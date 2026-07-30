# tpt_FineDetail_TcList

## Module: Transport → Student Route Fees Management → Fine Detail

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Student Route Fees Management |
| Feature | Fine Detail |
| URL(s) | `/std-route-Fees-mgmt` (index via tab), `/fine-detail` (standalone index — standalone route exists but `fineMasterRule` relationship gap may crash), `/fine-detail/create` (create — view directory does NOT exist), `/fine-detail` (store — empty method, no-op), `/fine-detail/{id}` (show), `/fine-detail/{id}/edit` (edit), `/fine-detail/{id}` (update PUT), `/fine-detail/{id}` (destroy DELETE), `/fine-detail-trashed` (trashed GET), `/fine-detail/{id}/restore` (restore GET), `/fine-detail/{id}/force-delete` (forceDelete DELETE), `/student-pay-log/{id}` (destroyData DELETE) |
| Controller | `Modules\Transport\Http\Controllers\TptStudentFineDetailController` — 12 methods: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, destroyData |
| Tab Container Controller | `Modules\Transport\Http\Controllers\StudentRouteFeesController@index()` — `fineDetailsQuery()` provides data |
| Model | `Modules\Transport\Models\TptStudentFineDetail` — table: `tpt_student_fine_detail`, 86 lines, 5 relationships ($feeMaster, $feeDetail, $fineMaster, $fineCollection) |
| Validation | No dedicated Form Request — uses `Illuminate\Http\Request` directly with inline validation in controller; NO validation rules in update() |
| Permissions | 17 CRUD permissions from `$crud` + 4 defined in policy only (waive, apply, viewReports, bulkApply) — NOT in `permissionslist.php`. Policy also defines `status()` gate method. Controller uses: viewAny, view, create, update, delete, restore, forceDelete (7 distinct gates). Blade uses: viewAny, status, edit, delete, view, forceDelete, restore. |
| Soft Deletes | Yes (`TptStudentFineDetail` uses `SoftDeletes` trait line 11) |
| Activity Log | Events: `Updated` (update with DB::transaction), `Trashed` (destroy), `Restored` (restore), `Force Deleted` (forceDelete) — 4 state-change events logged via `activityLog()` |
| StudentPayLog | Additional audit: `fine_deatils_updated` (update, note typo), `fine_details_deleted` (destroy), `fine_master_restored` (restore — copy-paste bug, should be fine_detail), `fine_master_deleted` (forceDelete) |
| DB Table | `tpt_student_fine_detail` — 13 columns, 2 RESTRICT FKs |
| Controller Controller | `StudentRouteFeesController@index()` at `/std-route-Fees-mgmt` — uses `include('transport::fine-details.index')` with `$fineDetails` from `fineDetailsQuery()` |

---

## 2. Pre-conditions

