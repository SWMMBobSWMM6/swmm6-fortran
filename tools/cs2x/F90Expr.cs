// F90Expr.cs - method bodies, part 2: expressions. X(op) gives a Fortran expression for a value (a pointer
// designator for a reference value); Place(op) and RefLoc(op) give the location an assignment or a ref binds.
// Statements an expression needs first (calls, assignments, short-circuit tests) go to Pre, in C#'s order.
// Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.Operations;

public static partial class Cs2F90
{
    public sealed partial class F90Fn
    {
        // -------------------------------------------------------------------------------------------- shapes of strings
        static readonly Regex IdRx = new(@"[A-Za-z_][A-Za-z0-9_]*", RegexOptions.Compiled);
        static readonly HashSet<string> Intrinsics = new() { "int", "real", "iand", "ior", "ieor", "not", "shiftl", "shiftr", "shifta", "mod", "abs", "sqrt", "transfer", "null", "logical", "kind", "size", "merge" };

        /// <summary>A Fortran designator: a name followed by %components, each optionally subscripted.</summary>
        static bool IsDesignator(string s)
        {
            int i = 0;
            if (!Name(s, ref i)) return false;
            if (i < s.Length && s[i] == '(') return false;          // a function reference
            while (i < s.Length)
            {
                if (s[i] != '%') return false;
                i++;
                if (!Name(s, ref i)) return false;
                if (i < s.Length && s[i] == '(')
                {
                    int d = 0;
                    for (; i < s.Length; i++) { if (s[i] == '(') d++; else if (s[i] == ')') { d--; if (d == 0) { i++; break; } } }
                    if (d != 0) return false;
                }
            }
            return true;
        }

        static bool Name(string s, ref int i)
        {
            int st = i;
            while (i < s.Length && (char.IsLetterOrDigit(s[i]) || s[i] == '_')) i++;
            return i > st && char.IsLetter(s[st]);
        }

        /// <summary>Can no statement change this value: literals, temporaries, self, never-assigned locals.</summary>
        bool IsStable(string s)
        {
            if (s.Contains('%') || s.Contains('"')) return s == "self" || s.StartsWith("self%") && !s.Substring(5).Contains('%') && false;
            foreach (Match m in IdRx.Matches(s))
            {
                var id = m.Value;
                if (m.Index > 0 && (char.IsDigit(s[m.Index - 1]) || s[m.Index - 1] == '.')) continue;   // kind suffix, exponent, .true.
                if (Intrinsics.Contains(id) || id == "self" || Regex.IsMatch(id, @"^zz\d+$") || Regex.IsMatch(id, @"^\d") || id is "true" or "false" or "e" or "d") continue;
                if (stableNames.Contains(id)) continue;
                return false;
            }
            return true;
        }

        readonly HashSet<string> stableNames = new();

        /// <summary>A Fortran expression that cannot fault or change anything (safe to evaluate even when C#
        /// would not, so a && b may be .and.): literals, locals, temporaries, self%f, arithmetic without division.</summary>
        static bool IsSafe(string s)
        {
            if (s.Contains('"') || s.Replace("/=", "").Contains('/')) return false;      // an integer division may trap
            int i = 0;
            while (i < s.Length)
            {
                if (s[i] == '%')
                {
                    // only self%name
                    int b = i - 1;
                    while (b >= 0 && (char.IsLetterOrDigit(s[b]) || s[b] == '_')) b--;
                    var baseName = s.Substring(b + 1, i - b - 1);
                    if (baseName != "self") return false;
                    i++;
                    while (i < s.Length && (char.IsLetterOrDigit(s[i]) || s[i] == '_')) i++;
                    if (i < s.Length && (s[i] == '%' || s[i] == '(')) return false;
                    continue;
                }
                if (s[i] == '(')
                {
                    int b = i - 1;
                    while (b >= 0 && (char.IsLetterOrDigit(s[b]) || s[b] == '_')) b--;
                    var fn = s.Substring(b + 1, i - b - 1);
                    if (fn.Length > 0 && !(fn is "int" or "real" or "iand" or "ior" or "ieor" or "not" or "abs" or "transfer" or "merge" or "logical")) return false;
                }
                i++;
            }
            return true;
        }

