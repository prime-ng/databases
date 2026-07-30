# tmp_Template_Assignment_TcList

## Module: Template → Template Assignment CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Template (TMP) |
| Tab Group | Template Assignment |
| Features | Template Assignment List with Filters, Create (School-wide / Class / Group), Edit (Change Scope), View Detail, Soft-Delete, Restore, Force-Delete, Toggle Status |
| URL(s) | `/assignments`, `/assignments/create`, `/assignments`, `/assignments/{template_assignment}`, `/assignments/{template_assignment}/edit`, `/assignments/{template_assignment}`, `/assignments/{template_assignment}`, `/assignments/{template_assignment}/toggle-status`, `/assignments/trashed`, `/assignments/{id}/restore`, `/assignments/{id}/force-delete` |
| Controller | `TemplateAssignmentController` |
| Model(s) | `TemplateAssignment`, `Template`, `TemplatePurpose`, `OrganizationAcademicSession`, `SchoolClass`, `SchClassGroupsJnt` |
| Validation | `StoreTemplateAssignmentRequest` (4 required + 2 nullable fields) / `UpdateTemplateAssignmentRequest` (same + ignores current ID in duplicate check) |
| Permission Gates | `tenant.template.assignment.viewAny`, `tenant.template.assignment.view`, `tenant.template.assignment.create`, `tenant.template.assignment.update`, `tenant.template.assignment.delete`, `tenant.template.assignment.restore`, `tenant.template.assignment.forceDelete` |
| Soft Deletes | Yes — `TemplateAssignment` model uses `SoftDeletes` trait |
| Transactional Logic | `store()` and `update()` wrapped in `DB::transaction` with mutex catch for Duplicate / FK / Generic exceptions |
| Activity Log | Yes — `activityLog()` called on store (created), update (updated), destroy (deleted), toggleStatus (status_updated), restore (restored), forceDelete (permanently_deleted) |

---

## 2. Pre-conditions

- Required permissions: `tenant.template.assignment.viewAny`, `tenant.template.assignment.create`, `tenant.template.assignment.update`, `tenant.template.assignment.view`, `tenant.template.assignment.delete`, `tenant.template.assignment.restore`, `tenant.template.assignment.forceDelete`
- At least one active Template must exist in `tmp_templates` (`is_active = 1`)
- At least one active TemplatePurpose must exist in `tmp_template_purposes` (`is_active = 1`)
- At least one active OrganizationAcademicSession must exist in `sch_org_academic_sessions_jnt`
- For class-scoped tests: at least one active SchoolClass must exist in `sch_classes`
- For group-scoped tests: at least one active class group must exist in `sch_class_groups_jnt`
- For search/filter tests: at least one TemplateAssignment record with populated FK fields
- For toggle-status tests: at least one active and one inactive assignment record
- For trash/restore tests: at least one soft-deleted assignment record
- For duplicate scope tests: an existing assignment that defines a unique `scope_hash` combination

---

## 3. Default Data Load

### 3.1 Assignment List via Tab View

The `index()` method redirects to `route('template.tabs', ['tab' => 'assignment_list'])`. The actual list is rendered by `TemplateController::assignmentsQuery()` which returns:
- `assignments` — Paginated `TemplateAssignment` records with filters
- `templates` — List of active templates for filter dropdown
- `purposes` — List of active purposes for filter dropdown
- `sessions` — List of active academic sessions for filter dropdown
- `classes` — List of active classes for filter dropdown
- `groups` — List of active class groups for filter dropdown

Search/filter parameters:
- `filter_template_id` — Filter by FK template_id
- `filter_purpose_id` — Filter by FK purpose_id
- `filter_session_id` — Filter by FK academic_session_id
- `filter_scope` — Scope filter: 'school', 'class', 'group'
- `filter_status` — `is_active` filter (converted to boolean)

### 3.2 Create Form Data

The `create()` method returns:
- `templates` — Only active templates (`is_active = 1`)
- `purposes` — Only active purposes
- `sessions` — Only active academic sessions
- `classes` — Only active classes
- `groups` — Only active class groups

---

## 4. BC-DB — Database Schema

