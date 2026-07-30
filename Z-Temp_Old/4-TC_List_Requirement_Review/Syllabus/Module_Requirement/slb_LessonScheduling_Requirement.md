# Lesson Scheduling — Business Requirements

## What This Screen Does

The Lesson Scheduling screen transforms the sequenced syllabus into an actionable teaching plan by assigning specific teachers and target date ranges to every topic. While Lesson Sequencing defines the order and period count, this screen answers the critical questions of who will teach each topic and by when it should be completed.

It provides editable dropdowns for teacher selection, date pickers for start and end dates, an intelligent auto-scheduling engine that calculates dates based on period allocation, and a lock mechanism to prevent accidental modifications to confirmed schedules.

---

## When This Screen Is Used

- Teacher Allocation at the start of the term when HODs assign specific topics to individual teachers based on their expertise and workload
- Date Assignment when converting the raw period estimates into concrete calendar dates with start and end boundaries
- Schedule Lockdown before exam periods when the administration wants to freeze the schedule to prevent last-minute changes
- Auto-Scheduling when the coordinator wants the system to intelligently distribute topics across the available teaching days using the configured periods-per-day allocation

## Default Data Load

This screen displays within the Syllabus Planning tab group. When the user navigates to Syllabus → Planning, SyllabusController@planning() applies default filters (class_section_id=1, subject_id=5, academic_session_id=7) and loads tab-specific data. Shared dropdowns include Class, Section, Class-Section, Subject, and Academic Session.

---

---

## Key Fields at a Glance

**Content Identification**
Columns for Mini-Topic, Sub-Topic, Topic, and Lesson are conditionally displayed based on the configured planning depth level. Each row shows the human-readable name and the auto-generated tracking code for unambiguous identification.

**Teacher Assignment**
A Teacher dropdown lists all active employees marked as teachers. The default value is the class teacher auto-resolved from the Class-Section mapping during sequencing. An empty selection falls back to a "Class Teacher" label. Disabled when the row is locked.

**Date Assignment**
A Scheduled Start Date and Scheduled End Date picker allow defining the calendar window for each topic. When both dates are set, the system auto-calculates the planned periods as the number of days in the range multiplied by the periods-per-day allocation.

**Duration Display**
A read-only Duration badge shows the planned periods for each row. This value is auto-calculated when dates are set and can also be inherited from the Lesson Sequencing step.

**Priority and Status**
A read-only Priority badge displays High, Medium, or Low as set during sequencing. A read-only Status badge shows Active or Inactive based on the sequencing toggle.

**Lock Control**
A Lock toggle button per row prevents further edits to the teacher, start date, and end date fields. Locked rows show a padlock icon in red; unlocked rows show an open lock in green. Locking is a soft safeguard—an authorized user can unlock at any time.

---

## How This Screen Works — Logic Flow (Non-Technical)

This screen has multiple interconnected features. Each one follows its own step-by-step logic. Below is exactly how each feature works.

### Feature 1: Loading Existing Data

When the user selects a class, section, and subject and clicks Apply, the system asks:

**"Has this class+subject been scheduled before?"**

```
Condition                                      → What happens
──────────────────────────────────────────────────────────────────────
No schedule records exist                      → Show empty table with message:
                                                "Complete Lesson Sequencing first"
Schedule records exist                         → Load all rows from Syllabus Schedule table
```

If records exist, each row is loaded with its saved teacher, start date, end date, planned periods, priority, status, and lock state. The depth filter from Settings determines which hierarchy columns are visible (same logic as Lesson Sequencing Step 1).

---

### Feature 2: Auto-Filling Dates When Tab Opens

The system has a convenience feature. When the Scheduling tab opens for the first time, it checks:

**"Are there rows with empty dates that need to be filled?"**

```
Condition                                                  → What happens
──────────────────────────────────────────────────────────────────────────────
At least one row has an empty start date AND start_date    → Automatically call the
filter is provided                                           Auto-Schedule API
All rows already have dates                                → Do nothing (skip auto-fill)
```

