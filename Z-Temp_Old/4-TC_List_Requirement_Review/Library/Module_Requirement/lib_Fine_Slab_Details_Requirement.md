# Lib Fine Slab Details — Business Requirements

## What This Screen Does
Manages the individual day-range rows within a fine slab configuration. Each detail record defines a `from_day`-`to_day` range, a `fine_rate`, a `rate_type` (Fixed or Percentage), and a `calculation_type` (Per_Day, Per_Week, Per_Month, Per_Year, or Per_Book). Together, these rows form a complete tiered late-fee structure with varying rates across day ranges. Each detail belongs to exactly one slab configuration.

---

## When This Screen Is Used
- Defining or modifying the day-range tiers within a slab configuration.
- Adding a new rate tier (e.g., adding a "Days 15-30" row with a different calculation type).
- Adjusting the rate, rate type, calculation type, or day boundaries of an existing tier.
- Deactivating a specific tier without deleting it.
- Viewing all tiers that make up a slab configuration.

## Default Data Load
- Index: Typically shown as a sub-table within the parent slab configuration's Show page, not as a standalone list. Filters by `fine_slab_config_id`.
- Create: Form with a dropdown to select the parent slab config, plus fields for `from_day`, `to_day`, `fine_rate`, `rate_type`, `calculation_type`, and active toggle.
- Edit: Pre-populated form for an existing detail record.
- Show: Read-only display of the detail record.

---

## Key Fields at a Glance
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| fine_slab_config_id | INT UNSIGNED | FK→lib_fine_slab_configs CASCADE, required | Parent slab configuration |
| from_day | INT | NOT NULL, required, min:0 | Start of day range (inclusive); can be 0 for first range |
| to_day | INT | NOT NULL, required, min:0, >= from_day | End of day range (inclusive) |
| fine_rate | DECIMAL(10,2) | DEFAULT 0.00, required, min:0 | Numeric rate value; meaning depends on rate_type |
| rate_type | VARCHAR(20) | required, in:Fixed,Percentage | Fixed = direct currency amount; Percentage = % of book's purchase cost |
| calculation_type | VARCHAR(20) | required, in:Per_Day,Per_Week,Per_Month,Per_Year,Per_Book | Unit over which the fine rate is applied |
| is_active | TINYINT(1) | DEFAULT 1, boolean | Soft on/off toggle |

---

