#!/usr/bin/env python3
# gen_rt_a.py - writes f90/runtime/cpp_rt_a.f90, part A (core) of the Fortran runtime of the SWMM6 engine port.
#
# The procedure signatures come from the part's stub (f90/runtime/stub/cpp_rt_a.f90, made from the translator's
# manifest f90/cs2f90_runtime.txt), so they match what the engine was compiled against; the bodies are written here:
# by hand for Str, CPtr, Pair, Opt, Variant, M, Arr, the exceptions and the numeric helpers, and from templates for
# the families that repeat per element type (Vec, Iter, Ptr over b d f i l s z and the erased o). The script stops if
# a stub procedure has no body or a part A entry of f90/runtime_parts.txt is missing from the output.
#
#   python3 f90/runtime/gen_rt_a.py          (writes f90/runtime/cpp_rt_a.f90)
#
# Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
STUB = os.path.join(HERE, 'stub', 'cpp_rt_a.f90')
PARTS = os.path.join(HERE, '..', 'runtime_parts.txt')
OUT = os.path.join(HERE, 'cpp_rt_a.f90')

stub = open(STUB).read().split('\n')

# ---------------------------------------------------------------------------------------------- parse the stub
procs = {}          # name -> header lines (signature and dummy declarations, without the end line)
order = []
types = {}          # name -> lines
type_order = []
i = 0
while i < len(stub):
    ln = stub[i]
    m = re.match(r'^  recursive (function|subroutine) (\w+)\(', ln)
    if m:
        name = m.group(2)
        hdr = []
        while not re.match(r'^  end (function|subroutine)', stub[i]):
            hdr.append(stub[i])
            i += 1
        procs[name] = (m.group(1), hdr)
        order.append(name)
        i += 1
        continue
    m = re.match(r'^  type\b.*::\s*(\w+)\s*$', ln)
    if m and not ln.startswith('  type(') :
        name = m.group(1)
        blk = []
        while not stub[i].startswith('  end type'):
            blk.append(stub[i])
            i += 1
        blk.append(stub[i])
        types[name] = blk
        type_order.append(name)
        i += 1
        continue
    i += 1

ai = stub.index('  abstract interface')
ae = stub.index('  end interface')
absint = stub[ai + 1:ae]
# cpp_maker goes first (a procedure pointer component names it); the rest after the types
mk_lo = absint.index('    function cpp_maker() result(zres)')
maker_iface = absint[mk_lo:mk_lo + 3]
absint = absint[:mk_lo] + absint[mk_lo + 3:]

# ---------------------------------------------------------------------------------------------- element kinds
PRIM = 'bdfilsz'
KT = {'b': 'integer(1)', 'd': 'real(8)', 'f': 'real(4)', 'i': 'integer(4)', 'l': 'integer(8)', 's': 'integer(2)',
      'z': 'logical'}
KZ = {'b': '0_1', 'd': '0.0_8', 'f': '0.0_4', 'i': '0', 'l': '0_8', 's': '0_2', 'z': '.false.'}
AT_KINDS = 'dilo'   # the kinds with a RefAt delegate type (a Ptr made from a field)


def eqx(k, x, y):
    """EqualityComparer<T>.Default.Equals of two elements of kind k (double.Equals: NaN equals NaN)."""
    if k in 'df':
        return '(%s == %s .or. (%s /= %s .and. %s /= %s))' % (x, y, x, x, y, y)
    if k == 'z':
        return '(%s .eqv. %s)' % (x, y)
    return '(%s == %s)' % (x, y)


# ---------------------------------------------------------------------------------------------- types
def T(*lines):
    return list(lines)


def iter_type(k):
    return T('  type :: cpp_iter_%s' % k,
             '    class(cpp_arr_%s), pointer :: a => null()' % k,
             '    integer(8) :: i = 0_8',
             '    class(cpp_vec_%s), pointer :: v => null()      ! the vector (null: an iterator over a bare array)' % k,
             '  end type cpp_iter_%s' % k)


def ptr_type(k):
    lines = ['  type :: cpp_ptr_%s' % k,
             '    integer(4) :: cpp_tag = 0',
             '    class(cpp_arr_%s), pointer :: a => null()' % k,
             '    integer(8) :: o = 0_8']
    if k in AT_KINDS:
        lines += ['    class(*), pointer :: ob => null()                ! &obj.field: the object ...',
                  '    class(cpp_refat_%s), pointer :: at => null()     ! ... and the lambda reaching the field' % k]
    lines.append('  end type cpp_ptr_%s' % k)
    return lines


def vec_type(k):
    lines = ['  type, extends(cpp_object) :: cpp_vec_%s' % k,
             '    class(cpp_arr_%s), pointer :: a => null()' % k,
             '    integer(4) :: n = 0']
    if k == 'o':
        lines += ['    type(cpp_mkr) :: mk                       ! Elem<T>.Make, as the translator passes it (mk%f)',
                  '    integer(4) :: cm = 0                                     ! the copy mode of T',
                  '    class(cpp_func_o), pointer :: fn => null()              ! C#\'s mk: the Func<T> of Vec(Func<T>)']
    lines += ['  contains',
              '    procedure :: clone => cpp_a_bclone_vec_%s' % k,
              '    procedure :: assign => cpp_a_bassign_vec_%s' % k,
              '  end type cpp_vec_%s' % k]
    return lines


REPL = {
    'cpp_object': T('  type :: cpp_object',
                    '    integer(4) :: cpp_tag = 0',
                    '  contains',
                    '    procedure :: clone => cpp_object_clone',
                    '    procedure :: assign => cpp_object_assign',
                    '    procedure :: dispose => cpp_object_dispose',
                    '    procedure :: hash_of => cpp_object_hash_of',
                    '    procedure :: call2 => cpp_object_call2',
                    '  end type cpp_object'),
    'cpp_cppexception': T('  type, extends(cpp_object) :: cpp_cppexception',
                          '    class(cpp_str), pointer :: msg => null()      ! what() returns msg.c_str()',
                          '  end type cpp_cppexception'),
    'cpp_opt_d': T('  type, extends(cpp_object) :: cpp_opt_d',
                   '    logical :: has = .false.',
                   '    real(8) :: val = 0.0_8',
                   '  contains',
                   '    procedure :: clone => cpp_a_bclone_opt_d',
                   '    procedure :: assign => cpp_a_bassign_opt_d',
                   '  end type cpp_opt_d'),
    'cpp_opt_o': T('  type, extends(cpp_object) :: cpp_opt_o',
                   '    logical :: has = .false.',
                   '    type(cpp_slot) :: val',
                   '    type(cpp_mkr) :: mk',
                   '    integer(4) :: cm = 0',
                   '  contains',
                   '    procedure :: clone => cpp_a_bclone_opt_o',
                   '    procedure :: assign => cpp_a_bassign_opt_o',
                   '  end type cpp_opt_o'),
    'cpp_pair': T('  type, extends(cpp_object) :: cpp_pair',
                  '    type(cpp_slot) :: first',
                  '    type(cpp_slot) :: second',
                  '    type(cpp_mkr) :: mk1                                     ! Elem<A>.Make, Elem<B>.Make (mk1%f, mk2%f)',
                  '    type(cpp_mkr) :: mk2',
                  '    integer(4) :: cm1 = 0                                    ! the copy modes of A and B',
                  '    integer(4) :: cm2 = 0',
                  '  contains',
                  '    procedure :: clone => cpp_a_bclone_pair',
                  '    procedure :: assign => cpp_a_bassign_pair',
                  '  end type cpp_pair'),
    'cpp_reviter_o': T('  type :: cpp_reviter_o',
                       '    integer(4) :: cpp_tag = 0',
                       '    class(cpp_vec_o), pointer :: v => null()',
                       '    integer(8) :: i = 0_8                 ! one past the element it designates',
                       '  end type cpp_reviter_o'),
    'cpp_str': T('  type, extends(cpp_object) :: cpp_str',
                 '    class(cpp_arr_b), pointer :: b => null()   ! capacity size(b%a) >= n + 1',
                 '    integer(4) :: n = 0',
                 '  contains',
                 '    procedure :: clone => cpp_a_bclone_str',
                 '    procedure :: assign => cpp_a_bassign_str',
                 '  end type cpp_str'),
    'cpp_variant': T('  type, extends(cpp_object) :: cpp_variant',
                     '    class(*), pointer :: v => null()     ! the alternative held: a logical, integer(4) or real(8) box, or a cpp_str',
                     '    integer(4) :: idx = 0                ! its index in variant<bool, int, double, std::string>',
                     '  contains',
                     '    procedure :: clone => cpp_a_bclone_variant',
                     '    procedure :: assign => cpp_a_bassign_variant',
                     '  end type cpp_variant'),
}
for k in PRIM + 'o':
    REPL['cpp_vec_' + k] = vec_type(k)
    REPL['cpp_ptr_' + k] = ptr_type(k)
