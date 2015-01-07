open HolKernel boolLib bossLib listTheory Parse IndDefLib finite_mapTheory relationTheory arithmeticTheory l1Theory pred_setTheory pairTheory lcsymtacs;

val _ = new_theory "il1";

val _ = Hol_datatype `il1_loc = User of loc
                              | Compiler of loc`; 

val _ = Hol_datatype `il1_value = IL1_ESkip
                                | IL1_Integer of int
				| IL1_Boolean of bool`;

val _ = Hol_datatype `il1_expr = IL1_Value of il1_value
                               | IL1_Plus of il1_expr => il1_expr
                               | IL1_Geq of il1_expr => il1_expr
                               | IL1_Deref of il1_loc
                               | IL1_EIf of il1_expr => il1_expr => il1_expr`;

val _ = Hol_datatype `il1_stm = IL1_Expr of il1_expr
                              | IL1_Assign of il1_loc => il1_expr
                              | IL1_Seq of il1_stm => il1_stm
                              | IL1_SIf of il1_expr => il1_stm => il1_stm
                              | IL1_While of il1_expr => il1_stm`;

val contains_expr_def = Define `
    (contains_expr l (IL1_Value v) = F) /\
    (contains_expr l (IL1_Plus e1 e2) = contains_expr l e1 \/ contains_expr l e2) /\
    (contains_expr l (IL1_Geq e1 e2) = contains_expr l e1 \/ contains_expr l e2) /\
    (contains_expr l1 (IL1_Deref l2) = (l1 = l2)) /\
    (contains_expr l (IL1_EIf e1 e2 e3) = contains_expr l e1 \/ contains_expr l e2 \/ contains_expr l e3)`;

val contains_def = Define `
    (contains l (IL1_Expr e) = contains_expr l e) /\
    (contains l1 (IL1_Assign l2 e) = (l1 = l2) \/ contains_expr l1 e) /\
    (contains l (IL1_Seq e1 e2) = contains l e1 \/ contains l e2) /\
    (contains l (IL1_SIf e1 e2 e3) = contains_expr l e1 \/ contains l e2 \/ contains l e3) /\
    (contains l (IL1_While e1 e2) = contains_expr l e1 \/ contains l e2)`;

val contains_a_def = Define `
    (contains_a l (IL1_Expr _) = F) /\
    (contains_a l1 (IL1_Assign l2 e) = (l1 = l2)) /\
    (contains_a l (IL1_Seq e1 e2) = contains_a l e1 \/ contains_a l e2) /\
    (contains_a l (IL1_SIf _ e2 e3) = contains_a l e2 \/ contains_a l e3) /\
    (contains_a l (IL1_While _ e2) = contains_a l e2)`;

val CONTAINS_A_SUB = store_thm("CONTAINS_A_SUB",
``!l e.contains_a l e ==> contains l e``,
Induct_on `e` THEN metis_tac [contains_a_def, contains_def]);

val (bs_il1_expr_rules, bs_il1_expr_induction, bs_il1_expr_cases) = Hol_reln `
    (* Values *)
    (!v s.bs_il1_expr (IL1_Value v, s) v) /\

    (* Plus *)
    (!e1 e2 n1 n2 s.
        (bs_il1_expr (e1, s) (IL1_Integer n1) /\
         bs_il1_expr (e2, s) (IL1_Integer n2))
     ==> bs_il1_expr (IL1_Plus e1 e2, s) (IL1_Integer (n1 + n2))) /\

    (* Geq *)
    (!e1 e2 n1 n2 s.
        (bs_il1_expr (e1, s) (IL1_Integer n1) /\
         bs_il1_expr (e2, s) (IL1_Integer n2))
     ==> bs_il1_expr (IL1_Geq e1 e2, s) (IL1_Boolean (n1 >= n2))) /\

    (* Deref *)
    (!l s.
        l ∈ FDOM s
    ==> bs_il1_expr (IL1_Deref l, s) (IL1_Integer (s ' l))) /\

    (* EIf *)
    (!e1 e2 e3 s v.
        (bs_il1_expr (e1, s) (IL1_Boolean T) /\
         bs_il1_expr (e2, s) v)
     ==> bs_il1_expr (IL1_EIf e1 e2 e3, s) v) /\

    (!e1 e2 e3 s v.
        (bs_il1_expr (e1, s) (IL1_Boolean F) /\
         bs_il1_expr (e3, s) v)
     ==> bs_il1_expr (IL1_EIf e1 e2 e3, s) v)`;

val bs_il1_expr_sinduction = derive_strong_induction(bs_il1_expr_rules, bs_il1_expr_induction);

