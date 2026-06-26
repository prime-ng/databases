# ID Card Generation — Requirements

## What It Does
Generates printable employee ID cards using configurable templates. Supports custom layout JSON with QR codes containing employee verification data. Uses DomPDF for PDF generation. Default template system with ability to set one template as default.

Features:
- QR code embedding with employee verification data
- Customizable layout via JSON configuration
- Default template fallback
- DomPDF-based PDF download
- Photo, name, designation, department display

## Database Fields

**hrs_id_card_templates**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(255) | Required. Template display name. |
| `layout_json` | JSON | Stores card layout configuration: element positions, colors, fonts, logos. Cast to array. |
| `is_default` | BOOLEAN | Default false. Only one template can be default. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Default Template Logic**
- Only one template can have `is_default = true` at any time
- Setting a new template as default unsets the previous default
- If no default exists, the first active template is used as fallback
- Non-active templates cannot be set as default

**QR Code Data Structure**
- Generated per employee
- Contains: employee ID, employee code, name, designation
- QR code is rendered as an embedded image in the PDF
- Scanning the QR code redirects to the employee's public profile (if available)

**Card Data Preparation**
- `IdCardService::prepareCardData()` collects:
  - Employee photo (from sys_media or default avatar)
  - Employee name, employee code
  - Designation (from `SchDesignation`)
  - Department (from `SchDepartment`)
  - Blood group (if stored)
  - Date of joining
  - Emergency contact number

**PDF Generation**
- Uses DomPDF library
- Card dimensions: standard credit card size (85.6mm × 54mm) or custom
- Output: downloadable PDF, inline browser view
- Single employee per page or multiple cards per page (configurable)

## CRUD Operations

**Show ID Card**
- Renders a preview of the ID card using the default template
- Shows card front with photo, name, designation
- Option to switch template via dropdown (AJAX preview refresh)

**Generate / Download ID Card (PDF)**
- Generates a PDF using DomPDF with the selected template
- Includes QR code, photo, employee details
- Downloads as `IDCard_{emp_code}.pdf`

## Permissions

| Operation | Permission Key |
|---|---|
| View ID card | `hrs.employment.manage` |
| Generate ID card PDF | `hrs.employment.manage` |