for k in 'bdfiloz':
    REPL['cpp_iter_' + k] = iter_type(k)
for k in REPL:
    if k not in types:
        sys.exit('gen_rt_a: replacement for a type the stub does not have: ' + k)

# ---------------------------------------------------------------------------------------------- bodies
B = {}      # name -> body text (local declarations, then statements), indented four spaces


def body(name, text):
    if name in B:
        sys.exit('gen_rt_a: two bodies for ' + name)
    B[name] = text.strip('\n')


# ---- arrays: cpp_arr_<k>_new, Arr.*, Array.Fill
for k in PRIM:
    body('cpp_arr_%s_new' % k, '''
    allocate(zres)
    allocate(zres%%a(0:a1 - 1))
    zres%%a = %s''' % KZ[k])
body('cpp_arr_o_new', '''
    allocate(zres)
    allocate(zres%a(0:a1 - 1))''')
body('cpp_arr_o_new_mk', '''
    integer(8) :: i
    allocate(zres)
    allocate(zres%a(0:a1 - 1))
    do i = 0, a1 - 1
      zres%a(i)%p => a2()
    end do''')
for k in 'bdilsz':
    body('cpp_arr_assign__' + k, '''
    integer(4) :: m
    m = size(a2%a)
    a1%a(0:m - 1) = a2%a(0:m - 1)''')
body('cpp_arr_assign__o', '''
    integer(4) :: i, m
    class(*), pointer :: s
    m = size(a2%a)
    if (cm4 == 2) then
      do i = 0, m - 1
        s => a2%a(i)%p
        if (.not. associated(a1%a(i)%p)) then
          ! (C# would throw NullReferenceException) a copy
          a1%a(i)%p => cpp_a_copy(s, 2)
        else
          select type (d => a1%a(i)%p)
          class is (cpp_object)
            select type (s)
            class is (cpp_object)
              call d%assign(s)
            end select
          end select
        end if
        if (associated(cpp_exc)) return
      end do
    else
      do i = 0, m - 1
        a1%a(i)%p => cpp_a_copy(a2%a(i)%p, merge(0, 1, cm4 == 0))
      end do
    end if''')
for k in 'bdilsz':
    body('cpp_arr_clone__' + k, '''
    zres => null()
    if (.not. associated(a1)) return
    allocate(zres)
    allocate(zres%a(0:size(a1%a) - 1), source=a1%a)''')
body('cpp_arr_clone__o', '''
    integer(4) :: i
    zres => null()
    if (.not. associated(a1)) return
    zres => cpp_arr_o_new(int(size(a1%a), 8))
    do i = 0, size(a1%a) - 1
      ! Elem<T>.IsClass: each element copied; otherwise Array.Copy (a value copied, a reference shared)
      if (cm3 == 2) then
        zres%a(i)%p => cpp_a_copy(a1%a(i)%p, 2)
        if (associated(cpp_exc)) return
      else
        zres%a(i)%p => cpp_a_copy(a1%a(i)%p, merge(0, 1, cm3 == 0))
      end if
    end do''')
body('cpp_arr_eq__d', '''
    integer(4) :: i
    zres = .false.
    if (size(a1%a) /= size(a2%a)) return
    do i = 0, size(a1%a) - 1
      if (.not. ''' + eqx('d', 'a1%a(i)', 'a2%a(i)') + ''') return
    end do
    zres = .true.''')
for k in 'dil':
    body('cpp_arr_make2__' + k, '''
    integer(4) :: i
    zres => cpp_arr_o_new(int(a1, 8))
    do i = 0, a1 - 1
      zres%%a(i)%%p => cpp_arr_%s_new(int(a2, 8))
    end do''' % k)
body('cpp_arr_make2__o', '''
    integer(4) :: i
    zres => cpp_arr_o_new(int(a1, 8))
    do i = 0, a1 - 1
      zres%a(i)%p => cpp_arr_make__o(a2, mk3, cm4)
    end do''')
for k in 'dilz':
    body('cpp_arr_make__' + k, '''
    zres => cpp_arr_%s_new(int(a1, 8))''' % k)
body('cpp_arr_make__o', '''
    ! Elem<T>.Make for every element (the maker gives a zero box for a value type, null for a class without a
    ! default constructor)
    zres => cpp_arr_o_new_mk(int(a1, 8), mk2)''')
body('cpp_arr_makewith__o', '''
    integer(4) :: i
    zres => cpp_arr_o_new(int(a1, 8))
    do i = 0, a1 - 1
      zres%a(i)%p => a2%invoke()
      if (associated(cpp_exc)) return
    end do''')
for k in 'dl':
    body('cpp_array_fill_' + k, '''
    a1%a(:) = a2''')

# ---- numeric helpers
body('cpp_u2d', '''
    ! C#'s ulong -> double: one rounding to nearest even (halve with the low bit kept sticky, convert, double)
    if (a1 >= 0) then
      zres = real(a1, 8)
    else
      zres = real(ior(ishft(a1, -1), iand(a1, 1_8)), 8) * 2.0_8
    end if''')
body('cpp_udiv8', '''
    integer(8) :: q, r
    if (a2 < 0) then
      ! a divisor >= 2**63: the quotient is 1 when a1 >= a2 (unsigned), else 0
      if (ieor(a1, CPP_A_SIGN8) >= ieor(a2, CPP_A_SIGN8)) then
        zres = 1
      else
        zres = 0
      end if
    else if (a1 >= 0) then
      zres = a1 / a2
    else
      q = ishft(ishft(a1, -1) / a2, 1)
      r = a1 - q * a2
      if (ieor(r, CPP_A_SIGN8) >= ieor(a2, CPP_A_SIGN8)) q = q + 1
      zres = q
    end if''')
body('cpp_urem8', '''
    zres = a1 - cpp_udiv8(a1, a2) * a2''')
body('cpp_urem4', '''
    zres = int(mod(iand(int(a1, 8), 4294967295_8), iand(int(a2, 8), 4294967295_8)), 4)''')
body('cpp_double_isnan', '''
    zres = a1 /= a1''')
body('cpp_double_isinfinity', '''
    zres = abs(a1) > huge(a1)''')
body('cpp_double_isfinite', '''
    zres = abs(a1) <= huge(a1)''')

# ---- M: std::min / max / clamp as libstdc++ writes them
body('cpp_m_min_d_d', '''
    if (a2 < a1) then
      zres = a2
    else
      zres = a1
    end if''')
body('cpp_m_max_d_d', '''
    if (a1 < a2) then
      zres = a2
    else
      zres = a1
    end if''')
B['cpp_m_min_i_i'] = B['cpp_m_min_d_d']
B['cpp_m_max_i_i'] = B['cpp_m_max_d_d']
B['cpp_m_max_l_l'] = B['cpp_m_max_d_d']
body('cpp_m_max_u_u', '''
    if (ieor(a1, CPP_A_SIGN4) < ieor(a2, CPP_A_SIGN4)) then
      zres = a2
    else
      zres = a1
    end if''')
body('cpp_m_max_ul_ul', '''
    if (ieor(a1, CPP_A_SIGN8) < ieor(a2, CPP_A_SIGN8)) then
      zres = a2
    else
      zres = a1
    end if''')
body('cpp_m_min_ul_ul', '''
    if (ieor(a2, CPP_A_SIGN8) < ieor(a1, CPP_A_SIGN8)) then
      zres = a2
    else
      zres = a1
    end if''')
body('cpp_m_min_uc_uc', '''
    if (iand(int(a2, 4), 255) < iand(int(a1, 4), 255)) then
      zres = a2
    else
      zres = a1
    end if''')
body('cpp_m_clamp_d_d_d', '''
    if (a1 < a2) then
      zres = a2
    else if (a3 < a1) then
      zres = a3
    else
      zres = a1
    end if''')
B['cpp_m_clamp_i_i_i'] = B['cpp_m_clamp_d_d_d']
for nm, cmp in (('max_da', 'r < a1%a(i)'), ('min_da', 'a1%a(i) < r'), ('max_ia', 'r < a1%a(i)'), ('min_ia', 'a1%a(i) < r')):
    if 'cpp_m_' + nm not in procs:
        continue
    tt = 'real(8)' if nm.endswith('da') else 'integer(4)'
    body('cpp_m_' + nm, '''
    %s :: r
    integer(4) :: i
    r = a1%%a(0)
    do i = 1, size(a1%%a) - 1
      if (%s) r = a1%%a(i)
    end do
    zres = r''' % (tt, cmp))

