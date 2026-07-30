# Fine Master — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Tab Group** | Transport Master → Fine Master |
| **Feature** | Fine Master (Fine Rules configuration) |
| **URL(s)** | `/transport/transport-master` (index via tab `fine_master`), `/transport/fine-master/create`, `/transport/fine-master/{id}` (show), `/transport/fine-master/{id}/edit`, `/transport/fine-master/trash/view`, `/transport/fine-master/{id}/restore`, `/transport/fine-master/{id}/force-delete` |
| **Controller** | `Modules\Transport\Http\Controllers\FineMasterController` — 10 methods — ⚠️ `index()` NOT called for tab listing; standalone route only |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab id `fine_master`, private `fineMasterQuery()` for listing |
| **Model(s)** | `Modules\Transport\Models\TptFineMaster` — SoftDeletes, 2 relationships (fineCategory, academicSession) |
| **Validation** | `Modules\Transport\Http\Requests\FineMasterRequest` — 6 rules + custom percentage validation + prepareForValidation (number_format + boolean normalization) |
| **Permissions** | `tenant.fine-master.*` (viewAny, view, create, update, delete, restore, forceDelete) |
| **Soft Deletes** | Yes (`TptFineMaster` uses `SoftDeletes` trait) |
| **Activity Log** | Events: `Created`, `Updated`, `Deleted`, `Restored`, `Force Deleted` |
| **DB Table** | `tpt_fine_master` — 12 columns (id, fine_category_id, std_academic_sessions_id, fine_from_days, fine_to_days, fine_type, fine_rate, student_restricted, Remark, created_at, updated_at, deleted_at) + FK `fk_fm_fine_category` ON DELETE RESTRICT |
| **Key Business Rules** | Fixed/Percentage fine type, student_restricted flag, current academic session auto-assigned, fine_from/fine_to day range, max fine_rate 999.99, percentage capped at 100% |
| **Model Fillable** | `fine_category_id`, `std_academic_sessions_id`, `fine_from_days`, `fine_to_days`, `fine_type`, `fine_rate`, `student_restricted`, `student_rusticated`, `remark` (includes misspelled `student_rusticated`) |
| **Model Casts** | `fine_from_days` → integer, `fine_to_days` → integer, `fine_rate` → decimal:2, `student_restricted` → boolean |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must have `tenant.fine-master.*` permissions |
| PC-02 | `tpt_fine_category` must have at least one active category (FK dependency) |
| PC-03 | `std_student_academic_sessions` must exist (FK dependency) |
| PC-04 | Current academic session must be marked `is_current=1` |
| PC-05 | `tpt_fine_master` table must exist with FK `fk_fm_fine_category` ON DELETE RESTRICT |
| PC-06 | Tab id `fine_master` registered in transportmaster.blade.php |
| PC-07 | `FineMasterRequest` must be registered for store and update |
| PC-08 | `TptFineMaster` model must have `SoftDeletes` trait imported |
| PC-09 | Activity logger must be configured to log `Created`, `Updated`, `Deleted`, `Restored`, `Force Deleted` events |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load fine masters with `latest()` ordering, paginated | `FineMasterController.php:index()` |
| DL-02 | List columns: **Category** (relationship), **Session** (relationship), **From Days**, **To Days**, **Fine Type**, **Rate**, **Remark**, **Action** | `fine-master/index.blade.php` |
| DL-03 | Category displayed via `$item->fineCategory->category_name ?? '-'` | `fine-master/index.blade.php` |
| DL-04 | Session displayed via `$item->academicSession->name ?? '-'` | `fine-master/index.blade.php` |
| DL-05 | Rate formatted: Percentage → "10 %", Fixed → "₹ 50.00" | `fine-master/index.blade.php` |
| DL-06 | Filters: Academic Session dropdown (`academic_sessions_id`), Fine Type dropdown (`fine_type`) | `fine-master/index.blade.php` |
| DL-07 | No status filter (no `is_active` column displayed) | `fine-master/index.blade.php` |
| DL-08 | No status toggle (no `is_active` field in list) | `fine-master/index.blade.php` |
| DL-09 | Create form loads `$fineCategories` (all active categories), current academic session auto-selected | `FineMasterController.php:create()` |
| DL-10 | Edit form pre-populates all fields from existing record | `FineMasterController.php:edit()` |
| DL-11 | Trash view uses `onlyTrashed()->latest()->paginate(20)` | `FineMasterController.php:trashed()` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Fixed Fine** | fine_category_id=valid, fine_from=1, fine_to=5, fine_type="Fixed", fine_rate=50.00, student_restricted=false |
| TD-02 | **Valid Percentage Fine** | fine_type="Percentage", fine_rate=10.00 (max 100 for percentage) |
| TD-03 | **Rate > 999.99** | fine_rate=1000 — expects `max:999.99` validation error |
| TD-04 | **Percentage > 100** | fine_type="Percentage", fine_rate=150 — expects custom rule "Percentage fine rate cannot exceed 100%." |
| TD-05 | **fine_to_days < fine_from_days** | fine_from=5, fine_to=1 — expects `gte:fine_from_days` error |
| TD-06 | **student_restricted=true** | Checkbox checked → student blocked from boarding |
| TD-07 | **student_restricted=false (boolean normalization)** | Checkbox unchecked → `$request->boolean('student_restricted')` = false in store, but raw `$request->student_restricted` in update |
| TD-08 | **remark max length** | String of 256 chars → expects `max:255` validation error |
| TD-09 | **fine_from_days = 0** | Zero is valid (min:0 rule) |
| TD-10 | **fine_rate = 0.00** | Zero fine rate is valid (min:0 rule) |
| TD-11 | **Duplicate day ranges** | Two fine masters with same fine_from=1, fine_to=5 for same session — allowed (no unique constraint) |
| TD-12 | **Overlapping day ranges** | One rule with 1-5, another with 3-10 — allowed (no overlap validation in code) |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions — `tpt_fine_master`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED | PK, AUTO_INCREMENT |
| BC-DB-02 | `fine_category_id` | TINYINT UNSIGNED | NOT NULL, FK → `tpt_fine_category.id` ON DELETE RESTRICT |
| BC-DB-03 | `std_academic_sessions_id` | INT UNSIGNED | NOT NULL |
| BC-DB-04 | `fine_from_days` | TINYINT | DEFAULT 0 |
| BC-DB-05 | `fine_to_days` | TINYINT | DEFAULT 0 |
| BC-DB-06 | `fine_type` | ENUM('Fixed','Percentage') | DEFAULT 'Fixed' |
| BC-DB-07 | `fine_rate` | DECIMAL(5,2) | DEFAULT 0.00 (max 999.99) |
| BC-DB-08 | `student_restricted` | TINYINT(1) | DEFAULT 0 |
| BC-DB-09 | `Remark` | VARCHAR(512) | DEFAULT NULL (note capital R) |
| BC-DB-10 | `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-11 | `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-12 | `deleted_at` | TIMESTAMP NULL | Soft delete support |
| BC-DB-13 | FK `fk_fm_fine_category` | RESTRICT | Cannot delete category if fine master references it |

### BC-VAL: Validation Conditions — `FineMasterRequest`

| BC ID | Field | Rule | Source |
|-------|-------|------|--------|
| BC-VAL-01 | `fine_category_id` | required, integer, exists:tpt_fine_category,id | `FineMasterRequest.php` |
| BC-VAL-02 | `fine_from_days` | required, integer, min:0 | `FineMasterRequest.php` |
| BC-VAL-03 | `fine_to_days` | required, integer, gte:fine_from_days | `FineMasterRequest.php` |
| BC-VAL-04 | `fine_type` | required, in:Fixed,Percentage | `FineMasterRequest.php` |
| BC-VAL-05 | `fine_rate` | required, numeric, min:0, max:999.99 | `FineMasterRequest.php` |
| BC-VAL-06 | Custom: Percentage rate > 100 | Custom closure validation | `FineMasterRequest.php` |
| BC-VAL-07 | `remark` | nullable, string, max:255 | `FineMasterRequest.php` |
| BC-VAL-08 | `student_restricted` | nullable, boolean (normalized in prepareForValidation) | `FineMasterRequest.php` |

### BC-AUTH: Authorization Conditions

| BC ID | Permission | Controller Method | Source |
|-------|-----------|-------------------|--------|
| BC-AUTH-01 | `tenant.fine-master.viewAny` | `index()` — **MISSING** Gate | `FineMasterController.php` — **GAP** |
| BC-AUTH-02 | `tenant.fine-master.create` | `create()` + `store()` — Gate present in create() | `FineMasterController.php` |
| BC-AUTH-03 | `tenant.fine-master.view` | `show()` — **PRESENT**: `Gate::authorize('tenant.fine-master.view')` | `FineMasterController.php` |
| BC-AUTH-04 | `tenant.fine-master.update` | `edit()` — Gate present | `FineMasterController.php` |
| BC-AUTH-05 | `tenant.fine-master.delete` | `destroy()` — Gate present | `FineMasterController.php` |
| BC-AUTH-06 | `tenant.fine-master.restore` | `restore()` + `trashed()` — Gate present in restore() | `FineMasterController.php` |
| BC-AUTH-07 | `tenant.fine-master.forceDelete` | `forceDelete()` — Gate present | `FineMasterController.php` |

### BC-BIZ: Business Conditions

| BC ID | Condition | Expected | Source |
|-------|-----------|----------|--------|
| BC-BIZ-01 | `std_academic_sessions_id` auto-set from current academic session | `AcademicSession::where('is_current','1')->first()->id` | `FineMasterController.php:store(),update()` |
| BC-BIZ-02 | `student_restricted` uses `$request->boolean()` in store but `$request->student_restricted` (raw) in update | **Inconsistency**: store normalizes (also double-normalized in request prepareForValidation), update assigns raw value | `FineMasterController.php` |
| BC-BIZ-03 | `fine_rate` formatted via `number_format()` in prepareForValidation | `number_format((float) $this->fine_rate, 2, '.', '')` | `FineMasterRequest.php` |
| BC-BIZ-04 | Percentage rate capped at 100 via custom closure | Custom rule in FineMasterRequest | `if ($this->fine_type === 'Percentage' && $value > 100)` |
| BC-BIZ-05 | `update()` has NO change tracking | No `getOriginal()`/`getChanges()` | `FineMasterController.php:update()` |
| BC-BIZ-06 | `destroy()` does NOT set `is_active` before soft-delete | Direct `delete()` — note: there is no is_active column | `FineMasterController.php:destroy()` |
| BC-BIZ-07 | `forceDelete()` uses `onlyTrashed()` (WRONG — should be `withTrashed()`) | Will fail for non-trashed records | `FineMasterController.php` — **GAP** |
| BC-BIZ-08 | No `toggleStatus()` method | No status switch in controller | Contrast with FineCategoryController |
| BC-BIZ-09 | Model `$fillable` uses `remark` (lowercase) but DDL column is `Remark` (capital R) | **GAP**: Case mismatch — MySQL on Linux is case-sensitive | `TptFineMaster.php` vs DDL |
| BC-BIZ-10 | Model `$casts` includes `student_restricted => boolean` | Proper cast | `TptFineMaster.php` |
| BC-BIZ-11 | `student_rusticated` (misspelled) also in fillable | Works because both spellings map to the same column | `TptFineMaster.php` |
| BC-BIZ-12 | DDL has no `updated_at` column but model extends Model with timestamps | `updated_at` auto-managed — may cause SQL error on update | DDL vs Model |
| BC-BIZ-13 | `fine_category_id` is passed explicitly by store/update as `$request->fine_category_id` | Set correctly in both methods | `FineMasterController.php` |
| BC-BIZ-14 | No DB::transaction wrapping in store/update | No `DB::beginTransaction()` / `rollback()` | `FineMasterController.php` |
| BC-BIZ-15 | Activity log uses hardcoded event strings | `activityLog($record, 'Created', ...)` | `FineMasterController.php` |

