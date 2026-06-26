# TimetableFoundation — Requirements Consolidation

## What It Does
Aggregates all scheduling requirements (slot requirements, class-subject groups, teacher assignments) into a consolidated view. Enables administrators to review total weekly period load per class-section, identify imbalances, adjust slot allocations, and ensure every subject gets its required periods before timetable generation begins.

## Tenant Admin Context
Curriculum planners define how many periods per week each subject gets per class-section. The consolidation engine aggregates these requirements, highlights over/under-allocation, and provides inline editing for fine-tuning.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_requirement_consolidations` | `id`, `class_id`, `section_id`, `subject_id`, `study_format_id`, `required_periods`, `allocated_periods`, `gap`, `academic_term_id` |
| `tt_class_subject_groups` | `id`, `class_id`, `subject_id`, `group_name`, `total_periods`, `is_active` |
| `tt_class_subject_subgroups` | `id`, `class_subject_group_id`, `section_id`, `periods`, `is_active` |

## Business Rules
1. **Consolidation generation**: Reads `ClassSubjectGroup` + `SlotRequirement` + curriculum data to compute total required periods per class-section-subject.
2. **Gap detection**: Compares `required_periods` (curriculum) vs `allocated_periods` (current activities). Gap = required − allocated. Positive gap = under-allocation.
3. **Inline editing**: Administrators can edit required periods directly in the consolidation grid.
4. **Statistics**: Per-class and per-section totals showing overall load balance.
5. **Regeneration**: Consolidation can be regenerated after curriculum changes.
6. **Feeds activity generation**: The consolidation data drives batch activity creation — one activity per class-section-subject-format combination.

## Process Flow: Requirements Consolidation Lifecycle
### Generation
1. Admin navigates to Requirement Consolidation → selects academic term.
2. Clicks "Generate Consolidation" — system reads all class-subject-group and slot-requirement records.
3. System computes required vs allocated periods per class-section-subject.
4. Displays consolidated grid with colour-coded gap indicators.

### Review & Adjust
1. Admin reviews the grid — identifies subjects with positive gaps (under-allocated) or negative gaps (over-allocated).
2. Admin can adjust required periods inline.
3. Admin can generate missing activities directly from the consolidation grid to fill gaps.

### Activity Generation
1. From consolidation, admin clicks "Generate Activities" for gap subjects.
2. System creates activity records with `weekly_periods = gap` value.
3. Activities are created in DRAFT status for teacher assignment.

## CRUD Operations
- **Create**: Generate consolidation records
- **Read**: Consolidated grid with gap analysis
- **Update**: Inline edit required periods
- **Delete**: Regenerate to replace existing consolidation

## Permissions
- **Admin**: Full access to consolidation operations
