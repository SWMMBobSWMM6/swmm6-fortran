// F90Rt.cs - the runtime the Fortran engine calls: the Fortran name and signature of every runtime member
// (derived mechanically from the C# runtime, cs/runtime), the manifest f90/cs2f90_runtime.txt that a runtime
// author implements, and a stub runtime module (interfaces, empty bodies) for gfortran -fsyntax-only.
//
// Naming: a runtime type Cpp.X<...> is cpp_x, or cpp_x_<code> when it is specialised (Vec, Ptr, Iter, RevIter,
// CSpan, Opt, Atomic, Box over a primitive: d f i l b z s c, else o), cpp_x_<codes> for a generic delegate; a
// member is <type>_<member>[_<parameter types> when overloaded][__<codes of the method's type arguments>].
// A type parameter that is not specialised is erased: its values travel as class(*), pointer (a reference value
// is the object, a value is an allocated box) and its places are cpp_slot.
//
// Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.Operations;

public static partial class Cs2F90
{
    sealed class RtType
    {
        public string Name = "", Desc = "";
        public string? Base;
        public bool Struct, Delegate, Abstract;
        public INamedTypeSymbol? Sym;
        public readonly SortedDictionary<string, string> Components = new(StringComparer.Ordinal);
        public Sig? Invoke;
        public readonly SortedSet<string> Bindings = new(StringComparer.Ordinal);
    }

    sealed class RtMember
    {
        public string Name = "", Cs = "", Note = "";
        public bool Func, Throws, Var;
        public readonly List<string> Args = new();
        public readonly List<string> Decls = new();
        public string? Result;
    }

    static readonly SortedDictionary<string, RtType> rtTypes = new(StringComparer.Ordinal);
    static readonly SortedDictionary<string, RtMember> rtMembers = new(StringComparer.Ordinal);

    static void UseType(string name, string desc, string? baseName, INamedTypeSymbol? sym = null)
    {
        if (rtTypes.ContainsKey(name)) return;
        var t = new RtType { Name = name, Desc = desc, Base = baseName, Sym = sym };
        if (name.StartsWith("cpp_arr_")) { t.Base = "cpp_object"; var c = name.Substring(8); t.Components["a"] = (c == "o" ? "type(cpp_slot)" : PrimSpec(c)) + ", allocatable :: a(:)"; if (c == "o") UseSlot(); }
        if (sym != null)
        {
            t.Struct = sym.TypeKind == TypeKind.Struct;
            if (t.Struct) t.Base = null;
            t.Delegate = sym.TypeKind == TypeKind.Delegate;
            t.Abstract = t.Delegate || sym.IsAbstract;
        }
        rtTypes[name] = t;
    }

    /// <summary>The invoke interfaces of the runtime's delegate types, from their names' codes.</summary>
    static void DelegateInvokes()
    {
        foreach (var t in rtTypes.Values)
            if (t.Delegate && t.Sym != null && t.Invoke == null)
            {
                try { t.Invoke = DelegateSig(delegateInfo.TryGetValue(t.Name, out var di) ? di.d : t.Sym, t.Name); }
                catch (global::Todo) { }
            }
    }

    static void UseComponent(string type, string comp, string decl)
    {
        if (rtTypes.TryGetValue(type, out var t)) t.Components[comp] = decl;
    }

    // ------------------------------------------------------------------------------------------------ type mapping
    /// <summary>A Fortran type for a value whose type in the runtime's generic definition is orig and whose
    /// constructed C# type is cons. erased(tp) tells whether a type parameter is erased in this context.</summary>
    sealed class FT
    {
        public string Kind = "";      // prim, ref, struct, erased, str, void
        public string Name = "";      // prim: code; ref/struct: Fortran type name ("*" for object)
        public override string ToString() => Kind + ":" + Name;
        public string Spec => Kind switch
        {
            "prim" => PrimSpec(Name), "struct" => "type(" + Name + ")", "ref" => "class(" + Name + "), pointer",
            "erased" => "class(*), pointer", _ => Kind
        };
    }

