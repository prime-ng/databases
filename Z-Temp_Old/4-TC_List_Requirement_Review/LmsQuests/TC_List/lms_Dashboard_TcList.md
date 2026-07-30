# lms_Dashboard_TcList

## Module: LmsQuests → Quest Management → Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuests |
| Tab Group | Quest Management (Tabbed Interface) |
| Features | Dashboard KPIs, Charts, Global Filters (REQ-QST-009, RPT-QST-001) |
| URL | `/lms-quests/quest` (index — default tab) |
| Controller | `Modules\LmsQuests\Http\Controllers\LmsQuestController` |
| Model(s) | `Quest`, `QuestQuestion`, `QuestAllocation`, `QuizQuestAttempt`, `QuizQuestResult` |
| Validation | Inline in `index()` — request parameter validation |
| Permission Gates | `tenant.quest.viewAny` (dashboard view) |
| Soft Deletes | N/A (read-intensive) |

---

## 2. Pre-conditions

- Required permissions: `tenant.quest.viewAny`
- At least one active Quest must exist (`is_active=1`) with questions and allocations
- At least one student must be allocated and have submitted an attempt
- At least one `QuizQuestResult` record must exist with `assessment_type='QUEST'`
- Master data: `sch_classes`, `sch_class_sections`, `sch_subjects` must be populated

---

## 3. Default Data Load

When page loads (GET `/lms-quests/quest`) with `active_tab=dashboard` (default):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Total Quests | `Quest::count()` | With class/subject filters | None |
| Total Questions | `QuestQuestion::count()` | Via quest relationship, with filters | None |
| Total Allocations | `QuestAllocation::count()` | With class/subject/date/SECTION-OR filters | None |
| Total Submissions | `QuizQuestAttempt::count()` | Status=SUBMITTED/TIMEOUT, assessment_type=QUEST, with filters | None |
| Total Checked | `QuizQuestResult::count()` | assessment_type=QUEST, with filters | None |
| Avg Score | `QuizQuestResult::avg('percentage')` | assessment_type=QUEST, with filters | None |
| Status Breakdown | `Quest::groupBy('status')` | DRAFT/PUBLISHED/ARCHIVED, with class filter | None |
| Monthly Activity | `Quest::groupBy month` | Last 6 months quest creation | None |
| Monthly Allocations | `QuestAllocation::groupBy month` | Last 6 months allocation creation | None |
| Score Distribution | `QuizQuestResult::percentage` | 5 bins (0–20, 21–40, 41–60, 61–80, 81–100) | None |
| Subject Breakdown | `Quest::groupBy subject_id` | Top 6 by quest count, with subject relation | None |
| Class Breakdown | `Quest::groupBy class_id` | Top 6 by quest count, with class relation | None |
| Recent Quests | `Quest::latest()` | Last 8, with withCount (questions/alloc/attempts/results) | None |
| Global Filters | Class/Section, Subject, Date Range | Populated from request | N/A |
| Subject List (AJAX-ready) | `Subject::where('is_active',1)` | Filtered by class_section_id if provided | None |

---

## 4. Test Data Strategy

- **Unique Suffix**: Use `now()->format('His') . random_int(100, 999)` for test data uniqueness
- **Dashboard Tests**: Require mixed data across multiple quests, allocations, attempts, and results to verify aggregation correctness
- **Global Filters**: Apply to ALL KPI metrics; class breakdown is exception (ignores class/subject filters)
- **Score Distribution Bins**: 0–20, 21–40, 41–60, 61–80, 81–100
- **Monthly Activity**: Always shows last 6 months (current + 5 previous), zero-filled

---

## 5. Database Schema (BC-DB)

