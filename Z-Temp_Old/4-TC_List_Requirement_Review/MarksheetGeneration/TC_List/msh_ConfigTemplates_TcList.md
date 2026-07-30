# Config Templates — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Config Template (`msh_config_templates`) |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\ConfigTemplateController` — 11 methods (index, create, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete) — hub listing via `MarksheetGenerationController::configuration()` |
| **Tab Container Controller** | `MarksheetGenerationController::configuration()` — tab id `config-templates`, private `applyFilters()` helper for listing |
| **Model** | `Modules\MarksheetGeneration\Models\ConfigTemplate` — SoftDeletes, 11 relationships |
| **Form Request** | `Modules\MarksheetGeneration\Http\Requests\ConfigTemplateRequest` — 18 validation rules + `prepareForValidation` |
| **Service** | `Modules\MarksheetGeneration\Services\ConfigTemplateService` — `create()`, `update()`, `delete()` with DB transaction + `syncClassAssignments()` |
| **Policy** | `ConfigTemplatePolicy` — 8 permission methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |
| **Route Prefix** | `marksheet-generation.config-template.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus` via modal entities loop |
| **Blade Views** | `_config-templates.blade.php` (tab partial), `config-template/create.blade.php` (standalone), `config-template/edit.blade.php` (standalone), `config-template/show.blade.php` (standalone), `trashed/config-template.blade.php` |
| **Tab Container** | `pages/configuration.blade.php` — tab id `config-templates`, permission `tenant.msh-config-template.view` |
| **DB Table** | `msh_config_templates` — 16 data columns + 3 timestamp columns; junction table `msh_class_config_jnt` |
| **Primary Screen** | Marksheet Generation → Configuration → Config Templates tab (paginated, searchable, standalone create/edit/show pages) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as Examination Coordinator (or role with `tenant.msh-config-template.*` permissions) |
| PC-02 | Database `msh_config_templates` table must exist with all 16 data columns |
| PC-03 | `msh_class_config_jnt` junction table must exist for class/group assignments |
| PC-04 | `msh_marksheet_types`, `msh_exam_groups`, `sch_org_academic_sessions_jnt`, `slb_grade_division_master` tables must have seed data |
| PC-05 | `sch_classes` and `msh_class_groups` tables must have data for class assignment selection |
| PC-06 | `ConfigTemplateController` must be registered with full resource + extra routes |
| PC-07 | `ConfigTemplatePolicy` must be registered in `AuthServiceProvider` |
| PC-08 | Config Templates tab must be included in `configuration.blade.php` with `@can('tenant.msh-config-template.view')` guard |
| PC-09 | Soft deletes enabled on `msh_config_templates` and `msh_class_config_jnt` |
| PC-10 | `ConfigTemplateService` must be available: `create()`, `update()`, `delete()`, `syncClassAssignments()` |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load config templates with pagination (15 per page) via `configuration() → applyFilters()` | `MarksheetGenerationController.php:77` — `ConfigTemplate::with(['marksheetType', 'examGroup', 'academicSession'])->...->paginate(15, ['*'], 'ct_page')` |
| DL-02 | Eager loads `marksheetType`, `examGroup`, `academicSession` relationships | `MarksheetGenerationController.php:77` |
| DL-03 | Search/status filters only when tab is `config-templates` | `$tab === 'config-templates'` conditional |
| DL-04 | Tab partial: `@include('..._config-templates')` inside `@can('tenant.msh-config-template.view')` | `configuration.blade.php:30-32` |
| DL-05 | List columns: **#**, **Code**, **Name**, **Board**, **Passing %**, **Status**, **Actions** | `_config-templates.blade.php:38-50` |
| DL-06 | Passing percentage displayed as `{{ $row->passing_percentage }}%` | `_config-templates.blade.php:57` |
| DL-07 | Board code shown as `-` if null | `_config-templates.blade.php:56` — `$row->board_code ?? '-'` |
| DL-08 | Status column uses `<x-backend.table.status-switch>` | `_config-templates.blade.php:61` |
| DL-09 | Action column uses `<x-backend.table.action>` (standard, not modal-based) | `_config-templates.blade.php:65` — links to standalone edit/show |
| DL-10 | Pagination preserves all query params | `_config-templates.blade.php:72` — `->appends(request()->query())` |
| DL-11 | Empty state: "No Config Templates Found" | `_config-templates.blade.php:23-31` |
| DL-12 | `create()` loads 7 collections: marksheetTypes, examGroups, academicSessions, gradingSchemas, schoolClasses, classGroups, existingAssignments (empty) | `ConfigTemplateController.php:35-41` |
| DL-13 | `edit()` loads 7 collections + existingAssignments loaded from `$configTemplate->classConfigs()` | `ConfigTemplateController.php:77-83` |
| DL-14 | Shared dropdowns in hub: `$currentAcademicSession`, `$marksheetTypesList`, `$examGroupsList` | `MarksheetGenerationController.php:82-86` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Config Template** | `academic_session_id=1`, `marksheet_type_id=1`, `exam_group_id=1`, `code='CBSE_SEC_TERM1'`, `name='CBSE Secondary Term-1'`, `board_code='CBSE'`, `passing_percentage=33.00`, `compartment_max_failures=2`, `is_best_of_n_enabled=true`, `best_of_n_count=2`, `class_assignments=[{type:'class', target_id:10}, {type:'group', target_id:1}]` |
| TD-02 | **Duplicate Code in Same Session** | Same `code`, same `academic_session_id` — expects scoped unique violation |
| TD-03 | **Duplicate Code Different Session** | Same `code`, different `academic_session_id` — should succeed |
| TD-04 | **Missing Required Fields** | Submit without `academic_session_id`, `marksheet_type_id`, `exam_group_id`, `code`, `name`, `passing_percentage`, `compartment_max_failures` — expects multiple required errors |
| TD-05 | **Passing Percentage > 100** | `passing_percentage=101` — expects `max:100` failure |
| TD-06 | **Passing Percentage < 0** | `passing_percentage=-5` — expects `min:0` failure |
| TD-07 | **Compartment Max Failures > 255** | `compartment_max_failures=256` — expects `max:255` failure |
| TD-08 | **Invalid Marksheet Type ID** | `marksheet_type_id=99999` — expects `exists` failure |
| TD-09 | **Invalid Exam Group ID** | `exam_group_id=99999` — expects `exists` failure |
| TD-10 | **Invalid Grading Schema ID** | `grading_schema_id=99999` — expects `exists` failure |
| TD-11 | **Invalid Class Assignment Type** | `class_assignments[0]={type:'invalid', target_id:1}` — expects `in:class,group` failure |
| TD-12 | **Soft-Deleted Code Reuse** | Delete template, create with same code in same session — should succeed |
| TD-13 | **Class Assignment Sync: Add** | Add 2 new assignments | Junction updated |
| TD-14 | **Class Assignment Sync: Remove** | Remove 2 assignments | Junction soft-deleted |
| TD-15 | **Class Assignment Sync: Clean Slate** | Service soft-deletes ALL existing assignments, then inserts/restores new ones | Clean-slate approach |
| TD-16 | **Force Delete with Components** | Template has Scholastic/IA components — expects 23000 catch |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `id` — INT PK, AUTO_INCREMENT | Primary key | DDL |
| BC-DB-02 | `academic_session_id` — SMALLINT UNSIGNED FK | FK → `sch_org_academic_sessions_jnt.id` | DDL |
| BC-DB-03 | `marksheet_type_id` — INT FK | FK → `msh_marksheet_types.id` | DDL |
| BC-DB-04 | `exam_group_id` — INT FK | FK → `msh_exam_groups.id` | DDL |
| BC-DB-05 | `grading_schema_id` — INT FK NULL | FK → `slb_grade_division_master.id`, nullable | DDL |
| BC-DB-06 | `code` — VARCHAR(50), NOT NULL | Max 50 chars | DDL |
| BC-DB-07 | Composite UNIQUE on (`academic_session_id`, `code`) | Unique within session | DDL |
| BC-DB-08 | `name` — VARCHAR(150), NOT NULL | Max 150 | DDL |
| BC-DB-09 | `description` — VARCHAR(500), NULLABLE | Max 500 | DDL |
| BC-DB-10 | `board_code` — VARCHAR(50), NULLABLE | Max 50 | DDL |
| BC-DB-11 | `passing_percentage` — DECIMAL(5,2), DEFAULT 33.00 | 5 digits total, 2 decimal | DDL |
| BC-DB-12 | `compartment_max_failures` — TINYINT UNSIGNED, DEFAULT 2 | 0-255 | DDL |
| BC-DB-13 | `is_best_of_n_enabled` — TINYINT(1), DEFAULT 0 | Boolean | DDL |
| BC-DB-14 | `best_of_n_count` — TINYINT UNSIGNED, NULL | Nullable count | DDL |
| BC-DB-15 | `is_locked` — TINYINT(1), DEFAULT 0 | Boolean | DDL |
| BC-DB-16 | `is_active` — TINYINT(1), DEFAULT 1 | Boolean | DDL |
| BC-DB-17 | `created_by` — INT, FK → `sys_users.id` | Required | DDL |
| BC-DB-18 | `updated_by` — INT NULL, FK → `sys_users.id` | Nullable | DDL |
| BC-DB-19 | Junction: `msh_class_config_jnt` with `config_template_id`, `class_id` NULL, `class_group_id` NULL, `is_active`, `created_by`, `updated_by`, `deleted_at` | Class/Group assignment junction | DDL |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `academic_session_id` — required, integer, exists | `required\|integer\|exists:sch_org_academic_sessions_jnt,id` | `ConfigTemplateRequest.php:17-22` |
| BC-VAL-02 | `marksheet_type_id` — required, integer, exists | `required\|integer\|exists:msh_marksheet_types,id` | `ConfigTemplateRequest.php:23` |
| BC-VAL-03 | `exam_group_id` — required, integer, exists | `required\|integer\|exists:msh_exam_groups,id` | `ConfigTemplateRequest.php:24` |
| BC-VAL-04 | `grading_schema_id` — nullable, integer, exists | `nullable\|integer\|exists:slb_grade_division_master,id` | `ConfigTemplateRequest.php:25` |
| BC-VAL-05 | `code` — required, string, max:50, unique within session | `required\|string\|max:50\|Rule::unique()->where(academic_session_id)` | `ConfigTemplateRequest.php:27-34` |
| BC-VAL-06 | `name` — required, string, max:150 | `required\|string\|max:150` | `ConfigTemplateRequest.php:35` |
| BC-VAL-07 | `description` — nullable, string, max:500 | `nullable\|string\|max:500` | `ConfigTemplateRequest.php:36` |
| BC-VAL-08 | `board_code` — nullable, string, max:50 | `nullable\|string\|max:50` | `ConfigTemplateRequest.php:37` |
| BC-VAL-09 | `passing_percentage` — required, numeric, min:0, max:100 | `required\|numeric\|min:0\|max:100` | `ConfigTemplateRequest.php:38` |
| BC-VAL-10 | `compartment_max_failures` — required, integer, min:0, max:255 | `required\|integer\|min:0\|max:255` | `ConfigTemplateRequest.php:39` |
| BC-VAL-11 | `is_best_of_n_enabled` — sometimes, boolean | `sometimes\|boolean` | `ConfigTemplateRequest.php:40` |
| BC-VAL-12 | `best_of_n_count` — nullable, integer, min:1, max:255 | `nullable\|integer\|min:1\|max:255` | `ConfigTemplateRequest.php:41` |
| BC-VAL-13 | `is_locked` — sometimes, boolean | `sometimes\|boolean` | `ConfigTemplateRequest.php:42` |
| BC-VAL-14 | `is_active` — sometimes, boolean | `sometimes\|boolean` | `ConfigTemplateRequest.php:43` |
| BC-VAL-15 | `class_assignments` — nullable, array | `nullable\|array` | `ConfigTemplateRequest.php:44` |
| BC-VAL-16 | `class_assignments.*.type` — required_with, in:class,group | `required_with:class_assignments\|in:class,group` | `ConfigTemplateRequest.php:45` |
| BC-VAL-17 | `class_assignments.*.target_id` — required_with, integer, min:1 | `required_with:class_assignments\|integer\|min:1` | `ConfigTemplateRequest.php:46` |
| BC-VAL-18 | `prepareForValidation()` normalizes all FK IDs to int | `(int) $this->input(...)` for 4 FK fields | `ConfigTemplateRequest.php:51-57` |
| BC-VAL-19 | `prepareForValidation()` normalizes 3 boolean fields | `$this->boolean()` for `is_best_of_n_enabled`, `is_locked`, `is_active` | `ConfigTemplateRequest.php:58-60` |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.msh-config-template.viewAny` | Hub via `configuration()`; Standalone: `index()` | `viewAny()` | `ConfigTemplateController.php:22` |
| BC-AUTH-02 | `tenant.msh-config-template.view` | Tab: `@can` in blade; Show: `show()` | `view()` | `configuration.blade.php:16`, `ConfigTemplateController.php:66` |
| BC-AUTH-03 | `tenant.msh-config-template.create` | `create()`, `store()` | `create()` | `ConfigTemplateController.php:33,51` |
| BC-AUTH-04 | `tenant.msh-config-template.update` | `edit()`, `update()`, `toggleStatus()`, `restore()` | `update()` | `ConfigTemplateController.php:75,93,108,144` |
| BC-AUTH-05 | `tenant.msh-config-template.delete` | `destroy()`, `forceDelete()` | `delete()` | `ConfigTemplateController.php:120,157` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Code unique within academic session | Composite unique + scoped Rule | `ConfigTemplateRequest.php:28-33` |
| BC-BIZ-02 | `store()` delegates to `ConfigTemplateService::create()` with DB transaction | Extracts `class_assignments`, creates template, syncs assignments | `ConfigTemplateService.php:9-20` |
| BC-BIZ-03 | `update()` delegates to `ConfigTemplateService::update()` | Re-syncs class assignments via clean-slate approach | `ConfigTemplateService.php:23-35` |
| BC-BIZ-04 | `destroy()` delegates to `ConfigTemplateService::delete()` | Soft-deletes within transaction | `ConfigTemplateService.php:39` |
| BC-BIZ-05 | `syncClassAssignments()` soft-deletes ALL existing assignments first | Clean-slate: `whereNull('deleted_at')->update(['deleted_at' => $now])` | `ConfigTemplateService.php:46-49` |
| BC-BIZ-06 | `syncClassAssignments()` then upserts each new assignment | Restores if previously soft-deleted, inserts if new | `ConfigTemplateService.php:51-76` |
| BC-BIZ-07 | `toggleStatus()` toggles `is_active` (not `is_locked`) | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | `ConfigTemplateController.php:111` |
| BC-BIZ-08 | `forceDelete()` catches `QueryException 23000` | Multiple FK consumers: schedules, scholastic, IA, exam weightage, coscholastic | `ConfigTemplateController.php:163-165` |
| BC-BIZ-09 | `create()` loads 7 reference collections for dropdowns | All active + ordered | `ConfigTemplateController.php:35-41` |
| BC-BIZ-10 | `edit()` loads same 7 collections + `existingAssignments` | `$configTemplate->classConfigs()->whereNull('deleted_at')->with(['schoolClass', 'classGroup'])->get()` | `ConfigTemplateController.php:83` |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | ConfigTemplate → OrganizationAcademicSession | `belongsTo(academicSession)` | `ConfigTemplate.php:35` |
| BC-REL-02 | ConfigTemplate → MarksheetType | `belongsTo(marksheetType)` | `ConfigTemplate.php:39` |
| BC-REL-03 | ConfigTemplate → ExamGroup | `belongsTo(examGroup)` | `ConfigTemplate.php:43` |
| BC-REL-04 | ConfigTemplate → GradeDivisionMaster | `belongsTo(gradingSchema)` | `ConfigTemplate.php:47` |
| BC-REL-05 | ConfigTemplate → TemplateScholasticComponent | `hasMany(scholasticComponents)` | `ConfigTemplate.php:63` |
| BC-REL-06 | ConfigTemplate → TemplateExamWeightage | `hasMany(examWeightages)` | `ConfigTemplate.php:67` |
| BC-REL-07 | ConfigTemplate → TemplateIaComponent | `hasMany(iaComponents)` | `ConfigTemplate.php:71` |
| BC-REL-08 | ConfigTemplate → TemplateCoscholasticComponent | `hasMany(coscholasticComponents)` | `ConfigTemplate.php:75` |
| BC-REL-09 | ConfigTemplate → ClassAssignment | `hasMany(classConfigs)` | `ConfigTemplate.php:79` |
| BC-REL-10 | ConfigTemplate → MarksheetSchedule | `hasMany(marksheetSchedules)` | `ConfigTemplate.php:83` |
| BC-REL-11 | ConfigTemplate → User (created_by) | `belongsTo(createdBy)` | `ConfigTemplate.php:51` |
| BC-REL-12 | ConfigTemplate → User (updated_by) | `belongsTo(updatedBy)` | `ConfigTemplate.php:55` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab loads with `@can('tenant.msh-config-template.view')` | Tab conditional | `configuration.blade.php:16` |
| BC-REF-02 | Search bar uses standard url (no `createModal` param) | Create links to standalone page, not modal | `_config-templates.blade.php:5` |
| BC-REF-03 | Status header/body in `@can('tenant.msh-config-template.update')` | Symmetrical | `_config-templates.blade.php:45-47,59-62` |
| BC-REF-04 | Actions header/body in `@canany(['...view','...update','...delete'])` | Symmetrical | `_config-templates.blade.php:48-50,63-66` |
| BC-REF-05 | Action column uses default `<x-backend.table.action>` (links to standalone pages) | Unlike other 4 entities which use modal-based editOnclick | `_config-templates.blade.php:65` |
| BC-REF-06 | `create()` and `edit()` return full standalone form views | Not modal-based | `ConfigTemplateController.php:43-46,85-88` |
| BC-REF-07 | `show()` eagerly loads all component relations | `load(['marksheetType', 'examGroup', 'academicSession', 'scholasticComponents', 'iaComponents', 'coscholasticComponents'])` | `ConfigTemplateController.php:68` |
| BC-REF-08 | `edit()` passes `existingAssignments` for class repeater pre-population | Junction data pre-loaded | `ConfigTemplateController.php:83` |
| BC-REF-09 | Empty state colspan in table | "No Config Templates Found" | `_config-templates.blade.php:23-31` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Hub paginates at 15 per page with page name `ct_page` | `ConfigTemplate::with(...)->...->paginate(15, ['*'], 'ct_page')` |
| BC-BIZ-DEEP-02 | Search on `name` and `code` columns | LIKE on both |
| BC-BIZ-DEEP-03 | Status filter on `is_active` | Exact match |
| BC-BIZ-DEEP-04 | Latest ordering via `->latest()` | `created_at DESC` |
| BC-BIZ-DEEP-05 | `store()` does NOT support AJAX JSON | Always redirect (no `$request->expectsJson()` check) |
| BC-BIZ-DEEP-06 | `update()` does NOT support AJAX JSON | Always redirect |
| BC-BIZ-DEEP-07 | `store()` redirects to hub with tab parameter | `->route('marksheet-generation.configuration.combined', ['tab' => 'config-templates'])` |
| BC-BIZ-DEEP-08 | `update()` same redirect pattern | Consistent |
| BC-BIZ-DEEP-09 | `destroy()` same redirect pattern | Consistent |
| BC-BIZ-DEEP-10 | `restore()` redirects to `marksheet-generation.config-template.trashed` | Trash route |
| BC-BIZ-DEEP-11 | `forceDelete()` failure redirects `->back()` | Error message |
| BC-BIZ-DEEP-12 | `toggleStatus()` returns JSON `{success: true, is_active, message}` | Consistent |
| BC-BIZ-DEEP-13 | `create()` filters all dropdowns to only active records | `where('is_active', true)` on all 6 collections |
| BC-BIZ-DEEP-14 | `create()` orders dropdowns by `display_order` or `name` | Appropriate sort for each |
| BC-BIZ-DEEP-15 | `existingAssignments` empty in `create()` | `$existingAssignments = collect()` — no pre-existing assignments |
| BC-BIZ-DEEP-16 | `edit()` existing assignments loaded with `schoolClass` and `classGroup` | `$configTemplate->classConfigs()->whereNull('deleted_at')->with(['schoolClass', 'classGroup'])->get()` |
| BC-BIZ-DEEP-17 | `syncClassAssignments()` soft-deletes ALL existing first | Clean-slate: all old records get `deleted_at` timestamp |
| BC-BIZ-DEEP-18 | `syncClassAssignments()` maps `type=class` → `class_id = target_id, class_group_id = null` | Mutually exclusive FK |
| BC-BIZ-DEEP-19 | `syncClassAssignments()` maps `type=group` → `class_group_id = target_id, class_id = null` | Mutually exclusive FK |
| BC-BIZ-DEEP-20 | `syncClassAssignments()` restores matching soft-deleted rows | `deleted_at = null` on matching existing |
| BC-BIZ-DEEP-21 | `syncClassAssignments()` inserts brand new rows | New `msh_class_config_jnt` rows |
| BC-BIZ-DEEP-22 | Class assignments extracted before create/update | `unset($data['class_assignments'])` |
| BC-BIZ-DEEP-23 | Service uses `DB::transaction()` for all CRUD | Atomic operations |
| BC-BIZ-DEEP-24 | `activityLog('Stored')` message: `'A new config template was created.'` | Consistency |
| BC-BIZ-DEEP-25 | `activityLog('Updated')` message: `'The config template was updated.'` | Consistency |
| BC-BIZ-DEEP-26 | `activityLog('Deleted')` message: `'The config template was deleted.'` | Consistency |
| BC-BIZ-DEEP-27 | `activityLog('Toggled')` message: `'Status was toggled.'` | No performed_by |
| BC-BIZ-DEEP-28 | `activityLog('Restored')` message: `'The record was restored.'` | No performed_by |
| BC-BIZ-DEEP-29 | `activityLog('Deleted')` (forceDelete) message | `'The record was permanently deleted.'` |
| BC-BIZ-DEEP-30 | **OBSERVATION**: All activityLog calls lack `performed_by` | Inconsistent with reference |
| BC-BIZ-DEEP-31 | `trashed()` eagerly loads relations for display | `with(['marksheetType', 'examGroup', 'academicSession'])` |
| BC-BIZ-DEEP-32 | `trashed()` paginates at 15 | `ConfigTemplate::onlyTrashed()->with(...)->latest()->paginate(15)` |
| BC-BIZ-DEEP-33 | `restore()` uses `update` permission (not `restore`) | `Gate::authorize('tenant.msh-config-template.update')` |
| BC-BIZ-DEEP-34 | `forceDelete()` uses `delete` permission (not `forceDelete`) | `Gate::authorize('tenant.msh-config-template.delete')` |
| BC-BIZ-DEEP-35 | `show()`, `update()`, `destroy()` use route-model-binding | Resolved from URL |
| BC-BIZ-DEEP-36 | `toggleStatus()`, `restore()`, `forceDelete()` use manual `findOrFail($id)` | Scalar ID |
| BC-BIZ-DEEP-37 | `config-template` is in modal entities loop for extra routes | toggleStatus, trashed, restore, forceDelete generated | `web.php:49` |
| BC-BIZ-DEEP-38 | `config-template` also has full resource route | `Route::resource('config-template', ConfigTemplateController::class)` | `web.php:73-74` |
| BC-BIZ-DEEP-39 | `passing_percentage` cast to `decimal:2` in model | `protected $casts = ['passing_percentage' => 'decimal:2']` |
| BC-BIZ-DEEP-40 | `compartment_max_failures` cast to `integer` | `protected $casts = ['compartment_max_failures' => 'integer']` |
| BC-BIZ-DEEP-41 | `is_best_of_n_enabled`, `is_locked`, `is_active` all cast to `bool` | 3 boolean casts |
| BC-BIZ-DEEP-42 | `best_of_n_count` cast to `integer` | Integer cast |
| BC-BIZ-DEEP-43 | `$fillable` includes all 16 columns | All fields mass-assignable |
| BC-BIZ-DEEP-44 | `grading_schema_id` nullable in both DB and Request | Optional grading schema |
| BC-BIZ-DEEP-45 | `board_code` is purely informational — no business rules driven by it | Free text field |
| BC-BIZ-DEEP-46 | `is_locked` field exists but no unlock mechanism in CRUD | Once locked, can't be edited via standard controller |
| BC-BIZ-DEEP-47 | `description` max 500 chars in DDL vs Request | Both enforce 500 |
| BC-BIZ-DEEP-48 | `code` max 50 chars in DDL vs Request | Both enforce 50 |
| BC-BIZ-DEEP-49 | `name` max 150 chars in DDL vs Request | Both enforce 150 |
| BC-BIZ-DEEP-50 | `prepareForValidation()` casts 4 FK IDs to int | Ensures integer type before DB query |
| BC-BIZ-DEEP-51 | `prepareForValidation()` casts 3 booleans | `is_best_of_n_enabled`, `is_locked`, `is_active` |
| BC-BIZ-DEEP-52 | `ConfigTemplateRequest@authorize()` always returns true | Authorization in controller |
| BC-BIZ-DEEP-53 | `index()` paginates at 20 (standalone) | `ConfigTemplate::with(...)->latest()->paginate(20)` |
| BC-BIZ-DEEP-54 | `show()` does NOT load `classConfigs` or `examWeightages` | Only 6 relations: marksheetType, examGroup, academicSession, scholastic, ia, coscholastic |
| BC-BIZ-DEEP-55 | `show()` does NOT load `marksheetSchedules` | Schedule info on separate page |
| BC-BIZ-DEEP-56 | `edit()` does NOT load `scholasticComponents`, `iaComponents`, etc. | Only metadata + class assignments |
| BC-BIZ-DEEP-57 | Hub tab uses `.view` permission in blade | `@can('tenant.msh-config-template.view')` |
| BC-BIZ-DEEP-58 | `forceDelete()` catches only `23000` | Re-throws other exceptions |
| BC-BIZ-DEEP-59 | `restore()` sets `is_active = true` | `$record->update(['is_active' => true])` |
| BC-BIZ-DEEP-60 | `updated_by` null on create | Set only on update |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — ConfigTemplateController Lines 20-29 (Standalone)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 22 | `Gate::authorize('tenant.msh-config-template.viewAny')` | Authorization |
| 02 | 24-26 | `$configTemplates = ConfigTemplate::with(['marksheetType', 'examGroup', 'academicSession'])->latest()->paginate(20)` | Eager load, paginate 20 |
| 03 | 28 | `return view('marksheetgeneration::config-template.index', compact('configTemplates'))` | Standalone view |

#### CODE-TRACE-A: Hub `configuration()` — MarksheetGenerationController Lines 68-93

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 70 | `Gate::authorize('tenant.msh-configuration.view')` | Hub gate |
| 02 | 72-74 | Extract filters | Input |
| 03 | 77 | `$configTemplates = $this->applyFilters(ConfigTemplate::with(['marksheetType', 'examGroup', 'academicSession']), $tab === 'config-templates' ? $search : null, ..., ['name', 'code'])->paginate(15, ['*'], 'ct_page')` | Query with eager loads, conditional filters, page name ct_page |

#### CODE-TRACE-02: `create()` — Lines 31-47

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 33 | `Gate::authorize('tenant.msh-config-template.create')` | Authorization |
| 02 | 35-41 | `$marksheetTypes = MarksheetType::where('is_active', true)->orderBy('display_order')->get(); $examGroups = ExamGroup::where('is_active', true)->orderBy('name')->get(); $academicSessions = OrganizationAcademicSession::where('is_active', 1)->orderBy('name')->get(); $gradingSchemas = GradeDivisionMaster::where('is_active', true)->orderBy('display_order')->get(); $schoolClasses = SchoolClass::where('is_active', 1)->orderBy('name')->get(); $classGroups = ClassGroup::where('is_active', 1)->orderBy('name')->get(); $existingAssignments = collect()` | Load 7 reference collections for form dropdowns |
| 03 | 43-46 | `return view('marksheetgeneration::config-template.create', compact(...))` | Return standalone create form with all data |

#### CODE-TRACE-03: `store(ConfigTemplateRequest $request, ConfigTemplateService $service)` — Lines 49-62

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 51 | `Gate::authorize('tenant.msh-config-template.create')` | Authorization |
| 02 | 53 | `$configTemplate = $service->create($request->validated(), (int) auth()->id())` | Service creates template + syncs class assignments in transaction |
| 03 | 55-57 | `activityLog($configTemplate, 'Stored', ['message' => 'A new config template was created.'])` | Activity log |
| 04 | 59-61 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'config-templates'])->with('success', flash('created.config_template'))` | Redirect to hub with flash |

