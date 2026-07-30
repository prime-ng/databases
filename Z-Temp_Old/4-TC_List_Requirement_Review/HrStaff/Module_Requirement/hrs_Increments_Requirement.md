# Increments — Business Requirements

## What This Screen Does

The Increments feature manages two related sub-screens: Increment Policies and Process Increments. Increment Policies define rules mapping appraisal rating ranges to salary increase amounts — either as a percentage of current CTC or as a flat amount. Policies can be linked to a specific appraisal cycle or left global for any cycle. The Process Increments engine then matches finalized appraisal ratings to applicable policies, computes new CTC values, and creates salary revision records with future effective dates.

This completes the appraisal-to-payroll integration: performance ratings directly drive salary changes through a configurable, transparent rule system.

---

## When This Screen Is Used

- Annual Compensation Planning when HR sets up increment matrices for the upcoming cycle
- Post-Appraisal Processing when HR runs increment processing after all appraisals are finalized
- Policy Revision when the school updates increment percentages mid-year
- Manual Override when an employee's rating falls outside all defined policy ranges

---

## Default Data Load

The Increment Policies tab loads via `HrMenuController@appraisalsIncrements()` (GET `/appraisals-overview?tab=increment-policies`), showing all active policies with their `appraisalCycle` relationship, ordered by `min_rating`. The Process Increments tab loads via the same combined page (`tab=process-increments`), showing pending `AppraisalIncrementFlag` records with `appraisal.employee` and `appraisal.cycle` relationships, paginated at 20 per page using the `flags_page` parameter. A standalone policies index also exists at `GET /increment-policies` via `IncrementController@policyIndex()`.

---

## Key Fields at a Glance

**Policy Definition**
Each policy has a Name, an optional Appraisal Cycle link, a Minimum Rating and Maximum Rating defining the inclusive range, an Increment Type (percentage of current CTC or flat INR amount), and an Increment Value (the percentage or fixed amount).

**Increment Processing**
The engine reads pending flags (created when appraisals are finalized), looks up each appraisal's overall rating, finds the best-matching policy by rating range, computes the new CTC, creates a salary revision (new `hrs_salary_assignments` row with end-dated previous assignment), and marks the flag as processed.

---

## Business Rules and Conditions

**Rating Range Matching**
An appraisal with `overall_rating = R` matches a policy where `min_rating <= R <= max_rating`. If multiple policies match (e.g., one cycle-specific and one global), the system prefers the cycle-specific policy by ordering `appraisal_cycle_id DESC`. If no policy matches, the flag is skipped (remains pending for manual intervention).

**Increment Calculation**
For `percentage` type: new_ctc = current_ctc × (1 + increment_value / 100). For `flat` type: new_ctc = current_ctc + increment_value.

**Salary Revision Integration**
The `IncrementService` uses `SalaryAssignmentService@revise()` to create a new salary assignment with `effective_from_date = next month's start`, a `revision_reason` including the rating and policy name, and computed `gross_monthly` after deducting employer PF and ESI contributions.

**Employer Contribution Computation**
PF employer share is computed at 12% on the PF-eligible wage (capped at ₹15,000, using 50% of gross monthly as basic+DA) if the employee has an active PF compliance record. ESI employer share is computed at 3.25% if the employee has an active ESI compliance record and gross monthly ≤ ₹21,000.

**Flag Lifecycle**
An `AppraisalIncrementFlag` starts at `pending` when created by appraisal finalization. After processing, it transitions to `processed` with a `processed_at` timestamp. Only pending flags are processed; processed and inactive flags are ignored.

---

## Workflow Steps

**Creating a Policy and Processing Increments**
HR creates increment policies for the annual cycle: 0.00–3.99 = 5% increment, 4.00–6.99 = 8%, 7.00–10.00 = 12%. After all appraisals are finalized, HR navigates to Process Increments, sees a list of pending flags with employee names, ratings, current CTC, and the suggested matching policy. HR clicks "Process Increments". The engine iterates each flag, matches the overall rating (e.g., 4.10 → 8% policy), computes new CTC = 360000 × 1.08 = ₹388,800, creates a salary revision effective next month, and updates the flag to processed. The page shows a summary: "15 salary increments processed."

