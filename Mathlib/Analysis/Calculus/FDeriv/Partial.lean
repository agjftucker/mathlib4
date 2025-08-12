/-
Copyright (c) 2025 A Tucker. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: A Tucker
-/
import Mathlib.Analysis.Calculus.MeanValue

/-!
# Partial derivatives

Results in this file relate the partial derivatives of a bivariate function to its differentiability
in the product space.

## Main statements

* `hasStrictFDerivAt_uncurry_coprod`: establishing strict differentiability at a point `x` in the
  product space, this requires that both partial derivatives exist in a neighbourhood of `x` and be
  continuous at `x`.
-/

open Asymptotics Filter
open scoped Convex Topology

section aux

variable {E F : Type*} [TopologicalSpace E] [NormedAddCommGroup F] [NormedSpace ℝ F]
variable {s : Set E} {t : Set F} {ξ : E} {x : F} {y z : E → F}

theorem eventually_segment {r : E → F → Prop}
    (hy : Tendsto y (𝓝[s] ξ) (𝓝 x)) (hz : Tendsto z (𝓝[s] ξ) (𝓝 x))
    (seg : ∀ᶠ χ in 𝓝[s] ξ, [z χ -[ℝ] y χ] ⊆ t) (hr : ∀ᶠ p in 𝓝[s ×ˢ t] (ξ, x), r p.1 p.2) :
    ∀ᶠ χ in 𝓝[s] ξ, ∀ v ∈ [z χ -[ℝ] y χ], r χ v := by
  rw [nhdsWithin_prod_eq, eventually_prod_iff] at hr
  obtain ⟨p, hp, q, hq, hr⟩ := hr
  rw [eventually_iff, Metric.mem_nhdsWithin_iff] at hq
  obtain ⟨δ, hδ, hq⟩ := hq
  rw [Metric.tendsto_nhds] at hy hz
  filter_upwards [hp, hy δ hδ, hz δ hδ, seg] with χ hp hy hz seg
  have := convex_iff_segment_subset.mp (convex_ball x δ) hz hy
  exact fun v hv => hr hp <| hq ⟨this hv, seg hv⟩

variable {𝕜 G : Type*} [NontriviallyNormedField 𝕜] [IsRCLikeNormedField 𝕜]
variable [NormedSpace 𝕜 F] [NormedAddCommGroup G] [NormedSpace 𝕜 G]

