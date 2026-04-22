-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import Init.Data.Order.Ord
import NonShannon.Inequality.Symmetry

namespace NonShannon

/-- Canonicalizes an inequality vector by (1) combining duplicate terms on normalized subsets and dropping zero-coefficient terms, (2) sorting the remaining terms by `(cardinality, lex)` via `VariableSubset.sortKeyLe`, and (3) flipping the overall sign so the first nonzero coefficient is nonnegative. Mirrors `canonicalize_candidate` in `src/non_shannon_search/canonical.py`; after M1a the two sides produce the same term list on equal inputs. The sort used here is `List.insertionSort`, chosen over `List.mergeSort` because insertion sort reduces under kernel `decide` while Lean core's merge sort does not. Both produce the same sorted output on total preorders; the choice is purely one of reducibility. -/
def canonicalize (vector : InequalityVector) : InequalityVector :=
  let combined := InequalityTerm.combineDuplicates vector.terms
  let sorted := combined.insertionSort
    fun first second => VariableSubset.sortKeyLe first.subset second.subset
  { vector with terms := sorted }.normalizeSign

/-- Predicate asserting that an inequality is fixed by the current canonicalizer. -/
def isCanonical (vector : InequalityVector) : Prop :=
  canonicalize vector = vector

/-- Structural shape predicate certifying that an `InequalityVector` is already fixed by each canonicalization pass. -/
def isCanonicalShape (vector : InequalityVector) : Prop :=
  (∀ term ∈ vector.terms, term.subset.isNormalized)
    ∧ vector.terms.Pairwise (fun a b => a.subset ≠ b.subset)
    ∧ vector.terms = vector.terms.insertionSort
      (fun first second => VariableSubset.sortKeyLe first.subset second.subset)
    ∧ (∀ term ∈ vector.terms, term.coefficient ≠ 0)
    ∧ (∀ head, vector.terms.head? = some head → 0 ≤ head.coefficient)

instance (vector : InequalityVector) : Decidable (isCanonicalShape vector) :=
  inferInstanceAs (Decidable (_ ∧ _ ∧ _ ∧ _ ∧ _))

private instance {α : Type _} : Std.Irrefl (fun a b : α => a ≠ b) where
  irrefl _ h := h rfl

private def termCompare : InequalityTerm → InequalityTerm → Ordering :=
  compareLex
    (compareOn fun term => term.subset.cardinality)
    (compareOn fun term => term.subset.vars)

private instance : Std.OrientedCmp termCompare := by
  unfold termCompare
  infer_instance

private instance : Std.TransCmp termCompare := by
  unfold termCompare
  infer_instance

private abbrev termSortLe (first second : InequalityTerm) : Bool :=
  VariableSubset.sortKeyLe first.subset second.subset

private abbrev termSortRel (first second : InequalityTerm) : Prop :=
  termSortLe first second = true

private theorem termSortRel_iff_isLE (first second : InequalityTerm) :
    termSortRel first second ↔ (termCompare first second).isLE := by
  rfl

private instance : Std.Total
    termSortRel where
  total first second := by
    have hTotal : (termCompare first second).isLE ∨ (termCompare second first).isLE := by
      unfold termCompare
      cases h : compareLex (compareOn fun term => term.subset.cardinality)
          (compareOn fun term => term.subset.vars) first second with
      | lt =>
          left
          simp
      | eq =>
          left
          simp
      | gt =>
          right
          have hSwap : compareLex (compareOn fun term => term.subset.cardinality)
              (compareOn fun term => term.subset.vars) second first = .lt := by
            have hEqSwap : compareLex (compareOn fun term => term.subset.cardinality)
                (compareOn fun term => term.subset.vars) first second =
                (compareLex (compareOn fun term => term.subset.cardinality)
                  (compareOn fun term => term.subset.vars) second first).swap :=
              (inferInstance : Std.OrientedCmp termCompare).eq_swap
            rw [h] at hEqSwap
            cases hRev : compareLex (compareOn fun term => term.subset.cardinality)
                (compareOn fun term => term.subset.vars) second first <;> simp [hRev] at hEqSwap
            rfl
          simp [hSwap]
    simpa [termSortRel_iff_isLE] using hTotal

