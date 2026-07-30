# Exam Groups — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Exam Group (`msh_exam_groups`) |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\ExamGroupController` — 10 methods (index, create, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete) — ⚠️ `index()` NOT used in hub; listing via `MarksheetGenerationController::configuration()` |
| **Tab Container Controller** | `MarksheetGenerationController::configuration()` — tab id `exam-groups`, private `applyFilters()` helper for listing |
| **Model** | `Modules\MarksheetGeneration\Models\ExamGroup` — SoftDeletes, 5 relationships |
| **Form Request** | `Modules\MarksheetGeneration\Http\Requests\ExamGroupRequest` — 9 validation rules + `prepareForValidation` |
| **Service** | `Modules\MarksheetGeneration\Services\ExamGroupService` — `create()`, `update()`, `delete()` with DB transaction + `syncItems()` for junction table |
| **Policy** | `ExamGroupPolicy` — 8 permission methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |
| **Route Prefix** | `marksheet-generation.exam-group.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus` via modal entities loop |
| **Blade Views** | `_exam-groups.blade.php` (tab partial), `modals/exam-group-create.blade.php`, `modals/exam-group-edit.blade.php`, `trashed/exam-group.blade.php` |
| **Tab Container** | `pages/configuration.blade.php` — tab id `exam-groups`, permission `tenant.msh-exam-group.view` |
| **DB Table** | `msh_exam_groups` — 11 data columns + 3 timestamp columns; junction table `msh_exam_group_items_jnt` |
| **Primary Screen** | Marksheet Generation → Configuration → Exam Groups tab (paginated, searchable, status-filtered, modal CRUD with junction sync) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as Examination Coordinator (or role with `tenant.msh-exam-group.*` permissions) |
| PC-02 | Database `msh_exam_groups` table must exist with all 11 data columns |
| PC-03 | `msh_exam_group_items_jnt` junction table must exist for exam type linkage |
| PC-04 | `sch_org_academic_sessions_jnt` table must have at least one active academic session |
| PC-05 | `lms_exam_types` table must have at least one active exam type for junction selection |
| PC-06 | `msh_config_templates` table must exist with FK `exam_group_id` referencing `msh_exam_groups.id` |
| PC-07 | `ExamGroupController` must be registered in module routes with resource + extra routes |
| PC-08 | `ExamGroupPolicy` must be registered in `AuthServiceProvider` |
| PC-09 | Exam Groups tab must be included in `configuration.blade.php` with `@can('tenant.msh-exam-group.view')` guard |
| PC-10 | Soft deletes must be enabled on both `msh_exam_groups` and `msh_exam_group_items_jnt` |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load exam groups with pagination (15 per page) via `configuration() → applyFilters()` | `MarksheetGenerationController.php:79` — `ExamGroup::with(['academicSession', 'items'])->...->paginate(15, ['*'], 'eg_page')` |
| DL-02 | Eager loads `academicSession` and `items` (junction records) for each exam group | `MarksheetGenerationController.php:79` — `ExamGroup::with(['academicSession', 'items'])` |
| DL-03 | Search filters: `?search=` (Code, Name) and `?status=` only when tab is `exam-groups` | `MarksheetGenerationController.php:79` — `$tab === 'exam-groups'` conditional |
| DL-04 | Tab partial loads via `@include('marksheetgeneration::pages.partials.configuration._exam-groups')` inside `@can('tenant.msh-exam-group.view')` | `configuration.blade.php:21-23` |
| DL-05 | List columns displayed: **#**, **Code**, **Name**, **Start Date**, **End Date**, **Status**, **Actions** | `_exam-groups.blade.php:38-49` |
| DL-06 | Start/End dates displayed as raw date values | `_exam-groups.blade.php:58-59` — `{{ $row->start_date }}` and `{{ $row->end_date }}` |
| DL-07 | Status column uses `<x-backend.table.status-switch>` component | `_exam-groups.blade.php:62` |
| DL-08 | Action column uses `<x-backend.table.action>` with `editOnclick` JS function `editExamGroup()` | `_exam-groups.blade.php:67-69` |
| DL-09 | Edit modal receives `selectedTypeIds` (JSON array of exam_type_ids) for pre-selecting exam types | `_exam-groups.blade.php:65-66` — `$selectedTypeIds = $row->items->pluck('exam_type_id')` |
| DL-10 | Pagination links appended with all current query parameters via `->appends(request()->query())` | `_exam-groups.blade.php:75` |
| DL-11 | Shared dropdowns: `$currentAcademicSession`, `$lmsExamTypes`, `$schoolClasses`, `$marksheetTypesList`, `$examGroupsList` | `MarksheetGenerationController.php:82-86` |
| DL-12 | Empty state: "No Exam Groups Found" with icon, title, and subtitle | `_exam-groups.blade.php:23-31` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Exam Group** | `academic_session_id=1`, `code='TERM1_EXAMS'`, `name='Term-1 Exams'`, `start_date='2026-04-01'`, `end_date='2026-09-30'`, `exam_type_ids=[5,7,9]`, `is_active=true` |
| TD-02 | **Duplicate Code in Same Session** | Create second exam group with same `code='TERM1_EXAMS'` in session_id=1 — expects unique within session violation |
| TD-03 | **Duplicate Code in Different Session** | Create same `code='TERM1_EXAMS'` in session_id=2 — should succeed |
| TD-04 | **End Date Before Start Date** | `start_date='2026-09-01'`, `end_date='2026-03-01'` — expects `after_or_equal:start_date` failure |
| TD-05 | **Invalid Academic Session ID** | `academic_session_id=99999` — expects `exists:sch_org_academic_sessions_jnt,id` failure |
| TD-06 | **Invalid Exam Type ID** | `exam_type_ids=[99999]` — expects `exists:lms_exam_types,id` failure |
| TD-07 | **Missing Required Fields** | Submit without `academic_session_id`, `code`, `name` — expects validation failures |
| TD-08 | **Code Exceeds Max Length** | `code` = 31 chars — expects `max:30` failure |
| TD-09 | **Soft-Deleted Code Reuse in Same Session** | Delete exam group, create new with same code in same session — should succeed (unique ignores soft-deleted) |
| TD-10 | **Junction Sync: Add Exam Types** | Edit group, add 2 new exam types — junction table updated with new rows |
| TD-11 | **Junction Sync: Remove Exam Types** | Edit group, remove 2 existing exam types — junction rows soft-deleted |
| TD-12 | **Junction Sync: Re-add Removed Types** | Remove type then re-add — previously soft-deleted row restored |
| TD-13 | **Force Delete Referenced Exam Group** | Create group, create Config Template referencing it, force-delete — expects `QueryException 23000` catch |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `id` — INT PK, AUTO_INCREMENT | Primary key | DDL: `msh_exam_groups` |
| BC-DB-02 | `academic_session_id` — SMALLINT UNSIGNED, NOT NULL, FK → `sch_org_academic_sessions_jnt.id` | Required session reference | DDL: `msh_exam_groups` |
| BC-DB-03 | `code` — VARCHAR(30), NOT NULL | Max 30 chars, no nulls | DDL: `msh_exam_groups` |
| BC-DB-04 | Composite UNIQUE on (`academic_session_id`, `code`) | Unique within session | DDL: `msh_exam_groups` |
| BC-DB-05 | `name` — VARCHAR(100), NOT NULL | Max 100 chars | DDL: `msh_exam_groups` |
| BC-DB-06 | `description` — TEXT, NULLABLE | Nullable free-text | DDL: `msh_exam_groups` |
| BC-DB-07 | `start_date` — DATE, NULLABLE | Nullable date | DDL: `msh_exam_groups` |
| BC-DB-08 | `end_date` — DATE, NULLABLE | Nullable date | DDL: `msh_exam_groups` |
| BC-DB-09 | `is_active` — TINYINT(1), DEFAULT 1 | Boolean flag | DDL: `msh_exam_groups` |
| BC-DB-10 | `created_by` — INT, NOT NULL, FK → `sys_users.id` | Required user | DDL: `msh_exam_groups` |
| BC-DB-11 | `updated_by` — INT, NULLABLE, FK → `sys_users.id` | Nullable user | DDL: `msh_exam_groups` |
| BC-DB-12 | `msh_exam_group_items_jnt` junction: `exam_group_id` FK, `exam_type_id` FK, `display_order`, `is_active`, `created_by`, `updated_by`, `deleted_at` | Junction table with soft delete | DDL: `msh_exam_group_items_jnt` |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `academic_session_id` — required, integer, exists | `required\|integer\|exists:sch_org_academic_sessions_jnt,id` | `ExamGroupRequest.php:17-22` |
| BC-VAL-02 | `code` — required, string, max:30, unique within session | `required\|string\|max:30\|Rule::unique(...)->where(academic_session_id)` | `ExamGroupRequest.php:24-31` |
| BC-VAL-03 | `name` — required, string, max:100 | `required\|string\|max:100` | `ExamGroupRequest.php:32` |
| BC-VAL-04 | `description` — nullable, string, max:255 | `nullable\|string\|max:255` | `ExamGroupRequest.php:33` |
| BC-VAL-05 | `start_date` — nullable, date | `nullable\|date` | `ExamGroupRequest.php:34` |
| BC-VAL-06 | `end_date` — nullable, date, after_or_equal:start_date | `nullable\|date\|after_or_equal:start_date` | `ExamGroupRequest.php:35` |
| BC-VAL-07 | `is_active` — sometimes, boolean | `sometimes\|boolean` | `ExamGroupRequest.php:36` |
| BC-VAL-08 | `exam_type_ids` — nullable, array | `nullable\|array` | `ExamGroupRequest.php:37` |
| BC-VAL-09 | `exam_type_ids.*` — integer, exists | `integer\|exists:lms_exam_types,id` | `ExamGroupRequest.php:38` |
| BC-VAL-10 | `prepareForValidation()` normalizes `academic_session_id` to int | `(int) $this->input('academic_session_id')` | `ExamGroupRequest.php:43` |
| BC-VAL-11 | `prepareForValidation()` normalizes `is_active` to boolean | `$this->boolean('is_active')` | `ExamGroupRequest.php:44` |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.msh-exam-group.viewAny` | Hub: via `configuration()` hub gate; Standalone: `Gate::authorize('tenant.msh-exam-group.viewAny')` in `index()` | `viewAny()` | `ExamGroupController.php:16` |
| BC-AUTH-02 | `tenant.msh-exam-group.view` | Tab: `@can('tenant.msh-exam-group.view')`; Show: `Gate::authorize('tenant.msh-exam-group.view')` in `show()` | `view()` | `configuration.blade.php:13`, `ExamGroupController.php:57` |
| BC-AUTH-03 | `tenant.msh-exam-group.create` | `Gate::authorize('tenant.msh-exam-group.create')` in `store()` | `create()` | `ExamGroupController.php:32` |
| BC-AUTH-04 | `tenant.msh-exam-group.update` | `Gate::authorize('tenant.msh-exam-group.update')` in `edit()`, `update()`, `toggleStatus()`, `restore()` | `update()` | `ExamGroupController.php:66,73,113,134` |
| BC-AUTH-05 | `tenant.msh-exam-group.delete` | `Gate::authorize('tenant.msh-exam-group.delete')` in `destroy()`, `forceDelete()` | `delete()` | `ExamGroupController.php:98,147` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Code must be unique within the same academic session | Composite unique on (`academic_session_id`, `code`) + scoped unique rule | `ExamGroupRequest.php:24-31` |
| BC-BIZ-02 | `store()` delegates to `ExamGroupService::create()` which extracts `exam_type_ids` and calls `syncItems()` | Service handles junction sync within transaction | `ExamGroupService.php:14-24` |
| BC-BIZ-03 | `update()` delegates to `ExamGroupService::update()` which re-syncs junction items | Delta sync: soft-deletes removed items, upserts current | `ExamGroupService.php:28-40` |
| BC-BIZ-04 | `destroy()` delegates to `ExamGroupService::delete()` which soft-deletes | `$model->delete()` within transaction | `ExamGroupService.php:44` |
| BC-BIZ-05 | `syncItems()` soft-deletes junction rows not in selected IDs | `DB::table('msh_exam_group_items_jnt')->whereNotIn('exam_type_id', $examTypeIds)->update(['deleted_at' => $now])` | `ExamGroupService.php:50-53` |
| BC-BIZ-06 | `syncItems()` restores previously soft-deleted junction rows | If `$existing`, updates `deleted_at = null` | `ExamGroupService.php:59-67` |
| BC-BIZ-07 | `syncItems()` inserts new junction rows for new exam types | `DB::table('msh_exam_group_items_jnt')->insert(...)` | `ExamGroupService.php:68-77` |
| BC-BIZ-08 | `syncItems()` sets `display_order` as sequential index | `$index + 1` based on array position | `ExamGroupService.php:63` |
| BC-BIZ-09 | `toggleStatus()` inverts `is_active` and sets `updated_by` | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | `ExamGroupController.php:116` |
| BC-BIZ-10 | `forceDelete()` catches `QueryException 23000` for FK violations | Returns user-friendly error | `ExamGroupController.php:153-155` |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | ExamGroup → OrgAcademicSession | `belongsTo(academicSession)` via `academic_session_id` | `ExamGroup.php:30` |
| BC-REL-02 | ExamGroup → ExamGroupItem | `hasMany(items)` via `exam_group_id` | `ExamGroup.php:42` |
| BC-REL-03 | ExamGroup → ConfigTemplate | `hasMany(configTemplates)` via `exam_group_id` | `ExamGroup.php:46` |
| BC-REL-04 | ExamGroup → User (created_by) | `belongsTo(createdBy)` | `ExamGroup.php:34` |
| BC-REL-05 | ExamGroup → User (updated_by) | `belongsTo(updatedBy)` | `ExamGroup.php:38` |
| BC-REL-06 | ExamGroupItem → ExamType | `belongsTo(examType)` via `exam_type_id` | `ExamGroupItem.php:28` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab loads with `@can('tenant.msh-exam-group.view')` guard | Tab conditional | `configuration.blade.php:13` |
| BC-REF-02 | Search bar with `permissions="tenant.msh-exam-group"` and `createModal="#createExamGroupModal"` | Modal trigger | `_exam-groups.blade.php:5` |
| BC-REF-03 | Status header and body cells wrapped in `@can('tenant.msh-exam-group.update')` | Symmetrical | `_exam-groups.blade.php:44-46,61-63` |
| BC-REF-04 | Actions header/body wrapped in `@canany(['...view', '...update', '...delete'])` | Symmetrical | `_exam-groups.blade.php:47-49,64-69` |
| BC-REF-05 | Edit action uses `editExamGroup()` JS with `selectedTypeIds` JSON | Pre-populates multi-select | `_exam-groups.blade.php:67` |
| BC-REF-06 | `edit()` redirects to hub (modal-based) | No-op redirect | `ExamGroupController.php:68` |
| BC-REF-07 | Pagination preserves query params | `->appends(request()->query())` | `_exam-groups.blade.php:75` |
| BC-REF-08 | Empty state with icon and "No Exam Groups Found" | colspan covers all columns | `_exam-groups.blade.php:23-31` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Hub paginates at 15 per page with page name `eg_page` | `ExamGroup::with(...)->...->paginate(15, ['*'], 'eg_page')` — unique paginator name |
| BC-BIZ-DEEP-02 | `applyFilters()` only applies search when tab is active | `$tab === 'exam-groups'` — prevents cross-tab filter pollution |
| BC-BIZ-DEEP-03 | Search applies LIKE on `name` and `code` columns | `orWhere('name', 'like', "%{$search}%")->orWhere('code', 'like', ...)` |
| BC-BIZ-DEEP-04 | Status filter matches on `is_active` | `$query->where('is_active', (int) $status)` |
| BC-BIZ-DEEP-05 | Latest ordering via `->latest()` | Orders by `created_at DESC` |
| BC-BIZ-DEEP-06 | `store()` returns JSON when `$request->expectsJson()` | `{status: true, message, redirect}` |
| BC-BIZ-DEEP-07 | `update()` returns JSON when `$request->expectsJson()` | Same structure |
| BC-BIZ-DEEP-08 | All CRUD redirects to `configuration.combined?tab=exam-groups` | Consistent tab parameter |
| BC-BIZ-DEEP-09 | `restore()` redirects to `marksheet-generation.exam-group.trashed` | Trash management route |
| BC-BIZ-DEEP-10 | `forceDelete()` redirects back on failure | `redirect()->back() with error` |
| BC-BIZ-DEEP-11 | `toggleStatus()` returns JSON `{success: true, is_active, message}` | Consistent JSON structure |
| BC-BIZ-DEEP-12 | `syncItems()` uses raw DB queries (not Eloquent) | `DB::table('msh_exam_group_items_jnt')` for performance |
| BC-BIZ-DEEP-13 | `syncItems()` bulk soft-deletes excluded types in one query | `->whereNotIn('exam_type_id', $examTypeIds)->update(...)` |
| BC-BIZ-DEEP-14 | `syncItems()` handles empty exam_type_ids array correctly | `->when(!empty(...), fn($q) => ...)` — when empty, soft-deletes ALL items |
| BC-BIZ-DEEP-15 | `syncItems()` uses `Carbon::now()` for consistent timestamps | Same timestamp for all related rows |
| BC-BIZ-DEEP-16 | `academic_session_id` required in both Request and DB | Must exist in `sch_org_academic_sessions_jnt` |
| BC-BIZ-DEEP-17 | `code` scoped unique uses `->where(fn($q) => $q->where('academic_session_id', ...))` | Session-scoped uniqueness |
| BC-BIZ-DEEP-18 | `end_date` must be after or equal to `start_date` | `after_or_equal:start_date` validation |
| BC-BIZ-DEEP-19 | `start_date` and `end_date` are nullable | Both can be empty |
| BC-BIZ-DEEP-20 | `exam_type_ids.*` integer rule validates each array element | Validation fails if non-integer submitted |
| BC-BIZ-DEEP-21 | `exam_type_ids` extracted BEFORE model create/update in service | `unset($data['exam_type_ids'])` prevents mass-assignment of non-fillable |
| BC-BIZ-DEEP-22 | `activityLog('Stored')` for create | `'A new exam group was created.'` |
| BC-BIZ-DEEP-23 | `activityLog('Updated')` for update | `'The exam group was updated.'` |
| BC-BIZ-DEEP-24 | `activityLog('Deleted')` for destroy | `'The exam group was deleted.'` |
| BC-BIZ-DEEP-25 | `activityLog('Toggled')` for status toggle | `'Status was toggled.'` — no `performed_by` |
| BC-BIZ-DEEP-26 | `activityLog('Restored')` for restore | `'The record was restored.'` — no `performed_by` |
| BC-BIZ-DEEP-27 | `activityLog('Deleted')` for forceDelete success | `'The record was permanently deleted.'` |
| BC-BIZ-DEEP-28 | **OBSERVATION**: All activityLog calls lack `performed_by` key | Inconsistent with reference pattern |
| BC-BIZ-DEEP-29 | `show()` eagerly loads `academicSession` and `items.examType` | `$examGroup->load(['academicSession', 'items.examType'])` — N+1 prevention |
| BC-BIZ-DEEP-30 | `trashed()` paginates at 15 | `ExamGroup::onlyTrashed()->latest()->paginate(15)` |
| BC-BIZ-DEEP-31 | `trashed()` uses `viewAny` permission | `Gate::authorize('tenant.msh-exam-group.viewAny')` |
| BC-BIZ-DEEP-32 | `index()` paginates at 20 (standalone) | `ExamGroup::with('academicSession')->latest()->paginate(20)` |
| BC-BIZ-DEEP-33 | `restore()` uses `update` permission (not `restore`) | `Gate::authorize('tenant.msh-exam-group.update')` — **Anomaly**: should be restore |
| BC-BIZ-DEEP-34 | `forceDelete()` uses `delete` permission (not `forceDelete`) | `Gate::authorize('tenant.msh-exam-group.delete')` — **Anomaly**: should be forceDelete |
| BC-BIZ-DEEP-35 | `show()` uses route-model-binding | `show(ExamGroup $examGroup)` |
| BC-BIZ-DEEP-36 | `destroy()` uses route-model-binding | `destroy(ExamGroup $examGroup, ExamGroupService $service)` |
| BC-BIZ-DEEP-37 | `toggleStatus()`, `restore()`, `forceDelete()` use manual ID lookup | `findOrFail($id)` pattern |
| BC-BIZ-DEEP-38 | `is_active` is `sometimes` in Request (not `required`) | Can be omitted on update |
| BC-BIZ-DEEP-39 | `prepareForValidation()` casts `academic_session_id` to int | `(int) $this->input(...)` |
| BC-BIZ-DEEP-40 | `ExamGroupItem` model does NOT use SoftDeletes | Junction table has `deleted_at` but model uses manual DB queries |
| BC-BIZ-DEEP-41 | `syncItems()` sets `display_order` based on array index | Exam types displayed in user's selected order |
| BC-BIZ-DEEP-42 | `syncItems()` sets `is_active = 1` on all upserted rows | Junction items always active on create/restore |
| BC-BIZ-DEEP-43 | `syncItems()` sets `updated_by` and `updated_at` on restore | Audit trail for junction changes |
| BC-BIZ-DEEP-44 | `code` unique rule ignores soft-deleted records (no `->withoutTrashed()`) | Allows code reuse across deleted records |
| BC-BIZ-DEEP-45 | `$fillable` includes `academic_session_id`, `code`, `name`, `description`, `start_date`, `end_date`, `is_active`, `created_by`, `updated_by` | All visible fields mass-assignable except `exam_type_ids` |
| BC-BIZ-DEEP-46 | `ExamGroupRequest@authorize()` always returns true | Authorization in controller Gates |
| BC-BIZ-DEEP-47 | DB composite unique on (`academic_session_id`, `code`) | Additional DB-level protection beyond Request |
| BC-BIZ-DEEP-48 | Force delete catches only `23000` — re-throws other exceptions | `if ($e->getCode() === '23000')` specific check |
| BC-BIZ-DEEP-49 | `restore()` sets `is_active = true` after restore | `$record->update(['is_active' => true])` |
| BC-BIZ-DEEP-50 | `end_date` cast to `date` in model | `protected $casts = ['end_date' => 'date']` |
| BC-BIZ-DEEP-51 | `start_date` cast to `date` in model | `protected $casts = ['start_date' => 'date']` |
| BC-BIZ-DEEP-52 | `is_active` cast to `bool` in model | `protected $casts = ['is_active' => 'bool']` |
| BC-BIZ-DEEP-53 | `msh_exam_group_items_jnt` junction has `ExamGroupItem` model with `BelongsTo` relationships | `examGroup()`, `examType()`, `createdBy()`, `updatedBy()` |
| BC-BIZ-DEEP-54 | `items()` relationship uses `HasMany` to `ExamGroupItem` | `$this->hasMany(ExamGroupItem::class, 'exam_group_id')` |
| BC-BIZ-DEEP-55 | `configTemplates()` relationship uses `HasMany` to `ConfigTemplate` | `$this->hasMany(ConfigTemplate::class, 'exam_group_id')` |
| BC-BIZ-DEEP-56 | Hub tab uses `.view` permission in blade | `@can('tenant.msh-exam-group.view')` — not `.viewAny` |
| BC-BIZ-DEEP-57 | Modal entities loop in web.php generates routes for `exam-group` slug | `toggleStatus`, `trashed`, `restore`, `forceDelete` routes | `web.php:48` |
| BC-BIZ-DEEP-58 | Resource routes for `exam-group` | `Route::resource('exam-group', ExamGroupController::class)` | `web.php:76-77` |
| BC-BIZ-DEEP-59 | `edit()` route exists but never used (modal-based) | Route available but JS handles editing via PATCH directly | `ExamGroupController.php:64-68` |
| BC-BIZ-DEEP-60 | `array_map('intval', $examTypeIds)` in service sanitizes input | Ensures all IDs are integers before DB operations | `ExamGroupService.php:20` |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — ExamGroupController Lines 14-21 (Standalone)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 16 | `Gate::authorize('tenant.msh-exam-group.viewAny')` | Authorization gate |
| 02 | 18 | `$examGroups = ExamGroup::with('academicSession')->latest()->paginate(20)` | Eager load session, paginate 20 |
| 03 | 20 | `return view('marksheetgeneration::exam-group.index', compact('examGroups'))` | Return standalone view |

#### CODE-TRACE-A: Hub `configuration()` — MarksheetGenerationController Lines 68-93 (Primary Tab Listing)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 70 | `Gate::authorize('tenant.msh-configuration.view')` | Hub access gate |
| 02 | 72-74 | `$search/$status/$tab` extraction | Filter inputs |
| 03 | 79 | `$examGroups = $this->applyFilters(ExamGroup::with(['academicSession', 'items']), $tab === 'exam-groups' ? $search : null, ..., ['name', 'code'])->paginate(15, ['*'], 'eg_page')` | Query with eager loads, conditional filters, paginate 15 |

#### CODE-TRACE-02: `create()` — Lines 23-28

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 25 | `Gate::authorize('tenant.msh-exam-group.create')` | Authorization — create |
| 02 | 27 | `return view('marksheetgeneration::exam-group.create')` | Return standalone create view |

#### CODE-TRACE-03: `store(ExamGroupRequest $request, ExamGroupService $service)` — Lines 30-53

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 32 | `Gate::authorize('tenant.msh-exam-group.create')` | Authorization |
| 02 | 34 | `$examGroup = $service->create($request->validated(), (int) auth()->id())` | Delegate to service (handles junction sync) |
| 03 | 36-38 | `activityLog($examGroup, 'Stored', ['message' => 'A new exam group was created.'])` | Activity log — no performed_by |
| 04 | 40-42 | `$redirect = redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'exam-groups'])->with('success', flash('created.exam_group'))` | Build redirect |
| 05 | 44-49 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX JSON response |
| 06 | 52 | `return $redirect` | Standard redirect |

#### CODE-TRACE-04: `show(ExamGroup $examGroup)` — Lines 55-62

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 57 | `Gate::authorize('tenant.msh-exam-group.view')` | Authorization |
| 02 | 59 | `$examGroup->load(['academicSession', 'items.examType'])` | Eager load relationships for display |
| 03 | 61 | `return view('marksheetgeneration::exam-group.show', compact('examGroup'))` | Return show view |

#### CODE-TRACE-05: `edit(ExamGroup $examGroup)` — Lines 64-69

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 66 | `Gate::authorize('tenant.msh-exam-group.update')` | Authorization |
| 02 | 68 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'exam-groups'])` | No-op redirect (modal-based edit) |

