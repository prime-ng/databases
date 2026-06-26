# Library Publishers — Requirement Document

## 1. Screen Purpose & Overview
Tracks publishers, contact metrics, and addresses. It acts as the supplier/source authority for identifying where books were acquired.

---

## 2. Common Business Use Cases
1. **Adding Publisher:** Registering "O'Reilly Media".
2. **Updating Details:** Updating contact email or phone number.
3. **Vendor Correspondence**: Fetching publisher details for procurement.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_publishers`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `code` | `varchar(30)` | No | N/A | Unique identifier. Has a unique DB index. |
| `name` | `varchar(200)` | No | N/A | Name of publishing house. |
| `address` | `text` | Yes | `NULL` | Physical office address. |
| `email` | `varchar(150)` | Yes | `NULL` | Contact email. Must pass format check. |
| `phone` | `varchar(20)` | Yes | `NULL` | Office line. |
| `website` | `varchar(255)` | Yes | `NULL` | Website URL. Must pass URL format check. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Publisher Code** | Text Input | Yes | Unique. Max 30 chars. Alphanumeric. E.g., `PUB-01`. | None |
| **Publisher Name** | Text Input | Yes | Max 200 chars. | None |
| **Address** | Text Area | No | Free text. | None |
| **Email** | Text Input | No | Valid RFC email structure if provided. | None |
| **Phone** | Text Input | No | Alphanumeric. Max 20 characters. | None |
| **Website** | Text Input | No | Valid URL structure if provided. | None |

---

## 5. Business Logic & Validation Policies
1. **Unique Code:** Code must be unique. Duplicate code triggers: *"The code has already been taken."*
2. **Format Validations:** Email and website fields are validated only when filled, utilizing standard regex check logic.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Publishers** tab.

### Scenario A: Happy Path Create
1. Click **"Add Publisher"**.
2. Enter Code: `PEARSON`.
3. Enter Name: `Pearson Education`.
4. Enter Website: `https://pearson.com`.
5. Enter Email: `support@pearson.com`.
6. Click **"Save"**.
7. **Expected Result**: Redirects to index, success alert displays, and `Pearson Education` appears in the listing.

### Scenario B: Validation Failures
1. Click **"Add Publisher"**.
2. Leave **Publisher Code** and **Publisher Name** blank.
3. Enter Website: `invalid-url`.
4. Enter Email: `invalid-email`.
5. Click **"Save"**.
6. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The code field is required."*
   * *"The website format is invalid."*
   * *"The email must be a valid email address."*

### Scenario C: AJAX Status Toggling
1. Toggle the active switch for `Pearson Education` in the list (if status switch is present, else verify edit saves fine).
2. **Expected Result**: AJAX request toggles status and updates DB column `is_active` without page refresh.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Publishers Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@publishers-tab')
            ->click('@add-publisher-btn')
            ->type('code', 'PUB-TEST')
            ->type('name', 'Test Publisher')
            ->type('email', 'test@pub.com')
            ->type('website', 'https://testpub.com')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-publisher-btn')
            ->type('email', 'invalid-email') // Bad email
            ->press('@save-btn')
            ->assertSee('must be a valid email');
});
```
