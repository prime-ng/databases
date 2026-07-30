# tpt_FeeCollection_TcList

## Module: Transport → Student Route Fees Management → Fee Collection

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Student Route Fees Management |
| Feature | Fee Collection |
| URL(s) (Tab) | `/std-route-Fees-mgmt?tab=fee_collection` — `StudentRouteFeesController@index()` loads all tabs including fee_collection-pane |
| URL(s) (Standalone) | `/fee-collection` (index standalone), `/fee-collection/create` (create), `/fee-collection` (store POST), `/fee-collection/{id}` (show), `/fee-collection/{id}/edit` (edit), `/fee-collection/{id}` (update PUT), `/fee-collection/{id}` (destroy DELETE), `/fee-collection/allocation/export` (export GET) |
| Routes Registered | `Route::resource('fee-collection', FeeCollectionController::class)` + `Route::get('/fee-collection/allocation/export', ...)`. ❌ **MISSING:** `trashed`, `restore`, `forceDelete` routes — controller methods exist but are unreachable via HTTP. Trash view `trash.blade.php` does not exist. |
| Controller | `Modules\Transport\Http\Controllers\FeeCollectionController` — 12 methods: index, create, store, show, edit, update, destroy, export, trashed, restore, forceDelete, refreshFeeMasterStatus (private) |
| Tab Container Controller | `Modules\Transport\Http\Controllers\StudentRouteFeesController@index()` — calls `feeCollectionData()`, `feeCollectionSummary()`, passes `$feeCollectionList`, `$feeCollectionSummary`, `$organizationData` to view |
| Model | `Modules\Transport\Models\TptStudentFeeCollection` — table: `tpt_student_fee_collection`, uses `SoftDeletes`, 8 fillable fields, 3 relationships (`feeMaster`, `studentFeeDetail`, `fineDetails`) — **NO** `studentAllocation` relationship |
| Validation (Create + Update) | `Modules\Transport\Http\Requests\FeeCollectionRequest` — 6 rules, `prepareForValidation()` normalizes payment_mode/status to ucfirst, reconciled to 0/1 |
| Permissions | `tenant.fee-collection.viewAny`, `tenant.fee-collection.view`, `tenant.fee-collection.create`, `tenant.fee-collection.update`, `tenant.fee-collection.edit`, `tenant.fee-collection.delete`, `tenant.fee-collection.restore`, `tenant.fee-collection.forceDelete`, `tenant.fee-collection.export`. ❌ **Unused policy methods:** `status()`, `import()`, `print()`, `collect()`, `generateReceipt()`, `viewReports()`, `reconcile()`, `refund()` — no controller methods exist. |
| Soft Deletes | Yes — model uses `SoftDeletes` trait |
| Activity Log | Events: `Created` (store), `Updated` (update), `Deleted` (destroy), `Restored` (restore), `Force Deleted` (forceDelete) |
| Import / Export | Export only — `FeeCollectionExport` via `export()` method; import not implemented |
| Accounting Integration | Yes — `RemoteEntryService::processEvent('TRANSPORT', 'TPT_FEE_PAYMENT', ...)` called on store; failure logged (does NOT rollback payment) |
| DB Table | `tpt_student_fee_collection` — 11 columns, FK `student_fee_detail_id → tpt_student_fee_detail(id)` ON DELETE RESTRICT, no `updated_at` column |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-collection.viewAny`, `tenant.fee-collection.view`, `tenant.fee-collection.create`, `tenant.fee-collection.update`, `tenant.fee-collection.edit`, `tenant.fee-collection.delete`, `tenant.fee-collection.restore`, `tenant.fee-collection.forceDelete`
- Required seed data: At least one `TptFeeMaster` (tpt_student_fee_detail) record with `status != 'Completed'`
- Required seed data: At least one `TptStudentAllocationJnt` record
- Required seed data: At least one `TptFineMaster` record (optional, for fine calculation)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- The Fee Collection tab is loaded as part of StudentRouteFeesMgmt — the URL `/std-route-Fees-mgmt?tab=fee_collection` loads `StudentRouteFeesController@index` with all tabs
- `OrganizationAcademicSession` data required for academic session dropdown in filter
- `FeeCollectionController` has its own standalone views for create, show, edit (full page with breadcrumb). The list view is embedded in the tab container AND available standalone at `/fee-collection`.

---

## 3. Default Data Load

When the page loads via `StudentRouteFeesController@index()` (GET `/std-route-Fees-mgmt`), all fee management tab data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Fee Collections Grid (Tab) | `StudentRouteFeesController@feeCollectionData()` | `TptStudentFeeCollection::with('feeMaster.academicSession')` | `academic_sessions_id` (via whereHas feeMaster), `status` (direct), `month` (via whereHas feeMaster) | 10/page via `->paginate(10)->withQueryString()` |
| Fee Collections Grid (Standalone) | `FeeCollectionController@index()` | `TptStudentFeeCollection::with(['studentAllocation', 'feeMaster'])` — ⚠️ `studentAllocation` relationship does NOT exist in model; this will cause a SQL/query error at runtime | None — no filter support in standalone controller | 20/page via `->paginate(20)` |
| Summary Cards (Total Due, Collected, Pending, Rate) | `feeCollectionSummary()` — `StudentRouteFeesController` | `TptStudentFeeCollection::with('feeMaster')` + aggregated manual calculation | Same as feeCollectionData | N/A — computed |
| Organization Data | `OrganizationAcademicSession::get()` | All org academic sessions | None | None |

**CRITICAL FINDING:** The tab-based list uses `feeMaster.academicSession` eager-load (works). The standalone `FeeCollectionController@index()` uses `studentAllocation` eager-load which does NOT exist in the model — **runtime error** when accessing standalone index. Also, the standalone index has NO filter support (no `when()` clauses). Filters only work via the tab container controller.

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('YmdHis') . random_int(100, 999)` for unique references
- **student_fee_detail_id**: Must reference an existing `tpt_student_fee_detail` record (TptFeeMaster). Passed as hidden field `ids` in form
- **payment_date**: DATE, required. Used for delay calculation against feeMaster->due_date
- **paid_amount**: DECIMAL(10,2), required, numeric, min:0
- **payment_mode**: VARCHAR(20), required. `FeeCollectionRequest::prepareForValidation()` normalizes to ucfirst (e.g., "Cash"). Controller `store()` then applies `strtolower()` → stored as lowercase in DB "cash". Display via blade uses `ucfirst()`.
- **status**: VARCHAR(20), required. `prepareForValidation()` normalizes to ucfirst (e.g., "Paid"). Controller stores as-is. Options from model constants: paid, pending, overdue.
- **reconciled**: TINYINT(1), default 0. Checkbox in form; `prepareForValidation()` sets 1 if present, 0 if absent. Controller uses `$request->reconciled ?? 0` (redundant with prepareForValidation).
- **remarks**: VARCHAR(512), nullable. Stored directly.
- **fine_master_id**: Optional FK to `tpt_fine_master`. If provided, `TptStudentFineDetail` record is ALWAYS created (even if delay outside range — in that case fine_amount=0).
- **Delay calculation**: `$delayDays = $paymentDate->gt($dueDate) ? (int) $paymentDate->diffInDays($dueDate) : 0` (line 71-73)
- **Fine calculation**: If fine_master_id provided AND delayDays within fine_from_days → fine_to_days range (line 84-95):
  - `Fixed` type: `$fineAmount = $fineMaster->fine_rate`
  - `Percentage` type: `$fineAmount = ($feeMaster->amount * $fineMaster->fine_rate) / 100`
- **Student restriction**: If `$fineMaster->student_restricted == 1`, the student's `is_active` is set to 0 (student blocked) — line 97-104
- **FeeMaster status refresh**: After collection, `refreshFeeMasterStatus()` recalculates: Completed (collected >= due), Partial (collected > 0), Pending — line 358-373
- **Accounting integration**: `RemoteEntryService::processEvent()` called with 'TRANSPORT', 'TPT_FEE_PAYMENT' — failure does NOT roll back payment (line 157-179)
- **Pre-test cleanup**: Delete created fee collections by student_fee_detail_id + payment_date

---

## 5. Business Conditions (BC)

### 5.1 BC-DB: Database Schema — `tpt_student_fee_collection`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | student_fee_detail_id | INT UNSIGNED | NOT NULL, FK → `tpt_student_fee_detail.id`, ON DELETE RESTRICT |
| BC-DB-03 | payment_date | DATE | NOT NULL |
| BC-DB-04 | total_delay_days | INT | DEFAULT 0 |
| BC-DB-05 | paid_amount | DECIMAL(10,2) | NOT NULL |
| BC-DB-06 | payment_mode | VARCHAR(20) | NOT NULL |
| BC-DB-07 | status | VARCHAR(20) | NOT NULL |
| BC-DB-08 | reconciled | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-09 | remarks | VARCHAR(512) | DEFAULT NULL |
| BC-DB-10 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-12 | **updated_at** | **NOT IN DDL** | ⚠️ Column does NOT exist in migration — model has no `updated_at` timestamps |

### 5.2 BC-VAL: Validation Rules — `FeeCollectionRequest`

| BC ID | Field | Rule | prepareForValidation | Error Message |
|-------|-------|------|---------------------|---------------|
| BC-VAL-01 | payment_date | required, date | — | Default Laravel "The payment date field is required." |
| BC-VAL-02 | paid_amount | required, numeric, min:0 | — | Default |
| BC-VAL-03 | payment_mode | required (**NO** `Rule::in`) | `ucfirst(strtolower(...))` — normalizes to ucfirst ("Cash") | Default |
| BC-VAL-04 | status | required (**NO** `Rule::in`) | `ucfirst(strtolower(...))` — normalizes to ucfirst ("Paid") | Default |
| BC-VAL-05 | remarks | nullable, string, max:512 | — | Default |
| BC-VAL-06 | reconciled | nullable, boolean | `$this->has('reconciled') ? 1 : 0` | Default |

**CRITICAL FINDING — Data Flow Discrepancy:**
1. `FeeCollectionRequest::prepareForValidation()` (line 67): `payment_mode` → `ucfirst(strtolower("cash"))` = "Cash"
2. `FeeCollectionController::store()` (line 130): `'payment_mode' => strtolower($request->payment_mode)` → `strtolower("Cash")` = "cash"
3. **Net result**: DB stores "cash" (lowercase), NOT ucfirst. The `prepareForValidation()` normalization is immediately undone by the controller.
4. Display in blade uses `ucfirst($row->payment_mode)` (show.blade.php:91, index.blade.php:222) → shows "Cash" in UI.
5. For `status`: `prepareForValidation()` sets "Paid", controller stores as-is → DB stores "Paid" (ucfirst). No strtolower applied.

### 5.3 BC-AUTH: Authorization Conditions (Permission Gates)

| BC ID | Permission | Controller Method | Source | Behavior |
|-------|-----------|-------------------|--------|----------|
| BC-AUTH-01 | tenant.fee-collection.viewAny | `FeeCollectionController@index()` | Line 30 `Gate::authorize()` | Without → 403 |
| BC-AUTH-02 | tenant.fee-collection.viewAny | `StudentRouteFeesController@index()` tab display | Blade `@can` in stdroutefeesmgmt | Without → tab hidden |
| BC-AUTH-03 | tenant.fee-collection.view | `show()` | Line 198 `Gate::authorize()` | Without → 403 |
| BC-AUTH-04 | tenant.fee-collection.create | `store()`, `create()` | Lines 43, 60 `Gate::authorize()` | Without → 403 |
| BC-AUTH-05 | tenant.fee-collection.create | `FeeCollectionRequest::authorize()` | Request line 16-17 | 403 on POST |
| BC-AUTH-06 | tenant.fee-collection.update | `edit()`, `update()` | Lines 209, 225 `Gate::authorize()` | Without → 403 |
| BC-AUTH-07 | tenant.fee-collection.update | `FeeCollectionRequest::authorize()` | Request line 18-19 | 403 on PUT/PATCH |
| BC-AUTH-08 | tenant.fee-collection.edit | Action column visibility (blade `@canany`) | index.blade.php:164, 253 | Without → action column hidden |
| BC-AUTH-09 | tenant.fee-collection.delete | `destroy()` | Line 272 `Gate::authorize()` | Without → 403 |
| BC-AUTH-10 | tenant.fee-collection.restore | `trashed()`, `restore()` | Lines 314, 327 `Gate::authorize()` | Without → 403 ⚠️ Routes NOT registered |
| BC-AUTH-11 | tenant.fee-collection.forceDelete | `forceDelete()` | Line 345 `Gate::authorize()` | Without → 403 ⚠️ Route NOT registered |
| BC-AUTH-12 | tenant.fee-collection.viewAny | `export()` | Line 302 `Gate::authorize()` | Without → 403 |

### 5.4 BC-BIZ: Business Logic

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-01 | Create via `store()` in DB transaction | Fee collection created within `DB::transaction()`; fine calculated and TptStudentFineDetail created if applicable; FeeMaster status refreshed; StudentPayLog created; RemoteEntryService triggered | Controller lines 58-191 |
| BC-BIZ-02 | Activity log on create | `activityLog($feeCollection, 'Created', ['message' => 'Fee collected successfully'])` | Line 183-185 |
| BC-BIZ-03 | StudentPayLog on create | `activity_type: 'fee_collected_create'`, `reference_table: 'tpt_student_fee_collection'` | Lines 144-154 |
| BC-BIZ-04 | Fine calculation — Fixed type | `$fineAmount = $fineMaster->fine_rate` if delayDays within range | Lines 88-89 |
| BC-BIZ-05 | Fine calculation — Percentage type | `$fineAmount = ($feeMaster->amount * $fineMaster->fine_rate) / 100` | Lines 92-93 |
| BC-BIZ-06 | Fine detail ALWAYS created when fine_master_id provided | `TptStudentFineDetail::create(...)` called regardless of delay range match — fine_amount=0 if outside range | Lines 107-117 |
| BC-BIZ-07 | Student restriction on fine | If `$fineMaster->student_restricted == 1`, student `is_active` set to 0 | Lines 97-104 |
| BC-BIZ-08 | FeeMaster status refresh — Completed | `$collected >= $due` → status = 'Completed' | Lines 364-365 |
| BC-BIZ-09 | FeeMaster status refresh — Partial | `$collected > 0` but < `$due` → status = 'Partial' | Lines 366-367 |
| BC-BIZ-10 | FeeMaster status refresh — Pending | `$collected == 0` → status = 'Pending' | Lines 368-369 |
| BC-BIZ-11 | Accounting integration | `RemoteEntryService::processEvent('TRANSPORT', 'TPT_FEE_PAYMENT', ...)` called; failure logged but does NOT rollback | Lines 157-179 |
| BC-BIZ-12 | Update via `update()` in DB transaction | Fee collection updated; FeeMaster status refreshed; StudentPayLog created | Lines 223-265 |
| BC-BIZ-13 | Activity log on update | `activityLog($feeCollection, 'Updated', ['message' => 'Fee collection updated successfully'])` | Lines 239-241 |
| BC-BIZ-14 | Edit view — paid_amount readonly | Edit form has `readonly` attribute on paid_amount field — cannot be changed | edit.blade.php:64 |
| BC-BIZ-15 | Soft delete via `destroy()` | `$feeCollection->delete()` — single record soft delete. NOTE: does NOT call `refreshFeeMasterStatus()` | Lines 270-295 |
| BC-BIZ-16 | Activity log on delete | `activityLog($feeCollection, 'Deleted', ['message' => 'Fee collection deleted'])` | Lines 288-290 |
| BC-BIZ-17 | Trash list via `trashed()` | `TptStudentFeeCollection::onlyTrashed()->latest('deleted_at')->paginate(20)` ⚠️ Route NOT registered | Lines 312-320 |
| BC-BIZ-18 | Restore via `restore($id)` | `$feeCollection->restore()`; redirect to trash view ⚠️ Route NOT registered | Lines 325-338 |
| BC-BIZ-19 | Force delete via `forceDelete($id)` | `$feeCollection->forceDelete()`; redirect to trash view ⚠️ Route NOT registered | Lines 343-356 |
| BC-BIZ-20 | Activity log on restore | `activityLog($feeCollection, 'Restored', ['message' => 'Fee collection restored'])` ⚠️ Unreachable | Lines 331-333 |
| BC-BIZ-21 | Activity log on forceDelete | `activityLog($feeCollection, 'Force Deleted', ['message' => 'Fee collection permanently deleted'])` ⚠️ Unreachable | Lines 349-351 |
| BC-BIZ-22 | StudentPayLog on destroy | `StudentPayLog::create([...activity_type: 'fee_collected_delete'...])` | Lines 276-286 |
| BC-BIZ-23 | Export via `export()` | Downloads `FeeCollectionExport` as `.xlsx` — passes `$request->all()` as filters | Lines 300-307 |
| BC-BIZ-24 | FormRequest authorize gate check | POST → `tenant.fee-collection.create`; PUT/PATCH → `tenant.fee-collection.update` | Request lines 14-20 |
| BC-BIZ-25 | prepareForValidation() normalization | `payment_mode`: ucfirst+strtolower → "Cash"; `status`: ucfirst+strtolower → "Paid"; `reconciled`: 0/1 | Request lines 63-70 |
| BC-BIZ-26 | Controller `store()` re-lowercases payment_mode | `strtolower($request->payment_mode)` — undoes prepareForValidation ucfirst → DB stores "cash" | Line 130 |
| BC-BIZ-27 | Controller `store()` passes status unchanged | `'status' => $request->status` — stores ucfirst from prepareForValidation → DB stores "Paid" | Line 131 |
| BC-BIZ-28 | `refreshFeeMasterStatus()` calculates due as count×amount | `$due = $students * $feeMaster->amount` where `$students = $feeMaster->feeCollections()->count()` | Lines 360-362 |
| BC-BIZ-29 | `destroy()` does NOT refresh FeeMaster status | After delete, FeeMaster status may be incorrect (still showing collected amount that no longer exists) | Lines 270-295 (no refreshFeeMasterStatus call) |
| BC-BIZ-30 | `update()` does NOT recalculate `total_delay_days` | `total_delay_days` is NOT in the update fields array — original delay remains even if payment_date changes | Lines 230-237 |

