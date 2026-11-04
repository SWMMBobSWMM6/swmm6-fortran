! cpp_rt_c - STUB of part C of the Fortran runtime (types as the engine sees them, empty bodies), made by
! f90/tools/split_stub.py from the translator's stub. Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
module cpp_rt_c
  use cpp_rt_a
  implicit none
  type, extends(cpp_object) :: cpp_atomic_d
    real(8) :: v = 0.0_8
  end type cpp_atomic_d
  type, extends(cpp_object) :: cpp_atomic_i
    integer(4) :: v = 0
  end type cpp_atomic_i
  type, extends(cpp_object) :: cpp_atomic_l
    integer(8) :: v = 0_8
  end type cpp_atomic_l
  type, extends(cpp_object) :: cpp_atomic_z
    logical :: v = .false.
  end type cpp_atomic_z
  type, extends(cpp_object) :: cpp_box_z
  end type cpp_box_z
  type, extends(cpp_object) :: cpp_cfile
  end type cpp_cfile
  type, extends(cpp_object) :: cpp_condvar
  end type cpp_condvar
  type, extends(cpp_object) :: cpp_defer
  end type cpp_defer
  type :: cpp_duration
    integer(4) :: cpp_tag = 0
  end type cpp_duration
  type, extends(cpp_object) :: cpp_errorcode
  end type cpp_errorcode
  type :: cpp_fromcharsresult
    integer(4) :: ec = 0
    type(cpp_cptr) :: ptr
  end type cpp_fromcharsresult
  type, extends(cpp_object) :: cpp_lock
  end type cpp_lock
  type, extends(cpp_object) :: cpp_mutex
  end type cpp_mutex
  type, extends(cpp_object) :: cpp_onceflag
  end type cpp_onceflag
  type :: cpp_raw
    integer(4) :: cpp_tag = 0
  end type cpp_raw
  type, extends(cpp_object) :: cpp_refd
  end type cpp_refd
  type, extends(cpp_object) :: cpp_reff
  end type cpp_reff
  type, extends(cpp_object) :: cpp_refi
  end type cpp_refi
  type, extends(cpp_object) :: cpp_refl
  end type cpp_refl
  type, extends(cpp_object) :: cpp_scanslot
  end type cpp_scanslot
  type, extends(cpp_object) :: cpp_sysexception
  end type cpp_sysexception
  type, extends(cpp_object) :: cpp_thread
  end type cpp_thread
  type :: cpp_timepoint
    integer(4) :: cpp_tag = 0
  end type cpp_timepoint
  type, extends(cpp_object) :: cpp_tupn
  end type cpp_tupn
  class(cpp_scanslot), pointer :: cpp_r_slot
  class(cpp_cfile), pointer :: cpp_r_stderr_x
  class(cpp_cfile), pointer :: cpp_r_stdout_x
  type(cpp_raw), target :: cpp_raw_v
  real(8), target :: cpp_std_qnan
