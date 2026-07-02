# ParentPortal (PPT) — Complete Technical Audit, Mode X
**Date:** 2026-06-29 | **Auditor:** pa-technical-auditor | **Module:** PPT ParentPortal | **Audit Mode:** A + B + C + G + Scoped D

---

## 1. Executive Summary

| Field | Value |
|---|---|
| Module | ParentPortal (PPT) |
| Prefix | `ppt_` |
| DB Layer | tenant_db |
| Completion | ~45% scaffolded |
| P0 Issues | **2** |
| P1 Issues | **7** |
| P2 Issues | **6** |
| Health Score | **40 / 100** (P0-capped) |
| Verdict | **NO-GO** |

**Summary:** The ParentPortal module has a clean tenancy middleware stack (Pattern B) and 22 well-structured FormRequests that provide real authorization via `ParentContextService.resolveChild()` — a meaningful improvement over the June 2026 baseline which incorrectly reported zero FormRequests. Three prior P0s (SEC-PPT-001, SEC-PPT-004, and the stale SEC-PPT-002/VAL-PPT-001 findings) are resolved or were inaccurate. However, two P0 blockers remain: (1) PTM `book()` has no class-section scope guard, enabling cross-class slot booking IDOR, and (2) the OTP login feature (REQ-PPT-002) — the portal's primary authentication mechanism for parents — has no AuthController, no routes, and no infrastructure. Seven P1 issues include RSVP cross-class IDOR, a dead ConsentFormPolicy, 8 D29 enum migrations, 4 abort(501) API stubs, and a hardcoded `session('tenant_id') ?? 1` tenancy fallback in PTM. Zero automated tests exist for a module with real payment flows, IDOR risks, and legally immutable consent signatures.

---

## 2. P0 Issues Register

| Code | Severity | Title | File:Line |
|---|---|---|---|
| SEC-PPT-003 | **P0** | PTM `book()` has no class-section scope guard — cross-class slot booking IDOR | `Modules/ParentPortal/app/Http/Controllers/ParentPtmController.php:~150` |
| REQ-PPT-002-ABSENT | **P0** | OTP login AuthController entirely absent — portal's primary authentication mechanism not scaffolded | `Modules/ParentPortal/` (no Auth controller exists) |

### SEC-PPT-003 Detail

`ParentPtmController::show()` filters available PTM slots by `class_section_id` before presenting them in the UI. However, the `book()` action accepts a `PtmSlot $slot` via Laravel route model binding with no subsequent scope verification. An authenticated parent can POST directly to `parent-portal.ptm.event.book` with any `slot_id` from any class-section, bypassing the UI filter. The controller checks only:
- `$child->id` against existing bookings (line ~150)
- Time overlap for `$child->id` (line ~162)
- DB lockForUpdate for the slot row

It does NOT verify: `$slot->assignment->eventClassSection->class_section_id === $child->currentSession->class_section_id`.

**Impact:** A parent can book a PTM appointment in a teacher's class-section that is not their child's, corrupting the teacher's booking schedule and revealing cross-class scheduling data.

**Fix:** After `$child = $this->context->resolveChild($request)`, add:
```php
$childClassSectionId = $child->currentSession?->class_section_id;
abort_unless(
    $slot->assignment->eventClassSection->class_section_id === $childClassSectionId,
    403,
    'This slot is not available for your child\'s class.'
);
```

### REQ-PPT-002-ABSENT Detail

REQ-PPT-002 (OTP Login) is classified P0 in the FRD. The module has a `ParentPortalMiddleware` that enforces `user_type=PARENT`, but there is no OTP AuthController, no OTP routes registered in any of the three route files, and no SMS gateway configuration in the module. The RouteServiceProvider includes the `verified` middleware (`EnsureEmailIsVerified`), which will block all parents who authenticate without email verification — a common scenario for OTP-only users. Without OTP auth, schools using the portal must fall back to standard password auth, which is not part of the parent experience design.

---

## 3. Layer A — Module Structure and Scaffolding

### A1. Component Inventory

