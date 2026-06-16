# `qns_question_statistics` — Field Calculation Reference

> **Purpose:** Complete calculation specification for every computed field in
> `qns_question_statistics` (see `Question_Bank_ddl_v1.2.sql:209`).
> The DDL header comment (line 207) states
> *"Required a backend Service to calculate the statistics"* — this document is
> the specification that backend service must implement.
>
> **Target column type:** all metric columns are `DECIMAL(5,2)` or `INT UNSIGNED`.
> Every computed value MUST be clamped/rounded to fit those types before
> `UPDATE`.
>
> **Source tables used (all already in the schema):**
>
> | Table | File | Role |
> |---|---|---|
> | `qns_questions_bank` | `Question_Bank_ddl_v1.2.sql:5` | Question master (for MCQ type filter) |
> | `qns_question_options` | `Question_Bank_ddl_v1.2.sql:93` | Option count for baseline guessing |
> | `lms_quiz_quest_attempt_answers` | `55e-LMS_StudentAttempts/DDL/StudentAttempt_ddl_v3.sql:125` | Quiz + Quest per-question answers |
> | `lms_quiz_quest_results` | `StudentAttempt_ddl_v3.sql:170` | Overall percentage per attempt |
> | `lms_exam_attempt_answers` | `StudentAttempt_ddl_v3.sql:273` | Online exam per-question answers |
> | `lms_exam_results` | `StudentAttempt_ddl_v3.sql:349` | Overall percentage per exam attempt |
>
> **NOT used:** `lms_exam_marks_entry` (BULK_TOTAL offline mode — no per-question
> data; excluded from all question-level statistics).

---

## Field-by-field summary

