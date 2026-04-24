-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

private def bootstrapParams : CopyParameters :=
  { variableCount := 4
    frozen := { vars := [0] }
    copied := { vars := [1] }
    conditioning := { vars := [2, 3] }
    copyCount := 2
    label := "two-copy bootstrap fixture" }

private def expectedPrototype : CopyBlock :=
  { copied := bootstrapParams.copied
    conditioning := bootstrapParams.conditioning }

private def expectedIndependencePattern : ConditionalIndependencePattern :=
  { left := bootstrapParams.copied
    right := bootstrapParams.frozen
    given := bootstrapParams.conditioning }

private def swapZeroOne : VariableRelabeling :=
  VariableRelabeling.swap 4 0 1

private theorem swapZeroOne_scope : swapZeroOne.variableCount = bootstrapParams.variableCount := by
  decide

private def zeroCopyParams : CopyParameters :=
  { bootstrapParams with
    copyCount := 0
    label := "zero-copy bootstrap fixture" }

private def differentCopyCountParams : CopyParameters :=
  { bootstrapParams with
    copyCount := 3
    label := "different copy count" }

private def metadataVariantParams : CopyParameters :=
  { bootstrapParams with
    label := "metadata-only variant"
    conditionalIndependence :=
      [ { left := { vars := [0] }
          right := { vars := [1] }
          given := { vars := [] } } ] }

private def generatedTarget : ParameterizedCopyLemmaTarget :=
  { theoremName := "copyLemma_bootstrap_abcd1234"
    moduleName := "NonShannon.CopyLemma.Generated.bootstrap"
    parameters := bootstrapParams }

set_option linter.style.nativeDecide false

example : (CopyLemmaStatement.ofParameters bootstrapParams).variableCount = 4 := rfl

example : (CopyLemmaStatement.ofParameters bootstrapParams).copyPrototype = expectedPrototype := rfl

example :
    (CopyLemmaStatement.ofParameters bootstrapParams).independence =
      List.replicate bootstrapParams.copyCount expectedIndependencePattern := rfl

example :
    (CopyLemmaStatement.ofParameters bootstrapParams).copies =
      List.replicate bootstrapParams.copyCount expectedPrototype := rfl

example :
    CopyLemmaStatement.ofParameters (bootstrapParams.relabel swapZeroOne swapZeroOne_scope) =
      (CopyLemmaStatement.ofParameters bootstrapParams).relabel swapZeroOne swapZeroOne_scope :=
  CopyLemmaStatement.ofParameters_relabel bootstrapParams swapZeroOne swapZeroOne_scope

example :
    zeroCopyParams.SameStatementShape zeroCopyParams ↔
      (CopyLemmaStatement.ofParameters zeroCopyParams).SameShape
        (CopyLemmaStatement.ofParameters zeroCopyParams) :=
  CopyParameters.sameStatementShape_iff_ofParameters_sameShape (by decide) (by decide)

example :
    bootstrapParams.SameStatementShape (bootstrapParams.relabel swapZeroOne swapZeroOne_scope) ↔
      (CopyLemmaStatement.ofParameters bootstrapParams).SameShape
        (CopyLemmaStatement.ofParameters
          (bootstrapParams.relabel swapZeroOne swapZeroOne_scope)) :=
  CopyParameters.sameStatementShape_iff_ofParameters_sameShape (by decide) (by decide)

example : bootstrapParams.IsCanonical ∧ differentCopyCountParams.IsCanonical := by
  decide

example : ¬ bootstrapParams.SameStatementShape differentCopyCountParams := by
  rintro ⟨_, _relabeling, _hScope, hShape⟩
  have hCopyCount := congrArg CopyParameterShape.copyCount hShape
  norm_num [bootstrapParams, differentCopyCountParams, CopyParameters.statementShape,
    CopyParameterShape.relabel] at hCopyCount

example : bootstrapParams.SameStatementShape metadataVariantParams := by
  refine ⟨rfl, VariableRelabeling.id 4, rfl, ?_⟩
  decide

example : generatedTarget.theoremName.startsWith "copyLemma_" = true := by
  native_decide

example : generatedTarget.moduleName.startsWith "NonShannon.CopyLemma.Generated." = true := by
  native_decide

end NonShannonTest
