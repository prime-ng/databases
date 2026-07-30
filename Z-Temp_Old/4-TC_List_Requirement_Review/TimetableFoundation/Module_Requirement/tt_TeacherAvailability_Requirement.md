# Teacher Availability — Business Requirements

## What This Screen Does

The Teacher Availability screen is the **central resource-definition layer** for the timetable solver. It records, for every combination of (requirement consolidation, teacher profile), the constraints, preferences, and capacity metrics that govern how the solver may assign a specific teacher to a specific class–subject–section requirement.

This is **not** a simple master-data screen. It serves three distinct purposes:

1. **Availability & capacity definition** — How many periods per week a teacher can teach (`max_available_periods_weekly`), their minimum/maximum allocation ranges, shift preference, substitution eligibility, lab certification, and part-time status.
2. **Priority & optimisation scoring** — Proficiency percentage, scarcity index, historical success ratio, preference score, allocation strictness (Hard/Medium/Soft), and override priority — all feeding into the solver's weighted constraint optimisation.
3. **Timetable date scoping** — Teacher profile validity dates (`teacher_profile_from/to_date`), availability start date (`teacher_available_from_date`), and timetable window (`timetable_start/end_date`) — including two **GENERATED STORED** columns (`available_for_full_timetable_duration`, `no_of_days_not_available`) that pre-compute temporal readiness.

The screen also seeds a **per-period detail grid** via `AvailabilityCanvasService`: the `tt_teacher_availability_details` table stores one row per (teacher_profile_id × school_day × teaching_period), tracking `availability_for_period` status (`Available`, `Unavailable`, `Assigned`, `Free Period`) and optional assignment links to specific class/section/subject.

The screen lives under the **Resource Availability** menu (`timetable-foundation.menu.resourceAvailability`), tab `teacher-availability`. It has three special endpoints beyond standard CRUD:
- **`generateTeacherAvailability`** — Batch-generates availability records from `RequirementConsolidation` and `TeacherCapability` data.
- **`ratio`** — Returns teacher availability ratio data for dashboard/overview widgets.
- **`quickEdit`** — (Route defined, method not yet implemented) Intended for rapid per-slot toggling.

**Known naming inconsistency:** The model class is `TeacherAvailablity` (missing 'i') in some code paths (notably `AvailabilityCanvasService` and `TeacherAvailabilityDetail`), while the controller, primary model, and DDL all use `TeacherAvailability` (correct spelling). Both resolve to the same table `tt_teacher_availabilities`.

## When This Screen Is Used

- **After requirement consolidation generation** — Once `RequirementConsolidation` records are created for each (class, section, subject_study_format), the admin runs **Generate Teacher Availability** to populate `tt_teacher_availabilities` from matching `TeacherCapability` records.
- **Refining teacher constraints before solver run** — Before triggering the Smart Timetable solver, the Timetable Manager reviews each teacher's availability records, adjusting capacity limits, proficiency scores, scarcity indices, hard-constraint flags, and allocation strictness.
- **Viewing teacher–subject ratios** — The **ratio** view shows summary dashboards: teacher counts per subject, unassigned requirement counts, scarcity levels, and capacity utilisation.
- **Slot-level availability canvas** — After generating the detail canvas (`AvailabilityCanvasService`), the admin can inspect or toggle per-period availability status for each teacher.
- **Mid-term adjustments** — When a teacher's schedule changes (e.g., reduced hours, new subject assignment), the admin edits the relevant availability record or generates a fresh availability set.
- **Unassigned requirement coverage** — Records with `teacher_profile_id = null` represent requirements with no eligible teacher, surfaced in the ratio dashboard for resource planning.

## Default Data Load

The `TeacherAvailabilityController@index` authorises and redirects to the Resource Availability page. The actual data load happens in `TimetableFoundationController@resourceAvailability`, which provides:

**Teacher Availabilities List (main tab):**

```php
$teacherAvailabilities = TeacherAvailability::with([
    'teacherProfile.employee.user',
    'teacherProfile.employee.activeTeacherProfile.department',
    'class', 'section',
    'subjectStudyFormat.subject',
    'subjectStudyFormat.studyFormat',
    'requirementConsolidation',
    'preferredShift',
    'activity',
])->get();
```

Filters:

| Filter | Input name | Default |
|--------|------------|---------|
| Search (teacher name) | `ta_search` | None |
| Class ID | `ta_class_id` | None (all classes) |
| Section ID | `ta_section_id` | None |
| Subject Study Format | `ta_subject` | None |
| Shift | `ta_shift` | None |
| Status (is_active) | `ta_status` | `1` (active only) |
| Teacher Profile ID | `ta_teacher` | None |

Results are ordered by `created_at` descending and displayed in a table with columns: Profile, Class/Section, Subject, Required Periods, Available Periods, Shift, Proficiency, Scarcity, Preference Score, Hard Constraint, Status (toggle), Actions.

**Ratio Dashboard (ratio tab):**

The `ratio` endpoint (route `teacher-availability.ratio`) is not yet implemented in the controller but is expected to return:

- Total teacher availability count and unassigned count
- Teacher–subject ratios per class
- Capacity utilisation metrics
- Scarcity distribution
- `$taTotal = TeacherAvailability::where('is_active', true)->count()`
- `$taUnassigned = TeacherAvailability::where('is_active', true)->whereNull('teacher_profile_id')->count()`

**Availability Canvas Details (detail canvas tab):**

