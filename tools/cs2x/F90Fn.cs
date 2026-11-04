// F90Fn.cs - method bodies, part 1: the translation context (names, temporaries, labels), statements and
// control flow (loops, switch, goto, try/catch/finally, using) and the exception protocol.
//
// Exceptions: cpp_exc (runtime) holds the pending exception. A throw sets it and jumps to the innermost handler
// label (a catch dispatch or a finally), or returns when there is none; after every call that can throw the
// caller tests it the same way. A finally block is entered by every way out of its try: normal completion,
// exception (cpp_exc saved and cleared while the finally runs, then restored and propagated), and return,
// break, continue or goto to a target outside the try (a jump code set before entering the finally, and
// re-issued after it in the enclosing context, which may itself be guarded by a finally).
//
// Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.Operations;

public static partial class Cs2F90
{
    /// <summary>How a C# variable lives in Fortran: V a designator of the value (a variable, or a pointer to a
    /// cell, a ref local or a ref dummy), P a typed pointer designator, S a cpp_slot designator.</summary>
    sealed class VarInfo
    {
        public string D = "";
        public char K;
        public ITypeSymbol T = null!;
    }

    /// <summary>A location: designator D of kind K ('V' value, 'P' typed pointer, 'S' slot) holding type T.</summary>
    sealed class Loc
    {
        public string D = "";
        public char K;
        public ITypeSymbol T = null!;
        public Loc(string d, char k, ITypeSymbol t) { D = d; K = k; T = t; }
    }

    sealed class Region
    {
        public int FinLabel;
        public string CodeVar = "";
        public int Depth;
        public readonly List<int> Targets = new();     // code k = index + 1
        public int Code(int target)
        {
            var i = Targets.IndexOf(target);
            if (i < 0) { Targets.Add(target); i = Targets.Count - 1; }
            return i + 1;
        }
    }

    public sealed partial class F90Fn
    {
        readonly IMethodSymbol? method;
        readonly INamedTypeSymbol cls;
        public List<string> Pre = new();
        readonly Dictionary<ISymbol, VarInfo> vars = new(SymbolEqualityComparer.Default);
        readonly HashSet<string> used = new();
        public readonly List<string> Decls = new();
        public readonly List<string> Prologue = new();
        int tmp;
        int label = 100;
        ITypeSymbol? retType;
        bool retRef;
        bool resultErased;              // a lambda for a runtime delegate whose result is class(*)
        readonly Stack<string> condAccess = new();
        readonly Stack<string> implicitRecv = new();
        readonly List<Region> regions = new();
        readonly Stack<string> excTargets = new();     // labels as strings; empty: return
        readonly Dictionary<ILabelSymbol, int> labels = new(SymbolEqualityComparer.Default);
        readonly Dictionary<int, int> labelDepth = new();
        readonly HashSet<int> usedLabels = new();
        const int RET = -1;
        string self = "self";           // the designator of `this`
        // a lambda body: the captures it needs, by symbol (null for this)
        readonly F90Fn? parent;
        public readonly List<(ISymbol? sym, string comp, string decl, bool cell)> Captures = new();
        readonly IAnonymousFunctionOperation? lambda;

        public F90Fn(IMethodSymbol? m, INamedTypeSymbol c)
        {
            method = m; cls = c;
            retType = m?.ReturnType; retRef = m != null && m.RefKind != RefKind.None;
        }

        /// <summary>A lambda body: its own procedure, reaching the enclosing variables through self%c_*.</summary>
        F90Fn(F90Fn parent, IAnonymousFunctionOperation af, bool erasedResult)
        {
            this.parent = parent;
            lambda = af;
            method = af.Symbol; cls = parent.cls;
            retType = af.Symbol.ReturnType; retRef = af.Symbol.RefKind != RefKind.None;
            resultErased = erasedResult;
            self = "self";
        }

        string Tmp(string spec)
        {
            var n = "zz" + (++tmp);
            Decls.Add(spec + " :: " + n);
            return n;
        }

        int NewLabel() => ++label;

        static string Ind(int n) => new string(' ', 2 * n + 2);

        // -------------------------------------------------------------------------------------------- names
        string LocalName(string csName)
        {
            var n = Sanitize(csName.TrimStart('@'));
            if (n.Length == 0 || !char.IsLetter(n[0])) n = "x" + n;
            if (n.Length > 55) n = n.Substring(0, 46) + Hash8(csName);
            n += "_";
            var b = n; int k = 2;
            while (used.Contains(n)) n = b + k++ + "_";
            used.Add(n);
            return n;
        }

        public string DummyName(IParameterSymbol p)
        {
            var n = LocalName(p.Name);
            return n;
        }

