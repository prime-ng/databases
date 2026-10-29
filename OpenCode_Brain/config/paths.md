# OpenCode Brain — Path Configuration
# ================================================================================
# SINGLE SOURCE OF TRUTH for all file/folder locations.
# All OpenCode_Brain files use {VARIABLE} syntax instead of hardcoded paths.
#
# TO CHANGE A PATH: Update the value here, then tell the agent:
#   "paths changed in config/paths.md, propagate to all OpenCode_Brain files"
#
# VARIABLE RESOLUTION: Variables can reference other variables using {VAR}.
#   {DDL_DIR} = {DB_REPO}/1-Master_DDLs  resolves to full absolute path.
# ================================================================================

## Repositories

```
DB_REPO          = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/
OLD_REPO         = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db
OPENCODE_BRAIN   = {OLD_REPO}/OpenCode_Brain
LARAVEL_REPO     = /Users/bkwork/Herd/prime_ai_dev
LARAVEL_OPENCODE = {OPENCODE_BRAIN}/instructions
```

> **Application repo:** `{LARAVEL_REPO}` is `/Users/bkwork/Herd/prime_ai_dev` on this machine.
> `/Users/bkwork/Herd/prime_ai` exists but is empty and must not be used.

## Final Audit (Code Auditor)

```
AUDIT_REPO          = /Users/bkwork/Herd/prime_testing
AUDIT_REPORTS       = {AUDIT_REPO}/final-audit-reports
AUDIT_INFO          = {AUDIT_REPORTS}/_Info
AUDIT_CONFIG        = {AUDIT_REPORTS}/_config/audit_path.md
AUDIT_TEMPLATES     = {AUDIT_REPORTS}/_templates
AUDIT_TOOLS         = {AUDIT_REPORTS}/_tools
AUDIT_PROTOCOL      = {AUDIT_REPO}/.claude/rules/final-audit.md
AUDIT_PROTOCOL_COPY = {AUDIT_INFO}/FINAL-AUDIT-PROTOCOL.md
AUDIT_RULEBOOK      = {AUDIT_TOOLS}/00-RULEBOOK.md
AUDIT_CLASS_OWNERS  = {AUDIT_INFO}/00-CLASS-OWNERS.md
AUDIT_README        = {AUDIT_INFO}/README.md
AUDIT_DEVELOPERS    = tarun | shailesh | gaurav
AUDIT_APP_ROOT      = {LARAVEL_REPO}
AUDIT_MODULE_DIR    = {LARAVEL_REPO}/Modules
```

> **Rule:** the auditor starts in `{AUDIT_REPO}`. Report paths (`final-audit-reports/…`) are
> relative to it; application paths (`Modules/…`, `app/…`, `config/…`) and every
> `php artisan` command run from `{LARAVEL_REPO}`. Never create a developer folder.
> `<Module>` may exist as `<Module>-done` after a fix pass — check both.

## OpenCode Configuration (this brain)

```
OPENCODE_ROOT      = {OPENCODE_BRAIN}
OPENCODE_AGENTS    = {OPENCODE_BRAIN}/.opencode/agents
OPENCODE_COMMANDS  = {OPENCODE_BRAIN}/.opencode/commands
OPENCODE_SKILLS    = {OPENCODE_BRAIN}/.opencode/skills
OPENCODE_INSTRUCT  = {OPENCODE_BRAIN}/instructions
OPENCODE_CONFIG    = {OPENCODE_BRAIN}/opencode.json
OPENCODE_AGENTS_MD = {OPENCODE_BRAIN}/AGENTS.md
```

> OpenCode auto-discovers `AGENTS.md` at the workspace root, learns the agent files in
> `.opencode/agents/`, the commands in `.opencode/commands/`, and the skills in `.opencode/skills/`
> when the working directory is `{OPENCODE_BRAIN}`. The module-scoped rules in
> `{OPENCODE_BRAIN}/instructions/` are the OpenCode equivalent of path-scoped rules — read the
> matching file before working on a module.

## Rules

```
WORK_OUTPUT_DEFAULT = {OLD_REPO}/9-Working_tmp/Temp_Output_Files
```

