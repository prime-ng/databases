
Which area of SmartTimetable do you want to work on first?                                                                   
  
❯ 1. Phase 1: Critical Bug Fixes (Recommended)                                                                               
     Fix 9 runtime crash bugs (set_time_limit, saveGeneratedTimetable data loss, missing Shift/Period models, duplicate    
     routes, etc.) — 0.5 day effort, highest ROI
  2. Phase 2: Security Hardening
     Add EnsureTenantHasModule, Gate::authorize() to 17 unprotected controllers, protect truncate() ops, implement
     SmartTimetablePolicy — 3 days effort
  3. Phase 5: Room Allocation
     Implement RoomAllocationPass so room_id is no longer NULL, wire into generation, show rooms in views — 3 days effort
  4. Phase 11: Constraint Architecture
     Build ConstraintRegistry, ConstraintContext, ConstraintEvaluator — foundation for all 125+ unimplemented constraint
     rules — 3 days effort
  5. Type something.
  6. Chat about this
  7. Skip interview and plan immediately

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

## CONFIGURATION
```
AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
SOURCE_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis
OUTPUT_DIR     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/8-Smart_Timetable/Claude_Tasks/Task-2
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
MODULE_PATH    = {LARAVEL_REPO}/Modules/SmartTimetable
ROUTES_FILE    = {LARAVEL_REPO}/routes/tenant.php
DATE           = 2026-03-17
```

Read the SmartTimetable Gap Analysis files from (`{SOURCE_DIR}`) and generate Tasks & Sub-Tasks for all 37 action items identified in Sections 9-10 of the gap analysis. Each prompt must be a self-contained, ready-to-execute Claude prompt that a developer can paste into Claude to complete that specific task.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Create A Prompt which create a detailed list of Tasks & Sub-Tasks by reading all the file you just created in "5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis" and finally which should store that Tasks file into "5-Work-In-Progress/8-Smart_Timetable/Claude_Tasks/Task-2" Folder.
Store that Prompt into "5-Work-In-Progress/8-Smart_Timetable/Claude_Prompt" Filename "Prompt_to_create_Tasks.md"
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


Below are the requirement you need to produce for all 3 (Account, Payroll & Inventory) Modules :
- I have already create 3 Foleders for all 3 Module :
  - Account - "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/20-Account"
  - Payroll - "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/21-Payroll"
  - Inventory - "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/22-Inventory"
- First Create a Detail Requirement for all 3 Modules in there respective folder mentione above.


─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

The existing tenant_db has both `fin_*` tables (StudentFee module, 80% done) AND `acc_fee_*` tables in the accounting DDL. How should we handle this overlap?                                                       
                                                                                                                                                                                                                  
  1. Bridge approach (Recommended)           
     acc_fee_* tables act as the accounting bridge — linking existing fin_fee_head_master records to GL ledgers. StudentFee module stays as-is, Accounting reads from it.
  2. Replace with acc_fee_*
     Migrate StudentFee to use acc_fee_* tables instead. Higher risk — breaks existing 80% complete module.
  3. Remove acc_fee_* tables
     Drop the fee-related tables from Accounting DDL entirely. Accounting only handles journals, ledgers, and reports — not fee structures.
  4. Type something.
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

I have made some changes in "1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v2.md" & "1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement.md" but still I wanted you to make required changes by considering below conditions/Rules: 
- I want to create all 3 Modules Separate (Modules/Accounting/), (Modules/Inventory/) & (Modules/Payroll/) and DO NOT want to have single consolidated Module for all 3.
- Transport module also connected with Acounting Module as School will changes Transport fees as per Student's Registration to use Transport from a specific Stopage.
- I have made changes in Table Prefix in "Initial_Plan_v2.md" follow those.
- 1 table `sch_employees` (in your plan named as `acc_employees`) is already part of tenant_db, so you need not to create is again but if you need any additional columns in the table, then enhance the table as per the need.
- We will be having Dedicated database per tenant ensures complete data isolation. So NO NEED to have `tenant_id` column in any table.
- Ensure to have some mapping machanizm to map Tally Ledger Account with our Application's Ledger Account that we have in our account Module.
- In Section - "## 8. Integration Points" of "Account_Requirement.md", you need to add Transport Module Integration also.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

