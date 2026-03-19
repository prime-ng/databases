
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

---------------
Create A Prompt which create a detailed list of Tasks & Sub-Tasks by reading all the file you just created in "5-Work-In-Progress/8-Smart_Timetable/1-Timetable_Gap_Analysis" and finally which should store that Tasks file into "5-Work-In-Progress/8-Smart_Timetable/Claude_Tasks/Task-2" Folder.
Store that Prompt into "5-Work-In-Progress/8-Smart_Timetable/Claude_Prompt" Filename "Prompt_to_create_Tasks.md"
---------------

Below are the requirement you need to produce for all 3 (Account, Payroll & Inventory) Modules :
- I have already create 3 Foleders for all 3 Module :
  - Account - "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/20-Account"
  - Payroll - "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/21-Payroll"
  - Inventory - "/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/22-Inventory"
- First Create a Detail Requirement for all 3 Modules in there respective folder mentione above.





The existing tenant_db has both `fin_*` tables (StudentFee module, 80% done) AND `acc_fee_*` tables in the accounting DDL. How should we handle this overlap?                                                       
                                                                                                                                                                                                                  
  1. Bridge approach (Recommended)           
     acc_fee_* tables act as the accounting bridge — linking existing fin_fee_head_master records to GL ledgers. StudentFee module stays as-is, Accounting reads from it.
  2. Replace with acc_fee_*
     Migrate StudentFee to use acc_fee_* tables instead. Higher risk — breaks existing 80% complete module.
  3. Remove acc_fee_* tables
     Drop the fee-related tables from Accounting DDL entirely. Accounting only handles journals, ledgers, and reports — not fee structures.
  4. Type something.

----------------------------------------------------------------------------------------------------
I have made some changes in "1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v2.md" & "1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement.md" but still I wanted you to make required changes by considering below conditions/Rules: 
- I want to create all 3 Modules Separate (Modules/Accounting/), (Modules/Inventory/) & (Modules/Payroll/) and DO NOT want to have single consolidated Module for all 3.
- Transport module also connected with Acounting Module as School will changes Transport fees as per Student's Registration to use Transport from a specific Stopage.
- I have made changes in Table Prefix in "Initial_Plan_v2.md" follow those.
- 1 table `sch_employees` (in your plan named as `acc_employees`) is already part of tenant_db, so you need not to create is again but if you need any additional columns in the table, then enhance the table as per the need.
- We will be having Dedicated database per tenant ensures complete data isolation. So NO NEED to have `tenant_id` column in any table.
- Ensure to have some mapping machanizm to map Tally Ledger Account with our Application's Ledger Account that we have in our account Module.
- In Section - "## 8. Integration Points" of "Account_Requirement.md", you need to add Transport Module Integration also.


I have renamed "Payroll_Requirement.md" to "Payroll_Requirement_v1.md" and move it to Folder "1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/". I have also renamed "Inventory_Requirement.md" to "Inventory_Requirement_v1.md" and move it to Folder "1-DDL_Tenant_Modules/22-Inventory/Claude_Plan/". Now I want to refine these tables also similarly as you refined for "Accounting" and Create new files "Payroll_Requirement_v2.md" & "Inventory_Requirement_v2.md" in Folder "1-DDL_Tenant_Modules/21-Payroll/Claude_Plan/" & "1-DDL_Tenant_Modules/22-Inventory/Claude_Plan/" respectively. I wanted you to make required changes by considering below conditions/Rules:
- I want to create all 3 Modules Separate (Modules/Accounting/), (Modules/Inventory/) & (Modules/Payroll/) and DO NOT want to have single consolidated Module for all 3.
- 2 table are already part of tenant_db as mentioned below :
   - `sch_leave_types` - This table will capture type of Leaves available for All the staff.
   - `sch_leave_config` - This table will capture Leave configuration for different staff categories and leave types
- We will be having Dedicated database per tenant ensures complete data isolation. So NO NEED to have `tenant_id` column in any table.
- Any required changes which you have uderstood from my previous instruction and applicable to these 2 Modules.
