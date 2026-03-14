QUERY - 
        Why Do need 'TEACHER_ROLE' in Dropdown_Table' when we already have 'sch_teachers' and then I have 'sch_teachers_profile', whcih capture which Teacher can Capable of Teaching which Subject for which Class and also wht is their Primary & Secondary Skill. One Teacher may have multiple Capabilities. I also have Rols Table where I can have Teacher, ASSISTANT_TEACHER, Trainee Teacher, Lab Supervisor etc
--------------------------------------------------------------------------------------------------------------------------------------------------
ANSWER -

Let’s separate the THREE DIFFERENT CONCEPTS (this is the key)

Right now, you actually have three distinct dimensions, and confusion happens when they’re mixed.

🔹 A. Teacher Capability (WHAT they can teach)

    Source: sch_teachers_profile
    This answers:
        “Is this teacher qualified to teach THIS subject, for THIS class, in THIS format?”
    Examples:
        Math → Class 7 → Lecture → Primary skill
        Science → Class 7 → Lab → Secondary skill

✅ This is eligibility, not timetable assignment.

🔹 B. Teacher System Role (WHO they are in the organization)

    Source: Your Roles table
    Examples:
        TEACHER
        ASSISTANT_TEACHER
        TRAINEE_TEACHER
        LAB_SUPERVISOR
    This answers:
        “What is this person’s employment / functional role?”

✅ This is identity, not per-period responsibility.

🔹 C. Teacher Assignment Role (WHAT they are doing in THIS PERIOD)

    This is the missing piece ❗
    This answers:
        “In THIS timetable cell, what responsibility is this teacher performing?”
    Examples in the SAME school:
        A full Teacher may act as:
            Main instructor in Period 2
            Substitute in Period 4
        A Lab Supervisor may act as:
            Assistant in a lab period
            Observer in another period

⚠️ This cannot be derived reliably from A or B.

❌ Problem 1 — Substitution breaks everything

    Scenario:
        Teacher A (Math teacher) is absent
        Teacher B (Math teacher) substitutes
    Both have:
        Same role = TEACHER
        Same capability
    But in the timetable:
        Teacher A → ABSENT
        Teacher B → SUBSTITUTE
    If you don’t store this explicitly at the cell level, you lose:
        Audit
        Reports
        Payroll / extra duty
        Historical accuracy

=========================================================================================================================================
QUERY - 
        HOW 'TIMETABLE_MODE' IN 'DROPDOWN_TABLE' IS DIFFERENT FROM 'tt_period_set'?
 in New Version - How "timetable_type" is different from "tt_period_set"?

ANSWER-
Short Answer (Essence)
    TIMETABLE_MODE("timetable_type") answers WHY / CONTEXT
    tt_period_set answers HOW / STRUCTURE

They solve different problems and must not be merged.

1️⃣ What is TIMETABLE_MODE("timetable_type")? (Context / Policy)

    TIMETABLE_MODE("timetable_type") defines the academic or operational context under which a timetable is running.

It answers:

    “Under what SCHOOL SITUATION is this timetable applicable?”

    Examples (Dropdown: key = 'TIMETABLE_MODE') (tt_timetable_type)
    Mode (Type)	        Meaning
    NORMAL	            Regular teaching days
    TODDLER_NORMAL	    Nursery/LKG/UKG routine
    UNIT_TEST_1	        Unit Test
    HALF_YEARLY	        Half-Yearly exams
    ANNUAL	            Annual exams
    BOARD	            Board exams
    EVENT_DAY	        Sports / Annual function

What MODE(Type) controls
    Whether teaching is allowed
    Whether exams exist
    Whether teaching after exam is allowed
    Which rules apply (tt_class_mode_rule)
    Which scheduler constraints activate
    Which run is being generated
    📌 Mode = Policy + Rules

2️⃣ What is tt_period_set? (Time Structure)

    tt_period_set defines the physical time layout of a day.

    It answers:
        “How does a school day look in terms of periods and timings?”

    Examples (Period Sets)
    Period Set	            Meaning
    NORMAL_8P	            8 periods (08:00–15:00)
    TODDLER_6P	            6 periods, starts late
    EXAM_3P	                3 long exam periods
    EXAM_2P	                2 exam periods only
    EVENT_DAY	            Custom blocks

    What PERIOD SET controls
        Number of periods
        Start / end time of each period
        Period order
        Period type (TEACHING / EXAM / BREAK)
        Grid structure of timetable UI
    📌 Period Set = Time Grid

=========================================================================================================================================

What tt_class_subgroup SHOULD represent
---------------------------------------

tt_class_subgroup = ONE combined teaching unit that appears in ONE timetable cell

Examples:
    French Optional (Class 7A + 7B + 7C together)
    Music (Classes 6 + 7 together)
    Robotics (Class 8A + 9A together)