#### CODE-TRACE-06: `update(ExamGroupRequest $request, ExamGroup $examGroup, ExamGroupService $service)` — Lines 71-94

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 73 | `Gate::authorize('tenant.msh-exam-group.update')` | Authorization |
| 02 | 75 | `$service->update($examGroup, $request->validated(), (int) auth()->id())` | Delegate to service (re-syncs junction) |
| 03 | 77-79 | `activityLog($examGroup, 'Updated', ['message' => 'The exam group was updated.'])` | Activity log |
| 04 | 81-83 | `$redirect = ...redirect('configuration.combined', ['tab' => 'exam-groups'])...` | Build redirect |
| 05 | 85-90 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX JSON |
| 06 | 93 | `return $redirect` | Standard redirect |

#### CODE-TRACE-07: `destroy(ExamGroup $examGroup, ExamGroupService $service)` — Lines 96-109

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 98 | `Gate::authorize('tenant.msh-exam-group.delete')` | Authorization |
| 02 | 100 | `$service->delete($examGroup)` | Service soft-deletes |
| 03 | 102-104 | `activityLog($examGroup, 'Deleted', ['message' => 'The exam group was deleted.'])` | Activity log |
| 04 | 106-108 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'exam-groups'])->with('success', flash('deleted.exam_group'))` | Redirect with flash |

#### CODE-TRACE-08: `toggleStatus($id)` — Lines 111-121

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 113 | `Gate::authorize('tenant.msh-exam-group.update')` | Authorization |
| 02 | 115 | `$record = ExamGroup::findOrFail($id)` | Manual lookup |
| 03 | 116 | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | Toggle status |
| 04 | 118 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Activity log |
| 05 | 120 | `return response()->json([...])` | JSON response |

#### CODE-TRACE-09: `trashed()` — Lines 123-130

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 125 | `Gate::authorize('tenant.msh-exam-group.viewAny')` | Authorization |
| 02 | 127 | `$trashed = ExamGroup::onlyTrashed()->latest()->paginate(15)` | Query soft-deleted |
| 03 | 129 | `return view('marksheetgeneration::trashed.exam-group', compact('trashed'))` | Return trash view |

#### CODE-TRACE-10: `restore($id)` — Lines 132-143

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 134 | `Gate::authorize('tenant.msh-exam-group.update')` | Authorization (uses update, not restore) |
| 02 | 136 | `$record = ExamGroup::onlyTrashed()->findOrFail($id)` | Find trashed |
| 03 | 137 | `$record->restore()` | Restore |
| 04 | 138 | `$record->update(['is_active' => true])` | Activate |
| 05 | 140 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Activity log |
| 06 | 142 | `return redirect()->route('marksheet-generation.exam-group.trashed')->with('success', 'Record restored successfully.')` | Redirect |

#### CODE-TRACE-11: `forceDelete($id)` — Lines 145-161

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 147 | `Gate::authorize('tenant.msh-exam-group.delete')` | Authorization (uses delete, not forceDelete) |
| 02 | 149 | `$record = ExamGroup::withTrashed()->findOrFail($id)` | Find any record |
| 03 | 150-158 | `try { $record->forceDelete(); activityLog(...); } catch (QueryException $e) { if (23000) { error } throw $e; }` | Delete with FK protection |
| 04 | 152 | `activityLog($record, 'Deleted', ['message' => 'The record was permanently deleted.'])` | Log on success |
| 05 | 155 | `return redirect()->back()->with('error', 'Cannot delete...')` | FK error message |
| 06 | 160 | `return redirect()->route('marksheet-generation.exam-group.trashed')->with('success', 'Record permanently deleted.')` | Success redirect |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create exam group with all fields | Full form: academic_session, code, name, dates, exam types | Record created with junction items, flash 'created.exam_group' |
| TC-P-02 | Create exam group with minimum fields | Only required: session, code, name | Created, junction items empty, activityLog 'Stored' |
| TC-P-03 | Create exam group via AJAX modal | Submit with expectsJson | JSON `{status: true, message, redirect}` |
| TC-P-04 | Edit exam group name and dates | Change name and date range | Updated, activityLog 'Updated' |
| TC-P-05 | Edit exam group: add exam types | Add 2 new exam types to junction | Junction table has 2 new rows |
| TC-P-06 | Edit exam group: remove exam types | Remove 2 exam types | Junction rows soft-deleted |
| TC-P-07 | Edit exam group: re-add removed type | Remove type, then re-add in same edit | Junction row restored (deleted_at set to null) |
| TC-P-08 | Edit exam group via AJAX | Submit edit modal with expectsJson | JSON response |
| TC-P-09 | Toggle exam group active→inactive | Click status switch | JSON `{success: true, is_active: false}` |
| TC-P-10 | Search exam groups by code | Partial code search | Filtered |
| TC-P-11 | Filter by active status | Select Active filter | Only active groups |
| TC-P-12 | Restore soft-deleted exam group | Delete → Trash → Restore | Restored, is_active=true |
| TC-P-13 | Force delete with no dependencies | Delete → Trash → Force Delete | Permanently deleted |
| TC-P-14 | Create exam group in different session with same code | Same code, different academic_session_id | Success (scoped unique) |
| TC-P-15 | View exam group details | Click view action | Show page with session, items, exam types |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty academic_session_id | Missing session | "The academic session field is required." |
| TC-N-02 | Create with empty code | Missing code | "The code field is required." |
| TC-N-03 | Create with duplicate code in same session | Same code in session_id=1 | "The code has already been taken." |
| TC-N-04 | Create with code > 30 chars | 31-char code | "The code must not be greater than 30 characters." |
| TC-N-05 | Create with name > 100 chars | 101-char name | "The name must not be greater than 100 characters." |
| TC-N-06 | Create with end_date before start_date | start=2026-09-01, end=2026-03-01 | "The end date must be a date after or equal to start date." |
| TC-N-07 | Create with invalid academic_session_id | ID=99999 | "The selected academic session id is invalid." |
| TC-N-08 | Create with invalid exam_type_id | exam_type_ids=[99999] | "Selected exam type does not exist." |
| TC-N-09 | Access store without create permission | User lacks create | 403 Access Denied |
| TC-N-10 | Update without update permission | User lacks update | 403 Access Denied |
| TC-N-11 | Destroy without delete permission | User lacks delete | 403 Access Denied |
| TC-N-12 | Toggle status without update permission | User lacks update | 403 Access Denied |
| TC-N-13 | Restore non-trashed (active) record | Call restore on active | 404 — onlyTrashed()->findOrFail() |
| TC-N-14 | Force delete referenced by Config Templates | FK constraint violation | Error: "Cannot delete this record because it is referenced by other records." |
| TC-N-15 | Toggle status on non-existent ID | Send toggleStatus to missing ID | 404 — findOrFail |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Soft delete exam group with Config Templates | Delete referenced group | Soft delete allowed (soft-delete doesn't check FK) |
| TC-D-02 | Force delete exam group with Config Templates | Permanent delete referenced group | QueryException 23000 caught, user-friendly error |
| TC-D-03 | Verify junction soft-delete on item removal | Remove exam type from group | Junction row has deleted_at set, not physically removed |
| TC-D-04 | Verify junction restore on re-add | Re-add previously removed type | Junction row restored (deleted_at = null) |
| TC-D-05 | Verify is_active=true after restore | Restore trashed group | is_active=1, deleted_at=null |
| TC-D-06 | Duplicate code allowed after soft-delete in same session | Delete TERM1_EXAMS, create new with same code | Success (unique ignores soft-deleted) |
| TC-D-07 | Verify updated_by null on create | Newly created record | updated_by is null |
| TC-D-08 | Verify created_by and updated_by on update | After update | created_by unchanged, updated_by set |
| TC-D-09 | Verify composite unique enforcement at DB level | Insert duplicate (session_id, code) via raw DB | DB constraint violation 23000 |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Verify Gate::authorize in index() | `ExamGroupController.php:16` | `tenant.msh-exam-group.viewAny` |
| TC-CR-02 | Verify Gate in store() | `ExamGroupController.php:32` | `tenant.msh-exam-group.create` |
| TC-CR-03 | Verify Gate in update() | `ExamGroupController.php:73` | `tenant.msh-exam-group.update` |
| TC-CR-04 | Verify Gate in destroy() | `ExamGroupController.php:98` | `tenant.msh-exam-group.delete` |
| TC-CR-05 | Verify Gate in toggleStatus() | `ExamGroupController.php:113` | `tenant.msh-exam-group.update` |
| TC-CR-06 | Verify Gate in restore() | `ExamGroupController.php:134` | `tenant.msh-exam-group.update` |
| TC-CR-07 | Verify Gate in forceDelete() | `ExamGroupController.php:147` | `tenant.msh-exam-group.delete` |
| TC-CR-08 | Verify service delegation in store() | `ExamGroupController.php:34` | `$service->create($request->validated(), auth()->id())` |
| TC-CR-09 | Verify service update() | `ExamGroupController.php:75` | `$service->update(...)` |
| TC-CR-10 | Verify service delete() | `ExamGroupController.php:100` | `$service->delete(...)` |
| TC-CR-11 | Verify syncItems logic in ExamGroupService | `ExamGroupService.php:48-79` | DB-based upsert with soft-delete delta |
| TC-CR-12 | Verify DB transaction in service create | `ExamGroupService.php:15` | `DB::transaction(function()...)` |
| TC-CR-13 | Verify DB transaction in service update | `ExamGroupService.php:29` | `DB::transaction(function()...)` |
| TC-CR-14 | Verify exam_type_ids extraction in service | `ExamGroupService.php:17-18` | `unset($data['exam_type_ids'])` before create |
| TC-CR-15 | Verify array_map('intval') on exam type IDs | `ExamGroupService.php:20` | Sanitized input |
| TC-CR-16 | Verify JSON response in store() | `ExamGroupController.php:44-49` | `{status, message, redirect}` |
| TC-CR-17 | Verify JSON response in update() | `ExamGroupController.php:85-90` | Same structure |
| TC-CR-18 | Verify scope of code unique rule | `ExamGroupRequest.php:26-29` | `->where(fn($q) => $q->where('academic_session_id', ...))` |
| TC-CR-19 | Verify eager loading in show() | `ExamGroupController.php:59` | `load(['academicSession', 'items.examType'])` |
| TC-CR-20 | Verify eager loading in hub listing | `MarksheetGenerationController.php:79` | `ExamGroup::with(['academicSession', 'items'])` |
| TC-CR-21 | Verify trashed() pagination | `ExamGroupController.php:127` | `onlyTrashed()->latest()->paginate(15)` |
| TC-CR-22 | Verify edit() redirect | `ExamGroupController.php:68` | Redirect to hub |
| TC-CR-23 | Verify prepareForValidation() | `ExamGroupRequest.php:42-46` | `boolean('is_active')`, `(int) academic_session_id` |
| TC-CR-24 | Verify $casts in model | `ExamGroup.php:26-29` | `start_date => date, end_date => date, is_active => bool` |
| TC-CR-25 | **OBSERVATION**: restore() uses update permission | `ExamGroupController.php:134` | Should be `restore` permission |
| TC-CR-26 | **OBSERVATION**: forceDelete() uses delete permission | `ExamGroupController.php:147` | Should be `forceDelete` permission |
| TC-CR-27 | **OBSERVATION**: activityLog calls lack performed_by | All 6 calls | Inconsistent with reference pattern |
| TC-CR-28 | Verify symmetrical @can in _exam-groups.blade.php | Blade:44-49,61-69 | th and td matching |
| TC-CR-29 | Verify tab permission in configuration.blade.php | `configuration.blade.php:13` | `tenant.msh-exam-group.view` |
| TC-CR-30 | Verify modal entity routes | `web.php:48` | exam-group slug in modal loop |

---

## 7. Detailed Test Steps

### TC-P-01: Create exam group with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-exam-group.create` permission | Success |
| 2 | Navigate to Marksheet Generation → Configuration hub | Hub page with 5 tabs |
| 3 | Click "Exam Groups" tab | Tab active, list displayed |
| 4 | Click "Add Exam Group" button | Create modal opens |
| 5 | Enter code="EG01", name="Term 1 Exams", description="First term examination" | Fields populated |
| 6 | Select marksheet_type_id dropdown (existing marksheet type) | Dropdown selection |
| 7 | Set academic_session_id=2025-2026, is_active=Active | Form complete |
| 8 | Click "Save" | AJAX POST to store |
| 9 | **Verify**: `Gate::authorize('tenant.msh-exam-group.create')` passes | Authorized |
| 10 | **Verify**: `ExamGroupRequest` validation passes | No validation errors |
| 11 | **Verify**: `ExamGroup::create($request->validated())` inserts row in `msh_exam_groups` | DB has code="EG01" |
| 12 | **Verify**: `activityLog()` called with type "Stored" | Activity log entry created |
| 13 | **Verify**: Modal closes, table refreshes | New row visible |
| 14 | **Verify**: Flash success message displayed | "Exam Group created successfully" |

