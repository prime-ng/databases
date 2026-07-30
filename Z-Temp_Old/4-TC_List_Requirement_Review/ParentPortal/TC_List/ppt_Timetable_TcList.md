# ppt_Timetable_TcList

## Module: ParentPortal → Timetable

---

## 1. Feature Information

| Item | Details |
|---|---|
| Module | ParentPortal (PPT) |
| Tab Group | Timetable |
| Features | Weekly day × period grid, published timetable only, break period exclusion, current day/period highlighting (view-layer), Mon–Sat default day range |
| URL(s) | `GET /parent-portal/timetable` (index) |
| Controller | `Modules\ParentPortal\Http\Controllers\ParentTimetableController` (@index) |
| Service | `Modules\ParentPortal\Services\ParentContextService` |
| Model(s) | `TimetableCell` (tt_timetable_cells) — external (SmartTimetable module) |
| External Tables | `tt_timetable_cells`, `tt_timetables`, `sch_class_sections`, `sch_subjects`, `sys_users` (teachers) |
| Permission Gates | None — ParentChildPolicy MISSING (P0 gap) |
| Soft Deletes | Not applicable (read-only queries) |
| Events | `activityLog()` on timetable view |

---

## 2. Pre-conditions

- Authenticated parent session with at least one linked child
- Active child resolved via `ParentContextService::resolveChild()`
- Child has a current academic session with `classSection` assigned (class_id + section_id)
- Published or active timetable exists in `tt_timetables` for the child's class-section
- Timetable cells exist in `tt_timetable_cells` linked to the published timetable
- For empty-state tests: child with no class-section or no published timetable
- For break exclusion tests: timetable includes both regular cells and break cells (`is_break = true`)
- For day-filter tests: cells exist on various `day_of_week` values (1–6)

---

## 3. Default Data Load

### 3.1 Timetable Index

| Data | Source | Query | Pagination |
|---|---|---|---|
| Timetable cells | `TimetableCell::whereHas('activity', class+section)->whereHas('timetable', status)->orderBy('period_ord')->filter(!is_break)` | Published/ACTIVE/GENERATED timetables, non-break | None (full collection) |
| Grouped by day | `$cells->groupBy('day_of_week')` | 0=Sun, 1=Mon, ..., 6=Sat | N/A |
| Unique periods | `$cells->sortBy('period_ord')->unique('period_ord')->values()` | Sorted by period_ord | N/A |
| Active days | `$byDay->keys()->filter(fn($d) => $d >= 1 && $d <= 6)->sort()->values()` | Mon–Sat filter with fallback | N/A |

### 3.2 Eager-Loaded Relationships

| Relationship | Data Loaded |
|---|---|
| `activity.subject` | Subject name for each cell |
| `activity.teachers.teacher.user` | Teacher name(s) for each cell |
| `period` | Period order and time range |
| `room` | Room/location for each cell |

---

## 4. BC-DB — Database Schema

### 4.1 `tt_timetable_cells` — Timetable Cell Records

| Column | Data Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | BIGINT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| timetable_id | BIGINT UNSIGNED | NOT NULL | — | FK → tt_timetables.id |
| day_of_week | TINYINT UNSIGNED | NOT NULL | — | 0=Sun, 1=Mon, ..., 6=Sat |
| period_id | BIGINT UNSIGNED | NOT NULL | — | FK → tt_periods.id |
| activity_id | BIGINT UNSIGNED | NOT NULL | — | FK → tt_timetable_activities.id |
| period_ord | SMALLINT UNSIGNED | NOT NULL | — | Display order within the day |
| room_id | BIGINT UNSIGNED | YES | NULL | FK → sch_rooms.id |
| is_break | TINYINT(1) | NOT NULL | 0 | 1 = break/lunch period |
| is_active | TINYINT(1) | NOT NULL | 1 | Active flag |
| created_at | TIMESTAMP | YES | NULL | Creation time |
| updated_at | TIMESTAMP | YES | NULL | Update time |

### 4.2 Key Filter Fields

| Field | Filter Value | Purpose |
|---|---|---|
| `is_break` | `false` (exclude breaks) | Remove lunch/break periods from parent view |
| `day_of_week` | Grouped for grid columns | Day columns: 1=Mon through 6=Sat |
| `period_ord` | ORDER BY ASC | Ensure correct row order |
| `timetable.status` | IN `['ACTIVE', 'GENERATED', 'PUBLISHED']` | Exclude draft timetables |

---

## 5. BC-VAL — Validation Rules

### 5.1 Controller-Level Guards

