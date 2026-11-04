// F90Types.cs - C# types to Fortran types, the engine's derived types, procedure signatures, generated helpers
// and the layout of the output files.
//
// Decisions taken beyond tools/cs2x/F90.md:
//  - Non-virtual instance methods are module procedures called by name with the object as first argument (the
//    static binding C# gives them); only virtual, abstract and override methods, and the runtime's cpp_object
//    bindings (clone, assign, dispose, hash_of, call2), are type-bound. So a C# method that hides another of the
//    same name never meets it in a binding table.
//  - Every reference value (engine object, runtime object, array, delegate, string object) is held as
//    class(T), pointer; `object` is class(*), pointer. C# arrays are runtime objects (cpp_arr_d ... cpp_arr_o)
//    with a 0-based component a(:), as C# arrays are objects; a vector holds such an array object.
//  - A storage place of an erased generic element (a type argument of a runtime class that is not specialised)
//    is a cpp_slot, a type with one component `class(*), pointer :: p`. A reference element is the object
//    itself; a value element (a number, a runtime struct) is an allocated box. A `ref T` to a reference-typed
//    variable is a pointer to a cpp_slot, so a reference-typed local, parameter or field whose address is taken
//    is declared as a cpp_slot.
//  - By-value parameters of value type have the VALUE attribute (C# copies them; the callee may assign them);
//    object parameters are `pointer, intent(in)` and copied to a local when the callee reassigns them.
//  - Every call that is not pure is a statement of its own (into a temporary), so evaluation is left to right
//    as in C#; an earlier operand that a later call could change is first copied to a temporary.
//  - Enum constants and const fields are written as literals (Roslyn gives their values).
//  - String literals become cpp_r_lit("...") on every evaluation, as C#'s R.Lit makes a new buffer each time.
//  - Objects are never freed (C# has a garbage collector, Fortran does not).
//
// Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Operations;

public static partial class Cs2F90
{
    // ------------------------------------------------------------------------------------------------ type kinds
    static bool IsStructType(ITypeSymbol t) => t.TypeKind == TypeKind.Struct && t.SpecialType == SpecialType.None && !(t is INamedTypeSymbol n && n.OriginalDefinition.SpecialType == SpecialType.System_Nullable_T)
        && !(t.TypeKind == TypeKind.Enum);

    static ITypeSymbol Under(ITypeSymbol t) => t.TypeKind == TypeKind.Enum && t is INamedTypeSymbol e ? e.EnumUnderlyingType! : t;

    /// <summary>The one-letter code of a value Fortran holds in an intrinsic type: d f i l b z s c, or null.</summary>
    static string? PrimCode(ITypeSymbol? t)
    {
        if (t == null) return null;
        if (t.TypeKind == TypeKind.Enum && t is INamedTypeSymbol en) return PrimCode(en.EnumUnderlyingType!);
        return t.SpecialType switch
        {
            SpecialType.System_Double => "d", SpecialType.System_Single => "f",
            SpecialType.System_Int32 or SpecialType.System_UInt32 => "i",
            SpecialType.System_Int64 or SpecialType.System_UInt64 => "l",
            SpecialType.System_Byte or SpecialType.System_SByte => "b",
            SpecialType.System_Boolean => "z",
            SpecialType.System_Int16 => "s",
            SpecialType.System_UInt16 or SpecialType.System_Char => "c",
            _ => null
        };
    }

    static string PrimSpec(string code) => code switch
    {
        "d" => "real(8)", "f" => "real(4)", "i" => "integer(4)", "l" => "integer(8)", "b" => "integer(1)", "z" => "logical",
        "s" => "integer(2)", "c" => "integer(2)", _ => throw new Exception("prim " + code)
    };

    static string PrimZero(string code) => code switch
    {
        "d" => "0.0_8", "f" => "0.0_4", "i" => "0", "l" => "0_8", "b" => "0_1", "z" => ".false.", "s" => "0_2", "c" => "0_2", _ => "0"
    };

    static bool IsString(ITypeSymbol t) => t.SpecialType == SpecialType.System_String;

    /// <summary>A reference type: held in Fortran as a pointer.</summary>
    static bool IsRefType(ITypeSymbol t) => PrimCode(t) == null && !IsStructType(t) && !IsString(t) && t.SpecialType != SpecialType.System_Void;