| Component | Expected | Actual | Status |
|---|---|---|---|
| Controllers | 28 | 28 (21 web + 5 Api/ + 2 Mobile/) | PASS |
| Models | 6 | 6 | PASS |
| FormRequests | 22+ | 22 | PASS |
| Policies | 2+ | 1 (ConsentFormPolicy only) | FAIL — ParentChildPolicy absent |
| Services | 5 | 1 (ParentContextService only) | FAIL — 4 planned services absent |
| Middleware | 1 | 1 (ParentPortalMiddleware) | PASS |
| Seeders | 6 | 6 | PASS |
| Tests | 33 planned | 0 | FAIL — zero test coverage |
| Jobs | 0 | 0 | PASS (no async ops designed) |

### A2. ServiceProvider

`ParentPortalServiceProvider` does NOT call `registerPolicies()` or `Gate::policy()`. The existing `ConsentFormPolicy` is never registered with Laravel's Gate. This means:
- Admin-facing consent form operations have no policy-layer enforcement
- `$this->authorize('view', $consentForm)` would silently fall through to `Gate::before()` (super-admin only) or return false for normal users

### A3. Route Structure

`RouteServiceProvider` establishes Pattern B middleware:
```
web → InitializeTenancyByDomain → PreventAccessFromCentralDomains
    → EnsureTenantIsActive → auth → verified → ParentPortalMiddleware
```
- `InitializeTenancyByDomain` and `PreventAccessFromCentralDomains` confirmed present (correct tenant isolation)
- `EnsureTenantHasModule` NOT present — a school can disable PPT in their subscription but parents can still access it
- `verified` middleware present — blocks email-unverified users; incompatible with OTP-only auth design

### A4. Stale Prior Findings

| Finding | Status | Notes |
|---|---|---|
| SEC-PPT-001 (Gate::define overwrite) | **FIXED** | `reportCardPdf()` now uses delegation pattern with bypass flag; no `Gate::define()` in current code |
| SEC-PPT-002 (Zero FormRequests) | **STALE** | 22 FormRequests confirmed (June 2026 snapshot was incorrect) |
| SEC-PPT-004 (Complaint injection) | **FIXED** | Target fields now explicitly set to null with comment referencing SEC-PPT-004 |
| VAL-PPT-001 (All controllers plain Request) | **STALE** | 22 FormRequests exist; description was incorrect at time of writing |
| VAL-PPT-002 (Complaint unvalidated fields) | **FIXED** | Same fix as SEC-PPT-004 |

---

## 4. Layer B — FRD Coverage

### B1. REQ Coverage Matrix

| REQ | Title | Priority | DDL | Screen | API | Test | Coverage % |
|---|---|---|---|---|---|---|---|
| REQ-PPT-001 | Dashboard | P0 | N/A | Partial | Stub | None | 50% |
| REQ-PPT-002 | OTP Login | P0 | N/A | None | None | None | **0% — P0** |
| REQ-PPT-003 | Notification Prefs | P0 | N/A | Partial | Stub | None | 60% |
| REQ-PPT-004 | Teacher Messaging | P0 | None | None | None | None | 0% |
| REQ-PPT-005 | Fee Payment | P0 | N/A | Partial | N/A | None | 65% |
| REQ-PPT-006 | Attendance | P0 | N/A | Partial | Stub | None | 40% |
| REQ-PPT-007 | Homework | P1 | N/A | Partial | N/A | None | 40% |
| REQ-PPT-008 | Leave Application | P1 | Delegates to std_ | Done | Stub | None | 70% |
| REQ-PPT-009 | Exam Results | P1 | N/A | Partial | N/A | None | 50% |
| REQ-PPT-010 | Timetable | P1 | N/A | Partial | N/A | None | 55% |
| REQ-PPT-011 | PTM Scheduling | P1 | PTM module | Partial | Stub | None | 65% |
| REQ-PPT-012 | Health (HPC) | P1 | N/A | Partial | N/A | None | 40% |
| REQ-PPT-013 | Transport | P1 | N/A | Partial | N/A | None | 30% |
| REQ-PPT-014 | Consent Forms | P1 | Done | Partial | N/A | None | 60% |
| REQ-PPT-015 | Document Requests | P1 | Done | Partial | N/A | None | 70% |
| REQ-PPT-016 | Events / RSVP | P1 | Done | Partial | N/A | None | 55% |
| REQ-PPT-017 | Profile Management | P1 | N/A | Partial | N/A | None | 60% |
| REQ-PPT-018 | Hostel Info | P1 | N/A | Partial | N/A | None | 30% |
| REQ-PPT-019 | Learning Resources | P1 | N/A | Partial | N/A | None | 30% |
| REQ-PPT-020 | Child Switcher | P2 | Done | Done | N/A | None | 80% |

