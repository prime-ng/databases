# Subject Practical Config — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Subject Practical Config (`msh_subject_practical_configs`) |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\SubjectPracticalConfigController` — 11 methods (index, create, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete) |
| **Tab Container Controller** | `Modules\MarksheetGeneration\Http\Controllers\MarksheetGenerationController@scheduling()` — tab id `practical-configs` |
| **Model** | `Modules\MarksheetGeneration\Models\SubjectPracticalConfig` — SoftDeletes, HasFactory, 5 relationships |
| **Form Request** | `SubjectPracticalConfigRequest` — 8 validation rules + prepareForValidation |
| **Service Layer** | `SubjectPracticalConfigService` — create/update/delete wrapped in DB::transaction |
| **Permission Slug** | `tenant.msh-subject-practical-config` — full CRUD (viewAny, view, create, update, delete, restore, forceDelete) |
| **Route Prefix** | `subject-practical-config.*` (resource) + trashed, restore, forceDelete, toggleStatus |
| **Blade Views** | `subject-practical-config/index.blade.php` (tab partial), `create.blade.php`, `show.blade.php` |
| **Tab Container** | `scheduling/tab.blade.php` — tab id `practical-configs`, permission `tenant.msh-subject-practical-config.viewAny` |
| **Hub Route** | `marksheet-generation.scheduling.combined?tab=practical-configs` |
| **DB Table** | `msh_subject_practical_configs` — 10 fillable columns + timestamps + soft-deletes |
| **Primary Screen** | Marksheet Generation → Scheduling → Practical Configs tab |
| **Eager Loads** | `academicSession`, `schoolClass`, `subject` |
| **Pagination** | 20 per page (`index()`), 15 per page (hub tab) — page name `pc_page` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with role having `tenant.msh-subject-practical-config.*` permissions |
| PC-02 | Database table `msh_subject_practical_configs` must exist with all fillable columns |
| PC-03 | `sch_classes` table must have at least one active class record |
| PC-04 | `sch_subjects` table must have at least one active subject record |
| PC-05 | `sch_org_academic_sessions_jnt` table must have at least one active academic session |
| PC-06 | `SubjectPracticalConfigController` must be registered in routes with full resource + extra routes |
| PC-07 | Soft deletes must be enabled (`deleted_at` column) on `msh_subject_practical_configs` |
| PC-08 | Scheduling tab hub view must include `@can('tenant.msh-subject-practical-config.viewAny')` guard |
| PC-09 | `SubjectPracticalConfigService` must be injectable via container (auto-resolved) |
| PC-10 | Browser must support JavaScript for AJAX status toggle |
| PC-11 | `config/permissionslist.php` must have `msh-subject-practical-config` entry with full CRUD actions |
| PC-12 | Activity log system must be operational (`activityLog()` helper available) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load configs with pagination (20 per page) via `SubjectPracticalConfigController::index()` | `Controller.php:18-20` — `SubjectPracticalConfig::with(['academicSession','schoolClass','subject'])->latest()->paginate(20)` |
| DL-02 | Hub scheduling page loads configs via `MarksheetGenerationController@scheduling()` with eager loads | Hub controller passes data to `scheduling/tab.blade.php` |
| DL-03 | Eager loads: academicSession, schoolClass, subject — 3 relationships | `Controller.php:18` |
| DL-04 | Search/filter bar with tab hidden input `?tab=practical-configs` | Tab partial blade includes hidden tab param |
| DL-05 | Status column uses `<x-backend.table.status-switch>` component | Tab partial index.blade.php |
| DL-06 | Action column uses `<x-backend.table.action>` — conditional for view/update/delete | Tab partial index.blade.php |
| DL-07 | Pagination links appended with `?tab=practical-configs` and page name `pc_page` | Tab partial blade appends tab param |
| DL-08 | Empty state: "No records found" displayed for table colspan | Tab partial `@empty` block |
| DL-09 | Create form loads without dropdown data (empty view returned) | `Controller.php:29` — no variables passed to view |
| DL-10 | Show page loads subjectPracticalConfig with 3 eager loads | `Controller.php:64` — `->load(['academicSession','schoolClass','subject'])` |
| DL-11 | edit() does NOT render edit view — redirects to hub page | `Controller.php:73` — `return redirect()->route('marksheet-generation.scheduling.combined', ['tab' => 'practical-configs'])` |
| DL-12 | Trash page paginates at 15 per page | `Controller.php:132` — `SubjectPracticalConfig::onlyTrashed()->latest()->paginate(15)` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Config** | `academic_session_id=1, class_id=1, subject_id=1, has_practical=true, theory_max_marks=80, practical_max_marks=20, is_active=true` |
| TD-02 | **Duplicate Composite Key** | Create second config with same `class_id`, `subject_id`, `academic_session_id` — expects unique composite violation |
| TD-03 | **Invalid Academic Session ID** | `academic_session_id=99999` — expects `exists:sch_org_academic_sessions_jnt,id` failure |
| TD-04 | **Invalid Class ID** | `class_id=99999` — expects `exists:sch_classes,id` failure |
| TD-05 | **Invalid Subject ID** | `subject_id=99999` — expects `exists:sch_subjects,id` failure |
| TD-06 | **Negative Theory Max Marks** | `theory_max_marks=-10` — expects `min:0` validation failure |
| TD-07 | **Theory-only Config** | `has_practical=false, practical_max_marks=0` — valid theory-only config |
| TD-08 | **Soft-deleted Config Reuse** | Delete config, create new with same composite key — should succeed (unique ignores soft-deleted at Request layer) |
| TD-09 | **Force Delete with FK References** | Config referenced by student IA marks — expects QueryException 23000 catch block with user-friendly error |
| TD-10 | **Toggle Status from Active to Inactive** | Toggle active config — expects AJAX JSON `{success:true, is_active:false}` |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `academic_session_id` — INT UNSIGNED, NOT NULL, FK → `sch_org_academic_sessions_jnt.id` | Required, integer FK | DDL migration |
| BC-DB-02 | `class_id` — INT UNSIGNED, NOT NULL, FK → `sch_classes.id` | Required, integer FK | DDL migration |
| BC-DB-03 | `subject_id` — INT UNSIGNED, NOT NULL, FK → `sch_subjects.id` | Required, integer FK | DDL migration |
| BC-DB-04 | UNIQUE KEY on (`academic_session_id`, `class_id`, `subject_id`) | Composite unique across all three fields | DDL migration |
| BC-DB-05 | `has_practical` — TINYINT(1), DEFAULT 0 | Boolean flag for practical exam existence | DDL |
| BC-DB-06 | `theory_max_marks` — DECIMAL(10,2), NOT NULL, DEFAULT 0.00 | Max theory marks, decimal precision | DDL |
| BC-DB-07 | `practical_max_marks` — DECIMAL(10,2), NOT NULL, DEFAULT 0.00 | Max practical marks, decimal precision | DDL |
| BC-DB-08 | `is_active` — TINYINT(1), DEFAULT 1 | Active flag for soft-delete tracking | DDL |
| BC-DB-09 | `created_by` — INT UNSIGNED, NULLABLE, FK → `users.id` | Creator user reference | DDL |
| BC-DB-10 | `updated_by` — INT UNSIGNED, NULLABLE, FK → `users.id` | Updater user reference | DDL |
| BC-DB-11 | `deleted_at` — TIMESTAMP, NULLABLE | Soft delete timestamp | SoftDeletes trait |
| BC-DB-12 | `created_at` / `updated_at` — TIMESTAMP | Standard Laravel timestamps | DDL |
| BC-DB-13 | `id` — BIGINT UNSIGNED AUTO_INCREMENT | Primary key | DDL |
| BC-DB-14 | `theory_max_marks` decimal(10,2) — max value 99999999.99 | Supports large mark values | Model cast `decimal:2` |
| BC-DB-15 | `practical_max_marks` decimal(10,2) — max value 99999999.99 | Supports large mark values | Model cast `decimal:2` |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `academic_session_id` — required, integer, exists in DB | `'required', 'integer', 'exists:sch_org_academic_sessions_jnt,id'` | Request:20-24 |
| BC-VAL-02 | `class_id` — required, integer, exists, unique composite with where clause | `'required', 'integer', 'exists:sch_classes,id', Rule::unique(...)->where(fn $q => $q->where('academic_session_id', ...)->where('subject_id', ...))->ignore($id)` | Request:25-34 |
| BC-VAL-03 | `subject_id` — required, integer, exists | `'required', 'integer', 'exists:sch_subjects,id'` | Request:35 |
| BC-VAL-04 | `has_practical` — sometimes, boolean | `'sometimes', 'boolean'` | Request:36 |
| BC-VAL-05 | `theory_max_marks` — required, numeric, min:0 | `'required', 'numeric', 'min:0'` | Request:37 |
| BC-VAL-06 | `practical_max_marks` — required, numeric, min:0 | `'required', 'numeric', 'min:0'` | Request:38 |
| BC-VAL-07 | `is_active` — sometimes, boolean | `'sometimes', 'boolean'` | Request:39 |
| BC-VAL-08 | No validation for `created_by` or `updated_by` — set by controller/service | Not present in Request rules | Controller:37, Service:24 |
| BC-VAL-09 | Unique composite ignores current record on update via `->ignore($id)` | Allows updating record without unique self-conflict | Request:33 |
| BC-VAL-10 | `prepareForValidation()` casts FK fields to integer | `(int) $this->input(...)` for academic_session_id, class_id, subject_id | Request:46-48 |
| BC-VAL-11 | `prepareForValidation()` normalizes boolean fields | `$this->boolean('has_practical')`, `$this->boolean('is_active')` | Request:49-50 |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Source |
|----|-----------|-----------------|--------|
| BC-AUTH-01 | `tenant.msh-subject-practical-config.viewAny` | `Gate::authorize('...viewAny')` in `index()` and `trashed()` | Controller:16,130 |
| BC-AUTH-02 | `tenant.msh-subject-practical-config.view` | `Gate::authorize('...view')` in `show()` | Controller:62 |
| BC-AUTH-03 | `tenant.msh-subject-practical-config.create` | `Gate::authorize('...create')` in `create()` and `store()` | Controller:27,34 |
| BC-AUTH-04 | `tenant.msh-subject-practical-config.update` | `Gate::authorize('...update')` in `edit()`, `update()`, `toggleStatus()`, `restore()` | Controller:71,78,118,139 |
| BC-AUTH-05 | `tenant.msh-subject-practical-config.delete` | `Gate::authorize('...delete')` in `destroy()` and `forceDelete()` | Controller:103,152 |
| BC-AUTH-06 | `permissionslist.php` entry exists | `'msh-subject-practical-config' => $crud` (full CRUD) | permissionslist.php:618 |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | A subject can have only one practical config per class per academic session | Unique composite on (academic_session_id, class_id, subject_id) | Request:29-33 |
| BC-BIZ-02 | `theory_max_marks` must be non-negative (>= 0) | Validation `min:0` | Request:37 |
| BC-BIZ-03 | `practical_max_marks` must be non-negative (>= 0) | Validation `min:0` | Request:38 |
| BC-BIZ-04 | `has_practical=false` means theory-only — practical_max_marks may be 0 | Logical business rule | Business requirement |
| BC-BIZ-05 | Soft-deleted records can be recreated with same composite key (Request layer) | Unique rule ignores soft-deleted; DB UNIQUE still applies | Request:33 vs DDL |
| BC-BIZ-06 | `created_by` set automatically in store() via controller | `$validatedData['created_by'] = auth()->id()` | Controller:37 |
| BC-BIZ-07 | `updated_by` set automatically in update() via service | Service sets `$data['updated_by'] = $userId` | Service.php:24 |
| BC-BIZ-08 | `edit()` redirects to hub instead of rendering form | Modal-based editing via hub | Controller:73 |
| BC-BIZ-09 | `store()` supports JSON response for AJAX requests | Returns `{status: true, message, redirect}` | Controller:49-55 |
| BC-BIZ-10 | `update()` supports JSON response for AJAX requests | Returns `{status: true, message, redirect}` | Controller:90-95 |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | SubjectPracticalConfig → AcademicSession | `belongsTo(academicSession)` via `academic_session_id` | Model:39-42 |
| BC-REL-02 | SubjectPracticalConfig → SchoolClass | `belongsTo(schoolClass)` via `class_id` | Model:44-47 |
| BC-REL-03 | SubjectPracticalConfig → Subject | `belongsTo(subject)` via `subject_id` | Model:49-52 |
| BC-REL-04 | SubjectPracticalConfig → User (created_by) | `belongsTo(createdBy)` via `created_by` | Model:54-57 |
| BC-REL-05 | SubjectPracticalConfig → User (updated_by) | `belongsTo(updatedBy)` via `updated_by` | Model:59-62 |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab loads in Scheduling hub with `@can('tenant.msh-subject-practical-config.viewAny')` | Tab hidden without permission | `scheduling/tab.blade.php` |
| BC-REF-02 | Search bar with filters for class, subject, session | Conditional toolbar | Tab partial blade |
| BC-REF-03 | Action column shown only for `@canany(['tenant.msh-subject-practical-config.view', 'update', 'delete'])` | Conditional | Tab partial blade |
| BC-REF-04 | Create form — session, class, subject dropdowns | Modal create form | `create.blade.php` |
| BC-REF-05 | Flash keys: `created.subject_practical_config`, `updated.subject_practical_config`, `deleted.subject_practical_config` | Must exist in lang file | Controller:47,88,113 |
| BC-REF-06 | `store()` redirects to hub with `?tab=practical-configs` | Tab-specific redirect | Controller:46 |
| BC-REF-07 | `update()` redirects to hub with `?tab=practical-configs` | Tab-specific redirect | Controller:87 |
| BC-REF-08 | `destroy()` redirects to hub with `?tab=practical-configs` | Tab-specific redirect | Controller:112 |
| BC-REF-09 | `toggleStatus()` returns JSON response | AJAX success | Controller:125 |
| BC-REF-10 | Tab parameter `?tab=practical-configs` appended to pagination links | Blade `->appends(['tab' => 'practical-configs'])` | Tab partial blade |
| BC-REF-11 | Status switch component renders toggle with JS | AJAX POST to toggleStatus route | Tab partial blade |
| BC-REF-12 | Empty state colspan in table | "No records found" when empty | Tab partial `@empty` |
| BC-REF-13 | `trashed()` route: `subject-practical-config/trash/view` | Soft-delete listing | Routes `web.php:63` |
| BC-REF-14 | `restore()` route: `subject-practical-config/{id}/restore` | Restore action | Routes `web.php:64` |
| BC-REF-15 | `forceDelete()` route: `subject-practical-config/{id}/force-delete` | Permanent delete | Routes `web.php:65` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Pagination at 20 per page in `index()` | `SubjectPracticalConfig::with(...)->latest()->paginate(20)` |
| BC-BIZ-DEEP-02 | `store()` sets `created_by` before create | `$validatedData['created_by'] = auth()->id()` |
| BC-BIZ-DEEP-03 | `store()` calls `SubjectPracticalConfig::create()` directly (not via service) | Controller calls Model::create, not service |
| BC-BIZ-DEEP-04 | `update()` delegates to service which wraps in DB::transaction | Service uses `DB::transaction()` |
| BC-BIZ-DEEP-05 | `destroy()` delegates to service which soft-deletes in transaction | Service uses `DB::transaction(fn => $model->delete())` |
| BC-BIZ-DEEP-06 | `toggleStatus()` flips `is_active` to opposite value | `$record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()])` |
| BC-BIZ-DEEP-07 | `toggleStatus()` has NO failure branch — always returns success | Unlike Vehicle controller which has success/failure paths |
| BC-BIZ-DEEP-08 | `restore()` sets `is_active=true` after restore | `$record->restore(); $record->update(['is_active' => true])` |
| BC-BIZ-DEEP-09 | `forceDelete()` catches `QueryException` with code '23000' (FK constraint) | Returns: "Cannot delete this record because it is referenced..." |
| BC-BIZ-DEEP-10 | `forceDelete()` re-throws non-23000 exceptions | `throw $e` for unrelated DB errors |
| BC-BIZ-DEEP-11 | `trashed()` uses `onlyTrashed()` scope | `SubjectPracticalConfig::onlyTrashed()->latest()->paginate(15)` |
| BC-BIZ-DEEP-12 | `show()` loads 3 relationships via `load()` | `$subjectPracticalConfig->load(['academicSession', 'schoolClass', 'subject'])` |
| BC-BIZ-DEEP-13 | activityLog called in store() with type 'Stored' | `activityLog($config, 'Stored', ['message' => 'A new subject practical config was created.'])` |
| BC-BIZ-DEEP-14 | activityLog called in update() with type 'Updated' | `activityLog($subjectPracticalConfig, 'Updated', ['message' => 'The subject practical config was updated.'])` |
| BC-BIZ-DEEP-15 | activityLog called in destroy() with type 'Deleted' | `activityLog($subjectPracticalConfig, 'Deleted', ['message' => 'The subject practical config was deleted.'])` |
| BC-BIZ-DEEP-16 | activityLog called in toggleStatus() with type 'Toggled' | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` |
| BC-BIZ-DEEP-17 | activityLog called in restore() with type 'Restored' | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` |
| BC-BIZ-DEEP-18 | activityLog called in forceDelete() success with type 'Deleted' | `activityLog($record, 'Deleted', ['message' => 'The record was permanently deleted.'])` |
| BC-BIZ-DEEP-19 | No `performed_by` key in any activityLog call | No user attribution — unlike Vendor controller pattern |
| BC-BIZ-DEEP-20 | `toggleStatus()` uses `findOrFail($id)` — manual ID lookup | Not route-model-binding |
| BC-BIZ-DEEP-21 | `restore()` uses `onlyTrashed()->findOrFail($id)` — manual lookup | Only finds soft-deleted records |
| BC-BIZ-DEEP-22 | `forceDelete()` uses `withTrashed()->findOrFail($id)` — finds any record | Both active and trashed records found |
| BC-BIZ-DEEP-23 | `authorize()` method in FormRequest returns `true` | Authorization delegated to controller Gate |
| BC-BIZ-DEEP-24 | `create()` has no dropdown loading — returns empty view | No data passed to create form view |
| BC-BIZ-DEEP-25 | `edit()` immediately redirects — never renders a view | `return redirect()->route(...)` |
| BC-BIZ-DEEP-26 | `index()` has no search filter — only `latest()->paginate(20)` | No `when($request->filled('search'))` block |
| BC-BIZ-DEEP-27 | `index()` does NOT use `withQueryString()` on paginator | No query parameter preservation |
| BC-BIZ-DEEP-28 | Model `$casts` includes `has_practical` as `bool` | Boolean type casting |
| BC-BIZ-DEEP-29 | Model `$casts` includes `theory_max_marks` as `decimal:2` | Decimal precision casting |
| BC-BIZ-DEEP-30 | Model `$casts` includes `practical_max_marks` as `decimal:2` | Decimal precision casting |
| BC-BIZ-DEEP-31 | `$fillable` includes `academic_session_id` (per DB schema) | Additional field in fillable |
| BC-BIZ-DEEP-32 | `$fillable` includes `has_practical`, `theory_max_marks` (additional fields) | More fields than minimal list |
| BC-BIZ-DEEP-33 | `restore()` redirects to `subject-practical-config.trashed` route | `redirect()->route('marksheet-generation.subject-practical-config.trashed')` |
| BC-BIZ-DEEP-34 | `forceDelete()` redirects to `subject-practical-config.trashed` route | Same redirect as restore |
| BC-BIZ-DEEP-35 | `store()` JSON response includes full redirect URL | `route('marksheet-generation.scheduling.combined', ['tab' => 'practical-configs'])` |
| BC-BIZ-DEEP-36 | `update()` JSON response includes same redirect URL | Same pattern as store |
| BC-BIZ-DEEP-37 | All CRUD redirects go to hub with `?tab=practical-configs` | Consistent tab persistence |
| BC-BIZ-DEEP-38 | `SubjectPracticalConfigService::update()` returns `$model->fresh()` | Fresh instance ensures consistent state |
| BC-BIZ-DEEP-39 | No change tracking in `update()` — no `$original`/`$changes` comparison | Unlike Vehicle controller's detailed audit |
| BC-BIZ-DEEP-40 | `SubjectPracticalConfigService::create()` adds `created_by` to data array | `$data['created_by'] = $userId` |
| BC-BIZ-DEEP-41 | `show()` uses explicit `load()` instead of `with()` in query | `load()` after retrieval, not `with()` |
| BC-BIZ-DEEP-42 | `toggleStatus()` updates both `is_active` and `updated_by` in one `update()` call | `$record->update([...])` with both fields |
| BC-BIZ-DEEP-43 | Force delete success path returns hardcoded string: "Record permanently deleted." | Not using `flash()` key |
| BC-BIZ-DEEP-44 | All activityLog messages are hardcoded English strings | Not using `__()` lang helper |
| BC-BIZ-DEEP-45 | DB-level UNIQUE constraint still applies to soft-deleted records | Cannot insert duplicate at DB level even if Request allows |
| BC-BIZ-DEEP-46 | `edit()` has no `findOrFail()` — relies on route-model-binding | Route-model-binding returns 404 automatically |
| BC-BIZ-DEEP-47 | `index()` standalone route is accessible directly (not just via hub) | `SubjectPracticalConfigController::index()` exists |
| BC-BIZ-DEEP-48 | `trashed()` uses `viewAny` gate — same permission as `index()` | Consistent gate between index and trash |
| BC-BIZ-DEEP-49 | `forceDelete()` reuses `delete` permission gate | Not a dedicated `forceDelete` gate |
| BC-BIZ-DEEP-50 | `restore()` reuses `update` permission gate | Not a dedicated `restore` gate |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — SubjectPracticalConfigController Lines 14-23

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 16 | `Gate::authorize('tenant.msh-subject-practical-config.viewAny')` | Authorization gate — user must have viewAny permission |
| 02 | 18-20 | `$configs = SubjectPracticalConfig::with(['academicSession', 'schoolClass', 'subject'])->latest()->paginate(20)` | Query builder with 3 eager loads, ordered by created_at DESC, paginated 20 per page |
| 03 | 22 | `return view('marksheetgeneration::subject-practical-config.index', compact('configs'))` | Return index view with configs collection |

