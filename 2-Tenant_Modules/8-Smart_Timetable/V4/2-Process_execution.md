# Smart Timetable Generation Process

## Timetable Menu :
1. Pre-Requisites
2. Timetable Configuration
3. Timetable Masters
4. Timetable Requirement
5. Timetable Resource Availability
6. Timetable Constraint Engine
7. Timetable Operations
8. Timetable Generation
9. Manual Refinement
10. Report & Logs        --> (This include Audit & History)
11. Timetable Review & Publish
12. Substitute Management



------------------------------------------------------------------------------------------------------------------

When Start Timetable Generation process user will get dropdown to select - 
 - academic_term_id [sch_academic_term.term_code] where [sch_academic_term.is_active] = 1
 - Timetable Type [tt_timetable_type.code] where [tt_timetable_type.is_active] = 1

## 0. Pre-requisite
When user select Academic Term we will fetch below parameter from [sch_academic_term]
      Set: $academic_term_id from [sch_academic_term.id]
      Set: $academic_session_id from [sch_academic_term.academic_session_id]
      Set: $academic_year_start_date [sch_academic_term.start_date]
      Set: $academic_year_end_date [sch_academic_term.end_date]
      Set: $term_code [sch_academic_term.term_code]
      Set: $Academic_term_start_date [sch_academic_term.start_date]
      Set: $Academic_term_end_date [sch_academic_term.end_date]
We will fetch below parameters from [tt_timetable_type]
      Set: $timetable_type_id from [tt_timetable_type.id]
      Set: $timetable_type_code [tt_timetable_type.code]
      Set: $timetable_type_name [tt_timetable_type.name]
      Set: $timetable_from_date [tt_timetable_type.`effective_from_date`]
      Set: $timetable_to_date [tt_timetable_type.effective_to_date]
      Set: $max_weekly_periods_allowed_to_allocate [tt_timetable_type.max_weekly_periods_can_be_allocated_to_teacher]
      Set: $min_weekly_periods_can_be_allocated_to_teacher [tt_timetable_type.min_weekly_periods_can_be_allocated_to_teacher]


## 1. Generate Timetable Slot Requirement

 ### 1.1 Generate Timetable Slot Requirement [tt_slot_requirement]
 -----------------------------------------------------------------
 Step 1: Create Records where [tt_class_timetable_type_jnt.applies_to_all_sections] = 0
   Select all the Records from [tt_class_timetable_type_jnt] where 
      [tt_class_timetable_type_jnt.academic_term_id] = [$academic_term_id] AND
      [tt_class_timetable_type_jnt.timetable_type_id] = [$timetable_type_id] AND
      [tt_class_timetable_type_jnt.applies_to_all_sections] = 0 AND
      [tt_class_timetable_type_jnt.is_active] = 1
   Insert all those records into [tt_slot_requirement]
 Step 2: Create Records where [tt_class_timetable_type_jnt.applies_to_all_sections] = 1
   Select all the Records from [tt_class_timetable_type_jnt] where 
      [tt_class_timetable_type_jnt.academic_term_id] = [$academic_term_id] AND
      [tt_class_timetable_type_jnt.timetable_type_id] = [$timetable_type_id] AND
      [tt_class_timetable_type_jnt.applies_to_all_sections] = 1 AND
      [tt_class_timetable_type_jnt.is_active] = 1
   Loop through all the records from [tt_class_timetable_type_jnt]
      Select * from [sch_class_section_jnt] where 
         [sch_class_section_jnt.class_id] = [tt_class_timetable_type_jnt.class_id] AND
         [sch_class_section_jnt.is_active] = 1
      Loop through all the records from [sch_class_section_jnt]
         Insert all records from [tt_class_timetable_type_jnt] into [tt_slot_requirement] for each 
            section_id in [sch_class_section_jnt]
      EndLoop
   EndLoop


