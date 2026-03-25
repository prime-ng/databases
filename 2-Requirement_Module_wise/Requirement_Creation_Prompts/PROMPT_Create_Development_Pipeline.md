# Master Prompt: Create Prime-AI Development Pipeline System

> **How to use:** Copy everything below the horizontal line and paste it into Claude Agent in VS Code as a single prompt. Claude Agent will create the entire pipeline system in your workspace.

---

## INSTRUCTION TO CLAUDE AGENT

I need you to create a **complete Automated Development Pipeline System** inside my VS Code workspace. This system will automate the entire software development lifecycle for my Prime-AI platform — from Requirements Specification through Coding, Testing, Bug Fixing, and Deployment.

The system works like this: I feed it my RBS (Requirements Breakdown Structure) and tell it which module to develop. It then executes 33 steps across 7 phases automatically, where each step's output becomes the next step's input.

**Read this entire prompt carefully before creating anything. Understand the full structure first, then create everything in the correct order.**

---

## PART 1: FOLDER STRUCTURE

Create the following folder structure at the root of my workspace under a directory called `dev-pipeline/`:

```
dev-pipeline/
│
├── config/
│   ├── pipeline.config.yaml          # All configurable parameters
│   ├── module-registry.yaml          # Registry of all modules with metadata
│   └── tech-stack.yaml               # Technology stack constants referenced by prompts
│
├── pipeline.yaml                     # Master pipeline definition (all 33 steps, dependencies, I/O)
├── orchestrator.py                   # Main orchestrator script
├── validator.py                      # Output validation functions per step
├── utils.py                          # Shared utilities (file I/O, logging, template rendering)
├── state/                            # Pipeline execution state (auto-generated, gitignored)
│   └── .gitkeep
│
├── phases/
│   │
│   ├── phase-1_requirements-architecture/
│   │   ├── README.md                 # Phase overview, when to run, expected duration
│   │   ├── step-1.1_srs/
│   │   │   ├── prompt.md             # The prompt template with {{placeholders}}
│   │   │   ├── context.md            # Additional context/examples to include
│   │   │   ├── validation-rules.yaml # What makes this step's output valid
│   │   │   └── output/               # Where generated output is saved (gitignored)
│   │   │       └── .gitkeep
│   │   ├── step-1.2_dependency-map/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-1.3_data-dictionary/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-1.4_system-architecture/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   └── step-1.5_coding-standards/
│   │       ├── prompt.md
│   │       ├── context.md
│   │       ├── validation-rules.yaml
│   │       └── output/
│   │           └── .gitkeep
│   │
│   ├── phase-2_module-design/
│   │   ├── README.md
│   │   ├── step-2.1_erd/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-2.2_api-specification/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   └── step-2.3_ui-ux-wireframes/
│   │       ├── prompt.md
│   │       ├── context.md
│   │       ├── validation-rules.yaml
│   │       └── output/
│   │           └── .gitkeep
│   │
│   ├── phase-3_backend-development/
│   │   ├── README.md
│   │   ├── step-3.1_migrations/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-3.2_models/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-3.3_form-requests/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-3.4_services/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-3.5_controllers-routes/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-3.6_events-listeners/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   └── step-3.7_jobs-scheduling/
│   │       ├── prompt.md
│   │       ├── context.md
│   │       ├── validation-rules.yaml
│   │       └── output/
│   │           └── .gitkeep
│   │
│   ├── phase-4_frontend-development/
│   │   ├── README.md
│   │   ├── step-4.1_blade-templates/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-4.2_livewire-components/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-4.3_alpine-js/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   └── step-4.4_dashboard-widgets/
│   │       ├── prompt.md
│   │       ├── context.md
│   │       ├── validation-rules.yaml
│   │       └── output/
│   │           └── .gitkeep
│   │
│   ├── phase-5_testing-qa/
│   │   ├── README.md
│   │   ├── step-5.1_unit-tests/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-5.2_feature-tests/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-5.3_browser-tests/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-5.4_bug-fixing/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   └── step-5.5_code-review/
│   │       ├── prompt.md
│   │       ├── context.md
│   │       ├── validation-rules.yaml
│   │       └── output/
│   │           └── .gitkeep
│   │
│   ├── phase-6_documentation/
│   │   ├── README.md
│   │   ├── step-6.1_api-docs/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   ├── step-6.2_technical-docs/
│   │   │   ├── prompt.md
│   │   │   ├── context.md
│   │   │   ├── validation-rules.yaml
│   │   │   └── output/
│   │   │       └── .gitkeep
│   │   └── step-6.3_user-manual/
│   │       ├── prompt.md
│   │       ├── context.md
│   │       ├── validation-rules.yaml
│   │       └── output/
│   │           └── .gitkeep
│   │
│   └── phase-7_integration-deployment/
│       ├── README.md
│       ├── step-7.1_integration-tests/
│       │   ├── prompt.md
│       │   ├── context.md
│       │   ├── validation-rules.yaml
│       │   └── output/
│       │       └── .gitkeep
│       ├── step-7.2_performance-tests/
│       │   ├── prompt.md
│       │   ├── context.md
│       │   ├── validation-rules.yaml
│       │   └── output/
│       │       └── .gitkeep
│       ├── step-7.3_security-audit/
│       │   ├── prompt.md
│       │   ├── context.md
│       │   ├── validation-rules.yaml
│       │   └── output/
│       │       └── .gitkeep
│       ├── step-7.4_devops-cicd/
│       │   ├── prompt.md
│       │   ├── context.md
│       │   ├── validation-rules.yaml
│       │   └── output/
│       │       └── .gitkeep
│       ├── step-7.5_deployment-plan/
│       │   ├── prompt.md
│       │   ├── context.md
│       │   ├── validation-rules.yaml
│       │   └── output/
│       │       └── .gitkeep
│       ├── step-7.6_monitoring/
│       │   ├── prompt.md
│       │   ├── context.md
│       │   ├── validation-rules.yaml
│       │   └── output/
│       │       └── .gitkeep
│       └── step-7.7_platform-docs/
│           ├── prompt.md
│           ├── context.md
│           ├── validation-rules.yaml
│           └── output/
│               └── .gitkeep
│
└── templates/
    ├── prompt-header.md              # Common header included in every prompt
    └── coding-standards-snippet.md   # Coding standards summary included in code-gen prompts
```

---

## PART 2: CONFIGURATION FILE

Create `dev-pipeline/config/pipeline.config.yaml` with the following content. This is the **single source of truth** for all paths and parameters. Every prompt template and the orchestrator reads from this file.

```yaml
# ============================================================================
# PRIME-AI DEVELOPMENT PIPELINE — MASTER CONFIGURATION
# ============================================================================
# This file is the single source of truth for all pipeline parameters.
# All prompt templates reference these values via {{config.*}} placeholders.
# Update paths here when your project structure changes.
# ============================================================================

# --- PROJECT IDENTITY ---
project:
  name: "Prime-AI"
  description: "Multi-tenant SaaS Academic Intelligence Platform for Indian K-12 Schools"
  version: "1.0.0"
  organization: "PrimeGurukul"

# --- CURRENT MODULE BEING DEVELOPED ---
# Change these values when switching to a new module
module:
  name: ""                                          # e.g., "Student Management"
  slug: ""                                          # e.g., "student-management"
  code: ""                                          # e.g., "STU"
  table_prefix: ""                                  # e.g., "stu_"
  description: ""                                   # Brief description of the module
  priority: ""                                      # P0, P1, P2, etc.
  depends_on: []                                    # List of module slugs this depends on

# --- APPLICATION PATHS (relative to workspace root) ---
paths:
  # Application source code
  application_root: ""                              # e.g., "prime-ai/" or "./"
  
  # Backend paths
  models_dir: "app/Models"
  controllers_dir: "app/Http/Controllers/Api/V1"
  services_dir: "app/Services"
  form_requests_dir: "app/Http/Requests"
  resources_dir: "app/Http/Resources"
  policies_dir: "app/Policies"
  events_dir: "app/Events"
  listeners_dir: "app/Listeners"
  notifications_dir: "app/Notifications"
  jobs_dir: "app/Jobs"
  middleware_dir: "app/Http/Middleware"
  traits_dir: "app/Traits"
  enums_dir: "app/Enums"
  
  # Database paths
  migrations_dir: "database/migrations"
  seeders_dir: "database/seeders"
  factories_dir: "database/factories"
  
  # Frontend paths
  views_dir: "resources/views"
  livewire_views_dir: "resources/views/livewire"
  livewire_components_dir: "app/Http/Livewire"
  js_dir: "resources/js"
  css_dir: "resources/css"
  
  # Route paths
  routes_dir: "routes"
  api_routes_file: "routes/api.php"
  web_routes_file: "routes/web.php"
  
  # Test paths
  unit_tests_dir: "tests/Unit"
  feature_tests_dir: "tests/Feature"
  browser_tests_dir: "tests/Browser"
  
  # Config and misc
  config_dir: "config"
  lang_dir: "resources/lang"
  
  # Documentation output
  docs_dir: "docs"
  
  # Pipeline internal
  pipeline_root: "dev-pipeline"
  pipeline_output_dir: "dev-pipeline/phases"
  pipeline_state_dir: "dev-pipeline/state"

# --- DATABASE CONFIGURATION ---
database:
  # Multi-tenant architecture
  global_db_name: "prime_ai_global"
  tenant_db_prefix: "prime_ai_tenant_"
  
  # Schema conventions
  tenant_id_column: "tenant_id"
  soft_deletes: true
  audit_columns: true                               # created_by, updated_by
  timestamps: true
  uuid_primary_keys: false                          # true = UUID, false = auto-increment
  
  # Existing schema file (if available)
  schema_dump_path: ""                              # e.g., "database/schema/mysql-schema.sql"
  existing_erd_path: ""                             # e.g., "docs/erd/current-erd.md"

# --- TECHNOLOGY STACK ---
tech_stack:
  php_version: "8.2"
  laravel_version: "11"
  mysql_version: "8.0"
  node_version: "20"
  
  # Frontend
  css_framework: "Tailwind CSS"
  js_framework: "Alpine.js"
  livewire_version: "3"
  
  # Auth & permissions
  auth_package: "Laravel Sanctum"
  rbac_package: "Spatie Laravel Permission"
  
  # Queue & cache
  queue_driver: "redis"
  cache_driver: "redis"
  session_driver: "redis"
  
  # AI/ML
  ai_bridge: "Python microservices via HTTP"

# --- ROLE DEFINITIONS ---
roles:
  - Super Admin
  - Management
  - Principal
  - Vice Principal
  - Academic Head
  - Teacher
  - Class Teacher
  - Accountant
  - Librarian
  - Transport Manager
  - Hostel Warden
  - Receptionist
  - Admin Staff
  - Inventory Manager
  - Parent
  - Student

# --- CODE GENERATION CONVENTIONS ---
conventions:
  # Naming
  model_suffix: ""                                   # e.g., "" means "Student", not "StudentModel"
  controller_suffix: "Controller"
  service_suffix: "Service"
  request_suffix: "Request"
  resource_suffix: "Resource"
  event_prefix: ""                                   # e.g., "StudentEnrolled"
  policy_suffix: "Policy"
  
  # API
  api_version: "v1"
  api_prefix: "api/v1"
  api_response_envelope: true                        # Wrap responses in {success, data, message}
  pagination_default: 25
  pagination_max: 100
  
  # Coding style
  strict_types: true
  final_classes: false
  return_types: true
  phpdoc_blocks: true

# --- INPUT FILES (your existing documents) ---
inputs:
  rbs_file: ""                                       # Path to your RBS Excel/PDF
  existing_srs: ""                                   # If you already have a partial SRS
  existing_coding_standards: ""                       # If you already have coding standards
  ai_brain_path: ""                                  # Path to your AI_Brain directory
  
# --- EXECUTION SETTINGS ---
execution:
  auto_validate: true                                # Run validation after each step
  auto_advance: false                                # Auto-proceed to next step on success
  save_intermediate: true                            # Save intermediate outputs
  log_level: "INFO"                                  # DEBUG, INFO, WARN, ERROR
  max_retries: 2                                     # Retry failed steps
  pause_between_steps: true                          # Wait for confirmation between steps
  
  # Code deployment
  auto_copy_to_app: false                            # Auto-copy generated code to application paths
  create_git_branch: true                            # Create a git branch per module
  git_branch_prefix: "module/"                       # e.g., "module/student-management"
```

