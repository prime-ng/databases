# Module Knowledge Summary: FrontOffice (FOF)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/4-Initial_Requirements/V2/FOF_FrontOffice_Requirement.md` (V2, 17 FRs, 15 BRs, 28 UI screens)
- `2-DDL_Tenant_Consolidated/FrontOffice_DDL_v1.sql` (22 tables, 4 dependency layers)
- `Herd/prime_ai/Modules/FrontOffice/` (live filesystem verification — seeding + update pass on 2026-06-27)

**Knowledge File:** `AI_Brain/module-knowledge/FOF_FrontOffice.md`

---

## 1. Module Identity

| Item | Finding |
|------|---------|
| Module Code | `FOF` |
| Table Prefix | `fof_*` |
| Database | `tenant_db` (per-school, no `tenant_id` columns) |
| Laravel Path | `Modules/FrontOffice/` |
| DDL Version | v1 (4 dependency layers, 22 tables) |
| V2 Requirement | `FOF_FrontOffice_Requirement.md` (17 FRs, 15 BRs, 28 screens) |
| FRD Status | Not yet generated |
| Scope | Campus reception operations: registers, circulars, certificates, gate passes, complaints, visitor management |

**Key Discovery:** Seeded as "0% Greenfield (RBS_ONLY)" on 2026-06-27. Update pass on the same day found ~55–65% actual completion with 21 controllers, 22 models, 13 policies, 118 views, and 302 route lines — none verified at seeding.

---

## 2. Actual vs. Proposed Comparison

| Metric | Seeded Estimate | Actual (Verified) | Change |
|--------|----------------|-------------------|--------|
| Controllers | 16–18 proposed | **21** | +3 (`FrontOfficeController` base, `FofMenuController`, `VisitorPurposeController` standalone) |
| Models | ~22 proposed | **22** | Confirmed exact match to DDL |
| Services | **6** proposed | **4** actual | −2 (`FeedbackService` + `CertificateIssuanceService` missing) |
| FormRequests | ~10 proposed | **10** | Confirmed |
| Policies | **4** proposed | **13** actual | **+9 — 3× undercount** (biggest proportional error in audit) |
| Blade Views | ~28-screen estimate | **118** | 4× screen count |
| Route Lines | ~95 estimated | **302 lines** (221 named routes) | 3× estimate |
| Tests | 0 | **1 file** (`AppointmentControllerTest`) | 1 of ~15+ needed |
| Jobs | Not tracked | **1** (`EarlyDepartureAttSyncJob`) | Queued — not synchronous |
| Events | Expected | **0** | No Events/ directory |
| Artisan Commands | 1 proposed (`fof:flag-overstay`) | **0 found** | P1 gap |
| Seeders | 2 proposed | **3 actual** | +1 (`FofSeederRunner` orchestrator) |
| Migrations | Required | **0** | Gap |
| Completion % | 0% (incorrectly seeded) | **~55–65%** | Corrected |

---

## 3. DDL Architecture: 4-Layer Dependency Chain (22 Tables)

| Layer | Tables | Role |
|-------|--------|------|
| 1 — Masters | `fof_visitor_purposes`, `fof_emergency_contacts`, `fof_notices`, `fof_school_events`, `fof_email_templates`, `fof_feedback_forms`, `fof_key_register` | Config masters; no fof_* dependencies |
| 2 — Transactions | `fof_visitors`, `fof_gate_passes`, `fof_early_departures`, `fof_phone_diary`, `fof_postal_register`, `fof_dispatch_register`, `fof_appointments`, `fof_lost_found`, `fof_certificate_requests`, `fof_complaints` | Core transaction tables; depend on Layer 1 + cross-module |
| 3 — Dependent Docs | `fof_circulars`, `fof_feedback_responses` | Depend on Layer 2 |
| 4 — Logs & Distribution | `fof_circular_distributions`, `fof_communication_logs`, `fof_sms_logs` | Immutable logs; depend on Layer 3 |

**Migration order must follow layers 1→2→3→4.** 22 migrations needed — none exist.

---

## 4. The Policy Count Error: 4 Proposed → 13 Actual (3× Undercount)

