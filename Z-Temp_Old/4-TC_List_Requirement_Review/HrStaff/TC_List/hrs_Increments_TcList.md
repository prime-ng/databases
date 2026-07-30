# hrs_increments_TcList

## Module: HrStaff → Appraisals → Increments

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Appraisals |
| Feature | Increments (Increment Policies + Process Increments) |
| URL(s) | Policies: `GET /appraisals-overview?tab=increment-policies` (combined), `GET /increment-policies` (index), `POST /increment-policies` (store), `GET /increment-policies/{incrementPolicy}` (show), `GET /increment-policies/{incrementPolicy}/edit` (edit), `PUT /increment-policies/{incrementPolicy}` (update), `DELETE /increment-policies/{incrementPolicy}` (destroy), `GET /increment-policies/trash/view` (trashed), `GET /increment-policies/{id}/restore` (restore), `DELETE /increment-policies/{id}/force-delete` (forceDelete). Processing: `GET /appraisals-overview?tab=process-increments` (combined), `GET /increments` (index), `POST /increments/process` (process) |
| Controller | `Modules\HrStaff\Http\Controllers\IncrementController` — `policyIndex()` lines 43-53, `policyStore()` lines 58-72, `policyShow()` lines 77-84, `policyEdit()` lines 132-140, `policyUpdate()` lines 161-171, `policyDestroy()` lines 145-155, `policyTrashed()` lines 89-96, `policyRestore()` lines 101-112, `policyForceDelete()` lines 117-127, `index()` lines 25-38, `process()` lines 176-188 |
| Model(s) | `Modules\HrStaff\Models\IncrementPolicy` (table: `pay_increment_policies`), `Modules\HrStaff\Models\AppraisalIncrementFlag` (table: `hrs_appraisal_increment_flags`) |
| Validation (Create) | `Modules\HrStaff\Http\Requests\StoreIncrementPolicyRequest` |
| Validation (Update) | `Modules\HrStaff\Http\Requests\StoreIncrementPolicyRequest` |
| Permissions | `pay.increment.process` (all operations) |
| Pagination | `policyIndex()` — no pagination; `policyTrashed()` — 15/page; `index()` (pending flags) — 25/page |
| Soft Deletes | Yes — `IncrementPolicy` and `AppraisalIncrementFlag` use `SoftDeletes` trait |
| Data Source | Policies: direct CRUD. Processing: reads from `AppraisalIncrementFlag` created by appraisal finalization |
| Activity Log | Events: `Created`, `Updated`, `Trashed`, `Restored`, `Deleted` (policies); `IncrementsProcessed` (processing) |

---

## 2. Pre-conditions

- Required permissions: `pay.increment.process`
- Required seed data: At least one active `AppraisalCycle`, finalized `Appraisal` records with `overall_rating` set
- Required dependent data: Active `Employee` with an active `SalaryAssignment` (via `hrs_salary_assignments`)
- For processing tests: Create finalized appraisals + pending `AppraisalIncrementFlag` records
- For policy matching tests: Define policies with varying rating ranges
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `HrMenuController@appraisalsIncrements()`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Increment Policies Grid | `HrMenuController@appraisalsIncrements()` | `IncrementPolicy::with('appraisalCycle')->orderBy('name')->get()` | None (loads all) | None |
| Pending Flags Grid | `HrMenuController@appraisalsIncrements()` | `AppraisalIncrementFlag::with(['appraisal.employee','appraisal.cycle'])->pending()->active()->orderByDesc('created_at')` | flag_status=pending, is_active=1 | 20/page (`flags_page`) |
| Processed Count | `HrMenuController@appraisalsIncrements()` | `AppraisalIncrementFlag::where('flag_status', 'processed')->count()` | flag_status=processed | None |

---

## 4. Test Data Strategy

- Create increment policies with non-overlapping rating ranges covering low, medium, and high performance
- For processing test: Create finalized appraisals with known overall_rating values (e.g., 3.5, 5.0, 7.5, 9.0) and their corresponding flags
- For PF/ESI computation test: Create compliance records for employees with applicable_flag=true
- For salary revision test: Ensure employees have an active salary assignment before processing
- Pre-test cleanup: Remove created policies and flags after tests

