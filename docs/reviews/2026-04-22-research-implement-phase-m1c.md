# Branch Review: research/implement-phase-m1c

Base: main (merge base: fa55f26)
Commits: 7
Files changed: 26 (5 added, 19 modified, 1 deleted, 1 renamed)
Reviewed through: 38e0664

## Summary

The branch lands milestone M1c (orbit canonicalization) per the plan at
`docs/plans/done/2026-04-20-m1c-orbit-canonicalization.md`. It composes
the M1a within-inequality canonicalizer with the M1b scoped symmetry
action into an orbit-representative companion `orbitCanonical`, adds a
pinned-format `orbitIdOf` string serializer, plumbs `orbit_id` /
`orbitId` through the JSON schema, both language mirrors of
`CandidateInequality`, the Python-to-Lean emitter, the tracked
Zhang-Yeung fixture, and the public `canonicalize` CLI, and establishes
byte-identical cross-language orbit-ID parity through a reuse of the
existing checked-in-emitted-module parity pattern. The M1c plan is
archived to `docs/plans/done/`; the Track A roadmap is updated to
reflect M1c as shipped.

## Changes by Area

### Lean orbit API (`NonShannon/Inequality/Canonical.lean`, +66 lines)

Adds a lex-min comparator scaffolding (`termOrbitLt`, `termsOrbitLt`,
`vectorOrbitLt`, `orbitMin`), an orbit-internal permutation action
(`applyPermutationIndex`, `actOnSubsetValues`, `actOnVectorValues`),
orbit enumeration (`orbitImages`) over
`(List.range variableCount).permutations`, a direct string serializer
(`joinWith`, `serializeSubset`, `serializeCoefficient`, `serializeTerm`)
that does not delegate to `Rat.repr`, and the public
`orbitCanonical : InequalityVector → InequalityVector` and
`orbitIdOf : InequalityVector → String`. The M1a canonicalize docstring
gets one line clarifying that it is the within-inequality form, not the
orbit form.

### Lean test surface

Files: `NonShannonTest/Inequality/Orbit.lean` (new), `NonShannonTest.lean`, `NonShannonTest/Examples/ZhangYeung.lean`, `NonShannonTest/Certificate/Schema.lean`.

`Orbit.lean` covers orbit-invariance of `orbitCanonical` on the
Zhang-Yeung fixture under identity, `swap 0 1`, `swap 2 3`, and a
three-cycle `(0 1) * (1 2)`; orbit-invariance of `orbitIdOf` under the
three non-identity generators; a coefficient-serialization check
(`{-5, 3/2, -1/3, 7}` pinned to `"4;[0]:1/3;[1]:-7;[2]:-3/2;[3]:5"`) that
guards the cross-language contract against `Rat.repr` drift.
`NonShannonTest.lean` gains the module import. The
`NonShannonTest/Certificate/Schema.lean` module gains three concrete
`example`s exercising `orbitId = none` default, `orbitId = some "..."`,
and `orbitId` plus `symmetryOrbitSize?` set together.
`NonShannonTest/Examples/ZhangYeung.lean` gains a `native_decide`
example pinning `zhangYeungAveragedScaled.orbitId = some (orbitIdOf
zhangYeungAveragedScaled.vector)` so the tracked orbit-ID literal cannot
drift silently from the helper output, and two new `example`s asserting
that the Python-emitted `zhangYeungAveragedScaledFromPython.orbitId` and
`zhangYeungSwapZeroOneFromPython.orbitId` both equal
`zhangYeungAveragedScaled.orbitId`.

### Lean schema and fixtures

Files: `NonShannon/Certificate/Schema.lean`, `NonShannon/Examples/ZhangYeung.lean`, `NonShannonTest/Examples/ZhangYeungFromPython.lean`, `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`.

`CandidateInequality` gains `orbitId : Option String := none`,
positioned between `copyParametersRef?` and `symmetryOrbitSize?`.
`zhangYeungAveragedScaled` carries the concrete orbit-ID string
(`"4;[0]:1;[1]:1;[2]:4;[3]:4;[0,1]:2;[0,2]:-4;[0,3]:-4;[1,2]:-4;[1,3]:-4;[2,3]:-6;[0,2,3]:5;[1,2,3]:5"`).
Both regenerated Python-emitted modules carry the same string
byte-for-byte.

