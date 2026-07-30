# Transfer Certificates — Business Requirements

## What This Screen Does

The Transfer Certificates (TCs) screen manages official school leaving certificates for departing students. Each TC records the student's details at the time of leaving, conduct grade, reason for leaving, and generates a PDF with QR code. Issuing a TC deactivates the student's school accounts and closes their academic session.

This is the third tab (`?tab=tcs`) of the Promotions & Alumni page at `/admission/promotions-alumni`.

TCs follow a three-state lifecycle: **Draft** (created but not issued) → **Issued** (officially generated, PDF stored) → **Cancelled** (if revoked). The status is computed dynamically from the `issue_date` and `deleted_at` fields.

## When This Screen Is Used

- **TC Issuance**: Creating official Transfer Certificates for departing students
- **Duplicate TC**: Re-issuing lost or damaged certificates
- **Document Generation**: Generating PDF certificates with QR verification codes
- **Student Deactivation**: Automatically deactivating student accounts upon TC issuance
- **TC Cancellation**: Revoking incorrectly issued certificates

## Key Fields

**Student Information**
- Student (FK → std_students)
- Class at Leaving
- Academic Status
- Destination School

**Certificate Details**
- TC Number (unique, auto-generated format: TC-YYYY-NNN)
- Issue Date, Leaving Date
- Reason for Leaving
- Conduct Grade: Excellent, Good, Satisfactory, Poor
- Fees Cleared (boolean)

**Status (Computed)**
- Draft — created, not yet issued (no issue_date)
- Issued — issued, has issue_date and media_id
- Cancelled — soft-deleted (deleted_at set)

**Duplicate TC**
- Is Duplicate (boolean) — true for re-issued certificates
- Original TC (self-reference FK) — links to the original certificate

## Business Rules

**TC Lifecycle:** TCs are created in Draft status. Issuing transitions Draft → Issued. Cancelling can happen at any stage (Cancelled is indicated by soft-delete with an appended reason).

**Issue Effect (TransferCertificateService::issueTc):** Issuing a TC has several side effects:
1. **Timestamps**: Sets `issue_date` to current timestamp
2. **PDF Generation**: Generates a DomPDF document with student particulars, school header, QR code, and signatures. Stores the PDF file in `sys_media` and records `media_id`.
3. **Student Deactivation**: Sets `std_students.is_active = 0` (disables the student record)
4. **User Deactivation**: Sets `sys_users.is_active = 0` (disables portal login)
5. **Session Closure**: Sets `end_date = now()` on the student's current `StudentAcademicSession`
6. **TC Flag**: Sets `tc_issued = true` on the student record
7. **Activity Log**: Logs the operation

**Cancel:** Cancelling a TC appends a cancellation reason to the remarks and soft-deletes the record. Cancellation does **not** reverse the deactivation of the student, user, or academic session — those are permanent.

**Duplicate TC:** The `issueDuplicate()` method creates a new TC record with `is_duplicate = true` and `original_tc_id` referencing the original TC, then immediately issues it. This provides a complete audit trail for re-issued certificates.

**TC Number Uniqueness:** The `tc_number` field has a UNIQUE constraint at the DB level. Format follows TC-YYYY-NNN convention (enforced programmatically).

**Computed Status:** The `TransferCertificate` model does not have a `status` column. Instead, the status is computed:
- `Issued` — if `issue_date` is not null
- `Cancelled` — if `deleted_at` is not null (or issue_date is null and cancelled)
- `Draft` — otherwise (no issue_date, not deleted)

## Workflow

1. Admin opens the TC creation modal from the TCs tab or Alumni tab
2. Admin fills in student details, dates, conduct, reason, and TC number
3. System creates the TC in Draft status
4. Admin reviews the TC on the show page
5. Admin issues the TC — system generates the PDF, deactivates the student, and logs everything
6. Admin can download the PDF for printing/signing
7. If needed, admin can cancel the TC (but deactivation remains)
8. For lost certificates, admin can issue a duplicate TC referencing the original

## Related Screens

- **Alumni Tab** — Source of students needing TCs; "TC Issued" badge
- **Batches Tab** — Promotion batches that produce alumni
- **Incidents Tab** — Behavior incidents for students (conduct affects TC conduct grade)
- **TC PDF** — A4 portrait PDF template with QR code and signature area

## Requirements

- MUST display paginated TCs list at `/admission/promotions-alumni?tab=tcs` with search
- MUST authorize via `tenant.adm-tc.*` policy gates
- MUST validate store with 12 rules including tc_number uniqueness
- MUST create TC in Draft status (no issue_date)
- MUST issue TC via TransferCertificateService::issueTc() — generates PDF, stores in sys_media
- MUST deactivate std_students.is_active = 0 on issue
- MUST deactivate sys_users.is_active = 0 on issue
- MUST close StudentAcademicSession.end_date = now on issue
- MUST set tc_issued = true on std_students on issue
- MUST support TC cancellation (soft-delete with reason)
- MUST support duplicate TC via issueDuplicate() with original_tc_id reference
- MUST render transfer-certificate PDF with QR code
- MUST compute status dynamically (Draft/Issued/Cancelled)
- MUST support soft-delete lifecycle with restore/force-delete
- MUST log all operations via activityLog()