---

## PART 3: MODULE REGISTRY

Create `dev-pipeline/config/module-registry.yaml`:

```yaml
# ============================================================================
# MODULE REGISTRY — All Prime-AI Modules
# ============================================================================
# This registry defines every module, its dependencies, and metadata.
# The orchestrator uses this to validate module selection and resolve build order.
# ============================================================================

modules:

  # --- P0: FOUNDATION ---
  tenant-core:
    name: "Tenant & Multi-tenancy Core"
    code: "TEN"
    priority: "P0"
    table_prefix: "ten_"
    depends_on: []
    description: "Multi-tenant infrastructure — tenant provisioning, DB switching, isolation middleware"
    
  auth-rbac:
    name: "Authentication & RBAC"
    code: "AUTH"
    priority: "P0"
    table_prefix: "auth_"
    depends_on: ["tenant-core"]
    description: "Authentication, role-based access control, permissions, Spatie integration"
    
  academic-session:
    name: "Academic Session & Configuration"
    code: "ACAD"
    priority: "P0"
    table_prefix: "acad_"
    depends_on: ["tenant-core", "auth-rbac"]
    description: "Academic years, terms, class-section structure, subjects, boards (CBSE/ICSE)"

  # --- P1: CORE ERP ---
  staff-management:
    name: "Staff Management"
    code: "STF"
    priority: "P1"
    table_prefix: "stf_"
    depends_on: ["tenant-core", "auth-rbac", "academic-session"]
    description: "Staff profiles, designations, departments, qualifications, documents"
    
  student-management:
    name: "Student Management"
    code: "STU"
    priority: "P1"
    table_prefix: "stu_"
    depends_on: ["tenant-core", "auth-rbac", "academic-session"]
    description: "Student enrollment, profiles, class assignment, promotion, TC, alumni"

  # --- P2: DAILY OPERATIONS ---
  attendance:
    name: "Attendance Management"
    code: "ATT"
    priority: "P2"
    table_prefix: "att_"
    depends_on: ["student-management", "staff-management", "academic-session"]
    description: "Student & staff attendance, biometric integration, leave management"
    
  timetable:
    name: "Timetable Management"
    code: "TT"
    priority: "P2"
    table_prefix: "tt_"
    depends_on: ["staff-management", "academic-session"]
    description: "Auto-scheduling, constraint satisfaction, substitution, resource allocation"
    
  communication:
    name: "Communication Module"
    code: "COM"
    priority: "P2"
    table_prefix: "com_"
    depends_on: ["student-management", "staff-management"]
    description: "Notices, circulars, SMS, email, in-app messaging, push notifications"

  # --- P3: FINANCE ---
  fees:
    name: "Fee Management"
    code: "FEE"
    priority: "P3"
    table_prefix: "fee_"
    depends_on: ["student-management", "academic-session"]
    description: "Fee structures, collection, receipts, dues, concessions, payment gateway"
    
  payroll:
    name: "Payroll Management"
    code: "PAY"
    priority: "P3"
    table_prefix: "pay_"
    depends_on: ["staff-management"]
    description: "Salary structures, payslips, deductions, tax computation"
    
  accounting:
    name: "Accounting & Finance"
    code: "ACC"
    priority: "P3"
    table_prefix: "acc_"
    depends_on: ["fees", "payroll"]
    description: "Chart of accounts, ledgers, journal entries, financial reports"
    
  inventory:
    name: "Inventory Management"
    code: "INV"
    priority: "P3"
    table_prefix: "inv_"
    depends_on: ["tenant-core", "auth-rbac"]
    description: "Stock management, purchase orders, vendors, asset tracking"

  # --- P4: SERVICES ---
  transport:
    name: "Transport Management"
    code: "TRN"
    priority: "P4"
    table_prefix: "trn_"
    depends_on: ["student-management", "staff-management"]
    description: "Routes, stops, vehicle tracking, fee mapping, GPS integration"
    
  hostel:
    name: "Hostel Management"
    code: "HST"
    priority: "P4"
    table_prefix: "hst_"
    depends_on: ["student-management", "fees"]
    description: "Rooms, bed allocation, mess management, hostel fees"
    
  library:
    name: "Library Management"
    code: "LIB"
    priority: "P4"
    table_prefix: "lib_"
    depends_on: ["student-management", "staff-management"]
    description: "Book catalog, issue/return, fine management, digital library"
    
  visitor-reception:
    name: "Visitor & Reception"
    code: "VIS"
    priority: "P4"
    table_prefix: "vis_"
    depends_on: ["tenant-core", "auth-rbac"]
    description: "Visitor registration, gate pass, appointment booking"

  # --- P5: LMS ---
  question-bank:
    name: "Question Bank"
    code: "QB"
    priority: "P5"
    table_prefix: "qb_"
    depends_on: ["academic-session", "staff-management"]
    description: "Questions with Bloom's taxonomy, difficulty levels, subject/topic mapping"
    
  homework:
    name: "Homework Management"
    code: "HW"
    priority: "P5"
    table_prefix: "hw_"
    depends_on: ["student-management", "academic-session", "question-bank"]
    description: "Assignment creation, submission, grading, plagiarism check"
    
  online-exam:
    name: "Online Examination"
    code: "EXAM"
    priority: "P5"
    table_prefix: "exam_"
    depends_on: ["student-management", "question-bank", "academic-session"]
    description: "Exam scheduling, auto-paper generation, proctoring, result processing"
    
  syllabus:
    name: "Syllabus & Curriculum"
    code: "SYL"
    priority: "P5"
    table_prefix: "syl_"
    depends_on: ["academic-session"]
    description: "Syllabus planning, SCORM content, NEP 2020 alignment, lesson plans"

  # --- P6: LXP ---
  learning-paths:
    name: "Personalized Learning Paths"
    code: "LP"
    priority: "P6"
    table_prefix: "lp_"
    depends_on: ["student-management", "online-exam", "homework", "syllabus"]
    description: "AI-recommended learning sequences, adaptive content, skill mapping"
    
  holistic-progress-card:
    name: "Holistic Progress Card (HPC)"
    code: "HPC"
    priority: "P6"
    table_prefix: "hpc_"
    depends_on: ["student-management", "attendance", "online-exam", "homework"]
    description: "NEP 2020 compliant multi-dimensional progress tracking and reporting"
    
  ai-analytics:
    name: "AI Analytics & Insights"
    code: "AIA"
    priority: "P6"
    table_prefix: "aia_"
    depends_on: ["learning-paths", "holistic-progress-card"]
    description: "Predictive analytics, performance trends, risk identification, recommendations"

  # --- P7: CROSS-CUTTING ---
  reports-dashboards:
    name: "Reports & Dashboards"
    code: "RPT"
    priority: "P7"
    table_prefix: "rpt_"
    depends_on: ["student-management", "staff-management", "fees", "attendance"]
    description: "Cross-module reporting, role-based dashboards, data export"
    
  complaints:
    name: "Complaints & Grievance"
    code: "CMP"
    priority: "P7"
    table_prefix: "cmp_"
    depends_on: ["student-management", "staff-management"]
    description: "Complaint registration, tracking, resolution workflow, escalation"
    
  audit-logs:
    name: "Audit Logs & Activity Tracking"
    code: "AUD"
    priority: "P7"
    table_prefix: "aud_"
    depends_on: ["tenant-core", "auth-rbac"]
    description: "System-wide activity logging, change tracking, compliance audit trail"
```

