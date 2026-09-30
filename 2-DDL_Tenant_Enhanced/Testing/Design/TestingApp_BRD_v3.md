# Prime-AI Testing Application — Business Requirements Document

**Document ID:** TSTAPP-BRD-V3
**Version:** 3.0
**Status:** Approved-for-Design baseline
**Date:** 2026-09-08
**Project:** `prime_testing`

**Supersedes:** `TestingApp_BRD_v2.md` (v2.0) · `TestingApp_BRD_v1.md` (v1.0)
**Realised by:** `Solution_Design_v3.md` → `testing_DDL_v7.2.sql`
**Derived from:** `testing_DDL_v7.1.sql` — the schema as revised by the product owner

---

## 0. Document Control

### 0.1 Position in the document set

| Layer | Document | Answers |
|---|---|---|
| Business | **this document** | What the business needs, in two delivery phases |
| Solution | `Solution_Design_v3.md` | How the system works and how it is built |
| Physical | `testing_DDL_v7.2.sql` | How the information is stored |

### 0.2 Why v3 exists

Two things changed after v2 was signed off.

**1. The application became too large to build in one pass.** v2 described a single system covering catalog, authoring, execution, defects, consolidation, Git traceability, dependency mapping, impact analysis and suites. That is a correct description of the destination and an unbuildable description of the next six months. v3 splits it into **Phase 1 — Record and Diagnose** and **Phase 2 — Correlate and Select**, and the split is not arbitrary: Phase 1 is everything needed to run a test and understand its result; Phase 2 is everything needed to decide *which* tests to run after a change.

**2. The identity model changed.** v2 and `testing_DDL_v7.0.sql` used surrogate integer keys for every internal relationship, with business codes carried alongside for recognition on import. The product owner replaced this with a **self-describing composite code** in `testing_DDL_v7.1.sql`:

```
test_case_code = machine_code + '_' + ts_code + '_' + sequence
                 D02A          _     T0104010200 _     001
```

This is a better answer to the problem than the one v2 gave, and §5 explains why. It also removes an entire concept from the system — see D-24.

### 0.3 What changed from v2

| # | Change | Driver |
|---|---|---|
| C-01 | **Delivery is split into Phase 1 and Phase 2.** Every requirement, rule and table in this document carries a **[P1]** or **[P2]** marker | Scope |
| C-02 | **Business codes replace surrogate ids as the relational key** for test cases, machines, users, screens and the catalog hierarchy | Owner decision (§5) |
| C-03 | **A test case is stamped with the machine that authored it**, so two people authoring independently can never collide | Owner decision |
| C-04 | **The Source Test Case concept is retired** (D-24). C-03 makes it unnecessary | Consequence of C-03 |
| C-05 | **Role and permission tables are removed.** A single role enum on the user record replaces them | Owner decision — small team |
| C-06 | **The Release entity is removed.** Release readiness is expressed through test-case review and sign-off | Owner decision |
| C-07 | **Test-case review and release becomes a first-class record** — reviewer, approver, readiness score, sign-off | New table `tst_test_case_review` |
| C-08 | **The required-test-case list (TcList) becomes a tracked backlog**, not a markdown file with a status column | New table `tst_tc_required_list` |
| C-09 | **Duplicate detection between test cases becomes explicit and decision-tracked** | New table `tst_duplicate_test_case` |
| C-10 | **Scheduling gains explicit targets**: which machine runs which module, screen or test case | New table `tst_schedule_targets` |
| C-11 | **Business codes are immutable once used.** This is now a rule, not a convention — §5.4 explains why the database enforces it whether we like it or not | Consequence of C-02 |
| C-12 | Eighteen defects in `testing_DDL_v7.1.sql` are identified and corrected | §17 |

### 0.4 The phase split in one sentence each

> **Phase 1 — Record and Diagnose.** A tester can plan, author, review, schedule, execute and evidence a test on their own machine; a lead can read what happened, raise and track a bug to verified closure, and consolidate every machine's evidence into one place.

> **Phase 2 — Correlate and Select.** The application can say *which* tests a given change requires, because it knows what changed in Git, which files map to which screens, what depends on what, and which tests belong to which suite.

---

# Part I — Business Context

## 1. Purpose

The Prime-AI Testing Application exists so that the quality of Prime-AI is a matter of **recorded evidence rather than recollection**.

It is installed locally on each developer and tester machine, with one central installation that consolidates evidence from all of them and governs the shared catalog. It discovers automated tests from the Prime-AI source tree, executes them, records every attempt with its evidence, groups recurring failures, manages defects through verified retest, and — in Phase 2 — proposes which tests a given code change requires.

## 2. Business Background

Prime-AI is a multi-tenant K-12 school management platform of roughly fifty modules. Testing today is distributed across a small team, each person working on their own machine, with results living in spreadsheets, terminal scrollback and memory.

The consequences are specific and measurable:

| Problem | What it costs |
|---|---|
| Nobody can state current test coverage per screen | Release decisions are made on feel |
| A failure's history is unavailable | The same defect is re-diagnosed repeatedly |
| Two testers write the same test independently | Duplicate effort, contradictory results |
| "Fixed" is not distinguished from "verified fixed" | Defects reach users |
| A flaky test is indistinguishable from a real failure | Real failures are ignored |
| After a change, nobody knows what to re-run | Either everything is run, or nothing is |

## 3. Business Problem

> **The organisation cannot answer basic questions about its own testing from recorded data, and therefore cannot improve it.**

Phase 1 makes the answers recordable. Phase 2 makes them actionable.

## 4. Glossary — Canonical Vocabulary

**Binding.** Where any later document, screen, report or table uses one of these words, it uses it with this meaning only. Terms new in v3 are marked *(v3)*; retired terms are listed at the end.

| Term | Definition |
|---|---|
| **Module** | A top-level functional area of Prime-AI (Fees, Examination, Student Profile) |
| **Category** | A grouping within a module |
| **Main Menu / Sub Menu** | Navigation levels within a category; sub menu is optional |
| **Screen (Tab/Screen)** | The smallest addressable, testable surface of Prime-AI, identified by `ts_code` |
| **User Code** *(v3)* | A person's stable 3-character identity: role letter + two digits, e.g. `D02` |
| **Machine Number** *(v3)* | A single letter distinguishing one person's machines: `A`, `B`, `C` … |
| **Machine Code** *(v3)* | `user_code + machine_number`, e.g. `D02A`. Four characters. Identifies an installation *and its owner* in one token |
| **Screen Code (`ts_code`)** | An 11-character positional code carrying category, main menu, sub menu and screen: `T0104010200` |
| **Required Test Case (TcList entry)** *(v3)* | A planned test case for a screen, before it is written. Identified by `tcr_code` |
| **Test Case** | A defined, repeatable verification of one behaviour of one screen |
| **Test Case Code** *(v3)* | `machine_code + '_' + ts_code + '_' + sequence`, e.g. `D02A_T0104010200_001`. **Globally unique without coordination.** The relational key of the whole system |
| **Test Case Version** | An immutable snapshot of a test case definition at a point in time |
| **Test Step** | An ordered instruction plus expected result within a manual or hybrid test case |
| **Test Case Review** *(v3)* | The record of a test case being reviewed, scored for readiness and signed off for release |
| **Duplicate Link** *(v3)* | A recorded judgement that two test cases are the same, equivalent, variant or distinct |
| **Test Run** | One execution *event*, with a scope, a trigger, an environment and a code version |
| **Run Item** | One test case selected into one run, with the reason it was selected |
| **Attempt** | One execution of one run item |
| **Result** | The outcome of one attempt: Passed, Failed, Error, Skipped, Blocked or Not Executed |
| **Evidence** | Artefacts retained with a result: message, trace, screenshot, console log, page source, video |
| **Failure Signature** | A normalised fingerprint of a failure, used to group recurring identical failures |
| **Bug** | A confirmed or suspected defect in Prime-AI. One bug is one problem |
| **Bug Occurrence** | One observation of one bug in one result |
| **Known Issue** | An accepted, documented problem whose recurrence is expected and must not be re-triaged |
| **Retest Cycle** | One managed attempt to verify one or more fixed bugs, including its regression scope |
| **Flaky Test** | A test whose outcome changes under materially unchanged conditions |
| **Environment Profile** | The identified combination of OS, runtime, browser, database and configuration under which a run executed |
| **Machine** | A registered installation of the Testing Application. Distinct from the user operating it |
| **Consolidation** | Bringing testing information from separate machines into one analysable body without losing its origin |
| **Change Request** *(v3, P2)* | A statement of an enhancement or change to Prime-AI. Replaces "Application Requirement" |
| **Path Mapping** *(P2)* | A rule resolving a source file path to a module, screen or test case |
| **Impact Analysis** *(P2)* | A reviewable proposal of which test cases a given change may affect |
| **Test Suite** *(P2)* | A named, reusable collection of test cases (Smoke, Regression, Release) |