        string Dsg(string s, ITypeSymbol t)
        {
            if (IsDesignator(s)) return s;
            if (s == "null()") return Todo("member access on null");
            var n = Tmp(VarSpec(t));
            Pre.Add(n + (IsRefType(t) ? " => " : " = ") + s);
            return n;
        }

        string DsgSpec(string s, string spec, bool ptr)
        {
            if (IsDesignator(s)) return s;
            var n = Tmp(spec);
            Pre.Add(n + (ptr ? " => " : " = ") + s);
            return n;
        }

        // -------------------------------------------------------------------------------------------- reading locations
        string ReadLoc(Loc l)
        {
            switch (l.K)
            {
                case 'V': case 'P': return l.D;
                case 'C': return "int(" + l.D + ", 4)";
                case 'S':
                    if (IsObjectLike(l.T)) return l.D + "%p";
                    return Cast("*", l.D + "%p", l.T);
            }
            return Todo("location kind " + l.K);
        }

        string Read(ILocalSymbol s) => ReadVar(Var(s));
        string ReadVar(VarInfo v) => ReadLoc(new Loc(v.D, v.K, v.T));

        /// <summary>A typed pointer to the object x (whose declared type is from: "*" or a cpp_object family name).</summary>
        string Cast(string from, string x, ITypeSymbol to)
        {
            if (IsObjectLike(to)) { if (from == "*") return x; return DsgSpec(x, "class(*), pointer", true); }
            var fn = from == "*" ? HUas(to) : HAs(to);
            if (from != "*" && !IsDesignator(x)) x = DsgSpec(x, "class(" + from + "), pointer", true);
            if (from == "*" && !IsDesignator(x)) x = DsgSpec(x, "class(*), pointer", true);
            var t = Tmp(VarSpec(to));
            Pre.Add(t + " => " + fn + "(" + x + ")");
            return t;
        }

        string IsTest(string x, string from, ITypeSymbol t)
        {
            if (!IsDesignator(x)) x = DsgSpec(x, from == "*" ? "class(*), pointer" : "class(" + from + "), pointer", true);
            if (PrimCode(t) != null || IsStructType(t)) { if (from != "*") return ".false."; return HUis(t) + "(" + x + ")"; }
            return (from == "*" ? HUis(t) : HIs(t)) + "(" + x + ")";
        }

        /// <summary>The value in the box x (class(*), pointer) of value type t.</summary>
        string UnboxRef(string x, ITypeSymbol t)
        {
            if (!IsDesignator(x)) x = DsgSpec(x, "class(*), pointer", true);
            return HRef(t) + "(" + x + ")";
        }

        /// <summary>v (of C# type t) as a class(*) pointer designator: the object itself, or a fresh box.</summary>
        string ToErased(string v, ITypeSymbol t)
        {
            if (v == "null()")
            {
                // gfortran wants an unlimited polymorphic actual for a class(*) pointer dummy, null() included
                var n = Tmp("class(*), pointer");
                Pre.Add(n + " => null()");
                return n;
            }
            if (PrimCode(t) != null || IsStructType(t))
            {
                var b = Tmp("class(*), pointer");
                Pre.Add(b + " => " + HBox(t) + "(" + v + ")");
                return b;
            }
            if (IsObjectLike(t) && IsDesignator(v)) return v;
            var o = Tmp("class(*), pointer");
            Pre.Add(o + " => " + v);
            return o;
        }

        // -------------------------------------------------------------------------------------------- values
        public string Value(IOperation op, ITypeSymbol? target)
        {
            var s = X(op);
            if (target != null && op.Type != null && !SEq.Equals(op.Type, target) && PrimCode(op.Type) != null && PrimCode(target) != null)
                s = NumConv(s, op.Type, target);
            return s;
        }

        /// <summary>A logical expression for a condition.</summary>
        string Cond(IOperation op) => X(op);

