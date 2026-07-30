# hrs_PayGrades_TcList

## Module: HrStaff → HR Masters → Pay Grades

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | HR Masters |
| Feature | Pay Grades |
| URL(s) | `GET /hr-masters?tab=pay-grades` (tab view), `GET /pay-grades` (index), `POST /pay-grades` (store), `GET /pay-grades/{payGrade}` (show), `GET /pay-grades/{payGrade}/edit` (edit), `PUT /pay-grades/{payGrade}` (update), `DELETE /pay-grades/{payGrade}` (destroy), `POST /pay-grades/{payGrade}/toggle-status` (toggleStatus), `GET /pay-grades/trash/view` (trashed), `GET /pay-grades/{id}/restore` (restore), `DELETE /pay-grades/{id}/force-delete` (forceDelete) |
| Controller | `Modules\HrStaff\Http\Controllers\PayGradeController` |
| Model(s) | `Modules\HrStaff\Models\PayGrade` (table: `hrs_pay_grades`) |
| Validation (Create/Update) | `Modules\HrStaff\Http\Requests\StorePayGradeRequest` |
| Policy | `Modules\HrStaff\Policies\PayGradePolicy` |
| Permissions | `hrs.salary.manage` (controller); `hrs.pay_grade.manage` (policy) |
| Pagination | 20 records per page using default `page` parameter |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` sets `is_active=false` before `delete()`; restore sets `is_active=true` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Deleted (force delete) |
| Data Source | Designations from `Modules\SchoolSetup\Models\Designation` for applicable_designation_ids |

---

## 2. Pre-conditions

- Required permissions: `hrs.salary.manage` (or `hrs.pay_grade.manage`)
- Required seed data: At least one active `Designation` in `sch_designation` for designation-mapping tests
- Test user must have required permissions (default admin user)
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For delete-guard tests: At least one salary assignment referencing the pay grade
- For pagination tests: Create 25 pay grades

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Pay Grades Grid (tab) | `HrMenuController@hrMasters()` | `PayGrade::orderBy('grade_name')` | search (grade_name) | None (full collection) |
| Pay Grades Grid (standalone) | `PayGradeController@index()` | `PayGrade::orderBy('grade_name')->withQueryString()` | search (grade_name) | 20/page |
| Designations (edit/show) | `PayGradeController@edit()` / `show()` | `Designation::where('is_active', true)->orderBy('name')` | is_active=1 | None |

> **Data Source:** `applicable_designation_ids` is a JSON column storing designation IDs from `sch_designation` (SchoolSetup module). Designation names are resolved at display time via `Designation::pluck()`.

---

## 4. Test Data Strategy

- **Grade name**: Unique name suffixed with timestamp for each test
- **CTC values**: Use realistic values (e.g., min=120000, max=240000)
- **Designation mapping**: Create designations in SchoolSetup module for mapping tests
- **Pre-test cleanup**: Delete created pay grades by name before/after tests
- **Pagination**: Create 25 pay grades to test 20-record boundary
- **JSON field**: `applicable_designation_ids` stored as JSON array

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_pay_grades`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | grade_name | VARCHAR(100) | NOT NULL |
| BC-DB-03 | min_ctc | DECIMAL(12,2) | NOT NULL |
| BC-DB-04 | max_ctc | DECIMAL(12,2) | NOT NULL |
| BC-DB-05 | applicable_designation_ids | JSON | NULL DEFAULT NULL |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-07 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-08 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-09 | created_at | TIMESTAMP | NULL |
| BC-DB-10 | updated_at | TIMESTAMP | NULL |
| BC-DB-11 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Validation Rules — `StorePayGradeRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | grade_name | required, string, max:100 | — |
| BC-VAL-02 | min_ctc | required, numeric, min:0 | — |
| BC-VAL-03 | max_ctc | required, numeric, gt:min_ctc | "The max ctc field must be greater than min ctc." |
| BC-VAL-04 | applicable_designation_ids | nullable, array | — |
| BC-VAL-05 | applicable_designation_ids.* | integer, exists:sch_designation,id | — |
| BC-VAL-06 | is_active | required, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.salary.manage` / `hrs.pay_grade.manage` | All controller methods gate; without → 403 |
| BC-AUTH-02 | Guest access | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with `tab=pay-grades` | Pay grades list displayed in tab |
| BC-BIZ-02 | Standalone index | Paginated grid 20/page, ordered by grade_name |
| BC-BIZ-03 | Search by grade_name | Grid filtered to matching name |
| BC-BIZ-04 | Create with no designations | applicable_designation_ids = null (all designations) |
| BC-BIZ-05 | Create with specific designations | applicable_designation_ids stores JSON array |
| BC-BIZ-06 | Show resolves designation names | Designation IDs resolved to human-readable names |
| BC-BIZ-07 | Delete blocked by salary assignments | "Cannot delete pay grade with existing salary assignments." |
| BC-BIZ-08 | is_active default true | New pay grade created with is_active=1 |
| BC-BIZ-09 | Empty grid | Empty state message shown |
| BC-BIZ-10 | Screen loads via PayGradeController@index() at GET /pay-grades | Standalone paginated; tab via GET /hr-masters?tab=pay-grades |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | id (self) | hrs_salary_assignments.pay_grade_id | Child FK — blocks delete if exists (controller guard) |
| BC-REF-02 | applicable_designation_ids.* | sch_designation (id) | Soft reference (JSON, no DB FK) |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Pay Grades page loads with all UI elements | Page loads with search, Add button, grid | — | — | ⬜ |
| TC-P02 | Search pay grades by name | Grid filtered to matching grade_name | — | — | ⬜ |
| TC-P03 | Create pay grade with all required fields | Pay grade created with correct values | — | — | ⬜ |
| TC-P04 | Create pay grade with no designation restriction | applicable_designation_ids = null | — | — | ⬜ |
| TC-P05 | Create pay grade with specific designations | JSON array of designation IDs stored | — | — | ⬜ |
| TC-P06 | Create pay grade with is_active=0 | Pay grade created as inactive | — | — | ⬜ |
| TC-P07 | Edit pay grade loads pre-filled data | Edit form shows existing values | — | — | ⬜ |
| TC-P08 | Update grade_name | Name updated successfully | — | — | ⬜ |
| TC-P09 | Update min_ctc and max_ctc | CTC range updated | — | — | ⬜ |
| TC-P10 | Update applicable designations | Designation list replaced | — | — | ⬜ |
| TC-P11 | View pay grade details with designation names | Designation IDs shown as human-readable names | — | — | ⬜ |
| TC-P12 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P13 | Soft delete pay grade (no assignments) | Pay grade moved to trash | — | — | ⬜ |
| TC-P14 | View trashed pay grades | Trash page lists soft-deleted | — | — | ⬜ |
| TC-P15 | Restore trashed pay grade | Restored with is_active=1 | — | — | ⬜ |
| TC-P16 | Force delete from trash | Permanently removed | — | — | ⬜ |
| TC-P17 | Full lifecycle: create→edit→toggle→delete→restore | All transitions succeed | — | — | ⬜ |
| TC-P18 | Pagination — first page 20 records | Page 1 shows 20 records | — | — | ⬜ |
| TC-P19 | Pagination — second page | Page 2 shows records 21+ | — | — | ⬜ |
| TC-P20 | Empty state | Empty message shown | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `grade_name` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `min_ctc` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `max_ctc` | Validation error | — | — | ⬜ |
| TC-N04 | Max length — name > 100 chars | Validation error on grade_name.max | — | — | ⬜ |
| TC-N05 | Max CTC not greater than min CTC | "The max ctc field must be greater than min ctc." | — | — | ⬜ |
| TC-N06 | Min CTC negative | Validation error on min_ctc.min | — | — | ⬜ |
| TC-N07 | Invalid designation ID in array | "The selected applicable designation ids.* is invalid." | — | — | ⬜ |
| TC-N08 | Delete pay grade with existing salary assignments | "Cannot delete pay grade with existing salary assignments." | — | — | ⬜ |
| TC-N09 | View non-existent pay grade (404) | 404 Not Found | — | — | ⬜ |
| TC-N10 | Edit non-existent pay grade (404) | 404 Not Found | — | — | ⬜ |
| TC-N11 | Delete non-existent pay grade (404) | 404 Not Found | — | — | ⬜ |
| TC-N12 | Permission denied — user without gate | 403 Forbidden | — | — | ⬜ |
| TC-N13 | Guest access | Redirected to /login | — | — | ⬜ |
| TC-N14 | Whitespace-only grade_name | Required validation catches empty | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft delete sets is_active=false | is_active=0 before delete() | — | — | ⬜ |
| TC-D02 | A | Restore sets is_active=true | is_active=1 after restore() | — | — | ⬜ |
| TC-D03 | B | Activity logged on create | activityLog called with 'Created' | — | — | ⬜ |
| TC-D04 | B | Activity logged on update | activityLog called with 'Updated' | — | — | ⬜ |
| TC-D05 | B | Activity logged on soft delete | activityLog called with 'Trashed' | — | — | ⬜ |
| TC-D06 | C | Model $casts — min_ctc/max_ctc as decimal:2 | Stored as DECIMAL, accessed as float | — | — | ⬜ |
| TC-D07 | C | Model $casts — applicable_designation_ids as array | JSON decoded to PHP array | — | — | ⬜ |
| TC-D08 | C | Model $casts — is_active as boolean | TINYINT accessed as bool | — | — | ⬜ |
| TC-D09 | D | Model relationship — salaryAssignments() HasMany | `$payGrade->salaryAssignments` returns related assignments | — | — | ⬜ |
| TC-D10 | E | Controller — findOrFail — 404 | Invalid ID returns 404 | — | — | ⬜ |
| TC-D11 | F | Controller — Gate::authorize() on every method | All 10 methods gate before execution | — | — | ⬜ |
| TC-D12 | G | Salary assignment blocks delete | salaryAssignments()->exists() guard | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — $fillable matches DDL | All non-PK, non-timestamp columns present | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — $casts correct | decimal:2, array, boolean casts defined | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait | SoftDeletes imported; deleted_at present | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — salaryAssignments relationship | HasMany defined | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Gate::authorize() on every method | All 10 methods gate | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — activityLog on all state changes | All write methods log | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — is_active=false before soft delete | destroy() sets is_active=false | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — restore sets is_active=true | restore() update is_active=1 | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — toggleStatus() flips | Toggles via update() | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — trash/restore/forceDelete flow | onlyTrashed/findOrFail/withTrashed patterns | — | — | ◌ |
| TC-CR11 | CR | P1 | Controller — JSON/flash success response | Flash messages and JSON toggle response | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — rules cover all fillable fields | All columns validated | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — prepareForValidation() | is_active boolean cast | — | — | ◌ |
| TC-CR14 | CR | P1 | Policy — all methods defined | viewAny, view, create, update, delete, restore, forceDelete | — | — | ◌ |
| TC-CR15 | CR | P1 | Routes — resource + custom routes | All route entries registered | — | — | ◌ |
| TC-CR16 | CR | P1 | View — $payGrade->applicable_designation_ids null-safe access | Blade uses isset/optional for JSON field | — | — | ◌ |

