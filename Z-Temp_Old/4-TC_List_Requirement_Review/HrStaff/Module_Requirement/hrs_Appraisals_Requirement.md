# Appraisals — Business Requirements

## What This Screen Does

The Appraisals screen is the core of the performance management workflow. Each employee in a cycle receives an appraisal record that captures two-phase ratings: self-assessment submitted by the employee, followed by a manager review submitted by their assigned reviewer. HR then finalises the appraisal, which computes a weighted overall rating from the reviewer scores, creates an increment flag for downstream salary processing, and fires an `AppraisalFinalized` event.

The screen provides role-based visibility — HR sees all appraisals, reviewers see their review assignments plus their own appraisals, and employees see only their own records.

---

## When This Screen Is Used

- Annual Self-Assessment when employees log in to rate themselves against the KPI template items
- Manager Review when a department head or principal evaluates their team members after self-assessment closes
- HR Finalization when the HR manager reviews both ratings, adds remarks, and locks the final score
- Increment Trigger when a finalized appraisal automatically creates a pending increment flag for salary processing

---

## Default Data Load

The Appraisals tab loads via `HrMenuController@appraisalsIncrements()` (GET `/appraisals-overview?tab=appraisals`). A standalone index page exists at `GET /appraisals` via `AppraisalController@index()`. The index query applies role-based filters: HR sees all, reviewers see their own plus their review assignments, employees see only their own. Records are paginated at 25 per page, ordered desc by `created_at`, with `employee`, `cycle`, and `reviewer` relationships eagerly loaded.

---

## Key Fields at a Glance

**Appraisal Identity**
Each record links an Employee to a Cycle, identifying which review period and which staff member. The Reviewer is assigned either automatically from the employee's reporting hierarchy or manually by HR.

**Two-Phase Ratings**
Self-Ratings (JSON) store the employee's per-KPI scores as an array of `{kpi_id, rating, comments}`. Reviewer Ratings (JSON) store the manager's per-KPI scores in the same structure. Self Comments and Reviewer Comments capture overall written assessments (minimum 10 characters, maximum 2000).

**Computed Score and Finalization**
The Overall Rating is a weighted average computed from reviewer ratings (falling back to self ratings if un-reviewed). The value is rounded to 2 decimal places. HR Remarks capture any final notes from the HR manager. Finalized At records the timestamp when the appraisal was locked.

---

## Business Rules and Conditions

**Appraisal State Machine**
The appraisal moves through four states: `draft` (created by cycle generation, editable by employee) → `submitted` (self-assessment completed) → `reviewed` (manager review submitted) → `finalized` (HR locked the score). Each transition is guarded: submit requires `draft`, review requires `submitted`, finalize requires `reviewed`.

**Overall Rating Computation**
The `computeOverallRating()` method in `AppraisalService` loads the cycle's KPI template items and the reviewer ratings. For each rating entry, it multiplies the score by the item's weight percentage divided by 100, sums the weighted values, then normalises by dividing by total weight and multiplying by 100. If weights do not sum to 100, the formula still works via normalisation. If no ratings or no items exist, the rating defaults to 0.0.

**HR Adjustment Cap**
When finalizing, HR cannot directly alter the computed overall rating. The system does not apply any manual override to the computed score — HR may only add `hr_remarks`. (The ±10% tolerance is handled conceptually by the increment policy rating ranges, not by adjusting the computed rating.)

**Delete Protection**
A finalized appraisal cannot be deleted. The controller checks `status === 'finalized'` and returns an error: "Cannot delete a finalized appraisal."

**Increment Flag Auto-Creation**
On finalization, the system automatically creates an `AppraisalIncrementFlag` record with `flag_status = pending`. This triggers the `AppraisalFinalized` event, which downstream increment processing picks up.

**Role-Based Access Control**
The `index()` method checks three permission levels: `hrs.appraisal.manage` (HR — all records), `hrs.appraisal.review` (reviewer — their own + review assignments), or default (employee — own records only). The `show()` method additionally checks ownership: the viewer must be the employee, the reviewer, or have `hrs.appraisal.manage`.

