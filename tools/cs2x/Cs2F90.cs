// Cs2F90 - translate the generated C# SWMM6 engine (cs/gen and cs/runtime/Hand_*.cs) into Fortran 2008
// (f90/gen), using Roslyn's semantic model, the way Cs2Go and Cs2Java write their engines. The design is
// tools/cs2x/F90.md; the decisions taken beyond it are listed at the top of F90Types.cs.
//
//   dotnet bin/cs2f90.dll CS_DIR F90_GEN_DIR [STUB_RUNTIME_FILE]
//
// Writes F90_GEN_DIR/swmm6_engine.f90 (the module: types, module variables, interfaces), the submodules
// F90_GEN_DIR/swmm6_engine_NNN.f90 (procedure bodies), F90_GEN_DIR/../cs2f90_runtime.txt (every runtime member
// and helper the engine calls, with its Fortran name and signature), F90_GEN_DIR/../cs2f90_todo.txt (the C#
// constructs not translated, by kind) and, if asked, a stub runtime module with those interfaces and empty
// bodies, for gfortran -fsyntax-only.
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

public sealed class Todo : Exception { public Todo(string m) : base(m) { } }

public static partial class Cs2F90
{
    static CSharpCompilation comp = null!;
    static readonly Dictionary<SyntaxTree, SemanticModel> models = new();
    static SemanticModel M(SyntaxNode n) => models[n.SyntaxTree];
    static readonly SortedDictionary<string, int> todos = new();
    static readonly SymbolEqualityComparer SEq = SymbolEqualityComparer.Default;

    public static int Main(string[] args)
    {
        var cs = args[0];
        var outDir = args[1];
        var stubPath = args.Length > 2 ? args[2] : null;
        var files = Directory.GetFiles(Path.Combine(cs, "gen"), "*.cs").Concat(Directory.GetFiles(Path.Combine(cs, "runtime"), "*.cs"))
            .Where(f => !f.EndsWith("Program.cs")).OrderBy(f => f, StringComparer.Ordinal).ToArray();
        var opts = new CSharpParseOptions(LanguageVersion.Latest);
        var trees = files.Select(f => CSharpSyntaxTree.ParseText(File.ReadAllText(f), opts, f)).ToList();
        var fw = Path.GetDirectoryName(typeof(object).Assembly.Location)!;
        var refs = new List<MetadataReference>();
        foreach (var f in Directory.GetFiles(fw, "*.dll"))
        {
            var b = Path.GetFileName(f);
            if (b.StartsWith("Microsoft.VisualBasic") || b == "mscorlib.dll") continue;
            try { refs.Add(MetadataReference.CreateFromFile(f)); } catch { }
        }
        comp = CSharpCompilation.Create("engine", trees, refs, new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary, allowUnsafe: true));
        var errs = comp.GetDiagnostics().Where(d => d.Severity == DiagnosticSeverity.Error).ToList();
        if (errs.Count > 0) { foreach (var e in errs.Take(10)) Console.Error.WriteLine(e); return 1; }
        foreach (var t in trees) models[t] = comp.GetSemanticModel(t);
        var gen = trees.Where(t => t.FilePath.Contains("/gen/") || Path.GetFileName(t.FilePath).StartsWith("Hand_")).ToList();
        var rt = trees.Where(t => !gen.Contains(t)).ToList();