### 4.1 `tmp_template_assignments` — Primary Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| template_id | INT UNSIGNED | NOT NULL | — | FK → `tmp_templates(id)` ON DELETE RESTRICT |
| purpose_id | INT UNSIGNED | NOT NULL | — | FK → `tmp_template_purposes(id)` ON DELETE RESTRICT |
| academic_session_id | SMALLINT UNSIGNED | NOT NULL | — | FK → `sch_org_academic_sessions_jnt(id)` ON DELETE RESTRICT |
| class_id | INT UNSIGNED | YES | NULL | FK → `sch_classes(id)` ON DELETE RESTRICT |
| class_group_id | INT UNSIGNED | YES | NULL | FK → `sch_class_groups_jnt(id)` ON DELETE RESTRICT |
| scope_hash | VARCHAR(80) | NOT NULL | — | `GENERATED ALWAYS AS (CONCAT(purpose_id,':',academic_session_id,':',COALESCE(CONCAT('C',class_id),COALESCE(CONCAT('G',class_group_id),'SCHOOL')))) STORED` — UNIQUE |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_template_assignments_scope_hash` (`scope_hash`)
- KEY `idx_tmp_ta_template_id` (`template_id`)
- KEY `idx_tmp_ta_purpose_id` (`purpose_id`)
- KEY `idx_tmp_ta_session_id` (`academic_session_id`)
- KEY `idx_tmp_ta_class_id` (`class_id`)
- KEY `idx_tmp_ta_class_group_id` (`class_group_id`)
- Composite indexes for resolution queries

**CHECK Constraint:**
```
CHECK (
    (class_id IS NOT NULL AND class_group_id IS NULL) OR
    (class_id IS NULL AND class_group_id IS NOT NULL) OR
    (class_id IS NULL AND class_group_id IS NULL)
)
```

---

## 5. BC-VAL — Validation Rules

### 5.1 StoreTemplateAssignmentRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| template_id | required, integer, exists:tmp_templates,id | "The template field is required." |
| purpose_id | required, integer, exists:tmp_template_purposes,id | "The purpose field is required." |
| academic_session_id | required, integer, exists:sch_org_academic_sessions_jnt,id | "The academic session field is required." |
| class_id | nullable, integer, exists:sch_classes,id | "The selected class is invalid." |
| class_group_id | nullable, integer, exists:sch_class_groups_jnt,id | "The selected class group is invalid." |

**withValidator — Mutual Exclusivity Check:**
- Rule: `class_id` XOR `class_group_id` (both set OR both null allowed for school-wide; both set disallowed)
- Custom message: "You cannot select both a class and a class group simultaneously."

**withValidator — Duplicate Scope Check:**
- Query: `TemplateAssignment::where('purpose_id', $value)->where('academic_session_id', $value)` with scope resolution matching
- Custom message: "A template assignment with the same purpose, session, and scope already exists."

**Custom Messages:**
- `template_id.required`: "The template field is required."
- `template_id.exists`: "The selected template does not exist."
- `purpose_id.required`: "The purpose field is required."
- `purpose_id.exists`: "The selected purpose does not exist."
- `academic_session_id.required`: "The academic session field is required."
- `academic_session_id.exists`: "The selected academic session does not exist."

### 5.2 UpdateTemplateAssignmentRequest Validation

Same rules as StoreTemplateAssignmentRequest, with the following difference:
- **Duplicate Scope Check:** Ignores the current record ID in the duplicate query:
  `->where('id', '!=', $this->route('template_assignment'))`

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.template.assignment.viewAny | index() | TemplateAssignmentPolicy@viewAny |
| tenant.template.assignment.restore | trashed() | TemplateAssignmentPolicy@restore |
| tenant.template.assignment.view | show() | TemplateAssignmentPolicy@view |
| tenant.template.assignment.create | create(), store() | TemplateAssignmentPolicy@create |
| tenant.template.assignment.update | edit(), update(), toggleStatus() | TemplateAssignmentPolicy@update |
| tenant.template.assignment.delete | destroy() | TemplateAssignmentPolicy@delete |
| tenant.template.assignment.restore | restore() | TemplateAssignmentPolicy@restore |
| tenant.template.assignment.forceDelete | forceDelete() | TemplateAssignmentPolicy@forceDelete |

**index() Gate Behaviour:** Uses `Gate::authorize('tenant.template.assignment.viewAny')` — requires the specific viewAny permission.

**trashed() Gate Behaviour:** Uses `Gate::authorize('tenant.template.assignment.restore')` — separate from index's viewAny gate.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | List with Filter Dropdowns | index() returns paginated assignments + active template/purpose/session/class/group lists for filter dropdowns |
| BC-BIZ-02 | Create Loads Only Active Entities | create() loads templates where is_active=1, purposes where is_active=1, sessions where is_active=1, classes where is_active=1, groups where is_active=1 |
| BC-BIZ-03 | DB::transaction in store() | store() wraps create in DB::transaction — on failure catches DuplicateEntryException, FK violation, and generic \Exception; each returns user-friendly flash message |
| BC-BIZ-04 | Mutual Exclusivity Enforced in Controller | store() and update() force `class_group_id = null` if `class_id` is set and vice versa BEFORE model creation/update — acts as second defence layer after FormRequest |
| BC-BIZ-05 | Scope Hash DB Uniqueness | The `scope_hash` generated column enforces uniqueness at DB level: CONCAT(purpose_id,':',academic_session_id,':',scope_identifier) where scope_identifier = C{class_id} or G{class_group_id} or 'SCHOOL' |
| BC-BIZ-06 | Duplicate Entry Detection | DB exception with code 23000 /Integrity constraint violation/ is parsed; if message contains 'Duplicate' → user message about duplicate scope; if contains 'Cannot add or update a child row' → FK violation message |
| BC-BIZ-07 | Foreign Key Violation Handling | FK violations caught in catch block, flash error message: "The referenced record does not exist or is invalid." |
| BC-BIZ-08 | Generic Exception Fallback | Any unhandled DB exception falls through to generic message: "An error occurred while saving the template assignment." |
| BC-BIZ-09 | DB::transaction in update() | update() follows same transaction + exception handling pattern as store() |
| BC-BIZ-10 | Soft Delete (destroy) | destroy() calls `$assignment->delete()` — no cascade check needed; model uses SoftDeletes |
| BC-BIZ-11 | Restore | restore() uses `TemplateAssignment::onlyTrashed()->findOrFail($id)` then `$assignment->restore()` |
| BC-BIZ-12 | Force Delete | forceDelete() uses `TemplateAssignment::withTrashed()->findOrFail($id)` then `$assignment->forceDelete()` |
| BC-BIZ-13 | Toggle Status via AJAX | toggleStatus() validates `is_active` as required|boolean, updates the field, returns JSON success/error response |
| BC-BIZ-14 | Polymorphic Scope Resolution | Scopes `forSession($sessionId)`, `forClass($classId)`, `forGroup($groupId)`, `schoolWide()` used for resolution queries |
| BC-BIZ-15 | Active Scope | Scope `active()` filters `is_active = 1` — used across the feature for dropdown population |
| BC-BIZ-16 | Composite Indexes for Resolution | DB indexes purpose_id+academic_session_id+scope_hash to optimise resolution queries that find matching assignments |
| BC-BIZ-17 | Activity Log All Operations | activityLog() called on store (created), update (updated), destroy (deleted), toggleStatus (status_updated), restore (restored), forceDelete (permanently_deleted) — tracks who performed each action |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_tmp_ta_template_id | tmp_template_assignments.template_id | tmp_templates.id | RESTRICT |
| fk_tmp_ta_purpose_id | tmp_template_assignments.purpose_id | tmp_template_purposes.id | RESTRICT |
| fk_tmp_ta_session_id | tmp_template_assignments.academic_session_id | sch_org_academic_sessions_jnt.id | RESTRICT |
| fk_tmp_ta_class_id | tmp_template_assignments.class_id | sch_classes.id | RESTRICT |
| fk_tmp_ta_class_group_id | tmp_template_assignments.class_group_id | sch_class_groups_jnt.id | RESTRICT |

---

## 9. Test Case Summary

### 9.1 Template Assignment CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPA-P01 | Template Assignment CRUD | Positive | List loads with all filter dropdowns | 5 |
| TC-TMPA-P02 | Template Assignment CRUD | Positive | Create assignment — school-wide scope | 7 |
| TC-TMPA-P03 | Template Assignment CRUD | Positive | Create assignment — specific class scope | 7 |
| TC-TMPA-P04 | Template Assignment CRUD | Positive | Create assignment — class group scope | 7 |
| TC-TMPA-P05 | Template Assignment CRUD | Positive | View assignment detail | 3 |
| TC-TMPA-P06 | Template Assignment CRUD | Positive | Edit assignment — change scope | 6 |
| TC-TMPA-P07 | Template Assignment CRUD | Positive | Toggle status — active to inactive | 4 |
| TC-TMPA-P08 | Template Assignment CRUD | Positive | Toggle status — inactive to active | 4 |
| TC-TMPA-P09 | Template Assignment CRUD | Positive | Soft-delete assignment | 3 |
| TC-TMPA-P10 | Template Assignment CRUD | Positive | View trashed assignments | 3 |
| TC-TMPA-P11 | Template Assignment CRUD | Positive | Restore assignment from trash | 4 |
| TC-TMPA-P12 | Template Assignment CRUD | Positive | Force-delete assignment | 4 |
| TC-TMPA-P13 | Template Assignment CRUD | Positive | Activity log created on assignment store | 3 |
| TC-TMPA-P14 | Template Assignment CRUD | Positive | Activity log created on assignment update | 3 |
| TC-TMPA-P15 | Template Assignment CRUD | Positive | Activity log created on assignment soft-delete | 2 |
| TC-TMPA-P16 | Template Assignment CRUD | Positive | Activity log created on assignment restore | 2 |
| TC-TMPA-P17 | Template Assignment CRUD | Positive | Activity log created on assignment force-delete | 2 |
| TC-TMPA-P18 | Template Assignment CRUD | Positive | Activity log created on assignment toggle-status | 3 |
 
### 9.2 Template Assignment CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPA-N01 | Template Assignment CRUD | Negative | Create — missing template_id | 2 |
| TC-TMPA-N02 | Template Assignment CRUD | Negative | Create — missing purpose_id | 2 |
| TC-TMPA-N03 | Template Assignment CRUD | Negative | Create — missing academic_session_id | 2 |
| TC-TMPA-N04 | Template Assignment CRUD | Negative | Create — invalid template_id (non-existent FK) | 2 |
| TC-TMPA-N05 | Template Assignment CRUD | Negative | Create — invalid purpose_id (non-existent FK) | 2 |
| TC-TMPA-N06 | Template Assignment CRUD | Negative | Create — invalid academic_session_id (non-existent FK) | 2 |
| TC-TMPA-N07 | Template Assignment CRUD | Negative | Create — invalid class_id (non-existent FK) | 2 |
| TC-TMPA-N08 | Template Assignment CRUD | Negative | Create — invalid class_group_id (non-existent FK) | 2 |
| TC-TMPA-N09 | Template Assignment CRUD | Negative | Create — duplicate scope (same purpose+session+class) | 3 |
| TC-TMPA-N10 | Template Assignment CRUD | Negative | Create — duplicate scope (same purpose+session+group) | 3 |
| TC-TMPA-N11 | Template Assignment CRUD | Negative | Create — both class_id and class_group_id set (check constraint violation) | 3 |
| TC-TMPA-N12 | Template Assignment CRUD | Negative | Create — inactive template (not in dropdown but directly POSTed) | 2 |
| TC-TMPA-N13 | Template Assignment CRUD | Negative | Permission — index without tenant.template.assignment.viewAny | 2 |
| TC-TMPA-N14 | Template Assignment CRUD | Negative | Permission — create without tenant.template.assignment.create | 2 |
| TC-TMPA-N15 | Template Assignment CRUD | Negative | Permission — store without tenant.template.assignment.create | 2 |
| TC-TMPA-N16 | Template Assignment CRUD | Negative | Permission — edit without tenant.template.assignment.update | 2 |
| TC-TMPA-N17 | Template Assignment CRUD | Negative | Permission — update without tenant.template.assignment.update | 2 |
| TC-TMPA-N18 | Template Assignment CRUD | Negative | Permission — view show without tenant.template.assignment.view | 2 |
| TC-TMPA-N19 | Template Assignment CRUD | Negative | Permission — destroy without tenant.template.assignment.delete | 2 |
| TC-TMPA-N20 | Template Assignment CRUD | Negative | Permission — trashed without tenant.template.assignment.viewAny | 2 |
| TC-TMPA-N21 | Template Assignment CRUD | Negative | Permission — restore without tenant.template.assignment.restore | 2 |
| TC-TMPA-N22 | Template Assignment CRUD | Negative | Permission — forceDelete without tenant.template.assignment.forceDelete | 2 |
| TC-TMPA-N23 | Template Assignment CRUD | Negative | Permission — toggleStatus without tenant.template.assignment.update | 2 |
| TC-TMPA-N24 | Template Assignment CRUD | Negative | Toggle status — missing is_active parameter | 2 |
| TC-TMPA-N25 | Template Assignment CRUD | Negative | Toggle status — non-boolean is_active value | 2 |
| TC-TMPA-N26 | Template Assignment CRUD | Negative | Operations — non-existent ID for show | 2 |
| TC-TMPA-N27 | Template Assignment CRUD | Negative | Operations — non-existent ID for edit | 2 |
| TC-TMPA-N28 | Template Assignment CRUD | Negative | Operations — non-existent ID for update | 2 |
| TC-TMPA-N29 | Template Assignment CRUD | Negative | Operations — non-existent ID for destroy | 2 |
| TC-TMPA-N30 | Template Assignment CRUD | Negative | Operations — non-existent ID for toggleStatus | 2 |
| TC-TMPA-N31 | Template Assignment CRUD | Negative | Operations — non-existent ID for restore | 2 |
| TC-TMPA-N32 | Template Assignment CRUD | Negative | Operations — non-existent ID for forceDelete | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPA-CR01 | Code Review | Review | store() — DB::transaction + exception handling with Duplicate/FK detection | 5 |
| TC-TMPA-CR02 | Code Review | Review | update() — DB::transaction + exception handling same pattern | 5 |
| TC-TMPA-CR03 | Code Review | Review | Mutual exclusivity logic in controller (class XOR group) | 3 |
| TC-TMPA-CR04 | Code Review | Review | StoreTemplateAssignmentRequest — field rules | 4 |
| TC-TMPA-CR05 | Code Review | Review | StoreTemplateAssignmentRequest — withValidator mutual exclusivity + duplicate checks | 5 |
| TC-TMPA-CR06 | Code Review | Review | UpdateTemplateAssignmentRequest — duplicate check ignores current ID | 4 |
| TC-TMPA-CR07 | Code Review | Review | TemplateAssignmentPolicy — all 7 gate method signatures | 4 |
| TC-TMPA-CR08 | Code Review | Review | TemplateAssignment Model — fillable, casts, SoftDeletes | 4 |
| TC-TMPA-CR09 | Code Review | Review | TemplateAssignment Model — scopes (active, forSession, forClass, forGroup, schoolWide) | 5 |
| TC-TMPA-CR10 | Code Review | Review | TemplateAssignment Model — relations (template, purpose, academicSession, classModel, classGroup) | 5 |
| TC-TMPA-CR11 | Code Review | Review | DDL — scope_hash GENERATED ALWAYS AS ... STORED UNIQUE | 4 |
| TC-TMPA-CR12 | Code Review | Review | DDL — CHECK constraint (class XOR group XOR both NULL) | 3 |
| TC-TMPA-CR13 | Code Review | Review | DDL — Composite indexes for resolution queries | 3 |
| TC-TMPA-CR14 | Code Review | Review | destroy() — soft-delete without cascade check | 3 |
| TC-TMPA-CR15 | Code Review | Review | restore() — onlyTrashed()->findOrFail + restore | 3 |
| TC-TMPA-CR16 | Code Review | Review | forceDelete() — withTrashed()->findOrFail + forceDelete | 3 |
| TC-TMPA-CR17 | Code Review | Review | toggleStatus() — Gate + validation + JSON response | 4 |
| TC-TMPA-CR18 | Code Review | Review | create() — loads only active entities for dropdowns | 3 |
| TC-TMPA-CR19 | Code Review | Review | store() — catch block detects "Duplicate entry" / "1062" and returns user-friendly message | 4 |
| TC-TMPA-CR20 | Code Review | Review | update() — catch block same pattern for duplicate entry | 4 |
| TC-TMPA-CR21 | Code Review | Review | store() — catch block detects "foreign key constraint" / "1452" and returns user-friendly message | 4 |
| TC-TMPA-CR22 | Code Review | Review | update() — catch block same pattern for FK violation | 4 |
| TC-TMPA-CR23 | Code Review | Review | store() — activityLog call with template_id and purpose_id | 2 |
| TC-TMPA-CR24 | Code Review | Review | update() — activityLog call with assignment id | 2 |
| TC-TMPA-CR25 | Code Review | Review | destroy() — activityLog called before model delete | 2 |
| TC-TMPA-CR26 | Code Review | Review | restore() — activityLog call after restore | 2 |
| TC-TMPA-CR27 | Code Review | Review | forceDelete() — activityLog called after forceDelete (model already gone) | 2 |
| TC-TMPA-CR28 | Code Review | Review | toggleStatus() — activityLog call with is_active state | 2 |
 
### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TMPA-D01 | Dependency | Dependency | FK template_id → tmp_templates — RESTRICT on delete | 3 |
| TC-TMPA-D02 | Dependency | Dependency | FK purpose_id → tmp_template_purposes — RESTRICT on delete | 3 |
| TC-TMPA-D03 | Dependency | Dependency | FK academic_session_id → sch_org_academic_sessions_jnt — RESTRICT on delete | 3 |
| TC-TMPA-D04 | Dependency | Dependency | FK class_id → sch_classes — RESTRICT on delete | 3 |
| TC-TMPA-D05 | Dependency | Dependency | FK class_group_id → sch_class_groups_jnt — RESTRICT on delete | 3 |
| TC-TMPA-D06 | Dependency | Dependency | scope_hash generated column — uniqueness enforced at DB level | 3 |
| TC-TMPA-D07 | Dependency | Dependency | CHECK constraint — mutual exclusivity enforcement at DB level | 3 |
| TC-TMPA-D08 | Dependency | Dependency | Composite indexes — optimise resolution queries | 3 |
| TC-TMPA-D09 | Dependency | Dependency | Activity log entry created on every CRUD operation | 6 |
 
---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Template Assignment CRUD

#### TC-TMPA-P01: List loads with all filter dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.viewAny` permission navigates to `/assignments` | Index page loads |
| 2 | Verify filter dropdowns are present: template, purpose, session, scope, status | 5 filters visible |
| 3 | Verify paginated list with columns: template, purpose, session, scope (school/class/group), is_active toggle, Actions | All columns present |
| 4 | Verify pagination links (configurable per-page) | Paginated |
| 5 | Select a filter value (e.g. filter_status=Active) and verify results filter accordingly | Filter applied |

