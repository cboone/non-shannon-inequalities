# Branch Review: research/m2-parameterized-copy-lemma

Base: `main` (merge base `b72f71a`)
Commits: 6
Files changed: 9 (3 added, 6 modified, 0 deleted, 0 renamed)
Reviewed through: `a415f53`
Reviewed on: 2026-04-24

## Summary

This branch lands milestone M2 of the Track A Discovery Roadmap: the parameterized copy-lemma statement layer. It removes the M0 placeholder (`parameterizedCopyLemma`, `parameterizedCopyLemmaSpec`, `ParameterizedCopyLemmaShape`) and replaces it with a typed `CopyLemmaStatement` record built on a new `CopyBlock`, a layered `IsCanonical` / `IsWellFormed` invariant pair on `CopyParameters`, a scoped `relabel` action that threads `VariableRelabeling` through both sides, and the characterization lemma `sameStatementShape_iff_ofParameters_sameShape` bridging parameter-level and statement-level equivalence. A new research note freezes the naming conventions and statement shape.

## Changes by Area

**Lean library (`NonShannon/CopyLemma/`).**

- `Parameters.lean` gains `ConditionalIndependencePattern.relabel`, `VariableSubset.Disjoint` (with a hand-rolled `Decidable` instance lifted from `List.Disjoint`), `CopyParameterShape` and `statementShape`, two layered predicates `IsCanonical` and `IsWellFormed` with `Decidable` instances constructed by nested `by_cases`, a scoped `CopyParameters.relabel`, preservation lemmas (`actOnSubset_isNormalized`, `actOnSubset_Disjoint`, `relabel_IsCanonical`, `relabel_IsWellFormed`, `relabel_variableCount`, `statementShape_relabel`), and `CopyParameters.SameStatementShape`.
- `Parameterized.lean` gains `CopyBlock`, `CopyLemmaStatement`, the derived `copies` view, `relabel`, `relabel_variableCount`, `inducedIndependence`, `ofParameters`, `inducedIndependence_relabel`, `ofParameters_relabel`, `SameShape`, two private bridge lemmas (`ofParameters_eq_of_statementShape_eq` and `statementShape_eq_of_ofParameters_eq`), and the public characterization theorem. `ParameterizedCopyLemmaTarget` is retained with an expanded struct-level docstring.

**Tests (`NonShannonTest/CopyLemma/`).**

- `Parameters.lean` replaces the single placeholder `example` with four: `copyCount = 2`, `IsWellFormed` by `decide`, `IsCanonical` via `IsWellFormed.toIsCanonical`, and `IsWellFormed` preserved under the identity relabeling.
- New `Parameterized.lean` module with ten `example`s covering `ofParameters` field-by-field, the derived `copies` view, the commuting square at `swap 4 0 1`, the bridge theorem on a zero-copy self-fixture, `IsCanonical` on distinct fixtures, a negative `SameStatementShape` case with mismatched `copyCount`, a metadata-only-variant positive case, and two `String.startsWith` checks on a `ParameterizedCopyLemmaTarget`.

**Documentation.**

- New `docs/research/copy-lemma-naming.md` (111 lines) with theorem-name and module-name templates, the frozen statement-shape snapshot, the induced independence rule, the `IsCanonical` / `IsWellFormed` split, the structural projection, and a future-changes policy.
- New `docs/plans/todo/2026-04-23-m2-copy-lemma-statement-layer.md` (308 lines) with the elaborated implementation plan and an extensive "Open questions and risks" section.
- `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md` is tightened: the M2 summary, deliverables, testing approach, checkpoint gate, and file inventory now match the plan's specific decisions, and the repo-shape diagram updates `Parameterized.lean`'s one-line description.

**Build configuration.**

- `NonShannonTest.lean` re-exports the new test module.
- `cspell-words.txt` gains `componentwise`, `elementwise`, and `formedness`, one word per committed commit that introduced it.

## File Inventory

- **New files (3):**
  - `NonShannonTest/CopyLemma/Parameterized.lean`
  - `docs/plans/todo/2026-04-23-m2-copy-lemma-statement-layer.md`
  - `docs/research/copy-lemma-naming.md`
- **Modified files (6):**
  - `NonShannon/CopyLemma/Parameterized.lean`
  - `NonShannon/CopyLemma/Parameters.lean`
  - `NonShannonTest.lean`
  - `NonShannonTest/CopyLemma/Parameters.lean`
  - `cspell-words.txt`
  - `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`
