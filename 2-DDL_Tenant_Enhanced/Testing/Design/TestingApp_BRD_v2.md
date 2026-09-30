# Prime-AI Testing Application — Business Requirements Document (BRD)

**Document ID:** TSTAPP-BRD-V2
**Version:** 2.0
**Supersedes:** TestingApp_BRD_v1.md (v1.0)
**Status:** Draft for Business Sign-off
**Perspective:** Business Analyst
**Date:** 2026-09-04

---

## 0. Document Control

### 0.1 Related Documents

| Document | Version | Role |
|---|---|---|
| `TestingApp_BRD_v1.md` | 1.0 | Predecessor of this document |
| `TestingApp_BRD_v2.md` | 2.0 | **This document** — authoritative business requirement |
| `Solution_Design_v2.md` | 2.0 | Functional + technical solution derived from this BRD |
| `testing_DDL_v7.0.sql` | 7.0 | Physical database schema derived from the solution design |

### 0.2 What Changed From v1

v1 was a broad, well-structured statement of intent. It was, however, **internally inconsistent in three places** and **silent in eight areas** that the schema work has since proved to be necessary. v2 resolves those.

| # | Change | Reason |
|---|---|---|
| C-01 | Added a **Glossary** (§4) fixing one meaning per term | v1 used "requirement", "test case", "run", "result" and "attempt" with more than one meaning |
| C-02 | Separated **Application Requirement** from **Test-Case Work Request (backlog)** | v1 §21 and v1 §37 described two different things using the same word |
| C-03 | Resolved the **Canonical vs Source test case** contradiction (§9.4, D-01) | v1 §10–11 demanded independent creation; the schema treats test cases as a single shared catalog. Both are now defined, with a governing mode |
| C-04 | Added **Manual test steps** as a first-class requirement (§9.5) | v1 permitted manual test cases but never said what a manual tester actually reads or records |
| C-05 | Added **Environment** as a business entity, not free-text (§9.21) | v1 §44 asked for environment awareness but treated it as narrative |
| C-06 | Added **Release / change validation** as a managed object (§9.22) | v1 §43 described the need but gave it no lifecycle |
| C-07 | Added **Test selection & impact analysis as a reviewable artefact** (§9.18) | v1 §29 required review/approval but defined no thing to review |
| C-08 | Added **Notifications, Retention and Access Control** acceptance criteria | v1 stated the needs without measurable outcomes |
| C-09 | Replaced v1 §56 "20 open questions" with an **answered Decisions Register** (§12) | Business could not sign off a document that ended in questions |
| C-10 | Every business rule now carries an **acceptance criterion** | v1 rules were not testable |
| C-11 | Added measurable **KPIs and phased delivery** (§13, §15) | v1 had no definition of "done" |
| C-12 | Added **Enhancements** section (§16) | Requested |

### 0.3 Reading Guide

- **§4–§8** — vocabulary, objectives, operating model, scope. Read first.
- **§9** — the requirements themselves. Each sub-section is: *Business need → Business rules (BR-*) → Acceptance criteria (AC-*)*.
- **§10–§11** — the non-negotiable rules and the lifecycles they protect.
- **§12** — decisions the business must confirm; each already carries a recommended answer.
- **§16** — proposed additional capabilities.

---

## 1. Purpose

This document defines **what the business needs from the Prime-AI Testing Application, and why**.

The Prime-AI application is a multi-tenant K-12 school management platform of roughly 47 modules and over 1,000 screens. It changes continuously. The business needs a dependable, historical, and increasingly intelligent account of that application's quality.

This document does **not** define database tables, keys, frameworks, APIs or infrastructure. Those belong to `Solution_Design_v2.md` and `testing_DDL_v7.0.sql`.

Where v1 said only "the business needs X", v2 also says **how the business will know it got X** (acceptance criteria) and **what it will measure** (KPIs).

---

## 2. Business Background

Quality verification of Prime-AI is currently performed by several people, on several machines, with results that live largely in each person's head, terminal scrollback, or local files.

The business must be able to answer, at any moment:

- What functionality exists, and what of it is covered by tests?
- What has been tested, by whom, on which machine, against which version of the code?
- What is failing right now, and was it failing last week?
- Is this failure a new defect, an already-known defect, an unstable test, or an environment problem?
- Which change caused it?
- Was the fix verified, or merely declared?
- Given today's code change, what should we test — and what can we safely not test?
- What does the accumulated history tell us about where quality risk actually lives?

No individual can hold this. The Testing Application exists to hold it.

---

## 3. Business Problem

| # | Problem | Business consequence |
|---|---|---|
| P-01 | Test knowledge is personal, not organisational | Knowledge leaves when a person leaves or forgets |
| P-02 | Testing happens on isolated machines | No consolidated view of quality |
| P-03 | Results are not retained in comparable form | "Did this ever work?" cannot be answered |
| P-04 | A failure is investigated from scratch every time | Repeated, expensive manual analysis |
| P-05 | A fix is trusted because it was declared fixed | Defects re-reach users |
| P-06 | Every change triggers either full regression or guesswork | Either too slow or too risky |
| P-07 | Unstable tests are indistinguishable from real defects | Erosion of trust in the whole test suite |
| P-08 | The same defect is reported repeatedly by different people | Duplicated triage effort |
| P-09 | Coverage is unknown | Cannot state release readiness with evidence |
| P-10 | Two people may create the same test twice, or two different tests with the same number | Inconsistent, uncountable inventory |

---

## 4. Glossary — Canonical Vocabulary

This glossary is **binding**. Where any later document, screen, report or table uses one of these words, it uses it with this meaning only.

| Term | Definition |
|---|---|
| **Module** | A top-level functional area of Prime-AI (e.g. Fees, Examination, Student Profile) |
| **Category** | A grouping within a module |
| **Main Menu / Sub Menu** | Navigation levels within a category; sub menu is optional |
| **Screen (Tab/Screen)** | The smallest addressable, testable functional surface of Prime-AI. Identified by a stable screen code |
| **Test Case** | A defined, repeatable verification of one behaviour of one screen. **Canonical** unless stated otherwise |
| **Canonical Test Case** | The organisation-recognised definition of a test case, identified by *Screen + Test Case Number*. The unit that coverage, history and reporting are counted against |
| **Source Test Case** | A test case as independently authored on one machine by one person, before the organisation has confirmed whether it is the same as an existing canonical test case |
| **Test Case Version** | An immutable snapshot of a test case definition at a point in time |
| **Test Step** | An ordered instruction plus expected result within a manual or hybrid test case |
| **Test Suite** | A named, reusable collection of test cases (Smoke, Regression, Release, …) |
| **Test Run** | One execution *event*. A run has a scope, a trigger, an environment, a code version, and a set of selected test cases |
| **Run Item** | One test case selected into one run, together with the reason it was selected |
| **Attempt** | One execution of one run item. A run item may have several attempts |
| **Result** | The outcome of one attempt: Passed, Failed, Error, Skipped, Blocked or Not Executed |
| **Evidence** | Artefacts retained with a result: message, trace, screenshot, console log, page source, video, notes |
| **Failure Signature** | A normalised fingerprint of a failure, used to group recurring identical failures |
| **Bug (Defect)** | A confirmed or suspected defect in Prime-AI. One bug is one problem |
| **Bug Occurrence** | One observation of one bug in one result. One bug has many occurrences |
| **Known Issue** | An accepted, documented problem or limitation whose recurrence is expected and must not be re-triaged as new |
| **Retest** | Execution performed specifically to verify a fix |
| **Retest Cycle** | One managed attempt to verify one or more fixed bugs, including its regression scope |
| **Regression** | Functionality that previously passed and now fails, where the failure is attributable to a change |
| **Flaky Test** | A test whose outcome changes under materially unchanged conditions |
| **Application Requirement** | A statement of what Prime-AI must do. Tests are mapped to it to measure coverage |
| **Test-Case Work Request** | A backlog item asking that a test case be created, modified or automated. **Not** an application requirement |
| **Impact Analysis** | A reviewable proposal of which screens and test cases a given change may affect |
| **Environment** | The identified combination of OS, runtime, browser, database and configuration under which a run executed |
| **Release** | A named delivery of Prime-AI against which testing is planned, executed and assessed |
| **Machine** | A registered installation of the Testing Application. Distinct from the user operating it |
| **Consolidation** | Bringing testing information created on separate machines into one analysable body of data without losing its origin |
| **Local Database** | The Testing Application database on one machine |
| **Central Database** | The consolidated Testing Application database |

---

## 5. Business Objectives

Each objective carries the measure by which its achievement is judged.

