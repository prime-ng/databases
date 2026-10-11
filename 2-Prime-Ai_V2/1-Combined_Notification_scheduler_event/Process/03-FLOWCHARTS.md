# Automation Core — Flowcharts with Live Examples from Prime-AI

**Written:** 9 October 2026 · **Status:** DESIGN, nothing built
**Read with:** [01-IMPLEMENTATION-PLAN.md](01-IMPLEMENTATION-PLAN.md) (classes, phases) · [02-SCREEN-DESIGN.md](02-SCREEN-DESIGN.md) (screens)
**Tables:** real table names from the test school DB (checked 9 Oct 2026). `aut_*` / `ntf_*` v4 columns come from the new DDL.

Every example has: **(a)** a flowchart, **(b)** a sequence diagram where timing matters, and **(c)** a step table that
says what happens and **which row to look at** when you test by hand.

| # | Example | Starts from | Ends in |
|---|---|---|---|
| 1 | Student admitted | a record change (module event) | a record action **+** a notification **+** a follow-up that may never fire |
| 2 | Fee reminders + late fee | a daily schedule (sweep) | many notifications **+** a money record action **+** a receipt |
| 3 | Teacher leave approved | a record change in HR | a record action in another module (Timetable) → notifications to two different people |
| 4a | Diwali greeting | a holiday schedule | a notification only |
| 4b | Attendance below 75 % | a weekly schedule (sweep) | a notification **+** a record action, **once per crossing** |

---

## 0. The two engine paths every example uses

### 0.1 Event path (something happened)

```mermaid
flowchart TD
    A["Module code, inside its DB transaction<br/>Automation::emit(code, subjectId, ctx)"] --> B["INSERT aut_event_log<br/>idempotency_key UNIQUE, chain_id, depth"]
    B --> C{"Transaction<br/>committed?"}
    C -- "no (save failed)" --> X["log row rolls back too<br/>nothing ever runs"]
    C -- yes --> D["afterCommit: MatchRulesJob(log_id)<br/>queue aut-high / aut-bulk<br/>payload carries tenant_id (stancl)"]
    D --> E["worker: school initialised<br/>enabled aut_rules for event_code<br/>(cached per school)"]
    E --> F{"ConditionEvaluator<br/>conditions_json true?"}
    F -- no --> F1["not matched"]
    F -- yes --> G["INSERT IGNORE aut_action_runs<br/>UNIQUE(event_log_id, owner_key)"]
    G --> H["RunActionJob(run_id)<br/>lane cap per school"]
    H --> I{"action_kind"}
    I -- NOTIFY --> J["Notify::event -> ntf_notifications (outbox)"]
    I -- RECORD --> K["module action class<br/>(idempotent, own service)"]
    I -- FOLLOW_UP --> L["INSERT aut_due + ZADD aut:due"]
    I -- WEBHOOK --> M["signed HTTPS POST"]
    J & K & L & M --> N["run DONE / SKIPPED / FAILED + reason<br/>5 failures in a row -> rule auto-paused"]
    K -. "may emit a new event (depth+1, max 3)" .-> A
```

### 0.2 Time path (a schedule or follow-up came due)

```mermaid
flowchart TD
    P["aut:pump every 15 s (one central process)"] --> Q["ZRANGEBYSCORE aut:due -inf now"]
    Q --> R["group members by school<br/>tenancy()->run(school)"]
    R --> S{"member type"}
    S -- "schedule:N" --> T["INSERT aut_schedule_runs (schedule, planned_at)<br/>UNIQUE = fires once"]
    T --> U{"what_type"}
    U -- EMIT_EVENT --> V["Automation::emit(event_code)<br/>source SCHEDULE"]
    U -- RUN_ACTION --> W["aut_action_runs with schedule_id<br/>-> RunActionJob"]
    T --> Z["NextRunCalculator -> next_run_at<br/>ZADD again (or waiting_reason)"]
    S -- "due:N" --> AA{"still_applies_check?"}
    AA -- "no longer applies" --> AB["aut_due SKIPPED + reason"]
    AA -- "still applies" --> AC["Automation::emit(event_code)<br/>source FOLLOW_UP"]
    S -- "ntf:N" --> AD["scheduled ntf_notifications send_at reached<br/>-> chunk job"]
    V & AC --> AE["event path 0.1"]
```

