I want you to act as a Enterprise Architect. Read all below files to get a in-depth understand of "SmartTmetable" Module. Here is the detail of files you need to read :

- Read AI-Brain from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain" to get all the path info.
- Also fetch the understanding about the entire application inclduing "SmartTmetable" from Ai_Brain.
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable", which is main folder of "SmartTmetable" Module
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/TimetableFoundation", , which is main folder for all dependent functionalities of "SmartTmetable" Module
- Read file "Timetable_Algorithm_Guide.md", "Timetable_Process_Detail_v1.md" & "Timetable_Process_Detail_v2.md" from folder "/Users/bkwork/WorkFolder/3-Local_Workspace/1-Working/Z-Timetable/Algo_Detail/". These are Claude generated files of how Timetable Generator Works but the information it provides is very generic whereas I am looking for a output which will be generic but includes some technical detail also. for exampal :
in Step - 2 "Timetable_Process_Detail_v1" says -

        ## Step 2 — The System Gathers All the Ingredients

        Before cooking, you need ingredients. The system loads:

        | What it loads | Real-world example |
        |---|---|
        | **Classes** | Class 5-A, Class 6-B, Class 10-Science |
        | **Activities (subjects)** | Math (5 times/week), English (4 times/week), PT (2 times/week) |
        | **Teachers** | Mrs. Sharma teaches Math, Mr. Khan teaches Science |
        | **Rooms** | Room 101, Lab-1, Music Room |
        | **School days** | Mon–Sat (Sunday off) |
        | **Period grid** | 8 periods per day, with lunch after period 4 |
        | **Class teaching windows** | Toddlers only have classes from 9 AM to 12 PM. Class 10 has the full day. |
        | **Daily targets** | Class 5-A should have 6–7 classes per day, not 12 in one day |

        **Example:** Toddlers go home early, so the system knows: "Don't put a class for them in the 5th period — they're already on the bus home."

Whereas I am expecting as below -

    ## Step 2 — The System Gathers All the required information to Generate Timetable, for that it will Load all below tables into memory:
     - sch_classes
     - sch_sections
     - sch_subjects
     - sch_subject_study_format_jnt
     - sch_class_groups_jnt
     - sch_subject_groups
     - sch_subject_group_subject_jnt
     - sch_rooms_type
     - sch_rooms
     - sch_teacher_profile
     - sch_teacher_capabilities



Timetable_Process_Detail_v2.md


------------------------------------------------------------------------------------------------------
I want you to act as a Enterprise Architect. 

Read all below files to get a in-depth understand of "SmartTmetable" Module. Here is the detail of files you need to read :

- Read AI-Brain from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain" to get all the path info.
- Also fetch the understanding about the entire application inclduing "SmartTmetable" from Ai_Brain.
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable", which is main folder of "SmartTmetable" Module
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/TimetableFoundation", , which is main folder for all dependent functionalities of "SmartTmetable" Module
- Read file "Timetable_Algorithm_Guide.md", "Timetable_Process_Detail_v1.md" & "Timetable_Process_Detail_v2.md" from folder "/Users/bkwork/WorkFolder/3-Local_Workspace/1-Working/Z-Timetable/Algo_Detail/". These are Claude generated files of how Timetable Generator Works.  Once you are done with the complete information about "SmartTimetable" Module, let me know. I have qeries to understand it in detail.

------------------------------------------------------------------------------------------------------

I want to refine the Algorithm especially the sequence of the parameter being used to priorities the allocation. Few quesries are below which will help me to understand the current parameter sqence being used in algo, which will ultimatly help me to refine the Algo. Answer the below queries and also provide any additional information which can help me to understand the internal machanism of the algorithm :
- What all Parameters are there which can be used to prioritise the placement of a teacher+Period to a Activity (Class+section+Subject+Study_Format)?
- What all Parameters are there which can be used to prioritise the placement of the Room to a Activity (Class+section+Subject+Study_Format)?
- What should be the Formula to calculate all the parameter which will be used to Prioritise Placements? If any will be provided by School (End User) then mark it as "User provided"
- What should be the Priority Sequence of all those Parameters to get perfect Placement of Teacher+Period & Rooms? Save the output into a file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_parameter_detail.md"