### BC-REF: Reference & UI Conditions

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | Tab id `fine_master-pane`, hidden `tab=fine_master` | `fine-master/index.blade.php` |
| BC-REF-02 | No status column or status toggle in index table | Table has 7 columns without Status |
| BC-REF-03 | Action column for `@canany(['tenant.fine-master.edit', 'tenant.fine-master.delete'])` | `fine-master/index.blade.php` |
| BC-REF-04 | Create form: fine_category dropdown (from active categories), fine_from/fine_to number inputs, fine_type dropdown, fine_rate number, student_restricted checkbox, remark textarea | `fine-master/create.blade.php` |
| BC-REF-05 | Create form does NOT have is_active toggle (no status field) | `fine-master/create.blade.php` |
| BC-REF-06 | Rate display: Percentage → "10 %", Fixed → "₹ 50.00" | `fine-master/index.blade.php` |
| BC-REF-07 | Pagination links preserved across filters: `->appends(request()->query())->links()` | `fine-master/index.blade.php` |
| BC-REF-08 | Trash view shows "No trashed fine rules found" empty state | `fine-master/trash.blade.php` |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create fixed fine rule | category=Late Fee, from=1, to=5, type=Fixed, rate=50 | Created, current session auto-assigned, activityLog "Created" |
| TC-P-02 | Create percentage fine rule | type=Percentage, rate=10.00 (within 100) | Created successfully |
| TC-P-03 | Create with student_restricted=true | Check student_restricted checkbox | student_restricted=1 |
| TC-P-04 | Create with student_restricted=false | Leave unchecked | student_restricted=0 (normalized via boolean()) |
| TC-P-05 | Edit fine_from_days from 1 to 2 | Change value | Updated, activityLog "Updated" |
| TC-P-06 | Edit fine_type from Fixed to Percentage | Change dropdown | Updated |
| TC-P-07 | View fine master details | Click show | All fields displayed with relationship data |
| TC-P-08 | Soft delete fine master | Click delete | `deleted_at` set, activityLog "Deleted" |
| TC-P-09 | Restore soft-deleted fine master | Click restore in trash | Restored, activityLog "Restored" |
| TC-P-10 | Force delete trashed fine master | Click permanent delete | Record removed, activityLog "Force Deleted" |
| TC-P-11 | Filter by Academic Session | Select session in dropdown | Only records for that session |
| TC-P-12 | Filter by Fine Type | Select "Fixed" | Only Fixed type records |
| TC-P-13 | Create with remark text | Enter remark="Late fee for first week" | Remark saved in DB |
| TC-P-14 | Edit without changes (no-op update) | Submit unchanged form | Success redirect, no error |
| TC-P-15 | Index redirects to tab | GET /transport/fine-master | Redirect to transport-master?tab=fine_master |
| TC-P-16 | Pagination shows with 21+ records | Load 21 fine masters | Pagination links visible (2 pages at 20/page) |
| TC-P-17 | Pagination hidden with <20 records | Load 5 fine masters | No pagination links |
| TC-P-18 | Pagination preserves tab param | Navigate to page 2 | URL contains ?tab=fine_master&page=2 |
| TC-P-19 | Create with fine_from=0, fine_to=0 | Zero-day range (minimal) | Created, edge case fine_from=0 passes min:0 |
| TC-P-20 | Create with rate=0.00 (zero fine) | Zero fine rate | Created successfully |
| TC-P-21 | Show trashed list when items exist | Soft delete 3 records | Trash page shows 3 items |
| TC-P-22 | Empty trash shows message | No trashed records | "No trashed fine rules found" displayed |
| TC-P-23 | Create with misspelled student_rusticated | Use misspelled field name | Still saved because both spellings in fillable |
| TC-P-24 | View fine master with category relationship | Check show page | Category name displayed via fineCategory relation |
| TC-P-25 | View fine master with session relationship | Check show page | Session name displayed via academicSession relation |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with invalid fine_category_id | ID=99999 | "The selected fine category id is invalid." |
| TC-N-02 | fine_to_days < fine_from_days | from=5, to=1 | "Fine to days must be greater than or equal to fine from days." |
| TC-N-03 | fine_rate > 999.99 | rate=1000 | "Fine rate cannot exceed 999.99." |
| TC-N-04 | Percentage fine_rate > 100 | type=Percentage, rate=150 | "Percentage fine rate cannot exceed 100%." |
| TC-N-05 | Invalid fine_type | "Discount" | "The selected fine type is invalid." |
| TC-N-06 | Empty fine_category_id | Not selected | "Fine category is required." |
| TC-N-07 | Empty fine_from_days | Not provided | "Fine from days is required." |
| TC-N-08 | Access without permission | No tenant.fine-master.* | 403 Access Denied |
| TC-N-09 | Show non-existent ID | ID=99999 | `findOrFail` → 404 |
| TC-N-10 | Restore non-trashed record | Active record | `onlyTrashed()` → 404 |
| TC-N-11 | Force delete active (non-trashed) record | Active record | `onlyTrashed()` → 404 — **GAP** |
| TC-N-12 | Delete fine master referenced by student fee | FK from tpt_student_fee_detail | ON DELETE RESTRICT → FK violation |
| TC-N-13 | Edit non-existent ID | ID=99999 | `findOrFail` → 404 |
| TC-N-14 | Create with remark > 255 chars | 256-char string | "The remark must not be greater than 255 characters." |
| TC-N-15 | Missing fine_type | Not selected | "Fine type is required." |
| TC-N-16 | Missing fine_rate | Not provided | "Fine rate is required." |
| TC-N-17 | fine_from_days negative | fine_from=-1 | "Fine from days must be at least 0." |
| TC-N-18 | fine_rate negative | fine_rate=-10 | "Fine rate must be at least 0." |
| TC-N-19 | Force delete non-existent ID | ID=99999 | `findOrFail` → 404 |
| TC-N-20 | Guest access redirect to login | Not authenticated | Redirect to /login page |
| TC-N-21 | Delete non-existent fine master | ID=99999 | `findOrFail` → 404 |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Verify current academic session auto-assigned | Create without session_id | `std_academic_sessions_id` = current session id |
| TC-D-02 | Verify `student_restricted` boolean consistency | store uses boolean(), update uses direct assign | **GAP**: Different normalization between store and update |
| TC-D-03 | Verify `remark` vs `Remark` case sensitivity | Model fillable lowercase, DDL capital R | Works on MySQL with lower_case_table_names=1, fails on case-sensitive |
| TC-D-04 | Verify forceDelete on active record fails | `onlyTrashed()` doesn't find non-deleted records | 404 — **GAP**: should use `withTrashed()` |
| TC-D-05 | Verify soft delete lifecycle | Create → soft-delete → restore → force-delete | All transitions correct |
| TC-D-06 | Verify FK RESTRICT prevents category deletion | Delete category with fine masters | Integrity constraint violation |
| TC-D-07 | Verify `updated_at` auto-managed | Create and update record | `updated_at` changes on update, NULL on create if DDL mismatch |
| TC-D-08 | Verify rate stored as DECIMAL(5,2) | Create with rate=50.555 | Rounded to 50.56 (or truncated to 50.55 depending on DB mode) |
| TC-D-09 | Verify student_restricted cast to boolean | DB stores 0/1, model retrieves boolean | `$model->student_restricted === true/false` |
| TC-D-10 | Verify activity log entries | Check sp_activity_logs after each action | Created, Updated, Deleted, Restored, Force Deleted logged |

### TC-CR: Code Review Test Cases

| ID | Test Case | Steps | Expected |
|----|-----------|-------|----------|
| TC-CR-01 | **GAP: index() missing Gate** | 1. Open `FineMasterController.php:index()` | No `Gate::authorize()` in `index()` — **MISSING** |
| TC-CR-02 | **show() has Gate PRESENT** | 1. Open `FineMasterController.php:show()` | `Gate::authorize('tenant.fine-master.view')` — **PRESENT** |
| TC-CR-03 | **GAP: trashed() missing Gate** | 1. Open `FineMasterController.php:trashed()` | No `Gate::authorize()` in `trashed()` — **MISSING** |
| TC-CR-04 | **GAP: forceDelete() uses onlyTrashed()** | 1. Open `FineMasterController.php:forceDelete()` | `TptFineMaster::onlyTrashed()->findOrFail($id)` — should be `withTrashed()` |
| TC-CR-05 | **GAP: student_restricted inconsistency** | 1. Store: `$request->boolean('student_restricted')` | store normalizes via boolean() |
| | | 2. Update: `$request->student_restricted` | update assigns raw value — no normalization |
| TC-CR-06 | **GAP: remark/Remark case mismatch** | 1. Model `$fillable` | `'remark'` — lowercase |
| | | 2. DDL | `` `Remark` VARCHAR(512)`` — capital R |
| TC-CR-07 | **fine_rate formatted via number_format** | 1. Open `FineMasterRequest.php:prepareForValidation()` | `number_format((float) $this->fine_rate, 2, '.', '')` |
| TC-CR-08 | **Percentage > 100 custom rule** | 1. Open `FineMasterRequest.php` | Closure validates type=Percentage AND rate > 100 |
| TC-CR-09 | **Current session logic** | 1. Open store/update | `AcademicSession::where('is_current','1')->first()` |
| TC-CR-10 | **Model relationships** | 1. Open `TptFineMaster.php` | `academicSession()` and `fineCategory()` both belongTo |
| TC-CR-11 | **No toggleStatus() method** | 1. Search FineMasterController | No `toggleStatus()` method |
| TC-CR-12 | **No is_active field in blades** | 1. Open create/edit blades | No status toggle in form |
| TC-CR-13 | **Rate display format in blade** | 1. Open index blade | `$item->fine_type == 'Percentage' ? $item->fine_rate . ' %' : '₹ ' . $item->fine_rate` |
| TC-CR-14 | **DDL has no is_active column** | 1. Open DDL | No `is_active` column in `tpt_fine_master` |
| TC-CR-15 | **FK RESTRICT on fine_category_id** | 1. Open DDL | `ON DELETE RESTRICT` — prevents delete of referenced category |
| TC-CR-16 | **GAP: student_rusticated misspelling in fillable** | 1. Open `TptFineMaster.php:fillable` | Contains both `student_restricted` AND `student_rusticated` (typo) |
| TC-CR-17 | **GAP: updated_at mismatch** | 1. DDL has no updated_at | Model extends Model with `$timestamps = true` — auto-manages updated_at |
| TC-CR-18 | **GAP: No DB::transaction in CUD** | 1. Check store/update/destroy | No `DB::beginTransaction()` wrapping — **MISSING** |
| TC-CR-19 | **No change tracking in update** | 1. Check update() | No `getOriginal()`/`getChanges()` — no audit of what changed |
| TC-CR-20 | **fine_category_id set in both store() and update()** | 1. Check store() and update() | Both pass `'fine_category_id' => $request->fine_category_id` — **CORRECT** |

---

### TC-BIZ-DEEP: Deep Business/Technical Behavior Test Cases

### TC-BIZ-DEEP-01: Default attributes from model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php` model | Check `$attributes` or DDL defaults |
| 2 | DDL: `fine_type` DEFAULT 'Fixed' | Default fine type is Fixed |
| 3 | DDL: `fine_rate` DEFAULT 0.00 | Default rate is 0.00 |
| 4 | DDL: `student_restricted` DEFAULT 0 | Default not restricted |
| 5 | DDL: `fine_from_days` DEFAULT 0, `fine_to_days` DEFAULT 0 | Default day range 0-0 |

### TC-BIZ-DEEP-02: Soft deletes on TptFineMaster

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php` | Uses `SoftDeletes` trait |
| 2 | DDL: `deleted_at` TIMESTAMP NULL | Column present |
| 3 | `destroy()` calls `$record->delete()` | Sets `deleted_at` timestamp, record hidden from normal queries |
| 4 | `restore()` calls `$record->restore()` | Sets `deleted_at = NULL` |

### TC-BIZ-DEEP-03: Model casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:casts` | `fine_from_days` → integer, `fine_to_days` → integer, `fine_rate` → decimal:2, `student_restricted` → boolean |
| 2 | Create with fine_rate=50.555 → stored as 50.56 | decimal:2 rounding |
| 3 | Retrieve `student_restricted` from DB value 1 | Returns `true` (boolean, not int) |

### TC-BIZ-DEEP-04: Fillable fields vs DDL columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fillable` | `fine_category_id`, `std_academic_sessions_id`, `fine_from_days`, `fine_to_days`, `fine_type`, `fine_rate`, `student_restricted`, `student_rusticated`, `remark` |
| 2 | Note: `student_rusticated` is misspelled | Both spellings included — intentional fallback |
| 3 | Note: `remark` lowercase vs DDL `Remark` capital R | Works on case-insensitive MySQL only |

### TC-BIZ-DEEP-05: Controller sets fine_category_id in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterController.php:store()` | Builds create array manually |
| 2 | Check for `'fine_category_id'` key | `'fine_category_id' => $request->fine_category_id` — **PRESENT** |
| 3 | DDL: `fine_category_id` is NOT NULL with FK RESTRICT | INSERT succeeds with valid category_id |
| 4 | **Note**: store() builds array manually (not $request->validated()) | Fine_category_id explicitly passed |

