# hrs_IdCard_TcList

## Module: HrStaff → Employee → ID Card

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HrStaff |
| Tab Group | Employee → ID Card |
| Feature | ID Card |
| URL(s) | `GET /hr-staff/employees/{employee}/id-card` (show) |
| | `POST /hr-staff/employees/{employee}/id-card/generate` (generate) |
| Controller | `Modules\HrStaff\Http\Controllers\IdCardController` — `show()` lines 22-34, `generate()` lines 39-57 |
| Model(s) | `Modules\HrStaff\Models\IdCardTemplate` (table: `hrs_id_card_templates`) |
| | `Modules\SchoolSetup\Models\Employee` (data source for card info) |
| Validation | None (no user data input) |
| Policy | None (gate checks directly in controller) |
| Permissions | `hrs.idcard.generate` (self-service exception for viewing own card) |
| Pagination | None |
| Soft Deletes | N/A |
| Read-Only | ID Card preview is read-only; generation returns PDF download |

---

## 2. Pre-conditions

- User must be logged in; employees can view their own card without permission
- At least one employee record must exist with a profile (designation, department) and photo
- At least one `IdCardTemplate` must be marked as `is_default = true` and `is_active = true` for PDF generation to succeed
- DomPDF (Barryvdh) must be configured
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

`IdCardController::show()` loads the employee, checks self-service or gates, then calls `IdCardService::getTemplate()` and `IdCardService::prepareCardData($employee)`.

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| ID Card Preview | `show()` | `IdCardService::getTemplate()` → first active default template | `is_active=true`, `is_default=true` | None |
| Card Data | `show()` | `IdCardService::prepareCardData($employee)` → eager-loads profiles | `activeEmployeeProfile`, `activeTeacherProfile` | None |

---

## 4. Test Data Strategy

- Create at least one `IdCardTemplate` record with `is_default = true` and `is_active = true`
- Create an employee with emp_code, profile_photo_url, and linked profile records (designation, department)
- For the "no template" scenario, set is_active=false or delete the only template
- Pre-test cleanup: truncate `hrs_id_card_templates`

---

## 5. Business Conditions

### 5.1 Database Schema — `hrs_id_card_templates`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto Increment |
| BC-DB-02 | name | VARCHAR(150) | NOT NULL |
| BC-DB-03 | layout_json | JSON | NOT NULL |
| BC-DB-04 | is_default | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-06 | created_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-07 | updated_by | BIGINT UNSIGNED | NOT NULL |
| BC-DB-08 | created_at | TIMESTAMP | NULL |
| BC-DB-09 | updated_at | TIMESTAMP | NULL |
| BC-DB-10 | deleted_at | TIMESTAMP | NULL |

### 5.2 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `hrs.idcard.generate` (granted) | User can view and generate ID card for any employee |
| BC-AUTH-02 | Own record (no `hrs.idcard.generate`) | User can view own card preview; cannot generate PDF (generate always gates) |
| BC-AUTH-03 | `hrs.idcard.generate` (denied, not own) | Show returns 403 |
| BC-AUTH-04 | `hrs.idcard.generate` (denied) | Generate returns 403 |
| BC-AUTH-05 | Guest (not logged in) | Redirect to /login |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Show own ID card (self-service) | Preview rendered with employee details; check self-service passes |
| BC-BIZ-02 | Show another employee's ID card (with permission) | Preview rendered with that employee's details |
| BC-BIZ-03 | Generate PDF with default template configured | PDF downloaded with filename `id-card-{emp_code}.pdf` |
| BC-BIZ-04 | Generate PDF without default template | 404 "No ID card template configured." |
| BC-BIZ-05 | Card data includes name, emp_code, designation, department | Preview shows employee full_name, emp_code, role name, department name |
| BC-BIZ-06 | Employee has no profile | Designation and department show "—" |
| BC-BIZ-07 | QR data uses emp_code or fallback | QR encodes `employee->emp_code` or `EMP-{employee->id}` if no code |
| BC-BIZ-08 | Activity logged on generate | `activityLog()` called with type 'Generated', message 'ID card generated.' |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-P01 | Employee views own ID card preview | Preview rendered with own employee details; no gate check | — | — | ⬜ |
| TC-P02 | HR Manager views another employee's ID card | Preview rendered with that employee's details | — | — | ⬜ |
| TC-P03 | Generate ID card PDF with default template configured | PDF downloaded as `id-card-{emp_code}.pdf`; activity logged | — | — | ⬜ |
| TC-P04 | Verify card data fields in preview | Name, emp_code, designation, department, photo, QR code displayed | — | — | ⬜ |
| TC-P05 | Employee without profile views card | Designation and department show "—" | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-N01 | Generate PDF without any default template | 404 "No ID card template configured." | — | — | ⬜ |
| TC-N02 | View another employee's ID card without `hrs.idcard.generate` | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N03 | Generate PDF without `hrs.idcard.generate` | 403 "This action is unauthorized." | — | — | ⬜ |
| TC-N04 | Guest user attempts to view ID card | Redirect to /login | — | — | ⬜ |
| TC-N05 | View ID card for non-existent employee | 404 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|-----------------|---------|---------|--------|
| TC-D01 | A | Activity logged on generate | `activityLog()` called with type 'Generated', message 'ID card generated.', employee_id in properties | — | — | ⬜ |
| TC-D02 | B | Gate `hrs.idcard.generate` enforced on generate() | `Gate::authorize('hrs.idcard.generate')` present in generate() | — | — | ⬜ |
| TC-D03 | B | Self-service check in show() | Own-record check before gating in show() | — | — | ⬜ |
| TC-D04 | C | IdCardService::getTemplate() returns default active template | Query returns first template where is_default=true AND is_active=true | — | — | ⬜ |
| TC-D05 | D | DomPDF renders with custom paper size | PDF generated with dimensions 85.6mm x 53.98mm | — | — | ⬜ |
| TC-D06 | E | Route names registered | `hr-staff.id-card.show` and `hr-staff.id-card.generate` resolve correctly | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — `Gate::authorize()` on every restricted method | `generate()` gates always; `show()` gates if not own | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — activity logged on generate | `activityLog()` called in `generate()` | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — abort if no template for generate | `abort_if(!$template, 404, 'No ID card template configured.')` present | — | — | ◌ |
| TC-CR04 | CR | P1 | Service — `IdCardService::getTemplate()` returns correct template | Method filters is_active true and is_default true | — | — | ◌ |
| TC-CR05 | CR | P1 | Service — `IdCardService::prepareCardData()` loads all relations | Eager-loads activeEmployeeProfile, activeTeacherProfile with department and role | — | — | ◌ |
| TC-CR06 | CR | P1 | Routes — both routes registered | `hr-staff.id-card.show` (GET), `hr-staff.id-card.generate` (POST) | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Gate::authorize() on restricted methods
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open IdCardController.php | `show()` line 26 checks self-service; `generate()` line 41 has `Gate::authorize('hrs.idcard.generate')` |

