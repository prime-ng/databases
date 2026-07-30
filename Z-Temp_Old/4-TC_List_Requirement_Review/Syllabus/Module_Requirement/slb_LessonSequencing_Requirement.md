# Lesson Sequencing — Business Requirements

## What This Screen Does

The Lesson Sequencing screen defines the teaching order and estimated time allocation for every topic within a subject. It acts as the foundational planning layer where academic coordinators arrange the entire syllabus into a logical, chronological sequence before dates and teachers are assigned.

By providing a drag-and-drop interface combined with configurable depth filtering, this screen allows schools to plan at their preferred granularity—whether at the broad Topic level, the detailed Sub-Topic level, or the highly granular Mini-Topic level. The sequencing data flows directly into the Lesson Scheduling and Lesson Date Planning screens, ensuring alignment from planning through execution.

---

## When This Screen Is Used

- Start of Term Setup used by HODs at the beginning of an academic term to arrange the teaching order for the entire subject
- Syllabus Restructuring when an academic coordinator needs to reorder topics due to curriculum changes, festival holidays, or exam schedules
- Period Estimation when defining how many classroom periods each topic requires, which feeds into workload and pacing calculations
- Config Level Adjustment when the school changes the teaching estimation level from Topic to Sub-Topic or Mini-Topic for more precise planning

## Default Data Load

This screen displays within the Syllabus Planning tab group. When the user navigates to Syllabus → Planning, SyllabusController@planning() applies default filters (class_section_id=1, subject_id=5, academic_session_id=7) and loads tab-specific data. Shared dropdowns include Class, Section, Class-Section, Subject, and Academic Session.

---

---

## Key Fields at a Glance

**Identity and Hierarchical Display**
The screen dynamically renders columns based on the configured estimation level. At Topic level, it shows Lesson and Topic. At Sub-Topic level, it adds a Sub-Topic column. At Mini-Topic level, it further adds a Mini-Topic column. Each row displays the human-readable name alongside the auto-generated tracking code for clear identification.

**Time Estimation**
A Planned Periods input captures the number of classroom periods allocated for each row. The screen enforces a configurable daily limit per row and a weekly limit across all rows. A running total at the bottom of the table provides instant feedback on the cumulative period count.

**Priority and Status**
A Priority dropdown with options for High, Medium, or Low determines the urgency displayed on teacher dashboards. A Status Toggle acts as an active or inactive switch, allowing topics to be excluded from the schedule without deleting their sequencing data.

**Ordinal Control**
An auto-numbered sequence column combined with a drag handle allows intuitive reordering. When rows are rearranged, the ordinal values automatically update to reflect the new teaching order.

---

## How This Screen Works — Logic Flow (Non-Technical)

Every time someone opens this screen and clicks Apply or Save, the system runs through a series of checklist-style decisions. Here is exactly how the logic flows, step by step:

### Step 1: Decide What to Show (Depth Filtering)

The system first asks: **"What level of detail should I display?"**

It reads one setting called `Syllabus Teaching Estimation Level`. Based on the answer, it follows this decision tree:

```
Configuration Value →     Columns Shown
─────────────────────────────────────────────
"Lesson"    →  Lesson Name only (one row per lesson)
"Topic"     →  Lesson + Topic 
"Sub-Topic" →  Lesson + Topic + Sub-Topic
"Mini-Topic"→  Lesson + Topic + Sub-Topic + Mini-Topic
```

**Why this matters:** If the school has topics nested 4 levels deep but the setting is "Topic", only the top-level topics appear. The deeper sub-topics and mini-topics are hidden. This prevents the table from showing hundreds of rows when the school only wants to plan at a broad level.

---

### Step 2: Load Data — Two Possible Sources

The system asks: **"Has this class+subject been sequenced before?"**

```
Condition                                        → What happens
────────────────────────────────────────────────────────────────────
No schedule records exist for this class+subject → Build rows from the Topic master table (first-time use)
Schedule records DO exist                        → Load existing rows from Syllabus Schedule table
```

**First-time behavior:** If no sequencing has ever been done, the system reads the Lesson and Topic master tables. It looks at every lesson in the subject, then finds all topics inside each lesson, then finds sub-topics inside topics, then mini-topics inside sub-topics. Each one becomes a row in the table with default values (periods = 0, priority = Medium, status = Active).

**Returning behavior:** If sequencing was already saved before, the system loads the exact saved rows with their saved order, periods, and priorities.

---

### Step 3: Build the Hierarchy Tree (Topic Traversal)

When building rows from scratch, the system follows this nesting logic to find every teachable unit:

