# SmartTimetable — Final Execution Process Flow
**Module:** `Modules/SmartTimetable`
**Last Updated:** 2026-03-03
**Branch:** `Brijesh-timetable`
**Base URL:** `https://<your-domain>/smart-timetable/`

---

## How to Read This Document

- **[ONE-TIME]** — Do this once per school/installation. Never repeat.
- **[PER TERM]** — Repeat at the start of every new academic term.
- **[PER RUN]** — Repeat every time you generate a new timetable (e.g. revised timetable).
- **[DAILY]** — Ongoing operational tasks during term.
- **✅ Required** / **⚠️ Optional** / **🔄 Auto** — Step type indicator.
- `Route Name` — Laravel named route for direct navigation.

---

## OVERVIEW — Full Sequence at a Glance

```
[ONE-TIME]
Phase 0  →  System Config + Master Data Setup

[PER TERM]
Phase 1  →  Academic Term + Timetable Structure
Phase 2  →  Requirements Generation
Phase 3  →  Resource Availability + Constraints
Phase 4  →  Validation (Requirement vs Availability)

[PER RUN]
Phase 5  →  Activity Creation + Prioritization
Phase 6  →  Timetable Generation (Async Job)
Phase 7  →  Post-Generation Analytics & Review
Phase 8  →  Manual Refinement (if needed)
Phase 9  →  Publication & Locking

[DAILY]
Phase 10 →  Substitution Management

[ANYTIME]
Phase 11 →  Standard Timetable Views (Published Timetable)
```

---

## PHASE 0: ONE-TIME SYSTEM SETUP

> **When:** Before using the timetable module for the first time. Never repeat.
> **Who:** System Administrator

---

### 0.1 Run Database Seeders ✅ Required

These populate master lookup tables. Run once after deployment.

```bash
# From Laravel root
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\TtConfigSeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\ConstraintCategorySeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\ConstraintScopeSeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\ConstraintTargetTypeSeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\ConstraintTypeSeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\GenerationStrategySeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\PeriodTypeSeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\DayTypeSeeder
php artisan db:seed --class=Modules\\SmartTimetable\\Database\\Seeders\\SchoolDaySeeder
```

**Populates:**
| Table | Records Created |
|-------|----------------|
| `tt_config` | ~20 system config parameters |
| `tt_constraint_category_scope` | 6 categories × 4 scopes |
| `tt_constraint_types` | 24+ standard constraint types |
| `tt_generation_strategies` | RECURSIVE, TABU, SA, HYBRID, GENETIC |
| `tt_period_types` | TEACHING, LAB, BREAK, LUNCH, ASSEMBLY, FREE |
| `tt_day_types` | STUDY_DAY, EXAM_DAY, HOLIDAY, PTM_DAY, SPORTS_DAY |
| `tt_school_days` | Mon–Sat school day template |

---

### 0.2 Setup School Shifts ✅ Required

**URL:** `GET /smart-timetable/shift`
**Route:** `smart-timetable.shift.index`

Create at least one shift:
- **MORNING** — 07:30 to 13:30
- **AFTERNOON** — 12:00 to 18:00 (if applicable)

> **Dependency:** Timetable Types (Phase 1.2) require a Shift.

---

### 0.3 Setup Teacher Assignment Roles ✅ Required

**URL:** `GET /smart-timetable/teacher-assignment-role`
**Route:** `smart-timetable.teacher-assignment-role.index`

Seeder pre-populates: PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE. Edit if needed.

---

### 0.4 Confirm School Master Data ✅ Required

Verify these exist in the School Setup module **before** starting timetable:
- `sch_buildings` + `sch_rooms` (with room_type, capacity)
- `sch_subjects` + `sch_study_formats` + `sch_subject_study_format_jnt`
- `sch_classes` + `sch_sections` + `sch_class_section_jnt`
- `sch_teachers_profile` (with max/min periods per week, shift preference)
- `sch_teacher_capabilities` (teacher-subject-format assignment with effective dates)
- `sch_class_groups_jnt` (class-section-subject-format mapping)

> **Critical:** `sch_teacher_capabilities` effective dates must overlap with the timetable term dates.

---

## PHASE 1: ACADEMIC TERM & TIMETABLE STRUCTURE [PER TERM]

> **When:** Start of every new academic term.
> **URL Hub:** `GET /smart-timetable/timetable-config`
> **Route:** `timetable.timetableConfig`

---

### 1.1 Create Academic Term ✅ Required

**URL:** `GET /smart-timetable/academic-term`
**Route:** `smart-timetable.academic-term.index`

**Create / Select:**
- `academic_session_id` — link to the active academic session
- `term_name`, `term_code`, `term_ordinal`
- `term_start_date`, `term_end_date`
- `term_total_periods_per_day`, `term_total_teaching_periods_per_day`
- `term_week_start_day` (1 = Monday, ISO standard)
- Mark `is_current = true` for the active term