------------------------------------------------------------------------------------------------------
Now when I have understood the Algorithm in detail what all Parameters it is using to priorities the Activities. I found many discripencies :
- Few Parameter which are being used to priorties Teacher (which activity we should place Teacher on first), actually should not be used for prioritising placement.
- Few Parameter has ben given higher weightage, however those are less important when we calculate prioritisation
- etc.

Now I want to know what is the best way to communicate all those discripencies, so that you can provide me a refined enhancement plan? Should I write all those discripencies in a saperarate .md file if yes then what should be format of that document(.md file)? Write the Template in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement"


======================================================================================================
## Points to Enhance Timetable Generation Process
======================================================================================================

| # | Parameter | Type | Source (table.column) | Used today? | Purpose |
|---|---|---|---|---|---|
| A1 | `is_compulsory` | USER_PROVIDED bool | tt_activity.is_compulsory | Yes (difficulty +20) | This will be used only to identify whether the subject+StudyFormat is compulsory for the entire Section of a Class OR this is a Optional Subject and Student can choose 1 option from Multipal options for one subject
| A2 | `priority` | USER_PROVIDED 0–100 | tt_activity.priority | Yes (× 20 in class-teacher rule) | Manual school priority |
| A3 | `difficulty_score` | USER_PROVIDED 0–100 | tt_activity.difficulty_score | Yes (fallback) | Scheduling hardness override |
| A4 | `difficulty_score_calculated` | COMPUTED 0–100 | tt_activity.difficulty_score_calculated | Yes (primary) | Auto-difficulty (see §2) |
| A5 | `required_weekly_periods` | USER_PROVIDED int | tt_activity.required_weekly_periods | Yes (× 500 in difficulty) | Higher load → harder |
| A6 | `min_periods_per_week` | USER_PROVIDED int | tt_activity.min_periods_per_week | Partial | Floor for partial coverage |
| A7 | `max_periods_per_week` | USER_PROVIDED int | tt_activity.max_periods_per_week | Partial | Ceiling |
| A8 | `min_per_day` | USER_PROVIDED int | tt_activity.min_per_day | Yes (+15 if not met) | Daily floor |
| A9 | `max_per_day` | USER_PROVIDED int | tt_activity.max_per_day | Yes (hard cap) | Daily ceiling |
| A10 | `min_gap_periods` | USER_PROVIDED int | tt_activity.min_gap_periods | Partial | Min gap between same-activity periods |
| A11 | `allow_consecutive` | USER_PROVIDED bool | tt_activity.allow_consecutive | Yes (built-in check) | Back-to-back permitted |
| A12 | `max_consecutive` | USER_PROVIDED int | tt_activity.max_consecutive | Partial | Cap on consecutive same activity |
| A13 | `duration_periods` | USER_PROVIDED int | tt_activity.duration_periods | Yes (× 3 in difficulty) | Block size (1 normal, 2 lab) |
| A14 | `weekly_periods` | USER_PROVIDED int | tt_activity.weekly_periods | Yes | Repetitions/week |
| A15 | `total_periods` | COMPUTED (generated col) | tt_activity.total_periods | Yes | duration × weekly |
| A16 | `preferred_periods_json` | USER_PROVIDED int[] | tt_activity.preferred_periods_json | Yes (+20) | Per-day-pos preference |
| A17 | `avoid_periods_json` | USER_PROVIDED int[] | tt_activity.avoid_periods_json | Yes (−30) | Per-day-pos avoidance |
| A18 | `preferred_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.preferred_time_slots_json | Yes (+40) | Exact (day,period) preference |
| A19 | `avoid_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.avoid_time_slots_json | Yes (−50) | Exact avoidance |
| A20 | `spread_evenly` | USER_PROVIDED bool | tt_activity.spread_evenly | Yes (+10 / −15) | Day-balance preference |
| A21 | `split_allowed` | USER_PROVIDED bool | tt_activity.split_allowed | Yes (−100 if violated) | Multi-day split permitted |
| A22 | `subject_type_id` (MAJOR/MINOR/OPT) | USER_PROVIDED FK | tt_activity.subject_type_id → sch_subject_types | Yes (constraints C1.16, C1.17) | Major must appear daily; minor caps |
| A23 | `study_format_id` | USER_PROVIDED FK | tt_activity.study_format_id → sch_study_formats | Yes (~12 study-format constraints) | LECTURE/LAB/TUTORIAL semantics |
| A24 | `eligible_teacher_count` | COMPUTED int | tt_activity.eligible_teacher_count | Yes (drives teacher_availability_score) | Inverse → scarcity |
| A25 | `min_teacher_availability_score` | COMPUTED 0–100 | tt_activity.min_teacher_availability_score | Yes | Floor of teacher pool % |
| A26 | `max_teacher_availability_score` | COMPUTED 0–100 | tt_activity.max_teacher_availability_score | Yes | Ceil of teacher pool % |
| A27 | `teacher_availability_score` | COMPUTED 0–100 | tt_activity.teacher_availability_score | Yes (in difficulty) | % of teachers actually available |
| A28 | `constraint_count` | COMPUTED int | tt_activity.constraint_count | Yes | Number of constraints touching this activity |
| A29 | `is_class_teacher_activity` | USER_PROVIDED bool | (custom field; verify in DDL — drift Q-13) | Yes (+1000) | First-period bonus |
| A30 | `status` | USER_PROVIDED enum | tt_activity.status (DRAFT/ACTIVE/LOCKED/ARCHIVED) | Yes (filter ACTIVE only) | Lifecycle gate |
| A31 | `activity_group_id` | USER_PROVIDED FK | tt_activity.activity_group_id | Yes | Parent class-group mapping |
| A32 | `is_in_parallel_group` | COMPUTED bool | tt_parallel_group_activity (drift D-org-1) | Yes (+20000 difficulty) | Forces solver to place anchor first |
| A33 | `is_anchor_in_group` | USER_PROVIDED bool | tt_parallel_group_activity.is_anchor | Yes (+5000) | Anchor placement leads siblings |