        /// <summary>The declaration of a dummy argument named dn for parameter p; records how the body reaches p
        /// (directly, or through a local copy made by the prologue).</summary>
        public string DummyDecl(IParameterSymbol p, string dn)
        {
            if (p.RefKind != RefKind.None)
            {
                vars[p] = new VarInfo { D = dn, K = IsRefType(p.Type) ? 'S' : 'V', T = p.Type };
                // TARGET: the caller may pass a field this procedure also reaches through self (C# allows the alias)
                return RefDummy(p.Type) + ", target :: " + dn;
            }
            var decl = ValDummy(p.Type);
            if (IsString(p.Type)) { vars[p] = new VarInfo { D = dn, K = 'V', T = p.Type }; return decl + " :: " + dn; }
            bool refT = IsRefType(p.Type);
            if (cells.Contains(p))
            {
                var ln = LocalName(p.Name + "_c");
                if (refT) { UseSlot(); Decls.Add("type(cpp_slot), pointer :: " + ln); Prologue.Add("allocate(" + ln + ")"); Prologue.Add(ln + "%p => " + dn); vars[p] = new VarInfo { D = ln, K = 'S', T = p.Type }; }
                else { Decls.Add(VarSpec(p.Type) + ", pointer :: " + ln); Prologue.Add("allocate(" + ln + ")"); Prologue.Add(ln + " = " + dn); vars[p] = new VarInfo { D = ln, K = 'V', T = p.Type }; }
                return decl + " :: " + dn;
            }
            if (refT && addr.Contains(p))
            {
                var ln = LocalName(p.Name + "_s");
                UseSlot();
                Decls.Add("type(cpp_slot), target :: " + ln);
                Prologue.Add(ln + "%p => " + dn);
                vars[p] = new VarInfo { D = ln, K = 'S', T = p.Type };
                return decl + " :: " + dn;
            }
            if (refT && mutated.Contains(p))
            {
                var ln = LocalName(p.Name + "_l");
                Decls.Add(VarSpec(p.Type) + " :: " + ln);
                Prologue.Add(ln + " => " + dn);
                vars[p] = new VarInfo { D = ln, K = 'P', T = p.Type };
                return decl + " :: " + dn;
            }
            vars[p] = new VarInfo { D = dn, K = refT ? 'P' : 'V', T = p.Type };
            if (!mutated.Contains(p) && !addr.Contains(p)) stableNames.Add(dn);
            return decl + (addr.Contains(p) && !refT ? ", target" : "") + " :: " + dn;
        }

        /// <summary>A dummy argument of an erased delegate's invoke (class(*) for a parameter typed by a type
        /// parameter): the body reads a typed local copy.</summary>
        /// <summary>An expression for the prologue: the statements it needs (a downcast's select type into a
        /// temporary) go to the prologue before it, not to Pre, which the first statement of the body would never
        /// see (74 lambdas read an erased parameter's never-assigned temporary before this).</summary>
        string ToPrologue(Func<string> f)
        {
            var mark = Pre.Count;
            var r = f();
            for (int i = mark; i < Pre.Count; i++) Prologue.Add(Pre[i]);
            Pre.RemoveRange(mark, Pre.Count - mark);
            return r;
        }

        void ErasedDummy(IParameterSymbol p, string dn, string dummyDecl)
        {
            if (!dummyDecl.StartsWith("class(*)") || IsObjectLike(p.Type) || p.RefKind != RefKind.None)
            {
                if (p.RefKind != RefKind.None) { vars[p] = new VarInfo { D = dn, K = dummyDecl.Contains("cpp_slot") ? 'S' : 'V', T = p.Type }; return; }
                if (IsObjectLike(p.Type)) { vars[p] = new VarInfo { D = dn, K = 'P', T = p.Type }; return; }
                DummyDeclC(p, dn, true);
                return;
            }
            var ln = LocalName(p.Name);
            if (PrimCode(p.Type) != null || IsStructType(p.Type))
            {
                Decls.Add(VarSpec(p.Type) + (cells.Contains(p) ? ", pointer" : addr.Contains(p) ? ", target" : "") + " :: " + ln);
                if (cells.Contains(p)) Prologue.Add("allocate(" + ln + ")");
                Prologue.Add(ln + " = " + ToPrologue(() => UnboxRef(dn, p.Type)));
                vars[p] = new VarInfo { D = ln, K = 'V', T = p.Type };
            }
            else if (cells.Contains(p) || addr.Contains(p))
            {
                UseSlot();
                Decls.Add("type(cpp_slot), " + (cells.Contains(p) ? "pointer" : "target") + " :: " + ln);
                if (cells.Contains(p)) Prologue.Add("allocate(" + ln + ")");
                Prologue.Add(ln + "%p => " + dn);
                vars[p] = new VarInfo { D = ln, K = 'S', T = p.Type };
            }
            else
            {
                Decls.Add(VarSpec(p.Type) + " :: " + ln);
                Prologue.Add(ln + " => " + ToPrologue(() => Cast("*", dn, p.Type)));
                vars[p] = new VarInfo { D = ln, K = 'P', T = p.Type };
            }
        }

        VarInfo Var(ISymbol s)
        {
            if (vars.TryGetValue(s, out var v)) return v;
            if (parent != null && lambda != null) return Capture(s);
            Todo("unknown variable " + s.Name);
            return null!;
        }

