# FrontOffice (FOF) — Feature Inventory

Module: **FrontOffice** · Code **FOF** · Prefix **`fof_`** (verified vs DDL, no divergence) · Scope **tenant-side** · Style **Dusk (browser)**.
Canonical feature list = the 16 screen `.md` files in `4-Requirement_Module_wise/2-Module_Requirement_V1/FrontOffice_v1/`.
All 16 are real screens (none are non-screen docs like `implementation-plan.md`). Each → one `{ModuleFolder}/{Feature}/` artifact set.

**Resolved module folder (reuse verbatim for every feature):**
`/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Testing_Audit/TestCases/FrontOffice`

## Inventory (16 features)

| # | Screen file | Feature (PascalCase) | Primary table | Controller(s) | Prefix | Type | Complexity | Output folder |
|---|-------------|----------------------|---------------|---------------|--------|------|-----------|---------------|
| 1 | visitor-management.md | **VisitorManagement** | fof_visitors (+ fof_visitor_purposes) | VisitorController, VisitorPurposeController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/VisitorManagement/ |
| 2 | gate-passes.md | **GatePass** | fof_gate_passes | GatePassController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/GatePass/ |
| 3 | early-departures.md | **EarlyDeparture** | fof_early_departures | EarlyDepartureController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/EarlyDeparture/ |
| 4 | phone-diary.md | **PhoneDiary** | fof_phone_diary | PhoneDiaryController | fof_ | Dusk/CRUD | CRUD | FrontOffice/PhoneDiary/ |
| 5 | postal-dispatch.md | **PostalDispatch** | fof_postal_register (+ fof_dispatch_register) | PostalRegisterController, DispatchRegisterController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/PostalDispatch/ |
| 6 | emergency-contacts.md | **EmergencyContact** | fof_emergency_contacts | EmergencyContactController | fof_ | Dusk/CRUD | CRUD | FrontOffice/EmergencyContact/ |
| 7 | circulars.md | **Circular** | fof_circulars (+ fof_circular_distributions) | CircularController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/Circular/ |
| 8 | notices-events.md | **NoticesEvents** | fof_notices (+ fof_school_events) | NoticeBoardController, SchoolEventController | fof_ | Dusk/CRUD | CRUD | FrontOffice/NoticesEvents/ |
| 9 | certificate-requests.md | **CertificateRequest** | fof_certificate_requests | CertificateRequestController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/CertificateRequest/ |
| 10 | complaints.md | **Complaint** | fof_complaints | ComplaintController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/Complaint/ |
| 11 | appointments.md | **Appointment** | fof_appointments | AppointmentController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/Appointment/ |
| 12 | lost-found.md | **LostFound** | fof_lost_found | LostFoundController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/LostFound/ |
| 13 | key-register.md | **KeyRegister** | fof_key_register | KeyRegisterController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/KeyRegister/ |
| 14 | feedback.md | **Feedback** | fof_feedback_forms (+ fof_feedback_responses) | FeedbackController | fof_ | Dusk/CRUD+FSM | Workflow | FrontOffice/Feedback/ |
| 15 | communication.md | **Communication** | fof_communication_logs (+ fof_sms_logs, fof_email_templates) | CommunicationController | fof_ | Dusk/Workflow | Workflow | FrontOffice/Communication/ |
| 16 | reports-dashboard.md | **ReportsDashboard** | (read-only across fof_*) | FrontOfficeDashboardController (+ FofMenuController) | fof_ | Dusk/read-focused | Light | FrontOffice/ReportsDashboard/ |

**Table coverage note:** the 16 features exercise 21 of the 22 `fof_*` tables directly. `fof_sms_logs`/`fof_communication_logs`/`fof_email_templates` → Communication; `fof_circular_distributions` → Circular (currently unwritten — BUG-FOF-002). `fof_feedback_responses` → Feedback. No orphan table.

## Controller-cluster grouping (shared-read optimization — output layout unchanged)
Each feature's artifacts always land in its OWN `{Feature}/` folder. Clustering only shares the *reading* of common source (controller/service/models) within one agent run. In FOF the mapping is ~1 controller per screen, so most clusters are singletons; three screens are **compound** (one screen backed by two controllers/tables — read both together). Generate in the order below (masters → children → compound → read-only last).

| Cluster | Feature(s) | Controllers read together | Services in cluster | Notes |
|---------|-----------|---------------------------|---------------------|-------|
| C1 Visitors | VisitorManagement | VisitorController + VisitorPurposeController | VisitorService | Compound (visitors + visitor-purposes lookup master). Do purpose master first (parent FK for visitors). |
| C2 GatePass | GatePass | GatePassController | GatePassService | Singleton. std_students FK. |
| C3 EarlyDeparture | EarlyDeparture | EarlyDepartureController | EarlyDepartureService | Singleton. std_students FK; ATT sync job. |
| C4 PhoneDiary | PhoneDiary | PhoneDiaryController | — | Singleton. |
| C5 Postal/Dispatch | PostalDispatch | PostalRegisterController + DispatchRegisterController | — | Compound (2 tables/2 controllers, 1 screen). |
| C6 EmergencyContact | EmergencyContact | EmergencyContactController | — | Singleton, simplest CRUD. |
| C7 Circular | Circular | CircularController | CircularService | Singleton. Also touches fof_circular_distributions (BUG-FOF-002). |
| C8 Notices/Events | NoticesEvents | NoticeBoardController + SchoolEventController | — | Compound (2 tables/2 controllers, 1 screen). |
| C9 Certificate | CertificateRequest | CertificateRequestController | — | Singleton. std_students FK; fee-gate defect; dup cert_number. |
| C10 Complaint | Complaint | ComplaintController | — | Singleton. cmp_complaints escalation FK. |
| C11 Appointment | Appointment | AppointmentController | — | Singleton. slot-overlap defect. |
| C12 LostFound | LostFound | LostFoundController | — | Singleton. |
| C13 KeyRegister | KeyRegister | KeyRegisterController | — | Singleton. |
| C14 Feedback | Feedback | FeedbackController | — | Singleton. Public token routes + anonymity defect. |
| C15 Communication | Communication | CommunicationController | — | Singleton. Email/SMS/templates/logs. |
| C16 Dashboard | ReportsDashboard | FrontOfficeDashboardController (+ FofMenuController) | — | Read-only; generate LAST; Light coverage set (render/filter/permission/empty-state, no CRUD matrix). |

## Feature-name alias notes
- **VisitorManagement** — app route base is `fof.visitors.*`; the screen also owns the `fof.visitor-purposes.*` lookup master. Feature named after the screen (`visitor-management`), primary table `fof_visitors`. Sub-entity: VisitorPurpose.
- **PostalDispatch** — screen `postal-dispatch` = two separate registers (`fof.postal-register.*` + `fof.dispatch-register.*`). Kept as ONE feature per the one-screen-one-feature rule; test file covers both tables.
- **NoticesEvents** — screen `notices-events` = Notice Board (`fof.notices.*`) + School Events (`fof.school-events.*`). ONE feature, two tables.
- **ReportsDashboard** — screen `reports-dashboard`; app route `fof.dashboard` + `fof.menu.*` (FofMenuController combined menu pages). Read-focused (Light).
- All other 12 features are 1 screen = 1 controller = 1 primary table (clean).

## Environment prerequisite (Rule Card #19)
**FrontOffice is DISABLED** — `"FrontOffice": false` in `prime_testing/modules_statuses.json`. Until enabled, all `/front-office/*` routes return 404. Flag in every feature's Validation Report as an env prerequisite (not a code defect).
