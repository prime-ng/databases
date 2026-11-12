# ExamPlanning module: plan, system design and requirements (v1.0)

**Date:** 2026-11-03 · **Status:** PLAN for review. Nothing is built yet.
**DDL:** [ExamPlanning_DDL_v1.0.sql](ExamPlanning_DDL_v1.0.sql) (same folder). It has 29 tables with the prefix `exp_` and was test-run on MySQL 8 against the real parent tables of the `inspiration` tenant: all 29 tables and all seed rows were created.

---

## 0. Decisions you took (2026-11-03)

| # | Decision | Choice |
|---|---|---|
| D1 | v1 scope | All four parts: **Date sheet generation**, **Seating plan**, **Invigilator duties**, **Printouts & notices** |
| D2 | Where the exam schedule lives | **Own sheet + import.** ExamPlanning keeps its own sittings. Papers can be imported from LmsExam (`lms_exam_papers`) or typed by hand, so offline, board and pre-board exams work too |
| D3 | Mixing students in a room | **Configurable rules.** A rule set per exam plan, each rule HARD or SOFT with a weight |
| D4 | Room layout | **Grid + blocked seats.** Rows × columns × seats-per-bench, and single seats or benches can be blocked |
| D5 | Table prefix | **`exp_`** |
| D6 | Day structure | **Configurable slots.** 1..N slots a day, with classes optionally limited to certain slots |
| D7 | Special needs in v1 | **All four.** Separate room (scribe/reader/isolation), accessible room (mobility), extra time, admin seat pins |
| D8 | Solver | **Google OR-Tools CP-SAT** (Apache-2.0), with a greedy fallback |
| D9 | Invigilators per room | **Ratio + minimum**, plus flying squad and relievers per sitting |
| D10 | Invigilator rules | **Not own subject**, **leave & availability**, **fair duty spread**, **not own class** |
| D11 | Date-sheet rules | **No student clash**, **gap before major papers**, **holidays skipped**, **room capacity per slot** |

---

## 1. What the module does

A school's exam cell runs the same cycle for every exam (UT, Half Yearly, Pre-Board, Annual):

1. **Date sheet:** decide which paper is written on which day and in which slot.
2. **Seating plan:** for each sitting, put every candidate in a room and on an exact seat, so that students who could copy from each other never sit together.
3. **Invigilation:** put enough teachers in every room, fairly, without a teacher guarding their own subject or their own class.
4. **Printouts & notices:** produce the door lists, seat maps, desk stickers, attendance sheets, seat slips and duty letters, and tell students, parents and teachers.

ExamPlanning does all four. A Python engine solves steps 1-3 as constraint problems. Laravel owns the data, the screens, the manual edits, the locks, publishing and printing.

**Out of scope for v1** (the DDL already has room for them):
- room-wise attendance marking and the UFM (unfair means) register. The columns exist on `exp_seat_allocations` (`attendance_status`, `answer_sheet_no`), but no screen marks them yet
- answer-booklet stock and reconciliation
- external (board) centre allotment
- paper-packet distribution

---

## 2. Data it reuses (read-only, never altered)

| Need | Source table(s) | Notes |
|---|---|---|
| Academic session | `sch_org_academic_sessions_jnt` (SMALLINT id) | Same FK target as `std_student_academic_sessions`. **Open question Q3** |
| Classes / sections | `sch_classes`, `sch_sections`, `sch_class_section_jnt` | `actual_total_student` is shown only as a hint. The real candidate list is built from students |
| Students per section | `std_student_academic_sessions` (`class_section_id`, `roll_no`, `is_current`, `session_status_id`) | Only current, active students. `roll_no` sets the seat-fill order |
| Optional subjects (XI-XII, 2nd language) | `std_student_opted_subjects` | A paper with `audience_type = OPTED_ONLY` gets only the students who opted for it. This drives the "no student clash" rule |
| Rooms | `sch_rooms` (`can_host_exam`, `capacity`, `max_limit`), `sch_buildings` | Only rooms with `can_host_exam = 1` can be given an exam layout |
| Holidays | `sch_holidays` | Pre-fills `exp_plan_days` with HOLIDAY rows |
| Teachers / staff | `sch_employees`, `sch_teacher_profile` | Duties are anchored on `employee_id`, so non-teaching staff can be added later (Q4) |
| Who teaches what | `tt_timetable_cells` + `tt_timetable_cell_teachers` (published timetable). Fallback: `sch_teacher_capabilities` | Used by the "not own subject" rule. **Q2** |
| Class teacher | `sch_class_section_jnt.class_teacher_id` (sys_users), `sch_teacher_profile.class_teacher_of_*` | Used by the "not own class" rule |
| Leave | `sch_employee_leave_applications` (`from_date`, `to_date`, `is_half_day`, `half_day_slot`, `status`) | Approved leave blocks duty. A half-day leave maps to the matching slot |
| LmsExam link (optional) | `lms_exam_types`, `lms_exams`, `lms_exam_papers` | Import papers. Optional write-back to `lms_exam_allocations` (**Q1**) |