---

## PART 4: MASTER PIPELINE DEFINITION

Create `dev-pipeline/pipeline.yaml`:

```yaml
# ============================================================================
# MASTER PIPELINE DEFINITION
# ============================================================================
# Defines all 33 steps, their dependencies, inputs, outputs, and validation.
# The orchestrator reads this file to determine execution order.
# ============================================================================

pipeline:
  name: "Prime-AI Development Pipeline"
  version: "1.0.0"
  total_steps: 33

phases:

  # ══════════════════════════════════════════════════════════════
  # PHASE 1: REQUIREMENTS & PLATFORM ARCHITECTURE (One-time)
  # ══════════════════════════════════════════════════════════════
  phase-1:
    name: "Requirements & Platform Architecture"
    scope: "once"                                    # Execute once for entire platform
    steps:
    
      step-1.1:
        name: "Software Requirements Specification"
        dir: "phase-1_requirements-architecture/step-1.1_srs"
        inputs:
          - source: "config"
            key: "inputs.rbs_file"
            description: "Your RBS document"
        outputs:
          - name: "srs.md"
            description: "Complete SRS document"
            deploy_to: "{{config.paths.docs_dir}}/srs/"
        validation:
          - check: "file_exists"
            target: "srs.md"
          - check: "contains_pattern"
            pattern: "FR-"
            description: "Must contain functional requirement IDs"
          - check: "min_length"
            chars: 5000
            
      step-1.2:
        name: "Module Dependency Map"
        dir: "phase-1_requirements-architecture/step-1.2_dependency-map"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
        outputs:
          - name: "dependency-map.md"
            description: "Module dependency graph and build sequence"
            deploy_to: "{{config.paths.docs_dir}}/architecture/"
        validation:
          - check: "file_exists"
            target: "dependency-map.md"
          - check: "contains_pattern"
            pattern: "mermaid"
            description: "Must contain Mermaid diagram"
            
      step-1.3:
        name: "Data Dictionary"
        dir: "phase-1_requirements-architecture/step-1.3_data-dictionary"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
        outputs:
          - name: "data-dictionary.md"
            description: "Domain glossary and entity definitions"
            deploy_to: "{{config.paths.docs_dir}}/architecture/"
        validation:
          - check: "file_exists"
            target: "data-dictionary.md"
            
      step-1.4:
        name: "System Architecture Document"
        dir: "phase-1_requirements-architecture/step-1.4_system-architecture"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
          - source: "step"
            step: "step-1.2"
            file: "dependency-map.md"
          - source: "step"
            step: "step-1.3"
            file: "data-dictionary.md"
        outputs:
          - name: "system-architecture.md"
            description: "Complete system architecture document"
            deploy_to: "{{config.paths.docs_dir}}/architecture/"
        validation:
          - check: "file_exists"
            target: "system-architecture.md"
          - check: "contains_all"
            patterns: ["global_db", "tenant_db", "middleware"]
            
      step-1.5:
        name: "Coding Standards & Project Scaffold"
        dir: "phase-1_requirements-architecture/step-1.5_coding-standards"
        inputs:
          - source: "step"
            step: "step-1.4"
            file: "system-architecture.md"
        outputs:
          - name: "coding-standards.md"
            description: "Coding conventions document"
            deploy_to: "{{config.paths.docs_dir}}/"
          - name: "scaffold/"
            description: "Base classes, traits, middleware"
            deploy_to: "{{config.paths.application_root}}"
        validation:
          - check: "file_exists"
            target: "coding-standards.md"

  # ══════════════════════════════════════════════════════════════
  # PHASE 2: MODULE DESIGN (Per Module)
  # ══════════════════════════════════════════════════════════════
  phase-2:
    name: "Module Design"
    scope: "per-module"
    steps:
    
      step-2.1:
        name: "Entity-Relationship Diagram"
        dir: "phase-2_module-design/step-2.1_erd"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"                 # Extract only current module's section
          - source: "step"
            step: "step-1.3"
            file: "data-dictionary.md"
          - source: "step"
            step: "step-1.4"
            file: "system-architecture.md"
            filter: "db_patterns_section"
        outputs:
          - name: "{{module.slug}}-erd.md"
            description: "ERD with Mermaid diagram and table specifications"
            deploy_to: "{{config.paths.docs_dir}}/modules/{{module.slug}}/"
        validation:
          - check: "file_exists"
            target: "{{module.slug}}-erd.md"
          - check: "contains_pattern"
            pattern: "erDiagram"
          - check: "contains_pattern"
            pattern: "{{module.table_prefix}}"
            
      step-2.2:
        name: "API Specification"
        dir: "phase-2_module-design/step-2.2_api-specification"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
          - source: "step"
            step: "step-2.1"
            file: "{{module.slug}}-erd.md"
          - source: "step"
            step: "step-1.5"
            file: "coding-standards.md"
        outputs:
          - name: "{{module.slug}}-api-spec.yaml"
            description: "OpenAPI 3.0 specification"
            deploy_to: "{{config.paths.docs_dir}}/modules/{{module.slug}}/"
          - name: "{{module.slug}}-api-summary.md"
            description: "Human-readable API summary"
            deploy_to: "{{config.paths.docs_dir}}/modules/{{module.slug}}/"
        validation:
          - check: "file_exists"
            target: "{{module.slug}}-api-spec.yaml"
          - check: "contains_pattern"
            pattern: "openapi:"
            
      step-2.3:
        name: "UI/UX Wireframes & Screen Specs"
        dir: "phase-2_module-design/step-2.3_ui-ux-wireframes"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
          - source: "step"
            step: "step-2.2"
            file: "{{module.slug}}-api-summary.md"
        outputs:
          - name: "{{module.slug}}-ui-specs.md"
            description: "Screen inventory and wireframe specifications"
            deploy_to: "{{config.paths.docs_dir}}/modules/{{module.slug}}/"
        validation:
          - check: "file_exists"
            target: "{{module.slug}}-ui-specs.md"

  # ══════════════════════════════════════════════════════════════
  # PHASE 3: BACKEND DEVELOPMENT (Per Module)
  # ══════════════════════════════════════════════════════════════
  phase-3:
    name: "Backend Development"
    scope: "per-module"
    steps:
    
      step-3.1:
        name: "Database Migrations"
        dir: "phase-3_backend-development/step-3.1_migrations"
        inputs:
          - source: "step"
            step: "step-2.1"
            file: "{{module.slug}}-erd.md"
          - source: "step"
            step: "step-1.5"
            file: "coding-standards.md"
        outputs:
          - name: "migrations/"
            description: "Laravel migration files"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.migrations_dir}}/"
          - name: "seeders/"
            description: "Seeder files"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.seeders_dir}}/"
          - name: "factories/"
            description: "Factory files"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.factories_dir}}/"
        validation:
          - check: "files_in_dir"
            target: "migrations/"
            extension: ".php"
          - check: "php_syntax"
            target: "migrations/"
            
      step-3.2:
        name: "Eloquent Models"
        dir: "phase-3_backend-development/step-3.2_models"
        inputs:
          - source: "step"
            step: "step-2.1"
            file: "{{module.slug}}-erd.md"
          - source: "step"
            step: "step-3.1"
            file: "migrations/"
          - source: "step"
            step: "step-1.5"
            file: "coding-standards.md"
        outputs:
          - name: "models/"
            description: "Eloquent model classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.models_dir}}/"
        validation:
          - check: "files_in_dir"
            target: "models/"
            extension: ".php"
          - check: "php_syntax"
            target: "models/"
          - check: "contains_pattern"
            target_dir: "models/"
            pattern: "tenant_id"
            
      step-3.3:
        name: "Form Requests"
        dir: "phase-3_backend-development/step-3.3_form-requests"
        inputs:
          - source: "step"
            step: "step-2.2"
            file: "{{module.slug}}-api-spec.yaml"
          - source: "step"
            step: "step-3.2"
            file: "models/"
        outputs:
          - name: "requests/"
            description: "FormRequest validation classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.form_requests_dir}}/"
        validation:
          - check: "files_in_dir"
            target: "requests/"
            extension: ".php"
          - check: "php_syntax"
            target: "requests/"
            
      step-3.4:
        name: "Service Classes"
        dir: "phase-3_backend-development/step-3.4_services"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
          - source: "step"
            step: "step-2.2"
            file: "{{module.slug}}-api-spec.yaml"
          - source: "step"
            step: "step-3.2"
            file: "models/"
          - source: "step"
            step: "step-1.5"
            file: "coding-standards.md"
        outputs:
          - name: "services/"
            description: "Business logic service classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.services_dir}}/"
        validation:
          - check: "files_in_dir"
            target: "services/"
            extension: ".php"
          - check: "php_syntax"
            target: "services/"
          - check: "contains_pattern"
            target_dir: "services/"
            pattern: "DB::transaction"
            
      step-3.5:
        name: "Controllers & Routes"
        dir: "phase-3_backend-development/step-3.5_controllers-routes"
        inputs:
          - source: "step"
            step: "step-2.2"
            file: "{{module.slug}}-api-spec.yaml"
          - source: "step"
            step: "step-3.3"
            file: "requests/"
          - source: "step"
            step: "step-3.4"
            file: "services/"
          - source: "step"
            step: "step-1.5"
            file: "coding-standards.md"
        outputs:
          - name: "controllers/"
            description: "API controller classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.controllers_dir}}/"
          - name: "resources/"
            description: "API Resource transformers"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.resources_dir}}/"
          - name: "policies/"
            description: "Authorization policy classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.policies_dir}}/"
          - name: "routes/"
            description: "Route definition files"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.routes_dir}}/api/v1/"
        validation:
          - check: "files_in_dir"
            target: "controllers/"
            extension: ".php"
          - check: "php_syntax"
            target: "controllers/"
            
      step-3.6:
        name: "Events, Listeners & Notifications"
        dir: "phase-3_backend-development/step-3.6_events-listeners"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
          - source: "step"
            step: "step-3.4"
            file: "services/"
        outputs:
          - name: "events/"
            description: "Domain event classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.events_dir}}/"
          - name: "listeners/"
            description: "Event listener classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.listeners_dir}}/"
          - name: "notifications/"
            description: "Notification classes (SMS, email, database)"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.notifications_dir}}/"
        validation:
          - check: "php_syntax"
            target: "events/"
            
      step-3.7:
        name: "Queue Jobs & Scheduling"
        dir: "phase-3_backend-development/step-3.7_jobs-scheduling"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
          - source: "step"
            step: "step-1.4"
            file: "system-architecture.md"
            filter: "queue_section"
        outputs:
          - name: "jobs/"
            description: "Queued job classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.jobs_dir}}/"
          - name: "schedule-config.md"
            description: "Kernel schedule entries for this module"
        validation:
          - check: "php_syntax"
            target: "jobs/"

  # ══════════════════════════════════════════════════════════════
  # PHASE 4: FRONTEND DEVELOPMENT (Per Module)
  # ══════════════════════════════════════════════════════════════
  phase-4:
    name: "Frontend Development"
    scope: "per-module"
    steps:
    
      step-4.1:
        name: "Blade Templates"
        dir: "phase-4_frontend-development/step-4.1_blade-templates"
        inputs:
          - source: "step"
            step: "step-2.3"
            file: "{{module.slug}}-ui-specs.md"
          - source: "step"
            step: "step-1.5"
            file: "coding-standards.md"
        outputs:
          - name: "views/"
            description: "Blade template files"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.views_dir}}/{{module.slug}}/"
        validation:
          - check: "files_in_dir"
            target: "views/"
            extension: ".blade.php"
            
      step-4.2:
        name: "Livewire Components"
        dir: "phase-4_frontend-development/step-4.2_livewire-components"
        inputs:
          - source: "step"
            step: "step-4.1"
            file: "views/"
          - source: "step"
            step: "step-3.5"
            file: "controllers/"
          - source: "step"
            step: "step-3.4"
            file: "services/"
        outputs:
          - name: "livewire-classes/"
            description: "Livewire component PHP classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.livewire_components_dir}}/"
          - name: "livewire-views/"
            description: "Livewire Blade views"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.livewire_views_dir}}/{{module.slug}}/"
        validation:
          - check: "php_syntax"
            target: "livewire-classes/"
            
      step-4.3:
        name: "Alpine.js & JavaScript"
        dir: "phase-4_frontend-development/step-4.3_alpine-js"
        inputs:
          - source: "step"
            step: "step-4.1"
            file: "views/"
          - source: "step"
            step: "step-2.2"
            file: "{{module.slug}}-api-summary.md"
        outputs:
          - name: "js/"
            description: "JavaScript/Alpine.js files"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.js_dir}}/modules/{{module.slug}}/"
        validation:
          - check: "files_in_dir"
            target: "js/"
            extension: ".js"
            
      step-4.4:
        name: "Dashboard Widgets"
        dir: "phase-4_frontend-development/step-4.4_dashboard-widgets"
        inputs:
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "dashboard_section"
          - source: "step"
            step: "step-3.5"
            file: "controllers/"
        outputs:
          - name: "widgets/"
            description: "Dashboard widget Livewire components"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.livewire_components_dir}}/Widgets/"
        validation:
          - check: "php_syntax"
            target: "widgets/"

  # ══════════════════════════════════════════════════════════════
  # PHASE 5: TESTING & QA (Per Module)
  # ══════════════════════════════════════════════════════════════
  phase-5:
    name: "Testing & Quality Assurance"
    scope: "per-module"
    steps:
    
      step-5.1:
        name: "Unit Tests"
        dir: "phase-5_testing-qa/step-5.1_unit-tests"
        inputs:
          - source: "step"
            step: "step-3.4"
            file: "services/"
          - source: "step"
            step: "step-3.2"
            file: "models/"
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
        outputs:
          - name: "unit-tests/"
            description: "PHPUnit unit test classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.unit_tests_dir}}/{{module.code}}/"
        validation:
          - check: "php_syntax"
            target: "unit-tests/"
          - check: "contains_pattern"
            target_dir: "unit-tests/"
            pattern: "function test_"
            
      step-5.2:
        name: "Feature / Integration Tests"
        dir: "phase-5_testing-qa/step-5.2_feature-tests"
        inputs:
          - source: "step"
            step: "step-2.2"
            file: "{{module.slug}}-api-spec.yaml"
          - source: "step"
            step: "step-3.5"
            file: "controllers/"
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
        outputs:
          - name: "feature-tests/"
            description: "PHPUnit feature test classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.feature_tests_dir}}/{{module.code}}/"
        validation:
          - check: "php_syntax"
            target: "feature-tests/"
            
      step-5.3:
        name: "Browser / E2E Tests"
        dir: "phase-5_testing-qa/step-5.3_browser-tests"
        inputs:
          - source: "step"
            step: "step-2.3"
            file: "{{module.slug}}-ui-specs.md"
          - source: "step"
            step: "step-4.1"
            file: "views/"
        outputs:
          - name: "browser-tests/"
            description: "Laravel Dusk test classes"
            deploy_to: "{{config.paths.application_root}}/{{config.paths.browser_tests_dir}}/{{module.code}}/"
        validation:
          - check: "php_syntax"
            target: "browser-tests/"
            
      step-5.4:
        name: "Bug Fixing Loop"
        dir: "phase-5_testing-qa/step-5.4_bug-fixing"
        inputs:
          - source: "runtime"
            description: "Test failure outputs collected during test execution"
          - source: "step"
            step: "step-3.4"
            file: "services/"
          - source: "step"
            step: "step-3.5"
            file: "controllers/"
        outputs:
          - name: "fixes/"
            description: "Corrected code files"
          - name: "bug-report.md"
            description: "Summary of bugs found and fixes applied"
        validation:
          - check: "file_exists"
            target: "bug-report.md"
            
      step-5.5:
        name: "Code Review & Refactoring"
        dir: "phase-5_testing-qa/step-5.5_code-review"
        inputs:
          - source: "phase"
            phase: "phase-3"
            description: "All backend code"
          - source: "phase"
            phase: "phase-4"
            description: "All frontend code"
          - source: "step"
            step: "step-1.5"
            file: "coding-standards.md"
        outputs:
          - name: "review-report.md"
            description: "Code review findings and recommendations"
          - name: "refactored/"
            description: "Refactored code files"
        validation:
          - check: "file_exists"
            target: "review-report.md"

  # ══════════════════════════════════════════════════════════════
  # PHASE 6: DOCUMENTATION (Per Module)
  # ══════════════════════════════════════════════════════════════
  phase-6:
    name: "Module Documentation"
    scope: "per-module"
    steps:
    
      step-6.1:
        name: "API Documentation"
        dir: "phase-6_documentation/step-6.1_api-docs"
        inputs:
          - source: "step"
            step: "step-2.2"
            file: "{{module.slug}}-api-spec.yaml"
          - source: "step"
            step: "step-3.5"
            file: "controllers/"
        outputs:
          - name: "{{module.slug}}-api-docs.md"
            description: "Developer-facing API documentation"
            deploy_to: "{{config.paths.docs_dir}}/api/{{module.slug}}/"
          - name: "{{module.slug}}.postman.json"
            description: "Postman collection"
            deploy_to: "{{config.paths.docs_dir}}/api/{{module.slug}}/"
        validation:
          - check: "file_exists"
            target: "{{module.slug}}-api-docs.md"
            
      step-6.2:
        name: "Technical Documentation"
        dir: "phase-6_documentation/step-6.2_technical-docs"
        inputs:
          - source: "phase"
            phase: "phase-3"
            description: "All backend code"
          - source: "step"
            step: "step-2.1"
            file: "{{module.slug}}-erd.md"
          - source: "step"
            step: "step-1.4"
            file: "system-architecture.md"
        outputs:
          - name: "{{module.slug}}-technical-docs.md"
            description: "Technical reference documentation"
            deploy_to: "{{config.paths.docs_dir}}/technical/{{module.slug}}/"
        validation:
          - check: "file_exists"
            target: "{{module.slug}}-technical-docs.md"
            
      step-6.3:
        name: "User Manual"
        dir: "phase-6_documentation/step-6.3_user-manual"
        inputs:
          - source: "step"
            step: "step-2.3"
            file: "{{module.slug}}-ui-specs.md"
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
            filter: "module_section"
        outputs:
          - name: "{{module.slug}}-user-guide.md"
            description: "End-user documentation per role"
            deploy_to: "{{config.paths.docs_dir}}/user-guide/{{module.slug}}/"
        validation:
          - check: "file_exists"
            target: "{{module.slug}}-user-guide.md"

  # ══════════════════════════════════════════════════════════════
  # PHASE 7: INTEGRATION, DEPLOYMENT & OPS (One-time / Per-release)
  # ══════════════════════════════════════════════════════════════
  phase-7:
    name: "Integration, Deployment & Operations"
    scope: "once"
    steps:
    
      step-7.1:
        name: "Cross-Module Integration Tests"
        dir: "phase-7_integration-deployment/step-7.1_integration-tests"
        inputs:
          - source: "all-modules"
            description: "All completed module code"
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
        outputs:
          - name: "integration-tests/"
            description: "Cross-module integration test suite"
          - name: "data-flow-report.md"
            description: "Data flow verification report"
        validation:
          - check: "file_exists"
            target: "data-flow-report.md"
            
      step-7.2:
        name: "Performance Testing"
        dir: "phase-7_integration-deployment/step-7.2_performance-tests"
        inputs:
          - source: "all-modules"
            description: "Complete codebase"
          - source: "step"
            step: "step-1.1"
            file: "srs.md"
        outputs:
          - name: "load-tests/"
            description: "k6/Artillery test configurations"
          - name: "optimization-report.md"
            description: "Performance findings and optimizations"
        validation:
          - check: "file_exists"
            target: "optimization-report.md"
            
      step-7.3:
        name: "Security Audit"
        dir: "phase-7_integration-deployment/step-7.3_security-audit"
        inputs:
          - source: "all-modules"
            description: "Complete codebase"
          - source: "step"
            step: "step-1.4"
            file: "system-architecture.md"
        outputs:
          - name: "security-audit-report.md"
            description: "OWASP-categorized security findings"
          - name: "fixes/"
            description: "Security-patched code files"
        validation:
          - check: "file_exists"
            target: "security-audit-report.md"
            
      step-7.4:
        name: "DevOps & CI/CD"
        dir: "phase-7_integration-deployment/step-7.4_devops-cicd"
        inputs:
          - source: "step"
            step: "step-1.4"
            file: "system-architecture.md"
        outputs:
          - name: "docker/"
            description: "Dockerfile, docker-compose.yml"
            deploy_to: "{{config.paths.application_root}}/"
          - name: "ci-cd/"
            description: "GitHub Actions / GitLab CI pipeline files"
            deploy_to: "{{config.paths.application_root}}/.github/workflows/"
          - name: "env-templates/"
            description: ".env template files for each environment"
        validation:
          - check: "file_exists"
            target: "docker/Dockerfile"
          - check: "file_exists"
            target: "docker/docker-compose.yml"
            
      step-7.5:
        name: "Deployment Plan"
        dir: "phase-7_integration-deployment/step-7.5_deployment-plan"
        inputs:
          - source: "step"
            step: "step-7.4"
            file: "docker/"
        outputs:
          - name: "deployment-runbook.md"
            description: "Step-by-step deployment procedures"
            deploy_to: "{{config.paths.docs_dir}}/operations/"
          - name: "tenant-onboarding.md"
            description: "New tenant setup runbook"
            deploy_to: "{{config.paths.docs_dir}}/operations/"
        validation:
          - check: "file_exists"
            target: "deployment-runbook.md"
            
      step-7.6:
        name: "Monitoring & Maintenance"
        dir: "phase-7_integration-deployment/step-7.6_monitoring"
        inputs:
          - source: "step"
            step: "step-1.4"
            file: "system-architecture.md"
          - source: "step"
            step: "step-7.4"
            file: "docker/"
        outputs:
          - name: "monitoring-config/"
            description: "Monitoring and alerting configurations"
          - name: "maintenance-playbook.md"
            description: "Routine maintenance procedures"
            deploy_to: "{{config.paths.docs_dir}}/operations/"
        validation:
          - check: "file_exists"
            target: "maintenance-playbook.md"
            
      step-7.7:
        name: "Platform Documentation"
        dir: "phase-7_integration-deployment/step-7.7_platform-docs"
        inputs:
          - source: "all-docs"
            description: "All Phase 6 documentation"
          - source: "step"
            step: "step-7.4"
            file: "docker/"
        outputs:
          - name: "admin-guide.md"
            description: "System administration guide"
            deploy_to: "{{config.paths.docs_dir}}/"
          - name: "developer-guide.md"
            description: "Developer onboarding guide"
            deploy_to: "{{config.paths.docs_dir}}/"
          - name: "release-notes-template.md"
            description: "Release notes template"
            deploy_to: "{{config.paths.docs_dir}}/"
        validation:
          - check: "file_exists"
            target: "admin-guide.md"
```