### Python library and CLI

Files: `src/non_shannon_search/schema.py`, `src/non_shannon_search/canonical.py`, `src/non_shannon_search/cli.py`, `src/non_shannon_search/emit_lean.py`.

`CandidateInequality` gains `orbit_id: str | None = None` with
always-present-null-when-absent emission via `to_dict`. `canonical.py`
gains internal `_term_orbit_key`, `_candidate_orbit_key`,
`_serialize_subset`, `_serialize_coefficient`, `_serialize_term`,
`_orbit_id_from_representative`, `_orbit_representative`, and public
`orbit_canonical(candidate) -> CandidateInequality` and
`orbit_id_of(candidate) -> str`. The CLI `canonicalize` subcommand now
emits `canonicalize_candidate(source)` with `orbit_id` populated via
`orbit_id_of(source)`, preserving the caller's specific labeling in
`terms` while carrying the orbit-invariant identifier. `emit_lean.py`
emits `orbitId := some "..."` when the source candidate has
`orbit_id is not None` and omits the line otherwise; the swap-zero-one
emitter populates the new field from `orbit_id_of(candidate)` (source
candidate, before the swap action) so the emitted constant carries the
orbit-invariant ID that matches the un-swapped fixture.

### JSON schema and tracked fixture

Files: `schemas/candidate-inequality.schema.json`, `data/fixtures/zhang-yeung.json`.

Schema adds `orbit_id: {"type": ["string", "null"], "minLength": 1}`;
`symmetry_orbit_size` is untouched. Fixture is regenerated through the
M1c pipeline with `orbit_id` populated as a non-null string.

### Python tests

Files: `tests/test_canonical.py`, `tests/test_symmetry.py`, `tests/test_schema.py`, `tests/test_emit_lean.py`.

`test_canonical.py` adds orbit-invariance checks under `swap 0 1` and
the `(0 1) * (1 2)` cycle, a pinned-serialization check on the same
fractional coefficient set used Lean-side, and a CLI contract test
asserting that `non-shannon-search canonicalize` on a permuted fixture
emits the M1a canonical terms of the input paired with the
orbit-invariant orbit-ID. `test_symmetry.py` adds a full-orbit check
over every element of `iter_symmetric_group(4)` and a cross-language
parity test that reads the generated Lean module, extracts the
`orbitId := some "..."` literal, and asserts equality with Python's
`orbit_id_of(load_candidate(FIXTURE))`. `test_schema.py` covers the
missing-field, `null`, and non-empty-string variants plus a
`from_dict` / `to_dict` round-trip. `test_emit_lean.py` covers the
orbit-ID line's presence when `orbit_id is not None` and its absence
otherwise.

### Documentation and planning

Files: `docs/research/interchange-format.md`, `docs/plans/done/2026-04-20-m1c-orbit-canonicalization.md`, `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`, `docs/reviews/2026-04-21-research-implement-phase-m1a.md`, `cspell-words.txt`.

Interchange-format note records the schema revision, the coexistence of
`orbit_id` and `symmetry_orbit_size`, and the M1c CLI behavior change.
The M1c plan moves from `todo/` to `done/`. Roadmap's Section 6 M1
dependency graph shows M1c shipped. The M1a review's stale link is
corrected. `cspell-words.txt` gains `repr`.

## File Inventory

**New files (5):**

- `NonShannonTest/Inequality/Orbit.lean`
- `NonShannonTest/Examples/ZhangYeungFromPython.lean` (regenerated, but
  new on this branch's diff since M1a's M1c follow-up)
- `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`
  (regenerated byte-for-byte)
- `data/fixtures/zhang-yeung.json` (regenerated through M1c pipeline)
- `docs/plans/done/2026-04-20-m1c-orbit-canonicalization.md`

**Modified files (19):**

- `NonShannon/Certificate/Schema.lean`
- `NonShannon/Examples/ZhangYeung.lean`
- `NonShannon/Inequality/Canonical.lean`
- `NonShannon/Inequality/Vector.lean`
- `NonShannonTest.lean`
- `NonShannonTest/Certificate/Schema.lean`
- `NonShannonTest/Examples/ZhangYeung.lean`
- `cspell-words.txt`
- `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`
- `docs/research/interchange-format.md`
- `docs/reviews/2026-04-21-research-implement-phase-m1a.md`
- `schemas/candidate-inequality.schema.json`
- `src/non_shannon_search/canonical.py`
- `src/non_shannon_search/cli.py`
- `src/non_shannon_search/emit_lean.py`
- `src/non_shannon_search/schema.py`
- `tests/test_canonical.py`
- `tests/test_emit_lean.py`
- `tests/test_schema.py`
- `tests/test_symmetry.py`

