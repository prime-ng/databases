# Technical Audit — FrontOffice (FOF) — 2026-06-29

## Executive Summary
Mode A (Standard Deep 12-Layer) read-only audit of `Modules/FrontOffice/` (FOF, prefix `fof_`).
The module is structurally complete (22 controllers, 22 models, 4 services, 13 policies, 10 FormRequests,
118 views) and — contrary to the dated module-knowledge snapshot — the `FlagOverstayCommand`
(`fof:flag-overstay`) **does** exist; but its business-rule and cross-module wiring is shallow: the worst
findings are a **missing fee-clearance gate on TC/Migration certificate issuance (BR-FOF-005)**, a
**circular "distribution" that only flips a status flag** (no recipient resolution, no per-recipient log,
no NTF — BR-FOF-018/REQ-FOF-009), a **government-inspection retention guard that is silently bypassed**
(BR-FOF-007), and an **ATT-sync retry job that carries no tenant context**. No P0 (no live cross-tenant
leak, no unauth write route, no committed secret in-module) — so **Health is NOT P0-capped**.

## Audit Mode(s) Run
- Mode A — full 12-layer deep scan (read-only).
- Light Mode B/C cross-reference against `FOF_FRD_2026-06-29.md` (BR-FOF-001..023) for the BR-enforcement findings.

## Health Score
**41 / 100** (weighted). **No P0 → no hard cap applied.**
Layer scores (G=1.0 / A=0.5 / R=0.0): L6 A, L5 A, L8 R, L7 A, L12 A, L2 A, L1 A, L9 A, L10 R, L4 A, L3 A, L11 A.

| Severity | Count |
|----------|-------|
| P0 | 0 |
| P1 | 9 |
| P2 | 6 |
| P3 | 3 |

---

## P1 Findings

### [DAT-FOF-001] P1 | Certificate issuance has NO fee-clearance check (BR-FOF-005)
- **Location:** `app/Http/Controllers/CertificateRequestController.php:210-238` (`issue()`); no `CertificateIssuanceService` file exists.
- **Evidence:**
```php
public function issue(Request $request, CertificateRequest $cert): RedirectResponse {
    Gate::authorize('frontoffice.certificate.issue');
    throw_unless($cert->status === 'Approved', new DomainException("Only Approved requests can be issued."));
    $data = $request->validate(['issued_to' => 'required|string|max:100']);
    DB::transaction(function () use ($cert, $data) {
        $cert->update(['status'=>'Issued','cert_number'=>$this->generateCertNumber($cert->cert_type), ...]);
    });
```
- **Why it's a risk:** BR-FOF-005 requires a StudentFee clearance check before issuing `TC_Copy`/`Migration` certificates. `issue()` performs no fee check and there is no StudentFee reference anywhere in the controller. TC/Migration certs are issued to fee-defaulters — a compliance/financial-policy violation.
- **Fix:** Extract a `CertificateIssuanceService::issue()` that, for `cert_type IN (TC_Copy, Migration)`, calls the StudentFee clearance service and blocks issuance on outstanding dues before generating the number/PDF.
- **Confidence:** High
- **Systemic?:** Module-local; mirrors the platform pattern of design-decision services that were never created.

### [BUG-FOF-002] P1 | Circular "distribution" is a status-flip stub — no recipient resolution, no per-recipient log, no NTF (BR-FOF-018 / REQ-FOF-009)
- **Location:** `app/Services/CircularService.php:93-110` (`distribute()`).
- **Evidence:**
```php
public function distribute(Circular $circular): Circular {
    throw_unless($circular->status === 'Approved', new DomainException(...));
    return DB::transaction(function () use ($circular) {
        $circular->update(['status'=>'Distributed','distributed_by'=>auth()->id(),'distributed_at'=>now(), ...]);
        ...
    });
}
```
- **Why it's a risk:** REQ-FOF-009 (a P0 requirement) and BR-FOF-018 require distribution to resolve recipients strictly from the audience config, write `fof_circular_distributions` per-recipient rows (Queued/Sent/Delivered/Failed), and dispatch via NTF. None of that happens — the circular is marked "Distributed" but no parent/staff ever receives it and no delivery log exists. The `CircularDistribution`/`CommunicationLog` models are unused by this path.
- **Fix:** Implement audience resolution (All/Parents/Staff/Both/Specific_Class/Specific_Section → recipient set), create `fof_circular_distributions` rows, and fire an NTF event per recipient; only then flip status.
- **Confidence:** High
- **Systemic?:** Module-local (also see the empty `EventServiceProvider::$listen` — events `fof.*` are dispatched but no listener is registered).