#### CODE-TRACE-02: `create()` — Lines 25-30

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 27 | `Gate::authorize('tenant.msh-subject-practical-config.create')` | Authorization gate — create permission |
| 02 | 29 | `return view('marksheetgeneration::subject-practical-config.create')` | Return create form view (no data passed) |

#### CODE-TRACE-03: `store(SubjectPracticalConfigRequest $request)` — Lines 32-58

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 34 | `Gate::authorize('tenant.msh-subject-practical-config.create')` | Authorization gate |
| 02 | 36 | `$validatedData = $request->validated()` | Validate request against SubjectPracticalConfigRequest rules (8 rules) |
| 03 | 37 | `$validatedData['created_by'] = auth()->id()` | Inject authenticated user ID as creator |
| 04 | 39 | `$config = SubjectPracticalConfig::create($validatedData)` | Mass-assign create new record |
| 05 | 41-43 | `activityLog($config, 'Stored', ['message' => 'A new subject practical config was created.'])` | Activity log entry |
| 06 | 45-47 | `$redirect = redirect()->route('marksheet-generation.scheduling.combined', ['tab' => 'practical-configs'])->with('success', flash('created.subject_practical_config'))` | Build redirect response with success flash |
| 07 | 49-55 | `if ($request->expectsJson()) { return response()->json([...]) }` | JSON response for AJAX/modal requests |
| 08 | 57 | `return $redirect` | Return standard redirect for non-AJAX requests |

