# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from functools import lru_cache
import json
from pathlib import Path
from typing import Any

import jsonschema


REPO_ROOT = Path(__file__).resolve().parents[2]
SCHEMAS_DIR = REPO_ROOT / "schemas"


def parse_rational(value: str) -> Fraction:
    """Parses a schema-level rational string into a `Fraction`."""

    return Fraction(value)


def format_rational(value: Fraction) -> str:
    """Serializes a `Fraction` back to the tracked rational string format."""

    if value.denominator == 1:
        return str(value.numerator)
    return f"{value.numerator}/{value.denominator}"


@lru_cache(maxsize=None)
def load_schema(schema_name: str) -> dict[str, Any]:
    """Loads one tracked JSON schema by filename."""

    return json.loads((SCHEMAS_DIR / schema_name).read_text())


def read_json(path: Path) -> dict[str, Any]:
    """Reads a JSON file into a dictionary."""

    return json.loads(path.read_text())


def validate_candidate_dict(data: dict[str, Any]) -> None:
    """Validates a candidate inequality payload against the tracked schema."""

    jsonschema.validate(data, load_schema("candidate-inequality.schema.json"))


def validate_candidate_path(path: Path) -> None:
    """Validates one candidate inequality JSON file."""

    validate_candidate_dict(read_json(path))


def validate_redundancy_certificate_dict(data: dict[str, Any]) -> None:
    """Validates a redundancy certificate payload against the tracked schema."""

    jsonschema.validate(data, load_schema("redundancy-certificate.schema.json"))


@dataclass(frozen=True, slots=True)
class Provenance:
    """Source metadata attached to tracked fixtures and catalog entries."""

    source: str
    note: str = ""

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Provenance":
        return cls(source=data["source"], note=data.get("note", ""))

    def to_dict(self) -> dict[str, Any]:
        return {"source": self.source, "note": self.note}


@dataclass(frozen=True, slots=True)
class Term:
    """One sparse coefficient in an inequality vector."""

    subset: tuple[int, ...]
    coefficient: Fraction

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Term":
        raw = tuple(int(value) for value in data["subset"])
        subset = tuple(sorted(raw))
        for left, right in zip(subset, subset[1:]):
            if left == right:
                raise ValueError(
                    f"subset contains duplicate index {left}: {list(raw)}"
                )
        return cls(subset=subset, coefficient=parse_rational(data["coefficient"]))

    def to_dict(self) -> dict[str, Any]:
        return {
            "subset": list(self.subset),
            "coefficient": format_rational(self.coefficient),
        }


@dataclass(frozen=True, slots=True)
class CandidateInequality:
    """Python mirror of the tracked candidate inequality schema."""

    id: str
    label: str
    variable_count: int
    basis: str
    terms: tuple[Term, ...]
    provenance: Provenance
    status: str
    copy_parameters_ref: str | None = None
    orbit_id: str | None = None
    symmetry_orbit_size: int | None = None

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "CandidateInequality":
        validate_candidate_dict(data)
        return cls(
            id=data["id"],
            label=data["label"],
            variable_count=int(data["variable_count"]),
            basis=data["basis"],
            terms=tuple(Term.from_dict(term) for term in data["terms"]),
            provenance=Provenance.from_dict(data["provenance"]),
            status=data["status"],
            copy_parameters_ref=data.get("copy_parameters_ref"),
            orbit_id=data.get("orbit_id"),
            symmetry_orbit_size=data.get("symmetry_orbit_size"),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "label": self.label,
            "variable_count": self.variable_count,
            "basis": self.basis,
            "terms": [term.to_dict() for term in self.terms],
            "provenance": self.provenance.to_dict(),
            "copy_parameters_ref": self.copy_parameters_ref,
            "orbit_id": self.orbit_id,
            "symmetry_orbit_size": self.symmetry_orbit_size,
            "status": self.status,
        }


@dataclass(frozen=True, slots=True)
class CombinationSource:
    """One weighted source inequality in a redundancy certificate."""

    id: str
    weight: Fraction

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "CombinationSource":
        return cls(id=data["id"], weight=parse_rational(data["weight"]))

    def to_dict(self) -> dict[str, Any]:
        return {"id": self.id, "weight": format_rational(self.weight)}


@dataclass(frozen=True, slots=True)
class RedundancyCertificate:
    """Python mirror of the tracked redundancy certificate schema."""

    target_id: str
    sources: tuple[CombinationSource, ...]
    backend: str
    backend_version: str
    lean_checkable: bool

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "RedundancyCertificate":
        validate_redundancy_certificate_dict(data)
        return cls(
            target_id=data["target_id"],
            sources=tuple(CombinationSource.from_dict(source) for source in data["sources"]),
            backend=data["backend"],
            backend_version=data["backend_version"],
            lean_checkable=bool(data["lean_checkable"]),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "target_id": self.target_id,
            "sources": [source.to_dict() for source in self.sources],
            "backend": self.backend,
            "backend_version": self.backend_version,
            "lean_checkable": self.lean_checkable,
        }


def load_candidate(path: Path) -> CandidateInequality:
    """Loads and validates one candidate inequality fixture."""

    return CandidateInequality.from_dict(read_json(path))