---

## 5. Business Conditions

### 5.1 Database Schema — `pay_increment_policies`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | name | VARCHAR(200) | NOT NULL |
| BC-DB-03 | appraisal_cycle_id | BIGINT UNSIGNED | NULL, FK → `hrs_appraisal_cycles.id` |
| BC-DB-04 | min_rating | DECIMAL(4,2) | NOT NULL |
| BC-DB-05 | max_rating | DECIMAL(4,2) | NOT NULL |
| BC-DB-06 | increment_type | ENUM('percentage','flat') | NOT NULL |
| BC-DB-07 | increment_value | DECIMAL(8,2) | NOT NULL |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-09 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-10 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-11 | created_at | TIMESTAMP | NULL |
| BC-DB-12 | updated_at | TIMESTAMP | NULL |
| BC-DB-13 | deleted_at | TIMESTAMP | NULL — Soft delete |

### 5.2 Validation Rules — StoreIncrementPolicyRequest (Create)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | name | required, string, max:200 | — |
| BC-VAL-02 | appraisal_cycle_id | nullable, exists:hrs_appraisal_cycles,id | — |
| BC-VAL-03 | min_rating | required, numeric, min:0, max:10 | — |
| BC-VAL-04 | max_rating | required, numeric, gt:min_rating, max:10 | — |
| BC-VAL-05 | increment_type | required, in:percentage,flat | — |
| BC-VAL-06 | increment_value | required, numeric, min:0 | — |
| BC-VAL-07 | is_active | required, boolean | — (auto-merged) |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `pay.increment.process` | Granted — all increment operations succeed |
| BC-AUTH-02 | `pay.increment.process` | Denied — 403 Forbidden on all operations |
| BC-AUTH-03 | Guest access | Redirect to /login |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-----------------|
| BC-BIZ-01 | Page load (increment-policies tab) | All policies listed with name, rating range, type, value, appraisal cycle |
| BC-BIZ-02 | Page load (process-increments tab) | Pending flags listed with employee, rating, cycle, paginated 20/page |
| BC-BIZ-03 | Create percentage-type policy | Saved with increment_type=percentage |
| BC-BIZ-04 | Create flat-type policy | Saved with increment_type=flat |
| BC-BIZ-05 | Create policy linked to a cycle | appraisal_cycle_id set |
| BC-BIZ-06 | Create policy without cycle (global) | appraisal_cycle_id=NULL |
| BC-BIZ-07 | Update policy name | Updated, flash success |
| BC-BIZ-08 | Toggle policy status | Via controller — no toggle endpoint for policies (uses edit/update pattern) |
| BC-BIZ-09 | Soft-delete policy | Trashed, is_active=false |
| BC-BIZ-10 | View trashed policies | Only trashed, paginated 15/page |
| BC-BIZ-11 | Restore trashed policy | Restored, flash success |
| BC-BIZ-12 | Force delete policy | Permanently deleted |
| BC-BIZ-13 | Process increments — all flags match policies | Each flag matched, salary revision created, flag status→processed |
| BC-BIZ-14 | Process increments — some flags have no matching policy | Matching flags processed, non-matching flags remain pending |
| BC-BIZ-15 | Process increments — employee has no active salary assignment | Flag skipped (stays pending) |
| BC-BIZ-16 | Process increments — percentage type calculation | New CTC = current × (1 + value/100) |
| BC-BIZ-17 | Process increments — flat type calculation | New CTC = current + increment_value |
| BC-BIZ-18 | Process increments — cycle-specific policy preferred over global | If cycle-specific policy matches, it is chosen over global |
| BC-BIZ-19 | Process increments — employer PF contribution computed | If PF compliance record exists and applicable, PF deducted from gross monthly |
| BC-BIZ-20 | Process increments — employer ESI contribution computed | If ESI compliance record exists, applicable, and gross ≤ ₹21,000, ESI deducted |
| BC-BIZ-21 | Show policy details | Policy loaded with appraisalCycle relationship |
| BC-BIZ-22 | Edit policy form loads | Form pre-filled with existing data |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | `appraisal_cycle_id` | `hrs_appraisal_cycles.id` | — (nullable FK) |
| BC-REF-02 | `hrs_appraisal_increment_flags.appraisal_id` | `hrs_appraisals.id` | — |
| BC-REF-03 | `hrs_appraisal_increment_flags.employee_id` | `sch_employees.id` | — |
| BC-REF-04 | `hrs_appraisal_increment_flags.cycle_id` | `hrs_appraisal_cycles.id` | — |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Load Increment Policies tab | All policies displayed with rating range, type, value, cycle | — | — | ⬜ |
| TC-P02 | Load Process Increments tab | Pending flags displayed with employee, rating, cycle | — | — | ⬜ |
| TC-P03 | Create percentage policy linked to cycle | Created, flash "Increment policy created." | — | — | ⬜ |
| TC-P04 | Create flat policy without cycle (global) | Created with NULL appraisal_cycle_id | — | — | ⬜ |
| TC-P05 | Create policy with min_rating=0.00 and max_rating=10.00 | Full range policy created | — | — | ⬜ |
| TC-P06 | Edit policy name and increment value | Updated, flash "Increment policy updated." | — | — | ⬜ |
| TC-P07 | Show policy details | Policy with appraisalCycle loaded | — | — | ⬜ |
| TC-P08 | Soft-delete policy | Trashed, flash "Increment policy removed." | — | — | ⬜ |
| TC-P09 | View trashed policies | Only trashed, paginated 15/page | — | — | ⬜ |
| TC-P10 | Restore trashed policy | Restored, is_active=true, flash success | — | — | ⬜ |
| TC-P11 | Force delete trashed policy | Permanently deleted, flash success | — | — | ⬜ |
| TC-P12 | Process increments — all flags matched and processed | All processed, salary revisions created, flash "{count} salary increments processed." | — | — | ⬜ |
| TC-P13 | Process increments — percentage: CTC=360000, value=10% | New CTC = 360000 × 1.10 = 396000 | — | — | ⬜ |
| TC-P14 | Process increments — flat: CTC=360000, value=30000 | New CTC = 360000 + 30000 = 390000 | — | — | ⬜ |
| TC-P15 | Process increments — cycle-specific policy selected over global | Cycle-specific policy (ordered DESC) used | — | — | ⬜ |
| TC-P16 | Process increments — PF applicable employee | Employer PF deducted from gross monthly | — | — | ⬜ |
| TC-P17 | Process increments — ESI applicable employee (gross ≤ 21000) | Employer ESI deducted from gross monthly | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create policy without name | Validation error: name required | — | — | ⬜ |
| TC-N02 | Create policy with max_rating <= min_rating | Validation error: gt:min_rating | — | — | ⬜ |
| TC-N03 | Create policy with min_rating < 0 | Validation error: min:0 | — | — | ⬜ |
| TC-N04 | Create policy with max_rating > 10 | Validation error: max:10 | — | — | ⬜ |
| TC-N05 | Create policy with invalid increment_type | Validation error: in:percentage,flat | — | — | ⬜ |
| TC-N06 | Create policy with negative increment_value | Validation error: min:0 | — | — | ⬜ |
| TC-N07 | Create policy with invalid appraisal_cycle_id | Validation error: exists:hrs_appraisal_cycles,id | — | — | ⬜ |
| TC-N08 | Access without permission pay.increment.process | 403 Forbidden | — | — | ⬜ |
| TC-N09 | Guest access | Redirect to /login | — | — | ⬜ |
| TC-N10 | Access non-existent policy ID | 404 Not Found | — | — | ⬜ |
| TC-N11 | Process increments — no matching policy for rating | Flag remains pending, count excludes it | — | — | ⬜ |
| TC-N12 | Process increments — employee has no active salary assignment | Flag skipped (stays pending) | — | — | ⬜ |
| TC-N13 | Process increments — appraisal not finalized | Flag skipped (appraisal->status must be finalized) | — | — | ⬜ |
| TC-N14 | Force delete non-trashed policy | Route uses withTrashed() — succeeds but verify intended flow | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Activity logging — policy CRUD and process operations logged | activityLog() called on all state changes | — | — | ⬜ |
| TC-D02 | B | Model casting — decimal fields correctly cast | min_rating, max_rating, increment_value => decimal:2, is_active => boolean | — | — | ⬜ |
| TC-D03 | B | Model relationship — policy belongsTo appraisalCycle | appraisalCycle() returns AppraisalCycle or null | — | — | ⬜ |
| TC-D04 | C | DB transaction on processIncrements | All flag updates and salary revisions in single transaction | — | — | ⬜ |
| TC-D05 | D | SalaryAssignmentService@revise called for each processed flag | Salary revision record created for each employee | — | — | ⬜ |
| TC-D06 | E | IncrementFlag linked to appraisal via appraisal_id | FK constraint on appraisal_id → hrs_appraisals.id | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Model — `$fillable` matches DDL columns for IncrementPolicy | All DDL columns in fillable | — | — | ◌ |
| TC-CR02 | CR | P1 | Model — `$casts` for decimals/boolean | min_rating/max_rating/increment_value => decimal:2, is_active => boolean | — | — | ◌ |
| TC-CR03 | CR | P1 | Model — SoftDeletes trait implemented | IncrementPolicy uses SoftDeletes | — | — | ◌ |
| TC-CR04 | CR | P1 | Model — relationships defined | appraisalCycle() belongsTo | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — exception handling | process() catches exceptions via IncrementService (DB transaction auto-rollback) | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — DB transactions on processIncrements | DB::transaction() wraps the entire processing loop | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — Gate::authorize() on every method | All policy* and increment methods gated by pay.increment.process | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — activity logged on all state changes | Create/update/delete/restore/forceDelete/process all call activityLog() | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — is_active=false before soft delete | policyDestroy() sets is_active=false before delete() | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — validation rules cover all fields | StoreIncrementPolicyRequest covers all 7 fields with correct rules | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — prepareForValidation() normalizations | is_active merged as boolean with default true | — | — | ◌ |
| TC-CR12 | CR | P1 | Routes — all increment routes registered | All policy CRUD + process routes present | — | — | ◌ |
| TC-CR13 | CR | P1 | Service — rating matching prefers cycle-specific policy | Policy selection query orders by appraisal_cycle_id DESC | — | — | ◌ |
| TC-CR14 | CR | P1 | Service — PF computation matches regulatory formula | PF = min(gross_monthly × 0.50, 15000) × 0.12 | — | — | ◌ |
| TC-CR15 | CR | P1 | Service — ESI computation matches regulatory formula | ESI = gross_monthly × 0.0325 if gross ≤ 21000 and compliance active | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Model — $fillable Matches DDL For IncrementPolicy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open IncrementPolicy model | File exists |
| 2 | Verify $fillable includes: name, appraisal_cycle_id, min_rating, max_rating, increment_type, increment_value, is_active, created_by, updated_by | All present |