## Business Rules and Conditions
1. **Day Range Validity:** `from_day` must be ≥ 0. `to_day` must be ≥ `from_day`. Day ranges within the same slab config must **not overlap** (e.g., if one row covers days 1–7, another row cannot start before day 8).
2. **UNIQUE KEY Enforcement:** The combination of `fine_slab_config_id` + `from_day` + `to_day` must be unique (enforced by `UNIQUE KEY uq_fineSlabDetail_ConfigId_FromDay_ToDay`). No two detail rows under the same parent can have the same day range.
3. **Fine Rate Interpretation (`fine_rate`):** The meaning of `fine_rate` depends on `rate_type`:
   - If `rate_type = 'Fixed'` → `fine_rate` is the direct amount in currency (e.g., ₹2.00 means ₹2 per calculation unit).
   - If `rate_type = 'Percentage'` → `fine_rate` is the percentage value (e.g., 10 means 10% of book's purchase cost per calculation unit).
4. **Rate Type (`rate_type`):**
   - **Fixed:** A fixed currency amount per calculation unit.
   - **Percentage:** A percentage of the book's purchase cost per calculation unit.
5. **Calculation Type (`calculation_type`):** Determines the unit over which the fine rate is applied:
   - **Per_Day:** Fine rate is multiplied by the number of overdue days.
   - **Per_Week:** Fine rate is multiplied by the number of overdue weeks (rounded up: `CEIL(overdue_days / 7)`).
   - **Per_Month:** Fine rate is multiplied by the number of overdue months (rounded up: `CEIL(overdue_days / 30)`).
   - **Per_Year:** Fine rate is multiplied by the number of overdue years (rounded up: `CEIL(overdue_days / 365)`).
   - **Per_Book:** Fine rate is a flat one-time charge regardless of how many days overdue.
6. **Parent `fine_amt_calc_type = 'BookCost'` Override:** When the parent slab config has `fine_amt_calc_type = 'BookCost'`, the raw fine equals the full `book_purchase_cost` regardless of this child table's `fine_rate`, `rate_type`, or `calculation_type`.
7. **Rate Non-Negative:** `fine_rate` must be ≥ 0. A zero rate means no fine for that day range.
8. **Cascade with Parent:** When a slab configuration is deleted, all its detail records are cascade-deleted (`ON DELETE CASCADE`).
9. **Active Flag:** Inactive detail records are excluded from fine calculation logic.
10. **Ordered Display:** Rows should be displayed ordered by `from_day` ascending to show the progression of tiers clearly.

---

## Workflow Steps
1. Admin navigates to a slab configuration's Show page.
2. The page displays existing slab details in a sub-table (from_day, to_day, fine_rate, rate_type, calculation_type, status).
3. Admin clicks "Add Detail" to open a form for a new day-range row.
4. Admin selects the parent slab config (pre-populated if accessed from context), enters from_day, to_day, fine_rate, selects rate_type (Fixed/Percentage), calculation_type (Per_Day/Per_Week/Per_Month/Per_Year/Per_Book), and toggles active status.
5. System validates: to_day >= from_day, from_day >= 0, fine_rate >= 0, rate_type and calculation_type are valid ENUMs, no day range overlap within the same slab config.
6. System saves the detail record.
7. Admin can edit any row to adjust day boundaries, rate, rate type, or calculation type.
8. Admin can toggle a row's active status.
9. Admin can delete a row (soft delete via parent or direct force delete).

---

## Example Scenario
**Building the "Standard Late Fee" slab details:**
1. Parent config "Standard Late Fee" (priority 1, fine_amt_calc_type=Fixed) already exists.
2. Admin adds detail: from_day=0, to_day=7, fine_rate=2.00, rate_type=Fixed, calculation_type=Per_Day.
3. Admin adds detail: from_day=8, to_day=30, fine_rate=5.00, rate_type=Fixed, calculation_type=Per_Day.
4. Admin adds detail: from_day=31, to_day=365, fine_rate=10.00, rate_type=Fixed, calculation_type=Per_Day.
5. When a book is 10 days overdue (after grace period), the system finds the matching range (from_day=8, to_day=30) and calculates: 10 overdue_days × ₹5.00 = ₹50.00.
6. If the library wants a weekly rate instead: calculation_type=Per_Week, fine_rate=10.00 → CEIL(10/7) × 10 = 2 × 10 = ₹20.00.
7. Day range overlap is prevented by the UNIQUE KEY on (fine_slab_config_id, from_day, to_day). Adding a range 5-15 when 8-30 already exists would be rejected.

---

## Related Screens
- **Fine Slab Config** — Parent configuration. Details are always viewed/created in the context of a parent slab.
- **Fine Calculation Engine** — Consumes slab details to compute late fines programmatically.
- **Fine Types** — Defines the fine categories referenced by the parent config.

---

## Requirements
(technical: controller, model, validation, activityLog, policy)

- **Controller:** `LibFineSlabDetailController` — Standard CRUD. The index typically scoped by `fine_slab_config_id` or shown as part of the parent's show view.
- **Model:** `LibFineSlabDetail` — table `lib_fine_slab_details`, fillable: `fine_slab_config_id`, `from_day`, `to_day`, `fine_rate`, `rate_type`, `calculation_type`, `is_active`. Relationships: `slab()` belongsTo `LibFineSlabConfig`.
- **Validation (FormRequest):** `fine_slab_config_id` => required|exists:lib_fine_slab_configs,id; `from_day` => required|integer|min:0; `to_day` => required|integer|min:0|gte:from_day; `fine_rate` => required|numeric|min:0; `rate_type` => required|in:Fixed,Percentage; `calculation_type` => required|in:Per_Day,Per_Week,Per_Month,Per_Year,Per_Book; `is_active` => boolean.
- **ActivityLog:** Must call `activityLog()` after create, update, delete, restore, forceDelete.
- **Policy:** Gate string `tenant.lib-fine-slab-details.*` mapped to `LibFineSlabDetailPolicy`.
- **Permissionslist entry:** `'lib-fine-slab-details' => $crud`

---

## Who Can Access This Screen
- Users with `tenant.lib-fine-slab-details.viewAny` — list visibility.
- Users with `tenant.lib-fine-slab-details.create` — add button and store.
- Users with `tenant.lib-fine-slab-details.view` — show/details page.
- Users with `tenant.lib-fine-slab-details.update` — edit, update, toggle status.
- Users with `tenant.lib-fine-slab-details.delete` — soft delete.
- Users with `tenant.lib-fine-slab-details.restore` — trash view and restore.
- Users with `tenant.lib-fine-slab-details.forceDelete` — permanent delete.

---

## How This Screen Works — Logic Flow (Non-Technical)
1. User views a slab configuration's show page.
2. The show page includes a sub-table of all detail rows associated with that configuration.
3. Each row shows the from-day, to-day, fine rate, rate type (Fixed/Percentage), calculation type (Per_Day/Per_Week/Per_Month/Per_Year/Per_Book), and an active status toggle.
4. The user can add a new day-range tier by clicking "Add Detail."
5. In the form, the user sets the day range boundaries, the fine rate, selects whether the rate is a fixed currency amount or a percentage, and selects how the rate is calculated (per day, per week, per month, per year, or flat per book).
6. The system checks that from_day is at least 0, to_day is the same or higher than from_day, and no overlapping day range exists within the same slab config.
7. After saving, the new tier appears in the sub-table.
8. The user can edit any tier's range, rate, rate type, or calculation type, toggle it inactive, or delete it.
9. Deleted items can be restored or permanently removed from the trash.

---

## Validate Before Save
1. `fine_slab_config_id` is required and must exist in `lib_fine_slab_configs`.
2. `from_day` is required, must be an integer ≥ 0.
3. `to_day` is required, must be an integer ≥ 0 and ≥ `from_day`.
4. `fine_rate` is required, must be a non-negative number.
5. `rate_type` is required, must be one of: Fixed, Percentage.
6. `calculation_type` is required, must be one of: Per_Day, Per_Week, Per_Month, Per_Year, Per_Book.
7. `is_active` is a boolean flag.
8. The combination of `fine_slab_config_id` + `from_day` + `to_day` must be unique within the same parent slab config (DB UNIQUE KEY enforcement).

---

## Error Handling and Validation Messages
| Condition | Message |
|-----------|---------|
| Config ID missing/invalid | "The fine slab config id field is required." or "The selected fine slab config id is invalid." |
| From day missing | "The from day field is required." |
| From day < 0 | "The from day must be at least 0." |
| From day not integer | "The from day must be an integer." |
| To day missing | "The to day field is required." |
| To day < from_day | "The to day must be greater than or equal to from day." |
| Rate missing | "The fine rate field is required." |
| Rate negative | "The fine rate must be at least 0." |
| Rate type missing | "The rate type field is required." |
| Rate type invalid | "The selected rate type is invalid." |
| Calculation type missing | "The calculation type field is required." |
| Calculation type invalid | "The selected calculation type is invalid." |
| Day range overlap | "Day range overlaps with an existing detail row in this slab config." |

---

## Success Scenarios
1. **Create:** Valid detail saved. Redirect with "Fine Slab Detail created successfully."
2. **Update:** Modified detail saved. Redirect with "Fine Slab Detail updated successfully."
3. **Toggle Status:** AJAX toggles `is_active`. Returns `{success: true, is_active: bool}`.
4. **Soft Delete:** Record soft-deleted. Success message displayed.
5. **Restore:** Record restored. Success message displayed.
6. **Force Delete:** Record permanently removed. Success message.

---

## Failure Scenarios
1. **Create with to_day < from_day:** Validation fails, "to day must be greater than or equal to from day."
2. **Create with non-existent parent config:** Validation fails with invalid exists error.
3. **Create with overlapping day range in same slab config:** DB UNIQUE KEY violation caught; user sees "Day range overlaps with an existing detail row in this slab config."
4. **Create with invalid rate_type (e.g., 'Flat'):** "The selected rate type is invalid."
5. **Create with invalid calculation_type:** "The selected calculation type is invalid."
6. **Force delete with no issues:** Normal deletion.
7. **Accessing edit on missing record:** `findOrFail` throws 404.

---

## Dependencies module and tables
| Dependency | Type | Details |
|-----------|------|---------|
| `lib_fine_slab_details` | Table | Primary table for this feature; UNIQUE KEY on (fine_slab_config_id, from_day, to_day) |
| `lib_fine_slab_configs` | Table | Parent table; FK cascade on delete |
| `LibFineSlabConfig` | Model | Parent model; each detail belongs to a slab config |
| `lib-fine-slab-details` | Permission | CRUD permissions defined in `permissionslist.php` |
| `LibFineSlabDetailPolicy` | Policy | Authorization policy mapped to `tenant.lib-fine-slab-details.*` |