---

## 1. Example 1 — Student admitted

**Story:** The office admits *Aarav Sharma* into XI-A (a hosteller). Three Prime rules react:
1. create his **library membership**;
2. send a **welcome message** to his guardians;
3. **in 7 days**, remind the guardians to upload Aadhaar and birth certificate, **only if they are still missing**.

### 1(a) Flowchart

```mermaid
flowchart TD
    A["Admission save: std_students id 1758 (XI-A)<br/>+ std_student_guardian_jnt rows"] --> B["emit STUDENT_ADMITTED<br/>key STUDENT_ADMITTED:1758"]
    B --> C["MatchRulesJob: 3 enabled rules"]
    C --> R1["PRM_ADMIT_LIBRARY_MEMBER<br/>record.library.create_member"]
    C --> R2["PRM_ADMIT_WELCOME<br/>notify GUARDIAN_WELCOME"]
    C --> R3["PRM_ADMIT_DOCS_FOLLOWUP<br/>follow_up 7 days"]
    R1 --> R1a["lib_members row<br/>user_type STUDENT, membership_number LIB-0921<br/>(skip if one exists for the user)"]
    R2 --> R2a["ntf_notifications outbox<br/>audience guardians_of_student 1758"]
    R2a --> R2b["resolver: std_student_guardian_jnt<br/>can_receive_notifications = 1 -> 2 guardians"]
    R2b --> R2c["ntf_resolved_recipients<br/>2 guardians x (In-app, Push, WhatsApp)"]
    R2c --> R2d["sent; WhatsApp fails for 1 number<br/>-> Email fallback row"]
    R3 --> R3a["aut_due: due 16-Oct 13:02<br/>emit STUDENT_DOCS_PENDING<br/>check std.documents_missing [AADHAAR, BIRTH_CERT]<br/>cancel_key docs:student:1758"]
    R3a --> D{"16-Oct: documents<br/>still missing?"}
    D -- "no: both uploaded<br/>(std_student_documents)" --> D1["aut_due SKIPPED<br/>nothing sent"]
    D -- "yes" --> D2["emit STUDENT_DOCS_PENDING"]
    D2 --> D3["PRM_DOCS_REMINDER -> notify DOCS_UPLOAD_REMINDER<br/>(category ACT, link to upload page)"]
```

### 1(b) Sequence

```mermaid
sequenceDiagram
    participant UI as Office (admission form)
    participant DB as School DB
    participant Q as Redis queues
    participant W as Workers
    participant G as Guardians' phones

    UI->>DB: BEGIN; INSERT std_students 1758; INSERT aut_event_log (STUDENT_ADMITTED:1758); COMMIT
    DB-->>Q: afterCommit MatchRulesJob(log)
    Q->>W: MatchRulesJob (school initialised)
    W->>DB: 3 rules match -> 3 aut_action_runs
    W->>DB: run 1: INSERT lib_members (LIB-0921)
    W->>DB: run 2: INSERT ntf_notifications + 6 recipient rows
    W->>G: in-app (Reverb), push (FCM), WhatsApp (school number)
    W->>DB: run 3: INSERT aut_due (16-Oct)
    Note over W,DB: 7 days later
    W->>DB: pump: still_applies std.documents_missing?
    alt documents uploaded
        W->>DB: aut_due SKIPPED
    else still missing
        W->>DB: emit STUDENT_DOCS_PENDING -> notify DOCS_UPLOAD_REMINDER
        W->>G: reminder with upload link
    end
```

### 1(c) Steps to check

