# Prime — User Management (Platform Staff)

**Feature:** User Management (Platform Staff) | **REQ-ID:** REQ-PRM-007 | **Priority:** P0 (MUST)

---

## 1. Description

The User Management feature enables Super Admins to manage PrimeGurukul platform staff accounts. Platform staff are employees of PrimeGurukul (not school-level staff) who operate the central management console. Super Admins can create, view, edit, soft-delete, restore, and permanently delete user records. New users receive their login credentials by email upon creation. The feature also supports role assignment through Spatie's permission package, user image upload via Spatie Media Library, two-factor authentication enablement via OTP verification, and a dedicated super-admin promotion flow with OTP verification.

**Key Capabilities:**
- Create platform staff accounts with name, email, employee code, phone, mobile, short name, and photo
- Assign exactly one role per user during creation (roles dropdown limited to single selection)
- Toggle user active/inactive status via AJAX
- Soft-delete, restore from trash, and force-delete
- Send login credentials via email on creation (LoginMail)
- Send email verification notification (MustVerifyEmail contract)
- 2FA enablement flow: send OTP → verify OTP → enable two-factor authentication
- Pre-create OTP verification: send OTP to mobile before user creation → session-based verification
- Promote user to Super Admin via dedicated gated flow (protected route, not via web form)
- Filter users by role (`usersByRole` endpoint)
- Activity logging for all state-changing operations

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/Prime/app/Http/Controllers/UserController.php` | 514 | PARTIAL |
| Model | `Modules/Prime/app/Models/User.php` | 195 | PARTIAL |
| Form Request | `Modules/Prime/app/Http/Requests/UserRequest.php` | 58 | EXISTS |
| View (index) | `prime::user.index` | — | EXISTS |
| View (create) | `prime::user.create` | — | EXISTS |
| View (edit) | `prime::user.edit` | — | EXISTS |
| View (show) | `prime::user.show` | — | EXISTS |
| View (trash) | `prime::user.trash` | — | EXISTS |

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/prime/user` | `index` | `prime.user.viewAny` | ✅ Gate check present |
| GET | `/prime/user/create` | `create` | `prime.user.create` | ✅ Gate check present |
| POST | `/prime/user` | `store` | `prime.user.create` | ✅ Gate check present |
| GET | `/prime/user/{user}` | `show` | `prime.user.view` | ✅ Gate check present |
| GET | `/prime/user/{user}/edit` | `edit` | `prime.user.update` | ✅ Gate check present |
| PUT | `/prime/user/{user}` | `update` | `prime.user.update` | ✅ Gate check present |
| DELETE | `/prime/user/{user}` | `destroy` | `prime.user.delete` | ✅ Gate check present |
| GET | `/prime/user/{role}/by-role` | `usersByRole` | `prime.user.viewAny` | ✅ Gate check present |
| GET | `/prime/user/trash/view` | `trashedUser` | `prime.user.restore` | ✅ Gate check present |
| GET | `/prime/user/{id}/restore` | `restore` | `prime.user.restore` | ✅ Gate check present |
| DELETE | `/prime/user/{id}/force-delete` | `forceDelete` | `prime.user.forceDelete` | ✅ Gate check present |
| POST | `/prime/user/{user}/toggle-status` | `toggleStatus` | `prime.user.update` | ✅ Gate check present |
| POST | `/prime/user/{user}/promote-super-admin` | `promoteToSuperAdmin` | `prime.super-admin.promote` | ✅ Gate check present |
| POST | `/prime/user/{user}/send-otp` | `sendEnableOtp` | `prime.user.update` | ✅ Gate check present |
| POST | `/prime/user/{user}/verify-otp` | `verifyEnableOtp` | `prime.user.update` | ✅ Gate check present |
| POST | `/prime/user/send-otp-pre` | `sendOtpPreCreate` | — | ✅ No auth required for pre-create |
| POST | `/prime/user/verify-otp-pre` | `verifyOtpPreCreate` | — | ✅ No auth required for pre-create |

All routes are central domain (not tenant-scoped), registered under the `web` middleware group with `auth` and `verified` middlewares.

---

## 4. Data Model

