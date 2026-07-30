# Requirements Consolidation — Business Requirements

## What This Screen Does

Requirements Consolidation is the bridge between curriculum planning and timetable generation. It aggregates all scheduling requirements — class-subject groups (compulsory subjects) and class-subject subgroups (optional/elective subjects) — into a single consolidated view for a given academic term and timetable type. Administrators can review total weekly period load per class-section-subject, identify imbalances, adjust scheduling parameters inline, and ensure every subject gets its required periods before activity generation and timetable solving begin.

## When This Screen Is Used

- After defining class-subject groups and subgroups, when the administrator needs a unified view of all scheduling requirements for a specific academic term and timetable type
- Before activity generation, to review and adjust period counts, daily constraints, consecutive period rules, and priority scores
- When identifying over/under-allocation patterns across classes and sections
- After curriculum changes, to regenerate the consolidated requirements from updated group/subgroup data
- When configuring period preferences (preferred slots, avoided slots) for solver guidance
- Before the timetable solver runs, to ensure all constraint parameters (min/max periods, gaps, consecutive rules, sharing flags) are correctly set

## Default Data Load

The screen loads via the **Timetable Preparation** page accessed at `timetable-foundation.menu.timetablePreparation` with tab parameter `?tab=requirement-consolidation`. The `RequirementConsolidationController@index()` method gates with `requirement-consolidation.viewAny` then redirects to the menu route. Default data load includes:

- Consolidated grid of `tt_requirement_consolidations` records for the selected academic term and timetable type (paginated)
- Each row shows: class, section, subject, study format, required weekly periods, min/max per week/day, gap rules, consecutive period settings, priority score, sharing flags, room requirements, and status toggle
- Academic term and timetable type selectors at the top to scope the grid

## Key Fields at a Glance

**Requirement Consolidations (`tt_requirement_consolidations`)**

| Column | Description |
|--------|-------------|
| `academic_term_id` | Academic term for which this timetable is being generated (SET NULL on term delete) |
| `timetable_type_id` | Timetable type — Standard, Exam, etc. (SET NULL on type delete) |
| `class_requirement_group_id` | Parent class requirement group (mutually exclusive with subgroup, CASCADE on delete) |
| `class_requirement_subgroup_id` | Parent requirement subgroup (mutually exclusive with group, CASCADE on delete) |
| `class_id` | Target class |
| `section_id` | Target section (NULL = all sections) |
| `subject_id` | Subject being scheduled |
| `study_format_id` | Study format (SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.) |
| `subject_type_id` | Subject type (MAJOR, MINOR, OPTIONAL, etc.) |
| `is_compulsory` | Whether this requirement is compulsory |
| `required_weekly_periods` | Total periods required per week for this class-section-subject-format |
| `min_periods_required_per_week` | Minimum periods allowed per week |
| `max_periods_required_per_week` | Maximum periods allowed per week |
| `min_periods_required_per_day` | Minimum periods allowed per day |
| `max_periods_required_per_day` | Maximum periods allowed per day |
| `min_gap_between_periods` | Minimum gap between periods (in period units) |
| `required_consecutive_periods` | Required number of consecutive periods |
| `allow_consecutive_periods` | Whether consecutive periods are allowed |
| `max_consecutive_periods` | Maximum consecutive periods allowed (default 2) |
| `class_priority_score` | Priority score for scheduling (0–100) |
| `preferred_periods_json` | Preferred period slots (JSON array) |
| `avoid_periods_json` | Periods to avoid (JSON array) |
| `spread_evenly` | Whether periods should be spread evenly (1 period per day) |
| `is_shared_across_sections` | Whether this requirement is shared across sections |
| `is_shared_across_classes` | Whether this requirement is shared across classes |
| `compulsory_specific_room_type` | Whether a specific room type is mandatory |
| `required_room_type_id` | Required room type |
| `required_room_id` | Specific required room (optional) |

## Business Rules and Conditions