#### TC-TMPA-P02: Create assignment — school-wide scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.create` permission clicks "Add Assignment" | Create form loads |
| 2 | Verify dropdowns only show active templates, active purposes, active sessions, active classes, active groups | Only active entities shown |
| 3 | Select a valid template_id, valid purpose_id, valid academic_session_id | Required fields populated |
| 4 | Leave class_id and class_group_id both empty (school-wide) | Scope = school |
| 5 | is_active defaults to true (checked) | Active by default |
| 6 | Click Submit | Redirected to index with success flash |
| 7 | Verify DB: scope_hash = "{purpose_id}:{academic_session_id}:SCHOOL" | scope_hash generated correctly |

#### TC-TMPA-P03: Create assignment — specific class scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select template, purpose, academic session | Required fields set |
| 3 | Select a class_id from dropdown; leave class_group_id empty | Class selected |
| 4 | Submit form | Success |
| 5 | Verify DB: class_group_id is NULL, class_id is set | Mutual exclusivity enforced |
| 6 | Verify scope_hash = "{purpose_id}:{academic_session_id}:C{class_id}" | scope_hash correct |
| 7 | Verify assignment visible in active list | Listed |

#### TC-TMPA-P04: Create assignment — class group scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Select template, purpose, academic session | Required fields set |
| 3 | Select a class_group_id from dropdown; leave class_id empty | Group selected |
| 4 | Submit form | Success |
| 5 | Verify DB: class_id is NULL, class_group_id is set | Mutual exclusivity enforced |
| 6 | Verify scope_hash = "{purpose_id}:{academic_session_id}:G{class_group_id}" | scope_hash correct |
| 7 | Verify assignment visible in active list | Listed |

