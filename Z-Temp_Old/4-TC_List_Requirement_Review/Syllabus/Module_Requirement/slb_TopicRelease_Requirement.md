# Topic Release Control — Business Requirements

## What This Screen Does

The Topic Release Control screen serves as the monitoring dashboard for the automated content release engine. It provides a read-only view into the release status of homework, quizzes, and learning quests across the entire syllabus hierarchy.

Rather than allowing teachers to manually toggle content visibility, this screen tracks whether the system has successfully linked and released LMS resources for each scheduled topic. It acts as an audit tool, answering the question: For every topic being taught, have the corresponding homework, quiz, and quest resources been properly attached and made available to students? The screen respects the configured release levels from the Syllabus Settings, ensuring that only topics at the correct hierarchy depth are evaluated.

---

## When This Screen Is Used

- Pre-Teaching Readiness Check used by teachers before starting a new topic to verify that homework and quizzes are ready for release
- Content Gap Analysis used by HODs to identify topics that have no linked LMS resources and need content creation
- Release Status Monitoring used by Academic Directors to verify that the automated release cron job is functioning correctly
- Audit and Compliance used by the administration to prove that all assessable topics have associated assessments before the exam period begins

## Default Data Load

This screen displays within the Syllabus Planning tab group. When the user navigates to Syllabus → Planning, SyllabusController@planning() applies default filters (class_section_id=1, subject_id=5, academic_session_id=7) and loads tab-specific data. Shared dropdowns include Class, Section, Class-Section, Subject, and Academic Session.

---

---

## Key Fields at a Glance

**Content Hierarchy Display**
Columns dynamically render based on the configured release level from the Syllabus Settings. If the Homework Release Level is set to Sub-Topic, the table shows Lesson, Topic, and Sub-Topic columns. If set to Mini-Topic, a Mini-Topic column is added. At the most granular level, Micro-Topic and Nano-Topic columns are also displayed. Each cell shows the entity name with its auto-generated tracking code below.

**Release Type Filter**
A dropdown filter allows the user to switch between Homework, Quiz, and Quest release views. Changing the filter reloads the table with the appropriate hierarchy level based on the corresponding release level setting. The current release type is displayed as a badge in the info bar.

**LMS Linked Status**
A status badge column indicates whether an LMS resource of the selected type exists and is linked to the topic. A green "Yes" badge with a link icon means a homework, quiz, or quest is attached. A gray "No" badge with a link-slash icon means no resource is linked, signaling a content gap.

**Release Status**
A status badge column indicates whether the linked resource has been released to students. A green "Released" badge means the resource has been published and is accessible. An amber "Pending" badge means the resource exists but has not yet been released, possibly awaiting a scheduled date or teacher action.

---

## How This Screen Works — Logic Flow (Non-Technical)

This screen has layered logic. Every action—applying filters, selecting a release type, loading data, or checking status—triggers a chain of decisions. Below is exactly how each part works.

### Step 1: Determine the Release Depth Level

When the user selects a release type from the dropdown (Homework, Quiz, or Quest), the system asks:

**"Which setting controls this release type?"**

```
Release Type Selected → Which Config Setting to Read
──────────────────────────────────────────────────────────
Homework             → homework_released_on_syllabus_level
Quiz                 → quiz_released_on_syllabus_level
Quest                → quest_released_on_syllabus_level
```

The system reads that specific setting from the database. If the setting has never been configured, it defaults to `topic`. The raw stored value (e.g., "Mini-Topic") is converted to lowercase with underscores (e.g., `mini_topic`) for internal comparison.

**Real example:** If the user selects "Quiz" and the Quiz Release Level setting is `Sub-Topic`, then the screen will filter data to show only Sub-Topic-level rows and will include Lesson + Topic + Sub-Topic columns.

---

### Step 2: Load the Data — Two Possible Sources

The system asks: **"Have schedules been created for this class+subject?"**

```
Condition                                               → What happens
────────────────────────────────────────────────────────────────────────────
YES: Schedule records exist in slb_syllabus_schedule     → Load rows from the Schedule table with hierarchy parents
NO: No schedule records found                            → Build rows from Lesson/Topic master tables (first-time use)
```

**Path A — Existing Schedules (most common):**
The system loads all Syllabus Schedule records for the selected filters. For each record, it looks at the topic's level name and walks up the parent chain to determine the full hierarchy:

```
Read the schedule record's topic → check its topic_level_type name

    IF name contains "nano"  → nano_topic = topic, micro = parent, sub = parent², root = parent³
    IF name contains "micro"  → micro_topic = topic, sub = parent, root = parent²
    IF name contains "mini"   → mini_topic = topic, sub = parent, root = parent²
    IF name contains "sub"    → sub_topic = topic, root = parent
    ELSE                      → root_topic = topic (this is a top-level topic)
```

This "parent walking" creates a flat row with up to 5 hierarchy columns (Lesson, Topic, Sub-Topic, Mini-Topic, Micro-Topic, Nano-Topic) regardless of how deep the actual nesting is.

**Path B — No Schedules Yet (first-time):**
If no Schedule records exist, the system calls a fallback method that builds rows directly from the Lesson and Topic master tables. It creates the same flat hierarchy structure but with default values and no release status. This ensures the screen never shows an empty table.

---

### Step 3: Filter Rows by Release Depth Level

After loading all rows, the system removes rows that are too deep or too shallow for the selected release type:

```
For each loaded row, check the topic_level field:

    Release setting = "nano_topic"  → Show ALL rows (no filtering)
    Release setting = "micro_topic" → Hide rows where level is "Nano" (too deep)
    Release setting = "mini_topic"  → Hide rows where level is Micro or Nano
    Release setting = "sub_topic"   → Hide rows where level is Mini, Micro, or Nano
    Release setting = "topic"       → Hide everything except root-level topics
```

**Why this matters:** If the Homework Release Level is set to "Sub-Topic", only Sub-Topic rows appear. Mini-Topics, Micro-Topics, and Nano-Topics are hidden because homework should not be released at those finer levels. This prevents teachers from seeing irrelevant granularity.

---

### Step 4: Check LMS Link and Release Status (Cross-Module Query Chain)

This is the most database-intensive step. For each remaining row, the system checks three external modules to determine whether a resource exists and has been released. The check depends on which release type is selected:

**If release type = Homework:**
```
For each row:
    Step 4a: Does a Homework exist for this class + subject + topic?
        Query: LMS Homework module → find homework records WHERE
            class_id = selected_class AND
            subject_id = selected_subject AND
            topic_id = this row's topic_id
        → If ANY homework found → is_linked = true
        → If NO homework found  → is_linked = false (skip to next row)

    Step 4b: Has any homework been released to students?
        If is_linked = true:
            Query: Homework Assignment table WHERE
                homework_id IN (found homework IDs) AND
                is_released = 1
            → If ANY assignment is released → is_released = true
            → If NO assignment is released  → is_released = false
```

**If release type = Quiz:**
```
For each row:
    Step 4a: Does a Quiz exist scoped to this topic?
        Query: LMS Quiz module → find quiz WHERE
            scope_topic_id = this row's topic_id
        → If quiz found → is_linked = true
        → If no quiz    → is_linked = false

    Step 4b: Has the quiz been allocated and activated?
        If is_linked = true:
            Query: Quiz Allocation table WHERE
                quiz_id = found quiz ID AND
                target_id = selected class AND
                is_active = 1
            → If allocation is active → is_released = true
            → Otherwise → is_released = false
```

**If release type = Quest:**
```
For each row:
    Step 4a: Does a Quest Scope exist for this topic?
        Query: LMS Quests module → find quest scopes WHERE
            topic_id = this row's topic_id
        → If any scopes found → is_linked = true
        → If none found      → is_linked = false

    Step 4b: Has any quest been allocated and activated?
        If is_linked = true:
            Query: Quest Allocation table WHERE
                quest_id IN (found quest IDs) AND
                target_id = selected class AND
                is_active = 1
            → If allocation is active → is_released = true
            → Otherwise → is_released = false
```

**Why the N+1 pattern:** For every row displayed in the table, the system runs 2-4 additional queries across different modules. If there are 30 rows, that is 60-120 separate database queries just to populate this screen. This is why the screen can feel slow for large datasets.

---

### Step 5: Cron-Driven Auto-Release (Background Job)

While the screen is read-only for humans, an automated cron command runs in the background to actually perform releases. Here is how that cron job works step by step:

```
SCHEDULE: Runs periodically via Laravel scheduler
COMMAND: php artisan tenant:syllabus:release-resources

STEP 1: Iterate over every school tenant
    For each tenant:
        Initialize tenant database connection

STEP 2: Read release level settings for this tenant
    homework_level = SchConfig: "homework_released_on_syllabus_level" (default: "Topic")
    quiz_level     = SchConfig: "quiz_released_on_syllabus_level"     (default: "Topic")
    quest_level    = SchConfig: "quest_released_on_syllabus_level"    (default: "Topic")

    Normalize: Remove all hyphens and underscores, lowercase everything
    Example: "Mini-Topic" → "minitopic", "Sub_Topic" → "subtopic"

STEP 3: Find all schedules whose start date has arrived
    Query: SyllabusSchedule WHERE scheduled_start_date <= today

STEP 4: For each schedule, check and release
    For each schedule found:
        Get the schedule's topic level name
        Normalize it the same way (remove hyphens/underscores, lowercase)

        IF schedule is ACTIVE:
            IF schedule level = homework level → Call syncHomeworkPublic(schedule, activate=true)
            IF schedule level = quiz level     → Call syncQuizPublic(schedule, activate=true)
            IF schedule level = quest level    → Call syncQuestPublic(schedule, activate=true)

        IF schedule is INACTIVE:
            IF schedule level = homework level → Call syncHomeworkPublic(schedule, activate=false)
            IF schedule level = quiz level     → Call syncQuizPublic(schedule, activate=false)
            IF schedule level = quest level    → Call syncQuestPublic(schedule, activate=false)

STEP 5: Log results and move to next tenant
```

**Decision tree for each schedule:**
```
                                                    ┌─ Level matches homework config? → Release homework
                            ┌─ Schedule is active?  ├─ Level matches quiz config?     → Release quiz
                            │                       └─ Level matches quest config?    → Release quest
    Schedule found ────────┤
                            │                       ┌─ Level matches homework config? → Deactivate homework
                            └─ Schedule is inactive? ├─ Level matches quiz config?     → Deactivate quiz
                                                    └─ Level matches quest config?    → Deactivate quest
```

**Why the level matching is fuzzy:** The system strips all separators (hyphens, underscores) before comparing. This means "Sub-Topic" matches "sub_topic" matches "subtopic". It is a deliberate design decision to tolerate minor formatting differences between how levels are stored and how they are compared.

---

## Business Rules and Conditions

**Configurable Depth Filtering**
The hierarchy depth displayed in the table is determined by the corresponding release level setting. For the Homework view, the system reads the Homework Release Level setting. For Quiz view, the Quiz Release Level setting. For Quest view, the Quest Release Level setting. Only topics at or above the configured level are displayed, ensuring the interface shows only the relevant rows for each resource type.

**Cross-Module Resource Verification**
The system queries three separate modules to determine link and release status. For homework, it checks the LMS Homework module for assignments linked by class, subject, and topic, then checks if those assignments have been marked as released. For quizzes, it checks the LMS Quiz module for quizzes scoped to the topic ID, then checks if quiz allocations exist and are active. For quests, it checks the LMS Quests module for quest scopes linked to the topic, then checks quest allocation status. Each query is scoped to the selected class and subject filter.

**Schedule-Aware Data Loading**
If syllabus schedule records already exist for the selected class, subject, and section, the screen loads data from the Syllabus Schedule table. If no schedules exist, the screen falls back to building rows directly from the Lesson and Topic master tables, showing default values without release status. This ensures the screen never appears empty even before scheduling is complete.

**Read-Only Monitoring Interface**
This screen is explicitly designed as a monitoring and audit tool. It does not provide toggle switches or action buttons to modify release status. All content release is managed by the automated cron job or through the individual LMS module interfaces. This separation of concerns ensures that release decisions follow the configured automation rules rather than ad-hoc manual overrides.

**Cron-Driven Auto Release Background Job**
A scheduled console command runs periodically across all tenants. It reads the three release level configurations and iterates over all syllabus schedules whose start date has arrived. For each schedule where the topic level matches the configured release level, it triggers the release service to publish homework, quiz, or quest resources. Deactivation occurs when a schedule is marked inactive. This ensures release actions happen automatically without teacher intervention.

---

## Conditions at a Glance — Decision Table

