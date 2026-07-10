# Development Completeness Calculation Process
## Prime-AI School ERP — Module Scoring Framework v1.0

**Created:** 2026-06-24  
**Purpose:** Defines the exact, reproducible formula Claude must use to calculate Development Completeness % for any Prime-AI module.  
**Replaces:** The old judgment-based approach documented in `ModuleCompletionCalculationFormula_v1.md`.  
**Must be followed by:** Technical Auditor agent on every module audit.

---

## 1. Why This Document Exists

The previous approach had no formula. The number was an intuitive judgment call anchored to a prior estimate, with a post-hoc table built to justify it. Two audits of the same module would produce different numbers. The v1 analysis (see `ModuleCompletionCalculationFormula_v1.md`) confirmed this.

This document replaces that approach with a **requirements-driven, three-layer formula** that:
- Produces the same result every time
- Can be challenged line-by-line
- Uses all three input sources available: DDL, Requirements, Code
- Separates "what fraction of planned work exists" from "how correctly it is implemented"
- Applies hard caps when critical blockers are present

---

## 2. Definition of "Completion"

**A module is 100% complete when:**
1. The DDL is valid and tenant migrations exist (it can be deployed to any new school)
2. Every planned feature from the requirement document is implemented
3. Every route executes without 500/404 errors
4. Every write and sensitive-read route has correct Gate authorization
5. No feature returns empty/wrong output due to broken column references, stub methods, or hardcoded placeholder keys
6. No critical P0 bugs exist on core flows

This definition **excludes** tests and future feature requests — those are tracked separately.

---

## 3. The Three Input Sources

Before starting any module audit, confirm all three input sources exist:

| Source | Location | What Claude Reads From It |
|--------|----------|--------------------------|
| **Requirements** | `4-Requirement_Module_wise/2-Detailed_Requirements/V2/{MODULE_PREFIX}_*_Requirement.md` | Feature list (what the module SHOULD do); existing status annotations |
| **DDL** | `1-DDL_Tenant_Modules/{Module}/DDL/*_ddl_v2.sql` | Schema validity — FKs, indexes, columns, table structure |
| **Code** | `{LARAVEL_REPO}/Modules/{Module}/` | Routes, controllers, models, migrations, FormRequests |

If a requirement file is missing, see Section 9.

---

## 4. The Formula

```
Completeness Score = (Layer_A × 50%) + (Layer_B × 35%) + (Layer_C × 15%)
Final Score        = min(Completeness_Score, P0_Cap)
```

| Layer | Name | Weight | What It Measures |
|-------|------|--------|-----------------|
| **A** | Requirements Coverage | **50%** | What fraction of PLANNED features have been built (any state) |
| **B** | Implementation Quality | **35%** | For features that exist: are routes working, authorized, complete, data-correct? |
| **C** | Technical Foundation | **15%** | Is the DDL valid? Do migrations exist? Is the RSP configured? |
| — | P0 Cap | — | Hard ceiling applied when blocking issues exist |

**Why 50% for requirements?** Because building something wrong is always worse than not building it at all. A module where 80% of features exist but 60% are broken is NOT more complete than a module where 40% of features exist and all 40% work perfectly. Requirements coverage measures scope; implementation quality measures correctness.

---

## 5. Step-by-Step Audit Process

### Phase 1: Load Input Files (always first)

```
1. Read: AI_Brain/config/paths.md      → resolve {LARAVEL_REPO}, {OLD_REPO}
2. Read: AI_Brain/memory/conventions.md → confirm table prefixes, permission naming
3. Read: {OLD_REPO}/4-Requirement_Module_wise/2-Detailed_Requirements/V2/{PREFIX}_*_Requirement.md
4. Read: {OLD_REPO}/1-DDL_Tenant_Modules/{Module}/DDL/*_ddl_v2.sql
5. Read: {LARAVEL_REPO}/Modules/{Module}/routes/web.php
6. Read: {LARAVEL_REPO}/Modules/{Module}/routes/api.php  (if exists)
7. Read: {LARAVEL_REPO}/Modules/{Module}/app/Providers/RouteServiceProvider.php
```

### Phase 2: Extract Feature Functions from Requirements (Layer A preparation)

From the requirement file, extract every **Feature Function** — a discrete user-facing action the module should support.