**Type trap found while test-running the DDL:** in the live tenant DB, `sch_subjects.id` is **BIGINT UNSIGNED**, but the SchoolSetup DDL file v4.7 says INT. The `exp_` DDL follows the live DB. The SchoolSetup DDL file should be corrected separately.

---

## 3. Workflow (what the exam cell does, screen by screen)

```
 ┌────────────┐   ┌─────────────┐   ┌──────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────────┐
 │ 1. Create  │──▶│ 2. Prepare  │──▶│ 3. Date sheet│──▶│ 4. Seating  │──▶│ 5. Invigil-  │──▶│ 6. Publish │
 │    plan    │   │  (papers,   │   │  Generate /  │   │  Generate / │   │  ation Gen / │   │  print +   │
 │            │   │  students,  │   │  edit / lock │   │  edit / lock│   │  edit / lock │   │  notify    │
 │            │   │  rooms,pool)│   │  [publish DS]│   │             │   │              │   │            │
 └────────────┘   └─────────────┘   └──────────────┘   └─────────────┘   └──────────────┘   └────────────┘
```

1. **Create plan:** session, name/code, date window, weekly-off days, optional LmsExam exam type. Slots are copied from `exp_slot_templates`, rules from `exp_rule_definitions` (with their defaults), and exam rooms from `exp_room_layouts`. "Copy from previous plan" clones the rules, slots, rooms and papers.
2. **Prepare:**
   - pick class-sections
   - papers: import from LmsExam (OFFLINE papers of the matching `lms_exams`) or type them in. Mark major papers, group keys (2nd-language options sit together) and fixed or preferred dates
   - **Build candidates** fills `exp_plan_paper_students` from students and opted subjects. The admin can exempt or add a student
   - review the calendar (holidays and weekly-offs are pre-marked; days can be blocked)
   - mark rooms unavailable on some days
   - build the invigilator pool (all active teachers by default) and add manual unavailability
   - record special needs (`exp_student_needs`)
3. **Date sheet:**
   - **Generate**, then review the grid (rows = dates × slots, columns = classes). Drag a paper to move it, and lock any cell
   - re-generating moves only unlocked papers
   - **Publish date sheet** is allowed early, because parents need it weeks before seating is done
4. **Seating:** generate per plan or per sitting, then review the room seat maps:
   - drag students to swap seats, and pin students
   - re-generating keeps locked rooms and pins
5. **Invigilation:** generate the duty chart and review the teacher × sitting matrix. Swap duties and lock any duty.
6. **Publish:**
   - a snapshot (`exp_plan_snapshots`) freezes the version
   - notices go out through the Notification module (`exp_publications`)
   - all printouts become available
   - a later change creates version N+1 with a "what changed" list, and only affected people get a change notice

### Plan status (state machine, `exp_exam_plans.status`)

```
DRAFT → DATESHEET_READY → DATESHEET_PUBLISHED → SEATING_READY → INVIGILATION_READY → PUBLISHED → IN_PROGRESS → CONCLUDED → ARCHIVED
           ▲    (any edit to an earlier stage drops the status back to that stage and marks later stages stale)
```

Editing a published stage is allowed, but it always creates a new snapshot version, and it is never a silent overwrite.

---

## 4. System design

### 4.1 Components

