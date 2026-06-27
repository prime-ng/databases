# Technical Audit — Complaint (CMP) — 2026-06-27
# Modes: B (FRD-Driven Gap Analysis) + C (Business Rule Enforcement)

| Field | Value |
|-------|-------|
| **Module** | Complaint |
| **Code** | CMP |
| **Prefix** | `cmp_` |
| **Audit Date** | 2026-06-27 |
| **Auditor Agent** | Technical Auditor |
| **Modes Run** | Mode B — FRD-Driven Gap Analysis + Mode C — Business Rule Enforcement |
| **FRD Reference** | `4-Requirement_Module_wise/0-FRD_Documents/Complaint/CMP_FRD_v1.md` |
| **Prior Audit** | Mode A (5-layer) run 2026-06-23 — see `3-Audit_Modules/V1_22Jun2026/Complaint/Complaint_Audit_2026-06-23.md` |
| **Module Knowledge** | `AI_Brain/module-knowledge/CMP_Complaint.md` |

---

## Executive Summary

The Complaint module (CMP) was audited against all 14 FRD requirements (REQ-CMP-001 to REQ-CMP-014) and all 24 business rules (BR-CMP-001 to BR-CMP-024). Of 14 requirements, 2 are fully compliant, 9 are partially implemented, and 3 are completely unimplemented. Of 24 business rules, only 5 are fully enforced — 9 are partially enforced and 10 are entirely missing. The most critical findings: `resolution_due_at` is never calculated on complaint creation (every ticket has no SLA deadline), no status-transition FSM exists (any status → any status), private notes are not filtered at the query layer (all staff can read them), the complaint reopening workflow does not exist, and no scheduled escalation job has been created. The module scores approximately 20% functional completion for business-critical paths.

---

## Mode B — FRD-Driven Gap Analysis

### B.1 Requirement Coverage Per REQ-ID

| REQ-ID | Feature | Priority | DDL | Screen/Code | Notification | Tests | Overall Status |
|--------|---------|---------|-----|------------|-------------|-------|---------------|
| REQ-CMP-001 | Category Management | P0 | ✅ `cmp_complaint_categories` | ✅ Full CRUD, Gate, FormRequest | N/A | ✅ `ComplaintCategoryTest.php` | **COMPLIANT** (minor gaps) |
| REQ-CMP-002 | Department SLA Config | P0 | ✅ `cmp_department_sla` | ✅ Full CRUD, Gate, FormRequest | N/A | ✅ `DepartmentSlaCrudTest.php` | **COMPLIANT** (minor gaps) |
| REQ-CMP-003 | Complaint Registration | P0 | ✅ `cmp_complaints` (with known FK bugs) | 🟡 `store()` exists but no Gate, no resolution_due_at, partial auto-populate | 🟡 Wrong role, cross-module class | 🟡 Schema/model tests only | **PARTIAL** |
| REQ-CMP-004 | Complaint Assignment | P0 | ✅ assignment columns exist | 🟡 `update()` handles assignment | ❌ No notification to assignee | ❌ No test | **PARTIAL** |
| REQ-CMP-005 | Resolution & Status Mgmt | P0 | ✅ status/resolution columns | 🟡 `update()` handles status changes | ❌ No resolution/escalation notification | ❌ No dedicated test | **PARTIAL** |
| REQ-CMP-006 | Action Timeline | P0 | ✅ `cmp_complaint_actions` | 🔴 `ComplaintActionController.store()` empty — manual notes broken | N/A | ❌ No test | **STUB** |
| REQ-CMP-007 | Medical Check Linkage | P1 | ✅ `cmp_medical_checks` (typo preserved) | ✅ Full CRUD, Gate, validation | N/A | ✅ `MedicalCheckCrudTest.php` | **COMPLIANT** (minor gap) |
| REQ-CMP-008 | AI Insight Engine | P1 | ✅ `cmp_ai_insights` | 🟡 Engine fires on save; `AiInsightController` is a complete stub | N/A | 🟡 `AiInsightCrudTest.php` exists | **PARTIAL** |
| REQ-CMP-009 | Analytics Dashboard | P1 | N/A (no new tables) | 🟡 Logic in `ComplaintController`; `ComplaintDashboardController` is stub | N/A | ❌ No test | **PARTIAL** |
| REQ-CMP-010 | Reporting Suite (5 reports) | P1 | N/A | 🟡 `ComplaintReportController` 538 lines; export status unknown; zero Gate | N/A | ❌ Only `requirement.md` in Reports/ | **PARTIAL** |
| REQ-CMP-011 | Portal Submission | P1 | N/A (uses cmp_complaints) | 🟡 `StudentPortalComplaintController` in StudentPortal module | ❌ No per-role masking at query level | 🟡 Partial (in StudentPortal) | **PARTIAL** |
| REQ-CMP-012 | Complaint Reopening | P1 | N/A | ❌ No `reopen()` method anywhere | ❌ No notification | ❌ No test | **NOT IMPLEMENTED** |
| REQ-CMP-013 | Scheduled Escalation | P1 | N/A | ❌ No Job or Artisan command | ❌ No escalation notification | ❌ No test | **NOT IMPLEMENTED** |
| REQ-CMP-014 | Feedback Collection | P2 | ❌ No `cmp_feedback` table | ❌ No controller/model/route | ❌ Not applicable | ❌ No test | **NOT IMPLEMENTED** (P2 — expected) |