**This is the largest proportional policy undercount across all modules audited in this session.**

The seeded knowledge file recorded "4 proposed" policies — the req doc only explicitly mentioned "key" policies. The actual module has 13:

| Policy (Actual) | Covers |
|-----------------|--------|
| `AppointmentPolicy` | Appointment CRUD + slot conflict |
| `CertificateRequestPolicy` | Request workflow + fee-clearance gate |
| `CircularPolicy` | Edit-lock after approval (BR-FOF-008) |
| `CommunicationPolicy` | Bulk email/SMS targeting |
| `EarlyDeparturePolicy` | Student departure with guardian auth |
| `EmergencyContactPolicy` | Contact CRUD |
| `FeedbackFormPolicy` | Form lifecycle + anonymous submission |
| `FofComplaintPolicy` | Complaint CRUD + escalation |
| `GatePassPolicy` | One-active-pass-per-student guard |
| `NoticePolicy` | Notice board visibility + emergency override |
| `SchoolEventPolicy` | Event management |
| `VisitorPolicy` | Government visit deletion block (D2) |
| `VisitorPurposePolicy` | Purpose master CRUD |

**Rule reconfirmed:** Requirement docs mention "key" policies; actual modules create one policy per significant entity. Always verify via `ls app/Policies/`. The 4 seeded count was from req doc text; 13 is the actual codebase reality.

---

## 5. Two Proposed Services Never Created (P1 Gaps)

The V2 requirement proposed 6 services; 4 exist; 2 referenced in Design Decisions do not:

| Service | Status | Evidence |
|---------|--------|---------|
| `CircularService` | ✅ Exists | Circular approval workflow, distribution dispatch |
| `EarlyDepartureService` | ✅ Exists | ATT sync coordination, departure logging |
| `GatePassService` | ✅ Exists | Gate pass approval flow, one-active-guard |
| `VisitorService` | ✅ Exists | Visitor registration, overstay check |
| **`FeedbackService`** | ❌ **Missing** | Design Decision D5 implies feedback token generation + response aggregation in service; `FeedbackController` likely handles all directly |
| **`CertificateIssuanceService`** | ❌ **Missing** | Design Decision D10 explicitly names this service for fee-clearance check + PDF generation; `CertificateRequestController` likely handles directly |

**Risk for `CertificateIssuanceService`:** Design Decision D10 states: "`CertificateIssuanceService` checks StudentFee module before generating PDF. Outstanding fees block issuance." If this logic is in the controller, the fee-clearance check is not independently testable and cannot be called from other controllers (e.g., if Portal modules need to check eligibility before showing the "Request Certificate" button).

**Risk for `FeedbackService`:** Anonymous feedback token generation (`/feedback/{token}` public URL) is security-sensitive — the token must be unguessable and single-use. If token logic is in the controller, it's harder to test and easier to miss edge cases (token reuse, token expiry).

---

## 6. `fof:flag-overstay` Artisan Command Not Found (P1)

The V2 requirement specified `fof:flag-overstay` as a daily Artisan command (run at school closing time) to auto-transition visitors who have not checked out to `Overstay` status.

**Actual state:** No Commands/ directory found in `Modules/FrontOffice/app/Console/`. The command does not exist.

**Impact:** The `Overstay` state in the Visitor FSM is **unreachable**:
```
Visitor FSM: In → Out  (manual check-out)
                 → Overstay  ← UNREACHABLE without this command
```
All visitors who leave without signing out simply remain in `In` status indefinitely. The receptionist dashboard will show them as still on campus. School-end reporting of overstay visitors is impossible.

---

## 7. `EarlyDepartureAttSyncJob` — Queued, Not Synchronous

The V2 requirement described ATT sync as a service call (`EarlyDepartureService::syncAttendance()`) made after early departure is recorded. The actual implementation creates `EarlyDepartureAttSyncJob` as a `ShouldQueue` job.

**Why this is better design:** A synchronous ATT module call during the receptionist's "save early departure" action would block the HTTP response until ATT completes. A queued job returns immediately and syncs asynchronously.

**Risk:** If the ATT module is not operational, the job fails silently and `att_sync_status` stays `pending`. The receptionist has no immediate feedback. The dashboard must surface `att_sync_status = 'pending'` / `'failed'` records prominently (BR-FOF-013).

