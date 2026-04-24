# 2026-04-23 M2: Parameterized Copy-Lemma Statement Layer

Implementation plan for milestone M2 of the Track A Discovery Roadmap (`docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`, Section 6).

## Context

M0 shipped a placeholder `parameterizedCopyLemma : ParameterizedCopyLemmaShape` defined as `params.copyCount = 0 ∨ 0 < params.copyCount`, which is trivially satisfied on every `CopyParameters` input. The placeholder exists so downstream milestones can import a stable name before the real shape is designed. M1a, M1b, and M1c finished the inequality-side representation layer: canonical form, scoped symmetry action, orbit representative, orbit ID in the schema.

M2 is where the copy-lemma side catches up. It replaces the placeholder with a typed statement shape that downstream search code (M5) can target and that M3's oracle can annotate. It also lands the bridge between M1's symmetry layer and copy-lemma parameters, so two parameter sets that differ only by a scoped relabeling of the underlying variables are recognized as generating the same statement up to relabeling.

The roadmap (Section 6, M2) names four deliverables: the typed shape, additional invariants on `CopyParameters`, the first nontrivial statement-layer lemma, and a naming-convention research note. This plan groups them into three implementation layers (data, action, convention) landed under a single milestone gate.

## Goal

After M2, the following hold:

1. `NonShannon/CopyLemma/Parameterized.lean` exports a typed `CopyLemmaStatement` record (exact field list in the approach below) and a derived `CopyLemmaStatement.copies` view. The placeholder `parameterizedCopyLemma`, `parameterizedCopyLemmaSpec`, and `ParameterizedCopyLemmaShape` are removed. `ParameterizedCopyLemmaTarget` is retained as theorem-generation metadata, and its existing struct-level docstring is expanded to clarify its intended use alongside `CopyLemmaStatement`.
1. `NonShannon/CopyLemma/Parameters.lean` carries two layered predicates on `CopyParameters` (`IsCanonical` for in-range plus normalized; `IsWellFormed` extending `IsCanonical` with the three pairwise-disjointness invariants), a `CopyParameterShape` projection that forgets non-structural metadata, and a scoped `relabel` action backed by the `VariableRelabeling` surface from `NonShannon/Inequality/Symmetry.lean`.
1. `CopyLemmaStatement.ofParameters : CopyParameters → CopyLemmaStatement` is defined in `NonShannon/CopyLemma/Parameterized.lean` as a deterministic projection: it stores `frozen` and the `copyPrototype` block from the parameters and derives `independence` by the M2 rule (see Approach §1). No statement-side well-formedness predicate is introduced at M2; statement-level invariants reduce to the parameter-side `IsCanonical` predicate via the projection.
1. The characterization lemma `CopyParameters.sameStatementShape_iff_ofParameters_sameShape` expresses: for parameters `a`, `b` whose three subsets are each in-range and normalized (the smaller predicate `CopyParameters.IsCanonical`, implied by the full `IsWellFormed`), there is a scoped relabeling witnessing equality between their statement-bearing structural projections (not their `label` or user-provided `conditionalIndependence` metadata) if and only if there is a scoped relabeling witnessing `CopyLemmaStatement.ofParameters b = (CopyLemmaStatement.ofParameters a).relabel r`. Disjointness is not load-bearing for the lemma; it remains on `IsWellFormed` for downstream consumers (M5 search) that want it as a separate invariant.
1. `docs/research/copy-lemma-naming.md` documents the theorem-name and module-name templates for future generated copy-lemma statements, and records the frozen field layout of `CopyLemmaStatement` (including the derived `copies` view), the frozen derivation rule for its `independence` field, and the `IsCanonical` / `IsWellFormed` split, all as of M2 closure.
1. `NonShannonTest/CopyLemma/Parameters.lean` and the new `NonShannonTest/CopyLemma/Parameterized.lean` exercise the public surface from outside `NonShannon`; `lake test` picks them up via `NonShannonTest.lean`.

## Approach

### 1. The `CopyLemmaStatement` record

Two candidate shapes:

1. **Flat record mirroring `CopyParameters`.** Same fields (`variableCount`, `frozen`, `copied`, `conditioning`, `copyCount`) plus a derived `independence : List ConditionalIndependencePattern`. The statement is a view of the parameters; `ofParameters` is the identity extended with the derived field.
1. **Record organized around copy operations.** Fields: `variableCount`, `frozen`, `copyPrototype : CopyBlock`, `copyCount`, `copies : List CopyBlock` (each `CopyBlock` is one copy operation with its `copied` and `conditioning` subsets), `independence : List ConditionalIndependencePattern`. Supports future multi-block copy families without a schema change while preserving the current single-block parameters even when `copyCount = 0`.

**Resolved:** option 2, simplified to drop the redundant `copies` field. The long-run search surface (M5) wants to enumerate copy-lemma families with varying numbers of copy blocks. Baking one copy block per statement into the shape would force a revision the first time a two-block family lands; carrying the prototype block plus the count keeps the single-block data recoverable in the legitimate `copyCount = 0` case without storing a derived list whose internal consistency cannot be enforced at the type level. A future milestone that introduces heterogeneous copy blocks promotes the derived `copies` view to a stored field at the same checkpoint that updates the research note. The result is two new small records:

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
  independence : List ConditionalIndependencePattern
  deriving DecidableEq, Inhabited

/-- Derived view: the prototype block repeated `copyCount` times. Stored implicitly via this projection rather than as a record field, so the M2 statement shape carries no internal redundancy. When a future milestone introduces heterogeneous copy blocks, replace this view with a stored `copies : List CopyBlock` field at the same checkpoint that updates the research note. -/
def CopyLemmaStatement.copies (s : CopyLemmaStatement) : List CopyBlock :=
  List.replicate s.copyCount s.copyPrototype
```

For the current `CopyParameters` shape (single-block copy with `copyCount` repetitions of the same block), `ofParameters` sets `copyPrototype := { copied := params.copied, conditioning := params.conditioning }`, sets `copyCount := params.copyCount`, and lets the derived `copies` view emit `params.copyCount` identical entries on demand. This keeps `CopyLemmaStatement` stable across later parameter-shape refinements that introduce heterogeneous blocks while ensuring the current `copied` and `conditioning` fields remain recoverable even when `copyCount = 0`.

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

Two predicates are introduced. `IsCanonical` carries the six in-range and normalization invariants and is the hypothesis the bridge theorem (§4) actually consumes. `IsWellFormed` adds the three pairwise-disjointness invariants for downstream consumers (M5 search). `IsWellFormed → IsCanonical` is a one-line projection (`structure ... extends ...` gives it for free).

`VariableSubset.Disjoint` is taken from Mathlib's `List.Disjoint` (which already supplies `Decidable List.Disjoint` via `List.decidableBAll` and a small lemma library) by lifting through the underlying `vars` field rather than defining a parallel notion. The local helper is one line:

```lean
def VariableSubset.Disjoint (a b : VariableSubset) : Prop :=
  a.vars.Disjoint b.vars
```

```lean
structure CopyParameters.IsCanonical (params : CopyParameters) : Prop where
  frozenInRange : params.frozen.IsInRange params.variableCount
  copiedInRange : params.copied.IsInRange params.variableCount
  conditioningInRange : params.conditioning.IsInRange params.variableCount
  frozenNormalized : params.frozen.isNormalized
  copiedNormalized : params.copied.isNormalized
  conditioningNormalized : params.conditioning.isNormalized

structure CopyParameters.IsWellFormed (params : CopyParameters) : Prop extends
    CopyParameters.IsCanonical params where
  frozenCopiedDisjoint : VariableSubset.Disjoint params.frozen params.copied
  frozenConditioningDisjoint : VariableSubset.Disjoint params.frozen params.conditioning
  copiedConditioningDisjoint : VariableSubset.Disjoint params.copied params.conditioning
