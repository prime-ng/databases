# Incidents — Business Requirements

## What This Screen Does

The Incidents screen is the discipline incident register for the hostel. Any rule violation, misconduct, or behavioral issue involving hostel residents is recorded here. Incidents are linked to incident types, warning letters can be issued, parents notified, and escalation workflows triggered for serious matters.

---

## When This Screen Is Used

- A student violates hostel rules (ragging, smoking, curfew violation, etc.)
- A fight or altercation between students
- Property damage by a student
- Repeated late returns or unauthorized absence
- Any behavior requiring formal documentation

---

## Key Fields

- **Student** — Student involved in the incident
- **Incident Type** — Type from Incident Types master (Tab 28)
- **Severity** — Minor / Moderate / Serious / Critical
- **Date & Time** — When the incident occurred
- **Location** — Where it happened
- **Description** — Detailed account of what happened
- **Action Taken** — What action was taken (counseling, warning, parent meeting, suspension, etc.)
- **Warning Letter Issued** — Whether a formal warning was given
- **Parent Notified** — Whether parent was informed
- **Notified By** — Who notified the parent
- **Linked Warnings** — Reference to Incident Warnings (Tab 29)
- **Media** — Photos, videos, or documents as evidence
- **Status** — Open / Action Taken / Closed / Escalated

---

## Business Rules

- Serious and Critical incidents require immediate parent notification
- Escalated incidents go to admin/principal for review
- Multiple incidents by same student trigger automatic warning/action
- Incident media (photos, videos) can be attached as evidence
- Warning letters are printable and stored digitally
- Incident history per student is retained permanently

---

## Workflow Steps

**Recording an Incident**
Warden selects student, incident type, severity, describes incident, records action taken, notifies parent if required.

**Issuing Warning**
For moderate+ incidents, warden can issue a formal warning letter (linked to Incident Warnings).

**Escalating**
If incident is beyond warden's authority, it is escalated to admin/principal.

**Closing**
After action is taken and parent notified (if required), incident is closed.

---

## Related Screens

- **Incident Types** (Tab 28) — Categories for incidents
- **Incident Warnings** (Tab 29) — Warning letter records
- **Sick Bay** (Tab 30) — Incidents involving injury
- **Audit Log** (Tab 25) — All changes logged
