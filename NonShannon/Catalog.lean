-- SPDX-FileCopyrightText: 2026 Christopher Boone
--
-- SPDX-License-Identifier: Apache-2.0

import NonShannon.Certificate.Schema

namespace NonShannon

/-- A curated inequality together with notes and any attached certificates. -/
structure CatalogEntry where
  /-- The candidate or validated inequality itself. -/
  candidate : CandidateInequality
  /-- Human-readable notes attached during curation. -/
  notes : List String := []
  /-- Attached redundancy or validation certificates. -/
  certificates : List RedundancyCertificate := []
  deriving DecidableEq, Inhabited

/-- The curated collection of tracked catalog entries. -/
abbrev Catalog := List CatalogEntry

end NonShannon
