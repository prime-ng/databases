# Certificate Request & Issuance — Requirements

## What It Does
Students/parents can request official certificates (Bonafide, Character, TC Copy, Migration, etc.) through the front office. Supports multi-stage approval tracking, DomPDF-based auto-generation, and fee clearance verification for TC/Migration certificates.

## Database Fields

### fof_certificate_requests

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `request_number` | VARCHAR(25) | Required. Unique. Auto-generated: `CERT-YYYY-NNNNN`. |
| `student_id` | INT UNSIGNED FK → `std_students` | Required. |
| `cert_type` | ENUM('Bonafide','Character','Fee_Paid','Study','TC_Copy','Migration','Conduct','Other') | Required. |
| `purpose` | VARCHAR(200) | Required. |
| `copies_requested` | TINYINT UNSIGNED | Default 1. Range: 1–5. |
| `is_urgent` | TINYINT(1) | Default 0. Escalates approval priority. |
| `applicant_name` | VARCHAR(100) | Nullable. Person requesting. |
| `applicant_contact` | VARCHAR(15) | Nullable. |
| `stages_json` | JSON | Nullable. Multi-stage approval history. |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Issued','Cancelled') | Default 'Pending_Approval'. |
| `approved_by` | INT UNSIGNED FK → `sys_users` | Nullable. |
| `approved_at` | DATETIME | Nullable. |
| `rejection_reason` | TEXT | Nullable. Required when Rejected. |
| `cert_number` | VARCHAR(30) | Nullable. Unique. NULL until issued (MySQL UNIQUE allows multiple NULLs). |
| `issued_at` | DATETIME | Nullable. |
| `issued_by` | INT UNSIGNED FK → `sys_users` | Nullable. |
| `issued_to` | VARCHAR(100) | Nullable. |
| `media_id` | INT UNSIGNED FK → `sys_media` | Nullable. Generated PDF. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-005 | TC_Copy and Migration certificates require no outstanding fees | `CertificateIssuanceService::issue()` calls FIN balance check before proceeding |
| BR-FOF-006 | Cert number is UNIQUE but NULL until issued (MySQL allows multiple NULLs) | DB unique constraint on `cert_number` |

**Lifecycle**
```
Pending_Approval → Approved → Issued
                → Rejected
                → Cancelled
```

**Certificate Number Generation**
- Prefix per type: Bonafide→BON, Character→CHAR, Fee_Paid→FEE, Study→STD, TC_Copy→TC, Migration→MIG, Conduct→COND, Other→CERT
- Format: `{PREFIX}-{YEAR}-{NNN}` (3-digit sequence, reset per year per type)
- Generated at issuance time, not at request time (NULL until issued)

**Issuance Flow**
1. Verify status = 'Approved'
2. If `cert_type IN ('TC_Copy', 'Migration')`: check FIN fee clearance — block with `CertificateFeesOutstandingException` if outstanding
3. Generate `cert_number`
4. Load student data + school branding (logo, address, principal signature)
5. Render DomPDF from per-type Blade template
6. Store PDF in `sys_media`
7. Update record: cert_number, media_id, issued_at, issued_by, issued_to, status = 'Issued'
8. Dispatch NTF to student/parent: certificate ready for collection

**Approval Tracking**
- `stages_json` stores approval history as array: `[{stage: 'HOD', status: 'approved', by: 1, at: '...', remarks: ''}, ...]`
- Each approval/rejection appends to this JSON array

## CRUD Operations

**Request Certificate**
- `POST /front-office/certificates` — validates student_id, cert_type, purpose, copies (1–5)
- Generates request_number CERT-YYYY-NNNNN

**Approve / Reject**
- `PATCH /front-office/certificates/{cert}/approve` — sets approved_by, approved_at, status = 'Approved'
- `PATCH /front-office/certificates/{cert}/reject` — requires rejection_reason

**Issue**
- `PATCH /front-office/certificates/{cert}/issue` — validates Approved status, checks FIN clearance, generates PDF

**Download**
- `GET /front-office/certificates/{cert}/download` — streams PDF from sys_media

**List**
- Request queue with status tabs: Pending / Approved / Issued
- Urgent flag highlight
- Issuance log with cert_number, issued_to, issued_at

## Permissions

| Operation | Permission Key |
|---|---|
| View requests | `frontoffice.certificate-request.view` |
| Create request | `frontoffice.certificate-request.create` |
| Approve/reject | `frontoffice.certificate-request.approve` |
| Issue certificate | `frontoffice.certificate-request.issue` |
