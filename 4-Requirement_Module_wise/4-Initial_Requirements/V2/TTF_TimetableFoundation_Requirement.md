# TTF — Timetable Foundation
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** TTF | **Platform:** Prime-AI Academic Intelligence Platform
**Tech Stack:** Laravel 12 + PHP 8.2 + MySQL 8.x | **Tenancy:** stancl/tenancy v3.9 | **Modules:** nwidart/laravel-modules v12

---

## 1. Executive Summary

TimetableFoundation (TTF) is the mandatory configuration and master-data layer that SmartTimetable (STT) and StandardTimetable consume before any timetable can be generated. It owns all `tt_*` tables in the tenant database, exposes 24 resource controllers, and organises its UI into 7 menu pages.

**Current completion: ~68% (Grade C-).** The module is architecturally sound but has four critical gaps preventing production readiness:

| Severity | Issue | Impact |
|----------|-------|--------|
| P0 — Critical | `EnsureTenantHasModule` middleware absent from all 100+ routes | Any tenant can access timetable pages without a license |
| P1 — High | Only 4 of 24 controllers have FormRequests | Input validation incomplete; mutation endpoints unsecured |
| P1 — High | ~19 of 24 policies not registered in AppServiceProvider | Gate::policy() calls silently pass; auth theatre |
| P1 — High | `TeacherAvailablity` model name typo | Import errors across modules that reference this model |

Estimated remediation effort: **46–65 hours** (P0: 2–3 h; P1: 24–32 h; P2: 16–24 h; P3: 4–6 h).

---

## 2. Module Overview

### 2.1 Purpose

TTF defines *everything the scheduler needs to know before it can run*:

| Question | TTF Answer |
|----------|------------|
| What time does school happen? | Shifts (`tt_shift`), period sets (`tt_period_set` + `tt_period_set_period_jnt`) |
| What kind of day is it? | Day types (`tt_day_type`), working day calendar (`tt_working_day`) |
| What subjects need scheduling? | Requirement consolidation (`tt_requirement_consolidation`), activities (`tt_activity`) |
| Who is available when? | Teacher availability (`tt_teacher_availabilities`, detail table), room availability |
| What algorithm to use? | Generation strategy (`tt_generation_strategy`) |
| What are the rules? | Constraint type catalog (`tt_constraint_type`), timetable config (`tt_config`) |

### 2.2 Module Characteristics

| Attribute | Value |
|-----------|-------|
| Namespace | `Modules\TimetableFoundation` |
| DB Connection | `tenant_mysql` (per-school tenant database) |
| Table Prefix | `tt_*` (shared with SmartTimetable) |
| Controllers | 24 |
| Models | 32 |
| Services | 3 (`AnalyticsService`, `RoomAvailabilityService`, `SubActivityService`) |
| FormRequests | 4 (`AcademicTermRequest`, `ConfigRequest`, `SchoolTimingProfileRequest`, `TimingProfileRequest`) |
| Policies | 24 defined; ~5 registered (most are dead code) |
| Tests | 7 files (Feature: 1, Unit: 6) |
| Routes | 280 lines — largest route file in project |
| EnsureTenantHasModule | **MISSING** from all routes |

### 2.3 Seven Menu Pages Architecture

| # | Page | Route Suffix | Key Tabs |
|---|------|-------------|----------|
| 1 | Pre-Requisites Setup | `pre-requisites-setup` | Buildings, Room Types, Rooms, Teacher Profiles, Classes, Subjects |
| 2 | Timetable Configuration | `timetable-configuration` | Config, Academic Terms, Generation Strategy |
| 3 | Timetable Masters | `timetable-masters` | Shift, Day Type, Period Type, Teacher Roles, School Days, Working Days, Class Working Days, Period Sets, Timetable Types, Class Timetables |
| 4 | Timetable Requirement | `timetable-requirement` | Slot Requirement, Requirement Groups, Requirement Sub-Groups, Requirement Consolidation |
| 5 | Resource Availability | `resource-availability` | Teacher Availability, Availability Log, Room Availability |
| 6 | Timetable Preparation | `timetable-preparation` | Activities, Sub-Activities, Activity Teacher Mapping |
| 7 | Reports & Logs | `reports-and-logs` | Class-wise, Teacher-wise, Room-wise, Workload, Utilization |

### 2.4 Relationship with Consumer Modules

```
TimetableFoundation (TTF)           SmartTimetable (STT)
─────────────────────────────────────────────────────────────
tt_config               ─reads→     SmartTimetableController
tt_period_set_period_jnt ─reads→    FET solver (time slots)
tt_activity             ─reads→     Placement engine (items to place)
tt_teacher_availabilities ─reads→   Constraint engine (teacher windows)
tt_generation_strategy  ─reads→     Algorithm selection
tt_constraint_type      ─seeds→     ConstraintManager catalog
tt_requirement_consolidation ─reads→ GenerateTimetableJob
```

---

## 3. Stakeholders & Roles

| Role | Access Level | Key Operations |
|------|-------------|----------------|
| School Admin | Full | All 7 TTF pages; all CRUD |
| Academic Coordinator | Full | Requirements, activities, availability |
| Timetable Manager | Full | Primary user; all TTF data |
| Principal | ViewAny only | Read-only review of configuration |
| Teacher | Limited | Read own availability record; cannot edit |
| System (seeder) | Backend | Seeds `tt_config`, `tt_constraint_type`, `tt_day_type`, `tt_generation_strategy` |

---

## 4. Functional Requirements

### FR-TTF-01: Timetable Configuration

**Status:** 🟡 Partial (view works; edit path needs auth verification)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-01.1 | Display all `tt_config` key-value records grouped by category | ✅ |
| FR-TTF-01.2 | Inline edit `value` field for `tenant_can_modify = 1` records | 🟡 |
| FR-TTF-01.3 | Block edit of `key` field (immutable) and `tenant_can_modify = 0` records | 🟡 |
| FR-TTF-01.4 | Type-aware UI: NUMBER → numeric input, BOOLEAN → toggle, TIME → time picker, JSON → JSON editor | 🟡 |
| FR-TTF-01.5 | Config cache: cache `tt_config` reads (read-heavy, write-rare) | ❌ |

**Key config keys (seeded, system-managed):**

| Key | Default | Description |
|-----|---------|-------------|
| `total_number_of_period_per_day` | 8 | Periods per school day |
| `default_school_open_days_per_week` | 6 | 5 or 6 day week |
| `max_weekly_periods_can_be_allocated_to_teacher` | 8 | Teacher workload cap |
| `min_weekly_periods_can_be_allocated_to_teacher` | 8 | Teacher min load |
| `minimum_student_required_for_class_subgroup` | 10 | Split group threshold |
| `maximum_student_required_for_class_subgroup` | 25 | Split group max |
| `week-start_day` | MONDAY | Day 1 for scheduler |

**Gaps:**
- `ConfigRequest` needs unique-key rule moved from controller into FormRequest
- `scopeByStatus()` queries non-existent `status` column — should query `is_active`
- JSON parsing via `json_decode()` in controller does not throw exceptions; try/catch is misleading

---

### FR-TTF-02: Academic Term Management

**Status:** 🟡 Partial (CRUD works; overlap check missing; auth status unverified)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-02.1 | Create/edit/delete academic terms linked to `sch_academic_sessions` | ✅ |
| FR-TTF-02.2 | term_type ENUM: QUARTER, SEMESTER, ANNUAL, TRIMESTER | ✅ |
| FR-TTF-02.3 | Prevent overlapping date ranges for the same academic session (application-level) | ❌ |
| FR-TTF-02.4 | Soft delete + restore + force-delete | ✅ |
| FR-TTF-02.5 | Toggle active status | ✅ |

**Consumer tables (term-scoped):** `tt_class_timetable_type_jnt`, `tt_requirement_consolidation`, `tt_activity`, `tt_timetable`, `tt_slot_requirement`.

---

### FR-TTF-03: Generation Strategy Management

**Status:** 🟡 Partial (85%; routes in TTF file but controller lives in SmartTimetable module)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-03.1 | CRUD for generation strategy records | ✅ |
| FR-TTF-03.2 | Algorithm types: RECURSIVE, GENETIC, SIMULATED_ANNEALING, TABU_SEARCH, HYBRID | ✅ |
| FR-TTF-03.3 | Toggle default strategy (only one default at a time; application-enforced) | ✅ |
| FR-TTF-03.4 | Parameters: max_recursive_depth, max_placement_attempts, tabu_size, cooling_rate, population_size, generations, timeout_seconds, activity_sorting_method, parameters_json | ✅ |

**Note:** `TtGenerationStrategyController` lives in `Modules\SmartTimetable\Http\Controllers` but is registered in TTF routes — cross-module controller usage. 📐 Proposed: move controller to TTF in V2 refactor.

---

### FR-TTF-04: Shift Management

