# FOF — Front Office Module Development Plan
**Version:** 1.0 | **Date:** 2026-03-27 | **Module:** `Modules\FrontOffice`
**Based on:** FOF_FeatureSpec.md + FOF_FrontOffice_Requirement.md v2

---

## Section 1 — Controller Inventory (18 Controllers)

> **Namespace:** `Modules\FrontOffice\App\Http\Controllers`
> **File base:** `Modules/FrontOffice/app/Http/Controllers/`
> **Route prefix:** `front-office/` | **Route name prefix:** `fof.`
> **Default middleware (all authenticated routes):** `['auth', 'tenant', 'EnsureTenantHasModule:FrontOffice']`

---

### 1. `FrontOfficeDashboardController`
**File:** `FrontOfficeDashboardController.php` | **FR:** All (overview)

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office` | `fof.dashboard` | — | `frontoffice.visitor.view` |

Dashboard shows: today's visitor count, pending gate passes, pending cert requests, active keys out, unresolved complaints, pending circulars.

---

### 2. `VisitorController`
**File:** `VisitorController.php` | **FR:** FOF-01

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/visitors` | `fof.visitors.index` | — | `frontoffice.visitor.view` |
| `create` | GET | `front-office/visitors/create` | `fof.visitors.create` | — | `frontoffice.visitor.create` |
| `store` | POST | `front-office/visitors` | `fof.visitors.store` | `RegisterVisitorRequest` | `frontoffice.visitor.create` |
| `show` | GET | `front-office/visitors/{visitor}` | `fof.visitors.show` | — | `frontoffice.visitor.view` |
| `checkout` | PATCH | `front-office/visitors/{visitor}/checkout` | `fof.visitors.checkout` | — | `frontoffice.visitor.checkout` |
| `pass` | GET | `front-office/visitors/{visitor}/pass` | `fof.visitors.pass` | — | `frontoffice.visitor.view` |

**Notes:**
- `pass` returns a print-optimized view (`@media print` CSS, A6 format) — no PDF download
- `checkout` calls `VisitorService::checkoutVisitor()`
- `VisitorPolicy::delete()` blocks delete if purpose has `is_government_visit=1` (BR-FOF-007)

---

### 3. `GatePassController`
**File:** `GatePassController.php` | **FR:** FOF-02

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/gate-passes` | `fof.gate-passes.index` | — | `frontoffice.gate-pass.view` |
| `create` | GET | `front-office/gate-passes/create` | `fof.gate-passes.create` | — | `frontoffice.gate-pass.create` |
| `store` | POST | `front-office/gate-passes` | `fof.gate-passes.store` | `IssueGatePassRequest` | `frontoffice.gate-pass.create` |
| `approve` | PATCH | `front-office/gate-passes/{gatePass}/approve` | `fof.gate-passes.approve` | — | `frontoffice.gate-pass.approve` |
| `reject` | PATCH | `front-office/gate-passes/{gatePass}/reject` | `fof.gate-passes.reject` | — | `frontoffice.gate-pass.approve` |
| `markExited` | PATCH | `front-office/gate-passes/{gatePass}/exit` | `fof.gate-passes.exit` | — | `frontoffice.gate-pass.create` |
| `markReturned` | PATCH | `front-office/gate-passes/{gatePass}/return` | `fof.gate-passes.return` | — | `frontoffice.gate-pass.create` |

**Notes:**
- Index view has tabs: Pending Approvals / Active / History
- `store` calls `GatePassService::createPass()` which dispatches parent NTF for student passes (BR-FOF-003)
- BR-FOF-004 (one active pass per student) enforced in `IssueGatePassRequest`

---

### 4. `EarlyDepartureController`
**File:** `EarlyDepartureController.php` | **FR:** FOF-03

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/early-departures` | `fof.early-departures.index` | — | `frontoffice.early-departure.view` |
| `create` | GET | `front-office/early-departures/create` | `fof.early-departures.create` | — | `frontoffice.early-departure.create` |
| `store` | POST | `front-office/early-departures` | `fof.early-departures.store` | `EarlyDepartureRequest` | `frontoffice.early-departure.create` |

**Notes:**
- `store` calls `EarlyDepartureService::logDeparture()` then `syncAttendance()` synchronously
- On ATT sync failure: flash alert added to session; `EarlyDepartureAttSyncJob` dispatched (3 retries, 60s delay)
- Print slip optimized with `@media print` CSS

---

### 5. `PhoneDiaryController`
**File:** `PhoneDiaryController.php` | **FR:** FOF-04

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/phone-diary` | `fof.phone-diary.index` | — | `frontoffice.visitor.view` |
| `store` | POST | `front-office/phone-diary` | `fof.phone-diary.store` | — (inline validation) | `frontoffice.visitor.create` |
| `update` | PATCH | `front-office/phone-diary/{phoneDiary}` | `fof.phone-diary.update` | — | `frontoffice.visitor.create` |

**Notes:** `update` used to toggle `action_completed = 1` when action is resolved.

---

### 6. `PostalRegisterController`
**File:** `PostalRegisterController.php` | **FR:** FOF-05

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/postal-register` | `fof.postal-register.index` | — | `frontoffice.visitor.view` |
| `store` | POST | `front-office/postal-register` | `fof.postal-register.store` | — (inline validation) | `frontoffice.visitor.create` |
| `acknowledge` | PATCH | `front-office/postal-register/{postal}/acknowledge` | `fof.postal-register.acknowledge` | — | `frontoffice.visitor.create` |

**Notes:**
- `acknowledge` sets `acknowledged_at = NOW()`, `acknowledgement_by` — locks the record thereafter (BR-FOF-009)
- Index has Inward/Outward tabs with type-date filter

---

### 7. `DispatchRegisterController`
**File:** `DispatchRegisterController.php` | **FR:** FOF-06

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/dispatch-register` | `fof.dispatch-register.index` | — | `frontoffice.visitor.view` |
| `store` | POST | `front-office/dispatch-register` | `fof.dispatch-register.store` | — (inline validation) | `frontoffice.visitor.create` |

---

### 8. `CircularController`
**File:** `CircularController.php` | **FR:** FOF-07

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/circulars` | `fof.circulars.index` | — | `frontoffice.circular.view` |
| `create` | GET | `front-office/circulars/create` | `fof.circulars.create` | — | `frontoffice.circular.create` |
| `store` | POST | `front-office/circulars` | `fof.circulars.store` | `StoreCircularRequest` | `frontoffice.circular.create` |
| `show` | GET | `front-office/circulars/{circular}` | `fof.circulars.show` | — | `frontoffice.circular.view` |
| `update` | PUT | `front-office/circulars/{circular}` | `fof.circulars.update` | `StoreCircularRequest` | `frontoffice.circular.create` |
| `approve` | PATCH | `front-office/circulars/{circular}/approve` | `fof.circulars.approve` | — | `frontoffice.circular.approve` |
| `distribute` | PATCH | `front-office/circulars/{circular}/distribute` | `fof.circulars.distribute` | — | `frontoffice.circular.distribute` |

**Notes:**
- `update` blocked when status is `Approved` or `Distributed` — returns HTTP 403 (BR-FOF-008)
- `distribute` calls `CircularService::distribute()` which creates `fof_circular_distributions` rows in a DB transaction
- No `DELETE` route for `fof_circular_distributions` — append-only log

---

