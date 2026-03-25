-- ==============================================================================================================
-- LMS - Sub-Module 2: HOMEWORK & ASSIGNMENTS
-- Version  : v3
-- Date     : 2026-03-25
-- Author   : Claude Code (Architect)
-- ==============================================================================================================
-- CHANGES FROM v2:
-- ---------------------------------------------------------------------------------------------------------------
--   [FIX-1]   lms_homework     → Removed dangling FK `fk_hw_sub_topic` — column `sub_topic_id` was never defined
--   [FIX-2]   lms_homework     → Added FK constraint for `academic_session_id` (was missing in v2)
--   [FIX-3]   lms_homework     → Removed invalid seed INSERT (referenced non-existent column `sub_topic_id`)
--   [ADD-1]   lms_homework     → Added `schedule_id` (links to slb_syllabus_schedule for ON_TOPIC_COMPLETE trigger)
--   [ADD-2]   lms_homework     → Added `release_scheduled_date` DATETIME for ON_SCHEDULED_DATE condition
--   [ADD-3]   lms_homework     → Added INDEX on `academic_session_id`
-- ---------------------------------------------------------------------------------------------------------------
--   [NEW]     lms_homework_assignment → NEW TABLE — one record per student per homework
--             • Created in bulk when homework is published (one row per student in Class+Section+Subject)
--             • Per-student `due_date` override (emergency extension)
--             • Per-student `allow_late_submission` override (NULL = inherit from lms_homework)
--             • Release tracking: `is_released`, `released_at`
--             • View tracking: `viewed_at`, `view_count`
--             • Notification history: student_notified_at, parent_notified_at, reminder_sent_at
--             • Status lifecycle: PENDING_RELEASE → ASSIGNED → VIEWED → SUBMITTED → GRADED / OVERDUE / EXEMPTED
-- ---------------------------------------------------------------------------------------------------------------
--   [FIX-4]   lms_homework_submissions → Corrected `student_id` FK target to std_students (was wrongly noted as sys_users)
--   [ADD-4]   lms_homework_submissions → Added `assignment_id` FK → lms_homework_assignment.id
--   [ADD-5]   lms_homework_submissions → Added `attachments_json` for multiple file uploads (replaces single FK)
--   [ADD-6]   lms_homework_submissions → Added `is_active`, `created_by`, `updated_by`
--   [ADD-7]   lms_homework_submissions → Added `resubmission_count` to track re-attempts
--   [ADD-8]   lms_homework_submissions → Added `score_published_at` (for auto_publish_score feature)
--   [CHG-1]   lms_homework_submissions → UNIQUE changed from (homework_id, student_id) → (assignment_id)
-- ==============================================================================================================

