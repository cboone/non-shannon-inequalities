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

/-- Applies a variable relabeling to the subset referenced by the term. -/
def InequalityTerm.mapVars (f : Var → Var) (term : InequalityTerm) : InequalityTerm :=
  { term with subset := term.subset.map f }

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

/-- Combines a list of terms into a deduplicated list keyed by the normalized subset. Normalizes each input subset, sums coefficients on equal subsets, and drops zero-coefficient entries. Matches the duplicate-combination pass of `canonicalize_candidate` in the Python canonicalizer. The internal `VariableSubset.normalize` pass is unconditional: callers that already hold pre-normalized subsets pay for one redundant sort per term. This is fine for M1a's one caller (`canonicalize` in `NonShannon/Inequality/Canonical.lean`), but a future M1b/M1c caller that composes an already-normalized relabeling output with `canonicalize` will traverse the normalize pass twice. Revisit the split between "normalize then combine" and "combine pre-normalized" when M1c rewrites `combineDuplicates` for orbit-enumeration performance (see M1c's risks for the tracked follow-up). -/
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
