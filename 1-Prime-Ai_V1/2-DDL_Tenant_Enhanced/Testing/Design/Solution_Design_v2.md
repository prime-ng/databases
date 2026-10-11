# Prime-AI Testing Application — Solution Design

**Document ID:** TSTAPP-SD-V2
**Version:** 2.0
**Supersedes:** `Solution_Design_v1.md` (v1.0 — "Requirement Detail & Functional Specification")
**Governed by:** `TestingApp_BRD_v2.md` (v2.0)
**Realised by:** `testing_DDL_v7.0.sql` (v7.0)
**Status:** Draft for Technical Review
**Date:** 2026-09-04

---

## 0. Document Control

### 0.1 Purpose and Position

`Solution_Design_v1.md` was written as a *functional specification with architectural suggestions appended*. It ended with 20 questions and 20 suggestions, and it described a data model that the DDL had already diverged from.

This document is different in kind. It is the **solution design**: it decides. Every open item in v1 is either resolved here or listed in §19 as an explicit, owned, dated decision. Every business rule in the BRD is traced to a component, a table and a screen.

| Layer | Document | Answers |
|---|---|---|
| Business | `TestingApp_BRD_v2.md` | What does the business need, and why |
| **Solution** | **This document** | How does the system work, and how is it built |
| Physical | `testing_DDL_v7.0.sql` | How is the information stored |

### 0.2 What Changed From v1

| # | Change | Reason |
|---|---|---|
| S-01 | **Resolved the identity model.** Internal relationships use surrogate keys; business identity uses codes; distributed identity uses (machine, source id). All three, each in its own place | v1 AS-002/AS-003/AS-004 raised the problem; v6.7 propagated the composite key into every child table instead |
| S-02 | **Resolved canonical vs source test case** with a two-layer model and an authoring mode | v1 §7–8 described the problem; the DDL implemented only one of the two layers |
| S-03 | **Specified the algorithms.** Flakiness, regression, impact selection, failure signatures, deduplication and confidence are defined as computable procedures, not aspirations | v1 described outcomes without method |
| S-04 | **Specified the sync protocol** — bundle format, manifest, ordering, idempotency, conflict classes, reversal | v1 stated the requirement; the mechanism was undefined |
| S-05 | **Added the application architecture** — layers, modules, services, jobs, queues, storage | v1 had none |
| S-06 | **Added the screen inventory** with role access | v1 had none |
| S-07 | **Added manual test execution** including steps and per-step results | Missing entirely from v1 and v6.7 |
| S-08 | **Added environment as a computed profile** with a fingerprint | v1 §33 wanted it; v6.7 stored free JSON |
| S-09 | **Corrected 11 defects found in `testing_DDL_v6.7.sql`** (§16.1) | Several prevent the script from executing at all |
| S-10 | **Added NFRs, sizing, indexing and archival strategy** | v1 had none; BC-14 makes them mandatory |
| S-11 | **Added the v6.7 → v7.0 migration plan** | Required to move without losing existing work |

---

## 1. Solution Overview

### 1.1 In one paragraph

The Prime-AI Testing Application is a **Laravel 12 / MySQL 8 application installed locally on each developer and tester machine, plus one central installation**. Each installation holds a complete schema. Catalog data (modules, screens, canonical test cases, suites, requirements, masters, users, machines) is **governed centrally and distributed outward as version-stamped bundles**. Evidence data (runs, results, bugs, occurrences, retests, notes, audit) is **produced locally and consolidated inward as export bundles**. The application discovers automated tests from the Prime-AI source tree, executes them, records every attempt with its evidence, correlates failures with Git changes, groups recurring failures by signature, manages the defect lifecycle through verified retest, and proposes — for human approval — which tests a given change requires.

### 1.2 Context

```
        ┌──────────────────────────────────────────────────────────────┐
        │                     PRIME-AI SOURCE TREE                     │
        │       Modules/*  ·  tests/Browser/*  ·  .git history         │
        └───────────────┬──────────────────────────┬───────────────────┘
                        │ discovery                │ git log / diff
                        ▼                          ▼
        ┌──────────────────────────────────────────────────────────────┐
        │            TESTING APPLICATION  (local installation)         │
        │                                                              │
        │  Catalog   Execution   Evidence   Defects   Analysis   Sync  │
        │                                                              │
        │  MySQL 8 (prime_testing)      Evidence store (filesystem)    │
        └───────────────┬──────────────────────────▲───────────────────┘
                        │ export bundle            │ catalog bundle
                        ▼                          │
        ┌──────────────────────────────────────────┴───────────────────┐
        │           TESTING APPLICATION  (central installation)        │
        │   Consolidated evidence · Catalog governance · Reporting     │
        └──────────────────────────────────────────────────────────────┘
```

### 1.3 Design tenets

| # | Tenet | Consequence in the design |
|---|---|---|
| T-01 | Recorded evidence is the only truth | Every summary, score and status is derived and rebuildable (§8.7) |
| T-02 | Append, never overwrite | Results, occurrences, versions, transitions and audit are insert-only |
| T-03 | Three identities, three jobs | Surrogate for joins, code for business, (machine, source id) for distribution (§3) |
| T-04 | Catalog out, evidence in | The sync protocol has two distinct directions with different rules (§12) |
| T-05 | Propose, don't assert | Every derived conclusion carries evidence, confidence and a review state |
| T-06 | Fail loudly on ambiguity | Conflicts queue; they are never resolved by a coin toss |
| T-07 | Explainable by construction | Every conclusion stores its inputs at the moment it was reached |
| T-08 | Local autonomy | No feature except consolidation may require the central installation |

---

## 2. Architecture

### 2.1 Technology

| Concern | Choice | Note |
|---|---|---|
| Runtime | PHP 8.3+, Laravel 12 | Matches the Prime-AI stack; the team already knows it |
| Database | MySQL 8.0, InnoDB, utf8mb4 | As per `testing_DDL_v7.0.sql` |
| Modularity | `nwidart/laravel-modules` | Same convention as Prime-AI |
| UI | Blade + AdminLTE + Alpine.js; Vue 3 for the run monitor and canvas-like grids | Matches Prime-AI; avoids a second front-end stack |
| Background work | Laravel queues (database driver locally, Redis centrally) | No external broker required on a laptop |
| Scheduling | Laravel scheduler via OS cron/Task Scheduler | With missed-run detection (§9.6) |
| Test execution | Laravel Dusk, PHPUnit/Pest, invoked as supervised child processes | Streamed output, heartbeat, timeout |
| Git access | `git` CLI invoked read-only against a configured repository path | No write access to Prime-AI, ever |
| Evidence store | Local filesystem under a configured root, content-addressed | Database stores metadata and path only |
| Export bundle | Zip: `manifest.json` + NDJSON per entity + artefacts | Streamable, diffable, checksummable |
| AI | Claude (Anthropic API) behind a single provider interface | Latest Claude models; never given tenant data (BR-AI-08) |
| Auth | Laravel session auth, role + permission checks in policies | Single-user-per-installation is common but not assumed |

### 2.2 Application modules

