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

### Action laws

Provable by `example` in `NonShannonTest/Inequality/Symmetry.lean`:

- `canonicalize (actOnVector 1 v) = canonicalize v`.
- `canonicalize (actOnVector (r₁ * r₂) v) = canonicalize (actOnVector r₁ (actOnVector r₂ v))`.
- If `v` is well-formed for its declared `variableCount`, then `actOnVector r v` is well-formed too.
- On the Zhang-Yeung fixture, `actOnVector (swap 0 1) zhangYeungAveragedScaled.vector` is a specific, named value that can be compared term-by-term after canonicalization.

### `VariableRelabeling` upgrade

Replace:

```text
structure VariableRelabeling where
  variableCount : Nat
  image : Var -> Var
  ...
```

with a scoped wrapper whose data proves bijectivity on the in-range variables. The recommended Lean implementation is a wrapper around `Equiv.Perm (Fin variableCount)` plus helpers that apply it to `Var` values known to be in range. Prefer the wrapper so downstream modules (`NonShannon/Inequality/Canonical.lean`, future `NonShannon/CopyLemma/*`) can still pattern-match against `VariableRelabeling.mk ...` without exposing the finite-index implementation everywhere.

Update `VariableRelabeling.applySubset` and `applyVector` to delegate to the new `actOnSubset` / `actOnVector`, inserting re-normalization as needed and requiring the relabeling's scope to match the vector it acts on.

### Python mirror

`src/non_shannon_search/symmetry.py` (new):

- `apply_subset(perm: tuple[int, ...], subset: tuple[int, ...]) -> tuple[int, ...]`: applies the scoped permutation pointwise, returns the re-sorted tuple.
- `apply_term(perm, term: Term) -> Term`
- `apply_candidate(perm, candidate: CandidateInequality) -> CandidateInequality` (returns a non-canonicalized candidate; caller composes with `canonicalize_candidate`).
- `identity_perm(n: int) -> tuple[int, ...]`, `transposition(n: int, i: int, j: int) -> tuple[int, ...]`, and a small `iter_symmetric_group(n: int)` that yields every `S_n` permutation for `n <= 6`.

Permutations are represented as `tuple[int, ...]` rather than `dict[int, int]` so the scope is explicit in the value's length and easy to validate against `candidate.variable_count`.

## Execution order

1. **Add range validity predicates** in `NonShannon/Inequality/Subsets.lean` and `NonShannon/Inequality/Vector.lean` so range-scoped relabelings have an explicit preservation target.
1. **Add `NonShannon/Inequality/Symmetry.lean`** with `actOnSubset`, `actOnTerm`, `actOnVector`, plus minimal lemmas for identity, composition, and preservation of range validity.
1. **Upgrade `VariableRelabeling`** in `NonShannon/Inequality/Canonical.lean` to the new scoped bijection-carrying structure. Rewrite `applySubset` and `applyVector` on top of the new action. Add a deprecation note only if downstream code breaks; prefer to keep the public API intact.
1. **Add `NonShannonTest/Inequality/Symmetry.lean`** with the identity-action law after canonicalization, composition law after canonicalization, preservation of range validity, and a named Zhang-Yeung `swap 0 1` `example`.
1. **Add `src/non_shannon_search/symmetry.py`** with the parallel functions.
1. **Add `tests/test_symmetry.py`** with: identity and composition laws after canonicalization; preservation of range validity; application of `swap 0 1` to Zhang-Yeung matching a named expected value; cross-language parity (Python `apply_candidate(r, zhang_yeung)` canonicalized via `canonicalize_candidate` equals the Lean output for the same `r` and the same fixture).
1. **Run `make check`.**

## Files touched

