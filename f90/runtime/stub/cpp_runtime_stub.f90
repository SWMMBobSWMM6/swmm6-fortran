! Stub of the runtime module cpp_runtime, generated from the manifest by tools/cs2x/Cs2F90.cs: types and
! interfaces only, for gfortran -fsyntax-only on the engine. Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
module cpp_runtime
  implicit none
  type :: cpp_object
    integer(4) :: cpp_tag = 0
  contains
    procedure :: clone => cpp_object_clone
    procedure :: assign => cpp_object_assign
    procedure :: dispose => cpp_object_dispose
    procedure :: hash_of => cpp_object_hash_of
    procedure :: call2 => cpp_object_call2
  end type cpp_object
  type :: cpp_slot
    class(*), pointer :: p => null()
  end type cpp_slot
  type :: cpp_u8
    integer(1) :: v = 0
  end type
  type :: cpp_u16
    integer(2) :: v = 0
  end type
  type :: cpp_u32
    integer(4) :: v = 0
  end type
  type :: cpp_u64
    integer(8) :: v = 0
  end type
  class(cpp_object), pointer :: cpp_exc => null()
  abstract interface
    function cpp_maker() result(zres)
      class(*), pointer :: zres
    end function
  end interface
  type, abstract, extends(cpp_object) :: cpp_action
  contains
    procedure(i_cpp_action), deferred :: invoke
  end type cpp_action
  type, abstract, extends(cpp_object) :: cpp_action_d
  contains
    procedure(i_cpp_action_d), deferred :: invoke
  end type cpp_action_d
  type, abstract, extends(cpp_object) :: cpp_action_f
  contains
    procedure(i_cpp_action_f), deferred :: invoke
  end type cpp_action_f
  type, abstract, extends(cpp_object) :: cpp_action_i
  contains
    procedure(i_cpp_action_i), deferred :: invoke
  end type cpp_action_i
  type, abstract, extends(cpp_object) :: cpp_action_l
  contains
    procedure(i_cpp_action_l), deferred :: invoke
  end type cpp_action_l
  type, extends(cpp_object) :: cpp_arr_b
    integer(1), allocatable :: a(:)
  end type cpp_arr_b
  type, extends(cpp_object) :: cpp_arr_d
    real(8), allocatable :: a(:)
  end type cpp_arr_d
  type, extends(cpp_object) :: cpp_arr_f
    real(4), allocatable :: a(:)
  end type cpp_arr_f
  type, extends(cpp_object) :: cpp_arr_i
    integer(4), allocatable :: a(:)
  end type cpp_arr_i
  type, extends(cpp_object) :: cpp_arr_l
    integer(8), allocatable :: a(:)
  end type cpp_arr_l
  type, extends(cpp_object) :: cpp_arr_o
    type(cpp_slot), allocatable :: a(:)
  end type cpp_arr_o
  type, extends(cpp_object) :: cpp_arr_s
    integer(2), allocatable :: a(:)
  end type cpp_arr_s
  type, extends(cpp_object) :: cpp_arr_z
    logical, allocatable :: a(:)
  end type cpp_arr_z
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
  type, extends(cpp_object) :: cpp_cppexception
  end type cpp_cppexception
  type :: cpp_cptr
    class(cpp_arr_b), pointer :: b => null()
    integer(4) :: o = 0
  end type cpp_cptr
  type :: cpp_cspan_o
    class(cpp_arr_o), pointer :: a => null()
    integer(8) :: n = 0_8
    integer(8) :: o = 0_8
  end type cpp_cspan_o
  type, extends(cpp_object) :: cpp_defer
  end type cpp_defer
  type :: cpp_duration
    integer(4) :: cpp_tag = 0
  end type cpp_duration
  type, extends(cpp_object) :: cpp_errorcode
  end type cpp_errorcode
  type, extends(cpp_object) :: cpp_filestatus
  end type cpp_filestatus
  type :: cpp_fromcharsresult
    integer(4) :: ec = 0
    type(cpp_cptr) :: ptr
  end type cpp_fromcharsresult
  type, extends(cpp_object) :: cpp_fspath
  end type cpp_fspath
  type, abstract, extends(cpp_object) :: cpp_func_b_b
  contains
    procedure(i_cpp_func_b_b), deferred :: invoke
  end type cpp_func_b_b
  type, abstract, extends(cpp_object) :: cpp_func_b_z
  contains
    procedure(i_cpp_func_b_z), deferred :: invoke
  end type cpp_func_b_z
  type, abstract, extends(cpp_object) :: cpp_func_d_d_z
  contains
    procedure(i_cpp_func_d_d_z), deferred :: invoke
  end type cpp_func_d_d_z
  type, abstract, extends(cpp_object) :: cpp_func_d_z
  contains
    procedure(i_cpp_func_d_z), deferred :: invoke
  end type cpp_func_d_z
  type, abstract, extends(cpp_object) :: cpp_func_i
  contains
    procedure(i_cpp_func_i), deferred :: invoke
  end type cpp_func_i
  type, abstract, extends(cpp_object) :: cpp_func_i_i_z
  contains
    procedure(i_cpp_func_i_i_z), deferred :: invoke
  end type cpp_func_i_i_z
  type, abstract, extends(cpp_object) :: cpp_func_i_l
  contains
    procedure(i_cpp_func_i_l), deferred :: invoke
  end type cpp_func_i_l
  type, abstract, extends(cpp_object) :: cpp_func_i_z
  contains
    procedure(i_cpp_func_i_z), deferred :: invoke
  end type cpp_func_i_z
  type, abstract, extends(cpp_object) :: cpp_func_l
  contains
    procedure(i_cpp_func_l), deferred :: invoke
  end type cpp_func_l
  type, abstract, extends(cpp_object) :: cpp_func_l_l
  contains
    procedure(i_cpp_func_l_l), deferred :: invoke
  end type cpp_func_l_l
  type, abstract, extends(cpp_object) :: cpp_func_l_l_z
  contains
    procedure(i_cpp_func_l_l_z), deferred :: invoke
  end type cpp_func_l_l_z
  type, abstract, extends(cpp_object) :: cpp_func_o
  contains
    procedure(i_cpp_func_o), deferred :: invoke
  end type cpp_func_o
  type, abstract, extends(cpp_object) :: cpp_func_o_d_z
  contains
    procedure(i_cpp_func_o_d_z), deferred :: invoke
  end type cpp_func_o_d_z
  type, abstract, extends(cpp_object) :: cpp_func_o_l
  contains
    procedure(i_cpp_func_o_l), deferred :: invoke
  end type cpp_func_o_l
  type, abstract, extends(cpp_object) :: cpp_func_o_o_z
  contains
    procedure(i_cpp_func_o_o_z), deferred :: invoke
  end type cpp_func_o_o_z
  type, abstract, extends(cpp_object) :: cpp_func_o_z
  contains
    procedure(i_cpp_func_o_z), deferred :: invoke
  end type cpp_func_o_z
  type, abstract, extends(cpp_object) :: cpp_func_z_z
  contains
    procedure(i_cpp_func_z_z), deferred :: invoke
  end type cpp_func_z_z
  type, extends(cpp_object) :: cpp_hashtable
  end type cpp_hashtable
  type, extends(cpp_object) :: cpp_iosbase
  end type cpp_iosbase
  type :: cpp_iter_b
    integer(4) :: cpp_tag = 0
  end type cpp_iter_b
  type :: cpp_iter_d
    class(cpp_arr_d), pointer :: a => null()
    integer(8) :: i = 0_8
  end type cpp_iter_d
  type :: cpp_iter_f
    integer(4) :: cpp_tag = 0
  end type cpp_iter_f
  type :: cpp_iter_i
    class(cpp_arr_i), pointer :: a => null()
    integer(8) :: i = 0_8
  end type cpp_iter_i
  type :: cpp_iter_l
    class(cpp_arr_l), pointer :: a => null()
    integer(8) :: i = 0_8
  end type cpp_iter_l
  type :: cpp_iter_o
    class(cpp_arr_o), pointer :: a => null()
    integer(8) :: i = 0_8
  end type cpp_iter_o
  type :: cpp_iter_z
    integer(4) :: cpp_tag = 0
  end type cpp_iter_z
  type, extends(cpp_object) :: cpp_less_d
  end type cpp_less_d
  type, extends(cpp_object) :: cpp_less_i
  end type cpp_less_i
  type, extends(cpp_object) :: cpp_less_o
  end type cpp_less_o
  type, extends(cpp_object) :: cpp_lock
  end type cpp_lock
  type, extends(cpp_object) :: cpp_map
  end type cpp_map
  type, abstract, extends(cpp_object) :: cpp_memptr_o_d
  contains
    procedure(i_cpp_memptr_o_d), deferred :: invoke
  end type cpp_memptr_o_d
  type :: cpp_mit
    integer(4) :: cpp_tag = 0
  end type cpp_mit
  type, extends(cpp_object) :: cpp_mutex
  end type cpp_mutex
  type, extends(cpp_object) :: cpp_onceflag
  end type cpp_onceflag
  type, extends(cpp_object) :: cpp_opt_d
    logical :: has = .false.
    real(8) :: val = 0.0_8
  end type cpp_opt_d
  type, extends(cpp_object) :: cpp_opt_o
    logical :: has = .false.
    type(cpp_slot) :: val
  end type cpp_opt_o
  type, extends(cpp_object) :: cpp_pair
    type(cpp_slot) :: first
    type(cpp_slot) :: second
  end type cpp_pair
  type :: cpp_ptr_b
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_b
  type :: cpp_ptr_d
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_d
  type :: cpp_ptr_f
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_f
  type :: cpp_ptr_i
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_i
  type :: cpp_ptr_l
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_l
  type :: cpp_ptr_o
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_o
  type :: cpp_ptr_s
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_s
  type :: cpp_ptr_z
    integer(4) :: cpp_tag = 0
  end type cpp_ptr_z
  type, extends(cpp_object) :: cpp_que
  end type cpp_que
  type :: cpp_raw
    integer(4) :: cpp_tag = 0
  end type cpp_raw
  type, abstract, extends(cpp_object) :: cpp_refat_d
  contains
    procedure(i_cpp_refat_d), deferred :: invoke
  end type cpp_refat_d
  type, abstract, extends(cpp_object) :: cpp_refat_i
  contains
    procedure(i_cpp_refat_i), deferred :: invoke
  end type cpp_refat_i
  type, abstract, extends(cpp_object) :: cpp_refat_l
  contains
    procedure(i_cpp_refat_l), deferred :: invoke
  end type cpp_refat_l
  type, abstract, extends(cpp_object) :: cpp_refat_o
  contains
    procedure(i_cpp_refat_o), deferred :: invoke
  end type cpp_refat_o
  type, extends(cpp_object) :: cpp_refd
  end type cpp_refd
  type, extends(cpp_object) :: cpp_reff
  end type cpp_reff
  type, abstract, extends(cpp_object) :: cpp_refget_z
  contains
    procedure(i_cpp_refget_z), deferred :: invoke
  end type cpp_refget_z
  type, extends(cpp_object) :: cpp_refi
  end type cpp_refi
  type, extends(cpp_object) :: cpp_refl
  end type cpp_refl
  type :: cpp_reviter_o
    integer(4) :: cpp_tag = 0
  end type cpp_reviter_o
  type, extends(cpp_object) :: cpp_scanslot
  end type cpp_scanslot
  type, extends(cpp_object) :: cpp_set
  end type cpp_set
  type, extends(cpp_object) :: cpp_stk
  end type cpp_stk
  type, extends(cpp_object) :: cpp_str
    class(cpp_arr_b), pointer :: b => null()
    integer(4) :: n = 0
  end type cpp_str
  type, extends(cpp_object) :: cpp_sysexception
  end type cpp_sysexception
  type, extends(cpp_object) :: cpp_thread
  end type cpp_thread
  type :: cpp_timepoint
    integer(4) :: cpp_tag = 0
  end type cpp_timepoint
  type, extends(cpp_object) :: cpp_tupn
  end type cpp_tupn
  type, extends(cpp_object) :: cpp_variant
  end type cpp_variant
  type, extends(cpp_object) :: cpp_vec_b
    class(cpp_arr_b), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_b
  type, extends(cpp_object) :: cpp_vec_d
    class(cpp_arr_d), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_d
  type, extends(cpp_object) :: cpp_vec_f
    class(cpp_arr_f), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_f
  type, extends(cpp_object) :: cpp_vec_i
    class(cpp_arr_i), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_i
  type, extends(cpp_object) :: cpp_vec_l
    class(cpp_arr_l), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_l
  type, extends(cpp_object) :: cpp_vec_o
    class(cpp_arr_o), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_o
  type, extends(cpp_object) :: cpp_vec_s
    class(cpp_arr_s), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_s
  type, extends(cpp_object) :: cpp_vec_z
    class(cpp_arr_z), pointer :: a => null()
    integer(4) :: n = 0
  end type cpp_vec_z
  type, extends(cpp_iosbase) :: cpp_istream
  end type cpp_istream
  type, extends(cpp_cppexception) :: cpp_logicerror
  end type cpp_logicerror
  type, extends(cpp_iosbase) :: cpp_ostream
  end type cpp_ostream
  type, extends(cpp_cppexception) :: cpp_runtimeerror
  end type cpp_runtimeerror
  type, extends(cpp_hashtable) :: cpp_umap
  end type cpp_umap
  type, extends(cpp_hashtable) :: cpp_uset
  end type cpp_uset
  type, extends(cpp_istream) :: cpp_ifstream
  end type cpp_ifstream
  type, extends(cpp_logicerror) :: cpp_invalidargument
  end type cpp_invalidargument
  type, extends(cpp_istream) :: cpp_istringstream
  end type cpp_istringstream
  type, extends(cpp_ostream) :: cpp_ofstream
  end type cpp_ofstream
  type, extends(cpp_ostream) :: cpp_ostringstream
  end type cpp_ostringstream
  type, extends(cpp_logicerror) :: cpp_outofrange
  end type cpp_outofrange
  type, extends(cpp_umap) :: cpp_umapc
  end type cpp_umapc
  class(cpp_func_d_d_z), pointer :: cpp_less_d_d_fn
  class(cpp_func_i_i_z), pointer :: cpp_less_i_i_fn
  class(cpp_func_o_o_z), pointer :: cpp_less_o_pairistr_fn
  class(cpp_scanslot), pointer :: cpp_r_slot
  class(cpp_cfile), pointer :: cpp_r_stderr_x
  class(cpp_cfile), pointer :: cpp_r_stdout_x
  type(cpp_raw), target :: cpp_raw_v
  real(8), target :: cpp_std_qnan
  abstract interface
    recursive subroutine i_cpp_action(self)
      import
      class(cpp_action), intent(inout), target :: self
    end subroutine i_cpp_action
    recursive subroutine i_cpp_action_d(self, a1)
      import
      class(cpp_action_d), intent(inout), target :: self
      real(8), value :: a1
    end subroutine i_cpp_action_d
    recursive subroutine i_cpp_action_f(self, a1)
      import
      class(cpp_action_f), intent(inout), target :: self
      real(4), value :: a1
    end subroutine i_cpp_action_f
    recursive subroutine i_cpp_action_i(self, a1)
      import
      class(cpp_action_i), intent(inout), target :: self
      integer(4), value :: a1
    end subroutine i_cpp_action_i
    recursive subroutine i_cpp_action_l(self, a1)
      import
      class(cpp_action_l), intent(inout), target :: self
      integer(8), value :: a1
    end subroutine i_cpp_action_l
    recursive function i_cpp_func_b_b(self, a1) result(zres)
      import
      class(cpp_func_b_b), intent(inout), target :: self
      integer(1), value :: a1
      integer(1) :: zres
    end function i_cpp_func_b_b
    recursive function i_cpp_func_b_z(self, a1) result(zres)
      import
      class(cpp_func_b_z), intent(inout), target :: self
      integer(1), value :: a1
      logical :: zres
    end function i_cpp_func_b_z
    recursive function i_cpp_func_d_d_z(self, a1, a2) result(zres)
      import
      class(cpp_func_d_d_z), intent(inout), target :: self
      real(8), value :: a1
      real(8), value :: a2
      logical :: zres
    end function i_cpp_func_d_d_z
    recursive function i_cpp_func_d_z(self, a1) result(zres)
      import
      class(cpp_func_d_z), intent(inout), target :: self
      real(8), value :: a1
      logical :: zres
    end function i_cpp_func_d_z
    recursive function i_cpp_func_i(self) result(zres)
      import
      class(cpp_func_i), intent(inout), target :: self
      integer(4) :: zres
    end function i_cpp_func_i
    recursive function i_cpp_func_i_i_z(self, a1, a2) result(zres)
      import
      class(cpp_func_i_i_z), intent(inout), target :: self
      integer(4), value :: a1
      integer(4), value :: a2
      logical :: zres
    end function i_cpp_func_i_i_z
    recursive function i_cpp_func_i_l(self, a1) result(zres)
      import
      class(cpp_func_i_l), intent(inout), target :: self
      integer(4), value :: a1
      integer(8) :: zres
    end function i_cpp_func_i_l
    recursive function i_cpp_func_i_z(self, a1) result(zres)
      import
      class(cpp_func_i_z), intent(inout), target :: self
      integer(4), value :: a1
      logical :: zres
    end function i_cpp_func_i_z
    recursive function i_cpp_func_l(self) result(zres)
      import
      class(cpp_func_l), intent(inout), target :: self
      integer(8) :: zres
    end function i_cpp_func_l
    recursive function i_cpp_func_l_l(self, a1) result(zres)
      import
      class(cpp_func_l_l), intent(inout), target :: self
      integer(8), value :: a1
      integer(8) :: zres
    end function i_cpp_func_l_l
    recursive function i_cpp_func_l_l_z(self, a1, a2) result(zres)
      import
      class(cpp_func_l_l_z), intent(inout), target :: self
      integer(8), value :: a1
      integer(8), value :: a2
      logical :: zres
    end function i_cpp_func_l_l_z
    recursive function i_cpp_func_o(self) result(zres)
      import
      class(cpp_func_o), intent(inout), target :: self
      class(*), pointer :: zres
    end function i_cpp_func_o
    recursive function i_cpp_func_o_d_z(self, a1, a2) result(zres)
      import
      class(cpp_func_o_d_z), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      real(8), value :: a2
      logical :: zres
    end function i_cpp_func_o_d_z
    recursive function i_cpp_func_o_l(self, a1) result(zres)
      import
      class(cpp_func_o_l), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      integer(8) :: zres
    end function i_cpp_func_o_l
    recursive function i_cpp_func_o_o_z(self, a1, a2) result(zres)
      import
      class(cpp_func_o_o_z), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      class(*), pointer, intent(in) :: a2
      logical :: zres
    end function i_cpp_func_o_o_z
    recursive function i_cpp_func_o_z(self, a1) result(zres)
      import
      class(cpp_func_o_z), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      logical :: zres
    end function i_cpp_func_o_z
    recursive function i_cpp_func_z_z(self, a1) result(zres)
      import
      class(cpp_func_z_z), intent(inout), target :: self
      logical, value :: a1
      logical :: zres
    end function i_cpp_func_z_z
    recursive function i_cpp_memptr_o_d(self, a1) result(zres)
      import
      class(cpp_memptr_o_d), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      real(8), pointer :: zres
    end function i_cpp_memptr_o_d
    recursive function i_cpp_refat_d(self, a1) result(zres)
      import
      class(cpp_refat_d), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      real(8), pointer :: zres
    end function i_cpp_refat_d
    recursive function i_cpp_refat_i(self, a1) result(zres)
      import
      class(cpp_refat_i), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      integer(4), pointer :: zres
    end function i_cpp_refat_i
    recursive function i_cpp_refat_l(self, a1) result(zres)
      import
      class(cpp_refat_l), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      integer(8), pointer :: zres
    end function i_cpp_refat_l
    recursive function i_cpp_refat_o(self, a1) result(zres)
      import
      class(cpp_refat_o), intent(inout), target :: self
      class(*), pointer, intent(in) :: a1
      type(cpp_slot), pointer :: zres
    end function i_cpp_refat_o
    recursive function i_cpp_refget_z(self) result(zres)
      import
      class(cpp_refget_z), intent(inout), target :: self
      logical, pointer :: zres
    end function i_cpp_refget_z
  end interface