### 9. `NoticeBoardController`
**File:** `NoticeBoardController.php` | **FR:** FOF-08

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/notices` | `fof.notices.index` | — | `frontoffice.notice.view` |
| `store` | POST | `front-office/notices` | `fof.notices.store` | `StoreNoticeRequest` | `frontoffice.notice.create` |
| `update` | PUT | `front-office/notices/{notice}` | `fof.notices.update` | `StoreNoticeRequest` | `frontoffice.notice.create` |
| `destroy` | DELETE | `front-office/notices/{notice}` | `fof.notices.destroy` | — | `frontoffice.notice.delete` |

**Notes:** Emergency notices (`is_emergency=1`) always included in query regardless of `display_until` (BR-FOF-014).

---

### 10. `AppointmentController`
**File:** `AppointmentController.php` | **FR:** FOF-09

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/appointments` | `fof.appointments.index` | — | `frontoffice.visitor.view` |
| `calendar` | GET | `front-office/appointments/calendar` | `fof.appointments.calendar` | — | `frontoffice.visitor.view` |
| `store` | POST | `front-office/appointments` | `fof.appointments.store` | `BookAppointmentRequest` | `frontoffice.visitor.create` |
| `confirm` | PATCH | `front-office/appointments/{appointment}/confirm` | `fof.appointments.confirm` | — | `frontoffice.visitor.create` |
| `cancel` | PATCH | `front-office/appointments/{appointment}/cancel` | `fof.appointments.cancel` | — | `frontoffice.visitor.create` |
| `complete` | PATCH | `front-office/appointments/{appointment}/complete` | `fof.appointments.complete` | — | `frontoffice.visitor.create` |

**Notes:** Calendar uses FullCalendar.js or custom day/week grid; colour-coded by appointment type.

---

### 11. `LostFoundController`
**File:** `LostFoundController.php` | **FR:** FOF-10

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/lost-found` | `fof.lost-found.index` | — | `frontoffice.visitor.view` |
| `store` | POST | `front-office/lost-found` | `fof.lost-found.store` | — (inline validation) | `frontoffice.visitor.create` |
| `claim` | PATCH | `front-office/lost-found/{lostFound}/claim` | `fof.lost-found.claim` | — | `frontoffice.visitor.create` |

---

### 12. `KeyRegisterController`
**File:** `KeyRegisterController.php` | **FR:** FOF-11

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/keys` | `fof.keys.index` | — | `frontoffice.visitor.view` |
| `store` | POST | `front-office/keys` | `fof.keys.store` | — (inline validation) | `frontoffice.visitor.create` |
| `issue` | PATCH | `front-office/keys/{key}/issue` | `fof.keys.issue` | — | `frontoffice.visitor.create` |
| `return` | PATCH | `front-office/keys/{key}/return` | `fof.keys.return` | — | `frontoffice.visitor.create` |

**Notes:** `issue` checks `status = 'Available'` before proceeding; blocks if `Issued` or `Overdue` (BR-FOF-012).

---

### 13. `EmergencyContactController`
**File:** `EmergencyContactController.php` | **FR:** FOF-12

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/emergency-contacts` | `fof.emergency-contacts.index` | — | `frontoffice.emergency-contact.view` |
| `store` | POST | `front-office/emergency-contacts` | `fof.emergency-contacts.store` | — (inline validation) | `frontoffice.emergency-contact.create` |
| `update` | PUT | `front-office/emergency-contacts/{contact}` | `fof.emergency-contacts.update` | — | `frontoffice.emergency-contact.create` |
| `destroy` | DELETE | `front-office/emergency-contacts/{contact}` | `fof.emergency-contacts.destroy` | — | `frontoffice.emergency-contact.create` |

---

### 14. `CertificateRequestController`
**File:** `CertificateRequestController.php` | **FR:** FOF-13

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/certificates` | `fof.certificates.index` | — | `frontoffice.certificate-request.view` |
| `store` | POST | `front-office/certificates` | `fof.certificates.store` | `RequestCertificateRequest` | `frontoffice.certificate-request.create` |
| `show` | GET | `front-office/certificates/{cert}` | `fof.certificates.show` | — | `frontoffice.certificate-request.view` |
| `approve` | PATCH | `front-office/certificates/{cert}/approve` | `fof.certificates.approve` | — | `frontoffice.certificate-request.approve` |
| `reject` | PATCH | `front-office/certificates/{cert}/reject` | `fof.certificates.reject` | — | `frontoffice.certificate-request.approve` |
| `issue` | PATCH | `front-office/certificates/{cert}/issue` | `fof.certificates.issue` | `IssueCertificateRequest` | `frontoffice.certificate-request.issue` |
| `download` | GET | `front-office/certificates/{cert}/download` | `fof.certificates.download` | — | `frontoffice.certificate-request.view` |
| `log` | GET | `front-office/certificates/log` | `fof.certificates.log` | — | `frontoffice.certificate-request.view` |

**Notes:**
- `issue` calls `CertificateIssuanceService::issue()` — checks FIN fee clearance for TC_Copy/Migration (BR-FOF-005)
- `download` streams the PDF from `sys_media` using `media_id`
- `log` shows the issuance audit log (issued certs only)

---

### 15. `ComplaintController`
**File:** `ComplaintController.php` | **FR:** FOF-14

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/complaints` | `fof.complaints.index` | — | `frontoffice.complaint.view` |
| `store` | POST | `front-office/complaints` | `fof.complaints.store` | — (inline validation) | `frontoffice.complaint.create` |
| `show` | GET | `front-office/complaints/{complaint}` | `fof.complaints.show` | — | `frontoffice.complaint.view` |
| `resolve` | PATCH | `front-office/complaints/{complaint}/resolve` | `fof.complaints.resolve` | — | `frontoffice.complaint.view` |
| `escalate` | PATCH | `front-office/complaints/{complaint}/escalate` | `fof.complaints.escalate` | — | `frontoffice.complaint.view` |

**Notes:**
- `escalate` creates a CMP module complaint, sets `cmp_complaint_id`, updates status to `Escalated`

---

### 16. `FeedbackController`
**File:** `FeedbackController.php` | **FR:** FOF-15

| Method | HTTP | URI | Route Name | FormRequest | Middleware | Permission |
|--------|------|-----|-----------|-------------|-----------|------------|
| `index` | GET | `front-office/feedback` | `fof.feedback.index` | — | auth+tenant | `frontoffice.feedback.view` |
| `store` | POST | `front-office/feedback` | `fof.feedback.store` | — | auth+tenant | `frontoffice.feedback.create` |
| `report` | GET | `front-office/feedback/{form}/report` | `fof.feedback.report` | — | auth+tenant | `frontoffice.feedback.view` |
| `publicForm` | GET | `feedback/{token}` | `fof.feedback.public` | — | **none** | — |
| `publicSubmit` | POST | `feedback/{token}` | `fof.feedback.submit` | — | **none** | — |

**Notes:**
- `publicForm` and `publicSubmit` use NO auth middleware — accessible from public URL with token
- `publicSubmit` enforces BR-FOF-010: if `is_anonymous=1`, `respondent_user_id` MUST be NULL

---

### 17. `CommunicationController`
**File:** `CommunicationController.php` | **FR:** FOF-16

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `emailCompose` | GET | `front-office/communication/email/compose` | `fof.communication.email.compose` | — | `frontoffice.communication.email` |
| `emailSend` | POST | `front-office/communication/email/send` | `fof.communication.email.send` | `SendBulkEmailRequest` | `frontoffice.communication.email` |
| `emailTemplates` | GET | `front-office/communication/email/templates` | `fof.communication.email.templates` | — | `frontoffice.communication.email` |
| `emailLogs` | GET | `front-office/communication/email/logs` | `fof.communication.email.logs` | — | `frontoffice.communication.email` |
| `smsSend` | POST | `front-office/communication/sms/send` | `fof.communication.sms.send` | `SendBulkSmsRequest` | `frontoffice.communication.sms` |
| `smsLogs` | GET | `front-office/communication/sms/logs` | `fof.communication.sms.logs` | — | `frontoffice.communication.sms` |

---

### 18. `SchoolEventController`
**File:** `SchoolEventController.php` | **FR:** FOF-17

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|--------|------|-----|-----------|-------------|------------|
| `index` | GET | `front-office/school-events` | `fof.school-events.index` | — | `frontoffice.notice.view` |
| `store` | POST | `front-office/school-events` | `fof.school-events.store` | — (inline validation) | `frontoffice.notice.create` |
| `update` | PUT | `front-office/school-events/{event}` | `fof.school-events.update` | — | `frontoffice.notice.create` |

---

## Section 2 — Service Inventory (5 Services)

> **Namespace:** `Modules\FrontOffice\App\Services`
> **File base:** `Modules/FrontOffice/app/Services/`

---

### Service 1: `VisitorService`
**File:** `VisitorService.php` | **Depends on:** —

```
createVisitor(array $data): Visitor
  └── Generates pass_number VP-YYYYMMDD-NNN (date + 3-digit sequence)
  └── Sets in_time = NOW(), status = 'In'
  └── If vsm_visitor_id provided: pre-populates fields from vsm_visitors record
  └── Returns persisted Visitor model

