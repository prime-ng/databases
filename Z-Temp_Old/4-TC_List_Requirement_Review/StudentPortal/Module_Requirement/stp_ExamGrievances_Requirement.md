# STP — Exam Grievances (stp_ExamGrievances)

## 1. Module Code
`stp_ExamGrievances` — StudentPortal Exam Grievances Feature

## 2. Feature Name
Exam Grievances / My Grievances

## 3. Feature Description
Enables students to lodge formal disputes or complaints regarding their online exam results. Grievance types include marking errors, question errors, out-of-syllabus content, or other issues. Students can file one grievance per exam result, reference specific questions, track resolution status (Open → Under Review → Resolved/Rejected), and view resolution details including mark changes. The grievance list provides a filtered summary with counts for open, resolved, and rejected tickets.

## 4. FRD Reference / REQ Mapping
| REQ-ID | Priority | Description |
|--------|----------|-------------|
| REQ-STP-033 | P1 | Exam Grievances — File grievance against exam result + track resolution |
| BR-STP-029 | — | Grievance eligibility: Student must have SUBMITTED or EVALUATED attempt |
| BR-STP-030 | — | One grievance per exam result (enforced via duplicate check) |

## 5. Route Structure

| # | Method | URI | Action | Name |
|---|--------|-----|--------|------|
| 1 | GET | `/online-exam/{id}/grievance/create` | `StudentGrievanceController@create` | `online-exam.grievance.create` |
| 2 | POST | `/online-exam/{id}/grievance` | `StudentGrievanceController@store` | `online-exam.grievance.store` |
| 3 | GET | `/my-grievances` | `StudentGrievanceController@index` | `my-grievances` |

## 6. Database Tables Involved
| Table | Type | Purpose |
|-------|------|---------|
| `lms_exam_grievances` | Write | Core grievance record (type, status, resolution details) |
| `lms_exam_results` | Read | Exam result record to file grievance against |
| `lms_exam_papers` | Read | Exam paper title/syllabus reference |
| `lms_exams` | Read | Parent exam entity for display |
| `lms_exam_paper_sets` | Read | Paper set for question listing in grievance form |
| `lms_paper_set_questions` | Read | Questions in the paper for optional question selection |
| `qns_questions_bank` | Read | Question content for dropdown display |
| `sch_subjects` | Read | Subject name for grievance list display |
| `sch_organizations` | Read | (via result chain) school context |

## 7. Finite State Machine (FSM)

### Grievance Status Transitions

| From State | Event | Guard | To State | Side Effects |
|-----------|-------|-------|---------|-------------|
| (new) | Student submits grievance | Student has SUBMITTED/EVALUATED attempt result | OPEN | Grievance record created; notification to admin |
| OPEN | Admin picks up grievance | — | UNDER_REVIEW | — |
| UNDER_REVIEW | Admin resolves (no mark change) | — | RESOLVED | `marks_changed = false`; resolution_remarks recorded; resolved_at set; notification to student |
| UNDER_REVIEW | Admin resolves (mark change) | — | RESOLVED | `marks_changed = true`; old_marks, new_marks recorded; exam result marks updated; resolved_at set; notification to student |
| UNDER_REVIEW | Admin rejects | — | REJECTED | Reason recorded in resolution_remarks; notification to student |

**Terminal states:** RESOLVED, REJECTED
**Grievance Types:** MARKING_ERROR, QUESTION_ERROR, OUT_OF_SYLLABUS, OTHER

## 8. Business Rules / Logic

### BR-STP-029: Grievance Eligibility
- Student must have an exam result record (`lms_exam_results`) for the given paper
- Result record must exist; no explicit SUBMITTED/EVALUATED status check in controller (relies on result existence)
- If no result found: redirect with error: "No result found to file a grievance against."

### BR-STP-030: One Grievance Per Result
- Duplicate check: `ExamGrievance::where('exam_result_id', $result->id)->where('student_id', $studentId)->first()`
- If existing grievance found: redirect to my-grievances with warning: "You have already filed a grievance for this exam result."

### Grievance Form Pre-population
- Exam title resolved from `lms_exam_papers → lms_exams`
- Questions from the paper's paper set listed in optional dropdown for reference
- `existing` variable passed to view for UI state (form disabled if already filed)

