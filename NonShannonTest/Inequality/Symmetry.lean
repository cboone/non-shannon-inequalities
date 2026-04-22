-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon
import NonShannonTest.Examples.ZhangYeungSwapZeroOneFromPython

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

private def zhangYeungSwapZeroOne : VariableRelabeling :=
  VariableRelabeling.swap 4 0 1

private def zhangYeungSwapOneTwo : VariableRelabeling :=
  VariableRelabeling.swap 4 1 2

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

example : (InequalityVector.relabel (VariableRelabeling.swap 2 0 1) sampleVector).variableCount = 2 := by
  decide

example : (InequalityVector.relabel (VariableRelabeling.swap 2 0 1) sampleVector).terms.map (·.subset.vars) = [[1], [0]] := by
  decide

example : (VariableRelabeling.swap 4 0 1 * VariableRelabeling.swap 4 1 2) 1 = 2 := by
  decide

example :
    canonicalize (actOnVector (VariableRelabeling.id 4) zhangYeungAveragedScaled.vector)
      = canonicalize zhangYeungAveragedScaled.vector := by
  decide

set_option maxHeartbeats 800000 in
-- The concrete composition check expands two canonicalization passes over the 12-term Zhang-Yeung fixture and needs a larger reduction budget than the default heartbeat cap.
example :
    canonicalize (actOnVector (zhangYeungSwapZeroOne * zhangYeungSwapOneTwo) zhangYeungAveragedScaled.vector)
      = canonicalize (actOnVector zhangYeungSwapZeroOne (actOnVector zhangYeungSwapOneTwo zhangYeungAveragedScaled.vector)) := by
  decide

example :
    (actOnVector zhangYeungSwapZeroOne zhangYeungAveragedScaled.vector).IsInRange := by
  exact InequalityVector.relabel_isInRange (vector := zhangYeungAveragedScaled.vector) (relabeling := zhangYeungSwapZeroOne)
    (by decide) (by decide)

example :
    canonicalize (actOnVector zhangYeungSwapZeroOne zhangYeungAveragedScaled.vector)
      = zhangYeungSwapZeroOneFromPython.vector := by
  decide

end NonShannonTest
