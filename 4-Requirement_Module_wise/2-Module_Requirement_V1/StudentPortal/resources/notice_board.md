# Resources — Notice Board Tab Requirements

## 1. Functional Overview
A chronological feed of school notices, circulars, and announcements sent by the administration.

---

## 2. Page Structure & Parameters

### A. Notice Feed List
- Lists notices:
  - **Title**: Header details.
  - **Category/Tag**: Event, General, Exam, Holiday, Emergency, etc.
  - **Sender**: Department or user who posted the notice.
  - **Date**: Date posted.
  - **Status**: Read / Unread tag.

### B. Notice Details View
- Renders full details of the selected notice, including descriptions and download links for attached files.
- Displays notices in a clean, readable layout.

---

## 3. Database References
- **Tables**:
  - `sys_notifications`
  - `sys_dropdowns`
