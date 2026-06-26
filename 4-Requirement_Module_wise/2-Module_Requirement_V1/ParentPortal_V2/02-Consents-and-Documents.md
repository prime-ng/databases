# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature: Consents & Document Requests

---

## 1. Executive Summary
This feature digitizes paper trails. It allows schools to publish Consent Forms (e.g., for a field trip) and allows parents to request official duplicate documents (e.g., Transfer Certificates, Marksheets) from the administration.

## 2. Business Motive & Rules
- **Immutability of Consent:** A parent cannot digitally sign a consent form, wait for the trip to happen, and then delete their signature. The signature is legally binding and must be immutable.
- **Paid Requests:** Requesting a duplicate Transfer Certificate (TC) might incur a ₹500 fee. The system must support integrating Razorpay for document requests.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Consent Forms (`ppt_consent_forms`)
- Created by the School Admin.
- Targeted at specific classes, sections, or the whole school.
- Defined with a strict `deadline`. After the deadline, the status becomes `Closed`.

### FR-02: Consent Responses (`ppt_consent_form_responses`)
- Managed by `ParentConsentFormController.php`.
- **Strictly Immutable:** The table deliberately omits `deleted_at`. Responses cannot be soft-deleted.
- **Fields:**
  - `response`: 'Signed' or 'Declined'.
  - `decline_reason`: Mandatory if declined.
  - `signer_name`: E-signature (parent typing their name).
  - `signed_ip`: Captured via `$request->ip()` for audit trails.
  - `signed_at`: The exact business timestamp of the signature.
- Prevents double-signing via a UNIQUE constraint on `(consent_form_id, student_id, guardian_id)`.

### FR-03: Document Requests (`ppt_document_requests`)
- Managed by `ParentDocumentController.php`.
- Parents request docs like 'TC', 'Bonafide', 'Migration'.
- Generates a unique `request_number` (e.g., PPT-DR-2026-00000001).
- **Payment Integration:** If the admin flags the request with `fee_required > 0`, the parent cannot download the fulfilled document until `fee_paid` is true.
- Integrates with `PaymentService` to initiate Razorpay checkouts. `payment_reference` enforces idempotency.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Immutable Consent Signing
**As a** School Administrator,
**I want** digital signatures on consent forms to be permanently recorded,
**So that** parents cannot deny giving permission for a field trip later.

**Acceptance Criteria:**
- **Given** a parent signs a field trip consent form, **When** the `ParentConsentFormController` processes it, **Then** a record is created in `ppt_consent_form_responses` capturing their IP address, and the backend explicitly blocks any subsequent UPDATE or DELETE actions on that row.
