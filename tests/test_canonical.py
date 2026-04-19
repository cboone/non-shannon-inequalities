from pathlib import Path

from non_shannon_search.canonical import canonicalize_candidate
from non_shannon_search.schema import load_candidate


FIXTURE = Path(__file__).resolve().parents[1] / "data" / "fixtures" / "zhang-yeung.json"


def test_canonicalize_sorts_terms_and_normalizes_sign() -> None:
    candidate = load_candidate(FIXTURE)
    canonical = canonicalize_candidate(candidate)

    assert canonical.terms[0].coefficient > 0
    assert [term.subset for term in canonical.terms] == sorted(
        [term.subset for term in canonical.terms],
        key=lambda subset: (len(subset), subset),
    )
