-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

private def swapZeroOne : VariableRelabeling :=
  VariableRelabeling.swap 4 0 1

private def swapTwoThree : VariableRelabeling :=
  VariableRelabeling.swap 4 2 3

private def cycleZeroOneTwo : VariableRelabeling :=
  VariableRelabeling.swap 4 0 1 * VariableRelabeling.swap 4 1 2

private theorem swapZeroOne_scope : swapZeroOne.variableCount = zhangYeungAveragedScaled.vector.variableCount := by
  decide

private theorem swapTwoThree_scope : swapTwoThree.variableCount = zhangYeungAveragedScaled.vector.variableCount := by
  decide

private theorem cycleZeroOneTwo_scope :
    cycleZeroOneTwo.variableCount = zhangYeungAveragedScaled.vector.variableCount := by
  decide

private def serializedCoefficientVector : InequalityVector :=
  { variableCount := 4
    terms :=
      [ { subset := { vars := [0] }, coefficient := (-5 : Rat) }
      , { subset := { vars := [1] }, coefficient := ((3 : Rat) / (2 : Rat)) }
      , { subset := { vars := [2] }, coefficient := ((-1 : Rat) / (3 : Rat)) }
      , { subset := { vars := [3] }, coefficient := (7 : Rat) } ] }

set_option linter.style.nativeDecide false

example : orbitCanonical zhangYeungAveragedScaled.vector = zhangYeungAveragedScaled.vector := by
  native_decide

example :
    orbitCanonical (actOnVector (VariableRelabeling.id 4) zhangYeungAveragedScaled.vector (by decide)) =
      orbitCanonical zhangYeungAveragedScaled.vector := by
  native_decide

example :
    orbitCanonical (actOnVector swapZeroOne zhangYeungAveragedScaled.vector swapZeroOne_scope) =
      orbitCanonical zhangYeungAveragedScaled.vector := by
  native_decide

example :
    orbitCanonical (actOnVector swapTwoThree zhangYeungAveragedScaled.vector swapTwoThree_scope) =
      orbitCanonical zhangYeungAveragedScaled.vector := by
  native_decide

example :
    orbitCanonical (actOnVector cycleZeroOneTwo zhangYeungAveragedScaled.vector cycleZeroOneTwo_scope) =
      orbitCanonical zhangYeungAveragedScaled.vector := by
  native_decide

example :
    orbitIdOf (actOnVector swapZeroOne zhangYeungAveragedScaled.vector swapZeroOne_scope) =
      orbitIdOf zhangYeungAveragedScaled.vector := by
  native_decide

example :
    orbitIdOf (actOnVector swapTwoThree zhangYeungAveragedScaled.vector swapTwoThree_scope) =
      orbitIdOf zhangYeungAveragedScaled.vector := by
  native_decide

example :
    orbitIdOf (actOnVector cycleZeroOneTwo zhangYeungAveragedScaled.vector cycleZeroOneTwo_scope) =
      orbitIdOf zhangYeungAveragedScaled.vector := by
  native_decide

example : orbitIdOf serializedCoefficientVector = "4;[0]:1/3;[1]:-7;[2]:-3/2;[3]:5" := by
  native_decide

end NonShannonTest
