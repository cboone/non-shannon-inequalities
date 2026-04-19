from __future__ import annotations

from fractions import Fraction
import re

from .schema import CandidateInequality


LEAN_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_']*$")


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
    term_lines = [
        "          ["
        + ",\n".join(
            f"            {{ subset := {{ vars := {list(term.subset)} }}, coefficient := {format_lean_rational(term.coefficient)} }}"
            for term in candidate.terms
        )
        + " ]"
    ]
    terms_block = "\n".join(term_lines)
    return (
        f"def {name} : CandidateInequality :=\n"
        f"  {{ id := {format_lean_string(candidate.id)}\n"
        f"    label := {format_lean_string(candidate.label)}\n"
        f"    vector :=\n"
        f"      {{ variableCount := {candidate.variable_count}\n"
        f"        basis := .jointEntropy\n"
        f"        terms :=\n"
        f"{terms_block} }}\n"
        f"    provenance := {{ source := {format_lean_string(candidate.provenance.source)}, note := {format_lean_string(candidate.provenance.note)} }}\n"
        f"    status := .{candidate.status} }}"
    )
