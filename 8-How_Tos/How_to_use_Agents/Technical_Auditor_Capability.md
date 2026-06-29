# Technical Auditor — Capability Document
===========================================
> Agent definition: `AI_Brain/agents/technical-auditor.md` (Enhanced — Maximum-Detail Edition)
> Last updated: 2026-06-27
> Read alongside: `Business_Analysts_Capability.md`, `How_to_use_Technical-Auditor_Agent.md`, `0-How_to_use_Agents.md`

This document lists **everything the Technical Auditor (TA) agent can find** and **exactly what to say**
to get each. The TA is **read-only** — it produces findings, issue codes, evidence, severity,
confidence, and fix recommendations. It does NOT rewrite code or redesign schema (that's Developer /
DB Architect). It is the defect-finding counterpart to the Business Analyst (who defines requirements)   
and the Status_Analyzer (who scores completeness).

The guiding idea of this edition: **maximum auditing detail.** The TA performs a **12-layer** deep
audit, plus FRD-driven gap analysis, business-rule enforcement, a platform-wide systemic sweep, and a
pre-deployment gate. Every finding is evidence-backed (`file:line` + snippet), severity-rated
(P0/P1/P2/P3), and confidence-tagged.

---

## 1. Activate the agent
------------------------

Open a Claude Code session and type:
```
act as Technical Auditor
```
Claude reads `AI_Brain/agents/technical-auditor.md`, loads context (paths, conventions, decisions
D17/D22–D35, known-issues + the Platform-Wide Systemic Patterns section, progress, modules-map,
deployment-config, and the module's knowledge/FRD if any), and replies:
```
Active role: Technical Auditor. Ready.
Which audit mode? (A) 12-layer deep  (B) FRD gap  (C) BR enforcement  (D) Platform sweep
                  (E) Combined  (F) Specific layer(s)  (G) Pre-deployment gate
```

> The TA is **session-scoped** — no memory between sessions. It stays accurate by reloading
> known-issues.md, decisions.md, modules-map.md, deployment-config.md, and the per-module knowledge
> file every session. Those files ARE its memory — keep them updated.

---

## 2. What the TA can do — capability surface at a glance
---------------------------------------------------------

```
THE 12 AUDIT LAYERS (Mode A)
   1. DDL Schema Integrity          (conventions, indexes, ENUM/D29, FK constraints)
   2. Migration ↔ Model ↔ DDL       (3-way consistency, fillable-vs-columns/D17, cross-DB FK)
   3. Model & ORM Correctness       (casts, relationships, duplicate models, $guarded)
   4. Code Quality & Dead Code      (dd()/debug, stubs, God controllers, backup files)
   5. Authorization & Access        (missing Gates, commented gates, policy coverage, prefix/D24)
   6. Multi-Tenancy Isolation  ⭐    (RSP tenancy/D23, initialize-without-end, cache prefixing)
   7. Input Validation & Mass-Assign(D25 $request->all(), D30 authorize()=true, privilege fields)
   8. Data Integrity / Tx / Locking (transactions, lockForUpdate, generated columns, disabled posting)
   9. Performance & Query Efficiency(N+1, unbounded ::all(), Schema:: in hot paths, eager ratio)
  10. Queue / Job / Scheduler       (tenancy re-init, tries/backoff/timeout, tenants:run)
  11. Frontend / Blade / Output     (XSS {!!..!!}, client-exposed secrets, CSRF)
  12. Deployment & Operational      (secrets, queue↔Horizon, committed .env, route/config cache)

THE AUDIT MODES
   A. Standard 12-layer deep audit (one module)
   B. FRD-driven gap analysis      (REQ → DDL/code/test, needs an FRD)
   C. Business-rule enforcement    (each BR enforced in code? needs an FRD)
   D. Platform systemic sweep      (cross-module hunt: D23/24/25/29/30 + more)
   E. Combined                     (A + B + C for one module, unified report)
   F. Specific layer(s)            (e.g. "Tenancy + Deployment only")
   G. Pre-deployment gate          (Layers 6, 8, 10, 12 + secrets + cache safety)

ALSO PRODUCES
   - Severity-rated, confidence-tagged findings with file:line evidence
   - Weighted Health Score (0–100) with hard P0 cap at 40
   - Issue codes (SEC-/BUG-/TEN-/PERF-/DAT-/JOB-/FE-/MIG-/ORM-/VAL-/DEPLOY-…)
   - Updates to known-issues.md, progress.md, decisions.md, module-knowledge
```

---

## 3. How to use EACH capability — say-this guide
-------------------------------------------------

> Pattern: `act as Technical Auditor` → then the request. Name the module by plain name (e.g.
> "Hostel"); the TA resolves code/prefix itself. Specify an output folder or it saves to
> `3-Audit_Reports/` and tells you the path.

### The Audit Modes

**Mode A — Standard 12-layer deep audit** (one module, everything)
```
act as Technical Auditor
Audit the Hostel module. All 12 layers. Save the report under 3-Audit_Reports/.
```
Produces: per-layer findings, a 12-row Green/Amber/Red Layer Health Summary, P0–P3 finding blocks,
a weighted Health Score, "vs Platform Baseline" comparison, and a recommended fix order. *Use when:*
you want the complete defect picture for a module.

**Mode B — FRD-driven gap analysis** (needs an FRD to exist)
```
act as Technical Auditor
Run an FRD gap analysis for Hostel (Mode B) — which REQ have DDL, code, and tests?
```
*Use when:* the BA has produced an FRD and you want each requirement traced to implementation.

**Mode C — Business-rule enforcement** (needs an FRD)
```
act as Technical Auditor
Mode C for Hostel — verify each BR- from the FRD is actually enforced in code.
```

**Mode D — Platform systemic sweep** (cross-module, all modules)
```
act as Technical Auditor
Run a platform systemic sweep — find D25 ($request->all()), D30 (authorize()=true),
D24 (permission-prefix typos), D29 (enum migrations), and cross-DB FK issues across all modules.
```
Produces a module × pattern heat-map with counts vs the platform baseline. *Use when:* you want to
hunt one class of defect everywhere, not audit one module.

**Mode E — Combined** (A + B + C, unified)
```
act as Technical Auditor
Combined audit for Hostel: 12-layer + FRD gap + BR enforcement, one report.
```

**Mode F — Specific layer(s) only**
```
act as Technical Auditor
Audit Hostel — Layer 6 (Tenancy) and Layer 8 (Data Integrity) only.
```

**Mode G — Pre-deployment gate** (release readiness)
```
act as Technical Auditor
Run the pre-deployment gate on the platform (Layers 6, 8, 10, 12 + secrets + cache safety).
```

### The 12 Layers (run individually via Mode F)

**Layer 1 — DDL Schema Integrity**
```
act as Technical Auditor
Layer 1 only for Hostel — DDL conventions, indexes, ENUM/D29, FK constraints.
```

**Layer 2 — Migration ↔ Model ↔ DDL Consistency**
```
act as Technical Auditor
Layer 2 for Hostel — 3-way reconcile migrations, models, DDL; find fillable-vs-column mismatches and cross-DB FKs.
```

**Layer 3 — Model & ORM Correctness**
```
act as Technical Auditor
Layer 3 for Hostel — casts, relationships, duplicate models, $guarded misuse.
```

**Layer 4 — Code Quality & Dead Code**
```
act as Technical Auditor
Layer 4 for Hostel — dd()/debug statements, stubs, God controllers, backup files.
```

**Layer 5 — Authorization & Access Control**
```
act as Technical Auditor
Layer 5 for Hostel — write methods with no Gate, commented gates, policy coverage, permission-prefix typos.
```

**Layer 6 — Multi-Tenancy Isolation** ⭐ (highest-risk class)
```
act as Technical Auditor
Layer 6 for Hostel — RSP tenancy middleware, initialize() without end(), cache prefixing, hardcoded tenant IDs.
```

**Layer 7 — Input Validation & Mass Assignment**
```
act as Technical Auditor
Layer 7 for Hostel — $request->all() (D25), authorize() returning true (D30), privilege fields in $fillable.
```

**Layer 8 — Data Integrity, Transactions & Concurrency**
```
act as Technical Auditor
Layer 8 for Hostel — missing transactions, missing lockForUpdate on balance/stock, generated-column writes, disabled posting.
```

**Layer 9 — Performance & Query Efficiency**
```
act as Technical Auditor
Layer 9 for Hostel — N+1, unbounded ::all(), Schema:: in hot paths, eager-load ratio.
```

**Layer 10 — Queue, Job & Scheduler Correctness**
```
act as Technical Auditor
Layer 10 for Hostel — jobs without tenancy re-init, missing tries/backoff/timeout, scheduler tenants:run.
```

**Layer 11 — Frontend / Blade / Output Safety**
```
act as Technical Auditor
Layer 11 for Hostel — {!! !!} XSS, client-exposed secrets in views, CSRF on forms.
```

**Layer 12 — Deployment & Operational Readiness**
```
act as Technical Auditor
Layer 12 — hardcoded secrets, queue↔Horizon mismatch, committed .env, route/config cache safety, unauth seeder routes.
```

---

## 4. Combos & targeted hunts — "whatever I need checked"
--------------------------------------------------------

```
act as Technical Auditor
Security pass only across ParentPortal, Hostel, Dashboard — Layers 5, 6, 7.
```
```
act as Technical Auditor
Hunt every place a financial/stock write lacks a row lock (Layer 8) across StudentFee, Inventory, Payment, Hostel.
```
```
act as Technical Auditor
Re-check SEC-RTG-001 — are the seeder routes still outside the auth group in routes/tenant.php?
```
```
act as Technical Auditor
Is BUG-HPC-016 still present? Confirm from the file and report current state.
```

---

## 5. Severity, evidence & confidence (what every finding contains)
------------------------------------------------------------------

Every finding is a structured block:
```
[CODE] Severity: P0 | Title
- Location: path/File.php:LINE (+ other sites)
- Evidence: <verbatim snippet>
- Why it's a risk: <concrete impact>
- Fix: <specific remediation>
- Confidence: High | Medium | Low
- Systemic?: <D-pattern link or "module-local">
```

**Severity rubric:**
```
P0 Blocker   — exploitable hole, data corruption/loss, cross-tenant leak, or "can't deploy/run"
P1 Critical  — real production defect, not an immediate breach/outage
P2 Major     — quality / maintainability / latent risk
P3 Minor     — hygiene / style
```
**Health Score:** weighted across the 12 layers (tenancy/security/data-integrity weighted highest);
**any P0 caps the module at 40/100** regardless of the weighted sum.

---

## 6. Issue code convention
---------------------------

```
Schema           SCH-DDL-NNN        Bug            BUG-XXX-NNN
Migration↔Model  MIG-XXX-NNN        Model/ORM      ORM-XXX-NNN
Security         SEC-XXX-NNN        Tenancy        TEN-XXX-NNN
Validation       VAL-XXX-NNN        Data Integrity DAT-XXX-NNN
Performance      PERF-XXX-NNN       Queue/Job      JOB-XXX-NNN
Frontend/XSS     FE-XXX-NNN         Dead Code      DEAD-XXX-NNN
Deployment       DEPLOY-YYY-NN
```
`XXX` = module code/prefix; `YYY` = subsystem (ENV/HRZ/MIG/LOG/STO/RTG).
**Rule:** the TA greps `known-issues.md` for the max existing number per prefix BEFORE assigning — never
reuses a code.

---

## 7. Execution Commands (copy/paste with your values)
------------------------------------------------------

```
AUDIT_MODULE = Hostel
OUTPUT_PATH  = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/3-Audit_Reports/V1_27Jun2026
OUTPUT_FOLDER = {OUTPUT_PATH}/{AUDIT_MODULE}
act as Technical Auditor
Audit the {AUDIT_MODULE} module. All 12 layers. Save output into folder {OUTPUT_FOLDER}.
Update known-issues.md and progress.md.
```
```
act as Technical Auditor
Pre-deployment gate (Mode G) on the full platform. Save under 3-Audit_Reports/Deploy_Gate_27Jun2026.
```

---

## 8. Typical session flow
--------------------------

```
You:    act as Technical Auditor
Claude: Active role: Technical Auditor. Ready. Which mode?

You:    Audit the Hostel module. All 12 layers. Save under 3-Audit_Reports/.
Claude: Module identified: Hostel | Code: HST | Prefix: hst_
        [runs detectors, opens files to confirm, applies false-positive guardrails]
        Health: 38/100 (CAPPED — P0 present).
        P0: TEN-HST-001 SendHst*Job missing tenancy re-init (Layer 10);
            DAT-HST-001 occupancy update without row lock (Layer 8).
        P1: ORM-HST-001 BedType.php + HstBedType.php duplicate model;
            PERF-HST-002 Schema::hasTable() feature-flags in services.
        New codes appended to known-issues.md. progress.md updated.
        Layer Health: Tenancy=Red, Data Integrity=Amber, Authz=Green …
        Recommended fix order: 1) job tenancy, 2) occupancy lock, 3) dedupe model.

You:    Now run Mode C — are the Hostel BRs enforced?
Claude: [needs the FRD] No FRD found for HST. Generate one first → act as Business Analyst.
```

---

## 9. Quick Reference Card
-------------------------

```
┌──────────────────────────────────────────┬──────────────────────────────────────────────────────────────┐
│                  Goal                       │                          Say This                            │
├──────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ Full 12-layer module audit                  │ act as Technical Auditor → Audit [Module]. All 12 layers.   │
│ Security pass                               │ act as Technical Auditor → Layers 5,6,7 for [Module]        │
│ Tenancy-leak hunt                           │ act as Technical Auditor → Layer 6 for [Module]             │
│ Data-integrity / locking                    │ act as Technical Auditor → Layer 8 for [Module]             │
│ Performance / N+1                           │ act as Technical Auditor → Layer 9 for [Module]             │
│ Queue/job correctness                       │ act as Technical Auditor → Layer 10 for [Module]            │
│ Schema/migration/model consistency          │ act as Technical Auditor → Layers 1,2,3 for [Module]        │
│ FRD requirement gap                         │ act as Technical Auditor → Mode B for [Module]              │
│ Business-rule enforcement                   │ act as Technical Auditor → Mode C for [Module]              │
│ Platform-wide systemic hunt                 │ act as Technical Auditor → Mode D (D24/D25/D29/D30 + FKs)   │
│ Pre-release deploy check                    │ act as Technical Auditor → Mode G pre-deployment gate       │
│ Re-check one known issue                    │ act as Technical Auditor → Is [CODE] still present?         │
└──────────────────────────────────────────┴──────────────────────────────────────────────────────────────┘
```

---

## 10. What the TA produces & updates
-------------------------------------

```
Audit report      → 3-Audit_Reports/{Module}_Technical_Audit_{date}.md (or your folder)
known-issues.md   → AI_Brain/lessons/known-issues.md   (new findings appended, non-conflicting codes)
progress.md       → AI_Brain/state/progress.md         (completion % revised — P0 stubs reduce "done")
decisions.md      → AI_Brain/state/decisions.md        (new D{N} if a pattern-level decision emerges)
module knowledge  → AI_Brain/module-knowledge/{CODE}_{Module}.md (Known Gaps + Lessons + Version History)
```

Report structure: Executive Summary · Health Score (+cap) · P0/P1/P2/P3 finding blocks · 12-row Layer
Health Summary · FRD Gap (Mode B) · BR Enforcement (Mode C) · vs Platform Baseline · Recommended Fix Order.

---

## 11. Steering the agent — corrections
---------------------------------------

The TA self-applies guardrails (evidence-or-it-didn't-happen, confidence rating, no false-positive
flooding, severity = impact × exploitability). If output drifts, correct precisely:

```
┌────────────────────────────────────────────┬──────────────────────────────────────────────────────────┐
│               Problem you see                │                       Say this                            │
├────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
│ Vague finding, no line number                │ Add file:line + a verbatim snippet for every finding.     │
│ Finding not confirmed from the file          │ Open the file and confirm; grep alone is a candidate.     │
│ Duplicate issue code used                     │ Grep known-issues.md for the max code per prefix; renumber.│
│ Wrong P0/P1/P2 severity                       │ Re-rate by impact × exploitability per the rubric.        │
│ Flagged an empty scaffold as an auth hole     │ Check the method body — empty {} is a stub, not a finding.│
│ Flagged a central module for missing tenancy  │ Prime/Billing/Documentation are central — not findings.   │
│ Flagged $tenant->run() as a leak              │ run() auto-reverts; only bare initialize() w/o end() leaks.│
│ Skipped a layer                               │ Run all 12 layers; list each with Green/Amber/Red.        │
│ Stopped after 2–3 findings                    │ Continue — exhaust every layer's detectors.               │
│ known-issues.md / progress.md not updated     │ Append findings and revise completion % before finishing. │
│ Re-reported a fixed issue                     │ Re-read the file; confirm current state before reporting. │
│ Prose instead of finding blocks/tables        │ Use the structured finding block + Layer Health table.    │
└────────────────────────────────────────────┴──────────────────────────────────────────────────────────┘
```

---

## 12. The intelligence the TA brings (so you don't have to specify it)
----------------------------------------------------------------------

Every audit runs on top of platform intelligence — you get these for free:
- **Real detectors** validated against the live tree (copy-paste bash per layer) + illustrative true-positive hits.
- **Platform Baseline** norms: 437/485 FormRequests return `true` (D30), ~476 enum migrations (D29),
  428 INT-PK tables, 52 cross-DB FKs to `sys_dropdowns`, 17 FKs to non-existent `sys_roles`, worst
  eager-load ratio Hpc 0.04 — so a module is judged against the norm, not in a vacuum.
- **Systemic-pattern awareness** (D17/D22–D30) with current state (D22 resolved; D23 Scheduler/EventEngine fixed).
- **Architecture facts:** migrations are centralized (not per-module); routes/policies are module-owned
  (post-D22); module policies live in `Modules/{Mod}/app/Policies/` (0 hits in central is expected).
- **False-positive guardrails** for the traps that waste time (empty scaffolds, central modules,
  `$tenant->run()`, json_encode charts, test fixtures, the `dd()` grep trap, shared prefixes).
- **Confirmed deploy blockers:** queue=database vs Horizon=redis, committed `APP_KEY` in `.env-original`,
  live SEC-RTG-001 seeder routes, route closures breaking `route:cache`.

---

## 13. Related files
--------------------

```
AI_Brain/agents/technical-auditor.md                 ← the agent definition (capability source)
AI_Brain/lessons/known-issues.md                     ← issue log + Platform-Wide Systemic Patterns section
AI_Brain/state/decisions.md                          ← D17/D22–D35 (the systemic patterns the TA hunts)
AI_Brain/memory/deployment-config.md                 ← Layer 12 baseline + confirmed deploy blockers
AI_Brain/memory/{conventions,modules-map}.md         ← prefixes, module inventory (loaded each session)
AI_Brain/module-knowledge/{CODE}_{Module}.md         ← per-module persistent memory
8-How_Tos/How_to_use_Agents/Business_Analysts_Capability.md ← the upstream BA (produces the FRD)
8-How_Tos/How_to_use_Agents/Technical_Auditor_Enhancement_Prompts.md ← prompt blocks + correction templates
```

> Hand-off chain: **Business Analyst** (FRD) → **Technical Auditor** (Modes B/C use that FRD) →
> **Status_Analyzer** (6-dimension score) / **Testing Architect** (test coverage) / **Developer** (fixes)
> / **DB Architect** (schema fixes). The TA is session-scoped; known-issues.md + module-knowledge files
> are its memory — keep them current and it stays accurate.
