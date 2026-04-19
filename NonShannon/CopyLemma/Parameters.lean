-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.Inequality.Subsets

namespace NonShannon

/-- A conditional-independence relation expected from a copy-lemma instance. -/
structure ConditionalIndependencePattern where
  /-- Left-hand variable block. -/
  left : VariableSubset
  /-- Right-hand variable block. -/
  right : VariableSubset
  /-- Conditioning variable block. -/
  given : VariableSubset
  deriving DecidableEq, Inhabited

/-- Statement-layer parameters for a generalized copy-lemma construction. -/
structure CopyParameters where
  /-- Number of base variables before copies are introduced. -/
  variableCount : Nat
  /-- Variables kept fixed during the copy construction. -/
  frozen : VariableSubset
  /-- Variables that are copied into fresh coordinates. -/
  copied : VariableSubset
  /-- Variables conditioning the copied distribution. -/
  conditioning : VariableSubset
  /-- Number of copies requested by the parameterization. -/
  copyCount : Nat
  /-- Human-readable label for debugging and catalog entries. -/
  label : String := ""
  /-- Conditional-independence constraints expected from the construction. -/
  conditionalIndependence : List ConditionalIndependencePattern := []
  deriving DecidableEq, Inhabited

end NonShannon