## 2. Generate (tt_class_subject_groups & tt_class_subject_subgroups)

 ### 2.1 Fill Data into [tt_class_requirement_groups & tt_class_requirement_subgroups]
 -------------------------------------------------------------------------------------
 Step 1: Insert Records into [tt_class_requirement_groups] -
   Select * from [sch_class_groups_jnt] where [sch_class_groups_jnt.is_compulsory] = 1 AND [sch_class_groups_jnt.is_active] = 1
   Insert all those records into [tt_class_requirement_groups]
 Step 2: Insert Records into [tt_class_requirement_subgroups] -
   Select * from [sch_class_groups_jnt] where [sch_class_groups_jnt.is_compulsory] = 0 AND [sch_class_groups_jnt.is_active] = 1
   Insert all those records into [tt_class_requirement_subgroups]

 ### 2.2 Class_House_Room in [tt_class_requirement_groups.class_house_room_id]
 -------------------------------------------------------------------------	
 Get: [sch_class_section_jnt.class_house_room_id] from [sch_class_section_jnt] where 
   [sch_class_section_jnt.class_id] = [tt_class_requirement_groups.class_id] AND
   [sch_class_section_jnt.section_id] = [tt_class_requirement_groups.section_id] AND
   [sch_class_section_jnt.is_active] = 1
 update [tt_class_requirement_groups] with [sch_class_section_jnt.class_house_room_id]

 ### 2.3 Class_House_Room in [tt_class_requirement_subgroups.class_house_room_id]
 ----------------------------------------------------------------------------
 Get: [sch_class_section_jnt.class_house_room_id] from [sch_class_section_jnt] where 
   [sch_class_section_jnt.class_id] = [tt_class_requirement_subgroups.class_id] AND
   [sch_class_section_jnt.section_id] = [tt_class_requirement_subgroups.section_id] AND
   [sch_class_section_jnt.is_active] = 1
 update [tt_class_requirement_subgroups] with [sch_class_section_jnt.class_house_room_id]

 ### 2.4 Update [sch_class_section_jnt.actual_total_student]
 -----------------------------------------------------------------
UPDATE sch_class_section_jnt cst
SET cst.actual_total_student = (
    SELECT COUNT(sas.id)
    FROM std_student_academic_sessions sas
    WHERE sas.academic_session_id = [$academic_session_id]
        AND sas.class_id = cst.class_id
        AND sas.section_id = cst.section_id
        AND sas.is_active = 1
);

 ### 2.5 Update Total_Student in [tt_class_requirement_groups.student_count]
 ---------------------------------------------------------------------------
UPDATE tt_class_requirement_groups tcrg
SET tcrg.student_count = (
    SELECT cst.actual_total_student
    FROM sch_class_section_jnt cst
    WHERE cst.class_id = tcrg.class_id
        AND cst.section_id = tcrg.section_id
        AND cst.is_active = 1
    LIMIT 1
);

 ### 2.6 Update Total_Student in [tt_class_requirement_subgroups.student_count]
 ------------------------------------------------------------------------------
  UPDATE tt_class_requirement_subgroups tcr
  SET tcr.student_count = (
    SELECT COUNT(DISTINCT sas.id)
    FROM std_student_academic_sessions sas
    INNER JOIN sch_subject_group_subject_jnt sgsj 
        ON sgsj.subject_group_id = sas.subject_group_id
    INNER JOIN sch_subject_groups sg 
        ON sg.id = sgsj.subject_group_id
    WHERE sg.class_id = tcr.class_id
        AND (sg.section_id = tcr.section_id OR (sg.section_id IS NULL AND tcr.section_id IS NULL))
        AND sgsj.subject_study_format_id = tcr.subject_study_format_id
        AND sgsj.subject_id = tcr.subject_id
        AND sas.academic_session_id = (
            SELECT id 
            FROM sch_org_academic_sessions_jnt 
            WHERE is_current = 1 
            LIMIT 1
        )
        AND sas.count_for_timetable = TRUE  -- Much cleaner!
  );

 ### 2.7 Calculate EligibleTeachers Count [tt_class_requirement_groups.eligible_teacher_count]
 ---------------------------------------------------------------------------------------------
  UPDATE tt_class_requirement_groups tcr
  SET tcr.eligible_teacher_count = (
    SELECT COUNT(DISTINCT tc.id)
    FROM sch_teacher_capabilities tc
    WHERE tc.class_id = tcr.class_id
        AND tc.subject_study_format_id = tcr.subject_study_format_id
        AND tc.effective_from <= tcr.academic_term_start_date
        AND tc.effective_to >= tcr.academic_term_end_date
        AND tc.is_active = 1
  );

 ### 2.8 Calculate EligibleTeachers Count [tt_class_requirement_subgroups.eligible_teacher_count]
 ---------------------------------------------------------------------------------------------
  UPDATE tt_class_requirement_subgroups tcr
  SET tcr.eligible_teacher_count = (
    SELECT COUNT(DISTINCT tc.id)
    FROM sch_teacher_capabilities tc
    WHERE tc.class_id = tcr.class_id
        AND tc.subject_study_format_id = tcr.subject_study_format_id
        AND tc.effective_from <= tcr.academic_term_start_date
        AND tc.effective_to >= tcr.academic_term_end_date
        AND tc.is_active = 1
  );