> **Validation:** No overlapping terms in same session. `term_start < term_end`.

---

### 1.2 Create Timetable Type ✅ Required

**URL:** `GET /smart-timetable/timetable-type`
**Route:** `smart-timetable.timetable-type.index`

Defines the schedule pattern (STANDARD, EXAM, HALF_DAY, etc.):
- `shift_id` — link to the school shift
- `max_weekly_periods_per_teacher` (default: 48)
- `min_weekly_periods_per_teacher` (default: 15)
- `effective_from_date`, `effective_to_date`
- Mark `is_default = true` for the main type

---

### 1.3 Create Period Set + Periods ✅ Required

**Step A — Create Period Set:**
**URL:** `GET /smart-timetable/period-set`
**Route:** `smart-timetable.period-set.index`

Example: `STANDARD_8P` (8 periods: 6 teaching + break + lunch)

**Step B — Add Periods to the Set:**
**URL:** `GET /smart-timetable/period-set-period`
**Route:** `smart-timetable.period-set-period.index`

For each period:
- `period_ord` (1, 2, 3…) — sequential order
- `period_type_id` — TEACHING / LAB / BREAK / LUNCH
- `start_time`, `end_time`
- `code` (e.g., P1, P2, SBREAK, LUNCH)

> **Rule:** No gaps between consecutive periods. Break/Lunch periods do NOT count as teaching.

---

### 1.4 Setup School Calendar (Working Days) ✅ Required

**Step A — Configure School Days template:**
**URL:** `GET /smart-timetable/school-day`
**Route:** `smart-timetable.school-day.index`

Mark which weekdays (Mon–Sat) are school days.

**Step B — Initialize Working Day Calendar:**
**URL:** `GET /smart-timetable/working-day`
**Route:** `smart-timetable.working-day.index`

Click **"Initialize Calendar"** for the term → bulk-generates all dates in the term range as STUDY_DAY.

**Step C — Apply Overrides (as needed):**
Mark specific dates as:
- `HOLIDAY` → `is_school_day = false`
- `EXAM_DAY`, `PTM_DAY`, `SPORTS_DAY` → `day_type2_id` override

> **Impact:** Only STUDY_DAY dates with `is_school_day = true` are used for timetable slots.

---

### 1.5 Map Classes to Timetable Types ✅ Required

**URL:** (inside `timetable-type` or `class-timetable-type` CRUD)
**Route:** `smart-timetable.class-timetable-type.*`

For each class (or all sections at once via `applies_to_all_sections = true`):
- Link class → timetable_type + period_set
- Set `effective_from`, `effective_to`

> **Outcome:** This creates the slot budget per class-section (how many periods per day/week are available).

---

### ✅ Phase 1 Checkpoint

Before proceeding, verify at `GET /smart-timetable/timetable-config`:
- [ ] Academic term is marked `is_current = true`
- [ ] Period set has periods with no gaps
- [ ] Working days calendar is initialized
- [ ] All active classes are mapped to a timetable type

---

## PHASE 2: REQUIREMENTS GENERATION [PER TERM]

> **When:** After Phase 1. Run once per term (re-run wipes existing data).
> **URL Hub:** `GET /smart-timetable/timetable-opration`
> **Route:** `timetable.timetableOperation`

---

### 2.1 Generate Slot Requirements 🔄 Auto

**Action:** Click **"Generate Slot Requirements"**
**Route:** `POST /smart-timetable/slot-requirement/generate`
**Route Name:** `smart-timetable.slot-requirement.generateSlotRequirement`

Bulk-inserts `tt_slot_requirements` from `tt_class_timetable_type_jnt`:
- Calculates `weekly_teaching_slots` per class-section
- Uses period_set to determine teaching vs break periods

**Verify:** `GET /smart-timetable/slot-requirement` → Should have one row per class-section.

---

### 2.2 Generate Class Subject Groups 🔄 Auto

**Action:** Click **"Generate Class Groups"**
**Route:** `POST /smart-timetable/class-subject-group/generate-class-groups`
**Route Name:** `smart-timetable.class-subject-group.generateClassSubjectGroups`

Copies from `sch_class_groups_jnt` into:
- `tt_class_requirement_groups` (is_compulsory = 1)
- `tt_class_requirement_subgroups` (is_compulsory = 0)

> **Optional update:** Use `POST /smart-timetable/class-subject-subgroup/update-sharing` to flag shared electives across sections.

---

### 2.3 Generate Requirement Consolidation 🔄 Auto

