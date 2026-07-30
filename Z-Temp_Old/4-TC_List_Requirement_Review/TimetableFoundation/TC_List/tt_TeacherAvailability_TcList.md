# tt_TeacherAvailability_TcList

## Module: TimetableFoundation → Resource Availability → Teacher Availability

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | TimetableFoundation |
| Tab Group | Resource Availability |
| Feature | Teacher Availability |
| URL(s) | `GET /timetable-foundation/menu/resource-availability?tab=teacher-availability` — main tab listing |
| | `GET /timetable-foundation/teacher-availability` — redirects to resource-availability tab |
| | `GET /timetable-foundation/teacher-availability/create` — create form |
| | `POST /timetable-foundation/teacher-availability` — store |
| | `GET /timetable-foundation/teacher-availability/{id}` — show |
| | `GET /timetable-foundation/teacher-availability/{id}/edit` — edit form |
| | `PUT /timetable-foundation/teacher-availability/{id}` — update (stub — only authorises, does not persist) |
| | `DELETE /timetable-foundation/teacher-availability/{id}` — destroy (soft) |
| | `GET /timetable-foundation/teacher-availability/trash/view` — trashed list |
| | `GET /timetable-foundation/teacher-availability/{id}/restore` — restore |
| | `DELETE /timetable-foundation/teacher-availability/{id}/force-delete` — force delete |
| | `POST /timetable-foundation/teacher-availability/{teacher_availability}/toggle-status` — toggle AJAX |
| | `POST /timetable-foundation/teacher-availability/generate` — batch generate from RequirementConsolidation |
| | `GET /timetable-foundation/teacher-availability-ratio` — ratio dashboard (**not implemented — route defined, method missing**) |
| | `PATCH /timetable-foundation/teacher-availability/{id}/quick-edit` — quick edit (**not implemented — route defined, method missing**) |
| Controller | `Modules\TimetableFoundation\Http\Controllers\TeacherAvailabilityController`; `index()` lines 20–23 (redirect), `create()` lines 28–33, `store()` lines 38–61, `show()` lines 66–86, `edit()` lines 91–96, `update()` lines 101–104 (stub), `destroy()` lines 109–123, `trashedTeacherAvailability()` lines 125–135, `forceDelete()` lines 137–149, `restore()` lines 151–165, `toggleStatus()` lines 167–192, `generateTeacherAvailability()` lines 194–439 |
| Model(s) | `Modules\TimetableFoundation\Models\TeacherAvailability` (table: `tt_teacher_availabilities`) |
| | `Modules\SmartTimetable\Models\TeacherAvailabilityDetail` (table: `tt_teacher_availability_details`, in SmartTimetable module) |
| Validation (Create) | Inline in `store()` — no separate Form Request |
| Validation (Update) | **None** — `update()` is a stub that does not validate or persist |
| Policy | `Modules\TimetableFoundation\Policies\TeacherAvailabilityPolicy` (viewAny, view, create, update, delete, restore, forceDelete) |
| | Custom gate `timetable-foundation.teacher-availability.generate` (not in policy — resolved by application gate resolution) |
| Permissions | `timetable-foundation.teacher-availability.viewAny` |
| | `timetable-foundation.teacher-availability.view` |
| | `timetable-foundation.teacher-availability.create` |
| | `timetable-foundation.teacher-availability.update` |
| | `timetable-foundation.teacher-availability.delete` |
| | `timetable-foundation.teacher-availability.restore` |
| | `timetable-foundation.teacher-availability.forceDelete` |
| | `timetable-foundation.teacher-availability.generate` (custom gate) |
| Pagination | 10 records per page on trash view (`trash` view paginates at 10). Main tab list is **unpaginated** (loads all via `->get()`). |
| Soft Deletes | Yes — `SoftDeletes` trait on Model |
| Read-Only | No — CRUD + batch generate + toggle |
| Known Gaps | `update()` method is a stub — persists nothing. `ratio()` and `quickEdit()` routes registered but methods not implemented — produce 404. |

---

## 2. Pre-conditions

- Admin user has all `timetable-foundation.teacher-availability.*` permissions granted plus the `generate` gate.
- Dusk environment variables set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- Tenant has academic sessions, classes, sections, subjects, subject-study-format records, teacher profiles, and teacher capabilities seeded.
- At least one `RequirementConsolidation` record exists (for generate flow tests).
- At least one `TeacherCapability` record exists matching a requirement for assigned-teacher tests.
- At least one `TeacherUnavailable` rule exists for canvas detail initialisation tests (cross-module).
- `SchoolDay` records configured (days of week), `PeriodSetPeriod` records created (period ordinals).
- The application's Gate resolution correctly resolves `timetable-foundation.teacher-availability.generate` as a permission string.

---

## 3. Default Data Load

The `TeacherAvailabilityController@index` redirects to `TimetableFoundationController@resourceAvailability` with `tab=teacher-availability`. That method loads all records with eager-loaded relationships, filtered by `rta_class_id`, `rta_section_id`, `rta_teacher_profile_id` query parameters, ordered by `class_id`, `section_id`, `subject_study_format_id`, `proficiency_percentage DESC`, and returns **all matching records** (unpaginated). The data is rendered as an accordion grouped by (class, section) then by subject.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Teacher Availabilities accordion | `TimetableFoundationController@resourceAvailability` | `TeacherAvailability::with('teacherProfile.employee.user', 'class', 'section', 'subjectStudyFormat.subject', 'subjectStudyFormat.studyFormat', 'preferredShift', 'activity')` | `rta_class_id` (class), `rta_section_id` (section), `rta_teacher_profile_id` (teacher) | None — all records returned via `->get()` |
| Dropdown — Classes | Same method | `SchoolClass::where('is_active', true)->orderBy('ordinal')->orderBy('name')->get()` | `is_active = true` | None |
| Dropdown — Sections | Same method | `Section::where('is_active', true)->orderBy('name')->get()` | `is_active = true` | None |
| Dropdown — Teacher Profiles | Same method | `TeacherProfile::with('employee.user')->whereHas('employee.user')->get()->map(...)->sortBy('name')->values()` | Only profiles with linked employee user | None |
| Trash view | `trashedTeacherAvailability()` | `TeacherAvailability::onlyTrashed()->with('teacherProfile', 'class', 'section')->latest('deleted_at')` | `onlyTrashed()` | 10/page (default Laravel paginate) |
| Show view | `show($id)` | `TeacherAvailability::with(...)->findOrFail($id)` — loads 9+ relationships | Single record by ID | None |

> **Data Source:** Teacher Availability records originate from two paths: (1) **Batch generation** via `generateTeacherAvailability()` which reads `RequirementConsolidation` records and matches `TeacherCapability` data, or (2) **Manual create** via the `store()` endpoint.

---

## 4. Test Data Strategy

- **Batch generation data**: Create 5+ `RequirementConsolidation` records with varied `class_id`, `section_id`, `subject_study_format_id`. Create matching `TeacherCapability` records with different `proficiency_percentage`, `teaching_experience_months`, `is_primary_subject`, and `competency_level` values. Include at least one requirement with no matching teacher capability (to test unassigned record creation).
- **Manual create data**: Use direct POST requests for single-record CRUD tests. Use validated class/section/subject IDs from pre-seeded data.
- **Pre-test cleanup**: Ensure unique test identifiers — generate availability records can be truncated before each test run (generation truncates the table anyway). For manual tests, use unique combinations to avoid unique-key collisions.
- **Pagination overflow**: Create 12+ soft-deleted records for trash pagination tests.
- **Cross-module data**: For dependency tests, create `ActivityTeacher` or `TimetableCellTeacher` records referencing an availability record to verify RESTRICT behavior. Create `TeacherAvailabilityDetail` rows to test cascade SET NULL on `teacher_profile_id`.
- **Consistent date ranges**: Use `2024-04-01` for `teacher_available_from_date`, `2024-04-01` to `2024-09-30` for timetable window, so generated columns compute predictably.
- **Generate endpoint test isolation**: The `generateTeacherAvailability()` truncates the entire table before re-inserting. Run generate tests in a fresh DB state and validate final counts.

---

## 5. Business Conditions