### [SEC-FOF-001] P1 | Government-inspection retention guard (BR-FOF-007) is bypassed by permission-string gates
- **Location:** `app/Http/Controllers/VisitorController.php:112` (`destroy`), `:169` (`forceDelete`); guard lives in `app/Policies/VisitorPolicy.php:15-22,49-56`.
- **Evidence:**
```php
// VisitorController::destroy()
Gate::authorize('frontoffice.visitor.delete');   // permission string, NO model passed
$visitor->delete();
// VisitorPolicy::delete(User $user, Visitor $visitor) — the govt guard that is NEVER reached:
if ($visitor->purpose && $visitor->purpose->is_government_visit) { return false; }
```
- **Why it's a risk:** `Gate::authorize('frontoffice.visitor.delete')` resolves the Spatie *permission* ability, not the `VisitorPolicy::delete()` *policy method* (which requires `Gate::authorize('delete', $visitor)`). The `is_government_visit` block is therefore dead code on the delete/forceDelete paths — a CBSE/State-Board inspection visitor can be soft- or permanently-deleted, violating BR-FOF-007's permanent-retention rule.
- **Fix:** Call `Gate::authorize('delete', $visitor)` / `Gate::authorize('forceDelete', $visitor)` (model-bound) so the policy runs, and have the policy `->can()` the permission internally; or re-check `is_government_visit` in the controller.
- **Confidence:** High
- **Systemic?:** Permission-string-vs-policy-method confusion — likely repeats across modules that registered policies but call string gates.

### [JOB-FOF-001] P1 | EarlyDepartureAttSyncJob carries no tenant context (and no $timeout)
- **Location:** `app/Jobs/EarlyDepartureAttSyncJob.php:26-77`.
- **Evidence:**
```php
public function __construct(private readonly int $earlyDepartureId) {}   // no tenant id
public function handle(): void {
    $departure = EarlyDeparture::find($this->earlyDepartureId);          // tenant table fof_early_departures
    ... app(\Modules\Attendance\Services\AttendanceService::class)->markAbsentFromPeriod(...)  // tenant writes
```
- **Why it's a risk:** On the `database` queue worker, unless `QueueTenancyBootstrapper` is enabled, `handle()` runs in central context: `EarlyDeparture::find()` returns null → the job silently returns, and BR-FOF-013 ("ATT sync must never fail silently / always retried") is defeated; if a different tenant is active, it could write to the wrong DB. The job declares `$tries`/`$backoff` but no `$timeout`, and `handle()`/`failed()` typehint `\Exception` (a `\Throwable`/`TypeError` from the cross-module call would not be caught).
- **Fix:** Pass `tenant()->id` into the constructor and `tenancy()->initialize($tenantId)` (or `$tenant->run()`) at the top of `handle()`; add `$timeout`; widen catches to `\Throwable`.
- **Confidence:** Medium (leak is conditional on `QueueTenancyBootstrapper` config; silent-no-op risk is concrete).
- **Systemic?:** D-pattern — platform jobs missing tenancy re-init (Vendor/Inventory/Hostel/FrontOffice baseline).

