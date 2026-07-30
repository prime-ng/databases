# Grade Divisions Master — Business Requirements

## What This Screen Does

The Grade Divisions Master screen is the definitive source of truth for generating official student Report Cards and Transcripts. 

While the Performance Categories screen drives internal remedial actions and dashboard alerts, the Grade Divisions screen strictly dictates how numerical percentages are translated into the official nomenclature required by the educational board. It converts a raw score into an official board-compliant label, such as "Grade A1" for CBSE, or "First Division" for a State Board.

---

## When This Screen Is Used

- Pre-Exam Configuration during the setup of the Examination Module before any term report cards are finalized and printed
- Multi-Board Operations when a school runs multiple curricula within the same campus and needs different grading scales for different groups of students
- Policy Changes when an educational board officially changes its grading criteria for a new academic year

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Identity and Nomenclature**
An Official Code captures the exact text printed on the report card, such as A1, DISTINCTION, or FAIL. A Display Name provides the expanded display name for reference, like 'Grade A1' or 'First Division with Honors'. A Grading Type classifies whether this specific rule is a Grade based system or a Division based system.

**Academic Band**
A Percentage Range captures the precise minimum and maximum percentage boundaries, such as 91.00% to 100.00%.

**Compliance and Dynamic Scoping**
A Board Selection links the grading rule to a specific educational board. An Academic Session links the rule to a specific year, allowing historical preservation so that if grading rules change in the future, past report cards remain unaffected. A Scope Rule determines how widely the rule applies, whether to the entire School, all students under a specific Board, or just students in a specific Class. A Target Class links the rule to that specific grade level if the scope is set to Class-level.

**Data Governance**
A Security Lock Toggle is a critical security feature. If enabled, the system absolutely forbids anyone from altering the minimum or maximum percentage boundaries.

---

## Business Rules and Conditions

**Overlap Prevention**
The system must ensure that percentage ranges do not overlap. Before saving, the system checks if the new range conflicts with any existing active rules that share the same scope, grading type, and class. 

**Resolution Hierarchy**
When the system evaluates a student's score to print their report card, it must search for the correct grade using a strict fallback hierarchy. First, it checks if a Class-specific rule exists for the student's exact class. If not found, it checks if a Board-specific rule exists for the student's registered board. If not found, it falls back to the global School-wide rule.

**Post-Publishing Lockdown**
Once the Examination Module executes the Publish Results action for an academic term, it must automatically trigger an update to this screen, locking all relevant rows. This prevents any user from maliciously or accidentally altering the percentage bands to artificially change a student's printed grade retroactively.

---

## Workflow Steps

**Adding a New Grading Rule**
The Exam Controller opens the Grade Divisions Master and selects Add New Rule. They select the Grading Type as Division, enter the Name as "First Division", and set the Code to "1ST_DIV". They define the range minimum as 60.00% and maximum as 74.99%. They set the Scope to Class and select Class 11 and Class 12. They save the record, and the system validates that no overlap exists for 11th and 12th grade Division rules before saving it.

---

## Example Scenario

A school caters to students from Nursery to Class 12 under the CBSE board. The board mandates a 3-point descriptive grading system for early childhood, an 8-point alphabetical Grade system for Classes 4 to 10, and a traditional Marks or Division system for Classes 11 and 12.

The Admin uses the Grade Divisions Master to set this up effortlessly. They create three distinct sets of rules, setting the scope to Class and mapping them to the respective classes. At the end of the year, the Exam Engine processes all 2,000 students. Thanks to the scoping rules, a 3rd grader with 85% gets "Proficient" printed on their card, a 9th grader with 85% gets "A2", and an 11th grader with 85% gets "Distinction"—all automatically handled by this single master configuration without manual intervention.

---

## Related Screens

- **Performance Categories** — The AI-driven, automated counterpart to this screen
- **Exam Module** — The primary consumer of this grading data for report card generation

---

## Requirements

