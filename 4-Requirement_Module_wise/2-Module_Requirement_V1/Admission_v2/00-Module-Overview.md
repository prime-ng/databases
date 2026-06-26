# Admission Module — Business Requirements Overview

## Module Purpose

The Admission Module manages the complete student lifecycle at a school — from initial enquiry through application, entrance testing, merit ranking, seat allotment, enrollment, promotions between classes, and finally transfer certificates or alumni status upon exit.

This module replaces manual paperwork and spreadsheet-based tracking with a structured digital workflow across 7 phases. It ensures regulatory compliance (RTE 25% quota, NEP 2020 age guidelines), accurate fee handling, and a complete audit trail for every student's journey.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| Admin / Principal | Admission cycle setup, quota configuration, merit list publication, batch promotion |
| Counselor / Front Desk | Lead capture, enquiry management, follow-ups, application verification |
| Finance Team | Fee invoicing, payment reconciliation, refund processing |
| Teachers | Entrance test evaluation, interview scoring, document verification |
| Parents (Public) | Online application submission, document upload, offer acceptance |

---

## Module Screens — Full Inventory (17 Screens)

### Screens Grouped by Sidebar Menu Item

| # | Menu / Page | Tabs Inside | Requirement File |
|---|-------------|-------------|------------------|
| 1 | **Admission Dashboard** | KPIs, charts, tables | [17-Admission-Dashboard.md](./17-Admission-Dashboard.md) |
| 2 | **Setup** | Cycles, Checklist, Quotas, Seats | — (tab-level docs below) |
| 3 | Setup → Cycles (list + inline form) | — | [04-Admission-Cycles.md](./04-Admission-Cycles.md) |
| 4 | Setup → Document Checklist | — | [05-Document-Checklist.md](./05-Document-Checklist.md) |
| 5 | Setup → Quota Config | — | [06-Quota-Config.md](./06-Quota-Config.md) |
| 6 | Setup → Seat Capacity | — | [07-Seat-Capacity.md](./07-Seat-Capacity.md) |
| 7 | **Enquiry Pipeline** | Enquiries, Applications | [16-Enquiry-Pipeline.md](./16-Enquiry-Pipeline.md) |
| 8 | Enquiry → Create/Edit/Show | Follow-ups timeline | (included in 16-Enquiry-Pipeline.md) |
| 9 | Application → Create/Edit/Show | Stage FSM actions | (included in 16-Enquiry-Pipeline.md) |
| 10 | **Assessment** | Entrance Tests, Merit Lists | — (tab-level docs below) |
| 11 | Assessment → Entrance Tests | + show page + marks entry | [08-Entrance-Tests.md](./08-Entrance-Tests.md) |
| 12 | Assessment → Merit Lists | + show page (Ranked + Allotments) | [09-Merit-Lists.md](./09-Merit-Lists.md) |
| 13 | **Allotment & Enrollment** | Allotments, Withdrawals | — (tab-level docs below) |
| 14 | Allotment → List + Show + Offer Letter | — | [10-Allotments.md](./10-Allotments.md) |
| 15 | Withdrawal → List + Show + Refund | — | [11-Withdrawals.md](./11-Withdrawals.md) |
| 16 | Enrollment (Atomic Conversion) | — | [12-Enrollment.md](./12-Enrollment.md) |
| 17 | **Promotions & Alumni** | Batches, Alumni, TCs, Incidents | — (tab-level docs below) |
| 18 | Promotions → Batch (create/edit/list) | — | [01-Promotion-Batch.md](./01-Promotion-Batch.md) |
| 19 | Promotions → Records (AJAX CRUD) | — | [02-Promotion-Records.md](./02-Promotion-Records.md) |
| 20 | Promotions → Batch Confirmation | — | [03-Batch-Confirmation.md](./03-Batch-Confirmation.md) |
| 21 | Alumni tab → List | — | [13-Alumni.md](./13-Alumni.md) |
| 22 | Transfer Certificates → List + Show + PDF | — | [14-Transfer-Certificates.md](./14-Transfer-Certificates.md) |
| 23 | Behavior Incidents → List + Show + Actions | — | [15-Behavior-Incidents.md](./15-Behavior-Incidents.md) |

