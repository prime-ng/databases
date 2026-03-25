# Prompts - Temporary
=====================

============================================================================================================================
Now you are having a complete understanding of What is required to generate "HPC Report Card" and how it should be filled. 
Now I want you to perform below tasks : 
- Evaluate the Development done to Generate those Report Card

DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain

I will update my AI_BRAIN in folder "/pgdatabase/9-Support/BrainBackup"

After copy that AI_BRAIN, you have perform below tasks -
- Ask Claude to update Your Local Repository Location in AI_BRAIN, because your Local Repository path is different from mine.
- Update your AI_BRAIN path also
- 

============================================================================================================================

I want to create a Config file for AI_BRAIN, so that in future if I get any need to change location of any file, I need not to do this entire excersice with you but I can only change the Config path as per my change and AI_BRAIN will be able to find all the reference. Do not start creating it but answer my below query first : 
- It this a good idea to make AI_BRAIN config because changing file location or File name is a normal requirement
- If you are agree then tell me how you will do it and how easy it iwll be for me to change the Path of any file?

- AI_BRAIN Path will always be "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain"
- DB_REPO will alwasy be "/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase"
- Every work output of Claude should be stored in some folder within "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/" till I am specificly not saying that this should be stored in New DB_REPO.
- In any Prompt I forgot to mentioned where you need to store it then either ask me where I want it to be stored or select some folder in OLD_REPO (/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/)
- OLD_REPO is now my day to day working Repository and will not be used in the Application.

============================================================================================================================
## Question:
Can I create a config file for me which I can use as Claude Command. Which will my life bit easy. I can create user freindly command as per my choice and Claude will understand those command from that config file. First only asnwer my query and if Yes I can then provide me the complete how can you do that for me and How will I use it?

## Responce:

Yes, absolutely. Claude Code has a built-in feature for exactly this — they're called Skills (slash commands).

  You already have some: /test, /review, /schema, /lint, /module-status — these are all custom commands defined in your AI_Brain.

  How it works

  You create a simple markdown file with instructions. When you type /command-name in Claude, it loads that file and follows those instructions.

  What you can create

  Any command you want. Examples:

  ┌────────────────────────┬──────────────────────────────────────────┐
  │      Your Command      │               What It Does               │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /gap-analysis Hpc      │ Run a full gap analysis on a module      │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /update-brain          │ Update AI_Brain files from a source doc  │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /fix-paths             │ Propagate config/paths.md to all files   │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /status                │ Show overall project status              │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /new-prompt ModuleName │ Generate a prompt template for a module  │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /check-links           │ Scan AI_Brain for broken file references │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /sprint-plan Hpc       │ Create a sprint plan for a module        │
  └────────────────────────┴──────────────────────────────────────────┘

  Where they live

  ~/.claude/skills/
  ├── gap-analysis/SKILL.md      ← /gap-analysis
  ├── update-brain/SKILL.md      ← /update-brain
  ├── fix-paths/SKILL.md         ← /fix-paths
  └── ...

  Each SKILL.md is just a markdown file with:
  - A name and description (frontmatter)
  - Step-by-step instructions Claude follows when you invoke it

  How easy is it?

  - Creating: Write a markdown file describing what you want Claude to do
  - Using: Just type /command-name with optional arguments
  - Editing: Change the markdown file, next invocation uses the new version — no restart needed

  Want me to create some commands for you? If yes, tell me what commands would make your daily work easier and I'll build them.

I want to create all those custom skills in a saperate folder named "custom_skills" in OLD_REPO

-------------------------------------

/resume-last Hpc : I want to

/start-day Hpc : When start work after closing VS-CodeI want to start my day with work on HPC Module, So refresh Memory on HPC Module
/start-fresh Hpc : Now I want to start work on a new Module Named "HPC", So create Memory for HPC Module
/switch-to Hpc : Till Now I was working on some other Module Now I want to switch to "HPC" Module, So refresh Memory on HPC Module
/save-session


============================================================================================================================



============================================================================================================================
## CONFIGURATION
```
AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
APP_REPO       = /Users/bkwork/Herd/prime_ai_shailesh
APP_BRANCH     = Brijesh_HPC
DATABASE_REPO  = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
DATABASE_FILE  = {DATABASE_REPO}/1-Master_DDLs/tenant_db_v2.sql
MODULE_NAME    = Hpc
MODULE_PATH    = {APP_REPO}/Modules/Hpc
OUTPUT_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/14-HPC/Claude_Prompts/TestCase_Prompt
ROUTES_FILE    = {APP_REPO}/routes/tenant.php
DATE           = 2026-03-17
```
SOURCE_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/14-HPC

