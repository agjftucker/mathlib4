/-
Copyright (c) 2025 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel
-/
import Mathlib.Geometry.Manifold.Riemannian.PathELength
import Mathlib.Geometry.Manifold.VectorBundle.Riemannian
import Mathlib.Geometry.Manifold.VectorBundle.Tangent
import Mathlib.MeasureTheory.Integral.IntervalIntegral.ContDiff

/-! # Riemannian manifolds

A Riemannian manifold `M` is a real manifold such that its tangent spaces are endowed with an
inner product, depending smoothly on the point, and such that `M` has an emetric space
structure for which the distance is the infimum of lengths of paths. -/

open Bundle Bornology Set MeasureTheory Manifold
open scoped ENNReal ContDiff Topology

local notation "⟪" x ", " y "⟫" => inner ℝ x y

noncomputable section

variable
  {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {H : Type*} [TopologicalSpace H] {I : ModelWithCorners ℝ E H} {n : WithTop ℕ∞}
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M]

section

variable [EMetricSpace M] [ChartedSpace H M] [RiemannianBundle (fun (x : M) ↦ TangentSpace I x)]

variable (I M) in
/-- Consider a manifold in which the tangent spaces are already endowed with an inner product, and
the space is already endowed with an extended distance. We say that this is a Riemannian manifold
if the distance is given by the infimum of the lengths of `C^1` paths, measured using the norm in
the tangent spaces.

This is a `Prop` valued typeclass, on top of existing data. -/
class IsRiemannianManifold : Prop where
  out (x y : M) : edist x y = riemannianEDist I x y

end

section

variable {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]

variable (F) in
/-- The standard riemannian metric on a vector space with an inner product, given by this inner
product on each tangent space. -/
noncomputable def riemannianMetricVectorSpace :
    ContMDiffRiemannianMetric 𝓘(ℝ, F) ω F (fun (x : F) ↦ TangentSpace 𝓘(ℝ, F) x) where
  inner x := (innerSL ℝ (E := F) : F →L[ℝ] F →L[ℝ] ℝ)
  symm x v w := real_inner_comm  _ _
  pos x v hv := real_inner_self_pos.2 hv
  isVonNBounded x := by
    change IsVonNBounded ℝ {v : F | ⟪v, v⟫ < 1}
    have : Metric.ball (0 : F) 1 = {v : F | ⟪v, v⟫ < 1} := by
      ext v
      simp only [Metric.mem_ball, dist_zero_right, norm_eq_sqrt_re_inner (𝕜 := ℝ),
        RCLike.re_to_real, Set.mem_setOf_eq]
      conv_lhs => rw [show (1 : ℝ) = √ 1 by simp]
      rw [Real.sqrt_lt_sqrt_iff]
      exact real_inner_self_nonneg
    rw [← this]
    exact NormedSpace.isVonNBounded_ball ℝ F 1
  contMDiff := by
    intro x
    rw [contMDiffAt_section]
    convert contMDiffAt_const (c := innerSL ℝ)
    ext v w
    simp? [hom_trivializationAt_apply, ContinuousLinearMap.inCoordinates,
        Trivialization.linearMapAt_apply] says
      simp only [hom_trivializationAt_apply, ContinuousLinearMap.inCoordinates,
        TangentBundle.symmL_model_space, ContinuousLinearMap.coe_comp',
        Trivialization.continuousLinearMapAt_apply, Function.comp_apply,
        Trivialization.linearMapAt_apply, hom_trivializationAt_baseSet,
        TangentBundle.trivializationAt_baseSet, PartialHomeomorph.refl_partialEquiv,
        PartialEquiv.refl_source, PartialHomeomorph.singletonChartedSpace_chartAt_eq,
        Trivial.fiberBundle_trivializationAt', Trivial.trivialization_baseSet, inter_self, mem_univ,
        ↓reduceIte, Trivial.trivialization_apply]
    rfl

noncomputable instance : RiemannianBundle (fun (x : F) ↦ TangentSpace 𝓘(ℝ, F) x) :=
  ⟨(riemannianMetricVectorSpace F).toRiemannianMetric⟩

set_option synthInstance.maxHeartbeats 30000 in
-- otherwise, the instance is not found!
lemma norm_tangentSpace_vectorSpace {x : F} {v : TangentSpace 𝓘(ℝ, F) x} :
    ‖v‖ = ‖show F from v‖ := by
  rw [norm_eq_sqrt_real_inner, norm_eq_sqrt_real_inner]

set_option synthInstance.maxHeartbeats 30000 in
-- otherwise, the instance is not found!
lemma nnnorm_tangentSpace_vectorSpace {x : F} {v : TangentSpace 𝓘(ℝ, F) x} :
    ‖v‖₊ = ‖show F from v‖₊ := by
  simp [nnnorm, norm_tangentSpace_vectorSpace]

lemma enorm_tangentSpace_vectorSpace {x : F} {v : TangentSpace 𝓘(ℝ, F) x} :
    ‖v‖ₑ = ‖show F from v‖ₑ := by
  simp [enorm, nnnorm_tangentSpace_vectorSpace]

open MeasureTheory Measure