checkoutVisitor(Visitor $visitor): Visitor
  └── Pre-condition: status must be 'In' or 'Overstay'
  └── Sets out_time = NOW(), status = 'Out'

flagOverstay(): int
  └── Batch UPDATE fof_visitors SET status = 'Overstay'
      WHERE status = 'In' AND out_time IS NULL
  └── Called by fof:flag-overstay Artisan command (scheduled at school closing time)
  └── Returns count of records updated
```

---

### Service 2: `GatePassService`
**File:** `GatePassService.php` | **Depends on:** NTF module (event dispatch)
**Fires:** Parent NTF notification on student pass creation

```
createPass(array $data): GatePass
  └── BR-FOF-004: check no active pass exists for student_id (Pending/Approved/Exited)
  └── Generates pass_number GP-YYYYMMDD-NNN
  └── If person_type = Student: dispatches NTF parent notification, sets parent_notified = 1 (BR-FOF-003)
  └── Sets status = 'Pending_Approval'

approvePass(GatePass $pass, int $approvedBy, ?string $remarks = null): GatePass
  └── Pre-condition: status = 'Pending_Approval'
  └── Sets status = 'Approved', approved_by, approved_at = NOW()
  └── Notifies front desk

rejectPass(GatePass $pass, string $reason, int $rejectedBy): GatePass
  └── Pre-condition: status = 'Pending_Approval'
  └── Sets status = 'Rejected', rejection_reason, approved_by, approved_at = NOW()

markExited(GatePass $pass): GatePass
  └── Pre-condition: status = 'Approved'
  └── Sets status = 'Exited', exit_time = NOW()

markReturned(GatePass $pass): GatePass
  └── Pre-condition: status = 'Exited'
  └── Sets status = 'Returned', actual_return_time = NOW()
```

---

### Service 3: `EarlyDepartureService`
**File:** `EarlyDepartureService.php` | **Depends on:** ATT service (cross-module), NTF module
**Fires:** `EarlyDepartureAttSyncJob` on ATT sync failure

```
logDeparture(array $data): EarlyDeparture
  └── Generates departure_number ED-YYYYMMDD-NNN
  └── Dispatches parent NTF notification
  └── Sets att_sync_status = 'Pending'
  └── Returns persisted EarlyDeparture model

syncAttendance(EarlyDeparture $departure): void
  Step 1: Resolve student_id and departure_time from $departure
  Step 2: Call ATT service: AttendanceService::markAbsentFromPeriod(
              student_id: $departure->student_id,
              date:       $departure->departure_time->toDateString(),
              from_time:  $departure->departure_time
          )
  Step 3: If ATT call succeeds:
            Update: att_sync_status = 'Synced', att_synced_at = NOW()
  Step 4: If ATT call fails (exception or error response):
            Update: att_sync_status = 'Failed'
            Dispatch EarlyDepartureAttSyncJob($departure->id)
              — $tries = 3, $backoff = 60 (seconds)
            Set flash alert in session:
              session()->flash('att_sync_warning',
                "ATT sync failed for {$departure->departure_number}. Retry queued.")
            // BR-FOF-013: silent failure NOT acceptable
            // Front desk sees banner alert on next page load
```

---

### Service 4: `CircularService`
**File:** `CircularService.php` | **Depends on:** NTF module, SchoolSetup (class/section resolution)
**Fires:** NTF email + SMS per recipient on `distribute()`

```
createCircular(array $data): Circular
  └── Generates circular_number CIR-YYYY-NNNN
  └── Sets status = 'Draft'

submitForApproval(Circular $circular): Circular
  └── Pre-condition: status = 'Draft'
  └── Sets status = 'Pending_Approval'
  └── Dispatches NTF to principal/approver

approve(Circular $circular, int $approvedBy): Circular
  └── Sets status = 'Approved', approved_by, approved_at = NOW()
  └── Editing is now LOCKED (BR-FOF-008)

distribute(Circular $circular, int $distributedBy): void
  Step 1: Validate status = 'Approved' (throws if not)
  Step 2: Resolve recipient list from audience:
            Parents/Both:           all parent sys_users with students in target classes
            Staff/Both:             all staff sys_users
            Specific_Class/Section: filter by audience_filter_json class_ids / section_ids
  Step 3: Begin DB transaction
  Step 4: For each resolved recipient:
            - INSERT fof_circular_distributions (status = 'Queued', channel = 'Email')
            - Dispatch NTF email job (queued)
            - If SMS enabled: INSERT fof_circular_distributions (channel = 'SMS')
                              Dispatch NTF SMS job
  Step 5: UPDATE fof_circulars SET status = 'Distributed',
                                   distributed_at = NOW(),
                                   distributed_by = $distributedBy
  Step 6: Commit transaction
  // Note: fof_circular_distributions rows are append-only — no update/delete routes

recall(Circular $circular): Circular
  └── Sets status = 'Recalled' (already-dispatched NTFs cannot be recalled)
```

---

### Service 5: `CertificateIssuanceService`
**File:** `CertificateIssuanceService.php`
**Depends on:** FIN fee-clearance service (TC_Copy/Migration), DomPDF, sys_media
**Fires:** NTF to student/parent on `issue()`

```
requestCertificate(array $data): CertificateRequest
  └── Generates request_number CERT-YYYY-NNNNN
  └── Sets status = 'Pending_Approval'
  └── Notifies approver

approve(CertificateRequest $request, int $approvedBy): CertificateRequest
  └── Sets status = 'Approved'; appends to stages_json
  └── Notifies front desk: ready to issue

issue(CertificateRequest $request, string $issuedTo): CertificateRequest
  Step 1: Verify status = 'Approved' (throws if not)
  Step 2: If cert_type IN ['TC_Copy', 'Migration']:
            Call FIN: FinFeeService::hasOutstandingFees(student_id)
            If outstanding fees exist: throw CertificateFeesOutstandingException (BR-FOF-005)
  Step 3: cert_number = getNextCertNumber($request->cert_type, now()->year)
  Step 4: Load Student + school branding (logo, address, principal signature)
  Step 5: Render DomPDF: view("fof.certificates.{$request->cert_type}")
  Step 6: Store PDF bytes in sys_media → $mediaId
  Step 7: UPDATE fof_certificate_requests:
            cert_number = $certNumber
            media_id    = $mediaId
            issued_at   = NOW()
            issued_by   = auth()->id()
            issued_to   = $issuedTo
            status      = 'Issued'
  Step 8: Dispatch NTF to student/parent: certificate ready for collection

reject(CertificateRequest $request, string $reason, int $rejectedBy): CertificateRequest
  └── Sets status = 'Rejected', rejection_reason; notifies applicant

getNextCertNumber(string $certType, int $year): string
  └── Cert number prefix mapping:
        Bonafide  → BON  | Character → CHAR | Fee_Paid → FEE  | Study → STD
        TC_Copy   → TC   | Migration → MIG  | Conduct  → COND | Other → CERT
  └── Format: {PREFIX}-{YEAR}-{NNN} (3-digit sequence, reset per year per type)
  └── Uses SELECT MAX + parse or separate sequence table for thread-safety
