# TMP — Complete Analysis Pack
**Module:** Template Management | **Code:** TMP | **Date:** 2026-06-30
**FRD:** `TMP_FRD_2026-06-30.md` (sibling file — all REQ-/BR-/RPT-/ENH- IDs are defined there and referenced here)
**Sources:** V1 screen specs (`Template_v2/`, 6 files) + Laravel module `Modules/Template/` + module knowledge `TMP_Template.md`

---

## Table of Contents
1. Requirements Traceability Matrix (RTM)
2. Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog
3. Process Flows + FSM Catalog
4. Data Dictionary (Business View) + Cross-Module Dependency Map
5. NFR Catalog + Risk Register
6. Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown
7. User Stories + Acceptance Criteria + Reporting & KPI Spec
8. Feature Specification (Screen-by-Screen)
9. Module Knowledge Update Summary

---

## Section 1 — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | Priority | BR Refs | Screen(s) | Workflow | Report | Code Status | Gap Summary |
|---|---|---|---|---|---|---|---|---|
| REQ-TMP-001 | Template Category Management | P0 | BR-003, 004, 005 | Tab: Template Types | WF-4 | — | PARTIAL | Seeded-type lock (BR-005) and delete-block-if-used (BR-004) unverified in controller |
| REQ-TMP-002 | Template Purpose Registry | P0 | BR-006, 007, 008 | Tab: Template Purposes | WF-5 | — | PARTIAL | update() not guarded for is_system; cascade on soft-delete unverified (BR-008) |
| REQ-TMP-003 | Template Variable Registry | P0 | BR-009, 010, 011, 021 | Tab: Template Variables | — | — | PARTIAL | Regex format (BR-009), partial mapping (BR-010), and global-vs-scoped unique (BR-021) all missing in FormRequest |
| REQ-TMP-004 | Visual Template Designer | P0 | BR-001, 002, 016, 017, 018 | Tab: Templates | WF-1, WF-4 | — | PARTIAL | Activation guard (BR-001), hard-delete block (BR-017), and cascade (BR-016) missing from controller |
| REQ-TMP-005 | Variable-to-Template Mapping | P0 | BR-001, 011 | Template Create/Edit | — | — | DONE | sync implemented; display_order preserved |
| REQ-TMP-006 | Template Scope Assignment | P0 | BR-012, 013, 014 | Tab: Assignments | WF-2 | — | PARTIAL | BR-012 silently resolves conflict instead of rejecting; BR-014 has no backend guard |
| REQ-TMP-007 | Background Image Management | P1 | BR-018 | Template Create/Edit | WF-6 | — | PARTIAL | GIF and WebP accepted beyond spec; file not cleaned on hard delete |
| REQ-TMP-008 | Engine — Scope Resolution | P0 | BR-015 | System (engine) | WF-3 | — | PARTIAL | Class Group fallback (Step 2) NOT implemented |
| REQ-TMP-009 | Engine — Variable Substitution | P0 | BR-019, 020 | System (engine) | WF-3 | — | PARTIAL | value_type column possibly missing in migration |
| REQ-TMP-010 | Engine — Loop Block Rendering | P1 | — | System (engine) | WF-3 | — | DONE | 5 unit tests pass; legacy markers translate correctly |
| REQ-TMP-011 | PDF Output Generation | P0 | — | System (engine) | WF-7 | — | PARTIAL | No integration test; toPdf() exists but untested end-to-end |
| REQ-TMP-012 | Sample Preview | P1 | — | Template Detail View | — | — | DONE | schema + sample data logic implemented; two HTTP tests missing |

**Summary:** DONE: 3 | PARTIAL: 9 | NOT STARTED: 0

---

## Section 2 — Business Rules Register + Requirement Conditions Catalog + Validation & Edge-Case Catalog

> Business Rules are fully defined in FRD Section 4. This section adds the conditions (trigger + enforcement) in catalog format and the edge-case table for testing.

### 2.1 Requirement Conditions Catalog

> Canonical copy also saved at: `{REQUIREMENT_CONDITIONS}/TMP_Conditions.md`

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-TMP-001 | Template / is_active | Template must have ≥ 1 mapped variable before is_active can be set to true | Validation | Template save or toggle-status | Return error: "The template must have at least one mapped variable before activation." |
| BR-TMP-002 | Template / code | Machine code must be unique across all templates including trashed | Validation | Template create / update | Return error: "The template code has already been taken." |
| BR-TMP-003 | Template Category / name | Category name must be unique (case-insensitive) | Validation | Category create / update | Return error: "The template type name has already been taken." |
| BR-TMP-004 | Template Category / delete | Category cannot be deleted if any template uses it | Workflow | Category destroy / forceDelete | Return error: "Cannot delete template type because it is being used by one or more templates." |
| BR-TMP-005 | Template Category / delete (seeded) | Seeded categories are permanently protected | Permission | Category destroy / forceDelete | Return error: "System protected template types cannot be deleted." |
| BR-TMP-006 | Template Purpose / code | Purpose code must be globally unique | Validation | Purpose create | Return error: "The purpose code has already been taken." |
| BR-TMP-007a | Template Purpose / code (system) | System purpose code cannot be changed | Permission | Purpose update | Return error: "System protected purposes cannot be modified." |
| BR-TMP-007b | Template Purpose / delete (system) | System purposes cannot be deleted | Permission | Purpose destroy / forceDelete | Return error: "System protected purposes cannot be modified or deleted." |
| BR-TMP-008 | Template Purpose / delete cascade | Soft-deleting a purpose cascades is_active=0 to assignments | Workflow | Purpose destroy | Related assignments marked inactive silently |
| BR-TMP-009 | Template Variable / name | Name must match [a-z0-9_] only | Validation | Variable create / update | Return error: "The variable name must contain only lowercase alphanumeric characters and underscores." |
| BR-TMP-010 | Template Variable / table_name + field_name | Both or neither must be provided | Validation | Variable create / update | Return error: "Both source table and source column are required to configure database auto-resolution." |
| BR-TMP-011 | Template Variable / delete cascade | Deleting variable removes junction records | Workflow | Variable destroy | DB CASCADE removes all junction rows |
| BR-TMP-012 | Scope Assignment / class_id + class_group_id | Cannot both be non-null | Validation | Assignment create / update | Return error: "An assignment cannot target both a class and a class group simultaneously." |
| BR-TMP-013 | Scope Assignment / scope_hash | Combination of purpose + session + scope target must be unique | Concurrency | Assignment create / update | Return error: "An active template assignment already exists for this scope." |
| BR-TMP-014 | Scope Assignment / class_id or class_group_id (school-wide purpose) | School-Wide purposes must not have class or group | Validation | Assignment create / update | Return error: "A school-wide purpose cannot be assigned to a specific class or class group." |
| BR-TMP-015 | Engine / resolveTemplate | Resolution follows Direct Class → Class Group → School-Wide | Workflow | Any render/PDF call | Raise TemplateNotFoundException if no match at any step |
| BR-TMP-016 | Template / soft-delete cascade | Soft-delete cascades assignments to inactive | Workflow | Template destroy | Related assignments set is_active=0 |
| BR-TMP-017 | Template / force-delete | Hard-delete blocked when active assignments exist | Workflow | Template forceDelete | Return error: "Cannot permanently delete a template that is linked to active scope assignments." |
| BR-TMP-018a | Background Image / mimes | Must be JPEG or PNG | Validation | Image upload | Return error: "The image must be a file of type: jpg, jpeg, png." |
| BR-TMP-018b | Background Image / size | Must not exceed 2 MB | Validation | Image upload | Return error: "The image may not be greater than 2048 kilobytes." |
| BR-TMP-019 | Engine / data merge | Caller data overrides provider data | Calculation | render() call | Merge: caller value wins on key collision |
| BR-TMP-020a | Engine / text type | Text values are HTML-escaped | Calculation | formatVariableValue() | Apply e() function |
| BR-TMP-020b | Engine / html type | Rich-HTML values are trusted pass-through | Calculation | formatVariableValue() | No escaping applied |
| BR-TMP-020c | Engine / image type | Image values rendered as img elements | Calculation | formatVariableValue() | Wrap in `<img src="..." alt="..." class="tpl-img-{name}">` |
| BR-TMP-021 | Template Variable / name (uniqueness scope) | Name must be unique within the same template category | Validation | Variable create | Return error: "The variable name has already been taken for this template type." |