#### CODE-TRACE-04: `show(ConfigTemplate $configTemplate)` — Lines 64-71

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 66 | `Gate::authorize('tenant.msh-config-template.view')` | Authorization |
| 02 | 68 | `$configTemplate->load(['marksheetType', 'examGroup', 'academicSession', 'scholasticComponents', 'iaComponents', 'coscholasticComponents'])` | Eager load 6 relations for details page |
| 03 | 70 | `return view('marksheetgeneration::config-template.show', compact('configTemplate'))` | Return show view |

#### CODE-TRACE-05: `edit(ConfigTemplate $configTemplate)` — Lines 73-89

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 75 | `Gate::authorize('tenant.msh-config-template.update')` | Authorization |
| 02 | 77-83 | `$marksheetTypes = ...; $examGroups = ...; $academicSessions = ...; $gradingSchemas = ...; $schoolClasses = ...; $classGroups = ...; $existingAssignments = $configTemplate->classConfigs()->whereNull('deleted_at')->with(['schoolClass', 'classGroup'])->get()` | Load 7 collections same as create + existing assignments |
| 03 | 85-88 | `return view('marksheetgeneration::config-template.edit', compact('configTemplate', ..., 'existingAssignments'))` | Return edit form with pre-populated data |

#### CODE-TRACE-06: `update(ConfigTemplateRequest $request, ConfigTemplate $configTemplate, ConfigTemplateService $service)` — Lines 91-104

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 93 | `Gate::authorize('tenant.msh-config-template.update')` | Authorization |
| 02 | 95 | `$service->update($configTemplate, $request->validated(), (int) auth()->id())` | Service updates + re-syncs assignments |
| 03 | 97-99 | `activityLog($configTemplate, 'Updated', ['message' => 'The config template was updated.'])` | Activity |
| 04 | 101-103 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'config-templates'])->with('success', flash('updated.config_template'))` | Redirect |

#### CODE-TRACE-07: `toggleStatus($id)` — Lines 106-116

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 108 | `Gate::authorize('tenant.msh-config-template.update')` | Authorization |
| 02 | 110 | `$record = ConfigTemplate::findOrFail($id)` | Manual lookup |
| 03 | 111 | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | Toggle |
| 04 | 113 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Activity |
| 05 | 115 | `return response()->json(['success' => true, ...])` | JSON |

#### CODE-TRACE-08: `destroy(ConfigTemplate $configTemplate, ConfigTemplateService $service)` — Lines 118-131

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 120 | `Gate::authorize('tenant.msh-config-template.delete')` | Authorization |
| 02 | 122 | `$service->delete($configTemplate)` | Service soft-delete |
| 03 | 124-126 | `activityLog($configTemplate, 'Deleted', ['message' => 'The config template was deleted.'])` | Activity |
| 04 | 128-130 | `return redirect()->route(...['tab' => 'config-templates'])->with('success', flash('deleted.config_template'))` | Redirect |

#### CODE-TRACE-09: `trashed()` — Lines 133-140

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 135 | `Gate::authorize('tenant.msh-config-template.viewAny')` | Authorization |
| 02 | 137 | `$trashed = ConfigTemplate::onlyTrashed()->with(['marksheetType', 'examGroup', 'academicSession'])->latest()->paginate(15)` | Trashed with eager loads |
| 03 | 139 | `return view('marksheetgeneration::trashed.config-template', compact('trashed'))` | Trash view |

#### CODE-TRACE-10: `restore($id)` — Lines 142-153

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 144 | `Gate::authorize('tenant.msh-config-template.update')` | Authorization |
| 02 | 146 | `$record = ConfigTemplate::onlyTrashed()->findOrFail($id)` | Find trashed |
| 03 | 147 | `$record->restore()` | Restore |
| 04 | 148 | `$record->update(['is_active' => true])` | Activate |
| 05 | 150 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Activity |
| 06 | 152 | `return redirect()->route('marksheet-generation.config-template.trashed')->with('success', 'Record restored successfully.')` | Redirect |

#### CODE-TRACE-11: `forceDelete($id)` — Lines 155-171

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 157 | `Gate::authorize('tenant.msh-config-template.delete')` | Authorization |
| 02 | 159 | `$record = ConfigTemplate::withTrashed()->findOrFail($id)` | Find any |
| 03 | 160-168 | `try { $record->forceDelete(); activityLog(...); } catch (QueryException $e) { if (23000) error; throw; }` | FK-protected delete |
| 04 | 161-162 | `$record->forceDelete(); activityLog(...)` | Success |
| 05 | 164-165 | `return redirect()->back()->with('error', 'Cannot delete...')` | FK error |
| 06 | 170 | `return redirect()->route('marksheet-generation.config-template.trashed')->with('success', 'Record permanently deleted.')` | Success |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create template with all fields + class assignments | Full form with 2 class assignments | Created, junction rows inserted, flash |
| TC-P-02 | Create template minimum fields | Only required fields, no assignments | Created, empty junction |
| TC-P-03 | Create template with grading schema | Include grading_schema_id | Created with schema FK |
| TC-P-04 | Create template with best-of-N enabled | is_best_of_n_enabled=true, best_of_n_count=2 | Created with best-of settings |
| TC-P-05 | Edit template name/passing% | Change passing_percentage from 33 to 40 | Updated |
| TC-P-06 | Edit class assignments: add | Add 2 new class assignments | Junction rows added |
| TC-P-07 | Edit class assignments: remove | Remove 2 existing | Junction soft-deleted |
| TC-P-08 | Edit class assignments: clean slate | Change all assignments | Old deleted, new inserted |
| TC-P-09 | Toggle active→inactive | Click status switch | JSON response |
| TC-P-10 | Search by code | Partial code match | Filtered |
| TC-P-11 | Filter by active status | Select Active | Only active |
| TC-P-12 | Restore soft-deleted template | Delete → Trash → Restore | Restored, active |
| TC-P-13 | Force delete with no dependencies | No schedules/components | Permanently deleted |
| TC-P-14 | View template details | Click view | Show page with 6 relations |
| TC-P-15 | Create in different session with same code | Diff session, same code | Success (scoped unique) |
| TC-P-16 | Create template with compartment_max_failures=0 | Zero tolerance | Created |
| TC-P-17 | Create template with passing_percentage=0 | Zero percent | Created |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty academic_session_id | Missing | "The academic session field is required." |
| TC-N-02 | Create with empty marksheet_type_id | Missing | "The marksheet type field is required." |
| TC-N-03 | Create with empty exam_group_id | Missing | "The exam group field is required." |
| TC-N-04 | Create with empty code | Missing | "The code field is required." |
| TC-N-05 | Create with empty name | Missing | "The name field is required." |
| TC-N-06 | Create with duplicate code in same session | Same code | "The code has already been taken." |
| TC-N-07 | Create with passing_percentage=101 | > 100 | "The passing percentage must not be greater than 100." |
| TC-N-08 | Create with passing_percentage=-5 | < 0 | "The passing percentage must be at least 0." |
| TC-N-09 | Create with compartment_max_failures=256 | > 255 | "The compartment max failures must not be greater than 255." |
| TC-N-10 | Create with invalid marksheet_type_id | 99999 | "The selected marksheet type id is invalid." |
| TC-N-11 | Create with invalid exam_group_id | 99999 | "The selected exam group id is invalid." |
| TC-N-12 | Create with invalid grading_schema_id | 99999 | "The selected grading schema id is invalid." |
| TC-N-13 | Create with invalid class assignment type | type='section' | "Assignment type must be 'class' or 'group'." |
| TC-N-14 | Create with name > 150 chars | 151-char name | "The name must not be greater than 150 characters." |
| TC-N-15 | Create with code > 50 chars | 51-char code | "The code must not be greater than 50 characters." |
| TC-N-16 | Store without create permission | User lacks create | 403 |
| TC-N-17 | Update without update permission | User lacks update | 403 |
| TC-N-18 | Destroy without delete permission | User lacks delete | 403 |
| TC-N-19 | Toggle without update permission | User lacks update | 403 |
| TC-N-20 | Restore active (non-trashed) | Not in trash | 404 |
| TC-N-21 | Force delete with components/schedules | FK constraint | "Cannot delete... referenced by other records." |
| TC-N-22 | Toggle on non-existent ID | Missing record | 404 |
| TC-N-23 | Create with best_of_n_count=0 when enabled | 0 count | "The best of n count must be at least 1." |
| TC-N-24 | Create with description > 500 chars | 501-char desc | "The description must not be greater than 500 characters." |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Soft delete with components | Delete referenced template | Soft delete allowed |
| TC-D-02 | Force delete with schedules | Permanent delete | 23000 caught |
| TC-D-03 | Force delete with scholastic components | FK from template_scholastic_components | 23000 caught |
| TC-D-04 | Force delete with IA components | FK from template_ia_components | 23000 caught |
| TC-D-05 | Force delete with exam weightages | FK from template_exam_weightages | 23000 caught |
| TC-D-06 | Force delete with coscholastic components | FK from template_coscholastic_components | 23000 caught |
| TC-D-07 | Verify is_active=true after restore | Restore | is_active=1 |
| TC-D-08 | Duplicate code after soft-delete | Delete, recreate same code/session | Allowed |
| TC-D-09 | Verify DB composite unique | Raw SQL duplicate (session_id, code) | 23000 |
| TC-D-10 | Verify updated_by null on create | New record | updated_by null |
| TC-D-11 | Verify created_by set | New record | created_by = auth user |
| TC-D-12 | Verify class_config_jnt clean slate on update | Old rows soft-deleted, new inserted | Junction correctly updated |
| TC-D-13 | Verify passing_percentage stored as DECIMAL(5,2) | 33.5 stored as 33.50 | Exact decimal |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Gate in index() | `ConfigTemplateController.php:22` | `tenant.msh-config-template.viewAny` |
| TC-CR-02 | Gate in create() | `ConfigTemplateController.php:33` | `tenant.msh-config-template.create` |
| TC-CR-03 | Gate in store() | `ConfigTemplateController.php:51` | `tenant.msh-config-template.create` |
| TC-CR-04 | Gate in show() | `ConfigTemplateController.php:66` | `tenant.msh-config-template.view` |
| TC-CR-05 | Gate in edit() | `ConfigTemplateController.php:75` | `tenant.msh-config-template.update` |
| TC-CR-06 | Gate in update() | `ConfigTemplateController.php:93` | `tenant.msh-config-template.update` |
| TC-CR-07 | Gate in destroy() | `ConfigTemplateController.php:120` | `tenant.msh-config-template.delete` |
| TC-CR-08 | Gate in toggleStatus() | `ConfigTemplateController.php:108` | `tenant.msh-config-template.update` |
| TC-CR-09 | Gate in restore() | `ConfigTemplateController.php:144` | `tenant.msh-config-template.update` |
| TC-CR-10 | Gate in forceDelete() | `ConfigTemplateController.php:157` | `tenant.msh-config-template.delete` |
| TC-CR-11 | Gate in trashed() | `ConfigTemplateController.php:135` | `tenant.msh-config-template.viewAny` |
| TC-CR-12 | Service delegation in store() | `ConfigTemplateController.php:53` | `$service->create(...)` |
| TC-CR-13 | Service delegation in update() | `ConfigTemplateController.php:95` | `$service->update(...)` |
| TC-CR-14 | Service delegation in destroy() | `ConfigTemplateController.php:122` | `$service->delete(...)` |
| TC-CR-15 | syncClassAssignments logic | `ConfigTemplateService.php:43-78` | DB clean-slate upsert |
| TC-CR-16 | DB transaction in service | `ConfigTemplateService.php:10,24,38` | All wrapped |
| TC-CR-17 | Eager loads in create() | `ConfigTemplateController.php:35-41` | 6 filtered collections |
| TC-CR-18 | Eager loads in edit() | `ConfigTemplateController.php:77-83` | 6 + existingAssignments |
| TC-CR-19 | Eager loads in show() | `ConfigTemplateController.php:68` | `load([6 relations])` |
| TC-CR-20 | Eager loads in hub | `MarksheetGenerationController.php:77` | `with(['marksheetType', 'examGroup', 'academicSession'])` |
| TC-CR-21 | Trashed eager loads | `ConfigTemplateController.php:137` | `with([3 relations])` |
| TC-CR-22 | prepareForValidation | `ConfigTemplateRequest.php:50-61` | 4 int casts + 3 boolean |
| TC-CR-23 | Model casts | `ConfigTemplate.php:24-33` | 6 casts |
| TC-CR-24 | **OBS**: restore uses update permission | `ConfigTemplateController.php:144` | Should be `restore` |
| TC-CR-25 | **OBS**: forceDelete uses delete permission | `ConfigTemplateController.php:157` | Should be `forceDelete` |
| TC-CR-26 | **OBS**: activityLog lacks performed_by | All calls | Inconsistent |
| TC-CR-27 | Symmetrical @can in blade | `_config-templates.blade.php:45-50,59-66` | th/td matching |
| TC-CR-28 | Tab permission in blade | `configuration.blade.php:16` | `tenant.msh-config-template.view` |
| TC-CR-29 | Resource routes | `web.php:73-74` | Full resource |
| TC-CR-30 | Modal entity extra routes | `web.php:49` | config-template slug |

---

## 7. Detailed Test Steps

### TC-P-01: Create config template with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-config-template.create` permission | Success |
| 2 | Navigate to Configuration hub, click "Config Templates" tab | Tab active, list displayed |
| 3 | Click "Add Config Template" button | Create modal opens |
| 4 | Enter template_name="Half-Yearly Report", code="CFG-HY-2025" | Fields populated |
| 5 | Select marksheet_type_id (existing), exam_group_id (existing), class_group_id (existing) | 3 FK dropdowns selected |
| 6 | Select ia_component_type_id (existing) | 4th FK selected |
| 7 | Set is_active=Active, weightage_value=25 | Numeric + status |
| 8 | Click "Save" | AJAX POST to store |
| 9 | **Verify**: `Gate::authorize('tenant.msh-config-template.create')` passes | Authorized |
| 10 | **Verify**: `ConfigTemplateRequest` validation passes | No errors |
| 11 | **Verify**: `ConfigTemplate::create($request->validated())` inserts row in `msh_config_templates` | DB has template_name="Half-Yearly Report" |
| 12 | **Verify**: `activityLog()` with type "Stored" | Activity log entry |
| 13 | **Verify**: Modal closes, table refreshes | New row visible |
| 14 | **Verify**: Flash success message | "Config Template created successfully" |