```

---

## Section 3 — FormRequest Inventory (10 FormRequests)

> **Namespace:** `Modules\FrontOffice\App\Http\Requests`
> **File base:** `Modules/FrontOffice/app/Http/Requests/`

| Class | Controller Method | Key Validation Rules |
|-------|------------------|---------------------|
| `RegisterVisitorRequest` | `VisitorController::store` | `visitor_name` required max:100; `visitor_mobile` required regex:/^[0-9]{10,15}$/; `id_proof_type` in ENUM list nullable; `purpose_id` exists:fof_visitor_purposes,id,is_active=1 |
| `IssueGatePassRequest` | `GatePassController::store` | `person_type` in:[Student,Staff]; `student_id` required_if:person_type,Student exists:std_students,id; `staff_user_id` required_if:person_type,Staff exists:sys_users,id; `purpose` in ENUM list; `expected_return_time` after:now nullable; **custom rule:** no active pass for student_id (BR-FOF-004) |
| `EarlyDepartureRequest` | `EarlyDepartureController::store` | `student_id` required exists:std_students,id; `departure_time` required date before_or_equal:now; `reason` in ENUM list; `collecting_person_name` required max:100; `collecting_person_relation` in ENUM list; `collecting_id_proof_type` in ENUM list nullable |
| `StoreCircularRequest` | `CircularController::store/update` | `title` required max:200; `subject` required max:300; `body` required; `audience` in ENUM list; `effective_date` required date; `audience_filter_json` required_if:audience,Specific_Class\|Specific_Section json; `attachment_media_id` exists:sys_media,id nullable |
| `StoreNoticeRequest` | `NoticeBoardController::store/update` | `title` required max:200; `content` required; `category` in ENUM list; `audience` in ENUM list; `display_from` required date; `display_until` after:display_from nullable date; `is_emergency` boolean |
| `BookAppointmentRequest` | `AppointmentController::store` | `appointment_type` in ENUM list; `with_user_id` required exists:sys_users,id; `visitor_name` required; `visitor_mobile` required regex phone; `appointment_date` required date; `start_time` required date_format:H:i; `end_time` required date_format:H:i after:start_time; **custom rule:** no slot conflict for same staff at same datetime range |
| `RequestCertificateRequest` | `CertificateRequestController::store` | `student_id` required exists:std_students,id; `cert_type` in ENUM list; `purpose` required max:200; `copies_requested` integer min:1 max:5 |
| `IssueCertificateRequest` | `CertificateRequestController::issue` | `issued_to` required max:100; `cert_type` in ENUM list (carry-through) |
| `SendBulkEmailRequest` | `CommunicationController::emailSend` | `subject` required max:300; `body` required; `recipient_group` required string; `template_id` exists:fof_email_templates,id nullable |
| `SendBulkSmsRequest` | `CommunicationController::smsSend` | `message` required string max:640 (4 SMS units cap); `recipient_group` required string; **custom rule:** calculate `sms_units = ceil(strlen($message) / 160)` and add to validator bag as warning (BR-FOF-011) |

---

## Section 4 — Blade View Inventory (~60 views)

> **Namespace:** `resources/views/` (within `Modules/FrontOffice/resources/views/`)
> **Layout:** `layouts.fof` (extends app shell with front-office sidebar)

### Dashboard (1 view)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/dashboard.blade.php` | `fof.dashboard` | Today's snapshot: visitor count, pending passes, pending certs, active keys, unresolved complaints |

### Visitors (3 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/visitors/index.blade.php` | `fof.visitors.index` | Visitor register with date filter, search, status badge (In/Out/Overstay); checkout inline |
| `fof/visitors/create.blade.php` | `fof.visitors.create` | Registration form with webcam photo capture; Aadhar last-4 masking |
| `fof/visitors/pass.blade.php` | `fof.visitors.pass` | **Print-optimized** A6 visitor pass: pass number, visitor name, in_time, valid_until, school logo; `@media print` CSS; no PDF |

### Gate Passes (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/gate-passes/index.blade.php` | `fof.gate-passes.index` | Tabs: Pending Approvals / Active / History; approve/reject inline with Alpine.js modal |
| `fof/gate-passes/create.blade.php` | `fof.gate-passes.create` | Issue pass form; Student/Staff toggle; student lookup autocomplete; BR-FOF-004 validation |

### Early Departures (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/early-departures/index.blade.php` | `fof.early-departures.index` | Today's early departures; ATT sync status badge (Pending/Synced/Failed with retry CTA) |
| `fof/early-departures/create.blade.php` | `fof.early-departures.create` | Departure form; print slip trigger after store |

### Phone Diary (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/phone-diary/index.blade.php` | `fof.phone-diary.index` | Call log with Incoming/Outgoing filter; action-required highlight; mark resolved inline |
| `fof/phone-diary/_form.blade.php` | (partial) | Inline create form embedded in index page |

### Postal Register (1 view)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/postal/index.blade.php` | `fof.postal-register.index` | Inward/Outward tabs; acknowledge button locks row after click; tracking number display |

### Dispatch Register (1 view)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/dispatch/index.blade.php` | `fof.dispatch-register.index` | Dispatch log with DSP-YYYY-NNNN numbering; mode and document type filters |

### Circulars (3 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/circulars/index.blade.php` | `fof.circulars.index` | List with status badges; tabs: Draft / Pending / Approved / Distributed |
| `fof/circulars/editor.blade.php` | `fof.circulars.create` | Rich text editor (Quill/TinyMCE); audience picker with class/section filter when Specific_*; attachment upload |
| `fof/circulars/show.blade.php` | `fof.circulars.show` | Circular detail; approve/distribute buttons per status; distribution stats table |

### Notice Board (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/notices/index.blade.php` | `fof.notices.index` | Active notices (pinned first) + archived tab; emergency notices always shown |
| `fof/notices/form.blade.php` | `fof.notices.store` | Notice create/edit form with emergency toggle and display date pickers |

### School Events (1 view)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/events/index.blade.php` | `fof.school-events.index` | Calendar / list toggle; NTF blast button per event |

### Appointments (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/appointments/index.blade.php` | `fof.appointments.index` | List with status filters |
| `fof/appointments/calendar.blade.php` | `fof.appointments.calendar` | Day/week calendar (FullCalendar.js); colour-coded by type; book slot modal |

### Lost & Found (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/lost-found/index.blade.php` | `fof.lost-found.index` | Unclaimed/Claimed/Disposed filter; photo thumbnail |
| `fof/lost-found/create.blade.php` | `fof.lost-found.store` | Register found item form with photo upload |

### Key Register (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/keys/index.blade.php` | `fof.keys.index` | Key list with status badges (Available/Issued/Overdue/Lost); issue/return actions inline |
| `fof/keys/create.blade.php` | `fof.keys.store` | Add new key master record form |

### Emergency Contacts (1 view)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/emergency/index.blade.php` | `fof.emergency-contacts.index` | Grouped by contact_type; quick-call numbers; CRUD inline |

### Certificates (3 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/certificates/index.blade.php` | `fof.certificates.index` | Request queue; status tabs: Pending / Approved / Issued; urgent flag highlight |
| `fof/certificates/show.blade.php` | `fof.certificates.show` | Request detail; issue button + issued_to input; PDF preview panel if issued; FIN fee warning for TC/Migration |
| `fof/certificates/log.blade.php` | `fof.certificates.log` | Issuance log with cert_number, issued_to, issued_at, download link |

### Complaints (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/complaints/index.blade.php` | `fof.complaints.index` | Complaint list; urgency colour-coding; escalate to CMP button |
| `fof/complaints/show.blade.php` | `fof.complaints.show` | Complaint detail with resolution notes; escalation link |

### Feedback (2 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/feedback/index.blade.php` | `fof.feedback.index` | Form list with token URL display; response count; report link |
| `fof/feedback/public.blade.php` | `fof.feedback.public` | **No auth** — token URL; anonymous checkbox; MCQ/rating/text question rendering |