#### CODE-TRACE-04: `show(SubjectPracticalConfig $subjectPracticalConfig)` — Lines 60-67

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 62 | `Gate::authorize('tenant.msh-subject-practical-config.view')` | Authorization gate — view permission |
| 02 | 64 | `$subjectPracticalConfig->load(['academicSession', 'schoolClass', 'subject'])` | Eager-load 3 relationships on the resolved model |
| 03 | 66 | `return view('marksheetgeneration::subject-practical-config.show', compact('subjectPracticalConfig'))` | Return show view with loaded model |

#### CODE-TRACE-05: `edit(SubjectPracticalConfig $subjectPracticalConfig)` — Lines 69-74

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 71 | `Gate::authorize('tenant.msh-subject-practical-config.update')` | Authorization gate — update permission |
| 02 | 73 | `return redirect()->route('marksheet-generation.scheduling.combined', ['tab' => 'practical-configs'])` | Redirect to hub — no edit view rendered |

#### CODE-TRACE-06: `update(SubjectPracticalConfigRequest $request, SubjectPracticalConfig $subjectPracticalConfig, SubjectPracticalConfigService $service)` — Lines 76-99

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 78 | `Gate::authorize('tenant.msh-subject-practical-config.update')` | Authorization gate |
| 02 | 80 | `$service->update($subjectPracticalConfig, $request->validated(), (int) auth()->id())` | Delegate update to service (transactional) |
| 03 | 82-84 | `activityLog($subjectPracticalConfig, 'Updated', ['message' => 'The subject practical config was updated.'])` | Activity log entry |
| 04 | 86-88 | `$redirect = redirect()->route('marksheet-generation.scheduling.combined', ['tab' => 'practical-configs'])->with('success', flash('updated.subject_practical_config'))` | Build redirect with flash |
| 05 | 90-95 | `if ($request->expectsJson()) { return response()->json([...]) }` | JSON response for AJAX |
| 06 | 98 | `return $redirect` | Standard redirect |

#### CODE-TRACE-07: `destroy(SubjectPracticalConfig $subjectPracticalConfig, SubjectPracticalConfigService $service)` — Lines 101-114

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 103 | `Gate::authorize('tenant.msh-subject-practical-config.delete')` | Authorization gate |
| 02 | 105 | `$service->delete($subjectPracticalConfig)` | Delegate soft-delete to service (transactional) |
| 03 | 107-109 | `activityLog($subjectPracticalConfig, 'Deleted', ['message' => 'The subject practical config was deleted.'])` | Activity log entry |
| 04 | 111-113 | `return redirect()->route('marksheet-generation.scheduling.combined', ['tab' => 'practical-configs'])->with('success', flash('deleted.subject_practical_config'))` | Redirect to hub with flash |

#### CODE-TRACE-08: `toggleStatus($id)` — Lines 116-126

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 118 | `Gate::authorize('tenant.msh-subject-practical-config.update')` | Authorization gate |
| 02 | 120 | `$record = SubjectPracticalConfig::findOrFail($id)` | Manual lookup by ID (not route-model-binding) |
| 03 | 121 | `$record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()])` | Toggle is_active to opposite value, set updater |
| 04 | 123 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Activity log entry |
| 05 | 125 | `return response()->json(['success' => true, 'is_active' => $record->is_active, 'message' => $record->is_active ? 'Status set to Active' : 'Status set to Inactive'])` | JSON response — always success, no failure branch |

#### CODE-TRACE-09: `trashed()` — Lines 128-135

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 130 | `Gate::authorize('tenant.msh-subject-practical-config.viewAny')` | Authorization gate — same permission as index() |
| 02 | 132 | `$trashed = SubjectPracticalConfig::onlyTrashed()->latest()->paginate(15)` | Fetch soft-deleted records only, paginated 15 per page |
| 03 | 134 | `return view('marksheetgeneration::trashed.subject-practical-config', compact('trashed'))` | Return trash view |

#### CODE-TRACE-10: `restore($id)` — Lines 137-148

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 139 | `Gate::authorize('tenant.msh-subject-practical-config.update')` | Authorization gate — uses UPDATE permission, not RESTORE |
| 02 | 141 | `$record = SubjectPracticalConfig::onlyTrashed()->findOrFail($id)` | Find soft-deleted record or 404 |
| 03 | 142 | `$record->restore()` | Restore (set deleted_at = NULL) |
| 04 | 143 | `$record->update(['is_active' => true])` | Reactivate the restored record |
| 05 | 145 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Activity log entry |
| 06 | 147 | `return redirect()->route('marksheet-generation.subject-practical-config.trashed')->with('success', 'Record restored successfully.')` | Redirect to trash page with hardcoded success message |

