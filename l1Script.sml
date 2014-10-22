open HolKernel boolLib bossLib wordsTheory wordsLib listTheory Parse IndDefLib finite_mapTheory;

val _ = new_theory "l1";

val _ = numLib.prefer_num();
val _ = wordsLib.prefer_word();

val _ = type_abbrev("loc", ``:word24``);

val _ = type_abbrev("int", ``:word16``);

val _ = type_abbrev("state", ``:loc |-> int``);

val _ = type_abbrev("pred", ``:state -> bool``);

val _ = Hol_datatype `exp = N of int
                        | B of bool
                        | Plus of exp => exp
                        | Geq of exp => exp
                        | If of exp => exp => exp
                        | Assign of loc => exp
                        | Deref of loc
                        | Skip
                        | Seq of exp => exp
                        | While of exp => exp`;

val (ss_rules, ss_induction, ss_ecases) = Hol_reln `
    (* Plus *)
    (!n1 n2 s.small_step (Plus (N n1) (N n2), s) (N (n1 + n2), s)) /\
    (!e1 e1' e2 s s'.
          small_step (e1, s) (e1', s')
      ==> small_step (Plus e1 e2, s) (Plus e1' e2, s')) /\
    (!n e2 e2' s s'.
          small_step (e2, s) (e2', s')
      ==> small_step (Plus (N n) e2, s) (Plus (N n) e2', s')) /\

    (* Geq *)
    (!n1 n2 s.small_step (Geq (N n1) (N n2), s) (B (n1 >= n2), s)) /\
    (!e1 e1' e2 s s'.
          small_step (e1, s) (e1', s')
      ==> small_step (Geq e1 e2, s) (Geq e1' e2, s')) /\
    (!n e2 e2' s s'.
          small_step (e2, s) (e2', s')
      ==> small_step (Geq (N n) e2, s) (Geq (N n) e2', s)) /\

    (* Deref *)
    (!l s.
          l ∈ FDOM s
      ==> small_step (Deref(l), s) (N (s ' l), s)) /\

    (* Assign *)
    (!l n s.
          l ∈ FDOM s
      ==> small_step (Assign l (N n), s) (Skip, s |+ (l, n))) /\
    (!l e e' s s'.
          small_step (e, s) (e', s')
      ==> small_step (Assign l e, s) (Assign l e', s')) /\

    (* Seq *)
    (!e2 s.small_step (Seq Skip e2, s) (e2, s)) /\
    (!e1 e1' e2 s s'.
          small_step (e1, s) (e1', s')
      ==> small_step (Seq e1 e2, s) (Seq e1' e2, s')) /\

    (* If *)
    (!e2 e3 s. small_step (If (B T) e2 e3, s) (e2, s)) /\
    (!e2 e3 s. small_step (If (B F) e2 e3, s) (e3, s)) /\
    (!e1 e1' e2 e3 s s'.
          small_step (e1, s) (e1', s')
      ==> small_step (If e1 e2 e3, s) (If e1' e2 e3, s')) /\

    (* While *)
    (!e1 e2 s. small_step (While e1 e2, s) (If e1 (Seq e2 (While e1 e2)) Skip, s))`;

val sinduction = derive_strong_induction(ss_rules, ss_induction);

val ss_rulel = CONJUNCTS ss_rules;

val _ = Hol_datatype `T = intL1 | boolL1 | unitL1`;

val _ = Hol_datatype `LT = intrefL1`;

