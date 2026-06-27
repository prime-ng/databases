# Prompt: Generate Module-wise FRD (Functional Requirements Document)
## Prime-AI — Non-Technical Business Requirements with Gap Analysis Support

---

## CONFIGURATION VARIABLES

> **No manual config needed.** Claude resolves all three variables automatically from the module list.
> Just tell Claude which module you want: *"create an FRD for Library"* — it does the rest.

```yaml
# --- STEP 0: READ THIS FILE FIRST ---
PATHS_CONFIG   = AI_Brain/config/paths.md   # ← resolves ALL variables below

# --- AUTO-RESOLVED FROM MODULE LIST ---
# Claude reads: {OLD_REPO}/0-Prime_Ai_Detail/module_list.md
# Finds the row matching the module name the user requested.
# Extracts:
MODULE_NAME    = <looked up from module_list.md>
MODULE_CODE    = <looked up from module_list.md>
MODULE_PREFIX  = <looked up from module_list.md>

# --- INPUT FILES (all paths resolved from AI_Brain/config/paths.md) ---
MODULE_LIST           = {OLD_REPO}/0-Prime_Ai_Detail/module_list.md
TECH_REQ_FILE         = {REQUIREMENT_OLD}/{MODULE_CODE}_{MODULE_NAME}_Requirement*.md    # consolidated V2 (1st priority)
PRELIMINARY_REQ_FILE  = {REQUIRE_DETAIL_V1}/{MODULE_NAME}_v*/                            # screen-spec folder (fallback)
CORE_DDL_FILE         = {OLD_REPO}/0-DDL_Masters/tenant_db_v4.sql
DDL_FILE              = {DEV_MODULE_DDL_DIR}/{MODULE_NAME}_DDL*.sql
CODE_PATH             = {LARAVEL_REPO}/Modules/{MODULE_NAME}/
TEST_CASES_FILE       = /Users/bkwork/Herd/prime_testing/tests/Browser/Modules/{MODULE_NAME}/*/*.md
FRD_FILE              = {FRD_DIR}/{MODULE_CODE}_FRD_*.md

# --- OUTPUT ---
OUTPUT_FILE           = {FRD_DIR}/{MODULE_CODE}_FRD_{YYYY-MM-DD}.md
```

---

---

## BEGIN PROMPT
*(Copy everything below this line through "END PROMPT" and paste to Claude)*