| Module | Responsibility | Principal tables |
|---|---|---|
| `Core` | Users, roles, permissions, machines, settings, audit, schema version | `tst_users`, `tst_roles`, `tst_permissions`, `tst_machines`, `tst_app_settings`, `tst_audit_logs`, `tst_schema_version` |
| `Catalog` | Modules → screens, test cases, steps, versions, tags, masters | `tst_modules` … `tst_test_cases`, `tst_test_case_steps`, `tst_test_case_versions` |
| `Discovery` | Source-tree scan, reconciliation, orphan detection | `tst_discovery_sync_logs` |
| `Requirements` | Application requirements, coverage mapping, work-request backlog | `tst_app_requirements`, `tst_app_requirement_test_cases`, `tst_test_case_requirements` |
| `Suites` | Suites, membership, rule-based suites, suite versions | `tst_test_suites`, `tst_test_suite_items`, `tst_test_suite_versions` |
| `Execution` | Run orchestration, adapters, heartbeat, results, artefacts | `tst_test_runs`, `tst_test_run_items`, `tst_test_run_results`, `tst_run_result_artifacts` |
| `Evidence` | Artefact storage, hashing, lifecycle, expiry | `tst_run_result_artifacts` |
| `Defects` | Bugs, occurrences, links, comments, status history, known issues, retest cycles | `tst_bugs`, `tst_bug_occurrences`, `tst_known_issues`, `tst_retest_cycles` |
| `Change` | Git ingest, path mapping, commit-to-screen resolution | `tst_git_repositories`, `tst_git_commits`, `tst_git_commit_files`, `tst_path_mappings` |
| `Impact` | Impact analysis, test selection, approval | `tst_impact_analyses`, `tst_impact_analysis_items` |
| `Analytics` | Summaries, flakiness, regression, confidence, health, debt | `tst_test_case_runs_summary`, `tst_failure_signatures` |
| `Releases` | Releases, scope, readiness assessment | `tst_releases` |
| `Sync` | Export, import, conflict handling, record mapping, catalog bundles | `tst_data_exports`, `tst_data_imports`, `tst_import_conflicts`, `tst_import_record_map` |
| `Insights` | AI analyses and recommendations with review states | `tst_ai_analyses`, `tst_ai_recommendations` |
| `Notify` | Notification generation, deduplication, delivery, digests | `tst_notifications` |
| `Reporting` | Views, dashboards, exports, saved searches | Database views `vw_*` |

### 2.3 Layering

```
 HTTP / Console
      │
 Controllers · Commands · Jobs        ← thin; no business logic
      │
 Services                             ← all business logic; the only writers
      │
 Repositories / Query objects         ← reads, including view-backed reads
      │
 Eloquent models  ·  Database views   ← persistence
```

**Rules enforced in review:**
1. Controllers never touch Eloquent directly.
2. Only services write. A service method is one business transaction.
3. Derived tables are written only by their own recompute service (§8.7) — never inline.
4. Every service that writes evidence records audit in the same transaction.
5. Every long operation is a queued job with progress, cancellability and a heartbeat.

### 2.4 Deployment topologies

| Topology | Setting | Behaviour |
|---|---|---|
| **Local** | `central_mode = false` | Full function. Catalog read-mostly (applied from bundles). Export enabled, import limited to catalog bundles |
| **Central** | `central_mode = true` | Full function plus: catalog authoring, evidence import, conflict resolution, cross-machine analysis, catalog bundle publishing |

A single-machine team may run one installation in Central mode and nothing else. Every feature except consolidation works identically in both.

---

## 3. The Identity Model

This is the most consequential part of the design, and the part v1 and v6.7 disagreed about. It is settled here.

### 3.1 Three identities, each with one job

| Identity | Form | Used for | Example |
|---|---|---|---|
| **Surrogate key** | `BIGINT/INT AUTO_INCREMENT` | Internal relationships and joins, within one database | `tst_test_cases.id = 4211` |
| **Business code** | Human-meaningful stable string | Cross-machine recognition of the same catalog entity; display; import matching | `ts_code = 'FIN-INV-01'`, `test_case_code = 7` |
| **Distributed identity** | `(machine_id, source_*_id)` | Recognising the same *transaction* record after it moves between databases | `(machine 3, run 118)` |

**None of the three is a substitute for the others.** v6.7's error was using the business code as the foreign key everywhere, which is correct for recognition and wrong for storage.

### 3.2 The rule

> **Child tables join by surrogate key. Catalog tables carry a UNIQUE business code. Transaction tables carry a UNIQUE (machine_id, source_id). Import resolves business codes to local surrogate keys once, at the boundary, and records the mapping.**

Concretely:

```
tst_test_cases
    id                      ← surrogate, used by every child FK
    ts_code, test_case_code ← UNIQUE business identity, used by import and display

tst_test_run_items
    test_case_id            ← FK to tst_test_cases.id     (join path)
    display_name_snapshot   ← what it was called then     (history path)

tst_test_runs
    id                      ← surrogate
    machine_id, source_run_id ← UNIQUE distributed identity
```

### 3.3 Why this matters at Prime-AI's scale

At 100,000 test cases and, say, 20 million results, the composite key `(VARCHAR(20), SMALLINT)` costs 22 bytes in every secondary index entry of every child table, against 4 bytes for an `INT` surrogate. On the four largest tables that is the difference between indexes that fit in the buffer pool and indexes that do not. It also removes the multi-column `ON DELETE SET NULL` foreign keys in v6.7 that MySQL handles poorly and that produced one outright schema defect (§16.1, item 6).

### 3.4 What is *not* changed

The business identity **remains** `(ts_code, test_case_code)`. It is still `UNIQUE`. It is still what import matches on, what a user sees, and what an export bundle carries. Only the *internal foreign keys* change. Every guarantee in the BRD is preserved.

### 3.5 Machine identity provisioning

1. An administrator registers a machine centrally, producing `machine_id`, `machine_code` and a registration token.
2. The local installation is configured with that identity, persisted in `.env` plus a signed `machine.json`.
3. The local `tst_machines` row is inserted **with an explicit id** — never allowed to auto-increment.
4. A `machine_fingerprint` (hash of hostname + OS + hardware serial + install path) is recorded and re-checked at boot.
5. On fingerprint mismatch the application **refuses to record new runs** and raises an administrative alert. Re-imaged hardware is registered as a new machine (BR-MACHINE-05, AC-MACHINE-02).
6. `machine_id = 1` is reserved for the central installation; local ids start at 10.

### 3.6 Source run identity

On a local installation, `source_run_id` is assigned from a per-machine monotonic counter and, in practice, equals the local `id`. On import, the central installation assigns a fresh `id` and preserves `(machine_id, source_run_id)` — whose `UNIQUE` constraint is what makes re-import a no-op.

---

## 4. The Test Case Model

### 4.1 The two layers

```
                    ┌───────────────────────────────┐
                    │   tst_test_cases (canonical)  │   centrally governed
                    │   UNIQUE (ts_code, tc_code)   │   counted for coverage
                    └───────────────▲───────────────┘
                                    │ canonical_test_case_id  (nullable)
                    ┌───────────────┴───────────────┐
                    │  tst_source_test_cases        │   machine-authored
                    │  UNIQUE (machine, author,     │   never auto-merged
                    │          ts_code, local no.)  │
                    └───────────────────────────────┘
```

`tst_source_test_cases.link_status` ∈ `Unmapped · Proposed_Same · Confirmed_Same · Confirmed_Different · Promoted · Superseded`, with `link_decided_by`, `link_decided_at`, `link_evidence_json`.

### 4.2 Authoring modes

| Mode (`test_case_authoring_mode`) | Behaviour | When |
|---|---|---|
| `Central_Catalog` *(default, D-01)* | Test cases are created directly in `tst_test_cases`. Numbers are issued by the central installation in blocks. The source layer is used only for offline authoring and for reconciling imports | Normal operation |
| `Local_Then_Promote` | Every machine writes to `tst_source_test_cases`. Nothing is canonical until a QA Lead promotes it | Distributed teams with weak catalog governance |

Number issuance in Central Catalog mode: the central installation allocates each machine a **block** of `test_case_code` values per screen (default 100). Local creation consumes from the block. Exhausting a block requires a new allocation, or falls back to the source layer. This eliminates the collision case for the normal workflow while keeping the source layer as the safety net.

### 4.3 Equivalence resolution

1. **Detect.** On import, and nightly, compare unmapped source test cases against canonical test cases on the same screen: exact `definition_hash` match; then class+method match; then normalised display-name similarity; then step-sequence similarity for manual tests.
2. **Propose.** Write `tst_test_case_links` rows with `link_type = 'Proposed_Equivalent'`, a score and an evidence payload.
3. **Review.** The proposal appears in a review queue (E-13). A QA Lead confirms Same, Different, or Duplicate.
4. **Apply.** `Confirmed_Same` sets `canonical_test_case_id`; history from that source is thereafter analysed under the canonical test case while `origin_machine_id` and `author_user_code` remain on every record.
5. **Reverse.** A confirmation may be reversed. The reversal writes a new link row; the original is retained with `superseded_at`. Nothing is deleted (BR-TC-IND-05).

### 4.4 Test case versioning

`definition_hash = sha256(normalised(class, method, display_name, description, type, layer, technology, ordered steps, expected results))`.