### 5.1 Database Schema — `tt_teacher_availabilities`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-02 | `requirement_consolidation_id` | INT UNSIGNED | NOT NULL, FK → `tt_requirement_consolidations(id)` |
| BC-DB-03 | `class_id` | INT UNSIGNED | NOT NULL, FK → `sch_classes(id)` via `fk_ta_class` |
| BC-DB-04 | `section_id` | INT UNSIGNED | NULLABLE, FK → `sch_sections(id)` via `fk_ta_section` |
| BC-DB-05 | `subject_study_format_id` | INT UNSIGNED | NOT NULL, FK → `sch_subject_study_format_jnt(id)` via `fk_ta_subject_study_format` |
| BC-DB-06 | `teacher_profile_id` | INT UNSIGNED | NULLABLE, FK → `sch_teacher_profile(id)` via `fk_tad_teacher_profile`, ON DELETE SET NULL |
| BC-DB-07 | `required_weekly_periods` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-08 | `is_full_time` | TINYINT(1) | DEFAULT 1 |
| BC-DB-09 | `preferred_shift` | INT UNSIGNED | NULLABLE, FK → `tt_shifts(id)` |
| BC-DB-10 | `capable_handling_multiple_classes` | TINYINT(1) | DEFAULT 0 |
| BC-DB-11 | `can_be_used_for_substitution` | TINYINT(1) | DEFAULT 1 |
| BC-DB-12 | `certified_for_lab` | TINYINT(1) | DEFAULT 0 |
| BC-DB-13 | `max_available_periods_weekly` | TINYINT UNSIGNED | DEFAULT 48 |
| BC-DB-14 | `min_available_periods_weekly` | TINYINT UNSIGNED | DEFAULT 36 |
| BC-DB-15 | `max_allocated_periods_weekly` | TINYINT UNSIGNED | DEFAULT 1 |
| BC-DB-16 | `min_allocated_periods_weekly` | TINYINT UNSIGNED | DEFAULT 1 |
| BC-DB-17 | `can_be_split_across_sections` | TINYINT(1) | DEFAULT 0 |
| BC-DB-18 | `proficiency_percentage` | TINYINT UNSIGNED | NULLABLE |
| BC-DB-19 | `teaching_experience_months` | SMALLINT UNSIGNED | NULLABLE |
| BC-DB-20 | `is_primary_subject` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-21 | `competancy_level` | ENUM('Advanced','Basic','Expert','Facilitator','Intermediate') | DEFAULT 'Basic' |
| BC-DB-22 | `priority_order` | INT UNSIGNED | NULLABLE |
| BC-DB-23 | `priority_weight` | TINYINT UNSIGNED | NULLABLE |
| BC-DB-24 | `scarcity_index` | TINYINT UNSIGNED | NULLABLE |
| BC-DB-25 | `is_hard_constraint` | TINYINT(1) | DEFAULT 0 |
| BC-DB-26 | `allocation_strictness` | ENUM('Hard','Medium','Soft') | DEFAULT 'Medium' |
| BC-DB-27 | `override_priority` | TINYINT UNSIGNED | NULLABLE |
| BC-DB-28 | `override_reason` | VARCHAR(255) | NULLABLE |
| BC-DB-29 | `historical_success_ratio` | TINYINT UNSIGNED | NULLABLE |
| BC-DB-30 | `last_allocation_score` | TINYINT UNSIGNED | NULLABLE |
| BC-DB-31 | `is_primary_teacher` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-32 | `is_preferred_teacher` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-33 | `preference_score` | TINYINT UNSIGNED | NULLABLE |
| BC-DB-34 | `teacher_profile_from_date` | DATE | NULLABLE |
| BC-DB-35 | `teacher_profile_to_date` | DATE | NULLABLE |
| BC-DB-36 | `teacher_available_from_date` | DATE | NULLABLE |
| BC-DB-37 | `timetable_start_date` | DATE | NULLABLE |
| BC-DB-38 | `timetable_end_date` | DATE | NULLABLE |
| BC-DB-39 | `available_for_full_timetable_duration` | TINYINT(1) | **GENERATED STORED**: `IF(teacher_available_from_date <= timetable_start_date, 1, 0)` |
| BC-DB-40 | `no_of_days_not_available` | INT | **GENERATED STORED**: `GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))` |
| BC-DB-41 | `min_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | DEFAULT 1.00 |
| BC-DB-42 | `max_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | DEFAULT 1.00 |
| BC-DB-43 | `activity_id` | INT UNSIGNED | NULLABLE, FK → `tt_activities(id)` via `fk_tad_activity` |
| BC-DB-44 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-45 | `created_at` | TIMESTAMP | NULLABLE |
| BC-DB-46 | `updated_at` | TIMESTAMP | NULLABLE |
| BC-DB-47 | `deleted_at` | TIMESTAMP | NULLABLE, SoftDeletes |
| BC-DB-48 | UNIQUE KEY `uq_ta_requirement_teacher` | — | `(requirement_consolidation_id, teacher_profile_id)` |