| # | Field | Type | Computed? | Formula (short) |
|---|---|---|---|---|
| 1 | `id` | INT UNSIGNED PK | No | auto-increment |
| 2 | `question_bank_id` | INT UNSIGNED FK | No | set by service at upsert time |
| 3 | `difficulty_index` | DECIMAL(5,2) | **YES** | `% correct` (p-value) — all attempts |
| 4 | `discrimination_index` | DECIMAL(5,2) | **YES** | top-27% correct rate − bottom-27% correct rate |
| 5 | `guessing_factor` | DECIMAL(5,2) | **YES (MCQ only)** | bottom-27% correct rate (empirical) OR `1/k` baseline |
| 6 | `min_time_taken_seconds` | INT UNSIGNED | **YES** | fastest successful attempt (topper's time) |
| 7 | `max_time_taken_seconds` | INT UNSIGNED | **YES** | slowest attempt (name/comment mismatch — see §6) |
| 8 | `avg_time_taken_seconds` | INT UNSIGNED | **YES** | mean of `time_spent_seconds` across attempts |
| 9 | `total_attempts` | INT UNSIGNED | **YES** | COUNT of evaluated answer rows |
| 10 | `last_computed_at` | TIMESTAMP | **YES** | `NOW()` at time of service run |
| 11 | `is_active` | TINYINT(1) | No | default 1 |
| 12 | `created_at` / `updated_at` / `deleted_at` | TIMESTAMP | No | Laravel/MySQL standard |

All percentage-type columns (`difficulty_index`, `discrimination_index`,
`guessing_factor`) store values on the **0–100 scale** (e.g. `62.50` means
62.5% correct), NOT on the 0.00–1.00 proportion scale, because `DECIMAL(5,2)`
can hold values up to `999.99` and the domain convention across PrimeAI
(`std_students.*percentage`, `lms_*_results.percentage`, `hpc_reports.*`) is
two-decimal percent values. The one exception — if the tenant prefers
0.00–1.00 proportions — is documented inline; pick one convention and
hold it tenant-wide.

---

## 0. Shared CTE — the "answer feed"

Every computed field builds on the same unified view of per-question answers
across all three assessment types (Quiz + Quest + Exam). Define it once as a
helper CTE / view and reuse it throughout the service:

```sql
-- Unified answer feed for question :qid (MCQ or non-MCQ, evaluated only)
CREATE OR REPLACE VIEW v_qns_answer_feed AS
SELECT
    a.question_id,
    a.attempt_id,
    r.student_id,
    r.percentage        AS attempt_percentage,  -- ability proxy
    a.is_correct,                               -- 0/1, NULL = pending
    a.time_spent_seconds
FROM lms_quiz_quest_attempt_answers a
JOIN lms_quiz_quest_results         r ON r.attempt_id = a.attempt_id
WHERE a.is_evaluated = 1
  AND a.is_active    = 1
  AND a.is_correct IS NOT NULL

UNION ALL

SELECT
    a.question_id,
    a.attempt_id,
    r.student_id,
    r.percentage        AS attempt_percentage,
    a.is_correct,
    a.time_spent_seconds
FROM lms_exam_attempt_answers a
JOIN lms_exam_results         r ON r.attempt_id = a.attempt_id
WHERE a.is_evaluated = 1
  AND a.is_active    = 1
  AND a.is_correct IS NOT NULL;
```

> **Why `is_correct IS NOT NULL`:** the column is nullable while evaluation is
> pending. Pending rows must NOT enter any statistic — otherwise `total_attempts`
> drifts ahead of `difficulty_index` and the ratios become meaningless.

---

## 1. `difficulty_index` — % students answered correctly

**Column:** `difficulty_index DECIMAL(5,2)` — `Question_Bank_ddl_v1.2.sql:212`
**DDL comment:** *"% students answered correctly"*
**Psychometric name:** p-value (Classical Test Theory)

### Meaning

The proportion of students who answered the question correctly. Despite being
called "difficulty", it actually measures **easiness** — a higher value means
the question was *easier*. PrimeAI stores it as-is (0–100) and interprets in
the UI.

### Formula

```
difficulty_index = 100 * (COUNT of correct answers) / (total evaluated attempts)
```

### SQL

```sql
SELECT ROUND(
         100.0 * SUM(is_correct) / NULLIF(COUNT(*), 0)
       , 2) AS difficulty_index
FROM v_qns_answer_feed
WHERE question_id = :qid;
```

### Interpretation bands (PrimeAI convention)

| Stored value | Band | Meaning |
|---|---|---|
| `0 – 29.99` | Very Hard | <30% students correct → probably too hard, mis-keyed, or poorly worded |
| `30 – 69.99` | Moderate | Ideal psychometric range |
| `70 – 84.99` | Easy | Acceptable, but watch for ceiling effect |
| `85 – 100` | Very Easy | Almost everyone gets it — little discrimination power; flag for review |

### Edge cases

| Scenario | Handling |
|---|---|
| `total_attempts = 0` | `difficulty_index = NULL` (leave the column null; do NOT write 0) |
| All answers pending | treat as 0 attempts — skip update |
| Question deleted/soft-deleted | `qns_question_statistics.is_active = 0`; stop computing |

---

## 2. `discrimination_index` — Top vs bottom performer delta

**Column:** `discrimination_index DECIMAL(5,2)` — `Question_Bank_ddl_v1.2.sql:213`
**DDL comment:** *"Top vs bottom performer delta"*
**Psychometric name:** D-index (Kelley 1939)

### Meaning

How well a question separates high-ability from low-ability students. A good
question is answered correctly by more top-performers than bottom-performers.
A negative value means the question is actively mis-keyed (low-ability
students outperformed high-ability ones).

### Formula

```
Let U = top-27% slice of attempters (by overall assessment percentage, DESC)
Let L = bottom-27% slice of attempters (by overall assessment percentage, ASC)

p_U = COUNT(correct ∩ U) / COUNT(U)      -- proportion correct in upper group
p_L = COUNT(correct ∩ L) / COUNT(L)      -- proportion correct in lower group

discrimination_index = 100 * (p_U - p_L)
```

The **27% cut-point** is the Kelley standard — it is the split that maximises
the reliability of the D index under a normal ability distribution. It is the
same cut-point used to compute `guessing_factor` (§3 below), so the two
calculations share one ranked pass.

### SQL

```sql
WITH ranked AS (
  SELECT is_correct,
         PERCENT_RANK() OVER (ORDER BY attempt_percentage ASC) AS pr_low,
         PERCENT_RANK() OVER (ORDER BY attempt_percentage DESC) AS pr_high
  FROM v_qns_answer_feed
  WHERE question_id = :qid
),
upper_group AS (SELECT is_correct FROM ranked WHERE pr_high <= 0.27),
lower_group AS (SELECT is_correct FROM ranked WHERE pr_low  <= 0.27),
p_u AS (
  SELECT CASE WHEN COUNT(*) = 0 THEN NULL
              ELSE SUM(is_correct) * 1.0 / COUNT(*)
         END AS val FROM upper_group
),
p_l AS (
  SELECT CASE WHEN COUNT(*) = 0 THEN NULL
              ELSE SUM(is_correct) * 1.0 / COUNT(*)
         END AS val FROM lower_group
)
SELECT
  CASE
    WHEN (SELECT val FROM p_u) IS NULL OR (SELECT val FROM p_l) IS NULL THEN NULL
    ELSE ROUND(100.0 * ((SELECT val FROM p_u) - (SELECT val FROM p_l)), 2)
  END AS discrimination_index;
```

Clamp to `[-100.00, +100.00]` defensively before `UPDATE`.

### Interpretation bands (Ebel 1972, adapted)

| Stored value | Quality | Action |
|---|---|---|
| `≥ 40`          | Excellent | Keep |
| `30 – 39.99`    | Good | Keep |
| `20 – 29.99`    | Fair | Consider improving wording or distractors |
| `0 – 19.99`     | Poor | Rewrite or retire |
| `< 0`           | **Negative — MIS-KEYED** | Auto-flag for review; likely wrong `is_correct` mark in `qns_question_options` |

### Edge cases

| Scenario | Handling |
|---|---|
| `total_attempts < 30` | Result is statistically noisy; still write it, but set a service-level flag (e.g. `qns_question_performance_category_jnt.recommendation_type = REVIEW`) |
| Fewer than 4 attempts in either group | `discrimination_index = NULL` |
| All students in lower group got it right *and* all in upper group got it right | D = 0 (question does not discriminate) — store `0.00`, flag as too-easy |

---

## 3. `guessing_factor` — MCQ only (pseudo-guessing parameter)

**Column:** `guessing_factor DECIMAL(5,2)` — `Question_Bank_ddl_v1.2.sql:214`
**DDL comment:** *"MCQ only"*
**Psychometric name:** c-parameter (IRT 3PL)

### Meaning

The probability that a student with *very low ability* still gets the MCQ
right — typically via blind guessing or by eliminating obviously wrong
distractors. Two views of the same quantity coexist:

| View | Meaning |
|---|---|
| **Theoretical baseline** `c₀` | `1 / k`, where *k* = number of active options |
| **Empirical `c_emp`** | % correct among bottom-27% attempters (Kelley slice) |

### Formula

```
-- Baseline (cold start)
c_0   = 1 / k          (k = active option count)

-- Empirical (when data is sufficient)
c_emp = COUNT(correct ∩ L) / COUNT(L)     (L = bottom-27% attempters)

-- Final stored value
IF total_attempts >= 30 AND c_emp IS NOT NULL:
    guessing_factor = ROUND(100 * c_emp, 2)
ELSE:
    guessing_factor = ROUND(100 * c_0, 2)

CLAMP to [0.00, 100.00]
```

### SQL

```sql
WITH
opts AS (
  SELECT COUNT(*) AS k
  FROM qns_question_options
  WHERE question_bank_id = :qid AND is_active = 1
),
feed AS (
  SELECT is_correct, attempt_percentage
  FROM v_qns_answer_feed
  WHERE question_id = :qid
),
ranked AS (
  SELECT is_correct,
         PERCENT_RANK() OVER (ORDER BY attempt_percentage ASC) AS pr
  FROM feed
),
lower_group AS (SELECT is_correct FROM ranked WHERE pr <= 0.27),
c_emp AS (
  SELECT CASE WHEN COUNT(*) = 0 THEN NULL
              ELSE SUM(is_correct) * 1.0 / COUNT(*)
         END AS val FROM lower_group
),
n_attempts AS (SELECT COUNT(*) AS n FROM feed)
SELECT LEAST(100.00, GREATEST(0.00, ROUND(
  CASE
    WHEN (SELECT n FROM n_attempts) >= 30
         AND (SELECT val FROM c_emp) IS NOT NULL
      THEN 100.0 * (SELECT val FROM c_emp)
    ELSE 100.0 / NULLIF((SELECT k FROM opts), 0)
  END
, 2))) AS guessing_factor;
```

### MCQ type filter (before calling this computation)

```sql
-- Only compute when the question is an MCQ type (single or multi)
SELECT 1
FROM qns_questions_bank q
JOIN slb_question_types t ON t.id = q.question_type_id
WHERE q.id = :qid
  AND t.code IN ('SINGLE_MCQ', 'MULTI_MCQ');
```

For descriptive / fill-in-the-blank / file-upload / true-false / matching,
leave `guessing_factor = NULL`.

### Interpretation

| `c_emp` vs `c_0` | Meaning | Action |
|---|---|---|
| `c_emp ≈ c₀` | Distractors working as designed — genuine random guessing | Keep |
| `c_emp > 2·c₀` | Weak distractors / cueing — even low-ability students get it right | Flag for distractor rewrite |
| `c_emp < 0.5·c₀` | Distractors too plausible OR question mis-keyed | Flag for review |

### Edge cases

| Scenario | Handling |
|---|---|
| Non-MCQ question | `guessing_factor = NULL` |
| Zero options active on the question | `guessing_factor = NULL` (and raise integrity alert — a question with no options is broken) |
| Multi-MCQ | Still valid; use `is_correct` from the answer row (pre-computed at submission time — do NOT re-score against `selected_option_ids` JSON here) |

---

## 4. `min_time_taken_seconds` — fastest time (topper's time)

**Column:** `min_time_taken_seconds INT UNSIGNED DEFAULT NULL`
— `Question_Bank_ddl_v1.2.sql:215`
**DDL comment:** *"time taken by topper to answer the question"*

### Meaning

The shortest amount of time any student spent on the question and **got it
right**. Useful for setting a floor on "how fast can this be answered when
known" — it feeds into anti-cheat heuristics (attempts that are faster than
this value by a wide margin are suspicious — pattern-click detection).

