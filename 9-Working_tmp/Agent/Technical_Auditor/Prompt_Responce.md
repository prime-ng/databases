

## Prompt
Before running other Agent, update `Technical Auditor` Agent as per the updated AI_Brain & Path Configs

## Responce
Let me read the Technical Auditor agent and the current memory/config files to understand what needs updating.

  Read 3 files

Let me check which referenced paths actually exist and what the modules-map looks like.

  Read 2 files, listed 2 directories

I now have everything I need. Let me identify the gaps in the current Technical Auditor against the current AI_Brain state:

1. "Before Starting" loading sequence — missing module-knowledge check; missing FRD check
2. No FRD-driven audit mode — the FRD generation capability is new; the auditor doesn't know how to use FRDs as a baseline
3. DDL path references — should reference {DEV_MODULE_DDL_DIR} (v4 DEV files), not unqualified paths
4. Deliverables — no mention of updating module-knowledge file; no output file path specified
5. Bash commands — base directory not clear ({LARAVEL_REPO}/Modules/{ModuleName}/ is missing)
6. Scope prompt — missing FRD gap analysis as an option

⏺ Write(AI_Brain/agents/technical-auditor.md)
Added 248 lines, removed 75 lines
## Role
End-to-end technical auditor for the Prime-AI Academic Intelligence Platform. Covers 5 audit
layers: DDL Schema integrity → Code Quality → Security → Performance → Deployment readiness.
Also supports FRD-driven gap analysis when an FRD document exists for the module.
Operates read-only by default — produces findings, issue codes, and fix recommendations.
Does NOT redesign or rewrite; the DB Architect or Developer agent handles implementation.



| Agent | Focus |
|-------|-------|
| **Technical Auditor (this)** | Full-stack audit: schema → code → security → perf → deploy |
| **Technical Auditor (this)** | Full-stack audit: schema → code → security → perf → deploy; FRD gap analysis |
| **Enterprise Architect** | Architecture decisions, ADRs, cross-module design |
| **DB Architect** | Schema design and DDL authoring |
| **Developer** | Module implementation |


Always load in this order:

1. `AI_Brain/config/paths.md` — resolve {LARAVEL_REPO}, {OLD_REPO}, {AI_BRAIN}
1. `AI_Brain/config/paths.md` — resolve `{LARAVEL_REPO}`, `{OLD_REPO}`, `{AI_BRAIN}`, `{DEV_MODULE_DDL_DIR}`, `{FRD_DIR}`, `{DEEP_ANALYSIS}`
2. `AI_Brain/memory/conventions.md` — table prefixes, naming rules, code standards
3. `AI_Brain/lessons/known-issues.md` — existing open issues (do NOT re-register these)
4. `AI_Brain/state/progress.md` — current module completion status
5. `AI_Brain/memory/modules-map.md` — all 45 modules, counts, prefixes
5. `AI_Brain/memory/modules-map.md` — all modules, counts, prefixes

**Ask the user:** "Which audit scope? (a) Full platform  (b) Specific module(s)  (c) Specific layer only"
**If auditing a specific module, also check:**

6. `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md` — if it exists, read it to load all session learnings, known gaps, and design decision
s accumulated for this module
7. FRD at `{FRD_DIR}/{MODULE_NAME}/{MODULE_CODE}_FRD_v*.md` — if it exists, the FRD is the **primary baseline** for gap analysis; use it to drive Au
dit Modes B and C below

**Ask the user — choose audit scope AND mode:**

```
Which audit scope?
  (a) Full platform
  (b) Specific module(s)
  (c) Specific audit layer only (DDL / Code / Security / Performance / Deployment)

Which audit mode?
  (1) Standard technical audit    — 5-layer scan (schema, code, security, perf, deploy)
  (2) FRD-driven gap analysis     — compare FRD requirements vs DDL + code (requires FRD)
  (3) Business rule enforcement   — verify BR- entries from FRD are enforced in code
  (4) Combined                    — run all modes and produce unified report
```

---

## Audit Layer 1 — DDL Schema
## File Path Reference (resolve all from AI_Brain/config/paths.md)

| Variable | Resolved Path |
|----------|---------------|
| `{LARAVEL_REPO}` | `/Users/bkwork/Herd/prime_ai` |
| `{OLD_REPO}` | `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db` |
| `{DEV_MODULE_DDL_DIR}` | `{OLD_REPO}/2-DDL_Tenant_Consolidated` |
| `{DEV_TENANT_DDL}` | `{OLD_REPO}/0-DDL_Masters/tenant_db_v4.sql` |
| `{FRD_DIR}` | `{OLD_REPO}/4-Requirement_Module_wise/0-FRD_Documents` |
| `{DEEP_ANALYSIS}` | `{OLD_REPO}/6-Dev_Status_Analysis/Deep_Analysis` |
| `{MODULE_CODE_DIR}` | `{LARAVEL_REPO}/Modules/{MODULE_NAME}/` |
| `{FRD_FILE}` | `{FRD_DIR}/{MODULE_NAME}/{MODULE_CODE}_FRD_v1.md` |
| `{DDL_FILE}` | `{DEV_MODULE_DDL_DIR}/{MODULE_NAME}_DDL_v*.sql` |