**Mutually Exclusive Target (Group XOR Subgroup).** A requirement consolidation record MUST target either a `class_requirement_group_id` OR a `class_requirement_subgroup_id`, but NOT both. This is enforced by a CHECK constraint (`chk_cgr_target`) at the database level and application-level validation with the message "Select either a class group or a class subgroup (not both)."

**Unique Per (Term × Type × Group/Subgroup).** The composite UNIQUE key `uq_cgr_group_session` on `(academic_term_id, timetable_type_id, class_requirement_group_id, class_requirement_subgroup_id)` ensures exactly one consolidation record per unique combination. Batch generation uses `upsert()` with these columns as the match key.

**Weekly Min/Max Consistency.** When both `min_periods_required_per_week` and `max_periods_required_per_week` are set, the minimum MUST NOT exceed the maximum. Same rule applies for daily min/max.

**Consecutive Period Logic.** If `allow_consecutive_periods` is false, the system forces `max_consecutive_periods = 1`.

**Shared Scope Mutually Exclusive.** `is_shared_across_sections` and `is_shared_across_classes` are mutually exclusive — only one can be active at a time. The UI uses a radio-style `shared_scope` field with values `none | section | class`.

**Generation Is Destructive.** The `generateRequirements()` method truncates the entire `tt_requirement_consolidations` table (with foreign key checks temporarily disabled) before regenerating from source groups and subgroups. All manual adjustments are permanently lost on regeneration.

**Source Data Cascade.** If a source ClassSubjectGroup or ClassSubjectSubgroup is deleted, the corresponding consolidation records are cascade-deleted via ON DELETE CASCADE FKs.

**Academic Term and Timetable Type Persist with NULL.** If an academic term or timetable type is deleted, the corresponding FK columns are set to NULL (ON DELETE SET NULL). The consolidation record survives but loses its scoping context.

**Compulsory Classification from Source.** Records generated from ClassSubjectGroup are always marked `is_compulsory = true`. Records generated from ClassSubjectSubgroup inherit `is_compulsory` from the parent `schClassGroup` relation.

**Soft Delete with Deactivation.** When `destroy()` is called, the controller sets `is_active = false` before calling `delete()`. On `restore()`, `is_active` is set back to `true`.

**Editable Fields via AJAX Inline Update.** Only whitelisted fields can be edited via `ajaxInlineUpdate()`: `required_weekly_periods`, min/max per week/day, gap rules, consecutive period settings, priority score, spread_evenly, is_compulsory, sharing flags, room requirement flags, student_count, eligible_teacher_count, and is_active. Any other field is rejected with 422.

## Workflow Steps

**Generate Consolidated Requirements.** The administrator selects an academic term and timetable type on the requirement-consolidation tab, then clicks "Generate Requirements". The system truncates all existing consolidation records, then processes all active ClassSubjectGroup records via `processClassSubjectGroups()` (mapping each group to a consolidation record marked as compulsory) and all active ClassSubjectSubgroup records via `processClassSubjectSubgroups()` (inheriting compulsory flags from parent groups). Both use `upsert()` for batch insertion. The total count is displayed.

**Review the Consolidated Grid.** The administrator sees every class-section-subject-study-format combination in a unified table with all scheduling parameters. Each row shows the required weekly periods, min/max per day/week, gap rules, consecutive period settings, priority score, sharing flags, and room requirements.

**Inline Edit Parameters.** The administrator clicks an inline edit icon on any editable field, changes the value, and saves. The `ajaxInlineUpdate()` method validates the field against the whitelist, casts booleans using `filter_var()`, updates the record, and returns a JSON success response.

**Update Sharing Scope.** The administrator clicks the sharing toggle and selects "None", "Across Sections", or "Across Classes". The `updateRequirement()` method converts the radio value to the corresponding boolean flags and enforces mutual exclusivity. Returns JSON success.

**Set Period Preferences.** The administrator clicks "Set Preferences" on a record, selects preferred period slots and/or avoided period slots from a multiselect. The `updatePeriods()` method saves the selections as JSON arrays in `preferred_periods_json` and `avoid_periods_json`.

**Toggle Status.** The administrator toggles a consolidation record's active/inactive status. Inactive records are excluded from activity generation but remain in the database.