The `AvailabilityCanvasService@initializeTeacherCanvas` generates `tt_teacher_availability_details` rows after main availability generation. It wipes existing details for affected profiles, then creates one row per (teacher_profile_id × school_day × teaching_period), resolved against `TeacherUnavailable` rules.

## Key Fields at a Glance

**Core Identity and Scoping**

- **Requirement Consolidation** — FK to `tt_requirement_consolidations`. The parent requirement record that this availability satisfies. Together with `teacher_profile_id`, forms a unique composite key (`uq_ta_requirement_teacher`).
- **Class / Section** — FK to `sch_classes` / `sch_sections`. The target class and (optional) section for which the teacher is available.
- **Subject Study Format** — FK to `sch_subject_study_format_jnt`. The specific subject + study format combination.
- **Teacher Profile** — FK to `sch_teacher_profile`. Nullable — a `null` value means "no eligible teacher found for this requirement" (unassigned).

**Capacity and Availability**

- **Required Weekly Periods** (`required_weekly_periods`) — How many periods per week this requirement needs (default 1, copied from `requirement_consolidation`).
- **Is Full Time** (`is_full_time`) — Boolean. Does the teacher work full-time? Part-time teachers (false) have proportionally scaled availability.
- **Preferred Shift** (`preferred_shift`) — FK to `tt_shifts`. The shift (morning/afternoon/evening) the teacher prefers. Resolved from the teacher profile's `preferred_shift` string during generation.
- **Capable Handling Multiple Classes** (`capable_handling_multiple_classes`) — Boolean. Can this teacher manage multiple class groups simultaneously?
- **Can Be Used for Substitution** (`can_be_used_for_substitution`) — Boolean. Default `true`. Is this teacher eligible for substitute assignments?
- **Certified for Lab** (`certified_for_lab`) — Boolean. Can this teacher be assigned to laboratory/ practical sessions?
- **Can Be Split Across Sections** (`can_be_split_across_sections`) — Boolean. Can this teacher's available periods be split across different sections of the same class?

**Period Constraints (Consumed by Solver)**

- **Max Available Periods Weekly** (`max_available_periods_weekly`) — U TINYINT, default 48. Hard upper cap on total weekly periods the teacher can be assigned (including non-teaching duties). Source: `teacher_profile.max_periods_weekly`.
- **Min Available Periods Weekly** (`min_available_periods_weekly`) — U TINYINT, default 36. Minimum weekly periods the teacher should ideally be assigned.
- **Max Allocated Periods Weekly** (`max_allocated_periods_weekly`) — U TINYINT, default 1. Maximum periods per day for this specific (teacher × class × subject) combination. Source: `teacher_profile.max_periods_daily`.
- **Min Allocated Periods Weekly** (`min_allocated_periods_weekly`) — U TINYINT, default 1. Minimum periods per day for this combination.

**Scoring and Prioritisation**

- **Proficiency Percentage** (`proficiency_percentage`) — U TINYINT, nullable. How proficient the teacher is in this subject (0–100). Source: `TeacherCapability.proficiency_percentage`.
- **Teaching Experience Months** (`teaching_experience_months`) — U SMALLINT, nullable. Teacher's experience in this subject, in months.
- **Is Primary Subject** (`is_primary_subject`) — Boolean, default `true`. Whether this subject is the teacher's primary specialisation.
- **Competency Level** (`competancy_level`) — ENUM: `Advanced`, `Basic`, `Expert`, `Facilitator`, `Intermediate`. Default `Basic`. Note the **typo**: the column name is `competancy_level` (with 'a'), but the migration and DDL both use this spelling consistently. The `$fillable` array in the model also uses `competancy_level`.
- **Priority Order** (`priority_order`) — U INT, nullable. Relative priority of this teacher for this requirement (lower = higher priority).
- **Priority Weight** (`priority_weight`) — U TINYINT, nullable. Numeric weight for scoring, default 50.
- **Scarcity Index** (`scarcity_index`) — U TINYINT, nullable. Computed during generation: 1 (≥5 teachers), 4 (3–4), 7 (2), 10 (1). Higher = scarcer = more valuable teacher.
- **Is Hard Constraint** (`is_hard_constraint`) — Boolean, default `false`. When `true`, the solver MUST respect this teacher's allocation boundaries.
- **Allocation Strictness** (`allocation_strictness`) — ENUM: `Hard`, `Medium`, `Soft`. Default `Medium`. Determines how strictly the solver honours allocation bounds.
- **Override Priority** (`override_priority`) — U TINYINT, nullable. Manual override of the computed priority.
- **Override Reason** (`override_reason`) — VARCHAR, nullable. Free-text justification for the override.

**Historical Performance**

- **Historical Success Ratio** (`historical_success_ratio`) — U TINYINT, nullable. How often this teacher has been successfully allocated in past runs (0–100).
- **Last Allocation Score** (`last_allocation_score`) — U TINYINT, nullable. The score from the most recent solver run.
- **Is Primary Teacher** (`is_primary_teacher`) — Boolean, default `true`. Derived from `is_primary_subject` during generation.
- **Is Preferred Teacher** (`is_preferred_teacher`) — Boolean, default `false`. Set to `true` when `preference_score > 70`.
- **Preference Score** (`preference_score`) — U TINYINT, nullable. Computed during generation:
  ```
  score = (proficiency_percentage × 0.5) + (historical_success_ratio × 0.3) + (scarcity_index × 2)
  ```