### TC-P-02: Create config template with minimum fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create modal | Modal displayed |
| 2 | Enter template_name="Minimal", code="CFG-MIN" | Required fields |
| 3 | Select marksheet_type_id, exam_group_id, class_group_id | Required FKs |
| 4 | Leave ia_component_type_id unselected (nullable), weightage_value=null | Nullable fields omitted |
| 5 | Click "Save" | POST request |
| 6 | **Verify**: Validation passes | No errors |
| 7 | **Verify**: Record created with ia_component_type_id=null, weightage_value=null | DB row inserted |

### TC-P-03: Edit config template — change template_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-config-template.update` | Success |
| 2 | Click edit icon on existing config template | Edit modal with pre-filled data |
| 3 | **Verify**: `Gate::authorize('tenant.msh-config-template.update')` passes | Authorized |
| 4 | Change template_name to "Half-Yearly Report Updated" | Input updated |
| 5 | Click "Update" | PUT request |
| 6 | **Verify**: `$record->update($request->validated())` | DB updated |
| 7 | **Verify**: `$record->getChanges()` captures changed name | Change tracking |
| 8 | **Verify**: `activityLog()` with type "Updated" and `changes` array | Activity log entry |
| 9 | **Verify**: Flash success `flash('updated.msh-config-template')` | Confirmation |

