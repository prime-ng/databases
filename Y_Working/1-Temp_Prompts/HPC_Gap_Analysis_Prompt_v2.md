# PROMPT: Complete HPC Module Gap Analysis (Enhanced with Source PDFs)

  ## Mode
  Switch to **Business Analyst** mode. Perform a comprehensive gap analysis of the HPC
  (Holistic Progress Card) module.

  ---

  ## CONFIGURATION
  ```
  MODULE         = HPC
  MODULE_DIR     = Hpc
  LARAVEL_ROOT   = /Users/bkwork/Herd/prime_ai_shailesh
  MODULE_PATH    = /Users/bkwork/Herd/prime_ai_shailesh/Modules/Hpc
  DB_REPO        = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
  AI_BRAIN       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain
  OUTPUT_FILE    = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/2-Gap_Analysis/HPC_Gap_Analysis_Complete.md
  BRANCH         = Brijesh_HPC
  DEVELOPER      = Shailesh
  DATE           = 2026-03-16
  ```

  ---

  ## PRIMARY SOURCE DOCUMENTS (Official NEP 2020 HPC Forms)

  ### Actual Report Card PDFs (the physical forms that must be digitized)
  These are the GOVERNMENT-ISSUED HPC report card forms. Every page, field, table,
  emoji, checkbox, and section in these PDFs must be captured by the digital system.
  These are the GROUND TRUTH — the app must reproduce these exactly.

  | Template | File | Pages | Grades |
  |----------|------|-------|--------|
  | T1 — Foundation |
  `{DB_REPO}/7-Support_Docs_for_Modules/HPC/HPC_Report_Cards/11-HPC-Found_Form.pdf` |
  18 | Pre-primary (Nursery/LKG/UKG, BV1-3) |
  | T2 — Preparatory |
  `{DB_REPO}/7-Support_Docs_for_Modules/HPC/HPC_Report_Cards/12-HPC-Prep_Form.pdf` | 30
   | Grades 1-5 |
  | T3 — Middle |
  `{DB_REPO}/7-Support_Docs_for_Modules/HPC/HPC_Report_Cards/13-HPC-Middle_Form.pdf` |
  46 | Grades 6-8 |
  | T4 — Secondary |
  `{DB_REPO}/7-Support_Docs_for_Modules/HPC/HPC_Report_Cards/14-HPC-Second_Form.pdf` |
  44 | Grades 9-12 |

  **Total: 138 pages of actual report card forms**

  ### How-to-Fill Instruction Manuals
  These explain WHAT each field means, WHO should fill it, WHEN it should be filled,
  and WHAT valid values are allowed. This is the AUTHORITATIVE REFERENCE for:
  - Field-level validation rules
  - Data provider per section (Teacher / Student / Parent / Peer / System)
  - NEP 2020 competency mapping
  - Descriptor levels and their meanings
  - Assessment methodology per page

  | Template | File | Pages |
  |----------|------|-------|
  | T1 Instructions | `{DB_REPO}/7-Support_Docs_for_Modules/HPC/How_to_fill_Report_Card
  s/1-HPC-Foundational_HowToFill.pdf` | 76 |
  | T2 Instructions | `{DB_REPO}/7-Support_Docs_for_Modules/HPC/How_to_fill_Report_Card
  s/2-HPC-Preparatory_HowToFill.pdf` | 82 |
  | T3 Instructions | `{DB_REPO}/7-Support_Docs_for_Modules/HPC/How_to_fill_Report_Card
  s/3-HPC-Middle_HowToFill.pdf` | 98 |
  | T4 Instructions | `{DB_REPO}/7-Support_Docs_for_Modules/HPC/How_to_fill_Report_Card
  s/4-HPC-Secondary_HowToFill.pdf` | 130 |

  **Total: 386 pages of instruction manuals**

  ### How to Read These PDFs
  - Use the Read tool with `pages` parameter (max 20 pages per request)
  - Read each Report Card PDF fully (they are the shorter ones: 18-46 pages each)
  - Read the How-to-Fill PDFs in strategic chunks — focus on:
    - Table of Contents / Index pages (first 2-3 pages) — to understand structure
    - Section headers and field lists — to identify every data point
    - "Who fills this" annotations — to map data providers
    - Pages that correspond to sections marked PARTIAL or NOT STARTED in the code

  ### Template ID ↔ PDF ↔ Blade Mapping
  | Template ID | Report Card PDF | Blade Template | How-to-Fill PDF |
  |-------------|----------------|----------------|-----------------|
  | 1 | 11-HPC-Found_Form.pdf (18 pg) | first_pdf.blade.php (1170 lines) |
  1-HPC-Foundational_HowToFill.pdf (76 pg) |
  | 2 | 12-HPC-Prep_Form.pdf (30 pg) | second_pdf.blade.php (2935 lines) |
  2-HPC-Preparatory_HowToFill.pdf (82 pg) |
  | 3 | 13-HPC-Middle_Form.pdf (46 pg) | third_pdf.blade.php (2260 lines) |
  3-HPC-Middle_HowToFill.pdf (98 pg) |
  | 4 | 14-HPC-Second_Form.pdf (44 pg) | fourth_pdf.blade.php (5865 lines) |
  4-HPC-Secondary_HowToFill.pdf (130 pg) |

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

  ### Tier 2: Official Source PDFs (read second — THIS IS THE GROUND TRUTH)
  7. **T1 Report Card:** `11-HPC-Found_Form.pdf` — Read pages 1-18 (full). Note every
  page title, section, field, table, emoji, checkbox
  8. **T2 Report Card:** `12-HPC-Prep_Form.pdf` — Read pages 1-20, then 21-30. Note
  every field and section
  9. **T3 Report Card:** `13-HPC-Middle_Form.pdf` — Read pages 1-20, 21-40, 41-46. Note
   repeating patterns (Activity Tab, Self-Reflection, Peer Feedback, Teacher Feedback
  cycles)
  10. **T4 Report Card:** `14-HPC-Second_Form.pdf` — Read pages 1-20, 21-40, 41-44.
  Note project work, credit framework, MOOC sections
  11. **T1 Instructions:** `1-HPC-Foundational_HowToFill.pdf` — Read pages 1-5 (TOC +
  overview), then sample 10-15 pages that cover parent sections and teacher observation
   sections
  12. **T2 Instructions:** `2-HPC-Preparatory_HowToFill.pdf` — Read pages 1-5 (TOC),
  then pages covering parent feedback (Q1-Q10), home resources
  13. **T3 Instructions:** `3-HPC-Middle_HowToFill.pdf` — Read pages 1-5 (TOC), then
  pages covering peer assessment and self-reflection sections
  14. **T4 Instructions:** `4-HPC-Secondary_HowToFill.pdf` — Read pages 1-5 (TOC), then
   pages covering student self-evaluation, project work, credit calculation,
  learner/peer assessment

  ### Tier 3: HPC Design & Requirements (read third)
  15. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_requirement.md` — Full HPC
  requirement (large file, read in chunks)
  16. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_ImplementationBlueprint.md` —
  9-section blueprint: phases, screens, APIs, data flow
  17. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_screen_requirement.md` —
  Screen-by-screen specs
  18. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/hpc_enhancement.md` — Schema
  analysis & recommendations
  19. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Design/screen_design.md` — UI design specs
  20. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/DDL/Template_HPC_ddl_v2.sql` — Canonical
  DDL schema
  21. `{DB_REPO}/Y_Working/4-Module_wise_Design/14-HPC/Info.md` — NEP 2020 domain
  knowledge (abilities, descriptors, competencies)
  22. `{DB_REPO}/Y_Working/4-Module_wise_Design/14-HPC/Assignment_Type.md` — Assessment
   tier architecture

  ### Tier 4: Previous Analysis (read fourth — avoid repeating work)
  23.
  `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Claude_Prompt/2026Mar14_HPC_Gap_Analysis.md` —
   Previous gap analysis (GAP-1 to GAP-8)
  24. `{DB_REPO}/2-DDL_Tenant_Modules/14-HPC/Claude_Prompt/2026Mar14_HPC_Data_Collectio
  n_Plan.md` — 5-phase implementation plan

  ### Tier 5: Actual Codebase (read/scan fifth — CODE is SOURCE OF TRUTH for what
  EXISTS)
  25. `{MODULE_PATH}/app/Http/Controllers/` — List ALL controllers, read each public
  method signature
  26. `{MODULE_PATH}/app/Models/` — List ALL models, check $table, $fillable,
  relationships, SoftDeletes
  27. `{MODULE_PATH}/app/Services/` — List ALL services, read method signatures
  28. `{MODULE_PATH}/app/Jobs/` — List ALL jobs
  29. `{MODULE_PATH}/app/Mail/` — List ALL mailables
  30. `{MODULE_PATH}/app/Http/Requests/` — List ALL FormRequests, check authorize()
  return value
  31. `{MODULE_PATH}/resources/views/` — Recursively list ALL blade files, count per
  subfolder
  32. `{MODULE_PATH}/resources/views/hpc_form/pdf/` — Read first 20 lines of each
  *_pdf.blade.php to check $css keys and $hpcData extraction
  33. `{MODULE_PATH}/routes/web.php` and `{MODULE_PATH}/routes/api.php` — Check if
  scaffold routes exist (should be empty)
  34. `{LARAVEL_ROOT}/routes/tenant.php` — Search for ALL HPC routes (prefix 'hpc'),
  extract route list with methods and controller actions
  35. `{LARAVEL_ROOT}/database/migrations/tenant/` — Search for `*hpc*` migration files
  36. `{MODULE_PATH}/tests/` — Check if any tests exist
  37. `{MODULE_PATH}/database/seeders/` — Check if any seeders exist

  ### Tier 6: Cross-Module Dependencies (scan sixth)
  38. `{LARAVEL_ROOT}/Modules/StudentProfile/app/Models/Student.php` — Relationships
  used by HPC
  39. `{LARAVEL_ROOT}/Modules/StudentProfile/app/Models/Guardian.php` — Email field for
   queued email
  40. `{LARAVEL_ROOT}/Modules/SchoolSetup/app/Models/Organization.php` — Used in PDF
  generation
  41. `{LARAVEL_ROOT}/Modules/SmartTimetable/app/Models/AcademicTerm.php` — FK
  dependency

  ---

  ## ANALYSIS DIMENSIONS (8 dimensions)

  ### Dimension 1: Feature Completeness vs Blueprint
  Compare EVERY screen/feature listed in `hpc_ImplementationBlueprint.md` (Section 4:
  Screen Requirements, Section 7: Implementation Phasing) against actual code.

  For each screen/feature produce:
  | Screen/Feature | Blueprint Section | Controller Method | View Exists? | Route
  Registered? | Status | Gap Description |
  |---|---|---|---|---|---|---|
  | SC-01: Template Builder | Phase 1 | HpcTemplatesController::* | Yes/No | Yes/No |
  DONE / PARTIAL / NOT STARTED | What's missing |

  ### Dimension 2: Page-by-Page PDF Fidelity Check (NEW — Primary Dimension)
  **This is the most important dimension.** For each of the 4 templates, compare EVERY
  PAGE
  of the official Report Card PDF against the corresponding generated Blade PDF
  template.

  #### Process:
  1. Read the Report Card PDF page by page
  2. For each page, identify: page title/header, all fields, tables, emojis,
  checkboxes, text areas
  3. Check if that page exists in the Blade template (search by page_no in @if blocks)
  4. Check if every field on that page has a corresponding `html_object_name` in the
  template
  5. Check if the layout matches (tables, columns, sections)

  #### Output per template:
  ```
  ### Template N: [Name] — Page Fidelity Report

  | PDF Page | Page Title/Section | In Blade? | Fields in PDF | Fields in Blade |
  Missing Fields | Layout Match? | Data Provider |
  |----------|-------------------|-----------|---------------|-----------------|-------
  ---------|---------------|---------------|
  | 1 | Student Info + Attendance | Yes | 15 | 15 | None | Yes | System (auto) |
  | 2 | Self-Evaluation | Yes | 8 | 5 | goal_setting, time_mgmt, future_plan | Partial
  | Student |
  | ... | ... | ... | ... | ... | ... | ... | ... |
  ```

  **Data Provider Column:** Based on the How-to-Fill manual, identify who should fill
  each page:
  - **SYSTEM** — Auto-populated (student master data, attendance, org info)
  - **TEACHER** — Class teacher / subject teacher enters
  - **STUDENT** — Student self-reflection, goals, project planning
  - **PARENT** — Home observations, parent feedback, parent questionnaire
  - **PEER** — Peer assessment, peer feedback
  - **MIXED** — Multiple providers for different sections on same page

  #### Summary per template:
  | Metric | T1 (18pg) | T2 (30pg) | T3 (46pg) | T4 (44pg) | Total |
  |--------|-----------|-----------|-----------|-----------|-------|
  | Pages in PDF | 18 | 30 | 46 | 44 | 138 |
  | Pages in Blade | ? | ? | ? | ? | ? |
  | Pages fully matching | ? | ? | ? | ? | ? |
  | Pages partially matching | ? | ? | ? | ? | ? |
  | Pages missing from Blade | ? | ? | ? | ? | ? |
  | Fields in PDF | ? | ? | ? | ? | ? |
  | Fields in Blade | ? | ? | ? | ? | ? |
  | Fields missing | ? | ? | ? | ? | ? |
  | Field coverage % | ? | ? | ? | ? | ? |

  ### Dimension 3: Data Provider Analysis (NEW — from How-to-Fill Manuals)
  Using the How-to-Fill instruction manuals, build a complete map of WHO should provide
   
  each section's data. This is critical for planning multi-actor data collection.

  | Template | Page(s) | Section | Intended Provider | Current Provider | Input
  Mechanism Exists? | Gap |
  |----------|---------|---------|-------------------|------------------|--------------
  ----------|-----|
  | T1 | 5-6 | Parent Observation | PARENT | Teacher (proxy) | No | Need parent
  form/link |
  | T4 | 2-12 | Self-Evaluation + Goals | STUDENT | Teacher (proxy) | No | Need student
   portal |
  | T3 | 8,12,16.. | Peer Feedback | PEER | Teacher (proxy) | No | Need peer workflow |

  **Aggregate Summary:**
  | Provider | Total Sections Across All Templates | Currently Has Input Mechanism? |
  Sections Actually Fillable By Intended Provider |
  |----------|-------------------------------------|-------------------------------|---
  --------------------------------------------|
  | SYSTEM | ? | Yes (auto-populate) | ?/? |
  | TEACHER | ? | Yes (HPC form) | ?/? |
  | STUDENT | ? | No | 0/? |
  | PARENT | ? | No | 0/? |
  | PEER | ? | No | 0/? |

  ### Dimension 4: Schema vs Code Alignment
  Compare `Template_HPC_ddl_v2.sql` tables against:
  - Models: Does every table have a model? Is $table correct? Is $fillable complete?
  - Migrations: Does every table have a migration in `database/migrations/tenant/`?
  - Relationships: Are all FKs reflected as Eloquent relationships?

  Produce:
  | DDL Table | Model Exists? | Model Name | $fillable Complete? | Migration Exists? |
  Relationships OK? | Issues |
  |---|---|---|---|---|---|---|

  ### Dimension 5: Security & Authorization Audit
  For EVERY public method in EVERY HPC controller:
  | Controller | Method | Has Gate::authorize? | FormRequest Used? | FR authorize()
  Logic | $request->validated() Used? | Issues |
  |---|---|---|---|---|---|---|

  Also check:
  - EnsureTenantHasModule middleware on route group
  - Cross-layer model imports (Prime/Global models in tenant context)
  - $fillable contains `is_super_admin` or `remember_token`?
  - Any `dd()`, `dump()`, hardcoded API keys?

  ### Dimension 6: Route Health Check
  For EVERY registered HPC route in tenant.php:
  | HTTP Method | URI | Controller@Method | Method Exists? | Import Exists? | Trash
  Before Resource? | Issues |
  |---|---|---|---|---|---|---|

  Flag: dead routes (method doesn't exist), missing imports (will 500), shadowed routes
   (trash after resource)

  ### Dimension 7: Data Flow & Integration Gaps
  Using the Data Capture Matrix from `hpc_ImplementationBlueprint.md` (Section 3) AND
  the How-to-Fill manuals:
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
  - Credit framework calculation (T4 secondary — NCrF)
  - MOOC/Online course tracking (T4 secondary)

  ### Dimension 8: Multi-Actor Data Collection Status
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
  **Source PDFs:** 4 Report Cards (138 pages) + 4 How-to-Fill Manuals (386 pages)

  ---

  ## Executive Summary
  - Total pages across all 4 report card PDFs: 138
  - Pages with full Blade coverage: N (X%)
  - Pages with partial Blade coverage: N (X%)
  - Pages missing from Blade: N (X%)
  - Total fields across all PDFs: N
  - Fields captured in digital form: N (X%)
  - Fields missing from digital form: N (X%)
  - Sections requiring STUDENT input: N (0% have student portal)
  - Sections requiring PARENT input: N (0% have parent mechanism)
  - Sections requiring PEER input: N (0% have peer workflow)
  - Blueprint screens fully implemented: N/N (X%)
  - Critical security issues: N
  - Critical bugs: N
  - Overall module completion: X%

  ## 1. Page-by-Page PDF Fidelity Check
  ### Template 1: Foundation (18 pages)
  [Page table]
  ### Template 2: Preparatory (30 pages)
  [Page table]
  ### Template 3: Middle (46 pages)
  [Page table]
  ### Template 4: Secondary (44 pages)
  [Page table]
  ### Fidelity Summary
  [Summary metrics table]

  ## 2. Data Provider Analysis
  ### Per-Template Provider Map
  [Provider tables per template]
  ### Aggregate Provider Summary
  [Cross-template summary]
  ### Teacher Workload Impact
  [Time estimate: how many minutes per student per template if teacher fills everything
   vs multi-actor]

  ## 3. Feature Completeness vs Blueprint
  [Dimension 1 table]

  ## 4. Schema vs Code Alignment
  [Dimension 4 table]

  ## 5. Security & Authorization Audit
  [Dimension 5 table]
  ### Summary: X/Y methods have Gate::authorize
  ### Summary: X/Y FormRequests have real authorize() logic

  ## 6. Route Health Check
  [Dimension 6 table]
  ### Dead Routes: [list]
  ### Missing Imports: [list]
  ### Shadowed Routes: [list]

  ## 7. Data Flow & Integration Gaps
  [Dimension 7 table]

  ## 8. Multi-Actor Data Collection Status
  [Dimension 8 table — GAP-1 through GAP-8 validation]

  ## 9. Known Issues Status (from AI Brain)
  | Issue ID | Severity | Description | Status | Notes |
  |---|---|---|---|---|
  | SEC-HPC-001 | CRITICAL | ... | OPEN / PARTIAL / RESOLVED | ... |
  [All SEC-HPC-*, BUG-HPC-*, PERF-HPC-* entries]

  ## 10. Priority Action Items
  ### P0 — Critical (fix before any new feature)
  1. ...
  ### P1 — High (fix this sprint)
  1. ...
  ### P2 — Medium (fix next sprint)
  1. ...
  ### P3 — Low (backlog)
  1. ...

  ## 11. Effort Estimation
  | Category | Item Count | Estimated Effort |
  |---|---|---|
  | Security fixes | N methods | Xh |
  | Bug fixes | N bugs | Xh |
  | Missing PDF pages/fields | N pages, N fields | X days |
  | Missing features (blueprint screens) | N screens | X days |
  | Integration (auto-feed from other modules) | N data flows | X days |
  | Student self-service portal | 1 portal | X days |
  | Parent data collection (signed links) | 1 mechanism | X days |
  | Peer assessment workflow | 1 workflow | X days |
  | Approval workflow (Draft→Final→Published) | 1 workflow | X days |
  | Credit framework calculation (T4) | 1 service | X days |
  | Tests | 0 → target coverage | X days |
  | **Total** | | **X developer-weeks** |

  ## 12. Appendix: Field Inventory per Template
  ### Template 1 Fields (from PDF)
  [Complete list of every field, grouped by page]
  ### Template 2 Fields (from PDF)
  [Complete list]
  ### Template 3 Fields (from PDF)
  [Complete list]
  ### Template 4 Fields (from PDF)
  [Complete list]
  ```

  ---

  ## RULES

  1. **Report Card PDFs are the GROUND TRUTH** — if a field exists in the PDF but not
  in the Blade template, that is a gap. The app must reproduce the official form.
  2. **How-to-Fill PDFs are the AUTHORITY** for who fills what — if the manual says
  "Student fills this section", that defines the data provider, regardless of what the
  code currently does.
  3. **Code is the source of truth for what EXISTS** — if AI Brain says "done" but code
   shows stub/missing, mark as NOT DONE
  4. **Read actual files** — do not guess. Open controllers, read method bodies, check
  for Gate::authorize as first line
  5. **Every claim must have evidence** — file path + line number or "file not found"
  or "PDF page N"
  6. **Do NOT fix anything** — this is analysis only, no code changes
  7. **Do NOT skip any controller/model/route/PDF page** — exhaustive audit
  8. **Cross-reference** previous gap analysis but VERIFY against current code — things
   may have changed since 2026-03-14
  9. **Count everything** — total pages, total fields, total methods, total with auth,
  percentages
  10. **Flag cross-layer imports** — any `Modules\Prime\*` or `App\Models\*` used in
  tenant context
  11. **Check tenant.php import section** — missing `use` statements cause 500 on
  route:cache
  12. **Read PDFs strategically** — Report Cards fully (they're shorter), How-to-Fill
  in targeted chunks (TOC + relevant sections)
  13. **Output MUST be a single file** at the specified OUTPUT_FILE path
  ```

  ---
  What Changed vs Previous Prompt

  ┌─────────────────┬─────────────────────┬────────────────────────────────────────┐
  │      Area       │      Previous       │                Enhanced                │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Source          │ Design docs + code  │ + 4 Report Card PDFs (138 pages) + 4   │
  │ documents       │ only                │ How-to-Fill manuals (386 pages)        │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Dimensions      │ 6                   │ 8 (+Page Fidelity, +Data Provider      │
  │                 │                     │ Analysis)                              │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Ground truth    │ Code + blueprint    │ Official NEP PDFs are now the ground   │
  │                 │                     │ truth for what the app must reproduce  │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Field-level     │ Not covered         │ Every field on every PDF page checked  │
  │ audit           │                     │ against Blade templates                │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Data provider   │ Basic (from         │ Authoritative mapping from How-to-Fill │
  │ mapping         │ previous gap        │  manuals                               │
  │                 │ analysis)           │                                        │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Output sections │ 9                   │ 12 (+Field Inventory appendix,         │
  │                 │                     │ +Teacher Workload Impact)              │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Pre-read items  │ 28                  │ 41 (8 PDFs + extra Blade reads added)  │
  ├─────────────────┼─────────────────────┼────────────────────────────────────────┤
  │ Template        │ Implicit            │ Explicit table: Template ID ↔ PDF ↔    │
  │ mapping         │                     │ Blade ↔ Instructions                   │
  └─────────────────┴─────────────────────┴────────────────────────────────────────┘

✻ Brewed for 2m 39s