- **Min / Max Teacher Availability Score** (`min/max_teacher_availability_score`) — DECIMAL(7,2). Computed as `score × 0.8` and `score × 1.2` respectively. Defines the acceptable scoring range for the solver.

**Temporal Scoping**

- **Teacher Profile From/To Date** — Validity range of the teacher's profile assignment. Nullable.
- **Teacher Available From Date** — The date from which the teacher becomes available. Nullable.
- **Timetable Start / End Date** — The timetable window for this availability record. Nullable.

**Generated Columns (NOT fillable)**

- **Available for Full Timetable Duration** (`available_for_full_timetable_duration`) — `TINYINT(1) GENERATED ALWAYS AS (IF(teacher_available_from_date <= timetable_start_date, 1, 0)) STORED`. Pre-computes whether the teacher is ready from day one.
- **No of Days Not Available** (`no_of_days_not_available`) — `INT GENERATED ALWAYS AS (GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))) STORED`. Number of days into the timetable before the teacher becomes available.

These generated columns must **NOT** be in `$fillable`. The model correctly excludes them.

**Detail-Level Fields (tt_teacher_availability_details)**

- **Day Number / Day Name** — Day of week (1–7) and name string.
- **Period Number** — Period ordinal within the day.
- **Can Be Assigned** (`can_be_assigned`) — Boolean. Derived from `availability_for_period`: `Available` → 1, otherwise 0.
- **Availability for Period** (`availability_for_period`) — ENUM: `Available` (default), `Unavailable`, `Assigned`, `Free Period`. Resolved from `TeacherUnavailable` rules during canvas initialisation.
- **Assigned Class / Section / Subject Study Format** — Nullable FKs; populated when the solver marks a slot as `Assigned`.
- **Activity ID** — FK to `tt_activities`. Populated when the slot is linked to a specific activity.

**Status Flags**
- `is_active` — Boolean, default `true`. Hides the record from active queries when inactive.
- `is_system` — Not present on this table (all records are user-managed).
- SoftDeletes: `deleted_at` — Nullable.

## Business Rules and Conditions

**BR-001 — Unique Requirement × Teacher Pair**
The composite unique key `uq_ta_requirement_teacher` on `(requirement_consolidation_id, teacher_profile_id)` ensures that for any given requirement, a teacher can have exactly one availability record. The generation logic uses `updateOrCreate` with `teacher_profile_id`, `class_id`, `section_id`, and `subject_study_format_id` as the match keys.

**BR-002 — Generated Columns Must Not Be Fillable**
`available_for_full_timetable_duration` and `no_of_days_not_available` are STORED GENERATED columns computed by MySQL. They MUST NOT appear in the model's `$fillable` array. Attempting to mass-assign them will either be silently ignored (if guarded) or cause a mass-assignment error (if fillable). The model correctly excludes them.

**BR-003 — Preference Score Auto-Calculation**
During `generateTeacherAvailability()`, the preference score is calculated as:
- `preference_score = ROUND((proficiency_percentage × 0.5) + (historical_success_ratio × 0.3) + (scarcity_index × 2))`
- `is_primary_teacher = is_primary_subject`
- `is_preferred_teacher = (preference_score > 70)`
- `min_teacher_availability_score = ROUND(preference_score × 0.8, 2)`
- `max_teacher_availability_score = ROUND(preference_score × 1.2, 2)`

**BR-004 — Scarcity Index Auto-Calculation**
After inserting all availability records, the generator groups by `(class_id, subject_study_format_id)` and assigns:
- Teacher count ≥ 5 → `scarcity_index = 1` (abundant)
- Teacher count ≥ 3 → `scarcity_index = 4` (moderate)
- Teacher count ≥ 2 → `scarcity_index = 7` (scarce)
- Teacher count = 1 → `scarcity_index = 10` (critical)

**BR-005 — Generation Truncates First**
`generateTeacherAvailability()` truncates the entire `tt_teacher_availabilities` table (disabling foreign key checks first) before re-inserting. This means all manual adjustments made since the last generation are lost. This is by design — the generation is a full rebuild, not an incremental update.

**BR-006 — Unassigned Records for Missing Teachers**
If a requirement consolidation has no eligible teacher (no matching `TeacherCapability` with the same class + subject_study_format), the generator creates a record with `teacher_profile_id = null`. These "unassigned" records are flagged in the ratio dashboard.

**BR-007 — Shift Resolution from Profile**
During generation, `preferred_shift` is resolved from the teacher's profile `preferred_shift` string by looking up the matching `tt_shifts` record by `code`. If no matching shift is found, `preferred_shift` remains `null`.

**BR-008 — Soft Delete with Deactivation Cascade**
When a teacher availability record is deleted via `destroy()`, the controller sets `is_active = false` before calling `delete()`. On restore, `is_active = true` is restored.

**BR-009 — Canvas Regeneration Rules**
The `AvailabilityCanvasService@initializeTeacherCanvas` wipes all existing `tt_teacher_availability_details` rows for the affected `teacher_profile_id` values, then rebuilds from scratch using active `SchoolDay` records, teaching `PeriodSetPeriod` records, and `TeacherUnavailable` rules. If no unavailability rules match, every period defaults to `Available`.