============================================================================================================================
```
AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
APP_REPO       = /Users/bkwork/Herd/prime_ai_shailesh
APP_BRANCH     = Brijesh_HPC
DATABASE_REPO  = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
DATABASE_FILE  = {DATABASE_REPO}/1-Master_DDLs/tenant_db_v2.sql
MODULE_NAME    = Hpc
MODULE_PATH    = {APP_REPO}/Modules/Hpc
SOURCE_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/2-Requirement_Module_wise/1-HighLevel_Requirements/{MODULE_NAME}
OUTPUT_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/14-HPC/Claude_Prompts/TestCase_Prompt
ROUTES_FILE    = {APP_REPO}/routes/tenant.php
DATE           = 2026-03-17
```


Provide me Prompt to Generate a Detailed Requirement for any Module. I will provide Highlevel requirement of the Module in {SOURCE_DIR}. 


-----------------------------------------------------------------------------------------------------------------------------
One of my team member has done some work on `Student Portal` & `Parent Portal`. He has updated his AI_Brain. The copy of his AI_Brain is in the folder "9-Support/BrainBackup/AI_Brain". When i check mainly he has updated 2 below File in AI_Brain:
- 9-Support/BrainBackup/AI_Brain/memory/MEMORY.md
- 9-Support/BrainBackup/AI_Brain/state/progress.md

Update the AI_Brain in my System (/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain) from these File if anything is missing, as Now I am going to work on these Modules (`Student Portal` & `Parent Portal`)

Read files from below Folders and update AI_Brain.
- "/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/8-Team_Work/Shailesh/Student Parent Portal"
- "/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/7-Work_on_Modules/StudentParentPortal"
- "/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/7-Work_on_Modules/LMS"

---------------------------------------------------
I have created Complete Development Master Plan in File "databases/7-Work_with_Claude/2-Claude_Dev_Plan/Complete_Dev_Master_Plan_v1.md".

---------------------------------------------------
Below are the fucntionalities I need to be covered in LMS-Homework. Read and Evaluate LMS_Homework DDl from "databases/1-DDL_Tenant_Modules/52-LMS_Homework/DDL/LMS_Homework_DDL_v2.sql" and create 


Below is the highlevel Requirement of LMS_Homework Module:

LMS_Homework Requirement:
1. Create Homework `lms_homework_submissions`
  - Select class & subject
  - Enter homework instructions
  - Attach supporting files
  - Fill all the Fileds (e.g. is_gradable, max_marks, passing_marks, allow_late_submission, auto_publish_score)
2. Lesson Planning (Homework Scheduling) `slb_syllabus_schedule`
  - Teacher will feed Lesson Plan (scheduling)
  - `scheduled_start_date`, `scheduled_end_date` & `planned_periods` etc. for Lesson, Topic, Sub-Topic
3. Homework Assignment (New Table Need to be Created)
  - Teacher change Topic/Sub-Topic status -> Completed
  - System will check `realease_condition`
      If Homework needs to be assigned on the Topic Comletion, then
        - Create Entry in `lms_homework_assignment` Table for all the Student of the selected Class+Section+Subject
      IF `realease_condition` = 'ON_SCHEDULED_DATE' then
        - Create Entry in `lms_homework_assignment` Table for all the Student of the selected Class+Section+Subject with `release_scheduled_date`
      IF `realease_condition` = 'IMMEDIATE' then
        - Create Entry in `lms_homework_assignment` Table for all the Student of the selected Class+Section+Subject with Immediatly
    - Fill all the requireed Fileds (e.g. allow_late_submission etc.)
    - Teacher can allow one student for late_submission inemergency whereas for other student it is not allowed.
    - So the fields which can have diiferent value for different Student needs to be in the New table.
4. Homework Submission `lms_homework_submissions`
  - Student complete Homework
  - Submit Homework
5. Review Submission	`lms_homework_submissions`
  - View submitted files
  - Review Submission	Evaluate and grade
6. Feedback	`lms_homework_submissions`
  - Provide written feedback
  - Send notification to parents
  
I have already Created 2 Tables in LMS_Homework (`lms_homework`, `lms_homework_submissions`) and 1 Table in `slb_syllabus_schedule`. Some other dependet tables are also there. Now I want you to evaluate all those table and create a new Table for Homework Assignment (`lms_homework_assignment`). Let me know if you have any other suggestion for enhanccement. LMS_Homework ddl is at "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/52-LMS_Homework/DDL/LMS_Homework_DDL_v2.sql", You have to create a New Enhanced DDl named "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/52-LMS_Homework/DDL/LMS_Homework_DDL_v3.sql"