```
============================================================
TASK: GENERATE FUNCTIONAL REQUIREMENTS DOCUMENT (FRD)
Module: {MODULE_NAME}  |  Code: {MODULE_CODE}
============================================================

You are a Senior Business Analyst documenting the Prime-AI School ERP platform.
Your task is to generate a complete, non-technical FRD for the {MODULE_NAME} module.

---

STEP 0 — RESOLVE PATHS AND MODULE IDENTIFIERS (ALWAYS FIRST)

0.1 — Read the paths configuration file BEFORE anything else:

  File: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/config/paths.md

  This file is the single source of truth for all folder locations.
  Resolve the following variables from it before proceeding:
    {OLD_REPO}            — root of the working repository
    {REQUIREMENT_OLD}     — path to consolidated V2 requirement files
    {REQUIRE_DETAIL_V1}   — path to detailed per-screen requirement folders
    {DEV_MODULE_DDL_DIR}  — path to per-module DDL files

  Do NOT hardcode paths. Use the values from paths.md so that path changes
  propagate automatically.

0.2 — Resolve module identifiers:

  File: {OLD_REPO}/0-Prime_Ai_Detail/module_list.md

  Find the row where MODULE_NAME matches what the user requested (case-insensitive).
  Extract MODULE_CODE and MODULE_PREFIX from that row.

  Confirm to the user before proceeding:
    "Module identified: {MODULE_NAME} | Code: {MODULE_CODE} | Prefix: {MODULE_PREFIX}"

  If no match is found, list the available module names from the file and ask the user
  to clarify which module they meant. Do NOT proceed until the match is confirmed.

---

STEP 1 — READ THESE FILES IN ORDER

Read all available input files listed below. Use them as context to understand
what the module is supposed to do, what data it manages, and what has already
been built. Do NOT copy-paste from these files — synthesize and rewrite in
plain business language.

  1. Requirement Files — check BOTH formats; use whichever is found:

    1a. Consolidated V2 requirement file (single file — ~35 modules have this):
        {REQUIREMENT_OLD}/{MODULE_CODE}_{MODULE_NAME}_Requirement*.md
        (If found: extract completion %, component counts, gaps, cross-module deps)

    1b. Detailed screen-spec folder (fallback — ~40 modules use this format):
        {REQUIRE_DETAIL_V1}/{MODULE_NAME}_v*/
        Run: ls {REQUIRE_DETAIL_V1}/ | grep -i {MODULE_NAME}  to find the folder.
        Read ALL .md files in the folder (one file per screen).
        (If found: extract screen names, business rules, field detail, workflows)

    NOTE: Some modules have BOTH; some have only one; some have neither.
    If neither found, note it in the FRD and proceed from DDL + code inference.

  2. DDL Schema Files:

    2.1. Foundational DDL (cross-module FK reference tables):
         {OLD_REPO}/0-DDL_Masters/tenant_db_v4.sql
         (Read table and column names to understand shared FK targets.
          Do NOT expose column names in the FRD — translate to business terms)

    2.2. Module-specific DDL file:
         {DEV_MODULE_DDL_DIR}/{MODULE_NAME}_DDL*.sql
         (Read table and column names to understand what data entities exist.
          Do NOT expose column names in the FRD — translate to business terms)

  3. Application Code:
     {LARAVEL_REPO}/Modules/{MODULE_NAME}/
     (Read controllers, models, routes to understand what has been implemented.
      Do NOT expose class names or method signatures in the FRD — translate to
      business terms only)

  4. Test Cases File (if available):
     /Users/bkwork/Herd/prime_testing/tests/Browser/Modules/{MODULE_NAME}/*/*.md

---

STEP 2 — UNDERSTAND THE MODULE BEFORE WRITING

Before generating the FRD, form answers to these questions:
  A. What business problem does this module solve? (in 2 sentences)
  B. Who are the users of this module? (roles: admin, teacher, student, parent, etc.)
  C. What are the 5–10 main things this module must do? (features)
  D. What business rules govern each feature? (conditions, validations, workflows)
  E. What reports/dashboards does this module need to provide?
  F. What does "this module is complete" look like from a business standpoint?

---

STEP 3 — GENERATE THE FRD

Generate the FRD following the exact structure below.
Save it to: {OUTPUT_FILE}

Use these language rules throughout:
  ✅ Write for a Business Analyst — clear, plain English
  ✅ Use business entity names (e.g., "Complaint Ticket", not "cmp_complaints")
  ✅ Use role names (e.g., "School Admin", not "auth()->user()")
  ✅ Express rules as business conditions ("System must send an alert when...")
  ✅ Each requirement gets a unique ID: REQ-{MODULE_CODE}-NNN (starting from 001)
  ✅ Each business rule gets a unique ID: BR-{MODULE_CODE}-NNN (starting from 001)
  ✅ Each enhancement idea gets a unique ID: ENH-{MODULE_CODE}-NNN
  ❌ No PHP, Laravel, SQL, REST, CRUD, API jargon
  ❌ No class names, method names, or technical file paths
  ❌ No implementation status markers (✅/🟡/❌ — these belong in gap analysis, not FRD)


============================================================
FRD TEMPLATE — GENERATE EXACTLY THIS STRUCTURE
============================================================

---

# Functional Requirements Document (FRD)
# Module: {MODULE_NAME}
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | {MODULE_NAME} |
| **Module Code** | {MODULE_CODE} |
| **Document Version** | 1.0 |
| **Date** | {YYYY-MM-DD} |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI |
| **Reviewed By** | (Pending) |
| **Approved By** | (Pending) |

---

## Section 1 — Module Overview

### 1.1 Business Purpose

[2-4 sentences: What real-world problem does this module solve for Indian K-12 schools?
Why does a school need this? What happens if this module doesn't exist?
Write this so a school principal can understand it.]

### 1.2 Business Value

[3-5 bullet points: What concrete benefits does this module deliver?
Examples: reduces manual work, improves accountability, saves time, ensures compliance.]

### 1.3 Scope

#### In Scope
[Numbered list: Everything this module is responsible for managing]

#### Out of Scope
[Numbered list: Things that seem related but are handled by other modules — with module names]

### 1.4 Key Terminology

| Business Term | Meaning |
|---------------|---------|
| [Term 1] | [Plain-English definition as used in this module] |
| [Term 2] | [Plain-English definition] |
[Continue for all domain terms used in this module — minimum 5 terms]

---

## Section 2 — User Roles & Access

### 2.1 Actor Definitions

| Role | Who They Are | Their Relationship to This Module |
|------|-------------|----------------------------------|
| [Role Name] | [Who this person is in a school] | [What they do in this module] |
[List every role that interacts with this module]

### 2.2 Role-Feature Access Matrix

| Feature | [Role 1] | [Role 2] | [Role 3] | [Role 4] |
|---------|----------|----------|----------|----------|
| [Feature Name] | View Only / Full Access / No Access | ... | ... | ... |
[One row per feature, one column per role]

---

## Section 3 — Functional Requirements

[For each major feature of the module, create a subsection following the template below.
Number features as 3.1, 3.2, 3.3... and sub-features as 3.1.1, 3.1.2...]

### 3.X [Feature Name]
**Requirement ID:** REQ-{MODULE_CODE}-NNN
**Priority:** Core (P0) / Standard (P1) / Enhanced (P2)
**Category Tags:** Choose all that apply: [DATA_ENTRY] [WORKFLOW] [REPORT] [NOTIFICATION] [CONFIGURATION] [DASHBOARD] [INTEGRATION] [APPROVAL] [SCHEDULED]

#### Business Description
[3-6 sentences explaining WHAT this feature does in plain business language.
Who initiates it? What happens? What is the end result? Why does the school need it?]

#### Actors
- **Initiates:** [Who triggers this feature]
- **Processes / Approves:** [Who acts on it]
- **Views / Receives notification:** [Who is informed]

#### Business Rules
List every condition, constraint, or validation that governs this feature:

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-{MODULE_CODE}-NNN | [The rule in plain language. E.g., "A complaint ticket cannot be closed unless a resolution note has been entered by the assigned handler."] | Validation / Workflow / Permission / Calculation |
| BR-{MODULE_CODE}-NNN | ... | ... |

#### Acceptance Criteria
This feature is considered complete when:
1. [Specific, testable condition — what the user can do when this is working]
2. [Another condition]
3. [Another condition]
[Minimum 3 acceptance criteria per feature]

#### Integration with Other Modules
[List any other module this feature needs data from or sends data to]
- Receives from: [Module name — what data]
- Sends to: [Module name — what data]
- (Write "None" if fully self-contained)

#### Enhancement Notes (Future)
[Any planned improvements or client-requested features not in current scope.
These become ENH-{MODULE_CODE}-NNN entries in Section 8.]

---

[Repeat Section 3.X for every feature. Typical FRD has 6–15 feature sections.]

---

## Section 4 — Business Rules Register

[Consolidated list of ALL business rules from Section 3, for easy reference and traceability]

| Rule ID | Description | Feature | Rule Type | Priority |
|---------|-------------|---------|-----------|----------|
| BR-{MODULE_CODE}-001 | [Full rule description] | REQ-{MODULE_CODE}-NNN | [Type] | P0/P1/P2 |
[Every rule from Section 3 must appear here]

---

## Section 5 — Data Requirements

[For each major business entity that this module manages, create a subsection.
Do NOT use database table names or column names — use business terms.]

### 5.X [Business Entity Name]
*(Example: "Complaint Ticket", "Category", "Escalation Record")*

**What it represents:** [Plain-English description of this entity]

**Key information captured:**
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| [Business field name] | [What this information means] | Yes/No | [Any rules about it] |
[6–15 rows per entity]

**Relationships:**
- Belongs to: [Other entity name]
- Contains: [Child entity name]
- Connected to: [Related entity name]

**Data Retention:**
[How long should this data be kept? Can it be deleted? What are the archive rules?]

**Privacy Classification:**
[Open / Internal / Confidential / Sensitive]
[Any data that requires special handling — names, medical info, financial data]

---

## Section 6 — Workflows

[For each major multi-step process in this module, define the full flow]

### 6.X [Workflow Name]
*(Example: "Complaint Registration and Assignment Workflow")*

**Trigger:** [What starts this workflow]
**End State:** [What "done" looks like]

#### Steps

1. [Step name]: [Who does what. Plain language.]
   - Decision: If [condition] → go to step N
   - Decision: If [condition] → go to step M

2. [Step name]: [Who does what]
   [Continue...]

#### Exception Paths
- If [exception condition]: [What happens instead]
- If [another exception]: [What happens]

#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| [Step N] | [Role] | [What the notification says — in plain language] |

---

## Section 7 — Reporting & Analytics Requirements

[For each report or dashboard this module must provide]

### 7.X [Report Name]

**Report ID:** RPT-{MODULE_CODE}-NNN
**Purpose:** [Why does the school need this report?]
**Primary Audience:** [Which role uses this most?]
**Frequency of Use:** [Daily / Weekly / Monthly / As-needed]

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| [Column name in business terms] | [What this number/value means] |

#### Filters Available
- By [filter name]: [What the user can select]
- By [filter name]: ...

#### Export Options
- [ ] Print (PDF)
- [ ] Download to Excel
- [ ] On-screen only

#### Business Rules for This Report
| Rule | Description |
|------|-------------|
| [Rule] | [How data is calculated or filtered] |

---

## Section 8 — Future Enhancement Log

[All planned enhancements, client requests, and improvement ideas not in current scope]

| Enhancement ID | Requested Feature | Reason / Business Value | Requested By | Priority | Status |
|----------------|------------------|------------------------|--------------|----------|--------|
| ENH-{MODULE_CODE}-001 | [Feature description] | [Why it matters] | [Who asked] | P1/P2/P3 | Backlog |
[Add all known future requirements here]

---

## Section 9 — Non-Functional Requirements

### 9.1 Performance Expectations
| Requirement | Standard |
|-------------|---------|
| Screen load time | All screens load within 3 seconds for up to 500 concurrent users |
| Report generation | Standard reports complete within 10 seconds |
| Large reports | Reports with 1,000+ rows complete within 30 seconds |
| [Module-specific requirement] | [Standard] |

### 9.2 Security Requirements (Business Language)
| Requirement | Rule |
|-------------|------|
| Access control | Only users with the correct role may access each screen |
| Data isolation | School A's data must never be visible to School B |
| Audit trail | All changes must record who made them and when |
| [Module-specific requirement] | [Rule] |

### 9.3 Usability Requirements
| Requirement | Standard |
|-------------|---------|
| Mobile access | Core screens must work on mobile browsers |
| Language | All labels and messages in English (Hindi/regional as future enhancement) |
| [Module-specific] | [Standard] |

---

## Section 10 — Gap Analysis Readiness Index

[This section makes the FRD machine-readable for gap analysis tools.
Fill this out systematically — it enables the Status_Analyzer and Technical Auditor agents
to measure completion % across 6 dimensions for this module.]

### 10.1 Requirement Coverage Summary

| Requirement ID | Feature Name | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|-------------|---------|------|------------------|---------------|------------|--------------------|--------------------|
| REQ-{MODULE_CODE}-001 | [Feature] | P0/P1/P2 | [Tags] | Yes/No | Yes/No | Yes/No | Yes/No | Yes/No |
[One row per requirement ID from Section 3]

### 10.2 Business Rules Coverage Summary

| Rule ID | Rule Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|-------------|-------------|--------------------|--------------------|---------------|
| BR-{MODULE_CODE}-001 | [Short rule] | REQ-NNN | Yes/No | Yes/No | Yes/No |

### 10.3 Report Coverage Summary

| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|------------|---------|---------------|---------------|
| RPT-{MODULE_CODE}-001 | [Name] | P0/P1/P2 | [N] | Yes/No |

### 10.4 Total Scope Numbers
*(These numbers define the denominator for all completion % calculations)*

| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | [N] |
| Total Business Rules (BR-) | [N] |
| Total Workflows defined | [N] |
| Total Reports required | [N] |
| Total Enhancements logged | [N] |
| Total P0 (Core) Requirements | [N] |
| Total P1 (Standard) Requirements | [N] |
| Total P2 (Enhanced) Requirements | [N] |

---

## Document Control

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | {YYYY-MM-DD} | Initial draft from input file synthesis | Business Analysis — Prime-AI |

---

*This FRD is the single source of truth for {MODULE_NAME} module requirements.*
*All gap analyses, completion scoring, and test coverage must reference this document.*
*For technical implementation details, refer to the corresponding DDL file and Laravel module code.*

============================================================
END OF FRD TEMPLATE
============================================================

---

STEP 4 — QUALITY CHECK BEFORE SAVING

Before saving, verify:
  [ ] Every REQ-{MODULE_CODE}-NNN is unique and sequential
  [ ] Every BR-{MODULE_CODE}-NNN is unique and sequential
  [ ] Section 10.4 totals match actual counts in the document
  [ ] No PHP/SQL/technical jargon appears anywhere in Sections 1–9
  [ ] Every feature in Section 3 appears in the Section 10.1 table
  [ ] Every business rule in Section 3 appears in the Section 4 register
  [ ] Acceptance criteria are testable (can a tester verify each one? YES/NO answer)
  [ ] At least 1 workflow defined in Section 6 for modules with multi-step processes

If any check fails, fix it before saving.

---

STEP 5 — SAVE AND CONFIRM

Save the completed FRD to:
  {OUTPUT_FILE}

Then confirm to me:
  "FRD saved: {OUTPUT_FILE}
   Total requirements: [N] REQ entries | [N] BR entries | [N] Reports
   P0 requirements: [N]  |  P1: [N]  |  P2: [N]
   Ready for gap analysis."

============================================================
END OF PROMPT
============================================================
```

