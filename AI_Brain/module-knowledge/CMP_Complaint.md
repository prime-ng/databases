# Module Knowledge: Complaint (CMP)
# Last Updated: 2026-06-27
# Completion Status: ~40% (sourced from V2 requirement doc)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `cmp_*` |
| Database | `tenant_db` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Complaint_DDL_v2.sql` — 6 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/CMP_Complaint_Requirement.md` |
| FRD | `4-Requirement_Module_wise/0-FRD_Documents/Complaint/CMP_FRD_v1.md` — generated 2026-06-27 |
| Routes | `Modules/Complaint/routes/web.php` — ~220 lines, ~63 declared routes |
| Controllers | 9 (ComplaintCategory ✅, ComplaintReport ✅, DepartmentSla 🟡, MedicalCheck ✅, Complaint 🟡, AiInsight ❌, ComplaintAction ❌, ComplaintDashboard ❌, DocumentRequest ?) |
| Models | 6 (Complaint, ComplaintCategory, ComplaintAction, DepartmentSla, MedicalCheck, AiInsight) |
| Services | 2 (ComplaintAIInsightEngine ✅, ComplaintDashboardService ✅) |
| FormRequests | 2 (exact classes unknown — per modules-map count; V2 doc says zero for core complaint) |
| Policies | 7 (ComplaintPolicy has P0 bug — wrong gate string) |
| Views | 36 blade files |
| Jobs | 0 (scheduled escalation job not created) |
| Module-level Tests | 0 (`.gitkeep` only in `Modules/Complaint/tests/`) |
| Browser Tests | Partial — see test coverage section below |
| Gap Analysis Score | 4.0/10 (as of 2026-03-22 deep gap analysis) |

---

## DDL Tables (6 total)

| Table | Purpose | Key Notes |
|-------|---------|-----------|
| `cmp_complaint_categories` | Hierarchical complaint types with 5-level SLA | Missing `deleted_at` and `created_by` in DDL — must add via migration |
| `cmp_department_sla` | Target-specific SLA overrides | Missing `deleted_at` and `created_by` in DDL — must add via migration |
| `cmp_complaints` | Core complaint tickets | Has `deleted_at` ✅; DDL bug: `idx_cmp_status(status)` — column should be `status_id`; invalid FK `fk_cmp_medical_check` (TINYINT → INT) must be removed |
| `cmp_complaint_actions` | Audit timeline entries per complaint | Uses `action_timestamp` (NOT `created_at`); NO `updated_at`, `deleted_at`, `is_active`, `created_by` in DDL — model must not use SoftDeletes or timestamps |
| `cmp_medical_checks` | Physical check records for welfare complaints | DDL typo: `evidence_uploded` (not `uploaded`); `result VARCHAR(20)` (not an INT FK despite constraint name); NO `updated_at`, `deleted_at`, `is_active` in DDL |
| `cmp_ai_insights` | AI risk scores per complaint (1:1) | UNIQUE on `complaint_id`; NO `deleted_at`, `is_active`, `created_by` in DDL |

---

## Known Gaps & Open Issues

### P0 — Block Production Deployment (8 critical issues from 2026-03-22 analysis)

| ID | Location | Issue |
|----|----------|-------|
| CT-03 | ComplaintController.php:407 | `dd($e->getMessage())` in catch block — exposes stack trace in production |
| CT-04 | ComplaintController.php:833 | `dd('FILTER HIT', ...)` in `filter()` — AJAX dashboard always crashes |
| CT-05 | ComplaintController.php:357 | `status_id = 124` hardcoded — will fail if dropdown IDs change |
| CT-06 | ComplaintController.php:560 | `action_type_id = 197` hardcoded |
| CT-07 | ComplaintController.php:575 | `action_type_id = 202` hardcoded |
| PL-01 | ComplaintPolicy.php:31 | `authorize()` checks `tenant.vendor-dahsboard.create` (wrong module + typo) instead of `tenant.complaint.create` |
| CT-12 | ComplaintController.php:591 | `destroy()` method is empty — no soft-delete implemented |
| FR-01 | Requests/ | Zero FormRequest classes for core complaint CRUD (`StoreComplaintRequest`, `UpdateComplaintRequest` not created) |

