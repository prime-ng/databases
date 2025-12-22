# Additional Features v1.4 - Data Dictionary

**Version:** 1.4  
**Created:** December 22, 2025  
**Purpose:** Suggested enhancements beyond original requirements

---

## Table Summary

| Section | Tables | Purpose |
|---------|--------|---------|
| Learning Pathways | 3 | Adaptive curriculum & personalized learning |
| Gamification | 4 | Student engagement via achievements & streaks |
| Peer Learning | 3 | Collaborative study & peer tutoring |
| AI Question Generation | 2 | AI-assisted question creation workflow |
| Parent Engagement | 2 | Parent notifications & activity tracking |
| Assessment Templates | 2 | Reusable exam blueprints |
| Question Quality | 2 | Feedback & usage statistics |
| Exam Scheduling | 2 | Academic calendar & seat allocation |
| Advanced Analytics | 2 | Predictions & at-risk alerts |
| Comparative Analytics | 1 | Cross-school benchmarking |
| **Total** | **24** | |

---

## 1. Learning Pathways & Adaptive Curriculum

### 1.1 `slb_learning_pathways`
**Purpose:** Define custom learning paths for different student needs.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED | Primary key |
| uuid | CHAR(36) | Unique identifier |
| name | VARCHAR(150) | Pathway name |
| pathway_type | ENUM | REMEDIAL/ENRICHMENT/STANDARD/ACCELERATED/SPECIAL_NEEDS |
| target_performance_category_id | INT UNSIGNED | Target student level |
| estimated_duration_days | INT UNSIGNED | Expected completion time |
| is_ai_generated | TINYINT(1) | AI-created flag |

**Use Case:** Create remedial pathways for struggling students or enrichment paths for advanced learners.

---

### 1.2 `slb_learning_pathway_nodes`
**Purpose:** Individual steps/nodes within a learning pathway.

| Column | Type | Description |
|--------|------|-------------|
| pathway_id | BIGINT UNSIGNED | Parent pathway |
| ordinal | SMALLINT UNSIGNED | Sequence order |
| node_type | ENUM | TOPIC/QUIZ/STUDY_MATERIAL/ASSESSMENT/CHECKPOINT |
| reference_id | BIGINT UNSIGNED | ID of referenced item |
| pass_criteria | JSON | {"min_score": 60, "max_attempts": 3} |
| unlock_condition | JSON | Conditions to access this node |

---

### 1.3 `sch_student_pathway_progress`
**Purpose:** Track student progress through assigned pathways.

| Column | Type | Description |
|--------|------|-------------|
| student_id | BIGINT UNSIGNED | Student reference |
| pathway_id | BIGINT UNSIGNED | Assigned pathway |
| current_node_id | BIGINT UNSIGNED | Current position |
| status | ENUM | NOT_STARTED/IN_PROGRESS/PAUSED/COMPLETED/ABANDONED |
| nodes_completed | INT UNSIGNED | Completion count |
| overall_score | DECIMAL(5,2) | Aggregate score |

---

## 2. Gamification & Student Engagement

### 2.1 `sch_achievements`
**Purpose:** Define badges/achievements students can earn.

| Column | Type | Description |
|--------|------|-------------|
| code | VARCHAR(50) | Unique achievement code |
| name | VARCHAR(100) | Display name |
| category | ENUM | ACADEMIC/CONSISTENCY/IMPROVEMENT/SPEED/PARTICIPATION/SPECIAL |
| criteria | JSON | {"type": "score", "threshold": 90} |
| points | INT UNSIGNED | Points awarded |
| rarity | ENUM | COMMON/UNCOMMON/RARE/EPIC/LEGENDARY |

**Example Achievements:**
- "Perfect Score" - 100% on any quiz
- "Weekly Warrior" - 7-day streak
- "Speed Demon" - Complete quiz 50% faster than average

---

### 2.2 `sch_student_achievements`
**Purpose:** Record of achievements earned by students.

| Column | Type | Description |
|--------|------|-------------|
| student_id | BIGINT UNSIGNED | Student reference |
| achievement_id | BIGINT UNSIGNED | Achievement earned |
| earned_at | TIMESTAMP | When earned |
| context | JSON | What triggered this |

---

### 2.3 `sch_leaderboard_snapshots`
**Purpose:** Historical leaderboard data for rankings.

| Column | Type | Description |
|--------|------|-------------|
| snapshot_date | DATE | Snapshot date |
| period_type | ENUM | DAILY/WEEKLY/MONTHLY/TERM/YEARLY |
| class_id | INT UNSIGNED | Class reference |
| leaderboard_data | JSON | [{student_id, rank, score, change}] |

---

### 2.4 `sch_student_streaks`
**Purpose:** Track consecutive activity streaks.

| Column | Type | Description |
|--------|------|-------------|
| student_id | BIGINT UNSIGNED | Student reference |
| streak_type | ENUM | LOGIN/QUIZ/STUDY/PRACTICE |
| current_streak | INT UNSIGNED | Current consecutive days |
| longest_streak | INT UNSIGNED | Best ever streak |
| last_activity_date | DATE | Last activity |