---

## PART 5: PROMPT TEMPLATES

Now create the prompt template files. Each prompt uses `{{placeholders}}` that the orchestrator resolves from the config file at runtime.

**CRITICAL RULES FOR ALL PROMPT TEMPLATES:**
1. Every prompt must start by including the content from `templates/prompt-header.md`
2. Every code-generation prompt (Phase 3, 4, 5) must include `templates/coding-standards-snippet.md`
3. All `{{config.*}}` and `{{module.*}}` placeholders are resolved from `pipeline.config.yaml`
4. All `{{input:step-X.X:filename}}` placeholders are resolved by reading the output file from that step

### Template: `templates/prompt-header.md`

```markdown
# Context

You are developing a module for **{{config.project.name}}** — {{config.project.description}}.

**Current Module:** {{module.name}} (Code: {{module.code}})
**Table Prefix:** {{module.table_prefix}}
**Module Description:** {{module.description}}
**Dependencies:** {{module.depends_on}}

**Technology Stack:** PHP {{config.tech_stack.php_version}} / Laravel {{config.tech_stack.laravel_version}} / MySQL {{config.tech_stack.mysql_version}} / {{config.tech_stack.css_framework}} / {{config.tech_stack.js_framework}} / Livewire {{config.tech_stack.livewire_version}}
**Auth:** {{config.tech_stack.auth_package}} + {{config.tech_stack.rbac_package}}
**Architecture:** Multi-tenant SaaS with separate database per tenant (global_db + tenant_db pattern)

**Roles in the system:** {{config.roles}}
```

