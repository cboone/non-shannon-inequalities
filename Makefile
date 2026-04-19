MATHLIB_BUILD_DIR := .lake/packages/mathlib/.lake/build/lib/lean

build: _check-mathlib-cache ## Build the NonShannon library
	lake build NonShannon

bootstrap: ## Bootstrap worktree (lake update, cache get, build)
	bin/bootstrap-worktree

_check-mathlib-cache:
	@if [ ! -d "$(MATHLIB_BUILD_DIR)" ] || { [ ! -f "$(MATHLIB_BUILD_DIR)/Mathlib.olean" ] && [ -z "$$(find $(MATHLIB_BUILD_DIR)/Mathlib -name '*.olean' -print -quit 2>/dev/null)" ]; }; then \
		echo "Error: Mathlib prebuilt artifacts not found." >&2; \
		echo "Run 'make bootstrap' or 'bin/bootstrap-worktree' first." >&2; \
		exit 1; \
	fi

test: _check-mathlib-cache ## Run Lean tests (NonShannonTest example suite)
	lake test

lean-lint: _check-mathlib-cache ## Run Lean linter (batteries)
	lake lint

lint: lint-markdown lint-spelling ## Run text linters

lint-markdown: ## Lint Markdown files
	markdownlint-cli2 "**/*.md"

lint-spelling: ## Check spelling with cspell
	cspell --no-progress .

check: lint lean-lint build test ## Lint, build, and test

clean: ## Remove Lake build artifacts
	lake clean

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: build bootstrap clean lint lint-markdown lint-spelling lean-lint test check help _check-mathlib-cache
