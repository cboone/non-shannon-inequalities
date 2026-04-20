# 2026-04-20 M1a: Term Normalization and Sparse-Vector Canonical Form

Implementation plan for milestone M1a of the Track A Discovery Roadmap (`docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`, Section 6).

## Context

The M0 bootstrap landed `NonShannon/Inequality/Canonical.lean` with a minimal `canonicalize` that only normalizes the overall sign: `canonicalize v = v.normalizeSign`. Meanwhile, the Python side's `canonicalize_candidate` in `src/non_shannon_search/canonical.py` already combines duplicate terms, sorts them by `(len(subset), subset)`, and flips the overall sign. That asymmetry is a standing hazard because any Lean-side fixture canonicalized before M1a disagrees with its Python round-trip whenever duplicate terms or unsorted subsets are present.

M1a closes the gap. It lifts the Python rule into Lean, strengthens `isCanonical` accordingly, and adds the Lean-side `example`s and Python round-trip tests that turn cross-language parity into a milestone gate.

M1a does not touch `VariableRelabeling` or introduce group actions; the upgrade to a bijection-carrying relabeling is M1b's scope.

## Goal

After M1a, the following identity holds by `example` on the Zhang-Yeung fixture and by `pytest` on round-tripped JSON:

```text
Lean.canonicalize (Python.canonicalize_candidate v) = Lean.canonicalize v
```

Both sides combine duplicate terms, sort by `(cardinality, lex)`, and sign-normalize to a nonnegative leading coefficient.

## Approach

### Data model

`VariableSubset.vars` stays an arbitrary `List Var`; the `isNormalized` invariant (strictly increasing) stays a predicate, not a field. Consumers that need normalized subsets explicitly require `isNormalized`. M1a adds helpers that turn an arbitrary `VariableSubset` into its normalized form, but the representation does not change.

`InequalityTerm` adds no fields. M1a provides merge helpers that combine two terms sharing a normalized subset.

`InequalityVector.terms` stays a `List InequalityTerm`. The canonical form is a term list with:

1. Every subset is normalized (strictly increasing `vars`).
1. No two terms share the same normalized subset; coefficients on equal subsets are combined.
1. Terms are ordered by `(subset.cardinality, subset.vars)` under lexicographic order.
1. The first nonzero coefficient is nonnegative.

### Algorithm

In Lean, implement `canonicalize` as a composition of three passes: combine duplicates (fold into a `List (VariableSubset × Rat)` keyed by the normalized subset), sort by the subset key, normalize sign. Prefer an expressible-in-Mathlib form over cleverness: if `Finset`-based combination is simpler than a list fold, use it.

In Python, the rule is already implemented in `canonicalize_candidate`. M1a does not change Python semantics; it adds tests.

### Where the sort key lives

Add `def VariableSubset.sortKey : VariableSubset -> Nat × List Nat := fun s => (s.cardinality, s.vars)` in `NonShannon/Inequality/Subsets.lean`. Keep the orderings used by the canonicalizer colocated with the subset type, not scattered through the canonicalization module. Python has `subset_sort_key` at module level in `canonical.py`; the Lean layout matches in spirit.

### `isCanonical` strengthening

`isCanonical v = canonicalize v = v` stays definitionally the same. The change is that `canonicalize` now does more, so `isCanonical` implicitly carries more invariants. Downstream code that assumes `isCanonical v` can assume sorted, duplicate-free, sign-normalized terms.

## Execution order

