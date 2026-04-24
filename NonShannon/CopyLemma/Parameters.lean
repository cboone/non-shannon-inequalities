-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.Inequality.Symmetry

namespace NonShannon

/-- A conditional-independence relation expected from a copy-lemma instance. -/
structure ConditionalIndependencePattern where
  /-- Left-hand variable block. -/
  left : VariableSubset
  /-- Right-hand variable block. -/
  right : VariableSubset
  /-- Conditioning variable block. -/
  given : VariableSubset
  deriving DecidableEq, Inhabited

/-- Relabels each block in a conditional-independence pattern by a scoped variable relabeling. -/
def ConditionalIndependencePattern.relabel
    (pattern : ConditionalIndependencePattern) (relabeling : VariableRelabeling) :
    ConditionalIndependencePattern :=
  { left := actOnSubset relabeling pattern.left
    right := actOnSubset relabeling pattern.right
    given := actOnSubset relabeling pattern.given }

/-- Statement-layer parameters for a generalized copy-lemma construction. -/
structure CopyParameters where
  /-- Number of base variables before copies are introduced. -/
  variableCount : Nat
  /-- Variables kept fixed during the copy construction. -/
  frozen : VariableSubset
  /-- Variables that are copied into fresh coordinates. -/
  copied : VariableSubset
  /-- Variables conditioning the copied distribution. -/
  conditioning : VariableSubset
  /-- Number of copies requested by the parameterization. -/
  copyCount : Nat
  /-- Human-readable label for debugging and catalog entries. -/
  label : String := ""
  /-- Conditional-independence constraints expected from the construction. -/
  conditionalIndependence : List ConditionalIndependencePattern := []
  deriving DecidableEq, Inhabited

/-- Two variable subsets are disjoint when their underlying variable lists are disjoint. -/
def VariableSubset.Disjoint (first second : VariableSubset) : Prop :=
  first.vars.Disjoint second.vars

instance (first second : VariableSubset) : Decidable (first.Disjoint second) :=
  decidable_of_iff (∀ var ∈ first.vars, var ∉ second.vars) List.disjoint_left.symm

/-- The statement-bearing structural projection of copy-lemma parameters, forgetting labels and user annotations. -/
structure CopyParameterShape where
  /-- Number of base variables before copies are introduced. -/
  variableCount : Nat
  /-- Variables kept fixed during the copy construction. -/
  frozen : VariableSubset
  /-- Variables that are copied into fresh coordinates. -/
  copied : VariableSubset
  /-- Variables conditioning the copied distribution. -/
  conditioning : VariableSubset
  /-- Number of copies requested by the parameterization. -/
  copyCount : Nat
  deriving DecidableEq, Inhabited

/-- The structural statement shape carried by a `CopyParameters` value. -/
def CopyParameters.statementShape (params : CopyParameters) : CopyParameterShape :=
  { variableCount := params.variableCount
    frozen := params.frozen
    copied := params.copied
    conditioning := params.conditioning
    copyCount := params.copyCount }

/-- Relabels the statement-bearing structural fields of a copy-parameter shape. -/
@[nolint unusedArguments]
def CopyParameterShape.relabel (shape : CopyParameterShape) (relabeling : VariableRelabeling)
    (_hScope : relabeling.variableCount = shape.variableCount) : CopyParameterShape :=
  { variableCount := shape.variableCount
    frozen := actOnSubset relabeling shape.frozen
    copied := actOnSubset relabeling shape.copied
    conditioning := actOnSubset relabeling shape.conditioning
    copyCount := shape.copyCount }

/-- Canonical copy-lemma parameters have in-range, normalized structural subsets. -/
structure CopyParameters.IsCanonical (params : CopyParameters) : Prop where
  /-- The frozen variables lie in the declared scope. -/
  frozenInRange : params.frozen.IsInRange params.variableCount
  /-- The copied variables lie in the declared scope. -/
  copiedInRange : params.copied.IsInRange params.variableCount
  /-- The conditioning variables lie in the declared scope. -/
  conditioningInRange : params.conditioning.IsInRange params.variableCount
  /-- The frozen variables are represented canonically. -/
  frozenNormalized : params.frozen.isNormalized
  /-- The copied variables are represented canonically. -/
  copiedNormalized : params.copied.isNormalized
  /-- The conditioning variables are represented canonically. -/
  conditioningNormalized : params.conditioning.isNormalized

