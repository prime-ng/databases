# Mobile SRS — Batch 09 (Profile · Settings · Search)

> Index: `02_mobile_srs_index.md`. Features: F-130, F-131, F-132, F-133, F-134, F-135, F-140.

---

## F-130: My Profile / Student ID Card

### 1. Overview
View and (limited) edit own profile. Generate / view digital student ID card with QR (verification URL).

### 2. User Stories
- **US-130.1** *As a student, I see my profile photo, class, roll, and a digital ID card I can show at the gate.*
- **US-130.2** *As an employee, I update my phone / address / emergency contact.*
- **US-130.3** *Edge — Aadhaar / PAN must NEVER appear on mobile (PII minimisation).*

### 3. Functional Requirements
- **FR-130.1** Profile read returns Resource without `aadhaar`, `pan`, `password`, internal flags.
- **FR-130.2** Editable fields whitelisted server-side (D25): `phone`, `secondary_phone`, `address`, `emergency_contact`, `avatar_media_id`. Other fields read-only.
- **FR-130.3** ID card via signed PDF (BG-33).
- **FR-130.4** ID card QR encodes a public verification URL (signed; no PII in QR).

### 4. Screen Specifications

#### S-130.1 — Profile
```
┌──────────────────────────────────┐
│ [Avatar]  Asha Sharma             │
│ Class VII-B · Roll 12             │
│ ──────────────                    │
│ Phone:   +91-9XXX-XXX-90  [edit]  │
│ Address: ...                       │
│ Emergency: Mr R Sharma 9XXXX      │
│                                  │
│ [View ID card]   [Health (F-131)] │
└──────────────────────────────────┘
```

States: loading, error, offline (cached).

### 5. API Contracts

#### `GET /api/mobile/v1/me/profile`
#### `PUT /api/mobile/v1/me/profile`
- **Status:** MODIFY (D25 whitelist; BG-39).

### 6. Data Model
`cache_profile`.

### 7. Offline Behavior
Read cached; writes queued.

### 8. Push Notifications
None.

### 9. Permissions & Security
- Self only.
- D25 / D30: PUT enforces FormRequest; only whitelisted fields persist.
- Audit: `PROFILE_UPDATED` row in `sys_activity_logs`.
- PII: response payload never includes Aadhaar / PAN / password / `is_super_admin`.

### 10. Non-Functional Requirements
- Cached < 200 ms.
- Localization: `f130.field.*`, `f130.cta.{edit,save}`.

### 11. Acceptance Criteria
- **AC-130.1** Sending `aadhaar` in PUT body has no effect (silently dropped).
- **AC-130.2** Avatar upload completes with new URL within 5 s p50.
- **AC-130.3** ID card QR → public verification page returns name + class only (no PII).

### 12. Dependencies
- F-002. BG-33 ID card PDF, BG-39 mass-assignment fix.

### 13. Out of Scope
- Email change (verification flow) — v1.2.

---

## F-131: Health Records (Student, P1)

### 1. Overview
Read-only view of student's health record (allergies, blood group, medications, immunisation history). Wraps planned `std_medical_details` (16-tables list per `student-parent-portal.md`).

### 2. User Stories
- **US-131.1** *As a parent, I update my child's allergies (later release).*
- **US-131.2** *As a teacher (limited view), I see allergies for an emergency.*

### 3. Functional Requirements
- **FR-131.1** Endpoint returns student's medical details; teacher view limited to allergies + blood group only.
- **FR-131.2** Edits restricted to parent / admin (web at v1; mobile read-only).

### 4. Screen Specifications
Card list: Allergies, Blood group, Medications, Immunisations.

### 5. API Contracts

#### `GET /api/mobile/v1/me/health` (student or parent variant)
- **Status:** NEW. Module: StudentProfile (planned `std_medical_details`).

### 6. Data Model
`cache_health_records`.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
None.

### 9. Permissions & Security
- Student-self / parent-of-child / teacher-limited-view roles.
- Sensitive medical PII — strictly scoped; **audit on every read** (`HEALTH_VIEWED`).

### 10. Non-Functional Requirements
- Localization: `f131.section.*`.

### 11. Acceptance Criteria
- **AC-131.1** Teacher reading another class's student → 403.
- **AC-131.2** Audit log captures every parent / teacher access.

### 12. Dependencies
- F-130.

