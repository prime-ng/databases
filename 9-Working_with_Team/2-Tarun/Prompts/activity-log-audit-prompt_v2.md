# Activity Log Audit — Claude AI Prompt (V2)

> **Version:** 2.0 · **Adapted for:** Bharadwaj's local machine (macOS / Laravel Herd)
> **Supersedes:** `activity-log-audit-prompt.md` (V1)
> **What changed in V2:**
> 1. Real, verified paths for this machine + ground-truth facts about the `activityLog()` helper (signature, target model, table, DB layer).
> 2. **Every output is a report written into one folder** (§0.2) — nothing is written anywhere else.
> 3. **Strict read-only mandate** (§0.1) — no code, DDL, migration, config, or any file outside the output folder is touched.
> 4. Audit deepened from "is the call present?" to **presence + correctness + risk**: right event name, right subject, meaningful `properties`, before/after diff on updates, transaction placement, tenant-context correctness, PII exposure, silent null-subject skips, and coverage of **non-controller mutation surfaces** (observers, jobs, services, actions, bulk ops).
> 5. Severity/risk classification + a prioritized, recommendation-only remediation plan.

---

## ⛔ 0.1 ABSOLUTE READ-ONLY MANDATE (Highest Priority)

**This task ONLY produces reports. It must not change anything, anywhere.**

**STRICTLY FORBIDDEN:**
- Editing, creating, deleting, moving, or renaming **any file** in the application repo `/Users/bkwork/Herd/prime_ai` (or anywhere else) **except** inside the single output folder in §0.2.
- Modifying **any code** (PHP, Blade, JS, config, `.env`, composer files, etc.) — including "just adding the missing `activityLog()` call." **You only document it as a recommendation.**
- Touching the **database in any way** — no DDL, migrations, seeders, `ALTER/CREATE/DROP/INSERT/UPDATE/DELETE`, no `php artisan migrate`. Any DB access is **read-only inspection only**.
- Running any **state-mutating command** (`composer`, `artisan` mutating commands, `npm`, `git commit/push`, formatters, auto-fixers).

**ALLOWED:**
- **Read** any file in `/Users/bkwork/Herd/prime_ai` (read-only inspection).
- Run **read-only** shell (`ls`, `cat`, `grep`, `rg`, `find`, `git status`/`git log` — never mutating git).
- **Create new report files ONLY** inside the output folder (§0.2).

**If any instruction would require modifying anything outside the output folder, STOP and ask.** Every finding is a documented recommendation — never an applied change.

---

## 0.2 Output Contract

Write **all** reports into:

```
/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/9-Working_with_Team/2-Tarun/Prompt_Output/Activity_Log_Audit/
├── 00_ACTIVITY_LOG_AUDIT_SUMMARY.md    # Executive summary: totals, compliance %, top risks (write LAST)
├── 01_COVERAGE_BY_MODULE.md            # Per-module coverage tables (the core matrix)
├── 02_MISSING_CALLS.md                 # Every missing call: full path · controller · method · risk
├── 03_CORRECTNESS_FINDINGS.md          # Calls that exist but are wrong/weak (event/subject/properties/txn)
├── 04_SENSITIVE_OPERATIONS.md          # High-risk mutations (auth, fees, marks, roles, deletes) ranked
├── 05_NON_CONTROLLER_SURFACES.md       # Mutations in observers/jobs/services/actions/commands
└── 06_REMEDIATION_PLAN.md              # Prioritized, recommendation-only fix plan
```

Create the folder if missing. Confirm it is writable before starting.

---

## 0.3 Ground Truth (verified on this machine — do not re-derive, but DO confirm before quoting)

