# Quiz Tab 6: Quiz Allocation

This tab is where teachers decide which students get to take a quiz. Without an allocation, no student can see or access a quiz, even if it is published. Allocations are what connect a quiz to the students who should take it.

---

## How It Works

The teacher chooses who gets the quiz. They can target a whole class — all students in "10th Science," for example. They can target a specific section within a class, like "Section A" only. They can target a student group, like the "Remedial Science Group." Or they can target an individual student — useful for make-up tests or special accommodations.

Each allocation can have its own schedule. By default, it follows the quiz's main schedule. But the teacher can give a specific group a different time window. For example, Section A takes the quiz on Monday, and Section B takes it on Tuesday. Or a student who was absent gets an "Open Range" allocation — they can take the quiz at any time with no deadline.

A quiz can have multiple allocations. Section A on Monday, Section B on Tuesday, a make-up allocation for one student with open range — all for the same quiz. If a student happens to be in multiple allocations (they are in Section A and also have an individual make-up), the system shows the quiz once and gives them the most permissive schedule.

---

## Important Business Rules

- The teacher can edit an allocation's schedule at any time, as long as no student in that allocation has started the quiz. Once a student starts, the target cannot be changed and the allocation cannot be deleted. The schedule can still be adjusted, but only for future access — students who are currently taking the quiz are unaffected.
- If the teacher needs to add a student mid-way — for example, a new student joins the class after the quiz was allocated — they create a new allocation for that student. The quiz does not automatically pick up new students from the class.
- If the teacher removes a student from an allocation while they are actively taking the quiz, the student's ongoing attempt is cancelled. They lose their progress and cannot resume. If the student has already submitted, their result is preserved.
- When a student logs in and looks at their quizzes, they see only the quizzes that have active allocations for them, that are within the schedule window, and that have the Published status. All three conditions must be met. If any one is missing, the quiz does not appear.
- A quiz can have multiple allocations with overlapping or different schedules. Each allocation operates independently.
- The "Open Range" schedule option means the student can take the quiz at any time indefinitely. Use this carefully as it bypasses all schedule restrictions.
- Deleting an allocation removes the quiz from all students in that allocation. If those students are also in another allocation for the same quiz, they retain access through the other allocation.
- Allocation history is preserved even after the allocation is deleted. The activity log records when allocations were created, modified, and deleted.

---

## Deep Analysis

### Business Workflows & State Machines

**Allocation Lifecycle State Machine:**

| Current State | Transition | Trigger | Next State | Conditions |
|---|---|---|---|---|
| Active | Create Allocation | Teacher selects target (class/section/group/student) | Active | Quiz must exist and be in Draft/Pending/Published |
| Active | Edit Schedule | Teacher changes dates | Active | Allowed unless any student in this allocation has started |
| Active | Add to Existing | Teacher adds another allocation | Active (Multiple) | Same quiz can have many allocations |
| Active | Student Starts | First student in allocation begins | Locked (Attempt Started) | Target and deletion become restricted |
| Locked (Attempt Started) | Edit Schedule | Teacher changes future dates | Locked | Schedule editable for future; current attempts unaffected |
| Locked (Attempt Started) | Delete Allocation | Teacher deletes | — | **Blocked** if any student has started |
| Active (No Attempts) | Delete Allocation | Teacher deletes | Deleted | Removes quiz access for all students in this allocation |
| Active | Remove Single Student | Teacher removes student | Active | If student is mid-attempt, their attempt is cancelled |
| Deleted | — | — | Deleted | History preserved in activity log |

**Student Quiz Visibility Decision Flow:**
1. Student logs in and views "My Quizzes."
2. System queries `lms_quiz_allocations` for allocations targeting this student (by class, section, group, or direct).
3. For each allocation, system checks:
   - `lms_quizzes.status = 'PUBLISHED'`
   - Current time within allocation's schedule window (`published_at` to `cut_off_date`)
   - Allocation is active (`is_active = 1`)
