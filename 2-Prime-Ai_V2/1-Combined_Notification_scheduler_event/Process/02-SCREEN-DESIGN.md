# Automation Core — Screen Design (v1)

**Written:** 9 October 2026 · **Status:** DESIGN, nothing built · **Format:** follows `pgdatabase/2-Screen_Report_Design/ScreenDesign_v2.md`
**Tables:** `Automation_DDL_v1.sql` (`aut_*`), `Notification_DDL_v4.sql` (`ntf_*`), `Automation_Central_DDL_v1.sql` (`glb_*`, `prm_*`)
**Who uses it:** **School Admin** for every school screen except USR-01/02 (decision B7). **Prime super admin** for PRM-*.

---

## 1. OVERVIEW

### 1.1 Purpose
A School Admin can answer four questions without a developer:
1. **What happens automatically** at my school? (Rules, AUT-01)
2. **When** do things run? (Schedules, AUT-04)
3. **Did it work**, and if not, why? (Activity, AUT-07; Sent notifications, NTF-14)
4. **How do we reach people**? (Channels, NTF-12; Message types, NTF-10)

### 1.2 Design rules for every screen
| Rule | Why |
|---|---|
| Every list shows a **status pill** and a **reason** column for anything not done | "no silent skips" (plan §8) |
| Every rule and schedule form has a **Dry run** / **Preview next 5 runs** before Save | no approval step (B4) |
| Times are shown in the **school timezone** with the zone label (`09:00 IST`) | B6 |
| Prime-owned items carry a **PRIME** badge; locked ones a 🔒 and no toggle | B3 |
| No free-text code or SQL anywhere; every choice is a dropdown built from the catalogue | A1 |
| Row actions use `x-backend.table.action`; trash uses `action-trashed` | house table standard |
| Search bar: one line, no `me-3`, no inline height | house search-bar standard |
| Breadcrumbs come from the route name; tab crumbs via `data-bc-label` | house breadcrumb standard |

### 1.3 Status pills (shared)
| Pill | Colour | Used for |
|---|---|---|
| `Enabled` / `Disabled` | green / grey | rules, schedules, events, webhooks |
| `Auto-paused` | amber | rules / webhooks stopped after N failures (`paused_reason` on hover) |
| `Waiting` | amber | schedule with no next run (`waiting_reason`) |
| `Done` `Skipped` `Failed` `Running` `Queued` | green / grey / red / blue / light blue | runs, sends |
| `PRIME` | navy outline | origin = PRIME |
| 🔒 | — | is_locked |

---

## 2. NAVIGATION & SCREEN INVENTORY

```
School (tenant) — menu "Automation"
├── Dashboard ...................................  AUT-00   /automation
├── Rules
│   ├── Rule list ...............................  AUT-01   /automation/rules
│   ├── Rule builder (create / edit) ............  AUT-02   /automation/rules/create · /{id}/edit
│   └── Rule detail + runs ......................  AUT-03   /automation/rules/{id}
├── Schedules
│   ├── Schedule list ...........................  AUT-04   /automation/schedules
│   ├── Schedule builder ........................  AUT-05   /automation/schedules/create · /{id}/edit
│   └── Schedule detail + run history ...........  AUT-06   /automation/schedules/{id}
├── Activity (event log) ........................  AUT-07   /automation/activity
├── Webhooks ....................................  AUT-08   /automation/webhooks
├── Follow-ups (waiting) ........................  AUT-09   /automation/follow-ups
├── Event catalogue .............................  AUT-10   /automation/events
└── Settings (timezone, quiet hours, retention)    AUT-S1   /automation/settings

School (tenant) — menu "Notifications"
├── Message types (tune channels / time) ........  NTF-10   /notification-mgt/message-types
├── Templates (existing tab, extended) ..........  NTF-11   /notification-mgt?tab=templates
├── Channels (WhatsApp, Email, Push status) .....  NTF-12   /notification-mgt/channels
├── Compose broadcast ...........................  NTF-13   /notification-mgt/compose
├── Sent notifications ..........................  NTF-14   /notification-mgt/sent
└── One send (recipients) .......................  NTF-15   /notification-mgt/sent/{uuid}

Every user
├── Bell dropdown + inbox .......................  USR-02   navbar · /my-notifications
└── My notification preferences .................  USR-01   /my-notifications/preferences

Prime (central) — menu "Platform automation"
├── Registry (events + actions, read-only) ......  PRM-01   /prime/automation/registry
├── Default rules ...............................  PRM-02   /prime/automation/rules
├── Notification catalogue + default templates ..  PRM-03   /prime/notifications/catalogue
├── Prime schedules + runs ......................  PRM-04   /prime/schedules
├── Cross-school health .........................  PRM-05   /prime/automation/health
└── Horizon (queues) ............................  PRM-06   /horizon   (central domain, super admin only)
```