### TC-P-02: Create exam group with minimum fields (nullable description)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.create` | Success |
| 2 | Open create modal | Modal displayed |
| 3 | Enter code="EG02", name="Minimal EG", select marksheet_type_id, set academic_session_id | Required fields |
| 4 | Leave description empty (nullable) | Optional omitted |
| 5 | Click "Save" | POST request |
| 6 | **Verify**: Validation passes — description nullable | No errors |
| 7 | **Verify**: Record created with `description=null` | DB row inserted |
| 8 | **Verify**: Flash success message | Confirmation shown |

### TC-P-03: Edit exam group — change name and description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.update` permission | Success |
| 2 | Navigate to Exam Groups tab | List displayed |
| 3 | Click edit icon on existing group "EG01" | Edit modal opens with pre-filled data |
| 4 | **Verify**: `Gate::authorize('tenant.msh-exam-group.update')` passes | Authorized |
| 5 | Change name from "Term 1 Exams" to "Term 1 Exams Updated" | Input updated |
| 6 | Update description | Description changed |
| 7 | Click "Update" | PUT request |
| 8 | **Verify**: `$record->update($request->validated())` | DB updated |
| 9 | **Verify**: `$record->getChanges()` captures changed attributes | Change tracking works |
| 10 | **Verify**: `activityLog()` with type "Updated" and `changes` array | Activity log shows old/new |
| 11 | **Verify**: Modal closes, table refreshes with updated data | Name updated in list |
| 12 | **Verify**: Flash success `flash('updated.msh-exam-group')` | Success message |