> **Rule:** All AI work output (analysis, prompts, context files, gap reports, etc.) goes into `{OLD_REPO}` by default. 
> Only store in `{DB_REPO}` when explicitly told.
> If a prompt doesn't specify where to store output, either ASK or use `{OLD_REPO}`.
> `{OLD_REPO}` is the day-to-day working repository. It is NOT used in the application.
> `{DB_REPO}` contains production schema files used by the application.
> `{DB_REPO}` is a copy of database schema files of `{OLD_REPO}` and is being used by {LARAVEL_REPO}. 
> For all AI work (creating requirement doc, analysis etc.), always use `{OLD_REPO}`.
> All OpenCode_Brain agents (business-analyst, technical-auditor etc.) should always use `{OLD_REPO}`.
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

## Key Locations — OLD_REPO (working repo / AI output)
```
PROJECT_PLAN              = {OLD_REPO}/5-Project_Planning
PROJECT_DOCS              = {PROJECT_PLAN}/1-Project_docs
RBS_DIR                   = {OLD_REPO}/4-Requirement_Module_wise/1-RBS
FRD_DIR                   = {OLD_REPO}/4-Requirement_Module_wise/0-FRD_Documents
REQUIREMENT_OLD           = {OLD_REPO}/4-Requirement_Module_wise/4-Initial_Requirements/V2
REQUIRE_DETAIL_V1         = {OLD_REPO}/4-Requirement_Module_wise/2-Module_Requirement_V1/[MODULE]*
REQUIRE_DETAIL_V2         = {FRD_DIR}/[MODULE]
REQUIREMENT_CONDITIONS    = {OLD_REPO}/4-Requirement_Module_wise/5-Requirement_Conditions
GAP_ANALYSIS              = {OLD_REPO}/6-Dev_Gap_Analysis_Status/Modules_Gap_Analysis
DEEP_ANALYSIS             = {OLD_REPO}/3-Audit_Reports
WORK_STATUS               = {OLD_REPO}/6-Dev_Gap_Analysis_Status/Progress_Status
DESIGN_ARCH               = {OLD_REPO}/5-Design_Architecture
```

## Template Paths (for business-analyst agent output)
> **Rule:** These are old Files. A new file will be created and paths updated once done.
```
TPL_RBS            = {RBS_DIR}/[MODULE]_RBS.md
TPL_FEATURE_SPEC   = {PROJECT_PLAN}/3-Feature_Specs/[MODULE]_FeatureSpec.md
TPL_GAP            = {GAP_ANALYSIS}/2-Modules_Wise/2026Mar22/[MODULE]_Gap_Analysis.md
TPL_SPRINT_TASKS   = {PROJECT_PLAN}/4-Sprint_Tasks/[MODULE]_Tasks.md
```

> Template paths: folders are created on first use. `[MODULE]` is replaced with actual module name.


## Initial Level Files
> **Rule:** These are old Files. A new file will be created and paths updated once done.
```
LIFECYCLE_BLUEPRINT            = {DESIGN_ARCH}/Dev_BluePrint/Development_Lifecycle_Blueprint_v2.md
RBS_MAPPING                    = {RBS_DIR}/PrimeAI_RBS_Menu_Mapping_v2.0.md
GAP_ANALYSIS_PROJECT           = {GAP_ANALYSIS}/1-Complete_Project
GAP_ANALYSIS_PROJECT_FILE      = {GAP_ANALYSIS_PROJECT}/PrimeAI_Gap_Analysis_v1.0.md
GAP_ANALYSIS_MODULE_WISE       = {GAP_ANALYSIS}/2-Modules_Wise/2026Mar22
TT_PARALLEL_TASKS              = {OLD_REPO}/1-DDL_Modules/Timetable_Smart/Claude_Context/2026Mar11_ParallelPeriod_Tasks.md
HPC_GAP_ANALYSIS               = {OLD_REPO}/Z-Archived/5-Work-In-Progress/1-Completed/HPC/Claude_Prompts/HPC_Gap_Analysis/2026Mar16_HPC_Complete_Gap_Analysis.md
```

> **Note:** The `Claude_Context/` and `Claude_Prompts/` folder names above are real, pre-existing
> working folders in `{OLD_REPO}`. They are kept verbatim so the paths still resolve.
