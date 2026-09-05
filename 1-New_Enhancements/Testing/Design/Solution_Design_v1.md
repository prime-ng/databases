# Prime-AI Testing Application
## Requirement Detail & Functional Specification
### Working Draft — For Review and Enhancement

---

# 1. Purpose of the Application

The Testing Application is intended to provide a centralized and structured system for managing, executing, monitoring and analyzing software test cases for the Prime-AI application.

The system should support the complete testing lifecycle:

1. Discovering application modules, screens and automated tests.
2. Creating and maintaining test cases.
3. Executing individual or multiple test cases.
4. Recording every execution and its result.
5. Maintaining historical execution data.
6. Identifying failures, regressions and flaky tests.
7. Recording and tracking bugs.
8. Assigning bugs to developers.
9. Retesting fixed bugs automatically or manually.
10. Managing test-case requirements/backlog.
11. Maintaining relationships between requirements, test cases, bugs and application areas.
12. Understanding the impact of application changes on testing.
13. Comparing test execution results across developers and machines.
14. Exporting locally generated testing data.
15. Importing data into a central database.
16. Combining the user's own historical executions with imported executions.
17. Providing dashboards, reports and analytical views for QA, developers, reviewers and management.

The application is intended primarily as an **internal testing and quality-management platform** for the Prime-AI development team.

---

# 2. Fundamental Architectural Requirements

## FR-001 — Local-First Application

The application shall operate locally on each developer/tester's laptop or desktop.

Each installation shall maintain its own local testing database.

The application shall not require continuous access to a central database for normal test creation or execution.

A developer should be able to:

- discover test cases;
- create/update test cases;
- execute tests;
- record test results;
- create bugs;
- add notes;
- manage requirements;
- review historical local results;

while working completely against the local database.

---

# 3. Multi-User Requirement

## FR-002 — Multiple Users

The application shall support multiple users.

Each user shall have:

- unique user code;
- name;
- email;
- password;
- role;
- active/inactive status;
- system-user designation where applicable.

The current DDL identifies roles such as:

- Admin
- Architect
- QA Lead
- Tester
- Developer
- Reviewer

The application also has system users such as `sys` intended for system-generated operations such as automated retesting.

---

# 4. Multi-Machine Requirement

## FR-003 — One User May Use Multiple Machines

A single user may work from multiple computers.

For example:

```text
User BRijesh
    ├── Machine M01
    ├── Machine M02
    └── Machine M03
```

The system must therefore distinguish:

```text
User + Machine
```

rather than assuming that a user is associated with only one computer.

---

# 5. Machine Identity

## FR-004 — Every Installation Shall Have a Machine Identity

Every installation of the Testing Application shall be associated with a unique machine identity.

The machine identity shall be assigned/provisioned in a controlled manner and persisted locally.

The system shall not simply generate an independent AUTO_INCREMENT machine ID on every local database because independent databases could all generate:

```text
machine_id = 1
```

The machine identity should therefore be independent of the local database's AUTO_INCREMENT sequence.

Machine metadata may include:

- machine code;
- machine name/hostname;
- operating system;
- hardware information;
- application installation information;
- machine fingerprint;
- registration status;
- first-seen date;
- last-seen date.

Hardware serial number, MAC address or similar information may be retained as metadata/fingerprint, but should not necessarily be treated as the application's primary business identity.

---

# 6. Distributed Data Identity

## FR-005 — No UUID-Based Distributed Identity

The system shall NOT depend on UUIDs for identifying test runs, test-run items or test results.

The preferred identity strategy shall use:

```text
AUTO_INCREMENT numeric ID
+
source machine identity
+
appropriate source/user/business identity
```

This is intended to keep the database simple and efficient while still allowing locally generated records to be safely consolidated.

---

# 7. Local Test Case Identity

## FR-006 — Test Case Codes Are Local/User/Machine Scoped

A test-case number such as:

```text
TC001
```

shall NOT automatically be considered globally unique.

Different users may independently create the same test-case number for the same screen.

Example:

```text
Machine M01 / User BRijesh / TS001 / TC001

Machine M02 / User Tarun   / TS001 / TC001
```

These may represent two independently created source test cases.

Therefore the source/local test-case identity shall be based on:

```text
Machine
+
User
+
Tab/Screen
+
Test Case Code
```

Conceptually:

```text
(machine_id, user_code, ts_code, test_case_code)
```

The same numeric `test_case_code` may therefore legitimately exist for different users and/or machines.

---

# 8. Canonical Test Case Identity

## FR-007 — Source Test Case and Canonical Test Case Shall Be Distinguishable

The system should distinguish between:

### Source Test Case

The test case as created/discovered on a particular developer machine.

Example:

```text
M01 / BRijesh / TS001 / TC001
```

### Canonical Test Case

A centrally recognized logical test case.

Two source test cases may eventually be determined to represent:

- the same logical test case;
- similar but different test cases;
- intentionally duplicated tests;
- variations of the same test scenario.

