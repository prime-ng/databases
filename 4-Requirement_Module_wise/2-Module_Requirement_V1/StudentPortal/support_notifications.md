# Support — Notifications Tab Requirements

## 1. Functional Overview
Lists all system notifications and announcements, allowing students to mark individual items or all notices as read.

---

## 2. Directory Layout & Parameters

### A. Notifications Feed
- Lists notifications:
  - **Title**: Header text.
  - **Time**: Relative time (e.g. "3 hours ago").
  - **Read Status**: Unread items marked with a blue dot.
- **Actions**:
  - "Mark all as read" button.
  - Clicking on an individual notification marks it as read and redirects the student to the relevant page.

---

## 3. Database References
- **Model**: `App\Models\Notification`
- **Table**: `sys_notifications`
- **Fields**:
  - `id`
  - `type`
  - `notifiable_type`
  - `notifiable_id`
  - `data` (JSON payload)
  - `read_at` (nullable datetime)
