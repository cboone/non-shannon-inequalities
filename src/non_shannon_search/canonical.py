# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from __future__ import annotations

from dataclasses import replace
from fractions import Fraction

from .schema import CandidateInequality, Term
from .symmetry import apply_candidate, iter_symmetric_group


def normalize_subset(subset: tuple[int, ...]) -> tuple[int, ...]:
    """Returns one subset in sorted duplicate-free order."""

    return tuple(sorted(set(subset)))


def subset_sort_key(subset: tuple[int, ...]) -> tuple[int, tuple[int, ...]]:
    """Orders subsets by size, then lexicographically by their indices."""

    return (len(subset), subset)


def canonicalize_candidate(candidate: CandidateInequality) -> CandidateInequality:
    """Applies the M1a within-inequality canonicalization pass only."""

    combined: dict[tuple[int, ...], Fraction] = {}
    for term in candidate.terms:
        subset = normalize_subset(term.subset)
        combined[subset] = combined.get(subset, Fraction(0)) + term.coefficient

    terms = [
        Term(subset=subset, coefficient=coefficient)
        for subset, coefficient in sorted(combined.items(), key=lambda item: subset_sort_key(item[0]))
        if coefficient != 0
    ]

    if terms and terms[0].coefficient < 0:
        terms = [Term(subset=term.subset, coefficient=-term.coefficient) for term in terms]

    return replace(candidate, terms=tuple(terms))


def _term_orbit_key(term: Term) -> tuple[tuple[int, tuple[int, ...]], Fraction]:
    return (subset_sort_key(term.subset), term.coefficient)


def _candidate_orbit_key(
    candidate: CandidateInequality,
) -> tuple[int, tuple[tuple[tuple[int, tuple[int, ...]], Fraction], ...]]:
    return (len(candidate.terms), tuple(_term_orbit_key(term) for term in candidate.terms))


def _serialize_subset(subset: tuple[int, ...]) -> str:
    return "[" + ",".join(str(index) for index in subset) + "]"


def _serialize_coefficient(value: Fraction) -> str:
    numerator = str(value.numerator)
    if value.denominator == 1:
        return numerator
    return f"{numerator}/{value.denominator}"


def _serialize_term(term: Term) -> str:
    return f"{_serialize_subset(term.subset)}:{_serialize_coefficient(term.coefficient)}"


def _orbit_id_from_representative(candidate: CandidateInequality) -> str:
    serialized_terms = ";".join(_serialize_term(term) for term in candidate.terms)
    if serialized_terms:
        return f"{candidate.variable_count};{serialized_terms}"
    return f"{candidate.variable_count};"


def _orbit_representative(candidate: CandidateInequality) -> CandidateInequality:
    canonical_orbit = (
        canonicalize_candidate(apply_candidate(perm, candidate))
        for perm in iter_symmetric_group(candidate.variable_count)
    )
    return min(canonical_orbit, key=_candidate_orbit_key)


def orbit_canonical(candidate: CandidateInequality) -> CandidateInequality:
    """Returns the lex-minimum M1a-canonical representative in the scoped symmetry orbit.

    The returned candidate keeps the caller's non-vector metadata (`id`, `label`,
    provenance, status, and other optional fields) and only rewrites the term list
    plus `orbit_id`. Use `orbit_id` to compare or deduplicate orbit-equivalent
    candidates rather than whole-object equality.
    """

    representative = _orbit_representative(candidate)
    return replace(representative, orbit_id=_orbit_id_from_representative(representative))


def orbit_id_of(candidate: CandidateInequality) -> str:
    """Serializes the orbit representative into the pinned M1c orbit-ID format."""

    representative = _orbit_representative(candidate)
    return _orbit_id_from_representative(representative)
