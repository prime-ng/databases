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
      Get: $academic_term_id from [sch_academic_term.id]
      Get: $academic_session_id from [sch_academic_term.academic_session_id]
      Get: $academic_year_start_date [sch_academic_term.start_date]
      Get: $academic_year_end_date [sch_academic_term.end_date]
      Get: $term_code [sch_academic_term.term_code]
      Get: $Academic_term_start_date [sch_academic_term.start_date]
      Get: $Academic_term_end_date [sch_academic_term.end_date]
We will fetch below parameters from [tt_timetable_type]
      Get: $timetable_type_id from [tt_timetable_type.id]
      Get: $timetable_type_code [tt_timetable_type.code]
      Get: $timetable_type_name [tt_timetable_type.name]
      Get: $timetable_from_date [tt_timetable_type.`effective_from_date`]
      Get: $timetable_to_date [tt_timetable_type.effective_to_date]

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

 ### 2.1 Fill Data into [tt_class_subject_groups & tt_class_subject_subgroups]
 -----------------------------------------------------------------------------
 Step 1: Insert Records into [tt_class_subject_groups] -
   Select * from [sch_class_groups_jnt] where [sch_class_groups_jnt.is_compulsory] = 1 AND [sch_class_groups_jnt.is_active] = 1
   Insert all those records into [tt_class_subject_groups]
 Step 2: Insert Records into [tt_class_subject_subgroups] -
   Select * from [sch_class_groups_jnt] where [sch_class_groups_jnt.is_compulsory] = 0 AND [sch_class_groups_jnt.is_active] = 1
   Insert all those records into [tt_class_subject_subgroups]

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
 update [sch_class_section_jnt]
 set [actual_total_student] = 
 Get: count of [std_student_academic_sessions.id] where 
   [std_student_academic_sessions.academic_session_id] = [$academic_session_id] AND
   [std_student_academic_sessions.class_id] = [tt_class_subject_groups.class_id] AND
   [std_student_academic_sessions.section_id] = [tt_class_subject_groups.section_id] AND
   [std_student_academic_sessions.is_active] = 1

 ### 2.5 Update Total_Student in [tt_class_requirement_groups.student_count]
 ---------------------------------------------------------------------------
 update [tt_class_requirement_groups]
 set [student_count] = 
 Get: [sch_class_section_jnt.actual_total_student] where 
   [sch_class_section_jnt.class_id] = [tt_class_requirement_groups.class_id] AND
   [sch_class_section_jnt.section_id] = [tt_class_requirement_groups.section_id] AND
   [sch_class_section_jnt.is_active] = 1

 ### 2.6 Update Total_Student in [tt_class_requirement_subgroups.student_count]
 ------------------------------------------------------------------------------
 update [tt_class_requirement_subgroups]
 set [student_count] = 
 Get: [sch_class_section_jnt.actual_total_student] where 
   [sch_class_section_jnt.class_id] = [tt_class_subject_subgroups.class_id] AND
   [sch_class_section_jnt.section_id] = [tt_class_subject_subgroups.section_id] AND
   [sch_class_section_jnt.is_active] = 1

 ### 2.7 Calculate EligibleTeachers Count [tt_class_requirement_groups.eligible_teacher_count]
 ---------------------------------------------------------------------------------------------
 update [tt_class_requirement_groups]
 set [eligible_teacher_count] = 
 Get: count of [sch_teacher_capabilities.id] where 
   [sch_teacher_capabilities.class_id] = [tt_class_requirement_groups.class_id] AND
   [sch_teacher_capabilities.subject_study_format_id] = [tt_class_requirement_groups.subject_study_format_id] AND
   [sch_teacher_capabilities.effective_from] <= [$Academic_term_start_date] AND
   [sch_teacher_capabilities.effective_to] >= [$Academic_term_end_date] AND
   [sch_teacher_capabilities.is_active] = 1

 ### 2.8 Calculate EligibleTeachers Count [tt_class_requirement_subgroups.eligible_teacher_count]
 ---------------------------------------------------------------------------------------------
 update [tt_class_requirement_subgroups]
 set [eligible_teacher_count] = 
 Get: count of [sch_teacher_capabilities.id] where 
   [sch_teacher_capabilities.class_id] = [tt_class_requirement_subgroups.class_id] AND
   [sch_teacher_capabilities.subject_study_format_id] = [tt_class_requirement_subgroups.subject_study_format_id] AND
   [sch_teacher_capabilities.effective_from] <= [$Academic_term_start_date] AND
   [sch_teacher_capabilities.effective_to] >= [$Academic_term_end_date] AND
   [sch_teacher_capabilities.is_active] = 1

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

 Step 1: Create Records in [tt_teacher_availability]
   Select all the Records from [tt_requirement_consolidation]
   Loop through all the records from [tt_requirement_consolidation]
      Update Key Fields in [tt_teacher_availability] from [tt_requirement_consolidation]
      set [requirement_consolidation_id], [class_id], [section_id], [subject_study_format_id] from 
         [tt_requirement_consolidation]
      set [preferred_shift], [capable_handling_multiple_classes], [can_be_used_for_substitution],
          [max_periods_daily], [min_periods_daily], [max_periods_weekly], [min_periods_weekly],
          [can_be_split_across_sections] 
          from [sch_teacher_profile]
      set [proficiency_percentage], [teaching_experience_months], [is_primary_subject], 
          [competancy_level], [priority_order], [priority_weight], [scarcity_index],
         [is_hard_constraint], [allocation_strictness], [override_priority], 
         [historical_success_ratio], [last_allocation_score], [effective_from], [effective_to] from [sch_teacher_capabilities]
   EndLoop