I have renamed "Payroll_Requirement.md" to "Payroll_Requirement_v1.md" and move it to Folder "1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/". I have also renamed "Inventory_Requirement.md" to "Inventory_Requirement_v1.md" and move it to Folder "1-DDL_Tenant_Modules/22-Inventory/Claude_Plan/". Now I want to refine these tables also similarly as you refined for "Accounting" and Create new files "Payroll_Requirement_v2.md" & "Inventory_Requirement_v2.md" in Folder "1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/" & "1-DDL_Tenant_Modules/22-Inventory/Claude_Plan/" respectively. I wanted you to make required changes by considering below conditions/Rules:
- I want to create all 3 Modules Separate (Modules/Accounting/), (Modules/Inventory/) & (Modules/Payroll/) and DO NOT want to have single consolidated Module for all 3.
- 2 table are already part of tenant_db as mentioned below :
   - `sch_leave_types` - This table will capture type of Leaves available for All the staff.
   - `sch_leave_config` - This table will capture Leave configuration for different staff categories and leave types
- We will be having Dedicated database per tenant ensures complete data isolation. So NO NEED to have `tenant_id` column in any table.
- Any required changes which you have uderstood from my previous instruction and applicable to these 2 Modules.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Before I start working on next tasks, update yourself that . I have renamed "Account_Requirement_v3.md" to "Account_Requirement_v2.md" in folder "1-DDL_Tenant_Modules/20-Account/"Claude_Plan/"

In "1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v3.md", You have written 3 tables in Section "**Enhanced Existing Tables**" :
`sch_employees`, `sch_employee_groups` & `sch_employee_attendance` but actually we have only 1 Table in Existing Schema that is `sch_employees`.

For "1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/Payroll_Requirement_v2.md", you have to consider below points:
- Read `sch_leave_config`, `sch_leave_types` & `sch_categories` in Tenant_db.sql. These are the tables which are having school wise statndard configuration for leave Management. 
- These Tables have below Information :
   - What type of Leaves are allowed in the school.
   - What is the standard Leave balance allocation every Year for which category.
   - School may different categories and school may different No of Leaves allocated to different Categories e.g. Teacher's No of leave may differ from other staff etc.
   - `sch_leave_types` also capture information which type of leave are Paid which type of leaves are unpaid.
- you to uderstand those 3 Tables in detail and do enhancement if required in "1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/Payroll_Requirement_v2.md"

Finally I want you to :
- Read "/databases/0-DDL_Masters/tenant_db_v2.sql" in detail to verify all the table which you mentioned available should be actually available.
- Evaluate any duplication of Table creationg should not be in any of these 3 Modules.
- If you find any Duplication or any table does not exeist which you consider exeists then make all require changes in all 4 files accordingly.
- Stictly Verify whatever Table you consider exists should be in atleast any one of the db Schema file in folder "databases/0-DDL_Masters".
- Also check Any Table which you consider to be created New should not be duplicate of any exeisting Table in 3 DB Schemas in folder "databases/0-DDL_Masters".

Other than all above points if you find anything needs to be enhanced and modified then include those in your plan and create all Enhanced files at below location :
- `Initial_Plan_v4.md` at `databases/20-Account/Claude_Plan/`
- `Account_Requirement_v3.md` at `databases/20-Account/Claude_Plan/`
- `Payroll_Requirement_v3.md` at `databases/21-Payroll/`
- `Inventory_Requirement_v3.md` at `databases/22-Inventory/`

*(Same as v2)*

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Same way enhance "databases/1-DDL_Tenant_Modules/22-Inventory/Claude_Plan/Inventory_Requirement_v3.md" also for below items :
- Check all the "*(Same as v2)*" in "Inventory_Requirement_v3.md" and find the exact section it refere to and add those sections from source file to in this file to make it completely independent.
- Remove all "*(Same as v2)*" from the file.
- Read "databases/0-DDL_Masters/tenant_db_v2.sql" and make sure every reference for other module should be correct in "Inventory_Requirement_v3.md".
- Create a new Enhanced File with named "databases/1-DDL_Tenant_Modules/22-Inventory/Claude_Plan/Payroll_Requirement_v4.md"

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