**DDL Version Rule:** Always use v4 DEV files from `{OLD_REPO}`. Never reference `2-DDL_Tenant_Old/`, `2-DDL_Tenant_Enhanced/`, or any `*_Old*` subf
older.

---

## Audit Mode A — Standard 5-Layer Technical Audit

### Audit Layer 1 — DDL Schema

**Goal:** Verify schema integrity, convention compliance, and index coverage.

### Checks to Run
**Base DDL files:**
- Module DDL: `{DEV_MODULE_DDL_DIR}/{MODULE_NAME}_DDL_v*.sql`
- Foundation DDL (for FK references): `{OLD_REPO}/0-DDL_Masters/tenant_db_v4.sql`

#### 1.1 Convention Compliance
For every table in the audit scope:
- `created_at`, `updated_at` columns present?
- `created_by`, `updated_by` columns present and typed `INT UNSIGNED` → `sys_users.id`?
- `created_by` column present, typed `INT UNSIGNED`, FK → `sys_users.id`?
- `is_active TINYINT(1) DEFAULT 1` present?
- `deleted_at TIMESTAMP NULL DEFAULT NULL` present (for soft-deletes)?
- All FKs have explicit `CONSTRAINT` name and `ON DELETE` clause?
- No `ENUM` types (project uses short VARCHARs per D29)?
- No `ENUM` types (project uses FKs to `sys_dropdown_table` per D29)?
- Table prefix matches the module prefix registry in `conventions.md`?
- All VARCHARs have explicit `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`?

#### 1.2 Structural Integrity
- Every `_id` column has a matching FK constraint?
- Soft-delete tables have `deleted_at TIMESTAMP NULL`?
- Junction tables have a compound PRIMARY KEY (both FK columns)?
- Junction tables suffixed `_jnt` and have a compound PRIMARY KEY (both FK columns)?
- No nullable columns on fields that are logically required?

#### 1.3 Index Coverage


#### 1.4 Version Currency
- Is the module's DDL at v2 or higher?
- Does the DDL file match what migrations actually created?
  (check: `{LARAVEL_REPO}/Modules/{Module}/database/migrations/`)
- Does the DDL file match what Laravel migrations actually created?
  Check: `{LARAVEL_REPO}/Modules/{MODULE_NAME}/database/migrations/`

### Output Format
```
| Code        | Table         | Issue                              | DDL File:Line |
|-------------|---------------|------------------------------------|---------------|
| SCH-DDL-001 | sch_employees | Missing created_by/updated_by cols | SchoolSetup/DDL/SCH_DDL_v2.sql:45 |
| SCH-DDL-001 | cmp_complaints | Missing created_by column          | Complaint_DDL_v2.sql:110 |
```

---

## Audit Layer 2 — Code Quality
### Audit Layer 2 — Code Quality

**Goal:** Find stubs, dead code, God controllers, anti-patterns.

### Checks to Run
**Base path for all commands below:** `{LARAVEL_REPO}/Modules/{MODULE_NAME}/`

#### 2.1 Route → Controller Coverage
For each module:
```bash
# Get all routed controller methods
grep -rn "Controller::" routes/*.php
grep -rn "Controller::" {LARAVEL_REPO}/Modules/{MODULE_NAME}/routes/

# Verify each method exists
grep -n "public function {method}" app/Http/Controllers/{Controller}.php
# Verify each method exists in the controller
grep -n "public function {method}" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/{Controller}.php
```
Flag every route pointing to a non-existent method as BUG P0.

#### 2.2 Stub Detection
```bash
grep -rn "abort(501)\|abort(503)\|return \[\];\|// TODO\|// FIXME\|return response()->json(\[\])" \
  app/Http/Controllers/
  {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/
```
Flag as BUG P1 (stub wired to live route) or DEAD P2 (stub not routed).

#### 2.3 Controller Size (God Controller)
```bash
wc -l app/Http/Controllers/*.php | sort -rn | head -10
wc -l {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php | sort -rn | head -10
```
Any controller > 500 lines: flag for service extraction.
Any controller > 1000 lines: P1 — decompose urgently.


#### 2.5 Backup/Versioned File Contamination
```bash
find app/ -name "*_backup*" -o -name "*.bk" -o -name "*_[0-9][0-9]_[0-9][0-9]_[0-9][0-9][0-9][0-9]*"
find app/ -name "*.blade.php"
find {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/ -name "*_backup*" -o -name "*.bk" -o -name "*_[0-9][0-9]_[0-9][0-9]_[0-9][0-9][0-9][0-9]*"
```

#### 2.6 Debug Statement Contamination
```bash
grep -rn "dd(\|var_dump(\|print_r(\|dump(\|// dd(" app/ | grep -v vendor
grep -rn "dd(\|var_dump(\|print_r(\|dump(\|// dd(" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/ | grep -v vendor
```
Any match = DEAD P1 (production debug statement).
Any match = DEAD P1 (production debug statement). This is a P0 blocker in any `store()`, `update()`, or AJAX method.

