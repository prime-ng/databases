# ppt_LearningHub_TcList

## Module: ParentPortal → Learning → My Learning Hub (Read-Only, P2)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | ParentPortal |
| Tab Group | Learning |
| Feature | My Learning Hub (Read-Only Aggregated Overview) |
| URL(s) | `GET /parent-portal/learning` (route: `parent-portal.learning.index`) |
| Controller | `Modules\ParentPortal\Http\Controllers\ParentLearningController` |
| Model(s) | `Modules\LmsQuiz\Models\QuizAllocation`, `Modules\LmsQuests\Models\QuestAllocation`, `Modules\LmsExam\Models\ExamAllocation` |
| FormRequest | None (read-only) |
| Policy / Permissions | No explicit policy — scoped via `ParentContextService::resolveChild()` |
| Soft Deletes | Yes — check `deleted_at IS NULL` on attempt queries |
| Activity Log | `activityLog()` in `index()` with action "Viewed" |
| View(s) | `parentportal::learning.index` |

---

## 2. Pre-conditions

- Parent must be authenticated and logged into a tenant (school)
- Parent must have at least one linked child with `can_access_parent_portal = 1`
- Child must have a current academic session with a class and section assigned
- Tenant must have at least one of: `LmsQuiz`, `LmsQuests`, or `LmsExam` modules active
- At least one published allocation should exist for the child's class/section/student ID
- Dusk environment: `DUSK_TENANT_URL`, `DUSK_GUARDIAN_EMAIL`, `DUSK_GUARDIAN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `ParentLearningController@index()`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Quiz Allocations | `QuizAllocation` | `->published()->where('is_active', true)->where(cut_off_date null or future)->where(allocation_type CLASS/SECTION/STUDENT)->with(quiz->subject)` | Published, active, within cut-off, matching allocation | None |
| Quests Allocations | `QuestAllocation` | Same structure as quizzes but with `QuestAllocation` and `quest` relation | Published, active, within cut-off | None |
| Online Exam Allocations | `ExamAllocation` | `->where('is_active', true)->where(allocation_type CLASS/SECTION/STUDENT)->with(examPaper.exam, examPaper.subject, attempt)` | Active, matching allocation | None |
| Quiz attempts | `DB::table('lms_quiz_quest_attempts')` | WHERE assessment_type='QUIZ' AND student_id=? ORDER BY attempt_number DESC | Per allocation | None |
| Quest attempts | `DB::table('lms_quiz_quest_attempts')` | WHERE assessment_type='QUEST' AND student_id=? ORDER BY attempt_number DESC | Per allocation | None |

---

## 4. Test Data Strategy

- Create published quiz/quest/exam allocations for the test child's class, section, and student ID
- Create at least one attempt record per assessment type with varying statuses
- Create allocations beyond cut-off date (should be excluded)
- Create allocations with no linked quiz/quest/exam (should be filtered out)
- Test with child who has no current session (no class/section — empty collections)
- Test with no allocations at all (empty state)
- Pre-test cleanup: Deactivate test allocations after execution

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_quiz_quest_attempts` (Read-Only)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-03 | assessment_type | ENUM(QUIZ,QUEST) | NOT NULL |
| BC-DB-04 | assessment_id | INT UNSIGNED | NOT NULL |
| BC-DB-05 | attempt_number | INT | NOT NULL |
| BC-DB-06 | status | VARCHAR(50) | NOT NULL |
| BC-DB-07 | score_obtained | DECIMAL(8,2) | NULL |
| BC-DB-08 | max_score | DECIMAL(8,2) | NULL |
| BC-DB-09 | percentage | DECIMAL(5,2) | NULL |
| BC-DB-10 | is_passed | TINYINT(1) | NULL |
| BC-DB-11 | submitted_at | DATETIME | NULL |
| BC-DB-12 | deleted_at | TIMESTAMP | NULL |

### 5.2 Authorization

| BC ID | Rule | Expected Behavior |
|-------|------|-------------------|
| BC-AUTH-01 | Guest access | Redirect to login |
| BC-AUTH-02 | No linked children | `resolveChild()` throws/redirects |
| BC-AUTH-03 | Child without class/session | All three collections empty — graceful empty state |
| BC-AUTH-04 | Unpublished allocation excluded | Only `published()` scope items shown |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default tab is 'quizzes' | Quizzes tab active on first load |
| BC-BIZ-02 | Tab query parameter respected | `?tab=quests` shows quests tab |
| BC-BIZ-03 | Cut-off date in future | Allocation included |
| BC-BIZ-04 | Cut-off date passed | Allocation excluded |
| BC-BIZ-05 | Null cut-off date | Allocation always included |
| BC-BIZ-06 | Allocation type: CLASS | Matches class_id only |
| BC-BIZ-07 | Allocation type: SECTION | Matches class_id + section_id |
| BC-BIZ-08 | Allocation type: STUDENT | Matches student's user_id |
| BC-BIZ-09 | Orphaned allocation (quiz/quest null) | Filtered out |
| BC-BIZ-10 | Attempt count tracked per allocation | `$allocation->attempts_used` reflects actual attempts |
| BC-BIZ-11 | Last attempt data attached | `$allocation->last_attempt` has latest attempt details |
| BC-BIZ-12 | Activity logging | "Viewed learning activities" entry in audit log |
| BC-BIZ-13 | Count badges shown | 3 badges: quiz count, quest count, exam count |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | quiz_id | lms_quizzes | CASCADE |
| BC-REF-02 | quest_id | lms_quests | CASCADE |
| BC-REF-03 | exam_paper_id | lms_exam_papers | CASCADE |

