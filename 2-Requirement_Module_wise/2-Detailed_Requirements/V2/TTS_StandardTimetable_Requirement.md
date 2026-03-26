# TTS — Standard Timetable (Manual)
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

The StandardTimetable (TTS) module provides a fully manual timetable builder for Indian K-12 schools that prefer hands-on scheduling over AI-generated timetables. While the SmartTimetable (STT) module uses automated constraint-solving algorithms, TTS gives timetable coordinators a direct drag-and-drop grid editor where each period cell is placed deliberately by a human.

The module currently stands at approximately 15–20% complete (revised upward from the 5% estimate in the gap analysis after the controller was significantly expanded). The `StandardTimetableController` now has five methods — `manualPlacement`, `placeCell`, `removeCell`, `createTimetable`, `deleteTimetable` — and the drag-and-drop view (`manual-placement.blade.php`) is 667 lines of scaffolded Blade. However, the class-wise, teacher-wise, and room-wise read views, all authorization infrastructure, all tests, and the publishing workflow remain unbuilt.

Key facts from code inspection:
- **Controller:** 442 lines, 5 methods — manual placement + 4 AJAX endpoints
- **Routes:** `web.php` has 5 routes (GET + 4 POST/DELETE); `tenant.php` route group is still empty
- **Views:** 3 Blade files (`master.blade.php`, `index.blade.php`, `manual-placement.blade.php`)
- **Models:** 0 (uses TimetableFoundation models)
- **Services:** 0
- **Tests:** 0
- **DDL tables owned:** 0 (shares all `tt_*` tables with TTF/STT)

**Estimated completion effort:** 90–125 hours total (P0–P3).

---

## 2. Module Overview

### 2.1 Purpose and Scope

StandardTimetable covers:

1. **Manual timetable creation** — Admin creates a `tt_timetable` record with `generation_method = 'MANUAL'`, then fills it cell by cell via a drag-and-drop grid
2. **Standard read views** — Class-wise, Teacher-wise, Room-wise weekly grids of any PUBLISHED timetable (manual or AI-generated)
3. **Conflict detection** — Real-time teacher and room double-booking detection on every AJAX cell placement
4. **Timetable lifecycle management** — Create, edit, submit for approval, publish, delete (DRAFT/MANUAL only), copy from prior term
5. **Print and export** — Print-optimized CSS rendering and CSV export for all three read views