| Feature | Condition | If True | If False |
|---------|-----------|---------|----------|
| Release depth | Release Type = Homework? | Read homework_release_level | Read quiz/quest level |
| Data source | Schedule records exist? | Load from Schedule table | Build from master tables |
| Hierarchy walk | Level name contains "nano"? | Walk 4 parents up | Check micro/mini/sub |
| Level filter | Row level = configured depth? | Keep row in display | Remove row from display |
| LMS linked (HW) | Homework found for topic? | is_linked = true | is_linked = false |
| LMS released (HW) | HomeworkAssignment.is_released = 1? | is_released = true | is_released = false |
| LMS linked (Quiz) | Quiz scoped to topic? | is_linked = true | is_linked = false |
| LMS released (Quiz) | QuizAllocation.is_active = 1? | is_released = true | is_released = false |
| LMS linked (Quest) | QuestScope for topic? | is_linked = true | is_linked = false |
| LMS released (Quest) | QuestAllocation.is_active = 1? | is_released = true | is_released = false |
| Cron: schedule active? | is_active = true? | Call release service (activate) | Call release service (deactivate) |
| Cron: level matches? | Schedule level = config level? | Process this resource type | Skip this resource type |

---

## Workflow Steps

**Monitoring Release Readiness Before Teaching**
A week before the new term begins, the Science HOD opens the Topic Release Control screen. They select Class 9, Section A, and Subject Science. They set the Release Type to Homework. The table loads showing all topics at the configured Sub-Topic level. The HOD scans the LMS Linked column and notices that 5 out of 30 topics show "No" in red. They export this list and email the content team, requesting homework creation for those specific topics. They then switch the Release Type to Quiz and repeat the audit, finding that all topics have linked quizzes but only 20 out of 30 show "Released." They verify that the cron job is scheduled to run and will release the remaining 10 quizzes on their scheduled start dates.

---

## Example Scenario

The academic year is in full swing, and the Principal wants to verify that the automated content release system is working as intended. They open the Topic Release Control screen and filter by Release Type = Quest for Class 10 Science. The table displays 20 topics at the Mini-Topic level. All show "Yes" for LMS Linked and "Released" for Release Status. However, the Principal notices that one topic titled "Chemical Bonding Lab" shows "Pending" instead of "Released." Upon investigation, they discover that the scheduled start date for this topic is next week, so the cron job has not yet processed it. The Principal confirms that the system is functioning correctly—content is released only when the scheduled teaching window arrives, preventing students from accessing materials too far in advance.

---

## Related Screens

- **Lesson Scheduling** — Provides the teacher assignments and date ranges that drive the auto-release timing
- **Lesson Date Planning** — Provides the scheduled start dates that the cron job uses to determine when to release content
- **Settings** — The Homework, Quiz, and Quest Release Level settings determine the hierarchy depth displayed in this screen
- **LMS Homework / Quiz / Quest Modules** — The external modules where the actual content resources are created and managed
- **Syllabus Reports** — Consumes release status data for compliance auditing and coverage analysis

---

## Requirements

- The system MUST display release status under the `topic_release_control` tab of `planning.index` — a read-only monitoring view with no save actions
- View rendered by `resources/views/lesson-management/partials/topic-release-control/index.blade.php`
- Three filter inputs: `class_section_id` (resolved to `class_id`+`section_id`), `subject_id`, and `release_type` (homework|quiz|quest)
- **Data source priority:** If `SyllabusSchedule` records exist for the filters → load from Schedule table with `lesson`, `topic`, `topicLevelType`, `topic.parent`, `topic.parent.parent` relations (same hierarchy walking as Sequencing/Scheduling); otherwise fall back to `buildSequencingFromCrud()` from Lesson/Topic masters
- **Depth level:** Determined by `release_type`: reads corresponding `SchConfig` (`homework_released_on_syllabus_level`, `quiz_released_on_syllabus_level`, `quest_released_on_syllabus_level`), normalized to snake_case, default `topic`
- **Filtering:** `SyllabusController@filterRowsByLevel()` removes rows whose level is deeper than configured — e.g., `sub_topic` level hides Mini/Micro/Nano rows
- **LMS Linked check (per row, in planning() map):**
  - Homework: `Homework::where('class_id', $classId)->where('subject_id', $subjectId)->where('topic_id', $topicId)->pluck('id')`; `HomeworkAssignment::whereIn('homework_id', $hwIds)->where('is_released', 1)->exists()` for release
  - Quiz: `Quiz::where('scope_topic_id', $topicId)->value('id')`; `QuizAllocation::where('quiz_id', $quizId)->where('target_id', $classId)->where('is_active', 1)->exists()` for release
  - Quest: `QuestScope::where('topic_id', $topicId)->pluck('quest_id')`; `QuestAllocation::whereIn('quest_id', $questIds)->where('target_id', $classId)->where('is_active', 1)->exists()` for release