---

## 3. AUT-00 — AUTOMATION DASHBOARD

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ AUTOMATION                                                                     SCHOOL > AUTOMATION > DASHBOARD │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [ DASHBOARD ] [ RULES ] [ SCHEDULES ] [ ACTIVITY ] [ WEBHOOKS ] [ FOLLOW-UPS ] [ EVENTS ] [ SETTINGS ]          │
├──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┬─────────────────┤
│ Rules enabled        │ Ran today            │ Failed today         │ Schedules waiting    │ Follow-ups due  │
│   18  (3 PRIME 🔒)   │   1,284              │   6  ⚠               │   1  (DIWALI 2027)   │   42 this week  │
├──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┴─────────────────┤
│ NEEDS ATTENTION                                                                                              │
│  ⚠ Rule "Admission → webhook CRM" auto-paused 09-Oct 11:42 — 5 failures: HTTP 503            [Open] [Enable] │
│  ⚠ Schedule "Diwali greeting" waiting — no DIWALI holiday after 08-Nov-2026                   [Add holiday]  │
│  ⚠ WhatsApp not configured — 3 rules want WhatsApp; those sends go in-app + email only        [Set up]       │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ LAST 7 DAYS  (runs per day, stacked Done / Skipped / Failed)                                                 │
│  ▇▇▇▇▇▇▅ ▇▇▇▇▇▇▇ ▇▇▇▇▇▇▆ ▇▇▇▇▇▇▇ ▇▇▇▇▇▇▇ ▇▇▃ ▇▇▇▇▇▇▇                                                         │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ NEXT UP                                                                                                      │
│  Today 15:00 IST   Fee daily sweep (PRIME)        → record.fee.emit_due_reminders, apply_late_fines          │
│  Mon 08:00 IST     Attendance weekly check (PRIME)→ evaluate_threshold 75 %                                   │
│  08-Nov 09:00 IST  Diwali greeting                → notify FESTIVAL_GREETING (all guardians + staff)          │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Region | Element | Behaviour | DDL |
|---|---|---|---|
| Tiles | counts | Today = school-local date; Failed links to AUT-07 filtered | `aut_rules.is_enabled`, `aut_action_runs.status`, `aut_schedules.waiting_reason`, `aut_due.status` |
| Needs attention | auto-paused rules, waiting schedules, unconfigured channels wanted by rules | one line each, action button | `aut_rules.paused_at/paused_reason`, `aut_schedules.waiting_reason`, `ntf_provider_master` + `ntf_events.channels_json` |
| Chart | 7-day stacked bars | today from detail rows; older days from `aut_daily_stats` | `aut_action_runs`, `aut_daily_stats` |
| Next up | next 5 `next_run_at` | shown in school timezone | `aut_schedules.next_run_at`, `timezone` |

---

## 4. AUT-01 — RULE LIST

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ RULES                                                                              AUTOMATION > RULES        │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [Search rules…            ] [Module ▾ All] [Origin ▾ All] [Status ▾ All]                    [+ New rule]    │
├────┬──────────────────────────────────┬─────────────────────┬──────────────────────────┬─────────┬─────────┬──────┤
│ #  │ Rule                             │ When (event)        │ Then (action)            │ Last ran│ Status  │      │
├────┼──────────────────────────────────┼─────────────────────┼──────────────────────────┼─────────┼─────────┼──────┤
│ 1  │ Library card for new students    │ Student admitted    │ Create library member    │ 2 h ago │ Enabled │ ⋯    │
│    │ PRIME                            │                     │                          │         │         │      │
│ 2  │ Welcome message to guardians     │ Student admitted    │ Send GUARDIAN_WELCOME    │ 2 h ago │ Enabled │ ⋯    │
│    │ PRIME · tuned                    │                     │                          │         │         │      │
│ 3  │ Fee receipt                      │ Fee collected       │ Send FEE_RECEIPT         │ 5 min   │ Enabled │ ⋯    │
│    │ PRIME 🔒                         │                     │                          │         │         │      │
│ 4  │ Admission → our CRM              │ Student admitted    │ Webhook "CRM"            │ 11:42   │Auto-paused│ ⋯  │
│    │                                  │ if class in (XI,XII)│                          │         │ 5 fails │      │
└────┴──────────────────────────────────┴─────────────────────┴──────────────────────────┴─────────┴─────────┴──────┘
  ⋯ = View · Edit · Dry run · Enable/Disable · Duplicate · Delete (school rules only)
