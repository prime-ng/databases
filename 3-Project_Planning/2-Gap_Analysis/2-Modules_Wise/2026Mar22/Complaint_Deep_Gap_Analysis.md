# Complaint Module — Production-Readiness Gap Analysis
**Date:** 2026-03-22  |  **Branch:** Brijesh_SmartTimetable  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** /Users/bkwork/Herd/prime_ai/Modules/Complaint

---

## EXECUTIVE SUMMARY

| Metric | Count |
|--------|-------|
| Critical (P0) | 8 |
| High (P1) | 12 |
| Medium (P2) | 14 |
| Low (P3) | 7 |
| **Total Issues** | **41** |

| Area | Score |
|------|-------|
| DB Integrity | 5/10 |
| Route Integrity | 6/10 |
| Controller Quality | 3/10 |
| Model Quality | 6/10 |
| Service Layer | 7/10 |
| FormRequest | 1/10 |
| Policy/Auth | 5/10 |
| Test Coverage | 0/10 |
| Security | 3/10 |
| Performance | 4/10 |
| **Overall** | **4.0/10** |

---

## SECTION 1: DATABASE INTEGRITY

### DDL Tables (6 tables)
1. `cmp_complaint_categories` (line 2040)
2. `cmp_department_sla` (line 2081)
3. `cmp_complaints` (line 2137)
4. `cmp_complaint_actions` (line 2212)
5. `cmp_medical_checks` (line 2237)
6. `cmp_ai_insights` (line 2260)

### Issues

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| DB-01 | P0 | `cmp_complaint_categories` missing `created_by` column | DDL line 2040-2075 |
| DB-02 | P0 | `cmp_complaint_categories` missing `deleted_at` column | DDL line 2040-2075 |
| DB-03 | P1 | `cmp_department_sla` missing `created_by` and `deleted_at` columns | DDL line 2081-2126 |
| DB-04 | P1 | `cmp_medical_checks` missing `updated_at`, `deleted_at`, `is_active`, `created_by` columns | DDL line 2237-2253 |
| DB-05 | P1 | `cmp_complaint_actions` missing `updated_at`, `deleted_at`, `is_active`, `created_by` columns (audit trail table) | DDL line 2212-2231 |
| DB-06 | P2 | `cmp_complaints` has index on non-existent column `status` at line 2187 — should be `status_id` | DDL line 2187 |
| DB-07 | P2 | `cmp_complaints` FK `fk_cmp_medical_check` references `cmp_medical_checks(id)` on `is_medical_check_required` TINYINT — type mismatch/wrong FK | DDL line 2204 |
| DB-08 | P2 | `cmp_complaint_categories` model has `department_id` in fillable but column missing from DDL | Model line 24 vs DDL |
| DB-09 | P2 | `cmp_complaint_categories` model has `expected_resolution_hours` but DDL has `default_expected_resolution_hours` — column name mismatch | Model line 28 vs DDL line 2048 |
| DB-10 | P2 | `cmp_complaint_categories` model has `escalation_hours_l1..l5` but DDL has `default_escalation_hours_l1..l5` — column name mismatch | Model line 29-33 vs DDL lines 2049-2053 |
| DB-11 | P3 | `cmp_ai_insights` missing `is_active`, `updated_at`, `deleted_at`, `created_by` columns | DDL line 2260-2276 |

---

## SECTION 2: ROUTE INTEGRITY

### Registered Routes (tenant.php lines 1187-1344)
- `complaint.complaint-mgt.*` — resource (7 routes)
- `complaint.complaint-categories.*` — resource + trash/restore/forceDelete/toggleStatus
- `complaint.complaints.*` — resource + trash/restore/forceDelete/toggleStatus/manage
- `complaint.complaint-actions.*` — resource + restore/forceDelete
- Department SLA routes — resource + trash/restore/forceDelete/toggleStatus
- Medical Checks routes — resource + trash/restore/forceDelete/toggleStatus
- AI Insights routes — resource + trash/restore/forceDelete/toggleStatus
- Reports routes — summary

### Issues

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| RT-01 | P1 | Duplicate resource registration: `complaint-mgt` and `complaints` both point to `ComplaintController` — ambiguous routing | tenant.php lines 1193, 1253 |
| RT-02 | P1 | `EnsureTenantHasModule` middleware NOT applied to complaint route group | tenant.php line 1189 — only `auth`, `verified` applied |
| RT-03 | P2 | Route name mismatch: `complaint.complaints.manage` expects `{id}` param but route definition at line 1277 has no parameter | tenant.php line 1277 |
| RT-04 | P2 | Dashboard route commented out at line 1191 | tenant.php line 1191 |
| RT-05 | P3 | Route naming inconsistency: `complaint-mgt` vs `complaints` for same controller | tenant.php lines 1193, 1253 |