**Action:** Click **"Generate Requirements"**
**Route:** `POST /smart-timetable/requirement-consolidation/generate-requirements/generate`
**Route Name:** `requirement-consolidation.generateRequirements`

Merges Phase 2.1 + 2.2 into `tt_requirement_consolidations`:
- One row per class-section-subject-format combination
- Calculates `required_weekly_periods`, `resource_scarcity_index`, `teacher_scarcity_index`

**Stats:** `GET /smart-timetable/requirement-consolidations/stats`

---

### 2.4 Review & Adjust Requirements ⚠️ Optional

**URL:** `GET /smart-timetable/requirement-consolidation`
**Route:** `smart-timetable.requirement-consolidation.index`

For each requirement you can adjust:
- `preferred_periods_json` — preferred time slots
- `avoid_periods_json` — slots to avoid
- `preferred_days_json` / `avoid_days_json`
- `manual_priority_override` (1–100)
- `spread_evenly` — distribute across the week

**Update periods:** `POST /smart-timetable/class-subject-requirement/update-periods`

---

### ✅ Phase 2 Checkpoint

- [ ] `tt_slot_requirements` count = number of active class-sections
- [ ] `tt_requirement_consolidations` count = total subject-format combinations
- [ ] No requirement has `eligible_teacher_count = 0` (critical flag)

---

## PHASE 3: RESOURCE AVAILABILITY & CONSTRAINTS [PER TERM]

> **When:** After Phase 2. Can run in parallel with Phase 2 reviews.

---

### 3.1 Add Teacher Unavailability ⚠️ Optional

**URL:** `GET /smart-timetable/teacher-unavailable`
**Route:** `smart-timetable.teacher-unavailable.index`

Add blocks for teachers who are unavailable on specific days/periods:
- e.g., Teacher X unavailable every Wednesday period 1–2 (admin duty)
- e.g., Teacher Y unavailable entire Fridays (part-time)

> **Impact:** Generator will not schedule these teachers in blocked slots.

---

### 3.2 Add Room Unavailability ⚠️ Optional

**URL:** `GET /smart-timetable/room-unavailable`
**Route:** `smart-timetable.room-unavailable.index`

Block rooms under maintenance or reserved for specific use:
- e.g., Chemistry Lab under maintenance Mon–Tue for 2 weeks
- e.g., Auditorium reserved every Friday

---

### 3.3 Generate Teacher Availability 🔄 Auto

**Action:** Click **"Generate Teacher Availability"**
**Route:** `POST /smart-timetable/teacher-availabilty/generate`
**Route Name:** `smart-timetable.teacher-availabilty.generateSlotRequirement`

Bulk-inserts `tt_teacher_availability`:
- Matches teachers from `sch_teacher_capabilities` to requirements
- Calculates `min/max_availability_score` and `weighted_availability_score`
- Applies teacher unavailability blocks from 3.1

**Verify:** `GET /smart-timetable/teacher-availabilty` — Each requirement should have ≥1 teacher.

---

### 3.4 Setup Constraints ✅ Required

**URL:** `GET /smart-timetable/constraint`
**Route:** `smart-timetable.constraint.index`

Add constraints that the generator must respect.

**Common Hard Constraints (must configure):**

| Constraint Type | Example Setting | Effect |
|-----------------|----------------|--------|
| `TEACHER_MAX_DAILY` | max = 6 | Teacher can't teach more than 6 periods/day |
| `TEACHER_MAX_WEEKLY` | max = 40 | Teacher total cap per week |
| `CLASS_MAX_SUBJECT_PER_DAY` | max = 2 | No subject appears >2× per day |
| `TEACHER_GAP_LIMIT` | max_gaps = 2 | Limit free periods between classes |
| `ACTIVITY_CONSECUTIVE` | count = 2 | Lab sessions must be consecutive |

**Common Soft Constraints (optional, improve quality):**

| Constraint Type | Example | Effect |
|-----------------|---------|--------|
| `TEACHER_PREFERRED_TIME` | periods 1–4 | Prefer morning for this teacher |
| `SUBJECT_EARLY_PLACEMENT` | Maths in period 1–3 | Core subjects in early slots |
| `ROOM_PREFERRED` | Chem Lab for Chemistry | Prefer specific room |

> **Constraint Types** are pre-seeded. Choose from the dropdown.
> **Scope:** GLOBAL (applies to all), INDIVIDUAL (specific teacher/class), GROUP (set of teachers).

---

### ✅ Phase 3 Checkpoint

- [ ] Teacher availability records exist for all requirements
- [ ] No requirement has `weighted_availability_score = 0`
- [ ] At least TEACHER_MAX_DAILY and CLASS_MAX_SUBJECT_PER_DAY constraints added
- [ ] Room unavailability entered if any rooms are blocked

---

## PHASE 4: VALIDATION [PER TERM / PER RUN]

