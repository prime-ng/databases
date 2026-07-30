# Fee Fine Rules — Business Requirements

## What This Screen Does

The Fee Fine Rules screen defines late payment fine rules for overdue invoices. It allows the school to configure how fines are calculated, applied, and what actions are taken when fines exceed limits. Supports percentage-based (per day or flat per tier) and fixed-amount fine calculation modes. Fines can be recurring with configurable intervals, have maximum caps, grace periods, and expiry actions. This screen is part of the Fine Management tab group in the Student Fee module.

---

## When This Screen Is Used

- **Late Fee Setup** when an Accountant configures the daily late fee percentage for tuition fee installments
- **Tiered Fine Configuration** when the school wants different fine rates for different overdue periods (e.g., ₹25/day for days 1–10, ₹50/day for days 11–30)
- **Expiry Action Configuration** when setting actions like name removal or suspension after accumulated fines cross thresholds
- **Recurring Fine Setup** when fines need to be reapplied every N days until the invoice is paid

## Default Data Load

This screen displays within the Fine Management tab group. When the user navigates to Student Fee → Fine Management, `StudentFeeManagementController@fineManagement()` loads all fine management data simultaneously: `FeeFineRule` paginated at 10 per page and `FeeFineTransaction` paginated at 15 per page. The fine rules grid shows rule_name, fine_type, fine_value, calculation_mode, grace_period_days, recurring status, and is_active status.

---

## Key Fields at a Glance

**Rule Identity**
The `rule_name` is a required human-readable name (e.g., "Daily Late Fee 2%", "Fixed Late Fee ₹500"). The `applicable_on` field defines the scope — whether the rule applies to a Fee Structure, an Installment, or a specific Head. The `applicable_id` holds the ID of the entity the rule applies to.

**Fine Calculation**
Three `fine_type` options: **Percentage** (fine = base_amount × fine_value / 100), **Fixed** (fine = fine_value), **Percentage+Capped** (percentage calculation with a `max_fine_amount` cap). The `fine_calculation_mode` determines if the fine is applied **PerDay** (fine_value × days_late) or **FlatPerTier** (one-time flat fine regardless of days late).

**Temporal Controls**
`grace_period_days` defines the buffer after due date before fines start. `applicable_from_day` and `applicable_to_day` define a day range within which the rule is active. `recurring` when enabled with `recurring_interval_days` reapplies fines at regular intervals. `max_fine_installments` limits how many times a recurring fine can be applied.

**Expiry Actions**
When accumulated fines reach thresholds, `action_on_expiry` defines what happens: `None`, `Mark Defaulter`, `Remove Name`, or `Suspend`.

---

## Business Rules and Conditions

**Fine Calculation Modes**
- **PerDay**: `fine = base_amount × (fine_value / 100) × days_late`. Each day past due adds the daily fine amount.
- **FlatPerTier**: `fine = fixed_amount` (one-time flat fine regardless of days late). Applied only once per overdue period.

**Conditional Validation**
- If `fine_type` is `Percentage+Capped`, `max_fine_amount` is required. The system validates this with error: "Max fine amount is required for capped percentage fine."
- If `recurring` is enabled, `recurring_interval_days` is required. The system validates this with error: "Recurring interval days required when recurring fine is enabled."
- If `fine_type` is not `Percentage+Capped`, `max_fine_amount` is forced to null.
- If `recurring` is not enabled, `recurring_interval_days` and `max_fine_installments` are forced to null.

**Grace Period**
Fine calculation starts after `due_date + grace_period_days`. `days_late` counts from the day after grace period ends.

**Max Fine Amount**
If `max_fine_amount` is set, cumulative fine for the invoice cannot exceed this value. Once max is reached, `action_on_expiry` is triggered.

**Duplicate Prevention**
The `ApplyFines` command checks for existing fine transactions before creating new ones. Prevents duplicate fine for the same `invoice_id + fine_rule_id + fine_date`. For recurring fines, checks if fine was already applied for the current interval.

**Soft Delete with Reactivation**
When a fine rule is soft-deleted, `is_active` is set to `false` before `delete()`. On restore, `is_active` is set back to `true`.

---

## Workflow Steps

**Creating a Fine Rule**
The Accountant clicks "Add Fine Rule" and selects the rule type (Percentage/Fixed/Percentage+Capped), enters the fine value, selects calculation mode (PerDay/FlatPerTier), sets the applicable scope (Fee Structure/Installment/Head with specific ID), defines the day range, grace period, and optional expiry action. If Percentage+Capped, max_fine_amount must be provided. If recurring, interval days must be set.

