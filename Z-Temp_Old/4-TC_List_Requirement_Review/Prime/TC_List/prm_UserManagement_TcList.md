# User Management (Platform Staff) — Test Case List

**Feature:** User Management (Platform Staff) | **REQ-ID:** REQ-PRM-007 | **Controller:** `UserController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 48 | — | — | — | 48 | 0% |

---

## 2. Index/List — User List (`GET /prime/user`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-001 | Verify user list loads with paginated results | Authenticated with `prime.user.viewAny`; 10+ users exist | — | Page renders 10 users per page, ordered by is_super_admin DESC then name ASC | — | — | ⬜ |
| TC-PRM-UM-002 | Verify stats cards show correct counts | Users and roles and tenants exist | — | totalUsers, totalRoles, totalTenants, activeTenants displayed with correct values | — | — | ⬜ |
| TC-PRM-UM-003 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login page | — | — | ⬜ |
| TC-PRM-UM-004 | Verify user without permission receives 403 | Authenticated without `prime.user.viewAny` | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-UM-005 | Verify usersByRole filters correctly by role | Users assigned to role "Admin" and "Manager" | role=Admin | Only users with role "Admin" displayed; currentRole variable set | — | — | ⬜ |
| TC-PRM-UM-006 | Verify usersByRole with non-existent role returns empty | No users with role "NonExistent" | role=NonExistent | Empty results; pagination shows 0 records | — | — | ⬜ |

---

## 3. Create/Store — User Create (`GET /prime/user/create` + `POST /prime/user`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-007 | Verify create form loads | Authenticated with `prime.user.create` | — | Create form renders | — | — | ⬜ |
| TC-PRM-UM-008 | Verify valid user creation succeeds with all fields | Valid role exists | name=John, email=john@test.com, emp_code=EMP001, short_name=JohnD, phone_no=1234567890, mobile_no=9876543210, password=Pass1234, roles=["Admin"] | User created; redirected; activity log written; email verification sent; LoginMail sent | — | — | ⬜ |
| TC-PRM-UM-009 | Verify user creation with image upload | Valid image file (jpg, 500KB) | user_img=photo.jpg | Image uploaded to media library with conversions; user created | — | — | ⬜ |
| TC-PRM-UM-010 | Verify duplicate email rejected | Existing user with email=john@test.com | email=john@test.com | Validation error: email already exists | — | — | ⬜ |
| TC-PRM-UM-011 | Verify duplicate emp_code rejected | Existing user with emp_code=EMP001 | emp_code=EMP001 | Validation error: emp_code already exists | — | — | ⬜ |
| TC-PRM-UM-012 | Verify password confirmation mismatch | — | password=Pass1234, password_confirmation=Diff5678 | Validation error: passwords do not match | — | — | ⬜ |
| TC-PRM-UM-013 | Verify password minimum length | — | password=Shor1 | Validation error: password minimum 8 characters | — | — | ⬜ |
| TC-PRM-UM-014 | Verify email verification notification sent | Valid creation data | — | PrimeVerifyEmail notification queued | — | — | ⬜ |
| TC-PRM-UM-015 | Verify login email sent with credentials | Valid creation data | — | LoginMail sent to user email with password | — | — | ⬜ |
| TC-PRM-UM-016 | Verify super admin notification on user creation | Another active super admin exists | — | UserCreatedNotification sent to all active super admins | — | — | ⬜ |
| TC-PRM-UM-017 | Verify teacher role redirects to teacher profile | Created with role "Teacher" | roles=["Teacher"] | Redirected to `central.prime.teacher.completeProfile` route | — | — | ⬜ |
| TC-PRM-UM-018 | Verify user without create permission receives 403 | Authenticated without `prime.user.create` | — | 403 Forbidden on both GET create and POST store | — | — | ⬜ |

---

## 4. Show — User Detail (`GET /prime/user/{user}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-019 | Verify user detail view shows all fields | User with assigned roles exists | — | All user fields displayed; roles list shown | — | — | ⬜ |
| TC-PRM-UM-020 | Verify non-existent user returns 404 | User ID 99999 doesn't exist | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-UM-021 | Verify user without view permission receives 403 | Authenticated without `prime.user.view` | — | 403 Forbidden | — | — | ⬜ |