---

## 8. Eight State Machines (8 FSMs)

FOF has the highest number of FSMs of any module in the audit to date:

| FSM | States | Critical Rule |
|-----|--------|--------------|
| Visitor | `In` → `Out` / `Overstay` (cron — **cron missing**) | Government visits cannot be deleted (D2) |
| Gate Pass | `Pending_Approval` → `Approved`/`Rejected` → `Exited` → `Returned`/`Cancelled` | One active pass per student at a time (BR-FOF-004) |
| Circular | `Draft` → `Pending_Approval` → `Approved` → `Distributed`/`Recalled` | Edit blocked after Approved (BR-FOF-008) |
| Certificate Request | `Pending_Approval` → `Approved`/`Rejected` → `Issued`/`Cancelled` | Fee clearance required for TC_Copy/Migration (BR-FOF-005) |
| Appointment | `Pending` → `Confirmed` → `Completed`/`No_Show`/`Cancelled` | Slot conflict check via composite index |
| Complaint | `Open` → `In_Progress` → `Resolved`/`Escalated`/`Closed` | Escalation creates linked CMP record |
| Lost & Found | `Unclaimed` → `Claimed`/`Disposed`/`Returned_to_Authority` | — |
| Key | `Available` → `Issued` → `Overdue`/`Returned`/`Lost` | Re-issue blocked if status is Issued or Overdue (BR-FOF-012) |

**Test coverage for FSM transitions:** 0 tests covering any FSM (1 test file covers Appointment CRUD, not FSM transitions).

---

## 9. Key Architecture Decisions (14 Documented)

| Decision | Summary | Risk if Missed |
|----------|---------|---------------|
| D1 — `fof_circular_distributions` immutable | No `deleted_at`, no `updated_by`; append-only NTF delivery log | Soft-delete attempt errors; any UPDATE is a compliance violation |
| D2 — Government visit deletion blocked | `VisitorPolicy::delete()` blocks when `is_government_visit = 1`; `GOVT_INSPECTION` purpose seeded with this flag | CBSE/State Board inspection records lost if policy not checked |
| D3 — Postal lock after acknowledgement | `acknowledged_at` set → record becomes read-only (BR-FOF-009) | Update after acknowledgement corrupts postal audit trail |
| D4 — Circular edit blocked after approval | `CircularController::update()` blocked when status = `Approved` or `Distributed` (BR-FOF-008) | Post-approval edits change distributed content without re-distribution |
| D5 — Anonymous feedback null user ID | `publicSubmit()` enforces `respondent_user_id = NULL` when `is_anonymous = 1` | Anonymous identity leak if null not enforced |
| D6 — `cert_number` UNIQUE but nullable | NULL until physical issuance; MySQL UNIQUE allows multiple NULLs; type-prefixed on issue (BON-YYYY-NNN) | Duplicate cert number if issuance logic creates number before save |
| D7 — Early departure ATT sync must not fail silently | Failed sync surfaces on receptionist dashboard; retry queue used (BR-FOF-013) | Silent failure leaves student marked present despite early departure |
| D8 — Emergency notices bypass display dates | `is_emergency = 1` notices always shown regardless of `display_from`/`display_until` (BR-FOF-014) | Emergency info hidden during date-filtered query if flag not checked |
| D9 — One active gate pass per student | `IssueGatePassRequest` queries for active passes before accepting new one (BR-FOF-004) | Concurrent gate pass requests could both pass without DB-level constraint |
| D10 — TC_Copy/Migration cert fee clearance | `CertificateIssuanceService` (not yet created) checks StudentFee module before PDF (BR-FOF-005) | TC issued despite outstanding fees |
| D11 — Aadhar stored full, displayed masked | `id_proof_number` stored complete per tenant encryption policy; UI shows last 4 digits only (BR-FOF-015) | Full Aadhar exposure in UI if masking removed |
| D12 — Appointment slot conflict via composite index | `idx_fof_apt_slot` on `(with_user_id, appointment_date, start_time, end_time)` supports slot check | Double-booking if index not used in availability query |
| D13 — Key re-issue blocked without return | `KeyRegisterController::issue()` checks status before issuing (BR-FOF-012) | Key lost without record if issued when already marked Issued |
| D14 — FOF vs VSM distinction | FOF = inside reception (registers, certs, circulars); VSM = gate security (biometric, vehicle); visitor handoff via `vsm_visitor_id` FK (pending VSM) | Wrong module for visitor security features |