### Communication (4 views)
| View | Route Name | Description |
|------|-----------|-------------|
| `fof/communication/email-compose.blade.php` | `fof.communication.email.compose` | Email compose: template picker, recipient group selector, rich text body, send preview |
| `fof/communication/email-templates.blade.php` | `fof.communication.email.templates` | Email template list with CRUD |
| `fof/communication/sms-compose.blade.php` | `fof.communication.sms.send` | SMS compose: live character counter with multi-unit indicator (BR-FOF-011); recipient group |
| `fof/communication/logs.blade.php` | `fof.communication.email.logs` | Bulk send audit log; per-recipient delivery status drill-down |

### Shared Partials (~5 partials)
| Partial | Description |
|---------|-------------|
| `fof/_partials/pagination.blade.php` | Standard pagination consistent with tenant UI |
| `fof/_partials/status-badge.blade.php` | Colour-coded status badge component |
| `fof/_partials/print-slip.blade.php` | `@media print` CSS reset + school logo header for pass slips |
| `fof/_partials/approval-buttons.blade.php` | Approve/Reject Alpine.js modal reused across gate pass, circular, certificate |
| `fof/_partials/att-sync-warning.blade.php` | Flash banner for ATT sync failure (BR-FOF-013) |

---

## Section 5 — Complete Route List

### Web Routes (`routes/web.php` inside module)
All authenticated routes use: `middleware(['auth', 'tenant', 'EnsureTenantHasModule:FrontOffice'])`

| Method | URI | Route Name | Controller@Method | FR |
|--------|-----|-----------|------------------|----|
| GET | `front-office` | `fof.dashboard` | `FrontOfficeDashboardController@index` | — |
| GET | `front-office/visitors` | `fof.visitors.index` | `VisitorController@index` | FOF-01 |
| GET | `front-office/visitors/create` | `fof.visitors.create` | `VisitorController@create` | FOF-01 |
| POST | `front-office/visitors` | `fof.visitors.store` | `VisitorController@store` | FOF-01 |
| GET | `front-office/visitors/{visitor}` | `fof.visitors.show` | `VisitorController@show` | FOF-01 |
| PATCH | `front-office/visitors/{visitor}/checkout` | `fof.visitors.checkout` | `VisitorController@checkout` | FOF-01 |
| GET | `front-office/visitors/{visitor}/pass` | `fof.visitors.pass` | `VisitorController@pass` | FOF-01 |
| GET | `front-office/gate-passes` | `fof.gate-passes.index` | `GatePassController@index` | FOF-02 |
| GET | `front-office/gate-passes/create` | `fof.gate-passes.create` | `GatePassController@create` | FOF-02 |
| POST | `front-office/gate-passes` | `fof.gate-passes.store` | `GatePassController@store` | FOF-02 |
| PATCH | `front-office/gate-passes/{gatePass}/approve` | `fof.gate-passes.approve` | `GatePassController@approve` | FOF-02 |
| PATCH | `front-office/gate-passes/{gatePass}/reject` | `fof.gate-passes.reject` | `GatePassController@reject` | FOF-02 |
| PATCH | `front-office/gate-passes/{gatePass}/exit` | `fof.gate-passes.exit` | `GatePassController@markExited` | FOF-02 |
| PATCH | `front-office/gate-passes/{gatePass}/return` | `fof.gate-passes.return` | `GatePassController@markReturned` | FOF-02 |
| GET | `front-office/early-departures` | `fof.early-departures.index` | `EarlyDepartureController@index` | FOF-03 |
| GET | `front-office/early-departures/create` | `fof.early-departures.create` | `EarlyDepartureController@create` | FOF-03 |
| POST | `front-office/early-departures` | `fof.early-departures.store` | `EarlyDepartureController@store` | FOF-03 |
| GET | `front-office/phone-diary` | `fof.phone-diary.index` | `PhoneDiaryController@index` | FOF-04 |
| POST | `front-office/phone-diary` | `fof.phone-diary.store` | `PhoneDiaryController@store` | FOF-04 |
| PATCH | `front-office/phone-diary/{phoneDiary}` | `fof.phone-diary.update` | `PhoneDiaryController@update` | FOF-04 |
| GET | `front-office/postal-register` | `fof.postal-register.index` | `PostalRegisterController@index` | FOF-05 |
| POST | `front-office/postal-register` | `fof.postal-register.store` | `PostalRegisterController@store` | FOF-05 |
| PATCH | `front-office/postal-register/{postal}/acknowledge` | `fof.postal-register.acknowledge` | `PostalRegisterController@acknowledge` | FOF-05 |
| GET | `front-office/dispatch-register` | `fof.dispatch-register.index` | `DispatchRegisterController@index` | FOF-06 |
| POST | `front-office/dispatch-register` | `fof.dispatch-register.store` | `DispatchRegisterController@store` | FOF-06 |
| GET | `front-office/circulars` | `fof.circulars.index` | `CircularController@index` | FOF-07 |
| GET | `front-office/circulars/create` | `fof.circulars.create` | `CircularController@create` | FOF-07 |
| POST | `front-office/circulars` | `fof.circulars.store` | `CircularController@store` | FOF-07 |
| GET | `front-office/circulars/{circular}` | `fof.circulars.show` | `CircularController@show` | FOF-07 |
| PUT | `front-office/circulars/{circular}` | `fof.circulars.update` | `CircularController@update` | FOF-07 |
| PATCH | `front-office/circulars/{circular}/approve` | `fof.circulars.approve` | `CircularController@approve` | FOF-07 |
| PATCH | `front-office/circulars/{circular}/distribute` | `fof.circulars.distribute` | `CircularController@distribute` | FOF-07 |
| GET | `front-office/notices` | `fof.notices.index` | `NoticeBoardController@index` | FOF-08 |
| POST | `front-office/notices` | `fof.notices.store` | `NoticeBoardController@store` | FOF-08 |
| PUT | `front-office/notices/{notice}` | `fof.notices.update` | `NoticeBoardController@update` | FOF-08 |
| DELETE | `front-office/notices/{notice}` | `fof.notices.destroy` | `NoticeBoardController@destroy` | FOF-08 |
| GET | `front-office/appointments` | `fof.appointments.index` | `AppointmentController@index` | FOF-09 |
| GET | `front-office/appointments/calendar` | `fof.appointments.calendar` | `AppointmentController@calendar` | FOF-09 |
| POST | `front-office/appointments` | `fof.appointments.store` | `AppointmentController@store` | FOF-09 |
| PATCH | `front-office/appointments/{apt}/confirm` | `fof.appointments.confirm` | `AppointmentController@confirm` | FOF-09 |
| PATCH | `front-office/appointments/{apt}/cancel` | `fof.appointments.cancel` | `AppointmentController@cancel` | FOF-09 |
| PATCH | `front-office/appointments/{apt}/complete` | `fof.appointments.complete` | `AppointmentController@complete` | FOF-09 |
| GET | `front-office/lost-found` | `fof.lost-found.index` | `LostFoundController@index` | FOF-10 |
| POST | `front-office/lost-found` | `fof.lost-found.store` | `LostFoundController@store` | FOF-10 |
| PATCH | `front-office/lost-found/{item}/claim` | `fof.lost-found.claim` | `LostFoundController@claim` | FOF-10 |
| GET | `front-office/keys` | `fof.keys.index` | `KeyRegisterController@index` | FOF-11 |
| POST | `front-office/keys` | `fof.keys.store` | `KeyRegisterController@store` | FOF-11 |
| PATCH | `front-office/keys/{key}/issue` | `fof.keys.issue` | `KeyRegisterController@issue` | FOF-11 |
| PATCH | `front-office/keys/{key}/return` | `fof.keys.return` | `KeyRegisterController@return` | FOF-11 |
| GET | `front-office/emergency-contacts` | `fof.emergency-contacts.index` | `EmergencyContactController@index` | FOF-12 |
| POST | `front-office/emergency-contacts` | `fof.emergency-contacts.store` | `EmergencyContactController@store` | FOF-12 |
| PUT | `front-office/emergency-contacts/{contact}` | `fof.emergency-contacts.update` | `EmergencyContactController@update` | FOF-12 |
| DELETE | `front-office/emergency-contacts/{contact}` | `fof.emergency-contacts.destroy` | `EmergencyContactController@destroy` | FOF-12 |
| GET | `front-office/certificates` | `fof.certificates.index` | `CertificateRequestController@index` | FOF-13 |
| POST | `front-office/certificates` | `fof.certificates.store` | `CertificateRequestController@store` | FOF-13 |
| GET | `front-office/certificates/log` | `fof.certificates.log` | `CertificateRequestController@log` | FOF-13 |
| GET | `front-office/certificates/{cert}` | `fof.certificates.show` | `CertificateRequestController@show` | FOF-13 |
| PATCH | `front-office/certificates/{cert}/approve` | `fof.certificates.approve` | `CertificateRequestController@approve` | FOF-13 |
| PATCH | `front-office/certificates/{cert}/reject` | `fof.certificates.reject` | `CertificateRequestController@reject` | FOF-13 |
| PATCH | `front-office/certificates/{cert}/issue` | `fof.certificates.issue` | `CertificateRequestController@issue` | FOF-13 |
| GET | `front-office/certificates/{cert}/download` | `fof.certificates.download` | `CertificateRequestController@download` | FOF-13 |
| GET | `front-office/complaints` | `fof.complaints.index` | `ComplaintController@index` | FOF-14 |
| POST | `front-office/complaints` | `fof.complaints.store` | `ComplaintController@store` | FOF-14 |
| GET | `front-office/complaints/{complaint}` | `fof.complaints.show` | `ComplaintController@show` | FOF-14 |
| PATCH | `front-office/complaints/{complaint}/resolve` | `fof.complaints.resolve` | `ComplaintController@resolve` | FOF-14 |
| PATCH | `front-office/complaints/{complaint}/escalate` | `fof.complaints.escalate` | `ComplaintController@escalate` | FOF-14 |
| GET | `front-office/feedback` | `fof.feedback.index` | `FeedbackController@index` | FOF-15 |
| POST | `front-office/feedback` | `fof.feedback.store` | `FeedbackController@store` | FOF-15 |
| GET | `front-office/feedback/{form}/report` | `fof.feedback.report` | `FeedbackController@report` | FOF-15 |
| GET | `front-office/communication/email/compose` | `fof.communication.email.compose` | `CommunicationController@emailCompose` | FOF-16 |
| POST | `front-office/communication/email/send` | `fof.communication.email.send` | `CommunicationController@emailSend` | FOF-16 |
| GET | `front-office/communication/email/templates` | `fof.communication.email.templates` | `CommunicationController@emailTemplates` | FOF-16 |
| GET | `front-office/communication/email/logs` | `fof.communication.email.logs` | `CommunicationController@emailLogs` | FOF-16 |
| POST | `front-office/communication/sms/send` | `fof.communication.sms.send` | `CommunicationController@smsSend` | FOF-16 |
| GET | `front-office/communication/sms/logs` | `fof.communication.sms.logs` | `CommunicationController@smsLogs` | FOF-16 |
| GET | `front-office/school-events` | `fof.school-events.index` | `SchoolEventController@index` | FOF-17 |
| POST | `front-office/school-events` | `fof.school-events.store` | `SchoolEventController@store` | FOF-17 |
| PUT | `front-office/school-events/{event}` | `fof.school-events.update` | `SchoolEventController@update` | FOF-17 |