1. **Add `VariableSubset.sortKey`** and `VariableSubset.normalize` (a function that returns a `VariableSubset` with `vars` sorted and deduplicated) in `NonShannon/Inequality/Subsets.lean`. Include an `example` that `normalize` is idempotent.
1. **Add term-merge helpers** in `NonShannon/Inequality/Vector.lean`: `InequalityTerm.addCoefficients` (same-subset merge returning one term), and a list-level fold that combines a `List InequalityTerm` into a deduplicated list keyed by the normalized subset.
1. **Rewrite `canonicalize`** in `NonShannon/Inequality/Canonical.lean` as the three-pass composition. Leave the function name intact. Delete nothing that downstream modules might reference without an explicit rename.
1. **Extend `NonShannonTest/Inequality/Canonical.lean`** with: idempotence on the Zhang-Yeung fixture; duplicate-combination on a synthetic `InequalityVector` with two terms on `[0, 2]`; sort on a synthetic vector whose terms appear out of order.
1. **Extend `tests/test_canonical.py`** with: idempotence on Zhang-Yeung; cross-language parity (serialize Python canonical form, parse in Lean via a fixture, compare term-by-term).
1. **Regenerate `data/fixtures/zhang-yeung.json`** only if the current fixture's term order differs from the new canonical order. Log the regeneration in `docs/research/interchange-format.md` if it happens.
1. **Run `make check`.** Resolve any downstream breakage; do not suppress warnings.

## Files touched

- Modified: `NonShannon/Inequality/Subsets.lean`, `NonShannon/Inequality/Vector.lean`, `NonShannon/Inequality/Canonical.lean`, `NonShannonTest/Inequality/Canonical.lean`, `tests/test_canonical.py`.
- Possibly modified: `data/fixtures/zhang-yeung.json`, `docs/research/interchange-format.md`.
- Not modified: `NonShannon/Inequality/Subsets.lean`'s public structure, Python canonicalization semantics, `VariableRelabeling` (that's M1b).

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` all green.

Sanity checks beyond the default suite:

- Lean `example`: `canonicalize zhangYeungAveragedScaled.vector = zhangYeungAveragedScaled.vector` (fixture is already in canonical form, so idempotence is direct).
- Lean `example`: for a synthetic vector `v` with two terms on `[0, 2]` carrying coefficients `1` and `-1`, `canonicalize v` produces a vector with zero terms on `[0, 2]` (merged, then dropped as zero-coefficient).
- Python `pytest`: `canonicalize_candidate(canonicalize_candidate(c)) == canonicalize_candidate(c)`.
- Cross-language: build a small tracked test payload (possibly just Zhang-Yeung), canonicalize in Python, serialize; in Lean, construct the same vector, canonicalize, check term-by-term equality against the parsed Python output.

## Commit strategy

Prefer small commits at each logical boundary:

1. `feat(lean): add VariableSubset.sortKey and normalize helpers`
1. `feat(lean): add InequalityTerm merge helpers and list fold`
1. `feat(lean): extend canonicalize with duplicate combination and sort`
1. `test(lean): cover idempotence, duplicate combination, and sort in NonShannonTest/Inequality/Canonical.lean`
1. `test(python): extend test_canonical.py with idempotence and cross-language parity`
1. `chore(fixtures): regenerate zhang-yeung.json through the M1a pipeline` (only if the fixture actually changes)

## Open questions and risks

- **Dropping zero-coefficient terms.** The Python rule drops terms whose combined coefficient is zero. Lean should do the same; confirm this is captured in the duplicate-combination pass.
- **Stability of the sort.** `List.mergeSort` in Mathlib is stable, but the key here is total, so stability does not matter for output equality. Leave a note in the canonicalization module that the sort is total on non-duplicate keys after the dedup pass.
- **Zhang-Yeung fixture is already canonical.** Running the new canonicalizer on it should be a no-op. If it changes the JSON, M1a either has a bug or the fixture was malformed; either way, do not silently rewrite the fixture without updating `docs/research/interchange-format.md`.
- **Performance.** M1a's cost is `O(k log k)` per canonicalization for `k` terms. Not a bottleneck for Zhang-Yeung (`k = 12`) and not expected to be one through M5. Benchmarking is M1b/M1c territory when the group action multiplies the term count by orbit size.

## Why this shape is the right adaptation

M1a is deliberately narrow: it is the minimum work that removes the Lean-Python canonicalization asymmetry. Folding symmetry or orbit work into this subphase would put the `VariableRelabeling` upgrade and orbit-ID plumbing behind a single checkpoint, which is the failure mode the M1 split is meant to avoid. By shipping M1a first, M1b starts from a known-good within-inequality canonical form, and M1c starts from a known-good `Equiv.Perm`-based action.