instance (params : CopyParameters) : Decidable params.IsCanonical :=
  decidable_of_iff
    (params.frozen.IsInRange params.variableCount ∧
      params.copied.IsInRange params.variableCount ∧
      params.conditioning.IsInRange params.variableCount ∧
      params.frozen.isNormalized ∧
      params.copied.isNormalized ∧
      params.conditioning.isNormalized)
    ⟨fun ⟨hFrozenInRange, hCopiedInRange, hConditioningInRange,
          hFrozenNormalized, hCopiedNormalized, hConditioningNormalized⟩ =>
      { frozenInRange := hFrozenInRange
        copiedInRange := hCopiedInRange
        conditioningInRange := hConditioningInRange
        frozenNormalized := hFrozenNormalized
        copiedNormalized := hCopiedNormalized
        conditioningNormalized := hConditioningNormalized },
      fun hCanonical =>
        ⟨hCanonical.frozenInRange, hCanonical.copiedInRange, hCanonical.conditioningInRange,
          hCanonical.frozenNormalized, hCanonical.copiedNormalized,
          hCanonical.conditioningNormalized⟩⟩

/-- Well-formed copy-lemma parameters add pairwise disjointness to canonical structural subsets. -/
structure CopyParameters.IsWellFormed (params : CopyParameters) : Prop extends
    CopyParameters.IsCanonical params where
  /-- The frozen and copied variable blocks are disjoint. -/
  frozenCopiedDisjoint : params.frozen.Disjoint params.copied
  /-- The frozen and conditioning variable blocks are disjoint. -/
  frozenConditioningDisjoint : params.frozen.Disjoint params.conditioning
  /-- The copied and conditioning variable blocks are disjoint. -/
  copiedConditioningDisjoint : params.copied.Disjoint params.conditioning

instance (params : CopyParameters) : Decidable params.IsWellFormed :=
  decidable_of_iff
    (params.IsCanonical ∧
      params.frozen.Disjoint params.copied ∧
      params.frozen.Disjoint params.conditioning ∧
      params.copied.Disjoint params.conditioning)
    ⟨fun ⟨hCanonical, hFrozenCopied, hFrozenConditioning, hCopiedConditioning⟩ =>
      { toIsCanonical := hCanonical
        frozenCopiedDisjoint := hFrozenCopied
        frozenConditioningDisjoint := hFrozenConditioning
        copiedConditioningDisjoint := hCopiedConditioning },
      fun hWellFormed =>
        ⟨hWellFormed.toIsCanonical, hWellFormed.frozenCopiedDisjoint,
          hWellFormed.frozenConditioningDisjoint, hWellFormed.copiedConditioningDisjoint⟩⟩

/-- Relabels the structural subsets and user-provided conditional-independence metadata of copy parameters. -/
@[nolint unusedArguments]
def CopyParameters.relabel (params : CopyParameters) (relabeling : VariableRelabeling)
    (_hScope : relabeling.variableCount = params.variableCount) : CopyParameters :=
  { params with
    frozen := actOnSubset relabeling params.frozen
    copied := actOnSubset relabeling params.copied
    conditioning := actOnSubset relabeling params.conditioning
    conditionalIndependence :=
      params.conditionalIndependence.map (·.relabel relabeling) }

/-- The normalized subset action always returns a normalized subset. -/
theorem actOnSubset_isNormalized (relabeling : VariableRelabeling) (subset : VariableSubset) :
    (actOnSubset relabeling subset).isNormalized := by
  exact VariableSubset.normalize_isNormalized _

