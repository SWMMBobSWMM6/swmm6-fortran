! cpp_rt_c.f90 - part C of the Fortran runtime of the SWMM6 engine (module cpp_rt_c): the C library layer of
! cs/runtime/CRuntime.cs and Stash.cs (C# class Cpp.R but CPtr, which is part A's), the C library functions of
! cs/runtime/Fs.cs that runtime_parts.txt gives this part (getenv, ctype, atol, strtol0, strncpy, strncmp,
! memcmp, ferror, fileno, setvbuf, fgetc, stderr_, BufOf, memcpyBuf), the rest of cs/runtime/Misc.cs but Algo
! (Mv, Conv, LibM, Std, Mem, Bytes, Box, Defer, Dtor, Atomic, TupN, TimePoint / Duration, Mutex / CondVar / Thread
! / Lock / OnceFlag as one-thread no-ops, ErrorCode, FromCharsResult, Raw, Sys, Dbg), C#'s System.Math as the
! engine calls it (cpp_math_*) and the System exception object (cpp_sysexception).
!
! Files: this module; submodule fmt (cpp_rt_c_fmt.f90: the printf / sscanf / strtod engines); submodule ptr
! (cpp_rt_c_ptr.f90: the few members that need part A's Ptr layout, see below).
!
! Sources. The C# runtime is the specification. The printf, sscanf and strtod engines, x86's float-to-integer
! conversions and the string functions are the SWMM5 Fortran port's (/home/claude/swmm5-ports/f90/runtime/
! crt_base.f90, crt_format.f90, crt_io.f90, 480/480 against EPA), adapted to this runtime's types. The choices
! where the C# departs from glibc follow the other ports of this runtime (py/cpp/crt.py, crtmath.py, crtmisc.py,
! ts/src/cpp/CRuntime.ts, Misc.ts, java/src/cpp/R.java, go/cpp), which do what glibc does (the C# engine is
! gated byte-identical to the C++ one, so glibc is the reference there):
!  - printf takes an integer argument at the size its length modifier says (%d of a long prints its low 32 bits,
!    %u of an int its 32 bits unsigned), %a rounds as glibc does, %#g keeps glibc's quirk, %s of a null pointer is
!    "(null)" or nothing (precision 0..5), %p / %n / unknown conversions are glibc's (the C# throws);
!  - sscanf is glibc's vfscanf: %n, %[ scan sets, %i / %x / %o, assignment suppression, the EOF rule (EOF when an
!    input failure comes before any assignment), %u of a negative or huge number, %f into a float rounded once
!    (strtof; the C# rounds to double, then to float), glibc's float scanner (how far "1e+x" reads);
!  - strtod reads hexadecimal floats exactly and NaN payloads; "nan" is +NaN (0x7FF8...) and "-nan" -NaN (the C#
!    gives .NET's NaN, which is negative, and its negation);
!  - std::from_chars is libstdc++'s: no hexadecimal prefix, out-of-range values are result_out_of_range with the
!    value unchanged (the C# reads them through strtod);
!  - fflush(NULL) flushes every stream (the C# does nothing).
! Other deliberate differences: files are glibc's stdio (fopen / fread / fwrite / fseek / ftell / fgets / fgetc /
! feof / fclose through bind(C), so positioning, buffering and the end-of-file flag are C's own; the C# emulates
! them with .NET streams), except that a stream opened for reading that cannot be read (a directory) is refused, as
! .NET's FileStream refuses it and the other ports do; stdout_ / stderr_ write with write(2) at once, unbuffered, as
! .NET's console streams do (and part D's cout / cerr);
! ctime is glibc's ctime_r (the C# formats DateTimeOffset the same way); the string functions stop at the end of
! the array where the C# would throw IndexOutOfRangeException; R.Back converts a stashed value to the target's
! width without .NET's overflow check (Convert.ChangeType would throw).
! System.Math: .NET computes Floor, Ceiling, Truncate and CopySign itself (exact operations: here libm's floor /
! ceil / trunc, the same results as .NET's roundsd, and CopySign on the bits) and calls glibc's libm for the
! transcendental functions, as this module does (bind(C)), so every cpp_math_* and cpp_libm_* result is glibc's.
!
! Part A's Ptr layout: the members that need more than part A's public Ptr procedures (the remaining length of a
! Ptr for Bytes.View, the array of Mem.Diff, IsNull of time's Ptr<long>, the array identity TupN compares) are in
! submodule ptr, which assumes components a (class(cpp_arr_<c>), pointer), o (integer(8)) and, for the field form,
! at (class(cpp_refat_<c>), pointer), as C#'s Ptr<T> has them. Everything else here uses part A's procedures
! (cpp_ptr_<c>_item_i, cpp_ptr_<c>_new_ta_l, cpp_ptr_d_op_add_ptrt_l, cpp_cppexception_what) and the manifest's
! components of CPtr (b, o), Str (b, n), the arrays (a) and Pair (first, second).
! For the other parts this module also exports cpp_r_format (printf's bytes, for Str.to_string and the streams),
! cpp_r_strtol (C's strtol with the end, for stoi / stol and the streams' >> long), cpp_tupn_compareto (the order of
! TupN keys, for Map / Set), cpp_rt_c_write_fd (unbuffered bytes to a descriptor) and cpp_r_flushall (what exit()
! does to streams); the components ErrorCode%v (errno), SysException%name / %message, TupN%v (the items) and
! CFile%fp (the FILE*) are public.
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
module cpp_rt_c
  use, intrinsic :: iso_c_binding, only: c_ptr, c_null_ptr, c_int, c_long, c_size_t, c_double, c_char, &
       c_null_char, c_loc, c_associated, c_f_pointer, c_intptr_t
  use cpp_rt_a
  implicit none
  private :: c_ptr, c_null_ptr, c_int, c_long, c_size_t, c_double, c_char, c_null_char, c_loc, c_associated, &
       c_f_pointer, c_intptr_t

  ! ---------------------------------------------------------------------------------------------- types
  type, extends(cpp_object) :: cpp_atomic_d
    real(8) :: v = 0.0_8
  contains
    procedure :: clone => crt_atomic_d_clone
    procedure :: assign => crt_atomic_d_assign
  end type cpp_atomic_d
  type, extends(cpp_object) :: cpp_atomic_i
    integer(4) :: v = 0
  contains
    procedure :: clone => crt_atomic_i_clone
    procedure :: assign => crt_atomic_i_assign
  end type cpp_atomic_i
  type, extends(cpp_object) :: cpp_atomic_l
    integer(8) :: v = 0_8
  contains
    procedure :: clone => crt_atomic_l_clone
    procedure :: assign => crt_atomic_l_assign
  end type cpp_atomic_l
  type, extends(cpp_object) :: cpp_atomic_z
    logical :: v = .false.
  contains
    procedure :: clone => crt_atomic_z_clone
    procedure :: assign => crt_atomic_z_assign
  end type cpp_atomic_z
  !> Cpp.Box<bool>: a bool& member, the place it refers to (a lambda giving a pointer to it, or an array cell)
  type, extends(cpp_object) :: cpp_box_z
    class(cpp_refget_z), pointer :: g => null()
    class(cpp_arr_z), pointer :: a => null()
    integer(8) :: o = 0_8
  end type cpp_box_z
  !> C's FILE*: a glibc stdio stream (fp) of a file fopen opened; stdout_ and stderr_ are the objects
  !> crt_out_obj / crt_err_obj, written with write(2)
  type, extends(cpp_object) :: cpp_cfile
    type(c_ptr) :: fp = c_null_ptr
  end type cpp_cfile
  type, extends(cpp_object) :: cpp_condvar
  end type cpp_condvar
  !> a destructor deferred to the end of a block (a using declaration): runs a on dispose unless cancelled
  type, extends(cpp_object) :: cpp_defer
    class(cpp_action), pointer :: a => null()
  contains
    procedure :: dispose => crt_defer_dispose
  end type cpp_defer
  !> std::chrono duration in nanoseconds; count() is seconds
  type :: cpp_duration
    integer(4) :: cpp_tag = 0
    integer(8) :: ns = 0_8
  end type cpp_duration
  !> std::error_code: v, the errno value
  type, extends(cpp_object) :: cpp_errorcode
    integer(4) :: v = 0
  end type cpp_errorcode
  type :: cpp_fromcharsresult
    integer(4) :: ec = 0
    type(cpp_cptr) :: ptr
  end type cpp_fromcharsresult
  type, extends(cpp_object) :: cpp_lock
  end type cpp_lock
  type, extends(cpp_object) :: cpp_mutex
  end type cpp_mutex
  !> std::once_flag: whether call_once has run its function
  type, extends(cpp_object) :: cpp_onceflag
    logical :: done = .false.
  end type cpp_onceflag
  type :: cpp_raw
    integer(4) :: cpp_tag = 0
  end type cpp_raw
  !> sscanf targets that are lvalues: the setter that stores the value scanned
  type, extends(cpp_object) :: cpp_refd
    class(cpp_action_d), pointer :: set => null()
  end type cpp_refd
  type, extends(cpp_object) :: cpp_reff
    class(cpp_action_f), pointer :: set => null()
  end type cpp_reff
  type, extends(cpp_object) :: cpp_refi
    class(cpp_action_i), pointer :: set => null()
  end type cpp_refi
  type, extends(cpp_object) :: cpp_refl
    class(cpp_action_l), pointer :: set => null()
  end type cpp_refl
  !> the sscanf target that is a C pointer parameter: the value is stashed, R.Back copies it
  type, extends(cpp_object) :: cpp_scanslot
  end type cpp_scanslot
  !> a .NET exception the engine throws itself (System.<name>, with its message)
  type, extends(cpp_object) :: cpp_sysexception
    character(len=:), allocatable :: name
    character(len=:), allocatable :: message
  end type cpp_sysexception
  !> std::thread: never started (the engine's one worker thread runs synchronously, Hand_IOThread.cs)
  type, extends(cpp_object) :: cpp_thread
  end type cpp_thread
  !> std::chrono time point: nanoseconds of the monotonic clock
  type :: cpp_timepoint
    integer(4) :: cpp_tag = 0
    integer(8) :: ns = 0_8
  end type cpp_timepoint
  !> std::tuple of more than three elements: the items (boxes the engine made), compared element by element
  type, extends(cpp_object) :: cpp_tupn
    type(cpp_slot), allocatable :: v(:)
  contains
    procedure :: clone => crt_tupn_clone
    procedure :: assign => crt_tupn_assign
  end type cpp_tupn

  ! a printf argument, classified: k 0 none, 1 an integer (iv its C# value), 2 an unsigned integer (iv its bits),
  ! 3 a floating value (rv), 4 a string (the bytes sb(so:), up to a NUL, the array's end, or sn bytes when sn >= 0),
  ! 5 a null pointer. No default initialization (40 of them per call): crt_cls sets every field.
  type :: crt_arg
    integer :: k
    integer(8) :: iv
    real(8) :: rv
    integer(1), pointer :: sb(:)
    integer(8) :: so
    integer(8) :: sn
  end type crt_arg
  ! a character argument's bytes (the n-th argument's in crt_cpool(n)); printf calls no other code, so one pool does
  type :: crt_bytes
    integer(1), allocatable :: b(:)
  end type crt_bytes
  ! a sscanf target, classified: k 0 none, 1 RefI, 2 RefL, 3 RefD, 4 RefF, 5 a char buffer (CPtr), 6 R.Slot.
  ! No default initialization: crt_tcls sets k, and the field k says is set.
  type :: crt_tgt
    integer :: k
    class(cpp_action_i), pointer :: ai
    class(cpp_action_l), pointer :: al
    class(cpp_action_d), pointer :: ad
    class(cpp_action_f), pointer :: af
    type(cpp_cptr) :: cp
  end type crt_tgt
  type, bind(C) :: crt_timespec
    integer(c_long) :: s, ns
  end type crt_timespec

  ! ---------------------------------------------------------------------------------------------- variables
  type(cpp_scanslot), target, save :: crt_slot_obj
  type(cpp_cfile), target, save :: crt_out_obj, crt_err_obj
  class(cpp_scanslot), pointer :: cpp_r_slot => crt_slot_obj
  class(cpp_cfile), pointer :: cpp_r_stderr_x => crt_err_obj
  class(cpp_cfile), pointer :: cpp_r_stdout_x => crt_out_obj
  type(cpp_raw), target :: cpp_raw_v
  real(8), target :: cpp_std_qnan = transfer(9221120237041090560_8, 1.0_8)     ! 0x7FF8000000000000

  ! the sscanf stash (R.Slot targets, in order): kind 1 int, 2 long, 3 sbyte, 4 double, 5 float
  integer, parameter :: crt_nst = 64
  integer, save :: crt_stn = 0
  integer, save :: crt_stk(crt_nst) = 0
  integer(8), save :: crt_sti(crt_nst) = 0_8
  real(8), save :: crt_std(crt_nst) = 0.0_8
  type(crt_bytes), target, save :: crt_cpool(40)
  ! printf's output buffer (reused; printf calls no other code)
  integer(1), allocatable, save :: crt_out(:)
  ! strtok's position
  type(cpp_cptr), save :: crt_toknext
  ! whether the last crt_strtod would have set errno to ERANGE in glibc: an overflow to +-inf, a nonzero number that
  ! became zero, or a double that is tiny (below DBL_MIN after rounding to 53 bits, the x86 rule) and inexact;
  ! libstdc++'s std::stod throws out_of_range on it (C# Cpp.R.ERange)
  logical, save :: crt_erange = .false.
  ! Dbg.Caught: 0 not looked up, 1 off, 2 on
  integer, save :: crt_trace = 0

  ! (crt_stash and crt_getb_<c> stay public: submodules fmt and ptr call them, and gfortran gives a private module
  ! procedure local linkage)
  private :: crt_arg, crt_tgt, crt_bytes, crt_cpool, crt_out, crt_timespec, crt_slot_obj, crt_out_obj, crt_err_obj, crt_nst, crt_stn, crt_stk, &
       crt_sti, crt_std, crt_toknext, crt_trace

  private :: crt_atomic_d_assign, crt_atomic_d_clone, crt_atomic_i_assign, crt_atomic_i_clone, crt_atomic_l_assign, crt_atomic_l_clone, &
       crt_atomic_z_assign, crt_atomic_z_clone, crt_c_clock_gettime, crt_c_ctime_r, crt_c_fclose, crt_c_feof, &
       crt_c_ferror, crt_c_fflush, crt_c_fgetc, crt_c_fgets, crt_c_fopen, crt_c_fread, &
       crt_c_fseek, crt_c_ftell, crt_c_fwrite, crt_c_get_nprocs, crt_c_getenv, crt_c_strlen, &
       crt_c_time, crt_c_write, crt_cls, crt_cz, crt_defer_dispose, crt_digit, &
       crt_format, crt_fstr, crt_i1, crt_inset, crt_int_chars, crt_low32, &
       crt_m_acos, crt_m_asin, crt_m_atan, crt_m_atan2, crt_m_cbrt, crt_m_ceil, &
       crt_m_cos, crt_m_cosh, crt_m_exp, crt_m_expm1, crt_m_floor, crt_m_fmod, &
       crt_m_hypot, crt_m_log, crt_m_log10, crt_m_log1p, crt_m_log2, crt_m_nextafter, &
       crt_m_pow, crt_m_remainder, crt_m_round, crt_m_sin, crt_m_sinh, crt_m_tan, &
       crt_m_tanh, crt_m_trunc, crt_putb_b, crt_putb_d, crt_putb_f, crt_putb_i, &
       crt_putb_l, crt_putb_s, crt_putb_z, crt_read, crt_scan, crt_span, &
       crt_strtod, crt_take, crt_tcls, crt_tupn_assign, crt_tupn_clone, crt_ub, &
       crt_write, crt_write_str

  ! ---------------------------------------------------------------------------------------------- glibc (bind(C))
  interface
    ! libm: the functions .NET's System.Math and the C# runtime's LibM call
    function crt_m_acos(x) bind(C, name='acos') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_asin(x) bind(C, name='asin') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_atan(x) bind(C, name='atan') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_atan2(y, x) bind(C, name='atan2') result(r)
      import :: c_double
      real(c_double), value :: y, x
      real(c_double) :: r
    end function
    function crt_m_cbrt(x) bind(C, name='cbrt') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_ceil(x) bind(C, name='ceil') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_cos(x) bind(C, name='cos') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_cosh(x) bind(C, name='cosh') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_exp(x) bind(C, name='exp') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_floor(x) bind(C, name='floor') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_log10(x) bind(C, name='log10') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_log2(x) bind(C, name='log2') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_log(x) bind(C, name='log') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_pow(x, y) bind(C, name='pow') result(r)
      import :: c_double
      real(c_double), value :: x, y
      real(c_double) :: r
    end function
    function crt_m_sin(x) bind(C, name='sin') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_sinh(x) bind(C, name='sinh') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_tan(x) bind(C, name='tan') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_tanh(x) bind(C, name='tanh') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_trunc(x) bind(C, name='trunc') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_expm1(x) bind(C, name='expm1') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_fmod(x, y) bind(C, name='fmod') result(r)
      import :: c_double
      real(c_double), value :: x, y
      real(c_double) :: r
    end function
    function crt_m_hypot(x, y) bind(C, name='hypot') result(r)
      import :: c_double
      real(c_double), value :: x, y
      real(c_double) :: r
    end function
    function crt_m_log1p(x) bind(C, name='log1p') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    function crt_m_nextafter(x, y) bind(C, name='nextafter') result(r)
      import :: c_double
      real(c_double), value :: x, y
      real(c_double) :: r
    end function
    function crt_m_remainder(x, y) bind(C, name='remainder') result(r)
      import :: c_double
      real(c_double), value :: x, y
      real(c_double) :: r
    end function
    function crt_m_round(x) bind(C, name='round') result(r)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: r
    end function
    ! stdio
    function crt_c_fopen(name, mode) bind(C, name='fopen') result(r)
      import :: c_ptr, c_char
      character(kind=c_char), intent(in) :: name(*), mode(*)
      type(c_ptr) :: r
    end function
    function crt_c_fclose(f) bind(C, name='fclose') result(r)
      import :: c_ptr, c_int
      type(c_ptr), value :: f
      integer(c_int) :: r
    end function
    function crt_c_fflush(f) bind(C, name='fflush') result(r)
      import :: c_ptr, c_int
      type(c_ptr), value :: f
      integer(c_int) :: r
    end function
    function crt_c_ferror(f) bind(C, name='ferror') result(r)
      import :: c_ptr, c_int
      type(c_ptr), value :: f
      integer(c_int) :: r
    end function
    function crt_c_feof(f) bind(C, name='feof') result(r)
      import :: c_ptr, c_int
      type(c_ptr), value :: f
      integer(c_int) :: r
    end function
    function crt_c_fseek(f, off, whence) bind(C, name='fseek') result(r)
      import :: c_ptr, c_int, c_long
      type(c_ptr), value :: f
      integer(c_long), value :: off
      integer(c_int), value :: whence
      integer(c_int) :: r
    end function
    function crt_c_ftell(f) bind(C, name='ftell') result(r)
      import :: c_ptr, c_long
      type(c_ptr), value :: f
      integer(c_long) :: r
    end function
    subroutine crt_c_rewind(f) bind(C, name='rewind')
      import :: c_ptr
      type(c_ptr), value :: f
    end subroutine
    function crt_c_fgets(buf, n, f) bind(C, name='fgets') result(r)
      import :: c_ptr, c_int
      type(c_ptr), value :: buf
      integer(c_int), value :: n
      type(c_ptr), value :: f
      type(c_ptr) :: r
    end function
    function crt_c_fgetc(f) bind(C, name='fgetc') result(r)
      import :: c_ptr, c_int
      type(c_ptr), value :: f
      integer(c_int) :: r
    end function
    function crt_c_fread(buf, size, n, f) bind(C, name='fread') result(r)
      import :: c_ptr, c_size_t
      type(c_ptr), value :: buf
      integer(c_size_t), value :: size, n
      type(c_ptr), value :: f
      integer(c_size_t) :: r
    end function
    function crt_c_fwrite(buf, size, n, f) bind(C, name='fwrite') result(r)
      import :: c_ptr, c_size_t
      type(c_ptr), value :: buf
      integer(c_size_t), value :: size, n
      type(c_ptr), value :: f
      integer(c_size_t) :: r
    end function
    function crt_c_write(fd, buf, n) bind(C, name='write') result(r)
      import :: c_ptr, c_int, c_size_t, c_intptr_t
      integer(c_int), value :: fd
      type(c_ptr), value :: buf
      integer(c_size_t), value :: n
      integer(c_intptr_t) :: r
    end function
    ! the rest of libc
    function crt_c_getenv(name) bind(C, name='getenv') result(r)
      import :: c_ptr, c_char
      character(kind=c_char), intent(in) :: name(*)
      type(c_ptr) :: r
    end function
    function crt_c_strlen(p) bind(C, name='strlen') result(r)
      import :: c_ptr, c_size_t
      type(c_ptr), value :: p
      integer(c_size_t) :: r
    end function
    function crt_c_time(p) bind(C, name='time') result(r)
      import :: c_ptr, c_long
      type(c_ptr), value :: p
      integer(c_long) :: r
    end function
    function crt_c_ctime_r(t, buf) bind(C, name='ctime_r') result(r)
      import :: c_ptr, c_long, c_char
      integer(c_long), intent(in) :: t
      character(kind=c_char), intent(inout) :: buf(*)
      type(c_ptr) :: r
    end function
    function crt_c_get_nprocs() bind(C, name='get_nprocs') result(r)
      import :: c_int
      integer(c_int) :: r
    end function
    function crt_c_clock_gettime(clk, ts) bind(C, name='clock_gettime') result(r)
      import :: c_int, crt_timespec
      integer(c_int), value :: clk
      type(crt_timespec), intent(out) :: ts
      integer(c_int) :: r
    end function
  end interface

  ! ---------------------------------------------------------------------------------------------- submodules
  interface
    ! submodule fmt: glibc's printf, strtod and sscanf
    !> the bytes printf writes for the format fb(fo:) (a NUL or the array's end ends it) and the arguments ar(1:na)
    recursive module subroutine crt_format(fb, fo, ar, na, out, nout)
      integer(1), intent(in) :: fb(0:)
      integer(8), intent(in) :: fo
      type(crt_arg), intent(in) :: ar(:)
      integer, intent(in) :: na
      integer(1), allocatable, intent(inout) :: out(:)
      integer, intent(out) :: nout
    end subroutine
    !> glibc's strtod (strtof when isflt) on b(start:): the IEEE bits (a float's sign-extended) and the bytes read
    recursive module subroutine crt_strtod(b, start, isflt, bits, ncons)
      integer(1), intent(in) :: b(0:)
      integer(8), intent(in) :: start
      logical, intent(in) :: isflt
      integer(8), intent(out) :: bits, ncons
    end subroutine
    !> glibc's sscanf of sb(so:) with the format fb(fo:) into the targets tg(1:nt)
    recursive module function crt_scan(sb, so, fb, fo, tg, nt) result(done)
      integer(1), intent(in) :: sb(0:)
      integer(8), intent(in) :: so
      integer(1), intent(in) :: fb(0:)
      integer(8), intent(in) :: fo
      type(crt_tgt), intent(inout) :: tg(:)
      integer, intent(in) :: nt
      integer :: done
    end function
    ! submodule ptr: the members that need part A's Ptr layout
    recursive module function cpp_bytes_view_ptrt__b(a1) result(zres)
      type(cpp_ptr_b), intent(in) :: a1
      type(cpp_cptr) :: zres
    end function
    recursive module function cpp_bytes_view_ptrt__d(a1) result(zres)
      type(cpp_ptr_d), intent(in) :: a1
      type(cpp_cptr) :: zres
    end function
    recursive module function cpp_bytes_view_ptrt__f(a1) result(zres)
      type(cpp_ptr_f), intent(in) :: a1
      type(cpp_cptr) :: zres
    end function
    recursive module function cpp_bytes_view_ptrt__i(a1) result(zres)
      type(cpp_ptr_i), intent(in) :: a1
      type(cpp_cptr) :: zres
    end function
    recursive module function cpp_bytes_view_ptrt__l(a1) result(zres)
      type(cpp_ptr_l), intent(in) :: a1
      type(cpp_cptr) :: zres
    end function
    recursive module function cpp_bytes_view_ptrt__s(a1) result(zres)
      type(cpp_ptr_s), intent(in) :: a1
      type(cpp_cptr) :: zres
    end function
    recursive module function cpp_bytes_view_ptrt__z(a1) result(zres)
      type(cpp_ptr_z), intent(in) :: a1
      type(cpp_cptr) :: zres
    end function
    recursive module function cpp_mem_diff_t_ptrt__o(a1, a2, mk3, cm4) result(zres)
      class(*), pointer, intent(in) :: a1
      type(cpp_ptr_o), intent(in) :: a2
      procedure(cpp_maker) :: mk3
      integer(4), value :: cm4
      integer(8) :: zres
    end function
    recursive module function cpp_r_time_ptrl(a1) result(zres)
      type(cpp_ptr_l), intent(in) :: a1
      integer(8) :: zres
    end function
    !> the order of two TupN keys (C#'s TupN.CompareTo): -1, 0 or 1, element by element
    recursive module function cpp_tupn_compareto(a, b) result(zres)
      class(cpp_tupn), intent(in) :: a, b
      integer(4) :: zres
    end function
  end interface

contains

  ! ============================================================================================== type bindings
  recursive function crt_atomic_d_clone(self) result(zres)
    class(cpp_atomic_d), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_atomic_d), pointer :: r
    allocate(r)
    r%v = self%v
    zres => r
  end function crt_atomic_d_clone
  recursive subroutine crt_atomic_d_assign(self, other)
    class(cpp_atomic_d), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    select type (other)
    class is (cpp_atomic_d)
      self%v = other%v
    end select
  end subroutine crt_atomic_d_assign
  recursive function crt_atomic_i_clone(self) result(zres)
    class(cpp_atomic_i), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_atomic_i), pointer :: r
    allocate(r)
    r%v = self%v
    zres => r
  end function crt_atomic_i_clone
  recursive subroutine crt_atomic_i_assign(self, other)
    class(cpp_atomic_i), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    select type (other)
    class is (cpp_atomic_i)
      self%v = other%v
    end select
  end subroutine crt_atomic_i_assign
  recursive function crt_atomic_l_clone(self) result(zres)
    class(cpp_atomic_l), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_atomic_l), pointer :: r
    allocate(r)
    r%v = self%v
    zres => r
  end function crt_atomic_l_clone
  recursive subroutine crt_atomic_l_assign(self, other)
    class(cpp_atomic_l), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    select type (other)
    class is (cpp_atomic_l)
      self%v = other%v
    end select
  end subroutine crt_atomic_l_assign
  recursive function crt_atomic_z_clone(self) result(zres)
    class(cpp_atomic_z), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_atomic_z), pointer :: r
    allocate(r)
    r%v = self%v
    zres => r
  end function crt_atomic_z_clone
  recursive subroutine crt_atomic_z_assign(self, other)
    class(cpp_atomic_z), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    select type (other)
    class is (cpp_atomic_z)
      self%v = other%v
    end select
  end subroutine crt_atomic_z_assign

  !> Defer.Dispose: run the action once (unless cancelled)
  recursive subroutine crt_defer_dispose(self)
    class(cpp_defer), intent(inout), target :: self
    class(cpp_action), pointer :: x
    x => self%a
    self%a => null()
    if (associated(x)) call x%invoke()
  end subroutine crt_defer_dispose

  !> TupN.Clone: a new tuple of the same items (C#'s object[] Clone: the boxes are shared, never changed)
  recursive function crt_tupn_clone(self) result(zres)
    class(cpp_tupn), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_tupn), pointer :: r
    allocate(r)
    if (allocated(self%v)) then
      allocate(r%v(size(self%v)))
      r%v = self%v
    else
      allocate(r%v(0))
    end if
    zres => r
  end function crt_tupn_clone
  recursive subroutine crt_tupn_assign(self, other)
    class(cpp_tupn), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    type(cpp_slot), allocatable :: t(:)
    select type (other)
    class is (cpp_tupn)
      if (allocated(other%v)) then
        allocate(t(size(other%v)))
        t = other%v
      else
        allocate(t(0))
      end if
      call move_alloc(t, self%v)
    end select
  end subroutine crt_tupn_assign

  ! ============================================================================================== Atomic
  !> compare_exchange on one thread: never fails spuriously; equality is .NET's for double (NaN equals NaN)
  recursive function cpp_atomic_d_compare_exchange(self, a1, a2) result(zres)
    class(cpp_atomic_d), intent(inout), target :: self
    real(8), intent(inout) :: a1
    real(8), value :: a2
    logical :: zres
    if (self%v == a1 .or. (self%v /= self%v .and. a1 /= a1)) then
      self%v = a2
      zres = .true.
    else
      a1 = self%v
      zres = .false.
    end if
  end function cpp_atomic_d_compare_exchange
  recursive function cpp_atomic_d_new_0() result(zres)
    class(cpp_atomic_d), pointer :: zres
    allocate(zres)
  end function cpp_atomic_d_new_0
  recursive function cpp_atomic_i_new_t(a1) result(zres)
    integer(4), value :: a1
    class(cpp_atomic_i), pointer :: zres
    allocate(zres)
    zres%v = a1
  end function cpp_atomic_i_new_t
  !> fetch_add (wrapping) returning the old value
  recursive function cpp_atomic_l_fetch_add(self, a1, a2) result(zres)
    class(cpp_atomic_l), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
    integer(8) :: zres
    zres = self%v
    self%v = self%v + a1
  end function cpp_atomic_l_fetch_add
  recursive function cpp_atomic_l_new_0() result(zres)
    class(cpp_atomic_l), pointer :: zres
    allocate(zres)
  end function cpp_atomic_l_new_0
  recursive function cpp_atomic_l_new_t(a1) result(zres)
    integer(8), value :: a1
    class(cpp_atomic_l), pointer :: zres
    allocate(zres)
    zres%v = a1
  end function cpp_atomic_l_new_t
  recursive function cpp_atomic_z_new_t(a1) result(zres)
    logical, value :: a1
    class(cpp_atomic_z), pointer :: zres
    allocate(zres)
    zres%v = a1
  end function cpp_atomic_z_new_t

  ! ============================================================================================== Box<bool>
  recursive function cpp_box_z_of(a1) result(zres)
    class(cpp_refget_z), pointer, intent(in) :: a1
    class(cpp_box_z), pointer :: zres
    allocate(zres)
    zres%g => a1
  end function cpp_box_z_of
  !> the place the reference refers to
  recursive function cpp_box_z_v(self) result(zres)
    class(cpp_box_z), intent(inout), target :: self
    logical, pointer :: zres
    if (associated(self%g)) then
      zres => self%g%invoke()
    else if (associated(self%a)) then
      zres => self%a%a(self%o)
    else
      zres => null()
    end if
  end function cpp_box_z_v

  ! ============================================================================================== Bytes
  !> Bytes.View(CPtr): the pointer itself
  recursive function cpp_bytes_view_cptr(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr) :: zres
    zres = a1
  end function cpp_bytes_view_cptr

  ! ============================================================================================== one-thread stand-ins
  recursive function cpp_condvar_new() result(zres)
    class(cpp_condvar), pointer :: zres
    allocate(zres)
  end function cpp_condvar_new
  recursive function cpp_lock_new() result(zres)
    class(cpp_lock), pointer :: zres
    allocate(zres)
  end function cpp_lock_new
  recursive function cpp_mutex_new() result(zres)
    class(cpp_mutex), pointer :: zres
    allocate(zres)
  end function cpp_mutex_new
  recursive function cpp_onceflag_new() result(zres)
    class(cpp_onceflag), pointer :: zres
    allocate(zres)
  end function cpp_onceflag_new
  recursive function cpp_thread_new() result(zres)
    class(cpp_thread), pointer :: zres
    allocate(zres)
  end function cpp_thread_new

  ! ============================================================================================== Conv (x86-64)
  !> cvttsd2si to int: NaN and out-of-range values give the integer indefinite value
  recursive function cpp_conv_d2i(a1) result(zres)
    real(8), value :: a1
    integer(4) :: zres
    if (a1 > -2147483649.0_8 .and. a1 < 2147483648.0_8) then
      zres = int(a1, 4)
    else
      zres = -huge(1_4) - 1_4
    end if
  end function cpp_conv_d2i
  recursive function cpp_conv_d2l(a1) result(zres)
    real(8), value :: a1
    integer(8) :: zres
    if (a1 >= -9223372036854775808.0_8 .and. a1 < 9223372036854775808.0_8) then
      zres = int(a1, 8)
    else
      zres = -huge(1_8) - 1_8
    end if
  end function cpp_conv_d2l
  !> GCC's double -> signed char: the int conversion, its low byte
  recursive function cpp_conv_d2sb(a1) result(zres)
    real(8), value :: a1
    integer(1) :: zres
    zres = crt_i1(int(cpp_conv_d2i(a1), 8))
  end function cpp_conv_d2sb
  !> GCC's double -> unsigned long: below 2^63 the signed conversion, above it that of x - 2^63 with the top bit
  recursive function cpp_conv_d2ul(a1) result(zres)
    real(8), value :: a1
    integer(8) :: zres
    if (a1 < 9223372036854775808.0_8) then
      zres = cpp_conv_d2l(a1)
    else
      zres = ieor(cpp_conv_d2l(a1 - 9223372036854775808.0_8), -huge(1_8) - 1_8)
    end if
  end function cpp_conv_d2ul

  ! ============================================================================================== Dbg, Defer, Dtor
  !> with the environment variable SWMM6_CS_TRACE set, each exception a translated catch handler catches is
  !> written to stderr
  recursive subroutine cpp_dbg_caught(a1)
    class(cpp_object), pointer, intent(in) :: a1
    integer :: st
    type(cpp_cptr) :: w
    character(len=:), allocatable :: s
    if (crt_trace == 0) then
      call get_environment_variable('SWMM6_CS_TRACE', status=st)
      crt_trace = merge(2, 1, st == 0 .or. st == -1)
    end if
    if (crt_trace /= 2 .or. .not. associated(a1)) return
    select type (a1)
    class is (cpp_sysexception)
      s = '[caught] System.' // a1%name // ': ' // a1%message
    class is (cpp_cppexception)
      w = cpp_cppexception_what(a1)
      s = '[caught] std::exception: ' // crt_fstr(w)
    class default
      s = '[caught] an exception object'
    end select
    call crt_write_str(2, s // achar(10))
  end subroutine cpp_dbg_caught
  recursive subroutine cpp_defer_cancel(self)
    class(cpp_defer), intent(inout), target :: self
    self%a => null()
  end subroutine cpp_defer_cancel
  recursive function cpp_defer_new(a1) result(zres)
    class(cpp_action), pointer, intent(in) :: a1
    class(cpp_defer), pointer :: zres
    allocate(zres)
    zres%a => a1
  end function cpp_defer_new
  !> run a C++ destructor: an object's dispose binding (an engine class's destructor, a container's elements, a
  !> stream's close), each element of an array of objects; nothing for null or a value
  recursive subroutine cpp_dtor_run(a1)
    class(*), pointer, intent(in) :: a1
    class(*), pointer :: x
    integer(8) :: i
    if (.not. associated(a1)) return
    select type (a1)
    class is (cpp_arr_o)
      if (.not. allocated(a1%a)) return
      do i = lbound(a1%a, 1, 8), ubound(a1%a, 1, 8)
        x => a1%a(i)%p
        call cpp_dtor_run(x)
        if (associated(cpp_exc)) return
      end do
    class is (cpp_object)
      call a1%dispose()
    end select
  end subroutine cpp_dtor_run

  ! ============================================================================================== chrono
  recursive function cpp_duration_clone(self) result(zres)
    type(cpp_duration), intent(in) :: self
    type(cpp_duration) :: zres
    zres = self
  end function cpp_duration_clone
  !> seconds (the engine's durations are duration<double>)
  recursive function cpp_duration_count(self) result(zres)
    type(cpp_duration), intent(in) :: self
    real(8) :: zres
    zres = real(self%ns, 8) * 1.0e-9_8
  end function cpp_duration_count
  recursive function cpp_timepoint_clone(self) result(zres)
    type(cpp_timepoint), intent(in) :: self
    type(cpp_timepoint) :: zres
    zres = self
  end function cpp_timepoint_clone
  !> now: the monotonic clock in nanoseconds (clock_gettime(CLOCK_MONOTONIC), what .NET's Stopwatch reads)
  recursive function cpp_timepoint_now() result(zres)
    type(cpp_timepoint) :: zres
    type(crt_timespec) :: ts
    integer(c_int) :: r
    r = crt_c_clock_gettime(1_c_int, ts)
    zres%ns = int(ts%s, 8) * 1000000000_8 + int(ts%ns, 8)
  end function cpp_timepoint_now
  recursive function cpp_timepoint_op_sub(a1, a2) result(zres)
    type(cpp_timepoint), intent(in) :: a1
    type(cpp_timepoint), intent(in) :: a2
    type(cpp_duration) :: zres
    zres%ns = a1%ns - a2%ns
  end function cpp_timepoint_op_sub

  ! ============================================================================================== ErrorCode
  recursive function cpp_errorcode_bool(self) result(zres)
    class(cpp_errorcode), intent(inout), target :: self
    logical :: zres
    zres = self%v /= 0
  end function cpp_errorcode_bool
  recursive function cpp_errorcode_new() result(zres)
    class(cpp_errorcode), pointer :: zres
    allocate(zres)
  end function cpp_errorcode_new

  ! ============================================================================================== LibM (glibc)
  recursive function cpp_libm_expm1(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_expm1(a1)
  end function cpp_libm_expm1
  recursive function cpp_libm_fmod(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
    zres = crt_m_fmod(a1, a2)
  end function cpp_libm_fmod
  recursive function cpp_libm_hypot(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
    zres = crt_m_hypot(a1, a2)
  end function cpp_libm_hypot
  recursive function cpp_libm_log1p(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_log1p(a1)
  end function cpp_libm_log1p
  !> nextafter: the C# computes it itself (BitIncrement / BitDecrement, x + y for a NaN), with glibc's results
  recursive function cpp_libm_nextafter(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
    zres = crt_m_nextafter(a1, a2)
  end function cpp_libm_nextafter
  recursive function cpp_libm_remainder(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
    zres = crt_m_remainder(a1, a2)
  end function cpp_libm_remainder
  !> C's round (halfway cases away from zero), not .NET's Math.Round
  recursive function cpp_libm_round(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_round(a1)
  end function cpp_libm_round

  ! ============================================================================================== System.Math
  recursive function cpp_math_acos_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_acos(a1)
  end function cpp_math_acos_d
  recursive function cpp_math_asin_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_asin(a1)
  end function cpp_math_asin_d
  recursive function cpp_math_atan2_dd(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
    zres = crt_m_atan2(a1, a2)
  end function cpp_math_atan2_dd
  recursive function cpp_math_atan_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_atan(a1)
  end function cpp_math_atan_d
  recursive function cpp_math_cbrt_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_cbrt(a1)
  end function cpp_math_cbrt_d
  !> .NET computes Ceiling itself (roundsd), exactly: the same as libm's ceil
  recursive function cpp_math_ceiling_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_ceil(a1)
  end function cpp_math_ceiling_d
  !> Math.CopySign: x's magnitude with y's sign bit (a NaN y's too), on the bits as .NET does it
  recursive function cpp_math_copysign_dd(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
    zres = transfer(ior(iand(transfer(a1, 0_8), huge(0_8)), iand(transfer(a2, 0_8), -huge(0_8) - 1_8)), 0.0_8)
  end function cpp_math_copysign_dd
  recursive function cpp_math_cos_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_cos(a1)
  end function cpp_math_cos_d
  recursive function cpp_math_cosh_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_cosh(a1)
  end function cpp_math_cosh_d
  recursive function cpp_math_exp_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_exp(a1)
  end function cpp_math_exp_d
  !> .NET computes Floor itself (roundsd), exactly: the same as libm's floor
  recursive function cpp_math_floor_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_floor(a1)
  end function cpp_math_floor_d
  recursive function cpp_math_log10_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_log10(a1)
  end function cpp_math_log10_d
  recursive function cpp_math_log2_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_log2(a1)
  end function cpp_math_log2_d
  recursive function cpp_math_log_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_log(a1)
  end function cpp_math_log_d
  recursive function cpp_math_pow_dd(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
    zres = crt_m_pow(a1, a2)
  end function cpp_math_pow_dd
  recursive function cpp_math_sin_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_sin(a1)
  end function cpp_math_sin_d
  recursive function cpp_math_sinh_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_sinh(a1)
  end function cpp_math_sinh_d
  recursive function cpp_math_tan_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_tan(a1)
  end function cpp_math_tan_d
  recursive function cpp_math_tanh_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_tanh(a1)
  end function cpp_math_tanh_d
  !> .NET computes Truncate itself (roundsd toward zero), exactly: the same as libm's trunc
  recursive function cpp_math_truncate_d(a1) result(zres)
    real(8), value :: a1
    real(8) :: zres
    zres = crt_m_trunc(a1)
  end function cpp_math_truncate_d

  ! ============================================================================================== Mem, Mv
  !> calloc(n, size) cast to double*: n*size bytes of zeroed doubles (C#'s Calloc<double>)
  recursive function cpp_mem_calloc__d(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    type(cpp_ptr_d) :: zres
    class(cpp_arr_d), pointer :: arr
    integer(8) :: n
    n = (a1 * a2) / 8_8
    if (n < 0) n = 0
    allocate(arr)
    allocate(arr%a(0:n-1))
    if (n > 0) arr%a = 0.0_8
    zres = cpp_ptr_d_new_ta_l(arr, 0_8)
  end function cpp_mem_calloc__d
  !> fread into a char buffer: size*count bytes (no more than the buffer holds), the number of whole items read
  recursive function cpp_mem_fread_cptr_ul_ul_cfile(a1, a2, a3, a4) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
    integer(8) :: want, got
    zres = 0
    if (.not. associated(a1%b) .or. a2 <= 0) return
    want = min(a2 * a3, size(a1%b%a, kind=8) - a1%o)
    if (want <= 0) return
    got = crt_read(a4, a1%b%a(a1%o:a1%o+want-1), want)
    zres = got / a2
  end function cpp_mem_fread_cptr_ul_ul_cfile
  recursive function cpp_mem_fread_ptrt_ul_ul_cfile__f(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
    integer(1), allocatable :: buf(:)
    integer(8) :: want, got
    zres = 0
    want = a2 * a3
    if (a2 <= 0 .or. want <= 0) return
    allocate(buf(0:want-1))
    got = crt_read(a4, buf, want)
    if (got > 0) call crt_putb_f(a1, got, buf)
    zres = got / a2
  end function cpp_mem_fread_ptrt_ul_ul_cfile__f
  recursive function cpp_mem_fread_ptrt_ul_ul_cfile__i(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
    integer(1), allocatable :: buf(:)
    integer(8) :: want, got
    zres = 0
    want = a2 * a3
    if (a2 <= 0 .or. want <= 0) return
    allocate(buf(0:want-1))
    got = crt_read(a4, buf, want)
    if (got > 0) call crt_putb_i(a1, got, buf)
    zres = got / a2
  end function cpp_mem_fread_ptrt_ul_ul_cfile__i
  recursive subroutine cpp_mem_free(a1)
    class(*), pointer, intent(in) :: a1
  end subroutine cpp_mem_free
  !> fwrite of a char buffer: size*count bytes; count (as the C# returns it)
  recursive function cpp_mem_fwrite_cptr_ul_ul_cfile(a1, a2, a3, a4) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
    integer(8) :: n
    zres = a3
    n = a2 * a3
    if (n <= 0 .or. .not. associated(a1%b)) return
    n = min(n, size(a1%b%a, kind=8) - a1%o)
    if (n > 0) call crt_write(a4, a1%b%a(a1%o:a1%o+n-1), n)
  end function cpp_mem_fwrite_cptr_ul_ul_cfile
  recursive function cpp_mem_fwrite_ptrt_ul_ul_cfile__f(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
    integer(1), allocatable :: buf(:)
    integer(8) :: n
    zres = a3
    n = a2 * a3
    if (n <= 0) return
    allocate(buf(0:n-1))
    call crt_getb_f(a1, n, buf)
    call crt_write(a4, buf, n)
  end function cpp_mem_fwrite_ptrt_ul_ul_cfile__f
  recursive function cpp_mem_fwrite_ptrt_ul_ul_cfile__i(a1, a2, a3, a4) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_cfile), pointer, intent(in) :: a4
    integer(8) :: zres
    integer(1), allocatable :: buf(:)
    integer(8) :: n
    zres = a3
    n = a2 * a3
    if (n <= 0) return
    allocate(buf(0:n-1))
    call crt_getb_i(a1, n, buf)
    call crt_write(a4, buf, n)
  end function cpp_mem_fwrite_ptrt_ul_ul_cfile__i
  !> memcpy from a char buffer into typed elements: exactly n bytes, a partly covered element changes only those
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__b(a1, a2, a3) result(zres)
    type(cpp_ptr_b), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_b) :: zres
    if (a3 > 0) call crt_putb_b(a1, a3, a2%b%a(a2%o:a2%o+a3-1))
    zres = a1
  end function cpp_mem_memcpy_ptrt_cptr_ul__b
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__d(a1, a2, a3) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_d) :: zres
    if (a3 > 0) call crt_putb_d(a1, a3, a2%b%a(a2%o:a2%o+a3-1))
    zres = a1
  end function cpp_mem_memcpy_ptrt_cptr_ul__d
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__f(a1, a2, a3) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_f) :: zres
    if (a3 > 0) call crt_putb_f(a1, a3, a2%b%a(a2%o:a2%o+a3-1))
    zres = a1
  end function cpp_mem_memcpy_ptrt_cptr_ul__f
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__i(a1, a2, a3) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_i) :: zres
    if (a3 > 0) call crt_putb_i(a1, a3, a2%b%a(a2%o:a2%o+a3-1))
    zres = a1
  end function cpp_mem_memcpy_ptrt_cptr_ul__i
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__l(a1, a2, a3) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_l) :: zres
    if (a3 > 0) call crt_putb_l(a1, a3, a2%b%a(a2%o:a2%o+a3-1))
    zres = a1
  end function cpp_mem_memcpy_ptrt_cptr_ul__l
  recursive function cpp_mem_memcpy_ptrt_cptr_ul__s(a1, a2, a3) result(zres)
    type(cpp_ptr_s), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_s) :: zres
    if (a3 > 0) call crt_putb_s(a1, a3, a2%b%a(a2%o:a2%o+a3-1))
    zres = a1
  end function cpp_mem_memcpy_ptrt_cptr_ul__s
  !> memcpy(uint*, byte*, n) (the hot-start file's CRC)
  recursive function cpp_mem_memcpy_ptrt_ptru_ul__ib(a1, a2, a3) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    type(cpp_ptr_b), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_i) :: zres
    integer(1), allocatable :: buf(:)
    if (a3 > 0) then
      allocate(buf(0:a3-1))
      call crt_getb_b(a2, a3, buf)
      call crt_putb_i(a1, a3, buf)
    end if
    zres = a1
  end function cpp_mem_memcpy_ptrt_ptru_ul__ib
  !> memcpy(ulong*, double*, n) (the bits of a double)
  recursive function cpp_mem_memcpy_ptrt_ptru_ul__ld(a1, a2, a3) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    type(cpp_ptr_d), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_ptr_l) :: zres
    integer(1), allocatable :: buf(:)
    if (a3 > 0) then
      allocate(buf(0:a3-1))
      call crt_getb_d(a2, a3, buf)
      call crt_putb_l(a1, a3, buf)
    end if
    zres = a1
  end function cpp_mem_memcpy_ptrt_ptru_ul__ld
  !> Mv.Delete: delete p, the object's dispose binding (its destructor)
  recursive subroutine cpp_mv_delete(a1)
    class(*), pointer, intent(in) :: a1
    if (.not. associated(a1)) return
    select type (a1)
    class is (cpp_object)
      call a1%dispose()
    end select
  end subroutine cpp_mv_delete
  !> p++ (d = 1) or p-- (d = -1) on a Ptr<double>: the old value, p moved
  recursive function cpp_mv_poststep_ptrtr_i__d(a1, a2) result(zres)
    type(cpp_ptr_d), intent(inout) :: a1
    integer(4), value :: a2
    type(cpp_ptr_d) :: zres
    zres = a1
    a1 = cpp_ptr_d_op_add_ptrt_l(zres, int(a2, 8))
  end function cpp_mv_poststep_ptrtr_i__d

  ! ============================================================================================== R: char arrays
  !> a new NUL-terminated buffer holding the bytes of the Fortran string a1 (every call)
  recursive function cpp_r_lit(a1) result(zres)
    character(len=*), intent(in) :: a1
    type(cpp_cptr) :: zres
    class(cpp_arr_b), pointer :: b
    integer :: n
    n = len(a1)
    allocate(b)
    allocate(b%a(0:n))
    if (n > 0) b%a(0:n-1) = transfer(a1, b%a(0:n-1))
    b%a(n) = 0
    zres%b => b
    zres%o = 0
  end function cpp_r_lit
  !> char a[n] = "literal": n bytes (at least the literal and its NUL), the literal's first, the rest zero
  recursive function cpp_r_litn(a1, a2) result(zres)
    character(len=*), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_cptr) :: zres
    class(cpp_arr_b), pointer :: b
    integer :: n
    n = len(a1)
    allocate(b)
    allocate(b%a(0:max(a2, n + 1) - 1))
    b%a = 0
    if (n > 0) b%a(0:n-1) = transfer(a1, b%a(0:n-1))
    zres%b => b
    zres%o = 0
  end function cpp_r_litn
  !> char buf[n]: n zeroed bytes (at least one)
  recursive function cpp_r_buf_i(a1) result(zres)
    integer(4), value :: a1
    type(cpp_cptr) :: zres
    class(cpp_arr_b), pointer :: b
    allocate(b)
    allocate(b%a(0:max(a1, 1) - 1))
    b%a = 0
    zres%b => b
    zres%o = 0
  end function cpp_r_buf_i
  !> char buf[n] = { ... }: n bytes (at least one), the given ones first, the rest zero
  recursive function cpp_r_bufof(a1, a2) result(zres)
    integer(4), value :: a1
    class(cpp_arr_i), pointer, intent(in) :: a2
    type(cpp_cptr) :: zres
    integer(8) :: i, m
    zres = cpp_r_buf_i(a1)
    if (.not. associated(a2)) return
    if (.not. allocated(a2%a)) return
    m = min(size(a2%a, kind=8), size(zres%b%a, kind=8))
    do i = 0, m - 1
      zres%b%a(i) = crt_i1(int(a2%a(lbound(a2%a, 1) + i), 8))
    end do
  end function cpp_r_bufof
  !> char a[n][m]: n zeroed rows of m bytes (an array of boxed CPtr)
  recursive function cpp_r_bufs(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    class(cpp_arr_o), pointer :: zres
    type(cpp_cptr) :: row
    integer :: i
    allocate(zres)
    allocate(zres%a(0:max(a1, 0) - 1))
    do i = 0, a1 - 1
      row = cpp_r_buf_i(a2)
      allocate(zres%a(i)%p, source=row)
    end do
  end function cpp_r_bufs
  !> a copy of the whole buffer, the same offset (null stays null)
  recursive function cpp_r_copybuf(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr) :: zres
    class(cpp_arr_b), pointer :: b
    zres = a1
    if (.not. associated(a1%b)) return
    allocate(b)
    allocate(b%a(0:size(a1%b%a) - 1))
    b%a = a1%b%a
    zres%b => b
  end function cpp_r_copybuf
  !> copy-assigning a char array member: as many bytes as both arrays hold from the offsets
  recursive subroutine cpp_r_memcpybuf(a1, a2)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8) :: n
    if (.not. associated(a1%b) .or. .not. associated(a2%b)) return
    n = min(size(a1%b%a, kind=8) - a1%o, size(a2%b%a, kind=8) - a2%o)
    if (n > 0) a1%b%a(a1%o:a1%o+n-1) = a2%b%a(a2%o:a2%o+n-1)
  end subroutine cpp_r_memcpybuf

  ! ============================================================================================== R: strings
  recursive function cpp_r_strlen(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8) :: zres
    integer(8) :: i, n
    zres = 0
    if (.not. associated(a1%b)) return
    n = size(a1%b%a, kind=8)
    i = a1%o
    do while (i < n)
      if (a1%b%a(i) == 0) exit
      i = i + 1
    end do
    zres = i - a1%o
  end function cpp_r_strlen
  !> strcmp: the difference of the first differing bytes (unsigned), 0 when equal
  recursive function cpp_r_strcmp(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4) :: zres
    integer(8) :: i
    integer(4) :: x, y
    i = 0
    do
      x = crt_ub(a1, i)
      y = crt_ub(a2, i)
      if (x /= y) then
        zres = x - y
        return
      end if
      if (x == 0) exit
      i = i + 1
    end do
    zres = 0
  end function cpp_r_strcmp
  recursive function cpp_r_strncmp(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    integer(4) :: zres
    integer(8) :: i
    integer(4) :: x, y
    zres = 0
    do i = 0, a3 - 1
      x = crt_ub(a1, i)
      y = crt_ub(a2, i)
      if (x /= y) then
        zres = x - y
        return
      end if
      if (x == 0) return
    end do
  end function cpp_r_strncmp
  recursive function cpp_r_memcmp(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    integer(4) :: zres
    integer(8) :: i
    integer(4) :: x, y
    zres = 0
    do i = 0, a3 - 1
      x = crt_ub(a1, i)
      y = crt_ub(a2, i)
      if (x /= y) then
        zres = x - y
        return
      end if
    end do
  end function cpp_r_memcmp
  !> strchr: the first byte equal to (char)c (the NUL itself for c = 0), or a null pointer
  recursive function cpp_r_strchr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_cptr) :: zres
    integer(8) :: i, n
    integer(1) :: ch
    zres = cpp_cptr()
    if (.not. associated(a1%b)) return
    ch = crt_i1(int(a2, 8))
    n = size(a1%b%a, kind=8)
    i = a1%o
    do while (i < n)
      if (a1%b%a(i) == ch) then
        zres%b => a1%b
        zres%o = int(i, 4)
        return
      end if
      if (a1%b%a(i) == 0) return
      i = i + 1
    end do
  end function cpp_r_strchr
  recursive function cpp_r_strrchr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_cptr) :: zres
    integer(8) :: i, n
    integer(1) :: ch
    zres = cpp_cptr()
    if (.not. associated(a1%b)) return
    ch = crt_i1(int(a2, 8))
    n = size(a1%b%a, kind=8)
    i = a1%o
    do while (i < n)
      if (a1%b%a(i) == ch) then
        zres%b => a1%b
        zres%o = int(i, 4)
      end if
      if (a1%b%a(i) == 0) return
      i = i + 1
    end do
  end function cpp_r_strrchr
  !> strstr: the first occurrence of a2 in a1 (a1 itself for an empty a2), or a null pointer
  recursive function cpp_r_strstr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    type(cpp_cptr) :: zres
    integer(8) :: nl, i, j
    zres = cpp_cptr()
    nl = cpp_r_strlen(a2)
    if (nl == 0) then
      zres = a1
      return
    end if
    i = 0
    do while (crt_ub(a1, i) /= 0)
      j = 0
      do while (j < nl)
        if (crt_ub(a1, i + j) /= crt_ub(a2, j)) exit
        j = j + 1
      end do
      if (j == nl) then
        zres%b => a1%b
        zres%o = a1%o + int(i, 4)
        return
      end if
      i = i + 1
    end do
  end function cpp_r_strstr
  !> strncpy: up to n bytes of s, then zeros up to n
  recursive function cpp_r_strncpy(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8), value :: a3
    type(cpp_cptr) :: zres
    integer(8) :: i, hi
    zres = a1
    if (.not. associated(a1%b)) return
    hi = size(a1%b%a, kind=8) - 1
    i = 0
    do while (i < a3)
      if (crt_ub(a2, i) == 0) exit
      if (a1%o + i > hi) return
      a1%b%a(a1%o + i) = a2%b%a(a2%o + i)
      i = i + 1
    end do
    do while (i < a3)
      if (a1%o + i > hi) return
      a1%b%a(a1%o + i) = 0
      i = i + 1
    end do
  end function cpp_r_strncpy
  !> strtok: the next token of s (or of the string the last call left off in, when s is null), NUL-ending it
  recursive function cpp_r_strtok(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    type(cpp_cptr) :: zres
    type(cpp_cptr) :: p
    zres = cpp_cptr()
    if (associated(a1%b)) crt_toknext = a1
    if (.not. associated(crt_toknext%b)) return
    p = crt_toknext
    do while (crt_ub(p, 0_8) /= 0 .and. crt_inset(crt_ub(p, 0_8), a2))
      p%o = p%o + 1
    end do
    if (crt_ub(p, 0_8) == 0) then
      crt_toknext = cpp_cptr()
      return
    end if
    zres = p
    do while (crt_ub(p, 0_8) /= 0 .and. .not. crt_inset(crt_ub(p, 0_8), a2))
      p%o = p%o + 1
    end do
    if (crt_ub(p, 0_8) /= 0) then
      p%b%a(p%o) = 0
      crt_toknext = p
      crt_toknext%o = p%o + 1
    else
      crt_toknext = cpp_cptr()
    end if
  end function cpp_r_strtok

  ! ============================================================================================== R: ctype (C locale)
  recursive function cpp_r_isalnum(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
    zres = merge(1, 0, cpp_r_isdigit(a1) /= 0 .or. cpp_r_isalpha(a1) /= 0)
  end function cpp_r_isalnum
  recursive function cpp_r_isalpha(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
    zres = merge(1, 0, (a1 >= 97 .and. a1 <= 122) .or. (a1 >= 65 .and. a1 <= 90))
  end function cpp_r_isalpha
  recursive function cpp_r_isdigit(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
    zres = merge(1, 0, a1 >= 48 .and. a1 <= 57)
  end function cpp_r_isdigit
  recursive function cpp_r_isspace(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
    zres = merge(1, 0, a1 == 32 .or. (a1 >= 9 .and. a1 <= 13))
  end function cpp_r_isspace
  recursive function cpp_r_tolower(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
    zres = a1
    if (a1 >= 65 .and. a1 <= 90) zres = a1 + 32
  end function cpp_r_tolower
  recursive function cpp_r_toupper(a1) result(zres)
    integer(4), value :: a1
    integer(4) :: zres
    zres = a1
    if (a1 >= 97 .and. a1 <= 122) zres = a1 - 32
  end function cpp_r_toupper

  ! ============================================================================================== R: numbers from text
  recursive function cpp_r_strtod_cptr(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    real(8) :: zres
    type(cpp_cptr) :: e
    zres = cpp_r_strtod_cptr_cptrr(a1, e)
  end function cpp_r_strtod_cptr
  !> glibc's strtod; the end is s itself when nothing converts
  recursive function cpp_r_strtod_cptr_cptrr(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(inout) :: a2
    real(8) :: zres
    integer(8) :: bits, n
    zres = 0.0_8
    a2 = a1
    if (.not. associated(a1%b)) return
    call crt_strtod(a1%b%a, int(a1%o, 8), .false., bits, n)
    zres = transfer(bits, zres)
    a2%o = a1%o + int(n, 4)
  end function cpp_r_strtod_cptr_cptrr
  recursive function cpp_r_atof(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    real(8) :: zres
    zres = cpp_r_strtod_cptr(a1)
  end function cpp_r_atof
  !> atoi: (int) strtol(s, NULL, 10) (the low 32 bits of the clamped long)
  recursive function cpp_r_atoi(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4) :: zres
    type(cpp_cptr) :: e
    zres = int(crt_low32(cpp_r_strtol(a1, e, 10)), 4)
  end function cpp_r_atoi
  recursive function cpp_r_atol(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8) :: zres
    type(cpp_cptr) :: e
    zres = cpp_r_strtol(a1, e, 10)
  end function cpp_r_atol
  recursive function cpp_r_strtol0(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    integer(8) :: zres
    type(cpp_cptr) :: e
    zres = cpp_r_strtol(a1, e, a2)
  end function cpp_r_strtol0
  !> glibc's strtol: optional white space and sign, the digits of base b (0: by the prefix, 0x / 0 / decimal; 16
  !> takes a 0x prefix), clamped to the long range with every digit read; a2, the end (s when nothing converts).
  !> For base 10, the only base the engine passes, this is also the C# runtime's strtol.
  recursive function cpp_r_strtol(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(inout) :: a2
    integer(4), value :: a3
    integer(8) :: zres
    integer(8) :: i, st, lim, v
    integer(4) :: c, d, base
    logical :: neg, ovf
    zres = 0
    a2 = a1
    if (.not. associated(a1%b)) return
    base = a3
    if (base /= 0 .and. (base < 2 .or. base > 36)) return
    i = 0
    do while (cpp_r_isspace(crt_ub(a1, i)) /= 0)
      i = i + 1
    end do
    neg = .false.
    c = crt_ub(a1, i)
    if (c == 45 .or. c == 43) then
      neg = c == 45
      i = i + 1
    end if
    if ((base == 0 .or. base == 16) .and. crt_ub(a1, i) == 48 .and. (crt_ub(a1, i + 1) == 120 .or. crt_ub(a1, i + 1) == 88)) then
      if (crt_digit(crt_ub(a1, i + 2)) < 16) then
        i = i + 2
        base = 16
      else
        ! "0x" with no hexadecimal digit: the 0 is the number, the end is at the x
        a2%o = a1%o + int(i + 1, 4)
        return
      end if
    else if (base == 0) then
      if (crt_ub(a1, i) == 48) then
        base = 8
      else
        base = 10
      end if
    end if
    st = i
    v = 0
    ovf = .false.
    if (neg) then
      lim = -huge(1_8) - 1_8
    else
      lim = huge(1_8)
    end if
    do
      d = crt_digit(crt_ub(a1, i))
      if (d >= base) exit
      if (.not. ovf) then
        if (neg) then
          if (v < (lim + d) / base) then
            ovf = .true.
          else
            v = v * base - d
          end if
        else
          if (v > (lim - d) / base) then
            ovf = .true.
          else
            v = v * base + d
          end if
        end if
      end if
      i = i + 1
    end do
    if (i == st) return
    a2%o = a1%o + int(i, 4)
    if (ovf) then
      zres = lim
    else
      zres = v
    end if
  end function cpp_r_strtol

  ! ============================================================================================== R: printf, sscanf
  !> fprintf: glibc's formatting; the number of bytes, or -1 for a null stream
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
    type(crt_arg) :: ar(40)
    integer :: na, nout
    na = 0
    if (.not. present(v1)) goto 900
    call crt_cls(v1, ar(1), 1)
    na = 1
    if (.not. present(v2)) goto 900
    call crt_cls(v2, ar(2), 2)
    na = 2
    if (.not. present(v3)) goto 900
    call crt_cls(v3, ar(3), 3)
    na = 3
    if (.not. present(v4)) goto 900
    call crt_cls(v4, ar(4), 4)
    na = 4
    if (.not. present(v5)) goto 900
    call crt_cls(v5, ar(5), 5)
    na = 5
    if (.not. present(v6)) goto 900
    call crt_cls(v6, ar(6), 6)
    na = 6
    if (.not. present(v7)) goto 900
    call crt_cls(v7, ar(7), 7)
    na = 7
    if (.not. present(v8)) goto 900
    call crt_cls(v8, ar(8), 8)
    na = 8
    if (.not. present(v9)) goto 900
    call crt_cls(v9, ar(9), 9)
    na = 9
    if (.not. present(v10)) goto 900
    call crt_cls(v10, ar(10), 10)
    na = 10
    if (.not. present(v11)) goto 900
    call crt_cls(v11, ar(11), 11)
    na = 11
    if (.not. present(v12)) goto 900
    call crt_cls(v12, ar(12), 12)
    na = 12
    if (.not. present(v13)) goto 900
    call crt_cls(v13, ar(13), 13)
    na = 13
    if (.not. present(v14)) goto 900
    call crt_cls(v14, ar(14), 14)
    na = 14
    if (.not. present(v15)) goto 900
    call crt_cls(v15, ar(15), 15)
    na = 15
    if (.not. present(v16)) goto 900
    call crt_cls(v16, ar(16), 16)
    na = 16
    if (.not. present(v17)) goto 900
    call crt_cls(v17, ar(17), 17)
    na = 17
    if (.not. present(v18)) goto 900
    call crt_cls(v18, ar(18), 18)
    na = 18
    if (.not. present(v19)) goto 900
    call crt_cls(v19, ar(19), 19)
    na = 19
    if (.not. present(v20)) goto 900
    call crt_cls(v20, ar(20), 20)
    na = 20
    if (.not. present(v21)) goto 900
    call crt_cls(v21, ar(21), 21)
    na = 21
    if (.not. present(v22)) goto 900
    call crt_cls(v22, ar(22), 22)
    na = 22
    if (.not. present(v23)) goto 900
    call crt_cls(v23, ar(23), 23)
    na = 23
    if (.not. present(v24)) goto 900
    call crt_cls(v24, ar(24), 24)
    na = 24
    if (.not. present(v25)) goto 900
    call crt_cls(v25, ar(25), 25)
    na = 25
    if (.not. present(v26)) goto 900
    call crt_cls(v26, ar(26), 26)
    na = 26
    if (.not. present(v27)) goto 900
    call crt_cls(v27, ar(27), 27)
    na = 27
    if (.not. present(v28)) goto 900
    call crt_cls(v28, ar(28), 28)
    na = 28
    if (.not. present(v29)) goto 900
    call crt_cls(v29, ar(29), 29)
    na = 29
    if (.not. present(v30)) goto 900
    call crt_cls(v30, ar(30), 30)
    na = 30
    if (.not. present(v31)) goto 900
    call crt_cls(v31, ar(31), 31)
    na = 31
    if (.not. present(v32)) goto 900
    call crt_cls(v32, ar(32), 32)
    na = 32
    if (.not. present(v33)) goto 900
    call crt_cls(v33, ar(33), 33)
    na = 33
    if (.not. present(v34)) goto 900
    call crt_cls(v34, ar(34), 34)
    na = 34
    if (.not. present(v35)) goto 900
    call crt_cls(v35, ar(35), 35)
    na = 35
    if (.not. present(v36)) goto 900
    call crt_cls(v36, ar(36), 36)
    na = 36
    if (.not. present(v37)) goto 900
    call crt_cls(v37, ar(37), 37)
    na = 37
    if (.not. present(v38)) goto 900
    call crt_cls(v38, ar(38), 38)
    na = 38
    if (.not. present(v39)) goto 900
    call crt_cls(v39, ar(39), 39)
    na = 39
    if (.not. present(v40)) goto 900
    call crt_cls(v40, ar(40), 40)
    na = 40
900 continue
    nout = 0
    if (associated(a2%b)) call crt_format(a2%b%a, int(a2%o, 8), ar, na, crt_out, nout)
    if (.not. associated(a1)) then
      zres = -1
      return
    end if
    if (nout > 0) call crt_write(a1, crt_out, int(nout, 8))
    zres = nout
  end function cpp_r_fprintf
  !> snprintf: glibc's formatting, at most n - 1 bytes and a NUL into the buffer (no more than it holds); the
  !> length of the whole output
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
    type(crt_arg) :: ar(40)
    integer :: na, nout
    integer(8) :: m
    na = 0
    if (.not. present(v1)) goto 900
    call crt_cls(v1, ar(1), 1)
    na = 1
    if (.not. present(v2)) goto 900
    call crt_cls(v2, ar(2), 2)
    na = 2
    if (.not. present(v3)) goto 900
    call crt_cls(v3, ar(3), 3)
    na = 3
    if (.not. present(v4)) goto 900
    call crt_cls(v4, ar(4), 4)
    na = 4
    if (.not. present(v5)) goto 900
    call crt_cls(v5, ar(5), 5)
    na = 5
    if (.not. present(v6)) goto 900
    call crt_cls(v6, ar(6), 6)
    na = 6
    if (.not. present(v7)) goto 900
    call crt_cls(v7, ar(7), 7)
    na = 7
    if (.not. present(v8)) goto 900
    call crt_cls(v8, ar(8), 8)
    na = 8
    if (.not. present(v9)) goto 900
    call crt_cls(v9, ar(9), 9)
    na = 9
    if (.not. present(v10)) goto 900
    call crt_cls(v10, ar(10), 10)
    na = 10
    if (.not. present(v11)) goto 900
    call crt_cls(v11, ar(11), 11)
    na = 11
    if (.not. present(v12)) goto 900
    call crt_cls(v12, ar(12), 12)
    na = 12
    if (.not. present(v13)) goto 900
    call crt_cls(v13, ar(13), 13)
    na = 13
    if (.not. present(v14)) goto 900
    call crt_cls(v14, ar(14), 14)
    na = 14
    if (.not. present(v15)) goto 900
    call crt_cls(v15, ar(15), 15)
    na = 15
    if (.not. present(v16)) goto 900
    call crt_cls(v16, ar(16), 16)
    na = 16
    if (.not. present(v17)) goto 900
    call crt_cls(v17, ar(17), 17)
    na = 17
    if (.not. present(v18)) goto 900
    call crt_cls(v18, ar(18), 18)
    na = 18
    if (.not. present(v19)) goto 900
    call crt_cls(v19, ar(19), 19)
    na = 19
    if (.not. present(v20)) goto 900
    call crt_cls(v20, ar(20), 20)
    na = 20
    if (.not. present(v21)) goto 900
    call crt_cls(v21, ar(21), 21)
    na = 21
    if (.not. present(v22)) goto 900
    call crt_cls(v22, ar(22), 22)
    na = 22
    if (.not. present(v23)) goto 900
    call crt_cls(v23, ar(23), 23)
    na = 23
    if (.not. present(v24)) goto 900
    call crt_cls(v24, ar(24), 24)
    na = 24
    if (.not. present(v25)) goto 900
    call crt_cls(v25, ar(25), 25)
    na = 25
    if (.not. present(v26)) goto 900
    call crt_cls(v26, ar(26), 26)
    na = 26
    if (.not. present(v27)) goto 900
    call crt_cls(v27, ar(27), 27)
    na = 27
    if (.not. present(v28)) goto 900
    call crt_cls(v28, ar(28), 28)
    na = 28
    if (.not. present(v29)) goto 900
    call crt_cls(v29, ar(29), 29)
    na = 29
    if (.not. present(v30)) goto 900
    call crt_cls(v30, ar(30), 30)
    na = 30
    if (.not. present(v31)) goto 900
    call crt_cls(v31, ar(31), 31)
    na = 31
    if (.not. present(v32)) goto 900
    call crt_cls(v32, ar(32), 32)
    na = 32
    if (.not. present(v33)) goto 900
    call crt_cls(v33, ar(33), 33)
    na = 33
    if (.not. present(v34)) goto 900
    call crt_cls(v34, ar(34), 34)
    na = 34
    if (.not. present(v35)) goto 900
    call crt_cls(v35, ar(35), 35)
    na = 35
    if (.not. present(v36)) goto 900
    call crt_cls(v36, ar(36), 36)
    na = 36
    if (.not. present(v37)) goto 900
    call crt_cls(v37, ar(37), 37)
    na = 37
    if (.not. present(v38)) goto 900
    call crt_cls(v38, ar(38), 38)
    na = 38
    if (.not. present(v39)) goto 900
    call crt_cls(v39, ar(39), 39)
    na = 39
    if (.not. present(v40)) goto 900
    call crt_cls(v40, ar(40), 40)
    na = 40
900 continue
    nout = 0
    if (associated(a3%b)) call crt_format(a3%b%a, int(a3%o, 8), ar, na, crt_out, nout)
    zres = nout
    if (a2 == 0 .or. .not. associated(a1%b)) return
    m = min(int(nout, 8), a2 - 1)
    if (a2 < 0) m = nout
    m = min(m, size(a1%b%a, kind=8) - a1%o - 1)
    if (m < 0) return
    if (m > 0) a1%b%a(a1%o:a1%o+m-1) = crt_out(1:m)
    a1%b%a(a1%o + m) = 0
  end function cpp_r_snprintf_cptr_ul_cptr_oa
  !> the bytes printf writes for the format and the arguments (no NUL): for part A's to_string and part D's
  !> streams (C#'s R.Format)
  recursive function cpp_r_format(fmt, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40) result(zres)
    type(cpp_cptr), intent(in) :: fmt
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
    integer(1), allocatable :: zres(:)
    type(crt_arg) :: ar(40)
    integer :: na, nout
    na = 0
    if (.not. present(v1)) goto 900
    call crt_cls(v1, ar(1), 1)
    na = 1
    if (.not. present(v2)) goto 900
    call crt_cls(v2, ar(2), 2)
    na = 2
    if (.not. present(v3)) goto 900
    call crt_cls(v3, ar(3), 3)
    na = 3
    if (.not. present(v4)) goto 900
    call crt_cls(v4, ar(4), 4)
    na = 4
    if (.not. present(v5)) goto 900
    call crt_cls(v5, ar(5), 5)
    na = 5
    if (.not. present(v6)) goto 900
    call crt_cls(v6, ar(6), 6)
    na = 6
    if (.not. present(v7)) goto 900
    call crt_cls(v7, ar(7), 7)
    na = 7
    if (.not. present(v8)) goto 900
    call crt_cls(v8, ar(8), 8)
    na = 8
    if (.not. present(v9)) goto 900
    call crt_cls(v9, ar(9), 9)
    na = 9
    if (.not. present(v10)) goto 900
    call crt_cls(v10, ar(10), 10)
    na = 10
    if (.not. present(v11)) goto 900
    call crt_cls(v11, ar(11), 11)
    na = 11
    if (.not. present(v12)) goto 900
    call crt_cls(v12, ar(12), 12)
    na = 12
    if (.not. present(v13)) goto 900
    call crt_cls(v13, ar(13), 13)
    na = 13
    if (.not. present(v14)) goto 900
    call crt_cls(v14, ar(14), 14)
    na = 14
    if (.not. present(v15)) goto 900
    call crt_cls(v15, ar(15), 15)
    na = 15
    if (.not. present(v16)) goto 900
    call crt_cls(v16, ar(16), 16)
    na = 16
    if (.not. present(v17)) goto 900
    call crt_cls(v17, ar(17), 17)
    na = 17
    if (.not. present(v18)) goto 900
    call crt_cls(v18, ar(18), 18)
    na = 18
    if (.not. present(v19)) goto 900
    call crt_cls(v19, ar(19), 19)
    na = 19
    if (.not. present(v20)) goto 900
    call crt_cls(v20, ar(20), 20)
    na = 20
    if (.not. present(v21)) goto 900
    call crt_cls(v21, ar(21), 21)
    na = 21
    if (.not. present(v22)) goto 900
    call crt_cls(v22, ar(22), 22)
    na = 22
    if (.not. present(v23)) goto 900
    call crt_cls(v23, ar(23), 23)
    na = 23
    if (.not. present(v24)) goto 900
    call crt_cls(v24, ar(24), 24)
    na = 24
    if (.not. present(v25)) goto 900
    call crt_cls(v25, ar(25), 25)
    na = 25
    if (.not. present(v26)) goto 900
    call crt_cls(v26, ar(26), 26)
    na = 26
    if (.not. present(v27)) goto 900
    call crt_cls(v27, ar(27), 27)
    na = 27
    if (.not. present(v28)) goto 900
    call crt_cls(v28, ar(28), 28)
    na = 28
    if (.not. present(v29)) goto 900
    call crt_cls(v29, ar(29), 29)
    na = 29
    if (.not. present(v30)) goto 900
    call crt_cls(v30, ar(30), 30)
    na = 30
    if (.not. present(v31)) goto 900
    call crt_cls(v31, ar(31), 31)
    na = 31
    if (.not. present(v32)) goto 900
    call crt_cls(v32, ar(32), 32)
    na = 32
    if (.not. present(v33)) goto 900
    call crt_cls(v33, ar(33), 33)
    na = 33
    if (.not. present(v34)) goto 900
    call crt_cls(v34, ar(34), 34)
    na = 34
    if (.not. present(v35)) goto 900
    call crt_cls(v35, ar(35), 35)
    na = 35
    if (.not. present(v36)) goto 900
    call crt_cls(v36, ar(36), 36)
    na = 36
    if (.not. present(v37)) goto 900
    call crt_cls(v37, ar(37), 37)
    na = 37
    if (.not. present(v38)) goto 900
    call crt_cls(v38, ar(38), 38)
    na = 38
    if (.not. present(v39)) goto 900
    call crt_cls(v39, ar(39), 39)
    na = 39
    if (.not. present(v40)) goto 900
    call crt_cls(v40, ar(40), 40)
    na = 40
900 continue
    nout = 0
    if (associated(fmt%b)) call crt_format(fmt%b%a, int(fmt%o, 8), ar, na, crt_out, nout)
    allocate(zres(nout))
    if (nout > 0) zres = crt_out(1:nout)
  end function cpp_r_format
  !> sscanf: glibc's vfscanf; the targets are RefI / RefL / RefD / RefF setters, CPtr buffers and R.Slot (whose
  !> values R.Back takes); the number of assignments, or -1 (EOF) for an input failure before the first
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
    type(crt_tgt) :: tg(40)
    integer :: nt
    nt = 0
    if (.not. present(v1)) goto 900
    call crt_tcls(v1, tg(1))
    nt = 1
    if (.not. present(v2)) goto 900
    call crt_tcls(v2, tg(2))
    nt = 2
    if (.not. present(v3)) goto 900
    call crt_tcls(v3, tg(3))
    nt = 3
    if (.not. present(v4)) goto 900
    call crt_tcls(v4, tg(4))
    nt = 4
    if (.not. present(v5)) goto 900
    call crt_tcls(v5, tg(5))
    nt = 5
    if (.not. present(v6)) goto 900
    call crt_tcls(v6, tg(6))
    nt = 6
    if (.not. present(v7)) goto 900
    call crt_tcls(v7, tg(7))
    nt = 7
    if (.not. present(v8)) goto 900
    call crt_tcls(v8, tg(8))
    nt = 8
    if (.not. present(v9)) goto 900
    call crt_tcls(v9, tg(9))
    nt = 9
    if (.not. present(v10)) goto 900
    call crt_tcls(v10, tg(10))
    nt = 10
    if (.not. present(v11)) goto 900
    call crt_tcls(v11, tg(11))
    nt = 11
    if (.not. present(v12)) goto 900
    call crt_tcls(v12, tg(12))
    nt = 12
    if (.not. present(v13)) goto 900
    call crt_tcls(v13, tg(13))
    nt = 13
    if (.not. present(v14)) goto 900
    call crt_tcls(v14, tg(14))
    nt = 14
    if (.not. present(v15)) goto 900
    call crt_tcls(v15, tg(15))
    nt = 15
    if (.not. present(v16)) goto 900
    call crt_tcls(v16, tg(16))
    nt = 16
    if (.not. present(v17)) goto 900
    call crt_tcls(v17, tg(17))
    nt = 17
    if (.not. present(v18)) goto 900
    call crt_tcls(v18, tg(18))
    nt = 18
    if (.not. present(v19)) goto 900
    call crt_tcls(v19, tg(19))
    nt = 19
    if (.not. present(v20)) goto 900
    call crt_tcls(v20, tg(20))
    nt = 20
    if (.not. present(v21)) goto 900
    call crt_tcls(v21, tg(21))
    nt = 21
    if (.not. present(v22)) goto 900
    call crt_tcls(v22, tg(22))
    nt = 22
    if (.not. present(v23)) goto 900
    call crt_tcls(v23, tg(23))
    nt = 23
    if (.not. present(v24)) goto 900
    call crt_tcls(v24, tg(24))
    nt = 24
    if (.not. present(v25)) goto 900
    call crt_tcls(v25, tg(25))
    nt = 25
    if (.not. present(v26)) goto 900
    call crt_tcls(v26, tg(26))
    nt = 26
    if (.not. present(v27)) goto 900
    call crt_tcls(v27, tg(27))
    nt = 27
    if (.not. present(v28)) goto 900
    call crt_tcls(v28, tg(28))
    nt = 28
    if (.not. present(v29)) goto 900
    call crt_tcls(v29, tg(29))
    nt = 29
    if (.not. present(v30)) goto 900
    call crt_tcls(v30, tg(30))
    nt = 30
    if (.not. present(v31)) goto 900
    call crt_tcls(v31, tg(31))
    nt = 31
    if (.not. present(v32)) goto 900
    call crt_tcls(v32, tg(32))
    nt = 32
    if (.not. present(v33)) goto 900
    call crt_tcls(v33, tg(33))
    nt = 33
    if (.not. present(v34)) goto 900
    call crt_tcls(v34, tg(34))
    nt = 34
    if (.not. present(v35)) goto 900
    call crt_tcls(v35, tg(35))
    nt = 35
    if (.not. present(v36)) goto 900
    call crt_tcls(v36, tg(36))
    nt = 36
    if (.not. present(v37)) goto 900
    call crt_tcls(v37, tg(37))
    nt = 37
    if (.not. present(v38)) goto 900
    call crt_tcls(v38, tg(38))
    nt = 38
    if (.not. present(v39)) goto 900
    call crt_tcls(v39, tg(39))
    nt = 39
    if (.not. present(v40)) goto 900
    call crt_tcls(v40, tg(40))
    nt = 40
900 continue
    crt_stn = 0
    zres = -1
    if (.not. associated(a1%b)) return
    zres = 0
    if (.not. associated(a2%b)) return
    zres = crt_scan(a1%b%a, int(a1%o, 8), a2%b%a, int(a2%o, 8), tg, nt)
  end function cpp_r_sscanf

  !> sscanf targets that are lvalues: their setters
  recursive function cpp_r_refd(a1) result(zres)
    class(cpp_action_d), pointer, intent(in) :: a1
    class(cpp_refd), pointer :: zres
    allocate(zres)
    zres%set => a1
  end function cpp_r_refd
  recursive function cpp_r_reff(a1) result(zres)
    class(cpp_action_f), pointer, intent(in) :: a1
    class(cpp_reff), pointer :: zres
    allocate(zres)
    zres%set => a1
  end function cpp_r_reff
  recursive function cpp_r_refi(a1) result(zres)
    class(cpp_action_i), pointer, intent(in) :: a1
    class(cpp_refi), pointer :: zres
    allocate(zres)
    zres%set => a1
  end function cpp_r_refi
  recursive function cpp_r_refl(a1) result(zres)
    class(cpp_action_l), pointer, intent(in) :: a1
    class(cpp_refl), pointer :: zres
    allocate(zres)
    zres%set => a1
  end function cpp_r_refl
  !> R.Back(n, ref a): copy the first stashed value (an R.Slot target of the sscanf just run) into a; n
  recursive function cpp_r_back_i_t1r__b(a1, a2) result(zres)
    integer(4), value :: a1
    integer(1), intent(inout) :: a2
    integer(4) :: zres
    integer(8) :: v
    if (crt_take(1, v)) a2 = crt_i1(v)
    zres = a1
  end function cpp_r_back_i_t1r__b
  recursive function cpp_r_back_i_t1r_t2r__lb(a1, a2, a3) result(zres)
    integer(4), value :: a1
    integer(8), intent(inout) :: a2
    integer(1), intent(inout) :: a3
    integer(4) :: zres
    integer(8) :: v
    if (crt_take(1, v)) a2 = v
    if (crt_take(2, v)) a3 = crt_i1(v)
    zres = a1
  end function cpp_r_back_i_t1r_t2r__lb

  ! ============================================================================================== R: files
  !> fopen: glibc's, with the same mode string; null when it fails. A directory opened for reading opens, as glibc
  !> opens it, and every read then fails (fgets null, ferror set, feof not)
  recursive function cpp_r_fopen(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    class(cpp_cfile), pointer :: zres
    type(c_ptr) :: fp
    zres => null()
    if (.not. associated(a1%b) .or. .not. associated(a2%b)) return
    fp = crt_c_fopen(crt_cz(a1), crt_cz(a2))
    if (.not. c_associated(fp)) return
    allocate(zres)
    zres%fp = fp
  end function cpp_r_fopen
  !> fclose: -1 for a null stream; the standard streams are not closed (C# flushes them)
  recursive function cpp_r_fclose(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = -1
    if (.not. associated(a1)) return
    zres = 0
    if (c_associated(a1%fp)) then
      zres = crt_c_fclose(a1%fp)
      a1%fp = c_null_ptr
    end if
  end function cpp_r_fclose
  !> fflush; fflush(NULL) flushes every stream, as glibc does
  recursive function cpp_r_fflush(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = 0
    if (.not. associated(a1)) then
      zres = crt_c_fflush(c_null_ptr)
    else if (c_associated(a1%fp)) then
      zres = crt_c_fflush(a1%fp)
    end if
  end function cpp_r_fflush
  recursive function cpp_r_feof(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = 0
    if (.not. associated(a1)) return
    if (c_associated(a1%fp)) zres = merge(1, 0, crt_c_feof(a1%fp) /= 0)
  end function cpp_r_feof
  !> ferror: glibc's error indicator (set by a read of a directory)
  recursive function cpp_r_ferror(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = 0
    if (.not. associated(a1)) return
    if (c_associated(a1%fp)) zres = merge(1, 0, crt_c_ferror(a1%fp) /= 0)
  end function cpp_r_ferror
  !> fileno: 3 (as the C# runtime; the engine only passes it on)
  recursive function cpp_r_fileno(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = 3
  end function cpp_r_fileno
  !> setvbuf: 0, buffering unchanged (as the C# runtime)
  recursive function cpp_r_setvbuf(a1, a2, a3, a4) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4), value :: a3
    integer(8), value :: a4
    integer(4) :: zres
    zres = 0
  end function cpp_r_setvbuf
  recursive function cpp_r_fgetc(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = -1
    if (.not. associated(a1)) return
    if (c_associated(a1%fp)) zres = crt_c_fgetc(a1%fp)
  end function cpp_r_fgetc
  !> fgets: glibc's (at most n - 1 bytes, no more than the buffer holds, up to and with a newline); null at the end
  recursive function cpp_r_fgets(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    class(cpp_cfile), pointer, intent(in) :: a3
    type(cpp_cptr) :: zres
    integer(4) :: n
    type(c_ptr) :: r
    zres = cpp_cptr()
    if (.not. associated(a3) .or. .not. associated(a1%b)) return
    if (.not. c_associated(a3%fp)) return
    n = int(min(int(a2, 8), size(a1%b%a, kind=8) - a1%o), 4)
    if (n <= 0) return
    r = crt_c_fgets(c_loc(a1%b%a(a1%o)), int(n, c_int), a3%fp)
    if (c_associated(r)) zres = a1
  end function cpp_r_fgets
  recursive function cpp_r_fseek_cfile_l_i(a1, a2, a3) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(4), value :: a3
    integer(4) :: zres
    zres = -1
    if (.not. associated(a1)) return
    if (c_associated(a1%fp)) zres = crt_c_fseek(a1%fp, int(a2, c_long), int(a3, c_int))
  end function cpp_r_fseek_cfile_l_i
  recursive function cpp_r_ftell(a1) result(zres)
    class(cpp_cfile), pointer, intent(in) :: a1
    integer(8) :: zres
    zres = -1
    if (.not. associated(a1)) return
    if (c_associated(a1%fp)) zres = crt_c_ftell(a1%fp)
  end function cpp_r_ftell
  recursive subroutine cpp_r_rewind(a1)
    class(cpp_cfile), pointer, intent(in) :: a1
    if (.not. associated(a1)) return
    if (c_associated(a1%fp)) call crt_c_rewind(a1%fp)
  end subroutine cpp_r_rewind
  !> fread of one value (x86's little-endian bytes): 1, or 0 at the end of the file (the value unchanged)
  recursive function cpp_r_freadd1(a1, a2) result(zres)
    real(8), intent(inout) :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
    integer(1) :: b(8)
    zres = 0
    if (crt_read(a2, b, 8_8) /= 8) return
    a1 = transfer(b, a1)
    zres = 1
  end function cpp_r_freadd1
  recursive function cpp_r_freadf1(a1, a2) result(zres)
    real(4), intent(inout) :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
    integer(1) :: b(4)
    zres = 0
    if (crt_read(a2, b, 4_8) /= 4) return
    a1 = transfer(b, a1)
    zres = 1
  end function cpp_r_freadf1
  recursive function cpp_r_freadi1(a1, a2) result(zres)
    integer(4), intent(inout) :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
    integer(1) :: b(4)
    zres = 0
    if (crt_read(a2, b, 4_8) /= 4) return
    a1 = transfer(b, a1)
    zres = 1
  end function cpp_r_freadi1
  !> fwrite of one value: 1
  recursive function cpp_r_fwrited1(a1, a2) result(zres)
    real(8), value :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
    integer(1) :: b(8)
    b = transfer(a1, b)
    call crt_write(a2, b, 8_8)
    zres = 1
  end function cpp_r_fwrited1
  recursive function cpp_r_fwritef1(a1, a2) result(zres)
    real(4), value :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
    integer(1) :: b(4)
    b = transfer(a1, b)
    call crt_write(a2, b, 4_8)
    zres = 1
  end function cpp_r_fwritef1
  recursive function cpp_r_fwritei1(a1, a2) result(zres)
    integer(4), value :: a1
    class(cpp_cfile), pointer, intent(in) :: a2
    integer(8) :: zres
    integer(1) :: b(4)
    b = transfer(a1, b)
    call crt_write(a2, b, 4_8)
    zres = 1
  end function cpp_r_fwritei1

  ! ============================================================================================== R: time, environment
  !> ctime(&t): glibc's ctime_r ("Www Mmm dd hh:mm:ss yyyy\n" in the local time zone) in a new buffer; null when
  !> glibc cannot convert t
  recursive function cpp_r_ctime_ptrl(a1) result(zres)
    type(cpp_ptr_l), intent(in) :: a1
    type(cpp_cptr) :: zres
    integer(8), pointer :: tp
    integer(c_long) :: t
    character(kind=c_char) :: buf(64)
    type(c_ptr) :: r
    integer :: n
    zres = cpp_cptr()
    tp => cpp_ptr_l_item_i(a1, 0)
    if (.not. associated(tp)) return
    t = int(tp, c_long)
    buf = c_null_char
    r = crt_c_ctime_r(t, buf)
    if (.not. c_associated(r)) return
    n = 0
    do while (n < 63)
      if (buf(n + 1) == c_null_char) exit
      n = n + 1
    end do
    zres = cpp_r_buf_i(n + 1)
    if (n > 0) zres%b%a(0:n-1) = transfer(buf(1:n), zres%b%a(0:n-1))
  end function cpp_r_ctime_ptrl
  recursive function cpp_r_difftime(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    real(8) :: zres
    zres = real(a1 - a2, 8)
  end function cpp_r_difftime
  !> getenv: a new copy of the value, or a null pointer
  recursive function cpp_r_getenv(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr) :: zres
    type(c_ptr) :: r
    integer(c_size_t) :: n
    character(kind=c_char), pointer :: s(:)
    zres = cpp_cptr()
    if (.not. associated(a1%b)) return
    r = crt_c_getenv(crt_cz(a1))
    if (.not. c_associated(r)) return
    n = crt_c_strlen(r)
    zres = cpp_r_buf_i(int(n, 4) + 1)
    if (n > 0) then
      call c_f_pointer(r, s, [n])
      zres%b%a(0:n-1) = transfer(s, zres%b%a(0:n-1))
    end if
  end function cpp_r_getenv

  ! ============================================================================================== Std
  !> call_once: run f the first time only (an exception leaves the flag unset)
  recursive subroutine cpp_std_call_once(a1, a2)
    class(cpp_onceflag), pointer, intent(in) :: a1
    class(cpp_action), pointer, intent(in) :: a2
    if (a1%done) return
    call a2%invoke()
    if (associated(cpp_exc)) return
    a1%done = .true.
  end subroutine cpp_std_call_once
  !> std::from_chars for double (chars_format::general), libstdc++'s: strtod's value on the same characters, but a
  !> sign other than '-', leading white space and a hexadecimal prefix are not read ("0x10" is 0, ending at the x),
  !> and a value too large or too small for a double is result_out_of_range (34), the value unchanged
  recursive function cpp_std_from_chars_cptr_cptr_dr(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    real(8), intent(inout) :: a3
    type(cpp_fromcharsresult) :: zres
    integer(1), allocatable :: t(:)
    integer(8) :: n, k, e, j, bits
    integer(4) :: c, lc, d
    real(8) :: r
    zres%ptr = a1
    zres%ec = 22
    n = crt_span(a1, a2)
    allocate(t(0:n))
    if (n > 0) t(0:n-1) = a1%b%a(a1%o:a1%o+n-1)
    t(n) = 0
    k = 0
    if (n > 0) then
      if (t(0) == 45) k = 1
    end if
    c = iand(int(t(k), 4), 255)
    lc = c
    if (c >= 65 .and. c <= 90) lc = c + 32
    if (.not. ((c >= 48 .and. c <= 57) .or. c == 46 .or. lc == 105 .or. lc == 110)) return
    if (c == 48 .and. k + 1 < n) then
      if (t(k + 1) == 120 .or. t(k + 1) == 88) t(k + 1) = 0     ! read the 0 alone
    end if
    call crt_strtod(t, 0_8, .false., bits, e)
    if (e <= 0) return
    r = transfer(bits, r)
    zres%ptr%o = a1%o + int(e, 4)
    if (r - r /= 0.0_8 .and. r == r .and. lc /= 105) then        ! overflow (not "inf")
      zres%ec = 34
      return
    end if
    if (r == 0.0_8) then                                         ! underflow: a nonzero digit before the exponent
      do j = k, e - 1
        d = iand(int(t(j), 4), 255)
        if (d == 101 .or. d == 69) exit
        if (d >= 49 .and. d <= 57) then
          zres%ec = 34
          return
        end if
      end do
    end if
    a3 = r
    zres%ec = 0
  end function cpp_std_from_chars_cptr_cptr_dr
  !> std::from_chars for int, base 10: an optional '-', digits; nothing is invalid_argument (22, ptr = first), a
  !> value out of range result_out_of_range (34, every digit read, the value unchanged)
  recursive function cpp_std_from_chars_cptr_cptr_ir(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4), intent(inout) :: a3
    type(cpp_fromcharsresult) :: zres
    integer(8) :: v
    logical :: ok
    zres = crt_int_chars(a1, a2, .true., -2147483648_8, 2147483647_8, v, ok)
    if (ok) a3 = int(v, 4)
  end function cpp_std_from_chars_cptr_cptr_ir
  !> std::from_chars for unsigned int (the bits in an int)
  recursive function cpp_std_from_chars_cptr_cptr_ur(a1, a2, a3) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(4), intent(inout) :: a3
    type(cpp_fromcharsresult) :: zres
    integer(8) :: v
    logical :: ok
    zres = crt_int_chars(a1, a2, .false., 0_8, 4294967295_8, v, ok)
    if (ok) a3 = int(crt_low32(v), 4)
  end function cpp_std_from_chars_cptr_cptr_ur
  !> std::get<0> / get<1> of a pair (structured bindings): a reference to the element (its box, or the slot of an
  !> erased element)
  recursive function cpp_std_get0_pairab__id(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    integer(4), pointer :: zres
    zres => null()
    if (.not. associated(a1%first%p)) return
    select type (p => a1%first%p)
    type is (integer(4))
      zres => p
    end select
  end function cpp_std_get0_pairab__id
  recursive function cpp_std_get0_pairab__ii(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    integer(4), pointer :: zres
    zres => null()
    if (.not. associated(a1%first%p)) return
    select type (p => a1%first%p)
    type is (integer(4))
      zres => p
    end select
  end function cpp_std_get0_pairab__ii
  recursive function cpp_std_get0_pairab__io(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(4), pointer :: zres
    zres => null()
    if (.not. associated(a1%first%p)) return
    select type (p => a1%first%p)
    type is (integer(4))
      zres => p
    end select
  end function cpp_std_get0_pairab__io
  recursive function cpp_std_get0_pairab__lo(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(8), pointer :: zres
    zres => null()
    if (.not. associated(a1%first%p)) return
    select type (p => a1%first%p)
    type is (integer(8))
      zres => p
    end select
  end function cpp_std_get0_pairab__lo
  recursive function cpp_std_get0_pairab__od(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
    zres => a1%first
  end function cpp_std_get0_pairab__od
  recursive function cpp_std_get0_pairab__ol(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
    zres => a1%first
  end function cpp_std_get0_pairab__ol
  recursive function cpp_std_get0_pairab__oo(a1, mk2, cm3, mk4, cm5) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_slot), pointer :: zres
    zres => a1%first
  end function cpp_std_get0_pairab__oo
  recursive function cpp_std_get0_pairab__os(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
    zres => a1%first
  end function cpp_std_get0_pairab__os
  recursive function cpp_std_get0_pairab__oz(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
    zres => a1%first
  end function cpp_std_get0_pairab__oz
  recursive function cpp_std_get1_pairab__id(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    real(8), pointer :: zres
    zres => null()
    if (.not. associated(a1%second%p)) return
    select type (p => a1%second%p)
    type is (real(8))
      zres => p
    end select
  end function cpp_std_get1_pairab__id
  recursive function cpp_std_get1_pairab__ii(a1) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    integer(4), pointer :: zres
    zres => null()
    if (.not. associated(a1%second%p)) return
    select type (p => a1%second%p)
    type is (integer(4))
      zres => p
    end select
  end function cpp_std_get1_pairab__ii
  recursive function cpp_std_get1_pairab__io(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
    zres => a1%second
  end function cpp_std_get1_pairab__io
  recursive function cpp_std_get1_pairab__lo(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    type(cpp_slot), pointer :: zres
    zres => a1%second
  end function cpp_std_get1_pairab__lo
  recursive function cpp_std_get1_pairab__od(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    real(8), pointer :: zres
    zres => null()
    if (.not. associated(a1%second%p)) return
    select type (p => a1%second%p)
    type is (real(8))
      zres => p
    end select
  end function cpp_std_get1_pairab__od
  recursive function cpp_std_get1_pairab__ol(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(8), pointer :: zres
    zres => null()
    if (.not. associated(a1%second%p)) return
    select type (p => a1%second%p)
    type is (integer(8))
      zres => p
    end select
  end function cpp_std_get1_pairab__ol
  recursive function cpp_std_get1_pairab__oo(a1, mk2, cm3, mk4, cm5) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_slot), pointer :: zres
    zres => a1%second
  end function cpp_std_get1_pairab__oo
  recursive function cpp_std_get1_pairab__os(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    integer(2), pointer :: zres
    zres => null()
    if (.not. associated(a1%second%p)) return
    select type (p => a1%second%p)
    type is (integer(2))
      zres => p
    end select
  end function cpp_std_get1_pairab__os
  recursive function cpp_std_get1_pairab__oz(a1, mk2, cm3) result(zres)
    class(cpp_pair), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    logical, pointer :: zres
    zres => null()
    if (.not. associated(a1%second%p)) return
    select type (p => a1%second%p)
    type is (logical)
      zres => p
    end select
  end function cpp_std_get1_pairab__oz
  recursive function cpp_std_nop(a1) result(zres)
    class(*), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = 0
  end function cpp_std_nop
  !> std::rethrow_exception: the exception is pending again
  recursive subroutine cpp_std_rethrow(a1)
    class(cpp_object), pointer, intent(in) :: a1
    cpp_exc => a1
  end subroutine cpp_std_rethrow

  ! ============================================================================================== Sys, exceptions, TupN
  !> std::thread::hardware_concurrency: glibc's get_nprocs (the processors online), 0 when unknown
  recursive function cpp_sys_hardware_concurrency() result(zres)
    integer(4) :: zres
    zres = crt_c_get_nprocs()
    if (zres < 0) zres = 0
  end function cpp_sys_hardware_concurrency
  !> new System.<a1>(a2)
  recursive function cpp_sysexception_new(a1, a2) result(zres)
    character(len=*), intent(in) :: a1
    character(len=*), intent(in) :: a2
    class(cpp_sysexception), pointer :: zres
    allocate(zres)
    zres%name = a1
    zres%message = a2
  end function cpp_sysexception_new
  !> new TupN(): no items (C#'s Array.Empty<object>())
  recursive function cpp_tupn_new_0() result(zres)
    class(cpp_tupn), pointer :: zres
    allocate(zres)
    allocate(zres%v(0))
  end function cpp_tupn_new_0
  !> new TupN(params object[]): the items are the boxes the engine made (kept, not copied)
  recursive function cpp_tupn_new_oa(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40) result(zres)
    class(*), intent(in), target, optional :: v1
    class(*), intent(in), target, optional :: v2
    class(*), intent(in), target, optional :: v3
    class(*), intent(in), target, optional :: v4
    class(*), intent(in), target, optional :: v5
    class(*), intent(in), target, optional :: v6
    class(*), intent(in), target, optional :: v7
    class(*), intent(in), target, optional :: v8
    class(*), intent(in), target, optional :: v9
    class(*), intent(in), target, optional :: v10
    class(*), intent(in), target, optional :: v11
    class(*), intent(in), target, optional :: v12
    class(*), intent(in), target, optional :: v13
    class(*), intent(in), target, optional :: v14
    class(*), intent(in), target, optional :: v15
    class(*), intent(in), target, optional :: v16
    class(*), intent(in), target, optional :: v17
    class(*), intent(in), target, optional :: v18
    class(*), intent(in), target, optional :: v19
    class(*), intent(in), target, optional :: v20
    class(*), intent(in), target, optional :: v21
    class(*), intent(in), target, optional :: v22
    class(*), intent(in), target, optional :: v23
    class(*), intent(in), target, optional :: v24
    class(*), intent(in), target, optional :: v25
    class(*), intent(in), target, optional :: v26
    class(*), intent(in), target, optional :: v27
    class(*), intent(in), target, optional :: v28
    class(*), intent(in), target, optional :: v29
    class(*), intent(in), target, optional :: v30
    class(*), intent(in), target, optional :: v31
    class(*), intent(in), target, optional :: v32
    class(*), intent(in), target, optional :: v33
    class(*), intent(in), target, optional :: v34
    class(*), intent(in), target, optional :: v35
    class(*), intent(in), target, optional :: v36
    class(*), intent(in), target, optional :: v37
    class(*), intent(in), target, optional :: v38
    class(*), intent(in), target, optional :: v39
    class(*), intent(in), target, optional :: v40
    class(cpp_tupn), pointer :: zres
    integer :: n
    allocate(zres)
    allocate(zres%v(40))
    n = 0
    if (.not. present(v1)) goto 900
    zres%v(1)%p => v1
    n = 1
    if (.not. present(v2)) goto 900
    zres%v(2)%p => v2
    n = 2
    if (.not. present(v3)) goto 900
    zres%v(3)%p => v3
    n = 3
    if (.not. present(v4)) goto 900
    zres%v(4)%p => v4
    n = 4
    if (.not. present(v5)) goto 900
    zres%v(5)%p => v5
    n = 5
    if (.not. present(v6)) goto 900
    zres%v(6)%p => v6
    n = 6
    if (.not. present(v7)) goto 900
    zres%v(7)%p => v7
    n = 7
    if (.not. present(v8)) goto 900
    zres%v(8)%p => v8
    n = 8
    if (.not. present(v9)) goto 900
    zres%v(9)%p => v9
    n = 9
    if (.not. present(v10)) goto 900
    zres%v(10)%p => v10
    n = 10
    if (.not. present(v11)) goto 900
    zres%v(11)%p => v11
    n = 11
    if (.not. present(v12)) goto 900
    zres%v(12)%p => v12
    n = 12
    if (.not. present(v13)) goto 900
    zres%v(13)%p => v13
    n = 13
    if (.not. present(v14)) goto 900
    zres%v(14)%p => v14
    n = 14
    if (.not. present(v15)) goto 900
    zres%v(15)%p => v15
    n = 15
    if (.not. present(v16)) goto 900
    zres%v(16)%p => v16
    n = 16
    if (.not. present(v17)) goto 900
    zres%v(17)%p => v17
    n = 17
    if (.not. present(v18)) goto 900
    zres%v(18)%p => v18
    n = 18
    if (.not. present(v19)) goto 900
    zres%v(19)%p => v19
    n = 19
    if (.not. present(v20)) goto 900
    zres%v(20)%p => v20
    n = 20
    if (.not. present(v21)) goto 900
    zres%v(21)%p => v21
    n = 21
    if (.not. present(v22)) goto 900
    zres%v(22)%p => v22
    n = 22
    if (.not. present(v23)) goto 900
    zres%v(23)%p => v23
    n = 23
    if (.not. present(v24)) goto 900
    zres%v(24)%p => v24
    n = 24
    if (.not. present(v25)) goto 900
    zres%v(25)%p => v25
    n = 25
    if (.not. present(v26)) goto 900
    zres%v(26)%p => v26
    n = 26
    if (.not. present(v27)) goto 900
    zres%v(27)%p => v27
    n = 27
    if (.not. present(v28)) goto 900
    zres%v(28)%p => v28
    n = 28
    if (.not. present(v29)) goto 900
    zres%v(29)%p => v29
    n = 29
    if (.not. present(v30)) goto 900
    zres%v(30)%p => v30
    n = 30
    if (.not. present(v31)) goto 900
    zres%v(31)%p => v31
    n = 31
    if (.not. present(v32)) goto 900
    zres%v(32)%p => v32
    n = 32
    if (.not. present(v33)) goto 900
    zres%v(33)%p => v33
    n = 33
    if (.not. present(v34)) goto 900
    zres%v(34)%p => v34
    n = 34
    if (.not. present(v35)) goto 900
    zres%v(35)%p => v35
    n = 35
    if (.not. present(v36)) goto 900
    zres%v(36)%p => v36
    n = 36
    if (.not. present(v37)) goto 900
    zres%v(37)%p => v37
    n = 37
    if (.not. present(v38)) goto 900
    zres%v(38)%p => v38
    n = 38
    if (.not. present(v39)) goto 900
    zres%v(39)%p => v39
    n = 39
    if (.not. present(v40)) goto 900
    zres%v(40)%p => v40
    n = 40
900 continue
    zres%v = zres%v(1:n)
  end function cpp_tupn_new_oa

  ! ============================================================================================== helpers
  !> one printf argument (a present vararg) as a crt_arg record
  recursive subroutine crt_cls(v, r, i)
    class(*), intent(in) :: v
    type(crt_arg), intent(inout) :: r
    integer, intent(in) :: i
    integer :: n
    r%k = 0
    r%iv = 0
    r%rv = 0
    r%sb => null()
    r%so = 0
    r%sn = -1
    select type (v)
    type is (integer(4))
      r%k = 1
      r%iv = v
    type is (integer(8))
      r%k = 1
      r%iv = v
    type is (real(8))
      r%k = 3
      r%rv = v
    type is (cpp_cptr)
      if (associated(v%b)) then
        r%k = 4
        r%sb => v%b%a
        r%so = v%o
      else
        r%k = 5
      end if
    type is (integer(2))
      r%k = 1
      r%iv = v
    type is (integer(1))
      r%k = 1
      r%iv = v
    type is (logical)
      r%k = 1
      r%iv = merge(1_8, 0_8, v)
    type is (real(4))
      r%k = 3
      r%rv = real(v, 8)
    type is (cpp_u8)
      r%k = 2
      r%iv = iand(int(v%v, 8), 255_8)
    type is (cpp_u16)
      r%k = 2
      r%iv = iand(int(v%v, 8), 65535_8)
    type is (cpp_u32)
      r%k = 2
      r%iv = iand(int(v%v, 8), 4294967295_8)
    type is (cpp_u64)
      r%k = 2
      r%iv = v%v
    class is (cpp_str)
      if (associated(v%b)) then
        r%k = 4
        r%sb => v%b%a
        r%so = 0
        r%sn = v%n
      else
        r%k = 5
      end if
    type is (character(*))
      n = len(v)
      if (allocated(crt_cpool(i)%b)) deallocate(crt_cpool(i)%b)
      allocate(crt_cpool(i)%b(0:n))
      if (n > 0) crt_cpool(i)%b(0:n-1) = transfer(v, crt_cpool(i)%b(0:n-1))
      crt_cpool(i)%b(n) = 0
      r%k = 4
      r%sb => crt_cpool(i)%b
      r%so = 0
    end select
  end subroutine crt_cls

  !> one sscanf target (a present vararg) as a crt_tgt record
  recursive subroutine crt_tcls(v, t)
    class(*), intent(in) :: v
    type(crt_tgt), intent(inout) :: t
    t%k = 0
    select type (v)
    class is (cpp_refi)
      if (associated(v%set)) t%k = 1
      t%ai => v%set
    class is (cpp_refl)
      if (associated(v%set)) t%k = 2
      t%al => v%set
    class is (cpp_refd)
      if (associated(v%set)) t%k = 3
      t%ad => v%set
    class is (cpp_reff)
      if (associated(v%set)) t%k = 4
      t%af => v%set
    type is (cpp_cptr)
      t%k = 5
      t%cp = v
    class is (cpp_scanslot)
      t%k = 6
    end select
  end subroutine crt_tcls

  !> sscanf's stash for R.Slot targets (in the order of the targets)
  recursive subroutine crt_stash(k, iv, rv)
    integer, intent(in) :: k
    integer(8), intent(in) :: iv
    real(8), intent(in) :: rv
    if (crt_stn >= crt_nst) return
    crt_stn = crt_stn + 1
    crt_stk(crt_stn) = k
    crt_sti(crt_stn) = iv
    crt_std(crt_stn) = rv
  end subroutine crt_stash
  !> the i-th stashed value as an integer (C#'s Convert.ChangeType: a floating value rounded half to even),
  !> false when the sscanf did not assign that many slot targets
  recursive function crt_take(i, v) result(ok)
    integer, intent(in) :: i
    integer(8), intent(out) :: v
    logical :: ok
    real(8) :: r, f
    v = 0
    ok = i <= crt_stn
    if (.not. ok) return
    select case (crt_stk(i))
    case (4, 5)
      r = crt_std(i)
      f = crt_m_floor(r)
      if (r - f > 0.5_8 .or. (r - f == 0.5_8 .and. mod(f, 2.0_8) /= 0.0_8)) f = f + 1.0_8
      v = cpp_conv_d2l(f)
    case default
      v = crt_sti(i)
    end select
  end function crt_take

  !> the low byte of v as a signed char
  recursive pure function crt_i1(v) result(r)
    integer(8), intent(in) :: v
    integer(1) :: r
    integer(8) :: w
    w = iand(v, 255_8)
    if (w > 127) w = w - 256
    r = int(w, 1)
  end function crt_i1
  !> the low 32 bits of v, sign-extended
  recursive pure function crt_low32(v) result(r)
    integer(8), intent(in) :: v
    integer(8) :: r
    r = iand(v, 4294967295_8)
    if (r > 2147483647_8) r = r - 4294967296_8
  end function crt_low32
  !> the unsigned byte p[i] (0 past either end of the array or for a null pointer)
  recursive function crt_ub(p, i) result(r)
    type(cpp_cptr), intent(in) :: p
    integer(8), intent(in) :: i
    integer(4) :: r
    integer(8) :: j
    r = 0
    if (.not. associated(p%b)) return
    j = p%o + i
    if (j < 0 .or. j >= size(p%b%a, kind=8)) return
    r = iand(int(p%b%a(j), 4), 255)
  end function crt_ub
  !> whether the byte c is one of the C string set's
  recursive function crt_inset(c, set) result(r)
    integer(4), intent(in) :: c
    type(cpp_cptr), intent(in) :: set
    logical :: r
    integer(8) :: j
    integer(4) :: s
    r = .false.
    j = 0
    do
      s = crt_ub(set, j)
      if (s == 0) return
      if (s == c) exit
      j = j + 1
    end do
    r = .true.
  end function crt_inset
  !> a digit's value in bases up to 36 (99 for anything else)
  recursive pure function crt_digit(c) result(d)
    integer(4), intent(in) :: c
    integer(4) :: d
    if (c >= 48 .and. c <= 57) then
      d = c - 48
    else if (c >= 97 .and. c <= 122) then
      d = c - 87
    else if (c >= 65 .and. c <= 90) then
      d = c - 55
    else
      d = 99
    end if
  end function crt_digit
  !> the C string p as a Fortran string with a NUL after it (for glibc's file and environment functions)
  recursive function crt_cz(p) result(s)
    type(cpp_cptr), intent(in) :: p
    character(len=:), allocatable :: s
    integer(8) :: n
    n = cpp_r_strlen(p)
    allocate(character(len=n + 1) :: s)
    if (n > 0) s(1:n) = transfer(p%b%a(p%o:p%o+n-1), s(1:n))
    s(n+1:n+1) = c_null_char
  end function crt_cz
  !> the C string p as a Fortran string
  recursive function crt_fstr(p) result(s)
    type(cpp_cptr), intent(in) :: p
    character(len=:), allocatable :: s
    integer(8) :: n
    n = cpp_r_strlen(p)
    allocate(character(len=n) :: s)
    if (n > 0) s = transfer(p%b%a(p%o:p%o+n-1), s)
  end function crt_fstr
  !> the number of bytes from first to last (0 if they are not in one array or last is before first)
  recursive function crt_span(first, last) result(n)
    type(cpp_cptr), intent(in) :: first, last
    integer(8) :: n
    n = 0
    if (.not. associated(first%b)) return
    n = max(0_8, min(int(last%o, 8), size(first%b%a, kind=8)) - first%o)
  end function crt_span
  !> std::from_chars of a base-10 integer between lo and hi (signed: an optional '-')
  recursive function crt_int_chars(first, last, signed, lo, hi, v, ok) result(res)
    type(cpp_cptr), intent(in) :: first, last
    logical, intent(in) :: signed
    integer(8), intent(in) :: lo, hi
    integer(8), intent(out) :: v
    logical, intent(out) :: ok
    type(cpp_fromcharsresult) :: res
    integer(8) :: n, i, st
    integer(4) :: c
    logical :: neg, big
    ok = .false.
    v = 0
    res%ptr = first
    res%ec = 22
    n = crt_span(first, last)
    i = 0
    neg = .false.
    if (signed .and. n > 0) then
      if (first%b%a(first%o) == 45) then
        neg = .true.
        i = 1
      end if
    end if
    st = i
    big = .false.
    do while (i < n)
      c = crt_ub(first, i)
      if (c < 48 .or. c > 57) exit
      if (.not. big) then
        if (v > (4294967295_8 * 4_8)) then      ! far past either range: stop accumulating
          big = .true.
        else
          v = v * 10 + (c - 48)
        end if
      end if
      i = i + 1
    end do
    if (i == st) return
    res%ptr%o = first%o + int(i, 4)
    if (neg) v = -v
    if (big .or. v < lo .or. v > hi) then
      res%ec = 34
      v = 0
      return
    end if
    res%ec = 0
    ok = .true.
  end function crt_int_chars

  !> read up to n bytes from the stream into b: the number read (glibc's fread; nothing from the standard streams)
  recursive function crt_read(f, b, n) result(got)
    class(cpp_cfile), pointer, intent(in) :: f
    integer(1), intent(inout), target, contiguous :: b(:)
    integer(8), intent(in) :: n
    integer(8) :: got
    got = 0
    if (.not. associated(f) .or. n <= 0) return
    if (.not. c_associated(f%fp)) return
    got = int(crt_c_fread(c_loc(b(1)), 1_c_size_t, int(n, c_size_t), f%fp), 8)
  end function crt_read
  !> write the n bytes b(1:n) to the stream: stdout_ and stderr_ at once with write(2), a file through glibc's stdio
  recursive subroutine crt_write(f, b, n)
    class(cpp_cfile), pointer, intent(in) :: f
    integer(1), intent(in), target, contiguous :: b(:)
    integer(8), intent(in) :: n
    integer(c_size_t) :: r
    if (.not. associated(f) .or. n <= 0) return
    if (associated(f, crt_out_obj)) then
      call cpp_rt_c_write_fd(1, b, n)
    else if (associated(f, crt_err_obj)) then
      call cpp_rt_c_write_fd(2, b, n)
    else if (c_associated(f%fp)) then
      r = crt_c_fwrite(c_loc(b(1)), 1_c_size_t, int(n, c_size_t), f%fp)
    end if
  end subroutine crt_write
  !> write the n bytes b(1:n) to the file descriptor fd with write(2), unbuffered (for the standard streams; part D's
  !> cout / cerr can use it so that their output and printf's interleave as in .NET, whose console streams do not
  !> buffer)
  recursive subroutine cpp_rt_c_write_fd(fd, b, n)
    integer(4), intent(in) :: fd
    integer(1), intent(in), target, contiguous :: b(:)
    integer(8), intent(in) :: n
    integer(8) :: done
    integer(c_intptr_t) :: r
    done = 0
    do while (done < n)
      r = crt_c_write(int(fd, c_int), c_loc(b(done + 1)), int(n - done, c_size_t))
      if (r <= 0) return
      done = done + int(r, 8)
    end do
  end subroutine cpp_rt_c_write_fd
  recursive subroutine crt_write_str(fd, s)
    integer(4), intent(in) :: fd
    character(len=*), intent(in) :: s
    integer(1), allocatable :: b(:)
    if (len(s) == 0) return
    allocate(b(len(s)))
    b = transfer(s, b)
    call cpp_rt_c_write_fd(fd, b, int(len(s), 8))
  end subroutine crt_write_str
  !> what C's exit() does to open streams: flush every one (the standard streams are not buffered here)
  recursive subroutine cpp_r_flushall()
    integer(c_int) :: r
    r = crt_c_fflush(c_null_ptr)
  end subroutine cpp_r_flushall

  !> the first nb bytes of the elements p[0], p[1], ... (x86's little-endian layout; a bool is one byte, 0 or 1)
  !> into buf(0:nb-1), and back: through part A's cpp_ptr_<c>_item_i, so the field form of a Ptr works too
  recursive subroutine crt_getb_b(p, nb, buf)
    type(cpp_ptr_b), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(inout) :: buf(0:)
    integer(1), pointer :: e
    integer(8) :: k
    do k = 0, nb - 1
      e => cpp_ptr_b_item_i(p, int(k, 4))
      buf(k) = e
    end do
  end subroutine crt_getb_b
  recursive subroutine crt_putb_b(p, nb, buf)
    type(cpp_ptr_b), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(in) :: buf(0:)
    integer(1), pointer :: e
    integer(8) :: k
    do k = 0, nb - 1
      e => cpp_ptr_b_item_i(p, int(k, 4))
      e = buf(k)
    end do
  end subroutine crt_putb_b
  recursive subroutine crt_getb_d(p, nb, buf)
    type(cpp_ptr_d), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(inout) :: buf(0:)
    real(8), pointer :: e
    integer(1) :: img(8)
    integer(8) :: k, m
    do k = 0, (nb + 7) / 8 - 1
      e => cpp_ptr_d_item_i(p, int(k, 4))
      img = transfer(e, img)
      m = min(8_8, nb - 8 * k)
      buf(8*k:8*k+m-1) = img(1:m)
    end do
  end subroutine crt_getb_d
  recursive subroutine crt_putb_d(p, nb, buf)
    type(cpp_ptr_d), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(in) :: buf(0:)
    real(8), pointer :: e
    integer(1) :: img(8)
    integer(8) :: k, m
    do k = 0, (nb + 7) / 8 - 1
      e => cpp_ptr_d_item_i(p, int(k, 4))
      m = min(8_8, nb - 8 * k)
      if (m < 8) img = transfer(e, img)
      img(1:m) = buf(8*k:8*k+m-1)
      e = transfer(img, e)
    end do
  end subroutine crt_putb_d
  recursive subroutine crt_getb_f(p, nb, buf)
    type(cpp_ptr_f), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(inout) :: buf(0:)
    real(4), pointer :: e
    integer(1) :: img(4)
    integer(8) :: k, m
    do k = 0, (nb + 3) / 4 - 1
      e => cpp_ptr_f_item_i(p, int(k, 4))
      img = transfer(e, img)
      m = min(4_8, nb - 4 * k)
      buf(4*k:4*k+m-1) = img(1:m)
    end do
  end subroutine crt_getb_f
  recursive subroutine crt_putb_f(p, nb, buf)
    type(cpp_ptr_f), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(in) :: buf(0:)
    real(4), pointer :: e
    integer(1) :: img(4)
    integer(8) :: k, m
    do k = 0, (nb + 3) / 4 - 1
      e => cpp_ptr_f_item_i(p, int(k, 4))
      m = min(4_8, nb - 4 * k)
      if (m < 4) img = transfer(e, img)
      img(1:m) = buf(4*k:4*k+m-1)
      e = transfer(img, e)
    end do
  end subroutine crt_putb_f
  recursive subroutine crt_getb_i(p, nb, buf)
    type(cpp_ptr_i), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(inout) :: buf(0:)
    integer(4), pointer :: e
    integer(1) :: img(4)
    integer(8) :: k, m
    do k = 0, (nb + 3) / 4 - 1
      e => cpp_ptr_i_item_i(p, int(k, 4))
      img = transfer(e, img)
      m = min(4_8, nb - 4 * k)
      buf(4*k:4*k+m-1) = img(1:m)
    end do
  end subroutine crt_getb_i
  recursive subroutine crt_putb_i(p, nb, buf)
    type(cpp_ptr_i), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(in) :: buf(0:)
    integer(4), pointer :: e
    integer(1) :: img(4)
    integer(8) :: k, m
    do k = 0, (nb + 3) / 4 - 1
      e => cpp_ptr_i_item_i(p, int(k, 4))
      m = min(4_8, nb - 4 * k)
      if (m < 4) img = transfer(e, img)
      img(1:m) = buf(4*k:4*k+m-1)
      e = transfer(img, e)
    end do
  end subroutine crt_putb_i
  recursive subroutine crt_getb_l(p, nb, buf)
    type(cpp_ptr_l), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(inout) :: buf(0:)
    integer(8), pointer :: e
    integer(1) :: img(8)
    integer(8) :: k, m
    do k = 0, (nb + 7) / 8 - 1
      e => cpp_ptr_l_item_i(p, int(k, 4))
      img = transfer(e, img)
      m = min(8_8, nb - 8 * k)
      buf(8*k:8*k+m-1) = img(1:m)
    end do
  end subroutine crt_getb_l
  recursive subroutine crt_putb_l(p, nb, buf)
    type(cpp_ptr_l), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(in) :: buf(0:)
    integer(8), pointer :: e
    integer(1) :: img(8)
    integer(8) :: k, m
    do k = 0, (nb + 7) / 8 - 1
      e => cpp_ptr_l_item_i(p, int(k, 4))
      m = min(8_8, nb - 8 * k)
      if (m < 8) img = transfer(e, img)
      img(1:m) = buf(8*k:8*k+m-1)
      e = transfer(img, e)
    end do
  end subroutine crt_putb_l
  recursive subroutine crt_getb_s(p, nb, buf)
    type(cpp_ptr_s), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(inout) :: buf(0:)
    integer(2), pointer :: e
    integer(1) :: img(2)
    integer(8) :: k, m
    do k = 0, (nb + 1) / 2 - 1
      e => cpp_ptr_s_item_i(p, int(k, 4))
      img = transfer(e, img)
      m = min(2_8, nb - 2 * k)
      buf(2*k:2*k+m-1) = img(1:m)
    end do
  end subroutine crt_getb_s
  recursive subroutine crt_putb_s(p, nb, buf)
    type(cpp_ptr_s), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(in) :: buf(0:)
    integer(2), pointer :: e
    integer(1) :: img(2)
    integer(8) :: k, m
    do k = 0, (nb + 1) / 2 - 1
      e => cpp_ptr_s_item_i(p, int(k, 4))
      m = min(2_8, nb - 2 * k)
      if (m < 2) img = transfer(e, img)
      img(1:m) = buf(2*k:2*k+m-1)
      e = transfer(img, e)
    end do
  end subroutine crt_putb_s
  recursive subroutine crt_getb_z(p, nb, buf)
    type(cpp_ptr_z), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(inout) :: buf(0:)
    logical, pointer :: e
    integer(8) :: k
    do k = 0, nb - 1
      e => cpp_ptr_z_item_i(p, int(k, 4))
      buf(k) = merge(1_1, 0_1, e)
    end do
  end subroutine crt_getb_z
  recursive subroutine crt_putb_z(p, nb, buf)
    type(cpp_ptr_z), intent(in) :: p
    integer(8), intent(in) :: nb
    integer(1), intent(in) :: buf(0:)
    logical, pointer :: e
    integer(8) :: k
    do k = 0, nb - 1
      e => cpp_ptr_z_item_i(p, int(k, 4))
      e = buf(k) /= 0
    end do
  end subroutine crt_putb_z

end module cpp_rt_c
