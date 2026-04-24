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

example : bootstrapParams.copyCount = 2 := rfl

example : bootstrapParams.IsWellFormed := by
  decide

example : bootstrapParams.IsCanonical := by
  exact (show bootstrapParams.IsWellFormed by decide).toIsCanonical

example : (bootstrapParams.relabel (VariableRelabeling.id 4) rfl).IsWellFormed := by
  decide

end NonShannonTest