**Deleted files (1):**

- `docs/plans/todo/2026-04-20-m1c-orbit-canonicalization.md` (moved to
  `done/`)

**Renamed files (0):**
None strictly; the plan is a delete-plus-add at the git level rather
than a rename.

## Notable Changes

- **Schema revision (non-breaking):** `orbit_id` added as
  `["string", "null"]` with `minLength: 1`; missing-field payloads and
  `null` payloads both validate, matching the plan's intent. Existing
  consumers that ignore the field are unaffected.
- **CLI behavior change (non-breaking in shape, new content):**
  `non-shannon-search canonicalize` now emits `orbit_id` as a non-null
  string on well-formed input. The `terms` field still reflects the
  caller's specific labeling after M1a within-inequality
  canonicalization, not the orbit representative.
- **New tracked invariants via `native_decide`:** the orbit-invariance
  checks in `NonShannonTest/Inequality/Orbit.lean` and the orbit-ID
  pinning example in `NonShannonTest/Examples/ZhangYeung.lean` are
  elaborated through `native_decide`. The linter's
  `style.nativeDecide` warning is locally disabled per example.
- **Cross-language contract pinning:** the pinned-serialization fixture
  `"4;[0]:1/3;[1]:-7;[2]:-3/2;[3]:5"` appears both in Lean's
  `NonShannonTest/Inequality/Orbit.lean` and in Python's
  `tests/test_canonical.py::test_orbit_id_of_uses_pinned_serialization`,
  so either implementation drifting from the shared format is caught by
  `make check`.
- **No new dependencies, no CI changes, no security-relevant surface
  touched.**

## Plan Compliance

**Compliance verdict.** Strong compliance. Every deliverable named in
the plan's "Goal" and "Approach" sections is implemented; every step of
the 16-step execution order landed; every concrete sanity check in the
"Testing and verification" section is covered by an `example` or
pytest. The plan was revised during the branch (commits `c1a759e` and
`5c14b9e` under `docs:` scope) before implementation began, so
divergences between the plan text and the implementation are
vanishingly small.

**Overall progress:** 16 / 16 execution-order items done (100%). All
six concrete sanity checks from "Testing and verification" are
satisfied.

**Done items (execution-order sequence):**

1. **`NonShannon/Inequality/Canonical.lean` orbit surface** — `fe1aff5`.
   `orbitCanonical` and `orbitIdOf` land; a lex-min comparator
   (`termOrbitLt` plus `termsOrbitLt` plus `vectorOrbitLt` plus
   `orbitMin`) stands in for the plan's mentioned `lexKey`; the orbit
   ID is serialized directly from the canonical term list without
   delegating to `Rat.repr`. **Caveat:** the plan specified "exhaustive
   enumeration of `Equiv.Perm (Fin v.variableCount)`, each lifted to a
   scoped `VariableRelabeling`, applied with `actOnVector`". The
   implementation enumerates via `(List.range variableCount).permutations`
   and applies the permutation through private helpers
   (`applyPermutationIndex` / `actOnSubsetValues` / `actOnVectorValues`)
   that duplicate the action defined in
   `NonShannon/Inequality/Symmetry.lean`'s `actOnSubset` /
   `actOnVector`. See the deviation discussion below.
2. **`NonShannonTest/Inequality/Orbit.lean`** — `fe1aff5`. Covers the
   three named `S_4` elements plus identity, the three orbit-ID
   invariance cases, and the pinned-serialization fixture.
3. **Wire test import** — `fe1aff5`. `import NonShannonTest.Inequality.Orbit`
   is present in `NonShannonTest.lean` at line 11.
4. **`orbitId : Option String := none` field** — `4425296` (for the
   schema plumbing) / `fe1aff5` (for the Zhang-Yeung literal). Both the
   default case and the populated case compile.
