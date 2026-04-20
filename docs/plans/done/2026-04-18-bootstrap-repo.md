# 2026-04-18 Bootstrap Non-Shannon-Inequalities Repo

## Context

This repository currently contains only `LICENSE` and a stub `README.md`. The closest working template is `~/Development/zhang-yeung-inequality`, whose bootstrap surfaces are already in good shape: Lake project wiring, `bin/bootstrap-worktree`, `Makefile`, Lean API tests under a `testDriver`, `AGENTS.md` plus `CLAUDE.md` symlink, text-lint CI, and dated planning documents under `docs/plans/`.

The target scope here is broader than `zhang-yeung-inequality`. This repository is not a single-theorem formalization project. It is the home for Track A of `~/Development/zhang-yeung-inequality/docs/plans/todo/2026-04-17-non-shannon-inequality-discovery-program.md`: discovering candidate non-Shannon inequalities by systematic copy-lemma search, classifying them via a redundancy LP, and validating survivors in Lean.

That difference matters. The new repository needs three coordinated layers from the start:

- A Lean layer for theorem statements, certificate checking, and the curated catalog of validated inequalities.
- An external search layer for enumeration, canonicalization, redundancy checking, and Lean-script emission.
- A documentation and planning layer for references, search architecture, trust boundaries, and milestone tracking.

This plan bootstraps those layers. It does **not** attempt to solve Track A during bootstrap. No parameterized copy lemma proof, LP implementation, or search pass should be attempted in the bootstrap change set.

## Bootstrap Objective

Create a reproducible repository skeleton that lets subsequent work begin immediately on Track A without first revisiting basic repo hygiene or project layout.

Concretely, the bootstrap should leave the repo with:

- a working Lean 4 project pinned to a PFR-compatible toolchain;
- a matching Lean API test library under `testDriver`;
- a Python workspace managed by `uv` for the external search tooling;
- shared interchange formats for candidate inequalities and certificates;
- planning, references, and research notes modeled on the working `zhang-yeung-inequality` conventions;
- CI for Lean, Python, and text surfaces;
- one small end-to-end reference fixture (for example Zhang-Yeung itself) represented in both Lean and Python, purely as a smoke-test artifact.

## In Scope

- General repository scaffolding copied or adapted from `zhang-yeung-inequality`.
- Lean project bootstrap with `PFR` as a direct dependency.
- Python project bootstrap with `uv` and a minimal test/lint setup.
- Track A statement-layer module stubs and shared data-model definitions.
- Planning and research-document surfaces.
- CI, lint, and community files.

## Out of Scope

- Proving the parameterized copy lemma.
- Implementing a complete redundancy LP backend.
- Running a real search over copy-lemma parameter space.
- Importing large search exhaust or solver outputs.
- Writing the first paper manuscript.
- GAP integration for Track B.

## Project Type

Hybrid Lean 4 plus Python research repository.

- **Lean side:** theorem statements, certificate formats, statement-layer validation, curated catalog, future mechanized proofs.
- **Python side:** candidate generation, canonicalization, redundancy checking, and Lean-emission utilities.
- **Shared dependency choice:** keep the permanent PFR dependency discipline from `zhang-yeung-inequality`, because Track A still depends on Shannon entropy, conditional mutual information, and data-processing results in the measure-theoretic random-variable formulation.

## Reference Surfaces To Reuse