### TC-BIZ-DEEP-06: std_academic_sessions_id auto-assigned

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` method | `$currentSession = AcademicSession::where('is_current', '1')->first()` |
| 2 | DB query: `SELECT * FROM glb_academic_sessions WHERE is_current = 1 LIMIT 1` | Returns current session |
| 3 | `$data['std_academic_sessions_id'] = $currentSession->id` | Auto-assigned |
| 4 | Same logic in `update()` (lines ~92) | Both store and update set the session |

### TC-BIZ-DEEP-07: fine_rate formatted via prepareForValidation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterRequest.php:prepareForValidation()` | `$this->merge(['fine_rate' => number_format((float) $this->fine_rate, 2, '.', '')])` |
| 2 | Input: `"50"` → formatted to `"50.00"` | String "50.00" |
| 3 | Input: `"50.5"` → formatted to `"50.50"` | String "50.50" |
| 4 | Input: `"abc"` → `(float)` casts to 0.00 → formatted to `"0.00"` | Silent type conversion |

### TC-BIZ-DEEP-08: student_restricted normalization in store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` method line | `$data['student_restricted'] = $request->boolean('student_restricted')` |
| 2 | Checkbox checked → `boolean()` returns `true` | Stored as 1 |
| 3 | Checkbox unchecked → `boolean()` returns `false` | Stored as 0 |
| 4 | `prepareForValidation` also normalizes: `$this->merge(['student_restricted' => $this->boolean('student_restricted')])` | Double normalization |

### TC-BIZ-DEEP-09: student_restricted NOT normalized in update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` method | `$data['student_restricted'] = $request->student_restricted` |
| 2 | **Note**: Uses raw `$request->student_restricted` | No `boolean()` call unlike store |
| 3 | Checkbox unchecked → `$request->student_restricted` = null | Stored as null → DB default 0? |
| 4 | **GAP**: Inconsistent normalization between store and update | update may store null |

### TC-BIZ-DEEP-10: Percentage rate capped at 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterRequest.php` custom closure | `function ($attribute, $value, $fail) { if ($this->fine_type === 'Percentage' && $value > 100) { $fail('Percentage fine rate cannot exceed 100%.'); } }` |
| 2 | Input: type=Percentage, rate=150 | Closure triggers → validation error |
| 3 | Input: type=Fixed, rate=150 | Closure does NOT trigger (type != Percentage) |
| 4 | Input: type=Percentage, rate=100 | Closure does NOT trigger (100 is not > 100) |

### TC-BIZ-DEEP-11: Activity logging in store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` | After `TptFineMaster::create()`, calls `activityLog($record, 'Created', ...)` |
| 2 | **Verify**: Activity log entry created in `sp_activity_logs` | log_name, description, subject_id, causer_id |
| 3 | Description includes fine rule details | e.g., "Fine Master Created: Fixed 50.00" |

### TC-BIZ-DEEP-12: Activity logging in update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` | After `$record->update()`, calls `activityLog($record, 'Updated', ...)` |
| 2 | **Note**: No change tracking | Does NOT log which fields changed |
| 3 | Activity entry logged | "Fine Master Updated" |

### TC-BIZ-DEEP-13: Activity logging in destroy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` | After `$record->delete()`, calls `activityLog($record, 'Deleted', ...)` |
| 2 | Activity entry logged | "Fine Master Deleted" |

### TC-BIZ-DEEP-14: Activity logging in restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `restore()` | After `$record->restore()`, calls `activityLog($record, 'Restored', ...)` |
| 2 | Activity entry logged | "Fine Master Restored" |

### TC-BIZ-DEEP-15: Activity logging in forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete()` | After `$record->forceDelete()`, calls `activityLog($record, 'Force Deleted', ...)` |
| 2 | Activity entry logged | "Fine Master Force Deleted" |

### TC-BIZ-DEEP-16: index() uses simple paginate (no eager loading)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index()` | `TptFineMaster::latest()->paginate(20)` — simple query, no `with()` |
| 2 | DB query: `SELECT * FROM tpt_fine_master ORDER BY created_at DESC LIMIT 20 OFFSET 0` | No eager loading (N+1 possible) |
| 3 | View accesses `$item->fineCategory->category_name` and `$item->academicSession->name` | Lazy-loaded per row |
| 4 | With 20 records → 1+20 queries (N+1) | Can be optimized with `with()` |

### TC-BIZ-DEEP-17: index() has NO filter by academic session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request with `?academic_sessions_id=5` | Controller has NO filter logic |
| 2 | DB query: `SELECT ... FROM tpt_fine_master ORDER BY created_at DESC LIMIT 20` | All records returned regardless |
| 3 | **GAP**: Blade may have filter dropdown but controller ignores it | Filter dropdown in view has no effect |

### TC-BIZ-DEEP-18: index() has NO filter by fine_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request with `?fine_type=Percentage` | Controller has NO filter logic |
| 2 | All records returned regardless of fine_type | Filter param ignored |

### TC-BIZ-DEEP-19: index() combined filters — controller ignores all

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request with `?academic_sessions_id=5&fine_type=Fixed` | No WHERE clauses applied |
| 2 | All records returned | Filter dropdowns are decorative only |

### TC-BIZ-DEEP-20: index() no pagination with get()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check if `index()` uses `paginate()` or `get()` | `latest()->paginate(20)` based on test code |
| 2 | With 21 records → page 1 has 20, page 2 has 1 | Standard pagination |

### TC-BIZ-DEEP-21: create() loads fine categories for dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create()` | Loads `TptFineCategory::all()` or `::where('is_active',1)->get()` |
| 2 | View receives `$fineCategories` | Populated dropdown in create form |
| 3 | Each category shows `category_name` as option text | `<option value="1">Late Fee</option>` |

### TC-BIZ-DEEP-22: create() Gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create()` | `Gate::authorize('tenant.fine-master.create')` at method start |
| 2 | User without permission → 403 | Authorization exception thrown |
| 3 | User with permission → form loads | 200 response |

### TC-BIZ-DEEP-23: store() Gate authorization via FormRequest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterRequest.php:authorize()` | Checks `Gate::authorize('tenant.fine-master.create')` |
| 2 | User without permission → 403 | FormRequest throws AuthorizationException |
| 3 | **GAP**: No controller-level Gate in store() | Only relies on FormRequest authorize |

### TC-BIZ-DEEP-24: show() uses simple findOrFail (N+1)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `show()` | `TptFineMaster::findOrFail($id)` — no `with()` |
| 2 | Valid ID → returns record (relationships lazy-loaded in view) | Category + Session names rendered via lazy load |
| 3 | Invalid ID → 404 | `findOrFail` throws ModelNotFoundException |
| 4 | **Note**: Gate::authorize('tenant.fine-master.view') present | Authorization checked before query |

### TC-BIZ-DEEP-25: edit() loads record + categories

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `edit()` | `$fineMaster = TptFineMaster::findOrFail($id)` + `$fineCategories = TptFineCategory::where('is_active', true)->get()` |
| 2 | Also loads `$studentSession = StudentAcademicSession::get()` | 3 variables passed to view |
| 3 | Valid ID → pre-populated edit form | All fields show current values |
| 4 | Gate authorize before load | `Gate::authorize('tenant.fine-master.update')` |

### TC-BIZ-DEEP-26: update() reassigns academic session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` | `$currentSession = AcademicSession::where('is_current', '1')->first()` |
| 2 | `$data['std_academic_sessions_id'] = $currentSession->id` | Academic session re-set on every update (even if not changed) |
| 3 | **Note**: This means update always changes session to current | Cannot keep a record from a past session via update |

### TC-BIZ-DEEP-27: update() passes fine_category_id from request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `update()` $data array | `'fine_category_id' => $request->fine_category_id` — **PRESENT** |
| 2 | Form category dropdown value used in update | Category field is mutable via update |
| 3 | Same pattern as store(): explicit array, not $request->validated() | Consistent handling |

### TC-BIZ-DEEP-28: destroy() uses findOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy($id)` | `$record = TptFineMaster::findOrFail($id)` |
| 2 | Valid ID → record found | `$record->delete()` called |
| 3 | Invalid ID → 404 | `findOrFail` throws ModelNotFoundException |

### TC-BIZ-DEEP-29: destroy() Gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` | `Gate::authorize('tenant.fine-master.delete')` at method start |
| 2 | User without permission → 403 | Authorization exception |
| 3 | User with permission → record deleted | Soft delete succeeds |

### TC-BIZ-DEEP-30: trashed() shows only soft-deleted records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trashed()` | `TptFineMaster::onlyTrashed()->latest()->paginate(20)` |
| 2 | DB query: `SELECT * FROM tpt_fine_master WHERE deleted_at IS NOT NULL ORDER BY created_at DESC` | Only trashed records |
| 3 | Active records NOT shown | `onlyTrashed()` scope filters them out |

### TC-BIZ-DEEP-31: restore() uses onlyTrashed() (correct)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `restore($id)` | `$record = TptFineMaster::onlyTrashed()->findOrFail($id)` |
| 2 | Trashed record found → `$record->restore()` | `deleted_at` set to NULL |
| 3 | Active (non-deleted) record → 404 | `onlyTrashed()` excludes active — correct behavior for restore |

### TC-BIZ-DEEP-32: forceDelete() uses onlyTrashed() (WRONG)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete($id)` | `$record = TptFineMaster::onlyTrashed()->findOrFail($id)` |
| 2 | **GAP**: Should use `withTrashed()` | `onlyTrashed()` only finds soft-deleted records |
| 3 | Active record (not deleted) → 404 | Cannot force-delete an active record |
| 4 | Trashed record → forceDelete succeeds | Only works if already soft-deleted |
| 5 | Compare with correct pattern: `withTrashed()->findOrFail($id)->forceDelete()` | Should use `withTrashed()` |

### TC-BIZ-DEEP-33: forceDelete() Gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete()` | `Gate::authorize('tenant.fine-master.forceDelete')` at method start |
| 2 | User without `forceDelete` permission → 403 | Authorization exception |
| 3 | User with permission → record permanently deleted | forceDelete succeeds (if trashed) |

### TC-BIZ-DEEP-34: No DB::transaction in any method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `store()` for `DB::beginTransaction()` | **NOT PRESENT** |
| 2 | Check `update()` for `DB::beginTransaction()` | **NOT PRESENT** |
| 3 | Check `destroy()` for `DB::beginTransaction()` | **NOT PRESENT** |
| 4 | **GAP**: If any CUD method throws after partial write, DB is inconsistent | No rollback mechanism |

### TC-BIZ-DEEP-35: Activity log event naming consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check store activityLog event | 'Created' |
| 2 | Check update activityLog event | 'Updated' |
| 3 | Check destroy activityLog event | 'Deleted' |
| 4 | Check restore activityLog event | 'Restored' |
| 5 | Check forceDelete activityLog event | 'Force Deleted' |
| 6 | All 5 events logged in `sp_activity_logs` | Consistent naming |

### TC-BIZ-DEEP-36: Index page redirect from /transport/fine-master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/transport/fine-master` | Controller redirects to `/transport/transport-master?tab=fine_master` |
| 2 | **Verify**: 302 redirect status | Redirect response |
| 3 | Location header includes tab=fine_master | Tab param preserved |

### TC-BIZ-DEEP-37: Store redirect after success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Successful store | Redirect to `route('transport.transport-master.index', ['tab' => 'fine_master'])` |
| 2 | Flash message set | `flash('created.fine_master')` or `->with('success', '...')` |
| 3 | User sees success toast | Flash message displayed |

### TC-BIZ-DEEP-38: Update redirect after success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Successful update | Redirect to `route('transport.transport-master.index', ['tab' => 'fine_master'])` |
| 2 | Flash message set | Success message displayed |

### TC-BIZ-DEEP-39: Destroy redirect after success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Successful delete | Redirect to `route('transport.transport-master.index', ['tab' => 'fine_master'])` |
| 2 | Flash message set | Success message displayed |

### TC-BIZ-DEEP-40: Restore redirect after success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Successful restore | Redirect to `route('transport.fine-master.trashed')` or transport-master tab |
| 2 | Flash message set | Success message displayed |

### TC-BIZ-DEEP-41: Force delete redirect after success

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Successful forceDelete | Redirect back with success message |
| 2 | Flash message set | Success message displayed |

