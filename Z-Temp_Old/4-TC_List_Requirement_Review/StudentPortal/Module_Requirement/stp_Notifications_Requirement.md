# STP — Notifications Requirement Document

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Support — Notifications Inbox
- **Table Prefix:** stp_ (uses sys_notifications from Notification module via Laravel Notifiable)

---

## 2. FRD Reference
| ID | Description | Priority |
|----|------------|----------|
| REQ-STP-027 | Notifications Inbox | P0 |
| BR-STP-030 | Notification ownership — must belong to authenticated user | P0 |
| BR-STP-031 | Notice board data source must be official announcement model, not notification inbox | P0 |
| BR-STP-032 | Notification mark-read HTTP method must be POST or PATCH | P0 |

---

## 3. Feature Description
Central notification centre listing all system-generated notifications for the student. Supports marking individual notifications as read (with optional redirect) and marking all notifications as read in one action.

---

## 4. User Stories / Use Cases
- **As a** student, **I want to** view all my notifications (read and unread) **so that** I don't miss school communications.
- **As a** student, **I want to** mark a notification as read **so that** I can track which ones I've seen.
- **As a** student, **I want to** mark all notifications as read **so that** I can clear my inbox quickly.

---

## 5. Business Rules (BR)
| BR ID | Rule | Type | Enforcement |
|-------|------|------|-------------|
| BR-STP-001 | Data must belong to authenticated user | Permission | `auth()->user()->notifications()` — Laravel Notifiable scope |
| BR-STP-031 | Notice board must use announcement model (not notification inbox) | Separation | Notice board controller uses `paginate(20)` on notifications — **GAP** |
| BR-STP-032 | mark-read must use POST/PATCH, not GET | Security | Route defined as POST — **BUT markRead() method accepts GET due to optional verb handling** |
| — | Notifications sorted by read status (unread first), then by created_at desc | Display | `->orderBy('read_at')->orderByDesc('created_at')` |
| — | Unread notifications highlighted with blue dot (in view) | UI | View concern; unread identified by `read_at === null` |
| — | Marking a notification as read is idempotent | Reliability | `markAsRead()` sets `read_at` to now; subsequent calls are no-ops |
| — | Optional redirect URL passed as query param `?redirect=` | UX | `markRead()` reads `$request->query('redirect')` |
| — | Marking another user's notification is silently prevented | Permission | `auth()->user()->notifications()->findOrFail($id)` — returns 404 if not owned |

---

## 6. Validations & Edge Cases
| Scenario | Input / Action | Expected Behaviour |
|----------|---------------|-------------------|
| No notifications | User has zero notifications | Empty state; unreadCount = 0; totalCount = 0 |
| All notifications read | All have non-null read_at | `$unread` is empty; `$read` contains all notifications grouped by date |
| All notifications unread | All have null read_at | `$unread` contains all; `$read` is empty; `$readGrouped` is empty |
| Mark read on already-read notification | Notification with read_at set | Idempotent — read_at unchanged, no error |
| Mark read on non-existent notification | ID = 99999 | 404 Not Found |
| Mark read on another user's notification | ID belonging to different user | 404 Not Found (scoped to `auth()->user()->notifications()`) |
| Mark all read with zero unread | No unread notifications | No-op; success message shown |
| GET request to mark-read route | Browser pre-fetch or direct GET | Route is POST-only in web.php; **but controller accepts due to no method restriction** — GAP |
| Redirect after mark-read | URL with `?redirect=/dashboard` | After mark-as-read, redirects to the specified URL |

---

## 7. Route Details
| Method | Route | Name | Controller Method |
|--------|-------|------|-------------------|
| GET | /all-notifications | student-portal.all-notifications | NotificationController@allNotifications |
| POST | /notifications/mark-all-read | student-portal.notifications.mark-all-read | NotificationController@markAllRead |
| POST | /notifications/{id}/mark-read | student-portal.notifications.mark-read | NotificationController@markRead |

---

## 8. Data / Entity Reference

### A. Notifications
- **Model:** Laravel's default `Notification` (via `Notifiable` trait on User model)
- **Table:** `sys_notifications`
- **Key fields:** id, type, notifiable_type, notifiable_id, data (JSON), read_at (nullable datetime), created_at, updated_at

### B. NotificationController Data Flow
- `allNotifications()`: Loads ALL notifications for user (no pagination), splits into unread/read
- `markRead($id)`: Marks single notification read; optional `?redirect=` query param
- `markAllRead()`: Calls `auth()->user()->unreadNotifications->markAsRead()`

---

## 9. Dependencies (Cross-Module)
| Module | Dependency | Type |
|--------|-----------|------|
| Notification (System) | sys_notifications, Notifiable trait | Read/Write |

---

## 10. Integration / API
- Uses Laravel's built-in notification system
- No AJAX endpoints
- All notifications from all sources (fee, leave, exam, etc.) appear in this inbox

---

## 11. Security & Permissions
| Check | Implementation |
|-------|---------------|
| Authentication | Standard `auth` + `verified` middleware |
| Data ownership | Scoped via `auth()->user()->notifications()` |
| Cross-user access | `findOrFail()` inside `auth()->user()->notifications()` → 404 for foreign IDs |
| Method enforcement (planned) | Route defined as POST; controller does not enforce method — GAP |

---

## 12. Assumptions & Constraints
- All system notifications are stored via Laravel's Notifiable trait
- No pagination on all-notifications page (all records loaded in memory)
- `markRead()` uses POST route but controller does not explicitly restrict GET — browser pre-fetch risk

---

## 13. Known Issues / Gaps
| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| BR-STP-032 | **GAP-STP-32**: mark-read route is POST but controller accepts GET — browser pre-fetch marks notifications as read | **High** | **Open** |
| GAP-STP-07 | **BR-STP-031 violation**: Notice board reads from notifications instead of announcement model | Medium | Open |
| — | No pagination on all-notifications — performance risk for users with thousands of notifications | Medium | Open |
| — | No filter/search by notification type | Low | Open |

---

## 14. Future Enhancements
| ID | Suggestion | Priority |
|----|-----------|----------|
| ENH-STP-NOT-01 | Add pagination (e.g., 50 per page) | P2 |
| ENH-STP-NOT-02 | Add notification type filter (Fee, Leave, Exam, etc.) | P3 |
| ENH-STP-NOT-03 | Add push notification support (FCM) for mobile | P2 |
| ENH-STP-NOT-04 | Group notifications by date (already partially implemented for read) | P3 |

---

## 15. V1/V2 Status
- **V1:** —
- **V2:** —
- **Status:** ✅ Implemented (with method bug)
- **CR:** ◌

---

## 16. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 23-07-2026 | OpenCode | Initial requirement document |