    static bool IsObjectLike(ITypeSymbol t) => t.SpecialType == SpecialType.System_Object || t is ITypeParameterSymbol
        || t is INamedTypeSymbol n && IsSystem(n) && n.Name == "ValueType";

    // ------------------------------------------------------------------------------------------------ names of types
    static readonly HashSet<string> Specializable = new() { "Vec", "Ptr", "Iter", "RevIter", "CSpan", "Opt", "Atomic", "Box", "Less", "Hash", "EqualTo" };

    /// <summary>The Fortran derived-type name of a reference or struct type ("*" for object).</summary>
    static string FName(ITypeSymbol t)
    {
        if (t is IArrayTypeSymbol at)
        {
            if (at.Rank != 1) Todo("multidimensional array");
            var n = "cpp_arr_" + (PrimCode(at.ElementType) ?? "o");
            UseType(n, "array " + at.ElementType.ToDisplayString() + "[]", null);
            return n;
        }
        if (t is ITypeParameterSymbol) return "*";
        if (t is INamedTypeSymbol nt)
        {
            if (IsEngine(nt)) return TypeName(nt);
            if (IsRuntime(nt)) return RtTypeName(nt);
            if (IsSystem(nt))
            {
                if (nt.SpecialType == SpecialType.System_Object || nt.Name == "ValueType") return "*";
                if (nt.Name == "Exception" || nt.Name == "IDisposable") return "cpp_object";
                if (nt.TypeKind == TypeKind.Delegate) return SysDelegateName(nt);
                if (nt.Name.EndsWith("Exception")) { UseType("cpp_sysexception", "System exceptions (name and message)", "cpp_object"); return "cpp_sysexception"; }
                return Todo("system type " + nt.ToDisplayString());
            }
        }
        return Todo("type " + t.ToDisplayString());
    }

    static string Codes(IEnumerable<ITypeSymbol> args) => string.Join("_", args.Select(a => PrimCode(a) ?? "o"));

    static string RtTypeName(INamedTypeSymbol n)
    {
        var parts = new List<string>();
        for (var c = n; c != null; c = c.ContainingType) parts.Insert(0, StripArity(c.Name).ToLowerInvariant());
        var s = "cpp_" + string.Join("_", parts);
        var name = StripArity(n.Name);
        if (name == "Tup") s += n.TypeArguments.Length;
        bool deleg = n.TypeKind == TypeKind.Delegate;
        if (n.TypeArguments.Length > 0)
        {
            if (deleg) s += "_" + Codes(n.TypeArguments);
            else if (Specializable.Contains(name) && n.TypeArguments.Length == 1) s += "_" + (PrimCode(n.TypeArguments[0]) ?? "o");
        }
        if (deleg) delegateInfo[s] = (n, n.TypeArguments.Select(a => PrimCode(a) ?? "o").ToArray());
        if (n.IsStatic) return s;          // a static class has members, not instances
        string? baseName = null;
        if (deleg) baseName = "cpp_object";
        else if (n.BaseType != null && IsRuntime(n.BaseType)) baseName = RtTypeName(n.BaseType);
        else if (n.TypeKind == TypeKind.Class) baseName = "cpp_object";
        UseType(s, n.OriginalDefinition.ToDisplayString() + (n.TypeArguments.Length > 0 ? " as " + n.ToDisplayString() : ""), baseName, n);
        return s;
    }

    static string SysDelegateName(INamedTypeSymbol n)
    {
        var inv = n.DelegateInvokeMethod!;
        var name = StripArity(n.Name);
        string s;
        if (name == "Func") s = "cpp_func_" + Codes(n.TypeArguments);
        else if (name == "Action") s = n.TypeArguments.Length == 0 ? "cpp_action" : "cpp_action_" + Codes(n.TypeArguments);
        else if (name == "Predicate") s = "cpp_func_" + Codes(n.TypeArguments) + "_z";
        else if (name == "Comparison") s = "cpp_func_" + Codes(n.TypeArguments) + "_" + Codes(n.TypeArguments) + "_i";
        else return Todo("system delegate " + n.ToDisplayString());
        if (!delegateInfo.ContainsKey(s)) delegateInfo[s] = (n, n.TypeArguments.Select(a => PrimCode(a) ?? "o").ToArray());
        UseType(s, "System delegate " + n.ToDisplayString(), "cpp_object", n);
        return s;
    }