### 13. Out of Scope
- Lab report attachments — v1.1.
- Edit on mobile — v1.2.

---

## F-132: My Teachers Directory (Student, P1)

### 1. Overview
Read-only directory of subject teachers + class teacher with phone/email (masked unless school config allows).

### 2. User Stories
- **US-132.1** *As a student, I see my Math teacher's email to ask a doubt.*

### 3. Functional Requirements
- **FR-132.1** Phone masked to last 4 digits unless tenant config `teacher_directory_show_phone=true`.
- **FR-132.2** Email visible by default.
- **FR-132.3** Endpoint returns teachers for student's class-section + subject teachers.

### 4. Screen Specifications
List with avatar, name, subject, contact actions.

### 5. API Contracts

#### `GET /api/mobile/v1/me/teachers`
- **Status:** NEW. Module: StudentProfile / SchoolSetup.

### 6. Data Model
`cache_my_teachers`.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
None.

### 9. Permissions & Security
- Read-only; PII minimal.
- Audit: not logged.

### 10. Non-Functional Requirements
- Cached < 200 ms.
- Localization: `f132.title`, `f132.role.*`.

### 11. Acceptance Criteria
- **AC-132.1** Teacher's Aadhaar / address never returned.
- **AC-132.2** Tap email opens system mail; phone (when visible) opens dialler.

### 12. Dependencies
- F-002.

### 13. Out of Scope
- Direct call from app (without dialler) — v1.2.

---

## F-133: Settings & Language

### 1. Overview
Centralised settings: language toggle, biometric toggle, notification preferences (deep-link to F-081), about (F-135), logout, switch-school (re-runs F-001).

### 2. User Stories
- **US-133.1** *As a Hindi-speaking parent, I switch the app language to Hindi.*
- **US-133.2** *As a security-conscious user, I disable biometric.*

### 3. Functional Requirements
- **FR-133.1** Language choices come from supported list (en-IN, hi-IN at v1).
- **FR-133.2** Language change applies immediately without app restart (intl re-bind).
- **FR-133.3** Logout calls `DELETE /auth/logout` and wipes local state.

### 4. Screen Specifications
List of grouped rows: Account, Preferences, Help, About.

### 5. API Contracts

#### `GET / PUT /api/mobile/v1/me/preferences`
- **Status:** NEW. Module: App.

### 6. Data Model
`cache_preferences` (single row).

### 7. Offline Behavior
Read cached; writes queued (language change applies locally immediately).

### 8. Push Notifications
None.

### 9. Permissions & Security
- Self-scoped.
- Audit: `LANGUAGE_CHANGED`.

### 10. Non-Functional Requirements
- Save perceived < 200 ms.
- Localization: `f133.section.*`, `f133.lang.{en,hi}`.

### 11. Acceptance Criteria
- **AC-133.1** Language toggle persists across launches.
- **AC-133.2** Logout wipes Drift `cache_*` + secure storage; next launch lands in F-002 (skips F-001 — tenant remains pinned).

### 12. Dependencies
- F-001 (switch-school), F-004 (biometric), F-081 (notif prefs).

### 13. Out of Scope
- Theme (dark mode) — v1.1.

---

## F-134: Help & Support

### 1. Overview
Raise a support ticket; view ticket history; FAQ.

### 2. User Stories
- **US-134.1** *As a user with a payment issue, I raise a ticket from inside the app.*
- **US-134.2** *I track the ticket status.*

### 3. Functional Requirements
- **FR-134.1** Ticket: subject, description, category, optional attachments (≤ 3, ≤ 1 MB each).
- **FR-134.2** Status: OPEN | IN_PROGRESS | RESOLVED | CLOSED.
- **FR-134.3** FAQ static + per-tenant override.

### 4. Screen Specifications
Ticket list + new-ticket form + FAQ.

### 5. API Contracts

#### `POST / GET /api/mobile/v1/support/tickets`
- **Status:** NEW. Module: App / new SupportShell.

### 6. Data Model
`cache_my_tickets`.

### 7. Offline Behavior
Queued submission.

### 8. Push Notifications
- `SUPPORT_TICKET_UPDATED` (P2) — channel `general`.

### 9. Permissions & Security
- Self-scoped.
- Attachments: anti-malware scan in Phase 3 design.
- Audit: `SUPPORT_TICKET_OPENED`.

