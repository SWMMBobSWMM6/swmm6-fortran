// F90Ops.cs - method bodies, part 3: operators, short-circuit logic, calls (engine, virtual, delegate, runtime,
// system), properties and object and array creation.
// Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Operations;

public static partial class Cs2F90
{
    public sealed partial class F90Fn
    {
        // -------------------------------------------------------------------------------------------- ordered evaluation
        sealed class Arg { public string S = ""; public string? Spec; public bool Ptr; }

        /// <summary>Evaluate the operands in order; when a later one needs statements, the earlier ones that those
        /// statements could change are first copied to temporaries (C# evaluates left to right).</summary>
        List<string> Ordered(List<Func<Arg>> evs)
        {
            var outv = new List<Arg>();
            foreach (var ev in evs)
            {
                int mark = Pre.Count;
                var a = ev();
                if (Pre.Count > mark)
                {
                    var ins = new List<string>();
                    foreach (var o in outv)
                        if (o.Spec != null && !IsStable(o.S) && o.S != "null()")
                        {
                            var t = Tmp(o.Spec);
                            ins.Add(t + (o.Ptr ? " => " : " = ") + o.S);
                            o.S = t;
                        }
                    Pre.InsertRange(mark, ins);
                }
                outv.Add(a);
            }
            return outv.Select(o => o.S).ToList();
        }

        Arg ValArg(IOperation op, ITypeSymbol t)
        {
            var v = Value(op, t);
            if (IsString(t)) return new Arg { S = v };
            if (IsRefType(t)) return new Arg { S = v, Spec = IsObjectLike(t) ? "class(*), pointer" : VarSpec(t), Ptr = true };
            return new Arg { S = v, Spec = VarSpec(t) };
        }

        Arg RefArg(IOperation op)
        {
            var l = RefLoc(op);
            return new Arg { S = l.D, Spec = l.K == 'S' ? "type(cpp_slot), pointer" : VarSpec(l.T) + ", pointer", Ptr = true };
        }

        // -------------------------------------------------------------------------------------------- operators
        string Binary(IBinaryOperation b)
        {
            if (b.OperatorMethod != null)
            {
                if (IsSystem(b.OperatorMethod)) return Todo("system operator " + b.OperatorMethod.ToDisplayString());
                return RtStaticCall(b.OperatorMethod, new List<IOperation> { b.LeftOperand, b.RightOperand });
            }
            var k = b.OperatorKind;
            if (k is BinaryOperatorKind.ConditionalAnd or BinaryOperatorKind.ConditionalOr) return ShortCircuit(b);
            var lt = b.LeftOperand.Type!;
            var rt = b.RightOperand.Type!;
            if (k is BinaryOperatorKind.Equals or BinaryOperatorKind.NotEquals && (IsRefType(lt) || IsRefType(rt) || b.LeftOperand.ConstantValue is { HasValue: true, Value: null } || b.RightOperand.ConstantValue is { HasValue: true, Value: null }))
            {
                var eq = RefEq(b.LeftOperand, b.RightOperand);
                return k == BinaryOperatorKind.Equals ? eq : "(.not. " + eq + ")";
            }
            var ops = Ordered(new List<Func<Arg>> { () => ValArg(b.LeftOperand, lt), () => ValArg(b.RightOperand, rt) });
            return BinOp(k, Under(lt), ops[0], ops[1], Under(rt));
        }

        string BinOp(BinaryOperatorKind k, ITypeSymbol t, string l, string r, ITypeSymbol rt)
        {
            bool boolean = t.SpecialType == SpecialType.System_Boolean;
            bool uns = t.SpecialType is SpecialType.System_UInt32 or SpecialType.System_UInt64;
            bool flt = IsFloat(t);
            int w = Width(t);
            string kind = w == 64 ? "8" : w == 32 ? "4" : w == 16 ? "2" : "1";
            switch (k)
            {
                case BinaryOperatorKind.Add: return "(" + l + " + " + r + ")";
                case BinaryOperatorKind.Subtract: return "(" + l + " - " + r + ")";
                case BinaryOperatorKind.Multiply: return "(" + l + " * " + r + ")";
                case BinaryOperatorKind.Divide:
                    if (uns) return Helper("cpp_udiv" + kind, "unsigned " + (w == 64 ? "ulong" : "uint") + " division", "integer(" + kind + ")", "integer(" + kind + "), value", "integer(" + kind + "), value") + "(" + l + ", " + r + ")";
                    return "(" + l + " / " + r + ")";
                case BinaryOperatorKind.Remainder:
                    if (flt) return Helper("cpp_frem" + (t.SpecialType == SpecialType.System_Double ? "d" : "f"), "C# % of floating-point numbers (C fmod)", PrimSpec(PrimCode(t)!), PrimSpec(PrimCode(t)!) + ", value", PrimSpec(PrimCode(t)!) + ", value") + "(" + l + ", " + r + ")";
                    if (uns) return Helper("cpp_urem" + kind, "unsigned " + (w == 64 ? "ulong" : "uint") + " remainder", "integer(" + kind + ")", "integer(" + kind + "), value", "integer(" + kind + "), value") + "(" + l + ", " + r + ")";
                    return "mod(" + l + ", " + r + ")";
                case BinaryOperatorKind.And: return boolean ? "(" + l + " .and. " + r + ")" : "iand(" + l + ", " + r + ")";
                case BinaryOperatorKind.Or: return boolean ? "(" + l + " .or. " + r + ")" : "ior(" + l + ", " + r + ")";
                case BinaryOperatorKind.ExclusiveOr: return boolean ? "(" + l + " .neqv. " + r + ")" : "ieor(" + l + ", " + r + ")";
                case BinaryOperatorKind.LeftShift: return "shiftl(" + l + ", " + ShiftCount(r, w) + ")";
                case BinaryOperatorKind.RightShift: return (uns ? "shiftr(" : "shifta(") + l + ", " + ShiftCount(r, w) + ")";
                case BinaryOperatorKind.UnsignedRightShift: return "shiftr(" + l + ", " + ShiftCount(r, w) + ")";
                case BinaryOperatorKind.Equals: return boolean ? "(" + l + " .eqv. " + r + ")" : "(" + l + " == " + r + ")";
                case BinaryOperatorKind.NotEquals: return boolean ? "(" + l + " .neqv. " + r + ")" : "(" + l + " /= " + r + ")";
                case BinaryOperatorKind.LessThan: case BinaryOperatorKind.LessThanOrEqual: case BinaryOperatorKind.GreaterThan: case BinaryOperatorKind.GreaterThanOrEqual:
                    {
                        var op = k switch { BinaryOperatorKind.LessThan => " < ", BinaryOperatorKind.LessThanOrEqual => " <= ", BinaryOperatorKind.GreaterThan => " > ", _ => " >= " };
                        if (uns)
                        {
                            // unsigned order: flip the sign bit
                            var sb = w == 64 ? "(-9223372036854775807_8 - 1_8)" : "(-2147483647 - 1)";
                            return "(ieor(" + l + ", " + sb + ")" + op + "ieor(" + r + ", " + sb + "))";
                        }
                        return "(" + l + op + r + ")";
                    }
            }
            return Todo("operator " + k);
        }

