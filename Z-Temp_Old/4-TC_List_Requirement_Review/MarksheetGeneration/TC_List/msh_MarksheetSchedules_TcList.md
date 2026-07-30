# Marksheet Schedule — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Marksheet Schedule (`msh_marksheet_schedules`) |
| **Controller** | `MarksheetScheduleController` — 14 methods (index, create, store, show, edit, update, destroy, review, publish, unlock, lock, precheck, compute, export) |
| **Tab Container** | `MarksheetGenerationController@scheduling()` — tab id `schedules` |
| **Model** | `MarksheetSchedule` — SoftDeletes, 10 relationships |
| **Form Requests** | `MarksheetScheduleRequest` (8 rules), `UnlockMarksheetScheduleRequest` (1 rule) |
| **Service Layer** | `MarksheetScheduleService` (CRUD), `MarksheetScheduleLifecycleService` (state machine) |
| **Job** | `ComputeMarksheetJob` — dispatched synchronously or queued |
| **Permission** | `tenant.msh-marksheet-schedule` — actions: view, create, update, delete, review, publish, lock, unlock, export |
| **Routes** | `marksheet-schedule.*` (resource) + review, publish, unlock, lock, precheck, compute, export |
| **Hub Route** | `marksheet-generation.scheduling.combined?tab=schedules` |
| **DB Table** | `msh_marksheet_schedules` — 18 fillable columns + timestamps |
| **Pagination** | 15 per page — page name `sch_page` |
| **Eager Loads** | configTemplate |
| **State Machine** | DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User logged in with `tenant.msh-marksheet-schedule.*` permissions |
| PC-02 | `msh_marksheet_schedules` table exists with all columns |
| PC-03 | `msh_config_templates` has active templates for selection |
| PC-04 | `sch_org_academic_sessions_jnt` has active academic sessions |
| PC-05 | `sys_dropdowns` has status entries for `msh_marksheet_schedules.status_id` (DRAFT, COMPUTED, REVIEWED, PUBLISHED, LOCKED) |
| PC-06 | `MarksheetScheduleService` and `MarksheetScheduleLifecycleService` injectable |
| PC-07 | `ComputeMarksheetJob` class exists and is dispatchable |
| PC-08 | Queue system configured (sync for local, queue worker for production) |
| PC-09 | Soft deletes enabled on `msh_marksheet_schedules` |
| PC-10 | Activity log system operational |
| PC-11 | `permissionslist.php` has `msh-marksheet-schedule` with specific actions |
| PC-12 | `Maatwebsite\Excel` installed for export functionality |
| PC-13 | `ComputationLog` table exists for tracking compute jobs |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | index() redirects to hub schedules tab | `Controller:37-39` — `redirect()->route('scheduling.combined', ['tab' => 'schedules'])` |
| DL-02 | Hub scheduling page loads schedules with eager loads and pagination | Hub controller via `MarksheetGenerationController@scheduling()` |
| DL-03 | Eager loads: configTemplate relationship | Loads template for display |
| DL-04 | Search/filter bar with tab hidden input `?tab=schedules` | Tab partial blade |
| DL-05 | Status column uses badge based on status value | Tab partial blade |
| DL-06 | Action column has lifecycle buttons (compute, review, publish, lock, unlock) | Conditional buttons based on current state |
| DL-07 | Pagination with `?tab=schedules&sch_page=N` | Blade appends tab param |
| DL-08 | Empty state: "No records found" | @empty block |
| DL-09 | Create form loads: configTemplates, academicSessions, statuses, classSections | `Controller:46-58` |
| DL-10 | Edit form loads same dropdowns + selectedClassSectionIds | `Controller:89-105` |
| DL-11 | Show page loads 6+ relationships | `Controller:80` |
| DL-12 | Precheck page loads extensive relations + template checks | `Controller:229-240` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Schedule (DRAFT)** | Valid config_template_id, academic_session_id, unique code, name, date, status_id=DRAFT |
| TD-02 | **Duplicate Code + Session** | Same `code` within same academic session — expects unique violation |
| TD-03 | **Invalid Config Template** | config_template_id=99999 — exists failure |
| TD-04 | **Invalid Academic Session** | academic_session_id=99999 — exists failure |
| TD-05 | **Invalid Status ID** | status_id=99999 — exists failure |
| TD-06 | **Schedule in COMPUTED state** | After computation: status_id=COMPUTED |
| TD-07 | **Schedule in REVIEWED state** | After review: status_id=REVIEWED |
| TD-08 | **Schedule in PUBLISHED state** | After publish: status_id=PUBLISHED |
| TD-09 | **Schedule in LOCKED state** | After lock: status_id=LOCKED, is_locked=true |
| TD-10 | **State Machine Violation** | Attempt review on DRAFT (should be COMPUTED) — DomainException |
| TD-11 | **Compute on LOCKED** | Attempt compute on locked schedule — error message |
| TD-12 | **Already Running Compute** | Existing RUNNING ComputationLog — error: "Computation already in progress" |

---

## 5. Business Conditions Matrix

