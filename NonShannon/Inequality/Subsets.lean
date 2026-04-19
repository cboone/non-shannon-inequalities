import NonShannon.Prelude

namespace NonShannon

/-- A subset of variables represented as a sorted, duplicate-free list of indices. -/
structure VariableSubset where
  /-- Sorted variable indices. -/
  vars : List Var
  deriving DecidableEq, Inhabited

/-- The normalization invariant expected by statement-layer subset values. -/
def VariableSubset.isNormalized (subset : VariableSubset) : Prop :=
  subset.vars.Pairwise (· < ·)

/-- The number of variable indices carried by the subset. -/
def VariableSubset.cardinality (subset : VariableSubset) : Nat :=
  subset.vars.length

/-- Applies a variable relabeling to every index in the subset. -/
def VariableSubset.map (f : Var → Var) (subset : VariableSubset) : VariableSubset :=
  { vars := subset.vars.map f }

end NonShannon