### 2.2 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Template Code | MSH_CLASSIC_V5 | MSH CLASSIC V5 (space) | 50 chars exactly | Required — rejected if blank | Two users submit same code simultaneously | DB UNIQUE constraint; second insert rejected with validation error |
| Category Name | Marksheet | Marksheet (duplicate) | 30 chars | Required | Two users submit same name | UNIQUE index rejects second; no orphan created |
| Purpose Code | MARKSHEET_PRINT | MARKSHEET PRINT (space) | 30 chars | Required | Two purposes submitted with same code | UNIQUE index on code; second rejected |
| Variable Name | student_name | StudentName (uppercase) | 50 chars | Required | Two variables with same name in same category | Scoped UNIQUE per FormRequest; DB global UNIQUE rejects cross-type duplicate (bug) |
| Partial Mapping | table+field both set | Only table_name set, field_name blank | All three blank (Manual mode — valid) | All three null → Manual mode | — | ValidationException: both must be set |
| Scope Hash | 3:5:C10 | — | — | — | Two admins create same scope assignment | DB UNIQUE on scope_hash; second rejected with duplicate message |
| Class + Group | class_id=10, class_group_id=null | class_id=10, class_group_id=2 (both set) | — | Both null → school-wide | — | FormRequest must reject both-set with error |
| Image Upload | border.jpg (< 2 MB) | report.pdf | 2048 KB exactly (accepted) | No file → no upload action | — | Oversized or wrong type → 422 validation error |
| Template Activation | has_variables = true | has_variables = false | Exactly 1 variable (valid) | No variables (invalid) | Admin activates while another removes last variable | Guard re-checks at save time |
| Loop Block | <!-- LOOP: subjects -->...<-- ENDLOOP --> with 3-row array | Nested LOOP inside LOOP | 0 rows (returns empty string) | Missing key → empty string | — | No error on empty; produces empty string |

---

## Section 3 — Process Flows + FSM Catalog

### 3.1 Process Flow — Template Design to Production

```
[School Admin]                     [System]
     |                                |
     | 1. Open Template Designer      |
     |------------------------------> |
     |                                | Loads active categories + variables
     |                                |
     | 2. Author HTML content         |
     |    Select category             |
     |    [Optional] Upload BG image  |
     |    [Optional] Pick variables   |
     |------------------------------> |
     |                                | Validate code uniqueness
     |                                | Normalise HTML
     |                                | Save as DRAFT
     |                                | Sync variable junctions
     | <-- Success / Validation error |
     |                                |
     | 3. Set status to Active        |
     |------------------------------> |
     |                                | Check variable count ≥ 1 (BR-001)
     |                                | If 0 → reject
     |                                | If ≥ 1 → mark Active
     | <-- Active / Error             |
     |                                |
     | 4. Create Scope Assignment     |
     |    Select purpose + session    |
     |    Select scope (class/group)  |
     |------------------------------> |
     |                                | Validate: school-wide purpose → no class/group
     |                                | Validate: mutual exclusion class vs group
     |                                | Compute scope_hash; check UNIQUE
     |                                | Save assignment (active)
     | <-- Assignment saved           |
```

### 3.2 Process Flow — Engine Render (Consuming Module)

```
[Consuming Module]                 [Template Engine]              [DB / Provider]
        |                                  |                             |
        | render(purpose, data, ids)        |                             |
        |--------------------------------> |                             |
        |                                  | resolveProviderData()        |
        |                                  |-------------------------> DataProvider.provide()
        |                                  | <-- providerData             |
        |                                  | merge(providerData, callerData) [caller wins]
        |                                  |                             |
        |                                  | resolveTemplate(purpose, classId, sessionId)
        |                                  |--------------------------> Step 1: Direct Class
        |                                  | <-- found? YES → templateId  |
        |                                  |   (else) Step 2: Class Group  |
        |                                  | <-- found? YES → templateId  |
        |                                  |   (else) Step 3: School-Wide  |
        |                                  | <-- found? YES → templateId  |
        |                                  |   (else) throw TemplateNotFoundException
        |                                  |                             |
        |                                  | loadTemplate(templateId)    |
        |                                  | expandLoopBlocks(html, data) |
        |                                  | resolveVariables(html, vars, data, ids)
        |                                  |   For each active variable:  |
        |                                  |     In caller data? → use it |
        |                                  |     Else → fetchColumn(table, field, ids)
        |                                  |     Else → junction default  |
        |                                  |     formatVariableValue(type, raw)
        |                                  |                             |
        | <-- rendered HTML string         |                             |
```

### 3.3 FSM — Template Status

**Entity:** Template Design

| From State | Event / Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Administrator saves new template | code unique; type exists | DRAFT | Activity log: created |
| DRAFT | Administrator activates | ≥ 1 variable mapped (BR-001) | ACTIVE | Activity log: status_updated |
| ACTIVE | Administrator deactivates | — | DRAFT | Activity log: status_updated |
| DRAFT or ACTIVE | Administrator soft-deletes | — | TRASHED | All scope assignments set inactive (BR-016) |
| TRASHED | Administrator restores | — | DRAFT | Activity log: restored; assignments remain inactive |
| TRASHED | Administrator force-deletes | No active assignments referencing template (BR-017) | HARD DELETED | Record removed; junction rows removed (CASCADE) |