> **When:** After Phase 3. Must pass before generation.
> **URL:** `GET /smart-timetable/validation/{termId}/dashboard`
> **Route:** `smart-timetable.validation.dashboard`

---

### 4.1 Run Validation 🔄 Auto

**Action:** Click **"Run Validation"**
**Route:** `POST /smart-timetable/validation/{termId}/run`

Checks:
- ✅ All requirements have eligible teachers
- ✅ All requirements have available rooms (if required)
- ✅ Teacher total load ≤ max_periods_per_week
- ✅ No contradictory constraints
- ✅ Total slot requirement ≤ total available teaching slots

**Status outcomes:**

| Status | Meaning | Action |
|--------|---------|--------|
| `PASSED` | Score ≥ 90, no hard failures | Proceed to Phase 5 |
| `PASSED_WITH_WARNINGS` | Score ≥ 70, soft issues only | Review warnings, then proceed |
| `FAILED` | Score < 70 OR hard failures | Must fix before proceeding |
| `BLOCKED` | Fatal errors (e.g., zero teachers) | Fix master data first |

---

### 4.2 Review & Resolve Issues ✅ Required (if failed)

**URL:** `GET /smart-timetable/validation/session/{sessionId}`
**Route:** `smart-timetable.validation.show`

For each issue:

**Resolve:** `POST /smart-timetable/validation/issue/{issueId}/resolve`
Fix the underlying data (add teacher, adjust periods, change constraint).

**Override (warnings only):** `POST /smart-timetable/validation/issue/{issueId}/override`
Accept a warning and proceed without fixing (adds override record for audit).

---

### 4.3 Re-run Validation ✅ Required (if issues fixed)

Repeat 4.1 until status is `PASSED` or `PASSED_WITH_WARNINGS`.

> **You cannot generate a timetable if validation status is `FAILED` or `BLOCKED`.**

---

## PHASE 5: ACTIVITY CREATION [PER RUN]

> **When:** After validation passes. Activities are the atomic units the generator places.
> **URL Hub:** `GET /smart-timetable/timetable-opration`

---

### 5.1 Generate Activities 🔄 Auto

**Action:** Click **"Generate Activities"** (for all) or per class-group
**Route All:** `POST /smart-timetable/requirements/generate-activities/all`
**Route All (alt):** `POST /smart-timetable/class-group-requirements/generate-all`

**What it creates (`tt_activities`):**
- One activity per required weekly occurrence per subject
- `duration_periods`: LECTURE=1, LAB=2, PRACTICAL=2
- `weekly_occurrences = required_weekly_periods ÷ duration_periods`
- `difficulty_score` calculated (teacher scarcity, room requirement, constraints)

**Monitor bulk progress:** `GET /smart-timetable/class-group-requirements/generation-progress`

---

### 5.2 Map Teachers to Activities 🔄 Auto

Included in activity generation. Creates `tt_activity_teachers`:
- Maps eligible teachers (from `tt_teacher_availability`) to each activity
- Sets `assignment_role_id` (PRIMARY, ASSISTANT, etc.)
- Calculates `preference_score`

> **Manual override:** Go to activity detail → edit teacher assignment if needed.

---

### 5.3 Map Rooms to Activities 🔄 Auto

Also included in generation. Updates `tt_activities`:
- `eligible_room_count`
- `preferred_room_ids_json` (from requirement preferences)
- `room_availability_score`

---

### 5.4 Review Activity Readiness ✅ Required

**URL:** `GET /smart-timetable/timetable-opration` → Activities section

Check for flagged activities:
- 🔴 **CRITICAL** — No eligible teacher (MUST fix)
- 🟠 **HIGH** — No room available (fix if room is required)
- 🟡 **MEDIUM** — Over-constrained (generator may fail for these)
- 🟢 **LOW** — Preference conflicts only

> Fix critical/high flags before generation. Medium/low can be attempted.

---

### ✅ Phase 5 Checkpoint

- [ ] `tt_activities` count matches expected (total required weekly periods / duration)
- [ ] Zero activities with `status = CRITICAL_FAILURE`
- [ ] All activities have ≥1 teacher in `tt_activity_teachers`

---

## PHASE 6: TIMETABLE GENERATION [PER RUN]

> **When:** After activities are ready.
> **URL:** `GET /smart-timetable/timetable-generation`
> **Route:** `timetable.timetableGeneration`

---

### 6.1 Choose Generation Strategy ✅ Required

Strategies (pre-seeded in `tt_generation_strategies`):

