# tpt_FeeCreation_TcList

## Module: Transport → Student Route Fees Management → Fee Creation (Invoicing)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Student Route Fees Management |
| Feature | Fee Creation (Invoicing) |
| URL(s) | `/std-route-Fees-mgmt` (index via tab), `/fee-master` (standalone index GET — **BROKEN**, see BC-BIZ-33), `/fee-master` (create), `/fee-master` (store), `/fee-master/{id}` (show), `/fee-master/{id}/edit` (edit), `/fee-master/{id}` (update PUT), `/fee-master/{id}` (destroy DELETE), `/fee-master/trash/view` (trash), `/fee-master/{id}/restore` (restore GET), `/fee-master/{id}/force-delete` (forceDelete DELETE), `/fee-master/{id}/toggle-status` (toggleStatus POST), `/fee-master/{id}/pdf` (downloadPdf GET), `/fee-master/validate/file` (validateFile POST), `/fee-master/start/import` (startImport POST), `/fee-master/allocation/export` (export GET) |
| Controller | `Modules\Transport\Http\Controllers\FeeMasterController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\StudentRouteFeesController@index()` |
| Model | `Modules\Transport\Models\TptFeeMaster` — table: `tpt_student_fee_detail` |
| Validation (Create + Update) | `Modules\Transport\Http\Requests\FeeMasterRequest` |
| Permissions | `tenant.fee-master.viewAny`, `tenant.fee-master.view`, `tenant.fee-master.create`, `tenant.fee-master.update`, `tenant.fee-master.edit` (blade-only; controller gates with `update`), `tenant.fee-master.delete`, `tenant.fee-master.restore`, `tenant.fee-master.forceDelete`, `tenant.fee-master.import` (blade-only; controller uses `create`), `tenant.fee-master.export` (blade-only; controller uses `viewAny`), `tenant.fee-master.pdf` (blade-only; controller uses `view`) |
| Soft Deletes | Yes (`TptFeeMaster` uses `SoftDeletes` trait) |
| Activity Log | Events: `Created` (store), `Updated` (update), `Trash` (destroy), `Restored` (restore), `Force Deleted` (forceDelete), `Toggled` (toggleStatus) |
| Import / Export | Implemented — `FeeMasterImport`, `FeeMasterExport`, `FeeMasterReadOnly` via `validateFile()` + `startImport()` + `export()` |
| PDF Download | Implemented — `downloadPdf($id)` renders `fee-master.pdf` view with collections & fines |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-master.viewAny`, `tenant.fee-master.view`, `tenant.fee-master.create`, `tenant.fee-master.update`, `tenant.fee-master.edit`, `tenant.fee-master.delete`, `tenant.fee-master.restore`, `tenant.fee-master.forceDelete`, `tenant.fee-master.import`, `tenant.fee-master.export`, `tenant.fee-master.pdf`
- Required seed data: At least one `StudentAcademicSession` record (std_student_academic_sessions) with `roll_no` populated
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- The Fee Creation tab is loaded as part of StudentRouteFeesMgmt -- the URL `/std-route-Fees-mgmt?tab=fee_creation` loads `StudentRouteFeesController@index` with all fee management tabs simultaneously
- `OrganizationAcademicSession` data required for academic session dropdown
- `updated_at` column is NOT present in DDL `tpt_student_fee_detail` -- model uses BaseModel which may provide it via Eloquent convention

---

## 3. Default Data Load

When the page loads via `StudentRouteFeesController@index()` (GET `/std-route-Fees-mgmt`), all fee management tab data is fetched in a single request and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Fee Masters Grid (Tab) | `StudentRouteFeesController@FeeMasterQuery()` | `TptFeeMaster::query()->orderBy('id', 'DESC')` | tab=fee_creation: `std_academic_sessions_id`, `due_date`, `month` | 10/page via `->paginate(10)->withQueryString()` |
| Fee Masters Grid (Standalone -- **BROKEN**) | `FeeMasterController@index()` | `TptFeeMaster::paginate(20)` passes `'data'` but blade expects `$feeMasters` | None -- no search/filter | 20/page via `->paginate(20)` |
| Fee Creation Tab Partial | view: `transport::fee-master.index` | Included inside `stdroutefeesmgmt.blade.php` via `@include('transport::fee-master.index')` | Uses `$feeMasters` variable from controller | As above |
| Summary data | `feeCollectionSummary()` | `TptStudentFeeCollection::with('feeMaster')` | `academic_sessions_id`, `month`, `status` | N/A -- computed collection |
| Fee Collections | `feeCollectionData()` | `TptStudentFeeCollection::with('feeMaster.academicSession')` | `academic_sessions_id`, `status`, `month` | 10/page |

Note: FeeMasterController has a standalone `index()` at GET `/fee-master` (maps via `Route::resource('fee-master')`), but it is **BROKEN** -- it passes `'data' => TptFeeMaster::paginate(20)` to the view, but `fee-master/index.blade.php` expects `$feeMasters` (the variable name used by the tab container). The PRIMARY entry point is the tab container at `/std-route-Fees-mgmt?tab=fee_creation`, which uses `StudentRouteFeesController@FeeMasterQuery()` passing `$feeMasters`.

The `FeeMasterController` methods `create()`, `show()`, `edit()` load their own dedicated full-page views (with breadcrumb and layout).

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('YmdHis') . random_int(100, 999)` for uniqueness
- **std_academic_sessions_id**: Must reference an existing `std_student_academic_sessions` record
- **month**: DATE type, stored as first day of month via `Carbon::parse($request->month)->startOfMonth()->format('Y-m-d')`
- **amount**: DECIMAL(10,2), required, numeric, min:0
- **due_date**: DATE, required
- **fine_amount**: DECIMAL(10,2), defaults to 0 in controller
- **total_amount**: DECIMAL(10,2), defaults to 0 in controller (computed as amount + fine_amount via JS in create/edit views)
- **status**: VARCHAR(20), defaults to 'Pending' in controller. Can be toggled to 'Paid' via `toggleStatus()` which uses `FILTER_VALIDATE_BOOLEAN` on `is_active` input
- **remark**: VARCHAR(512), nullable
- **Pre-test cleanup**: Delete created fee masters by `std_academic_sessions_id` + `month` combination
- **Activity log cleanup**: Records cleaned up after force-delete tests
- **Soft delete behavior**: `destroy()` uses DB transaction: `$feeMaster->feeCollections()->delete()` THEN `$feeMaster->delete()` -- cascading soft delete to child collections
- **Restore behavior**: `restore()` uses DB transaction: `$feeMaster->restore()` THEN `$feeMaster->feeCollections()->restore()` -- restores both parent and children
- **Force delete behavior**: `forceDelete()` uses DB transaction: `$feeMaster->feeCollections()->forceDelete()` THEN `$feeMaster->forceDelete()`
- **Import flow**: `validateFile()` validates Excel rows (roll_no, month, fee_amount, due_date, total_amount, fine_amount) then returns error TXT or stores validated file in session; `startImport()` runs `FeeMasterImport` from stored session file
- **Export**: `export()` downloads `FeeMasterExport` as `.xlsx`
- **toggleStatus**: Accepts `is_active` from request body. Uses `filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN)` to set status 'Paid' or 'Pending'. Returns JSON `{success: true/false, status, message}`
- **StudentPayLog**: Created after every CRUD action (create, update, delete, restore, forceDelete, toggleStatus) with appropriate `activity_type`

---

## 5. Business Conditions

### 5.1 Database Schema -- `tpt_student_fee_detail`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | std_academic_sessions_id | INT UNSIGNED | NOT NULL, FK -> `std_student_academic_sessions.id` (no explicit DDL FK) |
| BC-DB-03 | month | DATE | NOT NULL |
| BC-DB-04 | amount | DECIMAL(10,2) | NOT NULL |
| BC-DB-05 | fine_amount | DECIMAL(10,2) | DEFAULT 0.00 |
| BC-DB-06 | total_amount | DECIMAL(10,2) | NOT NULL |
| BC-DB-07 | due_date | DATE | NOT NULL |
| BC-DB-08 | Remark | VARCHAR(512) | DEFAULT NULL |
| BC-DB-09 | status | VARCHAR(20) | NOT NULL, DEFAULT 'Pending' |
| BC-DB-10 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

Note: DDL has NO `updated_at` column, and NO explicit FK constraint on `std_academic_sessions_id`. The column is named `Remark` (capital R) in DDL but the model's fillable uses `remark` (lowercase). DDL also has no `is_active` column -- status is tracked via the `status` VARCHAR field.

### 5.2 Validation Rules -- `FeeMasterRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | std_academic_sessions_id | required, `exists:std_student_academic_sessions,id` | "Student academic session is required." / "Selected student session is invalid." |
| BC-VAL-02 | month | required, date | "Month is required." |
| BC-VAL-03 | amount | required, numeric, min:0 | "Amount is required." |
| BC-VAL-04 | due_date | required, date | "Due date is required." |
| BC-VAL-05 | remark | nullable, string, max:255 | -- |
| BC-VAL-06 | fine_amount | nullable, numeric, min:0 | -- |
| BC-VAL-07 | total_amount | nullable, numeric, min:0 | -- |

