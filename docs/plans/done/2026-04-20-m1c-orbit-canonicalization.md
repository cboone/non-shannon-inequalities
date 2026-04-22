# 2026-04-20 M1c: Orbit Canonicalization and Duplicate-Term Combination

Implementation plan for milestone M1c of the Track A Discovery Roadmap (`docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`, Section 6).

## Context

M1a delivered a within-inequality canonical form (duplicate combination, subset-sorted term ordering, sign normalization) and reset the tracked Zhang-Yeung artifacts into that baseline. M1b delivered the scoped raw symmetry action on subsets, terms, and inequality vectors, with action laws and preservation of range validity proved by `example` in both Lean and Python. Neither subphase answers the question that M2 through M5 rely on: "are these two inequalities the same up to symmetry?"

M1c answers it. It composes M1a and M1b into an orbit-representative companion `orbitCanonical`, plumbs an orbit ID through `CandidateInequality` and the JSON schema, and establishes the cross-language contract that two permuted forms of the same inequality share one orbit ID byte-for-byte.

M1c is the integrating subphase of the M1 split. Its gate is the gate the original bootstrap M1 was trying to hit; landing M1a and M1b first makes that gate reachable.

## Goal

After M1c, the following hold:

- Applying any scoped relabeling to a canonical `InequalityVector` yields another well-formed `InequalityVector`; passing either form through `orbitCanonical` yields the same orbit representative and orbit ID.
- `CandidateInequality` in both Lean and Python carries an optional `orbit_id` / `orbitId` field, populated from `orbitCanonical`.
- The JSON schema `schemas/candidate-inequality.schema.json` is revised to include `orbit_id` while retaining `symmetry_orbit_size`; the Zhang-Yeung fixture is regenerated through the M1c pipeline; the migration note in `docs/research/interchange-format.md` records the schema revision.
- Lean's and Python's orbit IDs agree on the Zhang-Yeung fixture and on at least two of its non-trivial `S_4`-permuted forms.
- The public Python-facing canonicalization path (`non-shannon-search canonicalize`) emits fully populated M1c payloads, including `orbit_id`, rather than leaving orbit metadata to ad hoc post-processing.
- The existing Python-emitted Lean parity fixtures under `NonShannonTest/Examples/` are re-emitted with the new field so the M1a cross-language parity path stays live after the schema revision.

## Approach

### Orbit representative

Given a well-formed `InequalityVector v`, its `S_n` orbit is `{canonicalize (actOnVector r v) | r ∈ S_n}` for the appropriate `n = v.variableCount`. The orbit representative is the unique element of that orbit that is smallest under a deterministic total order on canonical `InequalityVector` values.

Total order on canonical `InequalityVector`:

1. Shorter term lists come first.
1. Ties broken by termwise lexicographic comparison under the order:
   - `InequalityTerm a < InequalityTerm b` iff `(a.subset.sortKey, a.coefficient) < (b.subset.sortKey, b.coefficient)`.

This extends the sort key already introduced in M1a to coefficients. Rational comparison is total, so the order is total on canonical vectors.

### Orbit enumeration

For `n = 4` (Zhang-Yeung), `|S_4| = 24`; for `n = 5`, `|S_5| = 120`; for `n = 6`, `|S_6| = 720`. All three sizes are cheap in practice. Exhaustive orbit enumeration: enumerate every scoped relabeling `r ∈ S_n`, compute `canonicalize (actOnVector r v)`, collect, return the lex-minimum. For larger `n`, the search milestones (M5) do not currently plan to go beyond `n = 5`, but if they do, M1c's enumeration becomes the bottleneck (Section 7.1 of the roadmap).

Implementation uses the scoped M1b relabeling surface: Lean enumerates `S_n` through finite permutations on the in-range variables, and Python does the same with `itertools.permutations` over `range(n)`.

### Orbit ID

The orbit ID is a deterministic serialization of the orbit representative's canonical form. Options:

1. **Deterministic string form of the canonical vector.** No hashing; the ID is the serialization. Pros: trivial to verify, trivial to eyeball, cross-language by construction. Cons: grows with inequality size.
1. **SHA-256 hex of the canonical serialization.** Fixed-width ID. Pros: compact; cons: obscures the content.

**Resolved:** option 1 (string form). The inequalities this project handles have at most a few dozen terms; opaque hashes hide the mathematical object from reviewers for no gain at this scale. Revisit if M5 produces tens of thousands of retained candidates.

**Pinned format.** The orbit-ID string is `{variableCount};{term};{term};...`, where each `{term}` is either `[{i0},{i1},...]:{num}` (when the denominator is 1) or `[{i0},{i1},...]:{num}/{den}` (otherwise). Detail:

