# ppt_Results_TcList

## Module: ParentPortal → Results → Results & Report Cards (Read-Only)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | ParentPortal |
| Tab Group | Results |
| Feature | Results & Report Cards (Read-Only View + PDF Download) |
| URL(s) | `GET /parent-portal/results` (route: `parent-portal.results.index`)<br>`GET /parent-portal/results/{exam}` (route: `parent-portal.results.show`)<br>`GET /parent-portal/results/report-card/pdf` (route: `parent-portal.results.report-card.pdf`)<br>`GET /parent-portal/results/report-card/pdf/{studentId}` (route: `parent-portal.results.report-card.pdf` with override) |
| Controller | `Modules\ParentPortal\Http\Controllers\ParentResultController` |
| Model(s) | `Modules\LmsExam\Models\Exam`, `Modules\StudentPortal\Models\ExamResult`, `Modules\LmsHomework\Models\HomeworkAssignment`, `Modules\Hpc\Models\HpcReport` |
| FormRequest | None (read-only + PDF download) |
| Policy / Permissions | No explicit policy — scoped via `ParentContextService::resolveChild()` + manual checks |
| Soft Deletes | Yes — `ExamResult`, `HomeworkAssignment` |
| Activity Log | `activityLog()` in `index()`, `show()`, `reportCardPdf()` |
| View(s) | `parentportal::results.index`, `parentportal::results.show` |
| PDF Service | `Barryvdh\DomPDF\Facade\Pdf` (via HPC controller) |

---

## 2. Pre-conditions

- Parent must be authenticated and logged into a tenant (school)
- Parent must have at least one linked child with `can_access_parent_portal = 1`
- Tenant must have `LmsExam` module active (core results data)
- For exam results: At least one `lms_exam_results` record with `is_published = true` for the active child
- For report card PDF: At least one `hpc_reports` record with `status = 'Published'` for the child
- Dusk environment: `DUSK_TENANT_URL`, `DUSK_GUARDIAN_EMAIL`, `DUSK_GUARDIAN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `ParentResultController@index()`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Exam Results | `DB::table('lms_exam_results')` | Join `lms_exam_papers`, `lms_exams`, `sch_subjects` WHERE `student_id = ?` AND `is_published = true` AND `deleted_at IS NULL` ORDER BY `created_at` DESC | Published only | None |
| Quiz Results | `DB::table('lms_quiz_quest_results')` | Join `lms_quizzes`, `sch_subjects` WHERE `student_id = ?` AND `assessment_type = 'QUIZ'` AND `is_published = true` | Published QUIZ only | None |
| Quest Results | `DB::table('lms_quiz_quest_results')` | Join `lms_quests`, `sch_subjects` WHERE `student_id = ?` AND `assessment_type = 'QUEST'` AND `is_published = true` | Published QUEST only | None |
| Homework Results | `HomeworkAssignment` | WHERE `student_id = ?` AND `is_active = true` AND `has submission` WITH `homework.subject`, `submission` ORDER BY `due_date` DESC | Has submission | None |

---

## 4. Test Data Strategy

- Create exam results across multiple exams and papers with varying statuses (PASS, FAIL, ABSENT)
- Create both published (`is_published = true`) and unpublished (`is_published = false`) results
- Create quiz and quest results with `assessment_type = 'QUIZ'` and `'QUEST'`
- Create homework assignments with submissions and marks
- For report card test: Create a `hpc_reports` record with `status = 'Published'`
- Test the publish gate with no published report (verify friendly redirect)
- Test IDOR with another child's exam
- Pre-test cleanup: Soft-delete or deactivate test data

---

## 5. Business Conditions

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
| BC-DB-13 | is_published | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-14 | deleted_at | TIMESTAMP | NULL |

### 5.2 Database Schema — `hpc_reports` (Read-Only, Gate)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-15 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-16 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-17 | status | VARCHAR(50) | NOT NULL |

### 5.3 Authorization

| BC ID | Rule | Expected Behavior |
|-------|------|-------------------|
| BC-AUTH-01 | Guest access | Redirect to login |
| BC-AUTH-02 | No linked children | `resolveChild()` throws/redirects |
| BC-AUTH-03 | Show exam — no published results | HTTP 403 |
| BC-AUTH-04 | Show exam — correct ownership | Detail page with subject-wise marks |
| BC-AUTH-05 | Report card — no published report | Redirect with warning message |
| BC-AUTH-06 | Report card — student override not allowed | `$studentId` not in accessible children → HTTP 403 |
| BC-AUTH-07 | Report card — student override allowed | HPC PDF generated for requested student |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Index loads 4 result types | Exam, Quiz, Quest, Homework sections all present |
| BC-BIZ-02 | Overall status = PASS | No FAIL or ABSENT papers → PASS |
| BC-BIZ-03 | Overall status = FAIL | Any paper FAIL → FAIL |
| BC-BIZ-04 | Overall status = ABSENT | Any paper ABSENT → ABSENT |
| BC-BIZ-05 | Overall grade | Uses first paper's grade_obtained |
| BC-BIZ-06 | Overall percentage | `(sum obtained / sum possible) * 100`, rounded to 1 decimal |
| BC-BIZ-07 | Show with mixed statuses | Multiple papers with PASS, FAIL, ABSENT all displayed |
| BC-BIZ-08 | Report card download — published | PDF returned via HPC controller |
| BC-BIZ-09 | Report card download — not published | Redirect to results index with warning flash message |
| BC-BIZ-10 | Activity logging | All 3 methods log "Viewed" entries |
| BC-BIZ-11 | Empty results set (no data at all) | Graceful empty state on index (no crash) |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | exam_id | lms_exams | CASCADE |
| BC-REF-02 | exam_paper_id | lms_exam_papers | CASCADE |
| BC-REF-03 | student_id | std_students | CASCADE |
| BC-REF-04 | assessment_id | lms_quizzes / lms_quests | CASCADE |

---

## 6. Test Scenarios

| TC ID | Scenario | Description | Priority |
|-------|----------|-------------|----------|
| TC-RS-001 | Load results index | All 4 result types load correctly | P0 |
| TC-RS-002 | View exam detail — published results | Subject-wise breakdown renders | P0 |
| TC-RS-003 | View exam detail — no published results | Must return 403 | P0 |
| TC-RS-004 | View exam detail — wrong child | Must return 403 | P0 |
| TC-RS-005 | Download report card — published | PDF returned | P0 |
| TC-RS-006 | Download report card — not published | Redirect with warning | P0 |
| TC-RS-007 | Overall status computation (PASS, FAIL, ABSENT) | Correct aggregation | P1 |
| TC-RS-008 | Quiz and quest results in index | Both shown in respective sections | P1 |
| TC-RS-009 | Activity logging verification | Audit log entries for all actions | P1 |
| TC-RS-010 | Empty results state (no data) | Graceful empty message | P2 |

---

## 7. Test Cases

| TC ID | Test Case | Steps | Expected Result |
|-------|-----------|-------|-----------------|
| TC-RS-001-01 | Results index loads all 4 sections | 1. Create exam, quiz, quest, homework results<br>2. Navigate to `/parent-portal/results` | All 4 sections visible with correct data |
| TC-RS-001-02 | Unpublished results excluded | 1. Create exam result with is_published=0<br>2. Navigate to index | Exam not shown in results list |
| TC-RS-002-01 | Exam detail — subject-wise breakdown | 1. Create exam with 2 papers (Maths 80/80, Science 65/80)<br>2. Navigate to exam show page | Both subjects listed with marks, percentage, grade |
| TC-RS-002-02 | Exam detail — aggregates computed | 1. Create exam with 2 papers (Maths 72/80, Science 65/80)<br>2. Check overall percentage | Overall: 137/160 = 85.6% — Overall status: PASS |
| TC-RS-003-01 | Exam with no published results | 1. Create exam where all results have is_published=0<br>2. Navigate to exam show | HTTP 403 |
| TC-RS-004-01 | Wrong child exam access | 1. Get exam ID that has results for another child<br>2. Navigate to exam show as different parent | HTTP 403 (empty result set) |
| TC-RS-005-01 | Download report card — published | 1. Create hpc_reports with status=Published for child<br>2. Click "Download Report Card" | PDF file downloaded |
| TC-RS-005-02 | Download report card — override valid student | 1. Pass another accessible child's ID<br>2. Click download | PDF for that child downloaded |
| TC-RS-006-01 | Download report card — not published | 1. No hpc_reports for child<br>2. Click "Download Report Card" | Redirect to results index with flash warning |
| TC-RS-006-02 | Warning message contains child name | 1. No published report for child "Aarav"<br>2. Click download | Flash message mentions "Aarav" |
| TC-RS-007-01 | Overall FAIL when any paper fails | 1. Create exam with 3 papers: PASS, FAIL, PASS<br>2. View exam detail | Overall status = FAIL |
| TC-RS-007-02 | Overall ABSENT when any paper absent | 1. Create exam with 3 papers: PASS, ABSENT, PASS<br>2. View exam detail | Overall status = ABSENT |
| TC-RS-007-03 | Overall PASS when all pass | 1. Create exam with all PASS papers<br>2. View exam detail | Overall status = PASS |
| TC-RS-008-01 | Quiz results in index | 1. Create quiz result for child<br>2. Navigate to results index | Quiz section shows quiz title, score, percentage |
| TC-RS-008-02 | Quest results in index | 1. Create quest result for child<br>2. Navigate to results index | Quest section shows quest title, score, percentage |
| TC-RS-009-01 | Index activity log | 1. Navigate to results index<br>2. Check sys_activity_logs | "Viewed results" entry with child details |
| TC-RS-009-02 | Show activity log | 1. View exam detail<br>2. Check sys_activity_logs | "Viewed exam result details" entry with exam_id |
| TC-RS-009-03 | Report card download activity log | 1. Download report card PDF<br>2. Check sys_activity_logs | "Downloaded report card PDF" entry |

---

## 8. Known Issues

| # | Issue | Severity | Status | Notes |
|---|-------|----------|--------|-------|
| 1 | ParentChildPolicy MISSING | P0 | ⬜ Open | No formal policy — relies on `resolveChild()` |
| 2 | No class-average comparison in show view | P1 | ⬜ Open | FRD promises class avg but controller does not compute it |
| 3 | Report card DomPDF template unverified | P1 | ⬜ Open | Delegates to HPC controller — template may use incorrect paths |
| 4 | Quiz/quest results duplicated with Learning Hub | P2 | ◌ Known | Separate features but same data sources |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Middleware |
|--------|-----|------|-------------------|------------|
| GET | `/parent-portal/results` | `parent-portal.results.index` | ParentResultController@index | web, auth, tenant, verified, ParentPortalMiddleware |
| GET | `/parent-portal/results/{exam}` | `parent-portal.results.show` | ParentResultController@show | web, auth, tenant, verified, ParentPortalMiddleware |
| GET | `/parent-portal/results/report-card/pdf` | `parent-portal.results.report-card.pdf` | ParentResultController@reportCardPdf | web, auth, tenant, verified, ParentPortalMiddleware |

---

## 10. Execution Status

| TC ID | Test Case | Status (⬜/🟨/🟩/🟥) | Tester | Date | Remarks |
|-------|-----------|----------------------|--------|------|---------|
| TC-RS-001-01 | Results index loads all 4 sections | ⬜ | — | — | — |
| TC-RS-001-02 | Unpublished results excluded | ⬜ | — | — | — |
| TC-RS-002-01 | Exam detail — subject-wise breakdown | ⬜ | — | — | — |
| TC-RS-002-02 | Exam detail — aggregates computed | ⬜ | — | — | — |
| TC-RS-003-01 | Exam with no published results | ⬜ | — | — | — |
| TC-RS-004-01 | Wrong child exam access | ⬜ | — | — | — |
| TC-RS-005-01 | Download report card — published | ⬜ | — | — | — |
| TC-RS-005-02 | Download report card — override valid student | ⬜ | — | — | — |
| TC-RS-006-01 | Download report card — not published | ⬜ | — | — | — |
| TC-RS-006-02 | Warning message contains child name | ⬜ | — | — | — |
| TC-RS-007-01 | Overall FAIL when any paper fails | ⬜ | — | — | — |
| TC-RS-007-02 | Overall ABSENT when any paper absent | ⬜ | — | — | — |
| TC-RS-007-03 | Overall PASS when all pass | ⬜ | — | — | — |
| TC-RS-008-01 | Quiz results in index | ⬜ | — | — | — |
| TC-RS-008-02 | Quest results in index | ⬜ | — | — | — |
| TC-RS-009-01 | Index activity log | ⬜ | — | — | — |
| TC-RS-009-02 | Show activity log | ⬜ | — | — | — |
| TC-RS-009-03 | Report card download activity log | ⬜ | — | — | — |

---

*End of ppt_Results_TcList.md*
