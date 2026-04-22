-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon

namespace NonShannonTest

open NonShannon

private def candidate : CandidateInequality :=
  { id := "fixture"
    label := "Fixture"
    vector := { variableCount := 4, terms := [] }
    provenance := { source := "bootstrap" } }

private def certificate : RedundancyCertificate :=
  { targetId := "fixture"
    sources := [ { id := "shannon-1", weight := (1 : Rat) } ]
    backend := "stub"
    backendVersion := "0"
    leanCheckable := false }

example : candidate.status = .candidate := rfl

example : candidate.vector.variableCount = 4 := rfl

example : candidate.orbitId = none := rfl

example : ({ candidate with orbitId := some "fixture-orbit" }).orbitId = some "fixture-orbit" := rfl

example : ({ candidate with orbitId := some "fixture-orbit", symmetryOrbitSize? := some 24 }).orbitId = some "fixture-orbit" := rfl

example : ({ candidate with orbitId := some "fixture-orbit", symmetryOrbitSize? := some 24 }).symmetryOrbitSize? = some 24 := rfl

example : certificate.sources.length = 1 := rfl

end NonShannonTest
