# Allotment & Enrollment — Business Requirements

## What This Screen Does

The Allotment & Enrollment page manages the final stages of the admission pipeline — converting merit-listed candidates into enrolled students. It is a tabbed interface at `/admission/allotment-enrollment` with two tabs: **Allotments** (default) and **Withdrawals**.

**Allotments** are seat offers made to shortlisted candidates from a published merit list. Each allotment links to a merit list entry and application, specifies the allotted class and section, tracks the offer lifecycle (Offered → Accepted/Declined/Expired → Enrolled), and generates offer letter PDFs.

**Enrollment** is the 14-step atomic process that creates the student record across multiple modules:
- Creates a `sys_users` portal login account
- Creates a `std_students` student profile
- Creates `std_student_academic_sessions` enrollment
- Creates `std_siblings_jnt` if the applicant is a sibling
- Updates the allotment, application, merit list entry, and seat capacity counters

**Withdrawals** record when an applicant or enrolled student withdraws from the admission process, with refund eligibility tracking.

The entire flow is permission-gated via three policies: `tenant.adm-allotment.*`, `tenant.adm-enrollment.create`, and `tenant.adm-withdrawal.*`.

## When This Screen Is Used

- **Allotment Creation**: Assigning seats to shortlisted candidates from merit lists
- **Offer Management**: Sending offer letters, tracking accept/decline responses
- **Student Enrollment**: Converting accepted allotments into full student records
- **Seat Capacity Tracking**: Monitoring allotted and enrolled seat counts per class/quota
- **Withdrawal Processing**: Recording withdrawals and processing refunds
- **Admission Number Generation**: Auto-generating unique admission numbers in {YEAR}/{SEQ} format

## Key Fields

**Allotment**
- Admission No — auto-generated {YEAR}/{SEQ} (e.g., 2026/0001)
- Application — linked application record
- Merit List Entry — source merit list ranking
- Allotted Class & Section — assigned classroom
- Status — Offered (default), Accepted, Declined, Expired, Enrolled, Withdrawn
- Offer Letter — generated PDF stored in sys_media
- Offer Expires At — deadline for accepting the offer
- Joining Date — expected first day
- Admission Fee — paid/amount/date
- Enrolled Student ID — set on enrollment (FK → std_students)

**Withdrawal**
- Application — withdrawn application
- Allotment — linked allotment (nullable, for pre-allotment withdrawals)
- Withdrawal Date
- Reason — Personal, Financial, Relocation, School_Change, Medical, Other
- Fee Paid Amount — total fees paid before withdrawal
- Refund Eligible Amount — computed from cycle's refund_policy_json
- Refund Status — Not_Eligible, Pending, Approved, Paid
- Refund Processed At

## Business Rules

**Seat Capacity Lock on Allotment Creation:** The store method uses `lockForUpdate()` on the `adm_seat_capacity` row to prevent race conditions. After locking, it increments `seats_allotted`. This ensures no two concurrent allotments can oversubscribe seats.

**Admission Number Generation:** The `EnrollmentService::generateAdmissionNo()` generates numbers in format `{YEAR}/{SEQ}` (e.g., `2026/0001`). It checks sequence continuity against both `adm_allotments.admission_no` and `std_students.admission_no` to prevent collisions across already-enrolled students and pending allotments.

**Offer Accept/Decline:**
- `accept()` transitions status from Offered → Accepted. The allotment becomes eligible for enrollment.
- `decline()` transitions status from Offered → Declined and **decrements** `seats_allotted` to free the seat.
- Both actions require the current status to be Offered (other statuses are no-ops).

**Offer Letter PDF:** The `offerLetter()` method generates a PDF via DomPDF, stores it in `sys_media`, sets `offer_letter_media_id` and `offer_issued_at`. The PDF includes school header, offer reference, student details, allotment details, terms & conditions, and signature area.