```
For each Lesson in the subject:
    For each Root Topic inside the Lesson:
        Create a row with periods = sum of all its children's durations
        
        For each Sub-Topic inside the Root Topic:
            Create a row with periods = sum of all mini-topics inside it
            
            For each Mini-Topic inside the Sub-Topic:
                Create a row with periods = the mini-topic's own duration
```

**The period calculation:** The system does not just set periods to zero. It looks at the `duration_minutes` field on each topic. It rolls up the minutes from child topics to parent topics. If a root topic has sub-topics with 20 minutes, 30 minutes, and 10 minutes, the root topic's planned periods = sum of 20+30+10 = 60.

**Why this matters:** Teachers do not have to manually enter periods for high-level topics. The system attempts to calculate them automatically from the granular child topics. If the calculation gives zero (no duration set), the teacher must enter it manually.

---

### Step 4: Filter Rows by Depth Level

After the rows are loaded, the system applies the depth filter again. But this time it does not just hide columns—it **removes entire rows** that do not match the level.

The filter logic checks each row's topic level name:

```
Row's Topic Level Name →     Included or Excluded?
──────────────────────────────────────────────────────
Setting = "nano_topic"   →  Show only rows where topic type name contains "Nano"
Setting = "micro_topic"  →  Show rows where level is Micro (hide Nano)
Setting = "mini_topic"   →  Show rows where level is Mini (hide Micro, Nano)
Setting = "sub_topic"    →  Show rows where level is Sub (hide Mini, Micro, Nano)
Setting = "topic"        →  Show only root-level topics (hide everything else)
```

**The condition cheat:** The system checks the name of the topic level type using simple string matching. It looks for words like "nano", "micro", "mini", "sub" inside the level name. If the level is named "Sub-Topic" and the filter is "sub_topic", it matches. This approach is flexible—schools can rename their levels and the filter still works as long as the keyword is present.

---

### Step 5: Validate Before Save (Multiple Conditions)

When the user clicks **Save Teaching Sequence**, the system does **five checks in order**. If any check fails, the save stops immediately and an error message is shown:

```
Check 1: Are all rows valid?
    Condition: Each row must have lesson_id, topic_id, ordinal, priority
    If FAIL → Error: "Invalid row data. Please refresh and try again."
    
Check 2: Does any single row exceed the daily period limit?
    Condition: planned_periods > daily_limit (from Periods Allocation table)
    If FAIL → Error: "Planned periods (X) exceeds the daily allocation limit (Y) for this class + subject."
    
Check 3: Does the total of all rows exceed the weekly limit?
    Condition: SUM of all planned_periods > weekly_limit
    If FAIL → Error: "Total planned periods (X) exceeds the weekly allocation limit (Y)."
    
Check 4: Is there a class teacher to auto-assign?
    Condition: section_id is set AND class_teacher_id exists in Class-Section mapping
    If YES → Auto-assign teacher to all rows
    If NO → Leave teacher as null (can be assigned later in Scheduling tab)
    
Check 5: Does each row already have a schedule ID?
    Condition: schedule_id is NOT empty → UPDATE existing record
    Condition: schedule_id is empty → INSERT new record
```

**Why this matters:** The system never saves partially. Either all rows pass all checks and are saved together, or none are saved. This prevents situations where some topics get sequenced but others do not due to an error midway.

---

### Step 6: Save All Rows in One Transaction

Once all checks pass, the system saves every row in a single batch:

```
BEGIN Transaction
    For each row in the submitted data:
        IF schedule_id EXISTS → UPDATE that record with new ordinal, periods, priority, status
        IF schedule_id is EMPTY → INSERT a new record with class, subject, section, lesson, topic
COMMIT Transaction
```

If the database has an error at any point during saving (for example, the 10th row out of 50 fails), the entire save is rolled back. Nothing is saved. The user gets an error message and must try again.

---

## Business Rules and Conditions

**Configurable Depth Filtering**
The system reads a global configuration setting called Syllabus Teaching Estimation Level. Based on this setting, the screen filters which depth of topics are displayed. If set to Mini-Topic, only rows with a Mini-Topic level are shown. If set to Topic, only root-level topics appear. This prevents the interface from being cluttered with irrelevant granularity.

**Period Allocation Limits**
The system reads Periods Allocation data from the Timetable module to enforce constraints. Each row's planned periods cannot exceed the daily limit for that class, subject, and section. The sum of all planned periods across rows cannot exceed the weekly limit. Validation errors are thrown before save if limits are violated.

