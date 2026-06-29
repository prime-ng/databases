# Complete Audit — Certificate (CRT) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** Certificate | **Code:** CRT | **Prefix:** `crt_` | **Type:** Tenant (`tenant_db`)
**Auditor:** Technical Auditor (AI_Brain) | **Baseline FRD:** `CRT_FRD_Complete_2026-06-29.md` (REQ-/BR-/RPT- IDs reused, never renumbered)
**App code:** `/Users/bkwork/Herd/prime_ai/Modules/Certificate`
**Method:** 12-layer deep scan + FRD gap + BR enforcement + deploy gate + module-scoped systemic sweep. Every finding read in source; cross-DB/table claims three-way reconciled (DDL ↔ tenant migration ↔ live code).

---

## Executive Summary

Certificate is a **structurally sound, well-gated module** (full tenancy middleware stack, consistent policy-based authorization, real transactions, a correct `lockForUpdate` serial counter) that is **undermined by a cluster of wrong-table / wrong-column database references in the runtime code** — none introduced by the schema, all in service/controller queries. The single worst class of finding: **three core features throw SQL errors at runtime** — Transfer Certificate generation (REQ-CRT-005, a P0 requirement), ID-card sheet generation (REQ-CRT-008), and DMS document upload (REQ-CRT-009) — because the code queries tables/columns that do not exist in the tenant schema (`fin_fee_invoices`, `std_profiles`, `std_students.class_id/section_id/date_of_birth`, and a `media_id => 0` FK violation).

**Health: 66 / 100 (Amber).** No P0 (no cross-tenant leak, no committed secret, no unauth write route, no migration blocker) → **health is NOT capped**. The verified-false-positive RISK-CRT-005 (PDF storage isolation) is mitigated by `suffix_storage_path => true`. **Deploy Gate: GO** for the platform/migration/security gates, **but release-readiness is NO-GO for the TC / DMS / ID-card features** until the runtime SQL bugs (P1) are fixed.

---

## Health Score

| Component | Value |
|-----------|-------|
| Weighted layer index | **66 / 100** |
| P0 cap applied? | No (no P0 findings) |
| Worst layer | L5 Authorization / L8 Data Integrity (Amber) |
| Best layer | L6 Tenancy / L2 Migration↔Model↔DDL (Green) |

Counts: **P0 = 0 · P1 = 6 · P2 = 6 · P3 = 5.**

---

## Deploy Gate Verdict (Mode G)

**GO** against the formal gate (Layers 6/8/10/12 + secrets + route/config-cache safety):
- No P0; no committed secret in the module; no cross-tenant path (storage is tenant-suffixed; DB is per-tenant).
- Tenancy middleware stack complete on all routes (`InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` + `EnsureTenantIsActive`).
- No route closures in `Modules/Certificate/routes/*` → `route:cache` safe. No `env()` in module routes/app.
- Migrations: 10 `crt_*` create migrations + `add_tc_issued_to_std_students` are present and self-consistent; all FK targets (`sys_users`, `sys_media`, `sys_dropdowns`, `std_students`, `crt_*`, `sch_org_academic_sessions_jnt`) exist in the tenant migration set → `tenants:migrate` will not fail for this module.

**Release-readiness caveat (NOT a deploy-gate blocker, but a go-live blocker for the affected features):**
- **TC (REQ-CRT-005), ID-card (REQ-CRT-008), and DMS upload (REQ-CRT-009) throw at runtime** — BUG-CRT-001…004. Do not enable these features for users until fixed.
- **Inherited platform risk DEPLOY-HRZ-01:** `config/queue.php` default `database` vs Horizon `redis`. `BulkGenerateCertificatesJob` is dispatched without an explicit connection → >200-cert bulk runs may never execute on a Horizon/redis worker. Not CRT-specific; confirm queue wiring before relying on bulk generation.

---

## P0 Findings

**None.** The module has no exploitable security hole, cross-tenant leak, committed secret, or migration/deploy blocker. The public verification endpoint is read-only, rate-limited (`throttle:20,60`), and privacy-safe (BR-CRT-010 enforced). All write controllers are gated.

---

## P1 Findings