#### CODE-TRACE-11: `forceDelete($id)` — Lines 150-166

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 152 | `Gate::authorize('tenant.msh-subject-practical-config.delete')` | Authorization gate — uses DELETE permission, not FORCE-DELETE |
| 02 | 154 | `$record = SubjectPracticalConfig::withTrashed()->findOrFail($id)` | Find ANY record (active or trashed) or 404 |
| 03 | 156 | `$record->forceDelete()` | Permanently delete record from DB |
| 04 | 157 | `activityLog($record, 'Deleted', ['message' => 'The record was permanently deleted.'])` | Activity log entry |
| 05 | 158-162 | `catch (QueryException $e) { if ($e->getCode() === '23000') { return redirect()->back()->with('error', 'Cannot delete this record because it is referenced by other records. Remove those references first.'); } throw $e; }` | FK constraint violation handler — returns user-friendly error |
| 06 | 165 | `return redirect()->route('marksheet-generation.subject-practical-config.trashed')->with('success', 'Record permanently deleted.')` | Success redirect to trash page |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create practical config with all fields | Fill all fields: academic_session, class, subject, has_practical=true, theory_max_marks=80, practical_max_marks=20 | Config created, activityLog 'Stored', redirect to hub with flash |
| TC-P-02 | Create theory-only config (has_practical=false) | has_practical=false, theory_max_marks=100, practical_max_marks=0 | Theory-only config created successfully |
| TC-P-03 | Update config — change theory_max_marks | Change theory_max_marks from 80 to 75 | Updated, activityLog 'Updated' recorded |
| TC-P-04 | Update config — change has_practical flag | Toggle has_practical from true to false | Config updated successfully |
| TC-P-05 | Toggle status active→inactive | Click status switch on active config | AJAX returns {success:true, is_active:false}, activityLog 'Toggled' |
| TC-P-06 | View config details | Click show action on a config row | Show page with 3 relation data loaded |
| TC-P-07 | Toggle status inactive→active (bidirectional) | Click status switch on inactive config | JSON {success:true, is_active:true} |
| TC-P-08 | Restore soft-deleted config | Navigate to trash, click Restore | Config restored, is_active=true, activityLog 'Restored' |
| TC-P-09 | Force delete config with no FK references | Trash → Force Delete | Record permanently deleted, activityLog 'Deleted' |
| TC-P-10 | Submit store via AJAX (modal create) | POST with Accept:application/json | JSON response {status:true, message, redirect} |
| TC-P-11 | Submit update via AJAX (modal edit) | PUT with Accept:application/json | JSON response {status:true, message, redirect} |
| TC-P-12 | Create config with decimal mark values | theory_max_marks=85.50, practical_max_marks=14.50 | Decimal marks stored with 2 decimal precision |
| TC-P-13 | Verify activityLog type 'Stored' message content | Query activity log after store | "A new subject practical config was created." |
| TC-P-14 | Verify activityLog type 'Updated' message content | Query activity log after update | "The subject practical config was updated." |
| TC-P-15 | Verify activityLog type 'Deleted' message content | Query activity log after destroy | "The subject practical config was deleted." |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty academic_session_id | Submit without academic session | "The academic session id field is required." |
| TC-N-02 | Create with empty class_id | Submit without class | "The class id field is required." |
| TC-N-03 | Create with empty subject_id | Submit without subject | "The subject id field is required." |
| TC-N-04 | Create with empty theory_max_marks | Submit without theory marks | "The theory max marks field is required." |
| TC-N-05 | Create with empty practical_max_marks | Submit without practical marks | "The practical max marks field is required." |
| TC-N-06 | Create with negative theory_max_marks | theory_max_marks=-10 | "The theory max marks must be at least 0." |
| TC-N-07 | Create with negative practical_max_marks | practical_max_marks=-5 | "The practical max marks must be at least 0." |
| TC-N-08 | Create with duplicate composite key | Same (academic_session, class, subject) as existing | "The class id has already been taken." |
| TC-N-09 | Create with invalid academic_session_id | academic_session_id=99999 | "The selected academic session id is invalid." |
| TC-N-10 | Create with invalid class_id | class_id=99999 | "The selected class id is invalid." |
| TC-N-11 | Create with invalid subject_id | subject_id=99999 | "The selected subject id is invalid." |
| TC-N-12 | Access index without viewAny permission | User lacks viewAny | 403 Access Denied |
| TC-N-13 | Access create without create permission | User lacks create | 403 Access Denied |
| TC-N-14 | Access show without view permission | User lacks view | 403 Access Denied |
| TC-N-15 | Access update without update permission | User lacks update | 403 Access Denied |
| TC-N-16 | Access destroy without delete permission | User lacks delete | 403 Access Denied |
| TC-N-17 | Force delete config with FK references | Config referenced by IA marks | Friendly error: "Cannot delete this record because it is referenced..." |
| TC-N-18 | Restore non-trashed (active) config | Call restore on active record | 404 — onlyTrashed() finds no record |
| TC-N-19 | Show non-existent config ID | Navigate to show/99999 | 404 Not Found |
| TC-N-20 | Force delete non-trashed (active) config | Call forceDelete on active record | Works — withTrashed() finds any record |
| TC-N-21 | Create with non-boolean has_practical | has_practical="invalid" | "The has practical field must be true or false." |
| TC-N-22 | Store with theory_max_marks as string | theory_max_marks="abc" | "The theory max marks must be a number." |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | Unauthorized access to index | User lacks viewAny | 403 via Gate::authorize at line 16 |
| TC-SQ-02 | Unauthorized access to create | User lacks create | 403 via Gate::authorize at line 27 |
| TC-SQ-03 | Unauthorized POST to store | User lacks create | 403 via Gate::authorize at line 34 |
| TC-SQ-04 | Unauthorized PUT to update | User lacks update | 403 via Gate::authorize at line 78 |
| TC-SQ-05 | Unauthorized DELETE to destroy | User lacks delete | 403 via Gate::authorize at line 103 |
| TC-SQ-06 | Unauthorized forceDelete | User lacks delete | 403 via Gate::authorize at line 152 |
| TC-SQ-07 | Unauthorized restore | User lacks update | 403 via Gate::authorize at line 139 |
| TC-SQ-08 | Unauthorized toggleStatus | User lacks update | 403 via Gate::authorize at line 118 |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | Hub loads practical-configs tab | Navigate to scheduling hub with tab=practical-configs | Configs listed with pagination |
| TC-INT-02 | Pagination with pc_page parameter | Navigate to page 2 via pc_page=2 | Page 2 loaded, tab preserved in URL |
| TC-INT-03 | Tab isolation — only configs shown | Other scheduling tabs show different data | No cross-tab data pollution |
| TC-INT-04 | Redirect after store keeps tab | POST store → redirect to hub | URL has ?tab=practical-configs |
| TC-INT-05 | Redirect after destroy keeps tab | DELETE destroy → redirect to hub | URL has ?tab=practical-configs |
| TC-INT-06 | Trash-to-restore lifecycle | Soft delete → trash → restore → hub | Record back in list, active |

---

## 7. Detailed Test Steps

### TC-P-01: Create practical config with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-subject-practical-config.create` permission | Success — user authenticated |
| 2 | Navigate to practical config create page (`/subject-practical-config/create`) | Create form displayed with all input fields |
| 3 | Select academic_session_id=1 from dropdown | Session selected |
| 4 | Select class_id=1 from dropdown | Class selected |
| 5 | Select subject_id=1 from dropdown | Subject selected |
| 6 | Set has_practical toggle to true (ON) | Practical exam flag enabled |
| 7 | Enter theory_max_marks=80 in numeric input | Theory max marks set to 80 |
| 8 | Enter practical_max_marks=20 in numeric input | Practical max marks set to 20 |
| 9 | Click "Save" or "Submit" button | POST request to store route |
| 10 | **Verify**: `Gate::authorize('tenant.msh-subject-practical-config.create')` at line 34 passes | User authorized |
| 11 | **Verify**: `SubjectPracticalConfigRequest` validation rules pass (all 8 rules) | No validation errors |
| 12 | **Verify**: `$validatedData['created_by'] = auth()->id()` at line 37 | created_by set to current user ID |
| 13 | **Verify**: `SubjectPracticalConfig::create($validatedData)` inserts a new row in DB | Record exists in `msh_subject_practical_configs` |
| 14 | **Verify**: `activityLog($config, 'Stored', ['message' => 'A new subject practical config was created.'])` called at lines 41-43 | Activity log entry created |
| 15 | **Verify**: Redirected to `marksheet-generation.scheduling.combined?tab=practical-configs` | Hub page loaded with practical-configs tab |
| 16 | **Verify**: Flash message `flash('created.subject_practical_config')` displayed | Success notification visible |
| 17 | **Verify**: New config visible in the practical-configs tab list | Record appears in paginated table |

### TC-P-02: Create theory-only config (has_practical=false)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Navigate to create page | Form displayed |
| 3 | Fill all required fields (session, class, subject) | Fields populated |
| 4 | Set has_practical=false (toggle OFF) | Practical disabled |
| 5 | Enter theory_max_marks=100 | Full marks for theory |
| 6 | Enter practical_max_marks=0 | Zero practical marks |
| 7 | Click "Save" | POST request |
| 8 | **Verify**: Validation `min:0` passes on practical_max_marks | No error |
| 9 | **Verify**: DB record has `has_practical=0`, `practical_max_marks=0.00` | Theory-only config stored |
| 10 | **Verify**: `activityLog()` recorded | Activity log entry "Stored" |

### TC-P-03: Update config — change theory_max_marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-subject-practical-config.update` permission | Success |
| 2 | Submit PUT/PATCH request with changed `theory_max_marks=75` | Update request |
| 3 | **Verify**: `Gate::authorize('tenant.msh-subject-practical-config.update')` at line 78 passes | Authorized |
| 4 | **Verify**: `SubjectPracticalConfigService::update()` called at line 80 | Service handles update transactionally |
| 5 | **Verify**: DB `theory_max_marks` updated to 75.00 | Value changed |
| 6 | **Verify**: `activityLog($model, 'Updated', ['message' => 'The subject practical config was updated.'])` at lines 82-84 | "Updated" logged |
| 7 | **Verify**: Redirect to hub with `?tab=practical-configs` at lines 86-88 | Tab preserved |
| 8 | **Verify**: Flash message `flash('updated.subject_practical_config')` | Success notification |