### P1 — Fix Before Beta Testing (schema + controller gaps)

| Issue | Detail |
|-------|--------|
| Schema column name mismatches | Laravel migrations use `expected_resolution_hours` / `escalation_hours_l1..l5`; DDL canonical names are `default_expected_resolution_hours` / `default_escalation_hours_l1..l5` |
| `target_id` vs `target_selected_id` | Model uses `target_id`; DDL uses `target_selected_id` — breaks all target queries |
| `escalation_level` vs `current_escalation_level` | Same mismatch on `cmp_complaints` |
| `deleted_at` missing from DDL | `cmp_complaint_categories` and `cmp_department_sla` have SoftDeletes in model but no `deleted_at` column in DDL |
| AI insight label IDs hardcoded | Sentiment label IDs 147–150 hardcoded in `ComplaintAIInsightEngine.php` — must resolve by key |
| `AiInsightController` stub | All 5 AI Insights routes return wrong views |
| `ComplaintActionController` stub | All 7 action timeline routes return wrong views |
| `ComplaintDashboardController` stub | Dashboard controller not implemented (logic lives in `ComplaintController::index()` — 220-line god method) |
| `DepartmentSlaController::toggleStatus()` missing | Route declared, method does not exist |
| Missing trash/restore/forceDelete on complaints | 3 routes declared in web.php but controller methods missing |
| `EnsureTenantHasModule` middleware missing | Not applied to the complaint route group |

### P2 — Fix Before General Availability

| Issue | Detail |
|-------|--------|
| N+1 queries in `index()` | `map()` loop calls `DB::table()` per row; escalation heatmap has N+1 |
| Complaint list not paginated | `->get()` on `cmp_complaints` — will timeout at scale |
| Escalation calculation duplicated | Same logic in `ComplaintController` and `ComplaintDashboardService` — needs `EscalationService` |
| AI listener synchronous | `ProcessComplaintAIInsights` should implement `ShouldQueue` |
| Scheduled escalation job missing | No `CheckComplaintEscalations` job/command exists |
| `logAction()` uses raw DB::table() | Should use `ComplaintAction::create([...])` |
| `manage()` gate wrong prefix | Uses `prime.complaint.manage` instead of `tenant.complaint.manage` |

### Not Started
- Complaint Reopening Workflow (REQ-CMP-012) — no implementation at all
- Scheduled Escalation (REQ-CMP-013) — no Job class
- Feedback Collection (REQ-CMP-014) — no model, controller, view, or DB table

---

## FRD Summary

| Item | Value |
|------|-------|
| FRD File | `CMP_FRD_v1.md` |
| Generated | 2026-06-27 |
| Total REQ- entries | 14 |
| Total BR- entries | 24 |
| Total Workflows | 3 |
| Total Reports | 5 |
| Total Enhancements | 13 |
| P0 Requirements | 6 (REQ-CMP-001 to REQ-CMP-006) |
| P1 Requirements | 7 (REQ-CMP-007 to REQ-CMP-013) |
| P2 Requirements | 1 (REQ-CMP-014 — Feedback Collection) |

---

## Design Decisions Made

| Decision | Detail |
|----------|--------|
| Ticket number format | `CMP-YYYY-NNNNNN` (6-digit zero-padded serial, resets each year, per-tenant unique, generated with `lockForUpdate()` + collision check) |
| Severity/priority auto-population | Not entered by user — auto-fetched from `cmp_complaint_categories` at registration time |
| Resolution due date calculation | System-calculated at registration from Department SLA (if match) falling back to category default; not manually editable at creation |
| AI engine type | Rule-based (`ComplaintAIInsightEngine.php` — `rules-v1`); Python ML microservice for category prediction is a future enhancement (ENH-CMP-012) |
| 1:1 AI insight per complaint | `cmp_ai_insights.complaint_id` has UNIQUE constraint; `updateOrCreate` used to prevent duplicates |
| Anonymous complaint masking | `is_anonymous=true` → complainant identity masked at view layer for non-admin/non-principal users (BR-CMP-021) |
| Private notes | `is_private_note=true` on `cmp_complaint_actions` → visible only to Admin + Principal; must be filtered at query level, not just view |
| `action_timestamp` column | `cmp_complaint_actions` uses `action_timestamp` as the time column — NOT `created_at`; model must have `public $timestamps = false` |
| `evidence_uploded` typo | DDL column name preserves the typo (missing 'a'); model `$fillable` and views must use the same spelling |

