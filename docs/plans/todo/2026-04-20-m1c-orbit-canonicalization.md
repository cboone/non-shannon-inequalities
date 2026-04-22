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

For `n <= 5`, `|S_n| = 120`, so exhaustive orbit enumeration is cheap: enumerate every scoped relabeling `r ∈ S_n`, compute `canonicalize (actOnVector r v)`, collect, sort, return the minimum. For `n = 6` (`|S_6| = 720`) still manageable. For larger `n`, the search milestones (M5) do not currently plan to go beyond `n = 5`, but if they do, M1c's enumeration becomes the bottleneck (Section 7.1 of the roadmap).

Implementation uses the scoped M1b relabeling surface: Lean enumerates `S_n` through finite permutations on the in-range variables, and Python does the same with `itertools.permutations` over `range(n)`.

### Orbit ID

The orbit ID is a deterministic serialization of the orbit representative's canonical form. Options:

1. **Deterministic string form of the canonical vector.** For example, `"4;[[[0],-1],[[1],-1],[[2],-4],...]"` where terms are in canonical order and coefficients are in rational string form. No hashing; the ID is the serialization. Pros: trivial to verify, trivial to eyeball, cross-language by construction. Cons: grows with inequality size.
1. **SHA-256 hex of the canonical serialization.** Fixed-width ID. Pros: compact; cons: obscures the content.

**Resolved:** option 1 (string form). The inequalities this project handles have at most a few dozen terms; opaque hashes hide the mathematical object from reviewers for no gain at this scale. Revisit if M5 produces tens of thousands of retained candidates.

This field supplements rather than replaces the existing optional `symmetry_orbit_size` metadata. `orbit_id` identifies the orbit representative; `symmetry_orbit_size` records an externally computed orbit cardinality when such a number is available.

### Schema revision

Add an optional `orbit_id` field (string) to `schemas/candidate-inequality.schema.json`. Optional on the way in so that existing fixtures without the field still validate; populated on the way out by the canonicalizer. Keep the existing optional `symmetry_orbit_size` field unchanged. Write a migration note in `docs/research/interchange-format.md` describing the new field, the unchanged role of `symmetry_orbit_size`, and the canonicalization rule that produces `orbit_id`.

Lean mirror: add `orbitId : Option String := none` to `CandidateInequality` in `NonShannon/Certificate/Schema.lean`.

Python mirror: add `orbit_id: str | None = None` to the `CandidateInequality` dataclass in `src/non_shannon_search/schema.py`.

Because the repo now carries checked-in Lean modules emitted from Python (`NonShannonTest/Examples/ZhangYeungFromPython.lean` and `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`), this schema revision also requires `src/non_shannon_search/emit_lean.py` and `tests/test_emit_lean.py` to learn the new field, followed by re-emission of those generated modules. Otherwise the M1a follow-up parity path drifts the moment `orbit_id` lands.

### The canonicalizer's surface

Two options for how the orbit-canonicalization integrates:

1. **Extend `canonicalize` in place.** Make `canonicalize : InequalityVector -> InequalityVector` return the orbit representative of the input vector. Every caller now gets orbit canonicalization.
1. **Add a separate `orbitCanonical` alongside `canonicalize`.** Keep `canonicalize` at the M1a-level (within-inequality) form; provide `orbitCanonical v = canonicalize (actOnVector p v)` for the minimizing `p`.

**Resolved:** option 2. Keep `canonicalize` as the within-inequality operation; add `orbitCanonical` as the stronger form. Reason: M2 and downstream might want the cheaper within-inequality form for fast equality checks, and the orbit version for deduplication across search outputs. Having both available without forcing every caller to pay the orbit-enumeration cost is cleaner.

`CandidateInequality.orbitId` is populated by a helper that calls `orbitCanonical` and serializes the result.

On the Python side, the public CLI must stay aligned with that rule. `src/non_shannon_search/cli.py`'s `canonicalize` subcommand should therefore emit a payload whose `orbit_id` is populated by the same orbit-aware helper used for fixture regeneration and tests, rather than continuing to expose only the M1a within-inequality canonical form.

## Execution order