On save, if the hash differs from the current row's hash, `version_no` increments and the **previous** definition is written to `tst_test_case_versions`. Every `tst_test_run_item` snapshots `test_case_version_no`, `display_name_snapshot` and `file_path_snapshot` at selection time, so a historical result renders as it was (BR-VERSION-03, AC-VER-01).

### 4.5 Manual test steps

`tst_test_case_steps` — ordered `(test_case_id, step_no)`, with `action`, `expected_result`, `test_data_note`, `is_optional`.
`tst_test_run_result_steps` — per attempt, per step: `status` (Passed / Failed / Blocked / Skipped / Not_Executed), `actual_result`, `note`.

**Consistency rule (BR-STEP-04):** the service refuses to save a result of `Passed` when any non-optional step is `Failed`, unless the tester supplies an explanatory note, which is stored on the result.

**Step versioning:** steps participate in `definition_hash`, so editing steps produces a new test case version and historical executions continue to render the steps that were current when they ran.

---

## 5. The Application Catalog

### 5.1 Hierarchy and integrity

`Module → Category → Main Menu → Sub Menu (optional) → Screen → Test Case`

Each level carries a globally unique business code. **v7.0 adds composite foreign keys** so that a child cannot belong to a parent in a different branch — a real integrity hole in v6.7, where a main menu could reference a category belonging to a different module (§16.1, item 5).

```
tst_categories   UNIQUE (module_code, cat_code)
tst_main_menus   FK (module_code, cat_code)        → tst_categories
tst_sub_menus    FK (module_code, cat_code, mm_code) → tst_main_menus
tst_tabs_screens FK (module_code, cat_code, mm_code) → tst_main_menus
                 FK (module_code, cat_code, mm_code, sm_code) → tst_sub_menus  (when sm_code present)
```

### 5.2 Screen readiness pipeline

Restored from v6.5 and extended, because it maps directly onto the team's existing two-stage test authoring process (requirement document → test specification → implemented test):

| Column | Meaning |
|---|---|
| `requirements_md_path`, `requir_doc_status` | The screen's requirement document and its state |
| `tc_list_md_path`, `tc_list_status` | The screen's test specification ("TcList") and its state |
| `dev_status` | Development readiness of the screen itself |
| `tc_creation_status` | Whether test cases have been authored |
| `test_run_status` | Whether they have been executed |
| `is_excluded`, `exclusion_reason` | Out of testing scope, with a stated reason (BR-STRUCT-05) |

This makes the screen the unit of work for the whole authoring pipeline, and makes "how far along is module X?" answerable directly from the catalog.

### 5.3 Reference masters

Five master tables (`type`, `method`, `technology`, `layer`, `status`) keyed by code, plus `tst_tags` for free classification (BR-TC-07). v6.5's generic `tst_common_dropdown_master` is deliberately not carried forward: dedicated masters allow real foreign keys, which a generic key-value master cannot. A small `tst_master_registry` records which master feeds which UI field, so the UI keeps the generic-dropdown convenience without losing referential integrity.

### 5.4 Discovery

```
Scan configured Prime-AI root
  → Modules/*                              → candidate modules
  → tests/Browser/**/*Test.php             → candidate test files
  → reflect classes and #[Test] methods    → candidate test cases
  → parse @screen / @ts-code annotations   → screen association
  → resolve path via tst_path_mappings     → module and screen fallback
  → compute definition_hash per method
```

Reconciliation, per discovered item:

| Situation | Action |
|---|---|
| Not in catalog | Create as `is_discovered = 1`, `status = Draft`, queued for confirmation |
| In catalog, hash equal | No change; touch `last_seen_at` |
| In catalog, hash differs | New version; flag `Needs_Update`; **never** overwrite human-edited display names without approval (BR-DISC-02) |
| In catalog, absent from source | Mark `is_orphaned = 1`; **never delete** (BR-DISC-06) |
| Previously orphaned, reappears | Clear the orphan flag; record the reappearance |

Every scan writes one `tst_discovery_sync_logs` row with counts, the commit hash scanned, duration and per-item detail. Re-running with no source change produces a log with zero changes (AC-DISC-01).

---

## 6. Test Execution

### 6.1 Run composition

```
tst_test_runs        one execution event: trigger, scope, environment, code version, actor
  ├─ tst_test_run_scopes   why this run exists (module / screen / bug / commit / suite / release)
  ├─ tst_test_run_items    which test cases, and why each was selected
  │    └─ tst_test_run_results     one row per attempt
  │           ├─ tst_test_run_result_steps    manual step outcomes
  │           └─ tst_run_result_artifacts     evidence
  └─ tst_run_annotations   human notes
```

### 6.2 Execution adapters

One interface, several implementations, so that new technologies do not change the orchestrator:

| Adapter | Executes | Result source |
|---|---|---|
| `DuskAdapter` | `php artisan dusk --filter=...` | JUnit XML + Dusk screenshots and console logs |
| `PestAdapter` / `PhpUnitAdapter` | `php artisan test --filter=...` | JUnit XML |
| `ManualAdapter` | Nothing — presents the guided runner | Human input per step |
| `ExternalAdapter` | Nothing — accepts a posted payload | CI webhook (E-22) |

Each adapter returns a normalised result set: status, duration, assertions, message, trace, artefact paths.

### 6.3 Run lifecycle and interruption

```
Queued ──► Running ──► Completed
              │
              ├──► Failed        (the harness itself failed)
              ├──► Cancelled     (a person stopped it)
              ├──► Interrupted   (heartbeat stopped)
              └──► Timed_Out     (exceeded max_run_duration_minutes)
```

- The runner writes `heartbeat_at` every 15 seconds and holds a `lock_token`.
- A watchdog (scheduled, and also on application boot) moves any `Running` run whose `heartbeat_at` is older than `run_heartbeat_timeout_seconds` (default 180) to `Interrupted`, retaining all results already recorded.
- Cancellation sets a cancel flag the runner observes at the next test boundary; results already produced are retained (BR-EXEC-09).
- This closes v1 FR-067 and BRD BR-EXEC-07, which v6.7 could not express — its status enum had no `Interrupted` and no heartbeat.

### 6.4 Attempts, retries and finality

- `tst_test_run_results` is unique on `(run_item_id, attempt_no)`.
- Automatic in-run retry (`auto_retry_on_failure`, default 0) increments `attempt_no`.
- Exactly one attempt per run item carries `is_final_attempt = 1`; the service maintains it inside the same transaction.
- Rolled-up run counters (`passed_tc_count` and so on) count **final attempts only**, and are recomputed from results rather than incremented ad hoc, so they cannot drift.

### 6.5 Concurrency

- Run creation takes the machine's source-run counter under a row lock, so two simultaneous runs cannot claim the same `source_run_id`.
- `max_concurrent_runs_per_machine` (default 1 for browser tests, configurable) is enforced at queue admission.
- Browser-based adapters additionally take a named lock, since two Dusk processes on one display interfere.

### 6.6 Evidence

- Artefacts are written to `{evidence_root}/{yyyy}/{mm}/{machine}/{run}/{result}/…` and hashed with SHA-256.
- Identical artefacts across results are stored once and referenced by hash.
- `tst_run_result_artifacts` records `artifact_type`, `path`, `sha256`, `bytes`, `mime`, `is_available`, `expires_at`.
- Purging clears the file and sets `is_available = 0` — so a result shows *evidence expired* rather than appearing never to have had any (BR-EVID-03, AC-RES-03).
- v6.7's three fixed columns (`screenshot_path`, `console_log_path`, `source_html_path`) become a table, because video, HAR files, network logs and per-step screenshots do not fit three columns.

---

## 7. Change Traceability and Impact Analysis

### 7.1 Git ingest

```
tst_git_repositories   registered repository: code, path, remote, default branch
tst_git_commits        commit hash, branch, author, message, merge flag, committed_at
tst_git_commit_files   file path, change type, resolved module and screen, impact level
```

Ingest runs on demand and on a schedule: `git log --numstat` since the last ingested commit, resolving each file path through `tst_path_mappings`.

### 7.2 Path mapping — the missing piece

v6.7 stored `module_code` and `ts_code` directly on each changed file with no rule for how they got there. In practice nobody hand-maps thousands of files. v7.0 adds:

```
tst_path_mappings
    pattern         'Modules/Fees/**'          glob, evaluated most-specific first
    target_type     Module | Screen | TestCase | Ignore
    module_code / ts_code / test_case_id
    confidence      how strongly a match implies impact
    priority        tie-break
```

Resolution order for a changed file: exact test-case file path → screen route/folder path → path mapping rule → module folder convention → unresolved (queued for a rule to be added). Unresolved paths are reported, because an unresolved path is a blind spot in impact analysis.

### 7.3 Impact analysis as a reviewable artefact

```
tst_impact_analyses        the proposal: source (commit range / bug / release / manual), status, actor, totals
tst_impact_analysis_items  one proposed test case: reason, confidence, evidence, include/exclude, decided_by
```

Selection algorithm:

```
INPUT: a set of changed files (from a commit range, a bug's fix commit, or a release scope)

1. DIRECT
   changed file resolves to a test case            → reason Direct_Change      confidence 1.00
   changed file resolves to a screen               → every active test case on that screen
                                                    → reason Direct_Change      confidence 0.90
   changed file resolves to a module only          → critical + high test cases of that module
                                                    → reason Direct_Change      confidence 0.60

2. DEPENDENCY  (breadth-first, max depth = impact_max_depth, default 2)
   modules depending on an affected module         → reason Dependency
       confidence = 0.70 × (impact_weight / 10) ^ depth
   test cases depending on an affected test case   → reason Dependency        same decay

3. HISTORY
   test cases that have previously failed on a commit touching any affected file
                                                   → reason Historical_Correlation
       confidence = min(0.85, 0.40 + 0.10 × prior_correlated_failures)

4. DEFECT
   test cases with an open bug on an affected screen → reason Open_Bug         confidence 0.75

5. POLICY
   all Critical test cases of every affected module → reason Critical          confidence 1.00
   suite named by regression_policy_suite           → reason Regression_Policy confidence 1.00

6. EXCLUDE
   confirmed flaky and unconfirmed                  → excluded, reason Flaky_Excluded
   retired / orphaned / excluded screen             → excluded, with reason

7. RANK by confidence desc, criticality desc, last_run_at asc
   Retain excluded items with their reason, so the proposal can state what it left out (BR-IMPACT-06)
```

The proposal is reviewed, edited and approved by a QA Lead or Architect, then executed as a run that keeps `impact_analysis_id`. After the run, defects found outside the proposed scope are counted against **K-05 impact hit rate**, which is how the algorithm's parameters get tuned by evidence rather than by opinion.

---

## 8. Analysis

Every algorithm below is defined so that two people computing it by hand would agree, and every conclusion stores the evidence it used (T-07).

### 8.1 Failure signature

```
signature_input =
    normalise(exception_class)
  + '|' + normalise(error_message)      strip numbers, ids, timestamps, paths, hex
  + '|' + top_3_application_frames(trace)     Prime-AI frames only, vendor frames dropped
  + '|' + assertion_kind

failure_fingerprint = sha256(signature_input)
```

`tst_failure_signatures` holds one row per fingerprint: first seen, last seen, occurrence count, distinct test cases affected, distinct machines affected, and the linked bug or known issue if any. New failures matching an existing signature are proposed as occurrences of the existing bug rather than as new bugs (BR-BUG-OCC-03).

### 8.2 Flakiness (BRD D-11)

```
Over the last flaky_window_runs (default 10) final attempts of one test case,
restricted to one environment profile:

  alternations = count of adjacent pairs where outcome class differs
                 (Passed) vs (Failed | Error)

  flaky_score  = alternations / (window_size - 1)

  is_flaky_candidate = alternations >= flaky_min_alternations (default 2)
                   AND no test-case version change within the window
                   AND no commit touching the covered screen within the window

  Confirmed flaky only by a person, or by candidacy persisting for
  flaky_auto_confirm_days (default 14) — recorded either way.
```

`flaky_evidence_json` stores the run ids, outcomes, environment profile and the change check, so the conclusion can be re-read a year later (BR-FLAKY-04, AC-FLAKY-01). Five consecutive failures give zero alternations and are therefore never flaky (AC-FLAKY-02).

### 8.3 Regression (BRD D-12)

```
A final attempt with status Failed or Error is a regression candidate when:

  1. the same test case has at least one Passed result within regression_lookback_days (default 30)
  2. the most recent prior final attempt was Passed
  3. it is not confirmed flaky
  4. it is not attributed to an active known issue
  5. its environment profile is comparable to the last passing run
     (same OS family, same browser major version) — otherwise it is
     classified Environment_Divergent rather than Regression

Attribution:
  candidate_commits = commits between the last passing run's commit and this run's commit
                      that touch files resolving to this test case's screen or module
  confidence = 1.00 single candidate commit
             = 0.70 several candidates, one touching the screen directly
             = 0.40 several candidates, module-level only
             = 0.20 no candidate commits (suspect environment or data)
```

### 8.4 Test confidence (E-01)

```
confidence = 0.35 × recent_pass_rate(30d)
           + 0.20 × min(1, executions(90d) / 10)
           + 0.20 × (1 - flaky_score)
           + 0.15 × recency_factor(last_run_at)        1.0 ≤7d, 0.6 ≤30d, 0.3 ≤90d, 0.1 older
           + 0.10 × environment_breadth                distinct env profiles / 3, capped at 1

reported as 0–100, with the component breakdown stored for the explanation panel (E-26)
```

### 8.5 Test health (E-02)

| Health | Condition (evaluated in order) |
|---|---|
| `Orphaned` | Implementation absent from the source tree |
| `Insufficient_History` | Fewer than 3 executions |
| `Blocked` | Last outcome Blocked, twice consecutively |
| `Frequently_Failing` | Pass rate over 30 days < 50% and not flaky |
| `Unstable` | Confirmed or candidate flaky |
| `Obsolete` | Not executed in `stale_test_days` (default 90) and its screen is retired or excluded |
| `Under_Investigation` | An open bug is linked to it |
| `Healthy` | Everything else |

### 8.6 Bug deduplication

```
score = 0.45 × (failure_fingerprint equal ? 1 : 0)
      + 0.20 × (same test case ? 1 : same screen ? 0.6 : same module ? 0.3 : 0)
      + 0.20 × title/description similarity  (trigram)
      + 0.15 × (open bug in the same area within 14 days ? 1 : 0)

score ≥ 0.80  → propose duplicate, pre-selected in the review queue
0.50–0.79     → propose as related
< 0.50        → no proposal

Never applied automatically (BR-BUG-DUP-02).
```

### 8.7 Derived data — the rebuild guarantee

`tst_test_case_runs_summary`, `tst_failure_signatures` counters, confidence, health and flakiness are **derived**. Each has:

1. an **incremental** updater invoked after each run completes, and
2. a **full rebuild** command (`php artisan tst:rebuild-analytics`) that truncates and recomputes from `tst_test_run_results` alone.

CI runs a nightly consistency check comparing incremental against rebuilt values and raises a discrepancy notification if they differ. This is BRD R-13 and BR-HISTORY-05 made operational, and it is why a corrupted summary is an inconvenience rather than a data loss.

---

## 9. Functional Specification by Area

### 9.1 Screen inventory