**Terminal state:** HARD DELETED (irreversible).
**Illegal transitions:** ACTIVE → HARD DELETED (must go ACTIVE → TRASHED → HARD DELETED).

### 3.4 FSM — Scope Assignment Status

**Entity:** Scope Assignment

| From State | Event / Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| (none) | Administrator saves assignment | scope_hash unique; template active | ACTIVE | Activity log: created |
| ACTIVE | Administrator deactivates (toggle) | — | INACTIVE | Excluded from engine resolution |
| INACTIVE | Administrator re-activates (toggle) | scope_hash still unique | ACTIVE | Included in engine resolution |
| ACTIVE or INACTIVE | Template soft-deleted | Cascade from template (BR-016) | INACTIVE | No actor log |
| ACTIVE or INACTIVE | Purpose soft-deleted | Cascade from purpose (BR-008) | INACTIVE | No actor log |
| ACTIVE or INACTIVE | Administrator soft-deletes | — | TRASHED | — |
| TRASHED | Administrator restores | — | INACTIVE | Does not re-activate automatically |
| TRASHED | Administrator force-deletes | — | HARD DELETED | Record removed |

**Terminal state:** HARD DELETED.

---

## Section 4 — Data Dictionary (Business View) + Cross-Module Dependency Map

### 4.1 Data Dictionary — Business View

#### Layout / Template Design (6 entities)

**Template Category**

| Business Field | Business Meaning | Type | Required | Values | PII? |
|---|---|---|---|---|---|
| Category Name | Groups layouts by document type | Short text ≤ 30 | Yes | Unique (case-insensitive) | No |
| Description | Explanation of usage | Medium text | No | — | No |
| Active | Visible and selectable | Boolean | Yes | Active / Inactive | No |

**Template Purpose**

| Business Field | Business Meaning | Type | Required | Values | PII? |
|---|---|---|---|---|---|
| Purpose Code | Machine identifier for this output role | Short text ≤ 30 | Yes | Unique; [A-Z0-9_] | No |
| Purpose Name | Human-readable label | Medium text ≤ 100 | Yes | — | No |
| Description | Where the purpose is used | Medium text | No | — | No |
| Target Scope | Class-specific or school-wide | Lookup | Yes | Class-Scoped / School-Wide | No |
| Display Order | Ranking in dropdowns | Integer ≥ 1 | Yes | — | No |
| System Protected | Seeded, unmodifiable flag | Boolean | No | Yes / No | No |
| Active | Operational status | Boolean | Yes | Active / Inactive | No |

**Template Variable (Merge Placeholder)**

| Business Field | Business Meaning | Type | Required | Values | PII? |
|---|---|---|---|---|---|
| Variable Name | Placeholder identifier in HTML | Short text ≤ 50 | Yes | Unique per category; [a-z0-9_] | No |
| Template Category | Scope of this placeholder | Lookup | Yes | — | No |
| Description | Tooltip for canvas editor | Medium text | No | — | No |
| Source Database | DB name for auto-resolution | Short text ≤ 60 | No | Confidential field | No |
| Source Table | Table name for auto-resolution | Short text ≤ 60 | No (required with Source Column) | Confidential | No |
| Source Column | Column for auto-resolution | Short text ≤ 60 | No (required with Source Table) | Confidential | No |
| Output Type | Rendering format | Lookup | No | Text / Rich HTML / Image; default Text | No |
| Active | Operational status | Boolean | Yes | Active / Inactive | No |

**Layout Design (Template)**

| Business Field | Business Meaning | Type | Required | Values | PII? |
|---|---|---|---|---|---|
| Machine Code | Immutable identifier | Short text ≤ 50 | Yes | Unique | No |
| Display Name | Human-readable label | Medium text ≤ 100 | Yes | — | No |
| Category | Document type category | Lookup | Yes | — | No |
| Description | Scope and use explanation | Long text | No | — | No |
| Canvas Data | Element positions (JSON) | JSON | No | — | No |
| HTML Content | Compiled layout + placeholders | HTML long text | Yes | — | Confidential |
| Background Image | Branding image storage path | File path | No | — | No |
| Status | Draft or Active | Boolean | Yes | Draft / Active | No |

**Variable-Template Junction**

| Business Field | Business Meaning | Type | Required | PII? |
|---|---|---|---|---|
| Template | Parent layout | Reference | Yes | No |
| Variable | Linked placeholder | Reference | Yes | No |
| Display Order | Rendering sequence | Integer | Yes | No |
| Default Value | Fallback when no source returns a value | Short text | No | No |
| Active | Mapping status | Boolean | Yes | No |

**Scope Assignment**

| Business Field | Business Meaning | Type | Required | PII? |
|---|---|---|---|---|
| Template | Assigned layout (active only) | Reference | Yes | No |
| Purpose | Output purpose | Reference | Yes | No |
| Academic Session | Year-term context | Reference | Yes | No |
| Target Scope | Class, Class Group, or School-Wide | Conditional | Yes | No |
| Scope Identifier | Computed unique key | Generated text | Auto | No |
| Active | Operational status | Boolean | Yes | No |

Note on PII: None of the Template module's own data is PII. The rendered output may contain student PII (names, photos, roll numbers) — but that data is owned by StudentProfile and supplied by consuming modules at render time; it is never persisted in the Template module itself.

### 4.2 Cross-Module Dependency Map

**TMP Consumes From (Inbound)**

| Source Module | Data / Entity | Why |
|---|---|---|
| SchoolSetup | Academic Session | FK on Scope Assignment (`sch_org_academic_sessions_jnt`) |
| SchoolSetup | School Class | FK on Scope Assignment for Direct Class targeting |
| SchoolSetup | School Organisation | Auto-resolved variable: school name, logo (sch_organizations) |
| MarksheetGeneration | Class Group | FK on Scope Assignment for Class Group targeting; direct model import (coupling — see Gap GAP-TMP-08) |
| SystemConfig (sys_dropdowns) | Scope Type values | FK on Purpose scope_type_id |
| StudentProfile | Student data | Auto-resolved variables: name, admission_no, photo, father_name (std_students, std_student_profiles) |
| HrStaff | Employee data | Auto-resolved variables: teacher name, designation (hrs_employees) |
| DomPDF (library) | PDF engine | toPdf() via barryvdh/laravel-dompdf |

**TMP Provides To (Outbound)**

