-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

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

/-! ### `isCanonicalShape` is decidable on concrete vectors -/

example : isCanonicalShape zhangYeungAveragedScaled.vector := by decide

example : ¬ isCanonicalShape signedVector := by decide

example : ¬ isCanonicalShape unsortedVector := by decide

/-! ### Canonicalization on synthetic vectors

Kernel `decide` reduces cleanly for the sign-flip and sort cases because
`canonicalize` uses `List.insertionSort`, which is structurally recursive. The
Zhang-Yeung fixed-point example below closes by kernel reduction for the same
reason.

The duplicate-combination case is the one remaining `native_decide` holdout:
combining `[0, 2]` with coefficient `1` and `[0, 2]` with coefficient `-1`
requires evaluating `(1 : Rat) + (-1 : Rat) = 0` at the kernel, and Mathlib's
`Rat.add` does not reduce under `decide` (normalization via `Nat.gcd` wedges).
The `set_option` override is scoped narrowly to that one example. -/

example : (canonicalize signedVector).terms.head?.map (·.coefficient) = some (3 : Rat) := by
  decide

set_option linter.style.nativeDecide false in
example :
    (canonicalize duplicateVector).terms.find? (fun term => term.subset = { vars := [0, 2] })
      = none := by
  native_decide

example :
    (canonicalize unsortedVector).terms.map (·.subset.vars)
      = [[0], [1, 2], [2, 3]] := by
  decide

/-! ### Zhang-Yeung fixture is a fixed point -/

example : canonicalize zhangYeungAveragedScaled.vector = zhangYeungAveragedScaled.vector := by
  decide

end NonShannonTest
