-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

/- Generated from Python's canonical Zhang-Yeung fixture. Keep in sync with `tests/test_emit_lean.py`. -/
def zhangYeungAveragedScaledFromPython : CandidateInequality :=
  { id := "zhang-yeung-averaged-scaled"
    label := "Zhang-Yeung averaged inequality (scaled by 4)"
    vector :=
      { variableCount := 4
        basis := .jointEntropy
        terms :=
          [
            { subset := { vars := [0] }, coefficient := (1 : Rat) },
            { subset := { vars := [1] }, coefficient := (1 : Rat) },
            { subset := { vars := [2] }, coefficient := (4 : Rat) },
            { subset := { vars := [3] }, coefficient := (4 : Rat) },
            { subset := { vars := [0, 1] }, coefficient := (2 : Rat) },
            { subset := { vars := [0, 2] }, coefficient := (-4 : Rat) },
            { subset := { vars := [0, 3] }, coefficient := (-4 : Rat) },
            { subset := { vars := [1, 2] }, coefficient := (-4 : Rat) },
            { subset := { vars := [1, 3] }, coefficient := (-4 : Rat) },
            { subset := { vars := [2, 3] }, coefficient := (-6 : Rat) },
            { subset := { vars := [0, 2, 3] }, coefficient := (5 : Rat) },
            { subset := { vars := [1, 2, 3] }, coefficient := (5 : Rat) } ] }
    provenance := { source := "Zhang and Yeung (1998), eq. 23", note := "Reference fixture imported during bootstrap from the sibling formalization project." }
    status := .reference }

end NonShannonTest
