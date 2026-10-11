# Prime-AI Testing Application — Solution Design

**Document ID:** TSTAPP-SD-V3
**Version:** 3.0
**Status:** Draft for Technical Review
**Date:** 2026-09-08
**Stack:** Laravel 12 · PHP 8.3 · MySQL 8.0.16+ · Blade + Alpine.js + AdminLTE · Laravel Dusk

**Governed by:** `TestingApp_BRD_v3.md` (v3.0)
**Realised by:** `testing_DDL_v7.2.sql` (v7.2)
**Supersedes:** `Solution_Design_v2.md` (v2.0)
**Derived from:** `testing_DDL_v7.1.sql` — the schema as revised by the product owner

---

## 0. Document Control

### 0.1 What this document is

BRD v3 decides **what the business needs, in two phases**. This document decides **how the system works and how it is built**. The DDL decides **how the information is stored**.

Every business rule in BRD v3 is traced here to a component, a table and an enforcement point.

### 0.2 What changed from v2

| # | Change | Section |
|---|---|---|
| S-01 | **The identity model is replaced.** Business codes are the relational key. The three-identity model of v2 collapses to two | §3 |
| S-02 | **Delivery is split into Phase 1 and Phase 2**, with a rule that keeps them separable under load | §2.5 |
| S-03 | **The source/canonical test case split is removed.** One table, one concept | §4.4 |
| S-04 | **Roles and permissions are removed.** Authorisation is a role enum plus ownership checks | §11.2 |
| S-05 | **Releases are removed.** Release readiness is test-case review and sign-off | §4.6 |
| S-06 | **The TcList becomes a table**, so coverage has a denominator | §4.2 |
| S-07 | **Scheduling gains explicit machine targets** | §6.6 |
| S-08 | **Eighteen defects in v7.1 are corrected**, eight of which prevent the script from running | §16 |
| S-09 | **Every view is rewritten** to join on codes | §9.4 |
| S-10 | The MySQL constraints that the generated-column design imposes are stated as design rules, because they are not optional | §3.5 |

### 0.3 Design tenets

| # | Tenet | Consequence |
|---|---|---|
| T-01 | Recorded evidence is the only truth | Every summary, score and status is derived and rebuildable (§8.7) |
| T-02 | Append, never overwrite | Results, occurrences, versions, transitions, reviews and audit are insert-only |
| T-03 | **A code is an identity, not a label** | Codes are generated, unique, and permanent (§3.5) |
| T-04 | Catalog out, evidence in | The sync protocol has two directions with different rules (§10) |
| T-05 | Propose, don't assert | Every derived conclusion carries evidence, confidence and a review state |
| T-06 | Fail loudly on ambiguity | Conflicts queue; they are never resolved by a coin toss |
| T-07 | Local autonomy | No feature except consolidation requires the central installation |
| T-08 | **Phase 1 stands alone** | No Phase-1 table has a foreign key into Phase 2 (§2.5) |

---

## 1. Solution Overview

### 1.1 In one paragraph

The Testing Application is installed locally on each developer and tester machine, with one central installation. Each installation holds a complete schema for the phase it is at. **Users, machines and the Prime-AI navigation catalog are governed centrally** and distributed outward as seeded bundles. **Everything else — required test-case lists, test cases, reviews, runs, results, artefacts, bugs, retests, notes, discovery logs, audit — is produced locally and consolidated inward.** A test case authored on machine `D02A` carries `D02A` in its code, so it can never collide with one authored on `T01A`, and consolidation needs no id translation. Phase 1 records and diagnoses. Phase 2 adds Git ingestion, path mapping, dependencies, suites and impact analysis, and turns "what changed?" into "run these tests, for these reasons".

### 1.2 Context

```
 ┌──────────────────────────────────────────────────────────────────────────┐
 │                          PRIME-AI SOURCE TREE                            │
 │           Modules/*      tests/Browser/*      .git history               │
 └────────────┬───────────────────────────────────────┬─────────────────────┘
              │ discovery  [P1]                       │ git ingestion  [P2]
              ▼                                       ▼
 ┌──────────────────────────────────────────────────────────────────────────┐
 │            TESTING APPLICATION — local installation  (D02A)              │
 │                                                                          │
 │  ┌──────────────── PHASE 1 ────────────────┐  ┌───── PHASE 2 ─────┐      │
 │  │ Config · Env · Users · Machines         │  │ Change requests    │      │
 │  │ Catalog · TcList · Test cases · Review  │  │ Dependencies       │      │
 │  │ Execution · Results · Evidence          │  │ Path mappings      │      │
 │  │ Scheduling · Discovery · History        │  │ Suites             │      │
 │  │ Bugs · Retest · Export/Import           │  │ Git ingestion      │      │
 │  │ AI · Notifications · Audit              │  │ Impact analysis    │      │
 │  └─────────────────────────────────────────┘  └────────────────────┘      │
 │                                                                          │
 │   MySQL 8 (prime_testing)            Evidence store (filesystem)         │
 └────────────┬───────────────────────────────────────▲─────────────────────┘
              │ evidence bundle out                   │ catalog bundle in
              ▼                                       │
 ┌────────────────────────────────────────────────────┴─────────────────────┐
 │            TESTING APPLICATION — central installation  (A01A, id 1)      │
 └──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Architecture

### 2.1 Layers

```
   HTTP ──▶ Controllers (thin) ──▶ Services (all business logic) ──▶ Models ──▶ MySQL
                  │                       │                                     │
           FormRequests             Jobs / Events                        FK, UNIQUE, CHECK,
           (validation)             (async work)                         generated columns
                  │                       │                                     │
              Policies              Listeners                            (last line of defence)
          (role + ownership)   (notification, audit)
