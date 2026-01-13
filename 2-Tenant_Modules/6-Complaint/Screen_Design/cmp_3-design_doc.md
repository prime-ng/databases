# Complaint Management Module - Technical Design Document (Deliverable C)

## 1. Overview
The **Complaint Management Module** is a critical subsystem designed to capture, track, and resolve grievances from all stakeholders (Students, Parents, Staff, Vendors). It moves beyond simple ticketing to an **SLA-driven**, **AI-enhanced**, and **Escalation-aware** system.

**Scope:**
- **Capture**: Omni-channel intake (Web, Mobile, Email, Walk-in).
- **Process**: Automated routing based on Category/Severity.
- **Resolution**: 5-Level Escalation Matrix enforced by system jobs.
- **Analytics**: AI Sentiment analysis and Risk Scoring.

**Cross-Module Interactions:**
- **Transport Module**: Links complaints to `sch_vehicle` and `tpt_driver`.
- **Vendor Module**: Links complaints to `vnd_vendors` for performance scoring.
- **Student/Staff Modules**: Links complainants to their profiles.

---

## 2. Data Context
**Cardinality Matrix:**
- **Category** (1) ---- (Many) **Complaints**
- **Complaint** (1) ---- (Many) **Action Logs**
- **Complaint** (1) ---- (1) **AI Insight**
- **Complaint** (1) ---- (0..1) **Medical Record**

**Sensitive Data (PII/Compliance):**
- **Identity**: `complainant_name` and `mobile` (if Anonymous).
- **Medical**: `cmp_medical_records` contains sensitive health data (Alcohol tests).
- **Handling**: Medical records restricted to 'Safety Officer' role.

**Retention Policy:**
- Closed Complaints: **5 Years** (Legal compliance).
- Medical Logs: **7 Years**.
- Audit Logs: **3 Years**.

---

## 3. Screen Layouts (Screen-Sample Pattern)
**Priority Screens:**
1.  **Complaint Dashboard** (Role-based Widget View).
2.  **Lodge Complaint (Public/Private)** (Wizard Step Form).
3.  **Complaint Detail (Resolution Center)** (Ticket View + Chat + Timeline).
4.  **SLA Configuration Matrix** (Admin Grid).

---

## 4. Data Models (ER Diagram)

```ascii
      +------------------------+       +---------------------+
      | cmp_complaint_category |<------| cmp_department_sla  |
      +------------------------+       +---------------------+
                 ^
                 |
      +------------------------+       +---------------------+
      |    cmp_complaints      |<------| cmp_medical_checks  |
      +------------------------+       +---------------------+
                 | 
                 +---------------------+
                 |                     |
      +------------------------+       +---------------------+
      |   cmp_action_logs      |       |   cmp_ai_insights   |
      +------------------------+       +---------------------+
```

---

## 5. User Workflows

### 5.1. Happy Path: Parent Reports Rash Driving
1.  **Lodge**: Parent logs in -> Selects "Transport" -> "Rash Driving".
2.  **Context**: Puts Bus No (Dropdown linked to `sch_vehicle`).
3.  **Route**: System checks `cmp_department_sla`. Category "Rash Driving" = Priority High. Auto-assigns to "Transport Manager".
4.  **Action**: Transport Manager receives alert. Adds comment "Investigating".
5.  **Evidence**: Manager uploads dashcam footage (stored in `sys_media`).
6.  **Resolve**: Manager marks "Resolved" -> "Warning Issued to Driver".
7.  **Close**: Parent receives OTP to close the ticket.

### 5.2. Exception: Escalation Logic
1.  **Breach**: Manager fails to update status in 24 hours (L1 Breached).
2.  **Job**: Scheduler runs `CheckSLAPerformanceJob`.
3.  **Action**: System auto-escalates to **Level 2 (Principal)**.
4.  **Notify**: Principal gets SMS. Status changes to "Escalated". Priority bumps to "Critical".

---

## 6. Visual Design & UI Components
**Style Guide (Z-Pattern):**
- **Header**: Ticket ID (Large), Status Badge (Right), SLA Countdown Timer (Red if < 4h).
- **Layout**: 
    - **Left Col (70%)**: Description, Chat/Action History, Attachments.
    - **Right Col (30%)**: Meta Info (Assigned To, Category, Complainant Info).
- **Forms**: Wizard style for lodging (Category -> Details -> Confirm).

---

## 7. Accessibility (WCAG AA)
- **Contrast**: Status Badges must use high-contrast colors (e.g., White text on Red background for "Closed").
- **Keyboard**: Full navigation support for the "Escalation Matrix" grid.
- **Screen Readers**: `aria-live="polite"` for new chat messages/updates in the timeline.

---

## 8. Testing Strategy
**Unit Tests**:
- **EscalationTest**: Mock time passing > 24h, verify `current_level` increments.
- **PolymorphTest**: Verify `against_entity` correctly links to `sch_vehicles`.

**E2E Tests**:
- **Flow**: Lodge Compliance -> Admin View -> Resolve -> Parent Verify.

---

## 9. Deployment / Runbook
1.  **Migration**: Run `cmp_complaint_management_v2.0.sql`.
2.  **Seeding**: Populate `cmp_complaint_categories` with standard School complaints (Academics, Infra, Transport).
3.  **Jobs**: Configure Cron for `php artisan complaints:check-sla` (Every Hour).
4.  **Storage**: Ensure `sys_media` S3/Local bucket is writable for Incident Photos.

---

## 10. Future Enhancements (Roadmap)
1.  **WhatsApp Integration** (High): Lodge complaints via WhatsApp Bot.
2.  **Voice-to-Text** (Medium): Auto-transcribe voicemail complaints using OpenAI Whisper.
3.  **Sentiment Dashboard** (High): Heatmap of "Angry" parents by Department.
