# Automation Core — End-to-End Implementation Plan

**Owner:** Tarun Chauhan · **Written:** 9 October 2026 · **Status:** PLAN, nothing built
**Companion files (this folder):** [AUTOMATION-CORE-REPORT.md](AUTOMATION-CORE-REPORT.md) (why one core) ·
[02-SCREEN-DESIGN.md](02-SCREEN-DESIGN.md) (every screen and user flow) · [03-FLOWCHARTS.md](03-FLOWCHARTS.md) (4 live examples step by step)
**DDL (pgdatabase):**
- `2-DDL_Tenant_Enhanced/Automation/Automation_Central_DDL_v1.sql`: `global_master` catalogue + `prime_db` Prime schedules (7 + 2 tables)
- `2-DDL_Tenant_Enhanced/Automation/Automation_DDL_v1.sql`: school DB, 11 `aut_*` tables + `sch_holidays.holiday_code` + 4 `sys_settings` rows
- `2-DDL_Tenant_Enhanced/Notification/Notification_DDL_v4.sql`: school DB, Notification v3 → v4 (16 tables: 1 new, 9 enhanced, 3 deprecated, 3 unchanged)

All three were run on throwaway databases on 9 Oct 2026 (MySQL 8.4): every statement succeeded, and 8 constraint
tests (CHECKs, run-once keys, idempotency, soft-delete-aware uniques) behaved as designed. Run order:
**Central → Automation (school) → Notification v4 (school)**. `ntf_notifications` references `aut_action_runs`.

---

## 1. Decisions this plan implements

| # | Decision | Taken |
|---|---|---|
| A1 | Developers register events + actions in code. Prime ships default rules. Schools wire rules from dropdowns; nobody types code or SQL. | 9 Oct |
| A2 | v1 actions: **notify**, **record.\*** (developer-written only), **follow_up**, **webhook** | 9 Oct |
| A4 | One core layer; the EventEngine and Scheduler modules become its screens | 9 Oct |
| A5 | Rules always run **queued, after commit** | 9 Oct |
| A6 | Schools may schedule **every minute** | 9 Oct |
| A7 | Existing engines (Accounting, Recommendation, BA, Laravel events, console schedules) move over **later, one by one** | 9 Oct |
| A8 | Order: **shared Phase 0 → core → Notification** | 9 Oct |
| B1 | Notification queue design = **shared queues + per-school lane cap** (OPTIMISED-DESIGN) | 9 Oct |
| B2 | **No `tenant_id` in school-DB tables**; the database is the isolation | 9 Oct |
| B3 | A school may **disable + tune** a Prime rule, never delete it or change its event / action; locked rules cannot be disabled | 9 Oct |
| B4 | **No approval** step for school-built rules or schedules | 9 Oct |
| B5 | Festivals come from the **school's own holidays** (`sch_holidays.holiday_code`), **no Prime calendar** (replaces report decision A3) | 9 Oct |
| B6 | **Per-school timezone**, default `Asia/Kolkata` (`sys_settings.school_timezone`); all stored times UTC | 9 Oct |
| B7 | Only the **School Admin** role manages rules, schedules, webhooks and channels | 9 Oct |
| B8 | Logs: **90 days detail**, then daily counts (`aut_daily_stats`) | 9 Oct |
| B9 | The old EventEngine `lms_*` models are **replaced** by `aut_*`; nothing to migrate (those tables never existed) | 9 Oct |
| — | Earlier and still valid: D9-D19 (isolation, Redis + Horizon, 4 tiers fixed by Prime, Prime-owned push, per-school WhatsApp, Reverb bell, fallback chain) | 9 Oct |

Because of B4 and A6, the safety guards in §8 (dry run, loop limit, auto-pause, lane cap) are the only brakes.
They are therefore part of the first rules phase (C2), not a later hardening phase.

---

## 2. Architecture

### 2.1 Where the code lives