1. **Extend `NonShannon/Inequality/Canonical.lean`** with `orbitCanonical` and the helper that serializes a canonical `InequalityVector` to the orbit-ID string. Prove orbit-invariance of `orbitCanonical` by `example` on Zhang-Yeung (applying any `S_4` element, then canonicalizing across the orbit, yields equal output).
1. **Add `NonShannonTest/Inequality/Orbit.lean`** with orbit-invariance `example`s under named `S_4` elements and a cross-form parity `example` (two hand-permuted forms of Zhang-Yeung share an orbit representative).
1. **Extend `NonShannon/Inequality/Canonical.lean` or add a small helper** to compute `orbitIdOf : InequalityVector -> String`.
1. **Add `orbitId : Option String := none`** to `CandidateInequality` in `NonShannon/Certificate/Schema.lean`. Update all call sites that construct a `CandidateInequality`, including `NonShannon/Examples/ZhangYeung.lean`.
1. **Extend `NonShannonTest/Certificate/Schema.lean`** so the orbit-ID field is covered in the API regression tests and its coexistence with `symmetryOrbitSize?` is explicit.
1. **Revise `schemas/candidate-inequality.schema.json`** to add the optional `orbit_id` field. Update `src/non_shannon_search/schema.py` to mirror.
1. **Extend `src/non_shannon_search/canonical.py`** with `orbit_canonical(candidate)` and `orbit_id_of(candidate)`. Ship matching helpers in `src/non_shannon_search/symmetry.py` for the orbit enumeration.
1. **Update `src/non_shannon_search/cli.py`** so the public `canonicalize` command emits M1c-complete payloads with `orbit_id` populated.
1. **Update `src/non_shannon_search/emit_lean.py` and `tests/test_emit_lean.py`** so the checked-in Python-emitted Lean mirrors keep tracking the fixture shape after `orbit_id` lands.
1. **Regenerate `NonShannonTest/Examples/ZhangYeungFromPython.lean` and `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`** through the updated Python emitter, and keep `NonShannonTest/Examples/ZhangYeung.lean` proving equality against those generated modules.
1. **Extend `tests/test_canonical.py`** with orbit-invariance and `tests/test_symmetry.py` with cross-language orbit-ID parity on Zhang-Yeung.
1. **Extend `tests/test_schema.py`** so the schema revision is covered by Python's dedicated schema-validation and round-trip tests, not only by fixture-level canonicalization tests.
1. **Regenerate `data/fixtures/zhang-yeung.json`** through the M1c pipeline so that its `orbit_id` field is populated. Commit the regenerated fixture.
1. **Update `docs/research/interchange-format.md`** with the migration note.
1. **Run `make check`.** Everything should be green; if a fixture breaks, the M1c pipeline has a bug.

## Files touched