| BC ID | Condition Type | Category | Description |
|-------|---------------|----------|-------------|
| BC-DB-01 | DB | Structure | Table `msh_marksheet_schedules` has 18 fillable columns + timestamps |
| BC-DB-02 | DB | Structure | `status_id` is Varchar(50) — NOT FK to sys_dropdowns (Laravel ENUM?) |
| BC-DB-03 | DB | Structure | `is_locked` boolean — enforced via model casts |
| BC-DB-04 | DB | Soft Delete | `deleted_at` column present — use SoftDeletes trait |
| BC-DB-05 | DB | Unique | Composite unique on (code, academic_session_id) |
| BC-DB-06 | DB | FK | `config_template_id` → `msh_config_templates.id` |
| BC-DB-07 | DB | FK | `academic_session_id` → `sch_org_academic_sessions_jnt.id` |
| BC-DB-08 | DB | FK | `created_by` → `users.id` |
| BC-DB-09 | DB | FK | `updated_by` → `users.id` |
| BC-VAL-01 | VAL | Required | `code`, `name`, `schedule_date`, `status_id`, `config_template_id`, `academic_session_id` |
| BC-VAL-02 | VAL | Unique | `code` unique within same `academic_session_id` |
| BC-VAL-03 | VAL | Exists | `config_template_id` must exist in `msh_config_templates` |
| BC-VAL-04 | VAL | Exists | `academic_session_id` must exist in `sch_org_academic_sessions_jnt` |
| BC-VAL-05 | VAL | Exists | `status_id` must exist in `sys_dropdowns` |
| BC-VAL-06 | VAL | Required | `selected_class_section_ids` on create |
| BC-VAL-07 | VAL | Boolean | `is_locked` cast to bool |
| BC-VAL-08 | VAL | Date | `schedule_date` must be valid date format |
| BC-AUTH-01 | AUTH | Gate | `index()` → `tenant.msh-marksheet-schedule.viewAny` |
| BC-AUTH-02 | AUTH | Gate | `create()` → `tenant.msh-marksheet-schedule.create` |
| BC-AUTH-03 | AUTH | Gate | `store()` → `tenant.msh-marksheet-schedule.create` |
| BC-AUTH-04 | AUTH | Gate | `show()` → `tenant.msh-marksheet-schedule.view` |
| BC-AUTH-05 | AUTH | Gate | `edit()` → `tenant.msh-marksheet-schedule.update` |
| BC-AUTH-06 | AUTH | Gate | `update()` → `tenant.msh-marksheet-schedule.update` |
| BC-AUTH-07 | AUTH | Gate | `destroy()` → `tenant.msh-marksheet-schedule.delete` |
| BC-AUTH-08 | AUTH | Gate | `review()` → `tenant.msh-marksheet-schedule.review` |
| BC-AUTH-09 | AUTH | Gate | `publish()` → `tenant.msh-marksheet-schedule.publish` |
| BC-AUTH-10 | AUTH | Gate | `unlock()` → `tenant.msh-marksheet-schedule.unlock` |
| BC-AUTH-11 | AUTH | Gate | `lock()` → `tenant.msh-marksheet-schedule.lock` |
| BC-AUTH-12 | AUTH | Gate | `precheck()` → `tenant.msh-marksheet-schedule.view` |
| BC-AUTH-13 | AUTH | Gate | `compute()` → `tenant.msh-marksheet-schedule.view` |
| BC-AUTH-14 | AUTH | Gate | `export()` → `tenant.msh-marksheet-schedule.export` |
| BC-AUTH-15 | AUTH | Gate | `trashed()` → `tenant.msh-marksheet-schedule.viewAny` |
| BC-AUTH-16 | AUTH | Gate | `restore()` → `tenant.msh-marksheet-schedule.update` |
| BC-AUTH-17 | AUTH | Gate | `forceDelete()` → `tenant.msh-marksheet-schedule.delete` |
| BC-BIZ-01 | BIZ | State Machine | Schedule must be in COMPUTED state to be reviewed |
| BC-BIZ-02 | BIZ | State Machine | Schedule must be in REVIEWED state to be published |
| BC-BIZ-03 | BIZ | State Machine | Only PUBLISHED schedules can be locked |
| BC-BIZ-04 | BIZ | State Machine | Only LOCKED schedules can be unlocked |
| BC-BIZ-05 | BIZ | State Machine | DRAFT schedules can be computed (compute moves DRAFT→COMPUTED) |
| BC-BIZ-06 | BIZ | State Machine | LOCKED schedules CANNOT be computed — error: "marksheet is locked" |
| BC-BIZ-07 | BIZ | State Machine | State transitions are one-way: DRAFT→COMPUTED→REVIEWED→PUBLISHED→LOCKED |
| BC-BIZ-08 | BIZ | Compute | Computation requires valid config_template_id with template data |
| BC-BIZ-09 | BIZ | Compute | Computation is asynchronous — dispatches `ComputeMarksheetJob` |
| BC-BIZ-10 | BIZ | Compute | Computation logs tracked in `ComputationLog` table |
| BC-BIZ-11 | BIZ | Compute | Cannot start compute if same schedule already has a RUNNING computation |
| BC-BIZ-12 | BIZ | Compute | Precheck validates template has required scores/components before compute |
| BC-BIZ-13 | BIZ | Export | Export uses `Maatwebsite\Excel` to generate spreadsheet |
| BC-BIZ-14 | BIZ | Export | Export returns downloadable .xlsx file |
| BC-BIZ-15 | BIZ | Delete | Only DRAFT schedules can be soft-deleted |
| BC-BIZ-16 | BIZ | Delete | Deleting a schedule cascades to marksheet entries |

### BC-REL: Relationship Map

| Relation | Type | Model | FK | Eager? |
|----------|------|-------|----|--------|
| configTemplate | BelongsTo | MarksheetConfigTemplate | config_template_id | Yes (hub list) |
| academicSession | BelongsTo | AcademicSession | academic_session_id | No (default) |
| marksheets | HasMany | Marksheet | schedule_id | No |
| computationLogs | HasMany | ComputationLog | schedule_id | No |
| createdBy | BelongsTo | User | created_by | No |
| updatedBy | BelongsTo | User | updated_by | No |
| deletedBy | BelongsTo | User | deleted_by | No |
| marksheetScores | HasManyThrough | MarksheetScore | via Marksheet | No |
| classSections | BelongsToMany | ClassSection | pivot | Yes (via selectedClassSectionIds) |
| scheduleClassSections | HasMany | ScheduleClassSection | schedule_id | Yes |

### BC-BIZ-DEEP: State Machine — Detailed Analysis

| State | Allowed Transitions → | Guards | Actions |
|-------|----------------------|--------|---------|
| DRAFT | → COMPUTED | Gate: view, Schedule not locked, No running computation | LifecycleService::compute() dispatches job |
| DRAFT | → DELETED | Gate: delete, No marksheets referencing | Service::trash() |
| COMPUTED | → REVIEWED | Gate: review, Must be COMPUTED | LifecycleService::review() |
| REVIEWED | → PUBLISHED | Gate: publish, Must be REVIEWED | LifecycleService::publish() |
| PUBLISHED | → LOCKED | Gate: lock, Must be PUBLISHED | LifecycleService::lock() |
| LOCKED | → PUBLISHED (unlock) | Gate: unlock, Must be LOCKED | LifecycleService::unlock() |
| LOCKED | ⊥ Terminus | No transitions out except unlock | Cannot compute, cannot delete |

### State Transition Matrix

```
                  ┌──────────┐
                  │  DRAFT   │
                  └────┬─────┘
                       │ compute()
                       ▼
                  ┌──────────┐
                  │ COMPUTED │
                  └────┬─────┘
                       │ review()
                       ▼
                  ┌──────────┐
                  │ REVIEWED │
                  └────┬─────┘
                       │ publish()
                       ▼
                  ┌──────────┐
                  │ PUBLISHED│◄────────────┐
                  └────┬─────┘            │
                       │ lock()           │ unlock()
                       ▼                  │
                  ┌──────────┐            │
                  │  LOCKED  │────────────┘
                  └──────────┘
```

### CODE-TRACE: MarksheetScheduleController — Complete Analysis