#### TC-TMPA-P05: View assignment detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.view` permission clicks "View" on an assignment row | Show page loads |
| 2 | Verify all fields displayed: template name, purpose, session, scope (class/group/school), status | All fields visible |
| 3 | Verify scope description is human-readable (e.g. "School-Wide", "Class: Class 10A", "Group: Group B") | Scope readable |

#### TC-TMPA-P06: Edit assignment — change scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.update` permission clicks "Edit" on a school-wide assignment | Edit form loads with pre-filled data |
| 2 | Change scope by selecting a class_id | class_group_id is cleared |
| 3 | Click Update | Redirected with success flash |
| 4 | Verify DB: class_id is set, class_group_id is NULL, scope_hash updated to "C{class_id}" | Scope changed |
| 5 | Edit same assignment again, change to a class_group_id | class_id is cleared |
| 6 | Verify scope_hash updated to "G{class_group_id}" | Group scope set |

#### TC-TMPA-P07: Toggle status — active to inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active assignment (is_active=true) in the list | Active assignment visible |
| 2 | Click status toggle to deactivate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 0 for the assignment | Deactivated |

#### TC-TMPA-P08: Toggle status — inactive to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive assignment (is_active=false) in the list | Inactive assignment visible |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 1 for the assignment | Activated |

#### TC-TMPA-P09: Soft-delete assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.delete` permission clicks "Delete" on an active assignment | Confirmation prompt |
| 2 | Confirm deletion | Assignment soft-deleted |
| 3 | Verify assignment no longer appears in active list, DB: deleted_at is not null | Soft-deleted |

#### TC-TMPA-P10: View trashed assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.viewAny` permission navigates to trashed list | Trash list loads with only soft-deleted records |
| 2 | Verify paginated list of trashed assignments with restore and force-delete actions | Trash actions visible |
| 3 | Verify active assignments are not shown in trash view | Only trashed records |