### TC-P-04: Edit config template — change FK associations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Success |
| 2 | Edit config template, change marksheet_type_id and exam_group_id to different values | Both FKs changed |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: Both FK columns updated in DB | Associations changed |
| 5 | **Verify**: Change tracking records old/new for both FKs | Full audit trail |

### TC-P-05: Edit config template — change weightage_value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Success |
| 2 | Edit config template, change weightage_value from 25 to 30 | Value updated |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: weightage_value=30 in DB | Numeric updated |
| 5 | **Verify**: Change tracking captures weightage_value delta | Old=25, New=30 |

### TC-P-06: Toggle config template active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-config-template.update` | Success |
| 2 | Find active config template toggle | Toggle ON (green) |
| 3 | Click status toggle | AJAX POST |
| 4 | **Verify**: `$record->is_active = false`, `$record->save()` | DB updated |
| 5 | **Verify**: JSON `{success: true, is_active: false}` | Toggle OFF |

### TC-P-07: Toggle config template inactive→active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find inactive config template | is_active=0 |
| 2 | Click status toggle | AJAX POST |
| 3 | **Verify**: `$request->boolean('is_active')` = true | Set active |
| 4 | **Verify**: JSON `{success: true, is_active: true}` | Toggle ON |

### TC-P-08: View config template details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-config-template.view` | Success |
| 2 | Click view icon on a config template row | Show modal opens |
| 3 | **Verify**: All fields displayed: template_name, code, marksheet_type_id, exam_group_id, class_group_id, ia_component_type_id, weightage_value, is_active | All data visible |
| 4 | **Verify**: FK fields resolve to related model names | Related data shown |