**Retired in v3:** *Source Test Case* (D-24) · *Role* and *Permission* as entities (D-25) · *Release* as an entity (D-26).

## 5. The Identity Model — the central decision of v3

### 5.1 What changed

`testing_DDL_v7.0.sql` used three identities: a surrogate integer for joins, a business code for recognition, and a `(machine_id, source_id)` pair for records created independently on many machines. Children joined to `tst_test_cases.id`.

v7.1 collapses the first two for the entities that travel between machines. A test case's relational key **is** its business code, and that code is built from parts that are already unique:

```
   D02A        _   T0104010200    _   001
   ↑               ↑                  ↑
   machine_code    ts_code            sequence within that screen on that machine
   ↑
   D02  +  A
   user    machine number
```

### 5.2 Why this is the right answer

| Property | How the composite code delivers it |
|---|---|
| **Unique across machines without coordination** | The machine segment makes collision structurally impossible. No central number allocator, no UUID |
| **Readable** | A human reads `D02A_T0104010200_001` and knows the author, the machine, the screen and the sequence. `id = 41,207` tells them nothing |
| **Stable across import** | A local `id` differs on every machine; the code does not. Import matches on the code and nothing has to be re-mapped |
| **Self-describing in evidence** | A test-case code appearing in a log, a screenshot filename or a Dusk output line is fully resolvable without a database lookup |
| **Removes a whole concept** | See D-24 |

### 5.3 What it costs, honestly

| Cost | Assessment |
|---|---|
| 21 bytes per index entry instead of 4 | Real, and acceptable at this system's scale. §14.2 sizes it |
| Codes cannot be renamed once used | Not a cost — a discipline. See §5.4 |
| A test case cannot be moved between screens | Correct behaviour: a test of a different screen is a different test |
| A machine cannot be reassigned to another user | Correct: `D02A` means "Tarun's first machine" permanently. A new owner registers a new machine code |

### 5.4 Business codes are immutable once used

**BR-CODE-05 [P1] — A business code, once referenced by any record, can never be changed.**

This is not a policy the team may relax. `machine_code` and `test_case_code` are *generated* columns, and MySQL forbids `ON UPDATE CASCADE` on a foreign key whose column feeds a generated column. There is therefore no mechanism by which a rename could propagate. The correct operation is always: deactivate the old code, create a new one, record the relationship.

Naming a screen, a user or a machine is consequently a **decision, not a data-entry step**, and §9.2 makes the registration of both centrally controlled.

---

# Part II — Delivery Phases

## 6. Phase Definition

### 6.1 Phase 1 — Record and Diagnose

**Business acceptance:** *A tester can plan, author, review, schedule, execute and evidence a full day's testing on their own machine; a QA Lead can read it the next morning, raise and drive a bug to verified closure, and consolidate every machine's evidence into one analysable body.*

| # | Capability | Requirements |
|---|---|---|
| 1 | Application Configuration | §9.1 |
| 2 | Machine Environment Profile | §9.2 |
| 3 | User Profile Management | §9.3 |
| 4 | Machine Profile per User | §9.4 |
| 5 | Catalog Management | §9.5 |
| 6 | Test Case Profile (TcList, cases, steps, versions, duplicates, review/release) | §9.6 – §9.10 |
| 7 | Test Case Execution | §9.11 – §9.13 |
| 8 | Test Execution Scheduling | §9.14 |
| 9 | Comments Management | §9.15 |
| 10 | Discovery | §9.16 |
| 11 | Execution History and Trending | §9.17 – §9.19 |
| 12 | Bug Management | §9.20 – §9.23 |
| 13 | Export / Import Management | §9.24 |
| 14 | AI Analysis | §9.25 |
| 15 | Notifications and Audit | §9.26 – §9.27 |

### 6.2 Phase 2 — Correlate and Select

**Business acceptance:** *Given a commit range, the application proposes the set of test cases that change requires, states the evidence for each inclusion and each deliberate exclusion, and a QA Lead approves or amends the proposal before it runs.*

| # | Capability | Requirements |
|---|---|---|
| 16 | Change Request Management | §10.1 |
| 17 | Dependency Management | §10.2 |
| 18 | Application Path Mapping | §10.3 |
| 19 | Test Suites | §10.4 |
| 20 | Git Ingestion Engine | §10.5 |
| 21 | Impact Analysis and Test Selection | §10.6 |

### 6.3 The rule that keeps the phases separable

**BR-PHASE-01 [P1] — Phase 1 must be complete, installable and useful with no Phase 2 table present.**

Phase-1 records may carry *columns* that will later point at Phase-2 entities (a run may name a suite; a bug may name a change request). Those columns are declared in Phase 1 and left null. **Their foreign keys are added by the Phase-2 installation, never before.** Phase 2 therefore adds constraints and tables; it never alters a Phase-1 column.

The reason is practical: `tst_test_run_results` will hold millions of rows by the time Phase 2 ships, and an `ALTER TABLE` that rewrites it is an outage.

---

# Part III — Operating Model

## 7. Local-First, Centrally Consolidated

```
   ┌────────────────────────────────────────────────────────────────────┐
   │                      PRIME-AI SOURCE TREE                          │
   │        Modules/*   ·   tests/Browser/*   ·   .git history          │
   └─────────────┬───────────────────────────────────┬──────────────────┘
                 │ discovery [P1]                    │ git ingestion [P2]
                 ▼                                   ▼
   ┌────────────────────────────────────────────────────────────────────┐
   │        TESTING APPLICATION — local installation  (machine D02A)    │
   │                                                                    │
   │   Catalog   Authoring   Execution   Evidence   Defects   Analysis  │
   │                                                                    │
   │   Every test case authored here is stamped D02A_…                  │
   └─────────────┬───────────────────────────────────▲──────────────────┘
                 │ evidence bundle out               │ catalog bundle in
                 ▼                                   │
   ┌─────────────────────────────────────────────────┴──────────────────┐
   │        TESTING APPLICATION — central installation  (machine A01A)  │
   │   Consolidated evidence · Catalog governance · Cross-machine view  │
   └────────────────────────────────────────────────────────────────────┘
```

**Two directions, two different rules:**

| Direction | Contents | Rule |
|---|---|---|
| **Catalog out** (central → local) | Users, machines, modules, categories, menus, screens, app settings | Centrally governed. A local installation receives these and does not edit them |
| **Evidence in** (local → central) | Test cases, TcList entries, reviews, runs, results, artefacts, bugs, occurrences, retests, notes, discovery logs, audit | Produced locally, consolidated centrally. Origin is preserved |

**BR-OPMODEL-04 [P1] — Test cases travel with the evidence, not with the catalog.** In v7.0 the canonical test case was central property. Under the new coding system a test case is stamped with the machine that authored it, so it is naturally evidence-direction data. The central installation holds every machine's test cases side by side; equivalence between them is a recorded judgement (§9.10), never an automatic merge.

## 8. Business Conditions

| ID | Condition | Phase |
|---|---|---|
| BC-01 | Every installation runs the full schema for its phase; there is no cut-down client | P1 |
| BC-02 | No feature except consolidation may require the central installation to be reachable | P1 |
| BC-03 | Users and machines are registered centrally by one accountable administrator | P1 |
| BC-04 | A machine id is issued centrally and inserted explicitly; a local database never auto-increments its own | P1 |
| BC-05 | Recorded results are insert-only. Nothing in the application may update a result status | P1 |
| BC-06 | Derived statistics must be rebuildable from recorded results alone | P1 |
| BC-07 | An import is idempotent: applying the same bundle twice changes nothing | P1 |
| BC-08 | An import is reversible: every record it created can be identified and withdrawn | P1 |
| BC-09 | AI output is a proposal with evidence and a review state; it never mutates record data | P1 |
| BC-10 | Every automated action has an owner, a reason and a bound | P1 |
| BC-11 | Central accepts a bundle from the current schema version or one prior minor version | P1 |
| BC-12 | Phase 2 adds tables and constraints only; it never rewrites a Phase-1 table | P2 |
| BC-13 | Impact analysis proposes; a person approves before anything runs | P2 |

