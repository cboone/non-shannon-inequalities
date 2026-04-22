# SPDX-FileCopyrightText: 2026 Christopher Boone
#
# SPDX-License-Identifier: MIT

from __future__ import annotations

from fractions import Fraction
import re

from .canonical import canonicalize_candidate
from .schema import CandidateInequality
from .symmetry import apply_candidate, transposition


LEAN_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_']*$")


BASIS_LEAN_CONSTRUCTOR = {
    "joint_entropy": ".jointEntropy",
}


TRACKED_ZHANG_YEUNG_ID = "zhang-yeung-averaged-scaled"
TRACKED_ZHANG_YEUNG_VARIABLE_COUNT = 4
TRACKED_ZHANG_YEUNG_BASIS = "joint_entropy"


def lean_basis_constructor(basis: str) -> str:
    """Maps a schema-level `basis` value to its Lean `CoordinateBasis` constructor."""

    try:
        return BASIS_LEAN_CONSTRUCTOR[basis]
    except KeyError:
        supported = ", ".join(sorted(BASIS_LEAN_CONSTRUCTOR))
        raise ValueError(
            f"unsupported basis {basis!r}; emit_lean knows these bases: {supported}"
        ) from None


def format_lean_rational(value: Fraction) -> str:
    """Formats a rational coefficient for Lean source emission."""

    if value.denominator == 1:
        return f"({value.numerator} : Rat)"
    return f"(({value.numerator} : Rat) / ({value.denominator} : Rat))"


def format_lean_string(value: str) -> str:
    """Formats a Python string as a Lean 4 double-quoted string literal."""

    pieces = ['"']
    for character in value:
        codepoint = ord(character)
        if character == "\\":
            pieces.append("\\\\")
        elif character == '"':
            pieces.append('\\"')
        elif character == "\n":
            pieces.append("\\n")
        elif character == "\r":
            pieces.append("\\r")
        elif character == "\t":
            pieces.append("\\t")
        elif codepoint < 0x20 or codepoint == 0x7F:
            pieces.append(f"\\u{{{codepoint:x}}}")
        else:
            pieces.append(character)
    pieces.append('"')
    return "".join(pieces)


def emit_candidate_constant(candidate: CandidateInequality, constant_name: str | None = None) -> str:
    """Emits a Lean constant skeleton for one candidate inequality fixture."""

    name = constant_name if constant_name is not None else candidate.id.replace("-", "_")
    if not LEAN_IDENTIFIER_RE.match(name):
        source = "constant_name" if constant_name is not None else f"candidate id {candidate.id!r}"
        raise ValueError(
            f"{source} does not yield a valid Lean identifier ({name!r}); "
            "pass an explicit constant_name (or --name on the CLI)"
        )
    terms_block = (
        "          [\n"
        + ",\n".join(
            f"            {{ subset := {{ vars := {list(term.subset)} }}, coefficient := {format_lean_rational(term.coefficient)} }}"
            for term in candidate.terms
        )
        + " ]"
    )
    return (
        f"def {name} : CandidateInequality :=\n"
        f"  {{ id := {format_lean_string(candidate.id)}\n"
        f"    label := {format_lean_string(candidate.label)}\n"
        f"    vector :=\n"
        f"      {{ variableCount := {candidate.variable_count}\n"
        f"        basis := {lean_basis_constructor(candidate.basis)}\n"
        f"        terms :=\n"
        f"{terms_block} }}\n"
        f"    provenance := {{ source := {format_lean_string(candidate.provenance.source)}, note := {format_lean_string(candidate.provenance.note)} }}\n"
        f"    status := .{candidate.status} }}"
    )


def emit_candidate_module(
    candidate: CandidateInequality,
    *,
    constant_name: str,
    comment: str,
) -> str:
    """Wraps one emitted candidate constant in the standard Lean fixture module boilerplate."""

    constant = emit_candidate_constant(candidate, constant_name=constant_name)
    return "\n".join(
        [
            "-- SPDX-FileCopyrightText: 2026 Christopher Boone",
            "--",
            "-- SPDX-License-Identifier: Apache-2.0",
            "",
            "import NonShannon",
            "",
            "namespace NonShannonTest",
            "",
            "open NonShannon",
            "",
            f"/- {comment} -/",
            constant,
            "",
            "end NonShannonTest",
            "",
        ]
    )


SWAP_ZERO_ONE_CONSTANT_NAME = "zhangYeungSwapZeroOneFromPython"
SWAP_ZERO_ONE_COMMENT = (
    "Generated from Python's swap-zero-one Zhang-Yeung fixture. Keep in sync with tests/test_symmetry.py."
)


def validate_swap_zero_one_candidate(candidate: CandidateInequality) -> None:
    """Rejects candidates that do not match the tracked Zhang-Yeung swap fixture."""

    if (
        candidate.id != TRACKED_ZHANG_YEUNG_ID
        or candidate.variable_count != TRACKED_ZHANG_YEUNG_VARIABLE_COUNT
        or candidate.basis != TRACKED_ZHANG_YEUNG_BASIS
    ):
        raise ValueError(
            "emit_swap_zero_one_module only supports the tracked Zhang-Yeung fixture "
            f"(id={TRACKED_ZHANG_YEUNG_ID!r}, "
            f"variable_count={TRACKED_ZHANG_YEUNG_VARIABLE_COUNT}, "
            f"basis={TRACKED_ZHANG_YEUNG_BASIS!r}), got "
            f"id={candidate.id!r}, variable_count={candidate.variable_count}, "
            f"basis={candidate.basis!r}"
        )


def emit_swap_zero_one_module(candidate: CandidateInequality) -> str:
    """Emits the checked-in Lean module for the canonicalized swap-zero-one action on one candidate."""

    validate_swap_zero_one_candidate(candidate)
    swapped = canonicalize_candidate(
        apply_candidate(transposition(candidate.variable_count, 0, 1), candidate)
    )
    return emit_candidate_module(
        swapped,
        constant_name=SWAP_ZERO_ONE_CONSTANT_NAME,
        comment=SWAP_ZERO_ONE_COMMENT,
    )