```

All nine components are `Decidable` (either via M1a/M1b or via the `Decidable List.Disjoint` instance), so both predicates are checkable by `decide` on Zhang-Yeung-scale fixtures. `copyCount` intentionally has no lower-bound constraint: `copyCount = 0` is the degenerate no-copy case and is legitimate at this layer, to match how M3's future oracle may treat "no copies required" as a sentinel. The simplified statement shape above keeps the underlying `copied` and `conditioning` data in `copyPrototype`, so the bridge theorem does not need to exclude the zero-copy case.

Why the bridge theorem has an unconditional core. The reverse direction reads back `frozen`, `copyPrototype.copied`, `copyPrototype.conditioning`, and `copyCount` directly from `CopyLemmaStatement`'s separately stored fields. Since `CopyLemmaStatement.ofParameters` stores every statement-bearing field, the projection is structurally injective on `CopyParameters.statementShape`; the proof does not need normalized-uniqueness or any `IsCanonical` hypothesis. M2 therefore exposes `CopyParameters.sameStatementShape_iff_ofParameters_sameShape_core` at this true strength and keeps `CopyParameters.sameStatementShape_iff_ofParameters_sameShape` as the planned canonical-hypothesis wrapper for downstream M5 callers that already carry the invariant. `IsWellFormed` remains the stronger predicate downstream search code will check on candidate parameter sets.

Naming note: both predicates use the `IsX` capitalization convention (matching the existing `VariableSubset.IsInRange` in `NonShannon/Inequality/Subsets.lean`). `VariableSubset.Disjoint` follows the same convention.

### 3. Relabeling action on `CopyParameters` and `CopyLemmaStatement`

```lean
def ConditionalIndependencePattern.relabel
    (pattern : ConditionalIndependencePattern) (r : VariableRelabeling) :
    ConditionalIndependencePattern :=
  { left := actOnSubset r pattern.left
    right := actOnSubset r pattern.right
    given := actOnSubset r pattern.given }

def CopyParameters.relabel
    (params : CopyParameters) (r : VariableRelabeling)
    (_h : r.variableCount = params.variableCount) : CopyParameters :=
  { params with
    frozen := actOnSubset r params.frozen
    copied := actOnSubset r params.copied
    conditioning := actOnSubset r params.conditioning
    conditionalIndependence :=
      params.conditionalIndependence.map (·.relabel r) }

def CopyLemmaStatement.relabel
    (s : CopyLemmaStatement) (r : VariableRelabeling)
    (_h : r.variableCount = s.variableCount) : CopyLemmaStatement :=
  { s with
    frozen := actOnSubset r s.frozen
    copyPrototype :=
      { copied := actOnSubset r s.copyPrototype.copied
        conditioning := actOnSubset r s.copyPrototype.conditioning }
    independence := s.independence.map (·.relabel r) }
```

The scope-equality hypothesis is a type-level constraint on callers, matching how `actOnVector` threads it in `NonShannon/Inequality/Symmetry.lean`; the bodies are independent of the proof term. `ConditionalIndependencePattern.relabel` is shared between the parameter-side and statement-side actions so the induced-independence derivation commutes with relabeling on both sides simultaneously (see `inducedIndependence_relabel` below). The statement-shape bridge in §4 does not quotient by `label` or user-provided `conditionalIndependence`; it quotients by the smaller `CopyParameterShape` projection introduced in this milestone.

Key lemmas landed in M2:

- `actOnSubset_Disjoint`: if two subsets are disjoint and both in-range for the relabeling's scope, their images under `actOnSubset` are disjoint. Follows from the fact that `actOnSubset` factors through the permutation and normalization, and permutations restricted to a shared scope are bijective on images.
- `CopyParameters.relabel_IsCanonical` and `CopyParameters.relabel_IsWellFormed`: `relabel` preserves `IsCanonical` (from M1b's range-preservation and normalization-preservation results) and `IsWellFormed` (composing the canonical case with `actOnSubset_Disjoint`).
- `CopyParameters.statementShape_relabel`: the structural projection commutes with `relabel`, so statement-shape equivalence is explicitly about the statement-bearing fields and not about debug or annotation metadata.
- `inducedIndependence_relabel`: `inducedIndependence (params.relabel r h) = (inducedIndependence params).map (·.relabel r)`. A small `simp` lemma; required so `ofParameters_relabel` can discharge the `independence` field uniformly with `frozen` and `copyPrototype`. Proof is one `unfold` plus `List.map_replicate`.
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

The unconditional characterization core, which is M2's first nontrivial statement-layer result:

```lean
theorem CopyParameters.sameStatementShape_iff_ofParameters_sameShape_core
    {a b : CopyParameters} :
    a.SameStatementShape b ↔
      (CopyLemmaStatement.ofParameters a).SameShape (CopyLemmaStatement.ofParameters b)