        /// <summary>A variable of an enclosing scope, reached from a lambda body through a component of the
        /// lambda object: a pointer to its cell when the variable is a cell, a copy of its value otherwise.</summary>
        VarInfo Capture(ISymbol s)
        {
            var outer = parent!.Var(s);
            var t = outer.T;
            var comp = "c_" + Sanitize(s.Name.TrimStart('@'));
            if (comp.Length > 50) comp = comp.Substring(0, 40) + Hash8(s.Name);
            var bc = comp; int k = 2;
            while (Captures.Any(c => c.comp == comp)) comp = bc + "_" + k++;
            bool cell = cells.Contains(s) || outer.K == 'S';
            string decl;
            VarInfo vi;
            if (outer.K == 'S') { decl = "type(cpp_slot), pointer :: " + comp + " => null()"; vi = new VarInfo { D = "self%" + comp, K = 'S', T = t }; }
            else if (cell) { decl = VarSpec(t) + ", pointer :: " + comp + " => null()"; vi = new VarInfo { D = "self%" + comp, K = 'V', T = t }; }
            else if (IsRefType(t)) { decl = VarSpec(t) + " :: " + comp + " => null()"; vi = new VarInfo { D = "self%" + comp, K = 'P', T = t }; }
            else { decl = VarSpec(t) + " :: " + comp + Init(t); vi = new VarInfo { D = "self%" + comp, K = 'V', T = t }; }
            Captures.Add((s, comp, decl, cell));
            vars[s] = vi;
            return vi;
        }

        string This()
        {
            if (lambda == null) return self;
            var c = Captures.FirstOrDefault(x => x.sym == null);
            if (c.comp == null)
            {
                var ot = parent!.ThisType();
                Captures.Add((null, "c_this", "class(" + ot + "), pointer :: c_this => null()", false));
            }
            return "self%c_this";
        }

        string ThisType() => lambda == null ? TypeName(cls) : parent!.ThisType();

        // -------------------------------------------------------------------------------------------- body
        public List<string> Body(IOperation op, IMethodSymbol m)
        {
            var lines = new List<string>();
            var ops = op is IBlockOperation b ? b.Operations.ToList() : op is IMethodBodyOperation mb && mb.BlockBody != null ? mb.BlockBody.Operations.ToList() : new List<IOperation> { op };
            if (op is IMethodBodyOperation mb2 && mb2.BlockBody == null && mb2.ExpressionBody != null) ops = mb2.ExpressionBody.Operations.ToList();
            // C# labels are all in the top-level block of their methods
            foreach (var o in op.DescendantsAndSelf().OfType<ILabeledOperation>()) { var l = NewLabel(); labels[o.Label] = l; labelDepth[l] = 0; }
            Block(ops, lines, 0);
            return lines;
        }

        /// <summary>The body of an expression-bodied lambda or a field initializer: statements plus the value.</summary>
        public List<string> Stmts(IEnumerable<IOperation> ops)
        {
            var lines = new List<string>();
            Block(ops, lines, 0);
            return lines;
        }

        public void FlushTo(List<string> lines, int ind)
        {
            foreach (var p in Pre) lines.Add(Ind(ind) + p);
            Pre.Clear();
        }

        void Block(IEnumerable<IOperation> ops, List<string> lines, int ind)
        {
            var list = ops.ToList();
            for (int i = 0; i < list.Count; i++)
            {
                if (list[i] is IUsingDeclarationOperation ud) { UsingRest(ud, list.Skip(i + 1).ToList(), lines, ind); return; }
                Stmt(list[i], lines, ind);
            }
        }

        void Stmt(IOperation op, List<string> lines, int ind)
        {
            var saved = Pre;
            Pre = new List<string>();
            try { StmtInner(op, lines, ind); }
            catch (global::Todo e)
            {
                Pre.Clear();
                lines.Add(Ind(ind) + "call cpp_todo(\"" + FEsc(e.Message) + "\")");
                Helper("cpp_todo", "the translator could not translate a construct: stop with this message", "", "character(len=*), intent(in)");
            }
            catch (Exception e) when (e is not global::Todo)
            {
                Pre.Clear();
                Note("translator error " + e.GetType().Name + ": " + e.Message.Split('\n')[0]);
                lines.Add(Ind(ind) + "call cpp_todo(\"translator error\")");
                Helper("cpp_todo", "the translator could not translate a construct: stop with this message", "", "character(len=*), intent(in)");
            }
            Pre = saved;
        }

        static string FEsc(string s) => s.Replace("\"", "'").Replace("\n", " ").Replace("!", ".");

        void StmtInner(IOperation op, List<string> lines, int ind)
        {
            var p = Ind(ind);
            switch (op)
            {
                case IBlockOperation b:
                    Block(b.Operations, lines, ind);
                    return;
                case IVariableDeclarationGroupOperation g:
                    foreach (var d in g.Declarations)
                        foreach (var v in d.Declarators) LocalDecl(v, d.Initializer, lines, ind);
                    return;
                case IExpressionStatementOperation es:
                    StmtExpr(es.Operation, lines, ind);
                    return;
                case IReturnOperation r: Return(r, lines, ind); return;
                case IConditionalOperation c: If(c, lines, ind); return;
                case IWhileLoopOperation w: While(w, lines, ind); return;
                case IForLoopOperation f: For(f, lines, ind); return;
                case IForEachLoopOperation fe: ForEach(fe, lines, ind); return;
                case IBranchOperation br: Branch(br, lines, ind); return;
                case ILabeledOperation l:
                    lines.Add(Ind(ind) + labels[l.Label] + " continue");
                    usedLabels.Add(labels[l.Label]);
                    if (l.Operation != null) Stmt(l.Operation, lines, ind);
                    return;
                case ISwitchOperation sw: Switch(sw, lines, ind); return;
                case ITryOperation t: Try(t, lines, ind); return;
                case IThrowOperation th:
                    {
                        string v = th.Exception == null ? Rethrow() : XP(th.Exception);
                        FlushTo(lines, ind);
                        lines.Add(p + "cpp_exc => " + v);
                        lines.Add(p + ExcJump());
                        return;
                    }
                case IEmptyOperation: return;
                case IUsingDeclarationOperation ud: UsingRest(ud, new List<IOperation>(), lines, ind); return;
                case IUsingOperation u: Using(u, lines, ind); return;
                case ILocalFunctionOperation: Todo("local function"); return;
            }
            Todo("statement " + op.Kind);
        }

