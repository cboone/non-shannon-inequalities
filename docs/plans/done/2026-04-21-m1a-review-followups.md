# 2026-04-21 M1a Review Follow-Ups

Implementation plan for the M1a review findings on `research/implement-phase-m1a`.

## Context

The M1a branch successfully landed the within-inequality canonicalizer in Lean, reset the tracked Zhang-Yeung artifacts into the new baseline, and passed `make check`. The review found two remaining gaps in the milestone gate:

1. the branch does not yet test the actual Python-canonicalize -> Lean-emission -> Lean-equality path that M1a treats as the cross-language parity contract; and
1. the new regression coverage does not yet exercise non-normalized subset inputs, even though subset normalization is a core part of the strengthened canonicalizer.

These are follow-up verification gaps, not evidence that the current implementation is wrong. The goal is to close them with the smallest changes that make the cross-language contract explicit and robust.

## Goal

After this follow-up lands:

- a checked-in Lean test fixture generated from Python's canonical Zhang-Yeung output is compared directly against `NonShannon/Examples/ZhangYeung.lean` inside the Lean test suite;
- Python tests verify that the checked-in generated Lean fixture still matches the current emitter output byte-for-byte; and
- Lean and Python regression tests both cover canonicalization of non-normalized subset inputs, including duplicate combination after subset normalization.

## Approach

### 1. Add a generated Lean parity fixture

Create a test-only Lean module whose candidate constant is emitted from Python's canonical Zhang-Yeung fixture. Keep the file checked in under `NonShannonTest/Examples/` so that `lake test` verifies it alongside the rest of the public-surface examples.

The generated module should contain only:

1. the standard SPDX header,
1. `import NonShannon`, and
1. one constant emitted from `src/non_shannon_search/emit_lean.py` for the canonical Zhang-Yeung fixture.

The main Zhang-Yeung Lean test module should then import that generated module and prove that the emitted constant's vector is definitionally equal to `zhangYeungAveragedScaled.vector`.

### 2. Add a Python golden test for the generated Lean fixture

Extend `tests/test_emit_lean.py` with a golden test that:

1. loads `data/fixtures/zhang-yeung.json`,
1. canonicalizes it with `canonicalize_candidate`,
1. emits the test-module source using the existing emitter, and
1. compares the resulting source to the checked-in Lean fixture file byte-for-byte.

This closes the missing path from the review: JSON fixture -> Python canonicalizer -> Lean emitter -> checked-in Lean source -> Lean equality test.

### 3. Strengthen regression coverage for non-normalized subsets

Add one synthetic Lean example and one synthetic Python test where equal subsets appear in different orders, for example `[2, 0]` and `[0, 2]`. The expected canonical output should show that the canonicalizer:

1. normalizes subset order,
1. combines coefficients after normalization,
1. drops zero-sum terms when appropriate, and
1. sorts the surviving terms by `(cardinality, lex)`.

Also add one scrambled fixture-level case in Lean that reaches the tracked Zhang-Yeung canonical form after a single pass through `canonicalize`.

## Execution order

1. Add this plan file and commit it by itself.
1. Add the generated Lean parity fixture plus the Python golden test and Lean equality check.
1. Add the stronger non-normalized-subset coverage in Lean and Python.
1. Run `lake test`, `make py-test`, and `make check`.
1. Move this plan to `docs/plans/done/` once the follow-up is complete.

## Files touched

- New: `docs/plans/todo/2026-04-21-m1a-review-followups.md`, one generated Lean test fixture under `NonShannonTest/Examples/`.
- Modified: `NonShannonTest/Examples/ZhangYeung.lean`, `NonShannonTest/Inequality/Canonical.lean`, `tests/test_canonical.py`, `tests/test_emit_lean.py`.
- Not modified: the M1a canonicalizer implementation in `NonShannon/Inequality/{Subsets,Vector,Canonical}.lean`, unless the new tests expose a real bug.

## Testing and verification

Gate:

- `lake test`
- `make py-test`
- `make check`

Concrete checks:

- Lean: the Python-emitted Zhang-Yeung fixture equals the tracked Lean mirror.
- Lean: a vector with subsets such as `[2, 0]` and `[0, 2]` canonicalizes exactly as expected.
- Lean: a scrambled Zhang-Yeung term list canonicalizes to `zhangYeungAveragedScaled.vector`.
- Python: the generated Lean fixture matches the current emitter output byte-for-byte.
- Python: non-normalized subsets canonicalize to the same output as already-normalized ones.

## Commit strategy

1. `docs(plan): add M1a review follow-up plan`
1. `test(lean): add Python-emitted Zhang-Yeung parity fixture`
1. `test: strengthen M1a canonicalization regression coverage`

## Risks

- The checked-in generated Lean fixture must stay obviously generated from the Python emitter rather than drifting into hand-edited source. The Python golden test is the guardrail.
- If the new non-normalized-subset tests fail on the Python side, decide whether `canonicalize_candidate` should accept arbitrary in-memory subsets or whether the supported contract is only schema-normalized input. Prefer the broader contract if it is a small change.