    /// <summary>Is a value of this delegate type invoked with erased (class(*)) arguments for its type parameters?</summary>
    static bool ErasedDelegate(INamedTypeSymbol d) => !IsEngine(d);

    // ------------------------------------------------------------------------------------------------ declarations
    /// <summary>The declaration type-spec of a variable holding a value of t.</summary>
    static string VarSpec(ITypeSymbol t)
    {
        if (PrimCode(t) is string c) return PrimSpec(c);
        if (IsString(t)) return Todo("a variable of type string");
        if (IsStructType(t)) return "type(" + FName(t) + ")";
        var n = FName(t);
        return "class(" + n + "), pointer";
    }

    static string Init(ITypeSymbol t)
    {
        if (PrimCode(t) is string c) return " = " + PrimZero(c);
        if (IsStructType(t)) return "";
        return " => null()";
    }

    /// <summary>A by-value dummy argument of type t.</summary>
    static string ValDummy(ITypeSymbol t)
    {
        if (PrimCode(t) is string c) return PrimSpec(c) + ", value";
        if (IsString(t)) return "character(len=*), intent(in)";
        if (IsStructType(t)) return "type(" + FName(t) + "), value";
        return "class(" + FName(t) + "), pointer, intent(in)";
    }

    /// <summary>A ref/out dummy argument of type t.</summary>
    static string RefDummy(ITypeSymbol t)
    {
        if (PrimCode(t) is string c) return PrimSpec(c) + ", intent(inout)";
        if (IsStructType(t)) return "type(" + FName(t) + "), intent(inout)";
        UseSlot();
        return "type(cpp_slot), intent(inout)";
    }

    /// <summary>A function result of type t (ref: a pointer to the location).</summary>
    static string ResultSpec(ITypeSymbol t, bool isRef)
    {
        if (isRef)
        {
            if (PrimCode(t) is string c) return PrimSpec(c) + ", pointer";
            if (IsStructType(t)) return "type(" + FName(t) + "), pointer";
            UseSlot();
            return "type(cpp_slot), pointer";
        }
        if (PrimCode(t) is string c2) return PrimSpec(c2);
        if (IsStructType(t)) return "type(" + FName(t) + ")";
        if (IsString(t)) return Todo("a function returning string");
        return "class(" + FName(t) + "), pointer";
    }

    static void UseSlot() => UseType("cpp_slot", "the place of an erased element or of a reference-typed variable whose address is taken: class(*), pointer :: p", null);

    // ------------------------------------------------------------------------------------------------ procedures
    sealed class Proc
    {
        public string Name = "";
        public bool Func;
        public readonly List<string> Args = new();
        public readonly List<string> ArgDecls = new();
        public string? Result;                 // "real(8) :: zres"
        public readonly List<string> Locals = new();
        public readonly List<string> Body = new();
        public string Group = "zz";
        public string Comment = "";
        public bool Bound;                     // the implementation of a binding (its dummies have canonical names)

        public string Interface()
        {
            var sb = new StringBuilder();
            if (Comment.Length > 0) sb.Append("    ! ").Append(Comment).Append('\n');
            sb.Append("    recursive module ").Append(Func ? "function " : "subroutine ").Append(Name).Append('(').Append(string.Join(", ", Args)).Append(')');
            if (Func) sb.Append(" result(zres)");
            sb.Append('\n');
            foreach (var d in ArgDecls) sb.Append("      ").Append(d).Append('\n');
            if (Func) sb.Append("      ").Append(Result).Append('\n');
            sb.Append("    end ").Append(Func ? "function " : "subroutine ").Append(Name).Append('\n');
            return sb.ToString();
        }

        public string Implementation()
        {
            var sb = new StringBuilder();
            sb.Append("  module procedure ").Append(Name).Append('\n');
            foreach (var l in Locals) sb.Append("    ").Append(l).Append('\n');
            foreach (var l in Body) sb.Append(l).Append('\n');
            sb.Append("  end procedure ").Append(Name).Append('\n');
            return sb.ToString();
        }
    }