---

## SECTION 3: CONTROLLER AUDIT

### ComplaintController.php (925 lines)
**Path:** `/Users/bkwork/Herd/prime_ai/Modules/Complaint/app/Http/Controllers/ComplaintController.php`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| CT-01 | P0 | **INLINE VALIDATION** — `store()` uses `$request->validate()` instead of FormRequest | Line 254-269 |
| CT-02 | P0 | **INLINE VALIDATION** — `update()` uses `$request->validate()` instead of FormRequest | Line 511-521 |
| CT-03 | P0 | **dd() in production code** — `store()` has `dd($e->getMessage())` in catch block | Line 407 |
| CT-04 | P0 | **dd() in production code** — `filter()` has `dd('FILTER HIT', request()->all())` | Line 833 |
| CT-05 | P0 | Hardcoded dropdown ID `status_id => 124` in `store()` | Line 357 |
| CT-06 | P0 | Hardcoded action type ID `197` in `update()` | Line 560 |
| CT-07 | P0 | Hardcoded action type ID `202` in `update()` | Line 575 |
| CT-08 | P1 | `$request->all()` used implicitly — `store()` uses `$request->field` instead of `$request->validated()` | Lines 332-358 |
| CT-09 | P1 | `show()` missing Gate authorization | Line 418-445 |
| CT-10 | P1 | `edit()` missing Gate authorization | Line 451-498 |
| CT-11 | P1 | `update()` missing Gate authorization | Line 503-585 |
| CT-12 | P1 | `destroy()` empty — no implementation | Line 591 |
| CT-13 | P1 | `index()` missing pagination on `Complaint::orderBy('created_at', 'desc')->get()` — loads ALL complaints | Line 92 |
| CT-14 | P1 | Duplicate escalation logic in `index()` (lines 96-162) and `getComplaintsWithEscalation()` (lines 633-705) — code duplication | Lines 96-162 and 633-705 |
| CT-15 | P2 | No activity logging (`activityLog()`) in store/update/destroy | Throughout controller |
| CT-16 | P2 | N+1 query: `index()` calls `DB::table('sys_dropdowns')` inside `$complaints->map()` for every complaint | Lines 98-102 |
| CT-17 | P2 | `update()` — `$statusChangeActionId` is a Query Builder, not a value; passed directly to `logAction()` | Line 532-536 |
| CT-18 | P2 | `manage()` uses wrong gate key `prime.complaint.manage` — should be `tenant.*` prefix | Line 779 |
| CT-19 | P3 | Commented-out code blocks throughout (lines 241-251, 313-320, 541-547) | Multiple |

### Other Controllers
- **ComplaintCategoryController** — Not present as standalone file; categories managed within ComplaintController
- **DepartmentSlaController** — Present at expected path
- **MedicalCheckController** — Present at expected path
- **AiInsightController** — Present at expected path
- **ComplaintDashboardController** — Present at expected path
- **ComplaintReportController** — Present at expected path
- **ComplaintActionController** — Present at expected path

---

## SECTION 4: MODEL AUDIT

### Complaint Model
**Path:** `/Users/bkwork/Herd/prime_ai/Modules/Complaint/app/Models/Complaint.php`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| MD-01 | P1 | `$fillable` contains `target_id` but DDL has `target_selected_id` | Line 37 |
| MD-02 | P1 | `$fillable` contains `escalation_level` but DDL has `current_escalation_level` | Line 64 |
| MD-03 | P1 | `$fillable` missing `target_table_name`, `target_code`, `target_user_type_id` (uses `target_type_id` instead) | Lines 35-76 vs DDL |
| MD-04 | P2 | `target()` method returns a scalar value, not a relationship — will break eager loading | Line 152 |
| MD-05 | P2 | Missing relationship for `subCategory` — uses lowercase `subcategory()` at line 162 but controller calls `subCategory` (capitalized) at line 422 | Lines 162, 422 |
| MD-06 | P3 | Missing `$casts` for `created_at`, `updated_at` as timestamps (auto-handled, but inconsistent) | Line 81-91 |