Note: DDL column `Remark` is VARCHAR(512) but request validates `max:255`. The `total_amount` and `fine_amount` can be null in request but DB defaults to 0.00. No unique constraint exists on any combination of fields -- multiple fee masters can exist for same academic session + month.

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.fee-master.viewAny | index() + tab display in StudentRouteFeesMgmt | Without -> tab hidden (blade @can), hitting URL with bad permission -> 403 |
| BC-AUTH-02 | tenant.fee-master.view | show(), downloadPdf() | Without -> 403 |
| BC-AUTH-03 | tenant.fee-master.create | store(), create(), validateFile(), startImport() | Without -> 403; also in FeeMasterRequest::authorize() |
| BC-AUTH-04 | tenant.fee-master.update | update(), edit(), toggleStatus() | Without -> 403; also in FeeMasterRequest::authorize() |
| BC-AUTH-05 | tenant.fee-master.edit | Action column visibility (blade @canany) | Without -> action dropdown hidden. **MISMATCH:** blade uses `tenant.fee-master.edit` but controller `edit()` gates with `tenant.fee-master.update`. A user with `update` but without `edit` sees buttons but gets 403 on click. |
| BC-AUTH-06 | tenant.fee-master.delete | destroy() | Without -> 403 |
| BC-AUTH-07 | tenant.fee-master.restore | restore(), trashed() | Without -> 403; trash view button hidden |
| BC-AUTH-08 | tenant.fee-master.forceDelete | forceDelete() | Without -> 403 |
| BC-AUTH-09 | tenant.fee-master.import | Import button visibility (blade @can) | Without -> import button hidden; route also guarded |
| BC-AUTH-10 | tenant.fee-master.viewAny | export() | Controller gate uses `tenant.fee-master.viewAny`, NOT `tenant.fee-master.export`. The blade `@can('tenant.fee-master.export')` controls button visibility separately. **BOTH must match for correct security.** Also: the export button in `fee-master/index.blade.php` links to `transport.fee-collection.export` (FeeCollection), not `transport.fee-master.export` -- copy-paste bug. |
| BC-AUTH-11 | tenant.fee-master.pdf | downloadPdf() | Without -> 403; PDF download button hidden |
| BC-AUTH-12 | tenant.fee-collection.create | "Add Collection" button in index dropdown | Without -> add collection link hidden |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create via `TptFeeMaster::create([...])` in store() | New fee master created with `status = 'Pending'`; redirect to `transport.std-route-Fees-mgmt.index` with flash `created.fee_master` |
| BC-BIZ-02 | Activity log on create | `activityLog($feeMaster, 'Created', ['message' => 'Fee Master created'])` |
| BC-BIZ-03 | StudentPayLog on create | `activity_type: 'fee_master_created'`, `reference_table: 'tpt_fee_master'` |
| BC-BIZ-04 | Update via `$feeMaster->update([...])` | Fee master attributes updated; month re-parsed via `Carbon::parse()` |
| BC-BIZ-05 | StudentPayLog on update | `activity_type: 'fee_master_updated'` |
| BC-BIZ-06 | Activity log on update | `activityLog($feeMaster, 'Updated', ['message' => 'Fee Master updated'])` |
| BC-BIZ-07 | Soft delete via `destroy()` | DB transaction: feeCollections() soft-deleted first, then feeMaster soft-deleted |
| BC-BIZ-08 | Activity log on soft delete | `activityLog($feeMaster, 'Trash', ['message' => 'Fee Master & related collections trashed'])` |
| BC-BIZ-09 | StudentPayLog on delete | `activity_type: 'fee_master_deleted'` |
| BC-BIZ-10 | Redirect after soft delete | Redirect to `transport.std-route-Fees-mgmt.index` with flash `trashed.fee_master` |
| BC-BIZ-11 | Trash list via `trashed()` | `TptFeeMaster::onlyTrashed()->paginate(20)` -- shows soft-deleted records |
| BC-BIZ-12 | Restore via `restore($id)` | DB transaction: feeMaster restored first, then feeCollections restored; redirects to `transport.std-route-Fees-mgmt.index` |
| BC-BIZ-13 | Activity log on restore | `activityLog($feeMaster, 'Restored', ['message' => 'Fee Master & collections restored'])` |
| BC-BIZ-14 | Force delete via `forceDelete($id)` | `TptFeeMaster::onlyTrashed()` with feeCollections -> forceDelete both in transaction |
| BC-BIZ-15 | Activity log on force delete | `activityLog($feeMaster, 'Force Deleted', ['message' => 'Fee Master & collections permanently deleted'])` |
| BC-BIZ-16 | toggleStatus | `filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN)` -> status = 'Paid' if true, 'Pending' if false |
| BC-BIZ-17 | toggleStatus success response | JSON `{success: true, status: 'Paid'|'Pending', message: flash('status_updated.fee_master')}` |
| BC-BIZ-18 | toggleStatus failure response | JSON `{success: false, message: flash('status_switch_failed.fee_master')}` |
| BC-BIZ-19 | StudentPayLog on toggle | `activity_type: 'fee_master_status_changed'` |
| BC-BIZ-20 | Gate check in FeeMasterRequest::authorize() | For POST: `Gate::allows('tenant.fee-master.create')`; for PUT/PATCH: `Gate::allows('tenant.fee-master.update')` |
| BC-BIZ-21 | All FeeMasterController methods use `Gate::authorize()` | Gate check at start of EVERY method BEFORE any DB query |
| BC-BIZ-22 | Fee master query filters in StudentRouteFeesController | `FeeMasterQuery()`: `std_academic_sessions_id`, `due_date`, `month` -- filtered via `$request->tab` context |
| BC-BIZ-23 | Import validation -- `validateFile()` | Validates Excel: roll_no (required, exist in std_student_academic_sessions), month, fee_amount (numeric), due_date, total_amount (optional numeric), fine_amount (optional numeric) |
| BC-BIZ-24 | Import success flow | Returns JSON `{status: 'success', file: $path}`; file stored in session for startImport |
| BC-BIZ-25 | Import error flow | Returns TXT file with per-row error messages; header `Content-Disposition: attachment` |
| BC-BIZ-26 | Export via `export()` | Downloads `FeeMasterExport` with dynamic filters as `.xlsx` |
| BC-BIZ-27 | PDF download via `downloadPdf($id)` | `Pdf::loadView('transport::fee-master.pdf')` with feeMaster, collections, fines |
| BC-BIZ-28 | Summary calculation in index view | `$students = $fm->feeCollections->count(); $collected = $fm->feeCollections->sum('paid_amount'); $due = $students * $fm->amount;` -- status = Completed if collected >= due, Partial if collected > 0, else Pending |
| BC-BIZ-29 | DDL discrepancy -- `Remark` column name | DDL uses uppercase `Remark` but model uses lowercase `remark`. Eloquent is case-insensitive on MySQL but may cause issues on case-sensitive DB. |
| BC-BIZ-30 | DDL discrepancy -- missing `updated_at` | DDL has NO `updated_at` but Eloquent BaseModel may expect it. If column missing, update operations may silently fail on `updated_at` timestamp. |
| BC-BIZ-31 | Fee master show view includes collections | `FeeMasterController@show()` passes `$record`; view renders collection history table below fee master details |
| BC-BIZ-32 | No unique constraint on fee master | Multiple fee masters can exist for same (std_academic_sessions_id, month) -- no uq_* key in DDL |
| BC-BIZ-33 | **BUG:** Standalone `FeeMasterController@index()` passes `$data` but blade expects `$feeMasters` | `FeeMasterController::index()` returns `'data' => TptFeeMaster::paginate(20)` but `fee-master/index.blade.php` iterates `$feeMasters`. Visiting GET `/fee-master` throws `Undefined variable $feeMasters`. This path is unreachable via primary UI but exposed via direct URL. |
| BC-BIZ-34 | **BUG:** Export button links to wrong controller | In `fee-master/index.blade.php` line 43, the export button's `data-url` uses `transport.fee-collection.export` (FeeCollectionController), NOT `transport.fee-master.export` (FeeMasterController). |

### 5.5 Model Relationships

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | feeCollections() | HasMany TptStudentFeeCollection | student_fee_detail_id | Returns all collection records for this fee master |
| BC-REL-02 | academicSession() | BelongsTo StudentAcademicSession | std_academic_sessions_id | Returns the student academic session |
| BC-REL-03 | session() | BelongsTo OrganizationAcademicSession | std_academic_sessions_id | Alternate relationship (same FK, different model) |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | student_fee_detail_id (in tpt_student_fee_collection) | tpt_student_fee_detail (id) | RESTRICT |
| BC-REF-02 | student_fee_detail_id (in tpt_student_fine_detail) | tpt_student_fee_detail (id) | RESTRICT |
| BC-REF-03 | std_academic_sessions_id | std_student_academic_sessions (id) | No explicit FK in DDL |

### 5.7 Deep Business Conditions -- BC-BIZ-DEEP

| BC ID | Condition | Expected Behavior | Code Source |
|-------|-----------|-------------------|-------------|
| BC-BIZ-DEEP-01 | Model $fillable has 8 fields | `std_academic_sessions_id`, `month`, `amount`, `due_date`, `fine_amount`, `status`, `total_amount`, `remark` | `TptFeeMaster.php:17-26` |
| BC-BIZ-DEEP-02 | Model table name differs from class | `protected $table = 'tpt_student_fee_detail'` class is TptFeeMaster | `TptFeeMaster.php:15` |
| BC-BIZ-DEEP-03 | Model uses SoftDeletes trait | `use HasFactory, SoftDeletes;` | `TptFeeMaster.php:13` |
| BC-BIZ-DEEP-04 | Default 'Pending' set in store() controller | `'status' => 'Pending'` hardcoded in store(); DDL also has DEFAULT 'Pending' | `FeeMasterController.php:74`, DDL line 23 |
| BC-BIZ-DEEP-05 | Month stored as YYYY-MM-01 (first of month) | `Carbon::parse($request->month)->startOfMonth()->format('Y-m-d')` | `FeeMasterController.php:64` |
| BC-BIZ-DEEP-06 | StudentPayLog student_id uses optional chain | `isset($feeMaster->academicSession->student->id) ? ... : ""` | `FeeMasterController.php:82` |
| BC-BIZ-DEEP-07 | StudentPayLog amount = total_amount of fee master | `'amount'=> $feeMaster->total_amount` at time of action | `FeeMasterController.php:86,138,167,209,248,278` |
| BC-BIZ-DEEP-08 | StudentPayLog reference_table fixed to 'tpt_fee_master' | Hardcoded string for all operations | Throughout Controller |
| BC-BIZ-DEEP-09 | StudentPayLog module_name fixed to 'Transport' | Hardcoded string in create() | `FeeMasterController.php:84` |
| BC-BIZ-DEEP-10 | StudentPayLog triggered_by = auth()->user()->id | Falls back gracefully if auth fails | `FeeMasterController.php:91` |
| BC-BIZ-DEEP-11 | show() passes $record variable, NOT $feeMaster | `return view('transport::fee-master.show', compact('record'))` | `FeeMasterController.php:100-101` |
| BC-BIZ-DEEP-12 | edit() passes $feeMaster + $organizationData | `compact('feeMaster', 'organizationData')` | `FeeMasterController.php:107-109` |
| BC-BIZ-DEEP-13 | create() loads ALL sessions (no active filter) | `StudentAcademicSession::get()` no where('is_active', 1) | `FeeMasterController.php:57-58` |
| BC-BIZ-DEEP-14 | trashed() passes $data variable to view | `compact('data')` naming inconsistent with other views | `FeeMasterController.php:183-184` |
| BC-BIZ-DEEP-15 | destroy() eager-loads feeCollections before transaction | `TptFeeMaster::with('feeCollections')->findOrFail($id)` outside DB::transaction() | `FeeMasterController.php:152` |
| BC-BIZ-DEEP-16 | restore() uses onlyTrashed() for parent + feeCollections | Correct: only trashed records can be restored | `FeeMasterController.php:190-194` |
| BC-BIZ-DEEP-17 | forceDelete() uses same onlyTrashed() pattern as restore | `TptFeeMaster::onlyTrashed()->with([...])->findOrFail($id)` | `FeeMasterController.php:225-229` |
| BC-BIZ-DEEP-18 | toggleStatus() uses $feeMaster->save() NOT update() | Sets `$feeMaster->status` then `$feeMaster->save()` bypasses mass-assignment | `FeeMasterController.php:264,283` |
| BC-BIZ-DEEP-19 | toggleStatus() only modifies status field | Does NOT touch any other attribute | `FeeMasterController.php:264` |
| BC-BIZ-DEEP-20 | toggleStatus() JSON response structure | Success: `{success:true, status: 'Paid'|'Pending', message}`; Failure: `{success:false, message}` | `FeeMasterController.php:284-294` |
| BC-BIZ-DEEP-21 | filter_var FILTER_VALIDATE_BOOLEAN mapping | "1"/"true"/"on"/"yes" -> true -> 'Paid'; "0"/"false"/"off"/"no"/"" -> false -> 'Pending' | `FeeMasterController.php:263` |
| BC-BIZ-DEEP-22 | validateFile checks 6 columns per Excel row | roll_number (required+exists), month (required), fee_amount (required+numeric), due_date (required), total_amount (opt+numeric), fine_amount (opt+numeric) | `FeeMasterController.php:310-371` |
| BC-BIZ-DEEP-23 | validateFile column name `roll_number` not `roll_no` | Excel heading must be exactly `roll_number` | `FeeMasterController.php:315` |
| BC-BIZ-DEEP-24 | validateFile column name `fee_amount` not `amount` | Excel heading must be exactly `fee_amount` | `FeeMasterController.php:345` |
| BC-BIZ-DEEP-25 | validateFile error TXT format | "TOTAL ROWS : N\nFAILED ROWS : N\n\n" + per-row "Row N : message" | `FeeMasterController.php:389-398` |
| BC-BIZ-DEEP-26 | validateFile stores path in session | `session(['fee_master_import_file' => $savedFile])` key = fee_master_import_file | `FeeMasterController.php:405` |
| BC-BIZ-DEEP-27 | validateFile validates file mime type | `'file' => 'required|mimes:xlsx,csv'` | `FeeMasterController.php:300-302` |
| BC-BIZ-DEEP-28 | startImport reads file from session | `$file = session('fee_master_import_file')` | `FeeMasterController.php:416` |
| BC-BIZ-DEEP-29 | startImport missing-file error response | JSON `{status: 'error', message: 'No validated file found'}` | `FeeMasterController.php:418-423` |
| BC-BIZ-DEEP-30 | startImport runs FeeMasterImport via disk('public') | `Excel::import(new FeeMasterImport, Storage::disk('public')->path($file))` | `FeeMasterController.php:427` |
| BC-BIZ-DEEP-31 | FeeMasterImport recalculates total_amount as amount + fine | `$totalAmount = $amount + $fineAmount;` ignores Excel total_amount | `FeeMasterImport.php:68` |
| BC-BIZ-DEEP-32 | FeeMasterImport handles Excel serial dates | `Date::excelToDateTimeObject($value)` for month and due_date | `FeeMasterImport.php:103-108,133-138` |
| BC-BIZ-DEEP-33 | FeeMasterImport silently skips rows missing required fields | `if (empty($row['roll_number']) || empty($row['month']) || empty($row['fee_amount'])) { continue; }` | `FeeMasterImport.php:25-31` |
| BC-BIZ-DEEP-34 | FeeMasterImport uses WithHeadingRow | First row of Excel must be header row | `FeeMasterImport.php:13` |
| BC-BIZ-DEEP-35 | FeeMasterImport month parsing for string dates | `Carbon::parse($value)->startOfMonth()->format('Y-m-d')` | `FeeMasterImport.php:112-114` |
| BC-BIZ-DEEP-36 | FeeMasterImport date parsing replaces hyphens with slashes | `Carbon::parse(str_replace('-', '/', $value))` | `FeeMasterImport.php:141` |
| BC-BIZ-DEEP-37 | FeeMasterImport trims roll_number before lookup | `trim($row['roll_number'])` | `FeeMasterImport.php:38` |
| BC-BIZ-DEEP-38 | FeeMasterImport always inserts, never updates | `TptFeeMaster::create([...])` for every valid row | `FeeMasterImport.php:78` |
| BC-BIZ-DEEP-39 | FeeMasterImport hardcodes status to 'Pending' | Never reads status from Excel | `FeeMasterImport.php:86` |
| BC-BIZ-DEEP-40 | FeeMasterImport remark with null fallback | `'remark' => $row['remark'] ?? null` | `FeeMasterImport.php:85` |


