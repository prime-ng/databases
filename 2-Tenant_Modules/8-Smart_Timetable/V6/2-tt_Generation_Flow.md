# TIMETABLE GENERATION PROCESS FLOW - ENHANCED v3.0
════════════════════════════════════════════════════

## Process Detail - What is the Process and What Action User/System will prform

PHASE 0: Whome we will be creating Timetable for ?
══════════════════════════════════════════════════

We will be Creating an School Timetable for a Selected Timetable Type By selecting :
	- School Board from (sch_board_organization_jnt)
	- Acedemic Session Year for selected Board from (sch_org_academic_sessions_jnt)
	- Acedemic Term for selected Acedemic Session from (sch_academic_term)
	- Select School Shift from (tt_shift)
	- Timetable Type from (tt_timetable_type)
    - To accomodate requirements of different Classes+Sections (i.e. one Class may have exam whereas another is having study in all the periods) we have table (tt_class_timetable_type_jnt).
    - This (tt_class_timetable_type_jnt) connect Timetable Type with class+section by (tt_class_timetable_type_jnt) to define how it will be implemented to the different classes+Section.
    - This (tt_class_timetable_type_jnt) also connects Timetable Type with Period Set (tt_period_set) to define how periods will be distributed for different Period Type (tt_period_type) e.g. 'Study', 'Exam', 'Free_Period' etc.
	- Same Timetable may have 6 periods for few classes whereas other classes may have 8 periods for the same period. This type of requirement will be managed by Period Set (tt_period_set) & it's detail table (tt_period_set_period_jnt)
	- Table (tt_period_set) & (tt_period_set_period_jnt) is having information 

## PHASE 0: PRE-REQUISITES SETUP (One-time)
══════════════════════════════════════════════════

0.1 Below are the Pre-Requisites to generate Timetable :
    - Atleast 1 record having `is_current` = 1 should be there in `sch_org_academic_sessions_jnt`. This represent current Academic Session of the School.
    - Atleast 1 record for current Academic Session should be in `sch_board_organization_jnt`. Represent Available Board in School.
    - All available Class & Section should be created in tables `sch_classes` & `sch_sections` respectivly.
    - Available session for every classes should be mapped in `sch_class_section_jnt`
    - Table `sch_class_section_jnt` capture whcih Room `class_house_room_id` will be the House Room for that Class+Section.
    - All available Subjects should be created in `sch_subjects`.
    - Every Subject will have 1 or more Study Format e.g. 'Lacture', 'Practical', 'Activity' etc.
    - Every Subject will have type called Subject Type `sch_subject_types`, e.g. 'Major', 'Minor', 'Optional', 'Skill' etc.
    - Table `sch_subject_study_format_jnt` will be having mapping between Subjects `sch_subjects` & subject Types `sch_subject_types`.
    - Table `sch_subject_study_format_jnt` will also having mapping between Subjects `sch_subjects` & `sch_study_formats`.
    - School will define How many Periods per week requireed for every `Subject`+`Study_Format` for Every Class, which may applicable to all the sections or different Sections may have different required Number of Periods per week for every `Subject`+`Study_Format`v.
    - Table `sch_subject_study_format_jnt` will also capture whether the period for that `Subject`+`Study_Format` will be conducted in the class house room in the field `require_class_house_room`






  - We will Create Acedemic Terms in 'sch_academic_term'
    - Acedemic Terms will be connected with Academic Session and will be connected with 'sch_org_academic_sessions_jnt'
    - 'sch_academic_term.term_start_date' & 'sch_academic_term.term_end_date' will be within the range of 'sch_org_academic_sessions_jnt.start_date' & 'sch_org_academic_sessions_jnt.end_date'
    - School may have multipl Acedemic Terms('sch_academic_term') within single (sch_org_academic_sessions_jnt)
    - Separate Timetable will be created for separate Acedemic Terms.