I want to create a detailed Prompt for Accounting Module which cover all 
Now I have 2 below input files for Accountng Module:
1. "1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md"
2. "1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement_v4.md"

Provide me a Prompt which shoudl cover all 9 Phases mentioned in "3-Design_Architecture/Module_Wise_Dev_Prompt/Accounting_Dev-Lifecycle.md" and produce All the Outputs mentioned in all the Phases in below Files :
- `databaes/3-Design_Architecture/Dev_BluePrint/Development_Lifecycle_Blueprint_v1.md`
- `databaes/3-Design_Architecture/Dev_BluePrint/Development_Lifecycle_Blueprint_v2.md`

Your Mission:
- Read "databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md" to understand Initial Plan.
- Read "dataases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement_v4.md" to understand Requirement of Accounting Module
- Read `Development_Lifecycle_Blueprint_v1.md` & `Development_Lifecycle_Blueprint_v2.md` from Folder `databaes/3-Design_Architecture/Dev_BluePrint/` to understand What Output I need from the Prompt.
- after providing output for each phase, prompt should wait for my confirmation
- Every Output file will have a different name with MODULE_CODE prefix
- Use Below Configuration to provide user Input:
      MODULE_CODE       = ACC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
      MODULE            = Accounting             # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
      MODULE_DIR        = Modules/Accounting/    # Used in: file paths (Modules/Hpc/), git commands
      BRANCH            = Brijesh_Accounting     # Used in: context for the prompt
      DEVELOPER         = Brijesh                 # Used in: context for the prompt
      RBS_MODULE_CODE   = K
      DB_TABLE_PREFIX   = acc_
      DATABASE_NAME     = tenant_db
      OUTPUT_DIR        = databases/5-Work-In-Progress/20-Accounting/1-Claude_Prompt

Store the prompt into folder "databases/5-Work-In-Progress/20-Accounting/1-Claude_Prompt"

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Prompt should cover all below Requirement:
- Prompt should be capable to produce output mentioned in all the Phases in both the above files.
-  

OUTPUT_REPO     = {OLD_REPO}
OUTPUT_DIR      = {OUTPUT_REPO}/8-Temp_Output
OUTPUT_DIR_A    = {OUTPUT_DIR}/Bugs_Missing_Modules
OUTPUT_DIR_B    = {OUTPUT_DIR}/1-DDL_Tenant_Modules/21-Payroll/DDL
OUTPUT_DIR_C    = {OUTPUT_DIR}/1-DDL_Tenant_Modules/21-Payroll/DDL
OUTPUT_DIR_D    = {OUTPUT_DIR}/1-DDL_Tenant_Modules/21-Payroll/DDL

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

I have created a prompt to Generate "Feature Specification", "Complete Development Plan" & "Database Schema Design" for Payroll Module at "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/21-Payroll/1-Claude_Prompt/Payroll_2Phases_Prompt.md". Please enhance it for Payroll Module and make it more complete. Save the output file as "databases/5-Work-In-Progress/21-Payroll/1-Claude_Prompt/Payroll_2Phases_Prompt2.md"

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

I get a Prompt from you to do a Deep Gap Analysis in the file "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Working_with_TEAM/3-Shailesh/Deep_Gap_Analysis_Prompt_v2.md". Read the Prompt file in Detail and do below enhancement:
- Some places prompt is written in Hindi, convert thos esentences into English.
- The 1st Section "List of Modules" of the prompt file is having list of the Modules present in my project. I want you to enhance the Promt file in such way that I will execute the entire file and claude run the analysis for all the Modules one by one from List and create separate Output file for every Module in {OUTPUT_DIR_A}.
- Correct the last section "START NOW — EXECUTION ORDER"
- Store the New Enhanced File into "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Working_with_TEAM/3-Shailesh" file name "Deep_Gap_Analysis_Prompt_v3.md"

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

