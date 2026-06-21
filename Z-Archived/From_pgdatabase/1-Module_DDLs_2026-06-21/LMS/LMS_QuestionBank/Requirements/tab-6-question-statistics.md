# Tab 6: Question Statistics

This tab shows how well each question performs when students answer it. The system tracks several metrics that help teachers understand whether a question is too easy, too hard, or just right — and whether it effectively separates students who know the material from those who do not.

Statistics are calculated automatically. Every night, the system looks at all questions that received new answers during the day and recalculates their numbers. Teachers can also trigger a recalculation for a specific question if they want to see the latest data immediately. However, statistics only become meaningful after at least 10 students have answered a question. Below that threshold, the system shows "Not enough data" and does not display the numbers.

---

## How Each Statistic Works

**Difficulty Index** tells you what percentage of students got the question right. If 65 out of 100 students answered correctly, the difficulty index is 0.65. A value between 0.51 and 0.75 is considered moderate — the ideal range. Below 0.25 means the question is very difficult, and above 0.85 means it is very easy. Teachers use this to spot questions that might be too hard for the class or too easy to be useful.

**Discrimination Index** measures how well the question separates strong students from weak ones. The system takes all students who attempted the question, sorts them by their total score on the assessment, and splits them into two groups — the top 27% (high performers) and the bottom 27% (low performers). It then compares how each group did on this specific question. If 80% of high performers got it right but only 30% of low performers got it right, the discrimination index is 0.50 — excellent.

A value above 0.40 is excellent. Between 0.30 and 0.39 is good. Between 0.20 and 0.29 is marginal and needs improvement. Below 0.20 is poor — the question does not tell strong and weak students apart. A negative value is a red flag: it means weak students somehow did better than strong students. This could mean the question is confusing, the correct answer is wrong, or the question tests something other than what was taught.

**Guessing Factor** estimates how likely students are to guess the correct answer by luck. For a multiple-choice question with four options, random guessing would give about 25% correct. If the actual correct rate is much higher than what random chance would predict, it might mean the wrong answers are too easy to eliminate — students can guess correctly without knowing the material. This helps teachers improve their distractor options.

**Time Analysis** shows how long students typically spend on the question. The system tracks average time, minimum time, and maximum time. If a student answered in under 5 seconds for a marks-bearing question, that is suspiciously fast and gets flagged. If the average time is much higher than what the teacher expected, the question might be too time-consuming.

**Option Analysis** is available for MCQ questions. It shows how many students chose each option, broken down by whether they were high performers or low performers. If a wrong answer (distractor) is selected by fewer than 5% of students, it is not doing its job — students can easily eliminate it. If a distractor is selected more by high performers than low performers, something is wrong — the smart students are being tricked by a plausible wrong answer. The teacher should review the question in that case.

---

## Important Business Rules

- Statistics accumulate across all assessments that use a question. If a question appears in three quizzes and one exam, all of those student attempts contribute to the same statistics. There is no way to see statistics for just one specific quiz — it is always the aggregate.
- Statistics do not reset when a question is edited. If a question had 1000 attempts with a difficulty index of 0.80, and then the teacher changes the question significantly, the statistics continue to include all 1000 old attempts. The new version's performance is mixed with the old version's data. This means teachers should be cautious about interpreting statistics for heavily edited questions.
- There is no way to reset statistics to zero. If a teacher wants a fresh start, they must clone the question — the clone starts with no statistics at all.
- A minimum of 10 student responses is required before any statistics are shown. Below this threshold, the system displays "Not enough data" for all metrics.
- The discrimination index uses the top 27% and bottom 27% for calculation. This is a standard psychometric practice and is not configurable.
- The time analysis flag for suspiciously fast answers uses a threshold of 5 seconds. This is a fixed threshold and is not configurable.
- Negative discrimination index values are flagged with a red indicator and a warning message suggesting the teacher review the question.
- Statistics are recalculated nightly for all questions that received new answers. Manual recalculation is available per question if the teacher needs real-time data.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|---|---|---|---|
| No data | Question created / cloned | No Statistics | qns_question_statistics has no record yet |
| No data | First 1-9 student attempts | Not Enough Data | System tracks attempts but does not display stats |
| Not Enough Data | 10th+ student attempt | Statistics Computed | Threshold crossed; metrics become visible |
| Statistics Available | Nightly cron job | Recalculated | Batch process for all questions with new attempts |
| Statistics Available | Teacher clicks "Recalculate" | Recalculated (single) | On-demand computation for one question |
| Question edited | Statistics preserved | Mixed Data | Old + new attempts combined |
| Question cloned | Clone created | No Statistics (clone) | Clone starts fresh; original stats unchanged |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Minimum responses | Must have >= 10 student responses | "Not enough data" (displayed for all metrics) |
| Difficulty Index range | 0.00 to 1.00 | Below 0.25 = Very Difficult, 0.25-0.50 = Difficult, 0.51-0.75 = Moderate, 0.76-0.85 = Easy, Above 0.85 = Very Easy |
| Discrimination Index | -1.00 to 1.00 | Above 0.40 = Excellent, 0.30-0.39 = Good, 0.20-0.29 = Marginal, Below 0.20 = Poor, Negative = Red flag |
| Negative discrimination | Automatically flagged | Red indicator with warning: "This question may need review. Weak students performed better than strong students." |
| Time analysis flag | Answer time < 5 seconds | Suspiciously fast answer flagged (but not blocked) |
| Distractor selection rate | < 5% selection | Distractor may be too easy to eliminate |
| High-performer distractor selection | Distractor chosen more by top 27% | Possible confusing or ambiguous question |
| Statistics after edit | Not reset | Old attempts remain in aggregate |
| Statistics reset | Not possible | "Clone this question to start fresh statistics." |
| Nightly recalculation | Automatic for questions with new attempts | All updated stats committed to qns_question_statistics |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Question Bank | qns_question_statistics | question_bank_id | Stores computed metrics per question |
| Question Bank | qns_questions_bank | id | Source question reference |
| Quiz Module | quz_*_responses | – | Student answer data consumed for computation |
| Exam Module | exm_*_responses | – | Student answer data consumed for computation |
| Background Jobs | Queue/Worker | – | Runs nightly statistic computation via QuestionStatisticsComputeJob |
| API | POST /question-bank/{question}/statistics/compute | – | On-demand recalculation endpoint |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View statistics | Teacher | question-statistics.viewAny |
| View detailed metrics | Teacher | question-statistics.view-details |
| Trigger manual recalculation | Teacher | question-statistics.recalculate |
| View option analysis breakdown | Teacher | question-statistics.view-option-analysis |

---

## Database Columns & Behavior

### qns_question_statistics

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| id | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| question_bank_id | INT UNSIGNED | qns_questions_bank.id | No | – | Question FK (CASCADE delete) |
| difficulty_index | DECIMAL(5,2) | No | Yes | NULL | Percentage of students who answered correctly |
| discrimination_index | DECIMAL(5,2) | No | Yes | NULL | Top 27% correct rate minus bottom 27% correct rate |
| guessing_factor | DECIMAL(5,2) | No | Yes | NULL | MCQ-specific estimate of random guessing contribution |
| min_time_taken_seconds | INT UNSIGNED | No | Yes | NULL | Minimum time taken by any student |
| max_time_taken_seconds | INT UNSIGNED | No | Yes | NULL | Maximum time taken by any student |
| avg_time_taken_seconds | INT UNSIGNED | No | Yes | 0 | Average time taken across all attempts |
| total_attempts | INT UNSIGNED | No | No | 0 | Total number of student attempts |
| last_computed_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | When the statistics were last computed |
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
| status | ENUM | No | No | 'DRAFT' | Lifecycle status |
| is_active | TINYINT(1) | No | No | 1 | Active flag |
| created_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Update timestamp |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete timestamp |