### [JOB-FOF-002] P1 | `fof:flag-overstay` is never scheduled and not tenant-wrapped (BR-FOF-002)
- **Location:** `app/Console/FlagOverstayCommand.php`; registered in `app/Providers/FrontOfficeServiceProvider.php:74` but no schedule entry exists anywhere (`grep` of app/, routes/, module = none); `app/Services/VisitorService.php:60-69` (`flagOverstay()`).
- **Evidence:**
```php
// FrontOfficeServiceProvider — command registered but never scheduled:
$this->commands([FlagOverstayCommand::class]);
// VisitorService::flagOverstay() — bulk update of tenant table, no closing-time / date filter:
return Visitor::where('status','In')->whereNull('out_time')
    ->update(['status'=>'Overstay','updated_by'=>0,'updated_at'=>now()]);
```
- **Why it's a risk:** BR-FOF-002 (P0) requires auto-flagging at closing time. With no scheduler entry the command never runs, so the visitor FSM terminal state `Overstay` is unreachable in production. When it is run, it must be wrapped in `tenants:run` (it mutates the tenant `fof_visitors` table) — a bare central run hits the wrong DB. It also has no closing-time guard, so a mid-day run would wrongly flag everyone currently `In`.
- **Fix:** Schedule `tenants:run fof:flag-overstay` daily at the configured closing time; add a closing-time/date guard inside `flagOverstay()`.
- **Confidence:** High (unscheduled); Medium (tenant-wrap requirement).
- **Systemic?:** D-pattern — tenant commands scheduled on central context (cf. Hostel `hst:escalate-complaints`).

### [VAL-FOF-001] P1 | Appointment double-booking (BR-FOF-017) is not enforced
- **Location:** `app/Http/Controllers/AppointmentController.php:62-81` (`store()`); `app/Http/Requests/AppointmentRequest.php:18-36`.
- **Evidence:** `store()` generates a number and `Appointment::create(...)` with no slot-overlap query; `AppointmentRequest::rules()` validates fields only (`end_time after start_time`) — no overlap rule against existing `with_user_id` appointments.
- **Why it's a risk:** BR-FOF-017 requires that a new appointment overlapping a non-cancelled appointment for the same staff member be blocked. As written, the same staff member can be booked into overlapping slots. The `idx_fof_apt_slot` composite index exists but no code uses it.
- **Fix:** Before create, query existing non-cancelled appointments for `with_user_id` on `appointment_date` where `start_time < new.end_time AND end_time > new.start_time`; reject on hit (ideally inside a transaction with a row/advisory lock).
- **Confidence:** High
- **Systemic?:** Module-local concurrency/validation gap.

### [SEC-FOF-002] P1 | Anonymous feedback stores respondent identity (BR-FOF-010)
- **Location:** `app/Http/Controllers/FeedbackController.php:260-267` (`publicSubmit()`).
- **Evidence:**
```php
FeedbackResponse::create([
    'feedback_form_id'   => $form->id,
    'respondent_user_id' => auth()->id(),   // unconditional; is_anonymous_allowed ignored
    'responses_json'     => $data['answers'],
    'created_by'         => auth()->id() ?? 0, ...
]);
```
- **Why it's a risk:** BR-FOF-010 (and design-decision #5) require NULL respondent identity for anonymous forms. The form's `is_anonymous_allowed` flag is never consulted; if a logged-in staff/admin opens the public token URL in the same browser session, their user id is persisted against the "anonymous" response — de-anonymization.
- **Fix:** Set `respondent_user_id = $form->is_anonymous_allowed ? null : auth()->id();` and do the same for `created_by/updated_by`.
- **Confidence:** High
- **Systemic?:** Module-local privacy gap.

### [BUG-FOF-001] P1 | `toggleStatus(): JsonResponse` references an unimported class — fatal Error on the live toggle-status routes
- **Location:** `app/Http/Controllers/CertificateRequestController.php:151` and `app/Http/Controllers/ComplaintController.php:142` (neither file imports `Illuminate\Http\JsonResponse` — verified `grep -c` = 0). Routes: `routes/web.php:207` and `:222`.
- **Evidence:**
```php
public function toggleStatus(CertificateRequest $cert): JsonResponse   // resolves to
// Modules\FrontOffice\Http\Controllers\JsonResponse — class does not exist
```
- **Why it's a risk:** With no `use Illuminate\Http\JsonResponse;`, the return type resolves to a non-existent class in the controller namespace; invoking the mapped `*/toggle-status` route throws `Error: Class "...Controllers\JsonResponse" not found` → HTTP 500. (Sister controllers — Visitor/Circular/Key/Feedback/Postal — correctly import it.)
- **Fix:** Add `use Illuminate\Http\JsonResponse;` to both controllers.
- **Confidence:** High
- **Systemic?:** Module-local (2 sites).