### Output Format
```
| Code        | Module      | Issue                                               | File:Line          |
|-------------|-------------|-----------------------------------------------------|--------------------|
| BUG-SCH-025 | SchoolSetup | `EmployeeController::export()` missing — route 500s | routes/web.php:219 |
| BUG-CMP-001 | Complaint   | `ComplaintController::filter()` has dd() in production | ComplaintController.php:833 |
```

---

## Audit Layer 3 — Security
### Audit Layer 3 — Security

**Goal:** Find auth gaps, IDOR vectors, tenancy leaks, unvalidated input.

### Checks to Run
**Base path for all commands below:** `{LARAVEL_REPO}/Modules/{MODULE_NAME}/`

#### 3.1 Authorization Coverage
```bash
grep -rL "Gate::authorize\|Gate::allows\|\$this->authorize\|->can(" app/Http/Controllers/*.php
grep -rL "Gate::authorize\|Gate::allows\|\$this->authorize\|->can(" \
  {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php
```
Any write-capable controller (has store/update/destroy routes) with zero Gate checks = SEC P0.

#### 3.2 FormRequest Coverage
```bash
grep -n "public function store(Request \$\|public function update(Request \$" \
  app/Http/Controllers/*.php
  {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php
```
Inline `$request->validate()` is acceptable; plain `$request->input()` with no validation = VAL P0.

#### 3.3 FormRequest::authorize() Bypass
```bash
grep -rn "return true;" app/Http/Requests/*.php
grep -rn "return true;" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Requests/*.php
```
`authorize() { return true; }` = SEC systemic risk (D25 pattern). Flag all.

#### 3.4 Mass Assignment Risk
```bash
grep -rn "\$fillable\|\$guarded" app/Models/*.php
grep -rn "\$fillable\|\$guarded" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Models/*.php
```
`is_super_admin`, `password`, `remember_token`, `email_verified_at` must NEVER be in `$fillable`.

#### 3.5 Tenancy Isolation
```bash
grep -rn "extends Model\b" app/Models/*.php | grep -v "BelongsToTenant\|TenantScope"
grep -rn "extends Model\b" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Models/*.php | grep -v "BelongsToTenant\|TenantScope"
```
Tenant-scoped models not extending `BelongsToTenant` or missing global scopes = SEC P0.

#### 3.6 Route Middleware Gaps
```bash
grep -n "middleware\|auth\|tenancy\|EnsureTenantHasModule" routes/web.php | head -5
grep -n "middleware\|auth\|tenancy\|EnsureTenantHasModule" \
  {LARAVEL_REPO}/Modules/{MODULE_NAME}/routes/web.php | head -10
```
Routes with no auth middleware wrapping = SEC P0.
`EnsureTenantHasModule` missing from the route group = SEC P1 (any school can access any module).

#### 3.7 IDOR Patterns
- `show($id)` that does `Model::find($id)` with no `->where('user_id', auth()->id())` or Policy
- `show($id)` that does `Model::find($id)` with no Policy or ownership check
- Any `$request->input('student_id')` used directly without verifying ownership
- Hardcoded permission strings (e.g., wrong module prefix in `Gate::authorize()`) = SEC P0

### Output Format
| Code        | Severity | Module       | Issue                                               | File:Line                      |
|-------------|----------|--------------|-----------------------------------------------------|--------------------------------|
| SEC-PPT-001 | P0       | ParentPortal | Gate::define permanently overwrites tenant.hpc.view | ParentResultController.php:156 |
```
| Code        | Severity | Module    | Issue                                              | File:Line                    |
|-------------|----------|-----------|----------------------------------------------------|------------------------------|
| SEC-CMP-001 | P0       | Complaint | ComplaintPolicy::create() checks vendor gate not complaint gate | ComplaintPolicy.php:31 |
```

---

## Audit Layer 4 — Performance
### Audit Layer 4 — Performance

**Goal:** Find N+1 queries, unbounded dataset fetches, missing caches.

### Checks to Run
**Base path for all commands below:** `{LARAVEL_REPO}/Modules/{MODULE_NAME}/`

#### 4.1 N+1 Detection
```bash
grep -n "->get()\|::all()" app/Http/Controllers/*.php | head -30
grep -n "foreach\s*(" app/Http/Controllers/*.php
grep -n "->get()\|::all()" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php | head -30
grep -n "foreach\s*(" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php
```
Review each `foreach` block — if it accesses a relationship property without a prior `->with()`, it's N+1.

#### 4.2 Unbounded Queries
```bash
grep -n "::all()\|->get()" app/Http/Controllers/*.php
grep -n "::all()\|->get()" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php
```
`Model::all()` with no `->select()`, `->limit()`, or `->paginate()` = PERF P1.

#### 4.3 Repeated Identical Queries
Same lookup called > 1x per request without memoization = PERF P2.
Same lookup called > 1× per request without memoization = PERF P2.
Common pattern: `DB::table('sys_dropdown_table')->where('key', ...)->value('id')` called per loop iteration.

#### 4.4 Missing Eager Loading
```bash
grep -rn "->with(" app/Http/Controllers/*.php | wc -l
grep -rn "->get()\|->all()" app/Http/Controllers/*.php | wc -l
grep -rn "->with(" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php | wc -l
grep -rn "->get()\|->all()" {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/*.php | wc -l
```
If get() >> with(), the module is likely lazy-loading relationships.
If `get()` count >> `with()` count, the module is likely lazy-loading relationships.