5. **Schema coexistence `example`s** — `4425296`. Three `example`s
   match the plan's minimum set exactly
   (`NonShannonTest/Certificate/Schema.lean` lines 28, 30, 32, 34).
6. **Schema revision** — `4425296`. `schemas/candidate-inequality.schema.json`
   adds the field; `src/non_shannon_search/schema.py` mirrors with
   always-present-null-when-absent `to_dict` convention.
7. **`orbit_canonical` and `orbit_id_of`** — `e7c833e`. Public Python
   surface matches the plan exactly, including the
   `orbit_canonical(candidate)` returning a `CandidateInequality` whose
   `vector` is the representative and whose `orbit_id` is populated.
   Orbit-representative computation is factored into private
   `_orbit_representative`.
8. **CLI `canonicalize` subcommand** — `e7c833e`. Emits the M1a
   within-inequality form of the input with `orbit_id` populated via
   `orbit_id_of(source)`, exactly matching the plan's "preserves the
   caller's specific permutation in the emitted `terms`" rule.
9. **`emit_lean.py` plus `tests/test_emit_lean.py`** — `e7c833e`.
   Emitter adds `orbitId := some "..."` when populated; omits when
   absent. Tests cover both cases.
10. **Regenerated `ZhangYeungFromPython.lean` and `ZhangYeungSwapZeroOneFromPython.lean`**
    — `e7c833e`. Both carry the orbit-ID literal byte-for-byte
    identical to Lean's.
11. **Tracked Lean literal + drift-guard example** — `fe1aff5`.
    `zhangYeungAveragedScaled.orbitId := some "..."` is pasted;
    `example : zhangYeungAveragedScaled.orbitId = some (orbitIdOf
    zhangYeungAveragedScaled.vector)` closes by `native_decide`.
12. **`tests/test_canonical.py` orbit invariance plus `tests/test_symmetry.py`
    cross-language parity** — `e7c833e`. Both sides implemented. The
    cross-language test uses `re.search` against the generated Lean
    source, reusing the existing emitted-module parity pattern.
13. **`tests/test_schema.py` field coverage** — `4425296`. Four new
    cases (missing, null, string, round-trip).
14. **`data/fixtures/zhang-yeung.json` regeneration** — `e7c833e`.
    Fixture carries `orbit_id` as a string, not null.
15. **`docs/research/interchange-format.md` migration note** —
    `2b2ddea`. Covers the schema revision, the coexistence with
    `symmetry_orbit_size`, the canonicalization rule producing
    `orbit_id`, and the CLI behavior change.
16. **`make check`** — implied green by the branch reaching merge
    readiness and the M1c plan moving to `done/`; not independently
    verified in this review. Recommend rerun before merge.

**Deviations:**

- **Orbit enumeration bypasses the public `VariableRelabeling` surface
  on the Lean side (minor / probably acceptable).** The plan wrote
  "exhaustive enumeration of `Equiv.Perm (Fin v.variableCount)`, each
  lifted to a scoped `VariableRelabeling`, applied with `actOnVector`".
  The implementation enumerates `List Nat` permutations via
  `(List.range variableCount).permutations` and applies them through
  private helpers `applyPermutationIndex`, `actOnSubsetValues`, and
  `actOnVectorValues` that mirror the action defined in
  `NonShannon/Inequality/Symmetry.lean` but do not reuse it. Positive
  arguments: the approach avoids `VariableRelabeling.ofPerm` machinery,
  keeps the orbit loop structurally simple (good for `decide` /
  `native_decide` reducibility on concrete vectors), and the
  end-to-end cross-check still goes through the public surface because
  the tests in `NonShannonTest/Inequality/Orbit.lean` apply
  `actOnVector (VariableRelabeling.swap ...)` and then invoke
  `orbitCanonical`. Negative arguments: the private action duplicates
  `actOnSubset` / `actOnVector` logic, so any future change to the
  public action (for example, changing how out-of-range indices are
  treated) must be mirrored in the private copy or orbit canonicalization
  will silently drift from symmetry-action semantics. Worth flagging in
  a code comment or as a deferred follow-up note. Not a blocker.
