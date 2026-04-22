## Branch Review: research/implement-phase-m1a

Base: main (merge base: 40a44efc)
Commits: 13
Files changed: 15 (2 added, 13 modified, 0 deleted, 0 renamed)
Reviewed through: 6b6c83b

### Summary

This branch ships milestone M1a of the Track A discovery roadmap: it lifts the within-inequality canonicalizer from Python into Lean so that `canonicalize` combines duplicate terms on normalized subsets, sorts by `(cardinality, lex)`, and sign-normalizes. It re-emits the Zhang-Yeung JSON and Lean fixtures through the new pipeline to establish the canonical baseline, adds cross-language parity and regression tests (including a checked-in Python-emitted Lean fixture), and folds in the two review follow-ups (generated parity fixture plus non-normalized-subset coverage). Along the way it swaps `mergeSort` for `insertionSort` in the canonicalizer and replaces almost all `native_decide` proofs with kernel `decide`, leaving exactly one narrowly scoped holdout for a Rat-arithmetic reduction wedge. It also updates the roadmap to wire the sibling `zhang-yeung-inequality` project as an M3 lake dependency and to add an M4 compatibility-theorem deliverable.

### Changes by Area

#### Lean canonicalizer implementation (`NonShannon/Inequality/`)

- `Subsets.lean`: adds `VariableSubset.sortKey`, `sortKeyLe`, `sortKeyLt`, `normalize`, and a `Decidable` instance for `isNormalized`. `normalize` is proved idempotent, with an inline `example` and kernel `decide` smoke test.
- `Vector.lean`: adds `InequalityTerm.addCoefficients`, `insertCombined`, and `combineDuplicates` (normalize subsets, fold-dedup, filter zeros).
- `Canonical.lean`: rewrites `canonicalize` as the three-pass composition specified by the plan. Adds `isCanonicalShape` as a decidable structural predicate and its `Decidable` instance.

#### Zhang-Yeung fixture and Lean mirror

- `NonShannon/Examples/ZhangYeung.lean`: sign-flipped at M1a so the leading coefficient is positive; docstrings updated to describe the new M1a semantics.
- `data/fixtures/zhang-yeung.json`: re-emitted through the M1a canonicalizer (new sign convention and one-index-per-line JSON formatting).
- `docs/research/interchange-format.md`: documents the one-time re-emission.

#### Test coverage (`NonShannonTest/`, `tests/`)

- `NonShannonTest/Inequality/Canonical.lean`: expanded with synthetic vectors for duplicate combination, unsorted input, mixed-order-duplicate input, and a scrambled Zhang-Yeung term list; adds `isCanonicalShape` decidability checks. All proofs use kernel `decide` except one `simp + decide` example for Rat-arithmetic cancellation (with `linter.flexible` scoped off via `set_option ... in`).
- `NonShannonTest/Examples/ZhangYeungFromPython.lean` (new): Python-emitted Lean fixture, kept in sync with the emitter via a byte-for-byte Python golden test.
- `NonShannonTest/Examples/ZhangYeung.lean`: adds the equality check bridging the Python-emitted and hand-written Lean mirrors.
- `tests/test_canonical.py`: adds idempotence, duplicate combination, non-normalized-subset normalization, cross-language term-by-term parity, and JSON round-trip tests.
- `tests/test_emit_lean.py`: adds the byte-for-byte golden test for the generated Lean fixture; updates the rational-coefficient regression to values present after the sign flip.

#### Python canonicalizer (`src/non_shannon_search/canonical.py`)

- Adds `normalize_subset` and calls it before indexing into the duplicate-combination dict. Small, focused change closing the cross-language parity gap on non-normalized inputs.

#### Planning and roadmap

- `docs/plans/done/2026-04-21-m1a-review-followups.md`: the follow-up plan, archived.
- `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`: expanded Section 2.2 (sibling project state), added M3 lake-require deliverable, added M4 `evaluateAt` plus sibling-compatibility theorem deliverables, updated Section 10 accordingly.

#### Supporting tweaks

- `cspell-words.txt`: adds `foldl`, `Nodup`, `preorders`, `reparsed`.

