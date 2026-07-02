# Module Knowledge — Notification (NTF)
**Last Updated:** 2026-06-30 | **Agent:** pa-business-analyst
**Source:** V2 Requirement (2026-03-26), live filesystem count (2026-06-30), Laravel code inspection

---

## Module Facts

| Property | Value |
|----------|-------|
| Module Name | Notification |
| Module Code | NTF |
| Table Prefix | `ntf_` |
| Module Type | Tenant (school-scoped, database-per-tenant) |
| Laravel Module Dir | `Modules/Notification/` |
| Route Prefix | `/notification/*` |
| Menu Path | Tenant Dashboard > Communication > Notifications |
| RBS Reference | Module Q — Communication & Messaging |
| FRD Status | Generated 2026-06-29 (`NTF_FRD_Complete_2026-06-29.md`) — confirmed written 2026-06-30 |
| Estimated Completion | ~45–50% (routes active but critical bugs block all dispatch) |

### Verified Counts (filesystem, 2026-06-30)

| Artifact | Count | Notes |
|----------|-------|-------|
| DDL Tables | 15 | `ntf_channel_master` through `ntf_schedule_audit` |
| Tenant Migrations (create) | 15 | `2026_06_16_111136` to `2026_06_16_111149` |
| Tenant Migrations (alter) | 4 | UUID fix, nullable columns, unique constraint |
| Controllers | 12 | Confirmed from filesystem |
| Models | 15 | Filesystem count; modules-map says 14 (one recent addition) |
| Services | 1 | `NotificationService.php` only; backup file appears deleted |
| FormRequests | 11 | Filesystem count; modules-map says 10 (ChannelMasterRequest may have been added) |
| Policies | 1 | `PrimeNotificationPolicy.php` — WRONG prefix (`prime.notification.*`) |
| Views (blade) | ~66 | Modules-map says 64; close (minor additions) |
| Route Lines | ~104 | In `Modules/Notification/routes/web.php` (fully populated) |
| Events | 1 | `SystemNotificationTriggered.php` |
| Listeners | 1 | `ProcessSystemNotification.php` (ShouldQueue, tries=3) |
| Laravel Notifications | 1 | `InAppSystemNotification.php` (working) |
| Facades | 2 | `Notification.php`, `NotificationDispatcher.php` |
| Seeders | 5 | Channel, Provider, TargetGroups, Templates, DatabaseSeeder |
| Jobs | 0 | `ProcessNotificationJob` does NOT exist — critical gap |
| Tests | 0 | Only `.gitkeep` in `tests/Feature/` and `tests/Unit/` |

---

## DDL Table Inventory

All 15 tables reside in `tenant_db`. Table prefix: `ntf_`.

| # | Table | Purpose |
|---|-------|---------|
| 1 | `ntf_channel_master` | Delivery channels (EMAIL/SMS/WHATSAPP/IN_APP/PUSH), rate limits, fallback |
| 2 | `ntf_provider_master` | External gateway credentials (MSG91, Twilio, SES, FCM) |
| 3 | `ntf_notifications` | Notification header record; event-driven or manual; status FSM |
| 4 | `ntf_notification_channels` | Per-notification channel assignment (junction) |
| 5 | `ntf_target_groups` | Named recipient groups — STATIC or DYNAMIC |
| 6 | `ntf_notification_targets` | Target definitions per notification (CLASS/SECTION/GROUP/INDIVIDUAL) |
| 7 | `ntf_user_devices` | FCM/APNS device tokens for push notifications |
| 8 | `ntf_user_preferences` | Per-user per-channel preferences, quiet hours, opt-in/out |
| 9 | `ntf_templates` | Message templates with `{{placeholder}}` syntax, versioned, approval-gated |
| 10 | `ntf_resolved_recipients` | Final resolved (user × channel) rows ready for delivery |
| 11 | `ntf_delivery_queue` | Delivery work queue with worker locking (`locked_by`/`locked_at`) |
| 12 | `ntf_delivery_logs` | Append-only delivery audit trail; per-stage timestamps |
| 13 | `ntf_notification_threads` | Thread grouping: CONVERSATION / DIGEST / BROADCAST |
| 14 | `ntf_notification_thread_members` | Thread-notification association (junction) |
| 15 | `ntf_schedule_audit` | Scheduled/recurring execution history |

