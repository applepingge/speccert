Require Import Coq.Logic.Classical_Prop.

Require Import SpecCert.Address.
Require Import SpecCert.Cache.
Require Import SpecCert.Formalism.
Require Import SpecCert.Interval.
Require Import SpecCert.Memory.
Require Import SpecCert.Smm.Delta.Invariant.
Require Import SpecCert.Smm.Delta.Preserve.Architecture.
Require Import SpecCert.Smm.Software.
Require Import SpecCert.x86.

Lemma read_strat_uc
      (r:  R)
      (pa: PhysicalAddress)
      (v:  Value)
  : partial_preserve (Read r pa v)
                     (fun a => resolve_cache_strategy (proc a) pa = Uncachable)
                     inv.
Proof.
  unfold partial_preserve.
  intros a a' Hinv Hres Hpre Hpost.
  unfold x86_postcondition, read_post in Hpost.
  rewrite Hres in Hpost.
  unfold read_uncachable_post in Hpost.
  rewrite Hpost.
  exact Hinv.
Qed.

Lemma read_strat_sh
      (r:  R)
      (pa: PhysicalAddress)
      (v:  Value)
  : partial_preserve (Read r pa v)
                     (fun a => resolve_cache_strategy (proc a) pa = SmrrHit)
                     inv.
Proof.
  unfold partial_preserve.
  intros a a' Hinv Hres Hpre Hpost.
  unfold x86_postcondition, read_post in Hpost.
  rewrite Hres in Hpost.
  unfold read_smrrhit_post in Hpost.
  rewrite Hpost.
  exact Hinv.
Qed.

Lemma read_strat_smrr_wb
      (r:  R)
      (pa: PhysicalAddress)
      (v:  Value)
    : partial_preserve (Read r pa v)
                       (fun a => is_inside_smrr (proc a) pa
                                 /\ smm_strategy (smrr (proc a)) = WriteBack)
                       inv.
Proof.
  unfold partial_preserve.
  intros a a' Hinv [Hsmrr Hsmm] Hpre Hpost.
  unfold x86_postcondition, read_post, resolve_cache_strategy in Hpost.
  destruct is_inside_smrr_dec; [| intuition ].
  destruct is_in_smm_dec.
  + rewrite Hsmm in Hpost.
    unfold read_writeback_post in Hpost.
    destruct cache_hit_dec.
    * rewrite Hpost.
      exact Hinv.
    * assert (is_inside_smram pa -> is_in_smm (proc a)).
      intro H; exact i0.
      apply (load_in_cache_from_memory_preserves_inv a a' pa Hinv H Hpost).
  + unfold read_smrrhit_post in Hpost.
    rewrite Hpost.
    exact Hinv.
Qed.

Lemma read_strat_not_smrr
      (r:  R)
      (pa: PhysicalAddress)
      (v:  Value)
  : partial_preserve (Read r pa v)
                     (fun a => ~ is_inside_smrr (proc a) pa)
                     inv.
Proof.
  unfold partial_preserve.
  intros a a' Hinv Hnot_smrr Hpre Hpost.
  unfold x86_postcondition, read_post in Hpost.
  unfold resolve_cache_strategy in Hpost.
  destruct is_inside_smrr_dec; [ intuition |].
  case_eq (strategy (proc a)); intro Heqstrat; rewrite Heqstrat in Hpost.
  + unfold read_uncachable_post in Hpost.
    rewrite Hpost.
    exact Hinv.
  + unfold read_writeback_post in Hpost.
    destruct cache_hit_dec.
    * rewrite Hpost; exact Hinv.
    * assert (is_inside_smram pa -> is_in_smm (proc a)).
      intro H.
      destruct Hinv as [Hsmramc [Hsmram [Hsmrr Hclean]]].
      apply Hsmrr in H.
      intuition.
      apply (load_in_cache_from_memory_preserves_inv a a' pa Hinv H Hpost).
  + unfold read_smrrhit_post in Hpost.
    rewrite Hpost.
    exact Hinv.
Qed.

Lemma read_inv
      (r:  R)
      (pa: PhysicalAddress)
      (v:  Value)
  : preserve (Read r pa v) inv.
Proof.
  unfold preserve.
  intros a a' Hinv Hpre Hpost.
  case_eq (resolve_cache_strategy (proc a) pa); intro Heqstrat.
  + apply (read_strat_uc r pa v a a' Hinv Heqstrat Hpre Hpost).
  + destruct (is_inside_smrr_dec (proc a) pa).
    * unfold resolve_cache_strategy in Heqstrat.
      destruct is_inside_smrr_dec; [| intuition ].
      destruct is_in_smm_dec; [| discriminate ].
      assert (is_inside_smrr (proc a) pa /\ smm_strategy (smrr (proc a)) = WriteBack); [
          split; trivial
         |].
      apply (read_strat_smrr_wb r pa v a a' Hinv H Hpre Hpost).
    * apply (read_strat_not_smrr r pa v a a' Hinv n Hpre Hpost).
  + apply (read_strat_sh r pa v a a' Hinv Heqstrat Hpre Hpost).
Qed.