### 5.2 Database Schema — `tt_teacher_availability_details`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-49 | `id` | INT UNSIGNED | PK, NOT NULL, AUTO_INCREMENT |
| BC-DB-50 | `teacher_availability_id` | INT UNSIGNED | NOT NULL, FK → `tt_teacher_availabilities(id)` |
| BC-DB-51 | `teacher_profile_id` | INT UNSIGNED | NOT NULL, FK → `sch_teacher_profile(id)` via `fk_tadet_teacher_profile` |
| BC-DB-52 | `day_number` | TINYINT UNSIGNED | NOT NULL, 1–7 |
| BC-DB-53 | `day_name` | VARCHAR(10) | NOT NULL |
| BC-DB-54 | `period_number` | TINYINT UNSIGNED | NOT NULL |
| BC-DB-55 | `can_be_assigned` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-56 | `availability_for_period` | ENUM('Assigned','Available','Free Period','Unavailable') | NOT NULL, DEFAULT 'Available' |
| BC-DB-57 | `teacher_available_from_date` | DATE | NULLABLE |
| BC-DB-58 | `assigned_class_id` | INT UNSIGNED | NULLABLE, FK → `sch_classes(id)` |
| BC-DB-59 | `assigned_section_id` | INT UNSIGNED | NULLABLE, FK → `sch_sections(id)` |
| BC-DB-60 | `assigned_subject_study_format_id` | INT UNSIGNED | NULLABLE, FK → `sch_subject_study_format_jnt(id)` |
| BC-DB-61 | `activity_id` | INT UNSIGNED | NULLABLE, FK → `tt_activities(id)` |
| BC-DB-62 | `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-63 | UNIQUE KEY `uq_ta_class_wise` | — | `(teacher_profile_id, day_number, period_number)` |
| BC-DB-64 | UNIQUE KEY `uq_ta_class_wise_assignment` | — | `(teacher_profile_id, day_number, period_number, assigned_class_id, assigned_section_id, assigned_subject_study_format_id)` |

### 5.3 Validation Rules — Inline in store() (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | `class_id` | `required`, `integer`, `exists:sch_classes,id` | "The class field is required." / "Selected class is invalid." |
| BC-VAL-02 | `section_id` | `required`, `integer`, `exists:sch_sections,id` | "The section field is required." / "Selected section is invalid." |
| BC-VAL-03 | `subject_study_format_id` | `required`, `integer`, `exists:sch_subject_study_formats,id` | "The subject field is required." / "Selected subject is invalid." |
| BC-VAL-04 | `teacher_profile_id` | `nullable`, `integer`, `exists:sch_teacher_profiles,id` | "Selected teacher profile is invalid." |
| BC-VAL-05 | `required_weekly_periods` | `nullable`, `integer`, `min:1`, `max:60` | "Required weekly periods must be between 1 and 60." |
| BC-VAL-06 | `is_full_time` | `nullable`, `boolean` | Coerced via `$request->boolean()` |
| BC-VAL-07 | `max_available_periods_weekly` | `nullable`, `integer`, `min:1`, `max:60` | "Max available periods must be between 1 and 60." |

### 5.4 Validation Rules — `toggleStatus()` (AJAX)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-08 | `is_active` | `required`, `boolean` | Laravel default |

### 5.5 Update Method — Known Gap

| BC ID | Note |
|-------|------|
| BC-VAL-09 | `update()` method is a **stub** — only calls `Gate::authorize()` and returns. No validation rules, no persistence logic. The edit form submits to this route but changes are silently discarded. This is a known gap. |

### 5.6 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `timetable-foundation.teacher-availability.viewAny` | Without it → 403 on index / main tab list |
| BC-AUTH-02 | `timetable-foundation.teacher-availability.view` | Without it → 403 on show |
| BC-AUTH-03 | `timetable-foundation.teacher-availability.create` | Without it → 403 on create/store |
| BC-AUTH-04 | `timetable-foundation.teacher-availability.update` | Without it → 403 on edit/update/toggleStatus |
| BC-AUTH-05 | `timetable-foundation.teacher-availability.delete` | Without it → 403 on destroy |
| BC-AUTH-06 | `timetable-foundation.teacher-availability.restore` | Without it → 403 on restore/trashed view |
| BC-AUTH-07 | `timetable-foundation.teacher-availability.forceDelete` | Without it → 403 on forceDelete |
| BC-AUTH-08 | `timetable-foundation.teacher-availability.generate` | Without it → 403 on generateTeacherAvailability |
| BC-AUTH-09 | Guest access | Redirect to `/login` on any route |

### 5.7 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Screen loads with `tab=teacher-availability` | Accordion list of teacher availability records rendered; each accordion item groups by class-section; within each, subject groups with teacher tables showing profile, availability, proficiency, competency, scarcity, preference score, status, and actions |
| BC-BIZ-02 | Filter by `rta_class_id` | Only records matching the selected class displayed |
| BC-BIZ-03 | Filter by `rta_section_id` | Only records matching the selected section displayed |
| BC-BIZ-04 | Filter by `rta_teacher_profile_id` | Only records matching the selected teacher displayed |
| BC-BIZ-05 | Combined filters | Filters AND together — only records matching all selected criteria shown |
| BC-BIZ-06 | Reset filters | Clicking reset link removes all filters, all records shown |
| BC-BIZ-07 | Empty record list (no generation done yet) | "No teacher availability records found. Click 'Generate from Requirements' to create them." placeholder displayed |
| BC-BIZ-08 | Generate Teacher Availability — batch run | Table truncated; all active RequirementConsolidation records processed; matching TeacherCapability records found; availability records created with defaults from profiles; scarcity index and preference scores computed; unassigned records created for requirements with no eligible teachers; success message with counts returned |
| BC-BIZ-09 | Generate with no active requirements | Transaction rolled back; error flash: "No active Requirement Consolidations found. Please generate requirements first." |
| BC-BIZ-10 | Generate — scarcity index computation | Per (class_id, subject_study_format_id): ≥5 teachers → index=1, 3–4 teachers → index=4, 2 teachers → index=7, 1 teacher → index=10 |
| BC-BIZ-11 | Generate — preference score computation | `score = (proficiency × 0.5) + (historical_success_ratio × 0.3) + (scarcity_index × 2)`; `is_primary_teacher = is_primary_subject`; `is_preferred_teacher = score > 70`; `min_score = round(score × 0.8, 2)`; `max_score = round(score × 1.2, 2)` |
| BC-BIZ-12 | Generate — shift resolution | `preferred_shift` resolved from teacher profile's `preferred_shift` string by matching `tt_shifts.code` (uppercased). If no match, shift remains null |
| BC-BIZ-13 | Generate — PRIMARY and ASSISTANT roles auto-created | `updateOrCreate` ensures both roles exist before processing requirements |
| BC-BIZ-14 | Soft delete sets `is_active = false` | `destroy()` sets `is_active = false` and `save()` before `delete()` |
| BC-BIZ-15 | Restore sets `is_active = true` | `restore()` calls Eloquent `restore()` then sets `is_active = true` and `save()` |
| BC-BIZ-16 | Toggle status via AJAX | POST to `toggle-status` with `is_active` boolean; returns JSON `{ success: true, is_active: <new_value>, message: "..." }` on success; `{ success: false, ... }` with 422 on failure |
| BC-BIZ-17 | `update()` is a stub | Edit form submits to `PUT /teacher-availability/{id}`; controller authorises the user but returns without persisting any changes. This is a known gap — data appears unchanged after save |
| BC-BIZ-18 | `ratio()` route not implemented | `GET /teacher-availability-ratio` throws `NotFoundHttpException` (method missing). Known gap |
| BC-BIZ-19 | `quickEdit()` route not implemented | `PATCH /teacher-availability/{id}/quick-edit` throws `NotFoundHttpException` (method missing). Known gap |
| BC-BIZ-20 | Generated columns NOT fillable | `available_for_full_timetable_duration` and `no_of_days_not_available` are GENERATED STORED columns excluded from `$fillable`. Mass assignment attempts are silently ignored |
| BC-BIZ-21 | `teacher_profile_id` can be null | Records with `teacher_profile_id = null` represent requirements with no eligible teacher; displayed as "unassigned" with warning badge in UI |
| BC-BIZ-22 | Show view loads all relationships | `show($id)` eager-loads: teacherProfile.employee.user, teacherProfile.employee.activeTeacherProfile.department/role, teacherProfile.employee.activeEmployeeProfile.department/role, class, section, subjectStudyFormat.subject/studyFormat, requirementConsolidation, preferredShift, activity |
| BC-BIZ-23 | Trash view paginated at 10 | `trashedTeacherAvailability()` uses `onlyTrashed()->paginate(10)`; page navigation visible with >10 trashed records |
| BC-BIZ-24 | Force delete permanently removes | `forceDelete()` uses `withTrashed()->findOrFail($id)`; record permanently removed from DB |

### 5.8 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `requirement_consolidation_id` | `tt_requirement_consolidations.id` | RESTRICT (MySQL default) |
| BC-REF-02 | `class_id` (via `fk_ta_class`) | `sch_classes.id` | RESTRICT (MySQL default) |
| BC-REF-03 | `section_id` (via `fk_ta_section`) | `sch_sections.id` | RESTRICT (MySQL default) |
| BC-REF-04 | `subject_study_format_id` (via `fk_ta_subject_study_format`) | `sch_subject_study_format_jnt.id` | RESTRICT (MySQL default) |
| BC-REF-05 | `teacher_profile_id` (via `fk_tad_teacher_profile`) | `sch_teacher_profile.id` | **SET NULL** |
| BC-REF-06 | `activity_id` (via `fk_tad_activity`) | `tt_activities.id` | RESTRICT (MySQL default) |
| BC-REF-07 | `preferred_shift` | `tt_shifts.id` | RESTRICT (MySQL default) |
| BC-REF-08 | `teacher_availability_id` (details) | `tt_teacher_availabilities.id` | RESTRICT (MySQL default) |
| BC-REF-09 | `teacher_profile_id` (details, via `fk_tadet_teacher_profile`) | `sch_teacher_profile.id` | RESTRICT (MySQL default) |
| BC-REF-10 | `assigned_class_id` (details, via `fk_tadet_class`) | `sch_classes.id` | RESTRICT (MySQL default) |
| BC-REF-11 | `assigned_section_id` (details, via `fk_tadet_section`) | `sch_sections.id` | RESTRICT (MySQL default) |
| BC-REF-12 | `assigned_subject_study_format_id` (details, via `fk_tadet_subject_study_format`) | `sch_subject_study_format_jnt.id` | RESTRICT (MySQL default) |
| BC-REF-13 | `activity_id` (details, via `fk_tadet_activity`) | `tt_activities.id` | RESTRICT (MySQL default) |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Load Teacher Availability tab on Resource Availability page | `GET /timetable-foundation/menu/resource-availability?tab=teacher-availability` returns 200; accordion list renders grouped by class-section; each accordion shows subject groups with teacher tables; total count, class-section count, and "Generate from Requirements" button visible | — | — | ⬜ |
| TC-P02 | Expand accordion item to view teacher table | Click accordion header; body expands showing subject groups; each subject shows header (name, format badge, required/week badge, teacher count badge) and teacher rows table with columns: #, Teacher, Avail/wk, Ratio, Primary, Proficiency, Competency, Priority, Weight, Scarcity, Pref Score, Status, Actions | — | — | ⬜ |
| TC-P03 | Filter by class | Select a class from the "All Classes" dropdown and click search; only records for that class displayed; other class accordion items hidden | — | — | ⬜ |
| TC-P04 | Filter by section | Select a section from the "All Sections" dropdown and click search; only records for that section displayed | — | — | ⬜ |
| TC-P05 | Filter by teacher | Select a teacher from the "All Teachers" dropdown and click search; only records for that teacher displayed | — | — | ⬜ |
| TC-P06 | Combined filters | Select class + section + teacher and click search; only records matching all three filters displayed | — | — | ⬜ |
| TC-P07 | Reset filters | Apply filters, then click reset (rotate-left icon); all filters cleared; all records shown; URL reverts to `?tab=teacher-availability` | — | — | ⬜ |
| TC-P08 | Empty state — no records | Access tab when no availability records exist; "No teacher availability records found. Click 'Generate from Requirements' to create them." placeholder with inbox icon displayed | — | — | ⬜ |
| TC-P09 | Create single record — all fields filled | Fill class, section, subject, teacher profile, required weekly periods=5, is_full_time=true, max_available_periods_weekly=40; submit; record created; redirected to index; success flash displayed | — | — | ⬜ |
| TC-P10 | Create single record — required fields only | Fill only class, section, subject (leave teacher_profile_id empty); submit; record created with `teacher_profile_id = null` (unassigned), defaults for other fields | — | — | ⬜ |
| TC-P11 | View record details | Navigate to show page for a record; all fields and relationships displayed: teacher name, class, section, subject, format, required periods, full-time status, shift, capabilities flags, period limits, proficiency, experience, competency, priority, scarcity, constraint flags, scores, dates, generated columns, activity, status | — | — | ⬜ |
| TC-P12 | Edit form loads | Navigate to edit page for a record; edit form rendered (note: submit does not persist changes — known gap) | — | — | ⬜ |
| TC-P13 | Toggle active status via AJAX — activate | POST to toggle-status with `is_active=true` for an inactive record; JSON `{"success": true, "is_active": true, "message": "..."}` returned; DB updated; status badge changes | — | — | ⬜ |
| TC-P14 | Toggle active status via AJAX — deactivate | POST to toggle-status with `is_active=false` for an active record; JSON `{"success": true, "is_active": false, "message": "..."}` returned; DB updated; record hidden from active queries | — | — | ⬜ |
| TC-P15 | Soft delete record | Click delete on a record; `is_active` set to false; `delete()` called; record soft-deleted; redirected with success flash; record removed from main accordion list | — | — | ⬜ |
| TC-P16 | Trash view loads soft-deleted records | Navigate to trash view; soft-deleted records shown with teacher profile, class, section; restore and force-delete actions visible | — | — | ⬜ |
| TC-P17 | Restore record from trash | Click restore on a soft-deleted record; `restore()` called; `is_active` set to true; redirected to trash view; success flash; record reappears in main list | — | — | ⬜ |
| TC-P18 | Force delete record from trash | Click force delete on a soft-deleted record; `forceDelete()` called; record permanently removed; redirected to trash view; success flash; record absent from trash and main list | — | — | ⬜ |
| TC-P19 | Batch generate — all requirements have teachers | Run generate with 5 requirements each having matching TeacherCapability records; success message: "Teacher Availability: X assigned, 0 unassigned, 0 errors"; all records created with computed scarcity, preference scores, is_primary_teacher, is_preferred_teacher; PRIMARY and ASSISTANT roles exist | — | — | ⬜ |
| TC-P20 | Batch generate — some unassigned requirements | Run generate where 1 of 5 requirements has no matching TeacherCapability; unassigned record created with `teacher_profile_id = null`; message: "Teacher Availability: X assigned, 1 unassigned, 0 errors" | — | — | ⬜ |
| TC-P21 | Batch generate — scarcity computation verification | Create requirements for (Class A, Subject X) with 6 teachers → index=1; (Class A, Subject Y) with 3 teachers → index=4; (Class B, Subject X) with 2 teachers → index=7; (Class B, Subject Y) with 1 teacher → index=10 | — | — | ⬜ |
| TC-P22 | Batch generate — preference score verification | Verify computed scores: proficiency=90, success_ratio=80, scarcity=4 → score = (90×0.5)+(80×0.3)+(4×2) = 45+24+8 = 77; is_preferred_teacher = true (score > 70); min_score = 77×0.8 = 61.60; max_score = 77×1.2 = 92.40 | — | — | ⬜ |
| TC-P23 | Batch generate — shift resolved from profile | Teacher profile has `preferred_shift = 'MORNING'`; matching `tt_shifts` with code `MORNING` exists; generated record's `preferred_shift` populated with the shift ID | — | — | ⬜ |
| TC-P24 | Trash pagination with 12+ records | Soft-delete 12+ records; navigate to trash view; 10 records on page 1; 2 records on page 2; page navigation visible | — | — | ⬜ |
| TC-P25 | Unassigned record displayed correctly | Record with `teacher_profile_id = null` shown in accordion with "unassigned" warning badge; teacher cell shows "—" | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Create — missing required fields | Submit with empty class_id, section_id, subject_study_format_id; validation errors for all three required fields; form not submitted | — | — | ⬜ |
| TC-N02 | Create — invalid class_id | Submit class_id=9999 (non-existent); validation error: "Selected class is invalid." | — | — | ⬜ |
| TC-N03 | Create — invalid section_id | Submit section_id=9999; validation error: "Selected section is invalid." | — | — | ⬜ |
| TC-N04 | Create — invalid subject_study_format_id | Submit subject_study_format_id=9999; validation error: "Selected subject is invalid." | — | — | ⬜ |
| TC-N05 | Create — invalid teacher_profile_id | Submit teacher_profile_id=9999; validation error: "Selected teacher profile is invalid." | — | — | ⬜ |
| TC-N06 | Create — required_weekly_periods < 1 | Submit required_weekly_periods=0; validation error: "Required weekly periods must be between 1 and 60." | — | — | ⬜ |
| TC-N07 | Create — required_weekly_periods > 60 | Submit required_weekly_periods=61; validation error: "Required weekly periods must be between 1 and 60." | — | — | ⬜ |
| TC-N08 | Create — max_available_periods_weekly < 1 | Submit max_available_periods_weekly=0; validation error: "Max available periods must be between 1 and 60." | — | — | ⬜ |
| TC-N09 | Create — max_available_periods_weekly > 60 | Submit max_available_periods_weekly=61; validation error: "Max available periods must be between 1 and 60." | — | — | ⬜ |
| TC-N10 | Create — duplicate requirement × teacher pair | Create two records with same (requirement_consolidation_id, teacher_profile_id) via direct DB insert; duplicate entry error for unique key `uq_ta_requirement_teacher` | — | — | ⬜ |
| TC-N11 | Guest access to any route | Visit any teacher-availability route while not logged in; redirect to `/login` | — | — | ⬜ |
| TC-N12 | Missing viewAny permission | User without `viewAny` accesses resource-availability tab; 403 Forbidden | — | — | ⬜ |
| TC-N13 | Missing create permission | User without `create` accesses create/store; 403 Forbidden | — | — | ⬜ |
| TC-N14 | Missing update permission | User without `update` accesses edit/update/toggleStatus; 403 Forbidden | — | — | ⬜ |
| TC-N15 | Missing delete permission | User without `delete` accesses destroy; 403 Forbidden | — | — | ⬜ |
| TC-N16 | Missing restore permission | User without `restore` accesses trash view/restore; 403 Forbidden | — | — | ⬜ |
| TC-N17 | Missing forceDelete permission | User without `forceDelete` accesses forceDelete; 403 Forbidden | — | — | ⬜ |
| TC-N18 | Missing generate permission | User without `generate` clicks "Generate from Requirements"; 403 Forbidden | — | — | ⬜ |
| TC-N19 | Non-existent record — show | Navigate to show for ID 9999; 404 Not Found | — | — | ⬜ |
| TC-N20 | Non-existent record — edit | Navigate to edit for ID 9999; 404 Not Found | — | — | ⬜ |
| TC-N21 | Non-existent record — destroy | DELETE to destroy for ID 9999; 404 Not Found | — | — | ⬜ |
| TC-N22 | Non-existent record — restore | Navigate to restore for ID 9999; 404 Not Found | — | — | ⬜ |
| TC-N23 | Non-existent record — force delete | DELETE to force-delete for ID 9999; 404 Not Found | — | — | ⬜ |
| TC-N24 | Non-existent record — toggle status | POST toggle-status for ID 9999; model binding fails; 404 Not Found | — | — | ⬜ |
| TC-N25 | Generate with zero requirements | Run generate when no active RequirementConsolidation records exist; transaction rolled back; error flash: "No active Requirement Consolidations found. Please generate requirements first." | — | — | ⬜ |
| TC-N26 | Toggle status with invalid is_active value | POST to toggle-status with `is_active=invalid`; validation error: "The is active field must be true or false."; 422 JSON `{success: false, message: "..."}` | — | — | ⬜ |
| TC-N27 | Ratio endpoint — not implemented | Navigate to `GET /teacher-availability-ratio`; 404 Not Found because `ratio()` method does not exist on controller | — | — | ⬜ |
| TC-N28 | Quick edit endpoint — not implemented | PATCH to `/teacher-availability/1/quick-edit`; 404 Not Found because `quickEdit()` method does not exist on controller | — | — | ⬜ |
| TC-N29 | Update method — stub does not persist | Submit edit form with changed values; controller authorises but returns without saving; data in DB unchanged | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Delete class referenced by teacher availability record | Delete blocked by FK RESTRICT constraint (`fk_ta_class`); integrity constraint violation; class not deleted | — | — | ⬜ |
| TC-D02 | A | Delete section referenced by teacher availability record | Delete blocked by FK RESTRICT constraint (`fk_ta_section`); section not deleted | — | — | ⬜ |
| TC-D03 | A | Delete subject_study_format referenced by teacher availability record | Delete blocked by FK RESTRICT constraint (`fk_ta_subject_study_format`); subject not deleted | — | — | ⬜ |
| TC-D04 | B | Delete teacher_profile referenced by teacher availability record (SET NULL) | Delete a teacher_profile that has availability records; `teacher_profile_id` set to NULL on all referencing records (ON DELETE SET NULL via `fk_tad_teacher_profile`) | — | — | ⬜ |
| TC-D05 | C | Delete activity referenced by teacher availability record | Delete blocked by FK RESTRICT constraint (`fk_tad_activity`); activity not deleted | — | — | ⬜ |
| TC-D06 | D | Delete requirement_consolidation referenced by teacher availability record | Delete blocked by FK RESTRICT constraint; requirement consolidation not deleted | — | — | ⬜ |
| TC-D07 | E | Unique key `uq_ta_requirement_teacher` at DB level | Insert duplicate (requirement_consolidation_id, teacher_profile_id) via raw SQL; integrity constraint violation for `uq_ta_requirement_teacher` | — | — | ⬜ |
| TC-D08 | F | Unique key `uq_ta_class_wise` at DB level (details table) | Insert duplicate (teacher_profile_id, day_number, period_number) in details table; integrity constraint violation | — | — | ⬜ |
| TC-D09 | F | Activity logging on create | `store()` creates record; activity log entry with action 'Created', message 'Teacher availability created.' | — | — | ⬜ |
| TC-D10 | F | Activity logging on soft delete | `destroy()` soft-deletes; activity log entry with action 'Trashed', message 'Teacher availability was deactivated and moved to trash.' | — | — | ⬜ |
| TC-D11 | F | Activity logging on restore | `restore()` restores; activity log entry with action 'Restored', message 'Teacher availability was restored successfully.' | — | — | ⬜ |
| TC-D12 | F | Activity logging on force delete | `forceDelete()` permanently deletes; activity log entry with action 'Deleted', message 'Teacher availability was permanently deleted.' | — | — | ⬜ |
| TC-D13 | F | Activity logging on toggle status | `toggleStatus()` flips status; activity log entry with action 'Toggled', message 'Teacher availability status was updated.' | — | — | ⬜ |
| TC-D14 | G | Generate — truncate resets table before insert | Run generate; all pre-existing manual availability records removed; only newly generated records present after run | — | — | ⬜ |
| TC-D15 | H | Generated columns compute correctly | Set `teacher_available_from_date=2024-04-01`, `timetable_start_date=2024-04-05` → `available_for_full_timetable_duration=0`, `no_of_days_not_available=4`. Set `teacher_available_from_date=2024-04-01`, `timetable_start_date=2024-03-25` → `available_for_full_timetable_duration=1`, `no_of_days_not_available=0` | — | — | ⬜ |
| TC-D16 | I | Model `$casts` for boolean/decimal/date columns | `is_full_time` → boolean, `is_active` → boolean, `is_hard_constraint` → boolean, `proficiency_percentage` → integer, `competancy_level` → string, `allocation_strictness` → string, dates → `date`, `min/max_teacher_availability_score` → `decimal:2`, timestamps → `datetime` | — | — | ⬜ |
| TC-D17 | J | Model `$fillable` excludes generated columns | `available_for_full_timetable_duration` and `no_of_days_not_available` not in `$fillable`; mass assignment silently ignores these columns | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for mass-assignment protection | All 39 fillable DDL columns present; 2 generated columns (`available_for_full_timetable_duration`, `no_of_days_not_available`) excluded; no extra column that does not exist in migration | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for booleans/integers/decimals/dates | Boolean casts on all tinyint(1) flags; integer casts on all numeric FK/value columns; string casts on enums; date casts on date columns; decimal:2 on score columns; datetime on 3 timestamps | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait correctly implemented | `SoftDeletes` imported and used; `deleted_at` column in `$casts`; `onlyTrashed()` query works; restore returns null `deleted_at` | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | `requirementConsolidation()` (BelongsTo), `class()` (BelongsTo), `section()` (BelongsTo), `subjectStudyFormat()` (BelongsTo), `teacherProfile()` (BelongsTo), `preferredShift()` (BelongsTo), `activity()` (BelongsTo) — all defined with correct FKs | — | — | ◌ |
| TC-CR05 | CR | P1 | Model — query scopes defined | `scopeActive()`, `scopeHardConstraints()`, `scopeForTeacher()`, `scopeForClassSection()` — each correctly filters | — | — | ◌ |
| TC-CR06 | CR | P1 | Model — helper methods implemented | `isCurrentlyEffective()`, `finalPriority()`, `isUsable()` — each returns correct boolean/null | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — try-catch exception handling on write methods | `generateTeacherAvailability()` wrapped in try-catch with rollback; `destroy()`, `forceDelete()`, `restore()` use `findOrFail()`; `toggleStatus()` has conditional error response | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — DB transactions on multi-step writes | `generateTeacherAvailability()` wraps entire insert/scarcity/score loop in `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()` | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — `Gate::authorize()` on every method | `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`, `trashedTeacherAvailability()`, `forceDelete()`, `restore()`, `toggleStatus()`, `generateTeacherAvailability()` — all call `Gate::authorize()` before any logic | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — activity logged on all state changes | `store()` → 'Created'; `destroy()` → 'Trashed'; `forceDelete()` → 'Deleted'; `restore()` → 'Restored'; `toggleStatus()` → 'Toggled'; each with descriptive message | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — `is_active=false` before soft delete; restore sets `is_active=true` | `destroy()`: sets `is_active=false`, `save()`, then `delete()`. `restore()`: calls Eloquent `restore()`, sets `is_active=true`, `save()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — `toggleStatus()` flips `is_active` and returns JSON | Method validates `is_active` boolean, updates model, saves; returns `{success: true, is_active: <new_value>, message: "..."}` on success; `{success: false, is_active, message}` with 422 on failure | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — trash/restore/forceDelete flow | `trashedTeacherAvailability()` uses `onlyTrashed()->paginate(10)`; `restore()` uses `onlyTrashed()->findOrFail($id)`; `forceDelete()` uses `withTrashed()->findOrFail($id)` | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — redirect/flash after write operations | All write methods return redirect with `success` flash message (or JSON for toggleStatus); failure scenarios return `error` flash | — | — | ◌ |
| TC-CR15 | CR | P1 | Controller — generate endpoint foreign key handling | `generateTeacherAvailability()` disables FK checks (`SET FOREIGN_KEY_CHECKS=0`) before `truncate()`, re-enables after, then wraps inserts in transaction | — | — | ◌ |
| TC-CR16 | CR | P1 | Validation — `store()` rules cover all validated fields | class_id (required, exists), section_id (required, exists), subject_study_format_id (required, exists), teacher_profile_id (nullable, exists), required_weekly_periods (nullable, integer, min:1, max:60), is_full_time (nullable, boolean), max_available_periods_weekly (nullable, integer, min:1, max:60) | — | — | ◌ |
| TC-CR17 | CR | P1 | Policy — all 7 CRUD method gates defined with correct permission strings | `viewAny`→viewAny, `view`→view, `create`→create, `update`→update, `delete`→delete, `restore`→restore, `forceDelete`→forceDelete — each calls `$user->can('timetable-foundation.teacher-availability.<action>')` | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — resource + custom routes registered; model binding 404s | `Route::resource('teacher-availability', ...)` generates 7 routes; 6 custom routes (trashed, restore, forceDelete, toggleStatus, generate, quickEdit, ratio); implicit model binding on `{teacher_availability}` returns 404 for missing IDs | — | — | ◌ |
| TC-CR19 | CR | P1 | View — Blade `@can`/`Route::has()` directives on action buttons | "Generate from Requirements" button only renders when route `timetable-foundation.teacher-availability.generateSlotRequirement` exists; view actions check route existence | — | — | ◌ |
| TC-CR20 | CR | P1 | Database — generated columns are STORED and computed correctly | `available_for_full_timetable_duration`: `IF(teacher_available_from_date <= timetable_start_date, 1, 0)`. `no_of_days_not_available`: `GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))`. Both are STORED (not VIRTUAL) | — | — | ◌ |
| TC-CR21 | CR | P1 | Database — unique indexes match request validation rules | `uq_ta_requirement_teacher` on `(requirement_consolidation_id, teacher_profile_id)` enforces unique teacher per requirement (the generate flow uses `updateOrCreate` with match keys, not the unique key) | — | — | ◌ |
| TC-CR22 | CR | P1 | Breadcrumb — route registered and renders correct hierarchy | `teacher-availability` menu item with parent route `timetable-foundation.menu.resourceAvailability` renders breadcrumb: Dashboard > Academic > Timetable Foundation > Resource Availability > Teacher Availability | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — `$fillable` Matches DDL Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAvailability.php` `$fillable` array | Array contains 39 columns matching all migration columns except id, timestamps, deleted_at, and the 2 GENERATED STORED columns |
| 2 | Cross-reference with migration columns of `tt_teacher_availabilities` | `available_for_full_timetable_duration` and `no_of_days_not_available` are NOT in `$fillable` |
| 3 | Verify no fillable column absent from migration | Every column in `$fillable` exists in the migration schema |

#### TC-CR02: Model — `$casts` for Booleans/Integers/Decimals/Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAvailability.php` `$casts` array | Contains: `is_full_time`→boolean, `capable_handling_multiple_classes`→boolean, `can_be_used_for_substitution`→boolean, `certified_for_lab`→boolean, `can_be_split_across_sections`→boolean, `is_primary_subject`→boolean, `is_hard_constraint`→boolean, `is_primary_teacher`→boolean, `is_preferred_teacher`→boolean, `is_active`→boolean; `proficiency_percentage`→integer, `teaching_experience_months`→integer, `priority_order`→integer, `priority_weight`→integer, `scarcity_index`→integer, `override_priority`→integer, `historical_success_ratio`→integer, `last_allocation_score`→integer, `preference_score`→integer; `competancy_level`→string, `allocation_strictness`→string; `teacher_profile_from_date`→date, `teacher_profile_to_date`→date, `teacher_available_from_date`→date, `timetable_start_date`→date, `timetable_end_date`→date; `min_teacher_availability_score`→decimal:2, `max_teacher_availability_score`→decimal:2; `created_at`→datetime, `updated_at`→datetime, `deleted_at`→datetime |