---

---

## HOW THE FRD ENABLES THE SIX GAP ANALYSES

Once the FRD is created, use it with these agents to produce the outputs you need:

### 1. DDL Schema Gap Analysis
**Agent:** `act as DB Architect` or `act as Technical Auditor`
**Prompt after activation:**
```
Compare this FRD against the DDL file for {MODULE_NAME}.
FRD: {OUTPUT_FILE}
DDL: {DDL_FILE}
For each REQ- entry in Section 10.1 where "DDL Entity Needed = Yes",
verify: does the DDL have the required table(s) and column(s)?
Produce a DDL gap table showing: REQ-ID | FRD Requirement | DDL Status | Missing Elements
```

### 2. Application Code Gap Analysis
**Agent:** `act as Technical Auditor`
**Prompt after activation:**
```
Compare this FRD against the code for {MODULE_NAME}.
FRD: {OUTPUT_FILE}
Code: {CODE_PATH}
For each REQ- entry in Section 10.1 where "Screen Needed = Yes" or "API Needed = Yes",
verify: is there a corresponding controller, route, and view implemented?
Produce a code gap table showing: REQ-ID | FRD Requirement | Code Status | Missing Elements
```

### 3. Technical Quality Gap Analysis
**Agent:** `act as Technical Auditor`
**Prompt after activation:**
```
Using the business rules from this FRD as the quality baseline,
audit the {MODULE_NAME} module code for:
- Business rule enforcement (BR- entries implemented?)
- Validation gaps (are all rules from BR- enforced in the form/request layer?)
- Security gaps (access control per Section 9.2?)
- Performance risks (report requirements from Section 7 met efficiently?)
- Coding standards, dead code, unfinished features
FRD: {OUTPUT_FILE}
Code: {CODE_PATH}
```