| Condition | Check | Behaviour |
|---|---|---|
| No `classSection` on session | `if (! $session?->classSection)` | Returns view with `noTimetable = true`, empty collections |
| No timetable cells returned | Empty `$cells` collection | View renders empty grid gracefully |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method | Status | Notes |
|---|---|---|---|
| N/A | index() | NO GATE | Protection via `ParentContextService::resolveChild()` only |

**Key Gap:** No `Gate::authorize()` or `$this->authorize()` exists. All protection relies on `ParentContextService`.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|---|---|---|
| BC-BIZ-01 | Child Resolution via Context | `$this->context->resolveChild($request)` — scopes timetable to parent's child |
| BC-BIZ-02 | Class-Section Guard | `if (! $session?->classSection)` — returns empty view if child has no class-section |
| BC-BIZ-03 | Published Timetable Filter | `whereIn('status', ['ACTIVE', 'GENERATED', 'PUBLISHED'])` — excludes draft timetables |
| BC-BIZ-04 | Break Period Exclusion | `->filter(fn ($c) => ! $c->is_break)` — removes lunch/break periods |
| BC-BIZ-05 | Day Grouping | `$cells->groupBy('day_of_week')` — groups cells for column-based grid rendering |
| BC-BIZ-06 | Unique Period Collection | `$cells->sortBy('period_ord')->unique('period_ord')` — builds row headers |
| BC-BIZ-07 | Mon–Sat Active Day Default | Active days filtered to 1–6 (Mon–Sat); falls back to all available days if no Mon–Sat cells exist |
| BC-BIZ-08 | Eager Loading Performance | 4 relationships eager-loaded: activity.subject, activity.teachers.teacher.user, period, room |
| BC-BIZ-09 | Activity Logging | `activityLog()` called with 'Viewed timetable' and student context |
| BC-BIZ-10 | Timetable Status via WhereHas | Uses `whereHas('timetable', fn ($q) => $q->whereIn('status', ...))` — status check through timetable relationship |

---

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|---|---|---|---|
| KI-PPT-TT-01 | **No Authorization Policy:** No Gate or Policy on timetable controller — relies solely on `ParentContextService`. | P0 (Critical) | ⬜ Not Started |
| KI-PPT-TT-02 | **No Term Selector:** Controller uses only current session's class-section. FRD (REQ-PPT-008 AC4) specifies a term selector for viewing past/future timetables. | P2 (Enhancement) | ⬜ Not Started |
| KI-PPT-TT-03 | **Current Period Highlight in View Only:** The controller does not pass current-time comparison data. The view must independently determine which period is current. | P2 (Low) | ⬜ Not Started |
| KI-PPT-TT-04 | **Day Fallback May Include Sunday:** If no Mon–Sat cells exist, the fallback includes day 0 (Sunday). Edge case for most K-12 schools. | P3 (Edge Case) | ⬜ Not Started |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Middleware |
|---|---|---|---|---|
| GET | `/parent-portal/timetable` | `parent-portal.timetable.index` | `ParentTimetableController@index` | web, tenant, auth, verified, ParentPortal |

---

## 10. Execution Status

| Item | Status | Notes |
|---|---|---|
| Controller Implementation | ✅ Complete | index() — 91 lines, fully implemented |
| Views | ✅ Complete | `parentportal::timetable.index` exists |
| FormRequest | ❌ Not Used | No FormRequest (read-only GET, no POST) |
| Service Layer | ✅ Complete | ParentContextService fully integrated |
| Route Registration | ✅ Complete | Single route registered |
| Activity Logging | ✅ Complete | 'Viewed timetable' logged with student context |
| Authorization Policy | ❌ **MISSING (P0)** | No Gate or Policy — service-layer check only |
| Term Selector | ❌ Not Implemented | Uses only current session — no term filter parameter |
| Period Time Data | ⬜ Partial | Period relationship loaded but start/end time usage depends on view |
| Pest Tests | ❌ Not Written | No test coverage for timetable |

---

## 11. Test Case Summary

