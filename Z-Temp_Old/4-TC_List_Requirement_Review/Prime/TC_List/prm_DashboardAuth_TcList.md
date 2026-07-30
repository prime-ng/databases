# Prime (PRM) — Dashboard & Authentication Test Case List

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Prime Dashboard & Central Authentication |
| **Sub-Features** | Platform Dashboard, User Login, OTP 2FA, Logout |
| **FRD Reference** | REQ-PRM-006 (Authentication), REQ-PRM-011 (Dashboard & Analytics), REQ-PRM-012 (Activity Log) |
| **Controller(s)** | `PrimeController`, `PrimeAuthController` |
| **TC List Version** | V1 |
| **CR ID** | ◌ |

---

## 2. Test Case Summary

| TC Total | TC Auto | TC Manual | TC Skipped | Blocked | Removed |
|:--------:|:-------:|:---------:|:----------:|:-------:|:-------:|
| 36 | 0 | 36 | — | — | — |

---

## 3. Test Cases

### 3.1 Login Page (Guest Routes)

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DASH-001 | Verify unauthenticated user can access login page | User is not logged in; central domain | — | Login page is displayed with email and password fields | — | ⬜ | — | ◌ |
| TC-PRM-DASH-002 | Verify authenticated user is redirected to dashboard when visiting /login | User is logged in | — | User is redirected to `central.prime.dashboard` | — | ⬜ | — | ◌ |
| TC-PRM-DASH-003 | Verify login page is not accessible from school subdomain | User on school subdomain | — | School's own login page is shown, not Prime login | — | ⬜ | — | ◌ |

### 3.2 Login Authentication

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DASH-004 | Verify successful login with valid credentials (no 2FA) | Valid active user with verified email, 2FA disabled | email: admin@prime.com, password: valid | User is authenticated, redirected to dashboard, login notification sent | — | ⬜ | — | ◌ |
| TC-PRM-DASH-005 | Verify login fails with invalid password | Valid active user | email: admin@prime.com, password: wrong | Error message displayed, user not authenticated | — | ⬜ | — | ◌ |
| TC-PRM-DASH-006 | Verify login fails with non-existent email | — | email: nobody@prime.com, password: any | Error message displayed, user not authenticated | — | ⬜ | — | ◌ |
| TC-PRM-DASH-007 | Verify login blocked for deactivated user | User exists with is_active = false | email: inactive@prime.com, password: valid | User is logged out, error: "Your account has been deactivated" | — | ⬜ | — | ◌ |
| TC-PRM-DASH-008 | Verify login blocked for unverified email | User exists with email_verified_at = null | email: unverified@prime.com, password: valid | User is logged out, error: "Please verify your email address before logging in" | — | ⬜ | — | ◌ |
| TC-PRM-DASH-009 | Verify login initiates 2FA OTP flow when 2FA enabled | User has two_factor_auth_enabled = true, has mobile_no | email: 2fa@prime.com, password: valid | Session variables set, OTP auto-sent, redirected to OTP challenge page | — | ⬜ | — | ◌ |
| TC-PRM-DASH-010 | Verify empty email field validation | — | email: (empty), password: any | Validation error: "The email field is required" | — | ⬜ | — | ◌ |
| TC-PRM-DASH-011 | Verify empty password field validation | — | email: admin@prime.com, password: (empty) | Validation error: "The password field is required" | — | ⬜ | — | ◌ |
| TC-PRM-DASH-012 | Verify login with invalid email format | — | email: not-an-email, password: valid | Validation error: invalid email format | — | ⬜ | — | ◌ |

### 3.3 OTP 2FA Challenge Flow

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DASH-013 | Verify OTP challenge page displays after 2FA initiation | User has 2fa:user_id in session after login | — | OTP challenge page is shown with OTP input field | — | ⬜ | — | ◌ |
| TC-PRM-DASH-014 | Verify OTP challenge page redirects to login if session expired | No 2fa:user_id in session | — | Redirected to login with error: "Session expired. Please log in again." | — | ⬜ | — | ◌ |
| TC-PRM-DASH-015 | Verify OTP challenge page redirects to dashboard if already authenticated | User is authenticated, no 2fa:user_id in session | — | Redirected to dashboard | — | ⬜ | — | ◌ |
| TC-PRM-DASH-016 | Verify valid OTP completes login | Valid OTP in session | otp: (valid 6-digit code) | User authenticated, 2FA session vars cleared, redirected to dashboard, login notification sent | — | ⬜ | — | ◌ |
| TC-PRM-DASH-017 | Verify invalid OTP shows error | Valid OTP in session | otp: 000000 (invalid) | Error: "Invalid or expired OTP. Please try again." | — | ⬜ | — | ◌ |
| TC-PRM-DASH-018 | Verify empty OTP field validation | Valid OTP in session | otp: (empty) | Validation error: "The otp field is required" | — | ⬜ | — | ◌ |
| TC-PRM-DASH-019 | Verify OTP with wrong length (less than 6) | Valid OTP in session | otp: 12345 | Validation error: "The otp field must be 6 characters" | — | ⬜ | — | ◌ |
| TC-PRM-DASH-020 | Verify OTP with wrong length (more than 6) | Valid OTP in session | otp: 1234567 | Validation error: "The otp field must be 6 characters" | — | ⬜ | — | ◌ |
| TC-PRM-DASH-021 | Verify "Resend OTP" sends new OTP | User has 2fa:user_id in session, has mobile_no | — | New OTP sent, success message: "OTP sent to your registered mobile number." | — | ⬜ | — | ◌ |
| TC-PRM-DASH-022 | Verify "Resend OTP" fails gracefully if user has no mobile | User has 2fa:user_id but mobile_no is null | — | Error: "No mobile number registered for 2FA. Contact administrator." | — | ⬜ | — | ◌ |
| TC-PRM-DASH-023 | Verify OTP send handles TwoFactorService exception | TwoFactorService throws exception | — | Error logged, user shown: "Failed to send OTP. Please try again." | — | ⬜ | — | ◌ |

