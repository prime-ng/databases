# Add Day Range — Requirement Document

## 1. Screen Purpose & Overview
This modal interface allows administrators and librarians to define specific overdue day range increments and their corresponding penalty rates (`lib_fine_slab_details`) linked to a parent fine configuration header. Tiers are defined sequentially (e.g., Days 1–5, Days 6–10, and Days 11+), enabling progressive overdue fee calculations.

---

## 2. Common Business Use Cases
1. **Setting up Progressive Penalty Slabs:** Defining a soft penalty for the first week, and a high deterrent fee for subsequent weeks.
   * *Slab 1:* Day 1 to 5 charged at $1.00/day.
   * *Slab 2:* Day 6 to 15 charged at $3.00/day.
   * *Slab 3:* Day 16 onwards (e.g., to 999) charged at $10.00/day.
2. **Applying Percentage-Based Penalties:** Charging a penalty that is a percentage of the book's retail price rather than a flat fee.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_fine_slab_details`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `fine_slab_config_id` | `bigint` | No | N/A | FK linking to the parent config header `lib_fine_slab_config.id`. |
| `from_day` | `unsigned int` | No | N/A | Start day of the penalty range. |
| `to_day` | `unsigned int` | No | N/A | End day of the penalty range. |
| `rate_per_day` | `decimal(10,2)` | No | N/A | Fine fee value charged per overdue day. |
| `rate_type` | `enum` | No | `'Fixed'` | Charge calculation metric. Values: `'Fixed'`, `'Percentage'`. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Update timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **From Day** | Number Input | Yes | Integer $\ge 1$. Automatically locked/pre-filled to $\text{To Day}_{prev} + 1$ (or `1` if first slab). | Pre-filled |
| **To Day** | Number Input | Yes | Integer. Must be $\ge$ **From Day**. Use large value (e.g. `9999`) for infinite upper bounds. | None |
| **Rate Type** | Radio Buttons / Select| Yes | Options: `Fixed` (flat currency), `Percentage` (of book replacement cost). | `Fixed` |
| **Daily Rate Value** | Number Input | Yes | Decimal $\ge 0.00$. If Rate Type is Percentage, must be $\le 100.00$. | `0.00` |

---

## 5. Business Logic & Validation Policies
1. **Sequence Continuity Rule:** To prevent gaps or overlaps in fine calculations, the start of any new slab range must strictly satisfy:
   $$\text{From Day}_{n} = \text{To Day}_{n-1} + 1$$
2. **No Overlapping Ranges:** Checks are enforced at database unique constraint level:
   $$\text{uk\_slab\_days} = (\text{fine\_slab\_config\_id}, \text{from\_day}, \text{to\_day})$$
   And checked dynamically during save actions:
   $$\text{Overlap} \iff \max(\text{from\_day}_{\text{new}}, \text{from\_day}_{\text{existing}}) \le \min(\text{to\_day}_{\text{new}}, \text{to\_day}_{\text{existing}})$$
3. **Percentage Bounds:** If `rate_type` is `'Percentage'`, the daily rate represents a percentage of the catalog replacement cost (`lib_book_copies.price`). It must be validated to fall in the range $[0.00, 100.00]$.
4. **Staged Changes:** During edits, day ranges are stored in a local state array and validated for continuous sequences before final submission to the backend.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` (Fine Master Tab).
* Select an existing fine config and click **"Manage Slabs"** / **"Add Day Range"**.

### Scenario A: Happy Path Create First Range
1. Open **"Add Day Range"** modal.
2. Observe that **From Day** is auto-filled to `1` and read-only.
3. Enter **To Day**: `7`.
4. Select Rate Type: `Fixed`.
5. Enter Daily Rate Value: `2.00`.
6. Click **"Save Range"**.
7. **Expected Result**: Slab is added to the config, displaying "Days 1 to 7 @ $2.00 / day".

### Scenario B: Continuity Check on Second Range
1. Click **"Add Day Range"** again.
2. Observe **From Day** is pre-filled to `8` ($\text{To Day}_{prev} + 1$).
3. Enter **To Day**: `14`.
4. Select Rate Type: `Percentage`.
5. Enter Daily Rate Value: `10.00` (meaning 10% of book price).
6. Click **"Save Range"**.
7. **Expected Result**: Slab is saved, showing "Days 8 to 14 @ 10.00% of book price / day".

### Scenario C: Boundary & Range Validation Failures
1. Click **"Add Day Range"**.
2. Observe **From Day** is pre-filled to `15`.
3. Enter **To Day**: `10` (which is less than `15`).
4. Click **"Save Range"**.
5. **Expected Result**: Validation fails, displaying: *"To Day must be greater than or equal to From Day."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Fine Slabs Manage Modal)
* **Modal Selector**: `#manage-slabs-modal`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@fine-master-tab')
            ->click('@manage-slabs-btn-1') // Open modal for first config
            ->waitFor('#manage-slabs-modal')
            ->click('@add-range-btn')
            ->type('to_day', '10')
            ->radio('rate_type', 'Fixed')
            ->type('rate_per_day', '5.00')
            ->press('@save-range-btn')
            ->assertSee('Days 1 - 10')
            ->assertSee('5.00');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@fine-master-tab')
            ->click('@manage-slabs-btn-1')
            ->waitFor('#manage-slabs-modal')
            ->click('@add-range-btn')
            ->type('to_day', '0') // Invalid value lower than From Day (1)
            ->press('@save-range-btn')
            ->assertSee('must be greater than or equal to');
});
```