### TC-P-04: Update config — toggle has_practical

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit PUT with `has_practical=false` (was true) | Update request |
| 2 | **Verify**: Validation `sometimes|boolean` passes | No error |
| 3 | **Verify**: DB `has_practical` changed to 0 | Updated |
| 4 | **Verify**: Redirect + flash | Confirmation shown |

### TC-P-05: Toggle status active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-subject-practical-config.update` permission | Success |
| 2 | Navigate to scheduling hub → practical-configs tab | Config list displayed |
| 3 | Locate a config with is_active=true (green toggle) | Status ON |
| 4 | Click the status toggle switch | AJAX POST to `toggleStatus` route |
| 5 | **Verify**: `Gate::authorize('tenant.msh-subject-practical-config.update')` at line 118 passes | Authorized |
| 6 | **Verify**: `SubjectPracticalConfig::findOrFail($id)` at line 120 finds the record | Record found |
| 7 | **Verify**: `$record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()])` at line 121 | is_active set to false, updated_by set |
| 8 | **Verify**: `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` at line 123 | "Toggled" logged |
| 9 | **Verify**: JSON response `{success: true, is_active: false, message: "Status set to Inactive"}` at line 125 | Success response |
| 10 | **Verify**: Toggle switch now shows OFF state in UI | Visual confirmation |

### TC-P-06: View config details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-subject-practical-config.view` permission | Success |
| 2 | Click view/show icon on a config in the table | GET request to show route |
| 3 | **Verify**: `Gate::authorize('tenant.msh-subject-practical-config.view')` at line 62 passes | Authorized |
| 4 | **Verify**: `$subjectPracticalConfig->load(['academicSession', 'schoolClass', 'subject'])` at line 64 | 3 relationships loaded |
| 5 | **Verify**: Show page renders all fields with relation data | Full details visible |

### TC-P-07: Toggle status inactive→active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Success |
| 2 | Locate config with is_active=false | Status OFF |
| 3 | Click status toggle | AJAX POST |
| 4 | **Verify**: `is_active` flips to true | JSON `{is_active: true}` |
| 5 | **Verify**: Message = "Status set to Active" | Correct phase |

### TC-P-08: Restore soft-deleted config

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-subject-practical-config.update` permission | Success |
| 2 | Navigate to trash page | Trashed configs listed |
| 3 | Click "Restore" on a trashed config | GET request to restore route |
| 4 | **Verify**: `Gate::authorize('tenant.msh-subject-practical-config.update')` at line 139 passes | Authorized |
| 5 | **Verify**: `SubjectPracticalConfig::onlyTrashed()->findOrFail($id)` at line 141 | Trashed record found |
| 6 | **Verify**: `$record->restore()` at line 142 | `deleted_at` set to NULL |
| 7 | **Verify**: `$record->update(['is_active' => true])` at line 143 | Record reactivated |
| 8 | **Verify**: `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` at line 145 | "Restored" logged |
| 9 | **Verify**: Redirected to trash page with "Record restored successfully." | Confirmation |
| 10 | Navigate to hub practical-configs tab | Config visible (active) |

### TC-P-09: Force delete with no FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-subject-practical-config.delete` permission | Success |
| 2 | Navigate to trash page | Trashed configs |
| 3 | Click "Force Delete" on a trashed config | DELETE request |
| 4 | **Verify**: `Gate::authorize('tenant.msh-subject-practical-config.delete')` at line 152 passes | Authorized |
| 5 | **Verify**: `SubjectPracticalConfig::withTrashed()->findOrFail($id)` at line 154 | Record found |
| 6 | **Verify**: `$record->forceDelete()` at line 156 succeeds (no FK references) | Permanently removed |
| 7 | **Verify**: `activityLog($record, 'Deleted', ['message' => 'The record was permanently deleted.'])` at line 157 | "Deleted" logged |
| 8 | **Verify**: Redirect to trash with "Record permanently deleted." | Success message |
| 9 | **Verify**: Record no longer exists in DB | Permanently deleted |

### TC-P-10: Store via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST valid data with `Accept: application/json` header | AJAX request |
| 2 | **Verify**: `$request->expectsJson()` at line 49 returns true | JSON path taken |
| 3 | **Verify**: Response `{status: true, message: "Subject practical config created.", redirect: "..."}` | JSON response |
| 4 | **Verify**: HTTP status 200 | Success |

### TC-P-11: Update via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT valid data with `Accept: application/json` header | AJAX request |
| 2 | **Verify**: `$request->expectsJson()` at line 90 returns true | JSON path |
| 3 | **Verify**: Response `{status: true, message: "Subject practical config updated.", redirect: "..."}` | JSON |
| 4 | **Verify**: HTTP 200 | Success |

### TC-P-12: Create with decimal marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with `theory_max_marks=85.50`, `practical_max_marks=14.50` | Decimal input |
| 2 | **Verify**: DB stores 85.50 and 14.50 | Decimal(10,2) precision preserved |
| 3 | **Verify**: Model cast `decimal:2` returns proper decimal values | Correct type |

### TC-P-13: Verify activityLog 'Stored'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After TC-P-01, query `activity_log` table | Entry exists |
| 2 | **Verify**: `type` = "Stored" | Correct action type |
| 3 | **Verify**: `message` = "A new subject practical config was created." | Correct message |
| 4 | **Verify**: `loggable_type` = SubjectPracticalConfig model class | Proper morph mapping |

### TC-P-14: Verify activityLog 'Updated'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After TC-P-03, check `activity_log` | Entry exists |
| 2 | **Verify**: `type` = "Updated" | Correct |
| 3 | **Verify**: `message` = "The subject practical config was updated." | Correct |

### TC-P-15: Verify activityLog 'Deleted'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After destroy, check `activity_log` | Entry exists |
| 2 | **Verify**: `type` = "Deleted" | Correct |
| 3 | **Verify**: `message` = "The subject practical config was deleted." | Correct |

### TC-N-01: Create with empty academic_session_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave `academic_session_id` empty | Missing |
| 2 | Fill all other required fields | Complete |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: `required` validation on `academic_session_id` | "The academic session id field is required." |
| 5 | **Verify**: No record created | DB unchanged |

### TC-N-02 through TC-N-11: Similar validation error patterns for required/exists/unique rules.

### TC-N-12 through TC-N-16: Each verifies 403 Forbidden for unauthorized access.

### TC-N-17: Force delete with FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure config has related student IA mark records | FK constraints exist |
| 2 | Soft-delete the config | Trashed |
| 3 | Navigate to trash page | Config in trash |
| 4 | Click "Force Delete" | DELETE to forceDelete |
| 5 | **Verify**: `$record->forceDelete()` throws `QueryException 23000` at line 158 | FK violation |
| 6 | **Verify**: Catch block at lines 158-162 returns friendly error | "Cannot delete this record because it is referenced by other records." |
| 7 | **Verify**: Record NOT deleted | Still exists in DB |

### TC-N-18 through TC-N-22: Standard negative test patterns.

### TC-SQ-01 through TC-SQ-08: Each verifies 403 Forbidden with specific Gate assertions.

### TC-INT-01 through TC-INT-06: Integration tests for hub loading, pagination, redirects.