```
                     Laravel (tenant request / queue worker)                          Python engine
 ┌──────────────────────────────────────────────────────────────────────┐      ┌──────────────────────────────┐
 │ Modules/ExamPlanning                                                 │      │ exam_engine (OR-Tools CP-SAT) │
 │  Controllers (tabs)  ─▶ Services:                                    │      │  main.py   (stage dispatcher) │
 │                          ExpPlanSetupService   (create/copy/prepare) │      │  datesheet.py                 │
 │                          ExpCandidateBuilder   (paper students)      │ JSON │  seating.py  + fill.py        │
 │                          ExpInputBuilder       (per stage)    ───────┼─────▶│  invigilation.py              │
 │                          ExpEngineRunner  (local | http) ◀───────────┼──────│  rules/ registry (code→class) │
 │                          ExpResultApplier (transaction, keeps locks) │ JSON │  diagnostics.py (infeasible   │
 │                          ExpPublishService (snapshot + notify)       │      │     core → human messages)    │
 │                          ExpPrintService   (dompdf / mpdf)           │      │  greedy.py (fallback)         │
 │  Jobs: GenerateExamPlanJob (queue 'engines') ─ progress → cache      │      └──────────────────────────────┘
 │  Generate modal polls the cache snapshot (same as the timetable)     │        local: Modules/ExamPlanning/python/.venv
 └──────────────────────────────────────────────────────────────────────┘        http:  docker/engines/exam (port 8093)
```

- **Engine plumbing is the same as the timetable and transport engines** (`config/engines.php`). It adds a third entry, `'exam' => ['url' => env('ENGINE_EXAM_URL','http://127.0.0.1:8093'), 'driver' => env('ENGINE_EXAM_DRIVER')]`, and a `docker/engines/exam/` image on top of `prime-engine-base` that adds `ortools`.
  - `local` mode runs the module's own venv
  - `http` mode posts to `/jobs`, polls `GET /jobs/{id}`, and uses `DELETE` to cancel
- **One queued job per stage run** (`GenerateExamPlanJob`, queue `engines`). The browser never waits on the solver.
- **The DB is the record.** The engine only gets an input JSON and returns an output JSON. It never touches MySQL. This keeps it tenant-safe, testable from files, and replayable: the input path is stored on `exp_generation_runs.input_path`.
- **Apply step:** in one transaction, `ExpResultApplier` deletes the unlocked `source = ENGINE` rows of that stage (and scope), inserts the new rows, and writes `exp_run_issues`. Locked rows and MANUAL or PIN rows are never deleted. They go to the engine as fixed inputs.
- **Live progress:** the job writes a progress snapshot to the cache. The Generate modal polls it, with the same NullSessionHandler-on-poll pattern used for timetable generation.

### 4.2 Why three stages instead of one big model

The three problems are only loosely coupled: the date sheet fixes the sittings, the sittings fix who needs a seat, and the seats fix which rooms need invigilators. Solving them in sequence:
- keeps each CP-SAT model small: seconds, not minutes, for a ~2,000-student school
- lets the exam cell publish the date sheet weeks before seating
- lets one sitting be re-planned (a room collapses, a teacher falls ill) without touching the rest. `exp_generation_runs.scope_sitting_id` handles this

The one coupling that has to flow backwards is **seat capacity per slot**. The date-sheet stage already enforces it (`DS_SLOT_SEAT_CAPACITY`, with a % buffer for special rooms and blocked seats), so seating will not hit a room shortage later.

---

## 5. Engine logic

### 5.1 Stage 1: date sheet (CP-SAT)

- **Variables:** `x[p, d, s] ∈ {0,1}` means paper *p* is written on exam day *d* in slot *s*. Only EXAM_DAY dates and allowed slots create variables.
- **HARD:**
  - every paper is placed exactly once
  - fixed date and slot pins are honoured, and so are locked rows
  - **no student clash:** a conflict graph is built from `exp_plan_paper_students`. Two papers conflict if they share at least one student, and conflicting papers never share a sitting. Because options are per student, XI-XII choices are handled exactly, not by class
  - max papers per student per day
  - `group_key` papers share a sitting
  - **seat capacity:** Σ candidates in a sitting ≤ usable seats of the available rooms × (1 − buffer)
  - **major gap:** two major papers of the same student group need ≥ *g* full days between them. Weekly-offs can count or not (param)
- **SOFT (objective, weighted):**
  - preferred dates
  - spread each class's papers evenly (penalise squared gaps from the ideal spacing)
  - finish early (optional)
- **Size:** about 15 classes × 8 papers = 120 papers, × 15 days × 2 slots ≈ 3,600 booleans. CP-SAT solves it in under 5 s.

### 5.2 Stage 2: seating (CP-SAT on "lanes", then a deterministic fill)

A seat-level model (2,000 students × 2,000 seats = 4M variables) is too large and isn't needed. Indian exam halls are organised by **column and bench position**, so the engine works on **lanes**.

> A **lane** is the line of seats front-to-back at one (column, seat position) in a room. A 6×4 room with dual desks has 8 lanes of 6 seats each.

