## Complete Audit — Transport (TPT) — 2026-06-29   (Mode X: A + B + C + G + scoped D)

> Supersets the Mode A report (`Transport_Technical_Audit_2026-06-29.md`) — full finding blocks and the
> STEP 1 reading-discipline output live there; this report reuses that evidence (same issue codes, counted
> once) and adds the FRD gap (B), business-rule enforcement (C), deploy gate (G), and scoped systemic (D)
> passes. Baseline FRD: `TPT_FRD_2026-06-29.md` (23 REQ, 26 BR).

### Executive Summary
Transport is large (30 controllers incl. a 1,984-line Mobile controller, 25 DDL tables, **0 services, 0 jobs, 0 events, 0 tests**). The deep scan found a live `dd($e)` (P0), unencrypted driver Aadhaar/licence (P0/legal), and a browser-shipped Maps key (P1). The FRD pass shows the UI/CRUD skeleton is broadly present but the **cross-cutting automation is not built** — compliance/licence gating, scheduled expiry alerts, parent notifications, boarding-scan validation, and vendor/accounting hand-offs are all missing. Business-rule enforcement is roughly **a third enforced, a third partial, a third missing**, with the safety- and money-critical rules (compliance gating, trip FSM, PII, module gate, boarding validation) on the missing side. **Health: 38/100 (P0 cap). Deploy: NO-GO.**

### Health Score
Weighted index ~46; **P0 cap → 40**; effective **38/100** (two P0 classes: live `dd` + PII-at-rest).

### Deploy Gate Verdict (Mode G): 🔴 **NO-GO**
| Blocker | Code | Why it blocks |
|---------|------|---------------|
| Live `dd($e)` in a write catch | BUG-TPT-011 | Stack-trace disclosure + broken bulk update (`TripController.php:587`) |
| Aadhaar/PAN/licence stored plaintext | SEC-TPT-005 | Aadhaar Act / DPDP violation — legal go-live blocker |
| Google Maps API key committed + browser-shipped | FE-TPT-001 | Key theft / billing fraud (3 views) — rotate before deploy |
| No module-subscription gate | TEN-RTG-001 | Any tenant can reach transport even if unlicensed |
| Clean: no route closures, no `env()` in module, no `initialize()` leak, RSP tenancy present | — | (these G checks pass) |

### Findings (Mode A evidence base — full blocks in the Mode A report; each coded once)
| Code | Sev | Title | Location |
|------|-----|-------|----------|
| BUG-TPT-011 | P0 | `dd($e)` in live bulk trip-update catch | `TripController.php:587` |
| SEC-TPT-005 | P0 | Driver Aadhaar/licence stored unencrypted (no `encrypted` cast) | `DriverHelper.php:31,36,59` |
| FE-TPT-001 | P1 | Hardcoded Maps API key in 3 views | `pickup_point/*.blade.php` |
| SEC-TPT-004 | P1 | `updateLastSeen()` ungated + force-enables device | `AttendanceDeviceController.php:~261` |
| VAL-TPT-001 | P1 | 19/19 FormRequests `authorize(){return true}` (D30) | `app/Http/Requests/*` |
| PERF-TPT-001 | P1 | God controllers + eager tabs + unbounded `::all()`; 0 services | `Mobile/MobileTransportController.php` |
| MIG-TPT-001 | P2 | `tpt_trip.status` VARCHAR not FK; `is_active` missing | `create_tpt_trip_table.php:24` |
| DEAD-TPT-002 | P2 | Orphan `TransportController.php-old` | controllers dir |
| TEN-RTG-001 | P1 (platform) | No `EnsureTenantHasModule` on transport group | `RouteServiceProvider.php` |

### Layer Health Summary
🔴 Code Quality (4), Authorization (5), Frontend (11) · 🟡 DDL (1), Mig↔Model (2), Tenancy (6 — module gate), Validation (7), Performance (9), Deployment (12) · 🟢 ORM (3), Data Integrity (8 — tx + locks + capacity) · ⚪ Queue/Job (10 — none built; that is itself a gap).

