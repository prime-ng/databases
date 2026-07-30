# StandardTimetable Module — Business Requirements Overview

## Module Purpose

The StandardTimetable Module is the human-guided alternative to AI-based timetable generation. It equips school Timetable Coordinators and Administrators with an interactive drag-and-drop grid builder to manually construct weekly timetables for every class-section. Every period cell — the intersection of a school day and a period ordinal — is placed deliberately by a staff member, with real-time conflict detection warning of teacher clashes, room clashes, and class double-bookings as each slot is filled.

The module transforms what is typically a spreadsheet-and-email workflow in K-12 schools into a structured digital process with a clear approval pipeline: a Coordinator builds and submits the timetable, a Principal approves and publishes it, and the published output is visible to all stakeholders in class-wise, teacher-wise, and room-wise read-only views. Lock controls protect critical cells from accidental overwrite, and a copy mechanism lets schools reuse a previous term's timetable as a starting point.

## Default Data Load

The Module Overview is not a standalone screen — the index dashboard (`StandardTimetableController.index()`) is the landing page. On page load, it executes queries to display aggregate statistics (total timetables, published/draft counts, active activities, class sections, cells placed, school days, period sets, timetable types, rooms), a table of the five most recently updated timetables with cell coverage counts, a summary card showing total/published/draft ratios with a progress bar, and a quick-navigation card grid linking to the Manual Placement screen and four Timetable Foundation sub-menus.

---

## Dashboard — Timetable Overview

The dashboard is the central hub for monitoring all manual timetables in the school. It surfaces key metrics such as total timetables, published-versus-draft splits, overall cell placement volume, and counts of supporting configuration entities (activities, rooms, school days, period sets). The recent-timetables table shows each timetable's name, type, academic term, cell count, status badge (Published or Draft), and last-updated timestamp. A summary card visualises the published-to-draft ratio as a progress bar.

**Route:** `GET /standard-timetable` — `StandardTimetableController.index()`

---

## Manual Placement Grid — Drag & Drop Builder

The core working screen of the module. It presents a two-panel layout: a left-side Activity Palette listing all schedulable activities for the selected class-section (each showing subject, study format, teacher(s), weekly periods needed, placement progress), and a right-side weekly period grid with school days as rows and period ordinals as columns. The Coordinator drags activity cards from the palette onto grid cells; each drop fires an AJAX request that runs five types of conflict detection before writing the cell. Break periods are visually marked and reject placements outright. Placed cells display subject, teacher initials, and room code. The palette counters update after every placement or removal.

**Route:** `GET /standard-timetable/manual-placement` — `StandardTimetableController.manualPlacement()`

### AJAX Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /standard-timetable/place-cell` | `placeCell()` | Place an activity onto a grid cell with conflict detection |
| `POST /standard-timetable/remove-cell` | `removeCell()` | Remove an activity from a grid cell |
| `POST /standard-timetable/create-timetable` | `createTimetable()` | Create a new draft manual timetable |
| `DELETE /standard-timetable/delete-timetable/{id}` | `deleteTimetable()` | Permanently delete a draft timetable and its cells |

### Conflict Detection Types

| Type | Code | Description |
|------|------|-------------|
| Intra-Timetable Teacher | `TEACHER_CONFLICT` | Teacher already assigned to another cell within the same timetable at the same day+period |
| Cross-Timetable Teacher | `TEACHER_CROSS_TT` | Teacher already assigned in a different active timetable at the same day+period |
| Intra-Timetable Room | `ROOM_CONFLICT` | Room already booked within the same timetable at the same day+period |
| Cross-Timetable Room | `ROOM_CROSS_TT` | Room already booked in a different active timetable at the same day+period |
| Class Double-Booking | `CLASS_DOUBLE_BOOKING` | The same class already has a different activity at this slot (the new activity replaces it) |

All conflicts are warnings — placement proceeds and the cell is marked with a conflict flag. The cell record stores conflict details as JSON and writes a `ConflictDetection` record.

---

## Publishing Workflow — Approval Pipeline

A manual timetable passes through three statuses: **DRAFT** → **GENERATED** → **PUBLISHED**. The Coordinator submits a draft for approval; the status changes to Generated (read-only for cells). A Principal (or Admin) then approves the Generated timetable, which transitions it to Published — recording the publication timestamp and making it visible in all read-only views. A direct `publish()` endpoint also exists, allowing a timetable to go from Draft or Generated directly to Published without the two-step submit-then-approve path. Published timetables are immutable: all cell write operations are refused with a 422 response.

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /standard-timetable/submit-for-approval/{id}` | `submitForApproval()` | Change status from Draft to Generated |
| `POST /standard-timetable/approve/{id}` | `approve()` | Change status from Generated to Published with timestamp |
| `POST /standard-timetable/publish/{id}` | `publish()` | Direct publish from Draft or Generated to Published |

Status guards ensure only the correct transitions are allowed: only Draft can be submitted (other statuses rejected with "Only draft timetables can be submitted"), only Generated can be approved ("Only submitted timetables can be approved"), and publish accepts both Draft and Generated states.

---

## Copy & Lock Cells — Timetable Management

The copy feature (`copyTimetable()`) creates a new Draft manual timetable by duplicating an existing timetable's cells and teacher assignments via the `ManualTimetableService.copyTimetable()` method in a single database transaction. The source timetable is never modified. The copy receives a new auto-generated code beginning with `CP_`.

Lock controls protect individual cells from accidental removal or replacement. Three operations are available: `lockCell()` sets `is_locked = true` on a single cell, `unlockCell()` sets `is_locked = false`, and `lockAll()` locks every cell in a timetable in one update. All three refuse to operate on Published timetables. The removeCell endpoint checks `is_locked` before proceeding and returns a 422 "Cell is locked" error if the cell is protected.

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /standard-timetable/copy-timetable/{id}` | `copyTimetable()` | Duplicate a timetable via ManualTimetableService |
| `POST /standard-timetable/lock-cell/{cellId}` | `lockCell()` | Lock a single cell |
| `POST /standard-timetable/unlock-cell/{cellId}` | `unlockCell()` | Unlock a single cell |
| `POST /standard-timetable/lock-all/{timetableId}` | `lockAll()` | Lock all cells in a timetable |