| Strategy | Best For | Speed |
|----------|----------|-------|
| `RECURSIVE_FAST` | < 500 activities, few constraints | Fast (seconds) |
| `FET` (Constraint-based + Backtracking) | Medium schools, standard constraints | Fast–Medium |
| `TABU_OPTIMIZED` | Complex constraints, >50 hard rules | Medium (minutes) |
| `SIMULATED_ANNEALING` | Soft-constraint optimization | Slow (minutes) |
| `HYBRID_BALANCED` | 500–1000 activities | Medium |
| `GENETIC_THOROUGH` | Large schools, >1000 activities | Slow (5–15 min) |

> **Recommendation:** Start with `FET` or `RECURSIVE_FAST`. Use `TABU` if placement rate < 85%.

---

### 6.2 Dispatch Async Generation ✅ Required

**Action:** Click **"Generate Timetable"** (queued/async)
**Route:** `POST /smart-timetable/smart-timetable/dispatch-generation`
**Route Name:** `smart-timetable-management.dispatch-generation`

This:
1. Creates `tt_timetable` record (status = `DRAFT`)
2. Creates `tt_generation_runs` record (status = `QUEUED`)
3. Dispatches `GenerateTimetableJob` (Laravel Queue, timeout 600s)

> **Ensure queue worker is running:** `php artisan queue:work`

---

### 6.3 Monitor Generation Status 🔄 Auto (polls every 3s)

**URL:** `GET /smart-timetable/smart-timetable/generation-status/{generationRun}`
**Route Name:** `smart-timetable-management.generation-status`

Status progression: `QUEUED → RUNNING → COMPLETED / FAILED`

**Key metrics on completion:**
- `activities_placed / activities_total` (target: ≥95%)
- `hard_violations` (target: 0)
- `soft_score` (higher = better quality)
- `generation_time` in seconds

---

### 6.4 Review Preview ✅ Required

**URL:** `GET /smart-timetable/smart-timetable/preview/{timetable}`
**Route:** `timetable.preview`

View the raw generated timetable grid:
- Class × Day × Period matrix
- Activities shown in each cell
- Conflicts highlighted

**If placement_rate < 85%:**
- Re-run with `TABU_OPTIMIZED` strategy
- Or relax soft constraints and re-generate

**If placement_rate ≥ 95% and hard_violations = 0:**
- Proceed to Phase 7

---

### 6.5 Store Generated Timetable ✅ Required

After reviewing the preview, save to the database.
**Route:** `POST /smart-timetable/smart-timetable/store` → saves `tt_timetable_cells`

---

## PHASE 7: POST-GENERATION ANALYTICS [PER RUN]

> **When:** After generation. Review quality before manual refinement.
> **URL:** `GET /smart-timetable/analytics/{timetable}/dashboard`
> **Route:** `smart-timetable.analytics.dashboard`

---

### 7.1 Compute All Analytics 🔄 Auto

**Action:** Click **"Compute All"**
**Route:** `POST /smart-timetable/analytics/{timetable}/compute-all`

Computes in one shot:
- Teacher workload (`tt_teacher_workloads`)
- Room utilization (`tt_room_utilizations`)
- Constraint violations (from `tt_conflict_detections`)

---

### 7.2 Review Teacher Workload

**URL:** `GET /smart-timetable/analytics/{timetable}/teacher-workload`
**Route:** `smart-timetable.analytics.teacher-workload`

Look for:
- 🔴 **Overloaded** (utilization > 100%) — Must reduce
- 🟠 **Under-utilized** (< 70%) — Can add more
- 🟢 **Normal** (70–100%)

**Export:** `GET /smart-timetable/analytics/{timetable}/export/teacher-workload` (CSV)

---

### 7.3 Review Room Utilization

**URL:** `GET /smart-timetable/analytics/{timetable}/room-utilization`
**Route:** `smart-timetable.analytics.room-utilization`

Look for rooms consistently at 100% (bottleneck) or < 30% (wasted).

---

### 7.4 Review Constraint Violations

**URL:** `GET /smart-timetable/analytics/{timetable}/violations`
**Route:** `smart-timetable.analytics.violations`

**Hard violations** (severity HIGH/CRITICAL) — Must resolve before publishing.
**Soft violations** (severity MEDIUM/LOW) — Acceptable but should minimize.

---

### 7.5 Review Individual Reports ⚠️ Optional

- **Class view:** `GET /smart-timetable/analytics/{timetable}/report/class`
- **Teacher view:** `GET /smart-timetable/analytics/{timetable}/report/teacher`
- **Room view:** `GET /smart-timetable/analytics/{timetable}/report/room`

---

### 7.6 Take Daily Snapshot ⚠️ Optional

**Route:** `POST /smart-timetable/analytics/{timetable}/snapshots/take`

Saves a point-in-time snapshot of analytics for trend tracking.

---

### ✅ Phase 7 Checkpoint

