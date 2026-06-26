# Student Transport Usage Report — Requirement Document

## 1. Screen Purpose & Overview

The Student Transport Usage Report screen tracks student-specific transit histories. It provides a detailed, searchable breakdown of how many days a selected student rode the bus, their exact boarding and unboarding times, stop locations, and any tracking exceptions (e.g. missing scan alerts). 

This screen is utilized to verify student transit attendance and handle parent queries.

---

## 2. Common Business Use Cases

1. **Verifying Student Attendance:** A parent asks the school to verify that their child successfully boarded the afternoon bus on a specific date.
2. **Identifying Scanning Failures:** Auditing a student's logs to identify patterns of forgotten cards (frequent missing scans).
3. **Billing Dispute Reconciliation:** Cross-referencing active usage logs against monthly transport invoices.

---

## 3. Database Schema & Data Dictionary

The report queries data aggregated from the boarding logs and student files:

* `tpt_student_boarding_log.student_id` (INT UNSIGNED): FK to `tpt_students`.
* `tpt_student_boarding_log.trip_date` (DATE): Date of transit.
* `tpt_student_boarding_log.boarding_time` (DATETIME): Boarding check-in time.
* `tpt_student_boarding_log.boarding_stop_id` (INT UNSIGNED): Mapped pickup point.
* `tpt_student_boarding_log.unboarding_time` (DATETIME): Unboarding check-out time.
* `tpt_student_boarding_log.unboarding_stop_id` (INT UNSIGNED): Mapped drop point.
* `tpt_student_boarding_log.device_id` (INT UNSIGNED): Mapped scanning device.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Student Select** | Dropdown | Required. Searchable list of active students. | Query parameter filter. |
| **Date Range** | Date Range Picker | Required. Defaults to the last 30 days. | Query filter parameters. |
| **Export Details** | Button | Downloads student's usage ledger as PDF. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Missing Scan Validation
* The system flags a safety warning if a boarding event exists but is missing its unboarding check-out timestamp:
  $$\text{boarding\_time} \neq \text{NULL} \quad \land \quad \text{unboarding\_time} == \text{NULL}$$
  * These rows are highlighted in red in the grid and marked "Missing Checkout Alert".

### Total Trips Counter
* Total trip count is calculated as:
  $$\text{Total Trips} = \text{COUNT(tpt\_student\_boarding\_log.id) WHERE student\_id = TargetStudent}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Search Student Ride History (Happy Path)
1. Go to `/transport/transport-report` and click the **Student Transport Usage Report** tab.
2. Select Student: `Bobby`.
3. Select Date Range: From 30 days ago to Today. Click search.
4. Verify that:
   - The grid renders Bobby's daily rides.
   - Columns show Date, Trip Route, Pickup Stop, Boarding Time, Drop Stop, Unboarding Time, and Scan Status.

### Test Case 2: Verify Missing Scan Warning
1. Manually insert a row in the database where Bobby has a `boarding_time` but `unboarding_time` is NULL for yesterday.
2. Search Bobby's history on the report screen.
3. Locate yesterday's row. Verify that:
   - The row is highlighted in light red.
   - Status column displays "Missing Checkout Alert".

### Test Case 3: Export Validation
1. Click the "Export PDF" button.
2. Confirm the generated PDF document renders the same transaction table as shown on the screen.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Student Usage Tab**: `@student-usage-tab`
* **Student Select Field**: `select[name="student_id"]`
* **Date Range Field**: `input[name="date_range"]`
* **Search Button**: `@filter-report-btn`
* **Report Grid Table**: `@usage-grid-table`
* **Missing Alert Cell**: `@status-cell-missing` (displays red warnings)

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportStudentUsageReportTest extends DuskTestCase
{
    public function testStudentUsageFiltersAndWarnings()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@student-usage-tab')
                    
                    // Filter report
                    ->select('student_id', '1') // Bobby
                    ->click('@filter-report-btn')
                    ->waitFor('@usage-grid-table')
                    
                    // Assert columns render details
                    ->assertSee('Sector 22 Market Stop')
                    
                    // Assert missing checkout alert highlights
                    ->assertVisible('@status-cell-missing')
                    ->assertSeeIn('@status-cell-missing', 'Missing Checkout Alert');
        });
    }
}
```