### 5.5 BC-BIZ-DEEP: Deep Dive Business Conditions

| BC ID | Condition | Expected Behavior | Source Line |
|-------|-----------|-------------------|-------------|
| BC-BIZ-DEEP-01 | `store()` uses `$request->ids` NOT `$request->student_fee_detail_id` | Hidden field `ids` maps to `student_fee_detail_id`. `findOrFail($request->ids)` at line 66 | Controller:66 |
| BC-BIZ-DEEP-02 | `store()` `$fineMaster` found with `find()` NOT `findOrFail()` | `TptFineMaster::find($request->fine_master_id)` — returns null silently if ID invalid; no 404 | Controller:82 |
| BC-BIZ-DEEP-03 | Fine detail created even when $fineMaster is null | If `find()` returns null but `$request->filled('fine_master_id')` is true, `TptStudentFineDetail::create()` still runs with `$fineMaster->id` → **500 error** (null property) | Controller:82,109 |
| BC-BIZ-DEEP-04 | Fine detail created when delay OUTSIDE range | If fine_master_id provided but delayDays NOT within fine_from_days→fine_to_days, `TptStudentFineDetail::create()` still executes with `$fineAmount=0` | Controller:107-117 |
| BC-BIZ-DEEP-05 | Student restriction guard checks isset($fineMaster) | `if((isset($fineMaster)) && ($fineMaster->student_restricted == 1))` — prevents null pointer if find() returns null | Controller:97 |
| BC-BIZ-DEEP-06 | `store()` creates fine detail BEFORE fee collection record | `TptStudentFineDetail::create()` at line 107, `TptStudentFeeCollection::create()` at line 125 — fine detail references `$request->ids` directly, not the newly created fee collection FK | Controller:107,125 |
| BC-BIZ-DEEP-07 | `update()` does NOT allow changing `student_fee_detail_id` | The `ids` hidden field is present in edit form but NOT used in `update()` — `student_fee_detail_id` cannot be changed | Controller:230-237 |
| BC-BIZ-DEEP-08 | `update()` does NOT recalculate `total_delay_days` | `total_delay_days` is absent from `$feeCollection->update([...])` array — old value persists even if payment_date changes | Controller:230-237 |
| BC-BIZ-DEEP-09 | `update()` does NOT trigger fine recalculation | No fine master handling in update — fine details are NOT re-created or updated when payment_date changes | Controller:223-265 |
| BC-BIZ-DEEP-10 | `update()` does NOT trigger RemoteEntryService | Only StudentPayLog and FeeMaster status refresh — no accounting re-entry | Controller:246-259 |
| BC-BIZ-DEEP-11 | `destroy()` does NOT refresh FeeMaster status | After soft-deleting a collection, FeeMaster status does NOT recalculate — collected amount remains in sum | Controller:270-295 |
| BC-BIZ-DEEP-12 | `destroy()` does NOT delete associated StudentPayLog | StudentPayLog entry for fee_collected_delete is CREATED (not deleted from original) — original pay log remains | Controller:276-286 |
| BC-BIZ-DEEP-13 | `destroy()` does NOT cascade to fine details | Fine details for this collection remain in DB after collection is soft-deleted | Controller:270-295 |
| BC-BIZ-DEEP-14 | `restore()` redirects to `transport.fee-collection.trashed` route name | Route name `fee-collection.trashed` does NOT exist in routes/web.php — **redirect will fail with RouteNotFoundException** | Controller:336 |
| BC-BIZ-DEEP-15 | `forceDelete()` redirects to `transport.fee-collection.trashed` route name | Same issue as BC-BIZ-DEEP-14 — route NOT registered | Controller:354 |
| BC-BIZ-DEEP-16 | `restore()` uses `onlyTrashed()->findOrFail($id)` | Correct for restore — only finds soft-deleted records | Controller:328 |
| BC-BIZ-DEEP-17 | `forceDelete()` uses `onlyTrashed()->findOrFail($id)` | Correct for force delete — prevents force-deleting active records without soft-delete first | Controller:346 |
| BC-BIZ-DEEP-18 | `create()` passes `$feeIds` as string or empty | `$feeIds = isset($request->fee_master_id) ? $request->fee_master_id : ""` — single ID string, not array | Controller:46 |
| BC-BIZ-DEEP-19 | `create()` loads ALL fee masters | `TptFeeMaster::get()` — no filter, all fee masters available in create form | Controller:45 |
| BC-BIZ-DEEP-20 | `create()` loads ALL fine masters | `TptFineMaster::get()` — all fine types available | Controller:48 |
| BC-BIZ-DEEP-21 | `create()` does NOT filter fee masters by status | Fee masters with 'Completed' status are still shown — user could attempt to add collection to already-completed fee | Controller:45 |
| BC-BIZ-DEEP-22 | `edit()` does NOT pass `$fineSelect` to view | Unlike `create()`, the edit view has no fine master dropdown — cannot change fine association | Controller:207-218 |
| BC-BIZ-DEEP-23 | `edit()` loads all fee masters (for reference) | `TptFeeMaster::get()` passed to view but not used in edit form for any dropdown | Controller:212 |
| BC-BIZ-DEEP-24 | `index()` standalone has NO filter support | No `when()` or `if` clauses for academic_sessions_id, month, or status — filters only in tab controller | Controller:28-36 |
| BC-BIZ-DEEP-25 | `index()` standalone uses `paginate(20)` — NOT 10 | Tab controller uses 10/page, standalone uses 20/page — different pagination sizes | Controller:33 |
| BC-BIZ-DEEP-26 | `index()` standalone eager-loads non-existent `studentAllocation` | `->with(['studentAllocation', 'feeMaster'])` — `studentAllocation()` method does NOT exist in model → **runtime error** | Controller:31, Model:86 |
| BC-BIZ-DEEP-27 | `show()` does NOT eager-load any relationships | `TptStudentFeeCollection::findOrFail($id)` — feeMaster accessed via lazy-loading in blade | Controller:199 |
| BC-BIZ-DEEP-28 | `show()` blade accesses `$record->feeMaster->academicSession->student` | Multi-level lazy-load chain — potential N+1 if called in loop (fine for single record) | show.blade.php:151 |
| BC-BIZ-DEEP-29 | `export()` passes all request params as filters | `new FeeCollectionExport($request->all())` — no explicit filter keys, all GET params passed | Controller:304 |
| BC-BIZ-DEEP-30 | `export()` uses `viewAny` permission | `Gate::authorize('tenant.fee-collection.viewAny')` — not a dedicated export permission | Controller:302 |
| BC-BIZ-DEEP-31 | `refreshFeeMasterStatus()` uses `count()` NOT `SUM(1)` | `$feeMaster->feeCollections()->count()` — counts ALL collections (including those with paid_amount=0) | Controller:360 |
| BC-BIZ-DEEP-32 | `refreshFeeMasterStatus()` multiplies count×amount | `$due = $students * $feeMaster->amount` — assumes each collection is for one student at full amount. If feeMaster allows multiple students at different amounts, this is incorrect | Controller:362 |
| BC-BIZ-DEEP-33 | `refreshFeeMasterStatus()` is NOT called after destroy() | When a collection is deleted, FeeMaster status does NOT update — stale status | Controller:270-295 |
| BC-BIZ-DEEP-34 | Activity log `Created` fires AFTER RemoteEntryService try/catch | `activityLog()` at line 183 runs after RemoteEntryService at line 160 — order: fine detail → fee collection → refreshFM → StudentPayLog → RemoteEntryService → activityLog | Controller:183-185 |
| BC-BIZ-DEEP-35 | StudentPayLog uses `optional()` chains | `optional($feeCollection->feeMaster->academicSession->student)->id` — multiple optional levels may silently produce null student_id | Controller:145 |
| BC-BIZ-DEEP-36 | `payment_mode` model constants are lowercase | `PAYMENT_CASH = 'cash'`, `PAYMENT_ONLINE = 'online'`, `PAYMENT_CHEQUE = 'cheque'` — matches what controller stores | Model:20-22 |
| BC-BIZ-DEEP-37 | Model `statusOptions()` returns ucfirst labels but lowercase keys | `['paid' => 'Paid', 'pending' => 'Pending', 'overdue' => 'Overdue']` — keys match ucfirst status stored by controller | Model:24-31 |
| BC-BIZ-DEEP-38 | No `paymentModeOptions()` used in controller | Payment mode options exist in model but controller does NOT validate against them — any string accepted | Model:33-40 |
| BC-BIZ-DEEP-39 | `index.blade.php` uses `$row->where('status', 'paid')->count()` on paginated collection | `$feeCollectionList->where('status', 'paid')->count()` counts within CURRENT PAGE ONLY, not all records | index.blade.php:137-149 |
| BC-BIZ-DEEP-40 | Summary cards in blade compute from `$feeCollectionSummary` (passed from tab controller) | Standalone `FeeCollectionController@index()` does NOT pass `$feeCollectionSummary` — summary cards would be undefined/missing | index.blade.php:13,58,60 |
| BC-BIZ-DEEP-41 | Index table uses `$feeCollectionList->firstItem() + $key` for # | Row numbering based on paginator's first item — correct for paginated results | index.blade.php:177 |
| BC-BIZ-DEEP-42 | Index table status badges with icons | 3 status visual states: green badge + check icon (paid), red + exclamation (overdue), yellow + clock (pending) | index.blade.php:230-250 |
| BC-BIZ-DEEP-43 | Show page "Back" button redirects to tab index | `route('transport.std-route-Fees-mgmt.index')` — back to tab container, not to standalone index | show.blade.php:14 |
| BC-BIZ-DEEP-44 | Show page "Edit" button links to standalone edit | `route('transport.fee-collection.edit', $record->id)` — opens full-page edit form | show.blade.php:18 |
| BC-BIZ-DEEP-45 | Edit form uses `old('payment_mode', ucfirst($feeCollection->payment_mode))` | Since DB stores "cash", `ucfirst("cash")` = "Cash" — dropdown pre-selects "Cash" | edit.blade.php:101 |
| BC-BIZ-DEEP-46 | Edit form `reconciled` checkbox uses `old('reconciled', $feeCollection->reconciled)` | Cast to boolean by model — `true` → checkbox checked, `false` → unchecked | edit.blade.php:131 |
| BC-BIZ-DEEP-47 | Create form hidden `ids` uses `isset($feeIds) ? $feeIds : ""` | If no fee_master_id in URL, `ids` is empty string — store will fail with `findOrFail("")` → ModelNotFoundException | create.blade.php:44 |
| BC-BIZ-DEEP-48 | Create form Total Delay Days is a FREE INPUT field | No auto-calculation in UI — user manually enters delay days; controller recalculates and overwrites | create.blade.php:57-62 |
| BC-BIZ-DEEP-49 | Create form has Fine Type dropdown | Dropdown shows all fine masters from `$fineSelect` — no filtering | create.blade.php:66-76 |
| BC-BIZ-DEEP-50 | Controller `store()` recalculates `total_delay_days` regardless of user input | Controller line 71-73 recalculates from dates — user's manual input in form is OVERWRITTEN | Controller:71-73 |

### 5.6 BC-REL: Model Relationships

| BC ID | Relationship | Type | Foreign Key | Source | Notes |
|-------|-------------|------|-------------|--------|-------|
| BC-REL-01 | feeMaster() | BelongsTo TptFeeMaster | student_fee_detail_id | Model:69-72 | Main relationship for fee details |
| BC-REL-02 | studentFeeDetail() | BelongsTo TptFeeMaster | student_fee_detail_id | Model:61-64 | Alias for feeMaster() |
| BC-REL-03 | fineDetails() | HasMany TptStudentFineDetail | student_fee_detail_id (local), student_fee_detail_id (foreign) | Model:77-84 | All fine details for collections sharing the same student_fee_detail_id |
| BC-REL-04 | **studentAllocation()** | **❌ DOES NOT EXIST** | N/A | Model:86 | Controller `index()` line 31 calls `->with(['studentAllocation', 'feeMaster'])` — this relationship has NO method in the model. Will cause a query error. |

### 5.7 BC-REF: Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | student_fee_detail_id | tpt_student_fee_detail (id) | RESTRICT |
| BC-REF-02 | fine_master_id (in tpt_student_fine_detail) | tpt_fine_master (id) | RESTRICT (inferred, not in FeeCollection table) |

---

### 5.8 CODE-TRACE: Controller Method Execution Traces

#### CODE-TRACE-01: `FeeCollectionController@index()` (Lines 28-36)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 30 | `Gate::authorize('tenant.fee-collection.viewAny')` | Authorization gate |
| 2 | 31 | `TptStudentFeeCollection::with(['studentAllocation', 'feeMaster'])` | ⚠️ `studentAllocation` relationship MISSING — runtime error |
| 3 | 32 | `->latest()` | Order by created_at DESC |
| 4 | 33 | `->paginate(20)` | 20 records per page |
| 5 | 35 | `return view('transport::fee-collection.index', compact('data'))` | View variable: `$data` |

#### CODE-TRACE-02: `FeeCollectionController@create()` (Lines 41-53)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 43 | `Gate::authorize('tenant.fee-collection.create')` | Authorization |
| 2 | 44 | `$studentAllocation = TptStudentAllocationJnt::get()` | All allocations |
| 3 | 45 | `$feeMatser = TptFeeMaster::get()` | All fee masters (variable name typo: feeMatser not feeMaster) |
| 4 | 46 | `$feeIds = isset($request->fee_master_id) ? $request->fee_master_id : ""` | Pre-populate from query string |
| 5 | 48 | `$fineSelect = TptFineMaster::get()` | All fine masters |
| 6 | 49-52 | `return view('transport::fee-collection.create', compact(...))` | View variables: studentAllocation, feeMatser, feeIds, fineSelect |

#### CODE-TRACE-03: `FeeCollectionController@store()` (Lines 58-191)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 60 | `Gate::authorize('tenant.fee-collection.create')` | Authorization |
| 2 | 61 | `DB::transaction(function () use ($request) {` | Transaction start |
| 3 | 66 | `$feeMaster = TptFeeMaster::findOrFail($request->ids)` | Fetch fee master by hidden field `ids` |
| 4 | 68-69 | `$dueDate = Carbon::parse($feeMaster->due_date)` | Parse due date |
| 5 | 69 | `$paymentDate = Carbon::parse($request->payment_date)` | Parse payment date |
| 6 | 71-73 | `$delayDays = $paymentDate->gt($dueDate) ? (int) $paymentDate->diffInDays($dueDate) : 0` | Delay calculation |
| 7 | 80 | `if ($request->filled('fine_master_id'))` | Fine master provided? |
| 8 | 82 | `$fineMaster = TptFineMaster::find($request->fine_master_id)` | ⚠️ `find()` NOT `findOrFail()` — null if invalid |
| 9 | 84-86 | `if ($fineMaster && $delayDays >= $fineMaster->fine_from_days && $delayDays <= $fineMaster->fine_to_days)` | Delay range check |
| 10 | 88-89 | `if ($fineMaster->fine_type === 'Fixed') { $fineAmount = $fineMaster->fine_rate }` | Fixed fine calculation |
| 11 | 92-93 | `if ($fineMaster->fine_type === 'Percentage') { $fineAmount = ($feeMaster->amount * $fineMaster->fine_rate) / 100 }` | Percentage fine |
| 12 | 97-104 | `if (isset($fineMaster) && $fineMaster->student_restricted == 1) { $student->update(['is_active' => 0]) }` | Student restriction |
| 13 | 107-117 | `TptStudentFineDetail::create([...])` | ALWAYS executes when fine_master_id provided (even if $fineMaster is null → **error**) |
| 14 | 125-134 | `TptStudentFeeCollection::create([...])` | Create collection |
| 15 | 139 | `$this->refreshFeeMasterStatus($feeMaster)` | Refresh status |
| 16 | 144-154 | `StudentPayLog::create([...])` | Create pay log with activity_type='fee_collected_create' |
| 17 | 160-171 | `RemoteEntryService::processEvent('TRANSPORT', 'TPT_FEE_PAYMENT', ...)` | Accounting integration |
| 18 | 173-179 | `catch (\Throwable $e) { Log::error(...) }` | Accounting failure caught and logged |
| 19 | 183-185 | `activityLog($feeCollection, 'Created', [...])` | Activity log |
| 20 | 188-190 | `redirect()->route('transport.std-route-Fees-mgmt.index')->with('success', flash('created.fee_collection'))` | Redirect with flash |