| Consumer Module | Mechanism | What TMP Provides |
|---|---|---|
| MarksheetGeneration | TemplateEngineInterface::render('MARKSHEET_PRINT', ...) | Rendered HTML / PDF for marksheet printing |
| Certificate (CRT) | TemplateEngine::render('TRANSFER_CERT', ...) | Certificate layout rendering |
| StudentFee (FIN) | TemplateEngine::render('FEE_RECEIPT', ...) | Fee receipt layout rendering |
| StudentProfile (STD) | TemplateEngine::render('STUDENT_ID_CARD', ...) | Student ID card rendering |
| LmsExam (EXM) | TemplateEngine::render('ADMIT_CARD', ...) | Exam admit card rendering |
| Any future consumer | Implement DataProviderInterface + register in config/template.php | Generic layout engine |

**Integration Pattern:** Consuming modules implement `DataProviderInterface::provide(array $context): array` and register themselves in central `config/template.php` under the relevant purpose code. The engine calls the provider automatically — consuming modules do not need to call Template directly except via `TemplateEngineInterface::render()` or `::toPdf()`.

---

## Section 5 — NFR Catalog + Risk Register

### 5.1 NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|---|---|---|---|
| NFR-TMP-P-001 | Performance | Single HTML render ≤ 500 ms | 95th percentile under production load |
| NFR-TMP-P-002 | Performance | PDF generation ≤ 2 000 ms for single-page | 95th percentile |
| NFR-TMP-P-003 | Performance | Scope resolution query ≤ 100 ms | Requires indexes on purpose_id + academic_session_id + class_id |
| NFR-TMP-S-001 | Security | All routes require authenticated tenant users | 401 / redirect on unauthenticated request |
| NFR-TMP-S-002 | Security | DB schema introspection endpoints restricted to Super Admin | 403 for non-super-admin |
| NFR-TMP-S-003 | Security | Background image MIME validated server-side | PHP file renamed .jpg is rejected |
| NFR-TMP-S-004 | Security | Rich-HTML variables source only from system-controlled data | Documented restriction; verified in seeded variable configs |
| NFR-TMP-S-005 | Security | All routes protected by module subscription middleware | School without Template module subscription receives 403 |
| NFR-TMP-U-001 | Usability | Tab dashboard loads all five datasets in one request | Page load < 3 s with 200+ templates |
| NFR-TMP-U-002 | Usability | Variable picker filters by selected template category | Selecting MARKSHEET shows only MARKSHEET variables |
| NFR-TMP-U-003 | Usability | All rule violation messages in plain language | No raw SQL error or stack trace visible to user |
| NFR-TMP-SC-001 | Scalability | Engine must handle parallel render calls for batch marksheet printing | Stateless singleton design supports concurrent calls without shared state |
| NFR-TMP-C-001 | Compliance | Template data isolated per school | No tenant_id column; isolation via separate database per stancl/tenancy architecture |

### 5.2 Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---|---|---|---|---|---|---|---|
| RISK-TMP-001 | Rich-HTML variable type allows XSS if user-controlled data is mapped to an html-type variable | Security | M | H | Document restriction; restrict html-type mapping to system-controlled source tables only; code review gate on new variable creation | Tech Lead | Any variable with html type whose source table stores user-submitted content |
| RISK-TMP-002 | DB schema introspection endpoints expose full tenant DB structure to any authenticated user | Security | H | M | Restrict getDatabases/getTables/getColumns to Super Admin role (currently any tenant user with variable.view permission can call) | Dev | POST gap analysis audit findings |
| RISK-TMP-003 | Class Group fallback not implemented — templates assigned to class groups are never resolved | Functional | H | H | Implement Step 2 in TemplateEngine::resolveTemplate() as P0 sprint task | Dev | MarksheetGeneration reports blank PDF for group-scoped classes |
| RISK-TMP-004 | value_type column missing from DDL migration — all variables silently default to text type | Data | M | M | Run Schema::hasColumn check; add migration if missing | Dev | Image and HTML variables render as escaped text in output |
| RISK-TMP-005 | Activation guard (BR-001) not enforced — blank templates can be activated and assigned | Functional | H | M | Add variable-count check in toggleStatus and store/update before setting is_active=1 | Dev | Engine renders blank PDFs for templates with no variables |
| RISK-TMP-006 | Hard-delete not guarded (BR-017) — active assignments lose their template FK silently | Data | M | H | Add active-assignment check in forceDelete before deleting | Dev | Engine throws 500 on next render for affected assignments |
| RISK-TMP-007 | TemplateAssignment model imports MarksheetGeneration ClassGroup directly — breaks if MarksheetGeneration is disabled | Architecture | L | H | Move ClassGroup to SchoolSetup or use a plain DB query; remove direct model import | Dev | Boot error when Template loads without MarksheetGeneration |
| RISK-TMP-008 | config/template.php missing from central config — all provider-based rendering silently returns empty data | Configuration | M | H | Add config/template.php stub with empty providers array to application config | Dev | All purpose rendering returns blank layout (no exception raised) |
| RISK-TMP-009 | Zero HTTP/controller tests — breaking changes to CRUD, permission checks, or cascade logic go undetected | Quality | H | M | Sprint 3 task: write HTTP test suite covering auth, CRUD lifecycle, scope conflict, and system-protection guards | Dev | Any regression in CI after a Template PR |

---

## Section 6 — Prioritization (MoSCoW) + Effort Estimation & Sprint Task Breakdown

### 6.1 MoSCoW Prioritization

| Requirement / Enhancement | MoSCoW | Rationale |
|---|---|---|
| REQ-TMP-001 Template Category Management | Must | Foundation for all template creation |
| REQ-TMP-002 Template Purpose Registry | Must | Required for engine resolution and assignment |
| REQ-TMP-003 Template Variable Registry | Must | Required for placeholder substitution |
| REQ-TMP-004 Visual Template Designer | Must | Core module capability |
| REQ-TMP-005 Variable-to-Template Mapping | Must | Required for substitution and activation |
| REQ-TMP-006 Template Scope Assignment | Must | Required for engine to find any template |
| REQ-TMP-007 Background Image Management | Should | Enhances visual quality; not blocking core function |
| REQ-TMP-008 Engine — Scope Resolution | Must | Platform-wide service depended on by 5+ modules |
| REQ-TMP-009 Engine — Variable Substitution | Must | Core engine function |
| REQ-TMP-010 Engine — Loop Block Rendering | Should | Required for marksheet subject-row rendering |
| REQ-TMP-011 PDF Output Generation | Must | Primary consumer output format |
| REQ-TMP-012 Sample Preview | Should | Quality gate before deployment; not blocking rendering |
| ENH-TMP-001 Version History | Could | Useful but deferred |
| ENH-TMP-002 Template Clone | Could | Convenience feature |
| ENH-TMP-003 Preview with Real Data | Could | Quality improvement |
| ENH-TMP-004 Usage Audit | Could | Monitoring |
| ENH-TMP-005 Visual Canvas Editor | Won't | Large frontend investment; deferred |
| ENH-TMP-006 Template Export/Import | Won't | Requires inter-tenant architecture |

### 6.2 Effort Estimation & Sprint Task Breakdown

