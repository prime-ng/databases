# FrontOffice (FOF) — Requirement Traceability Matrix (module roll-up)

> Screen/Requirement → Business Condition (BC) → Test Case (TC) → test method → status, rolled up across the 16 features.
> Per-TC granularity lives in each feature's `fof_{Feature}TcList_Require.md` (BC + TC list + Method Index + Manual Steps) and `fof_{Feature}GAPANALYSIS_Require.md` (TC↔method coverage). This roll-up gives the per-feature traceability envelope and points to the authoritative per-row tables rather than restating ~700 rows.
> Chain integrity rule applied per feature: **every requirement/screen element has ≥1 BC; every BC has ≥1 TC; every TC maps to ≥1 `test*` method; every method's status is recorded.** No orphan requirement, no orphan test.

## Status legend
- **Covered** = TC maps to a method with a real end-to-end assertion (Full).
- **Covered (Partial/env-gated)** = method asserts at DB/model layer now; browser/route dimension executes once FrontOffice is enabled.
- **Documented gap** = no method by design (source unreachable or single-tenant env) — raised as a defect, not silently dropped.

## Per-feature traceability envelope

| # | Feature (screen) | Primary table(s) | Controller(s) | BCs | TCs | Methods | Requirement→BC→TC→Method chain | Authoritative row table |
|---|------------------|------------------|---------------|:---:|:---:|:------:|--------------------------------|-------------------------|
| 1 | VisitorManagement (visitor-management) | fof_visitors, fof_visitor_purposes | Visitor, VisitorPurpose | full | 42 | 42 | complete; 7 positive Partial (env) | `VisitorManagement/fof_VisitorManagementTcList_Require.md` + GapAnalysis §1 |
| 2 | GatePass (gate-passes) | fof_gate_passes | GatePass | full | 53 | 51 | complete; SM 9/9 (4 legal+4 illegal+dead-state) | `GatePass/fof_GatePassTcList_Require.md` |
| 3 | EarlyDeparture (early-departures) | fof_early_departures | EarlyDeparture | full | 42 | 42 | complete; 8 positive Partial (env) | `EarlyDeparture/fof_EarlyDepartureTcList_Require.md` |
| 4 | PhoneDiary (phone-diary) | fof_phone_diary | PhoneDiary | full | 39 | 39 | complete; BC-SM 5/5 | `PhoneDiary/fof_PhoneDiaryTcList_Require.md` |
| 5 | PostalDispatch (postal-dispatch) | fof_postal_register, fof_dispatch_register | PostalRegister, DispatchRegister | full | 41 | 49 | complete (2-table compound); SM 6/6; 1 tenancy Partial | `PostalDispatch/fof_PostalDispatchTcList_Require.md` |
| 6 | EmergencyContact (emergency-contacts) | fof_emergency_contacts | EmergencyContact | full | 36 | 37 | complete; simplest CRUD | `EmergencyContact/fof_EmergencyContactTcList_Require.md` |
| 7 | Circular (circulars) | fof_circulars, fof_circular_distributions | Circular | full | 49 | 42 | complete; SM 7/7; distribution partial (BUG-FOF-002) | `Circular/fof_CircularTcList_Require.md` |
| 8 | NoticesEvents (notices-events) | fof_notices, fof_school_events | NoticeBoard, SchoolEvent | full | 46 | 61 | complete (2-table compound); BC-SM 4/4 | `NoticesEvents/fof_NoticesEventsTcList_Require.md` |
| 9 | CertificateRequest (certificate-requests) | fof_certificate_requests | CertificateRequest | full | 41 | 37 | complete; BC-SM 8/8; fee-gate remediated | `CertificateRequest/fof_CertificateRequestTcList_Require.md` |
| 10 | Complaint (complaints) | fof_complaints | Complaint | full | 36 | 42 | complete; BC-SM 7/7; 1 tenancy documented gap | `Complaint/fof_ComplaintTcList_Require.md` |
| 11 | Appointment (appointments) | fof_appointments | Appointment | full | 43 | 41 | complete; SM 7/7; slot-overlap remediated | `Appointment/fof_AppointmentTcList_Require.md` |
| 12 | LostFound (lost-found) | fof_lost_found | LostFound | full | 50 | 45 | complete; 9 DEV defects traced | `LostFound/fof_LostFoundTcList_Require.md` |
| 13 | KeyRegister (key-register) | fof_key_register | KeyRegister | full | 44 | 53 | complete; SM 5 tested/2 source-gap | `KeyRegister/fof_KeyRegisterTcList_Require.md` |
| 14 | Feedback (feedback) | fof_feedback_forms, fof_feedback_responses | Feedback | full | 41 | 42 | complete; SM 5/5; 1 positive env-guarded | `Feedback/fof_FeedbackTcList_Require.md` |
| 15 | Communication (communication) | fof_communication_logs, fof_sms_logs, fof_email_templates | Communication | full | 56 | 57 | complete; SM 5/5; 10 positive Partial (stub send) | `Communication/fof_CommunicationTcList_Require.md` |
| 16 | ReportsDashboard (reports-dashboard) | read-only across fof_* | FrontOfficeDashboard, FofMenu | full (read) | ~15 | 21 | complete (Light: render/filter/permission/empty-state) | `ReportsDashboard/fof_ReportsDashboardTcList_Require.md` |

**Table coverage:** the 16 features exercise **21 of 22** `fof_*` tables directly. No orphan table (only unwritten sink is `fof_circular_distributions` NTF dispatch — BUG-FOF-002, partially remediated). No orphan requirement or test method across the module.

## BC→TC→Method chain integrity (roll-up assertion)
- **Requirement coverage:** every screen requirement in each feature's `4-Requirement_Module_wise/.../FrontOffice_v1/{screen}.md` maps to ≥1 BC in the feature TcList §"BC list". Verified per feature at generation time.
- **BC→TC:** every BC row carries ≥1 TC id (TC-P/TC-N/TC-D/TC-S/TC-T/BC-SM/TC-DEV). Feature GapAnalysis §1 tables are the authoritative map.
- **TC→Method:** every TC id resolves to ≥1 `test*` method in the feature `_TestCas.php` (701 methods total). Method Index in each TcList is the reverse map.
- **Status:** recorded per method as Full / Partial(env-gated) / Documented-gap in each GapAnalysis. Module rollup: **Negative 100% Full across all 16**; Positive/Dependency ≥90% present all 16; the only non-100% *present* cell is Complaint Tenancy (1 TC documented gap) and KeyRegister SM (2 source-unreachable transitions analysed as defects).

## How to read a full per-row RTM
For any feature, open its two files together:
1. `{Feature}/fof_{Feature}TcList_Require.md` — BC table, TC table (with BC linkage + expected result), Method Index, Manual Steps.
2. `{Feature}/fof_{Feature}GAPANALYSIS_Require.md` — TC→Method coverage matrix (Full/Partial/Gap), Coverage-Score-by-requirement, and Cross-Reference Defect Scan.
The pair constitutes the executable RTM; this roll-up is the module index over them.