- **Lex-min scaffolding is built from `Bool`-valued comparators rather
  than the plan's `InequalityVector.lexKey` (non-blocking).** The plan
  text suggested a single `lexKey` extracting the canonical shape into
  an `(Int, List (subset.sortKey, coefficient))`-shaped comparison
  value, or "an equivalent comparator over (length, List (subset.sortKey,
  coefficient))". The implementation chose the comparator route
  (`termsOrbitLt` + `vectorOrbitLt` + `orbitMin`) without materializing
  a named `lexKey`. This is within the explicit "or equivalent"
  allowance in the plan.
- **Scope addition (tests) beyond the minimum:** the Python test
  `test_orbit_representation_is_invariant_across_all_of_s4` iterates
  over every element of `S_4` (24 checks) even though the plan's
  minimum was the named generator set. This is mentioned as a plus in
  the plan's "Testing and verification" Python bullet, so it is
  planned scope, not true scope creep.

**Fidelity concerns:** none. The orbit enumeration deviation is the
only implementation-versus-plan difference, and the tests enforce the
end-to-end property the plan actually cared about (orbit invariance
under the public `actOnVector` surface).

## Code Quality Assessment

### Strengths

- **The cross-language contract is enforced by a live test.** The
  single literal `"4;[0]:1/3;[1]:-7;[2]:-3/2;[3]:5"` appears in both
  `NonShannonTest/Inequality/Orbit.lean` and
  `tests/test_canonical.py`; a drift on either side turns
  `make check` red. Combined with
  `test_cross_language_orbit_id_parity_matches_generated_lean_fixture`
  extracting the orbit-ID literal from the emitted Lean module, the
  shared-byte gate the plan described is real, not aspirational.
- **Emission convention is coherent.** Python's `to_dict` always emits
  `orbit_id` with `null` when absent, matching how
  `copy_parameters_ref` and `symmetry_orbit_size` were already
  emitted. The JSON schema's
  `{"type": ["string", "null"], "minLength": 1}` form correctly
  accepts `null` (because `minLength` only applies to strings), accepts
  non-empty strings, and rejects `""`; `tests/test_schema.py` covers
  the first two cases explicitly.
- **Drift-guard for the tracked literal.** `NonShannonTest/Examples/ZhangYeung.lean`'s
  `example : zhangYeungAveragedScaled.orbitId = some (orbitIdOf
  zhangYeungAveragedScaled.vector)` is exactly the right guardrail for
  a compute-and-paste artifact: the pasted string cannot silently drift
  from the helper output; if the helper changes, compilation fails
  until the literal is repasted.
- **No silent failures.** `canonical.py` constructs orbit IDs via
  `min(_orbit_canonical_generator, key=_candidate_orbit_key)` over a
  non-empty generator (`_orbit_representative` always yields at least
  the identity). The Lean side falls back to `canonicalize vector` on
  an empty orbit image list (cannot happen for
  `variableCount ≥ 0`, but the branch exists defensively).
- **Plan text and implementation commits are tightly aligned in
  commit messages.** `feat(schema)`, `feat(lean)`, `feat(python)`, and
  `docs(research)` split the change along schema / Lean / Python /
  docs axes, matching the plan's commit-strategy section.
- **The drift-guard catches a real risk.** The tracked Zhang-Yeung
  literal is large and human-typed in the Lean source, but the
  `native_decide` example forces it to stay in sync with
  `orbitIdOf zhangYeungAveragedScaled.vector`. This is the best-case
  discipline for a string that has to be literal for `DecidableEq`
  purposes.

### Observations / issues

- **Duplicated orbit-action code in `NonShannon/Inequality/Canonical.lean`.**
  `applyPermutationIndex`, `actOnSubsetValues`, `actOnVectorValues`
  reimplement what `NonShannon/Inequality/Symmetry.lean`'s `actOnSubset`
  and `actOnVector` already provide. A future refactor should either
  (a) reexport / construct `VariableRelabeling` from a
  `List Nat`-indexed permutation and route orbit enumeration through
  `actOnVector`, or (b) keep the duplicate but add a short comment
  explaining why (structural reducibility for `native_decide`,
  avoidance of `VariableRelabeling.ofPerm` bijection proofs inside the
  orbit loop, etc.). As stands, the two actions must be changed in
  lockstep without a compiler hint to enforce it. Minor; flag as
  follow-up.
- **Local reinvention of `String.intercalate` (`joinWith`).** Lean core
  exposes `String.intercalate` with equivalent semantics. Swapping it
  in is a one-line simplification and removes a two-case recursive
  helper. Non-blocking.