| Method | Line | Gate | Input | Service Call | Response |
|--------|------|------|-------|-------------|----------|
| index() | 35-39 | viewAny | — | — | redirect to scheduling.combined?tab=schedules |
| create() | 46-58 | create | — | — | view with dropdowns |
| store() | 60-75 | create | MarksheetScheduleRequest | Service::create() | redirect to scheduling.combined?tab=schedules |
| show() | 80-83 | view | $id (route) | — | view with record |
| edit() | 89-111 | update | $id | — | view with record + dropdowns |
| update() | 113-130 | update | MarksheetScheduleRequest, $id | Service::update() | redirect with flash |
| destroy() | 132-145 | delete | $id | Service::trash() | redirect with flash |
| review() | 150-155 | review | $id | LifecycleService::review() | redirect |
| publish() | 157-162 | publish | $id | LifecycleService::publish() | redirect |
| lock() | 164-169 | lock | $id | LifecycleService::lock() | redirect |
| unlock() | 171-176 | unlock | $id | LifecycleService::unlock() | redirect |
| precheck() | 229-250 | view | $id | — | view with precheck data |
| compute() | 178-227 | view | $id | LifecycleService::compute() | view or redirect |
| export() | 256-275 | export | $id | Excel facade | download |
| trashed() | 277-283 | viewAny | — | — | view with trashed records |
| restore() | 285-297 | update | $id | Service::restoreRecord() | redirect |
| forceDelete() | 299-313 | delete | $id | Service::forceDeleteRecord() | redirect |

### CODE-TRACE: MarksheetScheduleLifecycleService — State Transitions

| Method | Line | Pre-condition | Action | Post-condition |
|--------|------|---------------|--------|----------------|
| review() | Lifecycle:40-55 | status=COMPUTED, !is_locked | status=REVIEWED, is_reviewed=true | DomainException if invalid |
| publish() | Lifecycle:57-72 | status=REVIEWED, !is_locked | status=PUBLISHED, is_published=true | DomainException if invalid |
| lock() | Lifecycle:74-89 | status=PUBLISHED, !is_locked | is_locked=true, status=LOCKED | DomainException if invalid |
| unlock() | Lifecycle:91-106 | is_locked=true | is_locked=false, status=PUBLISHED | DomainException if invalid |
| compute() | Lifecycle:108-180 | !is_locked, no RUNNING log | Dispatches ComputeMarksheetJob | Error: "marksheet is locked" if locked |

## 6. Test Case List

### 6.1 Positive Test Cases (TC-P)

| ID | Test Case | Summary | Pre-condition | Steps | Expected Result |
|----|-----------|---------|---------------|-------|-----------------|
| TC-P-01 | Create schedule — DRAFT | Create a new marksheet schedule with valid data | User has create permission, valid template + session | store() via form | Record saved with status DRAFT, redirect to hub, activityLog 'Stored' |
| TC-P-02 | Create schedule — with unique code | Create schedule with unique code per session | No existing record with same code+session | store() | Success |
| TC-P-03 | View schedule details | Access show() for a schedule | Schedule exists, user has view permission | show() via route | Record loaded with 6+ relations, view rendered |
| TC-P-04 | Edit schedule | Access edit() for a DRAFT schedule | Schedule exists in DRAFT, user has update | edit() via route | Form with dropdowns, selectedClassSectionIds loaded |
| TC-P-05 | Update schedule | Update name/date of DRAFT schedule | Schedule in DRAFT, user has update | update() via PUT | Redirect, activityLog |
| TC-P-06 | Soft-delete DRAFT schedule | Delete a DRAFT schedule | Schedule in DRAFT, delete permission | destroy() via DELETE | Trashed, redirect |
| TC-P-07 | Compute DRAFT schedule | Compute DRAFT→COMPUTED | Schedule in DRAFT, not locked | compute() | Job dispatched, status→COMPUTED |
| TC-P-08 | Review COMPUTED schedule | Review COMPUTED→REVIEWED | Schedule in COMPUTED, review permission | review() via route | Status→REVIEWED, activityLog |
| TC-P-09 | Publish REVIEWED schedule | Publish REVIEWED→PUBLISHED | Schedule in REVIEWED, publish permission | publish() via route | Status→PUBLISHED, activityLog |
| TC-P-10 | Lock PUBLISHED schedule | Lock PUBLISHED→LOCKED | Schedule in PUBLISHED, lock permission | lock() via route | is_locked=true, status→LOCKED |
| TC-P-11 | Unlock LOCKED schedule | Unlock LOCKED→PUBLISHED | Schedule in LOCKED, unlock permission | unlock() via route | is_locked=false, status→PUBLISHED |
| TC-P-12 | Precheck schedule | Validate template + scores before compute | Schedule exists, view permission | precheck() via route | Precheck data rendered, validation results |
| TC-P-13 | Export schedule | Download marksheet as Excel | Schedule exists, export permission | export() via route | .xlsx file download |
| TC-P-14 | Restore trashed schedule | Restore from trash | Schedule trashed, update permission | restore() via GET | Restored, is_active=true, redirect |
| TC-P-15 | Force delete trashed schedule | Permanently delete | Schedule trashed, no FK refs | forceDelete() via DELETE | Record removed permanently |

### 6.2 Negative Test Cases (TC-N)

| ID | Test Case | Summary | Steps | Expected Error |
|----|-----------|---------|-------|----------------|
| TC-N-01 | Create — missing required code | Submit without code | Validation fails: "The code field is required." |
| TC-N-02 | Create — missing required name | Submit without name | Validation fails: "The name field is required." |
| TC-N-03 | Create — missing schedule_date | Submit without date | Validation fails: "The schedule date field is required." |
| TC-N-04 | Create — invalid config_template_id | Use non-existent template | Validation fails: exists rule |
| TC-N-05 | Create — invalid academic_session_id | Use non-existent session | Validation fails: exists rule |
| TC-N-06 | Create — invalid status_id | Use non-existent status | Validation fails: exists rule |
| TC-N-07 | Create — duplicate code same session | Same code as existing | Unique composite violation |
| TC-N-08 | Store — Gate 403 missing create | No create permission | 403 Forbidden |
| TC-N-09 | Update — Gate 403 missing update | No update permission | 403 Forbidden |
| TC-N-10 | Delete — Gate 403 missing delete | No delete permission | 403 Forbidden |
| TC-N-11 | Review — Gate 403 missing review | No review permission | 403 Forbidden |
| TC-N-12 | Review — wrong state (DRAFT) | Review DRAFT, not COMPUTED | DomainException: transition not allowed |
| TC-N-13 | Publish — wrong state (DRAFT) | Publish DRAFT, not REVIEWED | DomainException: transition not allowed |
| TC-N-14 | Lock — wrong state (DRAFT) | Lock DRAFT, not PUBLISHED | DomainException: transition not allowed |
| TC-N-15 | Unlock — not locked | Unlock PUBLISHED, not LOCKED | DomainException: not locked |
| TC-N-16 | Compute — locked schedule | Compute LOCKED schedule | Error: "marksheet is locked" |
| TC-N-17 | Compute — already running | Compute while ComputationLog has RUNNING | Error: "Computation already in progress" |
| TC-N-18 | Export — Gate 403 | No export permission | 403 Forbidden |
| TC-N-19 | Show — Gate 403 | No view permission | 403 Forbidden |
| TC-N-20 | Force delete — FK constraint | Schedule referenced by other records | 23000 catch → user-friendly error |
| TC-N-21 | Restore — Gate 403 | No update permission | 403 Forbidden |
| TC-N-22 | Force delete — Gate 403 | No delete permission | 403 Forbidden |