        static string ShiftCount(string r, int w)
        {
            int mask = w == 64 ? 63 : 31;
            if (int.TryParse(r, out var c)) return (c & mask).ToString();
            return "iand(" + r + ", " + mask + ")";
        }

        /// <summary>a && b and a || b, left to right with b evaluated only when C# would: .and./.or. when b is a
        /// safe expression with no statements, else nested IFs on a logical temporary (lesson 04 of the SWMM5 ports).</summary>
        string ShortCircuit(IBinaryOperation b)
        {
            bool and = b.OperatorKind == BinaryOperatorKind.ConditionalAnd;
            var a = Cond(b.LeftOperand);
            var saved = Pre; Pre = new List<string>();
            var c = Cond(b.RightOperand);
            var pb = Pre; Pre = saved;
            // C# always evaluates a; Fortran may evaluate c too (or first), which is harmless when c cannot fault
            if (pb.Count == 0 && IsSafe(c)) return "(" + a + (and ? " .and. " : " .or. ") + c + ")";
            var t = Tmp("logical");
            Pre.Add(t + " = " + a);
            Pre.Add("if (" + (and ? t : ".not. " + t) + ") then");
            foreach (var s in pb) Pre.Add("  " + s);
            Pre.Add("  " + t + " = " + c);
            Pre.Add("end if");
            return t;
        }

        string RefEq(IOperation a, IOperation b)
        {
            static IOperation Strip(IOperation o)
            {
                while (o is IConversionOperation c && c.OperatorMethod == null && IsRefType(c.Type!) && c.Operand.Type != null && IsRefType(c.Operand.Type)) o = c.Operand;
                return o;
            }
            var sa = Strip(a); var sb = Strip(b);
            bool na = sa.ConstantValue is { HasValue: true, Value: null } || sa is IDefaultValueOperation;
            bool nb = sb.ConstantValue is { HasValue: true, Value: null } || sb is IDefaultValueOperation;
            if (na && nb) return ".true.";
            if (na || nb)
            {
                var o = na ? sb : sa;
                if (o.Type != null && !IsRefType(o.Type)) return ".false.";
                var x = X(o);
                if (x == "self" || x == "null()") return x == "self" ? ".false." : ".true.";
                x = DsgSpec(x, PtrSpec(o.Type!), true);
                return "(.not. associated(" + x + "))";
            }
            var ops = Ordered(new List<Func<Arg>> { () => new Arg { S = X(sa), Spec = PtrSpec(sa.Type!), Ptr = true }, () => new Arg { S = X(sb), Spec = PtrSpec(sb.Type!), Ptr = true } });
            string pa = ops[0], pb = ops[1];
            var ta = sa.Type!; var tb = sb.Type!;
            // associated(p, t) needs t assignable to p: the more general type goes first
            string first, second;
            if (EngineFT(ta).Name == EngineFT(tb).Name || ta is INamedTypeSymbol na2 && tb is INamedTypeSymbol nb2 && Derives(nb2, na2)) { first = pa; second = pb; }
            else if (ta is INamedTypeSymbol na3 && tb is INamedTypeSymbol nb3 && Derives(na3, nb3)) { first = pb; second = pa; }
            else { first = ToErased(pa, ta); second = ToErased(pb, tb); }
            if (first == "self") { first = Tmp(PtrSpec(ta)); Pre.Add(first + " => self"); }
            first = DsgSpec(first, PtrSpec(ta), true); second = DsgSpec(second, PtrSpec(tb), true);
            return "(associated(" + first + ", " + second + ") .or. (.not. associated(" + first + ") .and. .not. associated(" + second + ")))";
        }

        static string PtrSpec(ITypeSymbol t) => IsObjectLike(t) ? "class(*), pointer" : VarSpec(t);

        string Unary(IUnaryOperation u)
        {
            if (u.OperatorMethod != null) return RtStaticCall(u.OperatorMethod, new List<IOperation> { u.Operand });
            var o = X(u.Operand);
            return u.OperatorKind switch
            {
                UnaryOperatorKind.Minus => "(-" + o + ")",
                UnaryOperatorKind.Plus => o,
                UnaryOperatorKind.BitwiseNegation => "not(" + o + ")",
                UnaryOperatorKind.Not => "(.not. " + o + ")",
                _ => Todo("unary " + u.OperatorKind)
            };
        }

        string Ternary(IConditionalOperation c)
        {
            if (c.IsRef) return ReadLoc(RefConditional(c));
            var t = c.Type!;
            var cond = Cond(c.Condition);
            var saved = Pre; Pre = new List<string>();
            var a = Value(c.WhenTrue, t); var pa = Pre; Pre = new List<string>();
            var b = Value(c.WhenFalse!, t); var pb = Pre; Pre = saved;
            bool refT = IsRefType(t);
            if (!refT && pa.Count == 0 && pb.Count == 0 && IsSafe(a) && IsSafe(b) && PrimCode(t) != null && !a.Contains("null()"))
                return "merge(" + a + ", " + b + ", " + cond + ")";
            var tv = Tmp(PtrSpecOrVal(t));
            Pre.Add("if (" + cond + ") then");
            foreach (var s in pa) Pre.Add("  " + s);
            Pre.Add("  " + tv + (refT ? " => " : " = ") + a);
            Pre.Add("else");
            foreach (var s in pb) Pre.Add("  " + s);
            Pre.Add("  " + tv + (refT ? " => " : " = ") + b);
            Pre.Add("end if");
            return tv;
        }