- **App root:** `/Users/bkwork/Herd/prime_ai`
- **Helper file:** `app/Helpers/activityLog.php`
- **Signature:** `activityLog($subject, string $event, array $properties = [])`
- **Writes to model:** `Modules\GlobalMaster\Models\ActivityLog` → table **`sys_activity_logs`**
- **Columns captured:** `subject_type`, `subject_id`, `user_id` (`Auth::id()`), `event`, `properties` (JSON), `ip_address`, `user_agent`.
- **⚠️ Silent-skip behavior:** if `$subject === null` the helper **returns null and logs nothing** — a call that receives a null model is a *silent* compliance gap, not an error. Flag these.
- **DB layer nuance:** `sys_*` = **prime_db** (per project convention), yet the app is **multi-tenant** and a separate tenant `activity_logs` migration also exists (`database/migrations/tenant/2026_06_16_071024_create_activity_logs_table.php`). Auditing **which layer tenant-data mutations are logged to** is in scope (§3.6).
- **Baseline counts (approximate — recompute live):** ~**730** controllers across **45** modules; ~**362** controllers contain ≥1 `activityLog()` call; ~**368** contain zero; ~**387** total usages across the codebase (so ~25 non-controller usages); **4** observer files exist.

> Confirm these with quick read-only commands before relying on them (e.g. `grep -rl "activityLog(" Modules --include="*Controller.php" | wc -l`). If reality differs, trust the codebase and note the discrepancy in the summary.

---

## 1. Task

Audit **every mutation surface** in the Prime AI application and determine whether `activityLog()` is called **correctly** for each data mutation. Every operation that creates, updates, deletes, restores, toggles, or bulk-mutates data **must** produce a correct, meaningful activity-log entry.

V1 asked only "is the call present in each controller method?" **V2 also asks: is it the *right* call?** (correct event, correct subject, meaningful properties, placed so it actually runs).

---

## 2. Scan Scope

### 2.1 Controllers (primary surface)
All files matching:
```
/Users/bkwork/Herd/prime_ai/Modules/*/app/Http/Controllers/**/*Controller.php
```
(~730 files, 45 modules. Note the **`app/`** segment in the path.)

### 2.2 Mutating methods to check per controller

| Method | Needs `activityLog()`? | Typical event |
|--------|:---:|-------|
| `store()` | Yes | `'Stored'` |
| `update()` | Yes (with before/after diff) | `'Updated'` |
| `destroy()` / `delete()` | Yes | `'Trashed'` |
| `restore()` | Yes | `'Restored'` |
| `forceDelete()` | Yes | `'Deleted'` |
| `toggleStatus()` | Yes | `'Toggled'` / `'StatusUpdated'` |
| `bulkDelete()` / `bulkUpdate()` / `bulkRestore()` | Yes | `'BulkDeleted'`, etc. |
| `import()` | Yes | `'Imported'` |
| Custom mutating methods (`approve*`, `reject*`, `markAsPaid`, `assign*`, `cancel*`, `publish*`, `lock*`, `release*`, `generate*`, `verify*`, `promote*`, etc.) | Yes — if it writes data | Context-appropriate |

**`export()`** — audit judgment: exports don't mutate domain data but may be worth logging for data-access compliance (mark as **advisory**, not a hard failure).

### 2.3 Read-only methods to IGNORE
`index()`, `create()`, `edit()`, `show()`, and any other listing/form-display/read method.

### 2.4 Non-controller mutation surfaces (V2 addition — report in `05_NON_CONTROLLER_SURFACES.md`)
Data is also mutated outside controllers. Scan and report coverage for:
- **Model Observers** (`Modules/*/app/Observers/*`, `booted()` model events) — do they log, or is logging bypassed when models are saved here?
- **Jobs / Queued work** (`Modules/*/app/Jobs/*`) — bulk/async mutations.
- **Services / Actions / Repositories** (`Modules/*/app/Services|Actions|Repositories/*`) — business logic that persists data.
- **Console Commands** (`Modules/*/app/Console/*`, cron) — scheduled mutations (e.g. auto status changes).
- **API controllers / mobile endpoints** — same mutating-method rules apply; note if they use a different logging path.
- **Direct `DB::table()->update/insert/delete`** and Eloquent mass ops (`Model::where()->update()`, `->delete()`) that bypass model events entirely.

Flag any mutation surface that changes data **without** a corresponding `activityLog()` (or equivalent) — these are the gaps `index/store` scanning alone misses.

---

## 3. Audit Dimensions (V2 — presence + correctness + risk)

For each mutating method, record not just ✅/❌ presence, but also these correctness checks (report issues in `03_CORRECTNESS_FINDINGS.md`):

### 3.1 Presence
Is `activityLog()` called on every code path that mutates data (including early-return branches, `try/catch`, and conditional updates)?