**Bulk Save with Transaction**
All rows are saved in a single database transaction. If any row fails validation or save, the entire operation is rolled back to prevent partial updates. Rows with an existing schedule ID are updated; rows without one are newly created as syllabus schedule records.

**Teacher Auto-Assignment on Save**
When sequencing is saved for a specific section, the system attempts to resolve the class teacher from the Class-Section mapping. If found, the teacher is auto-assigned to all sequenced topics. This provides a sensible default that can be overridden in the Lesson Scheduling screen.

**Paginated Display with In-Memory Filtering**
The table can show hundreds of rows, but the display is paginated at 50 rows per page. The pagination works on the already-filtered data. When a user changes pages, any unsaved changes are automatically saved first via an AJAX call before navigating to the next page.

---

## Conditions at a Glance — Decision Table

| Condition | Check | If True | If False |
|-----------|-------|---------|----------|
| Has schedule data? | Query syllabus_schedule table | Load existing rows | Build from Topic master |
| Level = "topic"? | Read config setting | Show only root topics | Show deeper levels |
| Single row periods > daily limit? | Compare planned_periods vs max | ❌ Reject save | ✅ Allow |
| Total periods > weekly limit? | SUM all planned_periods vs max | ❌ Reject save | ✅ Allow |
| Section has class teacher? | Check ClassSection mapping | Auto-assign teacher | Leave teacher empty |
| Row has schedule_id? | Check primary key | UPDATE existing | INSERT new |

---

## Workflow Steps

**Setting Up the Teaching Sequence**
The Science HOD navigates to the Syllabus Module and opens the Lesson Sequencing tab. They select Class 9, Section A, and Subject Science from the filter, then click Apply. The system loads all topics for Science at the configured depth level. The HOD reviews the default order and uses the drag handle to move "Laws of Motion" before "Motion and its Types". They adjust the planned periods for each topic—setting 4 periods for complex topics and 2 for simpler ones. They mark a few optional topics as Inactive using the toggle. Finally, they click Save Teaching Sequence, and the system validates the limits, auto-assigns the class teacher, and persists the data.

---

## Example Scenario

The school administration decides to switch from Topic-level planning to Mini-Topic-level planning for more accurate teacher workload tracking. The Academic Director opens the Settings tab and changes the Syllabus Teaching Estimation Level to Mini-Topic. They return to Lesson Sequencing, select a class and subject, and click Apply. The system follows Step 1 (reads the new config), Step 2 (loads topics from master), Step 3 (builds hierarchy 4 levels deep), and Step 4 (filters to show only Mini-Topic rows). The table now displays rows at the Mini-Topic depth, showing 3 times more rows than before. Each row represents a finer unit of teaching. The HOD adjusts the periods accordingly—now allocating precise numbers like 1 period per Mini-Topic instead of broad estimates. The system respects the same daily and weekly limits but now allows much more granular capacity planning.

---

## Related Screens

- **Lesson Scheduling** — Consumes the sequenced order and planned periods to assign teachers and target dates
- **Lesson Date Planning** — Uses the sequencing order as the baseline for auto-generating the calendar timeline
- **Settings** — The Syllabus Teaching Estimation Level configuration controls which depth is displayed in this screen
- **Periods Allocation** — Provides the daily and weekly period limits that this screen enforces during save

---

## Requirements

