-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.CopyLemma.Parameters

namespace NonShannon

/-- One prototype block in a copy-lemma statement: copied variables and their conditioning variables. -/
structure CopyBlock where
  /-- Variables copied into fresh coordinates. -/
  copied : VariableSubset
  /-- Variables conditioning the copy operation. -/
  conditioning : VariableSubset
  deriving DecidableEq, Inhabited

/-- Typed statement-layer shape induced by copy-lemma parameters. The statement stores one prototype copy block and a copy count; the list of repeated blocks is available through `CopyLemmaStatement.copies`. -/
structure CopyLemmaStatement where
  /-- Number of base variables before copies are introduced. -/
  variableCount : Nat
  /-- Variables kept fixed during the copy construction. -/
  frozen : VariableSubset
  /-- Prototype copied-and-conditioning block repeated by the statement. -/
  copyPrototype : CopyBlock
  /-- Number of copies requested by the statement. -/
  copyCount : Nat
  /-- Conditional-independence patterns induced by the copy construction. -/
  independence : List ConditionalIndependencePattern
  deriving DecidableEq, Inhabited

/-- Derived view of a copy-lemma statement as a list of repeated copy blocks. -/
def CopyLemmaStatement.copies (statement : CopyLemmaStatement) : List CopyBlock :=
  List.replicate statement.copyCount statement.copyPrototype

/-- Relabels every structural subset in a copy-lemma statement. -/
@[nolint unusedArguments]
def CopyLemmaStatement.relabel (statement : CopyLemmaStatement) (relabeling : VariableRelabeling)
    (_hScope : relabeling.variableCount = statement.variableCount) : CopyLemmaStatement :=
  { statement with
    frozen := actOnSubset relabeling statement.frozen
    copyPrototype :=
      { copied := actOnSubset relabeling statement.copyPrototype.copied
        conditioning := actOnSubset relabeling statement.copyPrototype.conditioning }
    independence := statement.independence.map (·.relabel relabeling) }

/-- Relabeling does not change the declared variable count of a copy-lemma statement. -/
@[simp]
theorem CopyLemmaStatement.relabel_variableCount (statement : CopyLemmaStatement)
    (relabeling : VariableRelabeling)
    (hScope : relabeling.variableCount = statement.variableCount) :
    (statement.relabel relabeling hScope).variableCount = statement.variableCount := rfl

/-- The M2 conditional-independence list induced by single-block copy parameters. -/
def CopyLemmaStatement.inducedIndependence (params : CopyParameters) :
    List ConditionalIndependencePattern :=
  List.replicate params.copyCount
    { left := params.copied
      right := params.frozen
      given := params.conditioning }

/-- Deterministic projection from copy parameters to the statement-bearing shape. -/
def CopyLemmaStatement.ofParameters (params : CopyParameters) : CopyLemmaStatement :=
  { variableCount := params.variableCount
    frozen := params.frozen
    copyPrototype :=
      { copied := params.copied
        conditioning := params.conditioning }
    copyCount := params.copyCount
    independence := CopyLemmaStatement.inducedIndependence params }

/-- The induced conditional-independence list commutes with scoped relabeling. -/
theorem CopyLemmaStatement.inducedIndependence_relabel (params : CopyParameters)
    (relabeling : VariableRelabeling) (hScope : relabeling.variableCount = params.variableCount) :
    CopyLemmaStatement.inducedIndependence (params.relabel relabeling hScope) =
      (CopyLemmaStatement.inducedIndependence params).map (·.relabel relabeling) := by
  simp [CopyLemmaStatement.inducedIndependence, CopyParameters.relabel,
    ConditionalIndependencePattern.relabel]

/-- Projecting parameters to a statement commutes with scoped relabeling. -/
@[simp]
theorem CopyLemmaStatement.ofParameters_relabel (params : CopyParameters)
    (relabeling : VariableRelabeling) (hScope : relabeling.variableCount = params.variableCount) :
    CopyLemmaStatement.ofParameters (params.relabel relabeling hScope) =
      (CopyLemmaStatement.ofParameters params).relabel relabeling hScope := by
  simp [CopyLemmaStatement.ofParameters, CopyLemmaStatement.relabel, CopyParameters.relabel,
    CopyLemmaStatement.inducedIndependence, ConditionalIndependencePattern.relabel]

