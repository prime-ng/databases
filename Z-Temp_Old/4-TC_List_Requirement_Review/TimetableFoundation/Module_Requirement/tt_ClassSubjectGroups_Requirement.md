# Class Subject Groups & Subgroups — Business Requirements

## What This Screen Does

The Class Subject Groups & Subgroups feature defines **what** needs to be scheduled for each class and **how much** slot capacity is available. It covers three entities: Class Requirement Groups (subject groupings with room and teacher-count requirements), Requirement Subgroups (splitting a class into parallel scheduling units with sharing flags), and Slot Requirements (weekly slot budgets per class-section-timetable-type). Together they form the core scheduling input layer that drives activity generation and the timetable solver.

## When This Screen Is Used

- During curriculum planning when the administrator defines which subjects each class studies and how they are grouped
- When setting up parallel/elective scheduling — splitting a class into subgroups so that half takes Art while the other half takes Music at the same time
- When configuring cross-section or cross-class sharing for optional subjects like Music, Art, or PE
- When defining the weekly slot budget (total periods, teaching periods, exam periods, free periods) per class-section-timetable-type combination
- Before activity generation, to ensure every subject has its required slot capacity allocated
- Whenever class timetables are regenerated after curriculum changes

## Default Data Load

The screen loads via the **Timetable Preparation** page accessed at `timetable-foundation.menu.timetablePreparation` with tab parameter `?tab=class-subject-requirement` for groups/subgroups and `?tab=slot-requirements` for slot requirements. Default data load includes:

- **Requirement Groups:** Paginated list of `tt_class_requirement_groups` records showing code, name, class, section, subject, study format, subject type, room requirements, student count, and eligible teacher count
- **Requirement Subgroups:** Paginated list of `tt_class_requirement_subgroups` records showing code, name, sharing flags, class, section, subject, and student/teacher counts
- **Slot Requirements:** Paginated list of `tt_slot_requirements` records showing academic term, timetable type, class, section, weekly total/teaching/exam/free slots

## Key Fields at a Glance

**Requirement Groups (`tt_class_requirement_groups`)**

| Column | Description |
|--------|-------------|
| `code` | Group code copied from `sch_class_groups_jnt.code` |
| `name` | Group name copied from `sch_class_groups_jnt.name` |
| `class_group_id` | Reference to the original class group in `sch_class_groups_jnt` |
| `class_id` | Target class for this requirement group |
| `section_id` | Target section (NULL = applies to all sections) |
| `subject_id` | Subject being scheduled |
| `study_format_id` | Study format (e.g., SCI_LEC, SCI_LAB, COM_LEC, COM_OPT) |
| `subject_type_id` | Subject type (MAJOR, MINOR, OPTIONAL, etc.) |
| `subject_study_format_id` | Junction reference for subject + study format |
| `class_house_room_id` | Assigned classroom or house room |
| `required_room_type_id` | Required room type for scheduling |
| `required_room_id` | Specific required room |
| `student_count` | Number of students (from `sch_class_section_jnt.actual_total_student`) |
| `eligible_teacher_count` | Number of eligible teachers |

**Requirement Subgroups (`tt_class_requirement_subgroups`)**

| Column | Description |
|--------|-------------|
| `code` | Subgroup code copied from `sch_class_groups_jnt.code` |
| `name` | Subgroup name copied from `sch_class_groups_jnt.name` |
| `class_group_id` | Parent class group junction (SET NULL on delete) |
| `is_shared_across_sections` | Whether this subgroup is shared across sections (editable) |
| `is_shared_across_classes` | Whether this subgroup is shared across classes (editable) |
| `student_count` | Number of students in this subgroup |
| `eligible_teacher_count` | Number of eligible teachers |

**Slot Requirements (`tt_slot_requirements`)**