### 6.3 Security Test Cases (TC-SQ)

| ID | Test Case | Summary | Steps | Expected Result |
|----|-----------|---------|-------|-----------------|
| TC-SQ-01 | No viewAny → index redirect | User without viewAny accesses hub | 403 via Gate::any |
| TC-SQ-02 | No view → show | User without view accesses show() | 403 |
| TC-SQ-03 | No create → store | User without create submits store | 403 |
| TC-SQ-04 | No update → edit | User without update accesses edit | 403 |
| TC-SQ-05 | No delete → destroy | User without delete submits destroy | 403 |
| TC-SQ-06 | No review → review | User without review triggers review | 403 |
| TC-SQ-07 | No publish → publish | User without publish triggers publish | 403 |
| TC-SQ-08 | No lock → lock | User without lock triggers lock | 403 |
| TC-SQ-09 | No unlock → unlock | User without unlock triggers unlock | 403 |
| TC-SQ-10 | No export → export | User without export triggers export | 403 |
| TC-SQ-11 | SQL injection in code/search | Send malicious SQL in code | Escaped via Query Builder |
| TC-SQ-12 | XSS in name | Send `<script>alert(1)</script>` | Escaped via Blade {{ }} |

### 6.4 Integration Test Cases (TC-INT)

| ID | Test Case | Summary | Steps | Expected Result |
|----|-----------|---------|-------|-----------------|
| TC-INT-01 | Hub tab loads schedules | Navigate to scheduling.combined?tab=schedules | Schedules tab active, table loaded |
| TC-INT-02 | Pagination isolation | Navigate to sch_page=3, switch tabs | Tab switch resets to page 1 |
| TC-INT-03 | Schedule status badge rendering | Verify each schedule shows correct badge | DRAFT=secondary, COMPUTED=info, REVIEWED=warning, PUBLISHED=success, LOCKED=dark |
| TC-INT-04 | Lifecycle button visibility | Verify buttons shown based on state | Only valid transitions shown |
| TC-INT-05 | Combined compute → precheck flow | Compute triggers precheck validation | Precheck data validates template before compute |
| TC-INT-06 | Export from show page | Navigate to show → click export | Download triggers |
| TC-INT-07 | Class section pivot after schedule creation | Create schedule with sections | schedule_class_sections populated |
| TC-INT-08 | Activity log entries | Perform all lifecycle state transitions | Each transition logged with type+message |
| TC-INT-09 | ComputationLog workflow | Compute → check ComputationLog table | Log created with status=RUNNING→COMPLETED |
| TC-INT-10 | Marksheet generation after compute | After compute, check marksheets table | Marksheet records created per student |

### 6.5 Code Review Test Cases (TC-CR)

| ID | Test Case | Source Line | Expected |
|----|-----------|-------------|----------|
| TC-CR-01 | Gate in index() | Controller:36 | `tenant.msh-marksheet-schedule.viewAny` |
| TC-CR-02 | Gate in create() | Controller:47 | `tenant.msh-marksheet-schedule.create` |
| TC-CR-03 | Gate in store() | Controller:61 | `tenant.msh-marksheet-schedule.create` |
| TC-CR-04 | Gate in show() | Controller:81 | `tenant.msh-marksheet-schedule.view` |
| TC-CR-05 | Gate in edit() | Controller:90 | `tenant.msh-marksheet-schedule.update` |
| TC-CR-06 | Gate in update() | Controller:114 | `tenant.msh-marksheet-schedule.update` |
| TC-CR-07 | Gate in destroy() | Controller:133 | `tenant.msh-marksheet-schedule.delete` |
| TC-CR-08 | Gate in review() | Controller:151 | `tenant.msh-marksheet-schedule.review` |
| TC-CR-09 | Gate in publish() | Controller:158 | `tenant.msh-marksheet-schedule.publish` |
| TC-CR-10 | Gate in lock() | Controller:165 | `tenant.msh-marksheet-schedule.lock` |
| TC-CR-11 | Gate in unlock() | Controller:172 | `tenant.msh-marksheet-schedule.unlock` |
| TC-CR-12 | Gate in compute() | Controller:179 | `tenant.msh-marksheet-schedule.view` |
| TC-CR-13 | Gate in precheck() | Controller:230 | `tenant.msh-marksheet-schedule.view` |
| TC-CR-14 | Gate in export() | Controller:257 | `tenant.msh-marksheet-schedule.export` |
| TC-CR-15 | Gate in trashed() | Controller:279 | `tenant.msh-marksheet-schedule.viewAny` |
| TC-CR-16 | Gate in restore() | Controller:286 | `tenant.msh-marksheet-schedule.update` (not restore) |
| TC-CR-17 | Gate in forceDelete() | Controller:300 | `tenant.msh-marksheet-schedule.delete` (not forceDelete) |
| TC-CR-18 | activityLog in store() | Controller:68-70 | Type='Stored', message contains 'Marksheet schedule created' |
| TC-CR-19 | activityLog in update() | Controller:122-124 | Type='Updated', message contains 'updated' |
| TC-CR-20 | activityLog in destroy() | Controller:139 | Type='Deleted', message contains 'Marksheet schedule trashed' |
| TC-CR-21 | activityLog in review() | Controller:153 | Type='review' or 'Updated' |
| TC-CR-22 | activityLog in publish() | Controller:160 | Type='publish' or 'Updated' |
| TC-CR-23 | activityLog in lock() | Controller:167 | Type='lock' or 'Updated' |
| TC-CR-24 | activityLog in unlock() | Controller:174 | Type='unlock' or 'Updated' |
| TC-CR-25 | activityLog in restore() | Controller:292 | Type='Restored' |
| TC-CR-26 | activityLog in forceDelete() | Controller:307 | Type='forceDeleted' |
| TC-CR-27 | LifecycleService::review() validates state | Lifecycle:42 | Checks status===COMPUTED, throws DomainException |
| TC-CR-28 | LifecycleService::compute() check locked | Lifecycle:112 | Throws error if is_locked |
| TC-CR-29 | ComputeMarksheetJob dispatch | compute():218 | `dispatch(new ComputeMarksheetJob(...))` |
| TC-CR-30 | Export uses Maatwebsite\Excel | export():265 | `Maatwebsite\Excel\Facades\Excel::download()` |

