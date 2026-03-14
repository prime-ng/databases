# ENHANCED PARAMETER FORMULAS
-----------------------------

## E1.1 Teacher Availability Score
```sql
-- Min Teacher Availability Score
min_teacher_availability_score = 
    (min_available_periods_weekly / NULLIF(min_allocated_periods_weekly, 0)) * 100

-- Max Teacher Availability Score  
max_teacher_availability_score = 
    (max_available_periods_weekly / NULLIF(max_allocated_periods_weekly, 0)) * 100

-- Weighted Availability Score
weighted_availability_score = 
    (min_teacher_availability_score * 0.3) + 
    (max_teacher_availability_score * 0.7)
```

## E1.2 Activity Difficulty Score
```sql
difficulty_score = 
    -- Teacher scarcity (inverse of eligible teachers)
    CASE 
        WHEN eligible_teacher_count = 0 THEN 100
        WHEN eligible_teacher_count = 1 THEN 90
        WHEN eligible_teacher_count = 2 THEN 75
        WHEN eligible_teacher_count = 3 THEN 60
        WHEN eligible_teacher_count = 4 THEN 45
        WHEN eligible_teacher_count = 5 THEN 30
        ELSE 15
    END * 0.35 +
    
    -- Compulsory nature
    (CASE WHEN is_compulsory = 1 THEN 20 ELSE 0 END) * 0.20 +
    
    -- Weekly period count
    (CASE 
        WHEN required_weekly_periods > 6 THEN 25
        WHEN required_weekly_periods > 4 THEN 20
        WHEN required_weekly_periods > 2 THEN 15
        ELSE 5
    END) * 0.15 +
    
    -- Room requirement
    (CASE WHEN compulsory_specific_room_type = 1 THEN 20 ELSE 0 END) * 0.15 +
    
    -- Constraint count
    (LEAST(constraint_count, 10) * 2) * 0.15
```

## E1.3 Activity Priority Score
```sql
priority_score = 
    -- Resource scarcity (25%)
    (COALESCE(resource_scarcity, 1) * 25) +
    
    -- Teacher scarcity (25%)
    (COALESCE(teacher_scarcity, 1) * 25) +
    
    -- Rigidity (inverse of allowed slots) (20%)
    ((1 - COALESCE(rigidity_score, 0)) * 20) +
    
    -- Workload balance (15%)
    (COALESCE(workload_balance, 1) * 15) +
    
    -- Subject difficulty (15%)
    (COALESCE(subject_difficulty_index, 1) * 15)

WHERE:
    resource_scarcity = required_resources / NULLIF(available_resources, 0)
    teacher_scarcity = required_teachers / NULLIF(available_teachers, 0)
    rigidity_score = allowed_slots / NULLIF(total_slots, 0)
    workload_balance = current_load / NULLIF(max_load, 0)
    subject_difficulty_index = pre-defined subject difficulty (1-10) / 10
```

## E1.4 Substitution Compatibility Score
```sql
compatibility_score = 
    -- Proficiency (40%)
    (proficiency_percentage * 0.40) +
    
    -- Historical success (30%)
    (historical_success_ratio * 0.30) +
    
    -- Experience (15%)
    (LEAST(teaching_experience_months / 120, 1) * 100 * 0.15) +
    
    -- Availability (15%)
    (CASE 
        WHEN current_workload < max_workload THEN 
            ((max_workload - current_workload) / max_workload) * 100 * 0.15
        ELSE 0
    END)
```












--------------------------------------------------------------------------------------------------------

**Purpose:** Measure teacher availability for specific time slots

**Formula:**
```
AvailabilityScore = (AvailabilityWeight * AvailabilityPoints) + 
                    (ConflictWeight * ConflictPoints) + 
                    (PreferenceWeight * PreferencePoints)
```

**Components:**

| Component | Description | Calculation |
|-----------|-------------|-------------|
| AvailabilityPoints | Available time slots | `COUNT(available_slots) / MAX_SLOTS * 100` |
| ConflictPoints | Unavailable time slots | `COUNT(unavailable_slots) / MAX_SLOTS * 100` |
| PreferencePoints | Preferred time slots | `COUNT(preferred_slots) / MAX_SLOTS * 100` |

**Weights:**
- AvailabilityWeight: 0.5
- ConflictWeight: -0.3
- PreferenceWeight: 0.2

**Example:**
```
AvailabilityScore = (0.5 * 80) + (-0.3 * 10) + (0.2 * 90)
                  = 40 - 3 + 18
                  = 55
```