- [ ] `hard_violations = 0`
- [ ] No teacher overloaded (utilization > 100%)
- [ ] Placement rate ≥ 95%
- [ ] All classes have a complete timetable grid

> If hard violations exist or placement < 95%: go to Phase 8 (Manual Refinement) OR re-generate (Phase 6).

---

## PHASE 8: MANUAL REFINEMENT [PER RUN — if needed]

> **When:** After analytics reveal issues that need fixing without full re-generation.
> **URL:** `GET /smart-timetable/refinement/{timetable}/`
> **Route:** `smart-timetable.refinement.index`

---

### 8.1 Interactive Timetable Grid

The grid shows all class-sections with their period slots.

- **Per-cell color codes:** Green = placed, Red = conflict, Grey = locked, Yellow = empty
- **Two-click Swap:** Click ⇄ on source cell → click ⇄ on target cell → impact modal appears → confirm

---

### 8.2 Impact Analysis Before Swap 🔄 Auto

When you select source + target cells, system automatically calls:
**Route:** `POST /smart-timetable/refinement/{timetable}/analyse-impact`

Returns:
- `risk_level`: LOW / MEDIUM / HIGH / CRITICAL
- List of constraints that would be violated
- Affected teachers, rooms

> Only confirm the swap if risk_level is LOW or MEDIUM.

---

### 8.3 Cell Operations

| Action | Route | Notes |
|--------|-------|-------|
| Swap two cells | `POST .../swap` | Exchanges activities between two slots |
| Move cell | `POST .../move` | Moves activity, leaves source empty |
| Batch swap | `POST .../batch-swap` | Multiple swaps at once |
| Rollback batch | `POST .../batch/{batch}/rollback` | Undo entire batch |
| Lock cell | `POST .../cells/{cell}/lock` | Prevents accidental edits |
| Unlock cell | `POST .../cells/{cell}/unlock` | Re-enables editing |
| Lock all | `POST .../lock-all` | Lock entire timetable |

---

### 8.4 View Change Log ⚠️ Optional

**URL:** `GET /smart-timetable/refinement/{timetable}/change-log`
**Route:** `smart-timetable.refinement.change-log`

Audit trail of all manual changes with user, timestamp, reason.

---

### 8.5 Conflict Resolution Workflow ✅ Required (if hard violations exist)

**URL:** `GET /smart-timetable/refinement/{timetable}/conflict-resolution`
**Route:** `smart-timetable.refinement.conflict-resolution`

1. For each conflict, click **"Open Session"** → opens a resolution session
2. System suggests resolution options (swap candidates, constraint relaxations)
3. Click **"Apply"** on the chosen option
4. Or **"Escalate"** to flag for manual review by another admin

---

### 8.6 Re-validate After Changes ✅ Required

**Route:** `POST /smart-timetable/refinement/{timetable}/revalidate`

Runs ConflictDetectionService + ConstraintViolations again.
Analytics dashboard auto-refreshes with updated scores.

---

### ✅ Phase 8 Checkpoint

- [ ] `hard_violations = 0` (check analytics violations page)
- [ ] Change log shows all changes tracked
- [ ] No locked cells preventing needed edits

---

## PHASE 9: PUBLICATION & LOCKING [PER RUN]

> **When:** Timetable is reviewed, violations resolved, analytics acceptable.

---

### 9.1 Run Final Conflict Detection ✅ Required

**Route:** `POST /smart-timetable/smart-timetable/{timetable}/detect-conflicts`
**Route Name:** `smart-timetable-management.detect-conflicts`

Final check to ensure no conflicts were introduced during manual refinement.

> **Result stored in:** `tt_conflict_detections`

---

### 9.2 Create Resource Bookings 🔄 Auto

**Route:** `POST /smart-timetable/smart-timetable/{timetable}/create-bookings`
**Route Name:** `smart-timetable-management.create-bookings`

Creates `tt_resource_bookings` for every placed activity:
- Room bookings (ROOM type)
- Teacher bookings (TEACHER type)

> These bookings can be used by other modules (events, facility management) to check room/teacher availability.

---

### 9.3 Publish Timetable ✅ Required

**URL:** `GET /smart-timetable/smart-timetable-management` → Edit the timetable
**Route:** `smart-timetable-management.edit`

Change `status` from `DRAFT` → `PUBLISHED`.

Once published:
- Timetable becomes visible in Standard Views (Phase 11)
- Substitution module can use it (Phase 10)
- No generation re-runs will affect it (unless explicitly unlocked)

---

### 9.4 Lock Timetable ⚠️ Optional (strong protection)

Change `status` to `LOCKED` to prevent any further edits:
- Route: `smart-timetable-management.edit` → set `status = LOCKED`

> Use `lock-all` in Refinement module to lock individual cells without locking the timetable record.

