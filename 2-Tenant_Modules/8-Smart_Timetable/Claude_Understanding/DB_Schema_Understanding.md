# Prime-AI ERP/LMS/LXP — Complete Database Schema Understanding
> **Prepared by:** Claude (AI Assistant)
> **Date:** March 2026
> **Repo:** `prime-ai_db/databases`
> **Application:** Advanced ERP + LMS + LXP for Indian Schools (SaaS, Multi-Tenant)
> **Stack:** PHP + Laravel + MySQL 8.x

---

## 1. DATABASE ARCHITECTURE — HIGH LEVEL

### 3-Layer Multi-Tenant SaaS Design

```
┌─────────────────────────────────────────────────────────────┐
│                    GLOBAL MASTER DB (global_db)              │
│  Countries, States, Districts, Cities, Boards, Languages     │
│  Academic Sessions, Menus, Modules, Translations             │
└──────────────────────┬──────────────────────────────────────┘
                       │ Shared Reference
┌──────────────────────▼──────────────────────────────────────┐
│                    PRIME DB (prime_db)                        │
│  Tenant Registration, Plans, Module Licensing                 │
│  SaaS Billing, Invoicing, Payments                           │
│  System Users (Super Admins), Roles, Permissions             │
└──────────────────────┬──────────────────────────────────────┘
                       │ One DB per School
┌──────────────────────▼──────────────────────────────────────┐
│              TENANT DB (tenant_db) × N Schools               │
│  School Operations: Students, Staff, LMS, Exams              │
│  Finance, Transport, Library, HPC Reports, Timetable         │
│  Each school = isolated database = same schema               │
└─────────────────────────────────────────────────────────────┘
```

**Key Design Decisions:**
- **Database-level isolation** per tenant (not row-level multi-tenancy)
- Connection credentials stored in `prm_tenant_domains` in prime_db
- Schema identical across all tenant databases
- Module access controlled via `prm_tenant_plan_module_jnt`

---

## 2. TABLE NAMING CONVENTIONS

### Module Prefix Reference
| Prefix | Module | Database |
|--------|--------|----------|
| `glb_` | Global Masters | global_db |
| `sys_` | System Config (Auth, Roles, Media, Logs, Settings) | prime_db + tenant_db |
| `prm_` | Prime / Tenant Management | prime_db |
| `bil_` | Billing & Invoicing | prime_db |
| `sch_` | School Setup (Classes, Sections, Calendar) | tenant_db |
| `std_` | Student Management & Profiles | tenant_db |
| `slb_` | Syllabus & Curriculum | tenant_db |
| `bok_` | Syllabus Books | tenant_db |
| `qns_` | Question Bank | tenant_db |
| `exm_` | Exam Management | tenant_db |
| `quz_` | Quiz & Quest (Assessment) | tenant_db |
| `beh_` | Behavioral Assessment | tenant_db (pending) |
| `hpc_` | Holistic Report Card (NEP 2020) | tenant_db |
| `rec_` | Recommendation Engine | tenant_db |
| `tt_`  | Smart Timetable | tenant_db |
| `tpt_` | Transport Management | tenant_db |
| `lib_` | Library Management | tenant_db |
| `fin_` | Student Fee Management | tenant_db |
| `vnd_` | Vendor Management | tenant_db |
| `cmp_` | Complaint & Grievance | tenant_db |
| `fnt_` | Frontdesk Management | tenant_db |
| `hos_` | Hostel Management | tenant_db (pending) |
| `mes_` | Mess / Canteen | tenant_db (pending) |
| `acc_` | Accounting | tenant_db (pending) |
| `sys_event_*` | Event Engine (Rule Engine) | tenant_db |

**Junction table suffix:** `_jnt` (e.g., `prm_module_plan_jnt`)

### Universal Column Patterns (All Tables)
```sql
is_active    TINYINT(1)  -- Logical enable/disable flag
deleted_at   TIMESTAMP   -- Soft delete marker (NULL = active)
created_at   TIMESTAMP   -- Record creation time
updated_at   TIMESTAMP   -- Last modification time
```

---

## 3. GLOBAL DATABASE (global_db)

**File:** `1-master_dbs/1-DDL_schema/global_db.sql` (189 lines)

