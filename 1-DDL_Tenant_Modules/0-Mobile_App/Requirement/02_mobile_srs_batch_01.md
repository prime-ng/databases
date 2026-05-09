# Mobile SRS — Batch 01 (Authentication & Onboarding)

> Index: `02_mobile_srs_index.md`. Features in this batch: F-001, F-002, F-003, F-004, F-005.

---

## F-001: Multi-Tenant App Setup & School Lookup

### 1. Overview
**Description.** First-launch flow that lets a user identify their school by (a) typing the subdomain, (b) entering a 6-character tenant code printed on the school onboarding sheet, or (c) scanning a school-issued QR code. Backend resolves tenant identity, returns branding (logo, colour, name) and supported modules; client pins this tenant for the install.

**Primary users.** All roles, first-time setup. **Secondary users.** Same user re-running "Switch School" from Settings.

**Business value.** Mobile cannot rely on the HTTP host header that the web app uses for tenant resolution (D6). This feature is the bridge that maps a single API hostname (`api.prime-ai.com` — TBD Q-13) to a tenant. Without it, every other feature is unreachable.

### 2. User Stories

- **US-001.1** *As a parent installing the app for the first time, I want to enter my child's school code, so that I can be sure I'm connecting to the right school's data.*
  - Edge — invalid code: clear error message, retry allowed, no lockout.
  - Edge — code maps to a deactivated tenant: explicit "school suspended" message, contact link.

- **US-001.2** *As a teacher with a busy day, I want to scan the QR code on the staff onboarding sheet, so that I don't have to type anything.*
  - Edge — camera permission denied: graceful fallback to manual code entry.
  - Edge — QR is for a different app (not Prime-AI): app rejects with "this QR is not for Prime-AI" message.

- **US-001.3** *As a tech-savvy admin, I want to enter the school subdomain directly, so that I can connect even if onboarding sheets aren't available.*
  - Edge — non-existent subdomain: "School not found" error.
  - Edge — subdomain typed without TLD: app appends the canonical suffix (`.prime-ai.com`).

### 3. Functional Requirements

- **FR-001.1** App SHALL present three input modes on first launch: Subdomain, 6-char Tenant Code, QR scan. Q-2 may de-scope to (b)+(c) only at v1.
- **FR-001.2** Tenant code MUST be alphanumeric uppercase, length 6, regex `^[A-Z0-9]{6}$`. Client-side validation before network call.
- **FR-001.3** On successful resolution, client MUST persist `{tenant_uuid, tenant_host, branding}` in `flutter_secure_storage`.
- **FR-001.4** Branding response includes: `tenant_name`, `school_name`, `primary_color` (hex), `logo_url`, `splash_url` (optional), `supported_modules[]`, `default_locale`. Loaded into theme provider.
- **FR-001.5** "Switch School" action SHALL clear the entire Drift cache + secure storage and re-run F-001.
- **FR-001.6** Resolution SHALL be rate-limited (`throttle:10,1` — 10 attempts per minute per IP) on the backend.
- **FR-001.7** Resolution SHALL return 403 with `error_code = TENANT_INACTIVE` if `prm_tenant.is_active = 0`; client SHALL show a tenant-suspended dialog.
- **FR-001.8** Tenant code → host mapping MUST be sourced from `prm_tenant_domains` (or `prm_tenant.tenant_code` — confirm Phase 3) so admins can issue codes without DNS work.

### 4. Screen Specifications

#### S-001.1 — Welcome / Splash
```
┌──────────────────────────────────┐
│           [Prime-AI Logo]         │
│                                  │
│       Welcome to Prime-AI         │
│   Your school in your pocket      │
│                                  │
│        ┌──────────────┐          │
│        │  Get Started │          │
│        └──────────────┘          │
└──────────────────────────────────┘
```
- Components: logo (SVG), tagline, primary button.
- States: only one (loaded). No empty/error/offline distinction.

