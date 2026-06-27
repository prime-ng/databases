# Module Knowledge Summary: Admission Management (ADM)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/4-Initial_Requirements/V2/ADM_Admission_Requirement.md` (V2, 15 FRs, 15 BRs)
- `2-DDL_Tenant_Consolidated/AdmissionMgmt_DDL_v1.sql` (20 tables, 9 dependency layers)
- `Herd/prime_ai/Modules/Admission/` (live filesystem verification)

**Knowledge File:** `AI_Brain/module-knowledge/ADM_Admission.md`

---

## 1. Module Identity

| Item | Finding |
|------|---------|
| Module Code | `ADM` |
| Table Prefix | `adm_*` |
| Database | `tenant_db` (per-school, no `tenant_id` columns) |
| Laravel Path | `Modules/Admission/` |
| DDL Version | v1 (9-layer dependency chain, 20 tables) |
| V2 Requirement | `ADM_Admission_Requirement.md` (15 FRs, 15 BRs) |
| FRD Status | Not yet generated |

**Key Discovery from this session:** This module was seeded in a prior pass with status "0% Greenfield" (no code checked at seeding time). The update pass revealed ~60–65% actual completion with all controllers, models, services, and policies in place.

---

## 2. Actual vs. Proposed Comparison

The V2 requirement proposed counts. The update pass verified actual files from the filesystem.

| Metric | V2 Req Proposed | Actual (Jun 2026) | Change |
|--------|----------------|-------------------|--------|
| Controllers | **14** proposed | **18** actual | +4 (extras undocumented) |
| Models | 20 proposed | **20** actual | Exact match |
| Services | 6 proposed | **6** actual | Exact match |
| FormRequests | Not specified | **24** actual | New discovery |
| Policies | Not specified | **13** actual | New discovery |
| Tests | 25 scenarios specified | **0** actual | Critical gap |
| Blade Views | ~25 screens needed | **84** actual | 3× screen count |
| Route Lines | ~57 routes estimated | **251 lines** in web.php | 4× estimate |
| Jobs | 1 proposed (`PromoteExpiredOffersJob`) | **0** actual | P1 gap |
| Migrations | Required | **0** actual | P1 gap |
| Completion % | 0% (seeded incorrectly) | **~60–65%** | Corrected |

**Learning:** Controllers/models/services tend to match proposed counts accurately; views always exceed screen counts because each screen generates multiple blade partials; route lines far exceed named route counts because each route block includes `name()`, `middleware()`, and `prefix()` lines.

---

## 3. DDL Architecture: 9-Layer Dependency Chain

The ADM DDL v1 defines a strict 9-layer table dependency chain. This ordering must be followed for migrations, seeders, and factory setup.

| Layer | Tables | Key Dependency |
|-------|--------|----------------|
| 1 | `adm_admission_cycles` | No adm_* dependencies |
| 2 | `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity`, `adm_entrance_tests` | sch_classes |
| 3 | `adm_enquiries`, `adm_merit_lists` | std_students, sys_users |
| 4 | `adm_follow_ups`, `adm_applications` | adm_enquiries |
| 5 | `adm_application_documents`, `adm_application_stages`, `adm_entrance_test_candidates`, `adm_merit_list_entries` | adm_entrance_tests, adm_merit_lists |
| 6 | `adm_allotments`, `adm_promotion_batches` | sch_sections, sch_org_academic_sessions_jnt |
| 7 | `adm_withdrawals`, `adm_promotion_records` | sch_class_section_jnt |
| 8 | `adm_transfer_certificates`, `adm_behavior_incidents` | std_students (cross-module) |
| 9 | `adm_behavior_actions` | adm_behavior_incidents |

**Migration order must follow this chain exactly.** Any migration that violates layer order will fail on FK creation.

---

## 4. Four Extra Controllers Not in V2 Requirement

The actual module has 18 controllers vs 14 proposed. The 4 extras are:

| Controller | Purpose | Linked FR |
|-----------|---------|-----------|
| `AdmissionAnalyticsController` | Funnel reporting: Enquiry→Applied→Verified→Allotted→Enrolled conversion rates | FR-ADM-13 (V2 new) |
| `AdmMenuController` | Module sidebar menu configuration | Settings infrastructure |
| `AdmSettingsController` | Admission-level settings (cycle defaults, fee waiver rules, public form toggle) | FR-ADM-15 |
| `AlumniController` | Alumni management — **scope overlap risk** with `TransferCertificateController` | FR-ADM-11 |