#### TC-CR03: Model — SoftDeletes Trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAvailability.php` imports | `use SoftDeletes;` present from `Illuminate\Database\Eloquent\SoftDeletes` |
| 2 | Verify `deleted_at` in `$casts` | `'deleted_at' => 'datetime'` present |

#### TC-CR04: Model — Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAvailability.php` | `requirementConsolidation()` returns `$this->belongsTo(RequirementConsolidation::class, 'requirement_consolidation_id')` |
| 2 | | `class()` returns `$this->belongsTo(SchoolClass::class, 'class_id')` |
| 3 | | `section()` returns `$this->belongsTo(Section::class, 'section_id')` |
| 4 | | `subjectStudyFormat()` returns `$this->belongsTo(SubjectStudyFormat::class, 'subject_study_format_id')` |
| 5 | | `teacherProfile()` returns `$this->belongsTo(TeacherProfile::class, 'teacher_profile_id')` |
| 6 | | `preferredShift()` returns `$this->belongsTo(SchoolShift::class, 'preferred_shift')` |
| 7 | | `activity()` returns `$this->belongsTo(Activity::class, 'activity_id')` |

#### TC-CR05 through TC-CR22 — Implementation Verification

*These are static code review TCs verified by file inspection. Implementation details are described in the Expected Result column of Section 6.4. Run automated PHPStan/Pint or manual code review to confirm each assertion.*

