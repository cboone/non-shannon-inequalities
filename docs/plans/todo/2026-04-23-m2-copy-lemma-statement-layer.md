# 2026-04-23 M2: Parameterized Copy-Lemma Statement Layer

Implementation plan for milestone M2 of the Track A Discovery Roadmap (`docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`, Section 6).

## Context

M0 shipped a placeholder `parameterizedCopyLemma : ParameterizedCopyLemmaShape` defined as `params.copyCount = 0 ∨ 0 < params.copyCount`, which is trivially satisfied on every `CopyParameters` input. The placeholder exists so downstream milestones can import a stable name before the real shape is designed. M1a, M1b, and M1c finished the inequality-side representation layer: canonical form, scoped symmetry action, orbit representative, orbit ID in the schema.

M2 is where the copy-lemma side catches up. It replaces the placeholder with a typed statement shape that downstream search code (M5) can target and that M3's oracle can annotate. It also lands the bridge between M1's symmetry layer and copy-lemma parameters, so two parameter sets that differ only by a scoped relabeling of the underlying variables are recognized as generating the same statement up to relabeling.

The roadmap (Section 6, M2) names four deliverables: the typed shape, additional invariants on `CopyParameters`, the first nontrivial statement-layer lemma, and a naming-convention research note. This plan groups them into three implementation layers (data, action, convention) landed under a single milestone gate.

## Goal

After M2, the following hold:

1. `NonShannon/CopyLemma/Parameterized.lean` exports a typed `CopyLemmaStatement` record (exact field list in the approach below). The placeholder `parameterizedCopyLemma`, `parameterizedCopyLemmaSpec`, and `ParameterizedCopyLemmaShape` are removed. `ParameterizedCopyLemmaTarget` is retained as theorem-generation metadata and gains a docstring clarifying its intended use alongside `CopyLemmaStatement`.
1. `NonShannon/CopyLemma/Parameters.lean` carries a `CopyParameters.isWellFormed` predicate (disjointness of `frozen`, `copied`, `conditioning`; all three in-range for `variableCount`; all three normalized), a `CopyParameterShape` projection that forgets non-structural metadata, and a scoped `relabel` action backed by the `VariableRelabeling` surface from `NonShannon/Inequality/Symmetry.lean`.
1. `CopyLemmaStatement.ofParameters : CopyParameters → CopyLemmaStatement` is defined in `NonShannon/CopyLemma/Parameterized.lean` and produces a well-formed statement when applied to well-formed parameters.
1. The characterization lemma `CopyParameters.sameStatementShape_iff_ofParameters_sameShape` expresses: for well-formed parameters `a`, `b`, there is a scoped relabeling witnessing equality between their statement-bearing structural projections (not their `label` or user-provided `conditionalIndependence` metadata) if and only if there is a scoped relabeling witnessing `CopyLemmaStatement.ofParameters b = (CopyLemmaStatement.ofParameters a).relabel r`.
1. `docs/research/copy-lemma-naming.md` documents the theorem-name and module-name templates for future generated copy-lemma statements, and records the frozen field layout of `CopyLemmaStatement` together with the frozen derivation rule for its `independence` field as of M2 closure.
1. `NonShannonTest/CopyLemma/Parameters.lean` and the new `NonShannonTest/CopyLemma/Parameterized.lean` exercise the public surface from outside `NonShannon`; `lake test` picks them up via `NonShannonTest.lean`.

## Approach

### 1. The `CopyLemmaStatement` record

Two candidate shapes:

1. **Flat record mirroring `CopyParameters`.** Same fields (`variableCount`, `frozen`, `copied`, `conditioning`, `copyCount`) plus a derived `independence : List ConditionalIndependencePattern`. The statement is a view of the parameters; `ofParameters` is the identity extended with the derived field.
1. **Record organized around copy operations.** Fields: `variableCount`, `frozen`, `copyPrototype : CopyBlock`, `copyCount`, `copies : List CopyBlock` (each `CopyBlock` is one copy operation with its `copied` and `conditioning` subsets), `independence : List ConditionalIndependencePattern`. Supports future multi-block copy families without a schema change while preserving the current single-block parameters even when `copyCount = 0`.

