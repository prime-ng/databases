# Lib Fine Slab Config — Business Requirements

## What This Screen Does
Manages tiered fine slab configurations — named sets of rules that define how late fines accumulate over time based on day ranges. Each configuration defines the fine calculation method (`fine_amt_calc_type`), maximum fine cap (`max_fine_cap`), effective date range, priority, applicability scope (membership type and resource type filters), and contains multiple fine slab details (individual day-range rows in the child table). Admins can create, edit, view, soft-delete, restore, and permanently delete slab configurations.

---

## When This Screen Is Used
- Defining a new late-fee structure (e.g., "Standard Late Fee" with escalating rates).
- Configuring priority order when multiple slab sets exist (higher priority slabs apply first).
- Setting which fine type, membership types, and resource types a slab applies to.
- Deactivating an outdated slab configuration so it is no longer used.
- Viewing the details (day ranges and rates) of a specific slab configuration.

## Default Data Load
- Index: Paginated list of all slab configurations with name, priority, fine type, and active status.
- Create: Blank form with fields for name, fine type, fine amount calculation type, max fine cap, effective dates, priority, membership/resource type filters, and active toggle.
- Edit: Pre-populated form with existing slab configuration data.
- Show: Detailed view of the slab configuration including all associated slab detail rows (day ranges and rates).
- Trash: Paginated list of soft-deleted configurations with restore and force-delete actions.

---

## Key Fields at a Glance
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| name | VARCHAR(100) | required, max:100 | Display name (e.g., "Standard Late Fee") |
| fine_type_id | INT UNSIGNED | FK→lib_fine_type, required | Links to the fine category (Late Return, Lost Book, etc.) |
| fine_amt_calc_type | ENUM | 'Fixed','Percentage','BookCost' | How the fine amount is computed |
| max_fine_cap | ENUM | 'Fixed','BookCost','Unlimited' | Limits the maximum fine charged |
| max_fine_amt | DECIMAL(10,2) | nullable | Required when max_fine_cap='Fixed'; NULL otherwise |
| membership_type_id | INT UNSIGNED | FK→lib_membership_types, nullable | NULL = applies to ALL membership types |
| resource_type_id | INT UNSIGNED | FK→lib_resource_types, nullable | NULL = applies to ALL resource types |
| effective_from | DATE | required | Start of slab validity period |
| effective_to | DATE | nullable, >= effective_from | End of slab validity; NULL = valid indefinitely |
| priority | INT | DEFAULT 0, min:0, max:255 | Higher priority evaluated first (0=lowest, 255=highest) |
| is_active | TINYINT(1) | DEFAULT 1, boolean | Soft on/off toggle |

---

## Business Rules and Conditions

### 1. Slab Applicability (Scope Filtering)
- `membership_type_id` = NULL: The slab applies to ALL membership types.
- `membership_type_id` = specific: The slab applies ONLY to that membership type.
- `resource_type_id` = NULL: The slab applies to ALL resource types.
- `resource_type_id` = specific: The slab applies ONLY to that resource type.
- These act as **slab filters only** — they do NOT change the calculation formula.

### 2. Fine Type Required
Every slab must be linked to a valid fine type (e.g., Late Return, Lost Book) via `fine_type_id` FK to `lib_fine_type`.

### 3. Fine Amount Calculation (`fine_amt_calc_type`)
Determines how the raw fine amount is computed:
- **Fixed:** A fixed amount is charged regardless of the book's value. The actual per-unit rate is defined in child `lib_fine_slab_details.fine_rate`.
- **Percentage:** Fine is calculated as a percentage of the book's purchase cost. The percentage rate is defined in child `lib_fine_slab_details.fine_rate`.
- **BookCost:** Fine equals the full purchase cost of the book. In this case, `fine_rate` in the child table is not applicable — the raw fine = book's purchase cost directly.

### 4. Maximum Fine Cap (`max_fine_cap`)
Limits the maximum fine that can be charged:
- **Fixed:** Fine cannot exceed `max_fine_amt` value. `max_fine_amt` must have a value (cannot be NULL).
- **BookCost:** Fine cannot exceed the book's purchase cost. `max_fine_amt` is not applicable and should be NULL.
- **Unlimited:** No upper limit on fine amount. `max_fine_amt` is not applicable and should be NULL.

### 5. Effective Period
- `effective_from` is required (start date of slab validity).
- `effective_to` is optional. If provided, it must be >= `effective_from`.
- If `effective_to` is NULL, the slab is valid indefinitely.
- The system only applies slabs that are currently within their effective period (`effective_from <= CURRENT_DATE AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)`).

