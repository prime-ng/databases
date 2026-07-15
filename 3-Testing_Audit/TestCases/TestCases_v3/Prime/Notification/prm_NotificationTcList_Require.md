# Prime (PRM) — Notification — Test Case List & Requirements

**Module:** Prime (PRM) · central / `prime_db` (no tenant init)
**Feature / Screen:** Notification (central Laravel database notifications)
**Primary sink table:** `notifications` (morph table — `notifiable_type`/`notifiable_id`), **not** a domain (`ntf_*`) table
**Controller:** `Modules\Prime\Http\Controllers\NotificationController`
**Policy:** `Modules\Notification\Policies\PrimeNotificationPolicy`
**View:** `Modules/Prime/resources/views/notification/index.blade.php`
**Test file:** `prm_Notification_TestCas.php` (single comprehensive suite; host `http://127.0.0.1:8000`)
**Screen type:** Read/action-focused (list + mark-read + mark-all-read + delete + debug test-notification). No create/edit form → no store/update validation matrix.

> **Source-truth reconciliations (HARD RULE 1 — read before assert):**
> - **SEC-PRM-002 (P1) is REFUTED by source.** The `test-notification` route IS environment-guarded at registration (`if (app()->environment(['local','staging','testing']))`, `routes/web.php:93-95`). It is **not** an unguarded production debug route. Residual (minor) defense-in-depth gap only: no internal `App::environment()` check inside the controller method. BR-PRM-018 effectively **PASSES** at the route layer.
> - **markAsRead / markAllAsRead have NO gate** (brief claimed markAsRead is gated `prime.notification.viewAny` — false). They rely on `auth`+`verified` middleware and ownership scoping (`->notifications()->findOrFail`).
> - **`destroy()` authorizes an UNDEFINED ability** `prime.notification.delete` (never `Gate::define`d; no policy `delete()`), so only the super-admin `Gate::before` bypass permits deletion → **DEV-PRM-NTF-001**.
> - **`TestNotification` ignores its constructor arg** and uses `User::inRandomOrder()->first()` → **DEV-PRM-NTF-002**.

---

## 1. Business Conditions

### BC-DB — `notifications` table (DDL: `database/migrations/2025_12_31_045403_create_notifications_table.php`)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `notifications` table exists on the central connection | DDL-notifications |
| BC-DB-02 | `id` is a UUID primary key | DDL-notifications |
| BC-DB-03 | Polymorphic morph columns `notifiable_type` + `notifiable_id` present | DDL-notifications |
| BC-DB-04 | `data` is `text`; `read_at` is nullable timestamp; `created_at`/`updated_at` present | DDL-notifications |

### BC-AUTH — permission gates (Controller + AppServiceProvider + Policy)

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `allNotifications` gated `prime.notification.viewAny` | Controller:21 / Screen-PM-1 |
| BC-AUTH-02 | `testNotification` gated `prime.notification.create` | Controller:88 / Screen-PM-2 |
| BC-AUTH-03 | `destroy` calls `Gate::authorize('prime.notification.delete')` — ability **NOT defined**, no policy method → super-admin bypass only | Controller:73 / Audit-DEV-PRM-NTF-001 |
| BC-AUTH-04 | `markAsRead` / `markAllAsRead` are **ungated** (no `Gate::authorize`) | Controller:44-66 |
| BC-AUTH-05 | Gates `prime.notification.viewAny`/`create` defined in AppServiceProvider → PrimeNotificationPolicy | AppServiceProvider:98-99 |
| BC-AUTH-06 | Policy `viewAny`/`create` delegate to `tenant.notification.*` Spatie permissions | Policy:14,22 |
| BC-AUTH-07 | Super-admin `Gate::before` bypass (`is_super_admin && super_admin_flag`) grants all abilities | AppServiceProvider:64-66 |
| BC-AUTH-08 | All routes behind `auth` + `verified` middleware | routes/web.php:83 |