| Column | Description |
|--------|-------------|
| `academic_term_id` | Academic term context |
| `timetable_type_id` | Timetable type (Standard, Exam, etc.) |
| `class_timetable_type_id` | Class-timetable-type junction reference |
| `class_id` | Target class |
| `section_id` | Target section |
| `weekly_total_slots` | Total weekly slots (1–8) for this class+section |
| `weekly_teaching_slots` | Weekly teaching slots (1–8) |
| `weekly_exam_slots` | Weekly exam slots (1–8) |
| `weekly_free_slots` | Weekly free slots (1–8) |

## Business Rules and Conditions

**Code Uniqueness.** Each requirement group must have a unique `code` and each subgroup must have a unique `code`, enforced at the database level by `uq_clsReqGroups_code` and `uq_subgroup_code`.

**Composite Uniqueness — Groups.** No duplicate `(class_id, section_id, subject_study_format_id)` combinations are allowed in `tt_class_requirement_groups`, enforced by `uq_clsReqGroups_class_section_subjectType`.

**Composite Uniqueness — Subgroups.** No duplicate `(class_id, section_id, subject_study_format_id)` combinations are allowed in `tt_class_requirement_subgroups`, enforced by `uq_classGroup_subStdFmt_class_section_subjectType`.

**Slot Budget Validation.** `weekly_total_slots` MUST equal the sum of `weekly_teaching_slots + weekly_exam_slots + weekly_free_slots`. This is enforced by the model's `isValid()` method.

**Unique Slot Record.** Only one slot requirement record per `(timetable_type_id, class_timetable_type_id, class_id, section_id)` combination, enforced by `uq_sa_class_section`.

**Shared Scope Mutually Exclusive.** `is_shared_across_sections` and `is_shared_across_classes` are mutually exclusive — only one can be active at a time. The `ajaxToggleSharing()` method enforces this rule.

**Read-Only Data Fields (Subgroups).** All fields in `tt_class_requirement_subgroups` except `is_shared_across_sections` and `is_shared_across_classes` are system-populated from upstream data and cannot be modified via the subgroup edit screen.

**Generation Is Destructive (Slot Requirements).** The `generateSlotRequirement` endpoint deletes all existing slot requirements for the given term+type before regenerating fresh records. Manual edits are lost on regeneration.

**Section-Specific Rows First (Slot Requirements).** Generation processes `applies_to_all_sections = 0` rows first (section-specific), then `applies_to_all_sections = 1` rows (class-level, expanded to all sections), skipping sections already handled.

**Null Section = All Sections.** When `section_id` is NULL in a requirement group or subgroup, the record applies to all sections of the class.

**Downstream Cascade.** `tt_class_requirement_groups` and `tt_class_requirement_subgroups` are referenced by `tt_requirement_consolidations` via CASCADE FK — deleting a group or subgroup cascade-deletes the corresponding consolidation records.

## Workflow Steps

**Define Requirement Groups.** The administrator navigates to Timetable Preparation → class-subject-requirement tab. They create requirement groups by specifying the class, section (optional), subject, study format, subject type, room requirements, student count, and eligible teacher count. The group code and name are inherited from the class group definition in the SchoolSetup module.

**Define Requirement Subgroups.** From the same tab, the administrator creates subgroups within requirement groups. Each subgroup specifies which class, section, subject, and study format it covers. The system populates most fields automatically; the administrator only configures the two sharing flags: `is_shared_across_sections` and `is_shared_across_classes`. The `ajaxToggleSharing()` method ensures mutual exclusivity.

**Generate Slot Requirements.** The administrator navigates to the slot-requirements tab, selects an academic term and timetable type, and clicks "Generate Slot Requirements". The system processes section-specific rows first (creating one record per class+section), then class-level rows (expanding to all sections while skipping those already handled). Each slot requirement record stores the weekly total/teaching/exam/free slot counts.

**Edit Slot Requirements Inline.** After generation, the administrator can edit individual slot records to adjust the weekly slot counts, ensuring the slot budget matches curriculum requirements before activity generation.

## Example Scenario