### TC-P-09: Search config template by template_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-config-template.viewAny` | Success |
| 2 | Search "Half-Yearly" | GET with `?search=Half-Yearly` |
| 3 | **Verify**: `->where('template_name','like','%Half-Yearly%')->orWhere('code','like','%Half-Yearly%')` | Filtered |
| 4 | **Verify**: Only matching templates displayed | Filtered results |

### TC-P-10: Search config template by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "CFG-2025" | Filter by code |
| 2 | **Verify**: Matching by code column | Result filtered |

### TC-P-11: Filter config template by status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status filter | `status=1` |
| 2 | Submit | Only active displayed |
| 3 | Change to "Inactive" | Only inactive displayed |

### TC-P-12: Filter config template by marksheet_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific marksheet_type_id filter | FK filter applied |
| 2 | Submit | Only templates for that type shown |

### TC-P-13: Soft-delete config template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-config-template.delete` | Success |
| 2 | Click delete icon on a template row | Confirm dialog |
| 3 | Confirm deletion | DELETE request |
| 4 | **Verify**: `is_active=false → save() → delete()` | Soft-delete |
| 5 | **Verify**: DB: `is_active=0`, `deleted_at` IS NOT NULL | Trashed |
| 6 | **Verify**: `activityLog()` with type "Trashed" | Entry created |