- **The M1c orbit enumeration uses `List.permutations`, which is not a
  stable enumeration order across Lean / Mathlib versions.** This does
  not matter for orbit invariance (the lex-min selection erases order
  dependence), but it is worth keeping in mind if the orbit ID ever
  has to track a specific representative ordering. Not an M1c issue.
- **`cli.py` passes `orbit_id_of(source)` rather than
  `orbit_id_of(canonicalize_candidate(source))`.** Both produce the
  same string because `_orbit_representative` canonicalizes after
  permuting, so the enumerated orbit is the same set either way. The
  choice is fine; a two-word comment on the call site would make the
  invariance obvious to future readers.
- **The M1c `docs/plans/done/2026-04-20-m1c-orbit-canonicalization.md`
  Section 11 has an inline `#eval` instruction** for computing the
  Zhang-Yeung orbit-ID literal. The workflow is documented but not
  automated (there is no `lake exe m1c-orbit-id`-style tool); the
  drift-guard `example` absorbs the manual-paste risk, so full
  automation is not urgent.
- **No integration tests exercise `data/fixtures/zhang-yeung.json`'s
  `orbit_id` against the Python library end-to-end** beyond the CLI
  test. The fixture is regenerated and validates against the schema,
  and the cross-language parity test loads it, so coverage is adequate
  via transitive reads.
- **Test organization is clean but the `NonShannonTest/Inequality/Orbit.lean`
  module mixes orbit-invariance checks with one coefficient-serializer
  unit test.** Minor; the unit test does exercise the same
  `orbitIdOf` surface, so the collocation is defensible.

### Completeness

- No TODO / FIXME / HACK / XXX comments introduced on the branch.
- No stub implementations, placeholder values, or commented-out code.
- New public surfaces (`orbitCanonical`, `orbitIdOf`, `orbit_canonical`,
  `orbit_id_of`) all carry docstrings.
- Schema change is migration-note-covered in
  `docs/research/interchange-format.md`.
- Every new public Lean module (`NonShannonTest/Inequality/Orbit.lean`)
  is wired into `NonShannonTest.lean`.
- Python emitter and checked-in emitted modules are in lockstep
  (`tests/test_emit_lean.py::test_generated_zhang_yeung_module_matches_python_emitter`
  and
  `tests/test_symmetry.py::test_generated_zhang_yeung_swap_module_matches_python_emitter`
  are the gates).
- Plan is archived to `docs/plans/done/`; roadmap M1c status is
  updated.

### Assessment verdict

**Overall quality:** merge-ready subject to a `make check` rerun.
The branch delivers the M1c milestone with strict plan compliance,
visible cross-language parity enforcement, and clean commit boundaries.
The only observations worth addressing before merge are the duplicated
orbit-action code in `NonShannon/Inequality/Canonical.lean` (a comment
or a future refactor note) and the `String.intercalate` opportunity;
neither is a blocker.

**Strengths (summary):** cross-language literal-byte contract, working
drift-guard `example` on the pasted orbit-ID, always-present-null-when-absent
JSON convention, no silent failure paths, tight alignment between the
revised plan and the implementation.

**Issues to address (priority):**

- Low: add a one-line comment in `NonShannon/Inequality/Canonical.lean`
  explaining why orbit enumeration uses private `List Nat`-indexed
  action helpers instead of the public `actOnVector` (structural
  reducibility / decoupling from `VariableRelabeling.ofPerm`), or
  route the orbit loop through `actOnVector` and drop the private
  helpers.
- Low: replace `joinWith` with `String.intercalate`.
- Low: rerun `make check` once before merge to confirm the lake
  toolchain caches did not hide a regression on the new
  `NonShannonTest/Inequality/Orbit.lean` module.

**Suggestions (non-blocking):**

- Consider a tiny `lake exe` or `make` target that prints the
  Zhang-Yeung orbit-ID for cut-and-paste into `NonShannon/Examples/ZhangYeung.lean`.
  The drift-guard already catches staleness, but a named command is
  friendlier than `#eval`.
- Consider splitting `NonShannonTest/Inequality/Orbit.lean` into
  `Orbit.lean` (invariance) and a small `OrbitSerialization.lean`
  (pinned format) if future M1c-style serialization tests start to
  accumulate.