---

### B.2 DDL Gap Detail

| REQ-ID | DDL Entity | Status | Gap |
|--------|-----------|--------|-----|
| REQ-CMP-001 | `cmp_complaint_categories` | ✅ Exists | — |
| REQ-CMP-002 | `cmp_department_sla` | ✅ Exists | — |
| REQ-CMP-003 | `cmp_complaints` | 🟡 Exists with defects | `fk_cmp_medical_check` type mismatch (SCH-CMP-002), broken index (SCH-CMP-001), no `resolution_due_at` default |
| REQ-CMP-004 | `cmp_complaints` (assignment cols) | ✅ Exists | — |
| REQ-CMP-005 | `cmp_complaints` (resolution cols) | ✅ Exists | — |
| REQ-CMP-006 | `cmp_complaint_actions` | ✅ Exists | No `updated_at`, no `deleted_at` — model must NOT use SoftDeletes (DDL design decision) |
| REQ-CMP-007 | `cmp_medical_checks` | ✅ Exists | DDL typo: `evidence_uploded` (preserved by design) |
| REQ-CMP-008 | `cmp_ai_insights` | ✅ Exists | — |
| REQ-CMP-009 | N/A | — | No new table required |
| REQ-CMP-010 | N/A | — | No new table required |
| REQ-CMP-011 | N/A | — | Writes to `cmp_complaints` |
| REQ-CMP-012 | N/A | — | Reopening uses existing columns on `cmp_complaints` |
| REQ-CMP-013 | N/A | — | Uses `current_escalation_level` column (exists on `cmp_complaints`) |
| REQ-CMP-014 | `cmp_feedback` | ❌ Missing | No DDL table for Feedback Collection |

---

### B.3 Code Gap Detail

| REQ-ID | Controller | Route | View | Status | Key Gap |
|--------|-----------|-------|------|--------|---------|
| REQ-CMP-001 | `ComplaintCategoryController` ✅ | ✅ Full CRUD | ✅ Exists | COMPLIANT | `authorize()` returns bare `true` |
| REQ-CMP-002 | `DepartmentSlaController` ✅ | ✅ Full CRUD | ✅ Exists | COMPLIANT | Same `authorize()` issue; `toggleStatus()` wired ✅ |
| REQ-CMP-003 | `ComplaintController.store()` 🟡 | ✅ Wired | ✅ Exists | PARTIAL | No Gate on `store()`; no `resolution_due_at`; partial auto-populate |
| REQ-CMP-004 | `ComplaintController.update()` 🟡 | ✅ Wired | ✅ Exists | PARTIAL | No notification to assignee on assignment |
| REQ-CMP-005 | `ComplaintController.update()` 🟡 | ✅ Wired | ✅ Exists | PARTIAL | No BR-CMP-012 enforcement; no FSM; no notifications |
| REQ-CMP-006 | `ComplaintActionController` 🔴 | ✅ Wired | 🔴 Stub view | STUB | `store()` empty `{}`; `update()` empty `{}` |
| REQ-CMP-007 | `MedicalCheckController` ✅ | ✅ Wired | ✅ Exists | COMPLIANT | BR-CMP-017 not gated |
| REQ-CMP-008 | `AiInsightController` 🔴 | ✅ Wired | 🔴 Stub views | PARTIAL | Controller stub; engine runs via event listener |
| REQ-CMP-009 | Dashboard in `ComplaintController` 🟡 | ✅ Wired | ✅ Exists | PARTIAL | `ComplaintDashboardController` stub; `filter()` no Gate |
| REQ-CMP-010 | `ComplaintReportController` 🟡 | ✅ Wired | ✅ Exists | PARTIAL | Zero Gate on all methods; BR-CMP-020 partial |
| REQ-CMP-011 | `StudentPortalComplaintController` 🟡 | ✅ In StudentPortal | ✅ Exists | PARTIAL | Anonymous masking not at query layer |
| REQ-CMP-012 | None | ❌ No route | ❌ None | NOT IMPL | No `reopen()` method in any controller |
| REQ-CMP-013 | None | ❌ No route | ❌ None | NOT IMPL | No Job class; no Artisan command |
| REQ-CMP-014 | None | ❌ No route | ❌ None | NOT IMPL | P2 — not yet started |