---

# Part IV — Phase 1 Business Requirements

## 9.1 Application Configuration **[P1]**

**REQ-CFG-01** — The application shall hold configuration as typed key/value settings with a description, so a setting's meaning is discoverable without reading code.

| Rule | Statement |
|---|---|
| BR-CFG-01 | A setting marked `is_system` ships with the application and cannot be deleted |
| BR-CFG-02 | A setting marked `is_local_only` **never travels in a catalog bundle** — paths, machine specifics and credentials stay on the machine they describe |
| BR-CFG-03 | A setting marked `is_editable = 0` is read-only in the UI; changing it is a code change |
| BR-CFG-04 | Settings are maintained centrally by the administrator and distributed by seeder; a local user may change only editable values |
| BR-CFG-05 | The schema version the database is at is held as a setting and compared by the import validator (D-27) |

**Settings the business has committed to:** maximum automatic retest attempts · automatic retest on/off · automatic bug creation on/off · bug-fix SLA hours · central mode · allow multi-machine import · default regression look-back days · artefact retention days · audit retention days.

## 9.2 Machine Environment Profile **[P1]**

**REQ-ENV-01** — Every run shall record the environment it executed in, identified by a **repeatable fingerprint over its material attributes**, not by free text.

Material attributes: OS name and version · PHP version · Laravel version · database engine and version · browser name and version · driver version · application environment and version · configuration profile.

| Rule | Statement |
|---|---|
| BR-ENV-01 | The fingerprint is a hash of the normalised attributes. An identical environment produces an identical fingerprint on any machine |
| BR-ENV-02 | A newly seen fingerprint creates a profile automatically; a person may name it afterwards |
| BR-ENV-03 | Environment profiles are **never exported or imported**. They are derived facts about a machine, and a fingerprint recomputes identically anywhere |
| BR-ENV-04 | A result that cannot be compared to another result **in the same environment** is not evidence of a regression |

> **Why this matters more than it sounds.** "It fails on my machine" is the single most expensive sentence in testing. This requirement is what turns it into "it fails on Windows with Chrome 141 and passes on Chrome 140", which is a fixable statement.

## 9.3 User Profile Management **[P1]**

**REQ-USER-01** — Every action in the system shall be attributable to a person.

**The user code** is `role letter + two digits`: `A01` Architect, `Q01` QA Lead, `T01` Tester, `D02` Developer, `R01` Reviewer, `S01` System.

| Rule | Statement |
|---|---|
| BR-USER-01 | The user code is the primary key. It appears in every `created_by`, `updated_by`, `deleted_by`, and inside every machine code and test case code |
| BR-USER-02 | **Micro-level permissions are not implemented (D-25).** A single role enum on the user record governs access. The team is small and everybody does everything |
| BR-USER-03 | Users are created centrally by the administrator and distributed by seeder. A local user may change only their own password |
| BR-USER-04 | System actors (scheduler, importer, retest engine) are users flagged `is_system`, so an automatic action is attributable to a named actor rather than to nobody |
| BR-USER-05 | A user is deactivated, never deleted. Their code appears in historical evidence permanently |
| BR-USER-06 | **A user code, once issued, is never reissued to a different person.** It is embedded in every test case that person authored |

> **On removing roles and permissions.** v2 specified a role/permission matrix across four tables. For a team of six where everyone does everything, that is administrative overhead protecting nothing. If the team grows past roughly fifteen, or if an external contractor needs scoped access, revisit — the role enum leaves room for it, and no data would need to migrate.

## 9.4 Machine Profile per User **[P1]**

**REQ-MACH-01** — Every installation shall be registered, owned by a named user, and profiled.

**The machine code** is `user_code + machine_number`: `D02A` is Tarun's first machine, `D02B` his second.

| Rule | Statement |
|---|---|
| BR-MACH-01 | User and machine are different concepts. The same person on two machines is two machine codes; two people cannot share one |
| BR-MACH-02 | Machine ids are issued centrally and inserted explicitly. Id 1 is the central installation; local machines start at 10 |
| BR-MACH-03 | A machine records its hardware and software profile: name, model, OS, architecture, hostname, hardware serial, app version, schema version, and its two local paths (Prime-AI repository, evidence root) |
| BR-MACH-04 | The **11 profile fields are the only fields a local user may edit.** Ownership, code, status and central flag are administrator-controlled |
| BR-MACH-05 | A machine fingerprint is recomputed at every boot; a mismatch is reported, not silently accepted |
| BR-MACH-06 | A machine is retired, never deleted |
| BR-MACH-07 | **The machine profile is what separates "the application is broken" from "your machine is different".** A failure on `D02A` that passes on `T01A` with a different browser version is an environment finding, not a defect |

## 9.5 Catalog Management **[P1]**

**REQ-CAT-01** — The application shall hold the Prime-AI navigation structure so every test case maps to a real screen.

```
Module (SLB)
  └── Category (T01)
        └── Main Menu (T0104)
              └── Sub Menu (T010401)          ← optional
                    └── Tab/Screen (T0104010200)
                          └── Test Case (D02A_T0104010200_001)
```

| Rule | Statement |
|---|---|
| BR-CAT-01 | Each level's code **contains its parent's code as a prefix**. `T0104010200` is provably a screen under sub menu `T010401`, under main menu `T0104`, under category `T01` |
| BR-CAT-02 | Parentage is additionally enforced by composite foreign keys, so a main menu cannot belong to a category in a different module |
| BR-CAT-03 | Sub menu is optional; a screen may hang directly off a main menu |
| BR-CAT-04 | The catalog is centrally governed and distributed by seeder. Local users do not edit it |
| BR-CAT-05 | A screen carries the status of its **whole authoring pipeline**: requirement document, TcList, development, test-case creation, test-run status |
| BR-CAT-06 | A screen may be **excluded from testing with a stated reason and a named person**. It is never deleted |
| BR-CAT-07 | A screen records **how it was found** — manually, by discovery, or automatically — and whether a person has reviewed it |
| BR-CAT-08 | Catalog entities are deactivated, never deleted, while any test case references them |

## 9.6 Required Test Case List (TcList) **[P1]**

**REQ-TCL-01** — Before test cases are written for a screen, the required list shall be recorded, so that "what should exist" is separable from "what does exist".

| Rule | Statement |
|---|---|
| BR-TCL-01 | A TcList entry is identified by `tcr_code` = `machine_code + '_' + ts_code + '_' + list number` |
| BR-TCL-02 | An entry carries the requirement text and the required steps in business language, before any code exists |
| BR-TCL-03 | An entry carries a creation status: Planned, Pending, In-Progress, Ready, In-Review, Released, Error, Cancelled, Rolled Back, Hold, Not Required |
| BR-TCL-04 | **A test case is created against a TcList entry.** Coverage of a screen is measured as entries with a released test case ÷ total entries |
| BR-TCL-05 | An entry marked Not Required carries a reason and is excluded from the coverage denominator |
| BR-TCL-06 | A TcList entry is never deleted once a test case references it |

> **Why this is worth a table.** Today the required list is a markdown file with a status column. A file cannot be counted, queried, assigned or reported on. This is the difference between "we think Fees is about half tested" and "Fees has 214 required cases, 168 released, 31 in progress, 15 not started".

## 9.7 Test Case Management **[P1]**

**REQ-TC-01** — A test case is a defined, repeatable verification of one behaviour of one screen, identified by `test_case_code`.

| Rule | Statement |
|---|---|
| BR-TC-01 | `test_case_code` = `machine_code + '_' + ts_code + '_' + sequence`, generated by the database, never typed |
| BR-TC-02 | The code is **globally unique without coordination**. Two people authoring the same test on the same screen produce two different codes, both valid |
| BR-TC-03 | A test case carries its automation coordinates where automated: file path, namespace, class, method |
| BR-TC-04 | A test case carries type, method, technology, layer, criticality and creation status |
| BR-TC-05 | A test case carries a **definition hash** over its normalised definition including ordered steps. This drives versioning and duplicate detection |
| BR-TC-06 | A test case whose implementation has disappeared from the source tree is marked **orphaned**, with the date last seen. It is never deleted |
| BR-TC-07 | A test case is retired with a reason and a named person, never deleted |
| BR-TC-08 | A test case cannot be moved to a different screen. Its code says which screen it belongs to. Testing a different screen is a different test case |
| BR-TC-09 | Every state change of a test case is attributable and timestamped |

