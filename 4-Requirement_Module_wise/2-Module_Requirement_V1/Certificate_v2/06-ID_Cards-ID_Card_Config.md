# ID Card Configuration — Requirement Document

## 1. Screen Purpose & Overview

The **ID Card Configuration** screen is a design editor interface where administrators set up layouts and template attributes for printing student or staff ID cards. 

It defines size guidelines (e.g. standard CR80 credit-card or larger A5 size), orientation, cards per sheet layouts, and a JSON configuration payload describing absolute positions, background branding images, fonts, colors, and QR code coordinates.

---

## 2. Common Business Use Cases

1. **Configuring CR80 Student Cards**: Designing a standard landscape student ID card template (CR80) with logo positions, student profile photos, blood group fields, and a QR code block.
2. **Staff Identity Badges**: Setting up a portrait CR80 layout specifically for employees, including custom fields like Employee ID, designation, and joining year.
3. **Optimizing Printing Costs**: Changing the cards-per-sheet config to print 10 cards per sheet instead of 8 to reduce cardstock paper waste.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `crt_id_card_configs`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `card_type` | `enum` | No | N/A | Target recipient type: `'student'`, `'staff'`. |
| `name` | `varchar(150)` | No | N/A | Display label for this configuration. |
| `academic_session_id` | `smallint unsigned`| No | N/A | FK referencing `sch_org_academic_sessions_jnt.id` (RESTRICT). |
| `card_size` | `enum` | No | `'cr80'` | Standard sizes: `'cr80'` (85.6x54mm), `'a5'` (148x210mm). |
| `orientation` | `enum` | No | `'portrait'` | Layout: `'portrait'`, `'landscape'`. |
| `template_json` | `json` | No | N/A | Layout coordinates map: text coordinates, fonts, QR placement. |
| `cards_per_sheet` | `tinyint unsigned`| No | `8` | Layout grids per sheet (Range: 1 to 20). |
| Standard audit cols | | | | Includes `deleted_at`. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Configuration Name** | Text Input | Yes | String. Max: 150 characters. | None |
| **Recipients** | Dropdown | Yes | Choice: Student, Staff. | Student |
| **Academic Session** | Dropdown | Yes | Reference ID from `sch_org_academic_sessions_jnt`. | Active Session |
| **Card Sizing** | Dropdown | Yes | Choice: A5, CR80. | CR80 |
| **Card Orientation** | Radio group | Yes | Choice: Portrait, Landscape. | Portrait |
| **Layout JSON Config** | Code Area | Yes | JSON format. Must contain coordinates for logo, photo, text, QR. | Basic JSON template |
| **Cards Per Sheet** | Number Input | Yes | Integer. Range: 1 to 20. | 8 |

---

## 5. Business Logic & Validation Policies

1. **JSON Layout Structure Check**:
   * The `template_json` column must pass JSON syntax validation. It must contain the keys: `photo_box`, `qr_box`, `fields_positions`. If any critical key is missing, validation fails: *"The layout configuration JSON is missing required positioning nodes."*
2. **Sheet Grid Bounds**:
   * Limit `cards_per_sheet` to range `1 - 20`. Any entry outside this returns: *"Cards per sheet must be between 1 and 20."*
3. **Session Verification**:
   * Ensures that `academic_session_id` maps to a valid record.
4. **Audit Trail**:
   * Write all database writes, updates, and soft deletions to `sys_activity_logs`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Navigate to `/certificate/id-card-config`.

### Scenario A: Happy Path Configuration Create
1. Click **"New ID Card Layout"**.
2. Enter Name: `Standard CR80 Landscape 2026`.
3. Select Card Sizing: `CR80`. Orientation: `Landscape`.
4. Choose Recipient: `Student`.
5. Enter Layout JSON Config:
   ```json
   {
     "photo_box": { "x": 10, "y": 15, "w": 25, "h": 30 },
     "qr_box": { "x": 60, "y": 15, "w": 20, "h": 20 },
     "fields_positions": { "student_name": { "x": 10, "y": 50 } }
   }
   ```
6. Set Cards Per Sheet: `8`. Click **"Save Config"**.
7. **Expected Result**:
   * Success toast appears: *"ID Card configuration saved successfully."*
   * Row appears in the configurations list.

### Scenario B: Invalid JSON Configuration
1. Click **"New ID Card Layout"**.
2. Enter layout text with broken syntax (e.g. missing double quotes or trailing commas). Click Save.
3. **Expected Result**: Validation flags the field: *"The layout configuration JSON is invalid."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/id-card-config/create`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/id-card-config/create')
            ->type('name', 'CR80 Landscape Student')
            ->select('card_type', 'student')
            ->select('academic_session_id', '1')
            ->select('card_size', 'cr80')
            ->radio('orientation', 'landscape')
            ->type('template_json', '{"photo_box":{"x":10,"y":10,"w":20,"h":20},"qr_box":{"x":50,"y":10,"w":15,"h":15},"fields_positions":{}}')
            ->type('cards_per_sheet', '8')
            ->press('Save Config')
            ->assertPathIs('/certificate/id-card-config')
            ->assertSee('saved successfully');
});
```

### 3. Cards Per Sheet Validation Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/id-card-config/create')
            ->type('cards_per_sheet', '25') // Exceeds limit of 20
            ->press('Save Config')
            ->assertSee('must be between 1 and 20');
});
```