**Status:** ✅ Implemented (90%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-04.1 | CRUD for school shifts (MORNING, TODDLER, AFTERNOON, EVENING) | ✅ |
| FR-TTF-04.2 | Fields: code (UNIQUE), name (UNIQUE), ordinal (UNIQUE), default_start_time, default_end_time | ✅ |
| FR-TTF-04.3 | Soft delete + restore + toggle status | ✅ |
| FR-TTF-04.4 | FormRequest validation for store/update | ❌ Missing |

**DDL note:** `tt_shift` has UNIQUE keys on `code`, `name`, and `ordinal`. Application must present user-friendly error for duplicate key violations.

---

### FR-TTF-05: Day Type Management

**Status:** ✅ Implemented (90%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-05.1 | CRUD for day types: STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY | ✅ |
| FR-TTF-05.2 | `is_working_day` toggle — determines if timetable periods run on this day type | ✅ |
| FR-TTF-05.3 | `reduced_periods` flag — days with fewer periods (e.g. Sports Day) | ✅ |
| FR-TTF-05.4 | FormRequest validation | ❌ Missing |

---

### FR-TTF-06: Period Type Management

**Status:** ✅ Implemented (90%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-06.1 | CRUD for period types: THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE | ✅ |
| FR-TTF-06.2 | Scheduling flags: `is_schedulable`, `counts_as_teaching`, `counts_as_workload`, `is_break`, `is_free_period` | ✅ |
| FR-TTF-06.3 | Visual fields: `color_code`, `icon` (Font Awesome class) | ✅ |
| FR-TTF-06.4 | `duration_minutes` — stored default; overridden per period slot in period set | ✅ |
| FR-TTF-06.5 | FormRequest validation | ❌ Missing |

---

### FR-TTF-07: Period Set Management

**Status:** 🟡 Partial (85%; generated column handling needs verification)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-07.1 | CRUD for period set header | ✅ |
| FR-TTF-07.2 | Fields: code (UNIQUE), total_periods, teaching_periods, exam_periods, free_periods, assembly_periods, short_break_periods, lunch_break_periods, day_start_time, day_end_time, is_default | ✅ |
| FR-TTF-07.3 | CRUD for period slots within a set (`tt_period_set_period_jnt`) | ✅ |
| FR-TTF-07.4 | `duration_minutes` is a MySQL GENERATED STORED column — application must NOT write it | ✅ |
| FR-TTF-07.5 | CHECK constraint `end_time > start_time` enforced at DB level | ✅ |
| FR-TTF-07.6 | `addPeriodToOrganization` — copy period set to organisation scope | 🟡 |
| FR-TTF-07.7 | FormRequest for period slots (end > start cross-field rule) | ❌ Missing |

**Example period sets:**

| Code | Total | Teaching | Exam | Usage |
|------|-------|----------|------|-------|
| `STANDARD_8P` | 8 | 6 | 0 | Classes 3rd–12th normal day |
| `HALF_DAY_4P` | 4 | 4 | 0 | Half-day schedule |
| `TODDLER_6P` | 6 | 6 | 0 | Nursery/KG |
| `UT1_WITH_6P` | 8 | 6 | 2 | Unit test day |

---

### FR-TTF-08: Working Day & School Day Calendar

**Status:** 🟡 Partial (80%; calendar initialisation present but class-override coverage unclear)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-08.1 | `tt_school_days` — 7-day week reference (Mon–Sun), is_school_day flag | ✅ |
| FR-TTF-08.2 | `tt_working_day` — date-level calendar with up to 4 day types per day | ✅ |
| FR-TTF-08.3 | Calendar initialise: `ajaxInitializeWorkingDays` bulk-creates entries for academic session | ✅ |
| FR-TTF-08.4 | Calendar AJAX feed: `eventFeed` returns FullCalendar-compatible JSON | ✅ |
| FR-TTF-08.5 | AJAX CRUD: `ajaxStore`, `ajaxEdit`, `ajaxDestroy` for inline calendar editing | ✅ |
| FR-TTF-08.6 | Class working day override: `tt_class_working_day_jnt` — per class/section override | 🟡 |
| FR-TTF-08.7 | `ajaxInitialize` for class working days, `workingDayFeed`, `eventFeed` | 🟡 |
| FR-TTF-08.8 | Auto-update `tt_academic_term.term_total_teaching_days` / `term_total_exam_days` / `term_total_working_days` when day type changes | ❌ Not implemented |

**Business constraint:** Multiple day types can apply to the same date (e.g., Exam + Study, PTM + Study). The four `day_type_id` columns on `tt_working_day` support this.

---

### FR-TTF-09: Timetable Type & Class Assignment

**Status:** 🟡 Partial (80%; date-overlap validation missing)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-09.1 | CRUD for timetable types: STANDARD, UNIT_TEST-1, HALF_DAY, HALF_YEARLY, FINAL_EXAM | ✅ |
| FR-TTF-09.2 | Fields: code (UNIQUE), shift_id, effective_from_date, effective_to_date, school_start_time, school_end_time, has_exam, has_teaching, is_default | ✅ |
| FR-TTF-09.3 | CHECK constraint: `school_end_time > school_start_time` AND `effective_from_date <= effective_to_date` | ✅ DDL |
| FR-TTF-09.4 | Prevent overlapping school_start/end times for same shift (application-level) | ❌ |
| FR-TTF-09.5 | Class-timetable-type assignment: link class/section to timetable type for academic term | ✅ |
| FR-TTF-09.6 | `applies_to_all_sections = 1` → section_id must be NULL (DB CHECK enforced) | ✅ DDL |
| FR-TTF-09.7 | Weekly period counts stored: `weekly_teaching_period_count`, `weekly_exam_period_count`, `weekly_free_period_count` | ✅ |
| FR-TTF-09.8 | Prevent overlapping period sets for same class and section (application-level) | ❌ |

---

### FR-TTF-10: Teacher Availability Management

**Status:** 🟡 Partial (70%; per-slot matrix UI completeness unknown)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-10.1 | Create teacher availability master record per teacher per class-subject-study format | 🟡 |
| FR-TTF-10.2 | Workload fields: required_weekly_periods, max/min_available_periods_weekly, max/min_allocated_periods_weekly | 🟡 |
| FR-TTF-10.3 | Preference fields: is_full_time, preferred_shift, certified_for_lab, can_be_used_for_substitution | 🟡 |
| FR-TTF-10.4 | Priority fields: priority_order, priority_weight, scarcity_index, allocation_strictness (Hard/Medium/Soft) | 🟡 |
| FR-TTF-10.5 | GENERATED columns: `available_for_full_timetable_duration`, `no_of_days_not_available` — NOT writable | ✅ DDL |
| FR-TTF-10.6 | Per-slot availability matrix: 7 days × N periods, `can_be_assigned`, `availability_for_period` ENUM | 🟡 |
| FR-TTF-10.7 | `generateTeacherAvailability` — bulk generation from requirement consolidation records | 🟡 |
| FR-TTF-10.8 | Teacher availability log (audit trail of all changes) | 🟡 |
| FR-TTF-10.9 | FormRequest for create/update | ❌ Missing |

**Known issue:** Model class name `TeacherAvailablity` (missing 'i') — typo exists in both filename and class declaration. Must be renamed `TeacherAvailability` across all references.

---

### FR-TTF-11: Room Availability Management

**Status:** 🟡 Partial (65%; completeness of detail matrix uncertain)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-11.1 | Create room availability master record | 🟡 |
| FR-TTF-11.2 | Per-slot room availability matrix (day × period) | 🟡 |
| FR-TTF-11.3 | Room type linking (classroom, lab, sports hall) | 🟡 |
| FR-TTF-11.4 | FormRequest for store/update | ❌ Missing |

---

### FR-TTF-12: Slot Requirement

**Status:** 🟡 Partial (65%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-12.1 | Display slot summary per class-section-timetable-type | 🟡 |
| FR-TTF-12.2 | `generateSlotRequirement` — compute from `tt_class_timetable_type_jnt` + `tt_timetable_type` | 🟡 |
| FR-TTF-12.3 | Fields: weekly_total_slots, weekly_teaching_slots, weekly_exam_slots, weekly_free_slots | ✅ DDL |

---

### FR-TTF-13: Requirement Groups & Subgroups

**Status:** 🟡 Partial (60%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-13.1 | Class requirement groups — subject groupings for elective/optional subjects | 🟡 |
| FR-TTF-13.2 | Class requirement subgroups — subdivisions within groups | 🟡 |
| FR-TTF-13.3 | Sharing flags: `is_shared_across_sections`, `is_shared_across_classes` | 🟡 |
| FR-TTF-13.4 | Class-subject subgroup CRUD (`ClassSubjectSubgroupController`) | 🟡 |
| FR-TTF-13.5 | AJAX: `getSectionsByClass`, `ajaxToggleSharing` | 🟡 |

---

### FR-TTF-14: Requirement Consolidation

**Status:** 🟡 Partial (70%; complex FK management; inline update present)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-14.1 | Display consolidated requirements per class-subject-study format | 🟡 |
| FR-TTF-14.2 | `generateRequirements` — bulk generation from SchoolSetup subject mappings | 🟡 |
| FR-TTF-14.3 | `getRequirementsStats` — summary statistics | ✅ |
| FR-TTF-14.4 | `updateRequirement` and `updatePeriods` — inline editing of key fields | ✅ |
| FR-TTF-14.5 | `ajaxInlineUpdate` — AJAX inline cell editing | ✅ |
| FR-TTF-14.6 | Full CRUD + soft delete + restore | 🟡 |
| FR-TTF-14.7 | FormRequest for store/update | ❌ Missing |

**Key fields:** academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, subject_type, required_room_type, required_room, required_weekly_periods.

---

### FR-TTF-15: Activity Management

**Status:** 🟡 Partial (75%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-15.1 | CRUD for activities (core scheduler entity) | 🟡 |
| FR-TTF-15.2 | Rich eager loading: class, section, subject, teachers, timetable type | 🟡 |
| FR-TTF-15.3 | `generateActivities` — generate from requirement consolidation (single class) | 🟡 |
| FR-TTF-15.4 | `generateAllActivities` — batch generation across all classes | 🟡 |
| FR-TTF-15.5 | `getBatchGenerationProgress` — poll batch progress | 🟡 |
| FR-TTF-15.6 | Activity teacher assignment (ActivityTeacher junction) | 🟡 |
| FR-TTF-15.7 | Sub-activity management (SubActivityService) | 🟡 |
| FR-TTF-15.8 | Activity priority configuration | 🟡 |
| FR-TTF-15.9 | FormRequest for store/update | ❌ Missing |
| FR-TTF-15.10 | Rate limiting on batch generation endpoints | ❌ Missing |

---

### FR-TTF-16: Teacher Assignment Role Master

**Status:** ✅ Implemented (90%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-16.1 | CRUD for assignment roles: PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE | ✅ |
| FR-TTF-16.2 | Role flags: `is_primary_instructor`, `counts_for_workload`, `allows_overlap` | ✅ |
| FR-TTF-16.3 | `workload_factor` (0.25–3.00) for workload calculation weight | ✅ |
| FR-TTF-16.4 | FormRequest validation | ❌ Missing |

---

### FR-TTF-17: Timetable Master Records

**Status:** 🟡 Partial (75%)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-17.1 | CRUD for timetable master record (`tt_timetable` header) | ✅ |
| FR-TTF-17.2 | Status lifecycle: DRAFT → GENERATED → PUBLISHED → ARCHIVED | 🟡 |
| FR-TTF-17.3 | Version management (multiple timetable runs per term) | 🟡 |

---

### FR-TTF-18: Timing Profile Management

**Status:** 🟡 Partial (workaround — SchoolShift model aliased as both TimingProfile and SchoolTimingProfile)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-18.1 | TimingProfile CRUD (`TimingProfileController`) | 🟡 |
| FR-TTF-18.2 | SchoolTimingProfile CRUD (`SchoolTimingProfileController`) | 🟡 |
| FR-TTF-18.3 | Dedicated TimingProfile and SchoolTimingProfile models (currently aliased as SchoolShift in AppServiceProvider lines 189–190) | ❌ Workaround |

---

### FR-TTF-19: Constraint Type Catalog Viewer (NEW)

**Status:** ❌ Not Started | 📐 Proposed in V2

| Sub-FR | Description | Priority |
|--------|-------------|----------|
| FR-TTF-19.1 | Read-only list view of `tt_constraint_type` entries | P2 |
| FR-TTF-19.2 | Filter by is_hard (Hard/Soft constraints), by scope | P2 |
| FR-TTF-19.3 | Display seeded constraint categories and scopes | P2 |

**Note:** `tt_constraint_type` table exists and is seeded by SmartTimetable Stage 2 seeders. No controller exists in TTF to display this catalog.

---

### FR-TTF-20: Temporary Unavailability (NEW)

**Status:** ❌ Not Started | 📐 Proposed in V2

| Sub-FR | Description | Priority |
|--------|-------------|----------|
| FR-TTF-20.1 | `tt_teacher_unavailable` — record teacher absence dates (sick leave, leave etc.) | P2 |
| FR-TTF-20.2 | `tt_room_unavailable` — record room unavailability (maintenance, booking etc.) | P2 |
| FR-TTF-20.3 | Date range input with reason | P2 |
| FR-TTF-20.4 | Integration with SubstitutionService in SmartTimetable | P2 |

**Note:** Tables exist in the DDL schema but no TTF controllers or routes have been created.

---

### FR-TTF-21: Reports Page

**Status:** 🟡 Partial (reads SmartTimetable analytics; completeness unknown)

| Sub-FR | Description | Status |
|--------|-------------|--------|
| FR-TTF-21.1 | Class-wise timetable report | 🟡 |
| FR-TTF-21.2 | Teacher-wise timetable report | 🟡 |
| FR-TTF-21.3 | Room-wise utilisation report | 🟡 |
| FR-TTF-21.4 | Teacher workload summary | 🟡 |

---

## 5. Data Model

### 5.1 Master Tables (Reference Data)

| Table | Engine | Key Columns | Constraints |
|-------|--------|-------------|-------------|
| `tt_config` | InnoDB | key (UNIQUE), value, value_type ENUM(STRING/NUMBER/BOOLEAN/DATE/TIME/DATETIME/JSON), tenant_can_modify, mandatory | UQ on `key`, UQ on `ordinal` |
| `tt_generation_strategy` | InnoDB | code (UNIQUE), algorithm_type ENUM, max_recursive_depth, tabu_size, cooling_rate, population_size, generations, activity_sorting_method, timeout_seconds, parameters_json JSON, is_default | UQ on `code` |
| `tt_shift` | InnoDB | code (UNIQUE), name (UNIQUE), ordinal (UNIQUE), default_start_time, default_end_time | 3 UNIQUE keys |
| `tt_day_type` | InnoDB | code (UNIQUE), name (UNIQUE), ordinal (UNIQUE), is_working_day, reduced_periods | 3 UNIQUE keys |
| `tt_period_type` | InnoDB | code (UNIQUE), ordinal (UNIQUE), is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period, color_code, icon, duration_minutes | 2 UNIQUE keys |
| `tt_teacher_assignment_role` | InnoDB | code (UNIQUE), is_primary_instructor, counts_for_workload, allows_overlap, workload_factor DECIMAL(5,2) | UQ on `code` |
| `tt_school_days` | InnoDB | code (UNIQUE), day_of_week (UNIQUE), ordinal, is_school_day | 2 UNIQUE keys |

### 5.2 Configuration Tables

| Table | Key Columns | Important Constraints |
|-------|-------------|----------------------|
| `tt_period_set` | code (UNIQUE), total_periods, teaching/exam/free/assembly/short_break/lunch_break periods, day_start_time, day_end_time, is_default | UQ on `code` |
| `tt_period_set_period_jnt` | period_set_id, period_ord, code, period_type_id, start_time, end_time, **duration_minutes GENERATED STORED** | UQ(period_set_id, period_ord), UQ(period_set_id, code), CHECK(end_time > start_time), FK→tt_period_set CASCADE DELETE |
| `tt_working_day` | date (UNIQUE), academic_session_id, day_type1_id–day_type4_id, is_school_day, remarks | UQ on `date`; FK×4 to `tt_day_type` ON DELETE RESTRICT |
| `tt_class_working_day_jnt` | academic_session_id, date, class_id, section_id, working_day_id, is_exam_day, is_ptm_day, is_half_day, is_holiday, is_study_day | UQ(class_id, working_day_id) |
| `tt_timetable_type` | code (UNIQUE), shift_id, effective_from_date, effective_to_date, school_start_time, school_end_time, has_exam, has_teaching, is_default | CHECK(school_end_time > school_start_time), CHECK(effective_from_date <= effective_to_date) |
| `tt_class_timetable_type_jnt` | academic_term_id, timetable_type_id, class_id, section_id, period_set_id, applies_to_all_sections, has_teaching, has_exam, weekly_*_period_count | CHECK(section_id IS NULL ↔ applies_to_all_sections=1), FK×5 |

### 5.3 Requirement Tables

| Table | Key Columns | Important Constraints |
|-------|-------------|----------------------|
| `tt_slot_requirement` | academic_term_id, timetable_type_id, class_timetable_type_id, class_id, section_id, class_house_room_id, weekly_total/teaching/exam/free_slots | UQ(timetable_type_id, class_timetable_type_id, class_id, section_id) |
| `tt_class_requirement_groups` | code (UNIQUE), class_group_id, class_id, section_id, subject_id, study_format_id, subject_type_id, student_count, eligible_teacher_count | UQ on code; FK×5 |
| `tt_class_requirement_subgroups` | code (UNIQUE), class_group_id, class_id, section_id, subject_id, is_shared_across_sections, is_shared_across_classes | UQ on code |
| `tt_requirement_consolidation` | academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, required_weekly_periods | Final input to scheduler |

### 5.4 Availability Tables

| Table | Key Columns | Generated Columns |
|-------|-------------|-------------------|
| `tt_teacher_availabilities` | teacher_profile_id, requirement_consolidation_id, max/min_allocated_periods_weekly, allocation_strictness ENUM(Hard/Medium/Soft), priority_weight, scarcity_index, preferred_shift | `available_for_full_timetable_duration` STORED, `no_of_days_not_available` STORED |
| `tt_teacher_availability_details` | teacher_profile_id, day_number (1-7), period_number, can_be_assigned, availability_for_period ENUM | UNIQUE(teacher_profile_id, day_number, period_number) |
| `tt_teacher_availability_logs` | teacher_profile_id, change_date, old/new_value | Audit trail |
| `tt_room_availabilities` | room_id, rooms_type_id | Room availability master |
| `tt_room_availability_details` | room_availability_id, day_number, period_number | Per-slot room availability |

### 5.5 Activity Tables

| Table | Key Columns | Notes |
|-------|-------------|-------|
| `tt_activities` | academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, required_weekly_periods | Core scheduler entity |
| `tt_activity_teachers` | activity_id, teacher_id, assignment_role_id | Multiple teachers per activity |
| `tt_sub_activities` | activity_id (parent ref) | Split-class sub-activities |
| `tt_activity_priorities` | activity_id, priority_level | Placement order control |

### 5.6 Timetable Tables (Managed by TTF, Populated by SmartTimetable)

| Table | Key Columns | Notes |
|-------|-------------|-------|
| `tt_timetables` | academic_term_id, timetable_type_id, status ENUM(DRAFT/GENERATED/PUBLISHED/ARCHIVED), generation_run_id | Timetable header |
| `tt_timetable_cells` | timetable_id, day_number, period_number, class_id, section_id, subject_id, room_id | Individual cell |
| `tt_timetable_cell_teachers` | timetable_cell_id, teacher_id, is_substitute | Teacher-to-cell mapping |

### 5.7 Models (32 total)

| Model | Table | Key Issue |
|-------|-------|-----------|
| `Config` | `tt_config` | `scopeByStatus()` queries non-existent `status` column |
| `AcademicTerm` | `tt_academic_terms` | — |
| `Activity` | `tt_activities` | Central model; 10+ BelongsTo relations |
| `ActivityTeacher` | `tt_activity_teachers` | Junction: activity + teacher + role |
| `ActivityPriority` | `tt_activity_priorities` | — |
| `ClassSubjectGroup` | `tt_class_subject_groups` | — |
| `ClassSubjectSubgroup` | `tt_class_subject_subgroups` | — |
| `ClassSubgroupMember` | `tt_class_subgroup_members` | — |
| `ClassModeRule` | `tt_class_mode_rules` | Needs schema verification |
| `ClassRequirementGroup` | `tt_class_requirement_groups` | — |
| `ClassRequirementSubgroup` | `tt_class_requirement_subgroups` | — |
| `ClassTimetableType` | `tt_class_timetable_types` | — |
| `ClassWorkingDay` | `tt_class_working_day_jnt` | — |
| `DayType` | `tt_day_type` | — |
| `PeriodSet` | `tt_period_sets` | — |
| `PeriodSetPeriod` | `tt_period_set_periods` | duration_minutes must be in `$guarded` |
| `PeriodType` | `tt_period_types` | — |
| `RequirementConsolidation` | `tt_requirement_consolidations` | — |
| `RoomAvailability` | `tt_room_availabilities` | — |
| `RoomAvailabilityDetail` | `tt_room_availability_details` | — |
| `SchoolDay` | `tt_school_days` | — |
| `SchoolShift` | `tt_shift` | Aliased as TimingProfile AND SchoolTimingProfile in AppServiceProvider |
| `SlotRequirement` | `tt_slot_requirements` | — |
| `SubActivity` | `tt_sub_activities` | — |
| `TeacherAssignmentRole` | `tt_teacher_assignment_roles` | — |
| **`TeacherAvailablity`** | `tt_teacher_availabilities` | **TYPO in class name** — should be `TeacherAvailability` |
| `TeacherAvailabilityLog` | `tt_teacher_availability_logs` | — |
| `Timetable` | `tt_timetables` | — |
| `TimetableCell` | `tt_timetable_cells` | — |
| `TimetableCellTeacher` | `tt_timetable_cell_teachers` | — |
| `TimetableType` | `tt_timetable_types` | — |
| `WorkingDay` | `tt_working_days` | — |

---

## 6. API Endpoints & Routes

### 6.1 Route Configuration

| Attribute | Value |
|-----------|-------|
| Route file | `Modules/TimetableFoundation/Routes/web.php` (280 lines) |
| Registered by | `RouteServiceProvider` — prefix `timetable-foundation`, name prefix `timetable-foundation.*` |
| Base middleware | `auth`, `verified` |
| EnsureTenantHasModule | **MISSING** — P0 critical gap |

**Required fix:** Wrap all routes in a single group:
```php
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:TimetableFoundation'])
    ->prefix('timetable-foundation')
    ->name('timetable-foundation.')
    ->group(function () { /* all routes */ });
```

### 6.2 Menu Page Routes

| Method | URI | Controller@Method | EnsureTenantHasModule | Status |
|--------|-----|-------------------|-----------------------|--------|
| GET | `pre-requisites-setup` | `TimetableFoundationController@preRequisitesSetup` | ❌ | ✅ |
| GET | `timetable-configuration` | `TimetableFoundationController@timetableConfiguration` | ❌ | ✅ |
| GET | `timetable-masters` | `TimetableFoundationController@timetableMasters` | ❌ | ✅ |
| GET | `timetable-requirement` | `TimetableFoundationController@timetableRequirement` | ❌ | ✅ |
| POST | `generate-class-groups` | `TimetableFoundationController@generateClassGroups` | ❌ | ✅ |
| GET | `resource-availability` | `TimetableFoundationController@resourceAvailability` | ❌ | ✅ |
| GET | `timetable-preparation` | `TimetableFoundationController@timetablePreparation` | ❌ | ✅ |
| GET | `reports-and-logs` | `TimetableFoundationController@reportsAndLogs` | ❌ | ✅ |

### 6.3 Config Routes

| Method | URI Pattern | Controller@Method | Auth Gate | EnsureTenantHasModule | Status |
|--------|-------------|-------------------|-----------|-----------------------|--------|
| GET/POST | `config` (resource) | `ConfigController` | `config.viewAny` / `config.create` | ❌ | ✅ |
| GET | `config/trash/view` | `@trashed` | — | ❌ | ✅ |
| GET | `config/{id}/restore` | `@restore` | — | ❌ | ✅ |
| DELETE | `config/{id}/force-delete` | `@forceDelete` | — | ❌ | ✅ |
| POST | `config/{config}/toggle-status` | `@toggleStatus` | — | ❌ | ✅ |

### 6.4 Academic Term Routes

| Method | URI Pattern | Controller@Method | Status |
|--------|-------------|-------------------|--------|
| GET/POST/PUT/DELETE | `academic-term` (resource) | `AcademicTermController` | ✅ |
| GET | `academic-term/trash/view` | `@trashed` | ✅ |
| GET/DELETE/POST | restore, force-delete, toggle-status | `AcademicTermController` | ✅ |

### 6.5 Timetable Masters Routes (Grouped)

| Route Group | URI Prefix | Controller | CRUD | Extras |
|-------------|-----------|-----------|------|--------|
| Shift | `shift` | `SchoolShiftController` | Full | trashed/restore/forceDelete/toggleStatus |
| Day Type | `day-type` | `DayTypeController` | Full | trashed/restore/forceDelete/toggleStatus |
| Period Type | `period-type` | `PeriodTypeController` | Full | trashed/restore/forceDelete/toggleStatus |
| School Day | `school-day` | `SchoolDayController` | Full | trashed/restore/forceDelete/toggleStatus |
| Period Set | `period-set` | `PeriodSetController` | Full | trashed/restore/forceDelete/toggleStatus |
| Period Slot | `period-set-period` | `PeriodSetPeriodController` | Full | trashed/restore/forceDelete/toggleStatus/addPeriodToOrganization |
| Timetable Type | `timetable-type` | `TimetableTypeController` | Full | trashed/restore/forceDelete/toggleStatus |
| Class Timetable | `class-timetable` | `ClassTimetableTypeController` | Full | trashed/restore/forceDelete/toggleStatus |
| Teacher Role | `teacher-assignment-role` | `TeacherAssignmentRoleController` | Full | trashed/restore/forceDelete/toggleStatus |
| Timing Profile | `timing-profile` | `TimingProfileController` | Full | trashed/restore/forceDelete/toggleStatus |
| School Timing | `school-timing-profile` | `SchoolTimingProfileController` | Full | trashed/restore/forceDelete/toggleStatus |

### 6.6 Working Day Routes (AJAX)

| Method | URI | Controller@Method | Auth Verified | Status |
|--------|-----|-------------------|---------------|--------|
| POST | `working-day/ajax/store` | `WorkingDayController@ajaxStore` | 🟡 Needs verification | ✅ |
| POST | `working-day/ajax/edit` | `WorkingDayController@ajaxEdit` | 🟡 | ✅ |
| DELETE | `working-day/ajax/delete/{id}` | `WorkingDayController@ajaxDestroy` | 🟡 | ✅ |
| POST | `working-day/ajax/initialize-calander` | `WorkingDayController@ajaxInitializeWorkingDays` | 🟡 | ✅ |
| GET | `working-day/ajax/events` | `WorkingDayController@eventFeed` | 🟡 | ✅ |
| Full resource | `working-day` | `WorkingDayController` | — | ✅ |

**Note:** Working day AJAX routes must precede `Route::resource` to prevent wildcard capture.

### 6.7 Availability Routes

| Method | URI Pattern | Controller@Method | Extras | Status |
|--------|-------------|-------------------|--------|--------|
| Full resource | `teacher-availability` | `TeacherAvailabilityController` | trashed/restore/forceDelete/toggleStatus | 🟡 |
| POST | `teacher-availability/generate` | `@generateTeacherAvailability` | — | 🟡 |
| GET/PUT/DELETE | `teacher-availability-log/{id}` (show/edit/update/destroy) | `TeacherAvailabilityLogController` | trashed/restore/forceDelete/toggleStatus | 🟡 |
| Full resource | `room-availability` | `RoomAvailabilityController` | trashed/restore/forceDelete/toggleStatus | 🟡 |

### 6.8 Requirement & Activity Routes

| Method | URI Pattern | Controller@Method | Extras | Status |
|--------|-------------|-------------------|--------|--------|
| Full resource | `requirement-consolidation` | `RequirementConsolidationController` | trashed/restore/forceDelete/toggleStatus | 🟡 |
| POST | `requirement-consolidation/generate-requirements/generate` | `@generateRequirements` | — | 🟡 |
| GET | `requirement-consolidations/stats` | `@getRequirementsStats` | — | ✅ |
| POST | `class-subject-requirement/update` | `@updateRequirement` | — | ✅ |
| POST | `class-subject-requirement/update-periods` | `@updatePeriods` | — | ✅ |
| POST | `requirement-consolidation/ajax/inline-update/{id}` | `@ajaxInlineUpdate` | — | ✅ |
| Full resource | `slot-requirement` | `SlotRequirementController` | toggleStatus | 🟡 |
| POST | `slot-requirement/generate` | `@generateSlotRequirement` | — | 🟡 |
| Full resource | `activity` | `ActivityController` | trashed/restore/forceDelete/toggleStatus | 🟡 |
| POST | `requirements/generate-activities/all` | `ActivityController@generateActivities` | — | 🟡 |
| POST | `class-group-requirements/generate-all` | `ActivityController@generateAllActivities` | — | 🟡 |
| GET | `class-group-requirements/generation-progress` | `ActivityController@getBatchGenerationProgress` | — | 🟡 |

### 6.9 Class Subgroup Routes

| Method | URI Pattern | Controller@Method | Status |
|--------|-------------|-------------------|--------|
| Full resource | `class-subject-subgroup` (named `class-subgroup.*`) | `ClassSubjectSubgroupController` | 🟡 |
| GET | `class-subject-subgroup/{class}/get/sections` | `@getSectionsByClass` | 🟡 |
| POST | `class-subject-subgroup/ajax/toggle-sharing/{id}` | `@ajaxToggleSharing` | 🟡 |
| Full resource | `class-working-day` | `ClassWorkingDayController` | 🟡 |
| POST/DELETE/GET | AJAX: ajaxStore/ajaxDestroy/ajaxInitialize/eventFeed/workingDayFeed | `ClassWorkingDayController` | 🟡 |

### 6.10 Cross-Module Route Entries

| Route | External Controller | Module | Issue |
|-------|---------------------|--------|-------|
| `generation-strategies` (resource) | `TtGenerationStrategyController` | SmartTimetable | Cross-module controller in TTF routes |
| `class-subject-group/generate-class-groups` | `ClassSubjectGroupController` | SchoolSetup | Cross-module controller in TTF routes |
| `class-subject-subgroup/update-sharing` | `ClassSubjectGroupController` | SchoolSetup | Cross-module controller in TTF routes |

**Note:** Double-registration risk — TTF module routes AND `routes/tenant.php` (lines 140–162) may register the same controllers via `Foundation*` aliases.

### 6.11 Route Summary

| Category | Count | EnsureTenantHasModule |
|----------|-------|-----------------------|
| Menu pages | 8 | ❌ All missing |
| Config | 5 | ❌ |
| Academic Term | 5 | ❌ |
| Timetable Masters (11 groups × ~5) | ~55 | ❌ All missing |
| Working Day (AJAX + resource) | ~10 | ❌ |
| Availability (teacher + room + log) | ~15 | ❌ |
| Requirement + Activity | ~18 | ❌ |
| Subgroups + Class Working Days | ~15 | ❌ |
| Cross-module (generation strategy, class groups) | ~7 | ❌ |
| **TOTAL** | **~138** | **0 protected** |

---

## 7. UI Screens

### 7.1 Screen Inventory

| Screen | Route Name | Page | Implementation |
|--------|-----------|------|----------------|
| Pre-Requisites Setup | `timetable-foundation.menu.preRequisitesSetup` | 1 | ✅ |
| Timetable Configuration | `timetable-foundation.menu.timetableConfiguration` | 2 | ✅ |
| Timetable Masters | `timetable-foundation.menu.timetableMasters` | 3 | ✅ |
| Timetable Requirement | `timetable-foundation.menu.timetableRequirement` | 4 | ✅ |
| Resource Availability | `timetable-foundation.menu.resourceAvailability` | 5 | 🟡 |
| Timetable Preparation | `timetable-foundation.menu.timetablePreparation` | 6 | 🟡 |
| Reports & Logs | `timetable-foundation.menu.reportsAndLogs` | 7 | 🟡 |

### 7.2 Page 1 — Pre-Requisites Setup

Read-only display of SchoolSetup + StaffProfile data. No mutations in TTF — links/redirects to respective modules.

| Tab | Source Module | Data Shown |
|-----|--------------|------------|
| Buildings | SchoolSetup | Building list |
| Room Types | SchoolSetup | Room type catalog |
| Rooms | SchoolSetup | Room list with capacity, type |
| Teacher Profiles | StaffProfile | Teacher list with subjects |
| Class & Section | SchoolSetup | Class hierarchy |
| Subjects & Study Formats | SchoolSetup | Subject catalog |
| School Class Groups | SchoolSetup | Class groups via `ClassSubjectGroupController` |

### 7.3 Page 2 — Timetable Configuration

| Tab | Component | Status |
|-----|-----------|--------|
| Timetable Config | Config key-value table; inline edit for `tenant_can_modify=1` | 🟡 |
| Academic Terms | CRUD with date range, term_type | ✅ |
| Generation Strategy | CRUD; toggle default; algorithm parameters | ✅ |

### 7.4 Page 3 — Timetable Masters

Multi-tab page with 10 master-data sections. All use standard DataTable + modal CRUD pattern.

### 7.5 Page 4 — Timetable Requirement

| Tab | Component | Status |
|-----|-----------|--------|
| Slot Requirement | Summary grid with generateSlotRequirement | 🟡 |
| Class Requirement Groups | Group CRUD | 🟡 |
| Class Requirement Sub-Groups | Subgroup CRUD | 🟡 |
| Requirement Consolidation | Main consolidation table; bulk generate; inline edit | 🟡 |

### 7.6 Page 5 — Resource Availability

| Tab | Component | Status |
|-----|-----------|--------|
| Teachers Availability | Master record + 7×N slot matrix | 🟡 |
| Teachers Availability Log | Audit log table (read-only) | 🟡 |
| Rooms Availability | Room slot matrix | 🟡 |

### 7.7 Page 6 — Timetable Preparation

| Tab | Component | Status |
|-----|-----------|--------|
| Activities | Activity CRUD; bulk generate; batch progress | 🟡 |
| Sub-Activities | Sub-activity CRUD | 🟡 |
| Activity Teacher Mapping | Teacher assignment to activities | 🟡 |

### 7.8 Page 7 — Reports & Logs

Reads analytics from SmartTimetable `AnalyticsService`. Displays class/teacher/room timetable grids and workload/utilisation summaries.

---

## 8. Business Rules

| Rule ID | Rule | DB Enforcement | App Enforcement | Status |
|---------|------|----------------|-----------------|--------|
| BR-TTF-01 | Period slot `end_time > start_time` | CHECK `chk_psp_time` on `tt_period_set_period_jnt` | FormRequest cross-field rule needed | 🟡 |
| BR-TTF-02 | `tt_timetable_type` school start/end times must not overlap for the same shift | None | Application-level check | ❌ |
| BR-TTF-03 | `duration_minutes` on `tt_period_set_period_jnt` is GENERATED STORED — never write | MySQL generated column | Must not appear in `$fillable` | 🟡 |
| BR-TTF-04 | `tt_class_timetable_type_jnt`: `section_id IS NULL ↔ applies_to_all_sections = 1` | CHECK `chk_cttj_apply_to_all_section` | FormRequest conditional rule | 🟡 |
| BR-TTF-05 | Academic terms must not have overlapping date ranges for the same session | None | Application-level check | ❌ |
| BR-TTF-06 | Only one `tt_generation_strategy.is_default = 1` at a time | No DB UNIQUE constraint | Toggle logic in controller | 🟡 |
| BR-TTF-07 | `available_for_full_timetable_duration` is GENERATED STORED — never write | MySQL generated column | Must not be in `$fillable` | 🟡 |
| BR-TTF-08 | `no_of_days_not_available` is GENERATED STORED — never write | MySQL generated column | Must not be in `$fillable` | 🟡 |
| BR-TTF-09 | `tt_period_set.is_default = 1` should be unique | No DB constraint | Application-enforced | 🟡 |
| BR-TTF-10 | Teacher availability detail: UNIQUE per (teacher_profile_id, day_number, period_number) | UQ key on `tt_teacher_availability_details` | Handle DB duplicate key gracefully | 🟡 |
| BR-TTF-11 | `tt_config` keys with `tenant_can_modify = 0` are system-managed; tenants cannot edit | None | Gate check + UI read-only | 🟡 |
| BR-TTF-12 | `tt_working_day` triggers: update `tt_academic_term.term_total_*_days` when day type changes | No DB trigger defined | Application observer/event | ❌ |
| BR-TTF-13 | Period set overlap for same class+section must be prevented | No DB constraint | Application-level check | ❌ |
| BR-TTF-14 | `tt_shift` code, name, and ordinal are all UNIQUE — user-friendly error for duplicate violations | DB UNIQUE key | Catch unique violation in controller | 🟡 |
| BR-TTF-15 | Activities are term-scoped — changing academic term requires re-generating activities | No constraint | Application workflow | 📐 |

---

## 9. Workflows

### 9.1 TTF Setup Workflow (Pre-Generation Checklist)

```
Step 1: School Setup (SchoolSetup module)
    ├─ Buildings, Room Types, Rooms
    ├─ Classes, Sections
    └─ Subjects, Study Formats

Step 2: Timetable Configuration (TTF Page 2)
    ├─ Set tt_config values
    ├─ Create Academic Term(s)
    └─ Select/create Generation Strategy

Step 3: Timetable Masters (TTF Page 3)
    ├─ Create Shifts (MORNING etc.)
    ├─ Create Day Types (STUDY, HOLIDAY etc.)
    ├─ Create Period Types (TEACHING, BREAK etc.)
    ├─ Create Period Sets (STANDARD_8P etc.)
    ├─ Add Period Slots to each Set (with times)
    ├─ Create Timetable Types (STANDARD etc.)
    ├─ Assign Class-Timetable-Types per class/term
    └─ Initialise Working Day Calendar

Step 4: Timetable Requirement (TTF Page 4)
    ├─ Generate Slot Requirements
    ├─ Generate Requirement Groups (from SchoolSetup class groups)
    └─ Generate Requirement Consolidation records

Step 5: Resource Availability (TTF Page 5)
    ├─ Generate Teacher Availability (from req. consolidation)
    ├─ Edit per-slot availability matrix if needed
    └─ Set Room Availability

Step 6: Timetable Preparation (TTF Page 6)
    ├─ Generate Activities (from req. consolidation)
    ├─ Assign Teachers to Activities
    └─ Configure Sub-Activities if needed

Ready → SmartTimetable can now generate
```

### 9.2 Calendar Initialisation Workflow

```
User opens Page 3 → Working Days tab
→ Click "Initialize Calendar" for academic session
→ ajaxInitializeWorkingDays POST
→ Bulk-creates tt_working_day records for full academic session date range
→ Default: weekdays = STUDY, weekends = HOLIDAY
→ User edits individual dates on FullCalendar interface
→ AJAX edit/store/delete on individual dates
→ System should auto-update tt_academic_term.term_total_* counters [MISSING]
```

### 9.3 Requirement Consolidation Generation Workflow

```
User clicks "Generate Requirements"
→ RequirementConsolidationController@generateRequirements POST
→ Reads class-subject-study format mappings from SchoolSetup
→ Reads academic_term_id + timetable_type_id from user selection
→ Creates tt_requirement_consolidation records (one per class-subject-studyformat)
→ User reviews; can inline-edit required_weekly_periods per record
→ User proceeds to generate Activities from these records
```

### 9.4 Activity Generation Workflow

```
Single class: ActivityController@generateActivities POST
Batch (all classes): ActivityController@generateAllActivities POST → background
  → Poll: ActivityController@getBatchGenerationProgress GET (AJAX)
  → Creates tt_activity records from tt_requirement_consolidation
  → User assigns teachers to activities (ActivityTeacher mapping)
  → Activities are ready for SmartTimetable to consume
```

### 9.5 Teacher Availability Generation Workflow

```
User clicks "Generate Teacher Availability"
→ TeacherAvailabilityController@generateTeacherAvailability POST
→ Creates tt_teacher_availabilities record for each teacher-activity combination
→ Default: all slots available (7 days × N periods)
→ User edits specific slots to mark unavailable
→ Logged to tt_teacher_availability_logs for audit
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Requirement | Target | Current Status |
|-------------|--------|----------------|
| Page 3 (Masters) load time | < 800ms | 🟡 No eager loading verification |
| Page 6 (Activities) load with 200 activities + 10 relations | < 1,500ms | 🟡 |
| `generateAllActivities` batch (50 classes) | Async/queued | 🟡 Progress polling exists |
| `tt_config` reads | Cached (Redis/file) | ❌ No caching |
| Teacher availability matrix (50 teachers × 56 slots) | < 200ms | 🟡 Indexed on (teacher_profile_id, day_number, period_number) |
| Route resolution for 138 routes | < 10ms | ❌ No route caching mentioned |

### 10.2 Security

| Requirement | Target | Status |
|-------------|--------|--------|
| `EnsureTenantHasModule` on all routes | 100% coverage | ❌ 0% — P0 critical |
| Gate::authorize on all controller methods | 100% | 🟡 ~50% verified |
| FormRequest on all mutation endpoints | 100% | ❌ ~17% |
| CSRF protection on AJAX routes | Yes | 🟡 Standard Laravel CSRF; verify on DELETE AJAX |
| Rate limiting on batch generation | Yes | ❌ Missing |
| SQL injection protection | ORM | ✅ Eloquent used |
| Unauthorized cross-tenant data access | Tenancy isolation | ✅ stancl/tenancy row-level isolation |

### 10.3 Data Integrity

| Requirement | Enforcement |
|-------------|-------------|
| Generated columns not writable | MySQL enforces; must not be in `$fillable` |
| Period time ordering (`end > start`) | DB CHECK constraint |
| Timetable type time ordering | DB CHECK constraint |
| Class timetable section rule | DB CHECK constraint |
| Shift/DayType uniqueness | DB UNIQUE keys |
| Teacher availability slot uniqueness | DB UNIQUE key on (teacher_profile_id, day_number, period_number) |

### 10.4 Scalability

| Entity | Expected Volume | Index Strategy |
|--------|----------------|----------------|
| tt_config | 14 rows (seeded) | UNIQUE on key, ordinal |
| tt_working_day | ~365 rows/year/tenant | UNIQUE on date |
| tt_period_set_period_jnt | ~100 rows (10 sets × 10 slots) | UNIQUE(set_id, ord) |
| tt_teacher_availability_details | 56 × N teachers | UNIQUE(teacher_id, day_number, period_number) |
| tt_activities | ~300 rows per term | FK indexes on class_id, section_id, term_id |
| tt_requirement_consolidation | ~300 rows per term | FK indexes |

---

## 11. Dependencies

### 11.1 Inbound (TTF consumes from)

| Module | Data Consumed | Tables Read |
|--------|--------------|-------------|
| `SchoolSetup` | Classes, Sections, Subjects, Study Formats, Rooms, Room Types, Buildings | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_rooms`, `sch_room_types` |
| `StaffProfile` | Teacher profiles | `sch_teachers` (or staff profile table) |
| `GlobalMaster` | Academic sessions | `sch_academic_sessions` (or global view) |
| `SmartTimetable` | Generation strategy controller (`TtGenerationStrategyController`) | Cross-module controller reference |

### 11.2 Outbound (TTF produces for)

| Module | Data Produced | Key Tables |
|--------|--------------|------------|
| `SmartTimetable` | All configuration for generation | All `tt_*` tables |
| `StandardTimetable` | Period set and type context | `tt_period_set`, `tt_period_type`, `tt_timetable_type` |
| `TimetableApiController` | REST API reads activities + availability | `tt_activities`, `tt_teacher_availabilities`, `tt_period_sets` |
| `Syllabus` | Academic term alignment | `tt_academic_terms` |

### 11.3 Middleware Dependencies

| Middleware | Provider | Usage |
|-----------|----------|-------|
| `auth` | Laravel | All routes |
| `verified` | Laravel | All routes |
| `EnsureTenantHasModule:TimetableFoundation` | Prime-AI custom | **Missing — must add** |
| `Gate::authorize(...)` | Spatie Permissions + Laravel | Per controller method |

---

## 12. Test Scenarios

### 12.1 Existing Tests (7 files)

| File | Type | Focus | Coverage Estimate |
|------|------|-------|------------------|
| `tests/Feature/RouteAuthenticationTest.php` | Feature | Routes require auth | 🟡 |
| `tests/Unit/ControllerAuthTest.php` | Unit | Gate::authorize present | 🟡 |
| `tests/Unit/FormRequestValidationTest.php` | Unit | FormRequest rules | 🟡 (only 4 FRQs tested) |
| `tests/Unit/ModelStructureTest.php` | Unit | Model fillable/casts/relationships | 🟡 |
| `tests/Unit/PolicyTest.php` | Unit | Policy method existence | 🟡 |
| `tests/Unit/ServiceTest.php` | Unit | Service method behavior | 🟡 |
| `tests/Pest.php` | Config | Pest configuration | N/A |

### 12.2 Priority Missing Tests

| Test ID | Scenario | Priority | Type |
|---------|----------|----------|------|
| TST-TTF-01 | `EnsureTenantHasModule` blocks unlicensed tenant from all 138 routes | P0 | Feature |
| TST-TTF-02 | Period slot `end_time > start_time` DB constraint raises error on violation | P1 | Feature |
| TST-TTF-03 | `duration_minutes` GENERATED column is not in fillable; write attempt raises error | P1 | Unit |
| TST-TTF-04 | `available_for_full_timetable_duration` GENERATED column is not in fillable | P1 | Unit |
| TST-TTF-05 | Class timetable type `applies_to_all_sections ↔ section_id` check constraint | P1 | Feature |
| TST-TTF-06 | Teacher availability slot UNIQUE constraint handled gracefully (duplicate insert) | P1 | Feature |
| TST-TTF-07 | Academic term overlap detection (same session, overlapping dates) | P1 | Feature |
| TST-TTF-08 | `ConfigController` — tenant_can_modify=0 record cannot be updated by tenant | P1 | Feature |
| TST-TTF-09 | `generateActivities` creates correct `tt_activity` records from `tt_requirement_consolidation` | P1 | Feature |
| TST-TTF-10 | `generateRequirements` creates correct `tt_requirement_consolidation` records | P1 | Feature |
| TST-TTF-11 | Working day initialise creates entries for full academic session date range | P2 | Feature |
| TST-TTF-12 | `ajaxStore` / `ajaxEdit` AJAX endpoints require auth | P2 | Feature |
| TST-TTF-13 | Batch activity generation (`generateAllActivities`) completes without timeout | P2 | Feature |
| TST-TTF-14 | Timetable type school time overlap validation (same shift) | P2 | Feature |
| TST-TTF-15 | Policy authorization: all 24 policies correctly registered and callable | P2 | Unit |
| TST-TTF-16 | `Config::scopeByStatus()` uses `is_active` not `status` column | P2 | Unit |

---

## 13. Glossary

| Term | Definition |
|------|------------|
| Activity | The central scheduling entity: one class-subject-teacher combination requiring N periods/week that the scheduler must place into time slots |
| Academic Term | A scoped time window within an academic session (Quarter 1, Semester 1, Annual) — all timetable data is term-scoped |
| Day Type | Classification of a school day: STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY |
| GENERATED STORED column | MySQL column whose value is auto-computed by the DB engine; the application must never write to it |
| Period Set | A named template defining the ordered sequence of periods/breaks for a school day (e.g., STANDARD_8P = 8 periods) |
| Period Slot | An individual time slot within a period set — has start_time, end_time, period_type; `duration_minutes` is GENERATED |
| Period Type | Classification of a period: THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE |
| Requirement Consolidation | The normalised, final requirement record per class-subject-studyformat that the scheduler consumes; one record = one "line item" for FET solver |
| Shift | The time window in which a school operates: MORNING, TODDLER, AFTERNOON, EVENING |
| Slot Requirement | Computed summary of total available teaching/exam/free slots per class-timetable-type per term |
| Standard Timetable | A view-only rendering of the generated timetable (managed by StandardTimetableController in SmartTimetable module) |
| Timetable Type | The mode of scheduling (STANDARD, UNIT_TEST-1, HALF_DAY, HALF_YEARLY, FINAL_EXAM) — determines which period set and what activities run |
| `EnsureTenantHasModule` | Custom middleware in Prime-AI that checks the current tenant has licensed and enabled the specified module before granting route access |
| Teacher Assignment Role | The role a teacher plays in an activity: PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE |
| Working Day | A date-level record in the school calendar specifying what type of day it is (can have up to 4 day types simultaneously) |

---

## 14. Suggestions (V2 Improvements)

### 14.1 P0 — Must Fix Before Production

| Suggestion ID | Suggestion | Effort | Impact |
|---------------|-----------|--------|--------|
| SUG-TTF-01 | Add `EnsureTenantHasModule:TimetableFoundation` to a single top-level route group wrapping all 138 routes in `web.php` | 2 h | Critical security |
| SUG-TTF-02 | Fix `TeacherAvailablity` → `TeacherAvailability` model typo using search-and-replace across all files in both repos | 3 h | Prevents import errors |

### 14.2 P1 — High Priority

| Suggestion ID | Suggestion | Effort | Impact |
|---------------|-----------|--------|--------|
| SUG-TTF-03 | Create FormRequests for the 20 controllers missing them: priority order — `WorkingDayRequest`, `ActivityRequest`, `RequirementConsolidationRequest`, `TeacherAvailabilityRequest`, `PeriodSetRequest`, `PeriodSlotRequest`, then remaining 14 | 16–20 h | Input validation |
| SUG-TTF-04 | Audit and verify `Gate::authorize()` calls on all 24 controllers' methods; add missing checks | 8 h | Authorization |
| SUG-TTF-05 | Register all 24 policies in AppServiceProvider via `Gate::policy()` (currently ~19 are dead code) | 3 h | Authorization |
| SUG-TTF-06 | Fix `Config::scopeByStatus()` to query `is_active` instead of non-existent `status` column | 0.5 h | Bug fix |
| SUG-TTF-07 | Fix `ConfigController::store()` — move inline unique-key check and boolean field handling into `ConfigRequest` | 2 h | Code quality |
| SUG-TTF-08 | Resolve double route registration: remove TTF controller references from central `routes/tenant.php` lines 140–162 | 2 h | Architecture |

### 14.3 P2 — Medium Priority

| Suggestion ID | Suggestion | Effort | Impact |
|---------------|-----------|--------|--------|
| SUG-TTF-09 | Create dedicated `TimingProfile` and `SchoolTimingProfile` models; remove AppServiceProvider alias workaround (lines 189–190) | 4 h | Architecture |
| SUG-TTF-10 | Extract `WorkingDayService` (AJAX calendar logic), `RequirementConsolidationService` (generation logic), `ActivityGenerationService` (batch activity generation) | 12 h | Architecture |
| SUG-TTF-11 | Add `tt_config` caching using Laravel cache (Redis/file); cache on first read, invalidate on update | 3 h | Performance |
| SUG-TTF-12 | Add `ConstraintTypeController` (read-only) to TTF so Timetable Managers can view the constraint catalog from TTF UI | 4 h | Feature gap |
| SUG-TTF-13 | Add `TeacherUnavailableController` and `RoomUnavailableController` for temporary unavailability (tables exist in DDL but no controllers) | 8 h | Feature gap |
| SUG-TTF-14 | Add application-level validation for overlapping `tt_timetable_type` school start/end times per shift | 2 h | Data integrity |
| SUG-TTF-15 | Add application-level validation for overlapping academic term date ranges per session | 2 h | Data integrity |
| SUG-TTF-16 | Add rate limiting middleware on batch generation endpoints (`generateAllActivities`, `generateRequirements`) | 1 h | Performance |
| SUG-TTF-17 | Implement `tt_academic_term` counter updates (teaching/exam/working days) when working day type changes — use Eloquent Observer on `WorkingDay` model | 4 h | Business logic |

### 14.4 P3 — Low Priority

| Suggestion ID | Suggestion | Effort | Impact |
|---------------|-----------|--------|--------|
| SUG-TTF-18 | Move `TtGenerationStrategyController` from SmartTimetable module into TimetableFoundation to eliminate cross-module controller dependency | 3 h | Architecture |
| SUG-TTF-19 | Move `ClassSubjectGroupController` route entries from TTF `web.php` into SchoolSetup module routes; TTF calls via redirect or API | 2 h | Architecture |
| SUG-TTF-20 | Add integration tests for full TTF setup workflow (Steps 1–6 in Section 9.1) | 12 h | Test coverage |
| SUG-TTF-21 | Verify all 32 models have: correct `$fillable`, `$casts`, `SoftDeletes` trait, and match DDL column names | 6 h | Data integrity |

---

## 15. Appendices

### 15.1 FormRequests — Current vs Required

| Controller | FormRequest | Status |
|-----------|-------------|--------|
| `ConfigController` | `ConfigRequest` | ✅ Exists |
| `AcademicTermController` | `AcademicTermRequest` | ✅ Exists |
| `SchoolTimingProfileController` | `SchoolTimingProfileRequest` | ✅ Exists |
| `TimingProfileController` | `TimingProfileRequest` | ✅ Exists |
| `WorkingDayController` | `WorkingDayRequest` | ❌ Missing |
| `ActivityController` | `ActivityRequest` | ❌ Missing |
| `RequirementConsolidationController` | `RequirementConsolidationRequest` | ❌ Missing |
| `TeacherAvailabilityController` | `TeacherAvailabilityRequest` | ❌ Missing |
| `PeriodSetController` | `PeriodSetRequest` | ❌ Missing |
| `PeriodSetPeriodController` | `PeriodSlotRequest` (with end > start cross-field) | ❌ Missing |
| `RoomAvailabilityController` | `RoomAvailabilityRequest` | ❌ Missing |
| `TimetableTypeController` | `TimetableTypeRequest` | ❌ Missing |
| `ClassTimetableTypeController` | `ClassTimetableTypeRequest` | ❌ Missing |
| `SlotRequirementController` | `SlotRequirementRequest` | ❌ Missing |
| `ClassWorkingDayController` | `ClassWorkingDayRequest` | ❌ Missing |
| `DayTypeController` | `DayTypeRequest` | ❌ Missing |
| `PeriodTypeController` | `PeriodTypeRequest` | ❌ Missing |
| `SchoolDayController` | `SchoolDayRequest` | ❌ Missing |
| `SchoolShiftController` | `ShiftRequest` | ❌ Missing |
| `TeacherAssignmentRoleController` | `TeacherAssignmentRoleRequest` | ❌ Missing |
| `ClassSubjectSubgroupController` | `ClassSubjectSubgroupRequest` | ❌ Missing |
| `TimetableController` | `TimetableRequest` | ❌ Missing |
| `TimetableTypeController` | `TimetableTypeRequest` | ❌ Missing |
| `TeacherAvailabilityLogController` | `TeacherAvailabilityLogRequest` | ❌ Missing |

**Summary: 4 of 24 controllers have FormRequests (17%).**

### 15.2 Policy Registration Status

| Policy | Model | Registered |
|--------|-------|------------|
| `TimetableConfigPolicy` | `Config` | ✅ ~line 406 |
| `TimingProfilePolicy` | `SchoolShift` (alias) | ✅ line 653 |
| `SchoolTimingProfilePolicy` | `SchoolShift` (alias) | ✅ line 654 |
| `DayPolicy` | `SchoolDay` | ✅ line 652 |
| `PeriodPolicy` | `PeriodSetPeriod` | ✅ line 651 |
| `AcademicTermPolicy` | `AcademicTerm` | ❌ Not registered |
| `ActivityPolicy` | `Activity` | ❌ Not registered |
| `ClassSubgroupPolicy` | `ClassSubjectSubgroup` | ❌ Not registered |
| `ClassTimetableTypePolicy` | `ClassTimetableType` | ❌ Not registered |
| `ClassWorkingDayPolicy` | `ClassWorkingDay` | ❌ Not registered |
| `DayTypePolicy` | `DayType` | ❌ Not registered |
| `PeriodSetPolicy` | `PeriodSet` | ❌ Not registered |
| `PeriodTypePolicy` | `PeriodType` | ❌ Not registered |
| `RequirementConsolidationPolicy` | `RequirementConsolidation` | ❌ Not registered |
| `RoomAvailabilityPolicy` | `RoomAvailability` | ❌ Not registered |
| `SchoolShiftPolicy` | `SchoolShift` | ❌ Not registered |
| `SlotRequirementPolicy` | `SlotRequirement` | ❌ Not registered |
| `TeacherAssignmentRolePolicy` | `TeacherAssignmentRole` | ❌ Not registered |
| `TeacherAvailabilityLogPolicy` | `TeacherAvailabilityLog` | ❌ Not registered |
| `TeacherAvailabilityPolicy` | `TeacherAvailablity` (typo) | ❌ Not registered |
| `TimetablePolicy` | `Timetable` | ❌ Not registered |
| `TimetableTypePolicy` | `TimetableType` | ❌ Not registered |
| `WorkingDayPolicy` | `WorkingDay` | ❌ Not registered |

**Summary: 5 of 24 policies registered (~21%). 19 policies are dead code.**

### 15.3 DDL Key Constraints Reference

| Table | Constraint Name | Type | Expression |
|-------|----------------|------|------------|
| `tt_period_set_period_jnt` | `chk_psp_time` | CHECK | `end_time > start_time` |
| `tt_period_set_period_jnt` | `duration_minutes` | GENERATED STORED | `TIMESTAMPDIFF(MINUTE, start_time, end_time)` |
| `tt_timetable_type` | `chk_tttype_time` | CHECK | `school_end_time > school_start_time` AND `effective_from_date <= effective_to_date` |
| `tt_class_timetable_type_jnt` | `chk_cttj_apply_to_all_section` | CHECK | `(section_id IS NULL AND applies_to_all_sections=1) OR (section_id IS NOT NULL AND applies_to_all_sections=0)` |
| `tt_class_timetable_type_jnt` | `chk_valid_effective_range` | CHECK | `effective_from < effective_to` |
| `tt_teacher_availabilities` | `available_for_full_timetable_duration` | GENERATED STORED | `IF(teacher_available_from_date <= timetable_start_date, 1, 0)` |
| `tt_teacher_availabilities` | `no_of_days_not_available` | GENERATED STORED | `GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))` |
| `tt_teacher_availability_details` | `uq_ta_class_wise` | UNIQUE | `(teacher_profile_id, day_number, period_number)` |
| `tt_working_day` | `uq_workday_date` | UNIQUE | `date` |

---

## 16. V1 → V2 Delta

### 16.1 V1 to V2 Summary of Changes

| Section | V1 Coverage | V2 Addition |
|---------|-------------|-------------|
| Executive Summary | Basic | Added scorecard, effort estimate, severity table |
| Functional Requirements | 14 FRs | 21 FRs; added FR-TTF-19 (Constraint Type Catalog), FR-TTF-20 (Temp Unavailability), FR-TTF-21 (Reports) |
| Data Model | Table lists | Added DDL column details, constraint names, GENERATED columns, FK targets |
| Routes | Summary table | Full per-route table with EnsureTenantHasModule status for all 138 routes |
| Business Rules | 11 rules | 15 rules; added BR-TTF-12 (working day counter update), BR-TTF-13 (period set overlap), BR-TTF-14 (shift uniqueness), BR-TTF-15 (term-scoped activities) |
| Workflows | Not present in V1 | Section 9 added: 5 workflows (Setup, Calendar Init, Req Consolidation, Activity Generation, Teacher Availability) |
| NFRs | 4 subsections | Performance targets, security coverage table, scalability volumes added |
| Dependencies | Basic list | Inbound/outbound split; middleware dependencies table |
| Test Scenarios | 5 scenarios | 16 test scenarios with priority and type |
| Glossary | Not present | 15 terms defined |
| Suggestions | Priority list | 21 actionable suggestions with effort estimates |
| Appendices | Not present | FormRequest status (24 entries), Policy registration status (24 entries), DDL constraints reference |

### 16.2 New Issues Identified in V2 (Beyond V1)

| Issue | Severity | Description |
|-------|----------|-------------|
| Double route registration | P1 | TTF web.php AND central tenant.php both register same controllers |
| `Config::scopeByStatus()` bug | P2 | Queries non-existent `status` column instead of `is_active` |
| `ConfigController` manual boolean handling | P2 | Uses `$request->has()` instead of FormRequest `prepareForValidation()` |
| 19 of 24 policies unregistered | P1 | Dead code; Gate policy calls silently pass |
| Working day counter triggers missing | P2 | `tt_academic_term` totals not updated when day type changes |
| `TtGenerationStrategyController` cross-module | P3 | Lives in SmartTimetable but registered in TTF routes |
| `ClassSubjectGroupController` cross-module | P3 | Lives in SchoolSetup but registered in TTF routes |
| JSON parsing try/catch misleading | P2 | `json_decode()` doesn't throw; catch block never executes |