## 9.8 Manual Test Cases and Steps **[P1]**

**REQ-TC-10** — Manual and hybrid test cases shall carry ordered steps, each with an action, an expected result and optional test-data notes.

| Rule | Statement |
|---|---|
| BR-STEP-01 | Steps are ordered from 1 and unique within a test case |
| BR-STEP-02 | The steps table holds **only the current version**. Historical steps live in the version snapshot, so a manual tester is never shown a step list that has since changed |
| BR-STEP-03 | A step may be marked optional |
| BR-STEP-04 | Manual execution records a per-step outcome, and evidence is **mandatory for any Failed or Blocked step** |

## 9.9 Test Case Versioning **[P1]**

**REQ-TC-20** — When a test case definition changes materially, the previous definition shall be preserved.

| Rule | Statement |
|---|---|
| BR-VER-01 | A new version is written when the definition hash changes |
| BR-VER-02 | A version snapshot is **immutable** and carries the full definition including the ordered steps as they then stood |
| BR-VER-03 | A historical result renders against the version that was current when it ran |
| BR-VER-04 | A version records the commit hash it was captured from, where known |
| BR-VER-05 | Version numbers are sequential per test case and never reused |

## 9.10 Test Case Review, Release and Duplication **[P1]**

**REQ-TC-30** — A test case shall be reviewed and signed off before it is treated as released.

This replaces the Release entity of v2 (D-26). The unit of release is the **test case**, not a named delivery.

| Rule | Statement |
|---|---|
| BR-REV-01 | A review records the test case, the version reviewed, the machine, and the review date |
| BR-REV-02 | A review carries a **readiness score and assessment** — completeness, correctness, bug-free status |
| BR-REV-03 | A review carries a **technical review note**: step correctness, script logic, assertion accuracy, quality, suggestions |
| BR-REV-04 | A review carries a **sign-off note**: authorisation, risk acceptance, release clearance |
| BR-REV-05 | Reviewer and approver are separately recorded. They may be different people and the record must show which was which |
| BR-REV-06 | A review records whether the test case itself contains a defect, and whether known issues are in scope |
| BR-REV-07 | **A review is retained as issued.** Later data never retrospectively alters an assessment |
| BR-REV-08 | A test case may be reviewed repeatedly; each review is a separate record against a version |

**REQ-TC-40 — Duplicate management.** Because two people may legitimately author the same test on different machines, the system shall record the judgement about whether they are the same.

| Rule | Statement |
|---|---|
| BR-DUP-01 | A link records two test case codes and a relationship: Proposed Equivalent, Confirmed Equivalent, Confirmed Different, Duplicate Of, Variant Of, Supersedes |
| BR-DUP-02 | A proposal carries a **score and the evidence** the system relied on |
| BR-DUP-03 | **Equivalence is confirmed by a QA Lead or Architect, never automatically.** Two tests that look alike may verify different things |
| BR-DUP-04 | Links are **insert-only**. A reversal writes a new row and supersedes the old, so the decision history survives |
| BR-DUP-05 | A confirmed duplicate is not deleted. Both test cases keep their evidence; reporting counts the primary |

## 9.11 Test Execution **[P1]**

**REQ-EXEC-01** — A test run is one execution event with a scope, a trigger, an environment, a code version and a set of selected test cases.

| Rule | Statement |
|---|---|
| BR-EXEC-01 | Every run records the **user and the machine** that ran it, as codes |
| BR-EXEC-02 | Initiator and executor are recorded separately. A scheduled run is initiated by a person and executed by the system user |
| BR-EXEC-03 | Every run records the **code version under test**: repository, branch, commit hash, and whether the working tree was dirty. A result without this cannot be interpreted historically |
| BR-EXEC-04 | Every run item records **why that test case was selected** |
| BR-EXEC-05 | A run has a heartbeat. A run whose heartbeat stops is moved to **Interrupted**, retaining every result already recorded. It is not silently left Running |
| BR-EXEC-06 | Run roll-up counts are recomputed from results, never incremented ad hoc |
| BR-EXEC-07 | A run may be cancelled with a named person and a reason |
| BR-EXEC-08 | A run item records snapshots of the test case name, path and criticality **at selection time**, so a historical run renders as it then was |

## 9.12 Test Results and Evidence **[P1]**

**REQ-RES-01** — One row per attempt. Insert-only.

| Rule | Statement |
|---|---|
| BR-RES-01 | Result statuses are **Passed, Failed, Error, Skipped, Blocked, Not Executed**. Blocked and Not Executed are distinct from Failed — a blocked test recorded as failed inflates defect counts |
| BR-RES-02 | A run item may have several attempts; exactly one is marked final |
| BR-RES-03 | **Nothing in the application may update a result status.** A re-execution is a new attempt |
| BR-RES-04 | A failed result carries error message, trace, exception class and a normalised failure fingerprint |
| BR-RES-05 | A result carries a **triage state**: Untriaged, New Bug, Existing Bug, Known Issue, Flaky, Environment, Test Defect, Data Issue, Expected. **A failure is not automatically a bug** |
| BR-RES-06 | Evidence artefacts are separate records: screenshot, console log, page source, video, network log, raw output, trace, attachment |
| BR-RES-07 | An artefact purged by retention is marked unavailable with the date. The result shows "evidence expired" rather than appearing never to have had any |
| BR-RES-08 | Identical artefacts are stored once and referenced many times, by content hash |

## 9.13 Failure Grouping **[P1]**

**REQ-RES-10** — Recurring identical failures shall be grouped by a normalised signature.

| Rule | Statement |
|---|---|
| BR-SIG-01 | A signature is a fingerprint over the exception class, the normalised message and the top application frames, with vendor frames removed |
| BR-SIG-02 | A signature carries its occurrence count, distinct test cases and distinct machines |
| BR-SIG-03 | Once triaged, a signature carries its bug or known issue, and later matching failures are attributed automatically |
| BR-SIG-04 | **Grouping is what turns forty failures into one problem.** Without it, triage volume scales with test count rather than defect count |

## 9.14 Test Execution Scheduling **[P1]**

**REQ-SCHED-01** — Test execution shall be schedulable, on nominated machines, for nominated modules, screens or test cases.

| Rule | Statement |
|---|---|
| BR-SCHED-01 | A schedule has a cron expression, a timezone, an owner and a catch-up policy |
| BR-SCHED-02 | A schedule carries **explicit targets**: each target names what to run (module, screen or test case) and **which machine runs it** |
| BR-SCHED-03 | One schedule may target several machines. Fees on `D02A` and Examination on `T01A` may be one nightly schedule |
| BR-SCHED-04 | A schedule that did not fire is recorded as **missed**, not silently skipped |
| BR-SCHED-05 | A schedule may be suspended with a reason, distinct from being deactivated |
| BR-SCHED-06 | A schedule records its last run, last status and missed count |
| BR-SCHED-07 | A schedule's owner is answerable when it fails or is missed |

## 9.15 Comments Management **[P1]**

**REQ-NOTE-01** — Reviewers and developers shall be able to annotate runs and results.

| Rule | Statement |
|---|---|
| BR-NOTE-01 | A note attaches to a run, or to one specific result within it |
| BR-NOTE-02 | A note is attributed to a named user and timestamped |
| BR-NOTE-03 | A note may attribute a failure to a known issue |
| BR-NOTE-04 | Notes are evidence and consolidate with the run they belong to |

## 9.16 Discovery **[P1]**

**REQ-DISC-01** — The application shall scan the Prime-AI source tree and reconcile what it finds against the catalog.

| Rule | Statement |
|---|---|
| BR-DISC-01 | A discovery run is logged with its mode, the commit scanned, the folder, its duration and its outcome |
| BR-DISC-02 | Discovery reports **new test cases found**, added, updated, orphaned and unchanged |
| BR-DISC-03 | Discovery reports **missing modules and screens** — code that exists with no catalog entry |
| BR-DISC-04 | Discovery reports **orphaned test cases** — catalog entries whose implementation has gone |
| BR-DISC-05 | **Discovery never deletes.** It proposes; items await review |
| BR-DISC-06 | Discovery synchronises test-case status from the source tree, so the catalog reflects what actually exists |
| BR-DISC-07 | A discovery run is idempotent: rescanning an unchanged tree changes nothing |

## 9.17 Test History and Trending **[P1]**

**REQ-HIST-01** — Every test case shall carry its full execution history and a derived current picture.