**BR-010 — Solver Uses Availability for Constraint Enforcement**
The `TimetableGenerationService` and `PrimeSolver` read `tt_teacher_availabilities` for:
- `max_available_periods_weekly` as the hard cap on weekly assignments.
- `is_hard_constraint` and `allocation_strictness` for constraint pacing.
- `is_primary_instructor` (via `tt_teacher_assignment_roles`) for lead-teacher identification.
- `preference_score`, `scarcity_index`, and `proficiency_percentage` for weighted optimisation.

**BR-011 — Date Scoping Validation (Not Fully Implemented)**
The model provides helper methods `isCurrentlyEffective()` and `isUsable()` but there is no controller-side validation that enforces:
- `teacher_available_from_date ≤ timetable_end_date`
- `timetable_start_date ≤ timetable_end_date`
This is a known gap.

## Workflow Steps

**Generating Teacher Availability (Batch)**

1. Admin navigates to **Resource Availability → Teacher Availability** tab.
2. Clicks **"Generate Teacher Availability"** button.
3. `POST /teacher-availability/generate` → `generateTeacherAvailability()`.
4. `Gate::authorize('timetable-foundation.teacher-availability.generate')`.
5. System **truncates** `tt_teacher_availabilities` (FK checks disabled temporarily).
6. Loads all active `RequirementConsolidation` records.
7. Ensures PRIMARY and ASSISTANT `TeacherAssignmentRole` records exist (creates them if missing).
8. For each requirement:
   - Finds eligible `TeacherCapability` records (same class_id + subject_study_format_id, active, within effective date range).
   - If none found → creates unassigned record (teacher_profile_id = null).
   - For each eligible teacher → `updateOrCreate` availability record with profile-derived defaults.
9. After all records inserted:
   - Computes `scarcity_index` per (class, subject) group.
   - Computes `preference_score`, `is_primary_teacher`, `is_preferred_teacher`, and score range for each record.
10. Commits transaction.
11. Returns success message with counts: `"{createdCount} assigned, {skippedCount} unassigned, {errorCount} errors"`.

**Creating a Single Availability Record**

1. Admin clicks **"Add New"** → `create()`.
2. Fills form: Class, Section, Subject Study Format, Teacher Profile, Required Weekly Periods, Is Full Time, Max Available Periods Weekly.
3. `POST /teacher-availability` → `store()`.
4. Validation runs (class_id, section_id, subject_study_format_id required; teacher_profile_id optional).
5. `TeacherAvailability::create($validated)`.
6. Activity log entry created.
7. Redirect to teacher-availability index with success flash.

**Viewing and Editing Records**

1. Admin clicks **View** on a row → `show($id)` — loads with all relationships eager-loaded (teacherProfile, class, section, subjectStudyFormat, requirementConsolidation, preferredShift, activity).
2. Admin clicks **Edit** → `edit($id)` → renders edit form.
3. On submit → `PATCH /teacher-availability/{id}` → `update()` (Note: the current `update()` method only calls `Gate::authorize` and returns without persisting — the implementation is incomplete).

**Soft-Deleting a Record**

1. Admin clicks **Trash** → `destroy($id)`.
2. `is_active = false` → `save()` → `delete()`.
3. Activity log entry created.
4. Redirect with success flash.

**Quick Edit (Route Defined, Not Yet Implemented)**

The route `PATCH /teacher-availability/{id}/quick-edit` → `quickEdit()` exists but the method is not implemented in the controller. Intended to support rapid toggling of per-period availability without loading the full edit form.

**Viewing Ratio Dashboard**

The route `GET /teacher-availability-ratio` → `ratio()` exists but the method is not implemented in the controller. The ratio data is partially prepared in `TimetableFoundationController@resourceAvailability` via queries for total counts, unassigned counts, and capacity maps.

## Example Scenario

Mr. Kumar, the Timetable Manager at Gurukul Academy, is preparing for the new academic term:

**Step 1: Generate Availability**

Mr. Kumar has already generated Requirement Consolidations. He navigates to Resource Availability → Teacher Availability and clicks **"Generate Teacher Availability"**. The system processes 20 requirement consolidations:

- For **Class 10, Subject: Mathematics (Theory)**, it finds 3 eligible teachers: Ms. Sharma (15 yrs exp, 90% proficiency), Mr. Verma (8 yrs, 75%), and Ms. Patel (2 yrs, 60%).
- It creates availability records for each, with proficiency and experience sourced from their `TeacherCapability` records.
- Scarcity index for (Class 10, Math Theory): 3 teachers → index = 4 (moderate).
- For **Class 10, Subject: Computer Science (Lab)**, only 1 teacher (Mr. Iyer) is found → `scarcity_index = 10` (critical).
- For **Class 9, Subject: Sanskrit**, no eligible teacher exists → an unassigned record with `teacher_profile_id = null` is created.

Result: 45 assigned records, 1 unassigned, 0 errors.

**Step 2: Review and Adjust**

Mr. Kumar reviews the generated records:

1. He sees Ms. Sharma's record for Class 10 Math: `proficiency_percentage = 90`, `preference_score = 82`. The system auto-set `is_preferred_teacher = true` (score > 70).
2. For Mr. Verma, `preference_score = 60`. Mr. Kumar manually overrides `override_priority = 1` and adds a reason: "Senior teacher, should be prioritised."
3. Mr. Kumar sets `is_hard_constraint = true` for Ms. Patel because she is a part-time teacher who can only teach 20 periods per week.

**Step 3: Canvas Initialisation (Background)**

The system initialises the `tt_teacher_availability_details` canvas, creating one row per teacher per school day per teaching period. Mr. Iyer (Computer Science, the only lab teacher) has all periods default `Available`. No `TeacherUnavailable` rules exist yet.