### [BUG-CRT-001] P1 | TC fee-clearance gate queries a non-existent table/columns → TC generation always throws
- **Location:** `Modules/Certificate/app/Services/CertificateGenerationService.php:91-94`
- **Evidence:**
```php
$feeDues = DB::table('fin_fee_invoices')
    ->where('student_id', $studentId)
    ->where('payment_status', '!=', 'paid')
    ->sum('net_payable');
```
- **Why it's a risk:** No `fin_fee_invoices` table exists in `tenant_db` (StudentFee prefix is `fee_`; the table is `fee_invoices`). `fee_invoices` has **no `student_id`** (linkage is `student_assignment_id`), **no `payment_status`** (the column is `status` enum with value `'Paid'`, not `'paid'`), and **no `net_payable`** (`balance_amount` / `total_amount` / `paid_amount`). Every `generateTC()` call throws `SQLSTATE[42S02] Base table or view not found` at the fee gate, before any record is written. REQ-CRT-005 (P0 core, legally mandated) is non-functional. This also permanently masks BR-CRT-001's missing fee-override path (the override was never implemented either — RISK-CRT-002).
- **Fix:** Repoint to `fee_invoices` joined via `fee_student_assignments.student_id`; sum `balance_amount` where `status != 'Paid'` (or `balance_amount > 0`). Add the BR-CRT-001 override-justification capture (logged to `sys_activity_logs`).
- **Confidence:** High. **Systemic?** Module-local (wrong-table cluster).

### [BUG-CRT-002] P1 | `generateTC()` student snapshot uses non-existent columns/table → TcRegister write fails
- **Location:** `Modules/Certificate/app/Services/CertificateGenerationService.php:119-146`
- **Evidence:**
```php
$student = DB::table('std_students')
    ->join('sch_classes', 'sch_classes.id', '=', 'std_students.class_id')        // no class_id on std_students
    ->leftJoin('sch_sections', 'sch_sections.id', '=', 'std_students.section_id') // no section_id
    ...
$fatherName = DB::table('std_profiles')->where('student_id',$studentId)->value('father_name'); // std_profiles does not exist
...
'date_of_birth' => $student->date_of_birth,  // column is `dob`, not date_of_birth
```
- **Why it's a risk:** `std_students` has **no `class_id`/`section_id`** (class/section live via `std_student_academic_sessions` → `sch_class_section_jnt`) and **no `date_of_birth`** (the column is `dob`). `std_profiles` does not exist (the table is `std_student_profiles`). Each is a `SQLSTATE[42S22] Unknown column` / `42S02` error; even if BUG-CRT-001 were fixed, the snapshot query throws, and `crt_tc_register.date_of_birth` is `NOT NULL` so a null write would also fail.
- **Fix:** Resolve class/section via the academic-session join (the correct pattern is already used in `resolveMergeFields()` and `BulkGenerationController::resolveStudentIds()`); read `dob` not `date_of_birth`; source father name from the correct table.
- **Confidence:** High. **Systemic?** Module-local.

### [BUG-CRT-003] P1 | ID-card sheet generation joins non-existent columns/table → REQ-CRT-008 throws
- **Location:** `Modules/Certificate/app/Services/IdCardGenerationService.php:82-94`
- **Evidence:**
```php
DB::table('std_students')
    ->leftJoin('sch_classes', 'sch_classes.id', '=', 'std_students.class_id')   // no class_id
    ->leftJoin('sch_sections', 'sch_sections.id', '=', 'std_students.section_id')// no section_id
    ->leftJoin('std_profiles', 'std_profiles.student_id', '=', 'std_students.id')// std_profiles missing
    ->select('std_students.date_of_birth', 'std_profiles.blood_group', 'std_profiles.address_line1', ...) // dob; wrong table
```
- **Why it's a risk:** Same wrong joins as BUG-CRT-002. `IdCardConfigController::generate()` (POST) calls `generateSheet()` → this query throws `Unknown column`/`Base table not found`. The student ID-card print sheet (REQ-CRT-008 AC) cannot be produced.
- **Fix:** Use the `std_student_academic_sessions`/`sch_class_section_jnt` join; read `dob`; source `blood_group`/address from the correct table (see DATA-CRT-001).
- **Confidence:** High. **Systemic?** Module-local.