> Assumes 1 developer; ~30–35 usable hours per sprint; gap work only (existing working code not re-built).

#### Sprint 1 — Business Rule Enforcement (≈ 28 h)

| # | Task | Type | Effort | Depends | REQ/BR |
|---|---|---|---|---|---|
| S1-01 | Add ≥1-variable check in TemplateController store/update and toggleStatus before setting is_active=1 | Backend | 3 h | — | REQ-004, BR-001 |
| S1-02 | Add active-assignment check in TemplateController.forceDelete before hard delete | Backend | 2 h | — | REQ-004, BR-017 |
| S1-03 | Add cascade: soft-deleting template sets assignments is_active=0 | Backend | 2 h | — | REQ-004, BR-016 |
| S1-04 | Add is_system guard in TemplatePurposeController.update() for code and scope_type_id fields | Backend | 2 h | — | REQ-002, BR-007 |
| S1-05 | Add cascade: soft-deleting purpose sets assignments is_active=0 | Backend | 2 h | — | REQ-002, BR-008 |
| S1-06 | Add regex validation [a-z0-9_] to StoreTemplateVariableRequest + UpdateTemplateVariableRequest | Backend | 1 h | — | REQ-003, BR-009 |
| S1-07 | Add cross-field validation: table_name and field_name both set or both null | Backend | 1 h | — | REQ-003, BR-010 |
| S1-08 | Fix variable uniqueness: change FormRequest to global unique on name; resolve conflict with DB index | Backend | 2 h | S1-06 | REQ-003, BR-021 |
| S1-09 | Change StoreTemplateAssignmentRequest to REJECT when both class_id and class_group_id are set (not silently resolve) | Backend | 2 h | — | REQ-006, BR-012 |
| S1-10 | Add SCHOOL_WIDE backend guard in StoreTemplateAssignmentRequest: reject class/group if purpose is school-wide | Backend | 3 h | — | REQ-006, BR-014 |
| S1-11 | Verify / add seeded-type lock in TemplateTypeController.destroy + forceDelete | Backend | 2 h | — | REQ-001, BR-005 |
| S1-12 | Verify / add deletion-block-if-used in TemplateTypeController.destroy + forceDelete | Backend | 2 h | — | REQ-001, BR-004 |
| S1-13 | Add EnsureTenantHasModule middleware to all Template routes in web.php | Backend | 2 h | — | NFR-TMP-S-005 |
| S1-14 | Restrict getDatabases/getTables/getColumns to Super Admin role in TemplateVariableController | Backend | 2 h | — | NFR-TMP-S-002 |

**Sprint 1 total:** 28 h

#### Sprint 2 — Engine Gaps + DDL + Config (≈ 18 h)

| # | Task | Type | Effort | Depends | REQ/BR |
|---|---|---|---|---|---|
| S2-01 | Implement Class Group fallback in TemplateEngine::resolveTemplate() — Step 2: query class group membership, then match assignment | Backend | 8 h | — | REQ-008, BR-015 |
| S2-02 | Verify value_type column in tmp_template_variables migration; add missing migration if absent | Schema | 2 h | — | REQ-009, BR-020 |
| S2-03 | Add config/template.php stub with empty providers array to central application config | Config | 1 h | — | RISK-TMP-008 |
| S2-04 | Decouple TemplateAssignment model from MarksheetGeneration ClassGroup — use plain DB query or move ClassGroup to SchoolSetup | Backend | 4 h | — | RISK-TMP-007 |
| S2-05 | Audit and migrate any callers of deprecated TemplateService to inject TemplateEngineInterface directly | Backend | 3 h | — | GAP-TMP-06 |

**Sprint 2 total:** 18 h

#### Sprint 3 — Test Suite + Background Image Alignment (≈ 22 h)

| # | Task | Type | Effort | Depends | REQ/BR |
|---|---|---|---|---|---|
| S3-01 | HTTP test: Template category CRUD + seeded-type protection + deletion block | Testing | 3 h | S1-11, S1-12 | REQ-001 |
| S3-02 | HTTP test: Purpose registry CRUD + system protection + cascade deactivation | Testing | 3 h | S1-04, S1-05 | REQ-002 |
| S3-03 | HTTP test: Variable CRUD + regex + partial mapping + uniqueness | Testing | 3 h | S1-06, S1-07, S1-08 | REQ-003 |
| S3-04 | HTTP test: Template designer + activation guard + cascade + hard-delete block | Testing | 4 h | S1-01, S1-02, S1-03 | REQ-004 |
| S3-05 | HTTP test: Scope assignment + mutual exclusion + school-wide guard + scope conflict | Testing | 3 h | S1-09, S1-10 | REQ-006 |
| S3-06 | Unit test: Engine class-group resolution (Step 2) | Testing | 2 h | S2-01 | REQ-008 |
| S3-07 | Integration test: toPdf() end-to-end with mock provider | Testing | 2 h | — | REQ-011 |
| S3-08 | Align background image upload: remove GIF and WebP from accepted mimes to match spec | Backend | 1 h | — | REQ-007, BR-018 |
| S3-09 | Add file cleanup on hard-delete: remove background image from storage when template is force-deleted | Backend | 1 h | S1-02 | REQ-007 |

**Sprint 3 total:** 22 h

**Grand total gap effort:** 68 h across 3 sprints.
**Estimated residual completion after sprints 1–3:** ~95% (from current ~78%).

---

## Section 7 — User Stories + Acceptance Criteria + Reporting & KPI Spec

### 7.1 User Stories

> Every P0 and P1 requirement has at least one user story. All link back to REQ-TMP-IDs.

---

**US-TMP-001** | P0 | REQ-TMP-001
As a School Administrator, I want to create and manage template categories so that I can group layout designs by document type and control which categories are available for template design.

Scenario: Create a new category
  Given I am logged in as School Administrator
  When I submit a new category "VISITOR_PASS" with description
  Then the category appears in the active category list and is available as a template type option

Scenario: Duplicate name rejected
  Given category "Marksheet" already exists
  When I submit a new category "MARKSHEET" (same name, different case)
  Then I receive an error: "The template type name has already been taken."

Scenario: Seeded type cannot be deleted
  Given "Marksheet" is a seeded category
  When I attempt to delete it
  Then the action is blocked with an error: "System protected template types cannot be deleted."

Scenario: In-use category cannot be deleted
  Given "Fee Receipt" has 3 templates linked to it
  When I attempt to delete "Fee Receipt"
  Then the action is blocked with an error referencing the linked templates.

Definition of Done: Category creation, uniqueness rejection, seeded-type lock, and in-use block all pass HTTP tests.

---

**US-TMP-002** | P0 | REQ-TMP-002
As a School Administrator, I want to register custom template purposes so that I can define new document workflows (e.g., Library Card) beyond the six seeded purposes.