#### TC-CR02: Model — $casts
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IncrementPolicy::$casts | min_rating/max_rating/increment_value => decimal:2, is_active => boolean |

#### TC-CR03: Model — SoftDeletes Trait
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IncrementPolicy uses SoftDeletes | Trait present |

#### TC-CR04: Model — Relationships
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify appraisalCycle() | BelongsTo(AppraisalCycle::class) defined |

#### TC-CR05: Controller — Exception Handling
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check process() | Calls IncrementService@processIncrements() which has DB::transaction — auto-rollback on exception |

#### TC-CR06: Controller — DB Transactions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IncrementService@processIncrements() | `DB::transaction(function() ...)` wrapping entire processing loop |

#### TC-CR07: Controller — Gate::authorize() On Every Method
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check policyIndex() | Gate::authorize('pay.increment.process') |
| 2 | Check policyStore() | Gate present |
| 3 | Check policyShow() | Gate present |
| 4 | Check policyEdit() | Gate present |
| 5 | Check policyUpdate() | Gate present |
| 6 | Check policyDestroy() | Gate present |
| 7 | Check index() (pending flags) | Gate present |
| 8 | Check process() | Gate present |
| 9 | Check policyTrashed() | Gate present |
| 10 | Check policyRestore() | Gate present |
| 11 | Check policyForceDelete() | Gate present |

