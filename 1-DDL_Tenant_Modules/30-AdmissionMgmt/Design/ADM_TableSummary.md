# ADM Module — Table Summary
**Module:** Admission Management (`Modules\Admission`)
**Prefix:** `adm_*`
**Total Tables:** 20 | **Database:** tenant_db (per-school)

| # | Table | One-Line Description |
|---|-------|----------------------|
| 1 | `adm_admission_cycles` | Annual admission campaign configuration — cycle dates, fees, seat rules, form URL, refund policy |
| 2 | `adm_document_checklist` | Required document definitions per cycle/class; `is_system=1` rows are global templates seeded at install |
| 3 | `adm_quota_config` | Quota category settings per class per cycle — total seats, RTE reserved seats, fee waiver flag |
| 4 | `adm_seat_capacity` | Running seat counters per class/quota with `seats_allotted` and `seats_enrolled` incremented at runtime |
| 5 | `adm_entrance_tests` | Aptitude/entrance test sessions — schedule, venue, marks, result status per cycle and class |
| 6 | `adm_enquiries` | Raw inbound leads from walk-in, website, or campaign; entry point to the admission funnel |
| 7 | `adm_merit_lists` | Merit list header per cycle + class + quota, storing scoring criteria JSON and publish status |
| 8 | `adm_follow_ups` | CRM follow-up activity log (calls, meetings, SMS) linked to an enquiry with outcome tracking |
| 9 | `adm_applications` | Full admission application — student details, guardian info, address, fee, interview, and status FSM |
| 10 | `adm_application_documents` | Uploaded documents per application mapped to checklist items with verification workflow |
| 11 | `adm_application_stages` | Immutable audit trail of every application status transition — from/to status, staff, timestamp |
| 12 | `adm_entrance_test_candidates` | Applicant registration for a test session — roll number, marks, per-subject breakdown, result |
| 13 | `adm_merit_list_entries` | Individual applicant rankings within a merit list — composite score, component scores, sibling bonus |
| 14 | `adm_allotments` | Seat allotment offer records — admission number, section, offer letter PDF, fee, and enrollment link |
| 15 | `adm_promotion_batches` | Year-end promotion batch header — from/to session and class, criteria config, status (Draft/Confirmed) |
| 16 | `adm_withdrawals` | Withdrawal record with refund eligibility computed from the cycle's refund policy JSON |
| 17 | `adm_promotion_records` | Per-student promotion decision within a batch — result, new section, roll number |
| 18 | `adm_transfer_certificates` | TC issuance log with DomPDF + QR code; self-reference for duplicate re-issue tracking |
| 19 | `adm_behavior_incidents` | Disciplinary incident log per enrolled student; Critical severity auto-notifies principal and parent |
| 20 | `adm_behavior_actions` | Corrective actions taken per incident — Warning through Expulsion, parent meeting outcome |

## Dependency Layers

| Layer | Tables | Key Dependency |
|-------|--------|----------------|
| 1 | `adm_admission_cycles` | `sch_org_academic_sessions_jnt` |
| 2 | `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity`, `adm_entrance_tests` | `adm_admission_cycles`, `sch_classes` |
| 3 | `adm_enquiries`, `adm_merit_lists` | Layer 1 + `std_students`, `sys_users` |
| 4 | `adm_follow_ups`, `adm_applications` | Layer 3 + `sch_classes`, `std_students` |
| 5 | `adm_application_documents`, `adm_application_stages`, `adm_entrance_test_candidates`, `adm_merit_list_entries` | Layer 4 + Layer 2 |
| 6 | `adm_allotments`, `adm_promotion_batches` | Layer 5 + `sch_sections`, `sch_org_academic_sessions_jnt` |
| 7 | `adm_withdrawals`, `adm_promotion_records` | Layer 6 + `sch_class_section_jnt` |
| 8 | `adm_transfer_certificates`, `adm_behavior_incidents` | `std_students` (cross-module) |
| 9 | `adm_behavior_actions` | `adm_behavior_incidents` |

## Cross-Module WRITE Relationships
| Service | Writes To (External Table) | Trigger |
|---------|---------------------------|---------|
| `EnrollmentService::enrollStudent()` | `sys_users`, `std_students`, `std_student_academic_sessions`, `std_siblings_jnt` | Allotment → Enrolled |
| `TransferCertificateService::issue()` | `adm_transfer_certificates.fees_cleared` | FIN confirms clearance |
| `AllotmentService::generateOfferLetter()` | `sys_media` (DomPDF upload) | Offer issued |
| PAY webhook | `adm_applications.application_fee_paid`, `adm_allotments.admission_fee_paid` | Payment confirmed |