---

## Core Business Flow

```
Admission Cycle Created
       ↓
Seat Capacity & Quota Defined
       ↓
Document Checklist Published
       ↓
Enquiry/Lead Captured (CRM)
       ↓
Application Submitted (Online or Manual)
       ↓
Documents Verified
       ↓
Entrance Test + Interview (if applicable)
       ↓
Merit List Generated → Allotment → Offer Letter
       ↓
Fee Payment → Enrollment (Atomic: User + Student + Session)
       ↓
[Years Later] Promotion to Next Class
       ↓
[Eventually] Transfer Certificate / Alumni
```

---

## Document Index

| # | File | Screen | Description |
|---|------|--------|-------------|
| — | [00-Module-Overview.md](./00-Module-Overview.md) | — | This file — module overview, flow, dependencies |
| 1 | [01-Promotion-Batch.md](./01-Promotion-Batch.md) | Promotions → Batch List/Create/Edit | Create and manage class-to-class promotion batches |
| 2 | [02-Promotion-Records.md](./02-Promotion-Records.md) | Promotions → Student Records (AJAX) | Per-student promotion mapping within a batch |
| 3 | [03-Batch-Confirmation.md](./03-Batch-Confirmation.md) | Promotions → Confirm/Cancel Batch | Finalize promotions and update student academic sessions |
| 4 | [04-Admission-Cycles.md](./04-Admission-Cycles.md) | Setup → Admission Cycles | Define yearly campaigns with dates, fees, age rules |
| 5 | [05-Document-Checklist.md](./05-Document-Checklist.md) | Setup → Document Checklist | Define mandatory/optional documents per cycle/class |
| 6 | [06-Quota-Config.md](./06-Quota-Config.md) | Setup → Quota Config | Configure RTE/NRI/Staff Ward/General seat quotas |
| 7 | [07-Seat-Capacity.md](./07-Seat-Capacity.md) | Setup → Seat Capacity | Allocate total seats per class for a cycle |
| 8 | [08-Entrance-Tests.md](./08-Entrance-Tests.md) | Assessment → Entrance Tests | Test setups, candidate import, marks entry |
| 9 | [09-Merit-Lists.md](./09-Merit-Lists.md) | Assessment → Merit Lists | Composite score ranking, publish, allotment matching |
| 10 | [10-Allotments.md](./10-Allotments.md) | Allotment → List/Show/Offer Letter | Quota-based seat allotment with accept/decline workflow |
| 11 | [11-Withdrawals.md](./11-Withdrawals.md) | Withdrawal → List/Show/Refund | Record student exit, auto-compute refund eligibility |
| 12 | [12-Enrollment.md](./12-Enrollment.md) | Enrollment Page | Atomic conversion: creates user + student + academic session |
| 13 | [13-Alumni.md](./13-Alumni.md) | Promotions → Alumni Tab | List and flag graduated students as alumni |
| 14 | [14-Transfer-Certificates.md](./14-Transfer-Certificates.md) | Promotions → TC Tab + Show + PDF | Generate TC with verification QR, fee clearance check |
| 15 | [15-Behavior-Incidents.md](./15-Behavior-Incidents.md) | Promotions → Incidents Tab + Show | Log misconduct with severity, corrective actions workflow |
| 16 | [16-Enquiry-Pipeline.md](./16-Enquiry-Pipeline.md) | Enquiry Pipeline Page | CRM: Enquiries list + Applications list + stage FSM |
| 17 | [17-Admission-Dashboard.md](./17-Admission-Dashboard.md) | Admission Dashboard | KPIs, charts, counselor performance, recent leads |

---

## Key Dependencies Between Screens

