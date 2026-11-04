! cpp_rt_d.f90 - part D of the Fortran runtime of the SWMM6 engine (f90/gen): the iostreams, std::filesystem and
! System.IO.File.Exists. A port of cs/runtime/Streams.cs and Fs.cs (the specification), with the .NET System.IO
! behaviour those files rely on reproduced over the C library (open, pread, pwrite, stat, rename, ...), as the ports
! that pass the gate reproduce it (py/cpp fsnet.py, streams.py, fs.py; ts/src/cpp fsnet.ts, streams.ts, fs.ts;
! java/src/cpp/FsNet.java):
!   - Path.GetFullPath on Unix: lexical ("." and ".." and doubled separators removed against the current directory,
!     symbolic links left alone; ArgumentException for an empty path or a NUL); File.Exists / Directory.Exists
!     (stat, then lstat for a broken link; a full path ending in '/' is never a file); File.Move (rename(2), or copy
!     and delete across file systems; a directory destination refused), File.Copy (the bytes and the permission
!     bits, no overwrite), File.Delete, Directory.Delete (rmdir), Directory.CreateDirectory, FileInfo.Length.
!   - A FileStream: opened as .NET opens one (O_CLOEXEC, mode 0666, a directory refused, FileMode.Append without
!     O_APPEND: the stream starts at the end and may not seek before it); read in blocks of 64 KiB (the C# IStream's
!     buffer; .NET passes a request of a whole buffer straight to pread at the position it keeps); written through
!     its write buffer (BufferedFileStreamStrategy: fill the buffer, flush it, write a request of a whole buffer or
!     more directly) with pwrite at the position it keeps. A stream never closed keeps its buffered bytes, as a .NET
!     FileStream does at exit (no finalizer runs). A MemoryStream: writes overwrite, extend, zero-fill a gap.
!   - Paths reach the OS as .NET passes them: the C# string of the bytes (Latin-1) encoded as UTF-8; a .NET string
!     is held here as its UTF-8 bytes. A string from the OS (getcwd) is decoded as .NET decodes UTF-8 (a maximal
!     invalid subsequence becomes U+FFFD) and handed back to the engine as Encoding.Latin1 encodes it ('?' above
!     U+00FF).
!   - Streams: a double is written with the printf format libstdc++'s num_put builds from the stream flags (%.*g by
!     default, %.*f for fixed, %.*e for scientific, %a for fixed|scientific, '#' for showpoint), formatted by part
!     C's glibc-exact formatter through R.snprintf; width and fill are applied afterwards and width resets. Reading
!     numbers goes through part C's strtod and the C# strtol (decimal, saturating) as libstdc++'s num_get does for
!     ordinary input (a token that does not convert whole sets failbit and stores 0; an int out of range stores the
!     nearest limit). getline consumes the delimiter; at the end of the input it sets eof, and fail too when nothing
!     at all was read. seekg clears eof; on a file, ios::cur is relative to the logical read position (the fixed
!     C#). cout and cerr write through to descriptors 1 and 2 at once, as .NET's console streams do, after flushing
!     part C's stdout / stderr C file, so stream and printf output keep their order.
!   - Ptr<T> reads and writes (read<double>(Ptr, n), ...) see the bytes of the elements from p (Mem.BytesOf /
!     BytesInto, little-endian) through part A's Ptr components a and o, with the C# Span's checks.
! Deliberate difference from the C#, following the ports that pass: OFStream.open / IFStream.open on a stream that is
! already open close the old file first (the C# drops it to the finalizer, which would flush and close it).
! Beyond the 92 entries of f90/runtime_parts.txt marked D, the rest of Streams.cs and Fs.cs is here too (FStream,
! the other Put overloads and manipulators, tellp / seekp, peek / get / ignore, the FsPath element functions, the
! other Fs functions), named as the translator names runtime members, so tests/stdcheck's stream check can run
! statement for statement as streamcheck.cs. cpp_rt_d_init makes cout, cerr and clog (C#'s static fields).
! Uses part C's ErrorCode component v (C#'s ErrorCode.v), cpp_sysexception_new, cpp_r_snprintf_cptr_ul_cptr_oa,
! cpp_r_strtod_cptr_cptrr, cpp_r_lit, cpp_r_fflush, cpp_r_stdout_x, cpp_r_stderr_x; part A's Str constructors and
! the components of its Str (b, n), CPtr (b, o), arrays (a) and Ptr (a, o).
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
module cpp_rt_d
  use, intrinsic :: iso_c_binding, only: c_int, c_long, c_size_t, c_char, c_ptr, c_null_char, c_associated, &
      c_f_pointer, c_loc, c_int8_t
  use cpp_rt_a
  use cpp_rt_c
  use cpp_rt_b
  implicit none
  private

  ! ------------------------------------------------------------------------------------------- public names
  ! the 92 entries of the manifest
  public :: cpp_filestatus, cpp_fspath, cpp_ifstream, cpp_iosbase, cpp_istream, cpp_istringstream, cpp_ofstream, &
      cpp_ostream, cpp_ostringstream
  public :: cpp_file_exists, cpp_fs_create_hard_link, cpp_fs_equivalent_fspath_fspath, &
      cpp_fs_exists_fspath_errorcode, cpp_fs_file_size_fspath, cpp_fs_file_size_fspath_errorcode, &
      cpp_fs_is_directory_fspath, cpp_fs_is_regular_file_filestatus, cpp_fs_remove_fspath_errorcode, &
      cpp_fs_rename_fspath_fspath_errorcode, cpp_fs_symlink_status_fspath, cpp_fs_symlink_status_fspath_errorcode, &
      cpp_fs_weakly_canonical_fspath
  public :: cpp_fspath_assign_fspath, cpp_fspath_c_str, cpp_fspath_clear, cpp_fspath_clone, cpp_fspath_compare, &
      cpp_fspath_empty, cpp_fspath_extension, cpp_fspath_generic_string, cpp_fspath_is_relative, &
      cpp_fspath_join_fspath, cpp_fspath_lexically_normal, cpp_fspath_movefrom, cpp_fspath_new_0, &
      cpp_fspath_new_cptr, cpp_fspath_new_str, cpp_fspath_parent_path, cpp_fspath_replace_extension_fspath, &
      cpp_fspath_string
  public :: cpp_ifstream_is_open, cpp_ifstream_new_fspath_i, cpp_ifstream_new_str_i
  public :: cpp_iosbase_bad, cpp_iosbase_clear, cpp_iosbase_eof, cpp_iosbase_good, cpp_iosbase_imbue, &
      cpp_iosbase_notok, cpp_iosbase_ok
  public :: cpp_istream_gcount, cpp_istream_get_dr, cpp_istream_get_ir, cpp_istream_get_str, cpp_istream_get_ulr, &
      cpp_istream_get_ur, cpp_istream_manip_ws, cpp_istream_read_cptr_l, cpp_istream_read_ptrt_l__b, &
      cpp_istream_read_ptrt_l__d, cpp_istream_read_ptrt_l__f, cpp_istream_read_ptrt_l__i, cpp_istream_read_ptrt_l__l, &
      cpp_istream_seekg, cpp_istream_tellg
  public :: cpp_istringstream_new_str, cpp_istringstream_new_str_i
  public :: cpp_ofstream_close, cpp_ofstream_is_open, cpp_ofstream_new_0, cpp_ofstream_new_cptr_i, &
      cpp_ofstream_new_fspath_i, cpp_ofstream_open_str_i
  public :: cpp_ostream_manip_quoted_cptr, cpp_ostream_manip_quoted_str, cpp_ostream_manip_setprecision, &
      cpp_ostream_put_c, cpp_ostream_put_cptr, cpp_ostream_put_d, cpp_ostream_put_i, cpp_ostream_put_str, &
      cpp_ostream_put_ul, cpp_ostream_write_cptr_l, cpp_ostream_write_ptrt_l__d, cpp_ostream_write_ptrt_l__f, &
      cpp_ostream_write_ptrt_l__i, cpp_ostream_write_ptrt_l__l
  public :: cpp_ostringstream_new_0, cpp_ostringstream_new_i, cpp_ostringstream_str_0
  public :: cpp_streams_getline_istream_str, cpp_streams_getline_istream_str_c
  ! the rest of Streams.cs and Fs.cs (not used by the engine today)
  public :: cpp_fstream, cpp_setprec, cpp_setw, cpp_setfill, cpp_rt_d_init, cpp_streams_cout, cpp_streams_cerr, &
      cpp_streams_clog
  public :: cpp_iosbase_fail, cpp_iosbase_precision_0, cpp_iosbase_precision_l, cpp_iosbase_width_0, &
      cpp_iosbase_width_l, cpp_iosbase_fill_0, cpp_iosbase_fill_i, cpp_iosbase_setf_i, cpp_iosbase_setf_i_i, &
      cpp_iosbase_unsetf, cpp_iosbase_exceptions
  public :: cpp_ostream_put_uc, cpp_ostream_put_l, cpp_ostream_put_u, cpp_ostream_put_s, cpp_ostream_put_b, &
      cpp_ostream_put_f, cpp_ostream_put_setprec, cpp_ostream_put_setw, cpp_ostream_put_setfill, &
      cpp_ostream_put_ostream, cpp_ostream_manip_endl, cpp_ostream_manip_flush, cpp_ostream_manip_setw, &
      cpp_ostream_manip_setfill, cpp_ostream_manip_fixed, cpp_ostream_manip_scientific, &
      cpp_ostream_manip_defaultfloat, cpp_ostream_manip_left, cpp_ostream_manip_right, cpp_ostream_manip_boolalpha, &
      cpp_ostream_manip_noboolalpha, cpp_ostream_manip_showpoint, cpp_ostream_manip_noshowpoint, &
      cpp_ostream_write_ptrt_l__b, cpp_ostream_flush, cpp_ostream_tellp, cpp_ostream_seekp
  public :: cpp_ostringstream_new_str, cpp_ostringstream_str_str, cpp_ostringstream_movefrom
  public :: cpp_ofstream_new_str_i, cpp_ofstream_open_fspath_i, cpp_ofstream_dispose, cpp_ofstream_movefrom
  public :: cpp_fstream_new_str_i, cpp_fstream_is_open, cpp_fstream_close, cpp_fstream_dispose
  public :: cpp_istream_peek, cpp_istream_get_0, cpp_istream_get_cr_raw, cpp_istream_get_cr, cpp_istream_ignore, &
      cpp_istream_get_lr, cpp_istream_get_fr, cpp_istream_readline
  public :: cpp_istringstream_new_0, cpp_istringstream_str_str, cpp_istringstream_str_0, cpp_istringstream_movefrom
  public :: cpp_ifstream_new_0, cpp_ifstream_new_cptr_i, cpp_ifstream_open_str_i, cpp_ifstream_open_fspath_i, &
      cpp_ifstream_close, cpp_ifstream_dispose, cpp_ifstream_movefrom
  public :: cpp_streams_getline_istream_str_i, cpp_streams_setprecision, cpp_streams_setw, cpp_streams_setfill
  public :: cpp_fspath_new_chars, cpp_fspath_assign_str, cpp_fspath_native, cpp_fspath_u8string, &
      cpp_fspath_is_absolute, cpp_fspath_has_filename, cpp_fspath_has_parent_path, cpp_fspath_has_extension, &
      cpp_fspath_filename, cpp_fspath_stem, cpp_fspath_replace_extension_str, cpp_fspath_replace_filename, &
      cpp_fspath_remove_filename, cpp_fspath_join_str, cpp_fspath_join_cptr, cpp_fspath_compareto, cpp_fspath_tostring
  public :: cpp_fs_exists_fspath, cpp_fs_is_regular_file_fspath, cpp_fs_remove_fspath, &
      cpp_fs_create_directories_fspath, cpp_fs_create_directories_fspath_errorcode, cpp_fs_current_path, &
      cpp_fs_absolute, cpp_fs_canonical_fspath, cpp_fs_canonical_fspath_errorcode, &
      cpp_fs_weakly_canonical_fspath_errorcode, cpp_fs_temp_directory_path, cpp_fs_rename_fspath_fspath, &
      cpp_fs_equivalent_fspath_fspath_errorcode, cpp_fs_status_fspath, cpp_fs_status_fspath_errorcode, &
      cpp_fs_exists_filestatus, cpp_fs_is_directory_filestatus, cpp_fs_is_symlink, cpp_directory_exists
  public :: cpp_filestatus_of, cpp_filestatus_type, cpp_filestatus_clone
  ! .NET strings for the runner (f90/runtime/swmm6_main.F90): a command-line argument as .NET decodes it, R.Lit's
  ! bytes of a .NET string, Encoding.Latin1's bytes of one
  public :: cpp_net_from_os, cpp_net_lit_bytes, cpp_net_latin1

  ! ------------------------------------------------------------------------------------------- Cpp.Ios
  ! the libstdc++ values of ios_base::openmode, seekdir, fmtflags and iostate
  integer(4), parameter, public :: cpp_ios_in = 8, cpp_ios_out = 16, cpp_ios_binary = 4, cpp_ios_app = 1, &
      cpp_ios_trunc = 32, cpp_ios_ate = 2
  integer(4), parameter, public :: cpp_ios_beg = 0, cpp_ios_cur = 1, cpp_ios_end = 2
  integer(4), parameter, public :: cpp_ios_boolalpha = 1, cpp_ios_dec = 2, cpp_ios_fixed = 4, cpp_ios_hex = 8, &
      cpp_ios_internal = 16, cpp_ios_left = 32, cpp_ios_oct = 64, cpp_ios_right = 128, cpp_ios_scientific = 256, &
      cpp_ios_showbase = 512, cpp_ios_showpoint = 1024, cpp_ios_showpos = 2048, cpp_ios_skipws = 4096, &
      cpp_ios_unitbuf = 8192, cpp_ios_uppercase = 16384, cpp_ios_adjustfield = 176, cpp_ios_basefield = 74, &
      cpp_ios_floatfield = 260
  integer(4), parameter, public :: cpp_ios_goodbit = 0, cpp_ios_badbit = 1, cpp_ios_eofbit = 2, cpp_ios_failbit = 4

  ! FileStatus kinds
  integer(4), parameter :: FS_NOTFOUND = -1, FS_REGULAR = 1, FS_DIRECTORY = 2

  ! Linux x86-64 values of the C library's constants
  integer(c_int), parameter :: O_RDONLY = 0, O_WRONLY = 1, O_RDWR = 2, O_CREAT = 64, O_EXCL = 128, O_TRUNC = 512, &
      O_CLOEXEC = 524288
  integer(c_int), parameter :: E_NOENT = 2, E_INTR = 4, E_XDEV = 18, E_ISDIR = 21, E_RANGE = 34
  integer(8), parameter :: S_IFMT = 61440, S_IFDIR = 16384
  integer(c_int), parameter :: SEEK_SET = 0, SEEK_CUR = 1, SEEK_END = 2
  integer(8), parameter :: STREAM_BUF = 65536        ! the C# streams' buffers: 1 << 16

  character(len=*), parameter :: SEEK_BEFORE_BEGIN = &
      'An attempt was made to move the position before the beginning of the stream.'
  character(len=*), parameter :: SEEK_APPEND = &
      'Unable seek backward to overwrite data that previously existed in a file opened in Append mode.'

  ! ------------------------------------------------------------------------------------------- .NET streams
  ! a FileStream opened for writing, with its write buffer (BufferedFileStreamStrategy over the descriptor)
  type :: d_fileout
    integer(c_int) :: fd = -1
    integer(1), allocatable :: buf(:)       ! buf(0:size-1)
    integer(8) :: wpos = 0                  ! bytes in buf (_writePos)
    integer(8) :: fpos = 0                  ! the file offset buf starts at (OSFileStreamStrategy._filePosition)
    integer(8) :: append_start = -1         ! FileMode.Append: the end the file had when it was opened
    logical :: seekable = .true.
  end type d_fileout

  ! a MemoryStream: the bytes, their length and the position
  type :: d_memstream
    integer(1), allocatable :: b(:)         ! b(0:capacity-1)
    integer(8) :: len = 0
    integer(8) :: pos = 0
  end type d_memstream

  ! ------------------------------------------------------------------------------------------- the stream classes
  ! std::ios_base's state and format (C# Cpp.IosBase)
  type, extends(cpp_object) :: cpp_iosbase
    logical :: failbit = .false.
    logical :: eofbit = .false.
    logical :: badbit = .false.
    integer(8) :: prec = 6
    integer(4) :: flagsv = 0
    integer(8) :: widthv = 0
    integer(4) :: fillc = 32
  end type cpp_iosbase

  ! std::ostream (C# Cpp.OStream): the C# s is a FileStream (s here) or a console stream (std = 1 or 2)
  type, extends(cpp_iosbase) :: cpp_ostream
    type(d_fileout), pointer :: s => null()
    type(d_memstream), pointer :: mem => null()
    integer(4) :: std = 0
  end type cpp_ostream

  type, extends(cpp_ostream) :: cpp_ostringstream
  end type cpp_ostringstream

  type, extends(cpp_ostream) :: cpp_ofstream
  contains
    procedure :: dispose => d_ofstream_dispose_b
  end type cpp_ofstream

  type, extends(cpp_ostream) :: cpp_fstream
  contains
    procedure :: dispose => d_fstream_dispose_b
  end type cpp_fstream

  ! std::istream (C# Cpp.IStream): the bytes of a string, or the last block read from a file, and the position in it
  type, extends(cpp_iosbase) :: cpp_istream
    class(cpp_arr_b), pointer :: buf => null()   ! null: Array.Empty<byte>()
    integer(4) :: pos = 0
    integer(4) :: len = 0
    integer(c_int) :: src = -1                   ! the descriptor an ifstream reads (the C# src), or -1
    integer(8) :: srcpos = 0                     ! the file offset past the bytes read (FileStream.Position)
    logical :: srcseek = .true.
    integer(8) :: gcountv = 0
  end type cpp_istream

  type, extends(cpp_istream) :: cpp_istringstream
  end type cpp_istringstream

  type, extends(cpp_istream) :: cpp_ifstream
  contains
    procedure :: dispose => d_ifstream_dispose_b
  end type cpp_ifstream

  ! std::setprecision, std::setw, std::setfill values
  type, extends(cpp_object) :: cpp_setprec
    integer(4) :: n = 0
  end type cpp_setprec
  type, extends(cpp_object) :: cpp_setw
    integer(4) :: n = 0
  end type cpp_setw
  type, extends(cpp_object) :: cpp_setfill
    integer(4) :: c = 0
  end type cpp_setfill

  ! ------------------------------------------------------------------------------------------- the filesystem classes
  ! std::filesystem::path (C# Cpp.FsPath): p holds the path's bytes
  type, extends(cpp_object) :: cpp_fspath
    class(cpp_str), pointer :: p => null()
  contains
    procedure :: clone => d_fspath_clone_b
    procedure :: assign => d_fspath_assign_b
  end type cpp_fspath

  ! std::filesystem::file_status as far as the engine asks (C# Cpp.FileStatus)
  type, extends(cpp_object) :: cpp_filestatus
    integer(4) :: kind = 0
  end type cpp_filestatus

  ! ------------------------------------------------------------------------------------------- module variables
  class(cpp_ostream), pointer :: cpp_streams_cout => null()
  class(cpp_ostream), pointer :: cpp_streams_cerr => null()
  class(cpp_ostream), pointer :: cpp_streams_clog => null()
  ! the formats of libstdc++'s __num_base::_S_format_float: (g, f, e, a) x (showpoint), made on first use
  logical, save :: d_fmt_ready = .false.
  type(cpp_cptr), save :: d_fmt(0:3, 0:1)
  ! the buffer R.snprintf formats a double into
  class(cpp_arr_b), pointer, save :: d_fbuf => null()

  ! ------------------------------------------------------------------------------------------- the C library
  interface
    function d_c_open(path, flags, mode) bind(C, name='open') result(r)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: path(*)
      integer(c_int), value :: flags, mode
      integer(c_int) :: r
    end function
    function d_c_close(fd) bind(C, name='close') result(r)
      import :: c_int
      integer(c_int), value :: fd
      integer(c_int) :: r
    end function
    function d_c_pread(fd, buf, n, off) bind(C, name='pread') result(r)
      import :: c_int, c_size_t, c_long, c_int8_t
      integer(c_int), value :: fd
      integer(c_int8_t), intent(inout) :: buf(*)
      integer(c_size_t), value :: n
      integer(c_long), value :: off
      integer(c_long) :: r
    end function
    function d_c_read(fd, buf, n) bind(C, name='read') result(r)
      import :: c_int, c_size_t, c_long, c_int8_t
      integer(c_int), value :: fd
      integer(c_int8_t), intent(inout) :: buf(*)
      integer(c_size_t), value :: n
      integer(c_long) :: r
    end function
    function d_c_pwrite(fd, buf, n, off) bind(C, name='pwrite') result(r)
      import :: c_int, c_size_t, c_long, c_int8_t
      integer(c_int), value :: fd
      integer(c_int8_t), intent(in) :: buf(*)
      integer(c_size_t), value :: n
      integer(c_long), value :: off
      integer(c_long) :: r
    end function
    function d_c_write(fd, buf, n) bind(C, name='write') result(r)
      import :: c_int, c_size_t, c_long, c_int8_t
      integer(c_int), value :: fd
      integer(c_int8_t), intent(in) :: buf(*)
      integer(c_size_t), value :: n
      integer(c_long) :: r
    end function
    function d_c_lseek(fd, off, whence) bind(C, name='lseek') result(r)
      import :: c_int, c_long
      integer(c_int), value :: fd
      integer(c_long), value :: off
      integer(c_int), value :: whence
      integer(c_long) :: r
    end function
    function d_c_stat(path, st) bind(C, name='stat') result(r)
      import :: c_char, c_int, c_long
      character(kind=c_char), intent(in) :: path(*)
      integer(c_long), intent(inout) :: st(*)
      integer(c_int) :: r
    end function
    function d_c_lstat(path, st) bind(C, name='lstat') result(r)
      import :: c_char, c_int, c_long
      character(kind=c_char), intent(in) :: path(*)
      integer(c_long), intent(inout) :: st(*)
      integer(c_int) :: r
    end function
    function d_c_fstat(fd, st) bind(C, name='fstat') result(r)
      import :: c_int, c_long
      integer(c_int), value :: fd
      integer(c_long), intent(inout) :: st(*)
      integer(c_int) :: r
    end function
    function d_c_rename(a, b) bind(C, name='rename') result(r)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: a(*), b(*)
      integer(c_int) :: r
    end function
    function d_c_unlink(p) bind(C, name='unlink') result(r)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: p(*)
      integer(c_int) :: r
    end function
    function d_c_rmdir(p) bind(C, name='rmdir') result(r)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: p(*)
      integer(c_int) :: r
    end function
    function d_c_mkdir(p, mode) bind(C, name='mkdir') result(r)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: p(*)
      integer(c_int), value :: mode
      integer(c_int) :: r
    end function
    function d_c_fchmod(fd, mode) bind(C, name='fchmod') result(r)
      import :: c_int
      integer(c_int), value :: fd, mode
      integer(c_int) :: r
    end function
    function d_c_getcwd(buf, n) bind(C, name='getcwd') result(r)
      import :: c_char, c_size_t, c_ptr
      character(kind=c_char), intent(inout) :: buf(*)
      integer(c_size_t), value :: n
      type(c_ptr) :: r
    end function
    function d_c_errno_location() bind(C, name='__errno_location') result(r)
      import :: c_ptr
      type(c_ptr) :: r
    end function
    function d_c_strerror(e) bind(C, name='strerror') result(r)
      import :: c_int, c_ptr
      integer(c_int), value :: e
      type(c_ptr) :: r
    end function
    function d_c_getenv(name) bind(C, name='getenv') result(r)
      import :: c_char, c_ptr
      character(kind=c_char), intent(in) :: name(*)
      type(c_ptr) :: r
    end function
  end interface

contains

  ! ============================================================================================ init
  !> C#'s static fields of this part: Streams.cout, cerr and clog (clog is cerr).
  recursive subroutine cpp_rt_d_init()
    type(cpp_ostream), pointer :: o
    if (associated(cpp_streams_cout)) return
    allocate(o); o%std = 1; cpp_streams_cout => o
    allocate(o); o%std = 2; cpp_streams_cerr => o
    cpp_streams_clog => cpp_streams_cerr
  end subroutine cpp_rt_d_init

  ! ============================================================================================ bytes and text
  !> A byte as 0..255.
  recursive pure function d_u8(b) result(r)
    integer(1), intent(in) :: b
    integer :: r
    r = iand(int(b), 255)
  end function d_u8

  !> 0..255 (or any int: its low 8 bits, C#'s (byte)c) as a byte.
  recursive pure function d_i8(c) result(r)
    integer, intent(in) :: c
    integer(1) :: r
    integer :: x
    x = iand(c, 255)
    if (x > 127) x = x - 256
    r = int(x, 1)
  end function d_i8

  !> The bytes of a Fortran string.
  recursive pure function d_bytes_of(s) result(r)
    character(len=*), intent(in) :: s
    integer(1) :: r(0:len(s) - 1)
    integer :: i
    do i = 1, len(s)
      r(i - 1) = d_i8(ichar(s(i:i)))
    end do
  end function d_bytes_of

  !> n bytes of a(off:) as a Fortran string (C#'s Encoding.Latin1.GetString: one char per byte).
  recursive function d_chars_of(a, off, n) result(s)
    integer(1), intent(in) :: a(0:)
    integer(8), intent(in) :: off, n
    character(len=:), allocatable :: s
    integer(8) :: i
    allocate(character(len=max(n, 0_8)) :: s)
    do i = 1, n
      s(i:i) = char(d_u8(a(off + i - 1)))
    end do
  end function d_chars_of

  !> The bytes of a Str as a Fortran string (the text of C#'s Str.ToString(), one char per byte).
  recursive function d_sbytes(x) result(s)
    class(cpp_str), intent(in) :: x
    character(len=:), allocatable :: s
    if (x%n <= 0) then
      s = ''
    else
      s = d_chars_of(x%b%a, 0_8, int(x%n, 8))
    end if
  end function d_sbytes

  !> A new Str of the bytes of s (C#'s new Str(string) of a Latin-1 string, or new Str(byte[], 0, n)).
  recursive function d_newstr(s) result(zres)
    character(len=*), intent(in) :: s
    class(cpp_str), pointer :: zres
    class(cpp_arr_b), pointer :: a
    integer :: i, n
    n = len(s)
    a => cpp_arr_b_new(int(n + 1, 8))
    do i = 1, n
      a%a(i - 1) = d_i8(ichar(s(i:i)))
    end do
    zres => cpp_str_new_cptr_ul(cpp_cptr(b=a, o=0), int(n, 8))
  end function d_newstr

  !> A new Str of n bytes of a(off:).
  recursive function d_newstr_b(a, off, n) result(zres)
    integer(1), intent(in) :: a(0:)
    integer(8), intent(in) :: off, n
    class(cpp_str), pointer :: zres
    class(cpp_arr_b), pointer :: t
    t => cpp_arr_b_new(n + 1)
    if (n > 0) t%a(0:n - 1) = a(off:off + n - 1)
    zres => cpp_str_new_cptr_ul(cpp_cptr(b=t, o=0), n)
  end function d_newstr_b

  !> strlen of a CPtr (the bytes up to the NUL).
  recursive function d_clen(p) result(n)
    type(cpp_cptr), intent(in) :: p
    integer(8) :: n
    integer(8) :: i, m
    m = size(p%b%a, kind=8)
    i = p%o
    do while (i < m)
      if (p%b%a(i) == 0) exit
      i = i + 1
    end do
    n = i - p%o
  end function d_clen

  !> long.ToString() (InvariantCulture).
  recursive function d_dec(v) result(s)
    integer(8), intent(in) :: v
    character(len=:), allocatable :: s
    s = d_dec16(int(v, 16))
  end function d_dec

  !> ulong.ToString() of the bits of v.
  recursive function d_udec(v) result(s)
    integer(8), intent(in) :: v
    character(len=:), allocatable :: s
    integer(16) :: x
    x = int(v, 16)
    if (x < 0) x = x + 18446744073709551616_16
    s = d_dec16(x)
  end function d_udec

  recursive function d_dec16(v) result(s)
    integer(16), intent(in) :: v
    character(len=:), allocatable :: s
    character(len=48) :: t
    integer(16) :: x
    integer :: k
    x = abs(v)
    k = 48
    do
      t(k:k) = char(48 + int(mod(x, 10_16)))
      x = x / 10_16
      k = k - 1
      if (x == 0) exit
    end do
    if (v < 0) then
      t(k:k) = '-'
      k = k - 1
    end if
    s = t(k + 1:48)
  end function d_dec16

  ! ============================================================================================ .NET strings
  !> The .NET string of Latin-1 text (C#'s Str.ToString(), Encoding.Latin1.GetString), held as UTF-8: the form it
  !> reaches the OS in.
  recursive function d_net(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    character(len=2 * len(s)) :: t
    integer :: i, k, c
    k = 0
    do i = 1, len(s)
      c = ichar(s(i:i))
      if (c < 128) then
        k = k + 1
        t(k:k) = s(i:i)
      else
        t(k + 1:k + 1) = char(ior(192, ishft(c, -6)))
        t(k + 2:k + 2) = char(ior(128, iand(c, 63)))
        k = k + 2
      end if
    end do
    r = t(1:k)
  end function d_net

  !> Encoding.Latin1.GetBytes of a .NET string held as UTF-8: a character above U+00FF becomes '?'.
  recursive function d_latin1(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    character(len=len(s)) :: t
    integer :: i, k, c, cp, need, j
    i = 1
    k = 0
    do while (i <= len(s))
      c = ichar(s(i:i))
      if (c < 128) then
        cp = c
        need = 0
      else if (c < 224) then
        cp = iand(c, 31)
        need = 1
      else if (c < 240) then
        cp = iand(c, 15)
        need = 2
      else
        cp = iand(c, 7)
        need = 3
      end if
      do j = 1, need
        if (i + j <= len(s)) cp = ior(ishft(cp, 6), iand(ichar(s(i + j:i + j)), 63))
      end do
      i = i + 1 + need
      k = k + 1
      if (cp <= 255) then
        t(k:k) = char(cp)
      else
        t(k:k) = '?'
      end if
    end do
    r = t(1:k)
  end function d_latin1

  !> A string .NET reads from the OS (getcwd, environ): UTF-8, each maximal invalid subsequence replaced by U+FFFD.
  recursive function d_netos(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    character(len=3 * len(s)) :: t
    integer :: i, j, k, c, b, need, lo, hi, m
    logical :: ok
    i = 1
    k = 0
    do while (i <= len(s))
      c = ichar(s(i:i))
      if (c < 128) then
        k = k + 1
        t(k:k) = s(i:i)
        i = i + 1
        cycle
      end if
      lo = 128
      hi = 191
      if (c >= 194 .and. c <= 223) then
        need = 1
      else if (c == 224) then
        need = 2
        lo = 160
      else if ((c >= 225 .and. c <= 236) .or. c == 238 .or. c == 239) then
        need = 2
      else if (c == 237) then
        need = 2
        hi = 159
      else if (c == 240) then
        need = 3
        lo = 144
      else if (c >= 241 .and. c <= 243) then
        need = 3
      else if (c == 244) then
        need = 3
        hi = 143
      else
        need = -1
      end if
      if (need < 0) then
        t(k + 1:k + 3) = char(239) // char(191) // char(189)
        k = k + 3
        i = i + 1
        cycle
      end if
      j = i + 1
      ok = .true.
      do m = 1, need
        if (j > len(s)) then
          ok = .false.
          exit
        end if
        b = ichar(s(j:j))
        if (m > 1) then
          lo = 128
          hi = 191
        end if
        if (b < lo .or. b > hi) then
          ok = .false.
          exit
        end if
        j = j + 1
      end do
      if (ok) then
        t(k + 1:k + j - i) = s(i:j - 1)
        k = k + j - i
      else
        t(k + 1:k + 3) = char(239) // char(191) // char(189)
        k = k + 3
      end if
      i = j
    end do
    r = t(1:k)
  end function d_netos

  !> A string .NET reads from the OS (a command-line argument), held as UTF-8 (see d_netos).
  recursive function cpp_net_from_os(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    r = d_netos(s)
  end function cpp_net_from_os

  !> Encoding.Latin1.GetBytes of a .NET string held as UTF-8 ('?' above U+00FF).
  recursive function cpp_net_latin1(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    r = d_latin1(s)
  end function cpp_net_latin1

  !> The bytes R.Lit(string) stores for a .NET string held as UTF-8: the low byte of each UTF-16 unit.
  recursive function cpp_net_lit_bytes(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    character(len=2 * len(s)) :: t
    integer :: i, k, c, cp, need, j
    i = 1
    k = 0
    do while (i <= len(s))
      c = ichar(s(i:i))
      if (c < 128) then
        cp = c
        need = 0
      else if (c < 224) then
        cp = iand(c, 31)
        need = 1
      else if (c < 240) then
        cp = iand(c, 15)
        need = 2
      else
        cp = iand(c, 7)
        need = 3
      end if
      do j = 1, need
        if (i + j <= len(s)) cp = ior(ishft(cp, 6), iand(ichar(s(i + j:i + j)), 63))
      end do
      i = i + 1 + need
      if (cp > 65535) then                       ! a surrogate pair
        cp = cp - 65536
        t(k + 1:k + 1) = char(iand(55296 + ishft(cp, -10), 255))
        t(k + 2:k + 2) = char(iand(56320 + iand(cp, 1023), 255))
        k = k + 2
      else
        k = k + 1
        t(k:k) = char(iand(cp, 255))
      end if
    end do
    r = t(1:k)
  end function cpp_net_lit_bytes

  !> The .NET string of a Str (its bytes as Latin-1), as UTF-8.
  recursive function d_snet(x) result(r)
    class(cpp_str), intent(in) :: x
    character(len=:), allocatable :: r
    r = d_net(d_sbytes(x))
  end function d_snet

  !> A new Str of a .NET string (C#'s new Str(string): Encoding.Latin1).
  recursive function d_strnet(s) result(zres)
    character(len=*), intent(in) :: s
    class(cpp_str), pointer :: zres
    zres => d_newstr(d_latin1(s))
  end function d_strnet

  ! ============================================================================================ C library helpers
  recursive function d_errno() result(e)
    integer(c_int) :: e
    integer(c_int), pointer :: p
    call c_f_pointer(d_c_errno_location(), p)
    e = p
  end function d_errno

  !> A C string as a Fortran string.
  recursive function d_cstring(p) result(s)
    type(c_ptr), intent(in) :: p
    character(len=:), allocatable :: s
    character(kind=c_char), pointer :: a(:)
    integer :: n
    if (.not. c_associated(p)) then
      s = ''
      return
    end if
    call c_f_pointer(p, a, [1048576])
    n = 0
    do while (a(n + 1) /= c_null_char)
      n = n + 1
    end do
    allocate(character(len=n) :: s)
    if (n > 0) s = transfer(a(1:n), s)
  end function d_cstring

  !> strerror(errno): the message of .NET's IOException for an errno it does not map to another exception.
  recursive function d_strerror(e) result(s)
    integer(c_int), intent(in) :: e
    character(len=:), allocatable :: s
    s = d_cstring(d_c_strerror(e))
  end function d_strerror

  !> Set the pending exception to a .NET exception (System.<kind>, the message).
  recursive subroutine d_throw(kind, msg)
    character(len=*), intent(in) :: kind, msg
    class(cpp_sysexception), pointer :: e
    e => cpp_sysexception_new(kind, msg)
    cpp_exc => e
  end subroutine d_throw

  !> The ArgumentException of Path.GetFullPath (err 1: empty, 2: a NUL).
  recursive subroutine d_throw_path(err)
    integer, intent(in) :: err
    if (err == 1) then
      call d_throw('ArgumentException', "The value cannot be an empty string. (Parameter 'path')")
    else
      call d_throw('ArgumentException', "Null character in path. (Parameter 'path')")
    end if
  end subroutine d_throw_path

  !> stat(2), or lstat(2) when stat fails (a broken link): .true. when something is there; mode and size.
  recursive function d_stat(full, mode, sz) result(found)
    character(len=*), intent(in) :: full
    integer(8), intent(out) :: mode, sz
    logical :: found
    integer(c_long) :: st(32)
    st = 0
    found = .true.
    if (d_c_stat(full // c_null_char, st) /= 0) then
      if (d_c_lstat(full // c_null_char, st) /= 0) found = .false.
    end if
    mode = iand(int(st(4), 8), 4294967295_8)      ! st_mode: bytes 24..27 of struct stat (x86-64)
    sz = int(st(7), 8)                            ! st_size: bytes 48..55
  end function d_stat

  recursive function d_fstat(fd, mode, sz) result(ok)
    integer(c_int), intent(in) :: fd
    integer(8), intent(out) :: mode, sz
    logical :: ok
    integer(c_long) :: st(32)
    st = 0
    ok = d_c_fstat(fd, st) == 0
    mode = iand(int(st(4), 8), 4294967295_8)
    sz = int(st(7), 8)
  end function d_fstat

  !> Exact string equality (Fortran's == pads the shorter operand with blanks).
  recursive pure function d_eq(a, b) result(r)
    character(len=*), intent(in) :: a, b
    logical :: r
    r = len(a) == len(b)
    if (r) r = a == b
  end function d_eq

  recursive pure function d_isdir(mode) result(r)
    integer(8), intent(in) :: mode
    logical :: r
    r = iand(mode, S_IFMT) == S_IFDIR
  end function d_isdir

  ! ============================================================================================ Path.GetFullPath
  !> Directory.GetCurrentDirectory: getcwd(3) as a .NET string.
  recursive function d_cwd() result(r)
    character(len=:), allocatable :: r
    character(kind=c_char), allocatable :: buf(:)
    type(c_ptr) :: p
    integer :: n, k
    n = 4096
    do
      allocate(buf(n))
      p = d_c_getcwd(buf, int(n, c_size_t))
      if (c_associated(p)) exit
      deallocate(buf)
      if (d_errno() /= E_RANGE .or. n > 1048576) then
        r = '/'
        return
      end if
      n = n * 2
    end do
    k = 0
    do while (buf(k + 1) /= c_null_char)
      k = k + 1
    end do
    r = d_netos(transfer(buf(1:k), repeat(' ', k)))
  end function d_cwd

  !> Path.GetFullPath on Unix: err 1 for an empty path, 2 for a NUL in it (ArgumentException); a relative path is put
  !> under the current directory (Path.Combine), then PathInternal.RemoveRelativeSegments collapses it.
  recursive function d_fullpath(path, err) result(r)
    character(len=*), intent(in) :: path
    integer, intent(out) :: err
    character(len=:), allocatable :: r, p, c
    err = 0
    r = ''
    if (len(path) == 0) then
      err = 1
      return
    end if
    if (index(path, char(0)) > 0) then
      err = 2
      return
    end if
    if (path(1:1) /= '/') then
      c = d_cwd()
      if (c(len(c):len(c)) == '/') then
        p = c // path
      else
        p = c // '/' // path
      end if
    else
      p = path
    end if
    if (index(p, '//') == 0 .and. index(p, '/.') == 0) then
      r = p                    ! nothing to collapse (the common case)
      return
    end if
    r = d_rmrel(p)
    if (len(r) == 0) r = '/'
  end function d_fullpath

  !> PathInternal.RemoveRelativeSegments (dotnet/runtime) for '/' separators and a root length of 1.
  recursive function d_rmrel(path) result(r)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: r
    character(len=len(path) + 1) :: sb
    integer :: n, i, k, skip, s
    character :: c
    n = len(path)
    skip = 1
    if (path(skip:skip) == '/') skip = skip - 1
    k = skip
    if (k > 0) sb(1:k) = path(1:k)
    i = skip                                    ! 0-based index into path
    do while (i < n)
      c = path(i + 1:i + 1)
      if (c == '/' .and. i + 1 < n) then
        if (at(i + 1) == '/') then
          i = i + 1
          cycle
        end if
        if (at(i + 1) == '.') then
          if (i + 2 == n) then
            i = i + 2
            cycle
          else if (at(i + 2) == '/') then
            i = i + 2
            cycle
          end if
        end if
        if (i + 2 < n) then
          if (at(i + 1) == '.' .and. at(i + 2) == '.') then
            if (i + 3 == n .or. at(i + 3) == '/') then
              s = k - 1
              do while (s >= skip)
                if (sb(s + 1:s + 1) == '/') then
                  if (i + 3 >= n .and. s == skip) then
                    k = s + 1
                  else
                    k = s
                  end if
                  exit
                end if
                s = s - 1
              end do
              if (s < skip) k = skip
              i = i + 3
              cycle
            end if
          end if
        end if
      end if
      k = k + 1
      sb(k:k) = c
      i = i + 1
    end do
    if (skip /= 1 .and. k < 1) then
      k = k + 1
      sb(k:k) = path(1:1)
    end if
    r = sb(1:k)
  contains
    character function at(j)
      integer, intent(in) :: j
      if (j < n) then
        at = path(j + 1:j + 1)
      else
        at = char(0)
      end if
    end function at
  end function d_rmrel

  ! ============================================================================================ existence
  !> FileSystem.FileExists of a full path: something that is not a directory.
  recursive function d_fs_file_exists(full) result(r)
    character(len=*), intent(in) :: full
    logical :: r
    integer(8) :: mode, sz
    r = .false.
    if (len(full) > 1) then
      if (full(len(full):len(full)) == '/') return
    end if
    if (d_stat(full, mode, sz)) r = .not. d_isdir(mode)
  end function d_fs_file_exists

  recursive function d_fs_dir_exists(full) result(r)
    character(len=*), intent(in) :: full
    logical :: r
    integer(8) :: mode, sz
    r = .false.
    if (d_stat(full, mode, sz)) r = d_isdir(mode)
  end function d_fs_dir_exists

  !> System.IO.File.Exists of a .NET string.
  recursive function d_file_exists(path) result(r)
    character(len=*), intent(in) :: path
    logical :: r
    character(len=:), allocatable :: f
    integer :: err
    r = .false.
    if (len(path) == 0) return
    f = d_fullpath(path, err)
    if (err /= 0) return
    if (f(len(f):len(f)) == '/') return
    r = d_fs_file_exists(f)
  end function d_file_exists

  !> System.IO.Directory.Exists of a .NET string.
  recursive function d_dir_exists(path) result(r)
    character(len=*), intent(in) :: path
    logical :: r
    character(len=:), allocatable :: f
    integer :: err
    r = .false.
    if (len(path) == 0) return
    f = d_fullpath(path, err)
    if (err /= 0) return
    r = d_fs_dir_exists(f)
  end function d_dir_exists

  !> Whether the directory of a full path exists (.NET tells a missing directory from a missing file).
  recursive function d_parent_exists(full) result(r)
    character(len=*), intent(in) :: full
    logical :: r
    integer :: k
    k = index(full, '/', back=.true.)
    if (k <= 1) then
      r = d_fs_dir_exists('/')
    else
      r = d_fs_dir_exists(full(1:k - 1))
    end if
  end function d_parent_exists

  ! ============================================================================================ file operations
  !> FileSystem.CopyFile of two full paths: the bytes and the permission bits; a directory source is refused.
  !> err: 0, or the errno of what failed (EISDIR for a directory source).
  recursive function d_copy_full(fa, fb, overwrite) result(err)
    character(len=*), intent(in) :: fa, fb
    logical, intent(in) :: overwrite
    integer :: err
    integer(c_int) :: sfd, dfd, flags, r
    integer(8) :: mode, sz
    integer(c_int8_t), allocatable :: buf(:)
    integer(c_long) :: k, w, done
    err = 0
    sfd = d_c_open(fa // c_null_char, ior(O_RDONLY, O_CLOEXEC), 0_c_int)
    if (sfd < 0) then
      err = d_errno()
      return
    end if
    if (.not. d_fstat(sfd, mode, sz)) then
      err = d_errno()
      r = d_c_close(sfd)
      return
    end if
    if (d_isdir(mode)) then
      err = E_ISDIR
      r = d_c_close(sfd)
      return
    end if
    flags = ior(ior(O_WRONLY, O_CREAT), O_CLOEXEC)
    if (overwrite) then
      flags = ior(flags, O_TRUNC)
    else
      flags = ior(flags, O_EXCL)
    end if
    dfd = d_c_open(fb // c_null_char, flags, int(iand(mode, 4095_8), c_int))
    if (dfd < 0) then
      err = d_errno()
      r = d_c_close(sfd)
      return
    end if
    allocate(buf(1048576))
    do
      k = d_c_read(sfd, buf, int(size(buf), c_size_t))
      if (k < 0) then
        if (d_errno() == E_INTR) cycle
        err = d_errno()
        exit
      end if
      if (k == 0) exit
      done = 0
      do while (done < k)
        w = d_c_write(dfd, buf(done + 1:), int(k - done, c_size_t))
        if (w < 0) then
          if (d_errno() == E_INTR) cycle
          err = d_errno()
          exit
        end if
        done = done + w
      end do
      if (err /= 0) exit
    end do
    if (err == 0) r = d_c_fchmod(dfd, int(iand(mode, 4095_8), c_int))
    r = d_c_close(dfd)
    r = d_c_close(sfd)
  end function d_copy_full

  !> FileSystem.MoveFile(fa, fb, overwrite: true) of two full paths: a directory destination is refused (EISDIR);
  !> rename(2), or copy and delete across file systems (EXDEV). err: 0 or the errno.
  recursive function d_move_full(fa, fb) result(err)
    character(len=*), intent(in) :: fa, fb
    integer :: err
    integer(c_int) :: r
    err = 0
    if (d_fs_dir_exists(fb)) then
      err = E_ISDIR
      return
    end if
    if (d_c_rename(fa // c_null_char, fb // c_null_char) == 0) return
    err = d_errno()
    if (err /= E_XDEV) return
    err = d_copy_full(fa, fb, .true.)
    if (err /= 0) return
    if (d_c_unlink(fa // c_null_char) /= 0) err = d_errno()
    r = 0
  end function d_move_full

  !> File.Move(a, b, overwrite: true) of .NET strings; ok is .false. with the pending exception set when it fails
  !> (FileNotFoundException for a missing source or a missing name in an existing directory,
  !> DirectoryNotFoundException for a missing destination directory, IOException otherwise).
  recursive subroutine d_move_file(a, b)
    character(len=*), intent(in) :: a, b
    character(len=:), allocatable :: fa, fb
    integer :: err
    if (len(a) == 0) then
      call d_throw('ArgumentException', "The value cannot be an empty string. (Parameter 'sourceFileName')")
      return
    end if
    if (len(b) == 0) then
      call d_throw('ArgumentException', "The value cannot be an empty string. (Parameter 'destFileName')")
      return
    end if
    fa = d_fullpath(a, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    fb = d_fullpath(b, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    if (.not. d_fs_file_exists(fa)) then
      call d_throw('IO.FileNotFoundException', "Could not find file '" // d_latin1(fa) // "'.")
      return
    end if
    err = d_move_full(fa, fb)
    if (err == 0) return
    if (err == E_NOENT) then
      if (.not. d_parent_exists(fb)) then
        call d_throw('IO.DirectoryNotFoundException', "Could not find a part of the path '" // d_latin1(fb) // "'.")
      else
        call d_throw('IO.FileNotFoundException', "Could not find file '" // d_latin1(fb) // "'.")
      end if
    else
      call d_throw('IO.IOException', d_strerror(err))
    end if
  end subroutine d_move_file

  !> File.Copy(a, b) without overwrite; the pending exception set when it fails.
  recursive subroutine d_copy_file(a, b)
    character(len=*), intent(in) :: a, b
    character(len=:), allocatable :: fa, fb
    integer :: err
    fa = d_fullpath(a, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    fb = d_fullpath(b, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    err = d_copy_full(fa, fb, .false.)
    if (err == 0) return
    if (err == E_ISDIR) then
      call d_throw('UnauthorizedAccessException', "Access to the path '" // d_latin1(fa) // "' is denied.")
    else if (err == E_NOENT) then
      call d_throw('IO.FileNotFoundException', "Could not find file '" // d_latin1(fa) // "'.")
    else
      call d_throw('IO.IOException', d_strerror(err))
    end if
  end subroutine d_copy_file

  !> File.Delete of a .NET string (a missing file is not an error).
  recursive subroutine d_delete_file(path)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: f
    integer :: err
    f = d_fullpath(path, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    if (d_c_unlink(f // c_null_char) /= 0) then
      err = d_errno()
      if (err /= E_NOENT) call d_throw('IO.IOException', d_strerror(err))
    end if
  end subroutine d_delete_file

  !> Directory.Delete(path), not recursive: rmdir(2).
  recursive subroutine d_delete_dir(path)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: f
    integer :: err
    f = d_fullpath(path, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    if (d_c_rmdir(f // c_null_char) /= 0) call d_throw('IO.IOException', d_strerror(d_errno()))
  end subroutine d_delete_dir

  !> Directory.CreateDirectory: the directory and its missing parents (mode 0777); an existing directory is fine.
  recursive subroutine d_create_dirs(path)
    character(len=*), intent(in) :: path
    character(len=:), allocatable :: f
    integer :: err, k
    integer(c_int) :: r
    f = d_fullpath(path, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    if (d_fs_dir_exists(f)) return
    ! each prefix ending before a '/', and the whole path, made when missing
    do k = 2, len(f)
      if (f(k:k) == '/') cycle
      if (k < len(f)) then
        if (f(k + 1:k + 1) /= '/') cycle
      end if
      if (d_fs_dir_exists(f(1:k))) cycle
      r = d_c_mkdir(f(1:k) // c_null_char, 511_c_int)
      if (r /= 0) then
        err = d_errno()
        if (.not. d_fs_dir_exists(f(1:k))) then
          call d_throw('IO.IOException', d_strerror(err))
          return
        end if
      end if
    end do
  end subroutine d_create_dirs

  !> new FileInfo(path).Length: FileNotFoundException for a missing path or a directory.
  recursive function d_file_length(path) result(n)
    character(len=*), intent(in) :: path
    integer(8) :: n
    character(len=:), allocatable :: f
    integer :: err
    integer(8) :: mode, sz
    logical :: found
    n = 0
    f = d_fullpath(path, err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    found = .false.
    if (.not. (len(f) > 1 .and. f(len(f):len(f)) == '/')) then
      if (d_stat(f, mode, sz)) found = .not. d_isdir(mode)
    end if
    if (.not. found) then
      call d_throw('IO.FileNotFoundException', "Could not find file '" // d_latin1(f) // "'.")
      return
    end if
    n = sz
  end function d_file_length

  !> The FileStream constructor's open: the full path, a directory refused, files created with mode 0666 (less the
  !> umask). The descriptor, or -1 (open failed; .NET throws, the streams catch it).
  recursive function d_open_fd(path, flags) result(fd)
    character(len=*), intent(in) :: path
    integer(c_int), intent(in) :: flags
    integer(c_int) :: fd, r
    character(len=:), allocatable :: full
    integer :: err
    integer(8) :: mode, sz
    fd = -1
    full = d_fullpath(path, err)
    if (err /= 0) return
    if (len(full) > 1) then
      if (full(len(full):len(full)) == '/') return
    end if
    fd = d_c_open(full // c_null_char, ior(flags, O_CLOEXEC), 438_c_int)
    if (fd < 0) then
      fd = -1
      return
    end if
    if (d_fstat(fd, mode, sz)) then
      if (d_isdir(mode)) then
        r = d_c_close(fd)
        fd = -1
      end if
    end if
  end function d_open_fd

  recursive subroutine d_close_fd(fd)
    integer(c_int), intent(in) :: fd
    integer(c_int) :: r
    if (fd >= 0) r = d_c_close(fd)
  end subroutine d_close_fd

  ! ============================================================================================ FileStream (write)
  recursive function d_fo_new(fd, size, append) result(f)
    integer(c_int), intent(in) :: fd
    integer(8), intent(in) :: size
    logical, intent(in) :: append
    type(d_fileout), pointer :: f
    integer(8) :: mode, sz
    allocate(f)
    f%fd = fd
    allocate(f%buf(0:size - 1))
    f%seekable = d_c_lseek(fd, 0_c_long, SEEK_CUR) >= 0
    if (append) then
      if (d_fstat(fd, mode, sz)) f%fpos = sz
      f%append_start = f%fpos
    end if
  end function d_fo_new

  !> Write n bytes of a(off:) at the stream's position (pwrite until done, as RandomAccess.WriteAtOffset).
  recursive subroutine d_fo_raw(f, a, off, n)
    type(d_fileout), intent(inout) :: f
    integer(1), intent(in), contiguous :: a(0:)
    integer(8), intent(in) :: off, n
    integer(8) :: done
    integer(c_long) :: k
    integer(c_int) :: e
    done = 0
    do while (done < n)
      if (f%seekable) then
        k = d_c_pwrite(f%fd, a(off + done:), int(n - done, c_size_t), int(f%fpos, c_long))
      else
        k = d_c_write(f%fd, a(off + done:), int(n - done, c_size_t))
      end if
      if (k < 0) then
        e = d_errno()
        if (e == E_INTR) cycle
        call d_throw('IO.IOException', d_strerror(e))
        return
      end if
      done = done + k
      f%fpos = f%fpos + k
    end do
  end subroutine d_fo_raw

  recursive subroutine d_fo_flushw(f)
    type(d_fileout), intent(inout) :: f
    integer(8) :: k
    if (f%wpos > 0) then
      k = f%wpos
      f%wpos = 0
      call d_fo_raw(f, f%buf, 0_8, k)
    end if
  end subroutine d_fo_flushw

  !> BufferedFileStreamStrategy.WriteSpan.
  recursive subroutine d_fo_write(f, a, off0, n0)
    type(d_fileout), intent(inout) :: f
    integer(1), intent(in), contiguous :: a(0:)
    integer(8), intent(in) :: off0, n0
    integer(8) :: sz, room, off, n
    off = off0
    n = n0
    sz = size(f%buf, kind=8)
    if (f%wpos > 0) then
      room = sz - f%wpos
      if (room > 0) then
        if (room >= n) then
          if (n > 0) f%buf(f%wpos:f%wpos + n - 1) = a(off:off + n - 1)
          f%wpos = f%wpos + n
          return
        end if
        f%buf(f%wpos:f%wpos + room - 1) = a(off:off + room - 1)
        f%wpos = f%wpos + room
        off = off + room
        n = n - room
      end if
      call d_fo_flushw(f)
      if (associated(cpp_exc)) return
    end if
    if (n >= sz) then
      call d_fo_raw(f, a, off, n)
      return
    end if
    if (n == 0) return
    f%buf(0:n - 1) = a(off:off + n - 1)
    f%wpos = n
  end subroutine d_fo_write

  recursive function d_fo_position(f) result(p)
    type(d_fileout), intent(in) :: f
    integer(8) :: p
    p = f%fpos + f%wpos
  end function d_fo_position

  recursive function d_fo_length(f) result(n)
    type(d_fileout), intent(in) :: f
    integer(8) :: n, mode, sz
    sz = 0
    if (.not. d_fstat(f%fd, mode, sz)) sz = 0
    n = max(sz, f%fpos + f%wpos)
  end function d_fo_length

  !> FileStream.Seek: the buffer flushed, then the new position (IOException before 0 or, in append mode, before the
  !> end the file had when it was opened). dir: 0 begin, 1 current, 2 end.
  recursive subroutine d_fo_seek(f, off, dir)
    type(d_fileout), intent(inout) :: f
    integer(8), intent(in) :: off
    integer(4), intent(in) :: dir
    integer(8) :: np
    if (.not. f%seekable) then
      call d_throw('NotSupportedException', 'Stream does not support seeking.')
      return
    end if
    call d_fo_flushw(f)
    if (associated(cpp_exc)) return
    if (dir == 0) then
      np = off
    else if (dir == 2) then
      np = d_fo_length(f) + off
    else
      np = f%fpos + off
    end if
    if (np < 0) then
      call d_throw('IO.IOException', SEEK_BEFORE_BEGIN)
      return
    end if
    if (f%append_start /= -1 .and. np < f%append_start) then
      call d_throw('IO.IOException', SEEK_APPEND)
      return
    end if
    f%fpos = np
  end subroutine d_fo_seek

  !> Dispose: the buffer flushed, the descriptor closed (closed even when the flush fails).
  recursive subroutine d_fo_close(f)
    type(d_fileout), intent(inout) :: f
    call d_fo_flushw(f)
    call d_close_fd(f%fd)
    f%fd = -1
  end subroutine d_fo_close

  ! ============================================================================================ MemoryStream
  recursive function d_ms_new() result(m)
    type(d_memstream), pointer :: m
    allocate(m)
    allocate(m%b(0:-1))
  end function d_ms_new

  recursive subroutine d_ms_write(m, a, off, n)
    type(d_memstream), intent(inout) :: m
    integer(1), intent(in), contiguous :: a(0:)
    integer(8), intent(in) :: off, n
    integer(8) :: e, cap
    integer(1), allocatable :: nb(:)
    if (n <= 0) return
    e = m%pos + n
    if (e > m%len) then
      cap = size(m%b, kind=8)
      if (e > cap) then
        allocate(nb(0:max(max(256_8, e), 2 * cap) - 1))
        if (m%len > 0) nb(0:m%len - 1) = m%b(0:m%len - 1)
        call move_alloc(nb, m%b)
      end if
      if (m%pos > m%len) m%b(m%len:m%pos - 1) = 0
      m%len = e
    end if
    m%b(m%pos:e - 1) = a(off:off + n - 1)
    m%pos = e
  end subroutine d_ms_write

  recursive subroutine d_ms_seek(m, off, dir)
    type(d_memstream), intent(inout) :: m
    integer(8), intent(in) :: off
    integer(4), intent(in) :: dir
    integer(8) :: np
    if (dir == 0) then
      np = off
    else if (dir == 1) then
      np = m%pos + off
    else
      np = m%len + off
    end if
    if (np < 0) then
      call d_throw('IO.IOException', SEEK_BEFORE_BEGIN)
      return
    end if
    if (np > 2147483647_8) then
      call d_throw('ArgumentOutOfRangeException', &
          "Stream length must be non-negative and less than 2^31 - 1 - origin. (Parameter 'offset')")
      return
    end if
    m%pos = np
  end subroutine d_ms_seek

  !> A new Str of the MemoryStream's bytes (Str.FromBytes(mem.ToArray())).
  recursive function d_ms_str(m) result(zres)
    type(d_memstream), intent(in) :: m
    class(cpp_str), pointer :: zres
    zres => d_newstr_b(m%b, 0_8, m%len)
  end function d_ms_str

  ! ============================================================================================ IosBase
  recursive function cpp_iosbase_good(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
    zres = .not. self%failbit .and. .not. self%eofbit .and. .not. self%badbit
  end function cpp_iosbase_good

  recursive function cpp_iosbase_fail(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
    zres = self%failbit .or. self%badbit
  end function cpp_iosbase_fail

  recursive function cpp_iosbase_bad(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
    zres = self%badbit
  end function cpp_iosbase_bad

  recursive function cpp_iosbase_eof(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
    zres = self%eofbit
  end function cpp_iosbase_eof

  recursive function cpp_iosbase_ok(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
    zres = .not. (self%failbit .or. self%badbit)
  end function cpp_iosbase_ok

  recursive function cpp_iosbase_notok(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
    zres = self%failbit .or. self%badbit
  end function cpp_iosbase_notok

  !> clear(state): as in the C# port, every flag is reset whatever the argument.
  recursive subroutine cpp_iosbase_clear(self, a1)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4), value :: a1
    self%failbit = .false.
    self%eofbit = .false.
    self%badbit = .false.
  end subroutine cpp_iosbase_clear

  recursive subroutine cpp_iosbase_imbue(self, a1)
    class(cpp_iosbase), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
  end subroutine cpp_iosbase_imbue

  recursive subroutine cpp_iosbase_exceptions(self, a1)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4), value :: a1
  end subroutine cpp_iosbase_exceptions

  recursive function cpp_iosbase_precision_0(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(8) :: zres
    zres = self%prec
  end function cpp_iosbase_precision_0

  recursive function cpp_iosbase_precision_l(self, a1) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(8), value :: a1
    integer(8) :: zres
    zres = self%prec
    self%prec = a1
  end function cpp_iosbase_precision_l

  recursive function cpp_iosbase_width_0(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(8) :: zres
    zres = self%widthv
  end function cpp_iosbase_width_0

  recursive function cpp_iosbase_width_l(self, a1) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(8), value :: a1
    integer(8) :: zres
    zres = self%widthv
    self%widthv = a1
  end function cpp_iosbase_width_l

  recursive function cpp_iosbase_fill_0(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4) :: zres
    zres = self%fillc
  end function cpp_iosbase_fill_0

  recursive function cpp_iosbase_fill_i(self, a1) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4), value :: a1
    integer(4) :: zres
    zres = self%fillc
    self%fillc = a1
  end function cpp_iosbase_fill_i

  recursive function cpp_iosbase_setf_i(self, a1) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4), value :: a1
    integer(4) :: zres
    zres = self%flagsv
    self%flagsv = ior(self%flagsv, a1)
  end function cpp_iosbase_setf_i

  recursive function cpp_iosbase_setf_i_i(self, a1, a2) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4), value :: a1, a2
    integer(4) :: zres
    zres = self%flagsv
    self%flagsv = ior(iand(self%flagsv, not(a2)), iand(a1, a2))
  end function cpp_iosbase_setf_i_i

  recursive subroutine cpp_iosbase_unsetf(self, a1)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4), value :: a1
    self%flagsv = iand(self%flagsv, not(a1))
  end subroutine cpp_iosbase_unsetf

  ! ============================================================================================ OStream
  !> (s ?? mem)?.Write(b, off, n): the file, a console stream (written through at once, after part C's C file of
  !> the same descriptor is flushed), or the MemoryStream; nothing when there is none.
  recursive subroutine d_os_raw(self, a, off, n)
    class(cpp_ostream), intent(inout) :: self
    integer(1), intent(in), contiguous :: a(0:)
    integer(8), intent(in) :: off, n
    if (associated(self%s)) then
      call d_fo_write(self%s, a, off, n)
    else if (self%std /= 0) then
      call d_std_write(self%std, a, off, n)
    else if (associated(self%mem)) then
      call d_ms_write(self%mem, a, off, n)
    end if
  end subroutine d_os_raw

  recursive subroutine d_std_write(fd, a, off, n)
    integer(4), intent(in) :: fd
    integer(1), intent(in), contiguous :: a(0:)
    integer(8), intent(in) :: off, n
    integer(8) :: done
    integer(c_long) :: k
    integer(4) :: r
    if (n <= 0) return
    if (fd == 1) then
      r = cpp_r_fflush(cpp_r_stdout_x)
    else
      r = cpp_r_fflush(cpp_r_stderr_x)
    end if
    if (associated(cpp_exc)) return
    done = 0
    do while (done < n)
      k = d_c_write(int(fd, c_int), a(off + done:), int(n - done, c_size_t))
      if (k < 0) then
        if (d_errno() == E_INTR) cycle
        call d_throw('IO.IOException', d_strerror(d_errno()))
        return
      end if
      done = done + k
    end do
  end subroutine d_std_write

  !> A formatted field: the fill before it (after it when left-adjusted) up to the width, which resets.
  recursive subroutine d_os_pad(self, body, n)
    class(cpp_ostream), intent(inout) :: self
    integer(1), intent(in), contiguous :: body(0:)
    integer(8), intent(in) :: n
    integer(8) :: w
    integer(1), allocatable :: pad(:)
    w = self%widthv
    self%widthv = 0
    if (n >= w) then
      call d_os_raw(self, body, 0_8, n)
      return
    end if
    allocate(pad(0:w - n - 1))
    pad = d_i8(self%fillc)
    if (iand(self%flagsv, cpp_ios_left) /= 0) then
      call d_os_raw(self, body, 0_8, n)
      if (associated(cpp_exc)) return
      call d_os_raw(self, pad, 0_8, w - n)
    else
      call d_os_raw(self, pad, 0_8, w - n)
      if (associated(cpp_exc)) return
      call d_os_raw(self, body, 0_8, n)
    end if
  end subroutine d_os_pad

  recursive subroutine d_os_text(self, s)
    class(cpp_ostream), intent(inout) :: self
    character(len=*), intent(in) :: s
    integer(1) :: b(0:max(len(s), 1) - 1)
    b(0:len(s) - 1) = d_bytes_of(s)
    call d_os_pad(self, b, int(len(s), 8))
  end subroutine d_os_text

  recursive function cpp_ostream_put_str(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    if (a1%n > 0) then
      call d_os_pad(self, a1%b%a, int(a1%n, 8))
    else
      call d_os_text(self, '')
    end if
  end function cpp_ostream_put_str

  recursive function cpp_ostream_put_cptr(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    integer(8) :: n
    zres => self
    if (.not. associated(a1%b)) then
      call d_throw('NullReferenceException', 'Object reference not set to an instance of an object.')
      return
    end if
    n = d_clen(a1)
    if (n > 0) then
      call d_os_pad(self, a1%b%a(a1%o:), n)
    else
      call d_os_text(self, '')
    end if
  end function cpp_ostream_put_cptr

  recursive function cpp_ostream_put_c(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(1), value :: a1
    class(cpp_ostream), pointer :: zres
    integer(1) :: b(0:0)
    zres => self
    b(0) = a1
    call d_os_pad(self, b, 1_8)
  end function cpp_ostream_put_c

  recursive function cpp_ostream_put_uc(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(1), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => cpp_ostream_put_c(self, a1)
  end function cpp_ostream_put_uc

  recursive function cpp_ostream_put_i(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(4), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    call d_os_text(self, d_dec(int(a1, 8)))
  end function cpp_ostream_put_i

  recursive function cpp_ostream_put_l(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    call d_os_text(self, d_dec(a1))
  end function cpp_ostream_put_l

  recursive function cpp_ostream_put_u(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(4), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    call d_os_text(self, d_dec(iand(int(a1, 8), 4294967295_8)))
  end function cpp_ostream_put_u

  recursive function cpp_ostream_put_ul(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    call d_os_text(self, d_udec(a1))
  end function cpp_ostream_put_ul

  recursive function cpp_ostream_put_s(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(2), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => cpp_ostream_put_i(self, int(a1, 4))
  end function cpp_ostream_put_s

  recursive function cpp_ostream_put_b(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    logical, value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    if (iand(self%flagsv, cpp_ios_boolalpha) /= 0) then
      if (a1) then
        call d_os_text(self, 'true')
      else
        call d_os_text(self, 'false')
      end if
    else
      if (a1) then
        call d_os_text(self, '1')
      else
        call d_os_text(self, '0')
      end if
    end if
  end function cpp_ostream_put_b

  recursive function cpp_ostream_put_f(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    real(4), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => cpp_ostream_put_d(self, real(a1, 8))
  end function cpp_ostream_put_f

  recursive subroutine d_fmt_init()
    if (d_fmt_ready) return
    d_fmt(0, 0) = cpp_r_lit('%.*g')
    d_fmt(1, 0) = cpp_r_lit('%.*f')
    d_fmt(2, 0) = cpp_r_lit('%.*e')
    d_fmt(3, 0) = cpp_r_lit('%a')
    d_fmt(0, 1) = cpp_r_lit('%#.*g')
    d_fmt(1, 1) = cpp_r_lit('%#.*f')
    d_fmt(2, 1) = cpp_r_lit('%#.*e')
    d_fmt(3, 1) = cpp_r_lit('%#a')
    d_fbuf => cpp_arr_b_new(512_8)
    d_fmt_ready = .true.
  end subroutine d_fmt_init

  !> R.Format(fmt, [prec,] v) through R.snprintf into d_fbuf: the length of the text.
  recursive function d_format(fmt, withprec, prec, v) result(n)
    type(cpp_cptr), intent(in) :: fmt
    logical, intent(in) :: withprec
    integer(4), intent(in) :: prec
    real(8), intent(in) :: v
    integer(8) :: n
    integer(4) :: k
    integer :: tries
    n = 0
    do tries = 1, 2
      if (withprec) then
        k = cpp_r_snprintf_cptr_ul_cptr_oa(cpp_cptr(b=d_fbuf, o=0), size(d_fbuf%a, kind=8), fmt, prec, v)
      else
        k = cpp_r_snprintf_cptr_ul_cptr_oa(cpp_cptr(b=d_fbuf, o=0), size(d_fbuf%a, kind=8), fmt, v)
      end if
      if (associated(cpp_exc)) return
      n = k
      if (n < size(d_fbuf%a, kind=8)) return
      d_fbuf => cpp_arr_b_new(n + 1)
    end do
  end function d_format

  !> operator<<(double): libstdc++'s __num_base::_S_format_float: the conversion letter from the floatfield, '#'
  !> for showpoint, the precision.
  recursive function cpp_ostream_put_d(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    real(8), value :: a1
    class(cpp_ostream), pointer :: zres
    logical :: fx, sci
    integer :: sp, k
    integer(8) :: n
    zres => self
    fx = iand(self%flagsv, cpp_ios_fixed) /= 0
    sci = iand(self%flagsv, cpp_ios_scientific) /= 0
    sp = 0
    if (iand(self%flagsv, cpp_ios_showpoint) /= 0) sp = 1
    call d_fmt_init()
    if (fx .and. sci) then
      n = d_format(d_fmt(3, sp), .false., 0_4, a1)
    else
      k = 0
      if (fx) then
        k = 1
      else if (sci) then
        k = 2
      end if
      n = d_format(d_fmt(k, sp), .true., int(self%prec, 4), a1)
    end if
    if (associated(cpp_exc)) return
    call d_os_pad(self, d_fbuf%a, n)
  end function cpp_ostream_put_d

  recursive function cpp_ostream_put_setprec(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_setprec), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    self%prec = a1%n
  end function cpp_ostream_put_setprec

  recursive function cpp_ostream_put_setw(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_setw), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    self%widthv = a1%n
  end function cpp_ostream_put_setw

  recursive function cpp_ostream_put_setfill(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_setfill), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    self%fillc = a1%c
  end function cpp_ostream_put_setfill

  recursive function cpp_ostream_put_ostream(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
  end function cpp_ostream_put_ostream

  recursive function cpp_ostream_manip_endl(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    integer(1) :: nl(0:0)
    zres => self
    nl(0) = 10
    call d_os_raw(self, nl, 0_8, 1_8)
    if (associated(cpp_exc)) return
    zres => cpp_ostream_flush(self)
  end function cpp_ostream_manip_endl

  recursive function cpp_ostream_manip_flush(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => cpp_ostream_flush(self)
  end function cpp_ostream_manip_flush

  recursive function cpp_ostream_manip_setprecision(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    self%prec = a1
  end function cpp_ostream_manip_setprecision

  recursive function cpp_ostream_manip_setw(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    self%widthv = a1
  end function cpp_ostream_manip_setw

  recursive function cpp_ostream_manip_setfill(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(4), value :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    self%fillc = a1
  end function cpp_ostream_manip_setfill

  !> std::quoted(s): s between double quotes, with every '"' and '\' escaped by a backslash; the width applies to
  !> the whole quoted string, as in libstdc++ (__ostream_insert of the built string).
  recursive subroutine d_os_quoted(self, a, off, n)
    class(cpp_ostream), intent(inout) :: self
    integer(1), intent(in) :: a(0:)
    integer(8), intent(in) :: off, n
    integer(1), allocatable :: b(:)
    integer(8) :: i, k
    integer :: c
    allocate(b(0:2 * n + 1))
    k = 0
    b(k) = 34
    k = k + 1
    do i = off, off + n - 1
      c = d_u8(a(i))
      if (c == 34 .or. c == 92) then
        b(k) = 92
        k = k + 1
      end if
      b(k) = a(i)
      k = k + 1
    end do
    b(k) = 34
    k = k + 1
    call d_os_pad(self, b, k)
  end subroutine d_os_quoted

  recursive function cpp_ostream_manip_quoted_str(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    call d_os_quoted(self, a1%b%a, 0_8, int(a1%n, 8))
  end function cpp_ostream_manip_quoted_str

  recursive function cpp_ostream_manip_quoted_cptr(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    class(cpp_ostream), pointer :: zres
    zres => self
    if (.not. associated(a1%b)) then
      call d_throw('NullReferenceException', 'Object reference not set to an instance of an object.')
      return
    end if
    call d_os_quoted(self, a1%b%a, int(a1%o, 8), d_clen(a1))
  end function cpp_ostream_manip_quoted_cptr

  recursive function cpp_ostream_manip_fixed(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = ior(iand(self%flagsv, not(ior(cpp_ios_fixed, cpp_ios_scientific))), cpp_ios_fixed)
  end function cpp_ostream_manip_fixed

  recursive function cpp_ostream_manip_scientific(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = ior(iand(self%flagsv, not(ior(cpp_ios_fixed, cpp_ios_scientific))), cpp_ios_scientific)
  end function cpp_ostream_manip_scientific

  recursive function cpp_ostream_manip_defaultfloat(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = iand(self%flagsv, not(ior(cpp_ios_fixed, cpp_ios_scientific)))
  end function cpp_ostream_manip_defaultfloat

  recursive function cpp_ostream_manip_left(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = ior(iand(self%flagsv, not(ior(cpp_ios_left, cpp_ios_right))), cpp_ios_left)
  end function cpp_ostream_manip_left

  recursive function cpp_ostream_manip_right(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = ior(iand(self%flagsv, not(ior(cpp_ios_left, cpp_ios_right))), cpp_ios_right)
  end function cpp_ostream_manip_right

  recursive function cpp_ostream_manip_boolalpha(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = ior(self%flagsv, cpp_ios_boolalpha)
  end function cpp_ostream_manip_boolalpha

  recursive function cpp_ostream_manip_noboolalpha(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = iand(self%flagsv, not(cpp_ios_boolalpha))
  end function cpp_ostream_manip_noboolalpha

  recursive function cpp_ostream_manip_showpoint(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = ior(self%flagsv, cpp_ios_showpoint)
  end function cpp_ostream_manip_showpoint

  recursive function cpp_ostream_manip_noshowpoint(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    self%flagsv = iand(self%flagsv, not(cpp_ios_showpoint))
  end function cpp_ostream_manip_noshowpoint

  !> write(p, n): n raw bytes.
  recursive function cpp_ostream_write_cptr_l(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
    integer(8) :: n
    zres => self
    n = int(int(a2, 4), 8)
    if (n <= 0) return
    call d_os_raw(self, a1%b%a, int(a1%o, 8), n)
  end function cpp_ostream_write_cptr_l

  ! write((const char*)p, n) of an array of numbers: its first n bytes (Mem.BytesOf: the bytes of the elements from
  ! p, little-endian, as MemoryMarshal.AsBytes of new Span<T>(p.a, p.o, p.a.Length - p.o) sliced to n, with its
  ! checks: NullReferenceException for a pointer without an array (a field pointer), ArgumentOutOfRangeException
  ! when p.o or n is out of range)
  recursive function d_span_ok(alen, o, esz, n) result(ok)
    integer(8), intent(in) :: alen, o, esz, n
    logical :: ok
    ok = o >= 0 .and. o <= alen
    if (ok) ok = n >= 0 .and. n <= (alen - o) * esz
    if (.not. ok) call d_throw('ArgumentOutOfRangeException', 'Specified argument was out of the range of valid values.')
  end function d_span_ok

  recursive subroutine d_throw_nre()
    call d_throw('NullReferenceException', 'Object reference not set to an instance of an object.')
  end subroutine d_throw_nre

  recursive subroutine d_os_write_at(self, addr, n)
    class(cpp_ostream), intent(inout) :: self
    type(c_ptr), intent(in) :: addr
    integer(8), intent(in) :: n
    integer(c_int8_t), pointer, contiguous :: b(:)
    if (n <= 0) return
    call c_f_pointer(addr, b, [n])
    call d_os_raw(self, b, 0_8, n)
  end subroutine d_os_write_at

  recursive function cpp_ostream_write_ptrt_l__b(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_b), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
    integer(8) :: n
    type(c_ptr) :: addr
    zres => self
    n = int(int(a2, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 1_8, n)) return
    if (n <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_os_write_at(self, addr, n)
  end function cpp_ostream_write_ptrt_l__b

  recursive function cpp_ostream_write_ptrt_l__d(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
    integer(8) :: n
    type(c_ptr) :: addr
    zres => self
    n = int(int(a2, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 8_8, n)) return
    if (n <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_os_write_at(self, addr, n)
  end function cpp_ostream_write_ptrt_l__d

  recursive function cpp_ostream_write_ptrt_l__f(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
    integer(8) :: n
    type(c_ptr) :: addr
    zres => self
    n = int(int(a2, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 4_8, n)) return
    if (n <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_os_write_at(self, addr, n)
  end function cpp_ostream_write_ptrt_l__f

  recursive function cpp_ostream_write_ptrt_l__i(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
    integer(8) :: n
    type(c_ptr) :: addr
    zres => self
    n = int(int(a2, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 4_8, n)) return
    if (n <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_os_write_at(self, addr, n)
  end function cpp_ostream_write_ptrt_l__i

  recursive function cpp_ostream_write_ptrt_l__l(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_l), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
    integer(8) :: n
    type(c_ptr) :: addr
    zres => self
    n = int(int(a2, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 8_8, n)) return
    if (n <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_os_write_at(self, addr, n)
  end function cpp_ostream_write_ptrt_l__l

  !> s?.Flush(): a file's buffer reaches the file; a console stream writes through at once.
  recursive function cpp_ostream_flush(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_ostream), pointer :: zres
    zres => self
    if (associated(self%s)) call d_fo_flushw(self%s)
  end function cpp_ostream_flush

  !> The put position: the file's (with what is buffered), the MemoryStream's, 0 with neither.
  recursive function cpp_ostream_tellp(self) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8) :: zres
    zres = 0
    if (associated(self%s)) then
      zres = d_fo_position(self%s)
    else if (self%std /= 0) then
      call d_throw('NotSupportedException', 'Stream does not support seeking.')
    else if (associated(self%mem)) then
      zres = self%mem%pos
    end if
  end function cpp_ostream_tellp

  recursive function cpp_ostream_seekp(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
    class(cpp_ostream), pointer :: zres
    zres => self
    if (associated(self%s)) then
      call d_fo_seek(self%s, a1, a2)
    else if (self%std /= 0) then
      call d_throw('NotSupportedException', 'Stream does not support seeking.')
    else if (associated(self%mem)) then
      call d_ms_seek(self%mem, a1, a2)
    end if
  end function cpp_ostream_seekp

  ! ============================================================================================ OStringStream
  recursive function cpp_ostringstream_new_0() result(zres)
    class(cpp_ostringstream), pointer :: zres
    allocate(zres)
    zres%mem => d_ms_new()
  end function cpp_ostringstream_new_0

  recursive function cpp_ostringstream_new_i(a1) result(zres)
    integer(4), value :: a1
    class(cpp_ostringstream), pointer :: zres
    zres => cpp_ostringstream_new_0()
  end function cpp_ostringstream_new_i

  !> ostringstream(init): init's bytes with the put position at the start, so writes overwrite them.
  recursive function cpp_ostringstream_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_ostringstream), pointer :: zres
    zres => cpp_ostringstream_new_0()
    if (a1%n > 0) call d_ms_write(zres%mem, a1%b%a, 0_8, int(a1%n, 8))
    zres%mem%pos = 0
  end function cpp_ostringstream_new_str

  !> str(): every byte written.
  recursive function cpp_ostringstream_str_0(self) result(zres)
    class(cpp_ostringstream), intent(inout), target :: self
    class(cpp_str), pointer :: zres
    zres => d_ms_str(self%mem)
  end function cpp_ostringstream_str_0

  !> str(x): the contents replaced by x, the put position at its end.
  recursive subroutine cpp_ostringstream_str_str(self, a1)
    class(cpp_ostringstream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    self%mem => d_ms_new()
    if (a1%n > 0) call d_ms_write(self%mem, a1%b%a, 0_8, int(a1%n, 8))
  end subroutine cpp_ostringstream_str_str

  !> The move assignment: the bytes, the precision and the flags (the source is left empty).
  recursive subroutine cpp_ostringstream_movefrom(self, a1)
    class(cpp_ostringstream), intent(inout), target :: self
    class(cpp_ostringstream), pointer, intent(in) :: a1
    self%mem => a1%mem
    self%prec = a1%prec
    self%flagsv = a1%flagsv
    a1%mem => d_ms_new()
  end subroutine cpp_ostringstream_movefrom

  ! ============================================================================================ OFStream
  recursive function cpp_ofstream_new_0() result(zres)
    class(cpp_ofstream), pointer :: zres
    allocate(zres)
  end function cpp_ofstream_new_0

  recursive function cpp_ofstream_new_str_i(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ofstream), pointer :: zres
    allocate(zres)
    call cpp_ofstream_open_str_i(zres, a1, a2)
  end function cpp_ofstream_new_str_i

  recursive function cpp_ofstream_new_cptr_i(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ofstream), pointer :: zres
    class(cpp_str), pointer :: s
    allocate(zres)
    s => cpp_str_new_cptr(a1)
    if (associated(cpp_exc)) return
    call cpp_ofstream_open_str_i(zres, s, a2)
  end function cpp_ofstream_new_cptr_i

  recursive function cpp_ofstream_new_fspath_i(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ofstream), pointer :: zres
    allocate(zres)
    call cpp_ofstream_open_str_i(zres, a1%p, a2)
  end function cpp_ofstream_new_fspath_i

  !> open(path, mode): ios::app appends (FileMode.Append), any other mode creates or truncates (FileMode.Create),
  !> through a FileStream with a 64 KiB buffer; a file that cannot be opened leaves the stream closed with failbit
  !> set. An open stream is closed first (as the passing ports do; the C# leaves the old one to the finalizer).
  recursive subroutine cpp_ofstream_open_str_i(self, a1, a2)
    class(cpp_ofstream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    type(d_fileout), pointer :: old
    integer(c_int) :: fd
    logical :: app
    if (associated(self%s)) then
      old => self%s
      self%s => null()
      call d_fo_close(old)
      if (associated(cpp_exc)) return
    end if
    app = iand(a2, cpp_ios_app) /= 0
    if (app) then
      fd = d_open_fd(d_snet(a1), ior(O_WRONLY, O_CREAT))
    else
      fd = d_open_fd(d_snet(a1), ior(ior(O_WRONLY, O_CREAT), O_TRUNC))
    end if
    if (fd < 0) then
      self%s => null()
      self%failbit = .true.
      return
    end if
    self%s => d_fo_new(fd, STREAM_BUF, app)
    self%failbit = .false.
  end subroutine cpp_ofstream_open_str_i

  recursive subroutine cpp_ofstream_open_fspath_i(self, a1, a2)
    class(cpp_ofstream), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4), value :: a2
    call cpp_ofstream_open_str_i(self, a1%p, a2)
  end subroutine cpp_ofstream_open_fspath_i

  recursive function cpp_ofstream_is_open(self) result(zres)
    class(cpp_ofstream), intent(inout), target :: self
    logical :: zres
    zres = associated(self%s)
  end function cpp_ofstream_is_open

  !> close(): s?.Flush(); s?.Dispose(); s = null (a failing flush leaves the stream as it was).
  recursive subroutine cpp_ofstream_close(self)
    class(cpp_ofstream), intent(inout), target :: self
    type(d_fileout), pointer :: f
    if (.not. associated(self%s)) return
    call d_fo_flushw(self%s)
    if (associated(cpp_exc)) return
    f => self%s
    call d_fo_close(f)
    self%s => null()
  end subroutine cpp_ofstream_close

  !> ~basic_ofstream closes the file.
  recursive subroutine cpp_ofstream_dispose(self)
    class(cpp_ofstream), intent(inout), target :: self
    call cpp_ofstream_close(self)
  end subroutine cpp_ofstream_dispose

  recursive subroutine d_ofstream_dispose_b(self)
    class(cpp_ofstream), intent(inout), target :: self
    call cpp_ofstream_close(self)
  end subroutine d_ofstream_dispose_b

  recursive subroutine cpp_ofstream_movefrom(self, a1)
    class(cpp_ofstream), intent(inout), target :: self
    class(cpp_ofstream), pointer, intent(in) :: a1
    self%s => a1%s
    a1%s => null()
  end subroutine cpp_ofstream_movefrom

  ! ============================================================================================ FStream
  !> std::fstream as the C# port has it: the file opened, or created, for reading and writing (FileMode.OpenOrCreate,
  !> not truncated) and written from its start through a FileStream with the default 4 KiB buffer.
  recursive function cpp_fstream_new_str_i(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_fstream), pointer :: zres
    integer(c_int) :: fd
    allocate(zres)
    fd = d_open_fd(d_snet(a1), ior(O_RDWR, O_CREAT))
    if (fd < 0) then
      zres%failbit = .true.
      return
    end if
    zres%s => d_fo_new(fd, 4096_8, .false.)
  end function cpp_fstream_new_str_i

  recursive function cpp_fstream_is_open(self) result(zres)
    class(cpp_fstream), intent(inout), target :: self
    logical :: zres
    zres = associated(self%s)
  end function cpp_fstream_is_open

  recursive subroutine cpp_fstream_close(self)
    class(cpp_fstream), intent(inout), target :: self
    type(d_fileout), pointer :: f
    if (.not. associated(self%s)) return
    f => self%s
    self%s => null()
    call d_fo_close(f)
  end subroutine cpp_fstream_close

  recursive subroutine cpp_fstream_dispose(self)
    class(cpp_fstream), intent(inout), target :: self
    call cpp_fstream_close(self)
  end subroutine cpp_fstream_dispose

  recursive subroutine d_fstream_dispose_b(self)
    class(cpp_fstream), intent(inout), target :: self
    call cpp_fstream_close(self)
  end subroutine d_fstream_dispose_b

  ! ============================================================================================ IStream
  !> Fill(): more bytes when the buffer is used up (the next block of up to 64 KiB of the file, read at the position
  !> .NET keeps); .false. at the end of the input.
  recursive function d_fill(self) result(ok)
    class(cpp_istream), intent(inout) :: self
    logical :: ok
    integer(c_long) :: k
    if (self%pos < self%len) then
      ok = .true.
      if (self%pos < 0) then
        call d_throw('IndexOutOfRangeException', 'Index was outside the bounds of the array.')
        ok = .false.
      end if
      return
    end if
    ok = .false.
    if (self%src < 0) return
    if (.not. associated(self%buf)) then
      self%buf => cpp_arr_b_new(STREAM_BUF)
    else if (size(self%buf%a) == 0) then
      self%buf => cpp_arr_b_new(STREAM_BUF)
    end if
    do
      if (self%srcseek) then
        k = d_c_pread(self%src, self%buf%a, int(size(self%buf%a), c_size_t), int(self%srcpos, c_long))
      else
        k = d_c_read(self%src, self%buf%a, int(size(self%buf%a), c_size_t))
      end if
      if (k >= 0) exit
      if (d_errno() /= E_INTR) then
        call d_throw('IO.IOException', d_strerror(d_errno()))
        return
      end if
    end do
    self%srcpos = self%srcpos + k
    self%len = int(k, 4)
    self%pos = 0
    ok = self%len > 0
  end function d_fill

  recursive function d_cur(self) result(c)
    class(cpp_istream), intent(in) :: self
    integer :: c
    c = d_u8(self%buf%a(self%pos))
  end function d_cur

  recursive pure function d_isws(c) result(r)
    integer, intent(in) :: c
    logical :: r
    r = c == 32 .or. (c >= 9 .and. c <= 13)
  end function d_isws

  recursive function cpp_istream_peek(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(4) :: zres
    zres = -1
    if (.not. d_fill(self)) then
      if (associated(cpp_exc)) return
      self%eofbit = .true.
      return
    end if
    zres = d_cur(self)
  end function cpp_istream_peek

  !> get(): the next byte, or -1 (eof and fail) at the end.
  recursive function cpp_istream_get_0(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(4) :: zres
    zres = -1
    if (.not. d_fill(self)) then
      if (associated(cpp_exc)) return
      self%eofbit = .true.
      self%failbit = .true.
      return
    end if
    self%gcountv = 1
    zres = d_cur(self)
    self%pos = self%pos + 1
  end function cpp_istream_get_0

  !> get(ref c): the unformatted get of one char.
  recursive function cpp_istream_get_cr_raw(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(1), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    integer(4) :: x
    zres => self
    x = cpp_istream_get_0(self)
    if (associated(cpp_exc)) return
    if (x >= 0) a1 = d_i8(x)
  end function cpp_istream_get_cr_raw

  !> is >> c: whitespace skipped, then one char.
  recursive function cpp_istream_get_cr(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(1), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    integer(4) :: x
    zres => self
    call d_skipws(self)
    if (associated(cpp_exc)) return
    x = cpp_istream_get_0(self)
    if (associated(cpp_exc)) return
    if (x >= 0) a1 = d_i8(x)
  end function cpp_istream_get_cr

  recursive function cpp_istream_ignore(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
    class(cpp_istream), pointer :: zres
    integer(8) :: i
    integer(4) :: c
    zres => self
    i = 0
    do while (i < a1)
      c = cpp_istream_get_0(self)
      if (associated(cpp_exc)) return
      if (c < 0 .or. c == a2) exit
      i = i + 1
    end do
    self%failbit = self%failbit .and. .not. self%eofbit
  end function cpp_istream_ignore

  recursive function cpp_istream_gcount(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8) :: zres
    zres = self%gcountv
  end function cpp_istream_gcount

  !> read(p, n): up to n bytes into p; fewer set eof and fail. gcount is the number read.
  recursive function cpp_istream_read_cptr_l(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
    integer(8) :: got, k, d
    zres => self
    got = 0
    do while (got < a2)
      if (.not. d_fill(self)) exit
      k = min(a2 - got, int(self%len - self%pos, 8))
      d = a1%o + got
      a1%b%a(d:d + k - 1) = self%buf%a(self%pos:self%pos + k - 1)
      self%pos = self%pos + int(k, 4)
      got = got + k
    end do
    if (associated(cpp_exc)) return
    self%gcountv = got
    if (got < a2) then
      self%eofbit = .true.
      self%failbit = .true.
    end if
  end function cpp_istream_read_cptr_l

  ! read((char*)p, n) into an array of numbers: n bytes read into a scratch array, then its first gcount bytes
  ! replace the bytes of the elements from p (Mem.BytesInto, with Mem.Bytes's checks; a last element they cover only
  ! in part keeps its other bytes)
  recursive function d_is_read_tmp(self, n) result(tmp)
    class(cpp_istream), intent(inout) :: self
    integer(8), intent(in) :: n
    class(cpp_arr_b), pointer :: tmp
    class(cpp_istream), pointer :: r
    tmp => cpp_arr_b_new(max(n, 0_8))
    r => cpp_istream_read_cptr_l(self, cpp_cptr(b=tmp, o=0), n)
  end function d_is_read_tmp

  recursive subroutine d_is_put_at(addr, tmp, g)
    type(c_ptr), intent(in) :: addr
    class(cpp_arr_b), intent(in) :: tmp
    integer(8), intent(in) :: g
    integer(c_int8_t), pointer, contiguous :: b(:)
    if (g <= 0) return
    call c_f_pointer(addr, b, [g])
    b(1:g) = tmp%a(0:g - 1)
  end subroutine d_is_put_at

  recursive function cpp_istream_read_ptrt_l__b(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_b), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
    class(cpp_arr_b), pointer :: tmp
    integer(8) :: g
    type(c_ptr) :: addr
    zres => self
    tmp => d_is_read_tmp(self, a2)
    if (associated(cpp_exc)) return
    g = int(int(self%gcountv, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 1_8, g)) return
    if (g <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_is_put_at(addr, tmp, g)
  end function cpp_istream_read_ptrt_l__b

  recursive function cpp_istream_read_ptrt_l__d(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
    class(cpp_arr_b), pointer :: tmp
    integer(8) :: g
    type(c_ptr) :: addr
    zres => self
    tmp => d_is_read_tmp(self, a2)
    if (associated(cpp_exc)) return
    g = int(int(self%gcountv, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 8_8, g)) return
    if (g <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_is_put_at(addr, tmp, g)
  end function cpp_istream_read_ptrt_l__d

  recursive function cpp_istream_read_ptrt_l__f(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
    class(cpp_arr_b), pointer :: tmp
    integer(8) :: g
    type(c_ptr) :: addr
    zres => self
    tmp => d_is_read_tmp(self, a2)
    if (associated(cpp_exc)) return
    g = int(int(self%gcountv, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 4_8, g)) return
    if (g <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_is_put_at(addr, tmp, g)
  end function cpp_istream_read_ptrt_l__f

  recursive function cpp_istream_read_ptrt_l__i(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
    class(cpp_arr_b), pointer :: tmp
    integer(8) :: g
    type(c_ptr) :: addr
    zres => self
    tmp => d_is_read_tmp(self, a2)
    if (associated(cpp_exc)) return
    g = int(int(self%gcountv, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 4_8, g)) return
    if (g <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_is_put_at(addr, tmp, g)
  end function cpp_istream_read_ptrt_l__i

  recursive function cpp_istream_read_ptrt_l__l(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_l), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
    class(cpp_arr_b), pointer :: tmp
    integer(8) :: g
    type(c_ptr) :: addr
    zres => self
    tmp => d_is_read_tmp(self, a2)
    if (associated(cpp_exc)) return
    g = int(int(self%gcountv, 4), 8)
    if (.not. associated(a1%a)) then
      call d_throw_nre()
      return
    end if
    if (.not. d_span_ok(size(a1%a%a, kind=8), a1%o, 8_8, g)) return
    if (g <= 0) return
    addr = c_loc(a1%a%a(a1%o))
    call d_is_put_at(addr, tmp, g)
  end function cpp_istream_read_ptrt_l__l

  !> ReadLine(s, delim): the bytes up to the delimiter (consumed, not stored); at the end of the input eof, and fail
  !> too when nothing at all was read. .true. when anything was read.
  recursive function cpp_istream_readline(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    logical :: zres
    class(cpp_str), pointer :: t
    logical :: any
    integer(4) :: k
    integer(1) :: dl
    call cpp_str_clear(a1)
    any = .false.
    dl = d_i8(a2)
    do
      if (.not. d_fill(self)) then
        zres = .false.
        if (associated(cpp_exc)) return
        self%eofbit = .true.
        if (.not. any) self%failbit = .true.
        zres = any
        return
      end if
      any = .true.
      k = self%pos
      do while (k < self%len)
        if (self%buf%a(k) == dl) exit
        k = k + 1
      end do
      if (k > self%pos) then
        t => cpp_str_append_cptr_ul(a1, cpp_cptr(b=self%buf, o=self%pos), int(k - self%pos, 8))
        if (associated(cpp_exc)) then
          zres = .false.
          return
        end if
      end if
      if (k < self%len) then
        self%pos = k + 1
        zres = .true.
        return
      end if
      self%pos = self%len
    end do
  end function cpp_istream_readline

  recursive subroutine d_skipws(self)
    class(cpp_istream), intent(inout) :: self
    do
      if (.not. d_fill(self)) exit
      if (.not. d_isws(d_cur(self))) exit
      self%pos = self%pos + 1
    end do
  end subroutine d_skipws

  !> Token(): whitespace skipped, then the bytes up to the next whitespace; none sets fail (and eof at the end),
  !> and eof is set when the input ends right after the token.
  recursive subroutine d_token(self, t, n)
    class(cpp_istream), intent(inout) :: self
    integer(1), allocatable, intent(out) :: t(:)
    integer(8), intent(out) :: n
    integer(1), allocatable :: g(:)
    allocate(t(0:63))
    n = 0
    call d_skipws(self)
    if (associated(cpp_exc)) return
    do
      if (.not. d_fill(self)) exit
      if (d_isws(d_cur(self))) exit
      if (n >= size(t, kind=8)) then
        allocate(g(0:2 * n - 1))
        g(0:n - 1) = t(0:n - 1)
        call move_alloc(g, t)
      end if
      t(n) = self%buf%a(self%pos)
      n = n + 1
      self%pos = self%pos + 1
    end do
    if (associated(cpp_exc)) return
    if (n == 0) then
      self%failbit = .true.
      if (.not. d_fill(self)) self%eofbit = .true.
    else if (.not. d_fill(self)) then
      self%eofbit = .true.
    end if
  end subroutine d_token

  recursive function cpp_istream_get_str(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_istream), pointer :: zres
    integer(1), allocatable :: t(:)
    integer(8) :: n
    class(cpp_str), pointer :: s
    zres => self
    call d_token(self, t, n)
    if (associated(cpp_exc)) return
    if (n > 0) then
      s => d_newstr_b(t, 0_8, n)
      call cpp_str_assign_str(a1, s)
    end if
  end function cpp_istream_get_str

  !> is >> std::ws: skip whitespace (eof is set if the input ends there, failbit is not).
  recursive function cpp_istream_manip_ws(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    class(cpp_istream), pointer :: zres
    zres => self
    do
      if (.not. d_fill(self)) then
        if (associated(cpp_exc)) return
        self%eofbit = .true.
        exit
      end if
      if (.not. d_isws(d_cur(self))) exit
      self%pos = self%pos + 1
    end do
  end function cpp_istream_manip_ws

  recursive function cpp_istream_get_dr(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    real(8), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    integer(1), allocatable :: t(:)
    integer(8) :: n
    class(cpp_arr_b), pointer :: b
    type(cpp_cptr) :: p, e
    real(8) :: r
    zres => self
    call d_token(self, t, n)
    if (associated(cpp_exc)) return
    if (n == 0) then
      a1 = 0
      return
    end if
    b => cpp_arr_b_new(n + 1)
    b%a(0:n - 1) = t(0:n - 1)
    p = cpp_cptr(b=b, o=0)
    e = p
    r = cpp_r_strtod_cptr_cptrr(p, e)
    if (associated(cpp_exc)) return
    if (e%o /= n) then
      self%failbit = .true.
      a1 = 0
      return
    end if
    a1 = r
  end function cpp_istream_get_dr

  recursive function cpp_istream_get_fr(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    real(4), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    real(8) :: d
    d = 0
    zres => cpp_istream_get_dr(self, d)
    if (associated(cpp_exc)) return
    a1 = real(d, 4)
  end function cpp_istream_get_fr

  !> R.strtol(p, ref end, 10) of the C# port over the n bytes of a token: whitespace, a sign, decimal digits;
  !> saturated to the range of long. ends: the bytes used (0 when there are no digits).
  recursive function d_strtol(t, n, ends) result(v)
    integer(1), intent(in) :: t(0:)
    integer(8), intent(in) :: n
    integer(8), intent(out) :: ends
    integer(8) :: v
    integer(8) :: i, st
    integer(16) :: x
    logical :: neg
    integer :: c
    i = 0
    do while (i < n)
      c = d_u8(t(i))
      if (.not. (c == 32 .or. (c >= 9 .and. c <= 13))) exit
      i = i + 1
    end do
    neg = .false.
    if (i < n) then
      c = d_u8(t(i))
      if (c == 43 .or. c == 45) then
        neg = c == 45
        i = i + 1
      end if
    end if
    st = i
    x = 0
    do while (i < n)
      c = d_u8(t(i))
      if (c < 48 .or. c > 57) exit
      if (x < 100000000000000000000_16) x = x * 10 + (c - 48)
      i = i + 1
    end do
    if (i == st) then
      ends = 0
      v = 0
      return
    end if
    ends = i
    if (neg) x = -x
    if (x > 9223372036854775807_16) then
      v = huge(0_8)
    else if (x < -9223372036854775807_16 - 1) then
      v = -huge(0_8) - 1
    else
      v = int(x, 8)
    end if
  end function d_strtol

  recursive function cpp_istream_get_ir(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(4), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    integer(1), allocatable :: t(:)
    integer(8) :: n, e, r
    zres => self
    call d_token(self, t, n)
    if (associated(cpp_exc)) return
    if (n == 0) then
      a1 = 0
      return
    end if
    r = d_strtol(t, n, e)
    if (e /= n .or. r < -2147483648_8 .or. r > 2147483647_8) then
      self%failbit = .true.
      if (r < -2147483648_8) then
        a1 = -huge(0_4) - 1
      else if (r > 2147483647_8) then
        a1 = huge(0_4)
      else
        a1 = 0
      end if
      return
    end if
    a1 = int(r, 4)
  end function cpp_istream_get_ir

  recursive function cpp_istream_get_lr(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    integer(1), allocatable :: t(:)
    integer(8) :: n, e, r
    zres => self
    call d_token(self, t, n)
    if (associated(cpp_exc)) return
    if (n == 0) then
      a1 = 0
      return
    end if
    r = d_strtol(t, n, e)
    if (e /= n) then
      self%failbit = .true.
      a1 = 0
      return
    end if
    a1 = r
  end function cpp_istream_get_lr

  !> Get(ref ulong): Get(ref long) and the bits as they are.
  recursive function cpp_istream_get_ulr(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    integer(8) :: x
    x = 0
    zres => cpp_istream_get_lr(self, x)
    if (associated(cpp_exc)) return
    a1 = x
  end function cpp_istream_get_ulr

  !> Get(ref uint): Get(ref long) and its low 32 bits.
  recursive function cpp_istream_get_ur(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(4), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
    integer(8) :: x
    x = 0
    zres => cpp_istream_get_lr(self, x)
    if (associated(cpp_exc)) return
    a1 = int(iand(x, 2147483647_8), 4)
    if (btest(x, 31)) a1 = ibset(a1, 31)
  end function cpp_istream_get_ur

  !> The read position: the file offset of the next byte, or the index in the string.
  recursive function cpp_istream_tellg(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8) :: zres
    if (self%src >= 0) then
      zres = self%srcpos - (self%len - self%pos)
    else
      zres = self%pos
    end if
  end function cpp_istream_tellg

  !> seekg(off, dir): eof cleared; on a file ios::cur is relative to the read position, not to the file's, which is
  !> past the buffered block (the fixed C#), and a position before 0 sets fail.
  recursive function cpp_istream_seekg(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
    class(cpp_istream), pointer :: zres
    integer(8) :: np, mode, sz
    zres => self
    self%eofbit = .false.
    if (self%src >= 0) then
      if (a2 == cpp_ios_beg) then
        np = a1
      else if (a2 == cpp_ios_cur) then
        np = cpp_istream_tellg(self) + a1
      else
        if (.not. d_fstat(self%src, mode, sz)) then
          call d_throw('IO.IOException', d_strerror(d_errno()))
          return
        end if
        np = sz + a1
      end if
      if (np < 0) then
        self%failbit = .true.
        return
      end if
      self%srcpos = np
      self%pos = 0
      self%len = 0
    else
      if (a2 == cpp_ios_beg) then
        self%pos = int(a1, 4)
      else if (a2 == cpp_ios_cur) then
        self%pos = int(self%pos + a1, 4)
      else
        self%pos = int(self%len + a1, 4)
      end if
    end if
  end function cpp_istream_seekg

  ! ============================================================================================ IStringStream
  recursive function cpp_istringstream_new_0() result(zres)
    class(cpp_istringstream), pointer :: zres
    allocate(zres)
  end function cpp_istringstream_new_0

  recursive function cpp_istringstream_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_istringstream), pointer :: zres
    allocate(zres)
    call cpp_istringstream_str_str(zres, a1)
  end function cpp_istringstream_new_str

  recursive function cpp_istringstream_new_str_i(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_istringstream), pointer :: zres
    allocate(zres)
    call cpp_istringstream_str_str(zres, a1)
  end function cpp_istringstream_new_str_i

  !> str(x): a copy of x to read from the start; fail and eof are cleared.
  recursive subroutine cpp_istringstream_str_str(self, a1)
    class(cpp_istringstream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    integer(4) :: n
    n = max(a1%n, 0)
    self%buf => cpp_arr_b_new(int(n, 8))
    if (n > 0) self%buf%a(0:n - 1) = a1%b%a(0:n - 1)
    self%pos = 0
    self%len = n
    self%failbit = .false.
    self%eofbit = .false.
  end subroutine cpp_istringstream_str_str

  recursive function cpp_istringstream_str_0(self) result(zres)
    class(cpp_istringstream), intent(inout), target :: self
    class(cpp_str), pointer :: zres
    if (associated(self%buf) .and. self%len > 0) then
      zres => d_newstr_b(self%buf%a, 0_8, int(self%len, 8))
    else
      zres => d_newstr('')
    end if
  end function cpp_istringstream_str_0

  recursive subroutine cpp_istringstream_movefrom(self, a1)
    class(cpp_istringstream), intent(inout), target :: self
    class(cpp_istringstream), pointer, intent(in) :: a1
    self%buf => a1%buf
    self%pos = a1%pos
    self%len = a1%len
  end subroutine cpp_istringstream_movefrom

  ! ============================================================================================ IFStream
  recursive function cpp_ifstream_new_0() result(zres)
    class(cpp_ifstream), pointer :: zres
    allocate(zres)
  end function cpp_ifstream_new_0

  recursive function cpp_ifstream_new_str_i(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ifstream), pointer :: zres
    allocate(zres)
    call cpp_ifstream_open_str_i(zres, a1, a2)
  end function cpp_ifstream_new_str_i

  recursive function cpp_ifstream_new_cptr_i(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ifstream), pointer :: zres
    class(cpp_str), pointer :: s
    allocate(zres)
    s => cpp_str_new_cptr(a1)
    if (associated(cpp_exc)) return
    call cpp_ifstream_open_str_i(zres, s, a2)
  end function cpp_ifstream_new_cptr_i

  recursive function cpp_ifstream_new_fspath_i(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ifstream), pointer :: zres
    allocate(zres)
    call cpp_ifstream_open_str_i(zres, a1%p, a2)
  end function cpp_ifstream_new_fspath_i

  !> open(path): FileMode.Open, FileAccess.Read; a missing file, or a directory, leaves the stream closed with failbit
  !> set. An open stream is closed first (as the passing ports do).
  recursive subroutine cpp_ifstream_open_str_i(self, a1, a2)
    class(cpp_ifstream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    integer(c_int) :: fd
    if (self%src >= 0) then
      call d_close_fd(self%src)
      self%src = -1
    end if
    fd = d_open_fd(d_snet(a1), O_RDONLY)
    if (fd < 0) then
      self%src = -1
      self%failbit = .true.
      return
    end if
    self%src = fd
    self%srcpos = 0
    self%srcseek = d_c_lseek(fd, 0_c_long, SEEK_CUR) >= 0
    self%failbit = .false.
    self%pos = 0
    self%len = 0
  end subroutine cpp_ifstream_open_str_i

  recursive subroutine cpp_ifstream_open_fspath_i(self, a1, a2)
    class(cpp_ifstream), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4), value :: a2
    call cpp_ifstream_open_str_i(self, a1%p, a2)
  end subroutine cpp_ifstream_open_fspath_i

  recursive function cpp_ifstream_is_open(self) result(zres)
    class(cpp_ifstream), intent(inout), target :: self
    logical :: zres
    zres = self%src >= 0
  end function cpp_ifstream_is_open

  recursive subroutine cpp_ifstream_close(self)
    class(cpp_ifstream), intent(inout), target :: self
    if (self%src >= 0) call d_close_fd(self%src)
    self%src = -1
  end subroutine cpp_ifstream_close

  recursive subroutine cpp_ifstream_dispose(self)
    class(cpp_ifstream), intent(inout), target :: self
    call cpp_ifstream_close(self)
  end subroutine cpp_ifstream_dispose

  recursive subroutine d_ifstream_dispose_b(self)
    class(cpp_ifstream), intent(inout), target :: self
    call cpp_ifstream_close(self)
  end subroutine d_ifstream_dispose_b

  recursive subroutine cpp_ifstream_movefrom(self, a1)
    class(cpp_ifstream), intent(inout), target :: self
    class(cpp_ifstream), pointer, intent(in) :: a1
    self%src = a1%src
    self%srcpos = a1%srcpos
    self%srcseek = a1%srcseek
    self%buf => a1%buf
    self%pos = a1%pos
    self%len = a1%len
    a1%src = -1
  end subroutine cpp_ifstream_movefrom

  ! ============================================================================================ Streams
  recursive function cpp_streams_getline_istream_str(a1, a2) result(zres)
    class(cpp_istream), pointer, intent(in) :: a1
    class(cpp_str), pointer, intent(in) :: a2
    class(cpp_istream), pointer :: zres
    logical :: r
    zres => a1
    r = cpp_istream_readline(a1, a2, 10)
  end function cpp_streams_getline_istream_str

  recursive function cpp_streams_getline_istream_str_c(a1, a2, a3) result(zres)
    class(cpp_istream), pointer, intent(in) :: a1
    class(cpp_str), pointer, intent(in) :: a2
    integer(1), value :: a3
    class(cpp_istream), pointer :: zres
    logical :: r
    zres => a1
    r = cpp_istream_readline(a1, a2, d_u8(a3))
  end function cpp_streams_getline_istream_str_c

  recursive function cpp_streams_getline_istream_str_i(a1, a2, a3) result(zres)
    class(cpp_istream), pointer, intent(in) :: a1
    class(cpp_str), pointer, intent(in) :: a2
    integer(4), value :: a3
    class(cpp_istream), pointer :: zres
    logical :: r
    zres => a1
    r = cpp_istream_readline(a1, a2, iand(a3, 255))
  end function cpp_streams_getline_istream_str_i

  recursive function cpp_streams_setprecision(a1) result(zres)
    integer(4), value :: a1
    class(cpp_setprec), pointer :: zres
    allocate(zres)
    zres%n = a1
  end function cpp_streams_setprecision

  recursive function cpp_streams_setw(a1) result(zres)
    integer(4), value :: a1
    class(cpp_setw), pointer :: zres
    allocate(zres)
    zres%n = a1
  end function cpp_streams_setw

  recursive function cpp_streams_setfill(a1) result(zres)
    integer(4), value :: a1
    class(cpp_setfill), pointer :: zres
    allocate(zres)
    zres%c = a1
  end function cpp_streams_setfill

  ! ============================================================================================ FsPath
  recursive function d_path_of(s) result(zres)
    character(len=*), intent(in) :: s
    class(cpp_fspath), pointer :: zres
    allocate(zres)
    zres%p => d_newstr(s)
  end function d_path_of

  recursive function d_ps(self) result(s)
    class(cpp_fspath), intent(in) :: self
    character(len=:), allocatable :: s
    s = d_sbytes(self%p)
  end function d_ps

  recursive function cpp_fspath_new_0() result(zres)
    class(cpp_fspath), pointer :: zres
    allocate(zres)
    zres%p => cpp_str_new_0()
  end function cpp_fspath_new_0

  recursive function cpp_fspath_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    allocate(zres)
    zres%p => cpp_str_clone(a1)
  end function cpp_fspath_new_str

  recursive function cpp_fspath_new_cptr(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    allocate(zres)
    zres%p => cpp_str_new_cptr(a1)
  end function cpp_fspath_new_cptr

  !> FsPath(string): a Fortran string of the path's bytes.
  recursive function cpp_fspath_new_chars(a1) result(zres)
    character(len=*), intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    zres => d_path_of(a1)
  end function cpp_fspath_new_chars

  recursive function cpp_fspath_clone(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
    allocate(zres)
    zres%p => cpp_str_clone(self%p)
  end function cpp_fspath_clone

  ! ICopy: what the containers call
  recursive function d_fspath_clone_b(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => cpp_fspath_clone(self)
  end function d_fspath_clone_b

  recursive subroutine d_fspath_assign_b(self, other)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    select type (o => other)
    class is (cpp_fspath)
      self%p => cpp_str_clone(o%p)
    end select
  end subroutine d_fspath_assign_b

  recursive subroutine cpp_fspath_clear(self)
    class(cpp_fspath), intent(inout), target :: self
    self%p => cpp_str_new_0()
  end subroutine cpp_fspath_clear

  recursive subroutine cpp_fspath_assign_fspath(self, a1)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    self%p => cpp_str_clone(a1%p)
  end subroutine cpp_fspath_assign_fspath

  recursive subroutine cpp_fspath_assign_str(self, a1)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    self%p => cpp_str_clone(a1)
  end subroutine cpp_fspath_assign_str

  !> MoveFrom(o): p = o.p; o.p = new Str() (a move from itself leaves it empty, as in the C#).
  recursive subroutine cpp_fspath_movefrom(self, a1)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    self%p => a1%p
    a1%p => cpp_str_new_0()
  end subroutine cpp_fspath_movefrom

  !> compare: the bytes, as std::string compares them (the first differing byte, then the length).
  recursive function d_cmp_str(x, y) result(r)
    class(cpp_str), intent(in) :: x, y
    integer(4) :: r
    integer(4) :: i, m, a, b
    m = min(x%n, y%n)
    do i = 0, m - 1
      a = d_u8(x%b%a(i))
      b = d_u8(y%b%a(i))
      if (a /= b) then
        r = merge(-1, 1, a < b)
        return
      end if
    end do
    r = x%n - y%n
  end function d_cmp_str

  recursive function cpp_fspath_compare(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = d_cmp_str(self%p, a1%p)
  end function cpp_fspath_compare

  recursive function cpp_fspath_compareto(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4) :: zres
    zres = d_cmp_str(self%p, a1%p)
  end function cpp_fspath_compareto

  recursive function cpp_fspath_string(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer :: zres
    zres => cpp_str_clone(self%p)
  end function cpp_fspath_string

  recursive function cpp_fspath_generic_string(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer :: zres
    zres => cpp_str_clone(self%p)
  end function cpp_fspath_generic_string

  recursive function cpp_fspath_native(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer :: zres
    zres => cpp_str_clone(self%p)
  end function cpp_fspath_native

  recursive function cpp_fspath_u8string(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer :: zres
    zres => cpp_str_clone(self%p)
  end function cpp_fspath_u8string

  !> The path's bytes as a Fortran string (C#'s ToString(), one char per byte).
  recursive function cpp_fspath_tostring(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    character(len=:), allocatable :: zres
    zres = d_ps(self)
  end function cpp_fspath_tostring

  recursive function cpp_fspath_c_str(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    type(cpp_cptr) :: zres
    zres = cpp_str_c_str(self%p)
  end function cpp_fspath_c_str

  recursive function cpp_fspath_empty(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
    zres = self%p%n == 0
  end function cpp_fspath_empty

  recursive function cpp_fspath_is_absolute(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
    zres = .false.
    if (self%p%n > 0) zres = self%p%b%a(0) == 47
  end function cpp_fspath_is_absolute

  recursive function cpp_fspath_is_relative(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
    zres = .not. cpp_fspath_is_absolute(self)
  end function cpp_fspath_is_relative

  ! the element functions on the path's text (as the C# port's: filename is the part after the last '/')
  recursive function d_filename(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    integer :: i
    i = index(s, '/', back=.true.)
    r = s(i + 1:)
  end function d_filename

  recursive function d_parent(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r
    integer :: i, j
    i = index(s, '/', back=.true.) - 1          ! 0-based index of the last '/'
    if (i < 0) then
      r = ''
    else if (i == 0) then
      r = '/'
    else
      j = i
      do while (j > 0)
        if (s(j:j) /= '/') exit
        j = j - 1
      end do
      if (j == 0) j = 1
      r = s(1:j)
    end if
  end function d_parent

  recursive function d_extension(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r, f
    integer :: i
    f = d_filename(s)
    r = ''
    if (d_eq(f, '.') .or. d_eq(f, '..')) return
    i = index(f, '.', back=.true.) - 1
    if (i <= 0) return
    r = f(i + 1:)
  end function d_extension

  recursive function d_stem(s) result(r)
    character(len=*), intent(in) :: s
    character(len=:), allocatable :: r, f
    integer :: i
    f = d_filename(s)
    if (d_eq(f, '.') .or. d_eq(f, '..')) then
      r = f
      return
    end if
    i = index(f, '.', back=.true.) - 1
    if (i <= 0) then
      r = f
    else
      r = f(1:i)
    end if
  end function d_stem

  recursive function cpp_fspath_filename(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
    zres => d_path_of(d_filename(d_ps(self)))
  end function cpp_fspath_filename

  recursive function cpp_fspath_parent_path(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
    zres => d_path_of(d_parent(d_ps(self)))
  end function cpp_fspath_parent_path

  recursive function cpp_fspath_stem(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
    zres => d_path_of(d_stem(d_ps(self)))
  end function cpp_fspath_stem

  recursive function cpp_fspath_extension(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
    zres => d_path_of(d_extension(d_ps(self)))
  end function cpp_fspath_extension

  recursive function cpp_fspath_has_filename(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
    zres = len(d_filename(d_ps(self))) > 0
  end function cpp_fspath_has_filename

  recursive function cpp_fspath_has_parent_path(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
    zres = len(d_parent(d_ps(self))) > 0
  end function cpp_fspath_has_parent_path

  recursive function cpp_fspath_has_extension(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
    zres = len(d_extension(d_ps(self))) > 0
  end function cpp_fspath_has_extension

  !> replace_extension(ext): the extension removed, then ext added (with a '.' in front unless it has one); a null
  !> or empty ext only removes.
  recursive function cpp_fspath_replace_extension_fspath(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    character(len=:), allocatable :: s, e, x
    s = d_ps(self)
    e = d_extension(s)
    s = s(1:len(s) - len(e))
    if (associated(a1)) then
      if (a1%p%n > 0) then
        x = d_ps(a1)
        if (x(1:1) == '.') then
          s = s // x
        else
          s = s // '.' // x
        end if
      end if
    end if
    self%p => d_newstr(s)
    zres => self
  end function cpp_fspath_replace_extension_fspath

  recursive function cpp_fspath_replace_extension_str(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    class(cpp_fspath), pointer :: e
    e => cpp_fspath_new_str(a1)
    zres => cpp_fspath_replace_extension_fspath(self, e)
  end function cpp_fspath_replace_extension_str

  recursive function cpp_fspath_replace_filename(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    class(cpp_fspath), pointer :: par, j
    par => cpp_fspath_parent_path(self)
    j => cpp_fspath_join_fspath(par, a1)
    self%p => j%p
    zres => self
  end function cpp_fspath_replace_filename

  recursive function cpp_fspath_remove_filename(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
    character(len=:), allocatable :: s
    integer :: i
    s = d_ps(self)
    i = index(s, '/', back=.true.)
    self%p => d_newstr(s(1:i))
    zres => self
  end function cpp_fspath_remove_filename

  !> operator/ : an absolute right side replaces the path; otherwise a separator is added (unless the path ends in
  !> one or the right side is empty).
  recursive function cpp_fspath_join_fspath(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    character(len=:), allocatable :: s
    if (cpp_fspath_is_absolute(a1)) then
      zres => cpp_fspath_clone(a1)
      return
    end if
    s = d_ps(self)
    if (len(s) == 0) then
      zres => cpp_fspath_clone(a1)
      return
    end if
    if (s(len(s):len(s)) /= '/' .and. a1%p%n > 0) s = s // '/'
    zres => d_path_of(s // d_ps(a1))
  end function cpp_fspath_join_fspath

  recursive function cpp_fspath_join_str(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    class(cpp_fspath), pointer :: o
    o => cpp_fspath_new_str(a1)
    zres => cpp_fspath_join_fspath(self, o)
  end function cpp_fspath_join_str

  recursive function cpp_fspath_join_cptr(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    class(cpp_fspath), pointer :: o
    o => cpp_fspath_new_cptr(a1)
    zres => cpp_fspath_join_fspath(self, o)
  end function cpp_fspath_join_cptr

  !> Empty and "." elements dropped, ".." taking the element before it away (dropped at the root), a trailing '/'
  !> kept, "." for an empty result.
  recursive function cpp_fspath_lexically_normal(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
    character(len=:), allocatable :: s, x, r
    integer, allocatable :: ps(:), pe(:)          ! the kept parts: s(ps(k):pe(k))
    integer :: np, i, j, n
    logical :: abs
    s = d_ps(self)
    n = len(s)
    if (n == 0) then
      zres => d_path_of('')
      return
    end if
    abs = s(1:1) == '/'
    allocate(ps(n + 1), pe(n + 1))
    np = 0
    i = 1
    do                                            ! s.Split('/'): every element, empty ones too
      j = index(s(i:), '/')
      if (j == 0) then
        j = n + 1
      else
        j = i + j - 1
      end if
      x = s(i:j - 1)
      if (len(x) == 0 .or. d_eq(x, '.')) then
        ! dropped
      else if (d_eq(x, '..') .and. np > 0 .and. .not. is_dotdot(np)) then
        np = np - 1
      else if (d_eq(x, '..') .and. abs) then
        ! dropped at the root
      else
        np = np + 1
        ps(np) = i
        pe(np) = j - 1
      end if
      if (j > n) exit
      i = j + 1
    end do
    r = ''
    if (abs) r = '/'
    do i = 1, np
      if (i > 1) r = r // '/'
      r = r // s(ps(i):pe(i))
    end do
    if (s(n:n) == '/' .and. np > 0) r = r // '/'
    if (len(r) == 0) r = '.'
    zres => d_path_of(r)
  contains
    logical function is_dotdot(k)
      integer, intent(in) :: k
      is_dotdot = d_eq(s(ps(k):pe(k)), '..')
    end function is_dotdot
  end function cpp_fspath_lexically_normal

  ! ============================================================================================ FileStatus
  !> FileStatus.Of: not found, a regular file or a directory (File.Exists, then Directory.Exists).
  recursive function cpp_filestatus_of(a1) result(zres)
    character(len=*), intent(in) :: a1             ! a .NET string (UTF-8)
    class(cpp_filestatus), pointer :: zres
    allocate(zres)
    if (d_file_exists(a1)) then
      zres%kind = FS_REGULAR
    else if (d_dir_exists(a1)) then
      zres%kind = FS_DIRECTORY
    else
      zres%kind = FS_NOTFOUND
    end if
  end function cpp_filestatus_of

  recursive function cpp_filestatus_type(self) result(zres)
    class(cpp_filestatus), intent(inout), target :: self
    integer(4) :: zres
    zres = self%kind
  end function cpp_filestatus_type

  recursive function cpp_filestatus_clone(self) result(zres)
    class(cpp_filestatus), intent(inout), target :: self
    class(cpp_filestatus), pointer :: zres
    allocate(zres)
    zres%kind = self%kind
  end function cpp_filestatus_clone

  ! ============================================================================================ Fs
  !> System.IO.File.Exists(path) of the engine (path: the bytes of a Str as a Fortran string).
  recursive function cpp_file_exists(a1) result(zres)
    character(len=*), intent(in) :: a1
    logical :: zres
    zres = d_file_exists(d_net(a1))
  end function cpp_file_exists

  !> System.IO.Directory.Exists(path) (path: the bytes of a Str as a Fortran string).
  recursive function cpp_directory_exists(a1) result(zres)
    character(len=*), intent(in) :: a1
    logical :: zres
    zres = d_dir_exists(d_net(a1))
  end function cpp_directory_exists

  recursive function cpp_fs_exists_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    logical :: zres
    character(len=:), allocatable :: s
    s = d_snet(a1%p)
    zres = d_file_exists(s)
    if (.not. zres) zres = d_dir_exists(s)
  end function cpp_fs_exists_fspath

  !> exists(p, ec): exists(p); ec is not touched (the C# port).
  recursive function cpp_fs_exists_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    logical :: zres
    zres = cpp_fs_exists_fspath(a1)
  end function cpp_fs_exists_fspath_errorcode

  recursive function cpp_fs_exists_filestatus(a1) result(zres)
    class(cpp_filestatus), pointer, intent(in) :: a1
    logical :: zres
    zres = a1%kind /= FS_NOTFOUND
  end function cpp_fs_exists_filestatus

  recursive function cpp_fs_is_regular_file_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    logical :: zres
    zres = d_file_exists(d_snet(a1%p))
  end function cpp_fs_is_regular_file_fspath

  recursive function cpp_fs_is_regular_file_filestatus(a1) result(zres)
    class(cpp_filestatus), pointer, intent(in) :: a1
    logical :: zres
    zres = a1%kind == FS_REGULAR
  end function cpp_fs_is_regular_file_filestatus

  recursive function cpp_fs_is_directory_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    logical :: zres
    zres = d_dir_exists(d_snet(a1%p))
  end function cpp_fs_is_directory_fspath

  recursive function cpp_fs_is_directory_filestatus(a1) result(zres)
    class(cpp_filestatus), pointer, intent(in) :: a1
    logical :: zres
    zres = a1%kind == FS_DIRECTORY
  end function cpp_fs_is_directory_filestatus

  recursive function cpp_fs_is_symlink(a1) result(zres)
    class(cpp_filestatus), pointer, intent(in) :: a1
    logical :: zres
    zres = .false.
  end function cpp_fs_is_symlink

  !> new FileInfo(p).Length: a missing file or a directory throws (FileNotFoundException).
  recursive function cpp_fs_file_size_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(8) :: zres
    zres = d_file_length(d_snet(a1%p))
  end function cpp_fs_file_size_fspath

  !> file_size(p, ec): libstdc++ sets ENOENT for a missing file, EISDIR for a directory and returns
  !> static_cast<uintmax_t>(-1) on error.
  recursive function cpp_fs_file_size_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    integer(8) :: zres
    character(len=:), allocatable :: s
    s = d_snet(a1%p)
    if (d_file_exists(s)) then
      a2%v = 0
      zres = d_file_length(s)
      return
    end if
    if (d_dir_exists(s)) then
      a2%v = 21
    else
      a2%v = 2
    end if
    zres = -1
  end function cpp_fs_file_size_fspath_errorcode

  !> remove(p): a file (not a directory); whether one was removed.
  recursive function cpp_fs_remove_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    logical :: zres
    character(len=:), allocatable :: s
    class(cpp_object), pointer :: saved
    zres = .false.
    s = d_snet(a1%p)
    if (d_file_exists(s)) then
      saved => cpp_exc                            ! try { File.Delete } catch (Exception) { }
      cpp_exc => null()
      call d_delete_file(s)
      zres = .not. associated(cpp_exc)
      cpp_exc => saved
    end if
  end function cpp_fs_remove_fspath

  !> remove(p, ec): a file or an empty directory (EACCES = 13 when that fails).
  recursive function cpp_fs_remove_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    logical :: zres
    character(len=:), allocatable :: s
    class(cpp_object), pointer :: saved
    zres = .false.
    a2%v = 0
    s = d_snet(a1%p)
    saved => cpp_exc                              ! try { ... } catch (Exception) { ec.v = 13; }
    cpp_exc => null()
    if (d_file_exists(s)) then
      call d_delete_file(s)
      zres = .true.
    else if (d_dir_exists(s)) then
      call d_delete_dir(s)
      zres = .true.
    end if
    if (associated(cpp_exc)) then
      a2%v = 13
      zres = .false.
    end if
    cpp_exc => saved
  end function cpp_fs_remove_fspath_errorcode

  !> Directory.CreateDirectory: true unless it fails (an existing directory is fine).
  recursive function cpp_fs_create_directories_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    logical :: zres
    class(cpp_object), pointer :: saved
    saved => cpp_exc                              ! try { ...; return true; } catch (Exception) { return false; }
    cpp_exc => null()
    call d_create_dirs(d_snet(a1%p))
    zres = .not. associated(cpp_exc)
    cpp_exc => saved
  end function cpp_fs_create_directories_fspath

  recursive function cpp_fs_create_directories_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    logical :: zres
    a2%v = 0
    zres = cpp_fs_create_directories_fspath(a1)
  end function cpp_fs_create_directories_fspath_errorcode

  recursive function cpp_fs_current_path() result(zres)
    class(cpp_fspath), pointer :: zres
    allocate(zres)
    zres%p => d_strnet(d_cwd())
  end function cpp_fs_current_path

  recursive function cpp_fs_absolute(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    class(cpp_fspath), pointer :: c
    if (cpp_fspath_is_absolute(a1)) then
      zres => cpp_fspath_clone(a1)
    else
      c => cpp_fs_current_path()
      zres => cpp_fspath_join_fspath(c, a1)
    end if
  end function cpp_fs_absolute

  !> canonical and weakly_canonical: Path.GetFullPath (lexical, links left alone; ArgumentException for an empty
  !> path).
  recursive function cpp_fs_weakly_canonical_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    character(len=:), allocatable :: f
    integer :: err
    zres => null()
    f = d_fullpath(d_snet(a1%p), err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    allocate(zres)
    zres%p => d_strnet(f)
  end function cpp_fs_weakly_canonical_fspath

  recursive function cpp_fs_weakly_canonical_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    class(cpp_fspath), pointer :: zres
    a2%v = 0
    zres => cpp_fs_weakly_canonical_fspath(a1)
  end function cpp_fs_weakly_canonical_fspath_errorcode

  recursive function cpp_fs_canonical_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
    zres => cpp_fs_weakly_canonical_fspath(a1)
  end function cpp_fs_canonical_fspath

  recursive function cpp_fs_canonical_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    class(cpp_fspath), pointer :: zres
    if (.not. cpp_fs_exists_fspath(a1)) then
      a2%v = 2
      zres => cpp_fspath_new_0()
      return
    end if
    a2%v = 0
    zres => cpp_fs_canonical_fspath(a1)
  end function cpp_fs_canonical_fspath_errorcode

  !> $TMPDIR, or /tmp when it is not set.
  recursive function cpp_fs_temp_directory_path() result(zres)
    class(cpp_fspath), pointer :: zres
    type(c_ptr) :: p
    p = d_c_getenv('TMPDIR' // c_null_char)
    allocate(zres)
    if (c_associated(p)) then
      zres%p => d_strnet(d_netos(d_cstring(p)))
    else
      zres%p => d_newstr('/tmp')
    end if
  end function cpp_fs_temp_directory_path

  !> rename(a, b): File.Move(a, b, true), which throws when it fails.
  recursive subroutine cpp_fs_rename_fspath_fspath(a1, a2)
    class(cpp_fspath), pointer, intent(in) :: a1, a2
    call d_move_file(d_snet(a1%p), d_snet(a2%p))
  end subroutine cpp_fs_rename_fspath_fspath

  !> rename(a, b, ec): File.Move(a, b, true); FileNotFoundException gives ENOENT (2), anything else (a missing
  !> destination directory included: DirectoryNotFoundException) EACCES (13).
  recursive subroutine cpp_fs_rename_fspath_fspath_errorcode(a1, a2, a3)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer, intent(in) :: a2
    class(cpp_errorcode), pointer, intent(in) :: a3
    character(len=:), allocatable :: fa, fb
    integer :: err
    fa = d_fullpath(d_snet(a1%p), err)
    if (err == 0) fb = d_fullpath(d_snet(a2%p), err)
    if (err /= 0) then
      a3%v = 13
      return
    end if
    if (.not. d_fs_file_exists(fa)) then
      a3%v = 2
      return
    end if
    err = d_move_full(fa, fb)
    if (err == 0) then
      a3%v = 0
    else if (err == E_NOENT) then
      if (d_parent_exists(fb)) then
        a3%v = 2
      else
        a3%v = 13
      end if
    else
      a3%v = 13
    end if
  end subroutine cpp_fs_rename_fspath_fspath_errorcode

  !> The C# port's create_hard_link(target, link, ec): EEXIST (17) when link exists, otherwise a copy of target at
  !> link (ENOENT when that fails).
  recursive subroutine cpp_fs_create_hard_link(a1, a2, a3)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer, intent(in) :: a2
    class(cpp_errorcode), pointer, intent(in) :: a3
    class(cpp_object), pointer :: saved
    if (d_file_exists(d_snet(a2%p))) then
      a3%v = 17
      return
    end if
    saved => cpp_exc                              ! try { File.Copy; ec.v = 0; } catch (Exception) { ec.v = 2; }
    cpp_exc => null()
    call d_copy_file(d_snet(a1%p), d_snet(a2%p))
    if (associated(cpp_exc)) then
      a3%v = 2
    else
      a3%v = 0
    end if
    cpp_exc => saved
  end subroutine cpp_fs_create_hard_link

  !> equivalent(a, b): the two full paths compared (Path.GetFullPath, which throws for an empty path).
  recursive function cpp_fs_equivalent_fspath_fspath(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer, intent(in) :: a2
    logical :: zres
    character(len=:), allocatable :: fa, fb
    integer :: err
    zres = .false.
    fa = d_fullpath(d_snet(a1%p), err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    fb = d_fullpath(d_snet(a2%p), err)
    if (err /= 0) then
      call d_throw_path(err)
      return
    end if
    zres = d_eq(fa, fb)
  end function cpp_fs_equivalent_fspath_fspath

  recursive function cpp_fs_equivalent_fspath_fspath_errorcode(a1, a2, a3) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer, intent(in) :: a2
    class(cpp_errorcode), pointer, intent(in) :: a3
    logical :: zres
    zres = .false.
    if (.not. cpp_fs_exists_fspath(a1) .or. .not. cpp_fs_exists_fspath(a2)) then
      a3%v = 2
      return
    end if
    a3%v = 0
    zres = cpp_fs_equivalent_fspath_fspath(a1, a2)
  end function cpp_fs_equivalent_fspath_fspath_errorcode

  recursive function cpp_fs_status_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_filestatus), pointer :: zres
    zres => cpp_filestatus_of(d_snet(a1%p))
  end function cpp_fs_status_fspath

  recursive function cpp_fs_status_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    class(cpp_filestatus), pointer :: zres
    a2%v = 0
    zres => cpp_filestatus_of(d_snet(a1%p))
  end function cpp_fs_status_fspath_errorcode

  recursive function cpp_fs_symlink_status_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_filestatus), pointer :: zres
    zres => cpp_filestatus_of(d_snet(a1%p))
  end function cpp_fs_symlink_status_fspath

  recursive function cpp_fs_symlink_status_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    class(cpp_filestatus), pointer :: zres
    a2%v = 0
    zres => cpp_filestatus_of(d_snet(a1%p))
  end function cpp_fs_symlink_status_fspath_errorcode

end module cpp_rt_d