#### TC-TMPA-P11: Restore assignment from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.restore` permission navigates to trash | Trash list loads |
| 2 | Locate a soft-deleted assignment and click "Restore" | Assignment restored |
| 3 | Verify assignment appears in active list | Restored |
| 4 | Verify DB: deleted_at is NULL | Restoration confirmed |

#### TC-TMPA-P12: Force-delete assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.template.assignment.forceDelete` permission navigates to trash | Trash list loads |
| 2 | Locate a soft-deleted assignment and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Assignment permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) | Permanently deleted |

#### TC-TMPA-P13: Activity log created on assignment store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new assignment via store() | Success |
| 2 | Verify `activityLog()` was called with the TemplateAssignment model, action='created', and properties include template_id and purpose_id | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-TMPA-P14: Activity log created on assignment update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update an assignment via update() | Success |
| 2 | Verify `activityLog()` called with action='updated' and id in properties | Logged |
| 3 | Verify changes are tracked in activity log properties | Change tracking |

#### TC-TMPA-P15: Activity log created on assignment soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an assignment via destroy() | Success |
| 2 | Verify `activityLog()` called with action='deleted' and assignment id | Logged |

#### TC-TMPA-P16: Activity log created on assignment restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed assignment via restore() | Success |
| 2 | Verify `activityLog()` called with action='restored' and assignment id | Logged |

#### TC-TMPA-P17: Activity log created on assignment force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed assignment via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='permanently_deleted' and assignment id | Logged |

#### TC-TMPA-P18: Activity log created on assignment toggle-status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle assignment status via toggleStatus() | AJAX success |
| 2 | Verify `activityLog()` called with action='status_updated' and properties include is_active state | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

### 10.2 Negative TC Steps — Template Assignment CRUD

#### TC-TMPA-N01: Create — missing template_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without template_id | Validation error |
| 2 | Verify error: "The template field is required." | Error shown |

#### TC-TMPA-N02: Create — missing purpose_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without purpose_id | Validation error |
| 2 | Verify error: "The purpose field is required." | Error shown |

#### TC-TMPA-N03: Create — missing academic_session_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without academic_session_id | Validation error |
| 2 | Verify error: "The academic session field is required." | Error shown |

#### TC-TMPA-N04: Create — invalid template_id (non-existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with template_id = 99999 (non-existent) | Validation error |
| 2 | Verify error: "The selected template does not exist." | Error shown |

#### TC-TMPA-N05: Create — invalid purpose_id (non-existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with purpose_id = 99999 (non-existent) | Validation error |
| 2 | Verify error: "The selected purpose does not exist." | Error shown |

#### TC-TMPA-N06: Create — invalid academic_session_id (non-existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with academic_session_id = 99999 (non-existent) | Validation error |
| 2 | Verify error: "The selected academic session does not exist." | Error shown |

#### TC-TMPA-N07: Create — invalid class_id (non-existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with class_id = 99999 (non-existent) | Validation error |
| 2 | Verify error: "The selected class is invalid." | Error shown |

#### TC-TMPA-N08: Create — invalid class_group_id (non-existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit with class_group_id = 99999 (non-existent) | Validation error |
| 2 | Verify error: "The selected class group is invalid." | Error shown |

#### TC-TMPA-N09: Create — duplicate scope (same purpose+session+class)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing assignment for purpose_id=1, academic_session_id=2, class_id=3 | Record exists |
| 2 | Submit create with same purpose_id=1, academic_session_id=2, class_id=3 | Duplicate detected |
| 3 | Verify error message: "A template assignment with the same purpose, session, and scope already exists." | Duplicate error shown |

#### TC-TMPA-N10: Create — duplicate scope (same purpose+session+group)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing assignment for purpose_id=1, academic_session_id=2, class_group_id=4 | Record exists |
| 2 | Submit create with same purpose_id=1, academic_session_id=2, class_group_id=4 | Duplicate detected |
| 3 | Verify error message: "A template assignment with the same purpose, session, and scope already exists." | Duplicate error shown |

#### TC-TMPA-N11: Create — both class_id and class_group_id set (check constraint violation)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with class_id=3 AND class_group_id=4 both set | FormRequest rejects with custom error |
| 2 | Verify error: "You cannot select both a class and a class group simultaneously." | Mutual exclusivity error |
| 3 | If FormRequest withValidator is bypassed (direct API), verify DB CHECK constraint rejects the INSERT | DB constraint violation |

#### TC-TMPA-N12: Create — inactive template directly POSTed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template with id=5 exists but is_active=0 | Inactive template |
| 2 | Submit create with template_id=5 bypassing dropdown (direct POST) | StoreTemplateAssignmentRequest validates `exists:tmp_templates,id` — passes FK check |
| 3 | Record is created successfully (exists rule only checks existence, not is_active). Note: Frontend prevents selection but backend lacks active-only validation for template_id. | Gap: Active filter only in dropdown, not in validation rule |

#### TC-TMPA-N13: Permission — index without tenant.template.assignment.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.viewAny` accesses `/assignments` | 403 Forbidden |

#### TC-TMPA-N14: Permission — create without tenant.template.assignment.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.create` accesses `/assignments/create` | 403 Forbidden |

#### TC-TMPA-N15: Permission — store without tenant.template.assignment.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.create` POSTs to `/assignments` | 403 Forbidden |

#### TC-TMPA-N16: Permission — edit without tenant.template.assignment.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.update` accesses `/assignments/{id}/edit` | 403 Forbidden |

#### TC-TMPA-N17: Permission — update without tenant.template.assignment.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.update` PUTs to `/assignments/{id}` | 403 Forbidden |

#### TC-TMPA-N18: Permission — view show without tenant.template.assignment.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.view` accesses `/assignments/{id}` | 403 Forbidden |

#### TC-TMPA-N19: Permission — destroy without tenant.template.assignment.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.delete` DELETEs `/assignments/{id}` | 403 Forbidden |

#### TC-TMPA-N20: Permission — trashed without tenant.template.assignment.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.viewAny` accesses `/assignments/trashed` | 403 Forbidden |

#### TC-TMPA-N21: Permission — restore without tenant.template.assignment.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.restore` POSTs to `/assignments/{id}/restore` | 403 Forbidden |

#### TC-TMPA-N22: Permission — forceDelete without tenant.template.assignment.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.forceDelete` DELETEs `/assignments/{id}/force-delete` | 403 Forbidden |

#### TC-TMPA-N23: Permission — toggleStatus without tenant.template.assignment.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.template.assignment.update` POSTs to `/assignments/{id}/toggle-status` | 403 Forbidden |

#### TC-TMPA-N24: Toggle status — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/assignments/{id}/toggle-status` without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-TMPA-N25: Toggle status — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/assignments/{id}/toggle-status` with is_active="not-a-boolean" | Validation error |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-TMPA-N26: Operations — non-existent ID for show

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/assignments/99999` | Assignment 99999 doesn't exist |
| 2 | Verify 404 Not Found | 404 error |

#### TC-TMPA-N27: Operations — non-existent ID for edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/assignments/99999/edit` | Assignment 99999 doesn't exist |
| 2 | Verify 404 Not Found | 404 error |