- `{variableCount}` is the decimal `Nat` with no leading zeros.
- Subset indices are strictly increasing (as produced by `VariableSubset.normalize`), separated by `,` with no spaces.
- `{num}` is the signed numerator in base 10, no leading `+`. `{den}` is the unsigned denominator, never emitted when `1`. Zero coefficients do not appear (`canonicalize` filters them).
- Terms are in canonical order (sorted by `(cardinality, lex)`), separated by `;`.
- An empty term list still produces `{variableCount};`, preserving `;` as the sole structural separator.

Example (Zhang-Yeung prefix): `4;[0]:1;[1]:1;[2]:4;[3]:4;[0,1]:2;[0,2]:-4;...`.

Both Lean and Python construct this string directly from the canonical term list; neither side delegates coefficient formatting to a pre-existing printer (Lean's `Rat.repr`, Python's `format_rational`), so the format is one shared contract rather than an emergent agreement between two unrelated printers.

This field supplements rather than replaces the existing optional `symmetry_orbit_size` metadata. `orbit_id` identifies the orbit representative; `symmetry_orbit_size` records an externally computed orbit cardinality when such a number is available.

### Schema revision

Add an optional `orbit_id` field (typed `["string", "null"]`, with `minLength: 1` when non-null) to `schemas/candidate-inequality.schema.json`. Optional on the way in so that existing fixtures without the field still validate; populated on the way out by the canonicalizer. Keep the existing optional `symmetry_orbit_size` field unchanged. Write a migration note in `docs/research/interchange-format.md` describing (a) the new field, (b) the unchanged role of `symmetry_orbit_size`, (c) the canonicalization rule that produces `orbit_id`, and (d) the CLI behavior change: `non-shannon-search canonicalize` now emits M1c-complete payloads (`orbit_id` populated) instead of only the M1a within-inequality canonical form.

JSON emission convention: `orbit_id` is always present in `CandidateInequality.to_dict()` output, set to `null` when absent, matching how `copy_parameters_ref` and `symmetry_orbit_size` are emitted today. Fixtures regenerated through the M1c pipeline follow the same convention, so validators never split-brain on missing-versus-null.

Lean mirror: add `orbitId : Option String := none` to `CandidateInequality` in `NonShannon/Certificate/Schema.lean`.

Python mirror: add `orbit_id: str | None = None` to the `CandidateInequality` dataclass in `src/non_shannon_search/schema.py`.

Because the repo now carries checked-in Lean modules emitted from Python (`NonShannonTest/Examples/ZhangYeungFromPython.lean` and `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`), this schema revision also requires `src/non_shannon_search/emit_lean.py` and `tests/test_emit_lean.py` to learn the new field, followed by re-emission of those generated modules. Otherwise the M1a follow-up parity path drifts the moment `orbit_id` lands.

### The canonicalizer's surface

Two options for how the orbit-canonicalization integrates:

1. **Extend `canonicalize` in place.** Make `canonicalize : InequalityVector -> InequalityVector` return the orbit representative of the input vector. Every caller now gets orbit canonicalization.
1. **Add a separate `orbitCanonical` alongside `canonicalize`.** Keep `canonicalize` at the M1a-level (within-inequality) form; provide `orbitCanonical v = canonicalize (actOnVector p v)` for the minimizing `p`.

**Resolved:** option 2. Keep `canonicalize` as the within-inequality operation; add `orbitCanonical` as the stronger form. Reason: M2 and downstream might want the cheaper within-inequality form for fast equality checks, and the orbit version for deduplication across search outputs. Having both available without forcing every caller to pay the orbit-enumeration cost is cleaner.

Three surface pieces, each with a distinct return shape:

- **`orbitCanonical : InequalityVector -> InequalityVector`** (Lean) / **`orbit_canonical(candidate) -> CandidateInequality`** (Python). Returns the orbit-representative form: the lex-minimum `canonicalize (actOnVector r v)` over `r ∈ S_n`. Lossy on the caller's specific permutation (two permuted forms of the same inequality produce equal output). The Python variant returns a `CandidateInequality` whose `vector` is the representative and whose `orbit_id` is populated via `orbit_id_of`.
- **`orbitIdOf : InequalityVector -> String`** (Lean) / **`orbit_id_of(candidate) -> str`** (Python). Returns the pinned-format serialization of `orbitCanonical` applied to the input. Orbit-invariant by construction: the identity that powers the cross-language gate.
- **CLI `canonicalize` subcommand**: emits the M1a within-inequality canonical form of the input with `orbit_id` populated via `orbit_id_of`. Preserves the caller's specific permutation in the emitted `terms` while still carrying the orbit-invariant identifier. Callers that want the orbit representative's `terms` call `orbit_canonical` directly from the Python library.