| # | Pre-condition | Source |
|---|--------------|--------|
| PC-01 | Required permissions: `tenant.fine-detail.viewAny`, `tenant.fine-detail.view`, `tenant.fine-detail.create`, `tenant.fine-detail.update`, `tenant.fine-detail.edit`, `tenant.fine-detail.delete`, `tenant.fine-detail.restore`, `tenant.fine-detail.forceDelete` | Policy-based |
| PC-02 | Required seed data: At least one `TptFeeMaster` (tpt_student_fee_detail) record | FK `student_fee_detail_id` |
| PC-03 | Required seed data: At least one `TptFineMaster` (tpt_fine_master) record | FK `fine_master_id` |
| PC-04 | Test user must have all above permissions (default admin user) | Dusk authentication |
| PC-05 | Tenant context must be initialized via `tenancy()->initialize()` | Multi-tenant architecture |
| PC-06 | Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD` | Test bootstrap |
| PC-07 | The Fine Detail tab is loaded as part of StudentRouteFeesMgmt — URL `/std-route-Fees-mgmt?tab=fine_detail` loads `StudentRouteFeesController@index` | Blade tab system |
| PC-08 | `OrganizationAcademicSession` data required for filter dropdown | `index` view |
| PC-09 | `FeeCollectionController@store()` must be the primary creation pathway — standalone `store()` is empty | Controller |
| PC-10 | `fineMasterRule()` relationship does NOT exist on model — controller `index()` uses it but will fail | Model at `TptStudentFineDetail.php:44-85` |

---

## 3. Default Data Load

When the page loads via `StudentRouteFeesController@index()` (GET `/std-route-Fees-mgmt`):

| # | Data Load Rule | Details | Source |
|---|----------------|---------|--------|
| DL-01 | Fine Details Grid | `StudentRouteFeesController@fineDetailsQuery()` — `TptStudentFineDetail::with(['feeMaster', 'fineMaster'])` with 3 filters: `std_academic_sessions_id` (via feeMaster), `month` (via feeMaster), `fine_type` (direct) | `StudentRouteFeesController.php:134-157` |
| DL-02 | Pagination | 10/page via `->paginate(10)->withQueryString()` | `StudentRouteFeesController.php:80-81` |
| DL-03 | Fine Detail Tab Partial | view: `transport::fine-details.index` — Included via `@include('transport::fine-details.index')` in `stdroutefeesmgmt.blade.php:44` | Blade tab `fine_detail-pane` |
| DL-04 | Organization Academic Sessions | `OrganizationAcademicSession::get()` — all org academic sessions | `StudentRouteFeesController.php:83` |
| DL-05 | Standalone index() | `TptStudentFineDetailController::with(['feeMaster', 'fineMasterRule'])` — uses `->latest()->paginate(20)` | `TptStudentFineDetailController.php:26-28` |
| DL-06 | **GAP**: Standalone index uses `fineMasterRule` which is NOT a valid relationship on model | `with(['feeMaster', 'fineMasterRule'])` — only `fineMaster()` exists on model | `TptStudentFineDetailController.php:26` vs `TptStudentFineDetail.php:67-73` |

Note: Fine details are typically auto-created during Fee Collection creation (in `FeeCollectionController@store()`). The standalone `TptStudentFineDetailController@store()` method is empty (`return void`). The `create()` view directory `transport::fine-detail.create` does not exist in filesystem.

---

## 4. Test Data Strategy

| # | Data Strategy | Details | Source |
|---|---------------|---------|--------|
| TD-01 | **Unique suffix**: Use `now()->format('YmdHis') . random_int(100, 999)` for test data uniqueness | Prevents collision in parallel runs |
| TD-02 | **student_fee_detail_id**: Must reference existing `tpt_student_fee_detail` record (TptFeeMaster) | FK RESTRICT |
| TD-03 | **fine_master_id**: Must reference existing `tpt_fine_master` record (TptFineMaster) | FK RESTRICT |
| TD-04 | **fine_days**: TINYINT, typically calculated as delay days between payment_date and due_date | DDL |
| TD-05 | **fine_type**: ENUM in DDL: 'Fixed' or 'Percentage'. Default 'Fixed' | DDL `ENUM('Fixed','Percentage')` |
| TD-06 | **fine_rate**: DECIMAL(5,2), rate for fine calculation | DDL |
| TD-07 | **fine_amount**: DECIMAL(10,2), calculated fine amount | DDL |
| TD-08 | **waved_fine_amount**: DECIMAL(10,2), DEFAULT 0.00 — amount waived | DDL |
| TD-09 | **net_fine_amount**: DECIMAL(10,2), DEFAULT 0.00 — calculated as `fine_amount - waved_fine_amount` | Controller line 107 |
| TD-10 | **remark**: VARCHAR(512), DEFAULT NULL | DDL |
| TD-11 | **Test data creation**: Best created via Fee Collection flow (`FeeCollectionController@store`) which auto-creates fine details, or directly insert into `tpt_student_fine_detail` for testing edit/delete | Controller analysis |
| TD-12 | **Pre-test cleanup**: Delete created fine details before/after tests | Test hygiene |
| TD-13 | **Soft delete behavior**: `destroy()` calls `$fineDetail->delete()` then logs activity; redirects back with flash `trashed.fine_detail` | Controller lines 145-174 |
| TD-14 | **Restore behavior**: `restore()` calls `$fineDetail->restore()`; redirects to `transport.std-route-Fees-mgmt.index` with flash `restored.fine_detail` | Controller lines 197-227 |
| TD-15 | **Force delete**: `forceDelete()` calls `$fineDetail->forceDelete()`; redirects to index with flash `force_deleted.fine_detail` | Controller lines 234-263 |
| TD-16 | **StudentPayLog**: Each CRUD action creates a StudentPayLog record; destroyData DELETES existing log | Controller lines 118-128, 152-162, 207-217, 242-251, 265-276 |
| TD-17 | **Copy-paste bug in restore/forceDelete**: `reference_table: 'tpt_fine_master'` should be `'tpt_student_fine_detail'` | Controller lines 213, 249 |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions — `tpt_student_fine_detail`

| BC ID | Column | Type (DDL) | Constraints | Source |
|-------|--------|------------|-------------|--------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment | DDL |
| BC-DB-02 | student_fee_detail_id | INT UNSIGNED | NOT NULL, FK → `tpt_student_fee_detail.id`, ON DELETE RESTRICT | DDL |
| BC-DB-03 | fine_master_id | INT UNSIGNED | NOT NULL, FK → `tpt_fine_master.id`, ON DELETE RESTRICT | DDL |
| BC-DB-04 | fine_days | TINYINT | DEFAULT 0 | DDL |
| BC-DB-05 | fine_type | ENUM('Fixed','Percentage') | DEFAULT 'Fixed' | DDL |
| BC-DB-06 | fine_rate | DECIMAL(5,2) | DEFAULT 0.00 | DDL |
| BC-DB-07 | fine_amount | DECIMAL(10,2) | DEFAULT 0.00 | DDL |
| BC-DB-08 | waved_fine_amount | DECIMAL(10,2) | DEFAULT 0.00 | DDL |
| BC-DB-09 | net_fine_amount | DECIMAL(10,2) | DEFAULT 0.00 | DDL |
| BC-DB-10 | Remark | VARCHAR(512) | DEFAULT NULL | DDL — note uppercase `R` |
| BC-DB-11 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | DDL |
| BC-DB-12 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE | DDL |
| BC-DB-13 | deleted_at | TIMESTAMP | NULLABLE (soft delete) | DDL |

### BC-VAL: Validation Conditions

Note: `TptStudentFineDetailController` uses no dedicated Form Request. The `store()` method is empty. The `update()` method directly uses `$request->input` without explicit validation rules:

| BC ID | Field | Rule (Controller Level) | Error Message | Gap |
|-------|-------|------------------------|---------------|-----|
| BC-VAL-01 | fine_days | No validation rules in controller | — | **SECURITY GAP** — any value accepted |
| BC-VAL-02 | fine_amount | No validation rules in controller | — | **SECURITY GAP** — any value accepted |
| BC-VAL-03 | fine_type | No validation rules in controller | — | **SECURITY GAP** — any value accepted |
| BC-VAL-04 | waved_fine_amount | No validation rules in controller; defaults to 0 | — | **SECURITY GAP** — any value accepted |
| BC-VAL-05 | remark | No validation rules in controller | — | **SECURITY GAP** — XSS via remark stored literally |

Note: **No validation** is applied in the update method — this is a security gap. Malformed data can be stored. The `store()` method is empty (no implementation).

### BC-AUTH: Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Gate Behavior | Blade Usage |
|-------|-----------|-------------------|---------------|-------------|
| BC-AUTH-01 | tenant.fine-detail.viewAny | index() | `Gate::authorize()` → 403 if denied | Tab hidden via `@can` at `stdroutefeesmgmt.blade.php:43` |
| BC-AUTH-02 | tenant.fine-detail.view | show() | `Gate::authorize()` → 403 | Action column via `@canany(['edit','delete','view'])` at `index.blade.php:102` |
| BC-AUTH-03 | tenant.fine-detail.create | create(), store() | `Gate::authorize()` → 403 (but store() is empty) | Not used in blade (no create button) |
| BC-AUTH-04 | tenant.fine-detail.update | update(), edit() | `Gate::authorize()` → 403. `edit()` uses `update` gate (NOT `edit`) | Action column edit link via `@canany` |
| BC-AUTH-05 | tenant.fine-detail.edit | Action column visibility (blade `@canany`) | **Blade-only** — no controller `Gate::authorize('edit')` | `index.blade.php:102,146` |
| BC-AUTH-06 | tenant.fine-detail.delete | destroy() | `Gate::authorize()` → 403 | Action column delete via `@canany` |
| BC-AUTH-07 | tenant.fine-detail.restore | restore(), trashed() | Both use `Gate::authorize()` → 403 | `trash.blade.php:28,82` for action-trashed |
| BC-AUTH-08 | tenant.fine-detail.forceDelete | forceDelete() | `Gate::authorize()` → 403 | `trash.blade.php:28,82` |
| BC-AUTH-09 | tenant.fine-detail.status | **Not used in controller** — blade-only trash button | No `toggleStatus()` method exists | `index.blade.php:71` — Trash button wrapped in `@canany(['status'])` |
| BC-AUTH-10 | tenant.fine-detail.delete | destroyData() | Reuses `delete` gate — deletes StudentPayLog | Not in blade |

### BC-BIZ: Business Logic

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-01 | Create via `store()` | **Empty method** — returns void. Fine details can only be created via `FeeCollectionController@store()` | `TptStudentFineDetailController.php:56-60` |
| BC-BIZ-02 | Update via `update()` in DB transaction | Updates fine_days, fine_type, fine_amount, waved_fine_amount, net_fine_amount, remark. Uses `DB::transaction()` | `TptStudentFineDetailController.php:99-138` |
| BC-BIZ-03 | Net fine calculation | `$netFine = $request->fine_amount - ($request->waved_fine_amount ?? 0)` | Line 107 |
| BC-BIZ-04 | StudentPayLog on update | `activity_type: 'fine_deatils_updated'` (note: typo in code — 'deatils' instead of 'details') | Line 123 |
| BC-BIZ-05 | Activity log on update | `activityLog($fineDetail, 'Updated', ['message' => 'Fine detail updated'])` | Line 130-132 |
| BC-BIZ-06 | Soft delete via `destroy()` | `$fineDetail->delete()` — single record soft delete; redirects back with `trashed.fine_detail` | Lines 145-174 |
| BC-BIZ-07 | StudentPayLog on delete | `activity_type: 'fine_details_deleted'` | Line 156 |
| BC-BIZ-08 | Activity log on delete | `activityLog($fineDetail, 'Trashed', ['message' => 'Fine detail trashed'])` | Line 166-168 |
| BC-BIZ-09 | Trash list via `trashed()` | `TptStudentFineDetail::onlyTrashed()->latest('deleted_at')->paginate(20)` | Lines 181-190 |
| BC-BIZ-10 | Restore via `restore($id)` | `$fineDetail->restore()`; StudentPayLog created with `activity_type: 'fine_master_restored'` and `reference_table: 'tpt_fine_master'` (copy-paste bug — should reference fine-detail, not fine-master); redirect to index with `restored.fine_detail` | Lines 197-227 |
| BC-BIZ-11 | Activity log on restore | `activityLog($fineDetail, 'Restored', ['message' => 'Fine detail restored'])` | Line 220-222 |
| BC-BIZ-12 | Force delete via `forceDelete($id)` | `$fineDetail->forceDelete()`; StudentPayLog created with `activity_type: 'fine_master_deleted'` and `reference_table: 'tpt_fine_master'` (copy-paste bug); redirect to index with `force_deleted.fine_detail` | Lines 234-263 |
| BC-BIZ-13 | Activity log on force delete | `activityLog($fineDetail, 'Force Deleted', ['message' => 'Fine detail permanently deleted'])` | Lines 256-258 |
| BC-BIZ-14 | `destroyData($id)` for StudentPayLog | `StudentPayLog::findOrFail($id)->delete()`; **returns JSON** `{status: true, message: 'Log deleted successfully'}`. No `activityLog()` call — **only CRUD action without activity logging** | Lines 265-276 |
| BC-BIZ-15 | All activity logs redirect to `transport.std-route-Fees-mgmt.index` | Except `destroy()` which uses `redirect()->back()` | All redirects |
| BC-BIZ-16 | No validation in update — potential data integrity gap | Any data type can be passed through without validation | Lines 99-138 |
| BC-BIZ-17 | Controller `index()` uses `->with(['feeMaster', 'fineMasterRule'])` | `fineMasterRule()` relationship is **NOT defined** in `TptStudentFineDetail` model (only `fineMaster()` exists) — potential runtime error. Tab hub's `fineDetailsQuery()` correctly uses `fineMaster` | Controller line 26 vs Model lines 67-73 |
| BC-BIZ-18 | `toggleStatus()` method does NOT exist in `TptStudentFineDetailController` | Unlike most other Transport controllers, Fine Detail has no status toggle route/controller method. `tenant.fine-detail.status` permission exists in `$crud` and policy but is only used for blade trash button visibility | Controller lines 1-277 |
| BC-BIZ-19 | Trash button in blade uses `@canany(['tenant.fine-detail.status'])` | Unusual — trash button should logically use `restore` permission. Using `status` is a potential UI permission mismatch | `index.blade.php:71` |
| BC-BIZ-20 | Update uses both fine_days AND fine_amount AND fine_type | `$request->fine_days`, `$request->fine_amount`, `$request->fine_type` — all nullable/no default in request | Lines 109-116 |
| BC-BIZ-21 | StudentPayLog student_id derived from `feeMaster->academicSession->student_id` | `optional(optional($fineDetail->feeMaster)->academicSession)->student_id` — nullable chain, may store null | Lines 119, 153, 208, 243 |
| BC-BIZ-22 | StudentPayLog academic_session_id from `feeMaster->std_academic_sessions_id` | `optional($fineDetail->feeMaster)->std_academic_sessions_id` | Lines 120, 154, 209, 244 |
| BC-BIZ-23 | StudentPayLog amount set to `$fineDetail->fine_amount` | Amount is current value, not delta | Lines 122, 158, 214, 248 |
| BC-BIZ-24 | destroyData() JSON response | `{status: true, message: 'Log deleted successfully'}` — only success case, no error handling | Lines 272-275 |
| BC-BIZ-25 | `edit()` loads `TptFineMaster::latest()->get()` for dropdown | All fine masters loaded for `fine_master_id` select | Line 86 |

### BC-REL: Model Relationships

| BC ID | Relationship | Type | Foreign Key | Local Key | Notes |
|-------|-------------|------|-------------|-----------|-------|
| BC-REL-01 | feeMaster() | BelongsTo TptFeeMaster | student_fee_detail_id | id | Returns the fee master for this fine |
| BC-REL-02 | feeDetail() | BelongsTo TptStudentFeeDetail | student_fee_detail_id | id | Alternate relationship — same FK column, different target model (`TptStudentFeeDetail` class may not exist) |
| BC-REL-03 | fineMaster() | BelongsTo TptFineMaster | fine_master_id | id | Returns the fine master rule used |
| BC-REL-04 | fineMasterRule() | **NOT DEFINED** | fine_master_id (presumed) | id | Referenced in controller `index()` — does NOT exist on model. Causes `BadMethodCallException` if standalone route hit |
| BC-REL-05 | feeCollection() | BelongsTo TptStudentFeeCollection | student_fee_detail_id | student_fee_detail_id | Returns the fee collection record (custom FK→local mapping) |

### BC-REF: Reference & UI Conditions

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | Tab id `fine_detail-pane`, hidden `tab=fine_detail` | `stdroutefeesmgmt.blade.php` |
| BC-REF-02 | Filter bar: Academic Session dropdown (from `$organizationData`), Month dropdown (1-12), Fine Type dropdown (Fixed/Percentage) | `fine-details/index.blade.php:17-53` |
| BC-REF-03 | Table columns: Session, Month, Fine Rule, Delay Days, Fine Type, Fine Amount, Waived, Net Fine, Remark, Action | `fine-details/index.blade.php:93-104` |
| BC-REF-04 | Action column uses `<x-backend.table.action>` component with `url="transport.fine-detail" permissions="tenant.fine-detail"` | `index.blade.php:148-151` |
| BC-REF-05 | Trash table columns: Session, Month, Delay Days, Fine Type, Fine Amount, Net Fine, Status (Deleted), Action | `trash.blade.php` |
| BC-REF-06 | Edit form at `transport::fine-details.edit` pre-fills `$fineDetail` fields | `edit.blade.php` |
| BC-REF-07 | Show view at `transport::fine-details.show` with `$record` | `show.blade.php` |
| BC-REF-08 | Pagination uses `$fineDetails->withQueryString()->links()` | `index.blade.php:173` |

### BC-REF-INT: Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | student_fee_detail_id | tpt_student_fee_detail (id) | RESTRICT |
| BC-REF-02 | fine_master_id | tpt_fine_master (id) | RESTRICT |

---

## 6. Test Case List

### 6.1 TC-P: Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Fine Detail Tab Loads | `/std-route-Fees-mgmt?tab=fine_detail` loads with filter bar (Session, Month, Fine Type), table (Session, Month, Fine Rule, Delay Days, Fine Type, Fine Amount, Waived, Net Fine, Remark, Action), Trash button | — | — | ⬜ |
| TC-P02 | View Fine Detail | `/fine-detail/{id}` shows Academic Session, Fee Month, Fine Days, Fine Type, Fine Rate, Fine Amount, Waived Fine, Net Fine, Remark, Created At + Linked Fee Master Summary | — | — | ⬜ |
| TC-P03 | Edit Fine Detail — Update Fine Days and Amount | PUT `/fine-detail/{id}` updates fine_days, fine_amount; net_fine_amount recalculated; StudentPayLog created with `fine_deatils_updated` | — | — | ⬜ |
| TC-P04 | Edit Fine Detail — Waive Part of Fine | Set waved_fine_amount → net_fine_amount recalculated as fine_amount - waved_fine_amount | — | — | ⬜ |
| TC-P05 | Soft Delete Fine Detail | DELETE `/fine-detail/{id}` → deleted_at set; StudentPayLog with `fine_details_deleted`; redirect back with `trashed.fine_detail` | — | — | ⬜ |
| TC-P06 | Trash Page Shows Deleted Fine Details | GET `/fine-detail-trashed` → list with Session, Month, Delay Days, Fine Type, Fine Amount, Net Fine, Status, Action | — | — | ⬜ |
| TC-P07 | Restore Fine Detail From Trash | GET `/fine-detail/{id}/restore` → deleted_at=NULL; StudentPayLog with `fine_master_restored` (copy-paste bug); flash `restored.fine_detail` | — | — | ⬜ |
| TC-P08 | Force Delete Fine Detail | DELETE `/fine-detail/{id}/force-delete` → record permanently removed; StudentPayLog with `fine_master_deleted` (copy-paste bug); flash `force_deleted.fine_detail` | — | — | ⬜ |
| TC-P09 | Filter Fine Details By Academic Session | Select session → `whereHas('feeMaster', fn=>where std_academic_sessions_id)` | — | — | ⬜ |
| TC-P10 | Filter Fine Details By Month | Select month → `whereHas('feeMaster', fn=>where month)` | — | — | ⬜ |
| TC-P11 | Filter Fine Details By Fine Type | Select Fixed/Percentage → `where('fine_type', $value)` | — | — | ⬜ |
| TC-P12 | Empty State — No Fine Details | Table shows "No fine details found" with colspan=10 | — | — | ⬜ |
| TC-P13 | Activity Log — Updated on Update | `activityLog($fineDetail, 'Updated')` recorded after PUT | — | — | ⬜ |
| TC-P14 | Activity Log — Trashed on Delete | `activityLog($fineDetail, 'Trashed')` recorded after DELETE | — | — | ⬜ |
| TC-P15 | Activity Log — Restored on Restore | `activityLog($fineDetail, 'Restored')` recorded after restore GET | — | — | ⬜ |
| TC-P16 | Activity Log — Force Deleted on Permanently Delete | `activityLog($fineDetail, 'Force Deleted')` recorded after forceDelete DELETE | — | — | ⬜ |
| TC-P17 | Edit Fine Detail — Update fine_type | PUT with fine_type="Percentage" → DB updated to "Percentage" | — | — | ⬜ |
| TC-P18 | Edit Fine Detail — Update remark | PUT with remark="Late payment fine" → DB stores remark | — | — | ⬜ |
| TC-P19 | Edit Fine Detail — waved_fine_amount=0 (no waiver) | PUT waved_fine_amount=0 → net_fine_amount = fine_amount (unchanged) | — | — | ⬜ |
| TC-P20 | Fine Detail created via FeeCollection flow | `FeeCollectionController@store()` → auto-creates fine detail record | — | — | ⬜ |
| TC-P21 | Paginated fine detail list — page 2 | GET `/std-route-Fees-mgmt?tab=fine_detail&page=2` with 10+ records → page 2 shows records 11-20 | — | — | ⬜ |
| TC-P22 | Session filter + month filter combined | Select Session=S1 AND Month=3 → filtered results | — | — | ⬜ |
| TC-P23 | All three filters combined | Session + Month + Fine Type → intersection filter | — | — | ⬜ |

### 6.2 TC-N: Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | View Fine Detail With Invalid ID | GET `/fine-detail/99999` → 404 | — | — | ⬜ |
| TC-N02 | Edit Fine Detail With Invalid ID | GET `/fine-detail/99999/edit` → 404 | — | — | ⬜ |
| TC-N03 | Update Fine Detail With Invalid ID | PUT `/fine-detail/99999` → 404 | — | — | ⬜ |
| TC-N04 | Delete Fine Detail With Invalid ID | DELETE `/fine-detail/99999` → 404 | — | — | ⬜ |
| TC-N05 | Restore Non-Deleted Fine Detail | GET `/fine-detail/{id}/restore` where not trashed → 404 (`onlyTrashed()` finds nothing) | — | — | ⬜ |
| TC-N06 | Force Delete Non-Trashed Fine Detail | DELETE `/fine-detail/{id}/force-delete` → `onlyTrashed()` → 404 | — | — | ⬜ |
| TC-N07 | Permission 403 — No Fine Detail Permissions | 403 Forbidden on all CRUD endpoints | — | — | ⬜ |
| TC-N08 | Guest Access Redirect | All `/fine-detail/*` URLs redirect to `/login` | — | — | ⬜ |
| TC-N09 | XSS Injection In Remark | `<script>alert('xss')</script>` stored as literal string; Blade `{{ }}` escapes output | — | — | ⬜ |
| TC-N10 | No Validation on Update — Negative Fine Amount | Controller applies NO validation — negative fine_amount stored in DB (gap) | — | — | ⬜ |
| TC-N11 | No Validation on Update — Non-Numeric fine_days | No validation — string stored in TINYINT (MySQL may coerce to 0) | — | — | ⬜ |
| TC-N12 | Permission Denied — viewAny (index) | `/fine-detail` returns 403 when user lacks `tenant.fine-detail.viewAny` | — | — | ⬜ |
| TC-N13 | Permission Denied — view (show) | `/fine-detail/{id}` returns 403 when user lacks `tenant.fine-detail.view` | — | — | ⬜ |
| TC-N14 | Permission Denied — create (create/store) | `/fine-detail/create` and POST `/fine-detail` return 403 when user lacks `tenant.fine-detail.create` | — | — | ⬜ |
| TC-N15 | Permission Denied — update (edit/update) | `/fine-detail/{id}/edit` and PUT `/fine-detail/{id}` return 403 when user lacks `tenant.fine-detail.update` | — | — | ⬜ |
| TC-N16 | Permission Denied — delete (destroy) | DELETE `/fine-detail/{id}` returns 403 when user lacks `tenant.fine-detail.delete` | — | — | ⬜ |
| TC-N17 | Permission Denied — restore (trashed/restore) | GET `/fine-detail-trashed` and GET `/fine-detail/{id}/restore` return 403 when user lacks `tenant.fine-detail.restore` | — | — | ⬜ |
| TC-N18 | Permission Denied — forceDelete | DELETE `/fine-detail/{id}/force-delete` returns 403 when user lacks `tenant.fine-detail.forceDelete` | — | — | ⬜ |
| TC-N19 | Permission Denied — destroyData | DELETE `/student-pay-log/{id}` returns 403 when user lacks `tenant.fine-detail.delete` | — | — | ⬜ |
| TC-N20 | Update with invalid fine_type (not in ENUM) | PUT fine_type="InvalidType" → MySQL strict mode error or stored as-is depending on mode | — | — | ⬜ |
| TC-N21 | Update with null fine_days | PUT fine_days=null → MySQL TINYINT stores 0 or throws depending on schema | — | — | ⬜ |

### 6.3 TC-D: Dependency/Data Integrity Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Fine Detail Created via Fee Collection | `FeeCollectionController@store()` creates TptStudentFineDetail when fine_master_id provided | — | — | ⬜ |
| TC-D02 | B | Fee Master Delete Restricted by Fine Detail | DDL FK RESTRICT on student_fee_detail_id — cannot force-delete fee master with fine details | — | — | ⬜ |
| TC-D03 | C | Fine Master Delete Restricted by Fine Detail | DDL FK RESTRICT on fine_master_id — cannot delete fine master if fine details reference it | — | — | ⬜ |
| TC-D04 | D | Controller `index()` uses undefined `fineMasterRule` relationship | `TptStudentFineDetailController@index()` calls `->with(['feeMaster', 'fineMasterRule'])` but `fineMasterRule()` is NOT defined in model — only `fineMaster()` exists. Standalone index route may fail with `BadMethodCallException` | — | — | ⬜ |
| TC-D05 | E | DB transaction rollback on exception in update() | Force exception inside `DB::transaction()` → all changes reverted, StudentPayLog NOT created | — | — | ⬜ |
| TC-D06 | F | Restore uses onlyTrashed — non-trashed IDs get 404 | `TptStudentFineDetail::onlyTrashed()->findOrFail($id)` — cannot restore active records | — | — | ⬜ |
| TC-D07 | G | Force delete also uses onlyTrashed | Same pattern as restore — only trashed records can be force deleted | — | — | ⬜ |
| TC-D08 | H | StudentPayLog created in same transaction as update | `StudentPayLog::create()` inside `DB::transaction()` — if StudentPayLog insert fails, update also rolls back | — | — | ⬜ |
| TC-D09 | I | destroyData deletes existing StudentPayLog | DELETE `/student-pay-log/{id}` → record removed from DB permanently | — | — | ⬜ |
| TC-D10 | J | Copy-paste bug: restore uses fine_master reference | `reference_table: 'tpt_fine_master'` should reference `'tpt_student_fine_detail'` | — | — | ⬜ |

### 6.4 TC-CR: Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Tab Visibility | `stdroutefeesmgmt.blade.php`: `@can('tenant.fine-detail.viewAny')` wraps `@include('transport::fine-details.index')` | — | — | ◌ |
| TC-CR02 | CR | P1 | Blade — Trash Button Guard | `@canany(['tenant.fine-detail.status'])` wraps Trash button — uses `status` permission for trash access (mismatch) | — | — | ◌ |
| TC-CR03 | CR | P1 | Blade — Action Column Guard | `@canany(['tenant.fine-detail.edit', 'tenant.fine-detail.delete','tenant.fine-detail.view'])` wraps action column | — | — | ◌ |
| TC-CR04 | CR | P1 | Blade — Trash Action Column Guard | `@canany(['tenant.fine-detail.forceDelete', 'tenant.fine-detail.restore'])` wraps action-trashed | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() Before Every State Change | Every method: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, destroyData — all have Gate::authorize() | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activityLog Created on State Changes | Updated, Trashed, Restored, Force Deleted — all logged | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — StudentPayLog Created on Update/Delete/Restore/ForceDelete | Each action creates StudentPayLog with appropriate activity_type; destroyData DELETES (not creates) | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — store() is Empty | `store()` method (lines 56-60) has no implementation — returns void, no DB write | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — No Form Request Validation | Update method uses plain `Request` with NO validation rules — security gap | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — DB Transaction for update() | update() uses `DB::transaction()` for the full operation (save + StudentPayLog + activityLog) | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — OnlyTrashed for Restore/ForceDelete | Both restore() and forceDelete() use `onlyTrashed()->findOrFail()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Controller — destroyData for PayLog | Custom method to delete StudentPayLog records (not part of resource) — returns JSON | — | — | ◌ |
| TC-CR13 | CR | P1 | Controller — Typo in activity_type | `'fine_deatils_updated'` — misspelled 'deatils' instead of 'details' at line 123 | — | — | ◌ |
| TC-CR14 | CR | P1 | Controller — Typo in description | `'Transport fine setails ter updated'` — multiple typos ('setails' → 'details', 'ter' → 'were') at line 126 | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes | `Route::resource('fine-detail', ...)` + separate trashed/restore/forceDelete + destroyData defined on web.php lines 277-285 | — | — | ◌ |
| TC-CR16 | CR | P1 | View — Table Columns | Session, Month, Fine Rule, Delay Days, Fine Type, Fine Amount, Waived, Net Fine, Remark, Action — matches `index.blade.php:93-104` | — | — | ◌ |
| TC-CR17 | CR | P1 | View — Show Page Fields | Academic Session, Fee Month, Fine Days, Fine Type, Fine Rate, Fine Amount, Waived Fine, Net Fine, Remark, Created At | — | — | ◌ |
| TC-CR18 | CR | P1 | View — Trash Table Columns | Session, Month, Delay Days, Fine Type, Fine Amount, Net Fine, Status (Deleted), Action — matches `trash.blade.php` | — | — | ◌ |
| TC-CR19 | CR | P1 | View — Flash Messages | `updated.fine_detail`, `trashed.fine_detail`, `restored.fine_detail`, `force_deleted.fine_detail` via `flash()` helper | — | — | ◌ |
| TC-CR20 | CR | P1 | Model — Table Name and SoftDeletes | `protected $table = 'tpt_student_fine_detail'` and `use SoftDeletes` | — | — | ◌ |
| TC-CR21 | CR | P1 | Model — Fillable | student_fee_detail_id, fine_master_id, fine_days, fine_type, fine_rate, fine_amount, waved_fine_amount, net_fine_amount, remark — 9 fields | — | — | ◌ |
| TC-CR22 | CR | P1 | Model — Casts | fine_rate, fine_amount, waved_fine_amount, net_fine_amount => 'decimal:2' (4 casts) | — | — | ◌ |
| TC-CR23 | CR | P1 | DDL — ENUM fine_type | `ENUM('Fixed','Percentage')` DEFAULT 'Fixed' | — | — | ◌ |
| TC-CR24 | CR | P1 | DDL — RESTRICT FK Both Sides | Both student_fee_detail_id and fine_master_id use ON DELETE RESTRICT | — | — | ◌ |
| TC-CR25 | CR | P1 | DDL — Column Name Discrepancy `Remark` | DDL uses uppercase `Remark`, model uses lowercase `remark` in fillable | — | — | ◌ |
| TC-CR26 | CR | P1 | Controller `index()` uses `fineMasterRule` — relationship not in model | `with(['feeMaster', 'fineMasterRule'])` — `fineMasterRule()` does not exist on `TptStudentFineDetail` (only `fineMaster()` exists). Tab hub can work because `fineDetailsQuery()` uses `fineMaster`, but standalone `/fine-detail` route may crash | — | — | ◌ |
| TC-CR27 | CR | P1 | `toggleStatus()` method missing | Unlike most Transport CRUD controllers, `TptStudentFineDetailController` has no `toggleStatus()` method. Route not defined in web.php. `status` permission only used for blade trash button | — | — | ◌ |
| TC-CR28 | CR | P2 | Trash button uses `status` permission instead of `restore` | Blade `@canany(['tenant.fine-detail.status'])` wraps trash link — semantic mismatch. `status` permission should control status toggle, not trash page access (should be `restore`) | — | — | ◌ |
| TC-CR29 | CR | P2 | restore/forceDelete StudentPayLog references `tpt_fine_master` | Copy-paste bug: `reference_table: 'tpt_fine_master'` in restore (line 213) and forceDelete (line 249) — should be `tpt_student_fine_detail`. `activity_type` values `fine_master_restored`/`fine_master_deleted` also misnamed | — | — | ◌ |
| TC-CR30 | CR | P2 | `destroyData()` has no `activityLog()` call | Only CRUD method that performs a state change without calling `activityLog()`. StudentPayLog deletion is not audited | — | — | ◌ |
| TC-CR31 | CR | P2 | `edit()` loads `TptFineMaster::latest()->get()` but `TptFineMaster` model is `TptFeeMaster`? | Line 86-87: `TptFineMaster::latest()->get()` — check if class name is correct in context | — | — | ◌ |
| TC-CR32 | CR | P2 | StudentPayLog comment `/** 🔥 PAY LOG (Fee master is NOT student based) */` | Comment appears in destroy and forceDelete — indicates developer awareness of data model issue | — | — | ◌ |
| TC-CR33 | CR | P2 | destroy() StudentPayLog created BEFORE `$fineDetail->delete()` | `StudentPayLog::create()` at lines 152-162 is BEFORE `$fineDetail->delete()` at line 164 — if delete fails, PayLog is orphaned (not in transaction) | — | — | ◌ |
| TC-CR34 | CR | P2 | destroy() activityLog called after delete | `activityLog($fineDetail, 'Trashed')` at lines 166-168 called AFTER `$fineDetail->delete()` — `$fineDetail` still available in memory | — | — | ◌ |
| TC-CR35 | CR | P2 | update() does NOT update fine_master_id | `$fineDetail->update([...])` at lines 109-116 does NOT include `fine_master_id` — fine master rule cannot be changed via update | — | — | ◌ |
| TC-CR36 | CR | P2 | update() does NOT update fine_rate | `fine_rate` NOT in update() array — rate locked after creation | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P03: Edit Fine Detail — Update Fine Days and Amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin user having `tenant.fine-detail.update` | Success |
| 2 | Navigate to `/std-route-Fees-mgmt?tab=fine_detail` | Fine detail tab loads with table |
| 3 | Locate a fine detail row and click Action → Edit | GET `/fine-detail/{id}/edit` |
| 4 | **Verify**: `Gate::authorize('tenant.fine-detail.update')` passes | Authorized |
| 5 | **Verify**: `TptStudentFineDetail::findOrFail($id)` returns record | Record loaded |
| 6 | **Verify**: `TptFineMaster::latest()->get()` loaded for fine drop-down | Fine masters available |
| 7 | Edit form renders with current values pre-filled | fine_days, fine_type, fine_amount, waved_fine_amount, remark fields shown |
| 8 | Change fine_days from current to "15" | Input updated |
| 9 | Change fine_amount from current to "200.00" | Input updated |
| 10 | Enter waved_fine_amount "50.00" | Input updated |
| 11 | Select fine_type from dropdown (optional — stays current if unchanged) | Dropdown shows options |
| 12 | Enter remark "Updated via test" | Text input updated |
| 13 | Submit form (PUT) | PUT `/fine-detail/{id}` with form data |
| 14 | **Verify**: `DB::transaction()` begins | Transaction started (code at line 99: method, 105: closure) |
| 15 | **Verify**: `$netFine = $request->fine_amount - ($request->waved_fine_amount ?? 0)` | `$netFine = 200 - 50 = 150` |
| 16 | **Verify**: `$fineDetail->update([...])` called with all fields | `fine_days=15, fine_amount=200.00, waved_fine_amount=50.00, net_fine_amount=150.00, remark="Updated via test"` |
| 17 | **Verify**: `fine_master_id` and `fine_rate` NOT updated | Values unchanged from original |
| 18 | **Verify**: StudentPayLog created | `activity_type='fine_deatils_updated'`, `reference_table='tpt_fine_details'`, `reference_id={id}`, `amount=200.00` |
| 19 | **Verify**: StudentPayLog description has typos | `'Transport fine setails ter updated'` |
| 20 | **Verify**: `activityLog($fineDetail, 'Updated', ['message' => 'Fine detail updated'])` | Activity logged in system_activity_log |
| 21 | **Verify**: `DB::transaction()` committed | Transaction complete without exception |
| 22 | **Verify**: Redirect to `route('transport.std-route-Fees-mgmt.index')` | Redirect to `/std-route-Fees-mgmt?tab=fine_detail` |
| 23 | **Verify**: Flash message `updated.fine_detail` | "Fine detail updated successfully" displayed |
| 24 | **DB Check**: `SELECT fine_days, fine_amount, waved_fine_amount, net_fine_amount, remark FROM tpt_student_fine_detail WHERE id={id}` | `15, 200.00, 50.00, 150.00, "Updated via test"` |
| 25 | **DB Check**: `SELECT * FROM student_pay_logs WHERE reference_id={id} AND reference_table='tpt_fine_details'` | PayLog record exists with `activity_type='fine_deatils_updated'` |
| 26 | **DB Check**: `SELECT * FROM system_activity_log WHERE subject_id={id}` | Activity record with event='Updated' |

### TC-P04: Edit Fine Detail — Waive Part of Fine

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit form for a fine detail with fine_amount=500.00 | Edit form loaded |
| 2 | Set waved_fine_amount = "100.00" | Input updated |
| 3 | Keep fine_amount at 500.00 | Unchanged |
| 4 | Submit form | PUT request |
| 5 | **Verify**: `$netFine = 500 - 100 = 400` | `net_fine_amount=400.00` |
| 6 | DB Check: `SELECT waved_fine_amount, net_fine_amount` | `100.00, 400.00` |
| 7 | Submit again with waved_fine_amount = "0.00" | Waive removed |
| 8 | DB Check: `SELECT waved_fine_amount, net_fine_amount` | `0.00, 500.00` (net = fine_amount) |

### TC-P05: Soft Delete Fine Detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.fine-detail.delete` | Success |
| 2 | Navigate to Fine Detail tab | Grid loaded |
| 3 | Click Action → Delete on a fine detail row | DELETE `/fine-detail/{id}` |
| 4 | **Verify**: `Gate::authorize('tenant.fine-detail.delete')` passes | Authorized |
| 5 | **Verify**: `TptStudentFineDetail::findOrFail($id)` | Record found |
| 6 | **Verify**: StudentPayLog created at lines 152-162 | `activity_type='fine_details_deleted'`, `reference_table='tpt_fine_details'` |
| 7 | **Verify**: StudentPayLog created even if delete fails later | PayLog created BEFORE delete (line 152-162 before line 164) |
| 8 | **Verify**: `$fineDetail->delete()` called | Soft delete — sets deleted_at |
| 9 | **Verify**: `activityLog($fineDetail, 'Trashed', [...]` | Logged after delete |
| 10 | **Verify**: Redirect `->back()` | Redirect to previous page |
| 11 | **Verify**: Flash `trashed.fine_detail` | "Fine detail trashed successfully" |
| 12 | **DB Check**: `SELECT deleted_at FROM tpt_student_fine_detail WHERE id={id}` | `deleted_at` IS NOT NULL |
| 13 | **UI Check**: Record no longer visible in main list | Row absent from table |
| 14 | Click Trash button | Navigate to `/fine-detail-trashed` |
| 15 | **UI Check**: Deleted record visible in trash list | Row present with "Deleted" status |

