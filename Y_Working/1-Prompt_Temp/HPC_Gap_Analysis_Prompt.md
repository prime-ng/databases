 # PROMPT: Complete HPC Module Gap Analysis

  ## Mode
  Switch to **Business Analyst** mode. Perform a comprehensive gap analysis of the HPC
  (Holistic Progress Card) module.

  ---

  ## CONFIGURATION
  MODULE         = HPC
  MODULE_DIR     = Hpc
  LARAVEL_ROOT   = /Users/bkwork/Herd/prime_ai_shailesh
  MODULE_PATH    = /Users/bkwork/Herd/prime_ai_shailesh/Modules/Hpc
  DB_REPO        =
  /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
  AI_BRAIN       =
  /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  OUTPUT_FILE    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/5-Work-In-Progress/14-HPC/Claude_Context/HPC_Gap_Analysis_Complete.md
  BRANCH         = Brijesh_HPC
  DEVELOPER      = Shailesh
  DATE           = 2026-03-16

  ---

  ## PRE-READ (Mandatory — read ALL before analysis)

  ### Tier 1: AI Brain Context (read first)
  1. `{AI_BRAIN}/memory/project-context.md` — Tech stack, 3-layer DB, external services
  2. `{AI_BRAIN}/memory/modules-map.md` — HPC row: controllers, models, services,
  status %, known issues
  3. `{AI_BRAIN}/memory/school-domain.md` — School entity relationships
  4. `{AI_BRAIN}/memory/decisions.md` — D9 (DomPDF), D13 (HPC PDF pattern), D18 (CRUD
  auto-mapping), D19 (queued email)
  5. `{AI_BRAIN}/memory/conventions.md` — Naming standards
  6. `{AI_BRAIN}/lessons/known-issues.md` — Search for ALL entries: SEC-HPC-*,
  BUG-HPC-*, PERF-HPC-*

  ### Tier 2: HPC Design & Requirements (read second)
  7. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_requirement.md` — Full HPC
  requirement (large file, read in chunks)
  8. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_ImplementationBlueprint.md` —
  9-section blueprint: phases, screens, APIs, data flow
  9. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_screen_requirement.md` —
  Screen-by-screen specs
  10. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_enhancement.md` — Schema
  analysis & recommendations
  11. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/screen_design.md` — UI design specs
  12. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/DDL/Template_HPC_ddl_v2.sql` — Canonical
  DDL schema
  13. `{DB_REPO}/Y_Working/4-Module_wise_Design/14-HPC/Info.md` — NEP 2020 domain
  knowledge (abilities, descriptors, competencies)
  14. `{DB_REPO}/Y_Working/4-Module_wise_Design/14-HPC/Assignment_Type.md` — Assessment
   tier architecture

  ### Tier 3: Previous Analysis (read third — to avoid repeating work)
  15.
  `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Claude_Prompt/2026Mar14_HPC_Gap_Analysis.md` —
   Previous gap analysis (GAP-1 to GAP-8)
  16. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Claude_Prompt/2026Mar14_HPC_Data_Collectio
  n_Plan.md` — 5-phase implementation plan

  ### Tier 4: Actual Codebase (read/scan fourth — this is the SOURCE OF TRUTH)
  17. `{MODULE_PATH}/app/Http/Controllers/` — List ALL controllers, read each public
  method signature
  18. `{MODULE_PATH}/app/Models/` — List ALL models, check $table, $fillable,
  relationships, SoftDeletes
  19. `{MODULE_PATH}/app/Services/` — List ALL services, read method signatures
  20. `{MODULE_PATH}/app/Jobs/` — List ALL jobs
  21. `{MODULE_PATH}/app/Mail/` — List ALL mailables
  22. `{MODULE_PATH}/app/Http/Requests/` — List ALL FormRequests, check authorize()
  return value
  23. `{MODULE_PATH}/resources/views/` — Recursively list ALL blade files, count per
  subfolder
  24. `{MODULE_PATH}/routes/web.php` and `{MODULE_PATH}/routes/api.php` — Check if
  scaffold routes exist (should be empty)
  25. `{LARAVEL_ROOT}/routes/tenant.php` — Search for ALL HPC routes (prefix 'hpc'),
  extract route list with methods and controller actions
  26. `{LARAVEL_ROOT}/database/migrations/tenant/` — Search for `*hpc*` migration files
  27. `{MODULE_PATH}/tests/` — Check if any tests exist
  28. `{MODULE_PATH}/database/seeders/` — Check if any seeders exist

  ### Tier 5: Cross-Module Dependencies (scan fifth)
  29. `{LARAVEL_ROOT}/Modules/StudentProfile/app/Models/Student.php` — Relationships
  used by HPC
  30. `{LARAVEL_ROOT}/Modules/StudentProfile/app/Models/Guardian.php` — Email field for
   queued email
  31. `{LARAVEL_ROOT}/Modules/SchoolSetup/app/Models/Organization.php` — Used in PDF
  generation
  32. `{LARAVEL_ROOT}/Modules/SmartTimetable/app/Models/AcademicTerm.php` — FK
  dependency

  ---

  ## ANALYSIS DIMENSIONS (6 dimensions)

  ### Dimension 1: Feature Completeness vs Blueprint
  Compare EVERY screen/feature listed in `hpc_ImplementationBlueprint.md` (Section 4:
  Screen Requirements, Section 7: Implementation Phasing) against actual code.

  For each screen/feature produce:
  | Screen/Feature | Blueprint Section | Controller Method | View Exists? | Route
  Registered? | Status | Gap Description |
  |---|---|---|---|---|---|---|
  | SC-01: Template Builder | Phase 1 | HpcTemplatesController::* | Yes/No | Yes/No |
  DONE / PARTIAL / NOT STARTED | What's missing |

  ### Dimension 2: Schema vs Code Alignment
  Compare `Template_HPC_ddl_v2.sql` tables against:
  - Models: Does every table have a model? Is $table correct? Is $fillable complete?
  - Migrations: Does every table have a migration in `database/migrations/tenant/`?
  - Relationships: Are all FKs reflected as Eloquent relationships?

  Produce:
  | DDL Table | Model Exists? | Model Name | $fillable Complete? | Migration Exists? |
  Relationships OK? | Issues |
  |---|---|---|---|---|---|---|

  ### Dimension 3: Security & Authorization Audit
  For EVERY public method in EVERY HPC controller:
  | Controller | Method | Has Gate::authorize? | FormRequest Used? | FR authorize()
  Logic | $request->validated() Used? | Issues |
  |---|---|---|---|---|---|---|

  Also check:
  - EnsureTenantHasModule middleware on route group
  - Cross-layer model imports (Prime/Global models in tenant context)
  - $fillable contains `is_super_admin` or `remember_token`?
  - Any `dd()`, `dump()`, hardcoded API keys?

  ### Dimension 4: Route Health Check
  For EVERY registered HPC route in tenant.php:
  | HTTP Method | URI | Controller@Method | Method Exists? | Import Exists? | Trash
  Before Resource? | Issues |
  |---|---|---|---|---|---|---|

  Flag: dead routes (method doesn't exist), missing imports (will 500), shadowed routes
   (trash after resource)

  ### Dimension 5: Data Flow & Integration Gaps
  Using the Data Capture Matrix from `hpc_ImplementationBlueprint.md` (Section 3):
  | Data Element | Source Module | Auto-Feed Implemented? | Manual Entry Required? |
  Status | Gap |
  |---|---|---|---|---|---|

  Cover:
  - Student master data → HPC (auto-populate from StudentProfile)
  - Attendance → HPC (auto-populate from std_student_attendance)
  - Exam scores → HPC (LmsExam integration)
  - hpc_student_evaluation → hpc_report_items (auto-feed)
  - Parent input mechanism
  - Student self-service mechanism
  - Peer assessment mechanism

  ### Dimension 6: Multi-Actor Data Collection (from previous Gap Analysis)
  Validate current status of GAP-1 through GAP-8 from `2026Mar14_HPC_Gap_Analysis.md`:
  | Gap ID | Description | Status (Still Open / Partially Fixed / Resolved) | Evidence
  | Remaining Work |
  |---|---|---|---|---|

  ---

  ## OUTPUT FORMAT

  Write the complete analysis to `{OUTPUT_FILE}` with this structure:

  ```markdown
  # HPC Module — Complete Gap Analysis
  **Date:** 2026-03-16
  **Branch:** Brijesh_HPC
  **Auditor:** Claude (Business Analyst Agent)
  **Codebase:** /Users/bkwork/Herd/prime_ai_shailesh/Modules/Hpc

  ---

  ## Executive Summary
  - Total screens in blueprint: N
  - Screens fully implemented: N (X%)
  - Screens partially implemented: N (X%)
  - Screens not started: N (X%)
  - Critical security issues: N
  - Critical bugs: N
  - Overall module completion: X%

  ## 1. Feature Completeness vs Blueprint
  [Dimension 1 table]

  ## 2. Schema vs Code Alignment
  [Dimension 2 table]

  ## 3. Security & Authorization Audit
  [Dimension 3 table]
  ### Summary: X/Y methods have Gate::authorize
  ### Summary: X/Y FormRequests have real authorize() logic

  ## 4. Route Health Check
  [Dimension 4 table]
  ### Dead Routes: [list]
  ### Missing Imports: [list]
  ### Shadowed Routes: [list]

  ## 5. Data Flow & Integration Gaps
  [Dimension 5 table]

  ## 6. Multi-Actor Data Collection Status
  [Dimension 6 table]

  ## 7. Known Issues Status (from AI Brain)
  | Issue ID | Severity | Description | Status | Notes |
  |---|---|---|---|---|
  | SEC-HPC-001 | CRITICAL | ... | OPEN / PARTIAL / RESOLVED | ... |
  [All SEC-HPC-*, BUG-HPC-*, PERF-HPC-* entries]

  ## 8. Priority Action Items
  ### P0 — Critical (fix before any new feature)
  1. ...
  ### P1 — High (fix this sprint)
  1. ...
  ### P2 — Medium (fix next sprint)
  1. ...
  ### P3 — Low (backlog)
  1. ...

  ## 9. Effort Estimation
  | Category | Item Count | Estimated Effort |
  |---|---|---|
  | Security fixes | N methods | Xh |
  | Bug fixes | N bugs | Xh |
  | Missing features | N screens | X days |
  | Integration (auto-feed) | N data flows | X days |
  | Multi-actor (student/parent/peer portals) | 3 portals | X weeks |
  | Tests | 0 → target coverage | X days |
  | **Total** | | **X developer-weeks** |

  ---
  RULES

  1. Code is the source of truth — if AI Brain says "done" but code shows stub/missing,
   mark as NOT DONE
  2. Read actual files — do not guess. Open controllers, read method bodies, check for
  Gate::authorize as first line
  3. Every claim must have evidence — file path + line number or "file not found"
  4. Do NOT fix anything — this is analysis only, no code changes
  5. Do NOT skip any controller/model/route — exhaustive audit
  6. Cross-reference previous gap analysis but VERIFY against current code — things may
   have changed since 2026-03-14
  7. Count everything — total methods, total with auth, total without, percentages
  8. Flag cross-layer imports — any Modules\Prime\* or App\Models\* used in tenant
  context
  9. Check tenant.php import section — missing use statements cause 500 on route:cache
  10. Output MUST be a single file at the specified OUTPUT_FILE path

  ---
