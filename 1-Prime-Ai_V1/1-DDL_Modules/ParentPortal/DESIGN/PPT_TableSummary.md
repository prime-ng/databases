# PPT — Parent Portal Module: Table Summary
**Date:** 2026-03-27 | **Module:** ParentPortal | **DB:** tenant_db

---

## Overview

The Parent Portal introduces **6 new `ppt_*` tables**. All other data is **read** from 30+ existing module tables. No `ppt_*` table has a FK to another `ppt_*` table — all are Layer 1 (pure external FKs only).

---

## Table Index

| # | Table | Rows/Tenant Est. | Has `deleted_at` | Key Constraint(s) |
|---|---|---|---|---|
| 1 | `ppt_parent_sessions` | ~3–5 × number of guardians | ❌ (use `is_active=0`) | UNIQUE (guardian_id, device_token_fcm) |
| 2 | `ppt_messages` | High (~100s per active school year) | ✅ | FULLTEXT (subject, message_body) |
| 3 | `ppt_leave_applications` | ~10–50 per student per year | ✅ | UNIQUE (application_number); INDEX (student_id, status) |
| 4 | `ppt_event_rsvps` | ~events × guardians | ❌ (update rsvp_status) | UNIQUE (event_id, guardian_id) |
| 5 | `ppt_document_requests` | Low (~5–15 per student lifetime) | ✅ | UNIQUE (request_number); UNIQUE (payment_reference, nullable) |
| 6 | `ppt_consent_form_responses` | Low-medium (~forms × students) | ❌ **IMMUTABLE** | UNIQUE (consent_form_id, student_id, guardian_id) |

---

## Detailed Table Descriptions

### 1. `ppt_parent_sessions`

**Purpose:** Tracks per-device portal state for each guardian — which child is currently active, push notification device tokens (FCM/APNs/WebPush), notification preferences, and quiet hours.

**Design decisions:**
- No `deleted_at` — logout sets `is_active = 0`; stale rows cleaned up by scheduled cron
- `active_student_id` is nullable FK to `std_students` — NULL until parent selects a child
- UNIQUE on `(guardian_id, device_token_fcm)` prevents duplicate FCM token registration per guardian per device
- `notification_preferences_json` stores per-alert-type per-channel toggles: `{"FeeReminder":{"in_app":1,"sms":1,"email":0}}`

**Key columns:** `guardian_id` (INT UNSIGNED FK), `active_student_id` (INT UNSIGNED NULL FK), `device_token_fcm`, `device_token_apns`, `device_token_webpush` (TEXT for Web Push subscription JSON), `notification_preferences_json` (JSON), `quiet_hours_start/end` (TIME)

**Row count rationale:** A school with 500 guardians, each averaging 2 devices = ~1,000 rows. Low-volume table.

---

### 2. `ppt_messages`

**Purpose:** Parent-teacher direct messages scoped to a specific child context. Thread-based model using `thread_id = MD5(guardian_id + '_' + teacher_user_id + '_' + student_id)`.

**Design decisions:**
- `sender_user_id` and `recipient_user_id` = `INT UNSIGNED` — **verified**: `sys_users.id = INT UNSIGNED` in tenant_db_v2.sql
- FULLTEXT INDEX on `(subject, message_body)` enables full-text search per FR-PPT-04
- Composite INDEX on `(thread_id, created_at)` is the primary read pattern (load conversation)
- `attachment_media_ids_json` stores array of `sys_media.id` values — actual files stored in sys_media
- `direction` ENUM distinguishes Parent_to_Teacher vs Teacher_to_Parent replies

**Key columns:** `thread_id` (VARCHAR 64 — MD5 hash), `direction` (ENUM), `sender_user_id` (INT UNSIGNED), `recipient_user_id` (INT UNSIGNED), `read_at` (TIMESTAMP NULL)

**Row count rationale:** Active school with 500 parents × 5 messages/year/teacher × 6 teachers avg = ~15,000 rows/year. Medium-volume; grows linearly.

---

### 3. `ppt_leave_applications`

**Purpose:** Leave applications submitted by guardian on behalf of child. Follows PENDING → APPROVED/REJECTED/WITHDRAWN FSM. Approval triggers cross-module event to attendance module (BR-PPT-017).

**Design decisions:**
- `application_number` format: `PPT-LV-YYYY-XXXXXXXX` — generated in service layer before insert
- `from_date >= tomorrow` validated in `ApplyLeaveRequest` (not DB constraint — too inflexible)
- `number_of_days` computed in service layer (excluding holidays) before save
- `reviewed_by_user_id` = `INT UNSIGNED` (sys_users FK for class teacher)
- Composite INDEX on `(student_id, status)` is primary read pattern (list by child + filter pending)

**Key columns:** `application_number` (UNIQUE), `from_date` (DATE), `to_date` (DATE), `number_of_days` (TINYINT UNSIGNED), `leave_type` (ENUM 6 values), `status` (ENUM 4 states), `reviewed_by_user_id`, `reviewer_notes`

