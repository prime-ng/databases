# Complaints — Business Requirements

## What This Screen Does

The Complaints tab manages complaint registration, tracking, resolution, and escalation. Complaints have Open/In_Progress/Resolved/Escalated/Closed statuses, urgency levels (Normal/Urgent/Critical), and can be escalated to a central Complaint Module (CmpComplaint).

## When This Screen Is Used

- **Complaint Registration**: Logging complaints from parents, staff, visitors
- **Complaint Tracking**: Monitoring resolution progress
- **Escalation**: Escalating unresolved complaints to central system
- **Resolution**: Marking complaints as resolved

## Key Fields

- **complaint_number** (string) — Auto-generated unique identifier
- **complainant_name** (string) — Complainant's full name
- **complainant_contact** (string, nullable) — Phone number
- **complaint_type** (enum) — Academic, Infrastructure, Staff, Transport, Fee, Other
- **description** (text) — Complaint details
- **urgency** (enum) — Normal, Urgent, Critical
- **status** (enum) — Open, In_Progress, Resolved, Escalated, Closed
- **resolution_notes** (text, nullable)
- **resolved_by** (FK, nullable) / **resolved_at** (datetime, nullable)
- **cmp_complaint_id** (FK → cmp_complaints, nullable) — Central module link
- **assigned_to_user_id** (FK, nullable)

## Business Rules

**Two Sections:** Open/In_Progress (warning/primary borders) → Closed/Resolved (success/danger/secondary borders). Open section shows Resolve + Escalate buttons. Closed section is read-only.

**Urgency Colors:** Critical (danger red), Urgent (warning yellow), Normal (info teal).

**Escalation:** Creates a linked `CmpComplaint` ticket in the central Compliance module. Sets `cmp_complaint_id`.

**Resolve Action:** Sets status=Resolved, resolved_by, resolved_at.

## Requirements

- MUST display in Compliance tab group with Open/In_Progress + Closed/Resolved sections
- MUST authorize via `frontoffice.complaint.*` policy gates
- MUST show urgency badges with color coding
- MUST show Resolve + Escalate buttons for open complaints
- MUST support status filter: All/Open/In_Progress/Resolved/Escalated/Closed
- MUST create complaints via modal with complainant name, type, urgency, description
