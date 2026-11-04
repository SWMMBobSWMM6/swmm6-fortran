! cpp_rt_a - STUB of part A of the Fortran runtime (types as the engine sees them, empty bodies), made by
! f90/tools/split_stub.py from the translator's stub. Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
module cpp_rt_a
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
  type, abstract, extends(cpp_object) :: cpp_memptr_o_d
  contains
    procedure(i_cpp_memptr_o_d), deferred :: invoke
  end type cpp_memptr_o_d
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
  type, abstract, extends(cpp_object) :: cpp_refget_z
  contains
    procedure(i_cpp_refget_z), deferred :: invoke
  end type cpp_refget_z
  type :: cpp_reviter_o
    integer(4) :: cpp_tag = 0
  end type cpp_reviter_o
  type, extends(cpp_object) :: cpp_str
    class(cpp_arr_b), pointer :: b => null()
    integer(4) :: n = 0
  end type cpp_str
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
  type, extends(cpp_cppexception) :: cpp_logicerror
  end type cpp_logicerror
  type, extends(cpp_cppexception) :: cpp_runtimeerror
  end type cpp_runtimeerror
  type, extends(cpp_logicerror) :: cpp_invalidargument
  end type cpp_invalidargument
  type, extends(cpp_logicerror) :: cpp_outofrange
  end type cpp_outofrange
  class(cpp_object), pointer :: cpp_exc => null()
  abstract interface
    function cpp_maker() result(zres)
      class(*), pointer :: zres
    end function
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
  recursive function cpp_invalidargument_new_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    class(cpp_invalidargument), pointer :: zres
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
  recursive function cpp_u2d(a1) result(zres)
    integer(8), value :: a1
    real(8) :: zres
  end function
  recursive function cpp_udiv8(a1, a2) result(zres)
    integer(8), value :: a1
    integer(8), value :: a2
    integer(8) :: zres
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
end module cpp_rt_a
