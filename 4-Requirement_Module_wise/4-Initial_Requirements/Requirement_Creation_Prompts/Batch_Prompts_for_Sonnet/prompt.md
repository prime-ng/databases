{{> templates/prompt-header.md}}

# Task: Generate Software Requirements Specification (SRS) — Batch {{batch.number}} of {{batch.total}}

> **BATCHED EXECUTION NOTICE**
> This prompt processes ONE BATCH of modules at a time to ensure complete, high-quality output.
> Batch {{batch.number}} covers: **{{batch.module_names}}**
> Do NOT generate content for any modules outside this batch.
> Output file: `srs-batch-{{batch.number}}.md`

---

## Input: RBS Extract for This Batch

The following RBS data covers ONLY the modules assigned to this batch:

{{input:batch:rbs_extract}}

---

## Instructions

Convert the RBS extract above into a comprehensive SRS for ONLY the modules listed in this batch.
Produce every section below in full — do not abbreviate, summarise, or skip any section.

---

### SECTION A — PER-MODULE REQUIREMENTS
*(Repeat the full block below for EACH module in this batch)*

---

#### MODULE: {{module.name}} (`{{module.code}}`)

**Module Description:** {{module.description}}
**Table Prefix:** `{{module.table_prefix}}`
**Depends On:** {{module.depends_on}}

---

##### A1. Functional Requirements

List every functional capability this module must provide.
Use unique IDs in the format `FR-{{module.code}}-NNN` (zero-padded to 3 digits).

Rules:
- Each requirement must be **atomic** (one behaviour per ID)
- Each requirement must be **testable** (can be verified pass/fail)
- Each requirement must be **unambiguous** (no "should", "may" — use "must" or "shall")
- Cover all CRUD operations, workflows, state transitions, calculations, integrations
- Aim for completeness — missing FRs here cause gaps in all downstream documents

Format:

| ID | Requirement | Priority (Must/Should/Could) | Notes |
|----|-------------|------------------------------|-------|
| FR-{{module.code}}-001 | The system must ... | Must | |

---

##### A2. Non-Functional Requirements

Use IDs in the format `NFR-{{module.code}}-NNN`.

Cover ALL of these sub-categories:

**Performance**
- Page load / API response time targets
- Maximum concurrent users for this module
- Bulk operation limits (e.g., import 5000 students)

**Security**
- Data isolation (tenant scoping rules specific to this module)
- Field-level sensitivity (PII, financial data, health records)
- RBAC enforcement at the API layer

**Scalability**
- Data volume upper bounds (rows per table at scale)
- Query performance requirements at scale

**Availability**
- Uptime target
- Acceptable maintenance window impact

**Compliance**
- NEP 2020 alignment (specific clauses where applicable)
- CBSE / ICSE / State board regulatory requirements
- RBI / GST compliance where fees or financial data are involved
- DPDP Act 2023 (Digital Personal Data Protection) considerations

Format:

| ID | Category | Requirement | Target / Measure |
|----|----------|-------------|-----------------|
| NFR-{{module.code}}-001 | Performance | API response time for list endpoints | < 500ms at p95 |

---

##### A3. User Stories

For EVERY role that interacts with this module, generate user stories.
Roles to consider: {{config.roles}}
Only include roles that have a real interaction with this module — skip irrelevant roles.

Format per story:

**Story ID:** US-{{module.code}}-NNN
**Role:** [Role name]
**Story:** As a [role], I want [action], so that [benefit].

**Acceptance Criteria:**
- **Given** [precondition]
- **When** [action is performed]
- **Then** [expected outcome]
- **And** [additional assertion if needed]

**Priority:** Must Have / Should Have / Could Have
**Linked FRs:** FR-{{module.code}}-NNN, FR-{{module.code}}-NNN

Generate at minimum:
- 3 stories per primary role
- 1–2 stories per secondary role
- Cover both happy path and key error/edge cases

---

##### A4. Business Rules

List all rules governing this module's domain logic.
Use IDs in the format `BR-{{module.code}}-NNN`.

Include:
- Validation rules (what values are allowed, forbidden, conditional)
- Calculation rules (formulas, rounding, tax logic, percentages)
- State transition rules (what states exist, which transitions are legal)
- Constraint rules (uniqueness, capacity limits, date ordering)
- Dependency rules (what must exist before this record can be created/modified)
- Override rules (who can override defaults, what approvals are needed)

Format:

| ID | Rule | Applies To | Enforcement Level |
|----|------|-----------|------------------|
| BR-{{module.code}}-001 | A fee concession cannot exceed 100% of the original fee amount | Fee Concession | Hard constraint — reject at API |

---

##### A5. Data Requirements

List every entity this module owns or primarily manages.

For each entity:

**Entity Name:** [e.g., FeeInstallment]
**Owns/Manages:** Owns
**Key Attributes:** id, tenant_id, student_id, fee_head_id, amount, due_date, paid_date, status, created_by, updated_by, deleted_at
**Relationships:**
  - belongs to: Student (cross-module ref)
  - belongs to: FeeHead (same module)
  - has many: FeePayments (same module)