#### TC-CR02: Activity logged on generate
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect generate() line 51 | `activityLog(null, 'Generated', ...)` present with employee_id |

#### TC-CR03: Abort if no template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect generate() line 44 | `abort_if(! $template, 404, 'No ID card template configured.')` |

#### TC-CR04: Service getTemplate()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect IdCardService.php lines 17-23 | getTemplate() returns first active template where is_default=true |

#### TC-CR05: Service prepareCardData()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect IdCardService.php lines 37-56 | Eager-loads `activeEmployeeProfile.department`, `activeEmployeeProfile.role`, `activeTeacherProfile.department`, `activeTeacherProfile.role` |

#### TC-CR06: Routes registered
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --name=hr-staff.id-card` | 2 routes: show (GET), generate (POST) |

### 7.1 Positive TC Steps

#### TC-P01: Employee views own ID card
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee whose employee_id = 5 (own record) | Authenticated |
| 2 | Navigate to GET `/hr-staff/employees/5/id-card` | Preview renders with employee 5's name, emp_code, designation, department, photo, QR code |

#### TC-P02: HR Manager views another employee's ID card
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `hrs.idcard.generate` | Authenticated |
| 2 | Navigate to GET `/hr-staff/employees/5/id-card` | Preview renders with employee 5's details |

#### TC-P03: Generate ID card PDF
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure default active template exists | Template found |
| 2 | POST `/hr-staff/employees/5/id-card/generate` | PDF download starts; filename `id-card-{emp_code}.pdf` |
| 3 | Check activity log | Entry: type 'Generated', message 'ID card generated.', employee_id=5 |

#### TC-P04: Verify card data fields
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/employees/5/id-card` | Page shows: employee full_name, emp_code, designation (from role), department (from department), profile photo, QR code |

#### TC-P05: Employee without profile
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create employee with no activeEmployeeProfile or activeTeacherProfile | Employee created |
| 2 | GET `/hr-staff/employees/{id}/id-card` | Designation shows "—"; department shows "—" |

### 7.2 Negative TC Steps

#### TC-N01: Generate PDF without default template
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set all IdCardTemplate is_active=false or delete all templates | No active default template |
| 2 | POST `/hr-staff/employees/5/id-card/generate` | 404 "No ID card template configured." |

#### TC-N02: View another's card without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as employee 5 (no `hrs.idcard.generate`) | Authenticated |
| 2 | GET `/hr-staff/employees/6/id-card` | 403 "This action is unauthorized." |

#### TC-N03: Generate PDF without permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `hrs.idcard.generate` | Authenticated |
| 2 | POST `/hr-staff/employees/5/id-card/generate` | 403 "This action is unauthorized." |

#### TC-N04: Guest access
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout, GET `/hr-staff/employees/5/id-card` | Redirect to /login |

#### TC-N05: Non-existent employee
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/hr-staff/employees/99999/id-card` | 404 Not Found |

### 7.3 Dependency TC Steps

#### TC-D01: Activity logged on generate
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate PDF for employee 5 | Success |
| 2 | Check activity log | Entry: type 'Generated', message 'ID card generated.', employee_id=5 |

#### TC-D02: Gate on generate()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review generate() | `Gate::authorize('hrs.idcard.generate')` present at line 41 |

#### TC-D03: Self-service check in show()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review show() | Line 24: `$isOwnRecord = auth()->user()?->employee?->id === $employee->id` before gating |

#### TC-D04: getTemplate() returns default
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create two templates: one default, one not | Default template returned by getTemplate() |

#### TC-D05: DomPDF custom paper size
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Code review generate() line 48-49 | `->setPaper([0, 0, 242.65, 153.01])` for credit card size |

#### TC-D06: Route names
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan route:list --name=hr-staff.id-card` | 2 routes: show (GET), generate (POST) |