Ms. Patel, the timetable coordinator at Gurukul Academy, is setting up scheduling for Class 10. She creates a requirement group for "10A-Mathematics-STD_LEC" with `subject_type_id=MAJOR`, `student_count=40`, `eligible_teacher_count=2`, and a required room of "Mathematics Lab".

For optional subjects, she creates a subgroup "10A-Music-B" where half the class takes Music while the other half takes Art. She sets `is_shared_across_classes=false` and `is_shared_across_sections=false` since this is a single-section split.

On the slot requirements tab, she selects "2025-26 TERM-1" and "Standard" timetable type, then clicks "Generate". The system creates slot records: 10A gets 8 total weekly slots (6 teaching + 2 exam + 0 free). Ms. Patel adjusts 10A's teaching slots to 5 to accommodate a remedial workshop period.

## Related Screens

- **SchoolSetup → Class Groups** — upstream source of `code` and `name` for requirement groups and subgroups
- **SchoolSetup → Subjects** — upstream source of subject definitions and subject types
- **Requirement Consolidation** — downstream aggregation layer that reads groups and subgroups to create consolidated requirement records
- **Activity Generation** — downstream process that reads subgroups to create teaching activities
- **Timetable Master → Period Sets** — provides the period set context for slot requirement generation (fallback slot calculation)
- **Timetable Planning → Timetable Cells** — downstream consumer where subgroups are placed on the timetable grid

## Requirements

- `ClassSubjectSubgroupController` (688 lines) handles CRUD + AJAX endpoints for both requirement groups and subgroups in `tt_class_requirement_groups` and `tt_class_requirement_subgroups`. Key methods: `store()` validates and creates subgroups with members in a transaction; `update()` updates only the editable sharing flags; `destroy()` soft-deletes; `getSectionsByClass()` returns JSON with section capacity data; `ajaxToggleSharing()` enforces mutual exclusivity of sharing flags; `generateClassSubgroups()` auto-generates subgroups for non-MAJOR subject types using configurable min/max student thresholds from `tt_configs`.
- `SlotRequirementController` (408 lines) handles CRUD + generation for `tt_slot_requirements`. Key methods: `store()` creates/updates via `updateOrCreate` (idempotent); `generateSlotRequirement()` batch-generates records by deleting existing ones and re-creating from class-timetable-type assignments; `toggleStatus()` AJAX toggles active/inactive.
- Both controllers use explicit `Gate::authorize()` calls. Permission strings follow `timetable-foundation.class-subgroup.*` and `timetable-foundation.slot-requirement.*`.
- All three models (`ClassRequirementGroup`, `ClassRequirementSubgroup`, `SlotRequirement`) use `SoftDeletes`. The `SlotRequirement` model has an `isValid()` method that validates `weekly_total_slots === weekly_teaching_slots + weekly_exam_slots + weekly_free_slots`.
- Routes are under `timetable-foundation` prefix: `class-subgroup.*` (lines 243–249), `slot-requirement.*` (lines 265–267), plus `class-subject-requirement` tab via `menu.timetablePreparation` (lines 55–57) in `web.php`.
- Activity logging is implemented on all write operations via `activityLog()` helper.

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `timetable-foundation.class-subgroup.viewAny` | `index()`, `listSubgroups()`, `getSectionsByClass()`, `getSectionsWithClassGroups()`, `getSubgroupStats()` | List and AJAX data endpoints |
| `timetable-foundation.class-subgroup.view` | `show()` | View single record |
| `timetable-foundation.class-subgroup.create` | `create()`, `store()`, `generateClassSubgroups()` | Create and batch generation |
| `timetable-foundation.class-subgroup.update` | `edit()`, `update()`, `ajaxToggleSharing()`, `toggleStatus()` | Edit, update, AJAX toggle |
| `timetable-foundation.class-subgroup.delete` | `destroy()`, `forceDelete()` | Soft and hard delete |
| `timetable-foundation.slot-requirement.viewAny` | `index()` | List |
| `timetable-foundation.slot-requirement.view` | `show()` | View single |
| `timetable-foundation.slot-requirement.create` | `create()`, `store()`, `generateSlotRequirement()` | Create and batch generation |
| `timetable-foundation.slot-requirement.update` | `edit()`, `update()`, `toggleStatus()` | Edit and toggle |
| `timetable-foundation.slot-requirement.delete` | `destroy()` | Delete |
| Policy | `ClassSubgroupPolicy`, `SlotRequirementPolicy` | Registered in `TimetableFoundationServiceProvider` |

