-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

set_option linter.style.nativeDecide false

namespace NonShannonTest

open NonShannon

private def xz : VariableSubset := { vars := [0, 2] }

private def swapZeroOne : VariableRelabeling :=
  { image := fun v => if v = 0 then 1 else if v = 1 then 0 else v }

private def signedVector : InequalityVector :=
  { variableCount := 4
    terms := [ { subset := { vars := [0] }, coefficient := (-3 : Rat) } ] }

private def duplicateVector : InequalityVector :=
  { variableCount := 4
    terms :=
      [ { subset := { vars := [0, 2] }, coefficient := (1 : Rat) }
      , { subset := { vars := [0, 2] }, coefficient := (-1 : Rat) }
      , { subset := { vars := [1] }, coefficient := (2 : Rat) } ] }

private def unsortedVector : InequalityVector :=
  { variableCount := 4
    terms :=
      [ { subset := { vars := [2, 3] }, coefficient := (1 : Rat) }
      , { subset := { vars := [1, 2] }, coefficient := (1 : Rat) }
      , { subset := { vars := [0] }, coefficient := (1 : Rat) } ] }

/-! ### Relabeling -/

example : (swapZeroOne.applySubset xz).vars = [1, 2] := by
  simp [VariableRelabeling.applySubset, VariableSubset.map, swapZeroOne, xz]

/-! ### Canonicalization on synthetic vectors -/

example : (canonicalize signedVector).terms.head?.map (·.coefficient) = some (3 : Rat) := by
  native_decide

example :
    (canonicalize duplicateVector).terms.find? (fun term => term.subset = { vars := [0, 2] })
      = none := by
  native_decide

example :
    (canonicalize unsortedVector).terms.map (·.subset.vars)
      = [[0], [1, 2], [2, 3]] := by
  native_decide

/-! ### Zhang-Yeung fixture is a fixed point -/

example : canonicalize zhangYeungAveragedScaled.vector = zhangYeungAveragedScaled.vector := by
  native_decide

end NonShannonTest