contains
  recursive function cpp_atomic_d_compare_exchange(self, a1, a2) result(zres)
    class(cpp_atomic_d), intent(inout), target :: self
    real(8), intent(inout) :: a1
    real(8), value :: a2
    logical :: zres
  end function
  recursive function cpp_atomic_d_new_0() result(zres)
    class(cpp_atomic_d), pointer :: zres
  end function
  recursive function cpp_atomic_i_new_t(a1) result(zres)
    integer(4), value :: a1
    class(cpp_atomic_i), pointer :: zres
  end function
  recursive function cpp_atomic_l_fetch_add(self, a1, a2) result(zres)
    class(cpp_atomic_l), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_atomic_l_new_0() result(zres)
    class(cpp_atomic_l), pointer :: zres
  end function
  recursive function cpp_atomic_l_new_t(a1) result(zres)
    integer(8), value :: a1
    class(cpp_atomic_l), pointer :: zres
  end function
  recursive function cpp_atomic_z_new_t(a1) result(zres)
    logical, value :: a1
    class(cpp_atomic_z), pointer :: zres
  end function
  recursive function cpp_box_z_of(a1) result(zres)
    class(cpp_refget_z), pointer, intent(in) :: a1
    class(cpp_box_z), pointer :: zres
  end function
  recursive function cpp_box_z_v(self) result(zres)
    class(cpp_box_z), intent(inout), target :: self
    logical, pointer :: zres
  end function
  recursive function cpp_bytes_view_cptr(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_bytes_view_ptrt__b(a1) result(zres)
    type(cpp_ptr_b), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_bytes_view_ptrt__d(a1) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_bytes_view_ptrt__f(a1) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_bytes_view_ptrt__i(a1) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_bytes_view_ptrt__l(a1) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_bytes_view_ptrt__s(a1) result(zres)
    type(cpp_ptr_s), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_bytes_view_ptrt__z(a1) result(zres)
    type(cpp_ptr_z), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_condvar_new() result(zres)
    class(cpp_condvar), pointer :: zres
  end function
  recursive function cpp_conv_d2i(a1) result(zres)
    real(8), value :: a1
    integer(4) :: zres
  end function
  recursive function cpp_conv_d2l(a1) result(zres)
    real(8), value :: a1
    integer(8) :: zres
  end function
  recursive function cpp_conv_d2sb(a1) result(zres)
    real(8), value :: a1
    integer(1) :: zres
  end function
  recursive function cpp_conv_d2ul(a1) result(zres)
    real(8), value :: a1
    integer(8) :: zres
  end function
  recursive subroutine cpp_dbg_caught(a1)
    class(cpp_object), pointer, intent(in) :: a1
  end subroutine
  recursive subroutine cpp_defer_cancel(self)
    class(cpp_defer), intent(inout), target :: self
  end subroutine
  recursive function cpp_defer_new(a1) result(zres)
    class(cpp_action), pointer, intent(in) :: a1
    class(cpp_defer), pointer :: zres
  end function
  recursive subroutine cpp_dtor_run(a1)
    class(*), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_duration_clone(self) result(zres)
    type(cpp_duration), intent(in) :: self
    type(cpp_duration) :: zres
  end function
  recursive function cpp_duration_count(self) result(zres)
    type(cpp_duration), intent(in) :: self
    real(8) :: zres
  end function
  recursive function cpp_errorcode_bool(self) result(zres)
    class(cpp_errorcode), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_errorcode_new() result(zres)
    class(cpp_errorcode), pointer :: zres
  end function
  recursive function cpp_libm_expm1(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_libm_fmod(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_libm_hypot(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_libm_log1p(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_libm_nextafter(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_libm_remainder(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_libm_round(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_lock_new() result(zres)
    class(cpp_lock), pointer :: zres
  end function
  recursive function cpp_math_acos_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_asin_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_atan2_dd(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_math_atan_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_cbrt_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_ceiling_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_copysign_dd(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_math_cos_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_cosh_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_exp_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_floor_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_log10_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_log2_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_log_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_pow_dd(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_math_sin_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_sinh_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_tan_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_tanh_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_math_truncate_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_mem_calloc__d(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_mem_diff_t_ptrt__o(a1, a2, mk3, cm4) result(zres)
    class(*), pointer, intent(in) :: a1
    type(cpp_ptr_o), intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    integer(8) :: zres
  end function
  recursive function cpp_mem_fread_cptr_ul_ul_cfile(a1, a2, a3, a4) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
  end function
  recursive function cpp_mem_fread_ptrt_ul_ul_cfile__f(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
  end function
  recursive function cpp_mem_fread_ptrt_ul_ul_cfile__i(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
  end function
  recursive subroutine cpp_mem_free(a1)
    class(*), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_mem_fwrite_cptr_ul_ul_cfile(a1, a2, a3, a4) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
  end function
  recursive function cpp_mem_fwrite_ptrt_ul_ul_cfile__f(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
  end function
  recursive function cpp_mem_fwrite_ptrt_ul_ul_cfile__i(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__b(a1, a2, a3) result(zres)
    type(cpp_ptr_b), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_b) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__d(a1, a2, a3) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__f(a1, a2, a3) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_f) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__i(a1, a2, a3) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_i) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__l(a1, a2, a3) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_l) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__s(a1, a2, a3) result(zres)
    type(cpp_ptr_s), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_s) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_ptru_ul__ib(a1, a2, a3) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    type(cpp_ptr_b), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_i) :: zres
  end function
  recursive function cpp_mem_memcpy_ptrt_ptru_ul__ld(a1, a2, a3) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    type(cpp_ptr_d), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_l) :: zres
  end function
  recursive function cpp_mutex_new() result(zres)
    class(cpp_mutex), pointer :: zres
  end function
  recursive subroutine cpp_mv_delete(a1)
    class(*), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_mv_poststep_ptrtr_i__d(a1, a2) result(zres)
    type(cpp_ptr_d), intent(inout) :: a1
    integer(4), value :: a2
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_onceflag_new() result(zres)
    class(cpp_onceflag), pointer :: zres
  end function
  recursive function cpp_r_atof(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    real(8) :: zres
  end function
  recursive function cpp_r_atoi(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_atol(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8) :: zres
  end function
  recursive function cpp_r_back_i_t1r__b(a1, a2) result(zres)
    integer(4), value :: a1
    integer(1), intent(inout) :: a2
    integer(4) :: zres
  end function
  recursive function cpp_r_back_i_t1r_t2r__lb(a1, a2, a3) result(zres)
    integer(4), value :: a1
    integer(8), intent(inout) :: a2
    integer(1), intent(inout) :: a3
    integer(4) :: zres
  end function
  recursive function cpp_r_buf_i(a1) result(zres)
    integer(4), value :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_bufof(a1, a2) result(zres)
    integer(4), value :: a1
    class(cpp_arr_i), pointer, intent(in) :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_bufs(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_r_copybuf(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_ctime_ptrl(a1) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_difftime(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_r_fclose(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_feof(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_ferror(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_fflush(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_fgetc(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_fgets(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    class(cpp_cfile), pointer, intent(in) :: a3
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_fileno(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_fopen(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    class(cpp_cfile), pointer :: zres
  end function
  recursive function cpp_r_fprintf(a1, a2, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    class(*), intent(in), optional :: v1
    class(*), intent(in), optional :: v2
    class(*), intent(in), optional :: v3
    class(*), intent(in), optional :: v4
    class(*), intent(in), optional :: v5
    class(*), intent(in), optional :: v6
    class(*), intent(in), optional :: v7
    class(*), intent(in), optional :: v8
    class(*), intent(in), optional :: v9
    class(*), intent(in), optional :: v10
    class(*), intent(in), optional :: v11
    class(*), intent(in), optional :: v12
    class(*), intent(in), optional :: v13
    class(*), intent(in), optional :: v14
    class(*), intent(in), optional :: v15
    class(*), intent(in), optional :: v16
    class(*), intent(in), optional :: v17
    class(*), intent(in), optional :: v18
    class(*), intent(in), optional :: v19
    class(*), intent(in), optional :: v20
    class(*), intent(in), optional :: v21
    class(*), intent(in), optional :: v22
    class(*), intent(in), optional :: v23
    class(*), intent(in), optional :: v24
    class(*), intent(in), optional :: v25
    class(*), intent(in), optional :: v26
    class(*), intent(in), optional :: v27
    class(*), intent(in), optional :: v28
    class(*), intent(in), optional :: v29
    class(*), intent(in), optional :: v30
    class(*), intent(in), optional :: v31
    class(*), intent(in), optional :: v32
    class(*), intent(in), optional :: v33
    class(*), intent(in), optional :: v34
    class(*), intent(in), optional :: v35
    class(*), intent(in), optional :: v36
    class(*), intent(in), optional :: v37
    class(*), intent(in), optional :: v38
    class(*), intent(in), optional :: v39
    class(*), intent(in), optional :: v40
    integer(4) :: zres
  end function
  recursive function cpp_r_freadd1(a1, a2) result(zres)
    real(8), intent(inout) :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_r_freadf1(a1, a2) result(zres)
    real(4), intent(inout) :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_r_freadi1(a1, a2) result(zres)
    integer(4), intent(inout) :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_r_fseek_cfile_l_i(a1, a2, a3) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(4), value :: a3
    integer(4) :: zres
  end function
  recursive function cpp_r_ftell(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(8) :: zres
  end function
  recursive function cpp_r_fwrited1(a1, a2) result(zres)
    real(8), value :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_r_fwritef1(a1, a2) result(zres)
    real(4), value :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_r_fwritei1(a1, a2) result(zres)
    integer(4), value :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_r_getenv(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_isalnum(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_isalpha(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_isdigit(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_isspace(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_lit(a1) result(zres)
    character(len=*), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_litn(a1, a2) result(zres)
    character(len=*), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_memcmp(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    integer(4) :: zres
  end function
  recursive subroutine cpp_r_memcpybuf(a1, a2)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
  end subroutine
  recursive function cpp_r_refd(a1) result(zres)
    class(cpp_action_d), pointer, intent(in) :: a1
    class(cpp_refd), pointer :: zres
  end function
  recursive function cpp_r_reff(a1) result(zres)
    class(cpp_action_f), pointer, intent(in) :: a1
    class(cpp_reff), pointer :: zres
  end function
  recursive function cpp_r_refi(a1) result(zres)
    class(cpp_action_i), pointer, intent(in) :: a1
    class(cpp_refi), pointer :: zres
  end function
  recursive function cpp_r_refl(a1) result(zres)
    class(cpp_action_l), pointer, intent(in) :: a1
    class(cpp_refl), pointer :: zres
  end function
  recursive subroutine cpp_r_rewind(a1)
    class(cpp_cfile), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_r_setvbuf(a1, a2, a3, a4) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4), value :: a3
    integer(8), value :: a4
    integer(4) :: zres
  end function
  recursive function cpp_r_snprintf_cptr_ul_cptr_oa(a1, a2, a3, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_cptr), intent(in) :: a3
    class(*), intent(in), optional :: v1
    class(*), intent(in), optional :: v2
    class(*), intent(in), optional :: v3
    class(*), intent(in), optional :: v4
    class(*), intent(in), optional :: v5
    class(*), intent(in), optional :: v6
    class(*), intent(in), optional :: v7
    class(*), intent(in), optional :: v8
    class(*), intent(in), optional :: v9
    class(*), intent(in), optional :: v10
    class(*), intent(in), optional :: v11
    class(*), intent(in), optional :: v12
    class(*), intent(in), optional :: v13
    class(*), intent(in), optional :: v14
    class(*), intent(in), optional :: v15
    class(*), intent(in), optional :: v16
    class(*), intent(in), optional :: v17
    class(*), intent(in), optional :: v18
    class(*), intent(in), optional :: v19
    class(*), intent(in), optional :: v20
    class(*), intent(in), optional :: v21
    class(*), intent(in), optional :: v22
    class(*), intent(in), optional :: v23
    class(*), intent(in), optional :: v24
    class(*), intent(in), optional :: v25
    class(*), intent(in), optional :: v26
    class(*), intent(in), optional :: v27
    class(*), intent(in), optional :: v28
    class(*), intent(in), optional :: v29
    class(*), intent(in), optional :: v30
    class(*), intent(in), optional :: v31
    class(*), intent(in), optional :: v32
    class(*), intent(in), optional :: v33
    class(*), intent(in), optional :: v34
    class(*), intent(in), optional :: v35
    class(*), intent(in), optional :: v36
    class(*), intent(in), optional :: v37
    class(*), intent(in), optional :: v38
    class(*), intent(in), optional :: v39
    class(*), intent(in), optional :: v40
    integer(4) :: zres
  end function
  recursive function cpp_r_sscanf(a1, a2, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    class(*), intent(in), optional :: v1
    class(*), intent(in), optional :: v2
    class(*), intent(in), optional :: v3
    class(*), intent(in), optional :: v4
    class(*), intent(in), optional :: v5
    class(*), intent(in), optional :: v6
    class(*), intent(in), optional :: v7
    class(*), intent(in), optional :: v8
    class(*), intent(in), optional :: v9
    class(*), intent(in), optional :: v10
    class(*), intent(in), optional :: v11
    class(*), intent(in), optional :: v12
    class(*), intent(in), optional :: v13
    class(*), intent(in), optional :: v14
    class(*), intent(in), optional :: v15
    class(*), intent(in), optional :: v16
    class(*), intent(in), optional :: v17
    class(*), intent(in), optional :: v18
    class(*), intent(in), optional :: v19
    class(*), intent(in), optional :: v20
    class(*), intent(in), optional :: v21
    class(*), intent(in), optional :: v22
    class(*), intent(in), optional :: v23
    class(*), intent(in), optional :: v24
    class(*), intent(in), optional :: v25
    class(*), intent(in), optional :: v26
    class(*), intent(in), optional :: v27
    class(*), intent(in), optional :: v28
    class(*), intent(in), optional :: v29
    class(*), intent(in), optional :: v30
    class(*), intent(in), optional :: v31
    class(*), intent(in), optional :: v32
    class(*), intent(in), optional :: v33
    class(*), intent(in), optional :: v34
    class(*), intent(in), optional :: v35
    class(*), intent(in), optional :: v36
    class(*), intent(in), optional :: v37
    class(*), intent(in), optional :: v38
    class(*), intent(in), optional :: v39
    class(*), intent(in), optional :: v40
    integer(4) :: zres
  end function
  recursive function cpp_r_strchr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_strcmp(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4) :: zres
  end function
  recursive function cpp_r_strlen(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8) :: zres
  end function
  recursive function cpp_r_strncmp(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    integer(4) :: zres
  end function
  recursive function cpp_r_strncpy(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_strrchr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_strstr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_strtod_cptr(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    real(8) :: zres
  end function
  recursive function cpp_r_strtod_cptr_cptrr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(inout) :: a2
    real(8) :: zres
  end function
  recursive function cpp_r_strtok(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_r_strtol0(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_r_time_ptrl(a1) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    integer(8) :: zres
  end function
  recursive function cpp_r_tolower(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
  end function
  recursive function cpp_r_toupper(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
  end function
  recursive subroutine cpp_std_call_once(a1, a2)
    class(cpp_onceflag), pointer, intent(in) :: a1
    class(cpp_action), pointer, intent(in) :: a2
  end subroutine
  recursive function cpp_std_from_chars_cptr_cptr_dr(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    real(8), intent(inout) :: a3
    type(cpp_fromcharsresult) :: zres
  end function
  recursive function cpp_std_from_chars_cptr_cptr_ir(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4), intent(inout) :: a3
    type(cpp_fromcharsresult) :: zres
  end function
  recursive function cpp_std_from_chars_cptr_cptr_ur(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4), intent(inout) :: a3
    type(cpp_fromcharsresult) :: zres
  end function
  recursive function cpp_std_get0_pairab__id(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    integer(4), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__ii(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    integer(4), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__io(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(4), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__lo(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(8), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__od(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__ol(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__oo(a1, mk2, cm3, mk4, cm5) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__os(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get0_pairab__oz(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__id(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    real(8), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__ii(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    integer(4), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__io(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__lo(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__od(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    real(8), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__ol(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(8), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__oo(a1, mk2, cm3, mk4, cm5) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__os(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(2), pointer :: zres
  end function
  recursive function cpp_std_get1_pairab__oz(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    logical, pointer :: zres
  end function
  recursive function cpp_std_nop(a1) result(zres)
    class(*), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive subroutine cpp_std_rethrow(a1)
    class(cpp_object), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_sys_hardware_concurrency() result(zres)
    integer(4) :: zres
  end function
  recursive function cpp_sysexception_new(a1, a2) result(zres)
    character(len=*), intent(in) :: a1
    character(len=*), intent(in) :: a2
    class(cpp_sysexception), pointer :: zres
  end function
  recursive function cpp_thread_new() result(zres)
    class(cpp_thread), pointer :: zres
  end function
  recursive function cpp_timepoint_clone(self) result(zres)
    type(cpp_timepoint), intent(in) :: self
    type(cpp_timepoint) :: zres
  end function
  recursive function cpp_timepoint_now() result(zres)
    type(cpp_timepoint) :: zres
  end function
  recursive function cpp_timepoint_op_sub(a1, a2) result(zres)
    type(cpp_timepoint), intent(in) :: a1
    type(cpp_timepoint), intent(in) :: a2
    type(cpp_duration) :: zres
  end function
  recursive function cpp_tupn_new_0() result(zres)
    class(cpp_tupn), pointer :: zres
  end function
  recursive function cpp_tupn_new_oa(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40) result(zres)
    class(*), intent(in), optional :: v1
    class(*), intent(in), optional :: v2
    class(*), intent(in), optional :: v3
    class(*), intent(in), optional :: v4
    class(*), intent(in), optional :: v5
    class(*), intent(in), optional :: v6
    class(*), intent(in), optional :: v7
    class(*), intent(in), optional :: v8
    class(*), intent(in), optional :: v9
    class(*), intent(in), optional :: v10
    class(*), intent(in), optional :: v11
    class(*), intent(in), optional :: v12
    class(*), intent(in), optional :: v13
    class(*), intent(in), optional :: v14
    class(*), intent(in), optional :: v15
    class(*), intent(in), optional :: v16
    class(*), intent(in), optional :: v17
    class(*), intent(in), optional :: v18
    class(*), intent(in), optional :: v19
    class(*), intent(in), optional :: v20
    class(*), intent(in), optional :: v21
    class(*), intent(in), optional :: v22
    class(*), intent(in), optional :: v23
    class(*), intent(in), optional :: v24
    class(*), intent(in), optional :: v25
    class(*), intent(in), optional :: v26
    class(*), intent(in), optional :: v27
    class(*), intent(in), optional :: v28
    class(*), intent(in), optional :: v29
    class(*), intent(in), optional :: v30
    class(*), intent(in), optional :: v31
    class(*), intent(in), optional :: v32
    class(*), intent(in), optional :: v33
    class(*), intent(in), optional :: v34
    class(*), intent(in), optional :: v35
    class(*), intent(in), optional :: v36
    class(*), intent(in), optional :: v37
    class(*), intent(in), optional :: v38
    class(*), intent(in), optional :: v39
    class(*), intent(in), optional :: v40
    class(cpp_tupn), pointer :: zres
  end function
end module cpp_rt_c
