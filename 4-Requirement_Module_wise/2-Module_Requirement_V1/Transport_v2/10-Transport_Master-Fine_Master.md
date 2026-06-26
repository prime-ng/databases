# Fine Master — Requirement Document

## 1. Screen Purpose & Overview

The Fine Master screen defines the late fee rules and penalties for student transport fee payments. It enables administrators to configure tiered penalty structures based on day ranges (e.g., 1–5 days overdue vs. 6–10 days overdue) with fixed or percentage-based rates. It also manages policy options such as restricting student transport access if payments are severely delayed.

---

## 2. Common Business Use Cases

1. **Configuring Tiered Late Fees:** Defining a policy where transport fees delayed by 1 to 5 days incur a flat late fee of ₹10 per day, and delays of 6 to 15 days incur ₹20 per day.
2. **Applying a Percentage Penalty:** Configuring a 5% penalty rate on outstanding fee balances for delays exceeding 10 days.
3. **Locking Transport Access:** Enabling a student restriction policy if fees remain outstanding for more than 30 days.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_fine_master` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `std_academic_sessions_id` (INT UNSIGNED): FK to `std_student_academic_sessions` (or academic session mapping). Indicates the active session.
* `fine_from_days` (TINYINT): The start day offset for the fine tier range (e.g., 1).
* `fine_to_days` (TINYINT): The end day offset for the fine tier range (e.g., 10).
* `fine_type` (ENUM): Calculation model: 'Fixed' or 'Percentage'. Defaults to 'Fixed'.
* `fine_rate` (DECIMAL(5,2)): The financial rate (fixed monetary value or percentage amount, e.g. 10.00).
* `student_restricted` (TINYINT): 0 = Not Restricted, 1 = Restricted from using transport.
* `Remark` (VARCHAR(512)): Explanatory remark notes.
* `created_at` (TIMESTAMP): Creation date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Academic Session** | Dropdown | Required. Selects the active academic session. | `tpt_fine_master.std_academic_sessions_id` |
| **Fine From (Days)** | Number Input | Required. Integer $\ge 0$. | `tpt_fine_master.fine_from_days` |
| **Fine To (Days)** | Number Input | Required. Integer $\ge$ Fine From. | `tpt_fine_master.fine_to_days` |
| **Fine Type** | Dropdown | Required. Options: `Fixed`, `Percentage`. | `tpt_fine_master.fine_type` |
| **Fine Rate** | Number Input | Required. Decimal between $0.00$ and $999.99$. | `tpt_fine_master.fine_rate` |
| **Restrict Student** | Toggle / Checkbox| Required. Default is 0 (No). | `tpt_fine_master.student_restricted` |
| **Remarks** | Text Area | Optional. Max 512 characters. | `tpt_fine_master.Remark` |

---

## 5. Business Logic & Validation Policies

### Tier Continuity and Overlap Prevention
* The system checks that day ranges do not overlap. A new rule's day range must start after an existing range ends.
  $$\text{fine\_from\_days}_{\text{new}} > \text{fine\_to\_days}_{\text{existing}}$$
* The boundary must satisfy:
  $$\text{fine\_to\_days} \ge \text{fine\_from\_days}$$

### Late Fee Calculations
* **Fixed Mode**:
  $$\text{Calculated Fine} = \text{Late Days} \times \text{fine\_rate}$$
* **Percentage Mode**:
  $$\text{Calculated Fine} = \text{Outstanding Balance} \times \left( \frac{\text{fine\_rate}}{100} \right)$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Setup Fixed Fine Tier (Happy Path)
1. Navigate to `/transport/fine-master` and click "+ Add Fine Rule".
2. Select active Academic Session.
3. Enter Fine From: `1`, Fine To: `5` days.
4. Select Fine Type: `Fixed`, enter Rate: `10.00`.
5. Click Save. Confirm tier is registered successfully.

### Test Case 2: Validate Day Boundaries
1. Click "+ Add Fine Rule".
2. Enter Fine From: `10`, Fine To: `5` days (invalid).
3. Click Save.
4. Verify validation error: "Fine To days must be greater than or equal to Fine From days."

### Test Case 3: Overlapping Ranges Check
1. Click "+ Add Fine Rule".
2. Enter Fine From: `3`, Fine To: `7` (overlaps with 1–5 range created in Test Case 1).
3. Click Save.
4. Verify validation error: "Day range overlaps with an existing fine rule."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Fine Master Tab**: `@fine-master-tab`
* **Add Fine Rule Button**: `@add-fine-btn`
* **Session Dropdown**: `select[name="std_academic_sessions_id"]`
* **Fine From Field**: `input[name="fine_from_days"]`
* **Fine To Field**: `input[name="fine_to_days"]`
* **Fine Type Dropdown**: `select[name="fine_type"]`
* **Fine Rate Field**: `input[name="fine_rate"]`
* **Restrict Toggle**: `input[name="student_restricted"]`
* **Save Button**: `@save-fine-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportFineMasterTest extends DuskTestCase
{
    public function testFineRuleCreationAndRangeValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/fine-master')
                    ->click('@fine-master-tab')
                    ->click('@add-fine-btn')
                    ->select('std_academic_sessions_id', '1')
                    ->type('fine_from_days', '10')
                    ->type('fine_to_days', '5') // Invalid boundary
                    ->select('fine_type', 'Fixed')
                    ->type('fine_rate', '10.00')
                    ->click('@save-fine-btn')
                    ->assertSee('Fine To days must be greater than or equal to Fine From days')
                    
                    // Correcting values
                    ->type('fine_to_days', '15')
                    ->click('@save-fine-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
