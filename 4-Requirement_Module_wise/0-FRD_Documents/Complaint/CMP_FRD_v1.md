# Functional Requirements Document (FRD)
# Module: Complaint
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | Complaint |
| **Module Code** | CMP |
| **Document Version** | 1.0 |
| **Date** | 2026-06-27 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI |
| **Reviewed By** | (Pending) |
| **Approved By** | (Pending) |

---

## Section 1 — Module Overview

### 1.1 Business Purpose

Indian schools receive hundreds of grievances every year — parents complaining about teacher conduct, students reporting bullying, transport safety concerns, infrastructure failures, fee disputes, and welfare incidents. Without a structured system, these complaints are handled informally: noted on paper, addressed verbally, or simply forgotten — with no accountability trail and no way to know whether the issue was resolved. The Complaint module provides every school on the Prime-AI platform a ticket-based grievance management system with unique ticket numbers, SLA deadlines, progressive escalation, AI-powered risk scoring, and a full audit trail, ensuring that no complaint goes unresolved or untracked. A school principal can see at a glance which complaints are overdue, which targets are receiving repeated complaints, and which ones carry a safety or welfare risk — enabling proactive, evidence-based school governance.

### 1.2 Business Value

- **Accountability:** Every complaint receives a unique ticket number and is permanently on record; no complaint can be lost or informally dismissed.
- **SLA enforcement:** Each complaint category carries resolution deadlines and progressive escalation thresholds; responsible staff are automatically notified when deadlines approach or are breached.
- **Risk identification:** The built-in AI engine scores every complaint for sentiment, escalation risk, and physical safety risk, alerting leadership to high-risk situations before they escalate.
- **Transparency:** Complainants (students, parents, staff) can track the status of their submission; every action taken is logged in a visible timeline.
- **Compliance readiness:** The module supports CBSE grievance redressal requirements and Indian school welfare regulations, including medical check documentation for physical welfare complaints.
- **Analytics:** Management reports reveal complaint hotspots, SLA breach patterns, and recurring targets — enabling structural improvements, not just reactive fixes.

### 1.3 Scope

#### In Scope

1. Hierarchical complaint category and sub-category setup with per-category SLA timelines and five escalation thresholds
2. Department-specific SLA rules that override category defaults for targeted entities (departments, staff, vehicles, vendors)
3. Complaint registration by school staff, students, and parents with auto-generated ticket numbers, auto-classification, and SLA calculation
4. Complaint assignment to responsible roles or users
5. Complaint status management through the full lifecycle (Open → In-Progress → Resolved / Closed / Rejected)
6. Complaint action timeline — a chronological audit log of every action taken on every complaint
7. Medical check documentation linked to welfare-related complaints
8. AI-powered insight scoring on every complaint: sentiment, escalation risk, and safety risk
9. Analytics dashboard with real-time KPIs, escalation heatmap, and risk charts
10. Five standard reports: Summary & Status, SLA Violation, Pareto Analysis, Complainant Hotspot, and AI Risk & Sentiment
11. Complaint submission from the Student Portal (students and parents)
12. Complaint reopening workflow for dissatisfied complainants
13. Automated escalation level tracking via a scheduled system process

#### Out of Scope

1. **Feedback Collection** — collecting post-resolution satisfaction surveys is a separate sub-module (F.D3.2) not included in this release
2. **Parent Portal direct submission** — the Parent Portal module handles its own submission interface; this module only owns the complaint data
3. **Fee-related disputes** — financial grievances are managed by the StudentFee module
4. **HR disciplinary proceedings** — formal HR action on staff named in complaints is the responsibility of the HrStaff module
5. **Python ML microservice for category prediction** — the current AI engine is rule-based; a machine-learning microservice integration is a future enhancement

### 1.4 Key Terminology

| Business Term | Meaning |
|---------------|---------|
| Complaint Ticket | A registered grievance with a unique system-generated reference number in the format CMP-YYYY-NNNNNN |
| Complainant | The person raising the complaint — may be a student, parent, staff member, vendor, anonymous individual, or a member of the public |
| Target | The person, department, vehicle, or vendor the complaint is raised against |
| Category / Sub-category | A two-level classification that defines the nature of the complaint and the SLA rules that apply to it |
| SLA (Service Level Agreement) | The time commitment for resolving a complaint, measured in hours from the ticket date |
| Escalation Level | A progressive urgency level (0 = Pending, 1–5 = Levels, Breached) calculated from the elapsed time since the ticket date against cumulative SLA thresholds |
| Department SLA | A school-specific override of category SLA rules for a particular target entity (department, staff designation, role, user, vehicle, or vendor) |
| Resolution Due Date | The calculated deadline by which a complaint must be resolved, set automatically at registration time from the applicable SLA rule |
| Action Timeline | The chronological audit log of every action taken on a complaint ticket — creation, assignment, status changes, notes, and resolution |
| AI Insight | System-generated risk scores for every complaint: sentiment (how negative the tone is), escalation risk (likelihood of further escalation), and safety risk (physical safety concern) |
| Sentiment Score | A score from 0 to 1 representing how negative or distressed the complaint description is — higher scores indicate more urgency |
| Escalation Risk Score | A 0–100 composite score indicating the likelihood that a complaint will escalate further, based on complaint severity, frequency, sentiment, and pending time |
| Safety Risk Score | A 0–100 score indicating the level of physical safety concern, based on keywords related to injury, violence, or harassment |
| Hotspot | A target entity (staff member, department, vehicle) accumulating a disproportionate volume of complaints |
| Pareto Analysis | An 80/20 analysis identifying which 20% of complaint categories generate 80% of all complaints |
| Private Note | An action log entry on a complaint that is only visible to School Admin and Principal — not to other staff or the complainant |
| Medical Check | A formal physical examination documented against a welfare-related complaint, capturing the type of check, result, and any evidence |

---

## Section 2 — User Roles & Access

### 2.1 Actor Definitions

| Role | Who They Are | Their Relationship to This Module |
|------|-------------|----------------------------------|
| School Admin | The designated system administrator for the school tenant | Full access: configures categories and SLA rules, manages all complaints, views all reports and dashboards |
| Principal | Head of the school | Views all complaints, manages escalations, approves high-severity resolutions, receives escalation notifications |
| HOD / Department Head | Head of an academic or administrative department | Views complaints filed against their department or its staff; updates complaints assigned to them |
| Class Teacher / Staff | Teaching or non-teaching staff member | Registers complaints; appears as a complaint target; views and updates complaints assigned to them |
| Front Office Staff | Reception or administrative staff who handle walk-in complainants | Registers complaints on behalf of students, parents, or external visitors who approach the front office |
| Student | An enrolled student of the school | Submits complaints through the Student Portal; can track the status of their own complaints |
| Parent | A parent or guardian of an enrolled student | Submits complaints through the Student Portal; can track the status of complaints they filed |
| System (Automated) | Background processes run by the platform | Auto-generates ticket numbers, computes AI insight scores on every complaint save, and updates escalation levels on a scheduled basis |

### 2.2 Role-Feature Access Matrix

| Feature | School Admin | Principal | HOD / Teacher | Front Office Staff | Student / Parent |
|---------|-------------|-----------|--------------|-------------------|-----------------|
| Category Setup | Full Access | View Only | No Access | No Access | No Access |
| Department SLA Setup | Full Access | View Only | No Access | No Access | No Access |
| Register Complaint | Full Access | Full Access | Full Access | Full Access | Self-Submit via Portal |
| View All Complaints | Full Access | Full Access | Own Dept Only | No Access | Own Complaints Only |
| Assign Complaint | Full Access | Full Access | No Access | No Access | No Access |
| Update Complaint Status | Full Access | Full Access | Assigned Only | No Access | No Access |
| View Action Timeline | Full Access | Full Access | Assigned Only | No Access | Own (public notes only) |
| Add Notes to Timeline | Full Access | Full Access | Assigned Only | No Access | No Access |
| Add Private Note | Full Access | Full Access | No Access | No Access | No Access |
| Medical Check Records | Full Access | View Only | No Access | No Access | No Access |
| View AI Insights | Full Access | Full Access | No Access | No Access | No Access |
| Analytics Dashboard | Full Access | Full Access | Limited View | No Access | No Access |
| Reports | Full Access | Full Access | No Access | No Access | No Access |

---

## Section 3 — Functional Requirements

### 3.1 Complaint Category Management

**Requirement ID:** REQ-CMP-001
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION] [DATA_ENTRY]

#### Business Description