### BC-BIZ — behaviour (Controller / View / Notification)

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | `allNotifications` supports `filter` = `all` \| `unread` \| `read` (default `all`), paginate 20 | Controller:24-34 / Screen-BR-1 |
| BC-BIZ-02 | `allNotifications` returns `unreadCount` + `totalCount` to the view | Controller:35-38 |
| BC-BIZ-03 | `markAsRead` marks one notification read; JSON `{success, unreadCount}` | Controller:44-53 |
| BC-BIZ-04 | `markAllAsRead` marks all unread read; JSON `{success, unreadCount: 0}` | Controller:58-66 |
| BC-BIZ-05 | `destroy` deletes one notification; JSON `{success, unreadCount}` | Controller:71-81 |
| BC-BIZ-06 | `testNotification` sends `TestNotification`, redirects to index with success flash | Controller:86-95 |
| BC-BIZ-07 | View uses route names `central.dashboard.all-notifications` + `...notification.markAllAsRead` and endpoint `url('dashboard/notifications')` | View:22-30,151,175,206 |
| BC-BIZ-08 | `TestNotification` ignores ctor `$user`, uses `User::inRandomOrder()->first()`; `via()` = `database` | TestNotification:19-20,28 / Audit-DEV-PRM-NTF-002 |

### BC-CFG — configuration / environment guard

| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | `test-notification` route registered **only** in `local`/`staging`/`testing` | routes/web.php:93-95 / Screen-SEC (SEC-PRM-002) |
| BC-CFG-02 | Under `APP_ENV=testing` the guarded route is present (`Route::has`) | Env |
| BC-CFG-03 | Controller `testNotification()` has **no internal** `App::environment()` check (residual) | Controller:86-95 |

### BC-REF / BC-INT — polymorphic linkage

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `notifications` is a polymorphic sink (morph columns) linking any notifiable | DDL-notifications |
| BC-INT-01 | Resolved User model exposes `notifications()`/`unreadNotifications()`/`readNotifications()` (Notifiable) | Controller:26-35 |

### BC-SM — state machine

| ID | Condition | Source |
|----|-----------|--------|
| BC-SM-01 | Notification lifecycle: `unread (read_at = NULL)` → `read (read_at set)` via markAsRead/markAllAsRead; `read`/`unread` → `deleted` via destroy | Controller:47,60,75 |

*(Single trivial two-state transition — covered by action tests 71/72/73 and source assertions 11/90/91; no separate FSM band.)*

---

## 2. Test Case List

### Positive (TC-P)

| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-P01 | Config | BC-DB/AUTH/BIZ | DDL/Controller | Routes, gates, methods, `notifications` table all correct | All present | `test_..._01` | ✅ |
| TC-P02 | Config | BC-BIZ | Controller | Controller method signatures/return types | JsonResponse etc. | `test_..._02` | ✅ |
| TC-P03 | Config | BC-DB-02/03 | DDL | Column types polymorphic (uuid + morph) | char/uuid + morph | `test_..._03` | ✅ |
| TC-P04 | Config | BC-DB | DDL | Migration defines uuid/morph/text/read_at | Strings present | `test_..._04` | ✅ |
| TC-P05 | Config | BC-AUTH-06 | Policy | Policy delegates to tenant.notification.* | Present | `test_..._05` | ✅ |
| TC-P10 | Biz | BC-BIZ-01/02 | Controller | Filter all/unread/read + paginate(20) | Present | `test_..._10` | ✅ |
| TC-P12 | Biz | BC-BIZ-07 | View | View uses correct route names/endpoints | Present | `test_..._12` | ✅ |
| TC-P60 | UI | BC-AUTH-01 | View | Index renders for admin | Sees "Notifications" | `test_..._60` | ✅ |
| TC-P61 | UI | BC-BIZ-01 | View | All/Unread/Read filter buttons present | Present | `test_..._61` | ✅ |
| TC-P62 | UI edge | BC-BIZ-01 | View | Unread filter shows rows or empty state | One of | `test_..._62` | ✅ |
| TC-P63 | UI | View | View | Breadcrumb shows Notifications | Present | `test_..._63` | ✅ |
| TC-P70 | Action | BC-BIZ-06 | Controller | test-notification creates + lists a row | Row present | `test_..._70` | ✅ |
| TC-P71 | Action/API | BC-BIZ-04 | Controller | mark-all-read → success + unread 0 | 200 `{success,0}` | `test_..._71` | ✅ |
| TC-P72 | Action/API | BC-BIZ-05 | Controller | delete → success json | 200 `{success}` | `test_..._72` | ✅ |
| TC-P73 | Action/API | BC-BIZ-03 | Controller | mark single read → success + unreadCount | 200 `{success,unreadCount}` | `test_..._73` | ✅ |
| TC-P41 | Int | BC-INT-01 | Controller | User exposes Notifiable relations | Present | `test_..._41` | ✅ |
| TC-P40 | Ref | BC-REF-01 | DDL | Morph columns present | Present | `test_..._40` | ✅ |

