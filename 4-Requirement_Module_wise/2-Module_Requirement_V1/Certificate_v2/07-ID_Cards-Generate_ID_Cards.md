# Generate ID Cards — Requirement Document

## 1. Screen Purpose & Overview

The **Generate ID Cards** tab allows administrators to filter students or staff, preview their identity cards based on configured layouts, and generate a printable grid PDF containing multiple cards per sheet. 

It also provides a handover tracking grid where office staff can log when cards are physically received by recipients.

---

## 2. Common Business Use Cases

1. **Printing New Admissions Badges**: The registrar filters by Class 1 at the start of the session, clicks Generate, and downloads a PDF containing 40 student ID cards arranged 8 per sheet over 5 pages.
2. **Missing Photo Fallback**: Generating card grids where a student has no uploaded photo. The PDF renders with a generic male/female profile placeholder rather than breaking the alignment.
3. **Tracking Handover Logs**: A student picks up their printed ID card from the front desk; the clerk searches for their name and clicks "Mark Received," logging the date and clerk's user ID.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `crt_id_card_configs` (reads configurations), Student/User tables, and a handover tracking flag.
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).
*   **Cross-Module Schema Change**:
    *   Handover status is tracked on a transactional table or as columns on `crt_id_card_configs` / student extensions. For handover, the system updates:
        *   `card_received` (boolean)
        *   `received_at` (timestamp)
        *   `received_by` (int unsigned referencing `sys_users.id` SET NULL)

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Choose Configuration**| Dropdown | Yes | Reference ID from `crt_id_card_configs`. | None |
| **Filter Class** | Dropdown | No | Choice: Active class ID (Student type only). | All Classes |
| **Section** | Dropdown | No | Choice: Active section ID (Student type only). | All Sections |
| **Staff Department** | Dropdown | No | Choice: Staff departments (Staff type only). | All Departments |

---

## 5. Business Logic & Validation Policies

1. **Blood Group Display Rule (BR-CRT-007)**:
   * The generator resolves the blood group from `std_profiles.blood_group`.
   * If it is not null, print the value (e.g. `O+`).
   * If it is null, print a blank line / label placeholder: `Blood Group: ______` (do NOT hide the field, as it allows manual writing or keeps card formats identical).
2. **Photo Resolution & Fallback**:
   * Fetch the student photo from `sys_media` where `model_type = 'StudentProfile'`. If not found, use the asset path `images/placeholder-avatar.png` encoded in base64 to avoid DomPDF external file load errors.
3. **Card Grid Sheet Render**:
   * DomPDF renders page layout containers with widths/heights mapping to standard CR80 cards. Cards are floated inside CSS grid layout structures mapped to `cards_per_sheet` (e.g. `cards_per_sheet = 8` creates a $4 \times 2$ grid on an A4 page with 10mm margins).
4. **QR Code Embed**:
   * Encodes `https://{school-domain}/verify/student/{student_uuid}` or similar string. The QR code must render as an inline base64 image.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/certificate/id-cards/generate`.

### Scenario A: Happy Path PDF Sizing
1. Select Configuration: `CR80 Landscape Student`.
2. Select Class: `Grade 6`. Click **"Preview"**.
3. Verify the grid preview matches 8 cards per page.
4. Click **"Download ID Cards PDF"**.
5. **Expected Result**: 
   * Browser triggers PDF file download.
   * Open the PDF; confirm each card contains correct student details, profile photo, and QR code.
   * Verify that student `Amit Kumar` (who has no blood group set in profile) shows `Blood Group: _____` instead of missing label or formatting alignment collapse.

### Scenario B: Tracking Handover Status
1. Navigate to `/certificate/id-cards/generate` and view the recipient list.
2. Locate student `Rahul Sharma`'s row.
3. Click the checkbox in the **"Card Handed Over"** column.
4. **Expected Result**:
   * Checkbox checks. AJAX call PATCH to `/certificate/id-cards/{id}/received` fires.
   * Toast message displays: *"Handover logged successfully."*
   * Database check: row updates `card_received = 1`, `received_at = now()`, and `received_by = auth()->id()`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/id-cards/generate`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/id-cards/generate')
            ->select('config_id', '1') // Standard Student Config
            ->select('class_id', '4') // Grade 6
            ->press('Preview ID Cards')
            ->assertSee('Aarav Mehta') // Student in class
            ->press('Download PDF')
            ->assertPathIs('/certificate/id-cards/generate');
});
```

### 3. Checkbox Handover Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/id-cards/generate')
            ->select('config_id', '1')
            ->select('class_id', '4')
            ->press('Search Recipients')
            ->waitFor('.handover-checkbox')
            ->check('.handover-checkbox') // Toggle first student
            ->waitForText('Handover logged successfully');
});
```