```

The canonical-hypothesis wrapper preserves the roadmap-facing invariant boundary for downstream consumers:

```lean
theorem CopyParameters.sameStatementShape_iff_ofParameters_sameShape
    {a b : CopyParameters}
    (ha : a.IsCanonical) (hb : b.IsCanonical) :
    a.SameStatementShape b ↔
      (CopyLemmaStatement.ofParameters a).SameShape (CopyLemmaStatement.ofParameters b)
```

The forward direction follows from `ofParameters_relabel` (the commuting square). The reverse direction extracts the witness relabeling from the statement-level equivalence and reconstructs parameter-level structural equivalence by reading back the relabeled `frozen`, `copyPrototype.copied`, `copyPrototype.conditioning`, and `copyCount` from the statement's fields. Because these fields are stored directly, the core proof is unconditional. The simplified `copyPrototype` field is what makes the reverse direction remain true in the legitimate `copyCount = 0` case, and the structural projection is what prevents `label` or user-supplied `conditionalIndependence` metadata from falsifying the parameter-side equivalence. Downstream M5 callers that hold the stronger `IsWellFormed` invariant pass through the `IsWellFormed.toIsCanonical` projection and cite the wrapped theorem.

### 5. Removed: placeholder `parameterizedCopyLemma` surface

The current `parameterizedCopyLemmaSpec`, its `ParameterizedCopyLemmaShape` alias, and the `parameterizedCopyLemma` value are deleted in their entirety. The only caller is `NonShannonTest/CopyLemma/Parameters.lean`, which has a single `example` exercising the trivially-true spec. That `example` is replaced with `IsWellFormed`, `IsCanonical`, and relabel-of-`IsWellFormed` checks in the same change (see Execution step 8).

Rationale: keeping trivially-true placeholder aliases past M2 creates a maintenance tax (every future extension must decide whether to update the placeholder or ignore it) with no payoff. The M0 bootstrap promise was "a stable type name for downstream imports to land against"; after M2 the stable name is `CopyLemmaStatement`, which supersedes the placeholder.

`ParameterizedCopyLemmaTarget` (the theorem-generation metadata record) is **retained** per the roadmap. Its existing docstring (currently `"Metadata naming the future theorem and module associated to a parameter set."`) is expanded to clarify the split between the statement record (`CopyLemmaStatement`) and the generation metadata (`ParameterizedCopyLemmaTarget`); the per-field docstrings on `theoremName`, `moduleName`, and `parameters` are kept and cross-referenced to the new naming research note.

### 6. Naming document

`docs/research/copy-lemma-naming.md` is new and covers:

- **Theorem-name template** for future-generated copy-lemma statements: `copyLemma_<familyDescriptor>_<orbitDigest>`, where `<familyDescriptor>` is a short ASCII tag chosen by the generator (for example, `zhangYeung`, `dfz31`) and `<orbitDigest>` is a short prefix of the parameter set's orbit ID. The orbit-ID format is already frozen by M1c.
- **Module-name template**: `NonShannon.CopyLemma.Generated.<family>`, with one module per generator family. Deliberately disjoint from the hand-authored `NonShannon.Examples.*` modules so generator output cannot collide with curated fixtures.
- **Interaction with `ParameterizedCopyLemmaTarget`**: the `theoremName` and `moduleName` fields are expected to follow the templates above going forward. M2 does not mechanically enforce this (the fields remain `String`); enforcement is a candidate for a later milestone if drift is observed.
- **Frozen statement-shape snapshot**: the exact field layout of `CopyLemmaStatement` (with `copyPrototype` plus `copyCount` and a derived `copies` view, no stored `copies` field) and `CopyBlock` as of M2 closure, together with the frozen derivation rule for `independence`, the unconditional bridge core, and the canonical-wrapper boundary used by downstream consumers. Any future refactor of the shape must be accompanied by an explicit roadmap note acknowledging the break. Matches the "statement shape frozen" gate in the roadmap's M2 checkpoint.

The document is short (roughly 80 to 120 lines) and stabilizes conventions rather than introducing new machinery.

## Execution order

1. **Extend `NonShannon/CopyLemma/Parameters.lean`** with `VariableSubset.Disjoint` (a one-line lift of Mathlib's `List.Disjoint` through the underlying `vars` field), `ConditionalIndependencePattern.relabel`, `CopyParameterShape`, `CopyParameters.statementShape`, `CopyParameters.IsCanonical` (six in-range and normalization fields), `CopyParameters.IsWellFormed` (extends `IsCanonical` with the three pairwise-disjointness fields), and `CopyParameters.relabel`. Add preservation lemmas (`actOnSubset_Disjoint`, `CopyParameters.relabel_IsCanonical`, `CopyParameters.relabel_IsWellFormed`, `CopyParameters.relabel_variableCount`, `CopyParameters.statementShape_relabel`) here.
1. **Add `CopyBlock` and `CopyLemmaStatement`** records to `NonShannon/CopyLemma/Parameterized.lean`, with `copyPrototype`, `copyCount`, and `independence` as the only block-bearing fields on `CopyLemmaStatement` (no stored `copies` field at M2). Provide the list-of-blocks form as a derived `def CopyLemmaStatement.copies (s) : List CopyBlock := List.replicate s.copyCount s.copyPrototype`, so consumers that want the list shape can call it without the type-level invariant gap a stored field would create. Derive `DecidableEq` and `Inhabited`.
1. **Define `CopyLemmaStatement.relabel`** through `actOnSubset`, reusing `ConditionalIndependencePattern.relabel`. Prove `inducedIndependence_relabel` here so step 6's `ofParameters_relabel` can chain through it uniformly across `frozen`, `copyPrototype`, and `independence`.
1. **Define `CopyLemmaStatement.inducedIndependence` and `CopyLemmaStatement.ofParameters`** so `ofParameters` stores the prototype block explicitly, sets `copyCount := params.copyCount`, and derives `independence` by the fixed M2 rule `copied ⟂ frozen | conditioning`, repeated `copyCount` times. The list-of-copies view is recovered on demand via the derived `CopyLemmaStatement.copies` projection.
1. **Remove `parameterizedCopyLemmaSpec`, `ParameterizedCopyLemmaShape`, and `parameterizedCopyLemma`** from `NonShannon/CopyLemma/Parameterized.lean`. Expand the existing docstring on `ParameterizedCopyLemmaTarget` to clarify its role alongside `CopyLemmaStatement`; keep the per-field docstrings on `theoremName`, `moduleName`, and `parameters`.
1. **Prove `ofParameters_relabel`**: the commuting square between `ofParameters` and `relabel` on both sides. Discharges the `frozen` and `copyPrototype` fields directly via `actOnSubset` and the `independence` field via `inducedIndependence_relabel`. This is the engine of the characterization lemma.
1. **State and prove `CopyParameters.sameStatementShape_iff_ofParameters_sameShape`** in `NonShannon/CopyLemma/Parameterized.lean` with `IsCanonical` hypotheses on both sides. The forward direction is one `rw` with `ofParameters_relabel`. The reverse direction unfolds the statement-level existential, extracts the witness relabeling, and rebuilds equality of the structural projection `statementShape` by reading back each component from the corresponding `CopyLemmaStatement` field, with normalized-uniqueness via `VariableSubset.eq_of_isNormalized_of_mem_iff`.
1. **Update `NonShannonTest/CopyLemma/Parameters.lean`**: keep the existing bootstrap fixture, but replace the `parameterizedCopyLemma` `example` with (a) `example : bootstrapParams.IsWellFormed := by decide`, (b) an `example` recovering `bootstrapParams.IsCanonical` from the `IsWellFormed` witness via `IsWellFormed.toIsCanonical`, and (c) an `example` applying `VariableRelabeling.id 4` via `CopyParameters.relabel` and asserting the result still satisfies `IsWellFormed`.
1. **Add `NonShannonTest/CopyLemma/Parameterized.lean`** with:
   - An `example` constructing `CopyLemmaStatement.ofParameters bootstrapParams` and asserting its `variableCount = 4`.
   - An `example` asserting `CopyLemmaStatement.ofParameters bootstrapParams` preserves the prototype block explicitly and derives the expected `independence` list.
   - An `example` exercising the derived view: `(CopyLemmaStatement.ofParameters bootstrapParams).copies = List.replicate bootstrapParams.copyCount { copied := bootstrapParams.copied, conditioning := bootstrapParams.conditioning }`.
   - An `example` applying `VariableRelabeling.swap 4 0 1` and checking the commuting square.
   - An `example` invoking `sameStatementShape_iff_ofParameters_sameShape` on a concrete `IsCanonical` pair, including a `copyCount = 0` fixture.
   - A negative `example` exhibiting two `IsCanonical` parameter sets whose statement shapes are NOT related by any `VariableRelabeling` (for instance, mismatched `frozen` cardinalities), and asserting `¬ a.SameStatementShape b`. Without this case a degenerate `SameStatementShape` that always returned `True` would pass the rest of the suite.
   - An `example` showing two fixtures that differ only in `label` or user-provided `conditionalIndependence` still satisfy `SameStatementShape`.
   - An `example` constructing a `ParameterizedCopyLemmaTarget` whose `theoremName` begins with `"copyLemma_"` and whose `moduleName` begins with `"NonShannon.CopyLemma.Generated."`, proved by `decide` on `String.startsWith`.
1. **Wire the new test module into `NonShannonTest.lean`** by adding `import NonShannonTest.CopyLemma.Parameterized` next to the existing test imports.
1. **Write `docs/research/copy-lemma-naming.md`** per the structure in Approach section 6.
1. **Tighten the roadmap's M2 entry** in `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md` so its deliverable bullets match this plan's specific decisions (the simplified `copyPrototype`-only statement shape with derived `copies`; the `IsCanonical` / `IsWellFormed` split; the structural projection that forgets `label` and `conditionalIndependence`). The plan-file pointer at the bottom of the M2 entry already names this file; no new link is added.
1. **Run `make check`.** Everything should be green; if a fixture or test breaks, the M2 pipeline has a bug.

## Files touched

- Modified: `NonShannon/CopyLemma/Parameters.lean`, `NonShannon/CopyLemma/Parameterized.lean`, `NonShannonTest/CopyLemma/Parameters.lean`, `NonShannonTest.lean`, `docs/plans/todo/2026-04-18-track-a-discovery-roadmap.md`.
- New: `NonShannonTest/CopyLemma/Parameterized.lean`, `docs/research/copy-lemma-naming.md`.

No schema revisions, no fixture regenerations, no Python changes. M2 stays entirely inside the Lean statement layer plus one research note.

## Testing and verification

Milestone gate: `lake build NonShannon`, `lake lint`, `lake test`, `make lint`, `make py-test` all green. `make lint` covers the roadmap and research-note edits that freeze the statement shape, while `make py-test` is retained for parity with the M1c gate even though M2 makes no Python changes.

Concrete sanity checks:

- `NonShannonTest/CopyLemma/Parameters.lean` proves `(bootstrapParams).IsWellFormed` by `decide`, derives `bootstrapParams.IsCanonical` from it via `IsWellFormed.toIsCanonical`, and proves `((bootstrapParams).relabel (VariableRelabeling.id 4) rfl).IsWellFormed` similarly.
- `NonShannonTest/CopyLemma/Parameterized.lean` proves:
  1. `(CopyLemmaStatement.ofParameters bootstrapParams).variableCount = 4`.
  1. `(CopyLemmaStatement.ofParameters bootstrapParams).copyPrototype = { copied := bootstrapParams.copied, conditioning := bootstrapParams.conditioning }` and its `independence` field is exactly `List.replicate bootstrapParams.copyCount { left := bootstrapParams.copied, right := bootstrapParams.frozen, given := bootstrapParams.conditioning }`.
  1. The derived view satisfies `(CopyLemmaStatement.ofParameters bootstrapParams).copies = List.replicate bootstrapParams.copyCount { copied := bootstrapParams.copied, conditioning := bootstrapParams.conditioning }`.
  1. For `r := VariableRelabeling.swap 4 0 1`, `CopyLemmaStatement.ofParameters (bootstrapParams.relabel r hScope) = (CopyLemmaStatement.ofParameters bootstrapParams).relabel r hScope` (the commuting square at one named transposition).
  1. `bootstrapParams.SameStatementShape (bootstrapParams.relabel r hScope)` is derivable directly from the definition, and the theorem still closes on a zero-copy fixture because `copyPrototype` retains the structural block when `copyCount = 0`.
  1. Two fixtures with mismatched `frozen` cardinalities (or any other structural difference no relabeling can repair) satisfy `¬ a.SameStatementShape b`, guarding against a degenerate `SameStatementShape` that always returns `True`.
  1. Two fixtures that differ only in `label` or `conditionalIndependence` still satisfy `SameStatementShape`, confirming that the relation quotients away non-structural metadata exactly as intended.
  1. `(target : ParameterizedCopyLemmaTarget).theoremName.startsWith "copyLemma_" = true` and `.moduleName.startsWith "NonShannon.CopyLemma.Generated." = true` on a hand-constructed fixture.
- **Docstring coverage:** `lake lint` catches missing docstrings on any new public declaration. All new top-level definitions get `/-- ... -/` docstrings.
- **Regression guard:** after removing `parameterizedCopyLemma`, the Zhang-Yeung fixture's orbit checks from M1c are not disturbed; the change is confined to `NonShannon/CopyLemma/` and its test mirror.
- **Docs lint:** `make lint` runs markdownlint-cli2 and cspell over the new plan file, the new research note, and the roadmap edit. Any new technical word not already in `cspell-words.txt` is added in the same commit that introduces it.

## Commit strategy

1. `feat(lean): add IsCanonical and IsWellFormed predicates and relabel action on CopyParameters`
1. `feat(lean): introduce CopyLemmaStatement record and ofParameters`
1. `feat(lean): remove placeholder parameterizedCopyLemma and prove statement-equivalence bridge`
1. `test(lean): cover well-formedness, relabeling, and statement equivalence`
1. `docs(research): freeze copy-lemma naming and statement-shape conventions`
1. `docs(plans): tighten the roadmap M2 entry to match the M2 plan's specific decisions`