---

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Verify Gate in index() | Controller:16 | `tenant.msh-subject-practical-config.viewAny` |
| TC-CR-02 | Verify Gate in show() | Controller:62 | `tenant.msh-subject-practical-config.view` |
| TC-CR-03 | Verify Gate in create() | Controller:27 | `tenant.msh-subject-practical-config.create` |
| TC-CR-04 | Verify Gate in store() | Controller:34 | `tenant.msh-subject-practical-config.create` |
| TC-CR-05 | Verify Gate in edit() | Controller:71 | `tenant.msh-subject-practical-config.update` |
| TC-CR-06 | Verify Gate in update() | Controller:78 | `tenant.msh-subject-practical-config.update` |
| TC-CR-07 | Verify Gate in destroy() | Controller:103 | `tenant.msh-subject-practical-config.delete` |
| TC-CR-08 | Verify Gate in toggleStatus() | Controller:118 | `tenant.msh-subject-practical-config.update` |
| TC-CR-09 | Verify Gate in trashed() | Controller:130 | `tenant.msh-subject-practical-config.viewAny` |
| TC-CR-10 | Verify Gate in restore() | Controller:139 | `tenant.msh-subject-practical-config.update` (not restore) |
| TC-CR-11 | Verify Gate in forceDelete() | Controller:152 | `tenant.msh-subject-practical-config.delete` (not forceDelete) |
| TC-CR-12 | Verify activityLog 'Stored' in store() | Controller:41-43 | Message: "A new subject practical config was created." |
| TC-CR-13 | Verify activityLog 'Updated' in update() | Controller:82-84 | Message: "The subject practical config was updated." |
| TC-CR-14 | Verify activityLog 'Deleted' in destroy() | Controller:107-109 | Message: "The subject practical config was deleted." |
| TC-CR-15 | Verify activityLog 'Toggled' in toggleStatus() | Controller:123 | Message: "Status was toggled." |
| TC-CR-16 | Verify activityLog 'Restored' in restore() | Controller:145 | Message: "The record was restored." |
| TC-CR-17 | Verify activityLog in forceDelete() | Controller:157 | Message: "The record was permanently deleted." |
| TC-CR-18 | Verify no performed_by in activityLog calls | All activityLog | Missing performed_by key — GAP vs Vendor pattern |
| TC-CR-19 | Verify JSON response in store() | Controller:49-55 | `{status:true, message, redirect}` |
| TC-CR-20 | Verify JSON response in update() | Controller:90-95 | `{status:true, message, redirect}` |
| TC-CR-21 | Verify toggleStatus always succeeds | Controller:125 | No failure branch — always `{success:true}` |
| TC-CR-22 | Verify FK 23000 catch in forceDelete() | Controller:158-162 | Friendly error, re-throws non-23000 |
| TC-CR-23 | Verify restore() sets is_active=true | Controller:143 | `$record->update(['is_active' => true])` |
| TC-CR-24 | Verify edit() redirects | Controller:73 | No view, immediate redirect to hub |
| TC-CR-25 | Verify unique composite validation | Request:29-33 | `Rule::unique(...)->where(...)->ignore($id)` |
| TC-CR-26 | Verify prepareForValidation casts | Request:46-48 | `(int)` casting for FK fields |
| TC-CR-27 | Verify $casts on model | Model:32-37 | bool for has_practical/is_active, decimal:2 for marks |
| TC-CR-28 | Verify 5 relationships | Model:39-62 | academicSession, schoolClass, subject, createdBy, updatedBy |
| TC-CR-29 | Verify soft-delete trait | Model:16 | `use SoftDeletes` |
| TC-CR-30 | Verify $fillable includes all columns | Model:20-30 | 9 fillable fields |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Soft-delete sets deleted_at | Call destroy(), check DB | `deleted_at` IS NOT NULL, `is_active` unchanged (not set to false unlike Vehicle) |
| TC-D-02 | Force delete removes record entirely | Call forceDelete(), check DB | Record removed from `msh_subject_practical_configs` |
| TC-D-03 | Restore sets deleted_at=NULL | Call restore(), check DB | `deleted_at` = NULL, `is_active` = true |
| TC-D-04 | Composite unique at DB level | Insert duplicate via DB raw | DB constraint violation (23000) |
| TC-D-05 | Verify FK on academic_session_id | Delete referenced academic session | FK constraint behavior per migration |
| TC-D-06 | Verify FK on class_id | Delete referenced class | FK constraint behavior |
| TC-D-07 | Verify FK on subject_id | Delete referenced subject | FK constraint behavior |
| TC-D-08 | Verify toggleStatus updates updated_by | Toggle, check DB | `updated_by` = current user ID |
| TC-D-09 | Verify decimal precision (10,2) | Store 80.00, check DB | Stored as 80.00 with 2 decimal places |
| TC-D-10 | Verify boolean casting for has_practical | Store 0/1, retrieve | Returns true/false (boolean, not int) |
| TC-D-11 | Verify created_by auto-set on create | Store, check DB | `created_by` = authenticated user ID |
| TC-D-12 | Verify service fresh() after update | Update, check returned model | `$model->fresh()` returns reloaded instance |

## 8. Test Environment Requirements

| # | Requirement | Details |
|---|-------------|---------|
| TE-01 | Laravel PHP Framework | Version 10.x+ with Gate authorization |
| TE-02 | Database | MySQL 8.0+ with InnoDB engine (FK support) |
| TE-03 | Permissions config | `config/permissionslist.php` with `msh-subject-practical-config` entry |
| TE-04 | Test user roles | Users with each permission level (viewAny, view, create, update, delete) |
| TE-05 | Reference data | Academic sessions, classes, subjects must exist in DB |
| TE-06 | Activity log table | `activity_log` table must exist and be writable |
| TE-07 | Soft-delete columns | `deleted_at` column on `msh_subject_practical_configs` |
| TE-08 | Route registration | All routes in `routes/web.php` loaded via `RouteServiceProvider` |
| TE-09 | Browser | Modern browser with JavaScript enabled for AJAX toggle |
| TE-10 | Test data cleanup | Each test should clean up created records to avoid state pollution |

## 9. Test Execution Notes

| # | Note | Details |
|---|------|---------|
| TN-01 | Sequential execution | TC-N-17 (FK force delete) requires existing IA mark records referencing the config |
| TN-02 | Permission tests | TC-SQ-01 through TC-SQ-08 require separate user accounts with specific permission sets |
| TN-03 | AJAX tests | TC-P-10, TC-P-11 require `Accept: application/json` header |
| TN-04 | Trash tests | TC-P-08, TC-P-09 require prior soft-delete via store+destroy |
| TN-05 | Composite unique test | TC-N-08 requires an existing record with the same composite key |
| TN-06 | Tab persistence | All redirect tests must verify the `?tab=practical-configs` query parameter |
| TN-07 | activityLog assertion | All positive test cases should verify activityLog was called with correct type and message |
| TN-08 | FK 23000 re-throw | forceDelete re-throws non-23000 QueryExceptions — test with DB error simulation |

### TC-P-01 detailed verification steps (continued)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 18 | Verify pagination shows correct page count | 20 per page in standalone, 15 in hub |
| 19 | Verify academic session name displayed via relation | Session name shown |
| 20 | Verify school class name displayed via relation | Class name shown |
| 21 | Verify subject name displayed via relation | Subject name shown |
| 22 | Verify theory_max_marks formatted with 2 decimals | 80.00 displayed |
| 23 | Verify practical_max_marks formatted with 2 decimals | 20.00 displayed |

### TC-P-02 detailed verification steps

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-subject-practical-config.create` | Authenticated |
| 2 | Navigate to create page | Form displayed |
| 3 | Fill academic_session_id, class_id, subject_id | Required dropdowns |
| 4 | Set has_practical toggle to OFF (false) | Practical disabled |
| 5 | Enter theory_max_marks=100 | Max theory |
| 6 | Enter practical_max_marks=0 | Zero practical |
| 7 | Click Save | POST request |
| 8 | Verify validation passes — no errors on practical_max_marks=0 | Valid |
| 9 | Verify DB has_practical=0 | Stored correctly |
| 10 | Verify DB practical_max_marks=0.00 | Zero stored |
| 11 | Verify activityLog recorded with type 'Stored' | Logged |

### TC-P-03 detailed verification steps

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-subject-practical-config.update` | Authenticated |
| 2 | Navigate to scheduling hub → practical-configs tab | Config list |
| 3 | Click edit action | Redirect to hub (edit() redirects) |
| 4 | Submit PUT request with theory_max_marks=75 | Update |
| 5 | Verify Gate at Controller:78 passes | Authorized |
| 6 | Verify Service::update() called with validated data | Transaction wraps |
| 7 | Verify updated_by set to auth()->id() | Set |
| 8 | Verify DB theory_max_marks=75.00 | Changed |
| 9 | Verify activityLog 'Updated' at lines 82-84 | "The subject practical config was updated." |
| 10 | Verify redirect to hub with ?tab=practical-configs | Tab preserved |
| 11 | Verify flash('updated.subject_practical_config') | Message shown |

### TC-P-04 detailed verification steps

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit PUT with has_practical=false (was true) | Update |
| 2 | Verify validation passes (sometimes|boolean) | No error |
| 3 | Verify DB has_practical = 0 | Changed |
| 4 | Verify redirect + flash | Confirmation |

### TC-P-05 detailed verification steps

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-subject-practical-config.update` | Authenticated |
| 2 | Navigate to hub → practical-configs tab | List |
| 3 | Locate config with is_active=true (green toggle) | Active |
| 4 | Click status toggle switch | AJAX POST |
| 5 | Verify Gate at line 118 passes | Authorized |
| 6 | Verify findOrFail($id) at line 120 | Found |
| 7 | Verify is_active flipped to false at line 121 | Changed |
| 8 | Verify updated_by set to auth()->id() | Set |
| 9 | Verify activityLog 'Toggled' at line 123 | "Status was toggled." |
| 10 | Verify JSON response {success:true, is_active:false, message:"Status set to Inactive"} | Correct |
| 11 | Verify toggle UI updated to OFF | Visual |

### TC-P-06 through TC-P-15 follow the same detailed step pattern with Gate, DB, activityLog, and redirect assertions.

### TC-N-01 detailed verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave academic_session_id unselected | Empty |
| 2 | Fill all other fields | Complete |
| 3 | Click Save | POST |
| 4 | Verify `required` validation fails | "The academic session id field is required." |
| 5 | Verify no DB record created | Unchanged |
| 6 | Verify form re-displayed with error | Error visible |

### TC-N-02 through TC-N-07: Similar required/numeric/min validation patterns.

### TC-N-08 detailed verification (duplicate composite)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create config with (session=1, class=1, subject=1) | First record created |
| 2 | Attempt second config with same composite key | Duplicate |
| 3 | Click Save | POST |
| 4 | Verify `Rule::unique(...)->where(...)` at Request:29-33 | "The class id has already been taken." |
| 5 | Verify no duplicate created | DB unique maintained |

### TC-N-09 through TC-N-11: Invalid FK references — exists validation fails.

### TC-N-12 through TC-N-16: Each tests 403 Forbidden for missing permission.

### TC-N-17 detailed verification (FK 23000)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure config has related student IA mark records | FK exists |
| 2 | Soft-delete config (destroy) | Trashed |
| 3 | Navigate to trash | Listed |
| 4 | Click Force Delete | DELETE |
| 5 | Verify forceDelete() at line 156 throws QueryException | 23000 code |
| 6 | Verify catch block at 158-162 catches it | User-friendly message returned |
| 7 | Verify record NOT deleted | Still in DB |
| 8 | Verify redirect back with error message | Error shown |

### TC-N-18 through TC-N-22: Additional negative test patterns.

### TC-SQ-01 detailed verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.msh-subject-practical-config.viewAny` | No permission |
| 2 | Access index route /subject-practical-config | 403 Forbidden |
| 3 | Verify exception thrown by Gate::authorize at line 16 | AuthorizationException |
| 4 | Verify no data returned | Forbidden page |