- New: `NonShannon/Inequality/Symmetry.lean`, `NonShannonTest/Inequality/Symmetry.lean`, `src/non_shannon_search/symmetry.py`, `tests/test_symmetry.py`.
- Modified: `NonShannon/Inequality/Subsets.lean`, `NonShannon/Inequality/Vector.lean`, `NonShannon/Inequality/Canonical.lean` (`VariableRelabeling`), `NonShannonTest/Inequality/Canonical.lean` (update examples that exercise `VariableRelabeling`), `NonShannon.lean` (import new `Symmetry` module), `NonShannonTest.lean` (import new test module).
- Not modified: the canonicalizer itself beyond re-normalization calls, the interchange schemas, any fixtures.

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` all green.

Sanity checks:

- Lean: identity and composition laws by `example` after canonicalization (structural `rfl` or `simp` with the action lemmas).
- Lean: preservation of range validity for the Zhang-Yeung fixture and a small synthetic vector.
- Lean: `swap 0 1` applied to Zhang-Yeung produces a specific term list (named) whose canonical form is equal to the original's canonical form's `actOnVector (swap 0 1) _` value (not to the original canonical form itself; that equivalence is M1c).
- Python: identity and composition; preservation of range validity; `apply_candidate(swap(0, 1), zhang_yeung)` canonicalized matches the named expected value.
- Cross-language: Lean `swap 0 1` output and Python `swap(0, 1)` output have equal canonical JSON serializations when parsed with the same schema.

## Commit strategy

1. `feat(lean): add scoped symmetry action on subsets, terms, and vectors`
1. `refactor(lean): scope VariableRelabeling to the declared variable range`
1. `test(lean): cover action laws in NonShannonTest/Inequality/Symmetry.lean`
1. `feat(python): add symmetry module mirroring the Lean action`
1. `test(python): cover action laws and cross-language parity`

## Open questions and risks

- **Internal finite representation.** The public contract is resolved, but Lean may still need a little engineering to make a scoped `VariableRelabeling` ergonomic. If `Equiv.Perm (Fin n)` turns out awkward to thread through helper lemmas, add a thin wrapper API rather than loosening the scope discipline.
- **Canonicalization in the action.** `actOnSubset` re-normalizes its output; `actOnVector` does not re-canonicalize. That means two applications of a non-trivial permutation to a non-canonical input can yield a non-canonical output. Documented in the module docstring.
- **Python permutation representation.** `tuple[int, ...]` is now the resolved mirror of the scoped Lean contract. If debugging ergonomics suffer, add formatter helpers rather than changing the representation.
- **`VariableRelabeling` churn.** Any downstream code that constructs a `VariableRelabeling` from a bare function now needs to build the scoped object instead. No downstream caller exists at M1b's start (grep for `VariableRelabeling.mk` confirms), but anything landed in parallel with M1b will need a touch-up.
- **General `canonicalize` idempotence / commutation lemma.** Tracked as a follow-up from the 2026-04-21 M1a branch review. The Goal section's identity `canonicalize (actOnVector r v) = canonicalize (actOnVector r (canonicalize v))` relies on a `canonicalize`-idempotence lemma that does not yet exist: M1a proves `canonicalize`-idempotence only by `example` on the Zhang-Yeung fixture. M1b either needs a general `canonicalize_idempotent : ∀ v, canonicalize (canonicalize v) = canonicalize v` theorem in `NonShannon/Inequality/Canonical.lean`, or a direct equality proof for the stated identity via component idempotence lemmas for `combineDuplicates`, `insertionSort`, and `normalizeSign`. Decide per `example`; if the goal identity reduces to a structural `rfl` after `canonicalize`-idempotence on the specific `actOnVector r v`, the general theorem may not be needed.

## Why this shape is the right adaptation

M1b is the layer where "symmetry" stops being a vague organizing principle and becomes a typed, testable scoped group action. Splitting it out from M1c (orbit selection) keeps the action's correctness concerns separate from the representative-choice concerns: action laws and preservation of range validity are algebraic and mechanical; orbit representatives are a total-order choice on a finite set. Those are different kinds of argument and benefit from independent gates.