### STEP 1 Reading-Discipline Output
**Three-way:** `tpt_trip.status` VARCHAR(20) ↔ model plain fillable ↔ FSM string-compare (MIG-TPT-001); `is_active` cast in model but absent in migration. D36 N/A (no GENERATED columns).
**Snapshot corrections (file was stale):** `tested.` gate typo **FIXED**; capacity enforcement **implemented**; allocation **transactional**; "tpt 19 enums" → **0 enums**. Still true: 0 services, Aadhaar plaintext, `dd`, module-middleware gap.

---

### FRD Gap Summary (Mode B) — 23 REQ vs DDL / Code / Tests
| REQ | Feature | DDL | Code | Test | Gap |
|-----|---------|-----|------|------|-----|
| 001 Shift | ✅ | ✅ | ❌ | tests; no shift seeder |
| 002 Vehicle & compliance | ✅ | ✅ | ❌ | expiry auto-flag job missing |
| 003 Route & stop network | ✅ | ✅ | ❌ | tests |
| 004 Driver/helper | ✅ | ✅ | ❌ | **PII not encrypted** (SEC-TPT-005) |
| 005 Attendance device | ✅ | ✅ | ❌ | `updateLastSeen` ungated (SEC-TPT-004) |
| 006 Fine rules | ✅ | ✅ | ❌ | tests |
| 007 Driver-route-vehicle assign | ✅ | ✅ | ❌ | overlap trigger INSERT-only |
| 008 Scheduling & trip generation | ✅ | 🟡 | ❌ | **batch generation partial** |
| 009 Daily trip | ✅ | 🟡 | ❌ | **availability gate + vendor usage-log missing** |
| 010 Trip incidents | ✅ | 🟡 | ❌ | resolution FormRequest gap |
| 011 Student boarding | ✅ | 🟡 | ❌ | **scan-validation service missing** (BR-TPT-014) |
| 012 Driver attendance | ✅ | ✅ | ❌ | tests |
| 013 Inspection | ✅ | ✅ | ❌ | tests |
| 014 Service/maintenance | ✅ | 🟡 | ❌ | **vendor bill on approval missing** (BR-TPT-012) |
| 015 Fuel | ✅ | ✅ | ❌ | tests |
| 016 Student allocation | ✅ | 🟡 | ❌ | **stop-change workflow incomplete** |
| 017 Transport fee | ✅ | ✅ | ❌ | proration policy + ACC voucher (future) |
| 018 Parent notifications | ✅ | ❌ | ❌ | **not wired (0 jobs/events)** |
| 019 Expiry alerts (scheduled) | n/a | ❌ | ❌ | **no Console/Commands or Jobs** |
| 020 Reports | n/a | 🟡 | ❌ | no report service; inline queries |
| 021 Dashboard | n/a | 🟡 | ❌ | eager tab loads |
| 022 Live GPS (future) | ❌ | 🟡 | ❌ | **DDL tables absent (MD-06)** |
| 023 ML optimisation (future) | ❌ | 🟡 | ❌ | **DDL tables absent (MD-05)** |

**B headline:** CRUD/UI present for ~17/23; the gaps cluster in **automation** (notifications, scheduled alerts, batch generation), **cross-module hand-offs** (vendor bill/usage log, accounting), and **validation services** (boarding scan). **Tests: 0/23.** GPS/ML (022/023) have models but no DDL.

---

### Business-Rule Enforcement (Mode C) — 26 BR
| Status | BRs | Count |
|--------|-----|-------|
| ✅ ENFORCED | BR-001 (capacity, `StudentAllocationController:137`), BR-006 (trip-approve gate), BR-007 (failed inspection→service request, `…Inspection:54-71`), BR-009 (allocation atomic, tx), BR-010 (fuel approval), BR-015 (code/name unique), BR-018 (no schedule double-book, DB unique), BR-019 (one attendance/day), BR-023 (payment audit log) | 9 |
| 🟡 PARTIAL | BR-004 (police flag stored, alert/block not enforced), BR-008 (maintenance from request — flow present, gate not hard), BR-011 (monthly fee; proration policy unclear), BR-016 (stop-once DB unique; app sequence partial), BR-017 (overlap trigger INSERT-only, no UPDATE check), BR-020 (fine calc present; formula unverified), BR-025 (inspection sets unavailable; restore-on-out-service unverified) | 7 |
| ❌ MISSING | BR-002 (compliance gating on trip — no availability check in trip creation), BR-003 (licence gating — none), BR-005 (trip FSM — status set directly, no transition guard), BR-012 (maintenance→vendor bill — not wired), BR-013 (trip-approval→vendor usage log — not wired), BR-014 (boarding-scan validation — no service), BR-021 (PII encryption → SEC-TPT-005), BR-022 (module gate → TEN-RTG-001), BR-026 (rate limiting — none) | 9 |
| ➖ N/A | BR-024 (GPS isolation — GPS not built) | 1 |