        /// <summary>A pointer value (reference type).</summary>
        string XP(IOperation op) => X(op);

        public string X(IOperation op)
        {
            if (op.ConstantValue.HasValue && !(op.Type != null && IsString(op.Type))) return Const(op.ConstantValue.Value, op.Type);
            switch (op)
            {
                case IConversionOperation c: return Conversion(c);
                case ILocalReferenceOperation l: return Read(l.Local);
                case IParameterReferenceOperation pr: return ReadVar(Var(pr.Parameter));
                case IInstanceReferenceOperation ir:
                    if (ir.ReferenceKind == InstanceReferenceKind.ImplicitReceiver) return implicitRecv.Count > 0 ? implicitRecv.Peek() : Todo("implicit receiver");
                    return This();
                case IFieldReferenceOperation f: return ReadLoc(FieldLoc(f, false));
                case IPropertyReferenceOperation p: return Prop(p);
                case IArrayElementReferenceOperation ae: return ReadLoc(ArrElemLoc(ae));
                case IInvocationOperation inv: return Invoke(inv, false, false);
                case IObjectCreationOperation oc: return New(oc);
                case IArrayCreationOperation ac: return NewArray(ac);
                case IBinaryOperation b: return Binary(b);
                case IUnaryOperation u: return Unary(u);
                case IConditionalOperation c: return Ternary(c);
                case ISimpleAssignmentOperation a:
                    {
                        if (a.IsRef) return Todo("ref assignment as a value");
                        var loc = Place(a.Target);
                        var after = Pre.Count;
                        var v = Value(a.Value, a.Target.Type);
                        if (Pre.Count > after && !IsStableLoc(loc)) loc = Spill(loc, after);
                        var t = Tmp(VarSpec(a.Target.Type!));
                        bool r = IsRefType(a.Target.Type!);
                        Pre.Add(t + (r ? " => " : " = ") + v);
                        StorePre(loc, loc.K == 'C' ? "int(" + t + ", 1)" : t);
                        return t;
                    }
                case ICompoundAssignmentOperation ca: return CompoundValue(ca);
                case IIncrementOrDecrementOperation inc: return IncDec(inc, true);
                case IConditionalAccessOperation ca: return CondAccess(ca);
                case IConditionalAccessInstanceOperation: return condAccess.Count > 0 ? condAccess.Peek() : Todo("conditional access instance");
                case IAnonymousFunctionOperation af: return Lambda(af, null, null);
                case IDelegateCreationOperation dc: return DelegateCreation(dc, null);
                case IDefaultValueOperation dv: return DefaultOf(dv.Type!);
                case ILiteralOperation lit: return Const(lit.ConstantValue.Value, lit.Type);
                case IIsTypeOperation it:
                    {
                        var x = X(it.ValueOperand);
                        var ft = EngineFT(it.ValueOperand.Type!);
                        return IsTest(x, ft.Kind == "erased" ? "*" : ft.Name, it.TypeOperand);
                    }
                case IThrowOperation th:
                    {
                        var e = th.Exception == null ? Rethrow() : X(th.Exception);
                        Pre.Add("cpp_exc => " + e);
                        Pre.Add(ExcJump());
                        var t = op.Type ?? th.Parent?.Type;
                        return t != null ? DefaultOf(t) : "0";
                    }
                case IParenthesizedOperation pp: return X(pp.Operand);
                case IDiscardOperation: return Todo("discard as a value");
                case ITypeOfOperation: return Todo("typeof");
            }
            return Todo("expression " + op.Kind);
        }

        public static string DefaultOf(ITypeSymbol t)
        {
            if (PrimCode(t) is string c) return PrimZero(c);
            if (IsStructType(t)) return FName(t) + "()";
            return "null()";
        }