val (type_rules, type_induction, type_ecases) = Hol_reln `
    (!n.type (N n) intL1) /\
    (!b.type (B b) boolL1) /\
    (!e1 e2.(type e1 intL1 /\ type e2 intL1) ==> type (Plus e1 e2) intL1) /\
    (!e1 e2.(type e1 intL1 /\ type e2 intL1) ==> type (Geq e1 e2) boolL1) /\
    (!e1 e2 e3 T.(type e1 boolL1 /\ type e2 T /\ type e3 T) ==> type (If e1 e2 e3) T) /\
    (!l e.type e intL1 ==> type (Assign l e) unitL1) /\
    (!l .type (Deref l) intL1) /\
    (type Skip unitL1) /\
    (!e1 e2 T.type e1 unitL1 /\ type e2 T ==> type (Seq e1 e2) T) /\
    (!e1 e2. type e1 boolL1 /\ type e2 unitL1 ==> type (While e1 e2) unitL1)`;

val value_def = Define `(value (N _) = T) /\
                        (value (B _) = T) /\
                        (value Skip = T) /\
                        (value _ = F)`;

val (star_rules, star_induction, star_ecases) = Hol_reln `
(!x. star r x x) /\
(!x y z.(r x y ==> star r y z) ==> star r x z)`


val STAR_TRANS_THM = store_thm("STAR_TRANS_THM",
``!r x y z. star r x y ==> star r y z ==> star r x z``,
METIS_TAC [star_ecases]);

val evals_def = Define `evals x y = star small_step x y`;

val STUCK_ON_VALUE_THM = store_thm("STUCK_ON_VALUE_THM",
    ``!e s c.value e ==> ~small_step (e, s) c``,
        REPEAT STRIP_TAC THEN Cases_on `e` THENL [
            FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases],
            FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases],
            `~value (Plus e' e0)` by EVAL_TAC,
            `~value (Geq e' e0)` by EVAL_TAC,
            `~value (If e' e0 e1)` by EVAL_TAC,
            `~value (Assign c' e')` by EVAL_TAC,
            `~value (Deref c')` by EVAL_TAC,
            FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases],
            `~value (Seq e' e0)` by EVAL_TAC,
            `~value (While e' e0)` by EVAL_TAC]);

val PLUS_THM = store_thm("PLUS_THM",
    ``!n1 n2 n s s'.small_step (Plus (N n1) (N n2), s) ((N n), s') ==> ((n = n1 + n2) /\ (s=s'))``,
    REPEAT STRIP_TAC THEN
    FULL_SIMP_TAC std_ss [Once ss_ecases]
    THENL (List.tabulate (22, (fn x => FULL_SIMP_TAC (srw_ss ()) []))));

val PLUS2_THM = store_thm("PLUS2_THM",
    ``!n1 n2 e s s'. small_step (Plus (N n1) (N n2), s) (e, s') ==> ?n.(e = (N n))``,
    RW_TAC std_ss [Once ss_ecases] THENL
    [`value (N n1)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM],
     `value (N n2)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM]]);

val PLUS3_THM = store_thm("PLUS3_THM",
    ``!n1 n2 e s s'.small_step (Plus (N n1) (N n2), s) (e, s') ==> (s = s')``,
    RW_TAC std_ss [Once ss_ecases] THENL
    [`value (N n1)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM],
     `value (N n2)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM]]);

val PLUS4_THM = store_thm("PLUS4_THM",
``!e1 e2 n s s'.small_step (Plus e1 e2, s) ((N n), s') ==> ?n1 n2.((e1 = (N n1)) /\ (e2 = (N n2)))``,
RW_TAC std_ss [Once ss_ecases]);

val PLUS5_THM = store_thm("PLUS5_THM",
``!e1 e1' e2 n s s' s2.small_step (e1, s) (e1', s') ==> ~small_step (Plus e1 e2, s) (N n, s2)``,
RW_TAC std_ss [Once ss_ecases] THEN REPEAT (FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases]));

val PLUS5_2_THM = store_thm("PLUS5_THM",
``!e1 e1' e2 n s s' s2.small_step (e1, s) (e1', s') ==> ~small_step (Plus e2 e1, s) (N n, s2)``,
RW_TAC std_ss [Once ss_ecases] THEN REPEAT (FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases]));

