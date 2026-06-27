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

Read and execute "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-CLAUDE_Prompts/0-Important_Prompts/Save_Context.md"
---------------------------------------------------------------------------------------------

Priviously I have created DDL Schema for HR & Payrol in File "

---------------------------------------------------------------------------------------------
Read "old_db/1-DDL_Tenant_Modules/Library/DDL/Library_ddl_v4.sql" and evaluate the DDL Schema 

 Create a file to provide Calculation Process with Formulas for all the Fields (Which needs to be Calculated by App) in all the Tables in DDL
  "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Library/DDL/Library_ddl_v6.sql". Save the file as
  "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Library/Design/Calculation_Formulas.md". This should include all required detail SQL Queries, Stored procedure, Views, or anything which is required to get those Calculated Field filled with the required values.

---------------------------------------------------------------------------------------------
Yesterday when I asked you to update AI_brain, you have also created a file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/6-Dev_Gap_Analysis_Status/Deep_Analysis/2026-06-21/known-issues.md", where you have provide analysis of the code, whatever gaps you found along with security concerns. Read the file to understand what you have done over there. Now I want you to Provide me 2 Prompts for performing a Very Deep Analysis of my entire Application (Prime_AI). This Prompt should cover every possible aspects 

---------------------------------------------------------------------------------------------

I want to creat a separate Agent(Technical_Auditor) to analysis my entire application (starting from DDL Schema, Coding Quality and upto Code Deployment and Performance). Similerly I wanted to create a 'Testing_Architect' also to analyze and create everything related to the Testing of my Prime_Ai app. How can I achieve thos, what all steps I need to follow, provide the complete plan as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Temp_Output_Files/New_Agent_Creation_plan.md"

---------------------------------------------------------------------------------------------

Use the file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Temp_Output_Files/New_Agent_Creation_plan.md" you just created and Provide me 2 prompts to create 2 Agents "Technical Auditor" & "Testing Architect". Save both Prompts as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-CLAUDE_Prompts/Agent_Creation_Prompts/Tech_Auditor_Agent_creation_Prompt.md" & "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-CLAUDE_Prompts/Agent_Creation_Prompts/Testing_Architect_Agent_creation_Prompt.md"

## Output Summary :
How to use either prompt:
1. Open a new Claude Code session in this repo
2. Open the prompt file
3. Copy everything below === PROMPT START === and paste into chat
4. Claude will create the agent file, update CLAUDE.md, and confirm with Active role system updated.

After running both prompts, you'll activate agents simply by typing:
- act as Technical Auditor — 5-layer audit (DDL → code → security → perf → deploy)
- act as Testing Architect — test strategy, Pest writing, coverage gap analysis, CI setup

============================================================
# HOW TO USE THIS PROMPT:
- Open a new Claude Code session in VS Code (in this repo).
- Paste the entire content below the line "=== PROMPT START ===" into the chat.
- Claude will create the agent file, update CLAUDE.md, and confirm.
---------------------------------------------------------------------------------------------

Phase 2 code audit of 10 modules is complete with 108 findings written to known-issues.md. Next: run the two agent creation prompts to actually create the Technical Auditor and Testing Architect agent files in AI_Brain/agents/.

---------------------------------------------------------------------------------------------
## Prompt
I am not Agree with the completion %, you have mentioned in the Last Report of Complaint Module. I think we neeed to enhance the process of calcuating Completion %. How you calculate the Completion %, provide the Complete detail, I will review it and will provide feedback of what enhancement are required. Save the Output into "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/7-Work_with_CLAUDE/Temp_Output_Files/ModuleCompletionCalculationFormula.md"

Done
---------------------------------------------------------------------------------------------