---

## 3. Peer Learning & Collaboration

### 3.1 `sch_study_groups`
**Purpose:** Student-created study groups.

| Column | Type | Description |
|--------|------|-------------|
| name | VARCHAR(100) | Group name |
| class_id | INT UNSIGNED | Class reference |
| subject_id | BIGINT UNSIGNED | Subject focus |
| created_by | BIGINT UNSIGNED | Creator |
| max_members | TINYINT UNSIGNED | Member limit |
| is_public | TINYINT(1) | Open/closed group |

---

### 3.2 `sch_study_group_members`
**Purpose:** Group membership tracking.

| Column | Type | Description |
|--------|------|-------------|
| group_id | BIGINT UNSIGNED | Group reference |
| student_id | BIGINT UNSIGNED | Member |
| role | ENUM | LEADER/MEMBER |
| joined_at | TIMESTAMP | Join date |

---

### 3.3 `sch_peer_tutoring`
**Purpose:** Match students who need help with peer tutors.

| Column | Type | Description |
|--------|------|-------------|
| requester_student_id | BIGINT UNSIGNED | Help seeker |
| tutor_student_id | BIGINT UNSIGNED | Peer tutor |
| topic_id | BIGINT UNSIGNED | Topic for help |
| request_type | ENUM | HELP_NEEDED/CAN_HELP |
| status | ENUM | OPEN/MATCHED/IN_PROGRESS/COMPLETED/CANCELLED |
| rating | TINYINT UNSIGNED | 1-5 rating |

---

## 4. AI-Assisted Question Generation

### 4.1 `sch_ai_question_requests`
**Purpose:** Track AI question generation requests.

| Column | Type | Description |
|--------|------|-------------|
| requested_by | BIGINT UNSIGNED | Requesting user |
| topic_id | BIGINT UNSIGNED | Target topic |
| question_type_id | INT UNSIGNED | Type to generate |
| complexity_level_id | INT UNSIGNED | Difficulty level |
| quantity | INT UNSIGNED | Number to generate |
| status | ENUM | PENDING/PROCESSING/COMPLETED/FAILED/REVIEW |
| ai_model_used | VARCHAR(50) | AI model version |

---

### 4.2 `sch_ai_generated_questions`
**Purpose:** Store AI-generated questions pending review.

| Column | Type | Description |
|--------|------|-------------|
| request_id | BIGINT UNSIGNED | Parent request |
| question_data | JSON | Full question structure |
| review_status | ENUM | PENDING/APPROVED/REJECTED/MODIFIED |
| approved_question_id | BIGINT UNSIGNED | Link to approved question |
| quality_score | DECIMAL(5,2) | AI confidence score |

---

## 5. Parent Engagement

### 5.1 `sch_parent_notification_prefs`
**Purpose:** Parent notification preferences.

| Column | Type | Description |
|--------|------|-------------|
| parent_id | BIGINT UNSIGNED | Parent user |
| student_id | BIGINT UNSIGNED | Child |
| notify_quiz_assigned | TINYINT(1) | Notify on assignment |
| notify_low_score | TINYINT(1) | Alert on low scores |
| low_score_threshold | TINYINT UNSIGNED | Threshold percentage |
| preferred_channel | ENUM | EMAIL/SMS/PUSH/WHATSAPP |
| quiet_hours_start/end | TIME | Do not disturb window |

---

### 5.2 `sch_parent_activity_log`
**Purpose:** Track parent engagement with student data.

| Column | Type | Description |
|--------|------|-------------|
| parent_id | BIGINT UNSIGNED | Parent user |
| student_id | BIGINT UNSIGNED | Child |
| activity_type | ENUM | VIEW_DASHBOARD/VIEW_REPORT/VIEW_QUIZ/etc. |
| activity_timestamp | TIMESTAMP | When viewed |

---

## 6. Assessment Templates & Blueprints

### 6.1 `sch_assessment_templates`
**Purpose:** Reusable assessment structures.

| Column | Type | Description |
|--------|------|-------------|
| name | VARCHAR(150) | Template name |
| template_type | ENUM | QUIZ/ASSESSMENT/EXAM/HOMEWORK |
| blueprint | JSON | Structure definition |
| usage_count | INT UNSIGNED | Times used |
| is_public | TINYINT(1) | Shareable flag |

**Blueprint Example:**
```json
{
  "sections": [
    {"name": "Part A", "question_count": 10, "marks_each": 1, "complexity": "EASY"},
    {"name": "Part B", "question_count": 5, "marks_each": 3, "complexity": "MEDIUM"}
  ]
}
```

---

### 6.2 `sch_question_paper_blueprints`
**Purpose:** Board exam style paper patterns.