- **AJAX toggle:** `TopicController@toggleReleaseStatus()` at `POST /topics/{id}/toggle-release` (route: `topic.toggleReleaseStatus`) with `Gate::authorize('tenant.topic.update')` — supports `type=schedule` with `field=homework|quiz|quest` and `is_active` boolean; calls `TopicReleaseControlService::syncAllocation()` which flips `schedule.is_active` and calls the appropriate sync method
- **Service:** `TopicReleaseControlService` at `Modules\Syllabus\Services\TopicReleaseControlService` — methods `syncAllocation()`, `syncHomeworkPublic()`, `syncQuizPublic()`, `syncQuestPublic()`
- **Display only** — no create/update/delete buttons; the only action is an optional AJAX toggle for release status
- Default release type: `homework`

---

## Who Can Access This Screen

| Role | Access Level | Permission | Notes |
|------|-------------|------------|-------|
| HOD / Academic Coordinator | Read-Only (View) | `tenant.lesson.viewAny` | Can monitor release readiness; cannot toggle |
| Teacher | Read-Only | `tenant.lesson.viewAny` | Can verify their topics have linked resources before teaching |
| Administrator | Full (Toggle) | `tenant.topic.update` | Can toggle release status via AJAX |
| Principal / Director | Read-Only | `tenant.lesson.viewAny` | Can verify compliance and cron job functionality |
| System Admin | Full (Toggle) | `tenant.topic.update` | Can toggle release status for any schedule |

---

## Validate Before Save (Multiple Conditions)

**No user-facing save action on this screen — it is read-only.** The `TopicController@toggleReleaseStatus()` AJAX toggle performs:

```
CHECK 1: Gate Authorization
    Gate::authorize('tenant.topic.update')
    → If NO → 403 Forbidden
    → If YES → Continue

CHECK 2: Request Validation
    $request->validate([
        'type' => 'nullable|in:level,schedule,lesson,sync_all',
        'field' => 'nullable|string',
        'is_active' => 'required|boolean',
        'lesson_id' => 'nullable|integer',
        'class_id' => 'nullable|integer',
        'subject_id' => 'nullable|integer',
        'view_mode' => 'nullable|in:grid,list',
        'release_date' => 'nullable|date',
        'schedule_date' => 'nullable|date',
        'result_date' => 'nullable|date',
    ])
    → If FAIL → 500 with validation errors

CHECK 3: Resource Type Resolution
    If $type === 'schedule':
        $resourceType = match($field): 'homework'/'quiz'/'quest' → corresponding type, default → null
    → If $resourceType is null → Return: { success: false, message: "Invalid release field" }

CHECK 4: Service Call
    $releaseService->syncAllocation($id, $resourceType, $isActive, $dates)
    → Flips $schedule->is_active based on $isActive
    → Returns: { success: true, message: "Schedule release status updated." }
```

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status | Trigger |
|----------|--------------|-------------|---------|
| No schedules exist for filters | Empty table — "Select Class & Section and Subject above, then click Apply" | N/A (view) | No Schedule records and no CRUD data for selected filters |
| No LMS resource linked | Gray "No" badge displayed in table | N/A (view) | Cross-module query returns empty collection |
| Invalid toggle field | "Invalid release field" | 400 | `field` parameter is not homework/quiz/quest |
| Missing permission on toggle | `AuthorizationException` → 403 | 403 | User without `tenant.topic.update` |
| Toggle validation failure | Laravel validation error JSON | 500 | Missing `is_active` or invalid `type` value |
| Service: no homework linked | "No ON_TOPIC_COMPLETE homework linked to this schedule." | 200 (in response) | No Homework records match schedule's class+subject+topic |
| Service: no quiz linked | "No quiz found linked to this topic." | 200 (in response) | No Quiz with scope_topic_id matching schedule's topic |
| Service: no quest linked | "No quests found for this topic." | 200 (in response) | No QuestScope records for schedule's topic_id |

---

## Success Scenarios

