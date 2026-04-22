-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

private def xz : VariableSubset := { vars := [0, 2] }

private def swapZeroOne : VariableRelabeling :=
  VariableRelabeling.swap 4 0 1

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

private def mixedOrderDuplicateVector : InequalityVector :=
  { variableCount := 4
    terms :=
      [ { subset := { vars := [2, 0] }, coefficient := (1 : Rat) }
      , { subset := { vars := [0, 2] }, coefficient := (2 : Rat) }
      , { subset := { vars := [3, 1] }, coefficient := (4 : Rat) }
      , { subset := { vars := [0] }, coefficient := (1 : Rat) } ] }

private def scrambledZhangYeungVector : InequalityVector :=
  { variableCount := 4
    terms :=
      [ { subset := { vars := [3, 2] }, coefficient := (-6 : Rat) }
      , { subset := { vars := [2, 3, 1] }, coefficient := (5 : Rat) }
      , { subset := { vars := [1] }, coefficient := (1 : Rat) }
      , { subset := { vars := [3] }, coefficient := (4 : Rat) }
      , { subset := { vars := [3, 1] }, coefficient := (-4 : Rat) }
      , { subset := { vars := [1, 0] }, coefficient := (2 : Rat) }
      , { subset := { vars := [2] }, coefficient := (4 : Rat) }
      , { subset := { vars := [0] }, coefficient := (1 : Rat) }
      , { subset := { vars := [2, 0] }, coefficient := (-4 : Rat) }
      , { subset := { vars := [2, 1] }, coefficient := (-4 : Rat) }
      , { subset := { vars := [3, 0] }, coefficient := (-4 : Rat) }
      , { subset := { vars := [3, 0, 2] }, coefficient := (5 : Rat) } ] }

/-! ### Relabeling -/

example : (swapZeroOne.applySubset xz).vars = [1, 2] := by
  decide

/-! ### `isCanonicalShape` is decidable on concrete vectors -/

example : isCanonicalShape zhangYeungAveragedScaled.vector := by decide

example : ¬ isCanonicalShape signedVector := by decide

example : ¬ isCanonicalShape unsortedVector := by decide

example : ¬ isCanonicalShape mixedOrderDuplicateVector := by decide

/-! ### Canonicalization on synthetic vectors

Kernel `decide` reduces cleanly for the sign-flip and sort cases because
`canonicalize` uses `List.insertionSort`, which is structurally recursive.

The duplicate-combination case hits one extra wedge: combining terms on
`[0, 2]` with coefficients `1` and `-1` requires evaluating `(1 : Rat) + (-1 : Rat) = 0`,
and Mathlib's `Rat.add` does not reduce under `decide` because its
normalization goes through `Nat.gcd`. `simp` with the canonicalizer's
component unfolds does reduce through the Rat arithmetic (via
`simp`-set lemmas rather than kernel evaluation), leaving a structural
residue that `decide` then closes. -/

example : (canonicalize signedVector).terms.head?.map (·.coefficient) = some (3 : Rat) := by
  decide

-- `simp`'s default lemma set is needed here to reduce through `Rat` arithmetic in `combineDuplicates`; see the file-level docstring above. `linter.flexible` is disabled locally rather than project-wide so the unfold list stays reviewable and the suppression is visibly justified.
set_option linter.flexible false in
example :
    (canonicalize duplicateVector).terms.find? (fun term => term.subset = { vars := [0, 2] })
      = none := by
  simp [canonicalize, duplicateVector, InequalityTerm.combineDuplicates,
    InequalityTerm.insertCombined, VariableSubset.normalize,
    InequalityVector.normalizeSign, InequalityVector.leadingCoefficient?,
    List.dedup, List.pwFilter, List.insertionSort,
    List.foldl, List.filter, List.map, List.find?,
    InequalityTerm.addCoefficients, VariableSubset.sortKeyLe]
  decide

example :
    (canonicalize unsortedVector).terms.map (·.subset.vars)
      = [[0], [1, 2], [2, 3]] := by
  decide

example :
    InequalityTerm.combineDuplicates mixedOrderDuplicateVector.terms =
      [ { subset := { vars := [0, 2] }, coefficient := (3 : Rat) }
      , { subset := { vars := [1, 3] }, coefficient := (4 : Rat) }
      , { subset := { vars := [0] }, coefficient := (1 : Rat) } ] := by
  simp [mixedOrderDuplicateVector, InequalityTerm.combineDuplicates,
    InequalityTerm.insertCombined, VariableSubset.normalize,
    List.dedup, List.pwFilter,
    List.foldl, List.filter, List.map, List.find?,
    InequalityTerm.addCoefficients]
  norm_num

/-! ### Zhang-Yeung fixture is a fixed point -/

example : canonicalize scrambledZhangYeungVector = zhangYeungAveragedScaled.vector := by
  decide

example : canonicalize zhangYeungAveragedScaled.vector = zhangYeungAveragedScaled.vector := by
  decide

example : canonicalize (canonicalize duplicateVector) = canonicalize duplicateVector := by
  exact canonicalize_idempotent duplicateVector

end NonShannonTest