---

### 7.1 Positive TC Steps

#### TC-P01: Load Teacher Availability Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log in as admin with full permissions | Dashboard loads |
| 2 | Navigate to `GET /timetable-foundation/menu/resource-availability?tab=teacher-availability` | HTTP 200; page title "Resource Availability" visible |
| 3 | Locate the Teacher Availability tab pane | Accordion list visible with class-section grouped items; each accordion header shows class-section label, subject count badge, teacher count badge; unassigned count badge shown if any |
| 4 | Verify controls present | "Generate from Requirements" button visible; filter dropdowns for Class, Section, Teacher visible; total records and class-section counts shown |

#### TC-P02: Expand Accordion Item

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click on the first accordion header | Body expands showing subject-grouped tables |
| 2 | Verify subject group header | Shows subject name, format badge (e.g., "Theory"), required weekly badge (e.g., "5/wk required"), teacher count badge with color coding (green≥4, yellow≥2, blue≥1, red=0) |
| 3 | Verify teacher table columns | #, Teacher, Avail/wk (Min / Max), Ratio (Min / Max), Primary (Yes/No), Proficiency (%), Competency (badge), Priority, Weight, Scarcity (color badge), Pref Score, Status (Active/Inactive), View action button |

#### TC-P03: Filter by Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific class from "All Classes" dropdown | — |
| 2 | Click search (magnifying glass) button | Page reloads with `?tab=teacher-availability&rta_class_id=X`; only accordion items for that class displayed |
| 3 | Clear filter and reset | All classes shown again |

