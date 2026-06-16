# Temporary Prompts File
========================

--------------------------------------------------------------------------------------------

OLD_REPO     = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db
OLD_MODULE   = StudentPortal
OLD_MOD_FILE = {OLD_REPO}/5-Work-In-Progress/StudentPortal/1-Claude_Prompt/STP_2step_Prompt1.md
NEW_MODULE   = ParentPortal
NEW_REQ_FILE = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/PPT_ParentPortal_Requirement.md
OUTPUT_DIR   = {OLD_REPO}/5-Work-In-Progress/ParentPortal/1-Claude_Prompt

Create aN EXACTLY SAME prompt for `{NEW_MODULE}` Module as you have created for `{OLD_MODULE}` Module in File `{OLD_MOD_FILE}`. The Requirement File for `{NEW_MODULE}` Module is `{NEW_REQ_FILE}`. Store the final prompt for `{NEW_MODULE}` Module in Folder `{OUTPUT_DIR}`

---------------------------------------------------------------------------------------------
## Partially Done


### Created
-----------
Payroll
Inventory
FrontOffice
AdmissionMgmt
Hostel
Cafeteria
StudentPortal
ParentPortal
VisitorSecurity
Certificate
Maintenance


### Pending
-----------
LXP
PredictiveAnalytics
Communication
Notification


### Check
---------
Academics
Attendance
Recommendation
JOB_Scheduler

-----------------------
### Then Run The Prompt
-----------------------

---------------------------------------------------------------------------------------------
## Done

The Feedback DDL which you created in the last session (old_db/1-Module_DDLs/Feedback/StudentFeedback_ddl_v2.sql). you have used ENUM many places.
I want to avoid ENUM, as ENUM limits the options available for that data type. You can use one option from the below :
- I have created a Generic Dropdown table system. For which I have a Table `sys_dropdown_table` in DDL `old_db/0-DDL_Masters/tenant_db_v2.sql`
- If above table doesnt suit the requirement then create a new Table in the DDL to provide data for that Field
- Enum should be used only available options for tht field can not changed and the field is having fixed options only.

Create a new Enhanced DDL file as "/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Module_DDLs/Feedback/StudentFeedback_ddl_v3.sql"

---------------------------------------------------------------------------------------------
## Pending

I am in Process of developing StudentPortal Module. To understand what has been developed and what was Requirement you need to read below files :
- Read all the files from folder "/Users/bkwork/Herd/prime_ai/Modules/StudentPortal" to understand what has been developed.
- Read "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md" to understand what is the requirement.
- you can also add other items which are relevent to be on the Student Portal

Finally I want you to create a detailed requirement document for Student Portal in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-Requirement_Module_wise/2-Detailed_Requirements/V3"


---------------------------------------------------------------------------------------------
## Pending

Read all .md files in "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db" and find below path and replace them as mentioned below :
- Replace "Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases" with "Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db"
- Replace "databases/" with "old_db/"

Once you are done create a Report as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/Z-Temp_Old/Path_Updates/Update_old_db_path.md" by including complete detail what you have updated and which file has ben updated.

---------------------------------------------------------------------------------------------

Prompt - For Updating DDL Master from Module wise DDLS



---------------------------------------------------------------------------------------------

Prompt - Review Recommendation Module



---------------------------------------------------------------------------------------------
## Done

Prompt - How to calculate all the fields in `qns_question_statistics`

I have a table `qns_question_statistics` in `old_db/1-DDL_Tenant_Modules/51-QuestionBank/DDL/Question_Bank_ddl_v1.2.sql` DDL. This table will be used to capture Statistical Information for Questions. You can also read 
Read "old_db/1-DDL_Tenant_Modules/51-QuestionBank/DDL/Question_Bank_ddl_v1.2.sql" and provide me the detail how to calculate `guessing_factor` in Table `qns_question_statistics` in the DDL. If required you can    
  read AI_Brain to understand how All the Sub-Module in LMS Module works. Provide me the complete Formula with Table Refernce.   



---------------------------------------------------------------------------------------------

-- Need to create a Key in sch_config for getting Threshold for calculate Recommandation Due_date, will be used in Quiz / Quest.
-- Recommendation will be assigned only in Quiz / Quest. No recommendatino in Exam.
-- only in Quiz - Check "performance_percentage_threshold_to_reassign_quiz" in 'sch_config' to generate & assign new uiz to the Student

Shailesh - Need to create a screen

---------------------------------------------------------------------------------------------

I want to create Behavioral Assesment Module where Students will be assigned some Behavioural Assessment tasks which belongs to Behavioural Categories. The Teacher will Rate them on the basis of their performance on those Behavioral Categories. School may decide to include those Ratings in the Final Exam Result  with a Lower Weightage. Create a Detailed Requirement Document for Behavioral Assessment, which I can provide to AI to create DDL Schema and other Development Related Documents. I have collected below Behavioral Assessment points but you need to refine and add more in those and then ceate a detailed Requirement Document.