## Logic Flow

**Page Load.** User navigates to `timetable-foundation.menu.timetablePreparation?tab=class-subject-requirement`. The `TimetableFoundationController@timetablePreparation()` renders the shared layout. The `ClassSubjectSubgroupController@index()` gates with `class-subgroup.viewAny`, then redirects to the menu route. The view renders the active tab with two sub-sections: requirement groups grid and subgroups grid. The slot-requirements tab is rendered separately via `SlotRequirementController@index()`.

**Create Requirement Subgroup.** User clicks "Add New" on the subgroups section. The `create()` method gates with `.create`, loads class groups, classes, and min/max student config. User fills the form, selects sharing mode (none/sections/classes), and submits. The `store()` method validates (including shift consistency if applicable), creates the subgroup and member records in a transaction, logs activity, and redirects.

**AJAX Toggle Sharing.** User clicks the sharing toggle on a subgroup row. The `ajaxToggleSharing()` method accepts a `mode` parameter (`none|sections|classes`). It sets the corresponding flag to `true` and the other to `false`. The response is a JSON success confirmation.

**Generate Slot Requirements.** User selects academic term and timetable type, then clicks "Generate". The `generateSlotRequirement()` method deletes all existing records for that term+type, processes section-specific rows (STEP 1), then class-level rows expanded to all sections (STEP 2), skipping duplicates. It creates records with slot counts derived from explicit values or fallback calculations.

**Edit / Delete.** Standard resource controller pattern: `edit()` renders the form, `update()` validates and persists changes, `destroy()` soft-deletes, `restore()` restores, `forceDelete()` permanently removes.

## Validate Before Save