| ID | Objective | Measure of achievement |
|---|---|---|
| **BR-OBJ-01** | Improve testing visibility | Any authorised user can state, unaided, the current test status of any module within 60 seconds |
| **BR-OBJ-02** | Preserve testing history | No executed result is ever altered or lost; every result remains retrievable with its original context |
| **BR-OBJ-03** | Improve defect management | Every bug is traceable from first observation through fix to verified retest |
| **BR-OBJ-04** | Identify regressions | Every new failure is automatically classified against prior history and recent change, with supporting evidence |
| **BR-OBJ-05** | Identify flaky tests | Unstable tests are identified from evidence and excluded from regression alarm, without being hidden |
| **BR-OBJ-06** | Improve change impact analysis | For any change, the application proposes an affected-test set that a human can review and approve |
| **BR-OBJ-07** | Consolidate testing knowledge | Testing performed on any registered machine is analysable centrally without losing its origin |
| **BR-OBJ-08** | Reduce repeated manual analysis | Recurring failures are grouped automatically; a repeat failure is recognised, not re-investigated |
| **BR-OBJ-09** | Establish accountability | Every business-significant action attributes a person or an identified system process |
| **BR-OBJ-10** | Support continuous quality improvement | Quality trend is reportable over time by module, screen, requirement, release and environment |
| **BR-OBJ-11** | Make coverage measurable | Coverage is stated against screens and against application requirements, not only against test counts |
| **BR-OBJ-12** | Make release readiness evidence-based | A release recommendation is produced from recorded evidence, and states its own reservations |
| **BR-OBJ-13** | Make testing economical | Targeted test selection reduces the average tests executed per change without reducing defect detection |
| **BR-OBJ-14** | Make AI assistance trustworthy | Every AI-produced conclusion carries its evidence, its confidence, and a human review state |

---

## 6. Stakeholders and Personas

| Persona | Primary interest | Typical actions | Key screens |
|---|---|---|---|
| **System Administrator** | The platform works and is governed | Register users and machines, manage settings, retention, imports | Admin, Machines, Settings, Import |
| **Architect / Development Lead** | Structural quality and risk | Define modules, dependencies, path mappings, suites; review impact analyses | Catalog, Dependencies, Impact, Release |
| **QA Lead** | Coverage, triage, release readiness | Approve test selections, triage failures, assign bugs, confirm duplicates and equivalences, sign off releases | Dashboard, Triage, Bugs, Coverage, Release |
| **Tester** | Executing and recording testing | Run tests, record manual results and evidence, raise bugs, retest | Execute, Manual Runner, Results, Bugs |
| **Developer** | Fixing what is assigned; not breaking others | Review assigned bugs, run impacted tests before commit, mark fixed | My Bugs, Impacted Tests, Run |
| **Reviewer** | Independent confirmation | Review test definitions, approve consolidations, verify fixes | Review queues |
| **Business Analyst** | Requirement coverage | Maintain application requirements, map tests, view coverage gaps | Requirements, Traceability |
| **Management** | Quality trend and risk | Read dashboards and release assessments | Executive Dashboard |
| **System (automation)** | Executes without a human present | Scheduled runs, auto-retest, discovery, import | — |

**BR-PERSONA-01:** Every business action recorded by the application must be attributable either to a named person or to an identified system process. "Unknown" is not an acceptable actor.

---

## 7. Operating Model

### 7.1 Local-First, Centrally Consolidated

```
  Machine M01 ─┐
  Machine M02 ─┼──►  Export  ──►  Import  ──►  CENTRAL DATABASE  ──► Consolidated analysis
  Machine M03 ─┘                                    ▲
                                                    │
                                        Catalog governance flows back
```

- Work happens locally and must not require the central database to be reachable.
- Testing information is exported and consolidated centrally.
- The **catalog** (modules, screens, canonical test cases, suites, requirements, masters) is **governed centrally and distributed outward**.
- **Execution evidence** (runs, results, bugs, notes) is **created locally and consolidated inward**.

**BR-OPMODEL-01:** Catalog flows outward from the centre; evidence flows inward to the centre. Any exception is a business decision, not a technical convenience.

**BR-OPMODEL-02:** A machine must be able to work for an extended period with no central connectivity, and must lose nothing when it reconnects.

**BR-OPMODEL-03:** Consolidation must never require a person to reconcile records by hand as a routine step. Manual reconciliation is an exception path for genuine conflicts only.

### 7.2 Business Conditions

| ID | Condition |
|---|---|
| BC-01 | Testing may be performed independently on individual machines |
| BC-02 | Multiple users participate in testing |
| BC-03 | One user may use several machines; one machine may be used by several users |
| BC-04 | Different users may independently create tests for the same functionality |
| BC-05 | Information is consolidated later, not continuously |
| BC-06 | Prime-AI changes continuously |
| BC-07 | The same test is executed many times |
| BC-08 | The same test may produce different outcomes under different circumstances |
| BC-09 | Some relationships (duplicate? equivalent?) are not knowable at creation time |
| BC-10 | Some decisions require human confirmation |
| BC-11 | Some activities occur with no human present |
| BC-12 | Historical information must remain useful indefinitely |
| BC-13 | Machines may run different versions of the Testing Application at the same time |
| BC-14 | The test inventory is expected to reach 100,000+ test cases and millions of results |

---

## 8. Scope

### 8.1 In Scope — Business Capabilities

| ID | Capability | Phase |
|---|---|---|
| C-01 | User, role and access management | 1 |
| C-02 | Machine registration and identity | 1 |
| C-03 | Application structure catalog (module → screen) | 1 |
| C-04 | Test case management, including manual test steps | 1 |
| C-05 | Test case discovery from the Prime-AI source tree | 1 |
| C-06 | Test case versioning | 1 |
| C-07 | Test execution (manual and automated) | 1 |
| C-08 | Results, attempts and evidence capture | 1 |
| C-09 | Execution history and trend | 1 |
| C-10 | Bug management and lifecycle | 1 |
| C-11 | Audit and soft deletion | 1 |
| C-12 | Operational dashboards and reports | 1 |
| C-13 | Test suites | 2 |
| C-14 | Application requirements and coverage traceability | 2 |
| C-15 | Test-case work request backlog | 2 |
| C-16 | Known issues | 2 |
| C-17 | Bug occurrences and duplicate handling | 2 |
| C-18 | Retesting and retest cycles | 2 |
| C-19 | Environment identification | 2 |
| C-20 | Export, import and consolidation | 2 |
| C-21 | Flaky test identification | 3 |
| C-22 | Regression identification | 3 |
| C-23 | Git and change traceability | 3 |
| C-24 | Change impact analysis and test selection | 3 |
| C-25 | Test and module dependencies | 3 |
| C-26 | Scheduled testing | 3 |
| C-27 | Notifications | 3 |
| C-28 | Release and change validation | 4 |
| C-29 | Cross-user / cross-machine comparative analysis | 4 |
| C-30 | AI-assisted analysis and recommendation | 4 |

### 8.2 Out of Scope

- Modifying Prime-AI itself.
- Acting as the organisation's general-purpose project or ticket tracker.
- Replacing source control, CI infrastructure or code review.
- Performance/load testing execution engines (results may be recorded; execution is not orchestrated here).
- Customer-facing or tenant-facing reporting.
- Any technical design decision — those live in `Solution_Design_v2.md`.

### 8.3 Scope Boundary Rule

**BR-SCOPE-01:** The Testing Application records and reasons about testing. It never becomes the authority on what Prime-AI *is* — the source code is. Where the two disagree, the application must report a discrepancy rather than assert its own version.

---

## 9. Business Requirements

Format for each area: **Business need → Business rules (BR-\*) → Acceptance criteria (AC-\*)**.

---

### 9.1 User Management and Access Control

**Need.** Every activity must be attributable, and users must only do what their responsibility allows.

**Business rules**

| ID | Rule |
|---|---|
| BR-USER-01 | Every user performing a business activity must be identifiable by a stable user code |
| BR-USER-02 | A user may use more than one machine |
| BR-USER-03 | User identity and machine identity are separate concepts and must never be merged |
| BR-USER-04 | A deactivated user must not perform new activities; all their historical activity remains intact and attributed to them |
| BR-USER-05 | System-generated activity must be distinguishable from activity performed by a person |
| BR-USER-06 | User codes are issued centrally and are identical on every machine |
| BR-USER-07 | A user may hold more than one responsibility (e.g. Developer who also tests) |
| BR-ACCESS-01 | Access is granted by responsibility (role), not by individual exception |
| BR-ACCESS-02 | Administrative activities — user and machine registration, settings, retention, import approval, permanent deletion — are restricted |
| BR-ACCESS-03 | The ability to view historical information never implies the ability to alter it |
| BR-ACCESS-04 | Access restrictions must not prevent legitimate historical reporting |
| BR-ACCESS-05 | Every permission denial must be recorded when it concerns a restricted activity |

**Acceptance criteria**

- **AC-USER-01** Attempting to act as a deactivated user is refused, and the refusal is logged.
- **AC-USER-02** A report filtered by user returns identical results before and after that user is deactivated.
- **AC-ACCESS-01** A Tester account cannot register a machine, change a system setting, or approve an import.
- **AC-ACCESS-02** A Developer account can update bugs assigned to them and cannot close bugs assigned to others.
- **AC-ACCESS-03** Every role's permitted actions are listed on one screen and are the same on every machine.

---

### 9.2 Machine Identity

**Need.** Distinguish where testing happened, permanently.

