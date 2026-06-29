## Technical Audit — Complaint (CMP) — 2026-06-29

### Executive Summary
Mode A (12-layer deep audit) of the live `Modules/Complaint` tree. The headline finding is a **P0 hard failure**: the action-timeline subsystem references a `created_at` column that `cmp_complaint_actions` does not have (the table uses `action_timestamp`), so `logAction()` — called inside `store()`'s transaction — throws `Unknown column`, rolling back **every complaint registration**; the same mismatch breaks the timeline list (`->latest()`) and any `ComplaintAction` model write. Several previously-registered defects remain open (store() has no authorization gate, the SLA resolution deadline is never persisted, the status workflow has no transition guard, private notes are not query-filtered), and one new stored-XSS vector and one new ungated cross-module write were found. Tenancy and module-level deployment posture are clean. **Health: 35/100 (P0 cap applied).**

### Audit Mode(s) Run
- **Mode A** — full 12-layer scan (read-only), verified against live code (not the 2026-06-27 knowledge snapshot).
- Cross-referenced the 2026-06-27 Mode B/C findings to confirm what is fixed vs. still open.

### Health Score
Weighted index would be ~52 (Amber-heavy), but **a P0 caps module health at 40**; with two independent P0 classes (timeline hard-failure + the resolution/FSM data-integrity gaps) the effective score is **35/100**. State of play: not deployable for the complaint-registration path.

---

### P0 Findings

```
[BUG-CMP-020] Severity: P0 | action_timestamp/created_at mismatch breaks complaint create + timeline (severity raised from prior P2)
- Location: ComplaintController.php:1257 (logAction insert) ; ComplaintController.php:986 (buildComplaintActionsQuery ->latest()) ; ComplaintAction.php (model, no $timestamps override) ; migration create_cmp_complaint_actions_table.php:18
- Evidence:
    // migration — only column for time:
    $table->timestamp('action_timestamp')->useCurrent();   // NO created_at, no timestamps()
    // logAction() inserts a column that does not exist:
    DB::table('cmp_complaint_actions')->insert([ ... 'created_at' => now() ]);
    // timeline list orders by the same missing column:
    ComplaintAction::with([...])->...->latest();   // latest() => ORDER BY created_at
- Why it's a risk: The insert runs inside store()'s DB::beginTransaction try-block (line 395). 'created_at'
    does not exist on cmp_complaint_actions -> SQLSTATE[42S22] Unknown column -> catch -> DB::rollBack()
    -> NO complaint is ever created. Independently, buildComplaintActionsQuery()->latest() orders by the
    missing created_at, so the action-timeline list also errors, and any ComplaintAction::create()/save()
    fails because the model declares neither `public $timestamps = false` nor `const CREATED_AT`.
- Fix: (1) In logAction(), insert 'action_timestamp' => now() (not created_at). (2) On the ComplaintAction
    model set `public $timestamps = false;` (the table has no updated_at either) OR map CREATED_AT to
    'action_timestamp'. (3) Replace ->latest() with ->orderByDesc('action_timestamp').
- Confidence: High  (migration + model + both call sites read). Downgrades to P1 only if the deployed
    tenant schema diverges from the migration and actually carries a created_at column.
- Systemic? : Module-local manifestation of D17 (model/code references a column the DB lacks).
```

```
[ORM-CMP-001] Severity: P0 | ComplaintAction model missing $timestamps=false / CREATED_AT override (root cause of BUG-CMP-020)
- Location: Modules/Complaint/app/Models/ComplaintAction.php
- Evidence:
    protected $table = 'cmp_complaint_actions';
    protected $fillable = [ ... ];
    // (no `public $timestamps = false;`, no `const CREATED_AT`/`UPDATED_AT` — Eloquent defaults to created_at/updated_at)
- Why it's a risk: Eloquent will attempt to write created_at/updated_at (absent columns) on any save, and
    getCreatedAtColumn() returns 'created_at' for ->latest()/ordering. The module-knowledge design decision
    explicitly requires `$timestamps = false` here; the live model does not implement it.
- Fix: add `public $timestamps = false;` and order timeline reads by `action_timestamp`.
- Confidence: High
- Systemic? : D17 family.
```