School Admin sets up a master list of complaint categories and sub-categories that classify every complaint raised at the school. Each category carries a default SLA (how many hours the school commits to resolving complaints in that category) and up to five progressive escalation thresholds — each with an entity group responsible for receiving escalation notifications. Categories can be organized in a parent-child hierarchy: a parent category (e.g., "Transport") can have multiple sub-categories (e.g., "Rash Driving", "Late Arrival", "Vehicle Condition"). When a complaint is registered, the system automatically inherits the severity level, priority score, and medical check requirement from the selected category.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin
- **Views / Receives notification:** All roles who use the complaint registration screen (category appears in dropdown)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-001 | A category name must be unique within the same parent. Two sub-categories under the same parent category cannot share the same name. | Validation |
| BR-CMP-002 | Escalation hours must be strictly ascending. Escalation Level 1 threshold must be greater than the expected resolution hours; each subsequent escalation level must be greater than the previous one. | Validation |
| BR-CMP-003 | A category that has active child sub-categories cannot be permanently deleted. The admin must remove or reassign child sub-categories first. | Workflow |
| BR-CMP-004 | A category must be deactivated before it can be deleted. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. A School Admin can create a category and assign severity, priority, SLA hours, and up to five escalation thresholds with responsible entity groups
2. The system rejects a category where any escalation threshold is less than or equal to the previous one
3. Attempting to permanently delete a category with child sub-categories shows a clear error message and does not delete the record
4. A deactivated category no longer appears in the complaint registration dropdown
5. A School Admin can soft-delete, view deleted categories in a trash list, and restore a category

#### Integration with Other Modules
- Receives from: GlobalMaster — severity level and priority score lookup values come from the global dropdown master
- Receives from: SchoolSetup — entity groups referenced in escalation thresholds come from school setup
- Sends to: Complaint Registration (REQ-CMP-003) — category selected at registration auto-populates severity, priority, and medical check flag

#### Enhancement Notes (Future)
- Standard category seeder with pre-built CBSE/ICSE category trees (Academic, Infrastructure, Behavioral, Staff Conduct, Health & Safety, Fee-Related) so new schools do not need to configure from scratch

---

### 3.2 Department SLA Configuration

**Requirement ID:** REQ-CMP-002
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION] [DATA_ENTRY]

#### Business Description

Complaint categories carry default SLA timelines, but different departments or individual targets may warrant different response commitments. For example, a transport-related complaint filed against a specific vehicle may need resolution within 4 hours, while the same category complaint filed against a department has a 24-hour SLA. Department SLA Configuration lets School Admin define target-specific SLA overrides: for a given category (and optionally a sub-category), a more specific SLA can be set for a target department, designation, role, entity group, user, vehicle, or vendor. When a complaint is registered, the system checks for a matching Department SLA and uses it; if no match is found, the category default applies.

#### Actors
- **Initiates:** School Admin
- **Processes / Approves:** School Admin
- **Views / Receives notification:** None directly — SLA rules are applied automatically during complaint registration

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-005 | Department SLA escalation hours must be strictly ascending, following the same rule as category SLA. | Validation |
| BR-CMP-006 | When a complaint is registered, the system checks for a Department SLA matching the complaint's category and target entity. If a match is found, it takes precedence over the category default SLA. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. A School Admin can create a Department SLA rule linking a category to a specific target entity type (department, designation, role, vehicle, vendor, or specific user)
2. The system rejects a rule where any escalation hour is not strictly greater than the previous one
3. When a complaint is registered against a target that has a matching Department SLA, the resolution due date is calculated from the Department SLA, not the category default
4. A School Admin can activate, deactivate, soft-delete, and restore Department SLA rules

#### Integration with Other Modules
- Receives from: SchoolSetup — departments, designations, roles, entity groups, and vehicles
- Receives from: Transport — vendors referenced as targets
- Sends to: Complaint Registration — provides the applicable resolution hours used to calculate resolution due date

#### Enhancement Notes (Future)
- None identified at this time

---

### 3.3 Complaint Registration

**Requirement ID:** REQ-CMP-003
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [WORKFLOW] [NOTIFICATION]

#### Business Description

Any authorized user can register a complaint in the system. The complainant provides the nature of the complaint (category and optional sub-category), who the complaint is against (target entity), a title and description, and optional supporting details such as the incident date, location, and an attached photograph. Upon submission, the system automatically generates a unique ticket number, assigns the severity and priority from the selected category, flags whether a medical check is needed, calculates the resolution due date from the applicable SLA rule, and triggers AI processing to compute risk scores. A notification is sent to the School Admin on every new complaint. Students and parents submit complaints through the Student Portal; school staff can register complaints directly from the admin panel.