        // -------------------------------------------------------------------------------------------- places
        Loc Place(IOperation op)
        {
            switch (op)
            {
                case ILocalReferenceOperation l: { var v = Var(l.Local); return new Loc(v.D, v.K, v.T); }
                case IParameterReferenceOperation pr: { var v = Var(pr.Parameter); return new Loc(v.D, v.K, v.T); }
                case IFieldReferenceOperation f: return FieldLoc(f, true);
                case IArrayElementReferenceOperation ae: return ArrElemLoc(ae);
                case IPropertyReferenceOperation p: return PropLoc(p);
                case IInvocationOperation inv when inv.TargetMethod.RefKind != RefKind.None: return RefCall(inv);
                case IConversionOperation cv when cv.Conversion.IsIdentity: return Place(cv.Operand);
                case IInstanceReferenceOperation ir when ir.ReferenceKind == InstanceReferenceKind.ImplicitReceiver: return new Loc(implicitRecv.Peek(), 'P', ir.Type!);
                case IDiscardOperation d: { var t = Tmp(d.Type != null && IsRefType(d.Type) ? (UseSlotR()) : VarSpec(d.Type!) + ", target"); return new Loc(t, d.Type != null && IsRefType(d.Type) ? 'S' : 'V', d.Type!); }
                case IConditionalOperation c when c.IsRef: return RefConditional(c);
            }
            Todo("place " + op.Kind); return null!;
        }

        static string UseSlotR() { UseSlot(); return "type(cpp_slot), target"; }

        /// <summary>The location a ref binds (a ref argument, ref local, ref return): V with a pointer-target
        /// designator, or S (a cpp_slot) for a reference-typed variable.</summary>
        Loc RefLoc(IOperation op)
        {
            var l = Place(op);
            if (l.K == 'P') { Todo("reference to a reference-typed variable that is not a slot"); return null!; }
            if (l.K == 'C') { Todo("reference to a char of a C string"); return null!; }
            return l;
        }

        Loc RefConditional(IConditionalOperation c)
        {
            var cond = Cond(c.Condition);
            var t = c.Type!;
            bool refT = IsRefType(t);
            var p = Tmp(refT ? "type(cpp_slot), pointer" : VarSpec(t) + ", pointer");
            if (refT) UseSlot();
            Pre.Add("if (" + cond + ") then");
            var saved = Pre; Pre = new List<string>();
            var a = RefLoc(c.WhenTrue);
            var pa = Pre; Pre = new List<string>();
            var b = RefLoc(c.WhenFalse!);
            var pb = Pre; Pre = saved;
            foreach (var s in pa) Pre.Add("  " + s);
            Pre.Add("  " + p + " => " + a.D);
            Pre.Add("else");
            foreach (var s in pb) Pre.Add("  " + s);
            Pre.Add("  " + p + " => " + b.D);
            Pre.Add("end if");
            return new Loc(p, refT ? 'S' : 'V', t);
        }

        bool IsStableLoc(Loc l) => l.K is 'V' or 'P' or 'S' && (Regex.IsMatch(l.D, @"^zz\d+$") || IsDesignator(l.D) && !l.D.Contains('(') && (l.D.StartsWith("self%") && l.D.Count(ch => ch == '%') == 1 || !l.D.Contains('%')));

        /// <summary>Fix a location before statements at Pre[at..] run: a pointer to it, made first.</summary>
        Loc Spill(Loc l, int at)
        {
            if (l.K == 'P' || l.K == 'C') return l;
            var spec = l.K == 'S' ? "type(cpp_slot), pointer" : VarSpec(l.T) + ", pointer";
            var t = Tmp(spec);
            Pre.Insert(at, t + " => " + l.D);
            return new Loc(t, l.K, l.T);
        }

        string Recv(IOperation inst)
        {
            var s = X(inst);
            return Dsg(s, inst.Type!);
        }

        /// <summary>The designator of a struct receiver whose field is assigned: the variable itself.</summary>
        string PlaceRecv(IOperation inst)
        {
            if (inst.Type != null && IsStructType(inst.Type) && inst is not IInvocationOperation) return Place(inst).D;
            return Recv(inst);
        }

