# AI Brain — Path Configuration
# ================================================================================
# SINGLE SOURCE OF TRUTH for all file/folder locations.
# All AI_Brain files use {VARIABLE} syntax instead of hardcoded paths.
#
# TO CHANGE A PATH: Update the value here, then tell Claude:
#   "paths changed in config/paths.md, propagate to all AI_Brain files"
#
# VARIABLE RESOLUTION: Variables can reference other variables using {VAR}.
#   {DDL_DIR} = {DB_REPO}/1-Master_DDLs  resolves to full absolute path.
# ================================================================================

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/
OLD_REPO       = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## Rules

```
WORK_OUTPUT_DEFAULT = {OLD_REPO}/9-Working_tmp/Temp_Output_Files
```

> **Rule:** All Claude work output (analysis, prompts, context files, gap reports, etc.) goes into `{OLD_REPO}` by default. 
> Only store in `{DB_REPO}` when explicitly told.
> If a prompt doesn't specify where to store output, either ASK or use `{OLD_REPO}`.
> `{OLD_REPO}` is the day-to-day working repository. It is NOT used in the application.
> `{DB_REPO}` contains production schema files used by the application.
> `{DB_REPO}` is a copy of database schema files of `{OLD_REPO}` and is being used by {LARAVEL_REPO}. 
> For all AI work (creating requirement doc, analysis etc.), always use `{OLD_REPO}`.
> All AI_Brain agents (business-analyst, technical-auditor etc.) should always use `{OLD_REPO}`.
> use `{DB_REPO}` schema files only when explicitly told to use those.

## Key Locations — OLD_REPO (development schema)
```
DEV_DDL_DIR                 = {OLD_REPO}/0-DDL_Masters
DEV_MODULE_DDL_DIR          = {OLD_REPO}/2-DDL_Tenant_Consolidated
DEV_GLOBAL_DDL              = {DEV_DDL_DIR}/global_db_v4.sql
DEV_PRIME_DDL               = {DEV_DDL_DIR}/prime_db_v4.sql
DEV_TENANT_DDL              = {DEV_DDL_DIR}/tenant_db_v4.sql
DEV_CONFIG_TABLES           = {OLD_REPO}/0-Config_Tables
DEV_POLICIES                = {OLD_REPO}/0-Policies
```

## Key Locations — DB_REPO (production schema)
```
DDL_DIR                 = {DB_REPO}/1-Master_DDLs
MODULE_DDL_DIR          = {DB_REPO}/2-DDL_Tenant_Consolidated
GLOBAL_DDL              = {DDL_DIR}/global_db_v3.sql
PRIME_DDL               = {DDL_DIR}/prime_db_v3.sql
TENANT_DDL              = {DDL_DIR}/tenant_db_v3.sql
CONFIG_TABLES           = {DB_REPO}/3-Config_Tables
POLICIES                = {DB_REPO}/3-Policies
```

## Key Locations — OLD_REPO (working repo / Claude output)
```
PROJECT_PLAN              = {OLD_REPO}/5-Project_Planning
PROJECT_DOCS              = {PROJECT_PLAN}/1-Project_docs
RBS_DIR                   = {OLD_REPO}/4-Requirement_Module_wise/1-RBS
FRD_DIR                   = {OLD_REPO}/4-Requirement_Module_wise/0-FRD_Documents
REQUIREMENT_OLD           = {OLD_REPO}/4-Requirement_Module_wise/4-Initial_Requirements/V2
REQUIRE_DETAIL_V1         = {OLD_REPO}/4-Requirement_Module_wise/2-Module_Requirement_V1/[MODULE]*
REQUIRE_DETAIL_V2         = {FRD_DIR}/[MODULE]
REQUIREMENT_CONDITIONS    = {OLD_REPO}/4-Requirement_Module_wise/5-Requirement_Conditions
GAP_ANALYSIS              = {OLD_REPO}/6-Dev_Status_Analysis/Modules_Gap_Analysis
DEEP_ANALYSIS             = {OLD_REPO}/6-Dev_Status_Analysis/Deep_Analysis
WORK_STATUS               = {OLD_REPO}/6-Dev_Status_Analysis/Progress_Status
DESIGN_ARCH               = {OLD_REPO}/5-Design_Architecture
```

## Template Paths (for business-analyst agent output)
> **Rule:** These are old Files. I am going to create new file and will update Paths once done.
```
TPL_RBS            = {RBS_DIR}/[MODULE]_RBS.md
TPL_FEATURE_SPEC   = {PROJECT_PLAN}/3-Feature_Specs/[MODULE]_FeatureSpec.md
TPL_GAP            = {GAP_ANALYSIS}/2-Modules_Wise/2026Mar22/[MODULE]_Gap_Analysis.md
TPL_SPRINT_TASKS   = {PROJECT_PLAN}/4-Sprint_Tasks/[MODULE]_Tasks.md
```

> Template paths: folders are created on first use. `[MODULE]` is replaced with actual module name.


## Initial Level Files
> **Rule:** These are old Files. I am going to create new file and will update Paths once done.
```
LIFECYCLE_BLUEPRINT            = {DESIGN_ARCH}/Dev_BluePrint/Development_Lifecycle_Blueprint_v2.md
RBS_MAPPING                    = {RBS_DIR}/PrimeAI_RBS_Menu_Mapping_v2.0.md
GAP_ANALYSIS_PROJECT           = {GAP_ANALYSIS}/1-Complete_Project
GAP_ANALYSIS_PROJECT_FILE      = {GAP_ANALYSIS_PROJECT}/PrimeAI_Gap_Analysis_v1.0.md
GAP_ANALYSIS_MODULE_WISE       = {GAP_ANALYSIS}/2-Modules_Wise/2026Mar22
TT_PARALLEL_TASKS              = {OLD_REPO}/1-DDL_Modules/Timetable_Smart/Claude_Context/2026Mar11_ParallelPeriod_Tasks.md
HPC_GAP_ANALYSIS               = {OLD_REPO}/Z-Archived/5-Work-In-Progress/1-Completed/HPC/Claude_Prompts/HPC_Gap_Analysis/2026Mar16_HPC_Complete_Gap_Analysis.md
```