### 3.4 Logout

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DASH-024 | Verify logout destroys session and redirects | User is authenticated | POST /logout | Session destroyed, token regenerated, redirected to /login | — | ⬜ | — | ◌ |
| TC-PRM-DASH-025 | Verify authenticated user cannot access dashboard after logout | User logged out | — | Accessing /dashboard redirects to login page | — | ⬜ | — | ◌ |

### 3.5 Dashboard Access

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DASH-026 | Verify authenticated user can access dashboard | User logged in, has prime.dashboard.viewAny permission | GET /dashboard | Dashboard view loads with all metric cards | — | ⬜ | — | ◌ |
| TC-PRM-DASH-027 | Verify user without permission gets 403 | User logged in, lacks prime.dashboard.viewAny permission | GET /dashboard | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-DASH-028 | Verify unauthenticated user redirected to login | User not logged in | GET /dashboard | Redirected to login page | — | ⬜ | — | ◌ |
| TC-PRM-DASH-029 | Verify dashboard shows correct tenant counts | Database has known tenant records | GET /dashboard | Total/active/inactive tenant counts match database | — | ⬜ | — | ◌ |
| TC-PRM-DASH-030 | Verify dashboard shows correct revenue totals | Database has known invoice records | GET /dashboard | Revenue, paid, outstanding amounts match database | — | ⬜ | — | ◌ |
| TC-PRM-DASH-031 | Verify dashboard shows overdue invoices list | Invoices exist with due date < now and status != paid | GET /dashboard | Overdue invoices appear in the list sorted by due date | — | ⬜ | — | ◌ |
| TC-PRM-DASH-032 | Verify dashboard shows recent activity logs | Activity log entries exist | GET /dashboard | Last 15 activity logs displayed with user and timestamp | — | ⬜ | — | ◌ |
| TC-PRM-DASH-033 | Verify dashboard shows 12-month revenue chart data | Invoice data for past 12 months | GET /dashboard | Monthly revenue chart shows invoiced vs collected per month | — | ⬜ | — | ◌ |
| TC-PRM-DASH-034 | Verify dashboard shows 12-month tenant registration trend | Tenant records with created_at dates | GET /dashboard | Registration trend chart shows new tenants per month | — | ⬜ | — | ◌ |
| TC-PRM-DASH-035 | Verify dashboard shows user notification bell with unread count | User has notifications | GET /dashboard | Notification bell shows unread count; recent 10 notifications listed | — | ⬜ | — | ◌ |

### 3.6 Test/Debug Route Security

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DASH-036 | Verify test routes return 404 in production environment | APP_ENV=production | GET /test-email, GET /send-test-email, GET /test-notification | All return 404 Not Found | — | ⬜ | — | ◌ |

---

## 4. Requirements Coverage

| REQ ID | Feature | TC Coverage |
|--------|---------|:-----------:|
| REQ-PRM-006 | Central Platform Authentication | TC-PRM-DASH-001 to TC-PRM-DASH-025, TC-PRM-DASH-036 |
| REQ-PRM-011 | Platform Dashboard and Analytics | TC-PRM-DASH-026 to TC-PRM-DASH-035 |
| REQ-PRM-012 | Activity Log and Monitoring | TC-PRM-DASH-032 (partial) |

---

## 5. Business Rules Coverage

| BR ID | Rule Summary | TC Coverage |
|-------|-------------|:-----------:|
| BR-PRM-018 | Test routes not accessible in production | TC-PRM-DASH-036 |
| BR-PRM-023 | Activity log for state-changing operations | TC-PRM-DASH-032 |