Step 2: Update [sch_teacher_profile.teacher_availability_ratio] 
   Update in [sch_teacher_profile] as tp from [sch_teacher_capabilities] as tc
   set [teacher_availability_ratio] = (SELECT COUNT(DISTINCT teacher_profile_id) AS no_of_teachers_assigned FROM 
       [sch_teacher_capabilities] WHERE tc.class_id = tp.class_id AND tc.subject_study_format_id = tp.subject_study_format_id AND (tc.effective_from IS NULL OR tc.effective_from <= $timetable_from_date) AND 
       (tc.effective_to IS NULL OR tc.effective_to >= $timetable_to_date) AND tc.is_active = 1 GROUP BY tc.class_id, tc.subject_study_format_id ORDER BY tc.class_id, tc.subject_study_format_id);
   
   Select all the Records from [tt_teacher_availability] with count of allocated periods
   Loop through all the records from [tt_teacher_availability]
      Update [teacher_availability_ratio] in [sch_teacher_capabilities] from [tt_teacher_availability]
   EndLoop








   Update in [tt_teacher_availability] 
      set [day1_available_period_count], [day2_available_period_count], [day3_available_period_count], [day4_available_period_count],
          [day5_available_period_count], [day6_available_period_count], [day7_available_period_count]
   Select all the Records from [tt_teacher_availability]
   Loop through all the records from [tt_teacher_availability]
      Calculate [min_teacher_availability_score] and [max_teacher_availability_score] from [sch_teacher_capabilities]
   EndLoop

Step 3: Update in [tt_teacher_availability] from [tt_teacher_unavailable]
   set [day1_available_period_count], [day2_available_period_count], [day3_available_period_count], [day4_available_period_count],
       [day5_available_period_count], [day6_available_period_count], [day7_available_period_count]
   Select all the Records from [tt_teacher_availability]
   Loop through all the records from [tt_teacher_availability]
      Calculate [min_teacher_availability_score] and [max_teacher_availability_score] from [sch_teacher_capabilities]
   EndLoop

Step 4: Calculate [min_teacher_availability_score] and [max_teacher_availability_score]
   Select all the Records from [tt_teacher_availability]
   Loop through all the records from [tt_teacher_availability]
      Calculate [min_teacher_availability_score] and [max_teacher_availability_score] from [sch_teacher_capabilities]
   EndLoop

Step 5: Mannual modification in [tt_teacher_availability] for [is_primary_teacher], [is_preferred_teacher], [preference_score]












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