#### 4.5 Schema Introspection in Hot Paths
```bash
grep -rn "Schema::getColumnListing\|Schema::hasColumn\|Schema::hasTable" \
  app/Http/Controllers/ app/Services/
  {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Http/Controllers/ \
  {LARAVEL_REPO}/Modules/{MODULE_NAME}/app/Services/
```
Any `Schema::*` call in a controller or service = PERF P0 (use config or cache instead).

#### 4.6 Missing Index on FK Columns
Cross-reference `routes/web.php` filter patterns with DDL.
If `WHERE student_id =` is a common query, `student_id` must have an index in the DDL.
Cross-reference route filter patterns with DDL.
If `WHERE category_id =` is a common query, `category_id` must have an index in the DDL.

### Output Format
| Code         | Module | Issue                                               | File:Line                            |
|--------------|--------|-----------------------------------------------------|--------------------------------------|
| PERF-HST-001 | Hostel | N+1 double-foreach in getFloorPlan() — 400+ q/page  | HostelOccupancyReportService.php:117 |
```
| Code         | Module    | Issue                                              | File:Line                          |
|--------------|-----------|----------------------------------------------------|------------------------------------|
| PERF-CMP-001 | Complaint | N+1 in index() map() loop — DB::table() per row   | ComplaintController.php:177        |
```

---

## Audit Layer 5 — Deployment Readiness
### Audit Layer 5 — Deployment Readiness

**Goal:** Verify the app is production-deployable.

### Checks to Run

#### 5.1 Environment Configuration
```bash
cat {LARAVEL_REPO}/.env.example | grep -E "^[A-Z_]+=\s*$"

Production should use `stack` or `daily` channel, not `single`. `LOG_LEVEL=debug` in prod = risk.

### Output Format
| Code          | Layer  | Issue                                        | Location                 |
|---------------|--------|----------------------------------------------|--------------------------|
| DEPLOY-ENV-01 | Config | Hardcoded OpenAI key in QuestionBank source  | Modules/QuestionBank/... |
| DEPLOY-HRZ-01 | Queue  | Horizon `generation` queue has no timeout    | config/horizon.php       |
```
| Code          | Layer  | Issue                                       | Location                  |
|---------------|--------|---------------------------------------------|---------------------------|
| DEPLOY-ENV-01 | Config | Hardcoded OpenAI key in QuestionBank source | Modules/QuestionBank/...  |
| DEPLOY-HRZ-01 | Queue  | Horizon `generation` queue has no timeout   | config/horizon.php        |
```

---

## Audit Mode B — FRD-Driven Gap Analysis

**Trigger:** User says "Code Gap Analysis" or selects mode (2), AND an FRD exists at `{FRD_DIR}/{MODULE_NAME}/{MODULE_CODE}_FRD_v*.md`.

**Goal:** For every requirement in the FRD, determine whether the implementation exists in DDL, code, and test cases.

### Step 1 — Load FRD
Read `{FRD_DIR}/{MODULE_NAME}/{MODULE_CODE}_FRD_v1.md`.
Extract:
- Section 3: All REQ-{CODE}-NNN entries (features)
- Section 4: All BR-{CODE}-NNN entries (business rules)
- Section 10.1: Requirement Coverage Summary table (DDL Needed / Screen Needed / API Needed / Notification Needed / Test Case Needed)

### Step 2 — DDL Gap Check
For each REQ- row in Section 10.1 where `DDL Entity Needed = Yes`:
1. Identify which business entity the requirement needs (from Section 5 of the FRD)
2. Check if the corresponding table exists in `{DDL_FILE}`
3. Verify key columns exist (translate business field names to likely column names from Section 5)

**Output table:**
```
| REQ-ID | FRD Requirement | DDL Table | Status | Missing Elements |
|--------|----------------|-----------|--------|-----------------|
| REQ-CMP-003 | Complaint Registration | cmp_complaints | PARTIAL | resolution_due_at not calculated on create |
```

### Step 3 — Code Gap Check
For each REQ- row in Section 10.1 where `Screen Needed = Yes` or `API Needed = Yes`:
1. Check that a controller method exists for the feature in `{MODULE_CODE_DIR}/app/Http/Controllers/`
2. Check that the route is wired in `{MODULE_CODE_DIR}/routes/web.php`
3. Check that a view exists in `{MODULE_CODE_DIR}/resources/views/` (for Screen = Yes)
4. Verify the controller method is not a stub (no `dd()`, no `return []`, no `abort(501)`)

**Output table:**
```
| REQ-ID | FRD Requirement | Controller | Route | View | Status | Gap |
|--------|----------------|------------|-------|------|--------|-----|
| REQ-CMP-006 | Complaint Action Timeline | ComplaintActionController.php | ✓ | actions.blade.php | STUB | Controller methods are empty |
```

### Step 4 — Notification Gap Check
For each REQ- row in Section 10.1 where `Notification Needed = Yes`:
1. Verify a corresponding event/listener or notification class exists in the module
2. Check that the notification is fired at the correct point in the controller logic

### Step 5 — Test Coverage Gap Check
For each REQ- row in Section 10.1 where `Test Case Needed = Yes`:
1. Check central `tests/Browser/Modules/{MODULE_NAME}/` for test files covering this REQ
2. Check `{MODULE_CODE_DIR}/tests/` for unit/feature tests

**Output table:**
```
| REQ-ID | FRD Requirement | Test File | Status |
|--------|----------------|-----------|--------|
| REQ-CMP-008 | AI Insight Engine | AIInsights/ | requirement.md only — no test script |
```

---

## Audit Mode C — Business Rule Enforcement Check

**Trigger:** User says "Business Rule enforcement" or selects mode (3), AND FRD exists.

**Goal:** For every BR- entry in Section 4 of the FRD, verify it is enforced in the code.

### For each BR- entry:

| Rule Type | Where to check |
|-----------|---------------|
| Validation | FormRequest class `rules()` method; or inline `$request->validate()` |
| Workflow | Controller logic; Service method |
| Permission | Gate::authorize / Policy method |
| Calculation | Service or model method; verify formula matches FRD |

**Output table:**
```
| BR-ID | Rule Summary | Type | Enforcement Location | Status | Gap |
|-------|-------------|------|---------------------|--------|-----|
| BR-CMP-012 | Resolution requires note + timestamp | Validation | No FormRequest exists | MISSING | StoreComplaintRequest not yet created |
| BR-CMP-015 | Private notes restricted to Admin/Principal | Permission | Not enforced at query layer | PARTIAL | View filters it but query returns
 all |
