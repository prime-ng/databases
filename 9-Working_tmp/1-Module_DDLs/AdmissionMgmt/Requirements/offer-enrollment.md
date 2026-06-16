# Offer Letter & Enrollment — Requirements

## What It Does
Generate offer letters with DomPDF (including QR code for verification), manage admission fee payment via PAY webhook integration, and convert allotted candidates into enrolled students by creating permanent student records (sys_users + std_students + std_student_academic_sessions) in a single atomic transaction.

## Database Tables

### `adm_allotments` (Offer & Enrollment Extended Logic)

| Field | Offer/Enrollment Role |
|---|---|
| `admission_no` | Assigned on offer (format per cycle config). |
| `offer_letter_media_id` | Set when DomPDF offer letter generated. Stored in `sys_media`. |
| `offer_issued_at` | Timestamp of offer generation. |
| `offer_expires_at` | Deadline for parent response. |
| `admission_fee_paid` | Set to 1 by PAY webhook. |
| `admission_fee_amount` | Fee amount from cycle config. |
| `admission_fee_date` | Payment confirmation date. |
| `status` | Offered → Accepted → Enrolled. |
| `enrolled_student_id` | Set by `EnrollmentService` on conversion. |

## Offer Lifecycle (FSM)

```
Offered → Accepted (parent confirms) → Enrolled (fee paid + enrollment)
        → Declined → Waitlist promoted
        → Expired (daily job) → Waitlist promoted
```

## Offer Letter Generation
- DomPDF renders: school letterhead, student name, class, admission_no, joining date.
- QR code encoding public verification URL embedded in PDF.
- PDF stored in `sys_media` via private storage disk.
- NTF dispatched to parent via email + SMS.
- Offer letter can be regenerated (replaces existing PDF in sys_media).

## Payment Integration

**Application Fee**
- Paid at Draft → Submission via PAY module integration.
- RTE quota applicants exempt (BR-ADM-005).

**Admission Fee**
- Paid after offer acceptance via PAY webhook.
- Webhook: `POST /api/v1/admission/payment/webhook` — signature-verified, idempotent.
- Idempotency: Check `admission_fee_paid` before processing; return 200 on duplicate.

**Fee Confirmation (Manual)**
- Finance staff can manually confirm fee via permission `tenant.adm.fee.confirm`.
- Used when payment is made offline (bank deposit, DD).

## Enrollment Conversion (Critical Transaction)

### `EnrollmentService::enrollStudent()` Steps:

1. Verify `admission_fee_paid = 1`
2. Verify no existing enrollment for same session (BR-ADM-010)
3. **`DB::transaction()` begins**
4. Create `sys_users` — student login (name, email, password, user_type='STUDENT')
5. Create `std_students` — user_id, admission_no, admission_date, personal details
6. Auto-assign section (section with lowest enrollment count)
7. Assign roll number (sequential within section + session)
8. Create `std_student_academic_sessions` — is_current=1
9. Update `adm_allotments` — enrolled_student_id, status=Enrolled
10. Update `adm_applications` — status=Enrolled
11. If sibling (`is_sibling=1`) → create `std_siblings_jnt`
12. **Commit transaction**
13. Increment `adm_seat_capacity.seats_enrolled`
14. Dispatch NTF — login credentials + welcome message

## Business Rules

**Atomic Enrollment (BR-ADM-002)**
- Enrollment is all-or-nothing within single `DB::transaction()`.
- Partial records rolled back on any failure.

**Admission Number Uniqueness (BR-ADM-003)**
- `admission_no` unique within school-year.
- Format: configurable via `adm_admission_cycles.admission_no_format` (default `{YEAR}/{SEQ}`).

**One Enrollment Per Session (BR-ADM-010)**
- `std_student_academic_sessions` UNIQUE on `(student_id, academic_session_id)`.
- Pre-checked in `EnrollmentService` before transaction begins.

**Roll Number Assignment (BR-ADM-008)**
- Sequential within `(class_section_id, academic_session_id)`.
- Auto-assigned during enrollment.

## CRUD Operations

**Generate Offer Letter**
- Route: `POST /admission/allotments/{allotment}/offer-letter` → generates DomPDF, stores in sys_media, updates offer_issued_at and offer_expires_at

**View Offer Letter**
- Route: `GET /admission/allotments/{allotment}/offer-letter` → serve PDF from sys_media

**Confirm Fee (Manual)**
- Route: `PATCH /admission/allotments/{allotment}/confirm-fee` → sets admission_fee_paid = 1, admission_fee_date = now()

**Enroll Student**
- Route: `POST /admission/allotments/{allotment}/enroll` → runs `EnrollmentService::enrollStudent()`
- Fails with validation message if fee not paid

**Bulk Enroll**
- Route: `POST /admission/allotments/bulk-enroll` → runs `bulkEnroll()` processing multiple allotments
- Per-student success/failure report
- Never stops entire batch on one failure

## Permissions

| Operation | Permission Key |
|---|---|
| Generate offer letter | `tenant.adm.allotment.manage` |
| View offer letter | `tenant.adm.allotment.viewAny` |
| Confirm fee payment | `tenant.adm.fee.confirm` |
| Enroll student | `tenant.adm.enrollment.create` |
| Bulk enroll | `tenant.adm.enrollment.create` |