## Related Screens

| Screen | Module | Relationship |
|--------|--------|-------------|
| **Requirement Consolidation** | Timetable Foundation | Parent data source for `requirement_consolidation_id`. Generate runs `RequirementConsolidation::withoutTrashed()->where('is_active', true)` to drive availability creation. |
| **Teacher Capability** | SchoolSetup | Source of `TeacherCapability` records matched on `(class_id, subject_study_format_id)` during generation. Provides proficiency, experience, priority, and constraint defaults. |
| **Teacher Profile** | SchoolSetup | FK `teacher_profile_id`. Provides `is_full_time`, `preferred_shift`, `max_periods_weekly`, `max_periods_daily`, and other default values. |
| **Teacher Assignment Roles** | Timetable Foundation | The `generate` method ensures PRIMARY and ASSISTANT roles exist. Solver uses roles to identify primary instructors. |
| **Activity Teachers** | Timetable Foundation | `tt_activity_teachers` stores the actual pivot linking activities to teachers with roles. Populated from availability data. |
| **Teacher Unavailable** | SmartTimetable | Per-teacher unavailability rules (days + periods) consumed by `AvailabilityCanvasService` to initialise the detail canvas. |
| **Availability Canvas** | SmartTimetable | `AvailabilityCanvasService@initializeTeacherCanvas` generates `tt_teacher_availability_details` from availability records. |
| **Smart Timetable Solver** | SmartTimetable | `TimetableGenerationService` and `PrimeSolver` consume availability constraints for teacher allocation. |
| **Priority Config** | Timetable Foundation | `PriorityConfigService@avgTeacherAvailabilityByRc` computes average availability scores per requirement consolidation for priority tuning. |

## Requirements

**REQ-TA-001 — Display Availabilities List**
The system MUST display `tt_teacher_availabilities` records in a searchable, filterable table with columns: Teacher Profile, Class/Section, Subject, Required Periods, Available Periods, Shift, Proficiency, Scarcity Index, Preference Score, Hard Constraint, Status (toggle), Actions (View, Edit, Trash).

**REQ-TA-002 — Create Single Availability Record**
The system MUST allow authorised users to create a single availability record with: class_id, section_id, subject_study_format_id, teacher_profile_id (nullable), required_weekly_periods, is_full_time, max_available_periods_weekly.

**REQ-TA-003 — View Availability Detail**
The system MUST display a read-only detail view of a single availability record with all fields and relationships (teacherProfile, class, section, subjectStudyFormat, requirementConsolidation, preferredShift, activity).

**REQ-TA-004 — Edit Availability Record**
The system MUST allow authorised users to edit an existing availability record. Note: The `update()` method in the controller is a **stub** — it only authorises and returns without persisting changes. This needs implementation.

**REQ-TA-005 — Soft Delete Availability Record**
The system MUST allow authorised users to soft-delete a record. On delete, `is_active` MUST be set to `false` before `delete()`.

**REQ-TA-006 — Restore Availability Record**
The system MUST allow authorised users to restore a soft-deleted record. On restore, `is_active = true`.

**REQ-TA-007 — Force Delete Availability Record**
The system MUST allow authorised users to permanently delete a soft-deleted record.

**REQ-TA-008 — Toggle Status (AJAX)**
The system MUST allow authorised users to toggle `is_active` via an AJAX POST request, returning JSON `{ success, is_active, message }`.

**REQ-TA-009 — Generate Teacher Availability (Batch)**
The system MUST provide a batch generation endpoint (`POST /teacher-availability/generate`) that:
1. Truncates existing records.
2. Reads all active `RequirementConsolidation` records.
3. Matches each to eligible `TeacherCapability` records.
4. Creates availability records with defaults from teacher profiles.
5. Computes scarcity index and preference scores.
6. Creates unassigned records for requirements with no eligible teachers.
7. Ensures PRIMARY and ASSISTANT roles exist.
8. Returns a summary of created, unassigned, and error counts.

**REQ-TA-010 — Ratio Dashboard (Stub)**
The system MUST provide a ratio endpoint (`GET /teacher-availability-ratio`) that returns teacher availability summary metrics. **Note:** The `ratio()` method is not yet implemented.

**REQ-TA-011 — Quick Edit (Stub)**
The system MUST provide a quick edit endpoint (`PATCH /teacher-availability/{id}/quick-edit`). **Note:** The `quickEdit()` method is not yet implemented.

**REQ-TA-012 — Generated Columns Excluded from Fillable**
The model MUST exclude `available_for_full_timetable_duration` and `no_of_days_not_available` from `$fillable` because they are GENERATED STORED columns computed by MySQL.

**REQ-TA-013 — Activity Logging**
The system MUST record an audit log entry via `activityLog()` for every create, update, soft-delete, restore, force-delete, and toggle-status operation.

**REQ-TA-014 — View Trashed Records**
The system MUST display a paginated list of soft-deleted availability records with options to Restore or Force Delete.

**REQ-TA-015 — Unique Requirement × Teacher Constraint**
The system MUST enforce that each (requirement_consolidation_id, teacher_profile_id) pair is unique, enforced by the `uq_ta_requirement_teacher` database index.

## Who Can Access