| ID | Rule |
|---|---|
| BR-MACHINE-01 | Every installation has a machine identity that is registered, not self-assigned |
| BR-MACHINE-02 | Activity from one machine must never be presented as activity from another |
| BR-MACHINE-03 | Information created independently on different machines must remain distinguishable after consolidation |
| BR-MACHINE-04 | Machine identity remains available for historical analysis after the machine is retired |
| BR-MACHINE-05 | A machine's descriptive attributes (name, OS, hardware) may change; its identity may not |
| BR-MACHINE-06 | The central installation is itself an identified machine |

**Acceptance criteria**

- **AC-MACHINE-01** Two machines that have never communicated cannot produce colliding run identities.
- **AC-MACHINE-02** Re-imaging a laptop and re-registering it produces a *new* machine identity; prior history stays attached to the old one.
- **AC-MACHINE-03** Every run, bug, export and audit record can name the machine that produced it.

---

### 9.3 Application Structure

**Need.** Organise the system under test so that testing, coverage and reporting can be expressed at meaningful levels.

Hierarchy: **Module → Category → Main Menu → Sub Menu (optional) → Screen → Test Case**

| ID | Rule |
|---|---|
| BR-STRUCT-01 | Every test case is associated with the screen whose behaviour it verifies |
| BR-STRUCT-02 | Optional hierarchy levels may be absent without breaking identity or reporting |
| BR-STRUCT-03 | Renaming or re-organising navigation must not destroy historical testing information |
| BR-STRUCT-04 | Reporting must be possible at module, category, menu, screen and test-case level |
| BR-STRUCT-05 | A screen may be marked out of scope for testing without being deleted |
| BR-STRUCT-06 | A screen carries its own readiness state: development status, requirement-document status, test-specification status, test-creation status |
| BR-STRUCT-07 | Every level of the hierarchy is identified by a stable business code that is identical on every machine |
| BR-STRUCT-08 | A child may not belong to a parent in a different branch of the hierarchy |

**Acceptance criteria**

- **AC-STRUCT-01** A screen moved from one menu to another retains all of its test cases and all historical results.
- **AC-STRUCT-02** Excluded screens are absent from testing worklists and present in coverage reports as "excluded, with reason".
- **AC-STRUCT-03** The application can list, for any module, every screen and each screen's readiness state.

---

### 9.4 Test Case Management — Canonical and Source

**Need.** A single, countable, shared inventory of what is tested — that nevertheless tolerates people independently authoring the same thing.

This resolves the central contradiction in v1 (§10 vs §11).

#### 9.4.1 The two layers

| Layer | What it is | Identity | Who governs it |
|---|---|---|---|
| **Canonical Test Case** | The organisation's recognised test case | Screen + Test Case Number | Centrally governed |
| **Source Test Case** | An independently authored test case, not yet confirmed against the canonical catalog | Machine + Author + Screen + Local Number | The authoring machine |

A source test case is **promoted** to canonical, **linked** to an existing canonical test case as equivalent, or **kept separate** as genuinely different. Until then it is unmapped, and it is counted separately in reporting.

#### 9.4.2 Authoring mode

**BR-TC-MODE-01:** The organisation operates one of two authoring modes, set as a system setting:

- **Central Catalog mode** *(recommended default, see D-01)* — test cases are created against the shared catalog. Numbering is issued centrally. The source layer is used only for offline authoring and import.
- **Local-then-Promote mode** — every machine may author freely; nothing is canonical until reviewed and promoted.

**Business rules**

| ID | Rule |
|---|---|
| BR-TC-01 | Every test case has a meaningful, human-readable identity and a stable business code |
| BR-TC-02 | Two test cases with the same visible number are not the same test case unless the organisation has confirmed it |
| BR-TC-03 | The origin of a test case — machine, author, date, discovery or manual creation — is preserved permanently |
| BR-TC-04 | Changing a test case definition must never alter historical results produced under a previous definition |
| BR-TC-05 | A test case is always associated with the screen it validates |
| BR-TC-06 | A test case may be manual, automated, or hybrid |
| BR-TC-07 | A test case may carry several classifications simultaneously (type, layer, technology, tags) |
| BR-TC-08 | A test case carries a business criticality (Critical / High / Medium / Low) |
| BR-TC-09 | A test case may be retired without deletion, and retired test cases remain in history |
| BR-TC-10 | A test case may be cloned; the clone records what it was cloned from |
| BR-TC-11 | An automated test case must be traceable to the source file, class and method that implement it |
| BR-TC-12 | A test case whose implementation has disappeared from the source tree is flagged as orphaned, never silently deleted |
| BR-TC-IND-01 | Independently created test cases are never automatically assumed identical |
| BR-TC-IND-02 | Independently created test cases retain their origin after any linking decision |
| BR-TC-IND-03 | The application proposes potential duplicates or equivalents for human decision |
| BR-TC-IND-04 | A confirmed equivalence is recorded with who decided it, when, and on what evidence |
| BR-TC-IND-05 | An equivalence decision is reversible, and the reversal is itself recorded |
| BR-TC-IND-06 | Linking two test cases must merge their history for analysis without erasing either origin |

**Acceptance criteria**

- **AC-TC-01** Two machines can each create "Test Case 7" on the same screen; both survive import, both are visible, neither overwrites the other.
- **AC-TC-02** After a QA Lead confirms them equivalent, coverage counts them once and history shows both origins.
- **AC-TC-03** Reversing that decision restores separate counting without data loss.
- **AC-TC-04** A test case's description can be rewritten without changing any historical result's displayed name.
- **AC-TC-05** Filtering the catalog by criticality, layer, technology, tag and status returns consistent counts.

---

### 9.5 Manual Test Cases and Test Steps *(new in v2)*

**Need.** A manual tester must be able to execute a test without asking anyone what to do, and must record what actually happened per step.

| ID | Rule |
|---|---|
| BR-STEP-01 | A manual or hybrid test case may define ordered steps, each with an action and an expected result |
| BR-STEP-02 | A test case may define preconditions and required test data |
| BR-STEP-03 | A manual execution may record an outcome and evidence per step, not only for the test case as a whole |
| BR-STEP-04 | The overall result of a manual test case must be consistent with its step outcomes, and any inconsistency must be explained by the tester |
| BR-STEP-05 | Steps are versioned with the test case; a historical execution shows the steps as they were at that time |
| BR-STEP-06 | An automated test case need not define steps |

**Acceptance criteria**

- **AC-STEP-01** A tester who has never seen the screen can execute a manual test case from its recorded steps.
- **AC-STEP-02** A manual run with 8 steps where step 5 fails records: overall Failed, step 5 Failed with evidence, steps 6–8 Blocked or Not Executed.
- **AC-STEP-03** Editing the steps today does not change what yesterday's execution displays.

---

### 9.6 Test Case Discovery

**Need.** Keep the catalog aligned with the Prime-AI source tree without manual transcription.

| ID | Rule |
|---|---|
| BR-DISC-01 | Discovered information is always distinguishable from information a person created or confirmed |
| BR-DISC-02 | Discovery never overwrites human-confirmed information without authorisation |
| BR-DISC-03 | Every discovery run reports what was added, changed, removed and unchanged |
| BR-DISC-04 | Discovered items awaiting confirmation are visible as a review queue |
| BR-DISC-05 | Discovery must be repeatable and produce the same result on unchanged input |
| BR-DISC-06 | Discovery must never delete a test case that has execution history; it marks it orphaned |
| BR-DISC-07 | Every discovery run is recorded with who ran it, on which machine, against which code version |

**Acceptance criteria**

- **AC-DISC-01** Running discovery twice with no source change produces a second log with zero changes.
- **AC-DISC-02** Deleting a test method from the source tree flags the test case as orphaned and preserves its history.
- **AC-DISC-03** A discovered display name never replaces a name a QA Lead has edited, unless approved.

---

### 9.7 Test Case Versioning

| ID | Rule |
|---|---|
| BR-VERSION-01 | A material change to a test case creates a new version |
| BR-VERSION-02 | Previous versions remain retrievable |
| BR-VERSION-03 | Every result identifies the version of the test case that produced it |
| BR-VERSION-04 | Updating a test case never rewrites historical results |
| BR-VERSION-05 | The business defines what counts as material: definition, steps, expected result, scope or automation implementation. Cosmetic changes need not version |
| BR-VERSION-06 | A version records who captured it, when, and against which code version |

**Acceptance criteria**

- **AC-VER-01** A result from three months ago displays the test case as it was defined three months ago.
- **AC-VER-02** The version history of any test case is viewable as a list with differences.

---

### 9.8 Test Suites

| ID | Rule |
|---|---|
| BR-SUITE-01 | A test case may belong to many suites |
| BR-SUITE-02 | Suite membership is managed without altering the test cases themselves |
| BR-SUITE-03 | A suite represents a stated testing purpose |
| BR-SUITE-04 | Changing a suite's composition never alters the record of what a past run actually executed |
| BR-SUITE-05 | A run performed against a suite records the suite composition as it was at that time |
| BR-SUITE-06 | A suite may be defined by explicit membership, by rule (e.g. "all Critical tests in module X"), or both |

**Acceptance criteria**

- **AC-SUITE-01** Removing a test case from the Smoke suite today does not change what last month's Smoke run is reported to have executed.
- **AC-SUITE-02** A rule-based suite re-evaluates on each run and records the resolved membership.