---

## 7. Detailed Test Steps

### Code Review TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-CR03 | Check SoftDeletes import | use SoftDeletes; present in model |
| TC-CR05 | Inspect all PayGradeController methods | All call Gate::authorize('hrs.salary.manage') |
| TC-CR06 | Inspect store/update/destroy/restore/forceDelete | All call activityLog() |
| TC-CR07 | Inspect destroy() | Sets is_active=false before delete() |
| TC-CR08 | Inspect restore() | Calls update(['is_active' => true]) |
| TC-CR09 | Inspect toggleStatus() | Flips is_active via update() |
| TC-CR10 | Inspect trashed/restore/forceDelete | onlyTrashed/findOrFail/withTrashed patterns |
| TC-CR11 | Inspect JSON/flash responses | Flash on CRUD, JSON on toggleStatus |
| TC-CR12 | Inspect StorePayGradeRequest rules | All fillable columns have rules |
| TC-CR13 | Inspect prepareForValidation() | is_active cast via $this->boolean() |
| TC-CR14 | Inspect PayGradePolicy | 7 gates all use 'hrs.pay_grade.manage' |
| TC-CR15 | Check web.php routes | resource('pay-grades') + custom routes |
| TC-CR16 | Check view nullable access for applicable_designation_ids | Blade uses isset/optional for JSON field |