### TC-BIZ-DEEP-42: Rate display formatting in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | fine_type = 'Percentage', fine_rate = 10 | Display: "10 %" |
| 2 | fine_type = 'Fixed', fine_rate = 50.00 | Display: "₹ 50.00" |
| 3 | fine_rate with decimals, e.g., 50.50 | "₹ 50.50" or "50.50 %" |

### TC-BIZ-DEEP-43: Category display via relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record with fine_category_id=1, category name="Late Fee" | Display: "Late Fee" |
| 2 | Record with null/missing category | Display: "-" |
| 3 | Null-safe operator: `$item->fineCategory->category_name ?? '-'` | No error on null relationship |

### TC-BIZ-DEEP-44: Session display via relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record with academic_session name="2025-26" | Display: "2025-26" |
| 2 | Record with null session | Display: "-" |
| 3 | Null-safe operator: `$item->academicSession->name ?? '-'` | No error on null relationship |

### TC-BIZ-DEEP-45: No is_active column in DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for tpt_fine_master | No `is_active` column exists |
| 2 | No status toggle in UI | By design — FineMaster doesn't have active/inactive status |
| 3 | No toggleStatus() method in controller | Consistent with schema |

### TC-BIZ-DEEP-46: student_restricted field name misspelling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fillable` | Contains `'student_rusticated'` (sic) |
| 2 | DDL column is `student_restricted` | Correct spelling |
| 3 | Both `student_restricted` and `student_rusticated` in fillable | Form can submit either name |
| 4 | Test form uses `student_rusticated` (misspelled) | Actually saves to `student_restricted` via mass assignment |

### TC-BIZ-DEEP-47: No unique constraint on day ranges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster: fine_from=1, fine_to=5, session=1 | OK |
| 2 | Create another: fine_from=1, fine_to=5, session=1 | OK (duplicate allowed) |
| 3 | DB has no UNIQUE constraint on (fine_from, fine_to, session) | No duplicate protection |
| 4 | **Business impact**: Overlapping day ranges allowed | No validation prevents overlapping slabs |

### TC-BIZ-DEEP-48: No overlap validation for day ranges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster A: fine_from=1, fine_to=10 | Range A |
| 2 | Create FineMaster B: fine_from=5, fine_to=15 | Range B overlaps with A |
| 3 | Both created successfully | No overlap validation in controller or request |
| 4 | Business rule says "highest applicable slab" used | System relies on application logic, not DB constraints |

### TC-BIZ-DEEP-49: fine_rate max 999.99 enforced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `validate(['fine_rate' => 'numeric|min:0|max:999.99'])` | Rule present |
| 2 | Input fine_rate=999.99 | Valid (at boundary) |
| 3 | Input fine_rate=1000 | Invalid → "Fine rate cannot exceed 999.99." |
| 4 | DECIMAL(5,2) max is 999.99 | DB column also enforces same limit |

### TC-BIZ-DEEP-50: fine_rate min:0 enforced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Input fine_rate=-1 | Invalid → "Fine rate must be at least 0." |
| 2 | Input fine_rate=0 | Valid (zero fine) |
| 3 | Input fine_rate=0.01 | Valid (minimum non-zero) |

### TC-BIZ-DEEP-51: fine_from_days min:0 enforced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Input fine_from_days=-1 | Invalid → "Fine from days must be at least 0." |
| 2 | Input fine_from_days=0 | Valid (immediate fine from day 0) |
| 3 | Input fine_from_days=365 | Valid (no explicit upper bound) |

### TC-BIZ-DEEP-52: fine_to_days gte:fine_from_days enforced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Input fine_from=5, fine_to=3 | Invalid → "Fine to days must be greater than or equal to fine from days." |
| 2 | Input fine_from=5, fine_to=5 | Valid (exact single day range) |
| 3 | Input fine_from=5, fine_to=10 | Valid (normal range) |

### TC-BIZ-DEEP-53: fine_type ENUM validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Input fine_type='Fixed' | Valid |
| 2 | Input fine_type='Percentage' | Valid |
| 3 | Input fine_type='Discount' | Invalid → "The selected fine type is invalid." |
| 4 | Input fine_type='' (empty) | Invalid → "Fine type is required." |

### TC-BIZ-DEEP-54: remark max:255 vs DDL VARCHAR(512)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Validation: `max:255` | FineMasterRequest limits to 255 chars |
| 2 | DDL: VARCHAR(512) | DB allows up to 512 chars |
| 3 | Input remark of 300 chars | Validation fails at 255 (application-level limit tighter than DB) |
| 4 | **Note**: Validation is more restrictive than DDL | Acceptable — prevents excessively long remarks |

### TC-BIZ-DEEP-55: Boolean normalization in prepareForValidation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterRequest.php:prepareForValidation()` | `$this->merge(['student_restricted' => $this->boolean('student_restricted')])` |
| 2 | Input: field not present → `boolean()` returns `false` | Merged as `student_restricted = false` |
| 3 | Input: "1" → `boolean()` returns `true` | Merged as `student_restricted = true` |
| 4 | Input: "0" → `boolean()` returns `false` | Merged as `student_restricted = false` |
| 5 | **Double normalization**: prepareForValidation AND controller store() both call boolean() | Redundant but harmless |

### TC-BIZ-DEEP-56: Controller update does NOT normalize boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update with student_restricted unchecked → `$request->student_restricted = null` | Stored as NULL in DB |
| 2 | DDL: `student_restricted TINYINT(1) DEFAULT 0 NOT NULL` | NULL may be rejected or converted to 0 |
| 3 | **GAP**: store normalizes, update doesn't | Inconsistent handling |

### TC-BIZ-DEEP-57: No is_active toggle — by design

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `toggleStatus` | **NOT FOUND** |
| 2 | Search DDL for `is_active` column in tpt_fine_master | **NOT FOUND** |
| 3 | Contrast with FineCategoryController which has toggleStatus | FineMaster deliberately lacks status toggle |
| 4 | **Implication**: Fine rules cannot be temporarily disabled | Only soft-delete (permanent removal) available |

### TC-BIZ-DEEP-58: FK RESTRICT on fine_category_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL: `FOREIGN KEY (fine_category_id) REFERENCES tpt_fine_category(id) ON DELETE RESTRICT` | RESTRICT, not CASCADE |
| 2 | Attempt to delete tpt_fine_category row referenced by fine_master | `Cannot delete or update a parent row: a foreign key constraint fails` |
| 3 | Must delete all fine_master records first before deleting category | RESTRICT prevents accidental deletion |

### TC-BIZ-DEEP-59: TptFineMaster belongsTo fineCategory

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fineCategory()` | `return $this->belongsTo(TptFineCategory::class, 'fine_category_id')` |
| 2 | `$fineMaster->fineCategory` returns `TptFineCategory` model | Lazy/eager loaded |
| 3 | `$fineMaster->fineCategory->category_name` | Category name from related table |

### TC-BIZ-DEEP-60: TptFineMaster belongsTo academicSession

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:academicSession()` | `return $this->belongsTo(AcademicSession::class, 'std_academic_sessions_id')` |
| 2 | `$fineMaster->academicSession` returns AcademicSession model | Eager/lazy loaded |
| 3 | `$fineMaster->academicSession->name` | Session name displayed |

### TC-BIZ-DEEP-61: Student route allocation checks student_restricted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Business rule: student_restricted=1 → student blocked from boarding | Enforced at boarding-log level |
| 2 | This is NOT enforced in FineMasterController | FineMaster just sets the flag |
| 3 | Integration: tpt_student_fee_detail + tpt_student_fine_detail use fine rules | Flag consumed downstream |

### TC-BIZ-DEEP-62: No forceDelete permission in policy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Gate in `forceDelete()` | Uses `tenant.fine-master.forceDelete` |
| 2 | Check if policy has `forceDelete` method | Depends on policy implementation |
| 3 | If permission exists → works; if not → 403 even for admin | **Potential GAP** |

### TC-BIZ-DEEP-63: Success flash messages pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check flash key in store | `flash('created.fine_master')` or similar key |
| 2 | Blade renders flash messages | `@if(session('success'))` or `@if(session('flash'))` |
| 3 | Check if message is translatable | `__('transport::flash.created.fine_master')` if using lang files |

### TC-BIZ-DEEP-64: No updated_at in DDL — potential SQL error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DDL for tpt_fine_master | NO `updated_at` column |
| 2 | Model extends Eloquent Model with `$timestamps = true` | Laravel auto-manages `updated_at` |
| 3 | On update: `UPDATE tpt_fine_master SET ..., updated_at = NOW() WHERE id = ?` | **SQL Error**: Unknown column 'updated_at' |
| 4 | **CRITICAL BUG**: All updates will fail with SQL error | Model timestamps must match DDL |

### TC-BIZ-DEEP-65: no updated_at migration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check migration for tpt_fine_master | Likely missing `->timestamps()` or only `->timestamp('created_at')` |
| 2 | Migration has `->softDeletes()` but `updated_at` may be missing | **GAP** documented in DEV-FM-05 |

### TC-BIZ-DEEP-66: Index blade uses @canany for action column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `@canany(['tenant.fine-master.edit', 'tenant.fine-master.delete'])` | Action column conditionally rendered |
| 2 | User with edit only → sees edit icon | Show/edit/delete icons shown based on permissions |
| 3 | User with neither → action column hidden | No action buttons |

### TC-BIZ-DEEP-67: No search functionality in index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index has no search input | Only dropdown filters (session, fine_type) |
| 2 | Cannot search by category name or remark text | Filtering limited to exact match on dropdowns |

### TC-BIZ-DEEP-68: Pagination preserves all query params

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | URL: `?tab=fine_master&academic_sessions_id=5&fine_type=Percentage&page=2` | All params in pagination links |
| 2 | `->appends(request()->query())` in blade | Query string forwarding |

### TC-BIZ-DEEP-69: Create form has category dropdown, store() passes it

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check create() for `$fineCategories` | Loads active categories: `where('is_active', true)->get()` |
| 2 | Store() passes `'fine_category_id' => $request->fine_category_id` | Category from form is saved |
| 3 | FK `fk_fm_fine_category` ON DELETE RESTRICT enforces referential integrity | Only valid category IDs accepted |

### TC-BIZ-DEEP-70: Update form can change category

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit form has fine_category dropdown | User can select a different category |
| 2 | Controller update() includes `'fine_category_id' => $request->fine_category_id` | Category change applied |
| 3 | Category can be changed on update | Mutable field |

---

### CODE-TRACE: index() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User navigates to Transport Master → Fine Master tab | URL: `?tab=fine_master` |
| 2 | Controller `index()` called | Method entry |
| 3 | **GAP**: No `Gate::authorize('tenant.fine-master.viewAny')` | Any authenticated user can access |
| 4 | DB Query: `SELECT * FROM tpt_fine_master WHERE deleted_at IS NULL ORDER BY created_at DESC LIMIT 20` | `TptFineMaster::latest()->paginate(20)` |
| 5 | No eager loading (`with()` not called) | Relationships lazy-loaded per row (N+1) |
| 6 | For each row: `SELECT * FROM tpt_fine_category WHERE id = ?` | Lazy load fineCategory |
| 7 | For each row: `SELECT * FROM glb_academic_sessions WHERE id = ?` | Lazy load academicSession |
| 8 | Pagination links generated | URL params preserved |
| 9 | View: `fine-master/index.blade.php` rendered | Table with Category, Session, From, To, Type, Rate, Remark, Action |
| 10 | **GAP**: Filter dropdowns (Academic Session, Fine Type) in blade have no controller effect | Decorative only — no where() clauses in index() |

### CODE-TRACE: create() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks "Add Fine Master" button | GET `/transport/fine-master/create` |
| 2 | `Gate::authorize('tenant.fine-master.create')` | Permission check |
| 3 | User without permission → 403 | AuthorizationException |
| 4 | DB Query: `SELECT * FROM tpt_fine_category WHERE is_active = 1` (or all) | Load categories for dropdown |
| 5 | `$fineCategories` collection passed to view | Create form receives categories |
| 6 | View: `fine-master/create.blade.php` rendered | Form with all fields |
| 7 | Form fields: fine_category (select), fine_from_days (number), fine_to_days (number), fine_type (select), fine_rate (number), student_restricted (checkbox), remark (textarea) | All input elements present |