**Total web routes: ~76**

### Public Routes (no auth middleware)
| Method | URI | Route Name | Controller@Method |
|--------|-----|-----------|------------------|
| GET | `feedback/{token}` | `fof.feedback.public` | `FeedbackController@publicForm` |
| POST | `feedback/{token}` | `fof.feedback.submit` | `FeedbackController@publicSubmit` |

### API Routes (`routes/api.php` — prefix `/api/v1/front-office`)
Middleware: `['auth:sanctum', 'tenant']`

| Method | URI | Route Name | Controller@Method | FR |
|--------|-----|-----------|------------------|----|
| GET | `/api/v1/front-office/visitors/today` | `api.fof.visitors.today` | `VisitorController@todayStats` | FOF-01 |
| GET | `/api/v1/front-office/visitors/active` | `api.fof.visitors.active` | `VisitorController@active` | FOF-01 |
| GET | `/api/v1/front-office/gate-passes/pending` | `api.fof.gate-passes.pending` | `GatePassController@pending` | FOF-02 |
| GET | `/api/v1/front-office/early-departures/pending-sync` | `api.fof.early-departures.pending-sync` | `EarlyDepartureController@pendingSync` | FOF-03 |
| GET | `/api/v1/front-office/certificates/pending` | `api.fof.certificates.pending` | `CertificateRequestController@pending` | FOF-13 |
| GET | `/api/v1/front-office/notices/active` | `api.fof.notices.active` | `NoticeBoardController@active` | FOF-08 |
| GET | `/api/v1/front-office/circulars/{circular}/distribution-status` | `api.fof.circulars.dist-status` | `CircularController@distributionStatus` | FOF-07 |
| GET | `/api/v1/front-office/keys/overdue` | `api.fof.keys.overdue` | `KeyRegisterController@overdue` | FOF-11 |
| GET | `/api/v1/front-office/appointments/slots/{userId}/{date}` | `api.fof.appointments.slots` | `AppointmentController@availableSlots` | FOF-09 |
| GET | `/api/v1/front-office/dashboard/snapshot` | `api.fof.dashboard.snapshot` | `FrontOfficeDashboardController@snapshot` | — |
| POST | `/api/v1/front-office/visitors/{visitor}/checkout` | `api.fof.visitors.checkout` | `VisitorController@apiCheckout` | FOF-01 |
| GET | `/api/v1/front-office/school-events/upcoming` | `api.fof.events.upcoming` | `SchoolEventController@upcoming` | FOF-17 |

**Total API routes: 12**
**Grand total: ~90 routes**

---

## Section 6 — Implementation Phases

### Phase 1 — Core Registers
**FRs:** FOF-01, FOF-02, FOF-03, FOF-04, FOF-05, FOF-06
**Cross-module deps:** `sys_users`, `std_students`, `sys_media`, NTF (gate pass parent alert), ATT (early departure sync)

**Files to create:**

| Artifact | File(s) |
|----------|---------|
| Controllers | `FrontOfficeDashboardController`, `VisitorController`, `GatePassController`, `EarlyDepartureController`, `PhoneDiaryController`, `PostalRegisterController`, `DispatchRegisterController`, `EmergencyContactController` |
| Services | `VisitorService`, `GatePassService`, `EarlyDepartureService` |
| Models | `VisitorPurpose`, `Visitor`, `GatePass`, `EarlyDeparture`, `PhoneDiary`, `PostalRegister`, `DispatchRegister`, `EmergencyContact` |
| FormRequests | `RegisterVisitorRequest`, `IssueGatePassRequest`, `EarlyDepartureRequest` |
| Policies | `VisitorPolicy` (blocks delete on govt visit records per BR-FOF-007) |
| Jobs | `EarlyDepartureAttSyncJob` — `$tries = 3`, `$backoff = [60, 120, 300]` (seconds) |
| Commands | `FlagOverstayCommand` — registered as `fof:flag-overstay`; scheduled `daily at('17:00')` in `routes/console.php` |
| Seeders | `FofVisitorPurposeSeeder`, `FofSeederRunner` |
| Views | 13 views (dashboard ×1, visitor ×3, gate pass ×2, early departure ×2, phone diary ×2, postal ×1, dispatch ×1, emergency ×1) |
| Tests | 11 feature tests (see Section 8) |