**Editing a Fine Rule**
The user loads the edit form pre-filled with existing rule data. Changing fine_type from Percentage+Capped to another type automatically clears max_fine_amount. Disabling recurring clears interval and max_installments fields.

**Soft Deletion**
The user clicks delete. The system sets `is_active = false`, then soft-deletes. The rule is moved to trash and can be viewed in the trash page. Restore reactivates the rule.

---

## Example Scenario

A school implements a tiered late fee policy for tuition fee installments:
- **Tier 1**: Days 1–10 overdue: ₹25/day fixed fine (PerDay mode)
- **Tier 2**: Days 11–30 overdue: ₹50/day fixed fine (PerDay mode)
- **Tier 3**: Days 31–60 overdue: ₹100/day fixed fine (PerDay mode) with max cap of ₹3,000
- **Tier 4**: Day 61+: Name removal triggered (FlatPerTier mode, action_on_expiry = "Remove Name")

Each tier is a separate `FeeFineRule` record. The `applicable_from_day` and `applicable_to_day` fields define the range for each tier. The `ApplicableFines` command runs daily, checks all overdue invoices, and applies the appropriate tier rules.

---

## Related Screens

- **Fine Transactions** — Displays all applied fines per student/invoice with waiver workflow
- **Governance** — Shows name removal logs triggered by fine rule expiry actions
- **Billing** — Invoice grid showing accrued fine amounts on overdue invoices

---

## Requirements

