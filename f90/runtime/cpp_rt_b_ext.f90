! cpp_rt_b_ext.f90 - the submodule of part B (cpp_rt_b) of the Fortran runtime of the SWMM6 engine port: the members
! that need what the stubs of parts A and C do not show - the components of cpp_iter_b, cpp_iter_f, cpp_iter_z
! (a, the array object, and i, the index, as cpp_iter_d has them) and of cpp_ptr_d (a and o, as Cpp.Ptr<double>'s
! array form has them), and part C's TupN.CompareTo (cpp_tupn_compareto(a, b), an integer(4) < 0, 0 or > 0).
! The module compiles against the stubs; this file needs the real parts A and C. Port of the C# Algo class
! (cs/runtime/Misc.cs) and of TupN's order (Less<TupN>.Fn, EqualityComparer<TupN>.Default) for Map / Set keys.
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
submodule (cpp_rt_b) cpp_rt_b_ext
  implicit none
contains

  ! TupN.CompareTo: element by element, as std::tuple's operator< does (part C's)
  module procedure cpp_b_tupn_cmp
    zres = cpp_tupn_compareto(a, b)
  end procedure cpp_b_tupn_cmp

  module procedure cpp_algo_any_of__b
    integer(8) :: i
    zres = .true.
    do i = a1%i, a2%i - 1_8
      if (a3%invoke(a1%a%a(i))) return
      if (associated(cpp_exc)) return
    end do
    zres = .false.
  end procedure cpp_algo_any_of__b

  module procedure cpp_algo_any_of__z
    integer(8) :: i
    zres = .true.
    do i = a1%i, a2%i - 1_8
      if (a3%invoke(a1%a%a(i))) return
      if (associated(cpp_exc)) return
    end do
    zres = .false.
  end procedure cpp_algo_any_of__z

  module procedure cpp_algo_begin_ta__z
    zres = cpp_iter_z()
    zres%a => a1
    zres%i = 0_8
  end procedure cpp_algo_begin_ta__z

  module procedure cpp_algo_end_ta__z
    zres = cpp_iter_z()
    zres%a => a1
    zres%i = size(a1%a, kind=8)
  end procedure cpp_algo_end_ta__z

  ! copy_n(b, n, o) = copy(b, b + n, o) over the arrays of two pointers; returns o + n
  module procedure cpp_algo_copy_n_ptrt_ul_ptrt__d
    integer(8) :: i
    do i = 0_8, a2 - 1_8
      a3%a%a(a3%o + i) = a1%a%a(a1%o + i)
    end do
    zres = cpp_ptr_d_op_add_ptrt_l(a3, a2)
  end procedure cpp_algo_copy_n_ptrt_ul_ptrt__d

  module procedure cpp_algo_count__b
    integer(8) :: i
    zres = 0_8
    do i = a1%i, a2%i - 1_8
      if (a1%a%a(i) == a3) zres = zres + 1_8
    end do
  end procedure cpp_algo_count__b

  module procedure cpp_algo_fill_itert_itert_t__b
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      a1%a%a(i) = a3
    end do
  end procedure cpp_algo_fill_itert_itert_t__b

  module procedure cpp_algo_fill_itert_itert_t__f
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      a1%a%a(i) = a3
    end do
  end procedure cpp_algo_fill_itert_itert_t__f

  module procedure cpp_algo_fill_itert_itert_t__z
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      a1%a%a(i) = a3
    end do
  end procedure cpp_algo_fill_itert_itert_t__z

  module procedure cpp_algo_fill_n_ptrt_ul_t__d
    integer(8) :: i
    do i = 0_8, a2 - 1_8
      a1%a%a(a1%o + i) = a3
    end do
    zres = cpp_ptr_d_op_add_ptrt_l(a1, a2)
  end procedure cpp_algo_fill_n_ptrt_ul_t__d

  module procedure cpp_algo_fill_ptrt_ptrt_t__d
    integer(8) :: i
    do i = a1%o, a2%o - 1_8
      a1%a%a(i) = a3
    end do
  end procedure cpp_algo_fill_ptrt_ptrt_t__d

  module procedure cpp_algo_find__b
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      if (a1%a%a(i) == a3) then
        zres = cpp_iter_b_op_add(a1, i - a1%i)
        return
      end if
    end do
    zres = a2
  end procedure cpp_algo_find__b

  module procedure cpp_algo_replace__b
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      if (a1%a%a(i) == a3) a1%a%a(i) = a4
    end do
  end procedure cpp_algo_replace__b

  ! transform<byte, byte>: o[k] = f(b[k]); returns o + (e - b)
  module procedure cpp_algo_transform_itert_itert_iteru_functu__bb
    integer(8) :: i
    integer(1) :: r
    do i = a1%i, a2%i - 1_8
      r = a4%invoke(a1%a%a(i))
      if (associated(cpp_exc)) return
      a3%a%a(a3%i + (i - a1%i)) = r
    end do
    zres = cpp_iter_b_op_add(a3, a2%i - a1%i)
  end procedure cpp_algo_transform_itert_itert_iteru_functu__bb

  ! transform over a string's bytes with a Func<byte, sbyte> (::toupper and lambdas around it): each result stored
  ! as a char
  module procedure cpp_algo_transform_iteruc_iteruc_iteruc_funcucc
    integer(8) :: i
    integer(1) :: r
    do i = a1%i, a2%i - 1_8
      r = a4%invoke(a1%a%a(i))
      if (associated(cpp_exc)) return
      a3%a%a(a3%i + (i - a1%i)) = r
    end do
    zres = cpp_iter_b_op_add(a3, a2%i - a1%i)
  end procedure cpp_algo_transform_iteruc_iteruc_iteruc_funcucc

end submodule cpp_rt_b_ext