### 4.1 User (`sys_users` — prime_db)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `emp_code` | VARCHAR(20) | ✅ | — | UNIQUE |
| `short_name` | VARCHAR(30) | ✅ | — | UNIQUE; used for dropdown display |
| `name` | VARCHAR(100) | ✅ | — | Full name |
| `email` | VARCHAR(150) | ✅ | — | UNIQUE; login identifier |
| `mobile_no` | VARCHAR(32) | — | NULL | UNIQUE; used for 2FA |
| `phone_no` | VARCHAR(32) | — | NULL | Landline |
| `two_factor_auth_enabled` | TINYINT(1) | ✅ | 0 | Boolean flag for 2FA |
| `email_verified_at` | TIMESTAMP | — | NULL | Email verification timestamp |
| `mobile_verified_at` | TIMESTAMP | — | NULL | Mobile verification timestamp |
| `password` | VARCHAR(255) | ✅ | — | Hashed (bcrypt via Laravel) |
| `is_super_admin` | TINYINT(1) | ✅ | 0 | Boolean — guarded from mass assignment |
| `last_login_at` | DATETIME | — | NULL | Last successful login |
| `super_admin_flag` | TINYINT GENERATED | — | — | Generated column: CASE WHEN is_super_admin=1 THEN 1 ELSE NULL END; UNIQUE |
| `is_active` | TINYINT(1) | ✅ | 1 | Boolean |
| `is_pg_user` | TINYINT(1) | ✅ | 0 | Flag for PrimeGurukul staff |
| `remember_token` | VARCHAR(100) | — | NULL | Laravel auth remember token |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |
| `deleted_at` | TIMESTAMP | — | NULL | Soft delete timestamp |

**Database Triggers:**
- `trg_users_prevent_delete_super`: Prevents DELETE when `is_super_admin = 1`
- `trg_users_prevent_update_super`: Prevents UPDATE setting `is_super_admin = 0` when previously 1

**Model Fillable:** name, short_name, emp_code, email, phone_no, mobile_no, password, two_factor_auth_enabled, email_verified_at, mobile_verified_at, is_active, status_id, last_login_at, remember_token, prefered_language
**Model Hidden:** password, remember_token
**Model Casts:** email_verified_at (datetime), mobile_verified_at (datetime), password (hashed), is_super_admin (boolean), is_active (boolean), two_factor_auth_enabled (boolean)

### 4.2 Media Collections

| Collection Name | Single File | Conversions |
|----------------|:-----------:|-------------|
| `image` | Yes | small (100×100), medium (300×300), large (600×600) |

### 4.3 Relations

| Relation | Type | Target |
|----------|------|--------|
| `activityLogs` | hasMany | `Modules\Prime\Models\ActivityLog` |
| `auditLogs` | hasMany | `Modules\Prime\Models\TenantInvoicingAuditLog` (via `performed_by`) |
| `userOtps` | hasMany | `App\Models\UserOtp` (via `user_id`) |
| `roles` | MorphToMany | Spatie permission roles (via `sys_model_has_roles_jnt`) |
| `permissions` | MorphToMany | Spatie permission permissions (via `sys_model_has_permissions_jnt`) |

---

## 5. Controller Implementation Details

### 5.1 `index(Request $request)`

- **Gate:** `Gate::authorize('prime.user.viewAny')`
- **Stats:** Displays totalUsers count, totalRoles count, totalTenants count, activeTenants count
- **Query:** Users ordered by `is_super_admin` DESC then `name` ASC, paginated 10 per page
- **Data:** Also loads all roles for filter dropdown
- **View:** `prime::user.index` with `compact('roles', 'users', 'totalUsers', 'totalRoles', 'totalTenants', 'activeTenants')`

### 5.2 `usersByRole(string $role)`

- **Gate:** `Gate::authorize('prime.user.viewAny')`
- **Stats:** totalUsers, totalRoles, random stub values for totalStudents (1000–2000) and totalClasses (10–30)
- **Query:** `User::role($role)->paginate(10)` — uses Spatie's `role()` scope
- **View:** Same index view with `currentRole` variable for filtering context

### 5.3 `create()`

- **Gate:** `Gate::authorize('prime.user.create')`
- **View:** `prime::user.create`

### 5.4 `store(UserRequest $request)`

- **Gate:** `Gate::authorize('prime.user.create')`
- **Transaction:** Wrapped in `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()` on exception
- **Data:** Collects `name, email, emp_code, phone_no, mobile_no, short_name, is_active` from validated request
- **Password:** Hashed via `Hash::make()`; plain password retained for email
- **2FA Pre-Verification:** If `session('2fa_pre_verified')` is true, sets `two_factor_auth_enabled = true`, `mobile_verified_at = now()`, and uses session mobile number
- **Roles:** `$user->syncRoles($request->roles)` — assigns selected roles
- **Image:** If `user_img` file present, clears existing media collection and adds new media
- **Session Cleanup:** Forgets `2fa_pre_verified`, `2fa_pre_otp`, `2fa_pre_mobile`, `2fa_pre_expires` from session
- **Audit:** `activityLog($user, 'created', ...)`
- **Notifications:** Sends `UserCreatedNotification` to all active Super Admins (except current user)
- **Email Verification:** Calls `$user->sendEmailVerificationNotification()` — sends PrimeVerifyEmail via MustVerifyEmail contract
- **Login Email:** If user has email, sends `LoginMail` with credentials (subject: "Your Prime Central Login Credentials", includes Name, Email, Employee Code, and password in info section)
- **Teacher Redirect:** If roles include 'Teacher', redirects to `central.prime.teacher.completeProfile` route
- **Default Redirect:** Redirects to `central.prime.user-role-prm.index` with `#tanent` fragment