### CODE-TRACE: store() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User fills form and clicks "Save" | POST `/transport/fine-master` |
| 2 | `FineMasterRequest::authorize()` | `Gate::authorize('tenant.fine-master.create')` |
| 3 | `FineMasterRequest::prepareForValidation()` | `$this->merge(['fine_rate' => number_format((float) $this->fine_rate, 2, '.', '')])` |
| 4 | `prepareForValidation()` also normalizes: `$this->merge(['student_restricted' => $this->boolean('student_restricted')])` | Boolean normalization |
| 5 | `FineMasterRequest::rules()` validation | All rules pass |
| 6 | Custom closure: if type=Percentage AND rate>100 → fail | Percentage cap check |
| 7 | If validation fails → redirect back with errors | Form re-displayed with error messages |
| 8 | Controller `store()` begins | `$acadmincData = AcademicSession::where('is_current', '1')->first()` |
| 9 | DB Query: `SELECT * FROM glb_academic_sessions WHERE is_current = 1 LIMIT 1` | Current session fetched |
| 10 | Controller builds create array manually (NOT using $request->validated()) | Explicit field mapping |
| 11 | `'fine_category_id' => $request->fine_category_id` | **PRESENT** — category from dropdown |
| 12 | `'std_academic_sessions_id' => $acadmincData->id` | Current session forced |
| 13 | `'student_restricted' => $request->boolean('student_restricted')` | Boolean normalization (double-normalized) |
| 14 | `$fineMaster = TptFineMaster::create([...])` | INSERT with all fields |
| 15 | DB Query: `INSERT INTO tpt_fine_master (fine_category_id, std_academic_sessions_id, fine_from_days, fine_to_days, fine_type, fine_rate, student_restricted, remark) VALUES (?, ?, ?, ?, ?, ?, ?, ?)` | All values set — no SQL error |
| 16 | `activityLog($fineMaster, 'Created', [...])` | Activity log entry |
| 17 | Redirect to `transport.transport-master.index` | Success redirect (no tab param) |
| 18 | Flash message: `flash('created.fine_master')` | Success toast |

### CODE-TRACE: show() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks "View" on a fine master | GET `/transport/fine-master/{id}` |
| 2 | `Gate::authorize('tenant.fine-master.view')` | Permission check — **PRESENT** |
| 3 | User without permission → 403 | AuthorizationException |
| 4 | DB Query: `SELECT * FROM tpt_fine_master WHERE id = ? AND deleted_at IS NULL` | `findOrFail($id)` |
| 5 | If ID not found → 404 | ModelNotFoundException |
| 6 | No eager loading — relationships lazy-loaded in view | N+1 possible |
| 7 | View: `fine-master/show.blade.php` rendered | All fields displayed |
| 8 | Category name (via `$record->fineCategory->category_name`), session name (via `$record->academicSession->name`), from/to days, type, rate, restricted flag, remark | Full details, lazy-loaded |

### CODE-TRACE: edit() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks "Edit" on a fine master | GET `/transport/fine-master/{id}/edit` |
| 2 | `Gate::authorize('tenant.fine-master.update')` | Permission check |
| 3 | User without permission → 403 | AuthorizationException |
| 4 | DB Query: `SELECT * FROM tpt_fine_master WHERE id = ?` | `findOrFail($id)` |
| 5 | If ID not found → 404 | ModelNotFoundException |
| 6 | DB Query: `SELECT * FROM tpt_fine_category WHERE is_active = 1` | Load active categories for dropdown |
| 7 | DB Query: `SELECT * FROM std_student_academic_sessions` | Load student sessions |
| 8 | `$fineMaster` + `$fineCategories` + `$studentSession` passed to view | 3 variables for form |
| 9 | View: `fine-master/edit.blade.php` rendered | Form pre-filled with current values |
| 10 | Form fields: fine_category, fine_from, fine_to, fine_type, fine_rate, student_restricted, remark | Pre-populated |

### CODE-TRACE: update() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User modifies form and clicks "Update" | PUT `/transport/fine-master/{id}` |
| 2 | `FineMasterRequest::authorize()` | `Gate::authorize('tenant.fine-master.update')` |
| 3 | `FineMasterRequest::prepareForValidation()` | Format fine_rate, normalize student_restricted |
| 4 | `FineMasterRequest::rules()` validation | All rules pass |
| 5 | If validation fails → redirect back with errors | Form re-displayed |
| 6 | Controller `update()` begins | `$fineMaster = TptFineMaster::findOrFail($id)` |
| 7 | DB Query: `SELECT * FROM tpt_fine_master WHERE id = ?` | Find record |
| 8 | `$acadmincData = AcademicSession::where('is_current', '1')->first()` | Current session |
| 9 | DB Query: `SELECT * FROM glb_academic_sessions WHERE is_current = 1` | Session query |
| 10 | Controller builds update array manually (NOT using $request->validated()) | Explicit field mapping |
| 11 | `'fine_category_id' => $request->fine_category_id` | **PRESENT** — category can be changed |
| 12 | `'student_restricted' => $request->student_restricted` (raw, NOT boolean()) | **GAP**: No normalization unlike store() |
| 13 | `'std_academic_sessions_id' => $acadmincData->id` | Session re-set |
| 14 | `$fineMaster->update([...])` | UPDATE query |
| 15 | DB Query: `UPDATE tpt_fine_master SET fine_category_id=?, fine_from_days=?, fine_to_days=?, fine_type=?, fine_rate=?, student_restricted=?, remark=?, std_academic_sessions_id=?, updated_at=NOW() WHERE id = ?` | All columns updated |
| 16 | `activityLog($fineMaster, 'Updated', [...])` | Activity log entry |
| 17 | Redirect to `transport.transport-master.index` | Success redirect (no tab param) |
| 18 | Flash success message: `flash('updated.fine_master')` | Toast notification |

### CODE-TRACE: destroy() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks "Delete" on a fine master | DELETE `/transport/fine-master/{id}` |
| 2 | `Gate::authorize('tenant.fine-master.delete')` | Permission check |
| 3 | User without permission → 403 | AuthorizationException |
| 4 | DB Query: `SELECT * FROM tpt_fine_master WHERE id = ?` | `findOrFail($id)` |
| 5 | If ID not found → 404 | ModelNotFoundException |
| 6 | `$fineMaster->delete()` | Soft delete |
| 7 | DB Query: `UPDATE tpt_fine_master SET deleted_at = NOW() WHERE id = ?` | `deleted_at` timestamp set |
| 8 | **Note**: No `is_active = false` before delete (no is_active column anyway) | N/A |
| 9 | `activityLog($fineMaster, 'Deleted', [...])` | Activity log entry — uses 'Deleted' NOT 'Trashed' |
| 10 | Redirect to `transport.transport-master.index` (no tab param) | Success redirect |
| 11 | Flash message: `flash('deleted.fine_master')` | Success toast |

### CODE-TRACE: trashed() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User navigates to Trash | GET `/transport/fine-master/trash/view` |
| 2 | **GAP**: No `Gate::authorize('tenant.fine-master.restore')` | Any user can view trashed list |
| 3 | DB Query: `SELECT * FROM tpt_fine_master WHERE deleted_at IS NOT NULL ORDER BY created_at DESC` | `onlyTrashed()->latest()->paginate(20)` |
| 4 | If no trashed records → empty state message | "No trashed fine rules found." |
| 5 | Each trashed record shows: Category, Session, Days, Type, Rate, deleted_at timestamp | Table columns |
| 6 | Action column: Restore + Force Delete buttons | `@can` conditions applied |
| 7 | Pagination links if >20 records | Page navigation |

### CODE-TRACE: restore() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks "Restore" on trashed record | GET `/transport/fine-master/{id}/restore` |
| 2 | `Gate::authorize('tenant.fine-master.restore')` | Permission check |
| 3 | User without permission → 403 | AuthorizationException |
| 4 | DB Query: `SELECT * FROM tpt_fine_master WHERE id = ? AND deleted_at IS NOT NULL` | `onlyTrashed()->findOrFail($id)` |
| 5 | If record not trashed (or not found) → 404 | ModelNotFoundException |
| 6 | `$record->restore()` | Set `deleted_at = NULL` |
| 7 | DB Query: `UPDATE tpt_fine_master SET deleted_at = NULL WHERE id = ?` | Restore query |
| 8 | `activityLog($fineMaster, 'Restored', [...])` | Activity log entry |
| 9 | Redirect to `transport.transport-master.index` (no tab param) | Success redirect |
| 10 | Flash message: `flash('restored.fine_master')` | Success toast |

### CODE-TRACE: forceDelete() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks "Force Delete" on trashed record | DELETE `/transport/fine-master/{id}/force-delete` |
| 2 | `Gate::authorize('tenant.fine-master.forceDelete')` | Permission check |
| 3 | User without permission → 403 | AuthorizationException |
| 4 | **GAP**: `TptFineMaster::onlyTrashed()->findOrFail($id)` | Uses `onlyTrashed()` instead of `withTrashed()` |
| 5 | DB Query: `SELECT * FROM tpt_fine_master WHERE id = ? AND deleted_at IS NOT NULL` | `onlyTrashed()` scope |
| 6 | If record is ACTIVE (not deleted) → `onlyTrashed()` returns empty | `findOrFail()` throws 404 |
| 7 | **Correct behavior**: Should use `withTrashed()` | `TptFineMaster::withTrashed()->findOrFail($id)->forceDelete()` |
| 8 | If record IS trashed → found | `$record->forceDelete()` |
| 9 | DB Query: `DELETE FROM tpt_fine_master WHERE id = ?` | Permanent deletion |
| 10 | `activityLog($fineMaster, 'Force Deleted', [...])` | Activity log entry |
| 11 | Redirect to `transport.transport-master.index` | Success redirect |
| 12 | Flash message: `flash('force_deleted.fine_master')` | Success toast |
| 13 | **Impact**: Force-delete of active records always fails (404) | Two-step process required |

---

## 7. Detailed Test Steps

### TC-P-01: Create fixed fine rule [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.fine-master.create` permission | Success |
| 2 | Navigate to `/transport/fine-master/create` | Create form with fields: fine_category (dropdown), fine_from (number), fine_to (number), fine_type (dropdown), fine_rate (number), student_restricted (checkbox), remark (textarea) |
| 3 | Select fine_category = "Late Fee" | Category dropdown populated from `$fineCategories` |
| 4 | Enter fine_from_days = 1 | Number input shows 1 |
| 5 | Enter fine_to_days = 5 | Number input shows 5 |
| 6 | Select fine_type = "Fixed" | Dropdown shows Fixed |
| 7 | Enter fine_rate = 50.00 | Number input shows 50.00 |
| 8 | Leave student_restricted unchecked | Checkbox off → boolean(false) |
| 9 | Leave remark empty | Optional field |
| 10 | Click "Save" | POST to `/transport/fine-master` |
| 11 | **Verify**: `FineMasterRequest@prepareForValidation()` | `number_format(50.00, 2)` = "50.00", `boolean('student_restricted')` = false |
| 12 | **Verify**: `FineMasterRequest@rules()` passes | All validations ok |
| 13 | **Verify**: Custom closure: type=Fixed → no percentage check | Passes (closure only applies to Percentage) |
| 14 | **Verify**: `AcademicSession::where('is_current','1')->first()` | Current session ID retrieved |
| 15 | **Verify**: `TptFineMaster::create()` inserts record | DB row created (note: fine_category_id may cause SQL error — see GAP) |
| 16 | **Verify**: `activityLog($record, 'Created', ...)` called | Activity log entry |
| 17 | **Verify**: Redirect to `transport.transport-master.index?tab=fine_master` | URL has tab param |
| 18 | **Verify**: Flash success message | Success toast |
| 19 | **Verify**: List shows new rule with Category="Late Fee", From=1, To=5, Type="Fixed", Rate="₹ 50.00" | Row displayed |

### TC-P-02: Create percentage fine rule [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.fine-master.create` permission | Success |
| 2 | Navigate to create page | Form loads |
| 3 | Select fine_category = "Late Fee" | Valid category |
| 4 | Enter fine_from = 6, fine_to = 10 | Day range |
| 5 | Select fine_type = "Percentage" | Dropdown selection |
| 6 | Enter fine_rate = 10.00 | Within 100% limit |
| 7 | Click Save | POST to store |
| 8 | **Verify**: Custom closure: type=Percentage, rate=10.00 | 10.00 <= 100 → passes |
| 9 | **Verify**: Record created in DB | `std_academic_sessions_id` = current session |
| 10 | **Verify**: List shows rate as "10 %" (percentage format) | `$item->fine_rate . ' %'` in blade |

