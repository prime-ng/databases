# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 06: Document Requests & Vault

---

## 1. Executive Summary
Parents often need official duplicate documents (Transfer Certificate, Bonafide, Character Certificate). Instead of visiting the front desk, they can raise requests online. Some of these requests carry an administrative fee.

## 2. Core Components
- `ParentDocumentController.php`
- Table: `ppt_document_requests`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Request Generation
- Parent selects a `document_type` (TC, Bonafide, Migration, MedicalFitness).
- System auto-generates a unique `request_number` (e.g., PPT-DR-2026-00000001).
- Parent sets the urgency (Normal, Urgent).

### FR-02: Status & Payment Workflow
- **Initial:** Status is `Pending`.
- **Payment Trigger:** If the admin reviews the request and updates `fee_required` to a non-zero amount, the parent must pay.
- **Payment Gateway:** The portal integrates with Razorpay via `ParentDocumentController::payInitiate()`. The `payment_reference` column in the database is updated with the Razorpay order ID to prevent duplicate payments (Idempotency).
- **Fulfillment:** Once `fee_paid` is true (or if fee was 0), the admin uploads the fulfilled document (linking `fulfilled_media_id` via Spatie Media). The parent can then download it.

### FR-03: Withdrawals
- Parents can withdraw a request ONLY if the status is still `Pending` and no fee has been paid.

---

## 4. Acceptance Criteria
- **Given** I requested a Bonafide certificate, **When** the admin sets a ₹100 fee, **Then** I see a "Pay Now" button on the request. **When** I successfully pay via Razorpay, **Then** the `fee_paid` flag becomes true and the admin is notified to fulfill the document.