## Execution order

1. **Extend `NonShannon/Inequality/Canonical.lean`** with the full orbit-canonicalization surface:
   - Add `InequalityVector.lexKey` (or an equivalent comparator over `(length, List (subset.sortKey, coefficient))`) and a list-minimum helper on canonical vectors. `InequalityVector` currently only derives `DecidableEq`, so the lex-min scaffolding is where most of the implementation time will go.
   - Add `orbitCanonical : InequalityVector -> InequalityVector` via exhaustive enumeration of `Equiv.Perm (Fin v.variableCount)`, each lifted to a scoped `VariableRelabeling`, applied with `actOnVector`, canonicalized with `canonicalize`, and reduced to the lex-minimum via the helper above.
   - Add `orbitIdOf : InequalityVector -> String`, serializing a canonical vector into the pinned format directly (not via `Rat.repr` or any other existing printer).
   - Prove orbit-invariance of `orbitCanonical` and `orbitIdOf` by `example` on Zhang-Yeung (applying identity, `swap 0 1`, `swap 2 3`, and one three-cycle; each produces the same output after one `orbitCanonical` pass).
1. **Add `NonShannonTest/Inequality/Orbit.lean`** with orbit-invariance `example`s under the named `S_4` elements and a cross-form parity `example` (two hand-permuted forms of Zhang-Yeung share an orbit representative).
1. **Wire `NonShannonTest/Inequality/Orbit.lean` into `NonShannonTest.lean`** by adding `import NonShannonTest.Inequality.Orbit` next to the existing test imports, so `lake test` picks it up.
1. **Add `orbitId : Option String := none`** to `CandidateInequality` in `NonShannon/Certificate/Schema.lean`. Call sites constructing `CandidateInequality` (at minimum `NonShannon/Examples/ZhangYeung.lean`, `NonShannonTest/Certificate/Schema.lean`, `NonShannonTest/Catalog.lean`) continue to compile with the default `none`; the tracked Zhang-Yeung literal gets its concrete orbit ID in step 11 after the helper is available.
1. **Extend `NonShannonTest/Certificate/Schema.lean`** with concrete coexistence `example`s for the new field. At minimum:
   - `example : ({ candidate with orbitId := some "fixture-orbit", symmetryOrbitSize? := some 24 }).orbitId = some "fixture-orbit"`
   - `example : ({ candidate with orbitId := some "fixture-orbit", symmetryOrbitSize? := some 24 }).symmetryOrbitSize? = some 24`
   - `example : candidate.orbitId = none` (default case)
