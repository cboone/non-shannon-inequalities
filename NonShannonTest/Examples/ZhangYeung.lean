-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

example : zhangYeungAveragedScaled.status = .reference := rfl

example : zhangYeungAveragedScaled.vector.variableCount = 4 := rfl

example : zhangYeungAveragedScaled.vector.terms.length = 12 := rfl

end NonShannonTest