---

## 10. Immutable / Compliance Records

| Table | Immutability | Reason |
|-------|-------------|--------|
| `fof_circular_distributions` | No `deleted_at`, no `updated_by` | Append-only NTF delivery log per recipient |
| `fof_visitors` (government subset) | Policy blocks delete when `is_government_visit = 1` | CBSE/State Board inspection compliance |
| `fof_postal_register` | Read-only after `acknowledged_at` is set | Postal audit trail integrity |

---

## 11. Open Gaps & Recommended Actions

### P1 — Critical

| Gap | Recommended Action |
|-----|-------------------|
| **Only 1 test file** (AppointmentControllerTest) | Priority tests: gate pass one-active-per-student guard (BR-FOF-004), anonymous feedback null user_id (BR-FOF-010), postal record lock after acknowledgement (BR-FOF-009), circular edit-lock after approval (BR-FOF-008), visitor government-visit delete block (D2) |
| **`fof:flag-overstay` command missing** | Create Artisan command; schedule daily at `sys_school_settings.school_closing_time`; without it, Visitor Overstay FSM state is permanently unreachable |
| **`CertificateIssuanceService` missing** | Extract fee-clearance check + PDF generation from `CertificateRequestController`; critical for isolated testing and Portal module eligibility checks |
| **`FeedbackService` missing** | Extract token generation, form lifecycle, response aggregation from `FeedbackController`; token security is critical for anonymous feedback |
| **0 migrations** | Create 22 tenant migrations (4-layer order); `vsm_visitor_id` FK migration stays commented until VSM module DDL is ready |

### P2 — Architecture Risk

| Gap | Recommended Action |
|-----|-------------------|
| 0 Events/Listeners | NTF dispatch for gate pass alerts, circular distribution, cert notifications likely in controllers. Technical Audit to confirm dispatch pattern and whether it's queued. |
| `EarlyDepartureAttSyncJob` failure visibility | Verify receptionist dashboard surfaces `att_sync_status = 'pending'/'failed'` records as required by BR-FOF-013 |
| Controller logic completeness unknown | 21 controllers present; FSM enforcement depth, fee-clearance chains, CMP escalation unverified. Technical Audit (Mode A) needed. |
| `FrontOfficeController` scope unknown | Base controller exists — verify it's a navigation hub only, not a GOD controller with business logic |

### P3 — Integration & Cleanup

| Gap | Action |
|-----|--------|
| VSM FK still omitted | `vsm_visitor_id` FK on `fof_visitors` remains commented out; document removal from VSM release checklist |
| `fof_table_prefix` note | RBS spec uses `fro_` prefix; actual tables use `fof_*`. Ensure any agent reading RBS spec is aware — do not use `fro_*` in migrations or models |

---

## 12. Cross-Module Integration Map

### FOF Reads From:
| Module | Integration |
|--------|-----------|
| System (SYS) | `sys_users`, `sys_media`, `sys_activity_logs` — auth, staff lookup, file storage, audit |
| SchoolSetup (SCH) | `sch_organizations`, `sch_classes`, `sch_sections` — school branding on certs; class/section for circular targeting |
| StudentProfile (STD) | `std_students` — gate pass, early departure, certificate request FKs |
| Attendance (ATT) | Service/job call — early departure logs absence for remaining periods |
| Notification (NTF) | Email + SMS — circular distribution, gate pass parent notification, cert notifications |
| StudentFee (FIN) | Balance check — TC_Copy/Migration certificate fee clearance (BR-FOF-005) |
| Complaint (CMP) | `cmp_complaints` — FOF complaint escalation creates linked CMP record |
| VSM | `vsm_visitors` — pre-registered visitor handoff (FK pending VSM module) |
| GlobalMaster (GLB) | Country/state — visitor address dropdowns, ID proof types |

