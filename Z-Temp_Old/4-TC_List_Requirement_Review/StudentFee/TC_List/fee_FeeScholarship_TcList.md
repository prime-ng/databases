# fee_FeeScholarship_TcList

## Module: StudentFee → Scholarship → Fee Scholarship

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee |
| Tab Group | Scholarship |
| Feature | Fee Scholarship (Master) |
| URL(s) | `/student-fee/scholarship` (tab), `/student-fee/fee-scholarship` (index), `/student-fee/fee-scholarship/create` (create), `/student-fee/fee-scholarship` (store), `/student-fee/fee-scholarship/{id}` (show), `/student-fee/fee-scholarship/{id}/edit` (edit), `/student-fee/fee-scholarship/{id}` (update), `/student-fee/fee-scholarship/{id}` (destroy), `/student-fee/fee-scholarship/trash/view` (trashed), `/student-fee/fee-scholarship/{id}/restore` (restore), `/student-fee/fee-scholarship/{id}/force-delete` (forceDelete), `/student-fee/fee-scholarship/{fee_scholarship}/toggle-status` (toggleStatus) |
| Controller | `Modules\StudentFee\Http\Controllers\FeeScholarshipController` |
| Model(s) | `Modules\StudentFee\Models\FeeScholarship` (table: `fee_scholarships`) |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeScholarshipRequest` |
| Validation (Update) | `Modules\StudentFee\Http\Requests\UpdateFeeScholarshipRequest` |
| Permissions | `tenant.fee-scholarship.view`, `tenant.fee-scholarship.create`, `tenant.fee-scholarship.update`, `tenant.fee-scholarship.delete`, `tenant.fee-scholarship.restore`, `tenant.fee-scholarship.forceDelete`, `tenant.fee-scholarship.status` |
| Soft Deletes | Yes (`SoftDeletes` trait; `destroy()` sets `is_active=false` before soft-delete) |
| Activity Log | Events: `Created`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Toggled` |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-scholarship.{view,create,update,delete,restore,forceDelete,status}`
- For delete-blocked test: At least one scholarship with existing applications
- Tenant context must be initialized

---

## 3. Default Data Load

When the page loads via `StudentFeeManagementController@scholarship()` (GET `/student-fee/scholarship`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Scholarships | `FeeScholarship::withCount('applications')->latest()` | Latest first | search(code,name,sponsor_name), fund_source, is_active | 15/page |
| Applications | `FeeScholarshipApplication::with(['scholarship','student.user','academicSession'])->latest()` | Latest first | search(student/scholarship name), app_status | 15/page (app_page) |
| Approval History | `FeeScholarshipApprovalHistory::with(['application.scholarship','actionBy'])->latest('action_date')` | Latest by date | None | 15/page (hist_page) |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Code uniqueness**: Unique constraint on `code` — use suffixed codes
- **Pre-test cleanup**: Delete created scholarships by ID
- **Eligibility criteria**: Stored as textarea lines → parsed to array; use multi-line input for testing
- **Fund sources**: ['Government', 'Private', 'NGO', 'School Fund', 'Donor', 'Other']

---

## 5. Business Conditions

### 5.1 Database Schema — `fee_scholarships`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | fund_source | VARCHAR(100) | NOT NULL |
| BC-DB-05 | sponsor_name | VARCHAR(100) | NULLABLE |
| BC-DB-06 | total_fund_amount | DECIMAL(15,2) | NULLABLE |
| BC-DB-07 | available_fund | DECIMAL(15,2) | NULLABLE, defaults to total_fund_amount |
| BC-DB-08 | eligibility_criteria | JSON | NOT NULL |
| BC-DB-09 | application_start_date | DATE | NULLABLE |
| BC-DB-10 | application_end_date | DATE | NULLABLE |
| BC-DB-11 | max_amount_per_student | DECIMAL(10,2) | NULLABLE |
| BC-DB-12 | requires_renewal | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-13 | renewal_criteria | JSON | NULLABLE |
| BC-DB-14 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-15 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-16 | updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-17 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `StoreFeeScholarshipRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:50, unique:fee_scholarships,code | — |
| BC-VAL-02 | name | required, string, max:150 | — |
| BC-VAL-03 | fund_source | required, string, max:100 | — |
| BC-VAL-04 | sponsor_name | nullable, string, max:150 | — |
| BC-VAL-05 | total_fund_amount | nullable, numeric, min:0 | — |
| BC-VAL-06 | available_fund | nullable, numeric, min:0 | — |
| BC-VAL-07 | application_start_date | nullable, date | — |
| BC-VAL-08 | application_end_date | nullable, date, after_or_equal:application_start_date | — |
| BC-VAL-09 | max_amount_per_student | nullable, numeric, min:0 | — |
| BC-VAL-10 | requires_renewal | nullable, boolean | — |
| BC-VAL-11 | eligibility_criteria | nullable, string | — |
| BC-VAL-12 | renewal_criteria | nullable, string | — |
| BC-VAL-13 | is_active | nullable, boolean | — |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.fee-scholarship.view | index(), show() | Without → 403 |
| BC-AUTH-02 | tenant.fee-scholarship.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.fee-scholarship.update | edit(), update() | Without → 403 |
| BC-AUTH-04 | tenant.fee-scholarship.delete | destroy() | Without → 403 |
| BC-AUTH-05 | tenant.fee-scholarship.restore | trashedScholarships(), restore() | Without → 403 |
| BC-AUTH-06 | tenant.fee-scholarship.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-07 | tenant.fee-scholarship.status | toggleStatus() | Without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create scholarship | Code uppercased; eligibility_criteria parsed from newlines to array; available_fund defaults to total_fund_amount |
| BC-BIZ-02 | No total_fund_amount | available_fund set to null |
| BC-BIZ-03 | Update with eligibility_criteria | Re-parsed from textarea lines |
| BC-BIZ-04 | Delete with existing applications | Blocked: "Cannot delete scholarship with existing applications." |
| BC-BIZ-05 | Delete without applications | is_active=false then soft-delete |
| BC-BIZ-06 | Restore scholarship | deleted_at nullified |
| BC-BIZ-07 | Force delete | Permanently removed |
| BC-BIZ-08 | Toggle status | is_active flipped; JSON response |
| BC-BIZ-09 | scopeOpenForApplication | Returns scholarships where dates include today (or dates null) and is_active=true |
| BC-BIZ-10 | hasSufficientFund | Returns true if available_fund >= amount (or available_fund null) |
| BC-BIZ-11 | deductFund | Decrements available_fund by amount (null-safe) |
| BC-BIZ-12 | Show with applications count | `withCount('applications')` loaded |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | (no FK constraints on fee_scholarships) | Independent table | N/A |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Scholarship Page Loads With All Panels | Page loads with scholarships grid (15/page), applications grid (15/page), approval history | — | — | ⬜ |
| TC-P02 | Create Scholarship With All Fields | Scholarship created with code uppercased, eligibility_criteria as array, available_fund = total_fund_amount | — | — | ⬜ |
| TC-P03 | Create Scholarship With Minimum Fields | Only code, name, fund_source required; all others nullable | — | — | ⬜ |
| TC-P04 | Create Scholarship With Renewal Enabled | Scholarship created with requires_renewal=true, renewal_criteria parsed | — | — | ⬜ |
| TC-P05 | Create Scholarship With Fund Source "NGO" | Scholarship with fund_source="NGO", sponsor_name set | — | — | ⬜ |
| TC-P06 | Edit Scholarship Name and Fund Amount | Scholarship name and total_fund_amount updated | — | — | ⬜ |
| TC-P07 | Show Scholarship With Application Count | Details page shows application count | — | — | ⬜ |
| TC-P08 | Filter Scholarships By Fund Source | Grid filters to matching fund_source only | — | — | ⬜ |
| TC-P09 | Filter Scholarships By Status | Grid filters active/inactive scholarships | — | — | ⬜ |
| TC-P10 | Search Scholarships By Keyword | Grid filters by code, name, or sponsor_name | — | — | ⬜ |
| TC-P11 | Toggle Scholarship Status | is_active flips; JSON response `{success: true, is_active: false}` | — | — | ⬜ |
| TC-P12 | Soft Delete Scholarship Without Applications | is_active=false, soft-deleted, moved to trash | — | — | ⬜ |
| TC-P13 | View Trashed Scholarships | Trash page lists only soft-deleted scholarships | — | — | ⬜ |
| TC-P14 | Restore Scholarship From Trash | deleted_at nullified | — | — | ⬜ |
| TC-P15 | Force Delete Scholarship | Permanently removed from DB | — | — | ⬜ |
| TC-P16 | scopeOpenForApplication Returns Active Within Dates | Scholarship with dates covering today returns true | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `code` | Validation error | — | — | ⬜ |
| TC-N02 | Required — Missing `name` | Validation error | — | — | ⬜ |
| TC-N03 | Required — Missing `fund_source` | Validation error | — | — | ⬜ |
| TC-N04 | Invalid — Duplicate `code` | Validation error: unique constraint | — | — | ⬜ |
| TC-N05 | Invalid — `code` > 50 characters | Validation fails on max:50 | — | — | ⬜ |
| TC-N06 | Invalid — `application_end_date` before start_date | Validation error: "The application end date must be a date after or equal to application start date." | — | — | ⬜ |
| TC-N07 | Invalid — `total_fund_amount` negative | Validation fails on min:0 | — | — | ⬜ |
| TC-N08 | Business — Delete scholarship with applications | Error: "Cannot delete scholarship with existing applications." | — | — | ⬜ |
| TC-N09 | Business — scopeOpenForApplication returns false outside dates | Scholarship outside application window returns false | — | — | ⬜ |
| TC-N10 | Permission 403 | 403 Forbidden without permissions | — | — | ⬜ |
| TC-N11 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |
| TC-N12 | XSS in name field | Stored as literal; Blade escapes | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create → Code uppercased via strtoupper | code stored in uppercase | — | — | ⬜ |
| TC-D02 | B | Create → Eligibility criteria parsed to array | Textarea lines stored as JSON array | — | — | ⬜ |
| TC-D03 | C | Create → available_fund defaults to total_fund_amount | available_fund = total_fund_amount | — | — | ⬜ |
| TC-D04 | D | Destroy with applications → blocked | `$feeScholarship->applications()->exists()` check | — | — | ⬜ |
| TC-D05 | E | Soft delete → is_active=false | is_active set to 0 before delete | — | — | ⬜ |
| TC-D06 | F | hasSufficientFund → sufficient | Returns true when available_fund >= amount | — | — | ⬜ |
| TC-D07 | G | hasSufficientFund → null available_fund | Returns true (unlimited fund) | — | — | ⬜ |
| TC-D08 | H | deductFund → decrements | available_fund reduced by approved amount | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — DB Transaction in store/update | Both use DB::beginTransaction/commit/rollback with try-catch | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Gate::authorize() before all actions | All methods call authorize | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — activityLog after all CRUD events | All state-changing methods log activity | — | — | ◌ |
| TC-CR04 | CR | P1 | StoreFeeScholarshipRequest — authorize uses AuthorizesTenantFeature trait | Custom authorize method used | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P02: Create Scholarship With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Scholarship tab | Page loads |
| 2 | Click "Add Scholarship" | Create form opens with fund_source dropdown |
| 3 | Enter code: "test-merit-2025" | Field filled |
| 4 | Enter name: "Test Merit Scholarship 2025" | Field filled |
| 5 | Select fund_source: "Government" | Dropdown selected |
| 6 | Enter sponsor_name: "Ministry of Education" | Field filled |
| 7 | Enter total_fund_amount: 500000 | Field filled |
| 8 | Enter application_start_date: 2025-04-01, end_date: 2025-06-30 | Both filled |
| 9 | Enter max_amount_per_student: 25000 | Field filled |
| 10 | Enter eligibility_criteria (textarea): "Min 85% marks\nFamily income < 3L" | Multi-line input |
| 11 | Set requires_renewal = true | Toggle ON |
| 12 | Enter renewal_criteria: "Must maintain 80%" | Field filled |
| 13 | Click "Save" | POST to store() |
| 14 | Check flash message | "Scholarship created successfully." |
| 15 | DB check: `SELECT * FROM fee_scholarships WHERE code='TEST-MERIT-2025'` | Code uppercased; eligibility_criteria JSON array with 2 items; available_fund = 500000 |

