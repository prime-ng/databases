# Quest Tab 1: Dashboard

This is the first tab the teacher sees when they open the Quest module. It gives a quick overview of everything happening with quests — summary numbers, charts, and recent activity — all in one place.

---

## How It Works

When the teacher opens this tab, they see several summary cards at the top. One card shows the total number of quests in the system. Another shows how many are currently published and available to students. A third shows the total questions assigned across all quests. A fourth shows how many students have been allocated to quests. And a fifth shows the total number of attempts made by students so far.

Below the summary cards, there are charts. One chart shows how student scores are distributed — how many students scored in each range from 0-20% up to 81-100%. Another shows quest activity over the past year, month by month. A third breaks down quests by subject, so the teacher can see which subjects get the most assessment activity. A fourth shows quest status breakdown — how many are in Draft, Published, Ongoing, or Completed.

At the bottom, there is a list of the most recently created or updated quests. Each entry shows the quest title, its class and subject, its current status with a colored badge, and when it was created. The teacher can click any quest title to go directly to that quest's details.

Everything on this tab is read-only — it is designed for a quick visual check, not for taking actions. If the teacher wants to do something with a specific quest, they click through to the relevant tab.

---

## Important Business Rules

- The data is always live — it queries the database in real time. For schools with many quests and students, the dashboard might take a moment to load. The summary cards appear one by one as the data comes in.
- If no quests exist yet, the cards all show zero and the charts are empty. A message appears: "Create your first quest to see dashboard data."
- The dashboard only shows data for the teacher's own school. Admins see data across all schools in their system.
- All dashboard elements are read-only. No actions can be performed from this tab — it is purely informational.
- The recent quests list is limited to the 10 most recently updated quests. If the teacher needs to find an older quest, they must use the Quest Creation tab.
- Charts are rendered client-side using JavaScript charting libraries. Exporting charts requires using the browser's screenshot or print functionality.

---

## Deep Analysis

### Business Workflows & State Machines

**Dashboard Data Flow:**
The dashboard aggregates data from across the Quest module — `lms_quests` (counts by status), `lms_quest_allocations` (student allocation counts), student attempt tables (attempt totals), and scope/question junctions. It runs 5-7 independent database queries in parallel. Each query filters by `academic_session_id` and the teacher's assigned classes.

**State Dependency:** Dashboard KPIs are entirely read-only and reflect the current state of the quest life-cycle (Draft → Pending → Published → Ongoing → Completed → Archived). No state mutations occur from this tab.

### Validation Rules & Edge Cases

- **Empty state:** All cards show zero, charts render empty with "Create your first quest to see dashboard data."
- **Large dataset:** For schools with 10,000+ quests, summary cards may load sequentially to avoid long-running queries. The recent quests list is capped at 10.
- **Time zone:** All date-based aggregations (monthly activity chart) use the school's configured time zone, not UTC.
- **Caching:** No server-side caching — every dashboard load hits the database. This is intentional for real-time accuracy.
- **Cross-session boundary:** Dashboard only shows data for the current active academic session. Archived sessions are excluded.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Global | `glb_academic_sessions` | `lms_quests.academic_session_id` | Academic session filtering |
| SchoolSetup | `sch_classes`, `sch_subjects` | `lms_quests.class_id`, `lms_quests.subject_id` | Class/subject metadata |
| User | `sys_users` | `lms_quests.created_by` | Who created the quest |
| QuestionBank | `qns_questions_bank` | `lms_quest_questions.question_id` | Question count aggregation |

**Events/Listeners:** None triggered from this tab.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View dashboard | Teacher, Admin | `tenant.lms.quest.dashboard.view` |
| View quests list | Teacher, Admin | `tenant.lms.quest.viewAny` |
| Export charts (browser) | Teacher, Admin | N/A (client-side) |

- Admin users see data across all classes in the school. Teachers see only their assigned classes.
- Students have no access to this tab.

---

## Database Columns & Behavior