        string ExcJump() => excTargets.Count > 0 ? "goto " + excTargets.Peek() : "return";

        /// <summary>The exception test after a call that can throw.</summary>
        void Check(bool throws)
        {
            if (throws) Pre.Add("if (associated(cpp_exc)) " + ExcJump());
        }

        // -------------------------------------------------------------------------------------------- locals
        void LocalDecl(IVariableDeclaratorOperation v, IVariableInitializerOperation? outerInit, List<string> lines, int ind)
        {
            var p = Ind(ind);
            var loc = v.Symbol;
            var init = v.Initializer ?? outerInit;
            var t = loc.Type;
            if (loc.RefKind != RefKind.None)
            {
                var n0 = LocalName(loc.Name);
                if (IsRefType(t)) { UseSlot(); Decls.Add("type(cpp_slot), pointer :: " + n0); vars[loc] = new VarInfo { D = n0, K = 'S', T = t }; }
                else { Decls.Add(VarSpec(t) + ", pointer :: " + n0); vars[loc] = new VarInfo { D = n0, K = 'V', T = t }; }
                if (init != null)
                {
                    var l = RefLoc(init.Value);
                    FlushTo(lines, ind);
                    lines.Add(p + n0 + " => " + l.D);
                }
                return;
            }
            var n = LocalName(loc.Name);
            bool refT = IsRefType(t);
            if (IsString(t)) Todo("a local of type string");
            if (cells.Contains(loc))
            {
                if (refT) { UseSlot(); Decls.Add("type(cpp_slot), pointer :: " + n); vars[loc] = new VarInfo { D = n, K = 'S', T = t }; }
                else { Decls.Add(VarSpec(t) + ", pointer :: " + n); vars[loc] = new VarInfo { D = n, K = 'V', T = t }; }
                // a fresh cell at every execution of the declaration: each loop iteration's lambdas get their own
                var val = init != null ? Value(init.Value, t) : DefaultOf(t);
                FlushTo(lines, ind);
                lines.Add(p + "allocate(" + n + ")");
                lines.Add(p + (refT ? n + "%p => " + val : n + " = " + val));
                return;
            }
            if (refT && addr.Contains(loc))
            {
                UseSlot();
                Decls.Add("type(cpp_slot), target :: " + n);
                vars[loc] = new VarInfo { D = n, K = 'S', T = t };
                var val = init != null ? Value(init.Value, t) : "null()";
                FlushTo(lines, ind);
                lines.Add(p + n + "%p => " + val);
                return;
            }
            Decls.Add(VarSpec(t) + (addr.Contains(loc) && !refT ? ", target" : "") + " :: " + n);
            vars[loc] = new VarInfo { D = n, K = refT ? 'P' : 'V', T = t };
            if (!mutated.Contains(loc) && !addr.Contains(loc)) stableNames.Add(n);
            if (init == null)
            {
                if (refT) lines.Add(p + n + " => null()");
                return;
            }
            var value = Value(init.Value, t);
            FlushTo(lines, ind);
            lines.Add(p + n + (refT ? " => " : " = ") + value);
        }

        // -------------------------------------------------------------------------------------------- return
        void Return(IReturnOperation r, List<string> lines, int ind)
        {
            var p = Ind(ind);
            if (r.ReturnedValue != null)
            {
                if (retRef)
                {
                    var l = RefLoc(r.ReturnedValue);
                    FlushTo(lines, ind);
                    if (resultErased && l.K != 'S' && !IsRefType(l.T)) Todo("ref return of a value through an erased delegate");
                    lines.Add(p + "zres => " + l.D);
                }
                else if (resultErased)
                {
                    var v = Value(r.ReturnedValue, retType);
                    var bx = ToErased(v, retType!);
                    FlushTo(lines, ind);
                    lines.Add(p + "zres => " + bx);
                }
                else
                {
                    var v = Value(r.ReturnedValue, retType);
                    FlushTo(lines, ind);
                    lines.Add(p + "zres" + (IsRefType(retType!) ? " => " : " = ") + v);
                }
            }
            JumpTo(lines, ind, RET);
        }

