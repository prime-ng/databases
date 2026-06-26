# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature: Dashboard & Session Management

---

## 1. Executive Summary
The Parent Portal is the frontend interface for guardians. Since a guardian may have multiple children enrolled in the school, the system must handle multi-child session contexts flawlessly. Additionally, it must track Push Notification tokens (FCM/APNs) per device.

## 2. Business Motive & Rules
- **Multi-Child Context:** A parent shouldn't need multiple logins. They log in once and toggle between their children (`active_student_id`).
- **Device Management:** A parent might use the Android app and the Web Portal simultaneously. The system needs to track notification preferences and push tokens across all their devices.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Parent Session Tracking (`ppt_parent_sessions`)
- Managed by `ParentAccountController.php` and `ParentContextService`.
- **Fields:**
  - `guardian_id`: Links to the `std_guardians` table.
  - `active_student_id`: The currently selected child.
  - `device_token_fcm` / `device_token_apns`: Push notification identifiers.
  - `quiet_hours_start` / `quiet_hours_end`: Links to the Notification module for DND (Do Not Disturb) settings.
- **Child Context Switching:** When a parent clicks a child's avatar, `ParentContextService` updates `active_student_id`. All subsequent data fetches (Fees, Exams, Attendance) use this ID.

### FR-02: Parent Dashboard (`ParentDashboardController`)
- Aggregates data for the `active_student_id`:
  - Today's attendance status.
  - Pending fee dues.
  - Upcoming exams or pending homework.
  - Unsigned consent forms.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Switching Child Context
**As a** Parent with two children (Aarav and Priya),
**I want to** switch between their profiles easily,
**So that** I can view Aarav's fee dues and Priya's homework without logging out.

**Acceptance Criteria:**
- **Given** I am logged into the portal and viewing Aarav's profile, **When** I click Priya's avatar in the header, **Then** `ppt_parent_sessions.active_student_id` is updated to Priya's ID, and the dashboard reloads to show exclusively Priya's data.