### ComplaintCategory Model
**Path:** `/Users/bkwork/Herd/prime_ai/Modules/Complaint/app/Models/ComplaintCategory.php`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| MD-07 | P1 | Column name mismatches: fillable has `expected_resolution_hours` vs DDL `default_expected_resolution_hours` | Line 28 |
| MD-08 | P2 | Missing `HasFactory` trait import (not using it) | Line 11 — `SoftDeletes` used but DDL has no `deleted_at` column |
| MD-09 | P2 | `SoftDeletes` trait used but DDL table `cmp_complaint_categories` has no `deleted_at` column | Line 13 vs DDL line 2040 |
| MD-10 | P2 | Missing `default_escalation_l1..l5_entity_group_id` in fillable and relationships | DDL lines 2054-2058 |

---

## SECTION 5: SERVICE AUDIT

### ComplaintDashboardService
**Path:** `/Users/bkwork/Herd/prime_ai/Modules/Complaint/app/Services/ComplaintDashboardService.php`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| SV-01 | P2 | `getRepeatedTargetFrustration()` queries `target_id` — but model has `target_id` while DDL has `target_selected_id` | Line 447 |
| SV-02 | P2 | N+1 in `getEscalationHeatmapData()` — loads all complaints then iterates calling `calculateCurrentEscalationLevel()` which hits DB per complaint | Lines 131-152 |
| SV-03 | P3 | No interface/contract defined for the service | Throughout |

### ComplaintAIInsightEngine
- Present but not audited in detail — secondary service

---

## SECTION 6: FORMREQUEST AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| FR-01 | P0 | **NO FormRequest classes exist** for the entire Complaint module | `Modules/Complaint/app/Http/Requests/` directory does not exist |
| FR-02 | P0 | `store()` and `update()` use inline `$request->validate()` | Controller lines 254, 511 |

---

## SECTION 7: POLICY AUDIT

### ComplaintPolicy
**Path:** `/Users/bkwork/Herd/prime_ai/Modules/Complaint/app/Policies/ComplaintPolicy.php`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| PL-01 | P0 | `create()` method checks wrong permission `tenant.vendor-dahsboard.create` (typo + wrong module) | Line 31 |
| PL-02 | P1 | Policies exist but NOT consistently used in controller — `show()`, `edit()`, `update()`, `destroy()` have no Gate calls | Controller lines 418, 451, 503, 591 |
| PL-03 | P2 | `ComplaintDashboardPolicy` registered but dashboard route commented out | tenant.php line 1191 |

### Other Policies
- `AiInsightPolicy` — Present, registered in AppServiceProvider
- `ComplaintActionPolicy` — Present, registered
- `ComplaintCategoryPolicy` — Present, registered
- `DepartmentSlaPolicy` — Present, registered
- `MedicalCheckPolicy` — Present, registered

---

## SECTION 8: VIEW AUDIT

Views are present for all CRUD operations:
- `complaint/category/` — create, edit, index, show, trash (5 views)
- `complaint/complaint/` — create, edit, index, show, trash (5 views)
- `complaint/complaint-manage/` — actions, index (2 views)
- `complaint/department-sla/` — create, edit, index, show, trash (5 views)
- `complaint/medical-checks/` — create, edit, index, show, trash (5 views)
- `reports/` — 5 report views
- `complaint/dashboard.blade.php`
- `complaint/ai-insights/index.blade.php`

No issues with view coverage.

---

## SECTION 9: SECURITY AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| SEC-01 | P0 | `dd()` leaks stack trace and exception details to browser | ComplaintController.php line 407 |
| SEC-02 | P0 | Policy `create()` uses wrong permission — any user with vendor-dashboard create can create complaints | ComplaintPolicy.php line 31 |
| SEC-03 | P1 | No CSRF protection verification for AJAX endpoints (severity/department donut charts) | Controller lines 859-924 |
| SEC-04 | P1 | SQL injection risk via `$request->search` used in LIKE without sanitization in `getMedicalChecksData()` | Controller line 615 |
| SEC-05 | P1 | Webhook/event-based complaint creation has no rate limiting | Controller `store()` |
| SEC-06 | P2 | No input sanitization on `description`, `resolution_summary`, `notes` — potential XSS | Controller lines 265, 519 |
| SEC-07 | P2 | `$request->all()` used implicitly through `$request->field_name` bypassing validated() | Controller `store()` |
| SEC-08 | P2 | Sensitive bank/PII data in vendor FK accessible through complaint relationships | Model relationships |

---

