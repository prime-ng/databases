# ID Card — Business Requirements

## What This Screen Does

The ID Card screen displays a preview of the employee's identity card based on the configured template and allows authorised users to generate a downloadable PDF version. The ID card includes the employee's name, employee code, designation, department, photo, and a QR code containing their employee identifier.

## When This Screen Is Used

- When an employee wants to view or download their own ID card
- When HR Manager needs to generate physical ID cards for new staff members
- When an employee needs a digital copy of their ID card for verification purposes
- When the school issues re-printed ID cards with updated details

## Default Data Load

The screen is loaded by `IdCardController::show()` under the Employee → ID Card tab. The route `GET /hr-staff/employees/{employee}/id-card` renders a preview of the ID card. The controller calls `IdCardService::getTemplate()` to get the default active template and `IdCardService::prepareCardData($employee)` to assemble employee data. If no default template exists, the preview still loads but the PDF generation step returns a 404.

## Key Fields at a Glance

**Employee Identity Information**
- `full_name` — Employee's full name from the `sch_employees` record
- `emp_code` — Unique employee code (e.g., EMP/2025/001)
- `designation` — Employee's current job title/role from their active profile
- `department` — Employee's current department from their active profile
- `photo_url` — URL to the employee's profile photo

**Template Elements**
- `layout_json` — JSON configuration defining fields list, card dimensions, and color scheme from the selected template
- `qr_data` — QR code data string (employee code or fallback "EMP-{id}")

## Business Rules and Conditions

**Own Record Viewing.** An employee can view their own ID card preview without the `hrs.idcard.generate` permission. The controller checks if the authenticated user's employee ID matches the target employee ID.

**Permission Required for Others.** Viewing or generating an ID card for any employee other than yourself requires the `hrs.idcard.generate` permission.

**Default Template Required for PDF Generation.** The `generate()` endpoint fetches the default active template via `IdCardService::getTemplate()`. If no default template is found (or no active templates exist), the method aborts with 404 "No ID card template configured."

**QR Code Generation.** The ID card QR code data is generated from the employee code, or falls back to "EMP-{employee_id}" if no employee code is set.

**Profile Data Loading.** The service eager-loads `activeEmployeeProfile` (with department and role) and `activeTeacherProfile` (with department and role), then uses `current_profile` to derive designation and department. If no profile exists, placeholder "—" is shown.

**PDF Dimensions.** The generated PDF uses a custom paper size of 85.6mm × 53.98mm (standard credit card dimensions), set in points as `[0, 0, 242.65, 153.01]`.

## Workflow Steps

**Viewing ID Card Preview**
1. User navigates to Employee → ID Card tab
2. If self-service, no gate check; for other employees, gates for `hrs.idcard.generate`
3. System loads the default template and prepares card data (name, code, designation, department, photo)
4. System renders the preview view showing the card layout with employee details

**Generating ID Card PDF**
1. User clicks "Download PDF" on the ID Card preview
2. System gates for `hrs.idcard.generate`
3. System loads the default template; aborts with 404 if none configured
4. System prepares card data, renders the PDF view
5. System logs activity "ID card generated." with employee_id
6. System returns the PDF as a downloadable response with filename `id-card-{emp_code}.pdf`

## Example Scenario

Mr Verma (HR Manager) opens ID Card tab for teacher ID 5 (emp_code = "EMP/2025/012"). The system shows a preview with the employee's photo, name "Priya Sharma", code "EMP/2025/012", designation "Teacher", department "Science". He clicks "Download PDF" — the system generates a DomPDF document sized as a credit card and returns it as `id-card-EMP-2025-012.pdf`. The QR code on the card encodes "EMP/2025/012".

## Related Screens

- **Employee Profile (SchoolSetup)** — Parent employee record; ID Card is a sub-tab
- **ID Card Templates (HR Masters)** — Template configuration used for ID card layout and styling
- **Employee Profile** — Source of photo, designation, and department data

## Requirements