### 6. Priority Order
- Higher `priority` values are evaluated first (range: 0 lowest to 255 highest, default 0).
- The system picks the highest-priority matching slab when calculating fines.
- When two slabs have the same priority, the one with the more specific applicability (specific `membership_type_id` or `resource_type_id`) should be preferred over a general (NULL) slab.

### 7. Slab Day Ranges (Child Table)
The actual fine rates by day range are stored in `lib_fine_slab_details` (child table). Day ranges (e.g., 1-7 days, 8-30 days) must not overlap within the same slab configuration. The combination `(fine_slab_config_id, from_day, to_day)` is enforced as unique.

### 8. Cascade Delete
When a slab configuration is deleted (soft or force), all associated slab details are also deleted via DB cascade (`ON DELETE CASCADE`).

### 9. Soft Delete & Restore
- Deleting a configuration soft-deletes the record and cascades to its details.
- Restoring a configuration does NOT automatically restore its details (they remain soft-deleted).

### 10. Active Toggle
Inactive configurations (`is_active = 0`) are not used in fine calculations but remain available for reactivation.

### 11. Indirect Effect via Membership Type
While `membership_type_id` is a slab filter only, `lib_membership_types.grace_period_days` and `lib_membership_types.loan_period_days` indirectly affect fine calculation — see Complete Fine Calculation Flow below.

---

## 📐 Complete Fine Calculation Flow (Steps 1-5)

This section explains the end-to-end fine calculation by combining both the parent (`lib_fine_slab_config`) and child (`lib_fine_slab_details`) table logic.

### Step 1: Find the Matching Slab
The system finds the best matching slab config for the transaction using these filters (in order):
- `is_active = 1` AND `deleted_at IS NULL`
- `effective_from <= CURRENT_DATE` AND (`effective_to IS NULL` OR `effective_to >= CURRENT_DATE`)
- `fine_type_id` matches the applicable fine type (e.g., LateReturn)
- `membership_type_id` matches the member's membership type OR is NULL (applies to all)
- `resource_type_id` matches the book's resource type OR is NULL (applies to all)
- Among all matching slabs, pick the one with the **highest `priority`** value.
- If priority is equal, prefer the slab with a **specific** `membership_type_id` or `resource_type_id` over a NULL (general) one.

### Step 2: Calculate Overdue Days (with Grace Period)
**a) Get Due Date:**
- `due_date` is set at the time of book issue based on `loan_period_days` from `lib_membership_types`.
- Formula: `due_date = issue_date + loan_period_days`
- This is stored in `lib_transactions.due_date`.

**b) Calculate Raw Overdue Days:**
- `raw_overdue_days = actual_return_date − due_date`
- If `raw_overdue_days <= 0` → Book returned on time → **No fine applicable. Stop here.**

**c) Apply Grace Period (`grace_period_days` from `lib_membership_types`):**
- `grace_period_days` = Number of free days allowed after due date before fine starts.
- `billable_days = raw_overdue_days − grace_period_days`
- If `billable_days <= 0` → Book returned within grace period → **No fine applicable. Stop here.**
- If `billable_days > 0` → Use `billable_days` as `overdue_days` for fine calculation.

**d) Find Matching Day Range (`lib_fine_slab_details`):**
- Find the detail row where `from_day <= billable_days <= to_day` for the matched slab config.
- If no matching day range is found → **No fine applicable for that slab.**

### Step 3: Calculate Raw Fine Amount
Use the matched detail row's `fine_rate`, `rate_type`, and `calculation_type`:

| rate_type | calculation_type | Formula |
|-----------|-----------------|---------|
| Fixed | Per_Day | `fine_rate × overdue_days` |
| Fixed | Per_Week | `fine_rate × CEIL(overdue_days / 7)` |
| Fixed | Per_Month | `fine_rate × CEIL(overdue_days / 30)` |
| Fixed | Per_Year | `fine_rate × CEIL(overdue_days / 365)` |
| Fixed | Per_Book | `fine_rate` (flat, one-time charge) |
| Percentage | Per_Day | `(fine_rate / 100) × book_purchase_cost × overdue_days` |
| Percentage | Per_Week | `(fine_rate / 100) × book_purchase_cost × CEIL(overdue_days / 7)` |
| Percentage | Per_Month | `(fine_rate / 100) × book_purchase_cost × CEIL(overdue_days / 30)` |
| Percentage | Per_Year | `(fine_rate / 100) × book_purchase_cost × CEIL(overdue_days / 365)` |
| Percentage | Per_Book | `(fine_rate / 100) × book_purchase_cost` (flat, one-time) |

> **Note:** When the parent `fine_amt_calc_type = 'BookCost'`, the raw fine = full `book_purchase_cost` regardless of child table values.

