# Copy-Lemma Naming

This note records the M2 conventions for generated copy-lemma statement names, generated module names, and the frozen statement-shape snapshot used by downstream milestones.

## Scope

The conventions apply to future generated declarations that target `CopyParameters` values through `CopyLemmaStatement.ofParameters`. Hand-authored examples under `NonShannon.Examples.*` remain separate from generated copy-lemma modules.

M2 records conventions only. It does not enforce them with a smart constructor; `ParameterizedCopyLemmaTarget.theoremName` and `ParameterizedCopyLemmaTarget.moduleName` remain plain `String` fields.

## Theorem Names

Generated theorem names should use this template:

```text
copyLemma_<familyDescriptor>_<orbitDigest>
```

The `familyDescriptor` is a short ASCII tag chosen by the generator. It should be stable for a generator family, for example `zhangYeung` or `dfz31`.

The `orbitDigest` is a short prefix of the parameter set's orbit identifier. The orbit-ID format is the M1c format used for inequality orbits; M2 does not introduce a second digest scheme.

The prefix `copyLemma_` is reserved for generated copy-lemma theorem statements. Do not use it for hand-authored examples or catalog entries that are not generated from `CopyParameters`.

## Module Names

Generated modules should use this template:

```text
NonShannon.CopyLemma.Generated.<family>
```

Use one generated module per generator family. This keeps generated output disjoint from the hand-authored `NonShannon.Examples.*` modules and prevents generator output from colliding with curated fixtures.

The `<family>` segment should match the generator family rather than an individual theorem. Multiple generated theorem declarations may live in the same family module when they share enumeration logic and naming policy.

## Target Metadata

`ParameterizedCopyLemmaTarget` is theorem-generation metadata. Its fields have the following roles:

- `theoremName`: the planned Lean declaration name, expected to follow the `copyLemma_<familyDescriptor>_<orbitDigest>` template.
- `moduleName`: the planned Lean module path, expected to follow the `NonShannon.CopyLemma.Generated.<family>` template.
- `parameters`: the `CopyParameters` payload targeted by the generated theorem.

`CopyLemmaStatement` is the typed statement shape. `ParameterizedCopyLemmaTarget` does not replace it and should not duplicate its fields.

## Frozen Statement Shape

As of M2 closure, the statement shape is:

```lean
structure CopyBlock where
  copied : VariableSubset
  conditioning : VariableSubset

structure CopyLemmaStatement where
  variableCount : Nat
  frozen : VariableSubset
  copyPrototype : CopyBlock
  copyCount : Nat
  independence : List ConditionalIndependencePattern
```

There is no stored `copies` field in M2. Consumers that want a list view use the derived projection:

```lean
def CopyLemmaStatement.copies (statement : CopyLemmaStatement) : List CopyBlock :=
  List.replicate statement.copyCount statement.copyPrototype
```

The `copyPrototype` field deliberately retains the copied and conditioning blocks even when `copyCount = 0`. This keeps the statement-bearing structural data recoverable in the degenerate no-copy case.

## Induced Independence

M2 freezes the derived independence rule for the current single-block parameter shape:

```lean
def CopyLemmaStatement.inducedIndependence (params : CopyParameters) :
    List ConditionalIndependencePattern :=
  List.replicate params.copyCount
    { left := params.copied
      right := params.frozen
      given := params.conditioning }
```

`CopyLemmaStatement.ofParameters` uses this rule exactly. A future milestone that deduplicates, enriches, or changes the independence list must update this note and explicitly acknowledge the statement-shape break in the roadmap.

## Parameter Invariants

M2 splits parameter invariants into two predicates.

- `CopyParameters.IsCanonical` requires the frozen, copied, and conditioning subsets to be in range and normalized.
- `CopyParameters.IsWellFormed` extends `IsCanonical` with pairwise disjointness of the three structural subsets.

The statement-equivalence bridge uses `IsCanonical`, because `CopyLemmaStatement.ofParameters` stores every statement-bearing field directly. `IsWellFormed` remains the stronger predicate for downstream search code that wants disjoint candidate blocks.

## Structural Projection

`CopyParameters.statementShape` keeps only the statement-bearing fields:

- `variableCount`
- `frozen`
- `copied`
- `conditioning`
- `copyCount`

It intentionally forgets `label` and user-provided `conditionalIndependence` metadata. Two parameter values that differ only in those metadata fields may still have the same statement shape.

## Future Changes

Any future refactor that promotes `CopyLemmaStatement.copies` to a stored field, changes the independence derivation rule, or changes which `CopyParameters` fields participate in `statementShape` must update this note in the same change. The roadmap entry for the responsible milestone should name the compatibility break and explain why downstream search or generated theorem output needs it.
