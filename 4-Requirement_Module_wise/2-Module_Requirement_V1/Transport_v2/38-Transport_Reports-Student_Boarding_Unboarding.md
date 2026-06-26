# Student Boarding / Unboarding Report — Requirement Document

## 1. Screen Purpose & Overview

The Student Boarding / Unboarding Report provides daily passenger attendance listings for individual trip runs. 

It lists the checkout status of all students assigned to a specific Route, Shift, and Date, enabling coordinators to instantly verify boarding compliance and safety.

---

## 2. Common Business Use Cases

1. **Verify Bus Dispersal Completeness:** At 04:30 PM, the manager reviews the Afternoon Dispersal report for Route 10 to confirm that all 40 allocated students scanned out safely at their respective stops.
2. **Investigating Missing Students:** Checking if a student who was absent from school boarded the morning bus.
3. **Auditing Scan Compliance:** Verifying total boardings vs. total unboardings on a specific trip.

---

## 3. Database Schema & Data Dictionary

The report queries data from the following tables:

* `tpt_student_boarding_log.student_id` (INT UNSIGNED): FK to `tpt_students`.
* `tpt_student_boarding_log.trip_date` (DATE): Target date.
* `tpt_student_boarding_log.boarding_trip_id` (INT UNSIGNED): FK to `tpt_trip`. Mapped trip.
* `tpt_student_boarding_log.boarding_time` (DATETIME): Boarding check-in.
* `tpt_student_boarding_log.unboarding_time` (DATETIME): Unboarding check-out.
* `tpt_student_route_allocation_jnt.student_id` (INT UNSIGNED): Allocated passenger base.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Scheduled Date** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | Query filter parameter. |
| **Shift Select** | Dropdown | Required. Matches active shifts (`tpt_shift`). | Query filter parameter. |
| **Route Select** | Dropdown | Required. Matches active routes (`tpt_route`). | Query filter parameter. |
| **Export Details** | Button | Downloads attendance ledger as Excel/PDF. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Trip Boarding Rate (%)**:
  $$\text{Boarding Rate} = \left( \frac{\text{Boarded Count}}{\text{Total Allocated Passengers}} \right) \times 100$$
  * *Where Boarded Count* is the count of records in `tpt_student_boarding_log` with a non-null `boarding_time` for the selected date, route, and shift.

* **Unboard Reconciliation Rate (%)**:
  $$\text{Unboard Rate} = \left( \frac{\text{Unboarded Count}}{\text{Boarded Count}} \right) \times 100$$
  * *Where Unboarded Count* is the count of boarded records that also have a non-null `unboarding_time`. 
  * If $\text{Unboard Rate} < 100\%$, the report highlights the trip status as "Incomplete/Warning" in yellow.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Load Trip Attendance Grid (Happy Path)
1. Go to `/transport/transport-report` and click the **Student Boarding / Unboarding** tab.
2. Select Date: Today. Select Shift: Morning Shift. Select Route: Route 10. Click search.
3. Verify that:
   - The grid loads the names of all students allocated to Route 10.
   - Column columns display: Student Name, Roll No, Boarding Status, Boarding Time, Boarding Stop, Unboarding Time, Unboarding Stop.

### Test Case 2: Verify Unboarding Warnings
1. Simulate a trip where 10 students boarded, but only 9 scanned out.
2. Load the report for this trip.
3. Verify that:
   - The summary card displays: Boarded = 10, Unboarded = 9.
   - The Unboard Reconciliation Rate is calculated as:
     $$\text{Unboard Rate} = \left( \frac{9}{10} \right) \times 100 = 90.00\%$$
   - The row for the student who skipped scanning shows "Boarded Only" highlighted in yellow.

### Test Case 3: Export Report
1. Click the "Export PDF" button.
2. Confirm the generated PDF document renders the same student list and percentages as shown on the screen.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Student Boarding Tab**: `@student-boarding-report-tab`
* **Date Field**: `input[name="scheduled_date"]`
* **Shift Select**: `select[name="shift_filter"]`
* **Route Select**: `select[name="route_filter"]`
* **Search Button**: `@filter-report-btn`
* **Report Grid Table**: `@boarding-grid-table`
* **Boarding Rate Display**: `@boarding-rate-metric`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportStudentBoardingReportTest extends DuskTestCase
{
    public function testBoardingAttendanceFiltersAndRates()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@student-boarding-report-tab')
                    ->waitFor('@boarding-grid-table')
                    
                    // Filter report
                    ->keys('input[name="scheduled_date"]', '05232026') // 2026-05-23
                    ->select('shift_filter', '1')
                    ->select('route_filter', '1')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert columns render details
                    ->assertSee('Bobby')
                    ->assertVisible('@boarding-rate-metric');
        });
    }
}
```