    static readonly List<Proc> procs = new();
    static readonly HashSet<string> procNames = new();

    static void AddProc(Proc p)
    {
        if (!procNames.Add(p.Name)) { Note("translator error: procedure " + p.Name + " twice"); return; }
        procs.Add(p);
    }

    // ------------------------------------------------------------------------------------------------ engine types
    sealed class TypeInfo
    {
        public INamedTypeSymbol Sym = null!;
        public string Name = "";
        public string Base = "cpp_object";
        public bool Abstract;
        public readonly List<string> Components = new();
        public readonly List<string> Bindings = new();
        public readonly Dictionary<IFieldSymbol, string> Fields = new(SymbolEqualityComparer.Default);
    }

    static readonly Dictionary<INamedTypeSymbol, TypeInfo> typeInfo = new(SymbolEqualityComparer.Default);
    static readonly List<string> extraTypes = new();          // lambda and wrapper types, in order
    static readonly List<string> abstractIfaces = new();
    static readonly List<string> moduleVars = new();
    static readonly Dictionary<IFieldSymbol, string> staticNames = new(SymbolEqualityComparer.Default);
    static readonly Dictionary<IMethodSymbol, string> bindingNames = new(SymbolEqualityComparer.Default);

    static readonly HashSet<string> ReservedComponents = new() { "cpp_tag", "clone", "assign", "dispose", "hash_of", "call2", "invoke", "what", "msg" };

    static bool IsVirtualish(IMethodSymbol m) => !m.IsStatic && (m.IsVirtual || m.IsAbstract || m.IsOverride);

    static IMethodSymbol RootOf(IMethodSymbol m)
    {
        m = m.OriginalDefinition;
        while (m.OverriddenMethod != null) m = m.OverriddenMethod.OriginalDefinition;
        return m;
    }

    /// <summary>The binding name of a virtual method (the name of its override chain's root).</summary>
    static string BindingName(IMethodSymbol m)
    {
        var root = RootOf(m);
        if (bindingNames.TryGetValue(root, out var b)) return b;
        string n;
        if (IsRuntime(root)) n = Sanitize(root.Name);
        else
        {
            n = "v_" + Sanitize(root.Name.TrimStart('@'));
            var others = root.ContainingType.GetMembers(root.Name).OfType<IMethodSymbol>().Count(x => x.IsVirtual || x.IsAbstract);
            if (others > 1) n += "_" + string.Join("_", root.Parameters.Select(p => ShortType(p.Type)));
            if (n.Length > 60) n = n.Substring(0, 50) + "_" + Hash8(Key(root));
        }
        bindingNames[root] = n;
        return n;
    }

    static IEnumerable<INamedTypeSymbol> Ancestors(INamedTypeSymbol t)
    {
        for (var b = t.BaseType; b != null && IsEngine(b); b = b.BaseType) yield return b.OriginalDefinition;
    }

    static bool InstanceClass(INamedTypeSymbol s) => s.TypeKind == TypeKind.Class && !s.IsStatic;