#### CODE-TRACE-04: `FeeCollectionController@show()` (Lines 196-202)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 198 | `Gate::authorize('tenant.fee-collection.view')` | Authorization |
| 2 | 199 | `$record = TptStudentFeeCollection::findOrFail($id)` | Find or 404 — no eager loading |
| 3 | 201 | `return view('transport::fee-collection.show', compact('record'))` | View variable: `$record` |

#### CODE-TRACE-05: `FeeCollectionController@edit()` (Lines 207-218)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 209 | `Gate::authorize('tenant.fee-collection.update')` | Authorization |
| 2 | 210 | `$feeCollection = TptStudentFeeCollection::findOrFail($id)` | Find or 404 |
| 3 | 211 | `$studentAllocation = TptStudentAllocationJnt::get()` | All allocations |
| 4 | 212 | `$feeMatser = TptFeeMaster::get()` | All fee masters |
| 5 | 214-217 | `return view('transport::fee-collection.edit', compact(...))` | Variables: feeCollection, studentAllocation, feeMatser. ❌ NO fineSelect passed |

#### CODE-TRACE-06: `FeeCollectionController@update()` (Lines 223-265)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 225 | `Gate::authorize('tenant.fee-collection.update')` | Authorization |
| 2 | 226 | `$feeCollection = TptStudentFeeCollection::findOrFail($id)` | Find or 404 |
| 3 | 228 | `DB::transaction(function () use ($request, $feeCollection) {` | Transaction start |
| 4 | 230-237 | `$feeCollection->update([...])` | **Fields NOT updated:** `student_fee_detail_id`, `total_delay_days`. Fields updated: payment_date, paid_amount, payment_mode (strtolower), status, reconciled, remarks |
| 5 | 239-241 | `activityLog($feeCollection, 'Updated', [...])` | Activity log |
| 6 | 246-256 | `StudentPayLog::create([...activity_type: 'fee_collected_update'...])` | Student pay log |
| 7 | 259 | `$this->refreshFeeMasterStatus($feeCollection->feeMaster)` | Refresh status |
| 8 | 262-264 | `redirect()->route('transport.std-route-Fees-mgmt.index')->with('success', flash('updated.fee_collection'))` | Redirect with flash |

#### CODE-TRACE-07: `FeeCollectionController@destroy()` (Lines 270-295)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 272 | `Gate::authorize('tenant.fee-collection.delete')` | Authorization |
| 2 | 273 | `$feeCollection = TptStudentFeeCollection::findOrFail($id)` | Find or 404 |
| 3 | 274 | `$feeCollection->delete()` | Soft delete |
| 4 | 276-286 | `StudentPayLog::create([...activity_type: 'fee_collected_delete'...])` | Student pay log for deletion |
| 5 | 288-290 | `activityLog($feeCollection, 'Deleted', [...])` | Activity log |
| 6 | 292-294 | `redirect()->route('transport.std-route-Fees-mgmt.index')->with('success', flash('deleted.fee_collection'))` | Redirect |
| — | **MISSING** | `$this->refreshFeeMasterStatus(...)` | ⚠️ FeeMaster status NOT refreshed after delete |

#### CODE-TRACE-08: `FeeCollectionController@export()` (Lines 300-307)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 302 | `Gate::authorize('tenant.fee-collection.viewAny')` | Authorization (shared with index) |
| 2 | 303-306 | `Excel::download(new FeeCollectionExport($request->all()), 'fee_collection_' . now()->format('Y-m-d') . '.xlsx')` | Export with all request params as filters |

#### CODE-TRACE-09: `FeeCollectionController@trashed()` (Lines 312-320)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 314 | `Gate::authorize('tenant.fee-collection.restore')` | Authorization |
| 2 | 315-317 | `TptStudentFeeCollection::onlyTrashed()->latest('deleted_at')->paginate(20)` | Only soft-deleted, 20/page |
| 3 | 319 | `return view('transport::fee-collection.trash', compact('data'))` | ⚠️ VIEW FILE `trash.blade.php` DOES NOT EXIST |
| — | — | — | ⚠️ Route NOT registered in web.php |

#### CODE-TRACE-10: `FeeCollectionController@restore()` (Lines 325-338)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 327 | `Gate::authorize('tenant.fee-collection.restore')` | Authorization |
| 2 | 328 | `TptStudentFeeCollection::onlyTrashed()->findOrFail($id)` | Only find trashed |
| 3 | 329 | `$feeCollection->restore()` | Restore |
| 4 | 331-333 | `activityLog($feeCollection, 'Restored', [...])` | Activity log |
| 5 | 336 | `redirect()->route('transport.fee-collection.trashed')->with('success', flash('restored.fee_collection'))` | ⚠️ Route `fee-collection.trashed` NOT registered |
| — | — | — | ⚠️ Route NOT registered in web.php |

#### CODE-TRACE-11: `FeeCollectionController@forceDelete()` (Lines 343-356)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 345 | `Gate::authorize('tenant.fee-collection.forceDelete')` | Authorization |
| 2 | 346 | `TptStudentFeeCollection::onlyTrashed()->findOrFail($id)` | Only find trashed |
| 3 | 347 | `$feeCollection->forceDelete()` | Permanent delete |
| 4 | 349-351 | `activityLog($feeCollection, 'Force Deleted', [...])` | Activity log |
| 5 | 354 | `redirect()->route('transport.fee-collection.trashed')->with('success', flash('force_deleted.fee_collection'))` | ⚠️ Route NOT registered |
| — | — | — | ⚠️ Route and view NOT registered |

#### CODE-TRACE-12: `FeeCollectionController@refreshFeeMasterStatus()` private (Lines 358-373)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 360 | `$students = $feeMaster->feeCollections()->count()` | Count all collections for this fee master |
| 2 | 361 | `$collected = $feeMaster->feeCollections()->sum('paid_amount')` | Sum all paid amounts |
| 3 | 362 | `$due = $students * $feeMaster->amount` | Due = count × amount per student |
| 4 | 364-365 | `if ($due > 0 && $collected >= $due) { $feeMaster->status = 'Completed' }` | Full payment |
| 5 | 366-367 | `elseif ($collected > 0) { $feeMaster->status = 'Partial' }` | Partial payment |
| 6 | 368-369 | `else { $feeMaster->status = 'Pending' }` | No payment |
| 7 | 372 | `$feeMaster->save()` | Persist status |

---

## 6. Test Case List

### 6.1 TC-P: Positive Test Cases