### File Inventory

**New files (2):**

- `NonShannonTest/Examples/ZhangYeungFromPython.lean`
- `docs/plans/done/2026-04-21-m1a-review-followups.md`

**Modified files (13):**

- `NonShannon/Examples/ZhangYeung.lean`
- `NonShannon/Inequality/Canonical.lean`
- `NonShannon/Inequality/Subsets.lean`
- `NonShannon/Inequality/Vector.lean`
- `NonShannonTest/Examples/ZhangYeung.lean`
- `NonShannonTest/Inequality/Canonical.lean`
- `cspell-words.txt`
- `data/fixtures/zhang-yeung.json`
- `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`
- `docs/research/interchange-format.md`
- `src/non_shannon_search/canonical.py`
- `tests/test_canonical.py`
- `tests/test_emit_lean.py`

No files deleted or renamed.

### Notable Changes

- **Canonical baseline reset.** The tracked Zhang-Yeung JSON fixture and Lean mirror are now in the M1a sign convention (leading `[0]` coefficient `1` instead of `-1`), as the plan required at milestone closure.
- **Canonicalizer shape change.** `canonicalize` is no longer definitionally `normalizeSign`. Downstream proofs that relied on that definitional equality have been updated (only one, inside the test module).
- **Reducibility refactor.** `VariableSubset.normalize` and `canonicalize` use `List.insertionSort` rather than `List.mergeSort`, because Lean core's `mergeSort` is well-founded over length-proof subtypes and does not reduce under kernel `decide`. The canonicalization module docstring documents the rationale.
- **No more `native_decide` in the canonical test module.** All example proofs use kernel `decide` except one `simp + decide` example for the Rat-arithmetic cancellation that `decide` cannot reduce through.
- **Roadmap change (scope addition).** The sibling `zhang-yeung-inequality` project is now planned as an M3 lake require, with an M4 compatibility-theorem deliverable (`NonShannon/Inequality/EvaluateAt.lean`, `zhangYeungAveragedScaled_compatible_with_sibling`). This is explicitly labeled as a planning update; no code in this branch consumes the sibling project.

No new dependencies were pulled in. No CI/build config changes. No schema, auth, or security-relevant changes.

### Plan Compliance

**Compliance verdict.** Strong compliance. The branch delivers every item in the M1a plan, closes both review follow-ups, and stays inside the stated scope (`VariableRelabeling` untouched, schema unchanged, M1b/M1c work deferred). The roadmap-update and reducibility-refactor commits are scope additions that are clearly motivated and scoped. The one observable deviation from the M1a plan's "Algorithm" sub-section is the switch from `mergeSort` to `insertionSort`; it is a reasonable, documented reducibility choice, and the plan explicitly allowed either.

**Overall progress.** 6 / 6 items in the M1a plan done (100%). 3 / 3 items in the review follow-up plan done (100%).

**Done items (M1a plan, `docs/plans/done/2026-04-20-m1a-term-normalization.md`):**

1. `VariableSubset.sortKey` and `VariableSubset.normalize` with idempotence — `72f256a`. Also added `sortKeyLe` and `sortKeyLt` beyond what the plan listed, justified by how the canonicalizer and `isCanonicalShape` consume them.
1. `InequalityTerm.addCoefficients` and the list-level duplicate-combining fold — `422b8c2`. Implemented as `insertCombined` plus `combineDuplicates`, both documented.
1. `canonicalize` rewritten as the three-pass composition — `ad47aa0`. Name preserved, no deletions.
1. `NonShannonTest/Inequality/Canonical.lean` extended with idempotence, duplicate-combination, and sort examples — `93ae632`, expanded further in `4bb9207`. The fixture idempotence, the `[0, 2]` duplicate case, the unsorted case, and a synthetic out-of-order vector are all present.
1. `tests/test_canonical.py` extended with idempotence and cross-language parity — `33fdc18`. Adds idempotence, fixed-point, duplicate combination, JSON round trip, and term-by-term parity against the Lean mirror.
1. Regenerate `data/fixtures/zhang-yeung.json`, update `NonShannon/Examples/ZhangYeung.lean`, log in `docs/research/interchange-format.md` — `e157eee`. All three artifacts are consistent after the re-emission.