**Critical Gaps:**
- REQ-PPT-002 (OTP Login): 0% — P0 blocker
- REQ-PPT-004 (Teacher Messaging): 0% — ppt_messages table deferred; CommonChat integration undefined

### B2. Leave Feature Clarification

The module-knowledge and BA baseline flagged `ppt_leave_applications` as a missing P0 table. This finding was based on the DDL listing. The live `ParentLeaveController` delegates entirely to `Modules\StudentProfile\Services\LeaveService` and `Modules\StudentProfile\Models\LeaveApplication`, operating on `std_leave_applications`. The PPT-owned `ppt_leave_applications` table was intentionally deferred in favor of the shared StudentProfile leave infrastructure. **This is NOT a P0 blocker** — the leave feature will function correctly given a working StudentProfile module.

---

## 5. Layer C — Business Rule Enforcement

### C1. Business Rule Coverage Matrix

| BR | Rule | Status | Gap |
|---|---|---|---|
| BR-PPT-001 | Every data endpoint verifies guardian→child ownership | PARTIAL | Ad-hoc via resolveChild(); no unified Policy layer |
| BR-PPT-002 | Fee invoice must belong to active child before payment | PARTIAL | initiate() checks ownership; callback() also checks |
| BR-PPT-004 | Leave from_date must be >= tomorrow | GAP | `StoreParentLeaveRequest` uses `after_or_equal:today` — allows same-day leave |
| BR-PPT-012 | Every endpoint verifies guardian→student ownership | PARTIAL | PTM book() and Event rsvp() have scope gaps |
| BR-PPT-013 | OTP rate-limiting/lockout | NOT STARTED | No OTP infrastructure exists |
| BR-PPT-015 | PTM slot booking uses SELECT...FOR UPDATE to prevent doubles | PARTIAL | lockForUpdate present; class-section scope missing |
| BR-PPT-016 | No double-booking per student per PTM event | PARTIAL | existingBooking check present; cross-class not guarded |
| BR-PPT-018 | Razorpay payment_id uniqueness/idempotency | PARTIAL | isPaid() check + signature verification present |
| BR-PPT-021 | Consent responses are legally immutable | DONE | Migration has no deleted_at; model has no SoftDeletes |
| BR-PPT-022 | One response per guardian per form per student | DONE | UNIQUE(consent_form_id, student_id, guardian_id) in migration |

### C2. Critical BR Gap — BR-PPT-004

`StoreParentLeaveRequest::rules()` specifies:
```php
'from_date' => ['required', 'date', 'after_or_equal:today'],
```
BR-PPT-004 requires `from_date >= tomorrow` to prevent retroactive leave applications. The current rule allows `from_date = today`, violating the business rule.

**Fix:** Change to `'after:today'` which enforces "strictly after today" (i.e., from tomorrow onwards).

---

## 6. Layer G — Cross-Cutting Concerns

### G1. Tenancy (Layer 1)

- Tenancy middleware stack (Pattern B) confirmed correct in RouteServiceProvider
- All 5 ppt_* migrations are in `database/migrations/tenant/` (correct location)
- All 6 models use `ppt_` prefix and will bind to tenant DB via stancl/tenancy
- `EnsureTenantHasModule` NOT in middleware stack (P2 gap — GAP-PPT-P2-03)
- `session('tenant_id') ?? 1` in `ParentPtmController` notification creation: hardcoded fallback to tenant_id=1 will silently mismatch in any school that is not tenant 1 (NEW finding — SEC-PPT-008)

### G2. Authorization (Layer 2)

The PPT module uses a unique authorization model: custom `ParentPortalMiddleware` (not Spatie roles) + `ParentContextService.resolveChild()` via `ParentPortalBaseRequest.authorize()`. This provides workable parent-scoped authentication but lacks a proper Policy layer for resource-level IDOR checks.