| # | What happens | Look at |
|---|---|---|
| 1 | Student saved and event logged in **one** transaction | `std_students` 1758 + `aut_event_log` (event `STUDENT_ADMITTED`, `idempotency_key STUDENT_ADMITTED:1758`, `status MATCHED`, `matched_rules 3`) |
| 2 | Three runs, one per rule | `aut_action_runs` × 3, same `event_log_id`, owner `R<rule_id>` |
| 3 | Library membership created | `lib_members` (`user_id` = student's user, `user_type STUDENT`); run `result_json {"lib_member_id":…}` |
| 4 | Welcome send created | `ntf_notifications` (`event_code GUARDIAN_WELCOME`, `origin RULE`, `aut_action_run_id`, `dedupe_base GUARDIAN_WELCOME:1758`) |
| 5 | Only guardians allowed to receive | `std_student_guardian_jnt.can_receive_notifications = 1` → `ntf_resolved_recipients` rows (`contact_type GUARDIAN`, `contact_ref_table std_guardians`) |
| 6 | WhatsApp fails for one number → email | recipient `state FAILED reason "not on WhatsApp"` + new row `channel EMAIL`, `fallback_of_id` = failed row |
| 7 | Follow-up waiting | `aut_due` (`status WAITING`, `due_at` +7 days, `cancel_key docs:student:1758`), AUT-09 |
| 8a | Documents uploaded before day 7 | `std_student_documents` has both types → `aut_due status SKIPPED reason "no longer applies"` |
| 8b | Still missing on day 7 | new `aut_event_log` `STUDENT_DOCS_PENDING` (`source FOLLOW_UP`, same `chain_id`) → notify `DOCS_UPLOAD_REMINDER` |
| 9 | Admission saved twice / retried | still one `aut_event_log`, one `lib_members`, one send (`uq_ntf_dedupe_base`) |

---

## 2. Example 2 — Fee due reminders + late fee + receipt

**Story:** Every morning at 07:00 the school's **Fee daily sweep** runs. It finds invoices due in 7 days and in
1 day and sends reminders. It finds overdue invoices past their grace period and applies the late fine from
`fee_fine_rules`. When a guardian pays, a receipt goes out. The receipt rule is 🔒 locked.

### 2(a) Flowchart

```mermaid
flowchart TD
    S["aut_schedules PRM_FEE_DAILY<br/>DAILY 07:00 IST -> emit FEE_DAILY_SWEEP"] --> E["aut_event_log FEE_DAILY_SWEEP<br/>key schedule:PRM_FEE_DAILY:2026-10-09T01:30Z"]
    E --> R1["PRM_FEE_REMINDERS<br/>record.fee.emit_due_reminders offsets [7,1]"]
    E --> R2["PRM_FEE_LATE_FINES<br/>record.fee.apply_late_fines"]

    R1 --> R1a["fee_invoices where balance_amount > 0<br/>and due_date = today+7 or today+1"]
    R1a --> R1b["emit FEE_DUE_IN_DAYS per invoice (depth 1)<br/>key FEE_DUE_IN_DAYS:7381:T-7"]
    R1b --> R1c["PRM_FEE_DUE_NOTIFY -> notify FEE_DUE_REMINDER<br/>tier SCHEDULED, send_time 08:00, WhatsApp -> Email"]
    R1c --> R1d{"08:00 send:<br/>invoice still unpaid?<br/>(check fee.invoice_unpaid)"}
    R1d -- "paid since 07:00" --> R1e["recipient rows SKIPPED: no longer applies"]
    R1d -- unpaid --> R1f["reminder delivered to fee-payer guardian<br/>(is_fee_payer = 1)"]

    R2 --> R2a["fee_invoices past due_date + grace_days<br/>(fee_installments.grace_days / fee_fine_rules.grace_period_days)"]
    R2a --> R2b["INSERT fee_fine_transactions (one per invoice per fine period)<br/>UPDATE fee_invoices fine_amount, balance_amount"]
    R2b --> R2c["emit FEE_FINE_APPLIED (depth 1)"]
    R2c --> R2d["PRM_FEE_FINE_NOTIFY -> notify FEE_FINE_NOTICE"]

    P["Guardian pays online (Razorpay) / at counter"] --> P1["fee_transactions row<br/>emit FEE_COLLECTED"]
    P1 --> P2["PRM_FEE_RECEIPT (locked) -> notify FEE_RECEIPT<br/>Email with PDF + in-app + WhatsApp"]
```

### 2(b) Sequence (one invoice, INV-7381)

```mermaid
sequenceDiagram
    participant PUMP as aut:pump
    participant W as Workers
    participant FEE as StudentFee tables
    participant N as Notification pipeline
    participant G as Fee-payer guardian

    PUMP->>W: 07:00 IST schedule PRM_FEE_DAILY fires (run row, planned_at)
    W->>W: emit FEE_DAILY_SWEEP -> 2 rules
    W->>FEE: emit_due_reminders: INV-7381 due in 7 days
    W->>W: emit FEE_DUE_IN_DAYS (7381, T-7)
    W->>N: notify FEE_DUE_REMINDER, send_at 08:00
    N->>FEE: 08:00 still unpaid? yes
    N->>G: WhatsApp reminder (fallback email)
    Note over W,FEE: 8 days later, still unpaid, grace over
    W->>FEE: apply_late_fines: INSERT fee_fine_transactions, fine_amount += 100
    W->>N: notify FEE_FINE_NOTICE
    G->>FEE: pays -> fee_transactions
    FEE->>W: emit FEE_COLLECTED
    W->>N: notify FEE_RECEIPT (locked) with PDF
```

### 2(c) Steps to check

| # | What happens | Look at |
|---|---|---|
| 1 | 07:00 firing recorded once | `aut_schedule_runs` (`planned_at` 01:30 UTC, `status DONE`), unique per planned time |
| 2 | Sweep event | `aut_event_log FEE_DAILY_SWEEP` (`source SCHEDULE`, `source_ref_id` = run id) |
| 3 | One event per due invoice | `aut_event_log FEE_DUE_IN_DAYS` (`depth 1`, key `FEE_DUE_IN_DAYS:7381:T-7`); same `chain_id` as step 2 |
| 4 | Reminder waits for 08:00 | `ntf_notifications` (`tier SCHEDULED`, `send_at` 02:30 UTC, `pipeline_status SCHEDULED`) |
| 5 | Re-check at send time | paid in between → recipients `SKIPPED reason "no longer applies"`; unpaid → `SENT` |
| 6 | Audience = the fee payer only | `std_student_guardian_jnt.is_fee_payer = 1` AND `can_receive_notifications = 1` |
| 7 | Fine applied once per period | `fee_fine_transactions` (`invoice_id`, `fine_rule_id`, `fine_date`); re-running the sweep the same day adds nothing (action is idempotent on invoice + fine date) |
| 8 | Fine notice | `aut_event_log FEE_FINE_APPLIED` → `ntf_notifications FEE_FINE_NOTICE` |
| 9 | Receipt cannot be switched off | AUT-01 shows 🔒 on `PRM_FEE_RECEIPT`; NTF-10 shows 🔒 on Fee receipt; USR-01 cannot mute it |
| 10 | Sweep re-run manually (Run now) | new run row, but `FEE_DUE_IN_DAYS:7381:T-7` already exists → no second reminder |

---

## 3. Example 3 — Teacher leave approved → substitution

**Story:** Mr. Verma's 2-day leave is **approved** in HrStaff. The engine creates his absence in Smart Timetable,
which tells the coordinator a substitute is needed. When the coordinator assigns Ms. Rao, she gets a push
notification on primeadmin.

### 3(a) Flowchart

```mermaid
flowchart TD
    A["HrStaff: hrs_leave_applications status -> APPROVED<br/>employee Verma, 14-15 Oct"] --> B["emit HRS_LEAVE_APPROVED<br/>key HRS_LEAVE_APPROVED:leave_id"]
    B --> C{"PRM_LEAVE_TO_ABSENCE<br/>condition: employee is a teacher"}
    C -- "not a teacher" --> C1["not matched"]
    C -- teacher --> D["record.timetable.create_absence"]
    D --> D1["map employee -> sch_teachers.id"]
    D1 --> D2["tt_teacher_absences 1 row per day<br/>absence_type LEAVE, status APPROVED<br/>substitution_required 1<br/>UNIQUE(teacher_id, absence_date) = idempotent"]
    D2 --> E["emit TT_SUBSTITUTION_NEEDED (depth 1)<br/>periods affected from the published timetable"]
    E --> F["PRM_SUBSTITUTION_NEEDED -> notify SUBSTITUTION_NEEDED<br/>tier HIGH, audience: holders of the substitution permission"]
    F --> G["Coordinator opens Substitute Management<br/>assigns Ms. Rao to P3 VII-B on 14 Oct"]
    G --> H["tt_substitution_logs row<br/>emit TT_SUBSTITUTE_ASSIGNED"]
    H --> I["PRM_SUBSTITUTE_ASSIGNED -> notify SUBSTITUTE_ASSIGNED<br/>tier HIGH, audience user = Ms. Rao<br/>push to primeadmin + in-app"]
    A2["Leave later CANCELLED"] --> J["emit HRS_LEAVE_CANCELLED (future: a rule cancels the absence)"]
```

### 3(b) Sequence

```mermaid
sequenceDiagram
    participant HR as HrStaff approver
    participant W as Workers
    participant TT as Smart Timetable tables
    participant C as Coordinator
    participant S as Ms. Rao (primeadmin)

    HR->>W: approve leave -> emit HRS_LEAVE_APPROVED
    W->>TT: create_absence: tt_teacher_absences 14-Oct, 15-Oct
    W->>W: emit TT_SUBSTITUTION_NEEDED
    W->>C: notify SUBSTITUTION_NEEDED (bell + push)
    C->>TT: assign Ms. Rao for P3 VII-B (tt_substitution_logs)
    TT->>W: emit TT_SUBSTITUTE_ASSIGNED
    W->>S: notify SUBSTITUTE_ASSIGNED (push, high priority)
```

### 3(c) Steps to check

| # | What happens | Look at |
|---|---|---|
| 1 | Approval logged | `hrs_leave_applications.status`; `aut_event_log HRS_LEAVE_APPROVED` |
| 2 | Condition filters non-teachers | an approved leave for an accountant → run absent (`not matched`) |
| 3 | Absences created, once | `tt_teacher_absences` (2 rows, `uq_ta_teacher_date` keeps re-runs harmless); run `result_json {"absence_ids":[…]}` |
| 4 | Chained event | `aut_event_log TT_SUBSTITUTION_NEEDED` (`source ACTION`, `depth 1`, same `chain_id`) |
| 5 | Coordinator told | `ntf_notifications SUBSTITUTION_NEEDED` → recipients = users holding the permission |
| 6 | Substitute told | `tt_substitution_logs` row → `aut_event_log TT_SUBSTITUTE_ASSIGNED` → push to Ms. Rao's `ntf_user_devices` (`app PRIMEADMIN`) |
| 7 | Snapshot-safe | if the timetable is an old snapshot (PUBLISHED, detached) the absence still works (snapshot plan D9) |

---

## 4a. Example 4a — Diwali greeting (schedule → notification only)

**Story:** The School Admin codes the 2026 Diwali holiday as `DIWALI` and creates one schedule. On 8 Nov at 09:00
every guardian and staff member gets a greeting. Next year it fires again once the 2027 holiday row is coded.

```mermaid
flowchart TD
    H["sch_holidays: 'Deepavali' 2026-11-08<br/>holiday_code = DIWALI"] --> S["aut_schedules 'Diwali greeting'<br/>when HOLIDAY DIWALI 09:00, offset 0<br/>what RUN_ACTION notify FESTIVAL_GREETING<br/>audience all guardians + all staff"]
    S --> N["NextRunCalculator<br/>next DIWALI row after now -> 2026-11-08 09:00 IST<br/>= 03:30 UTC -> ZADD aut:due"]
    N --> P["08-Nov 03:30 UTC: pump"]
    P --> R["aut_schedule_runs (schedule, 2026-11-08 03:30)<br/>UNIQUE: fires once"]
    R --> A["aut_action_runs owner S&lt;id&gt; -> notify"]
    A --> O["ntf_notifications FESTIVAL_GREETING<br/>tier SCHEDULED, ~3,140 people, 16 chunks of 200<br/>lane cap 2 per school"]
    O --> D["delivered: in-app + push + WhatsApp (if connected)"]
    R --> X{"next DIWALI row after<br/>2026-11-08?"}
    X -- "2027 row coded" --> Y["next_run_at 2027-10-29 09:00 IST"]
    X -- "not yet" --> Z["next_run_at NULL<br/>waiting_reason 'No DIWALI date after 08-Nov-2026'<br/>dashboard card"]
```

| # | What happens | Look at |
|---|---|---|
| 1 | Holiday coded | `sch_holidays.holiday_code = DIWALI` |
| 2 | Schedule computed in IST | `aut_schedules.next_run_at = 2026-11-08 03:30:00` (UTC), `timezone Asia/Kolkata`; AUT-05 preview shows 09:00 IST |
| 3 | Fires once | `aut_schedule_runs` one row for that `planned_at` (pump restarts cannot repeat it) |
| 4 | No rule needed | `aut_action_runs.schedule_id` set, `rule_id` NULL |
| 5 | Big send stays fair | `ntf_notifications.next_chunk` advances 0 → 15; another school's sends interleave (lane cap) |
| 6 | Next year | after the run: `waiting_reason` set until a 2027 row has `holiday_code DIWALI` |

---

## 4b. Example 4b — Attendance below 75 % (weekly sweep, once per crossing)

**Story:** Every Monday 08:00 the weekly check computes each student's attendance for the session. A student who
**drops below 75 %** triggers a guardian message once. Below 65 % it also opens a counselling concern in
BehaviouralAssessment. Nothing more is sent while the student stays below. Recovering above 80 % sends one
"recovered" message.

```mermaid
flowchart TD
    S["aut_schedules PRM_ATTENDANCE_WEEKLY<br/>WEEKLY Mon 08:00 -> emit ATTENDANCE_WEEKLY_SWEEP"] --> E["aut_event_log ATTENDANCE_WEEKLY_SWEEP"]
    E --> R["PRM_ATTENDANCE_EVALUATE<br/>record.attendance.evaluate_threshold<br/>threshold 75, recover_at 80"]
    R --> C["per student: % present from std_student_attendance<br/>(academic_session_id, status) in chunks of 500"]
    C --> D{"aut_condition_state<br/>ATTENDANCE_BELOW_THRESHOLD<br/>previous state?"}
    D -- "OK -> now 72 %" --> F["state BELOW since today<br/>emit STUDENT_ATTENDANCE_BELOW (value 72.0)"]
    D -- "BELOW -> still 70 %" --> G["update state_value only<br/>emit nothing (no repeat alert)"]
    D -- "BELOW -> now 82 %" --> H["state OK<br/>emit STUDENT_ATTENDANCE_RECOVERED"]
    D -- "OK -> still OK" --> I["nothing"]
    F --> F1["PRM_ATTENDANCE_LOW_NOTIFY -> notify ATTENDANCE_LOW<br/>to guardians, category THR"]
    F --> F2{"PRM_ATTENDANCE_LOW_BA<br/>condition value < 65?"}
    F2 -- yes --> F3["record.ba.open_concern<br/>ba_incidents (category ATTENDANCE)<br/>+ ba_incident_intervention_jnt COUNSELLING"]
    F2 -- no --> F4["not matched"]
    H --> H1["(school rule) notify ATTENDANCE_RECOVERED"]
```

| # | What happens | Look at |
|---|---|---|
| 1 | Weekly firing | `aut_schedule_runs` (Monday 02:30 UTC) |
| 2 | Students evaluated in chunks | run `result_json {"evaluated":1758,"crossed_below":9,"recovered":3}` |
| 3 | First crossing only | `aut_condition_state` (`condition_code ATTENDANCE_BELOW_THRESHOLD`, `state BELOW`, `since`); one `STUDENT_ATTENDANCE_BELOW` per student per crossing |
| 4 | Next Monday, still below | `state_value` updated, **no** new event |
| 5 | Guardian alert | `ntf_notifications ATTENDANCE_LOW` (dedupe `ATTENDANCE_LOW:<student>:<since>`) |
| 6 | Counselling below 65 % | `ba_incidents` row for the student (open question O4: category to seed) |
| 7 | Recovery | `state OK` + `STUDENT_ATTENDANCE_RECOVERED` (a school can add a rule on it) |

---

## 5. How the examples combine the building blocks

| Example | Event source | Rule conditions | NOTIFY | RECORD | FOLLOW_UP | Chained events | Re-check at send |
|---|---|---|---|---|---|---|---|
| 1 Admission | module emit | — | ✅ welcome, reminder | ✅ library member | ✅ 7 days | ✅ DOCS_PENDING | ✅ documents missing |
| 2 Fees | schedule (sweep) | — | ✅ reminder, fine, receipt | ✅ late fine | — | ✅ DUE_IN_DAYS, FINE_APPLIED | ✅ invoice unpaid |
| 3 Leave | module emit | ✅ is a teacher | ✅ coordinator, substitute | ✅ timetable absence | — | ✅ SUBSTITUTION_NEEDED | — |
| 4a Diwali | holiday schedule | — | ✅ greeting | — | — | — | — |
| 4b Attendance | schedule (sweep) | ✅ value < 65 | ✅ low / recovered | ✅ BA concern | — | ✅ BELOW / RECOVERED | — (state table) |

Every combination uses the same two paths in §0. No example needs a module-specific engine.