#### S-001.2 — Tenant Lookup
```
┌──────────────────────────────────┐
│  ←   Find your school             │
│                                  │
│  [ Tab: Code ] [ Subdomain ] [ QR ]│
│                                  │
│  Enter your 6-letter school code  │
│  ┌────────────────────────────┐  │
│  │       _ _ _ _ _ _          │  │  (boxed input, single-cell-per-char)
│  └────────────────────────────┘  │
│                                  │
│  Don't have a code? [Help link]   │
│                                  │
│         ┌──────────────┐          │
│         │   Continue    │          │
│         └──────────────┘          │
└──────────────────────────────────┘
```
- Tab "QR": opens `mobile_scanner` view; auto-validates on detect.
- Tab "Subdomain": single text field with helper "your school subdomain (e.g. xyz)" — appends `.prime-ai.com` server-side.
- States:
  - **loading** — button shows spinner; input disabled.
  - **error** — inline below input: "School not found", "Connection failed (offline)", "School suspended — please contact admin".
  - **empty** — N/A (always primed).
  - **offline** — banner: "You're offline — connect to look up your school."

#### S-001.3 — Branding Confirm
```
┌──────────────────────────────────┐
│  [School Logo]                    │
│                                  │
│  Greenwood International Academy  │
│  greenwood.prime-ai.com           │
│                                  │
│  Modules available:               │
│  ✓ Academics  ✓ Fees  ✓ Transport │
│                                  │
│  [Wrong school?]   [Continue →]   │
└──────────────────────────────────┘
```
- Tap "Wrong school?" → back to S-001.2.
- "Continue →" → S-002 (Login).

**Validation rules (client):** code regex; subdomain strip whitespace, lowercase, alphanumeric + hyphen, length 3–40.

**Empty / error / offline copy** — i18n keys `f001.error.notfound`, `f001.error.suspended`, `f001.error.offline`, `f001.error.network`.

### 5. API Contracts

#### `POST /api/mobile/v1/tenant/resolve`
- **Auth:** none.
- **Status:** NEW (BG-02). Owning module `Modules/Prime/Http/Controllers/Api/Mobile/TenantController@resolve`.
- **Request:**
  ```json
  { "input_type": "code | subdomain | qr_token",
    "value": "ABC123 | greenwood | <qr-jwt>" }
  ```
- **Response 200:**
  ```json
  {
    "success": true,
    "data": {
      "tenant_uuid": "uuid-v4",
      "tenant_host": "greenwood.prime-ai.com",
      "tenant_name": "Greenwood International Academy",
      "default_locale": "en-IN",
      "supported_modules": ["StudentPortal","StudentFee","Transport", "..."],
      "branding": {
        "primary_color": "#0F4C81",
        "logo_url": "https://cdn.../tenant/uuid/logo.png",
        "splash_url": null
      }
    }
  }
  ```
- **Response 4xx:**
  - `404 TENANT_NOT_FOUND` — invalid code/subdomain
  - `403 TENANT_INACTIVE`
  - `429 TOO_MANY_ATTEMPTS`
  - `400 INVALID_INPUT`
- **Rate limit:** `throttle:10,1`.
- **Caching:** client caches in secure storage indefinitely until "Switch School".
- **Backend module:** `Modules/Prime/`. Tables read: `prm_tenant`, `prm_tenant_domains`, `prm_plans`, `prm_tenant_plan_module_jnt`, tenant settings.
- **Backend gap:** BG-02 (controller); BG-04 (fix `env('APP_DOMAIN')` → `config('app.domain')` — SEC-PLATFORM-002).

#### `GET /api/mobile/v1/tenant/{code}/branding`
- **Auth:** none.
- **Status:** NEW (BG-02).
- **Response 200:** subset of resolve response — `{tenant_name, branding{}}`.
- **Use case:** tenant branding refresh without re-running full resolve.

### 6. Data Model (client-side)

```sql
-- Drift table
device_state (
  k                TEXT PRIMARY KEY,   -- 'tenant_uuid', 'tenant_host', 'branding_json'
  v                TEXT NOT NULL,
  updated_at       INTEGER NOT NULL
)
```
- Branding cached as JSON blob; theme provider parses on app start.
- Mapped to backend: `tenant_uuid` ↔ `prm_tenant.uuid`, `tenant_host` ↔ `prm_tenant_domains.domain`.

### 7. Offline Behavior