---

## Cross-Module Dependencies

| Dependency | Integration Point |
|------------|-------------------|
| SchoolSetup (`sch_departments`, `sch_designations`, `sch_roles`, `sch_entity_groups`, `sch_vehicles`) | DepartmentSla target entities; escalation entity groups |
| GlobalMaster (`sys_dropdown_table`) | All status/type/severity/priority/action_type/sentiment label lookups (currently some hardcoded — P0) |
| Auth / Users (`sys_users`) | Complainant, assignee, resolver, performed_by |
| Transport (`tpt_vendor`) | DepartmentSla `target_vendor_id` FK |
| StudentPortal (`StudentPortalComplaintController`) | Student/parent self-service complaint submission writes to `cmp_complaints` |
| Notification module | Creation notification to Admin; assignment notification to assigned user; escalation notifications to entity groups |
| Spatie MediaLibrary (`sys_media`) | `complaint_img` (on complaints) and `medical_img` (on medical checks) — polymorphic media |

---

## Test Coverage

| Area | Coverage | Location |
|------|----------|----------|
| Category CRUD | ✅ Browser tests | `tests/Browser/Modules/Complaint/Category/ComplaintCategoryTest.php` |
| Department SLA CRUD | ✅ Browser tests | `tests/Browser/Modules/Complaint/DepartmentSLA/DepartmentSlaCrudTest.php` |
| Core Complaint CRUD | 🟡 Partial browser | `tests/Browser/Modules/Complaint/Complaint/ComplaintCrudTest.php` (schema + model only) |
| Medical Checks | ✅ Most comprehensive | `tests/Browser/Modules/Complaint/MedicalChecks/MedicalCheckCrudTest.php` |
| AI Insights | ❌ Zero | `tests/Browser/Modules/Complaint/AIInsights/` — requirement.md only, no test script |
| Action Timeline | ❌ Zero | Not started |
| Reports (5 types) | ❌ Zero | Not started |
| Dashboard + AJAX filter | ❌ Zero | Not started |
| Module-level Feature/Unit tests | ❌ Zero | `Modules/Complaint/tests/` has only `.gitkeep` |

---

## Mode B+C Audit Findings (2026-06-27)

> Full report: `6-Dev_Gap_Analysis_Status/Deep_Analysis/2026-06-27/Complaint_Technical_Audit_2026-06-27.md`
> BR enforcement: 5/24 fully compliant · 9/24 partial · 10/24 missing

### Key Discoveries (not in prior module knowledge)

