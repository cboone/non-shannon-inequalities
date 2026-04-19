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
