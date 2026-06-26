# Business Requirements Document (BRD)
## Module: Notification
### Feature: Templates & Target Groups

---

## 1. Executive Summary
Before a notification can be sent, the system needs to know **what** to say (Templates) and **who** to say it to (Target Groups).

## 2. Business Motive & Rules
- **Reusability:** Admins shouldn't type the same "Fee Reminder" message 100 times. Templates standardize communication.
- **Dynamic Audiences:** A Target Group like "Class 10 Defaulters" shouldn't be static. It needs to dynamically resolve users matching that criteria at the exact time of sending.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Notification Templates (`ntf_templates`)
- Managed by `TemplateController.php`.
- Templates are channel-specific (e.g., an SMS template is short, an Email template is rich HTML).
- Must support **Dynamic Placeholders** (e.g., `Hello {{student_name}}, your fee of {{amount}} is due.`).
- Support multilingual variants (`language_code`).

### FR-02: Target Groups (`ntf_target_groups`)
- Managed by `TargetGroupController.php`.
- **Group Type - STATIC:** A manually selected list of user IDs.
- **Group Type - DYNAMIC:** A saved JSON/SQL query that executes at runtime to fetch users (e.g., "All students with Attendance < 75%").

### FR-03: Notification Targets (`ntf_notification_targets`)
- Managed by `NotificationTargetController.php`.
- Bridges the core `Notification` to either a specific Target Group, or a direct list of selected users (`target_table_name`, `target_selected_id`).

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Dynamic Target Resolution
**As a** School Admin,
**I want to** create a Dynamic Target Group for "Absent Today",
**So that** I can reuse this group every day without manually selecting absent students.

**Acceptance Criteria:**
- **Given** a Dynamic Target Group based on an attendance query, **When** a Notification executes at 10 AM, **Then** the engine automatically evaluates the query and resolves the recipients based on today's attendance table.
