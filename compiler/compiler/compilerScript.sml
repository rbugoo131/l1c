open HolKernel boolLib bossLib l1_to_il1_compilerTheory il1_to_il2_compilerTheory store_creationTheory il1_il2_correctnessTheory l1_il1_correctnessTheory lcsymtacs il2_to_il3_compilerTheory listTheory pairTheory pred_setTheory l1_il1_totalTheory bigstep_il1Theory ast_l1Theory store_equivalenceTheory finite_mapTheory il3_to_vsm0_correctnessTheory il3_store_propertiesTheory il2_il3_correctnessTheory bs_ss_equivalenceTheory smallstep_vsm0_clockedTheory bigstep_il1_clockedTheory vsm0_clocked_equivTheory clocked_equivTheory relationTheory smallstep_il2Theory vsm_compositionTheory integerTheory vsm0_optTheory constant_foldingTheory

val _ = new_theory "compiler"

val il2_vsm_correctness_1 = store_thm("il2_vsm_correctness",``
!P pc c stk st.
exec_clocked P (SOME (pc, c, stk, st)) NONE /\ ms_il2 P st ==>

vsm_exec_c (il2_to_il3 P) (SOME (pc, c, astack (il2_to_il3 P) (MAP_KEYS (map_fun (FST (make_loc_map P))) st) stk)) NONE``,

rw []
THEN imp_res_tac IL2_IL3_EQ_1
THEN imp_res_tac vsm_exec_correctness_1_thm

THEN `ms_il2 P st ==> (!l.l ∈ FDOM (MAP_KEYS (map_fun (FST (make_loc_map P))) st) <=> (l < s_uloc (il2_to_il3 P)))` by metis_tac [min_store_imp_all_locs_in_range]

THEN metis_tac [])