---------------------------------------------------------------------------------------------

I have an initial requirement document for 'Behavioural_Assessment' Module as "/Users/bkwork/WorkFolder/3-Local_Workspace/8-Requirement/BehaviouralAssessment_Requirements_v1.md". Provide me 

---------------------------------------------------------------------------------------------

I will provide you DDL Schem & Complete Code Location for a Particuler Module. Give me a Prompt to create a Report after verifing all below items :
 - Compare all the Tables in DDL Schema with Fields covered in the Code and provide detail of all Missing Fields or if anything extra in the code.
 - Compare Migration with Tables in DDL Schema and provide detail of all Missing Fields or if anything extra in the migration.
 - Compare everything with each other DDL Schema, migration of the Module, Model etc. and provide detail if anything is missing or if anything is extra anywhere.
 - Do complete analysis and let me know any you find any dicripency in that Module

Keep Module Name and other required location Path and File name Configurable in the Prompt. Save the Prompt in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/2-Gap_Analysis"

---------------------------------------------------------------------------------------------
Below is my requirement and I have a Initial version of Prompt to cater below requirement which was created by Claude Sonnet. Now I want you to evaluate the Prompt and enhance it if required. Save the new prompt as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Marksheet_Generation/MSG_Module_Prompt_v2.md". Below is my initial requirement for the Marksheet Generation Prompt but you can add other features as well if I missed anything -

I want to create Configuration Setup to generate Marksheet for Students. Schools may use below Module to add Marks as per School's need :
 - LmsHomework
 - LmsQuiz
 - LmsQuest
 - LmsExam
 - BehaviouralAssessment

There are Some Conditions, which are required to be followed when Configur for Marksheet Generation :
- Read AI_Brain to understand all required Path
- LmsExam is having 2 type of Exams in it Online Exam & Offline Exam, Scholl may use both.
- Marks provided in above Module may have different Weightage in the Final Marksheet (e.g. Homework may have very low weighateg 5%, BehaviouralAssessment may have 10%)
- Every Class will have multipal Exams e.g. UT1, UT2, UT3, UT4, Half Yearly Exam, Annual Exam ect. (School need to configure weighatge for every Exam)
- Different Classes may have Different Type of Configuration (weightage) OR a Group Class can share same Configuration also.
- Some classes may have Practical Exam also which also needs to present in Final Marksheet.
- School may provide Marksheet 2 Time (After half Yearly Exam & Annual Exam) or it may choose to provide Marksheet after every Exam. So Configuration will be different for different Marksheets.

Now I want you to provide a Prompt which can read & Understand all above Module then Create all below required output :
- Create a detailed Development Plan
- Create DDL Schema
- Create Datab Dictionary
- Requirement Specification document for Marksheet Generation


---------------------------------------------------------------------------------------------
## Done

Now you need to read and understand Template Module from "prime_ai_main/Modules/Template". Template Module is mainly to create different type of Templates for different need of the school e.g. Template to Print Marksheet, Template to Generate ID card etc. To Generate some output like Marksheet or ID card school may have more then 1 Template for same purpose. Now we need to have a configurable system whcih will capture information that Whcih Temlate School want to use to generate a Particuler Output e.g. Whcih Template System need to use to Print Marksheet for Lower Classes (1st to 5th) & Which template will be used to generate Marksheet for higer classes (6th to 12th) etc. Below are some possible conditions school may have :
- Different Class Group 'msh_class_groups' may use different template for the same output
- School can Configur which Template it want to use for Marksheet Printing for a Particuler Class Group, Which Template it want to use for Staff ID Card printing, Which template they want to seu for Student ID Card Print etc.

Now I want you to create a prompt which should read all required files and create DDL Schema to capture the configuration Feature. Save the Prompt into "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Marksheet_Generation"


---------------------------------------------------------------------------------------------

I have some queries on ParentPortal & StudentPortal Modules. First read AI_Brain to get all the Path then Read and understand both Modules (ParentPortal & StudentPortal) from LARAVEL_REPO.

Perant Portal : information required
Where to show consent forms in the Dashboard?
Where to create/show Parent Meeting confirmation?
Where to show complaints in the Dashboard ?
What data to show in the Transport page of Parent & Student ?

---------------------------------------------------------------------------------------------

I want to work on SmartTimetable Module. Understand the complete Module by reading below files :
- Read all the files from folder '/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Input'
- To understand complete development read below Modules from below location
  - Read '/Users/bkwork/Herd/prime_ai/Modules/TimetableFoundation'
  - Read '/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable'
  - Controller, Routes & Models of both the Module

I noticed 1 issue in the SmartTimetable Module -
- 

