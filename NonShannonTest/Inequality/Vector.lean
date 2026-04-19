-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

private def x : VariableSubset := { vars := [0] }
private def y : VariableSubset := { vars := [1] }

private def signedVector : InequalityVector :=
  { variableCount := 4
    terms :=
      [ { subset := x, coefficient := (-1 : Rat) }
      , { subset := y, coefficient := (2 : Rat) } ] }

example : x.cardinality = 1 := rfl

example : x.isNormalized := by
  simp [VariableSubset.isNormalized, x]

example : signedVector.leadingCoefficient? = some (-1 : Rat) := rfl

example : signedVector.neg.terms.head?.map (·.coefficient) = some (1 : Rat) := rfl

end NonShannonTest