The system should therefore allow source test cases to be mapped to a canonical/shared test case when appropriate.

The mapping should not automatically assume that equal test-case codes mean equal test cases.

---

# 9. Application Hierarchy

## FR-008 — Application Functional Hierarchy

The Testing Application shall understand the Prime-AI application through a hierarchy broadly represented as:

```text
Module
   ↓
Category
   ↓
Main Menu
   ↓
Sub Menu (optional)
   ↓
Tab / Screen
   ↓
Test Case
```

---

# 10. Module Management

## FR-009 — Modules

The system shall maintain application modules.

A module may contain:

- module code;
- module name;
- description;
- folder name;
- version;
- active/inactive status;
- ordering;
- audit information.

Modules are expected to correspond to the Prime-AI application/module structure.

---

# 11. Category Management

## FR-010 — Categories

The system shall support categories within modules.

A category shall have:

- category code;
- name;
- module association;
- active/inactive status;
- ordering.

---

# 12. Main Menu Management

## FR-011 — Main Menus

The system shall maintain main-menu/application-area definitions.

Each main menu may contain:

- menu code;
- name;
- route URL;
- module;
- category;
- active status;
- ordering.

---

# 13. Sub Menu Management

## FR-012 — Optional Sub Menus

A main menu may optionally contain sub menus.

The application must support both:

```text
Main Menu
   ↓
Tab
```

and:

```text
Main Menu
   ↓
Sub Menu
   ↓
Tab
```

---

# 14. Tab / Screen Management

## FR-013 — Tab/Screen

A Tab/Screen represents a testable functional area of the application.

A screen may contain:

- screen code;
- name;
- route URL;
- folder path;
- application hierarchy;
- development status;
- test-case creation status;
- active/inactive status;
- exclusion status.

The current schema defines `ts_code` as a structured application-area identifier.

---

# 15. Screen Exclusion

## FR-014 — Out-of-Scope Screens

A screen shall be capable of being marked as excluded from testing.

Excluded screens should not necessarily be physically deleted from the catalog.

The system should retain the screen for historical/reference purposes while excluding it from normal testing workflows.

---

# 16. Test Case Creation

## FR-015 — Test Case Definition

The system shall support creation of test cases associated with a Tab/Screen.

A test case should contain information such as:

- source owner;
- screen;
- test-case code;
- module;
- file path;
- namespace;
- class name;
- method name;
- display name;
- description;
- test case type;
- testing method;
- testing technology;
- testing layer;
- creation status;
- requirements document reference;
- active status.

---

# 17. Automated and Non-Automated Test Cases

## FR-016 — Automated / Manual / Hybrid Tests

The system shall support at least:

- Manual
- Automated
- Hybrid

test execution methods.

A test-case record may represent an automated test discovered from source code or a test that is currently not automated but is required for future implementation.

---

# 18. Test Case Metadata

## FR-017 — Test Classification

Test cases should be classifiable by:

### Test Case Type

Examples:

- Standard
- Unit
- Validation
- Feature
- Business Condition

### Testing Method

Examples:

- Manual
- Automated
- Hybrid

### Testing Technology

Examples:

- Dusk
- Laravel Unit
- Native
- Other technologies as required

### Testing Layer

Examples:

- GUI
- API
- Unit
- Integration
- Performance
- Security
- Accessibility
- Other

---

# 19. Test Case Versioning

## FR-018 — Test Case History

Changes to the definition of a test case should be historically traceable.

The system should be able to determine:

- what the test case looked like at a particular point in time;
- who changed it;
- when it changed;
- what changed;
- which execution used which version of the test.

This is important because historical test results must remain meaningful even after the test definition changes.

---

# 20. Test Discovery / Synchronization

## FR-019 — Automated Test Discovery

The application shall be capable of discovering automated tests from the Prime-AI source-code structure.

Discovery should identify at least:

- modules;
- screens;
- test files;
- namespaces;
- classes;
- test methods;
- display names where available.

The system should detect:

- new tests;
- changed tests;
- removed tests;
- inactive tests.

---

# 21. Synchronization History

## FR-020 — Discovery/Sync Audit

Each discovery/synchronization operation shall be recorded.

The history should capture:

- who initiated it;
- machine;
- start time;
- completion time;
- status;
- number of modules found;
- number of tabs found;
- test cases added;
- test cases updated;
- test cases removed;
- detailed messages/errors.

---

# 22. Test Execution

## FR-021 — Test Run

A Test Run represents one execution request.

A run may contain:

- one test case;
- multiple test cases;
- an entire screen;
- a module;
- a test suite;
- a selected set of tests;
- tests selected because of application-code impact.

A run shall have its own numeric local ID.

---

# 23. Run Source Identity

## FR-022 — Distributed Run Identity

For central consolidation, the source identity of a run shall be represented conceptually by:

```text
machine_id + source_run_id
```

Example:

```text
Machine M01 / Run 1
Machine M02 / Run 1
```

These must remain distinguishable.

When imported centrally, the central database may assign a new local/central numeric `id`, while retaining the original source identity.

---

# 24. Test Run Metadata

## FR-023 — Run Information

A test run should record:

- initiating user;
- executing user/system;
- machine;
- trigger type;
- command executed;
- status;
- start time;
- finish time;
- duration;
- exit code;
- test counts;
- assertion counts;
- environment information;
- raw output location.

---

# 25. Run Trigger Types

## FR-024 — Execution Trigger

The system shall distinguish at least:

- Manual
- Scheduled
- Rerun
- Auto Retest

This is necessary for understanding why a particular execution occurred.

---

# 26. Run Items

## FR-025 — Test Cases Within a Run

A run may contain multiple test cases.

Each selected test case shall have an individual Run Item.

Example:

```text
Run #100
   ├── TC001
   ├── TC002
   ├── TC003
   └── TC004
```

The run item must identify the source/canonical test case being executed.

---

# 27. Run Results

## FR-026 — Individual Test Result

Each execution of a test case shall produce a result record.

The result should capture:

- test case reference;
- run reference;
- execution user;
- display name snapshot;
- result status;
- duration;
- assertion count;
- error message;
- error trace;
- screenshot;
- console log;
- source HTML where applicable;
- related bug(s), where applicable.

---

# 28. Result Status

## FR-027 — Test Result States

At minimum:

- Passed
- Failed
- Skipped
- Error

shall be supported.

The system should preserve the exact historical result and should not overwrite a previous execution result.

---

# 29. Attempt / Re-Execution

## FR-028 — Multiple Attempts

If a test case is executed multiple times, every attempt shall be preserved.

For example:

```text
Run 100
   TC001 → Failed

Run 101
   TC001 → Passed

Run 102
   TC001 → Failed
```

The historical sequence is important for identifying flaky behavior and regressions.

---

# 30. Test Run Summary

## FR-029 — Fast Test Case Statistics

The application should maintain derived statistics for fast dashboard/reporting purposes.

Examples:

- total runs;
- passed;
- failed;
- skipped;
- last status;
- last execution time;
- consecutive failures;
- pass rate;
- average duration;
- flaky indicator.

---

# 31. Flaky Test Detection

## FR-030 — Flaky Test Identification

The application should identify tests that exhibit unstable behavior.

A test may be considered flaky when:

- it alternates between Passed and Failed;
- failures occur without corresponding application-code changes;
- repeated execution produces inconsistent outcomes;
- environmental differences explain inconsistent results.

The system should retain the evidence used to classify a test as flaky rather than simply storing a boolean without explanation.

---

# 32. Regression Detection

## FR-031 — Regression Candidate Detection

The application should identify tests that:

1. passed historically;
2. subsequently fail;
3. have meaningful previous successful execution history.

A regression candidate should ideally be correlated with:

- source-code changes;
- Git commits;
- changed files;
- application module/screen;
- test case version;
- environment.

---

# 33. Cross-Developer Comparison

## FR-032 — Cross-User Test Comparison

The system shall allow the same logical test to be compared across different users and machines.

Example:

```text
TC001

Brijesh / M01 → Passed
Tarun   / M02 → Passed
Sameer  / M03 → Failed
```

This should help identify:

- environment-specific problems;
- machine-specific problems;
- configuration differences;
- code differences;
- reproducibility problems.

---

# 34. Environment Capture

## FR-033 — Execution Environment

The system should capture the relevant execution environment, such as:

- operating system;
- PHP version;
- Laravel version;
- browser;
- browser version;
- driver version;
- application environment;
- Git branch;
- commit;
- relevant configuration/version information.

Environment data should be stored in a structured manner where practical.

---

# 35. Test Suites

## FR-034 — Reusable Test Suites

The system should support named test suites.

A suite may contain:

- multiple test cases;
- tests from multiple screens;
- tests from multiple modules.

Suites may be used for:

- smoke testing;
- regression testing;
- release testing;
- module testing;
- pre-deployment testing;
- targeted testing.

---

# 36. Scheduled Testing

## FR-035 — Scheduled Runs

The application shall support scheduled test execution.

A schedule should contain:

- name;
- selected test scope;
- schedule/cron definition;
- active status;
- last execution;
- execution history.

---

# 37. Test Requirements Backlog

## FR-036 — Test Case Requirements

The application shall maintain a backlog of testing requirements.

A requirement may represent:

- a new test case required;
- an existing test case requiring modification;
- a new screen requiring testing;
- additional coverage required because of an enhancement;
- a business condition that is currently untested.

A requirement may contain:

- title;
- description;
- priority;
- target release;
- requester;
- assignee;
- status;
- target test case;
- completion information.

---

# 38. Requirement Lifecycle

## FR-037 — Requirement Status

Requirement states should include at least:

- Pending
- In Progress
- Completed
- Cancelled
- Hold