---

### 9.9 Application Requirements and Test-Case Work Requests

v1 used one word for two things. v2 separates them permanently.

#### 9.9.1 Application Requirements — *what Prime-AI must do*

| ID | Rule |
|---|---|
| BR-REQ-01 | A requirement may be verified by one or more test cases |
| BR-REQ-02 | A test case may verify one or more requirements |
| BR-REQ-03 | Requirement-to-test relationships are traceable in both directions |
| BR-REQ-04 | A requirement change identifies the tests that may need revision |
| BR-REQ-05 | Requirement coverage is reportable: covered, partially covered, uncovered |
| BR-REQ-06 | A requirement carries a business criticality that informs test prioritisation |
| BR-REQ-07 | Requirements are governed centrally |

#### 9.9.2 Test-Case Work Requests — *what the test team must build*

| ID | Rule |
|---|---|
| BR-WORK-01 | A work request asks for a test case to be created, modified, automated or retired |
| BR-WORK-02 | A work request has a requester, an assignee, a priority, a target release and a lifecycle |
| BR-WORK-03 | A completed work request names the test case it produced |
| BR-WORK-04 | Work request states: Pending, In Progress, Completed, Cancelled, Hold — and every transition is recorded |
| BR-WORK-05 | A work request may originate from a requirement, a coverage gap, a bug, or a person |

**Acceptance criteria**

- **AC-REQ-01** "Which tests verify requirement R?" and "Which requirements does test T verify?" are both answerable in one action.
- **AC-REQ-02** The coverage report distinguishes *no test exists* from *a test exists but has never passed*.
- **AC-WORK-01** A completed work request links to the test case created, and that test case links back.

---

### 9.10 Test Execution

| ID | Rule |
|---|---|
| BR-EXEC-01 | Every execution is a distinct, identifiable event |
| BR-EXEC-02 | Every execution records who or what initiated it, and who or what executed it — these may differ |
| BR-EXEC-03 | Every execution records its scope and the reason each test case was selected |
| BR-EXEC-04 | Every execution records the code version and environment under which it ran |
| BR-EXEC-05 | Historical executions are never overwritten by later executions |
| BR-EXEC-06 | A failed execution remains available for investigation even after a later execution passes |
| BR-EXEC-07 | An execution interrupted by crash, shutdown or timeout must be identifiable as such, never left appearing to be running |
| BR-EXEC-08 | Concurrent executions on the same machine must not corrupt one another's records |
| BR-EXEC-09 | An execution may be cancelled; the cancellation, its actor and its reason are recorded, and partial results are retained |
| BR-EXEC-10 | Execution triggers are distinguishable: Manual, Scheduled, Rerun, Bug Retest, Regression, Impact-Selected, Release, Merge |

**Acceptance criteria**

- **AC-EXEC-01** Killing the application mid-run leaves that run marked Interrupted within a defined period, with its completed results intact.
- **AC-EXEC-02** Every run can state, for each test case in it, why that test case was included.
- **AC-EXEC-03** Two runs started simultaneously on one machine both complete with correct, separate results.

---

### 9.11 Test Results and Evidence

Outcomes: **Passed, Failed, Error, Skipped, Blocked, Not Executed.**

| ID | Rule |
|---|---|
| BR-RESULT-01 | Every result belongs to exactly one attempt of one run item |
| BR-RESULT-02 | A test case may be executed many times within and across runs |
| BR-RESULT-03 | Every attempt is separately and permanently identifiable |
| BR-RESULT-04 | The latest result never replaces earlier results |
| BR-RESULT-05 | A failure retains sufficient evidence to be investigated without re-running it |
| BR-RESULT-06 | *Blocked* means the test could not run because of an unmet dependency, and must be distinguishable from *Failed* |
| BR-RESULT-07 | *Error* means the test itself or its harness malfunctioned, and must be distinguishable from a product defect |
| BR-RESULT-08 | Every result carries a snapshot of the test case name as it stood at execution time |
| BR-EVID-01 | Evidence attached to a failure remains available for investigation for the retention period |
| BR-EVID-02 | Evidence remains associated with the specific attempt that produced it |
| BR-EVID-03 | Loss or unavailability of evidence must be visible, not silent |

**Acceptance criteria**

- **AC-RES-01** Ten attempts of one test case produce ten independently retrievable results.
- **AC-RES-02** A failed attempt shows message, trace, screenshot and page source where the technology provides them.
- **AC-RES-03** Deleting an evidence file marks the result's evidence as unavailable rather than appearing to have had none.

---

### 9.12 Test History

The business must be able to determine, for any test case: first execution, most recent execution, total executions, passes, failures, skips, failure frequency, success rate, and trend.

| ID | Rule |
|---|---|
| BR-HISTORY-01 | Historical results remain available for the full retention period |
| BR-HISTORY-02 | Historical information is always associated with the correct test identity, including after an equivalence decision |
| BR-HISTORY-03 | Information from different users and machines remains distinguishable |
| BR-HISTORY-04 | Consolidated analysis is possible across all sources |
| BR-HISTORY-05 | Derived statistics are conveniences; the recorded results are the truth, and statistics must be rebuildable from them |

**Acceptance criteria**

- **AC-HIST-01** Deleting and rebuilding all derived statistics produces identical figures.
- **AC-HIST-02** A test case's full outcome sequence is displayable as a dated timeline.

---

### 9.13 Flaky Test Identification

| ID | Rule |
|---|---|
| BR-FLAKY-01 | Flakiness is concluded from historical evidence over a defined window, never from a single failure |
| BR-FLAKY-02 | Repeated alternation between outcomes under materially unchanged conditions is the primary indicator |
| BR-FLAKY-03 | A potentially flaky test must remain distinguishable from a confirmed product defect |
| BR-FLAKY-04 | The evidence behind a flakiness conclusion is reviewable |
| BR-FLAKY-05 | A person may confirm, reject or suppress a flakiness conclusion, and that decision is recorded |
| BR-FLAKY-06 | A test confirmed flaky is excluded from regression alarms but never hidden from coverage reporting |
| BR-FLAKY-07 | Confirmed flaky tests accumulate as testing debt and are reported as such |

**Acceptance criteria**

- **AC-FLAKY-01** The application states, in words, why it considers a given test flaky, listing the executions concerned.
- **AC-FLAKY-02** A test that fails five times consecutively is not classified as flaky.

---

### 9.14 Regression Identification

| ID | Rule |
|---|---|
| BR-REG-01 | Regression analysis considers prior results for the same test case |
| BR-REG-02 | A failure is evaluated against the most recent prior passes and the interval since |
| BR-REG-03 | Recent application changes are considered when assessing a failure |
| BR-REG-04 | Regression conclusions carry evidence; not every new failure is a regression |
| BR-REG-05 | A regression conclusion distinguishes: new failure with prior passes; failure after a specific change; failure of a previously known issue |
| BR-REG-06 | Regression identification must exclude confirmed flaky tests from automatic alarm, while still reporting them |

**Acceptance criteria**

- **AC-REG-01** A test that passed on commit A and failed on commit B is presented as a regression candidate naming both commits.
- **AC-REG-02** A test that has never passed is never presented as a regression.

---

### 9.15 Known Issues

| ID | Rule |
|---|---|
| BR-KNOWN-01 | A failure may be associated with a documented known issue |
| BR-KNOWN-02 | A recurrence of a known issue is not counted as a newly discovered defect |
| BR-KNOWN-03 | Every occurrence of a known issue remains recorded and countable |
| BR-KNOWN-04 | A known issue has an owner, a rationale, and a review date |
| BR-KNOWN-05 | An expired known issue reverts to normal defect treatment and notifies its owner |
| BR-KNOWN-06 | A known issue may be promoted to a bug, retaining its occurrence history |

**Acceptance criteria**

- **AC-KNOWN-01** A failure marked as a known issue is excluded from "new defects" and included in "known issue occurrences".
- **AC-KNOWN-02** Known issues past their review date appear on a review queue.

---

### 9.16 Bug Management

#### 9.16.1 Bug

| ID | Rule |
|---|---|
| BR-BUG-01 | Every bug has a responsible owner once triaged |
| BR-BUG-02 | Bug status follows the organisation's defined lifecycle; undefined transitions are refused |
| BR-BUG-03 | Every status transition is recorded with actor, time and note |
| BR-BUG-04 | A bug is not fixed because its status says so; it is fixed when a retest verifies it |
| BR-BUG-05 | A fixed bug requires a successful retest before it may be closed as verified |
| BR-BUG-06 | Severity (impact) and Priority (urgency) are separate attributes |
| BR-BUG-07 | A bug records the code change that fixed it where that is known |
| BR-BUG-08 | A bug may be raised manually without an originating failed result |
| BR-BUG-09 | A bug may be linked to other bugs as duplicate, related, blocking or caused-by |
| BR-BUG-10 | Reopening a bug is counted and is visible on the bug |
| BR-BUG-11 | A bug references the environment and code version in which it was observed |

#### 9.16.2 Bug Occurrence