### [BUG-CRT-004] P1 | DMS document upload inserts `media_id => 0` into a NOT NULL FK column → FK violation
- **Location:** `Modules/Certificate/app/Http/Controllers/StudentDocumentController.php:65-81`; migration `database/migrations/tenant/2026_06_16_083600_create_crt_student_documents_table.php:30-31`
- **Evidence:**
```php
$doc = StudentDocument::create([ ... 'media_id' => 0, ... ]); // placeholder
$media = $doc->addMediaFromRequest('document_file')->toMediaCollection('student_document');
$doc->update(['media_id' => $media->id, ...]);
```
```php
$table->unsignedInteger('media_id'); // NOT nullable
$table->foreign('media_id','fk_crt_sd_media_id')->references('id')->on('sys_media');
```
- **Why it's a risk:** `media_id` is `NOT NULL` with an immediate FK to `sys_media`. InnoDB enforces FKs on INSERT; `sys_media` has no row with `id = 0`, so the initial `create()` throws `SQLSTATE[23000] Cannot add or update a child row` before the media is ever uploaded. DMS upload (REQ-CRT-009, BR-CRT-029) fails for every document → also breaks the BR-CRT-008 rejected-document gate dependency for TCs.
- **Fix:** Upload the media first and create the row with the real `media_id`; or make `media_id` nullable and create-then-update inside a transaction with FK-safe ordering.
- **Confidence:** High (MySQL FK is non-deferred). **Systemic?** Module-local.