| Layer | Location | Why there |
|---|---|---|
| **Engine** (bus, matcher, runners, scheduler maths, pump, registry) | `app/Automation/` | Must work even when a school has the EventEngine *screens* module switched off; every module calls `Automation::emit()`. `app/` is always loaded. |
| Module **events, actions, still-applies checks** | `Modules/<Module>/app/Automation/{Events,Actions,Checks}/` | The owning module knows its data; the engine stays ignorant of `fee_invoices` or `lib_members`. |
| **Notify** action + delivery pipeline | `Modules/Notification/app/{Automation,Delivery}/` | Notification owns channels, audiences, templates. |
| **Rule / event-log / webhook / follow-up screens** | `Modules/EventEngine` (re-pointed at `aut_*`) | Existing module, today disabled with dead `lms_*` models. |
| **Schedule screens** (school + Prime) | `Modules/Scheduler` (re-pointed at `aut_schedules` + `prm_schedules`) | Existing module; keeps its `JobRegistry` + `SchedulableJob` contract for Prime jobs. |

### 2.2 Engine classes (`app/Automation/`)

| Class | Responsibility |
|---|---|
| `Automation` (facade) | `emit($code, $subjectId, $ctx, $key = null)`, `cancelDue($cancelKey)`, `fireSchedule($id)` (Run now) |
| `Attributes\AutomationEvent`, `Attributes\AutomationAction`, `Attributes\StillAppliesCheck` | Declarations scanned by the registry |
| `Contracts\DescribesPayload`, `Contracts\AutomationAction`, `Contracts\StillApplies` | What a module implements |
| `Registry\RegistryScanner` | Finds every attributed class in `app/` + `Modules/*/app/Automation` |
| `Registry\SyncRegistryCommand` (`aut:sync-registry`, central) | Upserts `glb_aut_events / actions / compat`; marks removed ones `is_active = 0` |
| `Registry\SyncSchoolCommand` (`aut:sync-school {--school=}`) | Copies catalogue → school `aut_events / aut_actions / aut_rules(PRIME)`, `ntf_events`, system `ntf_templates`; respects `params_overridden` / `school_overridden` |
| `Bus\EventLogWriter` | Writes `aut_event_log` in the caller's transaction; computes the idempotency key; enforces depth ≤ 3; `DB::afterCommit` → `MatchRulesJob` |
| `Bus\MatchRulesJob` | Loads enabled rules for the event (cached per school), evaluates conditions, inserts `aut_action_runs` (`INSERT IGNORE` on the run-once key), dispatches `RunActionJob` per run |
| `Bus\ConditionEvaluator` | JSON conditions: `all` / `any`, ops `= != > >= < <= in not_in between is_null contains`; fields from `payload_schema_json` only |
| `Bus\RunActionJob` | Lane cap → resolves the handler → `handle(ActionContext)` → writes status, reason, result; maintains `consecutive_failures` and auto-pause |
| `Actions\FollowUpAction` (`follow_up`) | Writes `aut_due` (+ ZSET entry) |
| `Actions\WebhookAction` (`webhook`) | HTTPS-only, SSRF guard, HMAC signature, 10 s timeout, 3 retries |
| `Schedule\NextRunCalculator` | INTERVAL / CRON / ONCE / HOLIDAY → next UTC time in the school timezone; HOLIDAY reads `sch_holidays` |
| `Schedule\DueIndex` | Redis ZSET `aut:due` (`school:schedule:<id>`, `school:due:<id>`, `school:ntf:<id>`), add / remove / rebuild |
| `Schedule\PumpCommand` (`aut:pump`, every 15 s, one instance) | Pops due members, groups by school, `tenancy()->run($school)` → fires the schedule / due row / scheduled send; repairs expired leases |
| `Schedule\RebuildDueIndexCommand` (`aut:rebuild-due`, nightly + on demand) | Rebuilds the ZSET from every school's DB |
| `Maintenance\PruneCommand` (`aut:prune`, nightly) | Rolls detail older than `aut_log_retention_days` into `aut_daily_stats`, deletes it |
| `Support\LaneCap` | `Redis::funnel("lane:{school}:{queue}")` wrapper shared with Notification |

### 2.3 Queues (Horizon, Phase 0 config + these additions)

| Queue | Jobs | Lane cap per school |
|---|---|---|
| `aut-high` | `MatchRulesJob` / `RunActionJob` for RECORD events | 4 |
| `aut-bulk` | the same for TIME / SWEEP events (schedules, sweeps that emit many events) | 2 |
| `ntf-critical`, `ntf-high`, `ntf-bulk` | notification chunk jobs (B1) | none / 4 / 2 |
| `ntf-hooks`, `aut-hooks` | provider webhooks in; outgoing webhook action | 2 |

