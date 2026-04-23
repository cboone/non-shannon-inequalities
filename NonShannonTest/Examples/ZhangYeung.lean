-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannonTest.Examples.ZhangYeungFromPython
import NonShannonTest.Examples.ZhangYeungSwapZeroOneFromPython
import NonShannon

namespace NonShannonTest

open NonShannon

example : zhangYeungAveragedScaledFromPython.vector = zhangYeungAveragedScaled.vector := rfl

example : zhangYeungAveragedScaled.status = .reference := rfl

set_option linter.style.nativeDecide false in
example : zhangYeungAveragedScaled.orbitId = some (orbitIdOf zhangYeungAveragedScaled.vector) := by
  native_decide

example : zhangYeungAveragedScaled.vector.variableCount = 4 := rfl

example : zhangYeungAveragedScaled.vector.terms.length = 12 := rfl

example :
    zhangYeungSwapZeroOneFromPython.vector =
      canonicalize (actOnVector (VariableRelabeling.swap 4 0 1) zhangYeungAveragedScaled.vector (by decide)) := rfl

example : zhangYeungAveragedScaledFromPython.orbitId = zhangYeungAveragedScaled.orbitId := rfl

example : zhangYeungSwapZeroOneFromPython.orbitId = zhangYeungAveragedScaled.orbitId := rfl

end NonShannonTest