| Rule | Statement |
|---|---|
| BR-HIST-01 | History is queryable per test case, per screen, per module, per machine and per environment |
| BR-HIST-02 | A summary carries first run, last run, last status, last pass, last fail, consecutive failures, consecutive passes, totals by status, pass rate over 30 days and overall, average and maximum duration, distinct machines and environments |
| BR-HIST-03 | **The summary is derived and never authoritative.** Every column must be reproducible from recorded results alone, and a nightly job compares the incremental values against a full rebuild |
| BR-HIST-04 | A summary records its rebuild provenance, so it can always be shown to be current with the evidence |
| BR-HIST-05 | A test case carries a **health status**: Healthy, Unstable, Frequently Failing, Obsolete, Blocked, Insufficient History, Under Investigation, Orphaned |

## 9.18 Flaky Test Identification **[P1]**

**REQ-FLAKY-01** — A test whose outcome changes under materially unchanged conditions shall be identified.

| Rule | Statement |
|---|---|
| BR-FLAKY-01 | **Definition:** two or more outcome alternations within the last 10 executions, in the same environment, with no intervening change to the test case or the covered code |
| BR-FLAKY-02 | A candidate is proposed by the system; **confirmation is a human decision** with a named person |
| BR-FLAKY-03 | The evidence — the outcome series, the environment and the change check — is retained so the conclusion can be re-argued a year later |
| BR-FLAKY-04 | A confirmed flaky test is excluded from regression alerting but **never from execution**. Excluding it from execution destroys the evidence needed to fix it |

## 9.19 Consecutive Failures and Regression **[P1]**

**REQ-REG-01** — A test that previously passed and now fails shall be identified as a regression candidate.

| Rule | Statement |
|---|---|
| BR-REG-01 | **Definition:** passed at least once in the last 30 days, in a comparable environment, now failing, and not confirmed flaky |
| BR-REG-02 | Consecutive failure count is maintained per test case and drives escalation |
| BR-REG-03 | A regression in a **critical** test case raises a notification immediately |
| BR-REG-04 | In Phase 1 a regression is reported. **Attributing it to a specific commit is Phase 2** (§10.5, §10.6) |

## 9.20 Bug Management **[P1]**

**REQ-BUG-01** — A bug is one problem in Prime-AI. One bug has many occurrences.

| Rule | Statement |
|---|---|
| BR-BUG-01 | **A failure is not a bug.** It may be a new bug, a known bug, a flaky test, an environment problem, a data problem, or expected behaviour |
| BR-BUG-02 | A bug carries a distributed identity — origin machine and source id — so it can be raised on any machine and consolidated without collision |
| BR-BUG-03 | A bug carries a display code, e.g. `BUG-000412` |
| BR-BUG-04 | A bug carries module, screen and, where applicable, the test case code that detected it |
| BR-BUG-05 | A bug carries severity, priority, status, resolution and root cause category |
| BR-BUG-06 | A bug records the environment profile and the commit hash it was observed at |
| BR-BUG-07 | Lifecycle: Open → Assigned → In Progress → Fixed → Retesting → Closed, with Reopened, Escalated, Won't Fix and Duplicate as branches |
| BR-BUG-08 | Every status transition is recorded with from-status, to-status, from-assignee, to-assignee, actor and whether it was a system action |
| BR-BUG-09 | An SLA due date is set on assignment; breach is recorded, not merely alerted |

## 9.21 Bug Occurrences and Relationships **[P1]**

| Rule | Statement |
|---|---|
| BR-OCC-01 | Every observation of a bug in a result is an occurrence. **Bug and occurrence are different concepts**; conflating them inflates defect counts |
| BR-OCC-02 | An occurrence records how it was matched: manually, by fingerprint, or by AI proposal |
| BR-LINK-01 | Bugs may be linked: Proposed Duplicate, Duplicate Of, Related, Blocks, Blocked By, Caused By, Causes, Regression Of |
| BR-LINK-02 | A proposed link carries a score and its evidence; confirmation is a human decision |
| BR-LINK-03 | Bug links are insert-only; a reversal supersedes rather than deletes |

## 9.22 Known Issues **[P1]**

**REQ-KNOWN-01** — An accepted, documented problem whose recurrence is expected shall not be re-triaged as new.

| Rule | Statement |
|---|---|
| BR-KNOWN-01 | A known issue carries a rationale — **why it is accepted rather than fixed** |
| BR-KNOWN-02 | A known issue may carry a failure fingerprint, so matching failures are attributed automatically |
| BR-KNOWN-03 | Every recurrence stays recorded and countable |
| BR-KNOWN-04 | A known issue has a **review due date**. On expiry it reverts to normal defect treatment and notifies its owner |
| BR-KNOWN-05 | A known issue may be promoted to a bug, retaining its occurrence history |
| BR-KNOWN-06 | A known issue has a named owner |

## 9.23 Retesting **[P1]**

**REQ-RETEST-01** — **Fixed does not equal verified.** Only a passing retest verifies a fix.

| Rule | Statement |
|---|---|
| BR-RETEST-01 | Marking a bug Fixed triggers a retest cycle where automatic retest is enabled |
| BR-RETEST-02 | A cycle records its trigger, its scope policy and its outcome |
| BR-RETEST-03 | Default scope: the failing test case, plus other test cases on the same screen, plus tests directly dependent on it *(the dependency limb activates in Phase 2)* |
| BR-RETEST-04 | **The original failure is preserved.** A retest never overwrites the evidence of what went wrong |
| BR-RETEST-05 | Retest cycles are numbered per bug and bounded by the configured maximum, after which the bug escalates |
| BR-RETEST-06 | A bug may be closed without a passing retest **only with an explicit override and a stated reason**, which is recorded and reportable |
| BR-RETEST-07 | One cycle may verify several bugs |

## 9.24 Export, Import and Consolidation **[P1]**

**REQ-SYNC-01** — Evidence created on separate machines shall be consolidated without losing its origin.

| Rule | Statement |
|---|---|
| BR-SYNC-01 | An export bundle carries a manifest: counts, per-file checksums, period and source identity |
| BR-SYNC-02 | An export declares its direction: **evidence out** or **catalog out** |
| BR-SYNC-03 | An import is **idempotent**. Applying the same bundle twice creates nothing new |
| BR-SYNC-04 | Idempotency rests on the code system for catalog and test-case data, and on `(origin machine, source id)` for evidence |
| BR-SYNC-05 | Every record an import creates or matches is recorded in a **record map**, which is what makes the import reversible |
| BR-SYNC-06 | An import is reversible with a named person and a reason |
| BR-SYNC-07 | A conflict is **queued, never resolved by a coin toss**. Both versions are retained in full |
| BR-SYNC-08 | Conflict types: missing catalog reference, definition divergence, machine metadata mismatch, duplicate business code, version incompatible, referential gap |
| BR-SYNC-09 | A blocking conflict stops the affected records; a warning does not |
| BR-SYNC-10 | Central accepts the current schema version or one prior minor version; older is migrated on read or **refused with a stated reason** |
| BR-SYNC-11 | **A duplicate business code is now a genuine anomaly, not a routine event.** Under the old scheme two machines minting the same test-case number was expected. Under the new coding system it can only mean a machine code was reused, which is a registration error and must be reported as one |

## 9.25 AI Analysis **[P1]**

**REQ-AI-01** — The application shall use AI to propose conclusions from recorded evidence.

**Analysis types:** duplicate test case · duplicate bug · failure cluster · flaky assessment · regression assessment · failure reason · consecutive-failure diagnosis · impact proposal *(P2)* · recommendation.

| Rule | Statement |
|---|---|
| BR-AI-01 | **AI assists; it does not decide.** No AI output mutates record data |
| BR-AI-02 | Every recommendation carries **evidence, a confidence score and a review state** |
| BR-AI-03 | A recommendation is Proposed, then Accepted, Rejected, Superseded or Expired by a named person |
| BR-AI-04 | Every analysis records its provider, model, prompt version, token counts and duration, so a conclusion can be reproduced or explained |
| BR-AI-05 | The **outcome** of an accepted recommendation is recorded — correct, incorrect, partially correct — so the system's usefulness is itself measurable |
| BR-AI-06 | An analysis carries a distributed identity and consolidates like any other evidence |

## 9.26 Notifications **[P1]**

**REQ-NOTIF-01** — The business shall be told about things that need a decision, and not about anything else.