### TC-SQ-02 through TC-SQ-08: Similar 403 patterns for each permission level.

### TC-INT-01 detailed verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-subject-practical-config.viewAny` | Success |
| 2 | Navigate to `marksheet-generation.scheduling.combined?tab=practical-configs` | Hub page |
| 3 | Verify practical-configs tab is active | Tab highlighted |
| 4 | Verify configs are listed in table | Data displayed |
| 5 | Verify pagination links show correct count | Paginator visible |
| 6 | Verify status switches and action buttons rendered | Components work |

### TC-INT-02 through TC-INT-06: Integration patterns for pagination, isolation, redirects.

---

## 10. Observations & Gaps

| # | Observation | Severity | Details |
|---|-------------|----------|---------|
| OBS-01 | No `performed_by` in activityLog calls | Low | All activityLog() calls omit performed_by key — audit trail lacks user attribution |
| OBS-02 | toggleStatus has no failure branch | Low | Unlike VehicleController which has success/failure paths, this always returns success |
| OBS-03 | edit() does not load record data — immediately redirects | Info | Intentional design: modal-based editing via hub, but edit route exists |
| OBS-04 | No search/status filter in index() | Medium | index() only does latest()->paginate(20) — no search or status filtering unlike Vehicle |
| OBS-05 | restore() uses update permission instead of restore | Low | Gate::authorize('...update') instead of '...restore' |
| OBS-06 | forceDelete() uses delete permission instead of forceDelete | Low | Gate::authorize('...delete') instead of '...forceDelete' |
| OBS-07 | No withQueryString() on paginator | Low | index() pagination loses query params |
| OBS-08 | Restore success message is hardcoded string | Low | "Record restored successfully." not using flash() key |
| OBS-09 | Force delete success message is hardcoded string | Low | "Record permanently deleted." not using flash() key |
| OBS-10 | store() calls Model::create directly, not via service | Info | Controller directly calls create — inconsistent with update() and destroy() which use service |

---

## 11. CODE-TRACE: Complete Controller Method Analysis

### SubjectPracticalConfigController — Method-by-Method Trace

| # | Method | File:Line | Gate | Key Logic | Return |
|---|--------|-----------|------|-----------|--------|
| T01 | `index()` | Controller:15-25 | `tenant.msh-subject-practical-config.viewAny` | `SubjectPracticalConfig::query()->latest()->paginate(20)` | view with compact('records') |
| T02 | `create()` | Controller:27-31 | `tenant.msh-subject-practical-config.create` | Returns view with form | view |
| T03 | `store()` | Controller:33-56 | `tenant.msh-subject-practical-config.create` | `create($request->validated())` + activityLog + JSON response | JSON (AJAX) |
| T04 | `show()` | Controller:58-63 | `tenant.msh-subject-practical-config.view` | `findOrFail($id)` | view |
| T05 | `edit()` | Controller:65-75 | `tenant.msh-subject-practical-config.update` | `findOrFail($id)` | view |
| T06 | `update()` | Controller:77-97 | `tenant.msh-subject-practical-config.update` | `Service::update($request->validated(), $id)` + activityLog | JSON |
| T07 | `destroy()` | Controller:99-113 | `tenant.msh-subject-practical-config.delete` | `Service::trash($id)` + activityLog + set is_active=0 | JSON |
| T08 | `toggleStatus()` | Controller:115-127 | `tenant.msh-subject-practical-config.update` | `$record->update(...)` + activityLog | JSON |
| T09 | `trashed()` | Controller:129-135 | `tenant.msh-subject-practical-config.viewAny` | `onlyTrashed()->paginate(20)` | view |
| T10 | `restore()` | Controller:137-148 | `tenant.msh-subject-practical-config.update` | `restore()` + `update(['is_active'=>true])` + activityLog | redirect |
| T11 | `forceDelete()` | Controller:150-165 | `tenant.msh-subject-practical-config.delete` | try: `forceDelete()` + activityLog — catch(23000): friendly error | redirect |

### CODE-TRACE: Service Layer

| # | Method | File:Line | Operation |
|---|--------|-----------|-----------|
| S01 | `SubjectPracticalConfigService::update()` | Service:1-15 | BeginTransaction → update + set updated_by → commit |
| S02 | `SubjectPracticalConfigService::trash()` | Service:16-30 | set is_active=false → save → delete → commit |
| S03 | `SubjectPracticalConfigService::restoreRecord()` | Service:31-45 | restore() → update is_active=true → commit |

### CODE-TRACE: Validation Rules

| # | Field | Rule (Create/Store) | Rule (Update) | Source |
|---|-------|---------------------|---------------|--------|
| V01 | academic_session_id | required, exists | sometimes, integer, exists | Request:29 |
| V02 | class_id | required, exists, unique per session+subject | sometimes, integer, exists, unique...$id | Request:30-33 |
| V03 | subject_id | required, exists | sometimes, integer, exists | Request:34 |
| V04 | has_practical | required, boolean | sometimes, boolean | Request:35 |
| V05 | theory_max_marks | required, numeric, min:0, max:100 | sometimes, numeric, min:0, max:100 | Request:36 |
| V06 | practical_max_marks | required, numeric, min:0, max:100 | sometimes, numeric, min:0, max:100 | Request:37 |
| V07 | total_max_marks | required, numeric, min:0, max:100 | sometimes, numeric, min:0, max:100 | Request:38 |

### CODE-TRACE: Model Configuration

| # | Property | Value | Source |
|---|----------|-------|--------|
| M01 | Table | `msh_subject_practical_configs` | Model:14 |
| M02 | Primary Key | `id` (auto-increment) | Default |
| M03 | Fillable | 9 fields | Model:20-30 |
| M04 | Casts | `has_practical`→bool, `is_active`→bool, marks→decimal:2 | Model:32-37 |
| M05 | Soft Delete | `use SoftDeletes` | Model:16 |
| M06 | Relationships | academicSession, schoolClass, subject, createdBy, updatedBy | Model:39-62 |
| M07 | Timestamps | `created_at`, `updated_at`, `deleted_at` | SoftDeletes |

---

## 12. Route Registration

| Route | Method | Controller Action | Permission |
|-------|--------|-------------------|------------|
| `subject-practical-config.index` | GET | index() | viewAny |
| `subject-practical-config.create` | GET | create() | create |
| `subject-practical-config.store` | POST | store() | create |
| `subject-practical-config.show` | GET | show() | view |
| `subject-practical-config.edit` | GET | edit() | update |
| `subject-practical-config.update` | PUT | update() | update |
| `subject-practical-config.destroy` | DELETE | destroy() | delete |
| `subject-practical-config.toggleStatus` | POST | toggleStatus() | update |
| `subject-practical-config.trashed` | GET | trashed() | viewAny |
| `subject-practical-config.restore` | GET | restore() | update |
| `subject-practical-config.forceDelete` | DELETE | forceDelete() | delete |

---

## 13. Permissions List Reference

From `config/permissionslist.php` — group name: `msh-subject-practical-config`

| Permission Key | Action |
|----------------|--------|
| `tenant.msh-subject-practical-config.viewAny` | Access listing |
| `tenant.msh-subject-practical-config.view` | View details |
| `tenant.msh-subject-practical-config.create` | Create new records |
| `tenant.msh-subject-practical-config.update` | Update, toggle status, restore |
| `tenant.msh-subject-practical-config.delete` | Delete, force delete |

---

## 14. Hub Tab Integration

| Property | Value |
|----------|-------|
| Hub Page | `marksheet-generation.scheduling.combined` |
| Tab ID | `practical-configs` |
| Tab Permission | `tenant.msh-subject-practical-config.viewAny` |
| Paginator Name | `practical_config_page` |
| Eager Loads | `academicSession`, `schoolClass`, `subject` |
| Search Fields | `subject.name` (via relation) |

---

## 15. Test Case Summary Statistics

| Category | Count | Description |
|----------|-------|-------------|
| TC-P (Positive) | 15 | Happy path scenarios |
| TC-N (Negative) | 22 | Validation, permission, FK constraint failures |
| TC-SQ (Security) | 8 | Permission boundary tests |
| TC-INT (Integration) | 6 | Hub tab, cross-module, pagination tests |
| TC-CR (Code Review) | 30 | Code pattern verification |
| TC-D (Data Integrity) | 12 | DB constraint, casting, audit tests |
| **Total** | **93** | All test categories combined |

---

## 16. Key Coverage Matrix

| Feature | Test Coverage | Verification Points |
|---------|--------------|-------------------|
| Gate::authorize — all 11 methods | TC-CR-01 to TC-CR-11 | Permission string matches permissionslist.php |
| activityLog — all 7 mutation methods | TC-CR-12 to TC-CR-18 | Type, message, performed_by (gap) |
| Validation — 7 fields, create + update | TC-N-01 to TC-N-08 | Required, unique, exists, numeric |
| Soft Delete cycle (destroy → trashed → restore → forceDelete) | TC-P-08, TC-D-01 to TC-D-03 | deleted_at, is_active toggles |
| FK 23000 catch in forceDelete | TC-N-17 | User-friendly error message on FK constraint |
| AJAX toggleStatus | TC-P-10, TC-P-11 | JSON response, is_active flip |
| Hub tab integration | TC-INT-01 to TC-INT-04 | Tab param, paginator name, permission |
| JSON responses (store, update, destroy, toggleStatus) | TC-CR-19 to TC-CR-21 | Status key, message, redirect |
| Composite unique constraint | TC-N-08 | session_id + class_id + subject_id |
| Model configuration | TC-CR-24 to TC-CR-30 | Fillable, casts, relationships |

---

## 17. Detailed Test Steps — Expanded Coverage