```

### 2.2 Modules

| Laravel module | Owns | Phase |
|---|---|---|
| `Platform` | App settings, environment profiles, schema version setting | P1 |
| `Identity` | Users, machines | P1 |
| `Catalog` | Modules, categories, menus, screens | P1 |
| `Authoring` | TcList, test cases, steps, versions, reviews, duplicates | P1 |
| `Execution` | Runs, scopes, items, results, steps, artefacts, signatures | P1 |
| `Scheduling` | Schedules, targets | P1 |
| `Discovery` | Source scanning and reconciliation | P1 |
| `Analytics` | Summaries, flakiness, regression, trending | P1 |
| `Defects` | Known issues, bugs, occurrences, links, retests | P1 |
| `Sync` | Exports, imports, record map, conflicts | P1 |
| `Intelligence` | AI analyses and recommendations | P1 |
| `Ops` | Notifications, audit | P1 |
| `ChangeRequests` | Change requests, coverage mapping, work backlog | **P2** |
| `Dependencies` | Module and test-case dependencies | **P2** |
| `SourceMap` | Path mappings | **P2** |
| `Suites` | Suites, items, versions | **P2** |
| `Git` | Repositories, commits, commit files | **P2** |
| `Impact` | Impact analyses and items | **P2** |

### 2.3 Key services

| Service | Responsibility | Phase |
|---|---|---|
| `CodeFactory` | Allocates the next sequence for a code and validates every code format (§3.6) | P1 |
| `MachineRegistry` | Machine registration, fingerprint verification, boot check | P1 |
| `CatalogService` | Hierarchy integrity, prefix validation, exclusion | P1 |
| `TcListService` | Required-list authoring, status, coverage denominator | P1 |
| `TestCaseService` | Authoring, definition hash, versioning, orphan marking, retirement | P1 |
| `ReviewService` | Review, readiness scoring, sign-off | P1 |
| `DuplicateService` | Proposal, scoring, human confirmation, supersede | P1 |
| `ExecutionService` | Run lifecycle, item selection, attempt recording, heartbeat, roll-ups | P1 |
| `EvidenceService` | Artefact write, content-hash dedupe, retention, purge marking | P1 |
| `SignatureService` | Failure normalisation, fingerprinting, grouping | P1 |
| `ScheduleService` | Cron evaluation, target dispatch, missed-run detection | P1 |
| `DiscoveryService` | Source scan, reconciliation, proposals | P1 |
| `AnalyticsService` | Summary maintenance, flakiness, regression, full rebuild | P1 |
| `DefectService` | Bug lifecycle, occurrence attribution, SLA, escalation | P1 |
| `RetestService` | Cycle creation, scope resolution, verification | P1 |
| `ExportService` / `ImportService` | Bundle build, validate, apply, map, reverse | P1 |
| `ConflictService` | Conflict classification and resolution | P1 |
| `AiService` | Analysis dispatch, recommendation lifecycle, outcome capture | P1 |
| `NotificationService` | Dedupe, delivery, digest | P1 |
| `AuditService` | Structured audit writes | P1 |
| `PathResolver` | Glob matching, priority, confidence, unresolved reporting | **P2** |
| `DependencyGraph` | Traversal with depth decay | **P2** |
| `SuiteService` | Membership resolution, versioning | **P2** |
| `GitIngestService` | Incremental commit and file ingestion, author resolution | **P2** |
| `ImpactService` | Selection algorithm, evidence capture, approval | **P2** |

### 2.4 Jobs

| Job | Trigger | Why queued | Phase |
|---|---|---|---|
| `RunDiscoveryJob` | Manual or scheduled | Full-tree scan | P1 |
| `RecordResultJob` | Adapter output | Isolates the hot path | P1 |
| `RebuildAnalyticsJob` | Nightly + on demand | Full rebuild over millions of rows | P1 |
| `RunWatchdogJob` | Every minute | Moves heartbeat-stopped runs to Interrupted | P1 |
| `ScheduleDispatchJob` | Every minute | Fires due schedules, records missed | P1 |
| `AutoRetestJob` | Bug marked Fixed | External execution, bounded attempts | P1 |
| `BuildExportJob` / `ApplyImportJob` | Manual | Large bundles | P1 |
| `AiAnalysisJob` | Manual or triggered | External API latency | P1 |
| `PurgeArtifactsJob` | Nightly | Retention marking | P1 |
| `GitIngestJob` | Manual or post-commit | Repository walk | **P2** |
| `ImpactAnalysisJob` | Commit range, bug fix, change request | Graph traversal | **P2** |

### 2.5 The phase boundary — how Phase 1 stays independent

**SD-01. A Phase-1 table never carries a foreign key to a Phase-2 table.**

Five Phase-1 tables hold columns that will later point at Phase-2 entities:

| Phase-1 table | Column | Phase-2 target |
|---|---|---|
| `tst_test_runs` | `suite_id`, `suite_version_no` | `tst_test_suites` |
| `tst_test_runs` | `impact_analysis_id` | `tst_impact_analyses` |
| `tst_test_run_scopes` | `suite_id`, `change_request_id` | `tst_test_suites`, `tst_app_requirements` |
| `tst_bugs` | `change_request_id` | `tst_app_requirements` |
| `tst_retest_cycles` | `scope_json` includes dependency scope | `tst_test_case_dependencies` |

**The columns are declared in the Phase-1 DDL and left null. The foreign keys are added by Section 30 of the Phase-2 DDL.**

The reason is operational, not aesthetic. By the time Phase 2 ships, `tst_test_run_results` will hold millions of rows and `tst_test_runs` hundreds of thousands. `ALTER TABLE … ADD COLUMN` on InnoDB is instant for most cases in MySQL 8, but `ADD CONSTRAINT` requires a full index build and a metadata lock. Declaring the column early costs nothing and turns a Phase-2 upgrade into a constraint addition rather than a table rewrite.

**SD-02. Phase 2 adds; it never alters.** The Phase-2 script contains `CREATE TABLE`, `ALTER TABLE … ADD CONSTRAINT`, `CREATE OR REPLACE VIEW` and `INSERT`. It contains no `ADD COLUMN`, no `MODIFY COLUMN`, and no `DROP`.

---

## 3. The Identity Model

This is the most important section in the document. Everything else follows from it.

### 3.1 Two identities, not three

v2 used three: a surrogate integer for joins, a business code for recognition, and `(machine_id, source_id)` for records created independently on many machines.

v3 uses two:

| # | Identity | Applies to | Form |
|---|---|---|---|
| **1** | **BUSINESS CODE** | Users, machines, catalog levels, TcList entries, test cases | A generated, stored, unique string that is identical on every machine |
| **2** | **DISTRIBUTED IDENTITY** | Runs, results, bugs, discovery logs, exports, imports, AI analyses, audit | `(machine_id, source_<entity>_id)` — a pair that makes re-import a no-op |

The surrogate `id` still exists on most tables. It is now **an internal convenience for pagination and for large child tables**, never an exported identity and never the parent key of a cross-machine relationship.

### 3.2 The code grammar

```
user_code        VARCHAR(3)    D02                     role letter + 2 digits
machine_number   ENUM('A'..'Z') A
machine_code     VARCHAR(4)    D02A                    GENERATED: user_code ‖ machine_number

module_code      VARCHAR(5)    SLB
cat_code         VARCHAR(3)    T01
mm_code          VARCHAR(5)    T0104                   ← contains cat_code as prefix
sm_code          VARCHAR(7)    T010401                 ← contains mm_code as prefix
ts_code          VARCHAR(11)   T0104010200             ← contains sm_code as prefix

