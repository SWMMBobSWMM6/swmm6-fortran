! cpp_rt_b.f90 - part B of the Fortran runtime of the SWMM6 engine port (module cpp_rt_b): the containers and
! algorithms of cs/runtime/Containers.cs, StdAlgo.cs, PrimeList.cs and the Algo class of Misc.cs, which are the
! specification. std::unordered_map / unordered_set keep libstdc++'s exact node order (GCC 13 bits/hashtable.h: one
! singly linked list, a bucket array pointing at the node before each bucket's first node, new nodes at the front of
! their bucket, the prime rehash policy with growth factor 2), std::hash is libstdc++'s (identity for integers,
! _Hash_bytes for strings), std::map / std::set are sorted lists, std::stack / std::queue lists, and std::sort is
! libstdc++'s introsort swap for swap (its result with equal keys depends on every swap). The engine iterates hashed
! containers and sorts with ties, so both reach its output; tests/stdcheck/f90 compares them with libstdc++.
!
! Erasure (see the manifest's header): keys, values and elements are class(*) pointers - an engine or runtime object
! itself, or an allocated box holding a number, a logical or a runtime struct. A container keeps the maker and copy
! mode of each type argument the translator hands its constructor. What C# decides from typeof(K) is decided here
! from the value's dynamic type, as the TypeScript and Python ports do: std::hash<K>, EqualityComparer<K>.Default
! and Less<K>.Fn (integers by value, a Str by its bytes, a Pair element by element, TupN by its CompareTo, anything
! else by identity).
!
! Where this differs from the C# on purpose (the same choices as the TypeScript, Java and Python ports):
! - Less<T>.Fn on numbers is the primitive a < b (C++'s std::less; C#'s Comparer<double> orders NaN first). Objects
!   with no order of their own (std::set<const Column*>, which C++ orders by address) get a fixed identity order
!   (C#'s Comparer throws on them). The identity hash is a sequence number given to an object the first time it is
!   hashed or ordered (C#: RuntimeHelpers.GetHashCode; libstdc++: the address, which no port reproduces).
! - KeyCopy<K>.Of (the container's own copy of a key) is decided by the key's dynamic type: a runtime value class
!   (Str, Pair, TupN, Vec, Opt, Variant) is cloned, anything else stored as it is. This is what the contract's key
!   copy mode says when that mode is right, and it stays right when a call site passes another type's mode.
! - Elem<T>.Copy with the copy mode: a box (a number, logical or struct) is always copied, an array deep-copied (as
!   Cpp.ArrCopy), an object cloned through its clone binding; mode 1 (a reference) shares objects and arrays.
! - The hash of a key is computed once per operation (the C# Insert and operator[] compute it again; hashers are
!   pure), and operator[] / emplace copy the key only when they insert it. A hash code is a ulong held in an
!   integer(8); bucket indices, the rehash policy and the prime table use unsigned comparisons and remainders.
! - std::hash of a bool hashes it as 0 / 1 and of an integer(1) as a signed char (C#: an identity hash for bool and
!   byte, which the engine never uses as keys); a float key is hashed as libstdc++ hashes a float.
! - A box does not say whether its integer is signed: an integer(4) key hashes as an int (sign-extended; a uint
!   key would be zero-extended in C#) and integer keys order as signed numbers in Map / Set (a ulong key at or
!   above 2^63 would order last in C#). The engine's unsigned keys (ulong counts and indices) stay below 2^63.
! - UMapC makes its hasher H and key-equal E with the translator's makers, once per container (C#: once per type,
!   new H()); they are called through the engine's hash_of / call2 bindings.
! - Map / Set iterators hold the container's item list, as the C# MIt holds its List<E>; Assign gives the container
!   a new list, so old iterators keep the old one, as in C#.
! - Out-of-range indexing is not checked (C# throws IndexOutOfRange where C++ is undefined).
!
! Procedures that touch components part A keeps private (the a / i of cpp_iter_b, cpp_iter_f, cpp_iter_z and the a / o
! of cpp_ptr_d) and the comparison of part C's TupN are separate module procedures, implemented in the submodule
! cpp_rt_b_ext (cpp_rt_b_ext.f90), so this module compiles against the stubs of parts A and C.
! The file holds two modules: cpp_rt_b0 (the iterator's types and three makers, first) and cpp_rt_b, which re-exports
! what of cpp_rt_b0 the engine sees. The four specialisations of StdAlgo (d, i, l and o) are one text with the
! element type changed.
! Not in the manifest, kept public for tests/stdcheck/f90 (members of the C# classes the engine does not call):
! HashTable erase(K) / bucket_count / rehash / empty, USet Clone / Assign, Map erase / lower_bound / upper_bound /
! count / contains / clear, Set find / count / contains / erase / size / empty / begin / end / clear, Stk Clone /
! Assign, Que push / pop / front / back / empty / size, StdHash.Of and HashBytes, StdAlgo.PartialSort and the
! StableSort of double and long, and Algo count_if / adjacent_find / equal / reverse / remove_if / replace over int.
! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.

! cpp_rt_b0: the types part B's iterators are made of, and the makers part B hands part A's Pair constructor. They are
! a module of their own because gfortran 13 rejects a procedure of the same module as an actual argument for a
! dummy procedure whose interface returns class(*), pointer ("must be a pointer or a valid target"). cpp_rt_b
! re-exports cpp_mit, cpp_b_hnode and cpp_b_list.
module cpp_rt_b0
  use cpp_rt_a
  implicit none
  private
  public :: cpp_b_mk, cpp_b_hnode, cpp_b_nodep, cpp_b_list, cpp_mit, cpp_b_mk_mit, cpp_b_mk_z, cpp_b_mk_null
  ! ------------------------------------------------------------------------------------------------ helper types
  ! A maker held in a component. gfortran 13 miscompiles pointer assignment from a bare procedure-pointer component
  ! whose interface returns class(*), pointer (and ICEs on ASSOCIATED of one); inside a derived type it is copied by
  ! intrinsic assignment, which works.
  type :: cpp_b_mk
    procedure(cpp_maker), pointer, nopass :: f => null()
  end type cpp_b_mk
  ! A hash table node (C# HNode<E>); the before-begin sentinel is a node too. val is the element E: the Pair of a
  ! map, the key of a set.
  type :: cpp_b_hnode
    type(cpp_b_hnode), pointer :: next => null()
    class(*), pointer :: val => null()
    integer(8) :: code = 0_8
  end type cpp_b_hnode
  type :: cpp_b_nodep
    type(cpp_b_hnode), pointer :: p => null()
  end type cpp_b_nodep
  ! The List<E> of a Map, a Set (and the storage of Stk, Que): slots 0 .. n-1.
  type :: cpp_b_list
    type(cpp_slot), allocatable :: a(:)
    integer(4) :: n = 0
  end type cpp_b_list

  ! An iterator over a hashed container (a node, null at the end) or a sorted one (a position in a list).
  type :: cpp_mit
    integer(4) :: cpp_tag = 0
    type(cpp_b_hnode), pointer :: node => null()
    type(cpp_b_list), pointer :: lst => null()
    integer(4) :: pos = 0
  end type cpp_mit
contains
  ! makers of the parts of the Pair<MIt<E>, bool> that insert and emplace return, and of nothing
  recursive function cpp_b_mk_mit() result(zres)
    class(*), pointer :: zres
    allocate(zres, source=cpp_mit())
  end function
  recursive function cpp_b_mk_z() result(zres)
    class(*), pointer :: zres
    allocate(zres, source=.false.)
  end function
  recursive function cpp_b_mk_null() result(zres)
    class(*), pointer :: zres
    zres => null()
  end function
end module cpp_rt_b0

module cpp_rt_b
  use cpp_rt_a
  use cpp_rt_c
  use cpp_rt_b0
  implicit none
  private
  ! ------------------------------------------------------------------------------------------------ the manifest's
  public :: cpp_hashtable, cpp_less_d, cpp_less_i, cpp_less_o, cpp_map, cpp_mit, cpp_que, cpp_set, cpp_stk
  public :: cpp_umap, cpp_umapc, cpp_uset, cpp_less_d_d_fn, cpp_less_i_i_fn, cpp_less_o_pairistr_fn
  public :: cpp_algo_accumulate_iterd_iterd_d, cpp_algo_all_of__d, cpp_algo_all_of__o, cpp_algo_any_of__b
  public :: cpp_algo_any_of__d, cpp_algo_any_of__i, cpp_algo_any_of__o, cpp_algo_any_of__z, cpp_algo_begin_ta__d
  public :: cpp_algo_begin_ta__z, cpp_algo_copy_itert_itert_itert__d, cpp_algo_copy_n_ptrt_ul_ptrt__d
  public :: cpp_algo_count__b, cpp_algo_end_ta__d, cpp_algo_end_ta__z, cpp_algo_fill_itert_itert_t__b
  public :: cpp_algo_fill_itert_itert_t__d, cpp_algo_fill_itert_itert_t__f, cpp_algo_fill_itert_itert_t__i
  public :: cpp_algo_fill_itert_itert_t__z, cpp_algo_fill_n_ptrt_ul_t__d, cpp_algo_fill_ptrt_ptrt_t__d
  public :: cpp_algo_find__b, cpp_algo_find__o, cpp_algo_find_if__o, cpp_algo_iota_iterul_iterul_ul
  public :: cpp_algo_is_sorted_itert_itert__d, cpp_algo_lower_bound_itert_itert_t__d
  public :: cpp_algo_lower_bound_itert_itert_t__i, cpp_algo_lower_bound_itert_itert_v_functvb__od
  public :: cpp_algo_max_element_itert_itert__d, cpp_algo_min_element_itert_itert__d, cpp_algo_none_of__i
  public :: cpp_algo_none_of__o, cpp_algo_replace__b, cpp_algo_transform_itert_itert_iteru_functu__bb
  public :: cpp_algo_transform_iteruc_iteruc_iteruc_funcucc, cpp_algo_unique_itert_itert__i
  public :: cpp_algo_upper_bound_itert_itert_t__d, cpp_algo_vecfrom__d, cpp_algo_vecfrom__i, cpp_algo_vecfrom__o
  public :: cpp_hashtable_begin, cpp_hashtable_clear, cpp_hashtable_contains, cpp_hashtable_count
  public :: cpp_hashtable_end, cpp_hashtable_erase_mite, cpp_hashtable_find, cpp_hashtable_reserve
  public :: cpp_hashtable_size, cpp_map_assign, cpp_map_begin, cpp_map_clone, cpp_map_emplace_k_v, cpp_map_empty
  public :: cpp_map_end, cpp_map_find, cpp_map_index, cpp_map_new_funckkb_funcv, cpp_map_size, cpp_mit_clone
  public :: cpp_mit_deref, cpp_mit_op_eq, cpp_mit_op_inc, cpp_que_assign, cpp_que_clone, cpp_que_new
  public :: cpp_set_assign, cpp_set_clone, cpp_set_insert, cpp_set_new_functtb, cpp_stdalgo_sort__d
  public :: cpp_stdalgo_sort__i, cpp_stdalgo_sort__l, cpp_stdalgo_sort__o, cpp_stdalgo_stablesort__i
  public :: cpp_stdalgo_stablesort__o, cpp_stk_empty, cpp_stk_new, cpp_stk_pop, cpp_stk_push, cpp_stk_size
  public :: cpp_stk_top, cpp_umap_assign, cpp_umap_clone, cpp_umap_emplace_k_v, cpp_umap_index
  public :: cpp_umap_new_funckul_funckkb_funcv, cpp_umap_new_pairkva_funckul_funckkb, cpp_umapc_assign
  public :: cpp_umapc_clone, cpp_umapc_new_funcv, cpp_uset_insert, cpp_uset_new_functul_functtb
  ! ------------------------------------------------------------------------------------------------ extras
  public :: cpp_b_hnode, cpp_b_list
  public :: cpp_hashtable_erase_k, cpp_hashtable_bucket_count, cpp_hashtable_rehash, cpp_hashtable_empty
  public :: cpp_uset_clone, cpp_uset_assign
  public :: cpp_map_erase_k, cpp_map_lower_bound, cpp_map_upper_bound, cpp_map_count, cpp_map_contains, cpp_map_clear
  public :: cpp_set_find, cpp_set_count, cpp_set_contains, cpp_set_erase_t, cpp_set_size, cpp_set_empty, &
            cpp_set_begin, cpp_set_end, cpp_set_clear
  public :: cpp_stk_clone, cpp_stk_assign
  public :: cpp_que_push, cpp_que_pop, cpp_que_front, cpp_que_back, cpp_que_empty, cpp_que_size
  public :: cpp_stdhash_of_str, cpp_stdhash_of_i, cpp_stdhash_of_l, cpp_stdhash_of_u, cpp_stdhash_of_ul, &
            cpp_stdhash_hashbytes
  public :: cpp_stdalgo_partialsort__d, cpp_stdalgo_partialsort__i, cpp_stdalgo_partialsort__l, &
            cpp_stdalgo_partialsort__o, cpp_stdalgo_stablesort__d, cpp_stdalgo_stablesort__l
  public :: cpp_algo_count_if__i, cpp_algo_adjacent_find_itert_itert__i, cpp_algo_equal__i, cpp_algo_reverse__i, &
            cpp_algo_remove_if__i, cpp_algo_replace__i

  ! ------------------------------------------------------------------------------------------------ the types
  ! libstdc++'s _Hashtable for unique keys (C# HashTable<K, E>, with UMap's and USet's state).
  type, extends(cpp_object) :: cpp_hashtable
    type(cpp_b_nodep), allocatable :: bk(:)          ! buckets(0:nbk-1): the node before each bucket's first node
    type(cpp_b_hnode), pointer :: bb => null()       ! before-begin
    integer(8) :: nbk = 0_8
    integer(8) :: nelem = 0_8
    real(8) :: maxload = 1.0_8                        ! the rehash policy
    integer(8) :: nextresize = 0_8
    logical :: isset = .false.                        ! E is the key (a set) or a Pair (a map)
    class(cpp_func_o_l), pointer :: hfn => null()     ! the hasher passed in (null: std::hash<K> by value)
    class(cpp_func_o_o_z), pointer :: eqfn => null()  ! the key-equal passed in (null: EqualityComparer<K>.Default)
    class(cpp_object), pointer :: hobj => null()      ! UMapC's H and E (called through hash_of / call2)
    class(cpp_object), pointer :: eobj => null()
    class(cpp_func_o), pointer :: vmk => null()       ! UMap's mk: how to make a mapped value V alone cannot describe
    type(cpp_b_mk) :: mkk                             ! Elem<K>.Make, Elem<V>.Make and the copy modes
    type(cpp_b_mk) :: mkv
    integer(4) :: cmk = 0
    integer(4) :: cmv = 0
    logical :: hasmk = .false.
  contains
    procedure :: clone => cpp_b_ht_clone_
    procedure :: assign => cpp_b_ht_assign_
  end type cpp_hashtable
  type, extends(cpp_object) :: cpp_less_d
  end type cpp_less_d
  type, extends(cpp_object) :: cpp_less_i
  end type cpp_less_i
  type, extends(cpp_object) :: cpp_less_o
  end type cpp_less_o
  ! std::map: keys kept sorted by the comparator in a list of Pairs.
  type, extends(cpp_object) :: cpp_map
    type(cpp_b_list), pointer :: items => null()
    class(cpp_func_o_o_z), pointer :: lt => null()    ! null: Less<K>.Fn
    class(cpp_func_o), pointer :: vmk => null()
    type(cpp_b_mk) :: mkk
    type(cpp_b_mk) :: mkv
    integer(4) :: cmk = 0
    integer(4) :: cmv = 0
  contains
    procedure :: clone => cpp_b_map_clone_
    procedure :: assign => cpp_b_map_assign_
  end type cpp_map
  ! std::queue: items a(head:n-1).
  type, extends(cpp_object) :: cpp_que
    type(cpp_slot), allocatable :: a(:)
    integer(4) :: n = 0
    integer(4) :: head = 0
    type(cpp_b_mk) :: mk
    integer(4) :: cm = 0
  contains
    procedure :: clone => cpp_b_que_clone_
    procedure :: assign => cpp_b_que_assign_
  end type cpp_que
  ! std::set: keys kept sorted by the comparator.
  type, extends(cpp_object) :: cpp_set
    type(cpp_b_list), pointer :: items => null()
    class(cpp_func_o_o_z), pointer :: lt => null()
    type(cpp_b_mk) :: mk
    integer(4) :: cm = 0
  contains
    procedure :: clone => cpp_b_set_clone_
    procedure :: assign => cpp_b_set_assign_
  end type cpp_set
  ! std::stack: items a(0:n-1), the top last.
  type, extends(cpp_object) :: cpp_stk
    type(cpp_slot), allocatable :: a(:)
    integer(4) :: n = 0
    type(cpp_b_mk) :: mk
    integer(4) :: cm = 0
  contains
    procedure :: clone => cpp_b_stk_clone_
    procedure :: assign => cpp_b_stk_assign_
  end type cpp_stk
  type, extends(cpp_hashtable) :: cpp_umap
  end type cpp_umap
  type, extends(cpp_hashtable) :: cpp_uset
  end type cpp_uset
  type, extends(cpp_umap) :: cpp_umapc
  end type cpp_umapc

  ! Less<T>.Fn as delegates
  type, extends(cpp_func_d_d_z) :: cpp_b_lessd_t
  contains
    procedure :: invoke => cpp_b_lessd_invoke
  end type cpp_b_lessd_t
  type, extends(cpp_func_i_i_z) :: cpp_b_lessi_t
  contains
    procedure :: invoke => cpp_b_lessi_invoke
  end type cpp_b_lessi_t
  type, extends(cpp_func_o_o_z) :: cpp_b_lesso_t
  contains
    procedure :: invoke => cpp_b_lesso_invoke
  end type cpp_b_lesso_t
  type(cpp_b_lessd_t), target, save :: cpp_b_lessd_obj
  type(cpp_b_lessi_t), target, save :: cpp_b_lessi_obj
  type(cpp_b_lesso_t), target, save :: cpp_b_lesso_obj
  ! static field Cpp.Less<T>.Fn of Less<double>, Less<int>, Less<Pair<int, Str>> (the last orders any values)
  class(cpp_func_d_d_z), pointer :: cpp_less_d_d_fn => cpp_b_lessd_obj
  class(cpp_func_i_i_z), pointer :: cpp_less_i_i_fn => cpp_b_lessi_obj
  class(cpp_func_o_o_z), pointer :: cpp_less_o_pairistr_fn => cpp_b_lesso_obj

  ! ------------------------------------------------------------------------------------------------ constants
  ! 0xc6a4a7935bd1e995, the multiplier of _Hash_bytes; 0xc70f6907, std::hash's seed
  integer(8), parameter :: cpp_b_mul = -4132994306676758123_8
  integer(8), parameter :: cpp_b_seed = 3339675911_8
  ! libstdc++'s __prime_list (PrimeList.cs, from the system libstdc++); the last entry, 18446744073709551557, is
  ! held as its bit pattern
  integer(8), parameter :: cpp_b_primes(0:303) = [ &
    2_8, 3_8, 5_8, 7_8, 11_8, 13_8, &
    17_8, 19_8, 23_8, 29_8, 31_8, 37_8, &
    41_8, 43_8, 47_8, 53_8, 59_8, 61_8, &
    67_8, 71_8, 73_8, 79_8, 83_8, 89_8, &
    97_8, 103_8, 109_8, 113_8, 127_8, 137_8, &
    139_8, 149_8, 157_8, 167_8, 179_8, 193_8, &
    199_8, 211_8, 227_8, 241_8, 257_8, 277_8, &
    293_8, 313_8, 337_8, 359_8, 383_8, 409_8, &
    439_8, 467_8, 503_8, 541_8, 577_8, 619_8, &
    661_8, 709_8, 761_8, 823_8, 887_8, 953_8, &
    1031_8, 1109_8, 1193_8, 1289_8, 1381_8, 1493_8, &
    1613_8, 1741_8, 1879_8, 2029_8, 2179_8, 2357_8, &
    2549_8, 2753_8, 2971_8, 3209_8, 3469_8, 3739_8, &
    4027_8, 4349_8, 4703_8, 5087_8, 5503_8, 5953_8, &
    6427_8, 6949_8, 7517_8, 8123_8, 8783_8, 9497_8, &
    10273_8, 11113_8, 12011_8, 12983_8, 14033_8, 15173_8, &
    16411_8, 17749_8, 19183_8, 20753_8, 22447_8, 24281_8, &
    26267_8, 28411_8, 30727_8, 33223_8, 35933_8, 38873_8, &
    42043_8, 45481_8, 49201_8, 53201_8, 57557_8, 62233_8, &
    67307_8, 72817_8, 78779_8, 85229_8, 92203_8, 99733_8, &
    107897_8, 116731_8, 126271_8, 136607_8, 147793_8, 159871_8, &
    172933_8, 187091_8, 202409_8, 218971_8, 236897_8, 256279_8, &
    277261_8, 299951_8, 324503_8, 351061_8, 379787_8, 410857_8, &
    444487_8, 480881_8, 520241_8, 562841_8, 608903_8, 658753_8, &
    712697_8, 771049_8, 834181_8, 902483_8, 976369_8, 1056323_8, &
    1142821_8, 1236397_8, 1337629_8, 1447153_8, 1565659_8, 1693859_8, &
    1832561_8, 1982627_8, 2144977_8, 2320627_8, 2510653_8, 2716249_8, &
    2938679_8, 3179303_8, 3439651_8, 3721303_8, 4026031_8, 4355707_8, &
    4712381_8, 5098259_8, 5515729_8, 5967347_8, 6456007_8, 6984629_8, &
    7556579_8, 8175383_8, 8844859_8, 9569143_8, 10352717_8, 11200489_8, &
    12117689_8, 13109983_8, 14183539_8, 15345007_8, 16601593_8, 17961079_8, &
    19431899_8, 21023161_8, 22744717_8, 24607243_8, 26622317_8, 28802401_8, &
    31160981_8, 33712729_8, 36473443_8, 39460231_8, 42691603_8, 46187573_8, &
    49969847_8, 54061849_8, 58488943_8, 63278561_8, 68460391_8, 74066549_8, &
    80131819_8, 86693767_8, 93793069_8, 101473717_8, 109783337_8, 118773397_8, &
    128499677_8, 139022417_8, 150406843_8, 162723577_8, 176048909_8, 190465427_8, &
    206062531_8, 222936881_8, 241193053_8, 260944219_8, 282312799_8, 305431229_8, &
    330442829_8, 357502601_8, 386778277_8, 418451333_8, 452718089_8, 489790921_8, &
    529899637_8, 573292817_8, 620239453_8, 671030513_8, 725980837_8, 785430967_8, &
    849749479_8, 919334987_8, 994618837_8, 1076067617_8, 1164186217_8, 1259520799_8, &
    1362662261_8, 1474249943_8, 1594975441_8, 1725587117_8, 1866894511_8, 2019773507_8, &
    2185171673_8, 2364114217_8, 2557710269_8, 2767159799_8, 2993761039_8, 3238918481_8, &
    3504151727_8, 3791104843_8, 4101556399_8, 4294967291_8, 6442450933_8, 8589934583_8, &
    12884901857_8, 17179869143_8, 25769803693_8, 34359738337_8, 51539607367_8, 68719476731_8, &
    103079215087_8, 137438953447_8, 206158430123_8, 274877906899_8, 412316860387_8, 549755813881_8, &
    824633720731_8, 1099511627689_8, 1649267441579_8, 2199023255531_8, 3298534883309_8, 4398046511093_8, &
    6597069766607_8, 8796093022151_8, 13194139533241_8, 17592186044399_8, 26388279066581_8, 35184372088777_8, &
    52776558133177_8, 70368744177643_8, 105553116266399_8, 140737488355213_8, 211106232532861_8, 281474976710597_8, &
    562949953421231_8, 1125899906842597_8, 2251799813685119_8, 4503599627370449_8, 9007199254740881_8, 18014398509481951_8, &
    36028797018963913_8, 72057594037927931_8, 144115188075855859_8, 288230376151711717_8, 576460752303423433_8, 1152921504606846883_8, &
    2305843009213693951_8, 4611686018427387847_8, 9223372036854775783_8, -59_8 ]
  integer(4), parameter :: cpp_b_fastbkt(0:13) = [2, 2, 2, 3, 5, 5, 7, 7, 11, 11, 11, 11, 13, 13]

  ! the identity numbers (address -> number, open addressing)
  integer(8), allocatable, save :: cpp_b_idk(:), cpp_b_idv(:)
  integer(8), save :: cpp_b_idn = 0_8

  ! ------------------------------------------------------------------------------------------------ the submodule
  interface
    ! TupN.CompareTo (part C's TupN)
    recursive module function cpp_b_tupn_cmp(a, b) result(zres)
      class(cpp_tupn), intent(inout), target :: a
      class(cpp_tupn), intent(inout), target :: b
      integer(4) :: zres
    end function
    recursive module function cpp_algo_any_of__b(a1, a2, a3) result(zres)
      type(cpp_iter_b), intent(in) :: a1
      type(cpp_iter_b), intent(in) :: a2
      class(cpp_func_b_z), pointer, intent(in) :: a3
      logical :: zres
    end function
    recursive module function cpp_algo_any_of__z(a1, a2, a3) result(zres)
      type(cpp_iter_z), intent(in) :: a1
      type(cpp_iter_z), intent(in) :: a2
      class(cpp_func_z_z), pointer, intent(in) :: a3
      logical :: zres
    end function
    recursive module function cpp_algo_begin_ta__z(a1) result(zres)
      class(cpp_arr_z), pointer, intent(in) :: a1
      type(cpp_iter_z) :: zres
    end function
    recursive module function cpp_algo_end_ta__z(a1) result(zres)
      class(cpp_arr_z), pointer, intent(in) :: a1
      type(cpp_iter_z) :: zres
    end function
    recursive module function cpp_algo_copy_n_ptrt_ul_ptrt__d(a1, a2, a3) result(zres)
      type(cpp_ptr_d), intent(in) :: a1
      integer(8), value :: a2
      type(cpp_ptr_d), intent(in) :: a3
      type(cpp_ptr_d) :: zres
    end function
    recursive module function cpp_algo_count__b(a1, a2, a3) result(zres)
      type(cpp_iter_b), intent(in) :: a1
      type(cpp_iter_b), intent(in) :: a2
      integer(1), value :: a3
      integer(8) :: zres
    end function
    recursive module subroutine cpp_algo_fill_itert_itert_t__b(a1, a2, a3)
      type(cpp_iter_b), intent(in) :: a1
      type(cpp_iter_b), intent(in) :: a2
      integer(1), value :: a3
    end subroutine
    recursive module subroutine cpp_algo_fill_itert_itert_t__f(a1, a2, a3)
      type(cpp_iter_f), intent(in) :: a1
      type(cpp_iter_f), intent(in) :: a2
      real(4), value :: a3
    end subroutine
    recursive module subroutine cpp_algo_fill_itert_itert_t__z(a1, a2, a3)
      type(cpp_iter_z), intent(in) :: a1
      type(cpp_iter_z), intent(in) :: a2
      logical, value :: a3
    end subroutine
    recursive module function cpp_algo_fill_n_ptrt_ul_t__d(a1, a2, a3) result(zres)
      type(cpp_ptr_d), intent(in) :: a1
      integer(8), value :: a2
      real(8), value :: a3
      type(cpp_ptr_d) :: zres
    end function
    recursive module subroutine cpp_algo_fill_ptrt_ptrt_t__d(a1, a2, a3)
      type(cpp_ptr_d), intent(in) :: a1
      type(cpp_ptr_d), intent(in) :: a2
      real(8), value :: a3
    end subroutine
    recursive module function cpp_algo_find__b(a1, a2, a3) result(zres)
      type(cpp_iter_b), intent(in) :: a1
      type(cpp_iter_b), intent(in) :: a2
      integer(1), value :: a3
      type(cpp_iter_b) :: zres
    end function
    recursive module subroutine cpp_algo_replace__b(a1, a2, a3, a4)
      type(cpp_iter_b), intent(in) :: a1
      type(cpp_iter_b), intent(in) :: a2
      integer(1), value :: a3
      integer(1), value :: a4
    end subroutine
    recursive module function cpp_algo_transform_itert_itert_iteru_functu__bb(a1, a2, a3, a4) result(zres)
      type(cpp_iter_b), intent(in) :: a1
      type(cpp_iter_b), intent(in) :: a2
      type(cpp_iter_b), intent(in) :: a3
      class(cpp_func_b_b), pointer, intent(in) :: a4
      type(cpp_iter_b) :: zres
    end function
    recursive module function cpp_algo_transform_iteruc_iteruc_iteruc_funcucc(a1, a2, a3, a4) result(zres)
      type(cpp_iter_b), intent(in) :: a1
      type(cpp_iter_b), intent(in) :: a2
      type(cpp_iter_b), intent(in) :: a3
      class(cpp_func_b_b), pointer, intent(in) :: a4
      type(cpp_iter_b) :: zres
    end function
  end interface

contains
  ! ================================================================================================ unsigned helpers
  ! x mod n for x a ulong (its bit pattern in x) and 0 < n < 2^62
  recursive function cpp_b_umod(x, n) result(r)
    integer(8), value :: x, n
    integer(8) :: r
    if (x >= 0_8) then
      r = mod(x, n)
    else
      r = mod(ishft(x, -1), n)
      r = mod(2_8 * r + iand(x, 1_8), n)
    end if
  end function

  ! (double) of a ulong
  recursive function cpp_b_u2d(x) result(r)
    integer(8), value :: x
    real(8) :: r
    if (x >= 0_8) then
      r = real(x, 8)
    else
      r = real(x, 8) + 18446744073709551616.0_8
    end if
  end function

  ! (ulong) of a non-negative integral double
  recursive function cpp_b_d2ul(x) result(r)
    real(8), value :: x
    integer(8) :: r
    if (x < 9223372036854775808.0_8) then
      r = int(x, 8)
    else
      r = int(x - 18446744073709551616.0_8, 8)
    end if
  end function

  ! Math.Max of two ulongs
  recursive function cpp_b_umax(a, b) result(r)
    integer(8), value :: a, b
    integer(8) :: r
    if (bgt(a, b)) then
      r = a
    else
      r = b
    end if
  end function

  ! 63 - LeadingZeroCount(n): floor(log2(n)) for n > 0
  recursive function cpp_b_lg(n) result(r)
    integer(8), value :: n
    integer(4) :: r
    r = 63 - leadz(n)
  end function

  ! ================================================================================================ std::hash
  recursive function cpp_b_shift_mix(v) result(r)
    integer(8), value :: v
    integer(8) :: r
    r = ieor(v, ishft(v, -47))
  end function

  ! libstdc++'s std::_Hash_bytes (libsupc++/hash_bytes.cc, the 64-bit branch) of b(off .. off+len-1)
  recursive function cpp_b_hash_bytes(b, off, len, seed) result(h)
    integer(1), intent(in) :: b(0:)
    integer(4), value :: off, len
    integer(8), value :: seed
    integer(8) :: h, d
    integer(4) :: aligned, p, rest, k
    aligned = iand(len, not(7))
    h = ieor(seed, int(len, 8) * cpp_b_mul)
    p = off
    do while (p < off + aligned)
      d = 0_8
      do k = 7, 0, -1
        d = ior(ishft(d, 8), iand(int(b(p + k), 8), 255_8))
      end do
      d = cpp_b_shift_mix(d * cpp_b_mul) * cpp_b_mul
      h = ieor(h, d)
      h = h * cpp_b_mul
      p = p + 8
    end do
    rest = iand(len, 7)
    if (rest /= 0) then
      d = 0_8
      do k = rest - 1, 0, -1
        d = ishft(d, 8) + iand(int(b(p + k), 8), 255_8)
      end do
      h = ieor(h, d)
      h = h * cpp_b_mul
    end if
    h = cpp_b_shift_mix(h) * cpp_b_mul
    h = cpp_b_shift_mix(h)
  end function

  recursive function cpp_b_hash_str(s) result(h)
    class(cpp_str), intent(in) :: s
    integer(8) :: h
    integer(1) :: none(0:0)
    if (s%n <= 0) then
      none = 0_1
      h = cpp_b_hash_bytes(none, 0, 0, cpp_b_seed)
    else
      h = cpp_b_hash_bytes(s%b%a, 0, s%n, cpp_b_seed)
    end if
  end function

  ! std::hash<K> of a key by its dynamic type (C#: StdHash.For<K>())
  recursive function cpp_b_stdhash(k) result(h)
    class(*), pointer, intent(in) :: k
    integer(8) :: h
    logical :: ident
    h = 0_8
    if (.not. associated(k)) return
    ident = .false.
    select type (kk => k)
    type is (integer(4))
      h = int(kk, 8)
    type is (integer(8))
      h = kk
    type is (integer(2))
      h = int(kk, 8)
    type is (integer(1))
      h = int(kk, 8)
    type is (logical)
      if (kk) h = 1_8
    type is (real(8))
      if (kk /= 0.0_8) h = cpp_b_hash_bytes(transfer(kk, [0_1], 8), 0, 8, cpp_b_seed)
    type is (real(4))
      if (kk /= 0.0_4) h = cpp_b_hash_bytes(transfer(kk, [0_1], 4), 0, 4, cpp_b_seed)
    class is (cpp_str)
      h = cpp_b_hash_str(kk)
    class default
      ident = .true.
    end select
    if (ident) h = cpp_b_ident(k)
  end function

  ! an object's identity number: a sequence number given the first time it is asked for
  recursive function cpp_b_ident(x) result(id)
    class(*), pointer, intent(in) :: x
    integer(8) :: id, addr, h, cap, i
    integer(8), allocatable :: ok(:), ov(:)
    id = 0_8
    if (.not. associated(x)) return
    addr = loc(x)
    if (.not. allocated(cpp_b_idk)) then
      allocate(cpp_b_idk(0:1023), cpp_b_idv(0:1023))
      cpp_b_idk = 0_8
      cpp_b_idv = 0_8
    end if
    cap = size(cpp_b_idk, kind=8)
    h = cpp_b_idslot(addr, cap)
    do
      if (cpp_b_idk(h) == addr) then
        id = cpp_b_idv(h)
        return
      end if
      if (cpp_b_idk(h) == 0_8) exit
      h = iand(h + 1_8, cap - 1_8)
    end do
    cpp_b_idn = cpp_b_idn + 1_8
    id = cpp_b_idn
    cpp_b_idk(h) = addr
    cpp_b_idv(h) = id
    if (2_8 * cpp_b_idn > cap) then
      call move_alloc(cpp_b_idk, ok)
      call move_alloc(cpp_b_idv, ov)
      allocate(cpp_b_idk(0:2_8 * cap - 1_8), cpp_b_idv(0:2_8 * cap - 1_8))
      cpp_b_idk = 0_8
      cpp_b_idv = 0_8
      do i = 0_8, cap - 1_8
        if (ok(i) /= 0_8) then
          h = cpp_b_idslot(ok(i), 2_8 * cap)
          do while (cpp_b_idk(h) /= 0_8)
            h = iand(h + 1_8, 2_8 * cap - 1_8)
          end do
          cpp_b_idk(h) = ok(i)
          cpp_b_idv(h) = ov(i)
        end if
      end do
    end if
  end function

  recursive function cpp_b_idslot(addr, cap) result(h)
    integer(8), value :: addr, cap
    integer(8) :: h
    h = iand(ishft(addr * (-7046029254386353131_8), -20), cap - 1_8)
  end function

  ! ---- StdHash (extras)
  recursive function cpp_stdhash_hashbytes(a1, a2, a3, a4) result(zres)
    class(cpp_arr_b), pointer, intent(in) :: a1
    integer(4), value :: a2
    integer(4), value :: a3
    integer(8), value :: a4
    integer(8) :: zres
    integer(1) :: none(0:0)
    if (a3 <= 0) then
      none = 0_1
      zres = cpp_b_hash_bytes(none, 0, 0, a4)
    else
      zres = cpp_b_hash_bytes(a1%a, a2, a3, a4)
    end if
  end function
  recursive function cpp_stdhash_of_str(a1) result(zres)
    class(cpp_str), pointer, intent(in) :: a1
    integer(8) :: zres
    zres = cpp_b_hash_str(a1)
  end function
  recursive function cpp_stdhash_of_i(a1) result(zres)
    integer(4), value :: a1
    integer(8) :: zres
    zres = int(a1, 8)
  end function
  recursive function cpp_stdhash_of_l(a1) result(zres)
    integer(8), value :: a1
    integer(8) :: zres
    zres = a1
  end function
  recursive function cpp_stdhash_of_u(a1) result(zres)
    integer(4), value :: a1
    integer(8) :: zres
    zres = iand(int(a1, 8), 4294967295_8)
  end function
  recursive function cpp_stdhash_of_ul(a1) result(zres)
    integer(8), value :: a1
    integer(8) :: zres
    zres = a1
  end function

  ! ================================================================================================ equality, order
  recursive function cpp_b_str_eq(x, y) result(r)
    class(cpp_str), intent(in) :: x, y
    logical :: r
    integer(4) :: i
    r = .false.
    if (x%n /= y%n) return
    do i = 0, x%n - 1
      if (x%b%a(i) /= y%b%a(i)) return
    end do
    r = .true.
  end function

  ! Str.compare: unsigned bytes, then the length
  recursive function cpp_b_str_cmp(x, y) result(c)
    class(cpp_str), intent(in) :: x, y
    integer(4) :: c, m, i, p, q
    m = min(x%n, y%n)
    do i = 0, m - 1
      p = iand(int(x%b%a(i), 4), 255)
      q = iand(int(y%b%a(i), 4), 255)
      if (p /= q) then
        if (p < q) then
          c = -1
        else
          c = 1
        end if
        return
      end if
    end do
    c = x%n - y%n
  end function

  ! EqualityComparer<K>.Default.Equals by the dynamic type: numbers by value (double.Equals: NaN equals NaN), a Str
  ! by its bytes, TupN by its CompareTo, CPtr and MIt by their ==, everything else (engine objects, Pair) by identity
  recursive function cpp_b_eq(a, b) result(r)
    class(*), pointer, intent(in) :: a, b
    logical :: r
    r = .false.
    if (.not. associated(a)) then
      r = .not. associated(b)
      return
    end if
    if (.not. associated(b)) return
    if (associated(a, b)) then
      r = .true.
      return
    end if
    select type (x => a)
    type is (integer(4))
      select type (y => b)
      type is (integer(4))
        r = x == y
      end select
    type is (integer(8))
      select type (y => b)
      type is (integer(8))
        r = x == y
      end select
    type is (integer(2))
      select type (y => b)
      type is (integer(2))
        r = x == y
      end select
    type is (integer(1))
      select type (y => b)
      type is (integer(1))
        r = x == y
      end select
    type is (logical)
      select type (y => b)
      type is (logical)
        r = x .eqv. y
      end select
    type is (real(8))
      select type (y => b)
      type is (real(8))
        r = x == y
        if (.not. r) r = (x /= x) .and. (y /= y)
      end select
    type is (real(4))
      select type (y => b)
      type is (real(4))
        r = x == y
        if (.not. r) r = (x /= x) .and. (y /= y)
      end select
    class is (cpp_str)
      select type (y => b)
      class is (cpp_str)
        r = cpp_b_str_eq(x, y)
      end select
    class is (cpp_tupn)
      select type (y => b)
      class is (cpp_tupn)
        r = cpp_b_tupn_cmp(x, y) == 0
      end select
    type is (cpp_cptr)
      select type (y => b)
      type is (cpp_cptr)
        if (.not. associated(x%b)) then
          r = .not. associated(y%b)
        else if (associated(x%b, y%b)) then
          r = x%o == y%o
        end if
      end select
    type is (cpp_mit)
      select type (y => b)
      type is (cpp_mit)
        r = cpp_mit_op_eq(x, y)
      end select
    end select
  end function

  ! Less<K>.Fn by the dynamic type: numbers with the primitive <, false before true, a Str as std::string compares,
  ! a Pair first then second, TupN by its CompareTo, null first, anything else by a fixed identity order
  recursive function cpp_b_less(a, b) result(r)
    class(*), pointer, intent(in) :: a, b
    logical :: r, ident
    r = .false.
    if (.not. associated(a)) then
      r = associated(b)
      return
    end if
    if (.not. associated(b)) return
    ident = .false.
    select type (x => a)
    type is (integer(4))
      select type (y => b)
      type is (integer(4))
        r = x < y
      end select
    type is (integer(8))
      select type (y => b)
      type is (integer(8))
        r = x < y
      end select
    type is (integer(2))
      select type (y => b)
      type is (integer(2))
        r = x < y
      end select
    type is (integer(1))
      select type (y => b)
      type is (integer(1))
        r = x < y
      end select
    type is (real(8))
      select type (y => b)
      type is (real(8))
        r = x < y
      end select
    type is (real(4))
      select type (y => b)
      type is (real(4))
        r = x < y
      end select
    type is (logical)
      select type (y => b)
      type is (logical)
        if (.not. x) r = y
      end select
    class is (cpp_str)
      select type (y => b)
      class is (cpp_str)
        r = cpp_b_str_cmp(x, y) < 0
      end select
    class is (cpp_pair)
      select type (y => b)
      class is (cpp_pair)
        if (cpp_b_less(x%first%p, y%first%p)) then
          r = .true.
        else if (cpp_b_less(y%first%p, x%first%p)) then
          r = .false.
        else
          r = cpp_b_less(x%second%p, y%second%p)
        end if
      end select
    class is (cpp_tupn)
      select type (y => b)
      class is (cpp_tupn)
        r = cpp_b_tupn_cmp(x, y) < 0
      end select
    class default
      ident = .true.
    end select
    if (ident) then
      if (.not. associated(a, b)) r = cpp_b_ident(a) < cpp_b_ident(b)
    end if
  end function

  ! Less<T>.Fn delegates
  recursive function cpp_b_lessd_invoke(self, a1, a2) result(zres)
    class(cpp_b_lessd_t), intent(inout), target :: self
    real(8), value :: a1
    real(8), value :: a2
    logical :: zres
    zres = a1 < a2
  end function
  recursive function cpp_b_lessi_invoke(self, a1, a2) result(zres)
    class(cpp_b_lessi_t), intent(inout), target :: self
    integer(4), value :: a1
    integer(4), value :: a2
    logical :: zres
    zres = a1 < a2
  end function
  recursive function cpp_b_lesso_invoke(self, a1, a2) result(zres)
    class(cpp_b_lesso_t), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(*), pointer, intent(in) :: a2
    logical :: zres
    zres = cpp_b_less(a1, a2)
  end function

  ! ================================================================================================ element copies
  ! KeyCopy<K>.Of: a key that is a runtime value (Str, Pair, TupN, Vec, Opt, Variant) is the container's own copy;
  ! anything else (an engine object: a pointer in C++, a box) is stored as it is
  recursive function cpp_b_keycopy(x) result(y)
    class(*), pointer, intent(in) :: x
    class(*), pointer :: y
    class(cpp_object), pointer :: o
    logical :: rt
    y => x
    if (.not. associated(x)) return
    rt = .false.
    select type (xx => x)
    class is (cpp_str)
      rt = .true.
    class is (cpp_pair)
      rt = .true.
    class is (cpp_tupn)
      rt = .true.
    class is (cpp_vec_b)
      rt = .true.
    class is (cpp_vec_d)
      rt = .true.
    class is (cpp_vec_f)
      rt = .true.
    class is (cpp_vec_i)
      rt = .true.
    class is (cpp_vec_l)
      rt = .true.
    class is (cpp_vec_o)
      rt = .true.
    class is (cpp_vec_s)
      rt = .true.
    class is (cpp_vec_z)
      rt = .true.
    class is (cpp_opt_d)
      rt = .true.
    class is (cpp_opt_o)
      rt = .true.
    class is (cpp_variant)
      rt = .true.
    end select
    if (.not. rt) return
    select type (xx => x)
    class is (cpp_object)
      o => xx%clone()
      y => o
    end select
  end function

  ! Elem<T>.Copy with copy mode cm (0 value, 1 reference, 2 ICopy, 3 array): a box is copied, an array deep-copied
  ! (as Cpp.ArrCopy), an object cloned; mode 1 shares objects and arrays
  recursive function cpp_b_copy(x, cm) result(y)
    class(*), pointer, intent(in) :: x
    integer(4), value :: cm
    class(*), pointer :: y
    class(cpp_object), pointer :: o
    class(cpp_arr_o), pointer :: ao
    integer(8) :: i
    y => null()
    if (.not. associated(x)) return
    select type (xx => x)
    class is (cpp_arr_o)
      if (cm == 1) then
        y => x
      else
        allocate(ao, source=xx)
        do i = lbound(ao%a, 1, 8), ubound(ao%a, 1, 8)
          ao%a(i)%p => cpp_b_copy(xx%a(i)%p, 2)
          if (associated(cpp_exc)) return
        end do
        y => ao
      end if
    class is (cpp_arr_b)
      y => x
      if (cm /= 1) allocate(y, source=xx)
    class is (cpp_arr_d)
      y => x
      if (cm /= 1) allocate(y, source=xx)
    class is (cpp_arr_f)
      y => x
      if (cm /= 1) allocate(y, source=xx)
    class is (cpp_arr_i)
      y => x
      if (cm /= 1) allocate(y, source=xx)
    class is (cpp_arr_l)
      y => x
      if (cm /= 1) allocate(y, source=xx)
    class is (cpp_arr_s)
      y => x
      if (cm /= 1) allocate(y, source=xx)
    class is (cpp_arr_z)
      y => x
      if (cm /= 1) allocate(y, source=xx)
    class is (cpp_object)
      if (cm == 1) then
        y => x
      else
        o => xx%clone()
        y => o
      end if
    class default
      allocate(y, source=xx)
    end select
  end function

  ! an element handed to an engine delegate: C# passes a value type by value, so a box is copied (the callee may
  ! keep it); an object is itself
  recursive function cpp_b_arg(x, cm) result(y)
    class(*), pointer, intent(in) :: x
    integer(4), value :: cm
    class(*), pointer :: y
    y => x
    if (.not. associated(x)) return
    if (cm /= 0) return
    select type (xx => x)
    class is (cpp_object)
    class default
      allocate(y, source=xx)
    end select
  end function

  ! the Pair<MIt<E>, bool> of insert / emplace
  recursive function cpp_b_insres(it, added) result(zres)
    type(cpp_mit), intent(in) :: it
    logical, intent(in) :: added
    class(cpp_pair), pointer :: zres
    class(*), pointer :: p1, p2
    allocate(p1, source=it)
    allocate(p2, source=added)
    zres => cpp_pair_new_a_b(p1, p2, cpp_b_mk_mit, 0, cpp_b_mk_z, 0)
  end function

  ! the key of a map's Pair
  recursive function cpp_b_first(e) result(k)
    class(*), pointer, intent(in) :: e
    class(*), pointer :: k
    k => null()
    if (.not. associated(e)) return
    select type (pe => e)
    class is (cpp_pair)
      k => pe%first%p
    end select
  end function

  ! ================================================================================================ lists
  recursive subroutine cpp_b_list_init(l)
    type(cpp_b_list), intent(inout) :: l
    if (allocated(l%a)) deallocate(l%a)
    allocate(l%a(0:3))
    l%n = 0
  end subroutine

  recursive subroutine cpp_b_slots_grow(a, n)
    type(cpp_slot), allocatable, intent(inout) :: a(:)
    integer(4), intent(in) :: n
    type(cpp_slot), allocatable :: t(:)
    integer(4) :: cap
    if (.not. allocated(a)) then
      allocate(a(0:3))
      return
    end if
    if (n < size(a)) return
    cap = max(4, 2 * size(a))
    allocate(t(0:cap - 1))
    t(0:n - 1) = a(0:n - 1)
    call move_alloc(t, a)
  end subroutine

  ! List.Insert(i, x)
  recursive subroutine cpp_b_list_insert(l, i, x)
    type(cpp_b_list), intent(inout) :: l
    integer(4), intent(in) :: i
    class(*), pointer, intent(in) :: x
    integer(4) :: k
    call cpp_b_slots_grow(l%a, l%n)
    do k = l%n - 1, i, -1
      l%a(k + 1) = l%a(k)
    end do
    l%a(i)%p => x
    l%n = l%n + 1
  end subroutine

  ! List.Add(x)
  recursive subroutine cpp_b_list_add(l, x)
    type(cpp_b_list), intent(inout) :: l
    class(*), pointer, intent(in) :: x
    call cpp_b_slots_grow(l%a, l%n)
    l%a(l%n)%p => x
    l%n = l%n + 1
  end subroutine

  ! List.RemoveAt(i)
  recursive subroutine cpp_b_list_remove(l, i)
    type(cpp_b_list), intent(inout) :: l
    integer(4), intent(in) :: i
    integer(4) :: k
    do k = i, l%n - 2
      l%a(k) = l%a(k + 1)
    end do
    l%n = l%n - 1
    l%a(l%n)%p => null()
  end subroutine

  ! ================================================================================================ the hash table
  ! the prime rehash policy (libstdc++ src/c++11/hashtable_c++0x.cc and hashtable-aux.cc)
  recursive function cpp_b_next_bkt(t, n) result(r)
    class(cpp_hashtable), intent(inout) :: t
    integer(8), value :: n
    integer(8) :: r
    integer(4) :: lo, hi, mid
    if (n >= 0_8 .and. n < 14_8) then
      if (n == 0_8) then
        r = 1_8
        return
      end if
      t%nextresize = cpp_b_d2ul(aint(real(cpp_b_fastbkt(n), 8) * t%maxload))
      r = int(cpp_b_fastbkt(n), 8)
      return
    end if
    lo = 6
    hi = 303                    ! __prime_list + __n_primes - 1 (the sentinel is excluded)
    do while (lo < hi)
      mid = (lo + hi) / 2
      if (blt(cpp_b_primes(mid), n)) then
        lo = mid + 1
      else
        hi = mid
      end if
    end do
    if (lo == 303) then
      t%nextresize = -1_8       ! ulong.MaxValue
    else
      t%nextresize = cpp_b_d2ul(aint(cpp_b_u2d(cpp_b_primes(lo)) * t%maxload))
    end if
    r = cpp_b_primes(lo)
  end function

  recursive function cpp_b_bkt_for_elements(t, n) result(r)
    class(cpp_hashtable), intent(inout) :: t
    integer(8), value :: n
    integer(8) :: r
    real(8) :: x
    x = cpp_b_u2d(n) / t%maxload
    if (aint(x) < x) then
      x = aint(x) + 1.0_8
    else
      x = aint(x)
    end if
    r = cpp_b_d2ul(x)
  end function

  ! _M_need_rehash: the new bucket count, or 0 for none (C#: the pair (true, n) / (false, 0))
  recursive function cpp_b_need_rehash(t, nbkt, nelt, nins) result(r)
    class(cpp_hashtable), intent(inout) :: t
    integer(8), value :: nbkt, nelt, nins
    integer(8) :: r, tot, floor0
    real(8) :: minb
    r = 0_8
    tot = nelt + nins
    if (bgt(tot, t%nextresize)) then
      floor0 = 11_8
      if (t%nextresize /= 0_8) floor0 = 0_8
      minb = cpp_b_u2d(cpp_b_umax(tot, floor0)) / t%maxload
      if (minb >= cpp_b_u2d(nbkt)) then
        r = cpp_b_next_bkt(t, cpp_b_umax(cpp_b_d2ul(aint(minb)) + 1_8, nbkt * 2_8))
        return
      end if
      t%nextresize = cpp_b_d2ul(aint(cpp_b_u2d(nbkt) * t%maxload))
    end if
  end function

  ! a table made by allocation alone gets one bucket (C#: new HNode[1])
  recursive subroutine cpp_b_ht_ready(t)
    class(cpp_hashtable), intent(inout) :: t
    if (associated(t%bb)) return
    allocate(t%bb)
    allocate(t%bk(0:0))
    t%nbk = 1_8
    if (.not. t%hasmk) then
      t%mkk%f => cpp_b_mk_null
      t%mkv%f => cpp_b_mk_null
      t%hasmk = .true.
    end if
  end subroutine

  recursive subroutine cpp_b_ht_init(t, isset, h, eq, mkk, cmk, mkv, cmv)
    class(cpp_hashtable), intent(inout) :: t
    logical, intent(in) :: isset
    class(cpp_func_o_l), pointer, intent(in) :: h
    class(cpp_func_o_o_z), pointer, intent(in) :: eq
    procedure(cpp_maker) :: mkk
    integer(4), intent(in) :: cmk
    procedure(cpp_maker) :: mkv
    integer(4), intent(in) :: cmv
    t%mkk%f => mkk
    t%mkv%f => mkv
    t%cmk = cmk
    t%cmv = cmv
    t%hasmk = .true.
    call cpp_b_ht_ready(t)
    t%isset = isset
    t%hfn => h
    t%eqfn => eq
  end subroutine

  recursive function cpp_b_ht_key(t, e) result(k)
    class(cpp_hashtable), intent(in) :: t
    class(*), pointer, intent(in) :: e
    class(*), pointer :: k
    if (t%isset) then
      k => e
    else
      k => cpp_b_first(e)
    end if
  end function

  recursive function cpp_b_ht_hash(t, k) result(code)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: k
    integer(8) :: code
    if (associated(t%hobj)) then
      code = t%hobj%hash_of(k)
    else if (associated(t%hfn)) then
      code = t%hfn%invoke(k)
    else
      code = cpp_b_stdhash(k)
    end if
  end function

  recursive function cpp_b_ht_eq(t, a, b) result(r)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: a, b
    logical :: r
    if (associated(t%eobj)) then
      r = t%eobj%call2(a, b)
    else if (associated(t%eqfn)) then
      r = t%eqfn%invoke(a, b)
    else
      r = cpp_b_eq(a, b)
    end if
  end function

  recursive function cpp_b_ht_bkt(t, code) result(b)
    class(cpp_hashtable), intent(in) :: t
    integer(8), value :: code
    integer(8) :: b
    b = cpp_b_umod(code, t%nbk)
  end function

  ! Find(k), the hash code given
  recursive function cpp_b_ht_find(t, k, code) result(f)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: k
    integer(8), value :: code
    type(cpp_b_hnode), pointer :: f, p
    class(*), pointer :: pk
    integer(8) :: b
    logical :: e
    f => null()
    b = cpp_b_ht_bkt(t, code)
    if (.not. associated(t%bk(b)%p)) return
    p => t%bk(b)%p%next
    do while (associated(p))
      if (p%code == code) then
        pk => cpp_b_ht_key(t, p%val)
        e = cpp_b_ht_eq(t, k, pk)
        if (associated(cpp_exc)) return
        if (e) then
          f => p
          return
        end if
      end if
      if (.not. associated(p%next)) exit
      if (cpp_b_ht_bkt(t, p%next%code) /= b) exit
      p => p%next
    end do
  end function

  ! Find(k): the node or null; hashes k (the engine's hasher may throw)
  recursive function cpp_b_ht_findk(t, k) result(f)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: k
    type(cpp_b_hnode), pointer :: f
    integer(8) :: code
    f => null()
    call cpp_b_ht_ready(t)
    code = cpp_b_ht_hash(t, k)
    if (associated(cpp_exc)) return
    f => cpp_b_ht_find(t, k, code)
  end function

  recursive subroutine cpp_b_ht_insert_bucket_begin(t, b, node)
    class(cpp_hashtable), intent(inout) :: t
    integer(8), value :: b
    type(cpp_b_hnode), pointer, intent(in) :: node
    if (associated(t%bk(b)%p)) then
      node%next => t%bk(b)%p%next
      t%bk(b)%p%next => node
    else
      node%next => t%bb%next
      t%bb%next => node
      if (associated(node%next)) t%bk(cpp_b_ht_bkt(t, node%next%code))%p => node
      t%bk(b)%p => t%bb
    end if
  end subroutine

  ! the second half of Insert: e (whose key, of hash code code, is absent) becomes a new node
  recursive function cpp_b_ht_insert_node(t, e, code) result(node)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: e
    integer(8), value :: code
    type(cpp_b_hnode), pointer :: node
    integer(8) :: n
    n = cpp_b_need_rehash(t, t%nbk, t%nelem, 1_8)
    if (n /= 0_8) call cpp_b_ht_rehash_to(t, n)
    allocate(node)
    node%val => e
    node%code = code
    call cpp_b_ht_insert_bucket_begin(t, cpp_b_ht_bkt(t, code), node)
    t%nelem = t%nelem + 1_8
  end function

  ! Insert(e): the node holding e's key and whether e was added
  recursive function cpp_b_ht_insert(t, e, added) result(node)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: e
    logical, intent(out) :: added
    type(cpp_b_hnode), pointer :: node
    class(*), pointer :: k
    integer(8) :: code
    added = .false.
    node => null()
    call cpp_b_ht_ready(t)
    k => cpp_b_ht_key(t, e)
    code = cpp_b_ht_hash(t, k)
    if (associated(cpp_exc)) return
    node => cpp_b_ht_find(t, k, code)
    if (associated(cpp_exc)) return
    if (associated(node)) return
    node => cpp_b_ht_insert_node(t, e, code)
    added = .true.
  end function

  recursive subroutine cpp_b_ht_rehash_to(t, n)
    class(cpp_hashtable), intent(inout) :: t
    integer(8), value :: n
    type(cpp_b_nodep), allocatable :: nb(:)
    type(cpp_b_hnode), pointer :: p, nxt
    integer(8) :: b, bbegin
    allocate(nb(0:n - 1_8))
    p => t%bb%next
    t%bb%next => null()
    bbegin = 0_8
    do while (associated(p))
      nxt => p%next
      b = cpp_b_umod(p%code, n)
      if (.not. associated(nb(b)%p)) then
        p%next => t%bb%next
        t%bb%next => p
        nb(b)%p => t%bb
        if (associated(p%next)) nb(bbegin)%p => p
        bbegin = b
      else
        p%next => nb(b)%p%next
        nb(b)%p%next => p
      end if
      p => nxt
    end do
    call move_alloc(nb, t%bk)
    t%nbk = n
  end subroutine

  recursive subroutine cpp_b_ht_erase_node(t, b, prev, n)
    class(cpp_hashtable), intent(inout) :: t
    integer(8), value :: b
    type(cpp_b_hnode), pointer, intent(in) :: prev, n
    type(cpp_b_hnode), pointer :: nxt
    integer(8) :: nextbkt
    logical :: other
    if (associated(prev, t%bk(b)%p)) then
      ! removing the bucket's first node (_M_remove_bucket_begin)
      nxt => n%next
      nextbkt = 0_8
      other = .true.
      if (associated(nxt)) then
        nextbkt = cpp_b_ht_bkt(t, nxt%code)
        other = nextbkt /= b
      end if
      if (other) then
        if (associated(nxt)) t%bk(nextbkt)%p => t%bk(b)%p
        if (associated(t%bk(b)%p, t%bb)) t%bb%next => nxt
        t%bk(b)%p => null()
      end if
    else if (associated(n%next)) then
      nextbkt = cpp_b_ht_bkt(t, n%next%code)
      if (nextbkt /= b) t%bk(nextbkt)%p => prev
    end if
    prev%next => n%next
    t%nelem = t%nelem - 1_8
  end subroutine

  recursive function cpp_b_ht_erase_key(t, k) result(r)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: k
    logical :: r
    type(cpp_b_hnode), pointer :: prev, p
    class(*), pointer :: pk
    integer(8) :: code, b
    logical :: e
    r = .false.
    call cpp_b_ht_ready(t)
    code = cpp_b_ht_hash(t, k)
    if (associated(cpp_exc)) return
    b = cpp_b_ht_bkt(t, code)
    prev => t%bk(b)%p
    if (.not. associated(prev)) return
    p => prev%next
    do while (associated(p))
      if (p%code == code) then
        pk => cpp_b_ht_key(t, p%val)
        e = cpp_b_ht_eq(t, k, pk)
        if (associated(cpp_exc)) return
        if (e) exit
      end if
      if (.not. associated(p%next)) return
      if (cpp_b_ht_bkt(t, p%next%code) /= b) return
      prev => p
      p => p%next
    end do
    if (.not. associated(p)) return
    call cpp_b_ht_erase_node(t, b, prev, p)
    r = .true.
  end function

  recursive subroutine cpp_b_ht_erase_at(t, n)
    class(cpp_hashtable), intent(inout) :: t
    type(cpp_b_hnode), pointer, intent(in) :: n
    type(cpp_b_hnode), pointer :: prev
    integer(8) :: b
    b = cpp_b_ht_bkt(t, n%code)
    prev => t%bk(b)%p
    do while (.not. associated(prev%next, n))
      prev => prev%next
    end do
    call cpp_b_ht_erase_node(t, b, prev, n)
  end subroutine

  ! a map's Pair copied as Pair.Clone copies it (Elem<K>.Copy, Elem<V>.Copy), with the table's makers and modes
  recursive function cpp_b_pair_copy(t, e) result(q)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: e
    class(*), pointer :: q
    class(*), pointer :: k, v
    class(cpp_pair), pointer :: np
    q => null()
    if (.not. associated(e)) return
    select type (pe => e)
    class is (cpp_pair)
      k => cpp_b_copy(pe%first%p, t%cmk)
      if (associated(cpp_exc)) return
      v => cpp_b_copy(pe%second%p, t%cmv)
      if (associated(cpp_exc)) return
      np => cpp_pair_new_a_b(k, v, t%mkk%f, t%cmk, t%mkv%f, t%cmv)
      q => np
    end select
  end function

  ! the element copy of Clone / Assign: Pair.Clone for a map, Elem<T>.Copy for a set
  recursive function cpp_b_ht_elem_copy(t, e) result(q)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer, intent(in) :: e
    class(*), pointer :: q
    if (t%isset) then
      q => cpp_b_copy(e, t%cmk)
    else
      q => cpp_b_pair_copy(t, e)
    end if
  end function

  ! CopyFrom (_M_assign): the same bucket count and node order, each element copied
  recursive subroutine cpp_b_ht_copy_from(t, o)
    class(cpp_hashtable), intent(inout) :: t
    class(cpp_hashtable), intent(inout) :: o
    type(cpp_b_hnode), pointer :: prev, p, n
    integer(8) :: b
    call cpp_b_ht_ready(t)
    call cpp_b_ht_ready(o)
    deallocate(t%bk)
    allocate(t%bk(0:o%nbk - 1_8))
    t%nbk = o%nbk
    t%bb%next => null()
    t%nelem = 0_8
    t%nextresize = o%nextresize
    prev => t%bb
    p => o%bb%next
    do while (associated(p))
      allocate(n)
      n%val => cpp_b_ht_elem_copy(o, p%val)
      if (associated(cpp_exc)) return
      n%code = p%code
      prev%next => n
      b = cpp_b_ht_bkt(t, n%code)
      if (.not. associated(t%bk(b)%p)) t%bk(b)%p => prev
      prev => n
      t%nelem = t%nelem + 1_8
      p => p%next
    end do
  end subroutine

  ! Clone: a new table of the same dynamic type with the same hasher, key-equal, makers and modes
  recursive function cpp_b_ht_clone(t) result(m)
    class(cpp_hashtable), intent(inout), target :: t
    class(cpp_hashtable), pointer :: m
    call cpp_b_ht_ready(t)
    allocate(m, mold=t)
    m%mkk = t%mkk
    m%mkv = t%mkv
    m%cmk = t%cmk
    m%cmv = t%cmv
    m%hasmk = .true.
    call cpp_b_ht_ready(m)
    m%isset = t%isset
    m%hfn => t%hfn
    m%eqfn => t%eqfn
    m%hobj => t%hobj
    m%eobj => t%eobj
    m%vmk => t%vmk
    m%maxload = t%maxload
    call cpp_b_ht_copy_from(m, t)
  end function

  recursive function cpp_b_ht_clone_(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_hashtable), pointer :: m
    m => cpp_b_ht_clone(self)
    zres => m
  end function

  recursive subroutine cpp_b_ht_assign_(self, other)
    class(cpp_hashtable), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    if (.not. associated(other)) return
    if (associated(other, self)) return
    select type (o => other)
    class is (cpp_hashtable)
      call cpp_b_ht_copy_from(self, o)
    end select
  end subroutine

  ! the mapped value operator[] inserts (UMap.MakeV: the Func<V> if one was given, else Elem<V>.Make)
  recursive function cpp_b_ht_makev(t) result(v)
    class(cpp_hashtable), intent(inout) :: t
    class(*), pointer :: v
    if (associated(t%vmk)) then
      v => t%vmk%invoke()
    else
      v => t%mkv%f()
    end if
  end function

  ! ------------------------------------------------------------------------------------------------ HashTable<K, E>
  recursive function cpp_hashtable_begin(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    type(cpp_mit) :: zres
    zres = cpp_mit()
    call cpp_b_ht_ready(self)
    zres%node => self%bb%next
  end function

  recursive subroutine cpp_hashtable_clear(self)
    class(cpp_hashtable), intent(inout), target :: self
    integer(8) :: n
    call cpp_b_ht_ready(self)
    n = self%nbk
    deallocate(self%bk)
    allocate(self%bk(0:n - 1_8))
    self%bb%next => null()
    self%nelem = 0_8
  end subroutine

  recursive function cpp_hashtable_contains(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    logical :: zres
    zres = associated(cpp_b_ht_findk(self, a1))
  end function

  recursive function cpp_hashtable_count(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    integer(8) :: zres
    zres = 0_8
    if (associated(cpp_b_ht_findk(self, a1))) zres = 1_8
  end function

  recursive function cpp_hashtable_end(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    type(cpp_mit) :: zres
    zres = cpp_mit()
  end function

  recursive function cpp_hashtable_erase_mite(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    type(cpp_mit), intent(in) :: a1
    type(cpp_mit) :: zres
    type(cpp_b_hnode), pointer :: n
    zres = cpp_mit()
    n => a1%node
    zres%node => n%next
    call cpp_b_ht_erase_at(self, n)
  end function

  recursive function cpp_hashtable_find(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_mit) :: zres
    zres = cpp_mit()
    zres%node => cpp_b_ht_findk(self, a1)
  end function

  recursive subroutine cpp_hashtable_reserve(self, a1)
    class(cpp_hashtable), intent(inout), target :: self
    integer(8), value :: a1
    call cpp_hashtable_rehash(self, cpp_b_bkt_for_elements(self, a1))
  end subroutine

  recursive function cpp_hashtable_size(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    integer(8) :: zres
    zres = self%nelem
  end function

  ! extras
  recursive function cpp_hashtable_erase_k(self, a1) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    integer(8) :: zres
    zres = 0_8
    if (cpp_b_ht_erase_key(self, a1)) zres = 1_8
  end function

  recursive function cpp_hashtable_bucket_count(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    integer(8) :: zres
    call cpp_b_ht_ready(self)
    zres = self%nbk
  end function

  ! rehash(n): _M_next_bkt(max(n, bkt_for_elements(size + 1))), only if it differs
  recursive subroutine cpp_hashtable_rehash(self, a1)
    class(cpp_hashtable), intent(inout), target :: self
    integer(8), value :: a1
    integer(8) :: want
    call cpp_b_ht_ready(self)
    want = cpp_b_next_bkt(self, cpp_b_umax(a1, cpp_b_bkt_for_elements(self, self%nelem + 1_8)))
    if (want /= self%nbk) call cpp_b_ht_rehash_to(self, want)
  end subroutine

  recursive function cpp_hashtable_empty(self) result(zres)
    class(cpp_hashtable), intent(inout), target :: self
    logical :: zres
    zres = self%nelem == 0_8
  end function

  ! ------------------------------------------------------------------------------------------------ UMap<K, V>
  recursive function cpp_umap_new_funckul_funckkb_funcv(a1, a2, a3, mk4, cm5, mk6, cm7) result(zres)
    class(cpp_func_o_l), pointer, intent(in) :: a1
    class(cpp_func_o_o_z), pointer, intent(in) :: a2
    class(cpp_func_o), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    procedure(cpp_maker) :: mk6
    integer(4), value :: cm7
    class(cpp_umap), pointer :: zres
    allocate(cpp_umap :: zres)
    call cpp_b_ht_init(zres, .false., a1, a2, mk4, cm5, mk6, cm7)
    zres%vmk => a3
  end function

  ! UMap(Pair<K, V>[] il, h, eq): each pair inserted as a copy (Insert(p.Clone()))
  recursive function cpp_umap_new_pairkva_funckul_funckkb(a1, a2, a3, mk4, cm5, mk6, cm7) result(zres)
    class(cpp_arr_o), pointer, intent(in) :: a1
    class(cpp_func_o_l), pointer, intent(in) :: a2
    class(cpp_func_o_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    procedure(cpp_maker) :: mk6
    integer(4), value :: cm7
    class(cpp_umap), pointer :: zres
    class(cpp_func_o), pointer :: nofn
    type(cpp_b_hnode), pointer :: node
    class(*), pointer :: q
    integer(8) :: i
    logical :: added
    nofn => null()
    zres => cpp_umap_new_funckul_funckkb_funcv(a2, a3, nofn, mk4, cm5, mk6, cm7)
    if (.not. associated(a1)) return
    do i = lbound(a1%a, 1, 8), ubound(a1%a, 1, 8)
      q => cpp_b_pair_copy(zres, a1%a(i)%p)
      if (associated(cpp_exc)) return
      node => cpp_b_ht_insert(zres, q, added)
      if (associated(cpp_exc)) return
    end do
  end function

  recursive subroutine cpp_umap_assign(self, a1)
    class(cpp_umap), intent(inout), target :: self
    class(cpp_umap), pointer, intent(in) :: a1
    if (associated(a1, self)) return
    call cpp_b_ht_copy_from(self, a1)
  end subroutine

  recursive function cpp_umap_clone(self) result(zres)
    class(cpp_umap), intent(inout), target :: self
    class(cpp_umap), pointer :: zres
    class(cpp_hashtable), pointer :: m
    zres => null()
    m => cpp_b_ht_clone(self)
    select type (m)
    class is (cpp_umap)
      zres => m
    end select
  end function

  ! emplace(k, v): insert(new Pair(KeyCopy(k), v)) if k is absent
  recursive function cpp_umap_emplace_k_v(self, a1, a2) result(zres)
    class(cpp_umap), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(*), pointer, intent(in) :: a2
    class(cpp_pair), pointer :: zres
    type(cpp_b_hnode), pointer :: f
    type(cpp_mit) :: it
    class(*), pointer :: kc, e
    class(cpp_pair), pointer :: np
    integer(8) :: code
    zres => null()
    call cpp_b_ht_ready(self)
    code = cpp_b_ht_hash(self, a1)
    if (associated(cpp_exc)) return
    f => cpp_b_ht_find(self, a1, code)
    if (associated(cpp_exc)) return
    it = cpp_mit()
    if (associated(f)) then
      it%node => f
      zres => cpp_b_insres(it, .false.)
      return
    end if
    kc => cpp_b_keycopy(a1)
    if (associated(cpp_exc)) return
    np => cpp_pair_new_a_b(kc, a2, self%mkk%f, self%cmk, self%mkv%f, self%cmv)
    e => np
    it%node => cpp_b_ht_insert_node(self, e, code)
    zres => cpp_b_insres(it, .true.)
  end function

  ! operator[]: the mapped value, inserted (made by MakeV) if k is absent
  recursive function cpp_umap_index(self, a1) result(zres)
    class(cpp_umap), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_slot), pointer :: zres
    type(cpp_b_hnode), pointer :: f
    class(*), pointer :: kc, v, e
    class(cpp_pair), pointer :: np
    integer(8) :: code
    zres => null()
    call cpp_b_ht_ready(self)
    code = cpp_b_ht_hash(self, a1)
    if (associated(cpp_exc)) return
    f => cpp_b_ht_find(self, a1, code)
    if (associated(cpp_exc)) return
    if (.not. associated(f)) then
      kc => cpp_b_keycopy(a1)
      if (associated(cpp_exc)) return
      v => cpp_b_ht_makev(self)
      if (associated(cpp_exc)) return
      np => cpp_pair_new_a_b(kc, v, self%mkk%f, self%cmk, self%mkv%f, self%cmv)
      e => np
      f => cpp_b_ht_insert_node(self, e, code)
    end if
    select type (pv => f%val)
    class is (cpp_pair)
      zres => pv%second
    end select
  end function

  ! ------------------------------------------------------------------------------------------------ UMapC<K, V, H, E>
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
    class(cpp_func_o_l), pointer :: noh
    class(cpp_func_o_o_z), pointer :: noe
    class(*), pointer :: h, e
    noh => null()
    noe => null()
    allocate(cpp_umapc :: zres)
    call cpp_b_ht_init(zres, .false., noh, noe, mk2, cm3, mk4, cm5)
    zres%vmk => a1
    h => mk6()
    if (associated(cpp_exc)) return
    e => mk8()
    if (associated(cpp_exc)) return
    if (associated(h)) then
      select type (hh => h)
      class is (cpp_object)
        zres%hobj => hh
      end select
    end if
    if (associated(e)) then
      select type (ee => e)
      class is (cpp_object)
        zres%eobj => ee
      end select
    end if
  end function

  recursive subroutine cpp_umapc_assign(self, a1)
    class(cpp_umapc), intent(inout), target :: self
    class(cpp_umapc), pointer, intent(in) :: a1
    if (associated(a1, self)) return
    call cpp_b_ht_copy_from(self, a1)
  end subroutine

  recursive function cpp_umapc_clone(self) result(zres)
    class(cpp_umapc), intent(inout), target :: self
    class(cpp_umapc), pointer :: zres
    class(cpp_hashtable), pointer :: m
    zres => null()
    m => cpp_b_ht_clone(self)
    select type (m)
    class is (cpp_umapc)
      zres => m
    end select
  end function

  ! ------------------------------------------------------------------------------------------------ USet<T>
  recursive function cpp_uset_new_functul_functtb(a1, a2, mk3, cm4) result(zres)
    class(cpp_func_o_l), pointer, intent(in) :: a1
    class(cpp_func_o_o_z), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_uset), pointer :: zres
    allocate(cpp_uset :: zres)
    call cpp_b_ht_init(zres, .true., a1, a2, mk3, cm4, cpp_b_mk_null, 0)
  end function

  ! insert(x): Insert(KeyCopy(x))
  recursive function cpp_uset_insert(self, a1) result(zres)
    class(cpp_uset), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(cpp_pair), pointer :: zres
    type(cpp_b_hnode), pointer :: f
    type(cpp_mit) :: it
    class(*), pointer :: kc
    integer(8) :: code
    zres => null()
    call cpp_b_ht_ready(self)
    code = cpp_b_ht_hash(self, a1)
    if (associated(cpp_exc)) return
    f => cpp_b_ht_find(self, a1, code)
    if (associated(cpp_exc)) return
    it = cpp_mit()
    if (associated(f)) then
      it%node => f
      zres => cpp_b_insres(it, .false.)
      return
    end if
    kc => cpp_b_keycopy(a1)
    if (associated(cpp_exc)) return
    it%node => cpp_b_ht_insert_node(self, kc, code)
    zres => cpp_b_insres(it, .true.)
  end function

  recursive function cpp_uset_clone(self) result(zres)
    class(cpp_uset), intent(inout), target :: self
    class(cpp_uset), pointer :: zres
    class(cpp_hashtable), pointer :: m
    zres => null()
    m => cpp_b_ht_clone(self)
    select type (m)
    class is (cpp_uset)
      zres => m
    end select
  end function

  recursive subroutine cpp_uset_assign(self, a1)
    class(cpp_uset), intent(inout), target :: self
    class(cpp_uset), pointer, intent(in) :: a1
    if (associated(a1, self)) return
    call cpp_b_ht_copy_from(self, a1)
  end subroutine

  ! ------------------------------------------------------------------------------------------------ MIt<E>
  recursive function cpp_mit_clone(self) result(zres)
    type(cpp_mit), intent(in) :: self
    type(cpp_mit) :: zres
    zres = self
  end function

  recursive function cpp_mit_deref(self) result(zres)
    type(cpp_mit), intent(in) :: self
    class(*), pointer :: zres
    if (associated(self%lst)) then
      zres => self%lst%a(self%pos)%p
    else
      zres => self%node%val
    end if
  end function

  recursive function cpp_mit_op_eq(a1, a2) result(zres)
    type(cpp_mit), intent(in) :: a1
    type(cpp_mit), intent(in) :: a2
    logical :: zres
    integer(4) :: p1, p2
    if (associated(a1%lst) .or. associated(a2%lst)) then
      p1 = huge(0)
      p2 = huge(0)
      if (associated(a1%lst)) p1 = a1%pos
      if (associated(a2%lst)) p2 = a2%pos
      zres = p1 == p2
    else if (.not. associated(a1%node)) then
      zres = .not. associated(a2%node)
    else
      zres = associated(a1%node, a2%node)
    end if
  end function

  recursive function cpp_mit_op_inc(a1) result(zres)
    type(cpp_mit), intent(in) :: a1
    type(cpp_mit) :: zres
    zres = a1
    if (associated(a1%lst)) then
      zres%pos = a1%pos + 1
    else
      zres%node => a1%node%next
    end if
  end function

  ! ================================================================================================ Map<K, V>
  recursive function cpp_b_map_lt(m, a, b) result(r)
    class(cpp_map), intent(inout) :: m
    class(*), pointer, intent(in) :: a, b
    logical :: r
    if (associated(m%lt)) then
      r = m%lt%invoke(a, b)
    else
      r = cpp_b_less(a, b)
    end if
  end function

  recursive subroutine cpp_b_map_ready(m)
    class(cpp_map), intent(inout) :: m
    if (associated(m%items)) return
    allocate(m%items)
    call cpp_b_list_init(m%items)
    m%mkk%f => cpp_b_mk_null
    m%mkv%f => cpp_b_mk_null
  end subroutine

  ! the first position whose key is not less than k
  recursive function cpp_b_map_lower(m, k) result(lo)
    class(cpp_map), intent(inout) :: m
    class(*), pointer, intent(in) :: k
    integer(4) :: lo, hi, mid
    class(*), pointer :: f
    logical :: l
    call cpp_b_map_ready(m)
    lo = 0
    hi = m%items%n
    do while (lo < hi)
      mid = (lo + hi) / 2
      f => cpp_b_first(m%items%a(mid)%p)
      l = cpp_b_map_lt(m, f, k)
      if (associated(cpp_exc)) return
      if (l) then
        lo = mid + 1
      else
        hi = mid
      end if
    end do
  end function

  ! the position of k, or -1
  recursive function cpp_b_map_find(m, k) result(i)
    class(cpp_map), intent(inout) :: m
    class(*), pointer, intent(in) :: k
    integer(4) :: i
    class(*), pointer :: f
    logical :: l
    i = cpp_b_map_lower(m, k)
    if (associated(cpp_exc)) return
    if (i < m%items%n) then
      f => cpp_b_first(m%items%a(i)%p)
      l = cpp_b_map_lt(m, k, f)
      if (associated(cpp_exc)) return
      if (.not. l) return
    end if
    i = -1
  end function

  recursive function cpp_b_map_it(m, i) result(it)
    class(cpp_map), intent(inout) :: m
    integer(4), intent(in) :: i
    type(cpp_mit) :: it
    it = cpp_mit()
    it%lst => m%items
    it%pos = i
  end function

  recursive function cpp_map_new_funckkb_funcv(a1, a2, mk3, cm4, mk5, cm6) result(zres)
    class(cpp_func_o_o_z), pointer, intent(in) :: a1
    class(cpp_func_o), pointer, intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
    class(cpp_map), pointer :: zres
    allocate(cpp_map :: zres)
    allocate(zres%items)
    call cpp_b_list_init(zres%items)
    zres%lt => a1
    zres%vmk => a2
    zres%mkk%f => mk3
    zres%cmk = cm4
    zres%mkv%f => mk5
    zres%cmv = cm6
  end function

  ! a Pair of the map copied as Pair.Clone copies it
  recursive function cpp_b_map_pair_copy(m, e) result(q)
    class(cpp_map), intent(inout) :: m
    class(*), pointer, intent(in) :: e
    class(*), pointer :: q
    class(*), pointer :: k, v
    class(cpp_pair), pointer :: np
    q => null()
    if (.not. associated(e)) return
    select type (pe => e)
    class is (cpp_pair)
      k => cpp_b_copy(pe%first%p, m%cmk)
      if (associated(cpp_exc)) return
      v => cpp_b_copy(pe%second%p, m%cmv)
      if (associated(cpp_exc)) return
      np => cpp_pair_new_a_b(k, v, m%mkk%f, m%cmk, m%mkv%f, m%cmv)
      q => np
    end select
  end function

  ! Assign: a new list of copies
  recursive subroutine cpp_map_assign(self, a1)
    class(cpp_map), intent(inout), target :: self
    class(cpp_map), pointer, intent(in) :: a1
    type(cpp_b_list), pointer :: l
    class(*), pointer :: q
    integer(4) :: i
    if (associated(a1, self)) return
    call cpp_b_map_ready(a1)
    allocate(l)
    call cpp_b_list_init(l)
    do i = 0, a1%items%n - 1
      q => cpp_b_map_pair_copy(a1, a1%items%a(i)%p)
      if (associated(cpp_exc)) return
      call cpp_b_list_add(l, q)
    end do
    self%items => l
  end subroutine

  recursive function cpp_map_begin(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    type(cpp_mit) :: zres
    call cpp_b_map_ready(self)
    zres = cpp_b_map_it(self, 0)
  end function

  recursive function cpp_map_clone(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(cpp_map), pointer :: zres
    class(*), pointer :: q
    integer(4) :: i
    call cpp_b_map_ready(self)
    allocate(cpp_map :: zres)
    allocate(zres%items)
    call cpp_b_list_init(zres%items)
    zres%lt => self%lt
    zres%vmk => self%vmk
    zres%mkk = self%mkk
    zres%cmk = self%cmk
    zres%mkv = self%mkv
    zres%cmv = self%cmv
    do i = 0, self%items%n - 1
      q => cpp_b_map_pair_copy(self, self%items%a(i)%p)
      if (associated(cpp_exc)) return
      call cpp_b_list_add(zres%items, q)
    end do
  end function

  recursive function cpp_b_map_clone_(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_map), pointer :: m
    m => cpp_map_clone(self)
    zres => m
  end function

  recursive subroutine cpp_b_map_assign_(self, other)
    class(cpp_map), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_map), pointer :: o
    if (.not. associated(other)) return
    select type (other)
    class is (cpp_map)
      o => other
      call cpp_map_assign(self, o)
    end select
  end subroutine

  ! emplace(k, v): insert(new Pair(k, v)), the key copied if inserted
  recursive function cpp_map_emplace_k_v(self, a1, a2) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(*), pointer, intent(in) :: a2
    class(cpp_pair), pointer :: zres
    class(*), pointer :: f, kc, e
    class(cpp_pair), pointer :: np
    integer(4) :: i
    logical :: l
    zres => null()
    i = cpp_b_map_lower(self, a1)
    if (associated(cpp_exc)) return
    if (i < self%items%n) then
      f => cpp_b_first(self%items%a(i)%p)
      l = cpp_b_map_lt(self, a1, f)
      if (associated(cpp_exc)) return
      if (.not. l) then
        zres => cpp_b_insres(cpp_b_map_it(self, i), .false.)
        return
      end if
    end if
    kc => cpp_b_keycopy(a1)
    if (associated(cpp_exc)) return
    np => cpp_pair_new_a_b(kc, a2, self%mkk%f, self%cmk, self%mkv%f, self%cmv)
    e => np
    call cpp_b_list_insert(self%items, i, e)
    zres => cpp_b_insres(cpp_b_map_it(self, i), .true.)
  end function

  recursive function cpp_map_empty(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    logical :: zres
    call cpp_b_map_ready(self)
    zres = self%items%n == 0
  end function

  recursive function cpp_map_end(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    type(cpp_mit) :: zres
    call cpp_b_map_ready(self)
    zres = cpp_b_map_it(self, self%items%n)
  end function

  recursive function cpp_map_find(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_mit) :: zres
    integer(4) :: i
    zres = cpp_mit()
    i = cpp_b_map_find(self, a1)
    if (associated(cpp_exc)) return
    if (i < 0) i = self%items%n
    zres = cpp_b_map_it(self, i)
  end function

  ! operator[]: the mapped value, inserted (the Func<V> if given, else Elem<V>.Make) if k is absent
  recursive function cpp_map_index(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_slot), pointer :: zres
    class(*), pointer :: f, kc, v, e
    class(cpp_pair), pointer :: np
    integer(4) :: i
    logical :: ins
    zres => null()
    i = cpp_b_map_lower(self, a1)
    if (associated(cpp_exc)) return
    ins = i == self%items%n
    if (.not. ins) then
      f => cpp_b_first(self%items%a(i)%p)
      ins = cpp_b_map_lt(self, a1, f)
      if (associated(cpp_exc)) return
    end if
    if (ins) then
      kc => cpp_b_keycopy(a1)
      if (associated(cpp_exc)) return
      if (associated(self%vmk)) then
        v => self%vmk%invoke()
      else
        v => self%mkv%f()
      end if
      if (associated(cpp_exc)) return
      np => cpp_pair_new_a_b(kc, v, self%mkk%f, self%cmk, self%mkv%f, self%cmv)
      e => np
      call cpp_b_list_insert(self%items, i, e)
    end if
    select type (pv => self%items%a(i)%p)
    class is (cpp_pair)
      zres => pv%second
    end select
  end function

  recursive function cpp_map_size(self) result(zres)
    class(cpp_map), intent(inout), target :: self
    integer(8) :: zres
    call cpp_b_map_ready(self)
    zres = int(self%items%n, 8)
  end function

  ! extras
  recursive function cpp_map_erase_k(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    integer(8) :: zres
    integer(4) :: i
    zres = 0_8
    i = cpp_b_map_find(self, a1)
    if (associated(cpp_exc)) return
    if (i < 0) return
    call cpp_b_list_remove(self%items, i)
    zres = 1_8
  end function

  recursive function cpp_map_lower_bound(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_mit) :: zres
    zres = cpp_b_map_it(self, cpp_b_map_lower(self, a1))
  end function

  recursive function cpp_map_upper_bound(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_mit) :: zres
    class(*), pointer :: f
    integer(4) :: i
    logical :: l
    zres = cpp_mit()
    i = cpp_b_map_lower(self, a1)
    if (associated(cpp_exc)) return
    do while (i < self%items%n)
      f => cpp_b_first(self%items%a(i)%p)
      l = cpp_b_map_lt(self, a1, f)
      if (associated(cpp_exc)) return
      if (l) exit
      i = i + 1
    end do
    zres = cpp_b_map_it(self, i)
  end function

  recursive function cpp_map_count(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    integer(8) :: zres
    zres = 0_8
    if (cpp_b_map_find(self, a1) >= 0) zres = 1_8
  end function

  recursive function cpp_map_contains(self, a1) result(zres)
    class(cpp_map), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    logical :: zres
    zres = cpp_b_map_find(self, a1) >= 0
  end function

  recursive subroutine cpp_map_clear(self)
    class(cpp_map), intent(inout), target :: self
    integer(4) :: i
    call cpp_b_map_ready(self)
    do i = 0, self%items%n - 1
      self%items%a(i)%p => null()
    end do
    self%items%n = 0
  end subroutine

  ! ================================================================================================ Set<T>
  recursive function cpp_b_set_lt(s, a, b) result(r)
    class(cpp_set), intent(inout) :: s
    class(*), pointer, intent(in) :: a, b
    logical :: r
    if (associated(s%lt)) then
      r = s%lt%invoke(a, b)
    else
      r = cpp_b_less(a, b)
    end if
  end function

  recursive subroutine cpp_b_set_ready(s)
    class(cpp_set), intent(inout) :: s
    if (associated(s%items)) return
    allocate(s%items)
    call cpp_b_list_init(s%items)
    s%mk%f => cpp_b_mk_null
  end subroutine

  recursive function cpp_b_set_lower(s, k) result(lo)
    class(cpp_set), intent(inout) :: s
    class(*), pointer, intent(in) :: k
    integer(4) :: lo, hi, mid
    logical :: l
    call cpp_b_set_ready(s)
    lo = 0
    hi = s%items%n
    do while (lo < hi)
      mid = (lo + hi) / 2
      l = cpp_b_set_lt(s, s%items%a(mid)%p, k)
      if (associated(cpp_exc)) return
      if (l) then
        lo = mid + 1
      else
        hi = mid
      end if
    end do
  end function

  ! the position of k, or -1
  recursive function cpp_b_set_find(s, k) result(i)
    class(cpp_set), intent(inout) :: s
    class(*), pointer, intent(in) :: k
    integer(4) :: i
    logical :: l
    i = cpp_b_set_lower(s, k)
    if (associated(cpp_exc)) return
    if (i < s%items%n) then
      l = cpp_b_set_lt(s, k, s%items%a(i)%p)
      if (associated(cpp_exc)) return
      if (.not. l) return
    end if
    i = -1
  end function

  recursive function cpp_b_set_it(s, i) result(it)
    class(cpp_set), intent(inout) :: s
    integer(4), intent(in) :: i
    type(cpp_mit) :: it
    it = cpp_mit()
    it%lst => s%items
    it%pos = i
  end function

  recursive function cpp_set_new_functtb(a1, mk2, cm3) result(zres)
    class(cpp_func_o_o_z), pointer, intent(in) :: a1
    procedure(cpp_maker) :: mk2
    integer(4), value :: cm3
    class(cpp_set), pointer :: zres
    allocate(cpp_set :: zres)
    allocate(zres%items)
    call cpp_b_list_init(zres%items)
    zres%lt => a1
    zres%mk%f => mk2
    zres%cm = cm3
  end function

  recursive subroutine cpp_set_assign(self, a1)
    class(cpp_set), intent(inout), target :: self
    class(cpp_set), pointer, intent(in) :: a1
    type(cpp_b_list), pointer :: l
    class(*), pointer :: q
    integer(4) :: i
    if (associated(a1, self)) return
    call cpp_b_set_ready(a1)
    allocate(l)
    call cpp_b_list_init(l)
    do i = 0, a1%items%n - 1
      q => cpp_b_copy(a1%items%a(i)%p, a1%cm)
      if (associated(cpp_exc)) return
      call cpp_b_list_add(l, q)
    end do
    self%items => l
  end subroutine

  recursive function cpp_set_clone(self) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(cpp_set), pointer :: zres
    class(*), pointer :: q
    integer(4) :: i
    call cpp_b_set_ready(self)
    allocate(cpp_set :: zres)
    allocate(zres%items)
    call cpp_b_list_init(zres%items)
    zres%lt => self%lt
    zres%mk = self%mk
    zres%cm = self%cm
    do i = 0, self%items%n - 1
      q => cpp_b_copy(self%items%a(i)%p, self%cm)
      if (associated(cpp_exc)) return
      call cpp_b_list_add(zres%items, q)
    end do
  end function

  recursive function cpp_b_set_clone_(self) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_set), pointer :: m
    m => cpp_set_clone(self)
    zres => m
  end function

  recursive subroutine cpp_b_set_assign_(self, other)
    class(cpp_set), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_set), pointer :: o
    if (.not. associated(other)) return
    select type (other)
    class is (cpp_set)
      o => other
      call cpp_set_assign(self, o)
    end select
  end subroutine

  ! insert(x): the position of x and whether it was added (a copy of x, KeyCopy)
  recursive function cpp_set_insert(self, a1) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    class(cpp_pair), pointer :: zres
    class(*), pointer :: kc
    integer(4) :: i
    logical :: l
    zres => null()
    i = cpp_b_set_lower(self, a1)
    if (associated(cpp_exc)) return
    if (i < self%items%n) then
      l = cpp_b_set_lt(self, a1, self%items%a(i)%p)
      if (associated(cpp_exc)) return
      if (.not. l) then
        zres => cpp_b_insres(cpp_b_set_it(self, i), .false.)
        return
      end if
    end if
    kc => cpp_b_keycopy(a1)
    if (associated(cpp_exc)) return
    call cpp_b_list_insert(self%items, i, kc)
    zres => cpp_b_insres(cpp_b_set_it(self, i), .true.)
  end function

  ! extras
  recursive function cpp_set_find(self, a1) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    type(cpp_mit) :: zres
    integer(4) :: i
    zres = cpp_mit()
    i = cpp_b_set_find(self, a1)
    if (associated(cpp_exc)) return
    if (i < 0) i = self%items%n
    zres = cpp_b_set_it(self, i)
  end function

  recursive function cpp_set_count(self, a1) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    integer(8) :: zres
    zres = 0_8
    if (cpp_b_set_find(self, a1) >= 0) zres = 1_8
  end function

  recursive function cpp_set_contains(self, a1) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    logical :: zres
    zres = cpp_b_set_find(self, a1) >= 0
  end function

  recursive function cpp_set_erase_t(self, a1) result(zres)
    class(cpp_set), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    integer(8) :: zres
    integer(4) :: i
    zres = 0_8
    i = cpp_b_set_find(self, a1)
    if (associated(cpp_exc)) return
    if (i < 0) return
    call cpp_b_list_remove(self%items, i)
    zres = 1_8
  end function

  recursive function cpp_set_size(self) result(zres)
    class(cpp_set), intent(inout), target :: self
    integer(8) :: zres
    call cpp_b_set_ready(self)
    zres = int(self%items%n, 8)
  end function

  recursive function cpp_set_empty(self) result(zres)
    class(cpp_set), intent(inout), target :: self
    logical :: zres
    call cpp_b_set_ready(self)
    zres = self%items%n == 0
  end function

  recursive function cpp_set_begin(self) result(zres)
    class(cpp_set), intent(inout), target :: self
    type(cpp_mit) :: zres
    call cpp_b_set_ready(self)
    zres = cpp_b_set_it(self, 0)
  end function

  recursive function cpp_set_end(self) result(zres)
    class(cpp_set), intent(inout), target :: self
    type(cpp_mit) :: zres
    call cpp_b_set_ready(self)
    zres = cpp_b_set_it(self, self%items%n)
  end function

  recursive subroutine cpp_set_clear(self)
    class(cpp_set), intent(inout), target :: self
    integer(4) :: i
    call cpp_b_set_ready(self)
    do i = 0, self%items%n - 1
      self%items%a(i)%p => null()
    end do
    self%items%n = 0
  end subroutine

  ! ================================================================================================ Stk<T>
  recursive function cpp_stk_new(mk1, cm2) result(zres)
    procedure(cpp_maker) :: mk1
    integer(4), value :: cm2
    class(cpp_stk), pointer :: zres
    allocate(cpp_stk :: zres)
    allocate(zres%a(0:3))
    zres%mk%f => mk1
    zres%cm = cm2
  end function

  recursive function cpp_stk_empty(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    logical :: zres
    zres = self%n == 0
  end function

  recursive subroutine cpp_stk_pop(self)
    class(cpp_stk), intent(inout), target :: self
    self%n = self%n - 1
    self%a(self%n)%p => null()
  end subroutine

  recursive subroutine cpp_stk_push(self, a1)
    class(cpp_stk), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    call cpp_b_slots_grow(self%a, self%n)
    self%a(self%n)%p => a1
    self%n = self%n + 1
  end subroutine

  recursive function cpp_stk_size(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    integer(8) :: zres
    zres = int(self%n, 8)
  end function

  recursive function cpp_stk_top(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    type(cpp_slot), pointer :: zres
    zres => self%a(self%n - 1)
  end function

  ! extras: Clone, Assign (each element Elem<T>.Copy)
  recursive function cpp_stk_clone(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    class(cpp_stk), pointer :: zres
    class(*), pointer :: q
    integer(4) :: i
    allocate(cpp_stk :: zres)
    allocate(zres%a(0:max(3, self%n - 1)))
    zres%mk = self%mk
    zres%cm = self%cm
    do i = 0, self%n - 1
      q => cpp_b_copy(self%a(i)%p, self%cm)
      if (associated(cpp_exc)) return
      zres%a(i)%p => q
      zres%n = i + 1
    end do
  end function

  recursive subroutine cpp_stk_assign(self, a1)
    class(cpp_stk), intent(inout), target :: self
    class(cpp_stk), pointer, intent(in) :: a1
    class(*), pointer :: q
    integer(4) :: i
    if (associated(a1, self)) return
    do i = 0, self%n - 1
      self%a(i)%p => null()
    end do
    self%n = 0
    do i = 0, a1%n - 1
      q => cpp_b_copy(a1%a(i)%p, a1%cm)
      if (associated(cpp_exc)) return
      call cpp_stk_push(self, q)
    end do
  end subroutine

  recursive function cpp_b_stk_clone_(self) result(zres)
    class(cpp_stk), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_stk), pointer :: m
    m => cpp_stk_clone(self)
    zres => m
  end function

  recursive subroutine cpp_b_stk_assign_(self, other)
    class(cpp_stk), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_stk), pointer :: o
    if (.not. associated(other)) return
    select type (other)
    class is (cpp_stk)
      o => other
      call cpp_stk_assign(self, o)
    end select
  end subroutine

  ! ================================================================================================ Que<T>
  recursive function cpp_que_new(mk1, cm2) result(zres)
    procedure(cpp_maker) :: mk1
    integer(4), value :: cm2
    class(cpp_que), pointer :: zres
    allocate(cpp_que :: zres)
    allocate(zres%a(0:3))
    zres%mk%f => mk1
    zres%cm = cm2
  end function

  recursive function cpp_que_clone(self) result(zres)
    class(cpp_que), intent(inout), target :: self
    class(cpp_que), pointer :: zres
    class(*), pointer :: q
    integer(4) :: i
    allocate(cpp_que :: zres)
    allocate(zres%a(0:3))
    zres%mk = self%mk
    zres%cm = self%cm
    do i = self%head, self%n - 1
      q => cpp_b_copy(self%a(i)%p, self%cm)
      if (associated(cpp_exc)) return
      call cpp_que_push(zres, q)
    end do
  end function

  recursive subroutine cpp_que_assign(self, a1)
    class(cpp_que), intent(inout), target :: self
    class(cpp_que), pointer, intent(in) :: a1
    class(*), pointer :: q
    integer(4) :: i
    if (associated(a1, self)) return
    do i = 0, self%n - 1
      self%a(i)%p => null()
    end do
    self%n = 0
    self%head = 0
    do i = a1%head, a1%n - 1
      q => cpp_b_copy(a1%a(i)%p, a1%cm)
      if (associated(cpp_exc)) return
      call cpp_que_push(self, q)
    end do
  end subroutine

  recursive function cpp_b_que_clone_(self) result(zres)
    class(cpp_que), intent(inout), target :: self
    class(cpp_object), pointer :: zres
    class(cpp_que), pointer :: m
    m => cpp_que_clone(self)
    zres => m
  end function

  recursive subroutine cpp_b_que_assign_(self, other)
    class(cpp_que), intent(inout), target :: self
    class(cpp_object), pointer, intent(in) :: other
    class(cpp_que), pointer :: o
    if (.not. associated(other)) return
    select type (other)
    class is (cpp_que)
      o => other
      call cpp_que_assign(self, o)
    end select
  end subroutine

  ! extras: push, pop, front, back, empty, size
  recursive subroutine cpp_que_push(self, a1)
    class(cpp_que), intent(inout), target :: self
    class(*), pointer, intent(in) :: a1
    call cpp_b_slots_grow(self%a, self%n)
    self%a(self%n)%p => a1
    self%n = self%n + 1
  end subroutine

  ! pop: the front leaves; the list drops its consumed head once that is more than 64 items and half of it
  recursive subroutine cpp_que_pop(self)
    class(cpp_que), intent(inout), target :: self
    integer(4) :: i, m
    self%a(self%head)%p => null()
    self%head = self%head + 1
    if (self%head > 64 .and. self%head * 2 > self%n) then
      m = self%n - self%head
      do i = 0, m - 1
        self%a(i) = self%a(self%head + i)
      end do
      do i = m, self%n - 1
        self%a(i)%p => null()
      end do
      self%n = m
      self%head = 0
    end if
  end subroutine

  recursive function cpp_que_front(self) result(zres)
    class(cpp_que), intent(inout), target :: self
    type(cpp_slot), pointer :: zres
    zres => self%a(self%head)
  end function

  recursive function cpp_que_back(self) result(zres)
    class(cpp_que), intent(inout), target :: self
    type(cpp_slot), pointer :: zres
    zres => self%a(self%n - 1)
  end function

  recursive function cpp_que_empty(self) result(zres)
    class(cpp_que), intent(inout), target :: self
    logical :: zres
    zres = self%n == self%head
  end function

  recursive function cpp_que_size(self) result(zres)
    class(cpp_que), intent(inout), target :: self
    integer(8) :: zres
    zres = int(self%n - self%head, 8)
  end function

  ! ================================================================================================ Algo
  ! <algorithm> and <numeric> over vector / array iterators (Iter: the array a and the index i); a result b + k is
  ! part A's Iter operator +. The over-Iter<byte> / <bool> / <float> and over-Ptr members are in cpp_rt_b_ext.
  recursive function cpp_algo_accumulate_iterd_iterd_d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
    real(8) :: zres
    integer(8) :: i
    zres = a3
    do i = a1%i, a2%i - 1_8
      zres = zres + a1%a%a(i)
    end do
  end function

  recursive function cpp_algo_all_of__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    class(cpp_func_d_z), pointer, intent(in) :: a3
    logical :: zres
    integer(8) :: i
    zres = .false.
    do i = a1%i, a2%i - 1_8
      if (.not. a3%invoke(a1%a%a(i))) return
      if (associated(cpp_exc)) return
    end do
    zres = .true.
  end function

  recursive function cpp_algo_all_of__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    logical :: zres
    integer(8) :: i
    class(*), pointer :: x
    zres = .false.
    do i = a1%i, a2%i - 1_8
      x => cpp_b_arg(a1%a%a(i)%p, cm5)
      if (.not. a3%invoke(x)) return
      if (associated(cpp_exc)) return
    end do
    zres = .true.
  end function

  recursive function cpp_algo_any_of__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    class(cpp_func_d_z), pointer, intent(in) :: a3
    logical :: zres
    integer(8) :: i
    zres = .true.
    do i = a1%i, a2%i - 1_8
      if (a3%invoke(a1%a%a(i))) return
      if (associated(cpp_exc)) return
    end do
    zres = .false.
  end function

  recursive function cpp_algo_any_of__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_func_i_z), pointer, intent(in) :: a3
    logical :: zres
    integer(8) :: i
    zres = .true.
    do i = a1%i, a2%i - 1_8
      if (a3%invoke(a1%a%a(i))) return
      if (associated(cpp_exc)) return
    end do
    zres = .false.
  end function

  recursive function cpp_algo_any_of__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    logical :: zres
    integer(8) :: i
    class(*), pointer :: x
    zres = .true.
    do i = a1%i, a2%i - 1_8
      x => cpp_b_arg(a1%a%a(i)%p, cm5)
      if (a3%invoke(x)) return
      if (associated(cpp_exc)) return
    end do
    zres = .false.
  end function

  recursive function cpp_algo_begin_ta__d(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    type(cpp_iter_d) :: zres
    zres = cpp_iter_d()
    zres%a => a1
    zres%i = 0_8
  end function

  recursive function cpp_algo_end_ta__d(a1) result(zres)
    class(cpp_arr_d), pointer, intent(in) :: a1
    type(cpp_iter_d) :: zres
    zres = cpp_iter_d()
    zres%a => a1
    zres%i = size(a1%a, kind=8)
  end function

  recursive function cpp_algo_copy_itert_itert_itert__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    type(cpp_iter_d), intent(in) :: a3
    type(cpp_iter_d) :: zres
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      a3%a%a(a3%i + (i - a1%i)) = a1%a%a(i)
    end do
    zres = cpp_iter_d_op_add(a3, a2%i - a1%i)
  end function

  recursive subroutine cpp_algo_fill_itert_itert_t__d(a1, a2, a3)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      a1%a%a(i) = a3
    end do
  end subroutine

  recursive subroutine cpp_algo_fill_itert_itert_t__i(a1, a2, a3)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    integer(4), value :: a3
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      a1%a%a(i) = a3
    end do
  end subroutine

  ! find: EqualityComparer<T>.Default (a Str by its bytes)
  recursive function cpp_algo_find__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(*), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_iter_o) :: zres
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      if (cpp_b_eq(a1%a%a(i)%p, a3)) then
        zres = cpp_iter_o_op_add(a1, i - a1%i)
        return
      end if
    end do
    zres = a2
  end function

  recursive function cpp_algo_find_if__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    type(cpp_iter_o) :: zres
    integer(8) :: i
    class(*), pointer :: x
    logical :: r
    zres = a2
    do i = a1%i, a2%i - 1_8
      x => cpp_b_arg(a1%a%a(i)%p, cm5)
      r = a3%invoke(x)
      if (associated(cpp_exc)) return
      if (r) then
        zres = cpp_iter_o_op_add(a1, i - a1%i)
        return
      end if
    end do
  end function

  recursive subroutine cpp_algo_iota_iterul_iterul_ul(a1, a2, a3)
    type(cpp_iter_l), intent(in) :: a1
    type(cpp_iter_l), intent(in) :: a2
    integer(8), value :: a3
    integer(8) :: i, v
    v = a3
    do i = a1%i, a2%i - 1_8
      a1%a%a(i) = v
      v = v + 1_8
    end do
  end subroutine

  ! is_sorted: no element is less than the one before it (Less<double>.Fn: the primitive <)
  recursive function cpp_algo_is_sorted_itert_itert__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    logical :: zres
    integer(8) :: i
    zres = .false.
    do i = a1%i + 1_8, a2%i - 1_8
      if (a1%a%a(i) < a1%a%a(i - 1_8)) return
    end do
    zres = .true.
  end function

  recursive function cpp_algo_lower_bound_itert_itert_t__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
    type(cpp_iter_d) :: zres
    integer(8) :: first, len, half, mid
    first = a1%i
    len = a2%i - a1%i
    do while (len > 0_8)
      half = ishft(len, -1)
      mid = first + half
      if (a1%a%a(mid) < a3) then
        first = mid + 1_8
        len = len - half - 1_8
      else
        len = half
      end if
    end do
    zres = cpp_iter_d_op_add(a1, first - a1%i)
  end function

  recursive function cpp_algo_lower_bound_itert_itert_t__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    integer(4), value :: a3
    type(cpp_iter_i) :: zres
    integer(8) :: first, len, half, mid
    first = a1%i
    len = a2%i - a1%i
    do while (len > 0_8)
      half = ishft(len, -1)
      mid = first + half
      if (a1%a%a(mid) < a3) then
        first = mid + 1_8
        len = len - half - 1_8
      else
        len = half
      end if
    end do
    zres = cpp_iter_i_op_add(a1, first - a1%i)
  end function

  ! lower_bound<T, V>(b, e, v, lt): lt(element, v)
  recursive function cpp_algo_lower_bound_itert_itert_v_functvb__od(a1, a2, a3, a4, mk5, cm6) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    real(8), value :: a3
    class(cpp_func_o_d_z), pointer, intent(in) :: a4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
    type(cpp_iter_o) :: zres
    integer(8) :: first, len, half, mid
    class(*), pointer :: x
    logical :: l
    zres = a1
    first = a1%i
    len = a2%i - a1%i
    do while (len > 0_8)
      half = ishft(len, -1)
      mid = first + half
      x => cpp_b_arg(a1%a%a(mid)%p, cm6)
      l = a4%invoke(x, a3)
      if (associated(cpp_exc)) return
      if (l) then
        first = mid + 1_8
        len = len - half - 1_8
      else
        len = half
      end if
    end do
    zres = cpp_iter_o_op_add(a1, first - a1%i)
  end function

  recursive function cpp_algo_max_element_itert_itert__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    type(cpp_iter_d) :: zres
    integer(8) :: i, best
    if (a1%i == a2%i) then
      zres = a2
      return
    end if
    best = a1%i
    do i = a1%i + 1_8, a2%i - 1_8
      if (a1%a%a(best) < a1%a%a(i)) best = i
    end do
    zres = cpp_iter_d_op_add(a1, best - a1%i)
  end function

  recursive function cpp_algo_min_element_itert_itert__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    type(cpp_iter_d) :: zres
    integer(8) :: i, best
    if (a1%i == a2%i) then
      zres = a2
      return
    end if
    best = a1%i
    do i = a1%i + 1_8, a2%i - 1_8
      if (a1%a%a(i) < a1%a%a(best)) best = i
    end do
    zres = cpp_iter_d_op_add(a1, best - a1%i)
  end function

  recursive function cpp_algo_none_of__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_func_i_z), pointer, intent(in) :: a3
    logical :: zres
    zres = .not. cpp_algo_any_of__i(a1, a2, a3)
  end function

  recursive function cpp_algo_none_of__o(a1, a2, a3, mk4, cm5) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    class(cpp_func_o_z), pointer, intent(in) :: a3
    procedure(cpp_maker) :: mk4
    integer(4), value :: cm5
    logical :: zres
    zres = .not. cpp_algo_any_of__o(a1, a2, a3, mk4, cm5)
  end function

  ! unique: keeps the first of each run of equal elements (libstdc++'s order of moves)
  recursive function cpp_algo_unique_itert_itert__i(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    type(cpp_iter_i) :: zres
    integer(8) :: first, last, nxt, dest
    if (a1%i == a2%i) then
      zres = a2
      return
    end if
    first = a1%i
    last = a2%i
    nxt = first
    do                                  ! adjacent_find
      nxt = nxt + 1_8
      if (nxt == last) exit
      if (a1%a%a(first) == a1%a%a(nxt)) exit
      first = nxt
    end do
    if (nxt == last) then
      zres = a2
      return
    end if
    dest = first
    first = nxt
    do
      first = first + 1_8
      if (first == last) exit
      if (a1%a%a(dest) /= a1%a%a(first)) then
        dest = dest + 1_8
        a1%a%a(dest) = a1%a%a(first)
      end if
    end do
    zres = cpp_iter_i_op_add(a1, dest + 1_8 - a1%i)
  end function

  recursive function cpp_algo_upper_bound_itert_itert_t__d(a1, a2, a3) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    real(8), value :: a3
    type(cpp_iter_d) :: zres
    integer(8) :: first, len, half, mid
    first = a1%i
    len = a2%i - a1%i
    do while (len > 0_8)
      half = ishft(len, -1)
      mid = first + half
      if (a3 < a1%a%a(mid)) then
        len = half
      else
        first = mid + 1_8
        len = len - half - 1_8
      end if
    end do
    zres = cpp_iter_d_op_add(a1, first - a1%i)
  end function

  ! VecFrom: a new Vec of copies of [b, e)
  recursive function cpp_algo_vecfrom__d(a1, a2) result(zres)
    type(cpp_iter_d), intent(in) :: a1
    type(cpp_iter_d), intent(in) :: a2
    class(cpp_vec_d), pointer :: zres
    class(cpp_arr_d), pointer :: arr
    integer(8) :: n, i
    n = a2%i - a1%i
    zres => cpp_vec_d_new_0()
    arr => cpp_arr_d_new(n)
    do i = 0_8, n - 1_8
      arr%a(i) = a1%a%a(a1%i + i)
    end do
    zres%a => arr
    zres%n = int(n, 4)
  end function

  recursive function cpp_algo_vecfrom__i(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_vec_i), pointer :: zres
    class(cpp_arr_i), pointer :: arr
    integer(8) :: n, i
    n = a2%i - a1%i
    zres => cpp_vec_i_new_0()
    arr => cpp_arr_i_new(n)
    do i = 0_8, n - 1_8
      arr%a(i) = a1%a%a(a1%i + i)
    end do
    zres%a => arr
    zres%n = int(n, 4)
  end function

  recursive function cpp_algo_vecfrom__o(a1, a2, mk3, cm4) result(zres)
    type(cpp_iter_o), intent(in) :: a1
    type(cpp_iter_o), intent(in) :: a2
    procedure(cpp_maker) :: mk3
    integer(4), value :: cm4
    class(cpp_vec_o), pointer :: zres
    class(cpp_arr_o), pointer :: arr
    integer(8) :: n, i
    n = a2%i - a1%i
    zres => cpp_vec_o_new_0(mk3, cm4)
    arr => cpp_arr_o_new(n)
    zres%a => arr
    zres%n = int(n, 4)
    do i = 0_8, n - 1_8
      arr%a(i)%p => cpp_b_copy(a1%a%a(a1%i + i)%p, cm4)
      if (associated(cpp_exc)) return
    end do
  end function

  ! ---- extras over int (members of the C# Algo the engine does not call; tests/stdcheck/f90 uses them)
  recursive function cpp_algo_count_if__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_func_i_z), pointer, intent(in) :: a3
    integer(8) :: zres
    integer(8) :: i
    zres = 0_8
    do i = a1%i, a2%i - 1_8
      if (a3%invoke(a1%a%a(i))) zres = zres + 1_8
      if (associated(cpp_exc)) return
    end do
  end function

  recursive function cpp_algo_adjacent_find_itert_itert__i(a1, a2) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    type(cpp_iter_i) :: zres
    integer(8) :: i
    do i = a1%i, a2%i - 2_8
      if (a1%a%a(i) == a1%a%a(i + 1_8)) then
        zres = cpp_iter_i_op_add(a1, i - a1%i)
        return
      end if
    end do
    zres = a2
  end function

  recursive function cpp_algo_equal__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    type(cpp_iter_i), intent(in) :: a3
    logical :: zres
    integer(8) :: i
    zres = .false.
    do i = a1%i, a2%i - 1_8
      if (a1%a%a(i) /= a3%a%a(a3%i + (i - a1%i))) return
    end do
    zres = .true.
  end function

  recursive subroutine cpp_algo_reverse__i(a1, a2)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    integer(8) :: i, j
    integer(4) :: t
    i = a1%i
    j = a2%i - 1_8
    do while (i < j)
      t = a1%a%a(i)
      a1%a%a(i) = a1%a%a(j)
      a1%a%a(j) = t
      i = i + 1_8
      j = j - 1_8
    end do
  end subroutine

  recursive function cpp_algo_remove_if__i(a1, a2, a3) result(zres)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    class(cpp_func_i_z), pointer, intent(in) :: a3
    type(cpp_iter_i) :: zres
    integer(8) :: first, res, i
    zres = a2
    first = a1%i
    do while (first /= a2%i)
      if (a3%invoke(a1%a%a(first))) exit
      if (associated(cpp_exc)) return
      first = first + 1_8
    end do
    if (first == a2%i) return
    res = first
    do i = first + 1_8, a2%i - 1_8
      if (.not. a3%invoke(a1%a%a(i))) then
        a1%a%a(res) = a1%a%a(i)
        res = res + 1_8
      end if
      if (associated(cpp_exc)) return
    end do
    zres = cpp_iter_i_op_add(a1, res - a1%i)
  end function

  recursive subroutine cpp_algo_replace__i(a1, a2, a3, a4)
    type(cpp_iter_i), intent(in) :: a1
    type(cpp_iter_i), intent(in) :: a2
    integer(4), value :: a3
    integer(4), value :: a4
    integer(8) :: i
    do i = a1%i, a2%i - 1_8
      if (a1%a%a(i) == a3) a1%a%a(i) = a4
    end do
  end subroutine

  ! ================================================================================================ StdAlgo

  ! ---- StdAlgo over double (std::sort, std::stable_sort, std::partial_sort; GCC 13 bits/stl_algo.h, stl_heap.h)
  recursive subroutine cpp_stdalgo_sort__d(a1, a2, a3, a4)
    class(cpp_arr_d), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_d_d_z), pointer, intent(in) :: a4
    if (a2 /= a3) then
      call cpp_b_introsort_d(a1, a2, a3, int(cpp_b_lg(a3 - a2), 8) * 2_8, a4)
      call cpp_b_final_insertion_sort_d(a1, a2, a3, a4)
    end if
  end subroutine
  recursive subroutine cpp_b_introsort_d(a, first, last0, depth0, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, last0, depth0
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: last, depth, cut
    last = last0
    depth = depth0
    do while (last - first > 16_8)
      if (depth == 0_8) then
        call cpp_b_partial_sort_d(a, first, last, last, comp)
        return
      end if
      depth = depth - 1_8
      cut = cpp_b_unguarded_partition_pivot_d(a, first, last, comp)
      call cpp_b_introsort_d(a, cut, last, depth, comp)
      last = cut
    end do
  end subroutine
  recursive function cpp_b_unguarded_partition_pivot_d(a, first, last, comp) result(zres)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: zres, mid
    mid = first + (last - first) / 2_8
    call cpp_b_move_median_to_first_d(a, first, first + 1_8, mid, last - 1_8, comp)
    zres = cpp_b_unguarded_partition_d(a, first + 1_8, last, first, comp)
  end function
  recursive subroutine cpp_b_move_median_to_first_d(x, result, a, b, c, comp)
    class(cpp_arr_d), intent(inout) :: x
    integer(8), value :: result, a, b, c
    class(cpp_func_d_d_z), intent(inout), target :: comp
    if (comp%invoke(x%a(a), x%a(b))) then
      if (comp%invoke(x%a(b), x%a(c))) then
        call cpp_b_swap_d(x, result, b)
      else if (comp%invoke(x%a(a), x%a(c))) then
        call cpp_b_swap_d(x, result, c)
      else
        call cpp_b_swap_d(x, result, a)
      end if
    else if (comp%invoke(x%a(a), x%a(c))) then
      call cpp_b_swap_d(x, result, a)
    else if (comp%invoke(x%a(b), x%a(c))) then
      call cpp_b_swap_d(x, result, c)
    else
      call cpp_b_swap_d(x, result, b)
    end if
  end subroutine
  recursive subroutine cpp_b_swap_d(a, i, j)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: i, j
    real(8) :: t
    t = a%a(i)
    a%a(i) = a%a(j)
    a%a(j) = t
  end subroutine
  recursive function cpp_b_unguarded_partition_d(a, first0, last0, pivot, comp) result(zres)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first0, last0, pivot
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: zres, first, last
    first = first0
    last = last0
    do
      do while (comp%invoke(a%a(first), a%a(pivot)))
        first = first + 1_8
      end do
      last = last - 1_8
      do while (comp%invoke(a%a(pivot), a%a(last)))
        last = last - 1_8
      end do
      if (.not. (first < last)) then
        zres = first
        return
      end if
      call cpp_b_swap_d(a, first, last)
      first = first + 1_8
    end do
  end function
  recursive subroutine cpp_b_final_insertion_sort_d(a, first, last, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: i
    if (last - first > 16_8) then
      call cpp_b_insertion_sort_d(a, first, first + 16_8, comp)
      do i = first + 16_8, last - 1_8
        call cpp_b_unguarded_linear_insert_d(a, i, comp)
      end do
    else
      call cpp_b_insertion_sort_d(a, first, last, comp)
    end if
  end subroutine
  recursive subroutine cpp_b_insertion_sort_d(a, first, last, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: i, k
    real(8) :: val
    if (first == last) return
    do i = first + 1_8, last - 1_8
      if (comp%invoke(a%a(i), a%a(first))) then
        val = a%a(i)
        do k = i - 1_8, first, -1_8          ! move_backward(first, i, i + 1)
          a%a(k + 1_8) = a%a(k)
        end do
        a%a(first) = val
      else
        call cpp_b_unguarded_linear_insert_d(a, i, comp)
      end if
    end do
  end subroutine
  recursive subroutine cpp_b_unguarded_linear_insert_d(a, last0, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: last0
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: last, next
    real(8) :: val
    last = last0
    val = a%a(last)
    next = last - 1_8
    do while (comp%invoke(val, a%a(next)))
      a%a(last) = a%a(next)
      last = next
      next = next - 1_8
    end do
    a%a(last) = val
  end subroutine
  recursive subroutine cpp_stdalgo_partialsort__d(a1, a2, a3, a4, a5)
    class(cpp_arr_d), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    integer(8), value :: a4
    class(cpp_func_d_d_z), pointer, intent(in) :: a5
    call cpp_b_partial_sort_d(a1, a2, a3, a4, a5)
  end subroutine
  recursive subroutine cpp_b_partial_sort_d(a, first, middle, last, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_d_d_z), intent(inout), target :: comp
    call cpp_b_heap_select_d(a, first, middle, last, comp)
    call cpp_b_sort_heap_d(a, first, middle, comp)
  end subroutine
  recursive subroutine cpp_b_heap_select_d(a, first, middle, last, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: i
    call cpp_b_make_heap_d(a, first, middle, comp)
    do i = middle, last - 1_8
      if (comp%invoke(a%a(i), a%a(first))) call cpp_b_pop_heap_d(a, first, middle, i, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_make_heap_d(a, first, last, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: len, parent
    real(8) :: hv
    if (last - first < 2_8) return
    len = last - first
    parent = (len - 2_8) / 2_8
    do
      hv = a%a(first + parent)
      call cpp_b_adjust_heap_d(a, first, parent, len, hv, comp)
      if (parent == 0_8) return
      parent = parent - 1_8
    end do
  end subroutine
  recursive subroutine cpp_b_pop_heap_d(a, first, last, result, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, last, result
    class(cpp_func_d_d_z), intent(inout), target :: comp
    real(8) :: hv
    hv = a%a(result)
    a%a(result) = a%a(first)
    call cpp_b_adjust_heap_d(a, first, 0_8, last - first, hv, comp)
  end subroutine
  recursive subroutine cpp_b_sort_heap_d(a, first, last0, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, last0
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: last
    last = last0
    do while (last - first > 1_8)
      last = last - 1_8
      call cpp_b_pop_heap_d(a, first, last, last, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_adjust_heap_d(a, first, hole0, len, hv0, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: first, hole0, len
    real(8), intent(in) :: hv0
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: top, second, hole, parent
    real(8) :: v
    v = hv0
    hole = hole0
    top = hole
    second = hole
    do while (second < (len - 1_8) / 2_8)
      second = 2_8 * (second + 1_8)
      if (comp%invoke(a%a(first + second), a%a(first + (second - 1_8)))) second = second - 1_8
      a%a(first + hole) = a%a(first + second)
      hole = second
    end do
    if (iand(len, 1_8) == 0_8 .and. second == (len - 2_8) / 2_8) then
      second = 2_8 * (second + 1_8)
      a%a(first + hole) = a%a(first + (second - 1_8))
      hole = second - 1_8
    end if
    parent = (hole - 1_8) / 2_8
    do
      if (.not. (hole > top)) exit
      if (.not. (comp%invoke(a%a(first + parent), v))) exit
      a%a(first + hole) = a%a(first + parent)
      hole = parent
      parent = (hole - 1_8) / 2_8
    end do
    a%a(first + hole) = v
  end subroutine
  recursive subroutine cpp_stdalgo_stablesort__d(a1, a2, a3, a4)
    class(cpp_arr_d), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_d_d_z), pointer, intent(in) :: a4
    real(8), allocatable :: buf(:)
    if (a3 - a2 < 2_8) return
    allocate(buf(0:a3 - a2 - 1_8))
    call cpp_b_merge_sort_d(a1, a2, a3, buf, a4)
  end subroutine
  recursive subroutine cpp_b_merge_sort_d(a, lo, hi, buf, comp)
    class(cpp_arr_d), intent(inout) :: a
    integer(8), value :: lo, hi
    real(8), intent(inout) :: buf(0:)
    class(cpp_func_d_d_z), intent(inout), target :: comp
    integer(8) :: mid, i, j, k
    if (hi - lo < 2_8) return
    mid = lo + (hi - lo) / 2_8
    call cpp_b_merge_sort_d(a, lo, mid, buf, comp)
    call cpp_b_merge_sort_d(a, mid, hi, buf, comp)
    i = lo
    j = mid
    k = 0_8
    do while (i < mid .and. j < hi)
      if (comp%invoke(a%a(j), a%a(i))) then        ! take the right one only if strictly less
        buf(k) = a%a(j)
        j = j + 1_8
      else
        buf(k) = a%a(i)
        i = i + 1_8
      end if
      k = k + 1_8
    end do
    do while (i < mid)
      buf(k) = a%a(i)
      i = i + 1_8
      k = k + 1_8
    end do
    do while (j < hi)
      buf(k) = a%a(j)
      j = j + 1_8
      k = k + 1_8
    end do
    a%a(lo:lo + k - 1_8) = buf(0:k - 1_8)
  end subroutine

  ! ---- StdAlgo over int (std::sort, std::stable_sort, std::partial_sort; GCC 13 bits/stl_algo.h, stl_heap.h)
  recursive subroutine cpp_stdalgo_sort__i(a1, a2, a3, a4)
    class(cpp_arr_i), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_i_i_z), pointer, intent(in) :: a4
    if (a2 /= a3) then
      call cpp_b_introsort_i(a1, a2, a3, int(cpp_b_lg(a3 - a2), 8) * 2_8, a4)
      call cpp_b_final_insertion_sort_i(a1, a2, a3, a4)
    end if
  end subroutine
  recursive subroutine cpp_b_introsort_i(a, first, last0, depth0, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, last0, depth0
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: last, depth, cut
    last = last0
    depth = depth0
    do while (last - first > 16_8)
      if (depth == 0_8) then
        call cpp_b_partial_sort_i(a, first, last, last, comp)
        return
      end if
      depth = depth - 1_8
      cut = cpp_b_unguarded_partition_pivot_i(a, first, last, comp)
      call cpp_b_introsort_i(a, cut, last, depth, comp)
      last = cut
    end do
  end subroutine
  recursive function cpp_b_unguarded_partition_pivot_i(a, first, last, comp) result(zres)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: zres, mid
    mid = first + (last - first) / 2_8
    call cpp_b_move_median_to_first_i(a, first, first + 1_8, mid, last - 1_8, comp)
    zres = cpp_b_unguarded_partition_i(a, first + 1_8, last, first, comp)
  end function
  recursive subroutine cpp_b_move_median_to_first_i(x, result, a, b, c, comp)
    class(cpp_arr_i), intent(inout) :: x
    integer(8), value :: result, a, b, c
    class(cpp_func_i_i_z), intent(inout), target :: comp
    if (comp%invoke(x%a(a), x%a(b))) then
      if (comp%invoke(x%a(b), x%a(c))) then
        call cpp_b_swap_i(x, result, b)
      else if (comp%invoke(x%a(a), x%a(c))) then
        call cpp_b_swap_i(x, result, c)
      else
        call cpp_b_swap_i(x, result, a)
      end if
    else if (comp%invoke(x%a(a), x%a(c))) then
      call cpp_b_swap_i(x, result, a)
    else if (comp%invoke(x%a(b), x%a(c))) then
      call cpp_b_swap_i(x, result, c)
    else
      call cpp_b_swap_i(x, result, b)
    end if
  end subroutine
  recursive subroutine cpp_b_swap_i(a, i, j)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: i, j
    integer(4) :: t
    t = a%a(i)
    a%a(i) = a%a(j)
    a%a(j) = t
  end subroutine
  recursive function cpp_b_unguarded_partition_i(a, first0, last0, pivot, comp) result(zres)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first0, last0, pivot
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: zres, first, last
    first = first0
    last = last0
    do
      do while (comp%invoke(a%a(first), a%a(pivot)))
        first = first + 1_8
      end do
      last = last - 1_8
      do while (comp%invoke(a%a(pivot), a%a(last)))
        last = last - 1_8
      end do
      if (.not. (first < last)) then
        zres = first
        return
      end if
      call cpp_b_swap_i(a, first, last)
      first = first + 1_8
    end do
  end function
  recursive subroutine cpp_b_final_insertion_sort_i(a, first, last, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: i
    if (last - first > 16_8) then
      call cpp_b_insertion_sort_i(a, first, first + 16_8, comp)
      do i = first + 16_8, last - 1_8
        call cpp_b_unguarded_linear_insert_i(a, i, comp)
      end do
    else
      call cpp_b_insertion_sort_i(a, first, last, comp)
    end if
  end subroutine
  recursive subroutine cpp_b_insertion_sort_i(a, first, last, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: i, k
    integer(4) :: val
    if (first == last) return
    do i = first + 1_8, last - 1_8
      if (comp%invoke(a%a(i), a%a(first))) then
        val = a%a(i)
        do k = i - 1_8, first, -1_8          ! move_backward(first, i, i + 1)
          a%a(k + 1_8) = a%a(k)
        end do
        a%a(first) = val
      else
        call cpp_b_unguarded_linear_insert_i(a, i, comp)
      end if
    end do
  end subroutine
  recursive subroutine cpp_b_unguarded_linear_insert_i(a, last0, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: last0
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: last, next
    integer(4) :: val
    last = last0
    val = a%a(last)
    next = last - 1_8
    do while (comp%invoke(val, a%a(next)))
      a%a(last) = a%a(next)
      last = next
      next = next - 1_8
    end do
    a%a(last) = val
  end subroutine
  recursive subroutine cpp_stdalgo_partialsort__i(a1, a2, a3, a4, a5)
    class(cpp_arr_i), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    integer(8), value :: a4
    class(cpp_func_i_i_z), pointer, intent(in) :: a5
    call cpp_b_partial_sort_i(a1, a2, a3, a4, a5)
  end subroutine
  recursive subroutine cpp_b_partial_sort_i(a, first, middle, last, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_i_i_z), intent(inout), target :: comp
    call cpp_b_heap_select_i(a, first, middle, last, comp)
    call cpp_b_sort_heap_i(a, first, middle, comp)
  end subroutine
  recursive subroutine cpp_b_heap_select_i(a, first, middle, last, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: i
    call cpp_b_make_heap_i(a, first, middle, comp)
    do i = middle, last - 1_8
      if (comp%invoke(a%a(i), a%a(first))) call cpp_b_pop_heap_i(a, first, middle, i, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_make_heap_i(a, first, last, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: len, parent
    integer(4) :: hv
    if (last - first < 2_8) return
    len = last - first
    parent = (len - 2_8) / 2_8
    do
      hv = a%a(first + parent)
      call cpp_b_adjust_heap_i(a, first, parent, len, hv, comp)
      if (parent == 0_8) return
      parent = parent - 1_8
    end do
  end subroutine
  recursive subroutine cpp_b_pop_heap_i(a, first, last, result, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, last, result
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(4) :: hv
    hv = a%a(result)
    a%a(result) = a%a(first)
    call cpp_b_adjust_heap_i(a, first, 0_8, last - first, hv, comp)
  end subroutine
  recursive subroutine cpp_b_sort_heap_i(a, first, last0, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, last0
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: last
    last = last0
    do while (last - first > 1_8)
      last = last - 1_8
      call cpp_b_pop_heap_i(a, first, last, last, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_adjust_heap_i(a, first, hole0, len, hv0, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: first, hole0, len
    integer(4), intent(in) :: hv0
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: top, second, hole, parent
    integer(4) :: v
    v = hv0
    hole = hole0
    top = hole
    second = hole
    do while (second < (len - 1_8) / 2_8)
      second = 2_8 * (second + 1_8)
      if (comp%invoke(a%a(first + second), a%a(first + (second - 1_8)))) second = second - 1_8
      a%a(first + hole) = a%a(first + second)
      hole = second
    end do
    if (iand(len, 1_8) == 0_8 .and. second == (len - 2_8) / 2_8) then
      second = 2_8 * (second + 1_8)
      a%a(first + hole) = a%a(first + (second - 1_8))
      hole = second - 1_8
    end if
    parent = (hole - 1_8) / 2_8
    do
      if (.not. (hole > top)) exit
      if (.not. (comp%invoke(a%a(first + parent), v))) exit
      a%a(first + hole) = a%a(first + parent)
      hole = parent
      parent = (hole - 1_8) / 2_8
    end do
    a%a(first + hole) = v
  end subroutine
  recursive subroutine cpp_stdalgo_stablesort__i(a1, a2, a3, a4)
    class(cpp_arr_i), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_i_i_z), pointer, intent(in) :: a4
    integer(4), allocatable :: buf(:)
    if (a3 - a2 < 2_8) return
    allocate(buf(0:a3 - a2 - 1_8))
    call cpp_b_merge_sort_i(a1, a2, a3, buf, a4)
  end subroutine
  recursive subroutine cpp_b_merge_sort_i(a, lo, hi, buf, comp)
    class(cpp_arr_i), intent(inout) :: a
    integer(8), value :: lo, hi
    integer(4), intent(inout) :: buf(0:)
    class(cpp_func_i_i_z), intent(inout), target :: comp
    integer(8) :: mid, i, j, k
    if (hi - lo < 2_8) return
    mid = lo + (hi - lo) / 2_8
    call cpp_b_merge_sort_i(a, lo, mid, buf, comp)
    call cpp_b_merge_sort_i(a, mid, hi, buf, comp)
    i = lo
    j = mid
    k = 0_8
    do while (i < mid .and. j < hi)
      if (comp%invoke(a%a(j), a%a(i))) then        ! take the right one only if strictly less
        buf(k) = a%a(j)
        j = j + 1_8
      else
        buf(k) = a%a(i)
        i = i + 1_8
      end if
      k = k + 1_8
    end do
    do while (i < mid)
      buf(k) = a%a(i)
      i = i + 1_8
      k = k + 1_8
    end do
    do while (j < hi)
      buf(k) = a%a(j)
      j = j + 1_8
      k = k + 1_8
    end do
    a%a(lo:lo + k - 1_8) = buf(0:k - 1_8)
  end subroutine

  ! ---- StdAlgo over long / ulong (std::sort, std::stable_sort, std::partial_sort; GCC 13 bits/stl_algo.h, stl_heap.h)
  recursive subroutine cpp_stdalgo_sort__l(a1, a2, a3, a4)
    class(cpp_arr_l), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_l_l_z), pointer, intent(in) :: a4
    if (a2 /= a3) then
      call cpp_b_introsort_l(a1, a2, a3, int(cpp_b_lg(a3 - a2), 8) * 2_8, a4)
      call cpp_b_final_insertion_sort_l(a1, a2, a3, a4)
    end if
  end subroutine
  recursive subroutine cpp_b_introsort_l(a, first, last0, depth0, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, last0, depth0
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: last, depth, cut
    last = last0
    depth = depth0
    do while (last - first > 16_8)
      if (depth == 0_8) then
        call cpp_b_partial_sort_l(a, first, last, last, comp)
        return
      end if
      depth = depth - 1_8
      cut = cpp_b_unguarded_partition_pivot_l(a, first, last, comp)
      call cpp_b_introsort_l(a, cut, last, depth, comp)
      last = cut
    end do
  end subroutine
  recursive function cpp_b_unguarded_partition_pivot_l(a, first, last, comp) result(zres)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: zres, mid
    mid = first + (last - first) / 2_8
    call cpp_b_move_median_to_first_l(a, first, first + 1_8, mid, last - 1_8, comp)
    zres = cpp_b_unguarded_partition_l(a, first + 1_8, last, first, comp)
  end function
  recursive subroutine cpp_b_move_median_to_first_l(x, result, a, b, c, comp)
    class(cpp_arr_l), intent(inout) :: x
    integer(8), value :: result, a, b, c
    class(cpp_func_l_l_z), intent(inout), target :: comp
    if (comp%invoke(x%a(a), x%a(b))) then
      if (comp%invoke(x%a(b), x%a(c))) then
        call cpp_b_swap_l(x, result, b)
      else if (comp%invoke(x%a(a), x%a(c))) then
        call cpp_b_swap_l(x, result, c)
      else
        call cpp_b_swap_l(x, result, a)
      end if
    else if (comp%invoke(x%a(a), x%a(c))) then
      call cpp_b_swap_l(x, result, a)
    else if (comp%invoke(x%a(b), x%a(c))) then
      call cpp_b_swap_l(x, result, c)
    else
      call cpp_b_swap_l(x, result, b)
    end if
  end subroutine
  recursive subroutine cpp_b_swap_l(a, i, j)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: i, j
    integer(8) :: t
    t = a%a(i)
    a%a(i) = a%a(j)
    a%a(j) = t
  end subroutine
  recursive function cpp_b_unguarded_partition_l(a, first0, last0, pivot, comp) result(zres)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first0, last0, pivot
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: zres, first, last
    first = first0
    last = last0
    do
      do while (comp%invoke(a%a(first), a%a(pivot)))
        first = first + 1_8
      end do
      last = last - 1_8
      do while (comp%invoke(a%a(pivot), a%a(last)))
        last = last - 1_8
      end do
      if (.not. (first < last)) then
        zres = first
        return
      end if
      call cpp_b_swap_l(a, first, last)
      first = first + 1_8
    end do
  end function
  recursive subroutine cpp_b_final_insertion_sort_l(a, first, last, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: i
    if (last - first > 16_8) then
      call cpp_b_insertion_sort_l(a, first, first + 16_8, comp)
      do i = first + 16_8, last - 1_8
        call cpp_b_unguarded_linear_insert_l(a, i, comp)
      end do
    else
      call cpp_b_insertion_sort_l(a, first, last, comp)
    end if
  end subroutine
  recursive subroutine cpp_b_insertion_sort_l(a, first, last, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: i, k
    integer(8) :: val
    if (first == last) return
    do i = first + 1_8, last - 1_8
      if (comp%invoke(a%a(i), a%a(first))) then
        val = a%a(i)
        do k = i - 1_8, first, -1_8          ! move_backward(first, i, i + 1)
          a%a(k + 1_8) = a%a(k)
        end do
        a%a(first) = val
      else
        call cpp_b_unguarded_linear_insert_l(a, i, comp)
      end if
    end do
  end subroutine
  recursive subroutine cpp_b_unguarded_linear_insert_l(a, last0, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: last0
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: last, next
    integer(8) :: val
    last = last0
    val = a%a(last)
    next = last - 1_8
    do while (comp%invoke(val, a%a(next)))
      a%a(last) = a%a(next)
      last = next
      next = next - 1_8
    end do
    a%a(last) = val
  end subroutine
  recursive subroutine cpp_stdalgo_partialsort__l(a1, a2, a3, a4, a5)
    class(cpp_arr_l), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    integer(8), value :: a4
    class(cpp_func_l_l_z), pointer, intent(in) :: a5
    call cpp_b_partial_sort_l(a1, a2, a3, a4, a5)
  end subroutine
  recursive subroutine cpp_b_partial_sort_l(a, first, middle, last, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_l_l_z), intent(inout), target :: comp
    call cpp_b_heap_select_l(a, first, middle, last, comp)
    call cpp_b_sort_heap_l(a, first, middle, comp)
  end subroutine
  recursive subroutine cpp_b_heap_select_l(a, first, middle, last, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: i
    call cpp_b_make_heap_l(a, first, middle, comp)
    do i = middle, last - 1_8
      if (comp%invoke(a%a(i), a%a(first))) call cpp_b_pop_heap_l(a, first, middle, i, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_make_heap_l(a, first, last, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: len, parent
    integer(8) :: hv
    if (last - first < 2_8) return
    len = last - first
    parent = (len - 2_8) / 2_8
    do
      hv = a%a(first + parent)
      call cpp_b_adjust_heap_l(a, first, parent, len, hv, comp)
      if (parent == 0_8) return
      parent = parent - 1_8
    end do
  end subroutine
  recursive subroutine cpp_b_pop_heap_l(a, first, last, result, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, last, result
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: hv
    hv = a%a(result)
    a%a(result) = a%a(first)
    call cpp_b_adjust_heap_l(a, first, 0_8, last - first, hv, comp)
  end subroutine
  recursive subroutine cpp_b_sort_heap_l(a, first, last0, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, last0
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: last
    last = last0
    do while (last - first > 1_8)
      last = last - 1_8
      call cpp_b_pop_heap_l(a, first, last, last, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_adjust_heap_l(a, first, hole0, len, hv0, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: first, hole0, len
    integer(8), intent(in) :: hv0
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: top, second, hole, parent
    integer(8) :: v
    v = hv0
    hole = hole0
    top = hole
    second = hole
    do while (second < (len - 1_8) / 2_8)
      second = 2_8 * (second + 1_8)
      if (comp%invoke(a%a(first + second), a%a(first + (second - 1_8)))) second = second - 1_8
      a%a(first + hole) = a%a(first + second)
      hole = second
    end do
    if (iand(len, 1_8) == 0_8 .and. second == (len - 2_8) / 2_8) then
      second = 2_8 * (second + 1_8)
      a%a(first + hole) = a%a(first + (second - 1_8))
      hole = second - 1_8
    end if
    parent = (hole - 1_8) / 2_8
    do
      if (.not. (hole > top)) exit
      if (.not. (comp%invoke(a%a(first + parent), v))) exit
      a%a(first + hole) = a%a(first + parent)
      hole = parent
      parent = (hole - 1_8) / 2_8
    end do
    a%a(first + hole) = v
  end subroutine
  recursive subroutine cpp_stdalgo_stablesort__l(a1, a2, a3, a4)
    class(cpp_arr_l), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_l_l_z), pointer, intent(in) :: a4
    integer(8), allocatable :: buf(:)
    if (a3 - a2 < 2_8) return
    allocate(buf(0:a3 - a2 - 1_8))
    call cpp_b_merge_sort_l(a1, a2, a3, buf, a4)
  end subroutine
  recursive subroutine cpp_b_merge_sort_l(a, lo, hi, buf, comp)
    class(cpp_arr_l), intent(inout) :: a
    integer(8), value :: lo, hi
    integer(8), intent(inout) :: buf(0:)
    class(cpp_func_l_l_z), intent(inout), target :: comp
    integer(8) :: mid, i, j, k
    if (hi - lo < 2_8) return
    mid = lo + (hi - lo) / 2_8
    call cpp_b_merge_sort_l(a, lo, mid, buf, comp)
    call cpp_b_merge_sort_l(a, mid, hi, buf, comp)
    i = lo
    j = mid
    k = 0_8
    do while (i < mid .and. j < hi)
      if (comp%invoke(a%a(j), a%a(i))) then        ! take the right one only if strictly less
        buf(k) = a%a(j)
        j = j + 1_8
      else
        buf(k) = a%a(i)
        i = i + 1_8
      end if
      k = k + 1_8
    end do
    do while (i < mid)
      buf(k) = a%a(i)
      i = i + 1_8
      k = k + 1_8
    end do
    do while (j < hi)
      buf(k) = a%a(j)
      j = j + 1_8
      k = k + 1_8
    end do
    a%a(lo:lo + k - 1_8) = buf(0:k - 1_8)
  end subroutine

  ! ---- StdAlgo over erased elements (slots) (std::sort, std::stable_sort, std::partial_sort; GCC 13 bits/stl_algo.h, stl_heap.h)
  recursive subroutine cpp_stdalgo_sort__o(a1, a2, a3, a4, mk5, cm6)
    class(cpp_arr_o), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_o_o_z), pointer, intent(in) :: a4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
    if (a2 /= a3) then
      call cpp_b_introsort_o(a1, a2, a3, int(cpp_b_lg(a3 - a2), 8) * 2_8, a4)
      call cpp_b_final_insertion_sort_o(a1, a2, a3, a4)
    end if
  end subroutine
  recursive subroutine cpp_b_introsort_o(a, first, last0, depth0, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, last0, depth0
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: last, depth, cut
    last = last0
    depth = depth0
    do while (last - first > 16_8)
      if (depth == 0_8) then
        call cpp_b_partial_sort_o(a, first, last, last, comp)
        return
      end if
      depth = depth - 1_8
      cut = cpp_b_unguarded_partition_pivot_o(a, first, last, comp)
      call cpp_b_introsort_o(a, cut, last, depth, comp)
      last = cut
    end do
  end subroutine
  recursive function cpp_b_unguarded_partition_pivot_o(a, first, last, comp) result(zres)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: zres, mid
    mid = first + (last - first) / 2_8
    call cpp_b_move_median_to_first_o(a, first, first + 1_8, mid, last - 1_8, comp)
    zres = cpp_b_unguarded_partition_o(a, first + 1_8, last, first, comp)
  end function
  recursive subroutine cpp_b_move_median_to_first_o(x, result, a, b, c, comp)
    class(cpp_arr_o), intent(inout) :: x
    integer(8), value :: result, a, b, c
    class(cpp_func_o_o_z), intent(inout), target :: comp
    if (comp%invoke(x%a(a)%p, x%a(b)%p)) then
      if (comp%invoke(x%a(b)%p, x%a(c)%p)) then
        call cpp_b_swap_o(x, result, b)
      else if (comp%invoke(x%a(a)%p, x%a(c)%p)) then
        call cpp_b_swap_o(x, result, c)
      else
        call cpp_b_swap_o(x, result, a)
      end if
    else if (comp%invoke(x%a(a)%p, x%a(c)%p)) then
      call cpp_b_swap_o(x, result, a)
    else if (comp%invoke(x%a(b)%p, x%a(c)%p)) then
      call cpp_b_swap_o(x, result, c)
    else
      call cpp_b_swap_o(x, result, b)
    end if
  end subroutine
  recursive subroutine cpp_b_swap_o(a, i, j)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: i, j
    type(cpp_slot) :: t
    t = a%a(i)
    a%a(i) = a%a(j)
    a%a(j) = t
  end subroutine
  recursive function cpp_b_unguarded_partition_o(a, first0, last0, pivot, comp) result(zres)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first0, last0, pivot
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: zres, first, last
    first = first0
    last = last0
    do
      do while (comp%invoke(a%a(first)%p, a%a(pivot)%p))
        first = first + 1_8
      end do
      last = last - 1_8
      do while (comp%invoke(a%a(pivot)%p, a%a(last)%p))
        last = last - 1_8
      end do
      if (.not. (first < last)) then
        zres = first
        return
      end if
      call cpp_b_swap_o(a, first, last)
      first = first + 1_8
    end do
  end function
  recursive subroutine cpp_b_final_insertion_sort_o(a, first, last, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: i
    if (last - first > 16_8) then
      call cpp_b_insertion_sort_o(a, first, first + 16_8, comp)
      do i = first + 16_8, last - 1_8
        call cpp_b_unguarded_linear_insert_o(a, i, comp)
      end do
    else
      call cpp_b_insertion_sort_o(a, first, last, comp)
    end if
  end subroutine
  recursive subroutine cpp_b_insertion_sort_o(a, first, last, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: i, k
    type(cpp_slot) :: val
    if (first == last) return
    do i = first + 1_8, last - 1_8
      if (comp%invoke(a%a(i)%p, a%a(first)%p)) then
        val = a%a(i)
        do k = i - 1_8, first, -1_8          ! move_backward(first, i, i + 1)
          a%a(k + 1_8) = a%a(k)
        end do
        a%a(first) = val
      else
        call cpp_b_unguarded_linear_insert_o(a, i, comp)
      end if
    end do
  end subroutine
  recursive subroutine cpp_b_unguarded_linear_insert_o(a, last0, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: last0
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: last, next
    type(cpp_slot) :: val
    last = last0
    val = a%a(last)
    next = last - 1_8
    do while (comp%invoke(val%p, a%a(next)%p))
      a%a(last) = a%a(next)
      last = next
      next = next - 1_8
    end do
    a%a(last) = val
  end subroutine
  recursive subroutine cpp_stdalgo_partialsort__o(a1, a2, a3, a4, a5, mk6, cm7)
    class(cpp_arr_o), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    integer(8), value :: a4
    class(cpp_func_o_o_z), pointer, intent(in) :: a5
    procedure(cpp_maker) :: mk6
    integer(4), value :: cm7
    call cpp_b_partial_sort_o(a1, a2, a3, a4, a5)
  end subroutine
  recursive subroutine cpp_b_partial_sort_o(a, first, middle, last, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_o_o_z), intent(inout), target :: comp
    call cpp_b_heap_select_o(a, first, middle, last, comp)
    call cpp_b_sort_heap_o(a, first, middle, comp)
  end subroutine
  recursive subroutine cpp_b_heap_select_o(a, first, middle, last, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, middle, last
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: i
    call cpp_b_make_heap_o(a, first, middle, comp)
    do i = middle, last - 1_8
      if (comp%invoke(a%a(i)%p, a%a(first)%p)) call cpp_b_pop_heap_o(a, first, middle, i, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_make_heap_o(a, first, last, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, last
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: len, parent
    type(cpp_slot) :: hv
    if (last - first < 2_8) return
    len = last - first
    parent = (len - 2_8) / 2_8
    do
      hv = a%a(first + parent)
      call cpp_b_adjust_heap_o(a, first, parent, len, hv, comp)
      if (parent == 0_8) return
      parent = parent - 1_8
    end do
  end subroutine
  recursive subroutine cpp_b_pop_heap_o(a, first, last, result, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, last, result
    class(cpp_func_o_o_z), intent(inout), target :: comp
    type(cpp_slot) :: hv
    hv = a%a(result)
    a%a(result) = a%a(first)
    call cpp_b_adjust_heap_o(a, first, 0_8, last - first, hv, comp)
  end subroutine
  recursive subroutine cpp_b_sort_heap_o(a, first, last0, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, last0
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: last
    last = last0
    do while (last - first > 1_8)
      last = last - 1_8
      call cpp_b_pop_heap_o(a, first, last, last, comp)
    end do
  end subroutine
  recursive subroutine cpp_b_adjust_heap_o(a, first, hole0, len, hv0, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: first, hole0, len
    type(cpp_slot), intent(in) :: hv0
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: top, second, hole, parent
    type(cpp_slot) :: v
    v = hv0
    hole = hole0
    top = hole
    second = hole
    do while (second < (len - 1_8) / 2_8)
      second = 2_8 * (second + 1_8)
      if (comp%invoke(a%a(first + second)%p, a%a(first + (second - 1_8))%p)) second = second - 1_8
      a%a(first + hole) = a%a(first + second)
      hole = second
    end do
    if (iand(len, 1_8) == 0_8 .and. second == (len - 2_8) / 2_8) then
      second = 2_8 * (second + 1_8)
      a%a(first + hole) = a%a(first + (second - 1_8))
      hole = second - 1_8
    end if
    parent = (hole - 1_8) / 2_8
    do
      if (.not. (hole > top)) exit
      if (.not. (comp%invoke(a%a(first + parent)%p, v%p))) exit
      a%a(first + hole) = a%a(first + parent)
      hole = parent
      parent = (hole - 1_8) / 2_8
    end do
    a%a(first + hole) = v
  end subroutine
  recursive subroutine cpp_stdalgo_stablesort__o(a1, a2, a3, a4, mk5, cm6)
    class(cpp_arr_o), pointer, intent(in) :: a1
    integer(8), value :: a2
    integer(8), value :: a3
    class(cpp_func_o_o_z), pointer, intent(in) :: a4
    procedure(cpp_maker) :: mk5
    integer(4), value :: cm6
    type(cpp_slot), allocatable :: buf(:)
    if (a3 - a2 < 2_8) return
    allocate(buf(0:a3 - a2 - 1_8))
    call cpp_b_merge_sort_o(a1, a2, a3, buf, a4)
  end subroutine
  recursive subroutine cpp_b_merge_sort_o(a, lo, hi, buf, comp)
    class(cpp_arr_o), intent(inout) :: a
    integer(8), value :: lo, hi
    type(cpp_slot), intent(inout) :: buf(0:)
    class(cpp_func_o_o_z), intent(inout), target :: comp
    integer(8) :: mid, i, j, k
    if (hi - lo < 2_8) return
    mid = lo + (hi - lo) / 2_8
    call cpp_b_merge_sort_o(a, lo, mid, buf, comp)
    call cpp_b_merge_sort_o(a, mid, hi, buf, comp)
    i = lo
    j = mid
    k = 0_8
    do while (i < mid .and. j < hi)
      if (comp%invoke(a%a(j)%p, a%a(i)%p)) then        ! take the right one only if strictly less
        buf(k) = a%a(j)
        j = j + 1_8
      else
        buf(k) = a%a(i)
        i = i + 1_8
      end if
      k = k + 1_8
    end do
    do while (i < mid)
      buf(k) = a%a(i)
      i = i + 1_8
      k = k + 1_8
    end do
    do while (j < hi)
      buf(k) = a%a(j)
      j = j + 1_8
      k = k + 1_8
    end do
    a%a(lo:lo + k - 1_8) = buf(0:k - 1_8)
  end subroutine

end module cpp_rt_b