4. If all three conditions met, quiz appears.
5. If student is in multiple allocations, most permissive schedule is used.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Create Allocation – Quiz State | Quiz must exist and be active | "Quiz not found or has been deleted." |
| Create Allocation – Target | Target must be valid (class/section/group/student) | "Invalid allocation target." |
| Edit Schedule – During Attempt | Schedule can still be edited for future | Warning: "Students currently taking the quiz are unaffected by this change." |
| Delete Allocation – Active Attempts | Cannot delete if any student started | "Cannot delete allocation while students are taking the quiz." |
| Remove Student – Mid-Attempt | Student's attempt is cancelled | "Student's ongoing attempt has been cancelled." |
| Remove Student – Already Submitted | Result preserved | "Student's submission is preserved." |
| Open Range – No Dates Set | Student can take quiz anytime | No error — intentional design |
| Overlapping Allocations | Same student in multiple allocations | Most permissive schedule applied automatically |
| New Student Added to Class | Not auto-allocated | Teacher must create allocation manually |
| Allocation – Empty Target | No students match target | Warning: "No students found for this target." |
| Quiz Not Published Yet | Allocation exists but invisible to students | Quiz becomes visible when published |
| Schedule – End Before Start | `cut_off_date` must be after `published_at` | "Cut-off date must be after the published date." |
| Allocation – Double Allocation | Same target added twice | "This allocation already exists." (duplicate check) |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | `id` → `lms_quiz_allocations.quiz_id` | Parent quiz for allocations |
| Quiz Allocations | `lms_quiz_allocations` | — | Stores all allocation records |
| Classes | `sch_classes` | Application-level FK via `target_table_name` + `target_id` | Target: entire class |
| Sections | `sch_sections` | Application-level FK via `target_table_name` + `target_id` | Target: specific section |
| Groups | `sch_entity_groups` | Application-level FK via `target_table_name` + `target_id` | Target: student group |
| Students | `std_students` | Application-level FK via `target_table_name` + `target_id` | Target: individual student |
| Users | `sys_users` | `assigned_by` → `sys_users.id` | Tracks who created the allocation |
| Activity Log | (separate log table) | — | Records all allocation CRUD events |
| Student Portal | (student-facing views) | — | Reads allocations to determine quiz visibility |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Allocations | Teacher | `quiz.allocation.view` |
| Create Allocation | Teacher | `quiz.allocation.create` |
| Edit Allocation Schedule | Teacher | `quiz.allocation.edit-schedule` |
| Delete Allocation | Teacher | `quiz.allocation.delete` |
| Remove Single Student | Teacher | `quiz.allocation.remove-student` |
| Create Open Range Allocation | Teacher | `quiz.allocation.open-range` |
| View All Allocations | Admin | `quiz.allocation.view.all` |

---

## Database Columns & Behavior

### Table: `lms_quiz_allocations`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `quiz_id` | INT UNSIGNED | Yes → `lms_quizzes.id` | No | — | FK to the quiz |
| `allocation_type` | ENUM('CLASS','SECTION','GROUP','STUDENT') | No | No | — | Type of target entity |
| `target_table_name` | VARCHAR(60) | No | No | — | Name of target table (e.g. sch_classes) |
| `target_id` | INT UNSIGNED | No | No | — | ID of target entity (FK enforced at app level) |
| `assigned_by` | INT UNSIGNED | Yes → `sys_users.id` | Yes | NULL | Teacher/admin who assigned |
| `published_at` | DATETIME | No | Yes | NULL | Visible from date/time |
| `due_date` | DATETIME | No | Yes | NULL | Due by date/time |
| `cut_off_date` | DATETIME | No | Yes | NULL | No submissions after this |
| `is_auto_publish_result` | TINYINT(1) | No | No | 0 | Overrides quiz-level auto_publish_result |
| `result_publish_date` | DATETIME | No | Yes | NULL | Results visible from date |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |

### Table: `lms_quizzes` (relevant columns only)

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key, referenced by allocations |
| `status` | VARCHAR(20) | No | No | 'DRAFT' | Must be PUBLISHED for students to see allocated quizzes |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