tcr_code         VARCHAR(21)   D02A_T0104010200_0001   GENERATED: machine_code ‖ '_' ‖ ts_code ‖ '_' ‖ LPAD(tc_list_number,4,'0')
test_case_code   VARCHAR(21)   D02A_T0104010200_001    GENERATED: machine_code ‖ '_' ‖ ts_code ‖ '_' ‖ LPAD(tc_seq_number,3,'0')
```

**Two properties do the work:**

1. **The catalog codes are positionally nested.** `T0104010200` *is* a screen under `T010401` under `T0104` under `T01`. Hierarchy is readable from the code and additionally enforced by composite foreign keys, so the two can never disagree.
2. **The test case code embeds the authoring machine.** Two people authoring the same test on the same screen produce `D02A_T0104010200_001` and `T01A_T0104010200_001` — different codes, both valid, neither wrong. Collision is structurally impossible.

### 3.3 What this removes

| Removed | Because |
|---|---|
| The id-to-code translation layer at every import boundary | Codes are already identical everywhere |
| `tst_source_test_cases` and its whole reconciliation path | §4.4 |
| `source_test_case_id` and the check constraint on run items | Follows |
| The central number allocator (`tst_code_allocations`) | The machine segment does the allocating |
| Ambiguity in a log line | `D02A_T0104010200_001` resolves without a database |

### 3.4 What it costs

| Cost | Assessment |
|---|---|
| 21 bytes per index entry instead of 4 | ~100 MB of index on 6M result rows. Acceptable — BRD §14.2 |
| No renaming, ever | §3.5. Turns out to be a feature |
| Fixed hierarchy depth | Accepted; the Prime-AI navigation is genuinely this shape |
| 999 test cases per screen per machine | BRD OPEN-02 |

### 3.5 The MySQL constraints this design imposes

**These are not preferences. MySQL enforces them, and the design has to be built around them.**

| # | Constraint | Consequence in this schema |
|---|---|---|
| **MC-1** | A foreign key **cannot reference a VIRTUAL generated column** | `machine_code`, `tcr_code` and `test_case_code` are all declared **STORED** |
| **MC-2** | A foreign key **on a base column of a stored generated column** cannot use `CASCADE`, `SET NULL` or `SET DEFAULT` for `ON UPDATE` or `ON DELETE` | `tst_test_cases.machine_code` and `.ts_code`, and `tst_machines.owner_user_code`, are all **`ON DELETE RESTRICT`**. They cannot be anything else |
| **MC-3** | Following MC-2, **`ON UPDATE CASCADE` is impossible** on any code that feeds a generated column | **There is no mechanism by which a rename could propagate.** This is why BRD R-17 is a rule rather than a guideline |
| **MC-4** | A generated column's expression must be deterministic | The codes are pure concatenation and `LPAD`. No `NOW()`, no session state |
| **MC-5** | The referenced side of a foreign key must be a unique index | `uq_tst_machines_code`, `uq_tst_tc_list_code`, `uq_tst_testCases_tcCode` are all `UNIQUE` |
| **MC-6** | Both sides of a string foreign key must share a character set and collation | Everything is `utf8mb4` / `utf8mb4_unicode_ci`, and **every declaration of a given code has an identical width** (§16, defects 9–12) |

**The important one is MC-3.** It means the schema physically cannot support renaming a user code, a machine code or a screen code once a test case exists. The correct operation is always *deactivate, create new, record the relationship* — and because the database will not let anyone do otherwise, the rule cannot be quietly broken by a data-fix script at 2am.

### 3.6 `CodeFactory` — where codes are minted

Codes are **generated by the database**, but the *sequence number* is allocated by the application. `CodeFactory` is the only place that does it:

```
CodeFactory::nextTestCaseSequence(machine_code, ts_code):
    lock the screen row for this machine        # SELECT ... FOR UPDATE on tst_tabs_screens
    seq := SELECT COALESCE(MAX(tc_seq_number),0) + 1
             FROM tst_test_cases
            WHERE machine_code = :machine_code AND ts_code = :ts_code
    return seq                                   # the unique key catches any race
```

The `SELECT … FOR UPDATE` serialises concurrent authoring on one machine. `uq_tst_testCases_tcCode` is the backstop: a lost race fails the insert and the service retries. **Sequences are never reused**, even after a soft delete — reusing `001` would attach an old code to a new test.

### 3.7 Distributed identity, still needed

Codes solve *catalog and authoring*. They do not solve *evidence*, because a run is not something anyone names. Runs, results, bugs, imports, exports, discovery logs, AI analyses and audit rows therefore keep `(machine_id, source_<entity>_id)`:

```
Local:    id = local AUTO_INCREMENT
          source_run_id = the same local id
          machine_id    = this machine's registered id

Central:  id = a NEW central AUTO_INCREMENT
          source_run_id / machine_id = preserved from the source
          UNIQUE(machine_id, source_run_id) makes a repeated import a no-op
```


### 3.8 Table inventory by phase — 58 tables

| Phase | Group | Tables | Count |
|---|---|---|---:|
| **1** | Platform | `tst_app_settings` · `tst_environment_profiles` | 2 |
| **1** | Identity | `tst_users` · `tst_machines` | 2 |
| **1** | Catalog | `tst_modules` · `tst_categories` · `tst_main_menus` · `tst_sub_menus` · `tst_tabs_screens` | 5 |
| **1** | Authoring | `tst_tc_required_list` · `tst_test_cases` · `tst_test_case_steps` · `tst_test_case_review` · `tst_test_case_versions_history` · `tst_duplicate_test_case` | 6 |
| **1** | Execution | `tst_test_runs` · `tst_test_run_scopes` · `tst_test_run_items` · `tst_test_run_results` · `tst_test_run_result_steps` · `tst_run_result_artifacts` · `tst_failure_signatures` · `tst_test_case_runs_summary` | 8 |
| **1** | Scheduling | `tst_schedules` · `tst_schedule_targets` | 2 |
| **1** | Comments & Discovery | `tst_run_annotations` · `tst_discovery_sync_logs` | 2 |
| **1** | Defects | `tst_known_issues` · `tst_known_issue_results` · `tst_bugs` · `tst_bug_occurrences` · `tst_bug_status_history` · `tst_bug_comments` · `tst_bug_links` · `tst_retest_cycles` · `tst_retest_cycle_bugs` | 9 |
| **1** | Sync | `tst_data_exports` · `tst_data_imports` · `tst_import_record_map` · `tst_import_conflicts` | 4 |
| **1** | AI | `tst_ai_analyses` · `tst_ai_recommendations` | 2 |
| **1** | Ops | `tst_notifications` · `tst_audit_logs` | 2 |
| | **Phase 1 total** | | **44** |
| **2** | Change requests | `tst_app_requirements` · `tst_app_requirement_test_cases` · `tst_test_case_requirements` | 3 |
| **2** | Dependencies | `tst_module_dependencies` · `tst_test_case_dependencies` | 2 |
| **2** | Path mapping | `tst_path_mappings` | 1 |
| **2** | Suites | `tst_test_suites` · `tst_test_suite_items` · `tst_test_suite_versions` | 3 |
| **2** | Git | `tst_git_repositories` · `tst_git_commits` · `tst_git_commit_files` | 3 |
| **2** | Impact | `tst_impact_analyses` · `tst_impact_analysis_items` | 2 |
| | **Phase 2 total** | | **14** |

**Views: 21** — 17 in Phase 1, 4 in Phase 2.

**Removed since v7.0 — 16 tables.** `tst_roles`, `tst_permissions`, `tst_role_permissions`, `tst_user_roles` (D-25) · `tst_releases` (D-26) · `tst_code_allocations` · `tst_source_test_cases` (D-24) · `tst_schema_version` (D-27) · `tst_tags`, `tst_test_case_tags`, `tst_test_case_types`, `tst_test_case_statuses`, `tst_testing_layers`, `tst_testing_methods`, `tst_testing_technologies`, `tst_master_registry` (owner: ENUMs replace single-purpose lookup tables).

---

## 4. The Authoring Pipeline

### 4.1 The pipeline in one line

```
Screen → requirement doc → required test-case list → test case → steps → review → released → executed
```

Each arrow is a status transition on a named record, so the pipeline is reportable at every stage.

### 4.2 The required test-case list (`tst_tc_required_list`)

**Why it is a table and not a markdown file.** Coverage needs a denominator. "Fees is about half tested" is not a number; "Fees has 214 required cases, 168 released" is. A file cannot be counted, filtered, assigned or joined to the test cases that satisfy it.

```
tst_tc_required_list
  tcr_code   D02A_T0104010200_0001      ← the planned test
  text_requir_detail                     ← what it must verify, in business language
  requir_steps_detail                    ← the required steps, before any code exists
  tc_creation_status                     ← Planned → Pending → In-Progress → Ready → In_Review → Released