### TC-P07: Restore Fine Detail From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/fine-detail-trashed` | Trash list loaded |
| 2 | Click Action → Restore on a trashed fine detail | GET `/fine-detail/{id}/restore` |
| 3 | **Verify**: `Gate::authorize('tenant.fine-detail.restore')` | Authorized |
| 4 | **Verify**: `TptStudentFineDetail::onlyTrashed()->findOrFail($id)` | Record found (deleted_at NOT NULL) |
| 5 | **Verify**: `$fineDetail->restore()` | Sets deleted_at = NULL |
| 6 | **Verify**: StudentPayLog created with copy-paste bug | `activity_type='fine_master_restored'`, `reference_table='tpt_fine_master'` (should be fine_detail) |
| 7 | **Verify**: `activityLog($fineDetail, 'Restored', [...])` | Activity logged |
| 8 | **Verify**: Redirect to `route('transport.std-route-Fees-mgmt.index')` | Redirect to main page |
| 9 | **Verify**: Flash `restored.fine_detail` | "Fine detail restored successfully" |
| 10 | **DB Check**: `SELECT deleted_at FROM tpt_student_fine_detail WHERE id={id}` | `deleted_at` IS NULL |
| 11 | **UI Check**: Record visible again in main list | Row restored |

### TC-P08: Force Delete Fine Detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/fine-detail-trashed` | Trash list loaded |
| 2 | Click Action → Force Delete on a trashed fine detail | DELETE `/fine-detail/{id}/force-delete` |
| 3 | **Verify**: `Gate::authorize('tenant.fine-detail.forceDelete')` | Authorized |
| 4 | **Verify**: `TptStudentFineDetail::onlyTrashed()->findOrFail($id)` | Record found (must be trashed first) |
| 5 | **Verify**: StudentPayLog created with copy-paste bug | `activity_type='fine_master_deleted'`, `reference_table='tpt_fine_master'` (should be fine_detail) |
| 6 | **Verify**: `$fineDetail->forceDelete()` | Record permanently removed from DB |
| 7 | **Verify**: `activityLog($fineDetail, 'Force Deleted', [...])` | Activity logged |
| 8 | **DB Check**: `SELECT * FROM tpt_student_fine_detail WHERE id={id}` | No rows (permanently deleted) |
| 9 | **PayLog Check**: StudentPayLog still exists (separate table) | Log entry remains |