    static void DeclareTypes()
    {
        // topological order: a type after its base
        var order = new List<INamedTypeSymbol>();
        var seen = new HashSet<INamedTypeSymbol>(SymbolEqualityComparer.Default);
        void Visit(INamedTypeSymbol t)
        {
            if (!seen.Add(t)) return;
            if (t.BaseType != null && IsEngine(t.BaseType)) Visit(t.BaseType.OriginalDefinition);
            order.Add(t);
        }
        foreach (var t in engineTypes) if (InstanceClass(t) || t.TypeKind == TypeKind.Delegate) Visit(t);
        foreach (var t in order)
        {
            var ti = new TypeInfo { Sym = t, Name = TypeName(t) };
            typeInfo[t] = ti;
            if (t.TypeKind == TypeKind.Delegate)
            {
                ti.Abstract = true;
                DelegateType(t, ti);
                continue;
            }
            var b = t.BaseType;
            if (b != null && IsEngine(b)) ti.Base = TypeName(b);
            else if (b != null && IsRuntime(b)) ti.Base = RtTypeName(b);
            else if (b != null && IsSystem(b) && b.Name == "Exception") { ti.Base = "cpp_sysexception"; UseType("cpp_sysexception", "System exceptions", "cpp_object"); }
            ti.Abstract = t.IsAbstract;
            // component names: unique in the hierarchy, never a binding name
            var taken = new HashSet<string>(ReservedComponents);
            foreach (var a in Ancestors(t)) foreach (var f in typeInfo[a].Fields.Values) taken.Add(f);
            if (b != null && IsRuntime(b)) for (var rb = b; rb != null && IsRuntime(rb); rb = rb.BaseType) foreach (var f in rb.GetMembers().OfType<IFieldSymbol>()) taken.Add(Sanitize(f.Name));
            foreach (var f in t.GetMembers().OfType<IFieldSymbol>().Where(f => !f.IsImplicitlyDeclared && !f.IsConst))
            {
                if (f.IsStatic) { StaticVar(f); continue; }
                var n = Sanitize(f.Name);
                if (n.Length == 0 || !char.IsLetter(n[0]) || n.StartsWith("v_") || n.StartsWith("t_") || n.StartsWith("cpp_") || n.StartsWith("c_")) n = "f" + n;
                if (n.Length > 60) n = n.Substring(0, 50) + "_" + Hash8(f.Name);
                var bn = n; int k = 2;
                while (taken.Contains(n)) n = bn + "_" + k++;
                taken.Add(n);
                ti.Fields[f] = n;
                try { ti.Components.Add(ComponentDecl(f, n)); }
                catch (global::Todo e) { ti.Components.Add("! TODO field " + f.Name + ": " + e.Message); }
            }
        }
        foreach (var t in engineTypes.Where(t => t.TypeKind == TypeKind.Class && t.IsStatic))
            foreach (var f in t.GetMembers().OfType<IFieldSymbol>().Where(f => !f.IsImplicitlyDeclared && !f.IsConst)) StaticVar(f);
    }

    static string ComponentDecl(IFieldSymbol f, string n)
    {
        if (slotFields.Contains(f.OriginalDefinition)) { UseSlot(); return "type(cpp_slot) :: " + n; }
        return VarSpec(f.Type) + " :: " + n + Init(f.Type);
    }

    static void StaticVar(IFieldSymbol f)
    {
        var n = Global("static " + Key(f), "s_" + TypePath(f.ContainingType) + "__" + f.Name);
        staticNames[f.OriginalDefinition] = n;
        try
        {
            if (slotFields.Contains(f.OriginalDefinition)) { UseSlot(); moduleVars.Add("type(cpp_slot), target :: " + n); return; }
            var spec = VarSpec(f.Type);
            moduleVars.Add(spec + (spec.Contains("pointer") ? "" : ", target") + " :: " + n + Init(f.Type));
        }
        catch (global::Todo e) { moduleVars.Add("! TODO static " + f.Name + ": " + e.Message); }
    }

    /// <summary>An engine delegate type: an abstract type with a deferred invoke.</summary>
    static void DelegateType(INamedTypeSymbol t, TypeInfo ti)
    {
        var inv = t.DelegateInvokeMethod!;
        var iname = Global("iface " + Key(t), "i_" + ti.Name.Substring(2));
        ti.Bindings.Add("procedure(" + iname + "), deferred :: invoke");
        try
        {
            var sig = InvokeSig(t, ti.Name);
            abstractIfaces.Add(AbstractIface(iname, sig));
        }
        catch (global::Todo e) { abstractIfaces.Add("    ! TODO delegate " + t.Name + ": " + e.Message + "\n"); }
    }

    /// <summary>The dummies of a delegate type's invoke: self, a1..aN, result.</summary>
    sealed class Sig
    {
        public bool Func;
        public readonly List<string> Args = new();
        public readonly List<string> Decls = new();
        public string? Result;
    }

    static Sig InvokeSig(INamedTypeSymbol d, string selfType)
    {
        var inv = d.DelegateInvokeMethod!;
        var od = d.OriginalDefinition.DelegateInvokeMethod!;
        bool erased = ErasedDelegate(d);
        var s = new Sig();
        s.Args.Add("self");
        s.Decls.Add("class(" + selfType + "), intent(inout), target :: self");
        for (int i = 0; i < inv.Parameters.Length; i++)
        {
            var p = inv.Parameters[i];
            var orig = od.Parameters[i].Type;
            var a = "a" + (i + 1);
            s.Args.Add(a);
            s.Decls.Add(ErasedParamDecl(p.Type, orig, p.RefKind, erased) + " :: " + a);
        }
        if (!inv.ReturnsVoid)
        {
            s.Func = true;
            s.Result = ErasedResultDecl(inv.ReturnType, od.ReturnType, inv.RefKind != RefKind.None, erased) + " :: zres";
        }
        return s;
    }