---

### ✅ Phase 9 Checkpoint

- [ ] `tt_timetable.status = PUBLISHED`
- [ ] `tt_conflict_detections` latest run = zero hard conflicts
- [ ] `tt_resource_bookings` created for all cells
- [ ] Standard Hub shows this timetable as COMPLETE

---

## PHASE 10: SUBSTITUTION MANAGEMENT [DAILY]

> **When:** Any day a teacher is absent during the active published timetable term.
> **URL:** `GET /smart-timetable/substitution/{timetable}/dashboard`
> **Route:** `smart-timetable.substitution.dashboard`

---

### 10.1 Record Absence ✅ Required (when absence occurs)

**URL:** `GET /smart-timetable/substitution/{timetable}/absences`
**Route:** `smart-timetable.substitution.absences`

**Fill:**
- `teacher_id` — absent teacher
- `absence_date` — date of absence
- `absence_type` — LEAVE / SICK / TRAINING / OFFICIAL_DUTY / OTHER
- `start_period`, `end_period` — which periods affected (leave blank = full day)
- `reason` — optional note
- `substitution_required` — check if substitution is needed

Creates `tt_teacher_absences` with `status = PENDING`.

---

### 10.2 Approve Absence ✅ Required

**Route:** `POST /smart-timetable/substitution/{timetable}/absences/{absence}/approve`

Approval triggers **automatic:**
- Identification of affected timetable cells
- Generation of substitute recommendations per cell (scored out of 100)

Scoring formula:
| Factor | Weight |
|--------|--------|
| Subject match (can teach that subject) | 40 pts |
| Historical pattern confidence | 25 pts |
| Day availability (not already teaching) | 20 pts |
| Workload balance (not overloaded) | 15 pts |

---

### 10.3 Assign Substitute ✅ Required

**URL:** `GET /smart-timetable/substitution/{timetable}/absences/{absence}/cells`
**Route:** `smart-timetable.substitution.cells`

For each affected cell:
- View ranked substitute recommendations (score shown)
- Click **"Assign"** on preferred candidate
- Or use **"Manual Override"** dropdown to pick any teacher

**Route:** `POST .../absences/{absence}/cells/{cell}/assign`

Assigns substitute by adding to `tt_timetable_cell_teachers` with `is_substitute = true`.
Original teacher record stays for audit purposes.

---

### 10.4 Complete Substitution ✅ Required (after class)

**Route:** `POST /smart-timetable/substitution/{timetable}/logs/{log}/complete`

- Add `feedback` (optional notes)
- Add `effectiveness_rating` (1–5)

This triggers **pattern learning** — updates `tt_substitution_patterns` with running average so future recommendations improve.

---

### 10.5 Cancel Substitution ⚠️ Optional

**Route:** `POST /smart-timetable/substitution/{timetable}/logs/{log}/cancel`

If the substitute cannot come:
- Removes them from `tt_timetable_cell_teachers`
- Returns cell to `needs substitution` state

---

### 10.6 View History

**URL:** `GET /smart-timetable/substitution/{timetable}/history`
**Route:** `smart-timetable.substitution.history`

Complete log of all substitutions for the timetable.

---

## PHASE 11: STANDARD TIMETABLE VIEWS [ANYTIME — after publish]

> **When:** After timetable is PUBLISHED. Anyone can view.
> **URL:** `GET /smart-timetable/standard/`
> **Route:** `smart-timetable.standard.hub`

---

### 11.1 Hub Overview (All Timetables)

**URL:** `GET /smart-timetable/standard/`

Shows:
- Summary cards: placed activities, hard violations, quality score, status
- Class-section grid: COMPLETE / PARTIAL / EMPTY / CONFLICTS
- Quick links to Class / Teacher / Room views and Edit

---

### 11.2 Class Timetable (Scr-1)

**URL:** `GET /smart-timetable/standard/class?timetable_id={id}&class_id={c}&section_id={s}`
**Route:** `smart-timetable.standard.class`

- Select class → sections auto-filter by JS
- Full period-by-period grid for the selected class-section
- Shows: Subject, teacher name, room

---

### 11.3 Teacher Timetable (Scr-2)

**URL:** `GET /smart-timetable/standard/teacher?teacher_id={id}`
**Route:** `smart-timetable.standard.teacher`

- Workload banner: periods/max, utilization%, consecutive max, gap periods, load status badge
- Full week grid: shows class + room for each period
- Links to Analytics for deeper workload analysis

---

### 11.4 Room Timetable (Scr-3)

**URL:** `GET /smart-timetable/standard/room?room_id={id}`
**Route:** `smart-timetable.standard.room`

- Period-by-period occupancy for a room
- Shows: Subject, class+section

---

## QUICK REFERENCE — Complete Sequence Summary