The lifecycle should be historically traceable.

---

# 39. Bug Management

## FR-038 — Bug Creation

A bug may be:

### Automatically generated

from a failed/error test result.

### Manually created

by QA/testers.

A manually created bug may exist without an originating test result.

---

# 40. Bug Information

## FR-039 — Bug Details

A bug should contain:

- title;
- description;
- severity;
- status;
- affected module;
- affected screen;
- affected test case;
- requirement reference where applicable;
- reporter;
- assignee;
- assignment time;
- fixed by;
- fixed time;
- fix notes;
- closed by;
- closed time;
- reopen count.

---

# 41. Bug Lifecycle

## FR-040 — Bug Status

The bug lifecycle shall support states such as:

```text
Open
Assigned
In Progress
Fixed
Retesting
Reopened
Closed
Escalated
Won't Fix
```

Every status transition should be historically recorded.

---

# 42. Bug Status History

## FR-041 — Bug Transition Audit

The system shall maintain a history of:

- previous status;
- new status;
- person/system making the change;
- date/time;
- transition note.

---

# 43. Bug Occurrence

## FR-042 — One Bug May Occur Multiple Times

The system should distinguish between:

```text
Bug
```

and:

```text
Bug Occurrence
```

A single logical bug may appear in many test runs/results.

Example:

```text
BUG-101

Run 100 → TC001 failed
Run 105 → TC001 failed
Run 110 → TC004 failed
Run 115 → TC001 failed
```

These are multiple occurrences of the same bug, not necessarily four separate bugs.

---

# 44. Bug Deduplication

## FR-043 — Duplicate Bug Detection

The system should assist QA in identifying whether a new failure represents:

- an existing bug;
- a new bug;
- a known issue;
- an environmental issue;
- a flaky test;
- an expected failure.

A failure fingerprint/error signature may be used to assist this process.

---

# 45. Automatic Retesting

## FR-044 — Bug Fix Retest

When a bug is marked Fixed, the system may automatically trigger retesting.

The retest scope should be configurable.

Possible scope:

```text
Fixed Bug's Test Case
        +
Other tests on affected Screen
        +
Related tests
        +
Regression tests
```

---

# 46. Retest Cycle

## FR-045 — Retest Cycle Tracking

Every automated retest cycle shall be independently recorded.

The system should know:

- which bug triggered it;
- affected screen;
- cycle number;
- execution/run;
- status;
- start/end;
- participating tests;
- individual bug outcomes.

---

# 47. Retest Safety Limit

## FR-046 — Maximum Automatic Retest Attempts

The system shall have a configurable safety limit for repeated automatic retesting.

For example:

```text
max_auto_retest_attempts = 5
```

After exceeding the limit, the bug should be escalated rather than causing an uncontrolled retest loop.

---

# 48. Known Issues / Exclusions

## FR-047 — Known Issue Annotation

Users should be able to annotate a test result/run as a known issue.

A known issue should be capable of being excluded from certain alerts such as flaky-test detection.

---

# 49. Run Notes / Annotations

## FR-048 — Test Execution Notes

Users shall be able to add notes to:

- a run;
- a test execution;
- potentially a specific failure.

Annotations should record:

- author;
- date/time;
- comment;
- detailed note;
- known-issue indicator.

---

# 50. Git Integration

## FR-049 — Source-Code Change Correlation

The application should integrate with Git information.

A test run should be associated with the relevant:

- repository;
- branch;
- commit;
- commit date;
- changed files.

The system should be able to determine which application areas/test cases may have been affected by a particular commit.

---

# 51. Impact Analysis

## FR-050 — Change Impact Analysis

The system should identify tests potentially affected by an application change.

For example:

```text
Git Commit
   ↓
Changed File
   ↓
Module
   ↓
Screen
   ↓
Related Test Cases
   ↓
Recommended Tests
```

This may be used to automatically create a targeted test run.

---

# 52. Test Case Dependencies

## FR-051 — Test Dependencies

The system should support dependencies between test cases where required.

Example:

```text
TC001 → TC002 → TC003
```

The system should be able to understand whether a test depends on another test or functional component.

Dependencies should support future impact-analysis and execution-order requirements.

---

# 53. Module-Level Dependencies

## FR-052 — Functional Dependencies

The system should also support relationships between modules/screens where useful.

This can help identify the broader impact of an enhancement or defect.

---

# 54. Export

## FR-053 — Local Data Export

A local installation shall be capable of exporting testing data.

Export may be:

- Full;
- Incremental;
- date-based;
- module-based;
- selected-scope.

The export process should itself be tracked.

---

# 55. Central Import

## FR-054 — Central Data Import

A central installation shall be capable of importing data produced by developer/tester machines.

Imported data shall retain:

- originating machine;
- originating user;
- originating source IDs;
- original timestamps;
- original execution information;
- original test-case source identity.

---

# 56. Duplicate Import Prevention