```
[BUG-CMP-019] Severity: P0 (re-confirmed open) | Resolution due date (SLA deadline) never persisted at registration
- Location: ComplaintController.php:339-379 (Complaint::create array)
- Evidence:
    $complaint = Complaint::create([
        'ticket_no' => $ticketNo, ... 'status_id' => $statusId,
    ]);   // no 'resolution_due_at' key anywhere; SLA lookup not performed in store()
- Why it's a risk: BR-CMP-010 requires the deadline computed from Department SLA (or category default) to
    be saved at registration. It is never set, so SLA Violation reporting, the escalation level calc, and
    the dashboard "critical tickets" widget (which filters whereNotNull('resolution_due_at')) all operate on
    NULL — the entire SLA/escalation feature is inert.
- Fix: in store(), resolve the applicable Department SLA / category default and persist resolution_due_at
    on the create() (cross-ref FRD REQ-CMP-003 / BR-CMP-010).
- Confidence: High
- Systemic? : module-local.
```

### P1 Findings

```
[FE-CMP-001] Severity: P1 | Stored XSS — raw complaint description rendered unescaped (NEW)
- Location: resources/views/complaint/complaint/show.blade.php:160 ; .../edit.blade.php:150
- Evidence:
    {!! $complaint->description !!}
- Why it's a risk: description is free-text complainant input (store(): 'description' => 'nullable|string',
    no sanitisation), reachable from the student/parent portal submission path. A complainant who submits
    <script>… executes it in any staff member's browser when the ticket is viewed/edited -> stored XSS /
    session theft.
- Fix: render with {{ $complaint->description }} (auto-escape); if formatting is needed, sanitise via a
    HTML purifier allow-list before storing/displaying.
- Confidence: High
- Systemic? : module-local (Blade output-safety, Layer 11).
```

```
[SEC-CMP-007] Severity: P1 (re-confirmed open) | store() has no authorization gate
- Location: ComplaintController.php:211 (store)  — cf. create():175, update():573, destroy():741 which DO gate
- Evidence:
    public function store(Request $request)
    {   $isAnonymous = ...        // no Gate::authorize('tenant.complaint.create') anywhere in the method
- Why it's a risk: every other write method authorizes; store() does not. Any authenticated tenant user can
    POST a complaint regardless of the create permission (the gate exists only on the create() form view).
- Fix: add Gate::authorize('tenant.complaint.create'); as the first line of store().
- Confidence: High
- Systemic? : D30-adjacent (defense-in-depth gap).
```

```
[SEC-CMP-017] Severity: P1 | DocumentRequestController::update() changes state with no authorization (NEW)
- Location: Modules/Complaint/app/Http/Controllers/DocumentRequestController.php:69
- Evidence:
    public function update(Request $request, ParentDocumentRequest $documentRequest)
    {   $request->validate([...]);          // validates input but NO Gate::authorize / policy
        $documentRequest->update([ 'status' => $request->status, ... ]);
- Why it's a risk: a state-changing update on a cross-module ParentPortal model (document-request status,
    fee, admin notes, file) with zero authz. Any authenticated tenant user reaching the route can mutate
    parent document requests.
- Fix: add a Gate/policy check (e.g. Gate::authorize('tenant.complaint.manage') or the ParentPortal
    document policy) before update; input validation is present and adequate.
- Confidence: High
- Systemic? : Layer 5.1.
```

```
[SEC-CMP-015] Severity: P1 (re-confirmed open) | Private notes not filtered by role at query layer
- Location: ComplaintController.php:969 (buildComplaintActionsQuery) ; 953 (getComplaintActionsData)
- Evidence:
    return ComplaintAction::with([...])
        ->when(... search/action_type/performed_by/assigned_to ...)
        ->latest();           // no ->where('is_private_note', 0) and no role check
- Why it's a risk: BR-CMP-015 limits private notes to Admin/Principal. The timeline query returns every
    action including is_private_note=1 rows to any role that can view the list.
- Fix: when the actor is not Admin/Principal, add ->where('is_private_note', 0) to the query (enforce at
    data layer, not the view).
- Confidence: High
- Systemic? : module-local (Layer 5/6 data exposure).
```