val il2_vsm_correctness_2 = store_thm("il2_vsm_correctness",``
!P pc c stk st pc' c' stk' st'.
exec_clocked P (SOME (pc, c, stk, st)) (SOME (pc', c', stk', st')) /\ ms_il2 P st ==>

?n astk.vsm_exec_c (il2_to_il3 P) (SOME (pc, c, astack (il2_to_il3 P) (MAP_KEYS (map_fun (FST (make_loc_map P))) st) stk)) (SOME (pc', c', astk)) /\ (stk' = TAKE n astk)``,

rw []
THEN imp_res_tac IL2_IL3_EQ_2
THEN imp_res_tac vsm_exec_correctness_2_thm

THEN `ms_il2 P st ==> (!l.l ∈ FDOM (MAP_KEYS (map_fun (FST (make_loc_map P))) st) <=> (l < s_uloc (il2_to_il3 P)))` by metis_tac [min_store_imp_all_locs_in_range]

THEN metis_tac [])

val compile_il2_def = Define `compile_il2 e = il1_to_il2 (l1_to_il1 e 0)`

val compile_def = Define `compile e = il2_to_il3 (compile_il2 e)`

val compile_opt_def = Define `compile_opt e = comp_nopr (comp_pp (compile e))`

val push_zeroes_def = Define `(push_zeroes 0 = []) /\ (push_zeroes (SUC n) = SNOC (VSM_Push 0) (push_zeroes n))`

val full_compile_def = Define `full_compile e = (push_zeroes (s_uloc (compile e))) ++ compile_opt e`

val create_il2_store_def = Define `
(create_il2_store [] = FEMPTY) /\
(create_il2_store (IL2_Store l::xs) = (create_il2_store xs) |+ (l, 0)) /\
(create_il2_store (IL2_Load l::xs) = (create_il2_store xs) |+ (l, 0)) /\
(create_il2_store (_::xs) = (create_il2_store xs))`

val ms_il2_st_thm = prove(``!e.ms_il2 e (create_il2_store e)``,

Induct_on `e` THEN rw [ms_il2_def, create_il2_store_def, make_loc_map_def, locs_to_map_def, get_locations_def, FST]

THEN Cases_on `h` THEN fs [create_il2_store_def, get_locations_def] THEN rw [] THEN fs [make_loc_map_def, ms_il2_def]

THEN fs [locs_to_map_def]

THEN `?m n.locs_to_map (get_locations e) = (m, n)` by metis_tac [locs_to_map_total_thm]

THEN rw [LET_DEF]

THEN metis_tac [ABSORPTION_RWT])

fun btotal f x = f x handle HOL_ERR _ => false

fun P id tm =
  btotal ((equal id) o fst o dest_var) tm orelse
  P id (snd(listSyntax.dest_cons tm))

fun tac P (g as (asl,w)) =
  let
    val ts = mk_set(List.concat (map (find_terms (btotal P)) (w::asl)))
    val ths = mapfilter (fn tm => map (C SPEC (ASSUME tm)) ts) asl
  in
    map_every assume_tac (List.concat ths)
  end g


val union_abs_thm = prove(``!x y.x ⊌ y ⊌ x = x ⊌ y``,
Induct_on `x` THEN rw [FUNION_FEMPTY_1, FUNION_FEMPTY_2] THEN rw [FUNION_FUPDATE_1, FUNION_FUPDATE_2])


val il2_store_etc = prove(``!x y.create_il2_store (x ++ y) = create_il2_store x ⊌ create_il2_store y``, Induct_on `x` THEN 
rw [create_il2_store_def, FUNION_FEMPTY_1] THEN Cases_on `h` THEN rw [create_il2_store_def, FUNION_FUPDATE_1])

val con_store_etc = prove(``!x y.con_store (x ⊌ y) = (con_store x) ⊌ (con_store y)``, rw [con_store_def]

THEN Induct_on `x` THEN Induct_on `y` THEN rw [FUNION_FEMPTY_1, FUNION_FEMPTY_2] THEN fs [GSYM MAP_APPEND_EQUIV_THM, FUNION_FUPDATE_1, FUNION_FUPDATE_2])

val zeroed_def = Define `zeroed m = !l.l ∈ FDOM m ==> (m ' l = 0)`

val equiv_etc = prove(``!a b c d.equiv a b /\ equiv c d ==> equiv (a ⊌ c) (b ⊌ d)``, rw [equiv_def] THEN Cases_on `User k ∈ FDOM a`
THEN metis_tac [FUNION_DEF])

val il2_store_etc2 = prove(``!l e.l ∈ FDOM (create_il2_store e) ==> ((create_il2_store e) ' l = 0)``,
Induct_on `e`
THEN rw [create_il2_store_def, FDOM_FEMPTY] THEN Cases_on `h` THEN fs [create_il2_store_def] THEN rw [] THEN Cases_on `i = l` THEN rw [FAPPLY_FUPDATE_THM])


val store_equiv_gen_thm = store_thm("store_equiv_gen_thm", ``!e n.equiv (con_store (create_store e)) (create_il2_store (il1_to_il2 (l1_to_il1 e n)))``,

Induct_on `e` THEN fs [compile_il2_def, il1_to_il2_def, il1e_to_il2_def, l1_to_il1_def, l1_to_il1_pair_def] THEN rw []

THEN1 (
rw [create_store_def]
THEN Cases_on `l` THEN
fs [l1_to_il1_pair_def] THEN rw []
THEN (TRY (Cases_on `b`)) THEN

 rw [il1_to_il2_def, create_il2_store_def, il2_store_etc, il1e_to_il2_def, con_store_def, MAP_KEYS_FEMPTY, EQUIV_REFL_THM])

THEN tac (P "n'")
THEN tac (P "n")
THEN tac (P "lc2")
THEN tac (P "lc3")
THEN tac (P "lc")
THEN rfs [LET_THM]

THEN rw []


THEN fs [il1_to_il2_def, il1e_to_il2_def]

THEN fs [il2_store_etc, create_il2_store_def, FUNION_FEMPTY_1, FUNION_FEMPTY_2, FUNION_FUPDATE_1, FUNION_FUPDATE_2]

THENL [Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1_to_il2 sl1))` THEN Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1e_to_il2 e1'))`,
Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1_to_il2 sl1))` THEN Cases_on `Compiler lc3 ∈ FDOM (create_il2_store (il1e_to_il2 e1'))`,
Cases_on `Compiler lc4 ∈ FDOM (create_il2_store (il1_to_il2 sl1))` THEN Cases_on `Compiler lc4 ∈ FDOM (create_il2_store (il1e_to_il2 e1'))`, Cases_on `User n ∈ FDOM (create_il2_store (il1_to_il2 sl))` THEN (Cases_on `User n ∈ FDOM (create_il2_store (il1e_to_il2 e'))`), all_tac, all_tac, all_tac]

THEN fs [] THEN rw [create_store_def] THEN fs [con_store_etc] THEN fs [equiv_def] THEN rw [] THEN `(create_il2_store (il1_to_il2 sl1) ⊌
 create_il2_store (il1e_to_il2 e1') ⊌
 create_il2_store (il1_to_il2 sl2) ⊌
 create_il2_store (il1e_to_il2 e2') ⊌
 create_il2_store (il1_to_il2 sl1)) = (create_il2_store (il1_to_il2 sl1) ⊌
 create_il2_store (il1e_to_il2 e1') ⊌
 create_il2_store (il1_to_il2 sl2) ⊌
 create_il2_store (il1e_to_il2 e2'))` by metis_tac [FUNION_ASSOC, union_abs_thm]
THEN rw []

THEN rw [GSYM FUNION_ASSOC, FUNION_DEF, FAPPLY_FUPDATE_THM, il2_store_etc2] THEN (TRY (metis_tac [il2_store_etc2])) THEN Cases_on `n=k` THEN rw [] THEN fs [con_store_def, GSYM MAP_APPEND_EQUIV_THM, MAP_KEYS_FEMPTY, FAPPLY_FUPDATE_THM] THEN rw [il2_store_etc2]

THEN rw [DISJ_ASSOC, EQ_IMP_THM] THEN TRY (metis_tac []))

