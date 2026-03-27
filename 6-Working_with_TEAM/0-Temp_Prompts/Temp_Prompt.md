 Review all the REquirement Files in Folder "2-Requirement_Module_wise/2-Detailed_Requirements/V1" and enhance them whereever require. in file   
  "2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/HRS_HrStaff_Requirement.md" you mention "HrStaff is distinct from the Payroll module (`prl_*`)", whcih is not True 

  ---

I have asked you  to create Modue wise Requirement Documents using prompt "databases/2-Requirement_Module_wise/Requirement_Creation_Prompts/Consolidated_Prompt_for_Opus/Module_Requirement_Generation_Prompt_v3.md". I used Claude Sonnet to create those REquirements because Opus was taking too much tokans and was not able to complete the cycle.
Now I have created an enhanced RBS file "3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v4.0.md" and I wanted to created new version of ERquirement files for all the Modules on the basis of my new RBS. Provide a Prompt for the same which create all new File in folder "databases/2-Requirement_Module_wise/2-Detailed_Requirements/V2". save that Prompt in folder "databases/2-Requirement_Module_wise/Requirement_Creation_Prompts/Consolidated_Prompt_for_Opus"

In HRS (HrStaff) Module File "2-Requirement_Module_wise/2-Detailed_Requirements/V2/HRS_HrStaff_Requirement.md", you have mentioned All items related to Payroll (prl_) Out of Scope But I wanted to keep a single Module for HR & Payroll Both. So update that file (HRS_HrStaff_Requirement.md) as `HRS_HrStaff_Requirement_v2.md` and incude all Payroll Related Task mentioned in the lates RBS "3-Project_Planning/1-RBS/PrimeAI_Complete_Spec_v2.md". Also consider additional steps (if anything left in latest RBS) to make it complete `HR & Payroll` Module with all possible requirement of a school to manage HR & Payrol Department.



--------------------------------------------------------------------------------------------

OLD_REPO     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
OLD_MODULE   = StudentPortal
OLD_MOD_FILE = {OLD_REPO}/5-Work-In-Progress/StudentPortal/1-Claude_Prompt/STP_2step_Prompt1.md
NEW_MODULE   = ParentPortal
NEW_REQ_FILE = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/PPT_ParentPortal_Requirement.md
OUTPUT_DIR   = {OLD_REPO}/5-Work-In-Progress/ParentPortal/1-Claude_Prompt

Create aN EXACTLY SAME prompt for `{NEW_MODULE}` Module as you have created for `{OLD_MODULE}` Module in File `{OLD_MOD_FILE}`. The Requirement File for `{NEW_MODULE}` Module is `{NEW_REQ_FILE}`. Store the final prompt for `{NEW_MODULE}` Module in Folder `{OUTPUT_DIR}`

---------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------

OLD_REPO     = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
OLD_MODULE   = Inventory
OLD_MOD_FILE = {OLD_REPO}/5-Work-In-Progress/22-Inventory/1-Claude_Prompt/INV_2step_Prompt1.md
NEW_MODULE   = Maintenance
NEW_REQ_FILE = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/MNT_Maintenance_Requirement.md
OUTPUT_DIR   = {OLD_REPO}/5-Work-In-Progress/Maintenance/1-Claude_Prompt

Create aN EXACTLY SAME prompt for `{NEW_MODULE}` Module as you have created for `{OLD_MODULE}` Module in File `{OLD_MOD_FILE}`. The Requirement File for `{NEW_MODULE}` Module is `{NEW_REQ_FILE}`. Store the final prompt for `{NEW_MODULE}` Module in Folder `{OUTPUT_DIR}`

---------------------------------------------------------------------------------------------

## Created
----------
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



## Pending
----------
LXP
PredictiveAnalytics


Communication

Notification


## Check
--------
Academics
Attendance
Recommendation
JOB_Scheduler

--------------------------------------------------------------
## Run The Prompt
-----------------



