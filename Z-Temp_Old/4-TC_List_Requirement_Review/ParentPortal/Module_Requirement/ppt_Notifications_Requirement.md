# ParentPortal — Notifications (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Notification Inbox |
| **Alias** | ppt_notifications |
| **Module** | ParentPortal (PPT) + Laravel Notification |
| **Route Prefix** | `/parent-portal/notifications` |
| **Primary Controller** | `ParentNotificationController` |
| **Primary Model** | Laravel `DatabaseNotification` (built-in) |
| **Base Table** | `notifications` (Laravel default) |
| **FRD Reference** | REQ-PPT-017 |
| **Priority** | P1 (Should Have) |
| **Type** | Read + Update (mark read) |

## 2. Purpose

Provide parents with a unified notification inbox showing all school circulars, announcements, alerts, and system notifications. Supports read/unread tracking, individual/ bulk mark-as-read, and unread count display.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| BR-PPT-001 | Notifications scoped to authenticated parent user | Laravel `$request->user()->notifications()` |
| — | Notifications sorted: unread first, then by newest | `ParentNotificationController::index()` — `orderBy('read_at')->orderByDesc('created_at')` |
| — | Paginated at 30 per page | `paginate(30)` |

## 4. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Notification Inbox | `parent-portal.notifications.index` | `index()` | `notifications/index` | Paginated list, unread first, grouped by date |
| Mark Single Read | `parent-portal.notifications.mark-read` | `markRead()` | — (redirect/JSON) | Mark one notification as read |
| Mark All Read | `parent-portal.notifications.mark-all-read` | `markAllRead()` | — (redirect) | Mark all unread as read |

## 5. Validation Rules

No FormRequests used. Notifications use Route Model Binding for single mark-read; no form validation needed.

## 6. Technical Implementation

### 6.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| Laravel `DatabaseNotification` | Model | Built-in notification system |
| `Illuminate\Notifications\Notifiable` | Trait | On User model |

### 6.2 Key Implementation Details

- **Data Source:** Uses Laravel's built-in `DatabaseNotification` (stored in tenant's `notifications` table).
- **Unread Count:** `$user->unreadNotifications()->count()` — displayed as badge.
- **Sorting:** `orderBy('read_at')` — nulls first (unread), then `orderByDesc('created_at')` — newest first.
- **Pagination:** 30 notifications per page.
- **Mark Single Read:** Uses `$notification->markAsRead()`. Accepts `{notification}` via route model binding. Supports dual response:
  - If `Accept: application/json` → returns `{"status": true}`
  - Otherwise → redirects back
- **Mark All Read:** `$user->unreadNotifications->markAsRead()` — marks all unread in one call.
- **Notification Types:** Standard Laravel notification classes — data stored as JSON in the `data` column.

## 7. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| No notifications | Empty state with friendly message |
| Mark single notification as read | read_at set; unread count decremented |
| Mark all as read when none unread | Success message; no error |
| AJAX request for mark-read | JSON response `{"status": true}` |
| Browser request for mark-read | Redirect back with success |
| Mark another user's notification (IDOR) | 404 — Route Model Binding scoped via `$request->user()->notifications()` |
| Very long notification list | Paginated at 30 per page |
| Unread count badge updating | Reflected after mark-read actions |

## 8. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | FRD mentions filter by type, date range, and read/unread — not implemented | Low | ⬜ |
| 2 | FRD mentions push notification deep-linking — depends on mobile integration | Low | ⬜ |
| 3 | No notification detail page — uses mark-read on the list item directly | Low | ⬜ |
| 4 | No notification preference integration in the inbox view | Low | ⬜ |
| 5 | Uses Laravel DatabaseNotification — may not integrate with custom Notification module's ntf_notifications/circulars | Medium | ⬜ |

## 9. Cross-Module Impact

| Module | Impact |
|--------|--------|
| Laravel Notification | Core notification system — notifications table |
| Notification (custom) | If ntf_notifications integration needed, not currently connected |

## 10. Route Reference

```php
Route::prefix('notifications')->name('notifications.')->group(function () {
    Route::get('/', [ParentNotificationController::class, 'index'])->name('index');
    Route::post('/{notification}/read', [ParentNotificationController::class, 'markRead'])->name('mark-read');
    Route::post('/read-all', [ParentNotificationController::class, 'markAllRead'])->name('mark-all-read');
});
```

## 11. Middleware Stack

```
web → InitializeTenancyByDomain → PreventAccessFromCentralDomains
→ EnsureTenantIsActive → auth → verified → ParentPortalMiddleware
```

## 12. Controller Constructor Dependencies

None — controller uses no injected services.

## 13. Audit Logging

- Event types: `Viewed` (index), `MarkedRead` (markRead, markAllRead)
- Context: student_id (null for notifications), module, route
- Entity reference: notification_id (single), count (bulk)

## 14. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| IDOR (access another user's notification) | Route Model Binding scoped to `$request->user()->notifications()` |
| CSRF | Laravel CSRF middleware on POST routes |

## 15. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| "Filter by notification type, date range, and read/unread" | No filter implemented | Missing |
| "Push notification deep-links to relevant screen" | Not implemented | Mobile integration needed |
| "Unread count badge updates immediately" | Depends on page refresh or AJAX polling | Partial |
