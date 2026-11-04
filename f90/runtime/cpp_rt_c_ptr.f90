! cpp_rt_c_ptr.f90 - submodule ptr of part C of the Fortran runtime (module cpp_rt_c): the members that need more of
! part A's Ptr than its public procedures give: the remaining length of a Ptr (Bytes.View<T>), its array
! (Mem.Diff), IsNull (time(Ptr<long>)) and the identity of its array (TupN's order of Ptr<double> items).
! It assumes that part A's cpp_ptr_<c> has C#'s Ptr<T> fields: a (class(cpp_arr_<c>), pointer, the array), o
! (integer(8), the offset) and, for the field form Ptr(object, RefAt<T>), at (class(cpp_refat_<c>), pointer).
! Element access goes through part A's cpp_ptr_<c>_item_i (the parent's crt_getb_<c>), so only those three names
! matter here.
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
submodule (cpp_rt_c) ptr
  implicit none

contains

  !> Bytes.View<T>(p): a copy of the bytes of the elements from p to the end of its array (x86's layout; a bool is
  !> one byte), as a char*; one element for a Ptr to a field
  module procedure cpp_bytes_view_ptrt__b
    integer(8) :: n
    n = 1
    if (associated(a1%a)) n = size(a1%a%a, kind=8) - a1%o
    zres = crt_viewbuf(n)
    if (n > 0) call crt_getb_b(a1, n, zres%b%a)
  end procedure cpp_bytes_view_ptrt__b
  module procedure cpp_bytes_view_ptrt__d
    integer(8) :: n
    n = 1
    if (associated(a1%a)) n = size(a1%a%a, kind=8) - a1%o
    zres = crt_viewbuf(8 * n)
    if (n > 0) call crt_getb_d(a1, 8 * n, zres%b%a)
  end procedure cpp_bytes_view_ptrt__d
  module procedure cpp_bytes_view_ptrt__f
    integer(8) :: n
    n = 1
    if (associated(a1%a)) n = size(a1%a%a, kind=8) - a1%o
    zres = crt_viewbuf(4 * n)
    if (n > 0) call crt_getb_f(a1, 4 * n, zres%b%a)
  end procedure cpp_bytes_view_ptrt__f
  module procedure cpp_bytes_view_ptrt__i
    integer(8) :: n
    n = 1
    if (associated(a1%a)) n = size(a1%a%a, kind=8) - a1%o
    zres = crt_viewbuf(4 * n)
    if (n > 0) call crt_getb_i(a1, 4 * n, zres%b%a)
  end procedure cpp_bytes_view_ptrt__i
  module procedure cpp_bytes_view_ptrt__l
    integer(8) :: n
    n = 1
    if (associated(a1%a)) n = size(a1%a%a, kind=8) - a1%o
    zres = crt_viewbuf(8 * n)
    if (n > 0) call crt_getb_l(a1, 8 * n, zres%b%a)
  end procedure cpp_bytes_view_ptrt__l
  module procedure cpp_bytes_view_ptrt__s
    integer(8) :: n
    n = 1
    if (associated(a1%a)) n = size(a1%a%a, kind=8) - a1%o
    zres = crt_viewbuf(2 * n)
    if (n > 0) call crt_getb_s(a1, 2 * n, zres%b%a)
  end procedure cpp_bytes_view_ptrt__s
  module procedure cpp_bytes_view_ptrt__z
    integer(8) :: n
    n = 1
    if (associated(a1%a)) n = size(a1%a%a, kind=8) - a1%o
    zres = crt_viewbuf(n)
    if (n > 0) call crt_getb_z(a1, n, zres%b%a)
  end procedure cpp_bytes_view_ptrt__z

  !> a new buffer of exactly n bytes (C#'s span.ToArray(): no NUL added)
  recursive function crt_viewbuf(n) result(p)
    integer(8), intent(in) :: n
    type(cpp_cptr) :: p
    class(cpp_arr_b), pointer :: b
    allocate(b)
    allocate(b%a(0:max(n, 0_8) - 1))
    if (n > 0) b%a = 0
    p%b => b
    p%o = 0
  end function crt_viewbuf

  !> &obj - p for an array of objects: the index of obj in p's array less p's offset (Array.IndexOf: -1 when absent)
  module procedure cpp_mem_diff_t_ptrt__o
    integer(8) :: i, k
    k = -1
    if (associated(a2%a)) then
      if (allocated(a2%a%a)) then
        do i = lbound(a2%a%a, 1, 8), ubound(a2%a%a, 1, 8)
          if (associated(a2%a%a(i)%p, a1)) then
            k = i - lbound(a2%a%a, 1, 8)
            exit
          end if
        end do
      end if
    end if
    zres = k - a2%o
  end procedure cpp_mem_diff_t_ptrt__o

  !> time(p): the seconds since the epoch (glibc's time), also stored through p unless it is null
  module procedure cpp_r_time_ptrl
    integer(8), pointer :: e
    zres = int(crt_c_time(c_null_ptr), 8)
    if (associated(a1%a) .or. associated(a1%at)) then
      e => cpp_ptr_l_item_i(a1, 0)
      if (associated(e)) e = zres
    end if
  end procedure cpp_r_time_ptrl

  !> TupN.CompareTo: element by element (C#'s Cmp): numbers by value (doubles with <, so NaNs compare equal),
  !> bools false first, a Ptr<double> by its array's identity then its offset, strings by their bytes
  module procedure cpp_tupn_compareto
    integer :: i, na, nb
    na = 0
    nb = 0
    if (allocated(a%v)) na = size(a%v)
    if (allocated(b%v)) nb = size(b%v)
    zres = 0
    do i = 1, min(na, nb)
      zres = crt_item_cmp(a%v(i)%p, b%v(i)%p)
      if (zres /= 0) return
    end do
  end procedure cpp_tupn_compareto

  recursive function crt_item_cmp(x, y) result(c)
    class(*), pointer, intent(in) :: x, y
    integer(4) :: c
    integer(8) :: ix, iy
    c = 0
    if (.not. associated(x)) then
      if (associated(y)) c = -1
      return
    end if
    if (.not. associated(y)) then
      c = 1
      return
    end if
    select type (x)
    type is (real(8))
      select type (y)
      type is (real(8))
        if (x < y) then
          c = -1
        else if (y < x) then
          c = 1
        end if
      end select
    type is (real(4))
      select type (y)
      type is (real(4))
        if (x < y) then
          c = -1
        else if (y < x) then
          c = 1
        end if
      end select
    type is (logical)
      select type (y)
      type is (logical)
        if (.not. x .and. y) then
          c = -1
        else if (x .and. .not. y) then
          c = 1
        end if
      end select
    type is (cpp_ptr_d)
      select type (y)
      type is (cpp_ptr_d)
        ix = 0
        iy = 0
        if (associated(x%a)) ix = loc(x%a)
        if (associated(y%a)) iy = loc(y%a)
        if (ix /= iy) then
          c = merge(-1, 1, ix < iy)
        else if (x%o /= y%o) then
          c = merge(-1, 1, x%o < y%o)
        end if
      end select
    class is (cpp_str)
      select type (y)
      class is (cpp_str)
        c = crt_str_cmp(x, y)
      end select
    class default
      if (crt_int_of(x, ix) .and. crt_int_of(y, iy)) then
        if (ix /= iy) c = merge(-1, 1, ix < iy)
      end if
    end select
  end function crt_item_cmp

  !> an integer item's value (int, long, short, sbyte, the unsigned boxes' bits)
  recursive function crt_int_of(x, v) result(ok)
    class(*), intent(in) :: x
    integer(8), intent(out) :: v
    logical :: ok
    ok = .true.
    v = 0
    select type (x)
    type is (integer(4))
      v = x
    type is (integer(8))
      v = x
    type is (integer(2))
      v = x
    type is (integer(1))
      v = x
    type is (cpp_u8)
      v = iand(int(x%v, 8), 255_8)
    type is (cpp_u16)
      v = iand(int(x%v, 8), 65535_8)
    type is (cpp_u32)
      v = iand(int(x%v, 8), 4294967295_8)
    type is (cpp_u64)
      v = x%v
    class default
      ok = .false.
    end select
  end function crt_int_of

  !> std::string's compare: the bytes as unsigned chars, then the lengths
  recursive function crt_str_cmp(x, y) result(c)
    class(cpp_str), intent(in) :: x, y
    integer(4) :: c
    integer(4) :: i, n, bx, by
    c = 0
    n = min(x%n, y%n)
    do i = 0, n - 1
      bx = iand(int(x%b%a(i), 4), 255)
      by = iand(int(y%b%a(i), 4), 255)
      if (bx /= by) then
        c = merge(-1, 1, bx < by)
        return
      end if
    end do
    if (x%n /= y%n) c = merge(-1, 1, x%n < y%n)
  end function crt_str_cmp

end submodule ptr
