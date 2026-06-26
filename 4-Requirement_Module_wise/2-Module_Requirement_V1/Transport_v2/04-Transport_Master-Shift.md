# Shift Master — Requirement Document

## 1. Screen Purpose & Overview

The Shift screen defines the active operational time and date bands during which school transport operates (e.g., Morning Shift for student arrival, Afternoon Shift for student dispersal, and Special Shift for extra-curricular events). 

Setting up shifts enables proper route scheduling, driver attendance tracking, and timing compliance audits.

---

## 2. Common Business Use Cases

1. **Configuring Morning Intake:** The administrator sets up a "Morning Intake Shift" starting at 07:00 AM and ending at 08:30 AM.
2. **Adjusting Afternoon Dispersal:** The administrator creates an "Afternoon Dispersal Shift" starting at 02:00 PM and ending at 03:30 PM.
3. **Special Exam Schedules:** Creating temporary, session-based shifts for special schedules or exams.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_shift` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `code` (VARCHAR(20)): Unique shift shorthand code (e.g., 'MS', 'AS').
* `name` (VARCHAR(100)): Unique descriptive shift name (e.g., 'Morning Shift').
* `effective_from` (DATE): Start date of the shift validity.
* `effective_to` (DATE): End date of the shift validity.
* `is_active` (TINYINT): 0 = Inactive, 1 = Active (Soft delete indicator).
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Last updated date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Shift Code** | Text Input | Required. Max 20 characters. Must be unique. | `tpt_shift.code` |
| **Shift Name** | Text Input | Required. Max 100 characters. Must be unique. | `tpt_shift.name` |
| **Effective From** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | `tpt_shift.effective_from` |
| **Effective To** | Datepicker | Required. Must be $\ge$ Effective From. | `tpt_shift.effective_to` |
| **Active Status** | Toggle / Checkbox| Required. Default is 1 (Active). | `tpt_shift.is_active` |

---

## 5. Business Logic & Validation Policies

### Uniqueness Restrictions
* The Shift Code and Shift Name must be globally unique to avoid schedule conflicts. Handled by database unique key indexes `uq_shift_code` and `uq_shift_name`.

### Date Alignment
* The effective date range validation check:
  $$\text{effective\_to} \ge \text{effective\_from}$$

### Operational Integration
* Although specific operational hours (Start/End times) are input on the front-end, they map directly to route timings on the stops level (`tpt_pickup_points_route_jnt.arrival_time` and `departure_time`). The system validates that all stop times on routes assigned to this shift fall within the shift's virtual bounds.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create a Shift (Happy Path)
1. Go to `/transport/shift` and click "+ Add Shift".
2. Enter Code: `MS26`, Name: `Morning Shift 2026`.
3. Set Effective From: Today's date, Effective To: One year from today.
4. Click Save. Confirm that the shift is registered and active in the grid.

### Test Case 2: Validate Date Bounds
1. Go to "+ Add Shift".
2. Enter Code: `FAIL`, Name: `Failing Shift`.
3. Set Effective From: Today's date, Effective To: Yesterday's date.
4. Click Save.
5. Verify that validation prevents saving: "Effective To date must be greater than or equal to Effective From date".

### Test Case 3: Duplicate Code Prevention
1. Go to "+ Add Shift".
2. Enter Code: `MS26` (same as Test Case 1), Name: `Another Morning Shift`.
3. Fill valid dates and click Save.
4. Verify validation error: "Shift Code must be unique".

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Shift Master Tab**: `@shift-master-tab`
* **Add Shift Button**: `@add-new-shift-btn`
* **Shift Code Field**: `input[name="code"]`
* **Shift Name Field**: `input[name="name"]`
* **Effective From Field**: `input[name="effective_from"]`
* **Effective To Field**: `input[name="effective_to"]`
* **Save Button**: `@save-shift-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportShiftTest extends DuskTestCase
{
    public function testShiftCreationAndValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/shift')
                    ->click('@shift-master-tab')
                    ->click('@add-new-shift-btn')
                    ->type('code', 'MS26')
                    ->type('name', 'Morning Shift 2026')
                    ->keys('input[name="effective_from"]', '05232026') // 2026-05-23
                    ->keys('input[name="effective_to"]', '05222026') // 2026-05-22 (Invalid)
                    ->click('@save-shift-btn')
                    ->assertSee('Effective To date must be greater than or equal to Effective From date')
                    
                    // Correcting date
                    ->keys('input[name="effective_to"]', '05232027')
                    ->click('@save-shift-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