**Events:** critical test failure · new critical bug · bug assigned · bug ready for retest · retest failed · SLA breach · schedule missed · import conflict · known issue expired · discovery anomaly · export ready.

| Rule | Statement |
|---|---|
| BR-NOTIF-01 | Notifications are **deduplicated by key**, with an occurrence count and first/last event times. Forty identical failures produce one notification saying forty |
| BR-NOTIF-02 | Channels are in-app, email and digest |
| BR-NOTIF-03 | Delivery and read state are recorded |
| BR-NOTIF-04 | A notification names the entity it concerns and links to it |

## 9.27 Audit **[P1]**

**REQ-AUDIT-01** — Every material change shall be attributable and reconstructable.

| Rule | Statement |
|---|---|
| BR-AUDIT-01 | An audit row records the table, the record id **or its business code**, the operation, the old and new values, the actor, the context, the IP and the user agent |
| BR-AUDIT-02 | Operations include INSERT, UPDATE, DELETE, RESTORE, PURGE, LOGIN, PERMISSION_DENIED, EXPORT, IMPORT |
| BR-AUDIT-03 | A system action is flagged as such, so automation is distinguishable from a person |
| BR-AUDIT-04 | Audit rows carry a distributed identity and consolidate |
| BR-AUDIT-05 | Audit is **insert-only** |
| BR-AUDIT-06 | Retention is configurable, defaulting to three years. Expiry is an explicit administrative action, never a silent purge |

---

# Part V — Phase 2 Business Requirements

## 10.1 Change Request Management **[P2]**

**REQ-CR-01** — Enhancements and changes to Prime-AI shall be recorded, so the question "which tests does this change require?" has a subject.

| Rule | Statement |
|---|---|
| BR-CR-01 | A change request carries a stable code, a module, optionally a screen, a title, a description and acceptance criteria |
| BR-CR-02 | A change request carries its source document, criticality, status and version |
| BR-CR-03 | Change requests are mapped to test cases, with a coverage type: Full, Partial, Negative, Boundary, Integration |
| BR-CR-04 | Coverage is measured in **both directions**: which tests cover this change, and which changes this test covers |
| BR-CR-05 | A change request is **not** a test-case work request. The first is about Prime-AI; the second is about the test suite |
| BR-CR-06 | The test-case work backlog carries its own requests: Create, Modify, Automate, Retire, Investigate |
| BR-CR-07 | A work request records where it came from: a person, a change request, a coverage gap, a bug, discovery or AI |
| BR-CR-08 | A completed work request names the test case it produced |

## 10.2 Dependency Management **[P2]**

**REQ-DEP-01** — The application shall record what depends on what, so a change's blast radius is computable.

| Rule | Statement |
|---|---|
| BR-DEP-01 | Module-to-module dependencies carry a type and an impact weight from 1 to 10 |
| BR-DEP-02 | Test-case-to-test-case dependencies carry a type, an impact weight and a **blocking** flag |
| BR-DEP-03 | **A blocking dependency changes the result semantics:** if the parent fails, the dependent test is recorded **Blocked**, not Failed. This is why Blocked exists as a status in Phase 1 |
| BR-DEP-04 | Impact weight **decays with depth**. A second-order dependency is weaker evidence than a first-order one |
| BR-DEP-05 | A dependency cannot reference itself |
| BR-DEP-06 | Dependencies are maintained by people and proposed by analysis; a proposal is never applied automatically |

## 10.3 Application Path Mapping **[P2]**

**REQ-PATH-01** — A changed source file shall resolve to a module, a screen or a test case by rule, not by hand.

| Rule | Statement |
|---|---|
| BR-PATH-01 | A mapping is a glob pattern with a target type, a target, a confidence and a priority. Most specific wins |
| BR-PATH-02 | A mapping may resolve to **Ignore**, so vendor and build paths do not pollute analysis |
| BR-PATH-03 | Confidence expresses **how strongly a match implies impact**, and carries into the selection score |
| BR-PATH-04 | **A path no rule matched is an unresolved file and is counted as a blind spot** — an impact analysis states how much of the change it could not interpret. This is the single most important honesty requirement in Phase 2 |
| BR-PATH-05 | Path mappings cover controllers, routes, models, views, migrations, services, config and test files |

## 10.4 Test Suites **[P2]**

**REQ-SUITE-01** — Test cases shall be groupable into named, reusable collections.

| Rule | Statement |
|---|---|
| BR-SUITE-01 | Types: Smoke, Regression, Integration, Critical, Full, Bug Retest, Release, Custom |
| BR-SUITE-02 | A suite may be **explicit** (a listed membership) or **rule-based** (module, criticality, health) |
| BR-SUITE-03 | Suite membership is **versioned**. Each version stores its resolved membership |
| BR-SUITE-04 | A run records the **suite version it actually executed**, so a historical run is reproducible even after the suite changes |
| BR-SUITE-05 | A test case may belong to many suites |
| BR-SUITE-06 | Suites group by module, sub-module, tab and screen, so a regression pass over Fees is one selection |

## 10.5 Git Ingestion Engine **[P2]**

**REQ-GIT-01** — The application shall ingest Git history so a result can be tied to the code that produced it.

| Rule | Statement |
|---|---|
| BR-GIT-01 | A repository is registered with its local path, remote and default branch, and records the last commit ingested |
| BR-GIT-02 | A commit records hash, short hash, branch, parent, merge parent, author, message, merge flag, file count, lines added and removed, and commit time |
| BR-GIT-03 | A commit author is **resolved to a Testing Application user where possible**, so "who changed this" and "who tested this" are the same vocabulary |
| BR-GIT-04 | Each changed file records its path, change type, lines changed, and its resolved module, screen or test case |
| BR-GIT-05 | Each resolution records **how it was resolved**: test file, screen path, path mapping, module convention, manual, or unresolved |
| BR-GIT-06 | Ingestion is idempotent and incremental |
| BR-GIT-07 | Git hashes are stored as 40-character values. A SHA-1 is 40 hex characters, and storing it padded means a hash read from `git log` never compares equal to a stored one |

## 10.6 Impact Analysis and Test Selection **[P2]**

**REQ-IMPACT-01** — Given a change, the application shall propose which test cases it requires.

| Rule | Statement |
|---|---|
| BR-IMPACT-01 | An analysis is a **named, retained, reviewable proposal**, not a transient list |
| BR-IMPACT-02 | Sources: a commit range, a single commit, a bug fix, a manual selection or a change request |
| BR-IMPACT-03 | Each proposed test case carries its **reason, confidence, dependency depth and evidence** |
| BR-IMPACT-04 | Inclusion reasons: direct change, dependency, historical correlation, open bug, critical, regression policy, manual addition |
| BR-IMPACT-05 | **Excluded items are retained with their reason**, so the proposal states what it deliberately left out |
| BR-IMPACT-06 | An analysis records its **unresolved file count** — how much of the change it could not interpret |
| BR-IMPACT-07 | An analysis records the algorithm parameters used, so the result is reproducible |
| BR-IMPACT-08 | **A person approves before anything runs.** The system proposes; a QA Lead decides |
| BR-IMPACT-09 | After the fact, defects found inside and outside the proposed scope are counted, which is how the selection's usefulness is measured |
| BR-IMPACT-10 | An analysis may be superseded but is never deleted |

---

# Part VI — Governance

## 11. Core Business Rules

These seventeen rules govern every requirement above. Where a design decision conflicts with one, **the rule wins**.

| # | Rule | Phase | Consequence if violated |
|---|---|---|---|
| **R-01** | History is preserved. Historical evidence is never sacrificed to simplify current data | P1 | The application's core value disappears |
| **R-02** | Origin is preserved. Where information came from is always determinable | P1 | Consolidated data becomes unaccountable |
| **R-03** | Same number does not mean same entity | P1 | Silent data corruption on import |
| **R-04** | User and machine are different concepts | P1 | Environment-specific defects become invisible |
| **R-05** | Current state and historical state are different | P1 | Reports change meaning retroactively |
| **R-06** | Failure is not automatically a bug | P1 | Defect counts become meaningless |
| **R-07** | Bug and bug occurrence are different | P1 | Defect counts inflate; triage duplicates |
| **R-08** | Fixed does not equal verified | P1 | Defects reach users |
| **R-09** | Retest preserves the original failure | P1 | The evidence of what went wrong is lost |
| **R-10** | Independent information stays independent until confirmed | P1 | Wrong merges destroy real distinctions |
| **R-11** | Consolidation is traceable and reversible | P1 | Bad merges become permanent |
| **R-12** | AI assists; it does not decide | P1 | Unverifiable conclusions enter the record |
| **R-13** | Derived data is never authoritative | P1 | Corruption becomes undetectable |
| **R-14** | Every automated action is attributable and bounded | P1 | Uncontrolled loops, unexplained data |
| **R-15** | Evidence outlives opinion | P1 | Conclusions cannot be re-examined |
| **R-16** | The application reports discrepancies rather than resolving them silently | P1 | The business is misled by tidy but wrong data |
| **R-17** *(v3)* | **A business code is permanent.** Once referenced, it is never changed or reissued | P1 | Every historical record referencing it becomes a lie |

