<!-- SPDX-FileCopyrightText: 2026 Christopher Boone -->
<!-- SPDX-License-Identifier: CC-BY-4.0 -->

# Non-Shannon Inequalities

A hybrid Lean 4 plus Python research repository for discovering, classifying, and validating non-Shannon information inequalities.

The immediate focus is Track A from the sibling `zhang-yeung-inequality` project: enumerate copy-lemma-guided candidate inequalities, canonicalize and classify them externally, and move stable survivors into a Lean-facing catalog and certificate pipeline.

## Status

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

Small curated fixtures live under [`data/fixtures/`](data/fixtures/). Large generated search exhaust should remain untracked.

## Build And Verify

Fresh clone or worktree:

```bash
make bootstrap
```

Day-to-day commands:

```bash
make build      # lake build NonShannon
make test       # lake test
make lean-lint  # lake lint
make py-lint    # uv run ruff check .
make py-test    # uv run pytest
make lint       # markdownlint-cli2 + cspell + ruff
make check      # lint + lean-lint + build + test + py-test
```

CLI smoke tests:

```bash
uv run non-shannon-search validate-schema data/fixtures/zhang-yeung.json
uv run non-shannon-search canonicalize data/fixtures/zhang-yeung.json
```

See [`AGENTS.md`](AGENTS.md) for project-local conventions and [`CONTRIBUTING.md`](CONTRIBUTING.md) for contribution workflow.

## Research Notes

- [`docs/research/track-a-architecture.md`](docs/research/track-a-architecture.md)
- [`docs/research/interchange-format.md`](docs/research/interchange-format.md)
- [`docs/research/trust-boundary.md`](docs/research/trust-boundary.md)
- [`docs/plans/todo/2026-04-18-bootstrap-non-shannon-inequalities-repo.md`](docs/plans/todo/2026-04-18-bootstrap-non-shannon-inequalities-repo.md)

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

Lean code is licensed under [Apache 2.0](./LICENSES/Apache-2.0.txt).
Python code and development artifacts are licensed under [MIT](./LICENSES/MIT.txt).
Most repository prose and mathematical exposition are licensed under [CC BY 4.0](./LICENSES/CC-BY-4.0.txt).
[`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) is adapted from Contributor Covenant and is licensed under [CC BY-SA 4.0](./LICENSES/CC-BY-SA-4.0.txt).

See [`NOTICE`](./NOTICE) and the per-file SPDX identifiers for the authoritative mixed-license breakdown.