val PLUS6_THM = store_thm("PLUS6_THM",
``!e1 e1' e2 s s'.small_step (e1, s) (e1', s') ==> small_step (Plus e1 e2, s) (Plus e1' e2, s')``,
METIS_TAC ss_rulel);

val PLUS_BAD_VALUE_THM = store_thm("ADD_BAD_VALUE_THM",
``!e1 e2 s e s'.small_step (Plus e1 e2, s) (e, s') ==> ~?b.(e1 = B b) /\ ~(e1 = Skip)``,
Cases_on `e1` THENL
(RW_TAC (srw_ss ()) [Once ss_ecases])
::(RW_TAC (srw_ss ()) [Once ss_ecases] THEN `value (B b)` by EVAL_TAC THEN
METIS_TAC [STUCK_ON_VALUE_THM])
::List.tabulate (8, (fn x => FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases])));


val PLUS7_THM = store_thm("PLUS7_THM",
``!n e' s e2 s2.small_step (Plus (N n) e',s) (e2,s2) ==> ((!n'.e' <> N n') ==> (?e''.small_step (e', s) (e'', s2)))``,
RW_TAC (srw_ss ()) [EQ_IMP_THM, Once ss_ecases] THENL[`value (N n)` by EVAL_TAC THEN
METIS_TAC [STUCK_ON_VALUE_THM],
METIS_TAC []]);

val PLUS8_THM = store_thm("PLUS8_THM",
``!n e2 e2' s s'.small_step (e2, s) (e2', s') ==> small_step (Plus (N n) e2, s) (Plus (N n) e2', s')``,
METIS_TAC ss_rulel);

val PLUS9_THM = store_thm("PLUS9_THM",
``!e1 e2 e s s'.(small_step (Plus e1 e2, s) (e, s')) ==> ((?n.e = (N n)) \/ (?e1' e2'.e = (Plus e1' e2')))``,
RW_TAC (srw_ss ()) [EQ_IMP_THM, Once ss_ecases]);

val PLUS_E2_IFF_THM = store_thm("PLUS_E2_IFF_THM",
``!e1 e1' s s'.(?n.small_step (Plus (N n) e1, s) (Plus (N n) e1', s')) <=> small_step (e1, s) (e1', s')``,
RW_TAC (srw_ss ()) [EQ_IMP_THM, Once ss_ecases] THENL [`value (N n)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM], METIS_TAC ss_rulel]);

fun repeat n x = List.tabulate (n, fn n => x);

val OP_PLUS_RULE_THM = store_thm("OP_PLUS_RULE_THM",
    ``!n1 n2 s p3.(small_step (Plus (N n1) (N n2), s) p3) ==> ((N (n1 + n2),s) = p3)``,
    (REPEAT STRIP_TAC)
        THEN (Cases_on `p3`)
        THEN ASM_SIMP_TAC std_ss []
        THEN REPEAT STRIP_TAC
        THEN (Cases_on `q`)
        THENL [METIS_TAC [PLUS_THM], 
               FULL_SIMP_TAC (srw_ss()) [Once ss_ecases],
               FULL_SIMP_TAC (srw_ss()) [Once ss_ecases] THENL [
                   (`value (N n1)` by EVAL_TAC) THEN METIS_TAC [STUCK_ON_VALUE_THM],
                   (`value (N n2)` by EVAL_TAC) THEN METIS_TAC [STUCK_ON_VALUE_THM]]]
               @(repeat 9 (FULL_SIMP_TAC (srw_ss()) [Once ss_ecases]))@
               [FULL_SIMP_TAC (srw_ss()) [Once ss_ecases] THENL [
                   (`value (N n1)` by EVAL_TAC) THEN METIS_TAC [STUCK_ON_VALUE_THM],
                   (`value (N n2)` by EVAL_TAC) THEN METIS_TAC [STUCK_ON_VALUE_THM]]]@
               (repeat 7 (FULL_SIMP_TAC (srw_ss()) [Once ss_ecases])));

val PLUS_STEP_DET_THM = store_thm("PLUS_STEP_DET_THM",
``!e1 e2 e1' e2' s s'.small_step (Plus e1 e2, s) (Plus e1' e2', s') ==> ((e1 = e1') \/ (e2 = e2'))``,
REPEAT STRIP_TAC THEN Cases_on `e1` THENL repeat 10 (FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases]));

val PLUS_STEP_LEFT_THM = store_thm("PLUS_STEP_LEFT_THM",
``!e1 e2 s e1' e2' s'.(!n.e1 <> (N n)) ==> small_step (Plus e1 e2, s) (Plus e1' e2', s') ==> ((e2 = e2') /\ small_step (e1, s) (e1', s'))``,
REPEAT STRIP_TAC THENL [
FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases] THEN METIS_TAC [],
FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases] THEN METIS_TAC []]);

val PLUS_STEP_RIGHT_1_THM = store_thm("PLUS_STEP_RIGHT_1_THM",
``!n1 e2 e1 s e2' s'.small_step (Plus (N n1) e2, s) (Plus e1 e2', s') ==> (small_step (e2, s) (e2', s'))``,
REPEAT STRIP_TAC THEN
FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases] THEN `value (N n1)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM]);