---

## Workflow Steps

**Full Appraisal Lifecycle**
A teacher named "Anita Sharma" is up for annual appraisal. HR generates appraisal records for the "Annual Appraisal 2025-26" cycle, creating a draft record for Anita with her department head assigned as reviewer (auto mode).

Anita logs in, navigates to My Appraisals, sees her draft appraisal. She rates each KPI item (Lesson Quality: 4/5, Student Feedback: 3/5, Punctuality: 5/5, Collaboration: 4/5), adds overall comments ("Good year with strong student results"), and submits. Status changes to `submitted`.

The department head logs in, sees pending reviews. He opens Anita's appraisal, sees her self-ratings, and adds his own ratings (4, 4, 5, 4 respectively) with review comments. He submits. Status changes to `reviewed`.

HR reviews the submission, verifies the computed overall rating (4.15), adds HR remarks ("Meets expectations — eligible for increment"), and finalizes. Status changes to `finalized`, an increment flag is created with `pending` status, and the system fires `AppraisalFinalized`.

---

## Example Scenario

A school's annual appraisal cycle uses a 5-point scale with 4 KPI items: Student Performance (weight 40%, rating 4), Lesson Preparation (25%, rating 5), Punctuality (15%, rating 3), Collaboration (20%, rating 4). The computed overall rating = (4×40 + 5×25 + 3×15 + 4×20) / (40+25+15+20) = (160+125+45+80)/100 = 410/100 = 4.10. HR finalizes, and the increment policy for ratings 4.0–5.0 applies a 10% CTC increase.

---

## Related Screens

- **Appraisal Cycles** — Defines the time window and KPI template for appraisals
- **KPI Templates** — Provides the rated criteria items with weights
- **Increment Policies** — Uses the finalized overall rating to determine increment amounts
- **Process Increments** — Processes pending increment flags to create salary revisions

---

## Requirements

- `AppraisalController@index()` applies role-based filter: HR (`hrs.appraisal.manage`) sees all; reviewers (`hrs.appraisal.review`) see their own plus assigned reviews; others see only their own. Paginated at 25/page.
- `AppraisalController@show()` loads appraisal with `employee`, `reviewer`, `cycle.kpiTemplate.items`. Authorizes via ownership check or `hrs.appraisal.manage`.
- `AppraisalController@generate()` accepts `cycle_id` via POST, finds the cycle, iterates all active employees, creates draft appraisals (skipping existing records via `withTrashed` check), logs count, returns success. Gated by `hrs.appraisal.manage`.
- `AppraisalController@submitSelf()` validates via `SubmitSelfAppraisalRequest`, delegates to `AppraisalService@submitSelfAppraisal()` which checks status is `draft`, sets `self_rating_json`, `self_comments`, transitions to `submitted`. Logs activity. Authorizes via employee ownership check.
- `AppraisalController@submitReview()` validates via `SubmitReviewRequest`, delegates to `AppraisalService@submitManagerReview()` which checks status is `submitted`, sets `reviewer_rating_json`, `reviewer_comments`, transitions to `reviewed`. Logs activity. Authorizes via reviewer ownership check.
- `AppraisalController@finalize()` gates via `hrs.appraisal.manage`, delegates to `AppraisalService@finalize()` which checks status is `reviewed`, computes overall rating, sets `overall_rating`, `hr_remarks`, `finalized_at`, transitions to `finalized`, creates `AppraisalIncrementFlag` with `flag_status=pending`, fires `AppraisalFinalized` event. Logs activity.
- `AppraisalController@destroyAppraisal()` checks `status === 'finalized'` — if true, returns error "Cannot delete a finalized appraisal." Otherwise sets `is_active=false`, soft-deletes, logs activity.
- Standard trash/restore/forceDelete for appraisals with pagination (20/page for trash).
- `SubmitSelfAppraisalRequest` rules: `ratings` required|array|min:1, `ratings.*.kpi_id` required|integer|exists:hrs_kpi_template_items,id, `ratings.*.rating` required|numeric|min:1|max:10, `ratings.*.comments` nullable|string|max:500, `self_comments` required|string|min:10|max:2000.
- `SubmitReviewRequest` rules: same rating structure, `reviewer_comments` required|string|min:10|max:2000.
- `AppraisalService@computeOverallRating()` loads KPI items from cycle template, iterates reviewer ratings, computes weighted sum using `rating * (weight/100)`, normalises by `totalWeight`, returns `round(normalized, 2)`.
- `AppraisalService@finalize()` runs in a DB transaction: throws if status !== reviewed, computes rating, updates appraisal, creates `AppraisalIncrementFlag`, dispatches `AppraisalFinalized` event.
- `AppraisalPolicy`: `viewAny` checks manage/self/review; `view` checks ownership or manage; `submitSelf` checks employee ownership + self permission; `submitReview` checks reviewer ownership + review permission; `finalize` checks manage permission.
- `Appraisal` model: `$casts` self_rating_json/reviewer_rating_json => array, overall_rating => decimal:2, finalized_at => datetime, is_active => boolean.
- Unique key on `(cycle_id, employee_id)` ensures one appraisal per employee per cycle.

