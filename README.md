<!-- SPDX-FileCopyrightText: 2026 Christopher Boone -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Non-Shannon Inequalities

A hybrid Lean 4 plus Python research repository for discovering, classifying, and validating non-Shannon information inequalities.

The immediate focus is Track A from the sibling `zhang-yeung-inequality` project: enumerate copy-lemma-guided candidate inequalities, canonicalize and classify them externally, and move stable survivors into a Lean-facing catalog and certificate pipeline.

In practical terms, this repository currently provides the statement and schema surfaces needed to represent candidate inequalities, validate interchange artifacts, canonicalize sparse expressions, and seed curated Lean fixtures such as Zhang-Yeung.

## Current Scope

Today the repository supports three closely related workflows:

- describe inequality and certificate objects in Lean
- validate and canonicalize candidate artifacts with the Python CLI
- move stable, externally checked survivors into curated fixtures and catalog-facing structures

The next major step is bounded search over copy-lemma parameter families, followed by a validated catalog and paper-facing outputs.

## Quick Start

### Prerequisites

- Lean 4 toolchain (version pinned in `lean-toolchain`)
- Lake (bundled with Lean)
- `zsh` for `bin/bootstrap-worktree`
- Python 3.11
- `uv`
- `markdownlint-cli2` and `cspell` for full text linting

### Fresh Clone Or Worktree

Bootstrap Lean dependencies and download Mathlib's prebuilt artifacts:

```bash
bin/bootstrap-worktree
```

This is the mandatory first step in a fresh clone or worktree. It runs `lake update`, `lake exe cache get`, verifies that Mathlib's prebuilt artifacts are present, and then builds `NonShannon`.

### Full Development Setup

Set up both the Lean and Python environments:

```bash
make bootstrap
```

`make bootstrap` runs `bin/bootstrap-worktree` and then `uv sync --dev`.

## Common Development Commands

```bash
make build      # lake build NonShannon
make test       # lake test
make lean-lint  # lake lint
make py-lint    # uv run ruff check .
make py-test    # uv run pytest
make lint       # markdownlint-cli2 + cspell + ruff
make check      # lint + lean-lint + build + test + py-test
```

For a full local verification pass before opening a pull request, run `make check`.

## CLI Example

The Python package in this repository exposes the `non-shannon-search` CLI for schema and canonicalization workflows.

Validate the Zhang-Yeung fixture against the tracked JSON schema:

```bash
uv run non-shannon-search validate-schema data/fixtures/zhang-yeung.json
```

Canonicalize the same fixture into the repository's sparse-term normal form:

```bash
uv run non-shannon-search canonicalize data/fixtures/zhang-yeung.json
```

## Repository Map

- [`NonShannon/`](NonShannon/) contains the Lean library
- [`NonShannonTest/`](NonShannonTest/) contains compile-time API regression tests that mirror the public Lean surface
- [`src/non_shannon_search/`](src/non_shannon_search/) contains the Python search and interchange tooling
- [`schemas/`](schemas/) contains tracked interchange schemas shared across the Lean and Python layers
- [`data/fixtures/`](data/fixtures/) contains small curated fixtures; large generated search exhaust should remain untracked
- [`docs/research/`](docs/research/) contains architecture, interchange, and trust-boundary notes
- [`docs/plans/todo/`](docs/plans/todo/) contains active repo-local planning documents

Public Lean modules under `NonShannon/` should land with a matching `NonShannonTest/` module that exercises the exported API with `example` checks.

## Architecture

The repository has three cooperating layers.

### Lean Layer

Lean owns theorem-facing object shapes, certificate mirrors, and curated catalog entries.

Current public surfaces include:

- [`NonShannon/Inequality/`](NonShannon/Inequality/) for subset and sparse vector vocabulary
- [`NonShannon/Certificate/`](NonShannon/Certificate/) for candidate and redundancy-certificate mirrors
- [`NonShannon/CopyLemma/`](NonShannon/CopyLemma/) for parameterized copy-lemma statement shapes
- [`NonShannon/Examples/ZhangYeung.lean`](NonShannon/Examples/ZhangYeung.lean) for the bootstrap reference fixture

### Python Layer

Python owns search-oriented tooling under [`src/non_shannon_search/`](src/non_shannon_search/):