### TC-N05: Restore Non-Deleted Fine Detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active fine detail (deleted_at=NULL) | Active record |
| 2 | Call GET `/fine-detail/{id}/restore` | Controller hit |
| 3 | **Verify**: `TptStudentFineDetail::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` → WHERE deleted_at IS NOT NULL |
| 4 | Active record has deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException |
| 5 | **Verify**: 404 error returned | "No query results" |

### TC-N06: Force Delete Non-Trashed Fine Detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active fine detail | Active record |
| 2 | Call DELETE `/fine-detail/{id}/force-delete` | Controller hit |
| 3 | **Verify**: `TptStudentFineDetail::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` filters to trashed only |
| 4 | Record not trashed → 404 | ModelNotFoundException |
| 5 | **Workaround**: Must soft-delete first, then force-delete | Two-step process |

### TC-N10: No Validation on Update — Negative Fine Amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit fine detail form | Edit form |
| 2 | Set fine_amount = "-100.00" | Negative value entered |
| 3 | Submit form | PUT `/fine-detail/{id}` |
| 4 | **Verify**: Controller does NOT call `$request->validate([...])` | No validation rules |
| 5 | **Verify**: `$fineDetail->update(['fine_amount' => $request->fine_amount])` | `fine_amount = -100.00` stored in DB |
| 6 | **DB Check**: `SELECT fine_amount FROM tpt_student_fine_detail WHERE id={id}` | `-100.00` |
| 7 | **Impact**: Negative fine amount stored — no guard against this | Data integrity gap |

### TC-N11: No Validation on Update — Non-Numeric fine_days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit fine detail form | Edit form |
| 2 | Set fine_days = "abc" | Non-numeric string |
| 3 | Submit form | PUT `/fine-detail/{id}` |
| 4 | **Verify**: No validation rule for fine_days | String passed to update |
| 5 | **DB Check**: `SELECT fine_days FROM tpt_student_fine_detail WHERE id={id}` | MySQL TINYINT coerces "abc" → 0 |
| 6 | **Impact**: Silent data mutation — user enters "abc", DB stores 0 | User confusion |

### TC-P01: Fine Detail Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin user | Success |
| 2 | Navigate to `/std-route-Fees-mgmt?tab=fine_detail` | StudentRouteFeesController@index() |
| 3 | **Verify**: `@can('tenant.fine-detail.viewAny')` → true | Include renders |
| 4 | **Verify**: `$fineDetails = $this->fineDetailsQuery($request)->paginate(10)->withQueryString()` | Fine details loaded with eager loaded feeMaster, fineMaster |
| 5 | **Verify**: Filter bar visible — 3 dropdowns | Session, Month, Fine Type |
| 6 | **Verify**: Table headers | Session, Month, Fine Rule, Delay Days, Fine Type, Fine Amount, Waived, Net Fine, Remark, Action |
| 7 | **Verify**: Pagination links visible (if >10 records) | `->links()` rendered |
| 8 | **Verify**: Trash button visible (if user has `status` permission) | Red button linking to `fine-detail-trashed` |
| 9 | **Verify**: Records show correct data | Session from feeMaster, Fine Rule from fineMaster (shown as "X-Y days") |
| 10 | **Verify**: Fine Amount/Waived/Net Fine formatted as `₹ XXXX.XX` | Currency formatting |

### TC-P02: View Fine Detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to fine detail list | Table loaded |
| 2 | Click Action → View on a row | GET `/fine-detail/{id}` |
| 3 | **Verify**: `Gate::authorize('tenant.fine-detail.view')` | Authorized |
| 4 | **Verify**: `TptStudentFineDetail::findOrFail($id)` | Record found |
| 5 | **Verify**: Show view renders all fields | Academic Session, Fee Month, Fine Days, Fine Type, Fine Rate, Fine Amount, Waived Fine, Net Fine, Remark, Created At |
| 6 | **Verify**: Linked Fee Master summary visible | feeMaster details shown |

### TC-P06: Trash Page Shows Deleted Fine Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete at least one fine detail | Record trashed |
| 2 | Navigate to `/fine-detail-trashed` | GET request |
| 3 | **Verify**: `Gate::authorize('tenant.fine-detail.restore')` | Authorized |
| 4 | **Verify**: `TptStudentFineDetail::onlyTrashed()->latest('deleted_at')->paginate(20)` | Only trashed records, 20 per page |
| 5 | **Verify**: Table columns | Session, Month, Delay Days, Fine Type, Fine Amount, Net Fine, Status (Deleted), Action |
| 6 | **Verify**: Action column has Restore and Force Delete buttons | Both present |
| 7 | **Verify**: Pagination if >20 trashed records | Page links |

### TC-P09/P10/P11: Filter Fine Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Academic Session "Session 2024-25" | `std_academic_sessions_id=1` |
| 2 | Click Search | GET with param |
| 3 | **Verify**: `$request->filled('std_academic_sessions_id')` → `whereHas('feeMaster', fn=>where('std_academic_sessions_id',1))` | Filtered results |
| 4 | Reset, select Month = "3" (March) | `month=3` |
| 5 | Click Search | `whereHas('feeMaster', fn=>where('month',3))` |
| 6 | Reset, select Fine Type = "Fixed" | `fine_type=Fixed` |
| 7 | Click Search | `where('fine_type', 'Fixed')` |
| 8 | Combine all 3 filters | Intersection filtering |

### TC-P12: Empty State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to fine detail tab when no records exist (clean DB) | Tab loads |
| 2 | **Verify**: `$fineDetails->count()` is 0 | Empty collection |
| 3 | **Verify**: `@forelse` → `@empty` block | `<td colspan="10" class="text-center text-muted py-3">No fine details found</td>` |

### TC-P13 through TC-P16: Activity Log Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Perform update on fine detail | `activityLog($fineDetail, 'Updated', ['message' => 'Fine detail updated'])` |
| 2 | Perform delete on fine detail | `activityLog($fineDetail, 'Trashed', ['message' => 'Fine detail trashed'])` |
| 3 | Perform restore on trashed fine detail | `activityLog($fineDetail, 'Restored', ['message' => 'Fine detail restored'])` |
| 4 | Perform force delete on trashed fine detail | `activityLog($fineDetail, 'Force Deleted', ['message' => 'Fine detail permanently deleted'])` |
| 5 | **DB Check**: Each action logged in `system_activity_log` | `subject_id={id}`, `subject_type=TptStudentFineDetail`, `event={event}` |

### TC-D04: CODE-TRACE — Controller index() Uses Undefined fineMasterRule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptStudentFineDetailController.php:22-31` | `index()` method |
| 2 | Inspect line 26: `TptStudentFineDetail::with(['feeMaster', 'fineMasterRule'])` | Eager loads `fineMasterRule` relationship |
| 3 | Open `TptStudentFineDetail.php` (model, 86 lines) | Full model file |
| 4 | Search for `function fineMasterRule` | **NOT FOUND** |
| 5 | Verify existing relationships: `feeMaster()`, `feeDetail()`, `fineMaster()`, `feeCollection()` | Only 4 relationships defined |
| 6 | `fineMasterRule` is undefined → Eloquent throws `BadMethodCallException` | `Call to undefined relationship [fineMasterRule] on model [TptStudentFineDetail]` |
| 7 | Therefore, standalone route `GET /fine-detail` will crash with 500 error | Route resource line 277 invokes index() |
| 8 | Compare with `StudentRouteFeesController@fineDetailsQuery()` line 136-138 | Correctly uses `with(['feeMaster', 'fineMaster'])` — no issue via tab |
| 9 | **Impact**: Standalone `/fine-detail` is broken. Only tab route works | This is a production bug |

### TC-CR13: CODE-TRACE — Typo in activity_type 'fine_deatils_updated'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptStudentFineDetailController.php:118-128` | StudentPayLog update block |
| 2 | Inspect line 123: `'activity_type' => 'fine_deatils_updated'` | **Typo**: 'deatils' instead of 'details' |
| 3 | Expected correct spelling: `'fine_details_updated'` | Missing 'l' in 'deatils' |
| 4 | Inspect line 126: `'description' => 'Transport fine setails ter updated'` | Multiple typos: 'setails' instead of 'details', 'ter' instead of 'were' |
| 5 | **Impact**: Reports and analytics filtering by `activity_type='fine_details_updated'` will miss these entries | Query mismatch cannot find these logs |

### TC-CR29: CODE-TRACE — Copy-Paste Bug in restore/forceDelete PayLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `restore()` at lines 207-217 | StudentPayLog::create block |
| 2 | Inspect line 211: `'activity_type' => 'fine_master_restored'` | Should be `'fine_detail_restored'` — says 'master' not 'detail' |
| 3 | Inspect line 213: `'reference_table' => 'tpt_fine_master'` | **WRONG** — should reference `'tpt_student_fine_detail'` |
| 4 | Open `forceDelete()` at lines 242-251 | Same copy-paste block |
| 5 | Inspect line 246: `'activity_type' => 'fine_master_deleted'` | Should be `'fine_detail_deleted'` |
| 6 | Inspect line 249: `'reference_table' => 'tpt_fine_master'` | Same wrong reference |
| 7 | **Root Cause**: Copy-paste from `TptFineMasterController` (Fine Master) CRUD | Developer copied code without updating table/type names |
| 8 | **Impact**: Reports filtering on `reference_table='tpt_student_fine_detail'` will miss these restore/forceDelete events | Audit trail corrupted |

### TC-CR09: CODE-TRACE — No Validation in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` at lines 99-138 | Full method |
| 2 | Scan for `$request->validate(...)`, `Validator::make(...)`, or any validation calls | **NONE FOUND** |
| 3 | The method uses plain `$request->fine_days`, `$request->fine_amount` etc. without any rules | Direct assignment to model |
| 4 | Method signature: `update(Request $request, $id)` — uses `Illuminate\Http\Request`, NOT a Form Request | No validation class |
| 5 | **Compare** with other Transport controllers that use Form Requests (e.g., `PickupPointRouteRequest`) | Inconsistent — missing validation entirely |
| 6 | **Impact**: Negative amounts, non-numeric types, XSS strings, invalid ENUM values — all pass through | Data integrity gap |

### TC-CR30: CODE-TRACE — destroyData() No activityLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroyData()` at lines 265-276 | Custom method |
| 2 | Line 267: `Gate::authorize('tenant.fine-detail.delete')` | Authorization present |
| 3 | Line 269-270: `StudentPayLog::findOrFail($id)->delete()` | Deletes the PayLog |
| 4 | Line 272-275: JSON response | `{status: true, message: 'Log deleted successfully'}` |
| 5 | Search for `activityLog` in method | **NOT CALLED** |
| 6 | **Impact**: Deletion of audit log entries is itself NOT audited | User can delete PayLog without trace |