### BC-DB-01: `lms_quests`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| uuid | BINARY(16) | UNIQUE, NOT NULL | |
| academic_session_id | INT UNSIGNED | FK → glb_academic_sessions.id, NOT NULL | |
| class_id | INT UNSIGNED | FK → sch_classes.id, NOT NULL | |
| subject_id | INT UNSIGNED | FK → sch_subjects.id, NOT NULL | |
| quest_type_id | INT UNSIGNED | FK → lms_assessment_types.id, NOT NULL | |
| quest_code | VARCHAR(50) | UNIQUE, NOT NULL | Auto-generated |
| title | VARCHAR(255) | NOT NULL | |
| description | TEXT | DEFAULT NULL | |
| instructions | TEXT | DEFAULT NULL | |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'DRAFT' | DRAFT/PUBLISHED/ARCHIVED |
| duration_minutes | INT UNSIGNED | DEFAULT NULL | |
| total_marks | DECIMAL(8,2) | NOT NULL, DEFAULT 0.00 | |
| total_questions | INT UNSIGNED | NOT NULL, DEFAULT 0 | |
| passing_percentage | DECIMAL(5,2) | NOT NULL, DEFAULT 33.00 | |
| allow_multiple_attempts | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| max_attempts | TINYINT UNSIGNED | NOT NULL, DEFAULT 1 | |
| negative_marks | DECIMAL(4,2) | NOT NULL, DEFAULT 0.00 | |
| is_randomized | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| question_marks_shown | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| auto_publish_result | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| timer_enforced | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| show_correct_answer | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| show_explanation | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| difficulty_config_id | INT UNSIGNED | FK → lms_difficulty_distribution_configs.id, DEFAULT NULL | |
| ignore_difficulty_config | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| is_system_generated | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| only_unused_questions | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| only_authorised_questions | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| created_by | INT UNSIGNED | FK → sys_users.id, DEFAULT NULL | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | TIMESTAMP | NULL DEFAULT NULL | Soft delete |

### BC-DB-02: `lms_quest_allocations`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| quest_id | INT UNSIGNED | FK → lms_quests.id, NOT NULL | |
| allocation_type | ENUM('CLASS','SECTION','GROUP','STUDENT') | NOT NULL | |
| target_table_name | VARCHAR(60) | NOT NULL | e.g. sch_classes, sch_sections |
| target_id | INT UNSIGNED | NOT NULL | Polymorphic target ID |
| assigned_by | INT UNSIGNED | FK → sys_users.id, DEFAULT NULL | |
| published_at | DATETIME | DEFAULT NULL | |
| due_date | DATETIME | DEFAULT NULL | |
| cut_off_date | DATETIME | DEFAULT NULL | |
| is_auto_publish_result | TINYINT(1) | NOT NULL, DEFAULT 0 | |
| result_publish_date | DATETIME | DEFAULT NULL | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | TIMESTAMP | NULL DEFAULT NULL | Soft delete |

### BC-DB-03: `lms_quest_questions`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| quest_id | INT UNSIGNED | FK → lms_quests.id, NOT NULL | |
| question_id | INT UNSIGNED | FK → qns_questions_bank.id, NOT NULL | |
| ordinal | INT UNSIGNED | NOT NULL, DEFAULT 0 | |
| marks_override | DECIMAL(5,2) | DEFAULT NULL | |
| is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | |
| deleted_at | TIMESTAMP | NULL DEFAULT NULL | Soft delete |

### BC-DB-04: `sp_quiz_quest_attempts` (StudentPortal)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | BIGINT(20) UNSIGNED | PK | |
| quest_id | BIGINT(20) UNSIGNED | | |
| student_id | BIGINT(20) UNSIGNED | | |
| assessment_type | VARCHAR(20) | | 'QUEST' |
| status | VARCHAR(20) | | IN_PROGRESS/SUBMITTED/EVALUATED/RESULT_PUBLISHED/TIMEOUT |
| score_obtained | DECIMAL(8,2) | | |
| max_score | DECIMAL(8,2) | | |
| percentage | DECIMAL(5,2) | | |
| is_passed | TINYINT(1) | | |
| submitted_at | TIMESTAMP | | |
| is_active | TINYINT(1) | | |

### BC-DB-05: `sp_quiz_quest_results` (StudentPortal)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | BIGINT(20) UNSIGNED | PK | |
| attempt_id | BIGINT(20) UNSIGNED | FK | |
| assessment_type | VARCHAR(20) | | 'QUEST' |
| assessment_id | BIGINT(20) UNSIGNED | | quest_id |
| student_id | BIGINT(20) UNSIGNED | | |
| total_marks_obtained | DECIMAL(8,2) | | |
| max_marks | DECIMAL(8,2) | | |
| percentage | DECIMAL(5,2) | | |
| grade_obtained | VARCHAR(5) | | A1/A2/B1/B2/C1/C2/D/E |
| is_passed | TINYINT(1) | | |
| is_published | TINYINT(1) | | |
| published_at | TIMESTAMP | | |
| teacher_remarks | TEXT | | |
| created_by | BIGINT(20) UNSIGNED | | |

---

## 6. Validation Rules (BC-VAL)

| BC ID | Rule | Description |
|-------|------|-------------|
| BC-VAL-01 | No direct validation — filters validated at controller level | Dashboard is read-only (no form request). All input validation is inline in `index()` via request parameter checks. `class_section_id` and `subject_id` passed as optional query params; `date_from`/`date_to` parsed via `Carbon::parse`. |

---

## 7. Authorization (BC-AUTH)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.quest.viewAny | index() (dashboard tab) | Without → 403 |

---

## 8. Business Logic (BC-BIZ)

### 8.1 Dashboard Metrics

| BC ID | Rule | Description |
|-------|------|-------------|
| BC-BIZ-01 | Global Filters Apply to All KPIs | class_section_id filters by class_id on quest; subject_id filters by subject_id; date range filters by published_at/created_at/submitted_at per entity |
| BC-BIZ-02 | SECTION Filter OR Resolution | class_section_id filter matches SECTION→target_id, CLASS→class_id, STUDENT→students in section — three OR conditions |
| BC-BIZ-03 | Monthly Activity = Last 6 Months | Always shows current month + 5 previous; empty months = 0 |
| BC-BIZ-04 | Score Distribution = 5 Bins | 0–20, 21–40, 41–60, 61–80, 81–100; inclusive upper boundary for each bin |
| BC-BIZ-05 | Subject Breakdown = Top 6 | Ordered by quest_count DESC, limited to 6 |
| BC-BIZ-06 | Class Breakdown = Top 6 | Ordered by quest_count DESC, limited to 6; only date range filter applies (no class/subject) |
| BC-BIZ-07 | Recent Quests = Last 8 | Ordered by latest created_at, limited to 8 |
| BC-BIZ-08 | Status Breakdown = Three Counts | DRAFT, PUBLISHED, ARCHIVED — only class_section_id filter applies |
| BC-BIZ-09 | total_checked = QuizQuestResult Count | assessment_type='QUEST'; NOT the same as total_evaluated (which adds assessment_id>0) |
| BC-BIZ-10 | total_submissions = SUBMITTED/TIMEOUT | Only SUBMITTED and TIMEOUT status; NOT IN_PROGRESS or EVALUATED |
| BC-BIZ-11 | avg_score rounds to 1 decimal | Uses `round($avg ?? 0, 1)` |
| BC-BIZ-12 | Class Breakdown ignores class/subject filters | Only date range filter applies; class_id/subject_id filters NOT applied to class_breakdown |

### 8.2 Shared Filter Conditions

| BC ID | Rule | Description |
|-------|------|-------------|
| BC-BIZ-13 | Class Section → Subject AJAX | `getSubjectsByClass` resolves section→class→SubjectGroup→subjects |
| BC-BIZ-14 | Subject List Filtered by Class Section | `Subject::whereHas('subjectGroups', fn=>where('class_id', $cs->class_id))` |
| BC-BIZ-15 | Date Range = startOfDay to endOfDay | Both date_from and date_to required; parsed via `Carbon::parse` |
| BC-BIZ-16 | Global Filters Persist Across Tabs | Filters stored in request, applied to all tabs in single index() call |

---

## 9. Referential Integrity (BC-REF)

| BC ID | Constraint Name | Child Table | Child Column | Parent Table | Parent Column | On Delete |
|-------|----------------|-------------|--------------|--------------|---------------|-----------|
| BC-REF-01 | fk_quest_academic_session | lms_quests | academic_session_id | glb_academic_sessions | id | CASCADE |
| BC-REF-02 | fk_quest_class | lms_quests | class_id | sch_classes | id | CASCADE |
| BC-REF-03 | fk_quest_subject | lms_quests | subject_id | sch_subjects | id | CASCADE |
| BC-REF-04 | fk_quest_type | lms_quests | quest_type_id | lms_assessment_types | id | CASCADE |
| BC-REF-05 | fk_quest_diff | lms_quests | difficulty_config_id | lms_difficulty_distribution_configs | id | SET NULL |
| BC-REF-06 | fk_quest_creator | lms_quests | created_by | sys_users | id | SET NULL |
| BC-REF-07 | fk_qst_q_quest | lms_quest_questions | quest_id | lms_quests | id | CASCADE |
| BC-REF-08 | fk_qst_q_question | lms_quest_questions | question_id | qns_questions_bank | id | CASCADE |
| BC-REF-09 | fk_qsta_quest | lms_quest_allocations | quest_id | lms_quests | id | CASCADE |
| BC-REF-10 | fk_qsta_assigner | lms_quest_allocations | assigned_by | sys_users | id | SET NULL |

---

## 10. Test Case Summary

### Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-DSH-P01 | Dashboard loads with all KPI metrics and charts | All 6 KPI cards, 4 charts, and recent quests grid render correctly | | | |
| TC-DSH-P02 | Dashboard global filter — Class/Section filter applied | KPIs filtered to selected class only | | | |
| TC-DSH-P03 | Dashboard global filter — Subject filter applied | KPIs filtered to selected subject only | | | |
| TC-DSH-P04 | Dashboard global filter — Date range filter applied | Allocations/submissions/checked filtered by date range; quests count unaffected | | | |
| TC-DSH-P05 | Dashboard SECTION filter uses OR conditions | Allocations matched by SECTION, CLASS, and STUDENT types all included | | | |
| TC-DSH-P06 | Recent Quests grid shows submission and evaluation rates | Per-row submission/evaluation percentages calculated correctly | | | |
| TC-DSH-P07 | Chart renders — Monthly activity with both quest and allocation trends | 6-month span, correct aggregation, zero-filled empty months | | | |
| TC-DSH-P08 | Subject breakdown includes aggregated stats | quest_count, total_q_sum, avg_marks per subject | | | |

### Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-DSH-N01 | Dashboard — No data state (empty DB) | All KPIs = 0, charts show empty/zero data, no errors | | | |
| TC-DSH-N02 | Dashboard — Invalid class_section_id | Graceful handling, no error | | | |
| TC-DSH-N03 | Dashboard — Invalid subject_id | All metrics show 0 or no results | | | |

### Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | index() — Dashboard stats filters applied correctly | All 7 queries verified for correct filter application | | | |
| TC-CR02 | index() — SECTION filter OR resolution in allocations | SECTION + CLASS types matched; STUDENT excluded from total_allocations | | | |
| TC-CR03 | index() — Monthly activity queries are last 6 months | 6-month window, GROUP BY, zero-initialized months | | | |
| TC-CR04 | index() — Score distribution calculation | 5 bins with inclusive upper boundaries, all results fetched | | | |
| TC-CR05 | index() — Recent Quests withCount relationships | with + withCount includes class, subject, questions, alloc, attempts, results | | | |
| TC-CR16 | getSubjectsByClass() — AJAX subject filtering | ClassSection resolution → SubjectGroup → deduped sorted subjects | | | |
| TC-CR17 | calculateGrade() — Grade letter boundaries | All 8 grade boundaries correct (91→A1, 81→A2, ..., else→E) | | | |
| TC-CR20 | index() — Class breakdown filter gap | Only date_from/date_to applied; class_section_id and subject_id intentionally skipped | | | |
| TC-CR21 | Blade @can Directives — Permission-based visibility for dashboard | All 7 tab includes wrapped in @can gates; Dashboard tab uses tenant.quest.viewAny | | | |
| TC-CR22 | Breadcrumb Config — Route registered in config/breadcrumb.php | lms-quests, quest, quest-scope, quest-question, quest-allocation entries present | | | |
| TC-CR23 | View — isset()/null-safe Checks for Relationship Variables | All `->name ?? '—'` and `?? 0` guards present for nullable relations | | | |
| TC-CR24 | View — Success Flash Messages | Store/update/trash/restore/forceDelete actions return with('success', ...) | | | |

### Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|-----------------|---------|---------|--------|
| TC-D01 | Dashboard metrics consistency — total_submissions vs total_checked | total_submissions counts SUBMITTED+TIMEOUT; total_checked counts QuizQuestResult | | | |
| TC-D03 | Summary assigned_count vs Performance Report totalStudents | Both counts match via same resolution logic | | | |

---

## 11. Test Case Steps

### 11.1 Positive TC Steps

#### TC-DSH-P01: Dashboard loads with all KPI metrics and charts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 Quests (2 DRAFT, 2 PUBLISHED, 1 ARCHIVED) across 3 subjects and 2 classes | Quests exist |
| 2 | Add 10 questions to each quest | Questions exist |
| 3 | Create 8 allocations across the quests | Allocations exist |
| 4 | Create 6 QuizQuestAttempt records (assessment_type=QUEST): 4 SUBMITTED, 1 IN_PROGRESS, 1 TIMEOUT | Attempts exist |
| 5 | Create 3 QuizQuestResult records with varied percentages (15%, 55%, 92%) | Results exist |
| 6 | Navigate to Dashboard (GET `/lms-quests/quest` with active_tab=dashboard) | Page loads |
| 7 | Verify total_quests = 5 | KPI matches |
| 8 | Verify total_questions = 50 (5 × 10) | KPI matches |
| 9 | Verify total_allocations = 8 | KPI matches |
| 10 | Verify total_submissions = 5 (4 SUBMITTED + 1 TIMEOUT; IN_PROGRESS excluded) | KPI matches |
| 11 | Verify total_checked = 3 (3 QuizQuestResult records) | KPI matches |
| 12 | Verify avg_score = 54.0 (round((15+55+92)/3, 1)) | KPI matches |
| 13 | Verify status_breakdown: DRAFT=2, PUBLISHED=2, ARCHIVED=1 | Status counts match |
| 14 | Verify score_distribution: '0–20'=1, '21–40'=0, '41–60'=1, '61–80'=0, '81–100'=1 | Bins match |
| 15 | Verify subject_breakdown returns top 6 subjects by count, ordered DESC | Correct ordering |
| 16 | Verify class_breakdown returns top 6 classes by count, ordered DESC | Correct ordering |
| 17 | Verify monthly_activity has exactly 6 months (current + 5 previous) | Correct range |
| 18 | Verify recentQuests has at most 8 quests, ordered by latest created_at | Correct limit/order |

---

#### TC-DSH-P02: Dashboard global filter — Class/Section filter applied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 in Class C1, Q2 in Class C2, Q3 in Class C1 | Quests exist |
| 2 | Create allocations: A1→Q1(C1), A2→Q2(C2), A3→Q3(C1) | Allocations exist |
| 3 | Get class_section_id for C1 (any section of C1) | Section ID known |
| 4 | Load dashboard with `class_section_id=X` | Page loads |
| 5 | Verify total_quests = 2 (only Q1 and Q3 in C1) | Filter applied |
| 6 | Verify only C1 quests appear in recentQuests | Recent filtered |

---

#### TC-DSH-P03: Dashboard global filter — Subject filter applied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 in Subject S1, Q2 in Subject S2, Q3 in Subject S1 | Quests exist |
| 2 | Load dashboard with `subject_id=S1` | Page loads |
| 3 | Verify total_quests = 2 | Filter applied |
| 4 | Verify subject_breakdown shows only S1 data | Breakdown filtered |

---

#### TC-DSH-P04: Dashboard global filter — Date range filter applied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 created 10 days ago, Q2 created 5 days ago, Q3 created 1 day ago | Quests exist |
| 2 | Create allocation A1 for Q1 published 8 days ago | Allocation exists |
| 3 | Create attempt for Q1 submitted 8 days ago, Q2 submitted 3 days ago | Attempts exist |
| 4 | Create result for Q1 created 7 days ago | Result exists |
| 5 | Load dashboard with `date_from=6_days_ago&date_to=2_days_ago` | Page loads |
| 6 | Verify total_quests = 3 (date range NOT applied to total_quests count — only class/subject) | (Confirmed: date range not in quests count query) |
| 7 | Verify total_allocations filters by published_at between dates | Allocations filtered |
| 8 | Verify total_submissions filters by submitted_at between dates | Submissions filtered |
| 9 | Verify total_checked filters by created_at between dates | Checked filtered |

---