**Resolved:** option 2, with one correction to preserve the current single-block shape exactly. The long-run search surface (M5) wants to enumerate copy-lemma families with varying numbers of copy blocks. Baking one copy block per statement into the shape would force a revision the first time a two-block family lands; a list-of-blocks shape carries the variation at M2's cost. But M2 also has to make the reverse direction of the bridge theorem true for the legitimate `copyCount = 0` case, so the statement keeps the current single-block data explicitly as `copyPrototype` alongside the future-facing `copies` list. The result is two new small records:

```lean
structure CopyBlock where
  copied : VariableSubset
  conditioning : VariableSubset
  deriving DecidableEq, Inhabited

structure CopyLemmaStatement where
  variableCount : Nat
  frozen : VariableSubset
  copyPrototype : CopyBlock
  copyCount : Nat
  copies : List CopyBlock
  independence : List ConditionalIndependencePattern
  deriving DecidableEq, Inhabited
```

For the current `CopyParameters` shape (single-block copy with `copyCount` repetitions of the same block), `ofParameters` sets `copyPrototype := { copied := params.copied, conditioning := params.conditioning }`, emits `params.copyCount` identical entries in `copies`, and sets `copyCount := params.copyCount`. This keeps `CopyLemmaStatement` stable across later parameter-shape refinements that introduce heterogeneous blocks while ensuring the current `copied` and `conditioning` fields remain recoverable even when `copyCount = 0`.

The `independence` field is no longer left semantically open at M2. It is frozen as the structural list induced by the current single-block copy construction:

```lean
def CopyLemmaStatement.inducedIndependence (params : CopyParameters) :
    List ConditionalIndependencePattern :=
  List.replicate params.copyCount
    { left := params.copied
      right := params.frozen
      given := params.conditioning }
```

`CopyLemmaStatement.ofParameters` uses this exact definition. The M2 freeze note in `docs/research/copy-lemma-naming.md` therefore records both the field layout and this derivation rule, not only the field names.

### 2. Well-formedness on `CopyParameters`

```lean
def VariableSubset.Disjoint (a b : VariableSubset) : Prop :=
  ∀ var ∈ a.vars, var ∉ b.vars

structure CopyParameters.IsWellFormed (params : CopyParameters) : Prop where
  frozenInRange : params.frozen.IsInRange params.variableCount
  copiedInRange : params.copied.IsInRange params.variableCount
  conditioningInRange : params.conditioning.IsInRange params.variableCount
  frozenNormalized : params.frozen.isNormalized
  copiedNormalized : params.copied.isNormalized
  conditioningNormalized : params.conditioning.isNormalized
  frozenCopiedDisjoint : VariableSubset.Disjoint params.frozen params.copied
  frozenConditioningDisjoint : VariableSubset.Disjoint params.frozen params.conditioning
  copiedConditioningDisjoint : VariableSubset.Disjoint params.copied params.conditioning
```

All nine components are already `Decidable` (either via M1a/M1b or via `List.mem`), so `params.IsWellFormed` is `Decidable` and checkable by `decide` on Zhang-Yeung-scale fixtures. `copyCount` intentionally has no lower-bound constraint: `copyCount = 0` is the degenerate no-copy case and is legitimate at this layer, to match how M3's future oracle may treat "no copies required" as a sentinel. The corrected statement shape above keeps the underlying `copied` and `conditioning` data in `copyPrototype`, so the bridge theorem does not need to exclude the zero-copy case.

Naming note: the predicate is `IsWellFormed` (uppercase `I`) to follow Mathlib's convention for bundled `Prop`-valued predicates, matching the existing `VariableSubset.IsInRange` in `NonShannon/Inequality/Subsets.lean`. `VariableSubset.Disjoint` follows the same convention.