**Key DDL Notes:**
- `tenant_id` column exists on most NTF tables — redundant in a database-per-tenant architecture; tagged for V3 cleanup
- FKs reference `sys_user` (singular) in some places; project convention is `sys_users` (plural) — migration needed
- `ntf_user_devices` missing `deleted_at` — cannot soft-delete stale device records
- `ntf_notifications` has `notification_uuid CHAR(36)` as public-facing route key
- `ntf_notifications.estimated_cost` and `actual_cost` columns exist (V1 screen spec requirement for cost preview)
- Unique constraint added to `ntf_channel_master` on 2026-06-24

---

## Feature Implementation Status

| Feature | Status | Evidence |
|---------|--------|----------|
| Channel Master Configuration | Partial | Controller + views exist; Gate prefix broken |
| Provider Master (gateway config) | Partial | Exists; no `encrypted` cast on credentials |
| Notification Templates | Partial | Routes ACTIVE in module web.php; was commented out in old tenant.php |
| Notification Create/Manage | Partial | Controller exists; uses `$request->field` not `$request->validated()` |
| Target Groups | Partial | Schema + controller + views; dynamic resolution not implemented |
| Event-Driven Dispatch | Partial | Event + listener exist; `ProcessNotificationJob::dispatch()` commented out (line 579) |
| Email Delivery | Partial | `sendEmail()` call is ACTIVE in current code (line 77) |
| In-App Delivery | Working | Via `InAppSystemNotification`; confirmed active |
| SMS Delivery | Not Started | Stub/default branch only |
| WhatsApp Delivery | Not Started | Not implemented |
| Push (FCM) Delivery | Not Started | Device model exists; dispatch stubbed |
| Delivery Queue Management | Partial | Schema + controller; no `ProcessNotificationJob` |
| Delivery Logs | Partial | Schema + model; service does not write to it |
| User Notification Preferences | Partial | Schema + controller + FormRequest + routes |
| User Device Registry (FCM) | Partial | Model exists; no dedicated API controller |
| Notification Threads | Partial | Schema + controller; functional in isolation |
| Schedule Audit | Partial | Schema + controller + views + routes NOW present |
| Recipient Resolution | Not Started | `RecipientResolutionService` does not exist |
| Notification Inbox (Bell) | Not Started | No dedicated inbox views |
| Recurring/Scheduled Command | Not Started | No `notifications:process-due` artisan command |
| DLT Template Registration | Not Started | `dlt_template_id` column — needs migration |
| Rate Limiting Enforcement | Not Started | Schema has columns; code does not enforce |
| Tests | Not Started | Zero tests |

---

## Known Gaps & Open Issues

### P0 — Critical Blockers (must fix before production use)

| Bug ID | Location | Description |
|--------|----------|-------------|
| BUG-NTF-003 | All 12 controllers | Gate prefix `prime.notification.*` / `prime.channel-master.*` instead of `tenant.notification.*` — all authorization checks fail for tenant users |
| BUG-NTF-004 | NotificationManageController.php:274, 371 | `store()`/`update()` use `$request->field` not `$request->validated()` — FormRequest validation bypassed |
| BUG-NTF-005 | NotificationManageController.php:579 | `ProcessNotificationJob::dispatch($notification)` commented out — notifications never actually processed from UI |
| BUG-NTF-011 | Notification.php model | `canBeProcessed()` method missing — controller calls it at line 562; PHP fatal error on process() |
| ARCH-01 | Missing file | `ProcessNotificationJob` does not exist — the entire delivery pipeline has no execution vehicle |

### P1 — Fix Before Beta

| Bug ID | Location | Description |
|--------|----------|-------------|
| BUG-NTF-007 | NotificationManageController.php:228, 337 | No Gate auth on `create()` and `edit()` methods — any authenticated user can access |
| BUG-NTF-009 | Notification.php:92 | `getRouteKeyName()` returns `notification_uuid` but controllers use `findOrFail($id)` with integer ID — route model binding conflict |
| BUG-NTF-010 | Notification.php:154, 178 | `resolvedRecipients()` and `logs()` relationships commented out |
| ARCH-02 | Missing service | `RecipientResolutionService` does not exist — target resolution (CLASS→individual students) cannot happen |
| ARCH-03 | Missing feature | Notification inbox (bell widget + inbox view) — no dedicated views or API endpoints |
| ARCH-04 | Missing command | `notifications:process-due` artisan command — scheduled/recurring notifications never fire |
| SEC-01 | ProviderMaster.php | Provider credentials (`api_key_encrypted`, `api_secret_encrypted`) in `$fillable` but no `encrypted` cast — stored as plaintext |