**C headline:** the enforced rules are the *operational* ones (capacity, approvals, attendance, fuel, inspection→request). The **missing rules are the safety- and money-critical ones**: a non-compliant vehicle or unlicensed driver *can* be assigned (BR-002/003), the trip lifecycle has no transition guard (BR-005), child boarding isn't validated against allocation/stop/device (BR-014), and the two financial hand-offs (BR-012/013) plus PII (BR-021) and the module gate (BR-022) are absent. 5 of the 9 MISSING rules already carry Mode A issue codes.

---

### Systemic-Pattern Scorecard (Mode D, scoped to TPT)
| Pattern | Present? | Evidence / count | vs baseline |
|---------|----------|------------------|-------------|
| D17 (model col not in DB) | 🟡 latent | `tpt_trip.is_active` cast, migration lacks column | per-module norm |
| D24 (permission prefix chaos) | 🟢 absent | uniform `tenant.*`; `tested.` typo FIXED | better than baseline |
| D25 (`$request->all()`) | 🟢 absent | 0 sinks | better than baseline |
| D29 (ENUM / non-FK status) | 🟡 variant | 0 `->enum()`, but VARCHAR status (MIG-TPT-001) | mixed |
| D30 (FormRequest authorize true) | 🔴 present | 19/19 | at norm |
| D36 (generated-col degraded) | ➖ N/A | no GENERATED columns in TPT DDL | — |
| Layer 2.5 (missing FK target / orphan models) | 🔴 present | 5 GPS/ML models, no DDL tables (MD-05/06/07) | — |
| Layer 6.2 (initialize without end) | 🟢 absent | none | clean |
| Layer 10.1 (job tenancy) | ➖ N/A | 0 jobs (but REQ-018/019 automation missing) | gap |
| TEN-RTG-001 (module-subscription gate) | 🔴 present | RSP stack lacks `EnsureTenantHasModule` | 25/26 modules |

### vs Platform Baseline
D30 at norm; `$request->all()` 0 (better); module-gate missing (with the platform majority); 0 services/0 tests/0 jobs (below the norm for a module this size); D36 N/A.

### Recommended Fix Order (unblock-the-most-first)
1. **Deploy blockers (NO-GO → GO):** BUG-TPT-011 (remove `dd`), SEC-TPT-005 (encrypt PII), FE-TPT-001 (rotate/restrict/move Maps key), TEN-RTG-001 (add `EnsureTenantHasModule:TPT`).
2. **Safety BRs:** BR-002/003 (gate trip creation on vehicle availability + driver licence), BR-005 (trip status transition guard), BR-014 (boarding-scan validation service).
3. **Automation gaps:** REQ-019 scheduled expiry job, REQ-018 parent notifications, BR-012/013 vendor hand-offs.
4. **Hardening:** SEC-TPT-004 gate, VAL-TPT-001 FormRequest authorize(), MIG-TPT-001 status→FK, PERF-TPT-001 service extraction + tab lazy-load.
5. **Coverage:** add the P0 critical-path tests (currently 0/23 REQ).

---
*Mode X complete. Read-only. Findings carry the codes registered in `known-issues.md` from the Mode A pass (not re-appended — de-dup rule). Handoffs: deploy blockers + safety BRs → Developer; status→FK / is_active / GPS-ML DDL → DB Architect; 0-test coverage → Testing Architect.*