        static string PtrSpecOrVal(ITypeSymbol t) => IsRefType(t) ? PtrSpec(t) : VarSpec(t);

        string CondAccess(IConditionalAccessOperation ca)
        {
            var recv = X(ca.Operation);
            var r = Dsg(recv, ca.Operation.Type!);
            var t = ca.Type!;
            var tv = Tmp(PtrSpecOrVal(t));
            bool refT = IsRefType(t);
            Pre.Add(tv + (refT ? " => null()" : " = " + DefaultOf(t)));
            Pre.Add("if (associated(" + r + ")) then");
            condAccess.Push(r);
            var saved = Pre; Pre = new List<string>();
            var inner = Value(ca.WhenNotNull, t);
            var pi = Pre; Pre = saved;
            condAccess.Pop();
            foreach (var s in pi) Pre.Add("  " + s);
            Pre.Add("  " + tv + (refT ? " => " : " = ") + inner);
            Pre.Add("end if");
            return tv;
        }

        // -------------------------------------------------------------------------------------------- compound and ++
        void Compound(ICompoundAssignmentOperation ca, List<string> lines, int ind)
        {
            CompoundValue(ca);
            FlushTo(lines, ind);
        }

        string CompoundValue(ICompoundAssignmentOperation ca)
        {
            var tt = ca.Target.Type!;
            var loc = Place(ca.Target);
            var after = Pre.Count;
            var cur = ReadLoc(loc);
            string nv;
            if (ca.OperatorMethod != null)
            {
                var v = X(ca.Value);
                if (Pre.Count > after && !IsStableLoc(loc)) { loc = Spill(loc, after); cur = ReadLoc(loc); }
                nv = RtStaticCallStr(ca.OperatorMethod, new List<(string, ITypeSymbol)> { (cur, tt), (v, ca.Value.Type!) });
            }
            else
            {
                if (IsString(tt)) return Todo("string +=");
                var opT = ca.InConversion.Exists && !ca.InConversion.IsIdentity ? ca.Value.Type! : tt;
                var v = X(ca.Value);
                if (Pre.Count > after && !IsStableLoc(loc)) { loc = Spill(loc, after); cur = ReadLoc(loc); }
                var l = Conv(cur, tt, opT);
                nv = Conv(BinOp(ca.OperatorKind, Under(opT), l, v, Under(ca.Value.Type!)), opT, tt);
            }
            if (loc.K == 'C') nv = "int(" + nv + ", 1)";
            var t = Tmp(VarSpec(tt));
            Pre.Add(t + " = " + nv);
            StorePre(loc, t);
            return t;
        }

        string IncDec(IIncrementOrDecrementOperation inc, bool asValue)
        {
            var up = inc.Kind == OperationKind.Increment;
            var tt = inc.Target.Type!;
            var loc = Place(inc.Target);
            var cur = ReadLoc(loc);
            string nv;
            if (inc.OperatorMethod != null) nv = RtStaticCallStr(inc.OperatorMethod, new List<(string, ITypeSymbol)> { (cur, tt) });
            else
            {
                var u = Under(tt);
                if (loc.K == 'C') { nv = "int(" + cur + (up ? " + 1" : " - 1") + ", 1)"; }
                else
                {
                    var one = IsFloat(u) ? (u.SpecialType == SpecialType.System_Double ? "1.0_8" : "1.0_4") : Width(u) switch { 64 => "1_8", 16 => "1_2", 8 => "1_1", _ => "1" };
                    nv = "(" + cur + (up ? " + " : " - ") + one + ")";
                }
            }
            if (!asValue) { StorePre(loc, nv); return ""; }
            var t = Tmp(VarSpec(tt));
            if (inc.IsPostfix)
            {
                Pre.Add(t + " = " + cur);
                StorePre(loc, nv);
            }
            else
            {
                Pre.Add(t + " = " + nv);
                StorePre(loc, t);
            }
            return t;
        }

        // -------------------------------------------------------------------------------------------- calls
        string Invoke(IInvocationOperation inv, bool asRef, bool asStmt)
        {
            var m = inv.TargetMethod;
            if (m.MethodKind == MethodKind.DelegateInvoke) return DelegateInvoke(inv, asRef, asStmt, out _);
            if (IsSystem(m)) return SystemCall(inv);
            if (IsRuntime(m)) return RtCall(m, "", inv.Instance, inv.Arguments, asStmt, asRef, out _);
            return EngineCall(inv, asRef, asStmt, out _);
        }

        Loc RefCall(IInvocationOperation inv)
        {
            var m = inv.TargetMethod;
            Loc? loc;
            if (m.MethodKind == MethodKind.DelegateInvoke) DelegateInvoke(inv, true, false, out loc);
            else if (IsRuntime(m)) RtCall(m, "", inv.Instance, inv.Arguments, false, true, out loc);
            else EngineCall(inv, true, false, out loc);
            return loc ?? new Loc(Todo("ref call"), 'V', m.ReturnType);
        }

        string EngineCall(IInvocationOperation inv, bool asRef, bool asStmt, out Loc? loc)
        {
            loc = null;
            var m = inv.TargetMethod;
            bool baseCall = inv.Instance is IInstanceReferenceOperation && inv.Instance.Syntax is BaseExpressionSyntax;
            bool virt = IsVirtualish(m) && !baseCall;
            var evs = new List<Func<Arg>>();
            if (!m.IsStatic) evs.Add(() => { var r = Recv(inv.Instance!); return new Arg { S = r, Spec = VarSpec(inv.Instance!.Type!), Ptr = true }; });
            foreach (var a in inv.Arguments.OrderBy(a => a.Parameter!.Ordinal))
            {
                var prm = a.Parameter!;
                if (prm.RefKind != RefKind.None) evs.Add(() => RefArg(a.Value));
                else evs.Add(() => ValArg(a.Value, prm.Type));
            }
            var vals = Ordered(evs);
            string text;
            if (virt)
            {
                var recv = vals[0];
                if (!IsDesignator(recv)) recv = Dsg(recv, inv.Instance!.Type!);
                text = recv + "%" + BindingName(m) + "(" + string.Join(", ", vals.Skip(1)) + ")";
            }
            else text = MethodName(m) + "(" + string.Join(", ", vals) + ")";
            return Result(text, m.ReturnsVoid, m.ReturnType, m.RefKind != RefKind.None, Throws(m), IsPure(m) && !virt, asStmt, asRef, out loc);
        }