1. **Revise `schemas/candidate-inequality.schema.json`** to add the optional `orbit_id` field (`["string", "null"]`, `minLength: 1` when non-null). Update `src/non_shannon_search/schema.py` to mirror, keeping the "always present, null when absent" emission convention already used by `copy_parameters_ref` and `symmetry_orbit_size`.
1. **Extend `src/non_shannon_search/canonical.py`** with `orbit_canonical(candidate) -> CandidateInequality` (returns the orbit-representative form with `orbit_id` populated) and `orbit_id_of(candidate) -> str` (returns the pinned-format serialization). Ship matching helpers in `src/non_shannon_search/symmetry.py` for the orbit enumeration if they do not fit cleanly in `canonical.py`.
1. **Update `src/non_shannon_search/cli.py`** so the public `canonicalize` command emits the M1a within-inequality canonical form of the input with `orbit_id` populated via `orbit_id_of`. The CLI does not permute `terms` to the orbit representative; that remains an explicit `orbit_canonical` call in Python.
1. **Update `src/non_shannon_search/emit_lean.py` and `tests/test_emit_lean.py`** so the checked-in Python-emitted Lean mirrors keep tracking the fixture shape after `orbit_id` lands. The Lean emitter adds an `orbitId := some "..."` line to each generated constant whose Python source carries one.
1. **Regenerate `NonShannonTest/Examples/ZhangYeungFromPython.lean` and `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`** through the updated Python emitter, and keep `NonShannonTest/Examples/ZhangYeung.lean` proving equality against those generated modules.
1. **Update the tracked Lean literal.** Compute the Zhang-Yeung orbit ID via `#eval orbitIdOf zhangYeungAveragedScaled.vector` (equivalent to Python's `orbit_id_of` on the fixture) and paste the resulting string as `orbitId := some "..."` on `zhangYeungAveragedScaled` in `NonShannon/Examples/ZhangYeung.lean`. Add a Lean `example` in `NonShannonTest/Examples/ZhangYeung.lean` asserting `zhangYeungAveragedScaled.orbitId = some (orbitIdOf zhangYeungAveragedScaled.vector)` so the pasted string cannot drift silently from the helper output.
1. **Extend `tests/test_canonical.py`** with orbit-invariance checks; extend `tests/test_symmetry.py` with cross-language orbit-ID parity on Zhang-Yeung. The cross-language parity test reads the generated Lean module's bytes, parses out the `orbitId := some "..."` string literal, and asserts equality with Python's `orbit_id_of(load_candidate(FIXTURE))` — reusing the existing checked-in-emitted-module parity pattern from `test_emit_lean.py` and `test_symmetry.py` rather than introducing a scrut harness.
1. **Extend `tests/test_schema.py`** with concrete cases: payload omitting `orbit_id` validates; payload with `orbit_id: null` validates; payload with `orbit_id: "..."` validates; `CandidateInequality.from_dict(...).to_dict()` round-trips the field without dropping it.
1. **Regenerate `data/fixtures/zhang-yeung.json`** through the M1c pipeline so its `orbit_id` field is populated (as a string, not `null`). Commit the regenerated fixture.
1. **Update `docs/research/interchange-format.md`** with the migration note (schema revision plus the `canonicalize` CLI behavior change).
1. **Run `make check`.** Everything should be green; if a fixture breaks, the M1c pipeline has a bug.

## Files touched

- Modified: `NonShannon/Inequality/Canonical.lean`, `NonShannon/Certificate/Schema.lean`, `NonShannon/Examples/ZhangYeung.lean`, `NonShannonTest/Inequality/Canonical.lean`, `NonShannonTest/Certificate/Schema.lean`, `NonShannonTest/Examples/ZhangYeung.lean`, `NonShannonTest.lean`, `schemas/candidate-inequality.schema.json`, `src/non_shannon_search/schema.py`, `src/non_shannon_search/canonical.py`, `src/non_shannon_search/symmetry.py`, `src/non_shannon_search/cli.py`, `src/non_shannon_search/emit_lean.py`, `data/fixtures/zhang-yeung.json`, `docs/research/interchange-format.md`, `tests/test_canonical.py`, `tests/test_symmetry.py`, `tests/test_schema.py`, `tests/test_emit_lean.py`.
- New: `NonShannonTest/Inequality/Orbit.lean`; import wired into `NonShannonTest.lean`.
- Regenerated: `NonShannonTest/Examples/ZhangYeungFromPython.lean`, `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`.

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` all green.

Concrete sanity checks:

- Lean `example`: for each element of the covered `S_4` set (identity, `swap 0 1`, `swap 2 3`, and one three-cycle), `orbitCanonical (actOnVector r zhangYeung.vector _) = orbitCanonical zhangYeung.vector` and `orbitIdOf (actOnVector r zhangYeung.vector _) = orbitIdOf zhangYeung.vector`.
- Python `pytest`: same pair of checks on the Python side for the named `S_4` elements, plus a full-orbit check that iterates every element of `iter_symmetric_group(4)` and asserts invariance.
- Cross-language: the Zhang-Yeung orbit ID is byte-identical in Lean and Python. The check reads `NonShannonTest/Examples/ZhangYeungFromPython.lean`'s emitted `orbitId := some "..."` line, parses the string literal, and asserts equality with Python's `orbit_id_of(load_candidate(FIXTURE))`. This reuses the existing checked-in-emitted-module parity pattern already in `test_emit_lean.py` and `test_symmetry.py`; no scrut harness is introduced.
- Schema/API: `NonShannonTest/Certificate/Schema.lean` gains concrete `example`s for `orbitId = none` (default), `orbitId = some "..."` with `symmetryOrbitSize? = none`, and both fields set simultaneously, per the execution order.
- Python CLI: `non-shannon-search canonicalize data/fixtures/zhang-yeung.json` emits JSON with `orbit_id` populated (not `null`), `terms` in the M1a canonical order of the input, and all other fields unchanged from the pre-M1c output.
- Python-emitted Lean parity: `tests/test_emit_lean.py` still matches the checked-in emitted modules byte-for-byte, and `NonShannonTest/Examples/ZhangYeung.lean` still proves equality between the emitted constants and the tracked Lean mirror after `orbitId` is added.
- Python schema gate: `tests/test_schema.py` validates payloads that omit `orbit_id`, payloads that set it to `null`, and payloads that set it to a string; it also round-trips the populated Zhang-Yeung fixture through `CandidateInequality.from_dict` / `to_dict` without dropping the field.

## Commit strategy

1. `feat(lean): add orbitCanonical and orbit-ID serialization`
1. `test(lean): cover orbit invariance on Zhang-Yeung`
1. `feat(schema): add optional orbit_id to candidate-inequality schema`
1. `feat(lean): thread orbitId through CandidateInequality`
1. `feat(python): mirror orbit canonicalization and orbit_id in schema.py and canonical.py`
1. `test(python): cover orbit invariance and cross-language parity`
1. `chore(fixtures): regenerate zhang-yeung.json with orbit_id populated`
1. `docs(research): record the M1c schema revision in interchange-format.md`

## Open questions and risks

- **Orbit size for `n > 5`.** `|S_n|` grows as `n!`; M1c's enumeration is `O(n! · k log k)` for `k` terms. For `n = 6`, `720` permutations is fine; for `n = 7`, `5040` is a noticeable per-inequality cost. Roadmap risk 7.1 already flags this; if M5 elects `n = 6` or higher, revisit the enumeration with coset representatives or a permutation canonicalization trick (for example, canonical labeling via a `nauty`-style scheme). Out of scope for M1c itself.
- **Orbit ID stability across coefficient serialization.** Closed by the pinned-format decision above: Lean and Python each construct the orbit ID from the canonical term list directly, without delegating to `Rat.repr` or `format_rational`. A small cross-language regression test (Lean-side and Python-side serializers applied to a spread of coefficients: `-5`, `3/2`, `-1/3`, `7`) guards the shared contract against future drift.
- **Existing callers of `CandidateInequality`.** The `orbitId` field is optional and defaults to `none`; existing callers (`NonShannon/Examples/ZhangYeung.lean`, `NonShannonTest/Certificate/Schema.lean`, `NonShannonTest/Catalog.lean`) compile unchanged. After the canonicalizer computes the Zhang-Yeung orbit ID, paste the resulting string as `orbitId := some "..."` on the Lean literal and add a Lean `example` asserting `zhangYeungAveragedScaled.orbitId = some (orbitIdOf zhangYeungAveragedScaled.vector)` so the pasted string cannot drift silently from the helper output.
- **Schema compatibility.** The schema revision adds an optional field, not a required one, and it does not remove `symmetry_orbit_size`. Consumers that validate fixtures without `orbit_id` still pass. No breaking change for existing consumers.
- **Emitter and generated-fixture drift.** M1a's follow-up work made the Python-emitted Lean fixtures part of the regression contract. Once `CandidateInequality` gains `orbit_id` / `orbitId`, `emit_lean.py`, `tests/test_emit_lean.py`, and the checked-in generated modules must move in lockstep or the parity path will fail even if orbit canonicalization itself is correct.
- **`O(k²)` within-inequality canonicalization cost and redundant subset normalization — deferred past M1c.** Tracked as a follow-up from the 2026-04-21 M1a branch review. `InequalityTerm.combineDuplicates` in `NonShannon/Inequality/Vector.lean` uses a linear-scan `List.find?` plus `List.map` inside a `foldl`, so the within-inequality canonicalization pass is `O(k²)` per call for `k` terms. M1c's `orbitCanonical` multiplies that by `|S_n| = n!`. A second, related wedge: `combineDuplicates` unconditionally normalizes every input subset, and M1b's `actOnSubset` is specified to hand out already-normalized subsets, so every `canonicalize (actOnVector r v)` inside the orbit loop walks each term's `vars` through `VariableSubset.normalize` twice. For Zhang-Yeung (`n = 4`, `k = 12`, `|S_4| = 24`) the total cost is roughly `24 · 12² = 3456` elementary operations — well under a millisecond. Decision: **leave `combineDuplicates` alone in M1c** and revisit when M5 elects `n ≥ 6` or the first real search input pushes `k` past a few dozen terms. The `NonShannon/Inequality/Vector.lean` docstring is updated in the same commit to point to a future milestone rather than claiming M1c will do the rewrite. When the rewrite does happen, the target is a `HashMap (List Nat) Rat`-keyed or `TreeMap`-keyed fold, with the contract split so `canonicalize` does the outer `normalize` once and `combineDuplicates` takes pre-normalized input.

## Why this shape is the right adaptation

M1c is the point where the roadmap's downstream milestones get the equality notion they need: "the same inequality up to variable relabeling." Splitting it into its own subphase means the gate is crisp (orbit ID cross-language identical on Zhang-Yeung plus two permuted forms) and the implementation work is contained (orbit enumeration plus string serialization). A single-shot M1 would have packed this integrating step into the same commit as the action-law proofs and the duplicate-combination work, hiding bugs behind each other. With M1a and M1b already green, M1c fails visibly or passes visibly.