    /// <summary>The runtime's and System's generic delegates by Fortran name: a C# type that has the name, and the
    /// code of each type argument (o: erased to class(*)). The name decides the invoke interface.</summary>
    static readonly Dictionary<string, (INamedTypeSymbol d, string[] codes)> delegateInfo = new();

    /// <summary>The invoke interface of a non-engine delegate type d seen as the Fortran type selfType (whose
    /// codes say which type arguments are erased). The lambda's own parameter types come from d.</summary>
    static Sig DelegateSig(INamedTypeSymbol d, string selfType)
    {
        if (IsEngine(d) || !delegateInfo.TryGetValue(selfType, out var info)) return InvokeSig(d, selfType);
        var codes = info.codes;
        var inv = d.DelegateInvokeMethod!;
        var od = d.OriginalDefinition.DelegateInvokeMethod!;
        var tps = d.OriginalDefinition.TypeParameters;
        // Predicate<T> and Comparison<T> share the names of Func<T, bool> and Func<T, T, int>
        string CodeOf(ITypeParameterSymbol tp) { var k = tps.IndexOf(tp); return k >= 0 && k < codes.Length ? codes[k] : "o"; }
        var s = new Sig();
        s.Args.Add("self");
        s.Decls.Add("class(" + selfType + "), intent(inout), target :: self");
        for (int i = 0; i < inv.Parameters.Length; i++)
        {
            var p = inv.Parameters[i];
            var orig = od.Parameters[i].Type;
            var a = "a" + (i + 1);
            s.Args.Add(a);
            string decl;
            bool r = p.RefKind != RefKind.None;
            if (orig is ITypeParameterSymbol tp)
            {
                var c = CodeOf(tp);
                decl = c == "o" ? (r ? SlotT() : "class(*), pointer, intent(in)") : PrimSpec(c) + (r ? ", intent(inout), target" : ", value");
            }
            else decl = r ? RefDummy(p.Type) + ", target" : ValDummy(p.Type);
            s.Decls.Add(decl + " :: " + a);
        }
        if (!inv.ReturnsVoid)
        {
            s.Func = true;
            bool r = inv.RefKind != RefKind.None;
            string rs;
            if (od.ReturnType is ITypeParameterSymbol tp)
            {
                var c = CodeOf(tp);
                if (d.Name == "Predicate") c = "z";
                rs = c == "o" ? (r ? SlotP() : "class(*), pointer") : PrimSpec(c) + (r ? ", pointer" : "");
            }
            else rs = ResultSpec(inv.ReturnType, r);
            s.Result = rs + " :: zres";
        }
        return s;
    }

    static string SlotT() { UseSlot(); return "type(cpp_slot), intent(inout), target"; }
    static string SlotP() { UseSlot(); return "type(cpp_slot), pointer"; }

    /// <summary>A parameter whose declared type in the generic definition is orig: erased to class(*) when orig is
    /// a type parameter bound to a non-primitive type in an erased context.</summary>
    static string ErasedParamDecl(ITypeSymbol t, ITypeSymbol orig, RefKind rk, bool erasedCtx)
    {
        if (erasedCtx && orig is ITypeParameterSymbol && PrimCode(t) == null)
        {
            if (rk != RefKind.None) { UseSlot(); return "type(cpp_slot), intent(inout), target"; }
            return "class(*), pointer, intent(in)";
        }
        return rk != RefKind.None ? RefDummy(t) + ", target" : ValDummy(t);
    }

    static string ErasedResultDecl(ITypeSymbol t, ITypeSymbol orig, bool isRef, bool erasedCtx)
    {
        if (erasedCtx && orig is ITypeParameterSymbol && PrimCode(t) == null)
        {
            if (isRef) { UseSlot(); return "type(cpp_slot), pointer"; }
            return "class(*), pointer";
        }
        return ResultSpec(t, isRef);
    }