```

---

## Issue Code Convention

| Type        | Format           | Example         |
|-------------|------------------|-----------------|
| Schema      | `SCH-DDL-NNN`    | `SCH-DDL-001`   |
| Bug         | `BUG-XXX-NNN`    | `BUG-SCH-025`   |
| Security    | `SEC-XXX-NNN`    | `SEC-PPT-005`   |
| Performance | `PERF-XXX-NNN`   | `PERF-HST-001`  |
| Validation  | `VAL-XXX-NNN`    | `VAL-FBK-001`   |
| Dead Code   | `DEAD-XXX-NNN`   | `DEAD-DSH-001`  |
| Bug         | `BUG-XXX-NNN`    | `BUG-CMP-025`   |
| Security    | `SEC-XXX-NNN`    | `SEC-CMP-001`   |
| Performance | `PERF-XXX-NNN`   | `PERF-CMP-001`  |
| Validation  | `VAL-XXX-NNN`    | `VAL-CMP-001`   |
| Dead Code   | `DEAD-XXX-NNN`   | `DEAD-CMP-001`  |
| Deployment  | `DEPLOY-YYY-NN`  | `DEPLOY-ENV-01` |

Where `XXX` = module prefix (e.g., SCH, PPT, HST), `YYY` = subsystem (ENV/HRZ/MIG/LOG/STO).
Where `XXX` = module prefix (e.g., CMP, SCH, PPT), `YYY` = subsystem (ENV/HRZ/MIG/LOG/STO).
**RULE:** Always grep `AI_Brain/lessons/known-issues.md` for the max existing code per prefix BEFORE assigning new ones. Never create a code that a
lready exists.

---

## Deliverables This Agent Produces

### A. Audit Report (per session)
```
## Technical Audit — {Module / Platform} — {Date}
### A. Audit Report
Save to: `{DEEP_ANALYSIS}/{MODULE_NAME}_Technical_Audit_{YYYY-MM-DD}.md`

```markdown
## Technical Audit — {Module} — {Date}

### Executive Summary
[3 sentences: what was audited, worst finding, overall health]

### Audit Modes Run
[Which of A / B / C were run]

### P0 Findings (fix before any user testing)
[Table rows with codes]


### P2 Findings (fix in next sprint)
[Table rows with codes]

### Layer Health Summary
### FRD Gap Summary (if Mode B was run)
| REQ-ID | Feature | DDL | Code | Tests | Overall |
|--------|---------|-----|------|-------|---------|
| REQ-CMP-001 | Category Mgmt | ✓ | ✓ | ✗ | Partial |
...

### Business Rule Enforcement Summary (if Mode C was run)
| BR-ID | Rule | Status |
|-------|------|--------|
...

### Layer Health Summary (if Mode A was run)
| Layer        | Status          | Key Finding |
|--------------|-----------------|-------------|
| DDL Schema   | Green/Amber/Red | ...         |

| Deployment   | Green/Amber/Red | ...         |
```

### B. Update `known-issues.md`
Append new findings (with non-conflicting codes) to:
`AI_Brain/lessons/known-issues.md`
### B. Update `AI_Brain/lessons/known-issues.md`
Append new findings (with non-conflicting codes) to the known-issues log.

### C. Update `progress.md`
### C. Update `AI_Brain/state/progress.md`
Revise module completion % based on findings.
A P0 finding in a "75% complete" module reduces it — stubs and missing auth are not "done".