**What counts as one Feature Function:**
- One CRUD operation on one entity (Create, Read/List, Edit, Delete, Restore, Force-Delete, Trash-View each count separately)
- One report or analytics view
- One AJAX/dropdown endpoint that populates a form
- One API endpoint (mobile or external)
- One background job or scheduled task
- One dashboard widget or KPI
- One configuration screen

**What does NOT count as a separate Feature Function:**
- A sub-component of a single form (individual fields are not separate features)
- Duplicate routes pointing to the same action

**Build the Feature Function Register:**

| # | Feature Function | Required By | Expected Route | Expected Controller::Method |
|---|-----------------|-------------|---------------|---------------------------|
| 1 | Create Complaint | Req §2.2 | POST /complaints | ComplaintController::store |
| 2 | List Complaints | Req §2.2 | GET /complaints | ComplaintController::index |
| ... | ... | ... | ... | ... |

Record this table. The total row count = **T** (Total Planned Feature Functions).

### Phase 3: Verify Each Feature Function (Layer A scoring)

For every row in the Feature Function Register, assign one of three scores:

| Status | Score | Criteria |
|--------|-------|----------|
| ✅ Implemented | 1.0 | Route exists, method exists, method has real logic (not empty `{}`), produces expected output type (view or JSON) |
| 🟡 Partial | 0.5 | Route exists AND method exists BUT at least one of: empty body, returns wrong view, fails silently (missing auth, wrong column) |
| ❌ Not Started | 0.0 | Route does not exist, OR method does not exist, OR method throws 500 |

```
Layer_A = Σ(Feature_Score) / T × 100
```

**Example shorthand check per feature:**
```bash
# Does the route exist?
grep -n "ControllerName::methodName" Modules/{Module}/routes/web.php

# Does the method exist in the controller?
grep -n "public function methodName" Modules/{Module}/app/Http/Controllers/ControllerName.php

# Is the method a stub (empty body)?
# Read the method — if body is empty {} or only contains Gate::authorize with no other logic → stub
```

### Phase 4: Score Implementation Quality (Layer B)

Layer B measures the QUALITY of everything that scored ✅ or 🟡 in Layer A (i.e., exists in some form).

Exclude ❌ (not-started) features from Layer B — there is nothing to evaluate.

**For each ✅ or 🟡 feature, score four quality criteria:**

#### B1 — Route Integrity (30 pts per feature)
| Situation | Points |
|-----------|--------|
| Route exists, method exists, no 500/404 | 30 |
| Route exists, method exists, but route is shadowed (another route captures it first) | 10 |
| Route 500s due to missing method or wrong signature | 0 |

#### B2 — Authorization Correctness (40 pts per feature)
| Situation | Points |
|-----------|--------|
| `Gate::authorize('tenant.{module}.{action}')` present AND permission prefix matches platform convention (`tenant.*`) | 40 |
| Gate present but permission prefix is wrong (e.g., `prime.*`, `tested.*`, `{module}.{module}.*`) | 15 |
| Gate present but `authorize()` returns bare `true` in FormRequest, no other check | 10 |
| No Gate, no auth check (write route: store/update/destroy) | 0 |
| No Gate on read route (index/show/report) | 5 |