```

| Element | Behaviour | DDL |
|---|---|---|
| "PRIME · tuned" | `origin = PRIME` and `params_overridden = 1`; a ● dot when `prime_update_available = 1` | `aut_rules.origin`, `params_overridden`, `prime_update_available` |
| Toggle | hidden for 🔒 rules; enabling an auto-paused rule clears `paused_at` and resets `consecutive_failures` | `is_enabled`, `is_locked`, `paused_at` |
| Delete | school rules only, soft delete; PRIME rows show no Delete | `deleted_at` |
| When / Then | names from the catalogue copies; conditions summarised on line 2 | `aut_events.name`, `aut_actions.name`, `conditions_json` |

---

## 5. AUT-02 — RULE BUILDER (create / edit)

Three steps on one page, left to right, like a sentence: **WHEN → IF → THEN**.

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ NEW RULE                                                                       AUTOMATION > RULES > NEW     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Name [ Welcome message to hostel guardians                         ]   Priority [ 100 ]                    │
├──────────────────────────────┬──────────────────────────────────────┬──────────────────────────────────────┤
│ ① WHEN                       │ ② IF  (optional)                     │ ③ THEN                               │
│ Module  [ Admission      ▾ ] │ Match [ all ▾ ] of:                   │ Action [ Send a notification     ▾ ]  │
│ Event   [ Student admitted▾] │  [is_hosteller ▾] [ =  ▾] [ Yes  ▾ ] ✕│ ───────────────────────────────────── │
│                              │  [class      ▾] [in ▾] [XI, XII ▾ ] ✕│ Message type [ GUARDIAN_WELCOME  ▾ ]  │
│ Fires when a student is      │  [+ condition]                        │   tier NORMAL · channels In-app, Push,│
│ admitted (new or transfer).  │                                       │   WhatsApp → Email fallback           │
│ Fields you can use:          │ Fields come from the event, nothing   │ Audience  [ Guardians of the student▾]│
│  student_id · class_id ·     │ else. Values are dropdowns where the  │ Template  [ Default (en, hi)     ▾ ]  │
│  section_id · is_hosteller · │ field is an id.                       │   [Preview message]                   │
│  admission_type              │                                       │                                       │
├──────────────────────────────┴──────────────────────────────────────┴──────────────────────────────────────┤
│ DRY RUN — last 20 "Student admitted" events                                                     [Run again] │
│  14 would fire · 6 would not (not hosteller: 6)                                                              │
│  ✓ STU-1758 Aarav Sharma XI-A  → 2 guardians would get GUARDIAN_WELCOME                                     │
│  ✗ STU-1757 Diya Patel IX-B    → is_hosteller = No                                                           │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                         [Cancel]  [Save as disabled]  [Save & enable]       │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Region | Element | Behaviour | DDL |
|---|---|---|---|
| ① | Module → Event | only `is_school_visible = 1` events of enabled modules; the description and field list come from the schema | `aut_events.module_code`, `name`, `payload_schema_json` |
| ② | Condition rows | field dropdown = payload fields; op list depends on type (`bool`: =; `id`: = in not_in; `number`: = > < between; `enum`: in); value input = dropdown for `id:` / `enum:` types | `aut_rules.conditions_json` |
| ③ | Action | only actions whose `compatible_events_json` contains the event or `*`; the form below is generated from `params_schema_json` | `aut_rules.action_code`, `params_json` |
| ③ | notify block | message type list = enabled `ntf_events`; shows tier + channels read-only; audience options come from the message type's `default_audience_json` plus types compatible with the event's subject | `ntf_events.*` |
| ③ | follow_up block | `After [7] [days ▾] emit [Docs pending ▾] unless [Documents still missing ▾ with Aadhaar, Birth cert]` | `params_json` → `aut_due` at run time |
| ③ | webhook block | `Send to [CRM ▾]` (AUT-08 list) | `aut_webhooks.id` in `params_json` |
| Dry run | evaluates the conditions on the last 20 log rows of this event; sends nothing; for notify shows recipient counts | reads `aut_event_log`; writes nothing |
| Save | validates params against the schema; rejects a THEN action whose `emits_events_json` would re-trigger this WHEN event at depth > 3 | `aut_rules` |

**Editing a PRIME rule:** ① and the action dropdown in ③ are read-only. ② and the params are editable, and saving
sets `params_overridden = 1`. A banner reads *"Prime rule. You can change the conditions and settings, or disable it.
It cannot be deleted."* 🔒 rules have no Disable button.

---

## 6. AUT-03 — RULE DETAIL + RUNS

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Welcome message to guardians   PRIME · tuned   ● Prime update available [Review]          [Edit] [Disable] │
│ WHEN Student admitted · IF — · THEN Send GUARDIAN_WELCOME to guardians of the student                       │
│ Fired 1,204 times · last 2 h ago · failures in a row 0                                                      │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ RUNS  [Status ▾ All] [Date ▾ Last 7 days]                                                                    │
│ ┌──────────────┬──────────────────────────────┬──────────┬────────┬──────────────────────────────┬─────────┐ │
│ │ When         │ Subject                      │ Status   │ Time   │ Result / reason              │         │ │
│ │ 09-Oct 13:02 │ Student STU-1758 Aarav Sharma│ Done     │ 140 ms │ send #5521 → 2 recipients    │ [Open]  │ │
│ │ 09-Oct 12:40 │ Student STU-1757 Diya Patel  │ Skipped  │ 22 ms  │ No guardian can receive      │ [Open]  │ │
│ │ 09-Oct 10:11 │ Student STU-1755 ...         │ Failed   │ 3 s    │ Template missing for hi      │ [Retry] │ │
│ └──────────────┴──────────────────────────────┴──────────┴────────┴──────────────────────────────┴─────────┘ │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Element | Behaviour | DDL |
|---|---|---|
| Review Prime update | side-by-side diff of Prime's new params vs the school's; Accept or Keep mine | `glb_aut_rules.version` vs `aut_rules.prime_version` |
| Open | AUT-07 detail of that occurrence (chain view) | `aut_action_runs.event_log_id` |
| Retry | re-dispatches the same run (idempotent action) | `aut_action_runs.status`, `attempts` |

---

## 7. AUT-04 — SCHEDULE LIST

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ SCHEDULES                                                                      AUTOMATION > SCHEDULES       │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [Search…              ] [Type ▾ All] [Status ▾ All]                                        [+ New schedule] │
├────┬──────────────────────────────┬───────────────────────────┬─────────────────────────┬────────────┬──────────┬───┤
│ #  │ Schedule                     │ When                      │ Does                    │ Next run   │ Status   │   │
├────┼──────────────────────────────┼───────────────────────────┼─────────────────────────┼────────────┼──────────┼───┤
│ 1  │ Fee daily sweep  PRIME       │ Every day 07:00           │ Emit Fee daily sweep    │ Tomorrow   │ Enabled  │ ⋯ │
│ 2  │ Attendance weekly  PRIME     │ Every week Mon 08:00      │ Emit Attendance sweep   │ Mon 13-Oct │ Enabled  │ ⋯ │
│ 3  │ Diwali greeting              │ On holiday DIWALI 09:00   │ Send FESTIVAL_GREETING  │ 08-Nov-26  │ Enabled  │ ⋯ │
│ 4  │ Library overdue check        │ Every 15 minutes          │ Emit Library sweep      │ 13:15      │ Enabled  │ ⋯ │
│ 5  │ Republic Day wishes          │ On holiday REPUBLIC_DAY   │ Send FESTIVAL_GREETING  │ —          │ Waiting  │ ⋯ │
│    │                              │ 08:00                     │                         │            │ no date  │   │
└────┴──────────────────────────────┴───────────────────────────┴─────────────────────────┴────────────┴──────────┴───┘
  ⋯ = View · Edit · Run now · Enable/Disable · Duplicate · Delete (school schedules only)
```