### TC-P-04: Edit exam group — change marksheet_type_id association

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.update` | Success |
| 2 | Edit an exam group, change marksheet_type_id to a different type | Different type selected |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: `marksheet_type_id` updated in DB | Association changed |
| 5 | **Verify**: Activity log records FK change | old/new values tracked |

### TC-P-05: Toggle exam group active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.update` permission | Success |
| 2 | Navigate to Exam Groups tab | List with status toggles |
| 3 | Locate an active exam group toggle | Toggle is ON (green) |
| 4 | Click the status toggle | AJAX POST to toggleStatus |
| 5 | **Verify**: `Gate::authorize('tenant.msh-exam-group.update')` passes | Authorized |
| 6 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` | Validation ok |
| 7 | **Verify**: `$record->is_active = false`, `$record->save()` | DB updated |
| 8 | **Verify**: JSON response `{success: true, is_active: false}` | Toggle now OFF |

### TC-P-06: Toggle exam group inactive→active (bidirectional)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.update` | Success |
| 2 | Find an inactive exam group | is_active=0 |
| 3 | Click status toggle | AJAX POST |
| 4 | **Verify**: `$request->boolean('is_active')` = true | Toggle sends true |
| 5 | **Verify**: `$record->is_active = true` | Set to active |
| 6 | **Verify**: JSON `{success: true, is_active: true}` | Toggle now ON |

