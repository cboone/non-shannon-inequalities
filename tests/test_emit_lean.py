from fractions import Fraction
from pathlib import Path

from non_shannon_search.emit_lean import emit_candidate_constant, format_lean_string
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

    assert "(-1 : Rat)" in source
    assert "(6 : Rat)" in source

    for term in candidate.terms:
        assert isinstance(term.coefficient, Fraction)