### 2.4 The developer contract (what a module writes)

```php
// Event (Modules/Admission/app/Automation/Events/StudentAdmitted.php)
#[AutomationEvent(code: 'STUDENT_ADMITTED', module: 'Admission', kind: 'RECORD',
                  subjectTable: 'std_students', queue: 'aut-high')]
final class StudentAdmitted implements DescribesPayload {
    public static function payload(): array {
        return ['student_id' => 'id:std_students', 'class_id' => 'id:sch_classes',
                'section_id' => 'id:sch_sections', 'is_hosteller' => 'bool',
                'admission_type' => 'enum:NEW,TRANSFER'];
    }
}

// Emit, inside the same transaction that saves the student
Automation::emit('STUDENT_ADMITTED', $student->id, [...]);

// Action (Modules/Library/app/Automation/Actions/CreateMember.php)
#[AutomationAction(code: 'record.library.create_member', module: 'Library', kind: 'RECORD',
                   compatibleEvents: ['STUDENT_ADMITTED', 'STAFF_JOINED'])]
final class CreateMember implements AutomationAction {
    public static function params(): array {
        return ['membership_type_code' => ['type' => 'lookup:lib_membership_types.code', 'required' => true]];
    }
    public function handle(ActionContext $ctx): ActionResult {   // idempotent: one member per user
        ...
    }
}

// Still-applies check (Modules/StudentProfile/app/Automation/Checks/DocumentsMissing.php)
#[StillAppliesCheck(code: 'std.documents_missing')]
final class DocumentsMissing implements StillApplies {
    public function stillApplies(array $subject, array $params): bool { ... }
}
```

Rules for every action: **idempotent** (re-running does nothing new), **ids in / ids out**, use the module's own
service (never raw table writes), return `done / skipped(reason) / failed(reason, retryable)`.

---

## 3. Database work

### 3.1 Laravel migrations to write (from the DDL files)

**Central (`database/migrations/` on the central / global connection):**

| # | Migration | Source |
|---|---|---|
| M-C1 | `create_glb_aut_events_table`, `..._actions`, `..._event_action_compat`, `..._rules`, `..._frequencies` (+ 12 seed rows) | Central DDL Part 1 |
| M-C2 | `create_glb_ntf_events_table`, `create_glb_ntf_templates_table` | Central DDL Part 1 |
| M-C3 | `create_prm_schedules_table`, `create_prm_schedule_runs_table` | Central DDL Part 2 |
| M-C4 | **Delete** `Modules/Scheduler/database/migrations/2026_01_02_*` (never ran; replaced by M-C3) | — |

**School (`database/migrations/tenant/`), in this order:**

| # | Migration | Notes |
|---|---|---|
| M-T1 | `create_aut_events_table`, `create_aut_actions_table` | |
| M-T2 | `create_aut_rules_table` | |
| M-T3 | `create_aut_schedules_table` | 2 CHECK constraints (no cascade on their FK columns, see DDL note) |
| M-T4 | `create_aut_event_log_table`, `create_aut_action_runs_table`, `create_aut_schedule_runs_table` | |
| M-T5 | `create_aut_due_table`, `create_aut_condition_state_table`, `create_aut_webhooks_table`, `create_aut_daily_stats_table` | |
| M-T6 | `add_holiday_code_to_sch_holidays` + dropdown key `sch_holidays.holiday_code` (14 values) | |
| M-T7 | `seed_automation_sys_settings` (4 keys, insert-if-missing) | |
| M-T8 | `drop_tenant_id_from_ntf_tables` (6 tables; drop the old tenant-scoped uniques first, re-add code-only soft-delete-aware uniques) | B2 |
| M-T9 | `create_ntf_events_table` | |
| M-T10 | `enhance_ntf_notifications_as_outbox`: add v4 columns; **backfill** `dedupe_base = CONCAT('LEGACY:', id)` and `audience_json = '{"type":"legacy"}'` **before** adding `uq_ntf_dedupe_base`; make `priority_id`, `confidentiality_level_id`, `notification_status_id`, `created_by` nullable | 3 seeded legacy rows exist |
| M-T11 | `enhance_ntf_resolved_recipients_state_machine`: **drop FKs from `ntf_delivery_logs` and `ntf_delivery_queue` first**, re-type `id` INT→BIGINT and the two child columns, then re-add FKs; add v4 columns; backfill `dedupe_key = CONCAT('LEGACY:', id)` | MySQL errno 3780 trap: parent and child types must match before an FK is re-added |
| M-T12 | `enhance_ntf_provider_master`, `enhance_ntf_templates`, `enhance_ntf_user_devices` (+ `device_token_hash`, drop old unique), `enhance_ntf_user_preferences` (+ event_code key), `enhance_ntf_delivery_logs` (nullable columns, BIGINT id) | |

