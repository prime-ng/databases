# Increment Policies & Processing — Requirements

## What It Does
Defines increment rules based on appraisal ratings. Each policy has a rating range (min to max), increment type (percentage of CTC or flat amount), and is linked to an appraisal cycle. The processing engine matches finalized appraisals with applicable policies, computes increment amounts, and creates salary revision records.

Features:
- Rating-based increment policies (percentage or flat amount)
- Appraisal cycle linkage for policy-to-cycle matching
- Min/max rating range per policy (non-overlapping recommended)
- Policy precedence: higher rating = higher increment %
- Processing engine: matches appraisal rating → applicable policy → computes increment
- Integration with salary assignment revision
- Soft-delete with full restore/force-delete

## Database Fields

**pay_increment_policies**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(200) | Required. E.g., `Outstanding Performer Increment`, `Good Performer Increment`. |
| `appraisal_cycle_id` | BIGINT UNSIGNED FK → `hrs_appraisal_cycles` | Nullable. If set, policy applies only to this cycle. |
| `min_rating` | DECIMAL(4,2) | Minimum rating for this policy. E.g., 8.00. |
| `max_rating` | DECIMAL(4,2) | Maximum rating for this policy. Must be > min_rating. E.g., 10.00. |
| `increment_type` | ENUM | `percentage`, `flat`. |
| `increment_value` | DECIMAL(8,2) | For percentage: percent value (e.g., 15.00 = 15%). For flat: amount in currency (e.g., 5000.00). |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Rating Range Matching**
- An appraisal with `overall_rating = R` matches a policy if `min_rating <= R <= max_rating`
- If no policy covers the rating, no increment is applied
- Ranges should not overlap for deterministic matching — if they do, the first matching policy by ID is used

**Increment Computation**
- `percentage` type: `increment_amount = current_ctc × (increment_value / 100)`
- `flat` type: `increment_amount = increment_value`
- New CTC = `current_ctc + increment_amount`

**Processing Flow**
1. HR views the "Increments" page showing all `AppraisalIncrementFlag` with `flag_status = pending`
2. HR clicks "Process Increments"
3. System iterates pending flags:
   - Looks up appraisal's `overall_rating`
   - Finds matching `IncrementPolicy` for the cycle
   - If found: computes new CTC, creates a salary revision (new `SalaryAssignment` with end-dated current)
   - Updates `IncrementFlag.flag_status` → `processed`, sets `processed_at`
   - If no matching policy: flag stays `pending` (manual intervention needed)

**Policy vs Cycle**
- If `appraisal_cycle_id` is set: policy only applies to appraisals in that cycle
- If `appraisal_cycle_id` is null: policy is global and can match any cycle
- Multiple policies can exist per cycle with different rating ranges

**Manual Override**
- If no policy matches, HR can manually process the increment
- Manual processing: enter increment amount or percentage directly
- Creates a new salary assignment with the manual value

## CRUD Operations

**List Increment Policies**
- Table: name, rating range, type, value, linked cycle, active status
- Policies are grouped by appraisal cycle

**Create Increment Policy**
- Rating range should not overlap existing policies (warning, not hard block)

**Show / Edit / Update / Destroy**

**Soft Delete / Restore / Force Delete**

**View Pending Increments**
- Shows all `AppraisalIncrementFlag` with `flag_status = pending`
- Each row: employee name, appraisal rating, cycle, current CTC, suggested increment
- Suggestion based on best-matching policy (computed but not yet applied)

**Process Increments**
- Processes all pending increment flags
- For each: find policy → compute → create salary revision → mark processed
- Returns summary: X processed, Y skipped (no matching policy)

## Permissions

| Operation | Permission Key |
|---|---|
| View / Manage increment policies | `hrs.appraisal.manage` |
| View pending increments | `hrs.appraisal.manage` |
| Process increments | `hrs.appraisal.manage` |