- Modified: `NonShannon/Inequality/Canonical.lean`, `NonShannon/Certificate/Schema.lean`, `NonShannon/Examples/ZhangYeung.lean`, `NonShannonTest/Inequality/Canonical.lean`, `NonShannonTest/Certificate/Schema.lean`, `NonShannonTest/Examples/ZhangYeung.lean`, `NonShannonTest.lean`, `schemas/candidate-inequality.schema.json`, `src/non_shannon_search/schema.py`, `src/non_shannon_search/canonical.py`, `src/non_shannon_search/symmetry.py`, `src/non_shannon_search/cli.py`, `src/non_shannon_search/emit_lean.py`, `data/fixtures/zhang-yeung.json`, `docs/research/interchange-format.md`, `tests/test_canonical.py`, `tests/test_symmetry.py`, `tests/test_schema.py`, `tests/test_emit_lean.py`.
- New: `NonShannonTest/Inequality/Orbit.lean`; import wired into `NonShannonTest.lean`.
- Regenerated: `NonShannonTest/Examples/ZhangYeungFromPython.lean`, `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`.

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` all green.

Concrete sanity checks:

- Lean `example`: for each element of a small generating set of `S_4` (say identity, `swap 0 1`, `swap 2 3`, and one three-cycle), `orbitCanonical (actOnVector r zhangYeung.vector) = orbitCanonical zhangYeung.vector`.
- Lean `example`: `orbitIdOf (actOnVector r zhangYeung.vector) = orbitIdOf zhangYeung.vector`.
- Python `pytest`: same pair of checks on the Python side.
- Cross-language: Lean `orbitIdOf` and Python `orbit_id_of` produce byte-identical output on the Zhang-Yeung fixture. A small scrut-or-pytest harness that imports both outputs and compares strings suffices; hardwiring the string into a Lean `example` is also acceptable but more brittle.
- Schema/API: constructing a `CandidateInequality` with both `orbitId := none` and `symmetryOrbitSize? := none` still works, and populating `orbitId` does not change the meaning of `symmetryOrbitSize?`.
- Python CLI: `non-shannon-search canonicalize data/fixtures/zhang-yeung.json` emits JSON with `orbit_id` populated, matching the fixture and the library helper rather than the pre-M1c shape.
- Python-emitted Lean parity: `tests/test_emit_lean.py` still matches the checked-in emitted modules byte-for-byte, and `NonShannonTest/Examples/ZhangYeung.lean` still proves equality between the emitted constants and the tracked Lean mirror after `orbitId` is added.
- Python schema gate: `tests/test_schema.py` validates payloads that omit `orbit_id`, validates payloads that include it, and round-trips the populated Zhang-Yeung fixture through `CandidateInequality.from_dict` / `to_dict` without dropping the field.

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
- **Orbit ID stability across coefficient serialization.** Orbit ID is sensitive to the exact rational string format. Python's `format_rational` and Lean's rational-to-string must produce identical output for every representable coefficient. Add a small cross-language test that iterates over a spread of coefficients (`-5`, `3/2`, `0` which should not appear, `-1/3`) and verifies equal string form.
- **Existing callers of `CandidateInequality`.** The `orbitId` field is optional; existing callers (`NonShannon/Examples/ZhangYeung.lean`, `NonShannonTest/Certificate/Schema.lean`, `NonShannonTest/Catalog.lean`) should continue to compile with the default `none`. After the canonicalizer populates the Zhang-Yeung fixture's orbit ID, update the Lean-side literal to match so the fixture is in canonical form by construction.
- **Schema compatibility.** The schema revision adds an optional field, not a required one, and it does not remove `symmetry_orbit_size`. Consumers that validate fixtures without `orbit_id` still pass. No breaking change for existing consumers.
- **Emitter and generated-fixture drift.** M1a's follow-up work made the Python-emitted Lean fixtures part of the regression contract. Once `CandidateInequality` gains `orbit_id` / `orbitId`, `emit_lean.py`, `tests/test_emit_lean.py`, and the checked-in generated modules must move in lockstep or the parity path will fail even if orbit canonicalization itself is correct.
- **O(n²) within-inequality canonicalization cost and redundant subset normalization.** Tracked as a follow-up from the 2026-04-21 M1a branch review. `InequalityTerm.combineDuplicates` in `NonShannon/Inequality/Vector.lean` uses a linear-scan `List.find?` plus `List.map` inside a `foldl`, so the within-inequality canonicalization pass is `O(k²)` per call for `k` terms. M1c's `orbitCanonical` multiplies that by `|S_n| = n!`. A second, related wedge: `combineDuplicates` unconditionally normalizes every input subset, and M1b's `actOnSubset` is specified to hand out already-normalized subsets. Every `canonicalize (actOnVector r v)` inside the orbit loop therefore walks each term's `vars` through `VariableSubset.normalize` twice. For Zhang-Yeung (`n = 4`, `k = 12`) both costs are trivial; for larger inequalities or if M5 elects `n ≥ 6`, upgrade `combineDuplicates` to a `HashMap (List Nat) Rat`-keyed or `RBMap`-keyed fold and split its contract (take pre-normalized input, do the outer `normalize` once in `canonicalize`) as part of M1c's enumeration work, rather than retrofitting after the orbit surface lands.

## Why this shape is the right adaptation

M1c is the point where the roadmap's downstream milestones get the equality notion they need: "the same inequality up to variable relabeling." Splitting it into its own subphase means the gate is crisp (orbit ID cross-language identical on Zhang-Yeung plus two permuted forms) and the implementation work is contained (orbit enumeration plus string serialization). A single-shot M1 would have packed this integrating step into the same commit as the action-law proofs and the duplicate-combination work, hiding bugs behind each other. With M1a and M1b already green, M1c fails visibly or passes visibly.
