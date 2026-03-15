# TIMETABLE GENERATION PROCESS FLOW - ENHANCED v3.0
════════════════════════════════════════════════════

## Process Detail - What is the Process and What Action User/System will prform

PHASE 0: Whome we will be creating Timetable for ?
══════════════════════════════════════════════════

I will Generate School Timetable for a Selected Timetable Type By selecting :
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

## PHASE 1: PRE-REQUISITES SETUP (One-time)
══════════════════════════════════════════════════

   - `sch_organizations` : This table is a replica of `prm_tenant` table from 'prime_db' database. It stores details of the Organizations/Schools using this Timetable Module, including group code, name, U-DISE code, affiliation number, location details, and establishment date. It ensures only one active record per organization with `flg_single_record` = 1.

    - `sch_org_academic_sessions_jnt`: This table stores the Academic Sessions for the Organization/School, linking to global academic sessions (`glb_academic_sessions`). It includes session name, start and end dates, and flags for current session. Only one session can be marked as current (`is_current` = 1) per organization.

    - `sch_org_academic_sessions_jnt`: This table stores the Academic Sessions for the Organization/School, linking to global academic sessions (`glb_academic_sessions`). It includes session name, start and end dates, and flags for current session. Only one session can be marked as current (`is_current` = 1) per organization.
	     
    - `sch_board_organization_jnt`: Junction table linking Organizations with Boards for specific Academic Sessions. It helps determine which education boards are associated with the school for the selected academic year, enabling board-specific timetable rules and subject requirements.
    
    - `sch_classes`: Stores the Classes available in the Organization/School, with ordinal for ordering, code (e.g., '1st', '10th'), short name, and full name. Each class has a unique code and name for timetable identification.
    
    - `sch_sections`: Stores the Sections for classes, with ordinal, code (e.g., 'A', 'B'), short name, and full name. Sections are combined with classes to form class-section combinations for detailed scheduling.
    
    - `sch_class_section_jnt`: Junction table linking Classes with Sections, creating unique class-section entities. It includes capacity details, assigned class teachers, room types, and daily period counts. This table defines the physical and administrative structure for timetable allocation.
    
    - `sch_subject_types`: Defines types of subjects (e.g., Major, Minor, Core, Optional) to categorize subjects for scheduling rules, such as prioritizing major subjects in morning periods.
    
    - `sch_study_formats`: Defines formats in which subjects are taught (e.g., Lecture, Lab, Practical, Tutorial). This influences room and resource requirements for different subject delivery methods.
    
    - `sch_subjects`: Stores all available Subjects in the school, with code, name, and other details. Subjects are the core elements around which timetables are built.
    
    - `sch_subject_study_format_jnt`: Junction table mapping Subjects to their Types and Study Formats. It captures weekly period requirements, room needs (e.g., class house room), and other scheduling constraints per subject combination.
    
    - `sch_class_groups_jnt`: Defines Class Groups based on subject-study-format combinations (e.g., '10th-A Science Lecture Major'). It includes teacher assignments, room requirements, and period allocations for specific class groupings, forming the basis for activity creation in timetables.

    - `sch_subject_groups`: Groups subjects into categories for curriculum management, such as core subjects or electives. This helps in organizing subject offerings and linking to student enrollments.
    
    - `sch_subject_group_subject_jnt`: Junction table mapping subjects to subject groups, defining which subjects belong to which groups. This enables flexible curriculum structures and student subject assignments.
    
    - `sch_buildings`: Stores building information within the school campus, including codes and locations. This provides the physical context for room assignments and navigation.
    
    - `sch_rooms_type`: Defines types of rooms (e.g., Classroom, Lab, Auditorium) with associated requirements and capacities. This categorizes rooms for appropriate activity scheduling.
    
    - `sch_rooms`: Details individual rooms, linking to buildings and types, with capacity, equipment, and availability. This is essential for room allocation in timetable generation.
    
    - `sch_employees`: Contains employee records, including teachers and staff, with basic information. This serves as the base for teacher profiles and assignments.
    
    - `sch_teacher_profile`: Extends employee data with teaching-specific details, such as subjects taught, availability, and qualifications. This informs teacher eligibility and workload calculations.
    
    - `sch_teacher_capabilities`: Records teacher competencies and specializations, enabling matching teachers to appropriate subjects and activities.
    
    - `std_students`: Stores student information, including enrollment details. This provides the student base for class and section assignments.
    
    - `std_student_academic_sessions`: Links students to academic sessions, capturing enrollment status, class/section assignments, and subject groups. This ensures accurate student counts and groupings for timetable planning.



    

    
    - `sch_board_organization_jnt`: Junction table linking Organizations with Boards for specific Academic Sessions. It helps determine which education boards are associated with the school for the selected academic year, enabling board-specific timetable rules and subject requirements.
    
    - `sch_classes`: Stores the Classes available in the Organization/School, with ordinal for ordering, code (e.g., '1st', '10th'), short name, and full name. Each class has a unique code and name for timetable identification.
    
    - `sch_sections`: Stores the Sections for classes, with ordinal, code (e.g., 'A', 'B'), short name, and full name. Sections are combined with classes to form class-section combinations for detailed scheduling.
    
    - `sch_class_section_jnt`: Junction table linking Classes with Sections, creating unique class-section entities. It includes capacity details, assigned class teachers, room types, and daily period counts. This table defines the physical and administrative structure for timetable allocation.
    
    - `sch_subject_types`: Defines types of subjects (e.g., Major, Minor, Core, Optional) to categorize subjects for scheduling rules, such as prioritizing major subjects in morning periods.
    
    - `sch_study_formats`: Defines formats in which subjects are taught (e.g., Lecture, Lab, Practical, Tutorial). This influences room and resource requirements for different subject delivery methods.
    
    - `sch_subjects`: Stores all available Subjects in the school, with code, name, and other details. Subjects are the core elements around which timetables are built.
    
    - `sch_subject_study_format_jnt`: Junction table mapping Subjects to their Types and Study Formats. It captures weekly period requirements, room needs (e.g., class house room), and other scheduling constraints per subject combination.
    
    - `sch_class_groups_jnt`: Defines Class Groups based on subject-study-format combinations (e.g., '10th-A Science Lecture Major'). It includes teacher assignments, room requirements, and period allocations for specific class groupings, forming the basis for activity creation in timetables.






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
	- `sch_class_groups_jnt`: Defines Class Groups based on subject-study-format combinations (e.g., '10th-A Science Lecture Major'). It includes teacher assignments, room requirements, and period allocations for specific class groupings, forming the basis for activity creation in timetables.

	- We will Create Acedemic Terms in 'sch_academic_term'
    - Acedemic Terms will be connected with Academic Session and will be connected with 'sch_org_academic_sessions_jnt'
    - 'sch_academic_term.term_start_date' & 'sch_academic_term.term_end_date' will be within the range of 'sch_org_academic_sessions_jnt.start_date' & 'sch_org_academic_sessions_jnt.end_date'
    - School may have multipl Acedemic Terms('sch_academic_term') within single (sch_org_academic_sessions_jnt)
    - Separate Timetable will be created for separate Acedemic Terms.