### Formula

```
min_time_taken_seconds = MIN(time_spent_seconds)
                         WHERE question_id = :qid
                           AND is_correct = 1
                           AND time_spent_seconds > 0
```

The **`> 0` guard** is important — the LMS may store `0` for "question shown
but never opened" or for offline attempts where telemetry is absent. Those
rows must not collapse the minimum to 0.

### SQL

```sql
SELECT MIN(time_spent_seconds) AS min_time_taken_seconds
FROM v_qns_answer_feed
WHERE question_id       = :qid
  AND is_correct        = 1
  AND time_spent_seconds > 0;
```

### Edge cases

| Scenario | Handling |
|---|---|
| No correct attempts yet | `min_time_taken_seconds = NULL` |
| All attempts have `time_spent_seconds = 0` (offline / telemetry off) | `min_time_taken_seconds = NULL` |
| Only BULK_TOTAL offline exam attempts | `min_time_taken_seconds = NULL` (no per-question time) |

---

## 5. `max_time_taken_seconds` — **name/comment mismatch — read carefully**

**Column:** `max_time_taken_seconds INT UNSIGNED DEFAULT NULL`
— `Question_Bank_ddl_v1.2.sql:216`
**DDL comment:** *"average time taken to answer by students"*

### ⚠️ DDL inconsistency

