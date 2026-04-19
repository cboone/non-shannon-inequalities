from pathlib import Path

from non_shannon_search.schema import load_candidate, validate_candidate_path


FIXTURE = Path(__file__).resolve().parents[1] / "data" / "fixtures" / "zhang-yeung.json"


def test_fixture_validates_against_schema() -> None:
    validate_candidate_path(FIXTURE)


def test_fixture_loads_as_reference_candidate() -> None:
    candidate = load_candidate(FIXTURE)

    assert candidate.id == "zhang-yeung-averaged-scaled"
    assert candidate.variable_count == 4
    assert candidate.status == "reference"