- `IdCardController` handles requests with methods: `show()` (lines 22–34), `generate()` (lines 39–57)
- `show()` loads template via `IdCardService::getTemplate()` and card data via `IdCardService::prepareCardData($employee)`
- `generate()` additionally renders PDF via `Barryvdh\DomPDF\Facade\Pdf::loadView()` with custom paper size `[0, 0, 242.65, 153.01]` and returns download response `$pdf->download("id-card-{$employee->emp_code}.pdf")`
- `IdCardService::getTemplate(bool $default = true)` — returns the first default active template, or if `$default=false`, the first active template irrespective of default flag
- `IdCardService::prepareCardData($employee)` — eager-loads profile relations, returns array with name, emp_code, designation, department, photo_url, qr_data
- `IdCardService::getQrData($employee)` — returns `$employee->emp_code ?? 'EMP-' . $employee->id`
- Route names: `hr-staff.id-card.show` (GET), `hr-staff.id-card.generate` (POST)
- `show()` gate: if not own record, requires `hrs.idcard.generate`; `generate()` gate: always requires `hrs.idcard.generate`
- Activity logged on generate (type 'Generated') with message "ID card generated." and employee_id

## Who Can Access

| Gate/Permission | Methods | Notes |
|-----------------|---------|-------|
| `hrs.idcard.generate` | `show()` (for others), `generate()` | Required for generating PDF and viewing others' cards |
| Own record (employee viewing own) | `show()` | Employee can view their own card preview without permission |
| None (no permission requirement) | `show()` for own self | Self-service — no gate check |

## Logic Flow

**Page Load (`show()`).** Route-model-binding loads Employee. Checks if authenticated user is the employee (self-service). If not, gates for `hrs.idcard.generate`. Calls `IdCardService::getTemplate()` (default template) and `IdCardService::prepareCardData($employee)` which eager-loads profile relationships. Renders the preview view.

**Generate PDF (`generate()`).** Gates for `hrs.idcard.generate`. Calls `IdCardService::getTemplate()`. If no template found, `abort(404, 'No ID card template configured.')`. Prepares card data. Renders Blade view `hrstaff::id_card.pdf` through DomPDF with credit-card-sized paper. Activity logged. Returns PDF download response.

## Validate Before Save

This screen does not accept user data input — no form validation is applicable. The `generate()` endpoint validates template existence via an explicit abort check.

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| No default ID card template configured | "No ID card template configured." | 404 abort (generate) |
| Missing permission | "This action is unauthorized." | 403 (Gate) |

## Success Scenarios

**SC-001 — View Own ID Card.** Employee ID 5 views their own ID card. Self-service check passes (own record). System renders the preview showing name "Priya Sharma", code "EMP/2025/012", designation "Teacher", department "Science", profile photo, and QR code.

**SC-002 — Generate PDF.** HR Manager generates ID card PDF for employee ID 5. System gates, finds default template, prepares data, returns `id-card-EMP-2025-012.pdf` as download.

## Failure Scenarios

**FC-001 — No Template Configured.** HR Manager tries to generate ID card but no default active template exists. System returns 404 "No ID card template configured."

**FC-002 — Missing Permission.** Employee ID 5 tries to view another employee's ID card without `hrs.idcard.generate` permission. Returns 403 "This action is unauthorized."

## Dependencies module and tables

| Dependency | Type | Details |
|------------|------|---------|
| `Modules\SchoolSetup\Models\Employee` | Data source | Employee personal info, emp_code, profile_photo_url, profile relationships |
| `Modules\HrStaff\Models\IdCardTemplate` | Data source | Template layout_json and is_default flag for rendering |
| `IdCardService` | Service | getTemplate(), prepareCardData(), getQrData() |
| Barryvdh\DomPDF | External library | PDF generation with custom paper dimensions |
| Activity Log | Service | `activityLog()` called on generate |

**Table:** `hrs_id_card_templates`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT UNSIGNED | PK, Auto Increment |
| name | VARCHAR(150) | NOT NULL |
| layout_json | JSON | NOT NULL |
| is_default | TINYINT(1) | NOT NULL DEFAULT 0 |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| created_by | BIGINT UNSIGNED | NOT NULL |
| updated_by | BIGINT UNSIGNED | NOT NULL |
| created_at | TIMESTAMP | NULL |
| updated_at | TIMESTAMP | NULL |
| deleted_at | TIMESTAMP | NULL |
