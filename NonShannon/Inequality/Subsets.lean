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

end NonShannon