Each migration is idempotent (`hasTable` / `hasColumn` guards), as the timetable snapshot migration is.
Remember the queue-worker trap: run `php artisan queue:restart` (Horizon: `horizon:terminate`) after migrating,
or the long-lived worker keeps old migration classes in memory.

### 3.2 Seed data

| Seeder | Writes |
|---|---|
| `AutomationFrequenciesSeeder` (central) | the 12 presets (also in the DDL) |
| `PrimeDefaultRulesSeeder` (central) | the Prime rules used by the 4 examples (§7) |
| `NotificationCatalogueSeeder` (central) | `glb_ntf_events` + `glb_ntf_templates` (en + hi) for the examples' message types |
| `HolidayCodeDropdownSeeder` (school) | 14 holiday codes |
| `aut:sync-school --all` | catalogue copies into every school (also run on school creation) |
| Registered in `SeederRegistry::sync()` | so they appear on `/seeder` (memory: a seeder shows only after sync) |

---

## 4. Permissions (naming standard `scope.module.feature.action`)

| Permission | Screens | Role |
|---|---|---|
| `tenant.event-engine.rule.{viewAny,view,create,update,delete,toggle,dry-run}` | AUT-01..03 | School Admin |
| `tenant.event-engine.event-log.{viewAny,view,retry}` | AUT-07 | School Admin |
| `tenant.event-engine.follow-up.{viewAny,cancel}` | AUT-09 | School Admin |
| `tenant.event-engine.webhook.{viewAny,create,update,delete,test}` | AUT-08 | School Admin |
| `tenant.event-engine.catalogue.{viewAny,toggle}` | AUT-10 | School Admin |
| `tenant.scheduler.schedule.{viewAny,view,create,update,delete,toggle,run-now}` | AUT-04..06 | School Admin |
| `tenant.notification.event.{viewAny,update,toggle}` | NTF-10 | School Admin |
| `tenant.notification.template.*` (exists) | NTF-11 | School Admin |
| `tenant.notification.channel.{viewAny,update,test}` | NTF-12 | School Admin |
| `tenant.notification.send.{viewAny,view,create,pause,cancel,retry}` | NTF-13..15 | School Admin |
| `tenant.notification.preference.self` | USR-01 | every logged-in user |
| `prime.scheduler.schedule.*`, `prime.event-engine.registry.viewAny`, `prime.event-engine.rule.*`, `prime.notification.catalogue.*`, `prime.automation.health.viewAny` | PRM-01..05 | Prime super admin |

Role grants go in `config/permission_role_defaults.php`. Grant migrations run before seeders and grant nothing
(memory: role-grant migrations are no-ops), so that file is the durable path.

---

## 5. Build phases

Each phase has its own go and ends with a **manual test script** for you, since you test by hand. Never more than one
phase in flight.

### Phase 0: Infrastructure (shared, already written)
[../notifications-requirements/PHASE-0-STEPS.md](../notifications-requirements/PHASE-0-STEPS.md), Steps 0-12, plus
queues `aut-high`, `aut-bulk`, `aut-hooks` in the Horizon supervisors.
**Exit:** isolation probes P1-P7 pass.

### Phase C1: Registry + event bus

| Task | Files |
|---|---|
| Central migrations M-C1, M-C2 | `database/migrations/*` |
| School migrations M-T1, M-T4 | `database/migrations/tenant/*` |
| Attributes, contracts, `RegistryScanner`, `aut:sync-registry`, `aut:sync-school` | `app/Automation/{Attributes,Contracts,Registry}` |
| `Automation::emit`, `EventLogWriter`, `MatchRulesJob` (no rules yet → `NO_RULES`) | `app/Automation/Bus` |
| One real event to prove it: `STUDENT_ADMITTED` emitted by the admission save | `Modules/Admission` or `StudentProfile` (whichever saves the student; verify at build time) |

