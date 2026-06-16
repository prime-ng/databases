# Homework Tab 10: Bulk Operations, Scheduling & Notifications

This tab covers the automated processes that run in the background — scheduled jobs, bulk operations, notification triggers, and the release condition engine. These features ensure homework operates smoothly without requiring manual intervention for every step.

---

## Section 1: Scheduled Jobs

Two scheduled console commands run automatically via the Laravel scheduler.

**Release Scheduled Homework:** The `tenant:homework:release-scheduled` command runs periodically and checks for homework assignments that have release_condition = ON_SCHEDULED_DATE and whose release_scheduled_date has arrived. When found, it sets is_released = 1, released_at = NOW(), and status = ASSIGNED. It also sends notifications to students and parents.

**Mark Overdue Assignments:** The `tenant:homework:update-status` command runs nightly and checks for assignments where the effective due date has passed, is_released = 1, and the status is not one of SUBMITTED, LATE_SUBMITTED, GRADED, or EXEMPTED. These assignments are marked as OVERDUE.

---

## Section 2: Syllabus Integration (ON_TOPIC_COMPLETE)

When a homework has release_condition = ON_TOPIC_COMPLETE, it is linked to a specific syllabus schedule entry. The system watches this entry via an observer (SyllabusScheduleObserver). When the teacher marks the syllabus topic as completed, the observer fires and automatically releases all matching homework assignments.

This creates a seamless workflow for teachers. They plan the lesson schedule at the start of the term. They create homework linked to specific topics. When they teach a topic in class and mark it as complete in the syllabus planner, the corresponding homework is automatically released to students. No manual publish step is needed — the system handles it.

---

## Section 3: Notifications

The system sends notifications for several events:

**New Homework Assigned:** When a homework is published with release_condition = IMMEDIATE, or when a scheduled/conditional homework is released, a notification is sent to the student. The parent is also notified if configured.

**Due Date Changed:** When the teacher changes the due date for a student (via the Assignment Tracking tab), a notification is sent to the student with the new due date.

**Homework Graded:** When the teacher grades a submission, a notification is sent to the student with the marks obtained.

**Reminder:** The teacher can manually send a reminder to a student who has not yet submitted. This creates a notification record.

**Late Submission Extended:** When the teacher grants a late submission override, a notification is sent to the parent.

---

## Section 4: Bulk Assignment Creation

When a homework is published, the system creates assignment records for every active student in the selected class and section. This happens in a database transaction with row-level locking to prevent duplicates.

The process:
1. Resolves all active students in the class (and section if specified).
2. For each student, creates an assignment record using firstOrNew (to handle re-publishing).
3. Sets the release condition — IMMEDIATE assignments get is_released = 1, others get is_released = 0.
4. Sets the initial status — ASSIGNED for immediate, PENDING_RELEASE for conditional/scheduled.
5. Updates the homework status to PUBLISHED.

If any part of the transaction fails, everything is rolled back.

---

## Section 5: Bulk Download

The teacher can download all submission files for a homework as a single ZIP file. The system collects files from all submissions, organizes them by student name, and packages them into a downloadable archive. The ZIP file is created temporarily and deleted after download.

---

## Important Business Rules

- The release scheduled command runs every minute but only processes assignments whose release_scheduled_date has passed.
- The overdue marking command runs once daily (typically at midnight) to avoid unnecessary server load.
- The SyllabusScheduleObserver fires only when a syllabus schedule entry's status is changed to "Completed." It does not fire on initial creation or other status changes.
- Bulk assignment creation uses row-level locking (lockForUpdate) to prevent race conditions.
- If a homework is re-published (status changed back to PUBLISHED from DRAFT), existing assignments are restored from soft-delete rather than recreated.
- Notifications are created in the notifications table. Delivery (email, SMS, in-app) depends on the school's notification configuration.
- Notification targets (student user, parent users) are resolved at the time of notification creation.
- The bulk download ZIP is generated on demand and deleted immediately after download. It is not stored permanently.
- The system tracks when each notification was sent (student_notified_at, parent_notified_at, reminder_sent_at) to avoid duplicate notifications.
- If a student does not have a user account linked, notifications cannot be sent. The system logs a warning but does not block the operation.

---

## Database Columns & Behavior

### lms_homework_assignment (used by scheduled jobs)
- `id` — For updating individual records. INT UNSIGNED.
- `homework_id` — For joining to homework. INT UNSIGNED.
- `is_released` — Checked by release job. Set to 1 on release. TINYINT(1).
- `released_at` — Set to NOW() on release. DATETIME.
- `status_id` — Checked by overdue job. Updated on status changes. INT UNSIGNED.
- `due_date` — Per-student override for effective due date. DATETIME.
- `release_condition` — Checked by release job. ENUM.
- `release_scheduled_date` — Checked by release job. DATETIME.
- `student_notified_at` — Updated when notification sent. DATETIME.
- `parent_notified_at` — Updated when notification sent. DATETIME.
- `reminder_sent_at` — Updated when reminder sent. DATETIME.

### lms_homework (used by scheduled jobs)
- `id` — For joining. INT UNSIGNED.
- `due_date` — Default due date. Used when assignment has no override. DATETIME.
- `release_condition` — ENUM. Controls release behavior.
- `release_scheduled_date` — For scheduled release. DATETIME.
- `schedule_id` — Links to syllabus schedule for ON_TOPIC_COMPLETE. INT UNSIGNED.
- `status_id` — Must be PUBLISHED for assignments to be created or processed. INT UNSIGNED.
- `allow_late_submission` — Default policy. TINYINT(1).