    static FT EngineFT(ITypeSymbol t)
    {
        if (t.SpecialType == SpecialType.System_Void) return new FT { Kind = "void" };
        if (PrimCode(t) is string c) return new FT { Kind = "prim", Name = c };
        if (IsString(t)) return new FT { Kind = "str" };
        if (IsStructType(t)) return new FT { Kind = "struct", Name = FName(t) };
        var n = FName(t);
        return new FT { Kind = n == "*" ? "erased" : "ref", Name = n };
    }

    static FT RtFT(ITypeSymbol orig, ITypeSymbol cons, Func<ITypeParameterSymbol, bool> erased)
    {
        if (orig is ITypeParameterSymbol tp)
        {
            if (!erased(tp) && PrimCode(cons) != null) return EngineFT(cons);
            if (!erased(tp) && PrimCode(cons) == null) return new FT { Kind = "erased", Name = "*" };
            return new FT { Kind = "erased", Name = "*" };
        }
        if (!ContainsTypeParam(orig)) return EngineFT(cons);
        if (orig is IArrayTypeSymbol oa && cons is IArrayTypeSymbol ca)
        {
            var e = RtFT(oa.ElementType, ca.ElementType, erased);
            var n = "cpp_arr_" + (e.Kind == "prim" ? e.Name : "o");
            UseType(n, "array", null);
            return new FT { Kind = "ref", Name = n };
        }
        if (orig is INamedTypeSymbol on && cons is INamedTypeSymbol cn)
        {
            var codes = new List<string>();
            for (int i = 0; i < on.TypeArguments.Length; i++)
            {
                var a = RtFT(on.TypeArguments[i], cn.TypeArguments[i], erased);
                codes.Add(a.Kind == "prim" ? a.Name : "o");
            }
            string name;
            if (IsSystem(cn) && cn.TypeKind == TypeKind.Delegate)
            {
                var b = StripArity(cn.Name);
                name = b == "Func" ? "cpp_func_" + string.Join("_", codes) : b == "Action" ? "cpp_action_" + string.Join("_", codes)
                    : b == "Predicate" ? "cpp_func_" + codes[0] + "_z" : "cpp_func_" + codes[0] + "_" + codes[0] + "_i";
                if (!delegateInfo.ContainsKey(name)) delegateInfo[name] = (cn, b is "Predicate" or "Comparison" ? new[] { codes[0] } : codes.ToArray());
                UseType(name, "System delegate " + cn.OriginalDefinition.ToDisplayString() + " (erased where o)", "cpp_object", cn);
                return new FT { Kind = "ref", Name = name };
            }
            if (IsRuntime(cn))
            {
                var parts = new List<string>();
                for (var c = cn; c != null; c = c.ContainingType) parts.Insert(0, StripArity(c.Name).ToLowerInvariant());
                name = "cpp_" + string.Join("_", parts);
                var bn = StripArity(cn.Name);
                if (bn == "Tup") name += cn.TypeArguments.Length;
                if (cn.TypeKind == TypeKind.Delegate) { name += "_" + string.Join("_", codes); if (!delegateInfo.ContainsKey(name)) delegateInfo[name] = (cn, codes.ToArray()); }
                else if (Specializable.Contains(bn) && codes.Count == 1) name += "_" + codes[0];
                if (cn.IsStatic) return new FT { Kind = "ref", Name = name };
                string? baseName = cn.TypeKind == TypeKind.Struct ? null : cn.BaseType != null && IsRuntime(cn.BaseType) ? RtFT(on.BaseType!, cn.BaseType, erased).Name : "cpp_object";
                UseType(name, cn.OriginalDefinition.ToDisplayString(), baseName, cn);
                return new FT { Kind = cn.TypeKind == TypeKind.Struct ? "struct" : "ref", Name = name };
            }
        }
        return EngineFT(cons);
    }