Out of scope for TTS: AI generation algorithms (owned by STT), constraint management UI (owned by TTF), substitution management (owned by STT's SubstitutionController).

### 2.2 Relationship to SmartTimetable (TTF/STT)

```
TimetableFoundation (TTF) — foundation data owner
  tt_activity, tt_period_set, tt_timetable_type, tt_constraint
  tt_school_days, tt_teacher_assignment_role
  Provides: models, period/day data, constraint types

SmartTimetable (STT) — AI generation + analytics + substitution
  tt_timetable, tt_timetable_cell, tt_timetable_cell_teacher
  AnalyticsService (getClassReport, getTeacherReport, getRoomReport)
  analytics/reports/_grid.blade.php partial
  SubstitutionController (teacher absence + substitute assignment)

StandardTimetable (TTS) — manual builder + read views
  Writes to: tt_timetable (generation_method=MANUAL)
             tt_timetable_cell (source=MANUAL)
             tt_timetable_cell_teacher
  Reads via: SmartTimetable AnalyticsService for read views
  No new tables introduced
```

TTS has a one-way dependency on TTF (models) and STT (AnalyticsService + views). STT does NOT depend on TTS. TTS can be disabled without affecting STT.

### 2.3 Module Identification

| Property | Value |
|---|---|
| Module Code | TTS |
| Module Path | `Modules/StandardTimetable/` |
| Table Prefix | `tt_` (shared, no exclusive tables) |
| Scope | Tenant |
| Generation Method Tag | `MANUAL` in `tt_timetable.generation_method` |
| Route Prefix | `standard-timetable` |
| Named Route Prefix | `standard-timetable.` |
| Laravel Module | `nwidart/laravel-modules` v12 |
| View Namespace | `standardtimetable::` |

---

## 3. Stakeholders and Roles

| Persona | Primary Actions | Access Level |
|---|---|---|
| Timetable Coordinator / Admin | Full CRUD — create, place cells, publish, delete | All views + manual placement |
| Principal | Read-only — class, teacher, room views; can approve | All read views, no placement |
| Class Teacher | View own class timetable only | Class-wise (own class) |
| Subject Teacher | View own schedule | Teacher-wise (own teacher_id) |
| Student / Parent (future) | Own class timetable (via portal) | Class-wise read-only (external) |
| IT Administrator | Module enable/disable, permission seeding | System config only |

Permission scoping rules:
- A `teacher`-role user may only request their own `teacher_id` in the teacher-wise view
- A class teacher may only request their own `class_id` + `section_id`
- Admin / Coordinator can request any entity
- Cross-tenant access is impossible via stancl/tenancy DB isolation

---

## 4. Functional Requirements

### FR-TTS-01: Manual Timetable Creation

**Status:** 🟡 Partial

**FR-TTS-01.1** ✅ The system must allow an authenticated admin to create a new `tt_timetable` record with `generation_method = 'MANUAL'` via an AJAX form (`POST /standard-timetable/create-timetable`). Required fields: `name`, `academic_term_id`, `timetable_type_id`, `period_set_id`.

**FR-TTS-01.2** ✅ The code field must be auto-generated with prefix `MT_` + date + random suffix (e.g., `MT_20260326_143022_A1B2`).

**FR-TTS-01.3** ✅ Initial status must be `DRAFT`; `academic_session_id` is populated from the current active academic session.

**FR-TTS-01.4** ❌ The system must support copying an existing timetable (manual or AI-generated) as a starting point. This creates a new MANUAL timetable with all cells from the source, marked `source = 'MANUAL'`. The original timetable is unchanged.

**FR-TTS-01.5** ❌ The system must allow the admin to set an `effective_from` date and optional `effective_to` date for the new timetable.

**FR-TTS-01.6** ❌ Only one timetable per `timetable_type_id` + `academic_term_id` combination may have status `PUBLISHED` at a time. Attempting to publish a second triggers a confirmation dialog offering to archive the current published timetable.

**FR-TTS-01.7** ❌ A DRAFT manual timetable may be deleted (hard-delete with cascade). A PUBLISHED timetable may not be deleted — only archived.

---

### FR-TTS-02: Drag-and-Drop Grid Editor

**Status:** 🟡 Partial

**FR-TTS-02.1** ✅ The manual placement page must present a two-panel layout: left panel (Activity Palette) and right panel (Period Grid).

**FR-TTS-02.2** ✅ The Period Grid rows represent school days (from `tt_school_days`) and columns represent period ordinals (from `tt_period_set_period_jnt` via the selected period set). Grid is keyed by `day_of_week × period_ord`.

**FR-TTS-02.3** ✅ The Activity Palette lists unplaced (or partially placed) activities for the selected class-section, sourced from `tt_activity` where `class_id` and `section_id` match.

**FR-TTS-02.4** ✅ Activity palette cards display: subject name, study format, weekly periods needed, current placed count.

**FR-TTS-02.5** ❌ Activities must be draggable via mouse (SortableJS or interact.js). Dropping an activity card onto a grid cell must trigger AJAX `POST /standard-timetable/place-cell`.

**FR-TTS-02.6** ✅ The AJAX `placeCell` endpoint creates or updates a `tt_timetable_cell` record via `updateOrCreate` and assigns teachers from the activity's `tt_activity_teachers` records.

**FR-TTS-02.7** ✅ On successful placement, the grid cell must update in-place (no full page reload) showing subject chip, teacher initials, and room code.

**FR-TTS-02.8** ✅ If conflict warnings exist, the cell is highlighted in amber/red with a conflict badge; the AJAX response returns a `has_conflict: true` flag and `conflicts[]` array.

**FR-TTS-02.9** ✅ A cell may be cleared via `POST /standard-timetable/remove-cell`. Locked cells (`is_locked = 1`) must refuse removal and return HTTP 422.

**FR-TTS-02.10** ❌ Right-clicking (or tapping) a placed cell must open a context menu with: View Detail, Change Room, Lock Cell, Clear Cell.

**FR-TTS-02.11** ❌ Rooms assigned to a placed cell must be overridable via a room picker dropdown (updates `tt_timetable_cell.room_id`).

**FR-TTS-02.12** ❌ A cell in a break/lunch period (where `tt_period_type.is_break = 1`) must be shown as non-droppable and visually shaded.

**FR-TTS-02.13** ✅ A placement progress counter is shown: `{placed} / {total_slots} placed` where total_slots = `days × periods`.

**FR-TTS-02.14** ❌ Activities with `required_weekly_periods` fully satisfied must be visually marked complete in the palette (e.g., green checkmark, grayed out).

---

### FR-TTS-03: Conflict Detection

**Status:** 🟡 Partial

**FR-TTS-03.1** ✅ On every `placeCell` call, the system must check for teacher conflicts within the same timetable: same `teacher_id` already assigned to another cell at the same `day_of_week` + `period_ord`.

**FR-TTS-03.2** ✅ The system must check for cross-timetable teacher conflicts: the same `teacher_id` is assigned in any other active timetable at the same slot.

**FR-TTS-03.3** ✅ The system must check for room conflicts within the same timetable: same `room_id` already used at the same slot.

**FR-TTS-03.4** ✅ The system must check for room conflicts across timetables.

**FR-TTS-03.5** ✅ The system must detect class double-booking: same `class_group_id` has another activity at the same slot (warns that it will be replaced via `updateOrCreate`).

**FR-TTS-03.6** ❌ Conflicts must be persisted to `tt_conflict_detection` with `detection_type = 'REAL_TIME'` for audit and later batch review.

**FR-TTS-03.7** ❌ A conflict summary badge on the page header must show total active conflicts for the current timetable, auto-updating after each placement.

**FR-TTS-03.8** ❌ A "Validate All" button must trigger a full batch conflict scan (`detection_type = 'BATCH'`) across all cells and display a paginated violation list.

---

### FR-TTS-04: Standard Read Views

**Status:** ❌ Not Started

**FR-TTS-04.1** 📐 The system must provide a class-wise timetable view at `GET /standard-timetable/class-view?timetable_id=&class_id=&section_id=`. It renders a days × periods grid where each cell shows: subject, teacher name(s), room.

**FR-TTS-04.2** 📐 The class-wise view must use `AnalyticsService::getClassReport(timetableId, classId, sectionId)` from SmartTimetable and render via the shared `smarttimetable::analytics/reports/_grid` Blade partial.

**FR-TTS-04.3** 📐 The system must provide a teacher-wise timetable view at `GET /standard-timetable/teacher-view?timetable_id=&teacher_id=`. Each cell shows: class+section, subject, room. Free periods are dimmed; gap periods (between assignments same day) have a dashed border.

**FR-TTS-04.4** 📐 The teacher-wise view must use `AnalyticsService::getTeacherReport(timetableId, teacherId)`.

**FR-TTS-04.5** 📐 The system must provide a room-wise timetable view at `GET /standard-timetable/room-view?timetable_id=&room_id=`. Free slots shown in green (available). Each booked cell shows: class+section, subject, teacher.

**FR-TTS-04.6** 📐 The room-wise view must use `AnalyticsService::getRoomReport(timetableId, roomId)`.

**FR-TTS-04.7** 📐 All three read views must display only PUBLISHED timetables. If no published timetable exists, show: "No published timetable found. Please publish a timetable first." with a link to the manual placement page.

**FR-TTS-04.8** 📐 Period type color coding must be applied: `tt_period_type.color_code` used as cell background. Teaching = default, Break/Lunch = shaded grey, Free = striped, Exam = highlighted amber, Locked = padlock icon overlay.

---

### FR-TTS-05: Timetable Selector

**Status:** 🟡 Partial (in manual placement view only)

**FR-TTS-05.1** ✅ The manual placement page presents a timetable selector dropdown listing all MANUAL timetables for the tenant, ordered by `created_at DESC`.

**FR-TTS-05.2** 📐 All read views (class/teacher/room) must present a timetable selector dropdown listing all PUBLISHED timetables (any `generation_method`), ordered by `published_at DESC`.

**FR-TTS-05.3** 📐 The selector must show: timetable name, status badge, academic term, version number, published date.

**FR-TTS-05.4** 📐 The most recently published timetable must be pre-selected by default on page load.

---

### FR-TTS-06: Cell Lock and Freeze

**Status:** 🟡 Partial

**FR-TTS-06.1** ✅ Removing a locked cell (`is_locked = 1`) must be rejected with HTTP 422 and message "Cell is locked."

**FR-TTS-06.2** ❌ Admin must be able to lock an individual cell via context menu → Lock. This sets `tt_timetable_cell.is_locked = 1`, `locked_by`, `locked_at`.

**FR-TTS-06.3** ❌ Admin must be able to unlock a locked cell via the same context menu.

**FR-TTS-06.4** ❌ A "Lock All" action must lock every placed cell in the current timetable in a single DB update.

**FR-TTS-06.5** ❌ Placing an activity on an already-occupied locked cell must be rejected (not just warned).

---

### FR-TTS-07: Publishing Workflow

**Status:** ❌ Not Started

**FR-TTS-07.1** 📐 A DRAFT manual timetable must support a status progression: `DRAFT` → `GENERATED` (after Validate) → `PUBLISHED` (after approval).

**FR-TTS-07.2** 📐 "Submit for Approval" button sets status to `GENERATED` and notifies the Principal via the Notification module.

**FR-TTS-07.3** 📐 Principal approves via a dedicated approval screen (or delegated to Admin), which sets status to `PUBLISHED`, populates `published_at` and `published_by`.

**FR-TTS-07.4** 📐 On publish, any previously PUBLISHED timetable of the same `timetable_type_id` + `academic_term_id` is automatically set to `ARCHIVED`.

**FR-TTS-07.5** 📐 A published timetable must be immutable — no cell additions, changes, or deletions are allowed unless it is first unpublished (reverted to GENERATED).

---

### FR-TTS-08: Copy Timetable

**Status:** ❌ Not Started

**FR-TTS-08.1** 📐 Admin must be able to copy any existing timetable (PUBLISHED or ARCHIVED, any `generation_method`) as the basis for a new DRAFT manual timetable.

**FR-TTS-08.2** 📐 The copy operation must duplicate all `tt_timetable_cell` and `tt_timetable_cell_teacher` records, setting `source = 'MANUAL'` on all cells.

**FR-TTS-08.3** 📐 The copy must carry over the same `period_set_id`, `timetable_type_id`, and `academic_term_id` as the source, but allow the admin to change `academic_term_id` for the new term.

**FR-TTS-08.4** 📐 Copy operation must be performed in a DB transaction. On failure, the new timetable and all cells are rolled back.

---

### FR-TTS-09: Print and Export

**Status:** ❌ Not Started

**FR-TTS-09.1** 📐 Each read view (class/teacher/room) must include a Print button that calls `window.print()` with a print-optimized CSS stylesheet (`@media print`) applying landscape A4 orientation and hiding navigation, sidebar, and action buttons.

**FR-TTS-09.2** 📐 The class-wise and teacher-wise views must support CSV export of grid data. Export returns a file with filename `TT_{class}_{section}_{date}.csv`.

**FR-TTS-09.3** 📐 CSV export must use `fputcsv()` to `php://temp` (no external package). Columns: Day, Period, Subject, Teacher, Room, Period Type.

**FR-TTS-09.4** 📐 PDF export via DomPDF (`barryvdh/laravel-dompdf`) must be provided for the class-wise view. Rendered from a dedicated print Blade partial.

---

### FR-TTS-10: Authorization and Permissions

**Status:** ❌ Not Started

**FR-TTS-10.1** 📐 The module must register the following Gate permissions in `AppServiceProvider` (or a dedicated `StandardTimetableServiceProvider`):

| Permission String | Who Can Use |
|---|---|
| `standard-timetable.viewAny` | Admin, Coordinator, Principal |
| `standard-timetable.viewClass` | Admin, Coordinator, Principal, Class Teacher (own class) |
| `standard-timetable.viewTeacher` | Admin, Coordinator, Principal, Teacher (own schedule) |
| `standard-timetable.viewRoom` | Admin, Coordinator, Principal |
| `standard-timetable.manualPlace` | Admin, Coordinator |
| `standard-timetable.publish` | Admin, Principal |
| `standard-timetable.export` | Admin, Coordinator, Principal |

**FR-TTS-10.2** 📐 Permissions must be seeded into `sys_permissions` via `StandardTimetableDatabaseSeeder`.

**FR-TTS-10.3** 📐 All routes must have `EnsureTenantHasModule` middleware applied with module code `TTS`.

**FR-TTS-10.4** ❌ The `placeCell`, `removeCell`, `createTimetable`, `deleteTimetable` routes must use dedicated `FormRequest` classes rather than inline `$request->validate()`.

---

### FR-TTS-11: Change Log

**Status:** ❌ Not Started

**FR-TTS-11.1** 📐 Every cell creation, update, deletion, lock, and unlock must write a record to `tt_change_log` with `change_type` (CREATE/UPDATE/DELETE/LOCK/UNLOCK), `old_values_json`, `new_values_json`, `reason`, and `changed_by`.

**FR-TTS-11.2** 📐 A change log viewer (read-only table) must be accessible to Admin at `GET /standard-timetable/{timetable}/change-log`.

---

## 5. Data Model

### 5.1 Tables Consumed (Read + Write)

StandardTimetable introduces no new tables. It reads and writes to the shared `tt_*` schema.

| Table | R/W | Usage |
|---|---|---|
| `tt_timetable` | R/W | Create MANUAL timetables; read PUBLISHED for views |
| `tt_timetable_cell` | R/W | Place/remove cells; read for grid rendering |
| `tt_timetable_cell_teacher` | R/W | Assign/remove teachers per cell |
| `tt_activity` | R | Activity palette: subject, weekly_periods, class/section |
| `tt_activity_teacher` | R | Teacher assignments per activity |
| `tt_period_set` | R | Period structure for grid columns |
| `tt_period_set_period_jnt` | R | Period ordinals, start/end times, period_type |
| `tt_period_type` | R | Color codes, is_break flag |
| `tt_school_days` | R | Day names, ordinals for grid rows |
| `tt_timetable_type` | R | Selector dropdown options |
| `tt_teacher_workload` | R | Teacher-wise view analytics |
| `tt_resource_booking` | R | Room-wise view analytics |
| `tt_conflict_detection` | R/W | Read conflict badge count; write REAL_TIME detections |
| `tt_constraint_violation` | R | Show violations in validation result |
| `tt_change_log` | W | Audit trail for all cell mutations |
| `tt_generation_run` | R | Informational stats header (N/A for MANUAL) |
| `sch_classes` | R | Class names in selectors and grid |
| `sch_sections` | R | Section names |
| `sch_rooms` | R | Room names/numbers |
| `sch_teachers` | R | Teacher names |
| `sch_subjects` | R | Subject names |
| `sch_org_academic_sessions_jnt` | R | Current academic session |
| `tt_academic_term` | R | Term selector |

### 5.2 Key Column References

**`tt_timetable`** — discriminator column for TTS:
```
generation_method ENUM('MANUAL','SEMI_AUTO','FULL_AUTO') DEFAULT 'MANUAL'
status            ENUM('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED')
```

**`tt_timetable_cell`** — discriminator column for manually placed cells:
```
source       ENUM('AUTO','MANUAL','SWAP','LOCK') DEFAULT 'AUTO'
is_locked    TINYINT(1)
has_conflict TINYINT(1)
conflict_details_json JSON
```

**`tt_change_log`** — audit:
```
change_type ENUM('CREATE','UPDATE','DELETE','LOCK','UNLOCK','SWAP','SUBSTITUTE')
```

### 5.3 Data Access Pattern — Read Views

```php
// SmartTimetable AnalyticsService (reused by TTS)
AnalyticsService::getClassReport(int $timetableId, int $classId, int $sectionId): array
AnalyticsService::getTeacherReport(int $timetableId, int $teacherId): array
AnalyticsService::getRoomReport(int $timetableId, int $roomId): array

// Shared grid partial (SmartTimetable module)
@include('smarttimetable::analytics/reports/_grid', ['report' => $report])
```

### 5.4 DDL Notes — Section 7 is Pending

DDL Section 7 ("TIMETABLE MANUAL MODIFICATION") is explicitly marked `-- PENDING` in `tenant_db_v2.sql` at line 3972. If the team decides TTS needs exclusive tables (e.g., for draft management, manual placement sessions, or undo history), they should be added in DDL Section 7 with prefix `tt_manual_` or `tt_draft_`.

---

## 6. API Endpoints and Routes

### 6.1 Current Routes (Implemented)

All routes are registered in `Modules/StandardTimetable/routes/web.php` and loaded by `StandardTimetableServiceProvider`. Prefix: `standard-timetable`. Middleware: `web`, tenancy, `auth`, `verified`.

| Method | URI | Controller Method | Route Name | Status |
|---|---|---|---|---|
| GET | `/standard-timetable/manual-placement` | `manualPlacement` | `standard-timetable.menu.manualPlacement` | ✅ |
| POST | `/standard-timetable/place-cell` | `placeCell` | `standard-timetable.placeCell` | ✅ |
| POST | `/standard-timetable/remove-cell` | `removeCell` | `standard-timetable.removeCell` | ✅ |
| POST | `/standard-timetable/create-timetable` | `createTimetable` | `standard-timetable.createTimetable` | ✅ |
| DELETE | `/standard-timetable/delete-timetable/{id}` | `deleteTimetable` | `standard-timetable.deleteTimetable` | ✅ |

> **Note:** `tenant.php` still contains an empty `standard-timetable` route group (lines 2210-2212). This is dead code — routes are loaded from `web.php` via the module's RouteServiceProvider. The empty group in `tenant.php` should be removed.

### 6.2 Required Routes (Not Yet Implemented)

| Method | URI | Controller Method | Route Name | Status |
|---|---|---|---|---|
| GET | `/standard-timetable/class-view` | `classView` | `standard-timetable.classView` | ❌ |
| GET | `/standard-timetable/teacher-view` | `teacherView` | `standard-timetable.teacherView` | ❌ |
| GET | `/standard-timetable/room-view` | `roomView` | `standard-timetable.roomView` | ❌ |
| PATCH | `/standard-timetable/lock-cell` | `lockCell` | `standard-timetable.lockCell` | ❌ |
| PATCH | `/standard-timetable/unlock-cell` | `unlockCell` | `standard-timetable.unlockCell` | ❌ |
| PATCH | `/standard-timetable/lock-all/{id}` | `lockAll` | `standard-timetable.lockAll` | ❌ |
| PATCH | `/standard-timetable/update-room` | `updateRoom` | `standard-timetable.updateRoom` | ❌ |
| POST | `/standard-timetable/submit-approval/{id}` | `submitForApproval` | `standard-timetable.submitApproval` | ❌ |
| PATCH | `/standard-timetable/publish/{id}` | `publish` | `standard-timetable.publish` | ❌ |
| POST | `/standard-timetable/copy/{id}` | `copyTimetable` | `standard-timetable.copy` | ❌ |
| POST | `/standard-timetable/validate/{id}` | `validateTimetable` | `standard-timetable.validate` | ❌ |
| GET | `/standard-timetable/{id}/change-log` | `changeLog` | `standard-timetable.changeLog` | ❌ |
| GET | `/standard-timetable/class-view/export-csv` | `exportClassCsv` | `standard-timetable.exportClassCsv` | ❌ |
| GET | `/standard-timetable/class-view/export-pdf` | `exportClassPdf` | `standard-timetable.exportClassPdf` | ❌ |
| GET | `/standard-timetable/teacher-view/export-csv` | `exportTeacherCsv` | `standard-timetable.exportTeacherCsv` | ❌ |

### 6.3 AJAX Response Format (Established Pattern)

The existing `placeCell` and `removeCell` methods return a consistent JSON envelope:

```json
{
  "success": true,
  "message": "Activity placed successfully.",
  "cell_id": 123,
  "has_conflict": false,
  "conflicts": [],
  "activity": {
    "id": 45,
    "subject": "Mathematics",
    "format": "Lecture",
    "teachers": [{"name": "A. Kumar", "is_primary": true}],
    "weekly_needed": 5,
    "placed_count": 2,
    "remaining": 3,
    "is_fully_placed": false
  }
}
```

All new AJAX endpoints must follow this envelope. Error responses must use `"success": false` with an appropriate HTTP status code (422 for validation, 500 for server errors).

---

## 7. UI Screens

### 7.1 Screen Inventory

| Screen ID | Screen Name | Route | Status |
|---|---|---|---|
| SCR-TTS-01 | Manual Placement Grid | `menu.manualPlacement` | 🟡 Partial |
| SCR-TTS-02 | Class-Wise View | `classView` | ❌ |
| SCR-TTS-03 | Teacher-Wise View | `teacherView` | ❌ |
| SCR-TTS-04 | Room-Wise View | `roomView` | ❌ |
| SCR-TTS-05 | Create Timetable Modal | (within SCR-TTS-01) | ✅ |
| SCR-TTS-06 | Timetable List (no timetable selected) | (within SCR-TTS-01) | ✅ |
| SCR-TTS-07 | Conflict Summary Panel | (within SCR-TTS-01) | ❌ |
| SCR-TTS-08 | Change Log View | `changeLog` | ❌ |
| SCR-TTS-09 | Validation Result Panel | (within SCR-TTS-01) | ❌ |

### 7.2 SCR-TTS-01: Manual Placement Grid Layout

```
[ Class-Section Selector ] [ Timetable Selector ]  [ + New Timetable ]
[ Conflicts: 3 ]  [ Progress: 45 / 120 placed ]  [ Lock All ] [ Validate ] [ Submit ]
───────────────────────────────────────────────────────────────────────────────────────
| Activity Palette          | Period Grid (Days x Periods)                              |
| ─────────────────         | ─────────────────────────────────────────────────────     |
| [filter by subject]       |         Mon      Tue      Wed      Thu      Fri    Sat    |
|                           | P1    [Math]   [Sci]    [Eng]   [Math]   [Sci]   [Eng]   |
| [=] Math (3A) 3/5 placed  | P2    [Sci]    [Math]   [Sci]   [Eng]    [Math]  [Sci]   |
| [=] Sci (3A)  2/3 placed  | BRK   [────]   [────]   [────]  [────]   [────]  [────]  |
| [=] Eng (3A)  4/4 done ✓  | P3    [drop]   [Eng]    [Math]  [drop]   [Eng]   [drop]  |
| [=] Hindi     0/4 placed  | ...                                                       |
|                           |                                                           |
| ✓ = fully placed          | Placed cell: subject chip / teacher initials / room code  |
|                           | Conflict cell: amber border + warning icon                |
───────────────────────────────────────────────────────────────────────────────────────
```

### 7.3 SCR-TTS-02: Class-Wise View Layout

```
[ Class ] [ Section ] [ Timetable ]  [Print] [CSV] [PDF]
───────────────────────────────────────────────────────────
        Mon         Tue         Wed         Thu        Fri
P1    Math         Science     English     Math       Science
      A. Kumar     R. Patel    S. Singh    A. Kumar   R. Patel
      Rm 101       Lab 2       Rm 101      Rm 101     Lab 2

LUNCH ─── Break ──────────────────────────────────────────

P4    Hindi        PE          Art         Hindi      PE
      M. Sharma    (Ground)    Art Room    M. Sharma  (Ground)
───────────────────────────────────────────────────────────
Color: Teaching=white | Break=grey | Exam=amber | Locked=padlock
```

### 7.4 SCR-TTS-03: Teacher-Wise View Layout

```
[ Teacher ] [ Timetable ]  [Print] [CSV]
──────────────────────────────────────────────────────────────
Teacher: A. Kumar (Mathematics)   Weekly Load: 18 / 20 periods
        Mon          Tue          Wed         Thu         Fri
P1    10A-Math      9B-Math       -- Free --  10A-Math    9B-Math
      Rm 101        Rm 102                    Rm 101      Rm 102

P2    11A-Math      -- Free --    10B-Math    -- Gap --   11A-Math
      Rm 103                      Rm 101      (dashed)    Rm 103
──────────────────────────────────────────────────────────────
Free = dimmed grey | Gap = dashed border (period between 2 assignments)
```

### 7.5 SCR-TTS-04: Room-Wise View Layout

```
[ Room ] [ Timetable ]  [Print]
──────────────────────────────────────────────────────────────
Room: Science Lab 2   Capacity: 40   Utilization: 72%
        Mon          Tue          Wed         Thu         Fri
P1    10A-Science   -- Free --    9B-Science  -- Free --  11A-Chem
      A. Kumar                    R. Patel                P. Nair

P2    -- Free --    11B-Chem      -- Free --  10A-Science 9B-Sci
                    P. Nair                    A. Kumar    R. Patel
──────────────────────────────────────────────────────────────
Free = green background | Booked = normal background
```

### 7.6 Responsive and Print Requirements

- Bootstrap 5 grid; AdminLTE 4 sidebar
- Grid wrapper: `overflow-x: auto` on mobile/tablet
- `@media print`: landscape A4, hide nav/sidebar/action buttons, 8pt font, scale to fit
- Print must render all days x periods on one page (or 2 for wide grids)

---

## 8. Business Rules

**BR-TTS-001** ✅ Only timetables with `generation_method = 'MANUAL'` may have cells placed or removed via TTS endpoints.

**BR-TTS-002** 📐 Only PUBLISHED timetables appear in the class/teacher/room read views.

**BR-TTS-003** ✅ A locked cell (`is_locked = 1`) rejects `removeCell` with HTTP 422.

**BR-TTS-004** 📐 A PUBLISHED timetable is immutable — all placement/removal/lock calls are rejected.

**BR-TTS-005** 📐 Only one PUBLISHED timetable per `timetable_type_id + academic_term_id` combination is permitted at a time.

**BR-TTS-006** 📐 Deleting a timetable is permitted only for DRAFT/GENERATED manual timetables. Hard-delete with cascade in a DB transaction.

**BR-TTS-007** ✅ Conflict detection covers: teacher double-booking (same TT), teacher cross-TT clash, room double-booking (same TT), room cross-TT clash, class double-booking.

**BR-TTS-008** 📐 Conflicts are warnings not blockers, except break-period placements which are hard-rejected (HTTP 422).

**BR-TTS-009** 📐 Every cell mutation must write a `tt_change_log` record with old/new values JSON.

**BR-TTS-010** 📐 Activity palette placement counts must be recalculated after every `placeCell` / `removeCell` call.

**BR-TTS-011** 📐 Copy-timetable creates a new DRAFT (version=1); does not increment source version.

**BR-TTS-012** ✅ All data is scoped to the tenant database via stancl/tenancy. No cross-tenant access.

**BR-TTS-013** 📐 A teacher-role user may only request their own teacher_id in the teacher-wise view.

**BR-TTS-014** 📐 Break periods (`tt_period_type.is_break = 1`) must not accept cell placements (HTTP 422 rejection).

**BR-TTS-015** 📐 Teacher conflict check uses `whereHas('teachers', fn($q) => $q->whereIn('teacher_id', $teacherIds))` — but currently the `conflictTeachers = $cell->teachers->whereIn('id', $teacherIds)` line in `checkConflicts()` has a bug: it compares the wrong column (`id` instead of `teacher_id`). This must be fixed before the conflict feature is considered production-ready.

---

## 9. Workflows

### 9.1 Manual Timetable Build Flow

```
1. Admin clicks "+ New Timetable"
   POST /standard-timetable/create-timetable
   → tt_timetable created (DRAFT, generation_method=MANUAL, status=DRAFT)

2. Admin selects class-section + timetable from top selectors
   GET /standard-timetable/manual-placement?class_section_id=X&timetable_id=Y
   → Activity palette populated | Grid loaded with existing cells

3. Admin drags activity card → drops onto grid cell
   POST /standard-timetable/place-cell
   → checkConflicts() → updateOrCreate TimetableCell → assign teachers
   → tt_change_log written
   → AJAX response: cell rendered, palette counter updated

4. Admin optionally changes room per cell
   PATCH /standard-timetable/update-room  [to build]

5. Admin optionally locks critical cells
   PATCH /standard-timetable/lock-cell  [to build]

6. Admin repeats steps 2-5 for each class-section

7. Admin clicks "Validate"
   POST /standard-timetable/validate/{id}  [to build]
   → Batch conflict scan → violations panel shown

8. Admin clicks "Submit for Approval"
   POST /standard-timetable/submit-approval/{id}  [to build]
   → tt_timetable.status = GENERATED
   → Notification to Principal

9. Principal reviews and approves
   PATCH /standard-timetable/publish/{id}  [to build]
   → status = PUBLISHED | published_at, published_by set
   → Previous PUBLISHED of same type/term → ARCHIVED
   → Timetable appears in read views
```

### 9.2 Standard Read View Flow

```
1. User navigates to Class/Teacher/Room view
2. Timetable selector loads PUBLISHED timetables (most recent pre-selected)
3. User picks entity (class+section / teacher / room)
4. Controller calls AnalyticsService::get[X]Report()
5. _grid partial renders visual grid with period_type color coding
6. User prints (window.print()) or exports CSV/PDF
```

### 9.3 Copy Timetable Flow

```
1. Admin selects source timetable → "Copy"
2. Modal: new name + academic_term_id (default = same as source)
3. POST /standard-timetable/copy/{source_id}  [to build]
   DB::beginTransaction()
   → New tt_timetable (DRAFT, MANUAL, version=1)
   → Duplicate all tt_timetable_cell (source=MANUAL)
   → Duplicate all tt_timetable_cell_teacher
   DB::commit()
4. Redirect to manual-placement with new timetable selected
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Metric | Requirement | Notes |
|---|---|---|
| `manualPlacement` page load | < 800ms | Loads activities, cells, selectors |
| `placeCell` AJAX response | < 200ms | Includes conflict detection |
| `removeCell` AJAX response | < 100ms | Simple delete |
| Class-wise view load | < 500ms | Pre-computed via AnalyticsService |
| Teacher-wise view load | < 300ms | |
| Room-wise view load | < 300ms | |
| CSV export | < 1 second | Typical school 50 classes |
| PDF export (DomPDF) | < 3 seconds | Single class timetable |
| Copy timetable | < 2 seconds | Up to 500 cells |

### 10.2 Security

- All routes must apply `EnsureTenantHasModule` middleware with code `TTS`
- All write operations must use CSRF-protected POST/PATCH/DELETE methods
- Gate-based authorization on every controller method
- Inline `$request->validate()` in `placeCell`, `removeCell`, `createTimetable` must be replaced with dedicated FormRequest classes (`PlaceCellRequest`, `RemoveCellRequest`, `CreateTimetableRequest`)
- Teacher-role users must be prevented from accessing other teachers' data at the application layer (not just UI)
- SQL injection is prevented by Eloquent ORM throughout; no raw queries

### 10.3 Scalability

- The conflict detection queries (`checkConflicts`) scan `tt_timetable_cell` using indexed columns (`timetable_id`, `day_of_week`, `period_ord`). These indexes exist in the DDL. Performance should be acceptable up to 10,000 cells per tenant.
- Cross-timetable conflict queries join on multiple active timetables — if a tenant has many active timetables, this may become slow. Consider limiting cross-TT checks to active timetables of the current academic term only.

### 10.4 Usability

- Drag-and-drop must function on mouse (desktop/laptop). Touch drag support (tablet) is desirable but not mandatory in V1.
- The grid must be horizontally scrollable on screens narrower than 1024px.
- All AJAX operations must show a loading spinner and disable the triggering element to prevent double-submission.
- All errors returned from AJAX endpoints must be displayed as toast notifications (not browser `alert()`).

### 10.5 Reliability

- `createTimetable` is not wrapped in a try/catch — server errors bubble to a 500 page. Must be wrapped in try/catch with graceful error response.
- `deleteTimetable` is correctly wrapped in `DB::beginTransaction()` with rollback.
- `copyTimetable` (to be built) must also use a transaction.
- All model queries must use tenant-scoped DB (guaranteed by stancl/tenancy).

### 10.6 Maintainability

- Business logic must be extracted from the controller into a `ManualTimetableService` class.
- The 440-line controller should be split: read-view methods into a separate `StandardTimetableViewController`.
- Conflict detection logic (`checkConflicts()`) should move to `ManualTimetableService::checkConflicts()`.

---

## 11. Dependencies

### 11.1 Module Dependencies

| Dependency | Module Code | Purpose | Type |
|---|---|---|---|
| TimetableFoundation | TTF | Models: Activity, Timetable, TimetableCell, TimetableCellTeacher, PeriodSet, SchoolDay, TimetableType, AcademicTerm | Hard compile-time |
| SmartTimetable | STT | AnalyticsService for read views; `_grid` Blade partial | Soft (read views only) |
| SchoolSetup | SCH | ClassSection, Room models | Hard compile-time |
| Prime | PRM | AcademicSession model | Hard compile-time |
| Notification | NTF | Send approval notification to Principal | Soft (publishing flow) |

### 11.2 External Package Dependencies

| Package | Version | Purpose | Status |
|---|---|---|---|
| `stancl/tenancy` | v3.9 | Multi-tenant DB isolation | Production |
| `nwidart/laravel-modules` | v12 | Module framework | Production |
| Bootstrap 5 | 5.x | Responsive layout, tabs, modals | Production |
| AdminLTE 4 | 4.x | UI components, sidebar | Production |
| Font Awesome 6 | 6.x | Icons | Production |
| SortableJS / interact.js | — | Drag-and-drop grid (not yet integrated) | Planned |
| `barryvdh/laravel-dompdf` | — | PDF export for class-wise view | Planned |
| `ramsey/uuid` | — | UUID generation for `tt_timetable.uuid` | Production |

### 11.3 Prerequisites (Must Exist Before TTS is Functional)

1. At least one active `tt_school_days` record per day
2. At least one `tt_period_set` with `is_default = 1` and associated `tt_period_set_period_jnt` records
3. At least one active `tt_timetable_type`
4. At least one current `tt_academic_term`
5. `tt_activity` records for the selected class-section (configured via TTF)
6. Rooms, classes, sections, teachers configured via SchoolSetup

### 11.4 Known Issues from Code Inspection

| ID | Severity | Issue | Location |
|---|---|---|---|
| BUG-TTS-001 | High | `$cell->teachers->whereIn('id', $teacherIds)` should be `->whereIn('teacher_id', $teacherIds)` — wrong column used in conflict reporting | `StandardTimetableController.php` line 349 |
| GAP-TTS-001 | Critical | `tenant.php` empty route group — routes served via `web.php` only; dead code in `tenant.php` should be removed | `routes/tenant.php` lines 2210-2212 |
| GAP-TTS-002 | High | Gate permission `standard-timetable.viewAny` used in all methods — not seeded, not registered in a Policy | All controller methods |
| GAP-TTS-003 | High | No `EnsureTenantHasModule` middleware applied | Route file |
| GAP-TTS-004 | Medium | Inline `$request->validate()` in 3 methods — should use FormRequests | `placeCell`, `removeCell`, `createTimetable` |
| GAP-TTS-005 | Medium | `createTimetable()` has no try/catch — unhandled DB errors will throw 500 | `createTimetable()` |
| GAP-TTS-006 | Medium | Cross-timetable conflict check has no term scope — could match timetables from prior years | `checkConflicts()` lines 361-381 |
| GAP-TTS-007 | Low | `$activity->weekly_periods` fallback in `placeCell` — `weekly_periods` may not exist on Activity model (v7.6 renamed to `required_weekly_periods`) | `placeCell()` line 180 |

---

## 12. Test Scenarios

### 12.1 Required Test Files (None Exist)

| File | Type | Priority |
|---|---|---|
| `tests/Feature/StandardTimetable/ManualPlacementTest.php` | Feature (Pest) | P0 |
| `tests/Feature/StandardTimetable/StandardViewsTest.php` | Feature (Pest) | P1 |
| `tests/Feature/StandardTimetable/PublishWorkflowTest.php` | Feature (Pest) | P1 |
| `tests/Unit/StandardTimetable/ConflictDetectionTest.php` | Unit (Pest) | P1 |
| `tests/Feature/StandardTimetable/AuthorizationTest.php` | Feature (Pest) | P1 |

### 12.2 Test Scenarios — Manual Placement

| ID | Scenario | Expected Result |
|---|---|---|
| TST-TTS-001 | Admin creates new manual timetable | HTTP 200, `tt_timetable` row created with `generation_method=MANUAL`, `status=DRAFT` |
| TST-TTS-002 | Admin places an activity in a free slot | HTTP 200, `tt_timetable_cell` row created, `source=MANUAL`, `has_conflict=0` |
| TST-TTS-003 | Admin places activity — teacher already in another cell at same slot | HTTP 200, response `has_conflict=1`, conflict type `TEACHER_CONFLICT` |
| TST-TTS-004 | Admin places activity — room already booked at same slot | HTTP 200, `has_conflict=1`, conflict type `ROOM_CONFLICT` |
| TST-TTS-005 | Admin removes a free cell | HTTP 200, cell deleted, teacher records deleted |
| TST-TTS-006 | Admin tries to remove a locked cell | HTTP 422, message "Cell is locked." |
| TST-TTS-007 | Admin places activity on break period | HTTP 422, message indicating break periods are not schedulable |
| TST-TTS-008 | Admin creates timetable for same type/term as published one | Creation succeeds (DRAFT); publishing this second one archives the first |
| TST-TTS-009 | Admin deletes a DRAFT timetable | All cells and teacher assignments cascade-deleted |
| TST-TTS-010 | Admin tries to delete a PUBLISHED timetable | HTTP 422, message "Cannot delete a published timetable." |

### 12.3 Test Scenarios — Standard Read Views

| ID | Scenario | Expected Result |
|---|---|---|
| TST-TTS-011 | Admin requests class-wise view for published timetable | HTTP 200, grid rendered with correct cells |
| TST-TTS-012 | Teacher requests teacher-wise view for own teacher_id | HTTP 200 |
| TST-TTS-013 | Teacher requests teacher-wise view for another teacher_id | HTTP 403 |
| TST-TTS-014 | Class teacher requests class-wise view for own class | HTTP 200 |
| TST-TTS-015 | Class teacher requests class-wise view for another class | HTTP 403 |
| TST-TTS-016 | Read view requested when no published timetable exists | HTTP 200, "No published timetable found" message displayed |
| TST-TTS-017 | Guest user accesses any route | Redirect to login |

### 12.4 Test Patterns

Follow SmartTimetable test conventions:
- Pest syntax for Feature tests; bare PHPUnit for Unit tests
- `RefreshDatabase` trait on all Feature tests
- Use model factories: `Timetable::factory()->published()`, `Activity::factory()->forClass($classId)`
- AJAX tests use `$this->postJson()` and assert JSON structure with `assertJsonStructure()`

---

## 13. Glossary

| Term | Definition |
|---|---|
| Manual Timetable | A `tt_timetable` record with `generation_method = 'MANUAL'` — all cells are placed by a human administrator |
| DRAFT | Initial status of a new manual timetable. Editable, not visible in read views |
| GENERATED | Status after "Submit for Approval". Awaiting principal sign-off. Not yet visible in read views |
| PUBLISHED | Approved and active timetable. Read-only. Visible in all read views |
| ARCHIVED | Previously published timetable superseded by a newer published one |
| Activity Palette | Left panel on the manual placement page listing all activities for the selected class-section |
| Period Grid | Right panel showing days (rows) × period ordinals (columns) as a droppable grid |
| Cell | A single intersection of a day and period ordinal in the timetable grid, stored as `tt_timetable_cell` |
| Source | `tt_timetable_cell.source` ENUM: `AUTO` (AI-generated), `MANUAL` (human-placed), `SWAP` (moved via refinement), `LOCK` (locked copy) |
| Conflict | A scheduling violation where two activities share the same teacher, room, or class-section at the same day+period |
| Gap Period | A free period between two assigned periods for the same teacher on the same day |
| Lock | Setting `tt_timetable_cell.is_locked = 1` to prevent a placed cell from being moved or removed |
| generation_method | ENUM on `tt_timetable`: MANUAL, SEMI_AUTO, FULL_AUTO — discriminates TTS from STT timetables |
| TTF | TimetableFoundation module — owns shared configuration tables and models |
| STT | SmartTimetable module — owns AI generation, analytics, substitution |
| TTS | StandardTimetable module — this module, manual timetable builder |
| AnalyticsService | SmartTimetable service (`app/Services/AnalyticsService.php`) that computes and returns class/teacher/room grid reports |
| _grid partial | Shared Blade partial at `smarttimetable::analytics/reports/_grid` for rendering the timetable grid |

---

## 14. Suggestions (New in V2)

These are architectural and product improvements identified during V2 analysis that go beyond fixing existing gaps.

### 14.1 Extract ManualTimetableService

The `StandardTimetableController` is 442 lines. Business logic (`checkConflicts`, cell CRUD, copy flow) should be extracted to `app/Services/ManualTimetableService.php` within the module. The controller should only handle HTTP concerns (request validation, responses). This follows the pattern established by SmartTimetable (AnalyticsService, RefinementService, SubstitutionService).

### 14.2 FormRequest Classes

Three of the five implemented methods use inline `$request->validate()`. Replace with:
- `PlaceCellRequest` — validates `timetable_id`, `activity_id`, `day_of_week`, `period_ord`; adds authorization check that the timetable is MANUAL and not PUBLISHED
- `RemoveCellRequest` — validates timetable_id, day_of_week, period_ord
- `CreateTimetableRequest` — validates name uniqueness per tenant + required fields

### 14.3 Persist Conflicts to tt_conflict_detection

Currently `checkConflicts()` returns an array but does NOT write to `tt_conflict_detection`. This means the conflict history is lost after the AJAX response. Persist each real-time detection as a `REAL_TIME` record so admins can review the conflict history and the conflict badge count is always accurate.

### 14.4 Undo/Redo Stack

For an interactive drag-and-drop grid, users expect Ctrl+Z undo. Consider a lightweight client-side undo stack (array of cell operations) paired with server-side `tt_change_log` — "Undo Last" sends a reverse `removeCell` or re-`placeCell` call.

### 14.5 Timetable Import from SmartTimetable

Allow importing a STT-generated timetable into TTS as a MANUAL timetable for further hand-editing. This bridges the two workflows: start with AI, refine manually. The import copies `tt_timetable_cell` records from the STT timetable and sets `generation_method = 'MANUAL'` on the copy.

### 14.6 ICS Calendar Export (Teacher-Wise)

For the teacher-wise view, offer `.ics` export so teachers can add their weekly schedule to personal calendar apps (Google Calendar, Outlook). Generate using `spatie/icalendar-generator` or manually via RFC 5545 format.

### 14.7 Bulk Period Assignment Tools

For large schools (50+ class-sections), filling the grid section by section is tedious. Consider:
- "Fill free periods with subject X across all Monday periods for this class" bulk action
- "Apply this class's timetable pattern to section B and C" clone-within-timetable action

### 14.8 Quick Substitution Link from Read Views

In the class-wise and teacher-wise read views, clicking on a cell should offer a "Quick Substitute" option that opens the SubstitutionController form (from STT) pre-populated with the cell's data. This avoids navigating away from TTS to find the substitution flow.

### 14.9 Mobile-Optimized Compact View

The current grid layout does not render usefully on mobile phones (< 480px). Consider a list-based alternative for mobile: per-day, per-period cards stacked vertically — switching between grid (desktop) and list (mobile) via a toggle or media query.

### 14.10 Fix Identified Bug Before Production

**BUG-TTS-001** in `checkConflicts()` — the conflict teacher filtering uses `.whereIn('id', $teacherIds)` when it should use `.whereIn('teacher_id', $teacherIds)`. This means conflict messages may show incorrect teacher names. Must be fixed before the feature is considered functional.

---

## 15. Appendices

### 15.1 Module File Structure (Current)

```
Modules/StandardTimetable/
├── app/
│   └── Http/
│       └── Controllers/
│           └── StandardTimetableController.php    (442 lines, 5 methods)
├── config/
│   └── config.php
├── database/
│   └── seeders/
│       └── StandardTimetableDatabaseSeeder.php    (empty scaffold)
├── module.json
├── composer.json
├── package.json
├── resources/
│   └── views/
│       ├── components/
│       │   └── layouts/
│       │       └── master.blade.php
│       ├── index.blade.php
│       └── pages/
│           └── manual-placement.blade.php          (667 lines)
├── routes/
│   ├── api.php                                    (empty)
│   └── web.php                                    (5 routes)
├── tests/
│   ├── Feature/                                   (empty)
│   └── Unit/                                      (empty)
└── vite.config.js
```

### 15.2 Target File Structure (After Full Implementation)

```
Modules/StandardTimetable/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── StandardTimetableController.php     (manual placement + AJAX)
│   │   │   └── StandardTimetableViewController.php (class/teacher/room views)
│   │   └── Requests/
│   │       ├── PlaceCellRequest.php
│   │       ├── RemoveCellRequest.php
│   │       └── CreateTimetableRequest.php
│   ├── Policies/
│   │   └── StandardTimetablePolicy.php
│   └── Services/
│       └── ManualTimetableService.php
├── database/
│   └── seeders/
│       └── StandardTimetableDatabaseSeeder.php    (seeds permissions)
├── resources/
│   └── views/
│       ├── components/layouts/master.blade.php
│       ├── index.blade.php
│       └── pages/
│           ├── manual-placement.blade.php
│           ├── class-view.blade.php
│           ├── teacher-view.blade.php
│           ├── room-view.blade.php
│           ├── change-log.blade.php
│           └── partials/
│               └── print-layout.blade.php
├── routes/
│   ├── api.php
│   └── web.php                                    (20 routes)
└── tests/
    ├── Feature/
    │   ├── ManualPlacementTest.php
    │   ├── StandardViewsTest.php
    │   ├── PublishWorkflowTest.php
    │   └── AuthorizationTest.php
    └── Unit/
        └── ConflictDetectionTest.php
```

### 15.3 Effort Estimate (From Gap Analysis)

| Priority | Key Items | Estimated Hours |
|---|---|---|
| P0 — Critical | Fix routes, EnsureTenantHasModule, expand controller CRUD, wire models | 30–40 hrs |
| P1 — High | ManualTimetableService, FormRequests, Policy, seed permissions, functional views | 25–35 hrs |
| P2 — Medium | Constraint validation, class/teacher/room views, publishing workflow | 20–30 hrs |
| P3 — Low | Tests, PDF export, copy-timetable, ICS export | 15–20 hrs |
| **Total** | | **90–125 hrs** |

### 15.4 V1 Source References

- V1 Requirement: `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done/TTS_StandardTimetable_Requirement.md`
- Gap Analysis: `3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22/StandardTimetable_Deep_Gap_Analysis.md`
- Controller: `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php`
- Routes: `Modules/StandardTimetable/routes/web.php`
- View: `Modules/StandardTimetable/resources/views/pages/manual-placement.blade.php`
- DDL (timetable tables): `tenant_db_v2.sql` lines 3758–4080 (Sections 6–10)

---

## 16. V1 to V2 Delta

### 16.1 What V1 Got Right

V1 correctly identified:
- Module is approximately 5% complete (V2 revises to 15-20% after examining the actual controller)
- No models, no services, no tests
- Class/teacher/room views not built
- Drag-and-drop not implemented
- Routes not registered (V1 claimed empty route group in `tenant.php` — V2 found 5 routes correctly registered in `web.php`)

### 16.2 What V1 Missed (V2 Discoveries)

| Discovery | Impact |
|---|---|
| Controller is NOT 21 lines — it is 442 lines with 5 complete methods | Completion status revised from 5% to 15-20% |
| `placeCell` AJAX endpoint is fully implemented with conflict detection | FR-TTS-02 and FR-TTS-03 are partially done, not 0% |
| `removeCell` is implemented (including locked cell rejection) | BR-TTS-003 is already enforced |
| `createTimetable` and `deleteTimetable` are implemented | FR-TTS-01.1-01.3 and 01.7 are done |
| `routes/web.php` has 5 routes | Routes are loaded via RouteServiceProvider, not `tenant.php` |
| `manual-placement.blade.php` is 667 lines (not a blank stub) | SCR-TTS-01 has significant UI scaffold |
| `tenant.php` route group is dead code (not the active route source) | Must be cleaned up |
| BUG-TTS-001: wrong column in conflict teacher filter | Conflict reporting is partially broken |
| DDL Section 7 ("TIMETABLE MANUAL MODIFICATION") is marked `-- PENDING` | No exclusive tables planned yet |
| Cross-timetable conflict check has no academic term scope | Could produce false positives from prior years |

### 16.3 New Requirements Added in V2

| FR / BR | Description | Rationale |
|---|---|---|
| FR-TTS-01.4 | Copy timetable from prior term/year | Schools reuse 90% of last year's timetable |
| FR-TTS-01.6 | Only one PUBLISHED timetable per type+term | Prevents scheduling chaos with duplicate active timetables |
| FR-TTS-07 | Publishing workflow (Submit → Approve → Publish) | DRAFT alone is insufficient for production use |
| FR-TTS-08 | Copy timetable (detailed) | Separate FR with transaction requirements |
| FR-TTS-10 | Full authorization framework | V1 only sketched gates; V2 specifies all 7 permissions |
| FR-TTS-11 | Change log viewer | Audit trail for regulatory compliance in Indian schools |
| BR-TTS-014 | Break periods reject placement (HTTP 422) | Prevent admin errors |
| BR-TTS-015 | BUG-TTS-001 documented as a business rule | Formal tracking of the identified bug |
| Section 14 | 10 improvement suggestions | Architecture, UX, and integration improvements |

### 16.4 Status Summary

| Category | V1 Estimate | V2 Revised | Notes |
|---|---|---|---|
| Controller | 1 method, 21 lines | 5 methods, 442 lines | V1 underestimated |
| Route count | 0 active | 5 active | V1 looked at wrong file |
| View lines | "blank stub" | 667 lines | V1 was incorrect |
| Tests | 0 | 0 | Unchanged |
| Overall completion | 5% | 15-20% | Revised upward |
| Build effort remaining | 90-125 hrs | 70-100 hrs | Revised based on actual state |

---

*Document generated by code inspection, DDL analysis, and V1 gap review on 2026-03-26.*
*Sources: `StandardTimetableController.php` (442 lines), `web.php` (5 routes), `manual-placement.blade.php` (667 lines), `tenant_db_v2.sql` (lines 3758–4080), V1 requirement doc, StandardTimetable gap analysis.*