### 3. Relabeling action on `CopyParameters` and `CopyLemmaStatement`

`CopyParameters.relabel : (params : CopyParameters) → (r : VariableRelabeling) → r.variableCount = params.variableCount → CopyParameters` applies the scoped M1b action `actOnSubset` to `frozen`, `copied`, and `conditioning`; preserves `variableCount`, `copyCount`, and `label`; and remaps `conditionalIndependence` elementwise via a small `ConditionalIndependencePattern.relabel` helper. That helper is shared with the statement layer. The statement-shape bridge below does not quotient by `label` or user-provided `conditionalIndependence`; it quotients by the smaller `CopyParameterShape` projection introduced in this milestone.

`CopyLemmaStatement.relabel` applies `actOnSubset` to `frozen`, to `copyPrototype`, and to each `CopyBlock`'s `copied` and `conditioning`; preserves `copyCount`; and remaps the `independence` patterns elementwise via the same `ConditionalIndependencePattern.relabel` helper.

Key lemmas landed in M2:

- `actOnSubset_Disjoint`: if two subsets are disjoint and both in-range for the relabeling's scope, their images under `actOnSubset` are disjoint. Follows from the fact that `actOnSubset` factors through the permutation and normalization, and permutations restricted to a shared scope are bijective on images.
- `CopyParameters.relabel_IsWellFormed`: `relabel` preserves `IsWellFormed`. Composes `actOnSubset_Disjoint` with M1b's range-preservation and normalization-preservation results.
- `CopyParameters.statementShape_relabel`: the structural projection commutes with `relabel`, so statement-shape equivalence is explicitly about the statement-bearing fields and not about debug or annotation metadata.
- `CopyLemmaStatement.ofParameters_relabel`: the commuting square `CopyLemmaStatement.ofParameters (params.relabel r h) = (CopyLemmaStatement.ofParameters params).relabel r h` under the scope hypothesis `h : r.variableCount = params.variableCount`.

### 4. Statement-equivalence characterization

Definitional structural projection on parameters:

```lean
structure CopyParameterShape where
  variableCount : Nat
  frozen : VariableSubset
  copied : VariableSubset
  conditioning : VariableSubset
  copyCount : Nat
```

```lean
def CopyParameters.statementShape (params : CopyParameters) : CopyParameterShape :=
  { variableCount := params.variableCount
    frozen := params.frozen
    copied := params.copied
    conditioning := params.conditioning
    copyCount := params.copyCount }
```

```lean
def CopyParameterShape.relabel (shape : CopyParameterShape) (r : VariableRelabeling)
    (h : r.variableCount = shape.variableCount) : CopyParameterShape :=
  { variableCount := shape.variableCount
    frozen := actOnSubset r shape.frozen
    copied := actOnSubset r shape.copied
    conditioning := actOnSubset r shape.conditioning
    copyCount := shape.copyCount }
```

The structural projection is intentionally the statement-bearing part only. Existing `CopyParameters` fields `label : String` and `conditionalIndependence : List ConditionalIndependencePattern` remain on the record as debugging and user-annotation metadata, but they do not participate in statement-shape equality because `CopyLemmaStatement.ofParameters` does not encode them.

Definitional equivalence on parameters:

```lean
def CopyParameters.SameStatementShape (a b : CopyParameters) : Prop :=
  a.statementShape.variableCount = b.statementShape.variableCount ∧
    ∃ (r : VariableRelabeling) (h : r.variableCount = a.statementShape.variableCount),
      b.statementShape = a.statementShape.relabel r h
```

Definitional equivalence on statements:

```lean
def CopyLemmaStatement.SameShape (s t : CopyLemmaStatement) : Prop :=
  s.variableCount = t.variableCount ∧
    ∃ (r : VariableRelabeling) (h : r.variableCount = s.variableCount),
      t = s.relabel r h
```

The characterization lemma, which is M2's first nontrivial statement-layer result:

```lean
theorem CopyParameters.sameStatementShape_iff_ofParameters_sameShape
    {a b : CopyParameters}
    (ha : a.IsWellFormed) (hb : b.IsWellFormed) :
    a.SameStatementShape b ↔
      (CopyLemmaStatement.ofParameters a).SameShape (CopyLemmaStatement.ofParameters b)
```

The forward direction follows from `ofParameters_relabel` (the commuting square). The reverse direction extracts the witness relabeling from the statement-level equivalence and reconstructs parameter-level structural equivalence by reading back the relabeled `frozen`, `copyPrototype.copied`, `copyPrototype.conditioning`, and `copyCount` from the statement's fields. The reverse is the nontrivial half and the reason M2 requires both sides to be `IsWellFormed`: without disjointness, the statement's structural fields could collapse under normalization in ways that hide the original block split. The corrected `copyPrototype` field is what makes the reverse direction remain true in the legitimate `copyCount = 0` case, and the structural projection is what prevents `label` or user-supplied `conditionalIndependence` metadata from falsifying the parameter-side equivalence.

### 5. Removed: placeholder `parameterizedCopyLemma` surface

The current `parameterizedCopyLemmaSpec`, its `ParameterizedCopyLemmaShape` alias, and the `parameterizedCopyLemma` value are deleted in their entirety. The only caller is `NonShannonTest/CopyLemma/Parameters.lean`, which has a single `example` exercising the trivially-true spec. That `example` is replaced with `IsWellFormed` and `ofParameters` checks in the same change (see Execution step 7).

Rationale: keeping trivially-true placeholder aliases past M2 creates a maintenance tax (every future extension must decide whether to update the placeholder or ignore it) with no payoff. The M0 bootstrap promise was "a stable type name for downstream imports to land against"; after M2 the stable name is `CopyLemmaStatement`, which supersedes the placeholder.

`ParameterizedCopyLemmaTarget` (the theorem-generation metadata record) is **retained** per the roadmap and gains a docstring clarifying the split between the statement record (`CopyLemmaStatement`) and the generation metadata (`ParameterizedCopyLemmaTarget`).

### 6. Naming document

`docs/research/copy-lemma-naming.md` is new and covers:

- **Theorem-name template** for future-generated copy-lemma statements: `copyLemma_<familyDescriptor>_<orbitDigest>`, where `<familyDescriptor>` is a short ASCII tag chosen by the generator (for example, `zhangYeung`, `dfz31`) and `<orbitDigest>` is a short prefix of the parameter set's orbit ID. The orbit-ID format is already frozen by M1c.
- **Module-name template**: `NonShannon.CopyLemma.Generated.<family>`, with one module per generator family. Deliberately disjoint from the hand-authored `NonShannon.Examples.*` modules so generator output cannot collide with curated fixtures.
- **Interaction with `ParameterizedCopyLemmaTarget`**: the `theoremName` and `moduleName` fields are expected to follow the templates above going forward. M2 does not mechanically enforce this (the fields remain `String`); enforcement is a candidate for a later milestone if drift is observed.
- **Frozen statement-shape snapshot**: the exact field layout of `CopyLemmaStatement` (and `CopyBlock`) as of M2 closure, together with the frozen derivation rule for `independence`, so any future refactor of the shape must be accompanied by an explicit roadmap note acknowledging the break. Matches the "statement shape frozen" gate in the roadmap's M2 checkpoint.

The document is short (roughly 80 to 120 lines) and stabilizes conventions rather than introducing new machinery.

## Execution order