### What should NOT consider for Prioritisation
-----------------------------------------------
- | A1 | `is_compulsory` | USER_PROVIDED bool | tt_activity.is_compulsory | This should not be considered for Prioritisation
- | A6 | `min_periods_per_week` | USER_PROVIDED int | tt_activity.min_periods_per_week | 
- | A7 | `max_periods_per_week` | USER_PROVIDED int | tt_activity.max_periods_per_week | 
- | A8 | `min_per_day` | USER_PROVIDED int | tt_activity.min_per_day | 
- | A9 | `max_per_day` | USER_PROVIDED int | tt_activity.max_per_day |
- 







### What SHOULD BE considered for Prioritisation
------------------------------------------------

| A2 | `priority` | USER_PROVIDED 0–100 | tt_activity.priority | Yes (× 20 in class-teacher rule) | Manual school priority |
| A3 | `difficulty_score` | USER_PROVIDED 0–100 | tt_activity.difficulty_score | 
| A4 | `difficulty_score_calculated` | COMPUTED 0–100 | tt_activity.difficulty_score_calculated |
| A16 | `preferred_periods_json` | USER_PROVIDED int[] | tt_activity.preferred_periods_json |
| A17 | `avoid_periods_json` | USER_PROVIDED int[] | tt_activity.avoid_periods_json |
| A18 | `preferred_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.preferred_time_slots_json |
| A19 | `avoid_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.avoid_time_slots_json |




### Conditions (Must be followed by Algo)
-----------------------------------------
Class Teacher Conditions :
- 1st Period of Every Class will be taken by Class Teacher. Below condition needs to be checked before assigning.
- If Class Teacher doesn't teach any subject for the class which is assigned her as a Class Teacher then any Teacher can be assigned 1st Period.
- If Total Required Periods of the Subject which can be tought by class teacher


Validation Check :
- If a Class Teacher is not having any Teaching capability to teach any subject of the class for which she is assigned as a Class Teach, then Raise Flag
- 

| A20 | `spread_evenly` | USER_PROVIDED bool | tt_activity.spread_evenly | Yes (+10 / −15) | Day-balance preference |
| A21 | `split_allowed` | USER_PROVIDED bool | tt_activity.split_allowed | Yes (−100 if violated) | Multi-day split permitted |




------------------------------------------------------------------------------------------------------
## Queries / Checkpoint for Tarun
----------------------------------
- Are we using `academic sessions` from Primedb?


------------------------------------------------------------------------------------------------------
### Prompt
I have few Queries related to the SmartTimetable Module :
  - What all Algorithm are being used in the SmartTimetable Module to Generate Timetable?
  - What is the Sequence of those Algorithms?
  - Provide Complete detail of those Algorithms, what parameter are being used in those algorithm and how it is deciding what action should be take next in process of Algo?
  - Does output of one Algorithm is being provided to the next Algorithm as input, if yes then provide detail?

  I want you to provide complete Algorithm detail in generic language. I have ben a developer 10 years back but now I am not very handon with coding on PHP. So keep the language of explaination accordingly, so that I can understand it easily. Save the output into file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_internal_detail.md"