## 7. Detailed Test Steps

### TC-P-01: Create schedule — DRAFT (Complete Steps)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-schedule.create` permission | Authenticated |
| 2 | Navigate to `marksheet-generation.scheduling.combined?tab=schedules` | Schedules tab visible |
| 3 | Click "Add Marksheet Schedule" button | Create form displayed |
| 4 | Fill **code** = "MS-2026-001" | Text input |
| 5 | Fill **name** = "Term 1 Marksheet 2026" | Text input |
| 6 | Fill **schedule_date** = "2026-07-15" | Date input |
| 7 | Select **config_template_id** = 3 (valid template) | Dropdown |
| 8 | Select **academic_session_id** = 5 (valid session) | Dropdown |
| 9 | Select **status_id** = "DRAFT" | Dropdown |
| 10 | Select **class sections** = [1, 2, 3] | Multi-select/pivot |
| 11 | Click Save | POST to store() |
| 12 | Verify Gate at line 61 passes | `authorize('tenant.msh-marksheet-schedule.create')` |
| 13 | Verify `$request->validated()` passes all rules | Validation OK |
| 14 | Verify Service::create() called with validated data | Records created |
| 15 | Verify DB: `msh_marksheet_schedules` has new record | code="MS-2026-001", status_id="DRAFT" |
| 16 | Verify pivot: `schedule_class_sections` has 3 entries | class_section_ids linked |
| 17 | Verify activityLog type='Stored' | "Marksheet schedule created." |
| 18 | Verify redirect to `scheduling.combined?tab=schedules` | Redirect OK |
| 19 | Verify flash('created.marksheet_schedule') displayed | Success message |

### TC-P-02: Create with unique code per session

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Create schedule with code="MS-2026-001" in session 5 | Success |
| 2 | Create schedule with code="MS-2026-001" in session 6 (different) | Success |
| 3 | Verify both records exist with same code in different sessions | Unique per session |

### TC-P-03: View schedule details

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Login with view permission | OK |
| 2 | GET route `marksheet-schedule.show(1)` | 200 |
| 3 | Verify findOrFail(1) returns record | Found |
| 4 | Verify 6+ relations loaded (configTemplate, academicSession, marksheets, etc.) | Eager loaded |
| 5 | Verify view rendered with compact('record') | Show page |
| 6 | Verify status badge matches schedule status | Badge correct |

### TC-P-04: Edit schedule

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Login with update permission | OK |
| 2 | GET edit(1) | 200 |
| 3 | Verify Gate at line 90 passes | Authorized |
| 4 | Verify dropdowns: configTemplates, academicSessions, statuses, classSections | Loaded |
| 5 | Verify selectedClassSectionIds loaded for pivots | |
| 6 | Verify form populated with existing values | old() + $record |

### TC-P-05: Update schedule

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | PUT marksheet-schedule.update(1) with new name | Update |
| 2 | Verify Gate line 114 passes | Authorized |
| 3 | Verify Service::update() with validated() | Transaction |
| 4 | Verify updated_by set | |
| 5 | Verify DB name changed | |
| 6 | Verify activityLog 'Updated' with changes tracked | Logged |
| 7 | Verify redirect with flash('updated.marksheet_schedule') | |

### TC-P-06: Soft-delete DRAFT

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in DRAFT state | Precondition |
| 2 | DELETE to marksheet-schedule.destroy(1) | Request |
| 3 | Verify Gate line 133 passes | Authorized |
| 4 | Verify Service::trash(1) called | |
| 5 | Verify DB deleted_at NOT NULL | Soft deleted |
| 6 | Verify activityLog 'Deleted' | Logged |
| 7 | Verify redirect with flash('trashed.marksheet_schedule') | |

### TC-P-07: Compute DRAFT → COMPUTED (State Transition)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DRAFT schedule with id=1, !is_locked | Precondition |
| 2 | Trigger compute() POST/GET | Request |
| 3 | Verify Gate at line 179 passes (`tenant.msh-marksheet-schedule.view`) | Authorized |
| 4 | Verify `$request->validate(['schedule_id' => 'required'])` passes | Valid input |
| 5 | Verify LifecycleService::compute() called | Service invoked |
| 6 | Verify schedule is NOT locked (Lifecycle:112) | `!$schedule->is_locked` |
| 7 | Verify no RUNNING ComputationLog exists (Lifecycle:120) | No conflict |
| 8 | Verify `ComputeMarksheetJob` dispatched at line 218 | `dispatch(new ComputeMarksheetJob(...))` |
| 9 | Verify ComputationLog created with status=RUNNING | Log entry |
| 10 | Verify response: view with "Computation initiated" message | Success view |
| 11 | (Async) Wait for job completion: status→COMPLETED | Job done |
| 12 | (Sync) Immediately: status→COMPUTED | Direct transition |
| 13 | Verify activityLog recorded for compute action | Optionally logged |

### TC-P-08: Review COMPUTED → REVIEWED

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in COMPUTED state | Precondition |
| 2 | POST to review(1) | Request |
| 3 | Gate line 151: `tenant.msh-marksheet-schedule.review` | Authorized |
| 4 | LifecycleService::review() validates status===COMPUTED | State matches |
| 5 | Status changed to REVIEWED | Updated |
| 6 | is_reviewed set to true | Flag set |
| 7 | activityLog recorded | Logged |
| 8 | Redirect back with flash | |

### TC-P-09: Publish REVIEWED → PUBLISHED

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in REVIEWED state | Precondition |
| 2 | POST to publish(1) | Request |
| 3 | Gate line 158: `tenant.msh-marksheet-schedule.publish` | Authorized |
| 4 | LifecycleService::publish() validates status===REVIEWED | State matches |
| 5 | Status changed to PUBLISHED | Updated |
| 6 | is_published set to true | Flag set |
| 7 | activityLog recorded | Logged |
| 8 | Redirect back with flash | |

### TC-P-10: Lock PUBLISHED → LOCKED

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in PUBLISHED state | Precondition |
| 2 | POST to lock(1) | Request |
| 3 | Gate line 165: `tenant.msh-marksheet-schedule.lock` | Authorized |
| 4 | LifecycleService::lock() validates status===PUBLISHED | State matches |
| 5 | is_locked set to true | Locked |
| 6 | Status changed to LOCKED | Updated |
| 7 | activityLog recorded | Logged |
| 8 | Redirect back with flash | |

