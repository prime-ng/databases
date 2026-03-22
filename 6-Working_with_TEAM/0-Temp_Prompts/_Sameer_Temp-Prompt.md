# Temp Prompt for Testing Rekated Work
======================================


## To Create Testcases
========================================================================================================================================

## CONFIGURATION
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

Provide me a generic Prompt which can create all type of Tastcases for Any Module. Testcases Type should be :
- Unit Testcases - Should be stored into {LARAVEL_REPO}/"tests/Unit/{MODULE_NAME}
- Feature Testcase - Should be stored into {LARAVEL_REPO}/"tests/Feature/{MODULE_NAME}
- Browser Testcase - UI / UX Testcases should be stored into {LARAVEL_REPO}/"tests/Browser/{MODULE_NAME}

Rules:
- It should use test_agent of AI_Brain
- To get understanding of 

========================================================================================================================================