### 11.1 Timetable — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-TT-P01 | Timetable | Positive | Timetable grid loads with correct day columns and period rows | 6 |
| TC-PPT-TT-P02 | Timetable | Positive | Each cell shows subject name and teacher name | 4 |
| TC-PPT-TT-P03 | Timetable | Positive | Cells ordered by period_ord ascending | 4 |
| TC-PPT-TT-P04 | Timetable | Positive | Only published/active timetables shown (drafts excluded) | 4 |
| TC-PPT-TT-P05 | Timetable | Positive | Break periods excluded from grid | 4 |
| TC-PPT-TT-P06 | Timetable | Positive | Grid shows Mon–Sat columns by default | 4 |
| TC-PPT-TT-P07 | Timetable | Positive | Current day column highlighted (view-layer) | 3 |
| TC-PPT-TT-P08 | Timetable | Positive | Current period cell highlighted (view-layer) | 3 |
| TC-PPT-TT-P09 | Timetable | Positive | Multiple teachers per subject all displayed | 4 |
| TC-PPT-TT-P10 | Timetable | Positive | Room/location shown for each cell | 3 |
| TC-PPT-TT-P11 | Timetable | Positive | Activity log created on timetable view | 3 |

### 11.2 Timetable — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-TT-N01 | Timetable | Negative | No class-section assigned — empty grid with noTimetable flag | 3 |
| TC-PPT-TT-N02 | Timetable | Negative | No published timetable — empty grid | 3 |
| TC-PPT-TT-N03 | Timetable | Negative | All cells are break periods — empty grid | 3 |
| TC-PPT-TT-N04 | Timetable | Negative | Only draft timetable exists — nothing shown | 3 |

### 11.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-CR-TT-01 | Code Review | Review | index() — child resolution via ParentContextService | 3 |
| TC-CR-TT-02 | Code Review | Review | index() — classSection guard for noTimetable scenario | 3 |
| TC-CR-TT-03 | Code Review | Review | index() — timetable cell query with whereHas activity + timetable status | 5 |
| TC-CR-TT-04 | Code Review | Review | index() — break period filter logic | 3 |
| TC-CR-TT-05 | Code Review | Review | index() — day grouping and period collection | 4 |
| TC-CR-TT-06 | Code Review | Review | index() — active days filter (Mon–Sat fallback) | 4 |
| TC-CR-TT-07 | Code Review | Review | index() — eager-loaded relationships | 4 |
| TC-CR-TT-08 | Code Review | Review | index() — activity logging | 3 |

---

## 12. Test Case Steps

### 12.1 Timetable Positive Steps

#### TC-PPT-TT-P01: Timetable grid loads with correct columns and rows

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as parent with linked child having class-section assigned | Authenticated |
| 2 | Create published timetable with cells: 6 days × 8 periods (Mon–Sat) | 48 cells |
| 3 | Navigate to `GET /parent-portal/timetable` | Timetable page loads |
| 4 | Verify 6 column headers: Mon, Tue, Wed, Thu, Fri, Sat | All weekdays shown |
| 5 | Verify 8 period rows (Period 1 through Period 8) | All periods shown |
| 6 | Verify grid has 48 cells (6 × 8) | Full grid rendered |

#### TC-PPT-TT-P02: Each cell shows subject and teacher name

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable cell with subject="Mathematics" and teacher="Mr. Verma" | Test data |
| 2 | Navigate to timetable | Grid loads |
| 3 | Verify Mon–Period 1 cell displays "Mathematics" and "Mr. Verma" | Subject + teacher shown |
| 4 | Verify multiple cells all show their respective subject and teacher | All cells populated |

#### TC-PPT-TT-P03: Cells ordered by period_ord ascending

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create cells with period_ord = 3, 1, 4, 2 (out of order) | Test data |
| 2 | Load timetable | Grid renders |
| 3 | Verify periods displayed in order: 1, 2, 3, 4 | Ascending period_ord |
| 4 | Verify underlying collection is `orderBy('period_ord')` | DB ordering confirmed |

#### TC-PPT-TT-P04: Only published/active timetables shown

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable with status='DRAFT' and another with status='PUBLISHED' | Two timetables |
| 2 | Create cells in both timetables for same class-section | Cells exist |
| 3 | Load timetable | Grid loads |
| 4 | Verify only PUBLISHED timetable's cells are shown; DRAFT cells excluded | Draft filtered out |

#### TC-PPT-TT-P05: Break periods excluded

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 6 regular cells + 1 break cell (is_break = true) for a day | 7 cells |
| 2 | Load timetable | Grid renders |
| 3 | Verify only 6 regular cells shown | Break excluded |
| 4 | Verify break period (e.g., lunch) does not appear as a row | Break hidden |

#### TC-PPT-TT-P06: Mon–Sat columns by default

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create cells on days 1 (Mon), 2 (Tue), 3 (Wed), 4 (Thu), 5 (Fri), 6 (Sat) | 6 days |
| 2 | Load timetable | Grid renders |
| 3 | Verify 6 columns: Mon, Tue, Wed, Thu, Fri, Sat | All 6 shown |
| 4 | Verify `activeDays = [1, 2, 3, 4, 5, 6]` | Days correct |

