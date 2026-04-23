# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

import re
from fractions import Fraction
from pathlib import Path

from non_shannon_search.canonical import canonicalize_candidate, orbit_canonical, orbit_id_of
import pytest

from non_shannon_search.emit_lean import emit_swap_zero_one_module
from non_shannon_search.schema import CandidateInequality, Provenance, Term, load_candidate
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
GENERATED_ORBIT_FIXTURE = (
    Path(__file__).resolve().parents[1]
    / "NonShannonTest"
    / "Examples"
    / "ZhangYeungFromPython.lean"
)
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

NONCANONICAL_CANDIDATE = CandidateInequality(
    id="synthetic-noncanonical",
    label="Synthetic noncanonical candidate",
    variable_count=4,
    basis="joint_entropy",
    terms=(
        Term(subset=(2, 0), coefficient=Fraction(3)),
        Term(subset=(3, 1), coefficient=Fraction(4)),
        Term(subset=(0,), coefficient=Fraction(1)),
    ),
    provenance=Provenance(source="unit test", note=""),
    status="reference",
)


def render_generated_swap_module() -> str:
    return emit_swap_zero_one_module(load_candidate(FIXTURE))


def extract_orbit_id_literal(source: str) -> str:
    match = re.search(r'orbitId := some "([^"]+)"', source)
    if match is None:
        raise AssertionError("expected an orbitId literal in generated Lean source")
    return match.group(1)


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


def test_compose_perm_falls_back_to_left_on_scope_mismatch() -> None:
    assert compose_perm((1, 0), (0, 1, 2)) == (1, 0)


def test_compose_perm_rejects_non_permutation_on_matching_scope() -> None:
    with pytest.raises(ValueError, match=r"expected permutation of range\(3\)"):
        compose_perm((0, 1, 2), (0, 1, 3))

    with pytest.raises(ValueError, match=r"expected permutation of range\(3\)"):
        compose_perm((0, 0, 2), (0, 1, 2))


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


def test_apply_candidate_rejects_non_bijective_tuple() -> None:
    candidate = load_candidate(FIXTURE)

    with pytest.raises(ValueError, match=r"expected permutation of range\(4\)"):
        apply_candidate((0, 0, 0, 0), candidate)


def test_action_commutes_with_precanonicalization_on_noncanonical_candidate() -> None:
    perm = transposition(4, 0, 1)

    assert NONCANONICAL_CANDIDATE != canonicalize_candidate(NONCANONICAL_CANDIDATE)

    direct = canonicalize_candidate(apply_candidate(perm, NONCANONICAL_CANDIDATE))
    after_precanonicalize = canonicalize_candidate(
        apply_candidate(perm, canonicalize_candidate(NONCANONICAL_CANDIDATE))
    )

    assert direct == after_precanonicalize


def test_swap_zero_one_matches_expected_canonical_terms() -> None:
    candidate = load_candidate(FIXTURE)
    swapped = canonicalize_candidate(apply_candidate(transposition(4, 0, 1), candidate))

    actual = tuple((term.subset, term.coefficient) for term in swapped.terms)
    assert actual == EXPECTED_SWAP_ZERO_ONE_TERMS


def test_perm_from_tuple_validates_scope() -> None:
    assert perm_from_tuple(3, (2, 0, 1)) == (2, 0, 1)


def test_iter_symmetric_group_yields_all_elements_for_s3() -> None:
    assert len(tuple(iter_symmetric_group(3))) == 6


def test_perm_from_tuple_rejects_negative_scope() -> None:
    with pytest.raises(ValueError, match="expected non-negative scope"):
        perm_from_tuple(-1, ())


def test_identity_perm_rejects_negative_scope() -> None:
    with pytest.raises(ValueError, match="expected non-negative scope"):
        identity_perm(-1)


def test_transposition_rejects_negative_scope() -> None:
    with pytest.raises(ValueError, match="expected non-negative scope"):
        transposition(-1, 0, 0)


def test_iter_symmetric_group_rejects_negative_scope() -> None:
    with pytest.raises(ValueError, match="expected non-negative scope"):
        next(iter_symmetric_group(-1))


def test_orbit_representation_is_invariant_across_all_of_s4() -> None:
    candidate = load_candidate(FIXTURE)
    expected_canonical = orbit_canonical(candidate)
    expected_orbit_id = orbit_id_of(candidate)

    for perm in iter_symmetric_group(4):
        permuted = apply_candidate(perm, candidate)
        assert orbit_canonical(permuted) == expected_canonical
        assert orbit_id_of(permuted) == expected_orbit_id


def test_cross_language_orbit_id_parity_matches_generated_lean_fixture() -> None:
    candidate = load_candidate(FIXTURE)

    assert extract_orbit_id_literal(GENERATED_ORBIT_FIXTURE.read_text()) == orbit_id_of(candidate)


def test_generated_zhang_yeung_swap_module_matches_python_emitter() -> None:
    assert GENERATED_FIXTURE.read_text() == render_generated_swap_module()