**Done items (review follow-up plan, `docs/plans/done/2026-04-21-m1a-review-followups.md`):**

1. Generated Lean parity fixture (`NonShannonTest/Examples/ZhangYeungFromPython.lean`) plus equality check against `zhangYeungAveragedScaled.vector` — `2738d37`.
1. Python golden test (`test_generated_zhang_yeung_module_matches_python_emitter`) comparing the emitted source byte-for-byte to the checked-in Lean fixture — `2738d37`.
1. Non-normalized-subset coverage in Lean (`mixedOrderDuplicateVector`, `scrambledZhangYeungVector`) and Python (`test_canonicalize_normalizes_subset_order_before_combining`). The Python side turned up a real bug where `canonicalize_candidate` did not normalize subset order, fixed in `c166513` (`normalize_subset` added to `canonical.py`). The follow-up plan's risks section anticipated this exact decision; the branch took the broader contract option, consistent with the plan.

**Not started items.** None.

**Deviations.**

1. **`List.mergeSort` → `List.insertionSort`** (`4bb9207`). The M1a plan said "fold into a `List (VariableSubset × Rat)` keyed by the normalized subset … sort by the subset key, normalize sign" and noted that `List.mergeSort` is stable. This branch uses `List.insertionSort` instead, with the rationale documented in code and commit message: `mergeSort` does not reduce under kernel `decide`, so the tests would otherwise have to fall back to `native_decide`. This is a strictly better choice for the test suite and the plan's "Open questions" section tacitly anticipated the sort choice being driven by proof convenience. **Assessment: reasonable and justified.**

1. **Roadmap change for M3 lake require and M4 compatibility theorem** (`9571113`). The M1a plan did not contemplate editing the roadmap. The commit does add real scope to M3 and M4 (new `NonShannon/Inequality/EvaluateAt.lean`, new theorem in the Zhang-Yeung module, lakefile changes). However, nothing is implemented in this branch, so the diff is purely planning. The expanded Section 2.2 reflects genuine sibling-project progress (M0-M4 shipped) that the roadmap needed to catch up with. **Assessment: reasonable; correctly scoped as a roadmap update, not smuggled into M1a implementation.**

1. **Replacing `native_decide` with `decide` across the canonical test module** (`4bb9207`, `59596da`). The plan did not call for this. It is a latent technical-debt fix enabled by the `insertionSort` switch, and it leaves exactly one scoped `simp + decide` example (with `linter.flexible` scoped off only over that example). **Assessment: justified and tightly scoped.**

1. **JSON fixture formatting change.** The re-emitted `data/fixtures/zhang-yeung.json` puts each subset index on its own line (old: `"subset": [0, 1]` / new: `"subset": [\n  0,\n  1\n]`). The plan did not specify JSON formatting. This is presumably just `json.dumps` at a default `indent` level; it is consistent with the other fixtures if they share that formatter. **Assessment: cosmetic, not problematic.**

**Fidelity concerns.** None. Each plan item is implemented thoroughly, not minimally. Coverage goes beyond the plan's minimum (the synthetic `mixedOrderDuplicateVector` and `scrambledZhangYeungVector` cases in the Lean test module are explicit stress tests that the plan did not require until the follow-up cycle, and they work).

### Code Quality Assessment

**Overall quality.** Good. The canonicalizer implementation is tight and well-documented, the Lean-Python parity story is now captured by a path (JSON → Python canonicalize → Python emitter → checked-in Lean → Lean equality test) that will fail loudly if anything drifts, and the test module reads as a clear specification of M1a's canonical form. This looks merge-ready.

**Strengths.**