Each commit leaves `make check` green. If removing the placeholder breaks a downstream import in commit 3, the removal and the caller updates stay together in one commit rather than splitting across two; no interim state should leave `lake build` red.

## Open questions and risks

- **Faithfulness of `ofParameters`.** The reverse direction of the characterization lemma asks that the statement determines the statement-bearing parameter shape up to relabeling. For the simplified M2 shape this is straightforward: `frozen`, `copyPrototype.copied`, `copyPrototype.conditioning`, and `copyCount` are all directly recoverable from `CopyLemmaStatement`'s fields, even when `copyCount = 0` (the case where the derived `copies` view is empty). If a future milestone makes `ofParameters` more forgetful (for example by deduplicating identical copy blocks and dropping `copyPrototype`, or by promoting `copies` to a stored field whose internal consistency with `copyPrototype` and `copyCount` is no longer enforced), the lemma must either restrict to a smaller parameter quotient or add a roadmap note accepting the weakening. Flagged here so the design choice stays visible in the plan record.
- **Scope-equality threading.** M1b's action requires `relabeling.variableCount = scope`, and M2 threads that proof through `CopyParameters.relabel` and `CopyLemmaStatement.relabel`. A wrong-scope call is a type error, not a silent no-op, but calls at the test boundary must supply the proof term. Tests use `rfl` for concrete `variableCount` literals; no heavier machinery is needed at M2.
- **Interaction with `conditionalIndependence` on `CopyParameters`.** The existing `conditionalIndependence : List ConditionalIndependencePattern` field on `CopyParameters` is user-provided metadata, not part of the statement-bearing structural core. `CopyParameters.relabel` still remaps it elementwise for consistency, but `CopyParameters.statementShape` and `CopyLemmaStatement.ofParameters` intentionally ignore it. This keeps the bridge theorem about the fields the statement actually freezes, while preserving the user annotation channel for future tooling.
- **Frozen semantics of the derived `independence` list.** M2 now freezes the exact derivation rule for `independence`: one pattern `copied ⟂ frozen | conditioning` per copy block, repeated `copyCount` times. That makes the field meaningfully part of the frozen statement shape rather than a placeholder slot. If a later milestone needs a richer or deduplicated list, the change must update `docs/research/copy-lemma-naming.md` and acknowledge the statement-shape break explicitly.
- **Performance at M5 search scale.** At Zhang-Yeung scale (`n = 4`, short subset lists) all M2 operations are microseconds. At M5's `n = 5` bounded search, `IsWellFormed` is called once per candidate and `relabel` is called inside the `|S_n|`-wide orbit loop. Both are `O(k)` per call where `k` is the largest subset's cardinality; no new hot loop is introduced. If M5 profiles show a bottleneck, cache `IsWellFormed` on the record at construction time.
- **Naming conventions versus downstream generators.** M2 freezes naming conventions in a research note but does not mechanically enforce them. If a future generator violates the convention, `lake lint` does not catch it. Possible M6 extension: introduce a `CopyLemmaName.isValid` predicate and a smart constructor for `ParameterizedCopyLemmaTarget` that only accepts conforming strings. Out of scope for M2.
- **Roadmap cross-reference drift.** The roadmap's M2 entry now names this concrete plan file. If the plan is renamed or superseded, the roadmap link and its short summary must be updated in the same change so the Section 6 summary does not drift from the elaboration.