    static string AbstractIface(string iname, Sig s)
    {
        var sb = new StringBuilder();
        sb.Append("    recursive ").Append(s.Func ? "function " : "subroutine ").Append(iname).Append('(').Append(string.Join(", ", s.Args)).Append(')');
        if (s.Func) sb.Append(" result(zres)");
        sb.Append('\n');
        sb.Append("      import\n");
        foreach (var d in s.Decls) sb.Append("      ").Append(d).Append('\n');
        if (s.Func) sb.Append("      ").Append(s.Result).Append('\n');
        sb.Append("    end ").Append(s.Func ? "function " : "subroutine ").Append(iname).Append('\n');
        return sb.ToString();
    }

    // ------------------------------------------------------------------------------------------------ method signatures
    /// <summary>The Fortran procedure of an engine method or constructor, with its dummies; the body is added by
    /// the function translator.</summary>
    static Proc MethodProc(IMethodSymbol m, F90Fn fn)
    {
        var p = new Proc();
        bool ctor = m.MethodKind == MethodKind.Constructor;
        p.Name = MethodName(m);
        bool virt = IsVirtualish(m);
        p.Bound = virt;
        if (!m.IsStatic)
        {
            p.Args.Add("self");
            p.ArgDecls.Add("class(" + TypeName(m.ContainingType) + "), intent(inout), target :: self");
        }
        // a method overriding a runtime virtual keeps the runtime's dummies (a1..) so the binding matches
        for (int i = 0; i < m.Parameters.Length; i++)
        {
            var prm = m.Parameters[i];
            var dn = virt ? "a" + (i + 1) : fn.DummyName(prm);
            p.Args.Add(dn);
            p.ArgDecls.Add(fn.DummyDeclC(prm, dn, virt));
        }
        if (!ctor && !m.ReturnsVoid)
        {
            p.Func = true;
            p.Result = ResultSpec(m.ReturnType, m.RefKind != RefKind.None) + " :: zres";
        }
        return p;
    }

    // ------------------------------------------------------------------------------------------------ bindings
    static void Bindings()
    {
        foreach (var (t, ti) in typeInfo)
        {
            if (t.TypeKind == TypeKind.Delegate) continue;
            foreach (var m in t.GetMembers().OfType<IMethodSymbol>().Where(x => x.MethodKind == MethodKind.Ordinary && IsVirtualish(x)))
            {
                var bn = BindingName(m);
                if (m.IsAbstract)
                {
                    var iname = Global("iface " + Key(m), "i_" + MethodName(m).Substring(2));
                    ti.Bindings.Add("procedure(" + iname + "), deferred :: " + bn);
                    ti.Abstract = true;
                    try
                    {
                        var fn = new F90Fn(m, t);
                        var p = MethodProc(m, fn);
                        var s = new Sig { Func = p.Func, Result = p.Result };
                        s.Args.AddRange(p.Args); s.Decls.AddRange(p.ArgDecls);
                        abstractIfaces.Add(AbstractIface(iname, s));
                    }
                    catch (global::Todo e) { abstractIfaces.Add("    ! TODO abstract " + m.Name + ": " + e.Message + "\n"); }
                }
                else ti.Bindings.Add("procedure :: " + bn + " => " + MethodName(m));
            }
            // the runtime's cpp_object bindings: ICopy (clone, assign), IDisposable (dispose), IHashFn, IBinFn
            foreach (var i in t.Interfaces)
            {
                var iname = StripArity(i.Name);
                if (IsRuntime(i) && iname == "ICopy" && SEq.Equals(i.TypeArguments[0].OriginalDefinition, t))
                {
                    ti.Bindings.Add("procedure :: clone => " + Wrapper("clone", t));
                    ti.Bindings.Add("procedure :: assign => " + Wrapper("assign", t));
                }
                if (IsRuntime(i) && iname == "IHashFn") ti.Bindings.Add("procedure :: hash_of => " + Wrapper("hash_of", t));
                if (IsRuntime(i) && iname == "IBinFn") ti.Bindings.Add("procedure :: call2 => " + Wrapper("call2", t));
            }
            var disp = comp.GetSpecialType(SpecialType.System_IDisposable).GetMembers("Dispose").OfType<IMethodSymbol>().First();
            if (t.AllInterfaces.Any(x => x.SpecialType == SpecialType.System_IDisposable) && t.FindImplementationForInterfaceMember(disp) is IMethodSymbol dm
                && SEq.Equals(dm.ContainingType.OriginalDefinition, t))
                // a virtual Dispose too: the wrapper calls it through its own binding (self%v_dispose), so an
                // override in a subclass is reached; the runtime only ever calls dispose (Dtor.Run, Mv.Delete)
                ti.Bindings.Add("procedure :: dispose => " + Wrapper("dispose", t));
        }
    }