private instance : IsTrans InequalityTerm
    termSortRel where
  trans first second third hFirst hSecond := by
    exact (termSortRel_iff_isLE first third).2 <|
      (inferInstance : Std.TransCmp termCompare).isLE_trans
        ((termSortRel_iff_isLE first second).1 hFirst)
        ((termSortRel_iff_isLE second third).1 hSecond)

private theorem normalizeTerms_eq_self_of_normalized {terms : List InequalityTerm}
    (hNormalized : ∀ term ∈ terms, term.subset.isNormalized) :
    terms.map (fun term => { term with subset := term.subset.normalize }) = terms := by
  induction terms with
  | nil => rfl
  | cons term terms ih =>
      have hTerm : term.subset.normalize = term.subset :=
        VariableSubset.normalize_eq_self_of_isNormalized (hNormalized term (by simp))
      have hTail : ∀ next ∈ terms, next.subset.isNormalized := by
        intro next hNext
        exact hNormalized next (by simp [hNext])
      simp [hTerm, ih hTail]

private theorem filterNonzero_eq_self_of_nonzero {terms : List InequalityTerm}
    (hNonzero : ∀ term ∈ terms, term.coefficient ≠ 0) :
    terms.filter (fun term => decide (term.coefficient ≠ 0)) = terms := by
  exact List.filter_eq_self.2 fun term hTerm => decide_eq_true (hNonzero term hTerm)

private theorem insertCombined_eq_append_of_pairwiseDistinct {processed rest : List InequalityTerm}
    {term : InequalityTerm}
    (hPairwise : (processed ++ term :: rest).Pairwise (fun a b => a.subset ≠ b.subset)) :
    InequalityTerm.insertCombined processed term = processed ++ [term] := by
  have hFind : processed.find? (fun existing => existing.subset = term.subset) = none := by
    induction processed with
    | nil => simp
    | cons first processed ih =>
        have hPairwise' : (first :: (processed ++ term :: rest)).Pairwise
            (fun a b => a.subset ≠ b.subset) := by
          simpa [List.append_assoc] using hPairwise
        rw [List.pairwise_cons] at hPairwise'
        have hFirst : first.subset ≠ term.subset := by
          exact hPairwise'.1 term (by simp)
        have hTail : (processed ++ term :: rest).Pairwise (fun a b => a.subset ≠ b.subset) := by
          exact hPairwise'.2
        simp [hFirst, ih hTail]
  simp [InequalityTerm.insertCombined, hFind]

private theorem foldl_insertCombined_eq_append_of_pairwiseDistinct :
    ∀ processed rest : List InequalityTerm,
      (processed ++ rest).Pairwise (fun a b => a.subset ≠ b.subset) →
      List.foldl InequalityTerm.insertCombined processed rest = processed ++ rest
  | processed, [], _ => by simp
  | processed, term :: rest, hPairwise => by
      have hInsert : InequalityTerm.insertCombined processed term = processed ++ [term] :=
        insertCombined_eq_append_of_pairwiseDistinct hPairwise
      have hTail : List.foldl InequalityTerm.insertCombined (processed ++ [term]) rest =
          (processed ++ [term]) ++ rest :=
        foldl_insertCombined_eq_append_of_pairwiseDistinct (processed ++ [term]) rest
          (by simpa [List.append_assoc] using hPairwise)
      simpa [List.foldl, hInsert, List.append_assoc] using hTail

theorem InequalityTerm.combineDuplicates_eq_self_of_normalized_distinct_nonzero
    {terms : List InequalityTerm}
    (hNormalized : ∀ term ∈ terms, term.subset.isNormalized)
    (hDistinct : terms.Pairwise (fun a b => a.subset ≠ b.subset))
    (hNonzero : ∀ term ∈ terms, term.coefficient ≠ 0) :
    InequalityTerm.combineDuplicates terms = terms := by
  unfold InequalityTerm.combineDuplicates
  have hFold : List.foldl InequalityTerm.insertCombined [] terms = terms :=
    foldl_insertCombined_eq_append_of_pairwiseDistinct [] terms (by simpa using hDistinct)
  simpa [normalizeTerms_eq_self_of_normalized hNormalized, hFold] using
    filterNonzero_eq_self_of_nonzero hNonzero