---

## 5. Edit/Update — User Edit (`GET /prime/user/{user}/edit` + `PUT /prime/user/{user}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-022 | Verify edit form loads with pre-filled data | User with roles exists | — | Edit form displays with current values; user roles pre-selected | — | — | ⬜ |
| TC-PRM-UM-023 | Verify valid update saves changes | Existing user | name=Updated Name | User updated; redirect; activity log shows changed fields with old/new values | — | — | ⬜ |
| TC-PRM-UM-024 | Verify password change only when filled | Existing user; new password=NewPass5678 | password=NewPass5678 | Password updated; user can login with new password | — | — | ⬜ |
| TC-PRM-UM-025 | Verify empty password does not change password | Existing user | password left empty | Password unchanged | — | — | ⬜ |
| TC-PRM-UM-026 | Verify role sync works on update | Existing user with 1 role; 2 new roles selected | roles=["Admin", "Manager"] | User's roles replaced with selected roles | — | — | ⬜ |
| TC-PRM-UM-027 | Verify user without update permission receives 403 | Authenticated without `prime.user.update` | — | 403 Forbidden on edit and update | — | — | ⬜ |

---

## 6. Delete/Trash — User Soft-Delete (`DELETE /prime/user/{user}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-028 | Verify soft-delete sets is_active=false and deleted_at | Active user | — | User is_active set to false; deleted_at timestamp set; redirect; activity log written | — | — | ⬜ |
| TC-PRM-UM-029 | Verify self-deletion blocked | Current authenticated user | — | Error message: cannot delete own account | — | — | ⬜ |
| TC-PRM-UM-030 | Verify user without delete permission receives 403 | Authenticated without `prime.user.delete` | — | 403 Forbidden | — | — | ⬜ |

---

## 7. Trash/Restore/Force-Delete

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-031 | Verify trashed list shows only soft-deleted users | Soft-deleted users exist | — | Only soft-deleted users displayed, paginated | — | — | ⬜ |
| TC-PRM-UM-032 | Verify restore works correctly | Soft-deleted user | — | User restored; deleted_at set to NULL; redirect; activity log written | — | — | ⬜ |
| TC-PRM-UM-033 | Verify force-delete permanently removes user | Soft-deleted user | — | User permanently deleted; record gone from DB; activity log written | — | — | ⬜ |
| TC-PRM-UM-034 | Verify user without restore permission receives 403 | Authenticated without `prime.user.restore` | — | 403 Forbidden on trashed/restore | — | — | ⬜ |
| TC-PRM-UM-035 | Verify user without forceDelete permission receives 403 | Authenticated without `prime.user.forceDelete` | — | 403 Forbidden | — | — | ⬜ |

---

## 8. Toggle Status & Promote

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-036 | Verify toggle status deactivates user | Active user (not self) | is_active=false | JSON success; user is_active=false; activity log written | — | — | ⬜ |
| TC-PRM-UM-037 | Verify toggle status reactivates user | Inactive user (not self) | is_active=true | JSON success; user is_active=true; activity log written | — | — | ⬜ |
| TC-PRM-UM-038 | Verify self-toggle blocked | Current authenticated user | — | JSON error: cannot toggle own status | — | — | ⬜ |
| TC-PRM-UM-039 | Verify promoteToSuperAdmin grants super admin | Non-super-admin user | — | User becomes super admin; activity log written | — | — | ⬜ |
| TC-PRM-UM-040 | Verify promoteToSuperAdmin already super admin | User already super admin | — | Info message: "User is already a Super Admin." | — | — | ⬜ |
| TC-PRM-UM-041 | Verify promoteToSuperAdmin without gate permission | Authenticated without `prime.super-admin.promote` | — | 403 Forbidden | — | — | ⬜ |

---