The column **name** says *maximum* and the **inline comment** says *average*.
This is almost certainly a copy-paste error in the DDL — `avg_time_taken_seconds`
already exists on the next line (217) and covers the average case. The column
name is authoritative; the comment should be corrected.

**Recommendation for the backend service:** honour the column NAME (store the
maximum). File a schema note to fix the comment in the next DDL revision
(v1.3).

### Meaning (assuming column name is authoritative)

The longest amount of time any single student spent on the question,
regardless of correctness. Feeds into UX review — if `max_time` is an order
of magnitude larger than `avg_time`, students are probably confused by the
wording, the image didn't load, or the question has an ambiguous stem.

### Formula

```
max_time_taken_seconds = MAX(time_spent_seconds)
                         WHERE question_id = :qid
                           AND time_spent_seconds > 0
                           AND time_spent_seconds < :reasonable_upper_bound
```

The **`< :reasonable_upper_bound`** guard eliminates outliers caused by
students who opened the question in tab A, walked away, and came back an hour
later. Recommended: drop values beyond `3 × expected_time_to_answer_seconds`
from `qns_questions_bank.expected_time_to_answer_seconds` — or a hard ceiling
of the assessment's time limit.

### SQL

```sql
WITH bounds AS (
  SELECT COALESCE(expected_time_to_answer_seconds * 3, 3600) AS ceiling
  FROM qns_questions_bank
  WHERE id = :qid
)
SELECT MAX(time_spent_seconds) AS max_time_taken_seconds
FROM v_qns_answer_feed
CROSS JOIN bounds
WHERE question_id       = :qid
  AND time_spent_seconds > 0
  AND time_spent_seconds < bounds.ceiling;
```