| Finding | Detail |
|---------|--------|
| `resolution_due_at` never saved (BUG-CMP-019 P0) | `store()` creates complaint with no SLA deadline. SLA lookup exists in `edit()` form display only — display-only, not persisted. |
| No status FSM (VAL-CMP-005 P0) | Any status can be set to any other status in `update()`. No transition guard. |
| Resolution requires note/timestamp (VAL-CMP-004 P0) | Both `resolution_summary` and `actual_resolved_at` are nullable — can mark Resolved with no resolution data. |
| Private notes not query-filtered (SEC-CMP-015 P0) | `show()` loads complaint without filtering `is_private_note` by role. All staff see private notes. |
| `ComplaintActionController.store()` empty (REQ-CMP-006 STUB) | Manual note addition is completely broken — the form exists but `store()` returns nothing and saves nothing. |
| Complaint reopening missing (BUG-CMP-022 P0) | No `reopen()` method in any controller. REQ-CMP-012 not implemented at all. |
| No escalation job (BUG-CMP-023 P0) | `Jobs/` directory empty. `current_escalation_level` never auto-updated. REQ-CMP-013 not implemented. |
| Notification wrong role (BUG-CMP-024 P1) | Creation notification goes to `User::role('Super Admin')` not School Admin. Class from `App\Notifications\` not module-level. |
| SLA report includes Resolved (BUG-CMP-021 P1) | `excludeRejectedAndClosed()` misses 'Resolved' — violates BR-CMP-020. |
| Anonymous masking not at query layer (SEC-CMP-016 P1) | `complainant_name`/`complainant_contact` returned to all roles regardless of `is_anonymous` flag. |
| Medical check not gated on flag (VAL-CMP-006 P1) | `MedicalCheckController.store()` doesn't verify `is_medical_check_required = true` on complaint. |
| `logAction()` uses `created_at` not `action_timestamp` (BUG-CMP-020 P2) | DDL column is `action_timestamp`; code inserts `created_at`. Timeline ordering may be incorrect. |
| L1 escalation hours not constrained (VAL-CMP-001 P1) | L1 hours not enforced `gt:expected_resolution_hours` in either FormRequest. |

### BR Enforcement Status (Mode C result)

| Status | BR IDs |
|--------|--------|
| ✅ Fully Enforced (5) | BR-001, BR-007, BR-011, BR-018, BR-019 |
| 🟡 Partially Enforced (9) | BR-002, BR-003, BR-004, BR-005, BR-008, BR-009, BR-013, BR-016, BR-020 |
| ❌ Missing (10) | BR-006, BR-010, BR-012, BR-014, BR-015, BR-017, BR-021, BR-022, BR-023, BR-024 |

### What Works (confirmed functional)

- ✅ Ticket number generation (BR-CMP-007): `lockForUpdate()` + collision loop working
- ✅ `is_medical_check_required` auto-populated from category on complaint creation
- ✅ Assignment change logged in timeline (BR-CMP-011)
- ✅ Status change logged in timeline (BR-CMP-013)
- ✅ `ComplaintAIInsightEngine` uses `updateOrCreate` (BR-CMP-018)
- ✅ AI scores in correct range: sentiment 0–1, risk scores 0–100 (BR-CMP-019)
- ✅ Category name unique-within-parent enforced (BR-CMP-001)
- ✅ `forceDelete()` blocks deletion of categories with children (BR-CMP-003)
- ✅ `destroy()` is no longer empty (fixed since prior audit) — soft-delete works
- ✅ `ComplaintCategoryController` and `DepartmentSlaController` fully implemented

## Pending Next Steps

- [ ] **Sprint 1 (P0)** → `act as Developer` — Fix BUG-CMP-019 (`resolution_due_at` in store), VAL-CMP-004 (resolution gate), VAL-CMP-005 (status FSM), SEC-CMP-015 (private note query filter), BUG-CMP-022 (reopen method), BUG-CMP-023 (escalation job)
- [ ] **Sprint 2 (P1)** → `act as Developer` — Fix VAL-CMP-001, VAL-CMP-003, VAL-CMP-006, BUG-CMP-021, BUG-CMP-024/025, SEC-CMP-016; implement `ComplaintActionController.store()`
- [ ] **Sprint 3 (Security)** → `act as Developer` — Fix SEC-CMP-007 (Gate on store), FormRequest authorize() real checks, BUG-CMP-020 (action_timestamp column)
- [ ] DDL Gap Analysis → `act as DB Architect` — compare `CMP_FRD_v1.md` Section 10.1 vs `Complaint_DDL_v2.sql`
- [ ] Fix remaining P0 issues from prior audit → `act as Developer` — 8 critical blockers (CT-03 dd(), CT-04 dd(), CT-05/06/07 hardcoded IDs, PL-01 wrong policy gate, CT-12 empty destroy—now fixed, FR-01 missing FormRequests)
- [ ] Schema migration reconciliation → reconcile 15 column name mismatches between migrations and canonical DDL

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | FRD generated (`CMP_FRD_v1.md`) — 14 REQ, 24 BR, 5 reports, 13 enhancements |
| 2026-06-27 | Business Analyst | Module knowledge seeded from `CMP_Complaint_Requirement.md` (V2) + `Complaint_DDL_v2.sql` + live code inspection |
| 2026-06-27 | Technical Auditor | Mode B (FRD gap) + Mode C (BR enforcement) against `CMP_FRD_v1.md`. 15 new issue codes registered (VAL-CMP-001–006, BUG-CMP-019–025, SEC-CMP-015–016). Report: `Deep_Analysis/2026-06-27/Complaint_Technical_Audit_2026-06-27.md` |