---

## Example Scenario

A school has 50 employees in the annual appraisal cycle. After finalization, 45 appraisals have ratings between 4.00 and 10.00, and 5 have ratings below 4.00. HR created three policies: Below 4.00 = 0% (no increment), 4.00–6.99 = 8%, 7.00–10.00 = 12%. When HR processes increments: 15 employees in the 12% bracket get new CTCs = current × 1.12, 30 employees in the 8% bracket get × 1.08, and 5 employees with rating < 4.00 get no increment (their flags remain pending). The system creates 45 salary revision records.

---

## Related Screens

- **Appraisals** — Provides the finalized ratings and creates the increment flags
- **Appraisal Cycles** — May be linked to policies for cycle-specific increment rules
- **Salary Assignment** — Salary revision records are created under each employee's salary tab
- **Increment Policies** — The policies tab within the same Appraisals & Increments combined page

---

## Requirements

- `IncrementController@policyIndex()` lists active policies with `appraisalCycle` relationship, ordered by `min_rating`, gated by `pay.increment.process`.
- `IncrementController@policyStore()` validates via `StoreIncrementPolicyRequest`, creates the policy, logs activity, redirects to tab with success flash, gated by `pay.increment.process`.
- `IncrementController@policyShow()` loads a single policy with `appraisalCycle` relationship.
- `IncrementController@policyEdit()` loads the policy plus active appraisal cycles for dropdown.
- `IncrementController@policyUpdate()` validates via request, updates policy, logs activity.
- `IncrementController@policyDestroy()` sets `is_active=false`, soft-deletes, logs activity.
- Standard trash/restore/forceDelete for policies with pagination (15/page for trash).
- `IncrementController@index()` lists pending increment flags with `appraisal.employee` and `appraisal.cycle`, paginated at 25/page, gated by `pay.increment.process`. Also provides `processedCount`.
- `IncrementController@process()` delegates to `IncrementService@processIncrements()`, logs result, redirects to increments index with "{count} salary increments processed." flash message. Gated by `pay.increment.process`.
- `IncrementService@processIncrements()` queries pending active flags, iterates in a DB transaction: for each flag, checks appraisal is finalized, finds matching policy ordered by cycle-specific-first, gets current salary assignment via `SalaryAssignmentService@getActiveAssignment()`, computes new CTC per policy type, computes employer PF and ESI, creates salary revision via `SalaryAssignmentService@revise()`, marks flag as processed.
- PF computation: 50% of gross monthly capped at ₹15,000, employer share 12%. Only if PF compliance record exists and `applicable_flag=true`.
- ESI computation: 3.25% of gross monthly if ESI compliance record exists and `applicable_flag=true` and gross_monthly ≤ ₹21,000.
- `StoreIncrementPolicyRequest` rules: `name` required|string|max:200, `appraisal_cycle_id` nullable|exists:hrs_appraisal_cycles,id, `min_rating` required|numeric|min:0|max:10, `max_rating` required|numeric|gt:min_rating|max:10, `increment_type` required|in:percentage,flat, `increment_value` required|numeric|min:0, `is_active` required|boolean.
- `StoreIncrementPolicyRequest::prepareForValidation()` merges `is_active` as boolean with default `true`.
- `IncrementPolicy` model: table `pay_increment_policies`, `$casts` min_rating/max_rating/increment_value => decimal:2, is_active => boolean.
- `IncrementController` gates all methods with `pay.increment.process`.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `pay.increment.process` | All policy CRUD, `index` (pending flags), `process` | HR Payroll — all increment operations require this permission |
| Guest | — | No access — redirected to /login |

No dedicated Policy class for IncrementPolicy — gates are enforced directly via `Gate::authorize('pay.increment.process')` in the controller.

---

## Logic Flow

