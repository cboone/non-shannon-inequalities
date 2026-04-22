-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import Mathlib.Data.Fin.SuccPred
import NonShannon.Inequality.Vector

namespace NonShannon

/-- A scoped variable relabeling. Inside `[0, variableCount)` it acts by a permutation of `Fin variableCount`; outside that range it acts as the identity. -/
structure VariableRelabeling where
  /-- Declared scope for the relabeling. -/
  variableCount : Nat
  /-- Permutation of the in-range variables. -/
  perm : Equiv.Perm (Fin variableCount)
  deriving DecidableEq

/-- Lifts an arbitrary finite permutation into the scoped relabeling surface. -/
def VariableRelabeling.ofPerm (variableCount : Nat) (perm : Equiv.Perm (Fin variableCount)) :
    VariableRelabeling :=
  { variableCount, perm }

/-- Identity relabeling on `variableCount` variables. -/
def VariableRelabeling.id (variableCount : Nat) : VariableRelabeling :=
  .ofPerm variableCount (Equiv.refl _)

instance : Inhabited VariableRelabeling :=
  ⟨VariableRelabeling.id 0⟩

/-- Transposition on the declared scope, falling back to the identity if either input is out of range. -/
def VariableRelabeling.swap (variableCount i j : Nat) : VariableRelabeling :=
  if hi : i < variableCount then
    if hj : j < variableCount then
      .ofPerm variableCount (Equiv.swap ⟨i, hi⟩ ⟨j, hj⟩)
    else
      .id variableCount
  else
    .id variableCount

/-- Applies a scoped relabeling to one variable index, acting as the identity outside the declared range. -/
def VariableRelabeling.apply (relabeling : VariableRelabeling) (var : Var) : Var :=
  if h : var < relabeling.variableCount then
    relabeling.perm ⟨var, h⟩
  else
    var

instance : CoeFun VariableRelabeling (fun _ => Var → Var) where
  coe := VariableRelabeling.apply

theorem VariableRelabeling.apply_of_lt {relabeling : VariableRelabeling} {var : Var}
    (h : var < relabeling.variableCount) :
    relabeling var = relabeling.perm ⟨var, h⟩ := by
  simp [VariableRelabeling.apply, h]

theorem VariableRelabeling.apply_of_ge {relabeling : VariableRelabeling} {var : Var}
    (h : relabeling.variableCount ≤ var) :
    relabeling var = var := by
  simp [VariableRelabeling.apply, Nat.not_lt.mpr h]

theorem VariableRelabeling.id_apply (variableCount var : Nat) :
    VariableRelabeling.id variableCount var = var := by
  unfold VariableRelabeling.id VariableRelabeling.ofPerm VariableRelabeling.apply
  split <;> simp

/-- Composition of scoped relabelings on a shared scope. When the two scopes agree, the product is the pointwise composition on the common `Fin` type; when they disagree, the product returns the left relabeling as an ill-defined fallback (no in-repo caller triggers that branch). -/
instance : Mul VariableRelabeling where
  mul left right :=
    { variableCount := left.variableCount
      perm :=
        if h : left.variableCount = right.variableCount then
          left.perm * (finCongr h.symm).permCongr right.perm
        else
          left.perm }

theorem VariableRelabeling.mul_variableCount (left right : VariableRelabeling) :
    (left * right).variableCount = left.variableCount := rfl

