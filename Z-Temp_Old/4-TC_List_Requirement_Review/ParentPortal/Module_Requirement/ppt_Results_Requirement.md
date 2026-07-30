# Results & Report Cards — Parent Portal (Read-Only)

## What This Screen Does

The Results & Report Cards screen in the Parent Portal gives parents a read-only view of their active child's academic performance across all assessment types — formal exams, quizzes, quests, and homework results. Parents can see subject-wise marks with class-average comparison (where enabled), check pass/fail status, view teacher remarks, and download an official PDF report card once the school publishes results for the term.

All data is sourced from the `LmsExam`, `LmsQuiz`, `LmsQuests`, and `LmsHomework` modules. The parent cannot modify any result data from this portal.

---

## When This Screen Is Used

- **Post-Exam Review:** After a unit test or term exam is published, the parent reviews their child's marks subject by subject, compares them to the class average, and reads the teacher's remarks.
- **Report Card Season:** At the end of a term, the school publishes report cards. The parent downloads the official PDF for their records.
- **Progress Tracking:** The parent monitors performance trends across all assessment types — how the child did in formal exams vs quizzes vs homework.

---

## Default Data Load

When the parent navigates to the Results tab, the system loads the active child's results aggregated from four sources:

1. **Exam Results** (`lms_exam_results`): All published (`is_published = true`) exam paper results, joined with `lms_exam_papers`, `lms_exams`, and `sch_subjects`. Ordered by `created_at` descending.
2. **Quiz Results** (`lms_quiz_quest_results` where `assessment_type = 'QUIZ'`): Published quiz results joined with `lms_quizzes` and `sch_subjects`.
3. **Quest Results** (`lms_quiz_quest_results` where `assessment_type = 'QUEST'`): Published quest results joined with `lms_quests` and `sch_subjects`.
4. **Homework Results** (`hmw_assignments`): Assignments with a submission and active homework, joined with homework subject.

Each section shows key metrics: subject, marks obtained, max marks, percentage, grade, rank (exam only), and pass/fail status.

---

## Key Fields at a Glance

**Exam Name & Paper Title** — Each exam result shows the exam title (e.g., "Half-Yearly 2026") and the specific paper title (e.g., "Mathematics — Paper I") with its paper code.

**Subject** — The subject name (e.g., "Science", "Mathematics") is shown for every assessment type.

**Marks & Percentage** — `total_marks_obtained` / `total_marks_possible` with an auto-calculated percentage.

**Grade & Division** — The grade (A+, A, B, etc.) and division category (Distinction, First, Second, etc.) as assigned by the school's grading system.

**Result Status** — PASS / FAIL / ABSENT per paper, and an overall status for the exam determined by the presence of any FAIL or ABSENT entries.

**Rank in Class** — The child's rank for this exam paper (if published by the school).

**Teacher Remarks** — Free-text remarks from the teacher evaluating the paper.

**Report Card Download** — A "Download Report Card" button that generates and serves a DomPDF A4 PDF. This button is only active after the school has published at least one HPC report with status "Published" for this child (BR-PPT-005 gate).

---

## Business Rules and Conditions

**Publish Gate on Report Card Download (BR-PPT-005)**
The report card PDF download endpoint (`/results/report-card/pdf`) verifies that at least one `HpcReport` record exists for the child with `status = 'Published'`. If none exist, the parent is redirected back to the results index with a friendly warning message: "Your school has not published a report card for {child name} yet."

**Subject-Wise Exam Breakdown (`show`)**
The single-exam detail view (`show`) loads all published results for that exam + child combination, aggregated by subject paper. It computes:
- Total marks possible and obtained across all papers
- Overall percentage
- Overall grade (taken from the first result with a grade)
- Overall status: ABSENT if any paper is ABSENT, FAIL if any paper is FAIL, otherwise PASS
If the result set is empty (no published results for this child + exam), the system returns 403 — no data leak before publication.