| BC-BIZ-DEEP-41 | FeeMasterReadOnly implements ToArray + WithHeadingRow | Used only for validation reading | `FeeMasterReadOnly.php:8-10` |
| BC-BIZ-DEEP-42 | export() passes dynamic filters from request | `new FeeMasterExport($request->all())` | `FeeMasterController.php:442` |
| BC-BIZ-DEEP-43 | export() gates with tenant.fee-master.viewAny NOT export | Controller `Gate::authorize('viewAny')` vs blade `@can('export')` mismatch | `FeeMasterController.php:440` |
| BC-BIZ-DEEP-44 | downloadPdf queries collections AND fines separately | Two independent ->get() queries by student_fee_detail_id | `FeeMasterController.php:40-42` |
| BC-BIZ-DEEP-45 | downloadPdf uses DomPDF A4 portrait | `Pdf::loadView('transport::fee-master.pdf', compact(...))->setPaper('A4', 'portrait')` | `FeeMasterController.php:44-47` |
| BC-BIZ-DEEP-46 | downloadPdf filename = fee_master_{id}.pdf | e.g. `fee_master_42.pdf` | `FeeMasterController.php:49-51` |
| BC-BIZ-DEEP-47 | FeeMasterQuery() accepts 3 optional filters | std_academic_sessions_id, due_date (whereDate), month -- no search or status filter | `StudentRouteFeesController.php:260-273` |
| BC-BIZ-DEEP-48 | FeeMasterQuery() orders by id DESC | `orderBy('id', 'DESC')` -- newest first | `StudentRouteFeesController.php:274` |
| BC-BIZ-DEEP-49 | Index tab paginates at 10 per page | `->paginate(10)->withQueryString()` | `StudentRouteFeesController.php:49` |
| BC-BIZ-DEEP-50 | Fee collection summary computed in controller | `total_due = sum(feeMaster.total_amount)`, `total_collected = sum(paid_amount)`, `pending = abs(due - collected)` | `StudentRouteFeesController.php:241-252` |
| BC-BIZ-DEEP-51 | Per-row status computed in blade view | `$students = $fm->feeCollections->count(); $collected = sum('paid_amount'); $due = $students * $fm->amount;` | `index.blade.php:80-88` |
| BC-BIZ-DEEP-52 | Double relationship traversal for session name | `$fm->academicSession->academicSession->name` TptFeeMaster -> StudentAcademicSession -> AcademicSession | `index.blade.php:91` |
| BC-BIZ-DEEP-53 | Status badge color coding | Completed=bg-success(green), Partial=bg-warning(yellow), Pending=bg-secondary(gray) | `index.blade.php:98-100` |
| BC-BIZ-DEEP-54 | Create form input-text components | Month, amount, due_date, fine_amount, total_amount use `<x-backend.form.input-text>` | `create.blade.php:52-108` |
| BC-BIZ-DEEP-55 | Create form academic session is raw select | Manual `<select>` with `@foreach($organizationData as $session)` | `create.blade.php:36-46` |
| BC-BIZ-DEEP-56 | Create form remark is raw textarea | `<textarea name="remark" class="form-control" rows="3">` | `create.blade.php:114-119` |
| BC-BIZ-DEEP-57 | JS auto-calculates total = amount + fine | `calculateFinalAmount()` on `input` event of both fields | `create.blade.php:138-147`, `edit.blade.php:137-146` |
| BC-BIZ-DEEP-58 | total_amount field is readonly | `readonly` attribute on input; user cannot manually edit | `create.blade.php:107`, `edit.blade.php:105` |
| BC-BIZ-DEEP-59 | Show view month as "F Y" literal | `Carbon::parse($record->month)->format('F Y')` e.g. "January 2026" | `show.blade.php:36-37` |
| BC-BIZ-DEEP-60 | Show view due_date as "d-m-Y" | `Carbon::parse($record->due_date)->format('d-m-Y')` | `show.blade.php:49-51` |
| BC-BIZ-DEEP-61 | Show view monetary values formatted | `number_format($record->fine_amount, 2)` with `₹` prefix | `show.blade.php:57,63-65` |
| BC-BIZ-DEEP-62 | Show view collection history lazy-loads | `@foreach ($record->feeCollections as $index => $collection)` | `show.blade.php:113` |
| BC-BIZ-DEEP-63 | Show view empty collections state | "No fee collection found for this fee master." | `show.blade.php:143-145` |
| BC-BIZ-DEEP-64 | Edit view uses old() with fallback to DB | `old('std_academic_sessions_id', $feeMaster->std_academic_sessions_id)` | `edit.blade.php:42` |
| BC-BIZ-DEEP-65 | Edit view month parsed to Y-m-d for date input | `old('month', Carbon::parse($feeMaster->month)->format('Y-m-d'))` | `edit.blade.php:58` |
| BC-BIZ-DEEP-66 | Edit view due_date also parsed | `old('due_date', Carbon::parse($feeMaster->due_date)->format('Y-m-d'))` | `edit.blade.php:82` |
| BC-BIZ-DEEP-67 | Trash view uses action-trashed component | `<x-backend.table.action-trashed>` renders Restore + Force Delete | `trash.blade.php:40` |
| BC-BIZ-DEEP-68 | Trash view paginates at 20 per page | `TptFeeMaster::onlyTrashed()->paginate(20)` | `FeeMasterController.php:183` |
| BC-BIZ-DEEP-69 | PDF view receives 3 variables | feeMaster (model), collections (Collection), fines (Collection) | `FeeMasterController.php:46` |
| BC-BIZ-DEEP-70 | StudentPayLog does NOT set log_date | No 'log_date' key in any StudentPayLog::create() call | Throughout controller |
| BC-BIZ-DEEP-71 | All flash messages use flash('key') helper | `flash('created.fee_master')`, `flash('updated.fee_master')`, `flash('trashed.fee_master')`, `flash('restored.fee_master')`, `flash('force_deleted.fee_master')`, `flash('status_updated.fee_master')` | Throughout controller |
| BC-BIZ-DEEP-72 | destroy() StudentPayLog before activityLog | StudentPayLog line 159 then activityLog line 171 -- opposite order to store() | `FeeMasterController.php:159-173` |
| BC-BIZ-DEEP-73 | restore() StudentPayLog activity_type 'fee_master_restored' | Distinct from activityLog event 'Restored' | `FeeMasterController.php:206` |
| BC-BIZ-DEEP-74 | forceDelete() StudentPayLog activity_type 'fee_master_force_deleted' | Distinct from destroy() 'fee_master_deleted' | `FeeMasterController.php:244` |
| BC-BIZ-DEEP-75 | feeCollectionSummary uses in-memory sum on collection | `$collections->sum(fn($row) => $row->feeMaster->total_amount ?? 0)` | `StudentRouteFeesController.php:241-243` |
| BC-BIZ-DEEP-76 | StudentRouteFeesController passes 19+ variables to view | All tab data loaded in single index() method | `StudentRouteFeesController.php:84-107` |
| BC-BIZ-DEEP-77 | DDL `Remark` (capital R) vs model `remark` (lowercase) | Migration `$table->string('Remark', 512)`, model `'remark'` | DDL line 22, `TptFeeMaster.php:25` |
| BC-BIZ-DEEP-78 | DDL has NO `updated_at` | Only `created_at` with `useCurrent()`. No `timestamps()` call. | DDL lines 24-25 |
| BC-BIZ-DEEP-79 | DDL has NO FK for std_academic_sessions_id | `unsignedInteger` without `foreign()` constraint | DDL line 16 |
| BC-BIZ-DEEP-80 | Fee_collection FK is RESTRICT (no CASCADE) | Default `references()->on()` without `onDelete` | `fee_collection migration:27` |
| BC-BIZ-DEEP-81 | Fine_detail FK is RESTRICT (no CASCADE) | Same default RESTRICT behavior | `fine_detail migration:27` |
| BC-BIZ-DEEP-82 | validateFile total_amount and fine_amount both labelled "5" | Copy-paste: both use "5" in comment instead of 5/6 | `FeeMasterController.php:359-370` |
| BC-BIZ-DEEP-83 | StudentPayLog creates bypass model events | Direct `::create()` call, no observer/listener | Throughout controller |
| BC-BIZ-DEEP-84 | toggleStatus() returns 200 even on failure | Both success and failure return HTTP 200, differ only in body JSON | `FeeMasterController.php:284-294` |
| BC-BIZ-DEEP-85 | DDL missing `is_active` column | Only `status` VARCHAR(20) exists for state tracking | DDL line 23 |

### 5.8 CODE-TRACE -- Complete Code Path Analysis