**What works:**
- `ParentPortalBaseRequest.authorize()` calls `resolveChild()` — real auth check (NOT a D30 false-positive)
- `ParentContextService.assertCanAccess()` provides explicit guardian→student link validation via `can_access_parent_portal` flag
- Complaint `store()` uses `StoreParentComplaintRequest` with FormRequest-level authorization
- PTM `cancel()` and `reschedule()` verify `booked_by_user_id === auth()->id()` and `student_id === $child->id`
- Fee `initiate()` and `callback()` verify child ownership

**What is broken or missing:**
- No `ParentChildPolicy` — the universal IDOR prevention policy intended for BR-PPT-012
- `ConsentFormPolicy` exists but is (a) never registered with Gate and (b) checks admin Spatie permissions (`tenant.consent-forms.viewAny` etc.) rather than parent-context IDOR prevention
- `ParentConsentFormController` never calls `$this->authorize()` — ConsentFormPolicy is dead code
- PTM `book()` has no class-section scope guard (SEC-PPT-003 — P0)
- Event `rsvp()` has no class-section scope guard (SEC-PPT-005 — P1, confirmed by prior audit)
- No policy-level enforcement on any document request, health data access, or attendance views

### G3. Security

| Code | Finding | Severity |
|---|---|---|
| SEC-PPT-003 | PTM `book()` — cross-class slot booking IDOR | **P0** |
| SEC-PPT-005 | Event `rsvp()` — cross-class RSVP (no class-section scope guard) | P1 |
| SEC-PPT-006 | ConsentForm `sign()` — signs any form without checking class/section scope | P1 |
| SEC-PPT-007 (NEW) | `ConsentFormPolicy` is dead code — never registered, wrong type (admin perms) | P1 |
| SEC-PPT-008 (NEW) | `session('tenant_id') ?? 1` in PTM notification creation — hardcoded fallback to tenant 1 | P1 |

### G4. Deployment (Layer 10)

- No jobs or queued operations in PPT — module relies on synchronous processing
- Platform-wide DEPLOY-HRZ-01 (queue driver database vs Horizon redis) does not directly affect PPT since no jobs exist
- Fee payment callback relies on synchronous Razorpay signature verification + DB transaction — correct approach
- No seeder routes found in PPT routes/web.php (SEC-RTG-001 pattern not replicated in this module)

### G5. Test Coverage (Layer 12)

Zero tests exist for a module that handles:
- Parent authentication and child resolution (IDOR attack surface)
- Razorpay payment flows (idempotency, race conditions)
- PTM slot booking with lockForUpdate (race conditions under concurrent load)
- Legally immutable consent form signatures (BR-PPT-021/022)
- Child ownership enforcement across 21 web controllers

Test gap is P1 (not P0 per rubric, but constitutes a critical risk for a production payment+legal module).

---

## 7. Layer D (Scoped) — DDL Schema Three-Way Reconcile

### D1. Table Inventory

| Table | DDL v2 | Migration | Model | SoftDeletes Match | Notes |
|---|---|---|---|---|---|
| `ppt_parent_sessions` | YES | YES (2026_06_16_105227) | YES (ParentSession) | CONSISTENT — both absent by design | Deactivated via is_active=0 |
| `ppt_event_rsvps` | YES | YES (2026_06_16_105226) | YES (EventRsvp) | CONSISTENT — both absent by design | Updated in-place |
| `ppt_document_requests` | YES | YES (2026_06_16_105225) | YES (ParentDocumentRequest) | Need verification | payment_reference UNIQUE nullable |
| `ppt_consent_forms` | YES | YES (2026_06_16_105224) | YES (ConsentForm) | CONSISTENT — both present | Model and migration have softDeletes |
| `ppt_consent_form_responses` | YES | YES (2026_06_16_105228) | YES (ConsentFormResponse) | CONSISTENT — both absent by design | Legally immutable; no deleted_at |

**Result:** No D36 (generated columns), no D38 (SoftDeletes mismatch), no D17 (prefix errors), no D25 ($request->all()) found in any PPT migration or model.

### D2. D29 — ENUM Columns (8 violations across 4 migrations)