This auto-fill only runs once when the tab becomes visible. If the user later clears dates and switches tabs, it will not re-trigger. The user must click "Auto Schedule" manually after that.

---

### Feature 3: Auto-Schedule Algorithm (Most Complex Logic)

When the user clicks **Auto Schedule** or the auto-fill triggers, the system runs this step-by-step date calculation:

```
INPUTS:
    - rows: array of {schedule_id, planned_periods}
    - start_date: the base date to start from (e.g., "2026-07-01")
    - class_id, subject_id, section_id
    - academic_session_id

STEP 1: Read allocation data
    Query: Periods Allocation table for this class+subject+section
    Get: MAX(tot_periods_in_day) → this becomes "periods_per_day" (ppd)
    If no data found → default ppd = 1

STEP 2: Find locked rows
    Check: which schedule_ids have is_locked = true
    These rows keep their existing dates and are SKIPPED during calculation

STEP 3: Calculate dates for each unlocked row

    cumulative = 0 (tracks how many periods have been used so far)
    
    For each unlocked row:
        duration = this row's planned_periods
        
        IF duration <= 0:
            Set start_date = null, end_date = null (no dates for zero-period topics)
            SKIP to next row
        
        IF duration > 0:
            start_offset = floor(cumulative / ppd)     ← which day to start
            end_offset = ceil((cumulative + duration) / ppd) - 1  ← which day to end
            
            start_date = base_date + start_offset days
            end_date = base_date + end_offset days
            
            cumulative = cumulative + duration     ← move the cursor forward

STEP 4: Return results
    For each row: {schedule_id, start_date, end_date, planned_periods}
```

**Real Example:**
```
Base date = July 1
ppd = 2 periods per day

Row 1: "Algebra Basics"     planned_periods = 3
    start = July 1, end = July 2 (covers 2 days, 2+1=3 periods)

Row 2: "Linear Equations"   planned_periods = 4  
    cumulative = 3, so start_offset = floor(3/2) = 1 → July 2
    end_offset = ceil(7/2)-1 = 3 → July 4
    start = July 2, end = July 4

Row 3: "Quadratic Equations" planned_periods = 2
    cumulative = 7, so start_offset = floor(7/2) = 3 → July 4
    end_offset = ceil(9/2)-1 = 4 → July 5
    start = July 4, end = July 5
```

**Why this matters:** Topics flow seamlessly. The end of one topic is the same day as the start of the next. There are no gaps. The system packs topics tightly based on how many periods are available per day.

---

### Feature 4: Manual Date Change — Periods Recalculation

When a user manually types a start date or end date, the system immediately recalculates:

```
TRIGGER: User changes start_date OR end_date on any row

ACTION:
    1. Read the new start_date and end_date
    2. Calculate days_in_range = (end_date - start_date) + 1
    3. Read periods_per_day (ppd) from allocation data
    4. new_planned_periods = days_in_range × ppd
    5. Update the Duration badge on screen

CONDITION CHECK:
    IF start_date is empty OR end_date is empty → Do nothing, show existing periods
    IF end_date < start_date → Show validation error, do not recalculate
    IF both dates are valid → Recalculate and display immediately
```

**Why this matters:** The Duration badge is always in sync with the date range. If a teacher sets a 5-day range and the school has 2 periods per day, the badge automatically shows 10 periods. No manual calculation needed.

---

### Feature 5: Save Scheduling — Multiple Conditions

When the user clicks **Save Dates**, the system checks multiple conditions in order:

```
CHECK 1: Is the row locked?
    Condition: schedule.is_locked = true
    If YES → SKIP this row entirely (do not update anything)
    If NO → Continue to next check

CHECK 2: Are dates provided?
    Condition: start_date AND end_date both present in the request
    If YES → Calculate planned_periods = days_in_range × ppd
    If NO → Keep existing planned_periods unchanged

CHECK 3: Is a teacher selected?
    Condition: assigned_teacher_id is provided
    If YES → Update the teacher
    If NO → Keep the existing teacher (do not overwrite with null)

CHECK 4: Should tracked_by be synced?
    Condition: assigned_teacher_id changed
    If YES → Also set taught_by_teacher_id = assigned_teacher_id
    (The person assigned is assumed to be the one teaching)

CHECK 5: Should Periods Allocation records be created?
    Condition: Any row in the batch has dates set
    If YES → Call syncPeriodsAllocation to create/update date records
    The system creates one record per date in the range with:
        - tot_periods_in_day = ppd
        - tot_periods_in_week = ppd × 5 (assumes 5 school days)
        - data_created_by = 'AUTO'
```

---

### Feature 6: Lock/Unlock Toggle

The lock button is a simple toggle with its own isolated API call:

```
TRIGGER: User clicks the lock/unlock icon on any row

ACTION:
    1. Send request: POST /planning/{id}/toggle-lock
    2. Server reads current is_locked value
    3. Server flips the value: if true → false, if false → true
    4. Server saves and returns new state
    5. Client updates the icon:
        - Locked → red lock icon, disable all inputs in that row
        - Unlocked → green open lock icon, enable all inputs

WHAT LOCKING PREVENTS:
    - Cannot change teacher dropdown
    - Cannot change start date
    - Cannot change end date
    - Save Scheduling API skips locked rows entirely

WHAT LOCKING DOES NOT PREVENT:
    - The lock itself can always be toggled back (no special permission required)
    - The Lesson Date Planning grid can still save (separate endpoint)
```

---

## Business Rules and Conditions

**Lock Precedence and Protection**
When a row is locked, the system rejects any updates to the teacher, start date, or end date from the save endpoint. The lock status is toggled via a dedicated isolated API call to prevent race conditions. Locked rows are visually distinct in the table with disabled form controls.

**Auto-Scheduling Algorithm**
The auto-schedule feature reads the periods-per-day allocation from the Periods Allocation table for the selected class, subject, and section. It then distributes the planned periods sequentially across working days, calculating start and end dates for each row. Locked rows are preserved with their existing dates and are skipped during calculation. The cumulative offset ensures topics flow seamlessly from one to the next without gaps or overlaps.

**Periods-Per-Day Recalculation**
When both start and end dates are manually set, the system recalculates planned periods as the number of calendar days in the range multiplied by the configured periods-per-day. This ensures the duration badge always reflects the actual date range. Changing either date triggers an immediate client-side recalculation for real-time feedback.

**Teacher Assignment Cascade**
If no teacher is explicitly selected for a row, the system falls back to the class teacher resolved from the Class-Section mapping. If no class teacher is configured, the field remains empty and must be manually assigned before the schedule is considered complete for execution.

**Section-Level Date Boundaries**
All scheduled dates must fall within the boundaries of the selected Academic Session. The system enforces that the end date cannot be earlier than the start date. Validation occurs both client-side before submission and server-side during save.

---

## Conditions at a Glance — Decision Table

| Feature | Condition | If True | If False |
|---------|-----------|---------|----------|
| Load data | Schedule records exist? | Load from DB | Show "do sequencing first" |
| Auto-fill on tab open | Any row date empty? | Run auto-schedule | Do nothing |
| Auto-schedule calculation | planned_periods > 0? | Calculate start/end dates | Set dates to null |
| Auto-schedule skipping | Row is_locked = true? | Keep existing dates | Calculate new dates |
| Manual date change | Both dates filled? | Recalculate periods | Keep existing periods |
| Save: row locked? | is_locked = true? | Skip row entirely | Save updates normally |
| Save: dates provided? | Both dates in request? | Recalc planned_periods | Keep existing periods |
| Save: teacher selected? | teacher_id in request? | Update teacher | Keep existing teacher |
| Save: sync allocation? | Any row has dates? | Create PeriodsAllocation records | Skip sync |