## PHASE 0.2: REFERENCE TABLES FROM OTHER MODULES SETUP
══════════════════════════════════════════════════════════

    0.2 Below are the Reference Tables that need to be populated from other modules for Timetable Generation:


=======================================================================================

## PHASE 0.3: CONFIGURATION TABLES SETUP
══════════════════════════════════════════════════════════

0.3 Below are the Configuration Tables that need to be set up for Timetable Generation:

    - `sch_academic_term`: Defines the academic term/quarter/semester structure within an academic session. It includes term codes, names, start/end dates, total teaching/exam days, period counts, and travel times between classes. This table is used for lesson planning and timetable generation, ensuring terms align with session dates and only one term is current at a time.
    
    - `tt_config`: Stores configuration settings for the timetable module, such as total periods per day, school open days, and teacher workload limits. These are key-value pairs with types (string, number, boolean), descriptions, and tenant modification flags. Only PRIME can add/edit keys, while tenants can modify values if allowed, ensuring centralized control over module parameters.
    
    - `tt_generation_strategy`: Contains algorithms and parameters for timetable generation, including recursive, genetic, simulated annealing, tabu search, and hybrid methods. It defines max recursion depth, population size, cooling rates, and activity sorting methods. This table allows selection of generation strategies with customizable parameters for efficient timetable creation.

## PHASE 0.4: MASTER TABLES SETUP
══════════════════════════════════════════════════════════

0.4 Below are the Master Tables that define the core entities and rules for Timetable Generation:

    - `tt_shift`: Defines school shifts (e.g., Morning, Afternoon, Evening) with default start/end times and ordinals. This allows scheduling timetables for different school timings or shifts.
    
    - `tt_day_type`: Categorizes types of days (e.g., Study, Holiday, Exam, Special) with flags for working days and reduced periods. This enables flexible scheduling based on day types, such as fewer periods on exam or sports days.
    
    - `tt_period_type`: Defines period types (e.g., Theory, Teaching, Practical, Break, Lunch, Assembly, Exam, Recess, Free) with properties like schedulability, teaching counts, and durations. This classifies periods for workload calculations and scheduling constraints.
    
    - `tt_teacher_assignment_role`: Specifies teacher roles in assignments (e.g., Primary, Assistant, Co-Teacher, Substitute, Trainee) with workload factors and overlap permissions. This manages teacher involvement and workload distribution in activities.
    
    - `tt_school_days`: Lists days of the week with codes, names, and school day flags. This establishes the weekly calendar, marking which days are operational for scheduling.
    
    - `tt_working_day`: Sets the status of specific dates (open/closed) and associates day types (e.g., multiple activities like exam with study). This creates the academic calendar, updating term counts for teaching/exam days.
    
    - `tt_class_working_day_jnt`: Links classes/sections to working days, allowing variations (e.g., one class has exam while another studies). This handles class-specific calendar exceptions.
    
    - `tt_period_set`: Defines period sets with total periods, teaching/exam/free counts, and daily timings. This accommodates different period structures (e.g., 8 periods standard, 3 for exams) for various timetable types.
    
    - `tt_period_set_period_jnt`: Details individual periods within a set, including codes, types, start/end times, and durations. This structures the daily schedule with breaks, lunches, and teaching slots.
    
    - `tt_timetable_type`: Defines timetable types (e.g., Standard, Unit Test, Half Day, Exam) with shifts, effective dates, and flags for teaching/exam inclusion. This specifies the timetable variants available for generation.
    
    - `tt_class_timetable_type_jnt`: Associates timetable types with classes/sections, linking to period sets and defining teaching/exam allowances. This applies timetable rules per class, preventing overlapping period sets.