### TC-P-03: Create with student_restricted=true [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Fill required fields: category, from=1, to=5, type=Fixed, rate=50 | Valid data |
| 3 | Check "student_restricted" checkbox | Checked |
| 4 | Click Save | POST to store |
| 5 | **Verify**: `$request->boolean('student_restricted')` returns `true` | Normalized to true |
| 6 | **Verify**: `$data['student_restricted'] = true` | Stored as 1 in DB |
| 7 | DB check: `SELECT student_restricted FROM tpt_fine_master` | 1 |
| 8 | **Verify**: Student blocked from boarding if fine unpaid | Downstream effect |

### TC-P-04: Create with student_restricted=false [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Fill required fields | Valid data |
| 3 | Leave student_restricted UNCHECKED | Checkbox off |
| 4 | Click Save | POST to store |
| 5 | **Verify**: `$request->boolean('student_restricted')` returns `false` | Normalized to false |
| 6 | **Verify**: `prepareForValidation` also normalizes | Double normalization |
| 7 | DB check: `SELECT student_restricted FROM tpt_fine_master` | 0 |
| 8 | **Verify**: Student NOT restricted | Normal boarding allowed |

### TC-P-05: Edit fine_from_days from 1 to 2 [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine master with fine_from=1, fine_to=5 | id=X |
| 2 | Navigate to `/transport/fine-master/{id}/edit` | Gate: `tenant.fine-master.update` |
| 3 | Edit form pre-filled with current values | fine_from shows 1 |
| 4 | Change fine_from from 1 to 2 | Updated |
| 5 | Click "Update" | PUT to `/transport/fine-master/{id}` |
| 6 | **Verify**: Validation passes | FineMasterRequest rules |
| 7 | **Verify**: `$record->update([...])` called | DB updated |
| 8 | DB check: `SELECT fine_from_days FROM tpt_fine_master WHERE id = X` | 2 |
| 9 | **Verify**: `activityLog($record, 'Updated', ...)` | Activity entry |
| 10 | **Verify**: Redirect to tab with success | Success toast |

### TC-P-06: Edit fine_type from Fixed to Percentage [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine master with fine_type=Fixed, rate=50 | id=X |
| 2 | Navigate to edit page | Edit form |
| 3 | Change fine_type from "Fixed" to "Percentage" | Dropdown changed |
| 4 | Change fine_rate from 50 to 10 (percentage within limit) | Rate updated |
| 5 | Click Update | PUT submitted |
| 6 | **Verify**: Custom percentage closure: 10 <= 100 | Passes |
| 7 | DB check: `SELECT fine_type, fine_rate FROM tpt_fine_master WHERE id = X` | Percentage, 10.00 |
| 8 | List display: "10 %" | Percentage format |

### TC-P-07: View fine master details [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine master with all fields populated | id=X |
| 2 | Navigate to `/transport/fine-master/{id}` | Show page |
| 3 | **Verify**: **GAP** — No Gate::authorize() | Any user can view |
| 4 | **Verify**: `findOrFail` loads record | Record found |
| 5 | **Verify**: Category name displayed via `fineCategory->category_name` | Relationship loaded |
| 6 | **Verify**: Session name displayed via `academicSession->name` | Relationship loaded |
| 7 | **Verify**: fine_from_days, fine_to_days displayed | Day range |
| 8 | **Verify**: fine_type displayed | "Fixed" or "Percentage" |
| 9 | **Verify**: fine_rate formatted (₹ or %) | Correct format |
| 10 | **Verify**: student_restricted displayed as Yes/No or badge | Boolean display |
| 11 | **Verify**: Remark shown if set | Text displayed |
| 12 | **Verify**: Action buttons: Back, Edit | Navigation available |

### TC-P-08: Soft delete fine master [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine master | id=X, active |
| 2 | Navigate to transport-master tab | Fine master visible in list |
| 3 | Click delete icon on row | DELETE `/transport/fine-master/{id}` |
| 4 | **Verify**: `Gate::authorize('tenant.fine-master.delete')` passes | Authorized |
| 5 | **Verify**: `TptFineMaster::findOrFail($id)` | Record found |
| 6 | **Verify**: `$record->delete()` | Soft delete executed |
| 7 | DB check: `SELECT deleted_at FROM tpt_fine_master WHERE id = X` | deleted_at IS NOT NULL |
| 8 | **Verify**: `activityLog($record, 'Deleted', ...)` called | Activity entry |
| 9 | **Verify**: Record hidden from index list | `deleted_at IS NOT NULL` filtered by default scope |
| 10 | **Verify**: Record visible in trash | `TptFineMaster::onlyTrashed()` finds it |
| 11 | **Verify**: Redirect to tab with success | Toast notification |

### TC-P-09: Restore soft-deleted fine master [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete fine master X | deleted_at set |
| 2 | Navigate to trash: `/transport/fine-master/trash/view` | Trash list shows record |
| 3 | Click "Restore" on trashed record | GET `/transport/fine-master/{id}/restore` |
| 4 | **Verify**: `Gate::authorize('tenant.fine-master.restore')` passes | Authorized |
| 5 | **Verify**: `TptFineMaster::onlyTrashed()->findOrFail($id)` | Found in trash |
| 6 | **Verify**: `$record->restore()` | deleted_at = NULL |
| 7 | DB check: `SELECT deleted_at FROM tpt_fine_master WHERE id = X` | NULL |
| 8 | **Verify**: `activityLog($record, 'Restored', ...)` called | Activity entry |
| 9 | **Verify**: Record back in active list | Visible in index tab |
| 10 | **Verify**: Redirect with success | Toast notification |

### TC-P-10: Force delete trashed fine master [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete fine master X first | deleted_at set |
| 2 | Navigate to trash: `/transport/fine-master/trash/view` | Record visible in trash |
| 3 | Click "Force Delete" on trashed record | DELETE `/transport/fine-master/{id}/force-delete` |
| 4 | **Verify**: `Gate::authorize('tenant.fine-master.forceDelete')` passes | Authorized |
| 5 | **Verify**: `TptFineMaster::onlyTrashed()->findOrFail($id)` | Found (record is trashed) |
| 6 | **Verify**: `$record->forceDelete()` | Permanently deleted |
| 7 | DB check: `SELECT * FROM tpt_fine_master WHERE id = X` | Record gone |
| 8 | **Verify**: `activityLog($record, 'Force Deleted', ...)` called | Activity entry |
| 9 | **Verify**: Redirect back with success | Toast notification |

### TC-P-11: Filter by Academic Session [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster A with session_id=1, FineMaster B with session_id=2 | Different sessions |
| 2 | Navigate to transport-master tab | Tab `fine_master-pane` active |
| 3 | Select Academic Session = "2025-26" (id=1) | Dropdown selection |
| 4 | Click Search/Submit | GET with `?tab=fine_master&academic_sessions_id=1` |
| 5 | **Verify**: Controller adds `->where('std_academic_sessions_id', 1)` | Filter applied |
| 6 | **Verify**: Only FineMaster A displayed | FineMaster B filtered out |
| 7 | **Verify**: Pagination links include filter param | `?academic_sessions_id=1&page=...` |

### TC-P-12: Filter by Fine Type [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster A (Fixed), FineMaster B (Percentage) | Different types |
| 2 | Navigate to transport-master tab | List shows both |
| 3 | Select Fine Type = "Fixed" | Dropdown selection |
| 4 | Click Search | GET with `?tab=fine_master&fine_type=Fixed` |
| 5 | **Verify**: Controller adds `->where('fine_type', 'Fixed')` | Filter applied |
| 6 | **Verify**: Only Fixed type records shown | Percentage records hidden |
| 7 | **Verify**: Both filters can combine with session | Combined WHERE clause |

### TC-P-13: Create with remark text [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Fill required fields: category, from=1, to=5, type=Fixed, rate=50 | Valid |
| 3 | Enter remark = "Late fee for first week of late payment" | Textarea input |
| 4 | Click Save | POST |
| 5 | **Verify**: Validation: remark nullable, string, max:255 | Passes |
| 6 | **Verify**: Remark saved to DB | `$record->remark` = "Late fee for first week of late payment" |
| 7 | **Note**: `remark` (lowercase) in fillable maps to `Remark` (capital R) in DDL | Case sensitivity concern |

### TC-P-14: Edit without changes (no-op update) [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine master X | id=X |
| 2 | Navigate to edit page | Form pre-filled |
| 3 | Click "Update" without changing any fields | PUT submitted |
| 4 | **Verify**: Validation passes | All rules pass |
| 5 | **Verify**: `$record->update()` with same values | No change but SQL update still executed |
| 6 | **Verify**: Redirect with success | Toast shown |
| 7 | **Verify**: No SQL error (but `updated_at` may cause error if column missing) | Depends on DDL |

### TC-P-15: Index redirects to tab [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/transport/fine-master` | GET request |
| 2 | **Verify**: 302 redirect status | Redirect response |
| 3 | **Verify**: Location header | `/transport/transport-master?tab=fine_master` |
| 4 | Browser follows redirect | Tab `fine_master-pane` shown |

### TC-P-16: Pagination shows with 21+ records [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 21 fine master records | 21 rows in DB |
| 2 | Navigate to transport-master tab | Tab loads |
| 3 | **Verify**: Only 20 records on page 1 | `paginate(20)` |
| 4 | **Verify**: Pagination links visible | Page 1, Page 2, Next |
| 5 | Click Page 2 | URL: `?tab=fine_master&page=2` |
| 6 | **Verify**: 1 record on page 2 (out of 21) | Remaining record |
| 7 | Cleanup: Delete all test records | DB cleanup |

### TC-P-17: Pagination hidden with <20 records [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create only 5 fine master records | 5 rows |
| 2 | Navigate to transport-master tab | Tab loads |
| 3 | **Verify**: Pagination links NOT visible | `< 20` records, single page |
| 4 | **Verify**: All 5 records shown | Full list |

### TC-P-18: Pagination preserves tab parameter [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 21 fine master records | Pagination needed |
| 2 | Navigate to transport-master tab | URL: `?tab=fine_master` |
| 3 | Click Page 2 link | URL: `?tab=fine_master&page=2` |
| 4 | **Verify**: tab=fine_master preserved in URL | Tab param not lost |
| 5 | **Verify**: Correct second page displayed | Records 21-40 or 1 record |

### TC-P-19: Create with fine_from=0, fine_to=0 [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter fine_from=0, fine_to=0 | Zero-day range |
| 3 | Select category, type=Fixed, rate=50 | Valid data |
| 4 | Click Save | POST |
| 5 | **Verify**: `min:0` rule passes for fine_from=0 | Valid |
| 6 | **Verify**: `gte:fine_from_days` passes for fine_to=0 | 0 >= 0 → valid |
| 7 | **Verify**: Record created | DB row with from=0, to=0 |
| 8 | **Note**: Zero-day range means fine applies immediately on due date | Business edge case |

### TC-P-20: Create with rate=0.00 (zero fine) [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter fine_rate = 0.00 | Zero rate |
| 3 | Fill other required fields | Valid data |
| 4 | Click Save | POST |
| 5 | **Verify**: `min:0` rule passes for rate=0 | Valid |
| 6 | **Verify**: `number_format(0, 2)` = "0.00" | Formatted |
| 7 | DB check: `SELECT fine_rate FROM tpt_fine_master` | 0.00 |

### TC-P-21: Show trashed list when items exist [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 3 fine masters | deleted_at set for 3 records |
| 2 | Navigate to `/transport/fine-master/trash/view` | Trash page |
| 3 | **Verify**: 3 trashed records displayed | Table rows |
| 4 | **Verify**: Each record shows: Category, Session, Days, Type, Rate, deleted_at | Columns present |
| 5 | **Verify**: Action column: Restore + Force Delete buttons | @can conditions |

### TC-P-22: Empty trash shows message [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no trashed fine masters | All records active or deleted permanently |
| 2 | Navigate to `/transport/fine-master/trash/view` | Trash page |
| 3 | **Verify**: "No trashed fine rules found" message displayed | Empty state |
| 4 | **Verify**: No records in table | Empty table body |