#### TC-P04: Filter by Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific section from "All Sections" dropdown | — |
| 2 | Click search button | Page reloads with `?tab=teacher-availability&rta_section_id=X`; only records for that section displayed |

#### TC-P05: Filter by Teacher

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific teacher from "All Teachers" dropdown | — |
| 2 | Click search button | Page reloads with `?tab=teacher-availability&rta_teacher_profile_id=X`; only records for that teacher displayed |

#### TC-P06: Combined Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class A, Section 1, Teacher Ms. Sharma | — |
| 2 | Click search | Page reloads with all three params; only records matching Class A AND Section 1 AND Ms. Sharma displayed |

#### TC-P07: Reset Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class and teacher filters | Filtered results shown |
| 2 | Click reset (rotate-left icon) button | Page reloads with `?tab=teacher-availability` only; all records shown; filters cleared |

#### TC-P08: Empty State — No Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure `tt_teacher_availabilities` table is empty (truncate if needed) | — |
| 2 | Navigate to teacher-availability tab | "No teacher availability records found. Click 'Generate from Requirements' to create them." placeholder with inbox icon displayed |

#### TC-P09: Create Single Record — All Fields Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button to navigate to create form | `GET /timetable-foundation/teacher-availability/create` — form rendered |
| 2 | Fill class_id: select an existing class | — |
| 3 | Fill section_id: select an existing section | — |
| 4 | Fill subject_study_format_id: select an existing subject | — |
| 5 | Fill teacher_profile_id: select an existing teacher | — |
| 6 | Fill required_weekly_periods: `5` | — |
| 7 | Check is_full_time | — |
| 8 | Fill max_available_periods_weekly: `40` | — |
| 9 | Click submit | POST request; redirect to resource-availability tab; success flash message "Teacher availability created successfully." |

