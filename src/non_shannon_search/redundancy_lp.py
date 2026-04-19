from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from .schema import CandidateInequality, RedundancyCertificate


class RedundancyBackend(Protocol):
    """Interface for external redundancy-checking backends."""

    def prove_redundant(self, candidate: CandidateInequality) -> RedundancyCertificate:
        """Returns a redundancy certificate for the supplied candidate."""


@dataclass(frozen=True, slots=True)
class NotImplementedBackend:
    """Placeholder backend used until a concrete LP integration lands."""

    name: str = "not-implemented"
    version: str = "0"

    def prove_redundant(self, candidate: CandidateInequality) -> RedundancyCertificate:
        raise NotImplementedError(
            "No redundancy LP backend is configured yet. "
            f"Cannot certify {candidate.id!r} with {self.name} {self.version}."
        )
