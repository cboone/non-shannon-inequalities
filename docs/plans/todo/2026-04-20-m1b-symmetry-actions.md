# 2026-04-20 M1b: Symmetry Group Actions

Implementation plan for milestone M1b of the Track A Discovery Roadmap (`docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`, Section 6).

## Context

M1a landed a within-inequality canonical form: duplicate-term combination, subset-sorted term ordering, and sign normalization, identical between Lean and Python on the Zhang-Yeung fixture. That canonical form makes equality checks meaningful but does not express the permutation symmetry that every downstream milestone depends on.

The bootstrap layer has a placeholder `VariableRelabeling` structure in `NonShannon/Inequality/Canonical.lean` that wraps a bare function `image : Var -> Var`. It has no bijectivity invariant, no group structure, and no lifted action on `InequalityVector` beyond a list-map. That is enough to write syntactic relabelings but not enough to reason about symmetry orbits.

M1b replaces the placeholder with a proper group action of `Equiv.Perm Var` (or a finite-index specialization where the action is interesting) on `VariableSubset`, `InequalityTerm`, and `InequalityVector`, with action laws proved by `example`. The cross-language contract is established by mirroring the same action in `src/non_shannon_search/symmetry.py`.

M1b does not attempt orbit-representative selection or orbit-ID plumbing; those are M1c.

## Goal

After M1b, the following hold:

- `Equiv.Perm Var` acts on `InequalityVector` through `actOnVector`, with identity and composition laws proved by `example`.
- `VariableRelabeling` carries a bijectivity invariant (either by wrapping `Equiv.Perm Var` or by an explicit predicate) and is definitionally usable by downstream modules.
- Applying an action and re-canonicalizing (M1a) is well-defined in both languages: `canonicalize (actOnVector p v) = canonicalize (actOnVector p (canonicalize v))`.
- The Python `src/non_shannon_search/symmetry.py` exposes parallel functions with identical behavior on the Zhang-Yeung fixture.

## Approach

### The `Var` type

`Var` is `abbrev Var := Nat` in `NonShannon/Prelude.lean`. `Equiv.Perm Nat` exists in Mathlib but its structure is the group of all bijections of `Nat`, which is not helpful for finite searches. In practice the action is indexed by the base variable count `n` (for Zhang-Yeung, `n = 4`).

Two workable options:

1. Continue to use `Equiv.Perm Var` (that is, `Equiv.Perm Nat`) and restrict to permutations that are the identity outside `Fin n`. Practical and matches how search code will generate permutations.
1. Parameterize the action by `n : Nat` and use `Equiv.Perm (Fin n)`, with an explicit embedding `Fin n -> Var` when acting on `InequalityVector` values whose `variableCount = n`.

**Resolved:** option 1. Use `Equiv.Perm Var`, but construct permutations in practice as `Equiv.Perm Var` values built from `Fin n` data through `Equiv.Perm.extendSubtype` or an equivalent Mathlib helper. Reason: it keeps the action type flat, matches the Python side (which builds permutations as `dict[int, int]` or `tuple[int, ...]`), and avoids threading an `n` parameter through every downstream type.

### Action definitions

```text
actOnSubset (p : Equiv.Perm Var) (s : VariableSubset) : VariableSubset
actOnTerm   (p : Equiv.Perm Var) (t : InequalityTerm) : InequalityTerm
actOnVector (p : Equiv.Perm Var) (v : InequalityVector) : InequalityVector
```

