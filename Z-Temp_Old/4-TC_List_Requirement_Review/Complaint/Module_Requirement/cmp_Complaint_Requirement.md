# Complaint (Manage) — Business Requirements

## What This Screen Does

The Manage Complaints screen is the core operations hub. It handles the complete lifecycle of complaints: creation (with optional anonymous submission and image attachment), assignment to users/roles, status transitions (Open → In-Progress → Resolved/Closed/Rejected), escalation tracking, resolution recording, and reopening. Complaints can target various entities (departments, students, staff, vehicles, vendors) via polymorphic relationships.

## When This Screen Is Used

- **Daily operations** when receiving and processing all incoming complaints.
- **When assigning complaints** to specific users or roles for resolution.
- **When resolving complaints** and recording resolution details.
- **When escalating complaints** that exceed SLA thresholds.
- **When analyzing complaint data** via the dedicated management page.

## Key Fields

- **Ticket Number** (string 30, unique, auto-generated) — Format: CMP-YYYY-XXXXXX
- **Ticket Date** (date) — Date complaint was raised
- **Complainant Type** (FK → sys_dropdown_table) — Parent, Student, Staff, etc.
- **Complainant User** (FK → sys_users, nullable) — If complainant is a system user
- **Complainant Name/Contact** (string, nullable) — For walk-in/anonymous complaints
- **Target Type** (FK → sys_dropdown_table, nullable) — Department, Staff, Vehicle, etc.
- **Target Polymorphic** (target_table_name + target_selected_id) — Flexible entity targeting
- **Category** (FK → cmp_complaint_categories) — Complaint category
- **Subcategory** (FK → cmp_complaint_categories, nullable) — Sub-category
- **Severity Level** (FK → sys_dropdown_table)
- **Priority Score** (FK → sys_dropdown_table)
- **Title** (string 200)
- **Description** (text, nullable)
- **Location/Incident Date/Incident Time** — Incident details
- **Status** (FK → sys_dropdown_table) — Open, In-Progress, Resolved, Closed, Rejected
- **Assigned To** (Role + User, nullable)
- **Resolution Due At** (datetime, computed)
- **Actual Resolved At / Resolution Summary** — Resolution details
- **Is Anonymous** (boolean) — Hides complainant identity
- **Is Escalated / Escalation Level** — Escalation tracking

## Business Rules

**Ticket Number Generation:**
Auto-generated as `CMP-YYYY-NNNNNN` where YYYY is the current year and NNNNNN is a sequential number. Uses DB lock for concurrency safety.

**Resolution Due At Calculation:**
On creation, computed from the category's `default_expected_resolution_hours` added to `ticket_date`.

**Anonymous Complaints:**
When `is_anonymous = true`, the complainant name displays as "Anonymous" and contact as "Hidden" for non-admin users (accessor logic).

**Status Transitions:**
Strictly enforced: Open → In-Progress → Resolved/Closed/Rejected. Resolved can be Reopened → In-Progress. Direct jumps are rejected.

**Resolution Requirements:**
When changing status to Resolved, `actual_resolved_at` and `resolution_summary` are required.

**Image Attachment:**
Supports a single complaint image via Spatie Media Library with small/medium/large conversions.

**Escalation:**
A cron command `complaints:escalate` updates escalation levels based on SLA thresholds. The `current_escalation_level` tracks which level (0–5).

**AI Processing:**
On create/update, a `ComplaintSaved` event fires, which triggers `ProcessComplaintAIInsights` listener. This auto-generates sentiment, risk scores, and predictions.

**Polymorphic Targeting:**
The `targetable()` morphTo allows complaints to target any entity (class, staff, vehicle, etc.) via `target_table_name` + `target_selected_id`.

## Workflow

1. User navigates to Complaint → Complaint Management → Manage Complaints tab.
2. Table lists: Ticket No, Title, Category, Status, Severity, Assigned To, Escalation Level, Actions.
3. User creates a complaint: selects complainant type, category, severity, priority, enters title, optionally adds target, image, anonymous flag.
4. Ticket number auto-generated. Resolution due date computed. AI insight auto-processed.
5. User can view details, edit (with status transition validation), assign, resolve, reopen.
6. Dedicated management page (`manage()`) provides detailed view with actions timeline.

## Requirements

- MUST display at `/complaint/complaint-mgt?tab=complaint-manage` as paginated table with filters
- MUST authorize via `tenant.complaint.*` policy gates
- MUST auto-generate unique ticket number as CMP-YYYY-NNNNNN with concurrency lock
- MUST auto-calculate resolution_due_at from ticket_date + category expected hours
- MUST enforce strict status transitions (Open → InProgress → Resolved/Closed/Rejected, Reopened → InProgress)
- MUST require actual_resolved_at and resolution_summary when resolving
- MUST hide complainant identity when is_anonymous = true (non-admin)
- MUST support image upload via Spatie Media Library (complaint_img)
- MUST fire ComplaintSaved event for AI processing
- MUST support polymorphic targeting of any entity
- MUST support is_active toggle via AJAX
- MUST support soft delete with trash view, restore, forceDelete
- MUST support reopen with reopen_reason
- MUST have dedicated manage page with full details and history
