# hrs_PtSlabs_TcList

## Module: HrStaff → HR Masters → PT Slabs

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters |
| Feature | PT Slabs |
| URL(s) | `GET /hr-masters?tab=pt-slabs` (tab view), `GET /pt-slabs` (index — redirects to tab), `POST /pt-slabs` (store), `GET /pt-slabs/{ptSlab}` (show), `GET /pt-slabs/{ptSlab}/edit` (edit), `PUT /pt-slabs/{ptSlab}` (update), `DELETE /pt-slabs/{ptSlab}` (destroy), `POST /pt-slabs/{ptSlab}/toggle-status` (toggleStatus), `GET /pt-slabs/trash/view` (trashed), `GET /pt-slabs/{id}/restore` (restore), `DELETE /pt-slabs/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\PtSlabController` |
| Model(s) | `Modules\HrStaff\Models\PtSlab` (table: `hrs_pt_slabs`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StorePtSlabRequest` |
| Policy | None (direct gate in controller) |
| Permissions | `hrs.compliance.manage` |
| Pagination | Full collection in tab view; 15 records per page in trash view |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` sets `is_active=false` before `delete()`; restore sets `is_active=true` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Deleted (force delete) |

---

## 2. Pre-conditions

- Required permissions: `hrs.compliance.manage`
- No seed data required — PT slabs can be created fresh
- Test user must have `hrs.compliance.manage` permission (default admin user)
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For unique-key collision tests: At least one PT slab with a given (state_code, min_salary) combination
- No delete dependency guards (PT slabs can be freely deleted)

---

## 3. Default Data Load

When the page loads via `HrMenuController@hrMasters()` (`GET /hr-masters` with `tab=pt-slabs`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| PT Slabs Grid | `HrMenuController@hrMasters()` | `PtSlab::orderBy('state_code')->orderBy('min_salary')` | search (state_code) | None (full collection) |

---

## 4. Test Data Strategy

- **State code**: Use 2-letter ISO codes (HP, KA, MH, TN, etc.); always uppercase
- **Slab ranges**: Use realistic ranges — test with open-ended top slab (max_salary = 999999999.00)
- **Unique constraint**: Composite unique on (state_code, min_salary) — avoid collision with test suffix
- **Pre-test cleanup**: Delete created slabs by state_code + min_salary before/after tests
- **No pagination in main view**: All slabs shown in one list (full collection)

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_pt_slabs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | state_code | VARCHAR(5) | NOT NULL |
| BC-DB-03 | min_salary | DECIMAL(10,2) | NOT NULL |
| BC-DB-04 | max_salary | DECIMAL(10,2) | NOT NULL |
| BC-DB-05 | pt_amount | DECIMAL(8,2) | NOT NULL |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-07 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-08 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-09 | created_at | TIMESTAMP | NULL |
| BC-DB-10 | updated_at | TIMESTAMP | NULL |
| BC-DB-11 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Validation Rules — `StorePtSlabRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | state_code | required, string, size:2, uppercase, unique:hrs_pt_slabs,state_code scoped to min_salary (ignore $id, whereNull deleted_at) | "The state code has already been taken." |
| BC-VAL-02 | min_salary | required, numeric, min:0 | — |
| BC-VAL-03 | max_salary | required, numeric, gt:min_salary | "The max salary field must be greater than min salary." |
| BC-VAL-04 | pt_amount | required, numeric, min:0 | — |
| BC-VAL-05 | is_active | required, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.compliance.manage` | All controller methods require gate; without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with `tab=pt-slabs` | PT slabs list displayed in tab, ordered by state_code then min_salary |
| BC-BIZ-02 | Search by state_code | Grid filtered to matching state code |
| BC-BIZ-03 | Create with auto-uppercased state code | "mh" → "MH" in prepareForValidation() |
| BC-BIZ-04 | Create with is_active default=true | is_active=1 |
| BC-BIZ-05 | Unique composite (state_code, min_salary) | Duplicate combo blocked |
| BC-BIZ-06 | Empty grid | Empty message shown |
| BC-BIZ-07 | Toggle status active→inactive | AJAX toggles is_active |
| BC-BIZ-08 | Screen loads via tab GET /hr-masters?tab=pt-slabs | Tab view shows all slabs |
| BC-BIZ-09 | Standalone index redirects | PtSlabController@index() redirects to hr-masters?tab=pt-slabs |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | created_by / updated_by | sys_users (id) | RESTRICT (implicit) |
> **Note:** `hrs_pt_slabs` has no FK consumers in the DDL. It is referenced logically by the payroll computation engine and compliance records but not via database FK constraints.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | PT Slabs page loads with all UI elements | Page loads with search, Add button, grid | — | — | ⬜ |
| TC-P02 | Search by state_code | Grid filtered to matching state_code | — | — | ⬜ |
| TC-P03 | Create PT slab with all required fields | Slab created with correct values | — | — | ⬜ |
| TC-P04 | Create PT slab with state_code auto-uppercased | "ka" → "KA" stored in DB | — | — | ⬜ |
| TC-P05 | Create PT slab with pt_amount=0 (nil slab) | pt_amount=0 saved | — | — | ⬜ |
| TC-P06 | Create PT slab with open-ended top range | max_salary=999999999.00 saved | — | — | ⬜ |
| TC-P07 | Create PT slab with is_active=0 | Created as inactive | — | — | ⬜ |
| TC-P08 | Create multiple slabs for same state (different min_salary) | Both slabs created with different ranges | — | — | ⬜ |
| TC-P09 | Edit PT slab loads pre-filled data | Edit form shows existing values | — | — | ⬜ |
| TC-P10 | Update PT amount | Amount updated successfully | — | — | ⬜ |
| TC-P11 | Update state_code | State code changed | — | — | ⬜ |
| TC-P12 | Update max_salary | Range expanded | — | — | ⬜ |
| TC-P13 | View PT slab details | Show page renders all fields | — | — | ⬜ |
| TC-P14 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P15 | Toggle status inactive to active | AJAX success, is_active flipped to 1 | — | — | ⬜ |
| TC-P16 | Soft delete PT slab | Slab moved to trash | — | — | ⬜ |
| TC-P17 | View trashed PT slabs ordered by state_code | Trash page lists soft-deleted | — | — | ⬜ |
| TC-P18 | Restore trashed PT slab | Restored with is_active=1 | — | — | ⬜ |
| TC-P19 | Force delete PT slab from trash | Permanently removed | — | — | ⬜ |
| TC-P20 | Full lifecycle: create→edit→toggle→delete→restore | All transitions succeed | — | — | ⬜ |
| TC-P21 | Empty state | Empty message shown | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `state_code` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `min_salary` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `max_salary` | Validation error | — | — | ⬜ |
| TC-N04 | Required — missing `pt_amount` | Validation error | — | — | ⬜ |
| TC-N05 | State code wrong length (not 2 chars) | "The state code must be 2 characters." | — | — | ⬜ |
| TC-N06 | State code not uppercase | prepareForValidation uppercases before validation passes | — | — | ⬜ |
| TC-N07 | Max salary not greater than min salary | "The max salary field must be greater than min salary." | — | — | ⬜ |
| TC-N08 | Duplicate (state_code + min_salary) | "The state code has already been taken." | — | — | ⬜ |
| TC-N09 | Negative min_salary | Validation error on min:0 | — | — | ⬜ |
| TC-N10 | Negative pt_amount | Validation error on min:0 | — | — | ⬜ |
| TC-N11 | View non-existent PT slab (404) | 404 Not Found | — | — | ⬜ |
| TC-N12 | Edit non-existent PT slab (404) | 404 Not Found | — | — | ⬜ |
| TC-N13 | Update non-existent PT slab (404) | 404 Not Found | — | — | ⬜ |
| TC-N14 | Delete non-existent PT slab (404) | 404 Not Found | — | — | ⬜ |
| TC-N15 | Permission denied — user without `hrs.compliance.manage` | 403 Forbidden | — | — | ⬜ |
| TC-N16 | Guest access | Redirect to /login | — | — | ⬜ |
| TC-N17 | Whitespace-only state_code | Required validation catches empty | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft delete sets is_active=false | is_active=0 before delete() | — | — | ⬜ |
| TC-D02 | A | Restore sets is_active=true | is_active=1 after restore() | — | — | ⬜ |
| TC-D03 | B | Activity logged on create | activityLog 'Created' with state_code | — | — | ⬜ |
| TC-D04 | B | Activity logged on update | activityLog 'Updated' with state_code | — | — | ⬜ |
| TC-D05 | B | Activity logged on soft delete | activityLog 'Trashed' | — | — | ⬜ |
| TC-D06 | C | Model $casts — min_salary, max_salary, pt_amount as decimal:2 | Stored as DECIMAL, accessed as float | — | — | ⬜ |
| TC-D07 | C | Model $casts — is_active as boolean | TINYINT accessed as bool | — | — | ⬜ |
| TC-D08 | D | Controller — findOrFail — 404 on invalid ID | All methods 404 | — | — | ⬜ |
| TC-D09 | E | Controller — Gate::authorize() on every method | All methods gate | — | — | ⬜ |
| TC-D10 | F | prepareForValidation uppercases state_code | strtoupper() applied before validation | — | — | ⬜ |
| TC-D11 | G | Unique composite (state_code, min_salary) at DB level | Direct INSERT with duplicate combo throws error | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — $fillable matches DDL columns | All non-PK, non-timestamp columns present | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts correct | decimal:2 for salary/pt, boolean for is_active | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait implemented | SoftDeletes imported; deleted_at column | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — Gate::authorize() on every method | All methods gate hrs.compliance.manage | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — activityLog on all state changes | All write methods log | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — is_active=false before soft delete | destroy() sets is_active=false | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — restore sets is_active=true | update is_active=1 | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — toggleStatus() flips is_active | Toggles via update() | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — trash/restore/forceDelete flow | onlyTrashed/findOrFail/withTrashed patterns | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — JSON/flash success response | Flash on CRUD, JSON on toggle | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — unique composite (state_code + min_salary) | Unique scoped to min_salary value | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — prepareForValidation() uppercases state_code | strtoupper() called | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — uppercase validation rule on state_code | Rule::uppercase() applied | — | — | ◌ |
| TC-CR14 | CR | P1 | Routes — resource + custom routes | All mapped correctly | — | — | ◌ |
| TC-CR15 | CR | P1 | Database — index on state_code | idx_hrs_pt_state on state_code | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-CR01 | Inspect PtSlab model $fillable | state_code, min_salary, max_salary, pt_amount, is_active, created_by, updated_by |
| TC-CR02 | Inspect $casts array | min_salary decimal:2, max_salary decimal:2, pt_amount decimal:2, is_active boolean |
| TC-CR03 | Check SoftDeletes | use SoftDeletes; present |
| TC-CR04 | Inspect all PtSlabController methods | All call Gate::authorize('hrs.compliance.manage') |
| TC-CR05 | Inspect store/update/destroy/restore/forceDelete | All call activityLog() |
| TC-CR06 | Inspect destroy() | Sets is_active=false before delete() |
| TC-CR07 | Inspect restore() | Calls update(['is_active' => true]) |
| TC-CR08 | Inspect toggleStatus() | Flips is_active via update() |
| TC-CR09 | Inspect trashed/restore/forceDelete | onlyTrashed/findOrFail/withTrashed patterns |
| TC-CR10 | Inspect flash/JSON responses | Flash on CRUD, JSON on toggle |
| TC-CR13 | Inspect web.php routes | resource('pt-slabs') + custom routes |
| TC-CR14 | Check DDL for state_code uppercase enforcement | Rule::uppercase() in request |
| TC-CR15 | Check DDL index | idx_hrs_pt_state on state_code |

#### TC-CR11: Request — Unique Composite (state_code + min_salary)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open StorePtSlabRequest.php | Request found |
| 2 | Inspect state_code rule | `Rule::unique('hrs_pt_slabs', 'state_code')->where('min_salary', $this->input('min_salary'))->ignore($id)->whereNull('deleted_at')` |

#### TC-CR12: prepareForValidation() Uppercases state_code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect prepareForValidation() | `$this->merge(['state_code' => strtoupper($this->input('state_code', ''))])` |

### 7.1 Positive TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-P02 | Create slabs "KA" and "MH", search "KA" | Only "KA" slabs shown |
| TC-P05 | Create slab with pt_amount=0 | DB has pt_amount=0.00 |
| TC-P06 | Create slab with max_salary=999999999.00 | DB stores large max_salary |
| TC-P07 | Create slab with is_active=0 | is_active=0 in DB |
| TC-P08 | Create 2 slabs for "KA" with min=0 and min=10001 | Both slabs exist under same state |
| TC-P09 | Click Edit on a PT slab | Edit form pre-filled with existing values |
| TC-P10 | Edit pt_amount from 200 to 250 | Updated, flash "PT slab updated successfully." |
| TC-P11 | Edit state_code from "KA" to "MH" | State code changed |
| TC-P12 | Edit max_salary from 15000 to 25000 | Range expanded |
| TC-P13 | Click View on PT slab | Show page renders all fields |
| TC-P15 | Toggle inactive to active | AJAX success, is_active=1 |
| TC-P17 | Navigate to trash view | Soft-deleted records ordered by state_code |
| TC-P18 | Restore trashed slab | Restored with is_active=1 |
| TC-P19 | Force delete from trash | Permanently removed |
| TC-P20 | Create→edit→toggle→delete→restore cycle | All transitions succeed |
| TC-P21 | No slabs exist | Empty state message |

#### TC-P01: PT Slabs Page Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to HrStaff → HR Masters → PT Slabs tab | Page loads with tab=pt-slabs |
| 3 | Verify search | Search field visible |
| 4 | Verify Add button | Add button visible |
| 5 | Verify grid columns | State Code, Min Salary, Max Salary, PT Amount, Status |

#### TC-P03: Create PT Slab With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button | Create form opens |
| 2 | Enter state_code: "KA" | State code filled |
| 3 | Enter min_salary: 0 | Min salary set |
| 4 | Enter max_salary: 15000 | Max salary set |
| 5 | Enter pt_amount: 0 | PT amount set |
| 6 | Click Save | POST to /pt-slabs |
| 7 | Verify flash | "PT slab created successfully." |
| 8 | DB check | Record with state_code=KA, min_salary=0 |

#### TC-P04: State Code Auto-Uppercased

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter state_code: "mh" (lowercase) | Lowercase entered |
| 3 | Fill remaining fields | All filled |
| 4 | Click Save | prepareForValidation uppercases to "MH" |
| 5 | DB check | state_code = "MH" |

#### TC-P08: Create Multiple Slabs for Same State

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create slab for KA: min=0, max=15000, pt=0 | Slab A created |
| 2 | Create slab for KA: min=15001, max=999999999, pt=200 | Slab B created (different min_salary) |
| 3 | Verify both exist | Two KA slabs with different ranges |

#### TC-P14: Toggle Status Active to Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active PT slab | is_active=1 |
| 2 | Click toggle button | AJAX POST to /pt-slabs/{id}/toggle-status |
| 3 | Verify JSON | success=true, is_active=false |

#### TC-P16: Soft Delete PT Slab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PT slab | Record exists |
| 2 | Click Delete | DELETE to /pt-slabs/{id} |
| 3 | Verify flash | "PT slab removed successfully." |
| 4 | DB check | deleted_at NOT NULL, is_active=0 |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-N01 | Submit without state_code | Validation error |
| TC-N02 | Submit without min_salary | Validation error |
| TC-N03 | Submit without max_salary | Validation error |
| TC-N04 | Submit without pt_amount | Validation error |
| TC-N06 | Enter state_code "ka" (lowercase) | prepareForValidation uppercases to "KA", validation passes |
| TC-N09 | Enter min_salary = -1 | Validation error on min:0 |
| TC-N10 | Enter pt_amount = -1 | Validation error on min:0 |
| TC-N11 | Access /pt-slabs/99999 | 404 Not Found |
| TC-N12 | Access /pt-slabs/99999/edit | 404 Not Found |
| TC-N13 | PUT /pt-slabs/99999 | 404 Not Found |
| TC-N14 | DELETE /pt-slabs/99999 | 404 Not Found |
| TC-N15 | Login as user without hrs.compliance.manage | 403 Forbidden |
| TC-N16 | Logout and access | Redirect to /login |
| TC-N17 | Submit whitespace-only state_code | Required validation catches empty |

#### TC-N05: State Code Wrong Length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter state_code: "KAR" (3 chars) | 3 chars entered |
| 3 | Fill remaining fields | All filled |
| 4 | Click Save | Validation error: "The state code must be 2 characters." |

#### TC-N07: Max Salary Not Greater Than Min Salary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter min_salary: 20000 | Min set |
| 3 | Enter max_salary: 15000 | Max lower than min |
| 4 | Click Save | Validation error: "The max salary field must be greater than min salary." |

#### TC-N08: Duplicate (state_code + min_salary)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create slab: state_code=MH, min_salary=0 | Slab exists |
| 2 | Try to create another slab: state_code=MH, min_salary=0 | Validation error: "The state code has already been taken." |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-D01 | Destroy slab (no guards) | is_active=0 before delete() |
| TC-D02 | Restore trashed slab | is_active=1 after restore() |
| TC-D03 | Create slab, check activity log | activityLog with 'Created' and state_code |
| TC-D04 | Update slab, check activity log | activityLog with 'Updated' and state_code |
| TC-D05 | Delete slab, check activity log | activityLog with 'Trashed' |
| TC-D06 | Access $slab->min_salary, max_salary, pt_amount | Returns float with 2 decimal places |
| TC-D07 | Access $slab->is_active | Returns boolean |
| TC-D08 | Access /pt-slabs/99999 | 404 on all methods |
| TC-D09 | Inspect PtSlabController methods | All call Gate::authorize('hrs.compliance.manage') |

#### TC-D10: prepareForValidation Uppercases state_code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with state_code="mh" | prepareForValidation converts to "MH" |
| 2 | Check DB | state_code stored as "MH" |

#### TC-D11: Unique Composite at DB Level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create slab: state_code=HP, min_salary=0, max_salary=999999999, pt_amount=100 | Record exists |
| 2 | Direct INSERT same (HP, 0) via DB query | Integrity constraint violation |