### Step 4: Apply Maximum Fine Cap (from parent `max_fine_cap`)
| max_fine_cap | Rule |
|-------------|------|
| **Fixed** | `Final Fine = MIN(raw_fine, max_fine_amt)` |
| **BookCost** | `Final Fine = MIN(raw_fine, book_purchase_cost)` |
| **Unlimited** | `Final Fine = raw_fine` (no cap applied) |

### Step 5: Final Fine Amount
The result from Step 4 is the final fine amount to be charged to the member and recorded in `lib_fines`.

---

## Workflow Steps
1. Admin navigates to Fine Slab Config list.
2. Admin clicks "Add Slab Config" to open the create form.
3. Admin enters a name, selects the fine type, sets the calculation type and max cap, sets effective dates, chooses priority, optionally filters by membership/resource type, and toggles active status.
4. System validates and saves the configuration.
5. Admin is redirected to the list where the new configuration appears.
6. Admin clicks "Show" on a configuration to view its slab details.
7. Admin can edit the configuration or toggle its status.
8. Admin can soft-delete the configuration; it and its details move to trash.
9. From the trash view, Admin can restore or permanently delete.

---

## Example Scenario
**Creating a "Standard Late Fee" slab:**
1. Admin creates a slab config named "Standard Late Fee" with priority `1`, fine_type `LateReturn`, calc type `Fixed`, max cap `Unlimited`, effective from `2025-01-01`, applicable to all membership and resource types.
2. Admin then adds slab details (via the related details screen):
   - Days 1-3: rate $2.00/day (rate_type=Fixed, calculation_type=Per_Day)
   - Days 4-7: rate $3.00/day
   - Days 8+: rate $5.00/day
3. When a book is returned 5 days late with a 2-day grace period: billable_days = 3. Day range 1-3 matches → fine = 3 × $2.00 = $6.00.
4. Later, the library introduces an "Expedited Late Fee" with priority `10` that overrides the standard fee for certain items.

---

## Related Screens
- **Fine Slab Details** — Each slab configuration contains multiple detail rows (day range + rate) managed via `LibFineSlabDetailController`.
- **Fine Calculation Engine** — The slab configuration is referenced when calculating late fines programmatically.
- **Fine Types** — Defines the fine categories (LateReturn, LostBook, etc.) referenced by `fine_type_id`.
- **Membership Types** — Provides `grace_period_days` and `loan_period_days` that indirectly affect fine calculation.
- **Resource Types** — Optional filter for slab applicability.

---

## Requirements
(technical: controller, model, validation, activityLog, policy)

- **Controller:** `LibFineSlabConfigController` — Standard CRUD with `show` method that loads the configuration plus its `details` relationship for display.
- **Model:** `LibFineSlabConfig` — table `lib_fine_slab_configs`, fillable: `name`, `fine_type_id`, `fine_amt_calc_type`, `max_fine_cap`, `max_fine_amt`, `membership_type_id`, `resource_type_id`, `effective_from`, `effective_to`, `priority`, `is_active`. Relationships: `details()` hasMany `LibFineSlabDetail`, `fineType()` belongsTo `LibFineType`, `membershipType()` belongsTo `LibMembershipType`, `resourceType()` belongsTo `LibResourceType`.
- **Validation (FormRequest):** `name` => required|string|max:100; `fine_type_id` => required|exists:lib_fine_type,id; `fine_amt_calc_type` => required|in:Fixed,Percentage,BookCost; `max_fine_cap` => required|in:Fixed,BookCost,Unlimited; `max_fine_amt` => required_if:max_fine_cap,Fixed|nullable|numeric|min:0; `membership_type_id` => nullable|exists:lib_membership_types,id; `resource_type_id` => nullable|exists:lib_resource_types,id; `effective_from` => required|date; `effective_to` => nullable|date|after_or_equal:effective_from; `priority` => required|integer|min:0|max:255; `is_active` => boolean.
- **ActivityLog:** Must call `activityLog()` after create, update, delete, restore, forceDelete.
- **Policy:** Gate string `tenant.lib-fine-slab-configs.*` mapped to `LibFineSlabConfigPolicy`.
- **Permissionslist entry:** `'lib-fine-slab-configs' => $crud`

---

## Who Can Access This Screen
- Users with `tenant.lib-fine-slab-configs.viewAny` — list page and tab visibility.
- Users with `tenant.lib-fine-slab-configs.create` — add button and store.
- Users with `tenant.lib-fine-slab-configs.view` — show/details page.
- Users with `tenant.lib-fine-slab-configs.update` — edit, update, toggle status.
- Users with `tenant.lib-fine-slab-configs.delete` — soft delete.
- Users with `tenant.lib-fine-slab-configs.restore` — trash view and restore.
- Users with `tenant.lib-fine-slab-configs.forceDelete` — permanent delete.

