from __future__ import annotations

from fractions import Fraction

from .schema import CandidateInequality


def format_lean_rational(value: Fraction) -> str:
    """Formats a rational coefficient for Lean source emission."""

    if value.denominator == 1:
        return f"({value.numerator} : Rat)"
    return f"(({value.numerator} : Rat) / ({value.denominator} : Rat))"


def emit_candidate_constant(candidate: CandidateInequality, constant_name: str | None = None) -> str:
    """Emits a Lean constant skeleton for one candidate inequality fixture."""

    name = constant_name or candidate.id.replace("-", "_")
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
        f"  {{ id := {candidate.id!r}\n"
        f"    label := {candidate.label!r}\n"
        f"    vector :=\n"
        f"      {{ variableCount := {candidate.variable_count}\n"
        f"        basis := .jointEntropy\n"
        f"        terms :=\n"
        f"{terms_block} }}\n"
        f"    provenance := {{ source := {candidate.provenance.source!r}, note := {candidate.provenance.note!r} }}\n"
        f"    status := .{candidate.status} }}"
    )