- F-001 itself REQUIRES network (cannot resolve a tenant offline).
- Once resolved, the cached branding survives offline use; subsequent app opens skip directly to F-002.
- Re-resolution (Switch School) requires network; offline → blocking dialog.

### 8. Push Notifications
N/A — F-001 happens before any token registration.

### 9. Permissions & Security

- **OS:** Camera (just-in-time, when user taps QR tab).
- **Sensitive data:** none (tenant code is not a secret).
- **Audit log:** N/A on mobile; backend writes `sys_activity_logs` row for resolves with `event = TENANT_RESOLVED` for analytics — TBD Phase 3.
- **Rules referenced:** `tenancy-rules.md` (database-per-tenant, D1); `security-rules.md` (rate-limit auth-class endpoints).
- **Pre-condition fix:** SEC-PLATFORM-002 must be cleared (BG-04) — the resolution lives below the auth middleware so the route file is evaluated; with `env('APP_DOMAIN')` and `config:cache` enabled, routes break in production.

### 10. Non-Functional Requirements

- **Performance:** resolution call < 800 ms p50, < 2 s p95 over 4G.
- **Accessibility:** input field reads "Six character school code" via TalkBack; QR scanner viewfinder has accessibility region announcement.
- **Localization keys:** `f001.title`, `f001.cta`, `f001.tab.{code,subdomain,qr}`, plus error keys above.
- **Analytics:** events `tenant_resolve_attempt`, `tenant_resolve_success`, `tenant_resolve_error{code}`.

### 11. Acceptance Criteria

- **AC-001.1** *Given* a valid code "ABC123" mapping to an active tenant, *when* the user submits, *then* response 200 returns branding and S-001.3 displays the school name and logo.
- **AC-001.2** *Given* a valid code mapping to an inactive tenant, *when* the user submits, *then* dialog "School suspended" shows with backend admin contact and the user CANNOT proceed.
- **AC-001.3** *Given* the device is offline, *when* the user submits, *then* offline banner appears within 3 s and resolution is not attempted.
- **AC-001.4** *Given* the QR camera permission is denied, *when* the user opens the QR tab, *then* a pre-prompt explains why and offers a "Use code instead" button.
- **AC-001.5** *Given* SEC-PLATFORM-002 is unfixed, *when* `php artisan config:cache` is run on backend, *then* this is detected by infra integration tests — F-001 cannot ship until BG-04 is closed.

### 12. Dependencies

- **Other features:** F-002 (downstream), F-004 (downstream).
- **Backend modules:** Prime (FULL ~65%) + middleware change.
- **Backend gaps:** BG-01 `InitializeTenancyByHeader`; BG-02 controller; BG-04 SEC-PLATFORM-002 fix.
- **Third-party:** `mobile_scanner`, `flutter_secure_storage`, `dio`.

### 13. Out of Scope

- SSO via Google / Apple sign-in (potential v1.2).
- Per-tenant deep-link install (Android App Links / iOS Universal Links) — Phase 3 OQ.
- Branding theming beyond logo + primary colour (typography, dark mode per tenant — v1.1+).

---

## F-002: Login (Email / Phone + Password)

### 1. Overview
Standard authenticated login. Returns Sanctum token + user profile + (for Parent role) the list of accessible children. Stores token in OS secure storage. Optionally registers FCM/APNs token with the backend for push.

**Primary users.** All roles. **Secondary.** N/A.

### 2. User Stories

- **US-002.1** *As any user, I want to log in with my email or phone + password, so that I can access my school account.*
  - Edge — wrong password 5+ times: backend lockout (`throttle:5,2`); client shows "Try again in 2 minutes".
  - Edge — account `is_active=0`: "Account inactive — contact your school admin".
- **US-002.2** *As a parent with two children, I want my login response to include both children, so that the child switcher (F-005) is ready immediately on the home screen.*
- **US-002.3** *As a returning user, I want the login screen pre-filled with my last-used identifier, so that I can sign in faster.*
  - The password field is NEVER pre-filled.

### 3. Functional Requirements

