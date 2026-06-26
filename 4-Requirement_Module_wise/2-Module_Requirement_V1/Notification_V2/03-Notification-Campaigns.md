# Business Requirements Document (BRD)
## Module: Notification
### Feature: Core Notification Campaigns

---

## 1. Executive Summary
This represents the actual creation of a message dispatch event. It ties together the Template, the Target Group, and the Scheduling logic.

## 2. Business Motive & Rules
- **Cron Flexibility:** Schools need to schedule announcements for future dates or set up recurring reminders (e.g., Monthly fee reminder).
- **Cost Estimation:** Before clicking "Send" on an SMS to 5,000 parents, the admin needs to see the estimated cost.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Notification Dispatch Rules (`ntf_notifications`)
- Managed by `NotificationManageController.php`.
- Define message metadata: Title, Event, Priority (links to `sys_dropdowns`), Confidentiality.
- **Schedule Types:** IMMEDIATE, SCHEDULED, RECURRING, TRIGGERED (API-driven).
- **Recurring Engine:** Uses Cron expressions or standard patterns (HOURLY, DAILY, WEEKLY).
- **Tracking:** Stores live counts for `total_recipients`, `sent_count`, `failed_count`, `delivered_count`, `read_count`.
- **Budgeting:** Calculates `estimated_cost` based on recipient count * `cost_per_unit` from Channel Master, updating `actual_cost` post-delivery.

### FR-02: Channel Assignments (`ntf_notification_channels`)
- A single notification can be broadcast over multiple channels simultaneously.
- Configures `sending_order` for Fallback execution (e.g., Try Push Notification first, if unread for 1 hour, send SMS).

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Recurring Fee Reminder
**As an** Accounts Manager,
**I want to** set up a recurring notification on the 5th of every month,
**So that** fee defaulters are automatically reminded without manual intervention.

**Acceptance Criteria:**
- **Given** I am creating a notification, **When** I select `schedule_type = RECURRING` and pattern `MONTHLY`, **Then** the background engine dispatches the message on the 5th of every month until the `recurring_end_at` date is reached.