| Element | Behaviour | DDL |
|---|---|---|
| When | human sentence from `frequency_code` + `when_json`, in the school timezone | `aut_schedules.*` |
| Next run | relative for < 7 days, date otherwise; "—" + Waiting pill when `next_run_at` is NULL | `next_run_at`, `waiting_reason` |
| Run now | fires immediately with `planned_at = now()` (own run row; does not move the next planned run) | `aut_schedule_runs` |

---

## 8. AUT-05 — SCHEDULE BUILDER

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ NEW SCHEDULE                                                                   AUTOMATION > SCHEDULES > NEW │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Name [ Diwali greeting                                   ]                                                 │
├──────────────────────────────────────────────┬─────────────────────────────────────────────────────────────┤
│ ① WHEN                                        │ ② DO                                                        │
│ Repeat  [ On a school holiday            ▾ ]  │ (•) Run an action directly   ( ) Emit an event (rules decide)│
│ Holiday [ DIWALI                         ▾ ]  │ Action  [ Send a notification             ▾ ]               │
│ Time    [ 09:00 ]  IST (school timezone)      │ Message type [ FESTIVAL_GREETING          ▾ ]  tier SCHEDULED│
│ Offset  [ 0 ] days   (-1 = the day before)    │ Audience [ All guardians + all staff      ▾ ]  ≈ 3,140 people│
│ Active  from [          ] to [          ]     │ Message  [ Happy Diwali (custom)          ▾ ] [Edit text]   │
│ If still running  [ Skip this run ▾ ]         │   "Wishing you and your family a very Happy Diwali …"       │
├──────────────────────────────────────────────┴─────────────────────────────────────────────────────────────┤
│ PREVIEW — next 5 runs                                                                                        │
│  Sun 08-Nov-2026 09:00 IST   (from holiday row "Deepavali" 08-Nov-2026)                                      │
│  — no DIWALI holiday after 08-Nov-2026. Add next year's row in School Setup > Holidays to continue.          │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                           [Cancel]  [Save as disabled]  [Save & enable]     │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**The WHEN panel changes with the Repeat choice** (from `glb_aut_frequencies.needs_fields_json`):