### TC-P-07: View exam group details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.view` permission | Success |
| 2 | Navigate to Exam Groups tab | List displayed |
| 3 | Click view icon on a group row | Show modal opens |
| 4 | **Verify**: All fields: code, name, description, marksheet_type_id, academic_session_id, is_active | Data visible |
| 5 | **Verify**: marksheet_type relationship resolved to type name | Related data displayed |
| 6 | **Verify**: is_active shown as Active/Inactive badge | Status indicator |

### TC-P-08: Search exam group by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.viewAny` | Success |
| 2 | Navigate to Exam Groups tab | List with search bar |
| 3 | Type "EG01" in search box | Search input filled |
| 4 | Submit search | GET with `?search=EG01` |
| 5 | **Verify**: Controller applies `->where('code','like','%EG01%')->orWhere('name','like','%EG01%')` | Filtered |
| 6 | **Verify**: Only matching groups displayed | Filtered results |

### TC-P-09: Filter exam group by status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.viewAny` | Success |
| 2 | Select "Active" from status filter | `status=1` |
| 3 | Submit filter | GET with `?status=1` |
| 4 | **Verify**: `->where('is_active', 1)` applied | Only active displayed |
| 5 | Change to "Inactive" filter | `?status=0` — only inactive |
| 6 | Verify status + search combined | Both params in URL |