- **FR-002.1** Login accepts either email or phone (E.164 or 10-digit Indian format) — backend normalises.
- **FR-002.2** Returned `User` object MUST be a Sanctum-aware **API Resource** that omits `is_super_admin`, `password`, `two_factor_*`, `remember_token`, internal flags. (SEC-PLATFORM-004 fix is a hard pre-req — BG-05.)
- **FR-002.3** Login MUST call `POST /devices` to register FCM token before navigating to Home, with a 3-second timeout — failure logs error but does not block login.
- **FR-002.4** Token MUST be stored only in `flutter_secure_storage`. Never in SharedPreferences, Drift, or memory beyond app lifetime.
- **FR-002.5** "Remember device" toggle (default ON) → eligible for biometric (F-004) in subsequent sessions.
- **FR-002.6** Backend MUST issue a token row in `personal_access_tokens` with `name = "{platform}:{device_id}"` — used for remote revocation (security console).
- **FR-002.7** Login response MUST include `user.role` from Spatie roles + `user.user_type` (one of Student / Parent / Teacher / Staff / Principal / Accountant / Librarian / Admin) for client-side routing.
- **FR-002.8** Rate-limit `throttle:5,2` (5 attempts per 2 minutes per identifier).

### 4. Screen Specifications

#### S-002.1 — Login
```
┌──────────────────────────────────┐
│  [School Logo]  Greenwood Academy │
│                                  │
│  Sign in                          │
│                                  │
│  Email or phone                   │
│  ┌────────────────────────────┐  │
│  │ student@greenwood.edu       │  │
│  └────────────────────────────┘  │
│  Password                         │
│  ┌────────────────────────────┐  │
│  │ ••••••••••              [👁] │  │
│  └────────────────────────────┘  │
│                                  │
│  ☑ Remember this device           │
│                                  │
│         ┌──────────────┐          │
│         │   Sign in     │          │
│         └──────────────┘          │
│  Forgot password?                 │
│  ↑ Switch school                  │
└──────────────────────────────────┘
```
- Eye icon toggles password visibility (client-side only; never logged).
- "Switch school" → confirm dialog → re-runs F-001.
- States: loading (button spinner, fields disabled), error (inline error: "Invalid credentials", "Account inactive", "Too many attempts — try in 2 min"), offline.

### 5. API Contracts

#### `POST /api/mobile/v1/auth/login`
- **Auth:** none.
- **Status:** NEW wrapper (BG-03). Module: Prime / App.
- **Request:**
  ```json
  { "identifier": "student@greenwood.edu",
    "password":   "redacted",
    "device":     { "device_id":"...", "platform":"android|ios",
                    "app_version":"1.0.0+1", "model":"...", "os_version":"..." }
  }
  ```
- **Response 200:**
  ```json
  {
    "success": true,
    "data": {
      "token": "<sanctum_token>",
      "user": {
        "uuid":"...","name":"...","email":"...","phone":"...",
        "user_type":"PARENT","roles":["parent"],
        "avatar_url":"...","default_locale":"en-IN"
      },
      "children": [   // present only when user_type = PARENT
        { "uuid":"s1","name":"Asha","class":"VII-B","is_fee_payer":true },
        { "uuid":"s2","name":"Ravi","class":"III-A","is_fee_payer":false }
      ]
    }
  }
  ```
- **Response 4xx:**
  - `401 INVALID_CREDENTIALS`
  - `403 ACCOUNT_INACTIVE`
  - `429 TOO_MANY_ATTEMPTS`
- **Rate limit:** `throttle:5,2`.
- **Caching:** none (token kept in secure storage).
- **Backend gap:** BG-03; BG-05 (SEC-PLATFORM-004 — `is_super_admin` field exclusion); BG-39 (D25 `validated()`); BG-40 (D30 authorize Gate).

#### `DELETE /api/mobile/v1/auth/logout`
- Revokes the calling token. Client wipes Drift cache + secure storage.

#### `GET /api/mobile/v1/auth/me`
- Silent ping — returns the Resource-shaped user; used by §3.2 cold-start flow.

#### `POST /api/mobile/v1/devices`
- **Status:** NEW (BG-10). Module: Notification.
- **Request:** `{ device_id, platform, fcm_token, app_version, locale }`.
- **Response 201:** `{ id }`.