### Tables
| Table | Purpose |
|-------|---------|
| `glb_countries` | Country master with currency codes |
| `glb_states` | States linked to countries |
| `glb_districts` | Districts linked to states |
| `glb_cities` | Cities with timezone (linked to district) |
| `glb_academic_sessions` | Academic year definitions (e.g., 2024-25) |
| `glb_boards` | Educational boards (CBSE, ICSE, State Boards) |
| `glb_languages` | Multi-language with RTL/LTR direction |
| `glb_menus` | Hierarchical app navigation menu |
| `glb_modules` | Module registry (versioned) |
| `glb_menu_model_jnt` | Menu ↔ Module mapping |
| `glb_translations` | Polymorphic multi-language translations |

---

## 4. PRIME DATABASE (prime_db)

**File:** `1-master_dbs/1-DDL_schema/prime_db.sql` (645 lines)

### System Tables (sys_ prefix)
| Table | Purpose |
|-------|---------|
| `sys_permissions` | Fine-grained permissions (Spatie Laravel based) |
| `sys_roles` | Role definitions (system vs tenant) |
| `sys_role_has_permissions_jnt` | Role ↔ Permission mapping |
| `sys_model_has_permissions_jnt` | Entity-level permissions (polymorphic) |
| `sys_model_has_roles_jnt` | Entity-level roles (polymorphic) |
| `sys_users` | Super admins and system users |
| `sys_settings` | Key-value config (public/private) |
| `sys_dropdown_needs` | Dropdown field configuration |
| `sys_dropdown_table` | Dropdown values with ordinal sorting |
| `sys_dropdown_need_table_jnt` | Dropdown config mapping |
| `sys_media` | Media file management (polymorphic) |
| `sys_activity_logs` | Full audit trail for all changes |

### Prime Tenant Management (prm_ prefix)
| Table | Purpose |
|-------|---------|
| `prm_tenant_groups` | School group/chains |
| `prm_tenant` | Individual school definitions |
| `prm_tenant_domains` | Domain → Database credential mapping |
| `prm_billing_cycles` | MONTHLY / QUARTERLY / YEARLY / ONE_TIME |
| `prm_plans` | Subscription plans with multi-tier pricing |
| `prm_module_plan_jnt` | Modules included in each plan |
| `prm_tenant_plan_jnt` | School subscription records (trial/active/suspended) |
| `prm_tenant_plan_rates` | Per-school billing rates + 4 tax types |
| `prm_tenant_plan_module_jnt` | Active modules per school per plan |
| `prm_tenant_plan_billing_schedule` | Pre-calculated billing dates |

### Billing Tables (bil_ prefix)
| Table | Purpose |
|-------|---------|
| `bil_tenant_invoices` | Invoice generation (qty-based billing) |
| `bil_tenant_invoicing_modules_jnt` | Module charges per invoice |
| `bil_tenant_invoicing_payments` | Payment records with gateway response |
| `bil_tenant_invoicing_audit_logs` | Billing lifecycle tracking |
| `bil_tenant_email_schedules` | Email notification scheduling |

**Billing Model:**
- Supports 4 tax types per rate (tax1% → tax4%)
- Monthly/Quarterly/Yearly pricing per tenant
- Minimum billing quantity (licenses)
- Discount (percent + fixed amount)
- Credit days for invoicing

---

## 5. TENANT DATABASE (tenant_db) — MAIN SCHEMA

**File:** `1-master_dbs/1-DDL_schema/tenant_db.sql` (4,219 lines)

### 5.1 System Tables (Replicated from prime_db)
Same `sys_*` structure as prime_db — duplicated per tenant for isolation.

**Special Patterns:**
- Generated columns for UNIQUE constraints on nullable booleans:
  ```sql
  super_admin_flag TINYINT(1) GENERATED ALWAYS AS (IF(is_super_admin=1, 1, NULL)) STORED
  ```
- Trigger on `sys_users` to protect super admin deletion

---

## 6. MODULE-BY-MODULE SCHEMA DETAIL

### 6.1 School Setup (sch_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/3-School_Setup/`