### P2 — Fix Before GA

| ID | Description |
|----|-------------|
| IMPL-01 | SMS dispatch — only `switch/default` stub; no provider adapter |
| IMPL-02 | Push (FCM) dispatch — device tokens exist; dispatch not implemented |
| IMPL-03 | WhatsApp dispatch — not implemented |
| IMPL-04 | Delivery logging — `NotificationService::dispatchToChannel()` never writes to `ntf_delivery_logs` |
| DDL-01 | `dlt_template_id VARCHAR(50)` column missing from `ntf_templates` — India SMS DLT compliance blocked |
| DDL-02 | `deleted_at` missing from `ntf_user_devices` — cannot soft-delete stale device records |
| DDL-03 | FK `sys_user` should be `sys_users` in `ntf_user_devices` and `ntf_resolved_recipients` |
| PERF-01 | `NotificationManageController::index()` god-method loads 8+ queries — refactor to tabbed AJAX |

---

## Design Decisions Made

| Decision | Detail |
|----------|--------|
| Event-driven architecture | Any module fires `SystemNotificationTriggered::dispatch($eventCode, $context)` — NTF is the consumer |
| Database-per-tenant | No cross-tenant notification leakage; `tenant_id` column redundant per D-architecture |
| Template versioning | Unique constraint `(tenant_id, template_code, template_version)` — highest approved version wins at dispatch |
| Worker locking | `locked_by`/`locked_at` in `ntf_delivery_queue` supports horizontal scaling without duplicate delivery |
| Opt-out is absolute | `is_opted_in = 0` always wins — even system notifications respect opt-out (except OTP/security) |
| Delivery log immutability | `ntf_delivery_logs` is append-only — no DELETE or UPDATE endpoints |
| Batch ID grouping | `batch_id` UUID groups bulk recipients for efficient parallel worker processing |
| DLT compliance | SMS templates require TRAI `dlt_template_id` for Indian tenants — enforced at dispatch time |
| Template render | `{{key}}` and `{{ key }}` forms both supported by `NotificationTemplate::render()` |
| Status backed by `sys_dropdown_table` | Per D29 — status values are config-driven, not hardcoded ENUMs in business logic |

---

## Cross-Module Dependencies

### NTF Depends On (Inbound)

| Source | Data/Service | Why |
|--------|-------------|-----|
| `sys_dropdown_table` | Priority, status, notification type, target type | Config-driven values |
| `sys_users` | User resolution for recipient targeting | Expand CLASS/SECTION/GROUP targets to individuals |
| `sys_media` | Template attachments via `ntf_templates.media_id` | Email attachments |
| `sys_settings` | Data retention policy, quiet hours defaults | NFR compliance |
| Laravel Queue | `ShouldQueue` for all dispatch | Async processing |
| Laravel Mail | Email delivery transport | REQ-NTF-021 |
| Firebase FCM | Push notification delivery | REQ-NTF-024 |
| MSG91 / Twilio | SMS delivery + DLT template ID | REQ-NTF-023 |
| Meta WhatsApp Business API | WhatsApp delivery | REQ-NTF-025 |

### Modules That Fire Events (NTF is Downstream Consumer)

| Module | Event Codes |
|--------|-------------|
| StudentFee (FIN) | `FEE_DUE_REMINDER`, `PAYMENT_RECEIVED`, `FEE_RECEIPT_GENERATED` |
| LmsExam (EXM) | `EXAM_RESULT_PUBLISHED`, `EXAM_SCHEDULED`, `EXAM_REMINDER` |
| LmsHomework (HMW) | `HOMEWORK_ASSIGNED`, `HOMEWORK_DUE_REMINDER`, `HOMEWORK_GRADED` |
| Attendance (ATT) | `ATTENDANCE_MARKED_ABSENT`, `ATTENDANCE_DAILY_SUMMARY` |
| Admission (ADM) | `STUDENT_ADMITTED`, `ADMISSION_APPLICATION_RECEIVED` |
| Library (LIB) | `BOOK_OVERDUE`, `BOOK_RETURN_REMINDER` |
| Transport (TPT) | `VEHICLE_ARRIVAL_ALERT`, `ROUTE_CHANGED` |
| Communication (COM) | `CIRCULAR_PUBLISHED`, `ANNOUNCEMENT_POSTED` |
| StudentProfile (STD) | `STUDENT_PROFILE_UPDATED`, `ID_CARD_GENERATED` |
| System (SYS) | `PASSWORD_RESET`, `OTP_VERIFICATION`, `LOGIN_ALERT` |

