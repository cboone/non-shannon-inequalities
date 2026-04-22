# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from fractions import Fraction
from pathlib import Path

from non_shannon_search.canonical import canonicalize_candidate
import pytest

from non_shannon_search.emit_lean import emit_swap_zero_one_module
from non_shannon_search.schema import load_candidate
from non_shannon_search.symmetry import (
    apply_candidate,
    apply_subset,
    compose_perm,
    identity_perm,
    iter_symmetric_group,
    perm_from_tuple,
    transposition,
)


FIXTURE = Path(__file__).resolve().parents[1] / "data" / "fixtures" / "zhang-yeung.json"
GENERATED_FIXTURE = (
    Path(__file__).resolve().parents[1]
    / "NonShannonTest"
    / "Examples"
    / "ZhangYeungSwapZeroOneFromPython.lean"
)

EXPECTED_SWAP_ZERO_ONE_TERMS: tuple[tuple[tuple[int, ...], Fraction], ...] = (
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


def render_generated_swap_module() -> str:
    return emit_swap_zero_one_module(load_candidate(FIXTURE))


def test_apply_subset_normalizes_and_keeps_out_of_range_indices_fixed() -> None:
    perm = transposition(4, 0, 1)
    assert apply_subset(perm, (2, 0, 2)) == (1, 2)
    assert apply_subset(perm, (5, 0)) == (1, 5)


def test_identity_action_is_noop_after_canonicalization() -> None:
    candidate = load_candidate(FIXTURE)
    assert canonicalize_candidate(apply_candidate(identity_perm(4), candidate)) == canonicalize_candidate(candidate)


def test_action_composition_matches_sequential_application_after_canonicalization() -> None:
    candidate = load_candidate(FIXTURE)
    left = transposition(4, 0, 1)
    right = transposition(4, 1, 2)
    combined = compose_perm(left, right)

    direct = canonicalize_candidate(apply_candidate(combined, candidate))
    sequential = canonicalize_candidate(apply_candidate(left, apply_candidate(right, candidate)))

    assert direct == sequential


def test_permuted_candidate_stays_within_declared_range() -> None:
    candidate = load_candidate(FIXTURE)
    permuted = apply_candidate(transposition(4, 0, 1), candidate)

    assert permuted.variable_count == 4
    assert all(
        0 <= index < permuted.variable_count
        for term in permuted.terms
        for index in term.subset
    )


def test_apply_candidate_rejects_scope_mismatch() -> None:
    candidate = load_candidate(FIXTURE)

    with pytest.raises(ValueError, match="expected permutation of length 4"):
        apply_candidate(identity_perm(5), candidate)


def test_swap_zero_one_matches_expected_canonical_terms() -> None:
    candidate = load_candidate(FIXTURE)
    swapped = canonicalize_candidate(apply_candidate(transposition(4, 0, 1), candidate))

    actual = tuple((term.subset, term.coefficient) for term in swapped.terms)
    assert actual == EXPECTED_SWAP_ZERO_ONE_TERMS


def test_perm_from_tuple_validates_scope() -> None:
    assert perm_from_tuple(3, (2, 0, 1)) == (2, 0, 1)


def test_iter_symmetric_group_yields_all_elements_for_s3() -> None:
    assert len(tuple(iter_symmetric_group(3))) == 6


def test_generated_zhang_yeung_swap_module_matches_python_emitter() -> None:
    assert GENERATED_FIXTURE.read_text() == render_generated_swap_module()