#### TC-TMPA-N28: Operations — non-existent ID for update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/assignments/99999` | Assignment 99999 doesn't exist |
| 2 | Verify 404 Not Found | 404 error |

#### TC-TMPA-N29: Operations — non-existent ID for destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/assignments/99999` | Assignment 99999 doesn't exist |
| 2 | Verify 404 Not Found | 404 error |

#### TC-TMPA-N30: Operations — non-existent ID for toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/assignments/99999/toggle-status` with is_active=true | Assignment 99999 doesn't exist |
| 2 | Verify 404 Not Found | 404 error |

#### TC-TMPA-N31: Operations — non-existent ID for restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/assignments/99999/restore` | Assignment 99999 doesn't exist |
| 2 | Verify 404 Not Found from onlyTrashed()->findOrFail | 404 error |

#### TC-TMPA-N32: Operations — non-existent ID for forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/assignments/99999/force-delete` | Assignment 99999 doesn't exist |
| 2 | Verify 404 Not Found from withTrashed()->findOrFail | 404 error |

### 10.3 Code Review TC Steps

#### TC-TMPA-CR01: store() — DB::transaction + exception handling with Duplicate/FK detection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `DB::transaction(function() { ... })` wrapping the entire store logic | Transaction wrap present |
| 2 | Review mutual exclusivity force: if class_id set → class_group_id = null and vice versa | Force set before create |
| 3 | Review catch block for `\Exception $e` — checks if `$e->getCode() == 23000` or message contains 'Duplicate' | Duplicate detection |
| 4 | Review catch block checking message for 'Cannot add or update a child row' to detect FK violations | FK detection |
| 5 | Review generic fallback: flash error message if no specific pattern matched | Generic error fallback |

#### TC-TMPA-CR02: update() — DB::transaction + exception handling same pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `DB::transaction(function() { ... })` wrapping update logic | Transaction wrap present |
| 2 | Review mutual exclusivity force (same as store) | Force set before update |
| 3 | Review catch block with same Duplicate/FK/generic exception patterns | Exception handling |
| 4 | Review that scope_hash is recalculated automatically after scope change (generated column) | Auto-update via DDL |
| 5 | Review flash success/error messages consistent with store() | Flash consistency |

#### TC-TMPA-CR03: Mutual exclusivity logic in controller (class XOR group)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store(): `if ($validated['class_id']) { $validated['class_group_id'] = null; } elseif ($validated['class_group_id']) { $validated['class_id'] = null; }` | XOR logic present |
| 2 | Review update(): same XOR pattern applied to validated data before update | XOR in update too |
| 3 | Review that empty strings are handled (converted to null) before the XOR logic | Empty string handling |

#### TC-TMPA-CR04: StoreTemplateAssignmentRequest — field rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `template_id`: required|integer|exists:tmp_templates,id | Rule present |
| 2 | Review `purpose_id`: required|integer|exists:tmp_template_purposes,id | Rule present |
| 3 | Review `academic_session_id`: required|integer|exists:sch_org_academic_sessions_jnt,id | Rule present |
| 4 | Review `class_id`: nullable|integer|exists:sch_classes,id and `class_group_id`: nullable|integer|exists:sch_class_groups_jnt,id | Nullable FK rules |

#### TC-TMPA-CR05: StoreTemplateAssignmentRequest — withValidator mutual exclusivity + duplicate checks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `withValidator($validator)` method override | Method present |
| 2 | Review `$validator->after()` callback with mutual exclusivity check: both class_id and class_group_id set → add error | XOR validation |
| 3 | Review `$validator->after()` callback with duplicate scope check query | Duplicate check |
| 4 | Review duplicate scope query correctly builds scope conditions matching class/group/school | Scope resolution in query |
| 5 | Review custom error messages for both after-validation rules | Custom messages |

#### TC-TMPA-CR06: UpdateTemplateAssignmentRequest — duplicate check ignores current ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review that UpdateTemplateAssignmentRequest extends or mirrors StoreTemplateAssignmentRequest | Inheritance/sharing |
| 2 | Review `$this->route('template_assignment')` or `$this->route('id')` to get current model ID | Route parameter resolution |
| 3 | Review duplicate scope query adds `->where('id', '!=', $currentId)` | Current ID ignored |
| 4 | Review same mutual exclusivity after-check exists in update request | XOR in update request |

#### TC-TMPA-CR07: TemplateAssignmentPolicy — all 7 gate method signatures

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `viewAny(User $user)` — returns `$user->can('tenant.template.assignment.viewAny')` | viewAny method |
| 2 | Review `view(User $user, TemplateAssignment $assignment)` — returns `$user->can('tenant.template.assignment.view')` | view method |
| 3 | Review `create(User $user)` — returns `$user->can('tenant.template.assignment.create')` | create method |
| 4 | Review `update(User $user, TemplateAssignment $assignment)` — returns `$user->can('tenant.template.assignment.update')` | update method |

#### TC-TMPA-CR08: TemplateAssignment Model — fillable, casts, SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array: template_id, purpose_id, academic_session_id, class_id, class_group_id, is_active | 6 fillable fields |
| 2 | Review `$casts` array: all FK fields → integer, is_active → boolean | Casts configured |
| 3 | Review `use SoftDeletes;` trait imported | SoftDeletes trait |
| 4 | Review `$dates` or `$casts` includes deleted_at if needed | Deleted at handled |

#### TC-TMPA-CR09: TemplateAssignment Model — scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeActive($query)` — `$query->where('is_active', 1)` | Active scope |
| 2 | Review `scopeForSession($query, $sessionId)` — `$query->where('academic_session_id', $sessionId)` | Session scope |
| 3 | Review `scopeForClass($query, $classId)` — `$query->where('class_id', $classId)` | Class scope |
| 4 | Review `scopeForGroup($query, $groupId)` — `$query->where('class_group_id', $groupId)` | Group scope |
| 5 | Review `scopeSchoolWide($query)` — `$query->whereNull('class_id')->whereNull('class_group_id')` | School-wide scope |

#### TC-TMPA-CR10: TemplateAssignment Model — relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `template()` — `$this->belongsTo(Template::class)` | BelongsTo Template |
| 2 | Review `purpose()` — `$this->belongsTo(TemplatePurpose::class)` | BelongsTo TemplatePurpose |
| 3 | Review `academicSession()` — `$this->belongsTo(OrganizationAcademicSession::class, 'academic_session_id')` | BelongsTo AcademicSession |
| 4 | Review `classModel()` — `$this->belongsTo(SchoolClass::class, 'class_id')` | BelongsTo SchoolClass |
| 5 | Review `classGroup()` — `$this->belongsTo(SchClassGroupsJnt::class, 'class_group_id')` | BelongsTo ClassGroup |