#### TC-PPT-TT-P07: Current day column highlighted (view-layer)

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Load timetable on a Wednesday | Grid renders |
| 2 | Verify Wednesday column has highlight CSS class (e.g., different header colour) | Wednesday highlighted |
| 3 | Verify the view uses `now()->dayOfWeek` vs `day_of_week` comparison | Comparison logic present |

#### TC-PPT-TT-P08: Current period cell highlighted (view-layer)

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Load timetable during school hours | Grid renders |
| 2 | Verify the current period's cell in today's column has highlight CSS | Current period highlighted |
| 3 | Verify the view uses period time range to determine current period | Time comparison logic present |

#### TC-PPT-TT-P09: Multiple teachers per subject

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable cell with activity having 2 teachers assigned | Multiple teachers |
| 2 | Load timetable | Grid renders |
| 3 | Verify cell shows both teacher names (e.g., "Mr. Verma, Ms. Patel") | Both teachers displayed |

#### TC-PPT-TT-P10: Room info displayed

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable cell with room = "Lab 1" | Room assigned |
| 2 | Load timetable | Grid renders |
| 3 | Verify cell displays room/location info (e.g., "Lab 1" or "Room 203") | Room shown |

#### TC-PPT-TT-P11: Activity log

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Load timetable page | Page renders |
| 2 | Query activity log for 'Viewed timetable' | Log entry exists |
| 3 | Verify log contains student_id, student_name, module='ParentPortal', route='parent-portal.timetable.index' | Context logged |

### 12.2 Timetable Negative Steps

#### TC-PPT-TT-N01: No class-section — empty grid

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure child's current session has `classSection = null` | No class-section |
| 2 | Navigate to `/parent-portal/timetable` | Page loads |
| 3 | Verify `noTimetable = true` and empty grid displayed | Graceful empty state |

#### TC-PPT-TT-N02: No published timetable — empty grid

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure no timetable exists for child's class-section (or only DRAFT timetables) | No published timetable |
| 2 | Navigate to timetable | Page loads without error |
| 3 | Verify empty grid with "No timetable published" message | Graceful empty state |

#### TC-PPT-TT-N03: All cells are breaks

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable cells all with `is_break = true` for child's class-section | All breaks |
| 2 | Load timetable | Page loads |
| 3 | Verify empty grid (all cells filtered out) | Graceful empty state |

#### TC-PPT-TT-N04: Only draft timetable

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable with status='DRAFT' and cells for child's class-section | Draft only |
| 2 | Load timetable | Page loads |
| 3 | Verify empty grid — draft timetable not visible to parent | Draft filtered |

### 12.3 Code Review Steps

#### TC-CR-TT-01: index() — child resolution

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$this->context->resolveChild($request)` at method start | Child resolved |
| 2 | Review `$session = $child->currentSession()->with(...)->first()` | Session loaded |
| 3 | Review no-access redirect if child resolution fails | Redirect handled |

#### TC-CR-TT-03: index() — timetable cell query

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `TimetableCell::whereHas('activity', fn ($q) => $q->where('class_id', ...)->where('section_id', ...))` | Class-section filter |
| 2 | Review `whereHas('timetable', fn ($q) => $q->whereIn('status', ['ACTIVE', 'GENERATED', 'PUBLISHED']))` | Status filter |
| 3 | Review `->with(['activity.subject', 'activity.teachers.teacher.user', 'period', 'room'])` | Eager loading |
| 4 | Review `->orderBy('period_ord')` | Ordering |
| 5 | Review `->filter(fn ($c) => ! $c->is_break)` | Break exclusion |

#### TC-CR-TT-06: index() — active days filter

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$activeDays = $byDay->keys()->filter(fn ($d) => $d >= 1 && $d <= 6)->sort()->values()` | Mon–Sat filter |
| 2 | Review `if (empty($activeDays)) { $activeDays = $byDay->keys()->sort()->values(); }` | Fallback to all days |
| 3 | Review that `$activeDays` is converted to array `->toArray()` | Array format |
| 4 | Review that `$activeDays` is passed to view for column rendering | View data complete |

#### TC-CR-TT-08: index() — activity logging

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `activityLog()` call at end of method | Logged |
| 2 | Review message = 'Viewed timetable' | Correct message |
| 3 | Review context includes student_id, student_name, module, route | Complete context |