| # | Screen | Purpose | Roles |
|---|---|---|---|
| 1 | Dashboard | Quality overview, my work, alerts | All |
| 2 | Executive Dashboard | Trend, coverage, debt, release readiness | Lead, QA Lead, Mgmt |
| 3 | Users | User CRUD, roles, activation | Admin |
| 4 | Roles & Permissions | Role matrix | Admin |
| 5 | Machines | Registration, fingerprint, last seen | Admin |
| 6 | Settings | System and local settings | Admin |
| 7 | Modules / Categories / Menus | Catalog maintenance | Architect, Admin |
| 8 | Screens | Screen list, readiness pipeline, exclusion | Architect, QA Lead |
| 9 | Screen Detail | Test cases, coverage, bugs, history for one screen | All |
| 10 | Test Cases | Catalog list with filters and bulk actions | All (edit by role) |
| 11 | Test Case Detail | Definition, steps, versions, dependencies, requirements, history, bugs | All |
| 12 | Test Case Editor | Create/edit including manual steps | QA Lead, Tester, Architect |
| 13 | Source Test Cases | Unmapped machine-authored test cases | QA Lead |
| 14 | Discovery | Run a scan, review results, confirm items | Architect, QA Lead |
| 15 | Suites | Suite CRUD, membership, rules | QA Lead, Architect |
| 16 | Requirements | Application requirements and coverage | BA, QA Lead |
| 17 | Traceability Matrix | Requirement × test × result × bug | BA, QA Lead, Mgmt |
| 18 | Work Requests | Test-case backlog | QA Lead, Tester |
| 19 | Execute | Choose scope, environment, options; start a run | Tester, Developer |
| 20 | Run Monitor | Live progress, streamed output, cancel | Tester, Developer |
| 21 | Manual Runner | Guided step-by-step manual execution | Tester |
| 22 | Runs | Run history with filters | All |
| 23 | Run Detail | Items, results, evidence, notes, scope, selection reasons | All |
| 24 | Result Detail | One attempt: evidence, steps, signature, related bugs | All |
| 25 | Triage Queue | Unclassified failures with proposals | QA Lead, Tester |
| 26 | Bugs | Bug list with filters | All |
| 27 | Bug Detail | Lifecycle, occurrences, links, comments, retests | All (edit by role) |
| 28 | Known Issues | Register with review dates | QA Lead |
| 29 | Retest Cycles | Cycle status and outcomes | QA Lead, Tester |
| 30 | Flaky Tests | Candidates and confirmed, with evidence | QA Lead |
| 31 | Regression Candidates | With attributed commits | QA Lead, Developer |
| 32 | Testing Debt | The debt register | QA Lead, Lead |
| 33 | Commits | Ingested commits and resolved files | Developer, Architect |
| 34 | Path Mappings | Rules and unresolved paths | Architect |
| 35 | Impact Analysis | Create, review, approve, execute | Architect, QA Lead, Developer |
| 36 | Dependencies | Module and test-case dependency maintenance | Architect |
| 37 | Schedules | Schedule CRUD and history | Admin, QA Lead |
| 38 | Environments | Environment profiles | Admin, Architect |
| 39 | Releases | Release scope, testing, readiness | QA Lead, Lead, Mgmt |
| 40 | Export | Create and download export bundles | All (own machine) |
| 41 | Import | Upload, validate, apply, review conflicts | Admin (central) |
| 42 | Conflicts | Import conflict resolution | Admin, QA Lead |
| 43 | Review Queues | Consolidated judgement work (E-13) | QA Lead, Architect |
| 44 | AI Recommendations | Proposals with evidence and review state | QA Lead, Architect |
| 45 | Notifications | Inbox and preferences | All |
| 46 | Reports | Standard reports and saved searches | All |
| 47 | Audit Log | Searchable audit trail | Admin, Lead |

### 9.2 Key workflows

**W-01 Discover and confirm.** Architect runs Discovery → new items appear as Draft → QA Lead reviews the queue → confirms or edits → items become Active and countable.

**W-02 Execute automated.** Tester chooses scope on *Execute* → the service resolves the scope to run items with selection reasons → the run is queued → the adapter executes with heartbeat → results and artefacts are stored per attempt → analytics update → failures enter the *Triage Queue*.

**W-03 Execute manual.** Tester opens *Manual Runner* → steps are shown one at a time with expected results → the tester records outcome, actual result and evidence per step → the overall result is derived and confirmed → the same result and bug paths apply as for automated tests.

**W-04 Triage a failure.** For each failure the queue shows: matching failure signature, prior history, environment comparison, recent commits touching the screen, matching known issues, candidate duplicate bugs. The tester classifies as Known Issue, Flaky, Environment, Existing Bug (occurrence) or New Bug — one action, fully recorded.

**W-05 Fix and verify.** Bug assigned → developer fixes and marks Fixed with the fixing commit → a retest cycle is created with the configured scope (D-10) → the retest runs → per-bug outcome recorded → pass moves the bug to Closed (Verified); fail reopens it and increments the cycle → beyond `max_auto_retest_attempts` the bug is Escalated, not retried.

**W-06 Change impact.** Commit ingested → impact analysis proposed → QA Lead reviews, edits and approves → run executed from the approved proposal → after-the-fact hit rate recorded against K-05.

**W-07 Consolidate.** Local machine exports → the bundle is transferred → central validates the manifest and schema version → applies in dependency order → matches by business code and distributed identity → records mappings → raises conflicts → an administrator resolves each conflict → the import completes.

**W-08 Assess a release.** Release scope defined → changed screens computed from the commit range → coverage and execution checked → open bugs and known issues in scope listed → a readiness assessment is generated with reservations → a person accepts or rejects it, recorded.

---

## 10. Reporting

### 10.1 Database views delivered in v7.0

| View | Answers |
|---|---|
| `vw_test_case_catalog` | The full catalog with hierarchy and current health |
| `vw_test_case_history` | Every attempt of every test case, dated, with run and machine |
| `vw_test_run_history` | Runs with actor, machine, trigger, environment, code version, counts |
| `vw_run_test_selection_analysis` | Why each test case was in each run |
| `vw_regression_candidates` | Failures with prior passes and attributed commits |
| `vw_flaky_tests` | Candidates and confirmed, with evidence summary |
| `vw_open_bugs` | Open bugs with occurrence counts and ageing |
| `vw_bug_lifecycle` | Time in each state per bug |
| `vw_module_quality_summary` | Per module: coverage, pass rate, failures, flaky tests, orphans |
| `vw_module_open_bugs` | Per module: open bugs by severity and SLA state, kept separate so neither join inflates the other |
| `vw_screen_coverage` | Per screen: test count, coverage state, last executed, exclusion |
| `vw_requirement_coverage` | Per requirement: verifying tests and their latest outcomes |
| `vw_testing_debt` | The debt register, categorised |
| `vw_developer_activity_summary` | Workload attribution, explicitly not a performance score |
| `vw_machine_comparison` | The same test case across machines and environments |
| `vw_environment_impact` | Outcome distribution by environment profile |
| `vw_known_issue_occurrences` | Known issues and their recurrence |
| `vw_impact_analysis_effectiveness` | K-05 hit rate per analysis |
| `vw_release_readiness` | Per release: scope, executed, failed, open bugs, reservations |
| `vw_import_status` | Imports, conflicts and unresolved items |

### 10.2 Reporting rules

- Every view derives from recorded results; none reads a status column alone (BR-RPT-01).
- Every figure is drillable; UI tables link through to the underlying records (BR-RPT-02).
- Counts distinguish zero, unknown and not-applicable (BR-RPT-04) — a module with no tests reports *no coverage*, not *100% passed*.
- Views used by dashboards at full volume are backed by summary tables, not by scanning results.

---

## 11. Non-Functional Requirements

### 11.1 Sizing (5-year horizon)

| Entity | Expected volume | Growth |
|---|---|---|
| Modules | ~50 | Static |
| Screens | 1,000–2,000 | Slow |
| Test cases | 20,000 → 100,000 | Steady |
| Test case versions | ~3× test cases | Steady |
| Runs | ~50/machine/day × 6 machines × 250 days ≈ 75,000/year | Linear |
| Run items | ~50–500 per run → 10–30 million | Linear |
| Results | ~1.05× run items → 10–35 million | Linear |
| Artefacts | ~0.1 per result, ~500 KB each → several hundred GB | Bounded by retention |
| Bugs | 2,000–10,000 | Slow |
| Audit | ~10 million | Bounded by retention |

### 11.2 Performance targets

| Operation | Target | Method |
|---|---|---|
| Catalog list, 100k test cases, filtered | < 1.5 s | Covering indexes; keyset pagination |
| Dashboard | < 3 s | Summary tables only |
| Run detail, 500 items | < 2 s | Two queries, no N+1 |
| Test case history, 5,000 attempts | < 2 s | Index `(test_case_id, created_at)`; paginated |
| Result insert during a run | < 20 ms | No triggers; analytics deferred to a job |
| Impact analysis, 200 changed files | < 30 s | Queued; progress reported |
| Import, 100k records | < 10 min | Chunked, batched, single transaction per entity |
| Analytics rebuild, 20 M results | < 60 min | Chunked by test case; runs offline |