### Template: `templates/coding-standards-snippet.md`

```markdown
# Coding Standards (Summary)

- **Strict types:** `declare(strict_types=1);` in every PHP file
- **Naming:** Models = PascalCase singular, Controllers = {Model}Controller, Services = {Model}Service
- **API prefix:** `{{config.conventions.api_prefix}}`
- **API envelope:** All responses wrapped in `{"success": bool, "data": mixed, "message": string}`
- **Pagination:** Default {{config.conventions.pagination_default}}, max {{config.conventions.pagination_max}}
- **Tenant isolation:** Every query scoped by `{{config.database.tenant_id_column}}` via TenantScope trait
- **Audit columns:** `created_by`, `updated_by` (unsignedBigInteger, nullable) on every table
- **Soft deletes:** On all user-facing tables
- **Transactions:** All multi-model operations wrapped in `DB::transaction()`
- **Events:** Fire domain events from services, never from controllers
- **PHPDoc:** Full PHPDoc blocks on all public methods

Refer to the full coding-standards.md for complete conventions.
```

### Now create each step's `prompt.md`:

---

#### `phases/phase-1_requirements-architecture/step-1.1_srs/prompt.md`

```markdown
{{> templates/prompt-header.md}}

# Task: Generate Software Requirements Specification (SRS)

## Input
The following is the Requirements Breakdown Structure (RBS) for the entire {{config.project.name}} platform:

{{input:config:inputs.rbs_file}}

## Instructions

Convert this RBS into a comprehensive Software Requirements Specification document. Structure it as follows:

### For EACH module in the RBS, generate:

1. **Functional Requirements** with unique IDs using format `FR-{MODULE_CODE}-{NNN}`
   - Example: FR-STU-001, FR-STU-002, FR-FEE-001
   - Each requirement must be atomic, testable, and unambiguous

2. **Non-Functional Requirements** with IDs using format `NFR-{MODULE_CODE}-{NNN}`
   - Performance (response times, concurrent users)
   - Security (data isolation, encryption, RBAC)
   - Scalability (max tenants, max students per tenant)
   - Availability (uptime targets)
   - Compliance (NEP 2020, CBSE/ICSE board requirements)

3. **User Stories** for each role that interacts with the module:
   - Format: "As a [{{role}}], I want [action], so that [benefit]"
   - Roles to consider: {{config.roles}}
   - Each story must have **Acceptance Criteria** in Given/When/Then format

4. **Business Rules** — explicit rules governing the module's behavior
   - Example: "BR-FEE-001: A fee concession cannot exceed 100% of the original fee amount"
   - Include validation rules, calculation logic, state transitions

5. **Data Requirements** — what data this module creates, reads, updates, deletes
   - Entity list with key attributes
   - Relationships to other modules

6. **NEP 2020 / Indian Education Compliance** (where applicable)
   - How the module aligns with NEP 2020 guidelines
   - Board-specific requirements (CBSE, ICSE, State boards)

### Cross-cutting sections (at the end):

7. **Multi-Tenancy Requirements**
   - Data isolation requirements
   - Tenant provisioning requirements
   - Cross-tenant data prohibition

8. **Role-Permission Matrix** — a table showing every role × every module action
   - Columns: Role | Module | Create | Read | Update | Delete | Special Actions

9. **Traceability Matrix** — map every FR/NFR back to the RBS line item it originated from

10. **Data Volume Assumptions**
    - Expected number of tenants: [estimate]
    - Students per tenant: 500–5000
    - Staff per tenant: 50–500
    - Concurrent users per tenant: up to 200

## Output Format
- Single Markdown file named `srs.md`
- Use consistent heading hierarchy (H1 for module names, H2 for sections, H3 for sub-sections)
- Every requirement must have a unique ID that will be referenced in all downstream documents
- Include a Table of Contents at the top
```