**Row count rationale:** 500 students × 5 leaves/year = ~2,500 rows/year. Low-volume.

---

### 4. `ppt_event_rsvps`

**Purpose:** Parent RSVPs and volunteer sign-ups for school events. One record per guardian per event.

**Design decisions:**
- No `deleted_at` — cancel by updating `rsvp_status = 'Not_Attending'` (keeps audit trail)
- UNIQUE on `(event_id, guardian_id)` enforces one RSVP per guardian per event (BR-PPT-016)
- `event_id` has NO FK constraint — Event Engine is a soft dependency (avoid migration coupling)
- `is_volunteer + volunteer_role` both NULL when not volunteering; `is_volunteer=1` + `volunteer_role` filled when signing up as volunteer
- No `student_id` FK constraint needed for events that affect all guardians regardless of child

**Key columns:** `event_id` (INT UNSIGNED — no FK, soft dep), `rsvp_status` (ENUM 3 values), `is_volunteer` (TINYINT), `volunteer_role` (VARCHAR 150), `confirmed_at`, `reminder_sent_at`

**Row count rationale:** 10 events/year × 500 guardians × 60% RSVP rate = ~3,000 rows/year. Low-volume.

---

### 5. `ppt_document_requests`

**Purpose:** Online requests for duplicate certificates (TC, MarkSheet, Bonafide, etc.). Follows PENDING → PROCESSING → READY (if fee required) → COMPLETED FSM.

**Design decisions:**
- `request_number` format: `PPT-DR-YYYY-XXXXXXXX` — unique per tenant
- `payment_reference` UNIQUE NULLABLE — MySQL allows multiple NULLs on UNIQUE column; ensures Razorpay idempotency (BR-PPT-011) when fee_required > 0
- `fee_paid` TINYINT flag updated after successful Razorpay payment
- `fulfilled_media_id` FK to sys_media — admin uploads completed document
- Download uses `Storage::temporaryUrl()` — 24-hour signed URL (BR-PPT-007 / SUG-PPT-07)

**Key columns:** `request_number` (UNIQUE), `document_type` (ENUM 7 values), `status` (ENUM 5 states), `fee_required` (DECIMAL 8,2), `fee_paid` (TINYINT), `payment_reference` (UNIQUE nullable), `fulfilled_media_id` (INT UNSIGNED FK)

**Row count rationale:** 500 students × 2 document requests lifetime = ~1,000 rows. Very low-volume.

---

### 6. `ppt_consent_form_responses`

**Purpose:** Stores parent's signed/declined response to school digital consent forms. **Immutable after creation** — no soft-delete, no update path once signed.

**Design decisions:**
- **NO `deleted_at`** — consent forms are legal records; cannot be deleted or modified
- `signed_at` is a BUSINESS timestamp (immutable, legal significance) — separate from `created_at`
- `signed_ip` captures IPv4/IPv6 at time of signing for audit evidence
- UNIQUE on `(consent_form_id, student_id, guardian_id)` — DB-level prevention of double-signing (BR-PPT-014)
- `consent_form_id` has NO FK constraint — Event/Activity module is soft dependency
- `signer_name` sanitized in `ConsentFormSignRequest::prepareForValidation()` via `strip_tags()`

**Key columns:** `consent_form_id` (INT UNSIGNED — no FK), `response` (ENUM Signed/Declined), `decline_reason` (TEXT NULL), `signer_name` (VARCHAR 150), `signed_ip` (VARCHAR 45), `signed_at` (TIMESTAMP — immutable)

**Row count rationale:** 5 consent forms/year × 500 students = ~2,500 rows/year. Low-volume.

---

## Additional Migration Required (Phase P1)

> **⚠️ DDL Gap identified during Phase 1 analysis:**
> The requirement references `std_health_records.parent_visible` but:
> - Table is actually `std_health_profiles` (confirmed in tenant_db_v2.sql)
> - `std_health_profiles` has **NO `parent_visible` column**
>
> P1 requires a separate migration to add this column:
> ```php
> Schema::table('std_health_profiles', function (Blueprint $table) {
>     $table->tinyInteger('parent_visible')
>           ->default(0)
>           ->after('dietary_restrictions')
>           ->comment('1 = visible to parent in portal; 0 = hidden (default)');
> });
> ```
> File: `database/migrations/tenant/2026_xx_xx_add_parent_visible_to_std_health_profiles.php`

---

## FK Type Reference (tenant_db_v2.sql verified 2026-03-27)

| External Table | PK Type | Use in ppt_* |
|---|---|---|
| `std_guardians.id` | INT UNSIGNED | All guardian_id columns |
| `std_students.id` | INT UNSIGNED | All student_id columns |
| `sys_users.id` | INT UNSIGNED | sender_user_id, recipient_user_id, reviewed_by_user_id |
| `sys_media.id` | INT UNSIGNED | supporting_doc_media_id, fulfilled_media_id |
| `created_by` | BIGINT UNSIGNED | Platform standard (per prompt spec) |
