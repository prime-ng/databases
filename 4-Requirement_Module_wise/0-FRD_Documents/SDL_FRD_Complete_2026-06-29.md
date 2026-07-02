# SDL — Scheduler Module | Complete Analysis Pack
**Date:** 2026-06-29 | **Version:** 1.0
**Module:** Scheduler | **Code:** SDL | **DB Layer:** prime_db (central)
**Sources read:** V2 req (`SCH_JOB_Scheduler_Requirement.md`), V1 req (Dev_Done), Gap Analysis (2026-03-22),
live code (`Modules/Scheduler/`), migrations (`2026_01_02_*`), module-knowledge (seeded this session)
**Module knowledge:** `AI_Brain/module-knowledge/SDL_Scheduler.md`

---

## Table of Contents

- [Section A — FRD (10 sections)](#section-a--frd)
  - [1. Module Overview](#1-module-overview)
  - [2. User Roles and Access](#2-user-roles-and-access)
  - [3. Functional Requirements](#3-functional-requirements)
  - [4. Business Rules Register](#4-business-rules-register)
  - [5. Data Requirements](#5-data-requirements)
  - [6. Workflows](#6-workflows)
  - [7. Reporting and Analytics](#7-reporting-and-analytics)
  - [8. Future Enhancements](#8-future-enhancements)
  - [9. Non-Functional Requirements](#9-non-functional-requirements)
  - [10. Gap Analysis Readiness Index](#10-gap-analysis-readiness-index)
- [Section B — Requirements Traceability Matrix (RTM)](#section-b--requirements-traceability-matrix-rtm)
- [Section C — Business Rules Register + Conditions + Validation Catalog](#section-c--business-rules-register--conditions--validation-catalog)
- [Section D — Process Flows + FSM Catalog](#section-d--process-flows--fsm-catalog)
- [Section E — Data Dictionary + Cross-Module Dependency Map](#section-e--data-dictionary--cross-module-dependency-map)
- [Section F — NFR Catalog + Risk Register](#section-f--nfr-catalog--risk-register)
- [Section G — Prioritization + Effort Estimation](#section-g--prioritization--effort-estimation)
- [Section H — User Stories + Reporting Spec](#section-h--user-stories--reporting-spec)

---

# SECTION A — FRD

---

## 1. Module Overview

### 1.1 Purpose

The Scheduler module is Prime-AI's central platform tool for registering, configuring, and monitoring
background job schedules. It allows Platform Administrators to define recurring automated tasks — such as
billing report generation, fee-reminder dispatch, attendance SMS delivery, and academic data archival — and
to track whether those tasks are running successfully.

Without this module, managing background tasks requires direct server access and manual editing of system
cron files. This module replaces that with a web interface backed by the platform's built-in scheduling
infrastructure.

**DB Layer Note:** The Scheduler is a central-only (Platform) module. It is accessed exclusively from the
Platform Admin dashboard and stores its data in the central platform database. No school-side interface
exists. School-specific tasks can be targeted at individual schools by selecting "School-Level" scope and
specifying which school the task runs for.

### 1.2 Business Value

| Benefit | Description |
|---|---|
| Operational efficiency | Platform operators can schedule and monitor background tasks from a browser — no SSH or cron file editing required |
| Visibility | Every execution attempt is recorded with status, duration, and error details — enabling proactive failure detection |
| Safety | Tasks run outside HTTP request cycles, preventing timeouts and degraded user experience during heavy processing |
| Scalability | A registry-based catalog means new job types can be added without changing the scheduling infrastructure |

### 1.3 Scope

**In Scope:**
- Catalog of all schedulable task types registered on the platform
- Create, edit, archive, and restore schedule configurations with cron-based timing patterns
- Enable and disable individual schedules without deleting them
- Automatic execution of due schedules once per minute (platform scheduler)
- On-demand manual trigger for any schedule by an authorized administrator
- Execution history — every run attempt recorded with status, duration, and error output
- Permission-gated access: only Platform Administrators may manage schedules

**Out of Scope (current phase):**
- Real-time server health metrics (CPU, memory, disk usage)
- Alert configuration and notification routing when a job fails (future: ENH-SDL-002)
- Queue monitoring dashboard (Laravel Horizon or failed-job inspection)
- School-side self-service schedule management (schools enabling their own recurring tasks)
- Automatic discovery of new job types from the filesystem
- Schedule dependency chains (Job A must complete before Job B starts)
- REST API endpoints for programmatic schedule management

### 1.4 Terminology

| Business Term | Meaning |
|---|---|
| **Job Schedule** | A named configuration that defines which task to run, when to run it (timing pattern), and in what context (platform-level or school-level) |
| **Timing Pattern** | A standard cron expression (e.g., `0 9 * * 1` = every Monday at 9 AM) that determines when a schedule is due |
| **Execution Record** | A single log entry capturing one run attempt of a Job Schedule: its start time, finish time, duration, and outcome (Success / Failed / Running) |
| **Job Catalog** | The platform's registry of all task types that can be scheduled — maintained by developers; each entry has a key, a human label, and the scope it runs in |
| **Platform-Level Task** | A task that runs in the central platform context (no school isolation required) — examples: billing report generation, platform data archival |
| **School-Level Task** | A task that runs within a specific school's isolated data context — examples: fee reminder SMS, attendance notifications, recommendation expiry |
| **Job Payload** | Optional JSON configuration parameters passed to a task at runtime (e.g., a date range, report type, or filter setting) |
| **Active / Paused** | The enabled/disabled state of a Job Schedule; Paused schedules are not executed but their configuration is preserved |
| **Run Status** | The outcome of one Execution Record: Running (in progress), Success, or Failed |

---

## 2. User Roles and Access

### 2.1 Actors

| Actor | Description | Scope |
|---|---|---|
| **Super Admin** | Full platform operator with all permissions on all platform functions | Platform |
| **Prime Admin** | Day-to-day platform administrator; manages schedules, monitors runs, triggers manual executions | Platform |
| **Support Staff** | Read-only view of schedules and run history for incident investigation | Platform |
| **Platform System (Scheduler)** | The platform's built-in scheduling engine that executes due schedules automatically once per minute | System |
| **Module Developer** | Registers new task types in the Job Catalog during development — not an end-user role | Developer |
| **School Admin (Tenant)** | Indirectly affected by school-level tasks but has NO access to the Scheduler module at all | Tenant (excluded) |

### 2.2 Role-Feature Matrix

| Feature | Super Admin | Prime Admin | Support Staff | School Admin |
|---|---|---|---|---|
| View schedule list | Yes | Yes | Yes (read-only) | No |
| View schedule detail | Yes | Yes | Yes (read-only) | No |
| Create Job Schedule | Yes | Yes | No | No |
| Edit Job Schedule | Yes | Yes | No | No |
| Archive (soft-delete) Schedule | Yes | Yes | No | No |
| Restore archived schedule | Yes | Yes | No | No |
| Permanently delete schedule | Yes | No | No | No |
| Enable / Pause schedule | Yes | Yes | No | No |
| Manually trigger a schedule | Yes | Yes | No | No |
| View run history | Yes | Yes | Yes (read-only) | No |
| View archived schedules | Yes | Yes | No | No |

---

## 3. Functional Requirements

### REQ-SDL-001 — Schedule Management Dashboard
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY][DASHBOARD]
**Status (code):** Partial — index view renders but has no pagination, no auth, no search/filter

**Description:**
A Platform Administrator can view all Job Schedules in a paginated list showing each schedule's name,
job type, timing pattern, scope (platform-level or school-level), active/paused status, last execution
time, and failure count. The list supports search by name or job type, and filter by active/paused status.
Archived (soft-deleted) schedules are hidden from this view but accessible via the Archived Schedules view.

**Actors:** Initiates — Prime Admin / Super Admin | Processes — System | Views — Support Staff

**Business Rules:** BR-SDL-001, BR-SDL-002, BR-SDL-016

**Acceptance Criteria:**
- [ ] An authenticated Platform Admin opening the schedule list sees all non-archived Job Schedules ordered by creation date (newest first)
- [ ] The list is paginated (15 items per page) and shows pagination controls
- [ ] Typing in the search box filters results by schedule name or job type without a page reload (or with a controlled reload)
- [ ] Selecting "Active" or "Paused" from the filter dropdown limits the list to schedules of that status
- [ ] An authenticated School Admin (tenant user) who attempts to access the schedule list receives an Access Denied response
- [ ] An unauthenticated user who attempts to access the schedule list is redirected to the login page
- [ ] The failure count column is visible and reflects the number of failed runs for each schedule

**Integration:** Reads Job Schedule data from the central platform database. No cross-module reads required.

**Enhancement Notes:** ENH-SDL-003 (real-time status refresh via AJAX)

---

### REQ-SDL-002 — Create Job Schedule
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY][CONFIGURATION]
**Status (code):** Partial — form and create work but: double validation bug, no auth, hardcoded platform-level scope, no job-type registry validation, no cron validation

**Description:**
A Platform Administrator can create a new Job Schedule by selecting a task type from the Job Catalog
dropdown, entering a display name, specifying a timing pattern (cron expression), optionally providing
a JSON payload, choosing the scope (platform-level or school-level), selecting the target school if
school-level scope is chosen, and setting the initial active/paused state. On save, the system computes
and stores the next scheduled run time and logs the creation to the activity trail.

**Actors:** Initiates — Prime Admin / Super Admin | Processes — System | Views — Prime Admin / Super Admin

**Business Rules:** BR-SDL-003, BR-SDL-004, BR-SDL-005, BR-SDL-006, BR-SDL-007, BR-SDL-008, BR-SDL-017

**Acceptance Criteria:**
- [ ] The create form shows a dropdown listing all task types from the Job Catalog with their human-readable labels
- [ ] Selecting a task type that only supports platform-level scope hides the school selector and locks scope to Platform-Level
- [ ] Selecting a task type that only supports school-level scope shows the school selector and locks scope to School-Level
- [ ] Submitting the form with a valid name, valid cron expression, and valid (or empty) payload creates a Job Schedule and redirects to the list with a success message
- [ ] Submitting with an unrecognised task type (not in the Job Catalog) is rejected with a validation error
- [ ] Submitting with an invalid cron expression (e.g., `99 99 * * *`) is rejected with a validation error identifying the field
- [ ] Submitting with a malformed JSON payload is rejected with a validation error
- [ ] Submitting with School-Level scope and no school selected is rejected with a validation error
- [ ] The creation is recorded in the activity trail with the acting user's name, timestamp, and schedule details
- [ ] A user without Create Schedule permission receives an Access Denied response

**Integration:** Reads Job Catalog (internal). Creates Job Schedule record. No cross-module API calls at create time.

**Enhancement Notes:** ENH-SDL-006 (visual cron expression builder)

---

### REQ-SDL-003 — Edit Job Schedule
**Priority:** Core (P0) | **Tags:** [DATA_ENTRY][CONFIGURATION]
**Status (code):** Not Started — `edit()` returns generic view with no data; `update()` is completely empty

**Description:**
A Platform Administrator can edit an existing Job Schedule to change its display name, timing pattern,
payload, scope, target school, or active/paused state. The same validation rules that apply at creation
apply at edit. Changing the timing pattern causes the system to recompute the next scheduled run time.
The edit is recorded in the activity trail.

**Actors:** Initiates — Prime Admin / Super Admin | Processes — System | Views — Prime Admin / Super Admin

**Business Rules:** BR-SDL-003, BR-SDL-004, BR-SDL-005, BR-SDL-006, BR-SDL-007, BR-SDL-008, BR-SDL-009

**Acceptance Criteria:**
- [ ] The edit form pre-populates all current field values for the selected Job Schedule
- [ ] Updating only the timing pattern leaves all other fields unchanged
- [ ] Changing the timing pattern causes the Next Run Time to be recomputed from the new expression
- [ ] All creation-time validation rules apply equally to the edit form (invalid cron, invalid JSON, etc.)
- [ ] A successfully submitted edit redirects to the schedule list (or detail view) with a success message
- [ ] The edit is recorded in the activity trail identifying which fields changed
- [ ] A user without Edit Schedule permission receives an Access Denied response

**Integration:** Reads and updates Job Schedule record. No cross-module calls.

---

### REQ-SDL-004 — Archive and Restore Schedule
**Priority:** Standard (P1) | **Tags:** [WORKFLOW][CONFIGURATION]
**Status (code):** Not Started — `destroy()` is empty; no `SoftDeletes` on `Schedule` model; no `restore()` method; `trash.blade.php` has wrong content

**Description:**
A Platform Administrator can archive a Job Schedule (soft-delete), which immediately pauses execution
of that schedule and moves it out of the active list. An archived schedule can be viewed in the Archived
Schedules view and can be restored (un-archived) to make it active again. A Super Admin can permanently
delete an archived schedule. Permanent deletion is irreversible and also permanently deletes all
associated Execution Records.

**Actors:** Initiates — Prime Admin / Super Admin | Processes — System | Views — Prime Admin / Super Admin

**Business Rules:** BR-SDL-010, BR-SDL-011, BR-SDL-012

**Acceptance Criteria:**
- [ ] Archiving a Job Schedule immediately prevents it from being executed on its next due time
- [ ] An archived schedule disappears from the main schedule list but appears in the Archived Schedules view
- [ ] The Archived Schedules view shows the schedule name, job type, and the date it was archived
- [ ] A Prime Admin can restore an archived schedule; the restored schedule resumes its previous active/paused state
- [ ] A Super Admin can permanently delete an archived schedule from the Archived Schedules view; a confirmation prompt is shown before deletion
- [ ] Permanently deleting a schedule removes both the schedule record and all associated Execution Records
- [ ] A user without Archive/Restore Schedule permission receives an Access Denied response
- [ ] Attempting to archive a schedule that is already archived returns an appropriate error

**Integration:** No cross-module calls. System impact: scheduled execution ceases for archived schedule.

---

### REQ-SDL-005 — Enable and Pause Schedule
**Priority:** Standard (P1) | **Tags:** [WORKFLOW][CONFIGURATION]
**Status (code):** Not Started — index view has Enable/Disable button but no route, no controller method

**Description:**
A Platform Administrator can toggle a Job Schedule between Active (enabled) and Paused (disabled) states
without modifying any other configuration. This is a lightweight operation intended for quickly pausing
a schedule without archiving it (for example, during a maintenance window). The change takes effect
immediately — a paused schedule will not be picked up on the next execution cycle.

**Actors:** Initiates — Prime Admin / Super Admin | Processes — System | Views — Prime Admin / Super Admin

**Business Rules:** BR-SDL-013

**Acceptance Criteria:**
- [ ] An Active schedule can be Paused by clicking the Pause button on the schedule list; the status badge updates immediately
- [ ] A Paused schedule can be Activated by clicking the Activate button; it will be eligible for execution on the next due cycle
- [ ] The toggle responds without a full page reload (AJAX or equivalent lightweight mechanism)
- [ ] Toggling does not change the timing pattern, payload, or any other schedule attribute
- [ ] The toggle action is recorded in the activity trail
- [ ] A user without Edit Schedule permission receives an Access Denied response

**Integration:** Updates `is_active` flag on the Job Schedule record only.

---

### REQ-SDL-006 — Manual Schedule Trigger
**Priority:** Standard (P1) | **Tags:** [WORKFLOW]
**Status (code):** Not Started — no `run()` method, no route

**Description:**
A Platform Administrator can manually trigger a Job Schedule to execute immediately, outside its normal
timing pattern. This bypasses the cron-due check and dispatches the associated job to the queue right
away. The system creates an Execution Record for this manual run (the same as for an automatic run),
so the run is visible in the schedule's history. The schedule's Last Run Time is updated.

**Actors:** Initiates — Prime Admin / Super Admin | Processes — System | Views — Prime Admin / Super Admin

**Business Rules:** BR-SDL-014, BR-SDL-015

**Acceptance Criteria:**
- [ ] Clicking the "Run Now" button on the schedule list or detail view triggers immediate dispatch of the job
- [ ] The system creates an Execution Record for the manual run, visible in Run History
- [ ] If the task type cannot be found in the Job Catalog (registry mismatch), the system creates a Failed Execution Record with a descriptive error message instead of silently failing
- [ ] If the schedule is School-Level, the task runs in the context of the specified school
- [ ] The manual trigger is recorded in the activity trail with the acting user's name
- [ ] A user without the "Manually Trigger Schedule" permission receives an Access Denied response

**Integration:** Dispatches the registered job to the platform queue. For school-level tasks, initializes the target school's data context before dispatching.

---

### REQ-SDL-007 — Run History
**Priority:** Standard (P1) | **Tags:** [REPORT][DASHBOARD]
**Status (code):** Not Started — `ScheduleRun` model exists but is never written to; no `runs.blade.php` view; "Runs" button on index has empty `href`

**Description:**
A Platform Administrator can view the complete execution history for any Job Schedule. The history shows
each run attempt with its outcome (Success / Failed / Running), start time, finish time, duration, and
error details on failure. Aggregate statistics (total runs, success count, failure count, average duration)
are shown at the top. The list is paginated and ordered by most recent first. Error details are expandable
for full visibility.

**Actors:** Initiates — Prime Admin / Super Admin / Support Staff | Views — same

**Business Rules:** BR-SDL-018, BR-SDL-019

**Acceptance Criteria:**
- [ ] Clicking "View History" for a schedule opens the Run History view for that schedule
- [ ] The history shows: run status (badge), start time, finish time, duration (human-readable, e.g. "1.2 s"), target school (if school-level), error message (on failure), attempt number
- [ ] The aggregate panel at the top shows: total runs, successful runs, failed runs, average duration
- [ ] Failed runs show an expandable error detail section containing the full error message and (when stored) execution output
- [ ] The list is paginated (15 items per page), ordered by start time descending
- [ ] A Support Staff user can view run history but cannot trigger, edit, or archive schedules from the same view
- [ ] A user without View Schedule permission receives an Access Denied response

**Integration:** Reads Execution Records. No cross-module reads required.

**Enhancement Notes:** ENH-SDL-004 (run history retention policy), ENH-SDL-005 (cross-schedule run dashboard)

---

### REQ-SDL-008 — Automatic Schedule Execution Engine
**Priority:** Core (P0) | **Tags:** [SCHEDULED][WORKFLOW]
**Status (code):** Not Started — `SchedulerService::dueSchedules()` exists but `runSchedule()` is missing; no Artisan command registered; `ScheduleRun` is never written to

**Description:**
The platform automatically checks all Active Job Schedules once per minute and dispatches the associated
jobs for any schedule whose timing pattern indicates it is currently due. Each dispatch creates an
Execution Record. If the job is a School-Level task, the system initializes the correct school data
context before dispatching. Failures are isolated per schedule — one schedule failing must not prevent
other due schedules from running. After each run, the schedule's Last Run Time and Next Run Time are
updated. Failure counts are incremented on failure.

This is the core functional capability of the module. Without it, the module stores schedule configurations
but never executes them.

**Actors:** Initiates — Platform System (automated) | Processes — System

**Business Rules:** BR-SDL-020, BR-SDL-021, BR-SDL-022, BR-SDL-023, BR-SDL-024

**Acceptance Criteria:**
- [ ] The platform's task scheduler runs the schedule-check process every minute automatically
- [ ] All Active Job Schedules whose timing pattern is due at the current minute are dispatched to the background queue
- [ ] For each dispatched schedule, an Execution Record is created with status "Running" and the start time
- [ ] When the job completes successfully, the Execution Record is updated to "Success" with finish time and duration
- [ ] When the job fails, the Execution Record is updated to "Failed" with the error message; the schedule's failure count increments
- [ ] A School-Level task is dispatched within the target school's data context (isolated from other schools' data)
- [ ] If the task type for a schedule is no longer in the Job Catalog, the system creates a "Failed" Execution Record with a "Job class not found" error — it does not throw an unhandled exception
- [ ] A failure in dispatching one schedule does not prevent the system from processing other due schedules in the same minute
- [ ] Invalid timing patterns are skipped safely with an error logged — the system does not crash
- [ ] The schedule-check process uses an overlap-prevention mechanism so that if the previous minute's check is still running, the new one does not start
- [ ] Last Run Time and Next Run Time on the Job Schedule are updated after each execution attempt

**Integration:** Reads Job Schedule records. Dispatches registered job classes to the platform queue. For school-level tasks, reads tenant records to initialize school context.

---

### REQ-SDL-009 — Job Catalog Management (Developer-Administered)
**Priority:** Enhanced (P2) | **Tags:** [CONFIGURATION]
**Status (code):** Partial — `JobRegistry` with 3 entries exists; no UI for catalog management (developer-only)

**Description:**
The Job Catalog is the authoritative list of task types that can be scheduled. Each entry has a unique
key, a human-readable label, and the set of scopes it supports (platform-level, school-level, or both).
The catalog is maintained by platform developers by adding new entries to the job registry. All job
classes must implement the Schedulable Job Agreement (interface contract). Platform Administrators can
view the catalog but cannot edit it through the UI — additions require a developer code change and
deployment.

The target catalog should include at least 10 task types covering billing, notifications, LMS, analytics,
and maintenance workloads. Currently 3 entries are registered.

**Actors:** Views — Prime Admin / Super Admin | Manages — Module Developer (code change)

**Business Rules:** BR-SDL-002

**Acceptance Criteria:**
- [ ] The Create Schedule form's job type dropdown reflects all task types currently in the Job Catalog
- [ ] A task type that is no longer in the catalog cannot be selected on the create form
- [ ] If an existing schedule's task type is removed from the catalog, running that schedule produces a Failed Execution Record with a descriptive error (not a crash)
- [ ] Each catalog entry exposes its human-readable label and supported scopes (platform-level / school-level / both)

**Integration:** No runtime cross-module calls. Catalog is populated at development time.

---

## 4. Business Rules Register

| BR-ID | Rule | Type | Trigger | Enforcement Point |
|---|---|---|---|---|
| BR-SDL-001 | Only users with the "View Schedules" permission may access the schedule list, detail, or run history screens | Permission | Any access to scheduler routes | Permission gate on every controller method |
| BR-SDL-002 | A Job Schedule's task type must match a key in the platform Job Catalog; unrecognised task types are rejected | Validation | Create and Edit form submission | Schedule Form validation |
| BR-SDL-003 | The timing pattern must be a syntactically valid cron expression (5 or 6 fields, valid ranges per field) | Validation | Create and Edit form submission | Custom cron validation rule |
| BR-SDL-004 | The optional JSON Payload, when provided, must be valid JSON and must not exceed 10,000 characters | Validation | Create and Edit form submission | Custom JSON validation rule |
| BR-SDL-005 | When scope is School-Level, a target school must be specified; no school identifier means validation fails | Validation | Create and Edit form submission | Form validation: required-if rule |
| BR-SDL-006 | A task type that only supports platform-level scope cannot be assigned to a School-Level schedule, and vice versa | Validation | Create and Edit form submission | Form validation cross-check against Job Catalog entry |
| BR-SDL-007 | Schedule display names must be unique within the platform (no two schedules may have the same name) | Validation | Create and Edit form submission | Database unique constraint check |
| BR-SDL-008 | On successful save (create or edit), the system computes and stores the Next Run Time from the timing pattern | Calculation | After save | Service layer: cron expression → next due datetime |
| BR-SDL-009 | Editing an active schedule does not interrupt any currently-running execution of that schedule | Concurrency | Edit save | Edit does not cancel in-flight jobs |
| BR-SDL-010 | Archiving a Job Schedule immediately pauses it — the schedule will not be picked up at the next execution cycle | Workflow | Archive action | Soft-delete sets `deleted_at`; execution engine skips non-null `deleted_at` records |
| BR-SDL-011 | Only a Super Admin may permanently delete an archived schedule; Prime Admin can only soft-delete (archive) | Permission | Permanent delete action | Policy: `forceDelete` permission check |
| BR-SDL-012 | Permanently deleting a Job Schedule also permanently deletes all its Execution Records (cascading delete) | Workflow | Permanent delete confirm | Hard delete logic in service layer |
| BR-SDL-013 | Toggling Active/Paused does not change the timing pattern, payload, or any other schedule attribute — only the enabled state changes | Workflow | Toggle action | Controller toggle method: only flips `is_active` |
| BR-SDL-014 | A manual trigger creates an Execution Record identical to an automatic trigger — distinguishable only by context in the activity trail | Workflow | Manual trigger action | Service layer: same `runSchedule()` path |
| BR-SDL-015 | A manual trigger dispatches the job even if the schedule is currently Paused (the Paused state only prevents automatic dispatch) | Workflow | Manual trigger action | Execution engine: bypass `is_active` check for manual triggers |
| BR-SDL-016 | Archived schedules are excluded from the main schedule list and must not appear in the execution engine's due-schedule query | Workflow | Index query; due-schedule query | Query scope filters `deleted_at IS NULL` |
| BR-SDL-017 | All CRUD operations (create, edit, archive, restore, permanent delete, toggle, manual trigger) must be recorded in the platform activity trail with acting user, timestamp, and affected schedule name | Workflow | After any write operation | Activity log call in controller/service |
| BR-SDL-018 | Execution Records are ordered by start time descending (most recent first) in the Run History view | Validation | Run History query | Query `ORDER BY started_at DESC` |
| BR-SDL-019 | Run History is paginated at 15 records per page | Validation | Run History view | Paginate query |
| BR-SDL-020 | The execution engine runs every minute; each minute, only Active (non-archived, non-paused) schedules are candidates for execution | Workflow | Artisan command, every minute | Schedule engine: query filter `is_active=true AND deleted_at IS NULL` |
| BR-SDL-021 | A schedule is dispatched only if its timing pattern indicates it is due at the current minute (standard cron semantics) | Calculation | Each execution cycle | `CronExpression::isDue()` check |
| BR-SDL-022 | A failure in dispatching one schedule in a cycle must not prevent processing of subsequent due schedules | Reliability | Each execution cycle | Per-schedule try/catch in command loop |
| BR-SDL-023 | For a School-Level task, the system must initialize the target school's data context before dispatching the job; the job must run in isolation from other schools' data | Workflow / Security | Execution engine dispatch | Tenancy initialization before job dispatch |
| BR-SDL-024 | The execution engine must use overlap prevention — if the previous minute's execution cycle has not finished, the new cycle must not start | Concurrency | Artisan command registration | `withoutOverlapping()` on the scheduled command |

---

## 5. Data Requirements

### 5.1 Job Schedule

| Business Field | Meaning | Privacy | Required |
|---|---|---|---|
| Schedule Name | Human-readable label uniquely identifying this schedule | Internal | Yes |
| Scope | Whether this schedule runs at platform level or within a specific school's data context | Internal | Yes |
| Target School | The specific school this schedule runs for (only when scope is School-Level) | Internal | Conditional |
| Job Type | Key identifying the task class to run from the Job Catalog | Internal | Yes |
| Timing Pattern | Cron expression defining when the schedule runs (e.g., "every Monday at 9 AM") | Internal | Yes |
| Job Payload | Optional JSON configuration parameters passed to the task at runtime | Internal | No |
| Active | Whether this schedule will be automatically executed when due | Internal | Yes (default: Active) |
| Last Run Time | When this schedule last executed (success or failure) | Internal | No (system-set) |
| Next Run Time | Computed next execution time based on the timing pattern | Internal | No (system-set) |
| Failure Count | Cumulative count of failed execution attempts | Internal | No (system-set) |
| Created By | The platform user who created this schedule | Internal | No (system-set) |
| Created At / Updated At | Standard timestamps | Internal | No (system-set) |
| Archived At | When the schedule was archived; null means active (not archived) | Internal | No (system-set) |

### 5.2 Execution Record

| Business Field | Meaning | Privacy | Required |
|---|---|---|---|
| Job Schedule | Link to the schedule this record belongs to | Internal | Yes |
| Target School | The school this run executed for (if school-level scope) | Internal | Conditional |
| Run Status | Outcome: Running / Success / Failed | Internal | Yes |
| Start Time | When the execution attempt began | Internal | Yes |
| Finish Time | When the execution attempt ended (null while still running) | Internal | Conditional |
| Duration | How long the execution took in milliseconds | Internal | Conditional |
| Error Message | Error description when Run Status is Failed | Internal | Conditional |
| Execution Output | Full stdout/output captured from the job (for debugging) | Internal | No |
| Attempt Number | Which retry attempt this is (1 = first try) | Internal | Yes (default: 1) |

### 5.3 Job Catalog Entry (in-code, not a database table)

| Business Field | Meaning |
|---|---|
| Job Key | Unique string identifier used in Job Schedule configurations |
| Label | Human-readable name displayed in the schedule create form dropdown |
| Supported Scopes | Which scope(s) this job type is valid for (platform-level, school-level, or both) |

---

## 6. Workflows

### Workflow 1: Automatic Schedule Execution (Core Engine)

**Trigger:** Platform clock reaches a new minute
**End States:** All due schedules dispatched (success or failed) | No due schedules found (idle)
**Actors:** Platform System

**Steps:**
1. [System] Retrieve all Active, non-archived Job Schedules
2. [System] For each schedule: evaluate timing pattern against current time
3. [System] Decision: is the schedule due this minute?
   - No → skip; move to next schedule
   - Yes → proceed to step 4
4. [System] Look up the task class for this schedule's Job Type in the Job Catalog
5. [System] Decision: is the task class found and valid?
   - No → create Failed Execution Record ("Job class not found"); increment failure count; move to next schedule
   - Yes → proceed to step 6
6. [System] Create Execution Record with status "Running" and start time
7. [System] Decision: is scope School-Level?
   - Yes → initialize target school's data context
   - No → dispatch in platform context
8. [System] Dispatch job to the background queue
9. [System] Update schedule: set Last Run Time to now; compute and store Next Run Time
10. [System] Decision: job dispatch succeeded?
    - Success → update Execution Record to status "Success", finish time, duration
    - Failed → update Execution Record to status "Failed", error message, duration; increment failure count
11. [System] Continue to the next due schedule (step 3 — overlap protection ensures no two cycles run simultaneously)

**Exception Paths:**
- Invalid timing pattern: log error, skip schedule, do not create Execution Record (cron expression itself is malformed)
- Tenancy initialization failure (school not found): create Failed Execution Record with "School context initialization failed"; continue to next schedule

**Notifications Triggered:** None in current phase (ENH-SDL-002 plans failure alerting)

---

### Workflow 2: Manual Schedule Trigger

**Trigger:** Platform Admin clicks "Run Now" on a Job Schedule
**End States:** Job dispatched; Execution Record created | Access denied | Job class not found
**Actors:** Prime Admin / Super Admin | Platform System

**Steps:**
1. [Prime Admin] Clicks "Run Now" on the schedule list or detail view
2. [System] Verify the user has "Manually Trigger Schedule" permission → deny if not
3. [System] Look up the task class for this schedule's Job Type in the Job Catalog
4. [System] Decision: task class found?
   - No → show error: "This schedule's job type is no longer registered. Cannot trigger."
   - Yes → proceed
5. [System] Create Execution Record with status "Running" and start time
6. [System] If School-Level: initialize target school's data context
7. [System] Dispatch job to queue
8. [System] Update Last Run Time on the schedule
9. [System] Record action in activity trail (manual trigger by User X at time Y)
10. [System] Show success message: "Schedule dispatched. Check Run History for status."

**Exception Paths:**
- Dispatch fails: create Failed Execution Record; show error message to admin with error detail

---

### Workflow 3: Create Job Schedule

**Trigger:** Platform Admin submits the Create Schedule form
**End States:** Schedule created and Active | Validation error returned
**Actors:** Prime Admin / Super Admin | Platform System

**Steps:**
1. [Prime Admin] Opens Create Schedule form; selects job type from catalog dropdown
2. [System] Filters scope selector based on the selected job type's supported scopes
3. [Prime Admin] Enters display name, timing pattern, optional payload; selects scope; selects target school if school-level
4. [System] Validate all fields (timing pattern syntax, payload JSON, job type in catalog, school required if school-level, name uniqueness)
5. [System] Decision: valid?
   - No → return form with field-level error messages
   - Yes → proceed
6. [System] Compute Next Run Time from timing pattern
7. [System] Create Job Schedule record with Active state
8. [System] Record creation in activity trail
9. [System] Redirect to schedule list with success message

**Exception Paths:** Validation errors returned to form (covered by BR-SDL-002 through BR-SDL-006)

---

## 7. Reporting and Analytics

### RPT-SDL-001 — Run History Report (Per Schedule)
**Purpose:** Show the complete execution history for one schedule
**Audience:** Prime Admin, Super Admin, Support Staff
**Frequency:** On demand (from schedule detail view)
**Contents:** Execution Records for the selected schedule — run status, start/finish times, duration, school (if applicable), error message, attempt number; aggregate header (total / success / failed / average duration)
**Filters:** Date range (optional); status filter (all / success / failed / running)
**Export:** None (display only in current phase; ENH-SDL-005 proposes exportable cross-schedule report)

### RPT-SDL-002 — Schedule Health Summary (Dashboard Widget)
**Purpose:** Surface failing or never-run schedules to platform operators
**Audience:** Prime Admin, Super Admin
**Frequency:** Shown on the Schedule List view
**Contents:** Per-schedule: last run status badge, failure count column, Last Run Time, Next Run Time
**Filters:** Status filter on list view (Active / Paused)
**Export:** None

### RPT-SDL-003 — Archived Schedules View
**Purpose:** Show soft-deleted schedules for recovery or permanent deletion
**Audience:** Prime Admin, Super Admin
**Frequency:** On demand (Archived Schedules view)
**Contents:** Schedule name, job type, timing pattern, archived date
**Filters:** None in current phase
**Export:** None

---

## 8. Future Enhancements

| ENH-ID | Title | Rationale |
|---|---|---|
| ENH-SDL-001 | Queue Monitoring Dashboard | Inspect failed and pending queue entries (Laravel Horizon wrapper) — RBS SYS1.1.1.2 |
| ENH-SDL-002 | Job Failure Alerting | Email or in-app notification to designated admins when a schedule exceeds a failure threshold — RBS SYS1.1.2 |
| ENH-SDL-003 | Real-Time Status Refresh | Auto-refresh the schedule list status badges without a full page reload |
| ENH-SDL-004 | Run History Retention Policy | Configurable window (e.g., keep 90 days) with an automated cleanup task — prevents unbounded table growth |
| ENH-SDL-005 | Cross-Schedule Run Report | Exportable (CSV/PDF) summary of all runs across all schedules — useful for platform health audits |
| ENH-SDL-006 | Visual Cron Expression Builder | UI component (like crontab.guru) for non-technical admins to build timing patterns without cron syntax knowledge |
| ENH-SDL-007 | Schedule Dependency Chains | Allow defining that Job B must run after Job A completes — for sequentially dependent tasks (e.g., archival before billing) |

---

## 9. Non-Functional Requirements

### 9.1 Performance

| NFR-SDL-001 | The schedule list must render with paginated results (15/page) — no full-table load |
| NFR-SDL-002 | The execution cycle (check due schedules + dispatch) must complete in under 10 seconds for up to 100 active schedules |
| NFR-SDL-003 | Run History queries must be indexed by start time and schedule ID for sub-second response |

### 9.2 Security

| NFR-SDL-004 | Every controller method must call `Gate::authorize()` with the appropriate permission before executing any business logic |
| NFR-SDL-005 | `SchedulePolicy` must enforce that tenant-side users (School Admin and below) can never reach any scheduler route |
| NFR-SDL-006 | The job type field must be validated against the Job Catalog registry — arbitrary class names must not be accepted |
| NFR-SDL-007 | JSON payload input must be validated as valid JSON and capped at 10,000 characters to prevent oversized storage |
| NFR-SDL-008 | Cron expression input must be validated against cron syntax rules — invalid expressions must be rejected at save time |
| NFR-SDL-009 | All CRUD and trigger operations must be recorded in the platform activity trail |
| NFR-SDL-010 | School-level task dispatch must use the platform's tenancy isolation mechanism — a school-level task may only access its own school's data |

### 9.3 Usability

| NFR-SDL-011 | Validation errors must be field-specific and human-readable (e.g., "The timing pattern is not a valid cron expression" rather than "Invalid field") |
| NFR-SDL-012 | The timing pattern field must include helper text or a link explaining cron expression syntax |
| NFR-SDL-013 | Run status badges must use consistent colour-coding: green = Success, red = Failed, amber = Running |

---

## 10. Gap Analysis Readiness Index

### 10.1 Requirement Coverage Table

| REQ-ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---|---|---|---|---|---|---|---|---|
| REQ-SDL-001 | Schedule Management Dashboard | P0 | DATA_ENTRY, DASHBOARD | schedules | Yes | No | No | Yes |
| REQ-SDL-002 | Create Job Schedule | P0 | DATA_ENTRY, CONFIGURATION | schedules | Yes | No | No | Yes |
| REQ-SDL-003 | Edit Job Schedule | P0 | DATA_ENTRY, CONFIGURATION | schedules | Yes | No | No | Yes |
| REQ-SDL-004 | Archive and Restore Schedule | P1 | WORKFLOW, CONFIGURATION | schedules (deleted_at) | Yes | No | No | Yes |
| REQ-SDL-005 | Enable and Pause Schedule | P1 | WORKFLOW, CONFIGURATION | schedules (is_active) | Yes | No | No | Yes |
| REQ-SDL-006 | Manual Schedule Trigger | P1 | WORKFLOW | schedule_runs | Yes | No | No | Yes |
| REQ-SDL-007 | Run History | P1 | REPORT, DASHBOARD | schedule_runs | Yes | No | No | Yes |
| REQ-SDL-008 | Automatic Schedule Execution Engine | P0 | SCHEDULED, WORKFLOW | schedule_runs, schedules (last_run_at, next_run_at, failure_count) | No | No | No | Yes |
| REQ-SDL-009 | Job Catalog Management | P2 | CONFIGURATION | (in-code only) | No | No | No | Yes |

### 10.2 Business Rule Coverage

| BR-ID | Rule Summary | REQ ref | Implemented? |
|---|---|---|---|
| BR-SDL-001 | Permission gate on every screen | REQ-SDL-001 through -009 | No — 0 Gate::authorize calls |
| BR-SDL-002 | Job type must be in Job Catalog | REQ-SDL-002, -003 | No |
| BR-SDL-003 | Valid cron expression required | REQ-SDL-002, -003 | No |
| BR-SDL-004 | Payload is valid JSON, max 10k chars | REQ-SDL-002, -003 | No |
| BR-SDL-005 | School required when school-level scope | REQ-SDL-002, -003 | No (scope hardcoded to prime) |
| BR-SDL-006 | Scope/task-type compatibility | REQ-SDL-002, -003 | No |
| BR-SDL-007 | Unique schedule name | REQ-SDL-002, -003 | No |
| BR-SDL-008 | Compute Next Run Time on save | REQ-SDL-002, -003 | No |
| BR-SDL-009 | Edit does not cancel running executions | REQ-SDL-003 | N/A (edit not implemented) |
| BR-SDL-010 | Archive pauses execution | REQ-SDL-004 | No (destroy is empty) |
| BR-SDL-011 | Only Super Admin can force-delete | REQ-SDL-004 | No |
| BR-SDL-012 | Permanent delete cascades to run records | REQ-SDL-004 | No |
| BR-SDL-013 | Toggle changes only is_active | REQ-SDL-005 | No (no toggle endpoint) |
| BR-SDL-014 | Manual trigger creates Execution Record | REQ-SDL-006 | No (no run endpoint) |
| BR-SDL-015 | Manual trigger bypasses paused state | REQ-SDL-006 | No |
| BR-SDL-016 | Archived schedules excluded from list/engine | REQ-SDL-001, -008 | No (SoftDeletes missing) |
| BR-SDL-017 | All writes logged to activity trail | All | No (0 activityLog calls) |
| BR-SDL-018 | Run history ordered by start time desc | REQ-SDL-007 | No (view not built) |
| BR-SDL-019 | Run history paginated at 15/page | REQ-SDL-007 | No |
| BR-SDL-020 | Engine only runs active, non-archived schedules | REQ-SDL-008 | Not applicable (engine not built) |
| BR-SDL-021 | Cron due-check semantics | REQ-SDL-008 | `dueSchedules()` exists; `runSchedule()` missing |
| BR-SDL-022 | Per-schedule failure isolation | REQ-SDL-008 | Not applicable (engine not built) |
| BR-SDL-023 | School context initialization for school-level tasks | REQ-SDL-008 | Not applicable |
| BR-SDL-024 | Overlap prevention on execution command | REQ-SDL-008 | Not applicable (command not built) |

### 10.3 Report Coverage

| RPT-ID | Report | Screen Needed | Export Needed |
|---|---|---|---|
| RPT-SDL-001 | Run History (per schedule) | Yes | No |
| RPT-SDL-002 | Schedule Health Summary (list widget) | Yes (as columns on list) | No |
| RPT-SDL-003 | Archived Schedules View | Yes | No |

### 10.4 Totals Summary

| Artifact | Count |
|---|---|
| Functional Requirements (REQ-SDL-) | 9 |
| Business Rules (BR-SDL-) | 24 |
| Reports (RPT-SDL-) | 3 |
| Future Enhancements (ENH-SDL-) | 7 |
| P0 Requirements | 3 (REQ-SDL-001, -002, -008) |
| P1 Requirements | 5 (REQ-SDL-003, -004, -005, -006, -007) |
| P2 Requirements | 1 (REQ-SDL-009) |
| BRs with no code implementation | 23 of 24 (BR-SDL-021 partially done) |

---

# SECTION B — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report | Test Class | Code Status | Key Gap |
|---|---|---|---|---|---|---|---|---|
| REQ-SDL-001 | Schedule Management Dashboard | BR-SDL-001, -016 | schedule/index | — | RPT-SDL-002 | SchedulerControllerAuthTest | Partial — renders but no pagination, no auth, no search/filter | Auth + pagination + search |
| REQ-SDL-002 | Create Job Schedule | BR-SDL-002–008, -017 | schedule/create | WF-3 | — | ScheduleCreateTest | Partial — form works; bugs: double validation, hardcoded scope, no registry/cron validation | Validation rules, scope handling, service layer |
| REQ-SDL-003 | Edit Job Schedule | BR-SDL-002–009, -017 | schedule/edit | WF-3 | — | ScheduleUpdateTest | Not Started — edit() returns wrong view; update() is empty | Entire feature |
| REQ-SDL-004 | Archive and Restore Schedule | BR-SDL-010–012, -016, -017 | schedule/trash | — | RPT-SDL-003 | ScheduleDeleteTest | Not Started — destroy() empty; SoftDeletes missing; trash view wrong content | SoftDeletes, destroy, restore, trash view |
| REQ-SDL-005 | Enable and Pause Schedule | BR-SDL-013, -017 | schedule/index (toggle) | — | — | ScheduleToggleTest | Not Started — button in view has no action URL | Toggle method + PATCH route |
| REQ-SDL-006 | Manual Schedule Trigger | BR-SDL-014, -015, -017 | schedule/show (button) | WF-2 | — | ScheduleDispatchTest | Not Started — no run() method, no route | run() method, POST route, runSchedule() service call |
| REQ-SDL-007 | Run History | BR-SDL-018, -019 | schedule/runs | — | RPT-SDL-001 | ScheduleRunHistoryTest | Not Started — no runs.blade.php; "Runs" href empty; ScheduleRun never written | runs view, runs route, runs() controller method |
| REQ-SDL-008 | Automatic Execution Engine | BR-SDL-020–024 | — (background) | WF-1 | — | ScheduleDispatchCommandTest | Not Started — runSchedule() missing; no Artisan command; ScheduleRun never created | Entire execution engine |
| REQ-SDL-009 | Job Catalog Management | BR-SDL-002 | schedule/create (dropdown) | — | — | JobRegistryTest | Partial — JobRegistry exists with 3 entries; needs 10+ | Expand registry to 10+ job types |

---

# SECTION C — Business Rules Register + Conditions + Validation Catalog

## C.1 Business Rules Register (standalone)

> Full register is in Section 4 (FRD). This section adds enforcement classification.

| BR-ID | Rule (abbreviated) | Type | Priority | Enforcement Layer |
|---|---|---|---|---|
| BR-SDL-001 | Permission gate on all screens | Permission | P0 | Controller (Gate::authorize), Policy |
| BR-SDL-002 | Job type must be in Job Catalog | Validation | P0 | FormRequest (Rule::in), custom rule |
| BR-SDL-003 | Valid cron expression | Validation | P1 | FormRequest (ValidCronExpression rule class) |
| BR-SDL-004 | Payload is valid JSON, max 10k | Validation | P1 | FormRequest (ValidJsonString rule class) |
| BR-SDL-005 | School required for school-level scope | Validation | P0 | FormRequest (required_if rule) |
| BR-SDL-006 | Scope/task-type compatibility | Validation | P1 | FormRequest (cross-field check) |
| BR-SDL-007 | Unique schedule name | Validation | P1 | FormRequest (unique rule on `schedules.name`) |
| BR-SDL-008 | Compute Next Run Time | Calculation | P1 | Service layer (SchedulerService::computeNextRunAt) |
| BR-SDL-009 | Edit does not cancel in-flight runs | Concurrency | P2 | None needed (edit is separate DB write) |
| BR-SDL-010 | Archive pauses execution | Workflow | P1 | Soft delete; execution engine query filter |
| BR-SDL-011 | Only Super Admin force-deletes | Permission | P1 | Policy (forceDelete), controller |
| BR-SDL-012 | Permanent delete cascades | Workflow | P1 | Service layer (explicit cascade) |
| BR-SDL-013 | Toggle changes only is_active | Workflow | P1 | Controller toggleStatus() — only `$schedule->update(['is_active' => !$schedule->is_active])` |
| BR-SDL-014 | Manual trigger creates Execution Record | Workflow | P1 | Service layer runSchedule() |
| BR-SDL-015 | Manual trigger bypasses paused state | Workflow | P1 | run() controller — passes schedule directly to runSchedule() without is_active check |
| BR-SDL-016 | Archived schedules excluded | Workflow | P1 | Model scope (withoutTrashed default, SoftDeletes) |
| BR-SDL-017 | Activity trail on all writes | Workflow | P1 | Controller/service activityLog() calls |
| BR-SDL-018 | Run history sorted desc | Validation | P1 | Query: `orderBy('started_at', 'desc')` |
| BR-SDL-019 | Run history paginated 15/page | Validation | P1 | Query: `->paginate(15)` |
| BR-SDL-020 | Engine only runs active, non-archived | Workflow | P0 | Execution command query: `is_active=true, deleted_at IS NULL` |
| BR-SDL-021 | Cron due-check | Calculation | P0 | SchedulerService::isDue() (already implemented) |
| BR-SDL-022 | Per-schedule failure isolation | Reliability | P0 | try/catch per schedule in command loop |
| BR-SDL-023 | School context initialization | Workflow / Security | P0 | tenancy()->initialize($tenant) in runSchedule() |
| BR-SDL-024 | Overlap prevention | Concurrency | P0 | ->withoutOverlapping() in registerCommandSchedules() |

## C.2 Requirement Conditions Catalog

| Condition (= BR-ID) | Entity/Field | Condition (business) | Type | Trigger | On-Violation |
|---|---|---|---|---|---|
| BR-SDL-002 | Job Type field | Must match an entry in the Job Catalog | Validation | Create/Edit form submit | Field-level error: "Please select a valid task type from the catalog" |
| BR-SDL-003 | Timing Pattern field | Must be a syntactically valid cron expression | Validation | Create/Edit form submit | Field-level error: "The timing pattern is not a valid cron expression" |
| BR-SDL-004 | Job Payload field | Must be valid JSON if provided; max 10,000 characters | Validation | Create/Edit form submit | Field-level error: "The payload must be valid JSON and under 10,000 characters" |
| BR-SDL-005 | Target School field | Required when scope is School-Level | Validation | Create/Edit form submit | Field-level error: "Please select a target school for School-Level schedules" |
| BR-SDL-006 | Scope + Job Type | Must be a supported scope for the chosen job type | Validation | Create/Edit form submit | Field-level error: "This task type does not support the selected scope" |
| BR-SDL-007 | Schedule Name | Must be unique across all schedules | Validation | Create/Edit form submit | Field-level error: "A schedule with this name already exists" |
| BR-SDL-011 | Permanent Delete action | Only Super Admin can permanently delete | Permission | Permanent delete attempt | HTTP 403 Access Denied |

## C.3 Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty/Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Schedule Name | "Monthly Billing Report" | "" (empty) | 255 characters exactly | Reject with required error | Two admins create same name simultaneously | Unique constraint violation → last writer gets DB-level error → shown as field validation error |
| Timing Pattern | `0 9 * * 1` (Mon 9AM) | `99 99 * * *` | `* * * * *` (every minute — valid) | Reject with required error | — | ValidCronExpression rule rejects invalid; `* * * * *` is accepted as valid (caution note in UI) |
| Job Payload | `{"year": 2026}` | `{broken json` | 10,000-character JSON string | Accepted (nullable) | — | ValidJsonString rule rejects malformed; max:10000 rejects oversized |
| Scope | "Platform-Level" | "random" | — | Reject with required error | — | `in:prime,tenant` rule |
| Target School | Valid school UUID | Non-existent UUID | — | Required when scope=tenant | — | required_if fails; FK validation recommended |
| is_active toggle | true → false | — | — | Defaults to Active on create | Two admins toggle same schedule simultaneously | Last write wins (acceptable; no monetary consequence) |
| runSchedule() — job class not found | Known key `prime_billing_report_job` | Removed key with existing schedule | — | — | Schedule exists; job class removed from code | Failed Execution Record created; error logged; no unhandled exception |
| Execution overlap | Single command cycle completes in <10s | 1000 due schedules causing >60s cycle | — | No due schedules: idle pass | Two scheduler processes start simultaneously | withoutOverlapping() prevents parallel execution |
| Cron expression in execution | `0 9 * * 1` | malformed (already blocked at save) | — | — | — | `SchedulerService::isDue()` catches Throwable, logs, returns false |

---

# SECTION D — Process Flows + FSM Catalog

## D.1 Process Flows

> Full narrative flows are in Section 6 (FRD). This section adds the FSM for schedule and run status.

## D.2 FSM Catalog

### FSM-SDL-001: Job Schedule States

**Entity:** Job Schedule
**Master driving states:** `is_active` (boolean) + `deleted_at` (soft-delete timestamp)

| From State | Event/Action | Guard (condition) | To State | Side-Effects |
|---|---|---|---|---|
| (new) | Create Schedule | Valid form; user has Create permission | Active | Execution Record: none; Next Run Time computed; activity logged |
| Active | Pause (toggle) | User has Edit permission | Paused | Next automatic execution skipped; activity logged |
| Paused | Activate (toggle) | User has Edit permission | Active | Schedule re-eligible for execution; activity logged |
| Active | Archive | User has Archive permission | Archived | `deleted_at` set; execution engine excludes it immediately; activity logged |
| Paused | Archive | User has Archive permission | Archived | Same as above |
| Archived | Restore | User has Restore permission | (returns to pre-archive state) Active or Paused | `deleted_at` cleared; activity logged |
| Archived | Force Delete | User has Force-Delete permission (Super Admin only) | [Destroyed — terminal] | All Execution Records also deleted; irreversible |

**Terminal states:** Destroyed (force-deleted)
**Illegal transitions:** Active → Force Delete (must archive first); Archived → Active directly without Restore

---

### FSM-SDL-002: Execution Record (Run) States

**Entity:** Execution Record (Schedule Run)
**Driven by:** `status` enum (`running` / `success` / `failed`)

| From State | Event/Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (new) | Execution begins (automatic or manual) | Execution engine or manual trigger | Running | `started_at` = now; `attempt` = 1 |
| Running | Job completes successfully | No exception thrown | Success | `finished_at` = now; `duration_ms` computed; schedule `last_run_at` updated |
| Running | Job throws exception or dispatch fails | Exception caught | Failed | `error_message` filled; `finished_at` = now; schedule `failure_count` incremented |
| Failed | — | — | — (terminal) | No state change; a new Execution Record is created on next trigger |
| Success | — | — | — (terminal) | No state change; a new Execution Record is created on next trigger |

**Terminal states:** Success, Failed
**Illegal transitions:** Success → Failed; Failed → Success (each run creates a new Execution Record)

---

# SECTION E — Data Dictionary + Cross-Module Dependency Map

## E.1 Data Dictionary (Technical View)

| Business Field | Table.Column | Type | FK | Cast | PII? |
|---|---|---|---|---|---|
| Schedule Name | `schedules.name` | VARCHAR(255) NOT NULL | — | string | No |
| Scope | `schedules.schedule_type` | ENUM('prime','tenant') NOT NULL | — | string | No |
| Target School | `schedules.tenant_id` | VARCHAR(255) NULL | informal (no FK constraint) | string | No |
| Job Type | `schedules.job_key` | VARCHAR(255) NOT NULL | — | string | No |
| Timing Pattern | `schedules.cron_expression` | VARCHAR(255) NOT NULL | — | string | No |
| Job Payload | `schedules.payload` | JSON NULL | — | array | No |
| Active | `schedules.is_active` | TINYINT(1) NOT NULL DEFAULT 1 | — | boolean | No |
| Last Run Time | `schedules.last_run_at` | TIMESTAMP NULL | — | datetime | No |
| Next Run Time | `schedules.next_run_at` | TIMESTAMP NULL | — | datetime | No |
| Failure Count | `schedules.failure_count` | INT UNSIGNED DEFAULT 0 | — | integer | No (MISSING — needs migration) |
| Created By | `schedules.created_by` | BIGINT UNSIGNED NULL | → sys_users.id | integer | No (MISSING — needs migration) |
| Archived At | `schedules.deleted_at` | TIMESTAMP NULL | — | datetime | No (MISSING — needs migration) |
| — | `schedules.created_at` / `updated_at` | TIMESTAMP | — | datetime | No |
| Run → Schedule | `schedule_runs.schedule_id` | INT UNSIGNED NOT NULL | → schedules.id RESTRICT | integer | No |
| Run Target School | `schedule_runs.tenant_id` | VARCHAR(255) NULL | informal | string | No |
| Run Status | `schedule_runs.status` | ENUM('running','success','failed') NOT NULL | — | string | No |
| Error Message | `schedule_runs.error_message` | TEXT NULL | — | string | No |
| Execution Output | `schedule_runs.output` | LONGTEXT NULL | — | string | No (MISSING — needs migration) |
| Start Time | `schedule_runs.started_at` | TIMESTAMP NOT NULL | — | datetime | No |
| Finish Time | `schedule_runs.finished_at` | TIMESTAMP NULL | — | datetime | No |
| Duration | `schedule_runs.duration_ms` | INT NULL | — | integer | No |
| Attempt Number | `schedule_runs.attempt` | TINYINT UNSIGNED DEFAULT 1 | — | integer | No (MISSING — needs migration) |
| Run Created By | `schedule_runs.created_by` | BIGINT UNSIGNED NULL | — | integer | No (MISSING — needs migration) |
| Run Archived At | `schedule_runs.deleted_at` | TIMESTAMP NULL | — | datetime | No (MISSING — needs migration) |

**Missing Migrations Required:**
1. `add_columns_to_schedules_table` — add `deleted_at`, `created_by`, `failure_count`
2. `add_columns_to_schedule_runs_table` — add `deleted_at`, `created_by`, `output`, `attempt`

## E.2 Cross-Module Dependency Map

### Inbound (Scheduler reads from)

| Source Module | Data/Entity | Why | Mechanism |
|---|---|---|---|
| Prime (central) | Tenant / School records (`prm_tenant`) | Required when dispatching School-Level tasks — need school identifier to initialize data context | Direct query at dispatch time |
| All modules with jobs | Job class implementations | Each module contributes job classes; `JobRegistry` must reference them by fully-qualified class name | Static registry — code change + deploy |

### Outbound (Scheduler triggers)

| Target Module | Mechanism | What Triggered | Status |
|---|---|---|---|
| Billing | Queue dispatch → `BillingReportJob` | Monthly billing report PDF generation (platform-level) | Registered in JobRegistry (job class may not exist yet) |
| Recommendation | Queue dispatch → `ExpireRecommendationsJob` (planned) | Mark overdue recommendations expired — school-level | Planned; not yet registered |
| StudentFee / Notification | Queue dispatch → `FeeReminderJob` (planned) | Fee reminder SMS/email to parents — school-level | Planned; not yet registered |
| StudentProfile / Notification | Queue dispatch → `AttendanceSmsJob` (planned) | Daily attendance SMS — school-level | Planned; not yet registered |
| HPC / MarksheetGeneration | Queue dispatch → `PdfBatchReportJob` (planned) | Batch PDF report card generation — school-level | Planned; not yet registered |
| Any (data archival) | Queue dispatch → `DataArchivalJob` (planned) | Year-end academic data archival | Planned; not yet registered |
| SmartTimetable | Queue dispatch → `TimetableConstraintValidationJob` (planned) | Re-validate constraints after bulk changes | Planned; not yet registered |

**Key architectural note:** The Scheduler does not read from or write to tenant databases directly — it only dispatches jobs to the queue. The actual data access happens inside the job class, which runs in the correct tenant context.

---

# SECTION F — NFR Catalog + Risk Register

## F.1 NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|---|---|---|---|
| NFR-SDL-001 | Performance | Schedule list must paginate at 15/page — no full-table load | Page renders in < 1 second with 100+ schedules |
| NFR-SDL-002 | Performance | Execution cycle (check all due + dispatch) completes within one minute | <10 seconds for 100 active schedules |
| NFR-SDL-003 | Performance | Run History query returns in < 500ms | With `started_at` and `schedule_id` indexes |
| NFR-SDL-004 | Security | Every controller method calls `Gate::authorize()` before any business logic | 0 unprotected methods in controller |
| NFR-SDL-005 | Security | Tenant-side users cannot reach any scheduler route | 403 for any school-role user attempting access |
| NFR-SDL-006 | Security | Job type field validated against Job Catalog | No arbitrary string accepted as job_key |
| NFR-SDL-007 | Security | Payload capped at 10,000 characters, validated as JSON | max:10000 + ValidJsonString rule |
| NFR-SDL-008 | Security | All writes logged in sys_activity_logs | 0 unlogged write operations |
| NFR-SDL-009 | Security | School-level tasks use platform tenancy isolation | job dispatched inside `tenancy()->initialize()` context |
| NFR-SDL-010 | Reliability | One schedule failure must not stop other due schedules | Per-schedule try/catch in execution loop |
| NFR-SDL-011 | Reliability | Execution cycle must not overlap with previous cycle | `withoutOverlapping()` registered on command |
| NFR-SDL-012 | Reliability | Invalid cron expressions are logged and skipped, not thrown | `isDue()` catches `\Throwable` — confirmed implemented |
| NFR-SDL-013 | Usability | Validation errors are field-specific and human-readable | Custom message bag per validation rule |
| NFR-SDL-014 | Usability | Timing pattern field includes helper text or cron documentation link | UI element visible on create/edit form |
| NFR-SDL-015 | Usability | Status badges use consistent colour-coding | Green = Success, Red = Failed, Amber = Running |

## F.2 Risk Register

| RISK-ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|---|
| RISK-SDL-001 | Zero authorization: any authenticated user (including school staff) can currently manage schedules | Security | High | Critical | P0: Add SchedulePolicy + Gate::authorize to all controller methods | Developer |
| RISK-SDL-002 | Execution engine not built: schedules are stored but never executed — the module has no actual scheduling capability | Functional | Confirmed (already true) | Critical | P0: Implement runSchedule() + ScheduleDispatchCommand | Developer |
| RISK-SDL-003 | Invalid cron expression accepted at create time causes silent skipping at execution time | Data Integrity | High (currently unfixed) | High | P1: Add ValidCronExpression rule to FormRequest | Developer |
| RISK-SDL-004 | Arbitrary job_key accepted: if malicious user sets job_key to a non-existent class, runtime exceptions occur | Security | Medium (requires authenticated access) | High | P1: Add Rule::in(JobRegistry::keys()) validation | Developer |
| RISK-SDL-005 | School-level task dispatch without tenancy initialization causes cross-school data contamination | Security / Data | High (once engine is built, if tenancy init is omitted) | Critical | Design review: runSchedule() must check `isTenant()` and call `tenancy()->initialize()` before dispatch | Developer / Architect |
| RISK-SDL-006 | ScheduleRun never written to: no execution history accumulated even if jobs run through other means | Observability | Confirmed (already true) | Medium | Fix within execution engine implementation | Developer |
| RISK-SDL-007 | Route triplication in central web.php causes named-route conflicts and unpredictable redirect behaviour | Functional | Confirmed (already true) | High | P1: Consolidate to module's own routes/web.php | Developer |
| RISK-SDL-008 | Execution cycle takes >60 seconds on large schedule counts, causing overlapping command instances | Performance | Low (only 3 jobs currently) | High | Implement withoutOverlapping(); monitor as registry grows | Developer / DevOps |
| RISK-SDL-009 | Scheduler routes loaded by RSP using only `web` middleware (no `InitializeTenancyByDomain`) — architecture correct for central module but must be verified after any middleware refactor | Architecture | Low | High | Document as design decision D-SDL-06; verify on middleware changes | Architect |

---

# SECTION G — Prioritization + Effort Estimation

## G.1 MoSCoW Prioritization

### Must Have (P0 — before any release)
- REQ-SDL-001: Schedule Management Dashboard (auth + pagination + search — partial today)
- REQ-SDL-002: Create Job Schedule (fix validation, scope selection, remove double-validation bug)
- REQ-SDL-003: Edit Job Schedule (implement update() and edit() methods)
- REQ-SDL-008: Automatic Schedule Execution Engine (runSchedule() + ScheduleDispatchCommand — entirely missing)
- All P0 security BRs: BR-SDL-001, -002, -005, -020, -022, -023, -024

### Should Have (P1 — same release, second priority)
- REQ-SDL-004: Archive and Restore Schedule (SoftDeletes + destroy() + restore() + trash view)
- REQ-SDL-005: Enable and Pause Schedule (toggle endpoint + route)
- REQ-SDL-006: Manual Schedule Trigger (run() method + route)
- REQ-SDL-007: Run History (runs view + route + runs() method)
- BR-SDL-003, -004, -007, -008 (validation, name uniqueness, Next Run Time compute)
- BR-SDL-017 (activity logging on all writes)
- Route consolidation (RT-001)
- Pagination on index (PERF-001)

### Could Have (P2 — next sprint)
- REQ-SDL-009: Job Catalog expansion (add 7+ new job types)
- Expandable error output in run history (ENH detail)
- Schedule name uniqueness check (could be later if name is descriptive enough)
- `SchedulerType` conversion to PHP 8.1 backed enum

### Won't Have (this phase)
- ENH-SDL-001 through -007 (queue monitoring, alerting, visual cron builder, dependency chains)
- School-side self-service scheduling
- REST API endpoints for programmatic access
- Auto-discovery of job classes

## G.2 Effort Estimation and Sprint Task Breakdown

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|---|---|---|---|---|
| 1 | Create `SchedulePolicy` with viewAny/view/create/update/delete/restore/forceDelete | Backend | 1.5 | — | 1 |
| 2 | Register `SchedulePolicy` in module service provider + seed permissions (`admin.scheduler.*`) | Backend | 0.5 | Task 1 | 1 |
| 3 | Add `Gate::authorize()` to all 7 existing controller methods | Backend | 1.0 | Task 1 | 1 |
| 4 | Update `ScheduleRequest::authorize()` to check policy | Backend | 0.25 | Task 1 | 1 |
| 5 | Add `ValidCronExpression` custom rule class | Backend | 1.0 | — | 1 |
| 6 | Add `ValidJsonString` custom rule class | Backend | 0.5 | — | 1 |
| 7 | Fix `ScheduleRequest` rules: add `schedule_type`, `tenant_id`, `job_key` (Rule::in), cron rule, payload rule | Backend | 1.0 | Tasks 5, 6 | 1 |
| 8 | Remove inline `$request->validate()` from `store()` (fix double-validation BUG-001) | Backend | 0.25 | Task 7 | 1 |
| 9 | Add scope selection + school selector to `schedule/create.blade.php` | Frontend | 1.5 | — | 1 |
| 10 | Migration: add `deleted_at`, `created_by`, `failure_count` to `schedules` table | Schema | 0.5 | — | 1 |
| 11 | Migration: add `deleted_at`, `created_by`, `output`, `attempt` to `schedule_runs` table | Schema | 0.5 | — | 1 |
| 12 | Add `SoftDeletes` to `Schedule` model; update `$fillable` (add `last_run_at`, `next_run_at`, `failure_count`, `created_by`) | Backend | 0.5 | Task 10 | 1 |
| 13 | Add `SoftDeletes` to `ScheduleRun` model; add `runs()` HasMany on `Schedule`; add `schedule()` BelongsTo on `ScheduleRun`; explicit `$table`; update `$fillable` | Backend | 0.5 | Task 11 | 1 |
| 14 | Implement `SchedulerService::runSchedule()` — job lookup, tenant init, dispatch, Execution Record creation, failure handling | Backend | 3.0 | Tasks 12, 13 | 2 |
| 15 | Implement `SchedulerService::createSchedule()` and `updateSchedule()` (service layer for controller delegation) | Backend | 1.0 | Task 14 | 2 |
| 16 | Implement `SchedulerService::computeNextRunAt()` using CronExpression | Backend | 0.5 | — | 2 |
| 17 | Create `ScheduleDispatchCommand` Artisan command; register in `SchedulerServiceProvider`; `withoutOverlapping()` | Backend | 2.0 | Task 14 | 2 |
| 18 | Implement `update()` controller method; fix `edit()` to load schedule model | Backend | 1.0 | Task 15 | 2 |
| 19 | Implement `destroy()` (soft delete), `trashedSchedule()`, `restore()` controller methods | Backend | 1.0 | Task 12 | 2 |
| 20 | Implement `toggleStatus()` AJAX method + PATCH route | Backend | 0.75 | — | 2 |
| 21 | Implement `run()` manual trigger method + POST route | Backend | 0.75 | Task 14 | 2 |
| 22 | Implement `runs()` run history method + GET route | Backend | 0.5 | — | 2 |
| 23 | Implement `show()` — load schedule + recent runs | Backend | 0.5 | — | 2 |
| 24 | Consolidate triplicated scheduler routes in central `web.php` | Backend | 1.0 | — | 2 |
| 25 | Add pagination (15/page) + search/filter to `index()` | Backend | 0.75 | — | 2 |
| 26 | Fix `schedule/index.blade.php` — populate Runs href, Toggle action URL, add `@can` guards, pagination links, failure count column | Frontend | 1.5 | Tasks 20, 22, 2 | 2 |
| 27 | Replace `schedule/edit.blade.php` with proper schedule edit form | Frontend | 1.5 | — | 2 |
| 28 | Replace `schedule/trash.blade.php` with proper archived schedules view | Frontend | 1.0 | — | 2 |
| 29 | Create `schedule/show.blade.php` — schedule detail with run history summary | Frontend | 1.5 | — | 2 |
| 30 | Create `schedule/runs.blade.php` — paginated run history with status, timing, error details | Frontend | 2.0 | — | 2 |
| 31 | Add `activityLog()` to all write operations in controller/service | Backend | 1.0 | — | 2 |
| 32 | Add 5+ additional job types to `JobRegistry` (expand to 10+ entries) | Backend | 2.0 | Job classes must exist | 3 |
| 33 | Convert `SchedulerType` to PHP 8.1 backed enum | Backend | 0.5 | — | 3 |
| 34 | Write `SchedulerControllerAuthTest` (Feature: HTTP auth enforcement) | Testing | 2.0 | Task 3 | 1 |
| 35 | Write `ScheduleCreateTest` (Feature: validation, scope, job_key rejection) | Testing | 2.0 | Tasks 7, 8 | 1 |
| 36 | Write `SchedulerServiceTest` (Unit: dueSchedules, runSchedule) | Testing | 2.0 | Task 14 | 2 |
| 37 | Write `ScheduleDispatchCommandTest` | Testing | 1.5 | Task 17 | 2 |
| 38 | Write `ScheduleUpdateTest`, `ScheduleDeleteTest`, `ScheduleToggleTest`, `ScheduleRunHistoryTest` | Testing | 3.0 | Tasks 18–22 | 2 |
| 39 | Write `JobRegistryTest`, `ValidCronExpressionRuleTest`, `ValidJsonStringRuleTest` | Testing | 2.0 | Tasks 5, 6 | 1 |
| 40 | Invert SchedulerModuleTest broken-state assertions after security fix | Testing | 0.5 | Task 3 | 1 |

**Total Estimated Effort: ~44 hours**

| Sprint | Focus | Hours |
|---|---|---|
| Sprint 1 (P0 Security + Schema) | Tasks 1–13, 34–35, 39–40 | ~16h |
| Sprint 2 (Execution Engine + UI) | Tasks 14–31, 36–38 | ~26h |
| Sprint 3 (Quality + Expansion) | Tasks 32–33 | ~2.5h |

---

# SECTION H — User Stories + Reporting Spec

## H.1 User Stories and Acceptance Criteria

### US-SDL-001 — View Schedule List
**REQ ref:** REQ-SDL-001 | **Priority:** P0

As a Platform Administrator, I want to see all Job Schedules in a paginated list so that I can quickly
assess the state of all automated tasks and identify any that are failing or paused.

**Acceptance Criteria (Gherkin):**
```
Scenario: Prime Admin views schedule list
  Given I am logged in as a Prime Admin
  When I navigate to the Schedule Management screen
  Then I see a paginated list (15/page) of all non-archived schedules
    And each row shows Name, Job Type, Timing Pattern, Scope, Status, Last Run, Failure Count
    And schedules are ordered newest first

Scenario: Search filters the list
  Given I am on the schedule list
  When I type "billing" in the search box
  Then only schedules whose name or job type contains "billing" are shown

Scenario: Tenant school user is denied access
  Given I am logged in as a School Admin
  When I attempt to navigate to the schedule list
  Then I receive an Access Denied (403) response

Scenario: Empty state
  Given no Job Schedules have been created
  When I open the schedule list
  Then I see a message indicating no schedules exist yet, with a link to create the first one
```

---

### US-SDL-002 — Create a Job Schedule
**REQ ref:** REQ-SDL-002 | **Priority:** P0

As a Platform Administrator, I want to create a new Job Schedule by selecting a task type from the
catalog and configuring when and how it runs, so that the platform automatically executes it at the
right time without manual intervention.

**Acceptance Criteria (Gherkin):**
```
Scenario: Valid schedule created successfully
  Given I am on the Create Schedule form
  When I select job type "Monthly Billing Report", enter name "Monthly Billing - Run 1",
       enter timing pattern "0 9 1 * *", leave payload empty, and click Save
  Then a new Job Schedule is created and I am redirected to the list with a success message
    And the schedule appears in the list as Active
    And the activity trail records my creation action

Scenario: Invalid cron expression rejected
  Given I am on the Create Schedule form
  When I enter timing pattern "99 9 1 * *"
  Then form submission is rejected with error "The timing pattern is not a valid cron expression"

Scenario: Unregistered job type rejected
  Given I am on the Create Schedule form
  When I manually submit a job_key "hacker_job" not in the catalog
  Then form submission is rejected with error "Please select a valid task type from the catalog"

Scenario: School-Level scope without school selected
  Given I select scope "School-Level"
  When I submit the form without selecting a target school
  Then I receive error "Please select a target school for School-Level schedules"

Scenario: User without Create permission
  Given I am logged in as a Support Staff user
  When I attempt to access the Create Schedule form
  Then I receive an Access Denied (403) response
```

---

### US-SDL-003 — Edit a Job Schedule
**REQ ref:** REQ-SDL-003 | **Priority:** P0

As a Platform Administrator, I want to edit an existing Job Schedule so that I can adjust its timing
or payload without recreating it.

**Acceptance Criteria (Gherkin):**
```
Scenario: Timing pattern updated
  Given I have an existing schedule "Monthly Billing - Run 1" with timing "0 9 1 * *"
  When I change the timing to "0 8 1 * *" and save
  Then the schedule shows the new timing pattern
    And the Next Run Time is recomputed from the updated pattern

Scenario: Invalid cron rejected on edit
  Given I am editing an existing schedule
  When I enter "invalid" as the timing pattern and submit
  Then the form is returned with a field-level error on the timing pattern field

Scenario: All other fields unchanged when only timing is edited
  Given I edit only the timing pattern
  Then job type, payload, scope, and active state remain unchanged
```

---

### US-SDL-004 — Archive and Restore a Schedule
**REQ ref:** REQ-SDL-004 | **Priority:** P1

As a Platform Administrator, I want to archive a Job Schedule that is no longer needed so that it
stops running but can be recovered if required.

**Acceptance Criteria (Gherkin):**
```
Scenario: Schedule archived and disappears from list
  Given I have an Active schedule "Old Billing Job"
  When I click Archive on that schedule and confirm
  Then it disappears from the main schedule list
    And it appears in the Archived Schedules view with the archive date

Scenario: Archived schedule is not executed
  Given a schedule "Old Billing Job" is archived
  When the execution cycle runs and "Old Billing Job"'s timing pattern would be due
  Then "Old Billing Job" is NOT dispatched

Scenario: Restore an archived schedule
  Given "Old Billing Job" is in the Archived Schedules view
  When a Prime Admin clicks Restore
  Then the schedule appears again in the main schedule list in Active state

Scenario: Super Admin permanently deletes an archived schedule
  Given "Old Billing Job" is archived
  When a Super Admin clicks "Permanently Delete" and confirms
  Then the schedule and all its Execution Records are removed permanently

Scenario: Prime Admin cannot permanently delete
  Given "Old Billing Job" is archived
  When a Prime Admin clicks "Permanently Delete"
  Then they receive an Access Denied (403) response
```

---

### US-SDL-005 — Pause and Resume a Schedule
**REQ ref:** REQ-SDL-005 | **Priority:** P1

As a Platform Administrator, I want to quickly pause a Job Schedule during a maintenance window
without archiving it, so that I can resume it afterwards without reconfiguring anything.

**Acceptance Criteria (Gherkin):**
```
Scenario: Active schedule paused
  Given an Active schedule "Daily SMS Batch" is in the list
  When I click Pause
  Then the status badge changes to "Paused" without a full page reload

Scenario: Paused schedule reactivated
  Given a Paused schedule "Daily SMS Batch"
  When I click Activate
  Then the status badge changes to "Active"
    And the schedule will be executed on its next due cycle

Scenario: Paused schedule not dispatched in execution cycle
  Given "Daily SMS Batch" is Paused
  When the execution cycle runs at the schedule's due time
  Then "Daily SMS Batch" is not dispatched
```

---

### US-SDL-006 — Manually Trigger a Schedule
**REQ ref:** REQ-SDL-006 | **Priority:** P1

As a Platform Administrator, I want to manually trigger a schedule on demand so that I can test it
or force-run it outside its normal timing window.

**Acceptance Criteria (Gherkin):**
```
Scenario: Manual trigger dispatches job and creates run record
  Given I have an Active schedule "Monthly Billing Report"
  When I click "Run Now"
  Then the job is dispatched immediately to the background queue
    And a new Execution Record appears in the Run History with status "Running"
    And the schedule's Last Run Time is updated

Scenario: Manual trigger works even when schedule is Paused
  Given "Monthly Billing Report" is Paused
  When I click "Run Now"
  Then the job is dispatched (pause only prevents automatic dispatch, not manual)

Scenario: Manual trigger fails gracefully when job class missing
  Given a schedule whose job type has been removed from the catalog
  When I click "Run Now"
  Then a Failed Execution Record is created with message "Job class not found in registry"
    And the admin sees an error message on screen

Scenario: Support Staff cannot trigger
  Given I am logged in as Support Staff
  When I attempt to click "Run Now" on a schedule
  Then I receive an Access Denied (403) response
```

---

### US-SDL-007 — View Run History
**REQ ref:** REQ-SDL-007 | **Priority:** P1

As a Platform Administrator or Support Staff, I want to view the execution history for a schedule
so that I can diagnose failures and verify that tasks are completing successfully.

**Acceptance Criteria (Gherkin):**
```
Scenario: View run history for a schedule
  Given a schedule has 20 Execution Records
  When I click "View History" for that schedule
  Then I see the 15 most recent records with pagination controls
    And each row shows: Status, Start Time, Finish Time, Duration, School (if applicable), Attempt #

Scenario: Aggregate stats shown at top
  Given a schedule with 10 success and 3 failed runs
  When I view its Run History
  Then the aggregate panel shows: Total Runs = 13, Successful = 10, Failed = 3, Avg Duration = (computed)

Scenario: Failed run shows expandable error
  Given a Failed Execution Record exists
  When I click to expand the error details
  Then I see the full error message and (if captured) the execution output

Scenario: Empty run history (no runs yet)
  Given a newly created schedule with no executions
  When I view its Run History
  Then I see a message "No executions recorded yet"
```

---

### US-SDL-008 — Automatic Execution Engine Runs Due Schedules
**REQ ref:** REQ-SDL-008 | **Priority:** P0

As the Platform System, I automatically dispatch all due Job Schedules every minute so that
administrators don't need to manually trigger recurring tasks.

**Acceptance Criteria (Gherkin):**
```
Scenario: Due schedule is dispatched automatically
  Given an Active schedule "Daily Attendance SMS" with timing pattern "0 8 * * *"
  And the time is 08:00
  When the execution cycle runs
  Then the schedule is dispatched to the queue
    And an Execution Record is created with status "Running"
    And when the job completes, the record updates to "Success"

Scenario: Non-due schedule is skipped
  Given the same schedule with timing "0 8 * * *"
  And the time is 08:01
  When the execution cycle runs
  Then the schedule is NOT dispatched

Scenario: Paused schedule is skipped
  Given a Paused schedule whose timing pattern is currently due
  When the execution cycle runs
  Then the schedule is NOT dispatched

Scenario: One failure does not stop others
  Given two due schedules: A (valid) and B (job class removed)
  When the execution cycle runs
  Then A is dispatched successfully
    And B gets a Failed Execution Record with "Job class not found"
    And A's execution is not affected by B's failure

Scenario: School-level task runs in isolated school context
  Given a School-Level schedule targeting School X
  When the execution cycle dispatches it
  Then the job runs in School X's isolated data context and cannot access School Y's data

Scenario: Overlap prevention works
  Given the execution cycle from the previous minute is still running
  When the new minute arrives
  Then a second cycle does NOT start (overlap prevented)
```

---

## H.2 Reporting and KPI Specification

> Detailed RPT specs are in FRD Section 7. This section adds KPI definitions.

| KPI | Definition / Formula | Source Data | Target | Cadence |
|---|---|---|---|---|
| Schedule Success Rate | (Total Successful Runs / Total Runs) × 100 for a given period | `schedule_runs.status` | > 95% | Weekly |
| Schedule Failure Count | Count of Failed Execution Records per schedule | `schedule_runs WHERE status='failed'` | 0 consecutive failures | Real-time on list |
| Average Execution Duration | Sum(duration_ms) / Count(runs) per schedule | `schedule_runs.duration_ms` | Baseline varies by job type | Per run batch |
| Pending Job Registry Gaps | Count of job types needed but not yet registered in Job Catalog | Code review vs V2 requirements | 0 (all 10+ planned jobs registered) | Per deployment |
| Time-to-First-Execution | Time from schedule creation to first Execution Record | schedules.created_at vs first schedule_runs.started_at | < 2 minutes (within 2 execution cycles) | Per schedule creation |

---

*Complete Analysis Pack generated by pa-business-analyst | 2026-06-29*
*Sources: V1 req (Dev_Done), V2 req (2026-03-26), Gap Analysis (2026-03-22), live code `Modules/Scheduler/`, migrations verified against filesystem*
*Module Knowledge: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/SDL_Scheduler.md`*
