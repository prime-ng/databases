# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 05: Consent Forms & E-Signatures

---

## 1. Executive Summary
Schools require legal permission from parents for field trips, vaccinations, and media releases. The Consent Form feature digitizes this with immutable electronic signatures.

## 2. Core Components
- `ParentConsentFormController.php`
- Table: `ppt_consent_forms` (School creates these)
- Table: `ppt_consent_form_responses` (Parent signs these)

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Form Visibility
- Forms are filtered based on the active child's `class_id` and `section_id`.
- The controller categorizes them into 3 tabs:
  - `Pending`: Status is Published, deadline has not passed, and not yet signed.
  - `Closed`: Deadline has passed (no longer signable).
  - `Signed`: Forms the parent has already responded to.

### FR-02: Immutable E-Signatures
- **Action:** Parent selects "Signed" or "Declined".
- **Decline Reason:** If "Declined", the `decline_reason` field becomes strictly required.
- **Audit Logging:** The system records `signer_name` (typed name), `signed_ip` (IPv4/IPv6 address), and `signed_at`.
- **Database Integrity:** The `ppt_consent_form_responses` table deliberately lacks a `deleted_at` column. Once a response is inserted, it cannot be soft-deleted. Double-signing is prevented by a database UNIQUE constraint on `(consent_form_id, student_id, guardian_id)`.

---

## 4. Acceptance Criteria
- **Given** an open consent form for a Museum Trip, **When** I click 'Sign', type my name "Rajesh Kumar", and submit, **Then** the form moves to the 'Signed' tab. **When** I try to change my answer to 'Declined' the next day, **Then** the system blocks the action because the record is permanently locked.