### Edge cases

| Scenario | Handling |
|---|---|
| No attempts with telemetry | `max_time_taken_seconds = NULL` |
| `expected_time_to_answer_seconds` not set on the question | Use fallback ceiling of `3600` seconds (1 hour) |
| All attempts exceeded the ceiling | Use the assessment's time limit instead (rare) |

---

## 6. `avg_time_taken_seconds` — mean time

**Column:** `avg_time_taken_seconds INT UNSIGNED` — `Question_Bank_ddl_v1.2.sql:217`

### Meaning

The arithmetic mean of `time_spent_seconds` across all evaluated attempts,
excluding telemetry-free rows (offline attempts / rows with `time = 0`).
Feeds into the difficulty narrative: a question that is marked "easy" by
`difficulty_index` but whose `avg_time` is far above the expected time is in
fact a laborious question that happens to be answerable by most people
(poor time-efficiency).

### Formula

```
avg_time_taken_seconds = ROUND(AVG(time_spent_seconds))
                         WHERE question_id = :qid
                           AND time_spent_seconds > 0
                           AND time_spent_seconds < :reasonable_upper_bound
```

### SQL

```sql
WITH bounds AS (
  SELECT COALESCE(expected_time_to_answer_seconds * 3, 3600) AS ceiling
  FROM qns_questions_bank
  WHERE id = :qid
)
SELECT CAST(ROUND(AVG(time_spent_seconds)) AS UNSIGNED)
           AS avg_time_taken_seconds
FROM v_qns_answer_feed
CROSS JOIN bounds
WHERE question_id       = :qid
  AND time_spent_seconds > 0
  AND time_spent_seconds < bounds.ceiling;
```

### Interpretation

Compare against `qns_questions_bank.expected_time_to_answer_seconds`:

| Ratio `avg / expected` | Meaning |
|---|---|
| `< 0.5` | Far faster than designed — question is easier than intended |
| `0.5 – 1.5` | On target |
| `> 1.5` | Slower than designed — wording may be ambiguous, or the question is harder than the author estimated |