val PLUS_STEP_RIGHT_2_THM = store_thm("PLUS_STEP_RIGHT_2_THM",
``!n1 e2 e1 s e2' s'.small_step (Plus (N n1) e2, s) (Plus e1 e2', s') ==> ~(small_step ((N n1), s) (e1, s'))``,
REPEAT STRIP_TAC THEN `value (N n1)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM]);


val OP_PLUS_RULE1_THM = store_thm("OP_PLUS_RULE1_THM",
``!e1 s e1' s' e2 p3.((small_step (e1, s) (e1', s')) /\ (!p3.small_step (e1, s) p3 ==> ((e1', s') = p3)) /\ (small_step (Plus e1 e2, s) p3)) ==> ((Plus e1' e2, s') = p3)``,
    REPEAT STRIP_TAC THEN
        Cases_on `p3` THEN
        REPEAT STRIP_TAC THEN
        Cases_on `q` THENL[
            METIS_TAC [PLUS5_THM],
            FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases],
            Cases_on `!n.e1 <> (N n)` THENL
                [`((e2 = e0) /\ small_step (e1, s) (e, r))` by METIS_TAC [PLUS_STEP_LEFT_THM] THEN
                     `(e1', s') = (e, r)` by METIS_TAC [] THEN
                      RW_TAC (srw_ss ()) [],
                  `?n.e1 = N n` by METIS_TAC [] THEN
                  `value (N n)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM]]]
             @ (repeat 7 (FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases])));

val VALUE_STEP_THM = store_thm("VALUE_STEP_THM",
``!e1 s e1' r e2 e0. ~small_step (e1, s) (e1', r) ==> small_step (Plus e1 e2, s) (Plus e1' e0, r) ==> value e1``,
    REPEAT STRIP_TAC THEN
        Cases_on `e1` THENL
            (repeat 2 EVAL_TAC) @
            (repeat 5 (FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases])) @
            [EVAL_TAC] @
            (repeat 2 (FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases])));

val PLUS_INT_UNCHANGED_THM = store_thm("PLUS_INT_UNCHANGED_THM",
``!n e2 s e1' e2' s'.small_step(Plus (N n) e2, s) (Plus e1' e2', s') ==> (e1' = N n)``,
    REPEAT STRIP_TAC THEN
        Cases_on `e1'` THENL
	    repeat 10
            (FULL_SIMP_TAC (srw_ss ()) [Once ss_ecases] THEN `value (N n)` by EVAL_TAC THEN METIS_TAC [STUCK_ON_VALUE_THM]));

val _ = export_theory ();