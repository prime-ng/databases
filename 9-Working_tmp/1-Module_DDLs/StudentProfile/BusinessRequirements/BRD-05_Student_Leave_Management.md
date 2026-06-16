# BRD-05: Student Leave Management

**Document Version:** 1.0
**Date:** 2026-05-21
**Author:** Business Analyst
**Status:** Draft

---

## 1. Business Need

### 1.1 Problem Statement
Students frequently need to take leave from school for various reasons — sickness, family events, medical appointments, festivals, or emergencies. Currently, leave requests are handled through paper applications, handwritten notes, or phone calls, making it difficult for class teachers to track, approve, and record leave systematically. There is no audit trail of who approved what, no way for teachers to request supporting documents (medical certificates), and no automatic update of attendance records when leave is approved. This leads to attendance discrepancies and communication gaps between teachers and parents.

### 1.2 Business Objectives
- Provide a structured digital leave application process for students/parents
- Enable class teachers to review, approve, or reject leave applications online
- Support a full conversation thread between teachers and students (information requests, document requests)
- Automatically mark attendance as "Leave" when an application is approved
- Maintain a complete audit trail of every status change
- Allow schools to configure leave policies (day limits, document requirements, advance notice)

---

## 2. Scope

### 2.1 In Scope
- Leave type configuration by school admin (Sick, Casual, Medical, Bereavement, Festival, etc.)
- Leave application submission by students/parents
- 8-state application workflow (Draft → Submitted → Under Review → Info/Doc Requested → Approved/Rejected/Cancelled)
- Teacher review and decision-making
- Teacher↔Student communication thread (remarks)
- Supporting document upload for leave applications
- Automatic attendance update on approval
- Document requests by teacher and student responses
- Leave application editing and cancellation

### 2.2 Out of Scope
- Attendance marking for non-leave purposes (covered in BRD-04)
- HR/staff leave management (separate HR module)
- Automated leave approval based on rules (all approvals require teacher review)
- Integration with calendar/holiday list for calculating working days

---

## 3. Stakeholders

| Stakeholder | Interest |
|---|---|
| Student | Applies for leave, needs status updates and ability to respond to teacher queries |
| Parent | Assists with leave application, provides supporting documents |
| Class Teacher | Reviews applications, communicates with student, approves/rejects |
| School Admin | Configures leave types, monitors leave trends |
| Principal | Needs visibility into leave patterns and attendance impact |
| Attendance Clerk | Benefits from auto-updated attendance on approved leave |

---

## 4. User Roles & Permissions

| Role | Configure Types | Apply Leave | Review Leave | Approve/Reject | View All |
|---|---|---|---|---|---|
| Super Admin | ✓ | N/A | ✓ | ✓ | ✓ |
| School Admin | ✓ | N/A | ✓ | ✓ | ✓ |
| Class Teacher | ✗ | N/A | ✓ (own class) | ✓ (own class) | ✓ (own class) |
| Student | ✗ | ✓ (self) | ✗ | ✗ | ✗ (own only) |
| Parent | ✗ | ✓ (children) | ✗ | ✗ | ✗ (children only) |

---

## 5. Functional Requirements

### 5.1 Leave Type Configuration
**As a** School Admin,
**I want to** configure the types of leave available to students
**So that** the school can enforce different policies for different reasons (e.g., medical leave requires a certificate, festival leave has a day limit).

**Requirements:**
- FR-01: System shall allow creating leave types with a unique code and display name (Sick Leave, Casual Leave, Medical Leave, Bereavement Leave, Festival Leave, etc.)
- FR-02: System shall allow setting maximum consecutive days allowed per application
- FR-03: System shall allow setting an annual quota (max days per academic year)
- FR-04: System shall allow marking a leave type as requiring a supporting document (e.g., medical certificate)
- FR-05: System shall allow enabling/disabling half-day leave for each leave type
- FR-06: System shall allow setting minimum advance notice required in days
- FR-07: System shall allow activating/deactivating leave types
- FR-08: System shall support soft-delete, restore, and permanent delete of leave types

### 5.2 Leave Application — Student Submission
**As a** Student / Parent,
**I want to** submit a leave application
**So that** the school is formally notified of my absence and can approve it through the proper channel.

**Requirements:**
- FR-09: System shall allow students/parents to submit a leave application specifying leave type, date range, and reason
- FR-10: System shall allow half-day leave requests (morning or afternoon slot) for single-day applications
- FR-11: System shall allow attaching supporting documents (medical certificates, parent letters, etc.) at the time of application
- FR-12: System shall save applications as "Draft" until formally submitted
- FR-13: System shall route the application to the student's class teacher based on their current class-section
- FR-14: System shall allow the student to cancel their application before the teacher makes a final decision

### 5.3 Teacher Review & Decision
**As a** Class Teacher,
**I want to** review leave applications submitted by students in my class
**So that** I can approve legitimate leave, reject inappropriate requests, or ask for more information.