## FR-055 — Idempotent Import

The same export should not accidentally create duplicate data when imported more than once.

The system should identify already-imported source records.

For test runs, the conceptual source identity should be:

```text
source_machine_id + source_run_id
```

For source test cases:

```text
source_machine_id
+
source_user_code
+
ts_code
+
source_test_case_code
```

---

# 57. Central Consolidation

## FR-056 — Combined Analysis

The central database shall be able to analyze:

```text
Local-originated executions
+
Imported executions
```

as one analytical dataset.

The source of each execution must remain identifiable.

Example:

```text
Central DB

TC001
 ├── Brijesh / M01 / Run 10
 ├── Brijesh / M02 / Run 17
 ├── Tarun   / M03 / Run 5
 └── Sameer  / M04 / Run 21
```

---

# 58. Historical Integrity

## FR-057 — Preserve Historical Facts

Historical test execution data shall not be rewritten merely because:

- the test case was renamed;
- the test method changed;
- the screen was renamed;
- a bug was closed;
- a user changed role;
- a machine was retired.

Historical results must continue to describe what actually happened at the time.

---

# 59. Snapshot Data

## FR-058 — Execution-Time Snapshot

Where necessary, execution records should preserve snapshots of important descriptive information.

For example:

- test display name;
- test method;
- file path;
- application version;
- Git commit;
- environment;
- test-case version.

This prevents historical reports from changing when current master data changes.

---

# 60. Audit Trail

## FR-059 — System Audit

The application shall maintain an audit trail for important data changes.

The audit should capture:

- user;
- machine;
- table/entity;
- record;
- operation;
- old values;
- new values;
- timestamp;
- relevant request/client information where applicable.

---

# 61. Soft Delete

## FR-060 — Historical Deletion

Important testing records should generally not be physically deleted.

Instead, the system should support soft deletion where historical preservation is important.

Deletion should record:

- deleted date;
- deleted by;
- deletion reason where appropriate.

---

# 62. Dashboard & Reporting

## FR-061 — Testing Dashboard

The system should provide dashboards for:

### Overall Quality

- total tests;
- passed;
- failed;
- skipped;
- error;
- pass rate;
- failure rate.

### Test Case Health

- flaky tests;
- repeatedly failing tests;
- recently failing tests;
- tests not executed recently;
- tests with high execution duration.

### Bugs

- open bugs;
- critical/high bugs;
- stale bugs;
- bugs awaiting retest;
- reopened bugs;
- bugs repeatedly reopened.

### Developer Activity

- tests executed;
- failures;
- bugs raised;
- bugs assigned;
- bugs fixed;
- recent activity.

---

# 63. Role-Based Access

## FR-062 — Role-Based Permissions

Different roles should have different capabilities.

For example:

### Admin

Full system configuration and management.

### Architect

Architecture/test strategy/configuration visibility.

### QA Lead

Test management, bug assignment, reporting, approvals.

### Tester

Test execution, test-case management, bug creation and retesting.

### Developer

Test execution, bug review/fix information and relevant test data.

### Reviewer

Read/review/approval-oriented access.

Exact permission granularity should be finalized separately.

---

# 64. System Settings

## FR-063 — Application Configuration

System behavior shall be configurable through controlled application settings.

Examples include:

- maximum automatic retest attempts;
- automatic retest enable/disable;
- automatic bug creation;
- bug SLA threshold;
- central mode;
- multi-user import.

System settings should be controlled so users cannot arbitrarily change settings that are intended to be developer-defined.

---

# 65. Data Ownership

## FR-064 — Source Ownership

The system should distinguish:

- who created a record;
- who currently owns/handles it;
- who executed it;
- which machine produced it;
- which machine imported it;
- which user/system performed a state transition.

These concepts should not be collapsed merely because they happen to be the same user in many cases.

---

# 66. System-Generated Activities

## FR-065 — System User

System-generated actions such as:

- scheduled execution;
- automatic retest;
- automatic bug creation;
- automated synchronization;

should be distinguishable from direct user actions.

A system user such as `sys` may be used for attribution, but the original triggering user should also be preserved where meaningful.

---

# 67. Concurrency

## FR-066 — Concurrent Local Activity

The application shall safely support:

- multiple users;
- multiple runs;
- simultaneous test execution requests;
- background synchronization;
- scheduled execution;
- automatic retesting.

The design must prevent two processes from accidentally claiming the same logical execution identity.

---

# 68. Failure Recovery

## FR-067 — Interrupted Execution

If the application crashes or a machine shuts down during execution, the system should be able to identify the run as:

- interrupted;
- failed;
- abandoned;
- incomplete;

rather than leaving it permanently in a misleading `Running` state.

---

# 69. Execution Artifact Management

## FR-068 — Test Artifacts

The system may store references to:

- screenshots;
- HTML;
- console logs;
- raw command output;
- error traces;
- videos where applicable;
- other execution artifacts.