---

### B.4 Notification Gap Detail

| REQ-ID | Notification Required | Implementation | Status | Gap |
|--------|----------------------|----------------|--------|-----|
| REQ-CMP-003 | Admin notified on new complaint | ✅ `Notification::send($admins, new StudentPortalComplaintRegistered())` | 🟡 PARTIAL | Notifies `User::role('Super Admin')` not School Admin role; class from `App\Notifications` not module |
| REQ-CMP-004 | Assignee notified on assignment | ❌ No notification code in `update()` | ❌ MISSING | Assignment change logged in timeline but no notification sent |
| REQ-CMP-005 | Complainant notified on resolution | ❌ No notification code | ❌ MISSING | — |
| REQ-CMP-005 | Principal notified on escalation | ❌ No notification code | ❌ MISSING | — |
| REQ-CMP-012 | Assignee notified on reopen | ❌ Feature not implemented | ❌ MISSING | — |
| REQ-CMP-013 | Entity groups notified on escalation level change | ❌ No job exists | ❌ MISSING | — |

---

### B.5 Test Coverage Gap Detail

| REQ-ID | Feature | Test File | Status | Gap |
|--------|---------|-----------|--------|-----|
| REQ-CMP-001 | Category Management | `tests/Browser/Modules/Complaint/Category/ComplaintCategoryTest.php` | ✅ Exists | — |
| REQ-CMP-002 | Department SLA | `tests/Browser/Modules/Complaint/DepartmentSLA/DepartmentSlaCrudTest.php` | ✅ Exists | — |
| REQ-CMP-003 | Complaint Registration | `tests/Browser/Modules/Complaint/Complaint/ComplaintCrudTest.php` (7 methods) | 🟡 Schema/CRUD only | Ticket number format, SLA auto-calculation, AI trigger not tested |
| REQ-CMP-004 | Assignment | None | ❌ MISSING | — |
| REQ-CMP-005 | Resolution & Status | None | ❌ MISSING | — |
| REQ-CMP-006 | Action Timeline | None | ❌ MISSING | — |
| REQ-CMP-007 | Medical Check | `tests/Browser/Modules/Complaint/MedicalChecks/MedicalCheckCrudTest.php` | ✅ Exists | — |
| REQ-CMP-008 | AI Insight Engine | `tests/Browser/Modules/Complaint/AIInsights/AiInsightCrudTest.php` | 🟡 Exists | Engine scoring accuracy not tested |
| REQ-CMP-009 | Dashboard | None | ❌ MISSING | — |
| REQ-CMP-010 | Reports | `tests/Browser/Modules/Complaint/Reports/` — only `requirement.md` | ❌ MISSING | — |
| REQ-CMP-011 | Portal Submission | Partial in StudentPortal tests | 🟡 PARTIAL | — |
| REQ-CMP-012 | Reopening | None | ❌ MISSING | Feature not implemented |
| REQ-CMP-013 | Escalation Job | None | ❌ MISSING | Feature not implemented |
| REQ-CMP-014 | Feedback Collection | None | ❌ MISSING | P2 — expected |

---

## Mode C — Business Rule Enforcement Check (All 24 BRs)

