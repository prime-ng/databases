# Quest Tab 2: Quest Creation

This is the main tab where teachers create, view, and manage quests. Building a quest happens in stages — first setting up the structure and rules, then adding questions, then assigning students, and finally publishing.

---

## Section 1: Creating a New Quest

When the teacher clicks "Create New Quest," they are taken to a form where they set up everything about the quest.

**Basic Information:** The teacher gives the quest a title and picks an assessment type — Practice, Formative, Summative, etc. This choice determines some behaviors later (like whether failing students get remedial quests). The type cannot be changed after saving. The teacher picks a class and subject. These also become locked after saving — they determine which questions from the Question Bank will be available when the teacher reaches the question selection step.

**Duration and Attempt Settings:** The teacher sets how long students have to complete the quest, in minutes. If they enter 0, there is no time limit at all. They set passing marks — if left blank, the default is 33% of the total. They can enable negative marking, which deducts points for wrong answers based on each question's negative marks value.

The teacher decides whether to shuffle questions so each student sees them in a different order, and whether to shuffle the answer options within each question. They can choose whether students see results immediately after submitting, and whether the answer key is shown. They set how many attempts each student gets — 1 by default, up to 10, or 0 for unlimited.

Several toggle switches control additional features. The teacher can let students pause and resume the quest (the timer pauses too), provide an in-browser calculator or formula sheet, and enable basic proctoring that tracks when a student switches to another browser tab.

**Schedule:** The teacher sets when the quest is available. "Now" means it becomes available immediately after publishing. "Schedule" means it is available daily between two times — for example, 9 AM to 10 AM every day. "Date Range" means it is available only between specific dates and times — for example, March 20 at 9 AM to March 25 at 5 PM.

The teacher can also write instructions that students will see before starting the quest.

When they click Save, the quest is created in Draft status. They still need to add questions and assign students before it is ready.

---

## Section 2: How a Quest Lives Through Its States

A quest moves through several states during its life. Draft means the teacher is still building it. Pending means questions have been added but the quest is not yet published. Published means students can see it and take it (according to the schedule). Ongoing means students are actively taking it. Completed means the quest window has closed. Cancelled means the teacher took it down. Archived means it has been retired for record-keeping.

The teacher publishes the quest when it is ready. At that point, students who have been allocated can see it. Once a student starts the quest, most settings become locked. The teacher can no longer cancel the quest, change the assessment type, add or remove questions, or change the class or subject. They can still adjust the duration, passing marks, and some toggle settings.

If the teacher needs to make changes after publishing, they are limited by the quest's current state. During Ongoing, only duration and passing marks can be changed. During Completed, nothing can be changed at all.

---

## Section 3: Editing and Deleting

Editing is allowed freely while the quest is in Draft or Pending. Once published, the restrictions kick in. The class and subject are locked at creation — they cannot be changed later at all.

If the teacher deletes a quest, what happens depends on the state. A Draft quest can be deleted entirely. A quest with student attempts can only be soft-deleted — hidden but preserved for historical records. A quest that is currently being taken cannot be deleted at all.

When a quest is deleted, its question assignments and allocations are also removed. But student attempt data is preserved — those records exist independently and are not deleted.

---

## Important Business Rules

- The assessment type, class, and subject are locked once the quest is saved for the first time. They cannot be changed later under any circumstances.
- A quiz with zero duration means no time limit. The student can take as long as they need, but the quiz still records the total time spent.
- The passing marks default to 33% of the total quest marks if left blank. This default is calculated dynamically based on the questions added later.
- If negative marking is enabled, each wrong answer deducts the negative marks value set on that specific question. Unanswered questions are not penalized — they simply get zero.
- The quest title can be changed at any time, even after publishing. Only the core settings (type, class, subject) are locked.
- Publishing requires at least one question to be added and at least one student to be allocated. If either is missing, the publish action is blocked with a clear error message.
- Soft-deleted quests are hidden from the main list but still exist in the system. They can be restored by an administrator if needed.
- The schedule uses the school's configured timezone. Daylight saving changes are handled automatically by the system.
- Once a student has started the quest, the teacher can only modify the duration and passing marks. No changes to questions, scope types, or allocations are allowed.

---

## Deep Analysis

### Business Workflows & State Machines