## 3. Requirement Consolidation [tt_requirement_consolidation]

### 3.1 Truncate [tt_requirement_consolidation]
-------------------------------------------
   Remove all the records from [tt_requirement_consolidation]

### 3.2 Fill [tt_requirement_consolidation]
-------------------------------------------

try {
   DB::transaction(function () use ($academicTermId, $timetableTypeId) {

      // Step 1: Insert from tt_class_requirement_groups (The "Main" Groups)
      // -------------------------------------------------------------------
      DB::table('tt_requirement_consolidation')->insertUsing([
            'class_requirement_group_id', 'class_id', 'section_id', 'subject_id', 
            'study_format_id', 'subject_type_id', 'subject_study_format_id', 
            'class_house_room_id', 'student_count', 'eligible_teacher_count',
            'is_compulsory', 'required_weekly_periods', 'min_periods_per_week', 
            'max_periods_per_week', 'max_per_day', 'min_per_day', 
            'min_gap_between_periods', 'allow_consecutive_periods', 
            'max_consecutive_periods', 'class_priority_score', 
            'compulsory_specific_room_type', 'required_room_type_id', 'required_room_id',
            'academic_term_id', 'timetable_type_id', 'is_active'
        ], function ($query) use ($academic_term_id, $timetable_type_id, $isActive) {
            $query->select([
                'g.id', 'g.class_id', 'g.section_id', 'g.subject_id',
                'g.study_format_id', 'g.subject_type_id', 'g.subject_study_format_id',
                'g.class_house_room_id', 'g.student_count', 'g.eligible_teacher_count',
                'j.is_compulsory', 'j.required_weekly_periods', 'j.min_weekly_periods',
                'j.max_weekly_periods', 'j.max_daily_periods', 'j.min_daily_periods',
                'j.min_gap_between_periods', 'j.allow_consecutive_periods',
                'j.max_consecutive_periods', 'j.priority_score',
                'j.compulsory_specific_room_type', 'j.required_room_type_id', 'j.required_room_id',
                DB::raw("$academic_term_id"), 
                DB::raw("$timetable_type_id"),
                DB::raw("$isActive")
            ])
         ->from('tt_class_requirement_groups as g')
         ->join('sch_class_groups_jnt as j', 'g.class_group_id', '=', 'j.id')
         ->whereNull('g.deleted_at');
      });

      // Step 2: Insert from tt_class_requirement_subgroups
      // --------------------------------------------------
      DB::table('tt_requirement_consolidation')->insertUsing([
            'class_requirement_subgroup_id', 'class_id', 'section_id', 'subject_id', 
            'study_format_id', 'subject_type_id', 'subject_study_format_id', 
            'class_house_room_id', 'student_count', 'eligible_teacher_count',
            'is_compulsory', 'required_weekly_periods', 'min_periods_per_week', 
            'max_periods_per_week', 'max_per_day', 'min_per_day', 
            'min_gap_between_periods', 'allow_consecutive_periods', 
            'max_consecutive_periods', 'class_priority_score', 
            'compulsory_specific_room_type', 'required_room_type_id', 'required_room_id',
            'is_shared_across_sections', 'is_shared_across_classes',
            'academic_term_id', 'timetable_type_id', 'is_active'
         ], function ($query) use ($academic_term_id, $timetable_type_id, $isActive) {
            $query->select([
                's.id', 's.class_id', 's.section_id', 's.subject_id',
                's.study_format_id', 's.subject_type_id', 's.subject_study_format_id',
                's.class_house_room_id', 's.student_count', 's.eligible_teacher_count',
                'j.is_compulsory', 'j.required_weekly_periods', 'j.min_weekly_periods',
                'j.max_weekly_periods', 'j.max_daily_periods', 'j.min_daily_periods',
                'j.min_gap_between_periods', 'j.allow_consecutive_periods',
                'j.max_consecutive_periods', 'j.priority_score',
                'j.compulsory_specific_room_type', 'j.required_room_type_id', 'j.required_room_id',
                's.is_shared_across_sections', 's.is_shared_across_classes',
                DB::raw("$academic_term_id"), 
                DB::raw("$timetable_type_id"),
                DB::raw("$isActive")
            ])
         ->from('tt_class_requirement_subgroups as s')
         ->join('sch_class_groups_jnt as j', 's.class_group_id', '=', 'j.id')
         ->whereNull('s.deleted_at');
      });
   });

   return "Consolidation Successful";
} catch (\Exception $e) {
   return "Error: " . $e->getMessage();
}
   