- The system MUST display sequencing rows under the `lesson_sequencing` tab of `planning.index`, filtered by class_section_id and subject_id
- If `SyllabusSchedule` records exist for the filters, load with `lesson`, `topic`, `topicLevelType`, `topic.parent`, `topic.parent.parent` relations, ordered by `ordinal`, `id`
- If no Schedule records exist, call `SyllabusController@buildSequencingFromCrud()` which walks `Lesson → Topic (root → sub → mini)`, computing `planned_periods` from `duration_minutes` roll-up (root gets sum of sub's children durations; sub gets sum of mini-topic durations; mini-topic uses its own duration)
- Rows MUST be filtered by depth level using `SyllabusController@filterRowsByLevel()` which uses exact `nano_topic`/`micro_topic`/`mini_topic`/`sub_topic` matching: shows only rows where the specific level column is non-null and higher levels are null
- Paginate at 50 rows per page using `seq_page` parameter via `LengthAwarePaginator`
- Save via `POST /planning/save-sequencing` (route: `planning.saveSequencing`) with `Gate::authorize('tenant.lesson.update')`
- Request validation: `rows.*.lesson_id` required, `rows.*.topic_id` required, `rows.*.ordinal` required integer min:1, `rows.*.priority` required in:HIGH,MEDIUM,LOW, `rows.*.is_active` required boolean, `rows.*.planned_periods` nullable numeric min:0 max:100
- Per-row daily limit check: `planned_periods > COALESCE(MAX(tot_periods_in_day), 10)` → reject with 500
- Total weekly limit check: `SUM(planned_periods) > COALESCE(MAX(tot_periods_in_week), 99)` → reject with 500
- Class teacher auto-assignment: resolve `ClassSection` by `class_id + section_id`, walk fallback chain: `class_teacher_id` → try `Employee::where('user_id', ...)` → try `Employee::find(...)` → try first active teacher
- All rows saved in a single `DB::transaction()`: rows with `schedule_id` UPDATE, rows without INSERT
- Default depth level read from `SchConfig` key `syllabus_teaching_estimation_level_for_lesson_planning`, normalized to snake_case
- Default daily limit: 10, default weekly limit: 99 (applied when PeriodsAllocation has no records)

---

## Who Can Access This Screen

| Role | Access Level | Permission | Notes |
|------|-------------|------------|-------|
| HOD / Academic Coordinator | Full Access | `tenant.lesson.update` | Can reorder topics, set periods, change priority/status, save sequences |
| Teacher | Read-Only | `tenant.lesson.viewAny` | Can view the sequence order but cannot modify |
| Administrator | Full Access | `tenant.lesson.update` | Can access all sequencing features |
| Principal / Director | Read-Only | `tenant.lesson.viewAny` | Can review the planned sequence but cannot edit |
| System Admin | Full Access | `tenant.lesson.update` | Full access to all sequencing operations |

---

## Validate Before Save (Multiple Conditions)

The `SyllabusController@saveSequencing()` validates in order:

```
CHECK 1: Gate Authorization
    Gate::authorize('tenant.lesson.update')
    → If NO → 403 Forbidden
    → If YES → Continue

CHECK 2: Request Structure Validation
    $request->validate([...]) — Laravel FormRequest-style inline
    → rows must be array, each row requires lesson_id, topic_id, ordinal, priority
    → If FAIL → 500 with validation errors

CHECK 3: Daily Period Limit (per row)
    $dailyLimit = PeriodsAllocation::MAX(tot_periods_in_day) defaults to 10
    For each row: if (float) $row['planned_periods'] > $dailyLimit
    → If ANY row exceeds → 500 error: "Planned periods (X) exceeds the daily allocation limit (Y)..."
    → If all pass → Continue

CHECK 4: Weekly Period Limit (sum of all rows)
    $totalPeriods = sum of all rows' planned_periods
    $weeklyLimit = PeriodsAllocation::MAX(tot_periods_in_week) defaults to 99
    If $totalPeriods > $weeklyLimit
    → 500 error: "Total planned periods (X) exceeds the weekly allocation limit (Y)..."
    → If pass → Continue

CHECK 5: Class Teacher Auto-Assignment
    If $sectionId is set:
        Query ClassSection where class_id + section_id
        If class_teacher_id found:
            Fallback chain: Employee::where('user_id', class_teacher_id)
                → Employee::find(class_teacher_id)
                → first active teacher
        → Set $classTeacherEmployeeId (may remain null)
    → assigned_teacher_id in update/insert data uses this value

CHECK 6: Transactional Save
    DB::beginTransaction()
    For each row:
        If schedule_id is NOT empty → UPDATE existing SyllabusSchedule
        If schedule_id IS empty → INSERT new SyllabusSchedule
    DB::commit()
    → If any exception → DB::rollBack() → 500 error
```

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status | Trigger |
|----------|--------------|-------------|---------|
| Missing permission | `AuthorizationException` → 403 | 403 | User without `tenant.lesson.update` |
| Row missing required field | Laravel validation error JSON | 500 | Missing `lesson_id`, `topic_id`, `ordinal`, or `priority` |
| Single row exceeds daily limit | "Planned periods ({X}) exceeds the daily allocation limit ({Y}) for this class + subject." (500 JSON) | 500 | `planned_periods > daily_limit` |
| Total exceeds weekly limit | "Total planned periods ({X}) exceeds the weekly allocation limit ({Y}) for this class + subject. Please reduce the periods." (500 JSON) | 500 | `SUM(planned_periods) > weekly_limit` |
| Database transaction failure | "Error saving sequence: {exception message}" (500 JSON) | 500 | Any row fails to insert/update within the transaction |
| Invalid planned_periods format | "The rows.0.planned_periods must be a number." (500 JSON) | 500 | Non-numeric value submitted for planned_periods |
| Invalid priority value | "The rows.0.priority must be one of HIGH, MEDIUM, LOW." (500 JSON) | 500 | Priority outside allowed enum |

---

## Success Scenarios

**Scenario 1: First-Time Sequence Creation**
HOD opens Lesson Sequencing for Class 9 Science with no existing Schedule records. `buildSequencingFromCrud()` walks Lesson → Topic → Sub-Topic → Mini-Topic hierarchy, computing `$rootDur = sum of minis(20+30+10)` and `$subDur = sum of minis(15+25)`. Each row gets `planned_periods` from roll-up, `priority='MEDIUM'`, `is_active=true`. HOD adjusts periods, drags to reorder (ordinals auto-update), clicks Save. `saveSequencing()` validates daily limit (max row=8, limit=10 → pass), weekly limit (total=45, limit=99 → pass), resolves class teacher (Employee via ClassSection.class_teacher_id), inserts 30 rows in transaction. Response: `{ success: true, message: "Teaching sequence saved successfully!" }`.

**Scenario 2: Reordering Existing Sequence**
HOD drags "Chemical Reactions" above "Acids and Bases". Ordinal values renumber client-side. Page change triggers auto-save AJAX calling `saveSequencing()` with updated ordinals. The UPDATE path runs for each existing `schedule_id`. Transaction commits.

**Scenario 3: Weekly Limit Prevents Overscheduling**
HOD sets total planned_periods = 50 but weekly_limit (from `PeriodsAllocation::MAX(tot_periods_in_week)`) = 30. Check 4 fails. Response: `{ success: false, message: "Total planned periods (50) exceeds the weekly allocation limit (30)..." }`. HOD reduces periods and re-saves.

---

## Failure Scenarios

**Scenario 1: Daily Limit Violation**
HOD sets 8 planned_periods for "Magnetism" but `MAX(tot_periods_in_day) = 5`. Check 3 fails: "Planned periods (8) exceeds the daily allocation limit (5) for this class + subject." HOD must reduce before saving.

**Scenario 2: Transaction Rollback on DB Error**
During save, the 15th row violates a FK constraint. `DB::rollBack()` reverts all 30 rows. No partial data persists. Response: `{ success: false, message: "Error saving sequence: SQLSTATE[23000]..." }`.

**Scenario 3: Class Teacher Not Found**
ClassSection has `class_teacher_id = 99` but no Employee matches (user_id=99 not found, Employee::find(99) not found, no active teachers). `$classTeacherEmployeeId` remains null. All rows save with `assigned_teacher_id = null`. Teacher must be assigned manually in Lesson Scheduling tab.

---

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_syllabus_schedule` | Database Table | Primary table; stores `id`, `lesson_id`, `topic_id`, `topic_level_type_id`, `ordinal`, `planned_periods`, `priority`, `is_active`, `assigned_teacher_id`, `class_id`, `section_id`, `subject_id`, `academic_session_id` |
| `SyllabusSchedule` Model | Eloquent Model | `Modules\Syllabus\Models\SyllabusSchedule`, table `slb_syllabus_schedule`, uses `SoftDeletes` |
| `SyllabusController@planning()` | Controller | Renders `lesson_sequencing` tab with sequencing data (lines 376-493) |
| `SyllabusController@saveSequencing()` | Controller | Handles save at `POST /planning/save-sequencing` (line 651) |
| `SyllabusController@buildSequencingFromCrud()` | Private Method | First-time data build from `Lesson` + `Topic` master tables (line 1139) |
| `SyllabusController@filterRowsByLevel()` | Private Method | Filters rows by depth level (line 1245) |
| `slb_lessons` | Database Table | Lesson master; provides `name`, `code`, `class_id`, `subject_id` |
| `slb_topics` | Database Table | Topic master; provides `name`, `code`, `duration_minutes`, `parent_id`, `level_id` |
| `slb_topic_level_types` | Database Table | Defines hierarchy level names and `level` ordering |
| `slb_syllabus_periods_allocation` | Database Table | Provides `MAX(tot_periods_in_day)` (default 10) and `MAX(tot_periods_in_week)` (default 99) for limit validation |
| `sch_configs` | Database Table | Stores `syllabus_teaching_estimation_level_for_lesson_planning` for depth filtering |
| `ClassSection` Model | Eloquent Model | `Modules\SchoolSetup\Models\ClassSection` — resolves class_teacher_id for auto-assignment |
| `Employee` Model | Eloquent Model | `Modules\SchoolSetup\Models\Employee` — teacher auto-assignment fallback chain |
| `tenant.lesson.update` | Permission | Gate authorization for save operations |
| View | Blade Template | `resources/views/lesson-management/partials/lesson-sequencing/index.blade.php` |
