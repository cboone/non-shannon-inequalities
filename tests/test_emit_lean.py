# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from dataclasses import replace
from fractions import Fraction
from pathlib import Path

import pytest

from non_shannon_search.emit_lean import (
    emit_candidate_constant,
    format_lean_string,
    lean_basis_constructor,
)
from non_shannon_search.schema import load_candidate


FIXTURE = Path(__file__).resolve().parents[1] / "data" / "fixtures" / "zhang-yeung.json"


def test_format_lean_string_uses_double_quotes() -> None:
    assert format_lean_string("hello") == '"hello"'


def test_format_lean_string_escapes_backslash_and_quote() -> None:
    assert format_lean_string('a"b\\c') == '"a\\"b\\\\c"'


def test_format_lean_string_escapes_whitespace_and_control() -> None:
    assert format_lean_string("\n\r\t") == '"\\n\\r\\t"'
    assert format_lean_string("\x01") == '"\\u{1}"'


def test_emit_candidate_constant_emits_double_quoted_strings() -> None:
    candidate = load_candidate(FIXTURE)
    source = emit_candidate_constant(candidate)

    assert f'id := "{candidate.id}"' in source
    assert f'label := "{candidate.label}"' in source
    assert f'source := "{candidate.provenance.source}"' in source
    assert f'note := "{candidate.provenance.note}"' in source
    assert "'" not in source.splitlines()[1]


def test_emit_candidate_constant_renders_rational_coefficients() -> None:
    candidate = load_candidate(FIXTURE)
    source = emit_candidate_constant(candidate)

    assert "(1 : Rat)" in source
    assert "(-4 : Rat)" in source

    for term in candidate.terms:
        assert isinstance(term.coefficient, Fraction)


def test_emit_candidate_constant_rejects_invalid_derived_identifier() -> None:
    candidate = replace(load_candidate(FIXTURE), id="1st candidate")
    with pytest.raises(ValueError, match="valid Lean identifier"):
        emit_candidate_constant(candidate)


def test_emit_candidate_constant_rejects_invalid_explicit_identifier() -> None:
    candidate = load_candidate(FIXTURE)
    with pytest.raises(ValueError, match="constant_name"):
        emit_candidate_constant(candidate, constant_name="has space")


def test_emit_candidate_constant_accepts_override_for_unsafe_id() -> None:
    candidate = replace(load_candidate(FIXTURE), id="1st candidate")
    source = emit_candidate_constant(candidate, constant_name="first_candidate")

    assert "def first_candidate : CandidateInequality" in source


def test_emit_candidate_constant_renders_basis_from_candidate() -> None:
    candidate = load_candidate(FIXTURE)
    source = emit_candidate_constant(candidate)

    assert "basis := .jointEntropy" in source


def test_lean_basis_constructor_maps_joint_entropy() -> None:
    assert lean_basis_constructor("joint_entropy") == ".jointEntropy"


def test_emit_candidate_constant_rejects_unknown_basis() -> None:
    candidate = replace(load_candidate(FIXTURE), basis="conditional_entropy")
    with pytest.raises(ValueError, match="unsupported basis"):
        emit_candidate_constant(candidate)