```
[BUG-CMP-024] Severity: P1 (re-confirmed open) | Creation notification sent to wrong role via app-level class
- Location: ComplaintController.php:384-385
- Evidence:
    $admins = User::role('Super Admin')->get();
    Notification::send($admins, new StudentPortalComplaintRegistered($complaint));
- Why it's a risk: BR/FRD require notifying the School Admin; "Super Admin" is the platform role, and the
    notification class is App\Notifications\… not a module-level class. On a tenant with no Super Admin the
    notification silently reaches nobody.
- Fix: target the School Admin role (per tenant) and move the notification into the module namespace.
- Confidence: High
- Systemic? : module-local.
```

```
[VAL-CMP-005] Severity: P1 (re-confirmed open) | No status-transition guard (FSM)
- Location: ComplaintController.php:582 (validate) + 656 (update)
- Evidence:
    'status_id' => 'nullable|integer',     // any id accepted
    ... $complaint->update($validated);     // any status -> any status, incl. backward
- Why it's a risk: BR-CMP-014 allows only Open->In-Progress->Resolved/Closed/Rejected (and Resolved->Reopened).
    Code permits Closed->Open, Rejected->Resolved, etc.
- Fix: validate the (old -> new) pair against an allowed-transition map; reject illegal transitions.
- Confidence: High
- Systemic? : module-local (Layer 8 workflow integrity).
```

```
[VAL-CMP-004] Severity: P1 (re-confirmed open) | Resolved with no resolution note / timestamp
- Location: ComplaintController.php:585-589, 714
- Evidence:
    'resolution_summary' => 'nullable|string',
    'actual_resolved_at' => 'nullable|date',
    ... if ($complaint->actual_resolved_at) { ...log Resolved... }   // not required when status=Resolved
- Why it's a risk: BR-CMP-012 requires both a resolution summary and actual_resolved_at before a complaint
    may be marked Resolved. Both are nullable and unguarded -> tickets close with empty resolution data.
- Fix: conditional rule — when the target status is Resolved, require resolution_summary + actual_resolved_at.
- Confidence: High
- Systemic? : module-local.
```

```
[PERF-CMP-009] Severity: P1 | Unbounded ::all() loading tenant user/complaint tables into dropdowns (NEW)
- Location: DepartmentSlaController.php:43,77 (User::all()); MedicalCheckController.php:58,124 (Complaint::all(), User::all())
- Evidence:
    'users' => User::all(),            // every tenant user, every form render
    'complaints' => Complaint::all(),  // every complaint ever, into a <select>
- Why it's a risk: User::all() and Complaint::all() grow without bound; on a populated tenant these forms
    load thousands of rows per request (memory + render). Complaint::all() in a dropdown is unbounded by design.
- Fix: replace with paginated/searchable AJAX selects, or constrain (active users, recent/open complaints).
- Confidence: High
- Systemic? : Layer 9.3 (echoes prior PERF-CMP for DepartmentSla; MedicalCheck Complaint::all() is new).
```

```
[JOB-CMP-001] Severity: P1 | Scheduled escalation job still absent; AI listener runs synchronously in request/transaction (NEW)
- Location: app/Jobs/ (directory does not exist) ; app/Listeners/ProcessComplaintAIInsights.php:8 (no implements ShouldQueue)
- Evidence:
    class ProcessComplaintAIInsights        // not ShouldQueue
    { public function handle(ComplaintSaved $event): void { $this->engine->processComplaint(...); } }
    // store() fires event(new ComplaintSaved($complaint)) at line 381 — INSIDE the open transaction
- Why it's a risk: (a) BUG-CMP-023: no CheckComplaintEscalations job/command exists, so current_escalation_level
    is never auto-advanced (REQ-CMP-013 inert). (b) AI scoring runs inline inside store()'s transaction,
    lengthening the lock window and adding latency to every save.
- Fix: implement the scheduled escalation command (wrapped for per-tenant run); make the AI listener
    implement ShouldQueue (with $tries/$backoff/$timeout) and re-init tenancy in handle().
- Confidence: High
- Systemic? : Layer 10 (tenancy/retry job norms).
```

### P2 Findings