```
PHASE 0  [ONE-TIME]     Seeders + Shifts + Master Data

PHASE 1  [PER TERM]     Academic Term (1.1)
                        → Timetable Type (1.2)
                        → Period Set + Periods (1.3)
                        → Working Day Calendar (1.4)
                        → Class-to-TimetableType Mapping (1.5)

PHASE 2  [PER TERM]     Generate Slot Requirements (2.1)
                        → Generate Class Groups (2.2)
                        → Generate Requirement Consolidation (2.3)
                        → [Optional] Adjust Preferences (2.4)

PHASE 3  [PER TERM]     [Optional] Teacher Unavailability (3.1)
                        [Optional] Room Unavailability (3.2)
                        → Generate Teacher Availability (3.3)
                        → Setup Constraints (3.4)

PHASE 4  [PER TERM]     Run Validation (4.1)
                        → Review & Resolve Issues (4.2)
                        → Re-run Until PASSED (4.3)

PHASE 5  [PER RUN]      Generate Activities (5.1)
                        → [Auto] Teacher Mapping (5.2)
                        → [Auto] Room Mapping (5.3)
                        → Review Activity Readiness (5.4)

PHASE 6  [PER RUN]      Choose Strategy (6.1)
                        → Dispatch Generation Job (6.2)
                        → Monitor Status (6.3)
                        → Review Preview (6.4)
                        → Store Timetable (6.5)

PHASE 7  [PER RUN]      Compute All Analytics (7.1)
                        → Review Workload (7.2)
                        → Review Room Utilization (7.3)
                        → Review Violations (7.4)

PHASE 8  [PER RUN]      [If violations] Swap / Move Cells (8.3)
         [if needed]    → Conflict Resolution (8.5)
                        → Re-validate (8.6)

PHASE 9  [PER RUN]      Final Conflict Detection (9.1)
                        → Create Resource Bookings (9.2)
                        → Publish Timetable (9.3)
                        → [Optional] Lock Timetable (9.4)

PHASE 10 [DAILY]        Record Absence (10.1)
                        → Approve (10.2)
                        → Assign Substitute (10.3)
                        → Complete + Rate (10.4)

PHASE 11 [ANYTIME]      Standard Views: Hub / Class / Teacher / Room
```

---

## CRITICAL DEPENDENCIES MAP

```
Master Data (Phase 0)
    ↓ REQUIRED BY
Academic Term (Phase 1.1)
    ↓ REQUIRED BY
Timetable Type (Phase 1.2) ──────────────────────────────────┐
Period Set (Phase 1.3) ─────────────────────────────────────┐ │
Working Days Calendar (Phase 1.4) ──────────────────────────┐ │ │
Class-TT Type Mapping (Phase 1.5) ──────────────────────────┤ │ │
                                                            ↓ ↓ ↓
                                              Slot Requirements (Phase 2.1)
                                                            ↓
                                          Class Groups (Phase 2.2)
                                                            ↓
                                        Requirement Consolidation (Phase 2.3)
                                                            ↓
                                ┌──────── Teacher Availability (Phase 3.3)
                                │                           ↓
                                │                  Constraints (Phase 3.4)
                                │                           ↓
                                └──────────────── Validation (Phase 4)
                                                            ↓
                                              Activities (Phase 5)
                                                            ↓
                                              Generation (Phase 6)
                                                            ↓
                                              Analytics (Phase 7)
                                                            ↓
                                         [Optional] Refinement (Phase 8)
                                                            ↓
                                               Publish (Phase 9)
                                                       ↙       ↘
                                        Substitution (Phase 10)  Standard Views (Phase 11)
```

---

## COMMON PROBLEMS & FIXES

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Placement rate < 80% | Too many hard constraints | Relax soft constraints; check teacher availability scores |
| `NO_COVERAGE` validation error | No eligible teacher for a subject | Add teacher capability in `sch_teacher_capabilities` |
| Generation job stuck in QUEUED | Queue worker not running | Run `php artisan queue:work` |
| Hard violations after generation | Conflicting constraints | Use Tabu Search strategy; open Conflict Resolution |
| Teacher shows as OVERLOADED | `max_periods_per_week` too low | Update teacher profile or add TEACHER_MAX_WEEKLY constraint |
| Room always at 100% utilization | Not enough rooms of that type | Add rooms, or split into smaller groups |
| Substitute recommendations empty | No available teachers | Check teacher unavailability and workload |
| Analytics dashboard blank | Analytics not computed yet | Click "Compute All" on the dashboard |

---

*Generated from the completed SmartTimetable module (Stages 1–10, branch `Brijesh-timetable`).*
*All routes verified against `routes/tenant.php` and `routes/api.php` as of 2026-03-03.*