| ID | Rule |
|---|---|
| BR-BUG-OCC-01 | One bug may be observed in many results across many runs |
| BR-BUG-OCC-02 | Every occurrence is separately recorded and dated |
| BR-BUG-OCC-03 | The application proposes whether a new failure matches an existing bug |
| BR-BUG-OCC-04 | A recurrence never automatically creates a second bug |
| BR-BUG-OCC-05 | A result may be associated with more than one bug |

#### 9.16.3 Deduplication

| ID | Rule |
|---|---|
| BR-BUG-DUP-01 | A candidate new bug is compared against existing bugs using failure signature, screen, test case and text similarity |
| BR-BUG-DUP-02 | The application may recommend a duplicate relationship; it may not assert one |
| BR-BUG-DUP-03 | An authorised user makes the final duplicate decision |
| BR-BUG-DUP-04 | After consolidation, the reporting history of the duplicate remains available |
| BR-BUG-DUP-05 | A duplicate decision is reversible and the reversal is recorded |

**Acceptance criteria**

- **AC-BUG-01** A bug cannot move from Fixed to Closed without a recorded passing retest, unless an authorised user overrides with a recorded reason.
- **AC-BUG-02** One bug failing 40 tests produces one bug and 40 occurrences.
- **AC-BUG-03** Marking bug B a duplicate of bug A moves future occurrences to A and keeps B's history retrievable.

---

### 9.17 Retesting

| ID | Rule |
|---|---|
| BR-RETEST-01 | A retest is linked to the bug or failure it verifies |
| BR-RETEST-02 | Retesting never removes the original failure history |
| BR-RETEST-03 | A failed retest is prominently visible and reopens the bug |
| BR-RETEST-04 | Repeated failed retests are distinguishable and counted |
| BR-RETEST-05 | Automatic retesting has a configurable maximum; beyond it the bug is escalated, not retried |
| BR-RETEST-06 | Retest scope is configurable: the failing test alone, the screen, related tests, or a regression set |
| BR-RETEST-07 | A retest cycle may verify several bugs at once, with a per-bug outcome |
| BR-RETEST-08 | A retest that cannot execute (environment unavailable, dependency blocked) is recorded as not covered, not as failed |

**Acceptance criteria**

- **AC-RETEST-01** With the limit set to 5, a sixth automatic retest is not attempted and the bug is escalated with a recorded reason.
- **AC-RETEST-02** A retest cycle covering three bugs records three separate outcomes.

---

### 9.18 Change Impact Analysis and Test Selection

**Need.** Convert "what changed?" into "what should we run?" — as a reviewable proposal.

| ID | Rule |
|---|---|
| BR-IMPACT-01 | Impact analysis produces a named, retained, reviewable proposal — not a transient list |
| BR-IMPACT-02 | The proposal names, for each proposed test, the reason and the confidence for its inclusion |
| BR-IMPACT-03 | Reasons include: directly changed, dependent module, dependent test, historical failure correlation, open bug on the area, business criticality, regression policy |
| BR-IMPACT-04 | An authorised user may add to, remove from, or approve the proposal, and the edits are recorded |
| BR-IMPACT-05 | An approved proposal may be executed as a run, and the run retains the link to the proposal |
| BR-IMPACT-06 | The application must be able to state what it deliberately excluded and why |
| BR-IMPACT-07 | Impact accuracy is measurable: of defects later found, how many were within the proposed scope |
| BR-IMPACT-08 | The mapping from source paths to modules and screens is maintained data, not embedded logic |

**Acceptance criteria**

- **AC-IMPACT-01** For a commit touching one module, the proposal lists affected tests grouped by reason with counts.
- **AC-IMPACT-02** A defect later found outside the proposed scope is reported as an impact-analysis miss.
- **AC-IMPACT-03** Every approved proposal names its approver and time.

---

### 9.19 Dependencies

| ID | Rule |
|---|---|
| BR-DEP-01 | Dependencies between modules and between test cases are recorded as data |
| BR-DEP-02 | A test blocked by an unmet dependency is recorded as Blocked, never as Failed |
| BR-DEP-03 | Dependency information informs test selection and execution order |
| BR-DEP-04 | Circular dependencies are detected and reported |
| BR-DEP-05 | A dependency carries a type and a strength, so impact can be weighted rather than absolute |

**Acceptance criteria**

- **AC-DEP-01** When a prerequisite test fails, dependent tests are recorded Blocked with the prerequisite named.
- **AC-DEP-02** Introducing a dependency cycle is refused with the cycle displayed.

---

### 9.20 Scheduled Testing

| ID | Rule |
|---|---|
| BR-SCHED-01 | Scheduled execution is distinguishable from manual execution |
| BR-SCHED-02 | Scheduled results are retained identically to manual results |
| BR-SCHED-03 | Failure of a scheduled run is identifiable for follow-up and notifies the responsible party |
| BR-SCHED-04 | A schedule names its owner, scope, machine and cadence |
| BR-SCHED-05 | A missed schedule (machine off, application closed) is recorded as missed, not silently skipped |
| BR-SCHED-06 | A schedule may be suspended without being deleted |

**Acceptance criteria**

- **AC-SCHED-01** A nightly run that did not occur appears as missed with its scheduled time.
- **AC-SCHED-02** Scheduled runs are attributable to the system process and to the schedule's owner.

---

### 9.21 Environment Awareness

| ID | Rule |
|---|---|
| BR-ENV-01 | Every run identifies the environment it executed in |
| BR-ENV-02 | An environment is identified by a repeatable combination of its material attributes, not by free text |
| BR-ENV-03 | Results from materially different environments are not automatically treated as equivalent |
| BR-ENV-04 | Environment information supports investigation of inconsistent outcomes |
| BR-ENV-05 | A change of environment between two executions of the same test must be visible when comparing them |
| BR-ENV-06 | Environment attributes include at minimum: operating system, runtime version, framework version, browser and driver, database version, application version and configuration profile |

**Acceptance criteria**

- **AC-ENV-01** Comparing a pass and a failure of the same test displays the environment differences between them.
- **AC-ENV-02** "This test fails only on Windows with Chrome 141" is answerable from recorded data.

---

### 9.22 Release and Change Validation

| ID | Rule |
|---|---|
| BR-REL-01 | A release is a named object with a scope, a period and a status |
| BR-REL-02 | Runs, bugs and impact analyses may be associated with a release |
| BR-REL-03 | For any release the business can state: what changed, what was affected, what was executed, what failed, what is known, what is open |
| BR-REL-04 | Release readiness is produced from recorded evidence and states its reservations |
| BR-REL-05 | The application recommends; it never authorises a release |
| BR-REL-06 | A release assessment is retained as it was issued, and is not retrospectively altered by later data |

**Acceptance criteria**

- **AC-REL-01** A release page lists open critical bugs, failed tests, untested changed screens and known issues in scope.
- **AC-REL-02** A past release assessment remains readable exactly as issued.

---

### 9.23 Export, Import and Consolidation

| ID | Rule |
|---|---|
| BR-SYNC-01 | Local work proceeds without central availability |
| BR-SYNC-02 | Exported information retains its origin: machine, user, original identifiers, original timestamps |
| BR-SYNC-03 | Consolidation never destroys original historical meaning |
| BR-SYNC-04 | Importing the same export twice creates nothing new |
| BR-SYNC-05 | Conflicts between independently created information are detected, retained and presented for decision — never silently resolved |
| BR-SYNC-06 | Identical visible numbers never imply identical entities |
| BR-SYNC-07 | Every export declares the application and schema version that produced it |
| BR-SYNC-08 | The central system refuses, or explicitly migrates, an export from an incompatible version — and says which |
| BR-SYNC-09 | Every export carries a manifest: contents, counts, period, integrity check |
| BR-SYNC-10 | An import is atomic per export: either it is accepted as a whole, or its partial state is visible and recoverable |
| BR-SYNC-11 | An import records what it created, what it matched to existing records, and what it rejected |
| BR-SYNC-12 | An import may be reversed while its conflicts are unresolved |

**Acceptance criteria**

- **AC-SYNC-01** Importing the same file three times results in identical central record counts.
- **AC-SYNC-02** An export from an older schema version is either migrated with a recorded decision or refused with a stated reason.
- **AC-SYNC-03** Every consolidated record can name the machine, user and original identifier it came from.
- **AC-SYNC-04** A conflicting test-case definition appears on a conflict queue, and neither version is lost.

---

### 9.24 Cross-User and Cross-Machine Analysis

| ID | Rule |
|---|---|
| BR-CROSS-01 | Source information remains identifiable after consolidation |
| BR-CROSS-02 | Unrelated test cases are never combined because of similar names or numbers |
| BR-CROSS-03 | Potentially equivalent information is surfaced for review |
| BR-CROSS-04 | Consolidated analysis retains enough information to trace any figure back to its origin |
| BR-CROSS-05 | The same test case executed on different machines is comparable side by side |
| BR-CROSS-06 | Comparative user metrics distinguish workload from quality and are never presented as individual performance scores |

**Acceptance criteria**

- **AC-CROSS-01** One test case's outcomes across four machines are displayable in one comparison.
- **AC-CROSS-02** Any dashboard number can be drilled down to the underlying results and their origins.

