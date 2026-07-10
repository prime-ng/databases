# Prime → User — Manual Testing Spec (`sys_UserMANUALTESTING_Require.md`)

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | Prime (PRM) |
| Feature | User (central user management) |
| DB scope | CENTRAL `prime_db` / connection `mysql` (no tenant init) |
| Base URL | `http://127.0.0.1:8000` |
| Index URL | `/prime/user` (route `central.prime.user.index`) |
| Create URL | `/prime/user/create` |
| Trash URL | `/prime/user/trash/view` |
| Controller | `Modules\Prime\Http\Controllers\UserController` |
| Request | `Modules\Prime\Http\Requests\UserRequest` |
| Models | `Modules\Prime\Models\User` (app), `App\Models\User` (runner), `Modules\Prime\Models\ActivityLog` |
| Primary table | `sys_users` |
| Soft delete | Yes (`deleted_at`) |
| Pagination | 10 / page |
| Activity log | `sys_central_activity_logs` (central) |
| Permissions | `prime.user.{viewAny,view,create,update,delete,restore,forceDelete}`, `prime.super-admin.promote` |

**Prerequisites:** Prime module ENABLED in `modules_statuses.json`; `APP_ENV=testing`; admin creds `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`; central DB reachable on `mysql` connection; a seeded super-admin row exists.

## 2. Business Conditions (with flows)

### Super-admin escalation guard (SEC-PRM-003 — remediated)
Elevation is **not** possible through `POST /prime/user/{user}` (update). The controller whitelists only:
`name, email, emp_code, phone_no, mobile_no, is_active, two_factor_auth_enabled` — `is_super_admin` is excluded.
The model `$fillable` also excludes `is_super_admin` and `super_admin_flag`. Elevation requires
`POST /prime/user/{user}/promote-super-admin`, gated by `prime.super-admin.promote`.

```
[Edit user] --(post is_super_admin=1)--> update(): $request->only([... no is_super_admin ...]) --> flag UNCHANGED
[Promote]   --(prime.super-admin.promote)--> promoteToSuperAdmin(): is_super_admin=1 --> super_admin_flag(generated)=1
```

### Store flow
```
store(): validate(UserRequest) -> Hash::make(password) -> User::create(whitelist) -> syncRoles
      -> activityLog('created') -> Notify super admins (UserCreatedNotification)
      -> Mail::to(new user) LoginMail(credentials) -> redirect user-role-prm.index#tanent
```

### Known defects to observe manually
- **BUG-PRM-N01:** open `/prime/user/{roleName}/by-role`; the index view references `$totalTenants`/`$activeTenants` which `usersByRole()` does not pass → expect an undefined-variable error on that page.
- **BUG-PRM-N02:** toggle Two-Factor on the create form and submit; the value never persists (`two_fact_enabled` validated but controller reads `two_factor_auth_enabled`).
- **BUG-PRM-N03:** upload an oversized/non-image `user_img`; the `image|max:2048` rule never fires (rule keyed `image`, upload keyed `user_img`).
- **BUG-PRM-009:** the "Roles/Students/Classes" stats on a by-role page change on every refresh (rand()).

## 3. Test Cases (step / action / expected)

### TC-P01 — Schema & config truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW COLUMNS FROM sys_users` | All BC-DB-01 columns present |
| 2 | `SHOW INDEX FROM sys_users` | uq_users_empCode/email/mobileNo/single_super_admin |
| 3 | Inspect `Modules\Prime\Models\User` | fillable excludes is_super_admin & super_admin_flag; casts is_super_admin=boolean, password=hashed; SoftDeletes |

### TC-S90 — Escalation prevented
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin, edit a normal user | Edit form loads |
| 2 | Add hidden `is_super_admin=1`, submit `POST /prime/user/{id}` | `SELECT is_super_admin FROM sys_users WHERE id={id}` still 0 |
| 3 | `POST /prime/user/{id}/promote-super-admin` as a user WITHOUT the promote gate | 403 Forbidden |

### TC-P10 — Create user emails credentials
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit create form with valid data | Redirect with success; row in sys_users |
| 2 | Check mail log | `LoginMail` sent to the new user with emp_code + password |
| 3 | `SELECT event FROM sys_central_activity_logs ORDER BY id DESC LIMIT 1` | `created` |

### TC-N30 — Validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit blank form | Errors: name/email/password/emp_code/short_name/roles required |
| 2 | Duplicate email | "email has already been taken" |
| 3 | password < 8 or mismatch | min:8 / confirmed error |
| 4 | Select 2 roles | roles max:1 error |
| 5 | phone_no non-10-digit | digits:10 error |

### TC-N17 / TC-N18 — Self-guard
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete own account | Redirect index with `unauthorized.user` error; not deleted |
| 2 | Toggle own status | JSON `{success:false}` |

### TC-D45 — Super-admin protection
| Step | Action | Expected |
|------|--------|----------|
| 1 | `DELETE` a super-admin row directly | SQLSTATE 45000 "Super Admin cannot be deleted" |
| 2 | Set super admin is_super_admin=0 | SQLSTATE 45000 "Super Admin cannot be demoted" |
| 3 | Insert 2nd super admin | Unique key `uq_single_super_admin` violation |

### TC-AUTH50–56 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/prime/user` as guest | Redirect `/login` |
| 2 | As user lacking `prime.user.viewAny` | 403 on index |
| 3 | As user lacking update/delete | Status toggle + Action controls hidden |

### TC-P60–64 — UI smoke
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit index | "User Management", 4 small-box widgets, table, pagination (10/pg) |
| 2 | Visit create | name/short_name/emp_code/email/phone_no/mobile_no/password/password_confirmation/user_img/roles + "Create User" |
| 3 | Visit trash | Trashed users table |