### 4. Completion Status Scoring (6 Dimensions)
**Agent:** `act as Status Analyzer`
**Prompt after activation:**
```
Using this FRD as the source of truth, calculate completion % across all 6 dimensions
for the {MODULE_NAME} module.
FRD: {OUTPUT_FILE}
DDL: {DDL_FILE}
Code: {CODE_PATH}
Test Cases: {TEST_CASES_FILE}

Dimension 1: DDL Schema Completeness
  Numerator: REQ entries in Section 10.1 where "DDL Entity Needed = Yes" AND DDL confirmed present
  Denominator: All REQ entries where "DDL Entity Needed = Yes"

Dimension 2: Application (Code) Completeness
  Numerator: REQ entries in Section 10.1 implemented in code
  Denominator: All REQ entries

Dimension 3: Test Case List Completeness
  Numerator: REQ entries in Section 10.1 where "Test Case Needed = Yes" AND test case exists in file
  Denominator: All REQ entries where "Test Case Needed = Yes"

Dimension 4: Test Case Scripts Completeness
  Numerator: REQ entries where an automated test SCRIPT exists and passes
  Denominator: All REQ entries where "Test Case Needed = Yes"

Dimension 5: Bug Fixing Status
  Numerator: BR- entries confirmed correctly enforced in code
  Denominator: All BR- entries in Section 4

Dimension 6: Deployment Readiness
  Evaluate against Section 9 non-functional requirements
  Score: percentage of NFRs that are met

Output: Scorecard showing % for each dimension + overall module health.
```