**Artisan schedule registration (`routes/console.php`):**
```php
Schedule::command('fof:flag-overstay')->dailyAt('17:00');
```

---

### Phase 2 — Communication
**FRs:** FOF-07, FOF-08, FOF-17
**Cross-module deps:** NTF module (circular distribution email/SMS), `sys_media`

| Artifact | File(s) |
|----------|---------|
| Controllers | `CircularController`, `NoticeBoardController`, `SchoolEventController` |
| Services | `CircularService` |
| Models | `Circular`, `CircularDistribution`, `Notice`, `SchoolEvent` |
| FormRequests | `StoreCircularRequest`, `StoreNoticeRequest` |
| Views | 6 views (circular ×3, notice ×2, events ×1) |
| Tests | 5 feature tests |

**Key constraints:**
- No DELETE route for `fof_circular_distributions` — append-only log
- `fof_circulars.update` blocked at HTTP 403 once status = Approved/Distributed

---

### Phase 3 — Certificates & Complaints
**FRs:** FOF-13, FOF-14
**Cross-module deps:** `std_students`, FIN fee-clearance service, `sys_media`, DomPDF, CMP module (escalation)

| Artifact | File(s) |
|----------|---------|
| Controllers | `CertificateRequestController`, `ComplaintController` |
| Services | `CertificateIssuanceService` |
| Models | `CertificateRequest`, `FofComplaint` |
| FormRequests | `RequestCertificateRequest`, `IssueCertificateRequest` |
| DomPDF views | `fof/certificates/templates/bonafide.blade.php`, `character.blade.php`, `tc_copy.blade.php`, `migration.blade.php` (school letterhead per type) |
| Views | 5 views (cert queue ×1, show/issue ×1, log ×1, complaint list ×1, complaint show ×1) |
| Tests | 5 feature tests |

**FIN integration:**
```php
// In CertificateIssuanceService::issue()
if (in_array($request->cert_type, ['TC_Copy', 'Migration'])) {
    if (app(FinFeeService::class)->hasOutstandingFees($request->student_id)) {
        throw new CertificateFeesOutstandingException();
    }
}
```

---

### Phase 4 — Appointments, Lost & Found, Key Management
**FRs:** FOF-09, FOF-10, FOF-11, FOF-12
**Cross-module deps:** `sys_users`, `sys_media` (lost & found photos), NTF (appointment reminders)

| Artifact | File(s) |
|----------|---------|
| Controllers | `AppointmentController`, `LostFoundController`, `KeyRegisterController` |
| Models | `Appointment`, `LostFound`, `KeyRegister` |
| FormRequests | `BookAppointmentRequest` |
| Views | 7 views (appointment calendar ×1, book ×1, lost found ×2, key register ×2, emergency contacts ×1) |
| Tests | 2 feature tests |

---

### Phase 5 — Feedback & Bulk Communication
**FRs:** FOF-15, FOF-16
**Cross-module deps:** NTF module (SMS/email delivery), `sys_users`

| Artifact | File(s) |
|----------|---------|
| Controllers | `FeedbackController`, `CommunicationController` |
| Models | `FeedbackForm`, `FeedbackResponse`, `CommunicationLog`, `EmailTemplate`, `SmsLog` |
| FormRequests | `SendBulkEmailRequest`, `SendBulkSmsRequest` |
| Views | 6 views (feedback forms ×1, public form ×1, email compose ×1, templates ×1, SMS compose ×1, SMS logs ×1) |
| Tests | 4 feature tests |

**Public routes (no auth):**
```php
// In module route file — OUTSIDE the auth middleware group
Route::get('/feedback/{token}', [FeedbackController::class, 'publicForm'])->name('fof.feedback.public');
Route::post('/feedback/{token}', [FeedbackController::class, 'publicSubmit'])->name('fof.feedback.submit');
```

---

## Section 7 — Seeder Execution Order

```bash
# Run module seeders
php artisan module:seed FrontOffice --class=FofSeederRunner

# Execution order:
FofSeederRunner
  └── FofVisitorPurposeSeeder     ← no dependencies; seeds 8 visitor purposes
```

**Minimum required seeder for test database:** `FofVisitorPurposeSeeder`

**Artisan scheduled commands (register in `routes/console.php`):**
```php
Schedule::command('fof:flag-overstay')->dailyAt('17:00');
// Configurable closing time: read from school settings (sys_settings) if available
```

---

## Section 8 — Testing Strategy

**Framework:** Pest (Feature tests) + PHPUnit Unit tests
**Base test class:** `Tests\TestCase` with `RefreshDatabase`

### Test Setup
```php
// Feature test header
uses(Tests\TestCase::class, RefreshDatabase::class);

// Mock strategy per feature:
// ATT service: Mockery::mock(AttendanceService::class) — EarlyDepartureService tests
// FIN fee service: mock(FinFeeService::class) — CertificateIssuanceService TC/Migration tests
// Event::fake() — circular distribution tests (verify NTF dispatch)
// Queue::fake() — EarlyDepartureAttSyncJob tests (verify job dispatched with correct params)
// Storage::fake() — certificate PDF generation tests (DomPDF output to fake disk)
```

### Factory Requirements
```php
// Modules/FrontOffice/database/factories/

VisitorFactory
  → generates pass_number (VP-YYYYMMDD-NNN), in_time = now(), status = 'In'
  → requires fof_visitor_purposes seeded (uses first seeded purpose)

GatePassFactory
  → generates pass_number (GP-YYYYMMDD-NNN), person_type = 'Student', status = 'Pending_Approval'
  → requires std_students factory

CircularFactory
  → generates circular_number (CIR-YYYY-NNNN), status = 'Draft', audience = 'Parents'

CertificateRequestFactory
  → generates request_number (CERT-YYYY-NNNNN), cert_type = 'Bonafide', status = 'Pending_Approval'
  → requires std_students factory
```

### Feature Test Files