        /// <summary>The value (or, asRef, the location) a call text gives: a statement for a subroutine, a temporary
        /// unless the call is pure and gives a number.</summary>
        string Result(string text, bool isVoid, ITypeSymbol rt, bool refRet, bool throws, bool isPure, bool asStmt, bool asRef, out Loc? loc)
        {
            loc = null;
            if (isVoid)
            {
                Pre.Add("call " + text);
                Check(throws);
                return "";
            }
            if (refRet)
            {
                bool refT = IsRefType(rt);
                if (refT) UseSlot();
                var p = Tmp(refT ? "type(cpp_slot), pointer" : VarSpec(rt) + ", pointer");
                Pre.Add(p + " => " + text);
                Check(throws);
                loc = new Loc(p, refT ? 'S' : 'V', rt);
                return asRef ? "" : ReadLoc(loc);
            }
            if (IsRefType(rt))
            {
                var p = Tmp(PtrSpec(rt));
                Pre.Add(p + " => " + text);
                Check(throws);
                return p;
            }
            if (isPure && !throws && !asStmt) return text;
            var t = Tmp(VarSpec(rt));
            Pre.Add(t + " = " + text);
            Check(throws);
            return t;
        }

        string DelegateInvoke(IInvocationOperation inv, bool asRef, bool asStmt, out Loc? loc)
        {
            loc = null;
            var m = inv.TargetMethod;
            var dt = (INamedTypeSymbol)m.ContainingType;
            var od = dt.OriginalDefinition.DelegateInvokeMethod!;
            bool erased = ErasedDelegate(dt);
            var evs = new List<Func<Arg>>();
            evs.Add(() => { var r = Recv(inv.Instance!); return new Arg { S = r, Spec = VarSpec(dt), Ptr = true }; });
            foreach (var a in inv.Arguments.OrderBy(a => a.Parameter!.Ordinal))
            {
                var prm = a.Parameter!;
                var orig = od.Parameters[prm.Ordinal].Type;
                bool er = erased && orig is ITypeParameterSymbol && PrimCode(prm.Type) == null;
                if (prm.RefKind != RefKind.None) evs.Add(() => RefArg(a.Value));
                else if (er) evs.Add(() => { var v = Value(a.Value, prm.Type); return new Arg { S = ToErased(v, prm.Type), Spec = "class(*), pointer", Ptr = true }; });
                else evs.Add(() => ValArg(a.Value, prm.Type));
            }
            var vals = Ordered(evs);
            var text = vals[0] + "%invoke(" + string.Join(", ", vals.Skip(1)) + ")";
            bool throws = throwingDelegates.Contains(dt.OriginalDefinition) || !IsEngine(dt);
            bool erRes = erased && od.ReturnType is ITypeParameterSymbol && PrimCode(m.ReturnType) == null && !m.ReturnsVoid;
            if (erRes) return ErasedResult(text, m.ReturnType, m.RefKind != RefKind.None, throws, out loc, asRef);
            return Result(text, m.ReturnsVoid, m.ReturnType, m.RefKind != RefKind.None, throws, false, asStmt, asRef, out loc);
        }

        /// <summary>A call whose result is erased: a class(*) pointer (or a cpp_slot pointer for a ref), seen as rt.</summary>
        string ErasedResult(string text, ITypeSymbol rt, bool refRet, bool throws, out Loc? loc, bool asRef = false)
        {
            loc = null;
            if (refRet)
            {
                UseSlot();
                var sp = Tmp("type(cpp_slot), pointer");
                Pre.Add(sp + " => " + text);
                Check(throws);
                if (IsRefType(rt)) { loc = new Loc(sp, 'S', rt); return asRef ? "" : ReadLoc(loc); }
                var vp = Tmp(VarSpec(rt) + ", pointer");
                Pre.Add(vp + " => " + HRef(rt) + "(" + sp + "%p)");
                loc = new Loc(vp, 'V', rt);
                return vp;
            }
            var p = Tmp("class(*), pointer");
            Pre.Add(p + " => " + text);
            Check(throws);
            if (PrimCode(rt) != null || IsStructType(rt)) return UnboxRef(p, rt);
            return Cast("*", p, rt);
        }

        // ---- runtime
        /// <summary>A call of a runtime member (method, constructor kind "new"/"ctor", accessor).</summary>
        string RtCall(IMethodSymbol m, string kind, IOperation? inst, IReadOnlyList<IArgumentOperation> argOps, bool asStmt, bool asRef, out Loc? loc)
        {
            loc = null;
            var special = RtSpecial(m, inst, argOps, asRef, ref loc);
            if (special != null) return special;
            var s = RtSignature(m, kind);
            var evs = new List<Func<Arg>>();
            if (s.Self && kind == "ctor") evs.Add(() => new Arg { S = "self" });
            else if (s.Self) evs.Add(() => { var r = Recv(inst!); return new Arg { S = r, Spec = VarSpec(inst!.Type!), Ptr = !s.StructSelf }; });
            int nva = 0;
            var ordered = argOps.OrderBy(a => a.Parameter!.Ordinal).ToList();
            int pi = 0;
            foreach (var a in ordered)
            {
                var rp = s.Params[pi++];
                var prm = a.Parameter!;
                switch (rp.Kind)
                {
                    case PK.VarArgs:
                        if (a.Value is IArrayCreationOperation ac && ac.Initializer != null)
                            foreach (var e in ac.Initializer.ElementValues) { nva++; var ee = e; evs.Add(() => VarArg(ee)); }
                        else return Todo("varargs from an array");
                        break;
                    case PK.Str:
                        evs.Add(() => new Arg { S = StrArg(a.Value) });
                        break;
                    case PK.Ref:
                        {
                            var rp0 = rp;
                            evs.Add(() =>
                            {
                                var l = RefLoc(a.Value);
                                if (rp0.T.Kind == "erased" && l.K != 'S') Todo("ref of an erased value");
                                return new Arg { S = l.D, Spec = l.K == 'S' ? "type(cpp_slot), pointer" : VarSpec(l.T) + ", pointer", Ptr = true };
                            });
                            break;
                        }
                    default:
                        {
                            var rp0 = rp;
                            evs.Add(() => RtValArg(a.Value, prm.Type, rp0));
                            break;
                        }
                }
            }
            // makers and copy modes of an erased container
            var tail = new List<string>();
            for (; pi < s.Params.Count; pi++)
            {
                var rp = s.Params[pi];
                if (rp.Kind == PK.Maker) tail.Add(HMk(TaAt(rp, m.ContainingType, m)));
                else if (rp.Kind == PK.Mode) tail.Add(ModeOf(m.ContainingType, TaAt(rp, m.ContainingType, m)).ToString());
            }
            if (nva > 40) Todo("more than 40 varargs");
            varArgsMax = Math.Max(varArgsMax, nva);
            var vals = Ordered(evs);
            vals.AddRange(tail);
            var text = s.Name + "(" + string.Join(", ", vals) + ")";
            if (kind == "ctor") { Pre.Add("call " + text); Check(s.Throws); return ""; }
            if (!s.Func) { Pre.Add("call " + text); Check(s.Throws); return ""; }
            var rt = kind == "new" ? m.ContainingType : m.ReturnType;
            if (s.Result!.Kind == "erased" && !IsObjectLike(rt) || s.RefResult && s.Result.Kind == "erased") return ErasedResult(text, rt, s.RefResult, s.Throws, out loc, asRef);
            if (s.Result.Kind == "ref" && EngineFT(rt).Name != s.Result.Name && IsRefType(rt))
            {
                // the runtime returns a more general type than C# sees (an erased delegate, a base class)
                var p0 = Tmp("class(" + s.Result.Name + "), pointer");
                Pre.Add(p0 + " => " + text);
                Check(s.Throws);
                if (rtTypes.TryGetValue(s.Result.Name, out var rtt) && rtt.Delegate) return Todo("an erased delegate seen as " + rt.ToDisplayString());
                return Cast(s.Result.Name, p0, rt);
            }
            return Result(text, false, rt, s.RefResult, s.Throws, s.Pure, asStmt, asRef, out loc);
        }