- **Clear cross-language contract.** `canonicalize_candidate` in Python and `canonicalize` in Lean mirror each other pass for pass (normalize → combine → sort → sign), and the docstrings on both sides say so. `test_python_canonical_matches_lean_mirror_terms` and `test_generated_zhang_yeung_module_matches_python_emitter` together with the Lean `example : zhangYeungAveragedScaledFromPython.vector = zhangYeungAveragedScaled.vector := rfl` form a closed loop.
- **Reducibility-first proof choices.** The `insertionSort` swap is the right call. Kernel-decidable `example`s avoid `native_decide`'s trust-boundary concerns and keep proofs deterministic in CI.
- **Honest documentation of the one `native_decide`-shaped holdout.** The `simp + decide` duplicate-combination example's docstring explains why kernel `decide` stalls on `Rat.add` through `Nat.gcd`, why `simp only` loses the Rat-rewrite lemmas, and why `linter.flexible` is scoped off over that one example.
- **`isCanonicalShape` is a good addition.** Having a decidable structural predicate, separate from `isCanonical = canonicalize v = v`, gives downstream callers a way to assert canonical form without invoking the canonicalizer's internals. The `Decidable` instance reduces cleanly and the test module exercises it.
- **Plan discipline.** The review follow-up plan was filed and committed separately, the follow-up work landed in its own commits, and the plan was archived to `done/` at closure. Commit messages are narrative and explain the why.

**Issues to address.** None that are blocking. A few minor items below.

**Suggestions (non-blocking).**

1. **`NonShannonTest/Examples/ZhangYeungFromPython.lean` formatting.** The emitted term list has an unusual indent at the first element: `[            { subset := ... }`. Everything still parses, and the Python golden test guarantees the file stays in sync with the emitter, so the oddness is stable. Still, if the emitter in `src/non_shannon_search/emit_lean.py` is easy to tighten (drop the stray whitespace between `[` and the first `{`), it would make the generated module more readable and match the hand-written Zhang-Yeung mirror's leading-comma style. This is cosmetic.

1. **`InequalityTerm.insertCombined` uses `acc.find?` then `acc.map`.** The two scans are O(n) each and the fold makes the whole duplicate-combination pass O(n²) per vector. Zhang-Yeung has 12 terms and the plan already called out that O(n log n) only matters starting at M1b/M1c. Not worth changing now; worth noting when revisiting performance at M1c. A `HashMap` or `RBMap`-keyed fold would be the natural upgrade.

1. **`isCanonicalShape`'s fourth conjunct.** `(∀ head, vector.terms.head? = some head → 0 ≤ head.coefficient)` is the "leading coefficient nonnegative" invariant, but it is expressed as a forall over an `Option` match. The equivalent `match vector.terms with | [] => True | head :: _ => 0 ≤ head.coefficient` reads more directly and has the same decidability. Minor readability. The current form is fine.

1. **`combineDuplicates` normalizes subsets inside the function, and the Python counterpart normalizes inside `canonicalize_candidate`.** Good. Just worth keeping in mind that callers who call `combineDuplicates` directly on already-normalized inputs pay a second normalization. Not a bug; M1a does not have such callers.

1. **`VariableSubset.normalize_idempotent` is proved, but `canonicalize`'s idempotence is asserted only via `example : canonicalize zhangYeungAveragedScaled.vector = zhangYeungAveragedScaled.vector`, not as a `theorem`.** The plan permits this (the milestone gate is `example`-level), and a general idempotence theorem would require a harder proof than M1a budgeted for. Worth adding on the M1b/M1c side if a downstream proof needs it.

1. **Commit grain.** The plan's suggested commit list has six entries; the branch has thirteen non-doc commits. The extra ones are the `isCanonicalShape`/`insertionSort` refactor, the follow-up plan, the generated fixture, the Python subset-order bug fix, and the roadmap update. All of them are logically separate and individually reviewable, which matches the project's small-commit preference. No concern.

**Potential issues looked for but not found.**

- No `TODO`/`FIXME`/`HACK`/`XXX` markers in the new code.
- No stub implementations or commented-out code.
- No silent failures in the Python canonicalizer; the new `normalize_subset` never raises and preserves the contract of `canonicalize_candidate`.
- No schema or data-migration concerns.
- No security-relevant surface in this diff.

**Completeness.** The branch feels finished. Every public module added in `NonShannon/` has matching coverage in `NonShannonTest/`, and every Python change has matching tests. Docs and the research note are updated. Plan is archived.