## Why this shape is the right adaptation

The roadmap's M2 entry names four deliverables (typed shape, invariants, bridge lemma, naming document). This plan groups them into three implementation layers:

1. **Data layer:** `CopyLemmaStatement` record plus `CopyBlock`, with the current single-block data carried explicitly as `copyPrototype` and `copyCount`; the list-of-blocks view is recovered on demand via the derived `CopyLemmaStatement.copies` projection rather than as a stored field. This preserves the current parameterization exactly, including the zero-copy case, and leaves M5 room to enumerate multi-block families by promoting the projection to a stored field at that milestone.
1. **Action layer:** the layered `IsCanonical` / `IsWellFormed` predicates, the scoped `relabel` action, and the commuting square between `relabel` and `ofParameters`. Building on M1b's `VariableRelabeling` keeps M1's symmetry vocabulary as the single source of truth for "same up to relabeling" across the project; no parallel action definition is introduced. Splitting `IsWellFormed` into its load-bearing canonical core and the orthogonal disjointness invariants lets the bridge theorem be stated at its true strength while still giving M5 search the stronger predicate when it wants it.
1. **Convention layer:** `docs/research/copy-lemma-naming.md`, recording both the naming templates and the frozen statement-shape snapshot, including the derivation rule for `independence`. Locking the conventions in a research note rather than in code lets M3's oracle and M5's search reference them without importing anything new.

Landing all three layers together satisfies the roadmap's "statement shape frozen" gate: the statement record, its action, and its naming conventions all ship at the same checkpoint. A future refactor that revisits any of the three must touch the research note, which is the paper trail the milestone-plan convention expects.

Compared with the alternative of shipping only the typed shape and deferring the characterization lemma to M5, this plan spends M2's checkpoint on exactly the bridge that makes the shape useful. Without the characterization, M5's search would have to invent its own notion of parameter equivalence under relabeling; with it, M5 can cite a theorem.
