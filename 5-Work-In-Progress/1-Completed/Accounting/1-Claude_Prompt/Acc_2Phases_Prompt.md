# ACC — Accounting Module Development Lifecycle Prompt

**Purpose:** This is a single consolidated prompt to build the "Feature Specification" & "Database Schema Design" for Accounting module for Prime-AI. Paste this into Claude and work through each phase sequentially. Claude will stop after each phase for your review and confirmation.

**Date:** 2026-03-20
**Developer:** Brijesh | **Branch:** Brijesh_Finance

---

## CONFIGURATION (Referenced throughout all phases)

```
MODULE_CODE       = ACC
MODULE            = Accounting
MODULE_DIR        = Modules/Accounting/
APP_REPO          = prime_ai_tarun
BRANCH            = Brijesh_Finance
DEVELOPER         = Brijesh
RBS_MODULE_CODE   = K
DB_TABLE_PREFIX   = acc_
DATABASE_NAME     = tenant_db
OUTPUT_DIR        = databases/5-Work-In-Progress/20-Accounting/DDL
MIGRATION_DIR     = prime_ai_tarun/database/migrations/tenant
REQUIREMENT_FILE  = databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement_v4.md
PLAN_FILE         = databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md
RBS_FILE          = 3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
FEATURE_SPEC_DIR  = databases/5-Work-In-Progress/20-Accounting/2-Claude_Plan/3-Feature_Specs
DDL_DIR           = databases/1-DDL_Tenant_Modules/20-Account/DDL
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Tell Claude: **"Start Phase 1"**
3. Claude will read the required files, generate the output, and STOP
4. You review the output, give feedback or confirm: **"Approved. Proceed to Phase 2"**
5. Repeat for all 9 phases
6. For Phase 3 (Screen Planning): YOU provide your layout decisions, then Claude confirms

**Estimated total time:** ~5 working days

---

## PHASE 1 — Requirements & Feature Specification
### Phase 1 Input Files
Read these files BEFORE generating output:
1. `{REQUIREMENT_FILE}` — Complete Accounting module requirement (v4)
2. `{PLAN_FILE}` — Initial plan with architecture and table summary
3. `{RBS_FILE}` — Find Module K section (line 2844)
4. `AI_Brain/memory/project-context.md` — Project context
5. `AI_Brain/memory/modules-map.md` — Existing modules (avoid duplication)
6. `AI_Brain/agents/business-analyst.md` — BA agent instructions

### Phase 1 Task
Generate a comprehensive Feature Specification for the Accounting module.

**Module:** Accounting
**RBS Module Code:** K (Finance & Accounting — 70 sub-tasks)
**Table Prefix:** acc_
**Database:** tenant_db
**Description:** Tally-Prime inspired double-entry bookkeeping system for Indian K-12 schools. Voucher Engine as central nervous system — every transaction flows through acc_vouchers + acc_voucher_items as Dr/Cr pairs.

**No wireframes.** Generate the feature specification from:
- Account_Requirement_v4.md (21 tables, 18 controllers, 9 services)
- Initial_Plan_v4.md (architecture, integration points)
- RBS Module K sub-tasks (K1-K13, 70 sub-tasks)
- Indian K-12 school domain knowledge
- Patterns from existing Prime-AI modules

**Generate:**
1. Entity list — all 21 tables with columns, types, relationships
2. Entity Relationship Diagram (text-based)
3. Business rules — validation rules, cascade behaviors, status workflows
4. Permission list — all Gate permissions needed (accounting.resource.action format)
5. Dependencies — which existing modules this connects to
6. Integration events — StudentFee, Transport, Payroll, Inventory events

Do NOT generate screen layouts yet — that comes in Phase 3.

### Phase 1 Output Files
| File | Location |
|------|----------|
| `ACC_FeatureSpec.md` | `{FEATURE_SPEC_DIR}/ACC_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] Every RBS sub-task (K1-K13) maps to at least one entity/column
- [ ] All 21 table relationships (FK) are defined
- [ ] Table names use `acc_` prefix convention
- [ ] Business rules documented (double-entry balance, FY locking, voucher numbering, etc.)
- [ ] All cross-module integration events listed

