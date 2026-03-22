# AI Brain — Path Configuration
# ============================================================
# SINGLE SOURCE OF TRUTH for all file/folder locations.
# All AI_Brain files use {VARIABLE} syntax instead of hardcoded paths.
#
# TO CHANGE A PATH: Update the value here, then tell Claude:
#   "paths changed in config/paths.md, propagate to all AI_Brain files"
#
# VARIABLE RESOLUTION: Variables can reference other variables using {VAR}.
#   {DDL_DIR} = {DB_REPO}/1-Master_DDLs  resolves to full absolute path.
# ============================================================

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## Rules

```
WORK_OUTPUT_DEFAULT = {OLD_REPO}/8-Temp_Output
```

> **Rule:** All Claude work output (analysis, prompts, context files, gap reports, etc.) goes into `{OLD_REPO}` by default. 
> Only store in `{DB_REPO}` when explicitly told.
> If a prompt doesn't specify where to store output, either ASK or use `{OLD_REPO}`.
> `{OLD_REPO}` is the day-to-day working repository. It is NOT used in the application.
> `{DB_REPO}` contains production schema files used by the application.

## Key Locations — DB_REPO (production schema)

```
DDL_DIR                 = {DB_REPO}/1-Master_DDLs
MODULE_DDL_DIR          = {DB_REPO}/1-Module_DDLs
GLOBAL_DDL              = {DDL_DIR}/global_db_v2.sql
PRIME_DDL               = {DDL_DIR}/prime_db_v2.sql
TENANT_DDL              = {DDL_DIR}/tenant_db_v2.sql
CONFIG_TABLES           = {DB_REPO}/2-Config_Tables
POLICIES                = {DB_REPO}/3-Policies
WORK_ON_MODULES         = {DB_REPO}/7-Work_on_Modules
TEAM_WORK               = {DB_REPO}/8-Team_Work
DB_SUPPORT              = {DB_REPO}/9-Support

```

## Key Locations — OLD_REPO (working repo / Claude output)
```
OLD_DDL_DIR           = {OLD_REPO}/0-DDL_Masters
OLD_PRIME_DDL_DIR     = {DB_REPO}/1-DDL_Prime_Modules
OLD_TENANT_DDL_DIR    = {DB_REPO}/1-DDL_Tenant_Modules```
PROJECT_PLAN          = {OLD_REPO}/3-Project_Planning
PROJECT_DOCS          = {PROJECT_PLAN}/Project_Docs
RBS_DIR               = {PROJECT_PLAN}/1-RBS
GAP_ANALYSIS          = {PROJECT_PLAN}/2-Gap_Analysis
WORK_STATUS           = {PROJECT_PLAN}/9-Work_Status
DESIGN_ARCH           = {OLD_REPO}/3-Design_Architecture
WORK_IN_PROGRESS      = {OLD_REPO}/5-Work-In-Progress
HPC_CONTEXT           = {WORK_IN_PROG}/14-HPC/Claude_Context
TT_CONTEXT            = {WORK_IN_PROG}/8-Smart_Timetable/Claude_Context
TEAM_PROMPTS          = {OLD_REPO}/6-Working_with_Team
CLAUDE_PROMPTS        = {WORK_IN_PROG}/14-HPC/Claude_Prompts
CLAUDE_LOG            = {OLD_REPO}/9-CLAUDE_Logs
TEMP_OUTPUT_DIR       = {OLD_REPO}/8-Temp_Output
```

## Key Files

```
LIFECYCLE_BLUEPRINT            = {DESIGN_ARCH}/Dev_BluePrint/Development_Lifecycle_Blueprint_v2.md
HPC_GAP_ANALYSIS               = {HPC_CONTEXT}/HPC_Gap_Analysis_Complete.md
RBS_MAPPING                    = {RBS_DIR}/PrimeAI_RBS_Menu_Mapping_v2.0.md
GAP_ANALYSIS_PROJECT           = {GAP_ANALYSIS}/1-Complete_Project
GAP_ANALYSIS_PROJECT_FILE      = {GAP_ANALYSIS_PROJECT}/PrimeAI_Gap_Analysis_v1.0.md
GAP_ANALYSIS_MODULE_WISE       = {GAP_ANALYSIS}/2-Modules_Wise
TT_PARALLEL_TASKS              = {TT_CONTEXT}/2026Mar11_ParallelPeriod_Tasks.md
```

## Template Paths (for business-analyst agent output)

```
TPL_RBS            = {RBS_DIR}/[MODULE]_RBS.md
TPL_FEATURE_SPEC   = {PROJECT_PLAN}/3-Feature_Specs/[MODULE]_FeatureSpec.md
TPL_GAP            = {GAP_ANALYSIS}/[MODULE]_Gap.md
TPL_SPRINT_TASKS   = {PROJECT_PLAN}/4-Sprint_Tasks/[MODULE]_Tasks.md
```

> Template paths: folders are created on first use. `[MODULE]` is replaced with actual module name.