**Scenario 1: Pre-Teaching Readiness Check**
HOD opens Topic Release Control, selects Class 9 Science, Release Type = Homework. `planning()` reads `homework_released_on_syllabus_level` config (normalized to `sub_topic`), loads Schedule records, walks hierarchy (topic.parent, topic.parent.parent), filters to Sub-Topic level only. For each of 25 rows, queries `Homework::where('class_id',9)->where('subject_id',5)->where('topic_id',$topicId)` for link status, then `HomeworkAssignment::whereIn('homework_id',$ids)->where('is_released',1)` for release status. Table shows 20 rows green (Yes/Released), 5 rows gray (No/Pending).

**Scenario 2: Toggling Release Status via AJAX**
User clicks toggle button for a schedule. `POST /topics/{id}/toggle-release` with `{type:"schedule", field:"homework", is_active:true}`. `toggleReleaseStatus()` validates, resolves `resourceType='homework'`, calls `syncAllocation($id, 'homework', true)`. Service flips `schedule.is_active = true`. Response: `{ success: true, message: "Schedule release status updated." }`.

**Scenario 3: Fallback to Master Tables When No Schedules**
No Schedule records exist for selected class+subject. `hasExistingSchedule` check returns false. `planning()` calls `buildSequencingFromCrud()` which walks Lesson → Topic hierarchy and builds rows with null `is_linked` and `is_released`. Table shows the hierarchy but all LMS and Release columns show defaults (No/Pending).

---

## Failure Scenarios

**Scenario 1: No LMS Resources Created**
HOD selects Quiz view. For each row, `Quiz::where('scope_topic_id', $topicId)->value('id')` returns null. `$isLinked = false`. All rows show gray "No" badge in LMS Linked column and "Pending" in Release Status. No content gaps can be resolved from this screen — quizzes must be created in the LMS Quiz module.

**Scenario 2: Toggle Fails on Missing Homework**
User toggles homework release for a schedule where no `ON_TOPIC_COMPLETE` homework exists. `syncHomework()` returns `{ success: false, message: "No ON_TOPIC_COMPLETE homework linked to this schedule." }`. The toggle request resolves but the sync operation reports failure in its response.

**Scenario 3: Level Mismatch After Config Change**
Admin changes Homework Release Level from `sub_topic` to `topic`. Next page load, `$trcDurLevel = 'topic'`. `filterRowsByLevel()` removes all rows below root Topic level. Previously visible Sub-Topic rows disappear from the view. Existing released homework remains active but is no longer displayed.

---

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_syllabus_schedule` | Database Table | Primary data source; stores `id`, `lesson_id`, `topic_id`, `topic_level_type_id`, `scheduled_start_date`, `is_active`, `class_id`, `section_id`, `subject_id`, `academic_session_id`, `ordinal` |
| `SyllabusSchedule` Model | Eloquent Model | `Modules\Syllabus\Models\SyllabusSchedule` |
| `SyllabusController@planning()` | Controller | Builds release control data (lines 212-351) with hierarchy walking, level filtering, and LMS status queries |
| `TopicController@toggleReleaseStatus()` | Controller | AJAX toggle at `POST /topics/{id}/toggle-release` (line 670) |
| `TopicReleaseControlService` | Service | `Modules\Syllabus\Services\TopicReleaseControlService` — `syncAllocation()`, `syncHomeworkPublic()`, `syncQuizPublic()`, `syncQuestPublic()`, `getLessonStats()` |
| `slb_lessons` | Database Table | Lesson master for hierarchy fallback display |
| `slb_topics` | Database Table | Topic master with `parent_id` for hierarchy walking; provides topic codes/names |
| `slb_topic_level_types` | Database Table | Defines hierarchy level names for level matching |
| `sch_configs` | Database Table | Stores `homework_released_on_syllabus_level`, `quiz_released_on_syllabus_level`, `quest_released_on_syllabus_level` |
| `Homework` / `HomeworkAssignment` | External Models | `Modules\LmsHomework\Models\Homework`, `HomeworkAssignment` — link/release status for homework |
| `Quiz` / `QuizAllocation` | External Models | `Modules\LmsQuiz\Models\Quiz`, `QuizAllocation` — link/release status for quizzes |
| `QuestScope` / `QuestAllocation` | External Models | `Modules\LmsQuests\Models\QuestScope`, `QuestAllocation` — link/release status for quests |
| `tenant.topic.update` | Permission | Gate authorization for AJAX toggle |
| `tenant.lesson.viewAny` | Permission | Gate authorization for read-only view |
| View | Blade Template | `resources/views/lesson-management/partials/topic-release-control/index.blade.php` |
