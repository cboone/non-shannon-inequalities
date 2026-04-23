-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.Inequality.Subsets

namespace NonShannon

/-- Coordinate conventions for encoding linear entropy inequalities. -/
inductive CoordinateBasis where
  | jointEntropy
  deriving DecidableEq, Inhabited

/-- One coefficient in a linear inequality, paired with the subset it multiplies. -/
structure InequalityTerm where
  /-- The entropy coordinate referenced by the term. -/
  subset : VariableSubset
  /-- The rational coefficient on the coordinate. -/
  coefficient : Rat
  deriving DecidableEq, Inhabited

/-- A term is in range for `variableCount` when its subset only references variables in `[0, variableCount)`. -/
def InequalityTerm.IsInRange (variableCount : Nat) (term : InequalityTerm) : Prop :=
  term.subset.IsInRange variableCount

instance (variableCount : Nat) (term : InequalityTerm) : Decidable (term.IsInRange variableCount) :=
  inferInstanceAs (Decidable (term.subset.IsInRange variableCount))

/-- Merges two terms that share a subset by summing their coefficients. The result keeps the first term's subset; callers are responsible for ensuring the two terms reference equal subsets (typically after passing each through `VariableSubset.normalize`). -/
def InequalityTerm.addCoefficients (first second : InequalityTerm) : InequalityTerm :=
  { subset := first.subset, coefficient := first.coefficient + second.coefficient }

/-- Inserts one term into a deduplicated accumulator keyed by subset: if the accumulator already contains a term with an equal subset, combine coefficients via `addCoefficients`; otherwise append the term. Callers should normalize subsets before inserting, so that equal subsets compare as equal. -/
def InequalityTerm.insertCombined (acc : List InequalityTerm) (term : InequalityTerm) :
    List InequalityTerm :=
  match acc.find? fun existing => existing.subset = term.subset with
  | some _ =>
      acc.map fun existing =>
        if existing.subset = term.subset then existing.addCoefficients term else existing
  | none => acc ++ [term]

/-- Combines a list of terms into a deduplicated list keyed by the normalized subset. Normalizes each input subset, sums coefficients on equal subsets, and drops zero-coefficient entries. Matches the duplicate-combination pass of `canonicalize_candidate` in the Python canonicalizer. The internal `VariableSubset.normalize` pass is unconditional: callers that already hold pre-normalized subsets pay for one redundant sort per term. This is fine for M1a's one caller (`canonicalize` in `NonShannon/Inequality/Canonical.lean`) and stays fine inside M1c's orbit loop at Zhang-Yeung scale (`n = 4`, `k = 12`, `|S_4| = 24`: total cost is a few thousand elementary operations). Revisit the split between "normalize then combine" and "combine pre-normalized" in a future milestone when `n ≥ 6` or `k` climbs into the dozens; the target rewrite is a `HashMap (List Nat) Rat`-keyed or `TreeMap`-keyed fold with the contract split so the outer `normalize` happens once in `canonicalize`. Not an M1c deliverable. -/
def InequalityTerm.combineDuplicates (terms : List InequalityTerm) : List InequalityTerm :=
  let normalized := terms.map fun term => { term with subset := term.subset.normalize }
  (normalized.foldl InequalityTerm.insertCombined []).filter
    fun term => decide (term.coefficient ≠ 0)

/-- A linear inequality written in a fixed entropy-coordinate basis. -/
structure InequalityVector where
  /-- Number of base variables referenced by the inequality. -/
  variableCount : Nat
  /-- Coordinate convention used by the term list. -/
  basis : CoordinateBasis := .jointEntropy
  /-- Sparse list of nonzero or candidate coefficients. -/
  terms : List InequalityTerm
  deriving DecidableEq, Inhabited

/-- The first nonzero coefficient, when one exists. -/
def InequalityVector.leadingCoefficient? (vector : InequalityVector) : Option Rat :=
  (vector.terms.find? fun term => term.coefficient ≠ 0).map fun term => term.coefficient

/-- An inequality vector is in range when each term stays within its declared `variableCount`. -/
def InequalityVector.IsInRange (vector : InequalityVector) : Prop :=
  ∀ term ∈ vector.terms, term.IsInRange vector.variableCount

instance (vector : InequalityVector) : Decidable vector.IsInRange :=
  inferInstanceAs (Decidable (∀ term ∈ vector.terms, term.IsInRange vector.variableCount))

/-- Negates every coefficient in the inequality vector. -/
def InequalityVector.neg (vector : InequalityVector) : InequalityVector :=
  { vector with terms := vector.terms.map fun term => { term with coefficient := -term.coefficient } }

/-- Normalizes the overall sign by making the leading nonzero coefficient nonnegative. -/
def InequalityVector.normalizeSign (vector : InequalityVector) : InequalityVector :=
  match vector.leadingCoefficient? with
  | some coefficient =>
      if coefficient < 0 then vector.neg else vector
  | none => vector

end NonShannon