        /// <summary>A value argument for a runtime parameter: boxed or upcast to class(*) when erased; a lambda made
        /// with the parameter's delegate type when that is erased.</summary>
        Arg RtValArg(IOperation v, ITypeSymbol t, RtParam rp)
        {
            if (rp.T.Kind == "erased")
            {
                var x = Value(v, t);
                return new Arg { S = ToErased(x, t), Spec = "class(*), pointer", Ptr = true };
            }
            if (rp.T.Kind == "ref" && rtTypes.TryGetValue(rp.T.Name, out var rtt) && rtt.Delegate && EngineFT(t).Name != rp.T.Name)
            {
                var src = v;
                while (src is IConversionOperation cv && cv.OperatorMethod == null) src = cv.Operand;
                if (src is IAnonymousFunctionOperation af) return new Arg { S = Lambda(af, (INamedTypeSymbol)t, rp.T.Name), Spec = "class(" + rp.T.Name + "), pointer", Ptr = true };
                if (src is IDelegateCreationOperation dc) return new Arg { S = DelegateCreation(dc, rp.T.Name), Spec = "class(" + rp.T.Name + "), pointer", Ptr = true };
                if (src.ConstantValue is { HasValue: true, Value: null } || src is IDefaultValueOperation) return new Arg { S = "null()" };
                Todo("a delegate value passed where the runtime erases its type");
            }
            if (rp.T.Kind is "ref" && IsObjectLike(t)) Todo("an object passed as " + rp.T.Name);
            return ValArg(v, t);
        }

        Arg VarArg(IOperation e)
        {
            var src = e is IConversionOperation cv && cv.IsImplicit && cv.Type?.SpecialType == SpecialType.System_Object ? cv.Operand : e;
            var st = src.Type != null ? Under(src.Type) : null;
            var v = X(src);
            string Wrap(string ty) { UseType(ty, "an unsigned vararg: component v", null); return ty + "(" + v + ")"; }
            if (st == null) return new Arg { S = v };
            switch (st.SpecialType)
            {
                case SpecialType.System_UInt32: return new Arg { S = Wrap("cpp_u32"), Spec = "type(cpp_u32)" };
                case SpecialType.System_UInt64: return new Arg { S = Wrap("cpp_u64"), Spec = "type(cpp_u64)" };
                case SpecialType.System_Byte: return new Arg { S = Wrap("cpp_u8"), Spec = "type(cpp_u8)" };
                case SpecialType.System_UInt16: case SpecialType.System_Char: return new Arg { S = Wrap("cpp_u16"), Spec = "type(cpp_u16)" };
            }
            if (PrimCode(st) != null || IsStructType(st)) return new Arg { S = v, Spec = VarSpec(st) };
            if (v == "null()") { Todo("a null vararg"); return null!; }
            return new Arg { S = Dsg(v, st), Spec = PtrSpec(st), Ptr = true };
        }

        /// <summary>The copy mode of an erased type argument t of runtime class ct (see the manifest header).</summary>
        static int ModeOf(INamedTypeSymbol ct, ITypeSymbol t)
        {
            bool key = StripArity(ct.Name) is "Map" or "UMap" or "UMapC" or "Set" or "USet" or "USetC" && SEq.Equals(t, ct.TypeArguments[0]);
            if (PrimCode(t) != null || IsStructType(t)) return 0;
            if (t is IArrayTypeSymbol) return key ? 1 : 3;
            bool icopy = t is INamedTypeSymbol n && n.AllInterfaces.Any(i => IsRuntime(i) && StripArity(i.Name) == "ICopy" && SEq.Equals(i.TypeArguments[0], t));
            if (!icopy) return 1;
            if (key) return IsRuntime(t) ? 2 : 1;
            return 2;
        }

