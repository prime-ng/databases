# Student Leave Management — Validation Report

**Feature:** StudentLeave  **Module:** StudentProfile  **Prefix:** `std_`  **DB scope:** TENANT
**Generated:** 2026-Jul-10

---

## 1. File Existence Summary

| # | File | Present |
|---|------|---------|
| 1 | `std_StudentLeaveTcList_Require.md` | ✅ |
| 2 | `std_StudentLeaveMANUALTESTING_Require.md` | ✅ |
| 3 | `std_StudentLeaveGAPANALYSIS_Require.md` | ✅ |
| 4 | `std_StudentLeave_TestCas.php` | ✅ (ONE file — no V1/V2) |
| 5 | `std_StudentLeaveValidation_Report.md` | ✅ |
| 6 | `run-StudentLeave-tests.ps1` | ✅ |
| 7 | `run-StudentLeave-tests.sh` | ✅ |

All 7 artifacts in `TestCases/StudentProfile/StudentLeave/`.

---

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix matches DDL primary table (`std_leave_applications` → `std_`) | ✅ (not `spr_`) |
| Feature PascalCase | ✅ `StudentLeave` |
| Class name = filename | ✅ `class std_StudentLeave_TestCas` |
| snake_case zero-padded methods, semantic bands | ✅ `test_student_leave_NN_*` |
| Exactly one `.php` test file | ✅ |

---

## 3. Structure Validation

| Check | Result |
|-------|--------|
| `namespace Tests\Browser;` | ✅ |
| `extends DuskTestCase` | ✅ (mirrors sibling `spr_MedicalIncident_TestCas`) |
| `use App\Models\User;` | ✅ (05_ #5) |
| Tenant init `initializeTenantContext()` via `Modules\Prime\Models\Domain` | ✅ (05_ #2) |
| Typed props initialised (`= null` / `''`) | ✅ (05_ #13) |
| Guarded teardown `tenancy()->end()` | ✅ (05_ #3) |
| Activity log via tenant `Modules\GlobalMaster\Models\ActivityLog` | ✅ (tenancy initialized — 05_ #25) |
| `php -l` | ✅ **No syntax errors detected** |

---

## 4. Coverage Completeness

- **Total methods:** 59 (single file).
- **Coverage gates:** Negative **100%**, Positive **100%** (≥90), Dependency **100%** covered (1 Full + 2 metadata-partial, ≥90% intent), Tenancy/Security **100%**.
- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §3 Test Method Index and Gap Analysis §1).
- **BC-SM:** 10 transition cases — 6 legal (Submitted→Under Review/Approved/Rejected/Info Requested/Doc Requested, Under Review→Approved), 2 illegal-target validation guards (→Cancelled, →Submitted/Draft/invalid), 1 auto-log, 1 defect proof (BUG-STD-15 no source guard).
- No V1/V2 ratio applies; coverage-gated only.

---

## 5. Known Source Defects Documented

| ID | Where documented | Proving test | Notes |
|----|------------------|--------------|-------|
| GAP-STD-06 | TcList §4, Gap §3/§5 | `_51`, `_52` | Audit (2026-06-30) reported `Gate::authorize` commented out at lines 25/250. **Current source has active gates on all 8 `StdLeaveController` methods → appears REMEDIATED.** Tests probe observed status (no 403 assumption); note `Gate::before` super-admin bypass requires a limited non-super user to exercise the gate. |
| BUG-STD-14 | TcList §4, Gap §3 | `_70` | `remark_type` DDL ENUM `('Comment','Info_Request','Doc_Request','Response','Status_Change')` vs lowercase model constants — round-trip case mismatch. |
| BUG-STD-15 | TcList §4, Gap §3 | `_28` | `updateReview`/`LeaveService::review()` validate only the target status → illegal FSM moves (Approved→Rejected) accepted. |
| (candidate) class-teacher row-level scoping | Gap §4 | — | Policy checks ability string only, not class ownership. Unverified — not raised as a DEV id. |

---

## 6. Environment Prerequisites (05_ §E)

- **Module must be ENABLED** — `prime_testing/modules_statuses.json` currently `"StudentProfile": false`; all routes return 404 until enabled (05_ #19). **Dusk was NOT run** (module disabled, per instruction). Only `php -l` executed.
- `APP_ENV=testing` required for CSRF-bypassed state changes (05_ #20).
- Tenant server reachable at `DUSK_TENANT_URL` (`http://test.localhost:8000`); tenant domain row present in `prm_domains` (05_ #2/#21 — this is a tenant-side feature, NOT central).
- Migration schema truth resolved by glob from `database/migrations/tenant/` (module migrations dir empty — 05_ #26).

## 7. Constraints applied (05_)
#2 Domain tenant resolve · #3 guarded teardown · #5 App\Models\User + factory · #8/#9 limited-user via `User::factory()` with `user_type='EMPLOYEE'`, emp_code-safe suffix · #13 typed props · #14 no `Browser::assertStatus` — status via in-page fetch (`sendJsonRequestFromBrowser`) · #18 status/half_day_slot/remark_type ENUMs asserted case-exact · #19/#20 env prereqs noted · #25 tenant activity_logs sink · #26 migration glob (fail-soft).

---

## 8. Final Verdict

**PASS WITH NOTES.**

Notes:
1. Suite not executed (StudentProfile module disabled in `modules_statuses.json`); `php -l` clean. Enable the module to run the Dusk suite.
2. Three defects carried with proving tests: GAP-STD-06 (appears remediated — tests confirm at runtime), BUG-STD-14 (enum case), BUG-STD-15 (FSM no source-state guard).
3. Two FK dependency cases (TC-D44/D45) use schema-metadata + defensive assertions rather than hard-deleting shared seed students/reviewer users in the live tenant DB.
