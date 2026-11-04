! cpp_rt_b - STUB of part B of the Fortran runtime (types as the engine sees them, empty bodies), made by
! f90/tools/split_stub.py from the translator's stub. Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
module cpp_rt_b
  use cpp_rt_a
  use cpp_rt_c
  implicit none
  type, extends(cpp_object) :: cpp_hashtable
  end type cpp_hashtable
  type, extends(cpp_object) :: cpp_less_d
  end type cpp_less_d
  type, extends(cpp_object) :: cpp_less_i
  end type cpp_less_i
  type, extends(cpp_object) :: cpp_less_o
  end type cpp_less_o
  type, extends(cpp_object) :: cpp_map
  end type cpp_map
  type :: cpp_mit
    integer(4) :: cpp_tag = 0
  end type cpp_mit
  type, extends(cpp_object) :: cpp_que
  end type cpp_que
  type, extends(cpp_object) :: cpp_set
  end type cpp_set
  type, extends(cpp_object) :: cpp_stk
  end type cpp_stk
  type, extends(cpp_hashtable) :: cpp_umap
  end type cpp_umap
  type, extends(cpp_hashtable) :: cpp_uset
  end type cpp_uset
  type, extends(cpp_umap) :: cpp_umapc
  end type cpp_umapc
  class(cpp_func_d_d_z), pointer :: cpp_less_d_d_fn
  class(cpp_func_i_i_z), pointer :: cpp_less_i_i_fn
  class(cpp_func_o_o_z), pointer :: cpp_less_o_pairistr_fn
contains
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
end module cpp_rt_b