**Risk:** `AlumniController` and `TransferCertificateController` both address FR-ADM-11. The V2 req expected TC to handle alumni management. A fat-controller or duplicate logic risk exists. Scope clarification needed before FRD generation.

---

## 5. Critical DDL Deviations from Requirement

Six DDL deviations were found where the DDL v1 differs from the V2 requirement spec. All require specific coding decisions.

### DDL-001 — Aadhar Uniqueness: Non-Unique Index Only (HIGH IMPACT)
- **Req doc says:** UNIQUE index on `adm_applications.aadhar_no` (nullable, partial)
- **DDL says:** `KEY idx_adm_app_aadhar (aadhar_no)` — non-unique only. DDL comment explicitly: "NOT UNIQUE at DB level; service-layer uniqueness check only"
- **Why:** MySQL partial UNIQUE on nullable causes issues across multi-tenant schema
- **Coding rule:** Never add a UNIQUE constraint on `aadhar_no`. Uniqueness enforced in `ApplicationService`, not the database. `StoreApplicationRequest` emits a warning, not a 422 block.

### DDL-002 — created_by / updated_by are NOT NULL (MEDIUM IMPACT)
- **Req doc says:** BIGINT UNSIGNED NULL (nullable)
- **DDL says:** NOT NULL on both columns, every table
- **Coding rule:** Model factories must always provide a valid `sys_users.id`. Seeder must run after `sys_users` seeder. No optional-user patterns allowed.

### DDL-003 — adm_merit_lists Has Two Extra Columns (MEDIUM IMPACT)
- `sibling_bonus_score TINYINT UNSIGNED NOT NULL DEFAULT 5` — copied from cycle at generation time (self-contained snapshot)
- `cutoff_score DECIMAL(6,2) NULL` — below cutoff → Rejected status
- **Why:** Merit list must be self-contained; changing cycle config after generation should not retroactively alter scores
- **Coding rule:** `MeritListService::generate()` must copy `adm_admission_cycles.sibling_bonus_score` and `cutoff_score` at generation time.

### DDL-004 — adm_document_checklist.admission_cycle_id is NULLABLE (LOW IMPACT)
- `admission_cycle_id BIGINT UNSIGNED NULL` — NULL means global system template row
- Extra column `is_system TINYINT(1) NOT NULL DEFAULT 0` not in req doc
- **Seeder rule:** System default checklist items → `admission_cycle_id = NULL, is_system = 1`. School-specific overrides → `admission_cycle_id` set.

### DDL-005 — FK Type: INT UNSIGNED vs BIGINT UNSIGNED (LOW IMPACT)
- Req doc specifies BIGINT UNSIGNED for all sys_users FKs (counselor_id, done_by, processed_by, etc.)
- DDL uses INT UNSIGNED to match `sys_users.id = INT UNSIGNED` in tenant_db
- `created_by`/`updated_by` remain BIGINT UNSIGNED with no FK constraint (audit columns only)
- **Rule:** All FK columns that reference `sys_users.id` → INT UNSIGNED. `created_by`/`updated_by` → BIGINT UNSIGNED.

### DDL-006 — behavior_score_impact is SIGNED TINYINT (LOW IMPACT)
- Signed allows negative values: "−5 for Medium, −15 for Critical" per DDL comment
- **Rule:** Model must not cast `behavior_score_impact` to unsigned. Negative values are intentional score deductions.

---

## 6. State Machines (4 FSMs)

### Application Lifecycle FSM (7 states)
```
Draft → Submitted → Verified → Shortlisted → Allotted → Enrolled ✅
                ↓           ↓              ↓
           (docs KO)   Rejected      Waitlisted ──(seat freed)──► Allotted
Any state before Enrolled → Withdrawn
```
All transitions logged to `adm_application_stages` (immutable audit trail).

### Allotment Offer FSM (3 states)
```
Offered → Accepted → enrollment queue
       → Declined  → next waitlisted promoted
       → Expired   → PromoteExpiredOffersJob (daily)
```

### Enquiry Lead FSM (6 states)
```
New → Assigned → Contacted → Interested → Converted ✅
                           → Not_Interested | Callback | Duplicate
```

### Promotion Batch FSM (2 states)
```
Draft → Confirmed ✅
(idempotent — firstOrCreate on std_student_academic_sessions)
```

