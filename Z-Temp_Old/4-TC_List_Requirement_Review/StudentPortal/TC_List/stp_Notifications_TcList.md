# STP — Notifications TC List

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Support — Notifications Inbox

---

## 2. FRD / BR Reference
- **REQ-STP-027** — Notifications Inbox (P0)
- **BR-STP-030** — Notification ownership
- **BR-STP-031** — Notice board data source
- **BR-STP-032** — mark-read HTTP method must be POST/PATCH

---

## 3. Test Scenarios

| TC ID | Test Case | Preconditions | Test Steps | Expected Result | Status |
|-------|-----------|--------------|------------|----------------|--------|
| TC-STP-NOT-001 | Verify all-notifications page loads with mixed read/unread | User has read + unread notifications | 1) Login as student 2) Navigate to /all-notifications | Unread shown first (blue dot); read grouped by date; unreadCount and totalCount shown | ⬜ |
| TC-STP-NOT-002 | Verify page loads with zero notifications | User has no notifications | 1) Login as student 2) Navigate to /all-notifications | Empty state shown; unreadCount = 0; totalCount = 0 | ⬜ |
| TC-STP-NOT-003 | Verify page loads with all read | All notifications have non-null read_at | 1) Login as student 2) Navigate to /all-notifications | Unread section empty; read section shows all grouped by date | ⬜ |
| TC-STP-NOT-004 | Verify page loads with all unread | All notifications have null read_at | 1) Login as student 2) Navigate to /all-notifications | Unread section shows all; read section empty | ⬜ |
| TC-STP-NOT-005 | Verify mark single notification as read (POST) | Unread notification exists | 1) Login 2) POST /notifications/{id}/mark-read | Notification read_at set; success; redirect back | ⬜ |
| TC-STP-NOT-006 | Verify mark single notification with redirect | Query param `?redirect=/dashboard` | 1) Login 2) POST /notifications/{id}/mark-read?redirect=/dashboard | Notification marked read; redirected to /dashboard | ⬜ |
| TC-STP-NOT-007 | Verify mark non-existent notification returns 404 | ID = 99999 | 1) Login 2) POST /notifications/99999/mark-read | 404 Not Found | ⬜ |
| TC-STP-NOT-008 | Verify mark another user's notification returns 404 | Notification ID belonging to different user | 1) Login as User A 2) POST /notifications/{B_id}/mark-read | 404 Not Found (scoped query) | ⬜ |
| TC-STP-NOT-009 | Verify mark-already-read notification is idempotent | Already-read notification | 1) Login 2) POST /notifications/{id}/mark-read on already-read notification | No error; read_at unchanged | ⬜ |
| TC-STP-NOT-010 | Verify mark-all-read with unread notifications | User has multiple unread | 1) Login 2) POST /notifications/mark-all-read | All notifications marked read; success message | ⬜ |
| TC-STP-NOT-011 | Verify mark-all-read when all already read | No unread notifications | 1) Login 2) POST /notifications/mark-all-read | No-op; success message still shown | ⬜ |
| TC-STP-NOT-012 | Verify sort order — unread before read | Mixed notifications | 1) Login 2) Navigate to /all-notifications | Unread notifications appear first in descending created_at order; read notifications below grouped by date | ⬜ |
| TC-STP-NOT-013 | Verify GET on mark-read route (GAP) | Browser pre-fetch or direct GET | 1) Login 2) GET /notifications/{id}/mark-read | **Current behaviour:** Notification marked as read (BUG — should reject GET). Expected after fix: 405 Method Not Allowed | ⬜ |
| TC-STP-NOT-014 | Verify notification data JSON renders correctly | Notification has structured JSON data | 1) Login 2) Navigate to /all-notifications | Notification title, message, timestamp rendered from JSON payload | ⬜ |
| TC-STP-NOT-015 | Verify unread count in header matches actual unread | Unread notifications exist | 1) Login 2) Check header badge 3) Navigate to /all-notifications | Badge count matches unread count on all-notifications page | ⬜ |

---

## 4. Test Data Requirements
- User with mix of read and unread notifications (at least 5 each)
- User with all read notifications
- User with all unread notifications
- User with zero notifications
- At least two users to test cross-user notification access

---

## 5. Test Environment
- **Browser:** Chrome / Firefox / Edge (latest)
- **Auth:** Authenticated student user
- **DB:** Tenant database seeded with sample notifications

---

## 6. Automation Scope
| TC ID | Automatable? | Notes |
|-------|-------------|-------|
| TC-STP-NOT-001–015 | Yes | All testable via Pest HTTP tests; TC-STP-NOT-013 verifies the known GAP |

---

## 7. Pass / Fail Criteria
- **Pass:** All TC IDs pass; notification ownership enforced; mark-read idempotent
- **Fail:** Cross-user notification visible; GET method marks as read; unread sorting incorrect

---

## 8. Known Issues
| Issue | Description | Severity |
|-------|-------------|----------|
| BR-STP-032 / GAP-STP-32 | mark-read route is POST but controller does not enforce method — GET also works | **High** |
| — | No pagination on all-notifications (performance risk) | Medium |
| GAP-STP-07 | Notice board uses notifications instead of announcement model | Medium |

---

## 9. Route Reference
| Method | URI | Name |
|--------|-----|------|
| GET | /all-notifications | student-portal.all-notifications |
| POST | /notifications/mark-all-read | student-portal.notifications.mark-all-read |
| POST | /notifications/{id}/mark-read | student-portal.notifications.mark-read |

---

## 10. Execution Status
| Total TCs | Passed | Failed | Blocked | Not Run |
|-----------|--------|--------|---------|---------|
| 15 | — | — | — | 15 |