        Loc FieldLoc(IFieldReferenceOperation f, bool write)
        {
            var fs = f.Field;
            var t = fs.Type;
            if (IsRuntime(fs))
            {
                var ct = fs.ContainingType;
                var tn = RtFT(ct.OriginalDefinition, ct, ErasureOfType(ct)).Name;
                var ft = RtFT(fs.OriginalDefinition.Type, t, ErasureOfType(ct));
                var comp = Sanitize(fs.Name);
                if (fs.IsStatic)
                {
                    // a generic class has statics per instantiation: the type arguments are in the name
                    var inst = ct.IsGenericType ? "_" + string.Join("_", ct.TypeArguments.Select(ShortType)) : "";
                    var vn = Global("rtvar " + tn + inst + "." + fs.Name, tn + inst + "_" + comp);
                    if (!rtMembers.ContainsKey(vn)) rtMembers[vn] = new RtMember { Name = vn, Var = true, Cs = "static field " + fs.OriginalDefinition.ToDisplayString() + (ct.IsGenericType ? " of " + ct.ToDisplayString() : ""), Result = ft.Spec + (ft.Spec.Contains("pointer") ? "" : ", target") + " :: " + vn };
                    return new Loc(vn, IsRefType(t) ? 'P' : 'V', t);
                }
                var recv = write ? PlaceRecv(f.Instance!) : Recv(f.Instance!);
                if (ft.Kind == "erased")
                {
                    UseSlot();
                    UseComponent(tn, comp, "type(cpp_slot) :: " + comp);
                    var d = recv + "%" + comp;
                    if (IsRefType(t)) return new Loc(d, 'S', t);
                    var pt = Tmp(VarSpec(t) + ", pointer");
                    Pre.Add(pt + " => " + HRef(t) + "(" + d + "%p)");
                    return new Loc(pt, 'V', t);
                }
                UseComponent(tn, comp, ft.Spec + " :: " + comp + (ft.Kind == "prim" ? " = " + PrimZero(ft.Name) : ft.Kind is "ref" or "erased" ? " => null()" : ""));
                return new Loc(recv + "%" + comp, ft.Kind is "ref" or "erased" ? 'P' : 'V', t);
            }
            if (IsSystem(fs)) return new Loc(SystemField(fs), 'V', t);
            var od = fs.OriginalDefinition;
            if (fs.IsStatic)
            {
                if (!staticNames.TryGetValue(od, out var sn)) return new Loc(Todo("static field " + fs.Name), 'V', t);
                return new Loc(sn, slotFields.Contains(od) ? 'S' : IsRefType(t) ? 'P' : 'V', t);
            }
            if (!typeInfo.TryGetValue(od.ContainingType, out var ti) || !ti.Fields.TryGetValue(od, out var cn)) return new Loc(Todo("field " + fs.Name), 'V', t);
            var r = Recv(f.Instance!);
            return new Loc(r + "%" + cn, slotFields.Contains(od) ? 'S' : IsRefType(t) ? 'P' : 'V', t);
        }

        string SystemField(IFieldSymbol f)
        {
            if (f.HasConstantValue) return Const(f.ConstantValue, f.Type);
            return Todo("system field " + f.ContainingType.Name + "." + f.Name);
        }

        Loc ArrElemLoc(IArrayElementReferenceOperation ae)
        {
            var at = (IArrayTypeSymbol)ae.ArrayReference.Type!;
            var et = at.ElementType;
            var arr = Recv(ae.ArrayReference);
            var idx = X(ae.Indices[0]);
            FName(at);
            return ElemLoc(arr + "%a(" + idx + ")", et);
        }

        /// <summary>The element d of an array object of element type et.</summary>
        Loc ElemLoc(string d, ITypeSymbol et)
        {
            if (PrimCode(et) != null) return new Loc(d, 'V', et);
            UseSlot();
            if (IsRefType(et)) return new Loc(d, 'S', et);
            var pt = Tmp(VarSpec(et) + ", pointer");
            Pre.Add(pt + " => " + HRef(et) + "(" + d + "%p)");
            return new Loc(pt, 'V', et);
        }

