# Mobile SRS — Batch 07 (Communication · HPC)

> Index: `02_mobile_srs_index.md`. Features: F-080, F-081, F-082, F-083, F-084, F-090, F-091.

---

## F-080: Notification Inbox

### 1. Overview
Central inbox of all notifications received. Tabs: Unread / All. **Hard pre-req:** BG-08 (NTF routes are commented out — BUG-NEW-002).

### 2. User Stories
- **US-080.1** *As any user, I want a single inbox of school messages, so I never miss a notice.*
- **US-080.2** *Tap any notification → deep-link to the source feature.*
- **US-080.3** *Mark read on view; long-press to mark unread.*

### 3. Functional Requirements
- **FR-080.1** Inbox paginated 20/page; query params `status=unread|read|all`, `category=academics|fees|transport|...`.
- **FR-080.2** Mark-read endpoint idempotent.
- **FR-080.3** Deep-links resolve to in-app routes; if route disabled (feature flag), fallback message.
- **FR-080.4** Soft delete supported.
- **FR-080.5** Notification "category" mapped from `ntf_notification_categories` (D29 — sys_dropdown_table).

### 4. Screen Specifications

#### S-080.1 — Inbox
List rows with category icon, title, body preview, time, unread dot.

States: loading, empty ("All caught up 🎉"), error, offline (cached).

### 5. API Contracts

#### `GET /api/mobile/v1/notifications?status=&category=&page=`
- **Status:** MODIFY (BG-08 uncomment routes; fix `tenant.*` Gate prefix).

#### `POST /api/mobile/v1/notifications/{id}/read`
- Idempotent.

### 6. Data Model
```sql
cache_notifications (id PRIMARY KEY, payload_json, read_at)
pending_writes  (read-receipts batched)
```

### 7. Offline Behavior
Read inbox cached; read-receipts queued; flushed every 60 s.

### 8. Push Notifications
This is the hub for all incoming pushes.

### 9. Permissions & Security
- BUG-NEW-002 (BG-08) hard pre-req.
- Per-user scoping (Sanctum auth).
- Audit: not logged.

### 10. Non-Functional Requirements
- Cached < 200 ms.
- Localization: `f080.tab.*`, `f080.empty`.
- Analytics: `notif_open`, `notif_click_deep_link`.

### 11. Acceptance Criteria
- **AC-080.1** Unread count badge updates on mark-read within 1 s.
- **AC-080.2** Tampered `/notifications/{otherUserNotif}` → 403.
- **AC-080.3** Deep-link to disabled feature falls back gracefully.

### 12. Dependencies
- F-002. BG-08.

### 13. Out of Scope
- In-app ad / promo carousel — never planned.
- Cross-tenant inbox — out of scope.

---

## F-081: Push Notification Preferences

### 1. Overview
User toggles which categories of pushes they want, sets quiet hours, mutes specific threads (e.g. "this homework assignment").

### 2. User Stories
- **US-081.1** *As a user, I disable "library reminders" and keep "fees" on.*
- **US-081.2** *I set quiet hours 22:00–07:00 — only `security` and `transport` (safety) channels still ring.*

### 3. Functional Requirements
- **FR-081.1** Per-category toggle: on/off + per-channel sound override.
- **FR-081.2** Quiet hours stored on `ntf_user_preferences`.
- **FR-081.3** Server respects quiet hours when dispatching pushes — except for non-respecting channels (`security`, `transport`).
- **FR-081.4** Thread-mute via `ntf_thread_mutes` table (NEW — BG-37).

### 4. Screen Specifications
List of categories with toggles + quiet-hours form.

### 5. API Contracts

#### `GET / PUT /api/mobile/v1/preferences/notifications`
- **Status:** MODIFY (BG-08 + BG-37). Module: Notification.

### 6. Data Model
`cache_preferences_notifications`.

### 7. Offline Behavior
Read cached; writes queued.

### 8. Push Notifications
None (config feature).

### 9. Permissions & Security
- Per-user scoping.

### 10. Non-Functional Requirements
- Save perceived < 200 ms.
- Localization: `f081.category.*`, `f081.quiet_hours`.

### 11. Acceptance Criteria
- **AC-081.1** A push to a disabled category does NOT reach the device (verified end-to-end).
- **AC-081.2** During quiet hours, `academics` push silenced; `transport` still rings.

### 12. Dependencies
- F-080. BG-08, BG-37.

### 13. Out of Scope
- Per-feature granularity beyond category — v1.1.

---

## F-082: Parent-Teacher 1:1 Messaging (P1)

### 1. Overview
DM-style chat between a parent and a teacher (or class teacher). Threads grouped per child. **Hard pre-req:** BG-29 (Communication module — PLANNED).

### 2. User Stories
- **US-082.1** *As a parent, I message my child's class teacher about late pickup.*
- **US-082.2** *As a teacher, I see my parent threads grouped by class.*
- **US-082.3** *Edge — abusive content: report-block flow.*