#### TC-CR08: Activity Logged On All State Changes
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check policyStore() | activityLog($policy, 'Created', ...) |
| 2 | Check policyUpdate() | activityLog($policy, 'Updated', ...) |
| 3 | Check policyDestroy() | activityLog($policy, 'Trashed', ...) |
| 4 | Check policyRestore() | activityLog($policy, 'Restored', ...) |
| 5 | Check policyForceDelete() | activityLog($policy, 'Deleted', ...) |
| 6 | Check process() | activityLog(null, 'IncrementsProcessed', ...) |

#### TC-CR09: is_active=false Before Soft Delete
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check policyDestroy() | Sets is_active=false then calls delete() |

#### TC-CR10: Request Validation Rules
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open StoreIncrementPolicyRequest.php | File exists |
| 2 | Verify rules() covers: name, appraisal_cycle_id, min_rating, max_rating, increment_type, increment_value, is_active | All present with correct rules |

#### TC-CR11: prepareForValidation()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check prepareForValidation() | Merges is_active as boolean with default true |

#### TC-CR12: Routes Registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check routes/web.php | All increment-policies routes + increments routes present with correct HTTP verbs and names |

#### TC-CR13: Policy Selection Prefers Cycle-Specific
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IncrementService@processIncrements() | Policy query uses `orderByDesc('appraisal_cycle_id')` — cycle-specific (non-null) comes first |