        /// <summary>Leave for target (a label, or RET), through every finally between here and there.</summary>
        void JumpTo(List<string> lines, int ind, int target)
        {
            int depth = target == RET ? 0 : labelDepth.TryGetValue(target, out var d) ? d : 0;
            if (regions.Count <= depth)
            {
                if (target == RET) lines.Add(Ind(ind) + "return");
                else { lines.Add(Ind(ind) + "goto " + target); usedLabels.Add(target); }
                return;
            }
            var r = regions[^1];
            lines.Add(Ind(ind) + r.CodeVar + " = " + r.Code(target));
            lines.Add(Ind(ind) + "goto " + r.FinLabel);
        }

        // -------------------------------------------------------------------------------------------- if
        void If(IConditionalOperation c, List<string> lines, int ind)
        {
            var p = Ind(ind);
            var cond = Cond(c.Condition);
            FlushTo(lines, ind);
            lines.Add(p + "if (" + cond + ") then");
            Sub(c.WhenTrue, lines, ind + 1);
            var e = c.WhenFalse;
            while (e is IConditionalOperation c2 && c2.Type == null)
            {
                var saved = Pre; Pre = new List<string>();
                string cond2;
                try { cond2 = Cond(c2.Condition); }
                catch (global::Todo) { Pre = saved; break; }
                if (Pre.Count > 0) { Pre = saved; break; }
                Pre = saved;
                lines.Add(p + "else if (" + cond2 + ") then");
                Sub(c2.WhenTrue, lines, ind + 1);
                e = c2.WhenFalse;
            }
            if (e != null)
            {
                lines.Add(p + "else");
                Sub(e, lines, ind + 1);
            }
            lines.Add(p + "end if");
        }

        void Sub(IOperation op, List<string> lines, int ind)
        {
            if (op is IBlockOperation b) Block(b.Operations, lines, ind);
            else Stmt(op, lines, ind);
        }

        static bool IsTrue(IOperation? c) => c == null || c.ConstantValue.HasValue && c.ConstantValue.Value is true;

        // -------------------------------------------------------------------------------------------- loops
        int LoopLabel(ILabelSymbol? l)
        {
            var n = NewLabel();
            if (l != null) labels[l] = n;
            labelDepth[n] = regions.Count;
            return n;
        }

        void While(IWhileLoopOperation w, List<string> lines, int ind)
        {
            var p = Ind(ind);
            var brk = LoopLabel(w.ExitLabel);
            var cont = LoopLabel(w.ContinueLabel);
            lines.Add(p + "do");
            if (w.ConditionIsTop)
            {
                if (!IsTrue(w.Condition))
                {
                    var cond = Cond(w.Condition!);
                    FlushTo(lines, ind + 1);
                    lines.Add(Ind(ind + 1) + "if (.not. (" + cond + ")) exit");
                }
                Sub(w.Body, lines, ind + 1);
                if (usedLabels.Contains(cont)) lines.Add(Ind(ind + 1) + cont + " continue");
            }
            else
            {
                Sub(w.Body, lines, ind + 1);
                if (usedLabels.Contains(cont)) lines.Add(Ind(ind + 1) + cont + " continue");
                var cond = Cond(w.Condition!);
                FlushTo(lines, ind + 1);
                lines.Add(Ind(ind + 1) + "if (.not. (" + cond + ")) exit");
            }
            lines.Add(p + "end do");
            if (usedLabels.Contains(brk)) lines.Add(p + brk + " continue");
        }

        void For(IForLoopOperation f, List<string> lines, int ind)
        {
            var p = Ind(ind);
            foreach (var b in f.Before) Stmt(b, lines, ind);
            var brk = LoopLabel(f.ExitLabel);
            var cont = LoopLabel(f.ContinueLabel);
            lines.Add(p + "do");
            if (!IsTrue(f.Condition))
            {
                var cond = Cond(f.Condition!);
                FlushTo(lines, ind + 1);
                lines.Add(Ind(ind + 1) + "if (.not. (" + cond + ")) exit");
            }
            Sub(f.Body, lines, ind + 1);
            if (usedLabels.Contains(cont)) lines.Add(Ind(ind + 1) + cont + " continue");
            foreach (var a in f.AtLoopBottom) Stmt(a, lines, ind + 1);
            lines.Add(p + "end do");
            if (usedLabels.Contains(brk)) lines.Add(p + brk + " continue");
        }

