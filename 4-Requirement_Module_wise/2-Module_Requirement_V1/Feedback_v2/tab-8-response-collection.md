# Feedback Tab 8: Response Collection

This is the feedback submission interface where students, parents, teachers, and staff fill out and submit their feedback forms. Respondents see a list of pending feedback tasks they need to complete, open a form to answer questions, and submit or save their responses as drafts.

---

## How It Works

When a respondent logs in, they see a list of all active feedback cycles where they are an eligible respondent. Each pending item shows the cycle name, the target they are rating (e.g., their class teacher, subject teacher, or peer), the deadline, and whether they have already started a draft. Respondents can click on any pending item to open the feedback form.

The feedback form displays the questions from the assigned template, grouped by category. Questions appear in the configured order with their type-appropriate input controls: star ratings for Rating_5, sliders for Rating_10, Likert scale radio buttons, emoji selectors, yes/no toggles, multiple choice dropdowns, and text areas for free text. Required questions are clearly marked. Help text is shown as tooltips or inline hints.

Respondents can save their progress as a draft and return later. Once they submit, the response is marked as Submitted and can no longer be edited unless withdrawal is allowed. If withdrawal is enabled, the respondent can withdraw their submission within the active window, which allows them to resubmit a revised response.

Anonymity is handled automatically. When the cycle feedback type has anonymity enabled, the respondent's identity is never shown to the target in any reports or dashboards. The system enforces this at the database and application level.

---

## Important Business Rules

- A respondent can only submit feedback during the active cycle window. The current date must be within start_date and end_date and the cycle status must be Active.
- Student respondents must be logged in as themselves. A student cannot submit feedback on behalf of another student.
- Parent respondents must be linked to their child through the guardian relationship and must have portal access enabled. Parents rate teachers in the context of their own child.
- Teacher respondents must actually teach the target student or be related through a valid timetable activity.
- Peer respondents must share the same class section as the target peer. A student cannot rate themselves in a peer relationship.
- Each respondent can submit only one response per (cycle feedback type × target × context). The system enforces this deduplication.
- Draft responses are saved with status = Draft and can be edited. Submitted responses cannot be edited but can be withdrawn if the cycle feedback type allows it.
- Withdrawn responses are marked with status = Withdrawn and a reason. The respondent can create a new draft after withdrawing.
- Anonymity is enforced for peer relationships regardless of cycle settings. The system never reveals the respondent identity for peer feedback.
- All submissions record the respondent's IP address and user agent for audit purposes.
- The overall rating is computed server-side at submission time based on the template's rating method and question weights.

---

## Database Columns & Behavior

### fbk_responses
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `cycle_id` / `cycle_feedback_type_id` / `template_id` / `relationship_type_id` — Snapshot references to the cycle configuration at submission time.
- `cycle_target_id` — Optional FK to fbk_cycle_targets.id. Links response to participation tracking. INT UNSIGNED, nullable.
- `respondent_kind_id` — FK to sys_dropdown_table.id (key: fbk_responses.respondent_kind). Student, Parent, Teacher, Staff, Admin, or Self. INT UNSIGNED.
- `respondent_user_id` — Always populated. The sys_users.id of the logged-in actor. INT UNSIGNED.
- `respondent_student_id` — FK to std_students.id. Populated when respondent is Student or when Parent is rating about their child. INT UNSIGNED, nullable.
- `respondent_guardian_id` — FK to std_guardians.id. Populated when respondent is Parent. INT UNSIGNED, nullable.
- `respondent_employee_id` — FK to sch_employees.id. Populated when respondent is Teacher, Staff, or Admin. INT UNSIGNED, nullable.
- `target_type_id` — FK to fbk_target_types.id. SMALLINT UNSIGNED.
- `target_user_id` / `target_student_id` / `target_employee_id` / `target_department_id` — Polymorphic target identity. One is populated based on target type. INT UNSIGNED, nullable.
- `class_section_id` / `subject_id` / `tt_activity_id` / `context_json` — Context in which the feedback was given.
- `overall_rating` — Computed overall score. DECIMAL(4,2), nullable.
- `overall_comment` — Optional overall comment. TEXT, nullable.
- `is_anonymous_to_target` — Snapshot of anonymity setting at submission time. TINYINT(1), default 1.
- `status_id` — FK to sys_dropdown_table.id (key: fbk_responses.status). Draft, Submitted, Withdrawn. INT UNSIGNED.
- `submitted_at` / `withdrawn_at` / `withdrawn_reason` — Submission lifecycle timestamps.
- `submission_ip` / `submission_user_agent` — Audit trail. VARCHAR(45) / VARCHAR(255).