/-- Scoped relabeling preserves disjointness for in-range variable subsets. -/
theorem actOnSubset_Disjoint {relabeling : VariableRelabeling} {variableCount : Nat}
    {first second : VariableSubset} (hScope : relabeling.variableCount = variableCount)
    (hFirstRange : first.IsInRange variableCount) (hSecondRange : second.IsInRange variableCount)
    (hDisjoint : first.Disjoint second) :
    (actOnSubset relabeling first).Disjoint (actOnSubset relabeling second) := by
  intro var hFirstImage hSecondImage
  unfold actOnSubset at hFirstImage hSecondImage
  rw [VariableSubset.mem_normalize] at hFirstImage hSecondImage
  change var ∈ first.vars.map relabeling at hFirstImage
  change var ∈ second.vars.map relabeling at hSecondImage
  rcases List.mem_map.1 hFirstImage with ⟨firstVar, hFirstVar, hFirstVarImage⟩
  rcases List.mem_map.1 hSecondImage with ⟨secondVar, hSecondVar, hSecondVarImage⟩
  have hFirstLt : firstVar < relabeling.variableCount := by
    rw [hScope]
    exact hFirstRange firstVar hFirstVar
  have hSecondLt : secondVar < relabeling.variableCount := by
    rw [hScope]
    exact hSecondRange secondVar hSecondVar
  have hImageEq : relabeling firstVar = relabeling secondVar :=
    hFirstVarImage.trans hSecondVarImage.symm
  rw [VariableRelabeling.apply_of_lt hFirstLt, VariableRelabeling.apply_of_lt hSecondLt] at hImageEq
  have hFinEq : (⟨firstVar, hFirstLt⟩ : Fin relabeling.variableCount) = ⟨secondVar, hSecondLt⟩ :=
    relabeling.perm.injective (Fin.ext hImageEq)
  have hVarEq : firstVar = secondVar := congrArg Fin.val hFinEq
  exact hDisjoint hFirstVar (by simpa [hVarEq] using hSecondVar)

/-- Relabeling does not change the declared variable count of copy parameters. -/
@[simp]
theorem CopyParameters.relabel_variableCount (params : CopyParameters)
    (relabeling : VariableRelabeling) (hScope : relabeling.variableCount = params.variableCount) :
    (params.relabel relabeling hScope).variableCount = params.variableCount := rfl

/-- The structural projection commutes with relabeling copy parameters. -/
@[simp]
theorem CopyParameters.statementShape_relabel (params : CopyParameters)
    (relabeling : VariableRelabeling) (hScope : relabeling.variableCount = params.variableCount) :
    (params.relabel relabeling hScope).statementShape = params.statementShape.relabel relabeling hScope := rfl

/-- Relabeling preserves canonical copy parameters. -/
theorem CopyParameters.relabel_IsCanonical {params : CopyParameters}
    {relabeling : VariableRelabeling} (hScope : relabeling.variableCount = params.variableCount)
    (hCanonical : params.IsCanonical) :
    (params.relabel relabeling hScope).IsCanonical := by
  refine
    { frozenInRange := ?_
      copiedInRange := ?_
      conditioningInRange := ?_
      frozenNormalized := ?_
      copiedNormalized := ?_
      conditioningNormalized := ?_ }
  · exact actOnSubset_isInRange (Nat.le_of_eq hScope) hCanonical.frozenInRange
  · exact actOnSubset_isInRange (Nat.le_of_eq hScope) hCanonical.copiedInRange
  · exact actOnSubset_isInRange (Nat.le_of_eq hScope) hCanonical.conditioningInRange
  · exact actOnSubset_isNormalized relabeling params.frozen
  · exact actOnSubset_isNormalized relabeling params.copied
  · exact actOnSubset_isNormalized relabeling params.conditioning

/-- Relabeling preserves well-formed copy parameters. -/
theorem CopyParameters.relabel_IsWellFormed {params : CopyParameters}
    {relabeling : VariableRelabeling} (hScope : relabeling.variableCount = params.variableCount)
    (hWellFormed : params.IsWellFormed) :
    (params.relabel relabeling hScope).IsWellFormed := by
  refine
    { toIsCanonical := CopyParameters.relabel_IsCanonical hScope hWellFormed.toIsCanonical
      frozenCopiedDisjoint := ?_
      frozenConditioningDisjoint := ?_
      copiedConditioningDisjoint := ?_ }
  · exact actOnSubset_Disjoint hScope hWellFormed.frozenInRange hWellFormed.copiedInRange hWellFormed.frozenCopiedDisjoint
  · exact actOnSubset_Disjoint hScope hWellFormed.frozenInRange hWellFormed.conditioningInRange hWellFormed.frozenConditioningDisjoint
  · exact actOnSubset_Disjoint hScope hWellFormed.copiedInRange hWellFormed.conditioningInRange hWellFormed.copiedConditioningDisjoint

/-- Two parameter sets have the same statement shape when their structural projections agree up to scoped relabeling. -/
def CopyParameters.SameStatementShape (first second : CopyParameters) : Prop :=
  first.statementShape.variableCount = second.statementShape.variableCount ∧
    ∃ (relabeling : VariableRelabeling) (hScope : relabeling.variableCount = first.statementShape.variableCount),
      second.statementShape = first.statementShape.relabel relabeling hScope

end NonShannon
