-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import Mathlib.Data.Fin.Embedding
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

private def VariableRelabeling.mapSubset (relabeling : VariableRelabeling) (subset : VariableSubset) :
    VariableSubset :=
  subset.map relabeling

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

private def VariableRelabeling.extendPerm (relabeling : VariableRelabeling) (variableCount : Nat)
    (h : relabeling.variableCount ≤ variableCount) :
    Equiv.Perm (Fin variableCount) :=
  relabeling.perm.extendDomain (Fin.castLEEmb h).toEquivRange

instance : Mul VariableRelabeling where
  mul left right :=
    let variableCount := max left.variableCount right.variableCount
    .ofPerm variableCount
      (left.extendPerm variableCount (Nat.le_max_left _ _)
        * right.extendPerm variableCount (Nat.le_max_right _ _))

/-- Applies a relabeling to one subset and normalizes the result. -/
def actOnSubset (relabeling : VariableRelabeling) (subset : VariableSubset) : VariableSubset :=
  (relabeling.mapSubset subset).normalize

/-- Applies a scoped relabeling to a subset via the normalized action. -/
def VariableRelabeling.applySubset (relabeling : VariableRelabeling) (subset : VariableSubset) :
    VariableSubset :=
  actOnSubset relabeling subset

/-- Applies a relabeling to one inequality term. -/
def actOnTerm (relabeling : VariableRelabeling) (term : InequalityTerm) : InequalityTerm :=
  { term with subset := actOnSubset relabeling term.subset }

/-- Applies a relabeling termwise to an inequality vector without re-canonicalizing it. The action preserves the vector's declared scope; callers that want range preservation must supply a relabeling whose declared scope stays within that scope. -/
def actOnVector (relabeling : VariableRelabeling) (vector : InequalityVector) : InequalityVector :=
  { vector with
    terms := vector.terms.map (actOnTerm relabeling) }

/-- Applies a scoped relabeling to every term of an inequality vector via the raw action. The action preserves the vector's declared scope. -/
def VariableRelabeling.applyVector (relabeling : VariableRelabeling) (vector : InequalityVector) :
    InequalityVector :=
  actOnVector relabeling vector

/-- Applies a relabeling to one inequality term. -/
def InequalityTerm.relabel (relabeling : VariableRelabeling) (term : InequalityTerm) : InequalityTerm :=
  actOnTerm relabeling term

/-- Applies a relabeling pointwise to all terms of an inequality vector. The action preserves the vector's declared scope; callers that want range preservation must supply a relabeling whose declared scope stays within that scope. -/
def InequalityVector.relabel (relabeling : VariableRelabeling) (vector : InequalityVector) :
    InequalityVector :=
  actOnVector relabeling vector

theorem VariableSubset.normalize_map_commute (f : Var → Var) (subset : VariableSubset) :
    (subset.normalize.map f).normalize = (subset.map f).normalize := by
  apply VariableSubset.eq_of_isNormalized_of_mem_iff
  · exact VariableSubset.normalize_isNormalized _
  · exact VariableSubset.normalize_isNormalized _
  intro var
  simp [VariableSubset.map, VariableSubset.mem_normalize, List.mem_map]

theorem VariableRelabeling.actOnSubset_id (variableCount : Nat) (subset : VariableSubset) :
    actOnSubset (VariableRelabeling.id variableCount) subset = subset.normalize := by
  unfold actOnSubset VariableRelabeling.mapSubset
  have hId : VariableSubset.map (VariableRelabeling.id variableCount).apply subset = subset := by
    cases subset
    have hFun : (VariableRelabeling.id variableCount).apply = (fun var => var) := by
      funext var
      exact VariableRelabeling.id_apply variableCount var
    simp [VariableSubset.map, hFun]
  rw [hId]

theorem VariableRelabeling.apply_lt_of_lt {relabeling : VariableRelabeling} {variableCount var : Nat}
    (hScope : relabeling.variableCount ≤ variableCount) (hVar : var < variableCount) :
    relabeling var < variableCount := by
  by_cases hIn : var < relabeling.variableCount
  · rw [VariableRelabeling.apply_of_lt hIn]
    exact lt_of_lt_of_le (relabeling.perm ⟨var, hIn⟩).is_lt hScope
  · rw [VariableRelabeling.apply_of_ge (Nat.le_of_not_lt hIn)]
    exact hVar

theorem VariableRelabeling.applySubset_isInRange {relabeling : VariableRelabeling}
    {variableCount : Nat} {subset : VariableSubset}
    (hScope : relabeling.variableCount ≤ variableCount) (hSubset : subset.IsInRange variableCount) :
    (VariableRelabeling.mapSubset relabeling subset).IsInRange variableCount := by
  intro var hVar
  change var ∈ subset.vars.map relabeling at hVar
  rcases List.mem_map.1 hVar with ⟨previous, hPrevious, rfl⟩
  exact relabeling.apply_lt_of_lt hScope (hSubset previous hPrevious)

theorem VariableRelabeling.actOnSubset_isInRange {relabeling : VariableRelabeling}
    {variableCount : Nat} {subset : VariableSubset}
    (hScope : relabeling.variableCount ≤ variableCount) (hSubset : subset.IsInRange variableCount) :
    (actOnSubset relabeling subset).IsInRange variableCount := by
  intro var hVar
  have hVar' : var ∈ (VariableRelabeling.mapSubset relabeling subset).vars :=
    (VariableSubset.mem_normalize (subset := VariableRelabeling.mapSubset relabeling subset) (var := var)).1 hVar
  exact relabeling.applySubset_isInRange hScope hSubset var hVar'

theorem InequalityTerm.relabel_isInRange {relabeling : VariableRelabeling} {variableCount : Nat}
    {term : InequalityTerm} (hScope : relabeling.variableCount ≤ variableCount)
    (hTerm : term.IsInRange variableCount) :
    (term.relabel relabeling).IsInRange variableCount :=
  relabeling.actOnSubset_isInRange hScope hTerm

theorem InequalityVector.relabel_isInRange {relabeling : VariableRelabeling} {vector : InequalityVector}
    (hScope : relabeling.variableCount ≤ vector.variableCount) (hVector : vector.IsInRange) :
    (vector.relabel relabeling).IsInRange := by
  intro term hTerm
  rw [InequalityVector.relabel, actOnVector] at hTerm
  rw [List.mem_map] at hTerm
  rcases hTerm with ⟨previous, hPrevious, rfl⟩
  exact previous.relabel_isInRange hScope (hVector previous hPrevious)

end NonShannon