| File | Tests | Key Scenarios |
|------|-------|--------------|
| `tests/Feature/FrontOffice/VisitorRegistrationTest.php` | 3 | Visitor stored with pass_number VP-YYYYMMDD-NNN; status = In; mandatory fields validated |
| `tests/Feature/FrontOffice/VisitorCheckoutTest.php` | 2 | Checkout sets out_time + status = Out; already-checked-out returns 422 |
| `tests/Feature/FrontOffice/OverstayFlagTest.php` | 2 | `fof:flag-overstay` sets all In + out_time=null to Overstay; already-out visitors unaffected |
| `tests/Feature/FrontOffice/GovtVisitDeleteBlockTest.php` | 2 | Delete blocked when purpose.is_government_visit=1 (BR-FOF-007); normal visit deletable |
| `tests/Feature/FrontOffice/GatePassCreateTest.php` | 2 | Student pass dispatches NTF; staff pass skips NTF; parent_notified flag set correctly |
| `tests/Feature/FrontOffice/DuplicateGatePassTest.php` | 2 | Second gate pass for same student with Pending/Approved/Exited status returns 422 (BR-FOF-004) |
| `tests/Feature/FrontOffice/GatePassLifecycleTest.php` | 3 | Pending → Approved → Exited → Returned full flow; invalid transitions blocked |
| `tests/Feature/FrontOffice/EarlyDepartureAttSyncTest.php` | 2 | Successful ATT sync sets att_sync_status = Synced; att_synced_at populated |
| `tests/Feature/FrontOffice/EarlyDepartureAttFailTest.php` | 3 | Failed ATT sync sets att_sync_status = Failed; EarlyDepartureAttSyncJob dispatched; session flash alert set (BR-FOF-013) |
| `tests/Feature/FrontOffice/PostalAcknowledgeLockTest.php` | 2 | Acknowledge sets acknowledged_at; subsequent update returns 403 (BR-FOF-009) |
| `tests/Feature/FrontOffice/CircularDraftApproveTest.php` | 3 | Draft → Pending → Approved flow; approved_by + approved_at recorded |
| `tests/Feature/FrontOffice/CircularEditBlockTest.php` | 2 | Edit permitted on Draft/Pending; blocked (HTTP 403) when Approved or Distributed (BR-FOF-008) |
| `tests/Feature/FrontOffice/CircularDistributionTest.php` | 3 | distribute() creates fof_circular_distributions rows; NTF jobs dispatched (Event::fake()); status = Distributed |
| `tests/Feature/FrontOffice/CircularAudienceFilterTest.php` | 2 | Specific_Class audience sends only to Class 5 parents; Staff audience excludes parents |
| `tests/Feature/FrontOffice/NoticeEmergencyBypassTest.php` | 2 | Emergency notice shown when display_until expired; normal notice hidden after expiry (BR-FOF-014) |
| `tests/Feature/FrontOffice/CertificateRequestTest.php` | 2 | Request stored with CERT-YYYY-NNNNN; status = Pending_Approval |
| `tests/Feature/FrontOffice/CertificateFeesBlockTest.php` | 2 | TC_Copy blocked when FIN.hasOutstandingFees = true (BR-FOF-005); Bonafide bypasses fee check |
| `tests/Feature/FrontOffice/CertificateIssuanceTest.php` | 3 | issue() generates cert_number, creates sys_media record (Storage::fake()), sets status = Issued |
| `tests/Feature/FrontOffice/CertificateNumberUniqueTest.php` | 2 | Two Bonafide certs same year get different cert_numbers (BR-FOF-006); UNIQUE constraint respected |
| `tests/Feature/FrontOffice/ComplaintEscalateTest.php` | 2 | Escalate creates CMP complaint; cmp_complaint_id set; status → Escalated |
| `tests/Feature/FrontOffice/AppointmentDoubleBookTest.php` | 2 | Booking same staff + date + overlapping slot returns 422 |
| `tests/Feature/FrontOffice/KeyDoubleIssueTest.php` | 2 | Re-issue of Issued/Overdue key blocked (BR-FOF-012); Available key issued successfully |
| `tests/Feature/FrontOffice/FeedbackAnonymousTest.php` | 2 | Anonymous submission: respondent_user_id = NULL; is_anonymous = 1 (BR-FOF-010) |
| `tests/Feature/FrontOffice/FeedbackPublicTokenTest.php` | 2 | Public form accessible without auth via valid token; invalid token returns 404 |
| `tests/Feature/FrontOffice/BulkEmailSendTest.php` | 2 | Bulk send creates fof_communication_logs; per-recipient delivery rows in expected table |
| `tests/Feature/FrontOffice/SmsMultiPartTest.php` | 2 | SMS > 160 chars calculated as multiple sms_units; unit count returned in validation (BR-FOF-011) |

**Total feature tests: ~55 | Total test files: 26**

### Unit Test Files

| File | Tests | Key Scenarios |
|------|-------|--------------|
| `tests/Unit/FrontOffice/CertNumberFormatTest.php` | 4 | getNextCertNumber() returns correct prefix per cert_type (BON, CHAR, TC, MIG, etc.) |
| `tests/Unit/FrontOffice/AadharMaskingTest.php` | 2 | Blade helper masks Aadhar to last 4 digits; other ID types unmasked (BR-FOF-015) |
| `tests/Unit/FrontOffice/SmsUnitCalcTest.php` | 3 | sms_units = 1 for ≤160; =2 for 161–320; calculation correct at boundary (BR-FOF-011) |
| `tests/Unit/FrontOffice/PassNumberFormatTest.php` | 3 | VP/GP/ED-YYYYMMDD-NNN format correct; sequence resets per day |

**Total unit tests: ~12**

---

## Appendix — Module File Structure

```
Modules/FrontOffice/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── FrontOfficeDashboardController.php
│   │   │   ├── VisitorController.php
│   │   │   ├── GatePassController.php
│   │   │   ├── EarlyDepartureController.php
│   │   │   ├── PhoneDiaryController.php
│   │   │   ├── PostalRegisterController.php
│   │   │   ├── DispatchRegisterController.php
│   │   │   ├── CircularController.php
│   │   │   ├── NoticeBoardController.php
│   │   │   ├── AppointmentController.php
│   │   │   ├── LostFoundController.php
│   │   │   ├── KeyRegisterController.php
│   │   │   ├── EmergencyContactController.php
│   │   │   ├── CertificateRequestController.php
│   │   │   ├── ComplaintController.php
│   │   │   ├── FeedbackController.php
│   │   │   ├── CommunicationController.php
│   │   │   └── SchoolEventController.php
│   │   └── Requests/
│   │       ├── RegisterVisitorRequest.php
│   │       ├── IssueGatePassRequest.php
│   │       ├── EarlyDepartureRequest.php
│   │       ├── StoreCircularRequest.php
│   │       ├── StoreNoticeRequest.php
│   │       ├── BookAppointmentRequest.php
│   │       ├── RequestCertificateRequest.php
│   │       ├── IssueCertificateRequest.php
│   │       ├── SendBulkEmailRequest.php
│   │       └── SendBulkSmsRequest.php
│   ├── Models/
│   │   ├── VisitorPurpose.php
│   │   ├── Visitor.php
│   │   ├── GatePass.php
│   │   ├── EarlyDeparture.php
│   │   ├── PhoneDiary.php
│   │   ├── PostalRegister.php
│   │   ├── DispatchRegister.php
│   │   ├── EmergencyContact.php
│   │   ├── Circular.php
│   │   ├── CircularDistribution.php
│   │   ├── Notice.php
│   │   ├── SchoolEvent.php
│   │   ├── Appointment.php
│   │   ├── LostFound.php
│   │   ├── KeyRegister.php
│   │   ├── CertificateRequest.php
│   │   ├── FofComplaint.php
│   │   ├── FeedbackForm.php
│   │   ├── FeedbackResponse.php
│   │   ├── EmailTemplate.php
│   │   ├── CommunicationLog.php
│   │   └── SmsLog.php
│   ├── Policies/
│   │   └── VisitorPolicy.php          ← blocks delete on govt visit records (BR-FOF-007)
│   └── Services/
│       ├── VisitorService.php
│       ├── GatePassService.php
│       ├── EarlyDepartureService.php
│       ├── CircularService.php
│       └── CertificateIssuanceService.php
├── database/
│   ├── factories/
│   │   ├── VisitorFactory.php
│   │   ├── GatePassFactory.php
│   │   ├── CircularFactory.php
│   │   └── CertificateRequestFactory.php
│   └── seeders/
│       ├── FofVisitorPurposeSeeder.php
│       └── FofSeederRunner.php
├── Jobs/
│   └── EarlyDepartureAttSyncJob.php   ← $tries=3, $backoff=[60,120,300]
├── Console/
│   └── Commands/
│       └── FlagOverstayCommand.php    ← fof:flag-overstay; scheduled daily at 17:00
└── resources/
    └── views/
        ├── layouts/
        │   └── fof.blade.php
        ├── dashboard.blade.php
        ├── visitors/
        │   ├── index.blade.php
        │   ├── create.blade.php
        │   └── pass.blade.php
        ├── gate-passes/
        ├── early-departures/
        ├── phone-diary/
        ├── postal/
        ├── dispatch/
        ├── circulars/
        │   └── templates/             ← DomPDF certificate templates
        │       ├── bonafide.blade.php
        │       ├── character.blade.php
        │       ├── tc_copy.blade.php
        │       └── migration.blade.php
        ├── notices/
        ├── events/
        ├── appointments/
        ├── lost-found/
        ├── keys/
        ├── emergency/
        ├── certificates/
        ├── complaints/
        ├── feedback/
        │   └── public.blade.php       ← no auth; public token URL
        ├── communication/
        └── _partials/
            ├── pagination.blade.php
            ├── status-badge.blade.php
            ├── print-slip.blade.php
            ├── approval-buttons.blade.php
            └── att-sync-warning.blade.php
```