### Negative (TC-N)

| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-N30 | Auth | BC-AUTH-08 | routes | Guest redirected to /login from index | Redirect /login | `test_..._30` | ✅ |
| TC-N31 | Auth | BC-AUTH-08 | routes | All routes require auth+verified middleware | Present | `test_..._31` | ✅ |
| TC-N93 | Auth | BC-AUTH-08 | routes | Guest JSON POST never returns 200 success | Not 200 | `test_..._93` | ✅ |

### Permissions (TC-AUTH)

| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-A50 | Perm | BC-AUTH-01 | Controller | allNotifications gated viewAny | Present | `test_..._50` | ✅ |
| TC-A51 | Perm | BC-AUTH-02 | Controller | testNotification gated create | Present | `test_..._51` | ✅ |
| TC-A52 | Perm | BC-AUTH-03 | Controller | **DEV-PRM-NTF-001** destroy → undefined delete ability | Gate::has false + no policy delete | `test_..._52` | ✅ |
| TC-A53 | Perm | BC-AUTH-07 | AppServiceProvider | Super-admin Gate::before bypass present | Present | `test_..._53` | ✅ |
| TC-A54 | Perm | BC-AUTH-04 | Controller | mark-read actions ungated; exactly 3 authorize calls | Present | `test_..._54` | ✅ |

### Security / Config (TC-S)

| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-S80 | Config | BC-CFG-01 | routes | **SEC-PRM-002 REFUTED** — test-notification env-guarded at registration | Regex matches | `test_..._80` | ✅ |
| TC-S81 | Config | BC-CFG-02 | Env | Guarded route registered in testing env | Route::has true | `test_..._81` | ✅ |
| TC-S82 | Config | BC-CFG-03 | Controller | Residual: no internal env check in method | No App::environment | `test_..._82` | ✅ |
| TC-S90 | IDOR | BC-BIZ-03 | Controller | markAsRead ownership-scoped findOrFail | Present | `test_..._90` | ✅ |
| TC-S91 | IDOR | BC-BIZ-05 | Controller | destroy ownership-scoped findOrFail | Present | `test_..._91` | ✅ |
| TC-S92 | Config | BC-AUTH | routes | All routes under central.dashboard. group | Present | `test_..._92` | ✅ |
| TC-S11 | Scope | BC-BIZ-03/04 | Controller | mark actions scoped to current user | Present | `test_..._11` | ✅ |
| TC-S13 | Biz defect | BC-BIZ-08 | Notification | **DEV-PRM-NTF-002** TestNotification ignores ctor arg | Present | `test_..._13` | ✅ |

---