Large binary files should preferably remain in filesystem/object storage, while the database stores their metadata and paths.

---

# 70. Search & Filtering

## FR-069 — Test Data Search

The application should support filtering/search by:

- module;
- category;
- main menu;
- sub menu;
- screen;
- test case;
- user;
- machine;
- result;
- bug;
- severity;
- status;
- Git commit;
- date range;
- test type;
- technology;
- layer;
- flaky state.

---

# 71. Traceability

## FR-070 — End-to-End Traceability

The system should allow navigation through relationships such as:

```text
Requirement
   ↓
Test Case
   ↓
Test Case Version
   ↓
Test Run
   ↓
Test Result
   ↓
Bug
   ↓
Bug Fix
   ↓
Retest
   ↓
Final Result
```

This should become one of the most important capabilities of the application.

---

# 72. Requirement-to-Test Traceability

## FR-071

The system should answer:

> Which test cases verify this requirement?

and:

> Which requirements are currently not adequately covered by tests?

---

# 73. Bug-to-Test Traceability

## FR-072

The system should answer:

> Which tests detect this bug?

and:

> Which tests have historically failed because of this bug?

---

# 74. Enhancement Impact

## FR-073

When an enhancement is introduced, the application should help answer:

> Which screens and test cases are potentially affected?

and:

> Which regression tests should be executed?

This should use available relationships such as:

```text
Git Changes
Module
Screen
Test Case
Dependency
Requirement
Historical Bug
```

---

# 75. Test Quality Analytics

## FR-074

The system should eventually calculate quality indicators such as:

- pass rate;
- failure rate;
- flaky rate;
- failure recurrence;
- average execution duration;
- bug detection rate;
- bug reopen rate;
- time to fix;
- time to retest;
- regression frequency;
- test coverage;
- untested requirements;
- unstable environments.

---

# 76. Machine-Level Analytics

## FR-075

The central system should allow comparison by machine.

This should help determine:

- machine-specific failures;
- environment-specific failures;
- browser/version-specific failures;
- configuration-specific failures.

---

# 77. Developer-Level Analytics

## FR-076

The central system should allow meaningful developer-level analysis.

Examples:

- tests executed by developer;
- bugs raised;
- bugs fixed;
- bugs reopened;
- retest outcomes;
- areas owned/worked on.

Metrics should be interpreted carefully and should distinguish workload from quality rather than using simplistic productivity scoring.

---

# 78. Data Import Conflict Resolution

## FR-077

When importing data, the system should detect conflicts such as:

- same source test case identity but different definitions;
- same machine identity with inconsistent metadata;
- same requirement source identity with changed content;
- duplicate bug;
- conflicting catalog information.

The system should not silently overwrite valuable historical information.

---

# 79. Source vs Central Data

## FR-078

The system shall clearly distinguish:

```text
Source/Local Data
```

from:

```text
Central/Canonical Data
```

The central system may consolidate multiple source records without destroying their origin.

---

# 80. Reporting Principle

## FR-079

Reports must be based on actual historical execution records rather than only current test-case status.

For example:

A test currently marked `Passed` does not mean it never failed.

The system should be able to show:

```text
TC001

Jan 10 → Passed
Jan 11 → Passed
Jan 12 → Failed
Jan 12 → Passed
Jan 15 → Failed
Jan 16 → Passed
```

This historical sequence is essential for quality analysis.

---

# 81. Data Retention

## FR-080

The application should have a configurable retention strategy for:

- test results;
- raw logs;
- screenshots;
- audit logs;
- synchronization history;
- export/import history.

Retention should not destroy information required for long-term quality analysis.

---

# 82. Additional Requirements / Future Intelligence

## FR-081 — AI-Assisted Analysis

The application may eventually use AI to assist with:

- duplicate test-case detection;
- duplicate bug detection;
- failure classification;
- flaky-test identification;
- regression analysis;
- probable root-cause identification;
- impacted-test recommendation;
- test-case generation;
- requirement-to-test mapping;
- failure clustering.

AI-generated conclusions should remain distinguishable from actual recorded facts.

---

# 83. Important Identity Model

The following distinction is fundamental to the overall design:

```text
USER
  ↓
MACHINE
  ↓
SOURCE TEST CASE
  ↓
TEST RUN
  ↓
RUN ITEM
  ↓
RUN RESULT
```

Where source test-case identity is conceptually:

```text
Machine + User + Screen + Test Case Code
```

and execution identity is conceptually:

```text
Machine + Source Run ID
```

Central consolidation may create new central numeric IDs while retaining these source identities.

---

# 84. Expected Central Consolidation Example

Suppose:

### Machine M01

```text
User: Brijesh

TS001
  TC001
  TC002

Run #1
  TC001 → Passed
  TC002 → Failed
```

### Machine M02

```text
User: Tarun

TS001
  TC001
  TC002

Run #1
  TC001 → Failed
  TC002 → Passed
```

The central database must be able to retain both:

```text
M01 / Brijesh / TS001 / TC001
M02 / Tarun   / TS001 / TC001
```

without collision.

If later analysis determines that both TC001 records represent the same logical test, they may be mapped to a common canonical test case.

If they are different tests despite having the same code, they must remain distinct.

---

# 85. Core Design Principle

The application should follow this principle:

> **Never use a locally generated numeric ID as if it were globally unique after distributed consolidation.**

Instead:

```text
Local ID
+
Source Identity
```

must be retained whenever the record can originate independently on multiple machines.

---

# 86. Additional Suggestions From Architecture Review

The following are suggestions rather than confirmed requirements. Please review these carefully.

## AS-001 — Separate Source and Canonical Test Case Concepts

I strongly recommend treating these as separate concepts.

Potentially:

```text
Canonical Test Case
        ↑
        │
Source Test Case Mapping
        ↑
        │
Machine/User/Test Case Source
```

This will make future consolidation and duplicate-test detection considerably cleaner.

---

## AS-002 — Do Not Make Test Case Code the True Identity

`TC001` should be considered a **business/display code**, not the ultimate identity.

Its meaning depends on its source scope.

This will protect the system from future changes in numbering conventions.

---

## AS-003 — Avoid Propagating Composite Identity Everywhere

Although composite keys solve distributed collision problems, propagating:

```text
machine_id + user_code + ts_code + test_case_code
```

through every child table can make Laravel relationships and queries unnecessarily complicated.

A better architecture may be:

```text
Local/Source Identity
        ↓
Local Numeric ID
        ↓
Child Records
```

while retaining source identity at the appropriate boundary.

This is one of the most important areas to evaluate before finalizing the schema.

---

## AS-004 — Keep Numeric IDs for Internal Relationships

I recommend using numeric AUTO_INCREMENT IDs for internal database relationships wherever practical.

For example:

```text
run.id
   ↓
run_item.run_id
   ↓
result.run_item_id
```

rather than propagating UUIDs or large composite business keys through every level.

Source identity can be retained separately for synchronization/import.

---

## AS-005 — Consider a Dedicated Source/Origin Concept

Rather than repeating machine/user information everywhere, the architecture could potentially introduce a source/origin concept.

For example:

```text
Source
 ├── Machine
 ├── User
 └── Installation
```

Then imported records can consistently identify where they originated.

This could simplify future synchronization.

---

## AS-006 — Git Commit Should Become a First-Class Entity

Git commit information should not remain merely a JSON field.

A dedicated commit entity can support:

```text
Commit
  ↓
Changed Files
  ↓
Module
  ↓
Screen
  ↓
Test Cases
  ↓
Affected Test Selection
```

This would significantly improve regression and impact analysis.

---

## AS-007 — Separate Bug from Bug Occurrence

I strongly recommend this distinction.

```text
Bug
 ↓
Occurrences
 ↓
Test Results
```

rather than putting one `bug_id` directly on the test result.

One bug can appear in many results, and one test result may potentially expose more than one issue.

---

## AS-008 — Separate Current State From History

Tables such as:

```text
Bug
Test Case
Requirement
Screen
```

should contain the current state.

Separate history tables should preserve transitions/version changes.

This prevents the current state from destroying historical truth.

---

## AS-009 — Store Failure Fingerprints

For failed tests, generate a normalized failure signature from information such as:

- exception type;
- error message;
- relevant stack trace;
- assertion failure;
- affected test;
- application location.

This can later help identify:

```text
Same Failure
Different Failure
Known Bug
New Bug
Likely Environment Problem
```

---

## AS-010 — Test Execution Should Capture Code Version

A result without knowing the application version/commit is much less useful historically.

Ideally every run should answer:

> What exact application code was tested?

This is essential for reliable regression analysis.

---

## AS-011 — Test Case Version + Git Commit

Eventually, the system should be able to answer:

> Which version of the test definition executed against which version of the application?

This gives much stronger historical traceability than simply storing the latest test-case record.

---

## AS-012 — Do Not Overuse JSON

JSON is useful for:

- environment;
- flexible configuration;
- raw metadata;
- extensible attributes.

But important analytical relationships should remain relational.

For example, don't hide:

```text
test case
bug
requirement
module
screen
commit
user
machine
```

inside JSON.

---

## AS-013 — Derived Statistics Should Be Rebuildable

Summary tables are useful for performance, but the original execution records must remain the source of truth.

If a summary becomes corrupted, it should be possible to rebuild it from:

```text
Run
→ Run Item
→ Result
```

rather than treating the summary as authoritative.

---

## AS-014 — Import Must Be Idempotent

Import should be designed so that:

```text
Import Export A
Import Export A again
```

does not create duplicate executions.

This is especially important if users manually exchange export files.

---

## AS-015 — Export Should Have a Manifest

Every export bundle should ideally contain a manifest describing:

- export ID;
- machine;
- user;
- application version;
- schema version;
- export timestamp;
- data range;
- record counts;
- checksums;
- source database/application version.