### TC-P-23: Create with misspelled student_rusticated [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fillable` | Contains `'student_rusticated'` (misspelled) |
| 2 | Create form uses `student_rusticated` as checkbox name | Form field name |
| 3 | Fill all fields, check `student_rusticated` | Checkbox checked |
| 4 | Click Save | POST with `student_rusticated=on` |
| 5 | **Verify**: `prepareForValidation()` normalizes `student_restricted` by calling `$this->boolean('student_restricted')` | Correct field name used in normalization |
| 6 | **Verify**: Misspelled `student_rusticated` maps to `student_restricted` column via fillable | Works because both in fillable |
| 7 | DB check: `SELECT student_restricted FROM tpt_fine_master` | 1 |

### TC-P-24: View fine master with category relationship [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster with fine_category_id referencing "Late Fee" category | id=X |
| 2 | Navigate to show page | `/transport/fine-master/{id}` |
| 3 | **Verify**: Category name "Late Fee" displayed | `$item->fineCategory->category_name` |
| 4 | **Verify**: If category deleted (RESTRICT prevents this), shows "-" | Null-safe `?? '-'` |

### TC-P-25: View fine master with session relationship [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster with current academic session | Session auto-assigned |
| 2 | Navigate to show page | `/transport/fine-master/{id}` |
| 3 | **Verify**: Session name displayed (e.g., "2025-26") | `$item->academicSession->name` |
| 4 | **Verify**: If session missing, shows "-" | Null-safe `?? '-'` |

### TC-N-01: Create with invalid fine_category_id [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Select fine_category_id = 99999 (non-existent) | Or manipulate POST data |
| 3 | Fill other required fields | Valid data |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'fine_category_id' => 'exists:tpt_fine_category,id'` | "The selected fine category id is invalid." |
| 6 | **Verify**: Record NOT created | No new DB row |
| 7 | **Verify**: Form re-displayed with error | Error message on category field |

### TC-N-02: fine_to_days < fine_from_days [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter fine_from_days = 5 | From value set |
| 3 | Enter fine_to_days = 1 | To value LESS than from |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'fine_to_days' => 'gte:fine_from_days'` | 1 >= 5 → false |
| 6 | **Verify**: "Fine to days must be greater than or equal to fine from days." | Error message |
| 7 | **Verify**: Record NOT created | DB unchanged |

### TC-N-03: fine_rate > 999.99 [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter fine_rate = 1000 | Exceeds 999.99 |
| 3 | Fill other required fields | Valid |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'fine_rate' => 'max:999.99'` | 1000 > 999.99 → fails |
| 6 | **Verify**: "Fine rate cannot exceed 999.99." | Error displayed |
| 7 | **Verify**: Record NOT created | DB unchanged |

### TC-N-04: Percentage rate > 100 [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Select fine_type = "Percentage" | Percentage mode |
| 3 | Enter fine_rate = 150 | Exceeds 100% |
| 4 | Click Save | POST |
| 5 | **Verify**: Custom closure: `$this->fine_type === 'Percentage' && $value > 100` | true |
| 6 | **Verify**: "Percentage fine rate cannot exceed 100%." | Custom error message |
| 7 | **Verify**: Record NOT created | DB unchanged |

### TC-N-05: Invalid fine_type [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Select/inject fine_type = "Discount" (or any non-valid value) | Not in allowed list |
| 3 | Click Save | POST |
| 4 | **Verify**: Rule `'fine_type' => 'in:Fixed,Percentage'` | "Discount" not in allowed |
| 5 | **Verify**: "The selected fine type is invalid." | Error message |
| 6 | **Verify**: Record NOT created | DB unchanged |

### TC-N-06: Empty fine_category_id [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Leave fine_category dropdown unselected | null/empty |
| 3 | Fill other fields | Valid |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'fine_category_id' => 'required'` | Fails |
| 6 | **Verify**: "Fine category is required." | Error message |

### TC-N-07: Empty fine_from_days [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Leave fine_from_days empty | Empty input |
| 3 | Fill fine_to_days, type, rate | Other fields filled |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'fine_from_days' => 'required'` | Fails |
| 6 | **Verify**: "Fine from days is required." | Error message |
| 7 | **Verify**: Form re-displayed, previous values preserved | Validation errors shown |

### TC-N-08: Access without permission [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.fine-master.*` permissions | No fine-master perms |
| 2 | Navigate to `/transport/fine-master/create` | `Gate::authorize()` → 403 |
| 3 | POST to `/transport/fine-master` with valid data | `FineMasterRequest::authorize()` → 403 |
| 4 | Navigate to `/transport/fine-master/{id}/edit` | Gate → 403 |
| 5 | PUT to `/transport/fine-master/{id}` | Gate → 403 |
| 6 | DELETE to `/transport/fine-master/{id}` | Gate → 403 |
| 7 | GET `/transport/fine-master/{id}/restore` | Gate → 403 |
| 8 | DELETE `/transport/fine-master/{id}/force-delete` | Gate → 403 |
| 9 | **Note**: `index()`, `show()`, `trashed()` have NO Gate | These pages accessible without permission (**GAP**) |

### TC-N-09: Show non-existent ID [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/transport/fine-master/99999` | Non-existent ID |
| 2 | **Verify**: `TptFineMaster::findOrFail(99999)` | ModelNotFoundException |
| 3 | **Verify**: 404 error response | "No query results" page |

### TC-N-10: Restore non-trashed record [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active FineMaster (not deleted) | id=X, deleted_at=NULL |
| 2 | Call GET `/transport/fine-master/{id}/restore` | Restore endpoint |
| 3 | **Verify**: `Gate::authorize('tenant.fine-master.restore')` passes | Authorized |
| 4 | **Verify**: `TptFineMaster::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` → WHERE deleted_at IS NOT NULL |
| 5 | Active record has deleted_at=NULL → not found | `findOrFail()` throws 404 |
| 6 | **Verify**: 404 response | "No query results" |

### TC-N-11: Force delete active (non-trashed) record [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active FineMaster (not deleted) | id=X, deleted_at=NULL |
| 2 | Call DELETE `/transport/fine-master/{id}/force-delete` | Force delete endpoint |
| 3 | **Verify**: `Gate::authorize('tenant.fine-master.forceDelete')` passes | Authorized |
| 4 | **Verify**: `TptFineMaster::onlyTrashed()->findOrFail($id)` | **GAP**: uses onlyTrashed() |
| 5 | Record not trashed → not found by onlyTrashed() | `findOrFail()` throws 404 |
| 6 | **Verify**: 404 error | "No query results" |
| 7 | **Expected fix**: Should use `withTrashed()->findOrFail($id)->forceDelete()` | **GAP**: forceDelete unusable on active records |

### TC-N-12: Delete fine master with FK reference [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure FineMaster X is referenced by a tpt_student_fine_detail record | FK exists |
| 2 | Attempt to DELETE `/transport/fine-master/{id}` | Normal soft delete |
| 3 | **Note**: Soft delete (set deleted_at) works because FK doesn't check NULL | Soft delete succeeds |
| 4 | Attempt to force-delete `/transport/fine-master/{id}/force-delete` | Permanently delete |
| 5 | If tpt_student_fine_detail has FK to tpt_fine_master with RESTRICT | Integrity constraint violation |
| 6 | **Verify**: FK violation prevents permanent deletion of referenced record | Error thrown |
| 7 | **Note**: FK from tpt_student_fine_detail.fine_master_id → tpt_fine_master.id | Downstream reference |

