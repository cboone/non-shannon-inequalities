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

/-- Canonicalizes an inequality vector by (1) combining duplicate terms on normalized subsets and dropping zero-coefficient terms, (2) sorting the remaining terms by `(cardinality, lex)` via `VariableSubset.sortKeyLe`, and (3) flipping the overall sign so the first nonzero coefficient is nonnegative. Mirrors `canonicalize_candidate` in `src/non_shannon_search/canonical.py`; after M1a the two sides produce the same term list on equal inputs. The sort used here is `List.insertionSort`, chosen over `List.mergeSort` because insertion sort reduces under kernel `decide` while Lean core's merge sort does not. Both produce the same sorted output on total preorders; the choice is purely one of reducibility. -/
def canonicalize (vector : InequalityVector) : InequalityVector :=
  let combined := InequalityTerm.combineDuplicates vector.terms
  let sorted := combined.insertionSort
    fun first second => VariableSubset.sortKeyLe first.subset second.subset
  { vector with terms := sorted }.normalizeSign

/-- Predicate asserting that an inequality is fixed by the current canonicalizer. -/
def isCanonical (vector : InequalityVector) : Prop :=
  canonicalize vector = vector

/-- Structural shape predicate certifying that an `InequalityVector` is already in the M1a canonical form. Decidable on concrete vectors via the standard `Decidable` instances for list membership, pairwise predicates, and rational comparisons. Paired with `canonicalize_eq_self_of_isCanonicalShape`, this gives a kernel-reducible route to proving `canonicalize v = v` without invoking the canonicalizer's internals. -/
def isCanonicalShape (vector : InequalityVector) : Prop :=
  (∀ term ∈ vector.terms, term.subset.isNormalized)
    ∧ vector.terms.Pairwise (fun a b => VariableSubset.sortKeyLt a.subset b.subset = true)
    ∧ (∀ term ∈ vector.terms, term.coefficient ≠ 0)
    ∧ (∀ head, vector.terms.head? = some head → 0 ≤ head.coefficient)

instance (vector : InequalityVector) : Decidable (isCanonicalShape vector) :=
  inferInstanceAs (Decidable (_ ∧ _ ∧ _ ∧ _))

end NonShannon
