---
applyTo: "src/non_shannon_search/**/*.py"
---

# PR Review: Python Tooling

- **Repo-rooted schema loading is intentional.** `non_shannon_search` loads tracked JSON schemas relative to the repository checkout (via `Path(__file__).resolve().parents[...]`). Do not suggest replacing this with `importlib.resources`, package-data bundling, or wheel-install compatibility shims. The Python tooling is run from the repo checkout with `uv` (typically `uv run` or an editable install); non-editable wheel installs to `site-packages` are not a supported usage pattern. Packaging changes are tracked as future work, not PR-review findings.
- **`schemas/` is a repo-level reproducibility artifact**, not package data. It sits outside `src/non_shannon_search/` on purpose so that the tracked JSON schemas are reviewable alongside Lean statements rather than hidden inside the Python package.
- **No `variable_count` caps on orbit enumeration.** `iter_symmetric_group`, `orbit_canonical`, `orbit_id_of`, and the `canonicalize` CLI intentionally enumerate the full symmetric group `S_n` without an upper bound on `n`. The prior `n <= 6` cap was removed in commit `3929fa5` (`fix(python): support larger orbit scopes`). Do not suggest reinstating a numeric cap, raising for large `n`, adding `--max-orbit-n` / `--skip-orbit-id` CLI flags, or adding a schema `maximum` on `variable_count`. Orbit enumeration is factorial by definition and callers opt in by choosing the orbit surface; docstrings already document that callers pay the full factorial cost.
