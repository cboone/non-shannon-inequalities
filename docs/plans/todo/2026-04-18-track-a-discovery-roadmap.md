# 2026-04-18 Track A Discovery Roadmap

**Created:** 2026-04-18
**Target:** Lean 4 plus Python hybrid research repository
**Program document:** `~/Development/zhang-yeung-inequality/docs/plans/todo/2026-04-17-non-shannon-inequality-discovery-program.md`, Track A section.
**Primary paper anchors:** Zhang and Yeung 1998 (IEEE TIT 44(4), pp. 1440-1452); Dougherty, Freiling, and Zeger 2006 / 2011 (arXiv:1104.3602); Matús 2007 (IEEE TIT 53(1), pp. 320-330).
**Bibliography source:** `references/papers.bib`.

**Resolved decisions:**

- **Scope (resolved):** M0 through M5 as core; M6 catalog curation and paper-facing outputs as stretch. Details in Section 4.
- **Strategy:** copy-lemma-guided inequality search with an external redundancy LP oracle and Lean-side validation of survivors.
- **Dependency:** permanent PFR dependency (`teorth/pfr`, pin `80daaf1`) for the Shannon entropy API.
- **Naming:** Lean library `NonShannon`, sibling test library `NonShannonTest`, Python package `non_shannon_search`.
- **Track B:** finite-group correspondence work (Chan-Yeung 2002) is deferred to a future roadmap; see Section 9.

## 1. Context

Non-Shannon information inequalities are linear inequalities among joint entropies of `n` discrete random variables that hold for every distribution but are not derivable from the basic Shannon inequalities. Zhang and Yeung 1998 (eq. 21, p. 1445) exhibited the first such inequality for `n = 4`; Dougherty, Freiling, and Zeger 2006 and 2011 exhibited six more; Matús 2007 showed the family is infinite. No proof assistant has a systematic catalog of these inequalities, and the standard discovery pipeline (LP-based tools like ITIP, Xitip, psitip, AITIP) can detect candidates but cannot emit machine-checkable proof certificates for the non-Shannon portion.

This roadmap turns Track A from the parent discovery program into a repo-local execution plan. The bootstrap plan (`docs/plans/done/2026-04-18-bootstrap-repo.md`) created the three repository layers: a Lean statement layer, a Python search and canonicalization layer, and a shared schema layer. This roadmap governs the research and implementation milestones that follow.

Track A's objective is to discover candidate non-Shannon inequalities through copy-lemma-guided search, filter them with an external redundancy oracle, and validate the survivors as curated, Lean-facing catalog entries. The long-run endpoint is a reusable, reviewable catalog of validated non-Shannon inequalities that can back a first publishable paper slice (Section 6, M6).

