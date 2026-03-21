# Phase 1 — Requirements (No Wireframes Needed)
================================================

## CONFIGURATION
----------------
MODULE_CODE       = ACC                    # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
MODULE            = Accounting             # Used in: issue codes (BUG-HPC-001), section headers, AI Brain lookups
MODULE_DIR        = Modules/Accounting/    # Used in: file paths (Modules/Hpc/), git commands
BRANCH            = Brijesh_Accounting     # Used in: context for the prompt
DEVELOPER         = Brijesh                 # Used in: context for the prompt
RBS_MODULE_CODE   = K
DB_TABLE_PREFIX   = acc_
DATABASE_NAME     = tenant_db
DATE              = 20th Mar 2026         # Used in: git --since filter (Tier 3)


## What YOU Provide

You only need to give Claude **three things**:

1. **Module name + description** (1-2 sentences)
2. **RBS reference** — point to the relevant section in `PrimeAI_RBS_Menu_Mapping_v2.0.md`
3. **Business rules** — what special logic applies (optional — Claude can suggest defaults)

That's it. No wireframes. No field lists. No screen layouts.

### Prompt 1A — Generate Feature Specification from RBS

```
## Generate Feature Specification from RBS

Read these files:
1. `3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md` — find Module [X] section
2. `database/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement_v4.md` - Requirement for Accounting Module
3. `AI_Brain/memory/project-context.md` — project context
4. `AI_Brain/memory/modules-map.md` — existing modules (to avoid duplication)
5. `AI_Brain/agents/business-analyst.md` — follow the BA agent instructions

**Module:** {MODULE}
**RBS Module Code:** {RBS_MODULE_CODE} (e.g., O for Hostel, K for Accounting)
**Table Prefix:** {DB_TABLE_PREFIX} (e.g., hos_, acc_)
**Database:** {DATABASE_NAME}
**Description:** [The Accounting module implements a **Tally-Prime inspired double-entry bookkeeping system** for Indian K-12 schools. Every financial transaction (fee collection, salary payment, stock purchase, transport fee, expense) flows through a unified **Voucher Engine** as Dr/Cr pairs, ensuring the accounting equation (Assets = Liabilities + Equity) always holds.]

**Additional business rules (if any):**
- Read `databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Account_Requirement_v4.md` & `databases/1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md` toget complete detail about the Module.


**I do NOT have wireframes.** Generate the feature specification based purely on:
- Initial_Plan_v4.md
- Account_Requirement_v4.md
- The RBS sub-tasks for this module
- Indian K-12 school domain knowledge
- Patterns from similar existing modules in Prime-AI

Generate:
1. **Entity list** — all tables needed with columns, types, relationships
2. **Entity Relationship Diagram** (text-based)
3. **Business rules** — validation rules, cascade behaviors, status workflows
4. **Permission list** — all Gate permissions needed
5. **Dependencies** — which existing modules this connects to

Do NOT generate screen layouts yet — that comes in Phase 3 after DDL review.

Store output in: `3-Project_Planning/3-Feature_Specs/[MODULE_NAME]_FeatureSpec.md`
```

### Quality Gate 1
- [ ] Every RBS sub-task maps to at least one entity/column
- [ ] All entity relationships (FK) are defined
- [ ] Table names use correct prefix convention
- [ ] Business rules are documented
