# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from __future__ import annotations

from dataclasses import replace
from itertools import permutations

from .schema import CandidateInequality, Term


Permutation = tuple[int, ...]


def perm_from_tuple(n: int, values: tuple[int, ...]) -> Permutation:
    """Validates and returns one scoped permutation of `range(n)`."""

    if len(values) != n:
        raise ValueError(f"expected permutation of length {n}, got {len(values)}")
    if sorted(values) != list(range(n)):
        raise ValueError(f"expected permutation of range({n}), got {values!r}")
    return values


def identity_perm(n: int) -> Permutation:
    """Returns the identity permutation on `range(n)`."""

    if n < 0:
        raise ValueError(f"expected non-negative scope, got {n}")
    return tuple(range(n))


def transposition(n: int, i: int, j: int) -> Permutation:
    """Returns the transposition `(i j)` on `range(n)`, or the identity if either index is out of range."""

    if n < 0:
        raise ValueError(f"expected non-negative scope, got {n}")
    values = list(range(n))
    if 0 <= i < n and 0 <= j < n:
        values[i], values[j] = values[j], values[i]
    return tuple(values)


def iter_symmetric_group(n: int):
    """Yields every element of `S_n` for `0 <= n <= 6`."""

    if n < 0:
        raise ValueError(f"expected non-negative scope, got {n}")
    if n > 6:
        raise ValueError("iter_symmetric_group only supports n <= 6")
    for values in permutations(range(n)):
        yield tuple(values)


def _apply_index(perm: Permutation, index: int) -> int:
    if 0 <= index < len(perm):
        return perm[index]
    return index


def compose_perm(left: Permutation, right: Permutation) -> Permutation:
    """Returns the scoped permutation whose action matches applying `right` then `left`.

    Mirrors the Lean `Mul` instance on `VariableRelabeling`: when the scopes agree, the result at position `i` is `left(right(i))`. When the scopes disagree, the result falls back to `left`. Both inputs are validated as scoped permutations when the scopes agree, so callers see `ValueError` rather than `IndexError` on malformed input.
    """

    if len(left) != len(right):
        return left
    n = len(left)
    left = perm_from_tuple(n, left)
    right = perm_from_tuple(n, right)
    return tuple(left[right[index]] for index in range(n))


def apply_subset(perm: Permutation, subset: tuple[int, ...]) -> tuple[int, ...]:
    """Applies one scoped permutation pointwise and returns the normalized subset."""

    return tuple(sorted({_apply_index(perm, index) for index in subset}))


def apply_term(perm: Permutation, term: Term) -> Term:
    """Applies one scoped permutation to one term."""

    return Term(subset=apply_subset(perm, term.subset), coefficient=term.coefficient)


def apply_candidate(perm: Permutation, candidate: CandidateInequality) -> CandidateInequality:
    """Applies one scoped permutation termwise without canonicalizing the result."""

    perm = perm_from_tuple(candidate.variable_count, perm)

    return replace(
        candidate,
        terms=tuple(apply_term(perm, term) for term in candidate.terms),
    )