**Requirements:**
- FR-15: System shall display all pending leave applications for the teacher's class section
- FR-16: System shall show the teacher the application details: student name, leave type, dates, reason, and attached documents
- FR-17: Teacher shall be able to Approve, Reject, or Request Additional Information/Documents
- FR-18: Teacher shall provide remarks when approving or rejecting
- FR-19: When approving, teacher may modify the number of approved days (partial approval)
- FR-20: System shall clearly show the current status and complete history of each application

### 5.4 Teacher↔Student Communication Thread
**As a** Class Teacher / Student,
**I want to** communicate through the leave application
**So that** the teacher can ask clarifying questions or request documents, and the student can respond.

**Requirements:**
- FR-21: System shall allow teachers to post remarks requesting additional information
- FR-22: System shall allow teachers to post remarks requesting specific documents
- FR-23: System shall allow students to respond to teacher requests with explanations or uploaded documents
- FR-24: System shall allow general comments from both teacher and student (not just requests)
- FR-25: System shall auto-log every status change as a system remark (audit trail)
- FR-26: When a student responds to a request, the application status reverts to "Submitted" for teacher re-review
- FR-27: System shall mark teacher requests as resolved when the student has responded

### 5.5 Automatic Attendance Update
**As a** School Admin / Class Teacher,
**I want** the student's attendance to be automatically updated when leave is approved
**So that** the student is not shown as "Absent" for days when leave was granted.

**Requirements:**
- FR-28: On approval, system shall automatically create attendance records with status "Leave" for each working day in the approved date range
- FR-29: On rejection or cancellation, no attendance records shall be created
- FR-30: If leave is partially approved, only the approved days shall be marked as "Leave" in attendance

### 5.6 Document Management
**As a** Student / Parent,
**I want to** upload supporting documents for my leave application
**So that** the teacher has the necessary evidence (medical certificate, parent letter) to make an informed decision.

**Requirements:**
- FR-31: System shall allow uploading documents at the time of initial application
- FR-32: System shall allow uploading documents in response to a teacher's document request
- FR-33: Each document shall record who uploaded it and whether it was in response to a request

---

## 6. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-01 | A leave application follows this state machine: Draft → Submitted → Under Review → (Info Requested or Doc Requested) → Submitted → Approved or Rejected. From Draft/Submitted/Info Requested/Doc Requested, student may Cancel |
| BR-02 | Half-day leave is only valid when the from-date equals the to-date (single day) |
| BR-03 | The class teacher is determined by the student's current class-section at the time of submission |
| BR-04 | An approved leave automatically generates "Leave" attendance records for each day in the approved range |
| BR-05 | A rejected or cancelled leave does NOT impact attendance records |
| BR-06 | A student cannot submit a leave application that exceeds the configured max_days_per_application for that leave type |
| BR-07 | If the leave type requires a document, the application cannot be submitted without at least one document attached |
| BR-08 | Each status change in the application is automatically logged as a system remark for audit trail |
| BR-09 | When a student responds to an Info Request or Doc Request, the status reverts to "Submitted" for teacher re-review |

---

## 7. Workflow: Leave Application Lifecycle

```
Step 1: Student submits leave application via Student Portal
        (Leave type, date range, reason, optional attachments)
        ↓
  Status → [Submitted]
        ↓
Step 2: Application appears in Class Teacher's review inbox
        ↓
Step 3: Teacher opens the application
        ↓
  Status → [Under Review]
        ↓
Step 4: Teacher decides:
        ├── APPROVE → Provides remarks → Status → [Approved]
        │                                      ↓
        │                         Attendance auto-updated to "Leave"
        │
        ├── REJECT → Provides reason → Status → [Rejected]
        │
        └── REQUEST INFO/DOC → Writes query → Status → [Info Requested] or [Doc Requested]
                                                         ↓
                                              Student receives notification
                                                         ↓
                                              Student responds with info or uploads doc
                                                         ↓
                                              Status → [Submitted] (re-opens for teacher)
                                                         ↓
                                              Go back to Step 3
```

---

## 8. Acceptance Criteria

| Criterion | Description |
|---|---|
| AC-01 | Student can submit a leave application in under 3 minutes |
| AC-02 | Teacher sees all pending applications for their class immediately |
| AC-03 | Teacher can approve, reject, or request info with a single action |
| AC-04 | On approval, attendance records with status "Leave" are created within seconds |
| AC-05 | Student can see the current status and complete history of their application |
| AC-06 | Teacher can post a question and the student can respond with a message or document |
| AC-07 | Status changes are logged and visible in the application timeline |
| AC-08 | A canceled application shows as "Cancelled" and does not impact attendance |

---

## 9. Dependencies

| Dependency | Description |
|---|---|
| BRD-01 — Student Onboarding | Leave applications require existing student records |
| BRD-03 — Academic Journey | Leave routing requires current class-section assignment |
| BRD-04 — Attendance | Leave approval auto-creates attendance records |
| Student Portal | Students need portal access to submit leave applications |
| Notification Module | For informing teachers of new applications and students of status changes |

---

## 10. Assumptions

- Leave applications are submitted by students (not by teachers on behalf of students)
- Teachers review and approve/reject — there is no auto-approval
- Supporting documents are uploaded as PDFs or images
- The school defines leave types before students can apply
- Half-day leave is tracked as morning or afternoon absence

---

*End of BRD-05*