        Directory.CreateDirectory(outDir);
        foreach (var f in Directory.GetFiles(outDir, "*.f90")) File.Delete(f);
        CollectTypes(gen);
        Console.WriteLine("engine types " + engineTypes.Count);
        AnalyzeRuntime(rt);
        Analyze(gen);
        AnalyzeEffects(gen);
        Console.WriteLine("analysis done: " + throwing.Count + " throwing, " + pure.Count + " pure");
        DeclareTypes();
        TranslateAll(gen);
        StaticInit(gen);
        BindAll();
        EmitHelpers();
        WriteOutput(outDir);
        using (var w = new StreamWriter(Path.Combine(outDir, "..", "cs2f90_todo.txt")))
        {
            w.WriteLine("# C# constructs the Fortran translator (tools/cs2x/Cs2F90.cs) did not translate, by kind: count, kind.");
            w.WriteLine("# Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.");
            w.WriteLine("# Total sites: " + todos.Values.Sum() + " in " + todos.Count + " kinds.");
            foreach (var kv in todos.OrderByDescending(kv => kv.Value).ThenBy(kv => kv.Key, StringComparer.Ordinal)) w.WriteLine("{0,6}  {1}", kv.Value, kv.Key);
        }
        WriteManifest(Path.Combine(outDir, "..", "cs2f90_runtime.txt"));
        if (stubPath != null) WriteStub(stubPath);
        Console.WriteLine("wrote " + Directory.GetFiles(outDir, "*.f90").Length + " files, " + todos.Count + " TODO kinds, " + todos.Values.Sum() + " TODO sites, "
            + rtMembers.Count + " runtime members, " + rtTypes.Count + " runtime types");
        return 0;
    }

    static void Note(string what) { todos[what] = todos.TryGetValue(what, out var c) ? c + 1 : 1; }

    static string Todo(string what)
    {
        Note(what);
        throw new Todo(what);
    }

    // ------------------------------------------------------------------------------------------------ symbols
    static bool IsRuntime(ISymbol s)
    {
        var ns = s is INamespaceSymbol nss ? nss : s.ContainingNamespace;
        while (ns != null && !ns.IsGlobalNamespace)
        {
            if (ns.Name == "Cpp" && ns.ContainingNamespace.IsGlobalNamespace) return true;
            ns = ns.ContainingNamespace;
        }
        return false;
    }

    static bool IsSystem(ISymbol s)
    {
        var ns = s is INamespaceSymbol n0 ? n0 : s.ContainingNamespace;
        while (ns != null && !ns.IsGlobalNamespace) { if (ns.Name == "System" && ns.ContainingNamespace.IsGlobalNamespace) return true; ns = ns.ContainingNamespace; }
        return false;
    }

    static readonly List<INamedTypeSymbol> engineTypes = new();
    static readonly HashSet<INamedTypeSymbol> engineSet = new(SymbolEqualityComparer.Default);

    static bool IsEngine(ITypeSymbol? t) => t is INamedTypeSymbol n && engineSet.Contains(n.OriginalDefinition);

    static void CollectTypes(List<SyntaxTree> gen)
    {
        foreach (var t in gen)
        {
            foreach (var td in t.GetRoot().DescendantNodes().OfType<BaseTypeDeclarationSyntax>())
            {
                var s = (INamedTypeSymbol)M(td).GetDeclaredSymbol(td)!;
                if (engineSet.Add(s)) engineTypes.Add(s);
            }
            foreach (var dd in t.GetRoot().DescendantNodes().OfType<DelegateDeclarationSyntax>())
            {
                var s = (INamedTypeSymbol)M(dd).GetDeclaredSymbol(dd)!;
                if (engineSet.Add(s)) engineTypes.Add(s);
            }
        }
    }

    static bool Derives(INamedTypeSymbol d, INamedTypeSymbol b)
    {
        for (var x = d.BaseType; x != null; x = x.BaseType) if (SEq.Equals(x.OriginalDefinition, b.OriginalDefinition)) return true;
        return false;
    }

    static string StripArity(string s) { var i = s.IndexOf('`'); return i < 0 ? s : s.Substring(0, i); }

    // ------------------------------------------------------------------------------------------------ names
    // Fortran names are case-insensitive and at most 63 characters, and the module is one scope for types,
    // procedures and variables. Every module-level name has a prefix (t_ type, p_ procedure, s_ module variable,
    // h_ generated helper, i_ abstract interface; the runtime's are cpp_) and never ends in '_'; every local and
    // dummy argument translated from C# ends in '_'; the translator's own locals and temporaries start with z and
    // do not end in '_'. So no local can hide a module name or an intrinsic, and no two kinds collide.
    static readonly Dictionary<string, string> gnames = new();
    static readonly HashSet<string> gused = new() { "swmm6_engine", "cpp_runtime" };

    static string Sanitize(string raw)
    {
        var sb = new StringBuilder();
        foreach (var ch0 in raw)
        {
            var ch = char.ToLowerInvariant(ch0);
            if (ch >= 'a' && ch <= 'z' || ch >= '0' && ch <= '9' || ch == '_') sb.Append(ch);
            else if (ch == '@') { }
            else sb.Append('_');
        }
        return sb.ToString();
    }

    static string Hash8(string s)
    {
        uint h = 2166136261;
        foreach (var ch in s) { h ^= ch; h *= 16777619; }
        return h.ToString("x8");
    }

    /// <summary>A unique module-level Fortran name for the entity key, built from raw (already prefixed).</summary>
    static string Global(string key, string raw)
    {
        if (gnames.TryGetValue(key, out var n)) return n;
        var s = Sanitize(raw);
        while (s.Contains("___")) s = s.Replace("___", "__");
        if (s.EndsWith("_")) s += "x";
        if (s.Length > 63) s = s.Substring(0, 53).TrimEnd('_') + "_" + Hash8(key);
        var b = s; int k = 2;
        while (gused.Contains(s))
        {
            var suf = "_" + k++;
            s = (b.Length + suf.Length > 63 ? b.Substring(0, 63 - suf.Length) : b) + suf;
        }
        gused.Add(s);
        gnames[key] = s;
        return s;
    }

    /// <summary>The C# path of an engine type: namespace below openswmm and class nesting, joined by _.</summary>
    static string TypePath(INamedTypeSymbol t)
    {
        t = t.OriginalDefinition;
        var parts = new List<string>();
        for (var c = t; c != null; c = c.ContainingType) parts.Insert(0, c.Name);
        var ns = new List<string>();
        for (var x = t.ContainingNamespace; x != null && !x.IsGlobalNamespace; x = x.ContainingNamespace) ns.Insert(0, x.Name);
        if (ns.Count > 0 && (ns[0] == "openswmm" || ns[0] == "Gen")) ns.RemoveAt(0);
        return string.Join("_", ns.Concat(parts));
    }

    static string Key(ISymbol s) => (s.ContainingSymbol != null && !(s.ContainingSymbol is INamespaceSymbol ns0 && ns0.IsGlobalNamespace) ? Key(s.ContainingSymbol) + "::" : "") + s.MetadataName + "#" + s.Kind
        + (s is IMethodSymbol m ? "(" + string.Join(",", m.Parameters.Select(p => p.RefKind + p.Type.ToDisplayString())) + ")" : "");

    static string TypeName(INamedTypeSymbol t) => Global("type " + Key(t.OriginalDefinition), "t_" + TypePath(t));

    static string ShortType(ITypeSymbol t)
    {
        switch (t.SpecialType)
        {
            case SpecialType.System_Int32: return "i";
            case SpecialType.System_Int64: return "l";
            case SpecialType.System_UInt64: return "ul";
            case SpecialType.System_UInt32: return "u";
            case SpecialType.System_Double: return "d";
            case SpecialType.System_Single: return "f";
            case SpecialType.System_Boolean: return "b";
            case SpecialType.System_SByte: return "c";
            case SpecialType.System_Byte: return "uc";
            case SpecialType.System_Int16: return "s";
            case SpecialType.System_UInt16: return "us";
            case SpecialType.System_Char: return "ch";
            case SpecialType.System_Object: return "o";
            case SpecialType.System_String: return "str";
        }
        if (t is IArrayTypeSymbol at) return ShortType(at.ElementType) + "a";
        if (t is ITypeParameterSymbol tp) return tp.Name.ToLowerInvariant();
        if (t is INamedTypeSymbol nt)
        {
            var s = StripArity(nt.Name).ToLowerInvariant();
            if (nt.TypeArguments.Length > 0) s += string.Join("", nt.TypeArguments.Select(ShortType));
            return s;
        }
        return "x";
    }

    static string MethodName(IMethodSymbol m)
    {
        m = m.OriginalDefinition;
        var t = m.ContainingType;
        var nm = m.MethodKind == MethodKind.Constructor ? "ctor" : m.Name.TrimStart('@');
        var same = m.MethodKind == MethodKind.Constructor ? t.InstanceConstructors.Length : t.GetMembers(m.Name).OfType<IMethodSymbol>().Count();
        var sfx = same > 1 || m.MethodKind == MethodKind.Constructor ? "_" + string.Join("_", m.Parameters.Select(p => ShortType(p.Type) + (p.RefKind != RefKind.None ? "r" : ""))) : "";
        return Global("proc " + Key(m), "p_" + TypePath(t) + "__" + nm + sfx);
    }

    // ------------------------------------------------------------------------------------------------ analyses
    // Locals and parameters that need a home other than a plain Fortran variable (the Java translator's boxing
    // analysis, extended to Fortran's needs):
    //   addr     - its address is taken (a ref argument, ref local, ref return or ref assignment);
    //   captured - a lambda refers to it;  mutated - it is assigned somewhere other than its declaration.
    // A captured local that is mutated or addressed lives in an allocated cell for its whole life; a reference-
    // typed local, parameter or field whose address is taken is a cpp_slot (Fortran has no pointer to a pointer);
    // a value-typed local whose address is taken gets the TARGET attribute.
    static readonly HashSet<ISymbol> addr = new(SymbolEqualityComparer.Default);
    static readonly HashSet<ISymbol> mutated = new(SymbolEqualityComparer.Default);
    static readonly HashSet<ISymbol> captured = new(SymbolEqualityComparer.Default);
    static readonly HashSet<ISymbol> cells = new(SymbolEqualityComparer.Default);
    static readonly HashSet<IFieldSymbol> slotFields = new(SymbolEqualityComparer.Default);

    static IEnumerable<(SyntaxNode node, IOperation op)> Bodies(SyntaxTree t)
    {
        var m = models[t];
        foreach (var node in t.GetRoot().DescendantNodes().Where(n => n is BaseMethodDeclarationSyntax || n is VariableDeclaratorSyntax && n.Parent?.Parent is FieldDeclarationSyntax))
        {
            if (node is ConstructorDeclarationSyntax cds && cds.Initializer != null && m.GetOperation(cds.Initializer) is IOperation ci) yield return (node, ci);
            IOperation? root = node switch
            {
                BaseMethodDeclarationSyntax bm => bm.Body != null ? m.GetOperation(bm.Body) : bm.ExpressionBody != null ? m.GetOperation(bm.ExpressionBody) : null,
                VariableDeclaratorSyntax vd => vd.Initializer != null ? m.GetOperation(vd.Initializer) : null,
                _ => null
            };
            if (root != null) yield return (node, root);
        }
    }

    static void Analyze(List<SyntaxTree> gen)
    {
        foreach (var t in gen)
            foreach (var (_, root) in Bodies(t))
                foreach (var op in root.DescendantsAndSelf())
                {
                    switch (op)
                    {
                        case IArgumentOperation a when a.Parameter != null && (a.Parameter.RefKind == RefKind.Ref || a.Parameter.RefKind == RefKind.Out || a.Parameter.RefKind == RefKind.In):
                            if (!InlinedRefArg(a)) Mark(a.Value, addr);
                            Mark(a.Value, mutated); break;
                        case IVariableDeclaratorOperation vd when vd.Symbol.RefKind != RefKind.None && vd.Initializer != null:
                            Mark(vd.Initializer.Value, addr); break;
                        case IReturnOperation r when r.ReturnedValue != null && IsRefReturn(r):
                            Mark(r.ReturnedValue, addr); break;
                        case ISimpleAssignmentOperation sa when sa.IsRef:
                            Mark(sa.Value, addr); break;
                        case IConditionalOperation c when c.IsRef:
                            Mark(c.WhenTrue, addr); if (c.WhenFalse != null) Mark(c.WhenFalse, addr); break;
                        case IAssignmentOperation asg:
                            Mark(asg.Target, mutated); break;
                        case IIncrementOrDecrementOperation inc:
                            Mark(inc.Target, mutated); break;
                        case IAnonymousFunctionOperation af:
                            foreach (var r in af.Body.Descendants())
                            {
                                ISymbol? s = r is ILocalReferenceOperation lr ? lr.Local : r is IParameterReferenceOperation pr ? pr.Parameter : null;
                                if (s == null) continue;
                                if (!IsInside(s.ContainingSymbol, af.Symbol)) captured.Add(s);
                            }
                            break;
                    }
                }
        foreach (var s in captured) if ((mutated.Contains(s) || addr.Contains(s)) && !IsRefSym(s)) cells.Add(s);
        Console.WriteLine("cells " + cells.Count + ", addressed " + addr.Count + ", slot fields " + slotFields.Count);
    }

    /// <summary>A ref argument of a runtime generic the translator writes inline (Mv.Take, Std.swap, ...): it
    /// needs the variable, not its address.</summary>
    static bool InlinedRefArg(IArgumentOperation a)
    {
        if (a.Parent is not IInvocationOperation inv || !IsRuntime(inv.TargetMethod)) return false;
        var m = inv.TargetMethod;
        var tn = m.ContainingType.Name;
        return tn == "Mv" && m.Name is "Take" or "TakeRef" or "Reset" or "Back" || tn == "Std" && m.Name is "swap" or "exchange" or "release";
    }

    static bool IsRefSym(ISymbol s) => s is ILocalSymbol l && l.RefKind != RefKind.None || s is IParameterSymbol p && p.RefKind != RefKind.None;

    static bool IsInside(ISymbol? s, ISymbol lambda)
    {
        for (var x = s; x != null; x = x.ContainingSymbol) if (SEq.Equals(x, lambda)) return true;
        return false;
    }

    static bool IsRefReturn(IReturnOperation r)
    {
        for (var p = r.Parent; p != null; p = p.Parent)
        {
            if (p is IAnonymousFunctionOperation af) return af.Symbol.RefKind != RefKind.None;
            if (p is ILocalFunctionOperation) return false;
        }
        var sm = r.SemanticModel;
        var md = r.Syntax.Ancestors().OfType<MethodDeclarationSyntax>().FirstOrDefault();
        return md != null && sm != null && sm.GetDeclaredSymbol(md) is IMethodSymbol ms && ms.RefKind != RefKind.None;
    }

    static void Mark(IOperation op, HashSet<ISymbol> set)
    {
        while (op is IConversionOperation cv && cv.Conversion.IsIdentity) op = cv.Operand;
        if (op is ILocalReferenceOperation l) set.Add(l.Local);
        else if (op is IParameterReferenceOperation p) set.Add(p.Parameter);
        else if (op is IFieldReferenceOperation f && set == addr && !IsRuntime(f.Field) && IsRefType(f.Field.Type)) slotFields.Add(f.Field.OriginalDefinition);
    }

    // ------------------------------------------------------------------------------------------------ effects
    // Which methods can throw (a call-graph fixpoint over the engine and the runtime, with every delegate
    // invocation and virtual call counted as reaching every lambda or override it may reach), and which are
    // pure (no throw, no store outside their own locals, no impure call): pure calls may stay inside a Fortran
    // expression, every other call is a statement of its own followed, if it can throw, by the exception test.
    static readonly HashSet<ISymbol> throwing = new(SymbolEqualityComparer.Default);
    static readonly HashSet<ISymbol> pure = new(SymbolEqualityComparer.Default);
    static readonly Dictionary<ISymbol, Effects> effects = new(SymbolEqualityComparer.Default);
    static readonly HashSet<ITypeSymbol> throwingDelegates = new(SymbolEqualityComparer.Default);

    sealed class Effects
    {
        public bool Throws, Writes, CallsUnknown, Delegate;
        public readonly HashSet<ISymbol> Callees = new(SymbolEqualityComparer.Default);
        public readonly HashSet<ITypeSymbol> Invoked = new(SymbolEqualityComparer.Default);
        public bool Runtime;
    }

    static void Scan(IOperation root, Effects e, ISymbol owner)
    {
        foreach (var op in root.DescendantsAndSelf())
        {
            switch (op)
            {
                case IThrowOperation: e.Throws = true; break;
                case IInvocationOperation inv:
                    if (inv.TargetMethod.MethodKind == MethodKind.DelegateInvoke) { e.Invoked.Add(inv.TargetMethod.ContainingType.OriginalDefinition); e.Delegate = true; }
                    else Callee(e, inv.TargetMethod);
                    break;
                case IObjectCreationOperation oc:
                    if (oc.Constructor != null) Callee(e, oc.Constructor);
                    if (oc.Type is INamedTypeSymbol st && IsSystem(st) && !st.Name.EndsWith("Exception")) e.CallsUnknown = true;
                    break;
                case IPropertyReferenceOperation pr:
                    if (pr.Property.GetMethod != null) Callee(e, pr.Property.GetMethod);
                    break;
                case IConversionOperation cv when cv.OperatorMethod != null: Callee(e, cv.OperatorMethod); break;
                case IBinaryOperation b when b.OperatorMethod != null: Callee(e, b.OperatorMethod); break;
                case IUnaryOperation u when u.OperatorMethod != null: Callee(e, u.OperatorMethod); break;
                case IIncrementOrDecrementOperation inc when inc.OperatorMethod != null: Callee(e, inc.OperatorMethod); e.Writes |= !LocalTarget(inc.Target); break;
                case ICompoundAssignmentOperation ca when ca.OperatorMethod != null: Callee(e, ca.OperatorMethod); e.Writes = true; break;
                case IAssignmentOperation a: if (!LocalTarget(a.Target) && !(owner is IMethodSymbol om && om.MethodKind == MethodKind.Constructor && OwnField(a.Target))) e.Writes = true; break;
                case IIncrementOrDecrementOperation i2: if (!LocalTarget(i2.Target)) e.Writes = true; break;
                case IArgumentOperation ar when ar.Parameter != null && ar.Parameter.RefKind != RefKind.None: if (!LocalTarget(ar.Value)) e.Writes = true; break;
                case IVariableDeclaratorOperation vd when vd.Symbol.RefKind != RefKind.None: e.Writes = true; break;
                case IReturnOperation r when r.ReturnedValue != null && IsRefReturn(r): e.Writes = true; break;
                case IAnonymousFunctionOperation: e.Writes = true; break;      // allocates
                case IArrayCreationOperation: e.Writes = true; break;
                case IForEachLoopOperation: e.CallsUnknown = true; break;
                case IUsingDeclarationOperation: e.CallsUnknown = true; e.Throws = true; break;
                case ITryOperation: e.Writes = true; break;
            }
        }
    }

    /// <summary>A field of the object a constructor is making (this.f): storing there is not a side effect.</summary>
    static bool OwnField(IOperation t)
    {
        while (t is IConversionOperation c) t = c.Operand;
        return t is IFieldReferenceOperation f && f.Instance is IInstanceReferenceOperation;
    }

    static bool LocalTarget(IOperation t)
    {
        while (t is IConversionOperation c) t = c.Operand;
        return t is ILocalReferenceOperation l && !captured.Contains(l.Local) && l.Local.RefKind == RefKind.None
            || t is IParameterReferenceOperation p && p.Parameter.RefKind == RefKind.None && !captured.Contains(p.Parameter)
            || t is IDiscardOperation;
    }

    static void Callee(Effects e, IMethodSymbol m)
    {
        if (IsSystem(m))
        {
            var tn = m.ContainingType.Name;
            if (tn is "Math" or "MathF" or "Double" or "Single" or "BitConverter" or "Object" or "Int32" or "Int64") return;
            if (m.Name is "GetHashCode" or "Equals" or "ReferenceEquals") return;
            e.CallsUnknown = true;
            // System members that throw in normal use: parsing and I/O (the rest throw only on a bug)
            var ns = m.ContainingNamespace?.ToDisplayString() ?? "";
            if (m.Name.Contains("Parse") || ns.StartsWith("System.IO")) e.Throws = true;
            // an interface member (IDisposable.Dispose, ...) may run engine code
            if (m.ContainingType.TypeKind == TypeKind.Interface || m.IsAbstract || m.IsVirtual && m.ContainingType.SpecialType != SpecialType.System_Object) e.Throws = true;
            return;
        }
        e.Callees.Add(m.OriginalDefinition);
    }

    static void AnalyzeRuntime(List<SyntaxTree> rt)
    {
        foreach (var t in rt)
        {
            var m = models[t];
            foreach (var node in t.GetRoot().DescendantNodes())
            {
                ISymbol? sym = null; IOperation? body = null;
                switch (node)
                {
                    case BaseMethodDeclarationSyntax bm:
                        sym = m.GetDeclaredSymbol(bm);
                        body = bm.Body != null ? m.GetOperation(bm.Body) : bm.ExpressionBody != null ? m.GetOperation(bm.ExpressionBody) : null;
                        break;
                    case AccessorDeclarationSyntax ad:
                        sym = m.GetDeclaredSymbol(ad);
                        body = ad.Body != null ? m.GetOperation(ad.Body) : ad.ExpressionBody != null ? m.GetOperation(ad.ExpressionBody) : null;
                        break;
                    case PropertyDeclarationSyntax pd when pd.ExpressionBody != null:
                        sym = ((IPropertySymbol)m.GetDeclaredSymbol(pd)!).GetMethod;
                        body = m.GetOperation(pd.ExpressionBody);
                        break;
                    case IndexerDeclarationSyntax id when id.ExpressionBody != null:
                        sym = ((IPropertySymbol)m.GetDeclaredSymbol(id)!).GetMethod;
                        body = m.GetOperation(id.ExpressionBody);
                        break;
                }
                if (sym == null) continue;
                var e = new Effects { Runtime = true };
                if (body != null) Scan(body, e, sym);
                if (sym is IMethodSymbol ms && (ms.IsExtern || ms.GetAttributes().Any(a => a.AttributeClass?.Name == "DllImportAttribute"))) { }
                if (node is ConstructorDeclarationSyntax cd && cd.Initializer != null && m.GetOperation(cd.Initializer) is IOperation ci) Scan(ci, e, sym);
                effects[sym.OriginalDefinition] = e;
            }
        }
    }

    static void AnalyzeEffects(List<SyntaxTree> gen)
    {
        // engine methods and constructors (with their field initializers), and every lambda body
        var lambdasByDelegate = new Dictionary<ITypeSymbol, List<ISymbol>>(SymbolEqualityComparer.Default);
        foreach (var t in gen)
        {
            var m = models[t];
            foreach (var (node, root) in Bodies(t))
            {
                ISymbol? sym = node is BaseMethodDeclarationSyntax bm ? m.GetDeclaredSymbol(bm) : null;
                if (node is VariableDeclaratorSyntax vd)
                {
                    var f = (IFieldSymbol)m.GetDeclaredSymbol(vd)!;
                    sym = f.IsStatic ? (ISymbol)f.ContainingType : f.ContainingType.InstanceConstructors.FirstOrDefault();
                    if (!f.IsStatic)
                    {
                        // an instance field initializer runs in every constructor
                        foreach (var c in f.ContainingType.InstanceConstructors) Add(c, root);
                        continue;
                    }
                }
                if (sym == null) continue;
                Add(sym, root);
            }
            foreach (var af in t.GetRoot().DescendantNodes().OfType<AnonymousFunctionExpressionSyntax>())
            {
                if (m.GetOperation(af) is not IAnonymousFunctionOperation op) continue;
                var e = new Effects();
                Scan(op.Body, e, op.Symbol);
                effects[op.Symbol] = e;
                var dt = DelegateTargetOf(op);
                if (dt != null)
                {
                    if (!lambdasByDelegate.TryGetValue(dt, out var l)) lambdasByDelegate[dt] = l = new();
                    l.Add(op.Symbol);
                }
            }
            foreach (var mr in t.GetRoot().DescendantNodes().OfType<ExpressionSyntax>())
            {
                if (m.GetOperation(mr) is IDelegateCreationOperation dc && dc.Target is IMethodReferenceOperation mref)
                {
                    var dt = dc.Type!.OriginalDefinition;
                    if (!lambdasByDelegate.TryGetValue(dt, out var l)) lambdasByDelegate[dt] = l = new();
                    l.Add(mref.Method.OriginalDefinition);
                }
            }
        }
        // a constructor also runs its base class's constructor (an implicit base() is in no operation tree)
        foreach (var ty in engineTypes.Where(InstanceClass))
            foreach (var c in ty.InstanceConstructors)
            {
                var b = ty.BaseType;
                var bc = b?.InstanceConstructors.FirstOrDefault(x => x.Parameters.Length == 0);
                if (bc == null || b!.SpecialType == SpecialType.System_Object) continue;
                if (!effects.TryGetValue(c.OriginalDefinition, out var e)) effects[c.OriginalDefinition] = e = new Effects();
                e.Callees.Add(bc.OriginalDefinition);
            }
        void Add(ISymbol s, IOperation root)
        {
            if (!effects.TryGetValue(s.OriginalDefinition, out var e)) effects[s.OriginalDefinition] = e = new Effects();
            Scan(root, e, s);
        }
        // overrides: a virtual call reaches every override
        var overrides = new Dictionary<ISymbol, List<ISymbol>>(SymbolEqualityComparer.Default);
        foreach (var ty in engineTypes)
            foreach (var mm in ty.GetMembers().OfType<IMethodSymbol>())
                for (var o = mm.OverriddenMethod; o != null; o = o.OverriddenMethod)
                {
                    if (!overrides.TryGetValue(o.OriginalDefinition, out var l)) overrides[o.OriginalDefinition] = l = new();
                    l.Add(mm.OriginalDefinition);
                }
        foreach (var k in overrides.Keys.ToList()) if (!effects.ContainsKey(k)) effects[k] = new Effects();
        // fixpoint: throws
        bool changed = true;
        while (changed)
        {
            changed = false;
            foreach (var (s, e) in effects)
            {
                if (throwing.Contains(s)) continue;
                bool th = e.Throws || e.Callees.Any(c => CallThrows(c)) || e.Invoked.Any(d => throwingDelegates.Contains(d) || !lambdasByDelegate.ContainsKey(d) && !IsEngine(d))
                    || (s is IMethodSymbol ms && overrides.TryGetValue(s, out var ov) && ov.Any(x => throwing.Contains(x)));
                if (th) { throwing.Add(s); changed = true; }
            }
            foreach (var (d, ls) in lambdasByDelegate)
                if (!throwingDelegates.Contains(d) && ls.Any(x => throwing.Contains(x))) { throwingDelegates.Add(d); changed = true; }
        }
        // runtime members that call back into engine code (delegates, interfaces) throw if the engine can
        // fixpoint: pure
        foreach (var (s, e) in effects) if (!e.Throws && !e.Writes && !e.CallsUnknown && !e.Delegate && !throwing.Contains(s)) pure.Add(s);
        changed = true;
        while (changed)
        {
            changed = false;
            foreach (var s in pure.ToList())
            {
                var e = effects[s];
                if (e.Callees.Any(c => !pure.Contains(c) && !(c is IMethodSymbol cm && IsSystem(cm))) || s is IMethodSymbol ms && (ms.IsVirtual || ms.IsAbstract || ms.IsOverride))
                { pure.Remove(s); changed = true; }
            }
        }
        bool CallThrows(ISymbol c)
        {
            if (throwing.Contains(c)) return true;
            if (!effects.ContainsKey(c))
            {
                // a member with no body we could read (an interface member, an extern, a system call)
                if (c is IMethodSymbol cm && IsRuntime(cm) && (cm.ContainingType.TypeKind == TypeKind.Interface || cm.IsAbstract || cm.IsVirtual)) return true;
                return false;
            }
            return false;
        }
    }

    static ITypeSymbol? DelegateTargetOf(IAnonymousFunctionOperation af)
    {
        var p = af.Parent;
        if (p is IDelegateCreationOperation dc) return dc.Type?.OriginalDefinition;
        if (p is IConversionOperation cv) return cv.Type?.OriginalDefinition;
        return null;
    }

    /// <summary>Can a call to m (an engine or runtime method, constructor or accessor) throw?</summary>
    static bool Throws(IMethodSymbol m)
    {
        var od = m.OriginalDefinition;
        if (throwing.Contains(od)) return true;
        if (IsSystem(m)) return !(m.ContainingType.Name is "Math" or "MathF" or "Double" or "Object" or "BitConverter" or "Array");
        if (!effects.ContainsKey(od))
        {
            if (IsRuntime(m) && (m.ContainingType.TypeKind == TypeKind.Interface || m.IsAbstract || m.IsVirtual)) return true;
            // an implicit constructor: its field initializers were scanned under the constructor symbol
            return false;
        }
        return false;
    }

    static bool IsPure(IMethodSymbol m) => pure.Contains(m.OriginalDefinition);
}
