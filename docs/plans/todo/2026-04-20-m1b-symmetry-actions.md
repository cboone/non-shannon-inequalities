# 2026-04-20 M1b: Symmetry Group Actions

Implementation plan for milestone M1b of the Track A Discovery Roadmap (`docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`, Section 6).

## Context

M1a landed a within-inequality canonical form: duplicate-term combination, subset-sorted term ordering, sign normalization, and one coordinated reset of the tracked Zhang-Yeung artifacts into that baseline. That canonical form makes equality checks meaningful but does not express the permutation symmetry that every downstream milestone depends on.

The bootstrap layer has a placeholder `VariableRelabeling` structure in `NonShannon/Inequality/Canonical.lean` that wraps a bare function `image : Var -> Var`. It has no bijectivity invariant, no group structure, no notion of the vector's declared variable range, and no lifted action on `InequalityVector` beyond a list-map. That is enough to write syntactic relabelings but not enough to reason about symmetry orbits or even to guarantee that a relabeling stays inside the vector's declared `variableCount`.

M1b replaces the placeholder with a proper scoped group action on `VariableSubset`, `InequalityTerm`, and `InequalityVector`, with action laws proved by `example`. The public contract is tied to a declared `variableCount`, so vectors that stay within range continue to do so after relabeling. The cross-language contract is established by mirroring the same scoped action in `src/non_shannon_search/symmetry.py`.

M1b does not attempt orbit-representative selection or orbit-ID plumbing; those are M1c.

## Goal

After M1b, the following hold:

- `VariableRelabeling` is scoped to a declared `variableCount`, carries a bijectivity invariant on the in-range variables, and is definitionally usable by downstream modules.
- `actOnVector` is a raw relabeling action on `InequalityVector`, with identity and composition laws proved by `example` after canonicalization.
- Range validity is explicit: subsets and vectors that reference only variables in `[0, variableCount)` stay in range under the action.
- Applying an action and re-canonicalizing (M1a) is well-defined in both languages: `canonicalize (actOnVector r v) = canonicalize (actOnVector r (canonicalize v))`.
- The Python `src/non_shannon_search/symmetry.py` exposes parallel functions with identical behavior on the Zhang-Yeung fixture.

## Approach

### Scoped relabeling contract

`Var` is still `abbrev Var := Nat` in `NonShannon/Prelude.lean`, but the public symmetry API is no longer "an arbitrary permutation of `Nat` plus a convention." Instead, M1b introduces a scoped `VariableRelabeling` carrying:

1. a declared `variableCount : Nat`, and
1. a bijection of the finite range `[0, variableCount)`.

Lean can realize that contract internally with `Equiv.Perm (Fin variableCount)` or an equivalent structure. The key planning decision is the public surface, not the exact internal encoding: every relabeling is range-scoped, and every action law is stated relative to that scope.

Python mirrors the same contract with a fixed-length permutation representation, preferably `tuple[int, ...]` of length `variable_count`, validated to be a permutation of `range(variable_count)`.

#### Out-of-range convention

A `VariableRelabeling` with scope `n` maps any `Var` outside `[0, n)` to itself. This keeps `actOnSubset`, `actOnTerm`, and `actOnVector` total on arbitrary inputs while preserving the invariant that in-range vectors stay in range. The identity-outside-scope rule is stated in the module docstring and covered by an `example` in the test module.

#### Smart constructors

Expose a small, named set of smart constructors on top of the internal representation so callers build scoped relabelings without manipulating `Fin n` indices directly:

- `VariableRelabeling.id (n : Nat) : VariableRelabeling` returns the identity on scope `n`.
- `VariableRelabeling.swap (n i j : Nat) : VariableRelabeling` returns the transposition `(i j)` on scope `n`, falling back to the identity when either index is out of range. Named to match Mathlib's `Equiv.swap`.
- `VariableRelabeling.ofPerm (n : Nat) (σ : Equiv.Perm (Fin n)) : VariableRelabeling` lifts an arbitrary finite permutation into the scoped surface.