**Soft Delete and Restore.** The administrator clicks Trash to deactivate and soft-delete a record. The trash view shows all soft-deleted records for restore or force delete.

## Example Scenario

Mr. Kumar, the timetable manager at Gurukul Academy, has set up 15 active ClassSubjectGroup records (compulsory subjects across Class 10 sections) and 8 active ClassSubjectSubgroup records (optional/elective subjects). He navigates to Timetable Preparation → requirement-consolidation tab, selects "2025-26 TERM-1" and "Standard" timetable type, and clicks Generate Requirements.

The system creates 23 consolidation records. Mr. Kumar reviews the grid and notices Class 10A Mathematics (Theory) has `required_weekly_periods = 5` but needs 6. He inline-edits the field to 6. He also identifies an elective Music subject shared across all sections — he sets its sharing scope to "Across Sections". For Class 10 Science (Lab), he sets preferred periods [3,4] and avoided periods [7,8].

Later, a duplicate record is identified. Mr. Kumar soft-deletes it via Trash. The record becomes inactive and moves to the trash view.

## Related Screens

- **Class Subject Groups & Subgroups** — upstream source of requirement groups (compulsory) and subgroups (optional/elective) that feed into consolidation generation
- **Slot Requirements** — provides slot capacity context alongside consolidation
- **Activity Generation** — downstream process that reads consolidation records to create teaching activities (one activity per consolidation record)
- **Teacher Availability** — downstream process where teacher availability records reference consolidation records via `requirement_consolidation_id`
- **Priority Configuration** — downstream process where priority scores per consolidation record are computed
- **Timetable Solver** — final consumer of consolidation constraints for period placement

## Requirements

