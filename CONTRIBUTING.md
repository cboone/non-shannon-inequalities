# Contributing to non-shannon-inequalities

Thank you for your interest in contributing to `non-shannon-inequalities`.

Please note that this project has a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold it.

## Reporting Issues

- **Bug reports and feature requests:** use the repository's issue tracker
- **Security vulnerabilities:** see [SECURITY.md](.github/SECURITY.md)

## Development Setup

### Requirements

- Lean 4 toolchain (version specified in `lean-toolchain`)
- Lake (bundled with Lean)
- `uv`
- `markdownlint-cli2`
- `cspell`

### Getting Started

```bash
# Bootstrap Lean dependencies and the Python environment
make bootstrap

# Run the text linters and Python linter
make lint

# Run the full local check
make check
```

If you only need the Lean toolchain, `bin/bootstrap-worktree` remains the minimal bootstrap path.

## Code Style

- Run `make check` before committing
- Follow the Lean conventions documented in `AGENTS.md`
- Add domain-specific terms to `cspell-words.txt` when needed
- Every public module added in `NonShannon/` must land with a matching `NonShannonTest/` module covering it via `example` checks
- Keep large generated search exhaust out of git; only curated fixtures under `data/fixtures/` should be tracked

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
<type>: <description>
```

Recommended types for this repo: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`.

## Pull Request Process

1. Create a feature branch.
2. Make your changes.
3. Ensure all checks pass with `make check`.
4. Submit a pull request.

## Contact

For questions not covered by the issue tracker, email [contact@snappy.sh](mailto:contact@snappy.sh).