The Python mirror in `src/non_shannon_search/symmetry.py` exposes 1:1 counterparts: `identity_perm(n)`, `transposition(n, i, j)`, `perm_from_tuple(n, values)` (validated against `range(n)`), and an iterator `iter_symmetric_group(n)` yielding each `S_n` element as a scoped permutation for `n <= 6`.

### Range validity

M1b makes the range discipline explicit. Add predicates stating that:

1. a `VariableSubset` is well-formed for `n` when every entry lies in `[0, n)`, and
1. an `InequalityVector` is well-formed when every term's subset is well-formed for `vector.variableCount`.

Normalization (sorted, duplicate-free subset representation) remains M1a's concern. M1b's new guarantee is preservation of in-range variable references.

### Action definitions

```text
actOnSubset (r : VariableRelabeling) (s : VariableSubset) : VariableSubset
actOnTerm   (r : VariableRelabeling) (t : InequalityTerm) : InequalityTerm
actOnVector (r : VariableRelabeling) (v : InequalityVector) : InequalityVector
```

`actOnSubset` maps `vars` pointwise through the scoped relabeling and then re-normalizes (M1a's `VariableSubset.normalize`). `actOnTerm` applies `actOnSubset` and leaves the coefficient unchanged. `actOnVector` applies `actOnTerm` termwise and does not re-canonicalize; the caller composes with `canonicalize` when a canonical output is needed. Decoupling the action from the canonicalizer keeps the action laws clean and avoids blurring M1b with M1c.

#### Supporting lemmas

Two small helper lemmas in `NonShannon/Inequality/Symmetry.lean` carry the weight of the action laws so the `example`s reduce to structural comparisons:

- `VariableSubset.normalize_map_commute`: for any `f : Var → Var` and `s : VariableSubset`, `(s.normalize.map f).normalize = (s.map f).normalize`. Needed by the composition law, because `actOnSubset r₁ (actOnSubset r₂ s)` normalizes an already-normalized intermediate while `actOnSubset (r₁ * r₂) s` normalizes only once. Both sides have the same element multiset after the combined map, so both normalize to the same list.
- `VariableRelabeling.actOnSubset_id`: `actOnSubset (VariableRelabeling.id n) s = s.normalize`. A direct consequence of `VariableSubset.normalize_idempotent` (M1a) together with the identity-outside-scope convention.

#### Removed helpers

`InequalityTerm.mapVars` (added in M0 as a non-scoped, non-normalizing primitive over a bare `Var → Var`) is removed in this milestone. Its only intra-repo caller, `VariableRelabeling.applyVector`, is rewritten on top of `actOnVector`, leaving `mapVars` as dead code. Carrying two near-synonyms (one scoped and re-normalizing, one bare) would be a readability hazard; `actOnTerm` is the single entry point. `VariableSubset.map` stays as the low-level primitive that `actOnSubset` layers normalization onto.

### Action laws

M1b ships one general theorem and three `example`-level laws.

General theorem in `NonShannon/Inequality/Canonical.lean`:

- `theorem canonicalize_idempotent (v : InequalityVector) : canonicalize (canonicalize v) = canonicalize v`. Proved via a two-part decomposition: `canonicalize_of_isCanonicalShape : isCanonicalShape v → canonicalize v = v` (structural, one clause per conjunct of the predicate) and `isCanonicalShape_canonicalize : isCanonicalShape (canonicalize v)` (output of each of the three canonicalizer passes satisfies the matching conjunct). Both subsidiary lemmas live in the same file and become useful beyond M1b: the composition law in the symmetry tests consumes the theorem, and M1c's orbit-representative argument needs every orbit element to already be a `canonicalize` fixed point.

Laws in `NonShannonTest/Inequality/Symmetry.lean`, provable by `example`:

- `canonicalize (actOnVector (VariableRelabeling.id n) v) = canonicalize v`.
- `canonicalize (actOnVector (r₁ * r₂) v) = canonicalize (actOnVector r₁ (actOnVector r₂ v))`, discharged through `canonicalize_idempotent` and `VariableSubset.normalize_map_commute`.
- If `v` is well-formed for its declared `variableCount`, then `actOnVector r v` is well-formed too.
- On the Zhang-Yeung fixture, `canonicalize (actOnVector (VariableRelabeling.swap 4 0 1) zhangYeungAveragedScaled.vector)` equals a named Lean value that mirrors the Python swap-zero-one output (see "Python mirror" below).

### `VariableRelabeling` upgrade

Replace the bootstrap placeholder:

```text
structure VariableRelabeling where
  image : Var → Var
```

with a scoped wrapper that carries a declared `variableCount : Nat` alongside data proving bijectivity on `[0, variableCount)` and behaving as the identity outside that range. The recommended Lean implementation wraps `Equiv.Perm (Fin variableCount)` and exposes the smart constructors described in "Scoped relabeling contract" (`id`, `swap`, `ofPerm`) so downstream modules (`NonShannon/Inequality/Canonical.lean`, future `NonShannon/CopyLemma/*`) never need to handle raw `Fin`-indexed data.

Update `VariableRelabeling.applySubset` and `applyVector` to delegate to the new `actOnSubset` / `actOnVector`, inserting re-normalization as needed and requiring the relabeling's scope to match the vector it acts on.

### Python mirror

`src/non_shannon_search/symmetry.py` (new):

- `apply_subset(perm: tuple[int, ...], subset: tuple[int, ...]) -> tuple[int, ...]`: applies the scoped permutation pointwise, returns the re-sorted tuple. Indices outside `range(len(perm))` are left fixed, matching the Lean out-of-range convention.
- `apply_term(perm, term: Term) -> Term`.
- `apply_candidate(perm, candidate: CandidateInequality) -> CandidateInequality` (returns a non-canonicalized candidate; caller composes with `canonicalize_candidate`).
- `identity_perm(n: int) -> tuple[int, ...]`, `transposition(n: int, i: int, j: int) -> tuple[int, ...]`, `perm_from_tuple(n: int, values: tuple[int, ...]) -> tuple[int, ...]` (validated against `range(n)`), and `iter_symmetric_group(n: int)` yielding every `S_n` permutation for `n <= 6`.

Permutations are represented as `tuple[int, ...]` rather than `dict[int, int]` so the scope is explicit in the value's length and easy to validate against `candidate.variable_count`.

#### Cross-language parity mechanism

M1b reuses the closed-loop parity strategy M1a established with `NonShannonTest/Examples/ZhangYeungFromPython.lean`. `src/non_shannon_search/emit_lean.py` gains a second emitter that runs `apply_candidate(transposition(4, 0, 1), zhang_yeung)`, then `canonicalize_candidate` on the result, and prints a Lean module `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean` whose shape mirrors the M1a fixture. Three artifacts close the loop:

1. The emitted Lean fixture, checked into the repository under the canonical one-subset-index-per-line formatting used by the M1a fixture.
1. A `pytest` golden test (`test_generated_zhang_yeung_swap_module_matches_python_emitter` in `tests/test_emit_lean.py` or `tests/test_symmetry.py`) that re-runs the emitter and compares its output byte-for-byte to the checked-in file.
1. A Lean `example` in `NonShannonTest/Examples/ZhangYeung.lean` asserting `rfl` equality between `zhangYeungSwapZeroOneFromPython.vector` and `canonicalize (actOnVector (VariableRelabeling.swap 4 0 1) zhangYeungAveragedScaled.vector)`.

If any of those three diverges, one of them fails loudly.

## Execution order

1. **Add range validity predicates** in `NonShannon/Inequality/Subsets.lean` and `NonShannon/Inequality/Vector.lean` so range-scoped relabelings have an explicit preservation target.
1. **Prove `canonicalize_idempotent`** and its two supporting lemmas (`canonicalize_of_isCanonicalShape`, `isCanonicalShape_canonicalize`) in `NonShannon/Inequality/Canonical.lean`, and add one `example` in `NonShannonTest/Inequality/Canonical.lean` that consumes the general theorem (so it is exercised outside the fixture-specific idempotence `example` M1a shipped).
1. **Upgrade `VariableRelabeling`** in `NonShannon/Inequality/Canonical.lean` to the new scoped bijection-carrying structure. Add the `id`, `swap`, and `ofPerm` smart constructors. Rewrite `applySubset` and `applyVector` on top of the new action.
1. **Remove `InequalityTerm.mapVars`** from `NonShannon/Inequality/Vector.lean`; it has no callers after step 3.
1. **Add `NonShannon/Inequality/Symmetry.lean`** with `actOnSubset`, `actOnTerm`, `actOnVector`, the two supporting lemmas (`VariableSubset.normalize_map_commute`, `VariableRelabeling.actOnSubset_id`), and range-validity preservation lemmas. Ship the sibling test module `NonShannonTest/Inequality/Symmetry.lean` in the same commit as the action module; it carries the identity-action, composition, range-preservation, and named Zhang-Yeung swap `example`s.
1. **Update `NonShannonTest/Inequality/Canonical.lean`** to replace the old `swapZeroOne : VariableRelabeling := { image := ... }` construction with the new smart-constructor form (expected shape: `private def swapZeroOne : VariableRelabeling := VariableRelabeling.swap 4 0 1`) and retarget the existing `applySubset` `example` so it still passes (expected shape: `(swapZeroOne.applySubset xz).vars = [1, 2]`).
1. **Add `src/non_shannon_search/symmetry.py`** with `apply_subset`, `apply_term`, `apply_candidate`, `identity_perm`, `transposition`, `perm_from_tuple`, and `iter_symmetric_group`. Add an emitter entry point under `src/non_shannon_search/emit_lean.py` that emits a second Python-generated Lean fixture, `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`, mirroring the M1a parity fixture's shape.
1. **Add `tests/test_symmetry.py`** with identity and composition laws after canonicalization, preservation of range validity, `canonicalize_candidate(apply_candidate(transposition(4, 0, 1), zhang_yeung))` matching a hard-coded expected value, and a byte-for-byte golden test against the checked-in `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`.
1. **Add a Lean `example`** in `NonShannonTest/Examples/ZhangYeung.lean` asserting `zhangYeungSwapZeroOneFromPython.vector = canonicalize (actOnVector (VariableRelabeling.swap 4 0 1) zhangYeungAveragedScaled.vector) := rfl`, closing the cross-language parity loop.
1. **Run `make check`.**

## Files touched

- New: `NonShannon/Inequality/Symmetry.lean`, `NonShannonTest/Inequality/Symmetry.lean`, `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`, `src/non_shannon_search/symmetry.py`, `tests/test_symmetry.py`.
- Modified: `NonShannon/Inequality/Subsets.lean` (range-validity predicate), `NonShannon/Inequality/Vector.lean` (range-validity predicate, remove `InequalityTerm.mapVars`), `NonShannon/Inequality/Canonical.lean` (scoped `VariableRelabeling` upgrade, `canonicalize_idempotent` theorem and its two supporting lemmas), `NonShannonTest/Inequality/Canonical.lean` (smart-constructor form for `swapZeroOne`, one `example` exercising `canonicalize_idempotent`), `NonShannonTest/Examples/ZhangYeung.lean` (swap-zero-one parity `example`), `src/non_shannon_search/emit_lean.py` (emit helper for the new parity fixture), `NonShannon.lean` (import new `Symmetry` module), `NonShannonTest.lean` (imports for the new test module and parity fixture).
- Not modified: the interchange schemas, any tracked data fixtures, the M1a parity fixture `NonShannonTest/Examples/ZhangYeungFromPython.lean`.

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` all green.

Sanity checks:

- Lean: `canonicalize_idempotent` ships as a `theorem`, with one `example` in `NonShannonTest/Inequality/Canonical.lean` exercising it beyond the fixture-specific M1a case.
- Lean: identity, composition, and range-preservation action laws by `example` after canonicalization, discharged through `canonicalize_idempotent` and the named supporting lemmas.
- Lean: `canonicalize (actOnVector (VariableRelabeling.swap 4 0 1) zhangYeungAveragedScaled.vector) = zhangYeungSwapZeroOneFromPython.vector` by `rfl` (not equal to the original canonical form itself; that equivalence is M1c).
- Python: identity and composition laws; preservation of range validity; `canonicalize_candidate(apply_candidate(transposition(4, 0, 1), zhang_yeung))` matches a hard-coded expected value.
- Cross-language: the golden test compares the emitter output byte-for-byte against the checked-in `NonShannonTest/Examples/ZhangYeungSwapZeroOneFromPython.lean`, closing the Python → Lean loop; the Lean `rfl` `example` closes the Lean-side assertion.

## Commit strategy

1. `feat(lean): prove canonicalize_idempotent and isCanonicalShape lemmas`
1. `refactor(lean): scope VariableRelabeling to the declared variable range`
1. `refactor(lean): remove InequalityTerm.mapVars in favor of actOnTerm`
1. `feat(lean): add scoped symmetry action, supporting lemmas, and test module`
1. `feat(python): add symmetry module mirroring the Lean action`
1. `feat(python): emit Python-generated Lean fixture for swap-zero-one parity`
1. `test(python): cover action laws and the swap-zero-one golden test`
1. `test(lean): close the cross-language parity loop in ZhangYeung`

## Open questions and risks

- **Internal finite representation (resolved).** Internal data is `Equiv.Perm (Fin variableCount)`, with smart constructors (`id`, `swap`, `ofPerm`) as the public surface so callers never touch raw `Fin` values. Identity outside scope is the documented convention. If `Equiv.Perm (Fin n)` turns out awkward to thread through helper lemmas, add a thin wrapper API rather than loosening the scope discipline.
- **Canonicalization in the action.** `actOnSubset` re-normalizes its output; `actOnVector` does not re-canonicalize. That means two applications of a non-trivial permutation to a non-canonical input can yield a non-canonical output. Documented in the module docstring.
- **Python permutation representation (resolved).** `tuple[int, ...]` is the scoped mirror; the `perm_from_tuple` validator in `symmetry.py` rejects out-of-range entries at construction.
- **`VariableRelabeling` churn (resolved).** The one intra-repo caller of the old surface is `NonShannonTest/Inequality/Canonical.lean`; step 6 of "Execution order" rewrites it to the new smart-constructor form (`VariableRelabeling.swap 4 0 1`).
- **General `canonicalize_idempotent` theorem (resolved, now a deliverable).** The 2026-04-21 M1a branch review flagged this as M1b/M1c territory. M1b commits to shipping the general theorem rather than proving the stated identity via ad hoc component lemmas: the composition law in the symmetry tests needs it, and M1c's orbit-representative argument needs it again. Proof strategy: `canonicalize_of_isCanonicalShape` plus `isCanonicalShape_canonicalize`, both on top of the `isCanonicalShape` predicate that M1a already shipped.

## Why this shape is the right adaptation

M1b is the layer where "symmetry" stops being a vague organizing principle and becomes a typed, testable scoped group action. Splitting it out from M1c (orbit selection) keeps the action's correctness concerns separate from the representative-choice concerns: action laws and preservation of range validity are algebraic and mechanical; orbit representatives are a total-order choice on a finite set. Those are different kinds of argument and benefit from independent gates.