| Table | Column | ENUM Values | Migration |
|---|---|---|---|
| `ppt_parent_sessions` | device_type | Android, Unknown, Web, iOS | 2026_06_16_105227 |
| `ppt_consent_forms` | status | Closed, Draft, Published | 2026_06_16_105224 |
| `ppt_consent_form_responses` | response | Declined, Signed | 2026_06_16_105228 |
| `ppt_document_requests` | document_type | Bonafide, Character, MarkSheet, MedicalFitness, Migration, Other, TC | 2026_06_16_105225 |
| `ppt_document_requests` | urgency | Normal, Urgent | 2026_06_16_105225 |
| `ppt_document_requests` | status | Completed, Pending, Processing, Ready, Rejected | 2026_06_16_105225 |
| `ppt_event_rsvps` | rsvp_status | Attending, Maybe, Not_Attending | 2026_06_16_105226 |

All 7 enum columns should be FK references to `sys_dropdown_options` per the platform D29 pattern. Adding a new device type or document type currently requires a migration rather than a DB row.

### D3. D36 Check

No `storedAs()`, `virtualAs()`, or `GENERATED ALWAYS` columns found in any PPT migration. D36 does not apply.

### D4. D38 Check

No SoftDeletes/timestamps discrepancy detected between DDL design intent and migrations/models. D38 does not apply.

---

## 8. Systemic Pattern Scorecard

| Pattern | Description | PPT Status | Severity |
|---|---|---|---|
| D17 | Wrong table prefix in model | NOT FOUND — all 6 models use correct `ppt_` prefix | Pass |
| D24 | Permission string typos | N/A — PPT uses custom middleware, not Spatie permissions for parent routes | N/A |
| D25 | `$request->all()` mass-assignment | NOT FOUND — 0 occurrences in module | Pass |
| D29 | ENUM instead of sys_dropdown FK | 7 enum columns in 4 migrations (device_type, status×2, response, document_type, urgency, rsvp_status) | P2 (MIG-PPT-001) |
| D30 | FormRequest `authorize()` bare `true` | NOT FOUND — `ParentPortalBaseRequest.authorize()` calls `resolveChild()` (real auth) | Pass (positive finding) |
| D36 | Generated column degraded to plain | NOT FOUND — no generated columns in PPT DDL | Pass |
| D37 | Status as INT FK vs string literal | NOT FOUND — status columns use string enum or referenced by string constants | Pass |
| D38 | SoftDeletes/timestamps DDL mismatch | NOT FOUND — all models consistent with migrations | Pass |
| D39 | Unseeded permissions → super-admin only | N/A — PPT does not use Spatie permissions for parent-facing routes | N/A |

---

## 9. Complete Findings Register

### P0 — Critical Blockers

| Code | Title | File:Line |
|---|---|---|
| SEC-PPT-003 | PTM `book()` has no class-section scope guard — cross-class slot booking IDOR | `ParentPtmController.php:~150` |
| REQ-PPT-002-ABSENT | OTP AuthController entirely absent — parent portal primary login not implemented | (no file) |

### P1 — High Risk

| Code | Title | File:Line |
|---|---|---|
| SEC-PPT-005 | Event `rsvp()` no class-section scope check — cross-class RSVP possible | `ParentEventController.php:89-150` |
| SEC-PPT-006 | ConsentForm `sign()` no class-section scope check — can sign forms not for child's class | `ParentConsentFormController.php:79-128` |
| SEC-PPT-007 (NEW) | `ConsentFormPolicy` is dead code: never registered in ServiceProvider; wrong type (admin Spatie perms, not parent IDOR) | `Policies/ConsentFormPolicy.php`, `Providers/ParentPortalServiceProvider.php` |
| SEC-PPT-008 (NEW) | `session('tenant_id') ?? 1` fallback in PTM notification creation — silently mismatch for any school that is not tenant 1 | `ParentPtmController.php:~185` |
| BUG-PPT-001 | 4 Api/ controllers are `abort(501)` stubs wired to live routes (Attendance, Dashboard, Leave, Session APIs) | `Api/ParentLeaveApiController.php:13` et al. |
| VAL-PPT-003 (NEW) | `StoreParentLeaveRequest` uses `after_or_equal:today` — allows same-day leave, violating BR-PPT-004 (must be >= tomorrow) | `Http/Requests/StoreParentLeaveRequest.php:17` |
| GAP-PPT-P1-01 | Teacher messaging (REQ-PPT-004) 0% — ppt_messages deferred; CommonChat integration undefined | (no file) |