---

## 6. Test Scenarios

| TC ID | Scenario | Description | Priority |
|-------|----------|-------------|----------|
| TC-LH-001 | Learning hub loads with quizzes default tab | Quizzes tab active, all 3 sections present | P2 |
| TC-LH-002 | Quiz allocations with attempts tracked | Attempt count and last attempt data correctly shown | P2 |
| TC-LH-003 | Quest allocations with attempts | Quest section loads with attempt data | P2 |
| TC-LH-004 | Online exam allocations | Exam section loads with status | P2 |
| TC-LH-005 | Cut-off date filtering | Past cut-off allocations excluded | P2 |
| TC-LH-006 | Child with no class/session | Empty collections gracefully rendered | P2 |
| TC-LH-007 | No allocations at all | Empty state for all 3 tabs | P2 |
| TC-LH-008 | Tab switching via query parameter | `?tab=exams` shows exams tab | P2 |
| TC-LH-009 | Activity logging | Audit log entry created | P2 |

---

## 7. Test Cases

| TC ID | Test Case | Steps | Expected Result |
|-------|-----------|-------|-----------------|
| TC-LH-001-01 | Learning hub loads with 3 tabs | 1. Create quiz, quest, and exam allocations<br>2. Navigate to `/parent-portal/learning`<br>3. Observe tabs | 3 tabs visible (Quizzes, Quests, Exams) with correct counts |
| TC-LH-001-02 | Default tab is quizzes | 1. Navigate to `/parent-portal/learning`<br>2. Observe active tab | "Quizzes" tab is active by default |
| TC-LH-002-01 | Quiz attempt count correct | 1. Create quiz allocation, 2 attempts<br>2. Navigate to learning hub<br>3. Check quiz section | Attempt count shows 2; last attempt shows latest score |
| TC-LH-002-02 | Quiz not attempted | 1. Create quiz allocation, 0 attempts<br>2. Check quiz section | Shows "Not Attempted" with no score |
| TC-LH-003-01 | Quest allocations listed | 1. Create quest allocation, 1 attempt<br>2. Navigate to quests tab | Quest listed with title, subject, score |
| TC-LH-004-01 | Online exams listed | 1. Create exam allocation<br>2. Navigate to exams tab | Exam listed with paper title, subject, attempt status |
| TC-LH-005-01 | Cut-off date in future | 1. Create allocation with cut_off_date = +7 days<br>2. Navigate to hub | Allocation visible |
| TC-LH-005-02 | Cut-off date in past | 1. Create allocation with cut_off_date = -1 day<br>2. Navigate to hub | Allocation not visible |
| TC-LH-005-03 | Null cut-off date always visible | 1. Create allocation with cut_off_date = null<br>2. Navigate to hub | Allocation visible |
| TC-LH-006-01 | Child without session | 1. Create child with no current session<br>2. Switch to this child<br>3. Navigate to learning hub | All 3 sections show empty state, no errors |
| TC-LH-007-01 | No allocations at all | 1. No quiz/quest/exam allocations exist for child<br>2. Navigate to learning hub | Each tab shows "No items" empty state |
| TC-LH-008-01 | Tab query parameter works | 1. Navigate to `/parent-portal/learning?tab=exams`<br>2. Observe active tab | "Online Exams" tab is selected |
| TC-LH-009-01 | Activity log entry | 1. Navigate to learning hub<br>2. Check sys_activity_logs | "Viewed learning activities" entry with child details |

---

## 8. Known Issues

| # | Issue | Severity | Status | Notes |
|---|-------|----------|--------|-------|
| 1 | P2 Priority — not in scope for initial release | P2 | ⬜ Open | Feature may not be QA tested |
| 2 | No drill-down to individual quiz/quest detail | P2 | ◌ Known | Summary-only view by design |
| 3 | No caching — 6+ DB queries per page load | P2 | ⬜ Open | Acceptable for low-volume P2 feature |
| 4 | No search/filter/sort controls | P2 | ◌ Known | Not required for P2 |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Middleware |
|--------|-----|------|-------------------|------------|
| GET | `/parent-portal/learning` | `parent-portal.learning.index` | ParentLearningController@index | web, auth, tenant, verified, ParentPortalMiddleware |

---

## 10. Execution Status

| TC ID | Test Case | Status (⬜/🟨/🟩/🟥) | Tester | Date | Remarks |
|-------|-----------|----------------------|--------|------|---------|
| TC-LH-001-01 | Learning hub loads with 3 tabs | ⬜ | — | — | — |
| TC-LH-001-02 | Default tab is quizzes | ⬜ | — | — | — |
| TC-LH-002-01 | Quiz attempt count correct | ⬜ | — | — | — |
| TC-LH-002-02 | Quiz not attempted | ⬜ | — | — | — |
| TC-LH-003-01 | Quest allocations listed | ⬜ | — | — | — |
| TC-LH-004-01 | Online exams listed | ⬜ | — | — | — |
| TC-LH-005-01 | Cut-off date in future | ⬜ | — | — | — |
| TC-LH-005-02 | Cut-off date in past | ⬜ | — | — | — |
| TC-LH-005-03 | Null cut-off date always visible | ⬜ | — | — | — |
| TC-LH-006-01 | Child without session | ⬜ | — | — | — |
| TC-LH-007-01 | No allocations at all | ⬜ | — | — | — |
| TC-LH-008-01 | Tab query parameter works | ⬜ | — | — | — |
| TC-LH-009-01 | Activity log entry | ⬜ | — | — | — |

---

*End of ppt_LearningHub_TcList.md*