- An **Admission Cycle** must be created and activated before Enquiries, Applications, Quotas, or Seats can function
- **Seat Capacity** is configured per class per cycle — allotments check against remaining capacity
- **Quota Config** defines reserved percentages — allotments auto-match quota types
- **Document Checklist** is per cycle per class — defines what applicants must upload
- **Enquiries** are independent leads; can be converted to **Applications**
- **Applications** flow through a Finite State Machine: Draft → Submitted → Under_Review → Verified → Shortlisted → Selected
- **Entrance Tests** are associated with a cycle; candidates are imported from **Applications**
- **Merit Lists** are computed from test scores + interview + academic + sibling bonus
- **Allotments** are generated from **Merit Lists** — quota-based matching
- **Enrollment** is the final conversion of an **Allotment** — creates user + student + academic session atomically
- **Withdrawals** can happen pre-enrollment (from allotment) or post-enrollment
- **Promotions** require a valid `from_session` and `to_session` — classes must exist in SchoolSetup
- A **Promotion Batch** must exist before **Promotion Records** can be added
- A **Promotion Record** must have a student, from-section, to-section, and result before it can be saved
- Only **Promoted** records with a **to_class_section_id** are processed during **Batch Confirmation**
- **Batch Confirmation** writes to `std_student_academic_sessions` — cross-module dependency on StudentProfile
- A **Student** must have a current `is_current = true` academic session to appear in the promotion eligible list
- The **from_class** and **to_class** must be valid classes defined in SchoolSetup
- **Transfer Certificates** require fee clearance — cross-module dependency on StudentFee
- **Behavior Incidents** can optionally link to a **Student** or **Transfer Certificate**

---

## Data Tables Reference

| Table | Module | Description |
|-------|--------|-------------|
| `adm_admission_cycles` | Admission | Cycle header — name, status (Active/Closed/Draft), dates, age rules, refund policy |
| `adm_document_checklists` | Admission | Document definitions — name, is_mandatory, cycle_id, class_id |
| `adm_quota_configs` | Admission | Quota type definitions — name, percentage, priority_order, cycle_id |
| `adm_seat_capacities` | Admission | Seat allocation — class_id, cycle_id, quota_type, total_seats, available_seats |
| `adm_enquiries` | Admission | Lead/Enquiry CRM — student_name, contact, class_sought, status, source, counselor_id |
| `adm_enquiry_follow_ups` | Admission | Follow-up activity log — enquiry_id, note, next_follow_up_date, counselor_id |
| `adm_applications` | Admission | Student applications — full_name, status FSM, cycle_id, class_id, quota_type |
| `adm_entrance_tests` | Admission | Test setup — name, cycle_id, date, max_marks, passing_marks |
| `adm_entrance_test_candidates` | Admission | Candidate mapping — test_id, application_id, marks_obtained, rank |
| `adm_merit_lists` | Admission | Merit list header — cycle_id, class_id, status (Draft/Published) |
| `adm_merit_list_entries` | Admission | Ranked entries — merit_list_id, application_id, composite_score, rank, quota_type |
| `adm_allotments` | Admission | Seat allotments — application_id, cycle_id, class_id, quota_type, status (Allotted/Enrolled/Withdrawn) |
| `adm_withdrawals` | Admission | Withdrawal records — allotment_id, reason, refund_amount, status |
| `adm_enrollments` | Admission | Atomic enrollment log — allotment_id, user_id, student_id, academic_session_id |
| `adm_promotion_batches` | Admission | Batch header — from_session, from_class, to_session, to_class, status (Draft/Confirmed), counts |
| `adm_promotion_records` | Admission | Per-student records — student_id, from/to class_section, result, new_roll_no, is_active |
| `adm_transfer_certificates` | Admission | TC records — student_id, issue_date, reason, fee_cleared, pdf_path |
| `adm_behavior_incidents` | Admission | Incident log — student_id, severity, description, status (Open/Reviewed/Closed) |
| `adm_incident_actions` | Admission | Corrective actions — incident_id, action_type (Warning/Suspension/Expulsion), note |
| `std_student_academic_sessions` | StudentProfile | Target for promotions + enrollment — student_id, academic_session_id, class_section_id, roll_no, is_current |
| `sch_class_section_jnt` | SchoolSetup | Class-Section mapping — used for dropdowns |
| `std_students` | StudentProfile | Student master |
| `sys_users` | System | User accounts |
