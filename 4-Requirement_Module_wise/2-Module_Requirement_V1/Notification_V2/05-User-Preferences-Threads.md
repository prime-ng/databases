# Business Requirements Document (BRD)
## Module: Notification
### Feature: User Preferences & Threads

---

## 1. Executive Summary
Modern systems require user autonomy. Users must be able to control what they receive and when. Additionally, the system supports Two-Way Communication (Threads) for In-App messaging.

## 2. Business Motive & Rules
- **Anti-Spam Compliance:** Users must have the ability to opt-out of Promotional messages while still receiving Transactional (critical) alerts.
- **Do Not Disturb (DND):** Users shouldn't receive ping alerts at 2 AM.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: User Preferences (`ntf_user_preferences`)
- Managed by `UserPreferenceController.php`.
- Users can toggle `is_opted_in` per Channel (e.g., Off for SMS, On for Email).
- **Quiet Hours:** Define `quiet_hours_start` and `quiet_hours_end`. If a non-critical notification hits the queue during this window, it is delayed until the quiet hours end.
- **Priority Threshold:** Users can block low-priority notifications (e.g., "Only alert me for Priority Level 1-3").
- **Daily Digest:** Option to aggregate all daily non-critical alerts into a single 6 PM digest email.

### FR-02: Notification Threads (`ntf_notification_threads`)
- Managed by `NotificationThreadController.php` and `NotificationThreadMemberController.php`.
- Functions as an In-App chat or ticket thread.
- Tracks `unread_count` for each member in the thread.
- Thread members have specific `join_at` and `leave_at` timestamps.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Quiet Hours Delay
**As a** Parent,
**I want to** set Quiet Hours between 10 PM and 6 AM,
**So that** my phone doesn't wake me up for generic school announcements.

**Acceptance Criteria:**
- **Given** my Quiet Hours are set to 10 PM - 6 AM, **When** the school sends a bulk promotional SMS at 11 PM, **Then** the Delivery Queue Engine pauses my specific packet and schedules `next_attempt_at` for 6:01 AM.