---

### 9.25 Notifications

| ID | Rule |
|---|---|
| BR-NOTIFY-01 | Notifications are relevant to the recipient's responsibility |
| BR-NOTIFY-02 | The same event does not generate repeated notifications |
| BR-NOTIFY-03 | Notifiable events include at minimum: critical test failure, new critical bug, bug assigned, bug ready for retest, retest failed, scheduled run failed or missed, significant regression detected, import conflict raised, known issue expired |
| BR-NOTIFY-04 | Every notification states what happened, why the recipient is receiving it, and what action is expected |
| BR-NOTIFY-05 | A user may adjust their own notification preferences within the limits their role allows |
| BR-NOTIFY-06 | Delivered notifications are retained and reviewable |

**Acceptance criteria**

- **AC-NOTIFY-01** A bug assigned to a developer produces exactly one notification to that developer.
- **AC-NOTIFY-02** A test failing in ten consecutive scheduled runs produces one notification, not ten.

---

### 9.26 Reporting and Dashboards

Reporting areas: **Coverage, Execution, Quality, Bugs, Team, Change Impact, Release, Consolidation, Testing Debt.**

| ID | Rule |
|---|---|
| BR-RPT-01 | Every report is derived from recorded results, never from current status alone |
| BR-RPT-02 | Every figure is drillable to its underlying records |
| BR-RPT-03 | Every report states its period, its filters and its data cut-off |
| BR-RPT-04 | Reports must distinguish "zero" from "unknown" from "not applicable" |
| BR-RPT-05 | Reports respect access control without silently omitting data — they state that data was withheld |
| BR-RPT-06 | Dashboards must load within an acceptable time at full data volume (see §14) |

**Acceptance criteria**

- **AC-RPT-01** "Pass rate 92%" can be expanded to the exact runs and results behind it.
- **AC-RPT-02** A module with no tests reports "no coverage", not "100% passed".

---

### 9.27 Search and Analysis

**BR-SEARCH-01:** Users can locate testing information by module, category, menu, screen, test case, tag, criticality, user, machine, environment, result, attempt, bug, severity, priority, requirement, release, date range, code version, commit, suite, status and flakiness state — individually and in combination.

**BR-SEARCH-02:** Any saved search may be re-run and shared.

**AC-SEARCH-01:** A search combining five filters over the full data volume returns within the performance target in §14.

---

### 9.28 AI-Assisted Analysis

| ID | Rule |
|---|---|
| BR-AI-01 | AI output is a recommendation, never a fact |
| BR-AI-02 | Important decisions remain reviewable and reversible by authorised users |
| BR-AI-03 | Every AI conclusion carries the evidence it used and a confidence |
| BR-AI-04 | Confirmed information and AI suggestions are always visually and structurally distinguishable |
| BR-AI-05 | Every AI recommendation carries a review state: proposed, accepted, rejected, superseded |
| BR-AI-06 | AI must never modify historical results, bug status or catalog data directly; it proposes, a person disposes |
| BR-AI-07 | AI recommendation accuracy is measured against subsequent human decisions and reported |
| BR-AI-08 | Data sent to any external AI service is governed: no credentials, no tenant data, no personally identifying school data |

Candidate applications: duplicate test detection, duplicate bug detection, failure clustering, flakiness assessment, regression assessment, probable root cause, impacted-test recommendation, coverage gap identification, test case drafting from requirements, historical summarisation.

**Acceptance criteria**

- **AC-AI-01** Every AI recommendation displays its reasoning inputs and confidence.
- **AC-AI-02** Accepting or rejecting a recommendation is recorded with actor and time.
- **AC-AI-03** An acceptance-rate report by recommendation type is available.

---

### 9.29 Audit, Retention and Deletion

| ID | Rule |
|---|---|
| BR-AUDIT-01 | Business-significant changes are traceable: actor, machine, entity, before, after, time |
| BR-AUDIT-02 | Audit information is not casually deletable and its own deletion is auditable |
| BR-AUDIT-03 | Audit distinguishes user activity from system activity |
| BR-AUDIT-04 | Audit records are retained at least as long as the data they describe |
| BR-DELETE-01 | Business records are retired, not destroyed |
| BR-DELETE-02 | Retired records do not appear in active operational views |
| BR-DELETE-03 | Historical reports may still reference retired records |
| BR-DELETE-04 | Permanent deletion is an administrative act requiring a recorded reason |
| BR-RET-01 | Retention is defined per information class and is configurable |
| BR-RET-02 | Retention must never destroy information required for an active investigation, an open bug, or an unclosed release |
| BR-RET-03 | Purging is a deliberate, recorded, reviewable operation with a preview of what will be removed |
| BR-RET-04 | Large evidence artefacts may be purged before the results that reference them, and the result must then show its evidence as expired |

**Acceptance criteria**

- **AC-AUDIT-01** For any bug, the complete sequence of who changed what and when is displayable.
- **AC-RET-01** A purge preview lists counts by class before anything is removed.
- **AC-RET-02** Evidence for an open bug is never purged.

---

## 10. Core Business Rules

These sixteen rules govern every other requirement. Where a design decision conflicts with one of them, the rule wins.

| # | Rule | Consequence if violated |
|---|---|---|
| **R-01** | **History must be preserved.** Historical evidence is never sacrificed to simplify current data | The application's core value disappears |
| **R-02** | **Origin must be preserved.** Where information came from is always determinable | Consolidated data becomes unaccountable |
| **R-03** | **Same number does not mean same entity.** Independent records with equal visible codes are not equal | Silent data corruption on import |
| **R-04** | **User and machine are different concepts** | Environment-specific defects become invisible |
| **R-05** | **Current state and historical state are different.** Changing status never rewrites history | Reports change meaning retroactively |
| **R-06** | **Failure is not automatically a bug.** It may be a new bug, a known bug, a flaky test, an environment problem, a data problem, or expected | Defect counts become meaningless |
| **R-07** | **Bug and bug occurrence are different** | Defect counts inflate; triage duplicates |
| **R-08** | **Fixed does not equal verified.** Only a passing retest verifies | Defects reach users |
| **R-09** | **Retest must preserve the original failure** | The evidence of what went wrong is lost |
| **R-10** | **Independent information stays independent until confirmed** | Wrong merges destroy real distinctions |
| **R-11** | **Consolidation must be traceable and reversible** | Bad merges become permanent |
| **R-12** | **AI assists; it does not decide** | Unverifiable conclusions enter the record |
| **R-13** | **Derived data is never authoritative.** Every statistic must be rebuildable from recorded results | Corruption becomes undetectable |
| **R-14** | **Every automated action is attributable and bounded.** Automation has an owner, a reason and a limit | Uncontrolled loops, unexplained data |
| **R-15** | **Evidence outlives opinion.** Artefacts are retained per policy independently of anyone's current conclusion | Conclusions cannot be re-examined |
| **R-16** | **The application reports discrepancies rather than resolving them silently** | The business is misled by tidy but wrong data |

---

## 11. Business Lifecycles

### 11.1 Overall lifecycle

```
Application Requirement
        ↓
Functionality identified (module → screen)
        ↓
Test cases created or discovered  ←──────────── Test-case work request
        ↓
Test cases reviewed and versioned
        ↓
Tests selected (manual / suite / schedule / impact analysis)
        ↓
Tests executed  (run → run items → attempts)
        ↓
Results and evidence captured
        ↓
Failures triaged  → Known issue │ Flaky │ Environment │ New bug │ Existing bug
        ↓
Bug assigned → fixed → retested → verified or reopened
        ↓
Regression executed
        ↓
Release assessed
        ↓
History accumulated → analysed → improves the next selection
```

### 11.2 Test Case lifecycle

`Draft → Under Review → Active → (Needs Update) → Active → Retired`
plus `Orphaned` when the implementation disappears from the source tree.

**BR-LC-TC-01:** Only Active test cases are selected automatically. Draft, Needs Update and Orphaned test cases may be executed on request but are reported separately.

### 11.3 Test Run lifecycle

`Queued → Running → Completed`
with terminal alternatives `Failed`, `Cancelled`, `Interrupted`, `Timed Out`.

**BR-LC-RUN-01:** A run in Running that has not reported progress within the configured interval is moved to Interrupted with its partial results retained.

### 11.4 Bug lifecycle

```
Open ──► Assigned ──► In Progress ──► Fixed ──► Retesting ──► Closed (Verified)
  │                                                │
  │                                                └──► Reopened ──► Assigned
  ├──► Wont Fix
  ├──► Duplicate (of another bug)
  └──► Escalated  (retest limit exceeded, or SLA breached)
```

**BR-LC-BUG-01:** Fixed → Closed requires a recorded passing retest, or an authorised override with a recorded reason.
**BR-LC-BUG-02:** Every transition is recorded. Undefined transitions are refused.

### 11.5 Test-Case Work Request lifecycle

`Pending → In Progress → Completed`, with `Cancelled` and `Hold`. Completion requires a named test case.

### 11.6 Import lifecycle

`Received → Validated → Applied → Completed`, with `Rejected`, `Partial` and `Reversed`.