### 6. Data Model (client-side)

```sql
device_state (k='token', v=<token>, updated_at)
device_state (k='user_json', v=<resource>, updated_at)
device_state (k='children_json', v=<array>, updated_at)  -- parents only
```

Mapping: `user_json.uuid` ↔ `sys_users.uuid`; `children_json[].uuid` ↔ `std_students.uuid`.

### 7. Offline Behavior
F-002 requires network. If offline at login attempt, show blocking offline dialog. After successful login, the cached `user_json` and `children_json` survive offline use.

### 8. Push Notifications
**Triggered:** `AUTH_NEW_DEVICE_LOGIN` to self when `device_id` is unseen for this user (P1 push from Phase 1 — surfaces on Settings → Devices). Channel `security`. Quiet hours not respected (security event).

### 9. Permissions & Security

- **Token storage:** `flutter_secure_storage` only.
- **Sensitive data:** never log the request body, password, or response body to Sentry/Crashlytics; configure both SDKs to redact `password`, `token`.
- **Audit log:** backend writes `sys_activity_logs.event = USER_LOGIN_SUCCESS / USER_LOGIN_FAILED`.
- **SEC blockers:** **SEC-PLATFORM-004** must be fixed (BG-05) — without removing `is_super_admin` from `$fillable`, a malicious mobile or web client could elevate by sending it during profile edits.
- **Bug pre-req:** **BUG-008** (duplicate `user_type` and `two_factor_auth_enabled` in `$fillable`).
- **Rule reference:** `security-rules.md`, §"Auth & Sessions".

### 10. Non-Functional Requirements

- Performance: < 2.5 s p50 over 4G.
- Accessibility: password field announces "Password, hidden" / "Password, shown" on toggle.
- Localization: `f002.identifier`, `f002.password`, `f002.cta.signin`, plus errors.
- Analytics: `login_attempt`, `login_success`, `login_failed{reason}`, `device_register_failed`.

### 11. Acceptance Criteria

- **AC-002.1** Given valid credentials, when user submits, response includes a Sanctum token and the user is routed to their role-specific home (F-010/F-011/F-012/F-013) within < 2.5 s.
- **AC-002.2** Given a parent account with 2 children, when login succeeds, response `data.children` is a 2-element array and child switcher (F-005) shows them.
- **AC-002.3** Given 5 failed attempts within 2 minutes, the 6th attempt returns 429 and the UI shows the cooldown.
- **AC-002.4** Given a wire capture of the response, `is_super_admin` MUST NOT appear (Resource-enforced).
- **AC-002.5** Given Sentry crash report from this screen, the request body is redacted.

### 12. Dependencies
- F-001 (must be completed); F-004 (downstream toggle); F-005 (downstream for parents).
- BG-03 controller; BG-05 fillable fix; BG-10 device register; BG-39 / BG-40 mass-assignment defense.

### 13. Out of Scope
- 2FA TOTP (Q-OQ — `two_factor_auth_enabled` exists but no portal flow); v1.2.
- Social login; v1.2+.
- Magic-link login; not planned.

---

## F-003: Forgot Password / OTP Reset

### 1. Overview
Email or phone-based password reset. v1 = email-only; phone-OTP awaits the planned `Communication` module.

### 2. User Stories

- **US-003.1** *As a user who forgot my password, I want to receive a reset link by email, so that I can set a new password without contacting the school.*
- **US-003.2** *As a user who entered the wrong email, I want to be told the reset was sent (without revealing whether the email exists), so that user enumeration is prevented.*

### 3. Functional Requirements

- **FR-003.1** Forgot endpoint MUST always return 200 with a generic "If the email exists, a reset link has been sent" — no enumeration.
- **FR-003.2** Reset token validity 30 minutes; single-use.
- **FR-003.3** Password policy enforced by backend: min 8 chars, ≥ 1 number, ≥ 1 letter, ≠ last 3 passwords. Echoed in client validation.
- **FR-003.4** On success, user is auto-redirected to F-002 with email pre-filled.
- **FR-003.5** Rate-limit `throttle:5,2`.

### 4. Screen Specifications

