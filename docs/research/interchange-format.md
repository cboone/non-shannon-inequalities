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
