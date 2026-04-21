-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.Prelude

namespace NonShannon

/-- A list of variable indices denoting a subset. The representation is an arbitrary `List Var`; the normalization invariant (strictly increasing, hence duplicate-free) is carried by the separate `VariableSubset.isNormalized` predicate rather than enforced at construction. Consumers that rely on a canonical representation should assume or require `isNormalized` explicitly. -/
structure VariableSubset where
  /-- Underlying variable indices. May be in any order until `isNormalized` is established. -/
  vars : List Var
  deriving DecidableEq, Inhabited

/-- The normalization invariant expected by statement-layer subset values: the underlying list is strictly increasing. -/
def VariableSubset.isNormalized (subset : VariableSubset) : Prop :=
  subset.vars.Pairwise (· < ·)

/-- The number of variable indices carried by the subset. -/
def VariableSubset.cardinality (subset : VariableSubset) : Nat :=
  subset.vars.length

/-- Applies a variable relabeling to every index in the subset. Does not preserve `isNormalized` in general: if `f` is not strictly increasing on the underlying indices, the resulting subset may need to be re-normalized by a separate pass. -/
def VariableSubset.map (f : Var → Var) (subset : VariableSubset) : VariableSubset :=
  { vars := subset.vars.map f }

/-- Key used to order subsets during canonicalization: size first, then the underlying index list lexicographically. Matches `subset_sort_key` in the Python canonicalizer so that Lean and Python produce the same term order. -/
def VariableSubset.sortKey (subset : VariableSubset) : Nat × List Nat :=
  (subset.cardinality, subset.vars)

/-- Non-strict Bool comparator induced by `sortKey`: true exactly when the first subset should come no later than the second under the canonical `(cardinality, lex)` order. Intended as the comparator for `List.mergeSort` in the canonicalizer. -/
def VariableSubset.sortKeyLe (first second : VariableSubset) : Bool :=
  ((compare first.cardinality second.cardinality).then
    (compare first.vars second.vars)).isLE

/-- Returns the subset with its underlying indices deduplicated and sorted ascending. The output always satisfies `isNormalized`, regardless of the input's shape. -/
def VariableSubset.normalize (subset : VariableSubset) : VariableSubset :=
  { vars := subset.vars.dedup.mergeSort (· ≤ ·) }

/-- `VariableSubset.normalize` is idempotent: a second pass over a normalized subset returns the same subset. -/
theorem VariableSubset.normalize_idempotent (subset : VariableSubset) :
    subset.normalize.normalize = subset.normalize := by
  unfold VariableSubset.normalize
  have dedupIsDuplicateFree : subset.vars.dedup.Nodup := List.nodup_dedup subset.vars
  have normalizedIsDuplicateFree : (subset.vars.dedup.mergeSort (· ≤ ·)).Nodup :=
    (List.mergeSort_perm subset.vars.dedup _).nodup_iff.mpr dedupIsDuplicateFree
  have dedupFixedOnNormalized : (subset.vars.dedup.mergeSort (· ≤ ·)).dedup
      = subset.vars.dedup.mergeSort (· ≤ ·) :=
    List.dedup_eq_self.mpr normalizedIsDuplicateFree
  have normalizedIsSorted : (subset.vars.dedup.mergeSort (· ≤ ·)).Pairwise (· ≤ ·) :=
    List.pairwise_mergeSort' (· ≤ ·) subset.vars.dedup
  simp [dedupFixedOnNormalized, List.mergeSort_eq_self (· ≤ ·) normalizedIsSorted]

example : (VariableSubset.normalize ⟨[2, 0, 1, 0]⟩).vars = [0, 1, 2] := by
  simp [VariableSubset.normalize, List.dedup, List.pwFilter, List.mergeSort]

end NonShannon