### TC-P-10: Soft-delete exam group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.delete` permission | Success |
| 2 | Click delete icon on an exam group row | Confirmation dialog |
| 3 | Confirm deletion | DELETE request |
| 4 | **Verify**: `Gate::authorize('tenant.msh-exam-group.delete')` passes | Authorized |
| 5 | **Verify**: `$record->is_active = false; $record->save(); $record->delete()` | Soft-delete executed |
| 6 | **Verify**: DB: `is_active=0`, `deleted_at` IS NOT NULL | Properly trashed |
| 7 | **Verify**: `activityLog()` with type "Trashed" | Activity log entry |
| 8 | **Verify**: Row removed from active list | No longer visible |

### TC-P-11: Restore soft-deleted exam group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.restore` permission | Success |
| 2 | Navigate to trash listing | Trashed records shown |
| 3 | Click "Restore" on a trashed group | Restore action |
| 4 | **Verify**: `Gate::authorize('tenant.msh-exam-group.restore')` passes | Authorized |
| 5 | **Verify**: `onlyTrashed()->findOrFail($id)` | Record found |
| 6 | **Verify**: `$record->restore()` sets `deleted_at = NULL` | Restored |
| 7 | **Verify**: `is_active` remains FALSE | Group stays inactive |
| 8 | **Verify**: Redirect to index + flash success | Confirmation |

### TC-P-12: Force delete trashed exam group (no dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.forceDelete` permission | Success |
| 2 | Click "Force Delete" on a trashed group with NO dependent records | Force delete |
| 3 | **Verify**: `withTrashed()->findOrFail($id)` | Record found |
| 4 | **Verify**: `$record->forceDelete()` | Record permanently deleted |
| 5 | **Verify**: `activityLog()` with type "Deleted" | Log entry created |
| 6 | **Verify**: Redirect + flash success | Confirmation |

### TC-N-01: Create with empty code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.create` | Success |
| 2 | Open create modal, leave code EMPTY | code omitted |
| 3 | Fill name, marksheet_type_id, academic_session_id | Others filled |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: `ExamGroupRequest` rule `required` on `code` | "The code field is required." |
| 6 | **Verify**: No record created | DB unchanged |

### TC-N-02: Create with empty name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-exam-group.create` | Success |
| 2 | Open create modal, leave name EMPTY | name omitted |
| 3 | Fill code, marksheet_type_id | Others filled |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: `required` rule on `name` | "The name field is required." |

### TC-N-03: Create with duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure group with code="EG01" exists | Existing record |
| 2 | Create new group with same code="EG01" | Duplicate |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: `Rule::unique('msh_exam_groups', 'code')` | "The code has already been taken." |

### TC-N-04: Create without marksheet_type_id (required FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam group, leave marksheet_type_id unselected | FK omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required|integer` rule on `marksheet_type_id` | "The marksheet type id field is required." |

### TC-N-05: Create with non-existent marksheet_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam group with marksheet_type_id=99999 | Invalid FK |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `exists:msh_marksheet_types,id` rule | "The selected marksheet type id is invalid." |

### TC-N-06: Create without academic_session_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam group, leave academic_session_id empty | Required field omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required` rule on `academic_session_id` | Validation error |

### TC-N-07: Access tab without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-exam-group.view` | No view |
| 2 | Navigate to Configuration hub | Hub loads |
| 3 | **Verify**: Exam Groups tab HIDDEN via `@can` | Tab not visible |
| 4 | Direct URL with `?tab=exam-groups` | **Verify**: tab nav hidden + @include blocked |