#### TC-CR01: Model — $fillable Matches DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PayGrade.php | Model found |
| 2 | Inspect $fillable | grade_name, min_ctc, max_ctc, applicable_designation_ids, is_active, created_by, updated_by |
| 3 | Cross-check with DDL | All non-PK, non-timestamp columns present |

#### TC-CR02: Model — $casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect $casts | min_ctc => decimal:2, max_ctc => decimal:2, applicable_designation_ids => array, is_active => boolean |

#### TC-CR04: Model — salaryAssignments Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect salaryAssignments() | HasMany to SalaryAssignment::class, foreign key pay_grade_id |

### 7.1 Positive TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-P02 | Create "Grade A" and "Grade B", search "Grade A" | Only "Grade A" shown |
| TC-P04 | Create pay grade without selecting designations | applicable_designation_ids = null |
| TC-P06 | Create pay grade with is_active=0 | Record created with is_active=0 |
| TC-P07 | Click Edit on a pay grade | Edit form pre-filled with all existing values |
| TC-P08 | Edit grade_name from "Old" to "New" | Updated, flash "Pay grade updated successfully." |
| TC-P09 | Edit min_ctc from 100000 to 200000 and max_ctc from 500000 to 600000 | Both updated in DB |
| TC-P10 | Edit applicable designations to a new set | JSON array replaced with new IDs |
| TC-P12 | Toggle active pay grade to inactive | AJAX success, is_active=0 |
| TC-P13 | Delete pay grade with no salary assignments | Soft-deleted, flash "Pay grade removed successfully." |
| TC-P14 | Navigate to trash view | Soft-deleted records shown |
| TC-P15 | Restore trashed pay grade | Restored with is_active=1, flash success |
| TC-P16 | Force delete from trash | Permanently removed |
| TC-P17 | Create→edit→toggle→delete→restore cycle | All transitions succeed |
| TC-P18 | Create 25 pay grades, go to page 1 | 20 records shown |
| TC-P19 | Go to page 2 | 5 remaining records shown |
| TC-P20 | No pay grades exist | Empty state message shown |