### [SEC-FOF-003] P1 | All 10 FormRequests `authorize()` return hardcoded `true` (D30)
- **Location:** every file in `app/Http/Requests/` (Appointment, DispatchRegister, EarlyDeparture, IssueGatePass, KeyRegister, LostFound, PhoneDiary, PostalRegister, RegisterVisitor, StoreVisitorPurpose).
- **Evidence:** `public function authorize(): bool { return true; }` ×10.
- **Why it's a risk:** Defense-in-depth collapses to the controller's `Gate::authorize()` alone. The controllers DO currently gate every action, so this is not an open hole today — but any new/forgotten controller gate leaves zero fallback (the exact D30 failure mode).
- **Fix:** Return `Gate::allows('frontoffice.<entity>.<action>')` matching each route, keeping controller gates too.
- **Confidence:** High
- **Systemic?:** D30 platform-wide (437/485 baseline) — FOF is fully on-pattern (10/10).

---

## P2 Findings

### [DAT-FOF-002] P2 | Register-number generators use unlocked read-modify-write (BR-FOF-016 race)
- **Location:** `VisitorService::generatePassNumber` (`Services/VisitorService.php:74-86`), `GatePassService::generatePassNumber` (`:144-156`), `EarlyDepartureService::generateDepartureNumber` (`:106-118`), `CircularService::generateCircularNumber` (`:132-145`), `CertificateRequestController::generateRequestNumber/generateCertNumber` (`:284-304`), `PostalRegisterController::generatePostalNumber` (`:173-184`), `AppointmentController::generateNumber` (`:225-236`), `ComplaintController::generateComplaintNumber` (`:232-241`).
- **Evidence:** every generator does `... ->orderByDesc(col)->value(col)` then `(int)substr(...)+1` with no `lockForUpdate`/atomic counter.
- **Why it's a risk:** Two concurrent inserts compute the same `NNN` → duplicate register numbers (violating BR-FOF-016 uniqueness) or, where a DB UNIQUE exists, a 500 on the loser. Front-desk concurrency (two receptionists) is realistic.
- **Fix:** Generate inside the create transaction with `lockForUpdate()` on the prefix range, or use a dedicated atomic sequence table / DB `INSERT ... ON DUPLICATE KEY` retry.
- **Confidence:** High · **Systemic?:** Module-wide pattern.

### [DAT-FOF-003] P2 | Postal `update()` bypasses the acknowledgement lock (BR-FOF-009)
- **Location:** `app/Http/Controllers/PostalRegisterController.php:150-162` (`update()`) vs `:79-93` (`acknowledge()`).
- **Evidence:** `acknowledge()` guards with `abort_if($postal->isLocked(), 422, ...)`, but `update()` calls `$postal->update($data)` with no `isLocked()` check.
- **Why it's a risk:** BR-FOF-009 locks an entry from *modification* after acknowledgement; the edit/update path still allows changes to a locked record, breaking the audit trail.
- **Fix:** `abort_if($postal->isLocked(), 422, ...)` at the top of `update()` (and `destroy()`). Confidence: High.

### [DAT-FOF-004] P2 | Key issue and gate-pass creation lack row locks (BR-FOF-012 / BR-FOF-004 race)
- **Location:** `KeyRegisterController::issue()` (`:106-130`), `GatePassService::createPass()` (`Services/GatePassService.php:20-48`).
- **Evidence:** `abort_if($key->status !== 'Available', ...)` then `update(...)` with no lock; gate-pass `->whereIn('status',[...])->exists()` then `create()` inside a transaction but without `lockForUpdate` on the student's passes.
- **Why it's a risk:** Concurrent requests both pass the check → a key issued to two holders, or a student holding two active passes (BR-FOF-004). Low contention, hence P2.
- **Fix:** `lockForUpdate()` the row(s) inside the existing transaction before the guard. Confidence: High.