#### S-003.1 — Enter identifier
- Single text field; "Send reset link" CTA; "Back to sign in" link.

#### S-003.2 — Generic confirmation
"If `<masked-email>` matches an account, you'll receive a reset link within 5 minutes."

#### S-003.3 — Reset form (deep-linked from email)
- New password + confirm; client validates policy; submit → success → redirect to F-002.

States: loading, error (`token_expired`, `token_used`, `weak_password`), offline.

### 5. API Contracts

#### `POST /api/mobile/v1/auth/forgot`
- **Auth:** none. **Status:** NEW (BG-03).
- **Request:** `{ "identifier": "..." }`.
- **Response 200:** `{ success: true, message: "If the account exists ..." }` — always.
- **Rate limit:** `throttle:5,2`.

#### `POST /api/mobile/v1/auth/reset`
- **Auth:** none. **Status:** NEW (BG-03).
- **Request:** `{ "token":"...", "new_password":"..." }`.
- **Response 200:** `{ success:true }`.
- **4xx:** `400 INVALID_OR_EXPIRED_TOKEN`, `400 WEAK_PASSWORD`.

### 6. Data Model
N/A on client.

### 7. Offline Behavior
Network required for both endpoints.

### 8. Push Notifications
P1 push `AUTH_PASSWORD_CHANGED` on success — channel `security`, quiet hours not respected.

### 9. Permissions & Security
- No enumeration (FR-003.1).
- Rate-limit (FR-003.5).
- Backend audit `USER_PASSWORD_RESET_REQUESTED` and `_COMPLETED` rows in `sys_activity_logs`.
- `security-rules.md` §"Password recovery".

### 10. Non-Functional Requirements
- Email delivery target < 60 s p95 (backend SLA, not mobile).
- Reset link Universal Link / Android App Link → opens app directly to S-003.3 (Phase 3 deep-link).
- Localization: `f003.cta`, `f003.confirm`, `f003.policy.{minlength,number,letter,reuse}`.

### 11. Acceptance Criteria
- **AC-003.1** Given an unknown identifier, response is identical (200 generic) to a known one.
- **AC-003.2** Given a token > 30 min old, reset returns 400 INVALID_OR_EXPIRED_TOKEN.
- **AC-003.3** Given a successful reset, F-002 is reached with email pre-filled and old password no longer accepted.

### 12. Dependencies
- BG-03 endpoints.
- v1.1 SMS OTP gated on **Communication** module (BG-29) and **MSG91/Twilio DLT-templated SMS** (Q-7).

### 13. Out of Scope
- Phone OTP at v1 (Q-7).
- Account recovery via security questions; never planned.

---

## F-004: Biometric Unlock

### 1. Overview
After first password login, user can opt in to unlock the app on subsequent launches with Face ID / Touch ID / Android biometric. Biometric unlocks the locally stored Sanctum token; failure falls back to password.

### 2. User Stories
- **US-004.1** *As a frequent user, I want to unlock with Face ID, so that I can check my child's attendance without typing.*
- **US-004.2** *As a security-conscious user, I want to disable biometric anytime, so that a stolen unlocked phone can't access the app.*

### 3. Functional Requirements
- **FR-004.1** Biometric setup MUST be opt-in; NEVER forced.
- **FR-004.2** Token MUST remain in secure storage; biometric unlocks the *device keychain entry*, not derive a key.
- **FR-004.3** 3 failed biometric attempts → fall back to password (F-002 modal).
- **FR-004.4** Auto-lock after 5 minutes idle (configurable per tenant — Phase 3 release plan).
- **FR-004.5** Disabling biometric in Settings (F-133) immediately wipes the keychain biometric flag; next launch requires password.

### 4. Screen Specifications

#### S-004.1 — First-login opt-in modal
"Enable Face ID for faster sign-in?" — `[Not now]` / `[Enable]`.

#### S-004.2 — Cold-start biometric prompt
Native iOS / Android biometric overlay. Cancel → fallback password sheet.

States: success, failed-fallback, hardware-unavailable (modal: "Biometric not available — use password").

### 5. API Contracts
**N/A** — F-004 is fully client-side.

