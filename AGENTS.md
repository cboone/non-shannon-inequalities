# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Overview

`non-shannon-inequalities` is a hybrid Lean 4 plus Python research repository for discovering, classifying, and validating non-Shannon information inequalities. The Lean side owns theorem statements, certificate shapes, and curated validated artifacts. The Python side owns enumeration, canonicalization, schema validation, and external-oracle integration.

## Build Commands

```bash
bin/bootstrap-worktree         # mandatory first-time Lean setup (lake update + cache + build)
make bootstrap                 # Lean bootstrap plus uv sync --dev
lake build NonShannon          # build the main Lean library
lake test                      # run the NonShannonTest example suite
lake lint                      # run batteries/runLinter over the NonShannon library
make build                     # guarded lake build NonShannon
make test                      # guarded lake test
make lean-lint                 # guarded lake lint
make py-lint                   # ruff over the Python search tooling
make py-test                   # pytest over the Python search tooling
make lint                      # markdownlint-cli2 + cspell + ruff
make check                     # lint + lean-lint + build + test + py-test
```

Full local check: `make check`.

## Fresh Clone / Worktree Bootstrap

In a fresh clone or worktree, run:

```bash
bin/bootstrap-worktree
```

This is mandatory in every fresh clone or worktree. The script runs `lake update`, downloads prebuilt dependency artifacts with `lake exe cache get`, verifies that Mathlib's prebuilt artifacts exist, and only then runs `lake build NonShannon`. Never bootstrap by running `lake build` directly in a clean worktree or clone. Mathlib must always come from downloaded prebuilt artifacts, not a local source compilation.

## Repository Shape

- `NonShannon.lean`: project entrypoint for the Lean library
- `NonShannon/Prelude.lean`: import surface for PFR's entropy API plus basic shared types
- `NonShannon/Inequality/*.lean`: inequality representation and canonicalization vocabulary
- `NonShannon/Certificate/*.lean`: statement-layer certificate schemas and statuses
- `NonShannon/CopyLemma/*.lean`: parameter-space definitions and future generalized copy-lemma surface
- `NonShannon/Catalog.lean`: catalog entry types for curated inequalities
- `NonShannon/Examples/ZhangYeung.lean`: reference fixture for the Zhang-Yeung inequality
- `NonShannonTest.lean`: top-level re-export for Lean API tests
- `NonShannonTest/**/*.lean`: compile-time API regression tests mirroring the public surface
- `docs/plans/{todo,done}/`: dated planning surfaces
- `docs/research/`: research notes about architecture, schemas, and trust boundaries

## Namespace Convention

Flat under `NonShannon` for now. New Lean files go under `NonShannon/` and new test files go under `NonShannonTest/` with a 1:1 filename mirror.

## Top-Level Namespace

`NonShannon`

## Lean Conventions

- Tab size: 2 spaces (no hard tabs)
- Unicode: standard Lean 4 unicode symbols when useful
- `autoImplicit = false`, `relaxedAutoImplicit = false`
- Final newline in all files; trim trailing whitespace
- Follow existing proof style in this repo once the initial modules exist

### Skill And Workflow

Invoke the `write-lean-code` skill before any Lean edit, read-for-review, or planning discussion. When changing public Lean APIs, update the matching `NonShannonTest/` module in the same change.

### Testing Discipline

Every public module added in `NonShannon/` must land with a matching module under `NonShannonTest/` that imports only the public surface and proves API-level `example`s against it. `lake test` must continue to pass; the `testDriver` is `NonShannonTest`, and `defaultTargets = ["NonShannon"]` so `lake build` and `lake test` stay semantically distinct.

## Python Workflow

The Python tooling layer is managed with `uv`. Use `uv` for Python commands, not `python3` or `pip`. Large generated search artifacts do not belong in git; only curated small fixtures under `data/fixtures/` should be tracked.

Python sources live under `src/non_shannon_search/`, with tests under `tests/` and tracked interchange schemas under `schemas/`.

## Vendored Lean Dependencies

Exclude from style searches everything under `.lake/packages/`. Valid Lean style references are: (1) this project's own code under `NonShannon/`, then (2) Mathlib under `.lake/packages/mathlib/` when available.

## Key Files

- `lakefile.toml`: Lake project config for `NonShannon` and `NonShannonTest`
- `lean-toolchain`: pinned Lean version
- `Makefile`: guarded Lean build, lint, test, and check targets
- `bin/bootstrap-worktree`: bootstrap script for fresh worktrees