### TC-N-08: Direct store without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-exam-group.create` | No create |
| 2 | POST valid data to store | Direct access |
| 3 | **Verify**: `Gate::authorize('tenant.msh-exam-group.create')` throws 403 | Forbidden |

### TC-N-09: Direct update without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-exam-group.update` | No update |
| 2 | PUT valid data | Direct access |
| 3 | **Verify**: `Gate::authorize('tenant.msh-exam-group.update')` throws 403 | Forbidden |

### TC-N-10: Direct delete without delete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-exam-group.delete` | No delete |
| 2 | DELETE to destroy | Direct access |
| 3 | **Verify**: `Gate::authorize('tenant.msh-exam-group.delete')` throws 403 | Forbidden |

### TC-N-11: Restore non-trashed active record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure active exam group (deleted_at=NULL) | Active |
| 2 | Call restore route | Restore action |
| 3 | **Verify**: `onlyTrashed()->findOrFail($id)` throws ModelNotFoundException | 404 error |

### TC-N-12: Toggle status with invalid boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggleStatus with `is_active=2` | Invalid boolean |
| 2 | **Verify**: `required|boolean` validation | "The is active field must be true or false." |

### TC-N-13: Toggle status without is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggleStatus with no `is_active` param | Missing param |
| 2 | **Verify**: `required|boolean` validation | "The is active field is required." |
| 3 | **Verify**: 422 JSON error response | Validation error |

### TC-N-14: Code exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create group with code = 101 characters (exceeds max:100) | Over limit |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: Rule `max:100` on `code` | "The code must not be greater than 100 characters." |

### TC-N-15: Edit code to duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit EG02, change code to "EG01" (already exists) | Duplicate |
| 2 | Click "Update" | PUT request |
| 3 | **Verify**: `Rule::unique('msh_exam_groups','code')->ignore($id)` | "The code has already been taken." |

### TC-D-01: Force delete exam group with dependent items (FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam group "EG-DEP" | Parent record |
| 2 | Create exam group items referencing `exam_group_id="EG-DEP"` | Dependent records in `msh_exam_group_items` |
| 3 | Soft-delete EG-DEP | Trashed |
| 4 | Attempt force delete | Force delete action |
| 5 | **Verify**: DB FK constraint | `msh_exam_group_items.exam_group_id` → `msh_exam_groups.id` |
| 6 | **Verify**: `QueryException` code `23000` | Integrity constraint violation |
| 7 | **Verify**: Catch block handling | "Cannot delete due to existing records" |
| 8 | **Verify**: Record remains in trash | Delete prevented |

### TC-D-02: Duplicate code after force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "UNIQUE-EG", soft-delete, force-delete | Permanently removed |
| 2 | Create new group with same code "UNIQUE-EG" | Unique re-use allowed |
| 3 | **Verify**: New record created successfully | DB allows |

### TC-D-03: `is_active=false` before soft-delete sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active group: is_active=1, deleted_at=NULL | Active |
| 2 | Call destroy | Soft-delete |
| 3 | **Verify**: `is_active=0`, `deleted_at` IS NOT NULL | Deactivated before delete |
| 4 | Restore group | `is_active` stays 0 |

### TC-D-04: Toggle status after soft-delete (not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an exam group | Trashed |
| 2 | POST to toggleStatus | AJAX request |
| 3 | **Verify**: `findOrFail($id)` excludes soft-deleted | 404 ModelNotFoundException |

### TC-D-05: Marksheet type FK dependency from exam group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create marksheet type "MT-DEP" | Parent |
| 2 | Create exam group referencing MT-DEP | Dependent |
| 3 | Attempt to force delete MT-DEP | FK violation from exam group |
| 4 | **Verify**: QueryException 23000 | Cannot delete parent with children |

### TC-D-06: Update after soft-delete (record not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete an exam group | Trashed |
| 2 | PUT update request | Direct access |
| 3 | **Verify**: `findOrFail($id)` | 404 — soft-deleted excluded |

### TC-CR-01: Verify Gate::authorize in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:31` | `Gate::authorize('tenant.msh-exam-group.create')` |
| 2 | Verify string matches permissionslist.php | Consistent |

### TC-CR-02: Verify Gate::authorize in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:74` | `Gate::authorize('tenant.msh-exam-group.update')` |
| 2 | Verify consistency | OK |

### TC-CR-03: Verify Gate::authorize in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:93` | `Gate::authorize('tenant.msh-exam-group.delete')` |
| 2 | Verify | OK |

### TC-CR-04: Verify Gate::authorize in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:132` | `Gate::authorize('tenant.msh-exam-group.update')` |
| 2 | **OBSERVATION**: Uses `update` instead of `restore` | Inconsistent — should be `restore` |

### TC-CR-05: Verify Gate::authorize in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:145` | `Gate::authorize('tenant.msh-exam-group.delete')` |
| 2 | **OBSERVATION**: Uses `delete` instead of `forceDelete` | Inconsistent |

### TC-CR-06: Verify activityLog store() absence of performed_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:36-38` | `activityLog($record, 'Stored', ['message' => '...'])` |
| 2 | Check for `performed_by` | **MISSING** |

### TC-CR-07: Verify activityLog update() change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:79-83` | Change tracking via `getChanges()` |
| 2 | Verify `$original` before update | Pre-state captured |
| 3 | **OBSERVATION**: `performed_by` MISSING | Inconsistent |

### TC-CR-08: Verify activityLog destroy() and toggleStatus()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check destroy() at `ExamGroupController.php:99-101` | `performed_by` MISSING |
| 2 | Check toggleStatus() at `ExamGroupController.php:116` | `performed_by` MISSING |

### TC-CR-09: Verify `$request->validated()` usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check store() line 33 | `ExamGroup::create($request->validated())` |
| 2 | Check update() line 77 | `$record->update($request->validated())` |
| 3 | **Result**: No raw `$request->input()` used | Proper validation |

### TC-CR-10: Verify ExamGroupRequest rules for marksheet_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupRequest.php:19` | `'marksheet_type_id' => 'required|integer|exists:msh_marksheet_types,id'` |
| 2 | Verify FK validation | Proper exist rule |

### TC-CR-11: Verify prepareForValidation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupRequest.php:42-46` | `boolean('is_active')`, `(int) academic_session_id` |
| 2 | Verify normalizations | Proper type casting |

### TC-CR-12: Verify $casts in ExamGroup model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroup.php:26-29` | `start_date => date, end_date => date, is_active => bool` |
| 2 | Verify cast types | Dates = Carbon, bool = boolean |

### TC-CR-13: Verify $fillable includes all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroup.php:10-18` | All fillable fields listed |
| 2 | Cross-check DDL | Match |

### TC-CR-14: Verify `@can` symmetry in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `_exam-groups.blade.php:44-49,61-69` | th and td have matching `@can` wrappers |
| 2 | Verify `@canany` closed with `@endcanany` | Proper closing |

### TC-CR-15: Verify resource routes in web.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php:48` | `exam-group` slug in modal entity loop |
| 2 | Open `web.php:74-75` | `Route::resource('exam-group', ExamGroupController::class)` |
| 3 | Verify extra routes (trashed, restore, forceDelete, toggleStatus) | All 4 present |

### TC-CR-16: Verify `edit()` redirects to hub with tab param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:66` | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'exam-groups'])` |
| 2 | Verify tab param matches blade | `exam-groups` tab |

### TC-CR-17: Verify `show()` uses `findOrFail()` not route-model-binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:53` | `ExamGroup::findOrFail($id)` |
| 2 | Verify manual lookup | Explicit query |

### TC-CR-18: Verify `destroy()` 3-step deactivation sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:95-98` | `$record->is_active = false; $record->save(); $record->delete()` |
| 2 | Verify order | Deactivate → persist → soft-delete |

### TC-CR-19: Verify `restore()` does NOT reactivate is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:134-138` | `$record->restore()` — no is_active=true set |
| 2 | Verify consistent with MarksheetType/ClassGroup/IAComponentType | All 4 entities same behavior |