val BS_IL1_EXPR_PLUS_BACK_THM = store_thm("BS_IL1_EXPR_PLUS_BACK_THM",
``!e1 e2 s v.bs_il1_expr (IL1_Plus e1 e2, s) v ==> ?n1 n2.bs_il1_expr (e1, s) (IL1_Integer n1) /\ bs_il1_expr (e2, s) (IL1_Integer n2) /\ (v = IL1_Integer (n1 + n2))``,
rw [Once bs_il1_expr_cases] THEN metis_tac []);

val BS_IL1_EXPR_GEQ_BACK_THM = store_thm("BS_IL1_EXPR_GEQ_BACK_THM",
``!e1 e2 s v.bs_il1_expr (IL1_Geq e1 e2, s) v ==> ?n1 n2.bs_il1_expr (e1, s) (IL1_Integer n1) /\ bs_il1_expr (e2, s) (IL1_Integer n2) /\ (v = IL1_Boolean (n1 >= n2))``,
rw [Once bs_il1_expr_cases] THEN metis_tac []);

val BS_IL1_EXPR_DEREF_BACK_THM = store_thm("BS_IL1_EXPR_DEREF_BACK_THM",
``!l s v.bs_il1_expr (IL1_Deref l, s) v ==> l ∈ FDOM s /\ (v = IL1_Integer (s ' l))``,
rw [Once bs_il1_expr_cases] THEN metis_tac []);

val BS_IL1_EXPR_EIF_BACK_THM = store_thm("BS_IL1_EXPR_EIF_BACK_THM",
``!e1 e2 e3 s v.bs_il1_expr (IL1_EIf e1 e2 e3, s) v ==> (bs_il1_expr (e1, s) (IL1_Boolean T) /\ bs_il1_expr (e2, s) v) \/ (bs_il1_expr (e1, s) (IL1_Boolean F) /\ bs_il1_expr (e3, s) v)``,
rw [Once bs_il1_expr_cases] THEN metis_tac []);

val BS_IL1_EXPR_DETERMINACY = store_thm("BS_IL1_EXPR_DETERMINACY",
``!p v1.bs_il1_expr p v1 ==> !v2.bs_il1_expr p v2 ==> (v1 = v2)``,
ho_match_mp_tac bs_il1_expr_sinduction THEN rw []
THEN1 (Cases_on `v1` THEN Cases_on `v2` THEN fs [Once bs_il1_expr_cases])
THEN1 (imp_res_tac BS_IL1_EXPR_PLUS_BACK_THM THEN res_tac THEN rw [])
THEN1 (imp_res_tac BS_IL1_EXPR_GEQ_BACK_THM THEN res_tac THEN rw [])
THEN1 (imp_res_tac BS_IL1_EXPR_DEREF_BACK_THM THEN rw [])
THEN1 (imp_res_tac BS_IL1_EXPR_EIF_BACK_THM THEN res_tac THEN rw [])
THEN1 (imp_res_tac BS_IL1_EXPR_EIF_BACK_THM THEN res_tac THEN rw []));

val (bs_il1_rules, bs_il1_induction, bs_il1_cases) = Hol_reln `
    (*  Expressions *)
    (!e v s.
        bs_il1_expr (e, s) v
    ==> bs_il1 (IL1_Expr e, s) v s) /\

    (* Assign *)
    (!l e s n.
       (User l ∈ FDOM s /\
        bs_il1_expr (e, s) (IL1_Integer n))
    ==> bs_il1 (IL1_Assign (User l) e, s) IL1_ESkip (s |+ (User l, n))) /\

    (!l e s n.
        bs_il1_expr (e, s) (IL1_Integer n)
    ==> bs_il1 (IL1_Assign (Compiler l) e, s) IL1_ESkip (s |+ (Compiler l, n))) /\

    (* Seq *)
    (!e1 e2 v s s' s''.
        (bs_il1 (e1, s) IL1_ESkip s' /\
         bs_il1 (e2, s') v s'')
     ==> bs_il1 (IL1_Seq e1 e2, s) v s'') /\

    (* SIf *)
    (!e1 e2 e3 v s s'.
        (bs_il1_expr (e1, s) (IL1_Boolean T) /\
         bs_il1 (e2, s) v s')
     ==> bs_il1 (IL1_SIf e1 e2 e3, s) v s') /\

    (!e1 e2 e3 v s s'.
        (bs_il1_expr (e1, s) (IL1_Boolean F) /\
         bs_il1 (e3, s) v s')
     ==> bs_il1 (IL1_SIf e1 e2 e3, s) v s') /\

    (* While *)
    (!e1 e2 s s' s''.
        (bs_il1_expr (e1, s) (IL1_Boolean T) /\
         bs_il1 (e2, s) IL1_ESkip s' /\
         bs_il1 (IL1_While e1 e2, s') IL1_ESkip s'')
     ==> bs_il1 (IL1_While e1 e2, s) IL1_ESkip s'') /\

    (!e1 e2 s.
       (bs_il1_expr (e1, s) (IL1_Boolean F))
    ==> bs_il1 (IL1_While e1 e2, s) IL1_ESkip s)`;

val bs_il1_sinduction = derive_strong_induction(bs_il1_rules, bs_il1_induction);

val IL1_EXPR_BACK_THM = store_thm("IL1_EXPR_BACK_THM",
``!e v s s'.bs_il1 (IL1_Expr e, s) v s' ==> bs_il1_expr (e, s) v /\ (s = s')``,
rw [Once bs_il1_cases] THEN metis_tac []);

val IL1_SEQ_BACK_THM = store_thm("IL1_SEQ_BACK_THM",
``!e1 e2 v s s''.bs_il1 (IL1_Seq e1 e2, s) v s'' ==> ?s'.bs_il1 (e1, s) IL1_ESkip s' /\ bs_il1 (e2, s') v s''``,
rw [Once bs_il1_cases] THEN metis_tac []);

val IL1_ASSIGN_BACK_THM = store_thm("IL1_ASSIGN_BACK_THM",
``!l e s s' v.bs_il1 (IL1_Assign l e, s) v s' ==> (v = IL1_ESkip) /\ ?n.bs_il1_expr (e, s) (IL1_Integer n) /\ (s' = (s |+ (l, n))) /\ (!l'.(l = User l') ==> l ∈ FDOM s)``,
rw [Once bs_il1_cases] THEN metis_tac []);

val IL1_SIF_BACK_THM = store_thm("IL1_SIF_BACK_THM",
``!e1 e2 e3 s v s'.bs_il1 (IL1_SIf e1 e2 e3, s) v s' ==> (bs_il1_expr (e1, s) (IL1_Boolean T) /\ bs_il1 (e2, s) v s') \/ (bs_il1_expr (e1, s) (IL1_Boolean F) /\ bs_il1 (e3, s) v s')``,
rw [Once bs_il1_cases] THEN metis_tac []);

val IL1_WHILE_BACK_THM = store_thm("IL1_WHILE_BACK_THM",
``!e1 e2 s s'' v.bs_il1 (IL1_While e1 e2, s) v s'' ==> (v = IL1_ESkip) /\ ((bs_il1_expr (e1, s) (IL1_Boolean F) /\ (s = s'')) \/ (bs_il1_expr (e1, s) (IL1_Boolean T) /\ ?s'.bs_il1 (e2, s) IL1_ESkip s' /\ bs_il1 (IL1_While e1 e2, s') IL1_ESkip s''))``,
rw [Once bs_il1_cases] THEN metis_tac []);

val IL1_DETERMINACY_THM = store_thm("IL1_DETERMINACY_THM",
``!p v1 s1.bs_il1 p v1 s1 ==> !v2 s2.bs_il1 p v2 s2 ==> (v1 = v2) /\ (s1 = s2)``,
ho_match_mp_tac (fetch "-" "bs_il1_strongind") THEN rw []

THEN1 (fs [Once bs_il1_cases] THEN metis_tac [BS_IL1_EXPR_DETERMINACY])
THEN1 (fs [Once bs_il1_cases] THEN metis_tac [BS_IL1_EXPR_DETERMINACY])
THEN1 (fs [Once bs_il1_cases] THEN metis_tac [BS_IL1_EXPR_DETERMINACY])

THEN1 (imp_res_tac IL1_ASSIGN_BACK_THM THEN rw [] THEN `IL1_Integer n = IL1_Integer n'` by metis_tac [BS_IL1_EXPR_DETERMINACY] THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_ASSIGN_BACK_THM THEN rw [] THEN `IL1_Integer n = IL1_Integer n'` by metis_tac [BS_IL1_EXPR_DETERMINACY] THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_ASSIGN_BACK_THM THEN rw [] THEN `IL1_Integer n = IL1_Integer n'` by metis_tac [BS_IL1_EXPR_DETERMINACY] THEN rw [] THEN metis_tac [])

THEN1 (imp_res_tac IL1_SEQ_BACK_THM THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_SEQ_BACK_THM THEN rw [] THEN metis_tac [])

THEN1 (imp_res_tac IL1_SIF_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_SIF_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_SIF_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_SIF_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac [])


THEN1 (imp_res_tac IL1_WHILE_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_WHILE_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_WHILE_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac [])
THEN1 (imp_res_tac IL1_WHILE_BACK_THM THEN rw [] THEN imp_res_tac BS_IL1_EXPR_DETERMINACY THEN rw [] THEN metis_tac []));

val _ = export_theory ();