| Surface | Action | Notes |
| --- | --- | --- |
| `AGENTS.md` plus `CLAUDE.md` symlink | Copy pattern | Same hub-and-spoke setup as `zhang-yeung-inequality` |
| `lakefile.toml` with `testDriver` | Copy pattern | Use `defaultTargets = ["NonShannon"]`, `testDriver = "NonShannonTest"` |
| `bin/bootstrap-worktree` | Adapt | Keep Mathlib-cache discipline; repo name and main library name change |
| `Makefile` | Adapt | Keep Lean targets; add Python bootstrap, lint, and test targets |
| Lean API regression tests | Copy pattern | Every public module under `NonShannon/` gets a matching `NonShannonTest/` module |
| `.github/workflows/ci.yml` | Adapt | Separate Lean and Python jobs |
| `.github/workflows/text-lint.yml` | Copy | Same reusable markdown plus cspell workflow |
| `docs/plans/{todo,done}/` | Copy pattern | Keep dated plans and archive discipline |
| `references/README.md` | Copy pattern | Bibliography, PDFs, and transcription policy live here |
| `README.md` | Adapt | Explain both the proof layer and the search layer |
| Community files | Copy and rename | `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `.github/SECURITY.md`, PR template |
| New: Python workspace | Add | Not present in the reference repo |
| New: interchange schemas | Add | Needed because Track A crosses Lean and Python boundaries |
| New: generated-artifact policy | Add | Raw search exhaust should not pollute the tracked tree |

## Proposed Repository Shape

```text
non-shannon-inequalities/
  AGENTS.md
  CLAUDE.md -> AGENTS.md
  .editorconfig
  .gitignore
  .markdownlint-cli2.jsonc
  cspell-words.txt
  Makefile
  lakefile.toml
  lake-manifest.json
  lean-toolchain
  pyproject.toml
  uv.lock
  README.md
  bin/
    bootstrap-worktree
  .github/
    copilot-instructions.md
    PULL_REQUEST_TEMPLATE.md
    SECURITY.md
    workflows/
      ci.yml
      text-lint.yml
  NonShannon.lean
  NonShannon/
    Prelude.lean
    Inequality/
      Subsets.lean
      Vector.lean
      Canonical.lean
    Certificate/
      Schema.lean
      Status.lean
    CopyLemma/
      Parameters.lean
      Parameterized.lean
    Catalog.lean
    Examples/
      ZhangYeung.lean
  NonShannonTest.lean
  NonShannonTest/
    Prelude.lean
    Inequality/
      Vector.lean
      Canonical.lean
    Certificate/
      Schema.lean
    CopyLemma/
      Parameters.lean
    Catalog.lean
    Examples/
      ZhangYeung.lean
  src/
    non_shannon_search/
      __init__.py
      cli.py
      canonical.py
      schema.py
      redundancy_lp.py
      emit_lean.py
  tests/
    test_canonical.py
    test_schema.py
  schemas/
    candidate-inequality.schema.json
    redundancy-certificate.schema.json
  data/
    fixtures/
      zhang-yeung.json
  references/
    README.md
    papers/
    transcriptions/
    papers.bib
  docs/
    plans/
      todo/
      done/
    research/
    reviews/