| BR-ID | Rule Summary | Type | Enforcement Location | Status | Gap |
|-------|-------------|------|---------------------|--------|-----|
| BR-CMP-001 | Category name unique within parent | Validation | `ComplaintCategoryRequest.rules()` — `nameUniqueRule->where('parent_id', ...)` | ✅ **ENFORCED** | — |
| BR-CMP-002 | Escalation hours strictly ascending (L1–L5) | Validation | `ComplaintCategoryRequest` — `gt:l1 ... gt:l4` rules present | 🟡 **PARTIAL** | L1 not required `gt:default_expected_resolution_hours`; only L2+ are enforced relative to prior level |
| BR-CMP-003 | Cannot permanently delete category with children | Workflow | `ComplaintCategoryController.forceDelete()` — checks `where('parent_id', $id)->exists()` | ✅ **ENFORCED** | Applies to hard-delete only; soft-delete has no children check |
| BR-CMP-004 | Deactivate before delete | Workflow | `destroy()` auto-sets `is_active = false` before soft-delete | 🟡 **PARTIAL** | Does not ENFORCE prior deactivation as a prerequisite — auto-deactivates silently instead |
| BR-CMP-005 | Dept SLA escalation hours ascending | Validation | `DepartmentSlaRequest` — `gt:l1 ... gt:l4` rules | 🟡 **PARTIAL** | Same L1 gap: L1 not required `gt:dept_expected_resolution_hours` |
| BR-CMP-006 | Dept SLA overrides category SLA for resolution_due_at | Workflow | Dept SLA lookup exists in `edit()` form only — NOT in `store()` | ❌ **MISSING** | `resolution_due_at` is never calculated or stored during complaint creation (`Complaint::create()` call has no `resolution_due_at` field) |
| BR-CMP-007 | Unique ticket number CMP-YYYY-NNNNNN | Validation | `store()` — `lockForUpdate()` + collision loop | ✅ **ENFORCED** | — |
| BR-CMP-008 | Anonymous requires explicit name; no user link | Validation | Code sets `complainant_name = 'Anonymous'` as fallback; `complainant_user_id = null` for anonymous | 🟡 **PARTIAL** | Does not require the user to actively supply a real name for anonymous complaints — silently defaults to 'Anonymous' |
| BR-CMP-009 | Auto-populate severity/priority/medical from category | Workflow | Only `is_medical_check_required` auto-fetched from category; `severity_level_id` + `priority_score_id` read from `$request` | 🟡 **PARTIAL** | Staff can supply any severity/priority value — not restricted to category defaults |
| BR-CMP-010 | Auto-calculate resolution_due_at from SLA at registration | Workflow | `store()` does NOT include `resolution_due_at` in `Complaint::create()` | ❌ **MISSING** | Every complaint ticket is created without a resolution deadline. Visible in edit form only (display calculation, not persisted). |
| BR-CMP-011 | Log assignment in timeline | Workflow | `update()` calls `logAction('Assigned')` when `assigned_to_user_id` or `assigned_to_role_id` changes | ✅ **ENFORCED** | — |
| BR-CMP-012 | Resolution requires note + timestamp | Validation | `resolution_summary` and `actual_resolved_at` both validated as `nullable` — no conditional required rule | ❌ **MISSING** | Can mark a complaint as Resolved without providing a resolution note or resolution date |
| BR-CMP-013 | Log every status change in timeline | Workflow | `update()` calls `logAction('StatusChange')` when `status_id` changes | ✅ **ENFORCED** | Note field logs ID integers not human-readable labels (`"from 124 to 126"`) |
| BR-CMP-014 | Valid status transitions only (FSM) | Workflow | No FSM exists — `status_id` accepted as `nullable|integer` with no transition checks | ❌ **MISSING** | Any status can be set to any other status (e.g., Open → Resolved in one step, bypassing In-Progress) |
| BR-CMP-015 | Private notes restricted to Admin/Principal only | Permission | `is_private_note` stored correctly in `logAction()`; but `show()` loads complaint without filtering `complaintActions` relationship | ❌ **MISSING** | Private notes returned to all roles at query level. No role-based filter in `show()` or in the complaint actions query. Filtering (if any) is view-layer only — insufficient. |
| BR-CMP-016 | Timeline in chronological order | Workflow | `logAction()` inserts `created_at = now()` (correct); but uses `created_at` column, not the DDL's `action_timestamp` column | 🟡 **PARTIAL** | The `action_timestamp` DDL column exists for this purpose; current code uses `created_at`. If model timestamps are on, there is a mismatch between the DDL-intended column and the ORM column. |
| BR-CMP-017 | Medical check only for eligible complaints | Validation | `MedicalCheckController.store()` validates check data but does NOT verify `is_medical_check_required = true` on the linked complaint | ❌ **MISSING** | Medical check records can be created for any complaint regardless of category configuration |
| BR-CMP-018 | One AI insight per complaint; updateOrCreate | Validation | `ComplaintAIInsightEngine` uses `AiInsight::updateOrCreate(['complaint_id' => ...])` | ✅ **ENFORCED** | — |
| BR-CMP-019 | Sentiment 0–1; risk scores 0–100 | Calculation | Engine calculates sentiment as 0.0–1.0 float; escalation/safety risk as 0–100 int | ✅ **ENFORCED** | — |
| BR-CMP-020 | SLA report excludes Resolved/Closed/Rejected | Validation | `excludeRejectedAndClosed()` exists but only excludes 'Rejected' and 'Closed' | 🟡 **PARTIAL** | **Resolved complaints appear in the SLA Violation Report** — the method name and implementation omit 'Resolved' from exclusion |
| BR-CMP-021 | Anonymous complaint masking | Permission | `is_anonymous` flag stored; no query-layer filter in `show()` or `index()` | ❌ **MISSING** | Anonymous complainant name and contact visible to all authenticated roles in all screens |
| BR-CMP-022 | Reopen only from Resolved status | Validation | No `reopen()` method exists in any controller | ❌ **MISSING** | Feature not implemented |
| BR-CMP-023 | Reopen clears resolution fields + logs reason | Workflow | No `reopen()` method exists | ❌ **MISSING** | Feature not implemented |
| BR-CMP-024 | Escalation level auto-updated by scheduled process | Calculation | No Job class in `Modules/Complaint/app/Jobs/`; no Artisan command registered | ❌ **MISSING** | Escalation levels are never automatically updated. `current_escalation_level` column remains at its initial value forever. |