# ---- CPtr
body('cpp_cptr_clone', '''
    zres = self''')
body('cpp_cptr_diff', '''
    zres = int(a1%o, 8) - int(a2%o, 8)''')
body('cpp_cptr_from_ptrc', '''
    zres%b => a1%a
    zres%o = int(a1%o, 4)''')
B['cpp_cptr_from_ptruc'] = B['cpp_cptr_from_ptrc']
body('cpp_cptr_isnull', '''
    zres = .not. associated(self%b)''')
body('cpp_cptr_op_add_cptr_i', '''
    zres%b => a1%b
    zres%o = a1%o + a2''')
body('cpp_cptr_op_add_cptr_l', '''
    zres%b => a1%b
    zres%o = a1%o + int(a2, 4)''')
body('cpp_cptr_op_eq', '''
    zres = cpp_a_cptr_eq(a1, a2)''')
body('cpp_cptr_op_ne', '''
    zres = .not. cpp_a_cptr_eq(a1, a2)''')
body('cpp_cptr_op_lt', '''
    zres = a1%o < a2%o''')
body('cpp_cspan_o_empty', '''
    zres = self%n == 0''')

# ---- exceptions
body('cpp_cppexception_ctor_0', '''
    self%msg => cpp_a_str_of('std::exception')''')
body('cpp_cppexception_what', '''
    if (.not. associated(self%msg)) self%msg => cpp_a_str_of('std::exception')
    zres = cpp_str_c_str(self%msg)''')
for cls in ('invalidargument', 'outofrange', 'runtimeerror'):
    body('cpp_%s_new_str' % cls, '''
    allocate(zres)
    zres%msg => cpp_str_clone(a1)''')

# ---- Opt
body('cpp_opt_d_new_0', '''
    allocate(zres)''')
body('cpp_opt_d_new_t', '''
    allocate(zres)
    zres%has = .true.
    zres%val = a1''')
body('cpp_opt_d_value_or', '''
    if (self%has) then
      zres = self%val
    else
      zres = a1
    end if''')
body('cpp_opt_d_movefrom', '''
    if (associated(a1, self)) return
    self%has = a1%has
    self%val = a1%val''')
body('cpp_opt_d_clone', '''
    if (self%has) then
      zres => cpp_opt_d_new_t(self%val)
    else
      zres => cpp_opt_d_new_0()
    end if''')
body('cpp_opt_d_assign', '''
    self%has = a1%has
    if (a1%has) then
      self%val = a1%val
    else
      self%val = 0.0_8
    end if''')
body('cpp_opt_o_new_0', '''
    allocate(zres)
    zres%mk%f => mk1
    zres%cm = cm2
    zres%val%p => null()
    if (cm2 == 0) zres%val%p => zres%mk%f()''')
body('cpp_opt_o_set', '''
    self%has = .true.
    self%val%p => a1''')
body('cpp_opt_o_emplace', '''
    self%has = .true.
    self%val%p => a1
    zres => self%val''')
body('cpp_opt_o_reset', '''
    self%has = .false.
    self%val%p => null()
    if (self%cm == 0) self%val%p => self%mk%f()''')
body('cpp_opt_o_clone', '''
    allocate(zres)
    zres%mk = self%mk
    zres%cm = self%cm
    if (self%has) then
      zres%has = .true.
      zres%val%p => cpp_a_copy(self%val%p, self%cm)
    else
      if (self%cm == 0) zres%val%p => self%mk%f()
    end if''')
body('cpp_opt_o_assign', '''
    class(*), pointer :: v
    if (a1%has) then
      v => cpp_a_copy(a1%val%p, self%cm)
      if (associated(cpp_exc)) return
    else
      v => null()
      if (self%cm == 0) v => self%mk%f()
    end if
    self%has = a1%has
    self%val%p => v''')

# ---- Pair
body('cpp_pair_new_a_b', '''
    allocate(zres)
    zres%first%p => a1
    zres%second%p => a2
    zres%mk1%f => mk3
    zres%cm1 = cm4
    zres%mk2%f => mk5
    zres%cm2 = cm6''')
body('cpp_pair_new_0', '''
    ! Pair(): first = Elem<A>.Make(), second = Elem<B>.Make()
    allocate(zres)
    zres%mk1%f => mk1
    zres%cm1 = cm2
    zres%mk2%f => mk3
    zres%cm2 = cm4
    zres%first%p => zres%mk1%f()
    zres%second%p => zres%mk2%f()''')
body('cpp_pair_clone', '''
    class(*), pointer :: x, y
    zres => null()
    x => cpp_a_copy(self%first%p, self%cm1)
    if (associated(cpp_exc)) return
    y => cpp_a_copy(self%second%p, self%cm2)
    if (associated(cpp_exc)) return
    allocate(zres)
    zres%first%p => x
    zres%second%p => y
    zres%mk1 = self%mk1
    zres%cm1 = self%cm1
    zres%mk2 = self%mk2
    zres%cm2 = self%cm2''')

# ---- Variant
body('cpp_variant_new_0', '''
    allocate(zres)
    allocate(zres%v, source=.false.)
    zres%idx = 0''')
body('cpp_variant_set_b', '''
    allocate(self%v, source=a1)
    self%idx = 0''')
body('cpp_variant_set_i', '''
    allocate(self%v, source=a1)
    self%idx = 1''')
body('cpp_variant_set_d', '''
    allocate(self%v, source=a1)
    self%idx = 2''')
body('cpp_variant_set_str', '''
    self%v => cpp_str_clone(a1)
    self%idx = 3''')
body('cpp_variant_clone', '''
    zres => cpp_variant_new_0()
    call cpp_variant_assign(zres, self)''')
body('cpp_variant_assign', '''
    class(*), pointer :: v
    v => a1%v
    self%idx = a1%idx
    select type (q => v)
    class is (cpp_str)
      self%v => cpp_str_clone(q)
    class default
      self%v => cpp_a_copy(v, 0)
    end select''')
body('cpp_variant_movefrom', '''
    self%idx = a1%idx
    self%v => a1%v''')

# ---- Str
body('cpp_str_new_0', '''
    allocate(zres)
    zres%b => cpp_arr_b_new(16_8)''')
body('cpp_str_new_str', '''
    zres => cpp_a_str_bytes(a1%b, 0, a1%n)''')
body('cpp_str_new_cptr', '''
    zres => cpp_a_str_bytes(a1%b, a1%o, cpp_a_strlen(a1))''')
B['cpp_str_from'] = B['cpp_str_new_cptr']
body('cpp_str_new_cptr_ul', '''
    zres => cpp_a_str_bytes(a1%b, a1%o, int(a2, 4))''')
body('cpp_str_new_ul_i', '''
    integer(4) :: m
    m = int(a1, 4)
    allocate(zres)
    zres%b => cpp_arr_b_new(int(m + 1, 8))
    zres%b%a(0:m - 1) = int(a2, 1)
    zres%n = m''')
body('cpp_str_size', '''
    zres = int(self%n, 8)''')
body('cpp_str_empty', '''
    zres = self%n == 0''')
body('cpp_str_clear', '''
    self%n = 0''')
body('cpp_str_c_str', '''
    call cpp_a_str_reserve(self, self%n)
    self%b%a(self%n) = 0_1
    zres%b => self%b
    zres%o = 0''')
B['cpp_str_data'] = B['cpp_str_c_str']
body('cpp_str_front', '''
    zres => self%b%a(0)''')
body('cpp_str_back', '''
    zres => self%b%a(self%n - 1)''')
body('cpp_str_clone', '''
    zres => cpp_a_str_bytes(self%b, 0, self%n)''')
body('cpp_str_assign_str', '''
    class(cpp_arr_b), pointer :: src
    integer(4) :: m
    if (associated(a1, self)) return
    src => a1%b
    m = a1%n
    call cpp_a_str_reserve(self, m)
    if (m > 0) self%b%a(0:m - 1) = src%a(0:m - 1)
    self%n = m''')
body('cpp_str_assign_cptr', '''
    call cpp_a_str_set(self, a1%b, a1%o, cpp_a_strlen(a1))''')
body('cpp_str_assign_cptr_ul', '''
    call cpp_a_str_set(self, a1%b, a1%o, int(a2, 4))
    zres => self''')
body('cpp_str_assign_ptrc_ptrc', '''
    call cpp_a_str_set(self, a1%a, int(a1%o, 4), int(a2%o - a1%o, 4))
    zres => self''')