#### Actors
- **Initiates:** School Admin, Front Office Staff, Class Teacher / Staff, Student (via Portal), Parent (via Portal)
- **Processes / Approves:** System (auto-generates ticket number, AI scores, resolution due date)
- **Views / Receives notification:** School Admin (notification on creation), Principal (high-severity alerts)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-007 | Every complaint must receive a unique ticket number in the format CMP-YYYY-NNNNNN (e.g., CMP-2026-000042). The serial number resets to 000001 at the start of each calendar year. | Validation |
| BR-CMP-008 | If the complainant type is Anonymous or External (Public), a complainant name must be provided and no system user may be linked to the complaint. For all other complainant types, a system user must be linked. | Validation |
| BR-CMP-009 | The complaint's severity level, priority score, and medical check requirement are automatically taken from the selected category at the time of registration. Staff cannot manually enter these fields during complaint creation. | Workflow |
| BR-CMP-010 | The resolution due date is calculated automatically at registration from the Department SLA (if a matching rule exists for the complaint's category and target) or from the category's default expected resolution hours. Staff cannot manually set the resolution due date at creation time. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. Submitting a complaint creates a ticket with a unique reference number in the format CMP-YYYY-NNNNNN
2. The severity level and priority score displayed on the complaint match the values configured in the selected category
3. The resolution due date on the ticket reflects the applicable SLA (Department SLA if matched, otherwise category default)
4. Registering an anonymous complaint requires a complainant name and does not link a system user
5. A notification is sent to School Admin immediately upon complaint creation
6. An AI insight record (sentiment, escalation risk, safety risk) is generated for the complaint within moments of registration
7. Submitting a complaint with an attached photograph stores the image and marks the complaint as having supporting evidence

#### Integration with Other Modules
- Receives from: ComplaintCategory (REQ-CMP-001) — auto-populates severity, priority, medical check flag
- Receives from: DepartmentSLA (REQ-CMP-002) — calculates resolution due date
- Receives from: StudentPortal — students and parents submit via the portal which writes to the complaint records
- Sends to: AI Insight Engine (REQ-CMP-008) — AI processing triggered on every complaint save
- Sends to: Notification module — creation notification sent to School Admin

#### Enhancement Notes (Future)
- WhatsApp or email acknowledgement sent to complainant's registered contact with the ticket number upon submission
- Multi-file attachment support for complaint evidence (currently limited to a single photograph)

---

### 3.4 Complaint Assignment

**Requirement ID:** REQ-CMP-004
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [NOTIFICATION]

#### Business Description

After a complaint is registered and reviewed, School Admin or Principal assigns responsibility for resolving it to a specific role and/or a specific user. The assignment sets the ticket status to In-Progress and moves the complaint into the assignee's work queue. Every assignment is logged in the complaint timeline so there is a clear record of who was responsible at every stage.

#### Actors
- **Initiates:** School Admin, Principal
- **Processes / Approves:** School Admin, Principal
- **Views / Receives notification:** Assigned Role / User (notification of new assignment)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-011 | Every complaint assignment action must be automatically recorded in the complaint timeline with the assigning user's identity, the assigned role/user, and the timestamp. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. A School Admin can assign a complaint to a role and/or a specific user from the complaint detail screen
2. After assignment, the complaint status changes to In-Progress
3. The assignment is recorded in the complaint timeline showing who assigned it, who it was assigned to, and when
4. The assigned user or role receives a notification about the new assignment

#### Integration with Other Modules
- Receives from: SchoolSetup — system roles and users for the assignment dropdown
- Sends to: Notification module — assignment notification to the assigned user/role

#### Enhancement Notes (Future)
- None identified at this time

---

### 3.5 Complaint Resolution & Status Management

**Requirement ID:** REQ-CMP-005
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [NOTIFICATION]

#### Business Description

Throughout its lifecycle, a complaint moves through defined statuses: Open, In-Progress, Resolved, Closed, or Rejected. The assigned handler updates the complaint status as work progresses. Marking a complaint as Resolved requires entering a resolution summary and recording when the issue was resolved and by whom. Every status change is automatically logged in the complaint timeline. Complaints can also be marked as Escalated — a flag indicating that leadership attention is required — without changing the underlying status.

#### Actors
- **Initiates:** Assigned Staff, School Admin
- **Processes / Approves:** School Admin (for closing or rejecting)
- **Views / Receives notification:** Complainant (resolution notification), Principal (escalation notifications)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-012 | A complaint cannot be marked as Resolved without both a resolution note (summary of what was done) and a resolution timestamp (the actual date and time it was resolved). | Validation |
| BR-CMP-013 | Every status change must be automatically recorded in the complaint timeline with the user who made the change, the old status, the new status, and the timestamp. | Workflow |
| BR-CMP-014 | Valid status transitions are: Open → In-Progress; In-Progress → Resolved, Closed, or Rejected; Resolved → Reopened (see REQ-CMP-012). Status cannot be changed backward arbitrarily. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. An authorized user can change the status of a complaint they are assigned to or have permission to manage
2. Attempting to mark a complaint as Resolved without a resolution note displays a clear error and does not save the change
3. Every status change appears in the complaint timeline within seconds
4. The complaint detail screen shows the current status, who it is assigned to, and the resolution due date with a visual indicator if overdue

#### Integration with Other Modules
- Sends to: Notification module — resolution notification to complainant; escalation notification to Principal

#### Enhancement Notes (Future)
- Color-coded SLA status badge on the complaint list showing time remaining or overdue duration

---

### 3.6 Complaint Action Timeline & Audit Log

**Requirement ID:** REQ-CMP-006
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [DATA_ENTRY]

#### Business Description

Every action taken on a complaint — its creation, assignment, status change, resolution, note, escalation — is permanently recorded in a chronological timeline. The timeline is the backbone of accountability: it shows exactly who did what and when throughout the complaint's lifecycle. Authorized staff can also manually add notes (such as investigation findings or interim updates) to the timeline. Private notes can be added that are visible only to School Admin and Principal, allowing sensitive handling notes to be recorded without exposing them to other staff.

#### Actors
- **Initiates:** System (for automatic actions), School Admin, Principal, Assigned Staff (for manual notes)
- **Processes / Approves:** System automatically; no approval required for viewing
- **Views / Receives notification:** School Admin (all actions), Principal (all actions), Assigned Staff (non-private actions), Student/Parent (public-only actions via portal)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-015 | Private notes are visible only to School Admin and Principal. All other roles — including the assigned handler — see only non-private timeline entries. | Permission |
| BR-CMP-016 | The timeline must always be displayed in chronological order from the oldest action to the most recent. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. The complaint detail screen displays the full timeline of all actions in chronological order
2. School Admin can manually add a note to a complaint's timeline, choosing whether it is private or visible to all
3. A staff member who is not a School Admin or Principal cannot see private notes when viewing the timeline
4. System-generated actions (creation, assignment, status changes) appear in the timeline automatically without manual input

#### Integration with Other Modules
- None — the timeline is entirely within the Complaint module

#### Enhancement Notes (Future)
- Embed timeline as a panel within the complaint detail page (currently displayed on a separate screen)

---

### 3.7 Medical Check Linkage

**Requirement ID:** REQ-CMP-007
**Priority:** Standard (P1)
**Category Tags:** [DATA_ENTRY] [WORKFLOW]

#### Business Description

When a complaint involves a physical welfare concern — such as suspected substance use, injury, or a health and safety incident — the complaint category is configured to require a medical check. For such complaints, School Admin or medical staff can record a formal medical examination against the complaint: the type of check conducted, who conducted it, the date and result, any reading value (such as a blood alcohol level), and photographic or documentary evidence. Medical check records are permanently linked to the complaint and visible on the complaint detail screen.

#### Actors
- **Initiates:** School Admin, Medical Staff
- **Processes / Approves:** School Admin
- **Views / Receives notification:** School Admin, Principal

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-017 | A medical check record may only be created for a complaint whose category is configured to require a medical check. The system does not permit medical check entry for complaints where this requirement is not flagged. | Validation |

#### Acceptance Criteria
This feature is considered complete when:
1. A medical check record can be created and linked to an eligible complaint with all required fields (check type, examiner, date, result)
2. Attempting to create a medical check for a complaint whose category does not require one is blocked or warned
3. If supporting evidence (photograph or document) is uploaded, the system records that evidence has been attached
4. The medical check record appears on the complaint detail screen

#### Integration with Other Modules
- None directly — medical check data is self-contained within the Complaint module

#### Enhancement Notes (Future)
- Digital signature capture for the examining officer
- Multi-file attachment support for medical check evidence

---

### 3.8 AI Insight Engine

**Requirement ID:** REQ-CMP-008
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW] [DASHBOARD]

#### Business Description

Every complaint submitted on the Prime-AI platform is automatically analysed by a built-in rules-based intelligence engine. Without any manual input, the engine produces three scores: a sentiment score reflecting how negative or distressed the complaint description is; an escalation risk score predicting the likelihood of the complaint escalating further; and a safety risk score identifying physical welfare or safety concerns based on the language used. These scores are stored as an AI Insight record linked 1:1 with each complaint, and power the analytics dashboard and AI risk reports. The engine runs automatically every time a complaint is created or updated.

#### Actors
- **Initiates:** System (triggered automatically on every complaint save)
- **Processes / Approves:** System
- **Views / Receives notification:** School Admin, Principal (via dashboard and AI Insights screen)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-018 | One AI Insight record exists per complaint. If the complaint is updated, the existing insight record is updated — no duplicate records are created. | Validation |
| BR-CMP-019 | Sentiment scores are in the range 0 to 1 (0 = calm/neutral, 1 = highly negative). Escalation risk and safety risk scores are in the range 0 to 100. | Calculation |

#### Acceptance Criteria
This feature is considered complete when:
1. An AI Insight record exists for every complaint in the system
2. Updating a complaint's description updates the existing insight record rather than creating a new one
3. School Admin can view a paginated list of all complaints with their AI scores, sortable by risk level
4. School Admin can view the detailed AI breakdown for a specific complaint

#### Integration with Other Modules
- None — AI Insight Engine is internal to the Complaint module

#### Enhancement Notes (Future)
- Integration with a Python machine learning microservice for AI category prediction (currently the engine assigns the same category the user selected)
- Hindi/regional language keyword support for sentiment and safety scoring to improve accuracy for Indian school complaints
- Move AI processing to an asynchronous background queue to avoid adding latency to the complaint submission screen

---

### 3.9 Analytics Dashboard

**Requirement ID:** REQ-CMP-009
**Priority:** Standard (P1)
**Category Tags:** [DASHBOARD] [REPORT]

#### Business Description

School Admin and Principal access a real-time dashboard showing the health of the school's complaint management at a glance. The dashboard displays key metrics: open tickets, tickets created today, average resolution time, and the count of SLA breaches. Visual charts show complaint distribution by category, escalation heatmap (category × escalation level), a list of the five most at-risk tickets nearing their SLA breach point, and the five highest-risk tickets by AI escalation risk score. The dashboard is filterable by date range and updates without a full page reload.

#### Actors
- **Initiates:** School Admin, Principal (by visiting the dashboard)
- **Processes / Approves:** System (computes metrics in real time)
- **Views / Receives notification:** School Admin, Principal

#### Business Rules
*(No additional business rules — dashboard data derives from rules defined in other requirements)*

#### Acceptance Criteria
This feature is considered complete when:
1. The dashboard displays a count of open tickets, new tickets today, average resolution time, and SLA breach count
2. The escalation heatmap shows complaint counts across categories and escalation levels (L1–L5 and Breached)
3. The dashboard can be filtered by date range and refreshes without a full page reload
4. The complaint list on the dashboard is paginated and does not load more than 25 tickets per page

#### Integration with Other Modules
- None — all data is sourced from complaint tables within this module

#### Enhancement Notes (Future)
- Sentiment trend chart showing daily average sentiment score over a selected date range
- Recurring target frustration widget identifying target entities with high complaint frequency

---

### 3.10 Reporting Suite

**Requirement ID:** REQ-CMP-010
**Priority:** Standard (P1)
**Category Tags:** [REPORT]

#### Business Description

The module provides five standard reports for School Admin and Principal to analyse complaint patterns, measure SLA performance, and identify problem areas. Reports are filterable and can be exported as PDF or downloaded to Excel for sharing with school management or for compliance submissions.

#### Actors
- **Initiates:** School Admin, Principal
- **Processes / Approves:** System (generates report data)
- **Views / Receives notification:** School Admin, Principal

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-020 | The SLA Violation Report must only include complaints that are currently Open or In-Progress. Resolved, Closed, or Rejected complaints are excluded from this report. | Validation |