        /// <summary>foreach (var x in c.Items()): walk c.begin() to c.end() with the runtime's iterator.</summary>
        void ForEach(IForEachLoopOperation fe, List<string> lines, int ind)
        {
            var p = Ind(ind);
            var coll = fe.Collection is IConversionOperation cv && cv.IsImplicit ? cv.Operand : fe.Collection;
            if (coll is not IInvocationOperation inv || inv.TargetMethod.Name != "Items" || inv.Instance == null || !IsRuntime(inv.TargetMethod))
            { Todo("foreach over " + coll.Type?.ToDisplayString()); return; }
            if (fe.LoopControlVariable is not IVariableDeclaratorOperation vd) { Todo("foreach variable"); return; }
            var recvT = (INamedTypeSymbol)inv.Instance.Type!;
            var begin = FindMember(recvT, "begin");
            var end = FindMember(recvT, "end");
            if (begin == null || end == null) { Todo("foreach over a collection without begin/end"); return; }
            var recv = Dsg(XP(inv.Instance), inv.Instance.Type!);
            var itT = begin.ReturnType;
            var it = RtCallValue(begin, recv, new List<string>(), itT);
            var itv = Tmp(VarSpec(itT));
            Pre.Add(itv + " = " + it);
            var en = RtCallValue(end, recv, new List<string>(), itT);
            var env = Tmp(VarSpec(itT));
            Pre.Add(env + " = " + en);
            FlushTo(lines, ind);
            var brk = LoopLabel(fe.ExitLabel);
            var cont = LoopLabel(fe.ContinueLabel);
            lines.Add(p + "do");
            var eq = ((INamedTypeSymbol)itT).GetMembers("op_Equality").OfType<IMethodSymbol>().First();
            var inc = ((INamedTypeSymbol)itT).GetMembers("op_Increment").OfType<IMethodSymbol>().First();
            var deref = ((INamedTypeSymbol)itT).GetMembers("Deref").OfType<IPropertySymbol>().First().GetMethod!;
            var stop = RtCallValue(eq, null, new List<string> { itv, env }, eq.ReturnType);
            FlushTo(lines, ind + 1);
            lines.Add(Ind(ind + 1) + "if (" + stop + ") exit");
            // the element
            var loc = vd.Symbol;
            var n = LocalName(loc.Name);
            bool refT = IsRefType(loc.Type);
            Decls.Add(VarSpec(loc.Type) + " :: " + n);
            vars[loc] = new VarInfo { D = n, K = refT ? 'P' : 'V', T = loc.Type };
            if (cells.Contains(loc) || addr.Contains(loc)) Todo("foreach variable in a cell");
            var el = RtCallValue(deref, itv, new List<string>(), loc.Type);
            FlushTo(lines, ind + 1);
            lines.Add(Ind(ind + 1) + n + (refT ? " => " : " = ") + el);
            Sub(fe.Body, lines, ind + 1);
            if (usedLabels.Contains(cont)) lines.Add(Ind(ind + 1) + cont + " continue");
            var nx = RtCallValue(inc, null, new List<string> { itv }, itT);
            FlushTo(lines, ind + 1);
            lines.Add(Ind(ind + 1) + itv + " = " + nx);
            lines.Add(p + "end do");
            if (usedLabels.Contains(brk)) lines.Add(p + brk + " continue");
        }

        static IMethodSymbol? FindMember(INamedTypeSymbol t, string name)
        {
            for (var x = t; x != null; x = x.BaseType)
            {
                var m = x.GetMembers(name).OfType<IMethodSymbol>().FirstOrDefault(mm => mm.Parameters.Length == 0);
                if (m != null) return m;
            }
            return null;
        }

        void Branch(IBranchOperation br, List<string> lines, int ind)
        {
            if (!labels.TryGetValue(br.Target, out var l)) { Todo("branch to an unknown label"); return; }
            JumpTo(lines, ind, l);
        }

        // -------------------------------------------------------------------------------------------- switch
        void Switch(ISwitchOperation sw, List<string> lines, int ind)
        {
            var p = Ind(ind);
            var vt = sw.Value.Type!;
            var v = Value(sw.Value, null);
            FlushTo(lines, ind);
            if (PrimCode(vt) is not ("i" or "l" or "s" or "c" or "b")) { Todo("switch on " + vt.ToDisplayString()); return; }
            var brk = LoopLabel(sw.ExitLabel);
            lines.Add(p + "select case (" + v + ")");
            foreach (var c in sw.Cases)
            {
                bool def = c.Clauses.Any(cl => cl is IDefaultCaseClauseOperation);
                if (def) lines.Add(p + "case default");
                else
                {
                    var vals = new List<string>();
                    foreach (var cl in c.Clauses)
                    {
                        if (cl is ISingleValueCaseClauseOperation sv && sv.Value.ConstantValue.HasValue) vals.Add(Const(sv.Value.ConstantValue.Value, vt));
                        else Todo("case clause " + cl.CaseKind);
                    }
                    lines.Add(p + "case (" + string.Join(", ", vals) + ")");
                }
                var body = c.Body.ToList();
                // a section's final break is the end of the Fortran case
                if (body.Count > 0 && body[^1] is IBranchOperation lb && lb.BranchKind == BranchKind.Break && SEq.Equals(lb.Target, sw.ExitLabel)) body.RemoveAt(body.Count - 1);
                Block(body, lines, ind + 1);
            }
            lines.Add(p + "end select");
            if (usedLabels.Contains(brk)) lines.Add(p + brk + " continue");
        }

        // -------------------------------------------------------------------------------------------- try
        readonly Stack<string> rethrowVar = new();

        string Rethrow() => rethrowVar.Count > 0 ? rethrowVar.Peek() : Todo("throw; outside a catch");