body('cpp_str_movefrom', '''
    if (associated(a1, self)) return
    self%b => a1%b
    self%n = a1%n
    a1%b => cpp_arr_b_new(16_8)
    a1%n = 0''')
body('cpp_str_append_str', '''
    call cpp_a_str_app(self, a1%b, 0, a1%n)
    zres => self''')
body('cpp_str_append_cptr', '''
    call cpp_a_str_app(self, a1%b, a1%o, cpp_a_strlen(a1))
    zres => self''')
body('cpp_str_append_cptr_ul', '''
    call cpp_a_str_app(self, a1%b, a1%o, int(a2, 4))
    zres => self''')
body('cpp_str_append_i', '''
    call cpp_a_str_reserve(self, self%n + 1)
    self%b%a(self%n) = int(a1, 1)
    self%n = self%n + 1
    zres => self''')
body('cpp_str_push_back', '''
    call cpp_a_str_reserve(self, self%n + 1)
    self%b%a(self%n) = int(a1, 1)
    self%n = self%n + 1''')
body('cpp_str_pop_back', '''
    self%n = self%n - 1''')
body('cpp_str_resize', '''
    integer(4) :: k
    k = int(a1, 4)
    call cpp_a_str_reserve(self, k)
    if (k > self%n) self%b%a(self%n:k - 1) = int(a2, 1)
    self%n = k''')
body('cpp_str_reserve', '''
    call cpp_a_str_reserve(self, int(a1, 4))''')
body('cpp_str_remove_prefix', '''
    integer(4) :: m
    m = int(a1, 4)
    if (self%n - m > 0) self%b%a(0:self%n - m - 1) = self%b%a(m:self%n - 1)
    self%n = self%n - m
    self%b%a(self%n) = 0_1''')
body('cpp_str_substr', '''
    integer(4) :: m
    zres => null()
    if (ieor(a1, CPP_A_SIGN8) > ieor(int(self%n, 8), CPP_A_SIGN8)) then
      cpp_exc => cpp_a_exc(2, 'basic_string::substr: __pos (which is ' // cpp_a_udec8(a1) // &
        ') > this->size() (which is ' // cpp_a_dec8(int(self%n, 8)) // ')')
      return
    end if
    m = int(cpp_m_min_ul_ul(a2, int(self%n, 8) - a1), 4)
    zres => cpp_a_str_bytes(self%b, int(a1, 4), m)''')
body('cpp_str_erase', '''
    integer(4) :: p, m
    p = int(a1, 4)
    m = int(cpp_m_min_ul_ul(a2, int(self%n - p, 8)), 4)
    if (self%n - p - m > 0) self%b%a(p:self%n - m - 1) = self%b%a(p + m:self%n - 1)
    self%n = self%n - m
    zres => self''')
body('cpp_str_find_cptr_ul', '''
    integer(4) :: sn, j
    integer(8) :: i
    sn = cpp_a_strlen(a1)
    zres = CPP_NPOS
    if (sn == 0) then
      if (ieor(a2, CPP_A_SIGN8) <= ieor(int(self%n, 8), CPP_A_SIGN8)) zres = a2
      return
    end if
    if (a2 < 0) return
    i = a2
    do while (i + sn <= self%n)
      j = 0
      do while (j < sn)
        if (self%b%a(i + j) /= a1%b%a(a1%o + j)) exit
        j = j + 1
      end do
      if (j == sn) then
        zres = i
        return
      end if
      i = i + 1
    end do''')
body('cpp_str_find_i_ul', '''
    integer(8) :: i
    integer(1) :: ch
    ch = int(a1, 1)
    zres = CPP_NPOS
    if (a2 < 0) return
    do i = a2, int(self%n, 8) - 1
      if (self%b%a(i) == ch) then
        zres = i
        return
      end if
    end do''')
body('cpp_str_rfind_cptr_ul', '''
    integer(4) :: sn, j
    integer(8) :: i
    sn = cpp_a_strlen(a1)
    zres = CPP_NPOS
    if (sn > self%n) return
    i = cpp_m_min_ul_ul(a2, int(self%n - sn, 8))
    do while (i >= 0)
      j = 0
      do while (j < sn)
        if (self%b%a(i + j) /= a1%b%a(a1%o + j)) exit
        j = j + 1
      end do
      if (j == sn) then
        zres = i
        return
      end if
      i = i - 1
    end do''')
body('cpp_str_rfind_i_ul', '''
    zres = cpp_a_str_rfind_ch(self, a1, a2)''')
B['cpp_str_find_last_of_i_ul'] = B['cpp_str_rfind_i_ul']
for nm, test in (('find_first_of_cptr_ul', 'cpp_a_in(self%b%a(i), a1)'),
                 ('find_first_not_of_cptr_ul', '.not. cpp_a_in(self%b%a(i), a1)')):
    body('cpp_str_' + nm, '''
    integer(8) :: i
    zres = CPP_NPOS
    if (a2 < 0) return
    do i = a2, int(self%%n, 8) - 1
      if (%s) then
        zres = i
        return
      end if
    end do''' % test)
body('cpp_str_find_first_not_of_i_ul', '''
    integer(8) :: i
    integer(1) :: ch
    ch = int(a1, 1)
    zres = CPP_NPOS
    if (a2 < 0) return
    do i = a2, int(self%n, 8) - 1
      if (self%b%a(i) /= ch) then
        zres = i
        return
      end if
    end do''')
body('cpp_str_find_last_not_of_cptr_ul', '''
    integer(8) :: i
    zres = CPP_NPOS
    if (self%n == 0) return
    i = cpp_m_min_ul_ul(a2, int(self%n - 1, 8))
    do while (i >= 0)
      if (.not. cpp_a_in(self%b%a(i), a1)) then
        zres = i
        return
      end if
      i = i - 1
    end do''')
body('cpp_str_starts_with_str', '''
    integer(4) :: i
    zres = .false.
    if (a1%n > self%n) return
    do i = 0, a1%n - 1
      if (self%b%a(i) /= a1%b%a(i)) return
    end do
    zres = .true.''')
body('cpp_str_starts_with_cptr', '''
    integer(4) :: i, m
    zres = .false.
    m = cpp_a_strlen(a1)
    if (m > self%n) return
    do i = 0, m - 1
      if (self%b%a(i) /= a1%b%a(a1%o + i)) return
    end do
    zres = .true.''')
body('cpp_str_compare_ul_ul_str', '''
    class(cpp_str), pointer :: t
    zres = 0
    t => cpp_str_substr(self, a1, a2)
    if (associated(cpp_exc)) return
    zres = cpp_a_str_compare(t, a3)
    call cpp_a_str_free(t)''')
body('cpp_str_equals_str', '''
    integer(4) :: i
    zres = .false.
    if (.not. associated(a1)) return
    if (a1%n /= self%n) return
    do i = 0, self%n - 1
      if (self%b%a(i) /= a1%b%a(i)) return
    end do
    zres = .true.''')
body('cpp_str_eqlit', '''
    integer(4) :: i
    zres = .false.
    if (cpp_a_strlen(a1) /= self%n) return
    do i = 0, self%n - 1
      if (self%b%a(i) /= a1%b%a(a1%o + i)) return
    end do
    zres = .true.''')
body('cpp_str_cat_str_str', '''
    zres => cpp_a_str_bytes(a1%b, 0, a1%n)
    call cpp_a_str_app(zres, a2%b, 0, a2%n)''')
body('cpp_str_cat_str_cptr', '''
    zres => cpp_a_str_bytes(a1%b, 0, a1%n)
    call cpp_a_str_app(zres, a2%b, a2%o, cpp_a_strlen(a2))''')
body('cpp_str_cat_cptr_str', '''
    zres => cpp_a_str_bytes(a1%b, a1%o, cpp_a_strlen(a1))
    call cpp_a_str_app(zres, a2%b, 0, a2%n)''')
body('cpp_str_cat_str_i', '''
    zres => cpp_a_str_bytes(a1%b, 0, a1%n)
    call cpp_str_push_back(zres, a2)''')
body('cpp_str_tostring', '''
    integer(4) :: i
    allocate(character(len=a1%n) :: zres)
    do i = 1, a1%n
      zres(i:i) = achar(iand(int(a1%b%a(i - 1), 4), 255))
    end do''')
body('cpp_str_begin', '''
    zres%a => self%b
    zres%i = 0''')
body('cpp_str_end', '''
    zres%a => self%b
    zres%i = int(self%n, 8)''')
body('cpp_str_to_string_i', '''
    zres => cpp_a_str_of(cpp_a_dec8(int(a1, 8)))''')
