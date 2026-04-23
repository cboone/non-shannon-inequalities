---
applyTo: "NonShannon/**/*.lean"
---

# PR Review: Lean Library

- **Orbit-loop structure in `NonShannon/Inequality/Canonical.lean` is deliberate.** The private action helpers (`applyPermutationIndex`, `actOnSubsetValues`, `actOnVectorValues`) and the `orbitImages` intermediate list are retained to keep the orbit loop structurally simple for kernel `decide` / `native_decide` reducibility on Zhang-Yeung-scale vectors. Do not suggest fusing `orbitImages` into `orbitCanonical` / `orbitMin`, replacing the private helpers with the public `actOnVector` surface via `VariableRelabeling.ofPerm`, or otherwise coupling the orbit enumeration to the lex-min comparator. The rationale is documented in the extended comment above `applyPermutationIndex`, and the branch review at `docs/reviews/2026-04-22-research-implement-phase-m1c.md` records the trade-off.
- **No `variableCount` caps on orbit enumeration.** `orbitImages`, `orbitCanonical`, and `orbitIdOf` intentionally enumerate the full symmetric group on `variableCount` indices without an upper bound, mirroring the Python-side decision in commit `3929fa5` (`fix(python): support larger orbit scopes`). Do not suggest adding a numeric cap, a "small `variableCount` only" docstring warning, or guarded fallbacks. Orbit enumeration is factorial by definition; callers opt in by invoking the orbit surface.