#### TC-TMPA-CR11: DDL — scope_hash GENERATED ALWAYS AS ... STORED UNIQUE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scope_hash VARCHAR(80) GENERATED ALWAYS AS (CONCAT(purpose_id,':',academic_session_id,':',COALESCE(CONCAT('C',class_id),COALESCE(CONCAT('G',class_group_id),'SCHOOL')))) STORED` | Generated column formula correct |
| 2 | Review UNIQUE constraint on scope_hash | Unique enforced |
| 3 | Review VARCHAR(80) is large enough for worst-case value | Size adequate |
| 4 | Review STORED keyword means value is physically stored and indexed | Stored generated column |

#### TC-TMPA-CR12: DDL — CHECK constraint (class XOR group XOR both NULL)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review CHECK constraint: (class_id IS NOT NULL AND class_group_id IS NULL) OR (class_id IS NULL AND class_group_id IS NOT NULL) OR (both NULL) | Three valid states |
| 2 | Review constraint is named or unnamed | Constraint present |
| 3 | Review that FormRequest + Controller logic prevents constraint violations before they reach DB | Defense in depth |

#### TC-TMPA-CR13: DDL — Composite indexes for resolution queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review composite index covering (purpose_id, academic_session_id, scope_hash) | Resolution index present |
| 2 | Review additional composite indexes for common query patterns (e.g. academic_session_id + class_id) | Query optimization |
| 3 | Review that index order matches query WHERE clause patterns | SARGable indexes |

#### TC-TMPA-CR14: destroy() — soft-delete without cascade check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.assignment.delete')` | Gate present |
| 2 | Review `$assignment->delete()` — triggers SoftDeletes | Soft delete |
| 3 | Review no manual is_active = false before delete (no redundant step) | Clean delete |

#### TC-TMPA-CR15: restore() — onlyTrashed()->findOrFail + restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.assignment.restore')` | Gate present |
| 2 | Review `TemplateAssignment::onlyTrashed()->findOrFail($id)` | Scoped to trashed only |
| 3 | Review `$assignment->restore()` | Restore called |

#### TC-TMPA-CR16: forceDelete() — withTrashed()->findOrFail + forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.assignment.forceDelete')` | Gate present |
| 2 | Review `TemplateAssignment::withTrashed()->findOrFail($id)` | Bypasses soft-delete scope |
| 3 | Review `$assignment->forceDelete()` | Permanent delete |

#### TC-TMPA-CR17: toggleStatus() — Gate + validation + JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.template.assignment.update')` | Gate uses update |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `TemplateAssignment::findOrFail($id)` | Model binding |
| 4 | Review JSON success/error response based on `$assignment->save()` | AJAX JSON response |

#### TC-TMPA-CR18: create() — loads only active entities for dropdowns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Template::active()->get()` for templates dropdown | Active templates only |
| 2 | Review `TemplatePurpose::active()->get()` for purposes dropdown | Active purposes only |
| 3 | Review sessions/classes/groups also filtered to active | All dropdowns active-filtered |

#### TC-TMPA-CR19: store() — catch block detects "Duplicate entry" / "1062" and returns user-friendly message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review try/catch in store() — locate the `catch (\Exception $e)` block | Catch block exists |
| 2 | Verify `$e->getMessage()` is checked for `'Duplicate entry'` OR `str_contains($msg, '1062')` | Duplicate detection present |
| 3 | Verify that when duplicate is detected, `DB::rollBack()` is called before returning | DB rollback before redirect |
| 4 | Verify user-friendly flash error: `"A template is already assigned for this specific Purpose, Session, and Scope."` | User-friendly message returned with redirect |

#### TC-TMPA-CR20: update() — catch block same pattern for duplicate entry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review try/catch in update() — locate the `catch (\Exception $e)` block | Catch block exists |
| 2 | Verify same `'Duplicate entry'` / `'1062'` detection logic as store() | Duplicate detection same pattern |
| 3 | Verify `DB::rollBack()` called on exception | Rollback before redirect |
| 4 | Verify same user-friendly flash error: `"A template is already assigned for this specific Purpose, Session, and Scope."` | Same message returned |

#### TC-TMPA-CR21: store() — catch block detects "foreign key constraint" / "1452" and returns user-friendly message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review catch block in store() for FK violation detection | FK detection present |
| 2 | Verify `$e->getMessage()` is checked for `'foreign key constraint'` OR `str_contains($msg, '1452')` | FK detection logic correct |
| 3 | Verify `DB::rollBack()` called on FK violation | Rollback before redirect |
| 4 | Verify user-friendly flash error: `"Invalid reference in selection. Please select valid options."` | User-friendly message returned |

#### TC-TMPA-CR22: update() — catch block same pattern for FK violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review catch block in update() for FK violation detection | FK detection present |
| 2 | Verify same `'foreign key constraint'` / `'1452'` detection logic as store() | FK detection same pattern |
| 3 | Verify `DB::rollBack()` called on FK violation | Rollback before redirect |
| 4 | Verify same user-friendly flash error: `"Invalid reference in selection. Please select valid options."` | Same message returned |

#### TC-TMPA-CR23: store() — activityLog call with template_id and purpose_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method after successful `TemplateAssignment::create($validated)` | After DB insert |
| 2 | Verify `activityLog($assignment, 'created', ['template_id' => ..., 'purpose_id' => ...])` | Activity logged with FK IDs |

#### TC-TMPA-CR24: update() — activityLog call with assignment id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method after `$assignment->update($validated)` | After DB update |
| 2 | Verify `activityLog($assignment, 'updated', ['id' => $assignment->id])` | Activity logged |

#### TC-TMPA-CR25: destroy() — activityLog called before model delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | Method flow |
| 2 | Verify `activityLog()` is called BEFORE `$assignment->delete()` to capture model data | Logged before deletion |

#### TC-TMPA-CR26: restore() — activityLog call after restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method | Method flow |
| 2 | Verify `activityLog($assignment, 'restored', ['id' => $assignment->id])` called after `$assignment->restore()` | Restore logged |

#### TC-TMPA-CR27: forceDelete() — activityLog called after forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` method | Method flow |
| 2 | Verify `activityLog($assignment, 'permanently_deleted', ['id' => $assignment->id])` called AFTER `$assignment->forceDelete()` | Permanent delete logged even after model removed |

#### TC-TMPA-CR28: toggleStatus() — activityLog call with is_active state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus()` method | Method flow |
| 2 | Verify `activityLog($assignment, 'status_updated', ['id' => $assignment->id, 'is_active' => $assignment->is_active])` | Status change logged with new state |

### 10.4 Dependency TC Steps