### Edge cases

| Scenario | Handling |
|---|---|
| `AVG()` returns NULL (no rows after filters) | `avg_time_taken_seconds = NULL` |
| Rounding produces a value > 2^32 | Cap to `4294967295` (INT UNSIGNED max) — defensive only |

---

## 7. `total_attempts` — count of evaluated attempts

**Column:** `total_attempts INT UNSIGNED DEFAULT 0`
— `Question_Bank_ddl_v1.2.sql:218`

### Meaning

The number of times this question has been answered and evaluated. Drives
the cold-start fallback in `guessing_factor` (§3) and the statistical-noise
flag on `discrimination_index` (§2). The DEFAULT 0 means the row can exist
before any attempt has been recorded.

### Formula

```
total_attempts = COUNT(*)   -- across both quiz/quest and exam answer feeds
                 WHERE question_id = :qid
                   AND is_evaluated = 1
                   AND is_correct IS NOT NULL
```

### SQL

```sql
SELECT COUNT(*) AS total_attempts
FROM v_qns_answer_feed
WHERE question_id = :qid;
```

(The view already filters by `is_evaluated = 1 AND is_correct IS NOT NULL`.)

### Edge cases

| Scenario | Handling |
|---|---|
| Student attempted but exam/quiz not yet submitted | Excluded — `is_evaluated` flag is still 0 |
| Student answer evaluated but later soft-deleted | Excluded via the `is_active = 1` filter inside the view |
| Same student attempted twice (retake) | Both rows counted — two distinct `attempt_id` values |

### Question for business logic

Should a retake count as one attempt or two? The v3 DDL allows
`lms_quiz_quest_attempts.is_active` and `lms_exam_attempts.is_active` to mark
abandoned/superseded attempts; the view already filters those out. A
deliberate retake (fresh attempt, not an abandoned one) **should count as
two** — it reflects real interaction with the question.

---

## 8. `last_computed_at` — watermark

**Column:** `last_computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
— `Question_Bank_ddl_v1.2.sql:219`

### Meaning

The moment at which the statistics were last recomputed for this question.
Used by the scheduled job to decide which rows need a refresh.

### Formula

```
last_computed_at = NOW()
```

Set unconditionally at the time of `UPSERT` — even if the numeric values
did not change. Gives you a reliable "was the computation even attempted"
signal.

### Scheduling strategy

```sql
-- Re-compute statistics for any question that has new answers
-- since its last computation, prioritising older ones first
SELECT q.id
FROM qns_questions_bank q
LEFT JOIN qns_question_statistics s ON s.question_bank_id = q.id
WHERE q.is_active = 1
  AND (
    s.last_computed_at IS NULL
    OR EXISTS (
      SELECT 1 FROM v_qns_answer_feed f
      WHERE f.question_id = q.id
        -- would need an `evaluated_at` timestamp here; see note below
    )
  )
ORDER BY COALESCE(s.last_computed_at, '1970-01-01') ASC
LIMIT 500;
```

> **Scheduling note:** for the delta check, the backend service should compare
> `MAX(evaluated_at)` from the answer tables against `s.last_computed_at`.
> Both `lms_quiz_quest_attempt_answers.evaluated_at` and
> `lms_exam_attempt_answers.evaluated_at` already exist — no schema change
> needed.

---

## 9. Standard audit columns

| Field | Type | Handling |
|---|---|---|
| `is_active` | TINYINT(1) DEFAULT 1 | Set to 0 only if the statistics row must be hidden without deleting (e.g. question was retired but history is preserved) |
| `created_at` | TIMESTAMP DEFAULT CURRENT_TIMESTAMP | Laravel Eloquent default — no service action needed |
| `updated_at` | TIMESTAMP ... ON UPDATE CURRENT_TIMESTAMP | Laravel Eloquent default |
| `deleted_at` | TIMESTAMP DEFAULT NULL | Soft-delete via Laravel SoftDeletes; set when the parent question is soft-deleted |

---

## Unique constraint — one row per question

```sql
UNIQUE KEY `uq_qstats_q` (`question_bank_id`)
```

The table has a UNIQUE key on `question_bank_id`, so the backend service
MUST use **UPSERT** semantics, not blind INSERT:

```sql
INSERT INTO qns_question_statistics
    (question_bank_id, difficulty_index, discrimination_index,
     guessing_factor, min_time_taken_seconds, max_time_taken_seconds,
     avg_time_taken_seconds, total_attempts, last_computed_at, is_active)
