# Applications — Business Requirements

## What This Screen Does

The Applications tab records and manages admission applications submitted by prospective students. Each application links to an admission cycle, target class, student personal details, parent/guardian information, address, previous schooling, and interview/fee data. The system auto-generates a unique application number (APP-{YEAR}-{SEQ}) and defaults the status to "Draft".

Applications progress through a finite state machine (FSM): Draft → Submitted → Under_Review → Shortlisted/Waitlisted → Allotted → Enrolled/Withdrawn. Each transition is immutably audited in the `adm_application_stages` table with the user, timestamp, and remarks.

The applications tab is the second of two tabs in the Enquiry Pipeline page (`/admission/enquiry-pipeline?tab=applications`). Applications are paginated independently from enquiries using the `applications_page` query parameter.

Sensitive personally identifiable information (Aadhar number) is encrypted at rest using a `SafeEncrypted` cast, and a blind index hash (`aadhar_no_hash`) enables duplicate detection within the same admission cycle.

## When This Screen Is Used

- **Application Intake**: Converting an enquiry into a formal application for admission
- **Document Verification**: Verifying uploaded documents against checklist items
- **Interview Scheduling**: Setting interview date, venue, and recording scores
- **Application Review**: Reviewing applications, updating status through the pipeline
- **Merit List Preparation**: Shortlisting and allotting seats based on merit
- **Enrollment**: Converting allotted applications into enrolled students
- **Audit**: Reviewing stage history for any application

## Key Fields

**Application Identity**
- Application No (auto-generated: APP-{YEAR}-{SEQ})
- Admission Cycle — determines age rules and application period
- Linked Enquiry — optional reference to the originating enquiry
- Applied Class — target class for admission
- Quota Type — General, Government, Management, RTE, NRI, Staff_Ward, Sibling, EWS

**Student Personal Details**
- First Name (required), Middle Name, Last Name
- Date of Birth (validated against cycle age rules)
- Gender, Religion, Caste Category, Nationality, Mother Tongue
- Aadhar Number (encrypted at rest, hashed for uniqueness check)
- Birth Certificate No, Blood Group, Known Allergies

**Previous Schooling**
- Previous School Name, Class Passed, Marks Percentage, TC Number

**Parent & Guardian Details**
- Father/Mother/Guardian: name, mobile, email, occupation
- Guardian relation type

**Address**
- Address Line 1 & 2, City, State, Pincode

**Application Fee & Interview**
- Fee Paid (boolean), Amount, Date
- Interview Scheduled At, Venue, Notes, Score

**Status Lifecycle (FSM)**
- Draft → Submitted → Under_Review → Shortlisted / Waitlisted → Allotted → Enrolled / Withdrawn
- Any status → Rejected (requires rejection_reason)
- Displayed as color-coded badges

## Business Rules

**Auto-Generated Application Number:** Created inside a DB transaction with `lockForUpdate()` to prevent race conditions. Format: `APP-{YEAR}-{SEQ}` where SEQ is auto-incrementing per year. This ensures gapless uniqueness under concurrent writes.

**Aadhar PII Protection:** The `aadhar_no` field uses the `SafeEncrypted` cast for encryption at rest. On save, if `aadhar_no` has changed, the model's `saving` event hashes it via `PiiHashHelper::hash()` (HMAC-SHA-256 using APP_KEY) and stores the result in `aadhar_no_hash`. This blind index enables duplicate detection without exposing raw values.

**Aadhar Uniqueness (Store):** The `StoreApplicationRequest::withValidator()` checks whether any existing application in the same admission cycle has the same `aadhar_no_hash`. If found, validation fails with a duplicate error.

**Aadhar Uniqueness (Update):** The `UpdateApplicationRequest::withValidator()` performs the same check but excludes the current application's own ID (`where('id', '!=', $application->id)`).

**Age Validation:** The `withValidator()` checks the student's DOB against the selected cycle's `age_rules_json`. If the cycle defines `min_age` or `max_age`, the calculated age at the cycle's end date must fall within the range. If `age_rules_json` is missing, the check is skipped.

**Status FSM (Finite State Machine):** The `AdmissionPipelineService` enforces a strict transition map. All transitions are performed inside a DB transaction that atomically updates the application status and creates an immutable `ApplicationStage` record. Invalid transitions throw a `DomainException` caught by the controller.

**Stage Audit Trail:** Every status change creates an `ApplicationStage` record containing `from_status`, `to_status`, `remarks`, `changed_by`, and `changed_at`. This provides a complete, immutable audit history for each application. The `stages()` endpoint returns the history as JSON with the `changedBy` user relation loaded.

**Cycle Immutable on Update:** The `UpdateApplicationRequest` does not include `admission_cycle_id`, making the admission cycle unchangeable after creation.

**Separate Pagination:** Applications on the pipeline page paginate independently from enquiries using the `applications_page` query parameter name, preventing page number conflicts between the two tabs.

## Workflow

1. An application is created from an enquiry (or standalone) with student details, parent info, address, and previous schooling
2. System auto-generates application number and sets status to "Draft"
3. Application fee is recorded (paid/unpaid, amount, date)
4. Application is submitted (Draft → Submitted)
5. Admin reviews documents and sets status to Under_Review
6. Interview is scheduled, conducted, and scored
7. Based on merit: Shortlisted or Waitlisted
8. Shortlisted applicants are Allotted seats
9. Allotted applicants Enroll or Withdraw
10. At any point, an application can be Rejected with a reason

## Related Screens

- **Enquiries Tab** — First tab in the pipeline; source of most applications
- **Application Show** — Detail view with 8 information cards
- **Application Documents** — Document upload and verification per checklist
- **Admission Cycles** — Cycle status, age rules, and application period
- **Merit Lists** — MeritListEntries linked to applications
- **Allotments** — Seat allotments made to shortlisted applications

## Requirements

- MUST display paginated applications list at `/admission/enquiry-pipeline?tab=applications` with search (first_name, last_name, application_no) and status filter
- MUST paginate separately from enquiries using `applications_page` query parameter
- MUST authorize via `tenant.adm-application.*` policy gates (14 permissions)
- MUST auto-generate `application_no` as APP-{YEAR}-{SEQ} inside a locked DB transaction
- MUST enforce 52 validation rules on store (BC-VAL-01 through 52)
- MUST enforce age validation via withValidator using cycle's age_rules_json
- MUST encrypt `aadhar_no` at rest via SafeEncrypted cast
- MUST compute `aadhar_no_hash` on save when aadhar_no changes (PiiHashHelper)
- MUST enforce aadhar uniqueness within the same admission cycle (self-excluding on update)
- MUST default status=Draft on create
- MUST support soft-delete, restore, force-delete lifecycle
- MUST provide AJAX toggle-status endpoint returning JSON
- MUST enforce FSM status transitions (BC-BIZ-FSM-01 through 10)
- MUST create immutable ApplicationStage record on every status change
- MUST throw DomainException on invalid transition, caught as redirect error
- MUST validate rejection_reason required when status=Rejected
- MUST make admission_cycle_id immutable on update
- MUST show 8-card detail view with full relations on show page
- MUST log all CRUD operations and status transitions via activityLog()
