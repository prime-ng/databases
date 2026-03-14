# AI Rules Using Performance Categories

(Student → Topic → Action)

**1️⃣ Role of Performance Categories in AI**

Performance Category is NOT an output
It is a decision trigger.

**Flow:**
```
    Topic Mastery %
    ↓
    Performance Category
    ↓
    AI Rule Engine
    ↓
    Action (Content, Question, Alert, Intervention)
```

**2️⃣ Performance Categories (Input Layer)**

Example configuration from slb_performance_categories:

| Code	            | Min	| Max	| Meaning
|-------------------|-------|-------|----------------
| TOPPER	        | 90	| 100	| Advanced mastery
| EXCELLENT	        | 80	| 89.99	| Very strong
| GOOD	            | 70	| 79.99	| On track
| AVERAGE	        | 60	| 69.99	| Needs reinforcement
| BELOW_AVERAGE	    | 50	| 59.99	| Weak
| NEED_IMPROVEMENT	| 40	| 49.99	| Very weak
| POOR	            | 0	    | 39.99	| Critical

These ranges are configurable per school ✔

**3️⃣ Core AI Rule Dimensions**

Each rule uses multiple signals, not just marks.

🎯 Rule Inputs
| Signal	                | Source
|-------------------------|----------------
| Topic mastery %	        | MV (mv_student_topic_mastery)
| Performance category	    | slb_performance_categories
| Bloom level weakness	    | Attempt history
| Time inefficiency	        | Time factor
| Attempt frequency	        | Usage log
| Recency	                | Decay factor


**4️⃣ Rule Categories (High Level)**
| Rule Type	                | Purpose
|---------------------------|----------------
| Diagnostic Rules	        | Identify weakness
| Recommendation Rules	    | What to study next
| Assessment Rules	        | What questions to assign
| Alert Rules	            | Notify teacher/parent
| Progression Rules	        | Promote / accelerate

**5️⃣ Core Rule Set (Deterministic)**

🔹 Rule 1: Remediation Trigger

``` sql
IF
    performance_category IN ('POOR', 'NEED_IMPROVEMENT')
    AND questions_attempted >= 3
THEN
    Action:
    - Assign REVISION material
    - Assign EASY + MEDIUM questions
    - Disable HARD questions


📌 Why:
Low mastery after multiple attempts → concept gap

🔹 Rule 2: Reinforcement Rule
``` sql
IF
    performance_category = 'AVERAGE'
THEN
    Action:
    - Assign PRACTICE set
    - Focus Bloom: REMEMBER + UNDERSTAND


📌 Why:
Concept understood, not stabilized

🔹 Rule 3: Progression Rule
``` sql
IF
    performance_category IN ('GOOD', 'EXCELLENT')
    AND recent_attempts >= 2
THEN
    Action:
    - Assign APPLY + ANALYZE questions
    - Introduce case studies
```

🔹 Rule 4: Acceleration Rule (Topper)
``` sql
IF  
    performance_category = 'TOPPER'
    AND time_efficiency >= 0.9
THEN
    Action:
    - Assign HOTS / Olympiad / Challenge questions
    - Skip revision content
```

**6️⃣ Bloom-Specific AI Rules (Very Important)**

🔹 Bloom Weakness Detection
``` sql
For a topic:
    IF
        mastery >= 70%
        AND Bloom(REMEMBER) >= 80%
        AND Bloom(APPLY) < 50%
    THEN
        Weakness Type = "Application Gap"
        Action = Scenario-based questions
```

This uses your:

slb_bloom_taxonomy

Attempt history

**7️⃣ Time-Based Intelligence Rules**

🔹 Slow Learner Detection (Non-Academic)
``` sql
IF
    mastery >= 65%
    AND avg_time_taken > 1.5 × avg_expected_time
THEN
    Issue = "Processing Speed"
    Action = Reduce question length + visuals
```

📌 Important:
This avoids mislabeling such students as “weak”.

**8️⃣ Question Recommendation Rules**

Use your mapping table:
qns_question_recommendation_map

🔹 Question Selection Logic
``` sql
SELECT questions
WHERE
    topic_id = weak_topic
    AND performance_category = student_category
    AND complexity <= recommended_level
ORDER BY
    priority,
    difficulty ASC,
    usage_count ASC
LIMIT 10;
```

**9️⃣ Alert & Notification Rules**

🔹 Teacher Alert

``` sql
IF
    performance_category = 'POOR'
    AND no_improvement_days >= 14

THEN
    Notify:
    - Subject teacher
    - Academic coordinator
```

🔹 Parent Alert (Soft)
``` sql
IF
    performance_category = 'NEED_IMPROVEMENT'
    AND age < threshold

THEN
    Message:
    "Your child needs concept reinforcement, no concern yet."
```

**🔟 AI Rule Engine Table Design (Optional but Powerful)**

✅ ai_performance_rules

``` sql
CREATE TABLE ai_performance_rules (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  performance_category_id BIGINT UNSIGNED,
  rule_type ENUM(
    'REMEDIATION',
    'PRACTICE',
    'PROGRESSION',
    'ACCELERATION',
    'ALERT'
  ),
  condition_json JSON NOT NULL,
  action_json JSON NOT NULL,
  priority SMALLINT UNSIGNED DEFAULT 1,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

This lets schools configure AI behavior without code.

**Example Rule JSON**
``` json
{
  "conditions": {
    "min_attempts": 3,
    "time_efficiency_lt": 0.7
  },
  "actions": {
    "assign_material": ["VIDEO", "SIMULATION"],
    "question_complexity": ["EASY"],
    "notify_teacher": true
  }
}
```

**Why This Design Is Excellent for You**

✔ Explainable AI
✔ Rule-first, ML-later
✔ School-configurable
✔ Auditable
✔ Works in PHP without ML dependency
✔ Smooth upgrade path to ML

🚀 What Should We Do Next?

I can now:
    🎯 Map Topic Mastery → Recommendation Engine
    📊 Design AI dashboards (Student / Teacher / Parent)
    🤖 Convert rules into Laravel Service + Jobs
    🧠 Design ML upgrade path (when you’re ready)
    🔁 Create sample datasets & simulations