### 11.3 Indexing principles

1. Every foreign key is indexed.
2. Time-series tables are indexed leading with their entity, then the date: `(test_case_id, created_at)`, `(run_id, status)`, `(machine_id, started_at)`.
3. Dashboard reads never touch `tst_test_run_results` directly; they read summary tables.
4. `failure_fingerprint` is indexed everywhere it appears — it is the join for all grouping.
5. Text search fields (`title`, `display_name`, `description`) carry FULLTEXT indexes where search is offered.
6. `tst_test_run_results` is a partitioning candidate by `created_at` (yearly `RANGE`) once it exceeds ~20 million rows; the DDL keeps it partition-ready by including `created_at` in the primary key when partitioning is adopted (§16.3).

### 11.4 Availability, backup, recovery

- Local: nightly `mysqldump` to the evidence root; the application warns if no backup exists in 7 days.
- Central: nightly full plus binlog; monthly restore rehearsal.
- The evidence store is backed up separately, and its restore is independent of the database.
- RPO 24 h local, 1 h central; RTO 4 h.

### 11.5 Security and privacy

| Control | Implementation |
|---|---|
| Authentication | Laravel session auth; bcrypt/argon2 hashes |
| Authorisation | Policies keyed on `tst_permissions`, checked in every service entry point |
| Elevation | Administrative actions require re-authentication |
| Audit | Every write of business significance, with actor, machine, before, after |
| Evidence | Stored outside the web root; served through an authorising controller |
| Secrets | `.env`; never in the database, never in an export bundle |
| Export bundles | SHA-256 manifest; optional signing; no credentials, no `.env`, no tenant data |
| AI | A single provider gateway; payloads are scrubbed of tenant data, personal data and secrets; every call and payload class is logged (BR-AI-08) |
| Prime-AI access | Read-only. The application never writes to the Prime-AI repository or database |
| Tenant data | Screenshots may capture school data; the evidence store is treated as confidential and subject to retention (CN-05) |

---

## 12. Export, Import and Consolidation

### 12.1 Two directions, two rule sets

| | **Evidence bundle** (local → central) | **Catalog bundle** (central → local) |
|---|---|---|
| Contains | Runs, items, results, steps, artefact metadata, bugs, occurrences, retests, notes, source test cases, discovery logs, audit | Modules, categories, menus, screens, canonical test cases, steps, versions, suites, requirements, masters, users, machines, path mappings, dependencies |
| Identity | `(machine_id, source_*_id)` | Business codes |
| On conflict | Queue for decision; never overwrite | Central wins; local divergence is reported |
| Direction | Insert-only at the centre | Upsert on the local machine |
| Frequency | Daily or on demand | On catalog version change |

### 12.2 Bundle format

```
export_M03_20260904_114500.zip
├── manifest.json
├── data/
│   ├── 01_machines.ndjson
│   ├── 02_users.ndjson
│   ├── 10_source_test_cases.ndjson
│   ├── 20_test_runs.ndjson
│   ├── 21_test_run_scopes.ndjson
│   ├── 22_test_run_items.ndjson
│   ├── 23_test_run_results.ndjson
│   ├── 24_test_run_result_steps.ndjson
│   ├── 25_run_result_artifacts.ndjson
│   ├── 30_bugs.ndjson
│   ├── 31_bug_occurrences.ndjson
│   ├── 32_bug_status_history.ndjson
│   ├── 40_retest_cycles.ndjson
│   ├── 50_run_annotations.ndjson
│   ├── 60_discovery_sync_logs.ndjson
│   └── 90_audit_logs.ndjson
└── artifacts/<sha256 prefix>/<sha256>.<ext>
```

`manifest.json` carries: export id, machine id and code, exporting user, application version, **schema version**, export type, period covered, per-entity record counts, per-file SHA-256, bundle SHA-256, and the catalog version the machine held (BR-SYNC-07 … 09, v1 AS-015/AS-016).

The numeric file prefixes are the **apply order** — dependencies before dependants. NDJSON allows streaming, so a million-row bundle never has to be held in memory.

### 12.3 Import algorithm

```
1. VALIDATE
   verify bundle and per-file checksums
   compare schema_version against this installation
       equal            → proceed
       one minor behind → migrate on read, record the decision
       otherwise        → reject, stating the versions          (D-21)

2. IDEMPOTENCY
   if (source_machine_id, source_export_id) already imported and Completed → no-op, report it

3. RESOLVE  (per entity, in apply order)
   catalog references  : business code → local surrogate id
                         unknown code → conflict Missing_Catalog_Reference
   transaction records : (machine_id, source_id) already present → skip
                         otherwise insert with a new local id
   record every mapping in tst_import_record_map

4. CONFLICT CLASSES
   Missing_Catalog_Reference   an unknown screen or test case code
   Definition_Divergence       same business code, different definition hash
   Machine_Metadata_Mismatch   same machine id, different fingerprint
   Duplicate_Business_Code     the same code used for different entities
   Version_Incompatible        unmigratable payload
   Referential_Gap             a child arrived without its parent
   → each becomes a tst_import_conflicts row with the payload retained

5. COMPLETE
   no conflicts        → Completed
   conflicts remain    → Partial, blocking on the conflict queue
   validation failed   → Rejected, nothing applied

6. REVERSE
   while Partial or within reversal_window_hours, an import may be reversed
   using tst_import_record_map; the reversal is itself audited
```

### 12.4 What makes re-import safe

Three independent guards, so that a single mistake cannot duplicate evidence:

1. `UNIQUE (source_machine_id, source_export_id)` on `tst_data_imports` — the same bundle cannot be applied twice.
2. `UNIQUE (machine_id, source_run_id)` on `tst_test_runs`, and the equivalent on bugs, requirements, discovery logs, exports and audit — the same transaction record cannot be inserted twice.
3. `tst_import_record_map` — a per-entity source→local mapping that makes both re-import and reversal deterministic.

---

## 13. AI Integration

### 13.1 Boundaries

AI **proposes**. It never writes catalog data, never changes a result, never changes a bug status, never merges anything (BR-AI-06, R-12).

### 13.2 Structure

```
tst_ai_analyses          one invocation: type, scope, model, prompt version,
                         token usage, duration, status
tst_ai_recommendations   one proposal: type, target entity, recommendation,
                         confidence, evidence_json, review_state,
                         reviewed_by, reviewed_at, outcome
```

`review_state` ∈ `Proposed · Accepted · Rejected · Superseded · Expired`.

### 13.3 Use cases and their evidence obligations

| Type | Input | Evidence it must record |
|---|---|---|
| `Duplicate_Test_Case` | Two definitions | Hash comparison, name similarity, step overlap |
| `Duplicate_Bug` | New failure vs open bugs | Signature match, area match, text similarity |
| `Failure_Cluster` | A signature group | Member results, shared frames |
| `Flaky_Assessment` | Outcome window | The alternation series and the change check |
| `Regression_Assessment` | Failure + history + commits | Last pass, candidate commits, environment delta |
| `Root_Cause_Hypothesis` | Failure + diff | The specific lines and frames implicated |
| `Impacted_Tests` | Change set | Per-test reason and confidence |
| `Coverage_Gap` | Screens + requirements + tests | Which requirement or behaviour is unverified |
| `Test_Draft` (E-24) | Requirement or screen doc | Source paragraphs used |

### 13.4 Accuracy measurement

Acceptance rate by type is reported monthly (K-12). A type whose acceptance rate falls below 50% over 30 recommendations is automatically demoted to advisory-only until its prompt or heuristics are revised. Precision is thereby a measured property, not a claim.

---

## 14. Notifications

`tst_notifications`: recipient, event type, entity, severity, title, body, action URL, `dedupe_key`, `read_at`, `delivered_at`, `channel`.

Deduplication: a notification with the same `(recipient, dedupe_key)` inside `notification_dedupe_window_hours` (default 24) updates the existing row's occurrence count rather than creating a new one (BR-NOTIFY-02, AC-NOTIFY-02).

Channels: in-app (always), email (optional), digest (E-23). Routing is by role and by explicit assignment, never broadcast.

---

## 15. Data Retention