---

## How This Screen Works — Logic Flow (Non-Technical)
1. User goes to the Fine Slab Configuration section.
2. The system loads all slab configurations and displays them in a table with name, fine type, priority, effective dates, and active status.
3. The user can add a new configuration by clicking "Add Slab Config" and filling in the form.
4. To see the individual day-range rules inside a configuration, the user clicks "Show."
5. The show page displays the configuration details at the top and a sub-table of all slab details below.
6. When a book is returned late, the system automatically: finds the best matching active slab, calculates overdue days (minus grace period), finds the matching day range, computes the raw fine using the rate/calculation type, and caps it at the max limit.
7. The user can edit the configuration name, fine type, calculation settings, priority, effective dates, or scope filters. They can toggle its status, or delete it.
8. When deleted, the configuration and all its day-range rules are moved to the trash.
9. From the trash, the user can restore or permanently delete.

---

## Validate Before Save
1. Name is required, must be a string ≤100 characters.
2. `fine_type_id` is required and must reference an existing fine type.
3. `fine_amt_calc_type` must be one of: Fixed, Percentage, BookCost.
4. `max_fine_cap` must be one of: Fixed, BookCost, Unlimited.
5. `max_fine_amt` is required when `max_fine_cap = 'Fixed'`, otherwise must be NULL.
6. `membership_type_id` is optional; if provided, must reference an existing membership type.
7. `resource_type_id` is optional; if provided, must reference an existing resource type.
8. `effective_from` is required and must be a valid date.
9. `effective_to` is optional; if provided, must be >= `effective_from`.
10. Priority is required, must be an integer between 0 and 255.
11. Active status is a boolean flag.

---

## Error Handling and Validation Messages
| Condition | Message |
|-----------|---------|
| Name missing | "The name field is required." |
| Name too long | "The name must not be greater than 100 characters." |
| Fine type missing | "The fine type field is required." |
| Invalid calc type | "The selected fine amount calculation type is invalid." |
| Invalid max cap | "The selected maximum fine cap is invalid." |
| Max fine amt missing when cap=Fixed | "The max fine amount field is required when max fine cap is Fixed." |
| Max fine amt present when not Fixed | "The max fine amount must not be present when max fine cap is not Fixed." |
| Effective from missing | "The effective from field is required." |
| Effective to before from | "The effective to must be a date after or equal to effective from." |
| Priority out of range | "The priority must be between 0 and 255." |
| Priority missing | "The priority field is required." |
| Priority negative | "The priority must be at least 0." |

---

## Success Scenarios
1. **Create:** Valid data saved. Redirect to list with "Fine Slab Config created successfully."
2. **Update:** Modified data saved. Redirect to list with "Fine Slab Config updated successfully."
3. **Toggle Status:** AJAX request flips `is_active`. Returns `{success: true, is_active: bool}`.
4. **Show:** Configuration and its details displayed on the show page.
5. **Soft Delete:** Record and details soft-deleted. Redirect with success message.
6. **Restore:** `deleted_at` cleared, `is_active` set to true. Success message displayed.
7. **Force Delete:** Record permanently removed along with details (cascade). Success message.

---

## Failure Scenarios
1. **Create with missing required fields:** Validation fails, form re-displays with errors.
2. **Create with effective_to before effective_from:** "The effective to must be a date after or equal to effective from."
3. **Create with max_fine_amt missing when cap=Fixed:** Validation fails.
4. **Show on deleted record:** `findOrFail` on soft-deleted record throws 404 (use `withTrashed()` if needed).
5. **Restore already-active record:** No error; restored record is set active.
6. **Force delete non-existent record:** `findOrFail` throws 404.

---

## Dependencies module and tables
| Dependency | Type | Details |
|-----------|------|---------|
| `lib_fine_slab_configs` | Table | Primary table for slab configurations |
| `lib_fine_slab_details` | Table | Child table; cascade deletes on parent FK |
| `lib_fine_type` | Table | FK reference for `fine_type_id` |
| `lib_membership_types` | Table | FK reference for `membership_type_id` (nullable) |
| `lib_resource_types` | Table | FK reference for `resource_type_id` (nullable) |
| `LibFineSlabDetail` | Model | Related model with `belongsTo` back to this config |
| `lib-fine-slab-configs` | Permission | CRUD permissions defined in `permissionslist.php` |
| `LibFineSlabConfigPolicy` | Policy | Authorization policy mapped to `tenant.lib-fine-slab-configs.*` |