## 3. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_notification_01_routes_gates_methods_and_notifications_table_configuration_are_correct` | TC-P01 | Config truth | 01 |
| 2 | `test_notification_02_controller_method_signatures_are_correct` | TC-P02 | Config | 02 |
| 3 | `test_notification_03_notifications_table_column_types_are_polymorphic` | TC-P03 | Config | 03 |
| 4 | `test_notification_04_migration_defines_uuid_morph_and_nullable_read_at` | TC-P04 | Config | 04 |
| 5 | `test_notification_05_policy_delegates_to_tenant_notification_permissions` | TC-P05 | Config | 05 |
| 6 | `test_notification_10_allnotifications_supports_all_unread_read_filters` | TC-P10 | Biz | 10 |
| 7 | `test_notification_11_mark_read_actions_are_scoped_to_current_user` | TC-S11 | Biz | 11 |
| 8 | `test_notification_12_view_uses_correct_route_names_and_endpoints` | TC-P12 | Biz | 12 |
| 9 | `test_notification_13_test_notification_ignores_constructor_argument` | TC-S13 | Biz defect | 13 |
| 10 | `test_notification_30_guest_is_redirected_to_login` | TC-N30 | Negative | 30 |
| 11 | `test_notification_31_all_routes_require_auth_and_verified_middleware` | TC-N31 | Negative | 31 |
| 12 | `test_notification_40_notifiable_morph_columns_present` | TC-P40 | Ref | 40 |
| 13 | `test_notification_41_user_model_exposes_notifiable_relations` | TC-P41 | Int | 41 |
| 14 | `test_notification_50_allnotifications_gated_prime_notification_viewany` | TC-A50 | Perm | 50 |
| 15 | `test_notification_51_testnotification_gated_prime_notification_create` | TC-A51 | Perm | 51 |
| 16 | `test_notification_52_destroy_references_undefined_delete_ability` | TC-A52 | Perm/defect | 52 |
| 17 | `test_notification_53_super_admin_gate_before_bypass_exists` | TC-A53 | Perm | 53 |
| 18 | `test_notification_54_mark_read_actions_are_ungated` | TC-A54 | Perm | 54 |
| 19 | `test_notification_60_all_notifications_page_renders_for_admin` | TC-P60 | UI | 60 |
| 20 | `test_notification_61_filter_buttons_present` | TC-P61 | UI | 61 |
| 21 | `test_notification_62_unread_filter_renders_rows_or_empty_state` | TC-P62 | UI | 62 |
| 22 | `test_notification_63_breadcrumb_shows_notifications_title` | TC-P63 | UI | 63 |
| 23 | `test_notification_70_test_notification_route_creates_and_lists_notification` | TC-P70 | Action | 70 |
| 24 | `test_notification_71_mark_all_read_returns_success_and_zero_unread` | TC-P71 | Action/API | 71 |
| 25 | `test_notification_72_delete_notification_returns_success_json` | TC-P72 | Action/API | 72 |
| 26 | `test_notification_73_mark_single_read_returns_success_json` | TC-P73 | Action/API | 73 |
| 27 | `test_notification_80_test_notification_route_is_environment_guarded_in_source` | TC-S80 | Config/SEC | 80 |
| 28 | `test_notification_81_test_notification_route_registered_in_testing_env` | TC-S81 | Config | 81 |
| 29 | `test_notification_82_controller_testnotification_has_no_internal_env_check` | TC-S82 | Config/SEC | 82 |
| 30 | `test_notification_90_markasread_is_ownership_scoped` | TC-S90 | Security | 90 |
| 31 | `test_notification_91_destroy_is_ownership_scoped` | TC-S91 | Security | 91 |
| 32 | `test_notification_92_routes_under_central_dashboard_group` | TC-S92 | Security | 92 |
| 33 | `test_notification_93_guest_json_request_is_rejected` | TC-N93 | Negative | 93 |

**Total: 33 test methods.**

---

## 4. Known Source Defects

| ID | Severity | Description | Proving test | Status |
|----|----------|-------------|--------------|--------|
| SEC-PRM-002 | ~~P1~~ **REFUTED** | Brief claimed test-notification is an unguarded production debug route. **Source shows it IS environment-guarded at registration.** Only residual: no internal env check in method. | `test_..._80`, `_82` | Refuted / documented |
| DEV-PRM-NTF-001 | P3 | `destroy()` authorizes `prime.notification.delete` — ability never `Gate::define`d and no policy `delete()` method; non-super-admins with `tenant.notification.*` cannot delete (only super-admin `Gate::before` bypass works). | `test_..._52`, `_05` | Open |
| DEV-PRM-NTF-002 | P4 | `TestNotification` ignores its constructor `$user` and uses `User::inRandomOrder()->first()` for the message body. | `test_..._13` | Open (debug artifact) |