### TC-P-14: Restore soft-deleted config template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-config-template.restore` | Success |
| 2 | Navigate to trash listing | Trashed records |
| 3 | Click "Restore" on trashed template | Restore action |
| 4 | **Verify**: `onlyTrashed()->findOrFail($id)` | Record found |
| 5 | **Verify**: `$record->restore()` → `deleted_at = NULL` | Restored |
| 6 | **Verify**: `$record->update(['is_active' => true])` | Also set active |

### TC-P-15: Force delete trashed config template (no dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-config-template.forceDelete` | Success |
| 2 | Click "Force Delete" on trashed template with NO dependents | Force delete |
| 3 | **Verify**: `withTrashed()->findOrFail($id)` | Record found |
| 4 | **Verify**: `$record->forceDelete()` | Permanently deleted |
| 5 | **Verify**: `activityLog()` with type "Deleted" | Log entry |

### TC-N-01: Create with empty template_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave template_name EMPTY | Required field omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required` rule | "The template name field is required." |

### TC-N-02: Create with empty code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave code EMPTY | Required field omitted |
| 2 | **Verify**: `required` rule on `code` | "The code field is required." |

### TC-N-03: Create with duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | "CFG-HY-2025" exists | Existing |
| 2 | Create new with same code | Duplicate |
| 3 | **Verify**: `Rule::unique('msh_config_templates', 'code')` | "already been taken." |

### TC-N-04: Create without marksheet_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave marksheet_type_id unselected | Required FK omitted |
| 2 | **Verify**: `required|integer|exists:msh_marksheet_types,id` | Field required error |

