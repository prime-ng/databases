# Complaints — Business Requirements

## What This Screen Does

The Complaints screen is the hostel's internal issue reporting system. Students and wardens can file complaints about maintenance issues, electrical problems, plumbing, noise disturbances, cleanliness, or any other hostel-related concern. Each complaint has a priority, SLA deadline, assignment, and resolution tracking.

---

## When This Screen Is Used

- Student reports a maintenance issue in their room
- Noise complaint about a neighboring room
- Common area issue (broken light, dirty bathroom)
- Warden assigns complaint to maintenance staff
- Student follow-up on complaint resolution
- Satisfaction survey after resolution

---

## Key Fields

- **Student** — Who filed the complaint (optional, can be anonymous)
- **Category** — Maintenance / Electrical / Plumbing / Noise / Cleanliness / Security / Other
- **Priority** — Low / Medium / High / Urgent
- **Subject** — Brief title
- **Description** — Detailed description
- **Location** — Room or common area
- **Assigned To** — Staff member assigned to resolve
- **Assigned Date** — When assigned
- **SLA Deadline** — Expected resolution date (based on priority)
- **Resolution Notes** — How it was resolved
- **Resolved Date** — When resolved
- **Satisfaction Score** — 1-5 rating by student after resolution
- **Escalated To** — If unresolved, escalated to higher authority
- **Status** — Open / In Progress / Resolved / Escalated / Closed

---

## Business Rules

- Priority determines SLA deadline: Urgent = 4 hours, High = 24 hours, Medium = 48 hours, Low = 72 hours
- Complaints past SLA deadline without resolution are auto-flagged
- Students can track their complaint status
- Anonymous filing allowed (student field optional)
- Resolution requires warden verification before closing
- After closing, student receives satisfaction survey
- Escalated complaints go to admin/principal
- Repeated complaints about same issue indicate systemic problem

---

## Workflow Steps

**Filing a Complaint**
Student fills category, priority, subject, description, location. Submits.

**Assigning**
Warden reviews, assigns to appropriate staff, sets SLA deadline.

**Resolving**
Staff fixes issue, adds resolution notes. Marks as resolved.

**Verifying & Closing**
Warden verifies resolution. Student rates satisfaction. Complaint closed.

**Escalating**
If unresolved by SLA deadline, complaint can be escalated.

---

## Related Screens

- **Bed Maintenance** (Tab 21) — Maintenance complaints become work orders
- **Notification Log** (Tab 26) — SLA alerts sent via notification system
- **Audit Log** (Tab 25) — All status changes tracked
