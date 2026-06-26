# Tab 8: Question Review

This tab handles the quality check process. Before a question can be published and used by students, it should ideally go through a review by another teacher who checks that it is correct, clear, and appropriate.

---

## How It Works

When a question is submitted for review — status changes from Draft to In Review — it appears in this tab. If a specific reviewer was named, it shows up in that teacher's "My Pending Reviews" section. If no reviewer was named, it goes to "Available for Review," where any teacher can claim it.

The reviewer opens the question and sees everything about it — the question content, the answer options, the correct answer, the taxonomy mapping, the media attachments. Everything is read-only; the reviewer cannot make changes. They examine the question and decide.

**If they approve:** The question moves to Approved status. The reviewer can leave a comment but does not have to. The creator then needs to take one more step — publishing the question — before students can see it. Approval does not automatically publish.

**If they reject:** The reviewer MUST write a comment explaining why. The system will not accept a blank rejection. The question goes back to Draft status, and the creator sees the rejection reason prominently displayed. The creator fixes the issues and can submit for review again. There is no limit on how many times a question can be rejected and resubmitted.

The review log is permanent. Every approval and every rejection is recorded with the reviewer's name, the decision, the comment, and the timestamp. These logs stay forever and cannot be deleted. If a question is reviewed ten times — approved twice, rejected three times, approved three more times, rejected twice — all ten entries are preserved in order.

---

## Important Business Rules

- Any teacher can be a reviewer. There is no special "reviewer" role — the system treats all teachers as potential reviewers. A teacher can even review their own questions (self-review), though this somewhat defeats the purpose of having a second pair of eyes.
- If a reviewer is assigned but becomes unavailable — for example, they leave the school — the question stays stuck in In Review. There is no automatic reassignment. An admin must manually change the question's status to resolve this.
- The creator cannot edit the question while it is In Review. They must either wait for the review decision or cancel the review request (which sends the question back to Draft).
- There is no time limit. A question can sit In Review for weeks or months. The creator has no way to escalate if a reviewer is slow. The only option is to cancel the review and assign a different reviewer.
- There is a fast-track option during creation. If the creator sets the question status to Published and simultaneously assigns a reviewer with an approved decision, the system records it as reviewed and published in one step. This is useful for experienced teachers who want the audit trail without the delay.
- If two reviewers somehow try to review the same question at the same time, the first one to click Approve or Reject succeeds. The second one gets an error saying the question has already been reviewed.
- If a reviewer rejects a question but the creator disagrees, there is no formal dispute process. The creator can contact the reviewer directly or submit to a different reviewer next time.
- The review log for a question survives even if the question is deleted. The log becomes orphaned — it shows "(Deleted Question)" as the reference — but the review data remains.
- A rejection requires a mandatory comment. The system will not accept an empty rejection reason.
- Approving a question moves it to Approved status but does not publish it. The creator must take the additional step of changing the status from Approved to Published.
- There is no limit on how many times a question can go through the review cycle. It can be rejected and resubmitted indefinitely.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| Draft | Creator submits for review | In Review | Question enters review queue |
| In Review | Reviewer assigned explicitly | Assigned Review | Appears in "My Pending Reviews" |
| In Review | No specific reviewer | Available for Review | Any teacher can claim it |
| In Review | Reviewer clicks "Approve" | Approved | Comment optional; log entry created |
| In Review | Reviewer clicks "Reject" | Draft | Comment mandatory; log entry created |
| In Review | Creator cancels review | Draft | Review request withdrawn |
| In Review | Two reviewers attempt simultaneously | First succeeds, second gets error | "This question has already been reviewed." |
| Approved | Creator clicks "Publish" | Published | Question becomes available for assessments |
| Draft (rejected) | Creator fixes and resubmits | In Review | New review cycle begins |
| Any | Admin overrides stuck question | Chosen Status | Manual intervention for unavailable reviewer |
| Draft ? Published | Creator sets Published + reviewer approves | Fast-Track Published | Combined approve + publish in one step |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Rejection comment | Mandatory | "A comment is required when rejecting a question." |
| Self-review | Allowed | No error; system does not block self-review |
| Reviewer unavailable | No automatic reassignment | Admin must manually change question status |
| Edit while In Review | Blocked | "This question is currently under review. Cancel the review request before editing." |
| No time limit | Question can stay In Review indefinitely | No escalation mechanism |
| Concurrent review | First reviewer action wins | "This question has already been reviewed by another reviewer." |
| Duplicate review | Attempt to review already-reviewed question | "This question has already been reviewed." |
| Review log permanence | Cannot be edited or deleted | Survives question deletion (orphaned) |
| Re-review limit | Unlimited cycles | Can be rejected and resubmitted indefinitely |
| Approval ? Publish | Approval moves to Approved status | Creator must take separate publish action |
| Fast-track review | Creator = reviewer scenario | Approved decision recorded; status goes to Published |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | qns_question_review_log | question_id | Stores all review decisions |
| Question Bank | qns_questions_bank | id | Question status management (DRAFT/IN_REVIEW/APPROVED/REJECTED/PUBLISHED) |
| Users | sch_users | reviewer_id | Reviewer identity tracking |
| Users | sch_users | (referenced via question's created_by) | Creator notification on rejection |
| System Config | sys_dropdowns | review_status_id | Review status lookup (PENDING/APPROVED/REJECTED) |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View review queue | Teacher | question-review.viewAny |
| Claim available review | Teacher | question-review.claim |
| Approve question | Teacher | question-review.approve |
| Reject question | Teacher | question-review.reject |
| Cancel review request | Teacher (creator) | question-review.cancel |
| Override stuck review | Admin | question-review.override |
| View review log history | Teacher | question-review.view-history |
| View orphaned review logs | Admin | question-review.view-orphaned |
| Delete review log entries | Not available (any role) | – |

---

## Database Columns & Behavior

### qns_question_review_log

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete; survives as orphaned if question force-deleted) |
| reviewer_id | INT UNSIGNED | users.id | No | – | Reviewer user FK (CASCADE delete) |
| review_status_id | INT UNSIGNED | sys_dropdowns.id | No | – | Review decision (PENDING/APPROVED/REJECTED) |
| review_comment | TEXT | No | Yes | NULL | Reviewer's comment (mandatory for rejection) |
| reviewed_at | DATETIME | No | No | – | When the review decision was made |
| is_active | TINYINT(1) | No | No | 1 | Soft delete flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |

### qns_questions_bank

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| uuid | BINARY(16) | No | No | – | Globally unique identifier via UUID_TO_BIN |
| class_id | INT UNSIGNED | sch_classes.id | No | – | Denormalized FK to class |
| subject_id | INT UNSIGNED | sch_subjects.id | No | – | Denormalized FK to subject |
| lesson_id | INT UNSIGNED | slb_lessons.id | No | – | Denormalized FK to lesson |
| topic_id | INT UNSIGNED | slb_topics.id | No | – | FK to topic |
| competency_id | INT UNSIGNED | slb_competencies.id | No | – | FK to competency |
| ques_title | VARCHAR(255) | No | No | – | Internal title for system use |
| ques_title_display | TINYINT(1) | No | No | 0 | Whether title is shown to students |
| question_content | TEXT | No | No | – | Question text displayed to users |
| content_format | ENUM | No | No | 'TEXT' | Content format specification |
| media_required_for_question | TINYINT(1) | No | No | 0 | Whether media is mandatory |
| media_location_for_question | ENUM | No | Yes | 'Below Text' | Media placement |
| teacher_explanation | TEXT | No | Yes | NULL | Explanation shown to students |
| media_required_for_teacher_explanation | TINYINT(1) | No | No | 0 | Whether media is mandatory for explanation |
| media_location_for_teacher_explanation | ENUM | No | Yes | 'Below Text' | Media placement for explanation |
| bloom_id | INT UNSIGNED | slb_bloom_taxonomy.id | No | – | Bloom's taxonomy level FK |
| cognitive_skill_id | INT UNSIGNED | slb_cognitive_skill.id | No | – | Cognitive skill taxonomy FK |
| ques_type_specificity_id | INT UNSIGNED | slb_ques_type_specificity.id | No | – | Question type specificity FK |
| complexity_level_id | INT UNSIGNED | slb_complexity_level.id | No | – | Complexity level FK |
| question_type_id | INT UNSIGNED | slb_question_types.id | No | – | Question type FK |
| expected_time_to_answer_seconds | INT UNSIGNED | No | Yes | NULL | Expected answer time |
| marks | DECIMAL(5,2) | No | No | 1.00 | Marks for correct answer |
| negative_marks | DECIMAL(5,2) | No | No | 0.00 | Penalty marks |
| current_version | TINYINT UNSIGNED | No | No | 1 | Current version counter |
| for_quiz | TINYINT(1) | No | No | 1 | Usable in Quiz |
| for_quest | TINYINT(1) | No | No | 0 | Usable in Quest |
| for_exam | TINYINT(1) | No | No | 0 | Usable in Exam |
| for_offline_exam | TINYINT(1) | No | No | 0 | Usable in Offline Exam |
| ques_owner | ENUM | No | No | 'PrimeGurukul' | Ownership scope |
| created_by_AI | TINYINT(1) | No | No | 0 | AI-generated flag |
| created_by | INT UNSIGNED | sch_users.id | Yes | NULL | Creator user FK |
| is_school_specific | TINYINT(1) | No | No | 0 | School-specific flag |
| availability | ENUM | No | No | 'GLOBAL' | Visibility scope |
| selected_entity_group_id | INT UNSIGNED | slb_entity_groups.id | Yes | NULL | Entity group |
| selected_section_id | INT UNSIGNED | sch_sections.id | Yes | NULL | Section |
| selected_student_id | INT UNSIGNED | sch_students.id | Yes | NULL | Student |
| book_id | INT UNSIGNED | slb_books.id | Yes | NULL | Textbook reference |
| book_page_ref | VARCHAR(50) | No | Yes | NULL | Page number |
| external_ref | VARCHAR(100) | No | Yes | NULL | External mapping |
| reference_material | TEXT | No | Yes | NULL | Reference material |
| status | ENUM('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') | No | No | 'DRAFT' | Lifecycle status |
| is_active | TINYINT(1) | No | No | 1 | Active flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