    static bool ContainsTypeParam(ITypeSymbol t) => t switch
    {
        ITypeParameterSymbol => true,
        IArrayTypeSymbol a => ContainsTypeParam(a.ElementType),
        INamedTypeSymbol n => n.TypeArguments.Any(ContainsTypeParam),
        _ => false
    };

    /// <summary>Is the runtime class (as constructed) specialised for its single type argument?</summary>
    static bool Specialised(INamedTypeSymbol t) => Specializable.Contains(StripArity(t.Name)) && t.TypeArguments.Length == 1 && PrimCode(t.TypeArguments[0]) != null;

    static Func<ITypeParameterSymbol, bool> ErasureOf(IMethodSymbol m)
    {
        var ct = m.ContainingType;
        return tp =>
        {
            if (tp.TypeParameterKind == TypeParameterKind.Method)
            {
                var idx = m.OriginalDefinition.TypeParameters.IndexOf(tp);
                return idx < 0 || PrimCode(m.TypeArguments[idx]) == null;
            }
            // a type parameter of the containing type (or of one enclosing it)
            for (var c = ct; c != null; c = c.ContainingType)
            {
                var idx = c.OriginalDefinition.TypeParameters.IndexOf(tp);
                if (idx >= 0) return !(Specialised(c) && c.TypeKind != TypeKind.Delegate) && !(c.TypeKind == TypeKind.Delegate && PrimCode(c.TypeArguments[idx]) != null);
            }
            return true;
        };
    }

    static Func<ITypeParameterSymbol, bool> ErasureOfType(INamedTypeSymbol ct) => tp =>
    {
        for (var c = ct; c != null; c = c.ContainingType)
        {
            var idx = c.OriginalDefinition.TypeParameters.IndexOf(tp);
            if (idx >= 0) return !Specialised(c) && !(c.TypeKind == TypeKind.Delegate && PrimCode(c.TypeArguments[idx]) != null);
        }
        return true;
    };

    // ------------------------------------------------------------------------------------------------ member signatures
    enum PK { Val, Ref, Str, VarArgs, Maker, Mode }

    sealed class RtParam
    {
        public PK Kind;
        public FT T = null!;          // the Fortran type of the dummy
        public ITypeSymbol? Cs;       // the constructed C# type (of the first use: signatures are cached per name)
        public string Decl = "";
        public int TaIndex;           // a maker or copy mode: the index of its type argument, in the class's
        public bool TaMethod;         // type arguments or (TaMethod) the generic method's
    }

    /// <summary>The type argument a maker or copy mode stands for, at this call site. The signature is cached by
    /// name, so rp.Cs is the first instantiation's; every use takes its own (Map&lt;int, Row&gt; and
    /// Map&lt;Str, Str&gt; share one Fortran constructor but not their makers).</summary>
    static ITypeSymbol TaAt(RtParam rp, INamedTypeSymbol? ct, IMethodSymbol? m) =>
        rp.TaMethod ? m!.TypeArguments[rp.TaIndex] : ct!.TypeArguments[rp.TaIndex];

    sealed class RtSig
    {
        public string Name = "";
        public bool Func, Self, StructSelf;
        public string SelfType = "";
        public readonly List<RtParam> Params = new();
        public FT? Result;
        public bool RefResult;
        public bool Throws, Pure;
        public int VarArgsMax;
    }

    static readonly Dictionary<string, RtSig> rtSigCache = new();
    static int varArgsMax = 0;