| Repeat (`frequency_code`) | Fields shown | Stored as |
|---|---|---|
| Every minute / 5 / 15 min, Every hour | — | `when_type INTERVAL`, `interval_minutes` |
| Every day at … | Time | `CRON` `"{m} {h} * * *"` |
| Every week on … | Weekday(s), Time | `CRON` |
| Every N days | N, Time | `INTERVAL` N × 1440 from the first run |
| Every month on day … | Day 1-31 (or "last day"), Time | `CRON` |
| Every year on date … | Day, Month, Time | `CRON` |
| On a school holiday | Holiday code, Time, Offset days | `HOLIDAY`, `holiday_code`, `time_of_day`, `offset_days` |
| Once | Date + time | `ONCE`, `run_at` (UTC) |
| Advanced | cron expression + live "next 5" | `CRON` |

| Region | Behaviour | DDL |
|---|---|---|
| ② Emit an event | event list = `is_schedulable = 1` (TIME / SWEEP events, e.g. Fee daily sweep); rules then decide | `what_type EMIT_EVENT`, `event_code`, `context_json` |
| ② Run an action | same action forms as AUT-02 ③ (no rule needed) | `what_type RUN_ACTION`, `action_code`, `params_json` |
| Audience count | live estimate from the resolver (count only) | — |
| Preview | runs `NextRunCalculator` 5 times; HOLIDAY shows the holiday row used; flags a missing future row | `sch_holidays.holiday_code`, `holiday_date` |

---

## 9. AUT-06 — SCHEDULE DETAIL + RUN HISTORY

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Fee daily sweep   PRIME   Every day 07:00 IST → Emit "Fee daily sweep"           [Edit time] [Run now] [⏸] │
│ Next: tomorrow 07:00 IST · last: today 07:00 Done · runs 312 · failures in a row 0                          │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────────────────┬──────────┬────────┬────────────────────────────────────────────────────────────────┐   │
│ │ Planned          │ Status   │ Took   │ What it did                                                    │   │
│ │ 09-Oct 07:00 IST │ Done     │ 4.1 s  │ 2 rules ran: 38 due reminders emitted · 12 late fines applied  │   │
│ │ 08-Oct 07:00 IST │ Done     │ 3.8 s  │ 2 rules ran: 41 due reminders · 0 fines                         │   │
│ │ 07-Oct 07:00 IST │ Skipped  │ —      │ previous run still running (overlap policy: skip)              │   │
│ └──────────────────┴──────────┴────────┴────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
Clicking a row opens AUT-07 for that run's event (`aut_schedule_runs.event_log_id`) and shows the whole chain.
A PRIME schedule allows **Edit time** and pause only; its "Does" part is read-only.

---

## 10. AUT-07 — ACTIVITY (event log) with chain view

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ACTIVITY                                                                       AUTOMATION > ACTIVITY        │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [Search subject…  ] [Event ▾ All] [Source ▾ All] [Status ▾ All] [Date ▾ Today]                               │
├──────────────┬──────────────────────────┬────────────────────────────┬──────────┬───────────┬──────────────┤
│ When         │ Event                    │ Subject                    │ Source   │ Rules ran │ Status       │
├──────────────┼──────────────────────────┼────────────────────────────┼──────────┼───────────┼──────────────┤
│ 13:02:11     │ Student admitted         │ STU-1758 Aarav Sharma      │ Admission│ 3         │ Matched      │
│ 07:00:00     │ Fee daily sweep          │ —                          │ Schedule │ 2         │ Matched      │
│ 07:00:02     │ Fee due in 7 days        │ INV-7381 (Aarav Sharma)    │ Action   │ 1         │ Matched      │
│ 06:59:58     │ Library overdue sweep    │ —                          │ Schedule │ 0         │ No rules     │
└──────────────┴──────────────────────────┴────────────────────────────┴──────────┴───────────┴──────────────┘

 Drawer — chain of 13:02:11 "Student admitted" STU-1758
 ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │ ● Student admitted  (Admission, by Ms. Rao)                                         chain 7f3c…  depth 0 │
 │ ├─ Rule "Library card for new students" → Create library member ......... Done   member LIB-0921        │
 │ ├─ Rule "Welcome message to guardians"  → Send GUARDIAN_WELCOME ......... Done   send #5521 (2 people)  │
 │ └─ Rule "Documents follow-up"           → Follow-up in 7 days ........... Done   due 16-Oct 13:02       │
 │      └─ (16-Oct) Docs pending → Send DOCS_UPLOAD_REMINDER ............... Waiting  [Cancel follow-up]     │
 └──────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