### TC-N-13: Edit non-existent ID [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/transport/fine-master/99999/edit` | Non-existent |
| 2 | `Gate::authorize('tenant.fine-master.update')` | Passes (Gate check doesn't validate existence) |
| 3 | `TptFineMaster::findOrFail(99999)` | ModelNotFoundException |
| 4 | **Verify**: 404 error | "No query results" |

### TC-N-14: Create with remark > 255 chars [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter remark = 256-character string | Exceeds max:255 |
| 3 | Fill other fields | Valid |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'remark' => 'max:255'` | Fails |
| 6 | **Verify**: "The remark must not be greater than 255 characters." | Error displayed |
| 7 | **Verify**: Record NOT created | DB unchanged |

### TC-N-15: Missing fine_type [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Leave fine_type unselected | Empty |
| 3 | Fill other fields | Valid |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'fine_type' => 'required'` | Fails |
| 6 | **Verify**: "Fine type is required." | Error |

### TC-N-16: Missing fine_rate [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Leave fine_rate empty | Empty |
| 3 | Fill other fields | Valid |
| 4 | Click Save | POST |
| 5 | **Verify**: Rule `'fine_rate' => 'required'` | Fails |
| 6 | **Verify**: "Fine rate is required." | Error |

### TC-N-17: fine_from_days negative [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter fine_from_days = -1 | Negative value |
| 3 | Click Save | POST |
| 4 | **Verify**: Rule `'fine_from_days' => 'min:0'` | -1 < 0 → fails |
| 5 | **Verify**: "Fine from days must be at least 0." | Error |

### TC-N-18: fine_rate negative [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create page | Form loads |
| 2 | Enter fine_rate = -10 | Negative value |
| 3 | Click Save | POST |
| 4 | **Verify**: Rule `'fine_rate' => 'min:0'` | -10 < 0 → fails |
| 5 | **Verify**: "Fine rate must be at least 0." | Error |

### TC-N-19: Force delete non-existent ID [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call DELETE `/transport/fine-master/99999/force-delete` | Non-existent |
| 2 | `Gate::authorize('tenant.fine-master.forceDelete')` | Passes |
| 3 | `TptFineMaster::onlyTrashed()->findOrFail(99999)` | ModelNotFoundException |
| 4 | **Verify**: 404 error | "No query results" |

### TC-N-20: Guest access redirect to login [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated user) | Guest session |
| 2 | Navigate to `/transport/fine-master/create` | GET request |
| 3 | **Verify**: Redirect to `/login` | Authentication required |
| 4 | Navigate to `/transport/fine-master` index | Redirect to login |
| 5 | All protected routes redirect to login | Standard Laravel auth |

### TC-N-21: Delete non-existent fine master [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call DELETE `/transport/fine-master/99999` | Non-existent |
| 2 | `Gate::authorize('tenant.fine-master.delete')` | Passes |
| 3 | `TptFineMaster::findOrFail(99999)` | ModelNotFoundException |
| 4 | **Verify**: 404 error | "No query results" |

### TC-D-01: Verify current academic session auto-assigned [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check that current academic session exists: `SELECT * FROM glb_academic_sessions WHERE is_current = 1` | exists |
| 2 | Create fine master without providing session_id | Session is NOT in form |
| 3 | **Verify**: Controller line: `AcademicSession::where('is_current', '1')->first()` | Returns session object |
| 4 | **Verify**: `$data['std_academic_sessions_id'] = $currentSession->id` | Auto-assigned |
| 5 | DB check: `SELECT std_academic_sessions_id FROM tpt_fine_master` | Matches current session ID |

### TC-D-02: Verify student_restricted boolean consistency [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` method | `$data['student_restricted'] = $request->boolean('student_restricted')` |
| 2 | Open `update()` method | `$data['student_restricted'] = $request->student_restricted` |
| 3 | **GAP**: store normalizes via `boolean()`, update uses raw value | Different behavior |
| 4 | **Test**: store with checkbox unchecked → boolean() = false | Stored as 0 |
| 5 | **Test**: update with checkbox unchecked → `$request->student_restricted` = null | Stored as NULL (may cause error if column NOT NULL) |

### TC-D-03: Verify remark vs Remark case sensitivity [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fillable` | Contains `'remark'` (lowercase) |
| 2 | Open DDL: `tpt_fine_master` | Column is `` `Remark` `` (capital R) |
| 3 | On MySQL with `lower_case_table_names=1` (default Windows/macOS) | Case-insensitive → works |
| 4 | On MySQL with `lower_case_table_names=0` (Linux) | Case-sensitive → fillable `remark` maps to column `remark` NOT `Remark` |
| 5 | **Impact**: On Linux, remark data may be stored in wrong/non-existent column | **GAP** for Linux deployments |

### TC-D-04: Verify forceDelete on active record fails [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster (active, not deleted) | deleted_at = NULL |
| 2 | Call forceDelete endpoint | DELETE `/transport/fine-master/{id}/force-delete` |
| 3 | **Verify**: `TptFineMaster::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` filters WHERE deleted_at IS NOT NULL |
| 4 | Record has deleted_at=NULL → not found by onlyTrashed() | 404 thrown |
| 5 | **Expected**: `TptFineMaster::withTrashed()->findOrFail($id)->forceDelete()` | Should find via withTrashed() |
| 6 | **Workaround**: Must soft-delete first, then force-delete | Two-step process |

### TC-D-05: Verify soft delete lifecycle [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineMaster X | id=X, deleted_at=NULL |
| 2 | Soft delete: `$record->delete()` | deleted_at = NOW() |
| 3 | DB: `SELECT * FROM tpt_fine_master WHERE id = X` | deleted_at IS NOT NULL |
| 4 | Normal query: `TptFineMaster::find(X)` | NULL (excluded by default) |
| 5 | Trashed query: `TptFineMaster::onlyTrashed()->find(X)` | Found |
| 6 | Restore: `$record->restore()` | deleted_at = NULL |
| 7 | Normal query: `TptFineMaster::find(X)` | Found again |
| 8 | Force delete: `$record->forceDelete()` | Record permanently removed |
| 9 | DB: `SELECT * FROM tpt_fine_master WHERE id = X` | Empty (record gone) |

### TC-D-06: Verify FK RESTRICT prevents category deletion [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create FineCategory C1 | tpt_fine_category id = C1 |
| 2 | Create FineMaster referencing C1 | fine_category_id = C1 |
| 3 | Attempt to delete C1: `DELETE FROM tpt_fine_category WHERE id = C1` | FK constraint: `fk_fm_fine_category` ON DELETE RESTRICT |
| 4 | **Verify**: Integrity constraint violation | "Cannot delete or update a parent row: a foreign key constraint fails" |
| 5 | Must delete FineMaster first, then delete Category | RESTRICT protection |
| 6 | Soft-deleting FineMaster still prevents category deletion | RESTRICT checks actual existence, not deleted_at |

### TC-D-07: Verify updated_at auto-managed [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for tpt_fine_master | `updated_at` column — check if present in migration |
| 2 | If DDL has no updated_at column | Model's `$timestamps = true` tries to set `updated_at` on every update |
| 3 | **Potential SQL error**: `UPDATE tpt_fine_master SET ..., updated_at = NOW() WHERE id = ?` | "Unknown column 'updated_at'" |
| 4 | If DDL has updated_at → works normally | Timestamp managed by Eloquent |
| 5 | **DEV-FM-05**: Documented as medium severity issue | Migration may not have timestamps() |

### TC-D-08: Verify rate stored as DECIMAL(5,2) [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine master with fine_rate = 50.555 | Three decimal places |
| 2 | **Verify**: `number_format(50.555, 2, '.', '')` in prepareForValidation | Returns "50.56" (rounded) |
| 3 | DB check: `SELECT fine_rate FROM tpt_fine_master` | 50.56 (rounded) or 50.55 (truncated) |
| 4 | DECIMAL(5,2) stores exactly 2 decimal places | Precision enforced |

### TC-D-09: Verify student_restricted cast to boolean [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:casts` | `'student_restricted' => 'boolean'` |
| 2 | DB stores 1 → `$model->student_restricted` | Returns `true` (boolean) |
| 3 | DB stores 0 → `$model->student_restricted` | Returns `false` (boolean) |
| 4 | PHP type check: `is_bool($model->student_restricted)` | true |
| 5 | Blade conditional: `@if($item->student_restricted)` | Works correctly with boolean cast |

### TC-D-10: Verify activity log entries [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create fine master | Activity log: "Created" event |
| 2 | Update fine master | Activity log: "Updated" event |
| 3 | Soft delete fine master | Activity log: "Deleted" event |
| 4 | Restore fine master | Activity log: "Restored" event |
| 5 | Force delete fine master | Activity log: "Force Deleted" event |
| 6 | DB check: `SELECT * FROM sp_activity_logs WHERE subject_type = 'TptFineMaster'` | 5 log entries with correct event names |

### TC-CR-01: GAP — index() missing Gate [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterController.php:index()` | Method entry |
| 2 | Search for `Gate::authorize()` or `$this->authorize()` | **NOT FOUND** |
| 3 | Compare with create() which HAS Gate | `index()` has no authorization |
| 4 | Navigate to transport-master tab without permission | Page loads (no 403) |
| 5 | **Impact**: Any authenticated user can see fine masters listing | Authorization gap |

### TC-CR-02: GAP — show() missing Gate [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterController.php:show()` | Method entry |
| 2 | Search for `Gate::authorize('tenant.fine-master.view')` | **NOT FOUND** |
| 3 | Access show page without permission | Page loads (no 403) |
| 4 | **Impact**: Any user can view fine master details | Authorization gap |

### TC-CR-03: GAP — trashed() missing Gate [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterController.php:trashed()` | Method entry |
| 2 | Search for `Gate::authorize('tenant.fine-master.restore')` | **NOT FOUND** |
| 3 | Access trash page without permission | Page loads (no 403) |
| 4 | **Impact**: Any user can see trashed fine masters | Authorization gap |

### TC-CR-04: GAP — forceDelete() uses onlyTrashed() [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterController.php:forceDelete()` | Method entry |
| 2 | Check line: `TptFineMaster::onlyTrashed()->findOrFail($id)` | Uses `onlyTrashed()` |
| 3 | Compare with correct pattern (ShiftController) | `Shift::withTrashed()->findOrFail($id)` |
| 4 | **Test**: Call forceDelete on ACTIVE (non-deleted) record | `onlyTrashed()` returns NULL → 404 |
| 5 | **Test**: Call forceDelete on TRASHED record | `onlyTrashed()` finds it → success |
| 6 | **Impact**: Cannot force-delete an active record in one step | Must delete then force-delete |

### TC-CR-05: GAP — student_restricted inconsistency [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` method | `$data['student_restricted'] = $request->boolean('student_restricted')` |
| 2 | Open `update()` method | `$data['student_restricted'] = $request->student_restricted` |
| 3 | `boolean()` returns `false` for missing field | Store: safe default |
| 4 | Raw `$request->student_restricted` returns null for missing field | Update: may store null |
| 5 | **Fix needed**: update() should also use `$request->boolean()` | Inconsistent normalization |

### TC-CR-06: GAP — remark/Remark case mismatch [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fillable` | `'remark'` (lowercase) |
| 2 | Open DDL: tpt_fine_master | `` `Remark` `` (capital R) |
| 3 | On case-sensitive MySQL: fillable `remark` → column `remark` | But DDL has `Remark` |
| 4 | `$fillable` maps to column `remark`, DDL has `Remark` | Extra column `remark` created? Or fillable fails? |
| 5 | On case-insensitive MySQL (default on Windows) | Works fine — `remark` matches `Remark` |

### TC-CR-07: fine_rate formatted via number_format [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterRequest.php:prepareForValidation()` | `$this->merge(['fine_rate' => number_format((float) $this->fine_rate, 2, '.', '')])` |
| 2 | Input "50" → `(float)` = 50.0 → `number_format(50.0, 2)` = "50.00" | String "50.00" |
| 3 | Input "abc" → `(float)` = 0.0 → `number_format(0.0, 2)` = "0.00" | String "0.00" (silent error) |
| 4 | Input "50.5" → `(float)` = 50.5 → `number_format(50.5, 2)` = "50.50" | String "50.50" |

### TC-CR-08: Percentage > 100 custom rule [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `FineMasterRequest.php` custom closure | `function ($attribute, $value, $fail) { ... }` |
| 2 | Condition: `$this->fine_type === 'Percentage' && $value > 100` | Triggers for percentage > 100 |
| 3 | Error message: "Percentage fine rate cannot exceed 100%." | Custom message |
| 4 | **Test**: type=Percentage, rate=100 | Passes (100 is NOT > 100) |

### TC-CR-09: Current session logic [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` method | `AcademicSession::where('is_current','1')->first()` |
| 2 | Open `update()` method | Same query |
| 3 | DB Query: `SELECT * FROM glb_academic_sessions WHERE is_current = 1 LIMIT 1` | Returns single session |
| 4 | If no current session → `$currentSession` is null → `$currentSession->id` throws error | **Null pointer risk** |

### TC-CR-10: Model relationships [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fineCategory()` | `return $this->belongsTo(TptFineCategory::class, 'fine_category_id')` |
| 2 | Open `TptFineMaster.php:academicSession()` | `return $this->belongsTo(AcademicSession::class, 'std_academic_sessions_id')` |
| 3 | Both are `belongsTo` relationships | Singular naming |

### TC-CR-11: No toggleStatus() method [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search FineMasterController for `toggleStatus` | **NOT FOUND** |
| 2 | Search for `is_active` in controller | **NOT FOUND** |
| 3 | Compare with FineCategoryController which HAS toggleStatus | FineMaster lacks status toggle |
| 4 | Blades have no status column or toggle switch | No is_active in UI |

### TC-CR-12: No is_active field in blades [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `fine-master/index.blade.php` | Table columns: Category, Session, From, To, Type, Rate, Remark, Action |
| 2 | No Status column | No toggle switch |
| 3 | Open `fine-master/create.blade.php` | No is_active checkbox |
| 4 | Open `fine-master/edit.blade.php` | No is_active field |

### TC-CR-13: Rate display format in blade [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open index blade | `$item->fine_type == 'Percentage' ? $item->fine_rate . ' %' : '₹ ' . $item->fine_rate` |
| 2 | Record: type=Percentage, rate=10 | Displays "10 %" |
| 3 | Record: type=Fixed, rate=50 | Displays "₹ 50.00" |
| 4 | **Note**: Hardcoded currency symbol ₹ | Not localization-friendly |

### TC-CR-14: DDL has no is_active column [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open DDL for tpt_fine_master | Columns: id, fine_category_id, std_academic_sessions_id, fine_from_days, fine_to_days, fine_type, fine_rate, student_restricted, Remark, created_at, deleted_at |
| 2 | NO `is_active` column | By design — no status concept |
| 3 | NO `updated_at` column | **GAP**: Model expects it |

### TC-CR-15: FK RESTRICT on fine_category_id [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open DDL | `FOREIGN KEY (fine_category_id) REFERENCES tpt_fine_category(id) ON DELETE RESTRICT` |
| 2 | **RESTRICT**: Cannot delete category if fine master references it | Prevents orphan records |
| 3 | **Note**: Not CASCADE — category deletion blocked | Data integrity protection |

### TC-CR-16: GAP — student_rusticated misspelling [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TptFineMaster.php:fillable` | Contains `'student_rusticated'` (sic) |
| 2 | Correct spelling: `student_restricted` | Also present |
| 3 | Form uses `student_rusticated` (misspelled) as field name | Browser test confirms |
| 4 | Both spellings work due to mass assignment | Intentionally included as fallback |

### TC-CR-17: GAP — updated_at mismatch [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for tpt_fine_master | `updated_at` column status |
| 2 | Check migration for `$table->timestamps()` or `$table->timestamp('updated_at')` | May be missing |
| 3 | Model: `class TptFineMaster extends Model` | `$timestamps = true` by default |
| 4 | On update: Laravel sets `updated_at = NOW()` | SQL error if column missing |
| 5 | **DEV-FM-05**: Documented as medium severity | Migration fix needed |

### TC-CR-18: GAP — No DB::transaction in CUD [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `store()` for `DB::beginTransaction()` | **NOT PRESENT** |
| 2 | Check `update()` for `DB::beginTransaction()` | **NOT PRESENT** |
| 3 | Check `destroy()` for `DB::beginTransaction()` | **NOT PRESENT** |
| 4 | If exception occurs after partial write, DB is inconsistent | No rollback mechanism |
| 5 | Compare with PickupPointRouteController which wraps all CUD in transactions | Inconsistent pattern |

### TC-CR-19: No change tracking in update [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `update()` method | Calls `$record->update($data)` directly |
| 2 | No `$record->getOriginal()` before update | No "before" snapshot |
| 3 | No `$record->getChanges()` after update | No "what changed" tracking |
| 4 | Activity log uses generic "Updated" | Doesn't log specific field changes |

### TC-CR-20: fine_category_id never set in controller [detailed test]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `store()`: `$data = $request->validated()` | Returns validated fields |
| 2 | Check `$data` keys: fine_from_days, fine_to_days, fine_type, fine_rate, student_restricted, remark | **fine_category_id MISSING** |
| 3 | Controller never adds `$data['fine_category_id']` | **CRITICAL** |
| 4 | DDL: `fine_category_id TINYINT UNSIGNED NOT NULL` | Cannot be null |
| 5 | `TptFineMaster::create($data)` → INSERT with fine_category_id = NULL | **SQL ERROR**: "Column 'fine_category_id' cannot be null" |
| 6 | **CRITICAL BUG**: Store is completely broken | All create operations fail |

---

*Template: tpt_Route_TcList.md (Syllabus depth) | Entity: FineMaster | Date: 2026-07-21*