| CT ID | Method | Line Range | Execution Trace |
|-------|--------|------------|-----------------|
| CT-01 | store() | 61-95 | 1. `Gate::authorize('create')` -> 403 if fail -> 2. `Carbon::parse(month)->startOfMonth()` -> 3. `TptFeeMaster::create([8 fields])` with status='Pending' -> 4. `activityLog('Created')` -> 5. `StudentPayLog::create(['activity_type'=>'fee_master_created'])` -> 6. redirect()->route('transport.std-route-Fees-mgmt.index')->with('success', flash('created.fee_master')) |
| CT-02 | update() | 112-147 | 1. `Gate::authorize('update')` -> 2. `TptFeeMaster::findOrFail($id)` -> 404 if missing -> 3. `Carbon::parse(month)->startOfMonth()` -> 4. `$feeMaster->update([7 fields])` (status NOT updated) -> 5. StudentPayLog('fee_master_updated') -> 6. activityLog('Updated') -> 7. redirect with flash('updated.fee_master') |
| CT-03 | destroy() | 149-178 | 1. `Gate::authorize('delete')` -> 2. `with('feeCollections')->findOrFail($id)` -> 3. `DB::transaction()`: feeCollections()->delete() then $feeMaster->delete() -> 4. StudentPayLog('fee_master_deleted') -> 5. activityLog('Trash') -> 6. redirect with flash('trashed.fee_master') |
| CT-04 | restore() | 187-220 | 1. `Gate::authorize('restore')` -> 2. `onlyTrashed()->with(feeCollections=>onlyTrashed())->findOrFail($id)` -> 404 if not trashed -> 3. `DB::transaction()`: $feeMaster->restore() then feeCollections()->restore() -> 4. StudentPayLog('fee_master_restored') -> 5. activityLog('Restored') -> 6. redirect with flash('restored.fee_master') |
| CT-05 | forceDelete() | 222-255 | 1. `Gate::authorize('forceDelete')` -> 2. same onlyTrashed()->with() pattern as restore -> 3. `DB::transaction()`: feeCollections()->forceDelete() then $feeMaster->forceDelete() -> 4. activityLog('Force Deleted') -> 5. StudentPayLog('fee_master_force_deleted') -> 6. redirect with flash('force_deleted.fee_master') |
| CT-06 | toggleStatus() | 258-295 | 1. `Gate::authorize('update')` -> 2. `findOrFail($id)` -> 3. `filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN)` -> 4. `$feeMaster->status = $status ? 'Paid' : 'Pending'` -> 5. activityLog('Toggled') -> 6. StudentPayLog('fee_master_status_changed') -> 7. `$feeMaster->save()` -> 8. if true: JSON `{success:true,status,message}` else: `{success:false,message}` |
| CT-07 | validateFile() | 297-411 | 1. `Gate::authorize('create')` -> 2. Validate `file required|mimes:xlsx,csv` -> 3. `Excel::toArray(new FeeMasterReadOnly, file)[0]` -> 4. Loop: check roll_number(missing/invalid), month(missing), fee_amount(empty/!numeric), due_date(missing), total_amount(opt numeric), fine_amount(opt numeric) -> 5. Errors: return TXT with TOTAL/FAILED rows -> 6. Valid: store + session set -> JSON `{status:'success', file:path}` |
| CT-08 | startImport() | 413-432 | 1. `Gate::authorize('create')` -> 2. `session('fee_master_import_file')` -> 3. if !file: JSON error -> 4. `Storage::disk('public')->path($file)` -> 5. `Excel::import(new FeeMasterImport, path)` -> 6. JSON `{status:'completed'}` |
| CT-09 | export() | 438-445 | 1. `Gate::authorize('viewAny')` -> 2. `Excel::download(new FeeMasterExport($request->all()), 'fee_master_export_'.now()->format('Y-m-d').'.xlsx')` |
| CT-10 | downloadPdf() | 35-52 | 1. `Gate::authorize('view')` -> 2. `TptFeeMaster::findOrFail($id)` -> 3. FeeCollection::where(student_fee_detail_id, id)->get() -> 4. FineDetail::where(student_fee_detail_id, id)->get() -> 5. Pdf::loadView('transport::fee-master.pdf', feeMaster+collections+fines) -> 6. `->download('fee_master_'.$id.'.pdf')` |
| CT-11 | FeeMasterQuery() | 255-275 | `TptFeeMaster::query()` -> optional `where('std_academic_sessions_id')` -> optional `whereDate('due_date')` -> optional `where('month')` -> `orderBy('id', 'DESC')` -> `paginate(10)->withQueryString()` |
| CT-12 | feeCollectionSummary() | 222-253 | `TptStudentFeeCollection::with('feeMaster')` -> optional academic_sessions_id whereHas -> optional month whereHas -> optional status where -> get() -> totalDue = sum(feeMaster->total_amount) -> totalCollected = sum('paid_amount') -> pending = abs(due - collected) -> return array |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Fee Creation Tab Loads Inside Student Route Fees Mgmt | `/std-route-Fees-mgmt?tab=fee_creation` loads tab with filter bar, table (Session, Month, Fee Amount, Due Date, Total Students, Collected, Status, Action), Import/Export, Summary | -- | -- | ⬜ |
| TC-P02 | Create Fee Master With All Required Fields | POST `/fee-master` with std_academic_sessions_id, month, amount, due_date -> created status 'Pending'; redirect with flash | -- | -- | ⬜ |
| TC-P03 | Create Fee Master With Fine Amount and Total Amount | Fine amount + total_amount saved; total = amount + fine via JS | -- | -- | ⬜ |
| TC-P04 | Create Fee Master With Remark | Remark saved correctly in DB | -- | -- | ⬜ |
| TC-P05 | View Fee Master Details | `/fee-master/{id}`: 8 detail rows (Session, Month, Amount, Due Date, Fine, Total, Status, Remark) | -- | -- | ⬜ |
| TC-P06 | View Fee Master -- Collection History Listed | Show page has "Fee Collection History" table with 6 columns | -- | -- | ⬜ |
| TC-P07 | Edit Fee Master Loads Pre-Filled Data | `/fee-master/{id}/edit` shows existing values | -- | -- | ⬜ |
| TC-P08 | Update Fee Master -- Change Amount and Due Date | PUT update; redirect with flash | -- | -- | ⬜ |
| TC-P09 | Soft Delete Fee Master | DELETE: deleted_at set; collections cascade; redirect with flash | -- | -- | ⬜ |
| TC-P10 | Trash Page Shows Deleted Fee Masters | GET `/fee-master/trash/view`: list with Restore + Force Delete | -- | -- | ⬜ |
| TC-P11 | Restore Fee Master From Trash | GET restore: deleted_at=NULL; collections restored; visible | -- | -- | ⬜ |
| TC-P12 | Force Delete Fee Master | DELETE force-delete: record + collections permanently removed | -- | -- | ⬜ |
| TC-P13 | Toggle Pending -> Paid | POST with is_active=1 -> JSON `{success:true, status:'Paid'}` | -- | -- | ⬜ |
| TC-P14 | Toggle Paid -> Pending | POST with is_active=0 -> JSON `{success:true, status:'Pending'}` | -- | -- | ⬜ |
| TC-P15 | Full Lifecycle | Create -> View -> Edit -> Toggle -> Delete -> Trash -> Restore -> Force Delete: all succeed | -- | -- | ⬜ |
| TC-P16 | Export Fee Masters | GET `/fee-master/allocation/export` -> .xlsx download | -- | -- | ⬜ |
| TC-P17 | Download Fee Master PDF | GET `/fee-master/{id}/pdf` -> PDF with details, collections, fines | -- | -- | ⬜ |
| TC-P18 | Import -- Valid File | validateFile + startImport -> 2 JSON responses + DB rows created | -- | -- | ⬜ |
| TC-P19 | Filter By Due Date | due_date filter -> only matching records | -- | -- | ⬜ |
| TC-P20 | Empty State | "No Fee Master Records Found" | -- | -- | ⬜ |
| TC-P21 | Pagination | 11+ records -> pagination links appear | -- | -- | ⬜ |
| TC-P22 | Activity Log -- Update | event 'Updated', message 'Fee Master updated' | -- | -- | ⬜ |
| TC-P23 | Activity Log -- Soft Delete | event 'Trash', message 'Fee Master & related collections trashed' | -- | -- | ⬜ |
| TC-P24 | Activity Log -- Restore | event 'Restored', message 'Fee Master & collections restored' | -- | -- | ⬜ |
| TC-P25 | Activity Log -- Force Delete | event 'Force Deleted', message 'Fee Master & collections permanently deleted' | -- | -- | ⬜ |
| TC-P26 | Activity Log -- Toggle | event 'Toggled', message 'Fee Master status updated.' | -- | -- | ⬜ |
| TC-P27 | StudentPayLog -- Update | activity_type='fee_master_updated', reference_table='tpt_fee_master' | -- | -- | ⬜ |
| TC-P28 | StudentPayLog -- Soft Delete | activity_type='fee_master_deleted' | -- | -- | ⬜ |
| TC-P29 | StudentPayLog -- Restore | activity_type='fee_master_restored' | -- | -- | ⬜ |
| TC-P30 | StudentPayLog -- Force Delete | activity_type='fee_master_force_deleted' | -- | -- | ⬜ |
| TC-P31 | StudentPayLog -- Toggle | activity_type='fee_master_status_changed' | -- | -- | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Missing std_academic_sessions_id | "Student academic session is required." | -- | -- | ⬜ |
| TC-N02 | Missing month | "Month is required." | -- | -- | ⬜ |
| TC-N03 | Missing amount | "Amount is required." | -- | -- | ⬜ |
| TC-N04 | Missing due_date | "Due date is required." | -- | -- | ⬜ |
| TC-N05 | Non-existent std_academic_sessions_id | "Selected student session is invalid." | -- | -- | ⬜ |
| TC-N06 | Negative amount | min:0 error | -- | -- | ⬜ |
| TC-N07 | Non-numeric amount | numeric error | -- | -- | ⬜ |
| TC-N08 | Invalid month (not a date) | date error | -- | -- | ⬜ |
| TC-N09 | Invalid due_date (not a date) | date error | -- | -- | ⬜ |
| TC-N10 | Remark > 255 chars | max:255 error (DB allows 512) | -- | -- | ⬜ |
| TC-N11 | View with invalid ID | GET `/fee-master/99999` -> 404 | -- | -- | ⬜ |
| TC-N12 | Edit with invalid ID | GET `/fee-master/99999/edit` -> 404 | -- | -- | ⬜ |
| TC-N13 | Update with invalid ID | PUT `/fee-master/99999` -> 404 | -- | -- | ⬜ |
| TC-N14 | Delete with invalid ID | DELETE `/fee-master/99999` -> 404 | -- | -- | ⬜ |
| TC-N15 | Restore non-deleted record | onlyTrashed() -> null -> 404 | -- | -- | ⬜ |
| TC-N16 | Force delete non-trashed record | onlyTrashed()->findOrFail -> 404 | -- | -- | ⬜ |
| TC-N17 | Toggle with invalid ID | findOrFail -> 404 | -- | -- | ⬜ |
| TC-N18 | Import invalid file extension | PDF rejected: "must be a file of type: xlsx, csv" | -- | -- | ⬜ |
| TC-N19 | Import invalid roll number | Error TXT: "Invalid Student Roll Number Invalid" | -- | -- | ⬜ |
| TC-N20 | Import missing required columns | "Student Roll Number Invalid missing" | -- | -- | ⬜ |
| TC-N21 | Permission 403 -- all CRUD endpoints | 403 for user without tenant.fee-master.* | -- | -- | ⬜ |
| TC-N22 | Guest access redirect | All `/fee-master/*` -> `/login` | -- | -- | ⬜ |
| TC-N23 | XSS in Remark | Script stored literally; Blade `{{ }}` escapes | -- | -- | ⬜ |
| TC-N24 | Standalone index variable bug | `$data` vs `$feeMasters` -> Undefined variable | -- | -- | ⬜ |
| TC-N25 | Export button wrong controller | Links to fee-collection.export not fee-master.export | -- | -- | ⬜ |
| TC-N26 | Edit permission mismatch | Blade uses 'edit', controller uses 'update' | -- | -- | ⬜ |
| TC-N27 | Export permission mismatch | Blade uses 'export', controller uses 'viewAny' | -- | -- | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft-delete fee master -- collections cascade | Controller: feeCollections()->delete() then $feeMaster->delete() | -- | -- | ⬜ |
| TC-D02 | A | Restore fee master -- collections also restored | restore() restores both parent and feeCollections | -- | -- | ⬜ |
| TC-D03 | B | Force delete -- collections also force-deleted | forceDelete() force-deletes both parent and children | -- | -- | ⬜ |
| TC-D04 | C | StudentPayLog after every action | 6 distinct activity_types, all reference_table='tpt_fee_master' | -- | -- | ⬜ |
| TC-D05 | D | DDL RESTRICT blocks direct delete | FK RESTRICT prevents orphaned collections | -- | -- | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Priority | Description | Expected Result | V1 | V2 | Status |
|-------|----------|-------------|-----------------|----|----|--------|
| TC-CR01 | P1 | Blade @can Tab Visibility | `@can('viewAny')` wraps `@include('transport::fee-master.index')` | -- | -- | ◌ |
| TC-CR02 | P1 | Import/Export Button Guards | `@canany(['import','export'])` wraps buttons | -- | -- | ◌ |
| TC-CR03 | P1 | Action Dropdown Guards | `@canany(['view','edit','delete','pdf'])` wraps action column | -- | -- | ◌ |
| TC-CR04 | P1 | Gate::authorize() BEFORE every state change | First executable line of every method | -- | -- | ◌ |
| TC-CR05 | P1 | activityLog after every CRUD | 6 events: Created, Updated, Trash, Restored, Force Deleted, Toggled | -- | -- | ◌ |
| TC-CR06 | P1 | StudentPayLog after every action | Every CRUD creates StudentPayLog with distinct activity_type | -- | -- | ◌ |
| TC-CR07 | P1 | DB transaction for destroy/restore/forceDelete | All 3 use DB::transaction() | -- | -- | ◌ |
| TC-CR08 | P1 | onlyTrashed() for restore and forceDelete | Both use TptFeeMaster::onlyTrashed() | -- | -- | ◌ |
| TC-CR09 | P1 | Non-RESTful action methods | toggleStatus, validateFile, startImport, export, downloadPdf | -- | -- | ◌ |
| TC-CR10 | P1 | FeeMasterRequest authorize matches controller | POST->create, PUT->update | -- | -- | ◌ |
| TC-CR11 | P1 | Validation rules match DDL | amount numeric (DECIMAL), remark max:255 (DDL 512 discrepancy), etc. | -- | -- | ◌ |
| TC-CR12 | P1 | Model table + SoftDeletes | `$table='tpt_student_fee_detail'` + `use SoftDeletes` | -- | -- | ◌ |
| TC-CR13 | P1 | Fillable matches DB columns | 8 fields in $fillable | -- | -- | ◌ |
| TC-CR14 | P1 | Model casts | No explicit casts defined | -- | -- | ◌ |
| TC-CR15 | P1 | Relationships defined | feeCollections(HasMany), academicSession(BelongsTo), session(BelongsTo) | -- | -- | ◌ |
| TC-CR16 | P1 | Routes: resource + extras | resource() + trash/restore/forceDelete/toggleStatus/export/import/pdf | -- | -- | ◌ |
| TC-CR17 | P1 | Route names prefixed | All use `transport.fee-master.*` | -- | -- | ◌ |
| TC-CR18 | P1 | Table columns match | Session, Month, Fee Amount, Due Date, Total Students, Collected, Status, Action | -- | -- | ◌ |
| TC-CR19 | P1 | Filter controls present | Due date, Search, Reset | -- | -- | ◌ |
| TC-CR20 | P1 | Show page displays all fields | 8 detail rows | -- | -- | ◌ |
| TC-CR21 | P1 | Flash messages after every CRUD | created/updated/trashed/restored/force_deleted | -- | -- | ◌ |
| TC-CR22 | P1 | Null safety for relationships | `$fm->academicSession->academicSession->name ?? '-'` | -- | -- | ◌ |
| TC-CR23 | P1 | No unique constraints | Duplicate (session_id, month) allowed | -- | -- | ◌ |
| TC-CR24 | P1 | No updated_at in DDL | Only created_at with useCurrent | -- | -- | ◌ |
| TC-CR25 | P1 | Remark vs remark discrepancy | DDL capital R, model lowercase | -- | -- | ◌ |
| TC-CR26 | P1 | JS auto-calc total amount | amount + fine_amount -> readonly total_amount | -- | -- | ◌ |
| TC-CR27 | P1 | validateFile TXT error format | "TOTAL ROWS : N\nFAILED ROWS : N" headers + per-row errors | -- | -- | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Fee Creation Tab Loads Inside Student Route Fees Mgmt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.fee-master.viewAny` | Authenticated |
| 2 | Navigate to `/std-route-Fees-mgmt?tab=fee_creation` | `StudentRouteFeesController@index()` loads |
| 3 | Verify tab pane `fee_creation-pane` active | `tab-pane fade show active` |
| 4 | Verify filter bar: Due Date date input + Search + Reset | 3 form controls visible |
| 5 | Verify Import button (blue, upload icon) | `btn btn-info btn-sm openImportModal` |
| 6 | Verify Export button (gray, download icon) | `btn btn-secondary btn-sm exportBtn` |
| 7 | Verify Summary: Total Due, Collected, Pending | Three `div` elements |
| 8 | Verify 8 table columns: Session through Action | `<th>` elements in `<thead>` |
| 9 | Verify data from FeeMasterQuery() -> paginate(10) | 10 rows max, ordered by id DESC |
| 10 | Verify pagination section | `$feeMasters->withQueryString()->links()` |
| 11 | Verify empty state | "No Fee Master Records Found" colspan=8 |

### TC-P02: Create Fee Master With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fee Creation tab -> Click "Add" | `/fee-master/create` full-page form |
| 2 | Select Academic Session | Dropdown filled |
| 3 | Enter month (date picker) | Month selected |
| 4 | Enter amount: "1500" | Amount entered |
| 5 | Enter due_date | Date selected |
| 6 | Click "Add Fee" | POST `/fee-master` |
| 7 | Redirect to tab | `/std-route-Fees-mgmt?tab=fee_creation` |
| 8 | Flash success | `flash('created.fee_master')` |
| 9 | DB: `SELECT * FROM tpt_student_fee_detail WHERE ...` | Record with amount, due_date, status='Pending' |
| 10 | Activity log: `activityLog($feeMaster, 'Created')` | Entry exists |
| 11 | StudentPayLog: `activity_type='fee_master_created'` | Entry exists |

### TC-P03: Create Fee Master With Fine Amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/fee-master/create` | Form loaded |
| 2 | Fill required: session, month, amount=1500, due_date | Fields filled |
| 3 | Enter fine_amount: 200 | Fine entered |
| 4 | Observe total_amount (readonly) | Auto-calc: "1700.00" (via JS) |
| 5 | Click "Add Fee" | POST to store |
| 6 | DB: amount=1500.00, fine_amount=200.00, total_amount=1700.00 | Correct values |
| 7 | Verify status = 'Pending' | Default applied |