- **Deleted files (0):** none, though `parameterizedCopyLemma` and its aliases were removed from inside `Parameterized.lean`.
- **Renamed files (0):** none.

## Notable Changes

- **Removed public API.** The placeholder symbols `parameterizedCopyLemma`, `parameterizedCopyLemmaSpec`, and `ParameterizedCopyLemmaShape` are gone. This is an intentional milestone deliverable, not a breaking change for downstream milestones, because the M0 promise was explicitly a bootstrap-only stable name.
- **New frozen convention surface.** `docs/research/copy-lemma-naming.md` freezes both naming templates and the statement-shape snapshot. The roadmap and research note together treat the shape as load-bearing for M3 and M5, which matches the "statement shape frozen" checkpoint gate.
- **No schema, fixture, Python, or dependency changes.** M2 stays entirely inside the Lean statement layer and its research note, as the plan explicitly committed to.

## Plan Compliance

**Compliance verdict: strong, with three minor fidelity deviations.** Every Goal item and every Execution-order step is landed, `make check` is fully green (verified: 20 markdown files linted, 60 cspell files, `ruff` clean, `lake lint` clean, 2794 jobs built, 61 Python tests passing, `lake test` passing), and the roadmap update matches the plan. Deviations are either literal vs spiritual substitutions (all within the plan's stated latitude) or structural refinements of the proof.

**Overall progress: 12 / 12 execution steps done (100%).**

**Done items (in execution order).**

1. Extend `Parameters.lean` with `VariableSubset.Disjoint`, `ConditionalIndependencePattern.relabel`, `CopyParameterShape`, `statementShape`, `IsCanonical`, `IsWellFormed`, `CopyParameters.relabel`, and preservation lemmas. Landed in commit `cc5090a`. All six declarations are present; `VariableSubset.Disjoint` is lifted from `List.Disjoint` as specified. The `Decidable` instance is constructed by an explicit nested `by_cases` rather than deriving; semantically equivalent.
1. Add `CopyBlock` and `CopyLemmaStatement` to `Parameterized.lean` with `copyPrototype`, `copyCount`, and `independence`; no stored `copies` field. Derived `DecidableEq` and `Inhabited`. Landed in commit `48859d2` at lines 10-33.
1. Define `CopyLemmaStatement.relabel` through `actOnSubset` and prove `inducedIndependence_relabel`. Landed at lines 37-77.
1. Define `inducedIndependence` and `ofParameters`. Landed at lines 54-69.
1. Remove `parameterizedCopyLemmaSpec`, `ParameterizedCopyLemmaShape`, and `parameterizedCopyLemma`; expand the docstring on `ParameterizedCopyLemmaTarget`. Confirmed via `git diff`; the per-field docstrings are preserved.
1. Prove `ofParameters_relabel`. Landed at lines 80-85, discharged uniformly by `simp` across all three target fields, which chains through `inducedIndependence_relabel` implicitly via the unfolding.
1. State and prove `sameStatementShape_iff_ofParameters_sameShape` with `IsCanonical` hypotheses on both sides. Landed at lines 110-131. See "Fidelity concerns" below: the proof structure is simpler than the plan anticipated.
1. Update `NonShannonTest/CopyLemma/Parameters.lean` with the three replacement examples. Landed at lines 21-28, plus the retained `copyCount = 2` example.
1. Add `NonShannonTest/CopyLemma/Parameterized.lean` with the eight enumerated examples. Landed at lines 59-99. See "Deviations" below for one test-shape substitution.
1. Wire the new module into `NonShannonTest.lean`. Landed at line 8, in alphabetical order with the existing imports.
1. Write `docs/research/copy-lemma-naming.md` per Approach section 6. Landed (111 lines, well within the "roughly 80 to 120 lines" target).
1. Tighten the roadmap's M2 entry. Landed via the diff above: summary, deliverables, testing approach, checkpoint gate, file-inventory table, and repo-shape diagram are all updated in place; the plan-file pointer now names the concrete file rather than `<date>-...`.

**Partially done items:** none.

**Not started items:** none.

**Deviations.**

1. **Proof strength of the bridge theorem exceeds the plan.** The plan (Approach section 4, lines 198-205) motivates the `IsCanonical` hypotheses via a normalization-uniqueness argument: "each of `frozen`, `copyPrototype.copied`, and `copyPrototype.conditioning` is stored separately on `CopyLemmaStatement` and normalized independently by `actOnSubset`, so the in-range and normalization invariants of `IsCanonical` are sufficient for the uniqueness-of-normalized-representatives argument supplied by `VariableSubset.eq_of_isNormalized_of_mem_iff`." The actual proof at lines 110-131 does not use `VariableSubset.eq_of_isNormalized_of_mem_iff` at all. Instead, it observes that `CopyLemmaStatement.ofParameters` is *structurally injective* on the statement shape (via the two private helpers `ofParameters_eq_of_statementShape_eq` and `statementShape_eq_of_ofParameters_eq`, each discharged by `cases ... rfl`). This reduces the bridge to a pair of rewrites. The `IsCanonical` hypotheses are therefore genuinely unused in the proof body, which the file flags explicitly with `cases hFirst; cases hSecond` (structurally eliminating the predicates) and an `attribute [nolint unusedArguments]` declaration. **Assessment: reasonable deviation, with one concern.** The deviation strengthens the theorem: `sameStatementShape_iff_ofParameters_sameShape` is true unconditionally on `CopyParameters`. Keeping `IsCanonical` in the signature is a deliberate choice documented in the theorem's docstring ("The canonical hypotheses record the intended M2 invariant boundary; the projection itself stores all statement-bearing fields directly"), and it matches how M5 search will call the lemma. The concern is whether this should instead ship as a stronger unconditional lemma with a canonical-only wrapper, so future readers do not assume the hypotheses are load-bearing.
1. **Negative test fixture differs from the plan's example.** The plan (Execution step 9, line 242) names "mismatched `frozen` cardinalities" as the structural difference. The actual test at lines 82-89 uses mismatched `copyCount` instead. **Assessment: spirit-compliant.** The plan's own parenthetical allows "any other structural difference no relabeling can repair"; `copyCount` is one such field because it is untouched by `relabel`. The test still catches a degenerate `SameStatementShape` that always returned `True`.
1. **Commit decomposition is coarser than the plan's strategy.** The plan (Commit strategy, lines 279-286) lists six commits in a specific ordering (three `feat(lean)` commits, one `test(lean)`, one `docs(research)`, one `docs(plans)`). The actual branch lands two `feat(lean)` commits with tests bundled in (`cc5090a` bundles `Parameters.lean` library plus tests; `48859d2` bundles `Parameterized.lean` library plus tests plus placeholder removal), one `docs(research)` commit, and the roadmap tightening appears to have been folded into one of the earlier commits rather than shipped as its own. **Assessment: reasonable deviation.** Each individual commit leaves `make check` green (the key invariant the plan called out), and bundling the test alongside the library change makes each commit atomically reviewable, which is a stronger property than the plan required. The roadmap tightening should ideally be a separate commit for traceability; this is a very mild nit.

**Fidelity concerns.**

1. **Bridge theorem signature carries unused hypotheses.** See deviation 1. Signals an intentionally documented gap between the stated API and the proof obligation. Worth revisiting at M3/M5 if a stronger unconditional lemma would simplify call sites.
1. **Decidability instances are not derived from Mathlib.** `CopyParameters.IsCanonical` and `IsWellFormed` use nested `by_cases` (lines 104-124 and 136-150 of `Parameters.lean`) rather than any `deriving Decidable` or `instance ... := inferInstance` pattern. The approach is correct and the resulting predicates `decide` cleanly in tests, but the proof text is verbose (around twenty lines each). **Assessment: minor.** A more concise form is possible (for example `and_iff_left_of_imp` chains or a `Decidable.decEq`-style factoring), but the current form is auditable line by line and makes the structural content explicit, which has value in a foundational module. Not a correctness concern.
1. **`sameStatementShape_iff_ofParameters_sameShape` test at line 80 only exercises self-equivalence on `zeroCopyParams`.** The plan (Execution step 9, line 241) called for "a concrete `IsCanonical` pair, including a `copyCount = 0` fixture." Self-pairing is technically an `IsCanonical` pair, but a pair of distinct parameters related by a non-trivial relabeling would exercise the nontrivial direction of the iff. The negative case at lines 82-89 and the metadata-only case at lines 91-93 together provide some coverage, but none of them actually chain through the bridge theorem. **Assessment: mild test-depth gap.** Not a blocker; the commuting square test at lines 71-74 exercises the spirit of the forward direction without invoking the bridge.

## Code Quality Assessment

**Overall quality: ready to merge.** The code is clean, idiomatic, well-documented, and lints clean. The proofs are short, structured, and avoid heavy automation where a structural argument suffices. The test module is self-contained, does not reach into internals, and uses `decide` and `rfl` wherever the underlying data is fully concrete.

**Strengths.**

- **Docstring coverage is complete.** Every new top-level declaration in both `Parameters.lean` and `Parameterized.lean` carries a `/-- ... -/` docstring. Per-field docstrings are also provided on every new record field, which the existing module convention in `CopyParameters` established.
- **Scope-equality threading is consistent.** Every `relabel` definition takes the scope-equality hypothesis as a named `_hScope : relabeling.variableCount = _.variableCount` argument and carries `@[nolint unusedArguments]` because the body is independent of the proof term. This matches how `actOnVector` threads it in `NonShannon/Inequality/Symmetry.lean`. Consumers can discharge it with `rfl` on concrete fixtures, as the tests demonstrate.
- **The two private helpers in `Parameterized.lean`** (`ofParameters_eq_of_statementShape_eq`, `statementShape_eq_of_ofParameters_eq`, lines 93-107) are genuinely private, not accidentally public. Each is discharged by `cases ... rfl` in three lines. Good factoring.
- **Test mirroring invariant is preserved.** `NonShannon/CopyLemma/Parameters.lean` is mirrored by `NonShannonTest/CopyLemma/Parameters.lean`, and the new `NonShannon/CopyLemma/Parameterized.lean` is mirrored by `NonShannonTest/CopyLemma/Parameterized.lean`. `NonShannonTest.lean` imports both, keeping the re-export surface coherent.
- **Research note is scoped and actionable.** `docs/research/copy-lemma-naming.md` stays tight (111 lines), uses fenced Lean blocks to freeze the struct shape verbatim, and ends with an explicit "Future Changes" policy that names who has to update what on a refactor. This matches the milestone convention for freeze documents.
- **Cspell additions are minimal and scoped.** Exactly three new words (`componentwise`, `elementwise`, `formedness`), each legitimately technical and specific to the content added.

**Issues to address.**

- None are blocking. Items below are all suggestions.

**Suggestions (non-blocking).**

- **Consider splitting the bridge theorem into an unconditional core and an `IsCanonical`-wrapped alias.** The current signature carries vestigial hypotheses. A pattern like `theorem CopyParameters.sameStatementShape_iff_ofParameters_sameShape_core {first second : CopyParameters} : ...` proved unconditionally, with `CopyParameters.sameStatementShape_iff_ofParameters_sameShape` as a thin wrapper taking the canonical hypotheses to ease M5 call sites, would document the gap explicitly in the API rather than inside a docstring plus a `nolint` attribute. Not urgent, but worth considering before M3 lands and cites the theorem.
- **Consider tightening the `Decidable` instances.** The `by_cases` stacks in `Parameters.lean` lines 104-124 and 136-150 could be rewritten with `And.decidable`-style propagation or by synthesizing from the component instances via a structure-builder. Current form is correct and inspectable; replacement would shorten the file by about thirty lines.
- **Consider adding one more bridge-theorem test.** An `example` that exhibits two distinct `IsCanonical` parameter sets related by `VariableRelabeling.swap 4 0 1` and closes `sameStatementShape_iff_ofParameters_sameShape` through the bridge in its nontrivial direction would round out the test file. This matches the implied spirit of Execution step 9 item (e).
- **Consider promoting `ofParameters_relabel` to `@[simp]`.** It already has the shape of a commuting-square rewrite rule, and if M3 or M5 hit it repeatedly, an explicit `simp` tag would avoid needing to name it. The plan does not mention this and it is strictly a future ergonomic concern.

**Completeness.**

- No TODO, FIXME, HACK, or XXX markers are present in the new code.
- No stub implementations, placeholder values, or commented-out code.
- New features have matching `NonShannonTest/` modules per the project's testing discipline (stated in `CLAUDE.md`: "Every public module added in `NonShannon/` must land with a matching module under `NonShannonTest/`").
- No APIs need documentation updates; the new APIs *are* the documentation target, and `docs/research/copy-lemma-naming.md` captures them.
