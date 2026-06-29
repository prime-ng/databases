# Prompt to Run FRD & Tech Audit for all the Modules
I want to write a Single Prompt which should have 3 Phases and execute below step in exact same sequence :
## PHASE-1
```
- First Read all the info from "/old_db/0-Prime_Ai_Detail/module_list.md" and collect MODULE_NAME, MODULE_CODE, & MODULE_PREFIX
- Search Module Knowledge file : {MODULE_CODE}_{MODULE_CODE}.md exists in the folder : "old_db/AI_Brain/module-knowledge"
    1. If Exists then execute : update module knowledge for {MODULE_NAME}
       ELSE execute : seed module knowledge for {MODULE_NAME}
```
## PHASE-2
```
- Search FRD File : {MODULE_CODE}_FRD_Complete_YYYY-MM-DD in folder : "old_db/4-Requirement_Module_wise/0-FRD_Documents"
    1. If Exists then : do nothing
       ELSE execute : `/agent business-analyst` → Complete analysis of {MODULE_NAME} Module
```
## PHASE-3
```
- Search Technical Audit File : {MODULE_NAME}_Complete_Audit_YYYY-MM-DD in folder : "old_db/3-Audit_Reports/V1_Jun-2026"
    1. If Exists then : do nothing
       ELSE execute : `/agent technical-auditor` → Complete audit of {MODULE_NAME} Module
```
- Move to Next line of "module_list.md" to pick next MODULE_NAME, MODULE_CODE, & MODULE_PREFIX
- Do this till the last Module in "module_list.md"

### Rules
- **No Change other below 3 Folders** Prompt should NOT change anything other below 3 folders
    - /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge
    - /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents
    - /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Reports/V1_Jun-2026
- **Do Not for reading & writing file** Just do the job for all the Modules, DO NOT wait for my responce.
- if Claude Quota Limit reach then wait to get it Reset and then REsume the work.

Write the Complete Prompt which should strictly follow all above Rules and save it as "/old_db/7-CLAUDE_Prompts/3-Create_ModuleKnowledge_FRD_TechAudit/Prompt_Create_ModuleKnowledge_FRD_TechAudit.md"