| Class | Default | Rule |
|---|---|---|
| Test cases, versions, steps | Indefinite | Never purged |
| Runs, items, results, steps | Indefinite | Never purged |
| Artefacts | 180 days | Purged unless linked to an open bug, an unclosed release, or an active investigation |
| Raw run output | 90 days | Purged unconditionally |
| Discovery logs | 365 days | — |
| Audit logs | 3 years | Archived, then purged |
| Notifications | 180 days | Read notifications only |
| AI analyses | 365 days | Recommendations retained if accepted |
| Import bundles | 90 days | The record is retained; the file is removed |

Purging is a queued, previewed, audited operation. The preview lists counts by class before anything is removed (AC-RET-01). Purging an artefact sets `is_available = 0` on its metadata row; it never deletes the result (BR-RET-04).

---

## 16. The Database Design

### 16.1 Defects corrected from `testing_DDL_v6.7.sql`

Each of these was found by reading v6.7 against the BRD. The first four prevent the script from executing at all.

| # | Defect | Location | Effect | Fix in v7.0 |
|---|---|---|---|---|
| 1 | `UNIQUE KEY uq_tst_machines_fingerprint (machine_fingerprint)` names a column that is never declared | `tst_machines` | **`CREATE TABLE` fails** | `machine_fingerprint CHAR(64)` declared |
| 2 | `tst_users.code` is `VARCHAR(3)`; every `created_by`/`updated_by`/`deleted_by` referencing it is `VARCHAR(10)` | ~30 tables | **Every foreign key fails** — InnoDB requires matching string lengths | All user-code columns standardised to `VARCHAR(10)` |
| 3 | Master seed rows insert `created_by = 'super'`, a user code that does not exist (seeded users are `S1`, `S2`, `A1`, …) | 5 `INSERT` blocks | Foreign key violation once checks are enabled | Seeds use `S1` |
| 4 | `tst_users` seed relies on a self-referencing FK satisfied only because `FOREIGN_KEY_CHECKS = 0` | `tst_users` | Re-running the seed after setup fails | Bootstrap row inserted with `created_by` NULL, then updated |
| 5 | `tst_main_menus`, `tst_sub_menus` and `tst_tabs_screens` reference `cat_code` and `mm_code` alone | Catalog | A menu can belong to a category in a **different module**; hierarchy silently corrupts | Composite `UNIQUE` keys and composite foreign keys |
| 6 | Two overlapping `ON DELETE SET NULL` foreign keys on the same `ts_code` column | `tst_git_commit_files` | Undefined behaviour; MySQL may nullify a column another constraint still needs | Single `test_case_id` FK plus an indexed `module_code` |
| 7 | Result status enum lacks `Blocked` and `Not_Executed` | `tst_test_run_results` | BRD §9.11 outcomes cannot be recorded; blocked tests get logged as failures | Enum extended |
| 8 | Run status enum lacks `Interrupted` and `Timed_Out`; no heartbeat column | `tst_test_runs` | BR-EXEC-07 unimplementable; runs stay `Running` forever | Enum extended; `heartbeat_at`, `lock_token`, `cancelled_*` added |
| 9 | Evidence limited to three fixed path columns | `tst_test_run_results` | Video, HAR, per-step screenshots have nowhere to go; no expiry or availability state | `tst_run_result_artifacts` |
| 10 | Composite `(ts_code, test_case_code)` propagated as the foreign key into every child table | 9 tables | 22-byte keys in the largest indexes; awkward Eloquent relations; the `SET NULL` problem above | Surrogate `test_case_id`; business identity retained as `UNIQUE` on the parent |
| 11 | `tst_test_case_runs_summary` mixes `Passed/Failed/Skipped/Error` with no `Blocked`; no rebuild provenance | Analytics | Cannot reconcile against results | Aligned enum; `last_rebuilt_at`, `rebuild_source` |
| 12 | `commit_hash` and every related column declared `CHAR(64)`; a Git SHA-1 is 40 hex characters | 5 tables | `CHAR` pads to 64, so a hash read from `git log` never compares equal to a stored one | `VARCHAR(40)` |
| 13 | Trailing comment reads "END OF ENHANCED SCHEMA v8.0" in a file headed v6.7 | Footer | Version confusion | Corrected |

### 16.2 What v7.0 adds

| Area | New tables |
|---|---|
| Platform | `tst_schema_version`, `tst_master_registry`, `tst_code_allocations` |
| Access | `tst_roles`, `tst_permissions`, `tst_role_permissions`, `tst_user_roles` |
| Catalog | `tst_tags`, `tst_test_case_tags`, `tst_test_case_steps`, `tst_source_test_cases`, `tst_test_case_links` |
| Requirements | `tst_app_requirements`, `tst_app_requirement_test_cases` |
| Change | `tst_git_repositories`, `tst_path_mappings` |
| Impact | `tst_impact_analyses`, `tst_impact_analysis_items` |
| Execution | `tst_test_run_result_steps`, `tst_run_result_artifacts`, `tst_failure_signatures` |
| Environment | `tst_environment_profiles` |
| Defects | `tst_bug_comments`, `tst_bug_links`, `tst_known_issues`, `tst_known_issue_results` |
| Suites | `tst_test_suite_versions` |
| Releases | `tst_releases` |
| Sync | `tst_import_conflicts`, `tst_import_record_map` |
| Insight | `tst_ai_analyses`, `tst_ai_recommendations` |
| Notify | `tst_notifications` |

### 16.3 Verification

`testing_DDL_v7.0.sql` was executed against MySQL 8.4.7 before this document was issued. The results:

| Check | Result |
|---|---|
| Fresh install | Executes with zero errors |
| Re-run twice against the same database | Zero errors; object counts unchanged — the script is idempotent |
| Base tables created | 71 |
| Views created and individually `SELECT`-able | 20 of 20 |
| Foreign keys | 273 |
| `CHECK` constraints | 13 |
| End-to-end insert (module → screen → test case → steps → machine → run → item → result → step results → artefact → bug → occurrence) | Accepted; all views return correct rows |
| Negative tests | 12 of 12 correctly **rejected**: cross-branch hierarchy, a run item with both or neither test-case reference, `attempt_no = 0`, duplicate `(machine_id, source_run_id)`, duplicate machine fingerprint, self-referencing module and test-case dependencies, confidence > 1, duplicate test case code on a screen, unknown status code, notification dedupe collision |

Every `CREATE TABLE` uses `IF NOT EXISTS`, every seed uses `ON DUPLICATE KEY UPDATE`, and the deferred foreign keys are guarded by an `information_schema` lookup executed through `PREPARE` — so the script may be run repeatedly and may be applied to an existing v7.0 database without harm. No `DELIMITER` directive is used, so it also runs through tools that do not support one.

---

### 16.3 Deliberate omissions

| Not included | Why |
|---|---|
| UUID columns | Distributed identity is `(machine_id, source_id)`; UUIDs would add 16 bytes per row and no capability |
| Database triggers | Analytics are recomputed by explicit, testable services; triggers hide behaviour and slow inserts |
| Generic key-value entity-attribute tables | They defeat foreign keys and make reporting unverifiable |
| Physical partitioning, at first | `tst_test_run_results` becomes a partitioning candidate past ~20 M rows; §11.3 records the trigger, and the change is additive |
| Stored procedures | Business logic lives in services, which are testable and version-controlled |

---

## 17. Migration from v6.7 to v7.0

For any installation already holding v6.7 data. A fresh installation simply runs the v7.0 script.

| Step | Action | Reversible |
|---|---|---|
| 1 | Full backup of schema and evidence store | — |
| 2 | Widen every user-code column to `VARCHAR(10)`; drop and recreate the affected foreign keys | Yes |
| 3 | Add `machine_fingerprint`; backfill from hostname where derivable; re-register machines whose fingerprint cannot be derived | Yes |
| 4 | Create the new tables (§16.2) | Yes |
| 5 | Add `test_case_id` to each child table; backfill by joining on `(ts_code, test_case_code)`; verify zero unmatched rows | Yes |
| 6 | Add the new foreign keys on `test_case_id`; drop the composite foreign keys; **retain** `ts_code`/`test_case_code` columns for one release as a read-only cross-check | Yes |
| 7 | Migrate the three artefact path columns into `tst_run_result_artifacts`; hash existing files; mark missing files unavailable | Yes |
| 8 | Extend the status enums; no data change (no existing row uses a new value) | Yes |
| 9 | Add composite catalog uniqueness and foreign keys; **report** rows that violate the hierarchy rather than deleting them | Yes |
| 10 | Rebuild all analytics from results; compare against the existing summary and report differences | Yes |
| 11 | Seed roles and permissions from the existing `role` enum | Yes |
| 12 | Set `tst_schema_version` to 7.0.0 | — |
| 13 | After one release with no cross-check failures, drop the retained composite columns from child tables | No |