### TC-CR33: CODE-TRACE — destroy() PayLog Before Delete (Orphan Risk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` at lines 145-174 | Full method |
| 2 | Lines 152-162: `StudentPayLog::create([...])` | PayLog created BEFORE delete |
| 3 | Line 164: `$fineDetail->delete()` | Soft delete after PayLog |
| 4 | PayLog creation is NOT inside `DB::transaction()` (unlike update) | No transaction wrapping |
| 5 | If `$fineDetail->delete()` fails (FK constraint, DB error), PayLog is already committed | **Orphan**: PayLog exists for non-deleted record |
| 6 | **Compare** with `update()` which correctly wraps both operations in `DB::transaction()` | Inconsistent transaction usage |

### TC-BIZ-DEEP-01: Controller store() is Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` at lines 56-60 | Method body |
| 2 | Line 58: `Gate::authorize('tenant.fine-detail.create')` | Only authorization |
| 3 | Line 60: method ends | **No DB write, no validation, no redirect** — returns void |
| 4 | POST to `/fine-detail` with valid data | `store()` called, but no record created |
| 5 | **Verify**: 200 response with empty body | Laravel returns empty 200 |
| 6 | **DB Check**: `tpt_student_fine_detail` has no new record | No insert occurred |
| 7 | **Impact**: Route resource includes store endpoint, but it's a no-op | Dead endpoint |

### TC-BIZ-DEEP-02: StudentPayLog student_id Nullable Chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open update() line 119: `optional(optional($fineDetail->feeMaster)->academicSession)->student_id` | Null-coalescing chain |
| 2 | If `feeMaster` is null → `optional(null)` returns null → `optional(null)->student_id` is null | `student_id` stored as NULL |
| 3 | If `feeMaster` exists but `academicSession` is null → same null result | NULL student_id |
| 4 | **DB Check**: StudentPayLog records may have NULL student_id | Depends on relationship existence |

### TC-BIZ-DEEP-03: Remark Column Name Discrepancy (DDL vs Model)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL: column name is `Remark` (uppercase R) | DDL from migration |
| 2 | Check model fillable: `'remark'` (lowercase r) | `TptStudentFineDetail.php:27` |
| 3 | Check update() line 115: `'remark' => $request->remark` | Lowercase in Eloquent |
| 4 | MySQL on Linux is case-insensitive for column names by default | Works despite case difference |
| 5 | **Note**: If case-sensitive collation is used, this would fail | Portability concern |

### TC-BIZ-DEEP-04: Update Does NOT Allow fine_master_id Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open update() lines 109-116 | Array passed to `$fineDetail->update()` |
| 2 | Fields updated: fine_days, fine_amount, fine_type, waved_fine_amount, net_fine_amount, remark | 6 fields |
| 3 | Fields NOT updated: fine_master_id, fine_rate, student_fee_detail_id | These cannot be changed after creation |
| 4 | **Verify**: `$request->fine_master_id` exists in request but NOT used in update | Ignored silently |
| 5 | **Impact**: Fine rule assignment cannot be corrected via edit | User must delete and recreate |

### TC-BIZ-DEEP-05: net_fine_amount Can Exceed fine_amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit form: fine_amount = "100", waved_fine_amount = "-200" | waved_fine_amount can be negative (no validation) |
| 2 | Submit | $netFine = 100 - (-200) = 300 |
| 3 | DB Check: net_fine_amount = 300 | net exceeds fine_amount by 200 |
| 4 | **Impact**: Waived amount can exceed fine amount, making net negative or larger than original | Data integrity gap |

### TC-BIZ-DEEP-06: destroyData JSON Response Success Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open destroyData() lines 265-276 | Method body |
| 2 | Line 269: `StudentPayLog::findOrFail($id)` | Throws ModelNotFoundException if not found → 404 |
| 3 | Line 270: `$log->delete()` | May fail silently (no try-catch) |
| 4 | Line 272-275: always returns `{status: true}` | No error response path |
| 5 | **GAP**: If delete fails, method still returns success | False positive to client |

### TC-BIZ-DEEP-07: Edit View Does Not Load feeMaster Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `edit()` lines 81-91 | Method body |
| 2 | Line 85: `TptStudentFineDetail::findOrFail($id)` | Loads model |
| 3 | Line 86: `TptFineMaster::latest()->get()` | Loads fine masters only |
| 4 | **Missing**: No `TptFeeMaster::latest()->get()` loaded for display | Edit form lacks Fee Master context |

### TC-BIZ-DEEP-08: Show View View Path vs Store View Path Discrepancy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller show() line 73: `transport::fine-details.show` | View at `resources/views/fine-details/show.blade.php` |
| 2 | Controller edit() line 89: `transport::fine-details.edit` | View at `resources/views/fine-details/edit.blade.php` |
| 3 | Controller index() line 30: `transport::fine-detail.index` | View at `resources/views/fine-detail/index.blade.php` (NOTE: fine-detail SINGULAR, not fine-details) |
| 4 | Controller create() line 46: `transport::fine-detail.create` | **View DIRECTORY does NOT exist** — 500 ViewNotFoundException |
| 5 | **Inconsistency**: Mixed view paths: fine-detail (singular) vs fine-details (plural) | Standards violation |

### TC-BIZ-DEEP-09: StudentPayLog description typo patterns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update PayLog: `'Transport fine setails ter updated'` | 'setails' should be 'details', 'ter' should be 'were' | Line 126 |
| 2 | Delete PayLog: `'Transport fine details deleted'` | Correct spelling | Line 160 |
| 3 | Restore PayLog: `'Transport fine master restored'` | 'master' should be 'detail' | Line 215 |
| 4 | ForceDelete PayLog: `'Transport fine master permanently Deleted'` | 'master' should be 'detail', inconsistent 'Deleted' capitalization | Line 250 |
| 5 | **Pattern**: Only Update has typos, Delete is correctly spelled, Restore/ForceDelete have copy-paste from different controller | Inconsistent quality |

### TC-BIZ-DEEP-10: Model feeDetail() Relationship — Class Existence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model line 44-50: `public function feeDetail()` | BelongsTo TptStudentFeeDetail |
| 2 | Check if `TptStudentFeeDetail` model class exists | **May not exist** — verify class declaration |
| 3 | If class does not exist, this relationship will fail at runtime | Potential runtime error |

### TC-BIZ-DEEP-11: Fee Collection flow is the real create pathway

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `FeeCollectionController@store()` is the intended creation point | Auto-creates TptStudentFineDetail |
| 2 | Model fine detail is created as a side effect of fee collection | Not directly via TptStudentFineDetailController |
| 3 | Standalone create view does not exist | No UI to create fine details independently |

### TC-N07: Permission 403 — Full Suite

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with NO fine-detail permissions | No permissions assigned |
| 2 | GET `/fine-detail` | 403 (viewAny) |
| 3 | GET `/fine-detail/create` | 403 (create) |
| 4 | POST `/fine-detail` | 403 (create) |
| 5 | GET `/fine-detail/1` | 403 (view) |
| 6 | GET `/fine-detail/1/edit` | 403 (update) |
| 7 | PUT `/fine-detail/1` | 403 (update) |
| 8 | DELETE `/fine-detail/1` | 403 (delete) |
| 9 | GET `/fine-detail-trashed` | 403 (restore) |
| 10 | GET `/fine-detail/1/restore` | 403 (restore) |
| 11 | DELETE `/fine-detail/1/force-delete` | 403 (forceDelete) |
| 12 | DELETE `/student-pay-log/1` | 403 (delete — destroyData reuses delete gate) |

### TC-N08: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated user) | Guest session |
| 2 | GET `/fine-detail` | Redirect to `/login` |
| 3 | GET `/fine-detail/1/edit` | Redirect to `/login` |
| 4 | All `/fine-detail/*` URLs | All redirect to login (Laravel auth middleware) |

### TC-N09: XSS Injection In Remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update fine detail with remark = `<script>alert('XSS')</script>` | PUT request |
| 2 | Controller stores remark as-is (no validation, no sanitization) | Stored in DB |
| 3 | View: `{{ $item->remark ?? '-' }}` | Blade `{{ }}` uses htmlspecialchars → escaped output |
| 4 | **Verify**: Page source shows `&lt;script&gt;alert('XSS')&lt;/script&gt;` | Safe — XSS prevented by Blade escaping |
| 5 | **Verify**: No JS alert triggered | Safe output |

### TC-D05: DB Transaction Rollback on Exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate exception inside update() transaction (e.g., DB constraint violation) | Exception thrown |
| 2 | **Verify**: `DB::transaction()` closure is inside method but NO explicit try-catch | Laravel's `DB::transaction()` auto-rolls back on exception |
| 3 | **Verify**: No changes persisted to DB | fine_detail unchanged, StudentPayLog not created, activityLog not written |
| 4 | **Verify**: Exception propagates → 500 error | Laravel renders error page |

### TC-D08: StudentPayLog in Same Transaction as Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update fine detail — both `$fineDetail->update()` and `StudentPayLog::create()` inside same `DB::transaction()` | Both succeed or both fail |
| 2 | If update succeeds but PayLog create fails (e.g., DB error) | Transaction rolls back — update also reverted |
| 3 | **Verify**: Atomic consistency between fine detail update and audit log | No orphan state |

### TC-D09: destroyData Deletes PayLog Permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create StudentPayLog for a fine detail action | Log exists |
| 2 | DELETE `/student-pay-log/{logId}` | Call to destroyData |
| 3 | **Verify**: `StudentPayLog::findOrFail($logId)` | Log found |
| 4 | **Verify**: `$log->delete()` | Permanently deleted (soft deletes may not apply) |
| 5 | **Verify**: JSON response `{status: true, message: 'Log deleted successfully'}` | 200 OK |
| 6 | **DB Check**: StudentPayLog record removed | No longer exists |

### TC-D10: Copy-Paste Bug Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a fine detail | GET `/fine-detail/{id}/restore` |
| 2 | Fetch last StudentPayLog | `SELECT * FROM student_pay_logs ORDER BY id DESC LIMIT 1` |
| 3 | **Verify**: `activity_type = 'fine_master_restored'` | Should be `'fine_detail_restored'` |
| 4 | **Verify**: `reference_table = 'tpt_fine_master'` | Should be `'tpt_student_fine_detail'` |
| 5 | ForceDelete a fine detail | DELETE `/fine-detail/{id}/force-delete` |
| 6 | Fetch last StudentPayLog | Same query |
| 7 | **Verify**: `activity_type = 'fine_master_deleted'` | Should be `'fine_detail_deleted'` |
| 8 | **Verify**: `reference_table = 'tpt_fine_master'` | Should be `'tpt_student_fine_detail'` |

### TC-CR01: Blade Tab Visibility — @can('viewAny')

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `stdroutefeesmgmt.blade.php` | Tab layout file |
| 2 | Search for `@can('tenant.fine-detail.viewAny')` | Tab registration line 26 for tab, line 43 for include |
| 3 | `@can` directive controls both tab button AND content | Fine Detail tab hidden entirely if user lacks viewAny |
| 4 | **Verify**: Tab button text "Fine Detail" | Correct tab label |
| 5 | **Verify**: Tab content `@include('transport::fine-details.index')` | Wrapped in same @can |

### TC-CR02: Blade Trash Button — @canany('status')

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `fine-details/index.blade.php:71` | `@canany(['tenant.fine-detail.status'])` |
| 2 | Trash button: `<a href="{{ route('transport.fine-detail.trashed') }}" class="btn btn-sm btn-danger">` | Visible only when user has `status` permission |
| 3 | **Semantic Mismatch**: Trash button should be guarded by `restore`, not `status` | The `status` permission exists but toggleStatus() does not exist |

### TC-CR05: Gates Present on All Methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptStudentFineDetailController.php` | Full file |
| 2 | Check each public method for `Gate::authorize()` | All 11 methods have it: index(L24), create(L40), store(L58), show(L69), edit(L83), update(L101), destroy(L147), trashed(L183), restore(L199), forceDelete(L236), destroyData(L267) |
| 3 | All gates match their respective permissions | Correct mapping |

### TC-CR10: DB Transaction in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` lines 99-138 | Method body |
| 2 | Line 105: `DB::transaction(function () use ($request, $fineDetail) {` | Transaction start |
| 3 | Lines 107-132: All operations inside closure | Fine detail update, PayLog create, activityLog |
| 4 | Line 135-137: Redirect occurs AFTER transaction commits | Outside closure |
| 5 | **Verify**: Atomicity — all-or-nothing for update+PayLog+activityLog | Consistent state |

### TC-CR11: OnlyTrashed for Restore and ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `restore()` line 201-202 | `TptStudentFineDetail::onlyTrashed()->findOrFail($id)` |
| 2 | Open `forceDelete()` line 238-239 | `TptStudentFineDetail::onlyTrashed()->findOrFail($id)` |
| 3 | Both use `onlyTrashed()` → only find records where `deleted_at IS NOT NULL` | Cannot operate on active records |
| 4 | **Verify**: Active (non-deleted) records get 404 | ModelNotFoundException |

### TC-CR15: Routes Verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php:277-285` | Route definitions |
| 2 | Line 277: `Route::resource('fine-detail', ...)` | CRUD routes (index, create, store, show, edit, update, destroy) |
| 3 | Line 278-279: `Route::get('fine-detail-trashed', ...)->name('fine-detail.trashed')` | Trash list |
| 4 | Line 280-281: `Route::get('fine-detail/{id}/restore', ...)->name('fine-detail.restore')` | Restore |
| 5 | Line 282-283: `Route::delete('fine-detail/{id}/force-delete', ...)->name('fine-detail.forceDelete')` | Force delete |
| 6 | Line 285: `Route::delete('student-pay-log/{id}', ...)->name('student-pay-log.destroy')` | PayLog delete |
| 7 | `Route::resource` auto-names: index as `fine-detail.index`, etc. | All route names with `transport.` prefix from route group |

### TC-CR20: Model Table Name and SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptStudentFineDetail.php:16` | `protected $table = 'tpt_student_fine_detail'` |
| 2 | Open `TptStudentFineDetail.php:11` | `use HasFactory, SoftDeletes` |
| 3 | `SoftDeletes` trait enables `deleted_at` column | `destroy()` calls `->delete()` → soft delete |
| 4 | **Verify**: `trashed()` uses `onlyTrashed()` correctly | Scoped to soft-deleted records |

