# Fine Master List — Requirement Document

## 1. Screen Purpose & Overview
The Fine Master List screen displays all fine configuration records (`lib_fine_slab_config`). It provides administrators and librarians with a dashboard to audit active, inactive, and scheduled late-return penalty structures, check rules by precedence priority, and filter configurations by scoping parameters (such as membership types or resource types).

---

## 2. Common Business Use Cases
1. **Auditing Active Rules:** Reviewing which penalty slabs are currently operational based on the current date, to ensure fees are computed correctly.
2. **Prioritizing Conflict Slabs:** Auditing the priority integers to ensure custom rules (e.g., *VIP Student Overdue*) override standard fallback configs.
3. **Navigating to Details:** Transitioning from the high-level configuration table to edit the specific day ranges (slabs) or the main config details.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_fine_slab_config`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `name` | `varchar(100)` | No | N/A | Name of the slab configuration (e.g., *Standard Student Slab*). |
| `membership_type_id` | `bigint` | Yes | `NULL` | Scoping criteria. FK to `lib_membership_types.id`. |
| `resource_type_id` | `bigint` | Yes | `NULL` | Scoping criteria. FK to `lib_resource_types.id`. |
| `fine_type` | `enum` | No | `'Late Return'` | Values: `'Late Return'`, `'Lost Book'`, `'Damaged Book'`, `'Processing Fee'`. |
| `max_fine_amount` | `decimal(10,2)` | Yes | `NULL` | Maximum fine cap. |
| `max_fine_type` | `enum` | No | `'Unlimited'` | Values: `'Fixed'`, `'BookCost'`, `'Unlimited'`. |
| `is_active` | `boolean` | No | `1` | Manual operational state toggle. |
| `effective_from` | `date` | No | N/A | Start date for rule validity. |
| `effective_to` | `date` | Yes | `NULL` | End date for rule validity. |
| `priority` | `integer` | No | `0` | Sequence priority. Higher values evaluated first. |
| `created_at` | `timestamp` | Yes | `NULL` | Record creation date. |
| `updated_at` | `timestamp` | Yes | `NULL` | Record modification date. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Search Config** | Text Input | No | Optional. Filters list by partial string matching on name. | None |
| **Status Filter** | Dropdown | No | Choice of: *All*, *Active*, *Inactive*, *Expired*. | *All* |
| **Membership Type Scope**| Dropdown | No | Filter by target membership profile (e.g. *Student*, *Faculty*). | *All* |
| **Resource Type Scope** | Dropdown | No | Filter by target catalog resource type (e.g. *Reference Book*). | *All* |

---

## 5. Business Logic & Validation Policies
1. **Rule Precedence Calculation:** When the system calculates fines for a transaction, it evaluates matching configs based on:
   $$\text{Precedence} = \text{Order by } \texttt{priority} \text{ DESC, } \texttt{effective\_from} \text{ DESC}$$
2. **Scoping Match Rules:** A transaction matches a configuration if:
   * The member's membership type matches `membership_type_id` (or `membership_type_id` is NULL).
   * The copy's resource type matches `resource_type_id` (or `resource_type_id` is NULL).
3. **Automated Status Labeling:** On-screen status badges are derived dynamically:
   * **Active**: `is_active = 1` AND current date is between `effective_from` and `effective_to` (inclusive).
   * **Expired**: `is_active = 1` AND current date is after `effective_to`.
   * **Inactive**: `is_active = 0`.
4. **Tenant Isolation:** All queries strictly filter configurations by the tenant context to ensure separate data.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and select the **Fine Master** tab.

### Scenario A: Initial Grid Load & List Verification
1. Open the page and click the **Fine Master** tab.
2. Verify that the table columns list: Config Name, Scope (Membership/Resource), Fine Type, Date Limits, Priority, and Status.
3. Check if priority values are ordered descending.
4. **Expected Result**: Configurations load successfully, displaying correct active/expired/inactive status badges corresponding to the current system date.

### Scenario B: Filtering Slabs
1. In the search box, type `Standard Student`.
2. Choose "Active" from the Status Filter dropdown.
3. Choose "Student" from the Membership Type dropdown.
4. **Expected Result**: The grid automatically filters rows via AJAX or page reload, showing only matching active configs.

### Scenario C: Soft-Delete Fine Config
1. Locate a custom fine configuration row.
2. Click the **"Delete"** button.
3. Confirm the modal prompt.
4. **Expected Result**: The record is soft-deleted, vanishes from the default active list, and cannot be selected for any future transactions.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Fine Master Tab)
* **Tab Selector**: `@fine-master-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@fine-master-tab')
            ->assertVisible('@fine-master-grid')
            ->type('@fine-search-input', 'Standard Student')
            ->pause(500)
            ->assertSee('Standard Student Fine Slab');
});
```

### 3. Verification of Priority Ordering Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@fine-master-tab')
            // Assert that higher priority rows are displayed first
            ->assertSourceHas('@priority-badge');
});
```