- Controller `GradeDivisionController`; `index()` is loaded via Syllabus tab; `Gate::authorize('tenant.grade-division.viewAny')` is enforced
- Route: `syllabus.master.index` with tab parameter `grade_divisions`
- `store()` gates `tenant.grade-division.create`, calls `GradeDivisionMaster::create($request->validated())`, logs activity
- `update()` gates `tenant.grade-division.update`, checks `$gradeDivision->is_locked` (blocks with error if locked), validates overlap, then updates
- `destroy()` gates `tenant.grade-division.delete`, checks `is_locked` (blocks if locked), sets `is_active = false`, calls `save()` then `delete()`
- `toggleLock($id)` gates `tenant.grade-division.update`, toggles `is_locked` boolean on model
- `toggleStatus($id)` gates `tenant.grade-division.update`, checks `is_locked` (blocks if locked), toggles `is_active`
- `restore()` and `forceDelete()` for trashed records with `activityLog()`
- `prepareForValidation()` uppercases `code` via `strtoupper(trim())`, uppercases `board_code`, casts `is_locked` and `is_active` via `$this->boolean()`
- `withValidator()` performs overlap detection: same `grading_type`, `scope`, `class_id`, checks `min_percentage <= max_percentage AND max_percentage >= min_percentage`
- Soft deletes enabled on model; pagination: 10 per page
- Activity logged: Stored, Updated, Trashed, Restored, Deleted, Toggled, Lock Toggled
- Policies: `GradeDivisionMasterPolicy` (`tenant.grade-division-master.*`) and `GradeDivisionPolicy` (`tenant.grade-division.*`)

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.grade-division.viewAny` | `index()` | Page load |
| `tenant.grade-division.view` | `show()` | View single |
| `tenant.grade-division.create` | `create()`, `store()` | Create |
| `tenant.grade-division.update` | `edit()`, `update()`, `toggleLock()`, `toggleStatus()` | Edit / lock / status |
| `tenant.grade-division.delete` | `destroy()` | Soft delete |
| `tenant.grade-division.restore` | `restore()`, `trashed()` | Restore from trash |
| `tenant.grade-division.forceDelete` | `forceDelete()` | Permanent delete |
| Policies: `GradeDivisionMasterPolicy` + `GradeDivisionPolicy` | Both registered | Dual permission support |

## Logic Flow

1. **Page Load** — Screen loads via Master tab; Gates `tenant.grade-division.viewAny`, fetches all records ordered by `display_order` then `created_at` desc with `paginate(10)`.
2. **Create** — `create()` gates, loads `SchoolClass` and `OrganizationAcademicSession`. POST to `store()` gates, calls `GradeDivisionMaster::create($request->validated())`, logs "Stored". Redirects to `syllabus.master.index` with tab `grade_divisions`.
3. **Edit** — `edit()` gates, loads record + classes + sessions. POST to `update()` gates, checks `is_locked` (redirect back with error if locked), validates overlap manually, detects changes via `array_diff_assoc`, logs "Updated". Redirects.
4. **Lock/Unlock** — `toggleLock($id)` AJAX call. Toggles `is_locked`, saves, logs "Lock Toggled". Returns JSON `{success, is_locked}`.
5. **Status Toggle** — `toggleStatus($id)` checks `is_locked` (blocks if locked), toggles `is_active`, logs "Toggled". Returns JSON.
6. **Delete** — `destroy()` gates, checks `is_locked` (blocks). Sets `is_active = false`, `save()`, then `delete()` for soft delete. Logs "Trashed". Redirects.
7. **Restore** — `restore()` finds `onlyTrashed()`, calls `$item->restore()`, logs "Restored".
8. **Force Delete** — `forceDelete()` finds `withTrashed()`, calls `$item->forceDelete()`, logs "Deleted".

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | `required, string, max:20, unique` — scoped to `(grading_type, scope, class_id)` | "This grade/division code already exists for selected class and scope." |
| `name` | `required, string, max:100` | — |
| `description` | `nullable, string, max:255` | — |
| `grading_type` | `required, in:GRADE,DIVISION` | "Grading type is required." |
| `min_percentage` | `required, numeric, min:0, max:100` | "Minimum percentage is required." / "Minimum percentage must be a valid number." |
| `max_percentage` | `required, numeric, min:0, max:100, gt:min_percentage, unique` — unique scoped to `(scope, class_id, min_percentage)` | "Maximum percentage must be greater than minimum percentage." / "This percentage range already exists for the selected class and scope." |
| `board_code` | `nullable, string, max:50` | — |
| `academic_session_id` | `nullable, integer, exists:sch_org_academic_sessions_jnt,id` | — |
| `scope` | `required, in:SCHOOL,BOARD,CLASS` | "Scope is required." |
| `class_id` | `nullable, integer` | "Selected class is invalid." |
| `display_order` | `nullable, integer, min:1` | — |
| `color_code` | `nullable, string, max:10, regex:/^#?[0-9A-Fa-f]{6}$/` | "Color code must be a valid hex value (e.g. #FF5733)." |
| `is_locked` | `nullable, boolean` | — |
| `is_active` | `nullable, boolean` | — |
| **Overlap (custom)** | `withValidator()`: same `grading_type`, `scope`, `class_id`; range intersects | "The percentage range overlaps with an existing active grade/division." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Overlapping range | "The percentage range overlaps with an existing active grade/division." | Custom validation via `withValidator()` |
| Invalid range | "Maximum percentage must be greater than minimum percentage." | Validation (`gt:min_percentage`) |
| Code duplicate | "This grade/division code already exists for selected class and scope." | Validation (`code.unique`) |
| Range duplicate | "This percentage range already exists for the selected class and scope." | Validation (`max_percentage.unique`) |
| Edit locked rule | "Cannot update locked grade/division." | Controller check |
| Delete locked rule | "Cannot delete locked grade/division." | Controller check |
| Invalid hex | "Color code must be a valid hex value (e.g. #FF5733)." | Validation (`regex`) |