**After completing Phase 1, STOP and say:** "Phase 1 (Feature Specification) complete. Output: `ACC_FeatureSpec.md`. Please review and confirm to proceed to Phase 2 (DDL Design)."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)
### Phase 2 Input Files
1. `{FEATURE_SPEC_DIR}/ACC_FeatureSpec.md` — Feature spec from Phase 1
2. `{REQUIREMENT_FILE}` — Table schemas (Section 4)
3. `AI_Brain/agents/db-architect.md` — DB Architect agent instructions
4. `databases/0-DDL_Masters/tenant_db_v2.sql` — Existing schema for reference (old acc_* will be replaced)

### Phase 2A Task — Generate DDL
Generate the DDL SQL for all 21 tables in the Accounting module.

**Rules (MUST follow):**
1. Table prefix: `acc_`
2. Every table MUST have: `id` (BIGINT UNSIGNED AUTO_INCREMENT), `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`
3. Index ALL foreign keys
4. Junction tables suffix: `_jnt`
5. JSON columns suffix: `_json`
6. Boolean columns prefix: `is_` or `has_`
7. Use `BIGINT UNSIGNED` for all IDs
8. Add `COMMENT` on every column
9. Use InnoDB, utf8mb4_unicode_ci
10. Old acc_* DDL in tenant_db_v2.sql is UNUSED — this is a fresh schema

**Generate:**
1. DDL SQL file — all CREATE TABLE statements with comments
2. Laravel Migration file — for `database/migrations/tenant/`
3. Table summary — one-line description of each table
4. ALTER TABLE for `sch_employees` — add 14 payroll columns

### Phase 2B Task — Generate Seeders
Generate Laravel seeders for:
1. `AccountGroupSeeder` — 32 groups (Tally's 28 + 4 school-specific)
2. `VoucherTypeSeeder` — 10 voucher types with prefixes
3. `TaxRateSeeder` — 5 GST rates (CGST/SGST 9%, IGST 18%, CGST/SGST 2.5%)
4. `CostCenterSeeder` — 10 cost centers (Primary/Middle/Senior Wing, Admin, Transport, etc.)
5. `DefaultLedgerSeeder` — 11 default ledgers (Cash, Petty Cash, GST Payable, etc.)
6. `TallyLedgerMappingSeeder` — ~40 auto-mapped Tally ledger names
7. `AssetCategorySeeder` — 5 categories (Furniture SLM 10%, IT Equipment WDV 40%, etc.)

### Phase 2 Output Files
| File | Location |
|------|----------|
| `ACC_DDL_v1.sql` | `{DDL_DIR}/ACC_DDL_v1.sql` |
| `ACC_Migration.php` | `{OUTPUT_DIR}/ACC_Migration.php` |
| `ACC_SchEmployees_Enhancement.sql` | `{DDL_DIR}/ACC_SchEmployees_Enhancement.sql` |
| `ACC_Seeders/` | `{OUTPUT_DIR}/ACC_Seeders/` (7 seeder files) |
| `ACC_TableSummary.md` | `{OUTPUT_DIR}/ACC_TableSummary.md` |

### Phase 2 Quality Gate
- [ ] All 21 tables from requirement exist in DDL
- [ ] Foreign keys match referenced tables with correct `acc_` prefix
- [ ] Required columns (id, is_active, created_by, timestamps, deleted_at) on ALL tables
- [ ] `acc_vouchers` has source_module + source_type + source_id (polymorphic)
- [ ] `acc_ledgers` has student_id→std_students, employee_id→sch_employees, vendor_id→vnd_vendors
- [ ] sch_employees ALTER TABLE adds 14 columns with Schema::hasColumn() guard