#### Acceptance Criteria
This feature is considered complete when:
1. School Admin can open each of the five reports and view data for a selected date range
2. Each report shows accurate data matching complaint records in the system
3. Reports can be exported to PDF or downloaded to Excel
4. The SLA Violation Report only shows open or in-progress tickets

#### Integration with Other Modules
- None — all report data comes from complaint tables within this module

#### Enhancement Notes (Future)
- Grievance Redressal Committee auto-report (CBSE compliance) — auto-generated monthly list of complaints unresolved for more than 30 days

---

### 3.11 Student & Parent Portal Submission

**Requirement ID:** REQ-CMP-011
**Priority:** Standard (P1)
**Category Tags:** [DATA_ENTRY] [WORKFLOW]

#### Business Description

Students and parents have a self-service complaint submission screen within the Student Portal. They can select a category, describe their complaint, choose to submit anonymously, and attach a photograph. Once submitted, the complaint enters the same system as admin-registered tickets, receives a ticket number, and is visible to School Admin. The complainant can see the status of their complaint on their portal dashboard.

#### Actors
- **Initiates:** Student, Parent (via Student Portal)
- **Processes / Approves:** System (ticket number generation, AI scoring)
- **Views / Receives notification:** Student / Parent (status updates), School Admin (creation notification)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-021 | For complaints submitted anonymously, the complainant's name and contact details must be masked in all screens visible to staff other than School Admin and Principal. | Permission |

#### Acceptance Criteria
This feature is considered complete when:
1. A student or parent can submit a complaint from the Student Portal and receive a ticket number confirmation
2. The submitted complaint appears in the admin complaint list immediately
3. An anonymous complaint does not display the complainant's name or contact to staff who are not School Admin or Principal
4. The complainant can see the current status of their complaint on their portal

#### Integration with Other Modules
- Receives from: StudentPortal — complaint submission is initiated within the Student Portal module
- Receives from: StudentProfile — complainant identity linked to the student's profile record

#### Enhancement Notes (Future)
- Parent Portal direct submission (separate from Student Portal)

---

### 3.12 Complaint Reopening

**Requirement ID:** REQ-CMP-012
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW]

#### Business Description

A complaint marked as Resolved can be reopened if the complainant or School Admin is unsatisfied with the resolution or if the issue has recurred. Reopening requires a reason to be documented. The complaint status reverts to In-Progress, the resolution data is cleared, and the reopen reason is permanently logged in the complaint timeline. This ensures that "resolved" tickets cannot be prematurely closed and complainants have a formal escalation path if the issue persists.

#### Actors
- **Initiates:** School Admin, original complainant (via portal)
- **Processes / Approves:** School Admin
- **Views / Receives notification:** Assigned Staff (notification of reopen), School Admin

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-022 | A complaint can only be reopened if its current status is Resolved. Complaints with status Closed or Rejected cannot be reopened. | Validation |
| BR-CMP-023 | Reopening a complaint clears the resolution timestamp, resolution summary, and resolved-by fields, resets the status to In-Progress, and records the reopen reason in the complaint timeline. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. School Admin can reopen a Resolved complaint by providing a reopen reason
2. After reopening, the complaint status shows In-Progress and the resolution fields are cleared
3. The reopen reason and timestamp appear in the complaint timeline
4. Attempting to reopen a Closed or Rejected complaint displays an error and does not change the record

#### Integration with Other Modules
- None

#### Enhancement Notes (Future)
- Allow portal-submitting students/parents to request a reopen (currently only School Admin can initiate)

---

### 3.13 Scheduled Escalation Tracking

**Requirement ID:** REQ-CMP-013
**Priority:** Standard (P1)
**Category Tags:** [SCHEDULED] [NOTIFICATION] [WORKFLOW]

#### Business Description

Escalation levels are time-based: a complaint that has been open for longer than its SLA thresholds automatically moves to a higher escalation level. A scheduled system process runs at regular intervals, checks all open complaints against their SLA thresholds, and updates the escalation level for any that have progressed. When an escalation level increases, the entity groups assigned to that level in the category or department SLA configuration receive an automatic notification. This ensures that overdue complaints are surfaced to the right people without requiring manual monitoring.

#### Actors
- **Initiates:** System (scheduled background process)
- **Processes / Approves:** System
- **Views / Receives notification:** Escalation entity groups (notification on level change), School Admin and Principal (via dashboard)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-CMP-024 | Escalation level is determined by comparing the time elapsed since the ticket date against the complaint's cumulative SLA thresholds. Level 1 is reached when expected resolution hours are exceeded; Level 2 when Level 1 + additional L1 hours are exceeded; and so on through Level 5. A complaint that has exceeded all five thresholds is marked Breached. Resolved or Closed complaints are excluded from escalation level updates. | Calculation |

#### Acceptance Criteria
This feature is considered complete when:
1. The system automatically updates escalation levels for all open complaints that have exceeded their SLA thresholds since the last scheduled run
2. A complaint that crosses an escalation threshold triggers a notification to the entity group configured for that level
3. Resolved or Closed complaints are not processed for escalation updates
4. The updated escalation level is reflected on the complaint detail screen and dashboard

#### Integration with Other Modules
- Receives from: SchoolSetup — entity group membership for escalation notifications
- Sends to: Notification module — escalation threshold notifications

#### Enhancement Notes (Future)
- None

---

### 3.14 Feedback Collection

**Requirement ID:** REQ-CMP-014
**Priority:** Enhanced (P2)
**Category Tags:** [DATA_ENTRY] [WORKFLOW]

#### Business Description

After a complaint is marked as Resolved, the system invites the complainant to submit a satisfaction rating and optional feedback comments on how their complaint was handled. This post-resolution feedback feeds into the school's service quality tracking and can be reviewed by School Admin in a feedback summary. Feedback collection supports the school's continuous improvement goals and is particularly valuable for understanding patterns in complainant satisfaction.

#### Actors
- **Initiates:** System (triggered after complaint resolution)
- **Processes / Approves:** Complainant (submits feedback)
- **Views / Receives notification:** School Admin (feedback summary)

#### Business Rules
*(Business rules to be defined during detailed design of this feature)*

#### Acceptance Criteria
This feature is considered complete when:
1. After a complaint is resolved, the complainant receives an invitation to rate their experience
2. Complainant can submit a 1–5 star rating and optional comments
3. School Admin can view a summary of all feedback received for a date range

#### Integration with Other Modules
- Sends to: Notification module — feedback invitation notification to complainant

#### Enhancement Notes (Future)
- Feedback scores included in the Complainant Hotspot Report to cross-reference resolution quality with complaint volume

---

## Section 4 — Business Rules Register

