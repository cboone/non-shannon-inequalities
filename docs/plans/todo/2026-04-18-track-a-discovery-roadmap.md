# 2026-04-18 Track A Discovery Roadmap

## Context

This roadmap turns Track A from `zhang-yeung-inequality` into a repo-local execution plan. The bootstrap plan created the repository surfaces. This roadmap governs the actual research and implementation milestones that follow.

Track A's objective is to discover candidate non-Shannon inequalities through copy-lemma-guided search, filter them with an external redundancy oracle, and validate the survivors in Lean.

## Scope

In scope:

- sparse inequality representations
- canonicalization and symmetry-aware normalization
- parameterized copy-lemma statement layer
- redundancy-certificate interfaces and oracle metadata
- reproduction of known inequalities as validation targets
- bounded search over parameter families
- curated Lean-facing catalog entries

Out of scope:

- Track B finite-group search
- GAP integration
- full paper drafting beyond planning notes

## Milestones

### M0: Repository scaffold and shared schemas

Goal: finish the bootstrap surfaces and lock in the shared interchange format.

Deliverables:

- Lean library plus mirrored `NonShannonTest` suite
- `uv` workspace and CLI entry point
- tracked schemas for candidates and redundancy certificates
- Zhang-Yeung reference fixture available in both Lean and Python

Verification:

- `make bootstrap`
- `make check`
- CLI schema and canonicalization smoke tests

### M1: Inequality representation and canonicalization

Goal: strengthen the sparse vector layer until it can support real search outputs.

Deliverables:

- richer subset and term normalization rules
- symmetry-aware permutation actions
- duplicate-term combination and orbit metadata plumbing
- stronger regression tests on canonical forms

Verification:

- canonicalization examples in Lean
- canonicalization round-trip tests in Python

### M2: Parameterized copy-lemma statement layer

Goal: replace the bootstrap placeholder with a stable statement vocabulary for the future generalized copy lemma.

Deliverables:

- typed parameter objects for frozen, copied, and conditioning variable blocks
- theorem-name and module-name conventions for generated statement targets
- first nontrivial statement-layer lemmas that downstream search code can reference

Verification:

- `NonShannonTest/CopyLemma/` examples cover the public API
- roadmap note records the exact theorem-shape freeze

### M3: Redundancy-certificate oracle boundary

Goal: make external LP output auditable even before a fully Lean-checkable certificate exists.

Deliverables:

- backend interface for redundancy LPs
- tracked metadata for backend name and version
- initial certificate semantics for source combinations
- explicit policy on `lean_checkable` versus external-oracle status

Verification:

- schema tests for certificate payloads
- research-note update in `docs/research/trust-boundary.md`

### M4: Known-inequality reproduction

Goal: validate the pipeline on known targets before searching for new ones.

Deliverables:

- Zhang-Yeung as a stable cross-language reference fixture
- first DFZ fixtures in the tracked schema
- initial Matús family fixtures for small bounded cases

Verification:

- curated fixtures load in Python and Lean
- canonicalization and schema checks pass on the full known set

### M5: Bounded search over parameter families

Goal: run the first deliberately small search that exercises the full candidate pipeline.

Deliverables:

- bounded enumeration driver
- canonicalization and deduplication in the loop
- redundancy backend integrated behind the tracked interface
- retained survivors written as curated candidate files, not raw exhaust

Verification:

- search run documented in `docs/research/`
- retained candidates all validate against schema

### M6: Validated catalog and paper-facing outputs

Goal: turn reproduced and newly retained inequalities into a curated catalog with proof-facing metadata.

Deliverables:

- expanded `NonShannon/Catalog.lean`
- stable naming scheme for validated entries
- correspondence between curated fixtures and Lean-facing statement objects

Verification:

- catalog tests in Lean
- one updated roadmap or paper-planning note describing the first publishable slice

## Critical Files

- `NonShannon/Inequality/*.lean`
- `NonShannon/Certificate/*.lean`
- `NonShannon/CopyLemma/*.lean`
- `NonShannon/Catalog.lean`
- `src/non_shannon_search/*.py`
- `schemas/*.json`
- `data/fixtures/*.json`
- `docs/research/*.md`

## Risks To Keep Visible

1. Canonicalization may become the pacing bottleneck before LP solving does.
2. A poor schema choice can lock the Lean and Python layers into needless translation churn.
3. External LP backends can dominate the trust boundary unless certificate formats are tightened early.
4. Search exhaust can overwhelm the repo unless the tracked versus untracked artifact line stays strict.