Scenario: Create custom purpose
  Given I have a "Library Card" workflow needed
  When I register purpose "LIBRARY_CARD" with scope "Class-Scoped" and display order 10
  Then it appears in the purpose list and is available in scope assignment dropdowns

Scenario: System purpose code locked
  Given "MARKSHEET_PRINT" is a system purpose
  When I edit its code to "MARKSHEET_PRINT_NEW"
  Then the update is rejected: "System protected purposes cannot be modified."

Scenario: Soft-delete cascades
  Given purpose "LIBRARY_CARD" has 2 active scope assignments
  When I soft-delete "LIBRARY_CARD"
  Then both scope assignments are marked inactive

Definition of Done: Custom purpose creation, system lock, and cascade deactivation all pass HTTP tests.

---

**US-TMP-003** | P0 | REQ-TMP-003
As a School Administrator, I want to register placeholder variables for each template category so that the engine knows which data to insert into layouts at render time.

Scenario: Create automated variable
  Given I am on the Variable Registry screen
  When I create "father_name" for category MARKSHEET with source table "std_students" and column "father_name"
  Then the variable appears in the registry and is available in the MARKSHEET variable picker

Scenario: Partial mapping rejected
  Given I enter source table but leave source column empty
  When I save
  Then I receive: "Both source table and source column are required to configure database auto-resolution."

Scenario: Invalid name rejected
  Given I attempt to create a variable named "FatherName"
  When I save
  Then I receive: "The variable name must contain only lowercase alphanumeric characters and underscores."

Definition of Done: Automated variable creation, partial mapping error, and naming validation all pass HTTP tests.

---

**US-TMP-004** | P0 | REQ-TMP-004
As a School Administrator, I want to design and activate HTML-based document layouts so that consuming modules can render polished, school-branded PDFs.

Scenario: Create a draft template
  Given I am on the Template Designer tab
  When I enter code "MSH_CLASSIC_V5", name, and category MARKSHEET, paste HTML content
  Then the template is saved in Draft state

Scenario: Activation blocked without variables
  Given I have created "MSH_CLASSIC_V5" with no mapped variables
  When I set status to Active
  Then I receive: "The template must have at least one mapped variable before activation."

Scenario: Hard-delete blocked with active assignments
  Given "MSH_CLASSIC_V5" has an active scope assignment for Session 2026-27
  When I attempt to hard-delete it
  Then the action is blocked: "Cannot permanently delete a template that is linked to active scope assignments."

Scenario: Soft-delete cascades
  Given "MSH_CLASSIC_V5" has 2 active assignments
  When I soft-delete the template
  Then both assignments are marked inactive

Definition of Done: All four scenarios pass HTTP tests; activity log entries created.

---

**US-TMP-005** | P0 | REQ-TMP-005
As a School Administrator, I want to map placeholder variables to a template so that the engine knows which placeholders to substitute when rendering that specific layout.

Scenario: Mapping variables
  Given template "MSH_CLASSIC_V5" exists in Draft
  When I select variables [student_name, roll_no, school_name] with display orders [1, 2, 3]
  Then three junction records are created with the correct orders

Scenario: Default value fallback
  Given "result_status" is a manual variable mapped to "MSH_CLASSIC_V5" with default "Promoted"
  When the engine renders and the calling module does not supply a value for "result_status"
  Then "Promoted" appears in the output

Definition of Done: Junction sync, display order, and default fallback tested in HTTP/unit tests.

---

**US-TMP-006** | P0 | REQ-TMP-006
As a School Administrator, I want to assign templates to purposes for specific academic sessions and classes so that the engine resolves the correct layout when generating documents.

Scenario: Direct class assignment
  Given template "Grade 5 Marksheet" is Active
  When I assign it to MARKSHEET_PRINT for session 2026-27, scope = Specific Class, Grade 5
  Then the assignment is created with scope identifier "1:5:C10"

Scenario: Duplicate scope rejected
  Given the above assignment already exists
  When I try to create another assignment with the same purpose, session, and class
  Then I receive: "An active template assignment already exists for this scope."

Scenario: Both class and group rejected
  When I submit an assignment with both class_id and class_group_id set
  Then I receive: "An assignment cannot target both a class and a class group simultaneously."

Scenario: School-Wide purpose rejects class scope
  Given "FEE_RECEIPT" has scope type SCHOOL_WIDE
  When I submit an assignment for FEE_RECEIPT with a class selected
  Then I receive: "A school-wide purpose cannot be assigned to a specific class or class group."

Definition of Done: All four scenarios pass HTTP tests.

---

**US-TMP-007** | P1 | REQ-TMP-007
As a School Administrator, I want to upload a background branding image for a template so that the final PDF has the school's letterhead or border.

Scenario: Valid upload
  Given I am designing a template
  When I upload border.jpg (JPEG, 1.5 MB)
  Then the upload succeeds and the path is available to embed as the canvas background

Scenario: Oversized file rejected
  When I upload border.jpg at 3 MB
  Then I receive: "The image may not be greater than 2048 kilobytes."

Definition of Done: Valid upload and size rejection pass HTTP tests.

---

**US-TMP-008** | P0 | REQ-TMP-008
As a system (MarksheetGeneration module), I want the engine to automatically resolve the correct template for a purpose, session, and class so that I do not need to hard-code layout IDs.

Scenario: Direct class resolves first
  Given assignments: (MARKSHEET_PRINT, Session 5, Class 10) → Template A; (MARKSHEET_PRINT, Session 5, School-Wide) → Template B
  When engine is called with purpose=MARKSHEET_PRINT, sessionId=5, classId=10
  Then Template A is resolved (not Template B)

Scenario: Class Group fallback
  Given only a group assignment exists for a group containing Class 10
  When engine is called with classId=10
  Then the group-level template is resolved

Scenario: School-Wide fallback
  Given only a school-wide assignment exists
  When engine is called with classId=10
  Then the school-wide template is resolved

Scenario: No assignment raises exception
  Given no assignments exist for the purpose
  When engine is called
  Then TemplateNotFoundException is raised (not null or blank HTML)

Definition of Done: All four scenarios pass unit tests; Step 2 (class group) requires S2-01 sprint task.

---

**US-TMP-009** | P0 | REQ-TMP-009
As a system, I want the engine to substitute all placeholder markers with resolved values so that the rendered HTML contains real data.

Scenario: Automated variable resolved
  Given "student_name" is mapped to std_students.first_name
  When engine renders with studentId=42
  Then {{student_name}} is replaced with the student's actual first name

Scenario: Caller value overrides provider
  Given a Data Provider returns "John Doe" for "student_name"
  When the caller also passes student_name="Johnny"
  Then "Johnny" appears in the output