private theorem insertCombined_preserves_normalized {acc : List InequalityTerm} {term : InequalityTerm}
    (hAcc : ∀ existing ∈ acc, existing.subset.isNormalized)
    (hTerm : term.subset.isNormalized) :
    ∀ existing ∈ InequalityTerm.insertCombined acc term, existing.subset.isNormalized := by
  unfold InequalityTerm.insertCombined
  split
  · intro existing hExisting
    rw [List.mem_map] at hExisting
    rcases hExisting with ⟨previous, hPrevious, rfl⟩
    by_cases hSubset : previous.subset = term.subset
    · simpa [hSubset, InequalityTerm.addCoefficients] using hAcc previous hPrevious
    · simp [hSubset, hAcc previous hPrevious]
  · intro existing hExisting
    rw [List.mem_append] at hExisting
    rcases hExisting with hExisting | hExisting
    · exact hAcc existing hExisting
    · simp at hExisting
      subst hExisting
      exact hTerm

private theorem foldl_insertCombined_preserves_normalized :
    ∀ acc terms : List InequalityTerm,
      (∀ existing ∈ acc, existing.subset.isNormalized) →
      (∀ term ∈ terms, term.subset.isNormalized) →
      ∀ existing ∈ List.foldl InequalityTerm.insertCombined acc terms, existing.subset.isNormalized
  | acc, [], hAcc, _, existing, hExisting => by simpa using hAcc existing hExisting
  | acc, term :: terms, hAcc, hTerms, existing, hExisting => by
      have hInserted : ∀ next ∈ InequalityTerm.insertCombined acc term, next.subset.isNormalized :=
        insertCombined_preserves_normalized hAcc (hTerms term (by simp))
      have hTail : ∀ next ∈ terms, next.subset.isNormalized := by
        intro next hNext
        exact hTerms next (by simp [hNext])
      simpa [List.foldl] using
        foldl_insertCombined_preserves_normalized (InequalityTerm.insertCombined acc term) terms
          hInserted hTail existing hExisting

private theorem insertCombined_preserves_pairwiseDistinct {acc : List InequalityTerm}
    {term : InequalityTerm}
    (hAcc : acc.Pairwise (fun a b => a.subset ≠ b.subset)) :
    (InequalityTerm.insertCombined acc term).Pairwise (fun a b => a.subset ≠ b.subset) := by
  unfold InequalityTerm.insertCombined
  cases hEq : acc.find? (fun existing => existing.subset = term.subset) with
  | none =>
      have hCross : ∀ existing ∈ acc, existing.subset ≠ term.subset := by
        intro existing hExisting
        have := List.find?_eq_none.1 hEq existing hExisting
        simpa [ne_eq] using this
      rw [List.pairwise_append, List.pairwise_cons]
      have hCross' : ∀ existing ∈ acc, ¬ existing.subset = term.subset := by
        intro existing hExisting
        exact hCross existing hExisting
      refine ⟨hAcc, ⟨by simp, by simp⟩, ?_⟩
      intro existing hExisting other hOther
      simp at hOther
      subst hOther
      exact hCross' existing hExisting
  | some matched =>
      let f : InequalityTerm → InequalityTerm :=
        fun existing => if existing.subset = term.subset then existing.addCoefficients term else existing
      rw [List.pairwise_map]
      exact hAcc.imp (fun {a b} hab => by
        by_cases ha : a.subset = term.subset <;> by_cases hb : b.subset = term.subset <;>
          simpa [f, InequalityTerm.addCoefficients, ha, hb] using hab)

private theorem foldl_insertCombined_preserves_pairwiseDistinct :
    ∀ acc terms : List InequalityTerm,
      acc.Pairwise (fun a b => a.subset ≠ b.subset) →
      (List.foldl InequalityTerm.insertCombined acc terms).Pairwise (fun a b => a.subset ≠ b.subset)
  | acc, [], hAcc => hAcc
  | acc, term :: terms, hAcc => by
      simpa [List.foldl] using
        foldl_insertCombined_preserves_pairwiseDistinct (InequalityTerm.insertCombined acc term) terms
          (insertCombined_preserves_pairwiseDistinct hAcc)