| Element | Behaviour | DDL |
|---|---|---|
| Rows | 90 days of detail (B8); older days show "summarised" with counts only | `aut_event_log`, `aut_daily_stats` |
| Chain drawer | everything sharing `chain_id`, as a tree by `source_ref_id`; follow-ups shown under the run that created them | `aut_event_log.chain_id`, `aut_action_runs`, `aut_due.created_by_run_id` |
| Subject | resolved to a readable label by the event's `subject_table` (link to that record's page) | `subject_table`, `subject_id` |

---

## 11. AUT-08 — WEBHOOKS

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ WEBHOOKS                                                                                [+ New webhook]     │
├────┬────────────────┬───────────────────────────────────────┬───────────────┬──────────────┬──────────┬─────┤
│ #  │ Name           │ URL                                   │ Last success  │ Failures     │ Status   │     │
│ 1  │ CRM            │ https://crm.school.in/hooks/prime     │ 11:30         │ 5 in a row   │ Enabled  │ ⋯   │
└────┴────────────────┴───────────────────────────────────────┴───────────────┴──────────────┴──────────┴─────┘
 Create: Name · URL (https only) · Timeout (10 s) → Save → secret shown ONCE with a copy button.
 ⋯ = Send test · Rotate secret · Disable · Delete
```
Rules: `http://`, private or loopback addresses are rejected on save and again at send time. **Send test** posts a
sample event and shows the response code. DDL: `aut_webhooks.*`.

---

## 12. AUT-09 — FOLLOW-UPS (waiting)

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FOLLOW-UPS                         [Status ▾ Waiting] [Event ▾ All] [Due ▾ Next 7 days]                     │
├──────────────────┬──────────────────────┬────────────────────────────┬──────────────────────────┬──────────┤
│ Due              │ Will emit            │ Subject                    │ Only if                  │          │
│ 16-Oct 13:02 IST │ Docs pending         │ STU-1758 Aarav Sharma      │ Aadhaar / Birth cert     │ [Cancel] │
│                  │                      │                            │ still missing            │          │
└──────────────────┴──────────────────────┴────────────────────────────┴──────────────────────────┴──────────┘
```
DDL: `aut_due` (`due_at`, `event_code`, `subject_*`, `still_applies_check`, `check_params_json`, `status`).

---

## 13. AUT-10 — EVENT CATALOGUE

Read-only list of every event the school can use, grouped by module, with its fields and the number of rules on it.
Toggle **Enabled** switches off every rule on that event (`aut_events.is_enabled`). Used mainly to answer "what can I
automate?".

## 14. AUT-S1 — AUTOMATION SETTINGS

| Field | Default | Stored |
|---|---|---|
| School timezone | Asia/Kolkata | `sys_settings.school_timezone` (changing it recomputes every `next_run_at`) |
| Quiet hours | 21:00 – 07:00 | `sys_settings.ntf_quiet_hours_start / _end` |
| Keep detailed logs for | 90 days | `sys_settings.aut_log_retention_days` |

---

## 15. NTF-10 — MESSAGE TYPES (tune per school)

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ MESSAGE TYPES                                [Module ▾ All] [Tier ▾ All]                                    │
├──────────────────────────┬───────────┬──────────────────────────────────┬──────────────┬─────────┬──────────┤
│ Message type             │ Tier      │ Channels (fallback)              │ Send time    │ Status  │          │
│ Fee receipt 🔒           │ HIGH      │ In-app · Email(PDF) · WhatsApp   │ immediately  │ Enabled │ [Edit]   │
│ Fee due reminder         │ SCHEDULED │ In-app · Push · WhatsApp → Email │ 08:00        │ Enabled │ [Edit]   │
│ Guardian welcome         │ NORMAL    │ In-app · Push · WhatsApp → Email │ immediately  │ Enabled │ [Edit]   │
│ Bus breakdown 🔒         │ CRITICAL  │ all at once                      │ immediately  │ Enabled │ [View]   │
└──────────────────────────┴───────────┴──────────────────────────────────┴──────────────┴─────────┴──────────┘
 Edit: channels checkboxes (only channels allowed for the tier) · fallback order · send time (NORMAL / SCHEDULED)
       · Enabled (not for 🔒) · [Edit templates →]   Tier is shown, never editable.
```
DDL: `ntf_events` (`tier` read-only, `channels_json`, `fallback_json`, `send_time_local`, `is_enabled`, `is_locked`, `school_overridden`).

