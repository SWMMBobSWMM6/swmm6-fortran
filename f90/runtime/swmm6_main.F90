! swmm6_main.F90 - the SWMM6 command line (src/cli/main.cpp) for the Fortran engine, a port of cs/runtime/Program.cs
! (as ts/src/main.ts and py/runswmm6.py are): the same calls into the engine's C API (the _global._F.swmm_* functions,
! p__global__f__swmm_* in f90/gen) in the same order, the same messages on stdout, the same exit code, and R.FlushAll
! before exit (returning from main calls exit(), which flushes every open FILE).
! What the C# gets from .NET is made explicit:
!   - the messages are written to part C's C stdout (the C# writes Encoding.Latin1 bytes to R.stdout_'s stream), so
!     they keep their order with the engine's own printf output;
!   - the command-line arguments are .NET strings (UTF-8, an invalid sequence replaced by U+FFFD), handed to the
!     engine as R.Lit makes them (the low byte of each UTF-16 unit) and echoed as Encoding.Latin1 writes them ('?'
!     above U+00FF): part D's cpp_net_* helpers;
!   - {1:F2} of the elapsed seconds is .NET Core's: the exact value rounded half away from zero to two places (the
!     RC edit descriptor); the clock is the wall clock (DateTime.UtcNow);
!   - an exception that escapes the engine (the pending exception still set after an API call) ends the process as
!     .NET's unhandled-exception handler does: "Unhandled exception. ..." on stderr, no flushing of the C files, and
!     exit code 134 (SIGABRT's);
!   - the exit code is the int Main returns, as Linux keeps it (its low 8 bits).
! cpp_rt_d_init (part D's static fields) and swmm6_engine_init (the engine's) run first.
! Built by f90/build.sh with -cpp; -DHAVE_FLUSHALL when part C has cpp_r_flushall (C#'s R.FlushAll); without it the
! runner flushes part C's stdout and stderr only.
! Usage: swmm6 <input.inp> <report.rpt> [output.out]   (f90/runswmm6 is the wrapper the gate runs)
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
program swmm6_main
  use, intrinsic :: iso_c_binding, only: c_int, c_size_t, c_long, c_int8_t
  use cpp_runtime
  use swmm6_engine, only: swmm6_engine_init, p__global__f__swmm_engine_create, p__global__f__swmm_engine_open, &
      p__global__f__swmm_engine_initialize, p__global__f__swmm_engine_start, p__global__f__swmm_engine_step, &
      p__global__f__swmm_engine_end, p__global__f__swmm_engine_report, p__global__f__swmm_engine_close, &
      p__global__f__swmm_engine_destroy, p__global__f__swmm_get_last_error_msg
  implicit none

  interface
    subroutine c_exit(code) bind(C, name='exit')
      import :: c_int
      integer(c_int), value :: code
    end subroutine
    subroutine c_quick_exit(code) bind(C, name='_exit')
      import :: c_int
      integer(c_int), value :: code
    end subroutine
    function c_write(fd, buf, n) bind(C, name='write') result(r)
      import :: c_int, c_size_t, c_long, c_int8_t
      integer(c_int), value :: fd
      integer(c_int8_t), intent(in) :: buf(*)
      integer(c_size_t), value :: n
      integer(c_long) :: r
    end function
  end interface

  character(len=*), parameter :: VERSION = '6.0.0-alpha.4'
  character(len=*), parameter :: NL = achar(10)
  integer(4) :: rc

  call cpp_rt_d_init()
  call swmm6_engine_init()
  if (associated(cpp_exc)) call crash()
  rc = run()
  call flush_all()
  call c_exit(int(rc, c_int))

contains

  !> Out(s): s (a .NET string held as UTF-8) as Encoding.Latin1 writes it, to the C stdout.
  subroutine out(s)
    character(len=*), intent(in) :: s
    call out_bytes(cpp_net_latin1(s))
  end subroutine out

  subroutine out_bytes(b)
    character(len=*), intent(in) :: b
    integer(4) :: k
    if (len(b) == 0) return
    k = cpp_r_fprintf(cpp_r_stdout_x, cpp_r_lit('%s'), lit_of(b))
    if (associated(cpp_exc)) call crash()
  end subroutine out_bytes

  !> A fresh NUL-terminated buffer of the bytes b.
  function lit_of(b) result(p)
    character(len=*), intent(in) :: b
    type(cpp_cptr) :: p
    class(cpp_arr_b), pointer :: a
    integer :: i, c
    a => cpp_arr_b_new(int(len(b) + 1, 8))
    do i = 1, len(b)
      c = ichar(b(i:i))
      if (c > 127) c = c - 256
      a%a(i - 1) = int(c, 1)
    end do
    p = cpp_cptr(b=a, o=0)
  end function lit_of

  !> R.Lit(s) of a .NET string held as UTF-8.
  function rlit(s) result(p)
    character(len=*), intent(in) :: s
    type(cpp_cptr) :: p
    p = lit_of(cpp_net_lit_bytes(s))
  end function rlit

  !> R.Str(p) as the bytes Out writes again: the C string's bytes (Latin-1 both ways), as UTF-8 for out().
  function cstr(p) result(s)
    type(cpp_cptr), intent(in) :: p
    character(len=:), allocatable :: s, b
    integer(8) :: i, n
    s = ''
    if (.not. associated(p%b)) return
    n = 0
    do while (p%o + n < size(p%b%a, kind=8))
      if (p%b%a(p%o + n) == 0) exit
      n = n + 1
    end do
    allocate(character(len=n) :: b)
    do i = 1, n
      b(i:i) = char(iand(int(p%b%a(p%o + i - 1)), 255))
    end do
    s = latin1_to_net(b)
  end function cstr

  !> Latin-1 bytes as a .NET string held as UTF-8.
  function latin1_to_net(b) result(s)
    character(len=*), intent(in) :: b
    character(len=:), allocatable :: s
    character(len=2 * len(b)) :: t
    integer :: i, k, c
    k = 0
    do i = 1, len(b)
      c = ichar(b(i:i))
      if (c < 128) then
        k = k + 1
        t(k:k) = b(i:i)
      else
        t(k + 1:k + 1) = char(ior(192, ishft(c, -6)))
        t(k + 2:k + 2) = char(ior(128, iand(c, 63)))
        k = k + 2
      end if
    end do
    s = t(1:k)
  end function latin1_to_net

  !> The i-th command-line argument as a .NET string (UTF-8, invalid sequences replaced).
  function arg(i) result(s)
    integer, intent(in) :: i
    character(len=:), allocatable :: s, raw
    integer :: n
    call get_command_argument(i, length=n)
    allocate(character(len=n) :: raw)
    if (n > 0) call get_command_argument(i, raw)
    s = cpp_net_from_os(raw)
  end function arg

  function dec(v) result(s)
    integer(8), intent(in) :: v
    character(len=:), allocatable :: s
    character(len=24) :: t
    write(t, '(i0)') v
    s = trim(t)
  end function dec

  !> {0:F2} of .NET Core: the exact value rounded half away from zero to two places.
  function f2(x) result(s)
    real(8), intent(in) :: x
    character(len=:), allocatable :: s
    character(len=64) :: t
    write(t, '(RC,F0.2)') x
    s = trim(adjustl(t))
    if (s(1:1) == '.') s = '0' // s
    if (len(s) >= 2) then
      if (s(1:2) == '-.') s = '-0' // s(2:)
    end if
  end function f2

  function now() result(t)
    real(8) :: t
    integer(8) :: c, r
    call system_clock(c, r)
    t = real(c, 8) / real(r, 8)
  end function now

  !> .NET's unhandled-exception handler: the exception on stderr, then abort (no exit(), so no FILE flushing).
  subroutine crash()
    character(len=:), allocatable :: msg
    integer(c_long) :: k
    integer :: i
    integer(c_int8_t), allocatable :: b(:)
    msg = 'Unhandled exception. '
    select type (e => cpp_exc)
    class is (cpp_cppexception)
      msg = msg // 'Cpp exception: ' // cstr(cpp_cppexception_what(e))
    class is (cpp_sysexception)
      msg = msg // 'System.'
      if (allocated(e%name)) msg = msg // e%name
      msg = msg // ': '
      if (allocated(e%message)) msg = msg // e%message
    class default
      msg = msg // 'an exception object'
    end select
    msg = msg // NL // '   (the Fortran engine: the pending exception was set after an API call)' // NL
    allocate(b(len(msg)))
    do i = 1, len(msg)
      b(i) = int(iand(ichar(msg(i:i)), 127), c_int8_t)
    end do
    k = c_write(2_c_int, b, int(size(b), c_size_t))
    call c_quick_exit(134_c_int)
  end subroutine crash

  subroutine flush_all()
    integer(4) :: k
#ifdef HAVE_FLUSHALL
    call cpp_r_flushall()
#else
    k = cpp_r_fflush(cpp_r_stdout_x)
    k = cpp_r_fflush(cpp_r_stderr_x)
#endif
    k = 0
  end subroutine flush_all

  !> The last error message of the engine, as a .NET string.
  function lasterr(engine) result(s)
    class(*), pointer, intent(in) :: engine
    character(len=:), allocatable :: s
    type(cpp_cptr) :: p
    p = p__global__f__swmm_get_last_error_msg(engine)
    if (associated(cpp_exc)) call crash()
    s = cstr(p)
  end function lasterr

  function run() result(res)
    integer(4) :: res
    character(len=:), allocatable :: inp, rpt, outf, a0
    class(*), pointer :: engine
    class(cpp_arr_d), pointer :: elapsed
    integer(4) :: err, save, k
    integer(8) :: steps
    real(8) :: t0
    type(cpp_cptr) :: nullp
    integer :: n

    n = command_argument_count()
    if (n < 1) then
      call out(NL // 'Error: not enough arguments. Use --help for usage.' // NL // NL)
      res = 1
      return
    end if
    a0 = arg(1)
    if (a0 == '--version' .and. len(a0) == 9 .or. a0 == '-v' .and. len(a0) == 2) then
      call out('openswmm.engine ' // VERSION // NL)
      res = 0
      return
    end if
    if (n < 2) then
      call out(NL // 'Error: need at least input and report file paths.' // NL)
      call out('Usage: openswmm <input.inp> <report.rpt> [output.out]' // NL // NL)
      res = 1
      return
    end if
    inp = a0
    rpt = arg(2)
    outf = ''
    if (n > 2) outf = arg(3)
    call out(NL // '... OpenSWMM Engine ' // VERSION // NL // '... Input: ' // inp // NL // '... Report: ' // rpt // &
        NL // '... Output: ' // outf // NL)
    k = cpp_r_fflush(cpp_r_stdout_x)
    if (associated(cpp_exc)) call crash()
    t0 = now()
    engine => p__global__f__swmm_engine_create()
    if (associated(cpp_exc)) call crash()
    if (.not. associated(engine)) then
      call out('Error: failed to create engine instance.' // NL)
      res = 1
      return
    end if
    err = p__global__f__swmm_engine_open(engine, rlit(inp), rlit(rpt), rlit(outf), nullp)
    if (associated(cpp_exc)) call crash()
    if (err /= 0) then
      call out('Error opening input file: ' // lasterr(engine) // NL)
      call p__global__f__swmm_engine_destroy(engine)
      if (associated(cpp_exc)) call crash()
      res = err
      return
    end if
    err = p__global__f__swmm_engine_initialize(engine)
    if (associated(cpp_exc)) call crash()
    if (err /= 0) then
      call out('Error initializing: ' // lasterr(engine) // NL)
      k = p__global__f__swmm_engine_close(engine)
      if (associated(cpp_exc)) call crash()
      call p__global__f__swmm_engine_destroy(engine)
      if (associated(cpp_exc)) call crash()
      res = err
      return
    end if
    save = 0
    if (len(outf) > 0) save = 1
    err = p__global__f__swmm_engine_start(engine, save)
    if (associated(cpp_exc)) call crash()
    if (err /= 0) then
      call out('Error starting simulation: ' // lasterr(engine) // NL)
      k = p__global__f__swmm_engine_close(engine)
      if (associated(cpp_exc)) call crash()
      call p__global__f__swmm_engine_destroy(engine)
      if (associated(cpp_exc)) call crash()
      res = err
      return
    end if
    elapsed => cpp_arr_d_new(1_8)
    steps = 0
    do
      err = p__global__f__swmm_engine_step(engine, cpp_ptr_d_new_ta_l(elapsed, 0_8))
      if (associated(cpp_exc)) call crash()
      if (err /= 0) then
        call out(NL // 'Error at step ' // dec(steps) // ': ' // lasterr(engine) // NL)
        exit
      end if
      if (elapsed%a(0) <= 0.0_8) exit
      steps = steps + 1
    end do
    call out(NL // '... ' // dec(steps) // ' steps completed.' // NL)
    res = err
    k = p__global__f__swmm_engine_end(engine)
    call fin(k, 'ending simulation', engine, res)
    k = p__global__f__swmm_engine_report(engine)
    call fin(k, 'writing report', engine, res)
    k = p__global__f__swmm_engine_close(engine)
    call fin(k, 'closing simulation', engine, res)
    call p__global__f__swmm_engine_destroy(engine)
    if (associated(cpp_exc)) call crash()
    if (res == 0) then
      call out('... OpenSWMM Engine completed in ' // f2(now() - t0) // ' seconds.' // NL // NL)
    else
      call out('... OpenSWMM Engine failed in ' // f2(now() - t0) // ' seconds.' // NL // NL)
    end if
  end function run

  !> Fin(status, phase): a failing phase reports the engine's message and sets the result unless one is set.
  subroutine fin(status, phase, engine, res)
    integer(4), intent(in) :: status
    character(len=*), intent(in) :: phase
    class(*), pointer, intent(in) :: engine
    integer(4), intent(inout) :: res
    if (associated(cpp_exc)) call crash()
    if (status /= 0) then
      call out('Error ' // phase // ': ' // lasterr(engine) // NL)
      if (res == 0) res = status
    end if
  end subroutine fin

end program swmm6_main