#### TC-P01: Pay Grades Page Loads With All UI Elements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to HrStaff → HR Masters → Pay Grades tab | Page loads with tab=pay-grades |
| 3 | Verify search input | Search text field visible |
| 4 | Verify Add button | Add/New button visible |
| 5 | Verify grid columns | Grade Name, Min CTC, Max CTC, Designations, Status columns |

#### TC-P03: Create Pay Grade With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click "Add" button | Create form opens |
| 2 | Enter grade_name: "Senior Teacher" | Name filled |
| 3 | Enter min_ctc: 300000 | Min CTC set |
| 4 | Enter max_ctc: 600000 | Max CTC set |
| 5 | Click Save | POST to /pay-grades |
| 6 | Verify flash | "Pay grade created successfully." |
| 7 | DB check | Record exists with grade_name=Senior Teacher |

#### TC-P05: Create With Specific Designations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure designation "Teacher" exists with ID=X | Designation exists |
| 2 | Open create form | Form visible |
| 3 | Fill required fields | Name and CTC range set |
| 4 | Select designation "Teacher" from multi-select | Designation selected |
| 5 | Click Save | Record created |
| 6 | DB check applicable_designation_ids | JSON array containing ID X |

#### TC-P11: View Pay Grade With Designation Names

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create pay grade with designation_ids=[1,2] | Record exists |
| 2 | Click "View" on that record | Show page loads |
| 3 | Verify designation names displayed | Human-readable names shown (not IDs) |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-N01 | Submit create form without grade_name | Validation error on grade_name |
| TC-N02 | Submit create form without min_ctc | Validation error on min_ctc |
| TC-N03 | Submit create form without max_ctc | Validation error on max_ctc |
| TC-N04 | Enter grade_name > 100 characters | Validation error on grade_name.max |
| TC-N06 | Enter min_ctc = -1 | Validation error on min_ctc.min:0 |
| TC-N07 | Enter non-existent designation ID | Validation error on exists |
| TC-N09 | Access /pay-grades/99999 | 404 Not Found |
| TC-N10 | Access /pay-grades/99999/edit | 404 Not Found |
| TC-N11 | DELETE /pay-grades/99999 | 404 Not Found |
| TC-N12 | Login as user without hrs.salary.manage | 403 Forbidden on all endpoints |
| TC-N13 | Logout and access /pay-grades | Redirect to /login |
| TC-N14 | Submit with whitespace-only grade_name | Required validation catches empty |

#### TC-N05: Max CTC Not Greater Than Min CTC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form visible |
| 2 | Enter min_ctc: 500000 | Min set |
| 3 | Enter max_ctc: 300000 | Max lower than min |
| 4 | Click Save | Validation error: "The max ctc field must be greater than min ctc." |

#### TC-N08: Delete Blocked by Salary Assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create pay grade with ID=1 | Grade exists |
| 2 | Create salary assignment with pay_grade_id=1 | Assignment exists |
| 3 | Try to delete pay grade | Controller checks salaryAssignments()->exists() = true |
| 4 | Verify error | "Cannot delete pay grade with existing salary assignments." |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Expected |
|-------|--------|----------|
| TC-D01 | Create pay grade, call destroy() | is_active set to 0 before delete() |
| TC-D02 | Restore trashed pay grade | is_active set to 1 |
| TC-D03 | Create pay grade, check activity log | activityLog called with 'Created' |
| TC-D04 | Update pay grade, check activity log | activityLog called with 'Updated' |
| TC-D05 | Delete pay grade, check activity log | activityLog called with 'Trashed' |
| TC-D07 | Access $payGrade->applicable_designation_ids when null | Returns null |
| TC-D08 | Access $payGrade->is_active | Returns boolean |
| TC-D10 | Access /pay-grades/99999/show | 404 ModelNotFoundException |
| TC-D11 | Inspect PayGradeController methods | All call Gate::authorize() |
| TC-D12 | Create salary assignment referencing pay grade, try delete | Controller returns error (salaryAssignments()->exists() guard) |

#### TC-D06: Model $casts — min_ctc/max_ctc as decimal:2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create pay grade with min_ctc=300000.50 | Record created |
| 2 | Read from DB | Value stored as 300000.50 |
| 3 | Access via model | Cast to float with 2 decimal places |

#### TC-D09: Model $casts — applicable_designation_ids as array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create pay grade with applicable_designation_ids=["1","2","3"] | JSON stored in DB |
| 2 | Access via model | Returns PHP array [1, 2, 3] |
| 3 | Check empty (null) | Returns null when no designations set |