- **Groups:** a group is the set of students who must not sit next to each other. Rule param `separate_by` decides it: PAPER (default), CLASS or SECTION. Students with seating needs are taken out into sub-groups first.
- **Variables:**
  - `a[g, l] ∈ {0,1}`: group *g* uses lane *l*
  - `n[g, l]`: how many students of *g* sit in *l*
  - `open[r]`: room *r* is used
- **HARD:**
  - Σ students in a lane ≤ usable seats in that lane (blocked seats removed)
  - each group is fully seated
  - **side by side (`ST_NO_ADJ_SIDE`):** for lanes *l*, *l'* that are neighbours on the same bench, or across the gap between benches (param `across_aisle`), `a[g,l] + a[g,l'] ≤ 1`
  - **front/back (`ST_NO_ADJ_FRONT_BACK`):** if this rule is on, a lane takes **two** groups in alternating rows (A B A B…), and each group gets at most ⌈rows/2⌉ seats there. If it is off, a lane holds one group. Diagonal is an optional extra pairwise constraint
  - special room, accessible room and pins: sub-groups and pinned students may only use the allowed lanes or seats
- **SOFT:**
  - open few rooms (`ST_MIN_ROOMS`)
  - keep a section in few rooms
  - group extra-time students
  - front-row needs
  - not in their own house room
  - stable seat across sittings
- **Fill (Python, deterministic):** inside each lane, students are placed front to back in roll-number order (`ST_ROLL_ORDER`), alternating if the lane is two-group. Then `seat_label` is rendered from `exp_room_layouts.seat_label_format` (e.g. `11G-10A-R02-C3-L`).
- **Size:** about 30 groups × 300 lanes ≈ 10k booleans per sitting. Each sitting solves in seconds, and sittings are independent, so they can run in parallel.

**Special needs, solved first inside each sitting:**

| Need | Effect |
|---|---|
| SCRIBE / READER / MEDICAL_ISOLATION | Only rooms with `is_special_room = 1`. Scribe/reader also block the next seat for the companion. Mixing rules are relaxed in these rooms because they hold a handful of students |
| MOBILITY | Only rooms with `is_accessible = 1` |
| EXTRA_TIME | Mode `SEPARATE_ROOM` (all in extra-time rooms) or `SAME_ROOM_ALLOWED`. The room's `end_time` becomes the latest end time of its occupants, and its invigilators are held longer |
| LOW_VISION | Front rows (`max_row` param), SOFT |

### 5.3 Stage 3: invigilation (CP-SAT)

- **Requirement per room:** `max(min_per_room, ceil(students / ratio)) + special_room_extra`. A room can override it (`exp_room_layouts.default_invigilators`). Each sitting also gets *k* flying squad and relievers per N rooms.
- **Variables:** `y[t, r] ∈ {0,1}` means person *t* is in room *r* of sitting *s*. `z[t, s, role]` covers roving roles.
- **HARD:**
  - each requirement is met
  - one place per person per sitting
  - **leave & availability:** approved leave (half-day leave maps to a slot), manual blocks, and people not in the pool
  - **not own subject:** *t* teaches (class, subject) of any paper in room *r*. The source is the published timetable, falling back to capabilities (Q2)
  - **not own class:** *t* is class teacher of a section seated in *r*
  - max duties per day and per plan
- **SOFT:**
  - **fairness:** minimise (max − min) duties over the pool, weighted per person's `max_duties_total`
  - rotate rooms and partners
  - gender mix (off by default; Q6)
- **Size:** about 80 teachers × 40 rooms × 15 sittings ≈ 48k booleans, but most are pruned by hard filters before the model is built. Solves in seconds.

### 5.4 When the rules can't all be met

Every HARD rule is attached to the model through an **assumption literal** (CP-SAT `AddAssumptions`). If the solve is INFEASIBLE, `SufficientAssumptionsForInfeasibility()` returns the minimal set of rules that clash. `diagnostics.py` turns that into plain messages in `exp_run_issues`, for example:

> "Class X needs 6 major papers with a 1-day gap, but only 9 exam days exist. Relax DS_MAJOR_GAP to SOFT, or add 2 exam days."

The run is saved as `INFEASIBLE` and nothing is applied. If the time limit runs out before an optimum, the best solution found is applied as `PARTIAL`, and the issues are listed. If CP-SAT returns nothing within the limit, a greedy fallback (`solver = 'GREEDY'`) produces a feasible-if-possible draft and states that it is not optimised.

`relax_priority` on each rule orders the suggestions: capacity-type rules are never suggested; gaps and adjacency are suggested first.

---

## 6. Rule catalogue (seeded in `exp_rule_definitions`, 34 rules)

| Stage | Code | Default | Params |
|---|---|---|---|
| DS | DS_NO_STUDENT_CLASH | HARD only | |
| DS | DS_MAX_PAPERS_PER_DAY | HARD | `max:1` |
| DS | DS_MAJOR_GAP | HARD | `min_gap_days:1, count_weekly_off:false` |
| DS | DS_SKIP_NON_EXAM_DAYS | HARD only | |
| DS | DS_SLOT_SEAT_CAPACITY | HARD only | `seat_buffer_pct:5` |
| DS | DS_CLASS_ALLOWED_SLOTS | HARD only | |
| DS | DS_GROUP_TOGETHER | HARD only | |
| DS | DS_PREFERRED_DATE / DS_SPREAD_EVENLY / DS_FINISH_EARLY (off) | SOFT | |
| ST | ST_ROOM_CAPACITY | HARD only | |
| ST | ST_NO_ADJ_SIDE | HARD | `separate_by:PAPER, across_aisle:false` |
| ST | ST_NO_ADJ_FRONT_BACK | SOFT | `separate_by` |
| ST | ST_NO_ADJ_DIAGONAL (off) | SOFT | `separate_by` |
| ST | ST_SPECIAL_ROOM / ST_ACCESSIBLE_ROOM / ST_PINS | HARD only | |
| ST | ST_EXTRA_TIME_GROUPING | SOFT | `mode:SEPARATE_ROOM` |
| ST | ST_FRONT_ROW_NEED | SOFT | `max_row:2` |
| ST | ST_ROLL_ORDER / ST_MIN_ROOMS / ST_KEEP_SECTION_TOGETHER | SOFT | |
| ST | ST_NOT_HOME_ROOM (off) / ST_STABLE_SEAT (off) | SOFT | |
| IV | IV_RATIO | HARD only | `students_per_invigilator:30, min_per_room:1, special_room_extra:0` |
| IV | IV_FLYING_SQUAD | HARD | `flying_squad:1, relievers_per_rooms:10` |
| IV | IV_ONE_PLACE | HARD only | |
| IV | IV_LEAVE_AVAILABILITY | HARD only | `leave_statuses:[Approved]` |
| IV | IV_NOT_OWN_SUBJECT | HARD | `source:TIMETABLE_THEN_CAPABILITY` |
| IV | IV_NOT_OWN_CLASS | HARD | |
| IV | IV_MAX_DUTIES | HARD | `per_day:1, per_plan:null` |
| IV | IV_FAIR_SPREAD | SOFT only | |
| IV | IV_ROTATE_ROOMS (off) / IV_GENDER_MIX (off) | SOFT | |

A plan can hold the same rule more than once with `scope_class_id`. For example, a 2-day major gap for Class X only, while the plan-wide rule says 1 day.

---

## 7. Data model (29 tables)

| Group | Tables | Purpose |
|---|---|---|
| **Masters** (shared by all plans) | `exp_rule_definitions`, `exp_need_types`, `exp_room_layouts`, `exp_room_blocked_seats`, `exp_slot_templates`, `exp_print_templates`, `exp_student_needs` | Rule catalogue, needs catalogue, room grids, reusable slots, print templates, student needs per session |
| **Plan setup** | `exp_exam_plans`, `exp_plan_class_sections`, `exp_plan_slots`, `exp_plan_slot_classes`, `exp_plan_days`, `exp_plan_papers`, `exp_plan_paper_students`, `exp_plan_rules`, `exp_plan_rooms`, `exp_plan_room_blocks`, `exp_plan_invigilators`, `exp_invigilator_blocks` | Everything the engine needs, frozen per plan |
| **Engine runs** | `exp_generation_runs`, `exp_run_issues` | Audit, replay, live progress, infeasibility explanations |
| **Outputs** | `exp_sittings`, `exp_sitting_papers` (= the date sheet), `exp_sitting_rooms`, `exp_seat_pins`, `exp_seat_allocations` (= the seating plan), `exp_invigilation_duties` (= the duty chart) | What portals and printouts read |
| **Publish** | `exp_plan_snapshots`, `exp_publications` | Versioned published copies and the notice log |

```
exp_exam_plans ─┬─< exp_plan_papers ─< exp_plan_paper_students >─ std_students
                ├─< exp_plan_slots ─< exp_plan_slot_classes
                ├─< exp_plan_days
                ├─< exp_plan_rules >─ exp_rule_definitions
                ├─< exp_plan_rooms >─ exp_room_layouts >─ sch_rooms
                ├─< exp_plan_invigilators >─ sch_employees
                └─< exp_sittings ─┬─< exp_sitting_papers >─ exp_plan_papers         (date sheet)
                                  ├─< exp_sitting_rooms ─< exp_seat_allocations      (seating)
                                  └─< exp_invigilation_duties                        (duties)