### TC-CR21: Model Fillable Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptStudentFineDetail.php:18-28` | `$fillable = ['student_fee_detail_id', 'fine_master_id', 'fine_days', 'fine_type', 'fine_rate', 'fine_amount', 'waved_fine_amount', 'net_fine_amount', 'remark']` |
| 2 | 9 fillable fields | All DB columns except id, timestamps, deleted_at |
| 3 | **Verify**: `student_fee_detail_id` and `fine_master_id` are fillable (required for create) | Correct |

### TC-CR22: Model Casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptStudentFineDetail.php:30-35` | `$casts = ['fine_rate' => 'decimal:2', 'fine_amount' => 'decimal:2', 'waved_fine_amount' => 'decimal:2', 'net_fine_amount' => 'decimal:2']` |
| 2 | 4 decimal casts with precision 2 | All monetary values cast |
| 3 | **Note**: No cast for fine_days (TINYINT), fine_type (ENUM), remark (string) | Raw values from DB |

### TC-CR25: DDL Column Name Discrepancy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL migration for column `Remark` | DDL says `Remark` VARCHAR(512) (uppercase R) |
| 2 | Check model fillable `'remark'` | Lowercase r |
| 3 | Check update() line 115: `'remark' => $request->remark` | Lowercase |
| 4 | MySQL default collation `utf8mb4_general_ci` is case-insensitive | Works on MySQL |
| 5 | **Note**: On case-sensitive collations or PostgreSQL, this mismatch would cause column-not-found error | Portability risk |

### TC-CR27: toggleStatus() Missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search `TptStudentFineDetailController.php` for `toggleStatus` | **NOT FOUND** |
| 2 | Search `web.php` for `fine-detail.*toggle-status` | **NOT FOUND** |
| 3 | Compare with other Transport controllers (e.g., `FineCategoryController` has `toggleStatus()` at line 138) | Missing feature |
| 4 | Policy has `status()` gate method (line 29-32) | Gate defined but no controller method uses it |
| 5 | `$crud` includes `status` in `permissionslist.php:331` | Permission registered but unused |
| 6 | Blade uses `@canany(['tenant.fine-detail.status'])` for Trash button | Only usage of `status` permission — semantic mismatch |

### TC-CR28: Trash Button Permission Semantic Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `fine-details/index.blade.php:71` | `@canany(['tenant.fine-detail.status'])` |
| 2 | Open `fine-details/index.blade.php:74` | Trash link to `route('transport.fine-detail.trashed')` |
| 3 | The `status` permission controls trash page access | Should be `restore` permission |
| 4 | **Validation**: If user has `status` but NOT `restore` → sees trash button but trashed page returns 403 | Confusing UX — button leads to 403 |
| 5 | **Validation**: If user has `restore` but NOT `status` → cannot see trash button, cannot navigate to trash | Missing access despite having permission |

### TC-BIZ-DEEP-12: Update Method uses DB::transaction but destroy does not

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` lines 100-138 | Uses `DB::transaction()` for consistency |
| 2 | Open `destroy()` lines 145-174 | **NO** `DB::transaction()` — PayLog created before delete without transaction |
| 3 | **Inconsistency**: update uses transaction, destroy does not | Destroy can create orphan PayLog |

### TC-BIZ-DEEP-13: StudentPayLog reference_table inconsistency

| Step # | Method | reference_table | Correct? |
|--------|--------|-----------------|----------|
| 1 | update() | `'tpt_fine_details'` (line 125) | Mix of fine_details vs tpt_student_fine_detail — non-standard |
| 2 | destroy() | `'tpt_fine_details'` (line 159) | Same non-standard |
| 3 | restore() | `'tpt_fine_master'` (line 213) | **WRONG** — copy-paste bug |
| 4 | forceDelete() | `'tpt_fine_master'` (line 249) | **WRONG** — copy-paste bug |
| 5 | Standard convention: should be `'tpt_student_fine_detail'` | All 4 are non-standard | Consistency issue |

### TC-BIZ-DEEP-14: feeMaster->academicSession Chain Depth

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 112: `$item->feeMaster->academicSession->academicSession->name ?? '-'` | 3-level deep relation chain |
| 2 | `feeMaster` → BelongsTo TptFeeMaster | TptFeeMaster model |
| 3 | `->academicSession` → BelongsTo AcademicSession | On TptFeeMaster |
| 4 | `->academicSession` → BelongsTo AcademicSession | Possibly nested relation name collision |
| 5 | If any link in chain is null, `?? '-'` falls back | Null-safe display |

### TC-BIZ-DEEP-15: Fine Rule Display Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 124-126: `{{ abs($item->fineMaster->fine_from_days) ?? '' }} - {{ abs($item->fineMaster->fine_to_days) ?? '' }} days` | Shows range |
| 2 | Uses `abs()` on fine_from_days and fine_to_days | Handles negative values (if any) |
| 3 | If `fineMaster` is null → `null->fine_from_days` error | **Potential error** if fineMaster relationship missing |

### TC-BIZ-DEEP-16: Fine Amount Formatting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 133-135: `₹ {{ number_format($item->fine_amount, 2) }}` | `₹ 100.00` format |
| 2 | Same format for waved (line 138) and net fine (line 142) | Consistent formatting |
| 3 | `number_format` adds thousands separator | e.g., `₹ 1,000.00` |

### TC-BIZ-DEEP-17: destroy() Has No DB Transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` lines 145-174 | Full method |
| 2 | Line 152-162: StudentPayLog::create() | Creates log entry |
| 3 | Line 164: $fineDetail->delete() | Soft deletes record |
| 4 | No `DB::transaction()` wrapping these 2 operations | If line 164 fails, line 152-162 is NOT rolled back |
| 5 | **Compare** with `update()` which uses `DB::transaction()` | Inconsistent pattern — update is atomic, destroy is not |

### TC-BIZ-DEEP-18: Show View at transport::fine-details.show

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller `show()` line 73 returns `transport::fine-details.show` | View path |
| 2 | `$record` variable is `TptStudentFineDetail::findOrFail($id)` | Single model |
| 3 | Show page shows: Academic Session, Fee Month, Fine Days, Fine Type, Fine Rate, Fine Amount, Waived Fine, Net Fine, Remark, Created At | All fields via `$record` |
| 4 | Show page also shows linked Fee Master summary | `$record->feeMaster` relation |

### TC-BIZ-DEEP-19: Trash View at transport::fine-details.trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller `trashed()` line 189 returns `transport::fine-details.trash` | View path |
| 2 | `$data` is paginated collection of onlyTrashed records | Only soft-deleted |
| 3 | Table: Session, Month, Delay Days, Fine Type, Fine Amount, Net Fine, Status (Deleted), Action | Columns match |

### TC-BIZ-DEEP-20: Flash Message Keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | update() line 137: `flash('updated.fine_detail')` | Flash key in session |
| 2 | destroy() line 173: `flash('trashed.fine_detail')` | Flash key |
| 3 | restore() line 226: `flash('restored.fine_detail')` | Flash key |
| 4 | forceDelete() line 262: `flash('force_deleted.fine_detail')` | Flash key |
| 5 | Flash keys likely defined in language files (e.g., `transport.php`) | Translation support |

### TC-BIZ-DEEP-21: Model feeDetail() vs feeMaster() — Same FK, Different Targets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `feeDetail()` line 44-50: `belongsTo(TptStudentFeeDetail::class, 'student_fee_detail_id')` | Targets TptStudentFeeDetail |
| 2 | `feeMaster()` line 56-62: `belongsTo(TptFeeMaster::class, 'student_fee_detail_id')` | Targets TptFeeMaster |
| 3 | Both use same FK `student_fee_detail_id` | Same column, different related models |
| 4 | `TptStudentFeeDetail` class may not exist | If missing, feeDetail() crashes at runtime |
| 5 | Controller uses `feeMaster` exclusively | `feeDetail()` is unused in controller |

### TC-BIZ-DEEP-22: feeCollection() Relationship with Custom Local Key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `feeCollection()` line 78-85: `belongsTo(TptStudentFeeCollection::class, 'student_fee_detail_id', 'student_fee_detail_id')` | Custom local key matching FK |
| 2 | Third arg `'student_fee_detail_id'` is the local key on FeeCollection | Non-standard BelongsTo — both FK and local key are same column name |

### TC-BIZ-DEEP-23: Permission 403 on Tab — viewAny Hides Entire Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.fine-detail.viewAny` | User cannot view fine details |
| 2 | Navigate to `/std-route-Fees-mgmt?tab=fine_detail` | Tab button not rendered |
| 3 | Direct access via URL param `?tab=fine_detail` | Tab content hidden by `@can` directive |

### TC-BIZ-DEEP-24: Permission 403 on Action Column — Fine-grained Control

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with viewAny but NO edit/delete/view | User sees table but NO action column |
| 2 | `@canany(['edit','delete','view'])` at line 102, 146 | Action column hidden |
| 3 | User can see data but cannot interact | Read-only view |

### TC-BIZ-DEEP-25: Action Component Uses Generic Helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 148-151: `<x-backend.table.action :id="$item->id" url="transport.fine-detail" permissions="tenant.fine-detail" />` | Generic action component |
| 2 | Component renders view/edit/delete links based on permissions | Auto-generated from route name and permission prefix |
| 3 | `url="transport.fine-detail"` maps to route `transport.fine-detail.show`, `.edit`, `.destroy` | Consistent with resource route names |

### TC-BIZ-DEEP-26: Action-Trais Component in Trash View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Trash blade line 86: `url="transport.fine-detail" permissions="tenant.fine-detail"` | Same component in trash |
| 2 | Trash action component shows restore/forceDelete buttons | Different actions than main list |

### TC-BIZ-DEEP-27: DDL ENUM vs Model Fillable — fine_type Must Match ENUM Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL: `ENUM('Fixed','Percentage') DEFAULT 'Fixed'` | Two allowed values |
| 2 | Model fillable includes `'fine_type'` | Can be mass-assigned |
| 3 | No validation in controller — any value can be sent | MySQL strict mode rejects invalid ENUM |
| 4 | If MySQL is in non-strict mode, invalid ENUM silently becomes '' | Data integrity issue |

### TC-BIZ-DEEP-28: DDL RESTRICT FK Prevents Cascade Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine detail with student_fee_detail_id=1 | FK reference exists |
| 2 | Try to DELETE from `tpt_student_fee_detail WHERE id=1` | RESTRICT constraint — `Cannot delete or update a parent row: a foreign key constraint fails` |
| 3 | Same behavior for fine_master_id | Cannot delete fine master if fine details reference it |

### TC-BIZ-DEEP-29: DestroyData URL /student-pay-log/{id}

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route line 285: `/student-pay-log/{id}` | Outside resource group |
| 2 | Method: DELETE | Destructive action |
| 3 | `destroyData()` returns JSON | API-style endpoint |
| 4 | Used by frontend to delete a specific PayLog entry | AJAX call with JSON response |

### TC-BIZ-DEEP-30: Store View Does Not Exist — Create Button Not Rendered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check filesystem: `resources/views/fine-detail/create.blade.php` | **FILE DOES NOT EXIST** |
| 2 | Controller `create()` line 46 tries to load `transport::fine-detail.create` | Would throw `ViewNotFoundException` |
| 3 | No "Add Fine Detail" button in blade | No UI pathway to create() |
| 4 | **Impact**: Fine details can only be created via FeeCollection flow | Standalone create is dead code |

### TC-BIZ-DEEP-31: Update Does NOT Change fine_days Calculation Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update() simply stores `$request->fine_days` as-is | No recalculation logic |
| 2 | fine_days is user-supplied, not auto-calculated from dates | Manual entry |
| 3 | No business logic to compute delay days in controller | Simple pass-through |

### TC-BIZ-DEEP-32: StudentPayLog table schema assumptions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `StudentPayLog::create([...])` — fields used: student_id, academic_session_id, module_name, amount, activity_type, reference_id, reference_table, description, triggered_by | 9 fields |
| 2 | `module_name` always `'Transport'` | Hardcoded string |
| 3 | No `log_date` field being set explicitly | May auto-set via timestamps |

### TC-BIZ-DEEP-33: Gate::authorize Uses Tenant-Prefixed Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Gate::authorize('tenant.fine-detail.viewAny')` | Standard tenant prefix |
| 2 | All 7 gate calls use correct `tenant.fine-detail.*` pattern | Consistent |
| 3 | Permission string matches `permissionslist.php:331` where `'fine-detail' => $crud` | Correct registration |

### TC-BIZ-DEEP-34: Policy Methods vs Controller Gates — Direct Mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Policy defines: viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print, waive, apply, viewReports, bulkApply | 15 policy methods |
| 2 | Controller uses: viewAny, view, create, update, delete, restore, forceDelete, delete (for destroyData) | 8 gate calls (delete used twice) |
| 3 | Unused policy methods: status, import, export, print, waive, apply, viewReports, bulkApply | 8 methods never called |

### TC-BIZ-DEEP-35: Controller Comments Indicate Developer Awareness

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | destroy() line 151: `/** 🔥 PAY LOG (Fee master is NOT student based) */` | Developer notes FK concern |
| 2 | forceDelete() line 241: Same comment | Repeated awareness |
| 3 | **Implication**: Developer knew the data model limitation but did not fix it | Known issue |

### TC-BIZ-DEEP-36: StudentPayLog amount Uses Current Value Post-Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | update() line 122: `'amount'=> $fineDetail->fine_amount` | Uses value AFTER `$fineDetail->update()` |
| 2 | Since model is already updated, `$fineDetail->fine_amount` is the new value | Log records updated amount, not original |
| 3 | For destroy (line 158): `'amount'=> $fineDetail->fine_amount` | Uses current fine_amount before delete |

### TC-BIZ-DEEP-37: No Batch Operations Supported

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller has no bulk update/destroy/restore methods | Single-record operations only |
| 2 | `destroy()` takes single $id | No array of IDs |
| 3 | `forceDelete()` takes single $id | Same |
| 4 | Policy defines `bulkApply()` but controller never calls it | Dead policy method |