### TC-P04: Create Fee Master With Remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, fill required fields | Fields set |
| 2 | Remark = "Test fee remark for April 2026" | Remark entered |
| 3 | Click "Add Fee" | POST to store |
| 4 | DB: remark = "Test fee remark for April 2026" | Saved correctly |

### TC-P05: View Fee Master Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fee Creation tab -> Action -> View | GET `/fee-master/{id}` |
| 2 | Gate authorize('view') passes | Authorized |
| 3 | Breadcrumb: "Transport Fee Master Information" | Breadcrumb visible |
| 4 | 8 detail rows: Academic Session, Month, Fee Amount, Due Date, Fine Amount, Total Amount, Status, Remark | All rows present |
| 5 | Month formatted as "F Y" | e.g. "April 2026" |
| 6 | Monetary values formatted with `number_format` | `₹ 1,500.00` |
| 7 | Status badge colored | bg-success (Paid) or bg-warning (Pending) |

### TC-P06: View Fee Master -- Collection History

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Show page for fee master with collections | `/fee-master/{id}` |
| 2 | "Fee Collection History" card visible | Card with 6-column table |
| 3 | Columns: #, Paid Amount, Payment Date, Payment Mode, Status, Remarks | Correct headers |
| 4 | Each collection row: sequential #, formatted amount, date d-m-Y | Correct display |
| 5 | Empty state when no collections | "No fee collection found" |

### TC-P07: Edit Fee Master Pre-Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab -> Action -> Edit | GET `/fee-master/{id}/edit` |
| 2 | Form action points to update route | `PUT` method spoof |
| 3 | Academic Session pre-selected | `old('id', $feeMaster->std_academic_sessions_id)` matches |
| 4 | Month input shows YYYY-MM-DD | Parsed from DB date |
| 5 | Amount, due_date, fine_amount pre-filled | Existing values shown |
| 6 | total_amount readonly + pre-filled | Shows amount + fine |
| 7 | Remark textarea pre-filled | Existing remark |

### TC-P08: Update Fee Master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit page, change Amount 1500 -> 2000 | New value |
| 2 | Change Due Date | New date |
| 3 | Click "Update Fee" | PUT `/fee-master/{id}` |
| 4 | FeeMasterRequest validates | Rules pass |
| 5 | Gate authorize('update') | Authorized |
| 6 | findOrFail($id) | Found |
| 7 | month re-parsed via Carbon | startOfMonth applied |
| 8 | update([7 fields]) -- status NOT included | 7 fields updated |
| 9 | StudentPayLog('fee_master_updated') | Log created |
| 10 | activityLog('Updated') | Activity logged |
| 11 | Redirect + flash('updated.fee_master') | Success |
| 12 | DB: amount=2000.00, due_date=new | Correct |
| 13 | Status unchanged | Original status preserved |

### TC-P09: Soft Delete Fee Master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab -> Action -> Delete on fee master | DELETE `/fee-master/{id}` |
| 2 | Confirm deletion | Confirm dialog submitted |
| 3 | DB transaction: feeCollections()->delete() first | Children soft-deleted |
| 4 | DB transaction: $feeMaster->delete() second | Parent soft-deleted |
| 5 | Redirect + flash('trashed.fee_master') | Success |
| 6 | DB: deleted_at IS NOT NULL | Soft-deleted |
| 7 | Collections also soft-deleted | deleted_at NOT NULL |
| 8 | Record hidden from main list | Not visible |
| 9 | Visible in trash list | `/fee-master/trash/view` |
| 10 | Activity log: event='Trash' | "Fee Master & related collections trashed" |
| 11 | StudentPayLog: 'fee_master_deleted' | Entry exists |

### TC-P10: Trash Page Shows Deleted Fee Masters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/fee-master/trash/view` | Trash page |
| 2 | Gate authorize('restore') | Authorized |
| 3 | Table columns: Session, Month, Amount, Due Date, Fine, Action | 6 columns |
| 4 | `onlyTrashed()->paginate(20)` | Only soft-deleted records |
| 5 | Action column has Restore + Force Delete | `action-trashed` component |
| 6 | Pagination if >20 | `$data->links()` |
| 7 | Empty state: "No trashed records found" | `@empty` block |

### TC-P11: Restore Fee Master From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trash page -> find record | Visible in table |
| 2 | Click Restore | GET `/fee-master/{id}/restore` |
| 3 | onlyTrashed() with feeCollections onlyTrashed() | Found |
| 4 | DB transaction: $feeMaster->restore() first | Parent restored |
| 5 | DB: feeCollections()->restore() | Children restored |
| 6 | Redirect + flash('restored.fee_master') | Success |
| 7 | DB: deleted_at=NULL | Restored |
| 8 | Collections: deleted_at=NULL | Also restored |
| 9 | Back on Fee Creation tab -> visible | Record in main list |
| 10 | Activity: event='Restored' | "Fee Master & collections restored" |
| 11 | StudentPayLog: 'fee_master_restored' | Entry exists |

### TC-P12: Force Delete Fee Master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trash page -> Force Delete on trashed record | DELETE `/fee-master/{id}/force-delete` |
| 2 | Gate authorize('forceDelete') | Authorized |
| 3 | onlyTrashed() finds record | Found |
| 4 | Transaction: feeCollections()->forceDelete() | Children permanently gone |
| 5 | Transaction: $feeMaster->forceDelete() | Parent permanently gone |
| 6 | Redirect + flash('force_deleted.fee_master') | Success |
| 7 | DB: record GONE | Not found |
| 8 | Collections also GONE | Not found |
| 9 | Activity: event='Force Deleted' | "Fee Master & collections permanently deleted" |
| 10 | StudentPayLog: 'fee_master_force_deleted' | Entry exists |

### TC-P13: Toggle Pending -> Paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab, find Pending fee master | Badge bg-secondary |
| 2 | Click toggle with is_active=1 | POST `/fee-master/{id}/toggle-status` |
| 3 | Gate authorize('update') | Authorized |
| 4 | filter_var('1', FILTER_VALIDATE_BOOLEAN) -> true | Boolean true |
| 5 | status = 'Paid' | Property set |
| 6 | $feeMaster->save() succeeds | DB updated |
| 7 | JSON `{success:true, status:'Paid', message}` | 200 OK |
| 8 | UI badge updates to "Paid" bg-success | Visual update |
| 9 | activityLog('Toggled') | "Fee Master status updated." |
| 10 | StudentPayLog('fee_master_status_changed') | Entry exists |

### TC-P14: Toggle Paid -> Pending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find Paid fee master | Badge bg-success |
| 2 | Click toggle with is_active=0 | POST |
| 3 | filter_var('0') -> false | Boolean false |
| 4 | status = 'Pending' | Property set |
| 5 | JSON `{success:true, status:'Pending'}` | 200 OK |
| 6 | UI badge -> "Pending" bg-secondary | Updated |