- `RequirementConsolidationController` (1219 lines) handles CRUD + generation + AJAX endpoints for `tt_requirement_consolidations`. Key methods: `generateRequirements()` truncates and regenerates from ClassSubjectGroup and ClassSubjectSubgroup sources; `processClassSubjectGroups()` loads active groups with relations and batch upserts; `processClassSubjectSubgroups()` does the same for subgroups; `ajaxInlineUpdate()` validates field whitelist and updates single fields; `updateRequirement()` handles sharing scope conversion; `updatePeriods()` saves JSON period preferences; `getRequirementsStats()` returns per-class/per-section totals.
- All endpoints use explicit `Gate::authorize()` calls. Permission strings follow `timetable-foundation.requirement-consolidation.*` with an extra `generate` permission for the batch generation endpoint.
- The model (`RequirementConsolidation`) uses `SoftDeletes`. There is no policy class — authorization is handled entirely through `Gate::authorize()` calls.
- Key internal methods: `mapGroupToRequirement()` maps a group to the consolidation array format (sets `is_compulsory=true`, copies scheduling parameters from parent `schClassGroup`); `mapSubgroupToRequirement()` maps a subgroup (inherits `is_compulsory` from parent, preserves sharing flags).
- Routes are under `timetable-foundation` prefix: `requirement-consolidation.*` (lines 252–261), plus the tab entry via `menu.timetablePreparation` in `web.php`.
- Activity logging is implemented on all state-changing operations via `activityLog()` helper.

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.requirement-consolidation.viewAny` | `index()`, `getRequirementsStats()` | List and statistics |
| `timetable-foundation.requirement-consolidation.view` | `show()` | View single record |
| `timetable-foundation.requirement-consolidation.create` | `create()`, `store()` | Single record creation |
| `timetable-foundation.requirement-consolidation.update` | `edit()`, `update()`, `toggleStatus()`, `ajaxInlineUpdate()`, `updateRequirement()`, `updatePeriods()` | Edit, toggle, inline AJAX |
| `timetable-foundation.requirement-consolidation.delete` | `destroy()` | Soft delete |
| `timetable-foundation.requirement-consolidation.restore` | `restore()`, `trashedRequirementConsolidation()` | Restore and view trash |
| `timetable-foundation.requirement-consolidation.forceDelete` | `forceDelete()` | Permanent delete |
| `timetable-foundation.requirement-consolidation.generate` | `generateRequirements()` | Batch generation |
| Policy | No policy class — all Gates use `Gate::authorize()` with permission strings directly | — |

## Logic Flow

**Page Load.** User navigates to `timetable-foundation.menu.timetablePreparation?tab=requirement-consolidation`. The `index()` method gates with `requirement-consolidation.viewAny`, redirects to the menu route. The view renders academic term and timetable type selectors and an empty grid (or the last generated grid if records exist).

**Generate Requirements.** User selects term + type and clicks "Generate". The `generateRequirements()` method validates inputs, disables foreign key checks, truncates the table, re-enables checks, opens a transaction, runs `processClassSubjectGroups()` (loads active groups, maps via `mapGroupToRequirement()`, batch upserts), runs `processClassSubjectSubgroups()` (loads active subgroups, maps via `mapSubgroupToRequirement()`, batch upserts), commits. If zero records are created, a warning flash is shown.

**Inline Edit.** User clicks inline edit on a grid field. JavaScript sends AJAX POST to `ajaxInlineUpdate()` with `field` and `value`. The controller checks the whitelist, casts booleans via `filter_var()`, casts other values to `(int)`, updates the record, logs activity, and returns JSON `{ success: true, message: "{Field name} updated." }`.

**Update Sharing Scope.** User selects a sharing radio option. AJAX POST to `updateRequirement()` with `shared_scope` value. The controller converts to boolean flags, enforces mutual exclusivity, updates the record, and returns JSON success.

**Update Period Preferences.** User selects preferred/avoided periods. AJAX POST to `updatePeriods()` with `type` (preferred/avoid) and `periods` array. The controller saves the JSON array to `preferred_periods_json` or `avoid_periods_json`.

**Delete / Restore.** Standard soft-delete pattern: `destroy()` sets `is_active=false`, calls `delete()`, logs activity. `restore()` calls `restore()`, sets `is_active=true`, logs activity. `forceDelete()` permanently removes the record.

## Validate Before Save

**generateRequirements() Validation**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `academic_term_id` | required, integer, exists:sch_academic_term,id | "Please select an academic term." |
| `timetable_type_id` | required, integer, exists:tt_timetable_types,id | "Please select a timetable type." |

**update() Validation (consolidation path)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `class_id` | nullable, integer | — |
| `section_id` | nullable, integer | — |
| `required_weekly_periods` | nullable, integer, min:0 | — |
| `min_periods_required_per_week` | nullable, integer, min:0 | — |
| `max_periods_required_per_week` | nullable, integer, min:0 | — |
| `min_periods_required_per_day` | nullable, integer, min:0 | — |
| `max_periods_required_per_day` | nullable, integer, min:0 | — |
| `min_gap_between_periods` | nullable, integer, min:0 | — |
| `allow_consecutive_periods` | nullable, boolean | — |
| `max_consecutive_periods` | nullable, integer, min:1 | — |
| `class_priority_score` | nullable, integer, min:0, max:100 | — |
| `shared_scope` | nullable, in:none,section,class | — |
| `spread_evenly` | nullable, boolean | — |
| `compulsory_specific_room_type` | nullable, boolean | — |
| `**Controller check** | `min_periods_required_per_week` <= `max_periods_required_per_week` | "Minimum weekly periods cannot exceed maximum." |
| `**Controller check** | `min_periods_required_per_day` <= `max_periods_required_per_day` | "Minimum daily periods cannot exceed maximum." |

**ajaxInlineUpdate() Field Whitelist**

| Allowed Fields | Cast |
|----------------|------|
| `required_weekly_periods`, `min_periods_required_per_week`, `max_periods_required_per_week` | `(int)` |
| `min_periods_required_per_day`, `max_periods_required_per_day`, `min_gap_between_periods` | `(int)` |
| `allow_consecutive_periods`, `max_consecutive_periods`, `class_priority_score` | bool / `(int)` |
| `spread_evenly`, `is_compulsory`, `is_shared_across_sections`, `is_shared_across_classes` | `filter_var($value, FILTER_VALIDATE_BOOLEAN)` |
| `compulsory_specific_room_type`, `student_count`, `eligible_teacher_count`, `is_active` | bool / `(int)` |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Validation failure (store) | Redirect back with `$errors` bag | 302 Redirect |
| Model not found (show/edit/destroy) | `ModelNotFoundException` → 404 page | 404 |
| Not authorised (any operation) | `AuthorizationException` → 403 | 403 |
| Group XOR subgroup violation | "Select either a class group or a class subgroup (not both)." | Validation error |
| Weekly min > max | "Minimum weekly periods cannot exceed maximum." | Validation error |
| Daily min > max | "Minimum daily periods cannot exceed maximum." | Validation error |
| Duplicate requirement (store) | "A requirement for this target and academic session already exists." | Validation error |
| AJAX inline update — invalid field | `{ success: false, message: "Field not editable." }` | 422 JSON |
| Generation — no active source records | Warning: "No active class groups or subgroups found to generate requirements." | 302 Redirect |
| Generation — database error | Error flash with exception message | 302 Redirect |
| updatePeriods — exception | `{ success: false, message: "Failed to update periods: ..." }` | 500 JSON |
| updateRequirement — dual sharing | `{ success: false, message: "Only one shared scope can be enabled at a time." }` | 422 JSON |

## Success Scenarios

**SC-001 — Full Generation with Groups and Subgroups.** Mr. Kumar has 15 active ClassSubjectGroup records and 8 active ClassSubjectSubgroup records. He selects "2025-26 TERM-1" and "Standard", clicks Generate. The system truncates existing records, processes 15 groups (all marked `is_compulsory=true`) and 8 subgroups (inheriting compulsory flags), creating 23 consolidation records. Success message: "Requirements generated successfully: 15 groups, 8 subgroups (Total: 23)."

**SC-002 — Inline Edit Weekly Periods.** Mr. Kumar inline-edits Class 10A Mathematics `required_weekly_periods` from 5 to 6. AJAX POST to `ajaxInlineUpdate` succeeds. The grid refreshes to show 6. Response: `{ success: true, message: "Required weekly periods updated." }`.

**SC-003 — Update Sharing to Across Sections.** Mr. Kumar sets a Music requirement's sharing scope to "Across Sections". The system sets `is_shared_across_sections=true` and `is_shared_across_classes=false`. Response: `{ success: true, message: "Requirement updated successfully" }`.

**SC-004 — Soft Delete and Restore.** Mr. Kumar trashes a duplicate record. The controller deactivates it (`is_active=false`), soft-deletes it, logs activity. He later restores it from the trash view. The record becomes active again.

## Failure Scenarios

**FC-001 — Generate with No Active Source Records.** Mr. Kumar clicks Generate before creating any groups or subgroups. Both `processClassSubjectGroups()` and `processClassSubjectSubgroups()` return 0. Warning flash: "No active class groups or subgroups found to generate requirements." No records are created.

**FC-002 — Weekly Min > Max.** Mr. Kumar sets `min_periods_required_per_week=5` and `max_periods_required_per_week=3`. The cross-field validation rejects: "Minimum weekly periods cannot exceed maximum."

**FC-003 — Dual Sharing Flags.** Both `is_shared_across_sections` and `is_shared_across_classes` are set to `true` via a concurrent request. The `updateRequirement()` method returns 422 JSON: "Only one shared scope can be enabled at a time."

**FC-004 — Cascade Delete from Source Group.** A source ClassSubjectGroup is deleted in the SchoolSetup module. The ON DELETE CASCADE FK automatically deletes all associated consolidation records. Mr. Kumar loses all manual adjustments on those records.

**FC-005 — Inline Edit with Invalid Field.** An AJAX request to `ajaxInlineUpdate` with `field=created_at`. The field is not in the whitelist. Response: 422 JSON `{ success: false, message: "Field not editable." }`.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `tt_class_requirement_subgroups` | FK parent | Referenced by `class_requirement_subgroup_id` (ON DELETE CASCADE) |
| `sch_class_groups_jnt` | FK parent | Referenced by `class_requirement_group_id` (ON DELETE CASCADE) |
| `sch_academic_term` | FK parent | Referenced by `academic_term_id` (ON DELETE SET NULL) |
| `tt_timetable_types` | FK parent | Referenced by `timetable_type_id` (ON DELETE SET NULL) |
| `sch_classes` | Parent | Referenced by `class_id` |
| `sch_sections` | Parent | Referenced by `section_id` |
| `sch_subjects` | Parent | Referenced by `subject_id` |
| `sch_subject_types` | Parent | Referenced by `subject_type_id` |
| `sch_study_formats` | Parent | Referenced by `study_format_id` |
| `sch_subject_study_format_jnt` | Parent | Referenced by `subject_study_format_id` |
| `sch_rooms` | Parent | Referenced by `class_house_room_id`, `required_room_id` |
| `sch_room_types` | Parent | Referenced by `required_room_type_id` |
| `tt_teacher_availabilities` | Child | References `requirement_consolidation_id` (FK RESTRICT) |
| `tt_priority_configs` | Child | References `requirement_consolidation_id` |
| `tt_activities` | Consumer | Activity generation reads from consolidation records |
| SmartTimetable solver | Consumer | Reads all constraint fields for period placement |
| `activityLog()` helper | Service | Audit logging on every state change |

**Table:** `tt_requirement_consolidations`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `academic_term_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_academic_term(id)` ON DELETE SET NULL |
| `timetable_type_id` | INT UNSIGNED | DEFAULT NULL, FK → `tt_timetable_types(id)` ON DELETE SET NULL |
| `class_requirement_group_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt(id)` ON DELETE CASCADE |
| `class_requirement_subgroup_id` | INT UNSIGNED | DEFAULT NULL, FK → `tt_class_requirement_subgroups(id)` ON DELETE CASCADE |
| `class_id` | INT UNSIGNED | NOT NULL |
| `section_id` | INT UNSIGNED | DEFAULT NULL |
| `subject_id` | INT UNSIGNED | NOT NULL |
| `study_format_id` | INT UNSIGNED | NOT NULL |
| `subject_type_id` | INT UNSIGNED | NOT NULL |
| `subject_study_format_id` | INT UNSIGNED | NOT NULL |
| `class_house_room_id` | INT UNSIGNED | NOT NULL |
| `student_count` | INT UNSIGNED | DEFAULT NULL |
| `eligible_teacher_count` | INT UNSIGNED | DEFAULT NULL |
| `is_compulsory` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `required_weekly_periods` | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 |
| `min_periods_required_per_week` | TINYINT UNSIGNED | DEFAULT NULL |
| `max_periods_required_per_week` | TINYINT UNSIGNED | DEFAULT NULL |
| `min_periods_required_per_day` | TINYINT UNSIGNED | DEFAULT NULL |
| `max_periods_required_per_day` | TINYINT UNSIGNED | DEFAULT NULL |
| `min_gap_between_periods` | TINYINT UNSIGNED | DEFAULT NULL |
| `required_consecutive_periods` | TINYINT UNSIGNED | DEFAULT NULL |
| `min_required_consecutive_periods` | TINYINT UNSIGNED | DEFAULT NULL |
| `allow_consecutive_periods` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `max_consecutive_periods` | TINYINT UNSIGNED | DEFAULT 2 |
| `class_priority_score` | TINYINT UNSIGNED | DEFAULT NULL |
| `preferred_periods_json` | JSON | DEFAULT NULL |
| `avoid_periods_json` | JSON | DEFAULT NULL |
| `spread_evenly` | TINYINT(1) | DEFAULT 1 |
| `is_shared_across_sections` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_shared_across_classes` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `compulsory_specific_room_type` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `required_room_type_id` | INT UNSIGNED | NOT NULL |
| `required_room_id` | INT UNSIGNED | DEFAULT NULL |
| `is_active` | TINYINT(1) UNSIGNED | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |
| `deleted_at` | TIMESTAMP | NULL |