theorem InequalityTerm.combineDuplicates_normalized {terms : List InequalityTerm} :
    ∀ term ∈ InequalityTerm.combineDuplicates terms, term.subset.isNormalized := by
  unfold InequalityTerm.combineDuplicates
  intro term hTerm
  have hMapped : ∀ next ∈ terms.map (fun next => { next with subset := next.subset.normalize }),
      next.subset.isNormalized := by
    intro next hNext
    rw [List.mem_map] at hNext
    rcases hNext with ⟨previous, _, rfl⟩
    exact VariableSubset.normalize_isNormalized _
  have hFold := foldl_insertCombined_preserves_normalized []
    (terms.map fun next => { next with subset := next.subset.normalize })
    (by simp) hMapped
  exact hFold term (List.mem_of_mem_filter hTerm)

theorem InequalityTerm.combineDuplicates_pairwiseDistinct (terms : List InequalityTerm) :
    (InequalityTerm.combineDuplicates terms).Pairwise (fun a b => a.subset ≠ b.subset) := by
  unfold InequalityTerm.combineDuplicates
  simpa using
    (foldl_insertCombined_preserves_pairwiseDistinct []
      (terms.map fun next => { next with subset := next.subset.normalize }) (by simp)).filter
      (fun term => decide (term.coefficient ≠ 0))

theorem InequalityTerm.combineDuplicates_nonzero {terms : List InequalityTerm} :
    ∀ term ∈ InequalityTerm.combineDuplicates terms, term.coefficient ≠ 0 := by
  intro term hTerm
  exact by simpa using (List.mem_filter.1 hTerm).2

theorem InequalityVector.leadingCoefficient?_eq_head?_map_coefficient_of_nonzero
    {vector : InequalityVector}
    (hNonzero : ∀ term ∈ vector.terms, term.coefficient ≠ 0) :
    vector.leadingCoefficient? = vector.terms.head?.map (·.coefficient) := by
  cases vector with
  | mk variableCount basis terms =>
      cases terms with
      | nil => simp [InequalityVector.leadingCoefficient?]
      | cons head tail =>
          have hHead : head.coefficient ≠ 0 := hNonzero head (by simp)
          simp [InequalityVector.leadingCoefficient?, hHead]

theorem InequalityVector.normalizeSign_eq_self_of_head_nonnegative {vector : InequalityVector}
    (hNonzero : ∀ term ∈ vector.terms, term.coefficient ≠ 0)
    (hHead : ∀ head, vector.terms.head? = some head → 0 ≤ head.coefficient) :
    vector.normalizeSign = vector := by
  unfold InequalityVector.normalizeSign
  rw [InequalityVector.leadingCoefficient?_eq_head?_map_coefficient_of_nonzero hNonzero]
  cases hHead? : vector.terms.head? with
  | none => rfl
  | some head =>
      have hHeadNonneg : 0 ≤ head.coefficient := hHead head hHead?
      simp [if_neg (not_lt.mpr hHeadNonneg)]

theorem InequalityVector.head_nonnegative_normalizeSign_of_nonzero {vector : InequalityVector}
    (hNonzero : ∀ term ∈ vector.terms, term.coefficient ≠ 0) :
    ∀ head, vector.normalizeSign.terms.head? = some head → 0 ≤ head.coefficient := by
  cases vector with
  | mk variableCount basis terms =>
      cases terms with
      | nil =>
          intro head hHead
          cases hHead
      | cons first tail =>
          intro head hHead
          have hFirst : first.coefficient ≠ 0 := hNonzero first (by simp)
          by_cases hNeg : first.coefficient < 0
          · simp [InequalityVector.normalizeSign, InequalityVector.leadingCoefficient?,
              InequalityVector.neg, hFirst, hNeg] at hHead
            subst hHead
            exact neg_nonneg.mpr (le_of_lt hNeg)
          · simp [InequalityVector.normalizeSign, InequalityVector.leadingCoefficient?,
              InequalityVector.neg, hFirst, hNeg] at hHead
            subst hHead
            exact not_lt.mp hNeg

