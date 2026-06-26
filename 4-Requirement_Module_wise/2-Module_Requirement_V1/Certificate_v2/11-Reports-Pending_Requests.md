# Report: Pending Requests — Requirement Document

## 1. Screen Purpose & Overview

The **Pending Requests Report** tab is a dashboard used by school administrators and final approvers (like the Principal) to track outstanding certificate applications. 

The screen highlights overdue items where the applicant's target date has passed, sorts requests by urgency, and shows how many days have elapsed since each request was submitted.

---

## 2. Common Business Use Cases

1. **Prioritizing Urgent Tasks**: The Principal opens the report at the start of the week and immediately reviews requests highlighted in red because the "Required By Date" is already past or is today.
2. **Identifying Workflow Bottlenecks**: The school admin audits the list to see which requests have been sitting in the "Under Review" or "Pending" state for more than 7 days.
3. **Weekly Status Review**: The administrative clerk exports the pending queue to discuss processing queues in weekly staff coordination meetings.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `crt_requests`, `crt_certificate_types`, `std_students`
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Field Name / Value | Source Column | Business Logic / Output |
|---|---|---|
| **Days Open** | Calculated field | Difference in days between `crt_requests.created_at` and `now()`. |
| **Urgency Level** | Calculated field | If `required_by_date < today` $\to$ **CRITICAL** (Red row styling). If difference is $\le 2$ days $\to$ **WARNING** (Yellow styling). Else $\to$ **NORMAL**. |
| **Status Badge** | `crt_requests.status` | Rendered as text badge (yellow for pending, blue for under_review). |
| **Recipient Details** | `std_students` columns | Resolves class, section, and student name. |

---

## 4. Screen Fields & Input Rules

No form input fields are required, as this is a read-only tracking list. However, sorting and simple filter options are provided:
*   **Sort Order**: Dropdown (Default: Urgency/Required By Date Ascending, Days Open Descending).
*   **Type Filter**: Dropdown to filter by Certificate Type.

---

## 5. Business Logic & Validation Policies

1. **Strict Urgency Sorting**:
   * The query must retrieve requests where `status` is in `('pending', 'under_review')` and sort them as:
     `ORDER BY required_by_date ASC, created_at ASC`.
   * Requests without a `required_by_date` are listed at the bottom of the list.
2. **Visual Alert Styling**:
   * Front-end logic checks the `required_by_date`. If the date is strictly less than the current server date (`date < now()`), apply the CSS class `bg-red-50 text-red-700 border-red-200` to the row container.
3. **Elapsed Day Calculation**:
   * The column "Days Open" calculates `created_at->diffInDays(now())` at runtime.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator/Principal.
* Ensure a request exists with `required_by_date` in the past (e.g. yesterday), and another exists with a future date.
* Navigate to `/certificate/reports/pending`.

### Scenario A: Overdue Highlight Check
1. Open the report.
2. Locate the request for `Aarav Mehta` that was required by yesterday.
3. **Expected Result**:
   * The row is highlighted with a prominent red background or red border styling.
   * An alert icon or "OVERDUE" text label is visible next to the date.

### Scenario B: Days Open Count
1. Locate a request created 5 days ago.
2. **Expected Result**: The "Days Open" column displays `5 days` exactly.

### Scenario C: Urgency Sort Order
1. Check the ordering of rows in the list.
2. **Expected Result**: 
   * The row with target date `24 May 2026` appears above target date `30 May 2026`.
   * Requests with no specified needed-by date appear at the bottom.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/reports/pending`

### 2. Overdue Styling Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/reports/pending')
            // Assert that the overdue class or styling is applied to the row containing the overdue student
            ->assertPresent('.border-red-200') // Check for overdue class styling
            ->assertSeeIn('.border-red-200', 'OVERDUE')
            ->assertSee('Aarav Mehta');
});
```

### 3. Queue Order Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/reports/pending');
    
    // Retrieve selector values for first and second rows to check sorting
    $firstRowDate = $browser->text('table tbody tr:nth-child(1) td.required-date');
    $secondRowDate = $browser->text('table tbody tr:nth-child(2) td.required-date');
    
    $this->assertTrue(strtotime($firstRowDate) <= strtotime($secondRowDate));
});
```