**Manual test:**
1. `php artisan aut:sync-registry` → `glb_aut_events` has `STUDENT_ADMITTED`.
2. `php artisan aut:sync-school --school=<test>` → school `aut_events` has it.
3. Admit a student on test.localhost → one `aut_event_log` row, `status = NO_RULES`, `chain_id` set.
4. Save the same admission again (or retry) → still one row (idempotency key).
5. Make the save fail on purpose (a validation error after emit inside the transaction) → **no** log row (it rolls back with the save).

### Phase C2: Rules, conditions, safety, core actions

| Task | Files |
|---|---|
| School migration M-T2, M-T5 (due, webhooks, condition state, stats) | |
| `ConditionEvaluator`, `RunActionJob`, `LaneCap`, auto-pause, depth guard | `app/Automation/Bus`, `Support` |
| `follow_up` + `webhook` actions, `StillApplies` registry | `app/Automation/Actions` |
| EventEngine module re-pointed: models `AutRule`, `AutEventLog`, `AutActionRun`, `AutWebhook`, `AutDue`; screens AUT-00..03, AUT-07..10 | `Modules/EventEngine` (old `lms_*` models + views deleted) |
| Permissions + role defaults | `config/permission_role_defaults.php` |

**Manual test:**
1. Create a school rule: *STUDENT_ADMITTED → webhook to https://webhook.site/...*; admit a student → the POST arrives, signed; run row `DONE`.
2. Point the webhook at `http://127.0.0.1` → refused (SSRF guard), run `FAILED: private address`.
3. Break the URL 5 times → the rule shows **Auto-paused** with the reason.
4. Dry run on the rule → shows the last 20 admissions with "would fire / would not" and sends nothing.
5. Build a loop on purpose (a webhook test action that emits the same event) → stops at depth 3; event log shows `REFUSED`.

### Phase C3: Scheduler

| Task | Files |
|---|---|
| M-T3, M-T6, M-T7; central M-C3, M-C4 | |
| `NextRunCalculator` (INTERVAL / CRON / ONCE / HOLIDAY + timezone), `DueIndex`, `aut:pump`, `aut:rebuild-due` | `app/Automation/Schedule` |
| Scheduler module: school screens AUT-04..06; Prime screens PRM-04 on `prm_schedules`; `JobRegistry` kept | `Modules/Scheduler` |
| `sch_holidays` form gets the **Holiday code** dropdown | SchoolSetup holiday screen |
| `routes/console.php`: `aut:pump` every 15 s, `aut:rebuild-due` 02:30, `aut:prune` 03:15; the old `scheduler:run-dynamic` removed | |

**Manual test:**
1. School schedule *every 1 minute → emit ATTENDANCE_WEEKLY_SWEEP* (with no rule) → a run row every minute, status `DONE`, event log `NO_RULES`.
2. Stop Horizon for 3 minutes, start it → missed minutes are **not** replayed in a burst (one catch-up run, per the overlap policy); no duplicate `planned_at`.
3. Add a `sch_holidays` row *Diwali, code DIWALI, tomorrow* + schedule *HOLIDAY DIWALI 09:00* → `next_run_at` = tomorrow 03:30 UTC (09:00 IST).
4. Delete that holiday row → the schedule shows "waiting: no DIWALI date ahead".
5. `redis-cli DEL aut:due` then `php artisan aut:rebuild-due` → schedules fire again at their times.

### Phase C4: Notification v4 schema + in-app + `notify` action

| Task | Files |
|---|---|
| M-T8..M-T12, M-C2 data, `aut:sync-school` for `ntf_events` + templates | |
| `Notify::event()`, `AudienceResolver` (guardians_of_student, class_section, role, user, staff, reporting_manager, transport_stop, option_subgroup), chunk job, recipient state machine, in-app driver, Reverb bell | `Modules/Notification/app/Delivery` |
| `notify` action (`Modules/Notification/app/Automation/NotifyAction`) | |
| Screens NTF-10, NTF-11 (extend), NTF-14, NTF-15, USR-01, USR-02 | `Modules/Notification` |

**Manual test:** the GUARDIAN_WELCOME part of Example 1 end to end in-app: rule → outbox row → recipient rows per
guardian with `can_receive_notifications = 1` → the guardian's bell updates live.

