import NonShannon.Inequality.Vector

namespace NonShannon

/-- A variable relabeling used when comparing inequalities up to symmetry. -/
structure VariablePermutation where
  /-- The image of each variable index. -/
  image : Var → Var

/-- Applies a relabeling to a subset of variables. -/
def VariablePermutation.applySubset (permutation : VariablePermutation) (subset : VariableSubset) : VariableSubset :=
  subset.map permutation.image

/-- Applies a relabeling to every term in an inequality vector. -/
def VariablePermutation.applyVector (permutation : VariablePermutation) (vector : InequalityVector) : InequalityVector :=
  { vector with terms := vector.terms.map fun term => term.mapVars permutation.image }

/-- Bootstrap canonicalization currently normalizes only the overall sign. -/
def canonicalize (vector : InequalityVector) : InequalityVector :=
  vector.normalizeSign

/-- Predicate asserting that an inequality is fixed by the current canonicalizer. -/
def isCanonical (vector : InequalityVector) : Prop :=
  canonicalize vector = vector

end NonShannon
