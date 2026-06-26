# Certificate Types — Requirement Document

## 1. Screen Purpose & Overview

The **Certificate Types** screen is a configuration interface where administrators define the different types of certificates issued by the institution (e.g., Bonafide, Transfer Certificate, Achievement Certificate, Character Certificate). 

By setting up these types, administrators define core behaviors such as approval requirements, validity durations, and the structure of generated certificate numbers, which the application uses during generation workflows.

---

## 2. Common Business Use Cases

1. **Setting up Legal Certs**: Registering a `Transfer Certificate` with code `TC`, setting `requires_approval = true`, and format `{TYPE_CODE}-{YYYY}-{SEQ4}`.
2. **Setting up Achievement Certs**: Creating a `Merit Certificate` with code `MERIT`, setting `requires_approval = false` so that physical copies can be generated instantly.
3. **Deactivating Old Configurations**: Deactivating a type like `Covid-19 Vaccination Clearance` when it is no longer needed, without deleting historic records.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `crt_certificate_types`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `name` | `varchar(150)` | No | N/A | Display name of the certificate type. |
| `code` | `varchar(10)` | No | N/A | Unique short code. Has a unique DB index. |
| `category` | `enum` | No | N/A | Category: `'administrative'`, `'legal'`, `'character'`, `'achievement'`, `'identity'`. |
| `requires_approval`| `tinyint(1)` | No | `1` | If true, requests require manual approval. If false, they are auto-approved. |
| `validity_days` | `smallint unsigned`| Yes | `NULL` | Number of days the certificate is valid. `NULL` means no expiry. |
| `serial_format` | `varchar(100)` | No | N/A | Format tokens: `{TYPE_CODE}`, `{YYYY}`, `{YY}`, `{SEQ4}`, `{SEQ6}`. |
| `description` | `text` | Yes | `NULL` | Internal explanation of the certificate type. |
| `is_active` | `tinyint(1)` | No | `1` | Operational status. Inactive types cannot be requested in portals. |
| `created_by` | `int unsigned` | Yes | `NULL` | Creator reference (`sys_users.id`). |
| `updated_by` | `int unsigned` | Yes | `NULL` | Updater reference (`sys_users.id`). |
| `created_at` | `timestamp` | Yes | `NULL` | Timestamp of creation. |
| `updated_at` | `timestamp` | Yes | `NULL` | Timestamp of last modification. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Type Name** | Text Input | Yes | String. Max: 150 characters. | None |
| **Short Code** | Text Input | Yes | Alphanumeric. Max: 10 characters. Must be unique in `crt_certificate_types` (case-insensitive). | None |
| **Category** | Dropdown | Yes | Choice: Administrative, Legal, Character, Achievement, Identity. | Administrative |
| **Requires Approval** | Checkbox | No | Boolean. Checked = true (`1`), unchecked = false (`0`). | Checked (True) |
| **Validity (Days)** | Number Input | No | Integer. Minimum: 1. Nullable. | None (No Expiry) |
| **Serial Number Format** | Text Input | Yes | String. Max: 100 characters. Must contain at least one sequence token (`{SEQ4}` or `{SEQ6}`). | `{TYPE_CODE}-{YYYY}-{SEQ6}` |
| **Description** | Text Area | No | Text. Max: 1000 characters. | None |
| **Active Status** | Checkbox | No | Boolean. Checked = true (`1`), unchecked = false (`0`). | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Uniqueness Constraints**:
   * **On Create/Update**: The `code` must not exist in `crt_certificate_types` (excluding soft-deleted records). If duplicate, fails validation with: *"The certificate type code has already been taken."*
2. **Serial Format Checks**:
   * Must contain either `{SEQ4}` or `{SEQ6}`. If both are absent or if syntax is broken, returns: *"The serial number format must contain a sequence placeholder ({SEQ4} or {SEQ6})."*
3. **Hard Delete Restriction**:
   * If a type has issued certificates in `crt_issued_certificates`, database foreign keys prevent hard deletion (`RESTRICT`). Soft deletion is allowed.
4. **Audit Logging**:
   * All writes (create, update, toggle is_active, delete, restore) must write an audit record to `sys_activity_logs`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/certificate/types`.

### Scenario A: Happy Path Create
1. Click **"Add New Certificate Type"**.
2. Enter Name: `Bonafide Certificate`.
3. Enter Code: `BON`.
4. Select Category: `Administrative`.
5. Keep "Requires Approval" checked.
6. Enter Serial Number Format: `{TYPE_CODE}-{YYYY}-{SEQ6}`.
7. Click **"Save Certificate Type"** (Submit).
8. **Expected Result**: 
   * Redirects to index page.
   * Toast message: *"Certificate Type saved successfully."*
   * Row `BON` appears active in the list.

### Scenario B: Validation Failures
1. Click **"Add New Certificate Type"**.
2. Enter Name: `Bonafide` and Code: `BON` (duplicate).
3. Click Submit.
4. **Expected Result**: Form rejects with error: *"The certificate type code has already been taken."*

### Scenario C: AJAX Status Toggle
1. Locate `BON` in the types listing.
2. Click the active toggle switch.
3. **Expected Result**: Switch toggles off. AJAX PATCH request to `/certificate/types/{id}/toggle` returns success. Database status flips `is_active = 0`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/types`
* **Create Route**: `/certificate/types/create`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/types/create')
            ->type('name', 'Bonafide Certificate')
            ->type('code', 'BON')
            ->select('category', 'administrative')
            ->check('requires_approval')
            ->type('serial_format', '{TYPE_CODE}-{YYYY}-{SEQ6}')
            ->press('Save Certificate Type')
            ->assertPathIs('/certificate/types')
            ->assertSee('saved successfully');
});
```

### 3. Duplicate Validation Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/types/create')
            ->type('name', 'Duplicate Certificate')
            ->type('code', 'BON') // Existing code
            ->press('Save Certificate Type')
            ->assertPathIs('/certificate/types/create')
            ->assertSee('already been taken');
});
```