## 16. NTF-11 — TEMPLATES (existing tab, extended)
Adds: **Message type** filter, **Language** tabs (en / hi), variable chips from `variables_schema_json` that insert
`{{student_name}}`, a **Preview with a real record** button, and, for WhatsApp, the Meta template name and status
(`wa_meta_status`) with **Submit to Meta**. Unknown variables block Save.

## 17. NTF-12 — CHANNELS

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ CHANNELS                                                                                                    │
├─────────────┬──────────────────────────────────────────────────────────────────────────────┬──────────────┤
│ In-app      │ ✅ Always on                                                                 │              │
│ Push        │ ✅ Prime app (primeapp, primeadmin) · 1,102 devices registered               │ [Test to me] │
│ Email       │ ✅ Prime sender "St. Xavier's School" <noreply@primeai.co.in>, reply-to       │ [Test] [Use  │
│             │    office@stxaviers.in                                                        │  own account]│
│ WhatsApp    │ ⚠ Not connected — 3 message types want WhatsApp                              │ [Connect with│
│             │                                                                              │  Meta]       │
│ SMS         │ — not enabled                                                                │              │
└─────────────┴──────────────────────────────────────────────────────────────────────────────┴──────────────┘
```
| Element | Behaviour | DDL |
|---|---|---|
| Connect with Meta | Embedded Signup popup → stores phone number id, WABA id, token; shows quality rating | `ntf_provider_master.wa_*` |
| Use own account (email) | one DSN field + From + Reply-To; Test sends to the admin | `mailer_dsn_encrypted`, `from_address`, `reply_to_address` |
| Test | result stored and shown | `last_test_at`, `last_test_status`, `last_test_message` |

## 18. NTF-13 — COMPOSE BROADCAST

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ COMPOSE                                                                                                     │
│ Message type [ Announcement (NORMAL)      ▾ ]   Audience [ Class X, all sections + guardians ▾ ]           │
│ Subject [ PTM on Saturday                     ]                                                             │
│ Message [ Dear {{guardian_name}}, the parent-teacher meeting for {{student_name}} …                ]        │
│ Send  (•) now  ( ) at [ 10-Oct-2026 ] [ 08:00 ] IST                                                         │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ CONFIRM: 412 guardians · In-app 412 · Push 380 · WhatsApp 395 (≈ ₹ 316) · Email fallback ≤ 17                │
│ Quiet hours: sending now (13:05) is outside 21:00-07:00.                    [Back]  [Send to 412 people]    │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
Creates one `ntf_notifications` row (`origin ADMIN`, `audience_json`, `send_at`). The confirm step is mandatory
(no approval workflow, B4).

## 19. NTF-14 / NTF-15 — SENT NOTIFICATIONS / ONE SEND

```ascii
NTF-14
┌──────────────┬──────────────────────┬─────────┬──────────┬───────────────────────────────────┬────────────┐
│ When         │ Message type         │ Origin  │ To       │ Sent · Failed · Skipped · Held    │ Status     │
│ 13:02        │ Guardian welcome     │ Rule    │ 2        │ 2 · 0 · 0 · 0                     │ Done       │
│ 08:00        │ Fee due reminder     │ Rule    │ 38       │ 35 · 1 · 2 · 0                    │ Done       │
│ 07:58        │ PTM on Saturday      │ Admin   │ 412      │ 260 · 0 · 4 · 0                   │ Running ⏸ ✕│
└──────────────┴──────────────────────┴─────────┴──────────┴───────────────────────────────────┴────────────┘

NTF-15  (one send)  tabs: [ Recipients ] [ By channel ] [ Timeline ]
┌──────────────────────────┬───────────┬───────────┬──────────────────────────────────────────┬──────────┐
│ Person                   │ Channel   │ State     │ Reason / provider id                     │          │
│ Mr. R. Sharma (guardian) │ WhatsApp  │ Failed    │ 131026 number not on WhatsApp            │          │
│ Mr. R. Sharma (guardian) │ Email     │ Delivered │ fallback of the row above                │          │
│ Mrs. P. Patel (guardian) │ In-app    │ Read      │ read 13:10                               │          │
│ Mr. K. Iyer (guardian)   │ WhatsApp  │ Skipped   │ muted by user                            │          │
└──────────────────────────┴───────────┴───────────┴──────────────────────────────────────────┴──────────┘
 [Retry failed]  [Export]
