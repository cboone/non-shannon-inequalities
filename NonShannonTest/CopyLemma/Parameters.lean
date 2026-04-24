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

private def identityRelabeling : VariableRelabeling :=
  VariableRelabeling.id 4

private theorem identityRelabeling_scope : identityRelabeling.variableCount = bootstrapParams.variableCount := by
  decide

example : bootstrapParams.copyCount = 2 := rfl

example : (actOnSubset identityRelabeling { vars := [1, 0, 1] }).isNormalized :=
  actOnSubset_isNormalized identityRelabeling { vars := [1, 0, 1] }

example :
    (actOnSubset identityRelabeling bootstrapParams.frozen).Disjoint
      (actOnSubset identityRelabeling bootstrapParams.copied) :=
  actOnSubset_Disjoint (relabeling := identityRelabeling) (variableCount := 4)
    rfl (by decide) (by decide) (by decide)

example : bootstrapParams.IsWellFormed := by
  decide

example : bootstrapParams.IsCanonical := by
  exact (show bootstrapParams.IsWellFormed by decide).toIsCanonical

example :
    (bootstrapParams.relabel identityRelabeling identityRelabeling_scope).variableCount =
      bootstrapParams.variableCount :=
  CopyParameters.relabel_variableCount bootstrapParams identityRelabeling identityRelabeling_scope

example :
    (bootstrapParams.relabel identityRelabeling identityRelabeling_scope).statementShape =
      bootstrapParams.statementShape.relabel identityRelabeling identityRelabeling_scope :=
  CopyParameters.statementShape_relabel bootstrapParams identityRelabeling identityRelabeling_scope

example : (bootstrapParams.relabel identityRelabeling identityRelabeling_scope).IsCanonical :=
  CopyParameters.relabel_IsCanonical (params := bootstrapParams) (relabeling := identityRelabeling)
    identityRelabeling_scope (by decide)

example : (bootstrapParams.relabel identityRelabeling identityRelabeling_scope).IsWellFormed :=
  CopyParameters.relabel_IsWellFormed (params := bootstrapParams) (relabeling := identityRelabeling)
    identityRelabeling_scope (by decide)

end NonShannonTest
