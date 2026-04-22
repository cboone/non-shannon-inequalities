-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

private def xz : VariableSubset := { vars := [0, 2] }

private def sampleTerm : InequalityTerm :=
  { subset := { vars := [0, 2] }, coefficient := (3 : Rat) }

private def sampleVector : InequalityVector :=
  { variableCount := 2
    terms :=
      [ { subset := { vars := [0] }, coefficient := (1 : Rat) }
      , { subset := { vars := [1] }, coefficient := (-2 : Rat) } ] }

private def swapZeroOne : VariableRelabeling :=
  VariableRelabeling.swap 4 0 1

example : swapZeroOne 0 = 1 := by
  decide

example : swapZeroOne 1 = 0 := by
  decide

example : swapZeroOne 2 = 2 := by
  decide

example : swapZeroOne 5 = 5 := by
  decide

example : (swapZeroOne.applySubset xz).vars = [1, 2] := by
  decide

example : (InequalityTerm.relabel swapZeroOne sampleTerm).subset.vars = [1, 2] := by
  decide

example : (InequalityVector.relabel (VariableRelabeling.swap 4 0 2) sampleVector).variableCount = 4 := by
  decide

example : (InequalityVector.relabel (VariableRelabeling.swap 4 0 2) sampleVector).terms.map (·.subset.vars) = [[2], [1]] := by
  decide

example : (VariableRelabeling.swap 4 0 1 * VariableRelabeling.swap 4 1 2) 1 = 2 := by
  decide

end NonShannonTest