### TC-BIZ-DEEP-38: Remark Column in DDL Uses Uppercase 'R' — MySQL Compat

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL: `Remark VARCHAR(512) DEFAULT NULL` | Capital R |
| 2 | Laravel/Eloquent converts column names to lowercase by default | PDO reads as lowercase |
| 3 | `$fillable = ['remark']` works because MySQL is case-insensitive | No issue |
| 4 | If strict case-sensitive collation: mismatch would cause error | Theoretically possible |

### TC-BIZ-DEEP-39: All Monetary Fields Use decimal:2 Cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | fine_rate: decimal:2 | rate precision 2 |
| 2 | fine_amount: decimal:2 | amount precision 2 |
| 3 | waved_fine_amount: decimal:2 | waived precision 2 |
| 4 | net_fine_amount: decimal:2 | net precision 2 |
| 5 | All 4 monetary fields consistently cast | Prevents float precision issues |

### TC-BIZ-DEEP-40: Pagination Size Differs: Index 10 vs Standalone Index 20

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab hub `fineDetailsQuery()` → `paginate(10)` | 10 per page |
| 2 | Controller `index()` → `paginate(20)` | 20 per page |
| 3 | Inconsistency: Different page sizes depending on entry point | User experience difference |

### TC-BIZ-DEEP-41: SoftDelete Restore Activity Uses 'Restored' Event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | restore() line 220: `activityLog($fineDetail, 'Restored', [...])` | Event string 'Restored' |
| 2 | Consistent with other controllers | Standard event naming |

### TC-BIZ-DEEP-42: ForceDelete Uses 'Force Deleted' (with Space)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | forceDelete() line 256: `activityLog($fineDetail, 'Force Deleted', [...])` | Event string has space |
| 2 | Other controllers use 'Force Deleted' pattern | Consistent naming |

### TC-BIZ-DEEP-43: No Custom Flash Messages — Uses flash() Helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `flash('updated.fine_detail')` | Key-based lookup |
| 2 | `flash('trashed.fine_detail')` | Translation key |
| 3 | `flash('restored.fine_detail')` | Translation key |
| 4 | `flash('force_deleted.fine_detail')` | Translation key |
| 5 | Hardcoded strings are avoided — uses translation system | Good practice |

### TC-BIZ-DEEP-44: redirect()->back() in destroy() — Unique Pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | destroy() line 171: `return redirect()->back()` | Back to previous page |
| 2 | All other CRUD methods use `redirect()->route('transport.std-route-Fees-mgmt.index')` | To index |
| 3 | **Note**: `redirect()->back()` preserves query parameters (tab state) | Browser back behavior |

### TC-BIZ-DEEP-45: Blade Pagination Uses `->withQueryString()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Tab hub at `StudentRouteFeesController.php:81` | `->paginate(10)->withQueryString()` |
| 2 | Blade `index.blade.php:173` | `$fineDetails->withQueryString()->links()` |
| 3 | Query string filters (std_academic_sessions_id, month, fine_type) preserved in pagination links | Correct UX |

### TC-BIZ-DEEP-46: Blade Empty State colspan=10

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `index.blade.php:157`: `colspan="10"` | 10 columns in table |
| 2 | Columns: Session, Month, Fine Rule, Delay Days, Fine Type, Fine Amount, Waived, Net Fine, Remark, Action | 10 columns |
| 3 | colspan matches column count | Correct |

### TC-BIZ-DEEP-47: Filter Reset Link Uses `url()->current()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 61: `<a href="{{ url()->current() }}" class="btn btn-secondary">` | Reset button |
| 2 | `url()->current()` returns URL without query params | Clears all filters |
| 3 | Tab param `?tab=fine_detail` is also removed | May reset to first tab on page reload |

### TC-BIZ-DEEP-48: Fine Type Filter Has Only Two Options

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade lines 47-52: `<option value="Fixed">Fixed</option> <option value="Percentage">Percentage</option>` | Two options |
| 2 | Matches DDL ENUM('Fixed','Percentage') | Correctly limited |

### TC-BIZ-DEEP-49: No Search Input in Fine Detail Blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare with PickupStopsList which has search input | Fine Detail has no text search field |
| 2 | Only 3 filter dropdowns: Session, Month, Fine Type | No free-text search |

### TC-BIZ-DEEP-50: Month Filter Uses Numeric Month (1-12)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade lines 34-38: `range(1,12)` generates numeric months | 1=January...12=December |
| 2 | `date('F', mktime(0,0,0,$m,1))` converts to month name | "January", "February", etc. |
| 3 | feeMaster stores month as integer? | Assuming `feeMaster.month` is INT |

### TC-BIZ-DEEP-51: Policy status() Gate Method Defined but Never Invoked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportFineDetailPolicy.php:29-32` | `status()` method returns `$user->can('tenant.fine-detail.status')` |
| 2 | Controller has NO toggleStatus() that would invoke this gate | Never called via controller |
| 3 | Blade uses `@canany(['tenant.fine-detail.status'])` which calls `Gate::allows('status')` | Only use of this gate is Blade-level |
| 4 | **Implication**: The policy method exists but only serves the Blade directive | Redundant — could use direct permission check |

### TC-BIZ-DEEP-52: Policy Methods waive/apply/viewReports/bulkApply — Dead Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Policy lines 101-103: `waive()`, lines 109-111: `apply()`, lines 117-119: `viewReports()`, lines 125-127: `bulkApply()` | 4 policy methods |
| 2 | Search controller + blades for any call to these | **No references** — not in `permissionslist.php` either |
| 3 | These are dead permissions — registered in policy but not assignable to roles | Dead code |

### TC-BIZ-DEEP-53: Blade @can('viewAny') Tab Guard vs Controller Gate — Double Protection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `stdroutefeesmgmt.blade.php:43`: `@can('tenant.fine-detail.viewAny')` | First guard — hides tab |
| 2 | `TptStudentFineDetailController@index()` line 24: `Gate::authorize('tenant.fine-detail.viewAny')` | Second guard — 403 on direct access |
| 3 | Both guards necessary: Blade prevents visible tab, controller prevents direct URL access | Defense in depth |

### TC-BIZ-DEEP-54: Fine Rule Display Uses abs() — Safe Display but Masks Data Issues

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 124: `{{ abs($item->fineMaster->fine_from_days) ?? '' }}` | `abs()` ensures non-negative display |
| 2 | If DB has negative `fine_from_days`, abs() hides the sign | Display sanitization |
| 3 | No corresponding abs() in controller logic | Display-only effect |

### TC-BIZ-DEEP-55: No Sortable Headers in Fine Detail Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Examine table header in `index.blade.php:92-105` | Plain `<th>` headers — no sort links |
| 2 | Controller `fineDetailsQuery()` uses `->latest()` | Ordered by created_at DESC only |
| 3 | No column sorting available | Fixed sort order |

### TC-BIZ-DEEP-56: Fine Amount Uses `number_format()` — Comma in Thousands

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 134: `number_format($item->fine_amount, 2)` | `1,000.00` format |
| 2 | Same for waved and net fine | Consistent formatting |
| 3 | Indian locale: `1,00,000` vs default `100,000` | Uses English thousands separator |

### TC-BIZ-DEEP-57: `optional()` Chain May Nullify FeeMaster Display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 112: `$item->feeMaster->academicSession->academicSession->name ?? '-'` | 4-level optional chain |
| 2 | If any level is null → `?? '-'` fallback | Display shows '-' instead of error |
| 3 | Fine Rule display line 124: No `??` on `fineMaster->fine_from_days` | **Potential error** if fineMaster is null |

### TC-BIZ-DEEP-58: Fine Rules Display Uses `abs()` Around Both Days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 124-126: `abs($fineMaster->fine_from_days)` and `abs($fineMaster->fine_to_days)` | Both values positive |
| 2 | Separator: ` - ` with space | `1 - 30 days` display |

### TC-BIZ-DEEP-59: delete Gate Reused for destroyData

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `destroyData()` line 267: `Gate::authorize('tenant.fine-detail.delete')` | Uses `delete` permission |
| 2 | Deleting a StudentPayLog is semantically different from deleting a fine detail | Permission reuse without semantic distinction |
| 3 | No separate `tenant.fine-detail.delete-pay-log` permission | Coarse-grained |

### TC-BIZ-DEEP-60: All StudentPayLogs Created with module_name='Transport'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All 4 StudentPayLog::create() calls set `'module_name' => 'Transport'` | Hardcoded |
| 2 | No dynamic module name detection | Valid — this is the Transport module |

### TC-BIZ-DEEP-61: StudentPayLog No Timestamp Fields Set Explicitly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All StudentPayLog::create() calls | No `created_at` or `log_date` set |
| 2 | Model likely uses timestamps or DB default | Auto-set by Eloquent/DB |

### TC-BIZ-DEEP-62: Update Does Not Allow fine_master_id Change — Fixed Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update array (lines 109-116) does NOT include `fine_master_id` | Cannot change fine rule |
| 2 | If fine rule was incorrectly assigned, must delete and recreate | Operational limitation |

### TC-BIZ-DEEP-63: Edit Form Not Accessible in Some Scenarios

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Action column uses `@canany(['edit','delete','view'])` | If user lacks all 3, no action column |
| 2 | User with `update` permission but NOT `edit` permission | Can PUT but cannot navigate to edit form |
| 3 | `edit()` uses `Gate::authorize('tenant.fine-detail.update')` | Gate uses `update` not `edit` |
| 4 | Blade guard uses `edit` permission | Mismatch: blade requires `edit`, gate checks `update` |

### TC-BIZ-DEEP-64: `edit` vs `update` Permission — Gate and Blade Mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller `edit()` line 83: `Gate::authorize('tenant.fine-detail.update')` | Uses `update` permission |
| 2 | Blade `index.blade.php:102`: `@canany(['tenant.fine-detail.edit', ...])` | Uses `edit` permission |
| 3 | `tenant.fine-detail.edit` permission exists in `$crud` | Both permissions defined |
| 4 | **Result**: User can have `edit` (see edit button) but not `update` (cannot submit form) | Confusing: visible button leads to 403 |
| 5 | **Result**: User can have `update` (can PUT) but not `edit` (no visible button to navigate) | Invisible functionality |

### TC-BIZ-DEEP-65: Fine Details Created via FeeCollection — No Standalone Pathway

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `store()` empty → no POST creation | Cannot create |
| 2 | `create()` view missing → no UI pathway | Cannot navigate to create |
| 3 | `FeeCollectionController@store()` is only creation pathway | Dependency on Fee Collection flow |

### TC-BIZ-DEEP-66: StudentPayLog Module Name Override — Future-Proofing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All StudentPayLog have `module_name='Transport'` | Identifies source module |
| 2 | If cross-module reporting needed, this field enables filtering | Future-proof field |

### TC-BIZ-DEEP-67: Update Does Not Include `fine_rate` in Update Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$fineDetail->update([...])` array items | fine_rate ABSENT |
| 2 | Once set during creation (via FeeCollection flow), fine_rate frozen | Cannot be corrected |

### TC-BIZ-DEEP-68: Update Also Omits `student_fee_detail_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update array at lines 109-116 | No student_fee_detail_id |
| 2 | Fee master association cannot be changed | Fixed after creation |

### TC-BIZ-DEEP-69: `redirect()->back()` in destroy Preserves Tab State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | destroy() uses `redirect()->back()` | Returns to referring URL |
| 2 | Referring URL includes `?tab=fine_detail` | User stays on correct tab |
| 3 | update/restore/forceDelete redirect to named route | Tab param must be appended or default tab shown |

### TC-BIZ-DEEP-70: StudentRouteFeesController Uses Different Query Pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `fineDetailsQuery()` returns query builder, controller calls `paginate(10)` | Builder pattern |
| 2 | `index()` in TptStudentFineDetailController calls `paginate(20)` directly | Direct pagination |
| 3 | Different pagination sizes (10 vs 20) | UX inconsistency |

### TC-BIZ-DEEP-71: `groupBy` in fineDetailsQuery Not Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `fineDetailsQuery()` uses `when()` filters + `latest()` | Simple filtered query |
| 2 | No `groupBy()` or aggregation | Plain record listing |

### TC-BIZ-DEEP-72: Academic Session Filter Uses whereHas — Efficient

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `fineDetailsQuery()` line 141-147: `whereHas('feeMaster', fn=>where('std_academic_sessions_id', ...))` | Subquery on relation |
| 2 | Avoids JOIN, uses EXISTS | Efficient filtering |

### TC-BIZ-DEEP-73: Month Filter Also Uses whereHas

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 148-152: `whereHas('feeMaster', fn=>where('month', ...))` | Same pattern as session filter |
| 2 | Both filters on feeMaster relation | Consistent query approach |

### TC-BIZ-DEEP-74: fine_type Filter Is Direct Column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 153-155: `where('fine_type', $request->fine_type)` | Direct column filter |
| 2 | No join needed — fine_type is on tpt_student_fine_detail itself | Simple WHERE |

### TC-BIZ-DEEP-75: `latest()` on fineDetailsQuery — Ordered by created_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 156: `->latest()` | Order by `created_at DESC` |
| 2 | Most recent fine details appear first | Natural ordering |

### TC-BIZ-DEEP-76: Standalone index() Also Uses latest()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `TptStudentFineDetailController@index()` line 27: `->latest()` | Same ordering |
| 2 | Consistent with tab hub | Aligned behavior |

### TC-BIZ-DEEP-77: No Export/Import Endpoints in Controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Policy defines import() and export() gates | Policy methods exist |
| 2 | Controller has NO import/export methods | Not implemented |
| 3 | If export route was created, it would use other controller | Dead policy methods |

### TC-BIZ-DEEP-78: No Print Endpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Policy: `print()` at line 95-98 | Print gate defined |
| 2 | No controller method for print | Unused |

### TC-BIZ-DEEP-79: All Activity Uses system_activity_log (via activityLog helper)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `activityLog($fineDetail, 'Updated', [...])` | Calls global helper |
| 2 | Stores: subject_type (model class), subject_id (model id), event, custom message | Standard format |
| 3 | All 4 state changes logged via this helper | Consistent audit trail |

