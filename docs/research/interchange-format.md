# Interchange Format

The bootstrap format is deliberately small.

## Candidate Inequalities

Each candidate inequality records:

- `id`
- `label`
- `variable_count`
- `basis`
- `terms`
- `provenance`
- `status`
- optional `copy_parameters_ref`
- optional `orbit_id`
- optional `symmetry_orbit_size`

The M1c schema revision adds optional `orbit_id` while retaining `symmetry_orbit_size` as separate optional metadata. The two fields do different jobs: `orbit_id` identifies the orbit representative produced by canonicalization, while `symmetry_orbit_size` records an externally supplied orbit cardinality when one is known.

On input, `orbit_id` remains optional so pre-M1c payloads still validate. On output, `CandidateInequality.to_dict()` emits `orbit_id` explicitly and uses `null` when the field is absent, matching the established `copy_parameters_ref` and `symmetry_orbit_size` convention.

Each term is a sparse pair of:

- `subset`: an array of variable indices
- `coefficient`: a rational string such as `-5` or `3/2`

The schema uses rational strings instead of JSON numbers so that exact arithmetic survives round-trips through Python, future solver outputs, and Lean mirrors.

## Redundancy Certificates

Each redundancy certificate records:

- `target_id`
- weighted `sources`
- `backend`
- `backend_version`
- `lean_checkable`

This is enough for the bootstrap phase to make the trust boundary visible even before a concrete LP backend lands.

## Canonicalization Rule

The within-inequality canonicalization pass does three things only:

1. combine duplicate sparse terms,
2. sort subsets by arity and then lexicographically,
3. flip the overall sign so the first nonzero coefficient is nonnegative.

That M1a rule is intentionally modest. It gives a deterministic term list for one fixed labeling, but it does not identify two inequalities that differ only by a permutation of variables.

M1c adds orbit canonicalization on top of that baseline. For a vector with `n = variable_count`, enumerate every permutation in `S_n`, apply it termwise, pass the result through the M1a canonicalizer, and choose the lexicographically least resulting canonical vector. The comparison key is `(length, List ((subset.cardinality, subset.vars), coefficient))`, so shorter canonical term lists come first and ties break termwise by subset order and then rational coefficient.

The pinned `orbit_id` string is the direct serialization of that orbit representative:

- format: `{variableCount};{term};{term};...`
- subset format: `[{i0},{i1},...]`
- coefficient format: `{num}` when the denominator is `1`, otherwise `{num}/{den}`
- empty term list: `{variableCount};`

Example: `4;[0]:1;[1]:1;[2]:4;[3]:4;[0,1]:2;[0,2]:-4;...`

Lean and Python both construct this string directly from the canonical term list. Neither side delegates the coefficient rendering to a generic pretty-printer, so the byte representation is a tracked cross-language contract.

## M1a Canonical Baseline Reset

At milestone M1a closure, the tracked Zhang-Yeung JSON fixture (`data/fixtures/zhang-yeung.json`) and its Lean mirror (`NonShannon/Examples/ZhangYeung.lean`) were re-emitted through the M1a canonicalizer once and are now the canonical baseline for cross-language regression tests. The re-emission flipped the overall sign (the bootstrap fixture led with a negative coefficient on `[0]`) and fixed the term order to `(cardinality, lex)`.

## M1c Migration Note

The public `non-shannon-search canonicalize` CLI now emits M1c-complete payloads. Its `terms` field still reflects the M1a within-inequality canonicalization of the caller's specific labeling, but it now also populates `orbit_id` from the orbit representative. Callers that want the orbit representative's `terms` rather than only its identifier use the Python library's `orbit_canonical(...)` entry point.