    /// <summary>The Fortran signature of a runtime method, constructor or accessor m (constructed). kind: "" for a
    /// method, "new" for a constructor making an object, "ctor" for a constructor run on an existing object (an
    /// engine class extending a runtime class), "get"/"set"/"ref" for property accessors.</summary>
    static RtSig RtSignature(IMethodSymbol m, string kind, int nVarArgs = 0)
    {
        var ct = m.ContainingType;
        var erased = ErasureOf(m);
        var tname = ct.TypeKind == TypeKind.Struct || ct.TypeKind == TypeKind.Class || ct.TypeKind == TypeKind.Interface || ct.TypeKind == TypeKind.Delegate ? RtFT(ct.OriginalDefinition, ct, ErasureOfType(ct)).Name : "x";
        var od = m.OriginalDefinition;
        string member;
        int overloads;
        if (m.MethodKind == MethodKind.Constructor) { member = kind; overloads = ct.OriginalDefinition.InstanceConstructors.Length; }
        else if (m.AssociatedSymbol is IPropertySymbol ps)
        {
            member = ps.IsIndexer ? "item" : Sanitize(ps.Name);
            if (m.MethodKind == MethodKind.PropertySet) member = "set_" + member;
            overloads = ct.OriginalDefinition.GetMembers().OfType<IPropertySymbol>().Count(x => x.IsIndexer == ps.IsIndexer && (ps.IsIndexer || x.Name == ps.Name));
        }
        else if (m.MethodKind == MethodKind.UserDefinedOperator || m.MethodKind == MethodKind.Conversion)
        {
            member = m.Name switch
            {
                "op_Equality" => "op_eq", "op_Inequality" => "op_ne", "op_Addition" => "op_add", "op_Subtraction" => "op_sub",
                "op_LessThan" => "op_lt", "op_GreaterThan" => "op_gt", "op_LessThanOrEqual" => "op_le", "op_GreaterThanOrEqual" => "op_ge",
                "op_Multiply" => "op_mul", "op_Division" => "op_div", "op_Increment" => "op_inc", "op_Decrement" => "op_dec",
                "op_Implicit" => "from", "op_Explicit" => "from", _ => Sanitize(m.Name)
            };
            overloads = ct.OriginalDefinition.GetMembers(m.Name).Length;
        }
        else { member = Sanitize(m.Name.TrimStart('@')); overloads = ct.OriginalDefinition.GetMembers(m.Name).OfType<IMethodSymbol>().Count(); }
        var sfx = overloads > 1 ? "_" + string.Join("_", od.Parameters.Select(p => ShortType(p.Type) + (p.RefKind != RefKind.None ? "r" : ""))) : "";
        if (overloads > 1 && od.Parameters.Length == 0) sfx = "_0";
        var spec = m.IsGenericMethod ? "__" + string.Join("", m.TypeArguments.Select(a => PrimCode(a) ?? "o")) : "";
        var raw = tname + "_" + member + sfx + spec;
        var key = "rt " + raw + (nVarArgs > 0 ? "" : "");
        if (rtSigCache.TryGetValue(key, out var cached)) return cached;
        var s = new RtSig();
        s.Name = Global(key, raw);
        s.Throws = Throws(m);
        s.Pure = IsPure(m) && !s.Throws;
        if (!m.IsStatic && kind != "new")
        {
            s.Self = true;
            s.SelfType = tname;
            s.StructSelf = ct.TypeKind == TypeKind.Struct;
        }
        for (int i = 0; i < m.Parameters.Length; i++)
        {
            var p = m.Parameters[i];
            var op = od.Parameters[i];
            var rp = new RtParam { Cs = p.Type };
            if (p.IsParams && p.Type is IArrayTypeSymbol pa && pa.ElementType.SpecialType == SpecialType.System_Object)
            {
                rp.Kind = PK.VarArgs;
                rp.Decl = "class(*), intent(in), optional";
                s.Params.Add(rp);
                continue;
            }
            if (IsString(p.Type)) { rp.Kind = PK.Str; rp.T = new FT { Kind = "str" }; rp.Decl = "character(len=*), intent(in)"; s.Params.Add(rp); continue; }
            rp.T = RtFT(op.Type, p.Type, erased);
            if (p.RefKind != RefKind.None)
            {
                rp.Kind = PK.Ref;
                rp.Decl = rp.T.Kind switch { "prim" => PrimSpec(rp.T.Name) + ", intent(inout)", "struct" => "type(" + rp.T.Name + "), intent(inout)", _ => SlotDecl() };
            }
            else
            {
                rp.Kind = PK.Val;
                rp.Decl = rp.T.Kind switch
                {
                    "prim" => PrimSpec(rp.T.Name) + ", value", "struct" => "type(" + rp.T.Name + "), intent(in)",
                    "erased" => "class(*), pointer, intent(in)", _ => "class(" + rp.T.Name + "), pointer, intent(in)"
                };
            }
            s.Params.Add(rp);
        }
        // an erased container makes and copies its elements with what the translator hands it: per erased type
        // argument a maker (procedure(cpp_maker)) and a copy mode (see the manifest's header)
        if ((kind == "new" || kind == "ctor") && ct.TypeKind == TypeKind.Class && IsRuntime(ct))
            foreach (var (ta, i) in ErasedArgs(ct))
            {
                s.Params.Add(new RtParam { Kind = PK.Maker, Cs = ta, Decl = "procedure(cpp_maker)", TaIndex = i });
                s.Params.Add(new RtParam { Kind = PK.Mode, Cs = ta, Decl = "integer(4), value", TaIndex = i });
            }
        // likewise a generic method, per erased method type argument (Arr.Make<T>, Arr.Clone<T>, ...)
        if (m.IsGenericMethod)
            foreach (var (ta, i) in m.TypeArguments.Select((a, i) => (a, i)).Where(x => PrimCode(x.a) == null))
            {
                s.Params.Add(new RtParam { Kind = PK.Maker, Cs = ta, Decl = "procedure(cpp_maker)", TaIndex = i, TaMethod = true });
                s.Params.Add(new RtParam { Kind = PK.Mode, Cs = ta, Decl = "integer(4), value", TaIndex = i, TaMethod = true });
            }
        if (kind == "new") { s.Func = true; s.Result = RtFT(ct.OriginalDefinition, ct, ErasureOfType(ct)); }
        else if (!m.ReturnsVoid && m.MethodKind != MethodKind.Constructor)
        {
            s.Func = true;
            s.Result = RtFT(od.ReturnType, m.ReturnType, erased);
            s.RefResult = m.RefKind != RefKind.None;
        }
        rtSigCache[key] = s;
        Manifest(s, m, kind);
        return s;
    }

