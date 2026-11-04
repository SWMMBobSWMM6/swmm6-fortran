// F90Gen.cs - what the translator generates beyond method bodies: lambdas (a derived type per lambda, extending
// the abstract type of its delegate, with its captures as components and its body as the invoke binding),
// method-group delegates, constructors and field initializers, the static initialisation, and the helpers the
// engine calls (typed casts and tests, boxes, makers, the cpp_object bindings' wrappers).
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
    static string currentGroup = "zz";
    static int lambdaCount, mgCount;

    // ------------------------------------------------------------------------------------------------ translation driver
    static void TranslateAll(List<SyntaxTree> gen)
    {
        int n = 0;
        foreach (var t in engineTypes)
        {
            if (t.TypeKind != TypeKind.Class) continue;
            foreach (var sr in t.DeclaringSyntaxReferences)
            {
                if (sr.GetSyntax() is not ClassDeclarationSyntax cd) continue;
                currentGroup = Path.GetFileNameWithoutExtension(sr.SyntaxTree.FilePath);
                foreach (var mem in cd.Members)
                {
                    try
                    {
                        switch (mem)
                        {
                            case MethodDeclarationSyntax md: TranslateMethod(md, t); n++; break;
                            case ConstructorDeclarationSyntax ctor:
                                if (!ctor.Modifiers.Any(SyntaxKind.StaticKeyword)) { TranslateCtor(ctor, t); n++; }
                                else Note("static constructor");
                                break;
                            case FieldDeclarationSyntax: case BaseTypeDeclarationSyntax: case DelegateDeclarationSyntax: break;
                            default: Note("member " + mem.Kind()); break;
                        }
                    }
                    catch (global::Todo) { }
                }
            }
            if (InstanceClass(t))
            {
                currentGroup = Path.GetFileNameWithoutExtension(t.DeclaringSyntaxReferences[0].SyntaxTree.FilePath);
                try { FieldInits(t); } catch (global::Todo) { }
                foreach (var ic in t.InstanceConstructors.Where(c => c.IsImplicitlyDeclared)) { try { ImplicitCtor(ic, t); } catch (global::Todo) { } }
            }
            if (++n % 2000 == 0) Console.WriteLine("  " + n + " procedures");
        }
    }

    static void TranslateMethod(MethodDeclarationSyntax md, INamedTypeSymbol t)
    {
        var m = (IMethodSymbol)M(md).GetDeclaredSymbol(md)!;
        if (m.IsAbstract) return;
        var fn = new F90Fn(m, t);
        var p = MethodProc(m, fn);
        p.Comment = m.ToDisplayString();
        p.Group = currentGroup;
        IOperation? op = md.Body != null ? M(md).GetOperation(md.Body) : md.ExpressionBody != null ? M(md).GetOperation(md.ExpressionBody) : null;
        List<string> body;
        try { body = op == null ? new List<string>() : fn.Body(op, m); }
        catch (global::Todo e) { body = new List<string> { "  call cpp_todo(\"" + e.Message.Replace("\"", "'") + "\")" }; }
        Finish(p, fn, body);
    }

    static void Finish(Proc p, F90Fn fn, List<string> body)
    {
        if (p.Func && p.Result!.Contains("pointer")) p.Body.Add("  zres => null()");
        foreach (var l in fn.Prologue) p.Body.Add("  " + l);
        p.Body.AddRange(body);
        p.Locals.AddRange(fn.Decls);
        AddProc(p);
    }

    static bool HasFieldInits(INamedTypeSymbol t) => t.GetMembers().OfType<IFieldSymbol>().Any(f => !f.IsStatic && !f.IsConst && f.DeclaringSyntaxReferences.Any(r => r.GetSyntax() is VariableDeclaratorSyntax v && v.Initializer != null));

    static string FinitName(INamedTypeSymbol t) => Global("finit " + Key(t), "p_" + TypePath(t) + "__finit");

    /// <summary>The instance field initializers of a class, run first by each of its constructors that does not
    /// chain to another with this(...).</summary>
    static void FieldInits(INamedTypeSymbol t)
    {
        if (!HasFieldInits(t)) return;
        var fn = new F90Fn(null, t);
        var p = new Proc { Name = FinitName(t), Group = currentGroup, Comment = "field initializers of " + t.ToDisplayString() };
        p.Args.Add("self");
        p.ArgDecls.Add("class(" + TypeName(t) + "), intent(inout), target :: self");
        var lines = new List<string>();
        foreach (var f in t.GetMembers().OfType<IFieldSymbol>().Where(f => !f.IsStatic && !f.IsConst))
            foreach (var r in f.DeclaringSyntaxReferences)
                if (r.GetSyntax() is VariableDeclaratorSyntax v && v.Initializer != null)
                {
                    var op = M(v).GetOperation(v.Initializer) is IFieldInitializerOperation fi ? fi.Value : M(v).GetOperation(v.Initializer.Value);
                    if (op == null) { Note("field initializer"); continue; }
                    fn.FieldInit(f, op, lines);
                }
        Finish(p, fn, lines);
    }

    static void TranslateCtor(ConstructorDeclarationSyntax cd, INamedTypeSymbol t)
    {
        var c = (IMethodSymbol)M(cd).GetDeclaredSymbol(cd)!;
        var fn = new F90Fn(c, t);
        var p = MethodProc(c, fn);
        p.Comment = c.ToDisplayString();
        p.Group = currentGroup;
        var lines = new List<string>();
        bool chained = cd.Initializer != null && cd.Initializer.ThisOrBaseKeyword.IsKind(SyntaxKind.ThisKeyword);
        if (!chained && HasFieldInits(t)) { lines.Add("  call " + FinitName(t) + "(self)"); lines.Add("  if (associated(cpp_exc)) return"); }
        if (cd.Initializer != null && M(cd).GetOperation(cd.Initializer) is IOperation init)
        {
            var inv = init is IExpressionStatementOperation es ? es.Operation : init;
            if (inv is IInvocationOperation ci) fn.CtorInit(ci, lines);
            else Note("constructor initializer " + inv.Kind);
        }
        else BaseCtor(t, fn, lines);
        var op = cd.Body != null ? M(cd).GetOperation(cd.Body) : cd.ExpressionBody != null ? M(cd).GetOperation(cd.ExpressionBody) : null;
        try { if (op != null) lines.AddRange(fn.Body(op, c)); }
        catch (global::Todo e) { lines.Add("  call cpp_todo(\"" + e.Message.Replace("\"", "'") + "\")"); }
        Finish(p, fn, lines);
    }

    /// <summary>The implicit base() of a constructor: the base class's parameterless constructor.</summary>
    static void BaseCtor(INamedTypeSymbol t, F90Fn fn, List<string> lines)
    {
        var b = t.BaseType;
        if (b == null || b.SpecialType == SpecialType.System_Object) return;
        var bc = b.InstanceConstructors.FirstOrDefault(x => x.Parameters.Length == 0);
        if (bc == null) { Note("no parameterless base constructor"); return; }
        if (IsEngine(b)) { lines.Add("  call " + MethodName(bc) + "(self)"); if (Throws(bc)) lines.Add("  if (associated(cpp_exc)) return"); }
        else if (IsRuntime(b)) fn.RuntimeBaseCtor(bc, lines);
        else if (IsSystem(b) && b.Name == "Exception") { }
        else Note("base constructor of " + b.ToDisplayString());
    }

    static void ImplicitCtor(IMethodSymbol c, INamedTypeSymbol t)
    {
        var fn = new F90Fn(c, t);
        var p = MethodProc(c, fn);
        p.Comment = "implicit " + c.ToDisplayString();
        p.Group = currentGroup;
        var lines = new List<string>();
        if (HasFieldInits(t)) { lines.Add("  call " + FinitName(t) + "(self)"); lines.Add("  if (associated(cpp_exc)) return"); }
        BaseCtor(t, fn, lines);
        Finish(p, fn, lines);
    }

    // ------------------------------------------------------------------------------------------------ static initialisation
    /// <summary>The engine's static field initializers, class by class: a class after the classes whose static
    /// fields its initializers read (C# initialises a class's statics before their first use), in source order
    /// otherwise; swmm6_engine_init runs them all.</summary>
    static void StaticInit(List<SyntaxTree> gen)
    {
        var inits = new Dictionary<INamedTypeSymbol, List<(IFieldSymbol f, IOperation op)>>(SymbolEqualityComparer.Default);
        var order = new List<INamedTypeSymbol>();
        foreach (var tr in gen)
            foreach (var v in tr.GetRoot().DescendantNodes().OfType<VariableDeclaratorSyntax>())
            {
                if (v.Parent?.Parent is not FieldDeclarationSyntax || v.Initializer == null) continue;
                var f = (IFieldSymbol)M(v).GetDeclaredSymbol(v)!;
                if (!f.IsStatic || f.IsConst) continue;
                var op = M(v).GetOperation(v.Initializer) is IFieldInitializerOperation fi ? fi.Value : M(v).GetOperation(v.Initializer.Value);
                if (op == null) continue;
                var t = f.ContainingType.OriginalDefinition;
                if (!inits.TryGetValue(t, out var l)) { inits[t] = l = new(); order.Add(t); }
                l.Add((f, op));
            }
        var deps = new Dictionary<INamedTypeSymbol, HashSet<INamedTypeSymbol>>(SymbolEqualityComparer.Default);
        foreach (var (t, l) in inits)
        {
            var d = new HashSet<INamedTypeSymbol>(SymbolEqualityComparer.Default);
            foreach (var (_, op) in l)
                foreach (var fr in op.DescendantsAndSelf().OfType<IFieldReferenceOperation>())
                    if (fr.Field.IsStatic && !fr.Field.IsConst && IsEngine(fr.Field.ContainingType) && !SEq.Equals(fr.Field.ContainingType.OriginalDefinition, t)) d.Add(fr.Field.ContainingType.OriginalDefinition);
            deps[t] = d;
        }
        var sorted = new List<INamedTypeSymbol>();
        var state = new Dictionary<INamedTypeSymbol, int>(SymbolEqualityComparer.Default);
        void Visit(INamedTypeSymbol t)
        {
            if (state.TryGetValue(t, out var s)) { if (s == 1) Note("static initialisation cycle (source order kept)"); return; }
            state[t] = 1;
            foreach (var d in deps[t]) if (inits.ContainsKey(d)) Visit(d);
            state[t] = 2;
            sorted.Add(t);
        }
        foreach (var t in order) Visit(t);
        var init = new Proc { Name = "swmm6_engine_init", Group = "zz_init", Comment = "the engine's static fields, in dependency order" };
        gused.Add("swmm6_engine_init");
        foreach (var t in sorted)
        {
            currentGroup = "zz_init";
            var fn = new F90Fn(null, t);
            var p = new Proc { Name = Global("sinit " + Key(t), "p_" + TypePath(t) + "__sinit"), Group = "zz_init", Comment = "static field initializers of " + t.ToDisplayString() };
            var lines = new List<string>();
            foreach (var (f, op) in inits[t]) fn.FieldInit(f, op, lines);
            Finish(p, fn, lines);
            init.Body.Add("  call " + p.Name + "()");
            init.Body.Add("  if (associated(cpp_exc)) return");
        }
        AddProc(init);
    }

    public sealed partial class F90Fn
    {
        /// <summary>A field initializer: self%f = value, or a static field's module variable.</summary>
        public void FieldInit(IFieldSymbol f, IOperation op, List<string> lines)
        {
            try
            {
                var od = f.OriginalDefinition;
                Loc loc;
                if (f.IsStatic) loc = new Loc(staticNames[od], slotFields.Contains(od) ? 'S' : IsRefType(f.Type) ? 'P' : 'V', f.Type);
                else loc = new Loc("self%" + typeInfo[od.ContainingType].Fields[od], slotFields.Contains(od) ? 'S' : IsRefType(f.Type) ? 'P' : 'V', f.Type);
                var v = Value(op, f.Type);
                FlushTo(lines, 0);
                Store(loc, v, lines, 0);
            }
            catch (global::Todo e)
            {
                Pre.Clear();
                lines.Add("  call cpp_todo(\"" + FEsc(e.Message) + "\")");
                Helper("cpp_todo", "the translator could not translate a construct: stop with this message", "", "character(len=*), intent(in)");
            }
        }

        /// <summary>this(...) or base(...) at the start of a constructor.</summary>
        public void CtorInit(IInvocationOperation ci, List<string> lines)
        {
            var c = ci.TargetMethod;
            try
            {
                if (IsRuntime(c.ContainingType))
                {
                    RtCall(c, "ctor", null, ci.Arguments, true, false, out _);
                    FlushTo(lines, 0);
                    return;
                }
                var evs = ci.Arguments.OrderBy(a => a.Parameter!.Ordinal).Select(a => (Func<Arg>)(() => a.Parameter!.RefKind != RefKind.None ? RefArg(a.Value) : ValArg(a.Value, a.Parameter!.Type))).ToList();
                var vals = Ordered(evs);
                Pre.Add("call " + MethodName(c) + "(" + string.Join(", ", new[] { "self" }.Concat(vals)) + ")");
                Check(Throws(c));
                FlushTo(lines, 0);
            }
            catch (global::Todo e)
            {
                Pre.Clear();
                lines.Add("  call cpp_todo(\"" + FEsc(e.Message) + "\")");
            }
        }

        public void RuntimeBaseCtor(IMethodSymbol bc, List<string> lines)
        {
            var s = RtSignature(bc, "ctor");
            var tail = new List<string>();
            foreach (var rp in s.Params)
                if (rp.Kind == PK.Maker) tail.Add(HMk(TaAt(rp, bc.ContainingType, bc)));
                else if (rp.Kind == PK.Mode) tail.Add(ModeOf(bc.ContainingType, TaAt(rp, bc.ContainingType, bc)).ToString());
            lines.Add("  call " + s.Name + "(" + string.Join(", ", new[] { "self" }.Concat(tail)) + ")");
            if (s.Throws) lines.Add("  if (associated(cpp_exc)) return");
        }

        // -------------------------------------------------------------------------------------------- lambdas
        string Lambda(IAnonymousFunctionOperation af, INamedTypeSymbol? dt, string? expect)
        {
            dt ??= DelegateTargetOf(af) as INamedTypeSymbol;
            if (dt == null) return Todo("lambda without a delegate type");
            var dname = expect ?? FName(dt);
            bool eraseAll = expect != null && expect != FName(dt);
            var sig = DelegateSig(dt, dname);
            var k = ++lambdaCount;
            var tn = Global("lambda type " + k, "t_lam" + k);
            var pn = Global("lambda proc " + k, "p_lam" + k);
            bool resErased = sig.Result != null && sig.Result.StartsWith("class(*)");
            var sub = new F90Fn(this, af, resErased);
            for (int i = 0; i < af.Symbol.Parameters.Length; i++)
            {
                var prm = af.Symbol.Parameters[i];
                var decl = sig.Decls[i + 1];
                sub.LambdaDummy(prm, "a" + (i + 1), decl);
            }
            var body = sub.Body(af.Body, af.Symbol);
            // the derived type
            var sb = new StringBuilder();
            sb.Append("  ! lambda at ").Append(Path.GetFileName(af.Syntax.SyntaxTree.FilePath)).Append(':').Append(af.Syntax.GetLocation().GetLineSpan().StartLinePosition.Line + 1).Append('\n');
            sb.Append("  type, extends(").Append(dname).Append(") :: ").Append(tn).Append('\n');
            foreach (var c in sub.Captures) sb.Append("    ").Append(c.decl).Append('\n');
            sb.Append("  contains\n    procedure :: invoke => ").Append(pn).Append("\n  end type ").Append(tn).Append('\n');
            extraTypes.Add(sb.ToString());
            var p = new Proc { Name = pn, Func = sig.Func, Result = sig.Result, Bound = true, Group = currentGroup, Comment = "lambda " + k };
            p.Args.AddRange(sig.Args);
            p.ArgDecls.Add("class(" + tn + "), intent(inout), target :: self");
            p.ArgDecls.AddRange(sig.Decls.Skip(1));
            Finish(p, sub, body);
            // the object, made here
            var z = Tmp("class(" + tn + "), pointer");
            Pre.Add("allocate(" + z + ")");
            foreach (var c in sub.Captures)
            {
                if (c.sym == null) { Pre.Add(z + "%c_this => " + This()); continue; }
                var v = Var(c.sym);
                if (v.K == 'S' || c.cell) Pre.Add(z + "%" + c.comp + " => " + v.D);
                else if (v.K == 'P') Pre.Add(z + "%" + c.comp + " => " + v.D);
                else Pre.Add(z + "%" + c.comp + " = " + v.D);
            }
            return z;
        }

        /// <summary>A lambda's dummy argument: canonical (as the delegate's abstract interface has it), reached
        /// through a typed local copy when erased or when it needs a home of its own.</summary>
        void LambdaDummy(IParameterSymbol prm, string dn, string decl)
        {
            if (decl.StartsWith("class(*)")) { ErasedDummy(prm, dn, decl); return; }
            DummyDeclC(prm, dn, true);
        }

        string DelegateCreation(IDelegateCreationOperation dc, string? expect)
        {
            var dt = (INamedTypeSymbol)dc.Type!;
            if (dc.Target is IAnonymousFunctionOperation af) return Lambda(af, dt, expect);
            if (dc.Target is IMethodReferenceOperation mr) return MethodGroup(mr, dt, expect);
            return Todo("delegate creation " + dc.Target.Kind);
        }

        static readonly Dictionary<string, (string type, string proc)> mgTypes = new();

        /// <summary>A delegate made from a method: a wrapper type whose invoke calls the method (on c_this).</summary>
        string MethodGroup(IMethodReferenceOperation mr, INamedTypeSymbol dt, string? expect)
        {
            var m = mr.Method;
            if (IsRuntime(m) || IsSystem(m)) return Todo("delegate from a runtime method");
            var dname = expect ?? FName(dt);
            bool eraseAll = expect != null && expect != FName(dt);
            var key = dname + "|" + Key(m);
            if (!mgTypes.TryGetValue(key, out var w))
            {
                var k = ++mgCount;
                var tn = Global("mg type " + k, "t_mg" + k);
                var pn = Global("mg proc " + k, "p_mg" + k);
                w = (tn, pn);
                mgTypes[key] = w;
                var sig = DelegateSig(dt, dname);
                var sb = new StringBuilder();
                sb.Append("  ! delegate from ").Append(m.ToDisplayString()).Append('\n');
                sb.Append("  type, extends(").Append(dname).Append(") :: ").Append(tn).Append('\n');
                if (!m.IsStatic) sb.Append("    class(").Append(TypeName(m.ContainingType)).Append("), pointer :: c_this => null()\n");
                sb.Append("  contains\n    procedure :: invoke => ").Append(pn).Append("\n  end type ").Append(tn).Append('\n');
                extraTypes.Add(sb.ToString());
                var p = new Proc { Name = pn, Func = sig.Func, Result = sig.Result, Bound = true, Group = currentGroup, Comment = "delegate from " + m.ToDisplayString() };
                p.Args.AddRange(sig.Args);
                p.ArgDecls.Add("class(" + tn + "), intent(inout), target :: self");
                p.ArgDecls.AddRange(sig.Decls.Skip(1));
                var sub = new F90Fn(m, m.ContainingType);
                var args = new List<string>();
                if (!m.IsStatic && !IsVirtualish(m)) args.Add("self%c_this");
                for (int i = 0; i < m.Parameters.Length; i++)
                {
                    var prm = m.Parameters[i];
                    var a = "a" + (i + 1);
                    var decl = sig.Decls[i + 1];
                    if (decl.StartsWith("class(*)") && prm.RefKind == RefKind.None && !IsObjectLike(prm.Type))
                        args.Add(PrimCode(prm.Type) != null || IsStructType(prm.Type) ? sub.UnboxRef(a, prm.Type) : sub.Cast("*", a, prm.Type));
                    else args.Add(a);
                }
                var callee = m.IsStatic || !IsVirtualish(m) ? MethodName(m) : "self%c_this%" + BindingName(m);
                var lines = new List<string>();
                foreach (var l in sub.Pre) lines.Add("  " + l);
                sub.Pre.Clear();
                var text = callee + "(" + string.Join(", ", args) + ")";
                if (!sig.Func) lines.Add("  call " + text);
                else if (sig.Result!.StartsWith("class(*)"))
                {
                    var r = sub.Tmp(PtrSpecOrVal(m.ReturnType));
                    lines.Add("  " + r + (IsRefType(m.ReturnType) ? " => " : " = ") + text);
                    var e = sub.ToErased(r, m.ReturnType);
                    foreach (var l in sub.Pre) lines.Add("  " + l);
                    sub.Pre.Clear();
                    lines.Add("  zres => " + e);
                }
                else lines.Add("  zres" + (sig.Result.Contains("pointer") ? " => " : " = ") + text);
                Finish(p, sub, lines);
            }
            var z = Tmp("class(" + w.type + "), pointer");
            Pre.Add("allocate(" + z + ")");
            if (!m.IsStatic)
            {
                var recv = X(mr.Instance!);
                Pre.Add(z + "%c_this => " + recv);
            }
            return z;
        }

        /// <summary>The canonical dummy of a bound procedure (a virtual method, a lambda): its declaration never
        /// varies with the body; what the body needs (TARGET, a cell, a slot, a reassignable copy) is a local.</summary>
        public string DummyDeclC(IParameterSymbol p, string dn, bool canonical)
        {
            if (!canonical) return DummyDecl(p, dn);
            if (p.RefKind != RefKind.None)
            {
                vars[p] = new VarInfo { D = dn, K = IsRefType(p.Type) ? 'S' : 'V', T = p.Type };
                return RefDummy(p.Type) + ", target :: " + dn;
            }
            if (!IsRefType(p.Type) && !IsString(p.Type) && addr.Contains(p) && !cells.Contains(p))
            {
                var ln = LocalName(p.Name + "_t");
                Decls.Add(VarSpec(p.Type) + ", target :: " + ln);
                Prologue.Add(ln + " = " + dn);
                vars[p] = new VarInfo { D = ln, K = 'V', T = p.Type };
                return ValDummy(p.Type) + " :: " + dn;
            }
            var d = DummyDecl(p, dn);
            return d.Replace(", target ::", " ::");
        }
    }

    /// <summary>InvokeSig with every type-parameter-typed parameter erased when eraseAll (a lambda made for a
    /// runtime parameter whose delegate type the runtime erases).</summary>
    static Sig InvokeSigE(INamedTypeSymbol d, string selfType, bool eraseAll)
    {
        if (!eraseAll) return InvokeSig(d, selfType);
        var inv = d.DelegateInvokeMethod!;
        var od = d.OriginalDefinition.DelegateInvokeMethod!;
        var s = new Sig();
        s.Args.Add("self");
        s.Decls.Add("class(" + selfType + "), intent(inout), target :: self");
        for (int i = 0; i < inv.Parameters.Length; i++)
        {
            var p = inv.Parameters[i];
            var orig = od.Parameters[i].Type;
            var a = "a" + (i + 1);
            s.Args.Add(a);
            string decl = orig is ITypeParameterSymbol ? (p.RefKind != RefKind.None ? SlotTarget() : "class(*), pointer, intent(in)") : (p.RefKind != RefKind.None ? RefDummy(p.Type) + ", target" : ValDummy(p.Type));
            s.Decls.Add(decl + " :: " + a);
        }
        if (!inv.ReturnsVoid)
        {
            s.Func = true;
            s.Result = (od.ReturnType is ITypeParameterSymbol ? (inv.RefKind != RefKind.None ? "type(cpp_slot), pointer" : "class(*), pointer") : ResultSpec(inv.ReturnType, inv.RefKind != RefKind.None)) + " :: zres";
        }
        return s;
    }

    static string SlotTarget() { UseSlot(); return "type(cpp_slot), intent(inout), target"; }

    // ------------------------------------------------------------------------------------------------ helpers
    static readonly SortedDictionary<string, (string kind, ITypeSymbol t)> helpers = new(StringComparer.Ordinal);

    static string HelperName(string kind, ITypeSymbol t)
    {
        var tn = PrimCode(t) is string c ? c : FName(t);
        if (tn.StartsWith("t_")) tn = tn.Substring(2);
        // a maker or default constructor of an erased generic runtime class depends on its type arguments (it hands
        // the new object its element makers): one helper per instantiation, not per Fortran type
        var inst = (kind is "mk" or "new") && t is INamedTypeSymbol gn && gn.IsGenericType && IsRuntime(gn) && ErasedArgs(gn).Any();
        if (inst)
        {
            var gt = (INamedTypeSymbol)t;
            tn += "_" + string.Join("_", gt.TypeArguments.Select(a => { var x = PrimCode(a) ?? FName(a); return x.StartsWith("t_") ? x.Substring(2) : x; }));
        }
        var n = Global("helper " + kind + " " + (inst ? t.ToDisplayString() : PrimCode(t) ?? FName(t)), "h_" + kind + "_" + tn);
        if (!helpers.ContainsKey(n)) helpers[n] = (kind, t);
        return n;
    }

    static string HAs(ITypeSymbol t) => HelperName("as", t);
    static string HUas(ITypeSymbol t) => HelperName("uas", t);
    static string HIs(ITypeSymbol t) => HelperName("is", t);
    static string HUis(ITypeSymbol t) => HelperName("uis", t);
    static string HBox(ITypeSymbol t) => HelperName("box", t);
    static string HRef(ITypeSymbol t) => HelperName("ref", t);
    static string HMk(ITypeSymbol t) => HelperName("mk", t);
    static string HNew(ITypeSymbol t) => HelperName("new", t);

    static string TypeGuard(ITypeSymbol t) => PrimCode(t) is string c ? "type is (" + PrimSpec(c) + ")" : IsStructType(t) ? "type is (" + FName(t) + ")" : "class is (" + FName(t) + ")";

    static void EmitHelpers()
    {
        // helpers ask for more helpers (a maker of a pair makes its elements): repeat until no new ones
        var done = new HashSet<string>();
        while (true)
        {
            var todo = helpers.Where(kv => !done.Contains(kv.Key)).ToList();
            if (todo.Count == 0) break;
            foreach (var (name, (kind, t)) in todo)
            {
                done.Add(name);
                try { HelperProc(name, kind, t); }
                catch (global::Todo e) { Note("helper " + kind + " " + t.ToDisplayString() + ": " + e.Message); }
            }
        }
    }

    static void HelperProc(string name, string kind, ITypeSymbol t)
    {
        var p = new Proc { Name = name, Group = "zz_helpers" };
        var b = p.Body;
        switch (kind)
        {
            case "as": case "uas":
                p.Func = true;
                p.Args.Add("x");
                p.ArgDecls.Add((kind == "as" ? "class(cpp_object)" : "class(*)") + ", pointer, intent(in) :: x");
                p.Result = VarSpec(t) + " :: zres";
                p.Comment = "the object x as " + t.ToDisplayString() + " (null if it is not one)";
                b.Add("  zres => null()");
                b.Add("  if (.not. associated(x)) return");
                b.Add("  select type (x)");
                b.Add("  " + TypeGuard(t));
                b.Add("    zres => x");
                b.Add("  end select");
                break;
            case "is": case "uis":
                p.Func = true;
                p.Args.Add("x");
                p.ArgDecls.Add((kind == "is" ? "class(cpp_object)" : "class(*)") + ", pointer, intent(in) :: x");
                p.Result = "logical :: zres";
                p.Comment = "x is " + t.ToDisplayString();
                b.Add("  zres = .false.");
                b.Add("  if (.not. associated(x)) return");
                b.Add("  select type (x)");
                b.Add("  " + TypeGuard(t));
                b.Add("    zres = .true.");
                b.Add("  end select");
                break;
            case "box":
                p.Func = true;
                p.Args.Add("v");
                p.ArgDecls.Add((PrimCode(t) is string c ? PrimSpec(c) : "type(" + FName(t) + ")") + ", intent(in) :: v");
                p.Result = "class(*), pointer :: zres";
                p.Comment = "a new box holding v";
                b.Add("  allocate(zres, source=v)");
                break;
            case "ref":
                p.Func = true;
                p.Args.Add("x");
                p.ArgDecls.Add("class(*), pointer, intent(in) :: x");
                p.Result = (PrimCode(t) is string c2 ? PrimSpec(c2) : "type(" + FName(t) + ")") + ", pointer :: zres";
                p.Comment = "the value in the box x";
                b.Add("  zres => null()");
                b.Add("  select type (x)");
                b.Add("  " + TypeGuard(t));
                b.Add("    zres => x");
                b.Add("  end select");
                break;
            case "mk":
                p.Func = true;
                p.Result = "class(*), pointer :: zres";
                p.Comment = "a new default " + t.ToDisplayString() + " as Cpp.Elem<T>.Make makes it";
                if (PrimCode(t) is string c3) b.Add("  allocate(zres, source=" + PrimZero(c3) + ")");
                else if (IsStructType(t)) b.Add("  allocate(zres, source=" + FName(t) + "())");
                else if (DefaultCtor(t) != null) b.Add("  zres => " + HNew(t) + "()");
                else b.Add("  zres => null()");
                break;
            case "new":
                {
                    p.Func = true;
                    p.Result = VarSpec(t) + " :: zres";
                    p.Comment = "a new " + t.ToDisplayString() + " made by its parameterless constructor (null if it has none)";
                    var dc = DefaultCtor(t);
                    b.Add("  zres => null()");
                    if (dc == null) break;
                    if (IsEngine(t))
                    {
                        b.Add("  allocate(zres)");
                        b.Add("  call " + MethodName(dc) + "(zres)");
                    }
                    else
                    {
                        var s = RtSignature(dc, "new");
                        var tail = new List<string>();
                        foreach (var rp in s.Params)
                            if (rp.Kind == PK.Maker) tail.Add(HMk(TaAt(rp, (INamedTypeSymbol)t, dc)));
                            else if (rp.Kind == PK.Mode) tail.Add(F90Fn.ModeOfPublic((INamedTypeSymbol)t, TaAt(rp, (INamedTypeSymbol)t, dc)).ToString());
                        b.Add("  zres => " + s.Name + "(" + string.Join(", ", tail) + ")");
                    }
                    break;
                }
        }
        AddProc(p);
    }

    /// <summary>The public parameterless constructor Cpp.Elem&lt;T&gt;.Make calls (reflection finds no other).</summary>
    static IMethodSymbol? DefaultCtor(ITypeSymbol t)
    {
        if (t is not INamedTypeSymbol n || n.TypeKind != TypeKind.Class || n.IsAbstract || n.IsStatic) return null;
        if (!(IsEngine(n) || IsRuntime(n))) return null;
        return n.InstanceConstructors.FirstOrDefault(c => c.Parameters.Length == 0 && c.DeclaredAccessibility == Accessibility.Public);
    }

    /// <summary>The wrappers that bind an engine class's ICopy, IDisposable, IHashFn and IBinFn implementations to
    /// cpp_object's bindings (whose interfaces are fixed).</summary>
    static void WrapperProc(string name, string kind, INamedTypeSymbol t)
    {
        var p = new Proc { Name = name, Group = "zz_helpers", Bound = true, Comment = kind + " of " + t.ToDisplayString() };
        p.Args.Add("self");
        p.ArgDecls.Add("class(" + TypeName(t) + "), intent(inout), target :: self");
        IMethodSymbol? Impl(string iface, string member)
        {
            foreach (var i in t.AllInterfaces)
                if (StripArity(i.Name) == iface)
                    foreach (var im in i.GetMembers(member).OfType<IMethodSymbol>())
                        if (t.FindImplementationForInterfaceMember(im) is IMethodSymbol m && SEq.Equals(m.ContainingType.OriginalDefinition, t) || iface == "ICopy" && SEq.Equals(i.TypeArguments[0], t) && t.FindImplementationForInterfaceMember(im) is IMethodSymbol)
                            return (IMethodSymbol)t.FindImplementationForInterfaceMember(im)!;
            return null;
        }
        string Callee(IMethodSymbol m) => IsVirtualish(m) ? "self%" + BindingName(m) : MethodName(m);
        string SelfArg(IMethodSymbol m) => IsVirtualish(m) ? "" : "self";
        string Join(IMethodSymbol m, params string[] rest) => string.Join(", ", new[] { SelfArg(m) }.Concat(rest).Where(x => x.Length > 0));
        var fn = new F90Fn(null, t);
        switch (kind)
        {
            case "clone":
                {
                    var m = Impl("ICopy", "Clone");
                    p.Func = true; p.Result = "class(cpp_object), pointer :: zres";
                    if (m == null) { p.Body.Add("  zres => self"); break; }
                    p.Body.Add("  zres => " + Callee(m) + "(" + Join(m) + ")");
                    break;
                }
            case "assign":
                {
                    var m = Impl("ICopy", "Assign");
                    p.Args.Add("other");
                    p.ArgDecls.Add("class(cpp_object), pointer, intent(in) :: other");
                    if (m == null) break;
                    var o = fn.CastPublic("cpp_object", "other", m.Parameters[0].Type);
                    foreach (var l in fn.Pre) p.Body.Add("  " + l);
                    fn.Pre.Clear();
                    p.Body.Add("  call " + Callee(m) + "(" + Join(m, o) + ")");
                    break;
                }
            case "dispose":
                {
                    var disp = comp.GetSpecialType(SpecialType.System_IDisposable).GetMembers("Dispose").OfType<IMethodSymbol>().First();
                    var m = t.FindImplementationForInterfaceMember(disp) as IMethodSymbol;
                    if (m == null) break;
                    p.Body.Add("  call " + Callee(m) + "(" + Join(m) + ")");
                    break;
                }
            case "hash_of":
                {
                    var m = Impl("IHashFn", "HashOf");
                    p.Func = true; p.Result = "integer(8) :: zres";
                    p.Args.Add("k");
                    p.ArgDecls.Add("class(*), pointer, intent(in) :: k");
                    if (m == null) { p.Body.Add("  zres = 0"); break; }
                    var kt = m.Parameters[0].Type;
                    var a = PrimCode(kt) != null || IsStructType(kt) ? fn.UnboxPublic("k", kt) : fn.CastPublic("*", "k", kt);
                    foreach (var l in fn.Pre) p.Body.Add("  " + l);
                    fn.Pre.Clear();
                    p.Body.Add("  zres = " + Callee(m) + "(" + Join(m, a) + ")");
                    break;
                }
            case "call2":
                {
                    var m = Impl("IBinFn", "Call2");
                    p.Func = true; p.Result = "logical :: zres";
                    p.Args.Add("a"); p.Args.Add("b");
                    p.ArgDecls.Add("class(*), pointer, intent(in) :: a");
                    p.ArgDecls.Add("class(*), pointer, intent(in) :: b");
                    if (m == null) { p.Body.Add("  zres = .false."); break; }
                    var kt = m.Parameters[0].Type;
                    var a = PrimCode(kt) != null || IsStructType(kt) ? fn.UnboxPublic("a", kt) : fn.CastPublic("*", "a", kt);
                    var b2 = PrimCode(kt) != null || IsStructType(kt) ? fn.UnboxPublic("b", kt) : fn.CastPublic("*", "b", kt);
                    foreach (var l in fn.Pre) p.Body.Add("  " + l);
                    fn.Pre.Clear();
                    p.Body.Add("  zres = " + Callee(m) + "(" + Join(m, a, b2) + ")");
                    break;
                }
        }
        p.Locals.AddRange(fn.Decls);
        AddProc(p);
    }

    public sealed partial class F90Fn
    {
        public string CastPublic(string from, string x, ITypeSymbol to) => Cast(from, x, to);
        public string UnboxPublic(string x, ITypeSymbol t) => UnboxRef(x, t);
        public static int ModeOfPublic(INamedTypeSymbol ct, ITypeSymbol t) => ModeOf(ct, t);
    }
}