### Status Display in List
| Status | Color | Description |
|--------|-------|-------------|
| OPEN | Yellow | Newly filed, awaiting admin action |
| UNDER_REVIEW | Orange | Admin is investigating |
| RESOLVED | Green | Resolved with or without mark change |
| REJECTED | Red | Grievance rejected with reason |

### Resolution Details in List
When RESOLVED, the list displays:
- `marks_changed` (boolean)
- `old_marks` and `new_marks` (when marks changed)
- `resolution_remarks`
- `resolved_at` timestamp

## 9. Input / Payload Specifications

### POST /online-exam/{id}/grievance (store)
| Field | Type | Required | Validation | Description |
|-------|------|----------|-----------|-------------|
| `grievance_type` | string | Yes | `in:MARKING_ERROR,QUESTION_ERROR,OUT_OF_SYLLABUS,OTHER` | Type of grievance |
| `grievance_text` | string | Yes | `string\|min:20\|max:2000` | Detailed description of issue |
| `question_id` | integer | No | `nullable\|integer\|exists:qns_questions_bank,id` | Optional reference to specific question |

## 10. Validation Rules

| Rule | Implementation | Error Handling |
|------|---------------|---------------|
| Grievance type must be valid | `in:MARKING_ERROR,QUESTION_ERROR,OUT_OF_SYLLABUS,OTHER` | 422 validation error |
| Grievance text min 20 chars | `min:20` | 422 validation error: "The grievance text must be at least 20 characters." |
| Grievance text max 2000 chars | `max:2000` | 422 validation error: "The grievance text may not be greater than 2000 characters." |
| Question ID must exist | `exists:qns_questions_bank,id` | 422 validation error (if provided but invalid) |
| One grievance per result | `ExamGrievance::where('exam_result_id', ...)->exists()` | Redirect to my-grievances with warning |
| Result must exist for paper | `DB::table('lms_exam_results')->where(...)->first()` | Redirect to exam result with error |

## 11. Error / Exception Handling

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| No exam result found for paper | 302 | Redirect to exam result with error: "No result found to file a grievance against." |
| Grievance already filed | 302 | Redirect to my-grievances with warning: "You have already filed a grievance for this exam result." |
| Validation failure | 302 (back) | Validation errors displayed on form |
| Missing student profile | — | `$studentId` = 0 (no abort in Grievance controller — relies on null result redirect) |

## 12. Concurrency / Race Conditions

| Scenario | Mitigation |
|----------|-----------|
| Double grievance submission | Duplicate check before create — second request redirects with warning |
| Teacher resolves while student files another | Window of opportunity very small; UNIQUE constraint not enforced at DB level (no unique index on exam_result_id + student_id) |
| Exam result deleted mid-grievance | `ExamGrievance` has `examResult()` relationship — no cascading delete guard (SoftDeletes on both) |

## 13. Role-Based Access / Permissions
- **Student**: Full access — create grievance (for own results), view own grievance list
- **Parent**: No explicit parent support in controller (uses manual `studentContext()` helper rather than `StudentAttemptTrait`)
- **Admin**: Resolution handled in admin panel (not in StudentPortal)

## 14. Screens / UI States

| Screen | Route | UI Elements |
|--------|-------|-------------|
| My Grievances (list) | GET /my-grievances | Summary counts (Open, Resolved, Rejected); grievance cards with ticket ID, exam details, type, status badge, resolution details |
| Grievance Create (form) | GET /online-exam/{id}/grievance/create | Auto-populated exam title, grievance type dropdown, question selector (optional), description textarea |
| Grievance Create (already filed) | GET /online-exam/{id}/grievance/create | Form disabled/messaged showing grievance already exists |

## 15. API / Integration Points

| Integration | Direction | Mechanism |
|-------------|-----------|-----------|
| `activityLog()` helper | Outbound | Logs all grievance actions (viewed, submitted) |
| `ExamGrievance` model CRUD | Internal | Record creation, status management |
| Notification (planned) | Outbound | Admin notified on grievance creation; student notified on resolution |

## 16. Feature Status
- **V1:** Complete
- **V2:** Not started
- **Status:** Complete
- **CR:** ◌

---
*Generated from: `StudentGrievanceController.php` (228 lines), `ExamGrievance.php` (108 lines), `STP_FRD_Complete_2026-06-30.md`, `pgdatabase/Backup/4-Module_Requirement/StudentPortal/examinations/my_grievances.md`*