1. **Extend `NonShannon/CopyLemma/Parameters.lean`** with `VariableSubset.Disjoint`, `ConditionalIndependencePattern.relabel`, `CopyParameterShape`, `CopyParameters.statementShape`, `CopyParameters.IsWellFormed` (as a structure with nine fields), and `CopyParameters.relabel`. Add preservation lemmas (`actOnSubset_Disjoint`, `CopyParameters.relabel_IsWellFormed`, `CopyParameters.relabel_variableCount`, `CopyParameters.statementShape_relabel`) here.
1. **Add `CopyBlock` and `CopyLemmaStatement`** records to `NonShannon/CopyLemma/Parameterized.lean`, with `copyPrototype` and `copyCount` explicit on `CopyLemmaStatement`, and with their `DecidableEq` and `Inhabited` instances via `deriving`.
1. **Define `CopyLemmaStatement.relabel`** through `actOnSubset`, reusing `ConditionalIndependencePattern.relabel`.
1. **Define `CopyLemmaStatement.inducedIndependence` and `CopyLemmaStatement.ofParameters`** so `ofParameters` stores the prototype block explicitly, emits `params.copyCount` copies of it, and derives `independence` by the fixed M2 rule `copied ⟂ frozen | conditioning`, repeated `copyCount` times.
1. **Remove `parameterizedCopyLemmaSpec`, `ParameterizedCopyLemmaShape`, and `parameterizedCopyLemma`** from `NonShannon/CopyLemma/Parameterized.lean`. Add a docstring to `ParameterizedCopyLemmaTarget` clarifying its role alongside `CopyLemmaStatement`.
1. **Prove `ofParameters_relabel`**: the commuting square between `ofParameters` and `relabel` on both sides. This is the engine of the characterization lemma.
1. **State and prove `CopyParameters.sameStatementShape_iff_ofParameters_sameShape`** in `NonShannon/CopyLemma/Parameterized.lean`. The forward direction is one `rw` with `ofParameters_relabel`. The reverse direction unfolds the statement-level existential, extracts the witness relabeling, and rebuilds equality of the structural projection `statementShape` using `IsWellFormed` on both sides.
1. **Update `NonShannonTest/CopyLemma/Parameters.lean`**: keep the existing bootstrap fixture, but replace the `parameterizedCopyLemma` `example` with (a) `example : bootstrapParams.IsWellFormed := by decide`, (b) an `example` applying `VariableRelabeling.id 4` via `CopyParameters.relabel` and asserting the result still satisfies `IsWellFormed`.
1. **Add `NonShannonTest/CopyLemma/Parameterized.lean`** with:
   - An `example` constructing `CopyLemmaStatement.ofParameters bootstrapParams` and asserting its `variableCount = 4`.
   - An `example` asserting `CopyLemmaStatement.ofParameters bootstrapParams` preserves the prototype block explicitly and derives the expected `independence` list.
   - An `example` applying `VariableRelabeling.swap 4 0 1` and checking the commuting square.
   - An `example` invoking `sameStatementShape_iff_ofParameters_sameShape` on a concrete well-formed pair, including a `copyCount = 0` fixture.
   - An `example` showing two fixtures that differ only in `label` or user-provided `conditionalIndependence` still satisfy `SameStatementShape`.
   - An `example` constructing a `ParameterizedCopyLemmaTarget` whose `theoremName` begins with `"copyLemma_"` and whose `moduleName` begins with `"NonShannon.CopyLemma.Generated."`, proved by `decide` on `String.startsWith`.
1. **Wire the new test module into `NonShannonTest.lean`** by adding `import NonShannonTest.CopyLemma.Parameterized` next to the existing test imports.
1. **Write `docs/research/copy-lemma-naming.md`** per the structure in Approach section 6.
1. **Update the roadmap's M2 entry** in `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md` so it points at the concrete `2026-04-23-m2-copy-lemma-statement-layer.md` file and summarizes the corrected zero-copy and metadata-quotient decisions.
1. **Run `make check`.** Everything should be green; if a fixture or test breaks, the M2 pipeline has a bug.

## Files touched

- Modified: `NonShannon/CopyLemma/Parameters.lean`, `NonShannon/CopyLemma/Parameterized.lean`, `NonShannonTest/CopyLemma/Parameters.lean`, `NonShannonTest.lean`, `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`.
- New: `NonShannonTest/CopyLemma/Parameterized.lean`, `docs/research/copy-lemma-naming.md`.