1. **Policies Page Load**: `policyIndex()` gates, fetches active policies with `appraisalCycle`, ordered by `min_rating`.
2. **Create Policy**: `policyStore()` validates, sets `created_by`/`updated_by`, creates `IncrementPolicy`, logs, redirects.
3. **Process Increments Page Load**: `index()` gates, fetches pending flags with `appraisal.employee` and `appraisal.cycle`, paginated 25/page, plus counts of processed.
4. **Process Increments Execution**: `process()` calls `processIncrements()` which runs a DB transaction: for each pending flag, matches rating to policy, gets active salary assignment, computes new CTC and monthly amounts, calls `SalaryAssignmentService@revise()` to create a new assignment with future effective date, marks flag processed. Returns results collection. Logs and redirects with count.

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|---|---|---|
| name | required, string, max:200 | — |
| appraisal_cycle_id | nullable, exists:hrs_appraisal_cycles,id | — (attributes: "Appraisal Cycle") |
| min_rating | required, numeric, min:0, max:10 | — (attributes: "Minimum Rating") |
| max_rating | required, numeric, gt:min_rating, max:10 | — (attributes: "Maximum Rating") |
| increment_type | required, in:percentage,flat | — (attributes: "Increment Type") |
| increment_value | required, numeric, min:0 | — (attributes: "Increment Value") |
| is_active | required, boolean | — |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Process increments success | "{count} salary increments processed." | Flash success |
| Store policy success | "Increment policy created." | Flash success |
| Update policy success | "Increment policy updated." | Flash success |
| Remove policy success | "Increment policy removed." | Flash success |
| Restore policy success | "Increment Policy restored successfully." | Flash success |
| Force delete policy success | "Increment Policy permanently deleted." | Flash success |

---

## Success Scenarios

**SC-001 — Create Increment Policy**: HR creates a policy "Excellent Performer" with rating range 8.00–10.00, percentage type, increment value 12.00. System creates the policy, logs activity, redirects.

**SC-002 — Process Increments, All Match**: 10 pending flags all have ratings within defined policy ranges. The engine processes all 10, creates salary revisions with effective-from next month, marks flags processed, returns count 10. Flash: "10 salary increments processed."

**SC-003 — Process Increments, Partial Match**: 10 pending flags, 8 have matching policies, 2 have ratings outside all ranges. Engine processes 8, creates 8 salary revisions, skips 2 (flags remain pending). Flash: "8 salary increments processed."

**SC-004 — Percentage vs Flat Computation**: Employee with CTC ₹360,000 and rating 4.5 matches percentage policy (8%). New CTC = 360000 × 1.08 = ₹388,800. Employee with same CTC matches flat policy (₹30,000). New CTC = 390,000.

---

## Failure Scenarios

**FC-001 — No Active Salary Assignment**: An employee has a pending increment flag but no current active salary assignment. The engine skips this employee.

**FC-002 — No Matching Policy**: An employee's rating 2.50 has no policy covering 2.00–3.00. The flag remains pending without processing.

**FC-003 — Validation: max_rating <= min_rating**: HR attempts to create a policy with min=8.00 and max=7.00. Validation fails with `gt:min_rating` rule.

**FC-004 — Validation: Invalid Increment Type**: HR enters "bonus" as increment type. Validation fails with `in:percentage,flat`.

---

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `hrs_appraisal_cycles.id` | FK parent | `appraisal_cycle_id` references `hrs_appraisal_cycles.id`, nullable |
| `hrs_appraisals.id` | FK parent | Increment flag references appraisal record |
| `sch_employees.id` | FK parent | employee_id on flags and salary assignments |
| `hrs_salary_assignments` | Child/service | Salary revisions created for each processed flag |
| `hrs_compliance_records` | Service | Employer PF/ESI computation uses compliance records |
| `SalaryAssignmentService` | Service | `getActiveAssignment()` and `revise()` called during processing |

**Table:** `pay_increment_policies`

| Column | Type | Details |
|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| name | VARCHAR(200) | NOT NULL |
| appraisal_cycle_id | BIGINT UNSIGNED | NULL, FK → `hrs_appraisal_cycles.id` |
| min_rating | DECIMAL(4,2) | NOT NULL, inclusive lower bound |
| max_rating | DECIMAL(4,2) | NOT NULL, inclusive upper bound |
| increment_type | ENUM('percentage','flat') | NOT NULL |
| increment_value | DECIMAL(8,2) | NOT NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
