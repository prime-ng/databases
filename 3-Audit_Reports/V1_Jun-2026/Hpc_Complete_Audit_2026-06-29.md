# Complete Audit — Hpc (Holistic Progress Card) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** Hpc | **Code:** HPC | **Prefix:** `hpc_` | **Scope:** Tenant (database-per-school)
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/Hpc`
**Baseline FRD:** `4-Requirement_Module_wise/0-FRD_Documents/HPC_FRD_Complete_2026-06-29.md` (19 REQ / 16 BR / 6 RPT — IDs reused, never renumbered)
**Auditor:** Technical Auditor (read-only) | **Mode:** X (Complete)

---

## Executive Summary

HPC's *visible* surface (template CRUD, teacher form, PDF, email) is built, but four independent **P0** defects make the module unsafe to ship: (1) **BUG-HPC-016** — bulk PDF generation has no authorization (any authenticated user can render/distribute any student's confidential card); (2+3) the "Built" **approval workflow (REQ-HPC-013) cannot persist** — its migration ships a 4-value PascalCase status ENUM while the model writes 6 lowercase states, and the migration is missing **9 columns** the workflow `update()` writes (`submitted_at`, `reviewed_by`, …); (4) **five model-backed tables do not exist**, so every student / parent / peer feature throws `SQLSTATE 42S02` on its first live DB hit. Authorization (BUG-HPC-016) and data-integrity (broken workflow + missing tables) are both Red; tenancy (Layer 6) and queue/job (Layer 10) are genuinely healthy.

**Health: 40 / 100 (hard-capped — 4 P0s present).** **Deploy gate: NO-GO.**

## Audit Mode(s) Run
Mode A (12-layer) ✓ · Mode B (FRD gap) ✓ · Mode C (16 BR enforcement) ✓ · Mode G (deploy gate) ✓ · Mode D scoped (systemic detectors for HPC) ✓.

## Health Score
Weighted index would land ~52 (Tenancy/Queue Green offset Authorization/Data-Integrity Red), but the **P0 cap forces 40**. A single auth bypass plus a non-persisting workflow plus missing tables = "not healthy", period.

---

## Deploy Gate Verdict — **NO-GO**

Blocking items (all must clear before any user testing):
- **BUG-HPC-016** — unauthenticated-within-tenant bulk PDF generation/distribution of confidential child data.
- **DAT-HPC-001 + MIG-HPC-001** — approval workflow writes values/columns the schema rejects → REQ-HPC-013 is non-functional and corrupts `status`.
- **DAT-HPC-002** — student/parent/peer features query 5 non-existent tables → runtime 500s on live routes.
- **Platform SEC-RTG-001 (still live)** — `routes/tenant.php:361` `seeder/hpc` sits OUTSIDE the `auth` group; any anonymous tenant-domain visitor can trigger destructive HPC demo seeding (`SeederController` has zero environment guards). Inherited platform P0; flagged for the deploy gate.

Not blocking but tenancy/queue are clean: module `RouteServiceProvider` applies `InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive`; `SendHpcReportEmail` re-initialises tenancy and ends it in `finally`.

---

## P0 Findings

### [BUG-HPC-016] P0 — `generateReportPdf()` has NO authorization (CONFIRMED OPEN)
- **Location:** `Modules/Hpc/app/Http/Controllers/HpcController.php:1255` (route `POST /hpc/generate-report`, `routes/web.php:31`)
- **Evidence:**
```php
public function generateReportPdf(Request $request)
{
    $request->validate([
        'student_ids'   => 'required|array|min:1',
        'student_ids.*' => 'required|integer|exists:std_students,id',
        ...
    ]);                       // <-- NO Gate::authorize() anywhere in the method
```
  Sibling `generateSingleStudentPdf()` at line 2290 *does* gate: `if (!$bypassGate) { Gate::authorize('tenant.hpc.view'); }`.
- **Why it's a risk:** Any authenticated tenant user (regardless of role) can generate and, via the email actions, distribute the holistic progress card (child academic/behavioural data — Confidential) for arbitrary `student_ids`. Inconsistent with the 13 sibling methods gated in the 2026-03-17 sprint — this is a **regression**, not a never-built gap. The inline `$request->validate()` (not a FormRequest) means the D30 FormRequest-fallback defence does not apply either.
- **Fix:** Add `Gate::authorize('tenant.hpc.view')` (or a dedicated `tenant.hpc.generate-pdf`) as the first statement of the method.
- **Confidence:** High · **Systemic?** module-local regression (already registered as BUG-HPC-016).

### [DAT-HPC-001] P0 — `hpc_reports.status` ENUM ↔ model FSM mismatch breaks the approval workflow
- **Location:** migration `database/migrations/tenant/2026_06_15_152714_create_hpc_reports_table.php:17`; model `Modules/Hpc/app/Models/HpcReport.php:24-48`; writer `Modules/Hpc/app/Services/HpcWorkflowService.php:16-129`
- **Evidence:**
```php
// migration: 4 PascalCase values, default 'Draft'
$table->enum('status', ['Archived', 'Draft', 'Final', 'Published'])->default('Draft');

// model FSM: 6 lowercase states
const STATUS_DRAFT='draft'; const STATUS_SUBMITTED='submitted';
const STATUS_UNDER_REVIEW='under_review'; const STATUS_FINAL='final';
const STATUS_PUBLISHED='published'; const STATUS_ARCHIVED='archived';

// HpcWorkflowService::submit()
$report->update(['status' => HpcReport::STATUS_SUBMITTED, ...]);  // writes 'submitted'
```
- **Why it's a risk:** (a) `'submitted'`, `'under_review'`, `'draft'`, `'final'`, `'published'`, `'archived'` are **not** in the ENUM → MySQL strict mode rejects (errno 1265/1364) or truncates `status` to `''`. (b) New reports default to `'Draft'` (PascalCase) but `TRANSITIONS` is keyed by lowercase `'draft'`, so `canTransitionTo()` finds no allowed transitions and `validateTransition()` aborts **422 "Cannot transition from 'Draft'"** on the very first submit. The approval workflow (REQ-HPC-013, marked "Built") is non-functional and silently corrupts status. D29 violation too (ENUM instead of `sys_dropdown_table` FK).
- **Fix:** Replace the ENUM with a `varchar`/dropdown-FK carrying the 6 lowercase states (or migrate to align casing both ways); seed/default to `'draft'`; backfill existing rows. Pair with MIG-HPC-001.
- **Confidence:** High · **Systemic?** D29 (ENUM) + D17 (model↔DB divergence). Maps to BA gap GAP-DB-003.

### [MIG-HPC-001] P0 — `hpc_reports` migration is missing 9 columns the model writes
- **Location:** migration `…create_hpc_reports_table.php` (only creates `id, report_date, status, *_id FKs, prepared_by, timestamps, softDeletes`); model `HpcReport.php:50-69` (`$fillable`) + `HpcWorkflowService.php`
- **Evidence:** model `$fillable`/`$casts` and `HpcWorkflowService` write `submitted_at, reviewed_by, reviewed_at, review_comments, published_by, published_at, student_sections_complete, parent_sections_complete, created_by` — **none of these exist in the migration** (no ALTER migration adds them; the 3 ALTERs in the set touch `hpc_template_rubric_items`/`hpc_template_section_items` only).
```php
// HpcWorkflowService::startReview() — reviewed_by / reviewed_at do not exist as columns
$report->update(['status'=>HpcReport::STATUS_UNDER_REVIEW,'reviewed_by'=>$userId,'reviewed_at'=>now()]);
```
- **Why it's a risk:** Every workflow action (`submit`, `startReview`, `approve`, `sendBack`, `publish`) issues an `update()` including these columns → `SQLSTATE 42S22 Unknown column 'submitted_at'`. Combined with DAT-HPC-001 the workflow cannot run at all. Also: PK is `increments('id')` (signed INT — platform Layer 2.3 norm) and there is no `created_by` FK / `is_active`.
- **Fix:** Add the 9 columns (datetimes nullable, `reviewed_by`/`published_by`/`created_by` unsignedInteger FK→`sys_users`, two booleans default 0) in a new migration; cast already present in the model.
- **Confidence:** High · **Systemic?** D17. Maps to BA gap GAP-DB-003.

### [DAT-HPC-002] P0 — Five model-backed tables do not exist (student/parent/peer features fail at runtime)
- **Location:** models in `Modules/Hpc/app/Models/`; consumers are **live-routed** services/controllers:
  - `StudentFormSubmission` (`$table='hpc_student_form_submissions'`) — `StudentHpcFormService.php:87,103,114,129,149` (routes `student/form`, `student/submit`)
  - `ParentFormToken` (`$table='hpc_parent_form_tokens'`) — `ParentHpcFormService.php:18,23,38,131` (public routes `hpc/parent/*`, teacher link routes)
  - `PeerAssignment` (`hpc_peer_assignments`), `PeerResponse` (`hpc_peer_responses`) — `PeerAssignmentService.php:61,84,113,171,200,225`, `PeerHpcFormController.php:89,132` (routes `student/peer-review`, `teacher/assign-peers`)
  - `StudentHpcSnapshot` (`hpc_student_hpc_snapshot`) — REQ-HPC-015, inert
- **Evidence:** no `create_hpc_parent_form_tokens_table.php` / `…peer_assignments` / `…peer_responses` / `…student_form_submissions` / `…student_hpc_snapshot` exists in `database/migrations/tenant/` (verified: only the 11 template/report tables + 2 orphans are created). `ParentHpcFormService::generateToken()` calls `ParentFormToken::create([...])` directly.
- **Why it's a risk:** First DB hit on any of these routes → `SQLSTATE 42S02 Base table or view not found`. Student self-assessment (REQ-HPC-009), parent input (REQ-HPC-010), peer assessment (REQ-HPC-011) are coded end-to-end (controllers + services + 192 views) but inoperable. The FRD marks these "Partial" precisely because of this.
- **Fix:** Create the four needed migrations (`hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `hpc_student_form_submissions`) matching each model's `$fillable`; add `hpc_student_hpc_snapshot` for REQ-HPC-015 (P1 — feature inert, not crashing live yet).
- **Confidence:** High · **Systemic?** D17 (model-only, no migration). Maps to BA gaps GAP-DB-004b/c/d, 005, 006.

---

## P1 Findings

### [SEC-HPC-002] P1 (HIGH) — Public card-view route relies only on an encrypted id; no access-code / expiry check
- **Location:** `routes/web.php:16-18` (`GET /hpc/hpc-view/{student_id?}` OUTSIDE auth) → `HpcController::viewPdfPage()` line 1998
- **Evidence:**
```php
if (!is_numeric($student_id)) {
    $student_id = (int) Crypt::decryptString((string) $student_id);
    $publicAccess = true;            // no access-code check, no expiry check
} else {
    Gate::authorize('tenant.hpc.view');
}
...
return $this->renderStudentReportView($student_id, $publicAccess);
```
- **Why it's a risk:** Anyone holding the emailed encrypted-id link can view a child's full holistic card indefinitely. The access code (`HPC-{studentId}-{guardianId}-{sha1_8}`, design decision #4) and the "30-day validity" (REQ-HPC-014.4) are **not** verified on this request. Confidential child data, unauthenticated, no expiry.
- **Fix:** Require + verify the access code and a server-side expiry/issued-at on every public view; rate-limit the route. Already registered as SEC-HPC-002 — **still open**.
- **Confidence:** High · **Systemic?** module-local.

### [QUAL-HPC-001] P1 — `HpcController` is a 2,611-line god controller
- **Location:** `Modules/Hpc/app/Http/Controllers/HpcController.php` (2,611 lines, 21 `Gate::authorize` calls, ~7 inline `$request->validate()` actions)
- **Why it's a risk:** Per Layer 4.4 (>2000 lines = urgent decompose). Mixes index dashboard, teacher form load/save, single+bulk PDF, single+bulk email, the 6-state workflow endpoints, and the public PDF view. High regression surface — BUG-HPC-016 (one method losing its gate) is a direct symptom. The 4-template PDF if/elseif is a refactor target (`HpcPdfFactory`).
- **Fix:** Split into focused controllers (TemplateForm, Pdf, Email, Workflow, PublicView); extract a PDF-layout factory. Cross-ref NFR-HPC-03, RISK-HPC-006.
- **Confidence:** High · **Systemic?** platform god-object backlog.

---

## P2 Findings

### [SEC-HPC-003] P2 — `EnsureTenantHasModule:Hpc` NOT applied (entitlement bypass) — REGRESSED
- **Location:** `Modules/Hpc/app/Providers/RouteServiceProvider.php:41-47` (web group = `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive`); `routes/web.php:21` group = `['auth','verified']` only.
- **Evidence:** The middleware class exists (`app/Http/Middleware/EnsureTenantHasModule.php`) but is referenced **nowhere** in the HPC provider or routes. Known-issues marked SEC-HPC-003 "FIXED — `EnsureTenantHasModule::class.':Hpc'` on route group"; live code shows it absent.
- **Why it's a risk:** A tenant whose subscription plan excludes HPC can still reach every HPC feature (NFR-HPC-04 violated). Severity P2 — licensing/entitlement, behind `auth`, not a data breach.
- **Fix:** Add `EnsureTenantHasModule::class.':Hpc'` to the authenticated HPC group. Re-open SEC-HPC-003.
- **Confidence:** High · **Systemic?** TEN-RTG (module-subscription middleware) — module-local instance.

### [VAL-HPC-001] P2 — BR-HPC-009 bulk 50-student cap NOT enforced
- **Location:** `HpcController::generateReportPdf()` line 1257-1261 (validation block) and the generation loop through line 1644
- **Evidence:** validation is only `'student_ids' => 'required|array|min:1'` — there is **no** `max:50`, no `count()` guard, no `take(50)`/abort anywhere in the method.
- **Why it's a risk:** Synchronous bulk PDF over an unbounded student list → request timeout / OOM (each card is a DomPDF render). BR-HPC-009 ("≤50 students") is **MISSING**, contradicting the FRD/module-knowledge claim that it is enforced inline. Compounds BUG-HPC-016 (no auth on the same method).
- **Fix:** Add `'student_ids' => 'array|max:50'` (or a count guard returning 422); long-term move to a queued job (ENH-HPC-003).
- **Confidence:** High · **Systemic?** module-local.

### [DEAD-HPC-001] P2 — Orphan tables migrated with ENUMs, no model/code (D29)
- **Location:** `database/migrations/tenant/2026_06_16_132249_create_hpc_curriculum_change_request_table.php` and `…_132300_create_hpc_lesson_version_control_table.php`
- **Evidence:** `enum('entity_type',[...])`, `enum('change_type',['ADD','DELETE','UPDATE'])`, `enum('status',['APPROVED','DRAFT','REJECTED','SUBMITTED'])`. No model, controller, service, or route references either table (REQ-HPC-019 Not Built).
- **Why it's a risk:** Dead schema creates a false "done" impression; ENUMs violate D29. Low blast radius (unused).
- **Fix:** Either build REQ-HPC-019 or drop the migrations; if kept, convert ENUMs to dropdown FKs.
- **Confidence:** High · **Systemic?** D29 + orphan-table pattern. Maps to BA gap GAP-DB-001.

---

## P3 Findings

- **[P3] BR-HPC-011 strip-vs-reject deviation** — `downloadZip()` (line 1644) *sanitizes* the filename via `preg_replace('/[^A-Za-z0-9_\-\.]/','',$filename)` rather than rejecting with 400 as the FRD specifies. Path traversal is effectively prevented (slashes stripped), so the rule is functionally **ENFORCED**; only the on-violation behaviour differs. The method also correctly gates with `Gate::authorize('tenant.hpc.viewAny')`.
- **[P3] Inline `$request->validate()` in ~7 HpcController actions** instead of FormRequests — maintainability (Layer 7.3 is only P0 when validation is *absent*; here it is present).
- **[P3] Workflow notifications are TODO stubs** — `HpcWorkflowService` has `// TODO: Trigger event/notification` at submit/sendBack/publish (REQ-HPC-013.9 / ENH-HPC-001). Documented enhancement, not a defect.

---

## Layer Health Summary

| # | Layer | Rating | Key finding |
|---|-------|:------:|-------------|
| 1 | DDL Schema | 🟠 Amber | `hpc_reports.status` ENUM + 2 orphan ENUM tables (D29) |
| 2 | Migration↔Model↔DDL | 🔴 Red | MIG-HPC-001 (9 missing cols) + DAT-HPC-002 (5 missing tables) + DAT-HPC-001 |
| 3 | Model & ORM | 🟠 Amber | models well-formed but bound to non-existent tables |
| 4 | Code Quality | 🟠 Amber | QUAL-HPC-001 (2,611-line god controller); TODO stubs |
| 5 | Authorization | 🔴 Red | **BUG-HPC-016** auth bypass on bulk PDF |
| 6 | Multi-Tenancy | 🟢 Green | RSP applies full tenancy stack; job re-inits tenancy |
| 7 | Validation/Mass-assign | 🟠 Amber | VAL-HPC-001 (no 50 cap); `$request->all()` only in safe `->appends()` (D25 clean); `formStore` uses `$request->except()` |
| 8 | Data Integrity/Tx | 🔴 Red | workflow `update()` rejected by schema; missing tables |
| 9 | Performance | 🟠 Amber | god controller, unbounded bulk gen; PERF-HPC-001/002/004 known |
| 10 | Queue/Job | 🟢 Green | `SendHpcReportEmail` tenancy-init + `finally end()` (baseline "good template") |
| 11 | Frontend/Blade | 🟠 Amber | 192 views; no obvious unescaped-output XSS surfaced (not exhaustively swept) |
| 12 | Deployment | 🔴 Red | platform SEC-RTG-001 `seeder/hpc` unauth; queue/Horizon mismatch (platform) |

---

## STEP 1 Reading-Discipline Output — Three-way reconcile (DDL ↔ migration ↔ model)

| Bucket | Tables | Verdict |
|--------|--------|---------|
| Fully aligned | 11 template/report tables (`hpc_templates`, `hpc_template_parts`, `…_parts_items`, `…_sections`, `…_section_items`, `…_section_table`, `…_rubrics`, `…_rubric_items`, `hpc_reports`*, `hpc_report_items`, `hpc_report_table`) | working core (*`hpc_reports` has the status/audit-column defects above) |
| Migration only (orphan) | `hpc_curriculum_change_request`, `hpc_lesson_version_control` | DEAD-HPC-001 |
| Model only (no table) | `hpc_parent_form_tokens`, `hpc_peer_assignments`, `hpc_peer_responses`, `hpc_student_form_submissions`, `hpc_student_hpc_snapshot` | DAT-HPC-002 (P0) |
| Column-level gap | `hpc_reports`: 9 model columns absent from migration | MIG-HPC-001 (P0) |

**Snapshot corrections vs module-knowledge:** counts re-confirmed accurate (11 ctrl / 16 mdl / 10 svc / 4 FormRequest / 0 policy / 192 views / 0 tests). Corrections this audit adds: (a) the 4 template FormRequests are **not** bare `return true` — they carry conditional `Gate` logic (D30 not violated for the 4 that exist); (b) `StudentFormSubmission.$table` is `hpc_student_form_submissions` (has `hpc_` prefix — earlier note of "no prefix" superseded); (c) **BR-HPC-009 50-cap is NOT enforced** (module-knowledge said it was — corrected); (d) `downloadZip` BR-HPC-011 **is** enforced via sanitization + gate (SEC-HPC-006 effectively mitigated → P3); (e) SEC-HPC-003 is **regressed** (entitlement middleware absent), not "fixed".

---

## FRD Gap Summary (Mode B) — REQ → DDL / Code / Test

| REQ | Priority | Build (FRD) | DDL | Code | Test | Audit verdict |
|-----|:--------:|-------------|-----|------|------|---------------|
| REQ-HPC-001 Template Mgmt | P0 | Built | ✓ | ✓ | ✗ | OK |
| REQ-HPC-002…006 Curriculum analytics | P1/P2 | Not Built | ✗ | ✗ | ✗ | spec only (out of scope, ENH-HPC-006) |
| REQ-HPC-007 Student Evaluation | P1 | Not Built | ✗ | partial svc | ✗ | no table |
| REQ-HPC-008 Teacher Card | P0 | Built | ✓ | ✓ | ✗ | OK (depends on `hpc_reports`) |
| REQ-HPC-009 Student Self-Assess | P1 | Partial | ✗ | ✓ | ✗ | **DAT-HPC-002** (no `hpc_student_form_submissions`) |
| REQ-HPC-010 Parent Input | P1 | Partial | ✗ | ✓ | ✗ | **DAT-HPC-002** (no `hpc_parent_form_tokens`) |
| REQ-HPC-011 Peer Assessment | P1 | Partial | ✗ | ✓ | ✗ | **DAT-HPC-002** (no peer tables) |
| REQ-HPC-012 Card Generation | P0 | Built | n/a | ✓ | ✗ | **BUG-HPC-016** (no auth) + **VAL-HPC-001** (no 50 cap) |
| REQ-HPC-013 Approval Workflow | P0 | Built | ✗ | ✓ | ✗ | **DAT-HPC-001 + MIG-HPC-001** — cannot persist |
| REQ-HPC-014 Email Distribution | P0 | Built | n/a | ✓ | ✗ | OK (job tenancy-safe); SEC-HPC-002 on the view link |
| REQ-HPC-015 Card Snapshot | P2 | Not Built | ✗ | model only | ✗ | DAT-HPC-002 (inert) |
| REQ-HPC-016 Attendance Config | P1 | Built | ✓ (sys_settings) | ✓ | ✗ | OK |
| REQ-HPC-017 NCrF Credits | P1 | Partial | ✗ | svc only | ✗ | no override table (GAP-DB-002) |
| REQ-HPC-018 Activity Overview | P2 | Partial | ✓ | ✓ | ✗ | depends on missing peer/parent tables |
| REQ-HPC-019 Curriculum Change Req | P2 | Not Built | orphan | ✗ | ✗ | DEAD-HPC-001 |

**Test gap:** 0 automated tests in the module (only `.gitkeep` in `tests/Unit` and `tests/Feature`). Every REQ is a coverage gap (NFR-HPC-07; handoff to Testing Architect).

---

## Business-Rule Enforcement (Mode C)

| BR | Type | Location | Status | Link |
|----|------|----------|--------|------|
| BR-HPC-001 | Workflow | `HpcReportService::resolveTemplateId()` | ENFORCED | — |
| BR-HPC-002 | Validation | UNIQUE `(academic_session_id,term_id,student_id)` + `updateOrCreate()` | ENFORCED | migration `ux_reports_student_session_term` confirmed |
| BR-HPC-003 | Permission | `HpcSectionRoleService` / `formStore` `$request->except()` + role filter (log line 873) | ENFORCED | — |
| BR-HPC-004 | Workflow | `HpcWorkflowService::validateTransition()` (abort 422) | **PARTIAL** | transition guard exists but **cannot execute** — DAT-HPC-001/MIG-HPC-001 block persistence |
| BR-HPC-005 | Validation | `ParentHpcFormService::validateToken()` (expiry + completed) | **MISSING (runtime)** | DAT-HPC-002 — `hpc_parent_form_tokens` absent |
| BR-HPC-006 | Validation | `PeerAssignmentService::autoAssignPeers()` (no-self/no-reciprocal) | **MISSING (runtime)** | DAT-HPC-002 — peer tables absent |
| BR-HPC-007 | Calculation | `HpcAttendanceService` (Apr→Mar, recompute) | ENFORCED | — |
| BR-HPC-008 | Workflow | `HpcLmsIntegrationService` graceful fallback | ENFORCED | — |
| BR-HPC-009 | Validation | `generateReportPdf()` | **MISSING** | VAL-HPC-001 — no 50 cap |
| BR-HPC-010 | Workflow | `SendHpcReportEmail` (view link + access code) | ENFORCED | link, not attachment |
| BR-HPC-011 | Validation | `downloadZip()` sanitize+gate | ENFORCED | strip-vs-reject deviation P3 |
| BR-HPC-012 | Calculation | `HpcCreditCalculatorService` (national defaults) | PARTIAL | no override table (GAP-DB-002) |
| BR-HPC-013 | Workflow | template controllers trash/restore/force-delete | ENFORCED | — |
| BR-HPC-014 | Validation | template active flag | ENFORCED | — |
| BR-HPC-015 | Permission | published/archived read-only | **PARTIAL** | depends on workflow that cannot persist (DAT-HPC-001) |
| BR-HPC-016 | Workflow | section-complete lock | **MISSING (runtime)** | DAT-HPC-002 — submission tables absent |

ENFORCED 9 · PARTIAL 3 · MISSING 4 (3 of those purely because of the missing tables).

---

## Systemic-Pattern Scorecard (Mode D, scoped to HPC)

| Pattern | Present? | Count / Evidence |
|---------|:--------:|------------------|
| D17 model↔DB divergence | **YES** | `hpc_reports` 9 missing cols (MIG-HPC-001) + 5 model-only tables (DAT-HPC-002) |
| D24 permission-prefix chaos / typos | No | all gates use `tenant.hpc*` consistently (31 `tenant.hpc`, plus per-entity sub-prefixes) — no `tennat.`/dup |
| D25 `$request->all()` mass-assignment | No | the 4 hits are safe `->paginate()->appends($request->all())`; `formStore` uses `$request->except()` |
| D29 ENUM in migrations | **YES** | `hpc_reports.status` + orphan `hpc_curriculum_change_request` (3 enums) + `hpc_lesson_version_control` |
| D30 FormRequest `authorize(){return true;}` | No | the 4 template FormRequests carry real conditional `Gate` logic |
| D36 GENERATED columns degraded | n/a | no GENERATED columns in HPC DDL |
| Layer 2.5 cross-DB / missing-FK target | Partial | FKs target tenant tables that exist (`std_students`, `sch_*`, `hpc_templates`, `sys_users`); no `sys_roles`/`sys_dropdowns` FK in `hpc_reports` |
| Layer 6.2 `initialize()` without `end()` | No | only `SendHpcReportEmail` uses init + `finally end()` (correct) |
| Layer 10.1 job tenancy/retry | Clean | `SendHpcReportEmail` re-inits tenancy (baseline "good template") |
| TEN-RTG (module-subscription middleware) | **YES** | `EnsureTenantHasModule:Hpc` not applied (SEC-HPC-003) |
| Platform SEC-RTG-001 (seeder unauth) | **YES** | `routes/tenant.php:361` `seeder/hpc` outside `auth` (inherited platform P0) |

---

## vs Platform Baseline

- **Tenancy & queue better than typical** — module RSP carries the full stancl stack and the one job is a tenancy-correct template; many platform modules are not.
- **D25/D30 clean** — unlike the 24-site / 437-of-485 platform norms, HPC does not mass-assign and its FormRequests gate properly.
- **Worse on data-layer integrity** — the model-only-table pattern (5 tables) and the `hpc_reports` column gap are a concentrated D17 cluster; the "Built" workflow is the most severe instance (silent corruption + crash).
- **Eager-load ratio** — `app/` controllers+services with:get ≈ 53:79 (0.67), far healthier than the oft-cited whole-module "Hpc 0.04"; N+1 is a secondary concern behind the P0s. PERF-HPC-001/002 already fixed per known-issues.

---

## Recommended Fix Order (unblock-the-most-first)

1. **DAT-HPC-001 + MIG-HPC-001** (1 migration + enum reconcile) — restores REQ-HPC-013 workflow; highest functional unblock. ~4-6h.
2. **BUG-HPC-016** — one-line `Gate::authorize()` on `generateReportPdf()`; closes the confidential-data auth hole. ~15min.
3. **DAT-HPC-002** — 4 migrations (parent token, peer assign/response, student submission) → student/parent/peer features become operable; add snapshot (P1). ~8h.
4. **VAL-HPC-001** — add `max:50` to bulk validation (or count guard). ~15min.
5. **SEC-HPC-002 / SEC-HPC-003** — enforce access-code+expiry on public view; add `EnsureTenantHasModule:Hpc`. ~4h.
6. **DEAD-HPC-001** — decide build-vs-drop the 2 orphan tables. 
7. **QUAL-HPC-001 + tests** — decompose the god controller; feature tests for the now-fixed workflow / save / PDF (Testing Architect). ~24-42h.

---

## Next Steps
1. Fix P0 (BUG-HPC-016, DAT-HPC-001, MIG-HPC-001, DAT-HPC-002) → act as **Developer** / **DB Architect**
2. Schema migrations (status enum + 9 cols + 5 tables) → act as **DB Architect**
3. Completeness re-score against this FRD → act as **Status_Analyzer**
4. Feature tests (0 today) → act as **Testing Architect**

*End of HPC Complete Audit — 2026-06-29 (Mode X).*
</content>
</invoke>