Scenario: Text-type value HTML-escaped
  Given student_name value is "<b>Smith</b>"
  When rendered as text type
  Then "&lt;b&gt;Smith&lt;/b&gt;" appears in the output (not bold)

Definition of Done: All three scenarios pass engine unit tests.

---

**US-TMP-010** | P1 | REQ-TMP-010
As a system (MarksheetGeneration), I want the engine to expand loop blocks for repeating rows so that a marksheet lists all subjects in a table without needing one row per subject in the HTML template.

Scenario: Loop expansion
  Given HTML contains <!-- LOOP: subjects --> ... <!-- ENDLOOP --> and subjects data has 5 rows
  When engine renders
  Then the inner block is repeated 5 times with correct per-row values

Scenario: Empty loop
  Given subjects data is an empty array
  When engine renders
  Then the loop block produces empty string (no error)

Definition of Done: Both scenarios covered by existing unit tests (pass confirmed).

---

**US-TMP-011** | P0 | REQ-TMP-011
As a Class Teacher (via the MarksheetGeneration module), I want to download a PDF marksheet so that I can print it for students.

Scenario: PDF generated successfully
  Given a valid MARKSHEET_PRINT assignment exists for Session 2026-27 and Class 10
  When MarksheetGeneration calls toPdf(purpose='MARKSHEET_PRINT', classId=10, sessionId=5)
  Then a PDF object is returned with correct A4 portrait size and all placeholders resolved

Scenario: PDF fails cleanly on missing template
  Given no assignment exists for the purpose
  When toPdf() is called
  Then TemplateNotFoundException is propagated to the caller (not a blank PDF)

Definition of Done: Both scenarios covered by integration test (S3-07 sprint task).

---

**US-TMP-012** | P1 | REQ-TMP-012
As a School Administrator, I want to preview a template with sample data so that I can verify the layout before deploying it to production.

Scenario: Preview with provider
  Given "MSH_CLASSIC_V5" is assigned to MARKSHEET_PRINT purpose which has a registered data provider
  When I click "Preview Sample" on the template detail view
  Then the browser shows a rendered HTML preview with synthetic student data

Scenario: Preview without provider
  Given a template with no registered purpose provider
  When I click "Preview Sample"
  Then the preview renders with empty-string placeholders (no error)

Definition of Done: Both scenarios pass HTTP tests.

---

### 7.2 Reporting & KPI Spec

| RPT-ID | Report | Audience | Frequency | Contents | Filters | Export | Business Rules |
|---|---|---|---|---|---|---|---|
| RPT-TMP-001 | Template Catalogue | School Administrator, Principal | On demand | Template name, category, status (Draft/Active/Trashed), mapped variable count, active assignment count, last modified date | Category, Status | PDF, Excel | Count active assignments per template; exclude hard-deleted templates |

**KPI Catalog (future — ENH-TMP-004):**

| KPI | Definition | Source | Target |
|---|---|---|---|
| Template Render Success Rate | % of render() calls that return HTML without exception | Engine logging (future) | ≥ 99.5% |
| Purpose Coverage | % of seeded purposes that have at least one active assignment in the current academic session | tmp_template_assignments | 100% before term end |
| Template Draft Backlog | Count of templates in Draft state older than 30 days | tmp_templates | 0 (all designs should be activated or deleted) |

---

## Section 8 — Feature Specification (Screen-by-Screen)

### 8.1 Overview
The Template module exposes a single tabbed dashboard at `/template/templates-tabs` containing five tabs. Each tab corresponds to one resource area. Below are the screen-level field specifications derived from V1 screen specs and code review.

---

### Screen 1: Template Types Tab

**Purpose:** Define and manage visual categories grouping layouts by document type.
**Route:** `/template/templates-tabs?tab=type_list` (list); `/template-types/create` (create); `/template-types/{id}/edit` (edit)

| # | Field (Business Label) | Control | Required | Validation (Business) | Options Source | Notes |
|---|---|---|---|---|---|---|
| 1 | Type Name | Text input | Yes | Max 30 chars; unique (case-insensitive) | — | Seeded: Marksheet, ID Card, Fee Receipt, Admit Card, Certificate; protected from delete |
| 2 | Description | Text area | No | Max 255 chars | — | — |
| 3 | Active | Checkbox | No | Boolean | Active / Inactive | Default: Inactive |

**Actions:** Create, Edit, Soft-Delete, Restore (from trash), Hard-Delete, Toggle Status
**Filters:** Search by name/description; Status filter
**Empty state:** "No template types found. Create your first template type."
**Permissions:** School Administrator — full; Principal — view only
**Business Rule Guards:** Seeded-type deletion blocked (BR-005); in-use deletion blocked (BR-004)

---

### Screen 2: Template Purposes Tab

**Purpose:** Register functional output purposes and their scope rules.
**Route:** `/template/templates-tabs?tab=purpose_list`; `/purposes/create`; `/purposes/{id}/edit`

| # | Field | Control | Required | Validation | Options Source | Notes |
|---|---|---|---|---|---|---|
| 1 | Purpose Name | Text input | Yes | Max 100 chars | — | — |
| 2 | Unique Code | Text input | Yes | Max 30 chars; alphanumeric + underscore; unique | — | Locked on system records |
| 3 | Target Scope | Dropdown | Yes | From sys_dropdowns where key='tmp_template_purposes.scope_type_id' | CLASS_SCOPED / SCHOOL_WIDE | Locked on system records |
| 4 | Display Order | Number input | Yes | Integer ≥ 1 | — | Controls dropdown sort |
| 5 | Description | Text area | No | Max 255 chars | — | — |

**Actions:** Create, Edit, Soft-Delete, Restore, Hard-Delete, Toggle Status, Reorder
**Filters:** Search by name/code; Scope filter
**Empty state:** System purposes always visible; only custom purposes can be absent
**Permissions:** School Administrator — full; Principal — view only
**Business Rule Guards:** System purpose code/scope locked (BR-007); soft-delete cascade (BR-008)
**Seeded purposes (is_system=1):** MARKSHEET_PRINT, STUDENT_ID_CARD, TRANSFER_CERT, CHARACTER_CERT, ADMIT_CARD, FEE_RECEIPT

---

### Screen 3: Template Variables Tab

**Purpose:** Define and manage merge placeholder variables per template category.
**Route:** `/template/templates-tabs?tab=variable_list`; `/template-variables/create`; `/template-variables/{id}/edit`