**BR-LC-IMP-01:** An import that raises conflicts stops at Partial until each conflict has a recorded decision.

### 11.7 Test case equivalence lifecycle

`Unmapped → Proposed Equivalent → Confirmed Equivalent`
or `Confirmed Different`, with reversal to `Unmapped` permitted and recorded.

---

## 12. Business Decisions Register

v1 ended with twenty unanswered questions. Each is answered here with a recommendation. **Decisions marked ⚠ materially change the solution and must be confirmed before build.**

| ID | Decision | Recommended answer | Rationale |
|---|---|---|---|
| **D-01** ⚠ | Is the test-case catalog central or per-machine? | **Central Catalog mode by default**, with the source-test-case layer retained for offline authoring and import reconciliation | Prime-AI has one code base; test cases describe that one code base. Independent numbering is an import-time reality, not the normal working model |
| **D-02** | When are two independently created tests "the same"? | When they verify the same behaviour of the same screen with the same expected result. Confirmed by a QA Lead, never automatically | Prevents both silent merging and permanent duplication |
| **D-03** | Can one user modify another's test case? | In Central Catalog mode, yes within role limits — every change is versioned and attributed. In Local-then-Promote mode, only the author may edit before promotion | Shared catalog needs shared maintenance |
| **D-04** | Who approves duplicate/equivalence consolidation? | QA Lead or Architect | Requires domain judgement |
| **D-05** | What stays local? | In-progress runs, raw artefacts above the configured size, machine configuration | Everything else consolidates |
| **D-06** | What must consolidate? | Runs, run items, results, bugs, occurrences, retests, notes, discovery logs, source test cases, audit | These are the evidence |
| **D-07** ⚠ | Is the central database reporting-only or authoritative? | **Authoritative for catalog** (modules, screens, canonical test cases, suites, requirements, masters, users, machines); **aggregating for evidence** | Matches BR-OPMODEL-01 |
| **D-08** | Are bugs global once imported? | Yes. A bug is a property of Prime-AI, not of a machine | Otherwise the same defect is tracked many times |
| **D-09** | Are application requirements global? | Yes, and centrally governed | Coverage must be counted once |
| **D-10** | Default automatic retest scope | The failing test case, plus other test cases on the same screen, plus tests directly dependent on it | Balances confidence against cost |
| **D-11** | Definition of flaky | Two or more outcome alternations within the last 10 executions, in the same environment, with no intervening change to the test case or the covered code | Evidence-based and computable |
| **D-12** | Definition of regression | A test that passed at least once in the last 30 days, in a comparable environment, now failing, and not confirmed flaky | Evidence-based and computable |
| **D-13** | What triggers impact analysis? | Any commit or merge touching a mapped source path; any bug marked fixed; any release scope change | Automatic proposal, human approval |
| **D-14** | Which tests are critical? | Those covering critical application requirements, plus those historically detecting critical defects, plus those manually designated | Combines judgement and evidence |
| **D-15** | Retention | Results and bugs: indefinite. Raw artefacts: 180 days by default. Audit: 3 years. All configurable | Evidence is cheap; artefacts are not |
| **D-16** | What is automated? | Discovery, execution of automated tests, statistics, failure grouping, impact proposal, retest triggering, notifications, import matching | Everything repetitive |
| **D-17** | What always requires a human? | Equivalence and duplicate confirmation, bug closure, release recommendation acceptance, impact-scope approval, permanent deletion, conflict resolution | Everything judgemental |
| **D-18** | Acceptable AI level | Recommendation with evidence and confidence, with a review state. No autonomous mutation of record data | R-12 |
| **D-19** | Management dashboard content | Coverage, pass-rate trend, open critical bugs, regression count, flaky count, testing debt, release readiness | Decision-relevant only |
| **D-20** | Ultimate measure of testing effectiveness | **Escaped defect rate** — defects found after release that existing tests should have caught — supported by impact-analysis hit rate | Measures outcome, not activity |
| **D-21** ⚠ | Version compatibility across machines | Central accepts exports from the current schema version and one prior minor version; older is migrated on import or refused with a stated reason | BC-13 |
| **D-22** | Manual test evidence obligation | Mandatory for any Failed or Blocked manual step; optional otherwise | Investigability without bureaucracy |

---

## 13. Business Success Criteria and KPIs

### 13.1 The application succeeds when the business can answer, from recorded evidence:

**Testing** — What needs testing? What has been tested? What has not? What is failing now?
**History** — Has this failed before? When did it first fail? When did it last pass? How often does it fail?
**Bugs** — Is this failure a known bug? Who owns it? Is it fixed? Was the fix verified?
**Regression** — Did this work before? What changed? Is this a regression, and on what evidence?
**Flakiness** — Is the test itself unreliable? On what evidence?
**Impact** — What could this change affect? What should we run? What did we choose not to run, and why?
**Team** — Who created, executed, owns, fixed and verified?
**Consolidation** — Where did this information originate? Are these two tests the same? Can we analyse all machines together?
**Release** — Is this release ready, on what evidence, and with what reservations?

### 13.2 KPIs

| KPI | Definition | Target |
|---|---|---|
| K-01 Screen coverage | Screens with at least one active test case ÷ in-scope screens | ≥ 90% by end of Phase 3 |
| K-02 Requirement coverage | Requirements with at least one passing test ÷ all requirements | ≥ 85% |
| K-03 Automation ratio | Automated test cases ÷ all test cases | ≥ 70% |
| K-04 Escaped defect rate | Post-release defects an existing test should have caught ÷ all post-release defects | ↓ trend, < 15% |
| K-05 Impact hit rate | Defects found inside the proposed impact scope ÷ all defects found in that run | ≥ 80% |
| K-06 Test selection efficiency | Average tests executed per change ÷ full suite size | ≤ 25% with K-05 held |
| K-07 Flaky ratio | Confirmed flaky ÷ active test cases | ≤ 2% |
| K-08 Mean time to verify | Bug Fixed → Verified | ≤ 2 working days |
| K-09 Bug reopen rate | Reopened ÷ closed | ≤ 10% |
| K-10 Stale test ratio | Active tests not executed in 90 days ÷ active tests | ≤ 10% |
| K-11 Consolidation latency | Local result → available centrally | ≤ 1 working day |
| K-12 AI acceptance rate | Accepted AI recommendations ÷ reviewed | Tracked, not targeted |
| K-13 Evidence completeness | Failed results with usable evidence ÷ failed results | ≥ 95% |

---

## 14. Assumptions, Constraints and Risks

### 14.1 Assumptions

| ID | Assumption |
|---|---|
| A-01 | Prime-AI's module and screen structure is discoverable from its source tree |
| A-02 | The team uses Git, and commit history is available to the Testing Application |
| A-03 | User and machine registration is performed by one accountable administrator |
| A-04 | Testers have local execution capability for automated tests |
| A-05 | Export files are exchanged over a trusted channel |
| A-06 | The central installation is backed up |
| A-07 | Manual test execution will remain a material part of testing for the foreseeable future |

### 14.2 Constraints

| ID | Constraint |
|---|---|
| CN-01 | Must operate offline on each machine |
| CN-02 | Must consolidate through file exchange, not a live connection |
| CN-03 | Must remain usable with 100,000+ test cases and millions of results |
| CN-04 | Machines may run different versions of the application concurrently |
| CN-05 | No Prime-AI tenant or personal data may be stored in test evidence beyond what is strictly necessary, and none may be sent to external AI services |
| CN-06 | Operational screens must respond within 3 seconds, and dashboards within 5 seconds, at full data volume |

### 14.3 Risks

| ID | Risk | Impact | Mitigation |
|---|---|---|---|
| RK-01 | Catalog divergence between machines | Consolidation conflicts | Central governance (D-07); version-stamped catalog distribution |
| RK-02 | Evidence storage growth | Cost, performance | Retention policy (D-15); artefacts outside the database |
| RK-03 | Flaky tests erode trust in the suite | Test results ignored | Explicit flakiness lifecycle and testing-debt reporting |
| RK-04 | Impact analysis misses a defect | False confidence | Measure K-05; always retain a periodic full regression |
| RK-05 | Over-trusting AI recommendations | Wrong merges, wrong closures | R-12, BR-AI-05, human review states |
| RK-06 | Import conflicts accumulate unresolved | Consolidation stalls | Conflict queue with ownership and ageing |
| RK-07 | The application becomes a reporting burden | Adoption failure | Automate discovery, statistics, grouping and selection; keep manual entry minimal |
| RK-08 | Schema drift between machine versions | Import failure | D-21 version compatibility policy |
| RK-09 | Personal metrics misread as performance scoring | Team harm | BR-CROSS-06 |

---

## 15. Phased Delivery and Acceptance

| Phase | Delivers | Business acceptance |
|---|---|---|
| **1 — Record** | Users, roles, machines, catalog, test cases with steps, discovery, execution, results, evidence, bugs, audit, core dashboards | A tester can execute and record a full day's testing, and a QA Lead can read it the next morning |
| **2 — Consolidate** | Suites, application requirements and coverage, work-request backlog, known issues, occurrences, retest cycles, environments, export/import | Two machines' testing can be analysed together, with origins intact |
| **3 — Analyse** | Flakiness, regression, Git traceability, impact analysis and selection, dependencies, schedules, notifications | The application proposes what to test after a change, and a QA Lead approves it |
| **4 — Advise** | Releases, cross-machine comparison, AI recommendations, release readiness | The application produces an evidence-based release assessment with stated reservations |

