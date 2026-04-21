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

instance (subset : VariableSubset) : Decidable subset.isNormalized :=
  inferInstanceAs (Decidable (subset.vars.Pairwise (· < ·)))

/-- The number of variable indices carried by the subset. -/
def VariableSubset.cardinality (subset : VariableSubset) : Nat :=
  subset.vars.length

/-- Applies a variable relabeling to every index in the subset. Does not preserve `isNormalized` in general: if `f` is not strictly increasing on the underlying indices, the resulting subset may need to be re-normalized by a separate pass. -/
def VariableSubset.map (f : Var → Var) (subset : VariableSubset) : VariableSubset :=
  { vars := subset.vars.map f }

/-- Key used to order subsets during canonicalization: size first, then the underlying index list lexicographically. Matches `subset_sort_key` in the Python canonicalizer so that Lean and Python produce the same term order. -/
def VariableSubset.sortKey (subset : VariableSubset) : Nat × List Nat :=
  (subset.cardinality, subset.vars)

/-- Non-strict Bool comparator induced by `sortKey`: true exactly when the first subset should come no later than the second under the canonical `(cardinality, lex)` order. Intended as the comparator for `List.insertionSort` in the canonicalizer. -/
def VariableSubset.sortKeyLe (first second : VariableSubset) : Bool :=
  ((compare first.cardinality second.cardinality).then
    (compare first.vars second.vars)).isLE

/-- Strict variant of `sortKeyLe`: true exactly when the first subset strictly precedes the second under the canonical `(cardinality, lex)` order. Used by `isCanonicalShape` to certify that a term list is sorted with no duplicates. -/
def VariableSubset.sortKeyLt (first second : VariableSubset) : Bool :=
  ((compare first.cardinality second.cardinality).then
    (compare first.vars second.vars)).isLT

/-- Returns the subset with its underlying indices deduplicated and sorted ascending. The output always satisfies `isNormalized`, regardless of the input's shape. Implemented via `List.insertionSort` rather than `List.mergeSort` because insertion sort is structurally recursive over the outer list and reduces in the kernel, while Lean core's `List.mergeSort` uses well-founded recursion with length-carrying subtypes and does not reduce via `decide`. The two are equal as functions (Mathlib's `List.mergeSort_eq_insertionSort`); we choose insertion sort for test reducibility. -/
def VariableSubset.normalize (subset : VariableSubset) : VariableSubset :=
  { vars := subset.vars.dedup.insertionSort (· ≤ ·) }

/-- `VariableSubset.normalize` is idempotent: a second pass over a normalized subset returns the same subset. -/
theorem VariableSubset.normalize_idempotent (subset : VariableSubset) :
    subset.normalize.normalize = subset.normalize := by
  unfold VariableSubset.normalize
  have dedupIsDuplicateFree : subset.vars.dedup.Nodup := List.nodup_dedup subset.vars
  have normalizedIsDuplicateFree :
      (subset.vars.dedup.insertionSort (· ≤ ·)).Nodup :=
    (List.perm_insertionSort (· ≤ ·) subset.vars.dedup).nodup_iff.mpr dedupIsDuplicateFree
  have dedupFixedOnNormalized :
      (subset.vars.dedup.insertionSort (· ≤ ·)).dedup
        = subset.vars.dedup.insertionSort (· ≤ ·) :=
    List.dedup_eq_self.mpr normalizedIsDuplicateFree
  have normalizedIsSorted :
      (subset.vars.dedup.insertionSort (· ≤ ·)).Pairwise (· ≤ ·) :=
    List.pairwise_insertionSort (· ≤ ·) subset.vars.dedup
  simp [dedupFixedOnNormalized,
    List.Pairwise.insertionSort_eq normalizedIsSorted]

example : (VariableSubset.normalize ⟨[2, 0, 1, 0]⟩).vars = [0, 1, 2] := by
  decide

end NonShannon