    static readonly Dictionary<string, (string kind, INamedTypeSymbol t)> wrappers = new();

    static string Wrapper(string kind, INamedTypeSymbol t)
    {
        var n = Global("wrapper " + kind + " " + Key(t), "h_" + kind + "_" + TypePath(t));
        wrappers[n] = (kind, t);
        return n;
    }

    // ------------------------------------------------------------------------------------------------ output
    static void BindAll()
    {
        Bindings();
        foreach (var (n, (kind, t)) in wrappers.ToList()) WrapperProc(n, kind, t);
    }

    static void WriteOutput(string outDir)
    {
        var hdr = "! Generated by tools/cs2x/Cs2F90.cs from the C# SWMM6 engine (cs/gen). DO NOT EDIT.\n! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.\n";
        var sb = new StringBuilder(hdr);
        sb.Append("module swmm6_engine\n  use cpp_runtime\n  implicit none\n\n");
        foreach (var (t, ti) in typeInfo)
        {
            sb.Append("  ! ").Append(t.ToDisplayString()).Append('\n');
            sb.Append("  type, ").Append(ti.Abstract ? "abstract, " : "").Append("extends(").Append(ti.Base).Append(") :: ").Append(ti.Name).Append('\n');
            foreach (var c in ti.Components) sb.Append("    ").Append(c).Append('\n');
            if (ti.Bindings.Count > 0)
            {
                sb.Append("  contains\n");
                foreach (var b in ti.Bindings) sb.Append("    ").Append(b).Append('\n');
            }
            sb.Append("  end type ").Append(ti.Name).Append("\n\n");
        }
        foreach (var x in extraTypes) sb.Append(x).Append('\n');
        sb.Append("  ! static fields\n");
        foreach (var v in moduleVars) sb.Append("  ").Append(v).Append('\n');
        sb.Append("\n  abstract interface\n");
        foreach (var a in abstractIfaces) sb.Append(a);
        sb.Append("  end interface\n\n  interface\n");
        foreach (var p in procs) sb.Append(p.Interface());
        sb.Append("  end interface\nend module swmm6_engine\n");
        File.WriteAllText(Path.Combine(outDir, "swmm6_engine.f90"), sb.ToString());
        // submodules: procedures grouped by C# source file, cut at about 6000 lines
        var groups = procs.GroupBy(p => p.Group).OrderBy(g => g.Key, StringComparer.Ordinal).ToList();
        int fileNo = 0, lines = 0;
        StringBuilder? cur = null;
        void Close()
        {
            if (cur == null) return;
            cur.Append("end submodule swmm6_engine_").Append(fileNo.ToString("D3")).Append('\n');
            File.WriteAllText(Path.Combine(outDir, "swmm6_engine_" + fileNo.ToString("D3") + ".f90"), cur.ToString());
            cur = null;
        }
        foreach (var g in groups)
        {
            foreach (var p in g)
            {
                if (cur == null)
                {
                    fileNo++; lines = 0;
                    cur = new StringBuilder(hdr);
                    cur.Append("submodule (swmm6_engine) swmm6_engine_").Append(fileNo.ToString("D3")).Append("\n  implicit none\ncontains\n\n");
                }
                var text = p.Implementation();
                cur.Append(text).Append('\n');
                lines += p.Body.Count + p.Locals.Count + 2;
                if (lines > 6000) Close();
            }
        }
        Close();
        Console.WriteLine("procedures " + procs.Count + ", lambda/wrapper types " + extraTypes.Count + ", submodules " + fileNo);
    }
}
