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

/-- Applies a scoped relabeling pointwise to a subset. -/
def VariableRelabeling.applySubset (relabeling : VariableRelabeling) (subset : VariableSubset) :
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
  (relabeling.applySubset subset).normalize

/-- Applies a relabeling to one inequality term. -/
def actOnTerm (relabeling : VariableRelabeling) (term : InequalityTerm) : InequalityTerm :=
  { term with subset := actOnSubset relabeling term.subset }

/-- Applies a relabeling termwise to an inequality vector without re-canonicalizing it. The resulting scope covers both the original vector variables and the relabeling's declared support. -/
def actOnVector (relabeling : VariableRelabeling) (vector : InequalityVector) : InequalityVector :=
  { vector with
    variableCount := max vector.variableCount relabeling.variableCount
    terms := vector.terms.map (actOnTerm relabeling) }

/-- Applies a relabeling to one inequality term. -/
def InequalityTerm.relabel (relabeling : VariableRelabeling) (term : InequalityTerm) : InequalityTerm :=
  actOnTerm relabeling term

/-- Applies a relabeling pointwise to all terms of an inequality vector. The resulting scope covers both the original vector variables and the relabeling's declared support. -/
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
  unfold actOnSubset VariableRelabeling.applySubset
  have hId : subset.map (VariableRelabeling.id variableCount) = subset := by
    cases subset
    have hFun : (VariableRelabeling.id variableCount).apply = (fun var => var) := by
      funext var
      exact VariableRelabeling.id_apply variableCount var
    simpa [VariableSubset.map, hFun]
  simpa [hId] using VariableSubset.normalize_idempotent subset

end NonShannon