| Rule ID | Description | Feature | Rule Type | Priority |
|---------|-------------|---------|-----------|----------|
| BR-CMP-001 | A category name must be unique within the same parent. Two sub-categories under the same parent cannot share the same name. | REQ-CMP-001 | Validation | P0 |
| BR-CMP-002 | Escalation hours must be strictly ascending: L1 > expected hours; L2 > L1; L3 > L2; L4 > L3; L5 > L4. | REQ-CMP-001 | Validation | P0 |
| BR-CMP-003 | A category with active child sub-categories cannot be permanently deleted. Child categories must be removed first. | REQ-CMP-001 | Workflow | P0 |
| BR-CMP-004 | A category must be deactivated before it can be deleted. | REQ-CMP-001 | Workflow | P0 |
| BR-CMP-005 | Department SLA escalation hours must be strictly ascending: L1 > expected hours; L2 > L1; and so on. | REQ-CMP-002 | Validation | P0 |
| BR-CMP-006 | A Department SLA matching the complaint's category and target entity takes precedence over the category default SLA for resolution due date calculation. | REQ-CMP-002 | Workflow | P0 |
| BR-CMP-007 | Every complaint must receive a unique ticket number in the format CMP-YYYY-NNNNNN; the serial resets to 000001 each calendar year. | REQ-CMP-003 | Validation | P0 |
| BR-CMP-008 | For Anonymous or External complainant types, complainant name is required and no system user may be linked. For all other types, a system user link is required. | REQ-CMP-003 | Validation | P0 |
| BR-CMP-009 | Severity level, priority score, and medical check requirement are auto-assigned from the selected category; staff cannot manually enter these at complaint creation. | REQ-CMP-003 | Workflow | P0 |
| BR-CMP-010 | Resolution due date is calculated automatically at registration from the applicable SLA; staff cannot manually set it at creation time. | REQ-CMP-003 | Workflow | P0 |
| BR-CMP-011 | Every complaint assignment action must be recorded in the complaint timeline with the assigning user, assignee, and timestamp. | REQ-CMP-004 | Workflow | P0 |
| BR-CMP-012 | A complaint cannot be marked Resolved without both a resolution note and a resolution timestamp. | REQ-CMP-005 | Validation | P0 |
| BR-CMP-013 | Every status change is automatically recorded in the complaint timeline with the user, old status, new status, and timestamp. | REQ-CMP-005 | Workflow | P0 |
| BR-CMP-014 | Valid status transitions: Open → In-Progress; In-Progress → Resolved / Closed / Rejected; Resolved → Reopened. | REQ-CMP-005 | Workflow | P0 |
| BR-CMP-015 | Private notes are visible only to School Admin and Principal; all other roles see only non-private timeline entries. | REQ-CMP-006 | Permission | P0 |
| BR-CMP-016 | The complaint timeline must always be displayed in chronological order (oldest action first). | REQ-CMP-006 | Workflow | P0 |
| BR-CMP-017 | A medical check record may only be created for a complaint whose category is configured to require a medical check. | REQ-CMP-007 | Validation | P1 |
| BR-CMP-018 | One AI Insight record exists per complaint. Re-processing updates the same record; no duplicate records are created. | REQ-CMP-008 | Validation | P1 |
| BR-CMP-019 | Sentiment scores are in the range 0 to 1. Escalation risk and safety risk scores are in the range 0 to 100. | REQ-CMP-008 | Calculation | P1 |
| BR-CMP-020 | The SLA Violation Report includes only Open or In-Progress complaints; Resolved, Closed, and Rejected complaints are excluded. | REQ-CMP-010 | Validation | P1 |
| BR-CMP-021 | For anonymous complaints, the complainant's name and contact details are masked in all screens accessible to staff who are not School Admin or Principal. | REQ-CMP-011 | Permission | P1 |
| BR-CMP-022 | A complaint can only be reopened if its current status is Resolved. Closed or Rejected complaints cannot be reopened. | REQ-CMP-012 | Validation | P1 |
| BR-CMP-023 | Reopening clears the resolution timestamp, summary, and resolver fields; resets status to In-Progress; and logs the reopen reason in the timeline. | REQ-CMP-012 | Workflow | P1 |
| BR-CMP-024 | Escalation level is determined by time elapsed since ticket date vs. cumulative SLA thresholds. Resolved and Closed complaints are excluded from escalation level updates. | REQ-CMP-013 | Calculation | P1 |

---

## Section 5 — Data Requirements

### 5.1 Complaint Category

**What it represents:** The master classification of complaint types used at the school, organized in a parent-child hierarchy (Main Category → Sub-category). Each category carries the default SLA and escalation rules that apply to complaints filed under it.

**Key information captured:**

| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Category Name | The display name of the category (e.g., "Transport", "Rash Driving") | Yes | Must be unique within the same parent |
| Short Code | An optional abbreviation for the category (e.g., "TPT") | No | Unique across all categories if provided |
| Description | A brief explanation of what complaints this category covers | No | Max 512 characters |
| Parent Category | The parent if this is a sub-category; blank if this is a top-level category | No | Self-referencing link |
| Severity Level | The default severity assigned to complaints in this category (Low / Medium / High / Critical) | No | Sourced from the global dropdown master |
| Priority Score | The default priority assigned to complaints in this category (1–5) | No | Sourced from the global dropdown master |
| Expected Resolution Hours | The base SLA — how many hours the school commits to resolving complaints in this category | Yes | Must be a positive whole number |
| Escalation Hours L1–L5 | Five progressive escalation thresholds (additional hours beyond expected, at which point escalation to the next level is triggered) | Yes | Must be strictly ascending |
| Escalation Entity Groups L1–L5 | The group of staff notified when each escalation threshold is crossed | No | Linked to entity groups in school setup |
| Medical Check Required | Whether complaints in this category require a formal medical examination to be documented | No | Boolean; defaults to No |
| Active Status | Whether the category is currently available for use in complaint registration | Yes | Defaults to Active |

**Relationships:**
- Belongs to: Parent Complaint Category (self-referencing; null for top-level)
- Contains: Child Sub-categories
- Referenced by: Complaint Ticket, Department SLA Rule

**Data Retention:**
Categories are soft-deleted and retained indefinitely for historical complaint traceability. Force-delete is only possible when no complaints or child categories reference the record.

**Privacy Classification:** Internal

---

### 5.2 Department SLA Rule

**What it represents:** A target-specific override of the category's default SLA timelines. Defines different resolution commitments and escalation structures for complaints filed against specific departments, designations, roles, vehicles, vendors, or users.

**Key information captured:**

| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Complaint Category | The category this SLA rule applies to | Yes | Must exist in complaint categories |
| Complaint Sub-category | Optional further restriction to a specific sub-category | No | If blank, rule applies to all sub-categories of the category |
| Target Entity Type | The type of target this SLA covers (Department / Designation / Role / Entity Group / User / Vehicle / Vendor) | Yes | At least one target must be specified |
| Target Entity | The specific department, designation, role, entity group, user, vehicle, or vendor | Yes | Varies by target entity type |
| Expected Resolution Hours | The department-specific SLA in hours | Yes | |
| Escalation Hours L1–L5 | Department-specific escalation thresholds | Yes | Strictly ascending |
| Escalation Entity Groups L1–L5 | Groups notified when each escalation threshold is crossed | No | |
| Active Status | Whether this rule is currently in effect | Yes | |

**Relationships:**
- Belongs to: Complaint Category
- References: School departments, designations, roles, entity groups, users, vehicles, vendors

**Data Retention:**
Soft-deleted and retained. Rules are auditable even after deactivation.

**Privacy Classification:** Internal

---

### 5.3 Complaint Ticket

**What it represents:** The core grievance record. Every complaint raised at the school is stored as a Complaint Ticket with its unique reference number, complainant details, target information, classification, status, resolution, and escalation state.

**Key information captured:**

| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Ticket Number | Unique reference in the format CMP-YYYY-NNNNNN | Yes | System-generated; never editable |
| Ticket Date | The date the complaint was registered | Yes | Defaults to today |
| Complainant Type | Category of who is raising the complaint (Student / Parent / Staff / Vendor / Anonymous / Public) | Yes | Determines whether a system user link is required |
| Complainant | The linked system user who raised the complaint | Conditional | Required unless complainant type is Anonymous or External |
| Complainant Name | Free-text name for anonymous or walk-in complainants | Conditional | Required if complainant type is Anonymous or External |
| Complainant Contact | Contact number for anonymous/external complainants | No | |
| Target Type | The type of entity the complaint is against (Staff / Student / Department / Vehicle / Vendor / Facility / etc.) | No | |
| Target | The specific entity the complaint is against | No | Application-level link; no database constraint |
| Target Name | Display name of the target | No | Stored for read performance |
| Category | The complaint category | Yes | Drives auto-population of severity, priority, medical check flag |
| Sub-category | A more specific sub-category | No | |
| Severity Level | Auto-assigned from category | Yes | Not entered manually at registration |
| Priority Score | Auto-assigned from category | Yes | Not entered manually at registration |
| Title | Brief subject of the complaint | Yes | Max 200 characters |
| Description | Detailed account of the complaint | No | Fed into AI sentiment and risk analysis |
| Location | Where the incident occurred | No | |
| Incident Date & Time | When the incident occurred | No | May differ from the ticket date |
| Status | Current lifecycle status (Open / In-Progress / Resolved / Closed / Rejected) | Yes | Initially set to Open by system |
| Assigned To (Role & User) | The staff role and/or individual responsible for resolution | No | Set during complaint assignment |
| Resolution Due Date | The deadline for resolution, calculated from applicable SLA at registration | No | System-calculated; not manually set at creation |
| Actual Resolution Date | The date and time the complaint was actually resolved | Conditional | Required when marking Resolved |
| Resolution Summary | Description of what was done to resolve the complaint | Conditional | Required when marking Resolved |
| Resolved By (Role & User) | Who resolved the complaint | Conditional | Set on resolution |
| Is Escalated | Flag indicating leadership escalation is required | No | Manual flag; independent of the time-based escalation level |
| Escalation Level | Current time-based escalation level (0 = Pending; 1–5 = Level; Breached) | Yes | Updated by scheduled system process |
| Complaint Source | How the complaint was received (App / Web / Email / Walk-in / Phone) | No | |
| Is Anonymous | Whether the complainant chose to submit anonymously | No | Triggers masking rules for non-admin staff |
| Medical Check Required | Whether a medical check must be documented | No | Auto-assigned from category |
| Supporting Evidence | Whether a photograph or file has been attached | No | Boolean flag |

