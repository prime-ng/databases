# TimetableFoundation (TTF) — Complete Analysis Pack
**Module:** TimetableFoundation | **Code:** TTF | **Prefix:** `tt_*` | **DB:** Tenant
**Date:** 2026-06-30 | **Agent:** Business Analyst (pa-business-analyst)
**FRD:** `TTF_FRD_2026-06-30.md` (same folder) — all REQ-/BR-/RPT-/ENH- IDs are defined there and referenced here

---

## Table of Contents

1. [Link to FRD + Module Identity](#1-module-identity--frd-link)
2. [Requirements Traceability Matrix (RTM)](#2-requirements-traceability-matrix)
3. [Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog](#3-business-rules--conditions--validation)
4. [Process Flows + FSM Catalog](#4-process-flows--state-machine-catalog)
5. [Data Dictionary + Cross-Module Dependency Map](#5-data-dictionary--dependency-map)
6. [NFR Catalog + Risk Register](#6-nfr-catalog--risk-register)
7. [Prioritization + Effort Estimation & Sprint Tasks](#7-prioritization--effort-estimation)
8. [User Stories + Acceptance Criteria + Reporting & KPI Spec](#8-user-stories--reporting--kpi-spec)
9. [Feature Specification — Screen-by-Screen](#9-feature-specification)
10. [Requirements-vs-Code Gap Analysis](#10-requirements-vs-code-gap-analysis)

---

## 1. Module Identity & FRD Link

**Module:** TimetableFoundation
**Module Code:** TTF
**Table Prefix:** `tt_*` (shared with SmartTimetable and StandardTimetable — TTF owns migrations)
**DB Layer:** Tenant (`tenant_mysql` — per-school isolated database)
**Laravel Path:** `Modules/TimetableFoundation/`
**Route Prefix:** `/timetable-foundation/*` | **Route Name Prefix:** `timetable-foundation.*`
**FRD:** `TTF_FRD_2026-06-30.md` — canonical source for all REQ-/BR-/RPT-/ENH- IDs

### Module Role in Timetable Architecture

```
SmartTimetable (AI Generation Engine)     StandardTimetable (Manual Placement Views)
              |                                          |
              +--------------------+---------------------+
                                   |
                   TimetableFoundation (TTF)
                   "All data the scheduler needs to exist"
                                   |
              +--------------------+---------------------+
              |                    |                     |
         SchoolSetup          StaffProfile         GlobalMaster
      (Classes, Subjects,   (Teacher Profiles)   (Academic Sessions)
        Rooms, Buildings)
```

TTF is the mandatory prerequisite — SmartTimetable and StandardTimetable cannot function without TTF's `tt_*` tables containing valid data. TTF does not generate or display timetables; it provides the input data contract.

### Filesystem Counts (Verified 2026-06-30)

| Component | Count | Notes |
|-----------|-------|-------|
| Controllers | 26 | Includes 2 post-V2 additions: PriorityConfigController, SubActivityDetailController |
| Models | 33–34 | 33 confirmed files; V1 spec lists 34 (SubActivityDetail model may be included) |
| FormRequests | 4 | AcademicTermRequest, ConfigRequest, SchoolTimingProfileRequest, TimingProfileRequest |
| Policies | 23 | 5 registered, ~18 unregistered (dead code) |
| Services | 4 | AnalyticsService, RoomAvailabilityService, SubActivityService, PriorityConfigService |
| Views (Blade) | 172 | All 7 menu pages covered |
| Route Lines | 316 | Largest route file in project; cross-module imports present |
| Tests | 7 files | 1 Feature + 5 Unit + Pest.php config |
| Seeders | 1 | |
| Events | 1 | SpecialDayAssigned |
| Console Commands | 1 | BackfillSubActivityDetails |
| Exports | 2 | SheetExport, TimetableRequirementExport |

---

## 2. Requirements Traceability Matrix

> REQ- and BR- IDs defined in FRD §3 and §4. Code status assessed from module knowledge (2026-06-30) and V2 requirement.

| REQ ID | Feature | Priority | BR Refs | Screen(s) | Workflow(s) | Report(s) | Code Status | Gap Summary |
|--------|---------|---------|---------|-----------|-------------|-----------|-------------|-------------|
| REQ-TTF-001 | Pre-Requisites Setup Dashboard | P0 | — | Page 1 | WF-1 Step 1 | — | Done (read-only display works) | Empty-state handling unverified |
| REQ-TTF-002 | Timetable Configuration | P0 | BR-TTF-011 | Page 2 Tab 1 | WF-1 Step 2 | — | Partial (70%) | scopeByStatus() bug; no caching; ConfigRequest partial |
| REQ-TTF-003 | Academic Term Management | P0 | BR-TTF-005, BR-TTF-015 | Page 2 Tab 2 | WF-1 Step 2 | — | Partial (75%) | Date overlap check missing |
| REQ-TTF-004 | Generation Strategy Management | P0 | BR-TTF-012 | Page 2 Tab 3 | WF-1 Step 2 | — | Partial (85%) | Cross-module controller coupling |
| REQ-TTF-005 | School Shift Management | P0 | BR-TTF-014 | Page 3 Tab 1 | WF-1 Step 3 | — | Done (90%) | FormRequest missing; user-friendly duplicate error unverified |
| REQ-TTF-006 | Day Type Management | P0 | BR-TTF-015 | Page 3 Tab 2 | WF-1 Step 3 | — | Done (90%) | FormRequest missing |
| REQ-TTF-007 | Period Type Management | P0 | — | Page 3 Tab 3 | WF-1 Step 3 | — | Done (90%) | FormRequest missing |
| REQ-TTF-008 | Period Set Management | P0 | BR-TTF-001, BR-TTF-003, BR-TTF-009 | Page 3 Tabs 7-8 | WF-1 Step 3 | — | Partial (85%) | GENERATED column risk; PeriodSlotRequest with cross-field rule missing |
| REQ-TTF-009 | Working Day Calendar | P0 | BR-TTF-015 | Page 3 Tabs 5-6 | WF-1 Step 3, WF-2 | — | Partial (80%) | Term counter auto-update observer missing |
| REQ-TTF-010 | Timetable Type & Class Assignment | P0 | BR-TTF-002, BR-TTF-004 | Page 3 Tabs 9-10 | WF-1 Step 3 | — | Partial (80%) | Time overlap check missing; class-timetable period-set overlap check missing |
| REQ-TTF-011 | Slot Requirement | P0 | — | Page 4 Tab 1 | WF-1 Step 4 | RPT-TTF-005 | Partial (65%) | Generate flow exists; completeness uncertain |
| REQ-TTF-012 | Requirement Groups & Subgroups | P1 | — | Page 4 Tabs 2-3 | WF-1 Step 4 | — | Partial (60%) | AJAX toggle present; full CRUD completeness uncertain |
| REQ-TTF-013 | Requirement Consolidation | P0 | BR-TTF-013 | Page 4 Tab 4 | WF-1 Step 4, WF-3 | RPT-TTF-005 | Partial (70%) | FormRequest missing; regeneration behaviour unverified |
| REQ-TTF-014 | Teacher Availability | P0 | BR-TTF-007, BR-TTF-008, BR-TTF-010 | Page 5 Tabs 1-2 | WF-1 Step 5, WF-5 | RPT-TTF-004 | Partial (70%) | Model typo (TeacherAvailablity); GENERATED cols risk; FormRequest missing |
| REQ-TTF-015 | Room Availability | P1 | — | Page 5 Tab 3 | WF-1 Step 5 | RPT-TTF-003 | Partial (65%) | Detail matrix completeness uncertain; FormRequest missing |
| REQ-TTF-016 | Activity Management | P0 | BR-TTF-006, BR-TTF-015 | Page 6 Tabs 1-3 | WF-1 Step 6, WF-4 | — | Partial (75%) | FormRequest missing; rate limiting missing; no notification on batch complete |
| REQ-TTF-017 | Teacher Assignment Role Master | P1 | — | Page 3 Tab 4 | — | — | Done (90%) | FormRequest missing |
| REQ-TTF-018 | Timetable Master Records | P1 | — | (internal) | — | RPT-TTF-001 | Partial (75%) | Published→Archive auto-transition missing |
| REQ-TTF-019 | Timing Profile Management | P1 | — | Page 3 (Timing) | — | — | Partial (60%) | SchoolShift alias workaround; dedicated models missing |
| REQ-TTF-020 | Reports and Analytics Page | P1 | — | Page 7 | — | RPT-TTF-001 to RPT-TTF-004 | Partial (60%) | Reads STT analytics; completeness unknown |
| REQ-TTF-021 | Constraint Type Catalog Viewer | P2 | — | (proposed) | — | — | Not Started (0%) | No controller; table seeded by STT |
| REQ-TTF-022 | Temporary Resource Unavailability | P2 | — | (proposed) | — | — | Not Started (0%) | Tables exist; no controllers |

**RTM Totals reconciliation:** 22 REQs × 15 BRs × 5 RPTs × 4 ENHs — matches FRD §10.4.

---

## 3. Business Rules, Conditions, and Validation

### 3.1 Business Rules Register (from FRD §4)

> Full BR definitions in FRD §4. This register adds enforcement details.

| BR ID | Business Rule (business language) | Type | Trigger | Current Enforcement | Gap |
|-------|----------------------------------|------|---------|---------------------|-----|
| BR-TTF-001 | A period slot's end time must be later than its start time | Validation | Create/Edit Period Slot | DB CHECK constraint `chk_psp_time` | FormRequest cross-field rule missing |
| BR-TTF-002 | For a given shift, no two timetable types may run at overlapping school times | Validation | Create/Edit Timetable Type | None | Full application-level check missing |
| BR-TTF-003 | Period Duration is database-computed — must never be written by the application | Calculation | Any period slot write | MySQL GENERATED STORED | `duration_minutes` may still be in $fillable — audit needed |
| BR-TTF-004 | "Applies to All Sections" and "Specific Section" are mutually exclusive on a Class-Timetable-Type record | Validation | Create/Edit Class-Timetable-Type | DB CHECK `chk_cttj_apply_to_all_section` | FormRequest conditional validation missing |
| BR-TTF-005 | Academic terms within the same session must have non-overlapping date ranges | Validation | Create/Edit Academic Term | None | Application-level date overlap check missing |
| BR-TTF-006 | One activity per class-section-subject-study-format per academic term | Validation | Generate Activities / Create Activity | None explicit | Application-level uniqueness check partially implemented |
| BR-TTF-007 | "Available for Full Timetable Duration" is database-computed — must never be written | Calculation | Any teacher availability write | MySQL GENERATED STORED | May appear in $fillable — audit needed |
| BR-TTF-008 | "Days Not Available" count is database-computed — must never be written | Calculation | Any teacher availability write | MySQL GENERATED STORED | May appear in $fillable — audit needed |
| BR-TTF-009 | Only one Period Set may be the default at any time | Validation | Toggle Period Set default | Controller toggle logic | Single-default enforcement unverified |
| BR-TTF-010 | Each teacher-day-period slot combination must be unique; duplicate inserts produce a user-readable error | Validation | Save Teacher Availability Detail | DB UNIQUE key on (teacher_profile_id, day_number, period_number) | Graceful duplicate-key error handling not verified |
| BR-TTF-011 | Configuration keys with "System Managed" flag cannot be edited by the school | Permission | Inline config edit | Gate check + UI (partial) | Consistent enforcement unverified |
| BR-TTF-012 | Only one Generation Strategy may be the default at a time | Validation | Toggle Generation Strategy default | Controller toggle logic | Implemented |
| BR-TTF-013 | No duplicate Requirement Consolidation record per class-section-subject-format-term | Validation | Generate Requirements | Application-level dedup on generation | Partial; regeneration replace-vs-duplicate behaviour unverified |
| BR-TTF-014 | Shift code, name, and ordinal are each unique; violations produce a user-readable error (not a raw database error) | Validation | Create/Edit Shift | DB UNIQUE keys | User-friendly error handler unverified |
| BR-TTF-015 | When a Working Day's Day Type changes, the parent Academic Term's teaching/exam/working day counters must be updated | Workflow | AJAX edit Working Day | Observer on WorkingDay model | Observer not implemented |

### 3.2 Requirement Conditions Catalog

> This catalog is the canonical source for `5-Requirement_Conditions/TTF_Conditions.md`. BR IDs from Section 3.1.

| Condition ID | Entity / Field | Condition (business language) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-TTF-001 | Period Slot / End Time | End Time must be later than Start Time | Validation | Store/Update Period Slot | Reject with message "End time must be after start time" |
| BR-TTF-002 | Timetable Type / School Times | School start/end times for same Shift must not overlap with another Timetable Type | Validation | Store/Update Timetable Type | Reject with message "Times overlap with [name]" |
| BR-TTF-003 | Period Slot / Period Duration | Period Duration is database-computed; application must never write this field | Calculation | Eloquent save on PeriodSetPeriod | MySQL silently ignores (or throws); field must be absent from $fillable |
| BR-TTF-004a | Class-Timetable-Type / applies_to_all_sections | If "Applies to All Sections" is true, no section may be selected | Validation | Store/Update Class-Timetable-Type | Reject with message "Select either all sections or a specific section" |
| BR-TTF-004b | Class-Timetable-Type / section_id | If a specific section is selected, "Applies to All Sections" must be false | Validation | Store/Update Class-Timetable-Type | Same as above |
| BR-TTF-005 | Academic Term / Date Range | Terms within the same academic session must not have overlapping start/end dates | Validation | Store/Update Academic Term | Reject with message "Term dates overlap with [Term Name] ([date range])" |
| BR-TTF-006 | Activity | One activity per class-section-subject-study-format combination per academic term | Validation | Store Activity / Generate Activities | Reject or skip duplicate; log skipped items |
| BR-TTF-007 | Teacher Availability / available_for_full_timetable_duration | Database-computed field; application must never write this | Calculation | Eloquent save on TeacherAvailability | MySQL silently ignores; field must be absent from $fillable |
| BR-TTF-008 | Teacher Availability / no_of_days_not_available | Database-computed field; application must never write this | Calculation | Eloquent save on TeacherAvailability | MySQL silently ignores; field must be absent from $fillable |
| BR-TTF-009 | Period Set / is_default | Only one Period Set may carry the default flag | Validation | Toggle Period Set default | Clear the previous default before setting the new one |
| BR-TTF-010 | Teacher Availability Detail / slot key | (teacher_profile_id, day_number, period_number) must be unique | Validation | Store Teacher Availability Detail | Catch DB unique violation; return "Slot already configured — update instead of creating" |
| BR-TTF-011a | Timetable Config / tenant_can_modify | System-managed config keys (tenant_can_modify = false) cannot be updated by school users | Permission | Inline config edit | Reject with 403 Forbidden |
| BR-TTF-012 | Generation Strategy / is_default | Only one generation strategy may be the default | Validation | Toggle Generation Strategy default | Unset current default then set new one in a single transaction |
| BR-TTF-013 | Requirement Consolidation / uniqueness | No duplicate consolidation record per class-section-subject-format-term | Validation | Generate Requirements | Skip duplicates; log count of skipped records in response |
| BR-TTF-014a | Shift / code | Shift code must be unique across the school | Validation | Store/Update Shift | Catch DB unique violation; return "Shift code already exists" |
| BR-TTF-014b | Shift / name | Shift name must be unique across the school | Validation | Store/Update Shift | Catch DB unique violation; return "Shift name already exists" |
| BR-TTF-014c | Shift / ordinal | Shift display order must be unique | Validation | Store/Update Shift | Catch DB unique violation; return "Display order already in use" |
| BR-TTF-015 | Working Day / day_type_id | When Day Type changes, Academic Term teaching/exam/working day counters must be recalculated | Workflow | AJAX edit Working Day | Observer fires; term counters updated atomically; gap — not yet implemented |

### 3.3 Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Period Slot End Time | 08:45 (after 08:00 start) | 08:00 (same as start) | 1 minute after start | Null end time | Two users saving simultaneously | DB CHECK blocks; return user-readable error |
| Academic Term Dates | Q1: Apr–Jun, Q2: Jul–Sep (no overlap) | Q1: Apr–Sep, Q2: Jul–Dec (overlap) | Terms touching (last day of T1 = first day of T2) | Null end date | Two users creating overlapping terms | Application-level overlap check blocks |
| duration_minutes (GENERATED) | Not in form — computed automatically | User sending duration_minutes in POST body | N/A | Always computed | N/A | Column ignored by MySQL if sent; must be absent from $fillable to prevent Eloquent error |
| Shift Code | "MORNING" | "MORNING" (duplicate) | Single-character code | Empty string | Two users creating same code | DB UNIQUE key raises 1062; controller catches and returns user-friendly error |
| Teacher Availability Slot | Toggle slot to Unavailable | Duplicate insert of same slot | First-period slot (period_number=1) | teacher_profile_id null | Two users toggling same slot | DB UNIQUE key handles; first write wins; second write is an update |
| Class-Timetable-Type: applies_to_all_sections | applies_to_all_sections=1, section_id=NULL | applies_to_all_sections=1, section_id=42 | applies_to_all_sections=0, section_id=NULL | section_id NULL with applies=false | — | DB CHECK `chk_cttj_apply_to_all_section` blocks; FormRequest (missing) should also check |
| available_for_full_timetable_duration (GENERATED) | Not in form — computed by DB | Sending this field in POST body | N/A | Always computed | N/A | Must be absent from $fillable |
| no_of_days_not_available (GENERATED) | Not in form — computed by DB | Sending in POST body | N/A | Always computed | N/A | Must be absent from $fillable |
| Generation Strategy: is_default toggle | Single default strategy | Two strategies both is_default=1 | No strategies is_default=1 | — | Two admins toggling default simultaneously | Controller must toggle in a single atomic transaction (UPDATE ... WHERE is_default=1 → set to 0, then set new one) |
| Requirement Consolidation: uniqueness | One record per class-section-subject-format | Clicking "Generate Requirements" twice without clearing | Same class-subject in two sections | class_id null | Two users running generate simultaneously | Application must detect existing records and skip/replace; avoid duplicates |

---

## 4. Process Flows and State Machine Catalog

> Full workflow narratives in FRD §6. This section adds FSM detail and exception swim-lanes.

### 4.1 Summary of Workflows

| Workflow | Trigger | Key States / End State |
|----------|---------|----------------------|
| WF-1: Six-Step Pre-Generation Setup | Annual timetable preparation begins | Steps 1–6 complete; Activities in DRAFT |
| WF-2: Working Day Calendar Init & Edit | Timetable Manager opens Working Days tab | All session dates have Working Day records |
| WF-3: Requirement Consolidation Generation | Timetable Manager clicks Generate Requirements | Consolidation records created for term |
| WF-4: Activity Batch Generation | Timetable Manager clicks Generate All Activities | Activities in DRAFT; teacher assignment pending |
| WF-5: Teacher Availability Setup | Post-activity-generation on Page 5 | Each teacher has an availability record; slot matrix complete |

### 4.2 State Machine — Timetable Record Status

**Entity:** Timetable Master Record (`tt_timetables`)
**States:** DRAFT → GENERATED → PUBLISHED → ARCHIVED

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|---|---|---|---|---|
| (none) | SmartTimetable creates timetable header | Valid academic_term_id and timetable_type_id | DRAFT | Timetable record created with generation_run_id |
| DRAFT | SmartTimetable generation run completes successfully | At least one timetable cell exists | GENERATED | tt_timetable_cells populated |
| GENERATED | Timetable Manager reviews and publishes | No validation errors in cell grid | PUBLISHED | Previous PUBLISHED timetable for same term-type auto-archived |
| PUBLISHED | Newer timetable for same term-type is published | Another timetable transitions to PUBLISHED | ARCHIVED | Status set to ARCHIVED; record preserved read-only |
| GENERATED | Timetable Manager discards generated timetable | — | DRAFT | Cells cleared; re-generation available |
| ARCHIVED | — | Cannot be restored to PUBLISHED | ARCHIVED (terminal) | Read-only; accessible in Reports |

**Illegal transitions:**
- ARCHIVED → PUBLISHED (blocked; re-run generation for a new timetable)
- PUBLISHED → GENERATED (blocked; publish is a one-way gate)

### 4.3 State Machine — Activity Status

**Entity:** Activity (`tt_activities`)
**States:** DRAFT → ACTIVE → ARCHIVED

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Generate Activities / manual create | Valid class-section-subject-term | DRAFT | Activity record created; awaiting teacher assignment |
| DRAFT | Teacher(s) assigned; Timetable Manager confirms | At least one teacher assigned | ACTIVE | Activity ready for SmartTimetable solver |
| ACTIVE | Academic term ends / Activity removed from schedule | — | ARCHIVED | Removed from active solver input |
| DRAFT | Timetable Manager deletes activity | No timetable cell references | Deleted | Cascade deletes sub-activities and activity-teacher assignments |

### 4.4 State Machine — Teacher Availability Slot

**Entity:** Teacher Availability Detail slot
**States:** Available → Unavailable (togglable; no formal status field — managed by `can_be_assigned` boolean and `availability_for_period` ENUM)

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| Available | Timetable Manager toggles slot off | Valid teacher-day-period combination | Unavailable | Audit log entry created (old=Available, new=Unavailable) |
| Unavailable | Timetable Manager toggles slot on | Valid teacher-day-period combination | Available | Audit log entry created |
| (none) | Generate Teacher Availability fires | Teacher in Requirement Consolidation | Available (default) | Default record created; all slots set Available |

---

## 5. Data Dictionary and Dependency Map

### 5.1 Data Dictionary — Business View

**Entity Group 1: School Timetable Master Data**

| Business Field | Entity | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|---|
| Shift Code | School Shift | Unique identifier for a shift | Text | Yes | e.g., MORNING, AFTERNOON | No |
| Shift Name | School Shift | Display name | Text | Yes | Unique per school | No |
| Shift Display Order | School Shift | Sequence for UI ordering | Number | Yes | Unique per school | No |
| Shift Default Start | School Shift | Default opening time | Time | Yes | HH:MM format | No |
| Shift Default End | School Shift | Default closing time | Time | Yes | HH:MM format | No |
| Day Type Code | Day Type | Unique identifier | Text | Yes | STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY | No |
| Is Working Day | Day Type | Whether periods run on this day type | Boolean | Yes | Yes/No | No |
| Has Reduced Periods | Day Type | Whether fewer periods than normal run | Boolean | Yes | Yes/No | No |
| Period Type Code | Period Type | Unique identifier | Text | Yes | THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE | No |
| Is Schedulable | Period Type | Whether subjects can be placed in this slot | Boolean | Yes | Yes/No | No |
| Counts as Teaching | Period Type | Whether this slot counts toward teaching time | Boolean | Yes | Yes/No | No |
| Counts as Workload | Period Type | Whether this slot counts toward teacher load | Boolean | Yes | Yes/No | No |
| Colour Code | Period Type | Display colour for calendar grids | Text | No | Hex colour (#RRGGBB) | No |

**Entity Group 2: Period Schedule**

| Business Field | Entity | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|---|
| Period Set Code | Period Set | Unique schedule name | Text | Yes | e.g., STANDARD_8P, HALF_DAY_4P | No |
| Total Periods | Period Set | Count of all period slots | Number | Yes | Integer ≥ 1 | No |
| Teaching Periods | Period Set | Count of schedulable teaching slots | Number | Yes | ≤ Total Periods | No |
| Day Start Time | Period Set | First bell time | Time | Yes | HH:MM | No |
| Day End Time | Period Set | Last bell time | Time | Yes | After Day Start Time | No |
| Is Default | Period Set | Whether this is the default schedule | Boolean | Yes | Only one may be Yes | No |
| Slot Position | Period Slot | Ordered sequence number within the set | Number | Yes | Unique per period set | No |
| Slot Start Time | Period Slot | Period begins | Time | Yes | HH:MM | No |
| Slot End Time | Period Slot | Period ends | Time | Yes | Must be after Start Time | No |
| Period Duration | Period Slot | Length in minutes (computed) | Number | Computed | Computed: end − start | No |
| Slot Period Type | Period Slot | Nature of this slot | Reference | Yes | Links to Period Type | No |

**Entity Group 3: Academic Term and Calendar**

| Business Field | Entity | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|---|
| Term Type | Academic Term | Academic subdivision type | Dropdown | Yes | Quarter, Semester, Annual, Trimester | No |
| Term Start Date | Academic Term | First day of term | Date | Yes | Within academic session | No |
| Term End Date | Academic Term | Last day of term | Date | Yes | After start date; no overlap with another term | No |
| Total Teaching Days | Academic Term | Sum of working days typed Study | Number | Computed | Auto-updated by Working Day observer | No |
| Total Exam Days | Academic Term | Sum of working days typed Exam | Number | Computed | Auto-updated | No |
| Total Working Days | Academic Term | Total school-operational days | Number | Computed | Auto-updated | No |
| Calendar Date | Working Day | The calendar date | Date | Yes | Within academic session; unique | No |
| Day Type 1-4 | Working Day | Up to four simultaneous day types | Reference | Yes (≥1) | Links to Day Type | No |
| Is School Day | Working Day | Whether school is open on this date | Boolean | Yes | Derived from Day Type `is_working_day` | No |

**Entity Group 4: Timetable Types and Assignment**

| Business Field | Entity | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|---|
| Timetable Type Code | Timetable Type | Unique identifier | Text | Yes | STANDARD, UNIT_TEST-1, HALF_DAY, HALF_YEARLY, FINAL_EXAM | No |
| Linked Shift | Timetable Type | Which shift this type operates in | Reference | Yes | Links to School Shift | No |
| Effective From | Timetable Type | Date this type becomes active | Date | Yes | Within academic session | No |
| Effective To | Timetable Type | Date this type ends | Date | Yes | After Effective From | No |
| Has Teaching | Timetable Type | Whether this mode includes subject periods | Boolean | Yes | Yes/No | No |
| Has Exam | Timetable Type | Whether this mode includes exam periods | Boolean | Yes | Yes/No | No |
| Applies to All Sections | Class-Timetable-Type | Whether assignment covers all sections of the class | Boolean | Yes | If Yes → no section selected; if No → section required | No |

**Entity Group 5: Resource Availability and Activities**

| Business Field | Entity | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|---|
| Max Weekly Periods | Teacher Availability | Maximum periods teacher can be scheduled per week | Number | Yes | ≥ Min Weekly Periods | Internal |
| Min Weekly Periods | Teacher Availability | Minimum periods teacher must be scheduled | Number | Yes | ≤ Max | Internal |
| Allocation Strictness | Teacher Availability | How firmly the max periods limit is enforced | Dropdown | Yes | Hard, Medium, Soft | Internal |
| Priority Weight | Teacher Availability | Solver priority score for this teacher | Decimal | Yes | 0.00–10.00 | Internal |
| Full Timetable Availability | Teacher Availability | Whether teacher is available for the full timetable duration (computed) | Boolean | Computed | Computed from availability dates | Internal |
| Days Not Available | Teacher Availability | Count of days teacher cannot be scheduled (computed) | Number | Computed | ≥ 0 | Internal |
| Slot Available | Teacher Availability Detail | Whether teacher is available for a specific day-period | Boolean | Yes | Yes/No | Internal |
| Slot Availability Type | Teacher Availability Detail | Degree of availability | Dropdown | Yes | Available, Unavailable, Preferred | Internal |
| Activity Weekly Periods | Activity | Number of periods per week this activity needs scheduled | Number | Yes | ≥ 1 | No |
| Activity Priority | Activity | Solver placement priority | Dropdown | No | Critical, High, Normal, Low | No |
| Workload Factor | Teacher Assignment Role | Multiplier applied to period count for load calculation | Decimal | Yes | 0.25–3.00 | No |
| Algorithm Type | Generation Strategy | Which solver algorithm to run | Dropdown | Yes | Recursive, Genetic, Simulated Annealing, Tabu Search, Hybrid | No |

### 5.2 Cross-Module Dependency Map

**Inbound — TTF reads from:**

| Source Module | Data Consumed | Why Needed | Tables Read |
|---|---|---|---|
| SchoolSetup | Classes, Sections | Scope activities and requirements per class-section | `sch_classes`, `sch_sections` |
| SchoolSetup | Subjects, Study Formats | Define what subjects need scheduling | `sch_subjects`, `sch_study_formats` |
| SchoolSetup | Rooms, Room Types, Buildings | Room availability setup; Pre-Req Setup display | `sch_rooms`, `sch_room_types`, `sch_buildings` |
| SchoolSetup | Class Subject Groups | Generate class requirement groups; Pre-Req display | `sch_class_subject_groups` |
| StaffProfile / SchoolSetup | Teacher Profiles | Generate teacher availability; assign to activities | `sch_teachers` |
| GlobalMaster / SchoolSetup | Academic Sessions | Scope academic terms to the current year | `sch_academic_sessions` |
| SmartTimetable | TtGenerationStrategyController (code) | TTF routes reference STT's controller for Generation Strategy CRUD — architectural coupling | Cross-module controller reference |

**Outbound — TTF provides to:**

| Target Module | Data Provided | Mechanism | Key Tables Consumed |
|---|---|---|---|
| SmartTimetable | All configuration, requirements, activities, and availability for timetable generation | Direct `tt_*` table reads | All `tt_*` tables; primary consumer |
| StandardTimetable | Period set and type context; timetable type reference | Direct `tt_*` table reads | `tt_period_set`, `tt_period_type`, `tt_timetable_type` |
| Syllabus | Academic Term alignment (term dates used for syllabus scheduling) | Direct `tt_academic_terms` read | `tt_academic_terms` |
| MarksheetGeneration | Academic Term context for marksheet scoping | Direct `tt_academic_terms` read | `tt_academic_terms` |
| ParentPortal | Timetable display for parents | Reads `tt_timetable_cells` (populated by STT) | `tt_timetable_cells` |

**Cross-module architectural issues:**

| Issue | Impact | Recommended Fix |
|-------|--------|-----------------|
| `TtGenerationStrategyController` (SmartTimetable) registered in TTF routes | If STT is disabled, TTF's Generation Strategy page fails | Move controller to TTF module |
| `ClassSubjectGroupController` (SchoolSetup) registered in TTF routes | If SchoolSetup is disabled, TTF's class-group features fail | Move class-group-display route to SchoolSetup or use API call |
| `tt_*` prefix shared across TTF, STT, TTS | Schema drift risk if STT or TTS creates `tt_*` tables in their migrations | Convention: only TTF creates `tt_*` migrations; STT/TTS never create `tt_*` tables |

---

## 6. NFR Catalog and Risk Register

### 6.1 NFR Catalog

| NFR ID | Category | Requirement (measurable) | Acceptance Threshold |
|--------|----------|--------------------------|---------------------|
| NFR-TTF-P01 | Performance | Page 3 (Timetable Masters — 10 tabs) must load all master data | < 800 ms average, 50 teachers, 30 classes |
| NFR-TTF-P02 | Performance | Activity list with 200 activities, eager-loaded relations | < 1,500 ms |
| NFR-TTF-P03 | Performance | Batch activity generation for 50 classes via background job | < 3 minutes end-to-end; UI non-blocking |
| NFR-TTF-P04 | Performance | Teacher availability matrix: 7 × 8 = 56-slot grid render | < 200 ms |
| NFR-TTF-P05 | Performance | Timetable Config reads served from cache after first load | 0 DB queries for config reads after cache warm |
| NFR-TTF-S01 | Security | `EnsureTenantHasModule:TimetableFoundation` on all routes | 100% of routes protected; currently 0% — P0 |
| NFR-TTF-S02 | Security | CSRF protection on all AJAX mutation routes | 100% coverage |
| NFR-TTF-S03 | Security | Gate::authorize() on all controller methods | 100% coverage; currently ~50% verified |
| NFR-TTF-S04 | Security | FormRequest on all mutation endpoints | 100% coverage; currently ~15% — P1 gap |
| NFR-TTF-S05 | Security | Teacher Availability records accessible only to authorised users or owning teacher | Policy check enforced on every read |
| NFR-TTF-S06 | Security | Rate limiting on batch generation endpoints | Max 1 batch generation per user per 5 minutes |
| NFR-TTF-S07 | Security | All data isolated per tenant | Zero cross-tenant queries; enforced by stancl/tenancy |
| NFR-TTF-U01 | Usability | Six-step workflow is sequentially guided | Pages 4–6 require prior-step completion check |
| NFR-TTF-U02 | Usability | AJAX mutations provide immediate visual feedback | Spinner visible within 100 ms; result within 2,000 ms |
| NFR-TTF-U03 | Usability | Working Day Calendar renders as visual calendar | FullCalendar component; click-to-edit per date |
| NFR-TTF-U04 | Usability | Teacher Availability matrix is a visual grid | Grid: periods (rows) × days (columns); single-click toggle |
| NFR-TTF-SC01 | Scalability | Working Day Calendar: 365+ entries per school per year | UNIQUE index on date; query by academic_session_id |
| NFR-TTF-SC02 | Scalability | Teacher Availability Details: 56 slots × 100 teachers = 5,600 rows | Indexed on (teacher_profile_id, day_number, period_number) |
| NFR-TTF-CO01 | Compliance | NEP-2020: support for non-traditional academic terms (Trimester, Quarter) | term_type ENUM includes Quarter, Trimester |

### 6.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|----------|-----------|--------|-----------|-------|
| RISK-TTF-001 | All 138 routes unprotected by EnsureTenantHasModule: a school without a timetable license can access all timetable configuration screens | Security | High | High | Add single middleware wrapper to Routes/web.php (2 hours) | Developer |
| RISK-TTF-002 | `TeacherAvailablity` model typo: any code referencing `TeacherAvailability` (correct) fails with class-not-found | Bug | High | High | Global search-replace across both repos (3 hours) | Developer |
| RISK-TTF-003 | GENERATED columns (duration_minutes, available_for_full_timetable_duration, no_of_days_not_available) in $fillable: Eloquent write attempts cause silent failure or exception | Data Integrity | Medium | High | Audit all 33 models; remove from $fillable; add to $guarded | Developer |
| RISK-TTF-004 | 19 of 23 policies not registered: Gate::policy() calls silently pass, granting access to all authenticated users regardless of role | Security | High | High | Register all policies in TimetableFoundationServiceProvider | Developer |
| RISK-TTF-005 | 22 of 26 controllers lack FormRequests: raw $request input accepted without validation — XSS, mass-assignment, and data-integrity risks | Security | High | Medium | Create 22 FormRequests in priority order | Developer |
| RISK-TTF-006 | `Config::scopeByStatus()` queries non-existent `status` column: every call produces a DB error that crashes the Config tab | Bug | High | High | Change column reference to `is_active` (0.5 hours) | Developer |
| RISK-TTF-007 | Cross-module controller dependencies: if SmartTimetable or SchoolSetup is disabled, TTF routes for Generation Strategy and Class Groups fail | Architecture | Low | High | Move controllers to TTF module or use API calls | Architect |
| RISK-TTF-008 | Academic term date overlap not checked: two overlapping terms create ambiguous solver context — requirement consolidation records belong to the wrong term | Data Integrity | Medium | High | Add overlap check in AcademicTermController (2 hours) | Developer |
| RISK-TTF-009 | Working Day calendar counter auto-update missing: Academic Term teaching/exam day counts are inaccurate until manually updated — solver uses stale data | Data Integrity | Medium | Medium | Implement WorkingDay Eloquent Observer (4 hours) | Developer |
| RISK-TTF-010 | SchoolShift aliased as TimingProfile and SchoolTimingProfile in AppServiceProvider: naming collision prevents correct policy registration for timing profile entities | Architecture | Medium | Medium | Create dedicated models and tables (4 hours) | Developer |
| RISK-TTF-011 | Batch activity generation has no rate limiting: a user could trigger multiple concurrent batch jobs exhausting server resources | Performance | Low | Medium | Add throttle middleware to batch endpoints | Developer |
| RISK-TTF-012 | No integration tests for the end-to-end six-step setup workflow: regression in any step goes undetected | Testing | High | Medium | Implement WF-1 integration test suite (TST-TTF-01 through TST-TTF-16) | Tester |

---

## 7. Prioritization and Effort Estimation

### 7.1 MoSCoW Prioritization

**Must (P0 — production-blocking)**
- RISK-TTF-001: Add EnsureTenantHasModule middleware (2 h)
- RISK-TTF-002: Fix TeacherAvailablity typo (3 h)
- RISK-TTF-006: Fix scopeByStatus() bug (0.5 h)
- RISK-TTF-004: Register 19 unregistered policies (3 h)
- RISK-TTF-005: Create 22 FormRequests (16–20 h)
- RISK-TTF-003: Audit GENERATED columns in $fillable (4 h)

**Should (P1 — high business value)**
- BR-TTF-005 application enforcement: Academic term date overlap check (2 h)
- BR-TTF-002 application enforcement: Timetable type time overlap check (2 h)
- RISK-TTF-009: WorkingDay Observer for term counter auto-update (4 h)
- RISK-TTF-010: Dedicated TimingProfile / SchoolTimingProfile models (4 h)
- ENH-TTF-004: Config read caching (3 h)
- RISK-TTF-007: Resolve cross-module controller coupling (3–5 h)
- TST-TTF-01 through TST-TTF-10: Priority test cases (12–16 h)

**Could (P2 — enhancement)**
- ENH-TTF-001: Constraint Type Catalog Viewer (4 h)
- ENH-TTF-002: Temporary Unavailability screens (8 h)
- RISK-TTF-011: Rate limiting on batch endpoints (1 h)
- Service extraction: WorkingDayService, RequirementConsolidationService, ActivityGenerationService (12 h)

**Won't (this release)**
- Full route file split into per-page sub-files
- Eager-loading N+1 audit on Page 3

### 7.2 Effort Estimation and Sprint Task Breakdown

> Assumptions: 1 senior developer; 6 h/day effective coding time. Tasks are independent unless marked "Depends."

| # | Task | Type | Effort (h) | Sprint | Depends On |
|---|------|------|-----------|--------|-----------|
| 1 | Add `EnsureTenantHasModule:TimetableFoundation` to single Route group wrapper in Routes/web.php | Backend | 2 | 1 | — |
| 2 | Global search-replace `TeacherAvailablity` → `TeacherAvailability` across all files in both repos | Backend | 3 | 1 | — |
| 3 | Fix `Config::scopeByStatus()` — change `status` to `is_active` in Models/Config.php | Backend | 0.5 | 1 | — |
| 4 | Register all 23 policies in `TimetableFoundationServiceProvider.php` using `Gate::policy()` | Backend | 3 | 1 | #2 (policy references model) |
| 5 | Audit all 33 models for GENERATED columns in $fillable; move to $guarded or remove entirely | Backend | 4 | 1 | #2 |
| 6 | Create `WorkingDayRequest` FormRequest (AJAX fields, day_type validation) | Backend | 2 | 2 | — |
| 7 | Create `ActivityRequest` FormRequest (class, section, subject, term, weekly_periods validation) | Backend | 2 | 2 | — |
| 8 | Create `RequirementConsolidationRequest` FormRequest | Backend | 1.5 | 2 | — |
| 9 | Create `TeacherAvailabilityRequest` FormRequest | Backend | 2 | 2 | #2 |
| 10 | Create `PeriodSetRequest` FormRequest | Backend | 1.5 | 2 | — |
| 11 | Create `PeriodSlotRequest` FormRequest with `end_time > start_time` cross-field rule | Backend | 2 | 2 | — |
| 12 | Create `RoomAvailabilityRequest` FormRequest | Backend | 1.5 | 2 | — |
| 13 | Create `TimetableTypeRequest` FormRequest (includes school time validation) | Backend | 2 | 2 | — |
| 14 | Create `ClassTimetableTypeRequest` FormRequest (includes applies_to_all_sections conditional) | Backend | 2 | 2 | — |
| 15 | Create remaining 13 FormRequests (DayTypeRequest, PeriodTypeRequest, ShiftRequest, SchoolDayRequest, ClassWorkingDayRequest, SlotRequirementRequest, ClassSubjectSubgroupRequest, TimetableRequest, TimetableTypeRequest, TeacherAssignmentRoleRequest, TeacherAvailabilityLogRequest) | Backend | 10 | 2-3 | — |
| 16 | Add academic term date overlap check in AcademicTermController store() and update() | Backend | 2 | 3 | — |
| 17 | Add timetable type school-time overlap check per shift in TimetableTypeController | Backend | 2 | 3 | — |
| 18 | Implement WorkingDay Eloquent Observer to auto-update Academic Term day counters | Backend | 4 | 3 | — |
| 19 | Create dedicated TimingProfile and SchoolTimingProfile models + tables; remove AppServiceProvider alias | Backend | 4 | 3 | — |
| 20 | Add `tt_config` read caching (Laravel cache; invalidate on config update) | Backend | 3 | 3 | — |
| 21 | Resolve cross-module route entries: move TtGenerationStrategyController to TTF; update routes | Backend | 3 | 4 | — |
| 22 | Add rate limiting throttle to `generateAllActivities` and `generateRequirements` endpoints | Backend | 1 | 4 | — |
| 23 | Write feature test: TST-TTF-01 (EnsureTenantHasModule blocks all routes for unlicensed tenant) | Testing | 3 | 4 | #1 |
| 24 | Write unit tests: TST-TTF-02 through TST-TTF-10 (GENERATED columns, overlap checks, batch generation, availability unique) | Testing | 12 | 4-5 | #2, #4, #5 |
| 25 | Build ConstraintTypeController (read-only catalog viewer) + route + view (ENH-TTF-001) | Backend + Frontend | 4 | 5 | — |
| 26 | Build TeacherUnavailableController + RoomUnavailableController + routes + views (ENH-TTF-002) | Backend + Frontend | 8 | 5 | — |
| 27 | Extract WorkingDayService, RequirementConsolidationService, ActivityGenerationService | Backend | 12 | 6 | #6, #8, #7 |

**Total P0 effort:** ~12.5 h (tasks 1–5)
**Total P1 effort:** ~33.5 h (tasks 6–22)
**Total P2 effort:** ~24 h (tasks 23–27)
**Grand total:** ~70 h (~12 developer days)

---

## 8. User Stories, Acceptance Criteria, and Reporting KPI Spec

### 8.1 User Stories — P0 Requirements

**US-TTF-001** | Priority: P0 | REQ ref: REQ-TTF-009
As a Timetable Manager, I want to initialise the school's working day calendar for the new academic session so that the system knows which dates are teaching days, exam days, and holidays.

Acceptance Criteria:
- Scenario: Calendar initialisation
  - Given the academic session has a defined start and end date
  - When the Timetable Manager clicks "Initialise Calendar"
  - Then one Working Day record is created for every calendar date in the session range, weekdays defaulting to Study and weekends defaulting to Holiday
- Scenario: Editing a date after initialisation
  - Given the calendar is initialised
  - When the Timetable Manager clicks a date and selects "Exam Day"
  - Then the date's Day Type is updated via AJAX and the calendar cell reflects the new type without page reload
- Scenario: Permission denied
  - Given a user with Teacher role
  - When they attempt to access the Working Days calendar
  - Then they receive a 403 Forbidden response
Definition of Done: Working day records created; dates editable via calendar UI; AJAX saves confirmed; Academic Term counter updated (or gap logged); audit history of who initialised.

---

**US-TTF-002** | Priority: P0 | REQ ref: REQ-TTF-014
As a Timetable Manager, I want to generate teacher availability records and edit per-slot matrices so that the solver knows exactly which time slots each teacher is free to teach.

Acceptance Criteria:
- Scenario: Batch generate availability
  - Given Requirement Consolidation records exist for the academic term
  - When the Timetable Manager clicks "Generate Teacher Availability"
  - Then one Availability record is created per teacher in those records, all slots defaulting to Available
- Scenario: Toggling a slot to Unavailable
  - Given a teacher's availability matrix is open
  - When the Timetable Manager clicks the Wednesday Period 3 slot to mark it Unavailable
  - Then the slot is saved as Unavailable via AJAX; an Availability Log entry is created recording who changed it
- Scenario: Teacher views own record
  - Given a teacher is logged in
  - When they navigate to their own Availability
  - Then they see their availability matrix in read-only mode
- Scenario: Teacher tries to see another teacher's record
  - Given a teacher is logged in
  - When they navigate to another teacher's Availability URL
  - Then they receive a 403 Forbidden response

---

**US-TTF-003** | Priority: P0 | REQ ref: REQ-TTF-016
As a Timetable Manager, I want to generate all activities in batch from Requirement Consolidation records so that SmartTimetable has a complete list of what to schedule without manual data entry for hundreds of class-subject combinations.

Acceptance Criteria:
- Scenario: Batch generation starts
  - Given Requirement Consolidation records exist for the academic term
  - When the Timetable Manager clicks "Generate All Activities"
  - Then a background job starts and a progress bar appears polling every 2 seconds
- Scenario: Batch generation completes
  - Given the batch job is running
  - When all classes have been processed
  - Then the UI shows "Generation Complete" and the Activity list refreshes with newly created records in DRAFT status
- Scenario: Duplicate activity prevented
  - Given an Activity already exists for Class 9A — Mathematics — Theory — Term 1
  - When the batch generation runs again
  - Then the existing Activity is not duplicated; the generation skips it or updates it without creating a second record
- Scenario: Rate limiting
  - Given the Timetable Manager already triggered batch generation in the last 5 minutes
  - When they click "Generate All Activities" again
  - Then the system rejects the request with "Batch generation already in progress or recently completed"

---

**US-TTF-004** | Priority: P0 | REQ ref: REQ-TTF-002
As a Timetable Manager, I want to inline-edit configuration values so that I can adjust scheduler behaviour (such as maximum teacher weekly periods) without navigating to a separate editing screen.

Acceptance Criteria:
- Scenario: Edit a modifiable config key
  - Given a config key with "Tenant Can Modify" set to Yes
  - When the Timetable Manager clicks the value cell and enters a new number
  - Then the value is saved and reflected in the display immediately
- Scenario: System-managed key is read-only
  - Given a config key with "Tenant Can Modify" set to No
  - When the Timetable Manager attempts to edit the value
  - Then no edit control is shown; the value field is displayed as read-only text
- Scenario: Invalid type rejected
  - Given a NUMBER-type config key
  - When the Timetable Manager enters non-numeric text
  - Then the save is rejected with "This field must be a number"

---

**US-TTF-005** | Priority: P0 | REQ ref: REQ-TTF-013
As a Timetable Manager, I want to generate Requirement Consolidation records for a selected academic term so that the system automatically computes how many periods per week each class-section-subject needs before I start generating activities.

Acceptance Criteria:
- Scenario: Generation produces one record per combination
  - Given class-subject-study-format mappings exist in SchoolSetup for the selected academic term
  - When the Timetable Manager clicks "Generate Requirements"
  - Then one Requirement Consolidation record is created per unique class-section-subject-study-format combination
- Scenario: Inline period count editing
  - Given Requirement Consolidation records exist
  - When the Timetable Manager edits the "Required Weekly Periods" for Class 9A — Science Theory from 5 to 6
  - Then the cell updates via AJAX and the new value is persisted
- Scenario: Statistics summary
  - Given Requirement Consolidation records exist
  - When the Timetable Manager clicks "Get Statistics"
  - Then the summary panel shows total records count, number of classes covered, number of subjects, and average periods per class

---

### 8.2 User Stories — P1 Requirements

**US-TTF-006** | Priority: P1 | REQ ref: REQ-TTF-003
As a Timetable Manager, I want to create and manage Academic Terms with validated non-overlapping date ranges so that all timetable data is correctly scoped to the right time period.

Acceptance Criteria:
- Scenario: Create a valid term
  - Given an academic session with dates Apr 1–Mar 31
  - When the Timetable Manager creates Quarter 1 (Apr 1–Jun 30) and Quarter 2 (Jul 1–Sep 30)
  - Then both are created successfully with no overlap
- Scenario: Overlapping term rejected
  - Given Quarter 1 exists (Apr 1–Jun 30)
  - When the Timetable Manager creates Quarter 2 starting Jun 15
  - Then the save is rejected with "Term dates overlap with Quarter 1 (Apr 1–Jun 30)"
- Scenario: Delete term with dependencies
  - Given Quarter 1 has associated Requirement Consolidation records
  - When the Timetable Manager attempts to delete it
  - Then the delete is blocked and a warning lists the dependent records

---

**US-TTF-007** | Priority: P1 | REQ ref: REQ-TTF-008
As a Timetable Manager, I want to define Period Sets with ordered time slots so that the solver knows exactly what time each period of the school day runs.

Acceptance Criteria:
- Scenario: Create a period set with valid slots
  - Given I create "Standard 8-Period Day" with Day Start 08:00 and Day End 14:30
  - When I add 8 period slots with correct start/end times
  - Then the Period Set is saved; Duration for each slot is computed automatically and displayed
- Scenario: End time ≤ start time rejected
  - Given a period slot with Start Time 09:00
  - When I enter End Time 08:55
  - Then the save is rejected with "End time must be after start time"
- Scenario: Duration field not editable
  - Given the Period Slot create form
  - When I view the form
  - Then no input field for "Period Duration" appears — it is display-only in the list

---

### 8.3 Reporting and KPI Specification

| KPI | Definition (Business Language) | Source Data | Target | Cadence |
|-----|-------------------------------|-------------|--------|---------|
| Setup Completion Rate | Percentage of the six pre-generation steps completed for the current academic term (Steps 1–6) | TTF page data / Activity count / Availability count | 100% before generation | Before each generation run |
| Teacher Utilisation | Average allocated weekly periods across all teachers as a percentage of their maximum configured weekly periods | `tt_teacher_availabilities`, `tt_timetable_cell_teachers` | 80–95% | Per generation |
| Room Utilisation | Percentage of available teaching slots that are scheduled in each room | `tt_timetable_cells`, `tt_room_availabilities` | > 60% average | Per generation |
| Unassigned Activities | Count of Activity records in DRAFT status (teacher not yet assigned) as a proportion of total activities | `tt_activities` | 0 before generation | Before generation |
| Requirement Coverage | Percentage of Requirement Consolidation records that have a corresponding Activity record | `tt_requirement_consolidation`, `tt_activities` | 100% | Before generation |
| Teacher Overload Risk | Count of teachers whose allocated periods exceed their maximum configured limit | `tt_teacher_availabilities`, `tt_timetable_cell_teachers` | 0 | After generation |

**Report RPT-TTF-001 — Class-Wise Timetable:** See FRD §7.

**Report RPT-TTF-002 — Teacher-Wise Timetable:** See FRD §7.

**Report RPT-TTF-003 — Room Utilisation:** Formula: `(scheduled_slots ÷ available_slots) × 100 = utilisation %`. Rooms below 50% are highlighted yellow; above 90% are highlighted red.

**Report RPT-TTF-004 — Teacher Workload Summary:** Formula: `allocated_periods ÷ max_weekly_periods × 100 = workload %`. Over 100% = overloaded (red). Under 70% = under-loaded (yellow).

**Report RPT-TTF-005 — Requirement Consolidation Summary:** Formula: `gap = required_weekly_periods − allocated_periods`. Positive = under-allocated (red). Zero = balanced (green). Negative = over-allocated (yellow).

---

## 9. Feature Specification — Screen-by-Screen

> Layout and field tables for the seven menu pages and key sub-screens.

### 9.1 Page 1 — Pre-Requisites Setup

**Layout:** Multi-tab page | **Actions:** View only (no create/edit/delete) | **Route:** `timetable-foundation.menu.preRequisitesSetup`

| Tab | Fields Displayed | Source Module | Empty State |
|-----|-----------------|---------------|-------------|
| Buildings | Name, type, floor count, room count | SchoolSetup | "No buildings configured. Go to School Setup → Buildings." |
| Room Types | Code, name, capacity range | SchoolSetup | "No room types found." |
| Rooms | Name, building, room type, capacity, is_lab | SchoolSetup | "No rooms configured." |
| Teacher Profiles | Name, subject specialisation, shift preference | StaffProfile | "No teacher profiles found." |
| Classes & Sections | Class name, number of sections | SchoolSetup | "No classes found." |
| Subjects & Formats | Subject name, code, study formats available | SchoolSetup | "No subjects found." |
| School Class Groups | Group name, classes in group, subject count | SchoolSetup | "No class groups found." |

**Permissions:** All authenticated users with module access (view-only).

### 9.2 Page 2 — Timetable Configuration

**Tab 1: Timetable Config** | Route: `config` resource | Controller: `ConfigController`

| # | Field | Type | Required | Validation | Notes |
|---|-------|------|---------|------------|-------|
| 1 | Config Key | Text (read-only) | — | System-set; immutable | Display only |
| 2 | Value | Inline edit | Yes (if modifiable) | Type-aware: NUMBER→numeric, BOOLEAN→toggle, TIME→time picker, JSON→JSON editor | Only for tenant_can_modify=1 |
| 3 | Value Type | Badge | — | STRING/NUMBER/BOOLEAN/DATE/TIME/DATETIME/JSON | Display only |
| 4 | Can Modify | Badge | — | Yes/No | Controls inline edit visibility |
| 5 | Is Active | Toggle | — | Active/Inactive | scopeByStatus uses `is_active` (bug: currently uses `status`) |

**Tab 2: Academic Terms** | Route: `academic-term` resource | Controller: `AcademicTermController`

| # | Field | Type | Required | Validation |
|---|-------|------|---------|------------|
| 1 | Term Name | Text | Yes | Max 100 chars; unique per session |
| 2 | Term Type | Dropdown | Yes | Quarter, Semester, Annual, Trimester |
| 3 | Academic Session | Dropdown | Yes | Links to active session |
| 4 | Start Date | Date | Yes | Within session range |
| 5 | End Date | Date | Yes | After start; no overlap with other terms in same session |
| 6 | Total Teaching Days | Number (auto) | Computed | Auto from working day observer |
| 7 | Total Exam Days | Number (auto) | Computed | Auto |
| 8 | Total Working Days | Number (auto) | Computed | Auto |

**Tab 3: Generation Strategy** | Route: `generation-strategies` resource | Controller: `TtGenerationStrategyController` (SmartTimetable — architectural gap)

| # | Field | Type | Required | Notes |
|---|-------|------|---------|-------|
| 1 | Strategy Code | Text | Yes | Unique |
| 2 | Algorithm Type | Dropdown | Yes | Recursive, Genetic, Simulated Annealing, Tabu Search, Hybrid |
| 3 | Is Default | Toggle | Yes | Only one at a time; toggle clears others |
| 4 | Timeout (seconds) | Number | No | 0 = no limit |
| 5 | Max Recursive Depth | Number | Conditional | Visible for Recursive type only |
| 6 | Population Size | Number | Conditional | Visible for Genetic/Hybrid types |
| 7 | Cooling Rate | Decimal | Conditional | Visible for Simulated Annealing type |
| 8 | Tabu Size | Number | Conditional | Visible for Tabu Search type |
| 9 | Parameters (JSON) | JSON editor | No | Advanced override parameters |

### 9.3 Page 3 — Timetable Masters (10 sub-tabs)

All tabs follow the same pattern: DataTable index + modal create/edit + status toggle + soft delete/restore/force delete.

**Shift tab** — Fields: Code, Name, Display Order, Default Start Time, Default End Time, Active Status. Unique constraints on Code, Name, Order.

**Day Type tab** — Fields: Code, Name, Display Order, Is Working Day (toggle), Has Reduced Periods (toggle), Active Status.

**Period Type tab** — Fields: Code, Name, Display Order, Is Schedulable, Counts as Teaching, Counts as Workload, Is Break, Is Free Period, Colour Code (#hex), Icon (Font Awesome class), Default Duration (minutes).

**School Day Reference tab** — Fields: Day Code (MON–SUN), Day Name, Display Order, Is School Day (toggle). Seven rows only (seeded reference data).

**Working Day Calendar tab** — Full-screen FullCalendar display. Click a date → modal with Day Type 1–4 dropdowns. "Initialise Calendar" button. View: Monthly or Weekly.

**Class Working Day Override tab** — Class + Section selector → calendar view scoped to that class. Same edit pattern.

**Period Sets tab** — Fields: Code, Total Periods, Teaching Periods, Exam Periods, Free Periods, Assembly Periods, Short Break Periods, Lunch Break Periods, Day Start Time, Day End Time, Is Default.

**Period Slots sub-tab** (within Period Set edit) — Fields: Position (ordinal), Period Type, Start Time, End Time; Duration displayed (computed, not editable).

**Timetable Types tab** — Fields: Code, Shift, Effective From, Effective To, School Start Time, School End Time, Has Teaching, Has Exam, Is Default.

**Class Timetable Types tab** — Fields: Academic Term, Timetable Type, Class, Section (or "All Sections" toggle), Period Set, Weekly Teaching Periods, Weekly Exam Periods, Weekly Free Periods.

**Teacher Assignment Roles tab** — Fields: Code, Name, Is Primary Instructor, Counts for Workload, Allows Overlap, Workload Factor (0.25–3.00 decimal).

**Timing Profiles tabs** — Two sub-tabs: Timing Profile (effective date range + period set) and School Timing Profile. Note: current SchoolShift alias workaround pending dedicated model creation.

### 9.4 Page 4 — Timetable Requirement

**Tab 1: Slot Requirements** — DataTable showing class-section-timetable-type-term with weekly slot totals. Action: "Generate Slot Requirements" button. Inline status toggle.

**Tab 2: Requirement Groups** — Group CRUD with subject and class-section associations. AJAX "Toggle Sharing" on each row.

**Tab 3: Requirement Subgroups** — Subgroup CRUD within groups. Sharing flags: is_shared_across_sections, is_shared_across_classes. AJAX toggle.

**Tab 4: Requirement Consolidation** — The most important tab. DataTable with columns: Class, Section, Subject, Study Format, Required Weekly Periods (inline-editable), Academic Term. Actions: "Generate Requirements" (bulk), "Get Statistics" (summary panel), "Inline Update" per cell. Colour-coded gap indicator (positive gap = red, zero = green, negative = yellow).

### 9.5 Page 5 — Resource Availability

**Tab 1: Teacher Availability** — Two-level UI: (a) Master list of teachers with availability summary; (b) Click teacher → per-slot matrix grid (rows = periods, columns = days Mon–Sat). Each cell: colour-coded Available/Unavailable/Preferred toggle. Header shows: Max Periods, Min Periods, Allocation Strictness, Priority Weight. "Generate Teacher Availability" button generates default records. Workload Factor display (computed values shown read-only).

**Tab 2: Teacher Availability Log** — Audit log DataTable: Teacher Name, Changed By, Changed Date, Day, Period, Old Value, New Value, Reason. Read-only. Filter by teacher and date range.

**Tab 3: Room Availability** — Similar to teacher availability but for rooms. Room selector → per-slot matrix. Room Type filter.

### 9.6 Page 6 — Timetable Preparation

**Tab 1: Activities** — DataTable: Class, Section, Subject, Study Format, Required Weekly Periods, Assigned Teachers (count), Priority, Status, Academic Term. Actions: Create, Edit, Delete, Toggle Status, "Generate Activities" (single class), "Generate All Activities" (batch — shows progress bar), "Get Batch Progress."

**Tab 2: Sub-Activities** — Parent Activity selector → Sub-activity list. Fields: Name, Periods per Week, Study Format, Teacher (optional), Status. Within sub-activity: Sub-Activity Detail sub-tab (day preference, period preference, room preference, duration periods).

**Tab 3: Activity Teacher Mapping** — Activity selector → list of teacher assignments with role and allocation percentage. Add/remove teachers per activity.

### 9.7 Page 7 — Reports and Logs

Four report panels, each with class/teacher/room filter and term selector:
1. Class-Wise Timetable Grid (RPT-TTF-001)
2. Teacher-Wise Timetable Grid (RPT-TTF-002)
3. Room Utilisation Summary (RPT-TTF-003)
4. Teacher Workload Summary (RPT-TTF-004)

All panels have Print and Export PDF buttons.

---

## 10. Requirements-vs-Code Gap Analysis

> This is the BA-side gap analysis (requirement coverage oriented). Deep code/security gaps are in the module knowledge file and the Technical Auditor's scope.

| REQ / BR Ref | Requirement | Code Status | Evidence | Gap |
|---|---|---|---|---|
| REQ-TTF-001 | Pre-Requisites Setup read-only dashboard | DONE | `TimetableFoundationController@preRequisitesSetup` exists; 172 views include pre-requisites templates | Empty-state handling for missing SchoolSetup data unverified |
| REQ-TTF-002 | Timetable Configuration key-value CRUD | PARTIAL (70%) | `ConfigController` exists with `ConfigRequest`; `scopeByStatus()` calls non-existent `status` column (BUG-TTF-05) | `scopeByStatus()` bug makes Config tab error-prone; no caching |
| REQ-TTF-003 | Academic Term Management with overlap check | PARTIAL (75%) | `AcademicTermController` exists with `AcademicTermRequest`; CRUD works | Date overlap check (BR-TTF-005) not implemented |
| REQ-TTF-004 | Generation Strategy Management | PARTIAL (85%) | Routes exist in TTF for `generation-strategies`; controller lives in SmartTimetable module | Cross-module controller; will fail if SmartTimetable is disabled |
| REQ-TTF-005 | School Shift Management | DONE (90%) | `SchoolShiftController` exists; full CRUD + toggle + soft-delete routes confirmed | `ShiftRequest` FormRequest missing; user-friendly duplicate-key error unverified |
| REQ-TTF-006 | Day Type Management | DONE (90%) | `DayTypeController` exists | `DayTypeRequest` FormRequest missing |
| REQ-TTF-007 | Period Type Management | DONE (90%) | `PeriodTypeController` exists | `PeriodTypeRequest` FormRequest missing |
| REQ-TTF-008 | Period Set Management with GENERATED column protection | PARTIAL (85%) | `PeriodSetController` and `PeriodSetPeriodController` exist; `PeriodSlotRequest` missing | `duration_minutes` may be in $fillable (BUG-TTF-06); cross-field end>start FormRequest rule missing |
| REQ-TTF-009 | Working Day Calendar with term counter auto-update | PARTIAL (80%) | `WorkingDayController` with AJAX methods confirmed in routes; FullCalendar integration present | `WorkingDay` Observer missing — term counters never auto-update (BR-TTF-015 gap) |
| REQ-TTF-010 | Timetable Type and Class Assignment with overlap checks | PARTIAL (80%) | `TimetableTypeController` and `ClassTimetableTypeController` exist | Application-level time overlap check missing; class period-set overlap check missing |
| REQ-TTF-011 | Slot Requirement generation | PARTIAL (65%) | `SlotRequirementController` with `generateSlotRequirement` confirmed | Full CRUD completeness and edge-case handling uncertain |
| REQ-TTF-012 | Requirement Groups and Subgroups with sharing toggle | PARTIAL (60%) | `ClassSubjectSubgroupController` with `ajaxToggleSharing`; `getSectionsByClass` AJAX | Full group CRUD completeness uncertain; FormRequests missing |
| REQ-TTF-013 | Requirement Consolidation with inline edit | PARTIAL (70%) | `RequirementConsolidationController` with `generateRequirements`, `ajaxInlineUpdate`, `getRequirementsStats` confirmed | `RequirementConsolidationRequest` missing; regeneration replace vs duplicate unverified |
| REQ-TTF-014 | Teacher Availability with per-slot matrix and audit log | PARTIAL (70%) | `TeacherAvailabilityController` with `generateTeacherAvailability` confirmed | Model typo (BUG-TTF-02); GENERATED columns risk (BUG-TTF-07); `TeacherAvailabilityRequest` missing; `TeacherAvailabilityLog` model missing from filesystem |
| REQ-TTF-015 | Room Availability matrix | PARTIAL (65%) | `RoomAvailabilityController` confirmed; `RoomAvailabilityService` exists | Detail matrix completeness uncertain; FormRequest missing |
| REQ-TTF-016 | Activity Management with batch generation | PARTIAL (75%) | `ActivityController` with `generateActivities`, `generateAllActivities`, `getBatchGenerationProgress` confirmed; `SubActivityDetailController` and `PriorityConfigController` present (post-V2 additions) | `ActivityRequest` missing; no rate limiting; no notification on batch completion |
| REQ-TTF-017 | Teacher Assignment Role Master | DONE (90%) | `TeacherAssignmentRoleController` confirmed | `TeacherAssignmentRoleRequest` FormRequest missing |
| REQ-TTF-018 | Timetable Master Records with status lifecycle | PARTIAL (75%) | `TimetableController` confirmed | Published→Archive auto-transition unverified; version management partial |
| REQ-TTF-019 | Timing Profile Management | PARTIAL (60%) | `TimingProfileController` and `SchoolTimingProfileController` exist with `TimingProfileRequest` and `SchoolTimingProfileRequest` | `SchoolShift` model used as alias for both TimingProfile and SchoolTimingProfile (ARCH-TTF-08); dedicated models missing |
| REQ-TTF-020 | Reports and Analytics Page | PARTIAL (60%) | `TimetableFoundationController@reportsAndLogs` confirmed; `AnalyticsService` exists | Completeness of STT analytics integration unknown |
| REQ-TTF-021 | Constraint Type Catalog Viewer | NOT STARTED (0%) | `tt_constraint_type` table seeded by SmartTimetable; no TTF controller found | Full feature missing; tables exist |
| REQ-TTF-022 | Temporary Resource Unavailability | NOT STARTED (0%) | `tt_teacher_unavailable` and `tt_room_unavailable` in DDL; no controllers | Full feature missing |
| BR-TTF-001 | Period slot end > start | PARTIAL | DB CHECK exists; FormRequest rule missing | Application-level cross-field validation absent |
| BR-TTF-002 | Timetable type time no-overlap per shift | NOT IMPLEMENTED | No evidence in controller or DB | Full gap |
| BR-TTF-003 | duration_minutes not writable | PARTIAL | DB GENERATED STORED enforces; $fillable audit needed | Model audit outstanding |
| BR-TTF-004 | applies_to_all_sections ↔ section_id null | PARTIAL | DB CHECK exists; FormRequest conditional rule absent | Application-level conditional missing |
| BR-TTF-005 | Academic term dates no overlap | NOT IMPLEMENTED | No evidence of overlap check | Full gap |
| BR-TTF-006 | One activity per class-section-subject-format per term | PARTIAL | Partial application check suspected; no test | Unverified |
| BR-TTF-007/008 | GENERATED availability columns not writable | PARTIAL | MySQL enforces; $fillable audit needed | Model audit outstanding |
| BR-TTF-009 | One default Period Set | PARTIAL | Toggle logic in controller; single-default guarantee unverified | Concurrency risk |
| BR-TTF-010 | Teacher-day-period slot unique; graceful error | PARTIAL | DB UNIQUE enforces; graceful error handling unverified | |
| BR-TTF-011 | System-managed config keys read-only | PARTIAL | UI partially enforces; Gate check unverified | |
| BR-TTF-012 | One default Generation Strategy | DONE | Controller toggle logic confirmed | |
| BR-TTF-013 | No duplicate Requirement Consolidation | PARTIAL | Generation logic exists; regeneration behaviour unverified | |
| BR-TTF-014 | Shift unique fields; friendly errors | PARTIAL | DB UNIQUE enforces; user-friendly error handling unverified | |
| BR-TTF-015 | Working day change updates term counters | NOT IMPLEMENTED | Observer missing; confirmed absent | Full gap |

### Gap Summary

| Gap Severity | Count | Items |
|---|---|---|
| P0 — Production Blocking | 4 | EnsureTenantHasModule (0/138 routes), TeacherAvailablity typo, scopeByStatus() bug, 19 unregistered policies |
| P1 — High | 6 | 22 missing FormRequests, BR-TTF-005/002/015 not implemented, GENERATED column $fillable risk, cross-module controller coupling |
| P2 — Medium | 4 | Config caching, academic-term counter observer, Timing Profile model architectural debt, rate limiting |
| Feature Gaps (Not Started) | 2 | REQ-TTF-021 (Constraint Type Viewer), REQ-TTF-022 (Temporary Unavailability) |

---

*End of TTF Complete Analysis Pack — 2026-06-30*
*FRD file: `TTF_FRD_2026-06-30.md`*
*Conditions Catalog: `5-Requirement_Conditions/TTF_Conditions.md`*
*Module Knowledge: `AI_Brain/module-knowledge/TTF_TimetableFoundation.md`*