Why formalize this at all. The existing LP tooling finds inequalities but produces no artifact that survives review outside the tool's own runtime. A tracked catalog, backed by a shared schema and Lean mirrors of certificate shapes, separates the external oracle's verdict from the mathematical content that Lean can check, and does so in a way that future consumers (papers, downstream formalizations, Track B's group-theoretic correspondence) can cite by identifier.

## 2. State of the Art

### 2.1 PFR and Mathlib

Already upstream and directly usable (verified 2026-04-19 against PFR pin `80daaf1`):

- `PFR.ForMathlib.Entropy.Basic`: Shannon entropy `H[X]`, conditional entropy `H[X | Y]`, mutual information `I[X : Y]`, conditional mutual information `I[X : Y | Z]` on measure-theoretic random variables with finite-range hypotheses.
- `Mathlib.MeasureTheory.Measure.ProbabilityMeasure`, `Mathlib.Probability.Distributions.Uniform`: underlying probability-measure apparatus.

**Gap:** no non-Shannon inequality is formalized anywhere in Mathlib or PFR. This roadmap stays below the formalization threshold (curated statements plus certificate shapes, not proofs of the inequalities) until the sibling project lands a mechanized Zhang-Yeung proof.

### 2.2 `cboone/zhang-yeung-inequality` (sibling project)

The sibling repository is a single-theorem Lean 4 formalization of Zhang-Yeung 1998 Theorem 3, structured as a 6-milestone roadmap (`~/Development/zhang-yeung-inequality/docs/plans/todo/2026-04-15-zhang-yeung-formalization-roadmap.md`). When its M3 lands, Track A can import the Zhang-Yeung theorem statement as the first Lean-checkable validator for curated catalog entries. Until then, Track A treats Zhang-Yeung as a reference fixture only (present as `NonShannon/Examples/ZhangYeung.lean`).

**Transcription:** the sibling project has a verified transcription of Zhang-Yeung 1998 at `~/Development/zhang-yeung-inequality/references/transcriptions/zhangyeung1998.md` (verified 2026-04-16). Track A will depend on that transcription for equation-numbered citations until a local copy lands (see Section 9).

### 2.3 `cboone/shannon-entropy` (user's prior project)

A finite-alphabet Lean 4 formalization of Shannon's 1948 characterization. Indirectly useful: its module layout is one of the structural models for the `NonShannon` / `NonShannonTest` split.

### 2.4 Other proof assistants

- **Coq/Rocq `infotheo`** (Affeldt et al.): full Shannon apparatus, source/channel coding, no non-Shannon inequalities.
- **Isabelle/HOL** (Hoelzl; AFP): measure-theoretic entropy, Shannon coding, no non-Shannon inequalities.
- **HOL4** (Hasan/Tahar): discrete entropy and relative entropy, no non-Shannon inequalities.
- **Mizar:** no relevant entries.

No prior proof-assistant work catalogs non-Shannon inequalities.

### 2.5 External LP tooling

ITIP (Yeung and Yan), Xitip (Pulikkoonattu et al.), psitip (Li), and AITIP (Gattegno et al.) can decide whether a candidate inequality is implied by Shannon inequalities and can search a bounded parameter space for new inequalities. None emit artifacts that survive outside their own runtime; all treat the non-Shannon certificate as an LP verdict, not as a reviewable object. This roadmap's trust boundary (Section 7.3) is designed around that gap.

## 3. Architecture

The repository has three cooperating layers, described in `docs/research/track-a-architecture.md`.

### 3.1 Representation tension: sparse vectors versus packed bitmasks

Two natural encodings for a linear inequality on subset-indexed joint entropies:

| Dimension | Sparse list of `(subset, coefficient)` pairs | Packed `Fin (2^n) -> Rat` vector |
| --- | --- | --- |
| Small `n` | wasteful relative to dense | compact, cache-friendly |
| Large `n` | linear in non-zeros | exponential in `n` |
| Symmetry actions | natural: relabel each subset | awkward: index permutation scrambles the layout |
| Serialization | one JSON object per term; schema-friendly | requires a fixed bit ordering baked into the format |
| Lean encoding | structure with `List InequalityTerm` | `Finset (Fin n) -> Rat` or `Vector Rat (2^n)` |

**Strategy (resolved):** sparse list-of-pairs for both Lean and Python, with normalization invariants (sorted subset indices, sorted term list, sign-normalized leading coefficient, optional orbit representative) carried as predicates rather than enforced at construction. Reason: Track A needs `n` up to 5 or 6 for the first search milestones, subset orbits under `S_n` are the natural canonicalization tool, and the interchange schema is already committed to sparse term lists with rational strings.

### 3.2 Module dependency graph

```text
NonShannon/Prelude.lean
    |
    +-- NonShannon/Inequality/Subsets.lean
    |       |
    |       +-- NonShannon/Inequality/Vector.lean
    |               |
    |               +-- NonShannon/Inequality/Canonical.lean     <-- M1 target
    |
    +-- NonShannon/CopyLemma/Parameters.lean
    |       |
    |       +-- NonShannon/CopyLemma/Parameterized.lean          <-- M2 target
    |
    +-- NonShannon/Certificate/Status.lean
            |
            +-- NonShannon/Certificate/Schema.lean               <-- M3 extends
                    |
                    +-- NonShannon/Catalog.lean                  <-- M6 extends
                            |
                            +-- NonShannon/Examples/ZhangYeung.lean (M0)
                            +-- NonShannon/Examples/DFZ.lean     <-- M4 new
                            +-- NonShannon/Examples/Matus.lean   <-- M4 new
```

### 3.3 Cross-language boundary

The shared JSON schemas under `schemas/` are the contract. Lean mirrors live in `NonShannon/Certificate/Schema.lean`; Python mirrors live in `src/non_shannon_search/schema.py`. A change to one without the other is a schema divergence; M1 lands tests that make round-tripping cross-language a milestone gate.

## 4. Scope (resolved: M0 to M5 core; M6 stretch)

### Core (M0 to M5)

- **M0 (shipped):** repository scaffold, shared schemas, Zhang-Yeung reference fixture. Documented in `docs/plans/done/2026-04-18-bootstrap-repo.md`.
- **M1:** inequality representation and canonicalization, strengthened beyond the bootstrap placeholder. Symmetric-group action on subsets and inequality vectors; orbit-aware canonical form; cross-language round-trip stability on the Zhang-Yeung fixture (`data/fixtures/zhang-yeung.json`).
- **M2:** parameterized copy-lemma statement layer replacing the bootstrap placeholder `parameterizedCopyLemma`. Typed parameter objects for frozen, copied, and conditioning variable blocks; stable statement shape that downstream search code can target.
- **M3:** redundancy-certificate oracle boundary. Backend interface beyond `NotImplementedBackend`; initial certificate semantics for source combinations; explicit `lean_checkable` policy.
- **M4:** known-inequality reproduction. Zhang-Yeung 1998 eq. (21) / eq. (23), p. 1445 (already present); six DFZ inequalities from Dougherty-Freiling-Zeger 2011 (arXiv:1104.3602, Theorems 3.1 to 3.6); first three Matús small cases from Matús 2007 TIT (Section III, pp. 323-324).
- **M5:** bounded search over the `CopyParameters` space, canonicalization and deduplication in the loop, redundancy backend integrated behind the tracked interface, retained survivors curated as fixtures.

### Stretch (M6)

- **M6:** validated catalog and first publishable slice. Expanded `NonShannon/Catalog.lean`, stable naming scheme for validated entries, correspondence between curated fixtures and Lean statement objects. Publishable slice only: full paper manuscript is out of scope (Section 9).

### Out of scope

- Track B finite-group correspondence (Chan-Yeung 2002) and GAP integration.
- Lean-checkable LP certificates (beyond the `lean_checkable` flag in the schema); requires a tighter certificate format than M3 will deliver.
- Mechanized proofs of the non-Shannon inequalities themselves. Zhang-Yeung proof is owned by the sibling project; DFZ and Matús proofs are deferred.
- Full paper drafting beyond planning notes.

## 5. File Layout

```text
non-shannon-inequalities/
  lakefile.toml                   pinned Lake config (PFR rev 80daaf1)
  lean-toolchain                  leanprover/lean4:v4.28.0-rc1
  Makefile                        bootstrap, build, test, lint, check targets
  bin/bootstrap-worktree          mandatory first-run Lean setup
  NonShannon.lean                 top-level re-export
  NonShannon/
    Prelude.lean                  PFR entropy API plus shared types (Var := Nat)
    Inequality/
      Subsets.lean                VariableSubset vocabulary
      Vector.lean                 InequalityTerm and InequalityVector
      Canonical.lean              canonicalize (M1 target) and VariableRelabeling
      Symmetry.lean               (M1 new) group action by Equiv.Perm Var
    CopyLemma/
      Parameters.lean             CopyParameters record
      Parameterized.lean          parameterizedCopyLemma (M2 target)
    Certificate/
      Status.lean                 CertificateStatus enum
      Schema.lean                 CandidateInequality, RedundancyCertificate (M3 extends)
      Oracle.lean                 (M3 new) backend adapter layer on the Lean side
    Catalog.lean                  CatalogEntry and Catalog (M6 extends)
    Examples/
      ZhangYeung.lean             reference fixture (M0)
      DFZ.lean                    (M4 new)
      Matus.lean                  (M4 new)
  NonShannonTest.lean             top-level test re-export
  NonShannonTest/                 mirror of NonShannon/, 1:1 filename mapping
  src/
    non_shannon_search/
      __init__.py
      cli.py                      `canonicalize`, `validate-schema` commands
      schema.py                   Python mirror of tracked schemas
      canonical.py                canonicalization helpers (M1 extends)
      symmetry.py                 (M1 new) permutation actions and orbit helpers
      redundancy_lp.py            backend interface (M3 extends)
      emit_lean.py                text emitter for future Lean skeletons
      search.py                   (M5 new) bounded enumeration driver
  tests/
    test_canonical.py             canonicalization round-trip (M1 extends)
    test_schema.py                schema validation
    test_emit_lean.py             emitter smoke tests
    test_symmetry.py              (M1 new)
    test_redundancy_lp.py         (M3 new)
    test_search.py                (M5 new)
  schemas/
    candidate-inequality.schema.json
    redundancy-certificate.schema.json
  data/
    fixtures/
      zhang-yeung.json            M0 reference fixture
      dfz-*.json                  (M4 new, one per DFZ inequality)
      matus-*.json                (M4 new)
      retained/*.json             (M5 new, curated search survivors)
  references/
    papers/, transcriptions/, papers.bib, README.md
  docs/
    plans/{todo,done}/
    research/
      track-a-architecture.md, interchange-format.md, trust-boundary.md
      first-bounded-search.md     (M5 new)
      publishable-slice.md        (M6 new)
```

Namespace convention: flat under `NonShannon` for now (per `AGENTS.md`). New Lean files go under `NonShannon/` with a 1:1 test-mirror under `NonShannonTest/`. Tab size 2, `autoImplicit = false`, `relaxedAutoImplicit = false`.

## 6. Milestone-by-Milestone Plan

### Dependency graph

```text
M0 (shipped) -> M1 -> M2 -> M3 -> M4 -> M5 -> M6
                 |         ^
                 +---------+  (M1 canonicalization used by M3 certificate semantics
                               and by every downstream milestone)
```

Sequential throughout. Parallelism is possible between Python-side and Lean-side work within a milestone (shared schema is the contract), but not across milestones. M6 is stretch; see Section 4.

### Milestone plan spin-out

Per the write-formalization-roadmap spin-out convention, each milestone's implementation elaboration lives in a separate plan file under `docs/plans/todo/<YYYY-MM-DD>-<milestone-slug>.md`. When the milestone ships, the plan moves to `docs/plans/done/`. The Section 6 entries below carry the 5-part summary only; they do not duplicate the elaboration. Plan files spin out at the start of each milestone; milestones not yet started have no plan file.

### M0: Repository scaffold and shared schemas (shipped 2026-04-19)

One-line summary: repository scaffold, test library, Python workspace, shared schemas, and Zhang-Yeung reference fixture.

**Deliverables (all landed).**

- `lakefile.toml`, `lean-toolchain`, `bin/bootstrap-worktree`, `Makefile`, `NonShannon.lean` plus `NonShannon/Prelude.lean`, sibling `NonShannonTest` library with smoke-test `example`s per public module.
- `pyproject.toml`, `uv.lock`, `src/non_shannon_search/*.py`, `tests/test_*.py`.
- Tracked schemas `schemas/candidate-inequality.schema.json` and `schemas/redundancy-certificate.schema.json`; Lean mirrors under `NonShannon/Certificate/`; Python mirrors in `src/non_shannon_search/schema.py`.
- Zhang-Yeung reference fixture at `data/fixtures/zhang-yeung.json` (eq. 23, p. 1445, scaled by 4) plus Lean mirror `NonShannon/Examples/ZhangYeung.lean`.
- CI workflows (Lean job, Python job, text-lint job).
- References scaffolding (`references/papers.bib`, `references/README.md`), research notes (`docs/research/track-a-architecture.md`, `interchange-format.md`, `trust-boundary.md`), community files.

**Why now.** This is the structural scaffolding milestone mandated by the write-formalization-roadmap conventions. Every subsequent milestone assumes `make check` is green in a fresh worktree.

**Testing approach.** `NonShannonTest/Inequality/Vector.lean`, `NonShannonTest/Inequality/Canonical.lean`, `NonShannonTest/Certificate/Schema.lean`, `NonShannonTest/CopyLemma/Parameters.lean`, `NonShannonTest/Catalog.lean`, `NonShannonTest/Examples/ZhangYeung.lean`, `NonShannonTest/Prelude.lean` all present and building. Python: `tests/test_canonical.py`, `tests/test_schema.py`, `tests/test_emit_lean.py`.

**Checkpoint gate (met).** `make check` green at merge commit `cfc976c` on 2026-04-19.

**Plan file:** `docs/plans/done/2026-04-18-bootstrap-repo.md`.

### M1: Inequality representation and canonicalization

One-line summary: strengthen the sparse-vector layer with term normalization, symmetry group actions, and orbit-aware canonicalization, cross-checked between Lean and Python on the Zhang-Yeung fixture.

**Deliverables.**

- `NonShannon/Inequality/Canonical.lean`: enrich `canonicalize` beyond sign normalization with duplicate-term combination, subset-sorted term ordering, and orbit-representative selection. Predicate `isCanonical` strengthened in lockstep.
- `NonShannon/Inequality/Symmetry.lean` (new): group action of `Equiv.Perm Var` (or a finite-index specialization) on `VariableSubset`, `InequalityTerm`, and `InequalityVector`. Upgrades `VariableRelabeling` from a bare function to a bijection-carrying structure.
- `NonShannon/Inequality/Vector.lean` and `NonShannon/Inequality/Subsets.lean`: supporting normalization lemmas (`VariableSubset.isNormalized` preservation, `InequalityVector` combination rules).
- `NonShannon/Certificate/Schema.lean`: orbit-ID plumbing through `CandidateInequality.symmetryOrbitSize?` and a new orbit-representative field on the Lean side, matched by a schema revision.
- `src/non_shannon_search/canonical.py`: duplicate combination (already present) plus permutation action and orbit-representative selection matching the Lean side.
- `src/non_shannon_search/symmetry.py` (new): permutation generation helpers, orbit enumeration, representative selection.
- Schema revision to `schemas/candidate-inequality.schema.json` if orbit metadata shape changes; migration note in `docs/research/interchange-format.md`.

**Why now.** M0 landed the sparse-vector vocabulary with a placeholder `canonicalize` that only normalizes sign. Every downstream milestone needs more: M2 statement shapes must be comparable up to variable relabeling, M3 certificate source-combination checks need orbit-aware deduplication, M4 known-inequality reproduction must equate DFZ inequalities under `S_n`, and M5's bounded search is useless without dedup. M1 is therefore the load-bearing kernel; errors here propagate to every later milestone.

**Testing approach.** `NonShannonTest/Inequality/Canonical.lean` (extended from the M0 smoke test), `NonShannonTest/Inequality/Symmetry.lean` (new), and `NonShannonTest/Inequality/Orbit.lean` (new) cover: idempotence of `canonicalize`, group-action laws (identity and composition) by `example`, and equality of canonical representatives across orbit members. Python: `tests/test_canonical.py` extended with round-trip tests; `tests/test_symmetry.py` (new) mirrors the Lean action laws. Cross-language: round-tripping `data/fixtures/zhang-yeung.json` through `canonicalize` (Python), serializing, and comparing against the Lean canonical form on the same fixture produces identical orbit IDs.

**Checkpoint gate.** `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` all green. Concrete sanity check: applying a non-trivial element of `S_4` to the Zhang-Yeung fixture produces a value with the same canonical form and the same orbit ID in both Lean and Python, verified by `example` (Lean) and `pytest` (Python).

**Plan file:** `docs/plans/todo/2026-04-20-m1-inequality-representation-and-canonicalization.md` (spin out at milestone start).

### M2: Parameterized copy-lemma statement layer

One-line summary: replace the bootstrap `parameterizedCopyLemma` placeholder with a stable statement vocabulary that downstream search code can target.

**Deliverables.**

- `NonShannon/CopyLemma/Parameterized.lean`: replace the placeholder spec with a typed shape. Introduce `CopyLemmaStatement` (or similar) carrying frozen, copied, and conditioning blocks plus the induced conditional-independence pattern. Retain `ParameterizedCopyLemmaTarget` as the naming-convention record for theorem-generation metadata.
- `NonShannon/CopyLemma/Parameters.lean`: any additional invariants on `CopyParameters` surfaced by the typed shape (for example, disjointness of `frozen`, `copied`, and `conditioning` subsets).
- First nontrivial statement-layer lemma: a characterization of when two `CopyParameters` values induce the same statement shape modulo variable relabeling. This is the bridge between M1's symmetry layer and copy-lemma statements.
- Theorem-name and module-name conventions for future generated statement targets, documented in a new `docs/research/copy-lemma-naming.md`.

**Why now.** M1 delivered an orbit-aware canonical form for inequalities; M2 lifts that to copy-lemma parameters so that equivalent parameter choices produce equivalent statements. Downstream, M4 consumes the statement shape to annotate known-inequality reproductions, and M5 uses it to dedupe search outputs. Attempting M3 before M2 would force the certificate schema to carry implementation-specific parameter shapes; landing M2 first keeps the certificate layer parameter-shape-agnostic.

**Testing approach.** `NonShannonTest/CopyLemma/Parameters.lean` (extended), `NonShannonTest/CopyLemma/Parameterized.lean` (new) exercise the public API from outside `NonShannon`: construction of representative `CopyParameters` values, the statement-shape equivalence lemma on a small fixture, and the theorem-naming record's string format.

**Checkpoint gate.** `lake build NonShannon`, `lake lint`, `lake test` green. Statement shape frozen: a roadmap note in `docs/research/copy-lemma-naming.md` records the exact field layout of `CopyLemmaStatement` as of milestone closure, so future refactors must explicitly motivate changes.

**Plan file:** `docs/plans/todo/<date>-m2-copy-lemma-statement-layer.md` (spin out at milestone start).

### M3: Redundancy-certificate oracle boundary

One-line summary: make external LP output auditable by tightening the certificate interface and adding a concrete adapter behind the `RedundancyBackend` protocol.

**Deliverables.**

- `src/non_shannon_search/redundancy_lp.py`: at least one concrete backend beyond `NotImplementedBackend`, hidden behind the protocol. Candidate first target: a thin adapter over an existing LP (ITIP-style, via `scipy.optimize.linprog` or a pulled-in backend) that emits the tracked certificate format. Exact backend choice deferred to the spun-out plan.
- `NonShannon/Certificate/Oracle.lean` (new): Lean-side adapter types mirroring the oracle boundary, with `lean_checkable = false` as the default until a checkable format is designed.
- Tightened certificate semantics for source combinations in `NonShannon/Certificate/Schema.lean`: rational-arithmetic invariants (weights sum to a specified target, sources are all valid candidate IDs) expressed as predicates.
- Updated `docs/research/trust-boundary.md` documenting the backend name, version string, `lean_checkable` policy, and the explicit disclaimer that an `lean_checkable = false` certificate is a provisional artifact.

**Why now.** M2 froze the statement layer; before M5 runs a search that generates real certificates, the shape of a certificate and the trust boundary around it must be stable. Landing M3 before M4 means known-inequality reproduction can exercise the oracle on ground-truth inequalities (Zhang-Yeung, DFZ, Matús) and catch pipeline bugs against a known answer, not against search output.

**Testing approach.** `NonShannonTest/Certificate/Schema.lean` extended with `example`s for the new rational-arithmetic invariants. `NonShannonTest/Certificate/Oracle.lean` (new) covers the Lean-side adapter's public surface. Python: `tests/test_redundancy_lp.py` (new) runs the concrete backend on synthetic small inputs where the answer is decidable by hand (for example: a candidate that is a positive rational combination of two listed sources).

**Checkpoint gate.** `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` green. Sanity check: the concrete backend returns a valid, schema-conforming certificate on the synthetic test input, and that certificate round-trips through the Lean `RedundancyCertificate` mirror without loss.

**Plan file:** `docs/plans/todo/<date>-m3-redundancy-oracle-boundary.md` (spin out at milestone start).

### M4: Known-inequality reproduction

One-line summary: reproduce the Zhang-Yeung, DFZ-6, and first Matús cases as tracked fixtures that the canonicalization and oracle pipeline handles correctly.

**Deliverables.**

- `NonShannon/Examples/DFZ.lean` (new): Lean mirrors of the six Dougherty-Freiling-Zeger inequalities (Dougherty, Freiling, and Zeger 2011, Theorems 3.1 to 3.6, arXiv:1104.3602).
- `NonShannon/Examples/Matus.lean` (new): Lean mirrors of the first three small Matús family cases (Matús 2007 TIT, Section III, pp. 323-324).
- `data/fixtures/dfz-*.json` (six fixtures) and `data/fixtures/matus-*.json` (three fixtures).
- A verified local transcription of the DFZ 2011 preprint at `references/transcriptions/doughertyfreilingzeger2011.md`, with verification date recorded. (Zhang-Yeung 1998 transcription lives in the sibling project; Track A cites it by path until a local copy is made.)
- Optional: begin a local Zhang-Yeung 1998 transcription if the sibling project's copy is not enough.

**Why now.** M1, M2, and M3 give representation, statements, and oracle. M4 is the sanity check before M5 runs a real search: every listed fixture must be non-redundant under the oracle (because each is a genuine non-Shannon inequality), must canonicalize identically in Lean and Python, and must round-trip through the schema. A bug in the pipeline that survives M3 will fail on a known input here, before search output muddies the diagnosis.

**Testing approach.** `NonShannonTest/Examples/DFZ.lean` (new) and `NonShannonTest/Examples/Matus.lean` (new) test: each fixture's Lean mirror loads, its vector has the expected `variableCount`, its canonical form is stable under the canonicalizer, and its orbit representative matches the Python computation. Python: `tests/test_canonical.py` extended to cover each fixture. Cross-language: `make check` passes on the full known set.

**Checkpoint gate.** `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` green. All nine fixtures (Zhang-Yeung plus DFZ-6 plus three Matús) canonicalize identically cross-language; the oracle (M3) returns non-redundant verdicts on all nine.

**Plan file:** `docs/plans/todo/<date>-m4-known-inequality-reproduction.md` (spin out at milestone start).

### M5: Bounded search over parameter families

One-line summary: run the first deliberately small copy-lemma-parameter search with canonicalization, dedup, and oracle filtering in the loop, emit curated survivors.

**Deliverables.**

- `src/non_shannon_search/search.py` (new): bounded enumeration driver over `CopyParameters`. Parameters: `variableCount <= 5`, `copyCount <= 2`, enumeration of frozen/copied/conditioning splits. Shape deliberately small; the goal is to exercise the pipeline end to end, not to find novel inequalities.
- Canonicalization and orbit-dedup in the loop, using the M1 surface.
- Redundancy backend integration behind the M3 protocol.
- Retained survivors written as curated `data/fixtures/retained/*.json`, not raw enumeration exhaust. `.gitignore` prevents raw exhaust from entering the tree.
- `docs/research/first-bounded-search.md`: search parameters, runtime, retained-count, and any surprises.

**Why now.** Every upstream dependency is in place: representation (M1), statements (M2), oracle (M3), known-inequality sanity checks (M4). M5 is the first milestone that can actually produce new candidate inequalities, and it is the first milestone whose success is not guaranteed by construction (the retained count could be zero, and that would itself be a publishable result about the bounded family).

**Testing approach.** `NonShannonTest/Examples/FirstSearchRetained.lean` (new): each retained fixture loads as a Lean `CandidateInequality` and passes the orbit-ID stability check. Python: `tests/test_search.py` (new) runs the search driver on a trivially-small parameter subset where the retained count is known (one, zero, or a handful) and verifies the result.

**Checkpoint gate.** `lake build NonShannon`, `lake lint`, `lake test`, `make py-test` green. Search run documented in `docs/research/first-bounded-search.md` with parameters, retained count, and runtime. Every retained candidate validates against the schema and canonicalizes identically cross-language.

**Plan file:** `docs/plans/todo/<date>-m5-bounded-search.md` (spin out at milestone start).

### M6: Validated catalog and paper-facing outputs (stretch)

One-line summary: crystallize reproduced and retained inequalities into a curated catalog with proof-facing metadata and a first publishable slice.

**Deliverables.**

- Expanded `NonShannon/Catalog.lean`: catalog populated with Zhang-Yeung (M0), DFZ-6 (M4), Matús-3 (M4), and M5 retained survivors.
- Stable naming scheme for validated entries, documented in `docs/research/catalog-naming.md` (new).
- Correspondence between curated fixtures and Lean-facing statement objects (via M2 statement layer plus M3 certificates).
- `docs/research/publishable-slice.md`: planning note describing the first paper-facing slice of the catalog, including which entries are candidates for inclusion and why.

**Why now.** M5 lands the first search output; M6 is where the pipeline's value to downstream consumers (paper authors, Track B, Mathlib contributors) becomes visible. It is stretch because the publishable-slice argument needs at least one new retained inequality from M5 that is not already known, which is not guaranteed.

**Testing approach.** `NonShannonTest/Catalog.lean` extended: catalog loads, each entry's `id` is unique, each entry's canonical form matches its stored fixture, and the naming scheme is well-formed.

**Checkpoint gate.** `lake build NonShannon`, `lake lint`, `lake test` green. Catalog tests in Lean; publishable-slice note exists and names a concrete scope for the first paper.

**Plan file:** `docs/plans/todo/<date>-m6-validated-catalog.md` (spin out at milestone start).

## 7. Key Risks and Unknowns

### 7.1 Canonicalization pacing bottleneck (moderate)

Orbit-aware canonicalization requires enumerating coset representatives under a subgroup of `S_n`, which grows as `n!` in the worst case. For `n <= 5` this is fine; for `n = 6` it is `720` permutations per inequality, still manageable; beyond that, M5's search loop cost is dominated by canonicalization, not by the LP oracle. **Mitigation:** benchmark during M1 on `n = 4` and `n = 5` fixtures; if canonicalization is already a bottleneck at the M1 checkpoint, either restrict M5 to `n <= 5` explicitly or precompute coset tables for fixed `n`. Record the decision in `docs/research/first-bounded-search.md` before M5 begins.

### 7.2 Schema divergence (moderate-high)

The shared JSON schemas are the contract between Lean, Python, and any future external consumer. An unversioned breaking change to a schema forces a round of translation churn in both languages and invalidates every tracked fixture. **Mitigation:** M1 introduces a schema revision mechanism (migration notes in `docs/research/interchange-format.md`); every milestone touching a schema must add a migration note, and `make check` verifies all tracked fixtures still validate. No silent schema changes.

### 7.3 LP-backend trust (moderate-high)

Track A's trust boundary places the redundancy LP outside Lean. Without a Lean-checkable certificate format, the oracle's verdict is a provisional artifact (`lean_checkable = false`). A backend bug that returns a false redundancy claim would poison the retained-survivor corpus silently. **Mitigation:** M3 requires that every certificate carries backend name and version; M4 exercises the oracle on ground-truth non-Shannon inequalities before any novel search input; M5 keeps a `lean_checkable = false` disclaimer on every retained entry until a checkable format is designed (Section 9 extension). The `docs/research/trust-boundary.md` note documents this policy.

### 7.4 Search exhaust pollution (low-moderate)

A bounded enumeration over `CopyParameters` can still produce a large number of raw candidates before dedup. If the raw exhaust is tracked in git, the repo bloats and diffs become unreviewable. **Mitigation:** `.gitignore` excludes raw search output; only curated retained survivors under `data/fixtures/retained/` are tracked. M5's search driver writes raw exhaust to an untracked path; curation is a separate, explicit step. CI verifies that no `data/fixtures/retained/` entry exceeds a documented size budget.

### 7.5 Missing local transcriptions (low)

Track A cites Zhang-Yeung 1998 via the sibling project's verified transcription. If that transcription is moved, renamed, or rewritten, citations in Lean docstrings and in this roadmap go stale. **Mitigation:** M4 begins a local DFZ 2011 transcription; any Zhang-Yeung citation added after M4 must use either the sibling path with a verification date or a local copy at `references/transcriptions/zhangyeung1998.md`. Stale citations are caught by `make lint` only if they break Markdown or cspell; periodic manual review is required.

## 8. Verification Plan

**Milestone rule.** Every milestone M\<N\> for N >= 1 adds or updates at least one matching module under `NonShannonTest/` that imports only the public surface and proves `example`-level API regression checks. The test-parallel rule from `AGENTS.md` is mandatory; a milestone without its test module is not shipped.

**Build gate.** `make check` (which runs `make lint`, `make lean-lint`, `make build`, `make test`, `make py-test`) must stay green at every milestone closure. The aggregate `make check` is the shipping condition.

**Per-milestone test coverage.**

- **M0 (shipped):** `NonShannonTest/Prelude.lean`, `NonShannonTest/Inequality/{Vector,Canonical}.lean`, `NonShannonTest/Certificate/Schema.lean`, `NonShannonTest/CopyLemma/Parameters.lean`, `NonShannonTest/Catalog.lean`, `NonShannonTest/Examples/ZhangYeung.lean`; Python `tests/test_schema.py`, `tests/test_canonical.py`, `tests/test_emit_lean.py`.
- **M1:** extend `NonShannonTest/Inequality/Canonical.lean`; add `NonShannonTest/Inequality/Symmetry.lean` and `NonShannonTest/Inequality/Orbit.lean`. Python: extend `tests/test_canonical.py`; add `tests/test_symmetry.py`.
- **M2:** extend `NonShannonTest/CopyLemma/Parameters.lean`; add `NonShannonTest/CopyLemma/Parameterized.lean`.
- **M3:** extend `NonShannonTest/Certificate/Schema.lean`; add `NonShannonTest/Certificate/Oracle.lean`. Python: add `tests/test_redundancy_lp.py`.
- **M4:** add `NonShannonTest/Examples/DFZ.lean` and `NonShannonTest/Examples/Matus.lean`; extend `tests/test_canonical.py` with DFZ and Matús fixtures.
- **M5:** add `NonShannonTest/Examples/FirstSearchRetained.lean`; add `tests/test_search.py`.
- **M6:** extend `NonShannonTest/Catalog.lean`.

**CI.** The existing `ci.yml` runs two jobs: a Lean job (`lake lint` and `lake test` via `leanprover/lean-action`) and a Python job (`uv run ruff check .` and `uv run pytest`). `text-lint.yml` runs markdownlint-cli2 and cspell on every push. No additional CI work is required before M5; M5 may add a workflow step that runs the search driver on the fixed parameter subset used in `tests/test_search.py` to catch silent regressions.

## 9. Extensions (future work, post-release)

1. **Track B finite-group correspondence.** Chan and Yeung 2002 (IEEE TIT 48(7), pp. 1992-1995) establishes a correspondence between linear entropy inequalities on quasi-uniform distributions and linear inequalities on subgroup-index vectors of a finite group. Future work mines the correspondence with GAP integration. Requires GAP-to-Python bridge and a new trust-boundary analysis; explicitly deferred from this roadmap.
2. **Lean-checkable LP certificates.** M3 leaves `lean_checkable = false` as the default. A future milestone designs a certificate format that Lean can re-verify (for example: a dual LP certificate plus a Lean proof that the dual weights exhibit the required rational combination). This is a larger effort than M3's scope permits.
3. **Full DFZ catalog reproduction.** DFZ 2006 and DFZ 2011 together contain more than the six inequalities reproduced in M4. A future extension reproduces the full DFZ cone extreme rays for `n = 4`.
4. **Matús families to unbounded `n`.** Matús 2007 exhibits infinite families by induction on `n`. A future extension reproduces the induction in Lean and populates the catalog with one fixture per small `n`.
5. **Paper manuscript.** M6 produces a publishable-slice planning note; a future milestone writes the paper itself. Out of scope here.
6. **Local verified transcription of Zhang-Yeung 1998.** M4 introduces a local transcription for DFZ 2011 but not for Zhang-Yeung; future work produces a fully-local transcription of the primary paper anchor at `references/transcriptions/zhangyeung1998.md`.

## 10. Critical Files

### New (this project), grouped by milestone

**M0 (shipped):**

- `lakefile.toml`, `lean-toolchain`, `lake-manifest.json`
- `Makefile`, `bin/bootstrap-worktree`
- `NonShannon.lean`, `NonShannon/Prelude.lean`
- `NonShannon/Inequality/Subsets.lean`, `NonShannon/Inequality/Vector.lean`, `NonShannon/Inequality/Canonical.lean`
- `NonShannon/Certificate/Status.lean`, `NonShannon/Certificate/Schema.lean`
- `NonShannon/CopyLemma/Parameters.lean`, `NonShannon/CopyLemma/Parameterized.lean`
- `NonShannon/Catalog.lean`, `NonShannon/Examples/ZhangYeung.lean`
- `NonShannonTest.lean`, `NonShannonTest/Prelude.lean`, plus every mirror file under `NonShannonTest/`
- `pyproject.toml`, `uv.lock`, `src/non_shannon_search/{__init__,cli,schema,canonical,redundancy_lp,emit_lean}.py`
- `tests/{test_schema,test_canonical,test_emit_lean}.py`
- `schemas/{candidate-inequality,redundancy-certificate}.schema.json`
- `data/fixtures/zhang-yeung.json`
- `docs/research/{track-a-architecture,interchange-format,trust-boundary}.md`
- `references/README.md`, `references/papers.bib`
- `.github/workflows/{ci,text-lint}.yml`, community files

**M1:**

- New: `NonShannon/Inequality/Symmetry.lean`, `NonShannonTest/Inequality/Symmetry.lean`, `NonShannonTest/Inequality/Orbit.lean`, `src/non_shannon_search/symmetry.py`, `tests/test_symmetry.py`.
- Updated: `NonShannon/Inequality/Canonical.lean`, `NonShannon/Inequality/Vector.lean`, `NonShannon/Inequality/Subsets.lean`, `NonShannon/Certificate/Schema.lean`, `NonShannonTest/Inequality/Canonical.lean`, `NonShannonTest/Inequality/Vector.lean`, `src/non_shannon_search/canonical.py`, `tests/test_canonical.py`, possibly `schemas/candidate-inequality.schema.json` with a matching migration note in `docs/research/interchange-format.md`.

**M2:**

- New: `NonShannonTest/CopyLemma/Parameterized.lean`, `docs/research/copy-lemma-naming.md`.
- Updated: `NonShannon/CopyLemma/Parameterized.lean`, `NonShannon/CopyLemma/Parameters.lean`, `NonShannonTest/CopyLemma/Parameters.lean`.

**M3:**

- New: `NonShannon/Certificate/Oracle.lean`, `NonShannonTest/Certificate/Oracle.lean`, `tests/test_redundancy_lp.py`.
- Updated: `NonShannon/Certificate/Schema.lean`, `NonShannonTest/Certificate/Schema.lean`, `src/non_shannon_search/redundancy_lp.py`, `docs/research/trust-boundary.md`.

**M4:**

- New: `NonShannon/Examples/DFZ.lean`, `NonShannon/Examples/Matus.lean`, `NonShannonTest/Examples/DFZ.lean`, `NonShannonTest/Examples/Matus.lean`, `data/fixtures/dfz-*.json`, `data/fixtures/matus-*.json`, `references/transcriptions/doughertyfreilingzeger2011.md`.
- Updated: `tests/test_canonical.py`, `NonShannon.lean`, `NonShannonTest.lean`.

**M5:**

- New: `src/non_shannon_search/search.py`, `tests/test_search.py`, `NonShannonTest/Examples/FirstSearchRetained.lean`, `data/fixtures/retained/*.json`, `docs/research/first-bounded-search.md`.
- Updated: `.gitignore` (exclusions for raw search exhaust), possibly `.github/workflows/ci.yml`.

**M6:**

- New: `docs/research/catalog-naming.md`, `docs/research/publishable-slice.md`.
- Updated: `NonShannon/Catalog.lean`, `NonShannonTest/Catalog.lean`.

### External (depend on, do not modify)

- `PFR` package (`teorth/pfr`, rev `80daaf1`): `PFR.ForMathlib.Entropy.Basic` for `H`, `H[· | ·]`, `I[· : ·]`, `I[· : · | ·]`.
- `Mathlib` (pulled via PFR, rev `507f18f`): `Mathlib.MeasureTheory.*`, `Mathlib.Probability.*`, `Mathlib.Data.List.Basic`, `Mathlib.Data.Rat.Defs`, `Mathlib.GroupTheory.Perm.*` (for M1's `Equiv.Perm` action).
- `batteries` (via Mathlib): `batteries/runLinter` as `lintDriver`.
- `jsonschema` (Python, via `uv`): schema validation in `src/non_shannon_search/schema.py`.
- `ruff`, `pytest`, `jsonschema` (Python dev dependencies via `uv`).
- Sibling project `cboone/zhang-yeung-inequality`: verified transcription of Zhang-Yeung 1998 at `~/Development/zhang-yeung-inequality/references/transcriptions/zhangyeung1998.md` (verified 2026-04-16), cited until a local copy lands (Section 9, Extension 6).