### 6. Data Model
```sql
device_state (k='biometric_enabled', v='true', updated_at)
```
Plus `flutter_secure_storage` accessibility flag set to `iOS_BIOMETRY_CURRENT_SET` (token wiped if enrolled biometrics change — defends against stolen-phone-with-added-biometric attack).

### 7. Offline Behavior
**Full** — works offline if token still valid. Idle-timeout still applies offline.

### 8. Push Notifications
N/A.

### 9. Permissions & Security
- **OS:** Biometric (`local_auth`).
- **Sensitive data:** token in Keychain Access Group / Android Keystore. Never AES-encrypted-prefs.
- **Threat model:** stolen unlocked phone — mitigated by 5-min idle re-auth (FR-004.4); stolen phone with added biometric — mitigated by `BIOMETRY_CURRENT_SET` flag (token wipes on enrollment change).
- **Audit log:** N/A on client; backend has no signal of biometric use.
- **`security-rules.md`** §"Mobile biometric handling" (to be drafted in Phase 3).

### 10. Non-Functional Requirements
- Performance: biometric prompt < 500 ms.
- Accessibility: VoiceOver/TalkBack reads "Use Face ID to sign in to Greenwood Academy".
- Localization: `f004.prompt.title`, `f004.prompt.reason`, `f004.fallback.cta`.
- Analytics: `biometric_enabled`, `biometric_unlock_success/failed`, `biometric_disabled`.

### 11. Acceptance Criteria
- **AC-004.1** Given biometric not enrolled on the device, the opt-in toggle in S-004.1 is disabled with a "Set up biometric in your phone settings" caption.
- **AC-004.2** Given the user enrolls a new biometric in the OS, the next app launch wipes the saved biometric flag and prompts password (FR-004.5 / `BIOMETRY_CURRENT_SET`).
- **AC-004.3** Given 5 minutes of foreground idle, the app re-prompts biometric.

### 12. Dependencies
- F-002 (must succeed once before opt-in).

### 13. Out of Scope
- PIN fallback (v1 uses password); v1.2.
- Per-feature biometric step-up (e.g. biometric only for Pay Fee F-061); deferred — currently relies on session lock alone.

---

## F-005: Multi-Child Switcher (Parent)

### 1. Overview
Parents with two or more children see a header pill showing the active child; tapping shows a child list. Selection updates the global "active child" context for every screen. Backend MUST validate guardian-child binding on every request (see §9).

### 2. User Stories
- **US-005.1** *As a parent of two children, I want a sticky pill in the header showing whose data I'm seeing, so that I never confuse my children's records.*
- **US-005.2** *As a parent with a single child, I should NOT see the child switcher (cleaner UI).*
- **US-005.3** *As a security-conscious parent, I want my child list to come from the server every login — never from a stale cache — so that newly added (or removed) guardian rights take effect immediately.*

### 3. Functional Requirements
- **FR-005.1** Child list = `std_student_guardian_jnt` rows for the parent where `can_access_parent_portal = 1`. Order by `is_primary_guardian` desc, then student name.
- **FR-005.2** First-login auto-selects the first accessible child (per `student-parent-portal.md` D3).
- **FR-005.3** Active child propagated via header `X-Active-Student-Id: <uuid>` on every parent-scoped request.
- **FR-005.4** Backend MUST validate `(authenticated_parent_uuid, X-Active-Student-Id)` against `std_student_guardian_jnt` on EVERY parent endpoint — IDOR is the #1 risk per portal doc (BR-PPT-012, SR-AUTH-001).
- **FR-005.5** If a child is removed mid-session (`can_access_parent_portal=0`), next request returns `403 CHILD_ACCESS_REVOKED`; client refreshes child list and selects another.
- **FR-005.6** UI hides switcher when child list length ≤ 1.

### 4. Screen Specifications

#### Header pill (every screen, parent role)
```
┌──────────────────────────────────┐
│  [≡]   [👶 Asha (VII-B) ▾]   [🔔] │
└──────────────────────────────────┘
```