| Column | Type | Description |
|--------|------|-------------|
| name | VARCHAR(150) | Blueprint name |
| board_id | BIGINT UNSIGNED | Education board |
| paper_pattern | JSON | Pattern definition |
| is_board_pattern | TINYINT(1) | Official pattern flag |
| source | VARCHAR(100) | e.g., "CBSE 2024" |

---

## 7. Question Quality & Feedback

### 7.1 `sch_question_feedback`
**Purpose:** Collect feedback on question quality.

| Column | Type | Description |
|--------|------|-------------|
| question_id | BIGINT UNSIGNED | Question reference |
| user_type | ENUM | STUDENT/TEACHER |
| feedback_type | ENUM | DIFFICULTY/CLARITY/ERROR/SUGGESTION/APPRECIATION |
| rating | TINYINT UNSIGNED | 1-5 rating |
| is_resolved | TINYINT(1) | Resolution status |

---

### 7.2 `sch_question_usage_stats`
**Purpose:** Monthly question usage analytics.

| Column | Type | Description |
|--------|------|-------------|
| question_id | BIGINT UNSIGNED | Question reference |
| year_month | CHAR(7) | YYYY-MM |
| times_used | INT UNSIGNED | Usage count |
| times_answered_correctly | INT UNSIGNED | Correct answers |
| avg_time_seconds | INT UNSIGNED | Average time |

---

## 8. Exam Scheduling

### 8.1 `sch_academic_calendar`
**Purpose:** Academic events calendar.

| Column | Type | Description |
|--------|------|-------------|
| event_type | ENUM | EXAM/QUIZ_WEEK/REVISION/HOLIDAY/PTM/ACTIVITY |
| title | VARCHAR(150) | Event name |
| start_date/end_date | DATE | Event period |
| class_ids | JSON | Applicable classes |
| is_school_wide | TINYINT(1) | Applies to all |

---

### 8.2 `sch_exam_seat_allocation`
**Purpose:** Exam room and seat assignments.

| Column | Type | Description |
|--------|------|-------------|
| exam_id | BIGINT UNSIGNED | Exam reference |
| student_id | BIGINT UNSIGNED | Student |
| room_id | INT UNSIGNED | Room reference |
| seat_number | VARCHAR(20) | Seat identifier |
| row_number | TINYINT UNSIGNED | Row number |

---

## 9. Advanced Analytics & Predictions

### 9.1 `sch_performance_predictions`
**Purpose:** AI-based performance predictions.

| Column | Type | Description |
|--------|------|-------------|
| student_id | BIGINT UNSIGNED | Student |
| subject_id | BIGINT UNSIGNED | Subject |
| prediction_type | ENUM | TERM_END/ANNUAL/BOARD/TOPIC |
| predicted_score | DECIMAL(5,2) | Predicted % |
| confidence_level | DECIMAL(5,2) | AI confidence |
| prediction_factors | JSON | Contributing factors |
| actual_score | DECIMAL(5,2) | Actual result (post-exam) |
| accuracy | DECIMAL(5,2) | Prediction accuracy |

---

### 9.2 `sch_at_risk_alerts`
**Purpose:** Early warning for at-risk students.

| Column | Type | Description |
|--------|------|-------------|
| student_id | BIGINT UNSIGNED | Student |
| alert_type | ENUM | FAILING/DECLINING/DISENGAGED/ATTENDANCE/BEHAVIOR |
| severity | ENUM | LOW/MEDIUM/HIGH/CRITICAL |
| alert_message | VARCHAR(500) | Alert description |
| status | ENUM | ACTIVE/ACKNOWLEDGED/RESOLVED/ESCALATED |

---

## 10. Comparative Analytics

### 10.1 `sch_school_benchmark_data`
**Purpose:** Cross-school performance comparisons.

| Column | Type | Description |
|--------|------|-------------|
| year_month | CHAR(7) | YYYY-MM |
| class_id | INT UNSIGNED | Class |
| subject_id | BIGINT UNSIGNED | Subject |
| school_avg_score | DECIMAL(5,2) | This school's average |
| city_avg_score | DECIMAL(5,2) | City average |
| state_avg_score | DECIMAL(5,2) | State average |
| national_avg_score | DECIMAL(5,2) | National average |
| school_percentile | DECIMAL(5,2) | School's percentile rank |

**Use Case:** Enables queries like "How does our Grade 10 Math performance compare to city/state averages?"

---

## Implementation Phases

### Phase 1: Foundation (Immediate)
- Assessment Templates
- Question Feedback
- Question Usage Stats

### Phase 2: Engagement (Month 2-3)
- Parent Engagement
- Exam Scheduling
- Academic Calendar

### Phase 3: Motivation (Month 4-5)
- Gamification (Achievements, Streaks)
- Leaderboards

### Phase 4: Intelligence (Month 6-8)
- AI Question Generation
- Performance Predictions
- At-Risk Alerts

### Phase 5: Collaboration (Month 9-12)
- Learning Pathways
- Peer Learning
- Comparative Analytics

---

**End of Data Dictionary**