| Role | Permission Key | Operations |
|------|---------------|------------|
| Super Admin | `timetable-foundation.teacher-availability.*` | All operations |
| Timetable Manager (view) | `timetable-foundation.teacher-availability.viewAny` | View list, view detail |
| Timetable Manager (create) | `timetable-foundation.teacher-availability.create` | Create single records |
| Timetable Manager (update) | `timetable-foundation.teacher-availability.update` | Edit records, toggle status |
| Timetable Manager (delete) | `timetable-foundation.teacher-availability.delete` | Soft delete |
| Timetable Manager (restore) | `timetable-foundation.teacher-availability.restore` | Restore trashed records |
| Timetable Manager (forceDelete) | `timetable-foundation.teacher-availability.forceDelete` | Force delete |
| Timetable Manager (generate) | `timetable-foundation.teacher-availability.generate` | Run batch generation |
| Teacher | None | No access (administrative) |

The `TeacherAvailabilityPolicy` gates each method. The `generateTeacherAvailability` method uses a `generate` permission key (checked via `Gate::authorize('timetable-foundation.teacher-availability.generate')`).

## Logic Flow

### Batch Generation Flow

```
Admin clicks "Generate Teacher Availability"
        │
        ▼
POST /teacher-availability/generate
        │
        ▼
Gate::authorize('timetable-foundation.teacher-availability.generate')
        │
        ▼ (authorised)
DB::statement('SET FOREIGN_KEY_CHECKS=0')
        │
        ▼
TeacherAvailability::truncate()
        │
        ▼
DB::statement('SET FOREIGN_KEY_CHECKS=1')
DB::beginTransaction()
        │
        ▼
Load active RequirementConsolidation records
        │
        ▼ (none found → rollback → error)
Ensure PRIMARY + ASSISTANT TeacherAssignmentRole records exist
        │
        ▼
For each requirement:
  ├── Find eligible TeacherCapability (class_id + subject_study_format_id)
  ├── If none → create unassigned record (teacher_profile_id = null)
  └── For each eligible teacher:
        ├── Resolve shift_id from profile.preferred_shift
        ├── TeacherAvailability::updateOrCreate(
        │     match: [teacher_profile_id, class_id, section_id, subject_study_format_id],
        │     data: [all fields from profile + capability]
        │   )
        └── Count ++
        │
        ▼
Compute scarcity_index per (class_id, subject_study_format_id) group
        │
        ▼
Compute preference_score, is_primary_teacher, is_preferred_teacher,
  min/max_teacher_availability_score for each record
        │
        ▼
DB::commit()
        │
        ▼
Return redirect with summary message
```

### Store Flow (Single Record)

```
User submits create form
        │
        ▼
Gate::authorize('create')
        │
        ▼
Validate: class_id, section_id, subject_study_format_id (required)
          teacher_profile_id (nullable), required_weekly_periods (nullable int 1-60)
          is_full_time (nullable bool), max_available_periods_weekly (nullable int 1-60)
        │
        ▼
TeacherAvailability::create($validated)
        │
        ▼
activityLog('Created')
        │
        ▼
Redirect → teacher-availability.index
```

## Validate Before Save

The `store()` method applies these validation rules:

| Field | Rule | Error Message |
|-------|------|---------------|
| `class_id` | `required`, `integer`, `exists:sch_classes,id` | "The class field is required." / "Selected class is invalid." |
| `section_id` | `required`, `integer`, `exists:sch_sections,id` | "The section field is required." / "Selected section is invalid." |
| `subject_study_format_id` | `required`, `integer`, `exists:sch_subject_study_formats,id` | "The subject field is required." / "Selected subject is invalid." |
| `teacher_profile_id` | `nullable`, `integer`, `exists:sch_teacher_profiles,id` | "Selected teacher profile is invalid." |
| `required_weekly_periods` | `nullable`, `integer`, `min:1`, `max:60` | "Required weekly periods must be between 1 and 60." |
| `is_full_time` | `nullable`, `boolean` | Coerced via `$request->boolean()`. |
| `max_available_periods_weekly` | `nullable`, `integer`, `min:1`, `max:60` | "Max available periods must be between 1 and 60." |

**Known gap:** The `update()` method only authorises and returns — no validation or persistence logic is implemented. The form validation rules for edit must match the create rules.

## Error Handling and Validation Messages

| Scenario | HTTP Status | Response |
|----------|-------------|----------|
| Validation failure (store) | 302 Redirect | Redirect back with `$errors` bag |
| Model not found (show/edit/destroy) | 404 | `ModelNotFoundException` → 404 page |
| Not authorised (any operation) | 403 | `AuthorizationException` → 403 |
| Toggle status failure on save | 422 JSON | `{ success: false, is_active, message }` |
| Generation: no active requirements | 302 Redirect | Flash error: "No active Requirement Consolidations found. Please generate requirements first." |
| Generation: database error during insert | 302 Redirect | Flash error: "Error: <exception message>" — transaction rolled back |
| Generation: unexpected exception | 302 Redirect | Flash error: "Error: <exception message>" — transaction rolled back, error logged |
| Toggle status: validation failure | 422 JSON | `{ success: false, message }` |

## Success Scenarios

**SC-001 — Batch Generation with All Teachers Assigned**
Mr. Kumar runs Generate for 20 requirement consolidations. All 20 have matching teachers. Result: "Teacher Availability: 45 assigned, 0 unassigned, 0 errors. (Requirements: 20)"

