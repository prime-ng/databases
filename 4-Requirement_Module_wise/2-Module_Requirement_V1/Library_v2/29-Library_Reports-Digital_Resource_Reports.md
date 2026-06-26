# Digital Resource Reports — Requirement Document

## 1. Screen Purpose & Overview
The Digital Resource Reports screen tracks and audits digital library asset performance. By displaying metrics like views, file downloads, active user ratios, device access details, and license expiration timelines, it helps librarians make renewal decisions and optimize digital collection services.

---

## 2. Common Business Use Cases
1. **Auditing Subscription Expiries:** Identifying eBooks or digital subscriptions expiring in the next 30 to 60 days, evaluating usage rates to decide whether to renew or cancel.
2. **Analyzing User Access Formats:** Reviewing mobile vs. desktop access ratios to check if users prefer portable reading devices.
3. **Evaluating Top Circulating Media:** Identifying high-demand audio and PDF publications to license additional concurrent user slots.

---

## 3. Database Schema & Data Dictionary
This report aggregates records from:
*   **Table Name**: `lib_digital_resources` (Digital assets metadata)
*   **Table Name**: `lib_engagement_events` (Usage transaction logs)
*   **Table Name**: `lib_members` (Patron info)

The following database fields are queried and calculated:

| Column / Field | Data Source Table | Aggregation / Operation | Description |
|---|---|---|---|
| `license_end_date` | `lib_digital_resources` | Date Comparison | Subscription expiration deadline. |
| `event_type` | `lib_engagement_events` | `COUNT()` where matched | Slices: `Digital_View`, `Digital_Download`, `Read_Online`. |
| `device_type` | `lib_engagement_events` | `COUNT()` grouping | Identifies access method (Mobile, Desktop). |
| `time_spent_seconds`| `lib_engagement_events` | `AVG()` | Time in seconds spent on digital reading. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Start Date** | Date Picker | Yes | Standard date. Defaults to today minus 30 days. | Today - 30 Days |
| **End Date** | Date Picker | Yes | Must be a date $\ge$ **Start Date**. | Today's Date |
| **License Status** | Dropdown | No | Options: `Active`, `Expiring Soon`, `Expired`. | *All Statuses* |
| **Resource Format** | Dropdown | No | Options: `PDF`, `EPUB`, `MP3`, `ZIP`. | *All Formats* |
| **Export Format** | Dropdown | Yes | Options: `PDF`, `Excel`, `Screen View`. | `Screen View` |

---

## 5. Business Logic & Validation Policies
1. **Subscription Days Remaining Formula:** Computed relative to current date:
   $$\text{Days Remaining} = \text{License End Date} - \text{Today's Date}$$
2. **License Status Classification:**
   * **Expired**: $\text{Days Remaining} < 0$.
   * **Expiring Soon**: $\text{Days Remaining} \in [0, 30]$.
   * **Due for Review**: $\text{Days Remaining} \in [31, 90]$.
   * **Active**: $\text{Days Remaining} > 90$.
3. **Renewal Action Recommendations:**
   * **RENEW NOW**: $\text{Days Remaining} < 30 \land \text{Utilization Rate} > 80\%$.
   * **Plan Renewal**: $\text{Days Remaining} < 60 \land \text{Utilization Rate} > 70\%$.
   * **Consider Discontinue**: $\text{Utilization Rate} < 40\%$ (regardless of expiration).
4. **Device Ratio Split:** Counts views by platform metadata:
   $$\text{Mobile Ratio (\%)} = \left( \frac{\text{Sessions from Mobile/Tablet}}{\text{Total Sessions}} \right) \times 100$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Library reports section `/reports/digital`.

### Scenario A: Running Digital Report (Happy Path)
1. Select Start Date: `2026-05-01`.
2. Select End Date: `2026-05-23`.
3. Keep Export Format: `Screen View`.
4. Click **"Generate Report"**.
5. **Expected Result**: Page details load correctly, displaying cards for Total Views, Total Downloads, Active Users, and License Expiry statuses. Charts populate without errors.

### Scenario B: Expiry status checking
1. Locate the **License Tracking** grid table.
2. Verify that a resource with an end date of yesterday is highlighted in red as `'Expired'`.
3. Verify that a resource with 10 days remaining and high usage indicates `'RENEW NOW'`.
4. **Expected Result**: Row statuses and recommendation triggers display correctly.

### Scenario C: Period Fallback Validation
1. Set date filters with start date = today and end date = 5 days in the past.
2. Click **"Generate Report"**.
3. **Expected Result**: Report generation is blocked, displaying: *"The end date must be a date after or equal to start date."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/reports/digital`
* **Tab/Page Selector**: `@digital-report-container`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/digital')
            ->type('start_date', '2026-05-01')
            ->type('end_date', '2026-05-23')
            ->press('@generate-btn')
            ->waitFor('@digital-summary-widgets')
            ->assertSee('Total Views')
            ->assertSee('Total Downloads');
});
```

### 3. Expiry Warning Grid Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/digital')
            ->press('@generate-btn')
            ->waitFor('@license-tracking-table')
            ->assertSee('RENEW NOW')
            ->assertSee('Expired');
});
```