| ID | Description | Expected Result | V1 Test | V2 Test | Status |
|----|-------------|----------------|---------|---------|--------|
| TC-P-01 | Fee Collection Tab Loads | `/std-route-Fees-mgmt?tab=fee_collection` loads with 4 summary cards (Total Due, Total Collected, Pending, Collection Rate), filter bar (Academic Session, Month, Payment Status), enhanced table (#, Student Details, Fee Details, Payment Info, Status, Action), pagination | — | — | ⬜ |
| TC-P-02 | Create Fee Collection — Full Payment On Time | POST `/fee-collection` with valid fee_master_id, payment_date <= due_date, full paid_amount = amount → collection created; status='paid'; delay_days=0; FeeMaster status='Completed'; RemoteEntryService triggered | — | — | ⬜ |
| TC-P-03 | Create Fee Collection — Partial Payment | paid_amount < amount → collection created; FeeMaster status='Partial'; delay_days=0 if on time | — | — | ⬜ |
| TC-P-04 | Create Fee Collection — Payment With Fine (Fixed) | payment_date > due_date + fine_master_id with Fixed type → fine_detail created with fine_amount=fine_rate; StudentPayLog created | — | — | ⬜ |
| TC-P-05 | Create Fee Collection — Payment With Fine (Percentage) | fine_master with Percentage type → fine_amount = (amount * rate) / 100 | — | — | ⬜ |
| TC-P-06 | Create Fee Collection — Overdue Status | payment_date > due_date → total_delay_days > 0; status = 'overdue'; display shows red badge | — | — | ⬜ |
| TC-P-07 | View Fee Collection Details (show) | GET `/fee-collection/{id}` → page renders: Fee Month, Due Date, Fee Amount, Payment Date, Paid Amount, Delay Days, Payment Mode, Status, Reconciled, Remarks + Linked Fee Master Summary | — | — | ⬜ |
| TC-P-08 | Edit Fee Collection — Change Status and Remarks | PUT `/fee-collection/{id}` with updated status, remarks → updated; FeeMaster status refreshed; StudentPayLog created | — | — | ⬜ |
| TC-P-09 | Edit Fee Collection — paid_amount is Readonly | paid_amount field has `readonly` attribute in edit form — cannot be changed via browser | — | — | ⬜ |
| TC-P-10 | Soft Delete Fee Collection | DELETE `/fee-collection/{id}` → `deleted_at` set; record hidden from main list; StudentPayLog created with fee_collected_delete; redirect with success flash | — | — | ⬜ |
| TC-P-11 | Export Fee Collections (with filters) | GET `/fee-collection/allocation/export?status=paid` → downloads `.xlsx` file filtered by status | — | — | ⬜ |
| TC-P-12 | Export Fee Collections (all data) | GET `/fee-collection/allocation/export` → downloads `.xlsx` with all records | — | — | ⬜ |
| TC-P-13 | Filter Fee Collections By Academic Session (Tab) | Select session → table filters via `whereHas('feeMaster', fn→academic_sessions_id)` | — | — | ⬜ |
| TC-P-14 | Filter Fee Collections By Month (Tab) | Select month → table filters via `whereHas('feeMaster', fn→month)` | — | — | ⬜ |
| TC-P-15 | Filter Fee Collections By Payment Status (Tab) | Select paid/pending/overdue → direct `where('status')` filter | — | — | ⬜ |
| TC-P-16 | Summary Cards Reflect Filtered Data | Total Due / Collected / Pending cards recompute with filtered values | — | — | ⬜ |
| TC-P-17 | Empty State — No Fee Collections (Tab) | Table shows "No fee collection records found" with icon | — | — | ⬜ |
| TC-P-18 | Create Fee Collection — Payment With Cheque Mode | payment_mode='Cheque' → stored as 'cheque' in DB (strtolower), displayed as 'Cheque' (ucfirst) | — | — | ⬜ |
| TC-P-19 | Create Fee Collection — Payment With Online Mode | payment_mode='Online' → stored as 'online' in DB | — | — | ⬜ |
| TC-P-20 | Create Fee Collection — With Remarks | remarks='Test remark' → stored verbatim; displayed in show page | — | — | ⬜ |
| TC-P-21 | Create Fee Collection — Reconciled Checked | Checkbox checked → reconciled=1 in DB; show page shows "Yes" badge | — | — | ⬜ |
| TC-P-22 | Create Fee Collection — Reconciled Unchecked | Checkbox unchecked → reconciled=0 in DB | — | — | ⬜ |
| TC-P-23 | Create Fee Collection — Fine Master Selected, Delay Outside Range | fine_master_id provided but delayDays NOT within fine_from_days→fine_to_days → TptStudentFineDetail created with fine_amount=0 | — | — | ⬜ |
| TC-P-24 | Update Fee Collection — Change payment_date | PUT with new payment_date → record updated; FeeMaster status refreshed; total_delay_days NOT recalculated (known limitation) | — | — | ⬜ |
| TC-P-25 | Update Fee Collection — Toggle Reconciled | Change reconciled from 0 to 1 → updated | — | — | ⬜ |
| TC-P-26 | Pagination on Tab (Page 2) | GET `/std-route-Fees-mgmt?tab=fee_collection&page=2` → page 2 of results | — | — | ⬜ |
| TC-P-27 | Verify Activity Log Created on Store | After store → `activityLog($feeCollection, 'Created', [...])` entry exists | — | — | ⬜ |
| TC-P-28 | Verify Activity Log Updated on Update | After update → `activityLog($feeCollection, 'Updated', [...])` entry exists | — | — | ⬜ |
| TC-P-29 | Verify Activity Log Deleted on Destroy | After destroy → `activityLog($feeCollection, 'Deleted', [...])` entry exists | — | — | ⬜ |
| TC-P-30 | Verify StudentPayLog Created on Store | `SELECT * FROM std_student_pay_log WHERE activity_type='fee_collected_create'` → entry exists with correct reference_id | — | — | ⬜ |
| TC-P-31 | Verify StudentPayLog Created on Update | `activity_type='fee_collected_update'` → entry exists | — | — | ⬜ |
| TC-P-32 | Verify StudentPayLog Created on Delete | `activity_type='fee_collected_delete'` → entry exists | — | — | ⬜ |
| TC-P-33 | Create Fee Collection — Multiple Collections for Same FeeMaster | 2 collections for same fee_master_id → refreshFeeMasterStatus accumulates both amounts; status = 'Completed' when sum >= due | — | — | ⬜ |
| TC-P-34 | Create Fee Collection — FeeMaster Moves Pending→Partial→Completed | Sequence: 1st collection (partial), 2nd collection (completes) → status transitions correctly | — | — | ⬜ |
| TC-P-35 | Verify Summary Cards Show Correct Totals | `total_due` = sum of feeMaster.total_amount (filtered); `total_collected` = sum of paid_amount; `pending` = abs(total_due - total_collected); rate = (total_collected/total_due)*100 | — | — | ⬜ |
| TC-P-36 | Create Fee Collection — From FeeMaster Tab with FeeMaster ID Pre-Selected | Click "Add Collection" from FeeMaster list → create form loads with `ids` hidden field pre-populated | — | — | ⬜ |

### 6.2 TC-N: Negative Test Cases

| ID | Description | Expected Result | V1 Test | V2 Test | Status |
|----|-------------|----------------|---------|---------|--------|
| TC-N-01 | Required — Missing payment_date | Validation error: "The payment date field is required." | — | — | ⬜ |
| TC-N-02 | Required — Missing paid_amount | Validation error: "The paid amount field is required." | — | — | ⬜ |
| TC-N-03 | Required — Missing payment_mode | Validation error: "The payment mode field is required." | — | — | ⬜ |
| TC-N-04 | Required — Missing status | Validation error: "The status field is required." | — | — | ⬜ |
| TC-N-05 | Invalid paid_amount — Negative | `min:0` validation error: "The paid amount must be at least 0." | — | — | ⬜ |
| TC-N-06 | Invalid paid_amount — Non-Numeric | `numeric` validation error: "The paid amount must be a number." | — | — | ⬜ |
| TC-N-07 | Invalid payment_date — Not a Date | `date` validation error | — | — | ⬜ |
| TC-N-08 | remarks > 512 Characters | `max:512` validation error | — | — | ⬜ |
| TC-N-09 | Non-Existent fee_master_id (ids field) | POST with invalid ids → `TptFeeMaster::findOrFail()` → ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N-10 | View Fee Collection With Invalid ID | GET `/fee-collection/99999` → `findOrFail()` → 404 | — | — | ⬜ |
| TC-N-11 | Edit Fee Collection With Invalid ID | GET `/fee-collection/99999/edit` → `findOrFail()` → 404 | — | — | ⬜ |
| TC-N-12 | Update Fee Collection With Invalid ID | PUT `/fee-collection/99999` → `findOrFail()` → 404 | — | — | ⬜ |
| TC-N-13 | Delete Fee Collection With Invalid ID | DELETE `/fee-collection/99999` → `findOrFail()` → 404 | — | — | ⬜ |
| TC-N-14 | Invalid fine_master_id (null → error) | POST with fine_master_id=99999 (non-existent) → `TptFineMaster::find()` returns null → `TptStudentFineDetail::create()` accesses `$fineMaster->id` → **500 error** | — | — | ⬜ |
| TC-N-15 | Permission 403 — No Fee Collection Permissions | 403 Forbidden on all CRUD endpoints | — | — | ⬜ |
| TC-N-16 | Guest Access Redirect | All `/fee-collection/*` URLs redirect to `/login` | — | — | ⬜ |
| TC-N-17 | XSS Injection In remarks | `<script>alert('xss')</script>` stored as literal string; Blade `{{ }}` escapes output | — | — | ⬜ |
| TC-N-18 | Reconciled Not Checked | `prepareForValidation()` sets reconciled=0 when checkbox absent (or `?? 0` in controller catches it) | — | — | ⬜ |
| TC-N-19 | paid_amount = 0 (Boundary) | `min:0` passes — zero-value collection created. FeeMaster status would be 'Partial' (if other collections exist paid_amount>0) or remain 'Pending' | — | — | ⬜ |
| TC-N-20 | Access export without viewAny permission | `Gate::authorize('tenant.fee-collection.viewAny')` → 403 | — | — | ⬜ |
| TC-N-21 | Access show without view permission | `Gate::authorize('tenant.fee-collection.view')` → 403 | — | — | ⬜ |
| TC-N-22 | payment_mode with very long string (boundary) | No `max` rule on payment_mode — long strings accepted by validation | — | — | ⬜ |
| TC-N-23 | status with arbitrary string (no Rule::in) | Status accepts ANY string — "Fully Paid", "Cancelled" etc. are all valid via validation | — | — | ⬜ |
| TC-N-24 | payment_mode with arbitrary string (no Rule::in) | Payment mode accepts ANY string — "Bitcoin", "Barter" etc. are all valid via validation | — | — | ⬜ |
| TC-N-25 | Create with empty `ids` field (no fee_master_id in URL) | `findOrFail("")` → ModelNotFoundException → 500 error | — | — | ⬜ |
| TC-N-26 | Store with payment_date far in the future | `date` rule passes (no before/after constraint) — large delay_days calculated | — | — | ⬜ |
| TC-N-27 | Standalone index without fee-collection.viewAny | `FeeCollectionController@index()` → Gate::authorize → 403 | — | — | ⬜ |
| TC-N-28 | Create form submitted with no fine_master_id but fine detail still expected | No fine_master_id → no TptStudentFineDetail created (correct) | — | — | ⬜ |
| TC-N-29 | Trash, Restore, ForceDelete Routes Return 404 | Accessing `/fee-collection/trash/view`, `/fee-collection/{id}/restore`, `/fee-collection/{id}/force-delete` → routes not defined → 404 | — | — | ⬜ |

### 6.3 TC-D: Data Integrity / Dependency Test Cases

| ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|----|----------|-------------|-----------------|---------|---------|--------|
| TC-D-01 | A | Create Fee Collection — FeeMaster Status Changes Pending→Partial→Completed | FeeMaster status recalculated based on cumulative collected amount | — | — | ⬜ |
| TC-D-02 | A | Create Fee Collection — FineDetail Auto-Created | When fine_master_id provided (with delay within range), TptStudentFineDetail record created with calculated fine_amount | — | — | ⬜ |
| TC-D-03 | A | FineDetail created with fine_amount=0 when delay outside range | fine_master_id provided but delayDays not in range → TptStudentFineDetail created with fine_amount=0, waved=0, net=0 | — | — | ⬜ |
| TC-D-04 | A | FineDetail creation fails when invalid fine_master_id | `TptFineMaster::find(99999)` returns null → `TptStudentFineDetail::create()` tries `$fineMaster->id` → **500 error** | — | — | ⬜ |
| TC-D-05 | B | Student Restricted by Fine | If fineMaster->student_restricted=1, `student->update(['is_active' => 0])` | — | — | ⬜ |
| TC-D-06 | C | Accounting RemoteEntryService Failure Logged (No Rollback) | If RemoteEntryService throws, error logged via `Log::error()`; payment transaction NOT rolled back | — | — | ⬜ |
| TC-D-07 | C | Accounting RemoteEntryService Success | If RemoteEntryService succeeds, accounting entry created for TPT_FEE_PAYMENT | — | — | ⬜ |
| TC-D-08 | D | DDL RESTRICT — Cannot Delete FeeMaster With Collections | FK `ON DELETE RESTRICT` on `student_fee_detail_id` prevents TptFeeMaster deletion if collections reference it | — | — | ⬜ |
| TC-D-09 | D | Store in DB Transaction Rollback on Exception | If exception occurs in store() transaction (e.g., StudentPayLog creation fails), all DB changes reverted | — | — | ⬜ |
| TC-D-10 | D | Update in DB Transaction Rollback on Exception | If exception occurs in update() transaction, all DB changes reverted | — | — | ⬜ |
| TC-D-11 | D | Destroy does NOT rollback (no transaction) | `destroy()` does NOT use `DB::transaction()` — failure at any step leaves partial state (StudentPayLog created but delete failed, or vice versa) | — | — | ⬜ |
| TC-D-12 | D | StrToLower on payment_mode in store | Input "Cash" → prepareForValidation "Cash" → controller strtolower "cash" → DB stores "cash" | — | — | ⬜ |
| TC-D-13 | D | Status stored as ucfirst (from prepareForValidation) | Input "paid" → prepareForValidation "Paid" → controller stores as-is → DB stores "Paid" | — | — | ⬜ |
| TC-D-14 | D | refreshFeeMasterStatus after update | `update()` calls `refreshFeeMasterStatus($feeCollection->feeMaster)` → FeeMaster status recalculated | — | — | ⬜ |
| TC-D-15 | D | refreshFeeMasterStatus NOT called after destroy | `destroy()` does NOT call `refreshFeeMasterStatus()` → FeeMaster status is STALE after deletion | — | — | ⬜ |
| TC-D-16 | D | StudentPayLog for delete | `destroy()` creates StudentPayLog with `activity_type='fee_collected_delete'` — original pay log entries remain | — | — | ⬜ |
| TC-D-17 | D | total_delay_days NOT recalculated on update | `update()` does NOT include `total_delay_days` in update array — old delay value persists even if payment_date changes | — | — | ⬜ |

### 6.4 TC-CR: Code Review Test Cases

| ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|----|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR-01 | CR | P1 | Blade @can Directives — Tab Visibility | `stdroutefeesmgmt.blade.php`: `@can('tenant.fee-collection.viewAny')` wraps `@include('transport::fee-collection.index')` | — | — | ◌ |
| TC-CR-02 | CR | P1 | Blade — Action Column Guards | `@canany(['tenant.fee-collection.edit', 'tenant.fee-collection.delete'])` wraps `<x-backend.table.action>` | — | — | ◌ |
| TC-CR-03 | CR | P1 | Controller — Gate::authorize() Before Every State Change | Every method: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, export | — | — | ◌ |
| TC-CR-04 | CR | P1 | Controller — activityLog Created After Every CRUD | Created, Updated, Deleted, Restored, Force Deleted | — | — | ◌ |
| TC-CR-05 | CR | P1 | Controller — StudentPayLog on Create/Update/Delete | create, update, destroy all create StudentPayLog entries | — | — | ◌ |
| TC-CR-06 | CR | P1 | Controller — FeeMaster Status Refresh After Store/Update | `refreshFeeMasterStatus()` called in store() and update() | — | — | ◌ |
| TC-CR-07 | CR | P1 | Controller — Fine Calculation Logic | Fine calculated only if fine_master_id provided AND delayDays within fine_from_days → fine_to_days range; TptStudentFineDetail always created if fine_master_id provided | — | — | ◌ |
| TC-CR-08 | CR | P1 | Controller — DB Transaction for store() and update() | Both methods use `DB::transaction()` for atomicity. ❌ destroy() does NOT use transaction | — | — | ◌ |
| TC-CR-09 | CR | P1 | Controller — OnlyTrashed for Restore/ForceDelete | restore() and forceDelete() use `onlyTrashed()->findOrFail()` — correct pattern | — | — | ◌ |
| TC-CR-10 | CR | P1 | Controller — Edit View paid_amount Readonly | `readonly` attribute on paid_amount input field in edit.blade.php | — | — | ◌ |
| TC-CR-11 | CR | P1 | Controller — Accounting Integration | `RemoteEntryService::processEvent('TRANSPORT', 'TPT_FEE_PAYMENT', ...)` after store; failure caught and logged | — | — | ◌ |
| TC-CR-12 | CR | P1 | Request — authorize() | POST → `tenant.fee-collection.create`; PUT/PATCH → `tenant.fee-collection.update` | — | — | ◌ |
| TC-CR-13 | CR | P1 | Request — prepareForValidation() | payment_mode: ucfirst(strtolower(...)), status: ucfirst(strtolower(...)), reconciled: 0/1 | — | — | ◌ |
| TC-CR-14 | CR | P1 | Request — No Rule::in for status/payment_mode | Both fields accept ANY string (no ENUM validation) | — | — | ◌ |
| TC-CR-15 | CR | P1 | Model — Table Name and SoftDeletes | `protected $table = 'tpt_student_fee_collection'` and `use SoftDeletes` present | — | — | ◌ |
| TC-CR-16 | CR | P1 | Model — Fillable Matches DB Columns | $fillable: student_fee_detail_id, payment_date, total_delay_days, paid_amount, payment_mode, status, reconciled, remarks — 8 fields | — | — | ◌ |
| TC-CR-17 | CR | P1 | Model — Casts | reconciled => 'boolean', payment_date => 'date' | — | — | ◌ |
| TC-CR-18 | CR | P1 | Model — Status Constants | STATUS_PAID='paid', STATUS_PENDING='pending', STATUS_OVERDUE='overdue'; PAYMENT_CASH, PAYMENT_ONLINE, PAYMENT_CHEQUE constants | — | — | ◌ |
| TC-CR-19 | CR | P1 | Routes | `Route::resource('fee-collection', FeeCollectionController::class)` + `/fee-collection/allocation/export`. ❌ Missing: trash/view, restore, force-delete | — | — | ◌ |
| TC-CR-20 | CR | P1 | View — Table and Summary Cards | 4 summary cards (Total Due, Total Collected, Pending, Rate), filter bar (Session, Month, Status), enhanced table with #, Student Details, Fee Details, Payment Info, Status, Action | — | — | ◌ |
| TC-CR-21 | CR | P1 | View — Show Page Fields | Fee Month, Due Date, Fee Amount, Payment Date, Paid Amount, Delay Days, Payment Mode, Status, Reconciled, Remarks + Linked Fee Master Summary | — | — | ◌ |
| TC-CR-22 | CR | P1 | View — Flash Messages | `created.fee_collection`, `updated.fee_collection`, `deleted.fee_collection`, `restored.fee_collection`, `force_deleted.fee_collection` | — | — | ◌ |
| TC-CR-23 | CR | P1 | DDL — RESTRICT FK on student_fee_detail_id | FK with ON DELETE RESTRICT | — | — | ◌ |
| TC-CR-24 | CR | P1 | DDL — No updated_at column | No `updated_at` in DDL for tpt_student_fee_collection | — | — | ◌ |
| TC-CR-25 | CR | P1 | Controller — studentAllocation Eager-Load Mismatch | Controller `index()` line 31 calls `->with(['studentAllocation', 'feeMaster'])` but model has NO `studentAllocation()` relationship — **runtime error** | — | — | ◌ |
| TC-CR-26 | CR | P1 | Routes — Missing trash/restore/forceDelete Registration | Four controller methods (trashed, restore, forceDelete) + view (trash.blade.php) are implemented but routes are NOT registered. Compare with FeeMasterController, FineCategoryController, FineMasterController which all register these routes | — | — | ◌ |
| TC-CR-27 | CR | P1 | Policy — Unused Permission Methods | Policy defines `status()`, `import()`, `print()`, `collect()`, `generateReceipt()`, `viewReports()`, `reconcile()`, `refund()` — no controller methods exist | — | — | ◌ |
| TC-CR-28 | CR | P1 | Controller — destroy() does NOT refresh FeeMaster status | After soft-delete, FeeMaster.status is stale — collected amount still counted. This is a data integrity bug | — | — | ◌ |
| TC-CR-29 | CR | P1 | Controller — store() strtolower OVERRIDES prepareForValidation | prepareForValidation sets "Cash", controller line 130 strtolower sets "cash". Configurable — should either normalize in request OR controller, not both | — | — | ◌ |
| TC-CR-30 | CR | P1 | Controller — update() does NOT recalculate total_delay_days | If payment_date is changed in update, total_delay_days stays at original value — stale | — | — | ◌ |
| TC-CR-31 | CR | P1 | Controller — update() does NOT re-trigger fine calculation | Fine details are NOT re-created on update — cannot change fine association | — | — | ◌ |
| TC-CR-32 | CR | P1 | Controller — edit() does NOT pass fineSelect to view | edit() loads studentAllocation and feeMatser but NOT fineSelect — user cannot change fine association | — | — | ◌ |
| TC-CR-33 | CR | P1 | Controller — store() creates fineDetail BEFORE feeCollection | Order: fineDetail (line 107) → feeCollection (line 125). Fine detail references `$request->ids` (fee_master_id), NOT the new feeCollection FK | — | — | ◌ |
| TC-CR-34 | CR | P1 | Controller — Variable Typo `feeMatser` | Controller lines 45, 212: `$feeMatser = TptFeeMaster::get()` — variable name misspelling (missing 't') | — | — | ◌ |
| TC-CR-35 | CR | P1 | Controller — export() uses viewAny permission | `Gate::authorize('tenant.fee-collection.viewAny')` — same permission as index. No dedicated export permission | — | — | ◌ |
| TC-CR-36 | CR | P1 | Controller — trashed()/restore()/forceDelete() redirect to non-existent route | `redirect()->route('transport.fee-collection.trashed')` — route name `fee-collection.trashed` is NOT registered in web.php. Redirect will throw RouteNotFoundException | — | — | ◌ |
| TC-CR-37 | CR | P1 | Controller — trashed() returns non-existent view | `return view('transport::fee-collection.trash', compact('data'))` — file `trash.blade.php` does NOT exist in resources/views/fee-collection/ | — | — | ◌ |
| TC-CR-38 | CR | P1 | Tab Controller — Standalone Filter Inconsistency | Tab controller `feeCollectionData()` supports 3 filters. Standalone `FeeCollectionController@index()` has ZERO filter support | — | — | ◌ |
| TC-CR-39 | CR | P1 | Tab Controller — Summary Calculation uses total_amount | `$totalDue = $collections->sum(fn($row) => $row->feeMaster->total_amount ?? 0)` — uses total_amount, not amount | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P-02: Create Fee Collection — Full Payment On Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Student Route Fees Mgmt → Fee Creation tab | Fee master list visible |
| 2 | Locate a fee master with Pending status | Record has amount, due_date |
| 3 | Click Action → "Add Collection" on that fee master row | Navigate to `/fee-collection/create?fee_master_id={id}&source=fee_tab` |
| 4 | Verify fee_master_id is pre-populated in hidden field `ids` | `<input type="hidden" name="ids" value="{fee_master_id}">` |
| 5 | Enter payment_date = same as due_date | Field filled |
| 6 | Enter paid_amount = same as fee master amount | Field filled |
| 7 | Select payment_mode = "Cash" | Dropdown set to `Cash` |
| 8 | Select status = "Paid" | Dropdown set to `paid` |
| 9 | Leave reconciled unchecked | Checkbox unchecked |
| 10 | Leave remarks empty | Optional field |
| 11 | Click "Save Fee Collection" | POST `/fee-collection` with form data |
| 12 | Verify Gate: `FeeCollectionRequest::authorize()` returns true | POST method → `tenant.fee-collection.create` allowed |
| 13 | Verify Gate: Controller line 60 `Gate::authorize('tenant.fee-collection.create')` | Passes authorization |
| 14 | Verify `DB::transaction()` started (line 61) | Transaction active |
| 15 | Verify `TptFeeMaster::findOrFail($request->ids)` (line 66) | Fee master found |
| 16 | Verify delay calculation (line 71-73): payment_date = due_date → `$paymentDate->gt($dueDate)` = false | `$delayDays = 0` |
| 17 | Verify no fine master selected → fine block skipped | No TptStudentFineDetail created |
| 18 | Verify fee collection created (line 125-134): `TptStudentFeeCollection::create([...])` | `student_fee_detail_id`, `payment_date`, `total_delay_days=0`, `paid_amount`, `payment_mode='cash'` (strtolower), `status='Paid'`, `reconciled=0`, `remarks=null` |
| 19 | Verify `payment_mode` stored as lowercase `'cash'` | Controller line 130: `strtolower("Cash")` = "cash" — prepareForValidation ucfirst undone |
| 20 | Verify `refreshFeeMasterStatus($feeMaster)` called (line 139) | FeeMaster status recalculated |
| 21 | Verify `StudentPayLog::create()` (line 144-154) | Entry with `activity_type='fee_collected_create'` |
| 22 | Verify `RemoteEntryService::processEvent()` called (line 160-171) | Accounting event triggered for TPT_FEE_PAYMENT |
| 23 | Verify `activityLog($feeCollection, 'Created', [...])` (line 183-185) | Activity log entry created |
| 24 | Verify DB::commit() | Transaction committed |
| 25 | Verify redirect | Redirected to `/std-route-Fees-mgmt?tab=fee_creation` |
| 26 | Verify flash message | "Fee Collection created successfully" (`flash('created.fee_collection')`) |
| 27 | DB check: `SELECT * FROM tpt_student_fee_collection WHERE student_fee_detail_id={id}` | Record exists with correct values |
| 28 | DB check: FeeMaster status | `SELECT status FROM tpt_student_fee_detail WHERE id={id}` → 'Completed' |
| 29 | StudentPayLog check: `SELECT * FROM std_student_pay_log WHERE activity_type='fee_collected_create' AND reference_id={id}` | Entry exists with student_id, academic_session_id, amount |

### TC-P-04: Create Fee Collection — Payment With Fine (Fixed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a TptFineMaster exists with fine_type='Fixed', fine_rate=50, fine_from_days=1, fine_to_days=30, student_restricted=0 | Fine master active |
| 2 | Navigate to Fee Collection create page | Form loaded |
| 3 | Enter payment_date = due_date + 10 days | Delay days = 10 |
| 4 | Enter paid_amount = full amount | Field filled |
| 5 | Select Fine Type = created fine master from dropdown | fine_master_id set |
| 6 | Select status = "Paid" | Status set |
| 7 | Select payment_mode = "Cash" | Mode set |
| 8 | Click "Save Fee Collection" | POST to store |
| 9 | Verify controller line 80: `$request->filled('fine_master_id')` = true | Fine master provided |
| 10 | Verify controller line 82: `TptFineMaster::find($request->fine_master_id)` | $fineMaster found |
| 11 | Verify controller line 84-86: delayDays(10) >= fine_from_days(1) && <= fine_to_days(30) | true → enters calculation |
| 12 | Verify controller line 88-89: `$fineMaster->fine_type === 'Fixed'` → `$fineAmount = 50` | $fineAmount = 50 |
| 13 | Verify controller line 97-104: `$fineMaster->student_restricted == 1` = false | Student NOT restricted |
| 14 | Verify controller line 107-117: `TptStudentFineDetail::create([...])` | Created with correct values |
| 15 | Verify fine detail `fine_days=10`, `fine_amount=50`, `fine_type='Fixed'`, `fine_rate=50.00` | All fields correct |
| 16 | Verify `waved_fine_amount=0`, `net_fine_amount=50` | Default wave amount |
| 17 | Verify controller line 125-134: `TptStudentFeeCollection::create()` | Fee collection created |
| 18 | Verify `paid_amount` stored correctly | DB has correct amount |

### TC-P-05: Create Fee Collection — Payment With Fine (Percentage)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure TptFineMaster with fine_type='Percentage', fine_rate=10 (10%), fine_from_days=1, fine_to_days=15 | Fine master active |
| 2 | Ensure fee master has amount = 500 | Fee base amount |
| 3 | Create collection with payment_date = due_date + 5 days | Delay 5 days |
| 4 | Select fine master = Percentage type fine | fine_master_id set |
| 5 | Submit form | POST to store |
| 6 | Verify controller line 92-93: `$fineAmount = ($feeMaster->amount * $fineMaster->fine_rate) / 100` | `(500 * 10) / 100 = 50` |
| 7 | Verify DB fine_detail: `fine_amount=50, fine_type='Percentage', fine_rate=10.00` | Records match |

### TC-P-06: Create Fee Collection — Overdue Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee collection with payment_date > due_date (e.g., 15 days after) | `total_delay_days=15` |
| 2 | Select status = "overdue" | Status set to overdue |
| 3 | Submit form | Collection created |
| 4 | DB check: `total_delay_days=15`, `status='overdue'` | Stored correctly |
| 5 | Navigate to index/list | Table row shows red "Overdue" badge with exclamation-triangle icon |
| 6 | Verify "Due: X days ago" text shown in status column | Due date diff displayed |

### TC-P-08: Edit Fee Collection — Change Status and Remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Fee Collection list | Table with records |
| 2 | Click Edit icon on an existing collection | GET `/fee-collection/{id}/edit` |
| 3 | Verify Gate: Controller line 209 `Gate::authorize('tenant.fee-collection.update')` | Passes authorization |
| 4 | Verify `TptStudentFeeCollection::findOrFail($id)` (line 210) | Record found |
| 5 | Verify edit form fields are pre-populated | payment_date, paid_amount (readonly), payment_mode, status, reconciled, remarks |
| 6 | Change status from "Paid" to "Pending" | Dropdown changed |
| 7 | Change remarks to "Updated via edit" | Text input |
| 8 | Click "Update Fee Collection" | PUT `/fee-collection/{id}` |
| 9 | Verify `DB::transaction()` started (line 228) | Transaction active |
| 10 | Verify `$feeCollection->update([...])` (line 230-237) — fields: payment_date, paid_amount, payment_mode, status, reconciled, remarks | 6 fields updated |
| 11 | Verify `total_delay_days` is NOT in update array | **Known limitation**: delay not recalculated |
| 12 | Verify `activityLog($feeCollection, 'Updated', [...])` (line 239-241) | Activity log created |
| 13 | Verify `StudentPayLog::create([...activity_type='fee_collected_update'])` (line 246-256) | Pay log entry created |
| 14 | Verify `refreshFeeMasterStatus($feeCollection->feeMaster)` (line 259) | FeeMaster status recalculated |
| 15 | Verify redirect to tab with flash | "Fee collection updated successfully" |

### TC-P-09: Edit — paid_amount is Readonly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit form for a collection | Edit form loaded |
| 2 | Inspect paid_amount input field | `<input type="number" name="paid_amount" ... readonly>` |
| 3 | Try to change paid_amount value via browser | `readonly` attribute prevents editing |
| 4 | Try to submit with modified paid_amount via DevTools | Remove readonly → change value → submit → controller accepts the changed value (no server-side guard — only client-side readonly) |
| 5 | **Security Finding**: `readonly` is client-side only. Server does NOT re-validate that paid_amount is unchanged. If user bypasses readonly, any value is accepted. | Potential data integrity issue |
| 6 | DB check after modified submission | Changed paid_amount stored in DB |

### TC-P-10: Soft Delete Fee Collection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Fee Collection list | Table with records |
| 2 | Click Delete icon on an existing collection | DELETE `/fee-collection/{id}` |
| 3 | Verify Gate: line 272 `Gate::authorize('tenant.fee-collection.delete')` | Passes authorization |
| 4 | Verify `TptStudentFeeCollection::findOrFail($id)` (line 273) | Record found |
| 5 | Verify `$feeCollection->delete()` (line 274) | Soft delete — `deleted_at` set |
| 6 | Verify `StudentPayLog::create([...activity_type='fee_collected_delete'])` (line 276-286) | Pay log created for deletion |
| 7 | Verify `activityLog($feeCollection, 'Deleted', [...])` (line 288-290) | Activity log created |
| 8 | Verify redirect to tab | `redirect()->route('transport.std-route-Fees-mgmt.index')` |
| 9 | Verify flash message | "Fee collection deleted" (`flash('deleted.fee_collection')`) |
| 10 | DB check: `SELECT deleted_at FROM tpt_student_fee_collection WHERE id=X` | `deleted_at IS NOT NULL` |
| 11 | **CRITICAL** Verify: `refreshFeeMasterStatus()` NOT called | FeeMaster.status is STALE — still counts the deleted collection's amount |

### TC-P-23: Fine Master Selected, Delay Outside Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure TptFineMaster with fine_from_days=1, fine_to_days=7, fine_type='Fixed', fine_rate=100 | Fine master with 1-7 day window |
| 2 | Create collection with payment_date = due_date + 15 days | Delay 15 days > fine_to_days(7) |
| 3 | Select the fine master | fine_master_id provided but delay outside range |
| 4 | Submit form | POST to store |
| 5 | Verify controller line 84-86: `$delayDays(15) >= 1 && <= 7` | **false** — delay outside range |
| 6 | Verify fineAmount stays 0 | `$fineAmount = 0` (never set inside if block) |
| 7 | Verify controller line 107-117: `TptStudentFineDetail::create([...])` STILL executes | Fine detail created with `fine_days=15, fine_amount=0, net_fine_amount=0` |
| 8 | DB check: `SELECT * FROM tpt_student_fine_detail WHERE student_fee_detail_id=X` | Record with fine_amount=0 |
| 9 | **Note**: Fine record with zero amount is created unnecessarily | No operational impact but wastes DB space |

### TC-P-34: FeeMaster Status Transition Pending → Partial → Completed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure FeeMaster with amount=1000, current status='Pending', no existing collections | Initial state |
| 2 | Create collection 1: paid_amount=300, payment_date=on time | Collection created |
| 3 | Verify `refreshFeeMasterStatus()`: `$collected=300`, `$due=1*1000=1000`, `300>0 && 300<1000` | FeeMaster.status = 'Partial' |
| 4 | Create collection 2: paid_amount=700, same FeeMaster | Collection created |
| 5 | Verify `refreshFeeMasterStatus()`: `$collected=300+700=1000`, `$due=2*1000=2000`, `1000<2000` | FeeMaster.status = 'Partial' (because `$students=2` now) |
| 6 | **CRITICAL**: `$due = $students * $feeMaster->amount` = 2 × 1000 = 2000 | But only 2 collections exist for 2 students — total due should be 2000 |
| 7 | Create collection 3: paid_amount=1000 | Now $collected=2000, $students=3, $due=3000. Still Partial |
| 8 | **Observation**: `refreshFeeMasterStatus()` uses `count() * amount` formula | Status may never reach 'Completed' if feeMaster has many students but only some pay |

### TC-P-18: Create Fee Collection — Payment With Cheque Mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter valid data | All required fields filled |
| 3 | Select payment_mode = "Cheque" | Dropdown value = "Cheque" |
| 4 | Submit form | POST to store |
| 5 | Verify `FeeCollectionRequest::prepareForValidation()` line 67: `ucfirst(strtolower("Cheque"))` | "Cheque" |
| 6 | Verify controller store() line 130: `strtolower("Cheque")` | "cheque" |
| 7 | DB check: `payment_mode` = "cheque" (lowercase) | Stored as lowercase |
| 8 | Navigate to show page: display uses `ucfirst($record->payment_mode)` | Shows "Cheque" |
| 9 | Navigate to index: blade line 222: `ucfirst($row->payment_mode)` | Shows "Cheque" |

### TC-D-11: Destroy Does NOT Use DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FeeCollectionController@destroy()` lines 270-295 | Inspect code |
| 2 | Search for `DB::transaction()` or `DB::beginTransaction()` | **NOT FOUND** — no transaction wrapper |
| 3 | Compare with `store()` and `update()` which both use transactions | **Inconsistency**: destroy is the only CRUD operation without a transaction |
| 4 | Verify execution flow: line 273 findOrFail → 274 delete → 276 StudentPayLog → 288 activityLog | All run without transaction protection |
| 5 | **Impact**: If StudentPayLog::create() fails after delete, the fee collection is already deleted (no rollback) | Partial state: deleted collection without pay log |
| 6 | **Impact**: If activityLog() fails after StudentPayLog, the pay log is already created | Orphaned pay log entry |

### TC-D-06: Accounting RemoteEntryService Failure Logged (No Rollback)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up store() with valid data | All fields valid |
| 2 | Simulate RemoteEntryService failure (e.g., misconfigured accounting module) | `app(RemoteEntryService::class)->processEvent(...)` throws exception |
| 3 | Verify `try/catch` block lines 173-179 catches `\Throwable` | Exception caught |
| 4 | Verify `Log::error('RemoteEntryService failed on fee payment', [...])` | Error logged with payment_id and error message |
| 5 | Verify payment still committed (transaction completed) | Fee collection exists in DB |
| 6 | Verify StudentPayLog exists | `activity_type='fee_collected_create'` present |
| 7 | Verify activityLog exists | Activity log Created entry present |
| 8 | Verify redirect with success flash | User sees success (not error) — accounting failure is silent |
| 9 | **Note**: Business decision — payment collection always succeeds even if accounting sync fails | Accounting team must manually reconcile failed entries |

### TC-N-14: Invalid fine_master_id Causes 500 Error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Enter valid data for all required fields | Valid |
| 3 | Set fine_master_id to a non-existent value (e.g., 99999) | Via form select (if it doesn't appear, submit programmatically) |
| 4 | Submit form | POST to store |
| 5 | Verify controller line 82: `TptFineMaster::find(99999)` | Returns `null` (NOT `findOrFail`) |
| 6 | Verify controller line 80-120: enters `if ($request->filled('fine_master_id'))` block | true (99999 is filled) |
| 7 | Verify controller line 84-86: `if ($fineMaster && ...)` — `$fineMaster` is null → condition false | Skips fine calculation |
| 8 | Verify controller line 97: `if((isset($fineMaster)) && ...)` — `isset(null)` = false | Skips student restriction |
| 9 | Verify controller line 107-117: `TptStudentFineDetail::create([...'fine_master_id' => $fineMaster->id...])` | **$fineMaster is null → `$fineMaster->id` throws `Error: Call to a member function id on null`** |
| 10 | **500 Error** — script crashes at line 109 | `Symfony\Component\Debug\Exception\FatalThrowableError` |
| 11 | Verify `DB::rollBack()` triggered by transaction catch | Transaction rolled back — no data created |
| 12 | **BUG**: `find()` should be `findOrFail()` or null check before creating fine detail | Data integrity issue |

### TC-N-25: Create With Empty `ids` Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/fee-collection/create` WITHOUT `?fee_master_id=` parameter | Create form loads |
| 2 | Verify hidden field `ids`: `<input type="hidden" name="ids" value="">` | Empty value |
| 3 | Fill all other required fields | Valid data |
| 4 | Submit form | POST to store |
| 5 | Verify controller line 66: `TptFeeMaster::findOrFail($request->ids)` | `findOrFail("")` — empty string |
| 6 | `findOrFail("")` tries `SELECT * FROM tpt_student_fee_detail WHERE id = 0` → returns null | `ModelNotFoundException` thrown |
| 7 | **500 Error**: No record found for empty ID | User sees Laravel error page |
| 8 | Verify DB::rollBack() invoked by transaction catch | No data created |

### TC-CR-25: studentAllocation Eager-Load Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FeeCollectionController.php` line 31 | `$data = TptStudentFeeCollection::with(['studentAllocation', 'feeMaster'])` |
| 2 | Open `TptStudentFeeCollection.php` model | Search for `studentAllocation()` method — **NOT FOUND** |
| 3 | Relationships in model: `feeMaster()`, `studentFeeDetail()`, `fineDetails()` | 3 relationships, NONE named `studentAllocation` |
| 4 | Access standalone index URL `/fee-collection` | Controller index() runs |
| 5 | Line 31: Eloquent tries to eager-load `studentAllocation` relationship | `RelationNotFoundException: Call to undefined relationship [studentAllocation] on model [TptStudentFeeCollection]` |
| 6 | **500 Error on every standalone index access** | Tab-based index (via StudentRouteFeesController) works fine — uses `feeMaster.academicSession` |
| 7 | **Impact**: The standalone `/fee-collection` route returns a 500 error | Feature broken when accessed outside tab container |

### TC-CR-28: destroy() Does NOT Call refreshFeeMasterStatus()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` method (line 270-295) | Full method code |
| 2 | Check for any call to `$this->refreshFeeMasterStatus()` | **Not found** anywhere in destroy() |
| 3 | Check blueprint: store() line 139 calls refreshFeeMasterStatus; update() line 259 calls it | Both other CUD methods refresh status |
| 4 | Create a FeeMaster with one collection (paid_amount=500, amount=500) → status='Completed' | Initial state |
| 5 | Delete the only collection via destroy() | Soft deleted |
| 6 | DB check: FeeMaster.status after delete | **Still 'Completed'** — should be 'Pending' since no active collections remain |
| 7 | **BUG**: Stale FeeMaster status after deletion | Data integrity issue — FeeMaster shows wrong status |

### TC-CR-26: Routes Missing for trash/restore/forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` lines 210-230 | Compare FeeCollection route section with other entities |
| 2 | FeeCollection routes (lines 216-221): only `export` + `resource` | ONLY 2 route entries |
| 3 | FeeMaster routes (lines 201-213): resource + trash/view + restore + force-delete + toggle-status + pdf | 6 routes (all registered) |
| 4 | FineCategory routes (lines 224-229): resource + trash/view + restore + force-delete + toggle-status | 5 routes |
| 5 | FineMaster routes (lines 232-237): resource + trash/view + restore + force-delete | 4 routes |
| 6 | **GAP**: Only FeeCollection is missing trash/restore/forceDelete routes | **Inconsistent** — all other resource controllers have these routes |
| 7 | Verify `FeeCollectionController` HAS trashed(), restore(), forceDelete() methods (lines 312-356) | Methods exist — fully implemented |
| 8 | Verify `trash.blade.php` does NOT exist | View file NOT created |
| 9 | **Summary**: Controller code is complete but routes and view are MISSING | Feature is dead code |

### TC-CR-29: store() strtolower OVERRIDES prepareForValidation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FeeCollectionRequest.php` lines 63-70 | `prepareForValidation()`: `payment_mode = ucfirst(strtolower(...))` |
| 2 | Open `FeeCollectionController.php` line 130 | `'payment_mode' => strtolower($request->payment_mode)` |
| 3 | Trace data flow: Input "CASH" → Request: `ucfirst(strtolower("CASH"))` = "Cash" → Controller: `strtolower("Cash")` = "cash" | Net result: DB stores "cash" |
| 4 | Trace data flow: Input "cash" → Request: "Cash" → Controller: "cash" | Same result |
| 5 | Trace data flow: Input "Cheque" → Request: "Cheque" → Controller: "cheque" | Same |
| 6 | The `ucfirst()` in prepareForValidation is REDUNDANT — controller immediately lowercases | prepareForValidation has no effect on final stored value |
| 7 | Impact on status: No strtolower in controller for status → `prepareForValidation` ucfirst survives | DB stores "Paid", "Pending", "Overdue" |
| 8 | **Recommendation**: Either remove strtolower from controller (let prepareForValidation's ucfirst stand) or remove ucfirst from prepareForValidation | Inconsistent normalization strategy |

### TC-CR-30: update() Does NOT Recalculate total_delay_days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` lines 230-237 | `$feeCollection->update([...])` array |
| 2 | List updated fields: payment_date, paid_amount, payment_mode, status, reconciled, remarks | **6 fields** listed |
| 3 | Check if `total_delay_days` is in the array | **NOT present** |
| 4 | Check if any delay recalculation logic exists in update() | **Not found** anywhere in update method |
| 5 | Create collection with payment_date=2026-01-15, due_date=2026-01-10, delay=5 | Initial state |
| 6 | Update payment_date to 2026-01-20 (closer to due) | New payment_date |
| 7 | DB check: `total_delay_days` after update | **Still 5** — NOT recalculated for new payment_date 2026-01-20 (which is 10 days after due) |
| 8 | **BUG**: Stale delay days after payment_date change | Data integrity issue |

### TC-CR-36: trashed() Redirects to Non-existent Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `restore()` line 336 | `redirect()->route('transport.fee-collection.trashed')` |
| 2 | Open `forceDelete()` line 354 | `redirect()->route('transport.fee-collection.trashed')` |
| 3 | Open `routes/web.php` | Search for route name `fee-collection.trashed` |
| 4 | Verify: other entities have named routes like `fine-category.trashed`, `fine-master.trashed` | These exist with explicit ->name() |
| 5 | Check resource route for fee-collection: `Route::resource('fee-collection', FeeCollectionController::class)` | Resource generates `fee-collection.destroy`, `fee-collection.update` etc. but NOT `fee-collection.trashed` |
| 6 | **Conclusion**: Route name `transport.fee-collection.trashed` does NOT exist in web.php | Calling restore() or forceDelete() will throw `RouteNotFoundException` |
| 7 | **Impact**: Even if routes for restore/forceDelete were added, the redirect would still fail | Route name mismatch — would need `->name('fee-collection.trashed')` added |

### TC-P-01: Fee Collection Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin user (all permissions) | Authenticated |
| 2 | Verify user has `tenant.fee-collection.viewAny` permission | Policy allows |
| 3 | Navigate to `/std-route-Fees-mgmt?tab=fee_collection` | Page loads |
| 4 | Verify Gate: `StudentRouteFeesController@index()` line 32 `Gate::authorize('tenant.transport.viewAny')` | Authorized for transport module |
| 5 | Verify tab `fee_collection-pane` is active | `class="tab-pane fade p-4 bg-white rounded shadow-sm show active"` |
| 6 | Verify 4 summary cards visible: Total Due (indigo), Total Collected (green), Pending (yellow), Collection Rate (cyan) | 4 colored cards with icon + amount |
| 7 | Verify Total Due card shows `₹{total_due}` with file-invoice icon | Correct |
| 8 | Verify Total Collected card shows `₹{total_collected}` with money-check-alt icon | Correct |
| 9 | Verify Pending card shows `₹{pending}` computed as `abs(total_due - total_collected)` | Correct |
| 10 | Verify Collection Rate card shows `{round((total_collected/total_due)*100,1)}%` or `0%` if total_due=0 | Correct |
| 11 | Verify filter form present with 3 fields: Academic Session (dropdown from $organizationData), Month (1-12 dropdown), Payment Status (paid/pending/overdue) | Filters visible |
| 12 | Verify "Filter" button with filter icon | `<i class="fas fa-filter">` |
| 13 | Verify "Reset" link to `url()->current()` | Clears all filters |
| 14 | Verify Quick Stats badges: Total Records, Paid count, Pending count, Overdue count | Badges styled bg-light, bg-success, bg-warning, bg-danger |
| 15 | Verify enhanced table with header: #, Student Details, Fee Details, Payment Info, Status, Action | Header row correct |
| 16 | Verify # column uses `$feeCollectionList->firstItem() + $key` | Correct pagination numbering |
| 17 | Verify Student Details shows student first_name or 'N/A' | From `$row->feeMaster->academicSession->student->first_name` |
| 18 | Verify Fee Details shows Month (F Y format), Amount (₹ formatted), and delay badge if > 0 | All details correct |
| 19 | Verify Payment Info shows payment_date (d-M-Y), paid_amount (₹ formatted), payment_mode badge | Mode shown via `ucfirst()` |
| 20 | Verify Status column shows colored badge: Paid (green+check), Overdue (red+exclamation), Pending (yellow+clock) | Status indicators |
| 21 | Verify Action column renders only if user has edit OR delete permission | `@canany(['tenant.fee-collection.edit', 'tenant.fee-collection.delete'])` |
| 22 | Verify Action column uses `<x-backend.table.action>` component | Standard action buttons |
| 23 | Verify pagination links at bottom: `$feeCollectionList->withQueryString()->links()` | Page navigation |
| 24 | If no records: verify empty state with icon and "No fee collection records found" | Empty state rendered |

### TC-P-30: Verify StudentPayLog Created on Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a fee collection via store() | Success |
| 2 | DB query: `SELECT * FROM std_student_pay_log WHERE activity_type='fee_collected_create' ORDER BY id DESC LIMIT 1` | Most recent entry |
| 3 | Verify `student_id` = student ID from feeMaster->academicSession->student | `optional($feeCollection->feeMaster->academicSession->student)->id` |
| 4 | Verify `academic_session_id` = `$feeCollection->feeMaster->std_academic_sessions_id` | Correct session |
| 5 | Verify `module_name` = 'Transport' | Fixed value |
| 6 | Verify `activity_type` = 'fee_collected_create' | Correct type |
| 7 | Verify `reference_id` = `$feeCollection->id` | Links back to collection |
| 8 | Verify `reference_table` = 'tpt_student_fee_collection' | Table reference |
| 9 | Verify `description` = 'Transport fee collected' | Description text |
| 10 | Verify `amount` = `$feeCollection->paid_amount` | Amount matches |
| 11 | Verify `triggered_by` = `auth()->id()` | Current user ID |

### TC-P-32: Verify StudentPayLog Created on Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a fee collection (id=X) | Created |
| 2 | Verify StudentPayLog entry exists for creation (fee_collected_create) | 1 entry for create |
| 3 | Delete the fee collection via destroy(id=X) | Soft deleted |
| 4 | DB query: `SELECT * FROM std_student_pay_log WHERE reference_id=X AND reference_table='tpt_student_fee_collection'` | 2 entries: create + delete |
| 5 | Verify delete entry: `activity_type='fee_collected_delete'` | Correct type |
| 6 | Verify delete entry: `description='Transport fee collected Deleted'` | Description (note the odd capitalization — "collected Deleted" not "collected deleted") |
| 7 | Verify the original create entry STILL EXISTS | NOT deleted — new entry created for the delete action |
| 8 | **Note**: StudentPayLog is APPEND-ONLY — no records are ever deleted | Audit trail preserved |

### TC-N-17: XSS Injection In remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fee collection with remarks = `<script>alert('XSS')</script>` | Stored via create |
| 2 | DB check: remarks field contains literal `<script>alert('XSS')</script>` | Raw string stored |
| 3 | Navigate to show page for this collection | Show page renders |
| 4 | Verify show.blade.php line 131: `{{ $record->remarks ?? '-' }}` | Blade's `{{ }}` escapes HTML — displays literal `<script>alert('XSS')</script>` as text |
| 5 | Verify no script execution in browser | XSS prevented by Blade escaping |
| 6 | Navigate to index list | Table displays escaped text |
| 7 | **Note**: Using `{!! !!}` (unescaped) would be vulnerable — current code is safe | All transport blades use `{{ }}` escaping |

### TC-P-35: Verify Summary Cards Show Correct Totals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed data: 3 fee masters: FM1(amount=500, total_amount=500), FM2(amount=300, total_amount=300), FM3(amount=700, total_amount=700) | 3 fee masters |
| 2 | Create collections: C1 for FM1(paid=500), C2 for FM2(paid=100), C3 for FM3(paid=700) | 3 collections |
| 3 | Navigate to tab with no filters | All records shown |
| 4 | Verify `feeCollectionSummary()`: `$totalDue = $collections->sum(fn($r) => $r->feeMaster->total_amount ?? 0)` | 500 + 300 + 700 = 1500 |
| 5 | Verify `$totalCollected = $collections->sum('paid_amount')` | 500 + 100 + 700 = 1300 |
| 6 | Verify `$pending = abs(1500 - 1300)` = 200 | Pending = 200 |
| 7 | Verify Collection Rate = `(1300/1500)*100` = 86.7% | Rate shown as 86.7% |
| 8 | Apply filter for status='paid' | Only C1 and C3 shown (C2 is pending) |
| 9 | Verify filtered summary: total_due = 500+700=1200, total_collected = 500+700=1200, pending=0, rate=100% | Cards reflect filtered subset |

### TC-P-33: Multiple Collections for Same FeeMaster

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FeeMaster with amount=500, fee detail: FM1 | Initial state |
| 2 | Create Collection 1: paid_amount=200 | Created |
| 3 | Verify `refreshFeeMasterStatus(FM1)`: `$students=1`, `$collected=200`, `$due=1*500=500` | Status='Partial' (200>0 && 200<500) |
| 4 | Create Collection 2: paid_amount=300 | Created |
| 5 | Verify `refreshFeeMasterStatus(FM1)`: `$students=2`, `$collected=200+300=500`, `$due=2*500=1000` | Status='Partial' (500<1000) |
| 6 | **Key insight**: `$students` = count of collections = 2 now. `$due` = 2 × 500 = 1000. But total due is actually 500 (one student owes 500). The formula is WRONG for multiple collections for the same student. | **BUG** in status calculation |
| 7 | Create Collection 3: paid_amount=500 | Now $students=3, $collected=1000, $due=1500 |
| 8 | Status = 'Partial' (1000<1500) — will NEVER reach Completed | Infinite partial state |
| 9 | **RECOMMENDATION**: `refreshFeeMasterStatus()` should use `$feeMaster->amount` directly (not `$students * amount`) | Current formula is fundamentally flawed for multi-collection scenario |

### TC-D-04: FineDetail Creation Fails With Invalid fine_master_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit store() with fine_master_id=99999 (non-existent) | POST request |
| 2 | Controller line 82: `$fineMaster = TptFineMaster::find(99999)` | `$fineMaster = null` |
| 3 | Controller line 84-86: `if ($fineMaster && ...)` → false | Skip fine calculation |
| 4 | Controller line 97: `if(isset($fineMaster) && ...)` → `isset(null)` = false | Skip student restriction |
| 5 | Controller line 107-117: `TptStudentFineDetail::create(['fine_master_id' => $fineMaster->id, ...])` | `$fineMaster->id` on null → **Error** |
| 6 | `Symfony\Component\ErrorHandler\Error\FatalThrowableError: Call to a member function id on null` | **500 error** |
| 7 | `DB::transaction()` catch block (needs to check if controller has one — it uses `DB::transaction(function() {...})` which auto-rolls back on exception) | Transaction rolled back automatically |
| 8 | No data created | DB unchanged |
| 9 | **BUG**: Should use `findOrFail()` or check for `$fineMaster !== null` before creating fine detail | Data integrity vulnerability |

### TC-CR-20: View — Table and Summary Cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index.blade.php` | Full view file (300 lines) |
| 2 | Verify 4 summary cards at lines 5-71: Total Due (line 7-18), Total Collected (lines 21-33), Pending (lines 36-48), Collection Rate (lines 51-70) | All 4 cards with inline styles |
| 3 | Verify filter bar at lines 74-126: Academic Session select (78-87), Month select (90-101), Payment Status select (103-111), Filter button (116-118), Reset link (119-121) | 3 filters + actions |
| 4 | Verify Quick Stats badges at lines 128-150: Total Records, Paid, Pending, Overdue | Stat badges |
| 5 | Verify table header at lines 158-167: #, Student Details, Fee Details, Payment Info, Status, Action | 6 columns |
| 6 | Verify Action column guarded by `@canany(['tenant.fee-collection.edit', 'tenant.fee-collection.delete'])` at line 164 | Permission-based visibility |
| 7 | Verify Student Details using `$row->feeMaster->academicSession->student` at line 172 | Multi-relationship chain |
| 8 | Verify Fee Details showing month (F Y), amount (₹), delay badge at lines 187-208 | 3 sub-items |
| 9 | Verify Payment Info showing date (d-M-Y), amount (₹), mode badge at lines 210-226 | 3 sub-items |
| 10 | Verify Status column with conditional badges at lines 228-251: paid (green+check), overdue (red+exclamation), pending (yellow+clock) | 3 states + reconciled badge |
| 11 | Verify Empty state at lines 261-270: file-invoice-dollar icon, "No fee collection records found", "Try adjusting your filters" | Empty state |
| 12 | Verify Pagination at line 280: `$feeCollectionList->withQueryString()->links()` | Pagination links |
| 13 | Verify variable name: view uses `$feeCollectionList` (from StudentRouteFeesController) | Tab context |
| 14 | **CRITICAL**: Standalone FeeCollectionController@index passes `$data` (line 35) — view expects `$feeCollectionList` | **Variable mismatch** — standalone index will have undefined variable |

### TC-CR-37: trashed() Returns Non-existent View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trashed()` method line 312-320 | `return view('transport::fee-collection.trash', compact('data'))` |
| 2 | Check if file exists: `ls Modules/Transport/resources/views/fee-collection/trash.blade.php` | **File does NOT exist** |
| 3 | List existing files in fee-collection directory: index.blade.php, create.blade.php, show.blade.php, edit.blade.php | Only 4 files — NO trash.blade.php |
| 4 | Compare with other entities: FeeMaster has trash.blade.php, FineCategory has trash.blade.php, FineMaster has trash.blade.php | **Missing view** compared to peers |
| 5 | **Impact**: If route for trashed() were registered, accessing it would throw `InvalidArgumentException: View [transport::fee-collection.trash] not found` | ViewNotFoundException |
| 6 | **Combined gap**: No route + no view + dead controller code | 3 layers of missing implementation |

### TC-CR-24: DDL — No updated_at Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect migration for `tpt_student_fee_collection` | Check DDL schema |
| 2 | Search for `updated_at` in DDL | **NOT found** |
| 3 | Model extends `BaseModel` — check if BaseModel has `public $timestamps = false` | Likely (many transport models disable timestamps) |
| 4 | Create a fee collection and then update it | Record created and updated |
| 5 | DB check: `SELECT * FROM tpt_student_fee_collection` | `created_at` populated, `updated_at` does NOT exist |
| 6 | **Impact**: No way to know when a collection was last modified | Only created_at available for audit |

### TC-CR-38: Standalone vs Tab Filter Inconsistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FeeCollectionController@index()` lines 28-36 | No `when()` or filter logic |
| 2 | Open `StudentRouteFeesController@feeCollectionData()` lines 201-217 | 3 `when()` filter clauses |
| 3 | Verify standalone index blade expects `$data` — but tab blade expects `$feeCollectionList` | Two different variable names for the same data |
| 4 | Verify standalone index view `transport::fee-collection.index` vs tab include `@include('transport::fee-collection.index')` | Same blade file used in both contexts |
| 5 | Blade line 280: `$feeCollectionList->withQueryString()->links()` | Tab passes `$feeCollectionList` ✓ |
| 6 | Standalone controller line 35: `compact('data')` → `$data` | Standalone passes `$data` — blade expects `$feeCollectionList` → **undefined variable** |
| 7 | **BUG**: Standalone index will have undefined `$feeCollectionList` and will error | Variable name mismatch between tab and standalone contexts |

---

### TC-P-11: Export Fee Collections (with filters)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with user having `tenant.fee-collection.viewAny` permission | Authenticated |
| 2 | Navigate to tab `/std-route-Fees-mgmt?tab=fee_collection` | Page loads |
| 3 | Select Academic Session = some session | Filter set |
| 4 | Select Payment Status = "paid" | Filter set |
| 5 | Click "Filter" first to apply filters | Table shows filtered results |
| 6 | Access export URL: GET `/fee-collection/allocation/export?std_academic_sessions_id=X&status=paid` | Export endpoint |
| 7 | Verify Gate: Controller line 302 `Gate::authorize('tenant.fee-collection.viewAny')` | Authorized |
| 8 | Verify `new FeeCollectionExport($request->all())` | Export class instantiated with all request params (including std_academic_sessions_id, status) |
| 9 | Verify filename: `fee_collection_2026-07-22.xlsx` | `now()->format('Y-m-d')` |
| 10 | Verify response headers: `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` | Excel download |
| 11 | Verify downloaded file contains only filtered records (status=paid) | Export respects filters |
| 12 | Open downloaded .xlsx file | Columns match the export class definition |

### TC-P-12: Export Fee Collections (all data)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access GET `/fee-collection/allocation/export` with NO query params | Export endpoint |
| 2 | Verify `FeeCollectionExport()` receives empty `$request->all()` array | No filters |
| 3 | Verify all records exported | Complete dataset in .xlsx |
| 4 | Verify Content-Disposition header: `attachment; filename="fee_collection_2026-07-22.xlsx"` | Download triggered |

### TC-P-13: Filter Fee Collections By Academic Session (Tab)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to tab with fee collection data | Multiple records visible |
| 2 | Select Academic Session from filter dropdown | Choose a specific session |
| 3 | Click "Filter" | GET request with `std_academic_sessions_id=X` |
| 4 | Verify `StudentRouteFeesController@feeCollectionData()` line 204-207: `when(filled('academic_sessions_id'), fn → whereHas('feeMaster', fn → where('academic_sessions_id', X)))` | Subquery filters fee master records |
| 5 | Verify table only shows collections for fee masters in the selected academic session | Filtered results |
| 6 | Verify summary cards also reflect filtered data (total_due, total_collected recalculated) | Cards match filtered view |
| 7 | Verify pagination links include `?std_academic_sessions_id=X&tab=fee_collection` | Query string preserved |

### TC-P-14: Filter Fee Collections By Month (Tab)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Month = 3 (March) from filter dropdown | Month selected |
| 2 | Click "Filter" | GET with `month=3` |
| 3 | Verify feeCollectionData() line 212-215: `when(filled('month'), fn → whereHas('feeMaster', fn → where('month', 3)))` | Subquery filters by month |
| 4 | Verify only March collections shown | Table filtered |
| 5 | Verify month dropdown options: `range(1,12)` with `date('F', mktime(0,0,0,$m,1))` | January through December |

### TC-P-15: Filter Fee Collections By Payment Status (Tab)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Payment Status = "paid" | Status dropdown set |
| 2 | Click "Filter" | GET with `status=paid` |
| 3 | Verify feeCollectionData() line 209-211: `when(filled('status'), fn → where('status', 'paid'))` | Direct where clause |
| 4 | Verify only status='paid' collections shown | Table filtered |
| 5 | Verify status dropdown options: paid, pending, overdue (from blade) | 3 options matching model constants |
| 6 | Verify Quick Stats badges update: Paid count = total shown | Badges reflect filtered stats |

### TC-P-36: Create Fee Collection From FeeMaster Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/std-route-Fees-mgmt?tab=fee_creation` | Fee Master list |
| 2 | Locate a fee master with Pending or Partial status | Record has id=X |
| 3 | Click "Add Collection" action button on that row | Navigate to `/fee-collection/create?fee_master_id=X&source=fee_tab` |
| 4 | Verify `create()` controller line 46: `$feeIds = $request->fee_master_id` | Pre-population set |
| 5 | Verify hidden field in form: `<input type="hidden" name="ids" value="X">` (create.blade.php line 44) | IDs pre-filled |
| 6 | Verify no need to select fee master separately | Hidden field handles association |
| 7 | Fill payment_date, paid_amount, payment_mode, status | Required fields |
| 8 | Submit form | POST to store |
| 9 | Verify store() line 66: `TptFeeMaster::findOrFail($request->ids)` → finds FeeMaster X | Correct fee master linked |

### TC-P-20: Create Fee Collection — With Remarks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Enter all required fields | Valid data |
| 3 | Enter remarks = "First installment payment for March 2026" | Text entered |
| 4 | Click "Save Fee Collection" | POST to store |
| 5 | DB check: `remarks` = "First installment payment for March 2026" | Stored verbatim |
| 6 | Navigate to show page | Show page renders |
| 7 | Verify remarks displayed at show.blade.php line 131: `{{ $record->remarks ?? '-' }}` | "First installment payment for March 2026" |

### TC-P-21: Create Fee Collection — Reconciled Checked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Fill all required fields | Valid data |
| 3 | Toggle "Reconciled?" switch to ON | `reconciled` checkbox checked (value=1) |
| 4 | Submit form | POST to store |
| 5 | Verify `FeeCollectionRequest::prepareForValidation()` line 66: `$this->has('reconciled') ? 1 : 0` | reconciled = 1 |
| 6 | Verify controller line 132: `'reconciled' => $request->reconciled ?? 0` | reconciled = 1 |
| 7 | DB check: `reconciled` = 1 (TINYINT) | Model `casts` → boolean true |
| 8 | Navigate to show page | Show page renders |
| 9 | Verify show.blade.php line 120: `@if($record->reconciled) <span class="badge bg-info">Yes</span>` | "Yes" badge shown |

### TC-P-26: Pagination on Tab (Page 2)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure more than 10 fee collection records exist | At least 11 records |
| 2 | Navigate to `/std-route-Fees-mgmt?tab=fee_collection` | Page 1 with 10 records |
| 3 | Verify paginator shows page 1 of N | `$feeCollectionList->links()` |
| 4 | Click page 2 link | GET `/std-route-Fees-mgmt?tab=fee_collection&page=2` |
| 5 | Verify `feeCollectionData()` uses `->paginate(10)->withQueryString()` | Page 2, 10 per page |
| 6 | Verify # column continues numbering: `$feeCollectionList->firstItem() + $key` | Item 11, 12, ... |
| 7 | Verify filters preserved in pagination links | `withQueryString()` includes all params |

### TC-P-27: Activity Log Created on Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a fee collection via store() | Success |
| 2 | Verify controller line 183-185 executes: `activityLog($feeCollection, 'Created', ['message' => 'Fee collected successfully'])` | Log function called |
| 3 | Check activity_log table (or equivalent transport_activity_log) for entry | Entry with subject_type=TptStudentFeeCollection, subject_id=feeCollection->id, event='Created' |
| 4 | Verify properties contain: `{"message":"Fee collected successfully"}` | Attributes stored in log |

### TC-P-28: Activity Log Updated on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update a fee collection via PUT | Success |
| 2 | Verify controller line 239-241: `activityLog($feeCollection, 'Updated', ['message' => 'Fee collection updated successfully'])` | Log function called |
| 3 | Check activity_log: event='Updated' | Correct event type |
| 4 | Verify properties: `{"message":"Fee collection updated successfully"}` | Attributes match |

### TC-P-29: Activity Log Deleted on Destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a fee collection via DELETE | Success |
| 2 | Verify controller line 288-290: `activityLog($feeCollection, 'Deleted', ['message' => 'Fee collection deleted'])` | Log function called |
| 3 | Check activity_log: event='Deleted' | Correct event type |
| 4 | Verify properties: `{"message":"Fee collection deleted"}` | Attributes match |

### TC-P-31: StudentPayLog Created on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update fee collection (id=X) | PUT success |
| 2 | DB query: `SELECT * FROM std_student_pay_log WHERE reference_id=X AND activity_type='fee_collected_update'` | Entry exists |
| 3 | Verify `activity_type='fee_collected_update'` | Correct type |
| 4 | Verify `description='Transport fee collected update'` | Description text |
| 5 | Verify `amount = $feeCollection->paid_amount` | Amount matches updated value |
| 6 | Verify `triggered_by = auth()->id()` | Current user |

### TC-P-03: Partial Payment Creates Partial FeeMaster Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure FeeMaster with amount=1000, due_date=2026-07-15, status='Pending' | Ready for collection |
| 2 | Create collection: paid_amount=400, payment_date=2026-07-10 (on time), status='paid' | POST to store |
| 3 | Verify `delayDays` = 0 (payment_date <= due_date) | On time, no delay |
| 4 | Verify fee collection created with paid_amount=400 | Record exists |
| 5 | Verify `refreshFeeMasterStatus(FM1)`: `$collected=400`, `$due=1*1000=1000`, `400>0 && 400<1000` → status='Partial' | FM status = Partial |
| 6 | Navigate to tab, verify FeeMaster shows "Partial" status | Visual confirmation |
| 7 | Verify index shows the collection with "Paid" status badge (green) | Per-collection status correct |
| 8 | Verify summary cards: Total Collected includes 400 | Sum updated |

### TC-N-15: Permission 403 — No Fee Collection Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with NO `tenant.fee-collection.*` permissions | Authenticated |
| 2 | Navigate to `/std-route-Fees-mgmt?tab=fee_collection` | Tab container loads but fee_collection-pane hidden (blade `@can`) |
| 3 | Direct access to `/fee-collection/create` | `Gate::authorize('tenant.fee-collection.create')` → **403** |
| 4 | POST to `/fee-collection` with valid data | `FeeCollectionRequest::authorize()` → **403** |
| 5 | GET `/fee-collection/1` | `Gate::authorize('tenant.fee-collection.view')` → **403** |
| 6 | GET `/fee-collection/1/edit` | `Gate::authorize('tenant.fee-collection.update')` → **403** |
| 7 | PUT `/fee-collection/1` with valid data | `FeeCollectionRequest::authorize()` → **403** |
| 8 | DELETE `/fee-collection/1` | `Gate::authorize('tenant.fee-collection.delete')` → **403** |
| 9 | GET `/fee-collection/allocation/export` | `Gate::authorize('tenant.fee-collection.viewAny')` → **403** |
| 10 | Verify all endpoints return 403, not 404 or redirect | Consistent permission denial |
| 11 | Verify action column in tab (if somehow visible) is hidden for users without edit/delete | `@canany` guards |

### TC-N-16: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (not authenticated) | Guest session |
| 2 | Navigate to `/fee-collection` | Redirect to `/login` |
| 3 | Navigate to `/fee-collection/create` | Redirect to `/login` |
| 4 | POST to `/fee-collection` | Redirect to `/login` |
| 5 | Navigate to `/fee-collection/1` | Redirect to `/login` |
| 6 | Navigate to `/fee-collection/1/edit` | Redirect to `/login` |
| 7 | PUT to `/fee-collection/1` | Redirect to `/login` |
| 8 | DELETE `/fee-collection/1` | Redirect to `/login` |
| 9 | GET `/fee-collection/allocation/export` | Redirect to `/login` |
| 10 | Verify all routes protected by `auth` middleware | Consistent redirect |

### TC-N-19: paid_amount = 0 Boundary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Enter paid_amount = 0 | Value 0 |
| 3 | Fill all other required fields | Valid |
| 4 | Submit form | POST to store |
| 5 | Verify `FeeCollectionRequest` rules: `paid_amount` has `min:0` | Validation passes (0 >= 0) |
| 6 | Verify collection created with `paid_amount=0.00` | Zero-value collection |
| 7 | Verify `refreshFeeMasterStatus()`: `$collected=0`, `$due>0`, `$collected=0` → status = 'Pending' | Status unchanged |
| 8 | Verify StudentPayLog created with `amount=0` | Zero-amount pay log |
| 9 | **Note**: Zero-value collection is functionally useless but technically valid | Business logic should prevent this |

### TC-D-09: Store in DB Transaction Rollback on Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to store() method line 58-191 | Wrapped in `DB::transaction(function () use ($request) {` |
| 2 | Simulate exception at line 145 (StudentPayLog::create) — e.g., make student_id reference fail | Exception thrown inside transaction |
| 3 | Verify `DB::transaction()` auto-rolls back on exception | All changes reverted |
| 4 | DB check: `tpt_student_fee_collection` should have NO new records | Rolled back |
| 5 | DB check: `tpt_student_fine_detail` should have NO new records | Rolled back |
| 6 | Verify FeeMaster.status unchanged | Rolled back |
| 7 | Verify no StudentPayLog entry created | Rolled back |
| 8 | Verify no Accounting event sent | processEvent never reached |
| 9 | Verify no ActivityLog entry created | Rolled back |
| 10 | User sees error page (Laravel debug) or 500 error | Exception propagated |

### TC-D-17: total_delay_days NOT Recalculated on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create collection: due_date=2026-01-10, payment_date=2026-01-15 | delayDays = 5 |
| 2 | DB check: `total_delay_days` = 5 | Initial value correct |
| 3 | Update payment_date to 2026-01-20 (different delay) | PUT request |
| 4 | Verify controller update() lines 230-237: `$feeCollection->update([...])` | Update array has payment_date but NOT total_delay_days |
| 5 | DB check: `payment_date` = 2026-01-20 (updated) | Date changed |
| 6 | DB check: `total_delay_days` = **5** (NOT recalculated) | **Stale value** — should be 10 |
| 7 | **BUG**: delay days are frozen at original calculation | Data integrity issue |

### TC-CR-01: Blade @can Directives — Tab Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `stdroutefeesmgmt.blade.php` | Tab container view |
| 2 | Search for `@can('tenant.fee-collection.viewAny')` | Directive wrapping the fee-collection include |
| 3 | Verify the include statement: `@include('transport::fee-collection.index')` is inside the @can block | Tab conditional |
| 4 | Login as user with `tenant.fee-collection.viewAny` | Tab visible |
| 5 | Navigate to `/std-route-Fees-mgmt?tab=fee_collection` | fee_collection-pane renders |
| 6 | Login as user WITHOUT `tenant.fee-collection.viewAny` | Tab hidden |
| 7 | Verify the tab button for "Fee Collection" is NOT rendered in the tab navigation | Cannot navigate to hidden tab |
| 8 | Try direct URL `/std-route-Fees-mgmt?tab=fee_collection` without permission | Tab content not rendered (empty pane) |

### TC-CR-04: Controller — activityLog Created After Every CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `FeeCollectionController.php` for `activityLog(` | Count occurrences |
| 2 | Line 183-185: `activityLog($feeCollection, 'Created', ...)` in store() | 1 occurrence |
| 3 | Line 239-241: `activityLog($feeCollection, 'Updated', ...)` in update() | 1 occurrence |
| 4 | Line 288-290: `activityLog($feeCollection, 'Deleted', ...)` in destroy() | 1 occurrence |
| 5 | Line 331-333: `activityLog($feeCollection, 'Restored', ...)` in restore() | 1 occurrence (unreachable) |
| 6 | Line 349-351: `activityLog($feeCollection, 'Force Deleted', ...)` in forceDelete() | 1 occurrence (unreachable) |
| 7 | Total: 5 activityLog calls in controller | All CRUD methods covered (but 2 unreachable) |
| 8 | Verify `export()` has NO activityLog | Export is read-only — correct |
| 9 | Compare with controllers that lack activityLog (e.g., PickupPointRouteController has NONE) | **FeeCollection is correctly instrumented** |

### TC-CR-05: Controller — StudentPayLog on Create/Update/Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `FeeCollectionController.php` for `StudentPayLog::create(` | Count occurrences |
| 2 | Line 144-154: StudentPayLog for store (activity_type: fee_collected_create) | 1 occurrence |
| 3 | Line 246-256: StudentPayLog for update (activity_type: fee_collected_update) | 1 occurrence |
| 4 | Line 276-286: StudentPayLog for destroy (activity_type: fee_collected_delete) | 1 occurrence |
| 5 | Total: 3 StudentPayLog::create calls | All CUD operations tracked |
| 6 | Verify `export()`, `trashed()`, `restore()`, `forceDelete()` have NO StudentPayLog | Correct — no financial tracking for these |
| 7 | Verify each StudentPayLog entry has: student_id, academic_session_id, module_name='Transport', reference_id, reference_table='tpt_student_fee_collection', amount, triggered_by | All 7 fields present |

### TC-CR-07: Controller — Fine Calculation Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() lines 78-120 | Fine handling block |
| 2 | Verify line 80: `$request->filled('fine_master_id')` — guard clause | Only enters if fine_master_id provided |
| 3 | Verify line 82: `TptFineMaster::find($request->fine_master_id)` — uses `find()` not `findOrFail()` | Silent null on invalid ID |
| 4 | Verify line 84-86: range check `$delayDays >= $fine_from_days && $delayDays <= $fine_to_days` | Fine amount only calculated within range |
| 5 | Verify line 88-89: Fixed type → `$fineAmount = $fineMaster->fine_rate` | Fixed calculation |
| 6 | Verify line 92-93: Percentage type → `$fineAmount = ($feeMaster->amount * $fineMaster->fine_rate) / 100` | Percentage calculation |
| 7 | Verify line 97-104: Student restriction block — guarded by `isset($fineMaster)` | Null-safe check |
| 8 | Verify line 107-117: `TptStudentFineDetail::create()` — OUTSIDE the range check if-block | Unconditional creation when fine_master_id provided |
| 9 | Verify fine detail fields: student_fee_detail_id, fine_master_id, fine_days, fine_type, fine_rate, fine_amount, waved_fine_amount=0, net_fine_amount, remark | 9 fields mapped |

### TC-CR-13: Request — prepareForValidation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FeeCollectionRequest.php` lines 63-70 | `prepareForValidation()` method |
| 2 | Verify line 66: `'reconciled' => $this->has('reconciled') ? 1 : 0` | Checkbox presence → 1, absence → 0 |
| 3 | Verify line 67: `'payment_mode' => ucfirst(strtolower($this->payment_mode ?? ''))` | Lowercase first, then uppercase first letter |
| 4 | Verify line 68: `'status' => ucfirst(strtolower($this->status ?? ''))` | Same normalization for status |
| 5 | Test: Input `payment_mode = "CASH"` → prepareForValidation: `ucfirst(strtolower("CASH"))` = "Cash" | Normalizes to "Cash" |
| 6 | Test: Input `status = "PAID"` → `ucfirst(strtolower("PAID"))` = "Paid" | Normalizes to "Paid" |
| 7 | Test: Input `reconciled = absent` → `$this->has('reconciled')` = false → 0 | Default 0 |
| 8 | Test: Input `reconciled = present` → `$this->has('reconciled')` = true → 1 | Checkbox checked = 1 |
| 9 | **Note**: Controller strtolower on payment_mode (line 130) undoes the ucfirst normalization | Data flow: prepareForValidation "Cash" → controller "cash" |

### TC-CR-21: View — Show Page Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `show.blade.php` | Full view file (177 lines) |
| 2 | Verify Fee Month row (lines 29-36): `$record->feeMaster->month` formatted as 'F Y' | Month display |
| 3 | Verify Due Date row (lines 39-46): `$record->feeMaster->due_date` formatted as 'd-m-Y' | Due date |
| 4 | Verify Fee Amount row (lines 49-54): `$record->feeMaster->amount` with ₹ and number_format | Amount |
| 5 | Verify Payment Date row (lines 57-62): `$record->payment_date` formatted as 'd-m-Y' | Payment date |
| 6 | Verify Paid Amount row (lines 65-70): `$record->paid_amount` with ₹, bold green text | Amount |
| 7 | Verify Delay Days row (lines 73-84): conditional — if >0 shows red "X Days Late" badge, else green "On Time" | Delay status |
| 8 | Verify Payment Mode row (lines 87-94): `ucfirst($record->payment_mode)` with light badge | Mode display |
| 9 | Verify Status row (lines 97-114): 3 conditional badges: green+check (paid), red+exclamation (overdue), yellow+clock (pending) | Status with icon |
| 10 | Verify Reconciled row (lines 117-126): info badge "Yes" or secondary badge "No" | Reconciled status |
| 11 | Verify Remarks row (lines 129-132): `$record->remarks ?? '-'` | Remarks or fallback |
| 12 | Verify Linked Fee Details section (lines 138-173): Academic Session, Total Fee, Fee Status | Secondary table |
| 13 | Verify Academic Session (lines 148-153): `$record->feeMaster->academicSession->academicSession->name` | 3-level relationship chain |
| 14 | Verify Total Fee (lines 155-160): `$record->feeMaster->total_amount` | Total amount |
| 15 | Verify Fee Status (lines 162-169): `$record->feeMaster->status` with conditional badge color | Fee master status |
| 16 | Verify "Back" button links to `route('transport.std-route-Fees-mgmt.index')` (line 14) | Back to tab |
| 17 | Verify "Edit" button links to `route('transport.fee-collection.edit', $record->id)` (line 18) | Edit action |
| 18 | **Note**: No "Delete" button on show page | Delete only from index table action |

### TC-CR-06: Controller — FeeMaster Status Refresh After Store/Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` line 139: `$this->refreshFeeMasterStatus($feeMaster)` | Called after collection creation |
| 2 | Inspect `update()` line 259: `$this->refreshFeeMasterStatus($feeCollection->feeMaster)` | Called after update |
| 3 | Inspect `destroy()` lines 270-295 | **NOT called** — missing after delete |
| 4 | Inspect `refreshFeeMasterStatus()` lines 358-373 | Method implementation |
| 5 | Verify `$students = $feeMaster->feeCollections()->count()` counts ALL (including soft-deleted? No — SoftDeletes excludes by default) | Correct: excludes deleted collections |
| 6 | Verify `$collected = $feeMaster->feeCollections()->sum('paid_amount')` | Excludes deleted (same query scope) |
| 7 | Verify `$due = $students * $feeMaster->amount` | Due = count × amount |
| 8 | Verify status logic: Completed if `$collected >= $due`, Partial if `$collected > 0`, else Pending | 3 states |

### TC-D-07: Accounting RemoteEntryService Success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure RemoteEntryService is properly configured | Accounting module active |
| 2 | Create fee collection with valid data | POST to store |
| 3 | Verify line 160: `app(RemoteEntryService::class)->processEvent('TRANSPORT', 'TPT_FEE_PAYMENT', $feeCollection->id, [...])` | Called without exception |
| 4 | Verify event data: `student_id`, `amount` (paid_amount), `date` (payment_date), `payment_method` (payment_mode), `reference_no` (feeCollection->id) | All 5 data fields passed |
| 5 | Verify accounting entry created in remote accounting system | Integration confirmed |
| 6 | Verify no error logged | Clean execution |

### TC-D-08: DDL RESTRICT — Cannot Delete FeeMaster With Collections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FeeMaster (id=X) | Fee master created |
| 2 | Create a fee collection referencing fee_master_id=X | Collection links to master |
| 3 | Attempt to DELETE from `tpt_student_fee_detail WHERE id=X` directly via DB | `SQLSTATE[23000]: Integrity constraint violation: 1451 Cannot delete or update a parent row: a foreign key constraint fails` |
| 4 | Verify FK constraint name: `fk_tpt_student_fee_collection_student_fee_detail_id` (or similar) | RESTRICT prevents deletion |
| 5 | First delete the fee collection | Collection removed |
| 6 | Attempt to delete FeeMaster (id=X) again | Deletes successfully (no more referencing rows) |
| 7 | **Impact**: Cannot delete a fee master that has collections — must delete collections first | Data integrity enforced at DB level |

### TC-D-10: Update in DB Transaction Rollback on Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open update() method line 223-265 | Wrapped in `DB::transaction()` |
| 2 | Simulate exception at line 246 (StudentPayLog::create) — e.g., DB write failure | Exception thrown |
| 3 | Verify `DB::transaction()` auto-rolls back | Fee collection update reverted |
| 4 | DB check: fee collection fields unchanged | Original values preserved |
| 5 | DB check: no StudentPayLog created | Rolled back |
| 6 | DB check: FeeMaster.status unchanged | Rolled back |
| 7 | Verify no ActivityLog entry created | Rolled back |

### TC-N-26: Store With Future payment_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Enter payment_date = 2099-01-01 (far future) | Date accepted |
| 3 | Fill all other required fields | Valid data |
| 4 | Submit form | POST to store |
| 5 | Verify `date` validation rule passes | Future dates are valid dates |
| 6 | Verify controller line 68-73: `$paymentDate->gt($dueDate)` → true | delayDays = large number (e.g., 26680 days) |
| 7 | DB check: `total_delay_days` = very large number | Stored as large INT |
| 8 | **Business logic issue**: No validation prevents future payment dates | Invalid business scenario accepted |

### TC-N-23/24: status and payment_mode Accept ANY String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Set status = "Fully Paid" (not in statusOptions) | Custom status |
| 3 | Set payment_mode = "Bitcoin" (not in payment constants) | Custom mode |
| 4 | Fill all other required fields | Valid |
| 5 | Submit form via DevTools (bypass dropdown options) | POST to store |
| 6 | Verify `FeeCollectionRequest` rules: NO `Rule::in()` for either field | Both pass validation |
| 7 | Verify prepareForValidation: `ucfirst(strtolower("Fully Paid"))` = "Fully paid" | Normalized but not rejected |
| 8 | Verify prepareForValidation: `ucfirst(strtolower("Bitcoin"))` = "Bitcoin" | Not rejected |
| 9 | DB check: `status` = "Fully paid" | Any string accepted |
| 10 | DB check: `payment_mode` = "bitcoin" (strtolower by controller) | Any string accepted |
| 11 | View check: blade `@if($row->status == 'paid')` → false for "Fully paid" | Falls to `@else` (shows "Pending" badge — misleading) |
| 12 | **Business logic issue**: Arbitrary strings cause display issues | UI shows incorrect status badge |

### TC-CR-02: Blade — Action Column Guards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index.blade.php` lines 164-166 and 253-260 | `@canany(['tenant.fee-collection.edit', 'tenant.fee-collection.delete'])` |
| 2 | Login as user with `edit` permission only (no delete) | Partial permissions |
| 3 | Navigate to tab | Action column visible (edit icon shown, delete icon hidden by component) |
| 4 | Login as user with `delete` permission only (no edit) | Action column visible (delete icon shown, edit hidden) |
| 5 | Login as user with neither edit nor delete | Action column hidden entirely |
| 6 | Verify `<x-backend.table.action>` component handles individual permission checks | Component renders correct buttons based on permissions |
| 7 | **Note**: `edit` permission in blade uses `@canany` with `tenant.fee-collection.edit` but policy has NO `edit()` method — only `update()` | `@canany` works via raw permission check in Gate, not policy method |

### TC-CR-14: Request — No Rule::in for status/payment_mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FeeCollectionRequest.php` lines 39-45 | `payment_mode` rule: only `['required']`. `status` rule: only `['required']` |
| 2 | Compare with model constants: STATUS_PAID, STATUS_PENDING, STATUS_OVERDUE, PAYMENT_CASH, PAYMENT_ONLINE, PAYMENT_CHEQUE | Constants defined but NOT used in validation |
| 3 | Compare with blade dropdown options: payment_mode = Cash/Online/Cheque, status = paid/pending/overdue | UI restricts but server does NOT enforce |
| 4 | **SECURITY FINDING**: Any arbitrary string can be injected via API/direct POST | Server-side validation gap |
| 5 | **Impact**: status "cancelled" would display incorrectly in UI (falls to @else = "Pending" badge) | UI displays wrong status |

### TC-CR-09: Controller — OnlyTrashed for Restore/ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `restore()` line 328: `TptStudentFeeCollection::onlyTrashed()->findOrFail($id)` | Correct — only finds soft-deleted |
| 2 | Open `forceDelete()` line 346: `TptStudentFeeCollection::onlyTrashed()->findOrFail($id)` | Correct — only finds soft-deleted |
| 3 | Create a fee collection (active, not deleted) | id=X, deleted_at=NULL |
| 4 | Attempt to restore(id=X) without soft-deleting first | `onlyTrashed()` → WHERE deleted_at IS NOT NULL → not found → **404** |
| 5 | Soft-delete the collection first | deleted_at=timestamp |
| 6 | Now restore(id=X) works | `onlyTrashed()` finds it → restore succeeds |
| 7 | Force delete without soft-delete → 404 | Must soft-delete first |
| 8 | **Note**: This is correct behavior — prevents restoring/force-deleting active records accidentally | Proper guard |

### TC-D-12: StrToLower on payment_mode in Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with payment_mode="Cash" | Form submitted |
| 2 | Trace: Request prepareForValidation line 67: `ucfirst(strtolower("Cash"))` = "Cash" | Normalized by request |
| 3 | Trace: Controller store line 130: `'payment_mode' => strtolower($request->payment_mode)` = `strtolower("Cash")` = "cash" | Lowercased by controller |
| 4 | DB select: `SELECT payment_mode FROM tpt_student_fee_collection WHERE id=X` | "cash" |
| 5 | POST with payment_mode="ONLINE" | Next test |
| 6 | Trace: prepareForValidation: `ucfirst(strtolower("ONLINE"))` = "Online" | Normalized |
| 7 | Trace: Controller: `strtolower("Online")` = "online" | Lowercased |
| 8 | DB: "online" | Consistent lowercase |
| 9 | All payment modes stored lowercase — display uses `ucfirst()` | Display shows "Cash", "Online", "Cheque" |

### TC-D-13: Status Stored as ucfirst

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST with status="paid" | Form submitted |
| 2 | Trace: Request prepareForValidation line 68: `ucfirst(strtolower("paid"))` = "Paid" | Normalized |
| 3 | Trace: Controller store line 131: `'status' => $request->status` = "Paid" (no strtolower) | Stored as-is |
| 4 | DB select: `SELECT status FROM tpt_student_fee_collection WHERE id=X` | "Paid" |
| 5 | POST with status="OVERDUE" | Next test |
| 6 | Trace: prepareForValidation: `ucfirst(strtolower("OVERDUE"))` = "Overdue" | Normalized |
| 7 | DB: "Overdue" | Stored ucfirst |
| 8 | Compare with blade checks: `@if($row->status == 'paid')` | **MISMATCH**: blade checks lowercase "paid" but DB stores "Paid" (ucfirst). The `@if` condition in show.blade.php:100 checks `$record->status === 'paid'` (lowercase) — **WILL NOT MATCH** for status "Paid" |
| 9 | **BUG in show.blade.php**: Line 100 `@if($record->status === 'paid')` — status in DB is "Paid" (ucfirst). This condition is NEVER true. | Falls to `@elseif($record->status === 'overdue')` → false, then `@else` → shows "Pending" badge for ALL statuses |
| 10 | **Severity**: Show page status badge always shows "Pending" regardless of actual status | **UI BUG** — status display broken on show page |

### TC-D-13b: Index Blade Status Check Case Sensitivity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index.blade.php` line 230 | `@if($row->status == 'paid')` |
| 2 | Compare with DB value: "Paid" (ucfirst from prepareForValidation) | PHP `==` is case-sensitive → "Paid" != "paid" |
| 3 | Index blade line 230: `@if($row->status == 'paid')` → FALSE for "Paid" | Falls to `@elseif($row->status == 'overdue')` → FALSE for "Overdue" |
| 4 | Falls to `@else` → shows "Pending" badge with clock icon | **ALL statuses show "Pending"** |
| 5 | **Same BUG in index.blade.php as show.blade.php** | Status badge display broken in BOTH views |
| 6 | Quick Stats badges line 137-149: `$feeCollectionList->where('status', 'paid')->count()` | **Same bug** — Collection's `where()` is case-sensitive. "Paid" != "paid" → count = 0 |
| 7 | Quick Stats always shows Paid=0, Pending=total, Overdue=0 | Stats badges wrong |
| 8 | **CRITICAL BUG**: prepareForValidation stores ucfirst but ALL blade checks use lowercase | System-wide status display bug |

### TC-D-01: Create Fee Collection — FeeMaster Status Partial→Completed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure FeeMaster FM1: amount=500, no existing collections | Initial status='Pending' |
| 2 | Create Collection C1: paid_amount=300 | POST to store |
| 3 | Verify `refreshFeeMasterStatus(FM1)`: `$collected=300`, `$students=1`, `$due=1*500=500` | Status='Partial' (300>0 && 300<500) |
| 4 | Create Collection C2: paid_amount=200 | Second collection |
| 5 | Verify `refreshFeeMasterStatus(FM1)`: `$collected=500`, `$students=2`, `$due=2*500=1000` | Status='Partial' (500<1000) |
| 6 | **BUG**: FeeMaster never reaches 'Completed' because $due grows with each collection | Fundamental formula error in refreshFeeMasterStatus |

### TC-CR-32: Controller — edit() Does NOT Pass fineSelect to View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `edit()` lines 207-218 | Method body |
| 2 | List variables passed to view: `feeCollection`, `studentAllocation`, `feeMatser` | 3 variables |
| 3 | Compare with `create()` line 48: `$fineSelect = TptFineMaster::get()` and line 52: `compact(..., 'fineSelect')` | create() passes fineSelect, edit() does NOT |
| 4 | Open `edit.blade.php` | Search for fine master dropdown or fineSelect |
| 5 | **No fine master field in edit form** | User cannot change fine association during edit |
| 6 | Compare with `create.blade.php` line 64-76: Fine Type dropdown present | Create has fine, edit does not |

### TC-CR-08: Controller — DB Transaction for store() and update() but NOT destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` line 61: `DB::transaction(function () use ($request) {` | Transaction wrapper present |
| 2 | Open `update()` line 228: `DB::transaction(function () use ($request, $feeCollection) {` | Transaction wrapper present |
| 3 | Open `destroy()` lines 270-295 | **NO** `DB::transaction()` wrapper |
| 4 | Open `restore()` line 325-338 | **NO** `DB::transaction()` wrapper |
| 5 | Open `forceDelete()` line 343-356 | **NO** `DB::transaction()` wrapper |
| 6 | **Inconsistency**: Only store() and update() are transactional | destroy/restore/forceDelete are not atomic |
| 7 | Impact: If activityLog fails after destroy() delete, collection is deleted without audit trail | Partial state possible |

### TC-CR-17: Model — Casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptStudentFeeCollection.php` lines 53-56 | `$casts` array |
| 2 | `'reconciled' => 'boolean'` | Integer 0/1 → boolean true/false |
| 3 | `'payment_date' => 'date'` | String → Carbon instance |
| 4 | Test: Fetch collection from DB → `$collection->reconciled` = true/false (boolean) | Cast works |
| 5 | Test: `$collection->payment_date` = Carbon instance | Carbon methods available |
| 6 | Test: Blade `$feeCollection->reconciled ? 'checked' : ''` (edit.blade.php line 131) | boolean works in ternary |

### TC-CR-34: Variable Typo `feeMatser`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller line 45: `$feeMatser = TptFeeMaster::get()` | Variable name `$feeMatser` (missing 't') |
| 2 | Open controller line 212: `$feeMatser = TptFeeMaster::get()` | Same typo in edit() |
| 3 | Open controller line 51: `compact('studentAllocation', 'feeMatser','feeIds','fineSelect')` | Typo propagated to view |
| 4 | Open `create.blade.php` | Search for `$feeMatser` usage in blade |
| 5 | Verify no blade code actually uses `$feeMatser` | Typo has no runtime impact (loaded but unused in view) |
| 6 | **Impact**: None — variable loaded but never referenced in blade | Dead code / code smell |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: FeeCollection | Date: 2026-07-21*