### 3. Functional Requirements
- **FR-082.1** Threads scoped: `(parent, teacher, student_id?)` triple.
- **FR-082.2** Messages: text + (P1) photo attachments.
- **FR-082.3** Read-receipts client-side, 60-s flush.
- **FR-082.4** Block / report flow (writes to `com_message_reports`).
- **FR-082.5** No cross-tenant messaging.
- **FR-082.6** No teacher-to-teacher chat at v1.

### 4. Screen Specifications

#### S-082.1 — Threads list
Grouped by child + sorted by last message.

#### S-082.2 — Thread
Chat bubbles, "Asha" subtitle to indicate context, attachment menu.

States: loading, empty, error, offline (queued sends).

### 5. API Contracts

#### `GET /api/mobile/v1/messaging/threads`
#### `GET /api/mobile/v1/messaging/threads/{id}/messages`
#### `POST /api/mobile/v1/messaging/threads/{id}/messages`
- **Status:** NEW (BG-29). Module: Communication (PLANNED).
- WebSocket channel `private-thread.{id}` for live (Phase 3).

### 6. Data Model
`cache_threads`, `cache_messages` keyed by thread_id.

### 7. Offline Behavior
Queued send; resync on reconnect.

### 8. Push Notifications
Emits `MESSAGE_RECEIVED`. Channel `messaging`. Respects quiet hours.

### 9. Permissions & Security
- Authorize: thread participants only.
- DLT-compliant SMS fallback NOT in v1 (Q-7).
- Content moderation: server-side `com_blocked_words` filter.
- Audit: `MESSAGE_REPORTED` row.

### 10. Non-Functional Requirements
- Send perceived < 200 ms.
- 1:1 chat with WS round-trip < 1 s.
- Localization: `f082.empty`, `f082.report.*`.

### 11. Acceptance Criteria
- **AC-082.1** Parent A cannot create a thread with Teacher of student-of-Parent-B (BR-PPT-012 enforced).
- **AC-082.2** Reported message visible to admin in web console.
- **AC-082.3** Quiet hours suppress message-received pushes but messages still queue.

### 12. Dependencies
- F-002, F-005. BG-29 Communication module.

### 13. Out of Scope
- Group chats — v1.2.
- Voice / video calls — v1.2+.
- Stickers / GIFs — v1.2.

---

## F-083: Notice Board (School-wide notices)

### 1. Overview
Read-only feed of school-wide and audience-targeted notices (e.g. "All Class V parents — annual day on …"). **New table** `sch_notices` (BG-38).

### 2. User Stories
- **US-083.1** *As a parent, I scroll through the school notice feed; clicking opens detail with attachments.*
- **US-083.2** *Filter by audience: All / My Class / My Child's Class.*

### 3. Functional Requirements
- **FR-083.1** Audience filter applied server-side based on (role, class, child).
- **FR-083.2** Attachments via signed URL.
- **FR-083.3** Soft deletes.

### 4. Screen Specifications
Feed list with title, snippet, time, attachment indicator.

### 5. API Contracts

#### `GET /api/mobile/v1/notices?audience=&page=`
- **Status:** NEW (BG-38). Module: SchoolSetup (new table).

### 6. Data Model
`cache_notices` paged.

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
Consumes `NOTICE_PUBLISHED`.

### 9. Permissions & Security
- Audience scoping.
- Audit: not logged (read-only).

### 10. Non-Functional Requirements
- Cached < 200 ms.
- Localization: `f083.audience.*`.

### 11. Acceptance Criteria
- **AC-083.1** Class IV parent does not see notice targeted to "Class V parents only".

### 12. Dependencies
- F-002. BG-38.

### 13. Out of Scope
- Notice authoring — web-only.

---

## F-084: Circulars (Acknowledgement-required, P1)

### 1. Overview
Like notices but require explicit "Acknowledged" action; backend tracks per-user ack. Useful for fee reminders, policy updates.

### 2. User Stories
- **US-084.1** *As a parent, I see a circular requires acknowledgement; tapping "I acknowledge" closes it.*
- **US-084.2** *As an admin (web), I see who has and hasn't acknowledged.*

### 3. Functional Requirements
- **FR-084.1** `POST /circulars/{id}/ack` — idempotent.
- **FR-084.2** Acknowledged circulars move to "Done" tab.
- **FR-084.3** Optional digital signature (typed name) — Q-OQ.

### 4. Screen Specifications
Two tabs: Pending / Done. Detail screen shows full content + ack button.

### 5. API Contracts

#### `GET /api/mobile/v1/circulars`
#### `POST /api/mobile/v1/circulars/{id}/ack`
- **Status:** NEW (BG-38).

### 6. Data Model
`cache_circulars` paged.

### 7. Offline Behavior
Read cached; ack queued.

### 8. Push Notifications
Emits `CIRCULAR_PUBLISHED`. Reminder T-3 days if not acknowledged.

### 9. Permissions & Security
- Audience scoping.
- Audit: `CIRCULAR_ACKED` (compliance — necessary for fee/compliance tracking).