```

`tst_test_cases.tcr_code` is a foreign key to it. **Coverage of a screen = released test cases ÷ required entries not marked Not-Required.**

### 4.3 The test case (`tst_test_cases`)

Carries authoring coordinates (file, namespace, class, method), classification (type, method, technology, layer, criticality), lifecycle (creation status, execution status, orphan state, retirement) and the **definition hash**.

**The definition hash** is `sha256` over the normalised definition including the ordered steps. It drives two things:

1. **Versioning.** When the hash changes, `TestCaseService` writes the *previous* definition to `tst_test_case_versions_history` and increments `version_no`. The history table is immutable.
2. **Duplicate detection.** Two test cases with the same hash are the same test, authored twice. `DuplicateService` proposes the link; a person confirms it.

### 4.4 Why `tst_source_test_cases` is gone

This is the largest structural simplification in v3, and it is worth stating why it is safe.

**The problem it solved.** Under v7.0, a test case's identity was *screen + sequence*. Two machines authoring independently would both mint `T0104010200 / 001`. Importing one into the other would either collide or silently merge two different tests. `tst_source_test_cases` existed to hold the incoming one in quarantine until a human decided whether it was the same test.

**Why the problem no longer exists.** The machine segment makes the codes different: `D02A_T0104010200_001` and `T01A_T0104010200_001`. Both import cleanly into one table. Neither is quarantined, because neither is ambiguous.

**What replaces the judgement.** The judgement was never about identity — it was about *equivalence*, which is a different question and belongs in `tst_duplicate_test_case`:

| Link type | Meaning |
|---|---|
| `Proposed_Equivalent` | The system thinks these are the same test |
| `Confirmed_Equivalent` | A QA Lead agrees |
| `Confirmed_Different` | A QA Lead disagrees — **and this decision is retained**, so it is not re-proposed forever |
| `Duplicate_Of` | Same test; one is primary for reporting |
| `Variant_Of` | Related but deliberately different |
| `Supersedes` | This one replaces that one |

Links are **insert-only**; a reversal writes a new row and stamps `superseded_at` on the old one, so the decision history survives (BRD BR-DUP-04).

**Net effect:** one table removed, two nullable columns and a check constraint removed from `tst_test_run_items`, and an entire import path removed from `ImportService`.

### 4.5 Versioning

```
TestCaseService::save(testCase):
    newHash := sha256(normalise(definition + ordered steps))
    if newHash <> testCase.definition_hash:
        snapshot the CURRENT definition into tst_test_case_versions_history
            with version_no = testCase.version_no, steps_json = current steps
        testCase.version_no       += 1
        testCase.definition_hash   = newHash
    persist
```

`tst_test_case_steps` holds **only the current version**; historical steps live in the snapshot's `steps_json`. This is a deliberate denormalisation: a manual tester executing a historical run must see the steps as they *were*, and keeping every version in the live steps table would make the current-step query filter on version on every grid load.

### 4.6 Review and release (`tst_test_case_review`)

Replaces the Release entity of v2. The unit of release is the test case.

| Field group | Purpose |
|---|---|
| `test_case_code`, `version_no`, `machine_code`, `review_date` | What was reviewed, in which version, where, when |
| `readiness_score`, `readiness_assessment` | Metrics, completion checks, bug-free status |
| `review_note`, `reviewed_by`, `reviewed_at` | Step correctness, script logic, assertion accuracy, quality, suggestions |
| `sign_off_note`, `signed_off_by`, `signed_off_at` | Authorisation, risk acceptance, release clearance |
| `bug_in_testcase`, `known_issues_in_scope` | Two specific risk flags the team asked for |
| `status`, `released_at` | Pending → In-Progress → Completed → Released |

**`version_no` is a plain column with no foreign key**, and that is intentional. It records the version as it stood at review time. If it were a foreign key to the version history, reviewing version 1 would be impossible until version 2 existed — because the history table only holds *superseded* definitions.

**Reviewer and approver are separate columns.** Recording them in one field would make "who signed this off" unanswerable in the case that matters: when someone reviewed their own work.

**A review is retained as issued** (BRD BR-REV-07). `ReviewService` has no update path for `readiness_score` or `readiness_assessment` once `status = 'Completed'`.

---

## 5. The Catalog

### 5.1 Structure and double enforcement

```
tst_modules        module_code SLB
tst_categories     cat_code    T01          + module_code
tst_main_menus     mm_code     T0104        + module_code + cat_code
tst_sub_menus      sm_code     T010401      + module_code + cat_code + mm_code
tst_tabs_screens   ts_code     T0104010200  + module_code + cat_code + mm_code + sm_code(nullable)
```

Parentage is enforced **twice**, on purpose:

1. **By prefix.** `mm_code` begins with `cat_code`; `sm_code` begins with `mm_code`; `ts_code` begins with `sm_code` where one exists. `CatalogService` validates this on write.
2. **By composite foreign key.** `tst_main_menus (module_code, cat_code)` references `tst_categories (module_code, cat_code)`. This is what v6.7 got wrong — it referenced `cat_code` alone, which allowed a main menu to belong to a category in a different module.

The prefix rule is human-readable; the foreign key is machine-enforced. Neither alone is sufficient: a prefix can be typed wrong, and a composite key permits `T0104` under `T02` as long as both rows agree.

### 5.2 `sm_code` is nullable

A screen may hang directly off a main menu. MySQL treats a composite foreign key containing a NULL as satisfied, so `tst_tabs_screens` declares its main-menu parentage as a three-column composite and its sub-menu link separately, nullable.

### 5.3 The screen as pipeline state

`tst_tabs_screens` carries five status columns — requirement doc, TcList, development, test-case creation, test-run status. Together they are the **project management view of testing**: a QA Lead can list every screen whose development is complete and whose TcList has not been written.

`is_excluded` with a reason, an excluder and a date takes a screen out of the coverage denominator without deleting it (BRD BR-CAT-06). `finding_method` records whether a person or discovery found it, and `is_reviewed` whether a person has confirmed it belongs.

---

## 6. Execution

### 6.1 The shape

```
tst_test_runs                one execution EVENT
  tst_test_run_scopes        why the run exists
  tst_test_run_items         which test cases, and why each one
    tst_test_run_results     one row per ATTEMPT — insert-only, the source of truth
      tst_test_run_result_steps   per-step outcomes for manual execution
      tst_run_result_artifacts    evidence