        // -------------------------------------------------------------------------------------------- constants
        public static string Const(object? v, ITypeSymbol? t)
        {
            if (v == null) return t != null && !IsRefType(t) && !IsString(t) ? DefaultOf(t) : "null()";
            if (t != null && t.TypeKind == TypeKind.Enum) t = Under(t);
            switch (v)
            {
                case bool b: return b ? ".true." : ".false.";
                case string s: return FStr(s);
                case char ch: return IntLit((ulong)ch, t?.SpecialType ?? SpecialType.System_Char);
                case double d: return t != null && t.SpecialType == SpecialType.System_Single ? FloatLit((float)d) : t != null && PrimCode(t) is "i" or "l" or "s" or "c" or "b" ? IntLit((ulong)(long)d, t.SpecialType) : DoubleLit(d);
                case float f: return t != null && t.SpecialType == SpecialType.System_Double ? DoubleLit(f) : FloatLit(f);
            }
            var st = t?.SpecialType ?? SpecialType.System_Int32;
            ulong bits = v switch { int i => (ulong)(long)i, long l => (ulong)l, uint u => u, ulong ul => ul, short sh => (ulong)(long)sh, ushort us => us, byte by => by, sbyte sb => (ulong)(long)sb, _ => 0 };
            if (st == SpecialType.System_Double) return DoubleLit(v is ulong uu ? (double)uu : (double)(long)bits);
            if (st == SpecialType.System_Single) return FloatLit(v is ulong uu2 ? (float)uu2 : (float)(long)bits);
            if (st == SpecialType.System_Boolean) return bits != 0 ? ".true." : ".false.";
            return IntLit(bits, st);
        }

        static string IntLit(ulong bits, SpecialType st)
        {
            switch (st)
            {
                case SpecialType.System_Int64: case SpecialType.System_UInt64:
                    {
                        long x = (long)bits;
                        if (x == long.MinValue) return "(-9223372036854775807_8 - 1_8)";
                        return x < 0 ? "(" + x.ToString(CultureInfo.InvariantCulture) + "_8)" : x.ToString(CultureInfo.InvariantCulture) + "_8";
                    }
                case SpecialType.System_Byte: case SpecialType.System_SByte:
                    {
                        sbyte x = (sbyte)(byte)bits;
                        if (x == sbyte.MinValue) return "(-127_1 - 1_1)";
                        return x < 0 ? "(" + x + "_1)" : x + "_1";
                    }
                case SpecialType.System_Int16: case SpecialType.System_UInt16: case SpecialType.System_Char:
                    {
                        short x = (short)(ushort)bits;
                        if (x == short.MinValue) return "(-32767_2 - 1_2)";
                        return x < 0 ? "(" + x + "_2)" : x + "_2";
                    }
                default:
                    {
                        int x = (int)(uint)bits;
                        if (x == int.MinValue) return "(-2147483647 - 1)";
                        return x < 0 ? "(" + x.ToString(CultureInfo.InvariantCulture) + ")" : x.ToString(CultureInfo.InvariantCulture);
                    }
            }
        }

        static string DoubleLit(double d)
        {
            if (double.IsNaN(d) || double.IsInfinity(d) || d == 0 && double.IsNegative(d) || d != 0 && Math.Abs(d) < 2.2250738585072014E-308)
                return "transfer(" + IntLit((ulong)BitConverter.DoubleToInt64Bits(d), SpecialType.System_Int64) + ", 0.0_8)";
            var s = d.ToString("R", CultureInfo.InvariantCulture);
            if (!s.Contains('.') && !s.Contains('E')) s += ".0";
            s = s.Replace("E+", "E");
            s += "_8";
            return d < 0 ? "(" + s + ")" : s;
        }