### TC-P15: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master | POST with flash "created" |
| 2 | View record show page | 8 detail rows |
| 3 | Edit: change amount 1500 -> 2500 | PUT with flash "updated" |
| 4 | DB: amount=2500.00 | Updated |
| 5 | Toggle status to Paid | JSON success |
| 6 | Toggle status back to Pending | JSON success |
| 7 | Delete fee master | DELETE with flash "trashed" |
| 8 | Navigate to trash | Record visible |
| 9 | Restore fee master | GET with flash "restored" |
| 10 | Back to main list | Visible |
| 11 | Delete again -> Force delete | Permanently gone |
| 12 | Verify 6 StudentPayLog entries | 6 distinct activity_types |
| 13 | Verify 6 activityLog entries | 6 distinct events |

### TC-P16: Export Fee Masters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab -> Click Export button | GET `/fee-master/allocation/export` |
| 2 | Gate authorize('viewAny') | Authorized |
| 3 | Download starts | .xlsx Content-Type |
| 4 | Filename: `fee_master_export_YYYY-MM-DD.xlsx` | Correct date |

### TC-P17: Download Fee Master PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab -> Action -> Download PDF | GET `/fee-master/{id}/pdf` |
| 2 | Gate authorize('view') | Authorized |
| 3 | findOrFail finds record | Found |
| 4 | Collections + Fines loaded | 2 queries by student_fee_detail_id |
| 5 | PDF generated via DomPDF | A4 portrait |
| 6 | Filename: `fee_master_{id}.pdf` | Correct |

### TC-P18: Import Valid File

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare valid .xlsx: headers roll_number, month, fee_amount, due_date | 3 valid rows |
| 2 | Click Import button -> modal | Modal opens |
| 3 | Select file, click upload | POST `/fee-master/validate/file` |
| 4 | Gate authorize('create') | Authorized |
| 5 | Mime check: xlsx/csv | Passes |
| 6 | Excel parsed -> rows validated | All valid |
| 7 | JSON `{status:'success', file:'imports/...'}` | Success |
| 8 | Session: `fee_master_import_file` set | File path stored |
| 9 | Click "Start Import" | POST `/fee-master/start/import` |
| 10 | Excel::import(FeeMasterImport) runs | 3 records created |
| 11 | JSON `{status:'completed'}` | Done |
| 12 | DB: 3 new fee masters with correct data | Imported |

### TC-P19 Filter By Due Date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fee Creation tab, enter due_date filter | Date set |
| 2 | Click Search | GET with due_date param |
| 3 | FeeMasterQuery applies whereDate('due_date') | Filtered |
| 4 | Only matching records shown | Correct result |
| 5 | Click Reset | URL without params |

### TC-P20 Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No fee master records | Empty dataset |
| 2 | Navigate to Fee Creation tab | Tab loads |
| 3 | "No Fee Master Records Found" colspan=8 | Empty state |
| 4 | Table headers still visible | All 8 columns |

### TC-P21 Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12 fee masters | 12 records |
| 2 | Tab shows 10 per page | Page 1: 10 records |
| 3 | Pagination links visible | `$feeMasters->withQueryString()->links()` |
| 4 | Page 2: 2 remaining records | Correct count |

### TC-P22 Activity Log Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT update fee master | Update done |
| 2 | `activity_logs`: event='Updated' | Entry exists |
| 3 | Description = "Fee Master updated" | Correct |

### TC-P23 Activity Log Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE fee master | Soft-deleted |
| 2 | `activity_logs`: event='Trash' | Entry exists |
| 3 | Description = "Fee Master & related collections trashed" | Correct |

### TC-P24 Activity Log Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore fee master | Restored |
| 2 | `activity_logs`: event='Restored' | Entry exists |
| 3 | Description = "Fee Master & collections restored" | Correct |

### TC-P25 Activity Log Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete fee master | Permanently deleted |
| 2 | `activity_logs`: event='Force Deleted' | Entry exists |
| 3 | Description = "Fee Master & collections permanently deleted" | Correct |

### TC-P26 Activity Log Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status | Toggled |
| 2 | `activity_logs`: event='Toggled' | Entry exists |
| 3 | Description = "Fee Master status updated." | Correct |

### TC-P27 StudentPayLog Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT update fee master | Update done |
| 2 | `activity_type='fee_master_updated'` | Entry |
| 3 | `reference_table='tpt_fee_master'` | Correct |
| 4 | `reference_id={id}` | Correct |
| 5 | `module_name='Transport'` | Correct |
| 6 | `triggered_by=auth user id` | Correct |
| 7 | `amount=total_amount` | Captured |

### TC-P28 StudentPayLog Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE fee master | Soft-deleted |
| 2 | `activity_type='fee_master_deleted'` | Entry exists |

### TC-P29 StudentPayLog Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore fee master | Restored |
| 2 | `activity_type='fee_master_restored'` | Entry exists |

### TC-P30 StudentPayLog Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete fee master | Permanently deleted |
| 2 | `activity_type='fee_master_force_deleted'` | Entry exists |

### TC-P31 StudentPayLog Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status | Toggled |
| 2 | `activity_type='fee_master_status_changed'` | Entry exists |

### TC-N01: Missing std_academic_sessions_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, leave session empty | No selection |
| 2 | Fill all other required fields | Valid |
| 3 | Click "Add Fee" | Form submitted |
| 4 | Rule: `required` fails | "Student academic session is required." |
| 5 | No record created | DB unchanged |

### TC-N02: Missing month

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, leave month empty | Blank |
| 2 | Fill all other fields | Valid |
| 3 | Click "Add Fee" | Validation fails |
| 4 | "Month is required." | Error shown |

### TC-N03: Missing amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, amount empty | Blank |
| 2 | Other fields valid | Valid |
| 3 | Submit | Validation fails |
| 4 | "Amount is required." | Error shown |

### TC-N04: Missing due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, due_date empty | Blank |
| 2 | Other fields valid | Valid |
| 3 | Submit | Validation fails |
| 4 | "Due date is required." | Error shown |

### TC-N05: Invalid std_academic_sessions_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set std_academic_sessions_id = 99999 | Non-existent |
| 2 | Other fields valid | Valid |
| 3 | Submit | Validation fails |
| 4 | "Selected student session is invalid." | Error |

### TC-N06: Negative amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Amount = -100 | Negative |
| 2 | Submit | Rule: min:0 fails |
| 3 | "The amount must be at least 0." | Error |

### TC-N07: Non-numeric amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Amount = "abc" | Non-numeric |
| 2 | Submit | Rule: numeric fails |
| 3 | "The amount must be a number." | Error |

### TC-N08: Invalid month

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Month = "not-a-date" | Invalid |
| 2 | Submit | Rule: date fails |
| 3 | Error shown | Form re-displayed |

### TC-N09: Invalid due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | due_date = "invalid" | Invalid |
| 2 | Submit | Rule: date fails |
| 3 | Error shown | Form re-displayed |

### TC-N10: Remark > 255 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remark = 300 chars | Exceeds max:255 |
| 2 | Submit | rule: max:255 fails |
| 3 | "The remark must not be greater than 255 characters." | Error |
| 4 | Note: DDL allows 512 but request limits to 255 | Discrepancy |

### TC-N11: View invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/fee-master/99999` | Non-existent |
| 2 | findOrFail(99999) | ModelNotFoundException |
| 3 | 404 response | HTTP 404 |

### TC-N12: Edit invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/fee-master/99999/edit` | Non-existent |
| 2 | findOrFail(99999) -> 404 | HTTP 404 |

### TC-N13: Update invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/fee-master/99999` | Non-existent |
| 2 | findOrFail(99999) -> 404 | HTTP 404 |

### TC-N14: Delete invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/fee-master/99999` | Non-existent |
| 2 | with('feeCollections')->findOrFail(99999) -> 404 | HTTP 404 |

### TC-N15: Restore non-deleted record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active fee master (deleted_at=NULL) | Active |
| 2 | GET `/fee-master/{id}/restore` | onlyTrashed() finds nothing |
| 3 | ModelNotFoundException -> 404 | HTTP 404 |

### TC-N16: Force delete non-trashed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active fee master (not in trash) | deleted_at=NULL |
| 2 | DELETE `/fee-master/{id}/force-delete` | onlyTrashed() -> null |
| 3 | 404 (must soft-delete first) | Two-step required |

### TC-N17: Toggle invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/fee-master/99999/toggle-status` | Non-existent |
| 2 | findOrFail(99999) -> 404 | HTTP 404 |

### TC-N18: Import invalid file extension

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST validate/file with .pdf | Invalid format |
| 2 | Rule: mimes:xlsx,csv fails | "must be a file of type: xlsx, csv" |
| 3 | No file stored | Session key NOT set |

### TC-N19: Import invalid roll number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Excel row: roll_number="NONEXISTENT" | Invalid |
| 2 | POST validate/file -> validation loop | `StudentAcademicSession::where('roll_no','NONEXISTENT')->first()` = null |
| 3 | Error TXT: "Row 1 : Invalid Student Roll Number Invalid ('NONEXISTENT')" | TXT download |
| 4 | TXT: "TOTAL ROWS : 1\nFAILED ROWS : 1" | Correct counts |

### TC-N20: Import missing columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Excel row: roll_number empty | Missing |
| 2 | `$roll_no === ''` -> error | "Student Roll Number Invalid missing" |
| 3 | Error TXT returned | TXT download |

### TC-N21: Permission 403 all endpoints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login without fee-master permissions | Restricted user |
| 2 | GET `/fee-master` | `Gate::authorize('viewAny')` -> 403 |
| 3 | GET `/fee-master/create` | 403 |
| 4 | POST `/fee-master` | `FeeMasterRequest::authorize()` -> 403 |
| 5 | GET `/fee-master/{id}` | 403 |
| 6 | GET `/fee-master/{id}/edit` | 403 |
| 7 | PUT `/fee-master/{id}` | 403 |
| 8 | DELETE `/fee-master/{id}` | 403 |
| 9 | POST toggle-status | 403 |
| 10 | GET pdf | 403 |
| 11 | GET trash | 403 |
| 12 | GET restore | 403 |
| 13 | DELETE force-delete | 403 |

### TC-N22: Guest redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (guest) | No auth |
| 2 | All `/fee-master/*` URLs | Redirect to `/login` |
| 3 | `/std-route-Fees-mgmt` | Redirect to `/login` |

### TC-N23: XSS in Remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remark = "<script>alert('xss')</script>" | Stored literally |
| 2 | View show page | Blade `{{ }}` escapes -> `&lt;script&gt;alert('xss')&lt;/script&gt;` |
| 3 | Script does NOT execute | XSS prevented |