### TC-BIZ-DEEP-80: destroyData Returns JSON — Non-standard for This Controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All other methods return views or redirects | HTML responses |
| 2 | destroyData returns `response()->json([...])` | JSON API-style response |
| 3 | Different response format from rest of controller | Inconsistent pattern |

### TC-BIZ-DEEP-81: No Authorization for `redirect()->back()` — Allowed by Design

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `redirect()->back()` | No additional auth |
| 2 | Output is a redirect response | Safe — no data leaked |

### TC-BIZ-DEEP-82: Flash Messages Not Checkable Directly — Require Session Assertion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Flash messages use Laravel `session()->flash()` | Stored in session |
| 2 | Test: `$response->assertSessionHas('success')` | Standard Laravel test assertion |
| 3 | Flash keys: `updated.fine_detail`, `trashed.fine_detail`, etc. | Key-based lookup |

### TC-BIZ-DEEP-83: All Redirects Use Named Routes (Except destroy)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | update: `route('transport.std-route-Fees-mgmt.index')` | Named route |
| 2 | restore: same | Same |
| 3 | forceDelete: same | Same |
| 4 | destroy: `redirect()->back()` | URL-based (not named) |
| 5 | Inconsistency: destroy does not use named route | Different behavior |

### TC-BIZ-DEEP-84: No URL Signatures or Signed Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All routes use standard GET/POST/DELETE | No signed URL support |
| 2 | All require authentication + permission | Standard protection |

### TC-BIZ-DEEP-85: Controller index() Returns View, Tab Hub Includes Partial

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Standalone index: returns `view('transport::fine-detail.index')` with `$data` (paginated) | Full page |
| 2 | Tab hub includes: `@include('transport::fine-details.index')` with `$fineDetails` | Partial view |
| 3 | Both use different variable names (`$data` vs `$fineDetails`) | Inconsistency |
| 4 | Both render similar tables | Layout difference |

### TC-BIZ-DEEP-86: Standalone Index View vs Tab Partial View — Different Paths

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Standalone: `transport::fine-detail.index` | Singular `fine-detail` directory |
| 2 | Tab include: `transport::fine-details.index` | Plural `fine-details` directory |
| 3 | Different view files may exist | May be different files |

### TC-BIZ-DEEP-87: destroyData Uses findOrFail — 404 on Invalid PayLog ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `StudentPayLog::findOrFail($id)` at line 269 | If not found → ModelNotFoundException → 404 |
| 2 | No custom error handling | Standard 404 response |

### TC-BIZ-DEEP-88: All update Fields Use Direct Request Input — No Sanitization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$request->fine_days` | Raw input |
| 2 | `$request->fine_amount` | Raw input |
| 3 | `$request->fine_type` | Raw input |
| 4 | `$request->waved_fine_amount` | Raw input |
| 5 | `$request->remark` | Raw input |
| 6 | No `strip_tags()`, `trim()`, `cast`, or `filter_var()` | Completely unprocessed |

### TC-BIZ-DEEP-89: `waved_fine_amount` Defaults to 0 — Typo in Column Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL and model: column name `waved_fine_amount` | Should be `waived_fine_amount` (missing 'i') |
| 2 | Consistently misspelled throughout codebase | Known typo |
| 3 | Cannot be renamed without migration | Database-level typo |

### TC-BIZ-DEEP-90: `waved_fine_amount` Typo Propagates to Views and PayLog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Model fillable: `waved_fine_amount` | Typo |
| 2 | Controller update line 113: `waved_fine_amount` | Typo |
| 3 | Blade line 138: `$item->waved_fine_amount` | Typo |
| 4 | Entire codebase uses same misspelling | Consistent typo |

---

## 10. Appendix: CODE-TRACE Reference — Controller Line-by-Line Trace

```
TptStudentFineDetailController.php (277 lines)

  INDEX (lines 22-31):
    ├── Gate::authorize('tenant.fine-detail.viewAny')        [L24]
    ├── TptStudentFineDetail::with(['feeMaster', 'fineMasterRule'])
    │   └── ⚠ fineMasterRule NOT DEFINED on model            [L26]
    ├── ->latest()->paginate(20)                              [L27-28]
    └── return view('transport::fine-detail.index', compact('data')) [L30]

  CREATE (lines 38-49):
    ├── Gate::authorize('tenant.fine-detail.create')          [L40]
    ├── TptFeeMaster::latest()->get()                         [L42]
    ├── TptFineMaster::latest()->get()                        [L43]
    └── return view('transport::fine-detail.create', ...)     [L45-48]
        └── ⚠ VIEW NOT FOUND (directory missing)

  STORE (lines 56-60):
    ├── Gate::authorize('tenant.fine-detail.create')          [L58]
    └── ⚠ EMPTY — no implementation                          [L60]

  SHOW (lines 67-74):
    ├── Gate::authorize('tenant.fine-detail.view')            [L69]
    ├── TptStudentFineDetail::findOrFail($id)                 [L71]
    └── return view('transport::fine-details.show', ...)      [L73]

  EDIT (lines 81-91):
    ├── Gate::authorize('tenant.fine-detail.update')          [L83]
    │   └── ⚠ uses "update" gate, NOT "edit"
    ├── TptStudentFineDetail::findOrFail($id)                 [L85]
    ├── TptFineMaster::latest()->get()                        [L86]
    └── return view('transport::fine-details.edit', ...)      [L88-90]

  UPDATE (lines 99-138):
    ├── Gate::authorize('tenant.fine-detail.update')          [L101]
    ├── TptStudentFineDetail::findOrFail($id)                 [L103]
    └── DB::transaction(function () use (...) {               [L105]
        ├── $netFine = $request->fine_amount - ($request->waved_fine_amount ?? 0)  [L107]
        ├── $fineDetail->update([                             [L109-116]
        │   ├── fine_days, fine_amount, fine_type,
        │   ├── waved_fine_amount, net_fine_amount,
        │   └── remark
        │   └── ⚠ NO validation rules before update
        │])                                                   
        ├── StudentPayLog::create([                           [L118-128]
        │   ├── activity_type => 'fine_deatils_updated'      ⚠ TYPO
        │   ├── reference_table => 'tpt_fine_details'
        │   └── description => 'Transport fine setails ter updated' ⚪ TYPOS
        │])
        └── activityLog($fineDetail, 'Updated', [...])        [L130-132]
    })
    ├── return redirect()->route(...)->with('success', ...)   [L135-137]

  DESTROY (lines 145-174):
    ├── Gate::authorize('tenant.fine-detail.delete')          [L147]
    ├── TptStudentFineDetail::findOrFail($id)                 [L149]
    ├── StudentPayLog::create([...])    ⚠ BEFORE delete      [L152-162]
    │   └── activity_type => 'fine_details_deleted'
    ├── $fineDetail->delete()                                 [L164]
    ├── activityLog($fineDetail, 'Trashed', [...])            [L166-168]
    └── return redirect()->back()->with('success', ...)       [L171-173]
        └── ⚠ NOT inside DB::transaction (orphan risk)

  TRASHED (lines 181-190):
    ├── Gate::authorize('tenant.fine-detail.restore')         [L183]
    ├── TptStudentFineDetail::onlyTrashed()->latest('deleted_at')->paginate(20)  [L185-187]
    └── return view('transport::fine-details.trash', ...)     [L189]

  RESTORE (lines 197-227):
    ├── Gate::authorize('tenant.fine-detail.restore')         [L199]
    ├── TptStudentFineDetail::onlyTrashed()->findOrFail($id)  [L201-202]
    ├── $fineDetail->restore()                                [L204]
    ├── StudentPayLog::create([                               [L207-217]
    │   ├── activity_type => 'fine_master_restored'          ⚠ COPY-PASTE BUG
    │   └── reference_table => 'tpt_fine_master'             ⚠ COPY-PASTE BUG
    │])
    ├── activityLog($fineDetail, 'Restored', [...])           [L220-222]
    └── return redirect()->route(...)->with('success', ...)   [L224-226]

  FORCE DELETE (lines 234-263):
    ├── Gate::authorize('tenant.fine-detail.forceDelete')     [L236]
    ├── TptStudentFineDetail::onlyTrashed()->findOrFail($id)  [L238-239]
    ├── StudentPayLog::create([                               [L242-251]
    │   ├── activity_type => 'fine_master_deleted'           ⚠ COPY-PASTE BUG
    │   └── reference_table => 'tpt_fine_master'             ⚠ COPY-PASTE BUG
    │])
    ├── $fineDetail->forceDelete()                            [L254]
    ├── activityLog($fineDetail, 'Force Deleted', [...])      [L256-258]
    └── return redirect()->route(...)->with('success', ...)   [L260-262]

  DESTROY DATA (lines 265-276):
    ├── Gate::authorize('tenant.fine-detail.delete')          [L267]
    ├── StudentPayLog::findOrFail($id)                        [L269]
    ├── $log->delete()                                        [L270]
    ├── ⚠ NO activityLog() call
    └── return response()->json([status: true, message: ...]) [L272-275]
```

## 11. Appendix: Model Source Trace

```
TptStudentFineDetail.php (86 lines)

  TABLE:      protected $table = 'tpt_student_fine_detail'     [L16]
  FILLABLE:   [9 fields] student_fee_detail_id, fine_master_id,
              fine_days, fine_type, fine_rate, fine_amount,
              waved_fine_amount, net_fine_amount, remark         [L18-28]
  CASTS:      [4 decimal:2] fine_rate, fine_amount,
              waved_fine_amount, net_fine_amount                [L30-35]

  RELATIONSHIPS:
    feeDetail()       → BelongsTo TptStudentFeeDetail           [L44-50]
                        ⚠ Class may not exist
    feeMaster()       → BelongsTo TptFeeMaster                  [L56-62]
    fineMaster()      → BelongsTo TptFineMaster                 [L67-73]
    feeCollection()   → BelongsTo TptStudentFeeCollection       [L78-85]
                        custom FK→local: student_fee_detail_id

  ⚠ MISSING RELATIONSHIP:
    fineMasterRule()  → NOT DEFINED
                        Referenced in controller index() line 26
                        Would cause BadMethodCallException
```

## 12. Reference Index

| Section | Content | Lines |
|---------|---------|-------|
| 1 | Feature Information | ~7-22 |
| 2 | Pre-conditions | ~25-35 |
| 3 | Default Data Load | ~38-49 |
| 4 | Test Data Strategy | ~52-68 |
| 5 | Business Conditions (BC-DB/BC-VAL/BC-AUTH/BC-BIZ/BC-REL/BC-REF) | ~71-170 |
| 6.1 | TC-P: Positive Test Cases | ~173-195 |
| 6.2 | TC-N: Negative Test Cases | ~198-220 |
| 6.3 | TC-D: Dependency Test Cases | ~223-233 |
| 6.4 | TC-CR: Code Review Test Cases | ~236-270 |
| 7 | Detailed Test Steps | ~273+ |
| 8 | Test Data Factory / Seed Blueprint | ~1212-1241 |
| 9 | Known Bugs / Gaps Summary | ~1245-1263 |
| 10 | Appendix: CODE-TRACE Controller Trace | ~1265+ |
| 11 | Appendix: Model Source Trace | ~1265+ |
| 12 | Reference Index | ~1265+ |

---

## 8. Test Data Factory / Seed Blueprint

### Create Fine Detail for Direct Testing

```php
$feeMaster = TptFeeMaster::factory()->create([
    'std_academic_sessions_id' => 1,
    'month' => 7,
    'total_amount' => 1000.00,
]);

$fineMaster = TptFineMaster::factory()->create([
    'fine_from_days' => 1,
    'fine_to_days' => 30,
    'fine_type' => 'Fixed',
    'fine_rate' => 50.00,
]);

$fineDetail = TptStudentFineDetail::create([
    'student_fee_detail_id' => $feeMaster->id,
    'fine_master_id' => $fineMaster->id,
    'fine_days' => 10,
    'fine_type' => 'Fixed',
    'fine_rate' => 50.00,
    'fine_amount' => 500.00,
    'waved_fine_amount' => 0.00,
    'net_fine_amount' => 500.00,
    'remark' => 'Test fine detail',
]);
```

---

## 9. Known Bugs / Gaps Summary

| # | Bug/Gap | Severity | BC/TC Reference |
|---|---------|----------|-----------------|
| 1 | `store()` is empty — cannot create fine details via standalone controller | High | BC-BIZ-01, TC-CR08 |
| 2 | `update()` has NO validation — any data accepted | High | BC-VAL-01-05, TC-CR09 |
| 3 | `index()` uses undefined `fineMasterRule` relationship | Critical | BC-BIZ-17, TC-D04, TC-CR26 |
| 4 | Activity type typo `fine_deatils_updated` | Medium | BC-BIZ-04, TC-CR13 |
| 5 | Description typo `Transport fine setails ter updated` | Low | TC-CR14 |
| 6 | Copy-paste bug: restore/forceDelete reference `tpt_fine_master` instead of `tpt_student_fine_detail` | High | TC-CR29, TC-D10 |
| 7 | Copy-paste bug: restore/forceDelete activity_type says `fine_master_*` instead of `fine_detail_*` | High | TC-CR29 |
| 8 | `destroyData()` has no `activityLog()` call | Medium | TC-CR30 |
| 9 | Trash button uses `status` permission instead of `restore` | Medium | BC-BIZ-19, TC-CR28 |
| 10 | `toggleStatus()` method missing — `status` permission never used in controller | Low | BC-BIZ-18, TC-CR27 |
| 11 | `destroy()` creates StudentPayLog BEFORE delete without transaction (orphan risk) | Medium | TC-CR33 |
| 12 | create view directory does not exist | High | TC-BIZ-DEEP-30 |
| 13 | Model column name mismatch: DDL `Remark` vs model `remark` | Low | TC-CR25 |
| 14 | `destroyData()` only returns success response (no error handling) | Low | TC-BIZ-DEEP-06 |
| 15 | `feeDetail()` relationship may reference non-existent class | Medium | TC-BIZ-DEEP-10 |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: FineDetail | Date: 2026-07-21*
