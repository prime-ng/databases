# PPT (Parent Portal) Module — DDL Field-by-Field Explanation

> **Source DDL:** `PPT_DDL_v1.sql` (2026-03-27)
> **Database:** tenant_db | 6 tables | Prefix: `ppt_*`
> **Date:** 2026-04-14
> **Purpose:** Explain WHY each table exists, WHY each field is needed, and HOW it is used in the Parent Portal workflow.

---

## Table of Contents

1. [ppt_parent_sessions](#table-1-ppt_parent_sessions)
2. [ppt_messages](#table-2-ppt_messages)
3. [ppt_leave_applications](#table-3-ppt_leave_applications)
4. [ppt_event_rsvps](#table-4-ppt_event_rsvps)
5. [ppt_document_requests](#table-5-ppt_document_requests)
6. [ppt_consent_form_responses](#table-6-ppt_consent_form_responses)
7. [Cross-Table Design Decisions](#cross-table-design-decisions)

---

## Table 1: `ppt_parent_sessions`

### Why This Table Exists

A parent may have **multiple children** in the same school and may log in from **multiple devices** (Android phone, iOS tablet, web browser at work). The portal needs to remember:

1. **Which child is currently selected** — so every page shows the correct child's data without the parent re-selecting each time.
2. **Push notification tokens** — so the school can send alerts (fee reminders, bus GPS, attendance) to the parent's specific device.
3. **Notification preferences** — so the parent controls what they receive and when (quiet hours at night).

Without this table, the active child selection would live in the PHP session (lost on logout, not shared across devices) and push tokens would have nowhere to be stored.

**Volume:** ~3–5 rows per guardian (one per device). Medium volume.

---

### Fields

| # | Field | Type | Why It Exists / How It Is Used |
|---|-------|------|-------------------------------|
| 1 | `id` | INT UNSIGNED PK | Auto-increment primary key. INT (not BIGINT) because session volume per tenant is low — a school with 2,000 parents averaging 3 devices = ~6,000 rows max. INT supports up to 4.2 billion, which is far more than enough. |
| 2 | `guardian_id` | INT UNSIGNED, NOT NULL | **Links this session to the parent/guardian.** References `std_guardians.id`. A guardian may have multiple sessions (one per device). This is the primary lookup key — when a parent logs in, the system finds all their active sessions. ON DELETE CASCADE ensures sessions are cleaned up if the guardian record is removed. |
| 3 | `active_student_id` | INT UNSIGNED, NULL | **Tracks which child the parent is currently viewing.** This is the core of the multi-child switcher. When a parent with 3 children opens the dashboard, the portal reads this field to know whose attendance, fees, homework to display. **Nullable** because a freshly created session hasn't selected a child yet (the system defaults to the first linked child). **Stored in DB (not PHP session)** so it survives page reloads, browser restarts, and device switches — if a parent selects Child B on their phone, their laptop also shows Child B. ON DELETE SET NULL: if a child is removed from the school, the session doesn't break — it just resets to null and the portal picks the next available child. |
| 4 | `device_token_fcm` | VARCHAR(255), NULL | **Firebase Cloud Messaging token for Android devices.** When a parent installs the school's Android app or enables PWA notifications, Google issues a unique token for that device. The school server uses this token to push alerts like "Fee due in 3 days" or "Your child's bus has departed." VARCHAR(255) because FCM tokens are typically 150–160 characters but Google reserves the right to extend them. **Nullable** because web-only users won't have an FCM token. |
| 5 | `device_token_apns` | VARCHAR(255), NULL | **Apple Push Notification Service token for iOS devices.** Same concept as FCM but for iPhones/iPads. Apple issues a device-specific hex token (~64 chars). Stored separately from FCM because the push delivery mechanism is completely different — the server must send to Google's FCM API vs. Apple's APNs API depending on which token is populated. **Nullable** because Android/web users won't have this. |
| 6 | `device_token_webpush` | TEXT, NULL | **Web Push subscription payload for PWA (Progressive Web App) users.** Unlike FCM/APNs which are simple strings, Web Push requires a JSON object containing `endpoint`, `keys.p256dh`, and `keys.auth` — typically 300–500 characters. Stored as TEXT (not VARCHAR) because the JSON structure can vary by browser and may grow. This enables push notifications in Chrome, Firefox, Safari without a native app. **Nullable** because native app users don't need this. |
| 7 | `device_type` | ENUM('Android','iOS','Web','Unknown') | **Identifies which push channel to use for this session.** When the notification system needs to send an alert, it checks this field to decide: Android → use `device_token_fcm`, iOS → use `device_token_apns`, Web → use `device_token_webpush`. Also used for analytics (how many parents use mobile vs web). Defaults to `'Unknown'` for sessions created before the device type was captured. |
| 8 | `notification_preferences_json` | JSON, NULL | **Per-parent, per-alert-type notification settings.** Stores a structured object like: `{"FeeReminder": {"in_app": 1, "sms": 1, "email": 0}, "BusAlert": {"in_app": 1, "push": 1}}`. This allows each parent to individually choose which alert types they want on which channels. **Why JSON instead of a separate table?** Because preferences are always read/written as a whole block (never queried by individual key), and the schema varies as new alert types are added — JSON avoids migration churn. **Nullable** because default preferences (all enabled) apply when null. |
| 9 | `quiet_hours_start` | TIME, NULL | **Start of the "do not disturb" window.** For example, `22:00` means the parent does not want push/SMS notifications after 10 PM. During quiet hours, the notification system queues messages instead of delivering them immediately. TIME type (not DATETIME) because this is a daily recurring rule, not a one-time setting. **Nullable** means no quiet hours configured (notifications delivered anytime). |
| 10 | `quiet_hours_end` | TIME, NULL | **End of the "do not disturb" window.** For example, `07:00` means resume notifications at 7 AM. The system handles overnight ranges (22:00 → 07:00) correctly — if `start > end`, the quiet window crosses midnight. Queued notifications are delivered when quiet hours end. **Nullable** — paired with `quiet_hours_start`; both must be set or both null. |
| 11 | `last_active_at` | TIMESTAMP, NULL | **Tracks when the parent last interacted with the portal.** Updated on each authenticated request (or periodically). Used for: (a) showing "last seen" to school admins, (b) identifying stale sessions for cleanup cron, (c) analytics on parent engagement. **Nullable** because a brand-new session hasn't had any activity yet. |
| 12 | `is_active` | TINYINT(1), DEFAULT 1 | **Soft-active flag for session lifecycle.** `1` = session is live and can receive push notifications. `0` = parent logged out from this device (or admin revoked). **Why not use `deleted_at`?** Because sessions are not "deleted" — they're deactivated. A parent logging back in on the same device reactivates the existing session (updates `is_active=1`) rather than creating a new row. This preserves the push token history. A background cron hard-deletes rows where `is_active=0` AND `last_active_at < 90 days ago`. |
| 13 | `created_by` | BIGINT UNSIGNED, NULL | **Platform audit standard — who created this record.** Typically the parent's own `sys_users.id`. BIGINT UNSIGNED is the platform-wide convention for `created_by` across all modules (even though `sys_users.id` is INT UNSIGNED — the extra headroom is intentional per the architecture team's decision). **Nullable** for system-generated sessions (e.g., auto-created on first login). |
| 14 | `created_at` | TIMESTAMP, DEFAULT CURRENT_TIMESTAMP | **When this session was first created.** Auto-populated by MySQL. Used for auditing and sorting sessions by age. |
| 15 | `updated_at` | TIMESTAMP, ON UPDATE CURRENT_TIMESTAMP | **When this session was last modified.** Auto-updated by MySQL on any column change. Useful for debugging (when was the push token last refreshed?) and for cache invalidation. |

### Why No `deleted_at`?

Sessions are **transient infrastructure records**, not business data. When a parent logs out, set `is_active=0`. When they log back in, set `is_active=1`. A cron job periodically hard-deletes truly stale sessions (inactive for 90+ days). Soft-delete would add unnecessary overhead to every query and serve no audit purpose.

### Key Indexes & Constraints

| Index/Constraint | Why It Exists |
|-----------------|---------------|
| `uq_ppt_session_guardian_device_fcm` (guardian_id, device_token_fcm) | **Prevents duplicate sessions per device.** If a parent reinstalls the app, the same FCM token should update the existing session, not create a second row. |
| `idx_ppt_sessions_guardian` (guardian_id) | **Primary lookup pattern.** Every page load resolves the parent's active child via `WHERE guardian_id = ?`. |
| `idx_ppt_sessions_active_student` (active_student_id) | **Reverse lookup.** When a student is deactivated, find all sessions pointing to that child and reset them. |
| `idx_ppt_sessions_is_active` (is_active) | **Cron cleanup.** The stale-session cleanup job queries `WHERE is_active = 0 AND last_active_at < ?`. |
| FK CASCADE on guardian_id | If a guardian is deleted from the school, all their sessions are auto-removed. |
| FK SET NULL on active_student_id | If a child is removed, sessions aren't broken — they just reset to null. |

---

## Table 2: `ppt_messages`

### Why This Table Exists

Parents and teachers need a **secure, auditable communication channel** within the portal — like an internal email system scoped to a specific child. This replaces informal WhatsApp/phone calls with a school-managed channel where:

1. **Every message is recorded** for accountability (teacher said X, parent said Y).
2. **Messages are scoped to a child** — if a parent has 3 children, the conversation about Child A's grades doesn't mix with Child B's attendance issue.
3. **Messages are searchable** (FULLTEXT index) for the parent to find old conversations.
4. **School can audit** parent-teacher communication if disputes arise.

Without this table, schools have no visibility into parent-teacher communication, and parents have no formal record of what was discussed.

**Volume:** High — many parents x teachers x children x messages over time.

---

### Fields

| # | Field | Type | Why It Exists / How It Is Used |
|---|-------|------|-------------------------------|
| 1 | `id` | INT UNSIGNED PK | Auto-increment primary key. INT is sufficient — even a large school with 5,000 parents, 200 teachers, 50 messages per pair per year = ~500K messages/year. INT handles 4.2 billion. |
| 2 | `guardian_id` | INT UNSIGNED, NOT NULL | **Identifies which parent is in this conversation.** References `std_guardians.id`. Used to scope all message queries to the logged-in parent — a parent can only see messages involving their own guardian_id. ON DELETE CASCADE: if guardian is removed, their messages are cleaned up. |
| 3 | `student_id` | INT UNSIGNED, NOT NULL | **The child this conversation is about.** A parent may message the same Math teacher about two different children — this field separates those conversations. When the parent views "Messages about Arjun," only messages with `student_id = Arjun's ID` are shown. ON DELETE CASCADE: if the student is removed, related messages are cleaned up. |
| 4 | `direction` | ENUM('Parent_to_Teacher', 'Teacher_to_Parent') | **Who initiated this specific message.** The conversation is two-way, but each individual message has a clear direction. Used for: (a) UI styling (left-align vs right-align like a chat), (b) analytics (are parents initiating more than teachers?), (c) filtering ("show me only messages I sent"). ENUM is more storage-efficient and query-safe than a boolean `is_from_parent`. |
| 5 | `sender_user_id` | INT UNSIGNED, NOT NULL | **The sys_users.id of whoever sent this message.** Could be the parent's user account or the teacher's user account. Needed because `guardian_id` alone doesn't tell you which user account sent it (a guardian record links to a user account, but the FK relationship goes guardian → user, not message → guardian → user). Direct FK to `sys_users` makes sender resolution a single join. ON DELETE RESTRICT: cannot delete a user who has sent messages (audit trail protection). |
| 6 | `recipient_user_id` | INT UNSIGNED, NOT NULL | **The sys_users.id of the intended recipient.** Used to: (a) deliver in-app notification to the right person, (b) mark messages as unread for the recipient, (c) query "inbox" for a teacher — `WHERE recipient_user_id = teacher.id`. ON DELETE RESTRICT: same audit trail protection as sender. |
| 7 | `thread_id` | VARCHAR(64), NOT NULL | **Groups messages into a conversation thread.** Computed as `MD5(guardian_id + '_' + teacher_user_id + '_' + student_id)`. This creates a deterministic, unique thread identifier for each parent-teacher-child combination. Used to: (a) display messages as a conversation thread (chronologically ordered within same thread_id), (b) count unread messages per thread for badge display. VARCHAR(64) because MD5 produces a 32-character hex string — extra space for future hash algorithm changes. **Why MD5 and not a separate threads table?** Simplicity — no need to manage thread lifecycle. The thread "exists" as long as messages with that thread_id exist. |
| 8 | `subject` | VARCHAR(200), NOT NULL | **The subject line of the message.** Like an email subject — "Regarding Arjun's Math homework on 14-Apr." Used for: (a) displaying in message list without loading the full body, (b) FULLTEXT search (parents can search by subject keyword). 200 characters is sufficient for a descriptive subject without allowing abuse. |
| 9 | `message_body` | TEXT, NOT NULL | **The actual message content.** Stored as TEXT (up to 65KB) to allow detailed communication. This is where the parent writes their concern or the teacher provides feedback. Included in the FULLTEXT index for search capability. |
| 10 | `attachment_media_ids_json` | JSON, NULL | **References to attached files (report cards, homework photos, medical notes).** Stores an array of `sys_media.id` values like `[142, 143, 145]`. **Why JSON array instead of a junction table?** Because: (a) attachments are always loaded with the message (never queried independently), (b) a message rarely has more than 2-3 files, (c) avoids an extra join on every message load. The actual files are stored in Spatie MediaLibrary (`sys_media` table) — this field only stores the IDs. **Nullable** because most messages have no attachments. |
| 11 | `read_at` | TIMESTAMP, NULL | **When the recipient opened/viewed this message.** `NULL` means unread. This powers: (a) unread message count badges in the UI, (b) read receipts ("Seen at 3:45 PM"), (c) analytics on teacher responsiveness. Set once when the recipient first views the message — never reset to null. |
| 12 | `is_active` | TINYINT(1), DEFAULT 1 | **Standard platform active flag.** `0` = message hidden from UI but preserved in DB for audit. Different from `deleted_at` — `is_active=0` hides immediately, `deleted_at` is the soft-delete timestamp for the model's SoftDeletes trait. |
| 13 | `created_by` | BIGINT UNSIGNED, NULL | **Platform audit standard.** Same as sender_user_id in most cases, but kept separate because `created_by` is a platform-wide convention that middleware auto-populates, while `sender_user_id` is business logic. |
| 14 | `created_at` | TIMESTAMP | **When the message was sent.** Used for chronological ordering within a thread. |
| 15 | `updated_at` | TIMESTAMP | **Last modification time.** Typically only changes when `read_at` is set. |
| 16 | `deleted_at` | TIMESTAMP, NULL | **Soft-delete support.** A parent can "delete" a message from their view (it's hidden but preserved). Required for audit — schools may need to review deleted messages in dispute resolution. Teachers can also soft-delete inappropriate messages. |

### Key Indexes & Constraints

| Index/Constraint | Why It Exists |
|-----------------|---------------|
| `idx_ppt_messages_thread` (thread_id, created_at) | **Core query pattern.** Loading a conversation thread: `WHERE thread_id = ? ORDER BY created_at`. Composite index covers both filter and sort. |
| `idx_ppt_messages_guardian` (guardian_id) | **Parent inbox query.** `WHERE guardian_id = ? AND deleted_at IS NULL` to list all parent's conversations. |
| `idx_ppt_messages_student` (student_id) | **Child-scoped query.** When parent switches active child, reload messages for that child only. |
| `idx_ppt_messages_sender` (sender_user_id) | **Teacher inbox query.** A teacher loads their inbox: `WHERE recipient_user_id = ? OR sender_user_id = ?`. |
| `ft_ppt_messages_search` (subject, message_body) | **Full-text search** (FR-PPT-04). Parents can search across all their messages: `WHERE MATCH(subject, message_body) AGAINST('homework' IN BOOLEAN MODE)`. |
| FK RESTRICT on sender/recipient | **Prevents deleting users who have message history.** This is intentional — you cannot delete a teacher's account while their messages exist. Admin must soft-delete the user or reassign messages first. |

---

## Table 3: `ppt_leave_applications`

### Why This Table Exists

Parents need to **formally request leave** for their child through the portal — replacing paper leave letters. This creates:

1. **A trackable workflow** — Pending → Approved/Rejected → Withdrawn, with reviewer accountability.
2. **A permanent record** — for attendance reconciliation (absent days matched against approved leave).
3. **A communication channel** — reviewer can provide rejection reasons.

**Why not use the student's own leave system?** Because the StudentPortal has its own `LeaveApplication` model (from StudentProfile module) where the student applies for themselves. This table is specifically for **parent-submitted** leave on behalf of younger children who don't have their own portal login. The two systems are separate because approval workflows differ (student leave goes to class teacher, parent leave may go to a different approver).

**Volume:** Medium — 10–50 per student per year.

---

### Fields

| # | Field | Type | Why It Exists / How It Is Used |
|---|-------|------|-------------------------------|
| 1 | `id` | INT UNSIGNED PK | Auto-increment primary key. Low volume per tenant — INT is more than sufficient. |
| 2 | `application_number` | VARCHAR(30), UNIQUE, NOT NULL | **Human-readable reference number** in format `PPT-LV-2026-00000001`. Used in: (a) all UI displays — parents reference this number when calling the school, (b) printed acknowledgment, (c) search by application number. The format embeds the year for easy annual filtering. Auto-generated by the service layer using a DB sequence counter with locking to prevent duplicates. UNIQUE constraint enforces no two applications share the same number. |
| 3 | `student_id` | INT UNSIGNED, NOT NULL | **Which child this leave is for.** A parent with 3 children may submit separate leave applications for each. This scopes the leave to the correct child's attendance record. When leave is approved, the attendance module can mark these dates as "On Leave" for this specific student. ON DELETE CASCADE: if student is removed, their leave records are cleaned up. |
| 4 | `guardian_id` | INT UNSIGNED, NOT NULL | **Which parent submitted this application.** Required because: (a) a child may have multiple guardians (father, mother, legal guardian) — each can submit independently, (b) the reviewer knows who to contact if clarification is needed, (c) scoping queries to the logged-in parent's applications only. ON DELETE CASCADE. |
| 5 | `from_date` | DATE, NOT NULL | **First day of absence.** Must be ≥ today (enforced by FormRequest validation — you cannot apply for past-date leave through the portal). DATE type (not DATETIME) because leave is measured in whole days. Combined with `to_date` to calculate `number_of_days`. |
| 6 | `to_date` | DATE, NOT NULL | **Last day of absence.** Must be ≥ `from_date` (validated in FormRequest). For a single-day leave, `from_date = to_date`. The inclusive range `[from_date, to_date]` defines the absence period. |
| 7 | `number_of_days` | TINYINT UNSIGNED, NOT NULL | **Pre-computed count of leave days, excluding school holidays.** Computed by the LeaveService at submission time — it checks the school's holiday calendar and counts only working days within the date range. **Why store instead of compute on-the-fly?** Because: (a) the holiday calendar may change after submission — the approved day count should reflect what was approved, not recalculate, (b) reporting/dashboards need fast aggregation without re-joining the holiday table. TINYINT (0-255) is sufficient — no leave application spans 255+ working days. |
| 8 | `leave_type` | ENUM('Sick','Family','Personal','Festival','Medical','Other') | **Categorises the reason for leave.** Used for: (a) analytics — how many sick days vs personal days across the school, (b) different approval rules — some schools auto-approve 1-day sick leave but require manual approval for 3+ days, (c) government reporting — CBSE/state boards may require attendance breakdowns by leave type. ENUM enforces data integrity — no free-text categories that lead to inconsistency ("Sick" vs "sick" vs "Medical Leave"). |
| 9 | `reason` | TEXT, NOT NULL | **Detailed explanation for the leave.** Required field — parent must explain why the child will be absent. Minimum 20 characters enforced by FormRequest to prevent one-word reasons like "sick." TEXT allows detailed medical explanations or family event descriptions. The reviewer reads this to make an approval decision. |
| 10 | `supporting_doc_media_id` | INT UNSIGNED, NULL | **Optional attachment — medical certificate, travel ticket, event invitation.** References `sys_media.id` (Spatie MediaLibrary). For sick leave > 3 days, schools often require a doctor's certificate — this field links to the uploaded document. **Nullable** because not all leave types require documentation. ON DELETE SET NULL: if the media file is purged, the leave application isn't broken — it just loses the attachment reference. |
| 11 | `status` | ENUM('Pending','Approved','Rejected','Withdrawn') | **Workflow state of the application.** State machine: `Pending` (just submitted) → `Approved` or `Rejected` (by reviewer) → `Withdrawn` (by parent, only from Pending state). The UI shows different tabs for each status. Only `Pending` applications can be withdrawn by the parent. Only `Pending` applications can be approved/rejected by the reviewer. This prevents race conditions (parent withdraws while teacher approves simultaneously). |
| 12 | `reviewed_by_user_id` | INT UNSIGNED, NULL | **Which teacher/admin approved or rejected this application.** References `sys_users.id`. **Nullable** because newly submitted (Pending) and Withdrawn applications have no reviewer. Set when the reviewer clicks Approve/Reject. Accountability trail — parents can see WHO made the decision. ON DELETE SET NULL: if the reviewer's account is deleted, the leave record isn't broken — the name can be reconstructed from audit logs. |
| 13 | `reviewed_at` | TIMESTAMP, NULL | **When the approval/rejection decision was made.** Enables SLA tracking — "average time to review leave applications." Also displayed to the parent: "Reviewed on 15 Apr 2026 at 2:30 PM by Mrs. Sharma." **Nullable** for unreviewed applications. |
| 14 | `reviewer_notes` | TEXT, NULL | **Feedback from the reviewer — especially rejection reasons.** "Rejected because final exams are scheduled during this period. Please reschedule." Displayed to the parent so they understand the decision. **Nullable** — approvals may not need notes; rejections should always have notes (enforced by the admin UI, not the DDL). |
| 15 | `is_active` | TINYINT(1), DEFAULT 1 | **Standard platform active flag.** Rarely set to 0 — mostly used if an admin needs to hide a duplicate/spam application without deleting it. |
| 16 | `created_by` | BIGINT UNSIGNED, NULL | **Platform audit standard.** The parent's `sys_users.id`. |
| 17 | `created_at` | TIMESTAMP | **When the application was submitted.** |
| 18 | `updated_at` | TIMESTAMP | **Last modification time.** Changes when status updates. |
| 19 | `deleted_at` | TIMESTAMP, NULL | **Soft-delete support.** Parents can "withdraw" (status change) but admins can also soft-delete problematic records. Soft-deleted applications are excluded from all queries but preserved for audit. |

### Key Indexes & Constraints

| Index/Constraint | Why It Exists |
|-----------------|---------------|
| `uq_ppt_leave_app_number` (application_number) | **Business rule: no duplicate application numbers.** The auto-generator uses `SELECT ... FOR UPDATE` to get the next sequence value, but this UNIQUE constraint is the safety net. |
| `idx_ppt_leave_student_status` (student_id, status) | **Primary query pattern.** The parent dashboard shows: "Arjun has 5 leave applications (2 pending)." Query: `WHERE student_id = ? AND status = 'Pending'`. Composite index covers both filter conditions. |
| `idx_ppt_leave_guardian` (guardian_id) | **Parent-scoped listing.** `WHERE guardian_id = ?` to show the parent's own applications across all children. |
| `idx_ppt_leave_status` (status) | **Admin reporting.** School admin queries: `WHERE status = 'Pending'` to see all unreviewed applications across all students. |

---

## Table 4: `ppt_event_rsvps`

### Why This Table Exists

Schools organise events — Annual Day, Sports Day, Science Fair, PTA meetings — and need to know **which parents are coming** for logistics planning (seating, food, security passes). Parents also need a way to **volunteer** for event roles (registration desk, food stall, photography).

This table captures the parent's response (Attending / Not Attending / Maybe) and volunteer sign-up in a single record per guardian per event.

**Why not use the EventEngine module's own RSVP table?** Because the EventEngine is a generic cross-module system. The ParentPortal needs **parent-specific** fields (guardian_id, student_id context, volunteer role from the parent's perspective) and **parent-specific business rules** (one RSVP per guardian per event, not per user).

**Volume:** Medium — number of events x number of guardians.

### Why No `deleted_at`?

RSVPs are **not deleted, they are updated**. If a parent changes their mind, `rsvp_status` changes from `'Attending'` to `'Not_Attending'`. Soft-delete would create ambiguity — does "deleted RSVP" mean "not attending" or "never responded"? The explicit ENUM status is clearer. A parent who has never responded simply has no row in this table.

---

### Fields

| # | Field | Type | Why It Exists / How It Is Used |
|---|-------|------|-------------------------------|
| 1 | `id` | INT UNSIGNED PK | Auto-increment primary key. |
| 2 | `event_id` | INT UNSIGNED, NOT NULL | **Which school event this RSVP is for.** References the Event Engine's event record (or a `ppt_events` table if ParentPortal manages its own events). The school creates events like "Annual Day 2026" and this field links the parent's response to that specific event. **No FK constraint defined in DDL** — because the event table may be in a different module (EventEngine) and cross-module FKs are avoided in this architecture to allow independent module deployment. |
| 3 | `guardian_id` | INT UNSIGNED, NOT NULL | **Which parent is responding.** Combined with `event_id` in a UNIQUE constraint to enforce **one RSVP per guardian per event** (BR-PPT-016). If both parents want to attend, each submits their own RSVP (different guardian_id). ON DELETE CASCADE: if guardian is removed, their RSVPs are cleaned up. |
| 4 | `student_id` | INT UNSIGNED, NULL | **Child context for this RSVP.** Which child is the parent attending for? Important when: (a) a parent has 3 children but only one's class is performing, (b) the event is targeted at specific classes — the system verifies the child is in the target class before allowing RSVP. **Nullable** because some events are school-wide (not class-specific) and the student context is optional. ON DELETE SET NULL: if student is removed, the RSVP isn't broken. |
| 5 | `rsvp_status` | ENUM('Attending','Not_Attending','Maybe') | **The parent's attendance intention.** Three-state response: `Attending` (confirmed, counted for logistics), `Not_Attending` (explicit decline — different from "no response"), `Maybe` (tentative, counted separately for planning buffer). Defaults to `'Attending'` because the most common flow is: parent opens RSVP form → clicks "I'll attend" → saves. The school's logistics team uses the count of `Attending` RSVPs to plan seating/food. |
| 6 | `is_volunteer` | TINYINT(1), DEFAULT 0 | **Whether this parent has signed up to help at the event.** `1` = yes, `0` = no. Volunteer sign-up is optional and independent of attendance (though typically a volunteer is also attending). Used to generate the volunteer list for the event coordinator. |
| 7 | `volunteer_role` | VARCHAR(150), NULL | **Specific role the parent is volunteering for.** Examples: "Food stall coordinator," "Registration desk," "Photography," "First aid." The available roles are defined in the event's `volunteer_roles_json` field — this stores the parent's chosen role. **Nullable** because non-volunteers don't have a role, and even volunteers may not have a specific role assignment yet. The system checks role capacity — if "Food stall" has capacity 5 and 5 parents already signed up, the role is shown as full. |
| 8 | `rsvp_notes` | TEXT, NULL | **Free-text comment from the parent.** "Will arrive 30 mins late," "Bringing a friend — is that OK?," "My child has a food allergy — please arrange." Displayed to the event coordinator for planning. **Nullable** — most RSVPs don't include notes. |
| 9 | `confirmed_at` | TIMESTAMP, NULL | **When the parent's RSVP was finalised.** Different from `created_at` — a parent may submit "Maybe" initially (created_at = Day 1) and change to "Attending" later (confirmed_at = Day 5). This timestamp tracks the final confirmation. Used for reporting: "72 parents confirmed by the deadline." **Nullable** for "Maybe" responses that haven't been finalised. |
| 10 | `reminder_sent_at` | TIMESTAMP, NULL | **When the last RSVP reminder notification was sent.** The system may send reminders: "Annual Day is in 3 days — you haven't RSVP'd yet." This field prevents duplicate reminders — the cron job checks `WHERE reminder_sent_at IS NULL OR reminder_sent_at < DATE_SUB(NOW(), INTERVAL 3 DAY)`. **Nullable** for parents who have already responded (no reminder needed) or who haven't been reminded yet. |
| 11 | `is_active` | TINYINT(1), DEFAULT 1 | **Standard platform active flag.** `0` = RSVP hidden (admin action). Rarely used because RSVPs are updated in-place, not deactivated. |
| 12 | `created_by` | BIGINT UNSIGNED, NULL | **Platform audit standard.** |
| 13 | `created_at` | TIMESTAMP | **When the RSVP was first submitted.** |
| 14 | `updated_at` | TIMESTAMP | **Last modification.** Changes when parent updates their status or volunteer role. |

### Key Indexes & Constraints

| Index/Constraint | Why It Exists |
|-----------------|---------------|
| `uq_ppt_rsvp_event_guardian` (event_id, guardian_id) | **BR-PPT-016: One RSVP per guardian per event.** Prevents a parent from submitting multiple conflicting responses. If they want to change, they UPDATE the existing row. |
| `idx_ppt_rsvp_guardian` (guardian_id) | **"My RSVPs" query.** Parent views their RSVP history across all events. |
| `idx_ppt_rsvp_student` (student_id) | **Child-scoped event listing.** Show events relevant to the active child's class. |
| `idx_ppt_rsvp_event` (event_id) | **Event coordinator view.** Count RSVPs for a specific event: `WHERE event_id = ? AND rsvp_status = 'Attending'`. |

---

## Table 5: `ppt_document_requests`

### Why This Table Exists

Parents frequently need **official school documents** — Transfer Certificate (TC), Bonafide Certificate, Marksheets, etc. Traditionally, this requires visiting the school office, filling a paper form, and waiting days. This table digitalises the entire workflow:

1. **Parent submits request online** with document type, reason, and urgency.
2. **Admin processes it** — may require a fee (for duplicate certificates).
3. **Parent pays online** via Razorpay (if fee applies).
4. **Admin uploads the fulfilled document** → parent downloads it.

The workflow covers the full lifecycle: Pending → Processing → Ready → Completed (or Rejected).

**Volume:** Low-medium — 10–30 per student over their entire school lifetime.

---

### Fields

| # | Field | Type | Why It Exists / How It Is Used |
|---|-------|------|-------------------------------|
| 1 | `id` | INT UNSIGNED PK | Auto-increment primary key. Very low volume per tenant. |
| 2 | `request_number` | VARCHAR(30), UNIQUE, NOT NULL | **Human-readable reference number** in format `PPT-DR-2026-00000001`. Parents use this when calling the office: "I submitted document request PPT-DR-2026-00000042." The `DR` prefix distinguishes from leave applications (`LV`). Auto-generated with DB-level locking to prevent duplicates. |
| 3 | `student_id` | INT UNSIGNED, NOT NULL | **Which child this document is for.** A TC is issued for a specific student. The admin uses this to pull the student's records when preparing the document. ON DELETE CASCADE. |
| 4 | `guardian_id` | INT UNSIGNED, NOT NULL | **Which parent submitted the request.** Used for: (a) scoping the parent's "My Requests" page, (b) identifying who to notify when the document is ready, (c) identifying who to charge the fee to. ON DELETE CASCADE. |
| 5 | `document_type` | ENUM('TC','MarkSheet','Bonafide','Character','Migration','MedicalFitness','Other') | **What document is being requested.** Each type has different processing requirements: TC requires fee clearance check (no outstanding dues), Bonafide is usually free and quick, MedicalFitness needs medical records. The admin dashboard groups requests by type for batch processing. ENUM enforces consistency — 7 known types + 'Other' for edge cases. |
| 6 | `reason` | TEXT, NOT NULL | **Why the parent needs this document.** "Transferring to another school," "Required for passport application," "Duplicate — original lost in flood." Required field because: (a) it helps the admin prioritise, (b) for TC requests, it determines if the student should be marked as withdrawn, (c) regulatory requirement — some documents need a documented reason for issuance. |
| 7 | `urgency` | ENUM('Normal','Urgent') | **Processing priority.** `Normal` = processed in order (5-7 working days typical), `Urgent` = prioritised (1-2 days, may incur a higher fee). Used by the admin to sort their processing queue. Schools can set different fees for Normal vs Urgent in their configuration. Defaults to `'Normal'`. |
| 8 | `status` | ENUM('Pending','Processing','Ready','Completed','Rejected') | **Workflow state machine:** `Pending` (submitted, awaiting admin review) → `Processing` (admin accepted, working on it) → `Ready` (document prepared, awaiting download/fee payment) → `Completed` (parent downloaded the document). `Rejected` is a terminal state: "Cannot issue TC — outstanding fees of ₹15,000." Each transition triggers a notification to the parent. |
| 9 | `admin_notes` | TEXT, NULL | **Notes from the admin to the parent.** "Your TC will be ready by Friday," "Please clear outstanding fees before we can process TC," "Rejected because student has pending library books." Displayed in the request detail view. **Nullable** — not all status transitions need notes. |
| 10 | `fee_required` | DECIMAL(8,2), DEFAULT 0.00 | **How much the parent must pay for this document.** `0.00` = free (e.g., first-time Bonafide certificate). Non-zero = fee applies (e.g., ₹500 for duplicate TC). Set by admin based on school policy — not auto-calculated. DECIMAL(8,2) supports amounts up to ₹999,999.99 — more than enough for any document fee. The `fee_required > 0 AND fee_paid = 0` condition gates the download — parent must pay before downloading. |
| 11 | `fee_paid` | TINYINT(1), DEFAULT 0 | **Whether the fee has been paid.** `0` = not yet paid (or no fee required), `1` = payment confirmed. Set to `1` after Razorpay callback confirms successful payment. **Why a boolean instead of tracking the paid amount?** Because document fees are pay-in-full (no partial payments). The full payment amount and transaction details are tracked in the Payment module's `ptm_payments` table — this field is just a quick gate check. |
| 12 | `payment_reference` | VARCHAR(100), UNIQUE, NULL | **Razorpay payment ID** — e.g., `pay_LR1234abcdef`. Stored for: (a) idempotency — the UNIQUE constraint prevents the same Razorpay payment from being applied twice (BR-PPT-011), (b) reconciliation — admin can look up the payment in Razorpay dashboard using this reference, (c) refund processing — if the request is cancelled, the payment can be reversed using this ID. **Nullable** because: (a) free documents have no payment, (b) newly submitted requests haven't been paid yet. MySQL allows multiple NULL values in a UNIQUE column, so unpaid requests don't conflict. |
| 13 | `fulfilled_media_id` | INT UNSIGNED, NULL | **Link to the actual document file** uploaded by the admin. References `sys_media.id` (Spatie MediaLibrary). When the admin prepares the TC/certificate, they upload the PDF — this field links to that upload. The parent clicks "Download" → system checks `fee_paid = 1` → serves the file from this media record. **Nullable** until the admin fulfils the request. ON DELETE SET NULL: if the media is purged, the request record survives. |
| 14 | `fulfilled_at` | TIMESTAMP, NULL | **When the admin uploaded the document.** Enables SLA tracking: "Average fulfilment time for TC requests: 4.2 working days." Also displayed to the parent: "Document prepared on 18 Apr 2026." **Nullable** until fulfilment. |
| 15 | `is_active` | TINYINT(1), DEFAULT 1 | **Standard platform active flag.** |
| 16 | `created_by` | BIGINT UNSIGNED, NULL | **Platform audit standard.** |
| 17 | `created_at` | TIMESTAMP | **When the request was submitted.** |
| 18 | `updated_at` | TIMESTAMP | **Last modification.** Changes on status update, fee payment, or fulfilment. |
| 19 | `deleted_at` | TIMESTAMP, NULL | **Soft-delete.** Parents can "withdraw" a request (status change), and admins can soft-delete spam/duplicate requests. Preserved for audit. |

### Key Indexes & Constraints

| Index/Constraint | Why It Exists |
|-----------------|---------------|
| `uq_ppt_doc_request_number` (request_number) | **Business rule: unique request numbers.** |
| `uq_ppt_doc_payment_ref` (payment_reference) | **BR-PPT-011: Razorpay idempotency.** If a Razorpay webhook fires twice with the same payment_id, the second INSERT/UPDATE fails, preventing double-crediting. MySQL's UNIQUE on nullable columns allows multiple NULLs — unpaid requests don't conflict. |
| `idx_ppt_doc_student_status` (student_id, status) | **Primary query.** "Show Arjun's document requests that are Pending/Processing." |
| `idx_ppt_doc_guardian` (guardian_id) | **Parent-scoped listing.** "My Requests" page across all children. |
| `idx_ppt_doc_status` (status) | **Admin queue.** "Show all Pending requests across the school" for batch processing. |

---

## Table 6: `ppt_consent_form_responses`

### Why This Table Exists

Schools regularly need **formal parental consent** for activities — field trips, photo/video usage, medical procedures, sports participation, science lab chemicals, etc. Indian schools face increasing regulatory requirements (POCSO compliance, data privacy) that mandate documented consent.

This table stores the parent's response (Signed or Declined) with **legal-grade evidence**: the signer's name, IP address, and exact timestamp. These records are **immutable** — once a consent is recorded, it cannot be edited or deleted, providing a tamper-proof audit trail.

**The consent forms themselves** (title, content, deadline, target class) are stored in a separate table (`ppt_consent_forms`) — this table only stores the **responses**.

**Volume:** Low-medium — number of consent forms per year x students x responding guardians.

### Why No `deleted_at`?

**Legal requirement.** A consent form response is a legal record equivalent to a signed document. If a parent signed "Yes, my child can go on the field trip" and the response was later deleted, the school loses liability protection. Similarly, if a parent declined and that record was deleted, the school might inadvertently include the child. **This table MUST NEVER have `deleted_at` added** — even in future migrations.

---

### Fields

| # | Field | Type | Why It Exists / How It Is Used |
|---|-------|------|-------------------------------|
| 1 | `id` | INT UNSIGNED PK | Auto-increment primary key. |
| 2 | `consent_form_id` | INT UNSIGNED, NOT NULL | **Which consent form this response is for.** References the school's consent form record (from `ppt_consent_forms` or EventEngine). Combined with `student_id` and `guardian_id` in a UNIQUE constraint (BR-PPT-014) to prevent the same parent from signing the same form for the same child twice. **No FK constraint defined** — because the consent form table may be managed by a different module. Application-level validation ensures the form exists before allowing a response. |
| 3 | `student_id` | INT UNSIGNED, NOT NULL | **Which child this consent is for.** A parent with 3 children signs separately for each — the field trip consent for Child A is independent of Child B's. This prevents a parent from claiming "I signed for all my kids" when they only signed for one. ON DELETE CASCADE: if the student is removed from the school, their consent responses are cleaned up (the school no longer needs consent for a departed student). |
| 4 | `guardian_id` | INT UNSIGNED, NOT NULL | **Which parent/guardian signed.** Required because: (a) legal accountability — the school knows exactly which guardian gave consent, (b) in cases of separated parents, both may need to consent for sensitive activities (school policy), (c) for analytics — "Which guardians haven't responded yet?" ON DELETE CASCADE. |
| 5 | `response` | ENUM('Signed','Declined') | **The parent's decision.** Binary choice — there is no "Maybe" for consent. `Signed` = parent gives permission for the activity. `Declined` = parent explicitly refuses permission. **Why not a boolean?** Because ENUM is self-documenting in queries and reports. `WHERE response = 'Declined'` is clearer than `WHERE response = 0`. Note: a parent who hasn't responded at all simply has no row in this table — the absence of a row is the "No Response" state. |
| 6 | `decline_reason` | TEXT, NULL | **Explanation for declining.** Required when `response = 'Declined'` (enforced by FormRequest validation, not DB constraint). "My child has a medical condition that prevents participation," "Religious reasons — we don't celebrate this festival." Helps the school understand and accommodate. **Nullable** because signed responses don't need a reason. |
| 7 | `signer_name` | VARCHAR(150), NOT NULL | **The parent's typed full name — digital signature equivalent.** The parent types their name (e.g., "Rajesh Kumar Sharma") as an acknowledgment that they personally reviewed and responded to the form. This is NOT auto-filled from the user profile — the parent must actively type it, similar to typing your name on a DocuSign signature line. **Required** (NOT NULL) because an unnamed consent has no legal value. 150 characters accommodates long Indian names with titles. |
| 8 | `signed_ip` | VARCHAR(45), NULL | **The IP address of the device used to sign.** Recorded as forensic evidence — if a dispute arises ("I never signed that!"), the IP can be cross-referenced with the parent's known devices/network. VARCHAR(45) because IPv6 addresses can be up to 45 characters (e.g., `2001:0db8:85a3:0000:0000:8a2e:0370:7334`). **Nullable** as a fallback for edge cases where IP cannot be determined (proxied requests). |
| 9 | `signed_at` | TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP | **Exact moment the consent was given.** This is a **business timestamp**, NOT an alias for `created_at`. It records when the parent clicked "Sign" / "Decline" and is legally meaningful. Stored separately from `created_at` because: (a) the row could theoretically be created by a batch import at a different time than the actual signing, (b) `created_at` may be overwritten by framework operations, but `signed_at` must be immutable. **Immutable** — once set, this value MUST NEVER be updated. |
| 10 | `is_active` | TINYINT(1), DEFAULT 1 | **Standard platform active flag.** In practice, this should almost always be `1` because consent responses are immutable. Setting to `0` would only be used in extreme edge cases (e.g., court order to void a consent — even then, the row is preserved, just flagged). |
| 11 | `created_by` | BIGINT UNSIGNED, NULL | **Platform audit standard.** The parent's `sys_users.id`. |
| 12 | `created_at` | TIMESTAMP | **When the DB row was created.** May differ from `signed_at` in batch-import scenarios. |
| 13 | `updated_at` | TIMESTAMP | **Last modification.** In practice, this row should NEVER be updated after creation. The only legitimate update is `is_active` change (extreme edge case). If `updated_at != created_at`, it warrants an audit investigation. |

### Key Indexes & Constraints

| Index/Constraint | Why It Exists |
|-----------------|---------------|
| `uq_ppt_consent_response` (consent_form_id, student_id, guardian_id) | **BR-PPT-014: Prevents double-signing.** A parent cannot sign the same form for the same child twice. The application shows "Already signed" if a response exists. This is the most critical constraint in the table — double-signing could lead to conflicting consent records. |
| `idx_ppt_consent_student` (student_id) | **"Who hasn't signed?" query.** The school checks: which students in Class 5A are missing consent for the field trip? Query: LEFT JOIN students ON responses WHERE response IS NULL. |
| `idx_ppt_consent_guardian` (guardian_id) | **Parent's consent history.** "Show all consent forms I've signed/declined." |
| `idx_ppt_consent_form` (consent_form_id) | **Form-level aggregation.** "How many parents signed form #42?" Used for the compliance dashboard. |

---

## Cross-Table Design Decisions

### 1. All PKs are INT UNSIGNED (not BIGINT)

Per-tenant volume for ParentPortal is low-to-medium. INT UNSIGNED supports 4.2 billion rows — even a mega-school with 10,000 parents won't approach this. INT saves 4 bytes per row per index entry compared to BIGINT, which adds up across millions of rows and multiple indexes.

### 2. `created_by` is BIGINT UNSIGNED (exception)

This is a **platform-wide convention** — every table in every module uses BIGINT UNSIGNED for `created_by`. Even though `sys_users.id` is INT UNSIGNED, the architecture team mandated BIGINT for forward compatibility. This is intentional and should not be "fixed."

### 3. Three tables have NO `deleted_at`

| Table | Why No Soft-Delete |
|-------|-------------------|
| `ppt_parent_sessions` | Use `is_active=0` for logout; hard-delete stale sessions via cron. |
| `ppt_event_rsvps` | Update `rsvp_status` to change response; no concept of "deleted RSVP." |
| `ppt_consent_form_responses` | **Legally immutable.** Consent records cannot be deleted under any circumstance. |

### 4. No inter-ppt FK dependencies

All 6 tables are **Layer 1** — they reference external tables (`std_guardians`, `std_students`, `sys_users`, `sys_media`) but never reference each other. This means:
- Tables can be created in any order.
- Tables can be migrated independently.
- No cascading delete chains within the PPT module.

### 5. FK strategies by relationship type

| FK Target | ON DELETE | Rationale |
|-----------|----------|-----------|
| `std_guardians` | CASCADE | If guardian is removed from school, all their portal data is irrelevant. |
| `std_students` | CASCADE (on NOT NULL FKs) | If student leaves school, their portal data is cleaned up. |
| `std_students` | SET NULL (on nullable FKs) | Session's active child resets gracefully; RSVP preserves but loses child context. |
| `sys_users` | RESTRICT (messages) | Cannot delete a user who has message history — audit protection. |
| `sys_users` | SET NULL (leave reviewer) | If reviewer leaves school, leave record survives without the reviewer link. |
| `sys_media` | SET NULL | If media file is purged, parent record survives without the attachment link. |

---

**End of Document**
