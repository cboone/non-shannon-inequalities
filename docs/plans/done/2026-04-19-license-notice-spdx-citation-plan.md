# 2026-04-19 License, Notice, SPDX, and Citation Plan

## Context

The repository now declares project licensing in `README.md`, with license texts under `LICENSES/`. The repo does not yet have a `NOTICE` file and does not yet have repo-wide SPDX coverage.

There is already a tracked bibliography at `references/papers.bib`, and the current source or paper references appear primarily in:

- `NonShannon/Examples/ZhangYeung.lean`
- `data/fixtures/zhang-yeung.json`
- `README.md`
- `references/README.md`

Current REUSE baseline:

- `reuse lint` reports missing copyright and license information across the tracked repo.
- `reuse lint` also reports `LICENSES/APACHE-2.0.txt` as a bad license filename, because the SPDX identifier is `Apache-2.0`.

## Objective

Add a top-level `NOTICE`, make the tracked repository files REUSE-compliant under the intended mixed-license split, keep `references/papers.bib` as the canonical documentation bibliography, and attach explicit citations to mathematically substantive content without changing the mathematical APIs or search pipeline semantics.

## Coverage Rules

Recommended repo-wide coverage rule:

- `Apache-2.0` for Lean code.
- `MIT` for Python code and development artifacts, including build tooling, schemas, fixtures, workflows, lockfiles, and machine-readable project artifacts that are part of the software development surface.
- `CC-BY-4.0` for prose, planning documents, research notes, contribution and policy docs, bibliography files, and explanatory mathematical exposition.
- The `LICENSES/` directory remains the canonical store of full license texts.
- Per-file SPDX identifiers are the authoritative source of truth in a mixed-license repo. `NOTICE` should summarize, not override, those tags.

This rule needs to be made explicit in the implementation, because the current `README.md` needs to distinguish Lean code, Python plus development artifacts, and prose clearly before bulk annotation begins.

## Implementation Plan

### 1. Normalize the license-text surface first

1. Rename `LICENSES/APACHE-2.0.txt` to `LICENSES/Apache-2.0.txt` so the license filename matches the SPDX identifier.
2. Add `LICENSES/MIT.txt`, because MIT will now be referenced by SPDX tags across Python and development-artifact files.
3. Update in-repo links that point at the uppercase Apache filename or otherwise fail to mention MIT, especially the license section in `README.md`.
4. Re-run `reuse lint` immediately after the rename and MIT addition to confirm that the bad-license error is gone before doing bulk annotation.

Why this comes first:

- Every later `Apache-2.0` SPDX tag will continue to fail REUSE validation until the license filename is corrected.
- Every later `MIT` SPDX tag will fail REUSE validation until the MIT license text is present under `LICENSES/`.

### 2. Add `NOTICE`

Create a top-level `NOTICE` that:

- names the project;
- records the project copyright;
- explains that the repository contains material under multiple licenses;
- states that Lean code is under `Apache-2.0`;
- states that Python code and development artifacts are under `MIT`;
- states that prose and mathematical exposition are under `CC-BY-4.0`;
- points readers to `LICENSES/Apache-2.0.txt`, `LICENSES/MIT.txt`, `LICENSES/CC-BY-4.0.txt`, and the per-file SPDX tags.

Important wording constraint:

- `NOTICE` must not imply that every tracked file is under one software license. In this repo, the SPDX tags need to remain the authoritative per-file signal.

### 3. Keep `references/papers.bib` canonical and clean it up

1. Keep `references/papers.bib` as the canonical bibliography for documentation and Lean docstring citations.
2. Clean up and enrich the existing entries instead of splitting bibliography ownership across directories.
3. Ensure the file contains at least the papers already named or implied by current repo content: `zhangyeung1997`, `zhangyeung1998`, `doughertyfreilingzeger2006`, `doughertyfreilingzeger2011`, `matus2007isit`, `matus2007tit`, `chanyeung2002`, and `kacedromashchenko2013`.
4. Add missing bibliographic detail where readily available and appropriate, such as publishers, venues, page ranges, DOIs, or stable archive identifiers.
5. Add any additional entry that becomes necessary for the copy-lemma surfaces, but only once a specific source has been chosen.

Documentation follow-through:

- Update `README.md`, `references/README.md`, and any other in-repo pointers so they consistently describe `references/papers.bib` as the shared documentation bibliography.
- Remove any plan text or implementation fallout that assumes a future `docs/references.bib`.

Recommended outcome:

- `references/papers.bib` remains the single canonical docs bibliography.
- No parallel `docs/references.bib` is introduced.

### 4. Add SPDX coverage by file class

Use inline SPDX headers when the format safely supports comments and REUSE can parse the comment style. Use `.license` sidecars for generated files, comment-hostile formats, placeholder files, or files where inline headers would create tool churn.

Recommended inline `Apache-2.0` coverage:

- `NonShannon.lean`
- `NonShannon/**/*.lean`
- `NonShannonTest.lean`
- `NonShannonTest/**/*.lean`