- schema validation
- sparse-term canonicalization
- future redundancy-LP backend integration
- Lean fixture emission helpers

### Shared Schemas

The contract between the two layers lives under [`schemas/`](schemas/):

- [`candidate-inequality.schema.json`](schemas/candidate-inequality.schema.json)
- [`redundancy-certificate.schema.json`](schemas/redundancy-certificate.schema.json)

## Status And Roadmap

| Milestone | Focus | State |
| --- | --- | --- |
| M0 | Repository scaffold and shared schemas | done |
| M1 | Inequality representation and canonicalization | bootstrap surface landed |
| M2 | Parameterized copy-lemma statement layer | bootstrap surface landed |
| M3 | Redundancy-certificate oracle boundary | bootstrap surface landed |
| M4 | Known-inequality reproduction | Zhang-Yeung reference fixture seeded |
| M5 | Bounded search over parameter families | planned |
| M6 | Validated catalog and paper-facing outputs | planned |

The active repo-local roadmap is [`docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`](docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md).

## Research Notes

- [`docs/research/track-a-architecture.md`](docs/research/track-a-architecture.md)
- [`docs/research/interchange-format.md`](docs/research/interchange-format.md)
- [`docs/research/trust-boundary.md`](docs/research/trust-boundary.md)
- [`docs/plans/todo/2026-04-18-bootstrap-non-shannon-inequalities-repo.md`](docs/plans/todo/2026-04-18-bootstrap-non-shannon-inequalities-repo.md)

## Contributing And Conventions

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for development workflow, setup notes, and pull request expectations.

See [`AGENTS.md`](AGENTS.md) for project-local conventions, especially Lean module layout, test mirroring, and bootstrap requirements.

## References

The shared bibliography and source-material layout live under [`references/`](references/). The canonical bibliography for documentation and Lean docstrings is [`references/papers.bib`](references/papers.bib).

The initial Track A bibliography covers:

- Zhang and Yeung's first non-Shannon inequalities (`zhangyeung1997`, `zhangyeung1998`)
- Dougherty, Freiling, and Zeger's DFZ inequalities and survey (`doughertyfreilingzeger2006`, `doughertyfreilingzeger2011`)
- Matús's infinite-family and non-polyhedrality papers (`matus2007isit`, `matus2007tit`)
- Chan and Yeung on the group-theoretic correspondence (`chanyeung2002`)
- Kaced and Romashchenko on conditional information inequalities (`kacedromashchenko2013`)

## AI Statement

This formalization is being completed with substantial assistance from Opus 4.6 + 4.7 and GPT 5.4, through [`claude`](https://claude.com/claude-code) and [`opencode`](https://opencode.ai), and [GitHub Copilot](https://github.com/features/copilot).

## License

Copyright 2026 Christopher Boone.

This repository carries REUSE-style mixed-license coverage:

- Lean code under [Apache 2.0](./LICENSES/Apache-2.0.txt).
- Other substantive code — Python under `src/` and `tests/`, the `bin/bootstrap-worktree` shell script — under [MIT](./LICENSES/MIT.txt).
- Project-authored prose (READMEs, agent configs, planning, research notes, bibliography, this README, the NOTICE) under [CC BY 4.0](./LICENSES/CC-BY-4.0.txt).
- [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md), adapted from Contributor Covenant, under [CC BY-SA 4.0](./LICENSES/CC-BY-SA-4.0.txt).
- Hand-authored infrastructure config and data (Makefile, `lakefile.toml`, `pyproject.toml`, YAML, JSONC, dotfiles, cspell word list, JSON schemas, fixture data) under MIT via the root `REUSE.toml` config-group annotation.
- Generated artifacts (`lake-manifest.json`, `lean-toolchain`, `uv.lock`) dedicated to the public domain under [CC0 1.0](./LICENSES/CC0-1.0.txt) via the `REUSE.toml` generated-group annotation.
- Bundled third-party reference material under `references/papers/**` and `references/transcriptions/**` under [`LicenseRef-Reference-Material`](./LICENSES/LicenseRef-Reference-Material.txt); copyright remains with original authors and publishers.

See [`NOTICE`](./NOTICE) and the combination of per-file SPDX headers plus root [`REUSE.toml`](./REUSE.toml) annotations for the authoritative coverage. See <https://reuse.software/> for tooling.
