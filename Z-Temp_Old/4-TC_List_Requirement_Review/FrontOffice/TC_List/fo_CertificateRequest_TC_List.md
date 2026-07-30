# fo_CertificateRequest — Test Case List & Business Conditions

**Module:** FrontOffice (CODE `FOF`, prefix `fo_`) · **Feature:** Certificate Requests (Student Certificate Workflow)
**DB scope:** TENANT-side (`fof_certificate_requests`) · **Test style:** Browser Dusk
**Primary table:** `fof_certificate_requests` · **Module URL prefix:** `/front-office/compliance?tab=certificates`
**Test file:** `fo_CertificateRequest_TestCas.php`
**Tab:** Certificates (second tab of Compliance)

Controller: `FofMenuController::compliance()`, `CertificateRequestController`
Model: `CertificateRequest`
Policy: `CertificateRequestPolicy`

Routes: certificates CRUD + approve/reject/issue + toggleStatus + trash/restore/forceDelete + download/print

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `fof_certificate_requests`: id, request_number, student_id (FK), applicant_name, applicant_contact, cert_type (Bonafide/Character/Fee_Paid/Study/TC_Copy/Migration/Conduct/Other), purpose, copies_requested (int, min:1, max:10), is_urgent (boolean), stages_json, cert_number, issued_to, media_id, status (Pending_Approval/Approved/Rejected/Issued/Cancelled), approved_by, approved_at, issued_by, issued_at, rejected_by, rejected_at, rejection_reason, is_active, created_by, updated_by, created_at, updated_at, deleted_at | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` required exists:std_students,id | FR |
| BC-VAL-02 | `cert_type` required in:Bonafide,Character,Fee_Paid,Study,TC_Copy,Migration,Conduct,Other | FR |
| BC-VAL-03 | `purpose` required string max:500 | FR |
| BC-VAL-04 | `copies_requested` required integer min:1 max:10 | FR |
| BC-VAL-05 | `is_urgent` boolean | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `frontoffice.certificate.viewAny` → `frontoffice.certificate.view` | Policy |
| BC-AUTH-02 | create/store gate `frontoffice.certificate.create` | Policy |
| BC-AUTH-03 | update/approve/reject/issue gate `frontoffice.certificate.update` | Policy |
| BC-AUTH-04 | delete gate `frontoffice.certificate.delete` | Policy |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Pending Approval section (warning border, count) + Recent Requests section (paginated) | View |
| BC-BIZ-02 | Card: request_number, date, student name, cert type badge, Urgent badge (red), purpose, copies, Status toggle, Actions | View |
| BC-BIZ-03 | Status badges: Pending (warning), Approved (success), Issued (primary), Rejected (danger) | View |
| BC-BIZ-04 | Cert type badge: info (teal) with str_replace display | View |
| BC-BIZ-05 | Urgent badge: red "Urgent" badge next to cert type | View |
| BC-BIZ-06 | Create modal: student select, cert type, purpose, copies (1-10), is_urgent toggle | View |
| BC-BIZ-07 | Status filter: All/Pending/Approved/Issued/Rejected | View |
| BC-BIZ-08 | Search by student name, request_number | Ctrl |
| BC-BIZ-09 | Empty state: "No certificate requests found" | View |
| BC-BIZ-10 | Status toggle Ajax → JSON success | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-FOCR-P10 | Positive | View | Pending (warning) + Recent sections | Sections | test_fo_cr_10 | Automated |
| TC-FOCR-P11 | Positive | View | Card: request_number, student, cert type badge, urgent badge, purpose, copies, status, actions | Card | test_fo_cr_11 | Automated |
| TC-FOCR-P12 | Positive | View | Cert type badge (info) + Urgent badge (danger red) | Badges | test_fo_cr_12 | Automated |
| TC-FOCR-P13 | Positive | Ctrl | Create certificate request → stored | Created | test_fo_cr_13 | Automated |
| TC-FOCR-P14 | Positive | View | Status filter: All/Pending/Approved/Issued/Rejected | Filter | test_fo_cr_14 | Automated |
| TC-FOCR-P15 | Positive | Ctrl | Approve pending → status=Approved, approved_at set | Approved | test_fo_cr_15 | Automated |
| TC-FOCR-P16 | Positive | Ctrl | Issue approved → status=Issued, issued_at set | Issued | test_fo_cr_16 | Automated |
| TC-FOCR-P17 | Positive | Ctrl | Reject pending → status=Rejected, rejection_reason | Rejected | test_fo_cr_17 | Automated |
| TC-FOCR-P18 | Positive | View | Empty state "No certificate requests found" | Empty | test_fo_cr_18 | Automated |
| TC-FOCR-N19 | Negative | Val | Missing student_id/cert_type → validation error | Error | test_fo_cr_19 | Automated |
| TC-FOCR-N20 | Negative | Val | copies_requested > 10 → max error | Error | test_fo_cr_20 | Automated |