VALUES
    (:qid, :diff, :disc, :guess, :min_t, :max_t, :avg_t, :n, NOW(), 1)
ON DUPLICATE KEY UPDATE
    difficulty_index       = VALUES(difficulty_index),
    discrimination_index   = VALUES(discrimination_index),
    guessing_factor        = VALUES(guessing_factor),
    min_time_taken_seconds = VALUES(min_time_taken_seconds),
    max_time_taken_seconds = VALUES(max_time_taken_seconds),
    avg_time_taken_seconds = VALUES(avg_time_taken_seconds),
    total_attempts         = VALUES(total_attempts),
    last_computed_at       = NOW();
```

Or equivalently via Laravel Eloquent:

```php
QnsQuestionStatistics::updateOrCreate(
    ['question_bank_id' => $questionId],
    [
        'difficulty_index'       => $diff,
        'discrimination_index'   => $disc,
        'guessing_factor'        => $guess,
        'min_time_taken_seconds' => $minT,
        'max_time_taken_seconds' => $maxT,
        'avg_time_taken_seconds' => $avgT,
        'total_attempts'         => $n,
        'last_computed_at'       => now(),
        'is_active'              => 1,
    ]
);
```

---

## Recommended implementation

**Service:** `Modules\QuestionBank\Services\QuestionStatisticsService`

**Signature:**

```php
public function computeAndPersist(int $questionId): QnsQuestionStatistics;
public function computeBatch(Collection $questionIds): int;   // returns count persisted
```

**Scheduling:** register in `Modules\Scheduler` to run nightly (e.g. 02:30
tenant local time). Throttle to N questions per run so one cold tenant
with a large question bank does not monopolise the job queue.

**Transactionality:** wrap the whole question's computation in a single
read-consistent snapshot (`START TRANSACTION WITH CONSISTENT SNAPSHOT` in
MySQL 8) so all six metrics reflect the same set of answer rows. Do NOT
compute them over separate query plans — students may submit between queries
and cause metric drift.

**Feed-forward:** after computing the metrics, compare against the bands in
§1, §2, §3 and write `qns_question_performance_category_jnt` rows
(`recommendation_type = REVISION | PRACTICE | CHALLENGE`) to close the loop
into the Recommendation module per the condition listed at
`Question_Bank_ddl_v1.2.sql:243-245`.

---

## Quick reference card

```
difficulty_index     = 100 × Σ(correct) / n
discrimination_index = 100 × (p_upper27 − p_lower27)
guessing_factor      = MCQ only →
                         n ≥ 30 : 100 × p_lower27
                         else    : 100 / k  (k = #options)
min_time_taken_seconds = MIN(time_spent) WHERE is_correct = 1 AND t > 0
max_time_taken_seconds = MAX(time_spent) WHERE t > 0 AND t < 3·expected
avg_time_taken_seconds = ROUND(AVG(time_spent)) (same filters as max)
total_attempts       = COUNT(evaluated, non-null answers)
last_computed_at     = NOW()
```

---

*Authoritative source: `Question_Bank_ddl_v1.2.sql:209-226`
(table definition) and `StudentAttempt_ddl_v3.sql:125+, 273+`
(answer feed). This document is the backend service contract —
update it in lockstep with any DDL change.*