    static string SlotDecl() { UseSlot(); return "type(cpp_slot), intent(inout)"; }

    /// <summary>The type arguments of a runtime class that its Fortran form erases (with their index).</summary>
    static IEnumerable<(ITypeSymbol, int)> ErasedArgs(INamedTypeSymbol ct)
    {
        if (!ct.IsGenericType || Specialised(ct)) yield break;
        for (int i = 0; i < ct.TypeArguments.Length; i++) yield return (ct.TypeArguments[i], i);
    }

    static string ResultDecl(RtSig s)
    {
        var r = s.Result!;
        if (s.RefResult)
            return r.Kind switch { "prim" => PrimSpec(r.Name) + ", pointer", "struct" => "type(" + r.Name + "), pointer", _ => "type(cpp_slot), pointer" };
        return r.Kind switch { "prim" => PrimSpec(r.Name), "struct" => "type(" + r.Name + ")", "erased" => "class(*), pointer", _ => "class(" + r.Name + "), pointer" };
    }

    static void Manifest(RtSig s, IMethodSymbol m, string kind)
    {
        var e = new RtMember { Name = s.Name, Cs = (kind is "new" or "ctor" ? kind + " " : "") + m.OriginalDefinition.ToDisplayString() + (m.ContainingType.IsGenericType || m.IsGenericMethod ? "  [as " + m.ToDisplayString() + "]" : ""), Func = s.Func, Throws = s.Throws };
        if (s.Self)
        {
            e.Args.Add("self");
            e.Decls.Add(s.StructSelf ? "type(" + s.SelfType + "), intent(in) :: self" : "class(" + s.SelfType + "), intent(inout), target :: self");
        }
        int k = 0;
        foreach (var p in s.Params)
        {
            if (p.Kind == PK.VarArgs)
            {
                for (int j = 1; j <= 40; j++) { e.Args.Add("v" + j); e.Decls.Add(p.Decl + " :: v" + j); }
                e.Note = "varargs: up to 40 optional class(*) arguments; an unsigned value comes as cpp_u8/cpp_u16/cpp_u32/cpp_u64";
                continue;
            }
            k++;
            var n = p.Kind == PK.Maker ? "mk" + k : p.Kind == PK.Mode ? "cm" + k : "a" + k;
            e.Args.Add(n);
            e.Decls.Add(p.Decl + " :: " + n);
        }
        if (s.Func) e.Result = ResultDecl(s) + " :: zres";
        rtMembers[s.Name] = e;
    }