        /// <summary>A C# string argument (a runtime member's string parameter): a character constant, or a
        /// deferred-length character temporary for a conditional of strings or Str.ToString().</summary>
        string StrArg(IOperation op)
        {
            while (op is IConversionOperation cv && cv.Type?.SpecialType == SpecialType.System_String) op = cv.Operand;
            if (op.ConstantValue is { HasValue: true, Value: string str }) return FStr(str);
            if (op is IConditionalOperation c)
            {
                var cond = Cond(c.Condition);
                var t = Tmp("character(len=:), allocatable");
                var saved = Pre; Pre = new List<string>();
                var a = StrArg(c.WhenTrue); var pa = Pre; Pre = new List<string>();
                var b = StrArg(c.WhenFalse!); var pb = Pre; Pre = saved;
                Pre.Add("if (" + cond + ") then");
                foreach (var x in pa) Pre.Add("  " + x);
                Pre.Add("  " + t + " = " + a);
                Pre.Add("else");
                foreach (var x in pb) Pre.Add("  " + x);
                Pre.Add("  " + t + " = " + b);
                Pre.Add("end if");
                return t;
            }
            if (op is IInvocationOperation inv && inv.TargetMethod.Name == "ToString" && inv.Instance != null && inv.Instance.Type is INamedTypeSymbol rt && IsRuntime(rt))
            {
                var r = Recv(inv.Instance);
                var h = Helper(RtTypeName(rt) + "_tostring", rt.ToDisplayString() + ".ToString(): the bytes as a Fortran character string", "character(len=:), allocatable", "class(" + RtTypeName(rt) + "), intent(inout), target");
                var t = Tmp("character(len=:), allocatable");
                Pre.Add(t + " = " + h + "(" + r + ")");
                return t;
            }
            return Todo("a string argument of kind " + op.Kind);
        }

        /// <summary>A static runtime operator or conversion applied to already-ordered operands.</summary>
        string RtStaticCall(IMethodSymbol m, List<IOperation> operands)
        {
            var s = RtSignature(m, "");
            var evs = new List<Func<Arg>>();
            for (int i = 0; i < operands.Count; i++)
            {
                var o = operands[i]; var pt = m.Parameters[i].Type; var rp = s.Params[i];
                evs.Add(() => RtValArg(o, pt, rp));
            }
            var vals = Ordered(evs);
            vals.AddRange(Tail(s, m, operands.Count));
            return Result(s.Name + "(" + string.Join(", ", vals) + ")", m.ReturnsVoid, m.ReturnType, false, s.Throws, s.Pure, false, false, out _);
        }

        /// <summary>The makers and copy modes after the C# parameters.</summary>
        static List<string> Tail(RtSig s, IMethodSymbol m, int from)
        {
            var ct = m.ContainingType;
            var tail = new List<string>();
            for (int i = from; i < s.Params.Count; i++)
            {
                var rp = s.Params[i];
                if (rp.Kind == PK.Maker) tail.Add(HMk(TaAt(rp, ct, m)));
                else if (rp.Kind == PK.Mode) tail.Add(ModeOf(ct, TaAt(rp, ct, m)).ToString());
            }
            return tail;
        }

        string RtStaticCallStr(IMethodSymbol m, List<(string v, ITypeSymbol t)> args)
        {
            var s = RtSignature(m, "");
            var vals = args.Select((a, i) => s.Params[i].T.Kind == "erased" ? ToErased(a.v, a.t) : a.v).ToList();
            return Result(s.Name + "(" + string.Join(", ", vals) + ")", m.ReturnsVoid, m.ReturnType, false, s.Throws, s.Pure, false, false, out _);
        }

        /// <summary>A runtime call with arguments already translated (used by foreach).</summary>
        string RtCallValue(IMethodSymbol m, string? recv, List<string> args, ITypeSymbol rt)
        {
            var s = RtSignature(m, "");
            var vals = new List<string>();
            if (s.Self) vals.Add(recv!);
            vals.AddRange(args);
            var text = s.Name + "(" + string.Join(", ", vals) + ")";
            if (s.Result!.Kind == "erased" && !IsObjectLike(rt) || s.RefResult && s.Result.Kind == "erased") return ErasedResult(text, rt, s.RefResult, s.Throws, out _);
            return Result(text, false, rt, s.RefResult, s.Throws, s.Pure, false, false, out _);
        }

        /// <summary>Runtime generics with ref T parameters, inlined (a Fortran pointer cannot point at a pointer).</summary>
        string? RtSpecial(IMethodSymbol m, IOperation? inst, IReadOnlyList<IArgumentOperation> argOps, bool asRef, ref Loc? loc)
        {
            var tn = m.ContainingType.Name;
            var args = argOps.OrderBy(a => a.Parameter!.Ordinal).Select(a => a.Value).ToList();
            if (tn == "R" && m.Name == "Comma") { var a0 = X(args[0]); return X(args[1]); }
            if (tn == "R" && m.Name == "Discard") { X(args[0]); return ""; }
            if (tn == "Mv" && m.Name == "Back")
            {
                // Back(v, ref x, box): v, then x = box[0]
                var v = X(args[0]);
                var t0 = Tmp(PtrSpecOrVal(m.ReturnType));
                Pre.Add(t0 + (IsRefType(m.ReturnType) ? " => " : " = ") + v);
                var x = Place(args[1]);
                var box = Recv(args[2]);
                var el = ReadLoc(ElemLoc(box + "%a(0)", m.TypeArguments[1]));
                StorePre(x, el);
                return t0;
            }
            if (tn == "Mv" && m.Name is "Take" or "TakeRef")
            {
                var t = m.TypeArguments[0];
                var x = Place(args[0]);
                var r = Tmp(PtrSpecOrVal(t));
                Pre.Add(r + (IsRefType(t) ? " => " : " = ") + ReadLoc(x));
                StorePre(x, m.Name == "Take" ? MakeTyped(t) : DefaultOf(t));
                return r;
            }
            if (tn == "Mv" && m.Name == "Reset")
            {
                var t = m.TypeArguments[0];
                var p = Place(args[0]);
                var q = X(args[1]);
                var qd = DsgSpec(q, PtrSpec(t), true);
                var old = Tmp(PtrSpec(t));
                Pre.Add(old + " => " + ReadLoc(p));
                StorePre(p, qd);
                var dr = Helper("cpp_dtor_run", "Cpp.Dtor.Run(object): Dispose, DestroyElems, or each array element", "", "class(*), pointer, intent(in)");
                var oa = ToErased(old, t);
                Pre.Add("if (associated(" + old + ")) then");
                Pre.Add("  if (.not. associated(" + old + ", " + qd + ")) then");
                Pre.Add("    call " + dr + "(" + oa + ")");
                Pre.Add("    if (associated(cpp_exc)) " + ExcJump());
                Pre.Add("  end if");
                Pre.Add("end if");
                return "";
            }
            if (tn == "Std" && m.Name is "swap" or "exchange" or "release")
            {
                var t = m.TypeArguments[0];
                var a = Place(args[0]);
                var tmpv = Tmp(PtrSpecOrVal(t));
                bool rf = IsRefType(t);
                Pre.Add(tmpv + (rf ? " => " : " = ") + ReadLoc(a));
                if (m.Name == "swap")
                {
                    var b = Place(args[1]);
                    StorePre(a, ReadLoc(b));
                    StorePre(b, tmpv);
                    return "";
                }
                if (m.Name == "exchange") { var v = Value(args[1], t); StorePre(a, v); }
                else StorePre(a, DefaultOf(t));
                return tmpv;
            }
            return null;
        }

