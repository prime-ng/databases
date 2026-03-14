# Process Flow (Step By Step what we will be Doing)

1. First we will be Entering data into all the Master Tables
   - `tt_shift`
   - `tt_day_types`
   - `tt_period_types`
   - `tt_teacher_assignment_role`
   - `tt_school_days`
   - `tt_working_day`
   - `tt_period_set`
   - `tt_period_set_period`
   - `tt_timetable_type`
   - `tt_class_mode_rule`
2. Define all required Sub-Groups (Semi Auto)
   - `tt_class_subgroup`
   - `tt_class_subgroup_member`
     (create Entry in `tt_class_subgroup` for all the Records in `sch_subject_group_subject_jnt` where `sch_subject_group_subject_jnt`.`is_compulsory` = 0 )
     If `sch_subject_group_subject_jnt`.`is_compulsory` = 0 
     {
        Create an entry in `tt_class_subgroup_member`
        {
          `tt_class_subgroup_member`.`class_subgroup_id` = `sch_subject_group_subject_jnt`.`class_subgroup_id`
          `tt_class_subgroup_member`.`subject_id` = `sch_subject_group_subject_jnt`.`subject_id`
          `tt_class_subgroup_member`.`academic_session_id` = $academic_session_id$
        }
     }
3. Define all required Constraints (Auto data fetch from )
   - `tt_constraint_type`
   - `tt_constraints`
   - `tt_teacher_unavailable`
   - `tt_room_unavailable`

4. Now we need to Generate Requirement for Groups / Sub-Groups
   - tt_group_requirement
    - All the Major Subject for Class+Section will be tought in a Single Group , No Split OR Merging with other Sections.
      - Conditions:
        - In Student's Academic Session (`std_student_academic_sessions`.`subject_group_id` => `sch_subject_groups`.`id`)
        - IF `sch_subject_group_subject_jnt`.`is_compulsory` = 1 where `sch_subject_group_subject_jnt`.`subject_group_id` = `sch_subject_groups`.`id`
          then 
          {
            `tt_class_group_requirement`.`class_group_id` = `sch_subject_group_subject_jnt`.`class_group_id`
            `tt_class_group_requirement`.`class_subgroup_id` = `NULL`
            `tt_class_group_requirement`.`academic_session_id` = $academic_session_id$
            `tt_class_group_requirement`.`weekly_periods` = `sch_subject_group_subject_jnt`.`weekly_periods`
            `tt_class_group_requirement`.`min_periods_per_week` = `sch_subject_group_subject_jnt`.`min_periods_per_week`
            `tt_class_group_requirement`.`max_periods_per_week` = `sch_subject_group_subject_jnt`.`max_periods_per_week`
            `tt_class_group_requirement`.`max_per_day` = `sch_subject_group_subject_jnt`.`max_per_day`
            `tt_class_group_requirement`.`is_compulsory` = `sch_subject_group_subject_jnt`.`is_compulsory`
          }
          else **(when it is a optional subject then we need to create a Class Sub-Group `class_subgroup_id`)**
          {
            `tt_class_group_requirement`.`class_group_id` = `sch_subject_group_subject_jnt`.`class_group_id`
            `tt_class_group_requirement`.`class_subgroup_id` = `sch_subject_group_subject_jnt`.`class_subgroup_id`
            `tt_class_group_requirement`.`academic_session_id` = $academic_session_id$
            `tt_class_group_requirement`.`weekly_periods` = `sch_subject_group_subject_jnt`.`weekly_periods`
            `tt_class_group_requirement`.`min_periods_per_week` = `sch_subject_group_subject_jnt`.`min_periods_per_week`
            `tt_class_group_requirement`.`max_periods_per_week` = `sch_subject_group_subject_jnt`.`max_periods_per_week`
            `tt_class_group_requirement`.`max_per_day` = `sch_subject_group_subject_jnt`.`max_per_day`
            `tt_class_group_requirement`.`is_compulsory` = `sch_subject_group_subject_jnt`.`is_compulsory`
          }
    - tt_subgroup_requirement
   