```

The tree above is intentionally minimal. It seeds the main surfaces that later milestones will extend, but it does not pre-create speculative theorem modules for DFZ, Matús, or solver-specific integrations.

## Naming And Structural Decisions

- **Lean namespace:** `NonShannon`
- **Lean test namespace:** `NonShannonTest`
- **Python package name:** `non_shannon_search`
- **Primary bootstrap command:** `make bootstrap`
- **Lean bootstrap script:** `bin/bootstrap-worktree`
- **Tracked fixture policy:** only small, curated fixtures under `data/fixtures/`; large search outputs stay untracked and are ignored in `.gitignore`
- **Interchange format:** JSON files validated against tracked schemas in `schemas/`, mirrored by Lean and Python types
- **Reference inequality for smoke tests:** Zhang-Yeung itself, because it is already formalized in the sibling repo and gives a stable known-good fixture

## Execution Order And Scope

Run the bootstrap in the following order. Each step should land as its own logical commit.

### 0. Establish agent config, planning surfaces, and repo hygiene

Create the same base collaboration surfaces that already work in `zhang-yeung-inequality`:

- `AGENTS.md` as the authoritative project-local instructions file
- `CLAUDE.md` as a symlink to `AGENTS.md`
- `.github/copilot-instructions.md`
- `.editorconfig`
- `.gitignore`
- `.markdownlint-cli2.jsonc`
- `cspell-words.txt`
- `docs/plans/todo/` and `docs/plans/done/`
- `docs/research/` and `docs/reviews/`

The initial `AGENTS.md` should explicitly record three repo-specific facts that differ from the reference repo:

- this repo is hybrid Lean plus Python, not Lean-only;
- `uv` is mandatory for Python-side commands;
- generated search artifacts are mostly untracked and only curated fixtures belong in git.

### 1. Scaffold the Lean project first

Mirror the working Lean bootstrap shape from `zhang-yeung-inequality`.

- Create `lakefile.toml` with:
  - `name = "NonShannon"`
  - `defaultTargets = ["NonShannon"]`
  - `lintDriver = "batteries/runLinter"`
  - `testDriver = "NonShannonTest"`
- Add `PFR` as a direct dependency pinned to a revision compatible with the current Track A work. Start from the same rev used by `zhang-yeung-inequality` unless there is a concrete API mismatch.
- Set `lean-toolchain` to the exact Lean version required by that PFR pin. Do not guess. Check the dependency's current `lean-toolchain` at execution time.
- Track the generated `lake-manifest.json` after the first successful `lake update`.
- Create `NonShannon.lean`, `NonShannon/Prelude.lean`, `NonShannonTest.lean`, and `NonShannonTest/Prelude.lean` as the minimal import surface.
- Keep `autoImplicit = false` and `relaxedAutoImplicit = false`, matching the reference project's discipline.

The goal of this step is not mathematics. The goal is a green `lake build NonShannon`, `lake lint`, and `lake test` in a fresh worktree.

### 2. Reproduce the bootstrap script and Makefile pattern

Add `bin/bootstrap-worktree` by adapting the reference repo's script.

- It should run `lake update`.
- It should run `lake exe cache get`.
- It should verify that Mathlib prebuilt artifacts exist before invoking `lake build`.
- It should build `NonShannon`, not the tests.

Then add a root `Makefile` that extends the reference repo's target set.

- `bootstrap`: run `bin/bootstrap-worktree` and then `uv sync --dev`
- `build`: `lake build NonShannon`
- `test`: `lake test`
- `lean-lint`: `lake lint`
- `py-test`: `uv run pytest`
- `py-lint`: `uv run ruff check .`
- `lint-markdown`: `markdownlint-cli2 "**/*.md"`
- `lint-spelling`: `cspell --no-progress .`
- `lint`: depend on markdown, spelling, and Python lint
- `check`: depend on `lint`, `lean-lint`, `build`, `test`, and `py-test`
- `help`: same auto-doc extraction pattern as the reference repo

Retain the private `_check-mathlib-cache` target from the reference repo and reuse it for `build`, `test`, and `lean-lint`.

### 3. Bootstrap the Python workspace, but keep the solver boundary abstract

Track A requires an external redundancy LP and search driver, but the bootstrap should stop at the interface layer.

Create `pyproject.toml` managed by `uv` with:

- a package named `non-shannon-search`
- source rooted at `src/non_shannon_search/`
- dev dependencies at least for `pytest` and `ruff`
- a console entry point `non-shannon-search` wired to the CLI module
- no heavy mandatory LP backend yet unless one is clearly settled before execution

Track the generated `uv.lock` after the first successful `uv sync --dev`.

Seed these modules:

- `schema.py`: Python mirror of the tracked interchange format
- `canonical.py`: canonicalization helpers over coefficient vectors and variable permutations
- `redundancy_lp.py`: abstract backend interface plus a small placeholder backend that raises a clear `NotImplementedError`
- `emit_lean.py`: a pure-text emitter for future Lean theorem skeletons and fixtures
- `cli.py`: a thin CLI exposing at least `canonicalize` and `validate-schema` commands, even if the backend is still a stub

This step should create a useful developer surface without pretending the solver work is already done.

### 4. Define the interchange format before building algorithms on top of it

Track A only stays sane if Lean and Python agree on what a candidate inequality is.

Create tracked schemas under `schemas/` and mirror them in both languages.

- `candidate-inequality.schema.json`
- `redundancy-certificate.schema.json`

The candidate schema should include at least:

- variable count
- basis / coordinate convention
- normalized coefficient vector
- human label or slug
- provenance metadata
- symmetry-orbit metadata when known
- copy-lemma parameter payload or reference
- current status (`candidate`, `redundant`, `validated`, `rejected`, etc.)

The redundancy-certificate schema should include at least:

- target inequality identifier
- source inequalities used in the combination
- rational coefficients
- backend metadata and version
- whether the certificate is Lean-checkable already or still an external oracle

Mirror those schemas in:

- `NonShannon/Certificate/Schema.lean`
- `NonShannon/Certificate/Status.lean`
- `src/non_shannon_search/schema.py`

This is one of the most important bootstrap-specific steps. It prevents the Lean side and Python side from drifting before any serious search work begins.

### 5. Seed the Track A statement layer in Lean

Create minimal public modules that establish the vocabulary of the project without claiming proofs that do not exist yet.

- `NonShannon/Inequality/Subsets.lean`: subset indexing conventions for entropy coordinates
- `NonShannon/Inequality/Vector.lean`: coefficient-vector representation and normalization helpers
- `NonShannon/Inequality/Canonical.lean`: canonicalization interface and permutation action on inequalities
- `NonShannon/CopyLemma/Parameters.lean`: parameter record describing a Track A copy-lemma instance
- `NonShannon/CopyLemma/Parameterized.lean`: theorem statement placeholders and API shapes for the future `N`-copy lemma layer
- `NonShannon/Catalog.lean`: curated registry entry type for validated inequalities
- `NonShannon/Examples/ZhangYeung.lean`: a single known inequality encoded in the new representation, strictly as a reference fixture

Every module above must land with a matching `NonShannonTest/` module that imports only the public surface and checks it with `example`s.

The bootstrap should stop at simple definitions, structure fields, and basic normalization lemmas. It should not attempt nontrivial proofs beyond what is needed to establish the API surface.

### 6. Seed the first reference fixture across all layers

Create one small tracked fixture for Zhang-Yeung itself and thread it through the stack.

- `data/fixtures/zhang-yeung.json`: canonical JSON representation of the inequality
- `NonShannon/Examples/ZhangYeung.lean`: Lean-side value or theorem-statement wrapper for the same inequality
- `tests/test_schema.py`: round-trip schema validation of the JSON fixture
- `tests/test_canonical.py`: canonicalization smoke test for the same fixture
- `NonShannonTest/Examples/ZhangYeung.lean`: API regression test that the Lean fixture is available under the intended namespace

This gives the repo an immediate cross-language smoke test without requiring any search machinery.

### 7. Add references and research-document surfaces early

The reference repo already demonstrates that planning and source tracking need their own homes. Do the same here.

Create:

- `references/README.md`
- `references/papers/`
- `references/transcriptions/`
- `references/papers.bib`
- `docs/research/track-a-architecture.md`
- `docs/research/interchange-format.md`
- `docs/research/trust-boundary.md`

During bootstrap, seed the bibliography and notes with the papers that Track A directly depends on:

- Zhang and Yeung 1997
- Zhang and Yeung 1998
- Dougherty, Freiling, and Zeger 2006
- Dougherty, Freiling, and Zeger 2011
- Matús 2007 (both ISIT and TIT entries if both are used)
- Chan and Yeung 2002 as background, even though Track B is out of scope here
- Kaced and Romashchenko as context for essential conditional inequalities

The bootstrap pass does not need to complete verified transcriptions. It only needs the directories, bibliography discipline, and the first note files.

### 8. Create the repo-local roadmap that follows this bootstrap

Once the surfaces above exist, create a second dated planning document dedicated to the actual Track A execution plan inside this repo.

Recommended path:

- `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`

That roadmap should break Track A into repo-local milestones such as:

- M0: repo scaffolding and shared schemas
- M1: inequality representation and canonicalization
- M2: parameterized copy-lemma statement layer
- M3: redundancy-certificate interface and oracle boundary
- M4: reproduction of known inequalities (Zhang-Yeung, DFZ, first Matús cases)
- M5: search over bounded parameter families
- M6: validated catalog and paper-facing outputs

Do **not** fold that roadmap into this bootstrap plan. Keep the bootstrap plan bounded and execution-oriented.

### 9. Add CI modeled on the reference repo, with one extra language job

Create two workflow files under `.github/workflows/`.

- `ci.yml`
- `text-lint.yml`

`text-lint.yml` can be copied almost verbatim from `zhang-yeung-inequality`.

`ci.yml` should have separate jobs:

- **Lean job:** checkout, cache elan, run `leanprover/lean-action`, then `lake lint` and `lake test`
- **Python job:** install `uv`, run `uv sync --dev`, then `uv run ruff check .` and `uv run pytest`

Keep docs-only markdown and license changes out of the Lean and Python jobs via `paths-ignore` if that remains convenient, but let `text-lint.yml` run on all pushes and PRs.

### 10. Add the community and contributor surfaces

Mirror the reference repo's community files, adapted for this repository's mixed toolchain.

- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `.github/SECURITY.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