**CRUD Operations by This Module:** Create, Read, Update, Soft Delete
**Read by Other Modules:** [list modules that read this data]
**Data Retention Policy:** Retain for 7 years (financial record)

Also list cross-module data this module READS but does not own:

| Entity | Owned By Module | How This Module Uses It |
|--------|----------------|------------------------|
| Student | Student Management | Link fees to enrolled students |

---

##### A6. NEP 2020 & Indian Education Compliance

Where applicable, describe how this module supports:
- NEP 2020 holistic assessment guidelines
- Continuous and Comprehensive Evaluation (CCE) requirements
- Multi-lingual support requirements
- Inclusive education requirements (CWSN — Children with Special Needs)
- Board-specific marking / grading schemes (CBSE, ICSE, State boards)
- RTE Act compliance (Right to Education — free seats, fee structure limits)

If this module has no compliance requirements, state "No specific regulatory requirements for this module."

---

*(End of per-module block — repeat A1–A6 for each module in this batch)*

---

### SECTION B — CROSS-CUTTING SECTIONS
*(Generate ONCE per batch, covering only modules in this batch)*

---

#### B1. Multi-Tenancy Requirements for This Batch

For EACH module in this batch, explicitly state:

| Module | Tenant Isolation Method | Cross-Tenant Risk Areas | Isolation Verification |
|--------|------------------------|------------------------|----------------------|
| [module] | All queries scoped by `{{config.database.tenant_id_column}}` via TenantScope trait | [identify any shared resources or risks] | [how isolation is tested] |

Additional requirements:
- Tenant provisioning steps specific to these modules (tables to seed, configs to init)
- Any global_db records these modules create (e.g., plan feature flags)
- Cross-tenant data prohibition — list any aggregate/reporting queries that must never leak tenant data

---

#### B2. Role-Permission Matrix — This Batch's Modules

Generate a complete matrix for ONLY the modules in this batch.

Columns: Role | Module | Create | Read | Update | Delete | Special Actions

Use: ✅ = Allowed | ❌ = Denied | 🔒 = Own records only | 👁 = Read-only | ⚙️ = Configurable via RBAC

Roles to cover: {{config.roles}}

Special Actions column: list any non-CRUD actions (e.g., Approve, Reject, Export PDF, Bulk Import, Override, Publish, Archive).

---

#### B3. Traceability Matrix — This Batch

Map every FR and NFR generated in this batch back to its source RBS line item.

| Requirement ID | Requirement Summary | RBS Section | RBS Line / Feature | Notes |
|---------------|--------------------|--------------|--------------------|-------|
| FR-{{module.code}}-001 | [summary] | [RBS section heading] | [RBS line item text] | [any interpretation note] |

Every FR and NFR must appear in this matrix. If a requirement was inferred (not explicitly in RBS) mark it as `[INFERRED]` in the Notes column.

---

#### B4. Data Volume Assumptions — This Batch

For each module in this batch, state the expected data volumes that will influence database design and performance planning:

| Module | Entity | Expected Rows/Tenant (Year 1) | Expected Rows/Tenant (Year 5) | Growth Pattern |
|--------|--------|------------------------------|------------------------------|---------------|
| [module] | [entity] | [number] | [number] | [linear / seasonal / archival] |

Global platform assumptions:
- Expected tenants at launch: {{config.volumes.tenants_launch}}
- Expected tenants at scale: {{config.volumes.tenants_scale}}
- Students per tenant (typical): {{config.volumes.students_per_tenant}}
- Staff per tenant (typical): {{config.volumes.staff_per_tenant}}
- Concurrent users per tenant (peak): {{config.volumes.concurrent_users_peak}}

---

## Output Format

- **File name:** `srs-batch-{{batch.number}}.md`
- Use H1 (`#`) for module names within the file
- Use H2 (`##`) for section headings (A1, A2 … B4)
- Use H3 (`###`) for sub-headings within sections
- All tables must be valid GitHub-Flavoured Markdown tables
- All requirement IDs must be unique within this batch — no duplicates
- Include a **Table of Contents** at the very top listing every module and section
- Include a **Batch Summary** at the very bottom:
  ```
  ## Batch Summary
  - Batch Number: {{batch.number}} of {{batch.total}}
  - Modules Covered: {{batch.module_names}}
  - Total FRs Generated: [count]
  - Total NFRs Generated: [count]
  - Total User Stories Generated: [count]
  - Total Business Rules Generated: [count]
  - Next Batch: {{batch.next_description}}
  ```

---

## Quality Checklist

Before finishing, verify:
- [ ] Every module listed in `{{batch.module_names}}` has sections A1–A6
- [ ] Every FR/NFR/BR/US ID is unique within this file
- [ ] Every user story has at least one Given/When/Then acceptance criteria block
- [ ] The Role-Permission Matrix (B2) covers every role in `{{config.roles}}`
- [ ] The Traceability Matrix (B3) has an entry for every FR and NFR
- [ ] No content references modules outside this batch
- [ ] Batch Summary at the bottom is filled in with accurate counts
