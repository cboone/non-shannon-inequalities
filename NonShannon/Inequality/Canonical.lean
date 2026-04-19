-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.Inequality.Vector

namespace NonShannon

/-- A variable relabeling used when comparing inequalities up to symmetry. The bootstrap surface is a bare function; a bijectivity invariant will land with the symmetry-orbit milestone. -/
structure VariableRelabeling where
  /-- The image of each variable index. -/
  image : Var → Var

/-- Applies a relabeling to a subset of variables. -/
def VariableRelabeling.applySubset (relabeling : VariableRelabeling) (subset : VariableSubset) : VariableSubset :=
  subset.map relabeling.image

/-- Applies a relabeling to every term in an inequality vector. -/
def VariableRelabeling.applyVector (relabeling : VariableRelabeling) (vector : InequalityVector) : InequalityVector :=
  { vector with terms := vector.terms.map fun term => term.mapVars relabeling.image }

/-- Bootstrap canonicalization currently normalizes only the overall sign. -/
def canonicalize (vector : InequalityVector) : InequalityVector :=
  vector.normalizeSign

/-- Predicate asserting that an inequality is fixed by the current canonicalizer. -/
def isCanonical (vector : InequalityVector) : Prop :=
  canonicalize vector = vector

end NonShannon
