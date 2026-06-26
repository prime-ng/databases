# Driver & Attendant Performance Report — Requirement Document

## 1. Screen Purpose & Overview

The Driver & Attendant Performance Report screen monitors crew attendance rates, shift compliance punctuality, and incident involvements. 

It provides administrators with a performance scorecard for each driver and helper, aiding in safety evaluations and payroll audits.

---

## 2. Common Business Use Cases

1. **Reviewing Driver Attendance Rates:** The manager checks which drivers have attendance rates below 90% in the current quarter.
2. **Auditing Late Check-ins:** Monitoring drivers who consistently clock in late for the morning intake shift.
3. **Evaluating Staff Safety Records:** Tracing incident counts to adjust driver performance bonuses.

---

## 3. Database Schema & Data Dictionary

The report aggregates data from the following tables:

* `tpt_personnel.id` (INT UNSIGNED): Primary Key.
* `tpt_personnel.name` (VARCHAR(100)): Full Name.
* `tpt_personnel.role` (VARCHAR(20)): 'Driver' or 'Helper'.
* `tpt_driver_attendance.attendance_date` (DATE): Date of attendance.
* `tpt_driver_attendance.attendance_status` (INT): Mapped check-in status.
* `tpt_driver_attendance.total_work_minutes` (INT): Total minutes worked.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Date Range** | Date Range Picker | Required. Defaults to the last 30 days. | Query filter parameters. |
| **Role Select** | Dropdown | Optional. Options: `All`, `Driver`, `Helper`. | `tpt_personnel.role` |
| **Export Report** | Button | Downloads filtered report as CSV/Excel. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Attendance Compliance Rate (%)**:
  $$\text{Compliance Rate} = \left( \frac{\text{Present Days} + \text{Half-Day} \times 0.5}{\text{Total Working Days}} \right) \times 100$$

* **Punctuality Index (%)**:
  $$\text{Punctuality} = \left( \frac{\text{Present Days} - \text{Late Days}}{\text{Present Days}} \right) \times 100$$
  * *Where Late Days* is the count of attendance logs with a status representing 'Late'.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Search Performance Scorecard (Happy Path)
1. Go to `/transport/transport-report` and click the **Driver & Attendant** tab.
2. Select Date Range: Last 30 days.
3. Select Role: `Driver`. Click search.
4. Verify that:
   - The grid loads active drivers in the fleet.
   - Column columns show: Staff Code, Name, Present Days, Late Days, Attendance Compliance Rate, and Punctuality Index.

### Test Case 2: Verify Compliance Math
1. Locate John Driver's row in the grid.
2. In the DB, count John's attendance: Total working days = 20, Present = 18, Late = 2.
3. Verify that the displayed Compliance Rate shows:
   $$\text{Compliance Rate} = \left( \frac{18}{20} \right) \times 100 = 90.00\%$$
4. Verify Punctuality Index shows:
   $$\text{Punctuality} = \left( \frac{18 - 2}{18} \right) \times 100 = 88.89\%$$

### Test Case 3: Export Validation
1. Click the "Export CSV" button.
2. Confirm the downloaded CSV file contains correct columns (Name, Present, Late, Compliance, Punctuality).

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Crew Performance Tab**: `@crew-performance-tab`
* **Role Filter Select**: `select[name="role_filter"]`
* **Date Range Field**: `input[name="date_range"]`
* **Search Button**: `@filter-report-btn`
* **Performance Grid Table**: `@performance-grid-table`
* **Compliance Cell**: `@compliance-cell-1` (dynamic row ID)

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportDriverAttendantReportTest extends DuskTestCase
{
    public function testCrewPerformanceFiltersAndMetrics()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@crew-performance-tab')
                    ->waitFor('@performance-grid-table')
                    
                    // Filter report
                    ->select('role_filter', 'Driver')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert columns render details
                    ->assertSee('John Driver')
                    ->assertVisible('@compliance-cell-1');
        });
    }
}
```