Key tables:
- `sch_classes` — Grade/class levels
- `sch_sections` — Sections per class
- `sch_subjects` — Subject master
- `sch_subject_groups` — Subject group mappings
- `sch_academic_terms` — Terms per academic session
- `sch_class_groups_jnt` — Class groupings (used by Rule Engine for target audience)
- `sch_school_calendar` — School calendar events
- Infrastructure: `infra_buildings`, `infra_room_types`, `infra_rooms`

---

### 6.2 Student Management (std_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/13-StudentProfile/`

Key tables:
- `std_students` — Student master profile
- `std_student_academic_sessions` — Student ↔ Academic session enrollment
- `std_student_parents` — Parent profiles and relationships
- `std_student_documents` — Document storage (polymorphic via sys_media)

---

### 6.3 Syllabus & Curriculum (slb_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/9-Syllabus/`

Key tables:
- `slb_syllabus` — Syllabus master per class/subject/session
- `slb_topics` — Topic hierarchy (chapters/units/lessons)
- `slb_lesson_plans` — Lesson planning per teacher/class
- `slb_competencies` — Competency framework (Bloom's Taxonomy mapped)
- `slb_cognitive_skills` — Cognitive skill levels

---

### 6.4 Question Bank (qns_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/10-Question_Bank/`

Key tables:
- `qns_questions` — Question master with versioning
- `qns_question_pools` — Grouped question sets
- `qns_question_tags` — Tagging and categorization
- `qns_question_topic_jnt` — Question ↔ Syllabus topic linking

**Question Type Support:** MCQ, Short Answer, Long Answer, True/False, Fill-in-the-blank

---

### 6.5 LMS — Homework (lms_ prefix) — 80% Complete
**Directory:** `2-Tenant_Modules/16-LMS/2-LMS_Homework/`

Key tables:
- Homework creation, assignment per class/section/student
- Submission tracking per student
- Teacher review and marks

---

### 6.6 LMS — Quiz & Quest (quz_ prefix) — 80% Complete
**Directory:** `2-Tenant_Modules/16-LMS/3-LMS_Quiz/`
**Files:** `LMS_Quiz_ddl_v1.sql`, `LMS_Quiz_ddl_v2.sql`

Key tables:
- `quz_quizzes` — Quiz master
- `quz_quiz_questions_jnt` — Quiz ↔ Questions mapping
- `quz_attempts` — Student attempt records
- `quz_attempt_answers` — Per-question answers

**Conditions file:** `LMS_Quiz_Conditions.md` — Documents quiz business logic

---

### 6.7 LMS — Exam (exm_ prefix) — 80% Complete
**Directory:** `2-Tenant_Modules/16-LMS/5-LMS_Exam/`
**Versions:** v1 → v5 (5 iterations showing evolution)

Key tables:
- `exm_exams` — Exam master (online/offline types)
- `exm_exam_questions_jnt` — Exam ↔ Question paper setup
- `exm_marking_schemes` — Marking/grading schemes
- `exm_results` — Final result records
- `exm_result_items` — Subject-wise result details
- `exm_grading` — Grade boundaries (A+, A, B, etc.)

**Design Docs:** `LMS_Exam_Architecture_Overview.mmd`, `LMS_Exam_Data_Dictionary.md`

---

### 6.8 HPC — Holistic Report Card (hpc_ prefix) — 80% Complete
**Directory:** `2-Tenant_Modules/14-HPC/DDL/`
**Files:** `Template_HPC_ddl_v2.sql` (active), `Template_HPC_ddl.sql` (v1)

#### Template Layer (Design-time):
```
hpc_templates
    └── hpc_template_parts          (Pages/sections of report)
            ├── hpc_template_parts_items     (Items in a part)
            └── hpc_template_sections        (Sections within a part)
                    ├── hpc_template_section_items   (Text/Image/Table items)
                    │       └── hpc_template_section_table  (Table cells)
                    └── hpc_template_rubrics         (Assessment rubrics)
                            └── hpc_template_rubric_items   (Rubric levels)
```

**Rubric Item Types:** Descriptor, Numeric, Grade, Text, Boolean, Image, Json
**Applicable to:** Grade-wise via JSON field (BV1, BV2, Nur, LKG, UKG, 1-12)

#### Report Layer (Execution-time):
```
hpc_reports             (One per student per term per session)
    └── hpc_report_items        (All rubric responses — input + output values)
    └── hpc_report_table        (Table-type section data)
```

**Report Status Flow:** Draft → Final → Published → Archived
**NEP 2020 Compliance:** Competency-based assessment via rubrics, not just marks
**CRITICAL ISSUE:** `hpc_reports` references `cbse_terms` — board-specific; needs abstraction for ICSE

---

### 6.9 Event Engine / Rule Engine (sys_event_ prefix) — 20% Complete
**Directory:** `2-Tenant_Modules/2-Event_Engine/`

#### Schema (v2 — Production Ready):
```
sys_event_type          — Categorize events (e.g., "LMS Event", "Finance Event")
sys_trigger_event       — Specific triggers with JSON event_logic
sys_action_type         — Available actions with JSON action_logic + required_parameters
sys_rule_engine_config  — Core rule: trigger + conditions (logic_config JSON) + priority
    └── sys_rule_action_map     — Multiple actions per rule (with execution_order)
sys_rule_execution_log  — Audit log: every rule execution (SUCCESS/FAILED/SKIPPED)
```

#### v1 vs v2 Key Differences:
| Feature | v1 | v2 |
|---------|----|----|
| Table Prefix | `lms_` (LMS-only) | `sys_` (all modules) |
| Actions per rule | 1 | Multiple (sys_rule_action_map) |
| Priority control | No | Yes (priority + stop_further_execution) |
| AI support | No | Yes (ai_enabled + ai_confidence_score) |

#### Seeded Trigger Events:
- `ON_QUIZ_COMPLETION`, `ON_HOMEWORK_OVERDUE`, `ON_HOMEWORK_SUBMISSION`

#### Seeded Action Types:
- `AUTO_ASSIGN_REMEDIAL`, `NOTIFY_PARENT`

#### Laravel Implementation Pattern (5 Layers):
```
EventSource (Service Layer)
    → RuleEngineDispatcher::trigger(eventCode, context)
        → Load sys_trigger_event by code
        → Load sys_rule_engine_config (ordered by priority ASC)
            → RuleEvaluator::evaluate(rule, context)
                → ConditionResolver::match(condition, context)  ← Generic JSON conditions
                    → ActionExecutor::execute(actionCode, context, rule)
                        → Real system action
                        → Log to sys_rule_execution_log
```

**KNOWN ISSUE in v2:** FK constraints reference old v1 table names (`lms_trigger_event`, `lms_rule_engine_config`) — needs correction to `sys_trigger_event`, `sys_rule_engine_config`.

---

### 6.10 Recommendation Engine (rec_ prefix) — 90% Complete
**Directory:** `2-Tenant_Modules/11-Recommendation/`

AI-driven learning recommendations based on student performance data and learning gaps.
ML-ready tables with feature store pattern similar to Transport module.

---

### 6.11 Smart Timetable (tt_ prefix) — 70% In-Progress
**Directory:** `2-Tenant_Modules/8-Smart_Timetable/` (v0 → v7.3)

5 Algorithm Strategies:
- `RECURSIVE` — Backtracking
- `GENETIC` — Genetic algorithm
- `SIMULATED_ANNEALING`
- `TABU_SEARCH`
- `HYBRID` — Combined

Key tables: `tt_config`, `tt_generation_strategy`, `tt_shift`, constraint tables

---

### 6.12 Transport (tpt_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/4-Transport/` (~50+ tables)

Areas: Vehicle mgmt, Driver/helper profiles (license), Route & pickup points, Shifts,
Driver-route-vehicle scheduling, GPS trip logs, Fuel logs, Maintenance logs,
Student bus attendance, ML feature store + recommendations

---

### 6.13 Vendor Management (vnd_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/5-Vendor_Mgmt/`

Key tables: `vnd_vendors`, `vnd_items` (HSN-SAC codes), `vnd_agreements`,
`vnd_agreement_items_jnt` (FIXED/PER_UNIT/HYBRID billing), 4-tax support per item

---

### 6.14 Complaint & Grievance (cmp_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/6-Complaint/`

Sophisticated 5-level SLA & escalation: `cmp_complaint_categories` (hierarchical),
`cmp_department_sla` (L1-L5 escalation), `cmp_complaints`, severity levels,
medical check flags, full audit trail per action

---

### 6.15 Library (lib_ prefix) — 100% Complete
**Directory:** `2-Tenant_Modules/18-Library/`

Tables: `lib_books` (ISBN), `lib_book_copies` (shelf location), `lib_circulation`,
`lib_fines`, `lib_reservations`

---

### 6.16 Student Fees (fin_ prefix) — 90% Almost Done
**Directory:** `2-Tenant_Modules/19-Student_Fees_Module/`

Fee structure per class/category/session, collection tracking, concessions, fines

---

### 6.17 Accounting — Schema Ready, Integration Pending
**Directory:** `2-Tenant_Modules/20-Accounting/DDL/`
**File:** `Accounting_ddl_v1.sql` (641 lines — comprehensive, 8 parts)

#### 8 Parts:
```
Part 1: Core Accounting
    account_groups, ledgers, ledger_mappings (source_module: Fees/Library/Transport/HR/Vendor)
    fiscal_years, journal_entries, journal_entry_lines, recurring_journal_templates

Part 2: Fee Management
    fee_heads, fee_structures, fee_structure_lines, discount_types, student_fee_concessions

Part 3: Invoices & Transactions
    tax_rates (CGST/SGST/IGST/Cess), sales_invoices, purchase_invoices,
    invoice_tax_lines, invoice_lines, payment_transactions, receipts

Part 4: Budgeting
    cost_centers, budgets (per fiscal_year / cost_center / ledger)

Part 5: Expense Claims
    expense_claims (Draft→Submitted→Approved→Paid), expense_claim_lines

Part 6: Bank Reconciliation
    bank_reconciliations, reconciliation_matches

Part 7: Fixed Assets
    asset_categories (SLM/WDV depreciation), fixed_assets, depreciation_entries

Part 8: Tally Integration
    tally_export_logs (Ledgers/Journal_Vouchers/Inventory export)
```

**ISSUE:** Tables have no `acc_` prefix — will collide with other tables. Must prefix before integration.
**ISSUE:** `fee_heads`, `fee_structures` in accounting overlap with existing `fin_` module. Needs reconciliation.

---

## 7. PENDING MODULES — STATUS & NOTES

| Module | Status | Schema Exists? | Recommended Prefix | Notes |
|--------|--------|----------------|--------------------|-------|
| Behavioral Assessment | Pending | No | `beh_` | Link to hpc_ for report card |
| Analytical Reports | Pending | No | View layer | Materialized views/snapshots |
| Student & Parent Portal | Pending | No | API layer | Read-only view of existing data |
| HR & Payroll | Pending | No | `hr_` | PF/ESI/TDS Indian compliance |
| Inventory Management | Pending | No | `inv_` | Link to vnd_vendors for PO |
| Hostel Management | Pending | No | `hos_` | Extend infra_ rooms |
| Mess/Canteen | Pending | No | `mes_` | Meal subscriptions + tokens |
| Admission Enquiry | Pending | No | `adm_` | Lead → Application → Offer |
| Visitor Management | Pending | Partial (fnt_) | `vis_` | Extend frontdesk module |
| Template & Certificate | Pending | No | `tpl_` | PDF generation |
| Help Desk & Support | Partial | No | `hlp_` | Doc/video management |
| Register App Bug | Pending | No | `bug_` | Simple feedback tables |

---

## 8. KEY DESIGN PATTERNS

### Pattern 1: Soft Deletes (Universal)
```sql
is_active   TINYINT(1) NOT NULL DEFAULT 1
deleted_at  TIMESTAMP NULL DEFAULT NULL
-- Never hard-delete — always soft-delete
```

### Pattern 2: Polymorphic Relationships
Used in: `sys_media`, `sys_model_has_roles_jnt`, `sys_model_has_permissions_jnt`, `glb_translations`
```sql
model_type VARCHAR(255)   -- PHP Model class name (App\Models\Student)
model_id   BIGINT UNSIGNED -- Record ID
```

### Pattern 3: Generated Columns for Nullable Unique Flags
```sql
super_admin_flag TINYINT(1) GENERATED ALWAYS AS (IF(is_super_admin=1, 1, NULL)) STORED,
UNIQUE KEY uq_super_admin (super_admin_flag)
-- Allows only ONE super_admin=1 row while allowing multiple NULL rows
```

### Pattern 4: JSON for Flexible Configuration
Used in: Event Engine (logic_config, event_logic, action_logic), Timetable (algorithm params),
HPC (applicable_to_grade), Transport ML (feature payloads)

### Pattern 5: Audit Trail via sys_activity_logs
```sql
subject_type, subject_id  -- What changed (polymorphic)
user_id                   -- Who changed
event                     -- What happened (created/updated/deleted)
properties                -- Before/after values (JSON diff)
ip_address, user_agent    -- From where
```

### Pattern 6: Multi-Tax Support
- Billing rates: 4 tax types (tax1% → tax4% each with percent + amount + remark)
- Accounting: GST structure (CGST/SGST/IGST/Cess)
- Default currency: INR

### Pattern 7: Hierarchical Self-Reference
Used in: `glb_menus`, `glb_modules`, `cmp_complaint_categories`, `account_groups`
```sql
parent_id INT UNSIGNED NULL REFERENCES same_table(id)
```

### Pattern 8: Versioned Development
Multiple SQL file versions track schema evolution:
- LMS Exam: v1 → v5 (5 iterations)
- Smart Timetable: v0 → v7.3 (8 iterations)
- HPC: v1 → v2 (2 iterations)
- Event Engine: v1 → v2 (2 iterations)

---

## 9. CRITICAL ISSUES FOUND

| # | Issue | File | Impact | Fix |
|---|-------|------|--------|-----|
| 1 | Event Engine v2 FK references old v1 table names (`lms_trigger_event`, `lms_rule_engine_config`) | `2-Event_Engine/lms_rule_engine_v2.sql` | Breaks if v1 tables removed | Update FK names to `sys_trigger_event`, `sys_rule_engine_config` |
| 2 | HPC references `cbse_terms` (board-specific) | `14-HPC/DDL/Template_HPC_ddl_v2.sql:202` | ICSE schools break | Abstract to `sch_academic_terms` + board tag on template |
| 3 | Accounting tables missing `acc_` prefix | `20-Accounting/DDL/Accounting_ddl_v1.sql` | Name collision risk | Add `acc_` prefix before integration |
| 4 | Accounting fee tables overlap with `fin_` module | `Accounting_ddl_v1.sql` (fee_heads, fee_structures) | Duplicate functionality | Decide: merge or clear boundary |

---

## 10. PERFORMANCE CONSIDERATIONS

### High-Growth Tables (Partition Candidates)
| Table | Growth Rate | Suggested Partition Key |
|-------|-------------|------------------------|
| `sys_activity_logs` | Very High | Monthly (created_at) |
| `exm_attempt_details` | High | academic_session_id |
| `quz_attempt_answers` | High | academic_session_id |
| `tpt_trip_logs` | High | Monthly date |
| `sys_rule_execution_log` | High | Monthly |

### Critical Missing Indexes
```sql
ADD INDEX idx_std_session_class (academic_session_id, class_id, is_active);
ADD INDEX idx_exm_student_status (student_id, status, deleted_at);
ADD INDEX idx_fin_student_payment (student_id, due_date, payment_status);
ADD INDEX idx_rule_trigger_active (trigger_event_id, is_active, priority);
```

### Caching Strategy (Redis)
- Dropdown values + school config → 1hr TTL
- Timetable display → Invalidate on publish
- Dashboard aggregate counts → 15min TTL
- Module permissions per tenant → Per-session

---

## 11. BOARD COMPLIANCE STRATEGY

### CBSE (Primary Target)
- NEP 2020 Competency-Based Assessment → HPC module
- Term 1 + Term 2 → `sch_academic_terms`
- CCE → Exam + HPC
- UDISE code → School profile

### ICSE (Secondary Target)
- Single annual exam + internal assessment
- Different marking schemes from CBSE
- Impact on HPC templates

### Recommended Multi-Board Fix
```sql
-- Add board_id to HPC template for multi-board support
ALTER TABLE hpc_templates ADD COLUMN board_id INT UNSIGNED NULL;
-- NULL = applicable to all boards
-- Filter templates by school's board_id when generating reports
```

---

## 12. CLOUD DEPLOYMENT RECOMMENDATIONS

```
AWS RDS Aurora MySQL 8.x (Multi-AZ)
    ├── Primary (R/W) — Application queries
    └── Read Replica — Reports, analytics

AWS ElastiCache Redis
    ├── Laravel Sessions
    ├── Cache (permissions, config, timetable)
    └── Queue backend (Laravel Horizon)

AWS S3 + CloudFront
    ├── sys_media files
    ├── HPC report PDFs
    └── Static assets CDN

Laravel Horizon → Async jobs:
    ├── Rule Engine execution
    ├── Report generation
    ├── Bulk notifications
    └── Timetable algorithm runs
```

---

## 13. RECOMMENDED MODULE COMPLETION ORDER

```
Phase 1 — Foundation (Immediate)
├── Event Engine         (20% → 100%) — Fix FK issues + complete Laravel integration
├── Behavioral Assessment (0% → 100%) — Required for HPC completion
└── HPC Fix/Complete     (80% → 100%) — Fix cbse_terms + board abstraction

Phase 2 — Revenue Critical
├── Accounting           (Schema ready → Integrate) — Fix prefix + fin_ overlap
├── Analytical Reports   (0% → 100%)
└── Student/Parent Portal (0% → 100%)

Phase 3 — Operations
├── Admission Enquiry    (0% → 100%)
├── HR & Payroll         (0% → 100%)
└── Inventory Mgmt       (0% → 100%)

Phase 4 — Extended Services
├── Hostel Management    (0% → 100%)
├── Mess/Canteen         (0% → 100%)
└── Visitor Management   (Partial → 100%)

Phase 5 — Support & Utility
├── Template & Certificate
├── Help Desk & Support
└── Register App Bug
```

---

## 14. FILE STRUCTURE MAP

```
databases/
├── 0-Policies/
├── 1-master_dbs/
│   ├── 1-DDL_schema/
│   │   ├── global_db.sql     (189 lines)
│   │   ├── prime_db.sql      (645 lines)
│   │   └── tenant_db.sql     (4,219 lines) ← MAIN SCHEMA
│   ├── 2-Data_Scripts/
│   └── 3-Config_Tables/
├── 2-Prime_Modules/
│   ├── 1-Core_Config/
│   ├── 2-Billing_Module/
│   └── 2-Foundation_Setup/
├── 2-Tenant_Modules/
│   ├── 1-Foundation_Setup/
│   ├── 2-Event_Engine/       ← Rule Engine (v1+v2 SQL + implementation docs)
│   ├── 3-School_Setup/       ← Classes, Sections, Infra
│   ├── 4-Transport/          ← ~50+ tables, fully complete
│   ├── 5-Vendor_Mgmt/
│   ├── 6-Complaint/          ← SLA + 5-level escalation
│   ├── 7-Notification/
│   ├── 8-Smart_Timetable/    ← v0 to v7.3, 5 AI algorithms
│   ├── 8-Standard_Timetable/
│   ├── 9-Syllabus/
│   ├── 10-Question_Bank/
│   ├── 11-Recommendation/
│   ├── 12-Syllabus_Books/
│   ├── 13-StudentProfile/
│   ├── 14-HPC/               ← NEP 2020, template+rubrics design
│   ├── 15-Frontdesk_mgmt/
│   ├── 16-LMS/               ← Homework, Quiz, Quest, Exam (v1-v5)
│   ├── 17-LXP/
│   ├── 18-Library/
│   ├── 19-Student_Fees_Module/
│   ├── 20-Accounting/        ← Full accounting DDL (pending integration)
│   ├── Y_Pending_to_Place/
│   └── Z_Work-In-Progress/
└── Working/
    ├── 0-Claude_workspace/   ← THIS FILE
    │   └── DB_Schema_Understanding.md
    └── 1-Prompts/
```

---
*This document represents Claude's complete understanding of the Prime-AI database schema as of March 2026.*
*Update this file after major schema changes.*
