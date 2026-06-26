# Support — Complaints: View All Tab Requirements

## 1. Functional Overview
Enables students to view the progress, assigned handlers, and resolution logs of all submitted complaints.

---

## 2. Directory Layout & Parameters

### A. Complaints History List
- Lists submitted tickets:
  - **Ticket Number**: e.g., CMP-2026-000001.
  - **Ticket Date**: Date submitted.
  - **Title**: Short description of the issue.
  - **Category**: Selected category.
  - **Status Badge**:
    - `Open` (Yellow)
    - `Assigned` (Blue)
    - `Resolved` (Green)
    - `Closed` (Grey)

### B. Complaint Detail View
- Displays ticket logs, handler notes, severity, priority, and links to download uploaded files.

---

## 3. Database References
- **Model**: `Modules\Complaint\Models\Complaint`
- **Table**: `cmp_complaints`
- **Fields**:
  - `ticket_no`
  - `ticket_date`
  - `title`
  - `description`
  - `status_id`
  - `created_by`