### 5.5 `show(User $user)`

- **Gate:** `Gate::authorize('prime.user.view')`
- **Eager Load:** `$user->load('roles')`
- **View:** `prime::user.show` with `compact('user')`

### 5.6 `edit(User $user)`

- **Gate:** `Gate::authorize('prime.user.update')`
- **Data:** `$userRoles = $user->roles->pluck('name')->toArray()`
- **View:** `prime::user.edit` with `compact('user', 'userRoles')`

### 5.7 `update(UserRequest $request, User $user)`

- **Gate:** `Gate::authorize('prime.user.update')`
- **Transaction:** Wrapped in `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()`
- **Data:** Collects `name, email, emp_code, phone_no, mobile_no, is_active, two_factor_auth_enabled` — explicitly excludes `is_super_admin`
- **Password:** Only updates if `$request->filled('password')` — allows optional password change
- **Role Sync:** Maps role names to actual Role models by name (handles duplicate names by fetching via `Role::where('name', $roleName)->first()`)
- **Image:** Same as store — handles media upload
- **Audit:** Captures changed attributes with old/new values; passes only changed fields to `activityLog()`
- **Redirect:** Same as store — `central.prime.user-role-prm.index#tanent`

### 5.8 `destroy(User $user)`

- **Gate:** `Gate::authorize('prime.user.delete')`
- **Self-Delete Prevention:** If `$user->id === Auth::user()->id`, redirects with error flash
- **Logic:** Sets `is_active = false`, saves, then calls `$user->delete()` (soft-delete)
- **Audit:** `activityLog($user, 'Trashed', ...)`
- **Redirect:** `central.prime.user-role-prm.index#tanent`

### 5.9 `trashedUser()`

- **Gate:** `Gate::authorize('prime.user.restore')`
- **Query:** `User::onlyTrashed()->paginate(10)`
- **View:** `prime::user.trash` with `compact('users')`

### 5.10 `restore($id)`

- **Gate:** `Gate::authorize('prime.user.restore')`
- **Query:** `User::withTrashed()->findOrFail($id)`
- **Logic:** Calls `$user->restore()`
- **Audit:** `activityLog($user, 'Restored', ...)`
- **Redirect:** `central.prime.user.trashed` with success flash

### 5.11 `forceDelete($id)`

- **Gate:** `Gate::authorize('prime.user.forceDelete')`
- **Query:** `User::withTrashed()->findOrFail($id)`
- **Logic:** Calls `$user->forceDelete()`
- **Audit:** `activityLog($user, 'Deleted', ...)`
- **Redirect:** `central.prime.user.trashed` with success flash

### 5.12 `toggleStatus(Request $request, User $user)`

- **Gate:** `Gate::authorize('prime.user.update')`
- **Validation:** `is_active` required, boolean
- **Self-Toggle Prevention:** Cannot toggle own status; returns JSON error
- **Logic:** Sets `$user->is_active` to request value and saves
- **Audit:** `activityLog($user, 'Toggled', ...)`
- **Response:** JSON `{ success, is_active, message }`

### 5.13 `promoteToSuperAdmin(User $user)`

- **Gate:** `Gate::authorize('prime.super-admin.promote')` — dedicated high-privilege gate
- **Already Super Admin Check:** If already super admin, redirects with info message
- **Logic:** Sets `$user->is_super_admin = true`, saves
- **Audit:** `activityLog($user, 'Promoted', ...)`
- **Redirect:** Back with success flash

### 5.14 `sendOtpPreCreate(Request $request)` — JSON

- **Validation:** `mobile_no` required, `digits_between:10,12`
- **OTP Generation:** Random 6-digit integer
- **Session Storage:** Stores `2fa_pre_otp`, `2fa_pre_mobile`, `2fa_pre_expires` (10 minutes from now)
- **SMS:** Sends OTP via `SmsService`
- **Response:** JSON `{ success: true, message: "OTP sent successfully." }`

### 5.15 `verifyOtpPreCreate(Request $request)` — JSON

- **Validation:** `otp` required, string, size:6
- **Expiry Check:** If session OTP missing or expired (>10 min), returns JSON 422 error
- **Match Check:** If OTP does not match, returns JSON 422 error
- **Session Update:** Sets `2fa_pre_verified = true`, clears OTP and expiry
- **Response:** JSON `{ success: true, message: "OTP verified successfully. 2FA will be enabled on save." }`

