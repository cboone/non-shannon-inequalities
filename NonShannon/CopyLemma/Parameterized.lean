-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.CopyLemma.Parameters

namespace NonShannon

/-- Placeholder statement-layer target for the future generalized copy lemma. Bootstrap only. -/
def parameterizedCopyLemmaSpec (params : CopyParameters) : Prop :=
  params.copyCount = 0 ∨ 0 < params.copyCount

/-- Type alias for future generalized copy-lemma theorem statements. -/
abbrev ParameterizedCopyLemmaShape := CopyParameters → Prop

/-- Bootstrap alias exposing the current generalized copy-lemma target shape. -/
def parameterizedCopyLemma : ParameterizedCopyLemmaShape :=
  parameterizedCopyLemmaSpec

/-- Metadata naming the future theorem and module associated to a parameter set. -/
structure ParameterizedCopyLemmaTarget where
  /-- Planned theorem name in the Lean statement layer. -/
  theoremName : String
  /-- Planned module path for the theorem. -/
  moduleName : String
  /-- Parameter payload targeted by the theorem. -/
  parameters : CopyParameters
  deriving DecidableEq, Inhabited

end NonShannon