### TC-N-05: Create without exam_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave exam_group_id unselected | Required FK omitted |
| 2 | **Verify**: `required|integer|exists:msh_exam_groups,id` | Field required error |

### TC-N-06: Create without class_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave class_group_id unselected | Required FK omitted |
| 2 | **Verify**: `required|integer|exists:msh_class_groups,id` | Field required error |

### TC-N-07: Create with non-existent marksheet_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with marksheet_type_id=99999 | Invalid FK |
| 2 | **Verify**: `exists:msh_marksheet_types,id` | "The selected marksheet type id is invalid." |

### TC-N-08: Create with non-existent exam_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with exam_group_id=99999 | Invalid FK |
| 2 | **Verify**: `exists:msh_exam_groups,id` | "The selected exam group id is invalid." |

### TC-N-09: Create with non-existent class_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with class_group_id=99999 | Invalid FK |
| 2 | **Verify**: `exists:msh_class_groups,id` | "The selected class group id is invalid." |

### TC-N-10: Create with non-existent ia_component_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with ia_component_type_id=99999 | Invalid FK |
| 2 | **Verify**: `exists:msh_ia_component_types,id` | "The selected ia component type id is invalid." |

### TC-N-11: template_name exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter template_name = 256 chars (exceeds max:255) | Over limit |
| 2 | **Verify**: Rule `max:255` | "must not be greater than 255 characters." |

### TC-N-12: Code exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter code = 101 chars (exceeds max:100) | Over limit |
| 2 | **Verify**: Rule `max:100` | Validation error |

### TC-N-13: weightage_value not numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter weightage_value="abc" | Non-numeric |
| 2 | **Verify**: `nullable|numeric` rule | "The weightage value must be a number." |

### TC-N-14: Tab hidden without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-config-template.view` | No view |
| 2 | **Verify**: Config Templates tab hidden | Tab not displayed |

### TC-N-15: Direct store without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST valid data without create | Direct POST |
| 2 | **Verify**: `Gate::authorize(...)` throws 403 | Forbidden |

### TC-N-16: Direct update without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT without update | Direct PUT |
| 2 | **Verify**: 403 | Access denied |

### TC-N-17: Direct delete without delete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE without delete | Direct DELETE |
| 2 | **Verify**: 403 | Forbidden |

### TC-N-18: Restore non-trashed active record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active config template | Active |
| 2 | Call restore route | Restore |
| 3 | **Verify**: `onlyTrashed()->findOrFail($id)` → 404 | Not found |

### TC-N-19: Toggle with invalid boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `is_active=2` | Invalid boolean |
| 2 | **Verify**: `required|boolean` validation | "must be true or false." |

### TC-N-20: Toggle without is_active param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST without is_active | Missing param |
| 2 | **Verify**: `required` | Field required |

### TC-D-01: Force delete config template with dependent records (last FK level)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config template "CFG-DEP" | Parent |
| 2 | Create dependent records referencing config_template_id | Dependent data |
| 3 | Soft-delete CFG-DEP | Trashed |
| 4 | Attempt force delete | Force delete |
| 5 | **Verify**: FK constraint with downstream tables | QueryException 23000 |
| 6 | **Verify**: Catch block handles gracefully | User-friendly error |

### TC-D-02: Duplicate code after force-delete re-use

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "UNIQUE-CFG", force-delete | Removed |
| 2 | Re-create with same code | Unique re-use allowed |

### TC-D-03: `is_active=false` before soft-delete sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active: is_active=1 | Active |
| 2 | Destroy | Soft-delete |
| 3 | DB: `is_active=0`, `deleted_at` IS NOT NULL | Deactivated first |

### TC-D-04: Toggle after soft-delete (not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete config template | Trashed |
| 2 | POST to toggleStatus | AJAX |
| 3 | **Verify**: `findOrFail($id)` → 404 | Cannot toggle |

### TC-D-05: Update after soft-delete (not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete config template | Trashed |
| 2 | PUT update | Direct |
| 3 | **Verify**: `findOrFail($id)` → 404 | Cannot update |

### TC-D-06: Marksheet type FK from config template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create marksheet type "MT-DEP" | Parent |
| 2 | Create config templates referencing MT-DEP | Multiple dependents |
| 3 | Attempt force delete MT-DEP | FK violation from config templates |
| 4 | **Verify**: QueryException 23000 | Cannot delete parent with children |

### TC-CR-01: Verify Gate::authorize in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:31` | `Gate::authorize('tenant.msh-config-template.create')` |
| 2 | Verify string | Consistent |

### TC-CR-02: Verify Gate::authorize in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:76` | `Gate::authorize('tenant.msh-config-template.update')` |
| 2 | Verify | OK |

### TC-CR-03: Verify Gate::authorize in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:95` | `Gate::authorize('tenant.msh-config-template.delete')` |
| 2 | Verify | OK |

### TC-CR-04: Verify Gate::authorize anomaly in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:144` | `Gate::authorize('tenant.msh-config-template.update')` |
| 2 | **OBSERVATION**: Uses `update` instead of `restore` | Wrong permission |

### TC-CR-05: Verify Gate::authorize anomaly in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:157` | `Gate::authorize('tenant.msh-config-template.delete')` |
| 2 | **OBSERVATION**: Uses `delete` instead of `forceDelete` | Wrong permission |

### TC-CR-06: Verify activityLog missing performed_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check all 6 activityLog calls | `performed_by` key MISSING in all |
| 2 | Compare with reference pattern | Inconsistent |

### TC-CR-07: Verify $request->validated() usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check store() line 33 | `ConfigTemplate::create($request->validated())` |
| 2 | Check update() line 79 | `$record->update($request->validated())` |
| 3 | **Result**: Proper validated data used | No raw input |

### TC-CR-08: Verify ConfigTemplateRequest rules for all 4 FKs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateRequest.php:18-24` | `marksheet_type_id => required|integer|exists:msh_marksheet_types,id` |
| 2 | Verify all FK exists rules | marksheet_types, exam_groups, class_groups, ia_component_types |
| 3 | **Observation**: ia_component_type_id is `nullable` | Only nullable FK |

### TC-CR-09: Verify restore() sets is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:148` | `$record->update(['is_active' => true])` |
| 2 | **Observation**: Differs from other 4 entities (which do NOT set is_active on restore) | Unique behavior |

### TC-CR-10: Verify model casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplate.php:24-33` | `is_active => boolean, weightage_value => decimal:2, ...` |
| 2 | Verify all 6 casts | Proper typing |

### TC-CR-11: Verify $fillable matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplate.php:10-22` | All fillable fields |
| 2 | Cross-check migration | Match |

### TC-CR-12: Verify `@can` symmetry in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `_config-templates.blade.php:45-50,59-66` | th/td matching `@can` wrappers |
| 2 | Verify `@canany` closed with `@endcanany` | Proper |

### TC-CR-13: Verify tab permission in configuration.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `configuration.blade.php:16` | `'permission' => 'tenant.msh-config-template.view'` |
| 2 | Verify double-layer security | Proper |

### TC-CR-14: Verify resource routes in web.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php:73-74` | `Route::resource('config-template', ConfigTemplateController::class)` |
| 2 | Verify extra routes | 4 extra routes present |

### TC-CR-15: Verify `forceDelete()` catches QueryException 23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:159-163` | `try { forceDelete() } catch (\Exception $e) { if($e->getCode() == '23000') ... }` |
| 2 | Verify catch block redirects | Graceful error handling |

### TC-CR-16: Verify `edit()` redirects to hub with tab param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:68` | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'config-templates'])` |
| 2 | Verify tab matches blade | `config-templates` tab |

### TC-CR-17: Verify `show()` uses `findOrFail()` manual lookup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:55` | `ConfigTemplate::findOrFail($id)` |
| 2 | Verify | Explicit find |

### TC-CR-18: Verify `destroy()` 3-step sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:97-100` | `$record->is_active = false; $record->save(); $record->delete()` |
| 2 | Verify order | Deactivate → save → soft-delete |

### TC-CR-19: Verify `restore()` DOES set `is_active=true` (UNIQUE behavior)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:148` | `$record->update(['is_active' => true])` AFTER restore |
| 2 | Compare with other 4 entities which DON'T set is_active | **Unique**: ConfigTemplate actively reactivates |