#### S-005.1 — Child Switcher modal
```
┌──────────────────────────────────┐
│  Switch child                  [×]│
│ ─────────────────────────────────│
│  ◉ Asha       Class VII-B         │
│  ○ Ravi       Class III-A   [💰]   │  (💰 = is_fee_payer)
└──────────────────────────────────┘
```
- Tap a row → modal closes → entire app context updates → all visible screens auto-refresh from cache then network.

States: loading (during context switch), error (`child_access_revoked`).

### 5. API Contracts

#### `GET /api/mobile/v1/me/children`
- **Auth:** Bearer + tenant header.
- **Status:** NEW (BG-28 — module ParentPortal is PLANNED; v1 fallback path: `Modules/StudentProfile` exposes guardian read).
- **Response 200:**
  ```json
  { "data": [
    { "uuid":"s1","name":"Asha","class":"VII-B","section":"B",
      "academic_session":"2026-27","is_primary_guardian":true,
      "is_fee_payer":true,"avatar_url":"..." },
    { "uuid":"s2","name":"Ravi","class":"III-A","section":"A",
      "is_primary_guardian":false,"is_fee_payer":false,"avatar_url":"..." }
  ]}
  ```
- **4xx:** `403 NOT_A_PARENT` if user_type ≠ PARENT.

#### Cross-cutting header propagation
- Every parent-scoped GET / POST: `X-Active-Student-Id: <uuid>`.
- Backend rejects with `400 MISSING_ACTIVE_STUDENT` when omitted on a parent route.
- Backend rejects with `403 CHILD_ACCESS_REVOKED` when binding broken.

### 6. Data Model (client-side)

```sql
cache_children (
  student_uuid     TEXT PRIMARY KEY,
  name             TEXT,
  class_name       TEXT,
  section          TEXT,
  is_primary_guardian INTEGER,
  is_fee_payer     INTEGER,
  avatar_url       TEXT,
  cached_at        INTEGER
)
device_state (k='active_student_uuid', v=..., updated_at)
```
Mapping: `cache_children` ↔ `std_students` joined with `std_student_guardian_jnt`.

### 7. Offline Behavior
- Read-only — list is cached at login; switching uses local state.
- Refresh on every login + manual pull-to-refresh on switcher modal.

### 8. Push Notifications
- N/A directly. But every push that targets a parent must include `subject_id = student_uuid` so the client can route to the correct child context.

### 9. Permissions & Security
- **CRITICAL** — single most exposed feature. Every parent endpoint MUST enforce `ParentChildPolicy` (BR-PPT-012) before reading any child data.
- Backend tests: integration tests for every parent endpoint with `(parent_A, child_of_parent_B)` MUST return 403.
- `security-rules.md` §"Multi-tenant + role isolation"; `student-parent-portal.md` §"D3 Multi-Child Context".
- Audit log: every header-rejected 403 logged at WARN with `parent_uuid`, `attempted_student_uuid`, `endpoint`.

### 10. Non-Functional Requirements
- Performance: switcher open < 100 ms (cached); switch-and-refetch dashboard < 1.8 s p50 over 4G.
- Localization: `f005.title`, `f005.label.fee_payer`, `f005.label.primary_guardian`.
- Analytics: `child_switch{from,to}`, `child_switcher_opened`.

### 11. Acceptance Criteria
- **AC-005.1** Given a parent with 2 children, when login succeeds, the header pill appears with the auto-selected child's name and class.
- **AC-005.2** Given a parent with 1 child, the header pill is suppressed (no `▾` chevron).
- **AC-005.3** Given a request with a tampered `X-Active-Student-Id` of another parent's child, response is 403 CHILD_ACCESS_REVOKED and the client refreshes the child list.
- **AC-005.4** Given mid-session revocation, the next API call returns 403 and the UI auto-selects the next available child (or routes to "No children available" if none).

### 12. Dependencies
- F-002 (login result populates the cache).
- BG-28 ParentPortal module (XL — blocks ALL parent features).
- BG-39 / BG-40 mass-assignment defense.

### 13. Out of Scope
- Multi-child consolidated dashboard (all children at a glance) — Q-OQ on F-011; deferred to v1.1.
- Family-account features (chat across all parents/guardians of one child) — v1.2+.

---

> End of Batch 01. Continue to `02_mobile_srs_batch_02.md` (Dashboards).
