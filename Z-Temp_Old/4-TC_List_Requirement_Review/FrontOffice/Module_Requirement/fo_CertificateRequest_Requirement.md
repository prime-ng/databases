# Certificate Requests — Business Requirements

## What This Screen Does

The Certificate Requests tab manages student certificate request workflow. Requests go through Pending → Approved → Issued, or Rejected. The tab splits into Pending Approval (highlighted) and Recent Requests sections. Supports multiple certificate types, urgent requests, and copy counts.

## When This Screen Is Used

- **Certificate Applications**: Students requesting Bonafide, Character, TC Copy, etc.
- **Approval Workflow**: Admin approves/rejects requests
- **Certificate Issuance**: Issuing approved certificates
- **Urgent Requests**: Priority handling with urgent badge

## Key Fields

- **request_number** (string) — Auto-generated unique identifier
- **student_id** (FK → std_students) — Requesting student
- **cert_type** (enum) — Bonafide, Character, Fee_Paid, Study, TC_Copy, Migration, Conduct, Other
- **purpose** (string) — Reason for certificate
- **copies_requested** (integer, default 1, max 10)
- **is_urgent** (boolean) — Urgent request badge
- **status** (enum) — Pending, Approved, Issued, Rejected
- **approved_by / approved_at** — Approval tracking
- **issued_by / issued_at** — Issuance tracking
- **rejected_by / rejected_at / rejection_reason** — Rejection tracking

## Requirements

- MUST display in Compliance tab group with Pending + Recent sections
- MUST authorize via `frontoffice.certificate.*` policy gates
- MUST show Pending Approval section with warning border
- MUST show "Urgent" badge for urgent requests
- MUST support cert types: Bonafide, Character, Fee_Paid, Study, TC_Copy, Migration, Conduct, Other
- MUST support status filter: All/Pending/Approved/Issued/Rejected
- MUST create requests via modal with student select, cert type, purpose, copies, urgent flag
- MUST search by student name, request number