### TC-CR-20: Verify `toggleStatus()` inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:115-116` | `$request->validate(['is_active' => 'required|boolean'])` |
| 2 | Verify | Inline validation |

### TC-CR-21: Verify `_config-templates.blade.php` status column symmetry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade: th (line 45-50) and td (line 59-66) | Both wrapped in `@can('tenant.msh-config-template.update')` |
| 2 | Verify matching | Symmetrical guards |

### TC-CR-22: Verify `@canany` action column closed with `@endcanany`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade action column section | `@canany(['...view','...update','...delete']) ... @endcanany` |
| 2 | Verify NOT `@endcan` | Proper closing |

### TC-CR-23: Verify `trashed()` pagination = 15

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:127` | `onlyTrashed()->latest()->paginate(15)` |
| 2 | Verify paginator | 15 per page |

### TC-CR-24: Verify `ConfigTemplateRequest` has nullable ia_component_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateRequest.php:23` | `'ia_component_type_id' => 'nullable|integer|exists:msh_ia_component_types,id'` |
| 2 | Verify nullable | Only nullable FK among the 4 |

### TC-CR-25: Verify `configuration()` passes all 5 compact variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetGenerationController.php:90` | `compact('marksheetTypes', 'examGroups', 'classGroups', 'iaComponentTypes', 'configTemplates')` |
| 2 | Verify all 5 entity vars | Complete hub data |

### TC-P-16: Create config template with weightage_value=0.50 (decimal)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open create modal, template_name="Weighted Template", code="CFG-WT" | Form |
| 3 | Set weightage_value=0.50 | Decimal value |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: weightage_value=0.50 stored as decimal | Decimal precision preserved |

### TC-P-17: Filter config templates by marksheet_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Config Templates tab | Filters available |
| 2 | Select specific marksheet_type_id | FK filter |
| 3 | Submit | Only templates for that type |

### TC-N-21: Create with all 4 FKs referencing non-existent IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with marksheet_type_id=99999, exam_group_id=99999, class_group_id=99999 | All invalid FKs |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: All 4 exists rules fail | 4 validation errors |
| 4 | **Verify**: No record created | DB unchanged |

### TC-N-22: XSS in template_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with template_name = `<script>alert(1)</script>` | XSS |
| 2 | **Verify**: `{{ }}` escaping | Safe render |

### TC-D-07: Concurrent double-click status toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly click toggle twice | Two AJAX POSTs |
| 2 | **Verify**: Last request wins | Race condition |

### TC-D-08: Stale edit mid-air collision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Two users edit same config template simultaneously | Both read same |
| 2 | User A saves, User B saves | B's data overwrites A's |
| 3 | **Verify**: No optimistic locking | Last-write-wins |

### TC-D-09: CSRF token expiry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Session expires, submit form | Stale CSRF token |
| 2 | **Verify**: 419 Page Expired | Token mismatch |

### TC-D-10: Activity log after force-delete (orphan)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete config template | Permanently removed |
| 2 | Query activity_log for "Deleted" type | Log entry persists |

### TC-P-17: Verify show page renders all 4 FK relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show for config template | Detail page with all 4 FK names loaded |
| 2 | **Verify**: marksheet_type.name rendered via $record->marksheetType->name | Relation name shown |
| 3 | **Verify**: exam_group.name, class_group.name, academic_session.name | All 4 FK relations render |

### TC-P-18: Edit config template — toggle is_active off

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit page for active config template | Form pre-filled |
| 2 | Uncheck is_active status switch | is_active=false |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: is_active changed to 0 | Status shown as inactive |
| 5 | **Verify**: activityLog("Updated") records changes | Changes array includes is_active |

### TC-P-19: Redirect back to hub tab after create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config template | Store success |
| 2 | **Verify**: redirect route = `marksheet-generation.configuration` (NOT .index) | Redirect to hub |
| 3 | **Verify**: ?tab=config-templates is appended | Tab preserved |

### TC-P-20: Verify all 4 blade views exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `Modules/MarksheetGeneration/resources/views/config-template/` | 4 blade files |
| 2 | **Verify**: `index.blade.php` (tab partial) | Tab-pane partial |
| 3 | **Verify**: `create.blade.php`, `edit.blade.php`, `show.blade.php` | Create/Edit/Show standalone |

### TC-N-23: Create with is_active as non-boolean string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST is_active="yes" instead of boolean | Invalid type |
| 2 | **Verify**: `boolean` validation fails | Field error |

### TC-N-24: SQL injection in search field (index tab)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter search = `1 OR 1=1` | Attempted injection |
| 2 | **Verify**: `like "%...%"` treats as literal string | Safe binding |

### TC-N-25: Modify hidden template_id in POST during create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open browser dev tools, add hidden input template_id=5 | Tampered POST |
| 2 | **Verify**: template_id NOT in `$fillable` | Silently ignored |

### TC-D-11: Verify `show()` gates correctly with `view`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:56` | `Gate::authorize('tenant.msh-config-template.view')` |
| 2 | Verify `view` (not `viewAny`) used | Correct permission |

### TC-D-12: `trashed()` uses `restore` permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:86` | `Gate::authorize('tenant.msh-config-template.restore')` |
| 2 | Verify `restore` used for trash page | Prevents non-restorers from seeing trash |

### BC-BIZ-DEEP-60: `academic_session_id` filter is client-side only

| # | Condition | Expected Behavior |
|---|-----------|------------------|
| BC-BIZ-DEEP-60 | Tab partial blade filters academic_session_id in JS/hidden — no server-side applyFilters() for it | Filter purely client-side |
| BC-BIZ-DEEP-61 | ConfigTemplate show/edit/create pages are standalone (not modals) — each has own full-page layout | Standalone routes |
| BC-BIZ-DEEP-62 | `config_template_id` in marksheet_schedules is NOT required (nullable FK) | Schedule can exist without template |
| BC-BIZ-DEEP-63 | No `factory()` or `seeder` for ConfigTemplate — seed via direct DB or UI only | No Factory class exists |
| BC-BIZ-DEEP-64 | `Flash key` — `flash('created.config_template')` must exist in lang files | Verify in flash.php |
| BC-BIZ-DEEP-65 | `destroy()` does NOT set is_active=false before delete | Only `$record->delete()` called |
| BC-BIZ-DEEP-66 | `forceDelete()` catch block re-throws if code !== '23000' | Non-FK errors bubble up |
| BC-BIZ-DEEP-67 | `update()` change tracking excludes `deleted_at` if called (edge case) | Filtered in changes loop |
| BC-BIZ-DEEP-68 | Show page `@can('...update')` wraps Edit button ONLY | Edit guarded, delete NOT on show |

### CODE-TRACE-HUB: `configTemplatesQuery()` — MarksheetGenerationController Private Method

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | ~210 | `private function configTemplatesQuery(Request $request): Builder` | Private query helper for config-templates hub tab |
| 02 | ~211 | `$query = ConfigTemplate::with(['marksheetType', 'examGroup', 'classGroup', 'academicSession'])` | Eager load all 4 FKs |
| 03 | ~213 | `if ($request->input('tab') === 'config-templates')` | Only apply filters when tab active |
| 04 | ~214 | `->when($request->filled('search'), fn ($q) => $q->where('template_name', 'like', "%{$request->search}%"))` | Search on template_name |
| 05 | ~215 | `->when($request->filled('status'), fn ($q) => $q->where('is_active', (bool) $request->status))` | Status filter |
| 06 | ~217 | `return $query->latest()` | Always order by latest |
| 07 | Hub | `paginate(15, ['*'], 'config_templates_page')` | Unique paginator for this tab |

### TC-CR-33: Verify `edit()` passes `$record` to view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateController.php:60-64` | `$record = ConfigTemplate::findOrFail($id); return view('...edit', compact('record'))` |
| 2 | Verify uses `$record` not `$configTemplate` | Consistent variable name |

### TC-CR-34: Verify `marksheet_type_id` exists rule references correct table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ConfigTemplateRequest.php` | `'marksheet_type_id' => 'required|integer|exists:msh_marksheet_types,id'` |
| 2 | Verify all 4 exists rules | All reference correct tables |