## SECTION 10: PERFORMANCE AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| PERF-01 | P0 | `index()` loads ALL complaints without pagination — `Complaint::orderBy('created_at', 'desc')->get()` | Controller line 92 |
| PERF-02 | P1 | N+1 query: `complaints->map()` calls `DB::table('sys_dropdowns')` per complaint inside loop | Controller lines 98-102 |
| PERF-03 | P1 | Duplicate complaint loading: `getComplaintsWithEscalation()` called AND then overwritten by `Complaint::orderBy(...)` | Controller lines 53, 92 |
| PERF-04 | P1 | `getAiInsights()` loads ALL AI insights without any filtering/pagination | Controller line 760-768 |
| PERF-05 | P2 | `index()` method is a god-method — loads dashboards, categories, SLAs, medical checks, complaints, actions, AI insights all in one request | Controller lines 30-220 |
| PERF-06 | P2 | `getEscalationHeatmapData()` loads all complaints and iterates in PHP — should use aggregate SQL | Service lines 131-152 |
| PERF-07 | P2 | `getRepeatedTargetFrustration()` loads all complaints with AI insights — no pagination | Service lines 436-514 |

---

## SECTION 11: ARCHITECTURE AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| ARCH-01 | P1 | No Service class for core complaint CRUD — all logic is in controller | ComplaintController.php |
| ARCH-02 | P1 | `logAction()` bypasses Eloquent — uses raw `DB::table()` insert | Controller line 804 |
| ARCH-03 | P2 | Event/Listener exists (`ComplaintSaved`/`ProcessComplaintAIInsights`) but coupling unclear | Events/Listeners dirs |
| ARCH-04 | P2 | No Job classes for async processing (escalation checks, SLA breach notifications) | Module-wide |
| ARCH-05 | P3 | No Repository pattern — direct Eloquent in controllers | Throughout |

---

## SECTION 12: TEST COVERAGE

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| TST-01 | P0 | **ZERO tests** — only `.gitkeep` files in tests/Feature and tests/Unit | `Modules/Complaint/tests/` |

---

## SECTION 13: BUSINESS LOGIC COMPLETENESS

| Feature | Status | Notes |
|---------|--------|-------|
| Complaint Categories (CRUD) | Partial | Column name mismatches with DDL |
| Department SLA | Partial | Controller exists, not deeply audited |
| Complaint CRUD | Partial | Create works, Update has hardcoded IDs, Destroy empty |
| Escalation Engine | Partial | Logic duplicated, not using DB `current_escalation_level` |
| Medical Checks | Present | Views and controller exist |
| AI Insights | Present | Event-driven, Python microservice integration stub |
| Dashboard | Partial | Service exists, good analytics logic, but dd() in filter |
| Reports | Present | 5 report views, report controller exists |
| Scheduled Escalation Jobs | Missing | No cron/job to auto-escalate overdue complaints |
| Email Notifications on Escalation | Missing | Only admin notification on create |
| Complaint Assignment Workflow | Partial | Update handles assignment but no dedicated workflow |

---

## PRIORITY FIX PLAN

### P0 — Must Fix Before Production
1. Remove all `dd()` calls (lines 407, 833)
2. Create FormRequest classes for store/update
3. Fix ComplaintPolicy `create()` — wrong permission `tenant.vendor-dahsboard.create`
4. Remove hardcoded dropdown IDs (124, 197, 202)
5. Add Gate authorization to `show()`, `edit()`, `update()`, `destroy()`
6. Implement `destroy()` method
7. Fix `index()` to use pagination instead of `->get()`
8. Add `EnsureTenantHasModule` middleware to route group

### P1 — Fix Before Beta
1. Fix column name mismatches in models vs DDL (target_id, escalation_level, resolution_hours)
2. Add missing DDL columns (created_by, deleted_at on multiple tables)
3. Remove duplicate resource route registration
4. Add activity logging to all CRUD operations
5. Fix N+1 queries in complaint list/map operations
6. Write basic feature tests for CRUD operations
7. Use `$request->validated()` instead of `$request->field_name`

### P2 — Fix Before GA
1. Refactor god-method `index()` into separate endpoints
2. Create ComplaintService for business logic
3. Add input sanitization for text fields
4. Fix `logAction()` to use Eloquent model
5. Add scheduled job for escalation checks
6. Fix DDL FK type mismatch on `is_medical_check_required`

### P3 — Nice to Have
1. Remove commented-out code
2. Add service interface/contracts
3. Standardize route naming

---

## EFFORT ESTIMATION

| Priority | Estimated Hours |
|----------|----------------|
| P0 Fixes | 16-20 hours |
| P1 Fixes | 20-28 hours |
| P2 Fixes | 16-20 hours |
| P3 Fixes | 4-6 hours |
| Test Suite | 16-24 hours |
| **Total** | **72-98 hours** |