---

## 7. Critical Cross-Module Integration: EnrollmentService

`EnrollmentService::enrollStudent()` is the most architecturally significant method in ADM. It performs **cross-module writes across 4 tables in a single `DB::transaction()`**:

1. Create `sys_users` (role = Student)
2. Create `std_students`
3. Create `std_student_academic_sessions`
4. Update `adm_allotments.status = Enrolled` + set `enrolled_student_id`
5. Link sibling in `std_siblings_jnt` if `adm_applications.is_sibling = 1`

**Risk:** If STD module tables don't exist (e.g., tenant bootstrapped without STD), the transaction fails at step 2, but the `adm_allotments` update at step 4 would roll back — no partial state. However, the 5-table cross-module transaction requires integration testing; unit tests mocking individual repos would not catch this.

**Dependency:** `adm_allotments.enrolled_student_id` FK to `std_students.id` creates a hard DDL dependency on STD module being present.

---

## 8. V2 New Additions vs V1

The V2 requirement added significant scope over V1:

| Addition | What It Is |
|---------|-----------|
| `adm_seat_capacity` table | Real-time seat fill counters per class per quota — replaces static `adm_quota_config.total_seats` for runtime blocking |
| `adm_withdrawals` table | Full withdrawal + refund workflow (was absent in V1) |
| FR-ADM-08 Withdrawal & Refund | Refund policy JSON in cycle; `Pending → Approved → Paid` FSM |
| FR-ADM-13 Analytics Funnel | Conversion rate funnel with 6-stage count (AdmissionAnalyticsController confirmed present) |
| FR-ADM-14 Sibling Preference | Auto-detect at enquiry (guardian mobile match), staff-confirm at application, +5 merit bonus |
| `PromoteExpiredOffersJob` | Daily waitlist auto-promotion when offers expire — **proposed but never created** |
| `offer_expires_at` column in `adm_allotments` | Drives the Expired state transition |
| `adm_transfer_certificates.is_duplicate` + `original_tc_id` | Duplicate TC reprint support |

---

## 9. Open Gaps & Recommended Actions

### P1 — Critical (Block FRD / Audit)

| Gap | Recommended Action |
|-----|-------------------|
| **0 test files** (25 scenarios specified) | EnrollmentService cross-module transaction, MeritListService quota scoring, ApplicationFSM state transitions, and PromotionService idempotency are all high-risk untested paths |
| **`PromoteExpiredOffersJob` never created** | Daily scheduler job for waitlist auto-promotion. Without it, expired offers are never cleared and waitlists stall |
| **0 migrations** | All 20 `adm_*` tables exist only in raw DDL — cannot bootstrap a new tenant via `artisan migrate`. Create in 9-layer order. |

### P2 — Architecture Verification Needed

| Gap | Recommended Action |
|-----|-------------------|
| Controller logic completeness unknown | 18 controllers present, but may be stubs. Technical Audit (Mode A) needed. |
| Aadhar AES-256 encryption unconfirmed | V2 req mandates at-rest encryption for `adm_applications.aadhar_no`. No Model accessor/mutator or encryption service found in this pass. |
| `EnrollmentService` cross-module writes | Transaction spans 4 tables across 2 modules. Integration test needed — unit tests with mocks are insufficient. |
| Events/Listeners directory missing | V2 req specified NTF notifications at each FSM stage transition. No Events/ or Listeners/ directory found. Notifications may be dispatched directly from controllers — fat-controller risk. |

### P3 — Scope Decisions Required

| Gap | Decision Needed |
|-----|----------------|
| `AlumniController` vs `TransferCertificateController` overlap | Both address FR-ADM-11. Define AlumniController scope before FRD generation. |
| `adm_behavior_*` tables in ADM vs future BEH module | Req doc notes these may be extracted to standalone `BEH` module in V3. Design for low coupling now. |

---

## 10. Cross-Module Dependency Map

### ADM Reads From:
| Module | Integration |
|--------|-----------|
| SchoolSetup (SCH) | Class/section/session selection for capacity and enrollment |
| StudentProfile (STD) | Sibling detection via guardian mobile match; enrollment writes to STD tables |
| StudentFee (FIN) | Application fee invoice generation; TC fee-clearance check (BR-ADM-004) |
| Payment (PAY) | Razorpay webhook for online fee confirmation (no-auth route, signature verified) |
| Notification (NTF) | Stage-transition notifications (hall ticket, offer letter, expiry reminders) |
| LmsExam (EXM) | Promotion criteria — pass/fail result cross-reference |
| GlobalMaster (GLB) | Address dropdowns, board for previous school |