### 5. Test Case Coverage Gap
**Agent:** `act as Testing Architect`
**Prompt after activation:**
```
Using the FRD acceptance criteria as the test requirement baseline,
identify gaps in test coverage for {MODULE_NAME}.
FRD: {OUTPUT_FILE}
Test Cases File: {TEST_CASES_FILE}
Code: {CODE_PATH}

For each REQ- entry, check: does a test case exist that verifies each acceptance criterion?
Produce: Test Coverage Gap table | Recommended new test cases per REQ-ID
```

---

## FRD FOLDER STRUCTURE

Save all FRDs to:
```
/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/
├── CMP_FRD_2026-06-27.md             ← {MODULE_CODE}_FRD_{YYYY-MM-DD}.md
├── LIB_FRD_2026-06-25.md
└── ...
```

File naming convention: `{MODULE_CODE}_FRD_{YYYY-MM-DD}.md`
- `{MODULE_CODE}` — 2–4 letter code resolved from module_list.md (e.g., `CMP`, `LIB`)
- `{YYYY-MM-DD}` — the date the FRD is generated (e.g., `2026-06-27`)
- No version suffix — date is the version identifier; superseding FRDs get a new date

---

## ENHANCEMENT MANAGEMENT

When a client requests a new feature:
1. Add it as `ENH-{MODULE_CODE}-NNN` in Section 8 of the FRD with Status = "Backlog"
2. When approved, create a new REQ-{MODULE_CODE}-NNN in Section 3
3. Update Section 10.4 total counts
4. Increment document version (v1.0 → v1.1 or v2.0 for major changes)
5. Re-run gap analysis to measure new completion %

This makes the FRD a living document that grows with client requirements.

---

*Prompt Created: 2026-06-25*
*For use with: Claude Code (claude-sonnet-4-6 or higher)*
*Project: Prime-AI School ERP*