#### TC-CR14: PF Computation Formula
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IncrementService@computeEmployerPf() | Formula: min(gross_monthly × 0.50, 15000) × 0.12, only if PF compliance record exists and applicable_flag=true |

#### TC-CR15: ESI Computation Formula
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IncrementService@computeEmployerEsi() | Formula: gross_monthly × 0.0325 if gross ≤ 21000 and ESI compliance record exists with applicable_flag=true |

### 7.1 Positive TC Steps

#### TC-P01: Load Increment Policies Tab
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as HR/payroll admin | Dashboard |
| 2 | Navigate to Appraisals → Increment Policies tab | All policies displayed with name, rating range, type, increment value, linked cycle |

#### TC-P02: Load Process Increments Tab
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Process Increments tab | Pending flags displayed with employee name, appraisal rating, cycle name; paginated 20/page |

#### TC-P03: Create Percentage Policy Linked To Cycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Add Policy | Create form opens |
| 2 | Enter name "Excellent Performer" | Name set |
| 3 | Select appraisal cycle | Cycle selected |
| 4 | Enter min_rating=8.00 | Min set |
| 5 | Enter max_rating=10.00 | Max set |
| 6 | Select increment_type=percentage | Type set |
| 7 | Enter increment_value=12.00 | Value set |
| 8 | Click Save | Policy created, flash "Increment policy created." |

#### TC-P04: Create Flat Policy Without Cycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill form: name="Flat Bonus", min=4.00, max=6.99, type=flat, value=5000.00, no cycle | All fields set |
| 2 | Click Save | Policy created with NULL appraisal_cycle_id |

#### TC-P05: Create Full Range Policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create policy with min=0.00, max=10.00 | Full range covers all ratings |

#### TC-P06: Edit Policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit form for existing policy | Pre-filled |
| 2 | Change name to "Updated Policy TC-P06" | Name changed |
| 3 | Change increment_value to 15.00 | Value changed |
| 4 | Click Save | Updated, flash "Increment policy updated." |

#### TC-P07: Show Policy Details
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click View on a policy | Show page with policy details and linked appraisal cycle info |

#### TC-P08: Soft-Delete Policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete a policy | Trashed, is_active=false, flash "Increment policy removed." |

#### TC-P09: View Trashed Policies
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trash view | Only trashed policies, paginated 15/page |

#### TC-P10: Restore Trashed Policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Restore | Restored, is_active=true, flash success |

#### TC-P11: Force Delete Trashed Policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Force Delete | Permanently deleted, flash success |

#### TC-P12: Process Increments — All Matched
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pre-create: finalized appraisals with ratings 4.5, 7.0, 9.0 and corresponding pending flags | Flags exist |
| 2 | Pre-create: policies covering 4.0-6.99=8%, 7.0-10.0=12% | Policies exist |
| 3 | Click "Process Increments" | All 3 processed, salary revisions created, flash "3 salary increments processed." |