**Overall acceptance:** the business can answer every question in §13.1 from recorded evidence, without asking a person to remember anything.

---

## 16. Enhancements

The following are **additional capabilities proposed beyond v1**. Each states the business problem it solves, the value, and the effort in relative terms. They are recommendations, not committed scope.

### 16.1 Test intelligence

**E-01 — Test Confidence Score.** *(v1 AS-BR-01, now specified)*
A per-test-case score derived from execution count, recent pass rate, stability, environment breadth, age of last execution and open related bugs.
*Problem it solves:* "It passed" says nothing about whether that pass means anything. *Value:* release decisions weight strong evidence over weak. *Effort:* Low — derived from data already held.

**E-02 — Test Health Status.** *(v1 AS-BR-02)*
Each test case carries a health state: Healthy, Unstable, Frequently Failing, Obsolete, Blocked, Insufficient History, Under Investigation, Orphaned.
*Value:* a 100,000-test inventory becomes triageable by exception. *Effort:* Low.

**E-03 — Testing Debt Register.** *(v1 AS-BR-03, now a managed object)*
A standing, owned, ageing register of: untested screens, missing regression coverage, tests never executed, tests without requirements, stale tests, permanently failing tests, duplicates, confirmed flaky tests, orphaned tests.
*Value:* quality erosion becomes visible and assignable rather than accumulating silently. *Effort:* Medium.

**E-04 — Risk-Based Test Prioritisation.** *(v1 AS-BR-05)*
Ranking that combines business criticality, recent change, historical failure density, open bugs, usage frequency and test reliability.
*Value:* when the testing window is short, the right 200 tests run instead of an arbitrary 200. *Effort:* Medium.

**E-05 — Coverage Heat Map.**
A module × screen grid coloured by coverage, recent failure density and open bugs.
*Value:* one screen shows where quality risk actually lives. *Effort:* Low.

**E-06 — Mutation-style coverage challenge (long term).**
Periodically verify that tests actually detect deliberately introduced faults in the code they claim to cover.
*Value:* distinguishes tests that pass from tests that would catch a break. *Effort:* High.

### 16.2 Defect and failure intelligence

**E-07 — Failure Clustering.**
Group failures across runs, machines and users by normalised failure signature; present the cluster, not each instance.
*Value:* one triage decision instead of forty. *Effort:* Medium.

**E-08 — First-Failing-Change Identification.**
For a regression, identify the narrowest range of commits between the last pass and the first failure, and optionally bisect by re-running.
*Value:* removes most of the manual work of "what broke this". *Effort:* Medium–High.

**E-09 — Defect Prediction by Area.**
Rank modules and screens by predicted defect likelihood from change frequency, historical defect density, complexity and coverage gaps.
*Value:* directs both testing and review attention. *Effort:* Medium.

**E-10 — Bug SLA and Ageing.**
Configurable SLA per severity, with ageing buckets, breach notification and an escalation path.
*Value:* nothing critical sits unnoticed. *Effort:* Low.

**E-11 — Root-Cause Category Taxonomy.**
Record a cause category on each closed bug: logic, validation, data, tenancy, permission, integration, UI, performance, environment, test defect.
*Value:* after a hundred bugs, the pattern of *why* becomes visible and actionable. *Effort:* Low.

### 16.3 Process and workflow

**E-12 — Pre-Commit Test Gate.**
A developer, before committing, asks the application which tests their working changes affect and runs exactly those.
*Value:* defects are caught before they reach anyone else. This is the highest-value single feature in this list. *Effort:* Medium.

**E-13 — Review Queues as First-Class Screens.**
Standing queues for: discovered items awaiting confirmation, proposed equivalences, proposed duplicates, import conflicts, expiring known issues, AI recommendations, unassigned failures.
*Value:* judgement work has one place to happen instead of being scattered. *Effort:* Medium.

**E-14 — Test Execution Session (manual).**
A guided manual runner: pick a suite, step through each test case, record per-step outcomes and evidence, pause and resume, hand over to another tester.
*Value:* makes manual testing as recordable as automated testing. *Effort:* Medium.

**E-15 — Exploratory Testing Charters.**
Time-boxed, chartered exploratory sessions recorded with notes, evidence and defects found, counted as coverage of a different kind.
*Value:* recognises testing that no test case describes. *Effort:* Low–Medium.

**E-16 — Test Data Requirements and Fixtures.**
Record what data state a test case needs, and which fixture or seed provides it.
*Value:* removes the most common cause of "it fails on my machine". *Effort:* Medium.

**E-17 — Sign-off Workflow.**
Explicit, recorded sign-off for release readiness, with named approver, scope, reservations and date.
*Value:* release decisions become evidence, not conversation. *Effort:* Low.

### 16.4 Platform and operations

**E-18 — Catalog Distribution Bundles.**
A version-stamped catalog bundle published centrally and applied by each machine, so every machine provably holds the same catalog version.
*Value:* eliminates the largest class of import conflicts before it occurs. *Effort:* Medium.

**E-19 — Machine Health and Readiness Check.**
Before a run, verify the machine's environment against the expected profile — versions, browser, driver, database, disk space — and record the check.
*Value:* separates "the product is broken" from "this laptop is not ready". *Effort:* Low.

**E-20 — Evidence Store with Lifecycle.**
Artefacts held outside the database with deduplication by content hash, tiering and expiry, referenced by result.
*Value:* keeps the database fast and the evidence affordable. *Effort:* Medium.

**E-21 — Public Read-Only Quality Page.**
A single, always-current, link-shareable quality summary for people who will never open the application.
*Value:* stops the recurring "what's the status?" interruption. *Effort:* Low.

**E-22 — Webhook and CI Integration.**
Accept results from CI, and emit events on failure, regression and bug transitions.
*Value:* the Testing Application becomes the record for all execution, not only local execution. *Effort:* Medium.

**E-23 — Scheduled Digest.**
A daily or weekly summary per role: what failed, what regressed, what is assigned to you, what is awaiting your review.
*Value:* the application reaches people rather than waiting to be visited. *Effort:* Low.

### 16.5 Intelligence and assistance

**E-24 — Test Case Drafting from Requirements and Screens.**
Propose draft test cases — including manual steps — from an application requirement or a screen's requirement document, for human review before entering the catalog.
*Value:* addresses the coverage bottleneck directly; drafting is where the effort actually goes. *Effort:* Medium.

**E-25 — Natural Language Query over Testing History.**
"Show me every test that failed after the Fees module changed last month and has not passed since."
*Value:* removes the reporting bottleneck for non-technical stakeholders. *Effort:* Medium.

**E-26 — Explanation Panel.**
Every derived conclusion — flaky, regression, impacted, duplicate, recommended — offers a "why does it say that?" panel listing the evidence.
*Value:* the single largest determinant of whether the team trusts the application. *Effort:* Low, if designed in from the start; expensive if retrofitted.

**E-27 — Historical Knowledge Base.** *(v1 AS-BR-07)*
Automatically composed, per-area narrative of what failed, why, how it was fixed, which tests caught it and which change caused it.
*Value:* the organisation stops depending on individual memory. *Effort:* Medium.

**E-28 — Release Quality Assessment.** *(v1 AS-BR-08)*
A structured assessment — testing status, defect status, regression status, coverage, risk, reservations, recommendation — retained as issued.
*Value:* converts release confidence from opinion into evidence. *Effort:* Medium.

### 16.6 Recommended enhancement sequence

| Priority | Enhancements | Reason |
|---|---|---|
| **First** | E-26, E-02, E-01, E-10, E-13 | Cheap, immediately useful, and E-26 must be designed in from the start |
| **Second** | E-12, E-07, E-03, E-19, E-23 | Highest daily value to developers and QA |
| **Third** | E-04, E-08, E-14, E-16, E-18, E-20 | Efficiency and reliability at scale |
| **Fourth** | E-24, E-27, E-28, E-22, E-25 | Compounding value once history exists |
| **Later** | E-06, E-09, E-15, E-17, E-21 | Valuable but not on the critical path |

---

## 17. Document Boundary

This document answers **what the business needs** and **why**.

- `Solution_Design_v2.md` answers *how users perform these activities* and *how the system implements them*.
- `testing_DDL_v7.0.sql` answers *how the information is represented and related*.

Where any of the three conflict, **this document governs the intent** and the others must be corrected.

---

## 18. Final Business Principle

> **Testing information must remain independently identifiable and historically trustworthy, while the application must also be capable of recognising when independently created information represents the same logical entity.**

And the outcome the business is buying:

> The application should not merely answer *"did this test pass?"*. It should answer: **what was tested, by whom, where, when, against which version, what happened historically, why it failed, whether it is a real defect or a known one, whether the fix worked, what else may be affected, and what we should test next.**

---

**End of TestingApp_BRD_v2.md**