### TC-P-11: Unlock LOCKED → PUBLISHED

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in LOCKED state, is_locked=true | Precondition |
| 2 | POST to unlock(1) | Request |
| 3 | Gate line 172: `tenant.msh-marksheet-schedule.unlock` | Authorized |
| 4 | LifecycleService::unlock() validates is_locked===true | State matches |
| 5 | is_locked set to false | Unlocked |
| 6 | Status changed to PUBLISHED | Reverted to PUBLISHED |
| 7 | activityLog recorded | Logged |
| 8 | Redirect back with flash | |

### TC-P-12: Precheck schedule

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule exists with template | Precondition |
| 2 | GET to precheck(1) | Request |
| 3 | Gate line 230: view permission | Authorized |
| 4 | Controller loads: marksheets, students, template, scores, attendance | Extensive relations |
| 5 | Precheck validates template has scores per student | Validation results |
| 6 | View rendered showing precheck status | Precheck page |

### TC-P-13: Export schedule

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule exists, export permission | Precondition |
| 2 | GET to export(1) | Request |
| 3 | Gate line 257: export permission | Authorized |
| 4 | Excel::download() invoked | |
| 5 | Response headers: Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet | Excel MIME |
| 6 | File downloaded with .xlsx extension | Download |

### TC-P-14: Restore trashed schedule

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in trash (deleted_at not null) | Precondition |
| 2 | GET restore(1) | Request |
| 3 | Gate line 286: update permission | Authorized |
| 4 | Service::restoreRecord() called | |
| 5 | DB: deleted_at = NULL | Restored |
| 6 | DB: is_active = true | Reactivated |
| 7 | activityLog 'Restored' recorded | Logged |
| 8 | Redirect to scheduling.combined?tab=schedules | |

### TC-P-15: Force delete

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule trashed, no FK references | Precondition |
| 2 | DELETE forceDelete(1) | Request |
| 3 | Gate line 300: delete permission | Authorized |
| 4 | Service::forceDeleteRecord() called | |
| 5 | DB: record removed | Gone |
| 6 | activityLog 'forceDeleted' | Logged |
| 7 | Redirect | Back to hub |

### TC-N-01: Missing code — required validation

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Submit store() without code | |
| 2 | Validation fails: code is required | Error message |
| 3 | No DB record created | |

### TC-N-02 through TC-N-06: Follow same pattern for each required/exists field.

### TC-N-07: Duplicate code same session

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Create schedule with code="DUPE" in session 5 | OK |
| 2 | Create second schedule with code="DUPE" in same session 5 | Validation error |
| 3 | Error: "The code has already been taken." | Unique violation |

### TC-N-08 through TC-N-11, TC-N-18, TC-N-19, TC-N-21, TC-N-22: Each is a 403 Gate::authorize test.

### TC-N-12: Review DRAFT (State Machine Violation)

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in DRAFT state | Precondition |
| 2 | POST to review() | Request |
| 3 | Gate passes (has review permission) | 200 |
| 4 | LifecycleService::review() checks status | status !== COMPUTED |
| 5 | DomainException thrown: "Cannot review schedule in DRAFT state" | Exception |
| 6 | Controller catch returns error message | Error displayed |
| 7 | Status unchanged (still DRAFT) | State preserved |

### TC-N-13: Publish DRAFT (State Machine Violation)

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in DRAFT status | Precondition |
| 2 | POST to publish() | Request |
| 3 | Gate passes (has publish permission) | 200 |
| 4 | LifecycleService::publish() checks status | status !== REVIEWED |
| 5 | DomainException: "Cannot publish schedule in DRAFT state" | Exception |
| 6 | Status unchanged | State preserved |

### TC-N-14: Lock DRAFT (State Machine Violation)

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in DRAFT | Precondition |
| 2 | POST to lock() | Request |
| 3 | Gate passes | 200 |
| 4 | LifecycleService::lock() checks status | status !== PUBLISHED |
| 5 | DomainException thrown | Exception |
| 6 | is_locked stays false | State preserved |

### TC-N-15: Unlock not locked

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in PUBLISHED (is_locked=false) | Precondition |
| 2 | POST to unlock() | Request |
| 3 | Gate passes | 200 |
| 4 | LifecycleService::unlock() checks is_locked | !is_locked |
| 5 | DomainException: "Schedule is not locked" | Exception |
| 6 | State unchanged | |

### TC-N-16: Compute locked schedule

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule in LOCKED state, is_locked=true | Precondition |
| 2 | POST to compute() | Request |
| 3 | Gate passes | 200 |
| 4 | Service checks is_locked at Lifecycle:112 | is_locked=true |
| 5 | Error: "marksheet is locked. cannot compute." | Error returned |
| 6 | No job dispatched, state unchanged | |

### TC-N-17: Compute while already running

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | ComputationLog exists with status=RUNNING for this schedule | Precondition |
| 2 | POST to compute() | Request |
| 3 | Gate passes | 200 |
| 4 | Service checks for RUNNING log at Lifecycle:120 | Found existing |
| 5 | Error: "Computation already in progress" | Error returned |
| 6 | No new job dispatched | |

### TC-N-20: Force delete — FK constraint

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule has related marksheet records | FK exists |
| 2 | forceDelete() triggered | |
| 3 | QueryException with code 23000 thrown | FK constraint |
| 4 | Catch block at Service (or Controller) | User-friendly error |
| 5 | Redirect back with error message | |
| 6 | Record NOT deleted | Preserved |

### TC-SQ-01 through TC-SQ-10: Each accesses a route without the required permission → 403 Forbidden.

### TC-SQ-11: SQL Injection — code field

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Submit create with code = "1'; DROP TABLE msh_marksheet_schedules;--" | |
| 2 | Query Builder parameterizes the value | Escaped, no injection |
| 3 | Record created with literal malicious code string | Data not valid but harmless |

### TC-SQ-12: XSS — name field

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Submit with name = "<script>alert('xss')</script>" | |
| 2 | Stored in DB with raw script | |
| 3 | View rendered with Blade {{ }} | Escaped, script not executed |

### TC-INT-01: Hub tab loads schedules

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Navigate to scheduling.combined?tab=schedules | Tab active |
| 2 | Verify schedules listed in table | Data visible |
| 3 | Verify eager load: configTemplate name shown | Relation loaded |
| 4 | Verify pagination: sch_page parameter | Pagination works |

### TC-INT-02: Pagination isolation

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Navigate to hub with ?tab=schedules&sch_page=3 | Page 3 |
| 2 | Switch to different tab (e.g., practical-configs) | Tab changes |
| 3 | Back to schedules tab | Page 1 (resets) |