This will make import validation considerably safer.

---

## AS-016 — Schema Version Must Be Part of Export

Because local machines may not all be upgraded simultaneously, exports should identify the schema/application version that produced them.

The central importer can then decide whether:

```text
Supported
Migration Required
Rejected
```

---

## AS-017 — Environment Fingerprint

For repeated failures, it would be useful to compare an environment fingerprint.

Example:

```text
OS
PHP
Browser
Driver
Laravel
Application Commit
Database Version
```

This could help distinguish:

```text
Application Regression
vs
Machine/Environment Problem
```

---

## AS-018 — Test Selection Engine

Eventually the application could have a test-selection engine:

```text
Developer changes code
        ↓
Git diff
        ↓
Changed files
        ↓
Affected modules/screens
        ↓
Related test cases
        ↓
Dependencies
        ↓
Historical failure risk
        ↓
Recommended test suite
```

This could become one of the most valuable features of the entire application.

---

## AS-019 — Confidence-Based AI Recommendations

AI recommendations should ideally contain a confidence/explanation layer.

For example:

```text
Recommended TC001

Reason:
- Changed file belongs to Screen TS001
- TC001 historically covers the changed functionality
- TC001 failed after similar changes twice
- TC001 is related to Bug #102
```

This is much more useful than simply saying:

```text
AI recommends TC001
```

---

## AS-020 — Preserve Evidence for Every Important Decision

For important analytical conclusions such as:

```text
Flaky
Regression
Duplicate Bug
Affected Test
Known Issue
```

the system should preserve the evidence/reasoning inputs.

That will make the application explainable and trustworthy.

---

# 87. Areas Requiring Your Confirmation

Before the final database architecture is designed, I recommend that you specifically review and confirm these areas:

1. **What exactly constitutes a Test Case?**
2. Whether two independently created identical test cases should remain separate or eventually map to one canonical test case.
3. Whether test-case numbering should remain per User + Screen, or per Machine + User + Screen.
4. Whether a user can modify another user's source test case locally.
5. What information is synchronized between machines.
6. What information belongs only to the central database.
7. Whether the central database is only an aggregation/reporting database or can also become the authoritative master.
8. Whether bugs are globally shared once imported.
9. Whether requirements are globally shared once imported.
10. Exact automatic-retest scope.
11. Exact definition of a flaky test.
12. Exact definition of a regression.
13. How Git changes should select impacted tests.
14. Whether test cases can be manually created without corresponding automated source-code tests.
15. Whether test cases can be cloned.
16. Whether test-case versions are required for every modification or only significant modifications.
17. Data-retention period.
18. Expected maximum number of test cases, runs and results.
19. Whether multiple test executions can run simultaneously on one machine.
20. Whether the central database can modify source-owned records or only create canonical mappings.

---

# 88. Final Architectural Objective

The final system should provide this overall lifecycle:

```text
                    PRIME-AI SOURCE CODE
                           │
                           ▼
                    DISCOVERY / SYNC
                           │
                           ▼
                  TEST CASE CATALOG
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
       TEST REQUIREMENTS          TEST SUITES
              │                         │
              └────────────┬────────────┘
                           ▼
                    TEST EXECUTION
                           │
                           ▼
                     TEST RESULTS
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
           BUGS         ANALYSIS       NOTES
             │             │
             ▼             ▼
       FIX / REOPEN     REGRESSION
             │          FLAKY TEST
             ▼          IMPACT ANALYSIS
        AUTO RETEST
             │
             ▼
       FINAL VERIFICATION


LOCAL MACHINE M01 ─┐
LOCAL MACHINE M02 ─┼──► EXPORT / IMPORT ──► CENTRAL DATABASE
LOCAL MACHINE M03 ─┘                            │
                                                ▼
                                      CONSOLIDATED ANALYSIS
                                                │
                         ┌──────────────────────┼────────────────────┐
                         ▼                      ▼                    ▼
                    Developer             Machine              Application
                    Analysis              Analysis              Quality
```

The most important architectural rule is:

> **Local data must remain independently identifiable after consolidation, while the central system must also be capable of recognizing when independently created records represent the same logical business/test entity.**

This is the key requirement that the earlier v8.0 schema did not handle correctly, particularly for Test Cases.

---

# Review Instructions

Please review this document as a **business/functional specification**, not as a database proposal.

Mark anything that is:

- **Wrong**
- **Missing**
- **Too much**
- **Not required**
- **Needs different behavior**
- **Needs clarification**

In particular, pay special attention to:

- Sections 6–8 — Identity
- Sections 42–47 — Bugs and Retesting
- Sections 53–57 — Export, Import and Consolidation
- Sections 82–86 — AI and Architecture Suggestions

Once the corrected/enhanced requirement is provided, it should be treated as the authoritative requirement specification for designing the database from the requirements upward rather than continuing to patch the existing DDL.