### 10. Non-Functional Requirements
- Ack perceived < 200 ms.
- Localization: `f084.cta.{ack,signed}`.

### 11. Acceptance Criteria
- **AC-084.1** Re-ack of same circular returns 200 idempotently; counter not double-incremented.
- **AC-084.2** Pending tab shows only un-acked.

### 12. Dependencies
- F-080, F-083. BG-38.

### 13. Out of Scope
- Multi-stakeholder circulars (any of N must ack) — v1.2.

---

## F-090: View HPC Report (Student / Parent)

### 1. Overview
View Holistic Progress Card (HPC). Module **Hpc** is FULL ~70% with 4 PDF templates × 30–50 pages (D13). **Hard pre-req:** BG-11 (SEC-HPC-001 — 13/15 controllers no auth) + BG-06 (BUG-001 missing model imports → fatal Gate calls).

### 2. User Stories
- **US-090.1** *As a parent, I view Asha's Term 1 HPC including PDF render in app.*
- **US-090.2** *As a student, I view my HPC at end of term.*

### 3. Functional Requirements
- **FR-090.1** Endpoint scoped to (student | parent + child).
- **FR-090.2** Returns metadata + signed PDF URL (BG-33).
- **FR-090.3** Display in CC-05 viewer.
- **FR-090.4** Status `PUBLISHED` only — drafts hidden.
- **FR-090.5** Pre-requisite: BUG-001 fixed in `AppServiceProvider`.

### 4. Screen Specifications
List of HPC reports (one per term) → tap → CC-05 PDF viewer.

### 5. API Contracts

#### `GET /api/mobile/v1/hpc/me`
#### `GET /api/mobile/v1/hpc/student/{student_id}`
- **Status:** MODIFY (BG-11). Module: Hpc.
- **Header:** active-child for parent.
- **Response 200:** `{ data:[{ report_id, term, published_at, pdf_url, expires_at }] }`.

### 6. Data Model
`cache_hpc_reports` per student.

### 7. Offline Behavior
Read-only cached; PDF cache after first download.

### 8. Push Notifications
Consumes `HPC_REPORT_PUBLISHED`.

### 9. Permissions & Security
- **CRITICAL** — SEC-HPC-001 (BG-11). 13 / 15 HpcController methods no auth currently.
- BUG-001 missing model imports must be fixed (BG-06).
- BR-PPT-012 for parent.
- Audit: `HPC_VIEWED` (compliance).

### 10. Non-Functional Requirements
- 30-page PDF first paint < 3.5 s.
- Localization: `f090.title`, `f090.empty`.

### 11. Acceptance Criteria
- **AC-090.1** Without BG-11 / BG-06 fixed, mobile MUST not call this endpoint (CI infra check).
- **AC-090.2** Parent A cannot read child of Parent B.
- **AC-090.3** Drafts (status ≠ PUBLISHED) not visible.

### 12. Dependencies
- F-002, F-005. BG-06, BG-11, BG-33.

### 13. Out of Scope
- HPC editing on mobile — web-only / DomPDF designer.
- Skill rubric drilldowns — v1.1.

---

## F-091: Parent Form Token Submission (HPC, P1)

### 1. Overview
HPC requires parent input on certain rubric items. Backend issues a one-time token; mobile resolves it to a form, parent submits.

### 2. User Stories
- **US-091.1** *As a parent, I receive a push "HPC parent form due"; tapping deep-links to the form.*

### 3. Functional Requirements
- **FR-091.1** Token resolved: `GET /hpc/parent-form/{token}` — single-use + time-limited.
- **FR-091.2** Submit: `POST /hpc/parent-form/{token}` with answer payload.
- **FR-091.3** After submit, form locked (single-use).
- **FR-091.4** Pre-req: BG-11 (auth) + BG-06.

### 4. Screen Specifications
Token-resolved form: Likert / text / radio fields with progress indicator.

### 5. API Contracts

#### `GET / POST /api/mobile/v1/hpc/parent-form/{token}`
- **Status:** MODIFY (BG-11).

### 6. Data Model
Ephemeral; not cached.

### 7. Offline Behavior
Form cached after fetch; submit queued.

### 8. Push Notifications
Consumes `HPC_PARENT_FORM_DUE`.

### 9. Permissions & Security
- Token bound to (parent_id, child_id, form_id).
- BR-PPT-012.
- Audit: `HPC_PARENT_FORM_SUBMITTED`.

### 10. Non-Functional Requirements
- Submit perceived < 200 ms.
- Localization: `f091.field.*`, `f091.cta.submit`.

### 11. Acceptance Criteria
- **AC-091.1** Token reuse → 410 GONE.
- **AC-091.2** Token of another parent → 403.

### 12. Dependencies
- F-080, F-090. BG-11.

### 13. Out of Scope
- Editing after submit — never planned.

---

> End Batch 07. Continue to `02_mobile_srs_batch_08.md` (Leave + Library + Hostel).