### TC-P-12: Create config with practical=true (full marks)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as user with create permission | 200 OK |
| 2 | Navigate to scheduling hub | Tab page |
| 3 | Click "Add Subject Practical Config" | Modal/form opens |
| 4 | Select academic_session_id=1 | Dropdown value |
| 5 | Select class_id=5 | Dropdown value |
| 6 | Select subject_id=12 | Dropdown value |
| 7 | Set has_practical=true | Toggle ON |
| 8 | Enter theory_max_marks=70 | 70.00 |
| 9 | Enter practical_max_marks=30 | 30.00 |
| 10 | Enter total_max_marks=100 | 100.00 |
| 11 | Submit form | POST |
| 12 | Check DB: has_practical=1, theory=70.00, practical=30.00 | Values match |
| 13 | Check activityLog: type="Stored", message contains "A new subject practical config was created." | Logged |

### TC-P-13: Update to disable practical

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login with update permission | 200 OK |
| 2 | Select existing config with id=5 | Found |
| 3 | Submit PUT has_practical=false, theory=100, practical=0 | Update |
| 4 | Verify DB: has_practical=0, practical_max_marks=0.00 | Updated |
| 5 | Verify activityLog: type="Updated", message="The subject practical config was updated." | Logged |
| 6 | Verify updated_by set to auth user | Tracked |

### TC-P-14: Toggle status twice (ON→OFF→ON)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Config A has is_active=true | Active |
| 2 | POST toggleStatus($id, is_active=false) | JSON success:false |
| 3 | Check DB: is_active=0 | Inactive |
| 4 | POST toggleStatus($id, is_active=true) | JSON success:true |
| 5 | Check DB: is_active=1 | Active |
| 6 | Check 2 activityLog entries, both type="Toggled" | Both logged |

### TC-P-15: Restore record viewable in hub

| Step | Action | Expected |
|------|--------|----------|
| 1 | Trash config (destroy) | deleted_at set |
| 2 | Restore config (restore) | Restored |
| 3 | Navigate to practical-configs tab | Record visible again |
| 4 | Verify is_active=true | Active display |

### TC-N-19: theory_max_marks > 100

| Step | Action | Expected |
|------|--------|----------|
| 1 | Create config with theory_max_marks=101 | Invalid |
| 2 | Submit form | Validation error |
| 3 | Error: "The theory max marks must not be greater than 100." | max validation |

### TC-N-20: practical_max_marks negative

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set practical_max_marks=-5 | Invalid |
| 2 | Submit | Error: min:0 validation |

### TC-N-21: total_max_marks negative

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set total_max_marks=-1 | Invalid |
| 2 | Submit | Error: min:0 validation |

### TC-N-22: total_max_marks > 100

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set total_max_marks=150 | Invalid |
| 2 | Submit | Error: max:100 validation |

### TC-INT-05: Hub tab isolation — practical-configs pagination

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to hub with ?tab=schedules&sch_page=3 | Schedules tab page 3 |
| 2 | Switch to practical-configs tab | Tab switches |
| 3 | Verify practical-configs shows page 1 | Not page 3 |
| 4 | Verify paginator name is practical_config_page | Correct paginator |

### TC-INT-06: Config state after IA marks created (FK dependency)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Create config for (session=1, class=5, subject=12) | Success |
| 2 | Create student IA marks using this config | FK references config |
| 3 | Attempt destroy on config | deletes (soft) |
| 4 | Attempt forceDelete on trashed config | FK 23000 — user-friendly error |
---

## 18. Test Execution Summary

| # | Area | Result | Notes |
|---|------|--------|-------|
| 1 | Gate authorization across all methods | ✅ All 11 gates verified at correct line numbers |
| 2 | Validation rules | ✅ 7 field rules verified for create + update |
| 3 | CRUD operations | ✅ All 11 controller methods operational |
| 4 | State transitions | N/A — no state machine on this entity |
| 5 | Activity logging | ✅ 7 mutation methods log, ⚠️ missing performed_by |
| 6 | Soft delete cycle | ✅ Full cycle verified (destroy→trashed→restore→forceDelete) |
| 7 | FK constraint handling | ✅ 23000 catch tested in forceDelete |
| 8 | AJAX toggle status | ✅ JSON responses verified for toggleStatus |
| 9 | Hub tab integration | ✅ 4 integration tests covering tab persistence, pagination isolation |
| 10 | Composite unique | ✅ session+class+subject uniqueness enforced at validation level |

### TC-P-15: Verify index tab partial renders all 5 FK names

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to hub tab practical-configs | Table loads |
| 2 | **Verify**: academic_session.name displayed | Session name column |
| 3 | **Verify**: school_class.name displayed | Class name column |
| 4 | **Verify**: subject.name displayed | Subject name column |
| 5 | **Verify**: exam_group.name displayed | Exam group column |
| 6 | **Verify**: schedule_code shown (from schedule relation) | Schedule column |

### TC-P-16: Create with practical_max_marks = total_max_marks (equal)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set practical_max_marks=50, total_max_marks=50 | Equal values |
| 2 | Submit | POST |
| 3 | **Verify**: Validation passes (max_marks <= total_max_marks) | Stored successfully |

### TC-P-17: Update config — change subject only

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open edit for existing config | Form pre-filled |
| 2 | Change subject_id to a different active subject | Subject changed |
| 3 | Submit update | PUT |
| 4 | **Verify**: `composite_unique` re-checks with new subject | Passes if new combo unique |
| 5 | **Verify**: activityLog records subject change | Changes array |

### TC-P-18: Show page renders all FK relations

| Step | Action | Expected |
|------|--------|----------|
| 1 | Click View on config row | Show modal/page |
| 2 | **Verify**: All 5 FK names displayed | Relations loaded |
| 3 | **Verify**: is_active badge rendered | Green/red badge |

### TC-N-23: Create with practical_max_marks > total_max_marks

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set practical_max_marks=80, total_max_marks=50 | Exceeds total |
| 2 | Submit | Validation error: `max:50` or custom rule |
| 3 | **Verify**: "practical max marks must not exceed total max marks" | Custom validation message |

### TC-N-24: SQL injection in search field

| Step | Action | Expected |
|------|--------|----------|
| 1 | Search = `' OR '1'='1` | SQLi attempt |
| 2 | **Verify**: `like "%...%"` uses parameterized binding | Safe |

### TC-D-11: Concurrent edit mid-air collision

| Step | Action | Expected |
|------|--------|----------|
| 1 | User A and User B open edit for same config | Both load same data |
| 2 | User A saves first | Write committed |
| 3 | User B saves (overwrites) | Last-write-wins |
| 4 | **Verify**: No optimistic locking | B's data persists |

### TC-D-12: Transaction rollback on composite unique failure

| Step | Action | Expected |
|------|--------|----------|
| 1 | Mock DB::rollBack() scenario | Transaction failure |
| 2 | **Verify**: store() wrapped in DB::transaction() | Atomic |
| 3 | **Verify**: On exception, `DB::rollBack()` called | Rolled back |

### TC-INT-07: Hub tab persistence — practical-configs filter state

| Step | Action | Expected |
|------|--------|----------|
| 1 | Apply academic_session_id=1 filter on practical-configs tab | Filter active |
| 2 | Switch to schedules tab | Filter resets |
| 3 | Switch back to practical-configs tab | Filter NOT persisted (new GET) |

### BC-BIZ-DEEP-65: SubjectPracticalConfig is the only entity with `composite_unique` validation rule

| # | Condition | Expected Behavior |
|---|-----------|------------------|
| BC-BIZ-DEEP-65 | `academic_session_id + school_class_id + subject_id` forms composite unique | Enforced in FormRequest |
| BC-BIZ-DEEP-66 | `total_max_marks` range is 0–100 | `min:0|max:100` validation |
| BC-BIZ-DEEP-67 | `practical_max_marks` range is 0–total_max_marks | Dynamic max validation |
| BC-BIZ-DEEP-68 | `practical_config_code` is nullable and optional | Can be null |
| BC-BIZ-DEEP-69 | `destroy()` sets is_active=false before soft-delete | `$record->is_active = false; $record->save(); $record->delete()` |
| BC-BIZ-DEEP-70 | `forceDelete()` catch handles 23000 with user-friendly message | Non-23000 re-thrown |
| BC-BIZ-DEEP-71 | Flash key `flash('created.subject-practical-config')` must exist | Verify in flash.php |
| BC-BIZ-DEEP-72 | No `export` or `print` methods — CRUD only | Standard controller |

### CODE-TRACE-HUB: `subjectPracticalConfigsQuery()` — MarksheetGenerationController Private Method

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | ~260 | `private function subjectPracticalConfigsQuery(Request $request): Builder` | Private query helper for practical-configs hub tab |
| 02 | ~261 | `$query = SubjectPracticalConfig::with(['academicSession', 'schoolClass', 'subject', 'examGroup', 'schedule'])` | Eager load all 5 FKs |
| 03 | ~263 | `if ($request->input('tab') === 'practical-configs')` | Only apply filters when tab active |
| 04 | ~264 | `->when($request->filled('academic_session_id'), fn ($q) => $q->where('academic_session_id', (int) $request->academic_session_id))` | Filter by session |
| 05 | ~265 | `->when($request->filled('school_class_id'), fn ($q) => $q->where('school_class_id', (int) $request->school_class_id))` | Filter by class |
| 06 | ~266 | `->when($request->filled('status'), fn ($q) => $q->where('is_active', (bool) $request->status))` | Status filter |
| 07 | ~268 | `return $query->latest()` | Always order by latest |
| 08 | Hub | `paginate(15, ['*'], 'practical_config_page')` with `->appends(['tab' => 'practical-configs'])` | Unique paginator, tab persistence |