### NTF Feeds Into (Outbound)

| Target | Mechanism | What |
|--------|-----------|------|
| All modules | `SystemNotificationTriggered` event API | Delivery status and inbox for all modules' users |
| Communication module (COM) | Underlying delivery engine | COM fires events; NTF dispatches |
| Dashboard (DSH) | Unread count via AJAX | Notification bell counter |

---

## Lessons Learned

- [2026-06-30 | pa-business-analyst] NTF: The modules-map stated routes were "COMMENTED OUT" (SEC-NTF-006 in known-bugs). This is now stale — the route migration (2026-04-02) moved all routes into `Modules/Notification/routes/web.php`, which is fully populated. The old tenant.php comment issue no longer applies.
- [2026-06-30 | pa-business-analyst] NTF: BUG-NTF-006 (sendEmail commented out) appears fixed in current code — `sendEmail()` call at line 77 is active. The V2 req doc (2026-03-26) documented it as broken; it was fixed between then and now.
- [2026-06-30 | pa-business-analyst] NTF: The Schedule Audit controller and routes are now present (ScheduleAuditController.php exists, `Route::resource('schedule-audit')` in web.php). V2 doc marked it as "Missing" — this is now partial (views exist at `schedule-audit/_form`, `create`, `edit`, `index`, `show`).
- [2026-06-30 | pa-business-analyst] NTF: The single largest blocking gap is the absence of `ProcessNotificationJob` — without this, the delivery pipeline cannot run even after fixing the dispatch comment. This is the #1 build priority.
- [2026-06-30 | pa-business-analyst] NTF: `canBeProcessed()` method is missing from the `Notification` model, but it is called in `NotificationManageController::process()`. This would cause a PHP fatal error at runtime and should be fixed before any testing.

---

## Pending Next Steps

1. **Technical Auditor:** Full 12-layer audit against the FRD (REQ-NTF-018 through REQ-NTF-026 are the highest-risk gap cluster — dispatch pipeline)
2. **DB Architect:** Migration to add `dlt_template_id` to `ntf_templates`, `deleted_at` to `ntf_user_devices`, fix FK naming
3. **Developer (P0 Sprint):** Fix Gate prefix (global find-replace `prime.*` → `tenant.*`), add `canBeProcessed()` to Notification model, uncomment `ProcessNotificationJob::dispatch()`, add `encrypted` cast to ProviderMaster
4. **Developer (P1 Sprint):** Create `ProcessNotificationJob`, create `RecipientResolutionService`, build Notification Inbox UI
5. **Test Architect:** Design test suite (14+ test classes, 0 currently exist)
6. **Developer (P2 Sprint):** Implement SMS/Push/WhatsApp adapters, implement delivery logging, add `notifications:process-due` artisan command

---

## FRD Summary

| Property | Value |
|----------|-------|
| FRD File | `0-FRD_Documents/NTF_FRD_Complete_2026-06-29.md` |
| FRD Date | 2026-06-29 |
| Total REQs | 42 (P0: 24, P1: 17, P2: 1) — initial plan was 46; Thread Members merged into REQ-NTF-039 during authoring |
| Total BRs | 13 |
| Total RPTs | 4 |
| Total ENHs | 7 |
| Workflows Documented | 6 (Event Dispatch, Manual Compose, Template Approval, Opt-Out, DLT SMS, Scheduled/Recurring) |
| FSMs Documented | 4 (Notification Status, Template Approval, Delivery Queue, Delivery Log Stage) |
| User Stories | 12 (all P0 + key P1) |

---

## Version History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-06-30 | pa-business-analyst | Initial seed — counts verified against live filesystem; FRD generated |