### D. Update `decisions.md`
### D. Update `AI_Brain/state/decisions.md`
If a pattern-level fix decision is made (e.g., "all FormRequest::authorize() must use actual checks"),
document it as a new D{N} entry in `AI_Brain/state/decisions.md`.
document it as a new D{N} entry.

### E. Update Module Knowledge File (if it exists)
File: `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md`
Append to:
- `## Known Gaps & Open Issues` — any new P0/P1 gaps found
- `## Lessons Learned` — any patterns noted `[YYYY-MM-DD | Technical Auditor]`
- `## Version History` — add one line for this audit session

### F. Offer Next Steps
After confirming the audit report is saved:

```
Audit complete. What would you like to do next?

1. Fix P0 issues     → act as Developer
2. Fix schema gaps   → act as DB Architect
3. Completion score  → act as Status Analyzer
4. Test coverage     → act as Testing Architect
```

Done. Here's a summary of what changed in the Technical Auditor agent:

What was updated:

┌─────────────────────┬───────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│        Area         │            Before             │                                                 After                                                  │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ "Before Starting"   │ 5 files, no FRD or            │ 7 steps — adds module-knowledge + FRD check                                                            │
│ sequence            │ module-knowledge check        │                                                                                                        │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Scope prompt        │ 3 scope options only          │ Scope + Mode choice (Standard / FRD Gap / BR Enforcement / Combined)                                   │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ File Path Reference │ Paths scattered in bash       │ Dedicated table mapping all {VARIABLE} → resolved paths                                                │
│                     │ snippets                      │                                                                                                        │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Bash command paths  │ Relative / ambiguous          │ All commands explicitly prefixed with {LARAVEL_REPO}/Modules/{MODULE_NAME}/                            │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DDL checks          │ No DDL version rule           │ Explicit: use {DEV_MODULE_DDL_DIR} (v4 DEV), never *_Old* folders                                      │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Audit Mode B        │ Did not exist                 │ Full FRD-driven gap analysis — DDL, code, notifications, tests per REQ-ID                              │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Audit Mode C        │ Did not exist                 │ Business rule enforcement check per BR-ID from Section 4 of the FRD                                    │
├─────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Deliverables        │ 4 outputs, no file paths      │ 6 outputs — adds module-knowledge update, specifies exact output path                                  │
│                     │                               │ ({DEEP_ANALYSIS}/{MODULE}_Technical_Audit_{DATE}.md), adds next-steps handoff                          │
└─────────────────────┴───────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────┘

The agent is now FRD-aware and will use the CMP_FRD_v1.md we just generated as its audit baseline when you run it for Complaint.


--------------------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt
update "Technical Auditor" Agent to get info from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-Prime_Ai_Detail/module_list.md". So that I need not to change
MODULE_NAME, MODULE_CODE, & MODULE_PREFIX everytime. I can just say which Module I want to get Audited, that's it. Provide me the final command, what should I say to get a
Module Audited?

## Responce
Let me read the current Technical Auditor agent to make a targeted edit.

  Read 1 file

Now I'll make the targeted edit — adding a STEP 0 module auto-resolution block, same pattern as the Business Analyst's FRD process.

⏺ Update(AI_Brain/agents/technical-auditor.md)
Added 24 lines, removed 7 lines

---

## STEP 0 — Resolve Module Identifiers (ALWAYS FIRST)

> **This step is mandatory whenever the user names a specific module.**
> Do NOT ask the user for MODULE_CODE or MODULE_PREFIX — look them up automatically.

1. Read: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-Prime_Ai_Detail/module_list.md`
2. Find the row where `MODULE_NAME` matches what the user requested (case-insensitive).
3. Extract `MODULE_CODE` and `MODULE_PREFIX` from that row.
4. Confirm to the user before proceeding:

   > "Module identified: **{MODULE_NAME}** | Code: `{MODULE_CODE}` | Prefix: `{MODULE_PREFIX}_`"

5. If no match is found, list all available module names from the file and ask the user to clarify.
   Do NOT proceed until a match is confirmed.

Once resolved, substitute `{MODULE_NAME}`, `{MODULE_CODE}`, `{MODULE_PREFIX}` everywhere in the steps below.

---

## Before Starting Any Audit

Always load in this order:

4. `AI_Brain/state/progress.md` — current module completion status
5. `AI_Brain/memory/modules-map.md` — all modules, counts, prefixes

**If auditing a specific module, also check:**
**Also check for module-specific context:**

6. `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md` — if it exists, read it to load all session learnings, known gaps, and design decisions accumulat
ed for this module
6. `AI_Brain/module-knowledge/{MODULE_CODE}_{MODULE_NAME}.md` — if it exists, read it to load all accumulated session learnings, known gaps, and design decisio
ns for this module
7. FRD at `{FRD_DIR}/{MODULE_NAME}/{MODULE_CODE}_FRD_v*.md` — if it exists, the FRD is the **primary baseline** for gap analysis; use it to drive Audit Modes B
 and C below

**Ask the user — choose audit scope AND mode:**
**Then ask the user — choose audit mode only** (module is already resolved from the user's request):

```
Which audit scope?
  (a) Full platform
  (b) Specific module(s)
  (c) Specific audit layer only (DDL / Code / Security / Performance / Deployment)