```

### 6.2 A run is not a test case

**Correction to v7.1 (defect 6).** `tst_test_runs` in v7.1 carried a generated `test_case_code` built from `machine_code`, `ts_code` and `tc_seq_number`. A run is an *event covering many test cases*; giving it one test-case code is a category error, and the generated column referenced a column the table does not declare, so the script would not execute.

v7.2 gives the run what it actually needs:

| Column | Meaning |
|---|---|
| `machine_id`, `source_run_id` | Distributed identity |
| `run_machine_code` | Which machine executed it — the code, so it is readable and consolidates |
| `run_user_code` | Which person's machine it was |
| `initiated_by`, `executed_by` | Attribution; different for a scheduled run |

The per-test-case link lives where it belongs: `tst_test_run_items.test_case_code`.

### 6.3 Selection reason

Every run item records **why** it was selected: Manual, Suite, Direct Change, Dependency, Bug Retest, Critical, Regression, Full Regression, Historical Correlation, Open Bug, Schedule. In Phase 1 the reachable values are Manual, Bug Retest, Critical, Regression, Schedule and Open Bug; the rest activate with Phase 2.

This is what makes impact analysis explainable **after the fact** — a month later, "why did we run these 40 tests?" is answerable from the data.

### 6.4 Snapshots on the run item

`display_name_snapshot`, `file_path_snapshot`, `criticality_snapshot` and `test_case_version_no` are captured at selection time. A run from six months ago renders as the test case then stood, not as it stands now. Without these, renaming a test case silently rewrites history.

### 6.5 Attempts, not statuses

`tst_test_run_results` is **insert-only**. A re-execution is a new attempt with `attempt_no + 1`; exactly one attempt per item carries `is_final_attempt = 1`.

`ExecutionService` is the only writer. There is no code path anywhere in the application that updates `status` on an existing result row.

**Six statuses, and the two that v6.7 lacked matter most:**

| Status | Meaning |
|---|---|
| Passed / Failed / Error / Skipped | Conventional |
| **Blocked** | Did not run because a prerequisite failed. **Recording this as Failed inflates defect counts** and sends people to investigate a test that never executed |
| **Not_Executed** | Selected but never reached — the run was interrupted or cancelled |

### 6.6 Scheduling with explicit targets

BRD REQ-SCHED-01 asks for scheduled execution *on different machines for different modules, screens or test cases*. One `machine_id` column on the schedule cannot express that.

```
tst_schedules            cron, timezone, owner, catch-up policy, suspension, missed count
  tst_schedule_targets   one row per (what to run, where to run it)
                           target_type  Module | Screen | TestCase
                           module_code / ts_code / test_case_code
                           machine_code            ← which machine executes this target
```

`ScheduleDispatchJob` runs every minute on every machine, selects targets whose `machine_code` matches the local machine and whose schedule is due, and creates one run per target group. **A schedule that did not fire is recorded as missed** with the count on the schedule row — silence is not the same as success.

### 6.7 The heartbeat

A run writes `heartbeat_at` while executing. `RunWatchdogJob` moves any `Running` run whose heartbeat is older than the configured threshold to **Interrupted**, retaining every result already recorded.

Without this, a machine that loses power leaves a run permanently `Running`, and every dashboard that counts in-progress work is wrong forever.

### 6.8 Roll-ups

`total_tc_count`, `passed_tc_count` and the rest are **recomputed from results over final attempts only**, never incremented ad hoc. Incremental counters drift; recomputed ones cannot (BRD R-13).

---

## 7. Evidence and Failure Grouping

### 7.1 Artefacts

`tst_run_result_artifacts` replaces the three fixed path columns of v6.7, which left video, HAR files and per-step screenshots nowhere to go.

| Property | Design |
|---|---|
| Content-hash dedupe | `file_sha256`; identical artefacts stored once, referenced many times |
| Step attribution | `step_no` nullable — an artefact may belong to one manual step |
| Retention | `expires_at`, `purged_at`, `is_available` |
| **Expired ≠ never existed** | A purged artefact stays as a row with `is_available = 0`, so the result shows "evidence expired" rather than appearing never to have had any |

### 7.2 Failure signatures

```
normalise(failure):
    strip timestamps, ids, memory addresses, absolute paths
    keep exception class
    keep top application stack frames, drop vendor frames
    fingerprint := sha256(class + normalised message + top frames)
```

A signature carries occurrence count, distinct test cases and distinct machines. Once triaged to a bug or known issue, later matching failures are attributed automatically.

**This is what turns forty failures into one problem.** Without it, triage volume scales with test count rather than defect count, and the team stops triaging.

---

## 8. Analytics

### 8.1 Derived, never authoritative

`tst_test_case_runs_summary` is a convenience for dashboards. **Every column must be reproducible from `tst_test_run_results` alone.** `RebuildAnalyticsJob` does exactly that, and a nightly job compares incremental values against a full rebuild and reports divergence (BRD R-13, BR-HIST-03).

`last_rebuilt_at` and `rebuild_source` mean a summary can always be shown to be current with the evidence.

### 8.2 Flakiness

```
is_flaky_candidate(test_case):
    window   := last 10 final attempts, same environment_profile
    if count(window) < 5:                    return false, 'Insufficient_History'
    if definition_hash changed within window: return false, 'Definition_Changed'
    if covered code changed within window:    return false, 'Code_Changed'    # P2 refines this
    alternations := count of status changes across the window
    return alternations >= 2
```

The candidate is proposed; **confirmation is a human decision** recorded in `flaky_confirmed_by`. `flaky_evidence_json` retains the outcome series, the environment and the change check, so the conclusion can be re-argued a year later.

A confirmed flaky test is excluded from regression alerting but **never from execution** — excluding it destroys the evidence needed to fix it.

### 8.3 Regression

```
is_regression(test_case, result):
    if result.status <> 'Failed':                                  return false
    if summary.is_flaky_confirmed:                                 return false
    passed := exists a Passed final attempt within 30 days
              in a comparable environment_profile
    return passed
