# Add/Edit Fine Master — Requirement Document

## 1. Screen Purpose & Overview
This screen allows administrators and librarians to create and edit fine slab configuration headers (`lib_fine_slab_config`). It sets the general scoping filters (such as target membership profiles or resource types), fine types, maximum penalty caps (fixed limits vs. book cost limits), priority ordering, and effective date periods.

---

## 2. Common Business Use Cases
1. **Defining a New Penalty Scheme:** Creating a scheme named "VIP Member Late Return" with higher priority to override general rules.
2. **Applying Penalty Caps:** Restricting maximum late fees on standard novels to not exceed the price of the book (`max_fine_type = 'BookCost'`) or a fixed amount (`max_fine_type = 'Fixed'`).
3. **Setting Temporary Holiday Rules:** Setting up rules with an active date range (`effective_from` to `effective_to`) for holiday periods.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_fine_slab_config`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `name` | `varchar(100)` | No | N/A | Unique descriptive config name. |
| `membership_type_id` | `bigint` | Yes | `NULL` | Scoping filter. FK to `lib_membership_types.id`. |
| `resource_type_id` | `bigint` | Yes | `NULL` | Scoping filter. FK to `lib_resource_types.id`. |
| `fine_type` | `enum` | No | `'Late Return'` | Values: `'Late Return'`, `'Lost Book'`, `'Damaged Book'`, `'Processing Fee'`. |
| `max_fine_amount` | `decimal(10,2)` | Yes | `NULL` | Cap limit value. Required only if `max_fine_type` is `'Fixed'`. |
| `max_fine_type` | `enum` | No | `'Unlimited'` | Values: `'Fixed'`, `'BookCost'`, `'Unlimited'`. |
| `is_active` | `boolean` | No | `1` | Operational state. |
| `effective_from` | `date` | No | N/A | Rule start date. |
| `effective_to` | `date` | Yes | `NULL` | Rule end date. |
| `priority` | `integer` | No | `0` | Evaluated descending. Higher priority overrides lower. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Slab Name** | Text Input | Yes | Unique. Max 100 characters. | None |
| **Membership Type** | Dropdown | No | Select from active membership types. If blank, applies to all. | *All Memberships* |
| **Resource Type** | Dropdown | No | Select from active resource types. If blank, applies to all. | *All Resources* |
| **Fine Type** | Dropdown | Yes | Choice of: `Late Return`, `Lost Book`, `Damaged Book`, `Processing Fee`. | `Late Return` |
| **Max Cap Type** | Radio Buttons | Yes | Options: `Fixed`, `BookCost`, `Unlimited`. | `Unlimited` |
| **Max Fine Amount (Cap)**| Number Input | Conditional| Required if **Max Cap Type** is `Fixed`. Must be a decimal $\ge 0$. | None |
| **Priority** | Number Input | Yes | Integer $\ge 0$. High-priority slabs take precedence. | `0` |
| **Effective From** | Date Picker | Yes | Standard date. Must be $\ge$ today's date for new records. | Today's Date |
| **Effective To** | Date Picker | No | Optional. If provided, must be $\ge$ **Effective From**. | None |
| **Active Toggle** | Checkbox | No | Boolean. Present means active. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **Uniqueness:** The configuration `name` must be unique across all active config records.
2. **Date Alignment:** `effective_to` must be chronologically after or equal to `effective_from`.
3. **Cap Policy Calculation:** During checkout calculations, the maximum cap is applied to the accumulated day-range penalties as follows:
   $$\text{Final Fine} = \begin{cases} \min(\text{Accumulated Fine}, \text{max\_fine\_amount}) & \text{if max\_fine\_type is 'Fixed'} \\ \min(\text{Accumulated Fine}, \text{Book Copy Cost}) & \text{if max\_fine\_type is 'BookCost'} \\ \text{Accumulated Fine} & \text{if max\_fine\_type is 'Unlimited'} \end{cases}$$
4. **Overlapping Validation Warn:** If another active config contains the exact same combination of (`membership_type_id`, `resource_type_id`, `fine_type`) and its date ranges overlap with the new/edited record, the system must warn the operator (or throw a validation error if priorities are equal) to prevent deterministic execution conflicts.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the `/library-mgt/masters` (Fine Master Tab).
* Click **"Add Fine Config"** to open the creation form.

### Scenario A: Happy Path Create (Fixed Cap Scheme)
1. Enter Slab Name: `Standard Student Overdue`.
2. Select Membership Type: `Standard Student`.
3. Select Resource Type: `Book`.
4. Choose Fine Type: `Late Return`.
5. Select Max Cap Type: `Fixed`.
6. Enter Max Fine Amount: `150.00`.
7. Set Priority: `10`.
8. Set Effective From to today's date.
9. Leave Effective To blank.
10. Click **"Save"**.
11. **Expected Result**: Configuration is successfully saved, redirects to the list, showing `Standard Student Overdue` with a Priority of `10`.

### Scenario B: Validation Failures (Invalid Date Limits)
1. Open the form.
2. Enter Slab Name: `Invalid Date Slab`.
3. Select Max Cap Type: `Fixed` but leave Max Fine Amount blank.
4. Set Effective From to today.
5. Set Effective To to yesterday.
6. Click **"Save"**.
7. **Expected Result**: Submission fails. The following form fields highlight:
   * *"The max fine amount field is required when max fine type is Fixed."*
   * *"The effective to date must be a date after or equal to effective from."*

### Scenario C: Overlapping Checks
1. Attempt to add a second configuration named `Duplicate Student Overdue` with:
   * Membership Type: `Standard Student`
   * Resource Type: `Book`
   * Fine Type: `Late Return`
   * Priority: `10` (Same as standard)
   * Effective From: Today
2. Click **"Save"**.
3. **Expected Result**: System rejects the edit/creation because an identical scope & priority config already operates in this timeframe. It displays: *"An active configuration with matching criteria and identical priority already exists for this period."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Fine Master Add View)
* **Tab Selector**: `@fine-master-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@fine-master-tab')
            ->click('@add-fine-config-btn')
            ->type('name', 'Dusk Test Fine Slab')
            ->select('membership_type_id', $this->studentMembershipType->id)
            ->select('resource_type_id', $this->bookResourceType->id)
            ->select('fine_type', 'Late Return')
            ->radio('max_fine_type', 'Unlimited')
            ->type('priority', '15')
            ->type('effective_from', '2026-05-23')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@fine-master-tab')
            ->click('@add-fine-config-btn')
            ->radio('max_fine_type', 'Fixed')
            ->type('max_fine_amount', '') // Leave blank
            ->press('@save-btn')
            ->assertSee('The max fine amount field is required when');
});
```