### [VAL-CRT-001] P1 | BR-CRT-023 not enforced — TC issuable without mandatory leaving date/reason (silent defaults)
- **Location:** `Modules/Certificate/app/Http/Requests/ApproveCertificateRequestRequest.php:18-22`; `CertificateRequestController.php:144-154`
- **Evidence:**
```php
'date_of_leaving'    => ['nullable', 'date'],
'reason_for_leaving' => ['nullable', 'string', 'max:255'],
```
```php
'date_of_leaving'    => $validated['date_of_leaving'] ?? today()->toDateString(),
'reason_for_leaving' => $validated['reason_for_leaving'] ?? 'Transfer',
```
- **Why it's a risk:** BR-CRT-023 requires date-of-leaving and reason-for-leaving to be **mandatory** for a TC. The validation marks them nullable and the controller substitutes silent defaults (`today()`, `'Transfer'`) → a legally-mandated register entry can be written with fabricated leaving data. (Currently moot only because BUG-CRT-001/002 break TC entirely.)
- **Fix:** Make both `required` when the certificate type code is `TC` (conditional rule keyed on the request's type).
- **Confidence:** High. **Systemic?** Module-local.

### [SEC-CRT-001] P1 | Keyed third-party verification interface is a non-functional scaffold stub (REQ-CRT-007 AC4 / BR-CRT-027)
- **Location:** `Modules/Certificate/app/Http/Controllers/CertificateController.php:13-55`; `Modules/Certificate/routes/api.php:6-7`
- **Evidence:**
```php
public function store(Request $request) {}
public function update(Request $request, $id) {}
public function destroy($id) {}
public function index() { return view('certificate::index'); }   // returns a Blade view from an API resource
```
```php
Route::apiResource('certificates', CertificateController::class)->names('certificate');
```
- **Why it's a risk:** The advertised keyed/programmatic verification interface (REQ-CRT-007 AC4; BR-CRT-027 "rejects calls without a valid access key") does not exist — `CertificateController` is the generated scaffold (empty writers, view-returning readers) with no access-key check and no verify action. Not a security hole (the resource sits behind `auth:sanctum`), but a functional gap and a misleading public contract. **De-dupe:** this is the same item the FRD logs as ENH-CRT-012 / RISK-CRT-003.
- **Fix:** Implement a keyed `GET /api/v1/certificate/verify` action with an access-key middleware, or remove the stub `apiResource` and the advertised interface.
- **Confidence:** High. **Systemic?** Module-local.

---

## P2 Findings

### [BUG-CRT-005] P2 | `restore()` / `forceDelete()` always 403 on Issued, Request, and Template (missing policy abilities, no `before()`)
- **Location:** policies `CertificateIssuedPolicy.php`, `CertificateRequestPolicy.php`, `CertificateTemplatePolicy.php`; callers e.g. `CertificateIssuedController.php:150,161`, `CertificateRequestController.php:202,213`, `CertificateTemplateController.php:297,308`
- **Evidence:** `CertificateIssuedPolicy` defines only `viewAny, view, download, revoke`; `CertificateRequestPolicy` only `viewAny, view, create, approve, reject`; `CertificateTemplatePolicy` only `viewAny, view, create, update, delete`. No `before()` hook exists in any CRT policy. Controllers call `Gate::authorize('restore'|'forceDelete', Model::class)`.
- **Why it's a risk:** With a policy registered for the model but no matching ability method and no `before()`, Laravel denies → `AuthorizationException` (403) for **every** user. The trashed-restore and force-delete flows are dead for 6 of 8 resources. Fail-closed (safe), but the admin recovery UI is unusable. (`CertificateTypePolicy` correctly defines `restore` + `forceDelete`.)
- **Fix:** Add `restore()`/`forceDelete()` to the three policies (mirroring `CertificateTypePolicy`), or add a super-admin `before()` hook.
- **Confidence:** High. **Systemic?** Module-local.

### [DATA-CRT-001] P2 | Merge fields {{father_name}}/{{mother_name}}/{{blood_group}} are always blank; {{nationality}}/{{religion}} emit raw IDs
- **Location:** `Modules/Certificate/app/Services/CertificateGenerationService.php:262,280-284`
- **Evidence:**
```php
$profile = DB::table('std_student_profiles')->where('student_id',$studentId)->first();
'{{father_name}}' => $profile?->father_name ?? '',   // column does not exist on std_student_profiles
'{{blood_group}}' => $profile?->blood_group ?? '',   // column does not exist
'{{nationality}}' => $profile?->nationality ?? '',   // this is a sys_dropdowns FK id, not a label
```
- **Why it's a risk:** `std_student_profiles` has no `father_name`, `mother_name`, or `blood_group` columns (verified: it holds bank/RTE/EWS/measurement fields + `religion`/`caste_category`/`nationality`/`mother_tongue` as dropdown FK ids). These placeholders therefore render empty on every certificate, and `{{nationality}}`/`{{religion}}` print numeric ids instead of labels. **BR-CRT-007 (blood group on ID cards) is effectively unenforced** — the field is always blank, not "blank only when absent."
- **Fix:** Source parent names from the correct entity (guardians/relations table), join `sys_dropdowns` for nationality/religion labels, and source `blood_group` from wherever it actually lives (e.g. `std_health_profiles`).
- **Confidence:** High (columns verified absent). **Systemic?** Module-local.

### [SEC-CRT-002] P2 | No `EnsureTenantHasModule` middleware — schools without the Certificate plan can access all features
- **Location:** `Modules/Certificate/app/Providers/RouteServiceProvider.php:28-44`; `Modules/Certificate/routes/web.php` (no module gate)
- **Evidence:** Route stack is `['web', InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive]` — no `EnsureTenantHasModule`. `grep EnsureTenantHasModule Modules/Certificate` → none.
- **Why it's a risk:** Any active tenant can reach Certificate features even if the module is not in its subscription plan. Same pattern flagged platform-wide as SEC-LMS-001 / SEC-HPC-003 (TEN-RTG-001).
- **Fix:** Add `EnsureTenantHasModule::class.':Certificate'` to the module route group middleware.
- **Confidence:** High. **Systemic?** TEN-RTG-001 (platform pattern).

### [DEAD-CRT-001] P2 | Dead scaffold controller + API resource returning Blade views
- **Location:** `Modules/Certificate/app/Http/Controllers/CertificateController.php` (whole file)
- **Evidence:** `index()/create()/show()/edit()` return `view('certificate::index'|'create'|'show'|'edit')` — only `index.blade.php` exists; `create/show/edit` views do not. Writers are empty.
- **Why it's a risk:** Routed via `apiResource` (SEC-CRT-001); the read actions 500 (missing view) when hit as an API. Dead/contradictory code surface.
- **Fix:** Remove or replace with the real keyed-verify implementation (folds into SEC-CRT-001).
- **Confidence:** High. **Systemic?** Module-local.

### [PERF-CRT-001] P2 | BR-CRT-033 overdue-request highlight not implemented (RPT-CRT-002 PARTIAL)
- **Location:** `CertificateReportController.php` (reports index computes counts only); `CertificateRequestController::index()` (status filter only, no `required_by_date` overdue flag)
- **Why it's a risk:** RPT-CRT-002 requires the pending report to highlight requests past their required-by date (BR-CRT-033). Neither the reports panel nor the requests list computes/marks overdue.
- **Fix:** Add an overdue computation (`required_by_date < today()` and not terminal) and surface it in the pending view.
- **Confidence:** Medium (views not exhaustively read). **Systemic?** Module-local.

### [SCH-CRT-001] P2 | D29 — `->enum()` used across crt migrations instead of `sys_dropdowns` FK
- **Location:** crt tenant migrations — `verification_status` (`...083600`), `status`/`recipient_type`/`requester_type` (`crt_requests`, `crt_issued_certificates`), `category`/`card_type`/`card_size`/`orientation` (types/id-card/templates).
- **Why it's a risk:** D29 platform convention: pick-from-list columns should be `sys_dropdowns` FKs, not ENUMs (rigid, non-extensible per school). ~10 enum columns in this module.
- **Fix:** Migrate status/category sets to `sys_dropdowns` FKs where they are business-extensible; ENUM is tolerable only for code-gated binaries.
- **Confidence:** High. **Systemic?** D29 (platform, ~476 enums).

---

## P3 Findings

- **[VAL-CRT-002] P3 — D30 systemic:** all 10 FormRequests `authorize(){ return true; }` ("Gate checked in controller"). Mitigated — every consuming controller action has a matching `Gate::authorize()`. Recommend defense-in-depth `Gate::allows()` in `authorize()`. (Platform norm 437/485.)
- **[DAT-CRT-002] P3 — serial counter first-of-year race:** `QrVerificationService::incrementSerialCounter():25-39` does `lockForUpdate()->first()` then `create()` when absent. Two concurrent *first* generations for a (type, year) can both miss and collide on `UNIQUE(type, year)`; the loser throws. Subsequent allocations are correctly serialized. Pre-seed the counter on type creation, or catch+retry on unique violation.
- **[SCH-CRT-002] P3 — INT PK:** crt tables use `increments('id')` (signed INT). Platform norm (428/658); FK typing/2.1B-row note only.
- **[JOB-CRT-001] P3 — `BulkGenerateCertificatesJob` `tries=1`, no `$backoff`** (`:33`). Tenancy is correct (QueueTenancyBootstrapper enabled + dispatched in tenant context). Acceptable since per-student failures are logged and the batch continues; consider `tries=2` for transient infra faults.
- **[BUG-CRT-006] P3 — `resolveMergeFields():288` string/precedence smell:** `now()->format('Y').'-'.now()->year + 1` relies on PHP 8 `+` > `.` precedence; works on 8.2 but fragile. Use explicit `($y).'-'.($y+1)`.

**Verified false positives (do NOT report):**
- **RISK-CRT-005 (PDF storage not tenant-scoped):** mitigated — `config/tenancy.php` enables `FilesystemTenancyBootstrapper` with `suffix_storage_path => true`, so `storage_path('app/tenant_certificates/...')` resolves under `storage/tenant<id>/` per tenant. No cross-tenant collision/leak. (Code relies on implicit suffixing rather than an explicit `Storage::disk('tenant')` — note as hygiene, not a defect.)
- **`sys_dropdowns` / verification logging "wrong table":** `sys_dropdowns` exists in tenant_db (created as `sys_dropdown_table`, then renamed by `...145407_rename_sys_dropdown_table_to_sys_dropdowns`); `sys_activity_logs` exists (migration filename `create_activity_logs_table` but `Schema::create('sys_activity_logs')`). DMS category validation and verification/download logging target real tables. Correct the stale FRD/knowledge note that says `sys_dropdown_table`.

---

## Layer Health Summary

| # | Layer | Status | Key finding |
|---|-------|--------|-------------|
| 1 | DDL Schema Integrity | 🟡 Amber | D29 enums (SCH-CRT-001), INT PKs; otherwise clean, FK targets all exist |
| 2 | Migration ↔ Model ↔ DDL | 🟢 Green | Three-way reconcile passes; `$fillable` matches columns (no D17) |
| 3 | Model & ORM Correctness | 🟢 Green | Casts present (dates/booleans); relationships sound |
| 4 | Code Quality & Dead Code | 🟡 Amber | Dead scaffold controller (DEAD-CRT-001); no `dd()`/debug in app code |
| 5 | Authorization & Access Control | 🟡 Amber | Strong policy/gate coverage, but restore/forceDelete 403 (BUG-CRT-005); no module-plan gate (SEC-CRT-002) |
| 6 | Multi-Tenancy Isolation | 🟢 Green | Full RSP stack; storage suffixed; QueueTenancyBootstrapper; no `initialize()` leak; no bare cache keys |
| 7 | Input Validation / Mass-assign | 🟡 Amber | No `$request->all()`; good rules; D30 systemic; BR-CRT-023 gap (VAL-CRT-001) |
| 8 | Data Integrity, Tx & Concurrency | 🟡 Amber | Good transactions + serial `lockForUpdate`; first-of-year race; TC writes broken |
| 9 | Performance & Query Efficiency | 🟡 Amber | Lists paginated; reasonable; no egregious N+1 found |
| 10 | Queue / Job / Scheduler | 🟢 Green | Job tenancy correct; timeout set; inherits platform Horizon mismatch |
| 11 | Frontend / Blade / Output Safety | 🟡 Amber | Public verify page privacy-safe; views not exhaustively XSS-audited |
| 12 | Deployment & Operational Readiness | 🟡 Amber | Route-cache safe; no module secret; inherits DEPLOY-HRZ-01 for bulk |

---

## STEP 1 Reading-Discipline Output — three-way reconcile + snapshot corrections

| Claim under test | DDL/FRD says | Live tenant migration | Live code | Verdict |
|------------------|--------------|-----------------------|-----------|---------|
| Fee source table | `fin_fee_dues`/`fin_fee_invoices` | `fee_invoices` (no `student_id`/`payment_status`/`net_payable`) | uses `fin_fee_invoices` | **BUG-CRT-001 (wrong table+cols)** |
| Student profile table | `std_profiles` (knowledge) / `std_student_profiles` | `std_student_profiles` (no father/mother/blood cols) | mixed: merge uses `std_student_profiles`, TC/ID-card use `std_profiles` | **BUG-CRT-002/003 + DATA-CRT-001** |
| Student class/section | — | via `std_student_academic_sessions`→`sch_class_section_jnt` | TC/ID-card join `std_students.class_id/section_id` (absent) | **BUG-CRT-002/003** |
| DOB column | — | `std_students.dob` | TC/ID-card read `date_of_birth` | **BUG-CRT-002/003** |
| Dropdown table | FRD: `sys_dropdown_table` | renamed to `sys_dropdowns` | uses `sys_dropdowns` | Code correct; **FRD note stale** |
| Verification log table | by design → `sys_activity_logs` | `sys_activity_logs` exists | uses `sys_activity_logs` | Correct (not a gap) |
| PDF storage isolation | RISK-CRT-005 "confirm" | n/a | `storage_path()` + `suffix_storage_path=true` | **Isolated — false positive** |
| 10 migrations / Dusk suite / rate-limit / API stub | per BA notes | 10 `crt_*` + tc_issued alter present | `throttle:20,60`; API is scaffold stub | All confirmed |

---

## FRD Gap Summary (Mode B) — REQ → DDL / Code / Test

| REQ | Feature | DDL | Code | Runtime | Test | Status |
|-----|---------|-----|------|---------|------|--------|
| REQ-CRT-001 | Type Management | ✅ | ✅ gated CRUD + serial-format validation | ✅ | Dusk | **DONE** |
| REQ-CRT-002 | Template Designer | ✅ | ✅ versioning, default toggle, preview, placeholder check | ✅ | Dusk | **DONE** |
| REQ-CRT-003 | Request Workflow | ✅ | ✅ FSM, duplicate block, auto-approve, attachment | ✅ | Dusk | **DONE** |
| REQ-CRT-004 | Generation & Issuance | ✅ | ✅ serial lock, HMAC, QR, PDF, revoke, duplicate watermark | ✅ | Dusk | **DONE** |
| REQ-CRT-005 | Transfer Certificate | ✅ | present | ❌ **throws (BUG-CRT-001/002)**; BR-CRT-001 override absent | partial | **BROKEN** |
| REQ-CRT-006 | Achievement & Bulk | ✅ | ✅ ≤200 sync / >200 queue; per-student error log | ✅* | Dusk | **DONE** (*inherits Horizon risk) |
| REQ-CRT-007 | Digital Verification | ✅ | QR+public+logging ✅; **keyed API stub (SEC-CRT-001)** | partial | Dusk | **PARTIAL** |
| REQ-CRT-008 | ID Card Generation | ✅ | config CRUD ✅; **generate throws (BUG-CRT-003)**; blood always blank | ❌ | Dusk | **BROKEN (generate)** |
| REQ-CRT-009 | DMS | ✅ | verify/list ✅; **upload throws (BUG-CRT-004)** | ❌ | Dusk | **BROKEN (upload)** |
| REQ-CRT-010 | Number Format Config | ✅ | ✅ tokens + seq validation; counter per type/year | ✅ | — | **DONE** |
| REQ-CRT-011 | Reports & Analytics | n/a | issued/TC/analytics/log ✅; **overdue highlight missing (PERF-CRT-001)** | ✅ | Dusk | **PARTIAL** |
| REQ-CRT-012 | Portal Access | n/a | depends on StudentPortal module | — | — | **NOT STARTED** |

---

## Business-Rule Enforcement (Mode C)

| BR | Type | Location | Status | Note / link |
|----|------|----------|--------|-------------|
| BR-CRT-001 | Validation | `generateTC():91` | **MISSING/BROKEN** | wrong table (BUG-CRT-001); fee-override never implemented |
| BR-CRT-002 | Concurrency | `incrementTcSlNo():56-66` (lockForUpdate) | **ENFORCED** (path unreachable while TC broken) | correct lock |
| BR-CRT-003 | Workflow | `checkDuplicate()` + watermark `renderHtml():343` | **ENFORCED** | |
| BR-CRT-004 | Validation | `StoreCertificateTypeRequest` (unique code + seq token) + serial format | **ENFORCED** | |
| BR-CRT-005 | Workflow | `verifyHash():136` returns REVOKED | **ENFORCED** | |
| BR-CRT-006 | Workflow | FK `crt_issued_certificates.template_id` ON DELETE RESTRICT | **ENFORCED** | |
| BR-CRT-007 | Validation | ID-card `show_blood_group` | **PARTIAL/BROKEN** | blood_group always blank (DATA-CRT-001) |
| BR-CRT-008 | Validation | `generateTC():103-113` rejected-doc count | **ENFORCED** (but unreachable; DMS upload broken — BUG-CRT-004) | |
| BR-CRT-009 | Workflow | `BulkGenerationController::generate():85` (>200 queue) | **ENFORCED** | |
| BR-CRT-010 | Permission | `verifyHash()` returns first-name+initial only | **ENFORCED** | |
| BR-CRT-011 | Workflow | `generateTC():160-173` sets `tc_issued`+withdrawn | **ENFORCED** (unreachable while TC broken) | |
| BR-CRT-012 | Workflow | template store/update clear-other-defaults | **ENFORCED** | |
| BR-CRT-013 | Validation | `RejectCertificateRequestRequest` required min:10 | **ENFORCED** | |
| BR-CRT-014 | Validation | `StoreCertificateRequestRequest` mimes+max:5120 | **ENFORCED** | |
| BR-CRT-015 | Concurrency | `incrementSerialCounter()` lockForUpdate in tx | **ENFORCED** | first-of-year race (DAT-CRT-002) |
| BR-CRT-016 | Workflow | `active()` scope + toggleStatus | **ENFORCED** | |
| BR-CRT-017 | Workflow | type destroy blocks if templates exist; forceDelete catches FK | **ENFORCED** | |
| BR-CRT-018 | Validation | `StoreCertificateTemplateRequest` placeholder==declared | **ENFORCED** | |
| BR-CRT-019 | Workflow | update() archives `TemplateVersion` before overwrite | **ENFORCED** | |
| BR-CRT-020 | Workflow | store() auto-approve + generate | **ENFORCED** | |
| BR-CRT-021 | Validation | `StoreCertificateRequestRequest` duplicate closure | **ENFORCED** | only when beneficiary set (OK for staff) |
| BR-CRT-022 | Permission | `download()` gate + revoked abort | **ENFORCED** | |
| BR-CRT-023 | Validation | `ApproveCertificateRequestRequest` nullable + defaults | **MISSING** | VAL-CRT-001 |
| BR-CRT-024 | Workflow | bulk per-student try/catch + error_log | **ENFORCED** | |
| BR-CRT-025 | Workflow | `logVerification()` → sys_activity_logs | **ENFORCED** | |
| BR-CRT-026 | Permission | route `throttle:20,60` | **ENFORCED** | |
| BR-CRT-027 | Permission | keyed API access-key check | **MISSING** | SEC-CRT-001 (stub) |
| BR-CRT-028 | Calculation | cards_per_sheet grid | **ENFORCED** (config) / generation broken (BUG-CRT-003) | |
| BR-CRT-029 | Validation | `StoreStudentDocumentRequest` mimes+max | **ENFORCED** | |
| BR-CRT-030 | Validation | `VerifyStudentDocumentRequest` required_if reject | **ENFORCED** | |
| BR-CRT-031 | Calculation | counter per type/year (year key) | **ENFORCED** | |
| BR-CRT-032 | Permission | per-tenant DB + gated reads | **ENFORCED** | |
| BR-CRT-033 | Calculation | overdue highlight | **MISSING** | PERF-CRT-001 |
| BR-CRT-034 | Permission | portal own-only | **N/A** | StudentPortal not built |

**Enforced: 26 · Partial: 2 (BR-007, BR-028) · Missing/Broken: 5 (BR-001, BR-023, BR-027, BR-033 + BR-008 reachable-only) · N/A: 1.**

---

## Systemic-Pattern Scorecard (Mode D — scoped to CRT)

| Pattern | Present? | Count / Evidence | Severity |
|---------|----------|------------------|----------|
| D17 — `$fillable` ⊄ columns | **No** | models reconcile with migrations | — |
| D24 — permission-prefix chaos/typos | **No** | uniform `certificate.*`; gates map to policies | — |
| D25 — `$request->all()` into models | **No** | all controllers use `$request->validated()` | clean |
| D29 — `->enum()` in migrations | **Yes** | ~10 enum cols (status/category/card_*) | P2 (SCH-CRT-001) |
| D30 — FormRequest `authorize(){return true}` | **Yes** | 10/10 (mitigated by controller gates) | P3 (VAL-CRT-002) |
| D36 — DDL GENERATED cols degraded | **No** | no generated columns in crt schema | — |
| Layer 2.5 — cross-DB / missing FK target | **No** | `sys_roles` not referenced; `sys_dropdowns` exists in tenant | clean |
| Layer 6.2 — `initialize()` w/o `end()` | **No** | none; uses middleware stack | clean |
| Layer 10.1 — job missing tenancy/retry | **Partial** | tenancy OK (bootstrapper); `tries=1`/no backoff | P3 (JOB-CRT-001) |
| TEN-RTG-001 — module-subscription middleware | **Yes (missing)** | no `EnsureTenantHasModule` | P2 (SEC-CRT-002) |

---

## vs Platform Baseline

- **Cleaner than the norm** on the highest-blast-radius patterns: **0** `$request->all()` (baseline 24 sites), **0** D17 fillable mismatches, **0** permission-prefix typos, **0** `initialize()` leaks, **0** cross-DB FK targets, correct job tenancy. Authorization coverage (policy + per-action gate) is well above the platform median.
- **At the norm** on D30 (10/10 `return true`) and D29 (enums) — both mitigated/systemic.
- **The module's distinctive risk is NOT systemic** — it is a self-contained cluster of wrong-table/column references (BUG-CRT-001…004) in the integration-heavy paths (fee, profile, class/section, media). These are the kind of defect the FRD's RISK-CRT-004 predicted ("no in-module unit/feature tests for concurrency-critical logic") — a single feature test against a seeded tenant would have caught every one of them.

---

## Recommended Fix Order (unblock-the-most-first)

1. **BUG-CRT-001 + BUG-CRT-002** — repoint TC fee gate to `fee_invoices`(via `fee_student_assignments`) and fix the TC snapshot joins (`dob`, academic-session class/section, `std_student_profiles`). Restores REQ-CRT-005 (P0 core). Add BR-CRT-001 override capture in the same pass.
2. **BUG-CRT-004** — fix DMS `media_id => 0` FK violation (upload-first or nullable+tx). Restores REQ-CRT-009 and unblocks the BR-CRT-008 TC gate.
3. **BUG-CRT-003 + DATA-CRT-001** — fix ID-card joins and source blood_group/parent names from real tables. Restores REQ-CRT-008 + BR-CRT-007.
4. **VAL-CRT-001** — make TC leaving date/reason required (BR-CRT-023).
5. **BUG-CRT-005** — add `restore`/`forceDelete` to Issued/Request/Template policies.
6. **SEC-CRT-002** — add `EnsureTenantHasModule:Certificate`.
7. **SEC-CRT-001 / DEAD-CRT-001** — implement keyed verify API or remove the stub.
8. Add Pest feature tests for TC gate, DMS upload, ID-card generate, serial lock, duplicate detection (RISK-CRT-004) — these would have caught 1-4.
9. P2/P3 hygiene: D29 enums → dropdowns, overdue highlight (BR-CRT-033), serial first-of-year pre-seed, job `tries`.

---

## Next Steps
```
Audit complete — Health 66/100 (Amber; no P0 → uncapped).
1. Fix P1 runtime SQL bugs (TC/DMS/ID-card)   → act as Developer
2. Fix D29 enums / schema hygiene             → act as DB Architect
3. Completeness score                          → act as Status_Analyzer
4. Add feature tests (RISK-CRT-004)            → act as Testing Architect
5. Re-run Mode D systemic sweep platform-wide
```

*Issue IDs (BUG-/SEC-/VAL-/DATA-/PERF-/SCH-/DAT-/JOB-/DEAD-CRT-*) are first-assigned for CRT in this audit and are stable. REQ-/BR-/RPT- IDs reused verbatim from CRT_FRD_Complete_2026-06-29.md.*
