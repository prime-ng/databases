# Overdue Reports — Requirement Document

## 1. Screen Purpose & Overview
The Overdue Reports screen tracks all unreturned physical library copies whose return due dates are in the past. It groups overdue occurrences by aging severity categories (e.g. 1-7 days, 8-15 days, 16-30 days, 31-45 days, and 45+ days), projects pending penalty totals, lists frequent overdue offenders, and suggests recovery operations (reminders, warning letters, or marking items as lost).

---

## 2. Common Business Use Cases
1. **Sending Overdue Notices:** Generating a list of members with books overdue by 8-15 days to send automated reminder emails.
2. **Flagging Severe Overdues for Block actions:** Auditing members with books overdue by > 30 days to manually trigger account blocks.
3. **Evaluating Recovery Pipeline:** Inspecting how many books need to be officially retired and marked as lost (> 45 days overdue).

---

## 3. Database Schema & Data Dictionary
This report aggregates records from:
*   **Table Name**: `lib_transactions` (Circulation transactions)
*   **Table Name**: `lib_members` (Patron info)
*   **Table Name**: `lib_membership_types` (Fine rate parameters)
*   **Table Name**: `lib_book_copies` (Physical copies)

The following database fields are queried and calculated:

| Column / Field | Data Source Table | Aggregation / Operation | Description |
|---|---|---|---|
| `due_date` | `lib_transactions` | Comparison ($< \text{today}$) | Expected date of copy return. |
| `return_date` | `lib_transactions` | `IS NULL` Filter | Must be null (open checkout). |
| `fine_rate_per_day` | `lib_membership_types`| Multiplication Factor | Fine charge applied per overdue day. |
| `status` | `lib_transactions` | Filter | Status must not be `'Returned'`. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Start Date** | Date Picker | Yes | Standard date. Defaults to today minus 90 days. | Today - 90 Days |
| **End Date** | Date Picker | Yes | Must be a date $\ge$ **Start Date**. | Today's Date |
| **Overdue Range (Severity)**| Dropdown | No | Options: `1-7 days`, `8-15 days`, `16-30 days`, `31-45 days`, `45+ days`. | *All Severities* |
| **Membership Type** | Dropdown | No | Filter by target membership profile. | *All Memberships* |
| **Export Format** | Dropdown | Yes | Options: `PDF`, `Excel`, `Screen View`. | `Screen View` |

---

## 5. Business Logic & Validation Policies
1. **Overdue Aging Formula:** For any checkout with `return_date IS NULL` and `due_date < today`:
   $$\text{Days Overdue} = \text{Today's Date} - \text{Due Date}$$
2. **Projected Fine Formula:** Accumulates active daily late fees on outstanding checkouts:
   $$\text{Projected Fine} = \text{Days Overdue} \times \text{lib\_membership\_types.fine\_rate\_per\_day}$$
3. **Severity & Action Classification Rules:**
   * **1 - 7 days overdue**: Status = `'REMINDER'`. Action = *Send Gentle Reminder*.
   * **8 - 15 days overdue**: Status = `'NOTICE SENT'`. Action = *Send Firm Reminder*.
   * **16 - 30 days overdue**: Status = `'WARNING'`. Action = *Warning + Fine Notice*.
   * **31 - 45 days overdue**: Status = `'BLOCKED'`. Action = *Block Member*.
   * **45+ days overdue**: Status = `'LOST?'`. Action = *Mark as Lost*.
4. **Frequent Offenders List:** Identifies members with multiple concurrent overdue loans, sorting by cumulative overdue days descending.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Library reports section `/reports/overdue`.

### Scenario A: Loading Overdue Grid (Happy Path)
1. Select Start Date: `2026-02-01`.
2. Select End Date: `2026-05-23`.
3. Keep Export Format: `Screen View`.
4. Click **"Generate Report"**.
5. **Expected Result**: Page loads correctly, displaying cards for Total Overdue, Projected Fine Amount, and Members Affected. Detailed tables populate with member names, book titles, due dates, calculated days overdue, status labels, and action tags.

### Scenario B: Severity Range Filtering
1. Set overdue range filter to `45+ days`.
2. Click **"Generate Report"**.
3. **Expected Result**: Listing filters down, showing only copies overdue by more than 45 days. Action tag displays in red as "Mark Lost".

### Scenario C: Projected Fine Calibration Check
1. Locate a member with a book overdue by 10 days in the report details.
2. Verify the projected fine matches: 10 days $\times$ $5.00/day fine rate = $50.00.
3. **Expected Result**: Fine projection details align precisely with the member's profile limits.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/reports/overdue`
* **Tab/Page Selector**: `@overdue-report-container`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/overdue')
            ->type('start_date', '2026-02-01')
            ->type('end_date', '2026-05-23')
            ->press('@generate-btn')
            ->waitFor('@overdue-grid-details')
            ->assertSee('Total Overdue')
            ->assertSee('Projected Fine Amount');
});
```

### 3. Severity Filter Verification Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/overdue')
            ->select('overdue_range', '45+')
            ->press('@generate-btn')
            ->waitFor('@overdue-grid-details')
            ->assertSee('LOST?')
            ->assertSee('Mark Lost');
});
```