## PHASE 0.5: TIMETABLE REQUIREMENT TABLES SETUP
══════════════════════════════════════════════════════════

0.5 Below are the Timetable Requirement Tables that consolidate and prepare data for generation, based on the process execution steps:

    - `tt_slot_requirement`: Generated from `tt_class_timetable_type_jnt` for the selected academic term and timetable type. It creates records for each class-section combination, specifying weekly total/teaching/exam/free slots and linking to class house rooms. This table defines the slot availability for scheduling, handling cases where timetable types apply to all sections or specific ones.
    
    - `tt_class_requirement_groups`: Populated from `sch_class_groups_jnt` where `is_compulsory` = 1. It groups classes by subject-study-format combinations, capturing student counts, eligible teachers, and class house rooms. This forms the basis for compulsory activities, ensuring required subjects are scheduled.
    
    - `tt_class_requirement_subgroups`: Filled from `sch_class_groups_jnt` where `is_compulsory` = 0. It handles optional or subgroup-specific requirements, allowing sharing across sections/classes. This enables flexible scheduling for elective subjects or specialized groups.
    
    - `tt_requirement_consolidation`: Consolidates data from groups and subgroups for the selected term and timetable type. It links to class groups/subgroups, subjects, study formats, and captures student counts and room assignments. This table serves as the master requirement source for activity creation and constraint application during generation.

## PHASE 0.6: CONSTRAINT ENGINE TABLES SETUP
══════════════════════════════════════════════════════════

0.6 Below are the Constraint Engine Tables that define the rules and limitations for scheduling, based on predefined categories and scopes:

    - `tt_constraint_category_scope`: Defines constraint categories (e.g., PERIOD, ROOM, TEACHER, CLASS, SUBJECT) and scopes (e.g., GLOBAL, TEACHER, ROOM, ACTIVITY, CLASS_GROUP). This table is managed by PRIME only and establishes the framework for constraint types, ensuring consistent rule application across different entities and levels.
    
    - `tt_constraint_type`: Specifies individual constraint types within categories and scopes, such as "Teacher cannot have consecutive periods" or "Room capacity limits". It includes descriptions, priorities, and violation penalties, allowing fine-grained control over scheduling rules.
    
    - `tt_constraint`: Stores actual constraint instances applied to specific entities (e.g., a teacher cannot teach after 4 PM, or a room requires 15-minute breaks). It links to constraint types, targets (activities, teachers, rooms), and includes parameters for enforcement, enabling the algorithm to respect hard and soft constraints during generation.

    - `tt_teacher_unavailable`: Records periods when teachers are unavailable (e.g., due to meetings, training, or personal leave). It links to constraints and specifies date ranges or specific periods, ensuring the generation algorithm avoids scheduling activities for unavailable teachers.

    - `tt_room_unavailable`: Tracks periods when rooms are unavailable (e.g., maintenance, events, or equipment issues). It connects to constraints and defines unavailability windows, preventing room assignments during those times in the timetable generation process.




I am creating Steps required for Generate Automatic Timetable in the File '2-Tenant_Modules/8-Smart_Timetable/V6/2-tt_Generation_Flow.md' by refering from DDL Schema File "2-Tenant_Modules/8-Smart_Timetable/DDLs/tt_timetable_ddl_v7.6.sql" Add detail further in the file '2-Tenant_Modules/8-Smart_Timetable/V6/2-tt_Generation_Flow.md' by refering Section "SECTION 11: REFERENCE TABLES FROM OTHER MODULES" in file "2-Tenant_Modules/8-Smart_Timetable/DDLs/tt_timetable_ddl_v7.6.sql". Must follow below Instruction :

Do not remove or change anything in '2-tt_Generation_Flow.md' only insert further detail below the text already written in the file.
Output must be in the same Format as I have created in '2-tt_Generation_Flow.md'.