---

## Read-Only Views — Class, Teacher, Room

Three read-only grid views provide role-appropriate timetable visibility. Each loads a `Timetable` record with its type and term, then fetches placed cells grouped by day-period key for rendering.

| View | Route | Gate | Purpose |
|------|-------|------|---------|
| Class View | `GET /standard-timetable/class-view/{timetableId}/{classGroupId}` | `standard-timetable.viewClass` | Weekly grid for a class-section showing subject, teacher, room per cell |
| Teacher View | `GET /standard-timetable/teacher-view/{timetableId}/{teacherId}` | `standard-timetable.viewTeacher` | A teacher's schedule across all class-sections |
| Room View | `GET /standard-timetable/room-view/{timetableId}/{roomId}` | `standard-timetable.viewRoom` | Room occupancy grid with free slots marked |

All three views load school days (where `is_school_day = true`) and the timetable's associated period set for rendering column and row headers. They are currently implemented but do not restrict display to Published timetables only — that filter is enforced at the controller level only by endpoint logic, not by a dedicated middleware guard.

**Not implemented (FRD gaps):** Print-optimised CSS layout, CSV/PDF export, empty-state prompt when no Published timetable exists.

---

## Requirements

- The system MUST provide a dashboard aggregating timetable counts (total, published, draft), cell placement volume, and supporting entity counts (activities, class sections, rooms, school days, period sets)
- The system MUST enable creation of manual timetables with a name, academic term, and timetable type, auto-generating a unique code prefixed with `MT_` and setting initial status to Draft
- The system MUST validate that a Period Set is configured for the selected Timetable Type before allowing timetable creation, returning a 422 error if none exists
- The system MUST only permit deletion of timetables in Draft status, using a database transaction to atomically remove all child cells and teacher assignments
- The system MUST implement a drag-and-drop grid with real-time AJAX placement and removal of activities on weekly period cells, with five conflict types (teacher intra-TT, teacher cross-TT, room intra-TT, room cross-TT, class double-booking) checked on every placement
- The system MUST reject placement on break/lunch periods with a 422 error and reject all cell mutations on Published timetables
- The system MUST support cell locking (individual lock/unlock and bulk lock-all) to prevent accidental overwrite, with removal of locked cells returning a 422 error
- The system MUST provide a publishing workflow with three statuses (Draft → Generated → Published), status-appropriate transition guards, and immutable published state
- The system MUST support copying an existing timetable (cells and teacher assignments) into a new Draft via a transactional service method
- The system MUST provide three read-only grid views (class-wise, teacher-wise, room-wise) for viewing placed cells by entity
- The system MUST log all state-changing operations (create, place, remove, lock, unlock, delete, publish) via the `activityLog()` helper
- The system MUST enforce role-based access through a dedicated StandardTimetablePolicy with eight gates (`viewAny`, `manualPlace`, `publish`, `lock`, `viewClass`, `viewTeacher`, `viewRoom`, `delete`)

---

## Dependencies module and tables

### Primary Tables

The StandardTimetable module shares the `tt_*` timetable schema with the TimetableFoundation and SmartTimetable modules. The following tables are directly read or written by this module's controller and service:

| Table Name | Description | Module Area |
|-----------|-------------|-------------|
| `tt_timetables` | Core timetable registry — stores name, code, status, generation method, period set link, version, publication metadata | Core |
| `tt_timetable_cells` | Period cell records — day, period ordinal, activity, room, class group, lock flag, conflict flags | Core |
| `tt_timetable_cell_teachers` | Junction — links teachers to timetable cells with assignment role and substitute flag | Core |
| `tt_conflict_detections` | Conflict detection event log — stores real-time conflict details during placement | Support |
| `tt_change_logs` | Audit trail for cell mutations — create, update, delete, lock, unlock actions | Support |

### External Module Dependencies

| Module | Nature of Dependency |
|--------|---------------------|
| **TimetableFoundation** | Required — Provides `Timetable`, `TimetableCell`, `Activity`, `AcademicTerm`, `PeriodSet`, `SchoolDay`, `TimetableType`, `ClassTimetableType` models and the `ActivityTeacher` relationship |
| **SchoolSetup** | Required — Provides `ClassSection`, `Room`, `Teacher` models used in grid selectors and view rendering |
| **SmartTimetable** | Optional — Provides `ConflictDetection` model for persisting conflict log records (`tt_conflict_detections`); also shares the `tt_timetables`, `tt_timetable_cells`, and `tt_timetable_cell_teachers` tables |
