1. Fetch data from sch_clss_group
    a.  Check [is_compulsory]
        If True
            Insert data into tt_clss_subject_group
        Else
            Insert data into tt_clss_subject_subgroup
        Endif
    b. Fetch class section house detail [`class_house_room_id`]
        Get from sch_class_section_jnt
        Insrt into both tables (tt_clss_subject_group & tt_clss_subject_subgroup)
    c. Total_Student [student_count]
        Check [is_compulsory]
        If True 
            {
            Get from sch_class_section_jnt [sch_class_section_jnt.actual_total_student]
            }
        Else 
            {
              -- 1. Count (Student) from [std_student_academic_sessions] where 
               [std_student_academic_sessions.subject_group_id] = [sch_subject_groups.id]
               [sch_subject_group_subject_jnt.subject_group_id] = [sch_subject_groups.id]
            Condition
               [sch_subject_groups.class_id] = [ptt_class_subject_subgroups.class_id]
               [sch_subject_groups.section_id] = [tt_class_subject_subgroups.section_id]
               [sch_subject_group_subject_jnt.subject_study_format_id] = [tt_class_subject_subgroups.subject_study_format_id]
        }