**Relationships:**
- Belongs to: Complaint Category
- Contains: Complaint Actions (timeline entries)
- Has one: AI Insight record
- May have: Medical Check records
- May have: Attached media (photographs)

**Data Retention:**
Complaint tickets are soft-deleted and never permanently removed without explicit force-delete authorization. Retained for a minimum of 5 years for compliance purposes.

**Privacy Classification:** Confidential (contains personal information about complainant and target)

---

### 5.4 Complaint Action (Timeline Entry)

**What it represents:** A single chronological entry in the complaint's audit log. Automatically created by the system on every significant action (registration, assignment, status change, resolution); can also be created manually by authorized staff as a note.

**Key information captured:**

| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Complaint | The complaint this action belongs to | Yes | Links to Complaint Ticket |
| Action Type | The nature of the action (Created / Assigned / Status Changed / Note / Escalated / Resolved / etc.) | Yes | From global dropdown master |
| Performed By | The user who performed the action (blank for system-generated actions) | No | |
| Performed By Role | The role of the user who performed the action | No | |
| Assigned To (User & Role) | The user/role this action assigned the complaint to (for assignment actions) | No | |
| Notes | The text of the action, note, or observation | No | |
| Is Private Note | Whether this entry is restricted to Admin and Principal only | No | Defaults to No |
| Action Timestamp | The date and time this action occurred | Yes | Set automatically by the system |

**Relationships:**
- Belongs to: Complaint Ticket

**Data Retention:**
Timeline entries are permanent and cannot be deleted. They form the official audit trail.

**Privacy Classification:** Internal (Private notes are Confidential)

---

### 5.5 Medical Check Record

**What it represents:** Documentation of a formal physical examination or safety check conducted in connection with a welfare-related complaint. Used to record alcohol tests, drug tests, fitness checks, or other medical assessments.

**Key information captured:**

| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Complaint | The complaint this medical check is linked to | Yes | |
| Check Type | The type of examination (Alcohol Test / Drug Test / Fitness Check / etc.) | Yes | From global dropdown master |
| Conducted By | Name of the examining doctor or officer | No | Free-text name |
| Conducted At | Date and time the examination was carried out | Yes | |
| Result | The outcome of the examination (Positive / Negative / Inconclusive) | Yes | |
| Reading Value | A specific numeric or descriptive reading where applicable (e.g., BAC level) | No | Max 50 characters |
| Remarks | Any additional observations from the examiner | No | |
| Evidence Attached | Whether photographic or documentary evidence has been uploaded | No | Boolean |

**Relationships:**
- Belongs to: Complaint Ticket

**Data Retention:**
Medical check records are sensitive welfare data and must be retained for a minimum of 7 years.

**Privacy Classification:** Sensitive (contains health-related information)

---

### 5.6 AI Insight Record

**What it represents:** The system-generated risk assessment for a complaint, computed by the AI Insight Engine every time the complaint is saved. Stores three risk scores and a sentiment classification, forming a 1:1 record with each complaint.

**Key information captured:**

| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Complaint | The complaint this insight belongs to | Yes | Unique — one insight per complaint |
| Sentiment Score | How negative the complaint description is, on a scale of 0 to 1 | No | Higher = more negative |
| Sentiment Label | A human-readable classification (Calm / Neutral / Urgent / Angry) | No | Derived from sentiment score |
| Escalation Risk Score | Predicted likelihood of further escalation, on a scale of 0 to 100 | No | Based on severity, frequency, sentiment, pending time |
| Predicted Category | The category the AI engine suggests the complaint belongs to | No | Currently mirrors the selected category; will use ML in future |
| Safety Risk Score | Level of physical safety concern, on a scale of 0 to 100 | No | Based on safety-related keywords in description |
| Engine Version | The version of the rules engine used for this analysis | No | Allows future comparison when engine is updated |
| Processed At | The date and time the AI analysis was last run | Yes | |

**Relationships:**
- Belongs to: Complaint Ticket (unique 1:1 relationship)

**Data Retention:**
Insight records follow the same retention rules as the parent complaint.

**Privacy Classification:** Internal

---

## Section 6 — Workflows

### 6.1 Complaint Registration and Resolution Workflow

**Trigger:** A complaint is submitted by any authorized user (admin panel or student portal)
**End State:** The complaint is Resolved (or Closed / Rejected) with a full audit trail

#### Steps

1. **Registration:** Complainant (or Front Office Staff on their behalf) selects a category, provides complaint details, identifies the target entity, and optionally attaches a photograph and enters the incident date/location.
   - System auto-generates ticket number
   - System auto-assigns severity, priority, and medical check flag from category
   - System calculates resolution due date from the applicable SLA rule
   - System sets status to Open
   - System logs "Created" action in the complaint timeline
   - System triggers AI analysis (sentiment, escalation risk, safety risk)
   - System sends creation notification to School Admin

2. **Review:** School Admin or Principal reviews the complaint and decides whether to:
   - Assign it to a responsible role/user → go to step 3
   - Reject it (no valid basis) → go to step 5b

3. **Assignment:** School Admin or Principal assigns the complaint to a responsible role and/or user
   - System changes status to In-Progress
   - System logs "Assigned" action in the complaint timeline
   - System notifies the assigned user/role
   - Decision: If complaint breaches SLA thresholds (time-based) → scheduled process updates escalation level (see Workflow 6.3)

4. **Investigation / Resolution:** Assigned handler investigates, adds notes to the timeline, and resolves the issue
   - Handler can add notes (private or public) at any stage
   - If medical check is required → medical check record created (see REQ-CMP-007)
   - Handler marks complaint as Resolved, enters resolution summary and resolution date

5. **Closure:**
   - **5a Resolved:** Status set to Resolved; timeline logs resolution; complainant notified
     - Decision: If complainant is satisfied → complaint remains Resolved
     - Decision: If complainant is unsatisfied → complainant or Admin reopens complaint (see Workflow 6.2 variant)
   - **5b Rejected:** School Admin rejects complaint; timeline logs rejection with reason; complainant notified
   - **5c Closed:** Admin closes ticket (administrative closure); timeline logged

#### Exception Paths
- If the target entity no longer exists in the system (e.g., a staff member who has left): the target name is stored as free text and the complaint can still be processed
- If no matching Department SLA exists for the complaint category and target: the system falls back to the category default SLA
- If the complainant is anonymous: no complainant notification can be sent; School Admin must communicate resolution through other means

#### Notifications Triggered

| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| Step 1 (Registration) | School Admin | "New complaint received: [Ticket Number] — [Category] — submitted by [Complainant Type]" |
| Step 3 (Assignment) | Assigned User / Role | "Complaint [Ticket Number] has been assigned to you for resolution by [Assigning User]. Due by [Resolution Due Date]." |
| Step 5a (Resolved) | Complainant (if not anonymous) | "Your complaint [Ticket Number] has been resolved. Resolution: [Summary]. If unsatisfied, you may request a reopen." |
| Escalation Level Change | Escalation Entity Group | "Complaint [Ticket Number] has reached Escalation Level [N]. Immediate attention required." |

---

### 6.2 Complaint Reopening Workflow

**Trigger:** Complainant or School Admin initiates a reopen on a Resolved complaint
**End State:** Complaint is back In-Progress with the reopen reason recorded

#### Steps

1. **Reopen Request:** School Admin (or complainant via portal) selects "Reopen" on a Resolved complaint and provides a mandatory reopen reason
2. **Validation:** System verifies the complaint status is Resolved; blocks the action if status is Closed or Rejected
3. **Reopen:** System:
   - Clears the resolution timestamp, resolution summary, and resolved-by fields
   - Sets status back to In-Progress
   - Logs the reopen action and reason in the complaint timeline
4. **Re-assignment:** School Admin may re-assign the complaint to the same or a different handler
5. **Resolution (again):** Process continues from step 4 of Workflow 6.1

#### Exception Paths
- If the complaint status is Closed or Rejected, the reopen option is not available and a clear message is shown

#### Notifications Triggered

| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| Step 3 (Reopen) | Assigned User / School Admin | "Complaint [Ticket Number] has been reopened. Reason: [Reason]. Please investigate and resolve." |

---

### 6.3 Escalation Level Tracking Workflow

**Trigger:** Scheduled system process running at regular intervals (e.g., every hour)
**End State:** All open complaint escalation levels are current; affected entity groups are notified

#### Steps