---

## Who Can Access

| Gate/Permission | Methods | Notes |
|---|---|---|
| `hrs.appraisal.manage` | `index`, `generate`, `trashed`, `restoreAppraisal`, `forceDeleteAppraisal`, `destroyAppraisal`, `finalize` | HR — full access |
| `hrs.appraisal.manage` OR `hrs.appraisal.review` OR `hrs.appraisal.self` | `show` | Ownership-based OR manage permission |
| Employee ownership | `submitSelf` | Must be the appraisee |
| Reviewer ownership | `submitReview` | Must be the assigned reviewer |
| Guest | — | No access — redirected to /login |

`AppraisalPolicy` also defines `submitSelf`, `submitReview`, `finalize` methods.

---

## Logic Flow

1. **Page Load (index)**: Checks permission level. HR: no filter. Reviewer: `where(employee_id=me OR reviewer_id=me)`. Employee: `where(employee_id=me)`. Fetches with `employee`, `cycle`, `reviewer`. Paginates 25/page.
2. **Generate**: POST `cycle_id`. Finds cycle, gets all active employees, for each checks no existing appraisal (including trashed), creates draft appraisal. Returns count.
3. **Submit Self**: Employee opens appraisal, rates each KPI item on the cycle's template, adds overall comments. POST with ratings array and self_comments. Service checks draft status, saves data, transitions to submitted.
4. **Submit Review**: Reviewer opens submitted appraisal, sees self-ratings, adds reviewer ratings and comments. POST with ratings and reviewer_comments. Service checks submitted status, saves, transitions to reviewed.
5. **Finalize**: HR loads reviewed appraisal, adds optional remarks, clicks Finalize. Service computes overall rating from reviewer ratings × KPI weights. Updates record with rating/remarks/status/finalized_at. Creates increment flag. Dispatches event. Rolls back on any failure via DB transaction.
6. **Show**: Loads with `employee`, `reviewer`, `cycle.kpiTemplate.items`. Authorizes viewer must be employee, reviewer, or HR.
7. **Delete**: Checks not finalized. Sets inactive, soft-deletes.

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|---|---|---|
| ratings | required, array, min:1 | — (attributes: "KPI Ratings") |
| ratings.*.kpi_id | required, integer, exists:hrs_kpi_template_items,id | — |
| ratings.*.rating | required, numeric, min:1, max:10 | — |
| ratings.*.comments | nullable, string, max:500 | — |
| self_comments / reviewer_comments | required, string, min:10, max:2000 | — |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Submit self when not draft | "Cannot submit self-appraisal with status: {status}" | DomainException (flash error) |
| Submit review when not submitted | "Cannot submit review for appraisal with status: {status}" | DomainException (flash error) |
| Finalize when not reviewed | "Cannot finalize appraisal with status: {status}" | DomainException (flash error) |
| Delete finalized appraisal | "Cannot delete a finalized appraisal." | Controller check (back with error) |
| Unauthorized show | 403 | abort_unless |
| Generate success | "{count} appraisal records generated for cycle: {name}." | Flash success |
| Submit self success | "Self-appraisal submitted." | Flash success |
| Review success | "Review submitted." | Flash success |
| Finalize success | "Appraisal finalized." | Flash success |
| Remove success | "Appraisal removed." | Flash success |
| Restore success | "Appraisal restored." | Flash success |