**IDOR Guard via Child Ownership**
All endpoints use `ParentContextService::resolveChild()` to get the active child. The `show()` method further filters `ExamResult` by both `student_id` (child) and `exam_id` (route param), returning 403 if the result set is empty. The `reportCardPdf()` method allows an optional `$studentId` override but only if that student is one of the parent's accessible children.

**Bulk Results List (Index)**
The index page loads four separate result collections (exam, quiz, quest, homework) as independent data sets. There is no pagination — all published results for the current session are loaded.

**No Custom Validation**
This controller does not process any user input besides the route parameter (`Exam` model binding in `show`). No FormRequests are used. The `reportCardPdf()` method has an optional `$studentId` parameter.

---

## Workflow Steps

**Viewing the Results List**
The parent navigates to Results from the sidebar. `ParentResultController::index()` resolves the active child and executes four queries to load exam, quiz, quest, and homework results. These are rendered as collapsible sections on the page (exam results expanded by default).

**Viewing Exam Detail**
The parent clicks a specific exam to open `ParentResultController::show($exam)`. The system verifies published results exist for this child + exam (returning 403 if not), loads the subject-wise breakdown, computes aggregates, and renders the detail view.

**Downloading Report Card PDF**
The parent clicks "Download Report Card". The system checks for a published `HpcReport`. If none exists, the parent is redirected with a warning. If published, the system delegates to `HpcController::generateSingleStudentPdf()` with the bypass-gate flag set to `true` (parent authorization already verified). The PDF is generated as a DomPDF A4 document with school letterhead, student details, subject marks, grades, and teacher remarks.

---

## Example Scenario

**Scenario: End-of-Term Result Review**

Mr. Sharma logs into the Parent Portal to check his son Arjun's Half-Yearly exam results after the school published them. On the Results page, he sees:
- **Half-Yearly 2026** — 5 papers listed with marks and grades
- **Science Quiz — Periodic Table** — Scored 8/10, Passed
- **Math Quest — Algebra Challenge** — Completed with 85%

He clicks the Half-Yearly exam to see the subject-wise breakdown:
- Mathematics: 72/80 (90%) — Grade A+, Rank 3
- Science: 65/80 (81%) — Grade A, Rank 7
- English: 58/80 (73%) — Grade B+, Rank 12
- History: 60/80 (75%) — Grade B+, Rank 9
- Overall: 255/320 (79.7%) — Grade A, PASS

He clicks "Download Report Card." Since the school has published the HPC report, the PDF downloads immediately.

---

## Related Screens

- **Parent Dashboard** (last test score widget linking to Results)
- **Learning Hub** (quiz/quest results also appear in the learning activity overview)
- **HPC Module** (report card PDF generation delegated to HPC)

---

## Business Conditions

### 5.1 Database Schema — `lms_exam_results` (Read-Only)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-03 | exam_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-04 | exam_paper_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-05 | total_marks_obtained | DECIMAL(8,2) | NULL |
| BC-DB-06 | total_marks_possible | DECIMAL(8,2) | NOT NULL |
| BC-DB-07 | percentage | DECIMAL(5,2) | NULL |
| BC-DB-08 | grade_obtained | VARCHAR(10) | NULL |
| BC-DB-09 | result_status | ENUM(PASS,FAIL,ABSENT) | NOT NULL |
| BC-DB-10 | division | VARCHAR(50) | NULL |
| BC-DB-11 | rank_in_class | INT | NULL |
| BC-DB-12 | teacher_remarks | TEXT | NULL |
| BC-DB-13 | is_published | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-14 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Database Schema — `lms_quiz_quest_results` (Read-Only)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-15 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-16 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-17 | assessment_type | ENUM(QUIZ,QUEST) | NOT NULL |
| BC-DB-18 | assessment_id | INT UNSIGNED | NOT NULL |
| BC-DB-19 | total_marks_obtained | DECIMAL(8,2) | NULL |
| BC-DB-20 | max_marks | DECIMAL(8,2) | NOT NULL |
| BC-DB-21 | percentage | DECIMAL(5,2) | NULL |
| BC-DB-22 | grade_obtained | VARCHAR(10) | NULL |
| BC-DB-23 | is_passed | TINYINT(1) | NULL |
| BC-DB-24 | is_published | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-25 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.3 Database Schema — `hpc_reports` (Read-Only, Gate Check)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-26 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-27 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-28 | status | VARCHAR(50) | NOT NULL (e.g., 'Published') |

### 5.4 Authorization

| BC ID | Rule | Behavior |
|-------|------|----------|
| BC-AUTH-01 | Parent authenticated | Unauthenticated → redirect to login |
| BC-AUTH-02 | Child ownership | `resolveChild()` enforces guardian→child linkage |
| BC-AUTH-03 | Published results only | All queries filter `is_published = true` |
| BC-AUTH-04 | Exam detail IDOR guard | Empty result set → HTTP 403 |
| BC-AUTH-05 | Report card student override | Allowed only if student is in parent's accessible children list |
| BC-AUTH-06 | Report card publish gate | No published HPC report → redirect with warning |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | No published results for exam | `show()` returns 403 (empty collection) |
| BC-BIZ-02 | Overall exam status | ABSENT if any paper absent; FAIL if any paper fail; else PASS |
| BC-BIZ-03 | Overall grade | Uses first result's `grade_obtained` |
| BC-BIZ-04 | Overall percentage | `(obtained / possible) * 100`, rounded to 1 decimal |
| BC-BIZ-05 | Missing HPC report | Friendly redirect with child's first name in message |
| BC-BIZ-06 | Student override in report card | Only if `$studentId` in parent's accessible children list |
| BC-BIZ-07 | Activity logging | All `index()`, `show()`, `reportCardPdf()` calls logged |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_id | lms_exams | CASCADE |
| BC-REF-02 | exam_paper_id | lms_exam_papers | CASCADE |
| BC-REF-03 | student_id | std_students | CASCADE |
| BC-REF-04 | assessment_id | lms_quizzes / lms_quests | CASCADE |

---

## Validation Rules

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | exam (route) | Route model binding: `Exam` | 404 if exam not found |
| BC-VAL-02 | studentId (optional query) | Must be in parent's accessible children | 403 if not accessible |

---

## V1/V2 Gaps

| Gap | Type | Description | Impact |
|-----|------|-------------|--------|
| ParentChildPolicy MISSING | P0 Security | Results controller relies on `resolveChild()` + manual checks instead of a formal policy | Low — ownership checks are explicit in all three methods |
| Report card PDF DomPDF template unverified | P1 Code Review | Delegates to HPC controller; should verify template path, school letterhead, and font rendering | PDF may render incorrectly |
| No class-average comparison in show view | P1 Feature Gap | FRD promises class-average comparison (AC3) but controller does not compute or pass class-average data | Feature incomplete |
| Quiz/Quest results not linked to Learning Hub | P2 Integration | Quiz and quest results loaded in both Results and Learning Hub controllers — may duplicate | Acceptable as separate views |

---

## Module Integration

| Integration | Direction | Details |
|-------------|-----------|---------|
| LmsExam | Read | `Exam`, `ExamResult` models; exam_papers, exams tables |
| LmsQuiz | Read | `lms_quiz_quest_results` filtered by `QUIZ` type |
| LmsQuests | Read | `lms_quiz_quest_results` filtered by `QUEST` type |
| LmsHomework | Read | `HomeworkAssignment` with submission for homework results |
| HPC | Read | `HpcReport` for publish gate check; `HpcController` for PDF generation |
| ParentContextService | Read | Child resolution |
| DomPDF | Read (PDF) | `Barryvdh\DomPDF` for report card PDF generation |
| sys_activity_logs | Write | Audit log |

---

## Known Limitations

- No search or filter on results list — all results loaded at once
- No sort controls — results ordered by `created_at` descending
- Quiz and quest results are duplicated in the Learning Hub feature
- Class-average comparison data not passed to the view

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-23 | AI | Initial requirement doc from live code audit + FRD analysis |

---

*End of ppt_Results_Requirement.md*