```

**Key integrity guarantees (DB-level UNIQUE):**
- a paper sits once: `uq_expSittingPaper_paper`
- a student has one seat per sitting: `uq_expSeatAlloc_sitting_student`
- a seat holds one student: `uq_expSeatAlloc_room_seat`
- a person has one duty per sitting: `uq_expDuty_sitting_employee`
- one sitting per plan × date × slot: `uq_expSitting_plan_date_slot`

**Conventions used:**
- ENUM for code-owned state machines; lookup tables for anything a school may extend
- `source` + `is_locked` + `generation_run_id` on every engine output
- `*_json` columns for forward-compatible settings
- no CHECK constraint on FK columns (errno 3823)
- FK column types match the live DB exactly (errno 3780; see the `sch_subjects` BIGINT note in §2)
- UNIQUE keys that include a NULL-able column don't stop duplicate NULLs in MySQL. The FormRequests enforce those

---

## 8. Engine input/output contract (JSON, versioned)

```jsonc
// input (one stage)
{
  "contract": "exam-engine/1",
  "stage": "SEATING",
  "plan": {"id": 12, "time_limit_s": 60, "seed": 7},
  "rules": [{"code":"ST_NO_ADJ_SIDE","strictness":"HARD","weight":50,"params":{"separate_by":"PAPER"},"scope_class_id":null}],
  "sittings": [{"id": 301, "date":"2026-12-02", "slot":"MORNING",
    "papers":[{"id": 88, "class_id": 10, "subject_id": 4, "duration": 180}],
    "candidates":[{"student_id": 5001, "paper_id": 88, "class_section_id": 41, "roll_no": 7,
                   "needs":["EXTRA_TIME"], "extra_minutes": 20, "home_room_id": 112}],
    "rooms":[{"plan_room_id": 9, "rows":6, "cols":4, "seats_per_bench":2, "aisle_after":[2],
              "blocked":[[1,1,0]], "accessible":true, "special":false, "priority":50}],
    "pins":[{"student_id":5001,"plan_room_id":9,"seat":[2,3,1]}],
    "locked":[ /* rows that must stay */ ]}]
}
// output
{
  "contract": "exam-engine/1", "status": "SUCCEEDED", "solver": "CP_SAT",
  "stats": {"rooms_opened": 38, "objective": 412, "seconds": 3.1},
  "seat_allocations": [{"sitting_id":301,"plan_room_id":9,"student_id":5001,"paper_id":88,"seat":[2,3,1]}],
  "sitting_rooms": [{"sitting_id":301,"plan_room_id":9,"pattern":"LANE_ALTERNATE","end_time":"12:20"}],
  "issues": [{"severity":"WARNING","code":"SOFT_BROKEN","rule":"ST_KEEP_SECTION_TOGETHER","message":"..."}]
}
```

The contract has a version (`exam-engine/1`). A new rule is just a new `code` in `rules[]`. An engine that doesn't know a code returns `RULE_NOT_IMPLEMENTED` as a warning instead of failing.

---

## 9. Screens (tabs) and permissions

Menu: **Examination → Exam Planning**. The pages follow the existing standards: route-name breadcrumbs, the one-line search bar, row actions through `x-backend.table.action`, and the trash tab through `action-trashed`.

| Page / tab | What it does |
|---|---|
| **Masters → Exam Rooms** | Grid editor per room (rows × columns × seats, aisles, block seats by clicking), accessible/special flags, live seat count |
| **Masters → Rules Catalogue** | Read-only list of rule definitions with help text (system rows) |
| **Masters → Need Types / Slot Templates / Print Templates** | Simple CRUD |
| **Masters → Student Needs** | Per-session list, with filter by class |
| **Plans list** | Create / copy / archive plans, with a status badge |
| **Plan → Setup** | Class-sections, slots (+ allowed classes), calendar days, rooms + blocks, invigilator pool + blocks |
| **Plan → Papers** | Import from LmsExam / add, major flag, group key, pins, **Build candidates**, candidate list per paper |
| **Plan → Rules** | Toggle, HARD/SOFT, weight and params (form built from `params_schema_json`), class-scoped copies |
| **Plan → Date Sheet** | Generate modal (live progress), date × slot grid, drag & lock, issues panel, **Publish date sheet** |
| **Plan → Seating** | Per-sitting list → room seat-map view (visual grid, colour per group), swap/pin, issues |
| **Plan → Invigilation** | Teacher × sitting matrix with duty counts, swap, lock, fairness summary |
| **Plan → Publish & Print** | Versions, publish, notices log, every printout (per room / per class / bulk ZIP) |
| **Portals** | Student/parent: my date sheet + my seat per sitting. Teacher: my duties + acknowledge. Read-only, published snapshot only |

**Permissions** follow `scope.module.feature.action`: `tenant.exam-planning.{room-layout|need-type|student-need|plan|paper|rule|datesheet|seating|invigilation|publication}.{view|create|update|delete|generate|publish|print}`. There is a separate `…generate` permission because a run overwrites unlocked rows. The full list is built in the build phase, following the P0 map pattern.

---

## 10. Printouts & notices (v1)

| Output | Content | Per |
|---|---|---|
| Date sheet | Class-wise, with dates, slots and reporting time | class / whole school |
| Room door list | Roll numbers grouped by class-section and paper, with seat ranges | room × sitting |
| Room seat map | Visual grid of the room with each student's roll number on a seat | room × sitting |
| Desk stickers | Name, roll, class, seat label, paper (24/65 per A4 label sheet) | room × sitting, or whole plan |
| Attendance sheet | Roll, name, paper, answer-sheet no. column, signature column; invigilator signature at the end | room × sitting |
| Student seat slip | All sittings of one student with room + seat | student (also on the portal) |
| Invigilator duty letter | All duties of one teacher with room, time and reporting time | teacher (also on the portal) |
| Master duty chart | Teacher × sitting grid | plan (A3) |

PDFs use the stack that is already installed (barryvdh/laravel-dompdf, mpdf). Templates are rows in `exp_print_templates`, so a school can add its own header or layout without code changes to the generator.

Notices go through the Notification module. `exp_publications.channels` covers PORTAL / APP_PUSH / EMAIL / SMS / WHATSAPP. Only channels the Notification module actually supports are offered. A change after publishing sends a **change notice only to the affected people** (diff between snapshots).

---

## 11. How the module stays open to new features

| Want to add… | What it takes |
|---|---|
| A new seating / date / duty rule | 1 row in `exp_rule_definitions` + 1 Python class in `rules/`. **No DDL, no Laravel code**: the Rules tab form is built from `params_schema_json` |
| A new special-needs category | 1 row in `exp_need_types` (flags decide the behaviour) |
| A new printout | 1 Blade view + 1 row in `exp_print_templates` |
| A new solver (e.g. a metaheuristic for very large schools) | New `solver` value, chosen per run. The contract stays the same |
| Irregular rooms (L-shaped halls, auditorium) | `exp_room_layouts.layout_meta_json` + blocked seats already cover most cases. True free-form maps can be added later as a seat-list table without changing outputs |
| Room attendance, UFM register, booklet tracking | Columns are already on `exp_seat_allocations`; a v2 screen is needed |
| Board practical scheduling, external centres | New stage enum values + their own tables, reusing plans, sittings and rooms |
| Multi-campus | Rooms already carry `building_id`; a `campus` rule param scopes groups to buildings |

---

## 12. Open-source survey

**No open-source project covers this whole module** (date sheet + seating + invigilation for K-12, with rules). What exists:

| Project | What it is | Useful for us? |
|---|---|---|
| [Google OR-Tools](https://github.com/google/or-tools) (Apache-2.0) | Constraint/MIP solver suite (CP-SAT) | **Yes, the engine core** (D8) |
| [afreenpoly/Exam-Seat-Arrangement](https://github.com/afreenpoly/Exam-Seat-Arrangement) (MIT) | Flask app: upload timetable + students → seat arrangement | Reference only: fixed mixing logic, no rules, no invigilators |
| [legion0069/examseatingpython](https://github.com/legion0069/examseatingpython) (MIT) | Streamlit: rooms as rows × cols, assign faculty, CSV export | Reference for the room grid UI; fixed logic |
| [cs3157/seatingcharts](https://github.com/cs3157/seatingcharts) | Scripts: randomized seating per room, split roster across rooms, email seat | Reference for the "split across rooms" step |
| [novoid/GenerateSeatingplan.py](https://gh.r-mj.com/novoid/GenerateSeatingplan.py) (GPL-2+) | Randomized seat plan for one lecture hall → PDF/HTML | GPL, so don't copy code. Idea reference only |
| [sudharson-c/ExamHallGenerator](https://github.com/sudharson-c/ExamHallGenerator) | Node web app: rows/cols from count + capacity → PDF | Reference only |
| [dangnm9699/semester-exam-scheduling](https://github.com/dangnm9699/semester-exam-scheduling) | OR-Tools (Java) course project: exams → slots + rooms, conflict pairs, minimise days | **Closest to our Stage 1.** Confirms the CP-SAT formulation |
| [gabrielecuni/examination-timetabling-problem](https://github.com/gabrielecuni/examination-timetabling-problem) (Apache-2.0) | Python local-search exam timetabling (ITC-style) | Possible greedy/metaheuristic fallback ideas |
| Tablix | Old general school timetabling (C) | Not useful (unmaintained, no seating) |
| Invigilator assignment literature (e.g. the [Nottingham thesis](https://eprints.nottingham.ac.uk/27677/1/598041.pdf)) | MIP + heuristics, invigilation as a separate step after rooms | Confirms the 3-stage split and the fairness objective |

**Conclusion:** build our own engine on OR-Tools CP-SAT. The seating apps are small and hard-code one mixing pattern, and none handle rules, special needs or invigilators. Their licences (MIT/GPL) also don't matter, because no code is reused.

---

## 13. Open questions for your review

| # | Question | My default if you agree |
|---|---|---|
| **Q1** | On publish, should ExamPlanning **write back** the date/time/room into LmsExam's `lms_exam_allocations` for linked papers? (This is a cross-module write) | Off by default; a per-plan switch `sync_to_lms`. It writes only for papers that have `lms_exam_paper_id`, and only CLASS/SECTION allocations |
| **Q2** | "Not own subject": should the source be the **published timetable** (exact teacher × class-section × subject) or `sch_teacher_capabilities` (can teach, class level)? | Timetable first, capabilities as fallback when no timetable is published |
| **Q3** | Academic session FK: `sch_org_academic_sessions_jnt` (student side, SMALLINT) or `glb_academic_sessions` (LmsExam side)? | `sch_org_academic_sessions_jnt`, which is what the DDL uses |
| **Q4** | Invigilator pool in v1: teachers only, or all staff? | DDL supports all staff (`employee_id`). v1 defaults the pool to active teachers, and staff can be added by hand |
| **Q5** | Same seat across all sittings of a plan (`ST_STABLE_SEAT`)? This makes stickers reusable but weakens mixing | Off by default |
| **Q6** | Female invigilator where girls sit (`IV_GENDER_MIX`)? | Rule exists, off by default |
| **Q7** | Room attendance + UFM marking in v1 or v2? | v2 (columns exist) |
| **Q8** | Which notice channels must work at launch? | Portal + app push in v1; email/SMS/WhatsApp follow the Notification module |
| **Q9** | Module location: a new `Modules/ExamPlanning` (own menu under Examination), with the engine at `Modules/ExamPlanning/python` + `docker/engines/exam` | Yes |

---

## 14. Build phases (after you approve)

| Phase | Deliverable |
|---|---|
| **P0** | Answers to Q1-Q9 → DDL v1.1 if anything changes |
| **P1** | Module skeleton, migrations (from this DDL), models, seeders (rules, need types, slots, print templates), permissions, menu |
| **P2** | Masters: Exam Rooms grid editor, Need Types, Student Needs, Slot / Print templates |
| **P3** | Plan setup + Papers (LmsExam import, candidate builder) + Rules tab |
| **P4** | Python engine skeleton (contract, rule registry, local + http driver, `docker/engines/exam`) + **Stage 1 date sheet** + Generate modal + date sheet grid |
| **P5** | **Stage 2 seating** + seat-map view, swap/pin |
| **P6** | **Stage 3 invigilation** + duty matrix |
| **P7** | Publish, snapshots, change diff, notices, all printouts, portal views |
| **P8** | Test on the Inspiration tenant (real rooms and students): timing, infeasible-case messages, printouts |