        /// <summary>A new default T as Elem&lt;T&gt;.Make makes it (a value: its default; a class with a public
        /// parameterless constructor: a new object; otherwise null).</summary>
        string MakeTyped(ITypeSymbol t)
        {
            if (PrimCode(t) != null || IsStructType(t)) return DefaultOf(t);
            var n = HNew(t);
            var p = Tmp(PtrSpec(t));
            Pre.Add(p + " => " + n + "()");
            return p;
        }

        // ---- system
        string SystemCall(IInvocationOperation inv)
        {
            var m = inv.TargetMethod;
            var t = m.ContainingType.Name;
            var args = inv.Arguments.OrderBy(a => a.Parameter!.Ordinal).ToList();
            if (t == "Object" && m.Name == "ReferenceEquals") return RefEq(args[0].Value, args[1].Value);
            if (t == "File" && m.Name == "Exists")
            {
                var sa = StrArg(args[0].Value);
                return Helper("cpp_file_exists", "System.IO.File.Exists(path)", "logical", "character(len=*), intent(in)") + "(" + sa + ")";
            }
            var ops = Ordered(args.Select(a => (Func<Arg>)(() => ValArg(a.Value, a.Parameter!.Type))).ToList());
            if (t is "Math" or "MathF")
            {
                var pt = m.Parameters.Length > 0 ? m.Parameters[0].Type : m.ReturnType;
                if (m.Name == "Abs" && IsFloat(pt)) return "abs(" + ops[0] + ")";
                if (m.Name == "Sqrt") return "sqrt(" + ops[0] + ")";
                var name = "cpp_math_" + m.Name.ToLowerInvariant() + "_" + string.Join("", m.Parameters.Select(p => PrimCode(p.Type)));
                Helper(name, "System.Math." + m.Name + "(" + string.Join(", ", m.Parameters.Select(p => p.Type.ToDisplayString())) + "), as .NET computes it (libm for the transcendental functions)",
                    PrimSpec(PrimCode(m.ReturnType)!), m.Parameters.Select(p => PrimSpec(PrimCode(p.Type)!) + ", value").ToArray());
                return name + "(" + string.Join(", ", ops) + ")";
            }
            if (t is "Double" or "Single" && m.Name is "IsFinite" or "IsNaN" or "IsInfinity" or "IsPositiveInfinity" or "IsNegativeInfinity" or "IsNegative")
            {
                var c = PrimCode(m.Parameters[0].Type)!;
                var name = "cpp_" + t.ToLowerInvariant() + "_" + m.Name.ToLowerInvariant();
                Helper(name, "System." + t + "." + m.Name, "logical", PrimSpec(c) + ", value");
                return name + "(" + ops[0] + ")";
            }
            if (t == "BitConverter" && m.Name == "DoubleToInt64Bits") return "transfer(" + ops[0] + ", 0_8)";
            if (t == "BitConverter" && m.Name == "Int64BitsToDouble") return "transfer(" + ops[0] + ", 0.0_8)";
            if (t == "BitConverter" && m.Name == "SingleToInt32Bits") return "transfer(" + ops[0] + ", 0)";
            if (t == "BitConverter" && m.Name == "Int32BitsToSingle") return "transfer(" + ops[0] + ", 0.0_4)";
            if (t == "File" && m.Name == "Exists")
            {
                var sa = StrArg(args[0].Value);
                return Helper("cpp_file_exists", "System.IO.File.Exists(path)", "logical", "character(len=*), intent(in)") + "(" + sa + ")";
            }
            if (t == "Array" && m.Name == "Fill")
            {
                var et = ((IArrayTypeSymbol)m.Parameters[0].Type).ElementType;
                var c = PrimCode(et);
                if (c == null) return Todo("Array.Fill of " + et.ToDisplayString());
                var name = Helper("cpp_array_fill_" + c, "System.Array.Fill(T[], T)", "", "class(cpp_arr_" + c + "), pointer, intent(in)", PrimSpec(c) + ", value");
                Pre.Add("call " + name + "(" + string.Join(", ", ops) + ")");
                return "";
            }
            return Todo("system call " + m.ContainingType.ToDisplayString() + "." + m.Name);
        }

        // -------------------------------------------------------------------------------------------- properties
        string Prop(IPropertyReferenceOperation p)
        {
            var ps = p.Property;
            if (IsSystem(ps))
            {
                if (ps.Name == "Length" && ps.ContainingType.SpecialType != SpecialType.System_String) return "size(" + Recv(p.Instance!) + "%a)";
                return Todo("system property " + ps.ContainingType.Name + "." + ps.Name);
            }
            if (!IsRuntime(ps)) return Todo("engine property " + ps.Name);
            var direct = DirectElem(p);
            if (direct != null) return ReadLoc(direct);
            if (ps.RefKind != RefKind.None) return ReadLoc(PropLoc(p));
            return RtCall(ps.GetMethod!, "", p.Instance, p.Arguments, false, false, out _);
        }

        Loc PropLoc(IPropertyReferenceOperation p)
        {
            var ps = p.Property;
            if (!IsRuntime(ps)) return new Loc(Todo("place of a property " + ps.Name), 'V', p.Type!);
            var direct = DirectElem(p);
            if (direct != null) return direct;
            if (ps.RefKind == RefKind.None) return new Loc(Todo("assignment to a property " + ps.ContainingType.Name + "." + ps.Name), 'V', p.Type!);
            RtCall(ps.GetMethod!, "", p.Instance, p.Arguments, false, true, out var loc);
            return loc ?? new Loc(Todo("ref property"), 'V', p.Type!);
        }

