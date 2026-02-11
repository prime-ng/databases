# Smart Timetable Generation Process

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



## 3. Requirement Consolidation [tt_requirement_consolidation]

### 3.1 Fill [tt_requirement_consolidation]
-------------------------------------------
Fill [tt_class_subject_groups.class_group_id] = [sch_class_groups_jnt.id]
a. Check [is_compulsory]
If True
   Insert data into tt_requirement_consolidation
Else
   Insert data into tt_requirement_consolidation
EndIf





## 4. Teacher Assignment (tt_teacher_assignment)

### 4.1 Fill tt_teacher_assignment
------------------------------------
   a. Check [is_compulsory]
      If True
         Insert data into tt_teacher_assignment
      Else
         Insert data into tt_teacher_assignment
      Endif