---

## 6. Data Setup Requirements

| TC Group | Data Needed |
|----------|-------------|
| Login | At least one active user with verified email; one inactive user; one unverified user; one 2FA-enabled user with mobile |
| OTP 2FA | Valid TwoFactorService mock; user with mobile_no and two_factor_auth_enabled = true |
| Dashboard | Minimum 5 tenant records (mixed active/inactive), 10+ invoice records (mixed statuses), 15+ activity log entries, user notifications, plan records |
| Production gate | Environment switch between production and non-production |

---

## 7. Test Environment

| Environment | Details |
|-------------|---------|
| **Application** | Prime AI (prime_ai) |
| **Base URL** | Central domain (e.g., http://primeai.test) |
| **Database** | prime_db (sys_users populated, prm_tenant seeded) |
| **Auth** | Sanctum session-based authentication |
| **Queue** | Sync driver recommended for tests |
| **Mail** | Log driver for email notification tests |

---

## 8. Dependencies

| Dependency | Purpose |
|-----------|---------|
| `LoginRequest` | Authentication validation |
| `TwoFactorService` | OTP generation and verification |
| `SendSmsJob` | SMS dispatch for login notification |
| `LoginNotification` | Email notification on login |
| `EnsureTwoFactorVerified` middleware | 2FA verification gate on dashboard |
| PrimeAuthController routes | Must be registered in module routes/web.php |

---

## 9. Risk & Edge Cases

| Risk | Mitigation |
|------|------------|
| TwoFactorService external dependency (SMS gateway) | Mock in tests; handle exception gracefully in controller |
| Auto-send OTP failure on 2FA initiation | Non-blocking — user can resend manually; test error handling path |
| Dashboard loads ~15 inline queries | Performance test; caching needed at scale |
| Session expiry during OTP flow | Test redirect to login with clear error message |
| Concurrent login attempts | Not explicitly handled; LoginRequest may provide throttle |

---

## 10. Traceability Matrix

| TC ID | REQ ID | BR ID | Priority | Test Type | Automation Possible |
|-------|--------|-------|:--------:|-----------|:------------------:|
| TC-PRM-DASH-001 | REQ-PRM-006 | — | P0 | UI | Yes |
| TC-PRM-DASH-002 | REQ-PRM-006 | — | P1 | UI | Yes |
| TC-PRM-DASH-003 | REQ-PRM-006 | — | P0 | Integration | Yes |
| TC-PRM-DASH-004 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-005 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-006 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-007 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-008 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-009 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-010 | REQ-PRM-006 | — | P1 | UI | Yes |
| TC-PRM-DASH-011 | REQ-PRM-006 | — | P1 | UI | Yes |
| TC-PRM-DASH-012 | REQ-PRM-006 | — | P1 | UI | Yes |
| TC-PRM-DASH-013 | REQ-PRM-006 | — | P0 | UI | Yes |
| TC-PRM-DASH-014 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-015 | REQ-PRM-006 | — | P1 | Functional | Yes |
| TC-PRM-DASH-016 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-017 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-018 | REQ-PRM-006 | — | P1 | UI | Yes |
| TC-PRM-DASH-019 | REQ-PRM-006 | — | P1 | UI | Yes |
| TC-PRM-DASH-020 | REQ-PRM-006 | — | P1 | UI | Yes |
| TC-PRM-DASH-021 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-022 | REQ-PRM-006 | — | P1 | Functional | Yes |
| TC-PRM-DASH-023 | REQ-PRM-006 | — | P1 | Functional | Yes |
| TC-PRM-DASH-024 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-025 | REQ-PRM-006 | — | P0 | Functional | Yes |
| TC-PRM-DASH-026 | REQ-PRM-011 | — | P0 | Functional | Yes |
| TC-PRM-DASH-027 | REQ-PRM-011 | — | P0 | Security | Yes |
| TC-PRM-DASH-028 | REQ-PRM-011 | — | P0 | Security | Yes |
| TC-PRM-DASH-029 | REQ-PRM-011 | — | P1 | Functional | Yes |
| TC-PRM-DASH-030 | REQ-PRM-011 | — | P1 | Functional | Yes |
| TC-PRM-DASH-031 | REQ-PRM-011 | — | P1 | Functional | Yes |
| TC-PRM-DASH-032 | REQ-PRM-012 | BR-PRM-023 | P1 | Functional | Yes |
| TC-PRM-DASH-033 | REQ-PRM-011 | — | P1 | Functional | Yes |
| TC-PRM-DASH-034 | REQ-PRM-011 | — | P1 | Functional | Yes |
| TC-PRM-DASH-035 | REQ-PRM-011 | — | P1 | Functional | Yes |
| TC-PRM-DASH-036 | REQ-PRM-006 | BR-PRM-018 | P1 | Security | Yes |