**SC-002 — Batch Generation with Some Unassigned**
Mr. Kumar runs Generate. 19 of 20 requirements have teachers. Result: "Teacher Availability: 42 assigned, 1 unassigned, 0 errors." The unassigned record appears in the list with blank teacher profile.

**SC-003 — Create Single Record**
Ms. Sharma manually creates a record for a new part-time teacher: Class 5A, Subject English, Teacher = Ms. Patel, Part-Time, Max 24 periods/week. Record created successfully.

**SC-004 — Toggle Status via AJAX**
Mr. Kumar toggles a record inactive. Returns `{ success: true, is_active: false }`. The record disappears from active queries.

**SC-005 — Restore Deleted Record**
Mr. Kumar restores a trashed record. It reappears with `is_active = true` and is visible in the active list.

## Failure Scenarios

**FC-001 — Generate with No Requirements**
Mr. Kumar clicks Generate before creating Requirement Consolidations. The system finds zero active requirements and returns: "No active Requirement Consolidations found. Please generate requirements first."

**FC-002 — Duplicate Requirement × Teacher Pair**
The `updateOrCreate` logic in `generateTeacherAvailability` prevents duplicates by matching on `(teacher_profile_id, class_id, section_id, subject_study_format_id)`. If somehow a duplicate is attempted, the `uq_ta_requirement_teacher` unique key on `(requirement_consolidation_id, teacher_profile_id)` enforces it at the database level, throwing an integrity constraint violation.

**FC-003 — Database Error During Generation**
If a SQL error occurs during the batch insert loop, the transaction is rolled back and the user sees: "Error: <SQL exception message>". The `tt_teacher_availabilities` table remains empty (it was truncated before the transaction began).

**FC-004 — Unauthorised Access to Generate**
A user without `timetable-foundation.teacher-availability.generate` permission clicks Generate. `Gate::authorize()` throws 403.

**FC-005 — Update Method Is a Stub**
If a user edits and saves a record, the `update()` method authorises the user but returns without saving changes. The user sees a blank response or the edit form again. This is a **known gap** — the `update()` method needs full implementation.

**FC-006 — Quick Edit Not Implemented**
If a user attempts to use the quick-edit feature (route `PATCH /teacher-availability/{id}/quick-edit`), the framework throws a `MethodNotAllowedHttpException` or `NotFoundHttpException` because the `quickEdit()` method doesn't exist on the controller. This is a **known gap**.

**FC-007 — Ratio Endpoint Not Implemented**
If a user navigates to `GET /teacher-availability-ratio`, the framework throws a `NotFoundHttpException` because the `ratio()` method doesn't exist on the controller. This is a **known gap**.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_teacher_availabilities` | Primary table | All main availability records. See full schema below. |
| `tt_teacher_availability_details` | Detail table | Per-period availability canvas. One row per (teacher_profile_id × day_number × period_number). Unique: `(teacher_profile_id, day_number, period_number)`. |
| `tt_requirement_consolidations` | FK parent | `requirement_consolidation_id` FK references `tt_requirement_consolidations(id)`. RESTRICT on delete. |
| `sch_classes` | FK parent | `class_id` FK via `fk_ta_class`. RESTRICT on delete. |
| `sch_sections` | FK parent | `section_id` FK via `fk_ta_section`. RESTRICT on delete. |
| `sch_subject_study_format_jnt` | FK parent | `subject_study_format_id` FK via `fk_ta_subject_study_format`. RESTRICT on delete. |
| `sch_teacher_profile` | FK parent | `teacher_profile_id` FK via `fk_tad_teacher_profile`. SET NULL on delete. |
| `tt_activities` | FK parent | `activity_id` FK via `fk_tad_activity`. |
| `tt_shifts` | FK parent | `preferred_shift` references `tt_shifts(id)`. |
| `sch_teacher_profile` (detail) | FK parent | `teacher_profile_id` in `tt_teacher_availability_details` via `fk_tadet_teacher_profile`. |
| `TeacherCapability` | Service dependency | Source data for generation queries. |
| `TeacherUnavailable` | Service dependency | Consumed by `AvailabilityCanvasService` for detail canvas initialisation. |
| `AvailabilityCanvasService` | Service dependency | Initialises per-period detail rows. |
| `PriorityConfigService` | Service dependency | Computes average teacher availability scores for priority configuration. |
| `Modules\TimetableFoundation\Models\TeacherAvailability` | Eloquent model | Uses `SoftDeletes`. See fillable/casts below. |
| `Modules\SmartTimetable\Models\TeacherAvailabilityDetail` | Eloquent model | No timestamps. Belongs to `TeacherAvailablity` (note typo). |
| `TeacherAvailabilityPolicy` | Auth policy | Gates all CRUD + generate operations. |
| `activityLog()` helper | Service dependency | Called on every state change. |