---

## BR Enforcement Summary

| Status | Count | BR-IDs |
|--------|-------|--------|
| ✅ Fully Enforced | 5 | BR-001, BR-007, BR-011, BR-018, BR-019 |
| 🟡 Partially Enforced | 9 | BR-002, BR-003, BR-004, BR-005, BR-008, BR-009, BR-013, BR-016, BR-020 |
| ❌ Missing / Not Implemented | 10 | BR-006, BR-010, BR-012, BR-014, BR-015, BR-017, BR-021, BR-022, BR-023, BR-024 |

**Enforcement Rate:** 5/24 fully compliant (21%) · 9/24 partial (37%) · 10/24 missing (42%)

---

## New Issue Codes Registered This Audit

> Verified no duplicates: all codes below start from max+1 in each series.
> Existing maxima before this audit: SCH-CMP-007 | BUG-CMP-018 | SEC-CMP-014 | PERF-CMP-008 | DEAD-CMP-006 | DEPLOY-CMP-02 | VAL-CMP: none

### Validation Issues (VAL-CMP-*)

| Code | Severity | Issue | Location |
|------|---------|-------|----------|
| VAL-CMP-001 | P1 | `ComplaintCategoryRequest`: `default_escalation_hours_l1` validated as `required|integer` only — not required to be `gt:default_expected_resolution_hours`. L1 can be less than expected resolution hours, violating BR-CMP-002. Same gap in `DepartmentSlaRequest` for `dept_escalation_hours_l1` vs `dept_expected_resolution_hours` (BR-CMP-005). | `ComplaintCategoryRequest.php:69`, `DepartmentSlaRequest.php:63` |
| VAL-CMP-002 | P2 | For anonymous complaints, `complainant_name` defaults to the string `'Anonymous'` when not provided — the system does not require the operator to supply a real name for anonymous complainants. BR-CMP-008 states "a complainant name must be provided". | `ComplaintController.php:235` |
| VAL-CMP-003 | P1 | `store()` and `update()` accept `severity_level_id` and `priority_score_id` directly from `$request` with no restriction to the values defined in the selected category. BR-CMP-009 states these must be auto-assigned from the category and not manually entered at creation. | `ComplaintController.php:260,360` |
| VAL-CMP-004 | P0 | No conditional validation enforces that `resolution_summary` and `actual_resolved_at` are required when `status_id` corresponds to 'Resolved'. Both fields are `nullable` in `update()` validation. A complaint can be marked Resolved with no summary and no resolution date, violating BR-CMP-012. | `ComplaintController.php:586,589` |
| VAL-CMP-005 | P0 | No status-transition FSM enforced anywhere in complaint update flow. Any `status_id` can be set to any other `status_id` without validation of permitted transitions. Violates BR-CMP-014 (e.g., can jump Open → Closed, or revert Resolved → Open without the formal reopen process). | `ComplaintController.php:582` |
| VAL-CMP-006 | P1 | `MedicalCheckController.store()` and `update()` do not verify that the linked complaint has `is_medical_check_required = true` before allowing medical check creation. Any complaint can receive a medical check record regardless of category configuration, violating BR-CMP-017. | `MedicalCheckController.php:68` |

### Bug Issues (BUG-CMP-*)

