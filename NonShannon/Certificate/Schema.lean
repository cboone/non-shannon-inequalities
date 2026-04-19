-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.Certificate.Status
import NonShannon.Inequality.Vector

namespace NonShannon

/-- Provenance metadata carried by tracked fixtures and validated artifacts. -/
structure Provenance where
  /-- Human-readable source reference. -/
  source : String
  /-- Free-form note clarifying the source or bootstrap status. -/
  note : String := ""
  deriving DecidableEq, Inhabited

/-- Lean-side mirror of the tracked candidate-inequality interchange schema. -/
structure CandidateInequality where
  /-- Stable identifier for the candidate or reference fixture. -/
  id : String
  /-- Human-readable label for displays and catalog entries. -/
  label : String
  /-- Sparse coefficient vector in the chosen basis. -/
  vector : InequalityVector
  /-- Source and acquisition metadata. -/
  provenance : Provenance
  /-- Optional reference to a tracked copy-lemma parameter payload. -/
  copyParametersRef? : Option String := none
  /-- Optional symmetry-orbit size when known externally. -/
  symmetryOrbitSize? : Option Nat := none
  /-- Current lifecycle state inside the research pipeline. -/
  status : CertificateStatus := .candidate
  deriving DecidableEq, Inhabited

/-- One weighted source inequality used in a redundancy certificate. -/
structure CombinationSource where
  /-- Identifier of the source inequality. -/
  id : String
  /-- Rational coefficient attached to the source inequality. -/
  weight : Rat
  deriving DecidableEq, Inhabited

/-- Lean-side mirror of the tracked redundancy-certificate interchange schema. -/
structure RedundancyCertificate where
  /-- Identifier of the target inequality proved redundant. -/
  targetId : String
  /-- Weighted source inequalities appearing in the combination. -/
  sources : List CombinationSource
  /-- Name of the external backend that produced the certificate. -/
  backend : String
  /-- Backend version string recorded with the result. -/
  backendVersion : String
  /-- Whether the certificate is already checkable inside Lean. -/
  leanCheckable : Bool
  deriving DecidableEq, Inhabited

end NonShannon