### TC-CR-20: Verify `forceDelete()` catches QueryException 23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:149-153` | `catch (\Exception $e) { if($e->getCode() == '23000') ... }` |
| 2 | Verify flash message and redirect | Graceful FK error handling |

### TC-CR-21: Verify `toggleStatus()` inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:113-114` | `$request->validate(['is_active' => 'required|boolean'])` |
| 2 | Verify no custom FormRequest | Inline validation only |

### TC-CR-22: Verify `_exam-groups.blade.php` `@can` for status column symmetry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade file: th and td for Status column | Both wrapped in `@can('tenant.msh-exam-group.update')` |
| 2 | Verify matching | Symmetrical guards |

### TC-CR-23: Verify `@canany` for action column closed with `@endcanany`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade file line 69 | `@canany([...]) ... @endcanany` |
| 2 | Verify NOT `@endcan` | Proper closing directive |

### TC-CR-24: Verify `trashed()` pagination uses 15 per page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:125` | `onlyTrashed()->latest()->paginate(15)` |
| 2 | Verify paginator | 15 not 10 |

### TC-CR-25: Verify `ExamGroupRequest` has `academic_session_id` rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupRequest.php:20` | `'academic_session_id' => 'required|integer'` |
| 2 | Verify not just nullable | Required field |

### TC-P-13: Create exam group with academic_session_id=0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open create modal, code="EG-ZERO", name="Zero Session" | Form |
| 3 | Set academic_session_id=0 | Zero value |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: academic_session_id=0 stored as integer 0 | Zero allowed |

### TC-P-14: Search exam group by marksheet_type_id filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Exam Groups tab | List displayed |
| 2 | Select specific marksheet_type_id filter | FK filter |
| 3 | Submit | Only groups for that type shown |

### TC-N-16: Create with academic_session_id exceeding integer range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with academic_session_id=999999999999 | Over integer range |
| 2 | **Verify**: DB may throw out-of-range error | Error handling per DDL |

### TC-N-17: XSS injection in description field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with description = `<script>alert('xss')</script>` | XSS payload |
| 2 | **Verify**: `{{ }}` auto-escapes | Safe rendering |

### TC-D-07: Concurrent double-click status toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly click toggle twice | Two AJAX POSTs |
| 2 | **Verify**: Final state determined by last request | Race condition |

### TC-D-08: Stale edit mid-air collision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Two users open edit for same exam group | Both read same data |
| 2 | User A updates first | Write A |
| 3 | User B updates second | Write B overwrites A |
| 4 | **Verify**: No optimistic locking | Last-write-wins |

### TC-D-09: Session CSRF expiry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Session expires before form submission | Token invalid |
| 2 | Submit create/edit form | 419 Page Expired |

### TC-D-10: Activity log after force-delete (orphaned log entry)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete exam group | Removed |
| 2 | Query activity_log for "Deleted" with subject_type=ExamGroup | Log persists |

### TC-P-17: Create with 3 items, verify sync

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam group with code="EG-SYNC", item_ids=[1,2,3] | POST request |
| 2 | **Verify**: `syncItems()` called with [1,2,3] | Junction rows created |
| 3 | **Verify**: activityLog "Stored" recorded | Success log |

### TC-P-18: Edit — remove 2 items, add 1 new

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit for exam group with items [1,2,3] | Form with 3 selected |
| 2 | Deselect items 2 and 3, select item 4 | item_ids=[1,4] |
| 3 | Click "Update" | PUT with item_ids=[1,4] |
| 4 | **Verify**: syncItems detaches [2,3], attaches [4] | Junction correct |

### TC-P-19: Edit — verify `getOriginal()` captures pre-change state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read exam group code = "EG-OLD", name = "Old Name" | Original values |
| 2 | Update code to "EG-NEW", name to "New Name" | PUT request |
| 3 | **Verify**: `$record->getOriginal()` captured old values | Changes array shows both fields |
| 4 | **Verify**: `$changes` array has `'code' => ['old' => 'EG-OLD', 'new' => 'EG-NEW']` | Correct diff |

### TC-P-20: Show page renders with items count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show for exam group with 3 items | Detail page |
| 2 | **Verify**: `$record->load('items.schoolClass')` in show() | Items eager-loaded |
| 3 | **Verify**: Items list renders in view | All 3 displayed |

### TC-N-18: Create with non-array item_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST item_ids="not_an_array" | Invalid type |
| 2 | **Verify**: `nullable|array` validation fails | "The item ids must be an array." |

### TC-N-19: Create with item_ids containing non-existent IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with item_ids=[99999] via POST | Non-existent ID |
| 2 | **Verify**: `syncItems()` attaches 99999 without FK check | Junction row created (no validation) |
| 3 | **Verify**: Service does NOT validate IDs exist — passes to sync() | Orphan junction row |

### TC-N-20: SQL injection in code field search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter search = `' UNION SELECT * FROM users --` | SQLi attempt |
| 2 | **Verify**: `like "%...%"` uses parameterized query | Safe |

### TC-D-11: Verify `trashed()` uses `viewAny` not `restore` in controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:88` | `Gate::authorize('tenant.msh-exam-group.viewAny')` |
| 2 | **Verify**: viewAny used (not restore) for trash page | Matches ClassGroup pattern |

### TC-D-12: Verify `forceDelete()` catch block re-throws non-23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Mock `QueryException` with code '42S22' | Non-FK error |
| 2 | Call forceDelete | Exception re-thrown |
| 3 | **Verify**: `throw $e` executed | Not swallowed |

### TC-CR-25: Verify `store()` uses `syncItems()` from service

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ExamGroupController.php:42-45` | `$examGroup = ExamGroup::create($request->validated()); $service->syncItems($examGroup, $request->item_ids ?? []);` |
| 2 | Verify service method called after create | Correct order |

### BC-BIZ-DEEP-60: `display_order` on ExamGroupItem is non-auto

| # | Condition | Expected Behavior |
|---|-----------|------------------|
| BC-BIZ-DEEP-60 | `syncItems()` sets display_order explicitly from sync data — not auto-incrementing | display_order must be provided |
| BC-BIZ-DEEP-61 | Junction table `msh_exam_group_items_jnt` has `display_order` INT column | Sortable via sync |
| BC-BIZ-DEEP-62 | `syncItems()` restores (deleted_at = null) rather than re-creating | Soft-delete aware sync |
| BC-BIZ-DEEP-63 | `restore()` does NOT set is_active=true after restore | Matches ClassGroup pattern |
| BC-BIZ-DEEP-64 | `create()` in controller passes ALL validated data directly | No field filtering before create |
| BC-BIZ-DEEP-65 | Hub `examGroupsQuery()` does NOT eager-load `items` relation | Only base query with latest() |
| BC-BIZ-DEEP-66 | No `export` or `print` methods on ExamGroupController | Standard CRUD without export |
| BC-BIZ-DEEP-67 | `toggleStatus()` does NOT set `updated_by` | Missing field update gap |
| BC-BIZ-DEEP-68 | Flash key `flash('deleted.exam_group')` must exist in lang file | Verify in flash.php |

### CODE-TRACE-HUB: `examGroupsQuery()` — MarksheetGenerationController Private Method

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | ~220 | `private function examGroupsQuery(Request $request): Builder` | Private query helper for exam-groups hub tab |
| 02 | ~221 | `$query = ExamGroup::query()` | No eager loads needed |
| 03 | ~223 | `if ($request->input('tab') === 'exam-groups')` | Only apply filters when tab active |
| 04 | ~224 | `->when($request->filled('search'), fn ($q) => $q->where('code', 'like', "%{$request->search}%")->orWhere('name', 'like', "%{$request->search}%"))` | Search on code and name |
| 05 | ~225 | `->when($request->filled('status'), fn ($q) => $q->where('is_active', (bool) $request->status))` | Status filter |
| 06 | ~227 | `return $query->latest()` | Always order by latest |
| 07 | Hub | `paginate(15, ['*'], 'exam_groups_page')` with `->appends(['tab' => 'exam-groups'])` | Unique paginator, tab persistence |