body('cpp_str_to_string_l', '''
    zres => cpp_a_str_of(cpp_a_dec8(a1))''')
body('cpp_str_to_string_u', '''
    zres => cpp_a_str_of(cpp_a_udec8(iand(int(a1, 8), 4294967295_8)))''')
body('cpp_str_to_string_ul', '''
    zres => cpp_a_str_of(cpp_a_udec8(a1))''')
body('cpp_str_to_string_d', '''
    zres => cpp_a_fmt_f6(a1)''')
SUBMOD = {'cpp_str_stod'}      # bodies in the submodule cpp_rt_a_crt (they need part C)

# ---- Iter, RevIter (all kinds that the stub has)
for k in 'bdfiloz':
    I = 'cpp_iter_' + k
    body(I + '_clone', '''
    zres = self''')
    body(I + '_deref', '''
    zres => self%a%a(self%i)''')
    body(I + '_new_ta_l', '''
    zres%a => a1
    zres%i = a2''')
    body(I + '_op_add', '''
    if (associated(a1%v)) then
      zres%v => a1%v
      zres%a => a1%v%a
    else
      zres%a => a1%a
    end if
    zres%i = a1%i + a2''')
    body(I + '_op_inc', '''
    zres = %s_op_add(a1, 1_8)''' % I)
    body(I + '_op_eq', '''
    zres = a1%i == a2%i''')
    body(I + '_op_sub_itert_itert', '''
    zres = a1%i - a2%i''')
    body(I + '_op_sub_itert_l', '''
    zres = %s_op_add(a1, -a2)''' % I)
body('cpp_reviter_o_deref', '''
    zres => self%v%a%a(self%i - 1)''')
body('cpp_reviter_o_op_eq', '''
    zres = a1%i == a2%i''')
body('cpp_reviter_o_op_inc', '''
    zres%v => a1%v
    zres%i = a1%i - 1''')

# ---- Ptr (all kinds)
for k in PRIM + 'o':
    P = 'cpp_ptr_' + k
    hasat = k in AT_KINDS
    at = ('''
    if (associated(self%at)) then
      f => self%at
      zres => f%invoke(self%ob)
      return
    end if''' if hasat else '')
    atdecl = ('\n    class(cpp_refat_%s), pointer :: f' % k) if hasat else ''
    body(P + '_deref', atdecl + at + '''
    zres => self%a%a(self%o)''')
    for sfx, ix in (('i', 'int(a1, 8)'), ('l', 'a1'), ('ul', 'a1')):
        body(P + '_item_' + sfx, atdecl + at + '''
    zres => self%%a%%a(self%%o + %s)''' % ix)
    body(P + '_isnull', '''
    zres = .not. associated(self%a)''' + (' .and. .not. associated(self%at)' if hasat else ''))
    body(P + '_new_ta_l', '''
    zres%a => a1
    zres%o = a2''')
    if hasat:
        body(P + '_new_o_refatt', '''
    zres%ob => a1
    zres%at => a2''')
        eqb = '''
    if (associated(a1%at) .or. associated(a2%at)) then
      zres = .false.
      if (.not. associated(a1%at)) return
      if (.not. associated(a2%at)) return
      if (.not. cpp_a_same(a1%ob, a2%ob)) return
      if (.not. same_type_as(a1%at, a2%at)) return
      zres = a1%o == a2%o
      return
    end if'''
    else:
        eqb = ''
    body(P + '_op_eq', eqb + '''
    if (associated(a1%a) .neqv. associated(a2%a)) then
      zres = .false.
    else if (.not. associated(a1%a)) then
      zres = .true.
    else
      zres = associated(a1%a, a2%a)
      if (zres) zres = a1%o == a2%o
    end if''')
    # op_ne is the negation of op_eq, whose body returns early: op_eq's body as an internal procedure
    body(P + '_op_ne', '''
    zres = .not. eq(a1, a2)
  contains
    recursive function eq(a1, a2) result(zres)
      type(%s), intent(in) :: a1, a2
      logical :: zres''' % P + ('\n' + B[P + '_op_eq']).replace('\n    ', '\n      ') + '''
    end function eq''')
    body(P + '_op_add_ptrt_l', '''
    zres = a1
    zres%o = a1%o + a2''')
    body(P + '_op_sub_ptrt_l', '''
    zres = a1
    zres%o = a1%o - a2''')
    body(P + '_from', '''
    zres%a => a1%a
    zres%o = a1%i''')


# ---- Vec over a primitive element
def vec_prim(k):
    V = 'cpp_vec_' + k
    A = 'cpp_arr_' + k
    Z = KZ[k]
    t = KT[k]
    d = {}
    d['new_0'] = '''
    allocate(zres)
    zres%a => cpp_a_empty_K()'''
    d['new_ul'] = '''
    allocate(zres)
    zres%a => A_new(a1)
    zres%n = int(a1, 4)'''
    d['new_ul_t'] = '''
    allocate(zres)
    zres%a => A_new(a1)
    zres%n = int(a1, 4)
    zres%a%a(:) = a2'''
    d['new_ta'] = '''
    allocate(zres)
    zres%a => A_new(int(size(a1%a), 8))
    zres%n = size(a1%a)
    zres%a%a(:) = a1%a(:)'''
    d['size'] = '''
    zres = int(self%n, 8)'''
    d['empty'] = '''
    zres = self%n == 0'''
    d['capacity'] = '''
    zres = int(size(self%a%a), 8)'''
    d['at'] = '''
    zres => null()
    if (ieor(a1, CPP_A_SIGN8) >= ieor(int(self%n, 8), CPP_A_SIGN8)) then
      cpp_exc => cpp_a_vec_range(a1, self%n)
      return
    end if
    zres => self%a%a(a1)'''
    d['front'] = '''
    zres => self%a%a(0)'''
    d['back'] = '''
    zres => self%a%a(self%n - 1)'''
    d['data'] = '''
    zres%a => self%a
    zres%o = 0_8'''
    d['begin'] = '''
    zres%v => self
    zres%a => self%a
    zres%i = 0_8'''
    d['end'] = '''
    zres%v => self
    zres%a => self%a
    zres%i = int(self%n, 8)'''
    d['reserve'] = '''
    if (int(a1, 4) > size(self%a%a)) call cpp_a_setcap_K(self, int(a1, 4))'''
    d['shrink_to_fit'] = '''
    if (size(self%a%a) /= self%n) call cpp_a_setcap_K(self, self%n)'''
    d['push_back'] = '''
    if (self%n >= size(self%a%a)) call cpp_a_grow_K(self, self%n + 1)
    self%a%a(self%n) = a1
    self%n = self%n + 1'''
    d['pop_back'] = '''
    self%n = self%n - 1
    self%a%a(self%n) = Z'''
    d['clear'] = '''
    if (self%n > 0) self%a%a(0:self%n - 1) = Z
    self%n = 0'''
    d['resize_ul'] = '''
    integer(4) :: m
    m = int(a1, 4)
    if (m > self%n) then
      call cpp_a_grow_K(self, m)
    else if (m < self%n) then
      self%a%a(m:self%n - 1) = Z
    end if
    self%n = m'''
    d['resize_ul_t'] = '''
    integer(4) :: m
    m = int(a1, 4)
    if (m > self%n) then
      call cpp_a_grow_K(self, m)
      self%a%a(self%n:m - 1) = a2
    else if (m < self%n) then
      self%a%a(m:self%n - 1) = Z
    end if
    self%n = m'''
    d['assign_ul_t'] = '''
    integer(4) :: m
    m = int(a1, 4)
    if (m > size(self%a%a)) then
      self%a => A_new(int(m, 8))
    else
      self%a%a(:) = Z
    end if
    if (m > 0) self%a%a(0:m - 1) = a2
    self%n = m'''
    d['assign_itert_itert'] = '''
    class(A), pointer :: na
    integer(4) :: m
    m = int(a2%i - a1%i, 4)
    na => A_new(int(m, 8))
    if (m > 0) na%a(0:m - 1) = a1%a%a(a1%i:a1%i + m - 1)
    self%a => na
    self%n = m'''
    d['assign_vect'] = '''
    class(A), pointer :: na
    integer(4) :: m
    if (associated(a1, self)) return
    m = a1%n
    if (size(self%a%a) == m) then
      ! the storage is already of the new size (C# makes a new array of that size): copy in place
      if (m > 0) self%a%a(0:m - 1) = a1%a%a(0:m - 1)
    else
      na => A_new(int(m, 8))
      if (m > 0) na%a(0:m - 1) = a1%a%a(0:m - 1)
      self%a => na
    end if
    self%n = m'''
    d['movefrom_vect'] = '''
    if (associated(a1, self)) return
    self%a => a1%a
    self%n = a1%n
    a1%a => cpp_a_empty_K()
    a1%n = 0'''
    d['movefrom_ta'] = '''
    class(A), pointer :: na
    na => A_new(int(size(a1%a), 8))
    na%a(:) = a1%a(:)
    self%a => na
    self%n = size(a1%a)'''
    d['clone'] = '''
    allocate(zres)
    zres%a => A_new(int(self%n, 8))
    if (self%n > 0) zres%a%a(0:self%n - 1) = self%a%a(0:self%n - 1)
    zres%n = self%n'''
    d['swap'] = '''
    class(A), pointer :: ta
    integer(4) :: tn
    ta => self%a
    tn = self%n
    self%a => a1%a
    self%n = a1%n
    a1%a => ta
    a1%n = tn'''
    d['insert_itert_t'] = '''
    integer(4) :: p
    p = int(a1%i, 4)
    call cpp_a_grow_K(self, self%n + 1)
    if (self%n > p) self%a%a(p + 1:self%n) = self%a%a(p:self%n - 1)
    self%a%a(p) = a2
    self%n = self%n + 1
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    ins_tail = '''
    call cpp_a_grow_K(self, self%n + m)
    if (self%n > p) self%a%a(p + m:self%n + m - 1) = self%a%a(p:self%n - 1)
    if (m > 0) self%a%a(p:p + m - 1) = tmp(0:m - 1)
    self%n = self%n + m
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    d['insert_itert_itert_itert'] = '''
    T, allocatable :: tmp(:)
    integer(4) :: p, m
    p = int(a1%i, 4)
    m = int(a3%i - a2%i, 4)
    allocate(tmp(0:m - 1))
    if (m > 0) tmp(0:m - 1) = a2%a%a(a2%i:a2%i + m - 1)''' + ins_tail
    d['insert_itert_ptrt_ptrt'] = '''
    T, allocatable :: tmp(:)
    integer(4) :: p, m
    p = int(a1%i, 4)
    m = int(a3%o - a2%o, 4)
    allocate(tmp(0:m - 1))
    if (m > 0) tmp(0:m - 1) = a2%a%a(a2%o:a2%o + m - 1)''' + ins_tail
    d['insert_itert_ta'] = '''
    T, allocatable :: tmp(:)
    integer(4) :: p, m
    p = int(a1%i, 4)
    m = size(a2%a)
    allocate(tmp(0:m - 1))
    if (m > 0) tmp(0:m - 1) = a2%a(0:m - 1)''' + ins_tail
    d['erase_itert'] = '''
    integer(4) :: p
    p = int(a1%i, 4)
    if (self%n - p - 1 > 0) self%a%a(p:self%n - 2) = self%a%a(p + 1:self%n - 1)
    self%n = self%n - 1
    self%a%a(self%n) = Z
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    d['erase_itert_itert'] = '''
    integer(4) :: p, q, m
    p = int(a1%i, 4)
    q = int(a2%i, 4)
    m = q - p
    if (self%n - q > 0) self%a%a(p:p + self%n - q - 1) = self%a%a(q:self%n - 1)
    if (m > 0) self%a%a(self%n - m:self%n - 1) = Z
    self%n = self%n - m
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    d['eq'] = '''
    integer(4) :: i
    zres = .false.
    if (a1%n /= a2%n) return
    do i = 0, a1%n - 1
      if (.not. ''' + eqx(k, 'a1%a%a(i)', 'a2%a%a(i)') + ''') return
    end do
    zres = .true.'''
    out = {}
    for op, txt in d.items():
        txt = txt.replace('cpp_a_empty_K', 'cpp_a_empty_' + k).replace('cpp_a_grow_K', 'cpp_a_grow_' + k) \
            .replace('cpp_a_setcap_K', 'cpp_a_setcap_' + k).replace('A_new', A + '_new') \
            .replace('class(A)', 'class(%s)' % A).replace(' Z', ' ' + Z).replace('    T, ', '    %s, ' % t)
        out[op] = txt
    return out


