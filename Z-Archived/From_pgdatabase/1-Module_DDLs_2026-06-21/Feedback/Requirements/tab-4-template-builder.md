# Feedback Tab 4: Template Builder

This screen allows administrators to create and manage reusable question sets called templates. Each template is tied to a specific target type and a respondent kind, and contains a set of questions grouped by categories. Templates can be reused across multiple relationships that share the same target type.

---

## How It Works

The screen shows a list of existing templates with their name, target type, respondent kind, version, and whether they are locked. Administrators can create new templates or clone existing ones. When creating a template, the administrator selects the target type it applies to, the respondent kind that will use it, and the scoring method for calculating overall ratings.

Each template has a version number. When a template is used by an active cycle, it becomes locked to prevent edits that would change the feedback experience mid-cycle. To modify a locked template, the administrator must clone it, creating a new version with a bumped version number. The old version continues to serve the active cycle while the new version can be used for future cycles.

The template builder also allows the administrator to select which relationship types this template supports via the applicable relationships setting. This lets a single template (like "Teacher Evaluation") work for both STUDENT_TO_CLASS_TEACHER and STUDENT_TO_SUBJECT_TEACHER if they share the same questions.

---

## Important Business Rules

- A template becomes locked (is_locked = 1) as soon as any cycle using it moves to Active status. No edits to the template or its questions are allowed while locked.
- Cloning a template copies all its questions and categories. The clone gets an incremented version number and is unlocked by default.
- The overall rating method determines how the overall score is computed: Weighted Average (questions weighted by their weight field), Simple Average (all questions equally weighted), Manual Only (administrator sets score manually), or None (qualitative feedback only).
- Rating scale max defines the maximum value for Rating-type questions within this template (default 5, can be 10).
- The applicable relationship codes JSON is optional. When null, the template works with any relationship type that matches the target type. When populated, only the listed relationship codes can use this template.
- A template with no questions cannot be assigned to a cycle. The system validates this before allowing cycle activation.
- Templates are soft-deleted. Deleting a template that is in use by a cycle is blocked until the cycle is completed or cancelled.

---

## Database Columns & Behavior

### fbk_templates
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `code` — Unique template code. VARCHAR(60). Unique with soft-delete.
- `name` — Template name. VARCHAR(200).
- `description` — Optional notes about template purpose. VARCHAR(500).
- `target_type_id` — FK to fbk_target_types.id. Which target kind this template evaluates. SMALLINT UNSIGNED.
- `respondent_kind_id` — FK to sys_dropdown_table.id (key: fbk_templates.respondent_kind). Restricts who can use this template. INT UNSIGNED.
- `applicable_relationship_codes_json` — JSON array of relationship codes this template supports. JSON, nullable.
- `overall_rating_method_id` — FK to sys_dropdown_table.id (key: fbk_templates.overall_rating_method). INT UNSIGNED.
- `rating_scale_max` — Maximum value for rating scales. TINYINT UNSIGNED, default 5.
- `version` — Version string like 1.0, 1.1, 2.0. VARCHAR(10), default '1.0'.
- `is_active` — Soft delete flag. TINYINT(1), default 1.
- `is_locked` — 1 = used by an active cycle, cannot edit. TINYINT(1), default 0.
- `created_by` — FK to sys_users.id. INT UNSIGNED, nullable.

---

## Deep Analysis

### Business Workflows & State Machines

Template has a simple lock/unlock state machine:

- **Unlocked** (is_locked=0): Editable. Questions can be added/modified/deleted/reordered. All metadata editable.
- **Locked** (is_locked=1): Read-only. All question-level and metadata edits blocked. The only action is Clone.

State transitions:
- **Unlocked → Locked**: Triggered when a cycle referencing this template transitions from Draft → Active. This is an automated side-effect, not a user action on this tab.
- **Locked → Unlocked**: Never. A locked template cannot be unlocked. The only way to modify is to Clone.

Clone workflow: User clicks Clone → system creates a new row copying all metadata + questions + categories → bumps version (e.g., 1.0 → 2.0) → sets is_locked=0 → user can now edit the clone. The original remains locked for the active cycle.

### Validation Rules & Edge Cases

- **Lock enforcement**: When is_locked=1, ALL question-related APIs (create, update, delete, reorder question) must return 403. Template metadata edits (name, description, applicable_relationship_codes_json) should also be blocked.
- **Lock trigger timing**: The lock occurs at the moment a cycle's status transitions to Active. This could happen via scheduler (start_date reached) or manual activation. The application must handle this atomically — either all templates referenced by the cycle get locked, or none do.
- **applicable_relationship_codes_json validation**: If populated, each code must reference an existing fbk_relationship_types.code where target_type_id matches this template's target_type_id. Invalid or mismatched codes should be rejected at save time.
- **Template with zero questions**: Must not appear in the dropdown when selecting a template for a cycle feedback type.
- **rating_scale_max consistency**: If rating_scale_max=10, any question with question_type_id = Rating_10 must have max_scale ≤ 10. If rating_scale_max=5, Rating_10 questions should be disallowed. The system should validate.
- **Version string parsing**: The version field is VARCHAR(10). For auto-increment on clone, the system should parse as semantic versioning (major.minor) and bump the major version. Custom version strings that don't follow the pattern should be preserved as-is on clone.
- **Delete blocked**: If any fbk_cycle_feedback_types row references this template and the cycle is not in Cancelled or Published status, delete is blocked.
- **Cross-tenant uniqueness**: The unique constraint on code is per-tenant (tenant DB), so no cross-tenant collision concerns.

### Integration Points

- **fbk_target_types** via target_type_id — determines which target kind this template evaluates.
- **sys_dropdown_table** via respondent_kind_id (key: fbk_templates.respondent_kind) and overall_rating_method_id (key: fbk_templates.overall_rating_method).
- **fbk_cycle_feedback_types** via template_id — links templates to cycles.
- **fbk_questions** via template_id — cascade delete when template is hard-deleted (though soft-delete is preferred).
- **fbk_categories** via fbk_questions.category_id — questions reference categories.
- **sys_users** via created_by — tracks who created the template.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View list | Yes | Yes | Yes (read-only) | No | No | No |
| Create new | Yes | No | No | No | No | No |
| Edit (unlocked) | Yes | No | No | No | No | No |
| Edit (locked) | No | No | No | No | No | No |
| Clone | Yes | No | No | No | No | No |
| Deactivate | Yes | No | No | No | No | No |
| Delete (unused) | Yes | No | No | No | No | No |