**14-Step Atomic Enrollment (EnrollmentService::enrollStudent):**
1. Guard: allotment must be 'Accepted' — throws DomainException if not
2. Guard: admission_fee_paid must be true — throws DomainException if not
3. Guard: enrolled_student_id must be null (not already enrolled) — throws DomainException if not
4. Generate admission number if not already set
5. Create `sys_users` record with portal login (password = admission_no)
6. Create `std_students` record with name, DOB, gender, parents, address, etc.
7. Create `std_student_academic_sessions` for current session
8. Create `std_siblings_jnt` if application.is_sibling = true
9. Update allotment: set enrolled_student_id, status = 'Enrolled'
10. Transition application status to 'Enrolled' via AdmissionPipelineService
11. Update merit_list_entry status
12. Increment `seats_enrolled` on `adm_seat_capacity`
13. Append ApplicationStage audit log
14. All steps wrapped in a single DB transaction

**Enrollment Guard Failures:** Enrollment is strictly guarded. If the allotment is not Accepted, fee is unpaid, or the student is already enrolled, a `DomainException` is thrown and caught by the controller as a redirect error.

**Delete Protection:**
- Allotments with status 'Enrolled' cannot be soft-deleted.
- Withdrawals with refund_status 'Paid' cannot be soft-deleted.

**Withdrawal Application Transition:** When a withdrawal is created, the linked application's status is transitioned to 'Withdrawn' via `AdmissionPipelineService`. The FSM supports transitions from Enrolled or Allotted → Withdrawn.

**Refund Processing:** The `processRefund()` method sets `refund_status = 'Paid'`, `refund_processed_at = now()`, and `processed_by = auth user`. Refund eligibility is calculated at withdrawal time based on the admission cycle's `refund_policy_json`.

## Workflow

1. Allotment is created from a merit list entry with seat capacity locking
2. Offer letter PDF is generated and attached to the allotment
3. Candidate accepts or declines the offer (acceptance required before enrollment)
4. If declined, seat is freed (seats_allotted decremented)
5. If accepted, staff proceeds to enrollment form
6. Staff confirms enrollment → 14-step atomic process creates the student record
7. System creates user account, student profile, academic session, sibling links
8. Allotment, application, merit list entry, and seat capacity are all updated
9. If the student later withdraws, a withdrawal record is created and refund processed

## Related Screens

- **Assessment (Merit Lists)** — Source of shortlisted candidates for allotment
- **Applications** — Application records linked to allotments
- **Allotment Show** — Detail view with accept/decline/enrollment actions
- **Enrollment Form** — Pre-filled form for creating student record
- **Withdrawal Show** — Detail view with refund processing
- **Offer Letter PDF** — Generated DomPDF document

## Requirements

- MUST display paginated allotments at `/admission/allotment-enrollment` (default tab) with search and active filter
- MUST display paginated withdrawals at `/admission/allotment-enrollment?tab=withdrawals`
- MUST authorize via `tenant.adm-allotment.*`, `tenant.adm-enrollment.create`, and `tenant.adm-withdrawal.*` gates
- MUST validate store allotment with 11 rules including admission_no uniqueness
- MUST lock seat_capacity row with lockForUpdate on allotment creation
- MUST increment seats_allotted on store, decrement on decline
- MUST generate admission_no in {YEAR}/{SEQ} format, checking both adm_allotments and std_students
- MUST generate offer letter PDF via DomPDF, store in sys_media
- MUST enforce guard checks on enrollment (Accepted status, fee paid, not already enrolled)
- MUST execute 14-step enrollment atomically in a DB transaction
- MUST create cross-module records: sys_users, std_students, std_student_academic_sessions, std_siblings_jnt
- MUST transition application to Enrolled via AdmissionPipelineService
- MUST update merit_list_entry status on enrollment
- MUST increment seats_enrolled on enrollment
- MUST support offer accept (Offered→Accepted) and decline (Offered→Declined)
- MUST soft-delete allotments unless status is Enrolled
- MUST soft-delete withdrawals unless refund is Paid
- MUST support AJAX toggle-status for both allotments and withdrawals
- MUST process refunds with status=Paid, timestamp, and processor
- MUST log all CRUD, enrollment, and refund operations via activityLog()