```
[CQ-CMP] Severity: P1->P2 | ComplaintController is a 1368-line god controller
- Location: ComplaintController.php (1368 lines; index() + 6 private data-builders + dashboard donuts + table introspection helpers)
- Why it's a risk: >1000 lines = decompose (Layer 4.4). Mixes registration, timeline, dashboard, and generic
    table/column introspection (getTableData/getTableColumns) in one class.
- Fix: extract ComplaintRegistrationService, the dashboard donuts into the dashboard controller/service, and
    drop the generic table introspection helpers.
- Confidence: High
```

```
[SEC-CMP-016] Severity: P1->P2 (partially mitigated) | Anonymous masking is view-layer only, not role-aware
- Location: show.blade.php:76-91 (masks when is_anonymous) ; ComplaintController.php:442 (no query-layer masking)
- Evidence:
    @if($complaint->is_anonymous)  …masked…  @else {{ $complaint->complainant_name … }} @endif
- Why it's a risk: identity IS hidden in the primary show view, so the prior "exposed to everyone" finding is
    partially fixed. But masking is at the Blade layer only (the model still carries the data to the client and
    to any JSON/mobile path), and it is not role-aware (Admin/Principal cannot see the identity they are
    permitted to per BR-CMP-021).
- Fix: mask at the query/serialisation layer based on role; allow Admin/Principal to see identity.
- Confidence: Medium (mobile/API show paths not exhaustively checked).
```

```
[VAL-CMP-magic] Severity: P2 | Magic-number fallbacks for status/priority dropdown ids
- Location: ComplaintController.php:282 (?? 124), 288 (?? 3)
- Evidence:
    ->first()?->id ?? 124; // Fallback to 124 if not found for safety
- Why it's a risk: improved vs the prior hardcode (CT-05) — now only a fallback after a real lookup — but a
    misconfigured/absent 'Open' dropdown silently writes id 124, which may be wrong on another tenant.
- Fix: throw a clear configuration error instead of falling back to a literal id.
- Confidence: High
```

```
[DEAD-CMP-007] Severity: P2 | D30 — both FormRequests authorize() return true
- Location: ComplaintCategoryRequest.php, DepartmentSlaRequest.php
- Why it's a risk: platform-systemic D30; these two requests perform no authorization. The core complaint
    store/update use inline $request->validate() with no FormRequest at all (FR-01 carryover).
- Fix: return Gate::allows('tenant.complaint-category.*') etc.; add Store/UpdateComplaintRequest classes.
- Confidence: High
```

### P3 Findings
- Commented `// dd($request->all());` at MedicalCheckController.php:71,75 — remove.
- Commented-out dead `logAction`/status blocks in ComplaintController (683-689, 315-322) — remove.

---

### Layer Health Summary

| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema | 🟡 Amber | Prior SCH-CMP-001..007 open; not re-deep-audited this pass |
| 2 Migration↔Model↔DDL | 🔴 Red | **BUG-CMP-020 / ORM-CMP-001** — created_at vs action_timestamp |
| 3 Model & ORM | 🔴 Red | ComplaintAction missing `$timestamps=false`/CREATED_AT |
| 4 Code Quality | 🟡 Amber | 1368-line god controller; commented debug |
| 5 Authorization | 🔴 Red | store() ungated (SEC-CMP-007); DocumentRequest update ungated (SEC-CMP-017) |
| 6 Multi-Tenancy | 🟢 Green | RSP tenancy stack present; no initialize() leaks; no hardcoded tenant ids |
| 7 Validation/Mass-assign | 🟡 Amber | inline validate present; 2 FormRequests authorize()=true; no mass-assign hole (uses validated()) |
| 8 Data Integrity/Tx | 🔴 Red | tx + lockForUpdate good, but FSM (VAL-005), resolution gate (VAL-004), and logAction failure break integrity |
| 9 Performance | 🟡 Amber | User::all()/Complaint::all() dropdowns; sync AI listener |
| 10 Queue/Job | 🔴 Red | no escalation job; AI listener not queued (in-transaction) |
| 11 Frontend/Output | 🔴 Red | **FE-CMP-001** stored XSS on description |
| 12 Deployment | 🟢 Green | no module route closures / env() / secrets; platform-level SEC-RTG-001 etc. out of module scope |