#### TC-TMPA-D01: FK template_id → tmp_templates — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template T1 has 3 associated assignments in tmp_template_assignments | Referenced template |
| 2 | Attempt to delete T1 from tmp_templates | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-TMPA-D02: FK purpose_id → tmp_template_purposes — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TemplatePurpose P1 has 2 associated assignments | Referenced purpose |
| 2 | Attempt to delete P1 from tmp_template_purposes | RESTRICT violation |
| 3 | Verify FK constraint prevents deletion | Delete blocked |

#### TC-TMPA-D03: FK academic_session_id → sch_org_academic_sessions_jnt — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | AcademicSession S1 has 5 associated assignments | Referenced session |
| 2 | Attempt to delete S1 from sch_org_academic_sessions_jnt | RESTRICT violation |
| 3 | Verify FK constraint blocks deletion | Delete blocked |

#### TC-TMPA-D04: FK class_id → sch_classes — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | SchoolClass C1 has 2 associated assignments | Referenced class |
| 2 | Attempt to delete C1 from sch_classes | RESTRICT violation |
| 3 | Verify FK constraint prevents deletion | Delete blocked |

#### TC-TMPA-D05: FK class_group_id → sch_class_groups_jnt — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | ClassGroup G1 has 1 associated assignment | Referenced group |
| 2 | Attempt to delete G1 from sch_class_groups_jnt | RESTRICT violation |
| 3 | Verify FK constraint blocks deletion | Delete blocked |

#### TC-TMPA-D06: scope_hash generated column — uniqueness enforced at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing assignment with scope_hash = "1:2:C3" | Record exists |
| 2 | Attempt INSERT with same purpose_id=1, academic_session_id=2, class_id=3 | scope_hash "1:2:C3" duplicate |
| 3 | Verify DB throws Integrity constraint violation: Duplicate entry for scope_hash | Unique violation |

#### TC-TMPA-D07: CHECK constraint — mutual exclusivity enforcement at DB level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt raw INSERT with class_id=3 AND class_group_id=4 both set | CHECK constraint violated |
| 2 | Verify DB rejects the INSERT with constraint violation error | CHECK enforced |
| 3 | Verify school-wide (both NULL) and single-scope (one set, one NULL) INSERTs succeed | Valid combinations pass |

#### TC-TMPA-D08: Composite indexes — optimise resolution queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `EXPLAIN SELECT * FROM tmp_template_assignments WHERE purpose_id = X AND academic_session_id = Y` | Index used (type ref or range) |
| 2 | Review `EXPLAIN SELECT * FROM tmp_template_assignments WHERE academic_session_id = Y AND class_id = Z` | Appropriate index used |
| 3 | Verify no full table scans for common resolution query patterns | Index coverage adequate |

#### TC-TMPA-D09: Activity log entry created on every CRUD operation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform store | Activity log: 'created' event created |
| 2 | Perform update | Activity log: 'updated' event created |
| 3 | Perform destroy (soft-delete) | Activity log: 'deleted' event created |
| 4 | Perform restore | Activity log: 'restored' event created |
| 5 | Perform forceDelete | Activity log: 'permanently_deleted' event created |
| 6 | Perform toggleStatus | Activity log: 'status_updated' event created |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/assignments` | template-assignments.index | index() | tenant.template.assignment.viewAny |
| GET | `/assignments/create` | template-assignments.create | create() | tenant.template.assignment.create |
| POST | `/assignments` | template-assignments.store | store() | tenant.template.assignment.create |
| GET | `/assignments/{template_assignment}` | template-assignments.show | show() | tenant.template.assignment.view |
| GET | `/assignments/{template_assignment}/edit` | template-assignments.edit | edit() | tenant.template.assignment.update |
| PUT | `/assignments/{template_assignment}` | template-assignments.update | update() | tenant.template.assignment.update |
| DELETE | `/assignments/{template_assignment}` | template-assignments.destroy | destroy() | tenant.template.assignment.delete |
| POST | `/assignments/{template_assignment}/toggle-status` | template-assignments.toggleStatus | toggleStatus() | tenant.template.assignment.update |
| GET | `/assignments-trash` | assignments.trashed | trashed() | tenant.template.assignment.restore |
| POST | `/assignments/{id}/restore` | template-assignments.restore | restore() | tenant.template.assignment.restore |
| DELETE | `/assignments/{id}/force-delete` | template-assignments.forceDelete | forceDelete() | tenant.template.assignment.forceDelete |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | template_id validation lacks `active` scope check | **Low** | `exists:tmp_templates,id` validates FK existence but does NOT check `is_active=1`; frontend dropdown filters to active templates but direct POST can assign inactive templates |
| KI-02 | purpose_id validation lacks `active` scope check | **Low** | Same as KI-01 — no `where is_active=1` constraint in validation rule |
| KI-03 | no max length validation on FK fields | **Info** | Integer FK fields implicitly bounded by DB column type (BIGINT); no application-level max validation |
| KI-04 | scope_hash generated column error messages not user-friendly | **Low** | MySQL generated column UNIQUE violation returns raw SQL error; application must catch and translate in controller |
| KI-05 | CHECK constraint error messages not user-friendly | **Low** | CHECK constraint violation returns raw DB error; application catch block must provide meaningful message |
| KI-06 | scope_hash VARCHAR(80) — potential future overflow | **Info** | Current concatenation pattern fits within 80 chars; future FK ID increases (e.g. BIGINT > 10 digits with prefixes) could theoretically overflow |
| KI-07 | ~~No activity logging on CRUD operations~~ (removed — `activityLog()` IS called on all CRUD ops) | — | — |
| KI-08 | No dedicated status permission | **Low** | toggleStatus() reuses `tenant.template.assignment.update` permission; no dedicated status gate |
| KI-09 | FormRequest authorize() behaviour | **Info** | Verify whether FormRequest `authorize()` checks Gate or returns true; if true, defence relies solely on controller Gate |
| KI-10 | Soft-deleted records not excluded from duplicate scope check in StoreTemplateAssignmentRequest | **Medium** | Duplicate scope check in `withValidator` does not filter `whereNull('deleted_at')`; soft-deleted records could block new creation with same scope |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Template Assignment List | index() | TemplateAssignment, Template, TemplatePurpose, OrganizationAcademicSession, SchoolClass, SchClassGroupsJnt | Configurable per-page |
| Create Assignment | create(), store() | TemplateAssignment + 5 FK models | None (form) |
| View Assignment | show() | TemplateAssignment | None |
| Edit Assignment | edit(), update() | TemplateAssignment | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | TemplateAssignment | Configurable per-page (trash) |
| Force Delete | forceDelete() | TemplateAssignment | None |
| Toggle Status | toggleStatus() | TemplateAssignment | None (AJAX) |
| **TC Count** | **Positive: 18 / Negative: 32 / Code Review: 28 / Dependency: 9** | **Total: 87** | |
