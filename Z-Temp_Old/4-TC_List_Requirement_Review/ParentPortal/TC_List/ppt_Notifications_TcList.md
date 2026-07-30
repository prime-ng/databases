# ParentPortal — Notifications (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Notification Inbox |
| Module | ParentPortal (PPT) + Laravel Notification |
| Priority | P1 |
| Type | Read + Update (mark read) |
| Test Strategy | Functional + Mark-Read Actions + Pagination + AJAX |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/notifications` |
| Auth Required | Yes (Parent role) |
| Database | Tenant database with Laravel notifications table |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-NTF-001 | Verify notification inbox loads | 1. Login as Parent with notifications<br>2. Navigate to Notifications | Notification list displayed; unread first | ⬜ | ◌ |
| TC-PPT-NTF-002 | Verify empty state when no notifications | 1. Login as Parent with zero notifications<br>2. Navigate to Notifications | Empty state message; no errors | ⬜ | ◌ |
| TC-PPT-NTF-003 | Verify unread count badge displayed | 1. View notifications page<br>2. Check header/sidebar | Unread count badge visible with correct number | ⬜ | ◌ |
| TC-PPT-NTF-004 | Verify notifications sorted unread first | 1. Create read + unread notifications<br>2. View list | Unread notifications appear before read ones | ⬜ | ◌ |
| TC-PPT-NTF-005 | Verify notifications sorted by newest | 1. Create notifications at different times<br>2. View list | Newest notifications at top within each group | ⬜ | ◌ |
| TC-PPT-NTF-006 | Verify pagination at 30 per page | 1. Create 35 notifications<br>2. View list | First page shows 30; second page shows 5 | ⬜ | ◌ |
| TC-PPT-NTF-007 | Verify notification data rendered correctly | 1. View notification details | Title, message, timestamp, type visible | ⬜ | ◌ |

### 3.3 Mark Single Read

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-NTF-008 | Mark single notification as read (browser) | 1. Click "Mark Read" on unread notification<br>2. Redirected back | Notification marked read; unread count decremented | ⬜ | ◌ |
| TC-PPT-NTF-009 | Mark single notification as read (AJAX) | 1. Send POST with `Accept: application/json`<br>2. Check response | JSON `{"status": true}` | ⬜ | ◌ |
| TC-PPT-NTF-010 | Mark already-read notification again | 1. Mark read a notification<br>2. Mark same again | Succeeds (markAsRead is idempotent) | ⬜ | ◌ |
| TC-PPT-NTF-011 | Mark non-existent notification as read | 1. Send with invalid notification ID<br>2. Check response | 404 not found | ⬜ | ◌ |

### 3.4 Mark All Read

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-NTF-012 | Mark all unread as read | 1. Have multiple unread notifications<br>2. Click "Mark All Read" | All unread notifications marked read; unread count = 0 | ⬜ | ◌ |
| TC-PPT-NTF-013 | Mark all as read when none unread | 1. All notifications already read<br>2. Click "Mark All Read" | Success message; no error | ⬜ | ◌ |
| TC-PPT-NTF-014 | Verify success message after mark all read | 1. Mark all read<br>2. Check flash message | "All notifications marked as read." | ⬜ | ◌ |

### 3.5 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-NTF-015 | Access notifications without auth | 1. Logout<br>2. Navigate to Notifications | Redirected to login | ⬜ | ◌ |
| TC-PPT-NTF-016 | Mark another user's notification as read | 1. Get another user's notification ID<br>2. POST to mark-read | 404 (scoped to authenticated user) | ⬜ | ◌ |
| TC-PPT-NTF-017 | POST mark-read without CSRF token | 1. Submit without CSRF | 419 CSRF mismatch | ⬜ | ◌ |

### 3.6 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-NTF-018 | Verify audit log on notifications view | 1. Access notifications | "Viewed" event logged | ⬜ | ◌ |
| TC-PPT-NTF-019 | Verify audit log on mark single read | 1. Mark single read<br>2. Check logs | "MarkedRead" event with notification_id | ⬜ | ◌ |
| TC-PPT-NTF-020 | Verify audit log on mark all read | 1. Mark all read<br>2. Check logs | "MarkedRead" event with count | ⬜ | ◌ |

## 4. API Contract (AJAX)

### Mark Single Read — Success (JSON)
```json
{
    "status": true
}
```

## 5. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| Notifications | At least 35 notifications for the test user (mix of read/unread) |
| Auth user | User with notifiable trait |

## 6. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Notification marked read | `SELECT * FROM notifications WHERE id = ? AND read_at IS NOT NULL` |
| All marked read | `SELECT COUNT(*) FROM notifications WHERE notifiable_id = ? AND read_at IS NULL` = 0 |
| Pagination | Verify LIMIT 30 OFFSET 0 on first page |

## 7. Browser / Device Compatibility

| Platform | Support |
|----------|---------|
| Chrome (Desktop) | ✅ |
| Firefox (Desktop) | ✅ |
| Chrome (Android) | ✅ |
| Safari (iOS) | ✅ |

## 8. Known Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | No filter by type, date, or read/unread (per FRD) | Low | ⬜ |
| 2 | Uses Laravel DatabaseNotification — may not integrate with custom Notification module | Medium | ⬜ |

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/notifications` | `notifications.index` | `index` |
| POST | `/parent-portal/notifications/{notification}/read` | `notifications.mark-read` | `markRead` |
| POST | `/parent-portal/notifications/read-all` | `notifications.mark-all-read` | `markAllRead` |

## 10. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 20 | 0 | 0 | 0 | 0 | 0 | 20 |
