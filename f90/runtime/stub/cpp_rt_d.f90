! cpp_rt_d - STUB of part D of the Fortran runtime (types as the engine sees them, empty bodies), made by
! f90/tools/split_stub.py from the translator's stub. Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
module cpp_rt_d
  use cpp_rt_a
  use cpp_rt_c
  use cpp_rt_b
  implicit none
  type, extends(cpp_object) :: cpp_filestatus
  end type cpp_filestatus
  type, extends(cpp_object) :: cpp_fspath
  end type cpp_fspath
  type, extends(cpp_object) :: cpp_iosbase
  end type cpp_iosbase
  type, extends(cpp_iosbase) :: cpp_istream
  end type cpp_istream
  type, extends(cpp_iosbase) :: cpp_ostream
  end type cpp_ostream
  type, extends(cpp_istream) :: cpp_ifstream
  end type cpp_ifstream
  type, extends(cpp_istream) :: cpp_istringstream
  end type cpp_istringstream
  type, extends(cpp_ostream) :: cpp_ofstream
  end type cpp_ofstream
  type, extends(cpp_ostream) :: cpp_ostringstream
  end type cpp_ostringstream
contains
  recursive function cpp_file_exists(a1) result(zres)
    character(len=*), intent(in) :: a1
    logical :: zres
  end function
  recursive subroutine cpp_fs_create_hard_link(a1, a2, a3)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer, intent(in) :: a2
    class(cpp_errorcode), pointer, intent(in) :: a3
  end subroutine
  recursive function cpp_fs_equivalent_fspath_fspath(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_fs_exists_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_fs_file_size_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(8) :: zres
  end function
  recursive function cpp_fs_file_size_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_fs_is_directory_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    logical :: zres
  end function
  recursive function cpp_fs_is_regular_file_filestatus(a1) result(zres)
    class(cpp_filestatus), pointer, intent(in) :: a1
    logical :: zres
  end function
  recursive function cpp_fs_remove_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive subroutine cpp_fs_rename_fspath_fspath_errorcode(a1, a2, a3)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer, intent(in) :: a2
    class(cpp_errorcode), pointer, intent(in) :: a3
  end subroutine
  recursive function cpp_fs_symlink_status_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_filestatus), pointer :: zres
  end function
  recursive function cpp_fs_symlink_status_fspath_errorcode(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_errorcode), pointer, intent(in) :: a2
    class(cpp_filestatus), pointer :: zres
  end function
  recursive function cpp_fs_weakly_canonical_fspath(a1) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
  end function
  recursive subroutine cpp_fspath_assign_fspath(self, a1)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_fspath_c_str(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    type(cpp_cptr) :: zres
  end function
  recursive subroutine cpp_fspath_clear(self)
    class(cpp_fspath), intent(inout), target :: self
  end subroutine
  recursive function cpp_fspath_clone(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_compare(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_fspath_empty(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_fspath_extension(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_generic_string(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_fspath_is_relative(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_fspath_join_fspath(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_lexically_normal(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
  end function
  recursive subroutine cpp_fspath_movefrom(self, a1)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_fspath_new_0() result(zres)
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_new_cptr(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_parent_path(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_replace_extension_fspath(self, a1) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_fspath), pointer, intent(in) :: a1
    class(cpp_fspath), pointer :: zres
  end function
  recursive function cpp_fspath_string(self) result(zres)
    class(cpp_fspath), intent(inout), target :: self
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_ifstream_is_open(self) result(zres)
    class(cpp_ifstream), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_ifstream_new_fspath_i(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ifstream), pointer :: zres
  end function
  recursive function cpp_ifstream_new_str_i(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ifstream), pointer :: zres
  end function
  recursive function cpp_iosbase_bad(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
  end function
  recursive subroutine cpp_iosbase_clear(self, a1)
    class(cpp_iosbase), intent(inout), target :: self
    integer(4), value :: a1
  end subroutine
  recursive function cpp_iosbase_eof(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_iosbase_good(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
  end function
  recursive subroutine cpp_iosbase_imbue(self, a1)
    class(cpp_iosbase), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_iosbase_notok(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_iosbase_ok(self) result(zres)
    class(cpp_iosbase), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_istream_gcount(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive function cpp_istream_get_dr(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    real(8), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_get_ir(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(4), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_get_str(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_get_ulr(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_get_ur(self, a1) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(4), intent(inout) :: a1
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_manip_ws(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_read_cptr_l(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_read_ptrt_l__b(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_b), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_read_ptrt_l__d(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_read_ptrt_l__f(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_read_ptrt_l__i(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_read_ptrt_l__l(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    type(cpp_ptr_l), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_seekg(self, a1, a2) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_istream_tellg(self) result(zres)
    class(cpp_istream), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive function cpp_istringstream_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_istringstream), pointer :: zres
  end function
  recursive function cpp_istringstream_new_str_i(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_istringstream), pointer :: zres
  end function
  recursive subroutine cpp_ofstream_close(self)
    class(cpp_ofstream), intent(inout), target :: self
  end subroutine
  recursive function cpp_ofstream_is_open(self) result(zres)
    class(cpp_ofstream), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_ofstream_new_0() result(zres)
    class(cpp_ofstream), pointer :: zres
  end function
  recursive function cpp_ofstream_new_cptr_i(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ofstream), pointer :: zres
  end function
  recursive function cpp_ofstream_new_fspath_i(a1, a2) result(zres)
    class(cpp_fspath), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_ofstream), pointer :: zres
  end function
  recursive subroutine cpp_ofstream_open_str_i(self, a1, a2)
    class(cpp_ofstream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
  end subroutine
  recursive function cpp_ostream_manip_quoted_cptr(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_manip_quoted_str(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_manip_setprecision(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8), value :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_put_c(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(1), value :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_put_cptr(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_put_d(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    real(8), value :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_put_i(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(4), value :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_put_str(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_put_ul(self, a1) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    integer(8), value :: a1
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_write_cptr_l(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_write_ptrt_l__d(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_write_ptrt_l__f(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_write_ptrt_l__i(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostream_write_ptrt_l__l(self, a1, a2) result(zres)
    class(cpp_ostream), intent(inout), target :: self
    type(cpp_ptr_l), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_ostream), pointer :: zres
  end function
  recursive function cpp_ostringstream_new_0() result(zres)
    class(cpp_ostringstream), pointer :: zres
  end function
  recursive function cpp_ostringstream_new_i(a1) result(zres)
    integer(4), value :: a1
    class(cpp_ostringstream), pointer :: zres
  end function
  recursive function cpp_ostringstream_str_0(self) result(zres)
    class(cpp_ostringstream), intent(inout), target :: self
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_streams_getline_istream_str(a1, a2) result(zres)
    class(cpp_istream), pointer, intent(in) :: a1
    class(cpp_str), pointer, intent(in) :: a2
    class(cpp_istream), pointer :: zres
  end function
  recursive function cpp_streams_getline_istream_str_c(a1, a2, a3) result(zres)
    class(cpp_istream), pointer, intent(in) :: a1
    class(cpp_str), pointer, intent(in) :: a2
    integer(1), value :: a3
    class(cpp_istream), pointer :: zres
  end function
end module cpp_rt_d