**Table:** `tt_teacher_availabilities`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `requirement_consolidation_id` | INT UNSIGNED | FK → `tt_requirement_consolidations(id)` |
| `class_id` | INT UNSIGNED | FK → `sch_classes(id)` via `fk_ta_class` |
| `section_id` | INT UNSIGNED | NULLABLE. FK → `sch_sections(id)` via `fk_ta_section` |
| `subject_study_format_id` | INT UNSIGNED | FK → `sch_subject_study_format_jnt(id)` via `fk_ta_subject_study_format` |
| `teacher_profile_id` | INT UNSIGNED | NULLABLE. FK → `sch_teacher_profile(id)` via `fk_tad_teacher_profile`. SET NULL on delete. |
| `required_weekly_periods` | TINYINT UNSIGNED | DEFAULT 1 |
| `is_full_time` | BOOLEAN | DEFAULT TRUE |
| `preferred_shift` | INT UNSIGNED | NULLABLE. FK → `tt_shifts(id)` |
| `capable_handling_multiple_classes` | BOOLEAN | DEFAULT FALSE |
| `can_be_used_for_substitution` | BOOLEAN | DEFAULT TRUE |
| `certified_for_lab` | BOOLEAN | DEFAULT FALSE |
| `max_available_periods_weekly` | TINYINT UNSIGNED | DEFAULT 48 |
| `min_available_periods_weekly` | TINYINT UNSIGNED | DEFAULT 36 |
| `max_allocated_periods_weekly` | TINYINT UNSIGNED | DEFAULT 1 |
| `min_allocated_periods_weekly` | TINYINT UNSIGNED | DEFAULT 1 |
| `can_be_split_across_sections` | BOOLEAN | DEFAULT FALSE |
| `proficiency_percentage` | TINYINT UNSIGNED | NULLABLE |
| `teaching_experience_months` | SMALLINT UNSIGNED | NULLABLE |
| `is_primary_subject` | BOOLEAN | DEFAULT TRUE |
| `competancy_level` | ENUM('Advanced','Basic','Expert','Facilitator','Intermediate') | DEFAULT 'Basic' |
| `priority_order` | INT UNSIGNED | NULLABLE |
| `priority_weight` | TINYINT UNSIGNED | NULLABLE |
| `scarcity_index` | TINYINT UNSIGNED | NULLABLE. 1, 4, 7, or 10 |
| `is_hard_constraint` | BOOLEAN | DEFAULT FALSE |
| `allocation_strictness` | ENUM('Hard','Medium','Soft') | DEFAULT 'Medium' |
| `override_priority` | TINYINT UNSIGNED | NULLABLE |
| `override_reason` | VARCHAR(255) | NULLABLE |
| `historical_success_ratio` | TINYINT UNSIGNED | NULLABLE |
| `last_allocation_score` | TINYINT UNSIGNED | NULLABLE |
| `is_primary_teacher` | BOOLEAN | DEFAULT TRUE |
| `is_preferred_teacher` | BOOLEAN | DEFAULT FALSE |
| `preference_score` | TINYINT UNSIGNED | NULLABLE |
| `teacher_profile_from_date` | DATE | NULLABLE |
| `teacher_profile_to_date` | DATE | NULLABLE |
| `teacher_available_from_date` | DATE | NULLABLE |
| `timetable_start_date` | DATE | NULLABLE |
| `timetable_end_date` | DATE | NULLABLE |
| `available_for_full_timetable_duration` | TINYINT(1) | **GENERATED STORED**. `IF(teacher_available_from_date <= timetable_start_date, 1, 0)` |
| `no_of_days_not_available` | INT | **GENERATED STORED**. `GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))` |
| `min_teacher_availability_score` | DECIMAL(7,2) | DEFAULT 1.00 |
| `max_teacher_availability_score` | DECIMAL(7,2) | DEFAULT 1.00 |
| `activity_id` | INT UNSIGNED | NULLABLE. FK → `tt_activities(id)` via `fk_tad_activity` |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| `created_at` | TIMESTAMP | NULLABLE |
| `updated_at` | TIMESTAMP | NULLABLE |
| `deleted_at` | TIMESTAMP | NULLABLE. SoftDeletes |

**Unique Keys:**
- `uq_ta_requirement_teacher` — on `(requirement_consolidation_id, teacher_profile_id)` (ensures unique teacher per requirement)

**GENERATED STORED Columns (NOT fillable):**
- `available_for_full_timetable_duration`
- `no_of_days_not_available`

**Table:** `tt_teacher_availability_details`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | Primary key, auto-increment |
| `teacher_availability_id` | INT UNSIGNED | FK → `tt_teacher_availabilities(id)` |
| `teacher_profile_id` | INT UNSIGNED | FK → `sch_teacher_profile(id)` via `fk_tadet_teacher_profile` |
| `day_number` | TINYINT UNSIGNED | 1–7 |
| `day_name` | VARCHAR(10) | e.g., 'Monday', 'Tuesday' |
| `period_number` | TINYINT UNSIGNED | Period ordinal |
| `can_be_assigned` | BOOLEAN | DEFAULT TRUE |
| `availability_for_period` | ENUM('Assigned','Available','Free Period','Unavailable') | DEFAULT 'Available' |
| `teacher_available_from_date` | DATE | NULLABLE |
| `assigned_class_id` | INT UNSIGNED | NULLABLE. FK → `sch_classes(id)` |
| `assigned_section_id` | INT UNSIGNED | NULLABLE. FK → `sch_sections(id)` |
| `assigned_subject_study_format_id` | INT UNSIGNED | NULLABLE. FK → `sch_subject_study_format_jnt(id)` |
| `activity_id` | INT UNSIGNED | NULLABLE. FK → `tt_activities(id)` |
| `is_active` | BOOLEAN | DEFAULT TRUE |
| *No timestamps* | | Model has `$timestamps = false` |

**Unique Keys:**
- `uq_ta_class_wise` — on `(teacher_profile_id, day_number, period_number)`
- `uq_ta_class_wise_assignment` — on `(teacher_profile_id, day_number, period_number, assigned_class_id, assigned_section_id, assigned_subject_study_format_id)`
