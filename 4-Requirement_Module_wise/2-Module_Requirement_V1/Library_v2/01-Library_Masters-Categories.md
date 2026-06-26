# Library Categories — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the hierarchical cataloging categories for library resources (e.g., `Science` -> `Physics` -> `Thermodynamics`). It allows administrators to construct, edit, and order nested structures for catalog browsing and search categorization.

---

## 2. Common Business Use Cases
1. **Adding a Root Category:** Creating a main category like "Computer Science".
2. **Nesting a Subcategory:** Creating "Software Engineering" under "Computer Science".
3. **Ordering Categories:** Adjusting the `display_order` to place high-demand categories at the top.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_categories`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `parent_category_id` | `bigint` | Yes | `NULL` | Self-referencing FK linking to `lib_categories.id`. |
| `code` | `varchar(30)` | No | N/A | Unique, short alphanumeric code. |
| `name` | `varchar(100)` | No | N/A | Descriptive category name. |
| `description` | `varchar(255)` | Yes | `NULL` | Long-form summary. |
| `display_order` | `integer` | No | `0` | Sequence sorting number. |
| `level` | `integer` | No | `1` | Generated depth hierarchy level (1 to 4). |
| `is_active` | `boolean` | No | `1` | Operational state. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Parent Category** | Dropdown | No | Optional. If selected, must exist in `lib_categories.id`. | None |
| **Category Code** | Text Input | Yes | Alphanumeric, unique. Max 30 chars. E.g., `CS-01`. | None |
| **Category Name** | Text Input | Yes | String. Max 100 chars. | None |
| **Description** | Text Area | No | Max 255 characters. | None |
| **Display Order** | Number Input | No | Integer $\ge 0$. | `0` |
| **Active Toggle** | Checkbox | No | Boolean. Present means active. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **No Self-Referencing:** A category cannot set itself or its descendants as its parent.
2. **Unique Codes:** The category code must be unique across all active categories. Bypassed on edit if unchanged.
3. **Hierarchy Cap:** System limits depth to a maximum of 4 nested levels.
4. **Category Level Calculation**:
   $$\text{Level} = \begin{cases} 1 & \text{if Parent Category is NULL} \\ \text{Parent Level} + 1 & \text{otherwise} \end{cases}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Category** tab.

### Scenario A: Happy Path Create (Root Category)
1. Click **"Add Category"**.
2. Leave **Parent Category** blank.
3. Enter Code: `COMP-SCI`.
4. Enter Name: `Computer Science`.
5. Enter Description: `Core computer science titles`.
6. Enter Display Order: `1`.
7. Click **"Save"**.
8. **Expected Result**: Redirects to index, success alert displays, and `COMP-SCI` appears in the listing with Level `1` in database.

### Scenario B: Validation Failures
1. Click **"Add Category"**.
2. Leave **Category Code** and **Category Name** blank.
3. Click **"Save"**.
4. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The code field is required."*
   * *"The name field is required."*

### Scenario C: AJAX Hierarchy Toggling & Status Updates
1. Toggle the active switch for `Computer Science` in the category list.
2. **Expected Result**: AJAX request toggles status and updates DB column `is_active` without page refresh.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Category Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@category-tab')
            ->click('@add-category-btn')
            ->type('code', 'CS-TEST')
            ->type('name', 'Test Computer Science')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-category-btn')
            ->type('code', '') // Clear required field
            ->press('@save-btn')
            ->assertSee('required');
});
```