### 3.2 Correct subject
Is the **first argument the actual mutated model** (not a request, array, id, or null)? A call like `activityLog($request, ...)` or one that can receive `null` (→ silent skip) is a **correctness failure** even though the token `activityLog(` is present.

### 3.3 Correct event name
Does the event string match the operation and the conventional vocabulary (`Stored`/`Updated`/`Trashed`/`Restored`/`Deleted`/`Toggled`)? Flag mismatches (e.g. `'Updated'` used in a `destroy()`).

### 3.4 Meaningful properties
- `store`: has a human-readable `message`.
- `update`: captures **before/after `changes`** (the reference `CityController` pattern), not just a static message.
- All: does `properties` avoid dumping **raw PII / secrets** (passwords, tokens, full card/Aadhaar numbers)? Flag PII exposure as a **privacy finding**.

### 3.5 Placement & reliability
- Is the call **after** the persist succeeds (so it doesn't log failed writes)?
- Inside a **DB transaction**, is it placed so a rollback doesn't leave an orphan log (or a committed mutation without a log)?
- Is it reachable (not after a `return`, not in dead code)?

### 3.6 Tenant-context correctness (multi-tenant)
Tenant data mutations should be attributable within the correct tenant context. Note whether tenant-scoped operations log to the prime-layer `sys_activity_logs` vs. a tenant `activity_logs`, and whether that is intentional and isolated. (Report as an architectural observation, not a per-controller ❌.)

### 3.7 Base-controller inheritance
If a controller extends a base with shared CRUD: check the **child** first. Overridden mutating method → needs its own `activityLog()`. Inherited-without-override → note whether the base logs; if the base logs generically, mark child rows **Inherited ✅** with a note.

---

## 4. Reference: Correct Implementation (canonical)

**File:** `/Users/bkwork/Herd/prime_ai/Modules/GlobalMaster/app/Http/Controllers/CityController.php`
(`DistrictController.php` in the same module follows the identical pattern.)

```php
// store()
public function store(CityRequest $request)
{
    $city = City::create($request->all());
    activityLog($city, 'Stored', ['message' => 'A new city was created.']);
    return redirect()->to(...)->with('success', flash('created.city'));
}

// update() — logs before/after changes (THE pattern to expect on every update())
public function update(CityRequest $request, City $city)
{
    $original = $city->getOriginal();
    $city->update($request->all());
    $changes = $city->getChanges();
    $changedAttributes = [];
    foreach ($changes as $field => $newValue) {
        if ($field === 'updated_at') continue;
        $changedAttributes[$field] = ['old' => $original[$field] ?? null, 'new' => $newValue];
    }
    activityLog($city, 'Updated', [
        'message' => 'A city was updated.',
        'changes' => $changedAttributes,
        'performed_by' => Auth::user()->name,
    ]);
    return redirect()->to(...)->with('success', flash('updated.city'));
}

// destroy(): activityLog($city, 'Trashed', [...]);
// restore(): activityLog($city, 'Restored', [...]);
// forceDelete(): activityLog($city, 'Deleted', [...]);
// toggleStatus(): activityLog($city, 'Toggled', [...]);
```

**Helper contract (for reference):** `activityLog($subject, string $event, array $properties = [])` → creates a `Modules\GlobalMaster\Models\ActivityLog` (`sys_activity_logs`) capturing subject, `Auth::id()`, event, properties, IP, user-agent. **Returns `null` (logs nothing) if `$subject` is null.**

---

## 5. Output Format

### 5.1 `01_COVERAGE_BY_MODULE.md` — per module

#### Module: `<ModuleName>`

| Controller | store | update | destroy | restore | forceDelete | toggleStatus | Other mutating (name: state) | Notes |
|------------|:---:|:---:|:---:|:---:|:---:|:---:|------------------------------|-------|
| FooController | ✅ | ⚠️ | ❌ | ❌ | ❌ | ❌ | bulkDelete: ❌ | update ⚠️ = present but no before/after diff |
| BarController | ❌ | ❌ | ❌ | N/A | N/A | ❌ | markAsPaid: ❌ | high-risk (fees) |
| BazController | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | fully compliant |

**Legend:** ✅ correct & present · ⚠️ present but weak/incorrect (see `03_CORRECTNESS_FINDINGS.md`) · ❌ missing · N/A method absent · Inherited (from base, with note).

**Per-module summary:**
- Total controllers · Fully compliant · Partially compliant · Zero-coverage · Total missing calls · Total ⚠️ correctness issues · High-risk gaps.

### 5.2 `02_MISSING_CALLS.md`
A flat, sortable list — one row per missing call, with **full file path**, controller, method, and risk tier — so it can be worked through directly:
`Modules/StudentFee/app/Http/Controllers/InvoiceController.php · destroy() · MISSING · 🔴 High (financial)`

### 5.3 `00_ACTIVITY_LOG_AUDIT_SUMMARY.md` (write last)
- Confirmed live counts (controllers, with/without coverage, %).
- Compliance rate overall + a leaderboard of best/worst modules.
- Top 10 highest-risk gaps.
- Count of correctness (⚠️) issues by type (missing diff, wrong event, PII, null-subject, txn placement).
- Non-controller surface gaps.
- The 5 headline recommendations (pointer to `06_REMEDIATION_PLAN.md`).

---

## 6. Risk Classification (drives `04_SENSITIVE_OPERATIONS.md` and prioritization)

Rank every gap by blast radius, not just presence:

| Tier | Applies to | Examples |
|:----:|-----------|----------|
| 🔴 **Critical** | Money, grades, identity, access | Fees/invoices/payments, exam marks & results, marksheets, user/role/permission changes, admissions, deletes/forceDeletes of any of these |
| 🟠 **High** | Student-facing records & bulk ops | Attendance, behaviour, HPC, timetable, bulk delete/update/import, status toggles on the above |
| 🟡 **Medium** | Operational config | Master data, transport, hostel, library, notifications |
| ⚪ **Low** | Low-impact/rarely-changed | Cosmetic/config toggles, non-sensitive lookups |

A missing log on a fee deletion (🔴) outranks a missing log on a city update (🟡) even though both are one ❌.

---

## 7. Rules

1. **Do NOT modify any file** (see §0.1). Read-only audit; findings are recommendations only.
2. Presence of the token `activityLog(` is **necessary but not sufficient** — verify subject, event, properties, placement (§3).
3. Check **child controllers first**; note inherited-vs-overridden (§3.7).
4. Ignore `index/create/edit/show` and other read-only methods.
5. Flag **custom mutating methods** ("Other") and check them.
6. Flag **partial** controllers (some methods covered, some not).
7. Give the **full file path** for every gap.
8. Report **silent null-subject** calls and **PII in properties** as correctness/privacy findings, not passes.
9. Cover **non-controller mutation surfaces** (§2.4) in `05_NON_CONTROLLER_SURFACES.md`.
10. Prioritize by **risk tier** (§6), not just count.

---

## 8. Priority & Why It Matters

This is a multi-tenant K-12 school ERP/LMS/LXP handling **money (fees), academic records (marks, marksheets), and identity (students, staff, roles)**. Every data mutation must be traceable for compliance, debugging, dispute resolution, and security forensics. A missing or *incorrect* `activityLog()` on a financial or academic mutation is a **compliance and security gap** — and an entry that silently logs nothing (null subject) or leaks PII is arguably worse than an obvious absence.

---

## 9. Suggested Execution Order

1. Confirm ground-truth counts (§0.3) with read-only greps.
2. Sweep all controllers → build the `01_COVERAGE_BY_MODULE.md` matrix (presence).
3. Second pass on present calls → `03_CORRECTNESS_FINDINGS.md` (correctness).
4. Extract all ❌ → `02_MISSING_CALLS.md`; tag each with a risk tier.
5. Scan non-controller surfaces → `05_NON_CONTROLLER_SURFACES.md`.
6. Rank 🔴/🟠 gaps → `04_SENSITIVE_OPERATIONS.md`.
7. Write `06_REMEDIATION_PLAN.md` (phased, recommendation-only).
8. Write `00_ACTIVITY_LOG_AUDIT_SUMMARY.md` last, indexing all reports.

**Begin by confirming the counts, then build the coverage matrix. Everything is written under the output folder. Do not modify anything. Do not assume — if a pattern is ambiguous, note it and continue.**