---

## Workflow Steps

**Assigning Teachers and Scheduling Dates**
The Math HOD opens the Lesson Scheduling tab after completing the sequencing step. They select Class 10, Section B, and Subject Mathematics. The table loads all sequenced topics with their planned periods. The HOD notices that the system has auto-assigned Mr. Sharma as the teacher for all rows based on the class teacher mapping. They override the teacher for the "Calculus" topic, selecting Ms. Patel instead because of her specialization. They manually enter start and end dates for the first few topics to establish the baseline. For the remaining topics, they click Auto Schedule. The system follows the auto-schedule algorithm (Feature 3), reads the periods-per-day allocation, calculates cumulative offsets, and fills all empty date fields instantly.

---

## Example Scenario

It is the end of the first term, and the final exams are approaching. The Principal wants to ensure no teacher alters the already-confirmed exam preparation schedule. The Academic Director navigates to Lesson Scheduling and reviews the upcoming topics for Class 12 Physics. All critical revision topics have correct dates and assigned teachers. The Director clicks the Lock icon on each of these rows, turning them from green (unlocked) to red (locked). The lock toggle API (Feature 6) updates each row's is_locked flag. The following week, a junior teacher accidentally tries to adjust a locked topic's date. The Save Scheduling logic (Feature 5, Check 1) sees is_locked = true and skips that row entirely, preventing the change. The teacher must request the HOD to unlock the row before making adjustments.

---

## Related Screens

- **Lesson Sequencing** — Provides the ordered list of topics and planned periods that this screen uses as its baseline
- **Lesson Date Planning** — An alternative grid-based view for managing the same date data across all topics
- **Periods Allocation** — Provides the periods-per-day and periods-per-week values used by the auto-scheduling engine
- **Settings** — The planning depth level configuration determines which topic hierarchy columns are visible

---

## Requirements

- The system MUST display sequenced topics from `SyllabusSchedule` in an editable table under the `lesson_scheduling` tab of `planning.index`
- Each row MUST show hierarchy (Lesson/Topic/Sub-Topic/Mini-Topic based on config depth), Teacher dropdown, `scheduled_start_date`, `scheduled_end_date`, Duration badge (`planned_periods`), Priority badge, Status badge (`is_active`), Lock toggle (`is_locked`)
- The Teacher dropdown MUST list `Employee::where('is_teacher', true)->where('is_active', true)` ordered by `first_name`
- The batch save MUST use `POST /planning/save-scheduling` (route: `planning.saveScheduling`) with `Gate::authorize('tenant.lesson.update')`
- Locked rows (`is_locked = true`) MUST be skipped — the `saveScheduling` method does `if ($schedule->is_locked) { continue; }` without returning an error
- When both dates are provided, `planned_periods` MUST be recalculated as `diffInDays(start, end) + 1 × periodsPerDay` using `Carbon`
- When dates are saved and any row has dates, `syncPeriodsAllocation()` MUST create/update records via `PeriodsAllocation::updateOrCreate()` per date in range
- Auto-schedule (`POST /planning/auto-schedule`) MUST read `MAX(tot_periods_in_day)` from `PeriodsAllocation` as ppd (default 1), skip locked rows, and calculate dates using cumulative offset formula: `startOff = floor(cumulative/ppd)`, `endOff = ceil((cumulative+dur)/ppd) - 1`
- `assigned_teacher_id` MUST cascade to `taught_by_teacher_id` when set
- `SyllabusSchedule::find($row['schedule_id'])` — if not found, row is silently skipped with `continue`
- View rendered by `resources/views/lesson-management/partials/lesson-scheduling/index.blade.php`

---

## Who Can Access This Screen