        void Try(ITryOperation t, List<string> lines, int ind)
        {
            var p = Ind(ind);
            Region? reg = null;
            if (t.Finally != null)
            {
                reg = new Region { FinLabel = NewLabel(), CodeVar = Tmp("integer(4)"), Depth = regions.Count };
                lines.Add(p + reg.CodeVar + " = 0");
                regions.Add(reg);
                excTargets.Push(reg.FinLabel.ToString());
            }
            int catchLabel = 0, after = NewLabel();
            labelDepth[after] = regions.Count;
            if (t.Catches.Length > 0) { catchLabel = NewLabel(); excTargets.Push(catchLabel.ToString()); }
            Block(t.Body.Operations, lines, ind);
            if (t.Catches.Length > 0)
            {
                excTargets.Pop();
                lines.Add(p + "goto " + after);
                usedLabels.Add(after);
                lines.Add(p + catchLabel + " continue");
                var ex = Tmp("class(cpp_object), pointer");
                lines.Add(p + ex + " => cpp_exc");
                foreach (var cc in t.Catches)
                {
                    var et = cc.ExceptionType;
                    bool all = et.SpecialType == SpecialType.System_Object || et is INamedTypeSymbol en && IsSystem(en) && en.Name == "Exception";
                    string test = all ? ".true." : IsTest(ex, "cpp_object", et);
                    lines.Add(p + "if (" + test + ") then");
                    lines.Add(Ind(ind + 1) + "cpp_exc => null()");
                    if (cc.ExceptionDeclarationOrExpression is IVariableDeclaratorOperation vd)
                    {
                        var n = LocalName(vd.Symbol.Name);
                        var vt = vd.Symbol.Type;
                        Decls.Add(VarSpec(vt) + " :: " + n);
                        vars[vd.Symbol] = new VarInfo { D = n, K = 'P', T = vt };
                        if (cells.Contains(vd.Symbol) || addr.Contains(vd.Symbol)) Note("caught exception in a cell (read as a copy)");
                        var cv = all ? ex : Cast("cpp_object", ex, vt);
                        FlushTo(lines, ind + 1);
                        lines.Add(Ind(ind + 1) + n + " => " + cv);
                    }
                    if (cc.Filter != null) Todo("exception filter");
                    rethrowVar.Push(ex);
                    Block(cc.Handler.Operations, lines, ind + 1);
                    rethrowVar.Pop();
                    lines.Add(Ind(ind + 1) + "goto " + after);
                    lines.Add(p + "end if");
                    if (all) break;
                }
                // no catch matched: the exception goes on
                lines.Add(p + ExcJump());
            }
            lines.Add(p + after + " continue");
            if (reg != null)
            {
                excTargets.Pop();
                regions.RemoveAt(regions.Count - 1);
                var sv = Tmp("class(cpp_object), pointer");
                lines.Add(p + reg.FinLabel + " continue");
                lines.Add(p + sv + " => cpp_exc");
                lines.Add(p + "cpp_exc => null()");
                Block(t.Finally!.Operations, lines, ind);
                lines.Add(p + "if (associated(" + sv + ")) then");
                lines.Add(Ind(ind + 1) + "cpp_exc => " + sv);
                lines.Add(Ind(ind + 1) + ExcJump());
                lines.Add(p + "end if");
                for (int k = 0; k < reg.Targets.Count; k++)
                {
                    lines.Add(p + "if (" + reg.CodeVar + " == " + (k + 1) + ") then");
                    JumpTo(lines, ind + 1, reg.Targets[k]);
                    lines.Add(p + "end if");
                }
            }
        }

        /// <summary>using var x = ...; rest: rest is guarded by a finally that disposes x if it is not null.</summary>
        void UsingRest(IUsingDeclarationOperation ud, List<IOperation> rest, List<string> lines, int ind)
        {
            var decls = ud.DeclarationGroup.Declarations.SelectMany(d => d.Declarators).ToList();
            foreach (var d in ud.DeclarationGroup.Declarations)
                foreach (var v in d.Declarators) LocalDecl(v, d.Initializer, lines, ind);
            Guarded(lines, ind, (ls, i) => Block(rest, ls, i), (ls, i) =>
            {
                foreach (var v in decls.AsEnumerable().Reverse()) Dispose(Read(v.Symbol), v.Symbol.Type, ls, i);
            });
        }

        void Using(IUsingOperation u, List<string> lines, int ind)
        {
            var res = new List<(string, ITypeSymbol)>();
            if (u.Resources is IVariableDeclarationGroupOperation g)
            {
                foreach (var d in g.Declarations)
                    foreach (var v in d.Declarators) { LocalDecl(v, d.Initializer, lines, ind); res.Add((Read(v.Symbol), v.Symbol.Type)); }
            }
            else
            {
                var x = XP(u.Resources);
                var t = Tmp("class(cpp_object), pointer");
                FlushTo(lines, ind);
                lines.Add(Ind(ind) + t + " => " + x);
                res.Add((t, u.Resources.Type!));
            }
            Guarded(lines, ind, (ls, i) => Sub(u.Body, ls, i), (ls, i) =>
            {
                foreach (var (n, t) in res.AsEnumerable().Reverse()) Dispose(n, t, ls, i);
            });
        }

        void Dispose(string n, ITypeSymbol t, List<string> ls, int i)
        {
            var d = n;
            if (!IsDesignator(d)) { d = Tmp(VarSpec(t)); ls.Add(Ind(i) + d + " => " + n); }
            ls.Add(Ind(i) + "if (associated(" + d + ")) then");
            ls.Add(Ind(i + 1) + "call " + d + "%dispose()");
            ls.Add(Ind(i + 1) + "if (associated(cpp_exc)) " + ExcJump());
            ls.Add(Ind(i) + "end if");
        }