### ADM Writes To (Outbound Impact):
| Module | What ADM Creates |
|--------|----------------|
| StudentProfile (STD) | `sys_users`, `std_students`, `std_student_academic_sessions` — enrollment seeds these |
| Attendance | Requires `std_student_academic_sessions.is_current = 1` from ADM enrollment |
| StudentFee (FIN) | Fee assignments depend on enrolled student records |
| Timetable | Class strength counts from `std_student_academic_sessions` |
| ParentPortal (PPT) | Parent account created at enrollment trigger |

---

## 11. Auto-Generated Number Sequences

| Field | Format | Service |
|-------|--------|---------|
| `adm_enquiries.enquiry_no` | `ENQ-YYYY-NNNNN` | `AdmissionPipelineService` on first save |
| `adm_applications.application_no` | `APP-YYYY-NNNNN` | `AdmissionPipelineService` on first save |
| `adm_entrance_test_candidates.roll_no` | Sequential per test | Auto-assigned on candidate list generation |
| `adm_allotments.admission_no` | School-configurable template e.g. `{YEAR}/{SEQ}` | `EnrollmentService` at offer letter generation (NULL until then) |
| `adm_transfer_certificates.tc_number` | `TC-YYYY-NNN` | `TransferCertificateService` per school-year |

---

## 12. Key Lessons Learned

1. **"0% Greenfield" seeding without filesystem check is always wrong for active modules.** This was the ADM seeding error — the prior pass read only the requirement doc and DDL, then recorded 0% because no code had been verified. Active modules accumulate significant scaffold between the requirement writing date and knowledge seeding date.

2. **Models and services tend to match the requirement exactly; views and routes do not.** ADM models (20/20) and services (6/6) matched proposed counts precisely. Views (84 vs 25 screens) and routes (251 lines vs ~57 estimated) were dramatically higher because each screen generates multiple blade partials and each route block has multiple lines.

3. **Controllers frequently exceed proposed counts.** ADM had 18 vs 14 proposed. Extra controllers (Analytics, Menu, Settings, Alumni) emerge during development as cross-cutting concerns get extracted. The V2 requirement was written before these were identified.

4. **The enrollment service is the highest-risk code in this module.** A 5-table cross-module transaction with no integration tests is the single biggest failure point. If `sys_users` or `std_students` creation fails and the rollback misses a side effect (e.g., a queued NTF job already dispatched), data integrity is at risk.

5. **DDL is the authoritative source — not the requirement doc.** Three DDL deviations (Aadhar non-unique, NOT NULL created_by, nullable admission_cycle_id) directly contradict the V2 requirement text. The DDL was written later and reflects architect decisions made after the req doc. Always read DDL v1 alongside the requirement for any coding decision.

6. **`adm_merit_lists.sibling_bonus_score` and `cutoff_score` must be snapshot-copied at generation time.** This is a self-contained merit list design decision not explained in the requirement. Without it, changing cycle configuration would retroactively corrupt existing merit lists — a correctness invariant enforced only by the seeding convention, not a DB constraint.

---

## 13. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | Generate FRD — must use DDL v1 (not req doc) for all 6 DDL deviations; clarify AlumniController scope first | Business Analyst → "create an FRD for Admission" |
| 2 | Implement `PromoteExpiredOffersJob` as a scheduled daily command | Developer |
| 3 | Create tenant migrations for all 20 ADM tables (9-layer order strictly) | Developer |
| 4 | Technical Audit (Mode A) — verify controller logic completeness, Aadhar AES-256 encryption, notification dispatch pattern, EnrollmentService transaction safety | Technical Auditor |
| 5 | Add integration tests: EnrollmentService (rollback on STD failure), MeritListService (quota cap + sibling bonus), ApplicationFSM (state guard tests), PromotionService (idempotency) | Developer |
| 6 | Clarify AlumniController scope vs TransferCertificateController before any further ADM code work | Business Analyst + Tech Lead |
| 7 | Confirm `sys_users.id` column type = INT UNSIGNED in current STD/SYS DDL (DDL-005 has FK type mismatch risk) | DB Architect |