`CONTRIBUTING.md` should mention both bootstrap paths:

- `make bootstrap` for full setup
- `bin/bootstrap-worktree` for Lean-only setup when the Python surface is not needed yet

It should also explain the tracked versus untracked artifact rule for search outputs.

### 11. Expand `README.md` last

Keep the execution order from the reference bootstrap plan: write the full README only after the toolchain, module names, and commands are settled.

The README should contain, in this order:

1. Project title and one-sentence summary
2. Short explanation of non-Shannon inequality discovery and Track A
3. Status table for the first repo-local milestones
4. Architecture summary: Lean layer, Python layer, shared schemas
5. Build and verification commands
6. References and related papers
7. AI assistance statement
8. License

The README should link to the new repo-local Track A roadmap once that file exists.

## Files To Create Or Rewrite During Bootstrap

### Root and config

- `AGENTS.md`
- `CLAUDE.md` (symlink)
- `.editorconfig`
- `.gitignore`
- `.markdownlint-cli2.jsonc`
- `cspell-words.txt`
- `Makefile`
- `lakefile.toml`
- `lake-manifest.json`
- `lean-toolchain`
- `pyproject.toml`
- `uv.lock`
- `README.md`

### Scripts and workflows

- `bin/bootstrap-worktree`
- `.github/copilot-instructions.md`
- `.github/workflows/ci.yml`
- `.github/workflows/text-lint.yml`