**Slot Requirement (store/update)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `timetable_type_id` | required, exists:tt_timetable_types,id | — |
| `class_timetable_type_id` | required, exists:tt_class_timetable_types_jnt,id | — |
| `class_id` | required, exists:sch_classes,id | — |
| `section_id` | required, exists:sch_sections,id | — |
| `weekly_total_slots` | required, integer, min:0, max:8 | — |
| `weekly_teaching_slots` | required, integer, min:0, max:8 | — |
| `weekly_exam_slots` | required, integer, min:0, max:8 | — |
| `weekly_free_slots` | required, integer, min:0, max:8 | — |
| `**Model (SlotRequirement::isValid())** | weekly_total_slots == teaching + exam + free | "Slot totals must equal the sum of teaching, exam, and free slots." |

**Subgroup (store/update)**

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `members` | array (each member: class_id, section_id, student_count) | — |
| `is_shared_across_sections` | boolean (radio toggle) | — |
| `is_shared_across_classes` | boolean (radio toggle) | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Slot requirement sum mismatch | "Slot totals must equal the sum of teaching, exam, and free slots." | Model validation |
| Duplicate slot requirement on generation | Handled by `updateOrCreate` (idempotent) | — |
| Dual sharing flags attempt | "Only one shared scope can be enabled at a time." | 422 JSON |
| Model not found (any operation) | `ModelNotFoundException` → 404 | 404 |
| Not authorised (any operation) | `AuthorizationException` → 403 | 403 |
| Generation with no active source records | Warning: "No slot requirements generated." | 302 Redirect |

## Success Scenarios

**SC-001 — Create Subgroup with Section Sharing.** Ms. Patel creates a Music subgroup for Class 10, Section A, with `is_shared_across_sections=false`. The system creates the `tt_class_requirement_subgroups` record with `student_count=20` and `eligible_teacher_count=1`. The subgroup appears in the grid with the sharing flag set to "None".

**SC-002 — Toggle Sharing to Across Sections.** Ms. Patel toggles the sharing mode on the Music subgroup from "None" to "Across Sections". The `ajaxToggleSharing()` method sets `is_shared_across_sections=true` and `is_shared_across_classes=false`. The grid badge updates to show "Shared (Sections)".

**SC-003 — Generate Slot Requirements.** Ms. Patel selects "2025-26 TERM-1" and "Standard" timetable type, then clicks "Generate". The system deletes all existing slot requirements for that term+type, processes 10 section-specific rows and 3 class-level rows (expanded to 6 sections), creating 16 unique slot requirement records. The success message confirms the generation count.

**SC-004 — Edit Slot Requirement.** Ms. Patel adjusts Class 10A's `weekly_teaching_slots` from 6 to 5 to accommodate a remedial workshop. The `update()` method validates the slot sum (5 teaching + 2 exam + 0 free = 7 total, matching `weekly_total_slots=7`), updates the record, and logs the activity.

## Failure Scenarios

**FC-001 — Slot Sum Mismatch.** Ms. Patel sets `weekly_total_slots=8`, `weekly_teaching_slots=6`, `weekly_exam_slots=0`, `weekly_free_slots=0` (sum=6, not 8). The model's `isValid()` method fails validation, returning an error: "Slot totals must equal the sum of teaching, exam, and free slots."

**FC-002 — Dual Sharing Flags.** A concurrent AJAX request sets both `is_shared_across_sections=true` and `is_shared_across_classes=true` on the same subgroup. The `ajaxToggleSharing()` method detects the conflict and returns a 422 JSON response: "Only one shared scope can be enabled at a time."

**FC-003 — Delete Class With Active Groups.** A class that has active requirement groups is deleted from the SchoolSetup module. The ON DELETE RESTRICT FK on `class_id` in `tt_class_requirement_groups` prevents the deletion, returning a foreign key constraint error at the database level.

**FC-004 — Cascade Delete from Subgroup.** A subgroup referenced by requirement consolidation records is deleted. The ON DELETE CASCADE FK on `class_requirement_subgroup_id` in `tt_requirement_consolidations` automatically deletes the corresponding consolidation records. The administrator's manual adjustments on those records are lost.

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `sch_classes` | FK parent | Referenced by all three tables via `class_id` (ON DELETE RESTRICT) |
| `sch_sections` | FK parent | Referenced by all three tables via `section_id` (ON DELETE RESTRICT) |
| `sch_subject_types` | FK parent | Referenced by groups and subgroups via `subject_type_id` (ON DELETE RESTRICT) |
| `sch_subject_study_format_jnt` | FK parent | Referenced by groups and subgroups via `subject_study_format_id` (ON DELETE RESTRICT) |
| `sch_rooms` | FK parent | Referenced by groups via `class_house_room_id`, `required_room_id` (ON DELETE RESTRICT) |
| `sch_rooms_type` | FK parent | Referenced by groups via `required_room_type_id` (ON DELETE RESTRICT) |
| `sch_class_groups_jnt` | FK parent | Referenced by subgroups via `class_group_id` (ON DELETE SET NULL) |
| `tt_timetable_types` | FK parent | Referenced by `tt_slot_requirements` via `timetable_type_id` |
| `tt_class_timetable_types_jnt` | FK parent | Referenced by `tt_slot_requirements` via `class_timetable_type_id` |
| `tt_activities` | FK parent | Referenced by `tt_slot_requirements` via `activity_id` (nullable) |
| `tt_requirement_consolidations` | Child | References `class_requirement_group_id` and `class_requirement_subgroup_id` (ON DELETE CASCADE) |
| `tt_activities` | Child | References `class_subgroup_id` (ON DELETE SET NULL) |
| `tt_timetable_cells` | Child | References `class_subgroup_id` (ON DELETE CASCADE) |

**Table:** `tt_class_requirement_groups`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `code` | CHAR(50) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL |
| `class_group_id` | INT UNSIGNED | NOT NULL, FK → `sch_class_groups(id)` |
| `class_id` | INT UNSIGNED | NOT NULL, FK → `sch_classes(id)` ON DELETE RESTRICT |
| `section_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_sections(id)` ON DELETE RESTRICT |
| `subject_id` | INT UNSIGNED | DEFAULT NULL |
| `study_format_id` | INT UNSIGNED | DEFAULT NULL |
| `subject_type_id` | INT UNSIGNED | NOT NULL, FK → `sch_subject_types(id)` ON DELETE RESTRICT |
| `subject_study_format_id` | INT UNSIGNED | NOT NULL, FK → `sch_subject_study_format_jnt(id)` ON DELETE RESTRICT |
| `class_house_room_id` | INT UNSIGNED | NOT NULL, FK → `sch_rooms(id)` |
| `required_room_type_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms_type(id)` ON DELETE RESTRICT |
| `required_room_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_rooms(id)` ON DELETE RESTRICT |
| `student_count` | INT UNSIGNED | DEFAULT NULL |
| `eligible_teacher_count` | INT UNSIGNED | DEFAULT NULL |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `deleted_at` | TIMESTAMP | NULL |
| `created_at` | TIMESTAMP | NULL |
| `updated_at` | TIMESTAMP | NULL |

**Table:** `tt_class_requirement_subgroups`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100) | NOT NULL |
| `class_group_id` | INT UNSIGNED | DEFAULT NULL, FK → `sch_class_groups_jnt(id)` ON DELETE SET NULL |
| `class_id` | INT UNSIGNED | NOT NULL |
| `section_id` | INT UNSIGNED | DEFAULT NULL |
| `subject_id` | INT UNSIGNED | DEFAULT NULL |
| `study_format_id` | INT UNSIGNED | DEFAULT NULL |
| `subject_type_id` | INT UNSIGNED | NOT NULL |
| `subject_study_format_id` | INT UNSIGNED | NOT NULL |
| `class_house_room_id` | INT UNSIGNED | NOT NULL |
| `student_count` | INT UNSIGNED | DEFAULT NULL |
| `eligible_teacher_count` | INT UNSIGNED | DEFAULT NULL |
| `is_shared_across_sections` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_shared_across_classes` | TINYINT(1) | NOT NULL, DEFAULT 0 |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| `deleted_at` | TIMESTAMP | NULL |