Recommended inline `MIT` coverage:

- `src/non_shannon_search/**/*.py`
- `tests/**/*.py`
- `bin/bootstrap-worktree`
- `Makefile`
- `lakefile.toml`
- `pyproject.toml`
- `.github/workflows/*.yml`
- `.editorconfig`
- `.gitignore`
- `.markdownlint-cli2.jsonc`
- `cspell.jsonc`

Recommended inline `CC-BY-4.0` coverage:

- `README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/SECURITY.md`
- `.github/copilot-instructions.md`
- `.github/python.instructions.md`
- `docs/plans/todo/*.md`
- `docs/research/*.md`
- `references/README.md`
- `references/papers.bib`

Recommended `.license` sidecar coverage:

- `schemas/*.json`
- `data/fixtures/*.json`
- `lake-manifest.json`
- `uv.lock`
- `lean-toolchain`
- `cspell-words.txt` if an inline header would interfere with cspell parsing
- `docs/reviews/.gitkeep`
- `references/papers/.gitkeep`
- `references/transcriptions/.gitkeep`
- `docs/plans/done` if it is kept as an extensionless Markdown-like file instead of being renamed to `docs/plans/done.md`
- `NOTICE` if an extensionless plain-text format makes inline SPDX awkward

Recommended `.license` sidecar license assignments:

- `MIT` for JSON, lockfile, toolchain, and development-placeholder surfaces
- `CC-BY-4.0` for `NOTICE` if it is treated as explanatory prose instead of a software-artifact summary

Implementation note:

- Include both `SPDX-FileCopyrightText` and `SPDX-License-Identifier`.
- Prefer `reuse annotate` for batch-safe insertion on recognized file types.
- Prefer `reuse annotate --force-dot-license` for files that should use sidecars.

### 5. Add citations only where the math or provenance is substantive

Do not add literature citations to purely structural or plumbing docstrings. Add them where the file defines a paper-derived object, states a mathematical result, or preserves research provenance that a reader would reasonably want to trace.

First-pass citation targets:

1. `NonShannon/Examples/ZhangYeung.lean`: expand the docstring on `zhangYeungAveragedScaled` to identify the Zhang-Yeung source explicitly and cite `zhangyeung1998`, including the equation reference already present in the provenance field. Optionally add a shorter source-oriented docstring note on `zhangYeungCatalogEntry`.
2. `README.md`: add citations where the text names Zhang-Yeung, DFZ, Matús, Chan-Yeung, or Kaced-Romashchenko as specific mathematical background, rather than leaving those references as bare names.
3. `docs/research/track-a-architecture.md`: cite papers only where the architecture note makes mathematically meaningful source claims, not for generic repository-structure description.
4. `docs/research/interchange-format.md`: keep this mostly uncited unless it explicitly ties a design choice to a paper-derived mathematical object.
5. `docs/research/trust-boundary.md`: cite only if a claim depends on a particular paper or theorem, not for general software-trust discussion.
6. `NonShannon/CopyLemma/Parameters.lean` and `NonShannon/CopyLemma/Parameterized.lean`: add citations only if the chosen source actually backs the generalized copy-lemma surface used here; otherwise defer rather than cite loosely.

Lean docstring style target:

- use narrative docstrings rather than citation-only stubs;
- explain what mathematical object or result is being represented;
- add a `## References` section when a theorem, definition, or fixture is directly paper-derived;
- use stable bibliography keys from `references/papers.bib`.

Non-goal for this pass:

- Do not extend the JSON schema solely to add machine-readable citation keys unless the repo intentionally wants citation-bearing interchange artifacts.

### 6. Handle tool and documentation fallout

1. Update any text that mentions the old Apache filename or any obsolete bibliography-location plan.
2. Decide whether `references/papers.bib` should remain ignored by spelling checks. Keep the current ignore unless there is a clear reason to lint BibTeX fields.
3. Add only the minimum new words to `cspell-words.txt` if some cited names still need to remain visible to cspell.

### 7. Verify end to end

Verification sequence:

1. `reuse lint`
2. `make lint`
3. `make check`

Success criteria:

- `reuse lint` reports no bad license filenames and no missing copyright or license coverage for tracked files;
- `NOTICE` exists and accurately describes the mixed-license layout;
- every tracked file is covered either inline or by a `.license` sidecar;
- `references/papers.bib` contains every paper actually cited in documentation or Lean docstrings;
- citations appear in mathematically substantive places, with `NonShannon/Examples/ZhangYeung.lean` as the minimum required Lean example.

## Risks And Decisions To Keep Explicit

1. The current README must explicitly assign MIT to Python code and development artifacts before bulk-tagging those files.
2. Introducing a second docs bibliography would create drift. Keep `references/papers.bib` canonical.
3. The copy-lemma surfaces should not get placeholder citations. Only cite them once the source choice is explicit.
4. Sidecar coverage is preferable for generated or extensionless files even if inline comments are technically possible.
