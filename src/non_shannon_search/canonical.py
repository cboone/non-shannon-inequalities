# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from __future__ import annotations

from dataclasses import replace
from fractions import Fraction

from .schema import CandidateInequality, Term


def subset_sort_key(subset: tuple[int, ...]) -> tuple[int, tuple[int, ...]]:
    """Orders subsets by size, then lexicographically by their indices."""

    return (len(subset), subset)


def canonicalize_candidate(candidate: CandidateInequality) -> CandidateInequality:
    """Combines duplicate terms, sorts them, and normalizes the overall sign."""

    combined: dict[tuple[int, ...], Fraction] = {}
    for term in candidate.terms:
        combined[term.subset] = combined.get(term.subset, Fraction(0)) + term.coefficient

    terms = [
        Term(subset=subset, coefficient=coefficient)
        for subset, coefficient in sorted(combined.items(), key=lambda item: subset_sort_key(item[0]))
        if coefficient != 0
    ]

    if terms and terms[0].coefficient < 0:
        terms = [Term(subset=term.subset, coefficient=-term.coefficient) for term in terms]

    return replace(candidate, terms=tuple(terms))