---

#### `phases/phase-1_requirements-architecture/step-1.2_dependency-map/prompt.md`

```markdown
{{> templates/prompt-header.md}}

# Task: Generate Module Dependency Map & Build Sequence

## Input
{{input:step-1.1:srs.md}}

## Instructions

Analyze the SRS and produce:

1. **Mermaid Dependency Graph**
   - Every module as a node
   - Directed edges showing "depends on" relationships
   - Color-code by priority tier (P0=red, P1=orange, P2=yellow, P3=green, P4=blue, P5=purple, P6=pink, P7=gray)

2. **Topologically Sorted Build Order**
   - Table format: Priority | Module | Depends On | Blocks (downstream modules) | Estimated Complexity (S/M/L/XL)
   - Rationale for each module's position

3. **Circular Dependency Analysis**
   - Identify any circular dependencies
   - Provide resolution strategies (interface extraction, event-based decoupling)

4. **Critical Path Analysis**
   - Which modules, if delayed, delay the most downstream work?
   - Recommended parallelization opportunities

5. **Release Grouping Recommendation**
   - Group modules into logical releases (MVP, v1.1, v1.2, etc.)
   - Each release should be independently deployable and valuable

## Output Format
- Single Markdown file named `dependency-map.md`
- Mermaid diagrams must be in fenced code blocks with `mermaid` language identifier
```

---

#### `phases/phase-1_requirements-architecture/step-1.3_data-dictionary/prompt.md`

```markdown
{{> templates/prompt-header.md}}

# Task: Generate Data Dictionary & Domain Glossary

## Input
{{input:step-1.1:srs.md}}

## Instructions

Extract every domain term, entity, enumeration, and concept from the SRS and produce:

1. **Domain Glossary** — alphabetical table:
   | Term | Definition | Module(s) | Example Values |
   
   Include terms like: tenant, academic_session, section, house, HPC dimension, SCORM package, Bloom's taxonomy level, fee_head, concession, route_stop, attendance_status, etc.

2. **Entity Registry** — for every data entity:
   | Entity | Module | Description | Key Attributes | Relationships |

3. **Enumeration Registry** — every enum/status/type:
   | Enum Name | Module | Values | Description |
   
   Examples: attendance_status (Present, Absent, Late, Half-Day), fee_status (Pending, Paid, Partial, Overdue), etc.

4. **Abbreviation Reference**
   | Abbreviation | Full Form |
   
   Examples: HPC = Holistic Progress Card, LMS = Learning Management System, NEP = National Education Policy

## Output Format
- Single Markdown file named `data-dictionary.md`
- All terms must be precise enough that any developer can implement them without ambiguity
```

---

#### `phases/phase-1_requirements-architecture/step-1.4_system-architecture/prompt.md`

```markdown
{{> templates/prompt-header.md}}

# Task: Generate System Architecture Document

## Inputs
{{input:step-1.1:srs.md}}
{{input:step-1.2:dependency-map.md}}
{{input:step-1.3:data-dictionary.md}}

## Instructions

Design the complete system architecture for {{config.project.name}}. Cover every layer:

### 1. Multi-Tenant Architecture
- **global_db schema:** tenants table, plans, global configs, super-admin users
- **tenant_db schema pattern:** how each tenant gets its own database
- **Tenant resolution:** middleware that identifies tenant from subdomain/header → switches DB connection
- **Connection switching:** Laravel database manager configuration
- **Data isolation guarantee:** how to prevent cross-tenant data leaks

### 2. Application Layer Architecture
- **Directory structure:** complete Laravel folder organization
- **Service layer pattern:** Controller → Service → Model flow
- **Repository pattern:** if/when to use repositories
- **DTO pattern:** data transfer between layers
- **Event-driven architecture:** domain events, listeners, async processing
- **Trait library:** TenantScoped, HasAuditColumns, HasSlug, Searchable, etc.

### 3. API Architecture
- **Versioning strategy:** URL prefix (`/api/v1/`)
- **Authentication:** Sanctum token flow for SPA + API
- **Rate limiting:** per-tenant, per-user limits
- **Response envelope:** standard JSON structure
- **Error handling:** error codes, exception handler customization
- **Pagination:** cursor vs offset, default/max page sizes
- **Filtering & sorting:** query parameter conventions

### 4. Caching Strategy
- **Cache drivers:** Redis for sessions, cache, queue
- **Tenant-scoped cache keys:** `tenant:{id}:cache_key` pattern
- **Cache invalidation:** event-based invalidation
- **Query caching:** which queries to cache, TTL strategy

### 5. Queue Architecture
- **Queue connections:** separate queues for priority levels
- **Job types:** sync vs queued decision criteria
- **Failure handling:** failed_jobs table, retry strategy, dead letter
- **Horizon configuration:** supervisor settings, balancing

### 6. File Storage
- **Tenant isolation:** `tenant/{id}/` prefix in storage
- **Storage driver:** local for dev, S3-compatible for production
- **File types:** student photos, documents, SCORM packages, report PDFs
- **Upload validation:** size limits, type restrictions

### 7. Security Architecture
- **RBAC model:** Spatie Permission structure, role hierarchy
- **Data encryption:** at-rest and in-transit
- **Audit logging:** what to log, retention policy
- **Input sanitization:** XSS prevention, SQL injection prevention
- **CORS configuration**

### 8. Deployment Architecture (high-level)
- **Containerization:** Docker setup overview
- **CI/CD pipeline:** testing → staging → production flow
- **Database migration strategy:** for multi-tenant with 100+ tenant DBs
- **Scaling strategy:** horizontal scaling, read replicas

Include Mermaid diagrams for: system context diagram, container diagram, component diagram, database architecture diagram, and request flow diagram.

## Output Format
- Single Markdown file named `system-architecture.md`
- Mermaid diagrams in fenced code blocks
- Must be specific enough to implement — no hand-waving
```

---

#### `phases/phase-1_requirements-architecture/step-1.5_coding-standards/prompt.md`

```markdown
{{> templates/prompt-header.md}}

# Task: Generate Coding Standards & Project Scaffold

## Input
{{input:step-1.4:system-architecture.md}}

## Instructions

### Part A: Coding Standards Document

Create a comprehensive coding standards document covering:

1. **Naming Conventions** — table format for every artifact type:
   | Artifact | Convention | Example |
   Models, Controllers, Services, FormRequests, Resources, Events, Listeners, Jobs, Notifications, Migrations, Seeders, Factories, Policies, Middleware, Traits, Enums, Config keys, Route names, View files, Test classes

2. **Folder Structure** — complete tree of the Laravel project with descriptions

3. **PHP Standards**
   - `declare(strict_types=1)` everywhere
   - Return type declarations mandatory
   - PHPDoc for all public methods
   - Type hints for all parameters

4. **API Conventions**
   - Endpoint URL patterns
   - HTTP method usage
   - Response envelope format with examples
   - Error response format with error code registry
   - Pagination format
   - Filtering, sorting, including relationships

5. **Database Conventions**
   - Table naming (snake_case, plural, prefixed with module code)
   - Column naming patterns
   - Index naming: `idx_{table}_{columns}`
   - Foreign key naming: `fk_{table}_{column}_{ref_table}`
   - Migration naming

6. **Tenant Isolation Patterns**
   - TenantScope global scope implementation
   - How to ensure every query is tenant-scoped
   - Testing patterns for isolation verification

7. **Testing Standards**
   - Test file naming and organization
   - Required test categories per module
   - Factory usage patterns
   - Assertion conventions

8. **Git Standards**
   - Branch naming: `{{config.execution.git_branch_prefix}}{module-slug}`
   - Commit message format
   - PR template

### Part B: Project Scaffold Code

Generate the following base files:

1. `app/Traits/TenantScoped.php` — Global scope that adds `where tenant_id = current_tenant`
2. `app/Traits/HasAuditColumns.php` — Auto-fills created_by, updated_by from auth
3. `app/Traits/ApiResponse.php` — Standard JSON response methods (success, error, paginated)
4. `app/Services/BaseService.php` — Abstract base service class
5. `app/Http/Controllers/Api/V1/BaseApiController.php` — Abstract base API controller
6. `app/Http/Middleware/TenantResolver.php` — Resolves and sets current tenant
7. `app/Http/Middleware/AuditLogMiddleware.php` — Logs API requests for audit
8. `app/Exceptions/Handler.php` — Customized exception handler for API error responses
9. `config/tenant.php` — Tenant configuration file
10. `.editorconfig` — Editor configuration
11. `phpstan.neon` — Static analysis configuration
12. `pint.json` — Code style fixer configuration

## Output Format
- `coding-standards.md` — the standards document
- `scaffold/` directory — containing all the PHP files listed above, in their correct subdirectory structure
```

---

#### `phases/phase-2_module-design/step-2.1_erd/prompt.md`