#### TC-P10: Create Single Record — Required Fields Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Fill class_id, section_id, subject_study_format_id | — |
| 3 | Leave teacher_profile_id empty | — |
| 4 | Submit form | Record created with `teacher_profile_id = null`; defaults applied: `required_weekly_periods=1`, `is_full_time=true`, `max_available_periods_weekly=48`, `min_available_periods_weekly=36`, `is_active=true` |

#### TC-P11: View Record Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to show page: `GET /timetable-foundation/teacher-availability/{id}` | HTTP 200; detail view with all fields displayed |
| 2 | Verify identity section | Teacher name, class, section, subject, format, requirement consolidation ID |
| 3 | Verify capacity section | Required weekly periods, Is Full Time badge, Preferred Shift, capability flags (Multiple Classes, Substitution, Lab, Split Across Sections) |
| 4 | Verify period constraints section | Min/Max Available Periods Weekly, Min/Max Allocated Periods Weekly values displayed |
| 5 | Verify scoring section | Proficiency %, Experience Months, Primary Subject badge, Competency Level badge, Priority Order, Priority Weight, Scarcity Index badge, Hard Constraint badge, Allocation Strictness badge, Preference Score, Is Preferred Teacher badge |
| 6 | Verify date section | Teacher Profile From/To Date, Teacher Available From Date, Timetable Start/End Date |
| 7 | Verify generated columns | Available for Full Timetable Duration (Yes/No badge), No of Days Not Available displayed (not editable) |
| 8 | Verify score range | Min/Max Teacher Availability Score displayed |
| 9 | Verify Edit button present | Link to edit route visible |
| 10 | Verify Back button present | Link to resource-availability tab visible |

#### TC-P12: Edit Form Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit page: `GET /timetable-foundation/teacher-availability/{id}/edit` | HTTP 200; edit form rendered with current values pre-filled |
| 2 | Note: Changes submitted via this form will NOT persist (update() is a stub — known gap) | Known gap documented |

#### TC-P13: Toggle Active Status via AJAX — Activate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an inactive record (is_active = false) | — |
| 2 | POST to `/teacher-availability/{id}/toggle-status` with `is_active=true` | JSON `{"success": true, "is_active": true, "message": "..."}` |
| 3 | Verify DB updated | `is_active = true` in database |
| 4 | Reload tab | Record status badge shows "Active" (green) |

#### TC-P14: Toggle Active Status via AJAX — Deactivate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify an active record (is_active = true) | — |
| 2 | POST to toggle-status with `is_active=false` | JSON `{"success": true, "is_active": false, "message": "..."}` |
| 3 | Verify DB updated | `is_active = false` in database |
| 4 | Reload tab | Record status badge shows "Inactive" (grey) |

#### TC-P15: Soft Delete Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click delete (trash icon) on an active record | DELETE request to destroy route |
| 2 | Verify redirect | Redirect to resource-availability tab |
| 3 | Verify flash | Success flash message displayed |
| 4 | Verify record absent from accordion | Record not visible in active list |
| 5 | Query DB directly | `deleted_at` populated; `is_active=0` |

#### TC-P16: Trash View Loads Soft-Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view: `GET /timetable-foundation/teacher-availability/trash/view` | HTTP 200; table with teacher profile, class, section columns |
| 2 | Verify deleted record appears | Soft-deleted record listed with teacher name, class, section; restore and force-delete action icons visible |

#### TC-P17: Restore Record from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | On trash view, click restore (undo icon) for a soft-deleted record | GET request to restore route |
| 2 | Verify redirect | Redirect to trash view |
| 3 | Verify flash | Success flash message displayed |
| 4 | Navigate to main teacher availability tab | Record reappears in accordion; status is active |
| 5 | Query DB directly | `deleted_at` null; `is_active=1` |

#### TC-P18: Force Delete Record from Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a record (e.g. ID from TC-P15) | — |
| 2 | Navigate to trash view | Record visible in trash |
| 3 | Click force delete (X icon) | DELETE request to force-delete route |
| 4 | Verify redirect | Redirect to trash view |
| 5 | Verify flash | Success flash message displayed |
| 6 | Query DB directly | Record does not exist in `tt_teacher_availabilities` (even with `withTrashed()`) |

#### TC-P19: Batch Generate — All Requirements Have Teachers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 5 active RequirementConsolidation records exist with class_id, section_id, subject_study_format_id | — |
| 2 | For each requirement, ensure at least 2 matching TeacherCapability records exist (same class_id, subject_study_format_id, is_active=true) | — |
| 3 | Navigate to teacher-availability tab | No records initially (or pre-existing) |
| 4 | Click "Generate from Requirements" button | POST request to `/teacher-availability/generate` |
| 5 | Confirm dialog "This will replace ALL existing teacher availability records..." | Accept |
| 6 | Verify success message | Message format: "Teacher Availability: X assigned, 0 unassigned, 0 errors. (Requirements: Y)" |
| 7 | Verify PRIMARY and ASSISTANT roles exist | `tt_teacher_assignment_roles` has PRIMARY and ASSISTANT with correct attributes |
| 8 | Verify records in accordion | All generated records visible; scarcity index and preference score populated |

#### TC-P20: Batch Generate — Some Unassigned Requirements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 5 active RequirementConsolidation records exist | — |
| 2 | For 4 requirements, create matching TeacherCapability records. For the 5th, do NOT create any matching capability. | — |
| 3 | Click "Generate from Requirements" | Success message includes 1 unassigned |
| 4 | Locate the unassigned record in accordion | Record shown with "unassigned" warning badge; teacher name shows "—" |

#### TC-P21: Batch Generate — Scarcity Computation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create requirements: (Class A, Subject X), (Class A, Subject Y), (Class B, Subject X), (Class B, Subject Y) | — |
| 2 | Create teacher capabilities: 6 teachers for (A,X), 3 teachers for (A,Y), 2 teachers for (B,X), 1 teacher for (B,Y) | — |
| 3 | Generate | Verify scarcity_index: (A,X)=1, (A,Y)=4, (B,X)=7, (B,Y)=10 |

#### TC-P22: Batch Generate — Preference Score Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a TeacherCapability record with: proficiency_percentage=90, historical_success_ratio=80, scarcity_index=4 | — |
| 2 | Generate availability | Computed: score = (90×0.5)+(80×0.3)+(4×2) = 45+24+8 = 77; `preference_score=77`; `is_preferred_teacher=true`; `min_teacher_availability_score=61.60`; `max_teacher_availability_score=92.40`; `is_primary_teacher=is_primary_subject` |

#### TC-P23: Batch Generate — Shift Resolution from Profile

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set teacher profile `preferred_shift = 'MORNING'` | — |
| 2 | Ensure `tt_shifts` has a row with `code = 'MORNING'` | — |
| 3 | Run generate | Generated record's `preferred_shift` populated with the shift ID |
| 4 | Set teacher profile `preferred_shift = 'NONEXISTENT'` where no matching shift code exists | — |
| 5 | Run generate | Generated record's `preferred_shift` is null |

#### TC-P24: Trash Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 12 records | — |
| 2 | Navigate to trash view | 10 records shown on page 1; pagination controls visible |
| 3 | Click page 2 | Remaining 2 records shown; URL contains `?page=2` |

#### TC-P25: Unassigned Record Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a record with `teacher_profile_id = null` via create form or generation | — |
| 2 | Locate the record in accordion | Accordion shows warning badge "(X) unassigned"; teacher name shows "—" |

---

### 7.2 Negative TC Steps

#### TC-N01: Missing Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | — |
| 2 | Leave class_id, section_id, subject_study_format_id blank | — |
| 3 | Submit form | Validation errors for class_id, section_id, subject_study_format_id (all "required"); form not submitted |

#### TC-N02: Invalid class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with class_id=9999 | — |
| 2 | Submit form | Validation error: "Selected class is invalid." |

#### TC-N03: Invalid section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with section_id=9999 | — |
| 2 | Submit form | Validation error: "Selected section is invalid." |

#### TC-N04: Invalid subject_study_format_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with subject_study_format_id=9999 | — |
| 2 | Submit form | Validation error: "Selected subject is invalid." |