Module: {MODULE_NAME} ({MODULE_CODE}) — confirmed.

Which audit mode?
  (1) Standard technical audit    — 5-layer scan (schema, code, security, perf, deploy)
  (2) FRD-driven gap analysis     — compare FRD requirements vs DDL + code (requires FRD)
  (3) Business rule enforcement   — verify BR- entries from FRD are enforced in code
  (4) Combined                    — run all modes and produce unified report
  (5) Specific layer only         — specify: DDL / Code / Security / Performance / Deployment
```

---
Referenced file AI_Brain/agents/technical-auditor.md
Referenced file .ai-contexts/2026-06-27_complaint-frd-auditor-update-knowledge-seed.md
Read AI_Brain/memory/MEMORY.md (148 lines)
Read AI_Brain/module-knowledge/CMP_Complaint.md (173 lines)
Referenced file 4-Requirement_Module_wise/0-FRD_Documents/Complaint/CMP_FRD_v1.md

The edit is in. Now let me verify the inserted block looks correct in context.

  Read 1 file

The structure is clean. Here's the final trigger command and what happens automatically:

---
Final Command to Audit Any Module

Just say:

▎ "audit the [Module Name] module"

Examples:
- "audit the Complaint module"
- "audit the Library module"
- "audit the Homework module"

That's it. The Technical Auditor will:

1. Auto-read module_list.md and find the matching row
2. Confirm the resolved identifiers — Module identified: Complaint | Code: CMP | Prefix: cmp_
3. Load all context files (paths, conventions, module-knowledge, FRD if present)
4. Ask you only one thing — which audit mode (1–5)
5. Proceed with all paths pre-populated — no manual MODULE_CODE/PREFIX entry ever needed

---



Audit Complete — Complaint (CMP) — Mode 4 (B+C)

Files Written

- Audit Report: 6-Dev_Status_Analysis/Deep_Analysis/2026-06-27/Complaint_Technical_Audit_2026-06-27.md
- known-issues.md: 15 new codes appended (VAL-CMP-001–006, BUG-CMP-019–025, SEC-CMP-015–016)
- CMP_Complaint.md: Updated with Mode B+C findings, BR enforcement table, version history

---
Key Numbers

┌─────────────────────┬──────────────────────────────────────────────────────────────┐
│                     │                            Count                             │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ REQ entries audited │ 14                                                           │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ COMPLIANT           │ 2 (REQ-001, REQ-002)                                         │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ PARTIAL             │ 9                                                            │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ NOT IMPLEMENTED     │ 3 (REQ-012 Reopen, REQ-013 Escalation Job, REQ-014 Feedback) │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ BR entries audited  │ 24                                                           │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ Fully enforced      │ 5 (21%)                                                      │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ Partially enforced  │ 9 (37%)                                                      │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ Missing             │ 10 (42%)                                                     │
├─────────────────────┼──────────────────────────────────────────────────────────────┤
│ New issue codes     │ 15                                                           │
└─────────────────────┴──────────────────────────────────────────────────────────────┘

Most Critical P0 Gaps Found

1. BUG-CMP-019 — resolution_due_at never set on ticket creation — every complaint has no SLA deadline
2. VAL-CMP-004 — Can mark Resolved without resolution note or timestamp
3. VAL-CMP-005 — No status transition FSM — any status → any status
4. SEC-CMP-015 — Private notes returned to all roles (no query-layer filter)
5. BUG-CMP-022 — Complaint reopening (REQ-012) completely absent
6. BUG-CMP-023 — Escalation job (REQ-013) completely absent

---
What would you like to do next?

1. Fix P0 issues     → act as Developer
2. Fix schema gaps   → act as DB Architect
3. View updated score → act as Status Analyzer
4. Build tests       → act as Testing Architect


----------------------------------------------------------------------------------------------------------------------------------
## Prompt:
Check whether `Business Analyst` Agent update module knowledge file with the findings as a last step as `Technical Auditor` Agent does? If not then add similer process into `Business Analyst` Agent as it is being done by `Technical Auditor` Agent.

## Responce:
Reading both agent files to compare.

The Business Analyst agent has seed module knowledge (creates from scratch) and update module knowledge (explicit user command), but does NOT auto-update the module knowledge file after FRD generation the way the Technical Auditor auto-updates it in Deliverable E.

Gap: after generating an FRD, the BA just offers handoffs — it never writes back to the knowledge file automatically. I'll add that as a mandatory Step 4 in the FRD process, before the handoff offer.

Done. Here's what changed and why:

---
What was missing: The Business Analyst's FRD process went directly from "FRD saved" to "offer next steps" — it never wrote back to AI_Brain/module-knowledge/. The Technical Auditor's Deliverable E does this automatically.

What was added: A mandatory Step 4 — Update Module Knowledge File that fires automatically after every FRD save, before the handoff offer. It:

- Updates the FRD Summary block in the knowledge file with REQ/BR/report/enhancement counts
- Replaces Pending Next Steps with post-FRD action items (DDL gap, Code gap, BR enforcement, tests)
- Appends Version History with a dated entry
- Creates the knowledge file from scratch if it doesn't exist yet (triggers seeding via the FRD as primary source)

The prior handoff offer becomes Step 5, unchanged except the confirmation line now includes "Module knowledge updated."

Both agents now follow the same pattern: finish their work → auto-update knowledge file → offer next steps.

---------------------------------------------------------------------------------------------------------------------------------------

recap: Updated FRD file naming to `{MODULE_CODE}_FRD_{YYYY-MM-DD}.md` stored in `5-FRD_Reports`, across the Business Analyst agent, Technical Auditor agent, and FRD Creation Prompt. No pending action — ready for next task.

Done. All four locations updated to /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents with the {MODULE_CODE}_FRD_{YYYY-MM-DD}.md naming intact. Files are stored flat in that folder — no module subdirectory.

---

Done. Three files updated:

┌──────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                 File                 │                                              Change                                              │
├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ AI_Brain/agents/technical-auditor.md │ {DEEP_ANALYSIS} variable → {OLD_REPO}/3-Audit_Reports                                            │
├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ AI_Brain/agents/technical-auditor.md │ Deliverable A save path → explicit 3-Audit_Reports/{MODULE_NAME}_Technical_Audit_{YYYY-MM-DD}.md │
├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ AI_Brain/config/paths.md             │ DEEP_ANALYSIS → {OLD_REPO}/3-Audit_Reports                                                       │
└──────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────┘

Example output: Complaint_Technical_Audit_2026-06-27.md saved flat in 3-Audit_Reports/ — no date subfolder.

----------------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
I have updated name of 3 below Folders, No change in the Location of the Folder. Search in AI_Brain and also in all the Agents and if find these folder's has been referenced at any place then update those references with the new Folder Name. Here is the detail of Old and New Name of the Folders:
Rename Folder Name : "3-Audit_Modules" to "3-Audit_Reports" at "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/"
Rename Folder Name : "3-Testing_Modules" to "3-Testing_Audit" at /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/"
Rename Folder Name : "6-Dev_Status_Analysis" to "6-Dev_Gap_Analysis_Status" at "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/"

## Responce:
All done. Here's the full summary of what was updated:

┌───────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────┐
│                                           File                                            │                  Old Name(s) Replaced                   │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ AI_Brain/config/paths.md                                                                  │ 6-Dev_Status_Analysis → 6-Dev_Gap_Analysis_Status (2    │
│                                                                                           │ occurrences)                                            │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ AI_Brain/agents/status-analyzer.md                                                        │ 6-Dev_Status_Analysis → 6-Dev_Gap_Analysis_Status       │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ AI_Brain/lessons/known-issues.md                                                          │ 6-Dev_Status_Analysis → 6-Dev_Gap_Analysis_Status       │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ AI_Brain/module-knowledge/CMP_Complaint.md                                                │ 6-Dev_Status_Analysis → 6-Dev_Gap_Analysis_Status       │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ AI_Brain/state/progress.md                                                                │ 3-Audit_Modules → 3-Audit_Reports                       │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ 7-CLAUDE_Prompts/Dev_Completness_Status_Prompt/1-Prompt_Create_Status_Analyzer_Agent.md   │ Both 3-Audit_Modules and 6-Dev_Status_Analysis          │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ 7-CLAUDE_Prompts/Dev_Completness_Status_Prompt/2-Status_Analyzer_Agent_Creation_Prompt.md │ 6-Dev_Status_Analysis                                   │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ 7-CLAUDE_Prompts/.../22-Dev_Completness_Calculation_Process.md                            │ 3-Audit_Modules                                         │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ 7-CLAUDE_Prompts/.../21-Dev_Completness_Calculation_Process_Responce.md                   │ 3-Audit_Modules                                         │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ 7-CLAUDE_Prompts/Z-Temp_Prompts/Prompt_2026Jun22.md                                       │ 6-Dev_Status_Analysis                                   │
├───────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ 8-How_Tos/.../How_to_use_Technical-Auditor_Agent.md                                       │ 3-Audit_Modules (2 occurrences)                         │
└───────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────┘

3-Testing_Modules had no references in any of the scanned files.

----------------------------------------------------------------------------------------------------------------------------------------------------

## Prompt:
I want to create a Prompt which can perform below tasks :
- Read "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/6-Dev_Gap_Analysis_Status/1-Prompts/0-FRD_Audit_Status.md" to understand which all Modules we are working on.
- Understand which module are still pending to create "Module Knowledge" by checking the Status of coloumn "Module Knowledge" from "0-FRD_Audit_Status.md" file.
- If Status is not "Done" then execute below command :
    - Step-1 : seed module knowledge for {MODULE_NAME}
    - Step-2 : Once done Mark the Status "Done" in the Coloumn "Module Knowledge" for that Module.
    - Step-3 : Then move on the Next Module
    - Step-4 : Start from Step-1
    - Repeat this process till we will not complete generating "Module Knowledge" for all the Modules

- Add a Veriable to set how many agent can be run at a time in parralel.

Create a Prompt to achive the above tasks and save that Promt as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/6-Dev_Gap_Analysis_Status/1-Prompts/Create_Module_Knowledge/Generate_Module_Knowledge_Prompt.md"

## Responce:

