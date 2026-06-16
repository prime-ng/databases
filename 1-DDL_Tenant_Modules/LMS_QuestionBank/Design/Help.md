Table: qns_question_statistics.guessing_factor DECIMAL(5,2) at Question_Bank_ddl_v1.2.sql:214
  DDL comment: "MCQ only" and (line 207) "Required a backend Service to calculate the statistics" — the DDL delegates the formula to the backend. Below is the psychometrically correct method using only tables that
  already exist in the schema.

  ---
  1. What guessing_factor means

  It is the pseudo-guessing parameter (c) from IRT's 3PL model — the probability that a student with very low ability still gets the MCQ right, typically by blind guessing or by elimination of obviously wrong
  distractors.

  Two interpretations coexist in the ERP context:

  ┌─────────────────────────┬───────────────────────────────────────┬─────────────────────────────────────────────────┐
  │          View           │                Meaning                │                    Used when                    │
  ├─────────────────────────┼───────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Theoretical (baseline)  │ 1 / k where k = number of MCQ options │ Question has too few attempts (cold-start)      │
  ├─────────────────────────┼───────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Empirical (data-driven) │ % correct among bottom-27% performers │ Question has enough attempts (≥ 30 recommended) │
  └─────────────────────────┴───────────────────────────────────────┴─────────────────────────────────────────────────┘

  The backend service should return the empirical value when enough data exists, otherwise fall back to baseline — and clamp to [0.00, 1.00] because the column is DECIMAL(5,2).

  ---
  2. Data Sources (existing tables)

  The calculation pulls from 4 sources, all already in the schema:

  ┌───────────────────────────────────────┬─────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────┐
  │                Purpose                │                              Table                              │                                       Key columns                                       │
  ├───────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ Which option is the right answer      │ qns_question_options                                            │ question_bank_id, is_correct (line 98)                                                  │
  ├───────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ Student's chosen option (Quiz/Quest)  │ lms_quiz_quest_attempt_answers                                  │ attempt_id, question_id, selected_option_id, is_correct (StudentAttempt_ddl_v3.sql:125) │
  ├───────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ Student's chosen option (Exam online) │ lms_exam_attempt_answers                                        │ same shape (StudentAttempt_ddl_v3.sql:273)                                              │
  ├───────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ Student ability ranking               │ lms_quiz_quest_results.percentage + lms_exam_results.percentage │ used to split top-27% vs bottom-27%                                                     │
  ├───────────────────────────────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ MCQ question filter                   │ qns_questions_bank → slb_question_types                         │ only rows with question_type_id in {SINGLE_MCQ, MULTI_MCQ}                              │
  └───────────────────────────────────────┴─────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────┘

  ▎ Note: lms_exam_marks_entry (BULK_TOTAL offline mode) has NO per-question answer data, so offline-bulk exams are excluded from the calculation.

  ---
  3. The Formula (3 steps)

  Step A — Baseline c₀ (option-based floor)

  c₀ = 1 / k
  where k = COUNT(*) FROM qns_question_options WHERE question_bank_id = :q AND is_active = 1
  (i.e. 4 options → 0.25, 5 options → 0.20).

  Step B — Empirical c_emp (lower-group correct rate)

  Rank every attempter of question :q by their overall attempt percentage on the same assessment, then take the bottom-27% slice (Kelley, 1939 — the standard psychometric split used for CTT discrimination and
  guessing indices):

  Let L = set of (attempt_id, student_id) whose overall percentage
          is in the bottom 27% of all attempts that contain question :q.

  c_emp = COUNT(answers WHERE is_correct = 1 AND attempt_id ∈ L)
        / COUNT(answers WHERE attempt_id ∈ L)

  Step C — Final value written to the column

  IF total_attempts >= 30:
      guessing_factor = ROUND(c_emp, 2)
  ELSE:
      guessing_factor = ROUND(c₀, 2)          -- cold start
  guessing_factor = CLAMP(guessing_factor, 0.00, 1.00)

  Interpretation of the stored value (PrimeAI convention):

  ┌────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │   Stored   │                                               Meaning                                               │
  ├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ c_emp ≈ c₀ │ Distractors working as designed — genuine random guessing                                           │
  ├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ c_emp > c₀ │ Weak distractors / cueing — even low-ability students get it right. Flag for review.                │
  ├────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ c_emp < c₀ │ Distractors contain plausible-but-wrong options (mis-keyed key or trick question). Flag for review. │
  └────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────┘

  ---
  4. Reference SQL (MySQL 8)

  -- Compute guessing_factor for question :qid across both Quiz/Quest and Exam
  WITH
  -- Number of options on the question (for baseline c₀)
  opts AS (
    SELECT COUNT(*) AS k
    FROM qns_question_options
    WHERE question_bank_id = :qid AND is_active = 1
  ),

  -- Unified answer feed: quiz/quest + exam (MCQ only, evaluated only)
  answers AS (
    SELECT a.attempt_id,
           r.student_id,
           r.percentage,
           a.is_correct
    FROM lms_quiz_quest_attempt_answers a
    JOIN lms_quiz_quest_results r ON r.attempt_id = a.attempt_id
    WHERE a.question_id = :qid
      AND a.is_evaluated = 1
      AND a.is_active = 1

    UNION ALL

    SELECT a.attempt_id,
           r.student_id,
           r.percentage,
           a.is_correct
    FROM lms_exam_attempt_answers a
    JOIN lms_exam_results r ON r.attempt_id = a.attempt_id
    WHERE a.question_id = :qid
      AND a.is_evaluated = 1
      AND a.is_active = 1
  ),

  -- Rank attempts by overall percentage to find bottom 27%
  ranked AS (
    SELECT attempt_id,
           is_correct,
           PERCENT_RANK() OVER (ORDER BY percentage ASC) AS pr
    FROM answers
  ),

  -- Bottom-27% slice (Kelley)
  lower_group AS (
    SELECT is_correct FROM ranked WHERE pr <= 0.27
  ),

  -- Aggregates
  n_attempts AS (SELECT COUNT(*) AS n FROM answers),
  c_emp AS (
    SELECT CASE WHEN COUNT(*) = 0 THEN NULL
                ELSE SUM(is_correct) / COUNT(*)
           END AS val
    FROM lower_group
  )

  SELECT
    LEAST(1.00, GREATEST(0.00, ROUND(
        CASE
          WHEN (SELECT n FROM n_attempts) >= 30
               AND (SELECT val FROM c_emp) IS NOT NULL
            THEN (SELECT val FROM c_emp)              -- empirical
          ELSE 1.0 / NULLIF((SELECT k FROM opts), 0)  -- baseline
        END
    , 2))) AS guessing_factor;

  This result is what QuestionStatisticsService::computeGuessingFactor($questionId) in the backend should UPDATE into qns_question_statistics.guessing_factor alongside difficulty_index, discrimination_index,
  total_attempts, and last_computed_at.

  ---
  5. Implementation notes for the backend service

  1. Run context: scheduled job (e.g. nightly) iterating over questions with total_attempts delta since last_computed_at — write all three indices (difficulty_index, discrimination_index, guessing_factor) in a
  single pass, since they share the same ranked attempt set.
  2. MCQ gate: only compute for questions whose qns_questions_bank.question_type_id resolves to an MCQ type in slb_question_types (single-choice or multi-choice). For descriptive, fill-in-the-blank, or file-upload
  types, leave guessing_factor as NULL.
  3. Ability ranking: use the assessment-level percentage (lms_quiz_quest_results.percentage / lms_exam_results.percentage), not the per-question mark. A student's ability proxy is their overall score on the
  assessment where the question appeared, so the bottom-27% slice reflects low-ability students rather than students who happened to miss that one item.
  4. Small-sample guard: with total_attempts < 30, empirical estimates are unstable — fall back to 1/k. PrimeAI can override the threshold via a tenant setting (sch_config.qns_guessing_min_attempts if added later).
  5. Multi-MCQ (selected_option_ids JSON): the service still uses is_correct which is already pre-computed at answer-submission time by the LMS evaluator — no need to re-score against qns_question_options inside
  this calculation.
  6. Auto-feed loop: qns_question_performance_category_jnt (line 228) can then flag questions where guessing_factor > 2 * baseline as candidates for recommendation_type = 'REVISION' — closing the loop back to
  Recommendation module.

  ---
  Summary

  ┌─────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │    Component    │                                                                      Source                                                                       │
  ├─────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Baseline c₀     │ 1 / COUNT(qns_question_options)                                                                                                                   │
  ├─────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Empirical c_emp │ COUNT(correct∩L) / COUNT(L), L = bottom 27% of attempters ranked by lms_*_results.percentage                                                      │
  ├─────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Stored value    │ c_emp if total_attempts ≥ 30, else c₀, clamped to [0.00, 1.00], rounded to 2 dp                                                                   │
  ├─────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Source tables   │ qns_question_options · qns_questions_bank · lms_quiz_quest_attempt_answers · lms_quiz_quest_results · lms_exam_attempt_answers · lms_exam_results │
  ├─────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Owner           │ Backend QuestionStatisticsService run on a scheduled job                                                                                          │
  └─────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
  