### lms_homework_submissions (used by bulk download)
- `id` — For loading submissions. INT UNSIGNED.
- `homework_id` — Filters by homework. INT UNSIGNED.
- `sub_attachment_media_id` — JSON with file paths for ZIP. JSON.
- `student_id` — For naming files by student. INT UNSIGNED.

### Notifications Tables (used for notification creation)
- `notifications` — Stores the notification record. Fields: id, source_module, notification_event, title, description, created_by, is_active, created_at.
- `notification_targets` — Maps notifications to target users. Fields: id, notification_id, target_table_name, target_selected_id, is_active.

---

## Deep Analysis

### Business Workflows & State Machines

This tab orchestrates background state machines that drive automated transitions:

**Release Scheduler (runs every minute):**
| Condition | Check | Transition |
|---|---|---|
| `release_condition = ON_SCHEDULED_DATE` AND `release_scheduled_date ≤ NOW()` AND `is_released = 0` | Cron poll | `is_released = 1`, `released_at = NOW()`, `status = ASSIGNED`. Notifications sent. |

**Overdue Marker (runs nightly):**
| Condition | Check | Transition |
|---|---|---|
| `is_released = 1` AND `effective_due_date < NOW()` AND `status NOT IN (SUBMITTED, LATE_SUBMITTED, GRADED, EXEMPTED)` | Cron poll | `status = OVERDUE` |

**Syllabus Observer (event-driven):**
| Trigger | Condition | Transition |
|---|---|---|
| Syllabus schedule marked "Completed" | `lms_homework.release_condition = ON_TOPIC_COMPLETE` AND `lms_homework.schedule_id` matches completed entry | `is_released = 1`, `released_at = NOW()`, `status = ASSIGNED` for all matching assignments. |

**Bulk Assignment Creation (synchronous on publish):**
| Step | Operation | Locking |
|---|---|---|
| Resolve active students | Query `std_students` by class+section+session | — |
| Create/restore assignments | `firstOrNew` for each student | `lockForUpdate` on transaction |
| Set release flags | IMMEDIATE → `is_released=1, status=ASSIGNED`; others → `is_released=0, status=PENDING_RELEASE` | — |
| Update homework status | `status = PUBLISHED` | — |
| Rollback on failure | Entire transaction reversed | Auto-rollback |

**Notification Events:**
| Event | Trigger | Targets | Channel |
|---|---|---|---|
| New homework assigned | Publish (IMMEDIATE) / Release trigger | Student + Parent | In-app / Email / SMS |
| Due date changed | Teacher edits assignment due_date | Student | In-app / Email / SMS |
| Homework graded | Teacher finalizes grade | Student (if auto_publish) or on manual publish | In-app |
| Reminder | Teacher sends reminder | Student | In-app |
| Late submission override | Teacher grants override | Parent | In-app |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Release scheduler — cron freq | Runs every 1 minute; processes only records where `release_scheduled_date ≤ NOW()` | N/A — cron internal |
| Release scheduler — notification | `student_notified_at` and `parent_notified_at` updated to prevent re-notification | N/A — deduplication |
| Overdue cron — cron freq | Runs once daily (midnight); doesn't process submitted/graded/exempted | N/A — cron internal |
| Overdue cron — effective date | Uses `COALESCE(assignment.due_date, homework.due_date)` | N/A — computed |
| Syllabus observer — trigger only | Fires only on status change to "Completed"; not on create or other status changes | N/A — observer scope |
| Bulk create — row locking | Uses `lockForUpdate` to prevent duplicate assignments | N/A — database-level |
| Bulk create — re-publish | Existing soft-deleted assignments restored, not recreated | N/A — firstOrNew logic |
| Bulk download ZIP | Generated on demand, deleted after download; not stored permanently | N/A — temporary file |
| Notification — no user account | System logs warning but does not block the operation | Log: "No user account found for student {id}" |
| Notification — delivery config | Depends on school's notification configuration; some channels may be disabled | N/A — configurable |
| ON_TOPIC_COMPLETE — multiple homeworks | One syllabus schedule entry may trigger multiple homeworks | N/A — batch update |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Syllabus Planner | `slb_syllabus_schedule` | `lms_homework.schedule_id` | Topic completion observer triggers homework release |
| Student Management | `std_students` | (enrollment query) | Resolves active students for bulk assignment creation |
| Assignment Tracking | `lms_homework_assignment` | `homework_id` | Target of all scheduled jobs and release triggers |
| Submission Management | `lms_homework_submissions` | `homework_id`, `student_id` | File collection for bulk download ZIP |
| Notifications | `notifications`, `notification_targets` | (event-based) | Notification creation for all triggered events |
| Users | `sys_users` | (resolved via student) | Notification delivery targets |
| School Management | `sch_classes`, `sch_sections` | (enrollment query) | Student resolution scope |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Trigger bulk assignment publish | Teacher | `lms.homework.publish` |
| Bulk download submission files | Teacher | `lms.homework.submission.bulk_download` |
| View scheduled job logs | Admin | `lms.homework.scheduler.logs.view` |
| Manually trigger release job | Admin | `lms.homework.scheduler.release.trigger` |
| Manually trigger overdue job | Admin | `lms.homework.scheduler.overdue.trigger` |
