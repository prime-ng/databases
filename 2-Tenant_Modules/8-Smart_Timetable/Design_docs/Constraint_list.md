STANDARD CONSTRAINT CATALOG (ENTERPRISE-GRADE)
==============================================

This is the authoritative list of constraint types that your Timetable Engine will support, all stored in ONE table: tt_constraint.

Each constraint is defined by:

target_type

rule_json.type

Required parameters

Hard / Soft nature

Typical usage

🔹 A. TEACHER-LEVEL CONSTRAINTS
1. MAX_PERIODS_PER_DAY
    { "type": "MAX_PERIODS_PER_DAY", "value": 5 }

    Target: TEACHER
    Hard / Soft: Hard
    Meaning: Teacher cannot teach more than N periods/day

2. MAX_PERIODS_PER_WEEK
    { "type": "MAX_PERIODS_PER_WEEK", "value": 28 }

    Prevents overload
    Used for workload balancing

3. MAX_CONSECUTIVE_PERIODS
    { "type": "MAX_CONSECUTIVE_PERIODS", "value": 2 }

    Common for senior teachers

4. NO_CONSECUTIVE_PERIODS
    { "type": "NO_CONSECUTIVE_PERIODS", "value": true }

    Teacher must have a break between classes

5. UNAVAILABLE_PERIODS
    {
    "type": "UNAVAILABLE_PERIODS",
    "days": ["MON","WED"],
    "periods": [1,2]
    }

    Teacher not available in specific slots

6. PREFERRED_FREE_DAY
    { "type": "PREFERRED_FREE_DAY", "day": "FRI" }

    Soft constraint

    Used for optimization, not rejection

🔹 B. CLASS / SUBJECT (CLASS_GROUP) CONSTRAINTS
7. WEEKLY_PERIODS
    { "type": "WEEKLY_PERIODS", "value": 6 }

    Usually comes from tt_class_group_requirement

    Still evaluated as constraint

8. MAX_PERIODS_PER_DAY
    { "type": "MAX_PERIODS_PER_DAY", "value": 2 }

    Example: Maths not more than twice a day

9. NOT_FIRST_PERIOD
    { "type": "NOT_FIRST_PERIOD", "value": true }

    Avoid heavy subjects early morning

10. NOT_LAST_PERIOD
    { "type": "NOT_LAST_PERIOD", "value": true }

11. CONSECUTIVE_REQUIRED
    { "type": "CONSECUTIVE_REQUIRED", "count": 2 }

    Mandatory for labs / practicals

12. MIN_GAP_BETWEEN_CLASSES
    { "type": "MIN_GAP", "value": 1 }

    Avoids back-to-back same subject

🔹 C. ROOM-LEVEL CONSTRAINTS
13. ROOM_UNAVAILABLE
    {
    "type": "ROOM_UNAVAILABLE",
    "dates": ["2025-09-15"],
    "periods": [3,4]
    }

14. MAX_ROOM_USAGE_PER_DAY
    { "type": "MAX_ROOM_USAGE_PER_DAY", "value": 6 }

15. ROOM_EXCLUSIVE_USE
    { "type": "ROOM_EXCLUSIVE_USE", "value": true }

    No overlapping usage

🔹 D. MODE / EXAM-RELATED CONSTRAINTS
16. EXAM_ONLY_PERIODS
    { "type": "EXAM_ONLY_PERIODS", "periods": [1,2,3] }

17. NO_TEACHING_AFTER_EXAM
    { "type": "NO_TEACHING_AFTER_EXAM", "value": true }

    Reinforces teaching_after_exam_flag

18. EXAM_CUTOFF_TIME
    { "type": "EXAM_CUTOFF_TIME", "value": "12:00" }


🔹 E. GLOBAL / POLICY CONSTRAINTS
19. FIXED_PERIOD
    {
    "type": "FIXED_PERIOD",
    "day": "MON",
    "period": 1
    }

    Assembly / Prayer

20. NO_CLASSES_ON_DATE
    { "type": "NO_CLASSES_ON_DATE", "date": "2025-10-02" }

21. MAX_TEACHING_DAYS_PER_WEEK
    { "type": "MAX_TEACHING_DAYS", "value": 5 }


🔹 F. OPTIONAL / OPTIMIZATION (SOFT) CONSTRAINTS
22. PREFER_MORNING_CLASSES
    { "type": "PREFER_MORNING_CLASSES" }

23. PREFER_SAME_ROOM
    { "type": "PREFER_SAME_ROOM" }

24. BALANCED_DISTRIBUTION
    { "type": "BALANCED_DISTRIBUTION" }


Spreads classes evenly across week

How ALL of these fit into ONE TABLE
tt_constraint
-------------
target_type = TEACHER / CLASS_GROUP / ROOM / GLOBAL
target_id   = entity id (or NULL)
rule_json   = one of the above JSON blocks
is_hard     = 1 / 0
weight      = importance score


No schema change needed ever again.