## Success Scenarios

**SC-001 — Creating a Class-Level Grade Rule**
Exam Controller creates grade rule: `grading_type=GRADE`, scope=CLASS, class_id=10, range 91.00–100.00, code="A1". `store()` validates overlap via `withValidator()`, creates record, logs "Stored", redirects with success flash.

**SC-002 — Toggling Lock Status**
User clicks lock toggle on unlocked record. `toggleLock()` AJAX updates `is_locked` from 0 to 1, logs "Lock Toggled", returns JSON `{success: true, is_locked: true}`.

**SC-003 — Restoring a Trashed Rule**
Admin goes to trash view, clicks restore. `restore()` calls `onlyTrashed()->findOrFail()`, `$item->restore()`, logs "Restored", redirects with success.

## Failure Scenarios

**FC-001 — Overlap Conflict**
User adds grade rule for Class 10 with range 85–95% when 90–100% already exists. `withValidator()` detects overlap via `min <= max AND max >= min` query, adds error on `min_percentage`.

**FC-002 — Editing Locked Rule**
User tries to update locked record. `update()` checks `$gradeDivision->is_locked`, redirects back with "Cannot update locked grade/division."

**FC-003 — Deleting Locked Rule**
User tries to delete locked record. `destroy()` checks `is_locked`, redirects back with "Cannot delete locked grade/division."

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `sch_org_academic_sessions_jnt` | FK Table | `academic_session_id` → `id` |
| `sch_classes` | FK Table | `class_id` → `id` (nullable) |
| Activity Log | Consumer | `activityLog()` on all CRUD + lock operations |

**Table:** `slb_grade_division_master`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT PK | Auto-increment |
| code | VARCHAR(20) | Official report card text (e.g., A1, DISTINCTION) |
| name | VARCHAR(100) | Display name |
| description | VARCHAR(255) | — |
| grading_type | ENUM('GRADE','DIVISION') | — |
| min_percentage | DECIMAL(5,2) | Minimum boundary |
| max_percentage | DECIMAL(5,2) | Maximum boundary |
| board_code | VARCHAR(50) | Board reference |
| academic_session_id | BIGINT FK NULL | → `sch_org_academic_sessions_jnt.id` |
| display_order | INT | UI ordering |
| color_code | VARCHAR(10) | Hex color for display |
| scope | ENUM('SCHOOL','BOARD','CLASS') | Resolution scope |
| class_id | BIGINT FK NULL | → `sch_classes.id` (when scope=CLASS) |
| is_locked | TINYINT(1) | Prevents boundary modification |
| is_active | TINYINT(1) | Soft-delete flag |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP | Soft deletes | |