theorem VariableRelabeling.mul_perm_of_scope_eq {left right : VariableRelabeling}
    (h : left.variableCount = right.variableCount) :
    (left * right).perm = left.perm * (finCongr h.symm).permCongr right.perm := by
  change (if h' : left.variableCount = right.variableCount then _ else _) = _
  rw [dif_pos h]

/-- Pointwise composition of scoped relabelings on a shared scope. -/
theorem VariableRelabeling.mul_apply {left right : VariableRelabeling}
    (h : left.variableCount = right.variableCount) (var : Var) :
    (left * right) var = left (right var) := by
  by_cases hVar : var < right.variableCount
  · have hVarLeft : var < left.variableCount := h ▸ hVar
    have hVarMul : var < (left * right).variableCount := by
      rw [VariableRelabeling.mul_variableCount]; exact hVarLeft
    rw [VariableRelabeling.apply_of_lt hVar, VariableRelabeling.apply_of_lt hVarMul]
    have hRightImageLt : (right.perm ⟨var, hVar⟩).val < left.variableCount := by
      rw [h]; exact (right.perm ⟨var, hVar⟩).isLt
    rw [VariableRelabeling.apply_of_lt hRightImageLt]
    rw [VariableRelabeling.mul_perm_of_scope_eq h]
    rfl
  · rw [not_lt] at hVar
    have hVarLeft : left.variableCount ≤ var := h ▸ hVar
    rw [VariableRelabeling.apply_of_ge hVar, VariableRelabeling.apply_of_ge hVarLeft,
      VariableRelabeling.apply_of_ge (show (left * right).variableCount ≤ var by
        rw [VariableRelabeling.mul_variableCount]; exact hVarLeft)]

/-- Applies a relabeling to one subset and normalizes the result. -/
def actOnSubset (relabeling : VariableRelabeling) (subset : VariableSubset) : VariableSubset :=
  (subset.map relabeling).normalize

/-- Applies a scoped relabeling to a subset via the normalized action. Alias of `actOnSubset` kept so callers can write `relabeling.applySubset subset` when that reads more naturally. -/
def VariableRelabeling.applySubset (relabeling : VariableRelabeling) (subset : VariableSubset) :
    VariableSubset :=
  actOnSubset relabeling subset

/-- Applies a relabeling to one inequality term. -/
def actOnTerm (relabeling : VariableRelabeling) (term : InequalityTerm) : InequalityTerm :=
  { term with subset := actOnSubset relabeling term.subset }

/-- Applies a relabeling termwise to an inequality vector without re-canonicalizing it. The action requires the relabeling scope to match the vector's declared scope so in-range terms stay in range. The scope-equality hypothesis is a type-level constraint on callers only; the body ignores it. -/
@[nolint unusedArguments]
def actOnVector (relabeling : VariableRelabeling) (vector : InequalityVector)
    (_hScope : relabeling.variableCount = vector.variableCount) : InequalityVector :=
  { vector with terms := vector.terms.map (actOnTerm relabeling) }

/-- Applies a scoped relabeling to every term of an inequality vector via the raw action. Alias of `actOnVector` kept so callers can write `relabeling.applyVector vector h` when that reads more naturally. -/
def VariableRelabeling.applyVector (relabeling : VariableRelabeling) (vector : InequalityVector)
    (hScope : relabeling.variableCount = vector.variableCount) :
    InequalityVector :=
  actOnVector relabeling vector hScope

@[simp]
theorem actOnVector_terms (relabeling : VariableRelabeling) (vector : InequalityVector)
    (hScope : relabeling.variableCount = vector.variableCount) :
    (actOnVector relabeling vector hScope).terms = vector.terms.map (actOnTerm relabeling) := rfl

@[simp]
theorem actOnVector_variableCount (relabeling : VariableRelabeling) (vector : InequalityVector)
    (hScope : relabeling.variableCount = vector.variableCount) :
    (actOnVector relabeling vector hScope).variableCount = vector.variableCount := rfl

@[simp]
theorem actOnVector_basis (relabeling : VariableRelabeling) (vector : InequalityVector)
    (hScope : relabeling.variableCount = vector.variableCount) :
    (actOnVector relabeling vector hScope).basis = vector.basis := rfl

/-- Map-then-normalize commutes with normalize-then-map-then-normalize: both sides normalize the same underlying multiset, and uniqueness of normalized forms collapses the extra pass. Consumed by `actOnSubset_mul`. -/
theorem VariableSubset.normalize_map_commute (f : Var → Var) (subset : VariableSubset) :
    (subset.normalize.map f).normalize = (subset.map f).normalize := by
  apply VariableSubset.eq_of_isNormalized_of_mem_iff
  · exact VariableSubset.normalize_isNormalized _
  · exact VariableSubset.normalize_isNormalized _
  intro var
  simp [VariableSubset.map, VariableSubset.mem_normalize, List.mem_map]

/-- The identity relabeling normalizes its argument and does nothing else. -/
theorem VariableRelabeling.actOnSubset_id (variableCount : Nat) (subset : VariableSubset) :
    actOnSubset (VariableRelabeling.id variableCount) subset = subset.normalize := by
  unfold actOnSubset
  have hFun : ((VariableRelabeling.id variableCount) : Var → Var) = (fun var => var) := by
    funext var
    exact VariableRelabeling.id_apply variableCount var
  cases subset with
  | mk vars =>
      simp [VariableSubset.map, hFun]

/-- Composition of scoped relabelings induces pointwise composition of the subset action. -/
theorem actOnSubset_mul {left right : VariableRelabeling}
    (h : left.variableCount = right.variableCount) (subset : VariableSubset) :
    actOnSubset (left * right) subset = actOnSubset left (actOnSubset right subset) := by
  unfold actOnSubset
  rw [VariableSubset.normalize_map_commute]
  congr 1
  cases subset with
  | mk vars =>
      change (VariableSubset.mk (vars.map (left * right))) =
        VariableSubset.mk ((vars.map right).map left)
      rw [List.map_map]
      apply congrArg VariableSubset.mk
      apply List.map_congr_left
      intro var _
      change (left * right).apply var = left.apply (right.apply var)
      exact VariableRelabeling.mul_apply h var

/-- Composition of scoped relabelings induces pointwise composition of the term action. -/
theorem actOnTerm_mul {left right : VariableRelabeling}
    (h : left.variableCount = right.variableCount) (term : InequalityTerm) :
    actOnTerm (left * right) term = actOnTerm left (actOnTerm right term) := by
  unfold actOnTerm
  simp [actOnSubset_mul h]

/-- Composition of scoped relabelings induces pointwise composition of the vector action. -/
theorem actOnVector_mul {left right : VariableRelabeling} {vector : InequalityVector}
    (h : left.variableCount = right.variableCount)
    (hScopeLeft : left.variableCount = vector.variableCount)
    (hScopeRight : right.variableCount = vector.variableCount)
    (hScopeMul : (left * right).variableCount = vector.variableCount) :
    actOnVector (left * right) vector hScopeMul =
      actOnVector left (actOnVector right vector hScopeRight)
        (by rw [actOnVector_variableCount]; exact hScopeLeft) := by
  unfold actOnVector
  congr 1
  rw [List.map_map]
  apply List.map_congr_left
  intro term _
  exact actOnTerm_mul h term

theorem VariableRelabeling.apply_lt_of_lt {relabeling : VariableRelabeling} {variableCount var : Nat}
    (hScope : relabeling.variableCount ≤ variableCount) (hVar : var < variableCount) :
    relabeling var < variableCount := by
  by_cases hIn : var < relabeling.variableCount
  · rw [VariableRelabeling.apply_of_lt hIn]
    exact lt_of_lt_of_le (relabeling.perm ⟨var, hIn⟩).isLt hScope
  · rw [VariableRelabeling.apply_of_ge (Nat.le_of_not_lt hIn)]
    exact hVar

/-- Applying a scoped relabeling preserves range-validity of the underlying subset. -/
theorem actOnSubset_isInRange {relabeling : VariableRelabeling} {variableCount : Nat}
    {subset : VariableSubset} (hScope : relabeling.variableCount ≤ variableCount)
    (hSubset : subset.IsInRange variableCount) :
    (actOnSubset relabeling subset).IsInRange variableCount := by
  intro var hVar
  unfold actOnSubset at hVar
  rw [VariableSubset.mem_normalize] at hVar
  change var ∈ subset.vars.map relabeling at hVar
  rcases List.mem_map.1 hVar with ⟨previous, hPrevious, rfl⟩
  exact relabeling.apply_lt_of_lt hScope (hSubset previous hPrevious)

/-- Applying a scoped relabeling preserves range-validity of a term. -/
theorem actOnTerm_isInRange {relabeling : VariableRelabeling} {variableCount : Nat}
    {term : InequalityTerm} (hScope : relabeling.variableCount ≤ variableCount)
    (hTerm : term.IsInRange variableCount) :
    (actOnTerm relabeling term).IsInRange variableCount :=
  actOnSubset_isInRange hScope hTerm

/-- Applying a scoped relabeling preserves range-validity of an inequality vector. -/
theorem actOnVector_isInRange {relabeling : VariableRelabeling} {vector : InequalityVector}
    (hScope : relabeling.variableCount = vector.variableCount) (hVector : vector.IsInRange) :
    (actOnVector relabeling vector hScope).IsInRange := by
  intro term hTerm
  rw [actOnVector_terms, List.mem_map] at hTerm
  rcases hTerm with ⟨previous, hPrevious, rfl⟩
  exact actOnTerm_isInRange (Nat.le_of_eq hScope) (hVector previous hPrevious)

end NonShannon