| Code | Severity | Issue | Location |
|------|---------|-------|----------|
| BUG-CMP-019 | P0 | `resolution_due_at` is never calculated or saved during complaint creation. `Complaint::create()` in `store()` has no `resolution_due_at` field. The edit-form display calculates a candidate value from `DepartmentSla` but does not persist it. Every ticket is created without a resolution deadline — SLA enforcement, violation reports, and escalation calculations all depend on this field. Violates BR-CMP-010. | `ComplaintController.php:339` |
| BUG-CMP-020 | P2 | `logAction()` inserts timeline entries using `'created_at' => now()`. The DDL table `cmp_complaint_actions` defines `action_timestamp` as the intended time column (not `created_at`). Partial violation of BR-CMP-016 — timeline uses the wrong time column. | `ComplaintController.php:1248,1257` |
| BUG-CMP-021 | P1 | `ComplaintReportController::getSlaViolationReport()` calls `excludeRejectedAndClosed()` which filters out only 'Rejected' and 'Closed' statuses. 'Resolved' complaints are not excluded, violating BR-CMP-020 ("only Open or In-Progress complaints"). Resolved tickets appear in the SLA Violation Report. | `ComplaintReportController.php:129,200` |
| BUG-CMP-022 | P0 | No `reopen()` method exists in any Complaint module controller. REQ-CMP-012 (Complaint Reopening) is entirely unimplemented. Both BR-CMP-022 (status check) and BR-CMP-023 (clear resolution fields + log reason) are missing. | No file — feature absent |
| BUG-CMP-023 | P0 | No scheduled escalation job exists (`Modules/Complaint/app/Jobs/` is empty). `current_escalation_level` column on `cmp_complaints` is never updated by the system. REQ-CMP-013 and BR-CMP-024 are entirely unimplemented. | No file — `Jobs/` directory empty |
| BUG-CMP-024 | P1 | Complaint creation notification uses `User::role('Super Admin')->get()` — sending to 'Super Admin' instead of 'School Admin'. FRD Section 6.1 Step 1 specifies "notification sent to School Admin". Additionally, the notification class `StudentPortalComplaintRegistered` is imported from `App\Notifications\` (cross-layer) not from within the Complaint module. | `ComplaintController.php:384` |
| BUG-CMP-025 | P1 | `ComplaintController.update()` logs the assignment action in the timeline but sends NO notification to the assigned user or role. BR-CMP-011 includes the assignment being "recorded in the complaint timeline" (done) but REQ-CMP-004 AC4 requires "the assigned user or role receives a notification" (not done). | `ComplaintController.php:692` |

### Security Issues (SEC-CMP-*)

| Code | Severity | Issue | Location |
|------|---------|-------|----------|
| SEC-CMP-015 | P0 | Private notes (`is_private_note = true`) are stored correctly in `cmp_complaint_actions` via `logAction()`, but `ComplaintController.show()` does not filter complaint actions by role before loading them. All roles who can view a complaint receive private notes in the response. BR-CMP-015 states private notes must be restricted to School Admin and Principal — this enforcement must happen at the **query layer**, not view layer only. | `ComplaintController.php:442` |
| SEC-CMP-016 | P1 | Anonymous complaint masking (BR-CMP-021) is not enforced at the data retrieval layer. `ComplaintController.show()` and `index()` return `complainant_name` and `complainant_contact` for all complaints regardless of `is_anonymous` flag or the requesting user's role. Masking (if any) relies entirely on Blade templates — insufficient per FRD Section 9.2 ("must enforce this at the data retrieval level, not just the display layer"). | `ComplaintController.php:442,35` |

---

## P0 Findings (Fix Before Any User Testing)

| Code | Issue | Location |
|------|-------|----------|
| VAL-CMP-004 | Can mark Resolved without resolution note or timestamp | `ComplaintController.php:586,589` |
| VAL-CMP-005 | No status FSM — any status → any status allowed | `ComplaintController.php:582` |
| BUG-CMP-019 | `resolution_due_at` never calculated or saved on complaint creation | `ComplaintController.php:339` |
| BUG-CMP-022 | Complaint Reopening (REQ-CMP-012) entirely unimplemented | Feature absent |
| BUG-CMP-023 | Scheduled Escalation Job (REQ-CMP-013) entirely unimplemented | Jobs/ directory empty |
| SEC-CMP-015 | Private notes returned to all roles — no query-layer filter | `ComplaintController.php:442` |
| SEC-CMP-007 *(prior)* | `store()` has no Gate::authorize — any authenticated user creates complaints | `ComplaintController.php:211` |
| DEAD-CMP-001 *(prior)* | `AiInsightController` — all CRUD methods are empty stubs on live routes | `AiInsightController.php` |

---

## P1 Findings (Fix Before Beta Testing)

| Code | Issue | Location |
|------|-------|----------|
| VAL-CMP-001 | L1 escalation hours not enforced > expected resolution hours | `ComplaintCategoryRequest.php:69`, `DepartmentSlaRequest.php:63` |
| VAL-CMP-003 | Severity/priority accepted from request — not auto-locked from category | `ComplaintController.php:260,360` |
| VAL-CMP-006 | Medical check creation not gated on `is_medical_check_required` | `MedicalCheckController.php:68` |
| BUG-CMP-021 | SLA Violation Report includes Resolved complaints (should exclude) | `ComplaintReportController.php:200` |
| BUG-CMP-024 | Complaint creation notification sent to 'Super Admin' not 'School Admin'; cross-module notification class | `ComplaintController.php:384` |
| BUG-CMP-025 | No notification sent to assignee on complaint assignment | `ComplaintController.php:692` |
| SEC-CMP-016 | Anonymous complainant name/contact visible to all roles — no query-layer masking | `ComplaintController.php:442,35` |
| SEC-CMP-006 *(prior)* | `ComplaintReportController` — zero Gate on all methods | `ComplaintReportController.php` |

---

## P2 Findings (Fix Before General Availability)

| Code | Issue | Location |
|------|-------|----------|
| VAL-CMP-002 | Anonymous complaint allows 'Anonymous' as default name — no explicit name required | `ComplaintController.php:235` |
| BUG-CMP-020 | `logAction()` uses `created_at` column, not `action_timestamp` (DDL column) | `ComplaintController.php:1257` |
| `ComplaintCategoryRequest/DepartmentSlaRequest` | `authorize() { return true; }` — no actual authorization check | Both request files |

---

## FRD Gap Summary

| REQ-ID | Feature | DDL | Code | Tests | Notification | Overall |
|--------|---------|-----|------|-------|-------------|---------|
| REQ-CMP-001 | Category Management | ✅ | ✅ | ✅ | N/A | **COMPLIANT** |
| REQ-CMP-002 | Department SLA | ✅ | ✅ | ✅ | N/A | **COMPLIANT** |
| REQ-CMP-003 | Complaint Registration | 🟡 | 🟡 | 🟡 | 🟡 | **PARTIAL** |
| REQ-CMP-004 | Assignment | ✅ | 🟡 | ❌ | ❌ | **PARTIAL** |
| REQ-CMP-005 | Resolution & Status | ✅ | 🟡 | ❌ | ❌ | **PARTIAL** |
| REQ-CMP-006 | Action Timeline | ✅ | 🔴 | ❌ | N/A | **STUB** |
| REQ-CMP-007 | Medical Check | ✅ | 🟡 | ✅ | N/A | **MOSTLY COMPLIANT** |
| REQ-CMP-008 | AI Insight Engine | ✅ | 🟡 | 🟡 | N/A | **PARTIAL** |
| REQ-CMP-009 | Analytics Dashboard | ✅ | 🟡 | ❌ | N/A | **PARTIAL** |
| REQ-CMP-010 | Reporting Suite | ✅ | 🟡 | ❌ | N/A | **PARTIAL** |
| REQ-CMP-011 | Portal Submission | ✅ | 🟡 | 🟡 | ❌ | **PARTIAL** |
| REQ-CMP-012 | Complaint Reopening | ✅ | ❌ | ❌ | ❌ | **NOT IMPLEMENTED** |
| REQ-CMP-013 | Escalation Tracking | ✅ | ❌ | ❌ | ❌ | **NOT IMPLEMENTED** |
| REQ-CMP-014 | Feedback Collection | ❌ | ❌ | ❌ | ❌ | **NOT IMPL (P2)** |

---

## Business Rule Enforcement Summary

| BR-ID | Summary | Status |
|-------|---------|--------|
| BR-CMP-001 | Category name unique within parent | ✅ |
| BR-CMP-002 | Escalation hours ascending | 🟡 L1 not constrained > expected hours |
| BR-CMP-003 | Cannot force-delete category with children | ✅ (hard-delete only) |
| BR-CMP-004 | Deactivate before delete | 🟡 Auto-deactivated, not enforced as prerequisite |
| BR-CMP-005 | Dept SLA hours ascending | 🟡 Same gap as BR-002 |
| BR-CMP-006 | Dept SLA overrides category SLA | ❌ resolution_due_at never set |
| BR-CMP-007 | Unique ticket number format | ✅ |
| BR-CMP-008 | Anonymous complainant name required | 🟡 Defaults to 'Anonymous' not required |
| BR-CMP-009 | Auto-populate severity/priority from category | 🟡 Medical check only; severity/priority from request |
| BR-CMP-010 | Auto-calculate resolution_due_at | ❌ Not set on creation |
| BR-CMP-011 | Log assignment in timeline | ✅ |
| BR-CMP-012 | Resolution requires note + timestamp | ❌ Both nullable |
| BR-CMP-013 | Log every status change | ✅ (IDs not labels) |
| BR-CMP-014 | Status transition FSM | ❌ No FSM |
| BR-CMP-015 | Private notes — Admin/Principal only | ❌ No query-layer filter |
| BR-CMP-016 | Timeline chronological order | 🟡 Uses wrong column (created_at vs action_timestamp) |
| BR-CMP-017 | Medical check only if category requires it | ❌ Not checked |
| BR-CMP-018 | One AI insight per complaint (updateOrCreate) | ✅ |
| BR-CMP-019 | Score ranges 0–1 and 0–100 | ✅ |
| BR-CMP-020 | SLA report excludes Resolved/Closed/Rejected | 🟡 Excludes Rejected/Closed only |
| BR-CMP-021 | Anonymous masking in non-admin views | ❌ No query filter |
| BR-CMP-022 | Reopen only from Resolved | ❌ Not implemented |
| BR-CMP-023 | Reopen clears resolution fields + logs reason | ❌ Not implemented |
| BR-CMP-024 | Escalation level auto-updated by schedule | ❌ No job exists |

---

## Recommended Fix Priority

### Sprint 1 — Critical Business Logic (P0 BRs)
1. **BUG-CMP-019** — Calculate and store `resolution_due_at` in `store()` from DeptSLA/category (fixes BR-CMP-010)
2. **VAL-CMP-004** — Add conditional validation: if `status_id` = Resolved, require `resolution_summary` and `actual_resolved_at` (fixes BR-CMP-012)
3. **VAL-CMP-005** — Implement status transition FSM in `update()` (fixes BR-CMP-014)
4. **SEC-CMP-015** — Add query-layer private note filter in `show()` based on user role (fixes BR-CMP-015)
5. **BUG-CMP-022** — Implement `reopen()` method with BR-CMP-022/023 enforcement (fixes REQ-CMP-012)
6. **BUG-CMP-023** — Create `CheckComplaintEscalations` job + register in console kernel (fixes REQ-CMP-013, BR-CMP-024)

### Sprint 2 — Compliance & Validation (P1)
7. **VAL-CMP-001** — Add `gt:default_expected_resolution_hours` rule for L1 (fixes BR-CMP-002/005 gap)
8. **VAL-CMP-003** — Lock `severity_level_id`/`priority_score_id` to category values in `store()` (fixes BR-CMP-009)
9. **VAL-CMP-006** — Gate medical check creation on `complaint->is_medical_check_required` (fixes BR-CMP-017)
10. **BUG-CMP-021** — Add 'Resolved' to exclusion list in `excludeRejectedAndClosed()` (fixes BR-CMP-020)
11. **BUG-CMP-025** — Add notification to assignee in `update()` on assignment change (fixes REQ-CMP-004 AC4)
12. **SEC-CMP-016** — Add query-layer anonymous masking to `show()` and `index()` based on role (fixes BR-CMP-021)
13. **Implement `ComplaintActionController.store()`** — manual note addition is currently impossible (fixes REQ-CMP-006)

### Sprint 3 — Security & Cleanup (P2)
14. **SEC-CMP-007** *(prior)* — Add `Gate::authorize('tenant.complaint.create')` to `store()` method
15. **BUG-CMP-024** — Fix notification role ('Super Admin' → 'School Admin'), move class into module
16. **BUG-CMP-020** — Use `action_timestamp` column (not `created_at`) in `logAction()`
17. **`authorize()`** — Replace `return true` in both FormRequests with actual gate checks

---

## Deliverables

- [x] **A. Audit Report** — this file: `6-Dev_Status_Analysis/Deep_Analysis/2026-06-27/Complaint_Technical_Audit_2026-06-27.md`
- [ ] **B. Update `AI_Brain/lessons/known-issues.md`** — append new codes: VAL-CMP-001 through 006, BUG-CMP-019 through 025, SEC-CMP-015 through 016
- [ ] **C. Update `AI_Brain/state/progress.md`** — Complaint completion: ~20% (unchanged from 2026-06-23; Mode B confirms no new features completed)
- [ ] **D. Update `AI_Brain/module-knowledge/CMP_Complaint.md`** — append new findings from this audit
- [ ] **E. Next Steps** — see offer below

---

*Audit produced by Technical Auditor agent — 2026-06-27*
*FRD reference: CMP_FRD_v1.md (2026-06-27) | Prior audit: Complaint_Audit_2026-06-23.md*
