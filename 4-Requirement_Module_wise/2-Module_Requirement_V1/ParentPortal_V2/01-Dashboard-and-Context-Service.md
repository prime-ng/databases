# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 01: Dashboard & Context Service (Session Management)

---

## 1. Executive Summary
The foundation of the Parent Portal is its ability to handle **Multi-Child Families**. A single parent login must securely navigate and segment data for siblings enrolled in different classes.

## 2. Core Components
- `ParentContextService.php`
- `ParentAccountController.php`
- `ParentDashboardController.php`
- Table: `ppt_parent_sessions`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Multi-Child Context Switching
- **Mechanism:** The `ParentContextService` resolves the `active_student_id` from the HTTP Request or the `ppt_parent_sessions` table.
- **Rule:** Every single controller in the Parent Portal MUST call `$child = $this->context->resolveChild($request)` before loading data.
- **IDOR Prevention:** The system strictly verifies that the resolved `$child` actually belongs to the logged-in Guardian to prevent URL parameter tampering (Insecure Direct Object Reference).

### FR-02: Device & Push Token Tracking
- The `ppt_parent_sessions` table tracks `device_token_fcm` (Android) and `device_token_apns` (iOS).
- Updates whenever the user logs into the app, enabling the Notification Module to push alerts exactly to this device.

### FR-03: Dashboard Aggregation
- **Widgets:** Shows top-level metrics for the *currently active child*:
  - **Attendance:** Status for today (Present/Absent).
  - **Fees:** Total pending overdue balance.
  - **Homework:** Count of pending assignments.
  - **Consent:** Count of pending unsigned forms.
- **Timeline:** A unified chronological feed of recent events (e.g., "Homework Graded", "Fee Receipt Generated", "Attendance marked Absent").

---

## 4. Acceptance Criteria
- **Given** I am a parent of Aarav (Class 10) and Priya (Class 5), **When** I log in, **Then** I see Aarav by default. **When** I click Priya's profile, **Then** the URL or session updates, and the Dashboard instantly replaces Aarav's Class 10 homework with Priya's Class 5 homework.