### 10. Non-Functional Requirements
- Submit perceived < 200 ms.
- Localization: `f134.cta.{new,view}`, `f134.status.*`.

### 11. Acceptance Criteria
- **AC-134.1** Tampered ticket_id (other user) → 403.

### 12. Dependencies
- F-002.

### 13. Out of Scope
- In-app live chat — v1.2.
- Voice ticket — v1.2.

---

## F-135: About / Version / Forced Update

### 1. Overview
Show version + build; check for forced upgrade. Block app if below `min_supported_version`.

### 2. User Stories
- **US-135.1** *As any user, when I open the app and a critical update is available, I'm guided to the store and cannot proceed without upgrading.*

### 3. Functional Requirements
- **FR-135.1** On every cold start, call `GET /version` with current `app_version`.
- **FR-135.2** Response: `{ latest_version, min_supported_version, force_upgrade, store_url:{ios,android}, release_notes }`.
- **FR-135.3** When `force_upgrade=true`, app shows blocking screen with "Update now" CTA → opens platform store.
- **FR-135.4** When current ≥ `latest_version`: silent.
- **FR-135.5** When between min and latest: optional banner.

### 4. Screen Specifications

#### S-135.1 — Force-upgrade modal
Logo + "A critical update is required" + Update CTA. Cancel disabled.

### 5. API Contracts

#### `GET /api/mobile/v1/version`
- **Status:** NEW (BG-35).
- **Auth:** none required.

### 6. Data Model
None (ephemeral).

### 7. Offline Behavior
Cannot check; cache last response with 24-hour TTL — if cached `force_upgrade` was true, keep enforcing.

### 8. Push Notifications
- `FORCE_UPGRADE_AVAILABLE` (data-only push).

### 9. Permissions & Security
- No auth required (so even logged-out users can be told to upgrade).

### 10. Non-Functional Requirements
- Check < 500 ms.
- Localization: `f135.title`, `f135.cta.update`, `f135.release_notes`.

### 11. Acceptance Criteria
- **AC-135.1** App on outdated build is blocked at startup until updated.
- **AC-135.2** Store CTA opens correct platform store (App Store / Play Store) per app build.

### 12. Dependencies
- BG-35.

### 13. Out of Scope
- In-app update download (Android In-App Updates API) — v1.1 enhancement.

---

## F-140: App-wide Search (P1)

### 1. Overview
Universal search across the user's accessible content: classmates, books, homework, notices, messages.

### 2. User Stories
- **US-140.1** *As a student, I search "math" and find homework, books, notices.*
- **US-140.2** *Results respect role-scoping (parent results limited to active child + general).*

### 3. Functional Requirements
- **FR-140.1** Backend: per-tenant Meilisearch index (BG-36) — XL.
- **FR-140.2** Multi-entity search; results categorised.
- **FR-140.3** Indexed entities: `lms_homework`, `slb_books`, `lms_quizzes`, `sch_notices`, `ntf_notifications` (limited to user-visible).
- **FR-140.4** Permission filter applied at query time (Meilisearch attribute filters).

### 4. Screen Specifications
Search bar → categorised result tabs.

### 5. API Contracts

#### `GET /api/mobile/v1/search?q=&type=`
- **Status:** NEW (BG-36).

### 6. Data Model
`cache_recent_searches` (terms only).

### 7. Offline Behavior
Recent local searches cached; live search blocks offline.

### 8. Push Notifications
None.

### 9. Permissions & Security
- Permission filter MUST be enforced server-side (cross-user / cross-tenant leakage is the #1 risk).
- Audit: not logged (high frequency).

### 10. Non-Functional Requirements
- Search latency < 800 ms p50.
- Localization: `f140.placeholder`, `f140.tab.*`.

### 11. Acceptance Criteria
- **AC-140.1** Searching for another tenant's known title returns 0 results.
- **AC-140.2** Parent searching while active child is Asha does not return Ravi's homework.

### 12. Dependencies
- F-002, F-005. BG-36 search infra.

### 13. Out of Scope
- Voice search — v1.2.
- Search-as-you-type with semantic ranking — v1.1.

---

> **End of Phase 2 SRS.** Master index, 9 batches, 53 features covered.
> **STOP** — awaiting `approved — proceed to Phase 3`.