        /// <summary>Vector and string elements by their arrays (v%a%a(i)), a C string's char (p%b%a(p%o + i)).</summary>
        Loc? DirectElem(IPropertyReferenceOperation p)
        {
            var ps = p.Property;
            if (!ps.IsIndexer || !IsRuntime(ps)) return null;
            var tn = StripArity(ps.ContainingType.Name);
            if (tn == "Vec" && ps.RefKind != RefKind.None)
            {
                var vt = (INamedTypeSymbol)ps.ContainingType;
                var et = vt.TypeArguments[0];
                var vn = RtFT(vt.OriginalDefinition, vt, ErasureOfType(vt)).Name;
                var an = "cpp_arr_" + (PrimCode(et) ?? "o");
                UseType(an, "array", null);
                UseComponent(vn, "a", "class(" + an + "), pointer :: a => null()");
                UseComponent(vn, "n", "integer(4) :: n = 0");
                var r = Recv(p.Instance!);
                var i = X(p.Arguments[0].Value);
                return ElemLoc(r + "%a%a(" + i + ")", et);
            }
            if (tn == "Str" && ps.RefKind != RefKind.None)
            {
                UseType("cpp_arr_b", "array", null);
                UseComponent("cpp_str", "b", "class(cpp_arr_b), pointer :: b => null()");
                UseComponent("cpp_str", "n", "integer(4) :: n = 0");
                var r = Recv(p.Instance!);
                var i = X(p.Arguments[0].Value);
                return new Loc(r + "%b%a(" + i + ")", 'V', p.Type!);
            }
            if (tn == "CPtr")
            {
                UseType("cpp_arr_b", "array", null);
                UseComponent("cpp_cptr", "b", "class(cpp_arr_b), pointer :: b => null()");
                UseComponent("cpp_cptr", "o", "integer(4) :: o = 0");
                var r = Recv(p.Instance!);
                var i = X(p.Arguments[0].Value);
                return new Loc(r + "%b%a(" + r + "%o + " + i + ")", 'C', p.Type!);
            }
            return null;
        }

        // -------------------------------------------------------------------------------------------- creation
        string New(IObjectCreationOperation oc)
        {
            var t = (INamedTypeSymbol)oc.Type!;
            var c = oc.Constructor!;
            string e;
            if (IsEngine(t))
            {
                var z = Tmp("class(" + TypeName(t) + "), pointer");
                var evs = oc.Arguments.OrderBy(a => a.Parameter!.Ordinal).Select(a => (Func<Arg>)(() => a.Parameter!.RefKind != RefKind.None ? RefArg(a.Value) : ValArg(a.Value, a.Parameter!.Type))).ToList();
                var vals = Ordered(evs);
                Pre.Add("allocate(" + z + ")");
                Pre.Add("call " + CtorName(c) + "(" + string.Join(", ", new[] { z }.Concat(vals)) + ")");
                Check(Throws(c));
                e = z;
            }
            else if (IsRuntime(t))
            {
                e = RtCall(c, "new", null, oc.Arguments, false, false, out _);
                if (IsStructType(t) && !IsDesignator(e) && oc.Initializer != null && oc.Initializer.Initializers.Length > 0) e = Dsg(e, t);
            }
            else if (IsSystem(t) && t.Name.EndsWith("Exception"))
            {
                var msg = oc.Arguments.Length > 0 && oc.Arguments[0].Value.ConstantValue is { HasValue: true, Value: string s } ? FStr(s) : "\"\"";
                var h = Helper("cpp_sysexception_new", "new System.<name>(message): a System exception object", "class(cpp_sysexception), pointer", "character(len=*), intent(in)", "character(len=*), intent(in)");
                UseType("cpp_sysexception", "System exceptions (name and message)", "cpp_object");
                var z = Tmp("class(cpp_sysexception), pointer");
                Pre.Add(z + " => " + h + "(\"" + t.Name + "\", " + msg + ")");
                e = z;
            }
            else return Todo("new " + t.ToDisplayString());
            if (oc.Initializer == null || oc.Initializer.Initializers.Length == 0) return e;
            // new X() { a = 1, b = 2 }: the members are set in order, on the new object
            implicitRecv.Push(e);
            foreach (var init in oc.Initializer.Initializers)
            {
                var saved = Pre; Pre = new List<string>();
                var ls = new List<string>();
                StmtExpr(init, ls, -1);
                ls.AddRange(Pre);
                Pre = saved;
                Pre.AddRange(ls);
            }
            implicitRecv.Pop();
            return e;
        }

        static string CtorName(IMethodSymbol c) => MethodName(c);

        string NewArray(IArrayCreationOperation ac)
        {
            var at = (IArrayTypeSymbol)ac.Type!;
            var et = at.ElementType;
            var an = FName(at);
            var code = PrimCode(et);
            string n;
            if (ac.Initializer != null) n = ac.Initializer.ElementValues.Length + "_8";
            else n = NumConv(X(ac.DimensionSizes[0]), ac.DimensionSizes[0].Type!, comp.GetSpecialType(SpecialType.System_Int64));
            var z = Tmp("class(" + an + "), pointer");
            if (code != null || IsRefType(et))
            {
                var h = Helper(an + "_new", "a new array of n elements (zero, or null slots)", "class(" + an + "), pointer", "integer(8), value");
                Pre.Add(z + " => " + h + "(" + n + ")");
            }
            else
            {
                var h = Helper("cpp_arr_o_new_mk", "a new array of n slots, each holding a new element made by mk (an array of structs)", "class(cpp_arr_o), pointer", "integer(8), value", "procedure(cpp_maker)");
                Pre.Add(z + " => " + h + "(" + n + ", " + HMk(et) + ")");
            }
            if (ac.Initializer == null) return z;
            var vals = ac.Initializer.ElementValues;
            if (code != null && vals.All(v => v.ConstantValue.HasValue) && vals.Length > 0)
            {
                // a table of constants: one array constructor (in pieces, for gfortran's sake)
                var lits = vals.Select(v => Const(v.ConstantValue.Value, et)).ToList();
                for (int i = 0; i < lits.Count; i += 500)
                {
                    var part = lits.Skip(i).Take(500).ToList();
                    Pre.Add(z + "%a(" + i + ":" + (i + part.Count - 1) + ") = [" + PrimSpec(code) + " :: " + string.Join(", ", part) + "]");
                }
                return z;
            }
            for (int i = 0; i < vals.Length; i++)
            {
                var v = Value(vals[i], et);
                if (code != null) Pre.Add(z + "%a(" + i + ") = " + v);
                else if (IsRefType(et)) Pre.Add(z + "%a(" + i + ")%p => " + v);
                else Pre.Add(z + "%a(" + i + ")%p => " + ToErased(v, et));
            }
            return z;
        }
    }
}