/-- Two copy-lemma statements have the same shape when they agree up to scoped relabeling. -/
def CopyLemmaStatement.SameShape (first second : CopyLemmaStatement) : Prop :=
  first.variableCount = second.variableCount ∧
    ∃ (relabeling : VariableRelabeling) (hScope : relabeling.variableCount = first.variableCount),
      second = first.relabel relabeling hScope

private theorem CopyLemmaStatement.ofParameters_eq_of_statementShape_eq {first second : CopyParameters}
    (hShape : first.statementShape = second.statementShape) :
    CopyLemmaStatement.ofParameters first = CopyLemmaStatement.ofParameters second := by
  cases first
  cases second
  cases hShape
  rfl

private theorem CopyLemmaStatement.statementShape_eq_of_ofParameters_eq {first second : CopyParameters}
    (hStatement : CopyLemmaStatement.ofParameters first = CopyLemmaStatement.ofParameters second) :
    first.statementShape = second.statementShape := by
  cases first
  cases second
  cases hStatement
  rfl

/-- Parameter-side statement-shape equivalence is exactly statement-side shape equivalence after projection. The bridge holds unconditionally: `CopyLemmaStatement.ofParameters` stores every statement-bearing field directly, so the projection is injective on the structural shape regardless of canonicalization. Callers holding `IsCanonical` should prefer the wrapped alias `sameStatementShape_iff_ofParameters_sameShape`. -/
theorem CopyParameters.sameStatementShape_iff_ofParameters_sameShape_core {first second : CopyParameters} :
    first.SameStatementShape second ↔
      (CopyLemmaStatement.ofParameters first).SameShape (CopyLemmaStatement.ofParameters second) := by
  constructor
  · rintro ⟨hVariableCount, relabeling, hScope, hShape⟩
    refine ⟨hVariableCount, relabeling, hScope, ?_⟩
    have hShape' : second.statementShape = (first.relabel relabeling hScope).statementShape := by
      simpa [CopyParameters.statementShape_relabel] using hShape
    have hStatement : CopyLemmaStatement.ofParameters second =
        CopyLemmaStatement.ofParameters (first.relabel relabeling hScope) :=
      CopyLemmaStatement.ofParameters_eq_of_statementShape_eq hShape'
    simpa [CopyLemmaStatement.ofParameters_relabel] using hStatement
  · rintro ⟨hVariableCount, relabeling, hScope, hStatement⟩
    refine ⟨hVariableCount, relabeling, hScope, ?_⟩
    have hStatement' : CopyLemmaStatement.ofParameters second =
        CopyLemmaStatement.ofParameters (first.relabel relabeling hScope) := by
      simpa [CopyLemmaStatement.ofParameters_relabel] using hStatement
    have hShape := CopyLemmaStatement.statementShape_eq_of_ofParameters_eq hStatement'
    simpa [CopyParameters.statementShape_relabel] using hShape

/-- Parameter-side statement-shape equivalence is exactly statement-side shape equivalence after projection. This is the canonical-hypothesis wrapper around `sameStatementShape_iff_ofParameters_sameShape_core`; the canonical hypotheses record the intended M2 invariant boundary for downstream consumers (for example, M5 search) even though the underlying bridge holds unconditionally. -/
theorem CopyParameters.sameStatementShape_iff_ofParameters_sameShape {first second : CopyParameters}
    (_hFirst : first.IsCanonical) (_hSecond : second.IsCanonical) :
    first.SameStatementShape second ↔
      (CopyLemmaStatement.ofParameters first).SameShape (CopyLemmaStatement.ofParameters second) :=
  CopyParameters.sameStatementShape_iff_ofParameters_sameShape_core

attribute [nolint unusedArguments] CopyParameters.sameStatementShape_iff_ofParameters_sameShape

/-- Metadata naming a generated theorem and module for a copy-lemma parameter set. `CopyLemmaStatement` carries the typed statement shape; this record carries theorem-generation metadata such as the Lean declaration name and module path, following the conventions recorded in `docs/research/copy-lemma-naming.md`. -/
structure ParameterizedCopyLemmaTarget where
  /-- Planned theorem name in the Lean statement layer; see the copy-lemma naming note for the expected template. -/
  theoremName : String
  /-- Planned module path for the theorem; see the copy-lemma naming note for the generated-module template. -/
  moduleName : String
  /-- Parameter payload targeted by the generated theorem. -/
  parameters : CopyParameters
  deriving DecidableEq, Inhabited

end NonShannon