        /// <summary>body guarded by fin, as try { body } finally { fin }.</summary>
        void Guarded(List<string> lines, int ind, Action<List<string>, int> body, Action<List<string>, int> fin)
        {
            var p = Ind(ind);
            var reg = new Region { FinLabel = NewLabel(), CodeVar = Tmp("integer(4)"), Depth = regions.Count };
            lines.Add(p + reg.CodeVar + " = 0");
            regions.Add(reg);
            excTargets.Push(reg.FinLabel.ToString());
            body(lines, ind);
            excTargets.Pop();
            regions.RemoveAt(regions.Count - 1);
            var sv = Tmp("class(cpp_object), pointer");
            lines.Add(p + reg.FinLabel + " continue");
            lines.Add(p + sv + " => cpp_exc");
            lines.Add(p + "cpp_exc => null()");
            fin(lines, ind);
            lines.Add(p + "if (associated(" + sv + ")) then");
            lines.Add(Ind(ind + 1) + "cpp_exc => " + sv);
            lines.Add(Ind(ind + 1) + ExcJump());
            lines.Add(p + "end if");
            for (int k = 0; k < reg.Targets.Count; k++)
            {
                lines.Add(p + "if (" + reg.CodeVar + " == " + (k + 1) + ") then");
                JumpTo(lines, ind + 1, reg.Targets[k]);
                lines.Add(p + "end if");
            }
        }

        // -------------------------------------------------------------------------------------------- expression statements
        void StmtExpr(IOperation op, List<string> lines, int ind)
        {
            var p = Ind(ind);
            switch (op)
            {
                case ISimpleAssignmentOperation a:
                    {
                        if (a.IsRef)
                        {
                            var tl = a.Target is ILocalReferenceOperation lr ? Var(lr.Local) : null;
                            if (tl == null) { Todo("ref reassignment of " + a.Target.Kind); return; }
                            var l = RefLoc(a.Value);
                            FlushTo(lines, ind);
                            lines.Add(p + tl.D + " => " + l.D);
                            return;
                        }
                        Assign(a.Target, a.Value, lines, ind);
                        return;
                    }
                case ICompoundAssignmentOperation ca: Compound(ca, lines, ind); return;
                case IIncrementOrDecrementOperation inc:
                    {
                        var s = IncDec(inc, false);
                        FlushTo(lines, ind);
                        return;
                    }
                case IConditionalAccessOperation ca:
                    {
                        var recv = XP(ca.Operation);
                        var r = Dsg(recv, ca.Operation.Type!);
                        FlushTo(lines, ind);
                        lines.Add(p + "if (associated(" + r + ")) then");
                        condAccess.Push(r);
                        StmtExpr(ca.WhenNotNull, lines, ind + 1);
                        condAccess.Pop();
                        lines.Add(p + "end if");
                        return;
                    }
                case IDiscardOperation: return;
                default:
                    {
                        var s = Effect(op);
                        FlushTo(lines, ind);
                        if (s.Length > 0) lines.Add(p + s);
                        return;
                    }
            }
        }

        /// <summary>An expression evaluated for its effects: a call as a statement, anything else into Pre.</summary>
        string Effect(IOperation op)
        {
            if (op is IInvocationOperation inv && inv.TargetMethod.ReturnsVoid)
            {
                Invoke(inv, false, true);
                return "";
            }
            if (op is IConversionOperation cv && cv.Type?.SpecialType == SpecialType.System_Void) return Effect(cv.Operand);
            var v = X(op);
            return "";
        }

        void Assign(IOperation target, IOperation value, List<string> lines, int ind)
        {
            var p = Ind(ind);
            var tt = target.Type!;
            // the target's location is evaluated before the value, as C# does
            var mark = Pre.Count;
            var loc = Place(target);
            var afterTarget = Pre.Count;
            var v = Value(value, tt);
            if (Pre.Count > afterTarget && !IsStableLoc(loc)) loc = Spill(loc, afterTarget);
            FlushTo(lines, ind);
            Store(loc, v, lines, ind);
        }

        void Store(Loc loc, string v, List<string> lines, int ind)
        {
            var p = Ind(ind);
            switch (loc.K)
            {
                case 'V': case 'C': lines.Add(p + loc.D + " = " + v); break;     // C: a byte of a C string (CPtr element)
                case 'P': lines.Add(p + loc.D + " => " + v); break;
                case 'S': lines.Add(p + loc.D + "%p => " + v); break;
                default: throw new global::Todo("store to a location of kind " + loc.K);
            }
        }

        void StorePre(Loc loc, string v)
        {
            switch (loc.K)
            {
                case 'V': case 'C': Pre.Add(loc.D + " = " + v); break;     // C: a byte of a C string (CPtr element)
                case 'P': Pre.Add(loc.D + " => " + v); break;
                case 'S': Pre.Add(loc.D + "%p => " + v); break;
                default: throw new global::Todo("store to a location of kind " + loc.K);
            }
        }
    }
}