- Controller `FeeFineRuleController`; `index()` redirects to `student-fee.fineManagement` tab; `Gate::authorize('tenant.fee-fine-rule.view')` is enforced
- Route: `student-fee.fee-fine-rule.*` (resourceful with custom trash/restore/forceDelete/toggleStatus)
- `store()` validates via `StoreFeeFineRuleRequest`; conditional logic: Percentage+Capped requires max_fine_amount; recurring requires interval_days; normalizes booleans for `recurring` and `is_active`; sets `created_by` and `updated_by`
- `update()` validates via `UpdateFeeFineRuleRequest`; same conditional logic as store; sets `updated_by`
- `create()` passes dropdown options: `applicableOptions` = ['Fee Structure', 'Installment', 'Head']; `fineTypes` = ['Percentage', 'Fixed', 'Percentage+Capped']; `expiryActions` = ['None', 'Mark Defaulter', 'Remove Name', 'Suspend']
- `destroy()` sets `is_active = false` then soft-deletes, logs activity "Fee Fine Rule deactivated and moved to trash."
- `restore()` restores and sets `is_active = true`
- `forceDelete()` permanently deletes with activity log
- `toggleStatus()` flips `is_active` flag, returns JSON `{success, is_active, message}`
- `trashedFeeFineRules()` lists only soft-deleted records, paginated at 10 per page
- Activity logged via `activityLog()` for Created, Updated, Trashed, Restored, Deleted, Toggled events
- Fine calculation engine in `FeeFineRule::calculateFine(float $baseAmount)` supports three fine types with capping

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.fee-fine-rule.view` | `index()`, `show()` | Page load + view |
| `tenant.fee-fine-rule.create` | `create()`, `store()` | Create form + submit |
| `tenant.fee-fine-rule.update` | `edit()`, `update()` | Edit form + submit |
| `tenant.fee-fine-rule.delete` | `destroy()` | Soft delete |
| `tenant.fee-fine-rule.restore` | `trashedFeeFineRules()`, `restore()` | Trash view + restore |
| `tenant.fee-fine-rule.forceDelete` | `forceDelete()` | Permanent delete |
| `tenant.fee-fine-rule.status` | `toggleStatus()` | Toggle active/inactive |

## Logic Flow

1. **Page Load** — Screen loads via Fine Management tab. `StudentFeeManagementController@fineManagement()` gates `tenant.student-fee-management.viewAny`. Loads `FeeFineRule::paginate(10)` and `FeeFineTransaction::with(['student.user', 'invoice', 'fineRule'])->latest('fine_date')->paginate(15)`.
2. **Create** — `create()` gates `tenant.fee-fine-rule.create`, passes dropdown options. `store()` validates via `StoreFeeFineRuleRequest`. Conditional logic enforces Percentage+Capped → max_fine_amount required, recurring → interval required. Normalizes booleans. `FeeFineRule::create()` with `created_by` and `updated_by`. Activity logged.
3. **Edit** — `edit()` gates `tenant.fee-fine-rule.update`, loads rule with same dropdown options. `update()` validates via `UpdateFeeFineRuleRequest`. Conditional sanitization: non-capped types clear `max_fine_amount`; non-recurring clears interval/installment fields.
4. **Delete** — `destroy()` sets `is_active = false`, saves, then `delete()`. Activity logged as "Trashed". `restore()` nullifies `deleted_at` and sets `is_active = true`.
5. **Toggle Status** — `toggleStatus()` flips `is_active`, returns JSON `{success: true/false, is_active, message}`.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `rule_name` | `required, string, max:100` | — |
| `applicable_on` | `required, in:Fee Structure,Installment,Head` | — |
| `applicable_id` | `required, integer, min:1` | — |
| `fine_type` | `required, in:Percentage,Fixed,Percentage+Capped` | — |
| `fine_value` | `required, numeric, min:0` | — |
| `max_fine_amount` | `nullable, numeric, min:0` | — |
| `grace_period_days` | `nullable, integer, min:0` | — |
| `recurring` | `nullable, boolean` | — |
| `recurring_interval_days` | `nullable, integer, min:1` | — |
| `max_fine_installments` | `nullable, integer, min:1` | — |
| `applicable_from_day` | `required, integer, min:1` | — |
| `applicable_to_day` | `nullable, integer, gte:applicable_from_day` | — |
| `action_on_expiry` | `nullable, in:None,Mark Defaulter,Remove Name,Suspend` | — |
| `is_active` | `nullable, boolean` | — |
| **fine_type = Percentage+Capped (no max_fine_amount)** | Controller after-validation | "Max fine amount is required for capped percentage fine." |
| **recurring enabled (no interval_days)** | Controller after-validation | "Recurring interval days required when recurring fine is enabled." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Percentage+Capped without max_fine_amount | "Max fine amount is required for capped percentage fine." | Validation (after) |
| Recurring enabled without interval | "Recurring interval days required when recurring fine is enabled." | Validation (after) |
| Delete fine rule | "Fee Fine Rule deactivated and moved to trash." | Activity log |
| Restore fine rule | "Fee Fine Rule restored from trash." | Activity log |
| Force delete fine rule | "Fee Fine Rule permanently deleted." | Activity log |
| Toggle status success | flash('status_updated.fee_fine_rule') | JSON |
| Toggle status failure | flash('status_switch_failed.fee_fine_rule') | JSON |

## Success Scenarios

**SC-001 — Creating a Percentage+Capped Fine Rule**
Accountant creates rule with rule_name="Late Fee 2% Capped", fine_type="Percentage+Capped", fine_value=2.00, max_fine_amount=2000.00, applicable_on="Installment", applicable_id=1, grace_period_days=5, applicable_from_day=1, applicable_to_day=30. System saves and returns success message "Fee Fine Rule created successfully."

**SC-002 — Creating a Recurring Fixed Fine Rule**
Accountant creates rule with rule_name="Weekly Fixed Fine", fine_type="Fixed", fine_value=100.00, recurring=true, recurring_interval_days=7, max_fine_installments=4. System saves and returns success.

**SC-003 — Toggle Fine Rule Status**
Accountant toggles is_active on an existing rule. System flips the flag and returns JSON `{success: true, is_active: false}`.

**SC-004 — Restore Soft-Deleted Fine Rule**
Accountant restores a fine rule from trash. System nullifies `deleted_at` and sets `is_active = true`. Returns flash success.

## Failure Scenarios

**FC-001 — Percentage+Capped Without Max Amount**
User sets fine_type="Percentage+Capped" but leaves max_fine_amount empty. System returns validation error: "Max fine amount is required for capped percentage fine."

**FC-002 — Recurring Without Interval**
User enables recurring but leaves recurring_interval_days empty. System returns validation error: "Recurring interval days required when recurring fine is enabled."

**FC-003 — Applicable_to_day Less Than Applicable_from_day**
User sets applicable_from_day=30 and applicable_to_day=10. Validation rule `gte:applicable_from_day` fails.

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `fee_fine_rules` | Main Table | All CRUD operations on this table |
| `fee_fine_transactions` | Child Table | Fine rules are referenced by fine transactions (FK RESTRICT) |
| `fee_invoices` | FK Reference | Applied_on references fee_invoices indirectly via applicable_id |
| `FeeFineService` | Service | Used by FeeFineTransactionController for recording fines |
| Activity Log | Consumer | `activityLog()` on all CRUD events |