### Phase C5-C7: Email, WhatsApp, Push
Exactly as [NOTIFICATION-OPTIMISED-DESIGN.md](../notifications-requirements/NOTIFICATION-OPTIMISED-DESIGN.md)
phases 4-6, with screen NTF-12 (channel setup, test send) and NTF-13 (compose broadcast with cost preview).

### Phase C8: The four live examples (record actions + checks + Prime rules)

| Example | Events | Actions | Checks | Module work |
|---|---|---|---|---|
| 1 Student admitted | `STUDENT_ADMITTED`, `STUDENT_DOCS_PENDING` | `record.library.create_member`, `notify`, `follow_up` | `std.documents_missing` | Admission/StudentProfile, Library, StudentProfile |
| 2 Fee reminders + late fee | `FEE_DAILY_SWEEP`, `FEE_DUE_IN_DAYS`, `FEE_FINE_APPLIED`, `FEE_COLLECTED` | `record.fee.emit_due_reminders`, `record.fee.apply_late_fines`, `notify` | `fee.invoice_unpaid` | StudentFee |
| 3 Teacher leave approved | `HRS_LEAVE_APPROVED`, `TT_SUBSTITUTION_NEEDED`, `TT_SUBSTITUTE_ASSIGNED` | `record.timetable.create_absence`, `notify` | `hrs.leave_still_approved` | HrStaff, SmartTimetable |
| 4a Diwali greeting | (schedule `RUN_ACTION`) | `notify` | — | SchoolSetup (holiday code) |
| 4b Attendance < 75 % | `ATTENDANCE_WEEKLY_SWEEP`, `STUDENT_ATTENDANCE_BELOW`, `STUDENT_ATTENDANCE_RECOVERED` | `record.attendance.evaluate_threshold`, `notify`, `record.ba.open_concern` | — | Attendance (StudentProfile), BehaviouralAssessment |

Each example is built and tested on its own, in this order: 1 → 4a → 3 → 2 → 4b (simplest first).
**Manual test:** the step tables in [03-FLOWCHARTS.md](03-FLOWCHARTS.md). Each step names the row you should see.

### Phase C9: Visibility, retention, Prime health
AUT-07 event-log chain view, `aut:prune`, `aut_daily_stats` charts on AUT-00, Prime PRM-05 cross-school health
(per school: oldest pending age, failed runs 24 h, paused rules, channels not configured).

### Phase C10 (later, one module per go): move existing engines onto the core
Order by value: HrStaff leave listeners → Transport trip notify → Hostel stub → Library notify → Complaint →
Accounting `acc_module_events` (becomes events + `record.accounting.post_voucher`) → Recommendation triggers →
console schedules → BA last.

---

## 6. Risks and how the plan handles them

| Risk | Handling |
|---|---|
| Every-minute schedules × 200 schools overload workers | ZSET pump (O(due)), lane cap per school, `overlap_policy = SKIP`, run-once key per planned time |
| A school rule messages everyone by mistake (no approval, B4) | dry run shows matched count; NTF-13 confirm dialog shows recipients + cost; `notify` from rules respects the event's tier and dedupe; auto-pause on failures |
| Rule loops | depth ≤ 3, `chain_id`, `emits_events_json` checked at rule save |
| Prime upgrades a rule a school has tuned | `prime_update_available` flag + "Review Prime update" on AUT-03; never silently overwritten |
| Holiday row missing next year | `waiting_reason` on the schedule + a dashboard card "3 schedules waiting for a date" |
| Notification v4 migration on live data (INT→BIGINT, new uniques) | backfill before unique; drop/re-add FKs in one migration; tested on a clone of test.localhost first |
| Timezone bugs | one `NextRunCalculator`, UTC storage, a test matrix for IST and one non-IST zone |
| Engine down = silent loss | outbox / log rows are written in the caller's transaction; jobs are only wake-ups; `aut:rebuild-due` + lease repair restore everything |

---

## 7. Prime default rules shipped for the examples