#### TC-DSH-P05: Dashboard SECTION filter uses OR conditions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Class C1 with Section SecA | Class+Section exist |
| 2 | Create Quest Q1 (class=C1) with 3 allocations: TYPE=SECTION→SecA, TYPE=CLASS→C1, TYPE=STUDENT→S1 | 3 allocations |
| 3 | Enroll Student S1 in SecA | Student in section |
| 4 | Load dashboard with `class_section_id=SecA` | Page loads |
| 5 | Verify SECTION-type allocation counted (target_id=SecA) | Included |
| 6 | Verify CLASS-type allocation counted (target_id=C1 which is SecA's class) | Included |
| 7 | Verify STUDENT-type allocation counted (S1 is enrolled in SecA) | Included |
| 8 | Verify allocations NOT matching any OR condition excluded | Excluded |

---

#### TC-DSH-P06: Recent Quests grid shows submission and evaluation rates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 with 2 allocations, 3 submitted attempts, 1 evaluated result | Q1 has data |
| 2 | Load dashboard | Recent quests loads |
| 3 | Verify each recent quest row shows: questions_count, total_alloc, total_submitted, total_evaluated | Counts displayed |
| 4 | Verify submission rate = (total_submitted / total_alloc) × 100 | Percentage calculated |
| 5 | Verify evaluation rate = (total_evaluated / total_submitted) × 100 | Percentage calculated |

---

#### TC-DSH-P07: Chart renders — Monthly activity with both quest and allocation trends

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create quests across 3 different months | Quests in M1, M2, M3 |
| 2 | Create allocations in 2 different months | Allocations in M2, M3 |
| 3 | Load dashboard | Page loads |
| 4 | Verify months array has 6 entries | 6-month span |
| 5 | Verify quest counts per month match DB | Correct aggregation |
| 6 | Verify allocation counts per month match DB | Correct aggregation |
| 7 | Verify empty months show count=0 | Zero-filled |

---

#### TC-DSH-P08: Subject breakdown includes aggregated stats

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Quest Q1 (Subject=Math, total_questions=10, total_marks=100), Q2 (Subject=Math, total_questions=15, total_marks=150), Q3 (Subject=Science, total_questions=8, total_marks=80) | Quests exist |
| 2 | Load dashboard | Subject breakdown loads |
| 3 | Verify Math row: quest_count=2, total_q_sum=25, avg_marks=125.0 | Aggregation correct |
| 4 | Verify Science row: quest_count=1, total_q_sum=8, avg_marks=80.0 | Aggregation correct |
| 5 | Verify top 6 subjects returned with subject relation loaded | Subject name/ID present |

---

### 11.2 Negative TC Steps

#### TC-DSH-N01: Dashboard — No data state (empty DB)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no Quests, allocations, attempts, or results exist | Empty DB |
| 2 | Load Dashboard | Page loads without error |
| 3 | Verify total_quests = 0 | Zero state |
| 4 | Verify avg_score = 0.0 | Zero average |
| 5 | Verify status_breakdown all 0 | Zero breakdown |
| 6 | Verify score_distribution all bins = 0 | Zero bins |
| 7 | Verify monthly_activity all 6 months = 0 | Zero activity |
| 8 | Verify recentQuests empty | Empty list |

---

#### TC-DSH-N02: Dashboard — Invalid class_section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard with `class_section_id=99999` | Page loads |
| 2 | Verify no error (ClassSection::find returns null, gracefully skipped) | Graceful handling |

---

#### TC-DSH-N03: Dashboard — Invalid subject_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load Dashboard with `subject_id=99999` | Page loads |
| 2 | Verify all metrics show 0 or no results (subject filter excludes all quests) | Graceful handling |

---

### 11.3 Code Review TC Steps

#### TC-CR01: index() — Dashboard stats filters applied correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review total_quests query | Applies class_id filter (via class_section_id→class), subject_id filter; NO date range |
| 2 | Review total_questions query | Applies class_id and subject_id via quest relationship |
| 3 | Review total_allocations query | Applies SECTION/CLASS OR resolution for class_section_id, subject_id via quest, date range on published_at |
| 4 | Review total_submissions query | Status IN ('SUBMITTED','TIMEOUT'); filters via quest class_id/subject_id; date range on submitted_at |
| 5 | Review total_checked query | QuizQuestResult count, assessment_type='QUEST'; filters via quest class_id/subject_id; date range on created_at |
| 6 | Review avg_score query | Same as total_checked but avg('percentage') with round(,1) |
| 7 | Review status_breakdown | Three separate queries grouped by status; only class_section_id filter applied |

---

#### TC-CR02: index() — SECTION filter OR resolution in allocations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review total_allocations SECTION filter | `where(allocation_type='SECTION', target_id=cs->id) OR (allocation_type='CLASS', target_id=cs->class_id)` |
| 2 | Verify STUDENT type NOT included in total_allocations SECTION filter | Only SECTION and CLASS types matched for allocation count |

---

#### TC-CR03: index() — Monthly activity queries are last 6 months

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review monthly_activity closure | Iterates $i=5..0, keys by 'M Y' format, initializes all to 0 |
| 2 | Verify created_at condition: `>= now()->subMonths(5)->startOfMonth()` | 6-month window |
| 3 | Verify GROUP BY and ORDER BY | DATE_FORMAT + MIN(created_at) ASC |
| 4 | Review monthly_allocations closure | Same pattern with QuestAllocation |

---

#### TC-CR04: index() — Score distribution calculation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review score_distribution closure | Initializes 5 bins: '0–20'=>0, '21–40'=>0, '41–60'=>0, '61–80'=>0, '81–100'=>0 |
| 2 | Verify bin assignment: `<=20`, `<=40`, `<=60`, `<=80`, else | Inclusive upper boundary |
| 3 | Verify filter application | class_section_id and subject_id via quest relationship |
| 4 | Verify all results fetched (no limit) | All QuizQuestResult records |

---

#### TC-CR05: index() — Recent Quests withCount relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review recentQuests query | `with(['class','subject'])` + `withCount(['questQuestions', 'allocations as total_alloc', 'attempts as total_submitted', 'results as total_evaluated'])` |
| 2 | Verify class_section_id filter | Filters by class_id |
| 3 | Verify subject_id filter | Filters by subject_id |
| 4 | Verify limit(8) and latest() | 8 most recent |

---

#### TC-CR16: getSubjectsByClass() — AJAX subject filtering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review class resolution | `ClassSection::find($request->class_section_id)` |
| 2 | Review SubjectGroup traversal | `SubjectGroup::where('class_id', $cs->class_id)->when(section_id, fn...)` |
| 3 | Review deduplication and sorting | `unique('id')`, `sortBy('name')` |
| 4 | Verify error response | `{'success': false, 'message': 'Class identification failed'}` when section not found |

---

#### TC-CR17: calculateGrade() — Grade letter boundaries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review boundary: ≥91 → A1 | 91→A1, 90.9→A2 |
| 2 | Review boundary: ≥81 → A2 | 81→A2, 80.9→B1 |
| 3 | Review boundary: ≥71 → B1 | |
| 4 | Review boundary: ≥61 → B2 | |
| 5 | Review boundary: ≥51 → C1 | |
| 6 | Review boundary: ≥41 → C2 | |
| 7 | Review boundary: ≥33 → D | 33→D, 32.9→E |
| 8 | Review else → E | <33 |

---

#### TC-CR20: index() — Class breakdown filter gap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review class_breakdown query | Only `date_from/date_to` filter applied; NO `class_section_id` or `subject_id` filter |
| 2 | Verify this is intentional | Class breakdown shows ALL classes regardless of current class/subject filter |

---

#### TC-CR21: Blade @can Directives — Permission-based visibility for dashboard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `tab_module/tab.blade.php` | View file loads |
| 2 | Verify Dashboard tab include is wrapped in `@can('tenant.quest.viewAny')` | Line 28: `@can('tenant.quest.viewAny')` before `@include('lmsquests::dashboard.index')` |
| 3 | Verify all 7 tab includes are wrapped in matching @can gates | Lines 28–54: dashboard, quest, quest_scope, quest_question, quest_allocation, quest_summary, activity_log |
| 4 | Verify nav-tab component passes permission per tab | `'permission' => 'tenant.quest.viewAny'` for dashboard tab in nav-tab config |
| 5 | Verify without `tenant.quest.viewAny` permission, dashboard is inaccessible | Gate::authorize() at `LmsQuestController.php:71` returns 403 |

---

#### TC-CR22: Breadcrumb Config — Route registered in config/breadcrumb.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/breadcrumb.php` | Config file loads |
| 2 | Verify `lms-quests` entry maps to `lms-quests/quest` | Line 159 |
| 3 | Verify `quest` entry maps to `lms-quests/quest` | Line 160 |
| 4 | Verify `quest-scope` entry maps to `lms-quests/quest` | Line 161 |
| 5 | Verify `quest-question` entry maps to `lms-quests/quest` | Line 162 |
| 6 | Verify `quest-allocation` entry maps to `lms-quests/quest` | Line 163 |

---

#### TC-CR23: View — isset()/null-safe Checks for Relationship Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `dashboard/index.blade.php` | View file loads |
| 2 | Verify `->name ?? '—'` pattern for subject, class nullable relationships | Lines 151, 181, 242, 243 |
| 3 | Verify `?? 0` fallback for numeric values (status_breakdown, total_q_sum, avg_marks) | Lines 60, 107, 153, 154, 195–198 |
| 4 | Verify `??` fallback for avg_score in donut center | Line 107: `$dashboardStats['avg_score'] ?? 0` |
| 5 | Verify `@forelse` / `@if->isEmpty()` guards for empty collections | Lines 135, 174, 236 |
| 6 | Verify `max(1, ...)` guard in division to prevent division-by-zero | Lines 249, 255 |

---

#### TC-CR24: View — Success Flash Messages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `index()` — after store action | `->with('success', flash('created.quest'))` at line 596 |
| 2 | Review `index()` — after update action | `->with('success', flash('updated.quest'))` at line 702 |
| 3 | Review `index()` — after destroy action | `->with('success', flash('trashed.quest'))` at line 730 |
| 4 | Review `index()` — after restore action | `->with('success', flash('restored.quest'))` at line 769 |
| 5 | Review `index()` — after forceDelete action | `->with('success', flash('force_deleted.quest'))` at line 803 |
| 6 | Verify `dashboard/index.blade.php` does NOT have a dedicated `@if(session('success'))` block | Flash messages rendered by parent layout (x-backend.layouts.app) |

---

### 11.4 Dependency TC Steps

#### TC-D01: Dashboard metrics consistency — total_submissions vs total_checked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 attempts: 3 SUBMITTED, 2 EVALUATED with QuizQuestResult | Data exists |
| 2 | Load Dashboard | Page loads |
| 3 | Verify total_submissions = 5 (SUBMITTED + TIMEOUT included; TIMEOUT=0; EVALUATED/RESULT_PUBLISHED excluded from KPI but included in total_submitted) | 5 |
| 4 | Verify total_checked = 2 (QuizQuestResult count) | 2 |
| 5 | Note: KPI total_submissions differs from recentQuests.total_submitted which includes SUBMITTED+TIMEOUT only | Behavioral difference documented |

---

#### TC-D03: Summary assigned_count vs Performance Report totalStudents

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocation A1 TYPE=CLASS→C1 (5 students). Quest Q1 has only A1 | Data exists |
| 2 | Load Summary: assigned_count for A1 = 5 | Summary shows 5 |
| 3 | Load Performance Report for Q1: totalStudents = 5 | Report shows 5 |
| 4 | Verify both counts match (same resolution logic) | Consistent |

---

## 12. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/lms-quests/quest` | lms-quests.quest.index | index() (dashboard tab) | tenant.quest.viewAny |
| GET | `/lms-quests/get-subjects-by-class` | lms-quests.getSubjectsByClass | getSubjectsByClass() | tenant.quest.viewAny |

---

## 13. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | `total_submissions` KPI and `recentQuests.total_submitted` use different status filters | **Medium** | KPI `total_submissions` counts only `SUBMITTED` status. `recentQuests.total_submitted` counts `SUBMITTED` and `TIMEOUT`. |
| KI-02 | Dashboard `total_submissions` vs `total_submitted` naming confusion | **Low** | Two very similar stats: `total_submissions` (only SUBMITTED) and `total_submitted` (SUBMITTED+TIMEOUT). |
| KI-03 | `total_evaluated` uses `assessment_id > 0` filter while `total_checked` does not | **Low** | Dashboard has both stats with unclear distinction. |
| KI-04 | Class breakdown ignores class_section_id and subject_id filters | **Low** | Class chart always shows ALL classes regardless of selected filters. |
| KI-05 | Subject list loads ALL active subjects when no class_section_id is set | **Low** | May cause incompatible class+subject selections. |

---

## 14. Feature Summary Matrix

| Feature | REQ ID | RPT ID | Controller Method(s) | Key Models | Pagination |
|---------|--------|--------|---------------------|------------|------------|
| Dashboard KPIs | REQ-QST-009 | RPT-QST-001 | index() | Quest, QuestQuestion, QuestAllocation, QuizQuestAttempt, QuizQuestResult | None |
| Dashboard Charts | REQ-QST-009 | RPT-QST-001 | index() | Quest, QuestAllocation, QuizQuestResult | None (top 6/8) |

(End of file - total lines)
