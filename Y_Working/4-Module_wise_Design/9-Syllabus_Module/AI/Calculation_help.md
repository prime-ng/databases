# Topic Mastery Calculation — Complete Design

Perfect — this is the core math layer that converts your rich schema into real academic intelligence.

Below is a clean, production-grade design of Topic Mastery Calculation, aligned with your existing tables and future AI use.

🎯 Topic Mastery Calculation — Complete Design

We’ll build this in layers, exactly how an ERP + AI engine should.

1️⃣ Core Definitions (Very Important)
📌 What is Topic Mastery?

A normalized score (0–100%) representing how well a student has mastered a topic, based on all questions attempted that map to that topic.

2️⃣ Required Inputs (From Your Existing Schema)
| Data	                 | Source
|------------------------|----------------------
| Question Marks	       | qns_questions_bank.marks
| Student Score	         | Assessment response table
| Topic Mapping	         | qns_question_topic_jnt.weightage
| Question Difficulty	   | slb_complexity_level
| Bloom Level	           | slb_bloom_taxonomy.bloom_level
| Time Taken	           | attempt table
| Negative Marks	       | negative_marks

3️⃣ Base Topic Contribution Formula (Per Question)

For one question → one topic contribution:

TopicContribution =
( MarksObtained / MaxMarks )
× TopicWeightage

Example

MarksObtained = 6

MaxMarks = 10

TopicWeightage = 40%

(6 / 10) × 0.40 = 0.24


This means:

24% mastery contribution toward that topic from this question

4️⃣ Aggregated Topic Mastery (Basic Formula)

For a topic T, across all attempted questions:

TopicMastery(T) =
Σ (QuestionContribution × QuestionWeight)
-----------------------------------------
Σ (QuestionWeight)


Where:

QuestionWeight = TopicWeightage


Normalized to percentage:

FinalTopicMastery = TopicMastery × 100

5️⃣ Enhanced Formula (Industrial-Grade)

Now we add difficulty, Bloom level, and penalties.

🔹 5.1 Difficulty Weight Factor
Complexity	Factor
EASY	0.8
MEDIUM	1.0
HARD	1.2
DifficultyFactor = complexity_factor

🔹 5.2 Bloom Cognitive Weight
Bloom Level	Factor
Remember (1)	0.7
Understand (2)	0.85
Apply (3)	1.0
Analyze (4)	1.1
Evaluate (5)	1.2
Create (6)	1.3
BloomFactor = bloom_factor

🔹 5.3 Time Efficiency Factor (Optional but Powerful)
TimeFactor =
IF (time_taken <= avg_time)
  THEN 1.0
  ELSE (avg_time / time_taken)


Clamped between:

0.7 ≤ TimeFactor ≤ 1.0

6️⃣ Final Question → Topic Contribution Formula
WeightedContribution =
(MarksObtained / MaxMarks)
× TopicWeightage
× DifficultyFactor
× BloomFactor
× TimeFactor

7️⃣ Final Topic Mastery Formula (Full)
TopicMastery(T) =
Σ WeightedContribution
---------------------
Σ (TopicWeightage × DifficultyFactor × BloomFactor)


Convert to percentage:

TopicMastery% = TopicMastery × 100

8️⃣ Decay & Recency Adjustment (Highly Recommended)

Recent attempts should matter more.

📉 Time Decay Function
DecayFactor = e ^ (-λ × DaysSinceAttempt)


Typical:

λ = 0.03


Final contribution becomes:

WeightedContribution × DecayFactor

9️⃣ Mastery Level Classification
Mastery %	Level
≥ 90	Mastered
75 – 89	Strong
60 – 74	Adequate
40 – 59	Weak
< 40	Needs Remediation

(Store this for dashboards & AI rules)

🔟 SQL-Friendly Pseudocode (Materialized View Ready)
SELECT
  student_id,
  topic_id,
  SUM(
    (marks_obtained / max_marks)
    * topic_weightage
    * difficulty_factor
    * bloom_factor
    * time_factor
    * decay_factor
  )
  /
  SUM(
    topic_weightage
    * difficulty_factor
    * bloom_factor
  ) * 100 AS topic_mastery_percent
FROM student_question_attempts
JOIN qns_question_topic_jnt USING (question_bank_id)
JOIN qns_questions_bank USING (question_bank_id)
JOIN slb_bloom_taxonomy USING (bloom_id)
JOIN slb_complexity_level USING (complexity_level_id)
GROUP BY student_id, topic_id;

1️⃣1️⃣ Why This Design Is Enterprise-Level

✔ Accurate multi-topic analytics
✔ Fair evaluation across difficulty
✔ Bloom-aware mastery
✔ Time-sensitive learning decay
✔ AI-ready feature vector
✔ NEP-2020 compliant