### 3.3 Fill Additional Parameters [tt_requirement_consolidation_details]
-------------------------------------------------------------------------
Make All Editable Fiedls available to the user for Modification AND
Mannual Entry for - [`preferred_periods_json`], [`avoid_periods_json`], [`spread_evenly`]



----------------------------------------------------------------------------------------------------------------------------------------------------------



## 4. Timetable Resource Availability

### 4.1 Truncate [tt_teacher_availability]
-------------------------------------------
   Remove all the records from [tt_teacher_availability]

### 4.2 Fill tt_teacher_availability (tt_teacher_availability)
--------------------------------------------------------------

As tt_requirement_consolidation doesn't have teacher_profile_id. To populate tt_teacher_availability, we need to:
  - First Fill the data from [tt_requirement_consolidation], [sch_teacher_profile], [sch_teacher_capabilities] into [tt_teacher_availability] for the fields that are common in Source & Target
  - Identify which teachers are eligible for each requirement (based on Class+Subject+Study_Format)
  - Then update [tt_teacher_availability] for each record with eligible teacher count

#### Step 1: Truncate [tt_teacher_availability]
------------------------------------------------
   Remove all the records from [tt_teacher_availability]

#### Step 2: Fill Records into [tt_teacher_availability] from [tt_requirement_consolidation], [sch_teacher_profile],  [sch_teacher_capabilities]
-------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO `tt_teacher_availability` (
  -- From `tt_requirement_consolidation`
    `requirement_consolidation_id`, `class_id`, `section_id`, `subject_study_format_id`, `teacher_profile_id`, `required_weekly_periods`
    -- From `sch_teacher_profile`
    `is_full_time`, `preferred_shift`, `capable_handling_multiple_classes`, `can_be_used_for_substitution`,   `certified_for_lab`,`max_available_periods_weekly`, `min_available_periods_weekly`, `max_allocated_periods_weekly`, `min_allocated_periods_weekly`, `can_be_split_across_sections`, `min_teacher_availability_score`, `max_teacher_availability_score`
    -- From `sch_teacher_capabilities`
    `proficiency_percentage`, `teaching_experience_months`, `is_primary_subject`, `competency_level`, `priority_order`, `priority_weight`, `scarcity_index`, `is_hard_constraint`, `allocation_strictness`, `override_priority`, `override_reason`, `historical_success_ratio`, `last_allocation_score`,
    -- Effectivity (only from capabilities)
    `effective_from`, `effective_to`
SELECT 
    -- From `tt_requirement_consolidation`
    `trc.id` AS `requirement_consolidation_id`, `trc.class_id`, `trc.section_id`, `trc.subject_study_format_id`, `stc.teacher_profile_id`, `trc.required_weekly_periods`,
    -- From `sch_teacher_profile` (NULL if no teacher found)
    `stp.is_full_time`, `stp.preferred_shift`, `stp.capable_handling_multiple_classes`, `stp.can_be_used_for_substitution`, `stp.certified_for_lab`,`stp.max_available_periods_weekly`, `stp.min_available_periods_weekly`, `stp.max_allocated_periods_weekly`, `stp.min_allocated_periods_weekly`, `stp.can_be_split_across_sections`, `stp.min_teacher_availability_score`, `stp.max_teacher_availability_score`,
    -- From `sch_teacher_capabilities` (NULL if no capability found)
    `stc.proficiency_percentage`, `stc.teaching_experience_months`, `stc.is_primary_subject`, `stc.competency_level`, `stc.priority_order`, `stc.priority_weight`, `stc.scarcity_index`, `stc.is_hard_constraint`, `stc.allocation_strictness`, `stc.override_priority`, `stc.override_reason`, `stc.historical_success_ratio`, `stc.last_allocation_score`,
    -- Effectivity - ONLY from `sch_teacher_capabilities` (NULL if no capability)
    `stc.effective_from`, `stc.effective_to`
FROM 
    `tt_requirement_consolidation` trc
    LEFT JOIN `sch_teacher_capabilities` stc ON 
        `trc.class_id` = `stc.class_id` 
        AND (`trc.section_id` = `stc.section_id` OR (`trc.section_id` IS NULL AND `stc.section_id` IS NULL))
        AND `trc.subject_study_format_id` = `stc.subject_study_format_id`
        AND `stc.is_active` = 1
        AND (`stc.effective_from` IS NULL OR `stc.effective_from` <= @timetable_to_date)
        AND (`stc.effective_to` IS NULL OR `stc.effective_to` >= @timetable_from_date)
    LEFT JOIN `sch_teacher_profile` stp ON `stp.id` = `stc.teacher_profile_id` 
        AND `stp.is_active` = 1
WHERE 
    `trc.is_active` = 1
ORDER BY 
    `trc.id`,
    `stc.teacher_profile_id` IS NOT NULL DESC,  -- Records with teachers first
    `stc.priority_order` ASC,
    `stc.proficiency_percentage` DESC;

#### Step 3: Update in [max_allocated_periods_weekly] from [min_allocated_periods_weekly] in [tt_teacher_availability]
----------------------------------------------------------------------------------------------------------------------

UPDATE sch_teacher_profile tp
INNER JOIN (
    -- Calculate max and min periods per teacher
    SELECT tc.teacher_profile_id, SUM(class_subject_total.max_periods) AS total_max_periods, SUM(class_subject_total.min_periods) AS total_min_periods 
    FROM sch_teacher_capabilities tc
    INNER JOIN (SELECT class_id, subject_study_format_id, SUM(required_weekly_periods) AS max_periods, MAX(required_weekly_periods) AS min_periods FROM tt_requirement_consolidation WHERE is_active = 1 GROUP BY class_id, subject_study_format_id) class_subject_total ON class_subject_total.class_id = tc.class_id AND class_subject_total.subject_study_format_id = tc.subject_study_format_id
    WHERE tc.is_active = 1 GROUP BY tc.teacher_profile_id ) period_totals ON period_totals.teacher_profile_id = tp.id
SET 
    tp.max_allocated_periods_weekly = period_totals.total_max_periods,
    tp.min_allocated_periods_weekly = period_totals.total_min_periods
WHERE tp.is_active = 1;

This will Update `max_allocated_periods_weekly` = Sum of required_weekly_periods across ALL sections for each Class+Subject_Study_Format
`min_allocated_periods_weekly` = Take the MAX (largest single section requirement) for each Class+Subject_Study_Format

`min_teacher_availability_score` = (min_available_periods_weekly / min_allocated_periods_weekly) * 100
`max_teacher_availability_score` = (max_available_periods_weekly / max_allocated_periods_weekly) * 100

B - Calculate total of All Allocated Classes+Subject_Study_Format in the same way as (A)
C - Get Total Weekly Periods (Minimum) he is avaialable (6 * Available Days) = 6*6 = 36
D - Get Total Weekly Periods (Maximum) he is avaialable (8 * Available Days) = 8*6 = 48
E - min_teacher_availability_score = (C/A)*100 = (36/A)*100
F - max_teacher_availability_score = (D/A)*100 = (48/A)*100


#### Step 4: Calculate [min_teacher_availability_score] and [min_teacher_availability_score] in [tt_teacher_availability]
-------------------------------------------------------------------------------------------------------------------------
UPDATE sch_teacher_profile tp
INNER JOIN (
    SELECT tc.teacher_profile_id, SUM(class_subject_total.max_periods) AS total_max_periods, SUM(class_subject_total.min_periods) AS total_min_periods FROM sch_teacher_capabilities tc INNER JOIN (SELECT class_id, subject_study_format_id, SUM(required_weekly_periods) AS max_periods, MAX(required_weekly_periods) AS min_periods FROM tt_requirement_consolidation WHERE is_active = 1 GROUP BY class_id, subject_study_format_id) class_subject_total ON class_subject_total.class_id = tc.class_id AND class_subject_total.subject_study_format_id = tc.subject_study_format_id WHERE tc.is_active = 1 GROUP BY tc.teacher_profile_id) period_totals ON period_totals.teacher_profile_id = tp.id
SET 
    tp.max_allocated_periods_weekly = period_totals.total_max_periods, tp.min_allocated_periods_weekly = period_totals.total_min_periods, tp.min_teacher_availability_score = 
        CASE 
            WHEN period_totals.total_min_periods > 0 
            THEN (tp.min_available_periods_weekly / period_totals.total_min_periods) * 100
            ELSE NULL 
        END,
    tp.max_teacher_availability_score = 
        CASE 
            WHEN period_totals.total_max_periods > 0 
            THEN (tp.max_available_periods_weekly / period_totals.total_max_periods) * 100
            ELSE NULL 
        END
WHERE tp.is_active = 1;






#### Step 5: Update in [tt_teacher_availability] 
-------------------------------------------------






   Select all the Records from [tt_teacher_availability]
   Loop through all the records from [tt_teacher_availability]
      Calculate [min_teacher_availability_score] and [max_teacher_availability_score] from [sch_teacher_capabilities]
   EndLoop


    -- Preference Fields (NULL if no teacher)
    CASE 
        WHEN `stc.teacher_profile_id` IS NULL THEN 0
        WHEN `stc.is_primary_subject` = 1 OR `stc.proficiency_percentage` >= 80 OR `stc.competancy_level` IN ('Advanced', 'Expert')
        THEN 1 ELSE 0 
    END,
    
    CASE 
        WHEN `stc.teacher_profile_id` IS NULL THEN 0
        WHEN `stc.priority_weight` >= 8 OR `stc.scarcity_index` <= 3 OR `stc.allocation_strictness` = 'hard'
        THEN 1 ELSE 0 
    END,
    
    CASE 
        WHEN `stc.teacher_profile_id` IS NULL THEN NULL
        ELSE ROUND(
            COALESCE(`stc.proficiency_percentage`, 50) * 0.4 + 
            COALESCE(`stc.priority_weight`, 5) * 10 * 0.3 + 
            CASE `stc.competancy_level`
                WHEN 'Expert' THEN 100 
                WHEN 'Advanced' THEN 80 
                WHEN 'Intermediate' THEN 60 
                ELSE 40 
            END * 0.2 + 
            COALESCE(`stc.historical_success_ratio`, 50) * 0.1
        )
    END,
    
    `stc.effective_from`,
    `stc.effective_to`,
    
    -- Availability scores (calculate based on teacher count per requirement)
    CASE 
        WHEN `stc.teacher_profile_id` IS NULL THEN 0.00
        ELSE 1.00 
    END,
    CASE 
        WHEN `stc.teacher_profile_id` IS NULL THEN 0.00
        ELSE 1.00 
    END,
    
    -- is_active - always 1 for requirement records, even with no teacher
    1
    


#### Step 6: Update in [tt_teacher_availability] 
------------------------------------------------------------------------------------------------------------------
      set [day1_available_period_count], [day2_available_period_count], [day3_available_period_count], [day4_available_period_count],
          [day5_available_period_count], [day6_available_period_count], [day7_available_period_count]
   Select all the Records from [tt_teacher_availability]
   Loop through all the records from [tt_teacher_availability]
      Calculate [min_teacher_availability_score] and [max_teacher_availability_score] from [sch_teacher_capabilities]
   EndLoop


#### Step 7: Update in [tt_teacher_availability] from [tt_teacher_unavailable]
------------------------------------------------------------------------------------------------------------------
   set [day1_available_period_count], [day2_available_period_count], [day3_available_period_count], [day4_available_period_count],
       [day5_available_period_count], [day6_available_period_count], [day7_available_period_count]
   Select all the Records from [tt_teacher_availability]
   Loop through all the records from [tt_teacher_availability]
      Calculate [min_teacher_availability_score] and [max_teacher_availability_score] from [sch_teacher_capabilities]
   EndLoop


#### Step 8: Mannual modification in [tt_teacher_availability] for [is_primary_teacher], [is_preferred_teacher], [preference_score]
------------------------------------------------------------------------------------------------------------------
Important - Auto Calculate belwo Fields:
  In [sch_teacher_profile]
      [max_allocated_periods_weekly], [min_allocated_periods_weekly], [teacher_availability_ratio], [min_teacher_availability_score], [max_teacher_availability_score]

  In [sch_teacher_capabilities]
    - [scarcity_index]

  In [tt_teacher_availability]
    [is_primary_teacher], [is_preferred_teacher], [preference_score], [min_teacher_availability_score], [max_teacher_availability_score]

   - [teacher_availability_ratio] in [sch_teacher_profile]
   -  in [tt_teacher_availability]




#### Step 9: This will be final step to calculated Final Teacher Preference Score
---------------------------------------------------------------------------------
Update [is_primary_teacher], [is_preferred_teacher], [preference_score] in [tt_teacher_availability]
   Update in [tt_teacher_availability] as ta from [sch_teacher_capabilities] as tc
   set [teacher_availability_ratio] = (SELECT COUNT(DISTINCT teacher_profile_id) AS no_of_teachers_assigned FROM 
       [sch_teacher_capabilities] WHERE tc.class_id = tp.class_id AND tc.subject_study_format_id = tp.subject_study_format_id AND (tc.effective_from IS NULL OR tc.effective_from <= $timetable_from_date) AND 
       (tc.effective_to IS NULL OR tc.effective_to >= $timetable_to_date) AND tc.is_active = 1 GROUP BY tc.class_id, tc.subject_study_format_id ORDER BY tc.class_id, tc.subject_study_format_id);
   
   Select all the Records from [tt_teacher_availability] with count of allocated periods
   Loop through all the records from [tt_teacher_availability]
      Update [teacher_availability_ratio] in [sch_teacher_capabilities] from [tt_teacher_availability]
   EndLoop



-------------------------------------------------------------
New Enhancement on Teachers Profile for Shailesh

Create a New View to Order Teachers Priority on the basis of Class+Subject+Study_Format
   - User will Select Class from Dropdown and then Will Select Subject+Study_Format from Dropdown
   - All the Teacher Allocated to the selected Class & Subject+Study_Format will be displayed
   - User Can Change the Order of the Teacher by Drag and Drop to set the Priority for the Teacher for that Class+Subject+Study_Format
   -  






   a. Check [is_active]
      If True
         Insert data into tt_teacher_assignment
      Else
         Insert data into tt_teacher_assignment
      Endif


----------------------------------------------------------------------------------
Old
----------------------------------------------------------------------------------
#### Step 2: Fill Records into [tt_teacher_availability] from [tt_requirement_consolidation], [sch_teacher_profile],  [sch_teacher_capabilities]
-------------------------------------------------------------------------------------------------------------------------------------------
(Populate tt_teacher_availability with ALL requirements. LEFT JOIN ensures requirements with no teachers are also included)

INSERT INTO tt_teacher_availability (
    -- Key Fields
    requirement_consolidation_id, class_id, section_id, subject_study_format_id, teacher_profile_id, required_weekly_periods
    -- From sch_teacher_profile
    is_full_time, preferred_shift, capable_handling_multiple_classes, can_be_used_for_substitution,   certified_for_lab,max_available_periods_weekly, min_available_periods_weekly, max_allocated_periods_weekly, min_allocated_periods_weekly, can_be_split_across_sections, min_teacher_availability_score, max_teacher_availability_score
    -- From sch_teacher_capabilities
    proficiency_percentage, teaching_experience_months, is_primary_subject, competency_level, priority_order, priority_weight, scarcity_index, is_hard_constraint, allocation_strictness, override_priority, override_reason, historical_success_ratio, last_allocation_score,
    -- Effectivity (only from capabilities)
    effective_from, effective_to
)
SELECT 
    -- Key Fields from requirement (ALWAYS populated)
    trc.id AS requirement_consolidation_id, stc.teacher_profile_id,  -- NULL if no teacher found
    trc.class_id, trc.section_id, trc.subject_study_format_id, trc.academic_term_id, trc.timetable_type_id, trc.required_weekly_periods
    -- From sch_teacher_profile (NULL if no teacher found)
    stp.is_full_time, stp.preferred_shift, stp.capable_handling_multiple_classes, stp.can_be_used_for_substitution, stp.certified_for_lab,stp.max_available_periods_weekly, stp.min_available_periods_weekly, stp.max_allocated_periods_weekly, stp.min_allocated_periods_weekly, stp.can_be_split_across_sections, stp.min_teacher_availability_score, stp.max_teacher_availability_score,
    -- From sch_teacher_capabilities (NULL if no capability found)
    stc.proficiency_percentage, stc.teaching_experience_months, stc.is_primary_subject, stc.competency_level, stc.priority_order, stc.priority_weight, stc.scarcity_index, stc.is_hard_constraint, stc.allocation_strictness, stc.override_priority, stc.override_reason, stc.historical_success_ratio, stc.last_allocation_score,
    -- Effectivity - ONLY from sch_teacher_capabilities (NULL if no capability)
    stc.effective_from, stc.effective_to
    
FROM 
    tt_requirement_consolidation trc
    LEFT JOIN sch_teacher_capabilities stc ON 
        trc.class_id = stc.class_id 
        AND (trc.section_id = stc.section_id OR (trc.section_id IS NULL AND stc.section_id IS NULL))
        AND trc.subject_study_format_id = stc.subject_study_format_id
        AND stc.is_active = 1
        AND (stc.effective_from IS NULL OR stc.effective_from <= @timetable_to_date)
        AND (stc.effective_to IS NULL OR stc.effective_to >= @timetable_from_date)
    LEFT JOIN sch_teacher_profile stp ON stp.id = stc.teacher_profile_id 
        AND stp.is_active = 1
    
WHERE 
    -- Only filter active requirements
    trc.is_active = 1;

--------------------------------------------------------------------------------------
   Select * from `tt_requirement_consolidation` as `trc` where `trc.is_active` = 1
   Loop through all the records from `tt_requirement_consolidation`
      Select `stc.*`, `stp.*`
      from `sch_teacher_capabilities` as `stc` LEFT JOIN `sch_teacher_profile` as `stp` on `stc.teacher_profile_id` = `stp.id` where 
         `trc.class_id` = `stc.class_id` AND `trc.study_format_id` = `stc.subject_study_format_id` AND
         `stc.is_active` = 1 AND (`stc.effective_from` IS NULL OR `stc.effective_from` <= `$timetable_to_date`) AND (`stc.effective_to` IS NULL OR `stc.effective_to` >= `$timetable_from_date`) AND `stc.is_active` = 1 AND `stp.is_active` = 1
      Loop through all the records from `sch_teacher_capabilities`
         Insert all records from `trc`, `stc`, `stp` into `tt_teacher_availability` for each trc.records
            -- from `tt_requirement_consolidation`
            `trc.id` AS `requirement_consolidation_id`, `stc.teacher_profile_id`,  -- NULL if no teacher found
            `trc.class_id`, `trc.section_id`, `trc.subject_study_format_id`, `trc.academic_term_id`, `trc.timetable_type_id`, `trc.required_weekly_periods`
            -- From `sch_teacher_profile` (NULL if no teacher found)
            `stp.is_full_time`, `stp.preferred_shift`, `stp.capable_handling_multiple_classes`, `stp.can_be_used_for_substitution`, `stp.certified_for_lab`,`stp.max_available_periods_weekly`, `stp.min_available_periods_weekly`, `stp.max_allocated_periods_weekly`, `stp.min_allocated_periods_weekly`, `stp.can_be_split_across_sections`, `stp.min_teacher_availability_score`, `stp.max_teacher_availability_score`,
            -- From `sch_teacher_capabilities` (NULL if no capability found)
            `stc.proficiency_percentage`, `stc.teaching_experience_months`, `stc.is_primary_subject`, `stc.competency_level`, `stc.priority_order`, `stc.priority_weight`, `stc.scarcity_index`, `stc.is_hard_constraint`, `stc.allocation_strictness`, `stc.override_priority`, `stc.override_reason`, `stc.historical_success_ratio`, `stc.last_allocation_score`,
            -- Effectivity - ONLY from `sch_teacher_capabilities` (NULL if no capability)
            `stc.effective_from`, `stc.effective_to`
      EndLoop
   EndLoop
--------------------------
Doing same by Sql Query -