! cpp_rt_c_fmt.f90 - submodule fmt of part C of the Fortran runtime (module cpp_rt_c): the glibc-exact engines
! behind the printf family, sscanf and strtod. The algorithms are the SWMM5 Fortran port's (copied from
! /home/claude/swmm5-ports/f90/runtime/crt_format.f90, which passed 480/480 against EPA SWMM 5.2.4): printf's
! floating output from the exact decimal expansion of the binary value (big integers in base 1e9) rounded half to
! even on it, as glibc 2.39 does; %a / %A as glibc's printf_fphex; integers taken at the size their length
! modifier says; strtod correctly rounded (Clinger's AlgorithmR over big integers), with hexadecimal floats,
! inf / infinity and nan / nan(n-char-sequence) with its payload; sscanf following glibc's vfscanf, %f into a
! float rounded once (strtof), the EOF rule, %n.
! Changed for SWMM6: the arguments come pre-classified as crt_arg records and the sscanf targets as crt_tgt records
! (made by the parent module from the engine's class(*) varargs: integers, reals, logicals, cpp_u8..cpp_u64,
! CPtr / Str strings; RefI / RefL / RefD / RefF setters, CPtr buffers, R.Slot), and sscanf gained glibc's %[ scan
! sets (the SWMM5 one treated %[ as a matching failure). Nothing here calls libc.
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
submodule (cpp_rt_c) fmt
  use, intrinsic :: iso_fortran_env, only: int8, int16, int32, int64, real32, real64
  implicit none

  integer, parameter :: xp = selected_real_kind(18, 4900)   ! x87 extended on x86-64
  integer(int64), parameter :: BB = 1000000000_int64         ! big-integer limb base
  integer, parameter :: EOFC = -1
  integer(int64), parameter :: MASK32 = 4294967295_int64
  integer(int64), parameter :: TWO31 = 2147483648_int64
  integer(int64), parameter :: TWO32 = 4294967296_int64
  integer(int64), parameter :: TWO52 = 4503599627370496_int64
  integer(int64), parameter :: TWO53 = 9007199254740992_int64
  integer(int64), parameter :: SIGNBIT = -huge(1_int64) - 1_int64
  integer, parameter :: MAXSIG = 800      ! significant decimal digits kept by strtod (+1 sticky)
  integer, parameter :: MAXL = 400        ! limbs for strtod comparisons (needs < 100)
  integer, parameter :: PMAXL = 100       ! limbs for printf expansions (needs <= 86)
  integer, parameter :: PDIG = 900        ! digit buffer for printf (needs <= 767)
  integer(int64), parameter :: POW5(0:13) = [1_int64, 5_int64, 25_int64, 125_int64, 625_int64, &
       3125_int64, 15625_int64, 78125_int64, 390625_int64, 1953125_int64, 9765625_int64, &
       48828125_int64, 244140625_int64, 1220703125_int64]
  real(real64), parameter :: P10D(0:22) = [1.0e0_real64, 1.0e1_real64, 1.0e2_real64, &
       1.0e3_real64, 1.0e4_real64, 1.0e5_real64, 1.0e6_real64, 1.0e7_real64, 1.0e8_real64, &
       1.0e9_real64, 1.0e10_real64, 1.0e11_real64, 1.0e12_real64, 1.0e13_real64, &
       1.0e14_real64, 1.0e15_real64, 1.0e16_real64, 1.0e17_real64, 1.0e18_real64, &
       1.0e19_real64, 1.0e20_real64, 1.0e21_real64, 1.0e22_real64]
  real(real32), parameter :: P10F(0:10) = [1.0e0_real32, 1.0e1_real32, 1.0e2_real32, &
       1.0e3_real32, 1.0e4_real32, 1.0e5_real32, 1.0e6_real32, 1.0e7_real32, 1.0e8_real32, &
       1.0e9_real32, 1.0e10_real32]

  ! scanf length flags
  integer, parameter :: F_LONG = 1, F_LONGDBL = 2, F_SHORT = 4, F_CHAR = 8

  integer(int8), allocatable, save :: wb(:)              ! body of the conversion being built

contains

  ! ===================================================================================
  !  small character helpers (codes are unsigned bytes 0..255, EOFC = -1)
  ! ===================================================================================
  recursive pure logical function isspace(c)
    integer, intent(in) :: c
    isspace = c == 32 .or. (c >= 9 .and. c <= 13)
  end function isspace

  recursive pure logical function isdig(c)
    integer, intent(in) :: c
    isdig = c >= 48 .and. c <= 57
  end function isdig

  recursive pure logical function isxdig(c)
    integer, intent(in) :: c
    isxdig = (c >= 48 .and. c <= 57) .or. (c >= 65 .and. c <= 70) .or. (c >= 97 .and. c <= 102)
  end function isxdig

  recursive pure logical function isalnum(c)
    integer, intent(in) :: c
    isalnum = (c >= 48 .and. c <= 57) .or. (c >= 65 .and. c <= 90) .or. (c >= 97 .and. c <= 122)
  end function isalnum

  recursive pure integer function lower(c)
    integer, intent(in) :: c
    if (c >= 65 .and. c <= 90) then
       lower = c + 32
    else
       lower = c
    end if
  end function lower

  recursive pure integer function hexval(c)
    integer, intent(in) :: c
    if (c <= 57) then
       hexval = c - 48
    else
       hexval = lower(c) - 87
    end if
  end function hexval

  !> signed value of the low 32 / 16 / 8 bits
  recursive pure integer(int64) function sext32(v)
    integer(int64), intent(in) :: v
    sext32 = iand(v, MASK32)
    if (sext32 >= TWO31) sext32 = sext32 - TWO32
  end function sext32

  recursive pure integer(int64) function sext16(v)
    integer(int64), intent(in) :: v
    sext16 = iand(v, 65535_int64)
    if (sext16 >= 32768_int64) sext16 = sext16 - 65536_int64
  end function sext16

  recursive pure integer(int64) function sext8(v)
    integer(int64), intent(in) :: v
    sext8 = iand(v, 255_int64)
    if (sext8 >= 128_int64) sext8 = sext8 - 256_int64
  end function sext8

  recursive pure integer(int8) function byte(c)
    integer, intent(in) :: c
    integer :: w
    w = iand(c, 255)
    if (w > 127) w = w - 256
    byte = int(w, int8)
  end function byte

  ! ===================================================================================
  !  buffers

  recursive subroutine grow(out, need)
    integer(int8), allocatable, intent(inout) :: out(:)
    integer, intent(in) :: need
    integer(int8), allocatable :: tmp(:)
    integer :: ns
    if (.not. allocated(out)) then
       allocate(out(max(256, need)))
       return
    end if
    if (size(out) >= need) return
    ns = max(2*size(out), need + 256)
    allocate(tmp(ns))
    tmp(1:size(out)) = out
    call move_alloc(tmp, out)
  end subroutine grow

  recursive subroutine wbres(n)
    integer, intent(in) :: n
    integer(int8), allocatable :: tmp(:)
    if (.not. allocated(wb)) then
       allocate(wb(max(512, n)))
    else if (size(wb) < n) then
       allocate(tmp(max(2*size(wb), n)))
       tmp(1:size(wb)) = wb
       call move_alloc(tmp, wb)
    end if
  end subroutine wbres

  !> [spaces] pre(1:npre) '0'*nz wb(1:nbody) [spaces], padded with spaces to width
  recursive subroutine emit_field(out, nout, pre, npre, nz, nbody, width, left)
    integer(int8), allocatable, intent(inout) :: out(:)
    integer, intent(inout) :: nout
    integer(int8), intent(in) :: pre(:)
    integer, intent(in) :: npre, nz, nbody, width
    logical, intent(in) :: left
    integer :: tot, pad
    tot = npre + nz + nbody
    pad = max(width - tot, 0)
    call grow(out, nout + tot + pad)
    if (.not. left .and. pad > 0) then
       out(nout+1:nout+pad) = 32_int8
       nout = nout + pad
    end if
    if (npre > 0) then
       out(nout+1:nout+npre) = pre(1:npre)
       nout = nout + npre
    end if
    if (nz > 0) then
       out(nout+1:nout+nz) = 48_int8
       nout = nout + nz
    end if
    if (nbody > 0) then
       out(nout+1:nout+nbody) = wb(1:nbody)
       nout = nout + nbody
    end if
    if (left .and. pad > 0) then
       out(nout+1:nout+pad) = 32_int8
       nout = nout + pad
    end if
  end subroutine emit_field

  ! ===================================================================================
  ! ===================================================================================
  recursive subroutine mul_small(L, n, f)
    integer(int64), intent(inout) :: L(:)
    integer, intent(inout) :: n
    integer(int64), intent(in) :: f       ! f <= 2**31
    integer(int64) :: carry, t
    integer :: i
    carry = 0
    do i = 1, n
       t = L(i)*f + carry
       carry = t / BB
       L(i) = t - carry*BB
    end do
    do while (carry > 0)
       if (n >= size(L)) error stop 'crt_format: big integer overflow'
       n = n + 1
       L(n) = mod(carry, BB)
       carry = carry / BB
    end do
  end subroutine mul_small

  recursive subroutine mul_pow5(L, n, k)
    integer(int64), intent(inout) :: L(:)
    integer, intent(inout) :: n
    integer, intent(in) :: k
    integer :: r, s
    r = k
    do while (r > 0)
       s = min(r, 13)
       call mul_small(L, n, POW5(s))
       r = r - s
    end do
  end subroutine mul_pow5

  recursive subroutine mul_pow2(L, n, k)
    integer(int64), intent(inout) :: L(:)
    integer, intent(inout) :: n
    integer, intent(in) :: k
    integer :: r, s
    r = k
    do while (r > 0)
       s = min(r, 30)
       call mul_small(L, n, ishft(1_int64, s))
       r = r - s
    end do
  end subroutine mul_pow2

  recursive subroutine set_big(L, n, v)
    integer(int64), intent(out) :: L(:)
    integer, intent(out) :: n
    integer(int64), intent(in) :: v      ! v >= 0
    integer(int64) :: t
    n = 0
    t = v
    do while (t > 0)
       n = n + 1
       L(n) = mod(t, BB)
       t = t / BB
    end do
  end subroutine set_big

  recursive pure integer function cmp_big(A, na, B, nbb)
    integer(int64), intent(in) :: A(:), B(:)
    integer, intent(in) :: na, nbb
    integer :: i
    if (na /= nbb) then
       cmp_big = merge(1, -1, na > nbb)
       return
    end if
    do i = na, 1, -1
       if (A(i) /= B(i)) then
          cmp_big = merge(1, -1, A(i) > B(i))
          return
       end if
    end do
    cmp_big = 0
  end function cmp_big

  ! ===================================================================================
  !  printf: exact decimal expansion of a finite nonzero double
  !  value = 0.dg(1)dg(2)...dg(nd) x 10**dp ; dg(nd) /= 0
  ! ===================================================================================
  recursive subroutine exact_digits(bits, dg, nd, dp)
    integer(int64), intent(in) :: bits
    integer(int8), intent(inout) :: dg(:)
    integer, intent(out) :: nd, dp
    integer(int64) :: m, ex, t, L(PMAXL)
    integer :: e2, n, k, i, j, ndec, ntop
    ex = iand(ishft(bits, -52), 2047_int64)
    m = iand(bits, TWO52 - 1)
    if (ex == 0) then
       e2 = -1074
    else
       m = m + TWO52
       e2 = int(ex) - 1075
    end if
    k = trailz(m)
    m = ishft(m, -k)
    e2 = e2 + k
    call set_big(L, n, m)
    ndec = 0
    if (e2 > 0) then
       call mul_pow2(L, n, e2)
    else if (e2 < 0) then
       ndec = -e2
       call mul_pow5(L, n, ndec)
    end if
    t = L(n)
    ntop = 0
    do while (t > 0)
       ntop = ntop + 1
       t = t / 10
    end do
    nd = ntop + 9*(n - 1)
    t = L(n)
    do i = ntop, 1, -1
       dg(i) = int(mod(t, 10_int64), int8)
       t = t / 10
    end do
    j = ntop
    do i = n - 1, 1, -1
       t = L(i)
       do k = 9, 1, -1
          dg(j + k) = int(mod(t, 10_int64), int8)
          t = t / 10
       end do
       j = j + 9
    end do
    dp = nd - ndec
    do while (nd > 0)
       if (dg(nd) /= 0) exit
       nd = nd - 1
    end do
  end subroutine exact_digits

  !> keep `cut` significant digits, rounding half-to-even on the exact value
  recursive subroutine round_digits(dg, nd, dp, cut)
    integer(int8), intent(inout) :: dg(:)
    integer, intent(inout) :: nd, dp
    integer, intent(in) :: cut
    logical :: up
    integer :: nxt, i
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
          dg(i) = dg(i) + 1_int8
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
  end subroutine round_digits

  !> %f body with P decimals into wb(1:nbody)
  recursive subroutine render_f(dg, nd, dp, p, alt, nbody)
    integer(int8), intent(in) :: dg(:)
    integer, intent(in) :: nd, dp, p
    logical, intent(in) :: alt
    integer, intent(out) :: nbody
    integer :: k, i, j
    call wbres(max(dp, 1) + p + 1)
    k = 0
    if (dp > 0) then
       do i = 1, dp
          k = k + 1
          if (i <= nd) then
             wb(k) = 48_int8 + dg(i)
          else
             wb(k) = 48_int8
          end if
       end do
    else
       k = 1
       wb(1) = 48_int8
    end if
    if (p > 0 .or. alt) then
       k = k + 1
       wb(k) = 46_int8
    end if
    do j = 1, p
       i = dp + j
       k = k + 1
       if (i >= 1 .and. i <= nd) then
          wb(k) = 48_int8 + dg(i)
       else
          wb(k) = 48_int8
       end if
    end do
    nbody = k
  end subroutine render_f

  !> %e mantissa d.ddd (P decimals) into wb(1:nbody), no exponent
  recursive subroutine render_e_mant(dg, nd, p, alt, nbody)
    integer(int8), intent(in) :: dg(:)
    integer, intent(in) :: nd, p
    logical, intent(in) :: alt
    integer, intent(out) :: nbody
    integer :: k, j
    call wbres(p + 16)
    if (nd > 0) then
       wb(1) = 48_int8 + dg(1)
    else
       wb(1) = 48_int8
    end if
    k = 1
    if (p > 0 .or. alt) then
       k = 2
       wb(2) = 46_int8
    end if
    do j = 2, p + 1
       k = k + 1
       if (j <= nd) then
          wb(k) = 48_int8 + dg(j)
       else
          wb(k) = 48_int8
       end if
    end do
    nbody = k
  end subroutine render_e_mant

  recursive subroutine append_exp(x, upper, nbody)
    integer, intent(in) :: x
    logical, intent(in) :: upper
    integer, intent(inout) :: nbody
    integer :: ax
    call wbres(nbody + 8)
    nbody = nbody + 1
    wb(nbody) = merge(69_int8, 101_int8, upper)
    nbody = nbody + 1
    wb(nbody) = merge(45_int8, 43_int8, x < 0)
    ax = abs(x)
    if (ax >= 100) then
       nbody = nbody + 1
       wb(nbody) = int(48 + ax/100, int8)
       ax = mod(ax, 100)
    end if
    wb(nbody + 1) = int(48 + ax/10, int8)
    wb(nbody + 2) = int(48 + mod(ax, 10), int8)
    nbody = nbody + 2
  end subroutine append_exp

  !> %g: drop trailing zeros of the fraction, then a bare '.'
  recursive subroutine strip_zeros(nbody)
    integer, intent(inout) :: nbody
    integer :: i
    logical :: hasdot
    hasdot = .false.
    do i = 1, nbody
       if (wb(i) == 46_int8) then
          hasdot = .true.
          exit
       end if
    end do
    if (.not. hasdot) return
    do while (wb(nbody) == 48_int8)
       nbody = nbody - 1
    end do
    if (wb(nbody) == 46_int8) nbody = nbody - 1
  end subroutine strip_zeros

  recursive subroutine fmt_float(out, nout, conv, x, left, plus, space, alt, zero, width, prec0)
    integer(int8), allocatable, intent(inout) :: out(:)
    integer, intent(inout) :: nout
    integer, intent(in) :: conv, width, prec0
    real(real64), intent(in) :: x
    logical, intent(in) :: left, plus, space, alt, zero
    integer(int8) :: dg(PDIG), pre(1)
    integer(int64) :: bits, ex
    integer :: npre, nd, dp, nbody, prec, lc, pg, xe, xpre, nz
    logical :: upper
    bits = transfer(x, 0_int64)
    ex = iand(ishft(bits, -52), 2047_int64)
    upper = conv == 70 .or. conv == 69 .or. conv == 71
    lc = lower(conv)
    npre = 0
    if (bits < 0) then
       npre = 1
       pre(1) = 45_int8
    else if (plus) then
       npre = 1
       pre(1) = 43_int8
    else if (space) then
       npre = 1
       pre(1) = 32_int8
    end if
    if (ex == 2047) then
       call wbres(3)
       if (iand(bits, TWO52 - 1) == 0) then
          if (upper) then
             wb(1:3) = [73_int8, 78_int8, 70_int8]
          else
             wb(1:3) = [105_int8, 110_int8, 102_int8]
          end if
       else
          if (upper) then
             wb(1:3) = [78_int8, 65_int8, 78_int8]
          else
             wb(1:3) = [110_int8, 97_int8, 110_int8]
          end if
       end if
       call emit_field(out, nout, pre, npre, 0, 3, width, left)
       return
    end if
    prec = prec0
    if (prec < 0) prec = 6
    if (iand(bits, huge(bits)) == 0) then
       nd = 0
       dp = 1
    else
       call exact_digits(bits, dg, nd, dp)
    end if
    select case (lc)
    case (102)      ! f
       call round_digits(dg, nd, dp, dp + prec)
       call render_f(dg, nd, dp, prec, alt, nbody)
    case (101)      ! e
       call round_digits(dg, nd, dp, prec + 1)
       call render_e_mant(dg, nd, prec, alt, nbody)
       if (nd == 0) then
          call append_exp(0, upper, nbody)
       else
          call append_exp(dp - 1, upper, nbody)
       end if
    case default    ! g
       pg = prec
       if (pg == 0) pg = 1
       xpre = dp - 1
       call round_digits(dg, nd, dp, pg)
       if (nd == 0) then
          xe = 0
       else
          xe = dp - 1
       end if
       if (pg > xe .and. xe >= -4) then
          call render_f(dg, nd, dp, pg - 1 - xe, alt, nbody)
          if (.not. alt) call strip_zeros(nbody)
       else if (alt .and. nd > 0 .and. xe == pg .and. xpre == pg - 1) then
          ! glibc: a value laid out %f-style that rounds up to 10**P is re-cast as %e
          ! keeping its (zero) %f fraction count, so %#.3g of 999.9996 is "1.e+03"
          call wbres(2)
          wb(1:2) = [49_int8, 46_int8]
          nbody = 2
          call append_exp(xe, upper, nbody)
       else
          call render_e_mant(dg, nd, pg - 1, alt, nbody)
          if (.not. alt) call strip_zeros(nbody)
          call append_exp(xe, upper, nbody)
       end if
    end select
    nz = 0
    if (zero .and. .not. left .and. width > npre + nbody) nz = width - npre - nbody
    call emit_field(out, nout, pre, npre, nz, nbody, width, left)
  end subroutine fmt_float

  !> %a / %A (glibc printf_fphex for double: 0x1.hhhp+e, subnormals 0x0.hhhp-1022)
  recursive subroutine fmt_hexf(out, nout, conv, x, left, plus, space, alt, zero, width, prec)
    integer(int8), allocatable, intent(inout) :: out(:)
    integer, intent(inout) :: nout
    integer, intent(in) :: conv, width, prec
    real(real64), intent(in) :: x
    logical, intent(in) :: left, plus, space, alt, zero
    integer(int64) :: bits, ex, f
    integer :: h(13), lead, e, nfd, i, k, nxt, last, npre, nbody, nz, ae
    integer(int8) :: pre(3)
    logical :: upper, up, more
    bits = transfer(x, 0_int64)
    ex = iand(ishft(bits, -52), 2047_int64)
    upper = conv == 65
    if (ex == 2047) then
       call fmt_float(out, nout, merge(69, 101, upper), x, left, plus, space, alt, zero, &
                      width, prec)
       return
    end if
    f = iand(bits, TWO52 - 1)
    if (ex == 0) then
       lead = 0
       e = -1022
       if (f == 0) e = 0
    else
       lead = 1
       e = int(ex) - 1023
    end if
    do i = 1, 13
       h(i) = int(iand(ishft(f, -4*(13 - i)), 15_int64))
    end do
    if (prec < 0) then
       nfd = 13
       do while (nfd > 0)
          if (h(nfd) /= 0) exit
          nfd = nfd - 1
       end do
    else
       nfd = prec
       if (prec < 13) then
          nxt = h(prec + 1)
          more = .false.
          do i = prec + 2, 13
             if (h(i) /= 0) more = .true.
          end do
          if (prec > 0) then
             last = h(prec)
          else
             last = lead
          end if
          up = nxt > 8 .or. (nxt == 8 .and. (more .or. mod(last, 2) == 1))
          if (up) then
             i = prec
             do while (i >= 1)
                if (h(i) /= 15) exit
                h(i) = 0
                i = i - 1
             end do
             if (i >= 1) then
                h(i) = h(i) + 1
             else
                lead = lead + 1
             end if
          end if
       end if
    end if
    npre = 0
    if (bits < 0) then
       npre = 1
       pre(1) = 45_int8
    else if (plus) then
       npre = 1
       pre(1) = 43_int8
    else if (space) then
       npre = 1
       pre(1) = 32_int8
    end if
    pre(npre + 1) = 48_int8
    pre(npre + 2) = merge(88_int8, 120_int8, upper)
    npre = npre + 2
    call wbres(nfd + 16)
    wb(1) = hexch(lead)
    k = 1
    if (nfd > 0 .or. alt) then
       k = 2
       wb(2) = 46_int8
    end if
    do i = 1, nfd
       k = k + 1
       if (i <= 13) then
          wb(k) = hexch(h(i))
       else
          wb(k) = 48_int8
       end if
    end do
    k = k + 1
    wb(k) = merge(80_int8, 112_int8, upper)
    k = k + 1
    wb(k) = merge(45_int8, 43_int8, e < 0)
    ae = abs(e)
    if (ae >= 1000) then
       k = k + 1
       wb(k) = int(48 + ae/1000, int8)
    end if
    if (ae >= 100) then
       k = k + 1
       wb(k) = int(48 + mod(ae/100, 10), int8)
    end if
    if (ae >= 10) then
       k = k + 1
       wb(k) = int(48 + mod(ae/10, 10), int8)
    end if
    k = k + 1
    wb(k) = int(48 + mod(ae, 10), int8)
    nbody = k
    nz = 0
    if (zero .and. .not. left .and. width > npre + nbody) nz = width - npre - nbody
    call emit_field(out, nout, pre, npre, nz, nbody, width, left)
  contains
    recursive integer(int8) function hexch(d)
      integer, intent(in) :: d
      if (d < 10) then
         hexch = int(48 + d, int8)
      else if (upper) then
         hexch = int(55 + d, int8)
      else
         hexch = int(87 + d, int8)
      end if
    end function hexch
  end subroutine fmt_hexf

  ! ===================================================================================
  !  printf: integers, characters, strings
  ! ===================================================================================
  !> digits of the unsigned 64-bit value u (bit pattern), most significant first
  recursive subroutine udigits(u0, base, upper, digs, nd)
    integer(int64), intent(in) :: u0
    integer, intent(in) :: base
    logical, intent(in) :: upper
    integer(int8), intent(out) :: digs(:)
    integer, intent(out) :: nd
    integer(int8) :: tmp(64)
    integer(int64) :: u, hi, d, mask
    integer :: k, sh, i
    k = 0
    u = u0
    if (base == 10) then
       if (u < 0) then
          hi = ishft(u, -1)
          k = 1
          tmp(1) = int(48 + 2*mod(hi, 5_int64) + iand(u, 1_int64), int8)
          u = hi / 5
       end if
       do
          k = k + 1
          tmp(k) = int(48 + mod(u, 10_int64), int8)
          u = u / 10
          if (u == 0) exit
       end do
    else
       if (base == 16) then
          sh = 4
          mask = 15
       else if (base == 8) then
          sh = 3
          mask = 7
       else
          sh = 1
          mask = 1
       end if
       do
          k = k + 1
          d = iand(u, mask)
          if (d < 10) then
             tmp(k) = int(48 + d, int8)
          else if (upper) then
             tmp(k) = int(55 + d, int8)
          else
             tmp(k) = int(87 + d, int8)
          end if
          u = ishft(u, -sh)
          if (u == 0) exit
       end do
    end if
    nd = k
    do i = 1, k
       digs(i) = tmp(k + 1 - i)
    end do
  end subroutine udigits

  recursive subroutine fmt_int(out, nout, conv, iv, lenmod, left, plus, space, alt, zero, width, prec)
    integer(int8), allocatable, intent(inout) :: out(:)
    integer, intent(inout) :: nout
    integer, intent(in) :: conv, lenmod, width, prec
    integer(int64), intent(in) :: iv
    logical, intent(in) :: left, plus, space, alt, zero
    logical :: sgn, neg
    integer(int64) :: v, u
    integer(int8) :: digs(64), pre(3)
    integer :: base, nd, npre, nz
    sgn = conv == 100 .or. conv == 105
    select case (lenmod)
    case (1)
       v = iand(iv, 255_int64)
       if (sgn) v = sext8(v)
    case (2)
       v = iand(iv, 65535_int64)
       if (sgn) v = sext16(v)
    case (0)
       v = iand(iv, MASK32)
       if (sgn) v = sext32(v)
    case default
       v = iv
    end select
    neg = sgn .and. v < 0
    if (neg) then
       if (v == SIGNBIT) then
          u = v
       else
          u = -v
       end if
    else
       u = v
    end if
    select case (conv)
    case (111)
       base = 8
    case (120, 88)
       base = 16
    case (98, 66)
       base = 2
    case default
       base = 10
    end select
    call udigits(u, base, conv == 88, digs, nd)
    if (prec == 0 .and. u == 0) nd = 0
    nz = 0
    if (prec > nd) nz = prec - nd
    if (alt .and. base == 8 .and. nz == 0) then
       if (nd == 0) then
          nz = 1
       else if (digs(1) /= 48_int8) then
          nz = 1
       end if
    end if
    npre = 0
    if (neg) then
       npre = 1
       pre(1) = 45_int8
    else if (sgn .and. plus) then
       npre = 1
       pre(1) = 43_int8
    else if (sgn .and. space) then
       npre = 1
       pre(1) = 32_int8
    end if
    if (alt .and. (base == 16 .or. base == 2) .and. u /= 0) then
       pre(npre + 1) = 48_int8
       pre(npre + 2) = int(conv, int8)        ! 0x 0X 0b 0B
       npre = npre + 2
    end if
    if (zero .and. .not. left .and. prec < 0) then
       if (width > npre + nz + nd) nz = width - npre - nd
    end if
    call wbres(nd)
    if (nd > 0) wb(1:nd) = digs(1:nd)
    call emit_field(out, nout, pre, npre, nz, nd, width, left)
  end subroutine fmt_int

  !> %s of an argument record: its bytes up to a NUL, the end of the array or its length (a Str); a null pointer
  !> (or an argument that is not a string) as glibc prints it: "(null)", or nothing when the precision is 0..5
  recursive subroutine fmt_str(out, nout, a, width, prec, left)
    integer(int8), allocatable, intent(inout) :: out(:)
    integer, intent(inout) :: nout
    type(crt_arg), intent(in) :: a
    integer, intent(in) :: width, prec
    logical, intent(in) :: left
    integer(int8) :: pre(1)
    integer(int64) :: k, hi
    integer :: n
    pre(1) = 0
    if (a%k /= 4) then
       if (prec < 0 .or. prec >= 6) then
          call wbres(6)
          wb(1:6) = [40_int8, 110_int8, 117_int8, 108_int8, 108_int8, 41_int8]
          n = 6
       else
          n = 0
       end if
    else
       hi = ubound(a%sb, 1)
       if (a%sn >= 0) hi = min(hi, a%so + a%sn - 1)
       k = a%so
       do while (k <= hi)
          if (a%sb(k) == 0_int8) exit
          if (prec >= 0 .and. k - a%so >= prec) exit
          k = k + 1
       end do
       n = int(k - a%so)
       call wbres(n)
       if (n > 0) wb(1:n) = a%sb(a%so:k-1)
    end if
    call emit_field(out, nout, pre, 0, 0, n, width, left)
  end subroutine fmt_str

  !> an integer argument's value: the C# value of an integer, the bits of an unsigned one, x86's truncation
  !> (cvttsd2si: the integer indefinite value out of range) of a floating one
  recursive pure integer(int64) function argint(a)
    type(crt_arg), intent(in) :: a
    select case (a%k)
    case (1, 2)
       argint = a%iv
    case (3)
       if (a%rv >= -9223372036854775808.0_real64 .and. a%rv < 9223372036854775808.0_real64) then
          argint = int(a%rv, int64)
       else
          argint = SIGNBIT
       end if
    case default
       argint = 0
    end select
  end function argint

  !> a floating argument's value (an integer converted, an unsigned one as its unsigned value)
  recursive pure real(real64) function argreal(a)
    type(crt_arg), intent(in) :: a
    select case (a%k)
    case (1)
       argreal = real(a%iv, real64)
    case (2)
       if (a%iv >= 0) then
          argreal = real(a%iv, real64)
       else      ! 2^63 and above: halve with the low bit kept as a sticky bit, convert, double (exact)
          argreal = 2.0_real64 * real(ior(ishft(a%iv, -1), iand(a%iv, 1_int64)), real64)
       end if
    case (3)
       argreal = a%rv
    case default
       argreal = 0
    end select
  end function argreal

  ! ===================================================================================
  !  crt_format: the bytes printf writes for the format fb(fo:) and the arguments ar(1:na)
  ! ===================================================================================
  module procedure crt_format
    integer(int64) :: fp, flo, fhi, k, w
    integer :: c, conv, width, prec, lenmod, argi, n, nd
    logical :: left, plus, space, alt, zero, grp, i18n
    integer(int8) :: pre(1), digs(64)
    type(crt_arg) :: a

    nout = 0
    if (allocated(out)) then
       if (lbound(out, 1) /= 1) deallocate(out)
    end if
    if (.not. allocated(out)) allocate(out(256))
    flo = lbound(fb, 1)
    fhi = ubound(fb, 1)
    fp = fo
    argi = 0
    pre(1) = 0
    do
       c = fbc(fp)
       if (c == 0) exit
       if (c /= 37) then
          k = fp
          do while (fbc(k) /= 0 .and. fbc(k) /= 37)
             k = k + 1
          end do
          n = int(k - fp)
          call grow(out, nout + n)
          out(nout+1:nout+n) = fb(fp:k-1)
          nout = nout + n
          fp = k
          cycle
       end if
       fp = fp + 1
       left = .false.
       plus = .false.
       space = .false.
       alt = .false.
       zero = .false.
       grp = .false.
       i18n = .false.
       do
          c = fbc(fp)
          select case (c)
          case (45)
             left = .true.
          case (43)
             plus = .true.
          case (32)
             space = .true.
          case (35)
             alt = .true.
          case (48)
             zero = .true.
          case (39)
             grp = .true.
          case (73)
             i18n = .true.
          case default
             exit
          end select
          fp = fp + 1
       end do
       width = 0
       if (c == 42) then
          call nexta(a)
          w = sext32(argint(a))
          if (w < 0) then
             left = .true.
             w = -w
          end if
          width = int(min(w, 1000000000_int64))
          fp = fp + 1
          c = fbc(fp)
       else
          do while (c >= 48 .and. c <= 57)
             if (width < 100000000) width = width*10 + (c - 48)
             fp = fp + 1
             c = fbc(fp)
          end do
       end if
       prec = -1
       if (c == 46) then
          fp = fp + 1
          c = fbc(fp)
          if (c == 42) then
             call nexta(a)
             w = sext32(argint(a))
             if (w < 0) then
                prec = -1
             else
                prec = int(min(w, 1000000000_int64))
             end if
             fp = fp + 1
             c = fbc(fp)
          else
             prec = 0
             do while (c >= 48 .and. c <= 57)
                if (prec < 100000000) prec = prec*10 + (c - 48)
                fp = fp + 1
                c = fbc(fp)
             end do
          end if
       end if
       if (left) zero = .false.
       lenmod = 0
       select case (c)
       case (104)                    ! h, hh
          fp = fp + 1
          if (fbc(fp) == 104) then
             fp = fp + 1
             lenmod = 1
          else
             lenmod = 2
          end if
       case (108)                    ! l, ll (is_long)
          fp = fp + 1
          lenmod = 3
          if (fbc(fp) == 108) then
             fp = fp + 1
             lenmod = 4
          end if
       case (106, 122, 90, 116)      ! j z Z t (is_long on LP64)
          fp = fp + 1
          lenmod = 3
       case (76, 113)                ! L q (long double / long long)
          fp = fp + 1
          lenmod = 5
       end select
       conv = fbc(fp)
       if (conv == 0) exit           ! incomplete specification: glibc stops
       fp = fp + 1
       select case (conv)
       case (100, 105, 117, 111, 120, 88, 98, 66)   ! d i u o x X b B
          call nexta(a)
          call fmt_int(out, nout, conv, argint(a), lenmod, left, plus, space, alt, zero, width, prec)
       case (102, 70, 101, 69, 103, 71)     ! f F e E g G
          call nexta(a)
          call fmt_float(out, nout, conv, argreal(a), left, plus, space, alt, zero, width, prec)
       case (97, 65)                        ! a A
          call nexta(a)
          call fmt_hexf(out, nout, conv, argreal(a), left, plus, space, alt, zero, width, prec)
       case (99, 67)                        ! c C
          call nexta(a)
          k = argint(a)
          if (conv == 67 .or. lenmod == 3 .or. lenmod == 4) then
             ! wide character in the C locale: only 0..127 convert; glibc fails (EILSEQ)
             ! otherwise and stops, leaving what was already written
             if (k < 0 .or. k > 127) exit
          end if
          call wbres(1)
          wb(1) = int(sext8(k), int8)
          call emit_field(out, nout, pre, 0, 0, 1, width, left)
       case (115, 83)                       ! s S
          call nexta(a)
          call fmt_str(out, nout, a, width, prec, left)
       case (37)                            ! %%
          call grow(out, nout + 1)
          nout = nout + 1
          out(nout) = 37_int8
       case (112)                           ! p (no addresses here: (nil) or 0x<offset>)
          call nexta(a)
          if (a%k == 4) then
             call udigits(a%so, 16, .false., digs, nd)
             call wbres(nd + 2)
             wb(1:2) = [48_int8, 120_int8]
             wb(3:nd+2) = digs(1:nd)
             call emit_field(out, nout, pre, 0, 0, nd + 2, width, left)
          else
             call wbres(5)
             wb(1:5) = [40_int8, 110_int8, 105_int8, 108_int8, 41_int8]
             call emit_field(out, nout, pre, 0, 0, 5, width, left)
          end if
       case (110)                           ! n: consumes its argument (no int* to store through)
          call nexta(a)
       case default                         ! unknown conversion: glibc reprints the spec
          call unknown_spec()
       end select
    end do

  contains

    recursive integer function fbc(i)
      integer(int64), intent(in) :: i
      if (i < flo .or. i > fhi) then
         fbc = 0
      else
         fbc = iand(int(fb(i)), 255)
      end if
    end function fbc

    recursive subroutine nexta(r)
      type(crt_arg), intent(out) :: r
      argi = argi + 1
      if (argi <= na) then
         r = ar(argi)
      else                         ! a missing argument: nothing (0, a null string)
         r%k = 0
         r%iv = 0
         r%rv = 0
         r%sb => null()
         r%so = 0
         r%sn = -1
      end if
    end subroutine nexta

    recursive subroutine put1(ch)
      integer, intent(in) :: ch
      call grow(out, nout + 1)
      nout = nout + 1
      out(nout) = byte(ch)
    end subroutine put1

    recursive subroutine putnum(v)
      integer, intent(in) :: v
      integer :: i
      call udigits(int(v, int64), 10, .false., digs, nd)
      do i = 1, nd
         call put1(int(digs(i)))
      end do
    end subroutine putnum

    recursive subroutine unknown_spec()
      call put1(37)
      if (alt) call put1(35)
      if (grp) call put1(39)
      if (plus) then
         call put1(43)
      else if (space) then
         call put1(32)
      end if
      if (left) call put1(45)
      if (zero) call put1(48)
      if (i18n) call put1(73)
      if (width /= 0) call putnum(width)
      if (prec /= -1) then
         call put1(46)
         call putnum(prec)
      end if
      call put1(conv)
    end subroutine unknown_spec

  end procedure crt_format

  ! ===================================================================================
  !  decimal / binary -> IEEE conversion (shared by strtod and scanf)
  ! ===================================================================================
  !> IEEE bits from q * 2**e2 (q < 2**p, normalised or subnormal); float bits sign-extended
  recursive pure integer(int64) function compose(q, e2, isflt)
    integer(int64), intent(in) :: q
    integer, intent(in) :: e2
    logical, intent(in) :: isflt
    if (isflt) then
       if (q >= 8388608_int64) then
          compose = ishft(int(e2 + 150, int64), 23) + (q - 8388608_int64)
       else
          compose = q
       end if
    else
       if (q >= TWO52) then
          compose = ishft(int(e2 + 1075, int64), 52) + (q - TWO52)
       else
          compose = q
       end if
    end if
  end function compose

  recursive pure integer(int64) function infbits(isflt)
    logical, intent(in) :: isflt
    if (isflt) then
       infbits = 2139095040_int64            ! 0x7f800000
    else
       infbits = 9218868437227405312_int64   ! 0x7ff0000000000000
    end if
  end function infbits

  !> correctly rounded (m + sticky) * 2**e  (0 < m < 2**62)
  recursive pure integer(int64) function round_bin(m, sticky, e, isflt)
    integer(int64), intent(in) :: m
    logical, intent(in) :: sticky
    integer, intent(in) :: e
    logical, intent(in) :: isflt
    integer :: p, emin, emax, bl, e2, sh
    integer(int64) :: q, rem, half
    if (isflt) then
       p = 24
       emin = -149
       emax = 104
    else
       p = 53
       emin = -1074
       emax = 971
    end if
    bl = 64 - leadz(m)
    if (e > 100000 - bl) then
       round_bin = infbits(isflt)
       return
    end if
    if (e < -100000) then
       round_bin = 0
       return
    end if
    e2 = max(e + bl - p, emin)
    sh = e2 - e
    if (sh <= 0) then
       q = ishft(m, -sh)
    else if (sh > 62) then
       q = 0
    else
       q = ishft(m, -sh)
       rem = iand(m, ishft(1_int64, sh) - 1)
       half = ishft(1_int64, sh - 1)
       if (rem > half .or. (rem == half .and. (sticky .or. btest(q, 0)))) q = q + 1
    end if
    if (q == ishft(1_int64, p)) then
       q = ishft(1_int64, p - 1)
       e2 = e2 + 1
    end if
    if (e2 > emax) then
       round_bin = infbits(isflt)
    else
       round_bin = compose(q, e2, isflt)
    end if
  end function round_bin

  !> sign(D * 10**e10 - h * 2**g), D given as limbs
  recursive integer function cmp_dec_bin(dl, nd, e10, h, g)
    integer(int64), intent(in) :: dl(:)
    integer, intent(in) :: nd, e10, g
    integer(int64), intent(in) :: h
    integer(int64) :: lv(MAXL), rv(MAXL)
    integer :: nl, nr, s
    nl = nd
    lv(1:nd) = dl(1:nd)
    call set_big(rv, nr, h)
    if (e10 > 0) then
       call mul_pow5(lv, nl, e10)
    else if (e10 < 0) then
       call mul_pow5(rv, nr, -e10)
    end if
    s = e10 - g
    if (s > 0) then
       call mul_pow2(lv, nl, s)
    else if (s < 0) then
       call mul_pow2(rv, nr, -s)
    end if
    cmp_dec_bin = cmp_big(lv, nl, rv, nr)
  end function cmp_dec_bin

  !> correctly rounded 0.sd(1..ns) * 10**dexp  (sd(1) /= 0), magnitude bits
  recursive integer(int64) function dec_to_bin(sd, ns, dexp, isflt) result(bits)
    integer(int8), intent(in) :: sd(:)
    integer, intent(in) :: ns, dexp
    logical, intent(in) :: isflt
    integer(int64) :: dv, q, t, dl(MAXL), h, top
    integer :: e10, i, j, k, nl, p, emin, emax, e2, g, c, ntop, iter
    real(xp) :: ax
    real(real64) :: bd
    real(real32) :: bf
    integer(int64) :: ab
    if (isflt) then
       p = 24
       emin = -149
       emax = 104
       if (dexp - 1 >= 39) then
          bits = infbits(isflt)
          return
       end if
       if (dexp <= -46) then
          bits = 0
          return
       end if
    else
       p = 53
       emin = -1074
       emax = 971
       if (dexp - 1 >= 309) then
          bits = infbits(isflt)
          return
       end if
       if (dexp <= -324) then
          bits = 0
          return
       end if
    end if
    e10 = dexp - ns
    ! ---- fast paths: exact integer significand and exact power of ten, one rounding
    if (ns <= 18) then
       dv = 0
       do i = 1, ns
          dv = dv*10 + sd(i)
       end do
       if (isflt) then
          if (dv <= 16777216_int64 .and. abs(e10) <= 10) then
             if (e10 >= 0) then
                bf = real(dv, real32) * P10F(e10)
             else
                bf = real(dv, real32) / P10F(-e10)
             end if
             bits = int(transfer(bf, 0_int32), int64)
             return
          end if
       else
          if (dv <= TWO53 .and. abs(e10) <= 22) then
             if (e10 >= 0) then
                bd = real(dv, real64) * P10D(e10)
             else
                bd = real(dv, real64) / P10D(-e10)
             end if
             bits = transfer(bd, 0_int64)
             return
          end if
       end if
    end if
    ! ---- big-integer significand
    nl = (ns + 8) / 9
    do k = 1, nl
       t = 0
       j = ns - 9*k + 1          ! first digit of limb k
       do i = max(j, 1), j + 8
          t = t*10 + sd(i)
       end do
       dl(k) = t
    end do
    ! ---- estimate in extended precision
    ntop = min(ns, 18)
    top = 0
    do i = 1, ntop
       top = top*10 + sd(i)
    end do
    ax = real(top, xp) * (10.0_xp ** (e10 + ns - ntop))
    ! round the estimate with integer arithmetic (no overflow/underflow flags raised)
    ab = round_bin(int(scale(fraction(ax), 62), int64), .false., exponent(ax) - 62, isflt)
    if (isflt) then
       k = int(ishft(ab, -23))
       q = iand(ab, 8388607_int64)
       if (k == 255) then
          q = 16777215_int64
          e2 = emax
       else if (k == 0) then
          e2 = emin
       else
          q = q + 8388608_int64
          e2 = k - 150
       end if
    else
       k = int(ishft(ab, -52))
       q = iand(ab, TWO52 - 1)
       if (k == 2047) then
          q = TWO53 - 1
          e2 = emax
       else if (k == 0) then
          e2 = emin
       else
          q = q + TWO52
          e2 = k - 1075
       end if
    end if
    ! ---- refine against the exact value
    do iter = 1, 1000
       c = cmp_dec_bin(dl, nl, e10, 2*q + 1, e2 - 1)
       if (c > 0 .or. (c == 0 .and. btest(q, 0))) then
          q = q + 1
          if (q == ishft(1_int64, p)) then
             q = ishft(1_int64, p - 1)
             e2 = e2 + 1
             if (e2 > emax) then
                bits = infbits(isflt)
                return
             end if
          end if
          cycle
       end if
       if (q == 0) exit
       if (q == ishft(1_int64, p - 1) .and. e2 > emin) then
          h = 4*q - 1
          g = e2 - 2
       else
          h = 2*q - 1
          g = e2 - 1
       end if
       c = cmp_dec_bin(dl, nl, e10, h, g)
       if (c < 0 .or. (c == 0 .and. btest(q, 0))) then
          if (q == ishft(1_int64, p - 1) .and. e2 > emin) then
             q = ishft(1_int64, p) - 1
             e2 = e2 - 1
          else
             q = q - 1
          end if
          cycle
       end if
       exit
    end do
    bits = compose(q, e2, isflt)
  end function dec_to_bin

  !> strtoull(base 0) over b(i0:i1-1); ok when it consumes exactly that range
  recursive subroutine nan_payload(b, i0, i1, mant, ok)
    integer(int8), intent(in) :: b(0:)
    integer(int64), intent(in) :: i0, i1
    integer(int64), intent(out) :: mant
    logical, intent(out) :: ok
    integer(int64) :: k, hi, lo, endp
    integer :: base, d, c
    logical :: ovf
    mant = 0
    ok = .false.
    k = i0
    base = 10
    if (bch(k) == 48) then
       if (lower(bch(k + 1)) == 120 .and. isxdig(bch(k + 2))) then
          base = 16
          k = k + 2
       else
          base = 8
       end if
    end if
    hi = 0
    lo = 0
    ovf = .false.
    endp = i0
    do
       c = bch(k)
       if (base == 16) then
          if (.not. isxdig(c)) exit
          d = hexval(c)
       else
          if (.not. isdig(c)) exit
          d = c - 48
          if (d >= base) exit
       end if
       lo = lo*base + d
       hi = hi*base + ishft(lo, -32)
       lo = iand(lo, MASK32)
       if (hi >= TWO32) ovf = .true.
       hi = iand(hi, MASK32)
       k = k + 1
       endp = k
    end do
    if (ovf) then
       mant = -1
    else
       mant = ior(ishft(hi, 32), lo)
    end if
    ok = endp == i1
  contains
    recursive integer function bch(i)
      integer(int64), intent(in) :: i
      if (i >= size(b, kind=int64)) then
         bch = 0
      else
         bch = iand(int(b(i)), 255)
      end if
    end function bch
  end subroutine nan_payload

  !> crt_strtod: glibc strtod / strtof over b(start:), NUL or array end terminates.
  !> bits: IEEE bits (float bits sign-extended to int64); ncons: bytes consumed (0 = none)
  module procedure crt_strtod
    integer(int64) :: p, q, sod, nsz, mant, m
    integer :: c, ns, dexp, ev, d, nst, eb
    logical :: neg, hex, sticky, eneg, ok, isint
    integer(int8) :: sd(MAXSIG + 1)
    nsz = size(b, kind=int64)
    p = start
    bits = 0
    ncons = 0
    do while (isspace(ch(p)))
       p = p + 1
    end do
    neg = .false.
    c = ch(p)
    if (c == 45) then
       neg = .true.
       p = p + 1
    else if (c == 43) then
       p = p + 1
    end if
    c = ch(p)
    if (.not. (c == 46 .and. isdig(ch(p + 1))) .and. .not. isdig(c)) then
       if (lower(c) == 105 .and. lower(ch(p + 1)) == 110 .and. lower(ch(p + 2)) == 102) then
          p = p + 3
          if (lower(ch(p)) == 105 .and. lower(ch(p + 1)) == 110 .and. lower(ch(p + 2)) == 105 &
              .and. lower(ch(p + 3)) == 116 .and. lower(ch(p + 4)) == 121) p = p + 5
          bits = infbits(isflt)
          call finish()
          return
       end if
       if (lower(c) == 110 .and. lower(ch(p + 1)) == 97 .and. lower(ch(p + 2)) == 110) then
          p = p + 3
          if (isflt) then
             bits = 2143289344_int64           ! 0x7fc00000
          else
             bits = 9221120237041090560_int64  ! 0x7ff8000000000000
          end if
          if (ch(p) == 40) then
             q = p + 1
             do while (isalnum(ch(q)) .or. ch(q) == 95)
                q = q + 1
             end do
             if (ch(q) == 41) then
                call nan_payload(b, p + 1, q, mant, ok)
                if (ok) then
                   if (isflt) then
                      m = iand(mant, 4194303_int64)
                   else
                      m = iand(mant, 2251799813685247_int64)
                   end if
                   if (m /= 0) bits = ior(bits, m)
                end if
                p = q + 1
             end if
          end if
          call finish()
          return
       end if
       bits = 0          ! no conversion: +0.0, nothing consumed
       ncons = 0
       return
    end if
    hex = .false.
    if (c == 48 .and. lower(ch(p + 1)) == 120) then
       hex = .true.
       p = p + 2
       c = ch(p)
    end if
    sod = p
    do while (c == 48)
       p = p + 1
       c = ch(p)
    end do
    ok = isdig(c) .or. (hex .and. isxdig(c))
    if (.not. ok .and. c == 46) then
       ok = .not. hex .or. p /= sod .or. isxdig(ch(p + 1))
    end if
    if (.not. ok .and. hex .and. p /= sod .and. lower(c) == 112) ok = .true.
    if (.not. ok .and. .not. hex .and. lower(c) == 101) ok = .true.
    if (.not. ok) then
       bits = 0
       if (p == sod) then
          if (hex) then
             p = p - 1
          else
             p = start
             call finish()
             ncons = 0
             return
          end if
       end if
       call finish()
       return
    end if
    if (.not. hex) then
       ns = 0
       dexp = 0
       sticky = .false.
       isint = .true.
       do while (isdig(c))
          call add_digit(c - 48)
          p = p + 1
          c = ch(p)
       end do
       if (c == 46) then
          isint = .false.
          p = p + 1
          c = ch(p)
          do while (isdig(c))
             call add_digit(c - 48)
             p = p + 1
             c = ch(p)
          end do
       end if
       call read_exp(101)
       if (ns == 0) then
          bits = 0
       else
          if (sticky) then
             ns = MAXSIG + 1
             sd(ns) = 1
          end if
          do while (sd(ns) == 0)
             ns = ns - 1
          end do
          bits = dec_to_bin(sd, ns, int(max(min(int(dexp, int64) + ev, 100000_int64), &
                            -100000_int64)), isflt)
       end if
    else
       m = 0
       nst = 0
       eb = 0
       sticky = .false.
       do while (isxdig(c))
          d = hexval(c)
          if (nst < 15) then
             m = m*16 + d
             nst = nst + 1
          else
             eb = eb + 4
             if (d /= 0) sticky = .true.
          end if
          p = p + 1
          c = ch(p)
       end do
       if (c == 46) then
          p = p + 1
          c = ch(p)
          do while (isxdig(c))
             d = hexval(c)
             if (nst == 0 .and. d == 0) then
                eb = eb - 4
             else if (nst < 15) then
                m = m*16 + d
                nst = nst + 1
                eb = eb - 4
             else
                if (d /= 0) sticky = .true.
             end if
             p = p + 1
             c = ch(p)
          end do
       end if
       call read_exp(112)
       if (m == 0) then
          bits = 0
       else
          bits = round_bin(m, sticky, int(max(min(int(eb, int64) + ev, 1000000_int64), &
                           -1000000_int64)), isflt)
       end if
    end if
    call finish()

  contains

    recursive integer function ch(i)
      integer(int64), intent(in) :: i
      if (i >= nsz) then
         ch = 0
      else
         ch = iand(int(b(i)), 255)
      end if
    end function ch

    recursive subroutine add_digit(dd)
      integer, intent(in) :: dd
      if (ns == 0 .and. dd == 0) then
         if (.not. isint) dexp = dexp - 1
         return
      end if
      if (isint) dexp = dexp + 1
      if (ns < MAXSIG) then
         ns = ns + 1
         sd(ns) = int(dd, int8)
      else if (dd /= 0) then
         sticky = .true.
      end if
    end subroutine add_digit

    recursive subroutine read_exp(echar)
      integer, intent(in) :: echar
      integer(int64) :: r
      ev = 0
      if (lower(c) /= echar) return
      r = p + 1
      eneg = .false.
      if (ch(r) == 45) then
         eneg = .true.
         r = r + 1
      else if (ch(r) == 43) then
         r = r + 1
      end if
      if (.not. isdig(ch(r))) return
      do while (isdig(ch(r)))
         if (ev < 100000000) ev = ev*10 + (ch(r) - 48)
         r = r + 1
      end do
      if (eneg) ev = -ev
      p = r
    end subroutine read_exp

    recursive subroutine finish()
      if (neg) then
         if (isflt) then
            bits = ior(bits, TWO31)
         else
            bits = ior(bits, SIGNBIT)
         end if
      end if
      if (isflt) bits = sext32(bits)
      ncons = p - start
    end subroutine finish

  end procedure crt_strtod

  ! ===================================================================================
  !  crt_scan: glibc's sscanf of the input sb(so:) with the format fb(fo:) into the targets tg(1:nt)
  ! ===================================================================================
  !> strtol / strtoul over nb(0:n-1) = [sign] digits-of-base, 64-bit, glibc saturation
  recursive integer(int64) function parse_int(nb, n, base, sgn)
    integer(int8), intent(in) :: nb(0:)
    integer, intent(in) :: n, base
    logical, intent(in) :: sgn
    integer(int64) :: hi, lo, u
    integer :: i, c
    logical :: neg, ovf
    neg = .false.
    i = 0
    c = iand(int(nb(0)), 255)
    if (c == 45 .or. c == 43) then
       neg = c == 45
       i = 1
    end if
    hi = 0
    lo = 0
    ovf = .false.
    do while (i < n)
       c = iand(int(nb(i)), 255)
       lo = lo*base + hexval(c)
       hi = hi*base + ishft(lo, -32)
       lo = iand(lo, MASK32)
       if (hi >= TWO32) ovf = .true.
       hi = iand(hi, MASK32)
       i = i + 1
    end do
    u = ior(ishft(hi, 32), lo)
    if (sgn) then
       if (.not. neg) then
          if (ovf .or. u < 0) then
             parse_int = huge(u)
          else
             parse_int = u
          end if
       else
          if (ovf .or. (u < 0 .and. u /= SIGNBIT)) then
             parse_int = SIGNBIT
          else if (u == SIGNBIT) then
             parse_int = SIGNBIT
          else
             parse_int = -u
          end if
       end if
    else
       if (ovf) then
          parse_int = -1
       else if (neg) then
          if (u == SIGNBIT) then
             parse_int = u
          else
             parse_int = -u
          end if
       else
          parse_int = u
       end if
    end if
  end function parse_int

  module procedure crt_scan
    integer(int64) :: ip, ilo, ihi, fp, flo, fhi, bits, tw, num, cval
    integer :: c, fc, width, argi, base, nbn, lflags, exp_char, ierr, k
    logical :: skip_space, suppress, sgn, got_digit, got_dot, got_e, got_sign, hexa, isdbl
    logical :: special, ok, notin
    logical :: inset(0:255)
    real(real64) :: dv
    real(real32) :: fv
    integer(int8), allocatable :: nb(:)       ! the characters of the conversion being read (0-based)

    done = 0
    ilo = lbound(sb, 1)
    ihi = ubound(sb, 1)
    ip = so
    flo = lbound(fb, 1)
    fhi = ubound(fb, 1)
    fp = fo
    argi = 0
    ierr = 0
    skip_space = .false.
    c = 0
    nbn = 0
    allocate(nb(0:255))

    scan: do
       fc = fmtc(fp)
       if (fc == 0) exit scan
       fp = fp + 1
       if (fc /= 37) then
          if (isspace(fc)) then
             skip_space = .true.
             cycle scan
          end if
          call getc(c)
          if (c == EOFC) then
             ierr = 1
             exit scan
          end if
          if (skip_space) then
             do while (isspace(c))
                call getc(c)
                if (c == EOFC) then
                   ierr = 1
                   exit scan
                end if
             end do
             skip_space = .false.
          end if
          if (c /= fc) then
             call ungetc(c)
             exit scan
          end if
          cycle scan
       end if

       ! ---- a conversion
       suppress = .false.
       do
          fc = fmtc(fp)
          if (fc == 42) then
             suppress = .true.
          else if (fc /= 39 .and. fc /= 73) then
             exit
          end if
          fp = fp + 1
       end do
       width = 0
       do while (isdig(fmtc(fp)))
          if (width < 100000000) width = width*10 + fmtc(fp) - 48
          fp = fp + 1
       end do
       if (width == 0) width = -1
       lflags = 0
       select case (fmtc(fp))
       case (104)
          fp = fp + 1
          if (fmtc(fp) == 104) then
             fp = fp + 1
             lflags = F_CHAR
          else
             lflags = F_SHORT
          end if
       case (108)
          fp = fp + 1
          if (fmtc(fp) == 108) then
             fp = fp + 1
             lflags = F_LONG + F_LONGDBL
          else
             lflags = F_LONG
          end if
       case (113, 76)
          fp = fp + 1
          lflags = F_LONG + F_LONGDBL
       case (122, 106, 116)
          fp = fp + 1
          lflags = F_LONG
       end select
       fc = fmtc(fp)
       if (fc == 0) exit scan
       fp = fp + 1
       if (skip_space .or. (fc /= 91 .and. fc /= 99 .and. fc /= 67 .and. fc /= 110)) then
          do
             call getc(c)
             if (.not. isspace(c)) exit
          end do
          call ungetc(c)
          skip_space = .false.
       end if

       select case (fc)

       case (37)                                    ! %%
          call getc(c)
          if (c == EOFC) then
             ierr = 1
             exit scan
          end if
          if (c /= 37) then
             call ungetc(c)
             exit scan
          end if

       case (110)                                   ! %n
          if (.not. suppress) then
             if (iand(lflags, F_LONG + F_LONGDBL) /= 0) then
                cval = ip - so
             else if (iand(lflags, F_SHORT) /= 0) then
                cval = sext16(ip - so)
             else if (iand(lflags, F_CHAR) /= 0) then
                cval = sext8(ip - so)
             else
                cval = sext32(ip - so)
             end if
             call store_int(cval, iand(lflags, F_LONG + F_LONGDBL) /= 0)
             if (associated(cpp_exc)) return
          end if

       case (99, 67)                                ! %c
          if (width == -1) width = 1
          call getc(c)
          if (c == EOFC) then
             ierr = 1
             exit scan
          end if
          nbn = 0
          do
             call nbadd(c)
             width = width - 1
             if (width <= 0) exit
             call getc(c)
             if (c == EOFC) exit
          end do
          if (.not. suppress) then
             call store_chars(.false.)
             if (associated(cpp_exc)) return
             done = done + 1
          end if

       case (115, 83)                               ! %s
          call getc(c)
          if (c == EOFC) then
             ierr = 1
             exit scan
          end if
          nbn = 0
          do
             if (isspace(c)) then
                call ungetc(c)
                exit
             end if
             call nbadd(c)
             if (width > 0) then
                width = width - 1
                if (width == 0) exit
             end if
             call getc(c)
             if (c == EOFC) exit
          end do
          if (.not. suppress) then
             call store_chars(.true.)
             if (associated(cpp_exc)) return
             done = done + 1
          end if

       case (91)                                    ! %[ a scan set (glibc's vfscanf)
          notin = .false.
          if (fmtc(fp) == 94) then
             notin = .true.
             fp = fp + 1
          end if
          if (width < 0) width = huge(width)
          inset = .false.
          fc = fmtc(fp)
          if (fc == 93 .or. fc == 45) then          ! ] or - first: a member, not the end or a range
             inset(fc) = .true.
             fp = fp + 1
          end if
          do
             fc = fmtc(fp)
             fp = fp + 1
             if (fc == 0 .or. fc == 93) exit
             if (fc == 45 .and. fmtc(fp) /= 0 .and. fmtc(fp) /= 93 .and. fmtc(fp - 2) <= fmtc(fp)) then
                do k = fmtc(fp - 2), fmtc(fp) - 1   ! a range: from the character before '-' up to the next
                   inset(k) = .true.
                end do
             else
                inset(fc) = .true.
             end if
          end do
          if (fc == 0) exit scan                    ! no closing ]: a matching failure
          call getc(c)
          if (c == EOFC) then
             ierr = 1
             exit scan
          end if
          nbn = 0
          do
             if (inset(c) .eqv. notin) then
                call ungetc(c)
                exit
             end if
             call nbadd(c)
             width = width - 1
             if (width <= 0) exit
             call getc(c)
             if (c == EOFC) exit
          end do
          if (nbn == 0) exit scan
          if (.not. suppress) then
             call store_chars(.true.)
             if (associated(cpp_exc)) return
             done = done + 1
          end if

       case (120, 88, 111, 117, 100, 105, 98)       ! %x %X %o %u %d %i %b
          select case (fc)
          case (120, 88)
             base = 16
             sgn = .false.
          case (98)
             base = 2
             sgn = .false.
          case (111)
             base = 8
             sgn = .false.
          case (117)
             base = 10
             sgn = .false.
          case (100)
             base = 10
             sgn = .true.
          case default
             base = 0
             sgn = .true.
          end select
          call getc(c)
          if (c == EOFC) then
             ierr = 1
             exit scan
          end if
          nbn = 0
          if (c == 45 .or. c == 43) then
             call nbadd(c)
             if (width > 0) width = width - 1
             call getc(c)
          end if
          if (width /= 0 .and. c == 48) then
             if (width > 0) width = width - 1
             call nbadd(c)
             call getc(c)
             if (width /= 0 .and. lower(c) == 120) then
                if (base == 0) base = 16
                if (base == 16) then
                   if (width > 0) width = width - 1
                   call getc(c)
                end if
             else if (width /= 0 .and. lower(c) == 98 .and. base == 2) then
                ! 0b prefix: %b only (glibc's C23 %i binary prefix is not in the C17 sscanf)
                if (width > 0) width = width - 1
                call getc(c)
             else if (base == 0) then
                base = 8
             end if
          end if
          if (base == 0) base = 10
          do while (c /= EOFC .and. width /= 0)
             if (base == 16) then
                if (.not. isxdig(c)) exit
             else
                if (.not. isdig(c)) exit
                if (c - 48 >= base) exit
             end if
             call nbadd(c)
             if (width > 0) width = width - 1
             call getc(c)
          end do
          if (nbn == 0) then
             call ungetc(c)
             exit scan
          end if
          if (nbn == 1 .and. (nb(0) == 43_int8 .or. nb(0) == 45_int8)) then
             call ungetc(c)
             exit scan
          end if
          call ungetc(c)
          num = parse_int(nb, nbn, base, sgn)
          if (.not. suppress) then
             if (sgn) then
                if (iand(lflags, F_LONG + F_LONGDBL) /= 0) then
                   cval = num
                else if (iand(lflags, F_SHORT) /= 0) then
                   cval = sext16(num)
                else if (iand(lflags, F_CHAR) /= 0) then
                   cval = sext8(num)
                else
                   cval = sext32(num)
                end if
             else
                if (iand(lflags, F_LONG + F_LONGDBL) /= 0) then
                   cval = num
                else if (iand(lflags, F_SHORT) /= 0) then
                   cval = iand(num, 65535_int64)
                else if (iand(lflags, F_CHAR) /= 0) then
                   cval = iand(num, 255_int64)
                else
                   cval = iand(num, MASK32)
                end if
             end if
             call store_int(cval, iand(lflags, F_LONG + F_LONGDBL) /= 0)
             if (associated(cpp_exc)) return
             done = done + 1
          end if

       case (101, 69, 102, 70, 103, 71, 97, 65)     ! %e %f %g %a
          call getc(c)
          if (width > 0) width = width - 1
          if (c == EOFC) then
             ierr = 1
             exit scan
          end if
          nbn = 0
          got_digit = .false.
          got_dot = .false.
          got_e = .false.
          got_sign = .false.
          hexa = .false.
          special = .false.
          if (c == 45 .or. c == 43) then
             got_sign = .true.
             call nbadd(c)
             if (width == 0) exit scan
             call getc(c)
             if (c == EOFC) exit scan
             if (width > 0) width = width - 1
          end if
          if (lower(c) == 110) then                 ! nan
             call nbadd(c)
             call want(97, ok)
             if (.not. ok) exit scan
             call want(110, ok)
             if (.not. ok) exit scan
             special = .true.
          else if (lower(c) == 105) then            ! inf / infinity
             call nbadd(c)
             call want(110, ok)
             if (.not. ok) exit scan
             call want(102, ok)
             if (.not. ok) exit scan
             if (width /= 0) then
                call getc(c)
                if (c /= EOFC) then
                   if (lower(c) == 105) then
                      if (width > 0) width = width - 1
                      call nbadd(c)
                      call want(110, ok)
                      if (.not. ok) exit scan
                      call want(105, ok)
                      if (.not. ok) exit scan
                      call want(116, ok)
                      if (.not. ok) exit scan
                      call want(121, ok)
                      if (.not. ok) exit scan
                   else
                      call ungetc(c)
                   end if
                end if
             end if
             special = .true.
          end if
          if (.not. special) then
             exp_char = 101
             if (width /= 0 .and. c == 48) then
                call nbadd(c)
                call getc(c)
                if (width > 0) width = width - 1
                if (width /= 0 .and. lower(c) == 120) then
                   call nbadd(c)
                   hexa = .true.
                   exp_char = 112
                   call getc(c)
                   if (width > 0) width = width - 1
                else
                   got_digit = .true.
                end if
             end if
             do
                if (isdig(c)) then
                   call nbadd(c)
                   got_digit = .true.
                else if (.not. got_e .and. hexa .and. isxdig(c)) then
                   call nbadd(c)
                   got_digit = .true.
                else if (got_e .and. iand(int(nb(nbn - 1)), 255) == exp_char .and. &
                         (c == 45 .or. c == 43)) then
                   call nbadd(c)
                else if (got_digit .and. .not. got_e .and. lower(c) == exp_char) then
                   call nbadd(exp_char)
                   got_e = .true.
                   got_dot = .true.
                else if (.not. got_dot .and. c == 46) then
                   call nbadd(c)
                   got_dot = .true.
                else
                   call ungetc(c)
                   exit
                end if
                if (width == 0) exit
                call getc(c)
                if (c == EOFC) exit
                if (width > 0) width = width - 1
             end do
             if (got_sign) then
                if (nbn == 1) exit scan
                if (hexa .and. nbn == 3) exit scan
             else
                if (nbn == 0) exit scan
                if (hexa .and. nbn == 2) exit scan
             end if
          end if
          call nbgrow(nbn + 1)
          nb(nbn) = 0
          isdbl = iand(lflags, F_LONG + F_LONGDBL) /= 0
          call crt_strtod(nb, 0_int64, .not. isdbl, bits, tw)
          if (tw == 0) exit scan
          if (.not. suppress) then
             if (isdbl) then
                dv = transfer(bits, dv)
                fv = 0
             else
                fv = transfer(int(bits, int32), fv)
                dv = 0
             end if
             call store_real(dv, fv, isdbl)
             if (associated(cpp_exc)) return
             done = done + 1
          end if

       case default                                 ! %p and unknown: matching failure
          exit scan
       end select
    end do scan

    if (ierr == 1 .and. done == 0) done = -1

  contains

    recursive integer function fmtc(i)
      integer(int64), intent(in) :: i
      if (i < flo .or. i > fhi) then
         fmtc = 0
      else
         fmtc = iand(int(fb(i)), 255)
      end if
    end function fmtc

    recursive subroutine getc(ch)
      integer, intent(out) :: ch
      if (ip < ilo .or. ip > ihi) then
         ch = EOFC
         return
      end if
      ch = iand(int(sb(ip)), 255)
      if (ch == 0) then
         ch = EOFC
      else
         ip = ip + 1
      end if
    end subroutine getc

    recursive subroutine ungetc(ch)
      integer, intent(in) :: ch
      if (ch /= EOFC) ip = ip - 1
    end subroutine ungetc

    recursive subroutine nbgrow(n)   ! nb(0:n-1) must exist
      integer, intent(in) :: n
      integer(int8), allocatable :: tmp(:)
      if (size(nb) < n) then
         allocate(tmp(0:max(2*size(nb), n) - 1))
         tmp(0:size(nb) - 1) = nb
         call move_alloc(tmp, nb)
      end if
    end subroutine nbgrow

    recursive subroutine nbadd(ch)
      integer, intent(in) :: ch
      call nbgrow(nbn + 2)
      nb(nbn) = byte(ch)
      nbn = nbn + 1
    end subroutine nbadd

    recursive subroutine want(lc, good)        ! next char must be lc (case-insensitive), within width
      integer, intent(in) :: lc
      logical, intent(out) :: good
      good = .false.
      if (width == 0) return
      call getc(c)
      if (c == EOFC) return
      if (lower(c) /= lc) return
      if (width > 0) width = width - 1
      call nbadd(c)
      good = .true.
    end subroutine want

    !> an integer conversion's value v (already taken at its length modifier's size) into the next target: an
    !> int (RefI: the low 32 bits) or long (RefL) lvalue, or the stash (R.Slot: a long with l, an int without)
    recursive subroutine store_int(v, lng)
      integer(int64), intent(in) :: v
      logical, intent(in) :: lng
      argi = argi + 1
      if (argi > nt) return
      select case (tg(argi)%k)
      case (1)
         call tg(argi)%ai%invoke(int(sext32(v), int32))
      case (2)
         call tg(argi)%al%invoke(v)
      case (6)
         if (lng) then
            call crt_stash(2, v, 0.0_real64)
         else
            call crt_stash(1, sext32(v), 0.0_real64)
         end if
      end select
    end subroutine store_int

    !> a floating conversion's value (d with l, else f) into the next target: a double (RefD) or float (RefF)
    !> lvalue, or the stash (a double with l, a float without)
    recursive subroutine store_real(d, f, dbl)
      real(real64), intent(in) :: d
      real(real32), intent(in) :: f
      logical, intent(in) :: dbl
      argi = argi + 1
      if (argi > nt) return
      select case (tg(argi)%k)
      case (3)
         if (dbl) then
            call tg(argi)%ad%invoke(d)
         else
            call tg(argi)%ad%invoke(real(f, real64))
         end if
      case (4)
         if (dbl) then
            call tg(argi)%af%invoke(real(d, real32))
         else
            call tg(argi)%af%invoke(f)
         end if
      case (6)
         if (dbl) then
            call crt_stash(4, 0_int64, d)
         else
            call crt_stash(5, 0_int64, real(f, real64))
         end if
      end select
    end subroutine store_real

    !> the characters nb(0:nbn-1) of %c / %s / %[ into the next target: a char buffer (CPtr; a NUL after them for
    !> %s and %[, kept inside the buffer), a char lvalue (RefI: the first, as a signed char), or the stash
    recursive subroutine store_chars(addnul)
      logical, intent(in) :: addnul
      integer(int64) :: kk, hi
      integer :: i
      argi = argi + 1
      if (argi > nt) return
      select case (tg(argi)%k)
      case (5)
         if (.not. associated(tg(argi)%cp%b)) return
         hi = ubound(tg(argi)%cp%b%a, 1)
         kk = tg(argi)%cp%o
         do i = 0, nbn - 1
            if (kk > hi) exit
            tg(argi)%cp%b%a(kk) = nb(i)
            kk = kk + 1
         end do
         if (addnul) then
            if (kk > hi) kk = hi
            if (kk >= 0) tg(argi)%cp%b%a(kk) = 0
         end if
      case (1)
         call tg(argi)%ai%invoke(int(nb(0), int32))
      case (6)
         call crt_stash(3, int(nb(0), int64), 0.0_real64)
      end select
    end subroutine store_chars

  end procedure crt_scan

end submodule fmt