No schema revisions, no fixture regenerations, no Python changes. M2 stays entirely inside the Lean statement layer plus one research note.

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make lint`, `make py-test` all green. `make lint` covers the roadmap and research-note edits that freeze the statement shape, while `make py-test` is retained for parity with the M1c gate even though M2 makes no Python changes.

Concrete sanity checks:

- `NonShannonTest/CopyLemma/Parameters.lean` proves `(bootstrapParams).IsWellFormed` by `decide`, and `((bootstrapParams).relabel (VariableRelabeling.id 4) rfl).IsWellFormed` similarly.
- `NonShannonTest/CopyLemma/Parameterized.lean` proves:
  1. `(CopyLemmaStatement.ofParameters bootstrapParams).variableCount = 4`.
  1. `(CopyLemmaStatement.ofParameters bootstrapParams).copyPrototype = { copied := bootstrapParams.copied, conditioning := bootstrapParams.conditioning }` and its `independence` field is exactly `List.replicate bootstrapParams.copyCount { left := bootstrapParams.copied, right := bootstrapParams.frozen, given := bootstrapParams.conditioning }`.
  1. For `r := VariableRelabeling.swap 4 0 1`, `CopyLemmaStatement.ofParameters (bootstrapParams.relabel r hScope) = (CopyLemmaStatement.ofParameters bootstrapParams).relabel r hScope` (the commuting square at one named transposition).
  1. `bootstrapParams.SameStatementShape (bootstrapParams.relabel r hScope)` is derivable directly from the definition, and the theorem still closes on a zero-copy fixture because `copyPrototype` retains the structural block when `copies = []`.
  1. Two fixtures that differ only in `label` or `conditionalIndependence` still satisfy `SameStatementShape`, confirming that the relation quotients away non-structural metadata exactly as intended.
  1. `(target : ParameterizedCopyLemmaTarget).theoremName.startsWith "copyLemma_" = true` and `.moduleName.startsWith "NonShannon.CopyLemma.Generated." = true` on a hand-constructed fixture.
- **Docstring coverage:** `lake lint` catches missing docstrings on any new public declaration. All new top-level definitions get `/-- ... -/` docstrings.
- **Regression guard:** after removing `parameterizedCopyLemma`, the Zhang-Yeung fixture's orbit checks from M1c are not disturbed; the change is confined to `NonShannon/CopyLemma/` and its test mirror.
- **Docs lint:** `make lint` runs markdownlint-cli2 and cspell over the new plan file, the new research note, and the roadmap edit. Any new technical word not already in `cspell-words.txt` is added in the same commit that introduces it.

## Commit strategy

1. `feat(lean): add IsWellFormed predicate and relabel action on CopyParameters`
1. `feat(lean): introduce CopyLemmaStatement record and ofParameters`
1. `feat(lean): remove placeholder parameterizedCopyLemma and prove statement-equivalence bridge`
1. `test(lean): cover well-formedness, relabeling, and statement equivalence`
1. `docs(research): freeze copy-lemma naming and statement-shape conventions`
1. `docs(plans): record 2026-04-23-m2-copy-lemma-statement-layer.md in the roadmap`

Each commit leaves `make check` green. If removing the placeholder breaks a downstream import in commit 3, the removal and the caller updates stay together in one commit rather than splitting across two; no interim state should leave `lake build` red.

## Open questions and risks

- **Faithfulness of `ofParameters`.** The reverse direction of the characterization lemma asks that the statement determines the statement-bearing parameter shape up to relabeling. For the corrected M2 shape this is straightforward: `frozen`, `copyPrototype.copied`, `copyPrototype.conditioning`, and `copyCount` are all directly recoverable from `CopyLemmaStatement`'s fields, even when `copyCount = 0`. If a future milestone makes `ofParameters` more forgetful (for example by deduplicating identical copy blocks and dropping `copyPrototype`), the lemma must either restrict to a smaller parameter quotient or add a roadmap note accepting the weakening. Flagged here so the design choice stays visible in the plan record.
- **Scope-equality threading.** M1b's action requires `relabeling.variableCount = scope`, and M2 threads that proof through `CopyParameters.relabel` and `CopyLemmaStatement.relabel`. A wrong-scope call is a type error, not a silent no-op, but calls at the test boundary must supply the proof term. Tests use `rfl` for concrete `variableCount` literals; no heavier machinery is needed at M2.
- **Interaction with `conditionalIndependence` on `CopyParameters`.** The existing `conditionalIndependence : List ConditionalIndependencePattern` field on `CopyParameters` is user-provided metadata, not part of the statement-bearing structural core. `CopyParameters.relabel` still remaps it elementwise for consistency, but `CopyParameters.statementShape` and `CopyLemmaStatement.ofParameters` intentionally ignore it. This keeps the bridge theorem about the fields the statement actually freezes, while preserving the user annotation channel for future tooling.
- **Frozen semantics of the derived `independence` list.** M2 now freezes the exact derivation rule for `independence`: one pattern `copied ⟂ frozen | conditioning` per copy block, repeated `copyCount` times. That makes the field meaningfully part of the frozen statement shape rather than a placeholder slot. If a later milestone needs a richer or deduplicated list, the change must update `docs/research/copy-lemma-naming.md` and acknowledge the statement-shape break explicitly.
- **Performance at M5 search scale.** At Zhang-Yeung scale (`n = 4`, short subset lists) all M2 operations are microseconds. At M5's `n = 5` bounded search, `IsWellFormed` is called once per candidate and `relabel` is called inside the `|S_n|`-wide orbit loop. Both are `O(k)` per call where `k` is the largest subset's cardinality; no new hot loop is introduced. If M5 profiles show a bottleneck, cache `IsWellFormed` on the record at construction time.
- **Naming conventions versus downstream generators.** M2 freezes naming conventions in a research note but does not mechanically enforce them. If a future generator violates the convention, `lake lint` does not catch it. Possible M6 extension: introduce a `CopyLemmaName.isValid` predicate and a smart constructor for `ParameterizedCopyLemmaTarget` that only accepts conforming strings. Out of scope for M2.
- **Roadmap cross-reference drift.** The roadmap's M2 entry now names this concrete plan file. If the plan is renamed or superseded, the roadmap link and its short summary must be updated in the same change so the Section 6 summary does not drift from the elaboration.

## Why this shape is the right adaptation

The roadmap's M2 entry names four deliverables (typed shape, invariants, bridge lemma, naming document). This plan groups them into three implementation layers:

1. **Data layer:** `CopyLemmaStatement` record plus `CopyBlock`, with the current single-block data frozen explicitly as `copyPrototype` and `copyCount` alongside the future-facing `copies` list. This preserves the current parameterization exactly, including the zero-copy case, while still leaving M5 room to enumerate multi-block families without a schema revision.
1. **Action layer:** `IsWellFormed`, the scoped `relabel` action, and the commuting square between `relabel` and `ofParameters`. Building on M1b's `VariableRelabeling` keeps M1's symmetry vocabulary as the single source of truth for "same up to relabeling" across the project; no parallel action definition is introduced.
1. **Convention layer:** `docs/research/copy-lemma-naming.md`, recording both the naming templates and the frozen statement-shape snapshot, including the derivation rule for `independence`. Locking the conventions in a research note rather than in code lets M3's oracle and M5's search reference them without importing anything new.

Landing all three layers together satisfies the roadmap's "statement shape frozen" gate: the statement record, its action, and its naming conventions all ship at the same checkpoint. A future refactor that revisits any of the three must touch the research note, which is the paper trail the milestone-plan convention expects.

Compared with the alternative of shipping only the typed shape and deferring the characterization lemma to M5, this plan spends M2's checkpoint on exactly the bridge that makes the shape useful. Without the characterization, M5's search would have to invent its own notion of parameter equivalence under relabeling; with it, M5 can cite a theorem.