SECTION 0: CONFIGURATION TABLES
  - `sch_academic_term` - This Table capture detail about a aprticuler academic Term. 
    - Field `term_week_start_day` - Capture Info. which day will be consider as 1st day of the week (e.g. Monday or Saturday etc.)

  - TABlE `tt_config` - This Table capture all Major config Parameters of Timetable Module
    - Key `week_start_day` - Capture Info. which day will be consider as 1st day of the week (e.g. Monday or Saturday etc.)
    - Key `default_school_open_days_per_week` - How many days school will be open per day
    - Key `total_number_of_period_per_day` - How many periods school will be open every day
    - Key `default_number_of_short_breaks_daily_before_lunch` - How many Breaks school will have before Lunch
    - Key `default_number_of_short_breaks_daily_after_lunch` - How many Breaks school will have after Lunch
    - Key `default_total_number_of_short_breaks_daily` - 
    - Key `default_total_number_of_period_before_lunch` - 
    - Key `default_total_number_of_period_after_lunch` - 





---------------------------------------------------------------------------------------------
## Changes need to be made by Tarun
-----------------------------------
### Timetable DDl


### Tenant_db
Table - `sch_org_academic_sessions_jnt`




---------------------------------------------------------------------------------------------

Now I want to work on SmartTimetable Module. First read AI_Brain to get understanding on SmartTimetable Module and then Read the DDL schema of the Module from file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/DDL/tt_timetable_ddl_v7.6.sql" and suggest best solution for below Issue :
- Table `tt_period_set` & `tt_period_set_period_jnt` capture how many periods different classes have and timeslot for each periods for every classes. But since there is no direct control to make sure that timeslot should remain same for every class though different classes may have different number of periods. For example Normally school has 6 periods for Lower classes (1st & 2nd) whereas on the same day higher classes (3rd to 12th) have 8 Periods per day but period's timing remain same. So lower classes does not have period 1 and period 8th they have 6 periods starting from 2nd Periods and their classes ends by 7th periods. In current DDL Application may accept diffrent timeslot for different classes, which should nt allow. I need to have enhance the DDL to accomodate this requirement. 
My proposed solution to resolve this problem is I should create a new Table named `tt_period_config` which will be capture timeslot for every Period, Breaks and Lunch also. Whereas other tables like `tt_period_set` & `tt_period_set_period_jnt` will not capture Timeslot for Periods but will refer to `tt_period_config` table.  `tt_period_set` & `tt_period_set_period_jnt` can capture from which Period to Which Period different Classes will be having School timing but can not have Timeslot.

 Now I want you to act as a Senior Database Architect and create a New DDL file as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/DDL/tt_timetable_ddl_v7.7.sql". Keep all the detail from exeisting file `tt_timetable_ddl_v7.6.sql` also which is not required any change and enhance tables whereever required which adding new Tables if required.
---------------------------------------------------------------------------------------------
## DONE

Now I want you to create a similer document for SmartTimetable also as you have created for `MarksheetGneration` Module in file "db_design_guide.md". Create a similer format Document for SmartTimetable Module in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/DDL". Read "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/DDL/tt_timetable_ddl_v7.7.sql" to understand DDL Schem which you have created in last session and create a document "tt_db_design_guide.md" in same folder with below detail :               
  - Doc should have relationship digram of ables.
  - What is the use of all the Table(Why those Tables are Required)
  - What all the fields in each table are required.
  - What should be the data Capturing Flow.
  - Any other important detail related to the database tables.

---------------------------------------------------------------------------------------------

Now create an Implementation Guide for how to Generate & Show Marksheet to the Student / Teacher by using Template Module which will fatch the required data from MarksheetGeneration Module. As a first step Marksheet (Rating & Marks will be created in MarksheetGeneration Module using Configuration) will be created in MarksheetGeneration Module and then to showcase the Marksheet to the Student, system will use Template Module for th configuration & Template design and the data will be fethced from MarksheetGeneration Module. Before go for creation the Implementation Guide you need to read all below files & Folders :
- Read both files from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/LMS_MarksheetGeneration/DDL" for MarksheetGeneration DDL & Design
- Read both files from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Template/DDL" to understand Template Module

Create New Implementtion Guide in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Template/Design"

---------------------------------------------------------------------------------------------
Priviously I have created DDL Schema for HR & Payrol in File "

---------------------------------------------------------------------------------------------
Read "old_db/1-DDL_Tenant_Modules/Library/DDL/Library_ddl_v4.sql" and evaluate the DDL Schema 

 Create a file to provide Calculation Process with Formulas for all the Fields (Which needs to be Calculated by App) in all the Tables in DDL
  "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Library/DDL/Library_ddl_v6.sql". Save the file as
  "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Library/Design/Calculation_Formulas.md". This should include all required detail SQL Queries, Stored procedure, Views, or anything which is required to get those Calculated Field filled with the required values.

---------------------------------------------------------------------------------------------