### What is FIXED since 2026-06-27 (good news)
- `dd($e)` blockers (CT-03/CT-04) — gone; only commented `// dd()` remains.
- Hardcoded `status_id=124` / `action_type_id=197/202` (CT-05/06/07) — replaced by real dropdown lookups (124/3 remain only as `??` fallbacks → downgraded to P2).
- `destroy()` — implemented (soft delete with gate), no longer empty.
- Ticket-number generation (BR-CMP-007) — `lockForUpdate()` + collision loop present and correct.
- Tenancy stack on the module RSP — present (no D23).
- Permission prefixes — uniformly `tenant.` (no D24 typos in this module).

### vs Platform Baseline
- FormRequests returning bare `true`: 2/2 here — consistent with the 90% platform norm (D30).
- `$request->all()` into models: **0 live mass-assignment sinks** (the one hit is a safe `paginate()->appends()`) — better than the GlobalMaster/Library/Syllabus offenders.
- Jobs without tenancy/retry: the module ships **0 jobs** (escalation job missing) — below the expected baseline for a module with a scheduled-escalation requirement.
- god controller 1368 lines — mid-pack (well under StudentController 4222 / LmsExam 3767).

### Recommended Fix Order
1. **BUG-CMP-020 + ORM-CMP-001** (P0) — fix `logAction` column + `ComplaintAction` `$timestamps`/ordering. Unblocks complaint creation and the entire timeline. *(One small change set; highest leverage.)*
2. **BUG-CMP-019** (P0) — compute & persist `resolution_due_at` in store(); revives SLA/escalation/dashboard.
3. **FE-CMP-001** (P1) — escape the description in show/edit blades (stored XSS).
4. **SEC-CMP-007 + SEC-CMP-017** (P1) — add the missing authorization gates.
5. **SEC-CMP-015 + VAL-CMP-004 + VAL-CMP-005** (P1) — private-note query filter, resolution gate, status FSM.
6. **JOB-CMP-001 / BUG-CMP-024 / PERF-CMP-009** (P1) — escalation job + queue the AI listener; fix notification role; bound the dropdown queries.
7. P2/P3 — decompose the controller, replace magic-id fallbacks, FormRequest authorize(), remove dead/commented code.

---
*Read-only audit. No application code was modified. Handoffs: P0/P1 fixes → Developer; schema/DDL reconciliation (SCH-CMP-*) → DB Architect; completeness re-score → Status_Analyzer; test coverage → Testing Architect.*

---

## STEP 1 Reading-Discipline Output (D-pattern) — added 2026-06-29

### Three-Way Schema Reconciliation (DDL ↔ migration ↔ model)
| Subject | DDL spec | Live migration | Eloquent model | Code | Verdict |
|---------|----------|----------------|----------------|------|---------|
| `cmp_complaint_actions` time column | `action_timestamp` only | `timestamp('action_timestamp')->useCurrent()`, **no `created_at`** | `ComplaintAction` has **no** `$timestamps=false` / `CREATED_AT` override | `logAction()` inserts `'created_at'`; `buildComplaintActionsQuery()->latest()` orders by `created_at` | **All three disagree → BUG-CMP-020 (P0) + ORM-CMP-001 (P0).** Reading any one alone would have mis-rated this as P2 "ordering"; only the 3-way read showed it hard-fails `store()`. |
| `cmp_complaints.resolution_due_at` | present | present (nullable) | fillable | `store()` never writes it | Column exists, **code gap not schema gap** → BUG-CMP-019 (correctly a logic defect, not a migration defect). |

### Module-Knowledge Snapshot Corrections (hints vs live code)
Knowledge file dated 2026-06-27; live tree on 2026-06-29 differs:
- "destroy() is empty" → **now implemented** (gated soft-delete).
- "CT-03/CT-04 `dd($e)` blockers" → **removed**; only commented `// dd()` remains.
- "CT-05/06/07 hardcoded `124/197/202`" → **replaced by dropdown lookups**; `124/3` survive only as `??` fallbacks (downgraded P2).
- Module has grown since the snapshot: `ComplaintController` now 1368 lines; new `DocumentRequestController`, `Mobile/ComplaintMobileController`, and `Events/ComplaintSaved` + `Listeners/ProcessComplaintAIInsights`.