val l1_to_il2_correctness_1_thm = prove(
``!c e v s' c'.bs_l1_c c (e, create_store e) NONE ==> exec_clocked (compile_il2 e) (SOME (0, c, [], con_store (create_store e))) NONE``,
rw [] THEN imp_res_tac L1_TO_IL1_CORRECTNESS_LEMMA THEN fs [FST, SND] THEN rw [compile_il2_def] THEN
rw [l1_to_il1_def]
THEN  `equiv (con_store (create_store e)) (con_store (create_store e))` by metis_tac [EQUIV_REFL_THM] THEN (imp_res_tac EQ_SYM THEN res_tac THEN rfs [] THEN rw [])

THEN `bs_il1_c c (IL1_Seq s (IL1_Expr te), con_store (create_store e)) NONE` by rw [Once bs_il1_c_cases]
THEN imp_res_tac IL1_IL2_CORRECTNESS_1_THM
THEN metis_tac [])


val l1_to_il2_correctness_2_thm = prove(
``!c e v s' c'.bs_l1_c c (e, create_store e) (SOME (v, s', c')) ==> ?s''.exec_clocked (compile_il2 e) (SOME (0, c, [], con_store (create_store e))) (SOME (&LENGTH (compile_il2 e), c', [(il1_il2_val (l1_il1_val v))], s''))``,
rw [] THEN imp_res_tac L1_TO_IL1_CORRECTNESS_LEMMA THEN fs [FST, SND] THEN rw [compile_il2_def] THEN
rw [l1_to_il1_def]

THEN `?st ex lc1'.l1_to_il1_pair 0 e = (st, ex, lc1')` by metis_tac [L1_TO_IL1_TOTAL_THM]


THEN `equiv (con_store (create_store e)) (con_store (create_store e))` by metis_tac [EQUIV_REFL_THM] THEN (imp_res_tac EQ_SYM THEN res_tac THEN rfs [] THEN rw [])
 THEN 
`bs_il1_c c (IL1_Seq st (IL1_Expr ex), con_store (create_store e)) (SOME (l1_il1_val v, fs', c'))` by (rw [Once bs_il1_c_cases] THEN metis_tac [bs_il1_c_cases])
THEN imp_res_tac IL1_IL2_CORRECTNESS_2_THM
THEN metis_tac [])

val length_prog_thm = prove(``!e.LENGTH (compile e) = LENGTH (compile_il2 e)``, rw [compile_def, compile_il2_def, il2_to_il3_def])

val make_stack_def = Define `make_stack e = astack (compile e)
            (MAP_KEYS (map_fun (FST (make_loc_map (compile_il2 e))))
               (create_il2_store (compile_il2 e))) []`

val push_thm = prove(``!n c.vsm_exec_c (push_zeroes n) (SOME (0, c, [])) (SOME (&LENGTH (push_zeroes n), c, GENLIST_AUX (\x.0) n []))``,

rw [] THEN Induct_on `n` THEN1 fs [push_zeroes_def, GENLIST_AUX, vsm_exec_c_def, RTC_REFL]

THEN fs [vsm_exec_c_def]

THEN rw [Once RTC_CASES2] THEN DISJ2_TAC

THEN Q.EXISTS_TAC `(SOME (&LENGTH (push_zeroes n), c, GENLIST_AUX (\x.0) n []))`

THEN rw [push_zeroes_def]

THEN fs [GSYM vsm_exec_c_def]

THEN rw [SNOC_APPEND]

THEN1 (match_mp_tac APPEND_TRACE_SAME_VSM0_THM THEN rw [])

THEN rw_tac (srw_ss () ++ intSimps.INT_ARITH_ss) [vsm_exec_c_one_cases, vsm_exec_c_instr_cases, fetch_append_thm, fetch_def] THEN (WEAKEN_TAC (fn x => true)) THEN fs [GSYM GENLIST_GENLIST_AUX, GENLIST_CONS] THEN rw [GENLIST_FUN_EQ])

val constant_list_reverse = prove(``!x xs.(!n.(n < LENGTH xs) ==> (EL n xs = x)) ==> (REVERSE xs = xs)``,
rw [] THEN match_mp_tac LIST_EQ THEN rw [EL_REVERSE] THEN `PRE (LENGTH xs - x') < LENGTH xs` by decide_tac THEN metis_tac [])

val genlist_thm = prove(``!n'.(!n.(n < LENGTH (GENLIST (\l.0) n')) ==> (EL n (GENLIST (\l.0) n') = 0))``,
rw [])

val create_il2_store_zero = prove(``!p x. x ∈ FDOM (create_il2_store p) ==> (create_il2_store p ' x = 0)``,
Induct_on `p` THEN rw [] THEN fs [create_il2_store_def] THEN Cases_on `h` THEN fs [create_il2_store_def] THEN metis_tac [FAPPLY_FUPDATE_THM])

val push2_thm = prove(``!e.make_stack e = REVERSE (GENLIST (\l.0) (s_uloc (compile e)))``,

rw [make_stack_def, astack_def]

THEN match_mp_tac LIST_EQ THEN rw []

THEN `ms_il2 (compile_il2 e) (create_il2_store (compile_il2 e))` by metis_tac [ms_il2_st_thm]

THEN `x ∈
        FDOM
          (MAP_KEYS
             (map_fun (FST (make_loc_map (compile_il2 e))))
             (create_il2_store (compile_il2 e)))` by metis_tac [compile_def, compile_il2_def, ms_il2_st_thm, EQ_IMP_THM, min_store_imp_all_locs_in_range]

THEN imp_res_tac map_deref_thm THEN fs [MAP_KEYS_def] THEN res_tac THEN fs [] THEN metis_tac [il2_store_etc2])


val push3_thm = store_thm("push3_thm", ``!e c.vsm_exec_c (push_zeroes (s_uloc (compile e))) (SOME (0, c, [])) (SOME (&LENGTH (push_zeroes (s_uloc (compile e))), c, make_stack e))``,
rw []
THEN `make_stack e = GENLIST_AUX (\x.0) (s_uloc (compile e)) []` by (fs [push2_thm, GSYM GENLIST_GENLIST_AUX] THEN
match_mp_tac LIST_EQ THEN rw [] THEN rw [EL_REVERSE] THEN `PRE (s_uloc (compile e) - x) < s_uloc (compile e)` by decide_tac THEN rw []) THEN metis_tac [push_thm])

val thmtest1 = prove(``!P P' c c' stk stk' c'' stk'' endpc.vsm_exec_c P (SOME (0, c, stk)) (SOME (&LENGTH P, c', stk')) /\ vsm_exec_c P' (SOME (0, c', stk')) (SOME (&LENGTH P', c'', stk'')) /\ (&LENGTH P' + &LENGTH P = endpc) ==>
vsm_exec_c (P ++ P') (SOME (0, c, stk)) (SOME (endpc, c'', stk''))``,
rw [vsm_exec_c_def]
THEN
match_mp_tac (GEN_ALL(CONJUNCT2 (SPEC_ALL (REWRITE_RULE [EQ_IMP_THM] RTC_CASES_RTC_TWICE)))) 
THEN fs [GSYM vsm_exec_c_def]

THEN rw [GSYM incr_pc_vsm0_def]
THEN Q.EXISTS_TAC `(SOME (&LENGTH P, c', stk'))` THEN rw [] THENL [all_tac, REWRITE_TAC [Once (GSYM INT_ADD_LID)] THEN rw [GSYM incr_pc_vsm0_def]] THEN metis_tac [APPEND_TRACE_SAME_VSM0_THM, APPEND_TRACE_SAME_2_VSM0_THM])

val init_stack_1_thm = prove(``!e c.vsm_exec_c (compile e) (SOME (0, c, make_stack e)) NONE ==> vsm_exec_c (full_compile e) (SOME (0, c, [])) NONE``,

rw [full_compile_def, vsm_exec_c_def]
THEN
match_mp_tac (GEN_ALL(CONJUNCT2 (SPEC_ALL (REWRITE_RULE [EQ_IMP_THM] RTC_CASES_RTC_TWICE)))) 
THEN fs [GSYM vsm_exec_c_def]

THEN Q.EXISTS_TAC `(SOME (&LENGTH (push_zeroes (s_uloc (compile e))), c, make_stack e))`
 THEN rw [] THEN1 (match_mp_tac APPEND_TRACE_SAME_VSM0_THM THEN metis_tac [push3_thm])

THEN REWRITE_TAC [Once (GSYM INT_ADD_LID)]
THEN REWRITE_TAC [Once (CONJUNCT2 (SPEC_ALL (Q.SPEC `&LENGTH (push_zeroes (s_uloc (compile e)))` (GEN_ALL (GSYM incr_pc_vsm0_def)))))]
THEN rw [GSYM incr_pc_vsm0_def]

THEN match_mp_tac APPEND_TRACE_SAME_2_VSM0_THM THEN rw [compile_opt_def, comp_pp_1_thm, comp_nopr_1_thm])

val init_stack_2_thm = prove(``!e c astk c'.vsm_exec_c (compile e) (SOME (0, c, make_stack e)) (SOME (&LENGTH (compile e), c', astk)) ==>
vsm_exec_c (full_compile e) (SOME (0, c, [])) (SOME (&LENGTH (full_compile e), c', astk))``,
rw [full_compile_def]
THEN match_mp_tac thmtest1
THEN Q.LIST_EXISTS_TAC [`c`, `make_stack e`] THEN rw [push3_thm] THEN RW_TAC (srw_ss () ++ intSimps.INT_ARITH_ss) [compile_opt_def, comp_pp_2_thm, comp_nopr_2_thm])

val c_opts_def = Define `c_opts e = full_compile (cfold e)`

val total_c_lem_1 = store_thm("total_c_lem_1", ``!c e t.l1_type e (FDOM (create_store e)) t /\ bs_l1_c c (e, create_store e) NONE ==> vsm_exec_c (c_opts e) (SOME (0, c, [])) NONE``,
rw [c_opts_def] THEN match_mp_tac init_stack_1_thm
THEN imp_res_tac cf_1
THEN rw [make_stack_def] THEN imp_res_tac l1_to_il2_correctness_1_thm

THEN `equiv (con_store (create_store (cfold e))) (create_il2_store (compile_il2 (cfold e)))` by metis_tac [compile_il2_def, store_equiv_gen_thm]

THEN imp_res_tac L1_TO_IL1_CORRECTNESS_LEMMA THEN fs [FST] THEN res_tac


THEN `?st ex lc1.l1_to_il1_pair 0 (cfold e) = (st, ex, lc1)` by metis_tac [L1_TO_IL1_TOTAL_THM]
THEN fs []
THEN (imp_res_tac EQ_SYM THEN res_tac THEN rfs [] THEN rw [])
THEN `ms_il2 (compile_il2 (cfold e)) (create_il2_store (compile_il2 (cfold e)))` by metis_tac [ms_il2_st_thm]

THEN `bs_il1_c c (IL1_Seq st (IL1_Expr ex), create_il2_store (compile_il2 (cfold e))) NONE` by rw [Once bs_il1_c_cases]
THEN imp_res_tac IL1_IL2_CORRECTNESS_1_THM THEN imp_res_tac il2_vsm_correctness_1 THEN fs[compile_def] THEN fs [compile_il2_def, l1_to_il1_def] THEN rfs [LET_DEF])

val total_c_lem_2 = store_thm("total_c_lem_2", ``!c e v s' c' t. l1_type e (FDOM (create_store e)) t /\
    bs_l1_c c (e, create_store e) (SOME (v, s', c')) ==> 
    ?astk.
        vsm_exec_c (compile (cfold e)) (SOME (0, c, make_stack (cfold e))) (SOME (&LENGTH (compile (cfold e)), c', (il1_il2_val (l1_il1_val v))::astk))``,

rw [make_stack_def]
THEN imp_res_tac cf_2
THEN imp_res_tac l1_to_il2_correctness_2_thm

THEN `equiv (con_store (create_store (cfold e))) (create_il2_store (compile_il2 (cfold e)))` by metis_tac [compile_il2_def, store_equiv_gen_thm]

THEN `∀st lc1' ex.
        ((st,ex,lc1') = l1_to_il1_pair 0 (FST (cfold e,create_store (cfold e)))) ⇒
        ∀fs.
          equiv (con_store (SND (cfold e,create_store (cfold e)))) fs ⇒
          ∃fs'.
            bs_il1_c c (st,fs) (SOME (IL1_ESkip, fs', c')) ∧
            bs_il1_expr (ex,fs') (l1_il1_val v) ∧
            equiv (con_store s'') fs'` by (rw [] THEN imp_res_tac L1_TO_IL1_CORRECTNESS_LEMMA THEN fs [FST] THEN res_tac THEN metis_tac [])

THEN fs [FST, SND]
THEN `?st ex lc1.l1_to_il1_pair 0 (cfold e) = (st, ex, lc1)` by metis_tac [L1_TO_IL1_TOTAL_THM]

THEN fs []
THEN res_tac

THEN `bs_il1_c c (l1_to_il1 (cfold e) 0, create_il2_store (compile_il2 (cfold e))) (SOME (l1_il1_val v, fs', c'))` by (rw [l1_to_il1_def, Once bs_il1_c_cases] THEN Q.LIST_EXISTS_TAC [`c'`, `fs'`] THEN rw [Once bs_il1_c_cases])

THEN `exec_clocked (il1_to_il2 (l1_to_il1 (cfold e) 0))
          (SOME (0, c, [],create_il2_store (compile_il2 (cfold e))))
          (SOME (&LENGTH (il1_to_il2 (l1_to_il1 (cfold e) 0)), c',
           [il1_il2_val (l1_il1_val v)],fs'))` by metis_tac [IL1_IL2_CORRECTNESS_2_THM]

THEN `ms_il2 (compile_il2 (cfold e)) (create_il2_store (compile_il2 (cfold e)))` by metis_tac [ms_il2_st_thm]

THEN fs [GSYM compile_il2_def]

THEN imp_res_tac il2_vsm_correctness_2

THEN res_tac

THEN `?atsk.astk' = (il1_il2_val (l1_il1_val v))::atsk` by (Cases_on `astk'` THEN fs [TAKE_def]
THEN Cases_on `n' = 0` THEN fs [])

THEN metis_tac [c_opts_def, compile_def, length_prog_thm])

val total_c_lem_1_2 = store_thm("total_c_lem_2", ``!c e v s' c' t. l1_type e (FDOM (create_store e)) t /\
    bs_l1_c c (e, create_store e) (SOME (v, s', c')) ==> 
    ?astk.
        vsm_exec_c (c_opts e) (SOME (0, c, [])) (SOME (&LENGTH (c_opts e), c', (il1_il2_val (l1_il1_val v))::astk))``, metis_tac [total_c_lem_2, init_stack_2_thm, c_opts_def])

val CORRECTNESS_THM = store_thm("CORRECTNESS_THM",
``!e v s' t.l1_type e (FDOM (create_store e)) t /\ bs_l1 (e, create_store e) v s' ==> ?stk'.vsm_exec (c_opts e) (0, []) (&LENGTH (c_opts e), il1_il2_val (l1_il1_val v)::stk')``,
rw []
THEN imp_res_tac UNCLOCKED_IMP_CLOCKED THEN
`!c'. ?c astk.vsm_exec_c (c_opts e) (SOME (0, SUC c, [])) (SOME (&LENGTH (c_opts e), SUC c', il1_il2_val (l1_il1_val v)::astk))` by metis_tac [total_c_lem_1_2]

THEN ` ∃c astk.
          vsm_exec_c (c_opts e) (SOME (0,SUC c,[]))
            (SOME
               (&LENGTH (c_opts e),SUC 0,
                il1_il2_val (l1_il1_val v)::astk))` by metis_tac []

THEN imp_res_tac VSM0_CLOCKED_IMP_UNCLOCKED THEN fs [] THEN metis_tac [])

val _ = export_theory ()