### TC-N24: Standalone index bug

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/fee-master` (standalone, NOT tab) | `FeeMasterController@index()` |
| 2 | Returns `'data' => paginate(20)` | Variable is $data |
| 3 | Blade expects `$feeMasters` | `Undefined variable $feeMasters` error |
| 4 | Not reachable via normal UI | Latent bug via direct URL |

### TC-N25: Export button wrong controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect export button data-url | `route('transport.fee-collection.export')` -- WRONG |
| 2 | Correct route: `transport.fee-master.export` | Points to FeeMasterController |
| 3 | Current link exports Fee Collections, not Fee Masters | Bug confirmed |

### TC-N26: Edit permission mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with 'update' but without 'edit' | Partial perms |
| 2 | Edit button HIDDEN (blade @can('edit') fails) | Button not visible |
| 3 | Direct URL `/fee-master/{id}/edit` -> loads (Gate@update passes) | **Inconsistency**: button hidden but URL works |
| 4 | User with 'edit' but without 'update' | Reversed |
| 5 | Edit button VISIBLE (blade @can('edit') passes) | Button shown |
| 6 | Click -> controller Gate@update fails -> 403 | **Mismatch bug** |

### TC-N27: Export permission mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with 'viewAny' but without 'export' | Partial perms |
| 2 | Export button HIDDEN (blade @can('export') fails) | Button hidden |
| 3 | Direct URL `/fee-master/allocation/export` -> works (Gate@viewAny passes) | **Inconsistency**: hidden but URL works |
| 4 | User with 'export' but without 'viewAny' | Reversed |
| 5 | Export button VISIBLE | Button shown |
| 6 | Click -> controller Gate@viewAny fails -> 403 | **Mismatch bug** |

### TC-D01: Soft Delete -- Collections Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master (id=X) + collections | Both exist |
| 2 | DELETE destroy(X) | Controller hit |
| 3 | DB::transaction() wraps both deletes | Transactional |
| 4 | feeCollections()->delete() FIRST | Children soft-deleted |
| 5 | $feeMaster->delete() SECOND | Parent soft-deleted |
| 6 | Both: deleted_at NOT NULL | Verification |

### TC-D02: Restore -- Collections Also Restored

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Both fee master + collections soft-deleted | Trashed |
| 2 | GET restore(X) | Controller hit |
| 3 | Transaction: $feeMaster->restore() FIRST | Parent restored |
| 4 | Transaction: feeCollections()->restore() | Children restored |
| 5 | Both: deleted_at=NULL | Verified |

### TC-D03: Force Delete -- Collections Also Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Both soft-deleted | Trashed |
| 2 | DELETE force-delete | Controller hit |
| 3 | Transaction: feeCollections()->forceDelete() | Children gone |
| 4 | Transaction: $feeMaster->forceDelete() | Parent gone |
| 5 | Both: no DB rows remain | Permanently deleted |

### TC-D04: StudentPayLog After Every Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create | 'fee_master_created' |
| 2 | Update | 'fee_master_updated' |
| 3 | Delete | 'fee_master_deleted' |
| 4 | Restore | 'fee_master_restored' |
| 5 | Force delete | 'fee_master_force_deleted' |
| 6 | Toggle | 'fee_master_status_changed' |
| 7 | All: reference_table='tpt_fee_master' | Consistent |
| 8 | All: module_name='Transport' | Consistent |

### TC-D05: DDL RESTRICT -- Direct Delete Blocked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master with collections | Collections reference id=X |
| 2 | Direct DB: `DELETE FROM tpt_student_fee_detail WHERE id=X` | FK RESTRICT blocks: Integrity constraint violation |
| 3 | Controller's destroy() avoids this by soft-deleting collections FIRST then parent | Safe via transaction |
| 4 | forceDelete() also deletes collections first then parent | Also safe |

### TC-CR01: Blade @can Tab Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `stdroutefeesmgmt.blade.php` | `@can('viewAny')` wraps `@include('transport::fee-master.index')` |
| 2 | Inspect `fee-master/index.blade.php` line 30 | `@canany(['import','export'])` wraps buttons |
| 3 | Inspect line 71 | `@canany(['view','edit','delete','pdf'])` wraps action column |
| 4 | User with all perms -> all visible | Correct |
| 5 | User with viewAny only -> no action, no import/export | Correct |

### TC-CR02: Import/Export Button Guards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 30: @canany wraps import+export div | Both or none |
| 2 | Line 32: @can('import') wraps import button | Individual check |
| 3 | Line 41: @can('export') wraps export button | Individual check |
| 4 | Import-only user: sees import button | Correct |

### TC-CR03: Action Dropdown Guards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 102: @canany wraps action td | All or nothing |
| 2 | Line 119: @can('view') wraps View link | Per-item check |
| 3 | Line 129: @can('edit') wraps Edit link | Per-item check |
| 4 | Line 154: @can('pdf') wraps PDF link | Per-item check |
| 5 | Line 164: @can('delete') wraps Delete form | Per-item check |

### TC-CR04: Gate::authorize() Before Every Method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | index() line 29 | `Gate::authorize('viewAny')` |
| 2 | create() line 56 | `Gate::authorize('create')` |
| 3 | store() line 63 | `Gate::authorize('create')` |
| 4 | show() line 99 | `Gate::authorize('view')` |
| 5 | edit() line 106 | `Gate::authorize('update')` |
| 6 | update() line 114 | `Gate::authorize('update')` |
| 7 | destroy() line 151 | `Gate::authorize('delete')` |
| 8 | trashed() line 182 | `Gate::authorize('restore')` |
| 9 | restore() line 189 | `Gate::authorize('restore')` |
| 10 | forceDelete() line 224 | `Gate::authorize('forceDelete')` |
| 11 | toggleStatus() line 260 | `Gate::authorize('update')` |
| 12 | validateFile() line 299 | `Gate::authorize('create')` |
| 13 | startImport() line 415 | `Gate::authorize('create')` |
| 14 | export() line 440 | `Gate::authorize('viewAny')` |
| 15 | downloadPdf() line 37 | `Gate::authorize('view')` |

### TC-CR05: activityLog After Every CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store() line 77 | `activityLog($feeMaster, 'Created', ...)` |
| 2 | update() line 141 | `activityLog($feeMaster, 'Updated', ...)` |
| 3 | destroy() line 171 | `activityLog($feeMaster, 'Trash', ...)` |
| 4 | restore() line 213 | `activityLog($feeMaster, 'Restored', ...)` |
| 5 | forceDelete() line 236 | `activityLog($feeMaster, 'Force Deleted', ...)` |
| 6 | toggleStatus() line 266 | `activityLog($feeMaster, 'Toggled', ...)` |

### TC-CR06: StudentPayLog After Every Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store() line 81 | `activity_type = 'fee_master_created'` |
| 2 | update() line 129 | `activity_type = 'fee_master_updated'` |
| 3 | destroy() line 159 | `activity_type = 'fee_master_deleted'` |
| 4 | restore() line 201 | `activity_type = 'fee_master_restored'` |
| 5 | forceDelete() line 240 | `activity_type = 'fee_master_force_deleted'` |
| 6 | toggleStatus() line 270 | `activity_type = 'fee_master_status_changed'` |

### TC-CR07: DB Transaction for Delete/Restore/ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | destroy() line 154 | `DB::transaction(function() { ... })` |
| 2 | restore() line 196 | `DB::transaction(function() { ... })` |
| 3 | forceDelete() line 231 | `DB::transaction(function() { ... })` |

### TC-CR08: onlyTrashed() for Restore and ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | restore() line 190 | `TptFeeMaster::onlyTrashed()->with([...])->findOrFail($id)` |
| 2 | forceDelete() line 225 | `TptFeeMaster::onlyTrashed()->with([...])->findOrFail($id)` |

### TC-CR09: Non-RESTful Action Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | toggleStatus() line 258 | POST `/fee-master/{id}/toggle-status` |
| 2 | validateFile() line 297 | POST `/fee-master/validate/file` |
| 3 | startImport() line 413 | POST `/fee-master/start/import` |
| 4 | export() line 438 | GET `/fee-master/allocation/export` |
| 5 | downloadPdf() line 35 | GET `/fee-master/{id}/pdf` |

### TC-CR10: FeeMasterRequest authorize() matches Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST -> FeeMasterRequest::authorize() | `Gate::allows('tenant.fee-master.create')` |
| 2 | PUT/PATCH -> FeeMasterRequest::authorize() | `Gate::allows('tenant.fee-master.update')` |

### TC-CR11: Validation Match DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | amount: numeric | Matches DECIMAL(10,2) |
| 2 | remark: max:255 | Discrepancy: DDL VARCHAR(512) |
| 3 | month: date | Matches DATE |
| 4 | due_date: date | Matches DATE |

### TC-CR12: Model Table + SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Model line 15 | `protected $table = 'tpt_student_fee_detail'` |
| 2 | Model line 13 | `use SoftDeletes` trait |

### TC-CR13: Fillable Matches DB Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Model lines 17-26 | 8 fields in $fillable |
| 2 | All 8 correspond to DDL columns | Yes (except Remark/remark case) |

### TC-CR14: No Explicit Casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Model file search `protected $casts` | NOT defined |
| 2 | Decimal amounts stored as raw values | No casting |

### TC-CR15: Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | feeCollections() line 40 | `HasMany(TptStudentFeeCollection, student_fee_detail_id)` |
| 2 | academicSession() line 50 | `BelongsTo(StudentAcademicSession, std_academic_sessions_id)` |
| 3 | session() line 31 | `BelongsTo(OrganizationAcademicSession, std_academic_sessions_id)` |

### TC-CR16: Routes Resource + Additional

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | web.php line 204 | `Route::resource('fee-master', FeeMasterController::class)` |
| 2 | Additional routes lines 206-214 | trash, restore, forceDelete, toggleStatus, validate-file, start-import, export, pdf |

### TC-CR17: Route Names Prefixed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All routes use `transport.fee-master.*` | Consistent naming |
| 2 | Tab route: `transport.std-route-Fees-mgmt.index` | Separate prefix |

### TC-CR18: Table Columns Match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade lines 63-73 | 8 th elements |
| 2 | All 8 match requirements | Session, Month, Amount, Due Date, Students, Collected, Status, Action |

### TC-CR19: Filter Controls Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Due date input line 13 | `<input type="date" name="due_date">` |
| 2 | Search button line 21 | `<button type="submit">` |
| 3 | Reset button line 24 | `<a href="{{ url()->current() }}">` |

### TC-CR20: Show Page Displays All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Show view lines 26-83 | 8 `<tr>` detail rows |
| 2 | Each field: label + value | All present |

### TC-CR21: Flash Messages After Every CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store(): `flash('created.fee_master')` | "Fee Master created successfully" |
| 2 | update(): `flash('updated.fee_master')` | "Fee Master updated successfully" |
| 3 | destroy(): `flash('trashed.fee_master')` | "Fee Master trashed successfully" |
| 4 | restore(): `flash('restored.fee_master')` | "Fee Master restored successfully" |
| 5 | forceDelete(): `flash('force_deleted.fee_master')` | "Fee Master permanently deleted successfully" |

### TC-CR22: Null Safety for Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$fm->academicSession->academicSession->name ?? '-'` | Null coalescing |
| 2 | `$fm->due_date` | Direct column (no null chain) |

### TC-CR23: No Unique Constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL inspection | No UNIQUE KEY on any column |
| 2 | Same (session_id, month) can be duplicated | Allowed |

### TC-CR24: No updated_at in DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Migration inspection | Only `created_at` with `useCurrent()` |
| 2 | No `timestamps()` or `updated_at` | Missing column |

### TC-CR25: Remark vs remark Discrepancy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL line 22: `$table->string('Remark', 512)` | Capital R |
| 2 | Model line 25: `'remark'` | Lowercase |
| 3 | MySQL case-insensitive | Works, but not portable |

### TC-CR26: JS Auto-Calc Total Amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `calculateFinalAmount()` function | `amount + fine -> total_amount` |
| 2 | Input events on amount and fine_amount | Both trigger recalculation |
| 3 | total_amount readonly | User cannot override |

### TC-CR27: validateFile Error TXT Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Error TXT generated | "TOTAL ROWS : N\nFAILED ROWS : N\n\n" header |
| 2 | Per-row errors: "Row N : message" | Individual errors |
| 3 | Content-Disposition: attachment | Downloaded as .txt |

---
*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: FeeCreation (FeeMaster) | Date: 2026-07-21*


## 8. Additional Edge & Boundary Test Cases

### TC-EDGE-01: Create fee master with amount = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, amount = 0 | min:0 passes (0 is allowed) |
| 2 | Other fields valid | Submit |
| 3 | Fee master created with amount=0.00 | OK |
| 4 | Status = 'Pending' | Default |

### TC-EDGE-02: Create fee master with fine_amount = 0 (explicit)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, amount=1500, fine_amount=0 | Explicit zero |
| 2 | total_amount auto-calc = 1500.00 | Correct |
| 3 | Submit -> fine_amount=0.00 in DB | Stored |

### TC-EDGE-03: Create fee master with due_date in past

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Due date = last year | Past date |
| 2 | Submit | Created (no date validation requiring future) |
| 3 | No validation rule prevents past dates | date rule only validates format |

### TC-EDGE-04: Create fee master with due_date far future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Due date = 2099-12-31 | Far future |
| 2 | Submit | Created (no max date validation) |