**Table:** `tt_slot_requirements`

| Column | Type | Details |
|--------|------|---------|
| `id` | INT UNSIGNED | PK, Auto Increment |
| `academic_term_id` | INT UNSIGNED | NOT NULL, FK → `sch_academic_term(id)` |
| `timetable_type_id` | INT UNSIGNED | NOT NULL, FK → `tt_timetable_types(id)` |
| `class_timetable_type_id` | INT UNSIGNED | NOT NULL, FK → `tt_class_timetable_types_jnt(id)` |
| `class_id` | INT UNSIGNED | NOT NULL, FK → `sch_classes(id)` |
| `section_id` | INT UNSIGNED | NOT NULL, FK → `sch_sections(id)` |
| `class_house_room_id` | INT UNSIGNED | NOT NULL |
| `weekly_total_slots` | TINYINT UNSIGNED | NOT NULL, 1–8 |
| `weekly_teaching_slots` | TINYINT UNSIGNED | NOT NULL, 1–8 |
| `weekly_exam_slots` | TINYINT UNSIGNED | NOT NULL, 1–8 |
| `weekly_free_slots` | TINYINT UNSIGNED | NOT NULL, 1–8 |
| `activity_id` | INT UNSIGNED | NULL, FK → `tt_activities(id)` |
| `is_active` | TINYINT(1) | NOT NULL, DEFAULT 1 |