## 12. Business Lifecycles

### 12.1 Screen authoring pipeline **[P1]**
```
Screen catalogued
   → requirement document written        (requir_doc_status)
   → required test case list written     (tc_list_status)      → tst_tc_required_list rows
   → screen developed                    (dev_status)
   → test cases authored                 (tc_creation_status)  → tst_test_cases rows
   → test cases reviewed and signed off                        → tst_test_case_review rows
   → test cases executed                 (test_run_status)
```

### 12.2 Test case lifecycle **[P1]**
```
Planned (TcList) → Pending → In-Progress → Ready-For-Review → In-Review → Released
                                                                   ↓
                                        Cancelled / Rolled-Back / Hold / Not-Required
Released → (source file removed) → Orphaned
Released → (superseded)          → Retired      [never deleted]
```

### 12.3 Test run lifecycle **[P1]**
```
Queued → Running → Completed
            ├──→ Failed
            ├──→ Cancelled     (person + reason)
            ├──→ Interrupted   (heartbeat stopped)
            └──→ Timed_Out
```

### 12.4 Bug lifecycle **[P1]**
```
Open → Assigned → In_Progress → Fixed → Retesting → Closed
                                          ↓
                                       Reopened → Assigned
Open → Escalated                (SLA breach or retest limit)
Open → Wont_Fix / Duplicate     (with reason)
```

### 12.5 Test case review lifecycle **[P1]**
```
Pending → In-Progress → Completed → Released
                            ↓
              Error / Cancelled / Rolled-Back / Hold
```

### 12.6 Import lifecycle **[P1]**
```
Received → Validating → Applying → Completed
                ↓            ↓
             Rejected      Partial (open conflicts)
Completed → Reversed  (person + reason)
```

### 12.7 Impact analysis lifecycle **[P2]**
```
Draft → Proposed → Approved → Executed
            ↓
         Rejected / Superseded
```

## 13. Business Decisions Register

D-01 … D-22 are carried forward from BRD v2 with their original numbers and remain in force except where amended below. D-23 onward are new in v3.

### 13.1 Amended decisions

| ID | Decision | v2 answer | **v3 answer** | Why it changed |
|---|---|---|---|---|
| **D-01** | Is the catalog central or per-machine? | Central catalog with a source-test-case layer | **The navigation catalog is central; test cases are machine-stamped and consolidate as evidence.** The source-test-case layer is retired | The composite code makes independent authoring safe by construction |
| **D-03** | May one user modify another's test case? | Yes, within role limits | **A test case is edited on the machine that owns its code.** Another machine proposes a duplicate link rather than editing | The code names the owning machine; editing elsewhere would misattribute authorship |
| **D-07** | Is central authoritative or aggregating? | Authoritative for catalog, aggregating for evidence | **Authoritative for users, machines and the navigation catalog; aggregating for everything else, including test cases** | Follows D-01 |

### 13.2 New decisions

| ID | Decision | **Answer** | Rationale |
|---|---|---|---|
| **D-23** ⚠ | What is the relational key for test cases and machines? | **The business code.** `test_case_code` and `machine_code` are generated, stored, unique columns and are the parent keys of every child relationship | §5.2. Removes the id-to-code translation layer at every import boundary |
| **D-24** ⚠ | Is the Source Test Case concept still needed? | **No. Retired.** Its purpose was to hold an independently authored test case before deciding whether it duplicated a canonical one — because two machines could mint the same number. They no longer can. Every test case lives in one table, stamped with its author's machine; equivalence is recorded in `tst_duplicate_test_case` | One table, one concept, one place to look. This removes a table, two nullable columns on the run item, a check constraint and an entire import-reconciliation path |
| **D-25** | Roles and permissions? | **Removed.** A single role enum on the user record. Revisit above ~15 users or on first external contractor | Four tables of matrix administration protecting a team where everyone does everything |
| **D-26** | Is there a Release entity? | **No.** Release readiness is expressed through test-case review and sign-off in `tst_test_case_review` | The team releases test cases, not named deliveries. Where a "release run" is meaningful it is a run trigger label, not an entity |
| **D-27** | Is a schema-version table needed? | **No.** The version is one `tst_app_settings` row; Laravel's own `migrations` table already holds the applied history; an export bundle carries the version and the importer compares it | Two mechanisms recording the same fact will eventually disagree |
| **D-28** | How do Phase-1 tables reference Phase-2 entities? | **Columns in Phase 1, foreign keys in Phase 2.** Phase 2 adds constraints; it never alters a Phase-1 table | `tst_test_run_results` will hold millions of rows. An ALTER that rewrites it is an outage |
| **D-29** | Sequence width in codes | `tc_seq_number` is padded to **3** digits (999 test cases per screen per machine); `tc_list_number` to **4**. Both columns are `VARCHAR(21)` | Implemented as specified by the owner. **Flagged in §18 as worth aligning** — see OPEN-01 |
| **D-30** | May a test case move between screens? | **No.** Its code names its screen. Testing a different screen is a different test case, created against that screen's TcList | Consequence of D-23 and R-17 |
| **D-31** | What does a duplicate business code on import mean now? | **A registration error, reported as a blocking conflict.** It can only occur if a machine code was reused | Under the old scheme it was routine; under the new one it is a symptom |

## 14. Non-Functional Requirements

### 14.1 Performance

| ID | Requirement | Target | Phase |
|---|---|---|---|
| NFR-01 | Test case catalog list, 20,000 cases | p95 < 2s | P1 |
| NFR-02 | Recording one result with artefacts | < 200ms | P1 |
| NFR-03 | Test case history, one case, all attempts | p95 < 1.5s | P1 |
| NFR-04 | Dashboard | p95 < 3s | P1 |
| NFR-05 | Discovery scan of the full Prime-AI tree | < 5 min | P1 |
| NFR-06 | Import of a 100,000-record bundle | < 15 min | P1 |
| NFR-07 | Analytics full rebuild | < 30 min | P1 |
| NFR-08 | Git ingestion, 1,000 commits | < 10 min | P2 |
| NFR-09 | Impact analysis over a 50-commit range | < 60s | P2 |

### 14.2 Volume and the cost of the code system

Planning basis for one central installation after two years:

| Entity | Rows | Key size |
|---|---|---|
| Test cases | 20,000 | 21 bytes |
| Run items | 4,000,000 | 21 bytes |
| **Results** | **6,000,000** | 21 bytes |
| Artefacts | 12,000,000 | — |
| Audit rows | 8,000,000 | — |

**The honest arithmetic.** Carrying `test_case_code` instead of a 4-byte integer on 6,000,000 result rows costs roughly **100 MB of index**, on a table whose artefacts occupy tens of gigabytes. In exchange, every import stops needing an id-translation table, and every log line and filename becomes self-describing. **The trade is clearly worth it at this scale.** It would not be at a hundred times this scale, and §18 records that as the condition under which to revisit.

### 14.3 Other

| ID | Requirement | Phase |
|---|---|---|
| NFR-10 | MySQL 8.0.16 or later; InnoDB; utf8mb4 / utf8mb4_unicode_ci | P1 |
| NFR-11 | The schema installs on a machine with no network access to the central installation | P1 |
| NFR-12 | Artefact retention defaults to 180 days and is configurable | P1 |
| NFR-13 | Audit retention defaults to 3 years and is configurable | P1 |
| NFR-14 | Phase 2 installs against a populated Phase 1 database with no data migration | P2 |

## 15. Success Criteria and KPIs

### 15.1 The application succeeds when the business can answer, from recorded evidence

**Phase 1**