#### B3 — Business Logic Completeness (20 pts per feature)
| Situation | Points |
|-----------|--------|
| Method has real logic, returns expected data/view, no commented-out `dd()` or debug calls | 20 |
| Method has partial logic — does something but incomplete (e.g., saves to DB but doesn't update related tables) | 10 |
| Method is a stub — empty `{}` body, immediately returns null, or calls `abort(501)` | 0 |
| Method has `dd()` or `var_dump()` that is NOT commented out | 0 |

#### B4 — Data Integrity (10 pts per feature)
| Situation | Points |
|-----------|--------|
| Method uses correct column names (matching DDL), correct table names, real dropdown keys | 10 |
| Method uses placeholder keys like `dummy_table_name`, wrong column names that exist in code but not in DDL, or hardcoded IDs | 0 |
| Method queries a table/column that has a confirmed mismatch between DDL and code | 0 |

**Per-feature quality score:** B1 + B2 + B3 + B4 (max 100 per feature)

```
Layer_B = Σ(per-feature quality scores) / (count of ✅+🟡 features × 100) × 100
```

### Phase 5: Score Technical Foundation (Layer C)

Layer C is scored once per module, not per feature.

#### C1 — DDL Validity (50 pts)
| Situation | Points |
|-----------|--------|
| DDL file exists AND has zero P0 structural errors (no type-mismatch FKs, no broken indexes, no syntax errors) | 50 |
| DDL file exists, has P1 issues (broken indexes on non-existent columns, minor column mismatches) but no P0 errors | 25 |
| DDL file exists but has P0 structural errors (type-mismatch FK, invalid constraint that prevents CREATE TABLE) | 0 |
| DDL file does not exist | 0 |

**P0 DDL errors are specifically:** FK where source column type ≠ referenced column type; FK referencing a non-existent table; INDEX on a column that doesn't exist in the table definition.

#### C2 — Migration Files (30 pts)
| Situation | Points |
|-----------|--------|
| Migration files exist in `Modules/{Module}/database/migrations/` AND cover all module tables | 30 |
| Migration files exist but only cover some tables (partial migration coverage) | 15 |
| Migration directory is empty or does not exist | 0 |

```bash
ls {LARAVEL_REPO}/Modules/{Module}/database/migrations/
```

#### C3 — RouteServiceProvider Configuration (20 pts)
| Situation | Points |
|-----------|--------|
| RSP exists, web routes have full tenancy stack (`InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive + auth + verified`) | 20 |
| RSP exists, web routes have tenancy but missing one middleware (e.g., missing `EnsureTenantIsActive`) | 10 |
| RSP exists but web routes have NO tenancy middleware (module can run on wrong tenant DB) | 0 |
| RSP does not exist | 0 |

```
Layer_C = C1 + C2 + C3  (max 100)
```

### Phase 6: Apply P0 Caps

After calculating the raw score, check for P0-level blocking issues and apply the lowest applicable cap:

| P0 Condition | Maximum Allowed Final Score |
|---|---|
| Module cannot load at all (RSP error, missing class imports in routes file) | **20%** |
| DDL has P0 structural error (prevents CREATE TABLE execution) | **50%** |
| P0 Bug: Primary entity's CORE route (Create or List) throws 500 on every call | **55%** |
| P0 Security: Any write route (store/update/destroy) on primary entity has ZERO Gate authorization | **60%** |
| P0 Security: Any read route with sensitive data has ZERO authorization | **65%** |
| No P0 conditions present | No cap — use raw score |

**Apply the LOWEST applicable cap if multiple P0 conditions exist.**

```
Final Score = min(Raw Completeness Score, Lowest P0 Cap)
```

### Phase 7: Calculate and Record

```
Raw Score = (Layer_A × 0.50) + (Layer_B × 0.35) + (Layer_C × 0.15)
Final Score = min(Raw Score, P0_Cap)
Final Score = round to nearest integer
```

---

## 6. Standard Scorecard Output

Every audit must produce a scorecard in this exact format. Record in `AI_Brain/state/progress.md`.

```
MODULE: {Module Name}
AUDIT DATE: {YYYY-MM-DD}
AUDITOR: Technical Auditor Agent

LAYER A — Requirements Coverage
  Total Feature Functions: {T}
  Implemented (✅):        {N_full}  (each = 1.0)
  Partial (🟡):            {N_part}  (each = 0.5)
  Not Started (❌):        {N_none}  (each = 0.0)
  Raw A Score:             {Σ / T × 100} = {A}/100

LAYER B — Implementation Quality  (scored across {N_full + N_part} features)
  B1 Route Integrity avg:  {B1}/30
  B2 Authorization avg:    {B2}/40
  B3 Business Logic avg:   {B3}/20
  B4 Data Integrity avg:   {B4}/10
  Raw B Score:             {B}/100

LAYER C — Technical Foundation
  C1 DDL Validity:         {C1}/50
  C2 Migration Files:      {C2}/30
  C3 RSP Configuration:    {C3}/20
  Raw C Score:             {C}/100

CALCULATION
  Raw = ({A} × 0.50) + ({B} × 0.35) + ({C} × 0.15) = {raw}
  P0 Caps applied: {list P0 conditions found, or "None"}
  Final Score: {final}%

FEATURE FUNCTION REGISTER (summary)
  | # | Feature | Status | B1 | B2 | B3 | B4 |
  |---|---------|--------|----|----|----|----|
  | 1 | Create Complaint | ✅ | 30 | 40 | 20 | 10 |
  | 2 | List Complaints  | 🟡 | 30 | 0  | 20 | 10 |
  ...

OPEN BLOCKERS (issues preventing score increase)
  P0: {list}
  P1: {list}
```

---

## 7. Worked Example — Complaint Module (2026-06-24)

This applies the formula to the Complaint module using the same findings from the June 2026 audit.

### Feature Function Register

Reading `CMP_Complaint_Requirement.md` and the code, the planned feature functions are:

| # | Feature Function | Req Ref | Status | Justification |
|---|-----------------|---------|--------|---------------|
| 1 | Create Complaint | T.D3.1.1 | 🟡 | Route + method exist; store() has no Gate auth (P0 security) |
| 2 | List Complaints | T.D3.1.1 | ✅ | Works; weak gate (Gate::any) but acceptable |
| 3 | View Complaint | T.D3.1.1 | ✅ | Gate + method exist; works |
| 4 | Edit/Update Complaint | T.D3.1.1 | ✅ | Gate + method exist; works |
| 5 | Soft Delete Complaint | T.D3.1.1 | ❌ | destroy() method exists but trashed/restore/force-delete methods do not |
| 6 | Restore / Trash / Force-Delete | T.D3.1.1 | ❌ | 4 methods missing → 500 |
| 7 | Manage Complaint (detail view) | T.D3.1.2 | ❌ | Route permanently shadowed → 404 |
| 8 | Assign Complaint to Role/User | T.D3.1.1.2 | 🟡 | Works but action logging broken |
| 9 | Auto-Resolution-Due-At on Create | T.D3.1.1 | ❌ | Not implemented |
| 10 | Scheduled Escalation Job | Beyond RBS | ❌ | Not started |
| 11 | Complaint Categories — CRUD | F.D3.1 | ✅ | Fully implemented + Gate correct |
| 12 | Complaint Categories — Trash/Restore | F.D3.1 | ✅ | All methods exist + Gate |
| 13 | Complaint Categories — Toggle Status | F.D3.1 | ✅ | Works |
| 14 | Department SLA — CRUD | F.D3.1 | 🟡 | Works but column mismatch (escalation_hours vs default_escalation_hours) — queries return null |
| 15 | Department SLA — Trash/Restore | F.D3.1 | ✅ | All methods exist |
| 16 | Complaint Actions / Timeline Log | T.D3.1.2 | ❌ | ComplaintActionController is partial stub; restore/forceDelete missing |
| 17 | Medical Check — CRUD | Beyond RBS | 🟡 | Methods exist; create form always empty (dummy_table_name dropdown keys) |
| 18 | Medical Check — Trash/Restore | Beyond RBS | ✅ | Works |
| 19 | AI Insight — View/Store/Update | Beyond RBS | ❌ | Complete stub — empty methods on live routes |
| 20 | Dashboard KPIs + Charts | Beyond RBS | 🟡 | Service exists; chart methods have no Gate |
| 21 | Report: Summary/Status | Beyond RBS | 🟡 | Method exists; zero Gate (P0 security) |
| 22 | Report: Pareto | Beyond RBS | 🟡 | Method exists; zero Gate |
| 23 | Report: Complainant Hotspot | Beyond RBS | 🟡 | Method exists; zero Gate; N+1 |
| 24 | Document Requests — List/View/Update | Beyond RBS | 🟡 | Methods exist; zero Gate; cross-module dependency |
| 25 | Mobile API — View/Create Complaints | Mobile | 🟡 | store/update gated; dashboard/index/show/users NOT gated |
| 26 | AJAX Subcategory/User Dropdowns | Support | ✅ | Methods exist; no Gate needed (non-sensitive) |
| 27 | Get Table Data / Schema Columns | Support | 🟡 | Works; getTableColumns has no Gate |

**Totals:** T = 27, ✅ = 10 (score 1.0 each), 🟡 = 11 (score 0.5 each), ❌ = 6 (score 0.0 each)

```
Layer_A = (10×1.0 + 11×0.5 + 6×0.0) / 27 × 100
         = (10 + 5.5 + 0) / 27 × 100
         = 15.5 / 27 × 100
         = 57.4 / 100  →  A = 57
```

### Layer B Scoring (for 21 features with ✅ or 🟡 status)

Scoring by group for conciseness:

| Feature Group | B1/30 | B2/40 | B3/20 | B4/10 | Total/100 |
|---|---|---|---|---|---|
| List/View/Edit/Update Complaints (4 ✅) | 30 | 35 | 20 | 10 | 95 |
| Create Complaint (🟡 — no Gate) | 30 | 0 | 15 | 10 | 55 |
| Assign Complaint (🟡) | 30 | 30 | 10 | 10 | 80 |
| Categories CRUD + Trash (✅ ×4) | 30 | 40 | 20 | 10 | 100 |
| Dept SLA CRUD + Trash (✅+🟡) | 30 | 40 | 20 | 0 | 90 avg → 85 |
| Dashboard + Charts (🟡 — no Gate on charts) | 25 | 10 | 15 | 10 | 60 |
| Reports (🟡 ×3 — zero Gate) | 30 | 0 | 15 | 10 | 55 |
| Medical Check CRUD+Trash (🟡+✅) | 28 | 35 | 15 | 0 | 78 |
| Document Requests (🟡 — zero Gate, cross-module) | 30 | 0 | 15 | 10 | 55 |
| Mobile API (🟡 — partial Gate) | 30 | 12 | 15 | 10 | 67 |
| AJAX Dropdowns + Table Data (✅+🟡) | 30 | 25 | 20 | 10 | 85 |

Average across 21 features ≈ 74 (weighted by feature count):
Rough sum: (95×4 + 55 + 80 + 100×4 + 85×5 + 60 + 55×3 + 78×3 + 55 + 67) / 21 ≈ **73**

```
Layer_B ≈ 73 / 100  →  B = 73
```

### Layer C Scoring

| Criterion | Score | Reason |
|---|---|---|
| C1 DDL Validity | 0/50 | P0 type-mismatch FKs (SCH-CMP-002, SCH-CMP-003) prevent CREATE TABLE |
| C2 Migration Files | 0/30 | migrations/ directory is empty |
| C3 RSP Configuration | 20/20 | Web routes have full tenancy stack ✓ |

```
Layer_C = (0 + 0 + 20) = 20 / 100  →  C = 20
```

### Final Calculation

```
Raw Score = (57 × 0.50) + (73 × 0.35) + (20 × 0.15)
          = 28.5 + 25.55 + 3.0
          = 57.05

P0 Conditions present:
  1. DDL has P0 structural errors → cap at 50%
  2. store() on primary entity has ZERO Gate → cap at 60%

Lowest cap = 50%

Final Score = min(57, 50) = 50%
```

**Complaint module: 50% completion** using this formula.

> **Note:** The old judgment-based estimate was 20%. The v1 formula (code-only, no requirements) gave 52%. This requirements-driven formula gives 50% with the P0 DDL cap applied. The 50% figure reflects that: about half the planned features have been built in some form, implementation quality is moderate (many auth gaps), and the technical foundation is blocking deployment.

---

## 8. P0 Cap Reference Table (Full)

| P0 Condition | Test | Cap |
|---|---|---|
| Module cannot load — RSP has `use` import for a file that doesn't exist, or routes file has syntax error | Try `php artisan route:list` for this module — if it throws exception | **20%** |
| DDL has P0 structural error (type-mismatch FK, index on non-existent column) | Grep DDL for FKs; verify source column type matches referenced column type | **50%** |
| No migration files at all | `ls Modules/{Module}/database/migrations/` returns empty | **50%** |
| Primary entity list or create routes throw 500 (method missing) | Verify method exists in controller file | **55%** |
| Primary entity write route (store/update/destroy) has ZERO Gate authorization | Read store/update method; no `Gate::authorize`, no `$this->authorize` | **60%** |
| Any dashboard or report controller has ZERO Gate on every method | Read report controller; no Gate on any method | **65%** |

Apply the **lowest** cap from all matching conditions.

---

## 9. Handling Missing Requirement Files

If no V2 requirement file exists for a module, fall back in order:

1. **Check V1 requirements:** `4-Requirement_Module_wise/2-Detailed_Requirements/V1/`
2. **Check high-level requirements:** `4-Requirement_Module_wise/1-HighLevel_Requirements/`
3. **Check module-level DDL folder:** Sometimes `1-DDL_Tenant_Modules/{Module}/` has a requirement file
4. **Infer from DDL tables:** Each table in the DDL represents at least one CRUD feature set. Use this as a minimum feature list.
5. **Note in audit report:** "No V2 requirement file found — feature list inferred from [source]. Layer A scoring may undercount planned features."

When inferring from DDL, assume each table → 1 CRUD set = 5 Feature Functions (Create, List, View, Edit, Delete). This will typically undercount, so note that the final score is a **lower bound**.

---

## 10. Where to Store Results

| Output | Location |
|--------|----------|
| Full audit report with scorecard | `{OLD_REPO}/3-Audit_Reports/V1_{Date}/{Module}/` |
| Updated completion % | `{OLD_REPO}/AI_Brain/state/progress.md` — replace old entry with new scorecard |
| New issue codes | Append to `{OLD_REPO}/AI_Brain/lessons/known-issues.md` |

**Progress.md entry format** (replace old freeform text):
```
| Module | Completeness | Audit Date | A/B/C Scores | P0 Issues |
```
Example:
```
| Complaint | 50% (P0-capped) | 2026-06-24 | A=57 B=73 C=20 | DDL P0 FKs; store() no Gate |
```

---

## 11. Quick Reference — Layer Scoring Cheatsheet

```
LAYER A — Requirements Coverage
  ✅ = 1.0 (route exists, method exists, real logic, produces correct output)
  🟡 = 0.5 (route/method exists but incomplete, stub, or broken auth)
  ❌ = 0.0 (route or method missing, throws 500)
  Formula: Σ(scores) / Total Features × 100

LAYER B — Quality of Implemented Features (only ✅ + 🟡)
  B1 Route Integrity:    30 pts (works=30, shadowed=10, 500=0)
  B2 Authorization:      40 pts (correct=40, wrong prefix=15, bare true=10, missing write=0, missing read=5)
  B3 Business Logic:     20 pts (complete=20, partial=10, stub/dd=0)
  B4 Data Integrity:     10 pts (correct columns=10, dummy keys/wrong columns=0)
  Formula: Σ(all feature scores) / (count × 100) × 100

LAYER C — Technical Foundation
  C1 DDL Valid:          50 pts (clean=50, P1 issues=25, P0 errors=0)
  C2 Migrations Exist:   30 pts (all tables=30, partial=15, none=0)
  C3 RSP Config:         20 pts (full stack=20, partial=10, missing=0)

P0 CAPS (apply lowest matching)
  Module won't load:     20%
  DDL P0 / No migrations: 50%
  Primary CRUD 500:      55%
  Write route no Gate:   60%
  Reports all unguarded: 65%

FINAL = min((A×0.50 + B×0.35 + C×0.15), P0_Cap)
```

---

## 12. Calibration Notes (Update as Experience Grows)

This section records judgments that are consistently applied across modules so that Layer B scoring stays consistent:

| Judgment | Decision |
|----------|----------|
| FormRequest with `authorize() { return true; }` | B2 = 10 pts (bare true — systemic D25 pattern) |
| Gate::any() without explicit abort(403) — weak gate | B2 = 25 pts (partial auth) |
| `$request->all()` passed to create/update despite FormRequest | B4 = 0 pts (mass assignment bypass) |
| Method uses `Modules\Prime\Models\*` in tenant controller | B4 = 5 pts (cross-layer, reduces score but doesn't zero it) |
| Controller > 1000 lines | B3 = max 15 pts (God controller, logic integrity uncertain) |
| God controller 500–1000 lines | B3 = max 18 pts |
| Commented-out `dd()` | B3 = 18 pts (not blocking, but messy) |
| Live uncommitted `dd()` that actually executes | B3 = 0 pts |

---

*This document is the Single Source of Truth for completion scoring. Update Section 12 (Calibration Notes) as new judgment patterns are encountered. Treat the formula values (50/35/15 weights, P0 caps) as stable unless the user explicitly changes them.*