1. **Fetch Open Complaints:** System retrieves all complaints with status Open or In-Progress
2. **Calculate Escalation Level:** For each complaint, the system calculates how much time has elapsed since the ticket date, then compares against the cumulative escalation hour thresholds defined in the applicable SLA rule:
   - Elapsed < Expected Hours → Level 0 (Pending, no escalation)
   - Elapsed ≥ Expected Hours, < Expected + L1 Hours → Level 1
   - Each additional threshold advances by one level
   - Elapsed beyond all five thresholds → Breached
3. **Update Records:** If the calculated level differs from the current stored level, the system updates the escalation level on the complaint record and logs a system action in the timeline
4. **Notify:** For complaints that crossed into a new escalation level, the system sends a notification to the entity group assigned to that level in the category or department SLA configuration

#### Exception Paths
- If a complaint has no applicable SLA (no category or SLA rules), it is skipped and flagged for admin review

#### Notifications Triggered

| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| Step 4 (Level change) | Escalation Entity Group for that level | "Complaint [Ticket Number] — [Category] — has reached Escalation Level [N]. Ticket Date: [Date]. Action required." |

---

## Section 7 — Reporting & Analytics Requirements

### 7.1 Summary & Status Report

**Report ID:** RPT-CMP-001
**Purpose:** Provides a count and percentage breakdown of all complaints by status, priority, category, and severity — giving School Admin a complete picture of complaint volumes and resolution patterns
**Primary Audience:** School Admin, Principal
**Frequency of Use:** Weekly, Monthly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Status | Current complaint status (Open / In-Progress / Resolved / Closed / Rejected) |
| Priority | Priority level assigned to the complaint |
| Category | Top-level complaint category |
| Severity | Severity level |
| Total Tickets | Count of complaints matching the filter combination |
| Percentage | Percentage of total complaints this group represents |
| Avg. Resolution Hours | Average time taken from ticket date to resolution for Resolved complaints |

#### Filters Available
- By date range: filter by complaint ticket date
- By category: narrow to a specific category or sub-category
- By complainant type: filter by student, parent, staff, etc.
- By status: narrow to a specific status

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report

| Rule | Description |
|------|-------------|
| Date filter applies to ticket date | The report counts complaints based on when they were registered, not when they were resolved |

---

### 7.2 SLA Violation Report

**Report ID:** RPT-CMP-002
**Purpose:** Identifies complaints that have already breached their resolution due date or are at risk of breaching it — so management can intervene before situations worsen
**Primary Audience:** School Admin, Principal
**Frequency of Use:** Daily

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Ticket Number | The complaint reference |
| Category | Complaint category |
| Status | Current status (Open or In-Progress only — see BR-CMP-020) |
| Resolution Due Date | When the complaint was due to be resolved |
| Hours Overdue | How many hours past the deadline the complaint currently is |
| Assigned To | The role/user currently responsible |
| Escalation Level | Current escalation level |
| Violation Type | Whether the complaint is At-Risk (< 2 hours to deadline) or Breached (past deadline) |

#### Filters Available
- By date range
- By category
- By assigned role/user

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report

| Rule | Description |
|------|-------------|
| BR-CMP-020 | Only Open or In-Progress complaints are included; resolved or closed tickets are excluded |

---

### 7.3 Pareto Analysis Report

**Report ID:** RPT-CMP-003
**Purpose:** Applies the 80/20 principle to identify which categories generate 80% of all complaints, enabling management to focus improvement efforts on the highest-impact areas
**Primary Audience:** School Admin, Principal
**Frequency of Use:** Monthly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Category | Complaint category name |
| Total Complaints | Count of complaints in this category for the period |
| Percentage of Total | This category's share of all complaints |
| Cumulative Percentage | Running total — shows which categories make up 80% of volume |
| Rank | Categories ordered highest to lowest by complaint count |

#### Filters Available
- By date range

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report

| Rule | Description |
|------|-------------|
| Pareto threshold | A visual line or highlight marks the point where cumulative % crosses 80% |

---

### 7.4 Complainant Hotspot Report

**Report ID:** RPT-CMP-004
**Purpose:** Identifies the targets (staff members, departments, vehicles, vendors) receiving the highest volume of complaints, with AI risk context — helping leadership identify systemic issues or individuals who may need intervention
**Primary Audience:** School Admin, Principal
**Frequency of Use:** Monthly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Target Name | The entity receiving complaints (staff name, department, vehicle) |
| Target Type | Type of entity |
| Total Complaints | How many complaints have been filed against this target |
| Average Escalation Risk Score | The average AI escalation risk score across this target's complaints |
| Highest Safety Risk | The highest safety risk score recorded against this target |
| Most Common Category | The complaint category that appears most frequently for this target |

#### Filters Available
- By date range
- By target type

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report

| Rule | Description |
|------|-------------|
| Minimum threshold | Only targets with 2 or more complaints in the period are shown |

---

### 7.5 AI Risk & Sentiment Report

**Report ID:** RPT-CMP-005
**Purpose:** Provides a visual scatter-plot overview of all complaints positioned by their AI-generated sentiment and escalation risk scores — helping leadership identify clusters of high-risk, high-sentiment complaints at a glance
**Primary Audience:** School Admin, Principal
**Frequency of Use:** Weekly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Ticket Number | Label on each data point in the chart |
| Sentiment Score | Position on the horizontal axis (0 = calm, 1 = highly negative) |
| Escalation Risk Score | Position on the vertical axis (0 = low risk, 100 = high risk) |
| Safety Risk Score | Size of the bubble representing each complaint |
| Category | Color coding of each bubble |

#### Filters Available
- By date range
- By category
- By minimum risk score threshold

#### Export Options
- [x] Print (PDF)
- [x] On-screen only

#### Business Rules for This Report

| Rule | Description |
|------|-------------|
| Only complaints with AI insights are plotted | Complaints without AI scores (edge cases) are excluded from the chart |

---

## Section 8 — Future Enhancement Log

| Enhancement ID | Requested Feature | Reason / Business Value | Requested By | Priority | Status |
|----------------|------------------|------------------------|--------------|----------|--------|
| ENH-CMP-001 | Multi-file attachment support for complaint evidence | Schools need to attach multiple photos or documents (medical reports, CCTV screenshots) to a single complaint | Product Team | P1 | Backlog |
| ENH-CMP-002 | SLA status badge on complaint list (color-coded) | Instant visual signal of overdue and at-risk tickets without opening each complaint | Product Team | P1 | Backlog |
| ENH-CMP-003 | Bulk status update (multi-select complaints) | At term-end, Admin needs to close batches of resolved tickets quickly | School Admin feedback | P2 | Backlog |
| ENH-CMP-004 | Post-resolution satisfaction rating (1–5 star) | Enables tracking of resolution quality, not just resolution speed; feeds frustration reports | Product Team | P2 | Backlog |
| ENH-CMP-005 | POCSO / RTE compliance flags | Indian law mandates specific escalation and reporting procedures for POCSO-applicable complaints; must be flagged at registration and trigger mandatory escalation to Principal | Legal requirement | P1 | Backlog |
| ENH-CMP-006 | Complaint merge (deduplication) | When multiple tickets for the same incident are raised by different people, Admin needs to merge them into one master ticket | School Admin feedback | P2 | Backlog |
| ENH-CMP-007 | PTM (Parent-Teacher Meeting) complaint tagging | Complaints raised during PTM sessions should be linkable to that PTM session for tracking | PTM module integration | P2 | Backlog |
| ENH-CMP-008 | Grievance Redressal Committee auto-report (CBSE) | CBSE schools must present unresolved complaints > 30 days to a committee monthly; this report should auto-generate from SLA data | Compliance | P1 | Backlog |
| ENH-CMP-009 | Hindi / regional language AI keywords | Current sentiment and safety scoring is English-only; adding Hindi transliterations improves accuracy for Indian school context | Product Team | P2 | Backlog |
| ENH-CMP-010 | WhatsApp / Email acknowledgement on complaint creation | Sending the ticket number to the complainant's registered contact immediately upon submission improves confidence that the complaint was received | School Admin feedback | P1 | Backlog |
| ENH-CMP-011 | Standard category seeder (CBSE/ICSE ready) | New schools should not need to build the category tree from scratch — a pre-built set of standard categories covers 80% of Indian school complaint types | Implementation efficiency | P1 | Backlog |
| ENH-CMP-012 | Python ML microservice for AI category prediction | Current engine assigns the user-selected category as the AI prediction; a real ML model would suggest the correct category from the description text | Product Team | P2 | Backlog |
| ENH-CMP-013 | Parent Portal direct complaint submission | Currently only Student Portal supports self-service submission; Parent Portal should have a dedicated submission flow | Parent Portal module | P2 | Backlog |

