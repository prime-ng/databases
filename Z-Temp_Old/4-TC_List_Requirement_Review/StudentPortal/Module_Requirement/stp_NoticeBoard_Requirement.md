
# Module Requirement: stp_NoticeBoard

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Notice Board |
| **FRD Reference** | REQ-STP-023, BR-STP-031, BR-STP-034 |
| **Table Prefix** | `sys_*` (Notification module) |
| **DB Layer** | Tenant (tenant_{uuid}) |
| **Controller** | `StudentPortalController@noticeBoard` |
| **Route** | `GET /notice-board` (named `notice-board`) |
| **Associated View** | `studentportal::notice-board.index` |

---

## 2. Directory Layout

### 2.1 Route Map

| Method | URI | Controller Method | Name | Purpose |
|--------|-----|-------------------|------|---------|
| GET | `/notice-board` | `noticeBoard` | `notice-board` | Display chronological feed of notices/announcements |

---

## 3. Data / Entities

### 3.1 Current Data Source (GAP-STP-07)

| Entity | Table | Purpose |
|--------|-------|---------|
| `User.notifications()` (Laravel Notifiable) | `sys_notifications` | Currently used — shows user's personal notifications as notice board |

### 3.2 Expected Data Source (Per FRD)

| Entity | Table | Purpose |
|--------|-------|---------|
| Announcement model (SchoolSetup or dedicated) | `sch_announcements` (expected) | Official school-wide notices, circulars, and announcements |

**Current Implementation Gap:** The controller currently uses `auth()->user()->notifications()->latest()->paginate(20)` which returns the user's personal notification inbox, not a school-wide announcement feed. Per FRD (GAP-STP-07, RISK-STP-008), this needs to be replaced with a dedicated announcement model.

### 3.3 Expected Data Fields (Per Input Doc)

| Field | Type | Purpose |
|-------|------|---------|
| Title | String | Notice headline |
| Category/Tag | Dropdown | Event, General, Exam, Holiday, Emergency, etc. |
| Sender | String | Department or user who posted the notice |
| Date | DateTime | Date posted |
| Status | Read/Unread | Read status indicator |
| Description | Text | Full notice content |
| Attachments | File(s) | Downloadable files linked to notice |

---

## 4. Business Rules

### BR-STP-031 (Data Source Correction)
- **Current Violation**: Notice board uses `user()->notifications()` instead of a dedicated announcement model.
- **Expected Behaviour**: Official school announcements should come from an `sch_announcements` (or equivalent) model, not the personal notification inbox.
- **Impact**: Students miss official circulars; personal notifications clutter the notice board.

### BR-STP-034 (Data Ownership)
- Students should see only notices/announcements relevant to their role/class/school.

---

## 5. Business Logic / Conditions

| Condition | Trigger | On-Violation |
|-----------|---------|-------------|
| No notifications exist | Page load | Empty state with "No notices available" message |
| Notification belongs to another user | Page load (currently not possible due to `auth()->user()->notifications()`) | N/A with current implementation |

---

## 6. Access Control / Permissions

- **Authentication**: All routes require `auth` middleware.
- **Authorization Model**: No explicit `Gate::authorize()` calls.
- **Current data scoping**: `auth()->user()->notifications()` inherently scopes to the logged-in user.

---

## 7. States / Statuses

| State | Meaning |
|-------|---------|
| Unread | Notification not yet marked as read |
| Read | Notification has been read by the user |

---

## 8. Notifications / Alerts

- The notice board currently IS the notification display. This is the architectural issue — the board should show announcements, not personal notifications.

---

## 9. UI / UX Spec

- **Chronological feed**: List of notices sorted by `latest()` (descending created_at).
- **Pagination**: 20 items per page.
- **Per FRD input doc**, expected layout includes:
  - Title header
  - Category/Tag badge (Event, General, Exam, Holiday, Emergency)
  - Sender name/department
  - Date posted
  - Read/Unread indicator
  - Click to expand full details with description and attachment links

---

## 10. Error / Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| No notifications exist | Empty list rendered by paginator |
| Student has no active session | Notice board still shows notifications (no class dependency) |

---

## 11. Performance / NFR

- **Pagination**: 20 items per page via `paginate(20)`.
- **Query**: Single query via Laravel Notifiable relationship.

---

## 12. Dependencies (Cross-Module)

| Dependency | Type | Details |
|-----------|------|---------|
| `Modules\Notification\Models\Notification` | Current (incorrect) | Used as data source — should be replaced |
| SchoolSetup announcement model | Expected | Not yet integrated — gap GAP-STP-07 |

---

## 13. Test Scenarios Summary

**Positive:**
- Student with notifications views notice board with list
- Pagination works when >20 notifications exist

**Negative:**
- Student with no notifications sees empty state
- Student cannot see another user's notifications (inherently scoped)

---

## 14. FRD Traceability

| FRD ID | Requirement | Status |
|--------|-------------|--------|
| REQ-STP-023 | Notice Board — chronological feed of school notices | 🟡 (data source gap) |
| BR-STP-031 | Notice board should use official announcement model | ❌ (GAP-STP-07) |
| BR-STP-034 | Data ownership — student sees own data | ✅ (currently scoped to user) |

---

## 15. Known Gaps / Issues

| Gap ID | Issue | Severity |
|--------|-------|----------|
| GAP-STP-07 | Notice board uses `user()->notifications()` instead of dedicated announcement model — shows personal notifications, not school notices | High |
| RISK-STP-008 | Students miss official circulars because notice board is polluted with personal notifications | High |

---

## 16. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| V1 | 2026-07-23 | OpenCode | Initial requirement document |
