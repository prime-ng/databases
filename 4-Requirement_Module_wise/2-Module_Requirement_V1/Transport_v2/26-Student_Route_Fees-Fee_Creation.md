# Fee Creation — Requirement Document

## 1. Screen Purpose & Overview

The Fee Creation screen is an automated billing processor run monthly by school accountants. It scans active student transport allocations (`tpt_student_route_allocation_jnt`), retrieves stop-specific fares, and generates monthly transport fee records for all allocated students in bulk. 

This establishes outstanding student payment liabilities in the ledger.

---

## 2. Common Business Use Cases

1. **Bulk Monthly Invoicing:** Generating monthly transport fee invoices for all active transport students for the month of May 2026.
2. **Billing Recalculation:** Re-running invoice generation for a specific route after route stops or fare settings have been adjusted mid-month.
3. **Audit Log Generation:** Confirming the total transport bill liability created for the institutional cohort.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_student_fee_detail` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `std_academic_sessions_id` (INT UNSIGNED): FK to `std_student_academic_sessions`. Active academic year session link.
* `month` (DATE): Target billing month (stored as date representing first day of billing month, e.g. '2026-05-01').
* `amount` (DECIMAL(10,2)): Base transport allocation monthly fee.
* `fine_amount` (DECIMAL(10,2)): Total calculated late payment fines. Defaults to 0.00.
* `total_amount` (DECIMAL(10,2)): Total payable outstanding amount.
* `due_date` (DATE): Payment deadline date.
* `Remark` (VARCHAR(512)): Operational notes (e.g. 'Auto-generated invoice').
* `status` (VARCHAR(20)): Payment collection status ('Pending', 'Paid', 'Partially-Paid'). Defaults to 'Pending'.
* `created_at` (TIMESTAMP): Creation date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Academic Session** | Dropdown | Required. Matches active session ID. | `std_academic_sessions_id` |
| **Billing Month** | Dropdown | Required. Target month selection. | `month` (first day of select month) |
| **Due Date** | Datepicker | Required. Must be a future date $\ge$ `month`. | `due_date` |
| **Route Filter** | Dropdown | Optional. Filters generation to specific route. | Query filter parameter. |
| **Remarks** | Text Area | Optional. Max 512 characters. | `Remark` |

---

## 5. Business Logic & Validation Policies

### Double Billing Lock
* The system checks that a student does not receive duplicate invoices for the same calendar month:
  $$\text{COUNT(tpt\_student\_fee\_detail.id) WHERE student\_id = Bobby AND month = '2026-05-01'} == 0$$

### Financial Calculations
* **Total Payable Amount**:
  $$\text{total\_amount} = \text{amount} + \text{fine\_amount}$$
  * *Where amount* is the student's base monthly allocation fare.
  * *Where fine\_amount* defaults to `0.00` on creation, and is recalculated daily once the date exceeds the `due_date` using policies in `tpt_student_fine_detail`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Bulk Fee Generation (Happy Path)
1. Go to `/transport/fee-master` and select the **Fee Creation** tab.
2. Select Academic Session: `2026-2027`.
3. Select Billing Month: `May 2026`.
4. Enter Due Date: `2026-05-10`. Click **Generate Invoices**.
5. Verify:
   - A confirmation dialog displays: "Generated 145 student invoices successfully."
   - Go to student ledger; confirm Bobby has an invoice for `amount = 1800.00`, `due_date = 2026-05-10`, and status `Pending`.

### Test Case 2: Validate Due Date Bounds
1. Go to the Fee Creation form.
2. Set Billing Month: `May 2026` (stored as `2026-05-01`).
3. Set Due Date to `2026-04-20` (before billing month starts).
4. Click Generate.
5. Verify validation error: "Due Date must be equal to or greater than the Billing Month start date."

### Test Case 3: Block Re-Generation / Duplicate Invoice
1. Run invoice generation for `May 2026` again using the same parameters as Test Case 1.
2. Click Generate.
3. Verify the system ignores existing matches and generates invoices only for newly allocated students, showing message: "Invoices already exist for most students. Generated 0 new invoices."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Fee Creation Tab**: `@fee-creation-tab`
* **Session Select**: `select[name="std_academic_sessions_id"]`
* **Month Select**: `select[name="billing_month"]`
* **Due Date Field**: `input[name="due_date"]`
* **Generate Button**: `@generate-invoices-btn`
* **Results Notification**: `@generation-alert`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportFeeCreationTest extends DuskTestCase
{
    public function testMonthlyFeeGenerationAndDeadlines()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/fee-master')
                    ->click('@fee-creation-tab')
                    
                    // Invalid Date Check
                    ->select('std_academic_sessions_id', '1')
                    ->select('billing_month', '2026-05-01')
                    ->keys('input[name="due_date"]', '04202026') // 2026-04-20
                    ->click('@generate-invoices-btn')
                    ->assertSee('Due Date must be equal to or greater than the Billing Month')
                    
                    // Correcting Due Date
                    ->keys('input[name="due_date"]', '05102026') // 2026-05-10
                    ->click('@generate-invoices-btn')
                    ->waitFor('@generation-alert')
                    ->assertSee('Generated invoices successfully');
        });
    }
}
```
