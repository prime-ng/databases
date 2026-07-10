# Prime (PRM) — Notification — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Prime (PRM) — central (`prime_db`, no tenant init) |
| Feature / Screen | Notification (central Laravel database notifications) |
| Base URL | `http://127.0.0.1:8000` |
| Index URL | `/dashboard/all-notifications` (name `central.dashboard.all-notifications`) |
| Controller | `Modules\Prime\Http\Controllers\NotificationController` |
| Policy | `Modules\Notification\Policies\PrimeNotificationPolicy` (viewAny, create) |
| View | `Modules/Prime/resources/views/notification/index.blade.php` |
| Notification | `App\Notifications\TestNotification` (channel: `database`) |
| Sink table | `notifications` (morph — uuid id, `notifiable_type`/`notifiable_id`, `data` text, `read_at` nullable) |
| CRUD type | Read + mark-read + delete (no create/edit form) |
| Soft delete | N/A (hard `delete()`; notifications are disposable) |
| Pagination | 20 per page (`paginate(20)->withQueryString()`) |
| Activity log | **None** — notification actions do not write activity logs |
| Auth | `auth` + `verified` middleware on all routes; super-admin `Gate::before` bypass |

### Routes (verified)

| Verb | URI | Name | Gate |
|------|-----|------|------|
| GET | `dashboard/all-notifications` | `central.dashboard.all-notifications` | `prime.notification.viewAny` |
| POST | `dashboard/notifications/{id}/read` | `central.dashboard.notification.markAsRead` | *(none — ownership-scoped)* |
| POST | `dashboard/notifications/mark-all-read` | `central.dashboard.notification.markAllAsRead` | *(none — ownership-scoped)* |
| DELETE | `dashboard/notifications/{id}` | `central.dashboard.notification.destroy` | `prime.notification.delete` **(undefined — DEV-PRM-NTF-001)** |
| GET | `dashboard/test-notification` | `central.dashboard.test-notification` | `prime.notification.create` · **env-guarded** (local/staging/testing) |

---

## 2. Business Conditions (detailed)

- **BC-BIZ-01 — Filters.** `?filter=all|unread|read` (default `all`). `unread` → `unreadNotifications()`, `read` → `readNotifications()`, else full `notifications()`. Paginated 20/page. Header shows `{unreadCount} unread` badge and `{totalCount} total`.
- **BC-BIZ-03 — Mark single read.** POST → `auth()->user()->notifications()->findOrFail($id)->markAsRead()` → JSON `{success:true, unreadCount:<n>}`. Non-owned / missing id → `findOrFail` → **404**.
- **BC-BIZ-04 — Mark all read.** POST → `auth()->user()->unreadNotifications->markAsRead()` → JSON `{success:true, unreadCount:0}`.
- **BC-BIZ-05 — Delete.** DELETE → `Gate::authorize('prime.notification.delete')` (super-admin bypass) → `findOrFail($id)->delete()` → JSON `{success:true, unreadCount:<n>}`.
- **BC-BIZ-06 — Send test.** GET test-notification → authorize `create` → `notify(new TestNotification(...))` → redirect `central.dashboard.all-notifications` with flash `success = 'Test notification sent.'`.
- **BC-CFG-01 — Env guard (SEC-PRM-002 refuted).** The test-notification `Route::get(...)` is wrapped in `if (app()->environment(['local','staging','testing']))`. In production the route is **not registered** → 404. Residual: the controller method itself lacks an internal env check.

**Error / edge behaviour:** unauthenticated request → redirect `/login` (302). Missing/foreign notification id → 404 (`findOrFail`, scoped to the user's own relation → IDOR-safe).

---

## 3. Test Cases (step-by-step)

### TC-P60 — Notifications index renders

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as root/super-admin on `http://127.0.0.1:8000/login` | Dashboard loads |
| 2 | Visit `/dashboard/all-notifications` | HTTP 200; page shows "Notifications" header |
| 3 | Observe header bar | Bell icon, "Notifications" label, `{n} total`, All/Unread/Read filters |
| DB | `SELECT COUNT(*) FROM notifications WHERE notifiable_id = <admin id>` | Matches `{totalCount}` shown |

### TC-P70 — Send a test notification

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | While logged in, visit `/dashboard/test-notification` | Redirects to `/dashboard/all-notifications` with green "Test notification sent." |
| 2 | Observe list | A new unread row appears (bg-light + NEW badge) |
| DB | `SELECT * FROM notifications ORDER BY created_at DESC LIMIT 1` | New row; `read_at` IS NULL; `type = App\Notifications\TestNotification` |

### TC-P73 — Mark a single notification read

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On the unread view, click a row's "Mark as read" | Row loses bg-light, NEW badge removed, navbar count decremented |
| 2 | Inspect XHR `POST /dashboard/notifications/{id}/read` | 200 JSON `{success:true, unreadCount:<n>}` |
| DB | `SELECT read_at FROM notifications WHERE id='{id}'` | `read_at` is now set (non-null) |

### TC-P71 — Mark all read

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Mark all read" | All rows cleared of unread styling; badge hidden |
| 2 | Inspect XHR `POST /dashboard/notifications/mark-all-read` | 200 JSON `{success:true, unreadCount:0}` |
| DB | `SELECT COUNT(*) FROM notifications WHERE notifiable_id=<admin id> AND read_at IS NULL` | 0 |

### TC-P72 — Delete a notification

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click a row's "Delete", confirm the JS prompt | Row fades out and is removed |
| 2 | Inspect XHR `DELETE /dashboard/notifications/{id}` | 200 JSON `{success:true, unreadCount:<n>}` |
| DB | `SELECT COUNT(*) FROM notifications WHERE id='{id}'` | 0 (hard delete) |

### TC-N30 — Guest redirect

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log out / clear cookies | Session cleared |
| 2 | Visit `/dashboard/all-notifications` | Redirect to `/login` |

### TC-A52 — DEV-PRM-NTF-001 (undefined delete ability)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `NotificationController::destroy` | Calls `Gate::authorize('prime.notification.delete')` |
| 2 | Grep AppServiceProvider for `Gate::define('prime.notification.delete'` | **Not found** (only viewAny + create defined) |
| 3 | Inspect `PrimeNotificationPolicy` | **No `delete()` method** |
| 4 | Conclusion | Deletion works for super-admins only (Gate::before bypass); a non-super-admin with `tenant.notification.*` gets **403** on delete |

### TC-S80 — SEC-PRM-002 (REFUTED — env guard present)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open `routes/web.php` around the Notifications group | `if (app()->environment(['local','staging','testing'])) { Route::get('test-notification', ...) }` |
| 2 | Conclusion | Debug route is **not** exposed in production; the brief's "no environment guard" P1 does **not** reproduce |
| 3 | Residual | Controller method has no internal `App::environment()` check (defense-in-depth note only) |

### TC-S90 / TC-S91 — IDOR ownership scoping

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `markAsRead` / `destroy` | Both use `auth()->user()->notifications()->findOrFail($id)` |
| 2 | Attempt to mark/delete another user's notification id | `findOrFail` on the user's own relation → **404** (no cross-user access) |
