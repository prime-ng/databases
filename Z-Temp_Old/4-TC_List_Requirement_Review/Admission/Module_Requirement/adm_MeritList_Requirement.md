# Merit Lists — Business Requirements

## What This Screen Does

The Merit Lists screen ranks admission applications by composite score to determine seat allotment priority. Each merit list is scoped to an admission cycle, class, and quota type, with configurable criteria weights for academic marks, entrance test scores, and interview performance. The system computes composite scores, applies sibling bonuses, and assigns Shortlisted/Waitlisted/Rejected status based on seat capacity and cutoff thresholds.

The Merit Lists tab is the second of two tabs in the Assessment page (`/admission/assessment?tab=merit-lists`). The first tab shows Entrance Tests. Merit lists depend on entrance test scores computed in the first tab.

The scoring engine (`MeritListService::computeScores()`) fetches all Shortlisted and Waitlisted applications for the given cycle/class/quota, normalizes each score component (academic, entrance, interview) to a 0-100 scale, applies configurable weights, and generates ranked entries with automatic merit status assignment.

## When This Screen Is Used

- **Merit List Creation**: Defining a merit list for a specific class, quota, and cycle combination
- **Score Computation**: Running the scoring engine to rank candidates based on composite scores
- **Result Review**: Viewing ranked candidates with detailed score breakdowns
- **Publication**: Publishing finalized merit lists for allotment processing
- **Seat Allocation**: Determining which candidates are Shortlisted (within capacity), Waitlisted (above capacity but above cutoff), or Rejected (below cutoff)
- **Score Audit**: Reviewing individual candidate scores across all criteria

## Key Fields

**Merit List Configuration**
- List Name
- Admission Cycle, Class, Quota Type — defines the scope
- Seat Capacity — number of available seats for Shortlisted status
- Cutoff Score — minimum composite score to avoid Rejected status
- Sibling Bonus — additional points added for sibling applications
- Criteria Weights — JSON with academic_weight, entrance_weight, interview_weight (default: 40/40/20)

**Status**
- Draft (default), Published
- Displayed as badges (Draft=secondary, Published=success)

**Scoring Criteria Weights**
- Academic Weight % — applied to previous schooling marks
- Entrance Weight % — applied to best entrance test result
- Interview Weight % — applied to interview score
- All weights must sum to exactly 100 (validated in StoreMeritListRequest)

**Entry Fields**
- Merit Rank — position in sorted list
- Composite Score — weighted sum of all normalized scores + sibling bonus
- Academic Score — normalized prev_marks_percent (0-100)
- Entrance Score — best entrance test marks ratio (0-100)
- Interview Score — interview score (0-100)
- Sibling Bonus Applied — boolean flag
- Merit Status: Shortlisted, Waitlisted, Rejected

## Business Rules

**Criteria Weights Must Sum to 100:** The `StoreMeritListRequest::withValidator()` enforces that `criteria_academic_weight + criteria_entrance_weight + criteria_interview_weight === 100`. Any deviation (less or more) fails validation. If no weights are provided, defaults of 40/40/20 are used.

**Score Normalization:**
- **Academic Score**: Taken from the application's `prev_marks_percent` directly (expected 0-100 scale).
- **Entrance Score**: The system finds the best entrance test result for the application by computing `(marks_obtained / max_marks) × 100` for each candidate entry, then selects the highest ratio. Candidates with no test or absent status get 0.
- **Interview Score**: Taken from the application's `interview_score` directly (expected 0-100 scale).

**Composite Score Calculation:**
```
composite = (academic_weight/100 × academic_score)
          + (entrance_weight/100 × entrance_score)
          + (interview_weight/100 × interview_score)
```
If `sibling_bonus > 0` and `application.is_sibling === true`, the bonus is added to the composite score.

**Ranking:** Entries are sorted by `composite_score` descending. Ties are broken by `application_no` ascending (FIFO — earlier applications ranked higher).

**Merit Status Assignment:**
- `Shortlisted` — rank ≤ seat_capacity (within available seats)
- `Waitlisted` — rank > seat_capacity but composite_score ≥ cutoff_score
- `Rejected` — rank > seat_capacity or composite_score < cutoff_score
- If `seat_capacity` is null, all entries get merit_status based on cutoff_score only.
- If `cutoff_score` is null, no Rejected status is assigned (only Shortlisted/Waitlisted).

**Compute Idempotency:** Calling `compute()` on an already-computed list deletes all existing entries and re-creates them. The operation is performed in a DB transaction and the `generated_by` / `generated_at` fields are updated.

**Publish:** The `publish()` action sets the merit list status to `Published`, records `published_at` as the current timestamp, and logs the activity. Publishing does not lock the list — re-publishing is allowed.

**Soft Delete Lifecycle:** Merit lists support soft-delete, restore, and force-delete. Deleting a list cascades to its entries.

**AJAX CRUD:** The Merit Lists tab uses AJAX modals for create and edit operations, returning JSON responses rather than full page redirects. Compute and Publish operations also work via AJAX POST.

## Workflow

1. Admin creates a merit list for a specific cycle + class + quota with configurable weights, capacity, and cutoff
2. System creates list in Draft status
3. Admin runs Compute — the scoring engine processes all Shortlisted/Waitlisted applications
4. System generates ranked entries with composite scores and merit statuses
5. Admin reviews the ranked list on the show page
6. Admin publishes the finalized list, making it available for allotment processing
7. Allotted seats are processed via the Allotment module (linked through MeritListEntry → allotment)

## Related Screens

- **Entrance Tests** — First tab in Assessment; provides entrance test scores for computation
- **Applications** — Source data for candidate scores (academic, interview)
- **Allotment & Enrollment** — Downstream process using published merit lists for seat allocation
- **Admission Cycles** — Merit lists scoped to cycles

## Requirements

- MUST display paginated merit lists at `/admission/assessment?tab=merit-lists` with search and status filter
- MUST authorize via `tenant.adm-merit-list.*` policy gates (14 permissions)
- MUST validate store with 12 rules including criteria weights summing to exactly 100
- MUST default status=Draft, is_active=true on create
- MUST support AJAX CRUD via modals (create, edit, compute, publish)
- MUST compute composite scores using the MeritListService scoring engine
- MUST normalize all score components to a 0-100 scale before weighting
- MUST select best entrance test result when multiple tests exist per application
- MUST apply sibling bonus when configured and application.is_sibling = true
- MUST sort by composite_score DESC, tiebreak by application_no ASC
- MUST assign merit_status: Shortlisted (≤ seat_capacity), Waitlisted (> capacity but ≥ cutoff), Rejected (< cutoff)
- MUST handle null seat_capacity and null cutoff_score gracefully
- MUST be idempotent — re-compute deletes old entries and regenerates
- MUST support soft-delete, restore, force-delete lifecycle
- MUST provide AJAX toggle-status endpoint returning JSON
- MUST show ranked candidates table on the show page sorted by merit_rank
- MUST log all CRUD operations and compute/publish via activityLog()