1. What is our test coverage for this screen — required, written, reviewed, released?
2. What happened when this test last ran, and on which machine, in which environment, against which commit?
3. Has this test ever passed? When did it stop?
4. Is this failure new, known, flaky, or an environment difference?
5. Which bugs are open, on what, assigned to whom, and how long have they been open?
6. Has this fix actually been verified, or only claimed?
7. Which tests are unreliable, and on what evidence?
8. What did each machine contribute this week?
9. Who changed this test case, when, and what did it look like before?
10. What did the last discovery scan find that the catalog does not know about?

**Phase 2**

11. Given this commit range, which tests should we run, and why each one?
12. What did that proposal deliberately exclude, and on what grounds?
13. How much of that change could the system not interpret?
14. Which suite covers this module, and what did it look like when it last ran?
15. Did the tests we selected actually catch the defects, or did they escape?

### 15.2 KPIs

| ID | KPI | Definition | Phase |
|---|---|---|---|
| K-01 | Screen coverage | Screens with ≥1 released test case ÷ screens in scope | P1 |
| K-02 | TcList completion | Released test cases ÷ required test cases | P1 |
| K-03 | Review throughput | Test cases signed off per week | P1 |
| K-04 | Pass rate trend | Final-attempt pass rate over 30 days | P1 |
| K-05 | Verified-fix rate | Bugs closed with a passing retest ÷ bugs closed | P1 |
| K-06 | Mean time to verify | Fixed → verified, in hours | P1 |
| K-07 | Flaky ratio | Confirmed flaky ÷ active test cases | P1 |
| K-08 | Testing debt | Screens with no released test case, weighted by criticality | P1 |
| K-09 | Consolidation latency | Hours between a local run and its appearance centrally | P1 |
| K-10 | AI acceptance rate | Recommendations accepted ÷ proposed | P1 |
| K-11 | Impact hit rate | Defects found inside proposed scope ÷ all defects found | P2 |
| K-12 | Unresolved-path ratio | Unresolved changed files ÷ changed files | P2 |
| K-13 | **Escaped defect rate** | Defects found after release that existing tests should have caught | P2 |

## 16. Assumptions, Constraints and Risks

### 16.1 Assumptions

| # | Assumption |
|---|---|
| A-01 | The team is small (under 10) and every member is trusted with every function |
| A-02 | Prime-AI is one code base in one Git repository |
| A-03 | Every machine can reach the shared location where bundles are exchanged, eventually |
| A-04 | MySQL 8.0.16+ is available on every machine |
| A-05 | Test authorship is a normal activity on developer machines, not only tester machines |

### 16.2 Constraints

| # | Constraint |
|---|---|
| C-01 | **Generated columns cannot be referenced by a foreign key if they are virtual.** All code columns are STORED |
| C-02 | **A foreign key on a column that feeds a generated column cannot cascade or set null on update or delete.** This is what makes R-17 non-negotiable |
| C-03 | A machine code is four characters: 26 machines per user, 999 users per role letter |
| C-04 | A test case sequence is three digits: 999 test cases per screen per machine |
| C-05 | A screen code is 11 characters and positional; the hierarchy depth is fixed |

### 16.3 Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| RSK-01 | A machine code is reused after a machine is rebuilt, silently colliding codes | Medium | **High** | Registration is central; retired codes are never reissued; import reports duplicate codes as blocking conflicts (D-31) |
| RSK-02 | A screen code is renumbered when the navigation changes | Medium | **High** | R-17. Renumbering requires a new code and an explicit supersede link |
| RSK-03 | Phase 2 arrives and needs to alter a large Phase-1 table | Medium | High | D-28: columns are declared in Phase 1, constraints added in Phase 2 |
| RSK-04 | 999 test cases per screen proves insufficient for a large screen | Low | Medium | OPEN-01; a fourth digit costs one byte |
| RSK-05 | Discovery proposes catalog changes faster than anyone reviews them | High | Medium | Discovery never writes catalog data; the review queue is a first-class screen |
| RSK-06 | Artefact volume outgrows the evidence store | High | Medium | Retention policy, content-hash deduplication, per-machine evidence root |
| RSK-07 | The team defers Phase 2 indefinitely and never gets change-based selection | Medium | Medium | Phase 1 is designed to be useful alone; Phase 2 is additive |

## 17. Defects Identified in `testing_DDL_v7.1.sql`

Found while reading the revised schema. All are corrected in `testing_DDL_v7.2.sql`; several would prevent the script from executing.

| # | Table | Defect | Severity |
|---|---|---|---|
| 1 | `tst_app_settings` | Index declared on `group_name`, a column that does not exist | **Fatal** |
| 2 | `tst_users` | Foreign keys on `created_by`, `updated_by`, `deleted_by` — none of the three columns is declared | **Fatal** |
| 3 | `tst_users` | Index on `primary_role_code`, a column that does not exist | **Fatal** |
| 4 | `tst_tc_required_list` | Unique key on `tc_list_code`; the column is called `tcr_code` | **Fatal** |
| 5 | `tst_test_case_versions_history` | Foreign key on `test_case_id`; the column is `test_case_code` | **Fatal** |
| 6 | `tst_test_runs` | Generated column `test_case_code` built from `machine_code`, which is not declared (the column is `run_machine_code`) | **Fatal** |
| 7 | Deferred block | Adds foreign keys to `tst_releases` and `tst_roles`, both of which were removed | **Fatal** |
| 8 | `tst_source_test_cases`, `tst_schema_version` | Declared at the end of the file, after the tables that reference them | **Fatal** |
| 9 | `tst_test_cases` | `test_case_code` is `VARCHAR(21)`; children declare `VARCHAR(20)` | High |
| 10 | Many | `user_code` declared `VARCHAR(3)` in some tables and `VARCHAR(10)` in others | High |
| 11 | Many | `ts_code` declared `VARCHAR(11)` in some tables and `VARCHAR(20)` in others | High |
| 12 | Many | `module_code` declared `VARCHAR(5)` in some tables and `VARCHAR(10)` in others | High |
| 13 | `tst_test_runs` | A run is modelled as though it were one test case | High |
| 14 | `tst_tc_required_list` | No foreign key on `machine_code`; no foreign keys on the audit columns | Medium |
| 15 | `tst_test_case_review` | No foreign key from `version_no` to a version record, and none is possible — noted as intentional | Low |
| 16 | `tst_test_case_review` | Unique key includes `review_date DATETIME`; two reviews in the same second collide | Low |
| 17 | `tst_bugs` | `module_code VARCHAR(10)` against a `VARCHAR(5)` parent | Medium |
| 18 | Views | Every view still joins on `tc.id`; none uses the new codes | High |

## 18. Open Items

| # | Item | Recommendation | Owner |
|---|---|---|---|
| **OPEN-01** | `tcr_code` pads the sequence to 4 digits while `test_case_code` pads to 3, so the same conceptual position renders as `0001` and `001`. Both columns are `VARCHAR(21)` and both work, but a human comparing the two codes for one test case will see a difference that means nothing | **Align both to 3 digits and `VARCHAR(20)`**, or both to 4 and `VARCHAR(21)`. Implemented as specified for now (D-29) | Product owner |
| **OPEN-02** | Three digits caps a screen at 999 test cases per machine | Accept. Revisit if any screen passes 500 | Product owner |
| **OPEN-03** | Whether a `Q` (QA Lead) role letter is needed given the current team | Cosmetic; the enum already carries it | Product owner |
| **OPEN-04** | The `Release` label survives as a run trigger and a scope type although the Release entity is gone | Kept as a descriptive label with no entity behind it | Recorded |
| **OPEN-05** | Revisit the code-as-key decision if results exceed ~500,000,000 rows | Not a foreseeable condition for this team | Recorded |
| **OPEN-06** | The generated-column design rests on one MySQL behaviour that has not yet been executed against a live server: that a foreign key may *reference* a STORED generated column. The restriction MySQL documents applies to VIRTUAL columns, and all three code columns are STORED with a UNIQUE index — but this must be confirmed on the first real install | Verify before build. If a server rejects it, the fallback is to drop the generated clause and have the application write the concatenated code on insert; no other part of the design changes | Tech lead |

---

## 19. Final Business Principle

> **Testing information is only worth keeping if it can be read back and acted upon.**
>
> Phase 1 makes every fact about a test — who wrote it, on what machine, against which screen, from which requirement, reviewed by whom, run when, in what environment, against which commit, with what evidence, and whether the defect it found was ever actually verified as fixed — a recorded, queryable, consolidatable fact.
>
> Phase 2 turns that record into a decision: **given this change, run these tests, for these reasons, and here is what we deliberately left out.**

---

**End of `TestingApp_BRD_v3.md`**