| Role | Access Level | Permission | Notes |
|------|-------------|------------|-------|
| HOD / Academic Coordinator | Full Access | `tenant.lesson.update` | Can assign teachers, set dates, lock/unlock rows, run auto-schedule |
| Teacher | Read-Only | `tenant.lesson.viewAny` | Can view schedules but cannot modify |
| Administrator | Full Access | `tenant.lesson.update` | Can access all scheduling features including lock override |
| Principal / Director | Read-Only | `tenant.lesson.viewAny` | Can review the schedule but cannot make changes |
| System Admin | Full Access | `tenant.lesson.update` | Full access to all scheduling operations |

---

## Validate Before Save (Multiple Conditions)

The `SyllabusController@saveScheduling()` performs this chain per row:

```
CHECK 1: Row Existence (per row)
    $schedule = SyllabusSchedule::find($row['schedule_id'])
    → If null → continue (silently skip, no error)
    → If found → Continue

CHECK 2: Row Lock Status (per row)
    If $schedule->is_locked === true
    → continue (skip row, no error, row unchanged)
    → If unlocked → Continue

CHECK 3: Date Assignment
    $updateData['scheduled_start_date'] = $row['scheduled_start_date'] ?? null
    $updateData['scheduled_end_date'] = $row['scheduled_end_date'] ?? null
    → No after_or_equal enforcement server-side for scheduling save
    → Client-side validation assumed

CHECK 4: Teacher Assignment
    $updateData['assigned_teacher_id'] = $row['assigned_teacher_id'] ?? $schedule->assigned_teacher_id
    → If explicitly set → update teacher
    → If omitted → keep existing teacher (not nullified)

CHECK 5: Teacher Cascade
    If $updateData['assigned_teacher_id'] is set:
        $updateData['taught_by_teacher_id'] = $updateData['assigned_teacher_id']
    → Assigned teacher always becomes taught_by_teacher

CHECK 6: Periods Recalculation
    If both scheduled_start_date AND scheduled_end_date are present:
        $daysInRange = $sDate->diffInDays($eDate) + 1
        planned_periods = $daysInRange × $periodsPerDay
    → If one or both dates missing → keep existing planned_periods

CHECK 7: Periods Allocation Sync
    If any row in batch has scheduled_start_date set:
        Call $this->syncPeriodsAllocation(sessionId, classId, sectionId, subjectId, ...)
        → Resolves subject_study_format_id (skip if none active)
        → Builds date map from all date ranges
        → updateOrCreate per unique (session+date+class+section+subject+format)
    → If no dates in batch → skip sync
```

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status | Trigger |
|----------|--------------|-------------|---------|
| Row is locked | (Silent skip — no error message returned) | 200 | Locked row skipped in saveScheduling loop |
| Missing permission | `AuthorizationException` → 403 | 403 | User without `tenant.lesson.update` |
| Invalid schedule_id | (Silent skip — `find()` returns null) | 200 | schedule_id not in database |
| Database save error | "Error saving scheduling: {message}" | 500 | DB write failure, transaction rollback |
| Request validation failure | Standard Laravel validation error JSON | 500 | Missing required fields (rows, class_id, subject_id) |
| No subject study format for sync | (Silent return — no allocation records created) | 200 | `SubjectStudyFormat::where('subject_id', $subjectId)->where('is_active', 1)` returns null |
| No allocation data for auto-schedule | ppd defaults to 1 | 200 | `PeriodsAllocation::max('tot_periods_in_day')` returns null |

---

## Success Scenarios

**Scenario 1: Batch Save with Teacher and Dates**
The HOD modifies `assigned_teacher_id`, `scheduled_start_date` (2026-07-15), and `scheduled_end_date` (2026-07-18) for 3 rows and clicks Save Dates. `saveScheduling()` processes each row: skips none (unlocked), sets dates and teacher, cascades to `taught_by_teacher_id`, recalculates `planned_periods = 4 days × 2 ppd = 8`, calls `syncPeriodsAllocation()` which creates records for July 15-18. Transaction commits. Response: `{ success: true, message: "Scheduling saved successfully!" }`.