/-- An inner product vector space is a Riemannian manifold, i.e., the distance between two points
is the infimum of the lengths of paths between these points. -/
instance : IsRiemannianManifold 𝓘(ℝ, F) F := by
  refine ⟨fun x y ↦ le_antisymm ?_ ?_⟩
  · simp only [riemannianEDist, le_iInf_iff]
    intro γ hγ
    let e : ℝ → F := γ ∘ (projIcc 0 1 zero_le_one)
    have D : ContDiffOn ℝ 1 e (Icc 0 1) :=
      contMDiffOn_iff_contDiffOn.mp (hγ.comp_contMDiffOn contMDiffOn_projIcc)
    rw [lintegral_norm_mfderiv_Icc_eq_pathELength_projIcc,
      pathELength_eq_lintegral_mfderivWithin_Icc]
    simp only [mfderivWithin_eq_fderivWithin, enorm_tangentSpace_vectorSpace]
    conv_lhs =>
      rw [edist_comm, edist_eq_enorm_sub, show x = e 0 by simp [e], show y = e 1 by simp [e]]
    exact (enorm_sub_le_lintegral_derivWithin_Icc_of_contDiffOn_Icc D zero_le_one).trans_eq rfl
  · let γ := ContinuousAffineMap.lineMap (R := ℝ) x y
    have : riemannianEDist 𝓘(ℝ, F) x y ≤ pathELength 𝓘(ℝ, F) γ 0 1 := by
      apply riemannianEDist_le_pathELength ?_ (by simp [γ, ContinuousAffineMap.coe_lineMap_eq])
        (by simp [γ, ContinuousAffineMap.coe_lineMap_eq]) zero_le_one
      rw [contMDiffOn_iff_contDiffOn]
      exact γ.contDiff.contDiffOn
    apply this.trans_eq
    rw [pathELength_eq_lintegral_mfderiv_Ioo]
    simp only [mfderiv_eq_fderiv, enorm_tangentSpace_vectorSpace]
    have : edist x y = ∫⁻ (x_1 : ℝ) in Ioo 0 1, ‖y - x‖ₑ := by
      simp [edist_comm x y, edist_eq_enorm_sub]
    rw [this]
    apply lintegral_congr (fun z ↦ ?_)
    rw [show y - x = fderiv ℝ (ContinuousAffineMap.lineMap (R := ℝ) x y) z 1 by simp]
    rfl

end

open Manifold Metric
open scoped NNReal

variable [RiemannianBundle (fun (x : M) ↦ TangentSpace I x)]
[IsManifold I 1 M]
[IsContinuousRiemannianBundle E (fun (x : M) ↦ TangentSpace I x)]

attribute [local instance 2000]
  Bundle.instNormedAddCommGroupOfRiemannianBundle Bundle.instInnerProductSpaceReal

--set_option trace.profiler true in
variable (I) in
lemma bloops (x : M) : ∃ C > 0, ∀ᶠ y in 𝓝 x,
    ‖mfderiv I 𝓘(ℝ, E) (extChartAt I x) y‖ < C := by
  rcases eventually_norm_trivializationAt_lt E (fun (x : M) ↦ TangentSpace I x) x
    with ⟨C, C_pos, hC⟩
  refine ⟨C, C_pos, ?_⟩
  filter_upwards [hC] with y hy
  convert hy


#exit


set_option trace.profiler true in
variable (I) in
lemma bloo (x : M) : ∃ (C : ℝ≥0), 0 < C ∧ ∀ᶠ y in 𝓝[range I] (extChartAt I x x),
    ‖mfderivWithin 𝓘(ℝ, E) I (extChartAt I x).symm (range I) y‖ < C := sorry

#exit

variable (I) in
lemma blok (x : M) : ∃ (C : ℝ≥0), 0 < C ∧ ∀ᶠ y in 𝓝 x,
    riemannianEDist I x y ≤ C * edist (extChartAt I x x) (extChartAt I x y) := sorry
/-
  let γ (y : M) (t : ℝ) : M :=
    (extChartAt I x).symm
    (ContinuousAffineMap.lineMap (extChartAt I x x) (extChartAt I x y) t)
  obtain ⟨r, r_pos, hr⟩ : ∃ r > 0,
      ball (extChartAt I x x) r ∩ range I ⊆ (extChartAt I x).target := by
    have : (extChartAt I x).target ∈ 𝓝[range I] (extChartAt I x x) :=
      extChartAt_target_mem_nhdsWithin x
    sorry
  let f : TangentSpace I x →L[ℝ] E := mfderiv I 𝓘(ℝ, E) (extChartAt I x) x
  have A (v) : ‖f v‖ ≤ ‖f‖ * ‖v‖ := by
    apply ContinuousLinearMap.le_opNorm
-/

lemma foo (x : M) {c : ℝ≥0∞} (hc : 0 < c) : ∀ᶠ y in 𝓝 x, riemannianEDist I x y < c := by
  rcases blok I x with ⟨C, C_pos, hC⟩
  have : (extChartAt I x) ⁻¹' (EMetric.ball (extChartAt I x x) (c / C)) ∈ 𝓝 x := by
    apply (continuousAt_extChartAt x).preimage_mem_nhds
    exact EMetric.ball_mem_nhds _ (ENNReal.div_pos hc.ne' (by simp))
  filter_upwards [this, hC] with y hy h'y
  apply h'y.trans_lt
  have : edist (extChartAt I x x) (extChartAt I x y) < c / C := by
    simpa only [mem_preimage, EMetric.mem_ball'] using hy
  rwa [ENNReal.lt_div_iff_mul_lt, mul_comm] at this
  · exact Or.inl (mod_cast C_pos.ne')
  · simp