### TC-EDGE-05: Create fee master with month far past/future

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Month = 2000-01-01 or 2100-01-01 | Far dates |
| 2 | Submit | Created (no range validation on date) |

### TC-EDGE-06: Create fee master with large amount (decimal precision)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Amount = 9999999.99 | 9 digits + 2 decimals |
| 2 | Submit | DECIMAL(10,2) stores correctly |
| 3 | Amount = 99999999.99 | Too large for DECIMAL(10,2) -> truncation/error |

### TC-EDGE-07: Update fee master with NO field changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit form, submit without changing any values | PUT with same data |
| 2 | update() called with identical values | DB updated (same values) |
| 3 | StudentPayLog created | Still logs 'fee_master_updated' |
| 4 | activityLog created | Still logs 'Updated' |

### TC-EDGE-08: Toggle status on already-Paid fee master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fee master has status 'Paid' | Already paid |
| 2 | Toggle with is_active=1 | filter_var(true) -> 'Paid' still |
| 3 | JSON: status='Paid' (no change) | Same status returned |
| 4 | StudentPayLog still created | activity_type='fee_master_status_changed' |

### TC-EDGE-09: Create 2 fee masters for same student+month (no unique constraint)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master: session_id=X, month=2026-04-01 | Record 1 |
| 2 | Create fee master: session_id=X, month=2026-04-01 | Record 2 (allowed, no UQ) |
| 3 | Both records exist in DB | Duplicate fee masters allowed |

### TC-EDGE-10: Soft-delete fee master with NO collections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master with no collections | feeCollections count = 0 |
| 2 | DELETE destroy | Transaction: feeCollections()->delete() on empty = no-op |
| 3 | $feeMaster->delete() still works | Soft-deleted |

### TC-EDGE-11: Restore fee master with already-restored collections (idempotency)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete fee master with collections | Both trashed |
| 2 | Manually restore collections first | Collections restored individually |
| 3 | Call restore() on fee master | ->restore() works; feeCollections()->restore() on already-restored = no-op (idempotent) |

### TC-EDGE-12: Force delete fee master with already-force-deleted collections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete then manually force-delete all collections | Collections gone |
| 2 | Call forceDelete(X) | $feeMaster (onlyTrashed) found; feeCollections()->forceDelete() on empty = no-op |
| 3 | $feeMaster->forceDelete() works | Parent permanently deleted |

### TC-EDGE-13: validateFile with empty Excel (0 data rows)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload .xlsx with only header row, no data rows | 0 rows |
| 2 | $totalRows = 0, loop never executes | No errors |
| 3 | JSON `{status:'success', file:...}` returned | File stored |
| 4 | startImport -> 0 records created | Import completes |

### TC-EDGE-14: validateFile with 1000 rows (performance)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload .xlsx with 1000 valid rows | Large file |
| 2 | validateFile loops 1000 times | Completes within timeout |
| 3 | startImport creates 1000 fee masters | Batch import works |

### TC-EDGE-15: validateFile with Excel serial date for month

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Excel cell with serial number 46000 (approx 2025-12-15) | Serial date |
| 2 | validateFile checks `$month == ''` -> NOT empty | Valid |
| 3 | startImport -> FeeMasterImport -> Date::excelToDateTimeObject(46000) | Parsed to 2025-12-01 (startOfMonth) |

### TC-EDGE-16: StudentPayLog with null student relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fee master referencing academic session where student is deleted/null | `$feeMaster->academicSession->student` is null |
| 2 | store() creates StudentPayLog | `isset(null->id)` -> false -> `""` used as student_id |
| 3 | StudentPayLog created with student_id="" | Empty string stored |

### TC-EDGE-17: Multiple toggles in rapid succession

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle Pending -> Paid | Status = 'Paid' |
| 2 | Immediately toggle Paid -> Pending | Status = 'Pending' |
| 3 | Immediately toggle Pending -> Paid | Status = 'Paid' |
| 4 | 3 StudentPayLog entries created | 3x 'fee_master_status_changed' |

### TC-EDGE-18: Cross-tenant data isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tenant A creates fee master | Visible only in Tenant A |
| 2 | Tenant B loads Fee Creation tab | Tenant B's data only |
| 3 | FeeMasterQuery uses current tenant scope | `tenancy()->initialize()` ensures isolation |

### TC-EDGE-19: Download PDF for fee master with null fine_amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master, leave fine_amount=0 (default) | fine_amount=0.00 |
| 2 | Download PDF | PDF renders fine_amount=0.00 |
| 3 | PDF view accesses fine_amount -> no null error | safe |

### TC-EDGE-20: Download PDF for fee master with 100 collections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fee master has 100 fee collections | Large dataset |
| 2 | downloadPdf loads all collections | `->get()` returns 100 rows |
| 3 | PDF generated with all 100 collection rows | DomPDF handles pagination |

### TC-EDGE-21: Toggle with is_active="true" string (not "1")

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST toggle-status with is_active="true" | filter_var("true", FILTER_VALIDATE_BOOLEAN) = true |
| 2 | Status set to 'Paid' | Correct |

### TC-EDGE-22: Toggle with is_active="yes" string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST is_active="yes" | filter_var -> true -> 'Paid' |

### TC-EDGE-23: Toggle with is_active="off" string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST is_active="off" | filter_var -> false -> 'Pending' |

### TC-EDGE-24: store() with month already in YYYY-MM-DD format (not YYYY-MM)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Month input sends full date YYYY-MM-DD (from input type=date) | e.g. "2026-04-15" |
| 2 | Carbon::parse("2026-04-15") -> startOfMonth -> "2026-04-01" | Stored as first of month |

### TC-EDGE-25: store() with malformed month string (not caught by date validation?)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Month = "abc" | Rule: date fails -> validation error |
| 2 | Never reaches controller | Protected |

### TC-CONCURRENCY-01: Simultaneous soft-delete + restore race

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A sends DELETE on fee master | Transaction started |
| 2 | User B sends GET restore on same fee master at same time | Race condition |
| 3 | Only one should win; second gets 404 or ModelNotFound | DB transaction isolation |

### TC-CONCURRENCY-02: Simultaneous toggle status race

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Two simultaneous POST toggle-status for same id | Both process, last save() wins |
| 2 | StudentPayLog records both actions | Both logged |

### TC-CONCURRENCY-03: Import while another import running

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Start import 1 (large file) | Session set |
| 2 | Start import 2 (different file) | Session OVERWRITTEN |
| 3 | Import 1's file reference lost | Second import uses wrong file |

### TC-UI-01: Import modal -- download sample file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Import button | Modal opens |
| 2 | Verify sample download link | `data-sample-file="{{ Storage::url('transport/fee_master/fee_master.xlsx') }}"` |
| 3 | Click sample file link | Excel template downloaded |

### TC-UI-02: Import modal -- close and re-open

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open import modal | Modal visible |
| 2 | Close modal | Modal hidden |
| 3 | Re-open modal | Modal re-initialized properly |

### TC-UI-03: Mobile responsive -- table scroll

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | View Fee Creation tab on mobile (375px width) | Table horizontally scrollable |
| 2 | All 8 columns accessible | No content cut off |

### TC-DB-01: Create fee master -- verify created_at is set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master | id=X |
| 2 | DB: `SELECT created_at FROM tpt_student_fee_detail WHERE id=X` | Timestamp set (DEFAULT CURRENT_TIMESTAMP) |

### TC-DB-02: Create fee master -- verify DDL defaults (fine_amount=0.00)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert directly: `INSERT INTO tpt_student_fee_detail (std_academic_sessions_id, month, amount, due_date, total_amount) VALUES (1, '2026-04-01', 1500, '2026-04-15', 1500)` | fine_amount defaults to 0.00, status defaults to 'Pending' |

### TC-DB-03: Verify soft-delete sets deleted_at, does NOT remove row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete fee master | Row in tpt_student_fee_detail with id still exists |
| 2 | `SELECT COUNT(*) FROM tpt_student_fee_detail WHERE id=X` | 1 (not deleted) |
| 3 | `SELECT COUNT(*) FROM tpt_student_fee_detail WHERE id=X AND deleted_at IS NULL` | 0 (soft-deleted) |

### TC-DB-04: Verify force-delete removes row permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete soft-deleted fee master | Row removed |
| 2 | `SELECT COUNT(*) FROM tpt_student_fee_detail WHERE id=X` | 0 (permanently gone) |

### TC-DB-05: StudentPayLog table -- verify all columns stored

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee master -> triggers StudentPayLog | Row in std_student_pay_log |
| 2 | Verify: student_id, academic_session_id, module_name='Transport', activity_type, amount, reference_id, reference_table='tpt_fee_master', description, triggered_by | All populated |

---

## 9. Regression Impact Analysis

| Scenario | Change | Affected Components | Risk |
|----------|--------|--------------------|------|
| RIA-01 | Rename `Remark` column to `remark` in DDL | Model fillable, DDL migration | Low -- model already uses lowercase |
| RIA-02 | Add `updated_at` column to DDL | BaseModel timestamps, all update operations | Low -- Eloquent expects it |
| RIA-03 | Fix standalone index() variable name ($data -> $feeMasters) | FeeMasterController@index() | Low -- variable rename only |
| RIA-04 | Fix export button URL (fee-collection -> fee-master) | fee-master/index.blade.php line 43 | Low -- route URL change |
| RIA-05 | Add `tenant.fee-master.forceDelete` permission | Policy, Gate checks, blade directives | Medium -- new permission check |
| RIA-06 | Align blade 'edit' permission to controller 'update' | fee-master/index.blade.php @can directives | Medium -- permission change |
| RIA-07 | Align blade 'export' to controller 'viewAny' | fee-master/index.blade.php @can directives | Medium -- permission alignment |
| RIA-08 | Add unique constraint on (std_academic_sessions_id, month) | DDL migration, store() logic | High -- existing duplicates would break |
| RIA-09 | Add activityLog() to import operations | FeeMasterImport, startImport() | Low -- adding audit |
| RIA-10 | Add is_active column (separate from status VARCHAR) | DDL, model, toggleStatus, blade views | High -- fundamental field change |

---

## 10. Test Environment Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| PHP Version | 8.x | Laravel 10/11 compatible |
| Database | MySQL 8.x / MariaDB 10.x | Tenant-based |
| Queue Driver | sync (for imports, may use database) | Default for testing |
| Session Driver | file / database | For import file storage |
| Storage Disk | public | For import file storage |
| PDF Library | barryvdh/laravel-dompdf | For PDF generation |
| Excel Library | maatwebsite/laravel-excel 3.x | For import/export |
| Test Framework | Laravel Dusk | Browser automation |
| Mail Driver | array / log | For fee notifications (if any) |

---

## 11. Common Failure Patterns

| Pattern | Symptom | Root Cause | Fix |
|---------|---------|------------|-----|
| CFP-01 | Undefined variable $feeMasters | Visiting standalone `/fee-master` instead of tab URL | Use tab URL or fix index() variable name |
| CFP-02 | Export downloads wrong data | Export button links to fee-collection.export | Fix route in blade |
| CFP-03 | 403 on Edit click | User has 'edit' but no 'update' permission | Align blade @can with controller Gate |
| CFP-04 | 403 on Export click | User has 'export' but no 'viewAny' permission | Align blade @can with controller Gate |
| CFP-05 | Import session lost | Session driver not persistent across requests | Use database/cookie session driver |
| CFP-06 | PDF blank/garbled | DomPDF memory limit for large collections | Increase memory_limit or chunk collections |
| CFP-07 | toggleStatus returns 500 | Missing is_active in request body | Check JS sends is_active parameter |
| CFP-08 | StudentPayLog missing | Controller exception before StudentPayLog::create() | Check exception handling in try-catch |
| CFP-09 | date validation fails on month input | Browser sends local date format incompatible with Carbon | Use proper input type=date |
| CFP-10 | Import rows silently skipped | Empty required fields (roll_number, month, fee_amount) | Check Excel data completeness |

---
*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: FeeCreation (FeeMaster) | Date: 2026-07-21*