### [BUG-FOF-003] P2 | Front-office complaint escalation does not create a linked CMP record (BR-FOF-020)
- **Location:** `app/Http/Controllers/ComplaintController.php:180-199` (`escalate()`).
- **Evidence:** `escalate()` only `$complaint->update(['status'=>'Escalated', ...])` — no write to the Complaint (CMP) module, no linkage id stored.
- **Why it's a risk:** BR-FOF-020 / REQ-FOF-017 require escalation to create a linked `cmp_*` record; the full grievance workflow never starts.
- **Fix:** In the transaction, create the CMP-module record and persist its id on the FOF complaint. Confidence: High.

### [SEC-FOF-004] P2 | Aadhaar/ID-proof stored without encryption; no masking accessor (BR-FOF-015)
- **Location:** `app/Models/Visitor.php:20-50` (`$fillable` has `id_proof_number`; `$casts` has no `encrypted`/accessor).
- **Why it's a risk:** BR-FOF-015 requires full number stored under the tenant encryption policy and displayed masked to last 4. The model stores it plaintext and provides no masking accessor — confidential PII at rest.
- **Fix:** Add an `encrypted` cast (or tenant crypto) for `id_proof_number` and a `maskedIdProof` accessor for the UI. Confidence: Medium (UI masking may exist in Blade; encryption-at-rest is definitely absent).

### [PERF-FOF-001] P2 | Unbounded `->get()` on growing tenant tables / repeated full student loads
- **Location:** `CertificateRequestController::index/create/edit` load `Student::where('is_active',true)->...->get()` (full student table) on every render (`:35,43,106`) plus `pending->get()` (`:24-28`); `KeyRegisterController::index` three `->get()` (`:38-45`); `ComplaintController::index` open list `->get()` (`:36-40`); `AppointmentController::index/calendar` `->get()`.
- **Why it's a risk:** Loading the entire active-student set per certificate page, and unpaginated status lists, scale with school size — slow front-desk pages.
- **Fix:** Paginate status lists; replace the full-student preload with a server-side AJAX search/autocomplete. Confidence: High.

---

## P3 Findings

### [DEAD-FOF-001] P3 | Commented-out expiry guards in public feedback
- **Location:** `app/Http/Controllers/FeedbackController.php:178-180` (publicForm) and `:250-254` (publicSubmit) — `// if ($form->expires_at && ...)` blocks disabled. Intent existed; protection inert. Fix: restore once `expires_at` exists, or remove. Confidence: High.

### [BUG-FOF-004] P3 | Register-number formats deviate from BR-FOF-016 spec
- **Location:** `ComplaintController::generateComplaintNumber` produces `CMP-YYYYMMDD-NNN` (spec: `FOF-CMP-YYYY-NNNNN`); `CertificateRequestController::generateCertNumber` produces `BON/YYYY/NNNN` with a slash (spec: `BON-YYYY-NNN`); `generateRequestNumber` produces `CERT-YYYYMMDD-NNN` (spec: `CERT-YYYY-NNNNN`). Cosmetic/spec mismatch. Confidence: High.

### [ORM-FOF-001] P3 | `updated_by => 0` written by background paths (non-existent user)
- **Location:** `EarlyDepartureAttSyncJob` (`:43,63,71,85`), `VisitorService::flagOverstay` (`:66`). Writes audit `updated_by = 0` (no such `sys_users` row). Use NULL or a designated system-user id. Confidence: High.

---

## Layer Health Summary

| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema | Amber | Not deeply re-audited here; 0 module migrations (DDL-only, 22 tables). |
| 2 Migration↔Model↔DDL | Amber | Module ships 0 migrations — fresh-tenant bootstrap relies on central/DDL; verify `fof_*` exist in tenant migration set. |
| 3 ORM | Amber | Casts adequate; `updated_by=0` background writes (ORM-FOF-001). |
| 4 Code Quality | Amber | No `dd()`/debug; but two undefined-class `JsonResponse` return types (BUG-FOF-001). |
| 5 Authorization | Amber | Controllers gate every action, but BR-FOF-007 policy bypass (SEC-FOF-001) + D30 (SEC-FOF-003). |
| 6 Tenancy | Amber | RSP has full tenancy stack (good); job/command tenancy gaps (JOB-FOF-001/002); no `initialize()` leaks. |
| 7 Validation/Mass-assign | Amber | Validation present, no `$request->all()`; appointment overlap unchecked (VAL-FOF-001); D30. |
| 8 Data Integrity/Tx | Red | Missing fee gate (DAT-FOF-001), number races (DAT-FOF-002), postal-lock bypass (DAT-FOF-003), issue races (DAT-FOF-004). |
| 9 Performance | Amber | Unbounded gets / full student preloads (PERF-FOF-001). |
| 10 Queue/Job | Red | Job no tenant context/no timeout; overstay command unscheduled (JOB-FOF-001/002). |
| 11 Frontend | Amber | No XSS spotted in spot-checks; 118 views not exhaustively scanned. |
| 12 Deployment | Amber | 0 migrations + unscheduled tenant command; platform queue/Horizon mismatch is platform-level. |

## vs Platform Baseline
- **D30** FormRequest `authorize(){return true;}` — 10/10, fully on the platform norm.
- **D25** `$request->all()` into models — **0 sites** (better than baseline; controllers use `validated()` or inline `validate()`).
- **Debug contamination** — none (`dd/dump/var_dump` = 0).
- **Jobs missing tenancy** — 1/1 (matches the FrontOffice baseline entry).
- **Tenancy RSP** — full stack present (not a D23 offender).

## Recommended Fix Order
1. **DAT-FOF-001** fee-clearance gate on TC/Migration issuance (compliance/financial) + create `CertificateIssuanceService`.
2. **BUG-FOF-002** implement real circular distribution (recipient resolution + `fof_circular_distributions` + NTF).
3. **SEC-FOF-001** model-bound gate so BR-FOF-007 retention guard actually runs.
4. **BUG-FOF-001** add the missing `JsonResponse` imports (trivial, unblocks 2 live routes).
5. **JOB-FOF-001 / JOB-FOF-002** tenant-context the ATT job; schedule `tenants:run fof:flag-overstay`.
6. **VAL-FOF-001** appointment overlap check; **SEC-FOF-002** anonymous-feedback NULL identity.
7. Concurrency hardening: **DAT-FOF-002/003/004** (locks on number-gen, postal update, key/gate-pass issue).
8. **SEC-FOF-003** (D30) FormRequest gates; **BUG-FOF-003** CMP escalation linkage; P2/P3 cleanup.

---
*Read-only audit. No application code modified. Issue codes start at 001 per prefix (no prior FOF codes in `lessons/known-issues.md`). Consolidation of known-issues / progress / decisions is left to the orchestrator.*

---

## STEP 1 Reading-Discipline Output (D-pattern) — added 2026-06-29

### Three-Way Schema Reconciliation (DDL ↔ migration ↔ model)
| Subject | DDL spec | Live migration | Eloquent model / code | Verdict |
|---------|----------|----------------|-----------------------|---------|
| `fof_visitors.id_proof_number` (Aadhaar) | identity field; BR-FOF-015 = mask/encrypt | column present | model stores raw, no cast/mask | model vs BR intent → SEC-FOF-004 (P2). |
| Register-number columns | format per BR-FOF-016 | columns present | code generators deviate from the format | code vs spec → BUG-FOF-004 (P3). |
| 22 models ↔ 22 tables | 22 tables | tenant migrations present | 22 models | binding reconciled **clean**; defects are logic/concurrency, not orphan tables. |

### Module-Knowledge Snapshot Corrections (hints vs live code)
- "`fof:flag-overstay` command not found" → **stale**: `FlagOverstayCommand` **does exist** — but is never scheduled / not `tenants:run`-wrapped (JOB-FOF-002). The real defect differs from what the snapshot implied.
- `EarlyDepartureAttSyncJob` confirmed real and queued — but ships with no tenant context (JOB-FOF-001).
- RSP confirmed to carry the full tenancy stack (not a D23 offender).