### TC-N08: Delete Scholarship With Applications

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scholarship with at least one application | Scholarship ID=X has applications |
| 2 | Navigate to scholarship list | Grid shows scholarship |
| 3 | Click "Delete" on that scholarship | DELETE to destroy() |
| 4 | Check response | Error: "Cannot delete scholarship with existing applications." |

---

## 8. Known Issues

- `eligibility_criteria` column is `JSON NOT NULL` in DDL but stored as nullable in controller (null when empty)
- `trashedScholarships()` paginates at 15, while other module trash views paginate at 10
- `restore()` does NOT auto-set `is_active=true` (unlike FeeFineRule restore)

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/student-fee/scholarship` | `student-fee.scholarship` | `StudentFeeManagementController@scholarship` |
| GET | `/student-fee/fee-scholarship` | `student-fee.fee-scholarship.index` | `index` |
| GET | `/student-fee/fee-scholarship/create` | `student-fee.fee-scholarship.create` | `create` |
| POST | `/student-fee/fee-scholarship` | `student-fee.fee-scholarship.store` | `store` |
| GET | `/student-fee/fee-scholarship/{id}` | `student-fee.fee-scholarship.show` | `show` |
| GET | `/student-fee/fee-scholarship/{id}/edit` | `student-fee.fee-scholarship.edit` | `edit` |
| PUT/PATCH | `/student-fee/fee-scholarship/{id}` | `student-fee.fee-scholarship.update` | `update` |
| DELETE | `/student-fee/fee-scholarship/{id}` | `student-fee.fee-scholarship.destroy` | `destroy` |
| GET | `/student-fee/fee-scholarship/trash/view` | `student-fee.fee-scholarship.trashed` | `trashedScholarships` |
| GET | `/student-fee/fee-scholarship/{id}/restore` | `student-fee.fee-scholarship.restore` | `restore` |
| DELETE | `/student-fee/fee-scholarship/{id}/force-delete` | `student-fee.fee-scholarship.forceDelete` | `forceDelete` |
| POST | `/student-fee/fee-scholarship/{fee_scholarship}/toggle-status` | `student-fee.fee-scholarship.toggleStatus` | `toggleStatus` |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Skipped | Execution Date |
|----------|--------|--------|---------|---------|----------------|
| 0 | 0 | 0 | 0 | 0 | — |