| # | Field | Control | Required | Validation | Options Source | Notes |
|---|---|---|---|---|---|---|
| 1 | Variable Name | Text input | Yes | Max 50 chars; [a-z0-9_] only; unique per category | — | e.g., student_name, roll_no |
| 2 | Associated Category | Dropdown | Yes | Active template types | tmp_templates_type | Scopes available variables |
| 3 | Output Type | Dropdown | No | Text / Rich HTML / Image | Static | Default: Text |
| 4 | Source Database | Text input (or AJAX picker) | No | Max 60 chars; required if source table provided | getDatabases endpoint | Automated mode only |
| 5 | Source Table | Text input (or AJAX picker) | No | Max 60 chars; required if source column provided | getTables endpoint | Automated mode only |
| 6 | Source Column | Text input (or AJAX picker) | No | Max 60 chars; required if source table provided | getColumns endpoint | Automated mode only |
| 7 | Description | Text area | No | Max 255 chars | — | Tooltip in canvas picker |

**Actions:** Create, Edit, Soft-Delete, Restore, Hard-Delete, Toggle Status
**Filters:** Search by name/description; Category filter; Mode filter (Automated/Manual)
**Cross-field validation:** Source Table and Source Column must be both set or both empty (BR-010)
**Empty state:** "No variables found for this category."
**Permissions:** School Administrator — full (CRUD + introspection endpoints); Principal — view
**Security note:** Source Database / Source Table / Source Column introspection endpoints (AJAX) must be restricted to Super Admin (see NFR-TMP-S-002)

---

### Screen 4: Templates Tab (Designer)

**Purpose:** Design and manage HTML/CSS document layout templates.
**Route:** `/template/templates-tabs?tab=template_list`; `/template/create`; `/template/{id}/edit`

| # | Field | Control | Required | Validation | Options Source | Notes |
|---|---|---|---|---|---|---|
| 1 | Display Name | Text input | Yes | Max 100 chars | — | — |
| 2 | Machine Code | Text input | Yes | Max 50 chars; unique | — | Immutable after first activation recommended |
| 3 | Category | Dropdown | Yes | Active template types | tmp_templates_type | Filters variable picker |
| 4 | Description | Text area | No | — | — | — |
| 5 | Background Image | File input | No | JPEG / PNG; max 2 MB | — | Upload via separate AJAX endpoint |
| 6 | Canvas JSON | Hidden / canvas editor | No | Valid JSON | — | Element positions for drag-drop editor |
| 7 | HTML Content | Rich text / code area | Yes | Non-empty string | — | Contains {{placeholder}} markers |
| 8 | Mapped Variables | Multi-select / picker | No | Active variables matching category | tmp_template_variables | Min 1 required before activation |
| 9 | Default Values | Per-variable text inputs | No | Max 255 per field | — | Junction default value |
| 10 | Active | Toggle / Checkbox | No | Boolean; requires ≥1 variable | — | Default: Draft (inactive) |

**Actions:** Create, Edit, Preview Sample, Soft-Delete, Restore, Hard-Delete, Toggle Status, Upload Background Image
**Filters:** Search by name/code/description/category; Status filter (Active/Draft/Trashed)
**Empty state:** "No templates yet. Create your first layout."
**Additional screens:** Trash list; Preview (read-only rendered HTML)
**Permissions:** School Administrator — full; Principal — view + preview
**Business Rule Guards:** Activation requires ≥1 variable (BR-001); hard-delete blocked if active assignments (BR-017); soft-delete cascades assignments (BR-016)

---

### Screen 5: Template Assignments Tab

**Purpose:** Link active templates to purposes for academic sessions with scope targeting.
**Route:** `/template/templates-tabs?tab=assignment_list`; `/assignments/create`; `/assignments/{id}/edit`

| # | Field | Control | Required | Validation | Options Source | Notes |
|---|---|---|---|---|---|---|
| 1 | Choose Template | Dropdown | Yes | Active templates only | tmp_templates where is_active=1 | — |
| 2 | Associated Purpose | Dropdown | Yes | Active purposes | tmp_template_purposes | Scope type drives field visibility below |
| 3 | Academic Session | Dropdown | Yes | Active sessions | sch_org_academic_sessions_jnt | Default: current session |
| 4 | Scope Level | Radio group | Yes | School-Wide / Class Group / Specific Class | Static | Default: School-Wide |
| 5 | Target Class Group | Dropdown | Conditional (if Group) | Active class groups | msh_class_groups | Visible only when scope = Class Group; hidden if purpose is SCHOOL_WIDE |
| 6 | Target Class | Dropdown | Conditional (if Class) | Active classes | sch_classes | Visible only when scope = Specific Class; hidden if purpose is SCHOOL_WIDE |
| 7 | Active | Toggle | No | Boolean | — | Default: Active |

**Actions:** Create, Edit, Soft-Delete, Restore, Hard-Delete, Toggle Status
**Filters:** Academic Session filter; Purpose filter
**Empty state:** "No assignments yet. Assign a template to a purpose and session."
**Permissions:** School Administrator — full; Principal — view
**Business Rule Guards:** Mutual exclusion (BR-012 — must REJECT, not silently resolve); scope-hash uniqueness (BR-013); SCHOOL_WIDE purpose blocks class/group (BR-014)
**Scope Identifier formula:** `purpose_id : academic_session_id : C{class_id} | G{class_group_id} | SCHOOL`

---

## Section 9 — Module Knowledge Update Summary

This Complete Analysis Pack was produced 2026-06-30 by the Business Analyst agent. The module knowledge file at `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/TMP_Template.md` must be updated with the following FRD summary block:

**FRD Summary (to add to module knowledge):**
- FRD file: `TMP_FRD_2026-06-30.md`
- Complete pack: `TMP_FRD_Complete_2026-06-30.md`
- Date: 2026-06-30
- REQ count: 12 (P0: 9, P1: 3, P2: 0)
- BR count: 21 (DONE: 4, PARTIAL: 6, NOT ENFORCED: 5, NOT VERIFIED: 6)
- Workflow count: 7
- RPT count: 1
- ENH count: 6
- User Stories: 12 (one per P0/P1 REQ)
- Sprint tasks: 31 tasks across 3 sprints; ~68 h total gap effort
- Overall estimated completion after sprint 3: ~95%

**Critical P0 gaps confirmed by this analysis:**
1. BR-001 not enforced: activation guard missing
2. BR-015 Step 2 not implemented: class group fallback in engine
3. BR-016/BR-017 not enforced: cascade and hard-delete block missing
4. BR-007 update() not guarded: system purpose code/scope_type can be changed
5. BR-009/BR-010 not enforced in FormRequest: variable naming and partial-mapping validation missing
6. EnsureTenantHasModule missing from all routes
7. DB schema introspection endpoints exposed to all tenant users

**Next steps (post-FRD handoffs):**
1. DB Architect: verify value_type column in migration; confirm scope_hash index covers engine query pattern
2. Technical Auditor: deep audit TemplateTypeController, TemplatePurposeController cascade logic, TemplateController forceDelete, assignment mutual exclusion handling
3. Status Analyzer: 6-dimension completion scoring with evidence from Section 10.2
4. Testing Architect: test strategy from Section 6.2 Sprint 3 + Section 7.1 user story acceptance criteria
