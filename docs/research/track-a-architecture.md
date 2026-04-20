# Track A Architecture

Track A has three cooperating layers.

## Lean Layer

The Lean layer owns public statement shapes, certificate mirrors, and the curated catalog of known or validated inequalities. Its immediate job is not to search. Its job is to define the objects that later proofs and imported certificates must satisfy.

Current Lean surfaces:

- `NonShannon/Inequality/`: subset and vector vocabulary
- `NonShannon/Certificate/`: candidate and certificate schemas
- `NonShannon/CopyLemma/`: parameter-space vocabulary for future generalized copy-lemma theorems
- `NonShannon/Examples/ZhangYeung.lean`: bootstrap reference fixture

## Python Layer

The Python layer owns search-oriented mechanics that are awkward or premature to implement in Lean:

- canonicalization of sparse coefficient vectors
- schema validation for interchange files
- redundancy-LP backend interfaces
- future Lean emission helpers

This layer is intentionally backend-agnostic during bootstrap. The LP boundary is represented explicitly, but no concrete solver is committed yet.

## Shared Schema Layer

The repo uses tracked JSON schemas under `schemas/` as the contract between Lean, Python, and any future external tools. The first two tracked objects are:

- `candidate-inequality.schema.json`
- `redundancy-certificate.schema.json`

These schemas are mirrored in both `NonShannon/Certificate/Schema.lean` and `src/non_shannon_search/schema.py`.

## Initial Data Flow

1. A candidate inequality fixture is stored as JSON under `data/fixtures/`.
2. Python validates the JSON against the tracked schema.
3. Python canonicalizes the sparse term list into a stable ordering and sign convention.
4. Lean exposes a parallel statement-layer representation for catalog and proof work.
5. Future search tooling can emit additional candidate fixtures without inventing a new interchange format.
