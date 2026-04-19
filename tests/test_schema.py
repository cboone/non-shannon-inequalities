# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from fractions import Fraction
from pathlib import Path

import jsonschema
import pytest

from non_shannon_search.schema import (
    RedundancyCertificate,
    Term,
    load_candidate,
    validate_candidate_path,
    validate_redundancy_certificate_dict,
)


REDUNDANCY_CERTIFICATE_FIXTURE = {
    "target_id": "demo-target",
    "sources": [
        {"id": "demo-source-a", "weight": "1/2"},
        {"id": "demo-source-b", "weight": "-3"},
    ],
    "backend": "manual",
    "backend_version": "0.0.0",
    "lean_checkable": True,
}


FIXTURE = Path(__file__).resolve().parents[1] / "data" / "fixtures" / "zhang-yeung.json"


def test_fixture_validates_against_schema() -> None:
    validate_candidate_path(FIXTURE)


def test_fixture_loads_as_reference_candidate() -> None:
    candidate = load_candidate(FIXTURE)

    assert candidate.id == "zhang-yeung-averaged-scaled"
    assert candidate.variable_count == 4
    assert candidate.status == "reference"


def test_term_from_dict_sorts_subset_indices() -> None:
    term = Term.from_dict({"subset": [2, 0, 1], "coefficient": "1"})

    assert term.subset == (0, 1, 2)


def test_term_from_dict_rejects_duplicate_indices() -> None:
    with pytest.raises(ValueError, match="duplicate index"):
        Term.from_dict({"subset": [1, 1], "coefficient": "1"})


def test_redundancy_certificate_fixture_validates_against_schema() -> None:
    validate_redundancy_certificate_dict(REDUNDANCY_CERTIFICATE_FIXTURE)


def test_redundancy_certificate_from_dict_parses_rational_weights() -> None:
    certificate = RedundancyCertificate.from_dict(REDUNDANCY_CERTIFICATE_FIXTURE)

    assert certificate.target_id == "demo-target"
    assert certificate.backend == "manual"
    assert certificate.lean_checkable is True
    assert [source.weight for source in certificate.sources] == [
        Fraction(1, 2),
        Fraction(-3),
    ]


def test_redundancy_certificate_round_trips_through_to_dict() -> None:
    certificate = RedundancyCertificate.from_dict(REDUNDANCY_CERTIFICATE_FIXTURE)

    assert certificate.to_dict() == REDUNDANCY_CERTIFICATE_FIXTURE


def test_redundancy_certificate_rejects_malformed_weight() -> None:
    payload = {
        **REDUNDANCY_CERTIFICATE_FIXTURE,
        "sources": [{"id": "demo-source-a", "weight": "1.5"}],
    }
    with pytest.raises(jsonschema.ValidationError):
        validate_redundancy_certificate_dict(payload)
