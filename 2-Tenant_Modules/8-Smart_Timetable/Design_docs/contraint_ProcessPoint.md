# Smart Timetable Generation Process

When Start Timetable Generation process user will get dropdown to select - 
 - academic_term_id [sch_academic_term.term_code] where [sch_academic_term.is_active] = 1
 - Timetable Type [tt_timetable_type.code] where [tt_timetable_type.is_active] = 1

## 0. Pre-requisite
When user select Academic Term we will fetch below parameter from [sch_academic_term]
Get: $academic_term_id from [sch_academic_term.id]
Get: $academic_term_code from [sch_academic_term.academic_session_id]
Get: $academic_year_start_date [sch_academic_term.start_date]
Get: $academic_year_end_date [sch_academic_term.end_date]
Get: $term_code [sch_academic_term.term_code]
Get: $Academic_term_start_date [sch_academic_term.start_date]
Get: $Academic_term_end_date [sch_academic_term.end_date]

## 1. Generate Timetable Slot Availability

### 1.1 Generate Timetable Slot Availability
-------------------------------------------
Step 1: Create Records where [tt_class_timetable_type_jnt.applies_to_all_sections] = 0
   Select all the Records from [tt_class_timetable_type_jnt] where 
      [tt_class_timetable_type_jnt.academic_term_id] = [$academic_term_id] AND
      [tt_class_timetable_type_jnt.timetable_type_id] = [$timetable_type_id] AND
      [tt_class_timetable_type_jnt.applies_to_all_sections] = 0 AND
      [tt_class_timetable_type_jnt.is_active] = 1
   Insert all those records into [tt_slot_availability]
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
         Insert all records from [tt_class_timetable_type_jnt] into [tt_slot_availability] for each 
            section_id in [sch_class_section_jnt]
      EndLoop
   EndLoop


## 2. Generate (tt_class_subject_groups & tt_class_subject_subgroups)

### 2.1 Fill Data into [tt_class_subject_groups & tt_class_subject_subgroups]
-----------------------------------------------------------------------------
Check [sch_class_groups_jnt.is_compulsory]
If [True]
   Fill [tt_class_subject_groups.*] = [sch_class_groups_jnt.*]
   Fill all matching fields in [tt_class_subject_groups] from [sch_class_groups_jnt]
   where [sch_class_section_jnt.is_compulsory] = 1 AND
   [sch_class_section_jnt.is_active] = 1
Else
   Fill [tt_class_subject_subgroups.*] = [sch_class_groups_jnt.*]
   Fill all matching fields in [tt_class_subject_subgroups] from [sch_class_groups_jnt]
   where [sch_class_section_jnt.is_compulsory] = 1 AND
   [sch_class_section_jnt.is_active] = 1
EndIf

### 2.2 Class_House_Room in [tt_class_subject_groups.class_house_room_id]
-------------------------------------------------------------------------	
Get: from [sch_class_section_jnt.class_house_room_id] where 
   [sch_class_section_jnt.class_id] = [tt_class_subject_groups.class_id]
   [sch_class_section_jnt.section_id] = [tt_class_subject_groups.section_id]
   [sch_class_section_jnt.is_active] = 1

### 2.3 Class_House_Room in [tt_class_subject_subgroups.class_house_room_id]
----------------------------------------------------------------------------
Get: from [sch_class_section_jnt.class_house_room_id] where 
   [sch_class_section_jnt.class_id] = [tt_class_subject_subgroups.class_id]
   [sch_class_section_jnt.section_id] = [tt_class_subject_subgroups.section_id]
   [sch_class_section_jnt.is_active] = 1

### 2.4 Update [sch_class_section_jnt.actual_total_student]
-----------------------------------------------------------------
update [sch_class_section_jnt]
set [actual_total_student] = 
Get: count of [std_student_academic_sessions.id] where 
   [std_student_academic_sessions.academic_session_id] = [$academic_term_id]
   [std_student_academic_sessions.class_id] = [tt_class_subject_groups.class_id]
   [std_student_academic_sessions.section_id] = [tt_class_subject_groups.section_id]
   [std_student_academic_sessions.is_active] = 1

### 2.5 Total_Student in [tt_class_subject_groups.student_count]
-----------------------------------------------------------------
Get: count of [sch_class_section_jnt.actual_total_student] where 
   [sch_class_section_jnt.class_id] = [tt_class_subject_groups.class_id]
   [sch_class_section_jnt.section_id] = [tt_class_subject_groups.section_id]
   [sch_class_section_jnt.is_active] = 1

### 2.6 Total_Student in [tt_class_subject_subgroups.student_count]
-----------------------------------------------------------------
Get: count of [sch_class_section_jnt.actual_total_student] where 
   [sch_class_section_jnt.class_id] = [tt_class_subject_subgroups.class_id]
   [sch_class_section_jnt.section_id] = [tt_class_subject_subgroups.section_id]
   [sch_class_section_jnt.is_active] = 1

Condition
   [sch_subject_groups.class_id] = [ptt_class_subject_subgroups.class_id]
   [sch_subject_groups.section_id] = [tt_class_subject_subgroups.section_id]
   [sch_subject_group_subject_jnt.subject_study_format_id] = [tt_class_subject_subgroups.subject_study_format_id]
EndIf

### 2.7 Total_Student in [tt_class_subject_subgroups.student_count]
-----------------------------------------------------------------
Check [is_compulsory]
If True
   Get: count of [sch_class_section_jnt.actual_total_student] where 
      [sch_class_section_jnt.class_id] = [tt_class_subject_subgroups.class_id]
      [sch_class_section_jnt.section_id] = [tt_class_subject_subgroups.section_id]
      [sch_class_section_jnt.is_active] = 1
Else 
   Get: count of [std_student_academic_sessions.id] where 
      [std_student_academic_sessions.subject_group_id] = [sch_subject_groups.id]
      [sch_subject_group_subject_jnt.subject_group_id] = [sch_subject_groups.id]

Condition
   [sch_subject_groups.class_id] = [ptt_class_subject_subgroups.class_id]
   [sch_subject_groups.section_id] = [tt_class_subject_subgroups.section_id]
   [sch_subject_group_subject_jnt.subject_study_format_id] = [tt_class_subject_subgroups.subject_study_format_id]
EndIf



### 2.8 Calculate Allocated Teachers Count [eligible_teacher_count]
------------------------------------------------------------------
Get: count of [sch_teacher_capabilities.id] where 
   [sch_teacher_capabilities.class_group_id] = [sch_class_groups_jnt.id]
Insert into both tables (tt_clss_subject_group & tt_clss_subject_subgroup)



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