### P2 — Medium Risk

| Code | Title | File:Line |
|---|---|---|
| MIG-PPT-001 (NEW) | D29: 7 ENUM columns across 4 migrations — should FK to sys_dropdown_options | database/migrations/tenant/*ppt_* |
| PERF-PPT-001 | N+1: updateNotificationPreferences issues 1 query per channel inside foreach | `ParentAccountController.php:186-193` |
| PERF-PPT-002 | 5 separate COUNT queries in leave.index — use groupBy+count instead | `ParentLeaveController.php:54-58` |
| PERF-PPT-003 | 3 individual DB queries for complaint labels in show() | `ParentComplaintController.php:211-221` |
| GAP-PPT-P2-01 | `EnsureTenantHasModule` not in RSP middleware — school can access PPT even when disabled | `Providers/RouteServiceProvider.php` |
| GAP-PPT-P2-02 | 0 tests for 28 controllers, payment flows, IDOR checks, and consent immutability | `Tests/` (empty) |

### Resolved / Stale Findings from Prior Audit

| Code | Prior Severity | Resolution |
|---|---|---|
| SEC-PPT-001 | P0 | FIXED — `Gate::define()` overwrite removed; delegation pattern with bypass flag now used in `reportCardPdf()` |
| SEC-PPT-002 | P0 | STALE — 22 FormRequests exist; snapshot was incorrect |
| SEC-PPT-004 | P0 | FIXED — target injection fields now explicitly null with code comment referencing SEC-PPT-004 |
| VAL-PPT-001 | P2 | STALE — same as SEC-PPT-002; FormRequests were present |
| VAL-PPT-002 | P2 | FIXED — same fix as SEC-PPT-004 |
| BUG-PPT-002 | P1 | OPEN — not re-verified (ParentPortalController scaffold stub) |
| BUG-PPT-003 | P1 | PARTIALLY OPEN — store() refactored to FormRequest; show() redundancy not re-verified |

---

## 10. Remediation Roadmap

### Sprint 1 — P0 Blockers (Must fix before live access)

1. **Fix SEC-PPT-003** in `ParentPtmController::book()`: Add class-section scope verification after child resolution. One guard: `$slot->assignment->eventClassSection->class_section_id === $child->currentSession->class_section_id`. Similar guard may be needed in `reschedule()`.

2. **Scaffold OTP AuthController**: Create `ParentOtpAuthController` with `sendOtp()`, `verifyOtp()`, `logout()` methods. Register routes outside the auth middleware (send/verify need to be public). Integrate SMS gateway (MSG91 or Twilio). Add rate limiter per mobile number (5 attempts / 10 min, lock 30 min per BR-PPT-013). Remove `verified` middleware from RSP stack (OTP users will not have email verified).

### Sprint 2 — P1 Security Fixes

3. **Fix SEC-PPT-005** in `ParentEventController::rsvp()`: Add class-section scope check against the event's `class_section_id` (event targets).

4. **Fix SEC-PPT-006** in `ParentConsentFormController::sign()`: Add scope check — `$form->class_id === null || $form->class_id === $child->currentSession->classSection->class_id`.

5. **Register or Replace ConsentFormPolicy** (SEC-PPT-007): Either register the existing policy for admin routes via `Gate::policy(ConsentForm::class, ConsentFormPolicy::class)` in the ServiceProvider, or create a separate `ParentConsentFormPolicy` scoped to parent context.

6. **Fix SEC-PPT-008**: Replace `session('tenant_id') ?? 1` with `tenant()->id` from stancl/tenancy helpers.

7. **Fix VAL-PPT-003**: Change `after_or_equal:today` to `after:today` in `StoreParentLeaveRequest`.

### Sprint 3 — P2 Debt and Validation

8. **Implement 4 abort(501) API controllers** (BUG-PPT-001): Attendance, Dashboard, Leave, Session APIs for PWA/mobile support.

9. **Add `EnsureTenantHasModule`** to RSP middleware stack.

10. **Convert 7 ENUM columns** (MIG-PPT-001) to `sys_dropdown_options` FK references via new migrations.

11. **Fix PERF-PPT-001/002/003**: Batch notification preference upsert; leave status counts via groupBy; complaint label lookup via whereIn.

12. **Write Pest tests**: At minimum cover SEC-PPT-003 regression (cross-class PTM booking), fee payment idempotency, child ownership enforcement, and consent form immutability.

---

## 11. Health Score Breakdown

| Layer | Weight | Score | Notes |
|---|---|---|---|
| Tenancy | 15 | 12 | Pattern B correct; EnsureTenantHasModule missing; session('tenant_id')??1 fallback |
| Authorization | 14 | 4 | No ParentChildPolicy; ConsentFormPolicy dead; IDOR gaps in book()/rsvp()/sign() |
| Data Integrity | 13 | 9 | lockForUpdate present in PTM; Razorpay sig verify + isPaid() present; class-section guard missing in book() |
| Validation | 11 | 9 | 22 FormRequests with real auth (positive); inline validate() in fee callback; BR-PPT-004 date gap |
| Deployment | 10 | 8 | No jobs/queues; OTP infra absent; `verified` middleware incompatible with OTP auth |
| Migration-Model-DDL | 9 | 8 | 5 tables clean; no D36/D38 gaps; 7 D29 enum columns |
| DDL Schema | 7 | 4 | 7 ENUM columns all should be dropdown FKs |
| Performance | 7 | 5 | N+1 in notification prefs; 5 COUNT queries in leave.index; complaint label queries |
| Queue/Job | 6 | 5 | No async ops by design; acceptable for current scope |
| Code Quality | 4 | 2 | Dead ConsentFormPolicy (wrong type); stub controllers; tenant_id hardcode |
| ORM | 2 | 1 | Minor N+1 patterns; no D17/D25 |
| Frontend | 2 | 1 | 45 views present; 0 tests |
| **Raw Total** | **100** | **68** | — |
| **P0 Cap Applied** | — | **40** | 2 active P0 issues cap score to 40 |

**Final Health Score: 40 / 100 — NO-GO**

---

## 12. DDL / Code Evidence Checklist

| Evidence | File Verified | Finding |
|---|---|---|
| RouteServiceProvider middleware stack | `Providers/RouteServiceProvider.php:43-54` | Pattern B confirmed; EnsureTenantHasModule absent |
| ServiceProvider policy registration | `Providers/ParentPortalServiceProvider.php:25-33` | No registerPolicies(); ConsentFormPolicy unreachable |
| ParentContextService.resolveChild() | `Services/ParentContextService.php:63-88` | Proper guardian→child resolution; assertCanAccess() enforces link |
| ParentContextService.getAccessibleChildren() | `Services/ParentContextService.php:29-52` | Filters by can_access_parent_portal=1 flag; correct |
| ParentPortalBaseRequest.authorize() | `Http/Requests/ParentPortalBaseRequest.php:11-19` | Calls resolveChild() — real auth, NOT D30 bare true |
| PTM book() IDOR gap | `Http/Controllers/ParentPtmController.php:~150` | No class-section scope check on slot in book() action |
| ConsentFormPolicy type | `Policies/ConsentFormPolicy.php:16-66` | All methods check admin Spatie permissions — wrong for parent portal |
| SEC-PPT-001 FIXED | `Http/Controllers/ParentResultController.php` | No Gate::define(); delegation with bypass flag + child ownership check |
| SEC-PPT-004 FIXED | `Http/Controllers/ParentComplaintController.php:133` | Comment confirms SEC-PPT-004 fix; target fields null |
| PERF-PPT-002 CONFIRMED | `Http/Controllers/ParentLeaveController.php:54-58` | 5 separate COUNT queries confirmed in current code |
| D29 enums | `database/migrations/tenant/2026_06_16_105224-105228` | 7 enum columns across 4 migrations confirmed |
| D36 check | All 5 PPT migrations | No generated columns — D36 does not apply |
| D38 check | All 6 PPT models vs migrations | No SoftDeletes mismatch — D38 does not apply |
| leave controller cross-module delegation | `Http/Controllers/ParentLeaveController.php:1-17` | Delegates to StudentProfile.LeaveService — ppt_leave_applications NOT needed |