#### TC-N05: Invalid teacher_profile_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with teacher_profile_id=9999 | — |
| 2 | Submit form | Validation error: "Selected teacher profile is invalid." |

#### TC-N06: required_weekly_periods < 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with required_weekly_periods=0 | — |
| 2 | Submit form | Validation error: "Required weekly periods must be between 1 and 60." |

#### TC-N07: required_weekly_periods > 60

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with required_weekly_periods=61 | — |
| 2 | Submit form | Validation error: "Required weekly periods must be between 1 and 60." |

#### TC-N08: max_available_periods_weekly < 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with max_available_periods_weekly=0 | — |
| 2 | Submit form | Validation error: "Max available periods must be between 1 and 60." |

#### TC-N09: max_available_periods_weekly > 60

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form with max_available_periods_weekly=61 | — |
| 2 | Submit form | Validation error: "Max available periods must be between 1 and 60." |

#### TC-N10: Duplicate Unique Key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query DB to find an existing (requirement_consolidation_id, teacher_profile_id) pair that exists | — |
| 2 | Attempt to insert a duplicate pair via raw SQL: `INSERT INTO tt_teacher_availabilities (requirement_consolidation_id, class_id, section_id, subject_study_format_id, teacher_profile_id) VALUES (X, Y, Z, W, V)` using same req_cons_id and teacher_profile_id | SQL error: Integrity constraint violation for `uq_ta_requirement_teacher` |

#### TC-N11: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out | — |
| 2 | Navigate to `GET /timetable-foundation/teacher-availability/create` | Redirected to `/login` |

#### TC-N12 through TC-N18: Missing Permission — 403 Forbidden

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | For each permission listed in BC-AUTH, log in as a user missing that specific permission | — |
| 2 | Access the corresponding route | 403 Forbidden (or response with error) |

#### TC-N19 through TC-N24: Non-Existent Record — 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | For each route (show, edit, destroy, restore, forceDelete, toggleStatus), use ID 9999 | HTTP 404 Not Found |

#### TC-N25: Generate with Zero Requirements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active RequirementConsolidation records exist | — |
| 2 | Click "Generate from Requirements" | Transaction rolled back; redirected back; error flash: "No active Requirement Consolidations found. Please generate requirements first." |

#### TC-N26: Toggle Status Invalid Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggle-status with `is_active=invalid` | Validation error; JSON response `{"success": false, "message": "..."}` with HTTP 422 |

#### TC-N27: Ratio Endpoint — Not Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /timetable-foundation/teacher-availability-ratio` | HTTP 404 Not Found (route registered, controller method missing) |

#### TC-N28: Quick Edit Endpoint — Not Implemented

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send `PATCH /timetable-foundation/teacher-availability/1/quick-edit` | HTTP 404 Not Found (route registered, controller method missing) |

#### TC-N29: Update Method — Stub Does Not Persist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit page for an existing record | Form loads with current values |
| 2 | Change `required_weekly_periods` from current value to a different value | — |
| 3 | Submit the form | PUT request sent; controller authorises (`Gate::authorize('update')`) but returns without saving; page redirects or shows blank response |
| 4 | Reload the record's show page or edit form | Data unchanged — `required_weekly_periods` retains original value |

---

### 7.3 Dependency TC Steps

#### TC-D01: FK RESTRICT — Class Referenced by Teacher Availability

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a `sch_classes` record referenced by `tt_teacher_availabilities.class_id` | — |
| 2 | Attempt to delete this class record via SQL: `DELETE FROM sch_classes WHERE id = X` | Integrity constraint violation; FK `fk_ta_class` prevents deletion |

#### TC-D02: FK RESTRICT — Section Referenced by Teacher Availability

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a `sch_sections` record referenced by `tt_teacher_availabilities.section_id` | — |
| 2 | Attempt to delete it | Integrity constraint violation for `fk_ta_section` |

#### TC-D03: FK RESTRICT — Subject Study Format Referenced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify `sch_subject_study_format_jnt` record referenced by `tt_teacher_availabilities.subject_study_format_id` | — |
| 2 | Attempt to delete it | Integrity constraint violation for `fk_ta_subject_study_format` |

#### TC-D04: FK SET NULL — Teacher Profile Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a `sch_teacher_profile` record that has referencing rows in `tt_teacher_availabilities` | — |
| 2 | Delete the teacher profile record via SQL: `DELETE FROM sch_teacher_profile WHERE id = X` | Delete succeeds; all referencing `tt_teacher_availabilities.teacher_profile_id` values set to NULL (ON DELETE SET NULL via `fk_tad_teacher_profile`) |
| 3 | Verify in UI | Records now appear as "unassigned" with teacher name "—" |

#### TC-D05: FK RESTRICT — Activity Referenced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a `tt_activities` record referenced by `tt_teacher_availabilities.activity_id` | — |
| 2 | Attempt to delete it | Integrity constraint violation for `fk_tad_activity` |

#### TC-D06: FK RESTRICT — Requirement Consolidation Referenced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a `tt_requirement_consolidations` record referenced by `tt_teacher_availabilities.requirement_consolidation_id` | — |
| 2 | Attempt to delete it | Integrity constraint violation (RESTRICT) |

#### TC-D07: Unique Key at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a row into `tt_teacher_availabilities` with a specific (requirement_consolidation_id, teacher_profile_id) pair | — |
| 2 | Insert another row with the same pair | Integrity constraint violation for `uq_ta_requirement_teacher` |

#### TC-D08: Unique Key — Details Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert a row into `tt_teacher_availability_details` with specific (teacher_profile_id, day_number, period_number) | — |
| 2 | Insert another row with the same combination | Integrity constraint violation for `uq_ta_class_wise` |

#### TC-D09 through TC-D13: Activity Logging

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a record (see TC-P09) | Activity log: action 'Created', message 'Teacher availability created.' |
| 2 | Soft-delete a record (see TC-P15) | Activity log: action 'Trashed', message 'Teacher availability was deactivated and moved to trash.' |
| 3 | Restore a record (see TC-P17) | Activity log: action 'Restored', message 'Teacher availability was restored successfully.' |
| 4 | Force delete a record (see TC-P18) | Activity log: action 'Deleted', message 'Teacher availability was permanently deleted.' |
| 5 | Toggle a record's status (see TC-P13) | Activity log: action 'Toggled', message 'Teacher availability status was updated.' |

#### TC-D14: Generate — Truncate Resets Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manually create a teacher availability record via POST | Record created with ID (e.g., ID=100) |
| 2 | Run "Generate from Requirements" | Table truncated; only newly generated records present |
| 3 | Query DB | Record ID=100 no longer exists; new auto-increment IDs assigned |

#### TC-D15: Generated Column Computation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create record with `teacher_available_from_date=2024-04-01`, `timetable_start_date=2024-04-05` | `available_for_full_timetable_duration=0`; `no_of_days_not_available=4` |
| 2 | Create record with `teacher_available_from_date=2024-04-01`, `timetable_start_date=2024-03-25` | `available_for_full_timetable_duration=1`; `no_of_days_not_available=0` |
| 3 | Create record with `teacher_available_from_date=2024-04-10`, `timetable_start_date=2024-04-10` | `available_for_full_timetable_duration=1`; `no_of_days_not_available=0` |
| 4 | Create record with `teacher_available_from_date=NULL`, `timetable_start_date=2024-04-05` | `available_for_full_timetable_duration=0` (IF NULL <= date → NULL, treated as 0); `no_of_days_not_available=0` (GREATEST(0, DATEDIFF(NULL, date)) = GREATEST(0, NULL) = 0) |

#### TC-D16: Model — `$casts` for Boolean/Decimal/Integer/Datetime

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAvailability.php` `$casts` array | Verify all boolean, integer, decimal:2, date, and datetime casts are correctly defined (see TC-CR02) |

#### TC-D17: Model — `$fillable` Excludes Generated Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TeacherAvailability.php` `$fillable` array | `available_for_full_timetable_duration` and `no_of_days_not_available` NOT present |
| 2 | Verify via mass assignment: `TeacherAvailability::create(['available_for_full_timetable_duration' => 1])` | Column is not fillable; mass assignment silently ignores it (or throws mass assignment exception if not guarded) |

---
