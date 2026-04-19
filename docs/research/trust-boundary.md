<!--
SPDX-FileCopyrightText: 2026 Christopher Boone

SPDX-License-Identifier: CC-BY-4.0
-->

# Trust Boundary

Track A will eventually depend on components with different trust levels.

## Lean Kernel

The Lean kernel is the final trust anchor for theorem statements and any proof objects that land in the repository.

## Tracked Schemas

Tracked JSON schemas are not proofs, but they are part of the reproducibility boundary. They make the shape of imported candidates and certificates explicit and reviewable.

## External Search And LP Backends

Enumeration code, redundancy LPs, and future solver integrations live outside Lean. They are therefore trusted or semi-trusted components until they emit artifacts that Lean can check.

The bootstrap repository makes this visible in two ways:

- the schema records backend metadata,
- redundancy certificates carry a `lean_checkable` flag.

## Immediate Policy

During bootstrap and the first search milestones:

- solver results may be used to rank or filter candidates,
- only small curated fixtures are tracked in git,
- external results should be treated as provisional unless backed by a Lean-checkable artifact or a separately reviewed mathematical argument.
