  ! ------------------------------------------------------------------ helpers (gen_rt_a_helpers.inc)
  ! Elem<T>.Copy of an erased value under its copy mode: 0 a value (a new box with the same contents), 1 a reference
  ! (shared), 2 ICopy (x%clone(), the copy constructor), 3 an array (ArrCopy.Deep). Null stays null. A mode that
  ! does not fit the value (2 on a box, 3 on a non-array) falls back to what the value is.
  recursive function cpp_a_copy(x, cm) result(r)
    class(*), pointer, intent(in) :: x
    integer(4), intent(in) :: cm
    class(*), pointer :: r
    r => null()
    if (.not. associated(x)) return
    select case (cm)
    case (1)
      r => x
    case (2)
      select type (x)
      class is (cpp_object)
        r => x%clone()
      class default
        allocate(r, source=x)
      end select
    case (3)
      r => cpp_a_deep(x)
    case default
      allocate(r, source=x)
    end select
  end function cpp_a_copy

  ! ArrCopy.Deep: a C array copied with its object, every row and element (an array of arrays row by row; an array
  ! of objects with each element's clone binding, which is the copy constructor of an ICopy class and the object
  ! itself otherwise; an array of values with a copy of each value)
  recursive function cpp_a_deep(x) result(r)
    class(*), pointer, intent(in) :: x
    class(*), pointer :: r
    class(cpp_arr_o), pointer :: ro
    class(*), pointer :: e
    integer(4) :: i
    r => null()
    if (.not. associated(x)) return
    select type (x)
    type is (cpp_arr_b)
      r => cpp_arr_clone__b(x)
    type is (cpp_arr_d)
      r => cpp_arr_clone__d(x)
    type is (cpp_arr_i)
      r => cpp_arr_clone__i(x)
    type is (cpp_arr_l)
      r => cpp_arr_clone__l(x)
    type is (cpp_arr_s)
      r => cpp_arr_clone__s(x)
    type is (cpp_arr_z)
      r => cpp_arr_clone__z(x)
    type is (cpp_arr_f)
      allocate(cpp_arr_f :: r)
      select type (r)
      type is (cpp_arr_f)
        allocate(r%a(0:size(x%a) - 1), source=x%a)
      end select
    type is (cpp_arr_o)
      ro => cpp_arr_o_new(int(size(x%a), 8))
      do i = 0, size(x%a) - 1
        e => x%a(i)%p
        if (.not. associated(e)) cycle
        select type (q => e)
        class is (cpp_arr_b)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_arr_d)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_arr_f)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_arr_i)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_arr_l)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_arr_o)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_arr_s)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_arr_z)
          ro%a(i)%p => cpp_a_deep(e)
        class is (cpp_object)
          ro%a(i)%p => q%clone()
          if (associated(cpp_exc)) return
        class default
          allocate(ro%a(i)%p, source=q)
        end select
      end do
      r => ro
    class is (cpp_object)
      r => x%clone()
    class default
      allocate(r, source=x)
    end select
  end function cpp_a_deep

  ! EqualityComparer<T>.Default.Equals of two erased values: a Str by its bytes, a number or logical by value (a
  ! double's Equals has NaN equal to NaN), a CPtr by ==, any other object by identity (the C#'s classes do not
  ! override Equals)
  recursive function cpp_a_eq(x, y) result(r)
    class(*), pointer, intent(in) :: x, y
    logical :: r
    r = .false.
    if (.not. associated(x) .or. .not. associated(y)) then
      r = .not. associated(x) .and. .not. associated(y)
      return
    end if
    select type (xx => x)
    class is (cpp_str)
      select type (yy => y)
      class is (cpp_str)
        r = cpp_a_str_eq(xx, yy)
      end select
    type is (real(8))
      select type (yy => y)
      type is (real(8))
        r = xx == yy .or. (xx /= xx .and. yy /= yy)
      end select
    type is (real(4))
      select type (yy => y)
      type is (real(4))
        r = xx == yy .or. (xx /= xx .and. yy /= yy)
      end select
    type is (integer(4))
      select type (yy => y)
      type is (integer(4))
        r = xx == yy
      end select
    type is (integer(8))
      select type (yy => y)
      type is (integer(8))
        r = xx == yy
      end select
    type is (integer(2))
      select type (yy => y)
      type is (integer(2))
        r = xx == yy
      end select
    type is (integer(1))
      select type (yy => y)
      type is (integer(1))
        r = xx == yy
      end select
    type is (logical)
      select type (yy => y)
      type is (logical)
        r = xx .eqv. yy
      end select
    type is (cpp_cptr)
      select type (yy => y)
      type is (cpp_cptr)
        r = cpp_a_cptr_eq(xx, yy)
      end select
    type is (cpp_ptr_d)
      select type (yy => y)
      type is (cpp_ptr_d)
        r = cpp_ptr_d_op_eq(xx, yy)
      end select
    type is (cpp_ptr_o)
      select type (yy => y)
      type is (cpp_ptr_o)
        r = .not. cpp_ptr_o_op_ne(xx, yy)
      end select
    class default
      r = associated(x, y)
    end select
  end function cpp_a_eq

  ! Str.Equals(Str) of two non-null strings
  recursive function cpp_a_str_eq(x, y) result(r)
    class(cpp_str), intent(in) :: x, y
    logical :: r
    integer(4) :: i
    r = .false.
    if (x%n /= y%n) return
    do i = 0, x%n - 1
      if (x%b%a(i) /= y%b%a(i)) return
    end do
    r = .true.
  end function cpp_a_str_eq

  ! ReferenceEquals of two references (null equals null)
  recursive function cpp_a_same(x, y) result(r)
    class(*), pointer, intent(in) :: x, y
    logical :: r
    if (.not. associated(x) .or. .not. associated(y)) then
      r = .not. associated(x) .and. .not. associated(y)
    else
      r = associated(x, y)
    end if
  end function cpp_a_same

  ! Vec<T>.Fill(from, to): the Func<T> of Vec(Func<T>) when there is one, else Elem<T>.Make (the translator's maker:
  ! a new object, null for a type without a default constructor, a zero box for a value type)
  recursive subroutine cpp_a_fill_o(self, from, to)
    class(cpp_vec_o), intent(inout), target :: self
    integer(4), intent(in) :: from, to
    integer(4) :: i
    do i = from, to - 1
      if (associated(self%fn)) then
        self%a%a(i)%p => self%fn%invoke()
        if (associated(cpp_exc)) return
      else
        self%a%a(i)%p => self%mk%f()
      end if
    end do
  end subroutine cpp_a_fill_o

  ! CPtr ==: the same buffer and (unless both are null) the same offset
  recursive function cpp_a_cptr_eq(x, y) result(r)
    type(cpp_cptr), intent(in) :: x, y
    logical :: r
    if (associated(x%b) .neqv. associated(y%b)) then
      r = .false.
    else if (.not. associated(x%b)) then
      r = .true.
    else
      r = associated(x%b, y%b)
      if (r) r = x%o == y%o
    end if
  end function cpp_a_cptr_eq

  ! R.strlen: the bytes before the NUL (or before the end of the buffer)
  recursive function cpp_a_strlen(p) result(r)
    type(cpp_cptr), intent(in) :: p
    integer(4) :: r
    integer(4) :: i, e
    e = size(p%b%a)
    i = p%o
    do while (i < e)
      if (p%b%a(i) == 0_1) exit
      i = i + 1
    end do
    r = i - p%o
  end function cpp_a_strlen

  ! is byte c one of the NUL-terminated set at p
  recursive function cpp_a_in(c, p) result(r)
    integer(1), intent(in) :: c
    type(cpp_cptr), intent(in) :: p
    logical :: r
    integer(4) :: i, e
    r = .false.
    e = size(p%b%a)
    i = p%o
    do while (i < e)
      if (p%b%a(i) == 0_1) exit
      if (p%b%a(i) == c) then
        r = .true.
        return
      end if
      i = i + 1
    end do
  end function cpp_a_in

  ! new Str(string): the characters' codes as bytes
  recursive function cpp_a_str_of(s) result(zres)
    character(len=*), intent(in) :: s
    class(cpp_str), pointer :: zres
    integer(4) :: i
    allocate(zres)
    zres%b => cpp_arr_b_new(int(len(s) + 1, 8))
    do i = 1, len(s)
      zres%b%a(i - 1) = transfer(s(i:i), 0_1)
    end do
    zres%n = len(s)
  end function cpp_a_str_of

  ! new Str(byte[] src, int off, int len): a buffer of len + 1
  recursive function cpp_a_str_bytes(src, off, m) result(zres)
    class(cpp_arr_b), pointer, intent(in) :: src
    integer(4), intent(in) :: off, m
    class(cpp_str), pointer :: zres
    allocate(zres)
    zres%b => cpp_arr_b_new(int(m + 1, 8))
    if (m > 0) zres%b%a(0:m - 1) = src%a(off:off + m - 1)
    zres%n = m
  end function cpp_a_str_bytes

  ! Str.Reserve(need): room for need bytes and the NUL; growth doubles (a new buffer, the old one left as it is)
  recursive subroutine cpp_a_str_reserve(self, need)
    class(cpp_str), intent(inout), target :: self
    integer(4), intent(in) :: need
    class(cpp_arr_b), pointer :: nb
    integer(4) :: old
    if (.not. associated(self%b)) self%b => cpp_arr_b_new(16_8)
    old = size(self%b%a)
    if (need + 1 <= old) return
    nb => cpp_arr_b_new(int(max(need + 1, old * 2), 8))
    if (old > 0) nb%a(0:old - 1) = self%b%a(0:old - 1)
    self%b => nb
  end subroutine cpp_a_str_reserve

  ! Str.assign(CPtr p, ulong len) and Assign(CPtr): a new buffer of len + 1 with the bytes
  recursive subroutine cpp_a_str_set(self, src0, off, m)
    class(cpp_str), intent(inout), target :: self
    class(cpp_arr_b), pointer, intent(in) :: src0
    integer(4), intent(in) :: off, m
    class(cpp_arr_b), pointer :: src, t
    src => src0
    t => cpp_arr_b_new(int(m + 1, 8))
    if (m > 0) t%a(0:m - 1) = src%a(off:off + m - 1)
    self%b => t
    self%n = m
  end subroutine cpp_a_str_set

  ! Str.append of m bytes at src(off:): Reserve(n + m), then the copy (src taken before the buffer can move)
  recursive subroutine cpp_a_str_app(self, src0, off, m)
    class(cpp_str), intent(inout), target :: self
    class(cpp_arr_b), pointer, intent(in) :: src0
    integer(4), intent(in) :: off, m
    class(cpp_arr_b), pointer :: src
    src => src0
    call cpp_a_str_reserve(self, self%n + m)
    if (m > 0) self%b%a(self%n:self%n + m - 1) = src%a(off:off + m - 1)
    self%n = self%n + m
  end subroutine cpp_a_str_app

  ! Str.rfind(int ch, ulong pos)
  recursive function cpp_a_str_rfind_ch(self, ch, pos) result(zres)
    class(cpp_str), intent(in) :: self
    integer(4), intent(in) :: ch
    integer(8), intent(in) :: pos
    integer(8) :: zres
    integer(8) :: i
    integer(1) :: c
    zres = CPP_NPOS
    if (self%n == 0) return
    c = int(ch, 1)
    i = cpp_m_min_ul_ul(pos, int(self%n - 1, 8))
    do while (i >= 0)
      if (self%b%a(i) == c) then
        zres = i
        return
      end if
      i = i - 1
    end do
  end function cpp_a_str_rfind_ch

  ! Str.compare(Str): char_traits<char>::compare (memcmp: unsigned bytes), then the length
  recursive function cpp_a_str_compare(x, y) result(r)
    class(cpp_str), intent(in) :: x, y
    integer(4) :: r
    integer(4) :: i, m, p, q
    m = min(x%n, y%n)
    do i = 0, m - 1
      p = iand(int(x%b%a(i), 4), 255)
      q = iand(int(y%b%a(i), 4), 255)
      if (p /= q) then
        r = merge(-1, 1, p < q)
        return
      end if
    end do
    r = x%n - y%n
  end function cpp_a_str_compare

  ! free a Str the runtime made for itself and nobody else can see
  recursive subroutine cpp_a_str_free(s)
    class(cpp_str), pointer, intent(inout) :: s
    if (.not. associated(s)) return
    if (associated(s%b)) then
      deallocate(s%b)
    end if
    deallocate(s)
  end subroutine cpp_a_str_free

  ! decimal text of a signed / an unsigned 64-bit value (no Fortran I/O: the runtime may be called inside an I/O
  ! statement)
  recursive function cpp_a_udec8(v) result(s)
    integer(8), intent(in) :: v
    character(len=:), allocatable :: s
    character(len=20) :: buf
    integer(8) :: x, q
    integer(4) :: k
    x = v
    k = 21
    do
      q = cpp_udiv8(x, 10_8)
      k = k - 1
      buf(k:k) = achar(48 + int(x - q * 10_8, 4))
      x = q
      if (x == 0) exit
    end do
    s = buf(k:20)
  end function cpp_a_udec8

  recursive function cpp_a_dec8(v) result(s)
    integer(8), intent(in) :: v
    character(len=:), allocatable :: s
    if (v < 0) then
      s = '-' // cpp_a_udec8(not(v) + 1_8)
    else
      s = cpp_a_udec8(v)
    end if
  end function cpp_a_dec8

  ! a new C++ exception with the message: 1 runtime_error, 2 out_of_range, 3 invalid_argument, 4 logic_error,
  ! anything else std::exception
  recursive function cpp_a_exc(kind, s) result(zres)
    integer(4), intent(in) :: kind
    character(len=*), intent(in) :: s
    class(cpp_cppexception), pointer :: zres
    select case (kind)
    case (1)
      allocate(cpp_runtimeerror :: zres)
    case (2)
      allocate(cpp_outofrange :: zres)
    case (3)
      allocate(cpp_invalidargument :: zres)
    case (4)
      allocate(cpp_logicerror :: zres)
    case default
      allocate(cpp_cppexception :: zres)
    end select
    zres%msg => cpp_a_str_of(s)
  end function cpp_a_exc

  ! Vec<T>.at's out_of_range
  recursive function cpp_a_vec_range(i, n) result(zres)
    integer(8), intent(in) :: i
    integer(4), intent(in) :: n
    class(cpp_cppexception), pointer :: zres
    zres => cpp_a_exc(2, 'vector::_M_range_check: __n (which is ' // cpp_a_udec8(i) // &
      ') >= this->size() (which is ' // cpp_a_dec8(int(n, 8)) // ')')
  end function cpp_a_vec_range

  ! makers for the other parts (the engine's own are its h_mk_* helpers)
  recursive function cpp_a_mk_str() result(zres)
    class(*), pointer :: zres
    zres => cpp_str_new_0()
  end function cpp_a_mk_str
  recursive function cpp_a_mk_null() result(zres)
    class(*), pointer :: zres
    zres => null()
  end function cpp_a_mk_null
  recursive function cpp_a_mk_i() result(zres)
    class(*), pointer :: zres
    allocate(zres, source=0)
  end function cpp_a_mk_i
  recursive function cpp_a_mk_l() result(zres)
    class(*), pointer :: zres
    allocate(zres, source=0_8)
  end function cpp_a_mk_l
  recursive function cpp_a_mk_d() result(zres)
    class(*), pointer :: zres
    allocate(zres, source=0.0_8)
  end function cpp_a_mk_d
  recursive function cpp_a_mk_z() result(zres)
    class(*), pointer :: zres
    allocate(zres, source=.false.)
  end function cpp_a_mk_z

  ! ---- the ICopy bindings of Str, Pair, Opt and Variant
  recursive function cpp_a_bclone_str(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => cpp_str_clone(self)
  end function cpp_a_bclone_str
  recursive subroutine cpp_a_bassign_str(self, other)
    class(cpp_str), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_str), pointer :: o
    o => null()
    select type (other)
    class is (cpp_str)
      o => other
    end select
    if (associated(o)) call cpp_str_assign_str(self, o)
  end subroutine cpp_a_bassign_str
  recursive function cpp_a_bclone_pair(self) result(zres)
    class(cpp_pair), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => cpp_pair_clone(self)
  end function cpp_a_bclone_pair
  ! Pair.Assign(o): first = Copy(o.first); second = Copy(o.second)
  recursive subroutine cpp_a_bassign_pair(self, other)
    class(cpp_pair), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(*), pointer :: x
    select type (other)
    class is (cpp_pair)
      x => cpp_a_copy(other%first%p, self%cm1)
      if (associated(cpp_exc)) return
      self%first%p => x
      x => cpp_a_copy(other%second%p, self%cm2)
      if (associated(cpp_exc)) return
      self%second%p => x
    end select
  end subroutine cpp_a_bassign_pair
  recursive function cpp_a_bclone_opt_d(self) result(zres)
    class(cpp_opt_d), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => cpp_opt_d_clone(self)
  end function cpp_a_bclone_opt_d
  recursive subroutine cpp_a_bassign_opt_d(self, other)
    class(cpp_opt_d), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_opt_d), pointer :: o
    o => null()
    select type (other)
    class is (cpp_opt_d)
      o => other
    end select
    if (associated(o)) call cpp_opt_d_assign(self, o)
  end subroutine cpp_a_bassign_opt_d
  recursive function cpp_a_bclone_opt_o(self) result(zres)
    class(cpp_opt_o), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => cpp_opt_o_clone(self)
  end function cpp_a_bclone_opt_o
  recursive subroutine cpp_a_bassign_opt_o(self, other)
    class(cpp_opt_o), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_opt_o), pointer :: o
    o => null()
    select type (other)
    class is (cpp_opt_o)
      o => other
    end select
    if (associated(o)) call cpp_opt_o_assign(self, o)
  end subroutine cpp_a_bassign_opt_o
  recursive function cpp_a_bclone_variant(self) result(zres)
    class(cpp_variant), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => cpp_variant_clone(self)
  end function cpp_a_bclone_variant
  recursive subroutine cpp_a_bassign_variant(self, other)
    class(cpp_variant), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_variant), pointer :: o
    o => null()
    select type (other)
    class is (cpp_variant)
      o => other
    end select
    if (associated(o)) call cpp_variant_assign(self, o)
  end subroutine cpp_a_bassign_variant

  ! ---- "%f" of a double (Str.to_string(double)): glibc's output, from the exact decimal expansion rounded
  ! half-even at the sixth decimal. Big integers in base 1e9, little-endian limbs L(1:n); the routines below are
  ! the SWMM5 Fortran port's (crt_format.f90: set_big, mul_small, mul_pow5, mul_pow2, exact_digits, round_digits).
  recursive subroutine cpp_a_big_mul(L, n, f)
    integer(8), intent(inout) :: L(:)
    integer(4), intent(inout) :: n
    integer(8), intent(in) :: f
    integer(8) :: carry, t
    integer(4) :: i
    carry = 0
    do i = 1, n
      t = L(i) * f + carry
      carry = t / 1000000000_8
      L(i) = t - carry * 1000000000_8
    end do
    do while (carry > 0)
      if (n >= size(L)) error stop 'cpp_rt_a: big integer overflow'
      n = n + 1
      L(n) = mod(carry, 1000000000_8)
      carry = carry / 1000000000_8
    end do
  end subroutine cpp_a_big_mul

  recursive subroutine cpp_a_big_pow5(L, n, k)
    integer(8), intent(inout) :: L(:)
    integer(4), intent(inout) :: n
    integer(4), intent(in) :: k
    integer(8), parameter :: P5(0:13) = [1_8, 5_8, 25_8, 125_8, 625_8, 3125_8, 15625_8, 78125_8, 390625_8, &
      1953125_8, 9765625_8, 48828125_8, 244140625_8, 1220703125_8]
    integer(4) :: r, s
    r = k
    do while (r > 0)
      s = min(r, 13)
      call cpp_a_big_mul(L, n, P5(s))
      r = r - s
    end do
  end subroutine cpp_a_big_pow5

  recursive subroutine cpp_a_big_pow2(L, n, k)
    integer(8), intent(inout) :: L(:)
    integer(4), intent(inout) :: n
    integer(4), intent(in) :: k
    integer(4) :: r, s
    r = k
    do while (r > 0)
      s = min(r, 30)
      call cpp_a_big_mul(L, n, ishft(1_8, s))
      r = r - s
    end do
  end subroutine cpp_a_big_pow2

  ! value = 0.dg(1)dg(2)...dg(nd) x 10**dp exactly, dg(nd) /= 0, for a finite nonzero double's bits
  recursive subroutine cpp_a_exact_digits(bits, dg, nd, dp)
    integer(8), intent(in) :: bits
    integer(1), intent(inout) :: dg(:)
    integer(4), intent(out) :: nd, dp
    integer(8) :: m, ex, t, L(100)
    integer(4) :: e2, n, k, i, j, ndec, ntop
    ex = iand(ishft(bits, -52), 2047_8)
    m = iand(bits, 4503599627370495_8)
    if (ex == 0) then
      e2 = -1074
    else
      m = m + 4503599627370496_8
      e2 = int(ex, 4) - 1075
    end if
    k = trailz(m)
    m = ishft(m, -k)
    e2 = e2 + k
    n = 0
    t = m
    do while (t > 0)
      n = n + 1
      L(n) = mod(t, 1000000000_8)
      t = t / 1000000000_8
    end do
    ndec = 0
    if (e2 > 0) then
      call cpp_a_big_pow2(L, n, e2)
    else if (e2 < 0) then
      ndec = -e2
      call cpp_a_big_pow5(L, n, ndec)
    end if
    t = L(n)
    ntop = 0
    do while (t > 0)
      ntop = ntop + 1
      t = t / 10
    end do
    nd = ntop + 9 * (n - 1)
    t = L(n)
    do i = ntop, 1, -1
      dg(i) = int(mod(t, 10_8), 1)
      t = t / 10
    end do
    j = ntop
    do i = n - 1, 1, -1
      t = L(i)
      do k = 9, 1, -1
        dg(j + k) = int(mod(t, 10_8), 1)
        t = t / 10
      end do
      j = j + 9
    end do
    dp = nd - ndec
    do while (nd > 0)
      if (dg(nd) /= 0) exit
      nd = nd - 1
    end do
  end subroutine cpp_a_exact_digits

  ! keep cut significant digits, rounding half-to-even on the exact value
  recursive subroutine cpp_a_round_digits(dg, nd, dp, cut)
    integer(1), intent(inout) :: dg(:)
    integer(4), intent(inout) :: nd, dp
    integer(4), intent(in) :: cut
    logical :: up
    integer(4) :: nxt, i
    if (nd == 0) return
    if (cut >= nd) return
    if (cut < 0) then
      nd = 0
      return
    end if
    nxt = dg(cut + 1)
    if (nxt > 5) then
      up = .true.
    else if (nxt < 5) then
      up = .false.
    else if (nd > cut + 1) then
      up = .true.
    else if (cut >= 1) then
      up = mod(int(dg(cut)), 2) == 1
    else
      up = .false.
    end if
    nd = cut
    if (up) then
      i = cut
      do while (i >= 1)
        if (dg(i) /= 9) exit
        dg(i) = 0
        i = i - 1
      end do
      if (i >= 1) then
        dg(i) = dg(i) + 1_1
      else
        dg(1) = 1
        nd = 1
        dp = dp + 1
      end if
    end if
    do while (nd > 0)
      if (dg(nd) /= 0) exit
      nd = nd - 1
    end do
  end subroutine cpp_a_round_digits

  ! Str.FromBytes(R.Format("%f", x)): sign, digits, '.', six decimals; inf, nan (with the sign bit's '-')
  recursive function cpp_a_fmt_f6(x) result(zres)
    real(8), intent(in) :: x
    class(cpp_str), pointer :: zres
    integer(1) :: dg(800)
    character(len=340) :: buf
    integer(8) :: bits, ex
    integer(4) :: nd, dp, k, i, j
    bits = transfer(x, 0_8)
    ex = iand(ishft(bits, -52), 2047_8)
    k = 0
    if (bits < 0) then
      k = 1
      buf(1:1) = '-'
    end if
    if (ex == 2047) then
      if (iand(bits, 4503599627370495_8) == 0) then
        buf(k + 1:k + 3) = 'inf'
      else
        buf(k + 1:k + 3) = 'nan'
      end if
      zres => cpp_a_str_of(buf(1:k + 3))
      return
    end if
    if (iand(bits, huge(bits)) == 0) then
      nd = 0
      dp = 1
    else
      call cpp_a_exact_digits(bits, dg, nd, dp)
    end if
    call cpp_a_round_digits(dg, nd, dp, dp + 6)
    if (dp > 0) then
      do i = 1, dp
        k = k + 1
        if (i <= nd) then
          buf(k:k) = achar(48 + dg(i))
        else
          buf(k:k) = '0'
        end if
      end do
    else
      k = k + 1
      buf(k:k) = '0'
    end if
    k = k + 1
    buf(k:k) = '.'
    do j = 1, 6
      i = dp + j
      k = k + 1
      if (i >= 1 .and. i <= nd) then
        buf(k:k) = achar(48 + dg(i))
      else
        buf(k:k) = '0'
      end if
    end do
    zres => cpp_a_str_of(buf(1:k))
  end function cpp_a_fmt_f6
