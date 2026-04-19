---
applyTo: "src/non_shannon_search/**/*.py"
---

# PR Review: Python Tooling

- **Repo-rooted schema loading is intentional.** `non_shannon_search` loads tracked JSON schemas relative to the repository checkout (via `Path(__file__).resolve().parents[...]`). Do not suggest replacing this with `importlib.resources`, package-data bundling, or wheel-install compatibility shims. The Python tooling is run from the repo checkout with `uv` (typically `uv run` or an editable install); non-editable wheel installs to `site-packages` are not a supported usage pattern. Packaging changes are tracked as future work, not PR-review findings.
- **`schemas/` is a repo-level reproducibility artifact**, not package data. It sits outside `src/non_shannon_search/` on purpose so that the tracked JSON schemas are reviewable alongside Lean statements rather than hidden inside the Python package.