        static string FloatLit(float f)
        {
            if (float.IsNaN(f) || float.IsInfinity(f) || f == 0 && float.IsNegative(f) || f != 0 && Math.Abs(f) < 1.17549435E-38f)
                return "transfer(" + IntLit((uint)BitConverter.SingleToInt32Bits(f), SpecialType.System_Int32) + ", 0.0_4)";
            var s = f.ToString("R", CultureInfo.InvariantCulture);
            if (!s.Contains('.') && !s.Contains('E')) s += ".0";
            s = s.Replace("E+", "E");
            s += "_4";
            return f < 0 ? "(" + s + ")" : s;
        }

        /// <summary>A Fortran character constant with C#'s chars as bytes (0-255).</summary>
        public static string FStr(string s)
        {
            if (s.Length == 0) return "\"\"";
            var parts = new List<string>();
            var cur = new StringBuilder();
            foreach (var ch in s)
            {
                int c = ch;
                if (c > 255) Todo("non-Latin-1 character in a string");
                if (c >= 32 && c < 127) { if (ch == '"') cur.Append("\"\""); else cur.Append(ch); }
                else
                {
                    if (cur.Length > 0) { parts.Add("\"" + cur + "\""); cur.Clear(); }
                    parts.Add("achar(" + c + ")");
                }
            }
            if (cur.Length > 0) parts.Add("\"" + cur + "\"");
            return string.Join(" // ", parts);
        }

        // -------------------------------------------------------------------------------------------- conversions
        string Conversion(IConversionOperation c)
        {
            var from = c.Operand.Type;
            var to = c.Type!;
            if (c.OperatorMethod != null) return RtStaticCall(c.OperatorMethod, new List<IOperation> { c.Operand });
            if (c.Operand is IAnonymousFunctionOperation af) return Lambda(af, (INamedTypeSymbol)to, null);
            if (c.Operand is IDelegateCreationOperation dc0 && to.TypeKind == TypeKind.Delegate) return DelegateCreation(dc0, null);
            if (from == null)
            {
                if (c.Operand.ConstantValue is { HasValue: true, Value: null } || c.Operand is IDefaultValueOperation) return DefaultOf(to);
                if (c.Operand is IThrowOperation) return X(c.Operand);
                return X(c.Operand);
            }
            var s = X(c.Operand);
            if (c.IsTryCast) return Cast(EngineFT(from).Kind == "erased" ? "*" : EngineFT(from).Name, s, to);
            return Conv(s, from, to);
        }

        string Conv(string s, ITypeSymbol from, ITypeSymbol to)
        {
            if (SEq.Equals(from, to)) return s;
            var f = Under(from); var t = Under(to);
            if (SEq.Equals(f, t)) return s;
            if (PrimCode(f) != null && PrimCode(t) != null) return NumConv(s, f, t);
            if (s == "null()") return s;
            bool fv = PrimCode(f) != null || IsStructType(f), tv = PrimCode(t) != null || IsStructType(t);
            // boxing and unboxing
            if (fv && !tv)
            {
                if (IsObjectLike(t) || t is INamedTypeSymbol it && it.TypeKind == TypeKind.Interface) return ToErased(s, f);
                return Todo("conversion " + from.ToDisplayString() + " -> " + to.ToDisplayString());
            }
            if (!fv && tv)
            {
                if (IsObjectLike(f)) return UnboxRef(s, t);
                return Todo("conversion " + from.ToDisplayString() + " -> " + to.ToDisplayString());
            }
            if (fv && tv)
            {
                if (from is INamedTypeSymbol nf && nf.OriginalDefinition.SpecialType == SpecialType.System_Nullable_T) return Todo("nullable");
                return Todo("conversion " + from.ToDisplayString() + " -> " + to.ToDisplayString());
            }
            // reference conversions
            if (IsObjectLike(t)) return ToErased(s, f);
            var ff = EngineFT(f); var tf = EngineFT(t);
            if (ff.Kind == "erased") return Cast("*", s, t);
            if (ff.Name == tf.Name) return s;
            if (from is INamedTypeSymbol fn && to is INamedTypeSymbol tn)
            {
                if (Derives(fn, tn) || tn.TypeKind == TypeKind.Interface || tf.Name == "cpp_object") return s;     // an upcast
                if (Derives(tn, fn) || fn.TypeKind == TypeKind.Interface || ff.Name == "cpp_object") return Cast(ff.Name, s, t);
            }
            if (from.TypeKind == TypeKind.Array && to.TypeKind == TypeKind.Array) return s;
            return Todo("conversion " + from.ToDisplayString() + " -> " + to.ToDisplayString());
        }

