# PARAMETERS & FORMULAS BY STAGE

## STAGE 2: Requirement Consolidation

```sql
-- eligible_teacher_count
eligible_teacher_count = COUNT(DISTINCT stc.teacher_profile_id)
FROM sch_teacher_capabilities stc
WHERE stc.class_id = trc.class_id
  AND stc.subject_study_format_id = trc.subject_study_format_id
  AND (stc.section_id IS NULL OR stc.section_id = trc.section_id)
  AND stc.is_active = 1
  AND stc.effective_from <= @term_start_date
  AND stc.effective_to >= @term_end_date

-- class_priority_score (0-100)
class_priority_score = (
    CASE WHEN is_compulsory = 1 THEN 40 ELSE 0 END +
    CASE WHEN subject_type_id IN (SELECT id FROM sch_subject_types WHERE code = 'MAJOR') THEN 30 ELSE 0 END +
    (100 - (eligible_teacher_count * 10)) +  -- Fewer teachers = higher priority
    (required_weekly_periods * 5)  -- More periods = higher priority
)
```

## STAGE 3: Resource Availability

```sql
-- max_allocated_periods_weekly (per teacher)
max_allocated_periods_weekly = SUM(
    SELECT SUM(required_weekly_periods)
    FROM tt_requirement_consolidation trc
    WHERE trc.class_id IN (
        SELECT class_id FROM sch_teacher_capabilities stc
        WHERE stc.teacher_profile_id = tp.id
    )
    AND trc.subject_study_format_id IN (
        SELECT subject_study_format_id FROM sch_teacher_capabilities stc
        WHERE stc.teacher_profile_id = tp.id
    )
    GROUP BY trc.class_id, trc.subject_study_format_id
)

-- min_allocated_periods_weekly (per teacher)
min_allocated_periods_weekly = SUM(
    SELECT MAX(required_weekly_periods)
    FROM tt_requirement_consolidation trc
    WHERE trc.class_id IN (...)
    AND trc.subject_study_format_id IN (...)
    GROUP BY trc.class_id, trc.subject_study_format_id
)

-- teacher_availability_score
min_teacher_availability_score = (min_available_periods_weekly / NULLIF(min_allocated_periods_weekly, 0)) * 100
max_teacher_availability_score = (max_available_periods_weekly / NULLIF(max_allocated_periods_weekly, 0)) * 100
```

## STAGE 4: Activity Prioritization

```sql
-- difficulty_score (0-100, higher = harder to schedule)
difficulty_score = 
    -- Teacher scarcity (30%)
    LEAST(30, (100 / NULLIF(eligible_teacher_count, 0)) * 3) +
    
    -- Compulsory nature (20%)
    CASE WHEN is_compulsory = 1 THEN 20 ELSE 0 END +
    
    -- Period requirement (20%)
    LEAST(20, required_weekly_periods * 4) +
    
    -- Room constraint (15%)
    CASE WHEN compulsory_specific_room_type = 1 THEN 15 ELSE 0 END +
    
    -- Time constraints (15%)
    CASE WHEN preferred_periods_json IS NOT NULL OR avoid_periods_json IS NOT NULL THEN 15 ELSE 0 END

-- priority_score (for generation order)
priority_score = 
    (difficulty_score * 0.40) +
    ((100 - teacher_availability_score) * 0.25) +  -- Lower availability = higher priority
    (class_priority_score * 0.20) +
    (CASE WHEN spread_evenly = 1 THEN 15 ELSE 0 END)
```

## STAGE 5: Algorithm Parameters

```sql
-- For FET-based recursive swapping algorithm
algorithm_params = {
    -- Core parameters
    "max_recursion_depth": 14,  -- From FET (empirically found)
    "max_placement_attempts": 2000,  -- 2 * nInternalActivities
    "tabu_list_size": 100,  -- nInternalActivities * nHoursPerWeek
    
    -- Activity sorting (for step 1)
    "sort_method": "difficulty_score DESC",  -- Most difficult first
    
    -- Slot selection (for step 2b)
    "slot_selection": "conflicting_activities_count ASC",  -- Emptiest slots first
    
    -- Recursion optimization (for step 2e)
    "full_search_depth": 4,  -- Search all slots up to depth 4
    "best_only_depth": 5,    -- Only best slot from depth 5
    
    -- Conflict resolution
    "max_conflicts_per_slot": 3,  -- Maximum activities to swap out
    
    -- Termination conditions
    "timeout_seconds": 300,
    "max_iterations": 10000
}
```

## STAGE 7: Substitution Scoring

```sql
-- substitution_compatibility_score (0-100)
substitution_compatibility_score = 
    -- Subject proficiency (40%)
    (COALESCE(proficiency_percentage, 50) * 0.40) +
    
    -- Historical success (30%)
    (COALESCE(historical_success_ratio, 50) * 0.30) +
    
    -- Experience (15%)
    (LEAST(100, (teaching_experience_months / 12) * 10) * 0.15) +
    
    -- Availability (15%)
    (CASE 
        WHEN (max_available_periods_weekly - current_allocated) >= required_periods 
        THEN 100 
        ELSE ((max_available_periods_weekly - current_allocated) / required_periods) * 100 
    END * 0.15)

-- confidence_score (for recommendation)
confidence_score = 
    (substitution_compatibility_score * 0.60) +
    (teacher_reliability_score * 0.20) +
    (student_feedback_avg * 0.20)
```