---

## Success Scenarios

**SC-001 — Full Lifecycle**: HR generates appraisals for a cycle. Employee submits self-assessment (draft → submitted). Reviewer submits review (submitted → reviewed with weighted rating 4.10). HR finalizes (reviewed → finalized, increment flag created).

**SC-002 — Self-Assessment Only (No Review Yet)**: Employee submits self-assessment against 4 KPI items. Status becomes submitted. The appraisal awaits reviewer action.

**SC-003 — Bulk Generate Idempotent**: HR clicks Generate twice. First run creates appraisal records for all employees. Second run finds all exist (via `withTrashed`) and creates zero new records.

---

## Failure Scenarios

**FC-001 — Submit Self on Already-Submitted Appraisal**: Employee tries to submit self-assessment after already submitting. Service throws "Cannot submit self-appraisal with status: submitted."

**FC-002 — Review Before Self-Assessment**: Reviewer tries to submit review on a draft appraisal. Service throws "Cannot submit review for appraisal with status: draft."

**FC-003 — Finalize Before Review**: HR tries to finalize a submitted (but not reviewed) appraisal. Service throws "Cannot finalize appraisal with status: submitted."

**FC-004 — Delete Finalized Appraisal**: HR tries to soft-delete a finalized appraisal. Controller returns error "Cannot delete a finalized appraisal."

---

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `hrs_appraisal_cycles.id` | FK parent | `cycle_id` references `hrs_appraisal_cycles.id` |
| `sch_employees.id` | FK parent | `employee_id` and `reviewer_id` reference `sch_employees.id` |
| `hrs_kpi_template_items.id` | FK parent | `ratings.*.kpi_id` references `hrs_kpi_template_items.id` |
| `hrs_appraisal_increment_flags.appraisal_id` | Child FK | Auto-created on finalization, FK CASCADE — |

**Table:** `hrs_appraisals`

| Column | Type | Details |
|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| cycle_id | BIGINT UNSIGNED | NOT NULL, FK → `hrs_appraisal_cycles.id` |
| employee_id | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` |
| reviewer_id | INT UNSIGNED | NULL, FK → `sch_employees.id` |
| self_rating_json | JSON | NULL |
| reviewer_rating_json | JSON | NULL |
| overall_rating | DECIMAL(4,2) | NULL, computed weighted average |
| self_comments | TEXT | NULL |
| reviewer_comments | TEXT | NULL |
| hr_remarks | TEXT | NULL |
| status | ENUM('draft','submitted','reviewed','finalized') | NOT NULL, DEFAULT 'draft' |
| finalized_at | TIMESTAMP | NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |

UNIQUE KEY: `uq_hrs_appraisal` (`cycle_id`, `employee_id`)

**Table:** `hrs_appraisal_increment_flags`

| Column | Type | Details |
|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto-increment |
| appraisal_id | BIGINT UNSIGNED | NOT NULL, FK → `hrs_appraisals.id` |
| employee_id | INT UNSIGNED | NOT NULL, FK → `sch_employees.id` |
| cycle_id | BIGINT UNSIGNED | NOT NULL, FK → `hrs_appraisal_cycles.id` |
| flag_status | ENUM('pending','processed') | NOT NULL, DEFAULT 'pending' |
| processed_at | TIMESTAMP | NULL |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