### `lms_quests`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| uuid | BINARY(16) | No | No | — | Unique identifier for API/external references |
| academic_session_id | INT UNSIGNED | `glb_academic_sessions.id` ON DELETE CASCADE | No | — | Filters quests by academic year |
| class_id | INT UNSIGNED | `sch_classes.id` ON DELETE CASCADE | No | — | Target class — locked after first save |
| subject_id | INT UNSIGNED | `sch_subjects.id` ON DELETE CASCADE | No | — | Target subject — locked after first save |
| quest_type_id | INT UNSIGNED | `lms_assessment_types.id` ON DELETE CASCADE | No | — | Assessment type (Challenge, Enrichment, Practice, etc.) |
| quest_code | VARCHAR(50) | No | No | — | Auto-generated unique code (e.g. QUEST_9TH_SCI_L01_SUB08_EASY) |
| title | VARCHAR(255) | No | No | — | Quest name — editable anytime |
| description | TEXT | No | Yes | NULL | Optional longer description |
| instructions | TEXT | No | Yes | NULL | Student-facing instructions shown before attempt |
| status | VARCHAR(20) | No | No | 'DRAFT' | Lifecycle: DRAFT, PENDING, PUBLISHED, ONGOING, COMPLETED, CANCELLED, ARCHIVED |
| duration_minutes | INT UNSIGNED | No | Yes | NULL | Time limit in minutes. NULL = no limit |
| total_marks | DECIMAL(8,2) | No | No | 0.00 | Sum of all question marks. Auto-calculated if 0 |
| total_questions | INT UNSIGNED | No | No | 0 | Question count. Auto-calculated if 0 |
| passing_percentage | DECIMAL(5,2) | No | No | 33.00 | Threshold for pass/fail badge |
| allow_multiple_attempts | TINYINT(1) | No | No | 0 | If 1, students can attempt multiple times |
| max_attempts | TINYINT UNSIGNED | No | No | 1 | Max attempts when multiple_attempts = 1. 0 = unlimited |
| negative_marks | DECIMAL(4,2) | No | No | 0.00 | Per-wrong-answer deduction factor |
| is_randomized | TINYINT(1) | No | No | 0 | Randomize question order per student |
| question_marks_shown | TINYINT(1) | No | No | 0 | Show per-question marks during attempt |
| auto_publish_result | TINYINT(1) | No | No | 0 | Auto-publish results after due date |
| timer_enforced | TINYINT(1) | No | No | 1 | If 1, timer is visible and enforced |
| show_correct_answer | TINYINT(1) | No | No | 0 | Show correct answer after submission |
| show_explanation | TINYINT(1) | No | No | 0 | Show explanation after submission |
| difficulty_config_id | INT UNSIGNED | `lms_difficulty_distribution_configs.id` ON DELETE SET NULL | Yes | NULL | Difficulty distribution blueprint |
| ignore_difficulty_config | TINYINT(1) | No | No | 0 | If 1, difficulty config is bypassed |
| is_system_generated | TINYINT(1) | No | No | 0 | If 1, quest was auto-created by system rules |
| only_unused_questions | TINYINT(1) | No | No | 0 | Only include questions not in usage log |
| only_authorised_questions | TINYINT(1) | No | No | 0 | Only include questions with for_quiz = 1 |
| created_by | INT UNSIGNED | `sys_users.id` ON DELETE SET NULL | Yes | NULL | Creator reference |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility flag |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification time |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete marker |

### `lms_quest_scopes`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| quest_id | INT UNSIGNED | `lms_quests.id` ON DELETE CASCADE | No | — | Parent quest |
| lesson_id | INT UNSIGNED | `slb_lessons.id` ON DELETE CASCADE | No | — | Lesson reference |
| topic_id | INT UNSIGNED | `slb_topics.id` ON DELETE CASCADE | No | — | Topic reference |
| question_type_id | INT UNSIGNED | `qns_question_types.id` ON DELETE SET NULL | Yes | NULL | Filter by question type |
| target_question_count | INT UNSIGNED | No | Yes | 0 | Desired question count per scope. 0 = all |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility toggle |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification time |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete marker |

### `lms_quest_questions`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| quest_id | INT UNSIGNED | `lms_quests.id` ON DELETE CASCADE | No | — | Parent quest |
| question_id | INT UNSIGNED | `qns_questions_bank.id` ON DELETE CASCADE | No | — | Question from Question Bank |
| ordinal | INT UNSIGNED | No | No | 0 | Display order within the quest |
| marks_override | DECIMAL(5,2) | No | Yes | NULL | Per-question marks override. NULL = use question bank value |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility flag |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification time |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete marker |

### `lms_quest_allocations`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| quest_id | INT UNSIGNED | `lms_quests.id` ON DELETE CASCADE | No | — | Parent quest |
| allocation_type | ENUM | No | No | — | CLASS, SECTION, GROUP, or STUDENT |
| target_table_name | VARCHAR(60) | No | No | — | Polymorphic target table name |
| target_id | INT UNSIGNED | No | No | — | Polymorphic target record ID |
| assigned_by | INT UNSIGNED | `sys_users.id` ON DELETE SET NULL | Yes | NULL | Who assigned. NULL = system-assigned |
| published_at | DATETIME | No | Yes | NULL | When allocation became visible to student |
| due_date | DATETIME | No | Yes | NULL | Deadline for the quest attempt |
| cut_off_date | DATETIME | No | Yes | NULL | Hard cut-off — no submissions after |
| is_auto_publish_result | TINYINT(1) | No | No | 0 | Auto-publish after due date |
| result_publish_date | DATETIME | No | Yes | NULL | When results were published |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility flag |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification time |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete marker |