------------------------------------------------------------------------------------------------------
### Prompt
Yes, Create another deepDiving doc as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_deep_dive.md" where you should walk me through one by one all the algorithms in more depth — e.g., the backtracking + cache interaction, or how LPT and alternative-teacher retry actually interact?

### Final Summary
Saved to 1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_deep_dive.md.

What's deeper here vs. Algo_internal_detail.md

The plain-language doc told you what each algorithm does. This one shows you exactly how decisions are made, how state evolves, and where the interactions between algorithms produce non-obvious behavior.

Each section has the same 7-part structure:
  1. Decision in one sentence
  2. State at entry
  3. Exact rule (formula/pseudocode, no hand-waving)
  4. Worked example with state evolution
  5. Edge cases & boundaries
  6. Interactions with other algorithms 
  7. Where the bugs lurk

Two extra-deep sections (the ones you specifically asked about)

§10 — LPT + Alternative-Teacher Retry — walks through the three layers of teacher state (LPT charge, in-memory teacherOccupied, DB tt_teacher_workload) and exposes five non-obvious behaviors of the alternative-teacher retry:
  - (a) charge[] is not updated when retry reassigns a card → LPT's "balanced" view becomes stale.
  - (b) Eligible-teacher list is not re-sorted by least-loaded.
  - (c) Retry is per-card — splits an activity across multiple teachers.
  - (d) Retry doesn't honor is_preferred_teacher flags.
  - (e) Phase 1 doesn't try alternatives at all — meaning a card that could place cleanly with a different teacher is instead force-placed.

  Includes a full LPT trace (3 activities, 2 teachers, charge counters evolving step by step) and a Phase-2 retry trace showing how a Maths activity ends up split T1/T2.

  §12 — Phase 1 Backtracking + Constraint Cache — explains the cache key shape {type}-{classKey}-{dayId}-{startIndex}-{cardId}, walks two backtracking traces (one with no backtrack, one with cache pollution after undo), explains why the cache must be cleared coarsely on every backtrack, and where a smarter dependency-tracking cache could live.

  Other deeply-treated sections

  - §11 Difficulty Ordering — full numeric breakdown of three example cards with weights, plus the pathological "scarcity-blind" case that motivates your discrepancy doc.
  - §13 Slot Scoring — full formula with two complete trace calculations on the same card at different slots.
  - §17 Phase 3b Force-Place Bucketing — first-match-wins gotcha (a placement that's both D_CAPACITY and C_REAL_TEACHER gets only the first label).
  - §18 Room Allocation — score-then-walk dual-pass, why rooms aren't in the search space.
  - §20 Cross-Cutting Interactions — five "easy-to-miss" interaction issues across the whole pipeline.

  How to use this with the discrepancy template
 
  When you fill Activity_Prioritization_Discrepancies_TEMPLATE.md, you can now cite this doc by section in the "Evidence" column — e.g., "see §11.5 pathological case" or "see §10.5 alternative-teacher behaviors."
  That gives me a tight evidence chain when I do the architecture-review pass on your discrepancies.
 
  Want me to walk through any specific section live, or move on to drafting starter discrepancy rows based on what we've documented here? 

recap: We're refining SmartTimetable's activity-prioritization algorithm; you have a discrepancy template, plain-language algo doc, and deep-dive doc ready in Algo_Refinement/. Next action: fill the discrepancy template with your flagged parameter issues so I can do the architecture review.

------------------------------------------------------------------------------------------------------

Read and Evaluate DDL schema from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/DDL/Employee_setup_ddl_v3.sql" and enhance or Add a new table if anything is missing (any field in any table or any table itself is missing). Create a New DDL as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/DDL/Employee_setup_ddl_v4.sql"


hst_dynamic_status_masters (hst_dynamic_status_masters.id)

Room Status - 'available','full','maintenance','reserved'
Bed Status  - 'available','occupied','maintenance','reserved'
Bed Condition Status - 'good','fair','poor'
Repair Status - 'none','pending','under_repair','repaired','written_off'
Room Condition Status - 'good','fair','poor','under_repair','disposed'
Hostel Allotement Status - 'active','vacated','transferred','waitlisted'
Mess Attendance Status - 'present','absent','on_leave','opted_out'
Hostel Complaint Status - 'open','in_progress','resolved','escalated','closed'
Attendance Entry Status - 'present','absent','leave','home','late','sick_bay'
Room Change Request Status - 'pending','approved','rejected'
Hostel Leave Approval Status - 'pending','approved','rejected','returned','cancelled'
Bed Mainitenance Status - 'reported','assigned','in_progress','blocked','resolved','closed','cancelled'
Laundry Ticket Status - 'submitted','in_wash','ready','collected','lost','damaged','disputed'
Mess Opt-out Request Status - 'pending','approved','rejected','active','expired','cancelled'
Mess Bill Status - 'draft','finalised','disputed','adjusted','settled'
Hostel Fee Status - 'draft','pushed','accepted','rejected','revised','settled'
Room Reservation Status - 'pending','confirmed','expired','converted','cancelled','refunded'

------------------------------------------------------------------------------------------------------
Act as a Business Analysts.

I want to Create a Mobile Application for my ERP+LMS+LXP Application. Primarily I want to Create Mobile app for Student, Parents, Teachers & Transport Department But it can be usefull for other Department and Roles also to perform Day to Day Tasks quickly without loging into their System. I want you to create a list of Features which should be include inMobile Application. 

------------------------------------------------------------------------------------------------------

I want you to create a DDL schema for PTM Schduling (Parent Teacher Meeting) Module. Read "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/PTM/Ptm_Requirement.md" to understand the Requirement of the Module, then creat best DDL schema for the Module as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/PTM/Ptm_Setup_ddl_v2.sql". Add detail about the Tables and their Fields, what is the use of those with data example.

------------------------------------------------------------------------------------------------------

Read & understand "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/SyllabusBooks/DDL/SyllabusBooks_ddl_v2.sql". This DDL schema is for storing Syllabus Books for every subject of every Class, which Student can watch and download on `Student Portal` Moduel. I want to add a config table which will capture default parameter related to Books & Notes uplaod e.g. Maximum Size of the Book, Format of the Book/Notes (PDF/ePub/Jpg), Books are downloadable or not etc. I also want to add one more Table to upload / Download Notes. Below is the detail of functionality :
- Teachers can upload Notes to help Students
- Students can also upload Notes to help other Students.
- Students can Download Notes

I wanted to add a field to control whether book is downloadable or not. Other then all above if you find any gap which need to be enhanced then add those as well. Create a new Enhanced DDL as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/SyllabusBooks/DDL/SyllabusBooks_ddl_v3.sql"

------------------------------------------------------------------------------------------------------

Read and understand "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Hostel/DDL/HST_DDL_v3.sql" and Create All required Reports with all possible deatil of the Reports (e.g. Report design, Table will be used, Filters required for Reports etc.) to provide to developer.
Save the Report file as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Hostel/Design/HST_Report_Design_v1.md"

------------------------------------------------------------------------------------------------------

Read and understand "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/PTM/Ptm_Setup_ddl_v3.sql" and Create All required Reports with all possible deatil of the Reports (e.g. Report design, Table will be used, Filters required for Reports etc.) to provide to developer.
Save the Report file as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/PTM/PTM_Report_Design_v1.md"

Create Required
------------------------------------------------------------------------------------------------------

I have created Chat Functionality for Students in `StudentProfile` Module and for Employees in `SchoolSetup` Module. Now I want to create a a Common Chat Functionality where any Registered user can chat with any other registered user. I want to create below Documents :
- Phase-1 : Create a High Level Requirement Document (A Collection of Required Fuctionalities and Condition which those Functionalities should follow)
- Phase-2 : Using Requirement Document, create DDL schema for the Module (mention detail whay those table require and what is the meaning of each fields in those tables)

Provide me a Prompt which should read all required files from above Folders and then generate above documents. Save the Prompt in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/1-Sub-Modules/CommonChat". Prompt should read all the files from below Folders before generating all the documents :
- Read Files from `/Users/bkwork/Herd/prime_ai/Modules/StudentProfile` to understand `StudentProfile` Module
- Read Files from `/Users/bkwork/Herd/prime_ai/Modules/SchoolSetup` to understand `SchoolSetup` Module
- Read AI_Brain to get detailed understanding about Folder Paths & Application as required.