        static int Width(ITypeSymbol t) => t.SpecialType switch
        {
            SpecialType.System_Byte or SpecialType.System_SByte => 8, SpecialType.System_Int16 or SpecialType.System_UInt16 or SpecialType.System_Char => 16,
            SpecialType.System_Int32 or SpecialType.System_UInt32 => 32, SpecialType.System_Int64 or SpecialType.System_UInt64 => 64, _ => 0
        };

        static bool IsUnsigned(ITypeSymbol? t) => t != null && (Under(t).SpecialType is SpecialType.System_UInt32 or SpecialType.System_UInt64 or SpecialType.System_Byte or SpecialType.System_UInt16 or SpecialType.System_Char);
        static bool IsFloat(ITypeSymbol? t) => t != null && t.SpecialType is SpecialType.System_Double or SpecialType.System_Single;
        static int KindOf(ITypeSymbol t) => Width(t) / 8;

        static string Mask(int fromWidth, int kind) => fromWidth switch { 8 => "255_" + kind, 16 => "65535_" + kind, 32 => "4294967295_8", _ => "-1_" + kind };

        string NumConv(string s, ITypeSymbol from, ITypeSymbol to)
        {
            var f = Under(from); var t = Under(to);
            if (f.SpecialType == t.SpecialType) return s;
            if (f.SpecialType == SpecialType.System_Boolean || t.SpecialType == SpecialType.System_Boolean) return Todo("bool conversion");
            if (IsFloat(f) && IsFloat(t)) return "real(" + s + ", " + (t.SpecialType == SpecialType.System_Double ? 8 : 4) + ")";
            if (IsFloat(f))
            {
                var k = t.SpecialType switch
                {
                    SpecialType.System_Int32 => "i32", SpecialType.System_UInt32 => "u32", SpecialType.System_Int64 => "i64", SpecialType.System_UInt64 => "u64",
                    SpecialType.System_Int16 => "i16", SpecialType.System_UInt16 => "u16", SpecialType.System_SByte => "i8", SpecialType.System_Byte => "u8", SpecialType.System_Char => "u16",
                    _ => "x"
                };
                var h = Helper("cpp_f2_" + k, "C# (" + t + ") of a double on x86-64 (cvttsd2si; NaN and out of range give the integer indefinite), as Java's cpp.F2." + k, PrimSpec(PrimCode(t)!), "real(8), value");
                var arg = f.SpecialType == SpecialType.System_Single ? "real(" + s + ", 8)" : s;
                return h + "(" + arg + ")";
            }
            if (IsFloat(t))
            {
                int kr = t.SpecialType == SpecialType.System_Double ? 8 : 4;
                if (f.SpecialType == SpecialType.System_UInt64)
                {
                    var h = Helper("cpp_u2" + (kr == 8 ? "d" : "f"), "C# ulong -> " + (kr == 8 ? "double" : "float") + " (one rounding)", kr == 8 ? "real(8)" : "real(4)", "integer(8), value");
                    return h + "(" + s + ")";
                }
                if (IsUnsigned(f)) return "real(" + "iand(int(" + s + ", 8), " + Mask(Width(f), 8) + ")" + ", " + kr + ")";
                return "real(" + s + ", " + kr + ")";
            }
            // integral to integral
            int wf = Width(f), wt = Width(t), kt = KindOf(t);
            if (wt > wf)
            {
                if (IsUnsigned(f)) return "iand(int(" + s + ", " + kt + "), " + Mask(wf, kt) + ")";
                return "int(" + s + ", " + kt + ")";
            }
            if (wt == wf) return s;
            return "int(" + s + ", " + kt + ")";
        }
    }
}