-- ==============================================================================================================
-- TABLE 1: lms_homework
-- Purpose  : Homework definition/template created by the teacher.
--            One record = one homework task for a class-section-subject.
--            When published, bulk-creates lms_homework_assignment records for all students.
-- ==============================================================================================================
CREATE TABLE IF NOT EXISTS `lms_homework` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Academic Context
    `academic_session_id` INT UNSIGNED NOT NULL,       -- FK to sch_org_academic_sessions_jnt.id
    `class_id`            INT UNSIGNED NOT NULL,       -- FK to sch_classes.id
    `section_id`          INT UNSIGNED DEFAULT NULL,   -- FK to sch_sections.id (NULL = applies to all sections)
    `subject_id`          INT UNSIGNED NOT NULL,       -- FK to sch_subjects.id
    -- Content Alignment (Syllabus linkage)
    `lesson_id`           INT UNSIGNED DEFAULT NULL,   -- FK to slb_lessons.id (NULL = not linked to a specific lesson)
    `topic_id`            INT UNSIGNED DEFAULT NULL,   -- FK to slb_topics.id  (Topic / Sub-Topic / Mini-Topic / Micro-Topic)
    `schedule_id`         INT UNSIGNED DEFAULT NULL,   -- FK to slb_syllabus_schedule.id
                                                       -- Used when release_condition = ON_TOPIC_COMPLETE:
                                                       -- system watches this schedule entry; when teacher marks
                                                       -- the topic as completed, homework is auto-released.
    -- Homework Details
    `title`               VARCHAR(255) NOT NULL,
    `description`         LONGTEXT NOT NULL,           -- Supports HTML / Markdown
    `submission_type_id`  INT UNSIGNED NOT NULL,       -- FK to sys_dropdown_table.id (TEXT | FILE | HYBRID | OFFLINE_CHECK)

    -- Grading Settings
    `is_gradable`         TINYINT(1) NOT NULL DEFAULT 1,    -- 1 = Gradable, 0 = Not Gradable
    `max_marks`           DECIMAL(5,2) DEFAULT NULL,        -- NULL if not gradable
    `passing_marks`       DECIMAL(5,2) DEFAULT NULL,        -- NULL if not gradable
    `difficulty_level_id` INT UNSIGNED DEFAULT NULL,        -- FK to slb_complexity_level.id (EASY | MEDIUM | HARD)
    `auto_publish_score`  TINYINT(1) NOT NULL DEFAULT 0,    -- 1 = Score published to student immediately on grading

    -- Default Scheduling (can be overridden per-student in lms_homework_assignment)
    `assign_date`              DATETIME NOT NULL,            -- Date/time homework becomes active (for IMMEDIATE release)
    `due_date`                 DATETIME NOT NULL,            -- Default due date for all students
    `allow_late_submission`    TINYINT(1) NOT NULL DEFAULT 0, -- Default late-submission policy (0 = deny, 1 = allow)
                                                             -- Can be overridden per-student in lms_homework_assignment

    -- Auto-Release Logic
    -- IMMEDIATE        → Released to students right when homework is published
    -- ON_TOPIC_COMPLETE → Released when teacher marks schedule_id topic as completed
    -- ON_SCHEDULED_DATE → Released on release_scheduled_date (batch job / scheduler)
    `release_condition_id`     INT UNSIGNED DEFAULT NULL,    -- FK to sys_dropdown_table.id
    `release_scheduled_date`   DATETIME DEFAULT NULL,        -- Populated when release_condition = ON_SCHEDULED_DATE

    -- Workflow Status
    `status_id`           INT UNSIGNED NOT NULL,       -- FK to sys_dropdown_table.id (DRAFT | PUBLISHED | ARCHIVED)

    -- Audit
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`          INT UNSIGNED NOT NULL,       -- FK to sys_users.id (teacher)
    `updated_by`          INT UNSIGNED DEFAULT NULL,   -- FK to sys_users.id
    `created_at`          TIMESTAMP NULL DEFAULT NULL,
    `updated_at`          TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`          TIMESTAMP NULL DEFAULT NULL,

    PRIMARY KEY (`id`),
    INDEX `idx_hw_session`      (`academic_session_id`),
    INDEX `idx_hw_class_sub`    (`class_id`, `subject_id`),
    INDEX `idx_hw_status`       (`status_id`),
    INDEX `idx_hw_assign_date`  (`assign_date`),
    INDEX `idx_hw_due_date`     (`due_date`),

    CONSTRAINT `fk_hw_session`         FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hw_class`           FOREIGN KEY (`class_id`)            REFERENCES `sch_classes`              (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hw_section`         FOREIGN KEY (`section_id`)          REFERENCES `sch_sections`             (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hw_subject`         FOREIGN KEY (`subject_id`)          REFERENCES `sch_subjects`             (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hw_lesson`          FOREIGN KEY (`lesson_id`)           REFERENCES `slb_lessons`              (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hw_topic`           FOREIGN KEY (`topic_id`)            REFERENCES `slb_topics`               (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hw_schedule`        FOREIGN KEY (`schedule_id`)         REFERENCES `slb_syllabus_schedule`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hw_submission_type` FOREIGN KEY (`submission_type_id`)  REFERENCES `sys_dropdown_table`       (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hw_difficulty`      FOREIGN KEY (`difficulty_level_id`) REFERENCES `slb_complexity_level`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hw_release_cond`    FOREIGN KEY (`release_condition_id`) REFERENCES `sys_dropdown_table`      (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hw_status`          FOREIGN KEY (`status_id`)            REFERENCES `sys_dropdown_table`      (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hw_created_by`      FOREIGN KEY (`created_by`)           REFERENCES `sys_users`               (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hw_updated_by`      FOREIGN KEY (`updated_by`)           REFERENCES `sys_users`               (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Conditions:
--   1. `release_scheduled_date` MUST be set if release_condition = ON_SCHEDULED_DATE (enforce at app level).
--   2. `schedule_id` MUST be set if release_condition = ON_TOPIC_COMPLETE (enforce at app level).
--   3. `max_marks` and `passing_marks` are required if is_gradable = 1 (enforce at app level).
--   4. `passing_marks` must be <= `max_marks` (enforce at app level + DB CHECK constraint if MySQL 8.0.16+).
--   5. When status changes DRAFT → PUBLISHED, app bulk-creates lms_homework_assignment rows
--      for all active students enrolled in class+section+subject for the academic_session.
--   6. `allow_late_submission` here is the DEFAULT for all students.
--      It can be overridden per-student in lms_homework_assignment.allow_late_submission.


-- ==============================================================================================================
-- TABLE 2: lms_homework_assignment  [NEW IN v3]
-- Purpose  : Represents ONE homework assignment for ONE student.
--            Created in bulk when a homework is published.
--            Tracks the full lifecycle from release → view → submit → grade.
--            Supports per-student overrides for due_date and allow_late_submission.
-- ==============================================================================================================
CREATE TABLE IF NOT EXISTS `lms_homework_assignment` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Core Links
    `homework_id`          INT UNSIGNED NOT NULL,      -- FK to lms_homework.id
    `student_id`           INT UNSIGNED NOT NULL,      -- FK to std_students.id
    -- Denormalized for performance (avoids joining lms_homework for every query)
    `academic_session_id`  INT UNSIGNED NOT NULL,      -- Copied from lms_homework.academic_session_id
    `class_id`             INT UNSIGNED NOT NULL,      -- Copied from lms_homework.class_id
    `section_id`           INT UNSIGNED DEFAULT NULL,  -- Actual section of the student (not from homework)
    `subject_id`           INT UNSIGNED NOT NULL,      -- Copied from lms_homework.subject_id
    -- Release Control (per-student; NULL = inherit from lms_homework)
    `release_condition_id`    INT UNSIGNED DEFAULT NULL,   -- FK to sys_dropdown_table.id (NULL = inherit from homework)
    `release_scheduled_date`  DATETIME DEFAULT NULL,       -- Overrideable scheduled release date per student
    `is_released`             TINYINT(1) NOT NULL DEFAULT 0, -- 0 = Not yet visible to student, 1 = Visible
    `released_at`             DATETIME DEFAULT NULL,       -- Actual timestamp when released
    -- Due Date (per-student override; NULL = inherit from lms_homework.due_date)
    `due_date`             DATETIME DEFAULT NULL,          -- NULL = use homework.due_date
    -- Late Submission Override (per-student)
    -- NULL = inherit from lms_homework.allow_late_submission
    -- 0    = explicitly DENY late submission for this student (even if homework default is allow)
    -- 1    = explicitly ALLOW late submission for this student (emergency override by teacher)
    `allow_late_submission`         TINYINT(1) DEFAULT NULL,
    `late_submission_override_reason` VARCHAR(500) DEFAULT NULL,  -- Teacher's reason for the override
    `late_submission_override_by`   INT UNSIGNED DEFAULT NULL,    -- FK to sys_users.id (teacher who overrode)
    `late_submission_override_at`   DATETIME DEFAULT NULL,
    -- Student Activity Tracking
    `viewed_at`            DATETIME DEFAULT NULL,      -- Timestamp when student first opened/viewed the homework
    `view_count`           SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- How many times student viewed
    -- Notification History
    `student_notified_at`  DATETIME DEFAULT NULL,      -- When the "new homework" push/email was sent to student
    `parent_notified_at`   DATETIME DEFAULT NULL,      -- When the "new homework" notification was sent to parent
    `reminder_sent_at`     DATETIME DEFAULT NULL,      -- When the last due-date reminder was sent
    -- Lifecycle Status
    -- PENDING_RELEASE  → Assignment created but not yet released to student (waiting for trigger)
    -- ASSIGNED         → Released and visible to student (not yet viewed)
    -- VIEWED           → Student has opened/read the homework
    -- SUBMITTED        → Student submitted on time
    -- LATE_SUBMITTED   → Student submitted after due_date (allowed via late submission policy)
    -- GRADED           → Teacher has evaluated and graded the submission
    -- OVERDUE          → Past due_date, not submitted (set by scheduled job)
    -- EXEMPTED         → Student exempted from this homework (e.g. was absent on topic day)
    `status_id`            INT UNSIGNED NOT NULL,      -- FK to sys_dropdown_table.id
    -- Audit
    `assigned_by`          INT UNSIGNED NOT NULL,      -- FK to sys_users.id (teacher who published/bulk-assigned)
    `is_active`            TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`           INT UNSIGNED NOT NULL,      -- FK to sys_users.id
    `updated_by`           INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id
    `created_at`           TIMESTAMP NULL DEFAULT NULL,
    `updated_at`           TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`           TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_hwa_homework_student`    (`homework_id`, `student_id`),   -- one assignment per student per homework
    INDEX       `idx_hwa_student`            (`student_id`),
    INDEX       `idx_hwa_session_class`      (`academic_session_id`, `class_id`, `section_id`),
    INDEX       `idx_hwa_status`             (`status_id`),
    INDEX       `idx_hwa_is_released`        (`is_released`),
    INDEX       `idx_hwa_due_date`           (`due_date`),
    CONSTRAINT `fk_hwa_homework`         FOREIGN KEY (`homework_id`)             REFERENCES `lms_homework`                   (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hwa_student`          FOREIGN KEY (`student_id`)              REFERENCES `std_students`                   (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hwa_session`          FOREIGN KEY (`academic_session_id`)     REFERENCES `sch_org_academic_sessions_jnt`  (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hwa_class`            FOREIGN KEY (`class_id`)                REFERENCES `sch_classes`                    (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hwa_section`          FOREIGN KEY (`section_id`)              REFERENCES `sch_sections`                   (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hwa_subject`          FOREIGN KEY (`subject_id`)              REFERENCES `sch_subjects`                   (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hwa_release_cond`     FOREIGN KEY (`release_condition_id`)    REFERENCES `sys_dropdown_table`             (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hwa_status`           FOREIGN KEY (`status_id`)               REFERENCES `sys_dropdown_table`             (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hwa_late_override_by` FOREIGN KEY (`late_submission_override_by`) REFERENCES `sys_users`                 (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hwa_assigned_by`      FOREIGN KEY (`assigned_by`)             REFERENCES `sys_users`                      (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hwa_created_by`       FOREIGN KEY (`created_by`)              REFERENCES `sys_users`                      (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hwa_updated_by`       FOREIGN KEY (`updated_by`)              REFERENCES `sys_users`                      (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Conditions:
--   1. App creates one row per active enrolled student when homework status = PUBLISHED.
--   2. `due_date` is NULL by default — app resolves effective due date as:
--        COALESCE(assignment.due_date, homework.due_date)
--   3. `allow_late_submission` is NULL by default — app resolves effective policy as:
--        COALESCE(assignment.allow_late_submission, homework.allow_late_submission)
--   4. A scheduled job runs nightly to set status = OVERDUE for assignments where:
--        is_released=1 AND status NOT IN (SUBMITTED, LATE_SUBMITTED, GRADED, EXEMPTED)
--        AND COALESCE(assignment.due_date, homework.due_date) < NOW()
--   5. When teacher marks a slb_syllabus_schedule topic as completed and homework has
--        release_condition = ON_TOPIC_COMPLETE, app sets is_released=1, released_at=NOW()
--        and status = ASSIGNED for all matching PENDING_RELEASE assignment rows.
--   6. `section_id` here = student's actual section, NOT homework.section_id
--        (which can be NULL for "all sections").


-- ==============================================================================================================
-- TABLE 3: lms_homework_submissions
-- Purpose  : Stores the student's actual submission content (text, files, and evaluation).
--            Linked 1:1 to lms_homework_assignment.
--            When teacher rejects and asks to resubmit, the existing row is updated
--            (resubmission_count increments, previous content can be archived in attachments_json history).
-- ==============================================================================================================
CREATE TABLE IF NOT EXISTS `lms_homework_submissions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Core Links
    `assignment_id`        INT UNSIGNED NOT NULL,      -- FK to lms_homework_assignment.id (one submission per assignment)
    `homework_id`          INT UNSIGNED NOT NULL,      -- Denormalized from assignment for easy querying
    `student_id`           INT UNSIGNED NOT NULL,      -- FK to std_students.id (denormalized)
    -- Submission Content
    `submission_text`      LONGTEXT DEFAULT NULL,      -- Student's text response (for TEXT / HYBRID type)
    `attachments_json`     JSON DEFAULT NULL,          -- Array of sys_media IDs for uploaded files
                                                       -- e.g. [{"media_id": 12, "file_name": "hw1.pdf"}, ...]
                                                       -- Replaces single attachment_media_id from v2
    -- Submission Timing
    `submitted_at`         DATETIME NOT NULL,          -- When the student submitted
    `is_late`              TINYINT(1) NOT NULL DEFAULT 0, -- 1 = submitted after effective due_date
    -- Resubmission Tracking
    `resubmission_count`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
                                                       -- 0 = first submission, 1 = first resubmission, etc.
                                                       -- Incremented each time teacher rejects and student resubmits
    -- Evaluation (filled by teacher)
    `status_id`            INT UNSIGNED NOT NULL,      -- FK to sys_dropdown_table.id
                                                       -- (SUBMITTED | UNDER_REVIEW | GRADED | REJECTED | RESUBMIT_REQUESTED)
    `marks_obtained`       DECIMAL(5,2) DEFAULT NULL,  -- NULL until graded
    `teacher_feedback`     TEXT DEFAULT NULL,          -- Written feedback from teacher
    `graded_by`            INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id (teacher who graded)
    `graded_at`            DATETIME DEFAULT NULL,
    -- Score Publishing
    `score_published_at`   DATETIME DEFAULT NULL,      -- When score was made visible to student
                                                       -- Set by app when auto_publish_score=1 (on grading)
                                                       -- or manually when teacher clicks "Publish Score"
    -- Audit
    `is_active`            TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`           INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id (student's user_id)
    `updated_by`           INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id (teacher on grading)
    `created_at`           TIMESTAMP NULL DEFAULT NULL,
    `updated_at`           TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`           TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hws_assignment`        (`assignment_id`),          -- one active submission per assignment
    INDEX      `idx_hws_homework_student` (`homework_id`, `student_id`),
    INDEX      `idx_hws_status`           (`status_id`),
    INDEX      `idx_hws_submitted_at`     (`submitted_at`),
    CONSTRAINT `fk_hws_assignment`  FOREIGN KEY (`assignment_id`) REFERENCES `lms_homework_assignment` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hws_homework`    FOREIGN KEY (`homework_id`)   REFERENCES `lms_homework`             (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hws_student`     FOREIGN KEY (`student_id`)    REFERENCES `std_students`             (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hws_status`      FOREIGN KEY (`status_id`)     REFERENCES `sys_dropdown_table`       (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_hws_graded_by`   FOREIGN KEY (`graded_by`)     REFERENCES `sys_users`                (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hws_created_by`  FOREIGN KEY (`created_by`)    REFERENCES `sys_users`                (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hws_updated_by`  FOREIGN KEY (`updated_by`)    REFERENCES `sys_users`                (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--   1. Row is created when student submits. `assignment_id` is UNIQUE → one active submission per assignment.
--   2. When teacher clicks "Request Resubmission":
--        → status_id = RESUBMIT_REQUESTED
--        → student can update submission_text / attachments_json + resubmit
--        → on resubmit: resubmission_count++, submitted_at updated, is_late re-evaluated
--   3. `score_published_at` is set by app:
--        → If homework.auto_publish_score = 1: set immediately on grading (graded_at)
--        → If homework.auto_publish_score = 0: set when teacher manually publishes
--   4. `attachments_json` structure: array of objects { "media_id": INT, "file_name": STRING, "uploaded_at": DATETIME }


-- ==============================================================================================================
-- SUPPORTING NOTES
-- ==============================================================================================================
-- ---------------------------------------------------------------------------------------------------------------
-- REQUIRED sys_dropdown_table ENTRIES (to be seeded)
-- ---------------------------------------------------------------------------------------------------------------
-- Key: lms_homework.release_condition_id
--   IMMEDIATE           — Released to students immediately when homework is published
--   ON_TOPIC_COMPLETE   — Released when teacher marks the linked schedule topic as completed
--   ON_SCHEDULED_DATE   — Released on lms_homework.release_scheduled_date (via scheduler)
--
-- Key: lms_homework.status_id  /  lms_homework_assignment.status_id
--   lms_homework.status:
--     DRAFT             — Being created by teacher, not visible to students
--     PUBLISHED         — Released/available, assignment records created
--     ARCHIVED          — Closed, no further submissions
--
--   lms_homework_assignment.status:
--     PENDING_RELEASE   — Assignment row exists but not yet visible to student
--     ASSIGNED          — Visible to student but not yet viewed
--     VIEWED            — Student has opened the homework
--     SUBMITTED         — Student submitted on time
--     LATE_SUBMITTED    — Student submitted after due_date (late submission was allowed)
--     GRADED            — Teacher has graded the submission
--     OVERDUE           — Past due_date, no submission (set by scheduled job)
--     EXEMPTED          — Student exempted from this homework
--
--   lms_homework_submissions.status_id:
--     SUBMITTED         — Student has submitted
--     UNDER_REVIEW      — Teacher is reviewing
--     GRADED            — Grading complete
--     REJECTED          — Rejected (submission content invalid/empty)
--     RESUBMIT_REQUESTED — Teacher asked student to redo

-- ---------------------------------------------------------------------------------------------------------------
-- WORKFLOW SUMMARY
-- ---------------------------------------------------------------------------------------------------------------
-- 1. Teacher creates homework (DRAFT) in lms_homework
-- 2. Teacher attaches supporting files (via sys_media), sets release_condition, due_date, marks settings
-- 3. Teacher publishes homework → status = PUBLISHED
--    → App bulk-inserts lms_homework_assignment rows for all students in class+section+subject
--    → If release_condition = IMMEDIATE → is_released=1, status=ASSIGNED, send notifications
--    → If release_condition = ON_TOPIC_COMPLETE → is_released=0, status=PENDING_RELEASE
--    → If release_condition = ON_SCHEDULED_DATE → is_released=0, status=PENDING_RELEASE
-- 4. Release trigger fires (topic completed OR scheduled date arrives):
--    → lms_homework_assignment: is_released=1, released_at=NOW(), status=ASSIGNED
--    → Notifications sent (student_notified_at, parent_notified_at updated)
-- 5. Student views homework → assignment.viewed_at set, view_count++, status=VIEWED
-- 6. Student submits → lms_homework_submissions row created, assignment.status=SUBMITTED/LATE_SUBMITTED
-- 7. Teacher reviews → submission.status=UNDER_REVIEW
-- 8. Teacher grades → submission.marks_obtained, teacher_feedback, graded_by, graded_at set
--    → submission.status = GRADED
--    → assignment.status = GRADED
--    → If auto_publish_score=1 → submission.score_published_at = NOW()
-- 9. Teacher may request resubmission → submission.status = RESUBMIT_REQUESTED → student resubmits
-- 10. Parent notification → assignment.parent_notified_at updated on submit + grade

-- ---------------------------------------------------------------------------------------------------------------
-- ENHANCEMENT SUGGESTIONS
-- ---------------------------------------------------------------------------------------------------------------
-- [S-1] Table Prefix Alignment:
--       Project convention uses prefix `hmw_*` for LmsHomework module (per conventions.md / modules-map.md).
--       Current tables use `lms_homework*` prefix. Recommend renaming in a future migration:
--         lms_homework            → hmw_homeworks
--         lms_homework_assignment → hmw_homework_assignments
--         lms_homework_submissions→ hmw_homework_submissions
--
-- [S-2] Homework Attachments Table (optional alternative to attachments_json on homework):
--       If teacher attaches many files, consider a separate `lms_homework_attachments` table
--       instead of a JSON column on lms_homework:
--         lms_homework_attachments (id, homework_id, media_id, sort_order, is_active, created_by, created_at)
--       This enables easier querying, ordering, and deletion of individual files.
--
-- [S-3] Batch Assignment Audit Log (optional):
--       When homework is bulk-published, log the batch operation:
--         lms_homework_batch_log (id, homework_id, total_students, assigned_count, failed_count, triggered_by, created_at)
--       Useful for re-running if the batch fails mid-way.
--
-- [S-4] Scheduled Job for OVERDUE status:
--       A Laravel scheduled command should run nightly:
--         SELECT id FROM lms_homework_assignment
--         WHERE is_released=1
--           AND status_id NOT IN (SUBMITTED, LATE_SUBMITTED, GRADED, EXEMPTED)
--           AND COALESCE(due_date, (SELECT due_date FROM lms_homework WHERE id=homework_id)) < NOW()
--         → Update status_id = OVERDUE
--
-- [S-5] Effective Due Date Helper:
--       Add a MySQL generated column or handle in app:
--         `effective_due_date` DATETIME GENERATED ALWAYS AS (COALESCE(`due_date`, <homework.due_date>)) VIRTUAL
--       Not feasible as a generated column (cross-table), but can be a Model accessor in Laravel:
--         public function getEffectiveDueDateAttribute() {
--             return $this->due_date ?? $this->homework->due_date;
--         }