contains
  function cpp_object_clone(self) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    zres => self
  end function
  subroutine cpp_object_assign(self, other)
    class(cpp_object), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
  end subroutine
  subroutine cpp_object_dispose(self)
    class(cpp_object), intent(inout), target :: self
  end subroutine
  function cpp_object_hash_of(self, k) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(*), pointer, intent(in) :: k
    integer(8) :: zres
    zres = 0
  end function
  function cpp_object_call2(self, a, b) result(zres)
    class(cpp_object), intent(inout), target :: self
    class(*), pointer, intent(in) :: a, b
    logical :: zres
    zres = .false.
  end function
  recursive function cpp_algo_accumulate_iterd_iterd_d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
    real(8) :: zres
  end function
  recursive function cpp_algo_all_of__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    class(cpp_func_d_z), pointer, intent(in) :: a3
    logical :: zres
  end function
  recursive function cpp_algo_all_of__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    logical :: zres
  end function
  recursive function cpp_algo_any_of__b(a1, a2, a3) result(zres)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    class(cpp_func_b_z), pointer, intent(in) :: a3
    logical :: zres
  end function
  recursive function cpp_algo_any_of__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    class(cpp_func_d_z), pointer, intent(in) :: a3
    logical :: zres
  end function
  recursive function cpp_algo_any_of__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_func_i_z), pointer, intent(in) :: a3
    logical :: zres
  end function
  recursive function cpp_algo_any_of__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    logical :: zres
  end function
  recursive function cpp_algo_any_of__z(a1, a2, a3) result(zres)
    type(cpp_iter_z), intent(in) :: a1
    type(cpp_iter_z), intent(in) :: a2
    class(cpp_func_z_z), pointer, intent(in) :: a3
    logical :: zres
  end function
  recursive function cpp_algo_begin_ta__d(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_algo_begin_ta__z(a1) result(zres)
    class(cpp_arr_z), pointer, intent(in) :: a1
    type(cpp_iter_z) :: zres
  end function
  recursive function cpp_algo_copy_itert_itert_itert__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    type(cpp_iter_d), intent(in) :: a3
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_algo_copy_n_ptrt_ul_ptrt__d(a1, a2, a3) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_d), intent(in) :: a3
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_algo_count__b(a1, a2, a3) result(zres)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    integer(1), value :: a3
    integer(8) :: zres
  end function
  recursive function cpp_algo_end_ta__d(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_algo_end_ta__z(a1) result(zres)
    class(cpp_arr_z), pointer, intent(in) :: a1
    type(cpp_iter_z) :: zres
  end function
  recursive subroutine cpp_algo_fill_itert_itert_t__b(a1, a2, a3)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    integer(1), value :: a3
  end subroutine
  recursive subroutine cpp_algo_fill_itert_itert_t__d(a1, a2, a3)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
  end subroutine
  recursive subroutine cpp_algo_fill_itert_itert_t__f(a1, a2, a3)
    type(cpp_iter_f), intent(in) :: a1
    type(cpp_iter_f), intent(in) :: a2
    real(4), value :: a3
  end subroutine
  recursive subroutine cpp_algo_fill_itert_itert_t__i(a1, a2, a3)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    integer(4), value :: a3
  end subroutine
  recursive subroutine cpp_algo_fill_itert_itert_t__z(a1, a2, a3)
    type(cpp_iter_z), intent(in) :: a1
    type(cpp_iter_z), intent(in) :: a2
    logical, value :: a3
  end subroutine
  recursive function cpp_algo_fill_n_ptrt_ul_t__d(a1, a2, a3) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    real(8), value :: a3
    type(cpp_ptr_d) :: zres
  end function
  recursive subroutine cpp_algo_fill_ptrt_ptrt_t__d(a1, a2, a3)
    type(cpp_ptr_d), intent(in) :: a1
    type(cpp_ptr_d), intent(in) :: a2
    real(8), value :: a3
  end subroutine
  recursive function cpp_algo_find__b(a1, a2, a3) result(zres)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    integer(1), value :: a3
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_algo_find__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(*), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_algo_find_if__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_iter_o) :: zres
  end function
  recursive subroutine cpp_algo_iota_iterul_iterul_ul(a1, a2, a3)
    type(cpp_iter_l), intent(in) :: a1
    type(cpp_iter_l), intent(in) :: a2
    integer(8), value :: a3
  end subroutine
  recursive function cpp_algo_is_sorted_itert_itert__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_algo_lower_bound_itert_itert_t__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_algo_lower_bound_itert_itert_t__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    integer(4), value :: a3
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_algo_lower_bound_itert_itert_v_functvb__od(a1, a2, a3, a4, mk5, cm6) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    real(8), value :: a3
    class(cpp_func_o_d_z), pointer, intent(in) :: a4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_algo_max_element_itert_itert__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_algo_min_element_itert_itert__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_algo_none_of__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_func_i_z), pointer, intent(in) :: a3
    logical :: zres
  end function
  recursive function cpp_algo_none_of__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    logical :: zres
  end function
  recursive subroutine cpp_algo_replace__b(a1, a2, a3, a4)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    integer(1), value :: a3
    integer(1), value :: a4
  end subroutine
  recursive function cpp_algo_transform_itert_itert_iteru_functu__bb(a1, a2, a3, a4) result(zres)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    type(cpp_iter_b), intent(in) :: a3
    class(cpp_func_b_b), pointer, intent(in) :: a4
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_algo_transform_iteruc_iteruc_iteruc_funcucc(a1, a2, a3, a4) result(zres)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    type(cpp_iter_b), intent(in) :: a3
    class(cpp_func_b_b), pointer, intent(in) :: a4
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_algo_unique_itert_itert__i(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_algo_upper_bound_itert_itert_t__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_algo_vecfrom__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    class(cpp_vec_d), pointer :: zres
  end function
  recursive function cpp_algo_vecfrom__i(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_vec_i), pointer :: zres
  end function
  recursive function cpp_algo_vecfrom__o(a1, a2, mk3, cm4) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_vec_o), pointer :: zres
  end function
  recursive subroutine cpp_arr_assign__b(a1, a2)
    class(cpp_arr_b), pointer, intent(in) :: a1
    class(cpp_arr_b), pointer, intent(in) :: a2
  end subroutine
  recursive subroutine cpp_arr_assign__d(a1, a2)
    class(cpp_arr_d), pointer, intent(in) :: a1
    class(cpp_arr_d), pointer, intent(in) :: a2
  end subroutine
  recursive subroutine cpp_arr_assign__i(a1, a2)
    class(cpp_arr_i), pointer, intent(in) :: a1
    class(cpp_arr_i), pointer, intent(in) :: a2
  end subroutine
  recursive subroutine cpp_arr_assign__l(a1, a2)
    class(cpp_arr_l), pointer, intent(in) :: a1
    class(cpp_arr_l), pointer, intent(in) :: a2
  end subroutine
  recursive subroutine cpp_arr_assign__o(a1, a2, mk3, cm4)
    class(cpp_arr_o), pointer, intent(in) :: a1
    class(cpp_arr_o), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
  end subroutine
  recursive subroutine cpp_arr_assign__s(a1, a2)
    class(cpp_arr_s), pointer, intent(in) :: a1
    class(cpp_arr_s), pointer, intent(in) :: a2
  end subroutine
  recursive subroutine cpp_arr_assign__z(a1, a2)
    class(cpp_arr_z), pointer, intent(in) :: a1
    class(cpp_arr_z), pointer, intent(in) :: a2
  end subroutine
  recursive function cpp_arr_b_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_b), pointer :: zres
  end function
  recursive function cpp_arr_clone__b(a1) result(zres)
    class(cpp_arr_b), pointer, intent(in) :: a1
    class(cpp_arr_b), pointer :: zres
  end function
  recursive function cpp_arr_clone__d(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    class(cpp_arr_d), pointer :: zres
  end function
  recursive function cpp_arr_clone__i(a1) result(zres)
    class(cpp_arr_i), pointer, intent(in) :: a1
    class(cpp_arr_i), pointer :: zres
  end function
  recursive function cpp_arr_clone__l(a1) result(zres)
    class(cpp_arr_l), pointer, intent(in) :: a1
    class(cpp_arr_l), pointer :: zres
  end function
  recursive function cpp_arr_clone__o(a1, mk2, cm3) result(zres)
    class(cpp_arr_o), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_clone__s(a1) result(zres)
    class(cpp_arr_s), pointer, intent(in) :: a1
    class(cpp_arr_s), pointer :: zres
  end function
  recursive function cpp_arr_clone__z(a1) result(zres)
    class(cpp_arr_z), pointer, intent(in) :: a1
    class(cpp_arr_z), pointer :: zres
  end function
  recursive function cpp_arr_d_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_d), pointer :: zres
  end function
  recursive function cpp_arr_eq__d(a1, a2) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    class(cpp_arr_d), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_arr_f_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_f), pointer :: zres
  end function
  recursive function cpp_arr_i_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_i), pointer :: zres
  end function
  recursive function cpp_arr_l_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_l), pointer :: zres
  end function
  recursive function cpp_arr_make2__d(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_make2__i(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_make2__o(a1, a2, mk3, cm4) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_make__d(a1) result(zres)
    integer(4), value :: a1
    class(cpp_arr_d), pointer :: zres
  end function
  recursive function cpp_arr_make__i(a1) result(zres)
    integer(4), value :: a1
    class(cpp_arr_i), pointer :: zres
  end function
  recursive function cpp_arr_make__l(a1) result(zres)
    integer(4), value :: a1
    class(cpp_arr_l), pointer :: zres
  end function
  recursive function cpp_arr_make__o(a1, mk2, cm3) result(zres)
    integer(4), value :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_make__z(a1) result(zres)
    integer(4), value :: a1
    class(cpp_arr_z), pointer :: zres
  end function
  recursive function cpp_arr_makewith__o(a1, a2, mk3, cm4) result(zres)
    integer(4), value :: a1
    class(cpp_func_o), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_o_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_o_new_mk(a1, a2) result(zres)
    integer(8), value :: a1
    procedure(cpp_maker) :: a2
    class(cpp_arr_o), pointer :: zres
  end function
  recursive function cpp_arr_s_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_s), pointer :: zres
  end function
  recursive function cpp_arr_z_new(a1) result(zres)
    integer(8), value :: a1
    class(cpp_arr_z), pointer :: zres
  end function
  recursive subroutine cpp_array_fill_d(a1, a2)
    class(cpp_arr_d), pointer, intent(in) :: a1
    real(8), value :: a2
  end subroutine
  recursive subroutine cpp_array_fill_l(a1, a2)
    class(cpp_arr_l), pointer, intent(in) :: a1
    integer(8), value :: a2
  end subroutine
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
  recursive subroutine cpp_cppexception_ctor_0(self)
    class(cpp_cppexception), intent(inout), target :: self
  end subroutine
  recursive function cpp_cppexception_what(self) result(zres)
    class(cpp_cppexception), intent(inout), target :: self
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_cptr_clone(self) result(zres)
    type(cpp_cptr), intent(in) :: self
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_cptr_diff(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_cptr_from_ptrc(a1) result(zres)
    type(cpp_ptr_b), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_cptr_from_ptruc(a1) result(zres)
    type(cpp_ptr_b), intent(in) :: a1
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_cptr_isnull(self) result(zres)
    type(cpp_cptr), intent(in) :: self
    logical :: zres
  end function
  recursive function cpp_cptr_op_add_cptr_i(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_cptr_op_add_cptr_l(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_cptr_op_eq(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_cptr_op_lt(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_cptr_op_ne(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_cspan_o_empty(self) result(zres)
    type(cpp_cspan_o), intent(in) :: self
    logical :: zres
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
  recursive function cpp_double_isfinite(a1) result(zres)
    real(8), value :: a1
    logical :: zres
  end function
  recursive function cpp_double_isinfinity(a1) result(zres)
    real(8), value :: a1
    logical :: zres
  end function
  recursive function cpp_double_isnan(a1) result(zres)
    real(8), value :: a1
    logical :: zres
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
  recursive function cpp_hashtable_begin(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    type(cpp_mit) :: zres
  end function
  recursive subroutine cpp_hashtable_clear(self)
    class(cpp_hashtable), intent(inout), target :: self
  end subroutine
  recursive function cpp_hashtable_contains(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    logical :: zres
  end function
  recursive function cpp_hashtable_count(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    integer(8) :: zres
  end function
  recursive function cpp_hashtable_end(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    type(cpp_mit) :: zres
  end function
  recursive function cpp_hashtable_erase_mite(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    type(cpp_mit), intent(in) :: a1
    type(cpp_mit) :: zres
  end function
  recursive function cpp_hashtable_find(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_mit) :: zres
  end function
  recursive subroutine cpp_hashtable_reserve(self, a1)
    class(cpp_hashtable), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive function cpp_hashtable_size(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    integer(8) :: zres
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
  recursive function cpp_invalidargument_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_invalidargument), pointer :: zres
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
  recursive function cpp_iter_b_clone(self) result(zres)
    type(cpp_iter_b), intent(in) :: self
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_iter_b_op_add(a1, a2) result(zres)
    type(cpp_iter_b), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_iter_b_op_eq(a1, a2) result(zres)
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_iter_d_clone(self) result(zres)
    type(cpp_iter_d), intent(in) :: self
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_iter_d_deref(self) result(zres)
    type(cpp_iter_d), intent(in) :: self
    real(8), pointer :: zres
  end function
  recursive function cpp_iter_d_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_iter_d_op_add(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_iter_d_op_eq(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_iter_d_op_inc(a1) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_iter_d_op_sub_itert_itert(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_iter_i_clone(self) result(zres)
    type(cpp_iter_i), intent(in) :: self
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_iter_i_op_add(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_iter_i_op_sub_itert_itert(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    integer(8) :: zres
  end function
  recursive function cpp_iter_i_op_sub_itert_l(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_iter_o_clone(self) result(zres)
    type(cpp_iter_o), intent(in) :: self
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_iter_o_deref(self) result(zres)
    type(cpp_iter_o), intent(in) :: self
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_iter_o_op_add(a1, a2) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_iter_o_op_eq(a1, a2) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_iter_o_op_inc(a1) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o) :: zres
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
  recursive function cpp_m_clamp_d_d_d(a1, a2, a3) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8), value :: a3
    real(8) :: zres
  end function
  recursive function cpp_m_clamp_i_i_i(a1, a2, a3) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    integer(4), value :: a3
    integer(4) :: zres
  end function
  recursive function cpp_m_max_d_d(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_m_max_da(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    real(8) :: zres
  end function
  recursive function cpp_m_max_i_i(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    integer(4) :: zres
  end function
  recursive function cpp_m_max_ia(a1) result(zres)
    class(cpp_arr_i), pointer, intent(in) :: a1
    integer(4) :: zres
  end function
  recursive function cpp_m_max_l_l(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_m_max_u_u(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    integer(4) :: zres
  end function
  recursive function cpp_m_max_ul_ul(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_m_min_d_d(a1, a2) result(zres)
    real(8), value :: a1
    real(8), value :: a2
    real(8) :: zres
  end function
  recursive function cpp_m_min_da(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    real(8) :: zres
  end function
  recursive function cpp_m_min_i_i(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    integer(4) :: zres
  end function
  recursive function cpp_m_min_uc_uc(a1, a2) result(zres)
    integer(1), value :: a1
    integer(1), value :: a2
    integer(1) :: zres
  end function
  recursive function cpp_m_min_ul_ul(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive subroutine cpp_map_assign(self, a1)
    class(cpp_map), intent(inout), target :: self
    class(cpp_map), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_map_begin(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    type(cpp_mit) :: zres
  end function
  recursive function cpp_map_clone(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(cpp_map), pointer :: zres
  end function
  recursive function cpp_map_emplace_k_v(self, a1, a2) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(*), pointer, intent(in) :: a2
    class(cpp_pair), pointer :: zres
  end function
  recursive function cpp_map_empty(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_map_end(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    type(cpp_mit) :: zres
  end function
  recursive function cpp_map_find(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_mit) :: zres
  end function
  recursive function cpp_map_index(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_map_new_funckkb_funcv(a1, a2, mk3, cm4, mk5, cm6) result(zres)
    class(cpp_func_o_o_z), pointer, intent(in) :: a1
    class(cpp_func_o), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
    class(cpp_map), pointer :: zres
  end function
  recursive function cpp_map_size(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    integer(8) :: zres
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
  recursive function cpp_mit_clone(self) result(zres)
    type(cpp_mit), intent(in) :: self
    type(cpp_mit) :: zres
  end function
  recursive function cpp_mit_deref(self) result(zres)
    type(cpp_mit), intent(in) :: self
    class(*), pointer :: zres
  end function
  recursive function cpp_mit_op_eq(a1, a2) result(zres)
    type(cpp_mit), intent(in) :: a1
    type(cpp_mit), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_mit_op_inc(a1) result(zres)
    type(cpp_mit), intent(in) :: a1
    type(cpp_mit) :: zres
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
  recursive function cpp_onceflag_new() result(zres)
    class(cpp_onceflag), pointer :: zres
  end function
  recursive subroutine cpp_opt_d_assign(self, a1)
    class(cpp_opt_d), intent(inout), target :: self
    class(cpp_opt_d), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_opt_d_clone(self) result(zres)
    class(cpp_opt_d), intent(inout), target :: self
    class(cpp_opt_d), pointer :: zres
  end function
  recursive subroutine cpp_opt_d_movefrom(self, a1)
    class(cpp_opt_d), intent(inout), target :: self
    class(cpp_opt_d), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_opt_d_new_0() result(zres)
    class(cpp_opt_d), pointer :: zres
  end function
  recursive function cpp_opt_d_new_t(a1) result(zres)
    real(8), value :: a1
    class(cpp_opt_d), pointer :: zres
  end function
  recursive function cpp_opt_d_value_or(self, a1) result(zres)
    class(cpp_opt_d), intent(inout), target :: self
    real(8), value :: a1
    real(8) :: zres
  end function
  recursive subroutine cpp_opt_o_assign(self, a1)
    class(cpp_opt_o), intent(inout), target :: self
    class(cpp_opt_o), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_opt_o_clone(self) result(zres)
    class(cpp_opt_o), intent(inout), target :: self
    class(cpp_opt_o), pointer :: zres
  end function
  recursive function cpp_opt_o_emplace(self, a1) result(zres)
    class(cpp_opt_o), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_opt_o_new_0(mk1, cm2) result(zres)
    procedure(cpp_maker) :: mk1
    integer(4), value :: cm2
    class(cpp_opt_o), pointer :: zres
  end function
  recursive subroutine cpp_opt_o_reset(self)
    class(cpp_opt_o), intent(inout), target :: self
  end subroutine
  recursive subroutine cpp_opt_o_set(self, a1)
    class(cpp_opt_o), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
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
  recursive function cpp_outofrange_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_outofrange), pointer :: zres
  end function
  recursive function cpp_pair_clone(self) result(zres)
    class(cpp_pair), intent(inout), target :: self
    class(cpp_pair), pointer :: zres
  end function
  recursive function cpp_pair_new_0(mk1, cm2, mk3, cm4) result(zres)
    procedure(cpp_maker) :: mk1
    integer(4), value :: cm2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_pair), pointer :: zres
  end function
  recursive function cpp_pair_new_a_b(a1, a2, mk3, cm4, mk5, cm6) result(zres)
    class(*), pointer, intent(in) :: a1
    class(*), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
    class(cpp_pair), pointer :: zres
  end function
  recursive function cpp_ptr_b_item_i(self, a1) result(zres)
    type(cpp_ptr_b), intent(in) :: self
    integer(4), value :: a1
    integer(1), pointer :: zres
  end function
  recursive function cpp_ptr_b_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_b), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_b) :: zres
  end function
  recursive function cpp_ptr_b_op_add_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_b), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_b) :: zres
  end function
  recursive function cpp_ptr_b_op_sub_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_b), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_b) :: zres
  end function
  recursive function cpp_ptr_d_deref(self) result(zres)
    type(cpp_ptr_d), intent(in) :: self
    real(8), pointer :: zres
  end function
  recursive function cpp_ptr_d_from(a1) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_ptr_d_isnull(self) result(zres)
    type(cpp_ptr_d), intent(in) :: self
    logical :: zres
  end function
  recursive function cpp_ptr_d_item_i(self, a1) result(zres)
    type(cpp_ptr_d), intent(in) :: self
    integer(4), value :: a1
    real(8), pointer :: zres
  end function
  recursive function cpp_ptr_d_item_l(self, a1) result(zres)
    type(cpp_ptr_d), intent(in) :: self
    integer(8), value :: a1
    real(8), pointer :: zres
  end function
  recursive function cpp_ptr_d_item_ul(self, a1) result(zres)
    type(cpp_ptr_d), intent(in) :: self
    integer(8), value :: a1
    real(8), pointer :: zres
  end function
  recursive function cpp_ptr_d_new_o_refatt(a1, a2) result(zres)
    class(*), pointer, intent(in) :: a1
    class(cpp_refat_d), pointer, intent(in) :: a2
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_ptr_d_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_ptr_d_op_add_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_ptr_d_op_eq(a1, a2) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    type(cpp_ptr_d), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_ptr_d_op_ne(a1, a2) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    type(cpp_ptr_d), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_ptr_d_op_sub_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_d), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_ptr_f_item_i(self, a1) result(zres)
    type(cpp_ptr_f), intent(in) :: self
    integer(4), value :: a1
    real(4), pointer :: zres
  end function
  recursive function cpp_ptr_f_item_ul(self, a1) result(zres)
    type(cpp_ptr_f), intent(in) :: self
    integer(8), value :: a1
    real(4), pointer :: zres
  end function
  recursive function cpp_ptr_f_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_f), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_f) :: zres
  end function
  recursive function cpp_ptr_f_op_add_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_f), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_f) :: zres
  end function
  recursive function cpp_ptr_i_deref(self) result(zres)
    type(cpp_ptr_i), intent(in) :: self
    integer(4), pointer :: zres
  end function
  recursive function cpp_ptr_i_isnull(self) result(zres)
    type(cpp_ptr_i), intent(in) :: self
    logical :: zres
  end function
  recursive function cpp_ptr_i_item_i(self, a1) result(zres)
    type(cpp_ptr_i), intent(in) :: self
    integer(4), value :: a1
    integer(4), pointer :: zres
  end function
  recursive function cpp_ptr_i_item_l(self, a1) result(zres)
    type(cpp_ptr_i), intent(in) :: self
    integer(8), value :: a1
    integer(4), pointer :: zres
  end function
  recursive function cpp_ptr_i_item_ul(self, a1) result(zres)
    type(cpp_ptr_i), intent(in) :: self
    integer(8), value :: a1
    integer(4), pointer :: zres
  end function
  recursive function cpp_ptr_i_new_o_refatt(a1, a2) result(zres)
    class(*), pointer, intent(in) :: a1
    class(cpp_refat_i), pointer, intent(in) :: a2
    type(cpp_ptr_i) :: zres
  end function
  recursive function cpp_ptr_i_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_i), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_i) :: zres
  end function
  recursive function cpp_ptr_i_op_add_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_i) :: zres
  end function
  recursive function cpp_ptr_i_op_ne(a1, a2) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    type(cpp_ptr_i), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_ptr_i_op_sub_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_i), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_i) :: zres
  end function
  recursive function cpp_ptr_l_item_i(self, a1) result(zres)
    type(cpp_ptr_l), intent(in) :: self
    integer(4), value :: a1
    integer(8), pointer :: zres
  end function
  recursive function cpp_ptr_l_new_o_refatt(a1, a2) result(zres)
    class(*), pointer, intent(in) :: a1
    class(cpp_refat_l), pointer, intent(in) :: a2
    type(cpp_ptr_l) :: zres
  end function
  recursive function cpp_ptr_l_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_l), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_l) :: zres
  end function
  recursive function cpp_ptr_o_deref(self) result(zres)
    type(cpp_ptr_o), intent(in) :: self
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_ptr_o_isnull(self) result(zres)
    type(cpp_ptr_o), intent(in) :: self
    logical :: zres
  end function
  recursive function cpp_ptr_o_item_i(self, a1) result(zres)
    type(cpp_ptr_o), intent(in) :: self
    integer(4), value :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_ptr_o_item_l(self, a1) result(zres)
    type(cpp_ptr_o), intent(in) :: self
    integer(8), value :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_ptr_o_item_ul(self, a1) result(zres)
    type(cpp_ptr_o), intent(in) :: self
    integer(8), value :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_ptr_o_new_o_refatt(a1, a2) result(zres)
    class(*), pointer, intent(in) :: a1
    class(cpp_refat_o), pointer, intent(in) :: a2
    type(cpp_ptr_o) :: zres
  end function
  recursive function cpp_ptr_o_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_o), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_o) :: zres
  end function
  recursive function cpp_ptr_o_op_add_ptrt_l(a1, a2) result(zres)
    type(cpp_ptr_o), intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_o) :: zres
  end function
  recursive function cpp_ptr_o_op_ne(a1, a2) result(zres)
    type(cpp_ptr_o), intent(in) :: a1
    type(cpp_ptr_o), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_ptr_s_item_i(self, a1) result(zres)
    type(cpp_ptr_s), intent(in) :: self
    integer(4), value :: a1
    integer(2), pointer :: zres
  end function
  recursive function cpp_ptr_s_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_s), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_s) :: zres
  end function
  recursive function cpp_ptr_z_item_i(self, a1) result(zres)
    type(cpp_ptr_z), intent(in) :: self
    integer(4), value :: a1
    logical, pointer :: zres
  end function
  recursive function cpp_ptr_z_item_ul(self, a1) result(zres)
    type(cpp_ptr_z), intent(in) :: self
    integer(8), value :: a1
    logical, pointer :: zres
  end function
  recursive function cpp_ptr_z_new_ta_l(a1, a2) result(zres)
    class(cpp_arr_z), pointer, intent(in) :: a1
    integer(8), value :: a2
    type(cpp_ptr_z) :: zres
  end function
  recursive subroutine cpp_que_assign(self, a1)
    class(cpp_que), intent(inout), target :: self
    class(cpp_que), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_que_clone(self) result(zres)
    class(cpp_que), intent(inout), target :: self
    class(cpp_que), pointer :: zres
  end function
  recursive function cpp_que_new(mk1, cm2) result(zres)
    procedure(cpp_maker) :: mk1
    integer(4), value :: cm2
    class(cpp_que), pointer :: zres
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
  recursive function cpp_reviter_o_deref(self) result(zres)
    type(cpp_reviter_o), intent(in) :: self
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_reviter_o_op_eq(a1, a2) result(zres)
    type(cpp_reviter_o), intent(in) :: a1
    type(cpp_reviter_o), intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_reviter_o_op_inc(a1) result(zres)
    type(cpp_reviter_o), intent(in) :: a1
    type(cpp_reviter_o) :: zres
  end function
  recursive function cpp_runtimeerror_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_runtimeerror), pointer :: zres
  end function
  recursive subroutine cpp_set_assign(self, a1)
    class(cpp_set), intent(inout), target :: self
    class(cpp_set), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_set_clone(self) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(cpp_set), pointer :: zres
  end function
  recursive function cpp_set_insert(self, a1) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(cpp_pair), pointer :: zres
  end function
  recursive function cpp_set_new_functtb(a1, mk2, cm3) result(zres)
    class(cpp_func_o_o_z), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    class(cpp_set), pointer :: zres
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
  recursive subroutine cpp_stdalgo_sort__d(a1, a2, a3, a4)
    class(cpp_arr_d), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_d_d_z), pointer, intent(in) :: a4
  end subroutine
  recursive subroutine cpp_stdalgo_sort__i(a1, a2, a3, a4)
    class(cpp_arr_i), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_i_i_z), pointer, intent(in) :: a4
  end subroutine
  recursive subroutine cpp_stdalgo_sort__l(a1, a2, a3, a4)
    class(cpp_arr_l), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_l_l_z), pointer, intent(in) :: a4
  end subroutine
  recursive subroutine cpp_stdalgo_sort__o(a1, a2, a3, a4, mk5, cm6)
    class(cpp_arr_o), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_o_o_z), pointer, intent(in) :: a4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
  end subroutine
  recursive subroutine cpp_stdalgo_stablesort__i(a1, a2, a3, a4)
    class(cpp_arr_i), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_i_i_z), pointer, intent(in) :: a4
  end subroutine
  recursive subroutine cpp_stdalgo_stablesort__o(a1, a2, a3, a4, mk5, cm6)
    class(cpp_arr_o), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_o_o_z), pointer, intent(in) :: a4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
  end subroutine
  recursive function cpp_stk_empty(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_stk_new(mk1, cm2) result(zres)
    procedure(cpp_maker) :: mk1
    integer(4), value :: cm2
    class(cpp_stk), pointer :: zres
  end function
  recursive subroutine cpp_stk_pop(self)
    class(cpp_stk), intent(inout), target :: self
  end subroutine
  recursive subroutine cpp_stk_push(self, a1)
    class(cpp_stk), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_stk_size(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive function cpp_stk_top(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_str_append_cptr(self, a1) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_append_cptr_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_append_i(self, a1) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(4), value :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_append_str(self, a1) result(zres)
    class(cpp_str), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive subroutine cpp_str_assign_cptr(self, a1)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
  end subroutine
  recursive function cpp_str_assign_cptr_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_assign_ptrc_ptrc(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_ptr_b), intent(in) :: a1
    type(cpp_ptr_b), intent(in) :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive subroutine cpp_str_assign_str(self, a1)
    class(cpp_str), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_str_back(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(1), pointer :: zres
  end function
  recursive function cpp_str_begin(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_str_c_str(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_str_cat_cptr_str(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    class(cpp_str), pointer, intent(in) :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_cat_str_cptr(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    type(cpp_cptr), intent(in) :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_cat_str_i(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(4), value :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_cat_str_str(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_str), pointer, intent(in) :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive subroutine cpp_str_clear(self)
    class(cpp_str), intent(inout), target :: self
  end subroutine
  recursive function cpp_str_clone(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_compare_ul_ul_str(self, a1, a2, a3) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(8), value :: a1
    integer(8), value :: a2
    class(cpp_str), pointer, intent(in) :: a3
    integer(4) :: zres
  end function
  recursive function cpp_str_data(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr) :: zres
  end function
  recursive function cpp_str_empty(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_str_end(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_str_eqlit(self, a1) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    logical :: zres
  end function
  recursive function cpp_str_equals_str(self, a1) result(zres)
    class(cpp_str), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    logical :: zres
  end function
  recursive function cpp_str_erase(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(8), value :: a1
    integer(8), value :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_find_cptr_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_find_first_not_of_cptr_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_find_first_not_of_i_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(4), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_find_first_of_cptr_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_find_i_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(4), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_find_last_not_of_cptr_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_find_last_of_i_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(4), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_from(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_front(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(1), pointer :: zres
  end function
  recursive subroutine cpp_str_movefrom(self, a1)
    class(cpp_str), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_str_new_0() result(zres)
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_new_cptr(a1) result(zres)
    type(cpp_cptr), intent(in) :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_new_cptr_ul(a1, a2) result(zres)
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_new_ul_i(a1, a2) result(zres)
    integer(8), value :: a1
    integer(4), value :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive subroutine cpp_str_pop_back(self)
    class(cpp_str), intent(inout), target :: self
  end subroutine
  recursive subroutine cpp_str_push_back(self, a1)
    class(cpp_str), intent(inout), target :: self
    integer(4), value :: a1
  end subroutine
  recursive subroutine cpp_str_remove_prefix(self, a1)
    class(cpp_str), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_str_reserve(self, a1)
    class(cpp_str), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_str_resize(self, a1, a2)
    class(cpp_str), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
  end subroutine
  recursive function cpp_str_rfind_cptr_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_rfind_i_ul(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(4), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_str_size(self) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive function cpp_str_starts_with_cptr(self, a1) result(zres)
    class(cpp_str), intent(inout), target :: self
    type(cpp_cptr), intent(in) :: a1
    logical :: zres
  end function
  recursive function cpp_str_starts_with_str(self, a1) result(zres)
    class(cpp_str), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
    logical :: zres
  end function
  recursive function cpp_str_stod(a1, a2) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    type(cpp_ptr_l), intent(in) :: a2
    real(8) :: zres
  end function
  recursive function cpp_str_substr(self, a1, a2) result(zres)
    class(cpp_str), intent(inout), target :: self
    integer(8), value :: a1
    integer(8), value :: a2
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_to_string_d(a1) result(zres)
    real(8), value :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_to_string_i(a1) result(zres)
    integer(4), value :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_to_string_l(a1) result(zres)
    integer(8), value :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_to_string_u(a1) result(zres)
    integer(4), value :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_to_string_ul(a1) result(zres)
    integer(8), value :: a1
    class(cpp_str), pointer :: zres
  end function
  recursive function cpp_str_tostring(a1) result(zres)
    class(cpp_str), intent(inout), target :: a1
    character(len=:), allocatable :: zres
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
  recursive function cpp_u2d(a1) result(zres)
    integer(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_udiv8(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive subroutine cpp_umap_assign(self, a1)
    class(cpp_umap), intent(inout), target :: self
    class(cpp_umap), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_umap_clone(self) result(zres)
    class(cpp_umap), intent(inout), target :: self
    class(cpp_umap), pointer :: zres
  end function
  recursive function cpp_umap_emplace_k_v(self, a1, a2) result(zres)
    class(cpp_umap), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(*), pointer, intent(in) :: a2
    class(cpp_pair), pointer :: zres
  end function
  recursive function cpp_umap_index(self, a1) result(zres)
    class(cpp_umap), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_umap_new_funckul_funckkb_funcv(a1, a2, a3, mk4, cm5, mk6, cm7) result(zres)
    class(cpp_func_o_l), pointer, intent(in) :: a1
    class(cpp_func_o_o_z), pointer, intent(in) :: a2
    class(cpp_func_o), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    procedure(cpp_maker) :: mk6
    integer(4), value :: cm7
    class(cpp_umap), pointer :: zres
  end function
  recursive function cpp_umap_new_pairkva_funckul_funckkb(a1, a2, a3, mk4, cm5, mk6, cm7) result(zres)
    class(cpp_arr_o), pointer, intent(in) :: a1
    class(cpp_func_o_l), pointer, intent(in) :: a2
    class(cpp_func_o_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    procedure(cpp_maker) :: mk6
    integer(4), value :: cm7
    class(cpp_umap), pointer :: zres
  end function
  recursive subroutine cpp_umapc_assign(self, a1)
    class(cpp_umapc), intent(inout), target :: self
    class(cpp_umapc), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_umapc_clone(self) result(zres)
    class(cpp_umapc), intent(inout), target :: self
    class(cpp_umapc), pointer :: zres
  end function
  recursive function cpp_umapc_new_funcv(a1, mk2, cm3, mk4, cm5, mk6, cm7, mk8, cm9) result(zres)
    class(cpp_func_o), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    procedure(cpp_maker) :: mk6
    integer(4), value :: cm7
    procedure(cpp_maker) :: mk8
    integer(4), value :: cm9
    class(cpp_umapc), pointer :: zres
  end function
  recursive function cpp_urem4(a1, a2) result(zres)
    integer(4), value :: a1
    integer(4), value :: a2
    integer(4) :: zres
  end function
  recursive function cpp_urem8(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
  end function
  recursive function cpp_uset_insert(self, a1) result(zres)
    class(cpp_uset), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(cpp_pair), pointer :: zres
  end function
  recursive function cpp_uset_new_functul_functtb(a1, a2, mk3, cm4) result(zres)
    class(cpp_func_o_l), pointer, intent(in) :: a1
    class(cpp_func_o_o_z), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_uset), pointer :: zres
  end function
  recursive subroutine cpp_variant_assign(self, a1)
    class(cpp_variant), intent(inout), target :: self
    class(cpp_variant), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_variant_clone(self) result(zres)
    class(cpp_variant), intent(inout), target :: self
    class(cpp_variant), pointer :: zres
  end function
  recursive subroutine cpp_variant_movefrom(self, a1)
    class(cpp_variant), intent(inout), target :: self
    class(cpp_variant), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_variant_new_0() result(zres)
    class(cpp_variant), pointer :: zres
  end function
  recursive subroutine cpp_variant_set_b(self, a1)
    class(cpp_variant), intent(inout), target :: self
    logical, value :: a1
  end subroutine
  recursive subroutine cpp_variant_set_d(self, a1)
    class(cpp_variant), intent(inout), target :: self
    real(8), value :: a1
  end subroutine
  recursive subroutine cpp_variant_set_i(self, a1)
    class(cpp_variant), intent(inout), target :: self
    integer(4), value :: a1
  end subroutine
  recursive subroutine cpp_variant_set_str(self, a1)
    class(cpp_variant), intent(inout), target :: self
    class(cpp_str), pointer, intent(in) :: a1
  end subroutine
  recursive subroutine cpp_vec_b_assign_itert_itert(self, a1, a2)
    class(cpp_vec_b), intent(inout), target :: self
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b), intent(in) :: a2
  end subroutine
  recursive subroutine cpp_vec_b_assign_ul_t(self, a1, a2)
    class(cpp_vec_b), intent(inout), target :: self
    integer(8), value :: a1
    integer(1), value :: a2
  end subroutine
  recursive subroutine cpp_vec_b_assign_vect(self, a1)
    class(cpp_vec_b), intent(inout), target :: self
    class(cpp_vec_b), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_b_begin(self) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_vec_b_capacity(self) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_b_clear(self)
    class(cpp_vec_b), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_b_clone(self) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    class(cpp_vec_b), pointer :: zres
  end function
  recursive function cpp_vec_b_data(self) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    type(cpp_ptr_b) :: zres
  end function
  recursive function cpp_vec_b_empty(self) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_vec_b_end(self) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_vec_b_eq(a1, a2) result(zres)
    class(cpp_vec_b), pointer, intent(in) :: a1
    class(cpp_vec_b), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_vec_b_erase_itert(self, a1) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    type(cpp_iter_b), intent(in) :: a1
    type(cpp_iter_b) :: zres
  end function
  recursive function cpp_vec_b_insert_itert_t(self, a1, a2) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    type(cpp_iter_b), intent(in) :: a1
    integer(1), value :: a2
    type(cpp_iter_b) :: zres
  end function
  recursive subroutine cpp_vec_b_movefrom_vect(self, a1)
    class(cpp_vec_b), intent(inout), target :: self
    class(cpp_vec_b), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_b_new_0() result(zres)
    class(cpp_vec_b), pointer :: zres
  end function
  recursive function cpp_vec_b_new_ul(a1) result(zres)
    integer(8), value :: a1
    class(cpp_vec_b), pointer :: zres
  end function
  recursive function cpp_vec_b_new_ul_t(a1, a2) result(zres)
    integer(8), value :: a1
    integer(1), value :: a2
    class(cpp_vec_b), pointer :: zres
  end function
  recursive subroutine cpp_vec_b_push_back(self, a1)
    class(cpp_vec_b), intent(inout), target :: self
    integer(1), value :: a1
  end subroutine
  recursive subroutine cpp_vec_b_reserve(self, a1)
    class(cpp_vec_b), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_b_resize_ul(self, a1)
    class(cpp_vec_b), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_b_resize_ul_t(self, a1, a2)
    class(cpp_vec_b), intent(inout), target :: self
    integer(8), value :: a1
    integer(1), value :: a2
  end subroutine
  recursive subroutine cpp_vec_b_shrink_to_fit(self)
    class(cpp_vec_b), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_b_size(self) result(zres)
    class(cpp_vec_b), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_d_assign_ul_t(self, a1, a2)
    class(cpp_vec_d), intent(inout), target :: self
    integer(8), value :: a1
    real(8), value :: a2
  end subroutine
  recursive subroutine cpp_vec_d_assign_vect(self, a1)
    class(cpp_vec_d), intent(inout), target :: self
    class(cpp_vec_d), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_d_back(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    real(8), pointer :: zres
  end function
  recursive function cpp_vec_d_begin(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_vec_d_capacity(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_d_clear(self)
    class(cpp_vec_d), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_d_clone(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    class(cpp_vec_d), pointer :: zres
  end function
  recursive function cpp_vec_d_data(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    type(cpp_ptr_d) :: zres
  end function
  recursive function cpp_vec_d_empty(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_vec_d_end(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_vec_d_eq(a1, a2) result(zres)
    class(cpp_vec_d), pointer, intent(in) :: a1
    class(cpp_vec_d), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_vec_d_erase_itert(self, a1) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_vec_d_front(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    real(8), pointer :: zres
  end function
  recursive function cpp_vec_d_insert_itert_ptrt_ptrt(self, a1, a2, a3) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_ptr_d), intent(in) :: a2
    type(cpp_ptr_d), intent(in) :: a3
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_vec_d_insert_itert_t(self, a1, a2) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    type(cpp_iter_d), intent(in) :: a1
    real(8), value :: a2
    type(cpp_iter_d) :: zres
  end function
  recursive function cpp_vec_d_insert_itert_ta(self, a1, a2) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    type(cpp_iter_d), intent(in) :: a1
    class(cpp_arr_d), pointer, intent(in) :: a2
    type(cpp_iter_d) :: zres
  end function
  recursive subroutine cpp_vec_d_movefrom_ta(self, a1)
    class(cpp_vec_d), intent(inout), target :: self
    class(cpp_arr_d), pointer, intent(in) :: a1
  end subroutine
  recursive subroutine cpp_vec_d_movefrom_vect(self, a1)
    class(cpp_vec_d), intent(inout), target :: self
    class(cpp_vec_d), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_d_new_0() result(zres)
    class(cpp_vec_d), pointer :: zres
  end function
  recursive function cpp_vec_d_new_ta(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    class(cpp_vec_d), pointer :: zres
  end function
  recursive function cpp_vec_d_new_ul(a1) result(zres)
    integer(8), value :: a1
    class(cpp_vec_d), pointer :: zres
  end function
  recursive function cpp_vec_d_new_ul_t(a1, a2) result(zres)
    integer(8), value :: a1
    real(8), value :: a2
    class(cpp_vec_d), pointer :: zres
  end function
  recursive subroutine cpp_vec_d_push_back(self, a1)
    class(cpp_vec_d), intent(inout), target :: self
    real(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_d_reserve(self, a1)
    class(cpp_vec_d), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_d_resize_ul(self, a1)
    class(cpp_vec_d), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_d_resize_ul_t(self, a1, a2)
    class(cpp_vec_d), intent(inout), target :: self
    integer(8), value :: a1
    real(8), value :: a2
  end subroutine
  recursive subroutine cpp_vec_d_shrink_to_fit(self)
    class(cpp_vec_d), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_d_size(self) result(zres)
    class(cpp_vec_d), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_d_swap(self, a1)
    class(cpp_vec_d), intent(inout), target :: self
    class(cpp_vec_d), pointer, intent(in) :: a1
  end subroutine
  recursive subroutine cpp_vec_f_assign_ul_t(self, a1, a2)
    class(cpp_vec_f), intent(inout), target :: self
    integer(8), value :: a1
    real(4), value :: a2
  end subroutine
  recursive subroutine cpp_vec_f_assign_vect(self, a1)
    class(cpp_vec_f), intent(inout), target :: self
    class(cpp_vec_f), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_f_begin(self) result(zres)
    class(cpp_vec_f), intent(inout), target :: self
    type(cpp_iter_f) :: zres
  end function
  recursive subroutine cpp_vec_f_clear(self)
    class(cpp_vec_f), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_f_clone(self) result(zres)
    class(cpp_vec_f), intent(inout), target :: self
    class(cpp_vec_f), pointer :: zres
  end function
  recursive function cpp_vec_f_data(self) result(zres)
    class(cpp_vec_f), intent(inout), target :: self
    type(cpp_ptr_f) :: zres
  end function
  recursive function cpp_vec_f_end(self) result(zres)
    class(cpp_vec_f), intent(inout), target :: self
    type(cpp_iter_f) :: zres
  end function
  recursive function cpp_vec_f_new_0() result(zres)
    class(cpp_vec_f), pointer :: zres
  end function
  recursive subroutine cpp_vec_f_push_back(self, a1)
    class(cpp_vec_f), intent(inout), target :: self
    real(4), value :: a1
  end subroutine
  recursive subroutine cpp_vec_f_resize_ul(self, a1)
    class(cpp_vec_f), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive function cpp_vec_f_size(self) result(zres)
    class(cpp_vec_f), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_i_assign_ul_t(self, a1, a2)
    class(cpp_vec_i), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
  end subroutine
  recursive subroutine cpp_vec_i_assign_vect(self, a1)
    class(cpp_vec_i), intent(inout), target :: self
    class(cpp_vec_i), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_i_at(self, a1) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), pointer :: zres
  end function
  recursive function cpp_vec_i_back(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    integer(4), pointer :: zres
  end function
  recursive function cpp_vec_i_begin(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_vec_i_capacity(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_i_clear(self)
    class(cpp_vec_i), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_i_clone(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    class(cpp_vec_i), pointer :: zres
  end function
  recursive function cpp_vec_i_data(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    type(cpp_ptr_i) :: zres
  end function
  recursive function cpp_vec_i_empty(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_vec_i_end(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_vec_i_eq(a1, a2) result(zres)
    class(cpp_vec_i), pointer, intent(in) :: a1
    class(cpp_vec_i), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_vec_i_erase_itert(self, a1) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_vec_i_erase_itert_itert(self, a1, a2) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_vec_i_insert_itert_itert_itert(self, a1, a2, a3) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    type(cpp_iter_i), intent(in) :: a3
    type(cpp_iter_i) :: zres
  end function
  recursive function cpp_vec_i_insert_itert_t(self, a1, a2) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    type(cpp_iter_i), intent(in) :: a1
    integer(4), value :: a2
    type(cpp_iter_i) :: zres
  end function
  recursive subroutine cpp_vec_i_movefrom_vect(self, a1)
    class(cpp_vec_i), intent(inout), target :: self
    class(cpp_vec_i), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_i_new_0() result(zres)
    class(cpp_vec_i), pointer :: zres
  end function
  recursive function cpp_vec_i_new_ul(a1) result(zres)
    integer(8), value :: a1
    class(cpp_vec_i), pointer :: zres
  end function
  recursive function cpp_vec_i_new_ul_t(a1, a2) result(zres)
    integer(8), value :: a1
    integer(4), value :: a2
    class(cpp_vec_i), pointer :: zres
  end function
  recursive subroutine cpp_vec_i_push_back(self, a1)
    class(cpp_vec_i), intent(inout), target :: self
    integer(4), value :: a1
  end subroutine
  recursive subroutine cpp_vec_i_reserve(self, a1)
    class(cpp_vec_i), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_i_resize_ul(self, a1)
    class(cpp_vec_i), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_i_resize_ul_t(self, a1, a2)
    class(cpp_vec_i), intent(inout), target :: self
    integer(8), value :: a1
    integer(4), value :: a2
  end subroutine
  recursive subroutine cpp_vec_i_shrink_to_fit(self)
    class(cpp_vec_i), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_i_size(self) result(zres)
    class(cpp_vec_i), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_i_swap(self, a1)
    class(cpp_vec_i), intent(inout), target :: self
    class(cpp_vec_i), pointer, intent(in) :: a1
  end subroutine
  recursive subroutine cpp_vec_l_assign_ul_t(self, a1, a2)
    class(cpp_vec_l), intent(inout), target :: self
    integer(8), value :: a1
    integer(8), value :: a2
  end subroutine
  recursive subroutine cpp_vec_l_assign_vect(self, a1)
    class(cpp_vec_l), intent(inout), target :: self
    class(cpp_vec_l), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_l_begin(self) result(zres)
    class(cpp_vec_l), intent(inout), target :: self
    type(cpp_iter_l) :: zres
  end function
  recursive subroutine cpp_vec_l_clear(self)
    class(cpp_vec_l), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_l_clone(self) result(zres)
    class(cpp_vec_l), intent(inout), target :: self
    class(cpp_vec_l), pointer :: zres
  end function
  recursive function cpp_vec_l_end(self) result(zres)
    class(cpp_vec_l), intent(inout), target :: self
    type(cpp_iter_l) :: zres
  end function
  recursive subroutine cpp_vec_l_movefrom_vect(self, a1)
    class(cpp_vec_l), intent(inout), target :: self
    class(cpp_vec_l), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_l_new_0() result(zres)
    class(cpp_vec_l), pointer :: zres
  end function
  recursive function cpp_vec_l_new_ul(a1) result(zres)
    integer(8), value :: a1
    class(cpp_vec_l), pointer :: zres
  end function
  recursive subroutine cpp_vec_l_push_back(self, a1)
    class(cpp_vec_l), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_l_reserve(self, a1)
    class(cpp_vec_l), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_l_resize_ul(self, a1)
    class(cpp_vec_l), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_l_resize_ul_t(self, a1, a2)
    class(cpp_vec_l), intent(inout), target :: self
    integer(8), value :: a1
    integer(8), value :: a2
  end subroutine
  recursive subroutine cpp_vec_l_shrink_to_fit(self)
    class(cpp_vec_l), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_l_size(self) result(zres)
    class(cpp_vec_l), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_o_assign_itert_itert(self, a1, a2)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
  end subroutine
  recursive subroutine cpp_vec_o_assign_ul_t(self, a1, a2)
    class(cpp_vec_o), intent(inout), target :: self
    integer(8), value :: a1
    class(*), pointer, intent(in) :: a2
  end subroutine
  recursive subroutine cpp_vec_o_assign_vect(self, a1)
    class(cpp_vec_o), intent(inout), target :: self
    class(cpp_vec_o), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_o_at(self, a1) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    integer(8), value :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_vec_o_back(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_vec_o_begin(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_vec_o_capacity(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_o_clear(self)
    class(cpp_vec_o), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_o_clone(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    class(cpp_vec_o), pointer :: zres
  end function
  recursive function cpp_vec_o_data(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_ptr_o) :: zres
  end function
  recursive function cpp_vec_o_emplace_back(self, a1) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_vec_o_empty(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    logical :: zres
  end function
  recursive function cpp_vec_o_end(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_vec_o_eq(a1, a2) result(zres)
    class(cpp_vec_o), pointer, intent(in) :: a1
    class(cpp_vec_o), pointer, intent(in) :: a2
    logical :: zres
  end function
  recursive function cpp_vec_o_erase_itert(self, a1) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_vec_o_erase_itert_itert(self, a1, a2) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_vec_o_front(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_slot), pointer :: zres
  end function
  recursive function cpp_vec_o_insert_itert_itert_itert(self, a1, a2, a3) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    type(cpp_iter_o), intent(in) :: a3
    type(cpp_iter_o) :: zres
  end function
  recursive function cpp_vec_o_insert_itert_t(self, a1, a2) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_iter_o), intent(in) :: a1
    class(*), pointer, intent(in) :: a2
    type(cpp_iter_o) :: zres
  end function
  recursive subroutine cpp_vec_o_movefrom_ta(self, a1)
    class(cpp_vec_o), intent(inout), target :: self
    class(cpp_arr_o), pointer, intent(in) :: a1
  end subroutine
  recursive subroutine cpp_vec_o_movefrom_vect(self, a1)
    class(cpp_vec_o), intent(inout), target :: self
    class(cpp_vec_o), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_o_new_0(mk1, cm2) result(zres)
    procedure(cpp_maker) :: mk1
    integer(4), value :: cm2
    class(cpp_vec_o), pointer :: zres
  end function
  recursive function cpp_vec_o_new_funct(a1, mk2, cm3) result(zres)
    class(cpp_func_o), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    class(cpp_vec_o), pointer :: zres
  end function
  recursive function cpp_vec_o_new_ta(a1, mk2, cm3) result(zres)
    class(cpp_arr_o), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    class(cpp_vec_o), pointer :: zres
  end function
  recursive function cpp_vec_o_new_ul(a1, mk2, cm3) result(zres)
    integer(8), value :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    class(cpp_vec_o), pointer :: zres
  end function
  recursive function cpp_vec_o_new_ul_funct(a1, a2, mk3, cm4) result(zres)
    integer(8), value :: a1
    class(cpp_func_o), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_vec_o), pointer :: zres
  end function
  recursive function cpp_vec_o_new_ul_t(a1, a2, mk3, cm4) result(zres)
    integer(8), value :: a1
    class(*), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_vec_o), pointer :: zres
  end function
  recursive subroutine cpp_vec_o_pop_back(self)
    class(cpp_vec_o), intent(inout), target :: self
  end subroutine
  recursive subroutine cpp_vec_o_push_back(self, a1)
    class(cpp_vec_o), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_o_rbegin(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_reviter_o) :: zres
  end function
  recursive function cpp_vec_o_rend(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    type(cpp_reviter_o) :: zres
  end function
  recursive subroutine cpp_vec_o_reserve(self, a1)
    class(cpp_vec_o), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_o_resize_ul(self, a1)
    class(cpp_vec_o), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_o_resize_ul_t(self, a1, a2)
    class(cpp_vec_o), intent(inout), target :: self
    integer(8), value :: a1
    class(*), pointer, intent(in) :: a2
  end subroutine
  recursive subroutine cpp_vec_o_shrink_to_fit(self)
    class(cpp_vec_o), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_o_size(self) result(zres)
    class(cpp_vec_o), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_o_swap(self, a1)
    class(cpp_vec_o), intent(inout), target :: self
    class(cpp_vec_o), pointer, intent(in) :: a1
  end subroutine
  recursive subroutine cpp_vec_s_assign_ul_t(self, a1, a2)
    class(cpp_vec_s), intent(inout), target :: self
    integer(8), value :: a1
    integer(2), value :: a2
  end subroutine
  recursive subroutine cpp_vec_s_assign_vect(self, a1)
    class(cpp_vec_s), intent(inout), target :: self
    class(cpp_vec_s), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_s_clone(self) result(zres)
    class(cpp_vec_s), intent(inout), target :: self
    class(cpp_vec_s), pointer :: zres
  end function
  recursive function cpp_vec_s_new_0() result(zres)
    class(cpp_vec_s), pointer :: zres
  end function
  recursive subroutine cpp_vec_s_reserve(self, a1)
    class(cpp_vec_s), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_s_resize_ul(self, a1)
    class(cpp_vec_s), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_s_resize_ul_t(self, a1, a2)
    class(cpp_vec_s), intent(inout), target :: self
    integer(8), value :: a1
    integer(2), value :: a2
  end subroutine
  recursive subroutine cpp_vec_s_shrink_to_fit(self)
    class(cpp_vec_s), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_s_size(self) result(zres)
    class(cpp_vec_s), intent(inout), target :: self
    integer(8) :: zres
  end function
  recursive subroutine cpp_vec_z_assign_ul_t(self, a1, a2)
    class(cpp_vec_z), intent(inout), target :: self
    integer(8), value :: a1
    logical, value :: a2
  end subroutine
  recursive subroutine cpp_vec_z_assign_vect(self, a1)
    class(cpp_vec_z), intent(inout), target :: self
    class(cpp_vec_z), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_z_begin(self) result(zres)
    class(cpp_vec_z), intent(inout), target :: self
    type(cpp_iter_z) :: zres
  end function
  recursive subroutine cpp_vec_z_clear(self)
    class(cpp_vec_z), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_z_clone(self) result(zres)
    class(cpp_vec_z), intent(inout), target :: self
    class(cpp_vec_z), pointer :: zres
  end function
  recursive function cpp_vec_z_end(self) result(zres)
    class(cpp_vec_z), intent(inout), target :: self
    type(cpp_iter_z) :: zres
  end function
  recursive subroutine cpp_vec_z_movefrom_vect(self, a1)
    class(cpp_vec_z), intent(inout), target :: self
    class(cpp_vec_z), pointer, intent(in) :: a1
  end subroutine
  recursive function cpp_vec_z_new_0() result(zres)
    class(cpp_vec_z), pointer :: zres
  end function
  recursive function cpp_vec_z_new_ul_t(a1, a2) result(zres)
    integer(8), value :: a1
    logical, value :: a2
    class(cpp_vec_z), pointer :: zres
  end function
  recursive subroutine cpp_vec_z_push_back(self, a1)
    class(cpp_vec_z), intent(inout), target :: self
    logical, value :: a1
  end subroutine
  recursive subroutine cpp_vec_z_reserve(self, a1)
    class(cpp_vec_z), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_z_resize_ul(self, a1)
    class(cpp_vec_z), intent(inout), target :: self
    integer(8), value :: a1
  end subroutine
  recursive subroutine cpp_vec_z_resize_ul_t(self, a1, a2)
    class(cpp_vec_z), intent(inout), target :: self
    integer(8), value :: a1
    logical, value :: a2
  end subroutine
  recursive subroutine cpp_vec_z_shrink_to_fit(self)
    class(cpp_vec_z), intent(inout), target :: self
  end subroutine
  recursive function cpp_vec_z_size(self) result(zres)
    class(cpp_vec_z), intent(inout), target :: self
    integer(8) :: zres
  end function
end module cpp_runtime