**Order matters:** steps 2 and 3 must precede 4, because the new tables reference the corrected column types.

---

## 18. Implementation Roadmap

| Phase | Weeks | Delivers | Definition of done |
|---|---|---|---|
| **0 — Foundation** | 1–2 | Schema, seeds, auth, roles, machines, settings, audit, layout | A user can log in on a registered machine and every action is audited |
| **1 — Catalog & Discovery** | 3–6 | Modules → screens, test cases, steps, versions, tags, discovery, review queue | Discovery populates the catalog from the Prime-AI tree and is idempotent |
| **2 — Execution & Evidence** | 7–11 | Run orchestration, Dusk/Pest adapters, manual runner, results, artefacts, heartbeat, run screens | A full day's testing, automated and manual, is executed and recorded |
| **3 — Defects** | 12–15 | Bugs, occurrences, signatures, triage queue, known issues, retest cycles, notifications | A failure becomes a bug, gets fixed, and is verified by retest |
| **4 — Analytics** | 16–19 | Summaries, flakiness, regression, confidence, health, debt, dashboards, views | Every derived figure rebuilds identically from results |
| **5 — Change & Impact** | 20–24 | Git ingest, path mappings, impact analysis, approval, targeted runs, dependencies | An approved impact proposal executes as a run, and K-05 is measured |
| **6 — Sync** | 25–29 | Export, import, conflicts, record map, catalog bundles, reversal | Two machines consolidate with origins intact and re-import is a no-op |
| **7 — Requirements & Release** | 30–33 | Requirements, coverage, traceability, work requests, releases, readiness | Requirement coverage and a release assessment are produced from evidence |
| **8 — Intelligence** | 34–38 | AI gateway, recommendations, review states, explanation panels, digests | Every recommendation carries evidence, confidence and a review state |

Phases 0–4 are the minimum useful product. Phases 5–8 are where the compounding value is.

---

## 19. Open Decisions

Everything else in this document is decided. These require the business owner's confirmation before the phase that depends on them.

| ID | Decision | Recommendation | Needed by |
|---|---|---|---|
| **OD-01** | Confirm BRD D-01: Central Catalog as the default authoring mode | Yes — the source layer remains as the safety net | Phase 1 |
| **OD-02** | Test case code block size per machine per screen | 100 | Phase 1 |
| **OD-03** | Do manual test steps become mandatory for all manual test cases, or only for Critical and High? | Critical and High initially; all thereafter | Phase 2 |
| **OD-04** | Artefact retention: 180 days | Confirm, and confirm the evidence-store location and its backup | Phase 2 |
| **OD-05** | Automatic bug creation from failures: on or off by default? | **Off.** Propose in the triage queue instead — automatic creation produced most of the duplicate-bug problem it was meant to solve | Phase 3 |
| **OD-06** | Flakiness auto-confirmation after 14 days of candidacy | Confirm, or require explicit human confirmation always | Phase 4 |
| **OD-07** | Is a periodic full regression retained alongside impact-based selection? | Yes — weekly, as the safety net for RK-04 | Phase 5 |
| **OD-08** | Export transfer channel | Shared network folder; cloud storage only if encrypted | Phase 6 |
| **OD-09** | Does the central installation execute tests, or only aggregate? | Aggregate only, initially | Phase 6 |
| **OD-10** | AI provider, model and monthly budget | Claude, latest model, with a per-analysis token cap | Phase 8 |
| **OD-11** | Are user-level activity metrics visible to everyone, or to leads only? | Leads only, and never framed as performance (BR-CROSS-06) | Phase 4 |
| **OD-12** | Retention of raw run output: 90 days | Confirm | Phase 2 |

---

## 20. Traceability — BRD to Solution

| BRD area | Solution section | Principal tables |
|---|---|---|
| §9.1 Users and access | §2.2 Core, §11.5 | `tst_users`, `tst_roles`, `tst_permissions`, `tst_role_permissions`, `tst_user_roles` |
| §9.2 Machine identity | §3.5 | `tst_machines` |
| §9.3 Application structure | §5.1, §5.2 | `tst_modules` … `tst_tabs_screens` |
| §9.4 Test cases | §4.1–§4.4 | `tst_test_cases`, `tst_source_test_cases`, `tst_test_case_links`, `tst_test_case_versions` |
| §9.5 Manual steps | §4.5 | `tst_test_case_steps`, `tst_test_run_result_steps` |
| §9.6 Discovery | §5.4 | `tst_discovery_sync_logs` |
| §9.7 Versioning | §4.4 | `tst_test_case_versions` |
| §9.8 Suites | §2.2 Suites | `tst_test_suites`, `tst_test_suite_items`, `tst_test_suite_versions` |
| §9.9 Requirements & work requests | §2.2 Requirements | `tst_app_requirements`, `tst_app_requirement_test_cases`, `tst_test_case_requirements` |
| §9.10 Execution | §6.1–§6.5 | `tst_test_runs`, `tst_test_run_items` |
| §9.11 Results & evidence | §6.4, §6.6 | `tst_test_run_results`, `tst_run_result_artifacts` |
| §9.12 History | §8.7 | `tst_test_case_runs_summary` |
| §9.13 Flakiness | §8.2 | `tst_test_case_runs_summary` |
| §9.14 Regression | §8.3 | `vw_regression_candidates` |
| §9.15 Known issues | §2.2 Defects | `tst_known_issues`, `tst_known_issue_results` |
| §9.16 Bugs | §8.1, §8.6, W-04 | `tst_bugs`, `tst_bug_occurrences`, `tst_bug_links`, `tst_failure_signatures` |
| §9.17 Retesting | W-05 | `tst_retest_cycles`, `tst_retest_cycle_bugs` |
| §9.18 Impact analysis | §7.3 | `tst_impact_analyses`, `tst_impact_analysis_items` |
| §9.19 Dependencies | §7.3 step 2 | `tst_module_dependencies`, `tst_test_case_dependencies` |
| §9.20 Scheduling | §2.1, §9.1 #37 | `tst_schedules` |
| §9.21 Environments | §6.1, §8.3 | `tst_environment_profiles` |
| §9.22 Releases | W-08 | `tst_releases` |
| §9.23 Export/import | §12 | `tst_data_exports`, `tst_data_imports`, `tst_import_conflicts`, `tst_import_record_map` |
| §9.24 Cross-machine analysis | §10.1 | `vw_machine_comparison`, `vw_environment_impact` |
| §9.25 Notifications | §14 | `tst_notifications` |
| §9.26 Reporting | §10 | `vw_*` |
| §9.27 Search | §11.3 | FULLTEXT indexes |
| §9.28 AI | §13 | `tst_ai_analyses`, `tst_ai_recommendations` |
| §9.29 Audit & retention | §15 | `tst_audit_logs` |

---

## 21. Design Principles — the short version

1. **Recorded evidence is the only truth.** Everything else is derived and must be rebuildable.
2. **Never overwrite history.** Append, snapshot, version.
3. **Three identities, three jobs.** Surrogate for joins, code for business, (machine, source id) for distribution.
4. **Catalog flows out; evidence flows in.**
5. **Propose, don't assert.** Every conclusion carries evidence, confidence and a review state.
6. **Fail loudly on ambiguity.** Conflicts queue; they are never guessed.
7. **A local machine owes nothing to the network.**
8. **Every automated action has an owner, a reason and a limit.**
9. **Explainability is designed in, not retrofitted.**
10. **The schema serves the questions in BRD §13.1.** If a question cannot be answered from it, the schema is wrong — not the question.

---

**End of Solution_Design_v2.md**
