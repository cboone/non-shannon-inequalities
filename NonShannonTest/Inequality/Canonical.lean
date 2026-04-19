import NonShannon

namespace NonShannonTest

open NonShannon

private def xz : VariableSubset := { vars := [0, 2] }

private def swapZeroOne : VariablePermutation :=
  { image := fun v => if v = 0 then 1 else if v = 1 then 0 else v }

private def signedVector : InequalityVector :=
  { variableCount := 4
    terms := [ { subset := { vars := [0] }, coefficient := (-3 : Rat) } ] }

example : (swapZeroOne.applySubset xz).vars = [1, 2] := by
  simp [VariablePermutation.applySubset, VariableSubset.map, swapZeroOne, xz]

example : canonicalize signedVector = signedVector.normalizeSign := rfl

example : (canonicalize signedVector).terms.head?.map (·.coefficient) = some (3 : Rat) := rfl

end NonShannonTest