def vec_o():
    d = {}
    d['new_0'] = '''
    allocate(zres)
    zres%a => cpp_a_empty_o()
    zres%mk%f => mk1
    zres%cm = cm2'''
    d['new_funct'] = '''
    allocate(zres)
    zres%a => cpp_a_empty_o()
    zres%fn => a1
    zres%mk%f => mk2
    zres%cm = cm3'''
    d['new_ul'] = '''
    allocate(zres)
    zres%mk%f => mk2
    zres%cm = cm3
    zres%a => cpp_arr_o_new(a1)
    zres%n = int(a1, 4)
    call cpp_a_fill_o(zres, 0, zres%n)'''
    d['new_ul_funct'] = '''
    allocate(zres)
    zres%fn => a2
    zres%mk%f => mk3
    zres%cm = cm4
    zres%a => cpp_arr_o_new(a1)
    zres%n = int(a1, 4)
    call cpp_a_fill_o(zres, 0, zres%n)'''
    d['new_ul_t'] = '''
    integer(4) :: i
    allocate(zres)
    zres%mk%f => mk3
    zres%cm = cm4
    zres%a => cpp_arr_o_new(a1)
    zres%n = int(a1, 4)
    do i = 0, zres%n - 1
      zres%a%a(i)%p => cpp_a_copy(a2, cm4)
      if (associated(cpp_exc)) return
    end do'''
    d['new_ta'] = '''
    integer(4) :: i
    allocate(zres)
    zres%mk%f => mk2
    zres%cm = cm3
    zres%a => cpp_arr_o_new(int(size(a1%a), 8))
    zres%n = size(a1%a)
    do i = 0, zres%n - 1
      zres%a%a(i)%p => cpp_a_copy(a1%a(i)%p, cm3)
      if (associated(cpp_exc)) return
    end do'''
    d['size'] = '''
    zres = int(self%n, 8)'''
    d['empty'] = '''
    zres = self%n == 0'''
    d['capacity'] = '''
    zres = int(size(self%a%a), 8)'''
    d['at'] = '''
    zres => null()
    if (ieor(a1, CPP_A_SIGN8) >= ieor(int(self%n, 8), CPP_A_SIGN8)) then
      cpp_exc => cpp_a_vec_range(a1, self%n)
      return
    end if
    zres => self%a%a(a1)'''
    d['front'] = '''
    zres => self%a%a(0)'''
    d['back'] = '''
    zres => self%a%a(self%n - 1)'''
    d['data'] = '''
    zres%a => self%a
    zres%o = 0_8'''
    d['begin'] = '''
    zres%v => self
    zres%a => self%a
    zres%i = 0_8'''
    d['end'] = '''
    zres%v => self
    zres%a => self%a
    zres%i = int(self%n, 8)'''
    d['rbegin'] = '''
    zres%v => self
    zres%i = int(self%n, 8)'''
    d['rend'] = '''
    zres%v => self
    zres%i = 0_8'''
    d['reserve'] = '''
    if (int(a1, 4) > size(self%a%a)) call cpp_a_setcap_o(self, int(a1, 4))'''
    d['shrink_to_fit'] = '''
    if (size(self%a%a) /= self%n) call cpp_a_setcap_o(self, self%n)'''
    d['push_back'] = '''
    if (self%n >= size(self%a%a)) call cpp_a_grow_o(self, self%n + 1)
    self%a%a(self%n)%p => a1
    self%n = self%n + 1'''
    d['emplace_back'] = '''
    if (self%n >= size(self%a%a)) call cpp_a_grow_o(self, self%n + 1)
    self%a%a(self%n)%p => a1
    self%n = self%n + 1
    zres => self%a%a(self%n - 1)'''
    d['pop_back'] = '''
    self%n = self%n - 1
    self%a%a(self%n)%p => null()'''
    d['clear'] = '''
    integer(4) :: i
    do i = 0, self%n - 1
      self%a%a(i)%p => null()
    end do
    self%n = 0'''
    d['resize_ul'] = '''
    integer(4) :: m, i
    m = int(a1, 4)
    if (m > self%n) then
      call cpp_a_grow_o(self, m)
      call cpp_a_fill_o(self, self%n, m)
      if (associated(cpp_exc)) return
    else
      do i = m, self%n - 1
        self%a%a(i)%p => null()
      end do
    end if
    self%n = m'''
    d['resize_ul_t'] = '''
    integer(4) :: m, i
    m = int(a1, 4)
    if (m > self%n) then
      call cpp_a_grow_o(self, m)
      do i = self%n, m - 1
        self%a%a(i)%p => cpp_a_copy(a2, self%cm)
        if (associated(cpp_exc)) return
      end do
    else
      do i = m, self%n - 1
        self%a%a(i)%p => null()
      end do
    end if
    self%n = m'''
    d['assign_ul_t'] = '''
    integer(4) :: m, i
    m = int(a1, 4)
    if (m > size(self%a%a)) then
      self%a => cpp_arr_o_new(int(m, 8))
    else
      do i = 0, size(self%a%a) - 1
        self%a%a(i)%p => null()
      end do
    end if
    do i = 0, m - 1
      self%a%a(i)%p => cpp_a_copy(a2, self%cm)
      if (associated(cpp_exc)) return
    end do
    self%n = m'''
    d['assign_itert_itert'] = '''
    class(cpp_arr_o), pointer :: na, src
    integer(4) :: m, i
    integer(8) :: o
    m = int(a2%i - a1%i, 4)
    src => a1%a
    o = a1%i
    na => cpp_arr_o_new(int(m, 8))
    do i = 0, m - 1
      na%a(i)%p => cpp_a_copy(src%a(o + i)%p, self%cm)
      if (associated(cpp_exc)) return
    end do
    self%a => na
    self%n = m'''
    d['assign_vect'] = '''
    class(cpp_arr_o), pointer :: na
    integer(4) :: i
    if (associated(a1, self)) return
    na => cpp_arr_o_new(int(a1%n, 8))
    do i = 0, a1%n - 1
      na%a(i)%p => cpp_a_copy(a1%a%a(i)%p, self%cm)
      if (associated(cpp_exc)) return
    end do
    self%a => na
    self%n = a1%n
    if (.not. associated(self%fn)) self%fn => a1%fn'''
    d['movefrom_vect'] = '''
    if (associated(a1, self)) return
    self%a => a1%a
    self%n = a1%n
    if (.not. associated(self%fn)) self%fn => a1%fn
    a1%a => cpp_a_empty_o()
    a1%n = 0'''
    d['movefrom_ta'] = '''
    class(cpp_arr_o), pointer :: na
    integer(4) :: i
    na => cpp_arr_o_new(int(size(a1%a), 8))
    do i = 0, size(a1%a) - 1
      na%a(i)%p => cpp_a_copy(a1%a(i)%p, self%cm)
      if (associated(cpp_exc)) return
    end do
    self%a => na
    self%n = size(a1%a)'''
    d['clone'] = '''
    class(cpp_arr_o), pointer :: na
    integer(4) :: i
    zres => null()
    na => cpp_arr_o_new(int(self%n, 8))
    do i = 0, self%n - 1
      na%a(i)%p => cpp_a_copy(self%a%a(i)%p, self%cm)
      if (associated(cpp_exc)) return
    end do
    allocate(zres)
    zres%a => na
    zres%n = self%n
    zres%mk = self%mk
    zres%cm = self%cm
    zres%fn => self%fn'''
    d['swap'] = '''
    class(cpp_arr_o), pointer :: ta
    integer(4) :: tn
    ta => self%a
    tn = self%n
    self%a => a1%a
    self%n = a1%n
    a1%a => ta
    a1%n = tn'''
    d['insert_itert_t'] = '''
    integer(4) :: p
    p = int(a1%i, 4)
    call cpp_a_grow_o(self, self%n + 1)
    if (self%n > p) self%a%a(p + 1:self%n) = self%a%a(p:self%n - 1)
    self%a%a(p)%p => a2
    self%n = self%n + 1
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    d['insert_itert_itert_itert'] = '''
    type(cpp_slot), allocatable :: tmp(:)
    integer(4) :: p, m, i
    p = int(a1%i, 4)
    m = int(a3%i - a2%i, 4)
    allocate(tmp(0:m - 1))
    do i = 0, m - 1
      tmp(i)%p => cpp_a_copy(a2%a%a(a2%i + i)%p, self%cm)
      if (associated(cpp_exc)) return
    end do
    call cpp_a_grow_o(self, self%n + m)
    if (self%n > p) self%a%a(p + m:self%n + m - 1) = self%a%a(p:self%n - 1)
    if (m > 0) self%a%a(p:p + m - 1) = tmp(0:m - 1)
    self%n = self%n + m
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    d['erase_itert'] = '''
    integer(4) :: p
    p = int(a1%i, 4)
    if (self%n - p - 1 > 0) self%a%a(p:self%n - 2) = self%a%a(p + 1:self%n - 1)
    self%n = self%n - 1
    self%a%a(self%n)%p => null()
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    d['erase_itert_itert'] = '''
    integer(4) :: p, q, m, i
    p = int(a1%i, 4)
    q = int(a2%i, 4)
    m = q - p
    if (self%n - q > 0) self%a%a(p:p + self%n - q - 1) = self%a%a(q:self%n - 1)
    do i = self%n - m, self%n - 1
      self%a%a(i)%p => null()
    end do
    self%n = self%n - m
    zres%v => self
    zres%a => self%a
    zres%i = int(p, 8)'''
    d['eq'] = '''
    integer(4) :: i
    zres = .false.
    if (a1%n /= a2%n) return
    do i = 0, a1%n - 1
      if (.not. cpp_a_eq(a1%a%a(i)%p, a2%a%a(i)%p)) return
    end do
    zres = .true.'''
    return d


VT = {k: vec_prim(k) for k in PRIM}
VT['o'] = vec_o()
for name in order:
    m = re.match(r'^cpp_vec_([bdfilosz])_(.*)$', name)
    if m:
        k, op = m.groups()
        if op not in VT[k]:
            sys.exit('gen_rt_a: no template for ' + name)
        body(name, VT[k][op])

# ---------------------------------------------------------------------------------------------- module text
HEADER = r'''! cpp_rt_a.f90 - part A (core) of the Fortran runtime of the SWMM6 engine port: the root type cpp_object and its
! default bindings, cpp_slot, the unsigned vararg boxes, the pending exception cpp_exc and the maker interface; arrays
! (cpp_arr_*), std::vector (cpp_vec_*), vector iterators (cpp_iter_*, cpp_reviter_o), raw pointers (cpp_ptr_*,
! cpp_cptr), std::span, std::pair, std::optional, std::variant, std::string (cpp_str), std::min/max/clamp, the
! array helpers, the C++ exception classes, the System delegate types and the Ref delegates (RefAt, RefGet, MemPtr),
! and the unsigned and double helpers. The specification is the C# runtime: cs/runtime/Std.cs, Str.cs and the CPtr
! struct of CRuntime.cs. GENERATED by f90/runtime/gen_rt_a.py from the stub's signatures: edit the generator.
!
! Layout (the engine and parts B, C and D read these components directly):
!  - cpp_arr_<k>: component a(0:len-1), always allocated. A vector cpp_vec_<k> holds an array object a (its size is
!    the capacity) and the count n; slots n.. hold the element type's zero (null for cpp_arr_o slots).
!  - cpp_iter_<k>: a (the array it was taken over), i (the index) and v (the vector, null for an iterator over a bare
!    array, such as cpp_str_begin's); it + k re-reads v%a, as the C#'s Iter(Vec, i) does.
!  - cpp_ptr_<k>: a and o (offset); for d, i, l and o also ob and at (a pointer to a field: the object and the
!    lambda that reaches the field; a Ptr is a field pointer when at is associated).
!  - cpp_str: b (a cpp_arr_b; size(b%a) >= n + 1) and n. cpp_cptr: b and o. cpp_reviter_o: v and i (one past).
!  - cpp_vec_o, cpp_opt_o and cpp_pair keep the makers and copy modes they were constructed with (mk/cm, mk1/cm1,
!    mk2/cm2; a maker is a type(cpp_mkr) whose procedure pointer f is called, mk%f()) and copy their elements with
!    them, as C#'s Elem<T>.Copy does; cpp_vec_o also keeps fn, the Func<T> of Vec(Func<T>) (C#'s mk), which makes
!    its new elements when it is set.
!  - cpp_cppexception: msg, the cpp_str that what() returns.
!  Runtime classes that implement C#'s ICopy (Str, Vec, Pair, Opt, Variant) override the clone and assign bindings.
!  Helpers for the other parts (public, prefixed cpp_a_): cpp_a_copy(x, cm) (Elem<T>.Copy under a copy mode),
!  cpp_a_eq(x, y) (EqualityComparer<T>.Default of erased values), cpp_a_str_of(chars), cpp_a_str_bytes(arr, off,
!  len), cpp_a_str_compare(x, y) (Str.compare), cpp_a_strlen(p), cpp_a_dec8 / cpp_a_udec8 (decimal text),
!  cpp_a_exc(kind, chars) (a new exception: 1 runtime_error, 2 out_of_range, 3 invalid_argument, 4 logic_error),
!  and makers cpp_a_mk_str, cpp_a_mk_null, cpp_a_mk_i/l/d/z (a new Str, null, a zero box).
!
! Deliberate differences from the C#:
!  - Vec<T>.Assign(Vec<T>) of a primitive vector copies in place when the storage is already of the source's size
!    (C# allocates a new array of that size, so the capacity is the same; only an iterator or pointer taken before
!    the assignment can tell, and it sees what it would in C++). This keeps per-step state copies from leaking.
!  - Str.find / find_first_of / find_first_not_of with a position that is negative as a long (npos) return npos
!    (the C# indexes b[-1] and throws); strlen stops at the end of the buffer if there is no NUL.
!  - Where the C# would throw NullReferenceException the Fortran does not crash: Arr.Assign of an ICopy element type
!    onto a null element stores a copy; what() of an exception whose msg was never set is "std::exception"; a Str
!    allocated without a constructor gets its buffer on first use. A copy mode that does not fit the value (2 on a
!    number or struct box, 3 on a non-array) copies the value by what it is.
!  - Nothing is freed (the engine never frees objects): a vector's or string's old storage stays allocated when it
!    grows, as C# leaves it to the collector, so iterators and pointers into it stay valid. Temporaries the runtime
!    makes for itself (Str.compare's substring) are freed.
! to_string(double) is "%f" by exact decimal expansion, rounded half-even on the exact value as glibc does; the big
! integer and digit routines are copied from the SWMM5 Fortran port's runtime (/home/claude/swmm5-ports/f90/runtime/
! crt_format.f90: set_big, mul_small, mul_pow5, mul_pow2, exact_digits, round_digits, render_f). Str.stod is in the
! submodule cpp_rt_a_crt (f90/runtime/cpp_rt_a_crt.f90), which calls part C's strtod.
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.'''

out = []
w = out.append
w(HEADER)
w('module cpp_rt_a')
w('  implicit none')
w('  integer(8), parameter :: CPP_NPOS = -1_8                         ! std::string::npos')
w('  integer(8), parameter :: CPP_A_SIGN8 = -9223372036854775807_8 - 1_8')
w('  integer(4), parameter :: CPP_A_SIGN4 = -2147483647 - 1')
w('  abstract interface')
for ln in maker_iface:
    w(ln)
w('  end interface')
w('  ! a maker held by a container: a procedure pointer in a non-polymorphic wrapper, copied by assignment (gfortran 13')
w('  ! crashes on a procedure pointer component of a polymorphic object, and on associated() of one whose result is')
w('  ! class(*), pointer); it starts as cpp_a_mk_null')
w('  type :: cpp_mkr')
w('    procedure(cpp_maker), pointer, nopass :: f => cpp_a_mk_null')
w('  end type cpp_mkr')
for name in type_order:
    for ln in REPL.get(name, types[name]):
        w(ln)
w('  class(cpp_object), pointer :: cpp_exc => null()')
for k in PRIM + 'o':
    w('  class(cpp_arr_%s), pointer, private :: cpp_a_e_%s => null()     ! Array.Empty<T>()' % (k, k))
w('  abstract interface')
for ln in absint:
    w(ln)
w('  end interface')
# the separate module procedures (bodies in the submodule)
w('  interface')
for name in sorted(SUBMOD):
    kind, hdr = procs[name]
    w(hdr[0].replace('recursive %s' % kind, 'recursive module %s' % kind))
    for ln in hdr[1:]:
        w(ln)
    w('  end %s %s' % (kind, name))
w('  end interface')
w('contains')

# the default bindings of cpp_object
w('''  ! ------------------------------------------------------------------ cpp_object's default bindings
  recursive function cpp_object_clone(self) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => self
  end function cpp_object_clone
  recursive subroutine cpp_object_assign(self, other)
    class(cpp_object), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
  end subroutine cpp_object_assign
  recursive subroutine cpp_object_dispose(self)
    class(cpp_object), intent(inout), target :: self
  end subroutine cpp_object_dispose
  recursive function cpp_object_hash_of(self, k) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(*), pointer, intent(in) :: k
    integer(8) :: zres
    zres = 0
  end function cpp_object_hash_of
  recursive function cpp_object_call2(self, a, b) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(*), pointer, intent(in) :: a, b
    logical :: zres
    zres = .false.
  end function cpp_object_call2''')

HELPERS = open(os.path.join(HERE, 'gen_rt_a_helpers.inc')).read().rstrip('\n')
w(HELPERS)

# per-kind storage helpers
for k in PRIM + 'o':
    A = 'cpp_arr_' + k
    w('''  recursive function cpp_a_empty_%(k)s() result(zres)
    class(%(A)s), pointer :: zres
    if (.not. associated(cpp_a_e_%(k)s)) cpp_a_e_%(k)s => %(A)s_new(0_8)
    zres => cpp_a_e_%(k)s
  end function cpp_a_empty_%(k)s
  ! Array.Resize(ref a, cap): a new array, the old elements copied (the old array is left as it is)
  recursive subroutine cpp_a_setcap_%(k)s(self, cap)
    class(cpp_vec_%(k)s), intent(inout), target :: self
    integer(4), intent(in) :: cap
    class(%(A)s), pointer :: na
    integer(4) :: m
    na => %(A)s_new(int(cap, 8))
    m = min(cap, size(self%%a%%a))
    if (m > 0) na%%a(0:m - 1) = self%%a%%a(0:m - 1)
    self%%a => na
  end subroutine cpp_a_setcap_%(k)s
  ! libstdc++'s growth: a full vector grows to size + max(size, 1), or to what is needed if that is more
  recursive subroutine cpp_a_grow_%(k)s(self, need)
    class(cpp_vec_%(k)s), intent(inout), target :: self
    integer(4), intent(in) :: need
    if (need <= size(self%%a%%a)) return
    call cpp_a_setcap_%(k)s(self, max(need, self%%n + max(self%%n, 1)))
  end subroutine cpp_a_grow_%(k)s''' % {'k': k, 'A': A})
    # the ICopy bindings
    w('''  recursive function cpp_a_bclone_vec_%(k)s(self) result(zres)
    class(cpp_vec_%(k)s), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => cpp_vec_%(k)s_clone(self)
  end function cpp_a_bclone_vec_%(k)s
  recursive subroutine cpp_a_bassign_vec_%(k)s(self, other)
    class(cpp_vec_%(k)s), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_vec_%(k)s), pointer :: o
    o => null()
    select type (other)
    class is (cpp_vec_%(k)s)
      o => other
    end select
    if (associated(o)) call cpp_vec_%(k)s_assign_vect(self, o)
  end subroutine cpp_a_bassign_vec_%(k)s''' % {'k': k})

w('  ! ------------------------------------------------------------------ the manifest\'s procedures')
missing = []
for name in order:
    if name in SUBMOD:
        continue
    if name not in B:
        missing.append(name)
        continue
    kind, hdr = procs[name]
    for ln in hdr:
        w(ln)
    w(B[name])
    w('  end %s %s' % (kind, name))
if missing:
    sys.exit('gen_rt_a: no body for ' + ', '.join(missing))
unused = sorted(set(B) - set(order))
w('end module cpp_rt_a')
text = '\n'.join(out) + '\n'

# ---------------------------------------------------------------------------------------------- coverage
parts = [l.split('\t') for l in open(PARTS).read().split('\n') if l and not l.startswith('#')]
a_entries = [(p[0], p[2]) for p in parts if len(p) > 2 and p[1] == 'A']
bad = []
for name, kind in a_entries:
    if kind == 'TYPE':
        if not re.search(r'^  type\b[^\n]*::\s*%s\s*$' % name, text, re.M):
            bad.append(name)
    elif kind in ('FUNCTION', 'SUBROUTINE'):
        if not re.search(r'^  recursive (module )?(function|subroutine) %s\(' % name, text, re.M):
            bad.append(name)
    else:
        if not re.search(r'\b%s\b' % name, text):
            bad.append(name)
if bad:
    sys.exit('gen_rt_a: part A entries missing: ' + ', '.join(bad))
open(OUT, 'w').write(text)
nproc = len([n for n in order])
print('gen_rt_a: wrote %s (%d lines): %d part A entries (%d types, %d procedures, %d in the submodule); '
      'templates not used: %d' % (os.path.relpath(OUT), text.count('\n'), len(a_entries),
                                  sum(1 for _, k in a_entries if k == 'TYPE'), nproc, len(SUBMOD), len(unused)))