#### TC-P13: Percentage Calculation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee CTC=360000, policy type=percentage, value=10% | New CTC = 360000 × 1.10 = 396000 |

#### TC-P14: Flat Calculation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee CTC=360000, policy type=flat, value=30000 | New CTC = 360000 + 30000 = 390000 |

#### TC-P15: Cycle-Specific Policy Preferred
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create global policy (no cycle) covering 4.0-10.0=8% | Global policy |
| 2 | Create cycle-specific policy covering 4.0-10.0=10% | Cycle-specific |
| 3 | Process flag from that cycle | Cycle-specific policy (10%) selected (ordered by appraisal_cycle_id DESC) |

#### TC-P16: PF Applicable Employee
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PF compliance record for employee with applicable_flag=true | Record exists |
| 2 | Process increment for this employee | Employer PF deducted from gross monthly: min(gross_monthly×0.5, 15000)×0.12 |

#### TC-P17: ESI Applicable Employee
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create ESI compliance record for employee with applicable_flag=true and gross ≤ 21000 | Record exists |
| 2 | Process increment | Employer ESI deducted: gross_monthly × 0.0325 |

### 7.2 Negative TC Steps

#### TC-N01: Create Without Name
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name blank, fill other fields | Click Save → validation error: name is required |

#### TC-N02: Max_Rating <= Min_Rating
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set min_rating=8.00, max_rating=7.00 | Max ≤ min |
| 2 | Click Save | Validation error: gt:min_rating |

#### TC-N03: Min_Rating < 0
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set min_rating=-5 | Below minimum |
| 2 | Click Save | Validation error: min:0 |

#### TC-N04: Max_Rating > 10
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set max_rating=11 | Exceeds maximum |
| 2 | Click Save | Validation error: max:10 |

#### TC-N05: Invalid Increment_Type
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set increment_type="bonus" | Not in allowed list |
| 2 | Click Save | Validation error: in:percentage,flat |

#### TC-N06: Negative Increment_Value
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set increment_value=-100 | Negative |
| 2 | Click Save | Validation error: min:0 |

#### TC-N07: Invalid Appraisal_Cycle_Id
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set appraisal_cycle_id=99999 | Does not exist |
| 2 | Click Save | Validation error: exists:hrs_appraisal_cycles,id |

#### TC-N08: Without Permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without pay.increment.process | 403 Forbidden |

#### TC-N09: Guest Access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout | Session cleared |
| 2 | Navigate to /increment-policies | Redirect to /login |

#### TC-N10: Non-Existent Policy ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to /increment-policies/99999 | 404 Not Found |

#### TC-N11: No Matching Policy For Rating
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create flag with rating=2.50, no policy covers 2.00-3.00 range | Policy returns null |
| 2 | Process increments | Flag remains pending (skipped silently) |

#### TC-N12: No Active Salary Assignment
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Employee has no active salary assignment | getActiveAssignment() returns null |
| 2 | Process increment for this employee | Flag skipped (remains pending) |

#### TC-N13: Appraisal Not Finalized
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Appraisal in status other than finalized | Check in processIncrements: `$appraisal->status !== 'finalized'` → skip |

#### TC-N14: Force Delete Non-Trashed Policy
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call force-delete on a non-trashed policy | Route uses withTrashed() findOrFail — succeeds |

### 7.3 Dependency TC Steps

#### TC-D01: Activity Logging
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create, update, delete, restore, process increments | Each action logged in activity log |

#### TC-D02: Model Casting
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check IncrementPolicy::$casts | min_rating/max_rating/increment_value => decimal:2, is_active => boolean |

#### TC-D03: Policy BelongsTo AppraisalCycle
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load policy with appraisalCycle relationship | policy->appraisalCycle returns AppraisalCycle (or null) |

#### TC-D04: DB Transaction On Process
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check processIncrements() | DB::transaction() wrapping the loop — if any step fails, all rolled back |

#### TC-D05: SalaryAssignmentService@revise Called
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Process increments | For each successfully matched flag, revise() is called creating a new salary assignment |

#### TC-D06: IncrementFlag FK To Appraisal
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hrs_appraisal_increment_flags | FK constraint on appraisal_id → hrs_appraisals.id |