```markdown
{{> templates/prompt-header.md}}
{{> templates/coding-standards-snippet.md}}

# Task: Design Entity-Relationship Diagram for {{module.name}}

## Inputs
### Module Requirements (from SRS)
{{input:step-1.1:srs.md | filter:module_section}}

### Data Dictionary
{{input:step-1.3:data-dictionary.md}}

### Database Architecture Patterns
{{input:step-1.4:system-architecture.md | filter:db_patterns_section}}

## Instructions

Design the complete database schema for the **{{module.name}}** module.

### 1. Mermaid ER Diagram
- Show all tables with their columns
- Show all relationships (1:1, 1:N, M:N)
- Include junction tables for M:N relationships

### 2. Detailed Table Specifications

For EACH table, provide:

| Column | Type | Nullable | Default | Index | FK Reference | Notes |
|--------|------|----------|---------|-------|-------------|-------|

Rules:
- **Table prefix:** All tables must use `{{module.table_prefix}}` prefix
- **Tenant isolation:** Include `{{config.database.tenant_id_column}}` column (unsignedBigInteger, indexed)
- **Soft deletes:** `deleted_at` timestamp nullable on user-facing tables
- **Audit columns:** `created_by` and `updated_by` (unsignedBigInteger, nullable)
- **Timestamps:** `created_at` and `updated_at`
- **Primary key:** `id` as unsignedBigInteger auto-increment (unless UUID configured)
- **Foreign keys:** Reference tables from this module AND from dependency modules: {{module.depends_on}}
- **Indexes:** Create indexes for:
  - All foreign key columns
  - Columns used in WHERE clauses (inferred from SRS query patterns)
  - Columns used in ORDER BY
  - Composite indexes for common query combinations
- **Enums:** Define as string columns with allowed values documented, NOT MySQL ENUM type

### 3. Seed Data Specification
- What lookup/reference data needs to be seeded
- Use realistic Indian school data (Indian names, CBSE/ICSE terminology, INR values)

### 4. Cross-Module References
- List every foreign key that references a table from another module
- Verify those tables exist in the dependency modules

## Output Format
- Single Markdown file named `{{module.slug}}-erd.md`
- Mermaid ER diagram in fenced code block
- One table specification section per database table
```

---

#### `phases/phase-2_module-design/step-2.2_api-specification/prompt.md`

```markdown
{{> templates/prompt-header.md}}
{{> templates/coding-standards-snippet.md}}

# Task: Design API Specification for {{module.name}}

## Inputs
### Module Requirements (from SRS)
{{input:step-1.1:srs.md | filter:module_section}}

### ERD
{{input:step-2.1:{{module.slug}}-erd.md}}

### Coding Standards
{{input:step-1.5:coding-standards.md}}

## Instructions

Create a complete OpenAPI 3.0 specification for the **{{module.name}}** module's REST API.

### For each resource/entity in the ERD, define these endpoints:

| Method | Endpoint | Purpose |
|--------|---------|---------|
| GET | /{{config.conventions.api_prefix}}/{{module.slug}}/{resource} | List with filters |
| POST | /{{config.conventions.api_prefix}}/{{module.slug}}/{resource} | Create |
| GET | /{{config.conventions.api_prefix}}/{{module.slug}}/{resource}/{id} | Show detail |
| PUT | /{{config.conventions.api_prefix}}/{{module.slug}}/{resource}/{id} | Update |
| DELETE | /{{config.conventions.api_prefix}}/{{module.slug}}/{resource}/{id} | Soft delete |

Plus any module-specific action endpoints from the SRS.

### For EACH endpoint, specify:

1. **URL pattern** following conventions
2. **Request body schema** (for POST/PUT) with:
   - Every field with type, required/optional, validation rules
   - Nested objects for related data
3. **Response schema** using envelope format:
   ```json
   {"success": true, "data": {...}, "message": "..."}
   ```
4. **Query parameters** (for GET list):
   - Filtering: `?status=active&class_id=5`
   - Sorting: `?sort=name&direction=asc`
   - Pagination: `?page=1&per_page={{config.conventions.pagination_default}}`
   - Includes: `?include=class,section,parent`
   - Search: `?search=keyword`
5. **Authentication:** Bearer token required
6. **Permissions:** Which roles can access (from SRS role matrix)
7. **Validation rules** matching SRS acceptance criteria
8. **Error responses:** 400, 401, 403, 404, 422, 500 with error code and message
9. **Example request and response** (with realistic Indian school data)

## Output Format
- `{{module.slug}}-api-spec.yaml` — OpenAPI 3.0 YAML
- `{{module.slug}}-api-summary.md` — Human-readable API summary with examples
```

---

#### `phases/phase-2_module-design/step-2.3_ui-ux-wireframes/prompt.md`

```markdown
{{> templates/prompt-header.md}}

# Task: Design UI/UX Screens for {{module.name}}

## Inputs
### Module Requirements (from SRS)
{{input:step-1.1:srs.md | filter:module_section}}

### API Specification
{{input:step-2.2:{{module.slug}}-api-summary.md}}

## Instructions

Design all UI screens for the **{{module.name}}** module.

### For each screen, provide:

1. **Screen Metadata**
   - Screen name and purpose
   - URL route (e.g., `/admin/students`, `/admin/students/{id}/edit`)
   - Accessible by roles: [list which roles from {{config.roles}}]
   - Parent navigation location (sidebar section)

2. **Layout Description**
   - Page structure (full-width, sidebar+content, multi-column)
   - Components used (data table, form, cards, tabs, modals)
   - Responsive behavior (how it adapts to mobile)

3. **Data Table Screens** (list/index views)
   - Columns with: name, data source, sortable?, filterable?, width
   - Bulk action buttons (delete, export, status change)
   - Row action buttons (view, edit, delete)
   - Search bar behavior
   - Filter panel fields
   - Export options (CSV, PDF)

4. **Form Screens** (create/edit views)
   - Every form field with:
     | Field Label | Field Name | Type | Required | Validation | Data Source | Notes |
   - Field types: text, textarea, select, multi-select, date, datetime, file, toggle, radio, checkbox, dependent-dropdown
   - Form sections/tabs for grouping related fields
   - Submit/Cancel button behavior
   - Success/error feedback

5. **Detail Screens** (show views)
   - Information sections with fields displayed
   - Related data tabs (e.g., Student detail → Attendance tab, Fees tab, Grades tab)
   - Action buttons available on this screen

6. **Dashboard Widget Specifications**
   - What widgets this module contributes to each role's dashboard
   - Widget type (stat card, chart, table, quick-action)
   - Data source (which API endpoint)
   - Refresh behavior

7. **Navigation Flow Diagram**
   - Mermaid flowchart showing how screens connect
   - Which actions navigate to which screens

8. **Print Views** (if applicable)
   - Report cards, fee receipts, ID cards, certificates
   - Paper size, orientation, content layout

## Output Format
- Single Markdown file named `{{module.slug}}-ui-specs.md`
- Include Mermaid navigation flow diagram
- Be specific enough that a frontend developer can implement without further questions
```

---

#### `phases/phase-3_backend-development/step-3.1_migrations/prompt.md`

```markdown
{{> templates/prompt-header.md}}
{{> templates/coding-standards-snippet.md}}

# Task: Generate Laravel Database Migrations for {{module.name}}

## Inputs
### ERD
{{input:step-2.1:{{module.slug}}-erd.md}}

### Coding Standards
{{input:step-1.5:coding-standards.md}}

## Instructions

Generate complete Laravel migration files for every table defined in the ERD.

### Requirements for each migration file:

1. **File naming:** `{timestamp}_create_{{module.table_prefix}}{table_name}_table.php`
2. **Schema definition** matching the ERD exactly:
   - Column types matching ERD spec
   - Nullable columns marked correctly
   - Default values set
   - All indexes created (named using convention: `idx_{table}_{columns}`)
   - All foreign keys created (named using convention: `fk_{table}_{column}_{ref}`)
   - Foreign key cascade rules: onDelete('cascade') or onDelete('restrict') as appropriate
3. **Standard columns on every table:**
   - `$table->id();`
   - `$table->unsignedBigInteger('{{config.database.tenant_id_column}}')->index();`
   - `$table->unsignedBigInteger('created_by')->nullable();`
   - `$table->unsignedBigInteger('updated_by')->nullable();`
   - `$table->timestamps();`
   - `$table->softDeletes();` (on user-facing tables)
4. **Down method:** must correctly reverse the migration (drop tables in correct order for FKs)
5. **Order migrations** so that parent tables are created before child tables (FK dependencies)

### Also generate:

6. **Seeder file:** `{Module}Seeder.php`
   - Seed lookup/reference tables with realistic Indian school data
   - Use Indian names (Hindi/English), CBSE/ICSE board terminology
   - INR currency values where applicable
   - Indian phone number format (+91 XXXXX XXXXX)
   - Indian address format (City, State, PIN code)

7. **Factory files:** `{Model}Factory.php` for each model
   - Use Faker with `en_IN` locale where available
   - Generate realistic test data for all columns
   - Respect foreign key relationships (use factory states)

## Output Format
- `migrations/` directory with one `.php` file per migration, ordered by dependency
- `seeders/` directory with seeder file(s)
- `factories/` directory with factory file(s)
- All files must be valid PHP that passes syntax check
```

---

Now create similar prompt templates for the remaining steps. I'll provide the key instructions for each — **follow the same format as above** with the `{{> templates/prompt-header.md}}`, `{{> templates/coding-standards-snippet.md}}` (for code steps), `## Inputs`, `## Instructions`, and `## Output Format` sections.