**Scenario 2: Auto-Schedule Distributing Topics**
The HOD clicks Auto Schedule. `autoSchedule()` reads `MAX(tot_periods_in_day)=2` ppd from allocation, identifies zero locked rows, and distributes: Row 1 (planned_periods=3) → July 1-2, Row 2 (planned_periods=4) → July 2-4, Row 3 (planned_periods=2) → July 4-5. Response includes `{ rows: [{schedule_id, start, end, planned_periods}], ppd: 2, wpw: 10 }`.

**Scenario 3: Locking Confirmed Rows**
HOD locks 5 critical rows via `POST /planning/{id}/toggle-lock`. Server flips `is_locked = !$schedule->is_locked`. The `saveScheduling()` loop skips locked rows with `continue`, preserving their dates and teachers.

---

## Failure Scenarios

**Scenario 1: Locked Row Silently Skipped**
A teacher changes dates on 10 rows including 2 locked ones. `saveScheduling()` encounters locked rows, calls `continue`, and only saves the 8 unlocked rows. No error is returned for the locked rows. The teacher does not receive a warning — they must check lock status manually.

**Scenario 2: Subject Has No Study Format — Allocation Sync Skipped**
The sync algorithm in `syncPeriodsAllocation()` queries `SubjectStudyFormat::where('subject_id', $subjectId)->where('is_active', 1)->value('id')`. If null, the method returns early via `if (!$subjectStudyFormatId) return;`. No Periods Allocation records are created. The scheduling dates are still saved, but no allocation audit trail exists.

**Scenario 3: Auto-Schedule With No Existing Allocation**
The Periods Allocation table has no records for this class+subject. `autoSchedule()` reads `max('tot_periods_in_day')` which returns null, defaulting ppd to 1. Topics are spread thinly (1 period per day). The HOD may notice the schedule spans more days than expected.

---

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_syllabus_schedule` | Database Table | Stores `id`, `lesson_id`, `topic_id`, `assigned_teacher_id`, `taught_by_teacher_id`, `scheduled_start_date`, `scheduled_end_date`, `planned_periods`, `is_locked`, `is_active`, `ordinal`, `priority` |
| `SyllabusSchedule` Model | Eloquent Model | `Modules\Syllabus\Models\SyllabusSchedule`, table `slb_syllabus_schedule`, uses `SoftDeletes` |
| `SyllabusController@planning()` | Controller | Renders `lesson_scheduling` tab with scheduling data and teacher list |
| `SyllabusController@saveScheduling()` | Controller | Batch save at `POST /planning/save-scheduling` |
| `SyllabusController@autoSchedule()` | Controller | Auto date calculation at `POST /planning/auto-schedule` |
| `SyllabusController@toggleLock()` | Controller | Lock toggle at `POST /planning/{id}/toggle-lock` |
| `SyllabusController@syncPeriodsAllocation()` | Private Method | Creates/updates `PeriodsAllocation` records per date in range |
| `slb_syllabus_periods_allocation` | Database Table | Provides ppd values; receives auto-generated records during save |
| `PeriodsAllocation` Model | Eloquent Model | `Modules\Syllabus\Models\PeriodsAllocation`, table `slb_syllabus_periods_allocation` |
| `subject_study_format` | Database Table | Resolves `subject_study_format_id` for allocation sync |
| `Employee` Model | Eloquent Model | `Modules\SchoolSetup\Models\Employee` — teacher list filtered by `is_teacher=true`, `is_active=true` |
| `ClassSection` Model | Eloquent Model | `Modules\SchoolSetup\Models\ClassSection` — resolves class_id, section_id, class_teacher_id |
| `tenant.lesson.update` | Permission | Gate authorization for save operations |
| View | Blade Template | `resources/views/lesson-management/partials/lesson-scheduling/index.blade.php` |
