# Employee Profile — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Creation & Profile Mgmt sub-menu. Its primary purpose is to create and manage master profile records for all school employees, teachers, and support staff.

This screen acts as the core database for all staff members, securely storing permanent personal details, contact details, date of joining, department mappings, salary bank accounts, personal credentials, and profile photos. It serves as the primary data source for payroll, attendance, and role-based permissions across the entire system.

---

## Common Use Cases

1. **Onboarding New Employees / Teachers:** Creating a new profile record for newly joined staff members.
2. **Updating Profile Details:** Modifying contact information, residential addresses, or bank account details (for salary credits) when updates are requested.
3. **Bulk Onboarding via Excel/CSV Import:** Importing large volumes of staff records (e.g., onboarding 50-100 teachers at the start of a session) simultaneously using a standardized template.
4. **Uploading Credentials & Certificates:** Uploading scanned copies of academic degrees, experience letters, and identity cards (e.g., Aadhar Card) to the employee's digital file.
5. **Soft Deleting (Archiving) Resigned Staff:** Removing resigned or retired staff from the active list (archiving their profile) while preserving historical payroll, attendance, and audit records.

---

## Screen Fields & Input Rules

### Section A: Basic Information (Personal Details)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| First Name | Employee's first name | Required. Must contain only letters (A-Z, a-z). Special characters are not allowed. |
| Last Name | Employee's surname | Required. Must contain only letters (A-Z, a-z). |
| Email ID | Official school email address | Required. Must be unique. Must follow standard email format (e.g., name@school.com). |
| Phone Number | Active 10-digit mobile number | Required. Exact 10 digits required. Indian mobile number format. |
| Date of Birth | Date of birth (Date Picker) | Required. Minimum age requirement is 18 years (**Age >= 18**). |
| Gender | Gender | Required. Options: Male / Female / Other. |
| Blood Group | Blood group category | Optional. Dropdown: A+, B+, O+, AB+, etc. |

### Section B: Employment Information (Job Details)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Department | Assigned department | Required. Must select from the active department master list. |
| Designation | Employee designation | Required. Must select from the active designations master list. |
| System Role | System access permission role | Required. Dropdown: Teacher / Admin / HR / Accountant / Support Staff. |
| Employment Type | Contract status of the employment | Required. Dropdown: Permanent / Contract / Temporary / Probation / Intern. |
| Date of Joining | Date of official joining (Date Picker) | Required. Can be a past or current date. Future dates are not allowed. |
| Probation Period | Duration of the probation period | Optional (in months). Range: 0 to 12. |
| Probation End Date | Date when probation ends | Automatically calculated field: **Date of Joining + Probation Period**. |
| Reporting Manager | Direct supervisor of the employee | Optional. Selected from the active employee dropdown. (An employee cannot be selected as their own manager). |

### Section C: Address, Bank & Documents Details
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Permanent Address | Residential address | Required. Residential address lines 1 and 2. |
| City & Pincode | City and PIN code | Required. PIN code must be exactly 6 digits. |
| State & Country | State and country | Required. Selected from standard dropdown menus. |
| Bank Name | Bank name for salary transfers | Required. E.g., State Bank of India. |
| Account Number | Bank account number | Required. Range: 9 to 18 digits. Must be unique. |
| IFSC Code | Bank branch routing code | Required. Must match format: ABCD0123456. |
| Profile Photo | Digital portrait of the employee | Optional. Format: PNG/JPG. Maximum file size: 5MB. |
| Document Upload | Identity proof and academic degrees | Scanned PDF files. Maximum file size: 10MB per document. |

---

## Business Rules & Validation Policies

1. **Age Validation Lock:**
   - The system calculates the applicant's age based on the `Date of Birth`. If the calculated age is less than 18 years, the system blocks profile creation.

2. **Soft Delete / Archiving Policy:**
   - To maintain historical integrity for payroll, tax audits, and attendance reports, staff records are never permanently purged from the database.
   - Clicking "Delete" changes the status to inactive and shifts the record to the **Archive Tab**. HR can restore archived records if required.

3. **Probation End Date Calculation:**
   - When HR specifies a probation period (e.g., `3 months`) for an employee joining on `15-Jan-2026`, the system automatically computes and displays the `Probation End Date` as `15-Apr-2026`.

---

## Screen Workflows & Operations

### 1. Creating a Single Employee Profile (Create)
- The Admin clicks the "+ New Employee" button.
- A multi-tab form opens containing sections for Basic Info, Job Details, Address, and Bank details.
- The Admin uploads the passport photo and scanned PDFs of academic credentials.
- Clicks Save. The system performs background validations (email uniqueness, age limits, field formatting) and creates the profile.

### 2. Updating Profile Details (Update)
- The Admin searches the active staff list and clicks "Edit" next to the target profile.
- Modifies the details as required (e.g., changes the residential address or updating mobile number).
- Modifying sensitive fields like Bank Account Number or IFSC Code triggers a confirmation alert before changes are committed.

### 3. Bulk Onboarding (Bulk Import)
- HR clicks the "Import Excel" button.
- Downloads the standardized Excel onboarding template.
- Populates the Excel sheet with staff data (up to 500 rows).
- Uploads the file. The system parses the sheet and checks for validation errors (e.g., duplicate emails, incorrect phone lengths).
- If validation succeeds, a data preview is shown. Clicking "Confirm" imports the records into the database in bulk.

---

## Real-World Example Scenario

**School HR Manager** is onboarding a new primary section teacher, **Sunita Sharma**:

1. HR opens the `Employee` master screen and clicks "+ New Employee".
2. Fills in the form fields:
   - Name: `Sunita Sharma`, Email: `sunita.sharma@school.com`, Phone: `9876543210`.
   - DOB: `15-May-1994` (System calculates age as 32; age validation passed).
   - Department = `Academic`, Designation = `Junior Teacher`, Role = `Teacher`.
   - Date of Joining = `15-Jan-2026`, Probation Period = `3 months`.
   - **System calculated End Date** = `15-Apr-2026`.
   - Inputs bank details for payroll.
3. Uploads Sunita's profile photo and B.Ed degree certificate.
4. Clicks Save. Sunita's record is added to the active list, a unique Employee Code is generated, and a welcome email is sent to her inbox.
