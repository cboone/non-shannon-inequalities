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
- optional `symmetry_orbit_size`

The current bootstrap schema does not yet carry an `orbit_id`. The planned M1c schema revision adds optional `orbit_id` while retaining `symmetry_orbit_size` as separate optional metadata.

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

The current canonicalization pass does three things only:

1. combine duplicate sparse terms,
2. sort subsets by arity and then lexicographically,
3. flip the overall sign so the first nonzero coefficient is nonnegative.

That rule is intentionally modest. It is enough for fixtures, tests, and later schema consumers, while leaving room for more serious symmetry reduction work in later milestones.

## Pending M1 Notes

- **M1a canonical baseline reset:** the tracked Zhang-Yeung JSON fixture and Lean mirror are bootstrap artifacts today. M1a is expected to re-emit both through the strengthened canonicalizer once, after which they become the canonical baseline for regression tests.
- **M1c orbit metadata:** `orbit_id` is planned as the deterministic canonical serialization of the orbit representative, not as a replacement for `symmetry_orbit_size`. The two fields serve different purposes: identity of the orbit representative versus optional externally computed orbit cardinality.