theorem isLittleO_sub_sub_fderiv {f : E → F → G} {f' : E → F → F →L[𝕜] G}
    (hy : Tendsto y (𝓝[s] ξ) (𝓝 x)) (hz : Tendsto z (𝓝[s] ξ) (𝓝 x))
    (seg : ∀ᶠ χ in 𝓝[s] ξ, [z χ -[ℝ] y χ] ⊆ t) (cf' : ContinuousWithinAt ↿f' (s ×ˢ t) (ξ, x))
    (df' : ∀ᶠ p in 𝓝[s ×ˢ t] (ξ, x), HasFDerivWithinAt (f p.1) (f' p.1 p.2) t p.2) :
    (fun χ => f χ (y χ) - f χ (z χ) - f' ξ x (y χ - z χ)) =o[𝓝[s] ξ] (fun χ => y χ - z χ) := by
  rw [isLittleO_iff]
  intro ε hε
  replace cf' : ∀ᶠ χ in 𝓝[s] ξ, ∀ v ∈ [z χ -[ℝ] y χ], dist (f' χ v) (f' ξ x) < ε := by
    rw [Metric.continuousWithinAt_iff'] at cf'
    exact eventually_segment hy hz seg (cf' ε hε)
  replace df' : ∀ᶠ χ in 𝓝[s] ξ, ∀ v ∈ [z χ -[ℝ] y χ], HasFDerivWithinAt (f χ) (f' χ v) t v :=
    eventually_segment hy hz seg df'
  filter_upwards [seg, cf', df'] with χ seg cf' df'
  exact Convex.norm_image_sub_le_of_norm_hasFDerivWithin_le'
    (fun v hv => (df' v hv).mono seg) (fun v hv => (cf' v hv).le)
    (convex_segment ..) (left_mem_segment ..) (right_mem_segment ..)

end aux

variable {𝕜 E₁ E₂ F : Type*} [NontriviallyNormedField 𝕜] [NormedAddCommGroup E₁] [NormedSpace 𝕜 E₁]
  [NormedAddCommGroup E₂] [NormedSpace 𝕜 E₂] [NormedAddCommGroup F] [NormedSpace 𝕜 F]

/-- If a bivariate function `f` has partial derivatives `f₁` and `f₂` in a neighbourhood of a point
`(x₁, x₂)` and if they are continuous at that point then the uncurried function `↿f` is strictly
differentiable there with its derivative mapping `(h₁, h₂)` to `f₁ x₁ x₂ h₁ + f₂ x₁ x₂ h₂`. -/
theorem hasStrictFDerivAt_uncurry_coprod
    [IsRCLikeNormedField 𝕜] {f : E₁ → E₂ → F} {x₁ : E₁} {x₂ : E₂}
    {f₁ : E₁ → E₂ → E₁ →L[𝕜] F} (cf₁ : ContinuousAt ↿f₁ (x₁, x₂))
    (df₁ : ∀ᶠ y in 𝓝 (x₁, x₂), HasFDerivAt (f · y.2) (f₁ y.1 y.2) y.1)
    {f₂ : E₁ → E₂ → E₂ →L[𝕜] F} (cf₂ : ContinuousAt ↿f₂ (x₁, x₂))
    (df₂ : ∀ᶠ y in 𝓝 (x₁, x₂), HasFDerivAt (f y.1 ·) (f₂ y.1 y.2) y.2) :
    HasStrictFDerivAt ↿f ((f₁ x₁ x₂).coprod (f₂ x₁ x₂)) (x₁, x₂) := by
  unfold ContinuousAt at cf₁ cf₂
  rw [nhds_prod_eq] at cf₁ cf₂ df₁ df₂
  rw [hasStrictFDerivAt_iff_isLittleO]
  calc
    fun (y, z) => f y.1 y.2 - f z.1 z.2 - ((f₁ x₁ x₂).coprod (f₂ x₁ x₂)) (y - z)
    _ = fun (y, z) => (f y.1 z.2 - f z.1 z.2 - f₁ x₁ x₂ (y.1 - z.1))
          + (f y.1 y.2 - f y.1 z.2 - f₂ x₁ x₂ (y.2 - z.2)) := by
      ext
      dsimp only [ContinuousLinearMap.coprod_apply]
      abel
    _ =o[𝓝 ((x₁, x₂), (x₁, x₂))] fun (y, z) => y - z := by
      let : RCLike 𝕜 := IsRCLikeNormedField.rclike 𝕜
      apply IsLittleO.add
      · calc
          fun (y, z) => f y.1 z.2 - f z.1 z.2 - f₁ x₁ x₂ (y.1 - z.1)
          _ =o[𝓝 ((x₁, x₂), (x₁, x₂))] (fun (y, z) => y.1 - z.1 : _ → E₁) := by
            rw [← nhdsWithin_univ]
            have h := tendsto_snd.prodMk <| tendsto_snd.comp <| tendsto_snd.comp <|
              tendsto_fst (f := (𝓝 x₁ ×ˢ 𝓝 x₂) ×ˢ (𝓝 x₁ ×ˢ 𝓝 x₂)) (g := 𝓝 x₁)
            let : NormedSpace ℝ E₁ := RestrictScalars.normedSpace ℝ 𝕜 E₁
            apply isLittleO_sub_sub_fderiv (E := (E₁ × E₂) × (E₁ × E₂))
              (t := Set.univ) (f := fun (y, z) u => f u z.2) (f' := fun (y, z) u => f₁ u z.2)
            · simpa [nhds_prod_eq] using tendsto_fst.comp tendsto_fst
            · simpa [nhds_prod_eq] using tendsto_fst.comp tendsto_snd
            · simp
            · simpa [continuousWithinAt_univ, ContinuousAt, nhds_prod_eq] using cf₁.comp h
            · simpa [nhds_prod_eq] using h.eventually df₁
          _ =O[𝓝 ((x₁, x₂), (x₁, x₂))] (fun (y, z) => y - z : _ → E₁ × E₂) := by
            simp [isBigO_of_le]
      · calc
          fun (y, z) => f y.1 y.2 - f y.1 z.2 - f₂ x₁ x₂ (y.2 - z.2)
          _ =o[𝓝 ((x₁, x₂), (x₁, x₂))] (fun (y, z) => y.2 - z.2 : _ → E₂) := by
            rw [← nhdsWithin_univ]
            have h := (tendsto_fst.comp <| tendsto_fst.comp tendsto_fst).prodMk <|
              tendsto_snd (f := (𝓝 x₁ ×ˢ 𝓝 x₂) ×ˢ (𝓝 x₁ ×ˢ 𝓝 x₂)) (g := 𝓝 x₂)
            let : NormedSpace ℝ E₂ := RestrictScalars.normedSpace ℝ 𝕜 E₂
            apply isLittleO_sub_sub_fderiv (E := (E₁ × E₂) × (E₁ × E₂))
              (t := Set.univ) (f := fun (y, z) v => f y.1 v) (f' := fun (y, z) v => f₂ y.1 v)
            · simpa [nhds_prod_eq] using tendsto_snd.comp tendsto_fst
            · simpa [nhds_prod_eq] using tendsto_snd.comp tendsto_snd
            · simp
            · simpa [continuousWithinAt_univ, ContinuousAt, nhds_prod_eq] using cf₂.comp h
            · simpa [nhds_prod_eq] using h.eventually df₂
          _ =O[𝓝 ((x₁, x₂), (x₁, x₂))] (fun (y, z) => y - z : _ → E₁ × E₂) := by
            simp [isBigO_of_le]