### fbk_answers (per-question answers)
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `response_id` — FK to fbk_responses.id. INT UNSIGNED. Cascade delete.
- `question_id` — FK to fbk_questions.id. INT UNSIGNED.
- `question_type_id_snapshot` — Snapshot of question type at submission time. FK to sys_dropdown_table.id. INT UNSIGNED.
- `category_id_snapshot` — Snapshot of category. FK to fbk_categories.id, nullable.
- `weight_snapshot` — Snapshot of question weight. DECIMAL(4,2), default 1.00.
- `rating_value` — Numeric answer for Rating_5/10, Likert_5, Emoji_5. DECIMAL(4,2), nullable.
- `boolean_answer` — Yes/No answer. TINYINT(1), nullable.
- `selected_option_code` — Multi_Choice selected option code. VARCHAR(50), nullable.
- `selected_option_value` — Numeric value of selected option. DECIMAL(4,2), nullable.
- `text_answer` — Free text answer. TEXT, nullable.
- `emoji_value` — Emoji_5 answer code (angry, sad, neutral, smile, happy). VARCHAR(20), nullable.

---

## Deep Analysis

### Business Workflows & State Machines

Response has a three-state machine:

```
        ┌───────────┐
        │   Draft   │ ◄──── New
        └─────┬─────┘
              │ Submit
              ▼
        ┌───────────┐
        │ Submitted │ ──── Terminal (no edit)
        └─────┬─────┘
              │ Withdraw (if allowed)
              ▼
        ┌───────────┐
        │ Withdrawn │ ◄── Can create new Draft
        └───────────┘
```

Transitions:
- **(none) → Draft**: Respondent creates a new response and saves progress. A new row is inserted with status_id = Draft.
- **Draft → Draft**: Respondent saves updated draft. UPDATE on same row.
- **Draft → Submitted**: Respondent clicks Submit. Server computes overall_rating, sets submitted_at, changes status to Submitted. Side-effect: increment fbk_cycle_targets.submitted_response_count.
- **Submitted → Withdrawn**: Only if cycle_feedback_type.allow_withdrawal = 1 AND cycle is still Active. Sets withdrawn_at, withdrawn_reason, changes status to Withdrawn. After withdrawal, respondent can create a new Draft.
- **Submitted → Submitted**: No transitions. Submitted is terminal for editing.
- **Withdrawn → Submitted**: Can only happen via creating a new Draft → Submit (not a direct transition).

The pending-eligibility workflow:
1. System computes eligible respondent-target pairs from fbk_cycle_targets + context resolution.
2. For each pair, check if a response exists. If not, or if status = Withdrawn, show as pending.
3. If status = Draft, show as "In Progress".
4. If status = Submitted, show as "Completed".

### Validation Rules & Edge Cases