    // ------------------------------------------------------------------------------------------------ helpers the runtime provides
    /// <summary>A runtime helper the translator itself calls (unsigned arithmetic, conversions, math): recorded in
    /// the manifest with its signature.</summary>
    static string Helper(string name, string cs, string result, params string[] dummies)
    {
        if (!rtMembers.ContainsKey(name))
        {
            var e = new RtMember { Name = name, Cs = cs, Func = result.Length > 0 };
            int k = 0;
            foreach (var d in dummies) { k++; e.Args.Add("a" + k); e.Decls.Add(d + " :: a" + k); }
            if (e.Func) e.Result = result + " :: zres";
            rtMembers[name] = e;
        }
        return name;
    }

    // ------------------------------------------------------------------------------------------------ manifest
    static void WriteManifest(string path)
    {
        DelegateInvokes();
        var sb = new StringBuilder();
        sb.Append(@"# cs2f90_runtime.txt - every runtime type, component and procedure the Fortran SWMM6 engine (f90/gen) uses,
# with its Fortran name and signature. Generated by tools/cs2x/Cs2F90.cs; a runtime author implements these in a
# module named cpp_runtime (it may use other modules and re-export them).
# Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
#
# Conventions
#  - Kinds: integer(1) sbyte/byte, integer(2) short/ushort/char, integer(4) int/uint, integer(8) long/ulong,
#    real(4) float, real(8) double, logical bool. Unsigned values are the same bits in the signed kind.
#  - type cpp_object: the root of every reference type (engine classes, runtime classes, arrays, delegates). It
#    must have a data component (cpp_tag), so no object is zero-sized (ASSOCIATED would fail for one), and these
#    overridable bindings, which the engine overrides with its own implementations:
#      function clone(self) result(zres)        class(cpp_object), intent(inout), target :: self
#                                                class(cpp_object), pointer :: zres     (default: zres => self)
#      subroutine assign(self, other)            class(cpp_object), pointer, intent(in) :: other
#      subroutine dispose(self)                  (default: nothing)
#      function hash_of(self, k) result(zres)    class(*), pointer, intent(in) :: k ; integer(8) :: zres
#      function call2(self, a, b) result(zres)   class(*), pointer, intent(in) :: a, b ; logical :: zres
#  - type cpp_slot: class(*), pointer :: p => null(). The place of an erased element and of a reference-typed
#    variable whose address is taken. A `ref T` to such a place is type(cpp_slot), pointer.
#  - Erasure: a type parameter of a runtime class that is not specialised is erased. Its values are
#    class(*), pointer: a reference value is the object itself, a value (number, logical, runtime struct) is an
#    allocated box the callee may keep (the engine allocates a fresh box for every value it passes).
#  - Erased containers get, per erased type argument (in order), a maker and a copy mode appended to every
#    constructor:   procedure(cpp_maker) :: mkK   (abstract interface: function () result(zres); class(*), pointer :: zres)
#                   integer(4), value :: cmK      0 value (copy the box), 1 reference (share the object),
#                                                 2 ICopy (zres => x%clone()), 3 array (deep copy, as Cpp.ArrCopy)
#    For the key of Map/UMap/UMapC/Set/USet/USetC the mode is that of Cpp.KeyCopy (2 only for runtime classes).
#    A generic method gets the same pair, appended, per erased method type argument (it may make or copy a T).
#  - Arrays: cpp_arr_<c> extends cpp_object, component a(:), always allocated, lower bound 0; cpp_arr_o holds
#    type(cpp_slot) elements. Vectors (cpp_vec_<c>) hold an array object in component a and a count n, as Cpp.Vec.
#  - Runtime structs (CPtr, Ptr, Iter, ...) are types without extends whose components all have default values
#    (the engine writes default(T) as the structure constructor T()).
#  - Exceptions: module variable  class(cpp_object), pointer :: cpp_exc => null(). A procedure marked [throws]
#    that throws sets cpp_exc to the exception object and returns at once; the engine tests cpp_exc after every
#    such call. A procedure that calls engine code (a delegate, a binding) returns at once if cpp_exc is set.
#  - Delegates: an abstract type extending cpp_object with a deferred binding invoke(self, a1, ...), dummy names
#    exactly as listed (the engine's lambdas override it); self is class(<type>), intent(inout), target.
#  - String literals: cpp_r_lit(s) makes a new NUL-terminated buffer from the Fortran character string s, every call.
#  - A Ptr made from a field (Cpp.Ptr(object, RefAt)) holds the engine's lambda object; where C# compares
#    at.Method, compare the lambdas' dynamic types (same_type_as): each C# lambda is one Fortran derived type.
#  - Object identity is pointer association (ASSOCIATED(p, q)); nothing is ever deallocated by the engine.
#  - The engine's static fields are set by calling swmm6_engine_init() once, before anything else.
#
");
        sb.Append("# ---------------------------------------------------------------------------------------------- types\n");
        foreach (var t in rtTypes.Values)
        {
            sb.Append("TYPE ").Append(t.Name).Append(t.Struct ? "  (struct)" : t.Base != null ? "  extends " + t.Base : "").Append(t.Abstract ? "  abstract" : "").Append("    # ").Append(t.Desc).Append('\n');
            foreach (var c in t.Components) sb.Append("  component  ").Append(c.Value).Append('\n');
            if (t.Invoke != null)
            {
                sb.Append("  deferred   ").Append(t.Invoke.Func ? "function" : "subroutine").Append(" invoke(").Append(string.Join(", ", t.Invoke.Args)).Append(")\n");
                foreach (var d in t.Invoke.Decls) sb.Append("               ").Append(d).Append('\n');
                if (t.Invoke.Result != null) sb.Append("               ").Append(t.Invoke.Result).Append('\n');
            }
            foreach (var b in t.Bindings) sb.Append("  binding    ").Append(b).Append('\n');
        }
        sb.Append("# ---------------------------------------------------------------------------------------------- procedures\n");
        foreach (var e in rtMembers.Values.Where(e => e.Var))
            sb.Append("VARIABLE ").Append(e.Result).Append("    # ").Append(e.Cs).Append('\n');
        foreach (var e in rtMembers.Values.Where(e => !e.Var))
        {
            sb.Append(e.Func ? "FUNCTION " : "SUBROUTINE ").Append(e.Name).Append('(').Append(string.Join(", ", e.Args)).Append(')').Append(e.Throws ? "  [throws]" : "").Append("    # ").Append(e.Cs).Append('\n');
            foreach (var d in e.Decls) sb.Append("    ").Append(d).Append('\n');
            if (e.Result != null) sb.Append("    ").Append(e.Result).Append('\n');
            if (e.Note.Length > 0) sb.Append("    # ").Append(e.Note).Append('\n');
        }
        File.WriteAllText(path, sb.ToString());
        Console.WriteLine("manifest: " + rtTypes.Count + " types, " + rtMembers.Count + " procedures");
    }

    // ------------------------------------------------------------------------------------------------ stub runtime
    static void WriteStub(string path)
    {
        var sb = new StringBuilder("! Stub of the runtime module cpp_runtime, generated from the manifest by tools/cs2x/Cs2F90.cs: types and\n! interfaces only, for gfortran -fsyntax-only on the engine. Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.\n");
        sb.Append("module cpp_runtime\n  implicit none\n");
        sb.Append(@"  type :: cpp_object
    integer(4) :: cpp_tag = 0
  contains
    procedure :: clone => cpp_object_clone
    procedure :: assign => cpp_object_assign
    procedure :: dispose => cpp_object_dispose
    procedure :: hash_of => cpp_object_hash_of
    procedure :: call2 => cpp_object_call2
  end type cpp_object
  type :: cpp_slot
    class(*), pointer :: p => null()
  end type cpp_slot
  type :: cpp_u8
    integer(1) :: v = 0
  end type
  type :: cpp_u16
    integer(2) :: v = 0
  end type
  type :: cpp_u32
    integer(4) :: v = 0
  end type
  type :: cpp_u64
    integer(8) :: v = 0
  end type
  class(cpp_object), pointer :: cpp_exc => null()
  abstract interface
    function cpp_maker() result(zres)
      class(*), pointer :: zres
    end function
  end interface
");
        // types in base-first order
        var done = new HashSet<string> { "cpp_object", "cpp_slot", "cpp_u8", "cpp_u16", "cpp_u32", "cpp_u64" };
        var list = rtTypes.Values.Where(t => !done.Contains(t.Name)).ToList();
        var ifaces = new StringBuilder();
        while (list.Count > 0)
        {
            var ready = list.Where(t => t.Base == null || done.Contains(t.Base) || !rtTypes.ContainsKey(t.Base) && t.Base == "cpp_object").ToList();
            if (ready.Count == 0) ready = list.ToList();
            foreach (var t in ready)
            {
                list.Remove(t);
                done.Add(t.Name);
                sb.Append("  type").Append(t.Abstract ? ", abstract" : "").Append(t.Base != null ? ", extends(" + t.Base + ")" : "").Append(" :: ").Append(t.Name).Append('\n');
                foreach (var c in t.Components) sb.Append("    ").Append(c.Value).Append('\n');
                if (t.Components.Count == 0 && t.Base == null) sb.Append("    integer(4) :: cpp_tag = 0\n");
                if (t.Invoke != null || t.Bindings.Count > 0)
                {
                    sb.Append("  contains\n");
                    if (t.Invoke != null)
                    {
                        sb.Append("    procedure(i_").Append(t.Name).Append("), deferred :: invoke\n");
                        ifaces.Append(AbstractIface("i_" + t.Name, t.Invoke));
                    }
                    foreach (var b in t.Bindings) sb.Append("    ").Append(b).Append('\n');
                }
                sb.Append("  end type ").Append(t.Name).Append('\n');
            }
        }
        foreach (var e in rtMembers.Values.Where(e => e.Var)) sb.Append("  ").Append(e.Result).Append('\n');
        sb.Append("  abstract interface\n").Append(ifaces).Append("  end interface\ncontains\n");
        sb.Append(@"  function cpp_object_clone(self) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => self
  end function
  subroutine cpp_object_assign(self, other)
    class(cpp_object), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
  end subroutine
  subroutine cpp_object_dispose(self)
    class(cpp_object), intent(inout), target :: self
  end subroutine
  function cpp_object_hash_of(self, k) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(*), pointer, intent(in) :: k
    integer(8) :: zres
    zres = 0
  end function
  function cpp_object_call2(self, a, b) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(*), pointer, intent(in) :: a, b
    logical :: zres
    zres = .false.
  end function
");
        foreach (var e in rtMembers.Values.Where(e => !e.Var))
        {
            sb.Append("  recursive ").Append(e.Func ? "function " : "subroutine ").Append(e.Name).Append('(').Append(string.Join(", ", e.Args)).Append(')').Append(e.Func ? " result(zres)" : "").Append('\n');
            foreach (var d in e.Decls) sb.Append("    ").Append(d).Append('\n');
            if (e.Result != null) sb.Append("    ").Append(e.Result).Append('\n');
            sb.Append("  end ").Append(e.Func ? "function" : "subroutine").Append('\n');
        }
        sb.Append("end module cpp_runtime\n");
        File.WriteAllText(path, sb.ToString());
    }
}