### TC-INT-03: Status badge rendering

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule A: status_id=DRAFT | Badge: secondary/gray |
| 2 | Schedule B: status_id=COMPUTED | Badge: info/blue |
| 3 | Schedule C: status_id=REVIEWED | Badge: warning/yellow |
| 4 | Schedule D: status_id=PUBLISHED | Badge: success/green |
| 5 | Schedule E: status_id=LOCKED | Badge: dark/black |

### TC-INT-04: Lifecycle button visibility

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | DRAFT schedule: Only "Compute" button visible | Compute only |
| 2 | COMPUTED schedule: Only "Review" button visible | Review only |
| 3 | REVIEWED schedule: Only "Publish" button visible | Publish only |
| 4 | PUBLISHED schedule: Only "Lock" button visible | Lock only |
| 5 | LOCKED schedule: Only "Unlock" button visible | Unlock only |

### TC-INT-05: Compute → precheck flow

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Schedule has template with required scores | Precondition |
| 2 | Trigger compute() | Validation against template |
| 3 | Precheck validates all students have required scores | Complete |
| 4 | If precheck fails, compute not performed | Error displayed |
| 5 | If precheck passes, job dispatched | Compute proceeds |

### TC-INT-06: Export from show page

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Navigate to schedule show page | Details view |
| 2 | Click "Export" button | GET export(1) |
| 3 | File download initiated | .xlsx |

### TC-INT-07: Class section pivot after creation

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Create schedule with selected_class_section_ids=[10,20,30] | |
| 2 | After create, check `schedule_class_sections` table | 3 pivot rows |
| 3 | Each row: schedule_id=NEW, class_section_id=10/20/30 | Pivot populated |

### TC-INT-08: Activity log throughout lifecycle

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Create → activityLog('Stored') | Entry 1 |
| 2 | Update → activityLog('Updated') | Entry 2 |
| 3 | Compute → activityLog (possibly) | Entry 3 |
| 4 | Review → activityLog('review') or ('Updated') | Entry 4 |
| 5 | Publish → activityLog('publish') | Entry 5 |
| 6 | Lock → activityLog('lock') | Entry 6 |
| 7 | Unlock → activityLog('unlock') | Entry 7 |
| 8 | Soft-delete → activityLog('Deleted') | Entry 8 |
| 9 | Restore → activityLog('Restored') | Entry 9 |

### TC-INT-09: ComputationLog workflow

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | Compute schedule | |
| 2 | Check ComputationLog table | Log created with schedule_id |
| 3 | Log status = "RUNNING" | Initial state |
| 4 | Job executes | |
| 5 | Log status = "COMPLETED" or "FAILED" | Final state |
| 6 | Log has started_at and completed_at timestamps | Timestamps |

### TC-INT-10: Marksheet generation after compute

| Step # | Action | Expected |
|--------|--------|----------|
| 1 | After compute completes | |
| 2 | Check `msh_marksheets` table | Records created per student |
| 3 | Verify each marksheet references the schedule | schedule_id = schedule ID |
| 4 | Verify marksheet has scores per subject/component | Scores populated |

## 8. Observations & Gaps

| # | Observation | Severity | Details |
|---|-------------|----------|---------|
| OBS-01 | index() redirects to hub — no standalone listing | Info | index() redirects instead of rendering list; hub loads data independently |
| OBS-02 | restore() uses update permission instead of restore | Low | Gate::authorize('...update') rather than '...restore' |
| OBS-03 | forceDelete() uses delete permission instead of forceDelete | Low | Gate::authorize('...delete') rather than '...forceDelete' |
| OBS-04 | compute() and precheck() both use view permission | Info | These actions use view permission, not a dedicated compute permission |
| OBS-05 | Lifecycle state not enforced at Gate level | Low | All lifecycle methods have their own Gate permission but state enforcement is in service |
| OBS-06 | No performed_by key in activityLog calls | Low | Missing user attribution in audit trail |
| OBS-07 | Compute dispatches async job — no immediate status change | Info | Compute is async; state transition happens after job completes (not immediate) |
| OBS-08 | error vs return format may vary by service method | Medium | Some service methods return redirect, others throw, others return errors |
| OBS-09 | Export uses view permission for precheck? | Info | precheck() uses view permission — not a dedicated precheck permission |
| OBS-10 | State machine has no soft transition guard | Low | Can delete DRAFT but no software guard preventing delete of COMPUTED+ states |

## 9. Route Registration

| Route Name | Method | Controller Action | Permission Required |
|------------|--------|-------------------|---------------------|
| marksheet-schedule.index | GET | index() (redirect) | viewAny |
| marksheet-schedule.create | GET | create() | create |
| marksheet-schedule.store | POST | store() | create |
| marksheet-schedule.show | GET | show() | view |
| marksheet-schedule.edit | GET | edit() | update |
| marksheet-schedule.update | PUT/PATCH | update() | update |
| marksheet-schedule.destroy | DELETE | destroy() | delete |
| marksheet-schedule.review | POST | review() | review |
| marksheet-schedule.publish | POST | publish() | publish |
| marksheet-schedule.lock | POST | lock() | lock |
| marksheet-schedule.unlock | POST | unlock() | unlock |
| marksheet-schedule.precheck | GET | precheck() | view |
| marksheet-schedule.compute | POST | compute() | view |
| marksheet-schedule.export | GET | export() | export |
| marksheet-schedule.trashed | GET | trashed() | viewAny |
| marksheet-schedule.restore | GET | restore() | update |
| marksheet-schedule.forceDelete | DELETE | forceDelete() | delete |

## 10. Permissions Reference

From `config/permissionslist.php` — group name: `msh-marksheet-schedule`

| Permission Key | Used In | Purpose |
|----------------|---------|---------|
| `tenant.msh-marksheet-schedule.viewAny` | index(), trashed() | Listing access |
| `tenant.msh-marksheet-schedule.view` | show(), compute(), precheck() | View details, compute, precheck |
| `tenant.msh-marksheet-schedule.create` | create(), store() | Create new |
| `tenant.msh-marksheet-schedule.update` | edit(), update(), restore() | Edit, update, restore |
| `tenant.msh-marksheet-schedule.delete` | destroy(), forceDelete() | Soft-delete, force delete |
| `tenant.msh-marksheet-schedule.review` | review() | Review state transition |
| `tenant.msh-marksheet-schedule.publish` | publish() | Publish state transition |
| `tenant.msh-marksheet-schedule.lock` | lock() | Lock state transition |
| `tenant.msh-marksheet-schedule.unlock` | unlock() | Unlock state transition |
| `tenant.msh-marksheet-schedule.export` | export() | Excel download |

## 11. Test Coverage Summary