## 9. 2FA OTP Flow

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-UM-042 | Verify sendOtpPreCreate sends OTP | — | mobile_no=9876543210 | JSON success; OTP stored in session; SMS sent | — | — | ⬜ |
| TC-PRM-UM-043 | Verify sendOtpPreCreate invalid mobile | — | mobile_no=123 | Validation error: digits_between:10,12 | — | — | ⬜ |
| TC-PRM-UM-044 | Verify verifyOtpPreCreate with valid OTP | OTP sent to session | otp=123456 (matches session) | JSON success; 2fa_pre_verified set to true | — | — | ⬜ |
| TC-PRM-UM-045 | Verify verifyOtpPreCreate with invalid OTP | OTP sent to session | otp=999999 (doesn't match) | JSON 422 error: "Invalid OTP. Please try again." | — | — | ⬜ |
| TC-PRM-UM-046 | Verify verifyOtpPreCreate with expired OTP | OTP expired (past 10 minutes) | otp=123456 | JSON 422 error: "OTP has expired." | — | — | ⬜ |
| TC-PRM-UM-047 | Verify sendEnableOtp sends OTP for existing user | Authenticated with update permission | mobile_no=9876543210 | JSON success; TwoFactorService called | — | — | ⬜ |
| TC-PRM-UM-048 | Verify verifyEnableOtp enables 2FA | Valid OTP flow | otp=123456 | JSON success; user two_factor_auth_enabled=true; mobile_verified_at set | — | — | ⬜ |

---

## 10. Permissions Matrix

| Role | viewAny | create | update | view | delete | restore | forceDelete | promoteSuperAdmin |
|------|:-------:|:------:|:------:|:----:|:------:|:-------:|:-----------:|:----------------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Platform Finance | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Platform IT/Ops | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| School Admin | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 11. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-UM-001 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-UM-002 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-UM-003 | REQ-PRM-007 | BR-PRM-023 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-004 | REQ-PRM-007 | BR-PRM-023 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-005 | REQ-PRM-007 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-UM-006 | REQ-PRM-007 | — | Negative/Filter | P2 | Functional | ⬜ |
| TC-PRM-UM-007 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-UM-008 | REQ-PRM-007 | BR-PRM-019 | Positive | P0 | Functional | ⬜ |
| TC-PRM-UM-009 | REQ-PRM-007 | — | Positive/Media | P1 | Functional | ⬜ |
| TC-PRM-UM-010 | REQ-PRM-007 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-UM-011 | REQ-PRM-007 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-UM-012 | REQ-PRM-007 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-UM-013 | REQ-PRM-007 | — | Negative/Boundary | P2 | Functional | ⬜ |
| TC-PRM-UM-014 | REQ-PRM-007 | — | Positive/Notification | P1 | Integration | ⬜ |
| TC-PRM-UM-015 | REQ-PRM-007 | BR-PRM-019 | Positive/Notification | P0 | Integration | ⬜ |
| TC-PRM-UM-016 | REQ-PRM-007 | — | Positive/Notification | P1 | Integration | ⬜ |
| TC-PRM-UM-017 | REQ-PRM-007 | — | Positive/Redirect | P1 | Functional | ⬜ |
| TC-PRM-UM-018 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-019 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-UM-020 | REQ-PRM-007 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-UM-021 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-022 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-UM-023 | REQ-PRM-007 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-UM-024 | REQ-PRM-007 | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-UM-025 | REQ-PRM-007 | — | Positive/Edge | P1 | Functional | ⬜ |
| TC-PRM-UM-026 | REQ-PRM-007 | — | Positive | P1 | Functional | ⬜ |
| TC-PRM-UM-027 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-028 | REQ-PRM-007 | BR-PRM-023 | Positive/Soft-Delete | P0 | Functional | ⬜ |
| TC-PRM-UM-029 | REQ-PRM-007 | — | Negative/Security | P0 | Security | ⬜ |
| TC-PRM-UM-030 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-031 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-UM-032 | REQ-PRM-007 | BR-PRM-023 | Positive/Restore | P0 | Functional | ⬜ |
| TC-PRM-UM-033 | REQ-PRM-007 | BR-PRM-023 | Positive/Force-Delete | P0 | Functional | ⬜ |
| TC-PRM-UM-034 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-035 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-036 | REQ-PRM-007 | BR-PRM-023 | Positive/Toggle | P0 | Functional | ⬜ |
| TC-PRM-UM-037 | REQ-PRM-007 | BR-PRM-023 | Positive/Toggle | P0 | Functional | ⬜ |
| TC-PRM-UM-038 | REQ-PRM-007 | — | Negative/Security | P0 | Security | ⬜ |
| TC-PRM-UM-039 | REQ-PRM-007 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-UM-040 | REQ-PRM-007 | — | Positive/Edge | P2 | Functional | ⬜ |
| TC-PRM-UM-041 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-UM-042 | REQ-PRM-007 | — | Positive/2FA | P1 | Integration | ⬜ |
| TC-PRM-UM-043 | REQ-PRM-007 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-UM-044 | REQ-PRM-007 | — | Positive/2FA | P1 | Integration | ⬜ |
| TC-PRM-UM-045 | REQ-PRM-007 | — | Negative/2FA | P1 | Integration | ⬜ |
| TC-PRM-UM-046 | REQ-PRM-007 | — | Negative/2FA-Expiry | P1 | Integration | ⬜ |
| TC-PRM-UM-047 | REQ-PRM-007 | — | Positive/2FA | P1 | Integration | ⬜ |
| TC-PRM-UM-048 | REQ-PRM-007 | — | Positive/2FA | P1 | Integration | ⬜ |

---

## 12. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | `is_super_admin` is in `$fillable` — privilege escalation risk via mass assignment | TC-PRM-UM-008, TC-PRM-UM-023 | Critical | ⬜ |
| 2 | `usersByRole()` uses stub data for totalStudents and totalClasses | TC-PRM-UM-005 | Low | ⬜ |
| 3 | `UserRequest` field `two_fact_enabled` naming inconsistency | — | Low | ⬜ |
| 4 | No feature tests exist for any UserController method | All TCs | High | ⬜ |

---

## 13. Route Reference

| Method | URI | Name | Middleware |
|--------|-----|------|-----------|
| GET | `/prime/user` | `central.prime.user.index` | web, auth, verified |
| GET | `/prime/user/create` | `central.prime.user.create` | web, auth, verified |
| POST | `/prime/user` | `central.prime.user.store` | web, auth, verified |
| GET | `/prime/user/{user}` | `central.prime.user.show` | web, auth, verified |
| GET | `/prime/user/{user}/edit` | `central.prime.user.edit` | web, auth, verified |
| PUT | `/prime/user/{user}` | `central.prime.user.update` | web, auth, verified |
| DELETE | `/prime/user/{user}` | `central.prime.user.destroy` | web, auth, verified |
| GET | `/prime/user/{role}/by-role` | `central.prime.user.byRole` | web, auth, verified |
| GET | `/prime/user/trash/view` | `central.prime.user.trashed` | web, auth, verified |
| GET | `/prime/user/{id}/restore` | `central.prime.user.restore` | web, auth, verified |
| DELETE | `/prime/user/{id}/force-delete` | `central.prime.user.forceDelete` | web, auth, verified |
| POST | `/prime/user/{user}/toggle-status` | `central.prime.user.toggleStatus` | web, auth, verified |
| POST | `/prime/user/{user}/promote-super-admin` | `central.prime.user.promoteSuperAdmin` | web, auth, verified |
| POST | `/prime/user/{user}/send-otp` | `central.prime.user.sendOtp` | web, auth, verified |
| POST | `/prime/user/{user}/verify-otp` | `central.prime.user.verifyOtp` | web, auth, verified |
| POST | `/prime/user/send-otp-pre` | `central.prime.user.sendOtpPre` | web |
| POST | `/prime/user/verify-otp-pre` | `central.prime.user.verifyOtpPre` | web |

---

## 14. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-UM-001 | ⬜ | — | — | — | — |
| TC-PRM-UM-002 | ⬜ | — | — | — | — |
| ... (all 48 TCs) | ⬜ | — | — | — | — |