---

#### `phases/phase-3_backend-development/step-3.2_models/prompt.md`

Key instructions: Generate Eloquent models for every table. Include: `$fillable`, `$casts`, all relationships matching ERD, `TenantScoped` trait, local scopes from SRS query patterns (`scopeActive`, `scopeByAcademicSession`, `scopeByClass`), accessors/mutators, `boot()` method with creating/updating events for audit columns, complete PHPDoc blocks. Output: `models/` directory.

---

#### `phases/phase-3_backend-development/step-3.3_form-requests/prompt.md`

Key instructions: Generate FormRequest classes for every API endpoint. Include: validation rules matching API spec and SRS, custom error messages, `authorize()` checking Spatie permissions, conditional rules (`required_if`, `required_without`), custom validation rules for domain logic, `prepareForValidation()` for data sanitization. One request class per create/update endpoint. Output: `requests/` directory.

---

#### `phases/phase-3_backend-development/step-3.4_services/prompt.md`

Key instructions: Generate service classes following thin-controller-fat-service pattern. Each service: extends `BaseService`, handles all business logic from SRS, uses `DB::transaction()` for multi-step ops, fires domain events, returns arrays/DTOs (never models), includes PHPDoc with `@throws`, implements logging, handles SRS edge cases. Output: `services/` directory.

---

#### `phases/phase-3_backend-development/step-3.5_controllers-routes/prompt.md`

Key instructions: Generate API controllers with constructor-injected services, type-hinted FormRequests, JSON responses via `ApiResponse` trait, Spatie middleware, pagination support, API Resources for response shaping. Generate route file with grouping, middleware, and version prefix. Also generate: API Resource classes, Policy classes. Output: `controllers/`, `resources/`, `policies/`, `routes/` directories.

---

#### `phases/phase-3_backend-development/step-3.6_events-listeners/prompt.md`

Key instructions: Generate event classes carrying relevant data, listener classes reacting to events, notification classes with SMS/email/database channels, EventServiceProvider registration entries. Output: `events/`, `listeners/`, `notifications/` directories.

---

#### `phases/phase-3_backend-development/step-3.7_jobs-scheduling/prompt.md`

Key instructions: Generate queued job classes for heavy operations (bulk operations, PDF generation, reminders, data aggregation, exports). Include retry logic, failure handling, rate limiting. Generate schedule entries for Kernel. Output: `jobs/` directory + `schedule-config.md`.

---

#### `phases/phase-4_frontend-development/step-4.1_blade-templates/prompt.md`

Key instructions: Generate Blade templates using Tailwind CSS, extending master layout, with reusable components (data tables, forms, modals, stat cards). Responsive mobile-first design. Alpine.js for client interactivity. Include: index/list view, create/edit form, detail/show view, print views. Output: `views/` directory.

---

#### `phases/phase-4_frontend-development/step-4.2_livewire-components/prompt.md`

Key instructions: Generate Livewire components for: real-time search/filter, dependent dropdowns, inline editing, modal forms, file upload, drag-drop interfaces. Output: `livewire-classes/` and `livewire-views/` directories.

---

#### `phases/phase-4_frontend-development/step-4.3_alpine-js/prompt.md`

Key instructions: Generate Alpine.js components for: form validation, confirmation dialogs, toasts, print handlers, chart initialization (Chart.js), calendar widgets, data export triggers. Output: `js/` directory.

---

#### `phases/phase-4_frontend-development/step-4.4_dashboard-widgets/prompt.md`

Key instructions: For each role using this module, generate dashboard widget Livewire components. Each widget: self-contained with own data query, appropriate chart/stat/table type, configurable refresh interval. Output: `widgets/` directory.

---

#### `phases/phase-5_testing-qa/step-5.1_unit-tests/prompt.md`

Key instructions: Generate PHPUnit unit tests for service and model classes. Test: happy path, boundary values, business rule enforcement from SRS, edge cases, tenant isolation. Use factories, mock external dependencies, data providers for parameterized tests. Output: `unit-tests/` directory.

---

#### `phases/phase-5_testing-qa/step-5.2_feature-tests/prompt.md`

Key instructions: Generate feature tests for every API endpoint. Test: full HTTP request/response, RBAC per role, validation (422 responses), pagination/sorting/filtering, cascading effects, tenant isolation at HTTP level, response envelope format. Use `RefreshDatabase`, factories. Output: `feature-tests/` directory.

---

#### `phases/phase-5_testing-qa/step-5.3_browser-tests/prompt.md`

Key instructions: Generate Laravel Dusk tests for critical user flows: login → navigate → CRUD → verify. Test role-based access, Livewire interactions, modal workflows, print views. Output: `browser-tests/` directory.

---

#### `phases/phase-5_testing-qa/step-5.4_bug-fixing/prompt.md`

Key instructions: This is an iterative prompt. Input is test failure output + source code. Analyze the failure, identify root cause, provide corrected code with explanation. Support different failure types: migration errors, 500 API errors, Livewire reactivity issues, tenant isolation leaks, validation failures. Output: `fixes/` directory + `bug-report.md`.

---

#### `phases/phase-5_testing-qa/step-5.5_code-review/prompt.md`

Key instructions: Review all module code for: coding standards compliance, security vulnerabilities (SQLi, XSS, CSRF, mass assignment, IDOR, cross-tenant access), performance issues (N+1, missing indexes), error handling gaps, dead code, naming consistency, design pattern opportunities. Output: `review-report.md` + `refactored/` directory.

---

#### `phases/phase-6_documentation/step-6.1_api-docs/prompt.md`

Key instructions: Generate updated OpenAPI docs reflecting final code, with curl examples, Postman collection, auth setup guide, error code reference, webhook/event docs. Output: `{{module.slug}}-api-docs.md` + `{{module.slug}}.postman.json`.

---

#### `phases/phase-6_documentation/step-6.2_technical-docs/prompt.md`

Key instructions: Generate: module architecture overview, class diagrams (Mermaid), DB schema docs, service method reference, event/listener map, job docs, config options, troubleshooting guide. Output: `{{module.slug}}-technical-docs.md`.

---

#### `phases/phase-6_documentation/step-6.3_user-manual/prompt.md`

Key instructions: Per-role user guide with: step-by-step instructions, workflow walkthroughs, FAQ, troubleshooting. Simple English for non-technical school staff. Output: `{{module.slug}}-user-guide.md`.

---

#### Phase 7 step prompts (7.1 through 7.7):

Create prompt templates for each following the same pattern. Key focus areas:
- **7.1:** Integration tests verifying cross-module data flows
- **7.2:** k6/Artillery load test configs + query optimization
- **7.3:** OWASP security checklist with severity-rated findings
- **7.4:** Dockerfile, docker-compose.yml, GitHub Actions CI/CD pipeline, .env templates
- **7.5:** Deployment checklist, rollback procedures, tenant onboarding script
- **7.6:** Telescope config, Sentry integration, health checks, maintenance playbook
- **7.7:** Admin guide, developer onboarding guide, release notes template

---

## PART 6: PHASE README FILES

Create a `README.md` in each phase directory with:
- Phase name and description
- When to execute (once vs per-module)
- Steps in this phase with brief descriptions
- Estimated time to complete
- Prerequisites (which phases must be done first)

---

## PART 7: VALIDATION RULES FILES

Create `validation-rules.yaml` in each step directory. These define what makes a step's output valid. The orchestrator reads these to auto-validate output before marking a step complete.

Use this format:

```yaml
validations:
  - type: "file_exists"
    target: "output-filename.md"
    message: "Output file must exist"
    
  - type: "min_file_size"
    target: "output-filename.md"
    min_bytes: 1000
    message: "Output must be at least 1KB"
    
  - type: "contains_pattern"
    target: "output-filename.md"
    pattern: "required-text"
    message: "Output must contain required pattern"
    
  - type: "php_syntax_check"
    target: "directory/"
    message: "All PHP files must have valid syntax"
    
  - type: "file_count_min"
    target: "directory/"
    extension: ".php"
    min_count: 1
    message: "Directory must contain at least 1 PHP file"
```

---

## PART 8: .gitignore

Create `dev-pipeline/.gitignore`:

```
# Pipeline runtime state
state/*.json
state/*.log
!state/.gitkeep

# Step outputs (generated, can be recreated)
phases/**/output/*
!phases/**/output/.gitkeep

# Temporary files
*.tmp
*.bak
```

---

## EXECUTION INSTRUCTIONS

After creating all the above files:

1. **Verify the folder structure** by running: `find dev-pipeline -type f | head -100`
2. **Verify YAML syntax** of all `.yaml` files
3. **Count the prompt templates** — there should be exactly 33 `prompt.md` files (one per step)
4. **Report back** with a summary of what was created and any decisions you made

**Do NOT create the orchestrator.py, validator.py, or utils.py yet** — we will build those separately after reviewing the pipeline structure.

**Do NOT execute any prompts** — just create the template files.

---

## FINAL NOTES

- This pipeline is designed to work with Claude Agent in VS Code. Each step's prompt will be fed to Claude Agent with the resolved inputs.
- The `{{placeholder}}` syntax is for the orchestrator to resolve at runtime — do NOT replace them with actual values in the template files.
- The `{{input:step-X.X:filename}}` syntax means "read the output file from step X.X and insert its content here."
- The `{{> templates/filename.md}}` syntax means "include the content of that template file here."
- Every code-generation step (Phases 3, 4, 5) must produce files that pass PHP syntax check (`php -l`).
