! cpp_rt_a_crt.f90 - the part of cpp_rt_a (part A, core, of the Fortran runtime of the SWMM6 engine port) that needs
! part C: Str.stod (cs/runtime/Str.cs), which is C's strtod (cpp_r_strtod_cptr_cptrr). A submodule may use any part.
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
submodule (cpp_rt_a) cpp_rt_a_crt
  use cpp_rt_c, only: cpp_r_strtod_cptr_cptrr, crt_erange
  implicit none
contains
  ! std::stod (libstdc++'s __stoa over strtod): strtod over c_str(); invalid_argument("stod") when nothing converts,
  ! out_of_range("stod") when strtod sets ERANGE (crt_erange: overflow, or an underflow such as "1e-400" or the
  ! inexact subnormal 2.2250738585072011e-308); the count of bytes used goes to *idx when idx is not null
  module procedure cpp_str_stod
    type(cpp_cptr) :: p, e
    real(8) :: v
    integer(8), pointer :: q
    zres = 0.0_8
    p = cpp_str_c_str(a1)
    e = p
    v = cpp_r_strtod_cptr_cptrr(p, e)
    if (associated(cpp_exc)) return
    if (e%o == p%o) then
      cpp_exc => cpp_a_exc(3, 'stod')
      return
    end if
    if (crt_erange) then
      cpp_exc => cpp_a_exc(2, 'stod')
      return
    end if
    if (associated(a2%a) .or. associated(a2%at)) then
      q => cpp_ptr_l_item_i(a2, 0)
      q = int(e%o - p%o, 8)
    end if
    zres = v
  end procedure cpp_str_stod
end submodule cpp_rt_a_crt