### 5.16 `sendEnableOtp(Request $request, User $user)` — JSON

- **Gate:** `Gate::authorize('prime.user.update')`
- **Validation:** `mobile_no` required, `digits_between:10,12`
- **Logic:** Delegates to `TwoFactorService::generateAndSendOtp(userId, mobile, type: 'enable_2fa')`
- **Response:** JSON `{ success, message }`

### 5.17 `verifyEnableOtp(Request $request, User $user)` — JSON

- **Gate:** `Gate::authorize('prime.user.update')`
- **Validation:** `otp` required, string, size:6
- **Logic:** Delegates to `TwoFactorService::verifyOtp(userId, otp, type: 'enable_2fa')`
- **On Success:** Updates `two_factor_auth_enabled = true`, `mobile_no`, `mobile_verified_at = now()`
- **Audit:** `activityLog($user, 'Updated', 'Two-factor authentication enabled for user')`
- **Response:** JSON `{ success, message }`

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-PRM-007 | Super Admin flag must not be set via web form or API — field is guarded in model | ⚠️ **Known Issue:** `is_super_admin` is NOT in `$fillable` but the `UserRequest::prepareForValidation()` does capture and merge it; the controller's `update()` explicitly excludes it via `$request->only(...)` but `store()` uses `$request->only(...)` which also excludes it because `is_super_admin` is not listed in the `only()` call. The promoteToSuperAdmin route is the intended path. However, `is_super_admin` is listed in `$fillable` as noted in AGENTS.md — this is a **P0 security risk**. |
| BR-PRM-019 | New platform user must receive automated email with login credentials | ✅ `store()` sends `LoginMail` with password |
| BR-PRM-023 | All state-changing operations must produce activity log entry | ✅ All create/update/delete/restore/forceDelete/toggleStatus/promote operations call `activityLog()` |

---

## 7. Security Rules

| Rule | Implementation |
|------|---------------|
| Gate check on `viewAny` | ✅ `index()`, `usersByRole()` |
| Gate check on `create` | ✅ `create()`, `store()` |
| Gate check on `view` | ✅ `show()` |
| Gate check on `update` | ✅ `edit()`, `update()`, `toggleStatus()`, `sendEnableOtp()`, `verifyEnableOtp()` |
| Gate check on `delete` | ✅ `destroy()` |
| Gate check on `restore` | ✅ `trashedUser()`, `restore()` |
| Gate check on `forceDelete` | ✅ `forceDelete()` |
| Dedicated super-admin promote gate | ✅ `promoteToSuperAdmin()` uses `prime.super-admin.promote` |
| Self-delete prevention | ✅ User cannot delete own account |
| Self-toggle prevention | ✅ User cannot toggle own status |
| OTP expiry (10 minutes) | ✅ `sendOtpPreCreate` and `sendEnableOtp` use expiry checks |
| Password hashed at rest | ✅ `Hash::make()` in store; `password` cast as `hashed` in model |
| `is_super_admin` guarded from web form | ⚠️ `is_super_admin` is NOT in `$fillable`, but the `UserRequest` prepareForValidation does merge `is_super_admin` from input — not used in controller `only()` calls, but still a risk |
| Email verification required | ✅ Model implements `MustVerifyEmail` |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | `is_super_admin` is in `$fillable` — privilege escalation risk via mass assignment | Security | P0 — Critical | ⬜ |
| 2 | `usersByRole()` uses stub data (`rand(1000, 2000)`) for totalStudents and totalClasses instead of real queries | Dashboard accuracy | P2 — Low | ⬜ |
| 3 | `UserRequest` field `two_fact_enabled` is mapped to `two_factor_auth_enabled` in prepareForValidation — naming inconsistency may cause confusion | Maintainability | P2 — Low | ⬜ |
| 4 | No feature tests exist for any UserController method | Testing gap | P1 — High | ⬜ |
| 5 | Pre-create OTP session keys could collide if multiple users are being created simultaneously | Concurrency | P2 — Low | ⬜ |
| 6 | The 2FA pre-create flow stores OTP in session rather than database — no persistence across browser sessions | Reliability | P2 — Low | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-PRM-007 | FRD §1.3 | Central Staff User Management — create, deactivate, soft-delete, restore |
| REQ-PRM-008 | FRD §1.3 | Role and Permission Management — role assignment to users |
| BR-PRM-007 | FRD §1.4 | Super Admin flag not settable via web form |
| BR-PRM-019 | FRD §1.4 | Login email on user creation |
| BR-PRM-023 | FRD §1.4 | Activity log for all state-changing actions |
| US-PRM-007 | FRD §8.1 | User story for platform staff account management |
| REQ-PRM-006 | FRD §1.3 | Central Platform Authentication — login/logout, domain scoping |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