### Lean library and tests

- `NonShannon.lean`
- `NonShannon/Prelude.lean`
- `NonShannon/Inequality/Subsets.lean`
- `NonShannon/Inequality/Vector.lean`
- `NonShannon/Inequality/Canonical.lean`
- `NonShannon/Certificate/Schema.lean`
- `NonShannon/Certificate/Status.lean`
- `NonShannon/CopyLemma/Parameters.lean`
- `NonShannon/CopyLemma/Parameterized.lean`
- `NonShannon/Catalog.lean`
- `NonShannon/Examples/ZhangYeung.lean`
- `NonShannonTest.lean`
- `NonShannonTest/Prelude.lean`
- `NonShannonTest/Inequality/Vector.lean`
- `NonShannonTest/Inequality/Canonical.lean`
- `NonShannonTest/Certificate/Schema.lean`
- `NonShannonTest/CopyLemma/Parameters.lean`
- `NonShannonTest/Catalog.lean`
- `NonShannonTest/Examples/ZhangYeung.lean`

### Python workspace

- `src/non_shannon_search/__init__.py`
- `src/non_shannon_search/cli.py`
- `src/non_shannon_search/canonical.py`
- `src/non_shannon_search/schema.py`
- `src/non_shannon_search/redundancy_lp.py`
- `src/non_shannon_search/emit_lean.py`
- `tests/test_schema.py`
- `tests/test_canonical.py`

### Shared schemas and fixtures

- `schemas/candidate-inequality.schema.json`
- `schemas/redundancy-certificate.schema.json`
- `data/fixtures/zhang-yeung.json`

### Documentation and planning

- `references/README.md`
- `references/papers.bib`
- `docs/research/track-a-architecture.md`
- `docs/research/interchange-format.md`
- `docs/research/trust-boundary.md`
- `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `.github/SECURITY.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

## Commit Strategy

Use frequent small commits, following the same discipline as the reference repo. Proposed sequence:

1. `chore: adopt repo scaffolding and agent config surfaces`
2. `build: scaffold Lean project with testDriver bootstrap`
3. `build: add uv-managed Python workspace and Makefile targets`
4. `feat: add shared inequality and certificate schemas`
5. `feat: seed Track A statement-layer modules and fixture`
6. `docs: add references, research notes, and Track A roadmap`
7. `ci: add Lean, Python, and text lint workflows`
8. `docs: add community files and expand README`

All commits should remain small enough that each one leaves the repository in a usable state.

## Verification

Bootstrap is complete only when all of the following are true:

- `readlink CLAUDE.md` resolves to `AGENTS.md`
- `bin/bootstrap-worktree` succeeds in a fresh worktree
- `make bootstrap` succeeds
- `make build` succeeds
- `make test` succeeds
- `make py-test` succeeds
- `make lint` succeeds
- `make check` succeeds
- `uv run non-shannon-search validate-schema data/fixtures/zhang-yeung.json` succeeds
- `uv run non-shannon-search canonicalize data/fixtures/zhang-yeung.json` succeeds
- `lake test` exercises the `NonShannonTest` library, not just the main library
- the Zhang-Yeung fixture is available in both Lean and Python without reaching into implementation internals
- the README links resolve to `AGENTS.md`, `CONTRIBUTING.md`, `references/`, and the repo-local Track A roadmap

## Explicit Deferrals After Bootstrap

These are the first follow-on tasks, but they should not be folded into bootstrap itself:

- prove the parameterized copy lemma
- design the first Lean-checkable redundancy certificate format in detail
- implement a concrete LP backend and benchmark scaling
- reproduce the six DFZ inequalities as the first validation suite
- design symmetry reduction for the copy-lemma parameter space
- add automated Lean proof-term emission rather than theorem skeleton emission

## Why This Shape Is The Right Adaptation

The value of `zhang-yeung-inequality` is not just that it is a Lean repo. Its real value as a template is that it already solved the boring but important problems: how to bootstrap a fresh worktree, how to keep tests separate from the main library, how to organize dated plans, and how to keep documentation and CI from drifting.

This bootstrap plan preserves those proven surfaces, but changes the project core from "one theorem formalization" to "search plus certification infrastructure". The added Python workspace, shared schemas, and tracked fixture policy are the essential adaptations that Track A requires.