---

## Section 9 — Non-Functional Requirements

### 9.1 Performance Expectations

| Requirement | Standard |
|-------------|---------|
| Screen load time | All screens load within 3 seconds for up to 500 concurrent users |
| Report generation | Standard reports complete within 10 seconds |
| Large reports | Reports with 1,000+ complaints complete within 30 seconds |
| Complaint list | Complaint list screen must be paginated; no single request loads more than 25–50 records |
| AI processing | AI insight computation must not add more than 2 seconds of delay to the complaint submission screen; asynchronous processing is preferred |
| Escalation job | Scheduled escalation level update completes within 60 seconds for a school with up to 10,000 open complaints |

### 9.2 Security Requirements (Business Language)

| Requirement | Rule |
|-------------|------|
| Access control | Only users with the correct permission for their role may access each screen; a complaint assigned to one teacher must not be visible to another teacher in a different department |
| Data isolation | School A's complaint data must never be visible to School B; all complaint records are scoped to the school's tenant |
| Audit trail | All changes to complaint records must record who made them and when; deletion must be a soft-delete, never permanent without explicit authorization |
| Anonymous masking | Complaints submitted anonymously must mask complainant identity in all non-admin, non-principal screens |
| Private note protection | Notes marked private must only be returned to School Admin and Principal; the system must enforce this at the data retrieval level, not just the display layer |

### 9.3 Usability Requirements

| Requirement | Standard |
|-------------|---------|
| Mobile access | Complaint registration and status-check screens must work on mobile browsers |
| Language | All labels and messages in English; regional language support is a future enhancement |
| Ticket number visibility | The unique ticket number must be prominently displayed on the complaint detail screen and on any confirmation message shown after registration |
| Timeline readability | The complaint action timeline must be clearly formatted with timestamps, actor names, and action types so any authorized user can understand the full complaint history at a glance |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary

| Requirement ID | Feature Name | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|-------------|---------|------|------------------|---------------|------------|--------------------|--------------------|
| REQ-CMP-001 | Complaint Category Management | P0 | [CONFIGURATION] [DATA_ENTRY] | Yes | Yes | No | No | Yes |
| REQ-CMP-002 | Department SLA Configuration | P0 | [CONFIGURATION] [DATA_ENTRY] | Yes | Yes | No | No | Yes |
| REQ-CMP-003 | Complaint Registration | P0 | [DATA_ENTRY] [WORKFLOW] [NOTIFICATION] | Yes | Yes | No | Yes | Yes |
| REQ-CMP-004 | Complaint Assignment | P0 | [WORKFLOW] [NOTIFICATION] | Yes | Yes | No | Yes | Yes |
| REQ-CMP-005 | Resolution & Status Management | P0 | [WORKFLOW] [NOTIFICATION] | Yes | Yes | No | Yes | Yes |
| REQ-CMP-006 | Complaint Action Timeline | P0 | [WORKFLOW] [DATA_ENTRY] | Yes | Yes | No | No | Yes |
| REQ-CMP-007 | Medical Check Linkage | P1 | [DATA_ENTRY] [WORKFLOW] | Yes | Yes | No | No | Yes |
| REQ-CMP-008 | AI Insight Engine | P1 | [WORKFLOW] [DASHBOARD] | Yes | Yes | No | No | Yes |
| REQ-CMP-009 | Analytics Dashboard | P1 | [DASHBOARD] [REPORT] | No | Yes | Yes | No | Yes |
| REQ-CMP-010 | Reporting Suite (5 reports) | P1 | [REPORT] | No | Yes | No | No | Yes |
| REQ-CMP-011 | Student & Parent Portal Submission | P1 | [DATA_ENTRY] [WORKFLOW] | No | Yes | No | Yes | Yes |
| REQ-CMP-012 | Complaint Reopening | P1 | [WORKFLOW] | No | Yes | No | Yes | Yes |
| REQ-CMP-013 | Scheduled Escalation Tracking | P1 | [SCHEDULED] [NOTIFICATION] [WORKFLOW] | No | No | No | Yes | Yes |
| REQ-CMP-014 | Feedback Collection | P2 | [DATA_ENTRY] [WORKFLOW] | Yes | Yes | No | Yes | Yes |

### 10.2 Business Rules Coverage Summary

| Rule ID | Rule Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|-------------|-------------|--------------------|--------------------|---------------|
| BR-CMP-001 | Category name unique within parent | REQ-CMP-001 | Yes | Yes | No |
| BR-CMP-002 | Escalation hours strictly ascending | REQ-CMP-001 | Yes | Yes | No |
| BR-CMP-003 | Cannot delete category with children | REQ-CMP-001 | Yes | Yes | Yes |
| BR-CMP-004 | Deactivate before delete | REQ-CMP-001 | Yes | Yes | Yes |
| BR-CMP-005 | Dept SLA escalation hours ascending | REQ-CMP-002 | Yes | Yes | No |
| BR-CMP-006 | Dept SLA overrides category SLA | REQ-CMP-002 | No | Yes | Yes |
| BR-CMP-007 | Unique ticket number CMP-YYYY-NNNNNN | REQ-CMP-003 | Yes | Yes | Yes |
| BR-CMP-008 | Anonymous complainant rules | REQ-CMP-003 | Yes | Yes | No |
| BR-CMP-009 | Auto-populate severity/priority/medical from category | REQ-CMP-003 | No | Yes | Yes |
| BR-CMP-010 | Auto-calculate resolution due date from SLA | REQ-CMP-003 | No | Yes | Yes |
| BR-CMP-011 | Log every assignment in timeline | REQ-CMP-004 | No | No | Yes |
| BR-CMP-012 | Resolution requires note + timestamp | REQ-CMP-005 | Yes | Yes | Yes |
| BR-CMP-013 | Log every status change in timeline | REQ-CMP-005 | No | No | Yes |
| BR-CMP-014 | Valid status transitions only | REQ-CMP-005 | Yes | Yes | Yes |
| BR-CMP-015 | Private notes restricted to Admin/Principal | REQ-CMP-006 | No | No | Yes |
| BR-CMP-016 | Timeline in chronological order | REQ-CMP-006 | No | No | No |
| BR-CMP-017 | Medical check only if category requires it | REQ-CMP-007 | Yes | Yes | Yes |
| BR-CMP-018 | One AI insight per complaint; update not duplicate | REQ-CMP-008 | Yes | Yes | No |
| BR-CMP-019 | Sentiment 0–1; risk scores 0–100 | REQ-CMP-008 | No | Yes | No |
| BR-CMP-020 | SLA report excludes resolved/closed | REQ-CMP-010 | No | Yes | No |
| BR-CMP-021 | Anonymous complaint masking in non-admin views | REQ-CMP-011 | No | No | Yes |
| BR-CMP-022 | Reopen only from Resolved status | REQ-CMP-012 | Yes | Yes | Yes |
| BR-CMP-023 | Reopen clears resolution fields + logs reason | REQ-CMP-012 | No | No | Yes |
| BR-CMP-024 | Escalation level from elapsed time vs SLA thresholds | REQ-CMP-013 | No | Yes | Yes |

### 10.3 Report Coverage Summary

| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|------------|---------|---------------|---------------|
| RPT-CMP-001 | Summary & Status Report | P1 | 4 | Yes |
| RPT-CMP-002 | SLA Violation Report | P0 | 3 | Yes |
| RPT-CMP-003 | Pareto Analysis Report | P1 | 1 | Yes |
| RPT-CMP-004 | Complainant Hotspot Report | P1 | 2 | Yes |
| RPT-CMP-005 | AI Risk & Sentiment Report | P1 | 3 | Yes |

### 10.4 Total Scope Numbers

| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 14 |
| Total Business Rules (BR-) | 24 |
| Total Workflows defined | 3 |
| Total Reports required | 5 |
| Total Enhancements logged | 13 |
| Total P0 (Core) Requirements | 6 |
| Total P1 (Standard) Requirements | 7 |
| Total P2 (Enhanced) Requirements | 1 |

---

## Document Control

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-27 | Initial draft — synthesized from V2 technical requirement document (CMP_Complaint_Requirement.md), DDL (Complaint_DDL_v2.sql), and Complaint module code structure | Business Analysis — Prime-AI |

---

*This FRD is the single source of truth for Complaint module requirements.*
*All gap analyses, completion scoring, and test coverage must reference this document.*
*For technical implementation details, refer to the corresponding DDL file and Laravel module code.*