So:
    ✔ One tt_class_subgroup → one period → one room → one teacher (or more)
    ❌ It should NOT directly store class/section lists
    ❌ It should NOT duplicate class-group identity logic



=========================================================================================================================================
How we will be capturing all tye of constraints into single table 'tim_constraint'?
-----------------------------------------------------------------------------------

We capture all types of constraints in tt_constraint by:
    - Separating “WHO the constraint applies to” from
    - “WHAT the constraint rule is”
    and storing the rule itself as structured JSON, not columns.

This is a deliberate, proven design used in scheduling engines, rule engines, and ML systems.

The mistake most ERP systems make is this:
    teacher_constraint
    class_constraint
    room_constraint
    exam_constraint
    subject_constraint

This leads to:
    ❌ 10+ tables
    ❌ duplicated columns
    ❌ rigid logic
    ❌ impossible future changes

Our requirement is dynamic:
    New exam rules
    New teaching patterns
    New compliance rules
    New analytics

So the only sustainable solution is:
    ONE constraint table + structured rules

Every constraint has three dimensions:
    WHO is constrained
    WHAT rule applies
    HOW strong the rule is

This maps perfectly to:
    target_type   → WHO
    target_id     → WHO (exact instance)
    rule_json     → WHAT
    is_hard       → HOW strict
    weight        → HOW important

tt_constraint
-------------
    id
    target_type    ENUM('TEACHER','CLASS_GROUP','ROOM','GLOBAL')
    target_id      BIGINT NULL
    is_hard        TINYINT
    weight         INT
    rule_json      JSON

This table does NOT encode meaning in columns
👉 meaning lives in rule_json.

Below are real examples how all constraint will be stored in the same table.
A. Teacher Constraints
    Example 1 — Max periods per day
        {
        "type": "MAX_PERIODS_PER_DAY",
        "value": 5
        }

        target_type = 'TEACHER'
        target_id   = sch_teachers.id
        is_hard     = 1

    Example 2 — No back-to-back periods
        {
        "type": "NO_CONSECUTIVE",
        "value": true
        }
    
    Example 3 — Teacher unavailable slots
        {
        "type": "UNAVAILABLE_PERIODS",
        "days": ["MON","WED"],
        "periods": [1,2]
        }

B. Class / Subject Constraints
    Example 4 — Weekly frequency
        {
        "type": "WEEKLY_PERIODS",
        "value": 6
        }

        (target = class_group)

    Example 5 — No first period
        {
        "type": "NOT_FIRST_PERIOD",
        "value": true
        }

    Example 6 — Lab must be consecutive
        {
        "type": "CONSECUTIVE_REQUIRED",
        "count": 2
        }

C. Room Constraints
    Example 7 — Room unavailable
        {
        "type": "ROOM_UNAVAILABLE",
        "dates": ["2025-10-12"],
        "periods": [3,4]
        }

    Example 8 — Max usage per day
        {
        "type": "MAX_ROOM_USAGE_PER_DAY",
        "value": 6
        }

D. Global / Policy Constraints
    Example 9 — No exams after 12 PM
        {
        "type": "EXAM_CUTOFF_TIME",
        "value": "12:00"
        }
        (target_type = GLOBAL, target_id = NULL)

    Example 10 — Assembly period is fixed
        {
        "type": "FIXED_PERIOD",
        "day": "MON",
        "period": 1
        }

E. Soft Optimization Constraints (VERY IMPORTANT)
    Example 11 — Prefer teacher free on Friday
        {
        "type": "PREFER_FREE_DAY",
        "day": "FRI"
        }

        is_hard = 0
        weight  = 80

        Scheduler tries to satisfy it, but may break it if needed.

How the Scheduler Uses This (Critical)
    Scheduler loop (simplified):
        for each candidate assignment:
        violations = []
        for each applicable constraint:
            if constraint violated:
            if is_hard:
                reject assignment
            else:
                score -= weight

        choose assignment with highest score

This is exactly how professional solvers work.

How constraints are FILTERED efficiently
----------------------------------------
    SELECT * FROM tt_constraint
    WHERE is_active = 1
    AND (
    (target_type = 'GLOBAL')
    OR (target_type = 'TEACHER' AND target_id = :teacher_id)
    OR (target_type = 'CLASS_GROUP' AND target_id = :class_group_id)
    OR (target_type = 'ROOM' AND target_id = :room_id)
    )

No joins. Fast. Indexed
This is enterprise-grade rule modeling, not a shortcut.

Validation & Governance (Important)
-----------------------------------
To avoid “garbage JSON”, we enforce:

    => At application level (Laravel)
        Constraint type enum registry
        JSON schema validation per type
        Admin UI per constraint type
        Preview impact before activation

    => At DB level
        target_type enum
        is_hard boolean

- This model supports every constraint we’ve received so far
- New constraints require ZERO DDL changes
- Scheduler logic stays clean and extensible