```

In Phase 1 this reports a regression. **Attributing it to a commit is Phase 2** (§12.3).

### 8.4 Health status

| Status | Condition |
|---|---|
| `Insufficient_History` | Fewer than 5 recorded attempts |
| `Orphaned` | Implementation missing from source |
| `Blocked` | Last final attempt Blocked |
| `Frequently_Failing` | Pass rate over 30 days below 50% |
| `Unstable` | Confirmed or candidate flaky |
| `Under_Investigation` | An open bug references it |
| `Obsolete` | Retired, or its screen is excluded |
| `Healthy` | None of the above |

### 8.5 Confidence score

A 0–100 composite over pass rate, recency, evidence completeness, flakiness and open defects, with `confidence_json` holding the inputs. It answers "how much should I trust this green tick?" — a green result from a test that has run once, six months ago, on one machine, is not the same as one that has run 200 times this month on three.

---

## 9. Reporting

### 9.1 Read discipline

Dashboards read `tst_test_case_runs_summary` and the views. Investigation screens read `tst_test_run_results` directly and **always with a filter**. No screen aggregates the results table unfiltered.

### 9.2 Phase-1 views

| View | Purpose |
|---|---|
| `vw_test_case_catalog` | Catalog with full hierarchy and current health — the main list screen |
| `vw_tc_list_coverage` | **New in v3.** Required vs written vs reviewed vs released, per screen |
| `vw_test_case_history` | Every attempt for a test case, with run and environment context |
| `vw_test_run_history` | Run-level history with roll-ups |
| `vw_flaky_tests` | Candidates and confirmations with their evidence |
| `vw_regression_candidates` | Currently failing, previously passing, not flaky |
| `vw_open_bugs` | Open defects with age, SLA state and occurrence count |
| `vw_bug_lifecycle` | Time in each status, per bug |
| `vw_screen_coverage` | Screen-level coverage and health |
| `vw_module_quality_summary` | Module roll-up |
| `vw_machine_comparison` | **The same test, on different machines** — the environment-difference detector |
| `vw_environment_impact` | Pass rate by environment profile |
| `vw_known_issue_occurrences` | Recurrence counts per known issue |
| `vw_testing_debt` | Screens with no released test case, weighted by criticality |
| `vw_developer_activity_summary` | Authorship and execution per user |
| `vw_import_status` | Import outcomes and open conflicts |
| `vw_review_status` | **New in v3.** Review and sign-off state per test case |

### 9.3 Phase-2 views

| View | Purpose |
|---|---|
| `vw_change_request_coverage` | Which tests cover which change request |
| `vw_run_test_selection_analysis` | Selection reasons and their hit rate |
| `vw_impact_analysis_effectiveness` | Defects in scope vs out of scope |
| `vw_suite_composition` | Current and versioned membership |

### 9.4 Every view is rewritten

**Correction to v7.1 (defect 18).** Every view in v7.1 still joins `tst_test_cases` on `tc.id`. Under the new model the joining key is `test_case_code`, and a view that joins on `id` will silently return nothing after consolidation, because a central `id` does not match a local one. All views are rewritten to join on codes.

---

## 10. Export, Import and Consolidation

### 10.1 Two directions

| Direction | Contents | Rule |
|---|---|---|
| **Catalog out** | Users, machines, modules, categories, menus, screens, app settings (excluding `is_local_only`) | Centrally governed; a local installation receives and does not edit |
| **Evidence in** | TcList, test cases, steps, versions, reviews, duplicates, runs, items, results, steps, artefacts, signatures, notes, discovery logs, bugs, occurrences, history, comments, links, retests, exports, imports, AI, audit | Produced locally, consolidated centrally |

**Test cases moved from catalog to evidence in v3.** Under v7.0 the canonical test case was central property. Now a test case is stamped with its authoring machine, so it is naturally evidence-direction data.

### 10.2 The bundle

```
bundle/
  manifest.json        source machine, user, period, app + schema version,
                       per-file record counts, per-file sha256
  catalog/*.ndjson     only for a catalog bundle
  evidence/*.ndjson    ordered by dependency: tc_required_list → test_cases → steps →
                       versions → reviews → duplicates → runs → items → results →
                       result_steps → artifacts → bugs → occurrences → …
  artifacts/           optional; excluded above the configured size
```

### 10.3 Import

```
ApplyImportJob:
  1. validate manifest checksums
  2. compare schema version  → Same_Version | Migrated_On_Read | Rejected_Incompatible
  3. for each entity in dependency order:
       resolve references BY CODE (catalog, test cases) or BY (machine_id, source_id) (evidence)
       missing catalog reference   → conflict, do not create
       existing record, same code  → match, skip            ← idempotency
       existing record, different definition → conflict
       otherwise                   → create
       record the outcome in tst_import_record_map          ← reversibility
  4. summarise: created / matched / rejected / conflicts
```

**Idempotency** rests on codes for catalog and authoring data, and on `(machine_id, source_id)` for evidence. Applying the same bundle twice creates nothing.

**Reversibility** rests on `tst_import_record_map`, which records every record created or matched, with its source identity and its local id.

### 10.4 Conflicts

| Type | Meaning |
|---|---|
| `Missing_Catalog_Reference` | The bundle names a screen this installation does not have |
| `Definition_Divergence` | The same code carries a different definition here |
| `Machine_Metadata_Mismatch` | The bundle's machine profile disagrees with the registry |
| `Duplicate_Business_Code` | **Now a registration error, not a routine event** — see §10.5 |
| `Version_Incompatible` | Schema version outside the accepted range |
| `Referential_Gap` | A reference the bundle did not carry |

Both versions are retained in full (`incoming_json`, `existing_json`). A blocking conflict stops the affected records; a warning does not. **Nothing is resolved by a coin toss.**

### 10.5 A duplicate business code now means something

Under v7.0, two machines minting the same test-case number was *expected*, and the whole source/canonical layer existed to absorb it. Under v7.2 it can only mean **a machine code was reused** — two installations registered as `D02A`.

This is a registration error with serious consequences (two machines' evidence merging silently), so `Duplicate_Business_Code` is classified **Blocking** and surfaced as an operational alert, not a data-quality note.

---

## 11. Security and Access

### 11.1 What was removed

`tst_roles`, `tst_permissions`, `tst_role_permissions`, `tst_user_roles`. Four tables of matrix administration for a team where everyone does everything.

### 11.2 What replaces it

| Layer | Mechanism |
|---|---|
| Authentication | Laravel session auth; local installation, local users |
| **Role** | The `role` enum on `tst_users`: Architect, QA_Lead, Tester, Developer, Reviewer, System |
| **Ownership** | A policy check that the actor's `machine_code` matches the record's. **A test case is edited on the machine that owns its code** (BRD D-03) |
| **Judgement gates** | Three actions require QA_Lead or Architect: confirming equivalence, signing off a review, closing a bug without a passing retest |
| Audit | Every material change recorded with actor, context, IP and user agent |

### 11.3 When to revisit

Above roughly fifteen users, or on the first external contractor needing scoped access. The role enum leaves room; no data would need to migrate.

---

## 12. Phase 2 Design

### 12.1 Change requests and coverage

`tst_app_requirements` (change requests) ↔ `tst_app_requirement_test_cases` (coverage mapping, by `test_case_code`) ↔ `tst_test_case_requirements` (the test-case work backlog).

Two different things kept apart on purpose: a **change request** is about Prime-AI; a **work request** is about the test suite. Conflating them makes coverage uncountable.

### 12.2 Dependencies and path mapping

```
tst_module_dependencies      module → module, typed, weighted 1–10
tst_test_case_dependencies   test case → test case, typed, weighted, is_blocking
tst_path_mappings            glob pattern → Module | Screen | TestCase | Ignore,
                             with confidence and priority (lower wins)
```

**`is_blocking` reaches back into Phase 1.** If a prerequisite fails, the dependent test is recorded **Blocked**, not Failed. This is why `Blocked` exists as a result status from Phase 1 — the status is needed before the mechanism that produces it.

**Unresolved paths are the honesty mechanism.** A path no rule matched is counted and reported. An impact analysis that silently ignored 40% of a change is worse than no analysis, because it looks complete.

### 12.3 Git ingestion

```
tst_git_repositories   registered repo, last ingested commit
tst_git_commits        hash (VARCHAR(40) — a SHA-1 is 40 hex chars; CHAR(64) pads
                       and a hash read from `git log` never compares equal), branch,
                       parents, author resolved to a user code where possible
tst_git_commit_files   path, change type, lines, and its RESOLVED module/screen/test case
                       plus resolution_source: Test_File | Screen_Path | Path_Mapping |
                       Module_Convention | Manual | Unresolved
```

Recording *how* a resolution was reached is what lets the team improve the mapping rules: a high `Module_Convention` share means the explicit rules are thin.

### 12.4 Impact analysis

```
ImpactService::analyse(commit_range):
    files      := changed files across the range
    resolved   := PathResolver::resolve(files)         # records unresolved count
    direct     := test cases whose screen or file was touched
    dependent  := DependencyGraph::traverse(direct, max_depth)
                    confidence decays: conf(depth) = base × decay^depth
    historical := test cases that failed on similar changes before
    open_bugs  := test cases with an open bug
    critical   := test cases marked critical on affected screens

    for each candidate:
        write tst_impact_analysis_items with reason, confidence, depth, evidence_json
    for each deliberate exclusion (flaky, retired, orphaned, screen excluded):
        write the item with is_included = 0 and the reason

    status := 'Proposed'         # a person approves before anything runs
```

**Excluded items are retained with their reason.** A proposal that states what it left out and why is reviewable; one that shows only inclusions is not.

`defects_found_in_scope` and `defects_found_out_of_scope` are filled in afterwards, which is how the selection's usefulness becomes measurable (KPI K-11) rather than assumed.

---

## 13. Non-Functional Design

### 13.1 Indexing

| Table | Index | Serves |
|---|---|---|
| `tst_test_cases` | `uq (test_case_code)` | The parent key of everything |
| | `(ts_code, is_active)` | Screen catalog |
| | `(machine_code, ts_code, tc_seq_number)` | `CodeFactory` sequence allocation |
| | `(definition_hash)` | Duplicate detection |
| `tst_test_run_items` | `uq (run_id, test_case_code)` | One item per case per run |
| | `(test_case_code, created_at)` | Test case history |
| `tst_test_run_results` | `uq (run_item_id, attempt_no)` | Attempt integrity |
| | `(test_case_code, is_final_attempt, status, created_at)` | The history query |
| | `(failure_fingerprint)` | Signature grouping |
| | `(machine_id, created_at)` | Machine comparison |
| | `(environment_profile_id, status)` | Environment impact |
| `tst_bugs` | `(status, severity)` · `(assigned_to, status)` · `(test_case_code)` | Defect screens |
| `tst_schedule_targets` | `(machine_code, schedule_id)` | Dispatch |
| `tst_audit_logs` | `(table_name, record_key)` · `(created_at)` | Audit trail |

### 13.2 Archival

| Data | Policy |
|---|---|
| Results, bugs, occurrences | Indefinite |
| Artefacts | 180 days default; marked unavailable, not deleted as rows |
| Audit | 3 years default; explicit administrative archival, never a silent purge |
| Import bundles | 90 days after successful application |

### 13.3 Partitioning

Not applied. At 6,000,000 result rows, correct indexes suffice. Revisit above ~50,000,000, at which point `tst_test_run_results` would partition by `created_at` range.

---

## 14. Implementation Roadmap

### Phase 1

| Stage | Scope | Acceptance |
|---|---|---|
| **1.1 Foundation** | Settings, environment profiles, users, machines, `CodeFactory` | A machine registers and mints a valid code |
| **1.2 Catalog** | Modules → screens, with prefix and composite-key validation | The Prime-AI navigation is loaded and correct |
| **1.3 Authoring** | TcList, test cases, steps, versions, duplicates, review | A screen's required list is written, satisfied, reviewed and signed off |
| **1.4 Execution** | Runs, scopes, items, results, steps, artefacts, signatures, heartbeat | A Dusk suite runs and every attempt is evidenced |
| **1.5 Analytics** | Summary, flakiness, regression, health, rebuild job | A test case's history and reliability are readable |
| **1.6 Defects** | Known issues, bugs, occurrences, links, retest cycles | A bug goes from failure to verified closure |
| **1.7 Scheduling & Discovery** | Schedules, targets, dispatch, missed detection, source scan | A nightly run fires on two machines; discovery reports drift |
| **1.8 Sync** | Export, import, record map, conflicts, reversal | Two machines' evidence consolidates, twice, with no duplication |
| **1.9 Ops** | Notifications, audit, dashboards | The team is told what needs a decision |

### Phase 2

| Stage | Scope | Acceptance |
|---|---|---|
| **2.1 Change requests** | Requests, coverage mapping, work backlog | Coverage is countable per change |
| **2.2 Path mapping** | Patterns, priority, confidence, unresolved reporting | 90% of changed files resolve |
| **2.3 Dependencies** | Module and test-case graphs, blocking semantics | A blocked test records Blocked, not Failed |
| **2.4 Suites** | Suites, membership, versioning | A regression pass is one selection, reproducibly |
| **2.5 Git** | Repositories, commits, files, author resolution | A result ties to the commit that produced it |
| **2.6 Impact** | Analysis, items, evidence, approval, effectiveness | A commit range yields a reviewed, approved selection |

---

## 15. Testing Strategy

| Layer | Coverage |
|---|---|
| **Unit** | Code format validation · `CodeFactory` sequence allocation under concurrency · definition hash normalisation · failure normalisation · flakiness algorithm at boundary conditions · regression algorithm · confidence scoring |
| **Feature** | Every lifecycle transition including every rejected one · lock and immutability rules · idempotent import (apply twice, assert no change) · reversible import · conflict classification · retest verification including the override path |
| **Database** | That a generated column cannot be written directly · that `ON UPDATE` on a code fails · that a duplicate code is rejected · that a result cannot be updated — driven by raw SQL bypassing the model layer |
| **Integration** | Two-machine consolidation with overlapping screens and independently authored test cases; assert both survive and neither merges |
| **Performance** | 20,000 test cases, 6,000,000 results seeded: catalog list, history query, dashboard, full analytics rebuild |

The database-layer tests matter most, because §3.5 is the load-bearing part of this design and it is enforced by MySQL rather than by us.

---

## 16. Corrections to `testing_DDL_v7.1.sql`

Eighteen defects, of which **eight prevent the script from executing**.

### 16.1 Fatal

| # | Table | Defect | Fix |
|---|---|---|---|
| 1 | `tst_app_settings` | `INDEX (group_name, ordinal)` — `group_name` is not declared | Column added; it was a useful idea |
| 2 | `tst_users` | FKs on `created_by`, `updated_by`, `deleted_by` — none declared | Columns declared, self-referencing, nullable |
| 3 | `tst_users` | `INDEX (primary_role_code)` — not declared | Indexed on `role` |
| 4 | `tst_tc_required_list` | `UNIQUE KEY (tc_list_code)` — the column is `tcr_code` | Corrected |
| 5 | `tst_test_case_versions_history` | `FOREIGN KEY (test_case_id)` — the column is `test_case_code` | Corrected to the code |
| 6 | `tst_test_runs` | Generated `test_case_code` from `machine_code`, which is not declared | Column removed; §6.2 |
| 7 | Deferred block | FKs to `tst_releases` and `tst_roles`, both removed | Deleted |
| 8 | Ordering | `tst_source_test_cases` and `tst_schema_version` declared after the tables referencing them | Both removed (D-24, D-27) |

### 16.2 Width drift — every one of these is a broken foreign key

MySQL will accept differing `VARCHAR` lengths across a foreign key, which is worse than rejecting them: the constraint is created and the index is unusable for the intended lookups, and a value can be silently truncated on insert into the narrower side.

| # | Code | Declared as | Standardised to |
|---|---|---|---|
| 9 | `test_case_code` | `VARCHAR(21)` on the parent, `VARCHAR(20)` on children | **`VARCHAR(21)` everywhere** |
| 10 | `user_code` and every `*_by` column | `VARCHAR(3)` and `VARCHAR(10)` | **`VARCHAR(3)` everywhere** |
| 11 | `ts_code` | `VARCHAR(11)` and `VARCHAR(20)` | **`VARCHAR(11)` everywhere** |
| 12 | `module_code` | `VARCHAR(5)` and `VARCHAR(10)` | **`VARCHAR(5)` everywhere** |

### 16.3 Design and modelling

| # | Item | Fix |
|---|---|---|
| 13 | A run modelled as one test case | §6.2 |
| 14 | `tst_tc_required_list` has no FK on `machine_code` and none on its audit columns | Added |
| 15 | `tst_test_case_review.version_no` has no FK | **Intentional and documented** — §4.6 |
| 16 | The review unique key includes `review_date DATETIME`; two reviews in one second collide | Noted; acceptable at human review cadence. `review_date` is the business date of the review |
| 17 | `tst_bugs.module_code VARCHAR(10)` against a `VARCHAR(5)` parent | Corrected |
| 18 | Every view joins on `tc.id` | All rewritten to join on codes — §9.4 |

---

## 17. Decisions Owned by This Document

Business decisions are in BRD v3 §13. These are technical.

| # | Decision | Rationale |
|---|---|---|
| **SD-01** | Phase-1 tables declare Phase-2 columns but no Phase-2 foreign keys | An `ADD CONSTRAINT` on a multi-million-row table is an outage; an `ADD COLUMN` at build time is free |
| **SD-02** | Phase 2 adds only. No `ADD COLUMN`, no `MODIFY`, no `DROP` | Makes the Phase-2 upgrade reviewable in one read |
| **SD-03** | All code columns are `STORED`, never `VIRTUAL` | MC-1: a foreign key cannot reference a virtual generated column |
| **SD-04** | Every foreign key on a base column of a generated column is `ON DELETE RESTRICT` | MC-2: MySQL permits nothing else |
| **SD-05** | Every declaration of a given code has an identical width and collation | MC-6, and §16.2 shows what happens otherwise |
| **SD-06** | The surrogate `id` is retained on most tables, but is never a cross-machine parent key | Pagination and child-table joins still want a narrow key; identity does not |
| **SD-07** | `CodeFactory` allocates sequences under `SELECT … FOR UPDATE`, with the unique key as the backstop | Correct under concurrency without a central allocator |
| **SD-08** | Sequence numbers are never reused, even after soft delete | Reusing `001` attaches an old code to a new test |
| **SD-09** | `tst_test_case_steps` holds only the current version; history lives in `steps_json` | The grid query would otherwise filter on version on every load |
| **SD-10** | `tst_test_case_review.version_no` carries no foreign key | A version row only exists once superseded; a FK would make reviewing v1 impossible |
| **SD-11** | Results are insert-only, enforced by having exactly one writing service and no update path | Attempts, not statuses (§6.5) |
| **SD-12** | Roll-ups are recomputed, never incremented | Incremental counters drift; BRD R-13 |
| **SD-13** | `is_available = 0` rather than deleting a purged artefact row | "Evidence expired" and "never had evidence" are different facts |
| **SD-14** | `Duplicate_Business_Code` is a Blocking conflict | Under the new coding system it can only be a registration error (§10.5) |
| **SD-15** | Environment profiles are never exported or imported | A fingerprint recomputes identically anywhere; importing them would create duplicates that differ only by id |

---

## 18. Open Items

| # | Item | Status |
|---|---|---|
| **OPEN-01** | `tcr_code` pads to 4 digits, `test_case_code` to 3. Both are `VARCHAR(21)`; both work; the visual mismatch is a trap for a human comparing them | Implemented as specified. Recommend aligning to 3 / `VARCHAR(20)` |
| **OPEN-02** | 999 test cases per screen per machine | Accept; revisit above 500 on any screen |
| **OPEN-03** | Partitioning `tst_test_run_results` | Revisit above ~50M rows |
| **OPEN-04** | Roles and permissions | Revisit above ~15 users or on first external contractor |
| **OPEN-05** | Whether `Q` (QA Lead) is a needed role letter today | Cosmetic; the enum carries it |
| **OPEN-06** | **Verify on first run against real MySQL:** that a foreign key may *reference* a STORED generated column (`tst_machines.machine_code`, `tst_tc_required_list.tcr_code`, `tst_test_cases.test_case_code`). The documented MySQL restriction covers VIRTUAL generated columns only, and all three are STORED with a UNIQUE index — but this is the one load-bearing assumption in the design that has not been executed against a server. If a server rejects it, the fallback is to drop the generated clause and have `CodeFactory` write the concatenated value on insert; nothing else in the schema changes | Verify before build |

---

## 19. Design Principles — the short version

1. **A code is an identity, not a label.** It is generated, unique, permanent, and the database will not let you rename it.
2. **The machine segment is what makes independence safe.** Two people can author the same test without coordination, and consolidation still works.
3. **One table per concept.** The source/canonical split existed to solve a collision that can no longer happen.
4. **Append, never overwrite.** Results, versions, reviews, links and audit are insert-only.
5. **Derived data is rebuildable or it is not trusted.**
6. **Propose; let a person decide.** Equivalence, flakiness, bug closure and impact scope are judgements.
7. **State what you could not interpret.** An analysis that hides its blind spot is worse than none.
8. **Phase 1 must be worth having on its own**, because Phase 2 may be six months away.

---

**End of `Solution_Design_v3.md`**