**Quest Lifecycle States:**
```
DRAFT ──→ PENDING ──→ PUBLISHED ──→ ONGOING ──→ COMPLETED ──→ ARCHIVED
  │                    │               │                       │
  └──→ CANCELLED ←─────┘               └──→ CANCELLED ←────────┘
```

| Transition | Trigger | Conditions |
|-----------|---------|-----------|
| DRAFT → PENDING | Save with questions added | At least 1 question, 1 scope type defined |
| PENDING → PUBLISHED | Teacher clicks Publish | At least 1 allocation, at least 1 question |
| PUBLISHED → ONGOING | First student starts attempt | Automatic |
| ONGOING → COMPLETED | Due date passes or all students submit | Automatic or manual |
| COMPLETED → ARCHIVED | Teacher clicks Archive | All results published |
| Any → CANCELLED | Teacher cancels | No student attempts in progress |

**Locking Rules:**
- Status DRAFT/PENDING: Everything editable
- Status PUBLISHED: Class, subject, assessment type locked. Questions locked if students started
- Status ONGOING: Only duration and passing marks editable
- Status COMPLETED/ARCHIVED: Nothing editable

### Validation Rules & Edge Cases

| Field | Rule | Error Message |
|-------|------|---------------|
| `title` | Required, max 255 chars, unique per class+subject+session | "Quest title is required" |
| `quest_type_id` | Required, must be a valid type from `lms_assessment_types`, locked after save | "Assessment type cannot be changed after saving" |
| `class_id` | Required, must match one of teacher's assigned classes | "You must select a class" |
| `subject_id` | Required, must belong to selected class | "Invalid subject for selected class" |
| `duration_minutes` | Integer ≥ 0. 0 = no limit | "Duration must be 0 or more minutes" |
| `passing_percentage` | Decimal 0-100, default 33.00 | "Passing percentage must be between 0 and 100" |
| `max_attempts` | Integer 1-10, or 0 for unlimited (only when `allow_multiple_attempts` = 1) | "Max attempts must be 1-10 or 0 for unlimited" |
| Publish action | Requires ≥ 1 question and ≥ 1 allocation | "Add at least one question and allocate at least one student before publishing" |

**Edge Cases:**
- Deleting a quest with in-progress attempts: Blocked with "Cannot delete quest while students are taking it"
- Setting `total_marks` = 0: Auto-calculated from sum of question marks
- Setting `duration_minutes` = 0 after publishing: Removes time limit. Existing in-progress attempts honour the new setting
- Schedule conflicts: If a quest is scheduled but due date is in the past, publish is blocked with "Schedule dates must be in the future"

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Global | `glb_academic_sessions` | `academic_session_id` | Session scoping |
| SchoolSetup | `sch_classes`, `sch_subjects` | `class_id`, `subject_id` | Class/subject selection |
| Syllabus | `slb_lessons`, `slb_topics` | (implied in scopes) | Curriculum linkage |
| QuestionBank | `qns_questions_bank`, `qns_question_types` | `question_id` via junction | Question sourcing |
| LMS Shared | `lms_assessment_types`, `lms_difficulty_distribution_configs` | `quest_type_id`, `difficulty_config_id` | Assessment type & difficulty configuration |

**Events that should exist (potential additions):**
- `QuestPublished` — triggered when a quest moves to PUBLISHED. Could trigger notifications to allocated students.
- `QuestCompleted` — triggered when all students have submitted or due date passes.
- `QuestCancelled` — triggered when teacher cancels a quest. Should notify all allocated students.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View quest list | Teacher, Admin | `tenant.lms.quest.viewAny` |
| View quest details | Teacher, Admin | `tenant.lms.quest.view` |
| Create quest | Teacher, Admin | `tenant.lms.quest.create` |
| Edit own quest (Draft/Pending) | Teacher | `tenant.lms.quest.update` |
| Edit any quest | Admin, HOD | `tenant.lms.quest.updateAny` |
| Delete draft quest | Teacher (own), Admin | `tenant.lms.quest.delete` |
| Publish quest | Teacher, Admin | `tenant.lms.quest.publish` |
| Cancel quest | Teacher (own), Admin | `tenant.lms.quest.cancel` |
| Archive quest | Admin only | `tenant.lms.quest.archive` |

- Teachers can only edit/delete quests they created. Admins can edit any quest.
- Publishing requires the `publish` permission, which may be restricted to senior teachers or HODs.