### FOF Serves:
| Module | What It Provides |
|--------|----------------|
| Parent Portal (PPT) | `fof_circulars`, `fof_notices`, `fof_school_events`, `fof_certificate_requests` |
| Student Portal (STP) | `fof_notices`, `fof_school_events`; cert request submission |
| VSM | `fof_visitors` for visitor pass status; arrival notification posting |

---

## 13. Key Lessons Learned

1. **Policy count is the most under-represented metric in requirement docs.** FOF's seeded knowledge recorded 4 policies; actual is 13. Across all modules audited, policy count from req docs has been wrong in every case — either too high (BIL: 7 → 8) or dramatically too low (FOF: 4 → 13). Requirement docs list "key" policies; developers create one per entity. `ls app/Policies/` is the only reliable source.

2. **Services named in Design Decisions are not the same as implemented service files.** FOF's Design Decision D10 explicitly states "`CertificateIssuanceService` checks StudentFee module before generating PDF." The service does not exist. Similarly, the feedback token pattern implies `FeedbackService`. Design Decisions document *intent*; `ls app/Services/` documents *reality*.

3. **An FSM terminal state that requires a cron job is broken without it.** The Visitor FSM's `Overstay` state can only be reached by `fof:flag-overstay` running daily. The command doesn't exist. From the data perspective, `Overstay` is an orphaned enum value — records can never reach it in production. This is a class of bug that doesn't produce an error; it just silently leaves the FSM in an incomplete state.

4. **Queued jobs are the right pattern for cross-module side effects during user-facing saves.** `EarlyDepartureAttSyncJob` (queued) is better than synchronous ATT service call — it avoids blocking the receptionist's save action. The req doc implied synchronous; the developer chose async. This is an example where the implementation is better than the specification. When auditing, "implemented differently from req doc" is not automatically a gap — judge the design on its merits.

5. **Views are 4× screen count — confirmed again.** FOF has 28 UI screens and 118 blade files. This is now the fourth module in the audit to confirm the 3–4× ratio. Estimated view counts from req docs are always a floor, not a ceiling. The multiplier is: 1 screen → ~4 blade files (index, create/edit, show, partials/modals/print).

6. **Two requirement format ambiguities in FOF DDL:** The RBS spec uses prefix `fro_` while actual tables use `fof_*`. Any agent reading the RBS spec for table names would generate wrong FK references. Platform naming convention (`fof_*` per module code FOF) overrides RBS spec when they conflict.

7. **"0% Greenfield (RBS_ONLY)" tag in seeded file was incorrect.** The module had 21 controllers, 118 views, and 302 route lines at the time of seeding. "RBS_ONLY" referred to the requirement stage the module was thought to be at — not the actual code state. Any seeded status of "0% Greenfield" or "RBS_ONLY" must be verified before being relied on.

---

## 14. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | Create `fof:flag-overstay` Artisan command — scheduled daily at school closing time; without it Visitor Overstay FSM state is permanently unreachable | Developer |
| 2 | Create `CertificateIssuanceService` — extract fee-clearance check (FIN integration) + PDF generation from `CertificateRequestController` | Backend Developer |
| 3 | Create `FeedbackService` — extract token generation, form lifecycle, anonymous submission enforcement from `FeedbackController` | Backend Developer |
| 4 | Add tests: gate pass one-active guard (BR-FOF-004), anonymous feedback null user_id (BR-FOF-010), postal lock after acknowledgement (BR-FOF-009), circular edit-lock (BR-FOF-008), government visit delete block (D2) | Testing Architect |
| 5 | Create 22 tenant migrations (4-layer order; `vsm_visitor_id` FK stays commented until VSM ready) | Developer |
| 6 | Technical Audit (Mode A) — verify controller logic depth for all 8 FSMs; confirm NTF dispatch pattern; check `EarlyDepartureAttSyncJob` failure surfacing on dashboard | Technical Auditor |
| 7 | Generate FRD — document 2 missing services as gaps; include all 8 FSMs; use DDL v1 as authoritative source over RBS spec (`fof_*` not `fro_*`) | Business Analyst → "create an FRD for FrontOffice" |