theorem canonicalize_of_isCanonicalShape {vector : InequalityVector}
    (hShape : isCanonicalShape vector) :
    canonicalize vector = vector := by
  rcases hShape with ⟨hNormalized, hDistinct, hSorted, hNonzero, hHead⟩
  have hSorted' : List.insertionSort
      (fun first second => VariableSubset.sortKeyLe first.subset second.subset) vector.terms = vector.terms :=
    hSorted.symm
  unfold canonicalize
  simp [InequalityTerm.combineDuplicates_eq_self_of_normalized_distinct_nonzero
      hNormalized hDistinct hNonzero, hSorted',
    InequalityVector.normalizeSign_eq_self_of_head_nonnegative hNonzero hHead]

theorem isCanonicalShape_canonicalize (vector : InequalityVector) :
    isCanonicalShape (canonicalize vector) := by
  let combined := InequalityTerm.combineDuplicates vector.terms
  let sorted := combined.insertionSort
    (fun first second => VariableSubset.sortKeyLe first.subset second.subset)
  let sortedVector : InequalityVector := { vector with terms := sorted }
  have hCombinedNormalized : ∀ term ∈ combined, term.subset.isNormalized := by
    simpa [combined] using (InequalityTerm.combineDuplicates_normalized (terms := vector.terms))
  have hCombinedDistinct : combined.Pairwise (fun a b => a.subset ≠ b.subset) := by
    simpa [combined] using InequalityTerm.combineDuplicates_pairwiseDistinct vector.terms
  have hCombinedNonzero : ∀ term ∈ combined, term.coefficient ≠ 0 := by
    simpa [combined] using (InequalityTerm.combineDuplicates_nonzero (terms := vector.terms))
  have hSortedPairwiseComp : sorted.Pairwise
      termSortRel := by
    simpa [sorted, termSortRel] using List.pairwise_insertionSort
      (fun first second => VariableSubset.sortKeyLe first.subset second.subset) combined
  have hSortedNormalized : ∀ term ∈ sorted, term.subset.isNormalized := by
    intro term hTerm
    exact hCombinedNormalized term ((List.mem_insertionSort _).1 hTerm)
  have hSortedDistinct : sorted.Pairwise (fun a b => a.subset ≠ b.subset) := by
    have hCombinedSubsetNodup : (combined.map (fun term => term.subset)).Nodup := by
      have hPairwise : (combined.map (fun term => term.subset)).Pairwise (· ≠ ·) := by
        simpa [List.pairwise_map] using hCombinedDistinct
      exact hPairwise.nodup
    have hSortedSubsetNodup : (sorted.map (fun term => term.subset)).Nodup := by
      have hPerm : List.Perm sorted combined := by
        simpa [sorted] using List.perm_insertionSort
          (fun first second => VariableSubset.sortKeyLe first.subset second.subset) combined
      have hMappedPerm : List.Perm (sorted.map (fun term => term.subset))
          (combined.map (fun term => term.subset)) :=
        hPerm.map (fun term => term.subset)
      exact hMappedPerm.nodup_iff.mpr hCombinedSubsetNodup
    have hSortedSubsetPairwise : (sorted.map (fun term => term.subset)).Pairwise (· ≠ ·) :=
      hSortedSubsetNodup.pairwise_of_forall_ne (fun _ _ _ _ h => h)
    simpa [List.pairwise_map] using hSortedSubsetPairwise
  have hSortedSelf : sorted = sorted.insertionSort
      (fun first second => VariableSubset.sortKeyLe first.subset second.subset) := by
    exact (List.Pairwise.insertionSort_eq hSortedPairwiseComp).symm
  have hSortedNonzero : ∀ term ∈ sorted, term.coefficient ≠ 0 := by
    intro term hTerm
    exact hCombinedNonzero term ((List.mem_insertionSort _).1 hTerm)
  cases hHead? : sorted.head? with
  | none =>
      have hSortedNil : sorted = [] := by
        cases hSorted : sorted with
        | nil => rfl
        | cons head tail => simp [hSorted] at hHead?
      have hNormalizeSign : sortedVector.normalizeSign = sortedVector := by
        simp [sortedVector, hSortedNil, InequalityVector.normalizeSign, InequalityVector.leadingCoefficient?]
      have hSortedHead : ∀ head, sortedVector.terms.head? = some head → 0 ≤ head.coefficient := by
        intro head hHead
        simp [sortedVector, hSortedNil] at hHead
      simpa [canonicalize, combined, sorted, sortedVector, hNormalizeSign] using
        (show isCanonicalShape sortedVector from
          ⟨hSortedNormalized, hSortedDistinct, hSortedSelf, hSortedNonzero, hSortedHead⟩)
  | some first =>
      by_cases hNeg : first.coefficient < 0
      · have hNormalizeSign : sortedVector.normalizeSign = sortedVector.neg := by
          unfold InequalityVector.normalizeSign
          rw [InequalityVector.leadingCoefficient?_eq_head?_map_coefficient_of_nonzero hSortedNonzero]
          simp [hHead?, hNeg, sortedVector, InequalityVector.neg]
        have hNegNormalized : ∀ term ∈ sortedVector.neg.terms, term.subset.isNormalized := by
          intro term hTerm
          simp [sortedVector, InequalityVector.neg, List.mem_map] at hTerm
          rcases hTerm with ⟨previous, hPrevious, rfl⟩
          exact hSortedNormalized previous hPrevious
        have hNegDistinct : sortedVector.neg.terms.Pairwise (fun a b => a.subset ≠ b.subset) := by
          simpa [InequalityVector.neg, List.pairwise_map] using hSortedDistinct
        have hNegPairwiseComp : sortedVector.neg.terms.Pairwise
            termSortRel := by
          simpa [InequalityVector.neg, List.pairwise_map, termSortRel] using hSortedPairwiseComp
        have hNegSelf : sortedVector.neg.terms = sortedVector.neg.terms.insertionSort
            (fun first second => VariableSubset.sortKeyLe first.subset second.subset) := by
          exact (List.Pairwise.insertionSort_eq hNegPairwiseComp).symm
        have hNegNonzero : ∀ term ∈ sortedVector.neg.terms, term.coefficient ≠ 0 := by
          intro term hTerm
          simp [sortedVector, InequalityVector.neg, List.mem_map] at hTerm
          rcases hTerm with ⟨previous, hPrevious, rfl⟩
          exact neg_ne_zero.mpr (hSortedNonzero previous hPrevious)
        have hNegHead : ∀ head, sortedVector.neg.terms.head? = some head → 0 ≤ head.coefficient := by
          intro head hHead
          have hHead' : head = { first with coefficient := -first.coefficient } := by
            simpa [sortedVector, InequalityVector.neg, hHead?] using hHead.symm
          rw [hHead']
          exact neg_nonneg.mpr (le_of_lt hNeg)
        simpa [canonicalize, combined, sorted, sortedVector, hNormalizeSign] using
          (show isCanonicalShape sortedVector.neg from
            ⟨hNegNormalized, hNegDistinct, hNegSelf, hNegNonzero, hNegHead⟩)
      · have hNormalizeSign : sortedVector.normalizeSign = sortedVector := by
          unfold InequalityVector.normalizeSign
          rw [InequalityVector.leadingCoefficient?_eq_head?_map_coefficient_of_nonzero hSortedNonzero]
          simp [sortedVector, hHead?, hNeg]
        have hSortedHead : ∀ head, sortedVector.terms.head? = some head → 0 ≤ head.coefficient := by
          intro head hHead
          have hHead' : head = first := by
            simpa [sortedVector, hHead?] using hHead.symm
          rw [hHead']
          exact not_lt.mp hNeg
        simpa [canonicalize, combined, sorted, sortedVector, hNormalizeSign] using
          (show isCanonicalShape sortedVector from
            ⟨hSortedNormalized, hSortedDistinct, hSortedSelf, hSortedNonzero, hSortedHead⟩)

theorem canonicalize_idempotent (vector : InequalityVector) :
    canonicalize (canonicalize vector) = canonicalize vector := by
  exact canonicalize_of_isCanonicalShape (isCanonicalShape_canonicalize vector)

end NonShannon