`actOnSubset` maps `vars` pointwise through `p` and then re-normalizes (M1a's `VariableSubset.normalize`). `actOnTerm` applies `actOnSubset` and leaves the coefficient unchanged. `actOnVector` applies `actOnTerm` termwise and does not re-canonicalize; the caller composes with `canonicalize` when a canonical output is needed. Decoupling the action from the canonicalizer keeps the action laws clean.

### Action laws

Provable by `example` in `NonShannonTest/Inequality/Symmetry.lean`:

- `actOnVector (1 : Equiv.Perm Var) v = v` after canonicalization of both sides (the identity may leave `vars` unsorted if the input was not canonical to begin with, which is why canonicalization is part of the law).
- `actOnVector (p * q) v = actOnVector p (actOnVector q v)`.
- On the Zhang-Yeung fixture, `actOnVector (swap 0 1) zhangYeungAveragedScaled.vector` is a specific, named value that can be compared term-by-term.

### `VariableRelabeling` upgrade

Replace:

```text
structure VariableRelabeling where
  image : Var -> Var
```

with a wrapper around `Equiv.Perm Var`. Either:

```text
structure VariableRelabeling where
  perm : Equiv.Perm Var
```

or inline the `Equiv` fields. Prefer the wrapper so downstream modules (`NonShannon/Inequality/Canonical.lean`, future `NonShannon/CopyLemma/*`) can still pattern-match against `VariableRelabeling.mk _`.

Update `VariableRelabeling.applySubset` and `applyVector` to delegate to the new `actOnSubset` / `actOnVector`, inserting re-normalization as needed.

### Python mirror

`src/non_shannon_search/symmetry.py` (new):

- `apply_subset(perm: dict[int, int], subset: tuple[int, ...]) -> tuple[int, ...]`: applies `perm` pointwise, returns the re-sorted tuple.
- `apply_term(perm, term: Term) -> Term`
- `apply_candidate(perm, candidate: CandidateInequality) -> CandidateInequality` (returns a non-canonicalized candidate; caller composes with `canonicalize_candidate`).
- `identity_perm(n: int) -> dict[int, int]`, `transposition(n: int, i: int, j: int) -> dict[int, int]`, and a small `iter_symmetric_group(n: int)` that yields every `S_n` permutation for `n <= 6`.

Permutations are represented as `dict[int, int]` for clarity; an alternative `tuple[int, ...]` representation is fine if it ends up simpler. Decide during implementation; document the choice in the module docstring.

## Execution order

1. **Add `NonShannon/Inequality/Symmetry.lean`** with `actOnSubset`, `actOnTerm`, `actOnVector`, and the identity and composition laws as `theorem`s or `@[simp]` lemmas (keep them minimal; the test module will also have `example`s).
1. **Upgrade `VariableRelabeling`** in `NonShannon/Inequality/Canonical.lean` to wrap `Equiv.Perm Var`. Rewrite `applySubset` and `applyVector` on top of the new action. Add a deprecation note only if downstream code breaks; prefer to keep the public API intact.
1. **Add `NonShannonTest/Inequality/Symmetry.lean`** with the identity-action law, composition law, and a named Zhang-Yeung `swap 0 1` `example`.
1. **Add `src/non_shannon_search/symmetry.py`** with the parallel functions.
1. **Add `tests/test_symmetry.py`** with: identity and composition laws; application of `swap 0 1` to Zhang-Yeung matching a named expected value; cross-language parity (Python `apply_candidate(p, zhang_yeung)` canonicalized via `canonicalize_candidate` equals the Lean output for the same `p` and the same fixture).
1. **Run `make check`.**

## Files touched

- New: `NonShannon/Inequality/Symmetry.lean`, `NonShannonTest/Inequality/Symmetry.lean`, `src/non_shannon_search/symmetry.py`, `tests/test_symmetry.py`.
- Modified: `NonShannon/Inequality/Canonical.lean` (`VariableRelabeling`), `NonShannonTest/Inequality/Canonical.lean` (update examples that exercise `VariableRelabeling`), `NonShannon.lean` (import new `Symmetry` module), `NonShannonTest.lean` (import new test module).
- Not modified: the canonicalizer itself beyond re-normalization calls, the interchange schemas, any fixtures.

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` all green.

Sanity checks:

- Lean: identity and composition laws by `example` (structural `rfl` after canonicalization, or `simp` with the action lemmas).
- Lean: `swap 0 1` applied to Zhang-Yeung produces a specific term list (named) whose canonical form is equal to the original's canonical form's `actOnVector (swap 0 1) _` value (not to the original canonical form itself; that equivalence is M1c).
- Python: identity and composition; `apply_candidate(swap(0, 1), zhang_yeung)` canonicalized matches the named expected value.
- Cross-language: Lean `swap 0 1` output and Python `swap(0, 1)` output have equal canonical JSON serializations when parsed with the same schema.

## Commit strategy

1. `feat(lean): add Equiv.Perm action on subsets, terms, and vectors`
1. `refactor(lean): upgrade VariableRelabeling to wrap Equiv.Perm Var`
1. `test(lean): cover action laws in NonShannonTest/Inequality/Symmetry.lean`
1. `feat(python): add symmetry module mirroring the Lean action`
1. `test(python): cover action laws and cross-language parity`

## Open questions and risks

- **`Equiv.Perm Var` vs. `Equiv.Perm (Fin n)`.** Resolved above in favor of `Equiv.Perm Var`. If downstream code finds this awkward during M1c (for example, orbit enumeration of `S_n`), reconsider; the switch is mechanical.
- **Canonicalization in the action.** `actOnSubset` re-normalizes its output; `actOnVector` does not re-canonicalize. That means two applications of a non-trivial permutation to a non-canonical input can yield a non-canonical output. Documented in the module docstring.
- **Python permutation representation.** `dict[int, int]` is the clearest; `tuple[int, ...]` is faster if performance becomes a concern. Reevaluate at M1c or M5.
- **`VariableRelabeling` churn.** Any downstream code that constructs a `VariableRelabeling` from a bare function now needs `Equiv.ofBijective` or an explicit `Equiv.Perm` construction. No downstream caller exists at M1b's start (grep for `VariableRelabeling.mk` confirms), but anything landed in parallel with M1b will need a touch-up.

## Why this shape is the right adaptation

M1b is the layer where "symmetry" stops being a vague organizing principle and becomes a typed, testable group action. Splitting it out from M1c (orbit selection) keeps the action's correctness concerns separate from the representative-choice concerns: action laws are algebraic and mechanical; orbit representatives are a total-order choice on a finite set. Those are different kinds of argument and benefit from independent gates.