- **Cycle window check**: System must verify CURRENT_TIMESTAMP is between cycle.start_date and cycle.end_date AND cycle.status_id = Active. Reject submission if outside window.
- **Dedup enforcement**: UNIQUE KEY `uq_fbk_r_dedup` on (cycle_feedback_type_id, respondent_user_id, respondent_student_id_uq, target_user_id_uq, target_student_id_uq, target_employee_id_uq, target_department_id_uq, subject_id_uq, class_section_id_uq, deleted_at). This prevents double submission. The generated COALESCE columns convert NULLs to 0 for the unique constraint.
- **Respondent identity integrity**: Exactly one of respondent_student_id/respondent_guardian_id/respondent_employee_id must be non-null, matching respondent_kind_id:
  - Student → respondent_student_id IS NOT NULL
  - Parent → respondent_guardian_id IS NOT NULL
  - Teacher/Staff/Admin → respondent_employee_id IS NOT NULL
  - Self → respondent_{student|employee}_id matches target_{student|employee}_id
- **Target identity integrity**: Exactly one target_{user|student|employee|department}_id populated, matching target_type.linked_entity_table_id.
- **Peer self-rating prevention**: For is_peer_relationship = 1, respondent_student_id must NOT equal target_student_id.
- **Parent portal access**: Parent respondents require std_student_guardian_jnt.can_access_parent_portal = 1. Check at eligibility computation time.
- **Draft edit boundary**: Only responses with status = Draft can be edited. If a cycle becomes Closed while a respondent has a Draft, the Draft is frozen — cannot be submitted or edited.
- **Withdrawal deadline**: Withdrawal should only be allowed while cycle is Active (not Closed). The UI must grey out the Withdraw button after cycle end date.
- **Overall rating computation at submit**: The server must compute overall_rating atomically during the Submit action. If computation fails, the submission must roll back.
- **Audit trail**: IP address and user agent are captured. For security-sensitive flows (e.g., peer feedback), the system may also log geographic location from IP.
- **Anonymity snapshot**: is_anonymous_to_target is snapshotted at submission time. Changing the cycle feedback type's anonymity setting after submissions exist does not affect existing responses.
- **Large question sets**: A template with 100+ questions. The form should paginate by category or use a scrollable single-page layout with category anchors.
- **Required question validation**: On Submit (but NOT on Draft save), all questions with is_required = 1 must have a non-null answer. The server must validate this and return field-level errors for each missing required question.

### Integration Points

- **fbk_cycles** via cycle_id — validates active window and status.
- **fbk_cycle_feedback_types** via cycle_feedback_type_id — resolves anonymity, draft, withdrawal settings, and template.
- **fbk_templates** via template_id — determines question set and rating method.
- **fbk_relationship_types** via relationship_type_id — determines context rule and peer status.
- **fbk_cycle_targets** via cycle_target_id — links to participation tracking counts.
- **fbk_questions** via fbk_answers.question_id — the question being answered.
- **sys_users** via respondent_user_id — the logged-in respondent.
- **std_students** via respondent_student_id / target_student_id — student identity.
- **std_guardians** via respondent_guardian_id — parent/guardian identity.
- **sch_employees** via respondent_employee_id / target_employee_id — teacher/staff identity.
- **sch_departments** via target_department_id — aggregate department targets.
- **sys_dropdown_table** via respondent_kind_id, status_id, question_type_id_snapshot — resolves display values.
- **Rating calculation engine**: Reads template.overall_rating_method_id, question weights, and reverse-scored flags to compute overall_rating.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View pending items | Yes | Yes | Yes (own) | Yes (own) | Yes (own) | Yes (own) |
| Create response (Submit) | Yes (as Admin) | Yes (as Principal) | Yes (own context) | Yes (own context) | Yes (own context) | Yes (own context) |
| Save draft | Yes | Yes | Yes | Yes | Yes | Yes |
| Edit draft | Yes | Yes | Yes | Yes | Yes | Yes |
| Submit response | Yes | Yes | Yes | Yes | Yes | Yes |
| Withdraw response | If allowed | If allowed | If allowed | If allowed | If allowed | If allowed |
| View own complete responses | Yes | Yes | Yes | Yes | Yes | Yes |
| Submit on behalf of others | No | No | No | No | No | No |
| Override anonymity | No | No | No | No | No | No |