```
DDL: `ntf_notifications` (counters, `pipeline_status`, `paused_by`, `cancelled_by`), `ntf_resolved_recipients`
(`state`, `reason`, `fallback_of_id`, `provider_message_id`).

## 20. USR-01 / USR-02 — EVERY USER

```ascii
USR-02 bell                                   USR-01 My notification preferences
┌───────────────────────────────────┐         ┌─────────────────────────────┬────────┬──────┬───────┬──────────┐
│ 🔔 3 new                          │         │ Message type                │ In-app │ Push │ Email │ WhatsApp │
│ ● Fee due in 7 days — INV-7381    │         │ Fee receipt   (required)    │  🔒    │ 🔒   │ 🔒    │ 🔒       │
│ ● Welcome to St. Xavier's         │         │ Fee due reminder            │  ☑     │ ☑    │ ☐     │ ☑        │
│   Substitution assigned P3 VII-B  │         │ Announcements               │  ☑     │ ☐    │ ☐     │ ☑        │
│ [See all]                         │         │ Quiet hours [21:00]-[07:00] (school default)                │
└───────────────────────────────────┘         └─────────────────────────────────────────────────────────────┘
```
Bell = Laravel `notifications` table, live via Reverb `school.{tenant}.user.{id}`. Preferences = `ntf_user_preferences`
(`event_code`, `channel_id`); locked types show 🔒 and cannot be changed.

---

## 21. PRIME SCREENS (central)

| Screen | Content | DDL |
|---|---|---|
| **PRM-01 Registry** | events and actions from code, each with module, schema, compatible actions, `synced_at`, hash; **Sync now** (`aut:sync-registry`); "N schools behind" counter | `glb_aut_events`, `glb_aut_actions`, `glb_aut_event_action_compat` |
| **PRM-02 Default rules** | same builder as AUT-02 plus **Locked** and **Enabled by default**; Save bumps `version`; **Push to schools** runs `aut:sync-school --all` | `glb_aut_rules` |
| **PRM-03 Notification catalogue** | message types (tier, category, channels, fallback, locked, confidential, dedupe shape, TTL) + default templates per channel × language | `glb_ntf_events`, `glb_ntf_templates` |
| **PRM-04 Prime schedules** | the old Scheduler screens rebuilt on `prm_schedules`: job (from `JobRegistry`), scope (central / all schools / one school), builder as AUT-05; run history per school | `prm_schedules`, `prm_schedule_runs` |
| **PRM-05 Cross-school health** | one row per school: oldest pending event age, failed runs 24 h, auto-paused rules, waiting schedules, channels not configured, last pump tick | reads each school (nightly snapshot) |
| **PRM-06 Horizon** | link; central domain and super admin only (Phase 0 Step 6) | — |

---

## 22. USER FLOWS (end to end)

### Flow 1: School Admin automates "welcome hostel guardians"
1. **AUT-01** → *New rule* → **AUT-02**.
2. ① Module *Admission*, Event *Student admitted*.
3. ② Add condition `is_hosteller = Yes`.
4. ③ Action *Send a notification*, Message type *Guardian welcome*, Audience *Guardians of the student*, then *Preview message*.
5. **Dry run** → "14 would fire". Save & enable.
6. Next admission → **AUT-07** shows the chain; **NTF-15** shows each guardian's state.

### Flow 2: School Admin schedules the Diwali greeting
1. **School Setup › Holidays**: edit "Deepavali 08-Nov-2026" → *Holiday code* = **DIWALI** (once per year's row).
2. **AUT-04** → *New schedule* → **AUT-05**: Repeat *On a school holiday*, Holiday *DIWALI*, Time *09:00*.
3. Do *Run an action directly* → *Send a notification* → *Festival greeting* → Audience *All guardians + all staff* → edit the text.
4. **Preview** shows 08-Nov-2026 09:00 IST and warns that no 2027 row exists yet. Save.
5. 08-Nov 09:00 → **NTF-14** shows ~3,140 recipients. Afterwards the schedule shows **Waiting** until next year's holiday row is coded.

### Flow 3: School Admin investigates "parents didn't get the fee reminder"
1. **AUT-00** tile *Failed today 6* → **AUT-07** filtered by failed.
2. Open the *Fee due in 7 days* row → chain → *Send FEE_DUE_REMINDER* → **NTF-15**.
3. Recipient rows: WhatsApp *Failed: number not on WhatsApp*, then Email *Delivered* (fallback); another guardian *Skipped: muted by user*.
4. If WhatsApp was **Not configured** → **NTF-12** → *Connect with Meta*.

### Flow 4: Prime adds a new event for every school
1. A developer writes the event class → deploy → **PRM-01** *Sync now*.
2. **PRM-02** writes a default rule → *Push to schools*.
3. Every school sees it on **AUT-01** with the PRIME badge (enabled by default or not, as Prime chose).