| rule_code | Event | Conditions | Action | Params | Locked |
|---|---|---|---|---|---|
| `PRM_ADMIT_LIBRARY_MEMBER` | STUDENT_ADMITTED | — | record.library.create_member | membership_type_code = STUDENT | no |
| `PRM_ADMIT_WELCOME` | STUDENT_ADMITTED | — | notify | event GUARDIAN_WELCOME, audience guardians_of_student | no |
| `PRM_ADMIT_DOCS_FOLLOWUP` | STUDENT_ADMITTED | — | follow_up | in 7 days emit STUDENT_DOCS_PENDING, check std.documents_missing [AADHAAR, BIRTH_CERT], cancel_key docs:student:{id} | no |
| `PRM_DOCS_REMINDER` | STUDENT_DOCS_PENDING | — | notify | event DOCS_UPLOAD_REMINDER | no |
| `PRM_FEE_REMINDERS` | FEE_DAILY_SWEEP | — | record.fee.emit_due_reminders | offsets [7, 1] | no |
| `PRM_FEE_LATE_FINES` | FEE_DAILY_SWEEP | — | record.fee.apply_late_fines | — | no |
| `PRM_FEE_DUE_NOTIFY` | FEE_DUE_IN_DAYS | — | notify | event FEE_DUE_REMINDER | no |
| `PRM_FEE_FINE_NOTIFY` | FEE_FINE_APPLIED | — | notify | event FEE_FINE_NOTICE | no |
| `PRM_FEE_RECEIPT` | FEE_COLLECTED | — | notify | event FEE_RECEIPT (PDF) | **yes** |
| `PRM_LEAVE_TO_ABSENCE` | HRS_LEAVE_APPROVED | employee is a teacher | record.timetable.create_absence | — | no |
| `PRM_SUBSTITUTION_NEEDED` | TT_SUBSTITUTION_NEEDED | — | notify | event SUBSTITUTION_NEEDED, audience permission tenant.smart-timetable.substitution.assign | no |
| `PRM_SUBSTITUTE_ASSIGNED` | TT_SUBSTITUTE_ASSIGNED | — | notify | event SUBSTITUTE_ASSIGNED, audience user = substitute | no |
| `PRM_ATTENDANCE_EVALUATE` | ATTENDANCE_WEEKLY_SWEEP | — | record.attendance.evaluate_threshold | threshold 75, recover_at 80 | no |
| `PRM_ATTENDANCE_LOW_NOTIFY` | STUDENT_ATTENDANCE_BELOW | — | notify | event ATTENDANCE_LOW | no |
| `PRM_ATTENDANCE_LOW_BA` | STUDENT_ATTENDANCE_BELOW | value < 65 | record.ba.open_concern | category ATTENDANCE | no |

Prime-shipped **school schedules** (origin PRIME, editable time): `PRM_FEE_DAILY` (DAILY 07:00 → FEE_DAILY_SWEEP),
`PRM_ATTENDANCE_WEEKLY` (WEEKLY Mon 08:00 → ATTENDANCE_WEEKLY_SWEEP). The Diwali schedule is **school-made**
(Example 4a).

---

## 8. Safety guards (all in Phase C2)

| Guard | Where |
|---|---|
| Run once per occurrence × rule | `uq_aut_run_once` |
| Event once per idempotency key | `uq_aut_event_idem` |
| Schedule once per planned time | `uq_aut_sch_run` |
| Loop limit depth 3 | `EventLogWriter` + `emits_events_json` check on rule save |
| Auto-pause after N failures | `aut_rules.auto_pause_after` (5), `aut_webhooks.auto_disable_after` (20) |
| Lane cap per school | `LaneCap` on `aut-*` and `ntf-*` queues |
| No code, no SQL | conditions are JSON over declared payload fields; actions are developer classes |
| Webhook SSRF + signing | `WebhookAction` |
| Dry run before enabling | AUT-02 |
| Locked Prime rules / events | `is_locked` on `aut_rules`, `ntf_events` |

---

## 9. Open items (will ask before the phase that needs them)

| # | Item | Phase |
|---|---|---|
| O1 | Which module saves an admitted student today (Admission vs StudentProfile) and fires `STUDENT_ADMITTED` | C1 |
| O2 | The `std_student_documents.document_type_id` values for Aadhaar and birth certificate | C8 |
| O3 | How an HR employee maps to `sch_teachers` (needed by `record.timetable.create_absence`) | C8 |
| O4 | Whether BehaviouralAssessment has (or should get) an *Attendance concern* category for `record.ba.open_concern` | C8 |
| O5 | Which permission marks the substitution coordinator (audience of SUBSTITUTION_NEEDED) | C8 |
