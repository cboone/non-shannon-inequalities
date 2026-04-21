# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

import json
from fractions import Fraction
from pathlib import Path

from non_shannon_search.canonical import canonicalize_candidate
from non_shannon_search.schema import CandidateInequality, Provenance, Term, load_candidate


FIXTURE = Path(__file__).resolve().parents[1] / "data" / "fixtures" / "zhang-yeung.json"


# Mirrors the term list in `NonShannon/Examples/ZhangYeung.lean`. The Lean-side
# `example` that `canonicalize zhangYeungAveragedScaled.vector = zhangYeungAveragedScaled.vector`
# and this test together form the cross-language parity gate for the M1a canonical form.
EXPECTED_ZHANG_YEUNG_CANONICAL_TERMS: tuple[tuple[tuple[int, ...], Fraction], ...] = (
    ((0,), Fraction(1)),
    ((1,), Fraction(1)),
    ((2,), Fraction(4)),
    ((3,), Fraction(4)),
    ((0, 1), Fraction(2)),
    ((0, 2), Fraction(-4)),
    ((0, 3), Fraction(-4)),
    ((1, 2), Fraction(-4)),
    ((1, 3), Fraction(-4)),
    ((2, 3), Fraction(-6)),
    ((0, 2, 3), Fraction(5)),
    ((1, 2, 3), Fraction(5)),
)


def test_canonicalize_sorts_terms_and_normalizes_sign() -> None:
    candidate = load_candidate(FIXTURE)
    canonical = canonicalize_candidate(candidate)

    assert canonical.terms[0].coefficient > 0
    assert [term.subset for term in canonical.terms] == sorted(
        [term.subset for term in canonical.terms],
        key=lambda subset: (len(subset), subset),
    )


def test_zhang_yeung_fixture_is_canonical() -> None:
    candidate = load_candidate(FIXTURE)
    assert canonicalize_candidate(candidate) == candidate


def test_canonicalize_is_idempotent_on_zhang_yeung() -> None:
    candidate = load_candidate(FIXTURE)
    once = canonicalize_candidate(candidate)
    twice = canonicalize_candidate(once)
    assert once == twice


def test_canonicalize_combines_duplicate_subsets() -> None:
    candidate = CandidateInequality(
        id="synthetic-duplicate",
        label="Synthetic duplicate subset",
        variable_count=4,
        basis="joint_entropy",
        terms=(
            Term(subset=(0, 2), coefficient=Fraction(1)),
            Term(subset=(0, 2), coefficient=Fraction(-1)),
            Term(subset=(1,), coefficient=Fraction(2)),
        ),
        provenance=Provenance(source="synthetic"),
        status="reference",
    )
    canonical = canonicalize_candidate(candidate)

    assert all(term.subset != (0, 2) for term in canonical.terms)
    assert canonical.terms == (Term(subset=(1,), coefficient=Fraction(2)),)


def test_python_canonical_matches_lean_mirror_terms() -> None:
    candidate = load_candidate(FIXTURE)
    canonical = canonicalize_candidate(candidate)
    actual = tuple((term.subset, term.coefficient) for term in canonical.terms)
    assert actual == EXPECTED_ZHANG_YEUNG_CANONICAL_TERMS


def test_canonical_form_survives_json_round_trip() -> None:
    candidate = load_candidate(FIXTURE)
    canonical = canonicalize_candidate(candidate)
    serialized = json.dumps(canonical.to_dict())
    reparsed = CandidateInequality.from_dict(json.loads(serialized))
    assert canonicalize_candidate(reparsed) == canonical