| Category | Count | Details |
|----------|-------|---------|
| TC-P (Positive) | 15 | All CRUD + lifecycle + export |
| TC-N (Negative) | 22 | Validation, 403, state machine, FK |
| TC-SQ (Security) | 12 | Permission + injection |
| TC-INT (Integration) | 10 | Hub, pagination, lifecycle, workflow |
| TC-CR (Code Review) | 30 | Gate + activityLog verification |
| **Total** | **89** | Full feature coverage |

## 12. Model & DB Configuration

| Property | Value |
|----------|-------|
| Table | `msh_marksheet_schedules` |
| Fillable | 18 columns |
| Casts | is_locked→bool, schedule_date→date, JSON fields |
| Soft Delete | `use SoftDeletes` trait |
| Relationships | 10: configTemplate, academicSession, marksheets, computationLogs, createdBy, updatedBy, deletedBy, marksheetScores, classSections (belongsToMany), scheduleClassSections (hasMany) |
| Pivot Table | `schedule_class_sections` (schedule_id, class_section_id) |

## 13. Form Request Validation Details

### MarksheetScheduleRequest Validation Rules

| Field | Create Rule | Update Rule | Message Override |
|-------|-------------|-------------|------------------|
| code | required, string, max:255, unique:msh_marksheet_schedules | sometimes, string, max:255, unique:msh_marksheet_schedules,...id | — |
| name | required, string, max:255 | sometimes, string, max:255 | — |
| schedule_date | required, date | sometimes, date | — |
| status_id | required, string, max:50, exists:sys_dropdowns,key | sometimes, string, max:50, exists:sys_dropdowns,key | — |
| config_template_id | required, integer, exists:msh_config_templates,id | sometimes, integer, exists:msh_config_templates,id | — |
| academic_session_id | required, integer, exists:sch_org_academic_sessions_jnt,id | sometimes, integer, exists:sch_org_academic_sessions_jnt,id | — |
| selected_class_section_ids | required, array | sometimes, array | — |
| selected_class_section_ids.* | integer, exists:sch_class_sections,id | integer, exists:sch_class_sections,id | — |
| is_locked | boolean | boolean | — |

### UnlockMarksheetScheduleRequest Validation Rules

| Field | Rule | Purpose |
|-------|------|---------|
| reason | required, string, max:500 | Unlock reason for audit trail |

### prepareForValidation() Logic

The request casts `config_template_id` and `academic_session_id` to integers before validation:

## 14. LifecycleService CODE-TRACE (State Machine Engine)

### MarksheetScheduleLifecycleService — Detailed Trace

## 15. ComputeMarksheetJob Trace

| Step | Operation | Description |
|------|-----------|-------------|
| 1 | `handle()` called | Queue worker picks up job |
| 2 | Load schedule | `MarksheetSchedule::findOrFail($this->scheduleId)` |
| 3 | Load template | `$schedule->configTemplate` — get scoring rules |
| 4 | Load enrolled students | Via `$schedule->academicSession->enrollments()` |
| 5 | Compute per student | Loop: calculate theory + practical + total marks per subject |
| 6 | Create/update Marksheet records | `Marksheet::updateOrCreate([...])` |
| 7 | Update ComputationLog | status='COMPLETED', completed_at=now() |
| 8 | Update schedule status | status='COMPUTED' |
| 9 | activityLog 'Computed' | Log completion |

## 16. Test Environment Requirements

| # | Requirement | Details |
|---|-------------|---------|
| TE-01 | Laravel PHP Framework | Version 10.x+ with Gate authorization |
| TE-02 | Database | MySQL 8.0+ with InnoDB engine |
| TE-03 | Queue driver | sync (testing) or Redis/DB (production) |
| TE-04 | Permissions config | `permissionslist.php` with `msh-marksheet-schedule` entry (10 actions) |
| TE-05 | Reference data | Config templates, academic sessions, dropdowns must exist |
| TE-06 | Activity log table | `activity_log` table operational |
| TE-07 | Soft deletes | `deleted_at` column on `msh_marksheet_schedules` |
| TE-08 | ComputationLog table | Must exist for tracking compute jobs |
| TE-09 | Schedule class sections pivot | `schedule_class_sections` table |
| TE-10 | Excel export | `maatwebsite/excel` package installed |

## 17. Test Execution Notes

| # | Note | Details |
|---|------|---------|
| TN-01 | Sequential lifecycle | TC-P-07 through TC-P-11 must be executed in order (state machine) |
| TN-02 | Async compute | TC-P-07 requires queue worker if using production queue |
| TN-03 | FK cascade | delete may cascade to marksheets — verify cascade behavior |
| TN-04 | Permission granularity | Each lifecycle action has its own permission key (review/publish/lock/unlock/export) |
| TN-05 | Form Request difference | Unlock has special request with `reason` field |
| TN-06 | Composite unique | code + academic_session_id unique enforced at validation + DB index level |
| TN-07 | State machine guards | All state transitions validated in LifecycleService via DomainException |
| TN-08 | ActivityLog verification | Every positive TC should verify activityLog was called with correct type |

## 18. State Machine Test Coverage Matrix

| From \ To | DRAFT | COMPUTED | REVIEWED | PUBLISHED | LOCKED | DELETED |
|-----------|-------|----------|----------|-----------|--------|---------|
| DRAFT | — | ✅ TC-P-07 | ❌ TC-N-12 | ❌ | ❌ | ✅ TC-P-06 |
| COMPUTED | ❌ | — | ✅ TC-P-08 | ❌ TC-N-13 | ❌ | ❌ |
| REVIEWED | ❌ | ❌ | — | ✅ TC-P-09 | ❌ | ❌ |
| PUBLISHED | ❌ | ❌ | ❌ | — | ✅ TC-P-10 | ❌ |
| LOCKED | ❌ | ❌ | ❌ | ✅ TC-P-11 | — | ❌ |

## 19. Quick Reference — Key File Locations

| Artifact | Path |
|----------|------|
| Controller | `Modules/MarksheetGeneration/Http/Controllers/MarksheetScheduleController.php` |
| Model | `Modules/MarksheetGeneration/Models/MarksheetSchedule.php` |
| Form Request (Main) | `Modules/MarksheetGeneration/Http/Requests/MarksheetScheduleRequest.php` |
| Form Request (Unlock) | `Modules/MarksheetGeneration/Http/Requests/UnlockMarksheetScheduleRequest.php` |
| CRUD Service | `Modules/MarksheetGeneration/Services/MarksheetScheduleService.php` |
| Lifecycle Service | `Modules/MarksheetGeneration/Services/MarksheetScheduleLifecycleService.php` |
| Compute Job | `Modules/MarksheetGeneration/Jobs/ComputeMarksheetJob.php` |
| Routes | `Modules/MarksheetGeneration/routes/web.php` |
| Permissions | `config/permissionslist.php` |
| Migration | `database/migrations/*_create_msh_marksheet_schedules_table.php` |
