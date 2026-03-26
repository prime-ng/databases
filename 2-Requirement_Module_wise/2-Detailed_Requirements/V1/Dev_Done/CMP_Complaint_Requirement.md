# Complaint Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** CMP | **Module Path:** `Modules/Complaint`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `cmp_*` | **Processing Mode:** FULL
**RBS Reference:** Module D — Front Office & Communication (D3 — Complaint & Feedback Management)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The Complaint module provides a structured, SLA-driven grievance management system for Indian K-12 schools operating on the Prime-AI platform. It enables students, parents, staff, and administrators to register, track, escalate, and resolve complaints through a transparent lifecycle—with an embedded AI Insight Engine that performs rule-based sentiment analysis, safety-risk scoring, and escalation-risk prediction on every complaint.

### 1.2 Scope

This module covers:
- Hierarchical complaint category management with per-category SLA timelines (5-level escalation ladder)
- Department-specific SLA policies mapping complaint categories to responsible parties
- Core complaint registration, assignment, resolution, and audit trail
- Medical check linkage for physical-welfare complaints (substance/fitness checks)
- AI Insight Engine: sentiment scoring, escalation-risk score (0–100), safety-risk score (0–100), predicted category
- Analytics dashboard: open tickets, SLA breaches, category pie, escalation heatmap, repeated-target frustration report
- Reporting: summary-status, SLA violation, Pareto, hotspot, sentiment bubble chart
- Student portal integration via `StudentPortalComplaintController`

Out of scope for this version: feedback collection (F.D3.2), push notifications via SMS/email to complainant, real-ML AI (current engine is rule-based), mobile API endpoints for complaints.

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.D3.*) | 2 (F.D3.1, F.D3.2) |
| RBS Tasks | 4 (T.D3.1.1, T.D3.1.2, T.D3.2.1, T.D3.2.2) |
| RBS Sub-tasks | 6 (ST.D3.1.1.1–ST.D3.2.1.2) |
| DB Tables (cmp_*) | 6 |
| Named Routes | ~38 |
| Blade Views | 21 (+ 2 layout components + 1 module root index) |
| Controllers | 8 |
| Models | 6 |
| Services | 2 |
| Events | 1 |
| Listeners | 1 |
| Policies | 7 |
| FormRequests | 0 |
| Browser Tests | 4 (ComplaintCategoryTest, ComplaintCrudTest, DepartmentSlaCrudTest, MedicalCheckCrudTest) |

### 1.4 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ✅ Complete | 6 migrations — all tables created |
| Models (6) | ✅ Complete | Relationships, casts, scopes all defined |
| ComplaintCategoryController | ✅ Complete | Full CRUD + trash/restore/forceDelete/toggleStatus |
| DepartmentSlaController | ✅ Complete | Full CRUD + trash/restore/forceDelete |
| MedicalCheckController | ✅ Complete | Full CRUD + media upload + trash lifecycle |
| ComplaintController (core) | 🟡 Partial | store has `dd()` on exception, filter has `dd()`, hardcoded status_id=124, partial action-type resolution, `destroy()` is empty stub |
| ComplaintActionController | ❌ Stub | All methods return generic views — no real logic |
| AiInsightController | ❌ Stub | All methods return generic views — no real logic |
| ComplaintDashboardController | ❌ Stub | All methods return generic views — no real logic |
| ComplaintReportController | ✅ Complete | Full report suite: summary, SLA violation, Pareto, hotspot, AI risk/sentiment |
| ComplaintAIInsightEngine | ✅ Complete | Rule-based sentiment + escalation risk + safety risk + category prediction |
| ComplaintDashboardService | ✅ Complete | Dashboard KPIs, heatmap, sentiment trend, frustration report, donut charts |
| Event/Listener (AI pipeline) | ✅ Complete | ComplaintSaved → ProcessComplaintAIInsights (synchronous, not queued) |
| Policies (7) | ✅ Complete | All resource policies defined |
| FormRequests | ❌ None | Zero FormRequest classes — all validation inline |
| Views (Complaint CRUD) | ✅ Complete | create/edit/show/index/trash for each resource |
| Views (Reports) | ✅ Complete | 5 report views + index |
| Views (AI Insights) | 🟡 Partial | index view exists; no show/edit views |
| Browser Tests | 🟡 Partial | 4 tests exist; AIInsights has only requirement.md, no test file |

**Overall Implementation: ~40%** (schema + models + supporting features complete; core complaint management has significant code-quality and completeness gaps)

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

Indian schools handle a wide variety of grievances: parents complaining about teacher conduct, students reporting bullying, transport complaints about rash driving, hostel issues, infrastructure failures, and welfare concerns. Without a structured system, these are handled informally, often lost or mishandled with no accountability trail.

The Complaint module provides:
1. **Structured registration** — every complaint gets a unique ticket number (format: `CMP-YYYY-000001`), is classified under a category/subcategory, assigned a severity level and priority score, and tied to a specific target (person, department, vehicle, or vendor).
2. **SLA enforcement** — each category carries an expected resolution time and five escalation thresholds; the system calculates the current escalation level in real-time.
3. **Audit trail** — every state change (creation, assignment, status change, resolution) is logged to `cmp_complaint_actions`.
4. **Medical check linkage** — physical welfare complaints (suspected substance abuse, injury) can require medical checks with result documentation and evidence upload.
5. **AI insights** — the embedded rule-based engine scores every complaint for sentiment, escalation risk, and safety risk; these scores power the dashboard and reports.

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Category Management | Hierarchical categories (parent/child) with per-category SLA timers (5 levels) | F.D3.1 | ✅ |
| Department SLA | Maps categories to responsible entities with dept-specific SLA timers and escalation group assignments | F.D3.1 | ✅ |
| Complaint Registration | Ticket creation with complainant, target, classification, description, image evidence | F.D3.1, T.D3.1.1 | 🟡 |
| Complaint Assignment | Assign to role/user; update status | T.D3.1.1.2 | 🟡 |
| Complaint Resolution | Update resolution status, add notes, record resolved-by | T.D3.1.2 | 🟡 |
| Complaint Actions/Timeline | Full audit log of all state changes per complaint | T.D3.1.2 | ❌ |
| Medical Checks | Record physical exams linked to complaints (alcohol/drug/fitness) | Beyond RBS | ✅ |
| AI Insight Engine | Rule-based sentiment, escalation risk (0–100), safety risk (0–100), category prediction | Beyond RBS | ✅ |
| Dashboard | KPIs, escalation heatmap, category distribution, AI risk predictions, sentiment trend | Beyond RBS | ✅ |
| Reports | Summary-status, SLA violation, Pareto, hotspot, AI risk/sentiment bubble chart | Beyond RBS | ✅ |
| Student Portal Complaints | Students can register complaints through portal | Beyond RBS | 🟡 |
| Feedback Collection | Feedback forms and response collection | F.D3.2 | ❌ |

### 2.3 Menu Navigation Path

```
School Admin Panel
└── Complaint [/complaint]
    ├── Dashboard         [/complaint/complaint-mgt]  (combined index with tabs)
    ├── Categories        [/complaint/complaint-categories]
    ├── Department SLAs   [/complaint/department-sla]
    ├── Complaints        [/complaint/complaints]
    ├── Complaint Actions [/complaint/complaint-actions]
    ├── Medical Checks    [/complaint/medical-checks]
    ├── AI Insights       [/complaint/ai-insights]
    └── Reports
        └── Summary & Status [/complaint/reports/summary-status]
```

### 2.4 Module Architecture

```
Modules/Complaint/
├── app/
│   ├── Events/
│   │   └── ComplaintSaved.php               # Fired on create + update
│   ├── Http/Controllers/
│   │   ├── AiInsightController.php          # STUB — no real logic
│   │   ├── ComplaintActionController.php    # STUB — no real logic
│   │   ├── ComplaintCategoryController.php  # COMPLETE
│   │   ├── ComplaintController.php          # PARTIAL (dd() bugs, empty destroy)
│   │   ├── ComplaintDashboardController.php # STUB
│   │   ├── ComplaintReportController.php    # COMPLETE
│   │   ├── DepartmentSlaController.php      # COMPLETE
│   │   └── MedicalCheckController.php       # COMPLETE
│   ├── Listeners/
│   │   └── ProcessComplaintAIInsights.php   # Handles ComplaintSaved → AI engine
│   ├── Models/
│   │   ├── AiInsight.php
│   │   ├── Complaint.php                    # HasMedia (Spatie)
│   │   ├── ComplaintAction.php
│   │   ├── ComplaintCategory.php
│   │   ├── DepartmentSla.php
│   │   └── MedicalCheck.php                 # HasMedia (Spatie)
│   ├── Policies/ (7 policies)
│   ├── Providers/
│   │   ├── ComplaintServiceProvider.php
│   │   ├── EventServiceProvider.php         # registers ComplaintSaved→ProcessComplaintAIInsights
│   │   └── RouteServiceProvider.php
│   └── Services/
│       ├── ComplaintAIInsightEngine.php     # Rule-based AI engine
│       └── ComplaintDashboardService.php    # Dashboard KPIs + AJAX donuts
├── database/migrations/ (6 migrations)
├── resources/views/complaint/
│   ├── ai-insights/           # index.blade.php
│   ├── category/              # create, edit, index, show, trash
│   ├── complaint/             # create, edit, index, show, trash
│   ├── complaint-manage/      # index, actions
│   ├── department-sla/        # create, edit, index, show, trash
│   ├── medical-checks/        # create, edit, index, show, trash
│   ├── dashboard.blade.php
│   └── index.blade.php
├── resources/views/reports/
│   ├── complaint-status/      # index.blade.php
│   ├── hotspot/               # index.blade.php
│   ├── pareto/                # index.blade.php
│   ├── sentiment/             # index.blade.php
│   ├── sla-violation/         # index.blade.php
│   └── index.blade.php
└── routes/
    ├── api.php
    └── web.php                 # Minimal — actual routes in tenant.php
```

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role in Complaint Module | Permissions |
|---|---|---|
| School Admin | Full access: configure categories, SLAs, view all complaints, generate reports | All permissions |
| Principal | View all complaints, manage escalations, approve resolutions | view, update, manage |
| HOD / Teacher | View complaints in their department, update assigned complaints | view, update (assigned only) |
| Student | Register complaint via Student Portal | create (own) |
| Parent | Register complaint via Student Portal | create (own) |
| Staff Member | Register complaint; appear as target or complainant | create |
| Front Office Staff | Register and manage complaints on behalf of walk-in complainants | create, update |
| System | Auto-generates ticket number, fires AI insights, logs actions | system actor |

---

## 4. FUNCTIONAL REQUIREMENTS

---

### FR-CMP-001: Complaint Category Management (F.D3.1)

**RBS Reference:** F.D3.1 — Complaint Handling (configuration pre-requisite)
**Priority:** 🔴 Critical
**Status:** ✅ Implemented
**Table(s):** `cmp_complaint_categories`

#### Requirements

**REQ-CMP-001.1: Create Complaint Category**
| Attribute | Detail |
|---|---|
| Description | Admin creates a complaint category (optionally nested under a parent) with SLA timelines |
| Actors | School Admin |
| Preconditions | Authenticated with `tenant.complaint-category.create` permission |
| Input | name (required, max 100), code (optional, unique), description, severity_level_id, priority_score_id, expected_resolution_hours (required, min 1), escalation_hours_l1–l5 (each > previous, required), parent_id (optional) |
| Processing | Validate with hierarchical hour rules (l2 > l1 > expected, etc.); create record |
| Output | Redirect to complaint-mgt index with success flash |
| Status | ✅ |

**REQ-CMP-001.2: Edit / Update Category**
| Attribute | Detail |
|---|---|
| Description | Modify category including active/inactive toggle |
| Actors | School Admin |
| Preconditions | `tenant.complaint-category.update` permission |
| Input | All create fields + is_active; code must remain unique (excluding self) |
| Processing | Validate, update, log activity via `activityLog()` helper |
| Output | Redirect with success; activity log entry created |
| Status | ✅ |

**REQ-CMP-001.3: Soft Delete / Trash / Restore / Force Delete**
| Attribute | Detail |
|---|---|
| Description | Soft-delete category (deactivates first); view trash; restore; force-delete (blocks if has children) |
| Actors | School Admin |
| Preconditions | `tenant.complaint-category.delete/restore/forceDelete` |
| Processing | `is_active=false` then `delete()`; force delete checks for children via `parent_id` constraint |
| Status | ✅ |

**REQ-CMP-001.4: Toggle Active Status via AJAX**
| Attribute | Detail |
|---|---|
| Description | Toggle is_active via POST AJAX endpoint; returns JSON |
| Input | `is_active` boolean |
| Output | `{ success, is_active, message }` |
| Status | ✅ |

**Acceptance Criteria:**
- [x] ST.D3.1.1.1 — Category can be created and appears in category list
- [x] Hierarchical escalation hours are validated (l1 < l2 < l3 < l4 < l5)
- [x] Category with children cannot be force-deleted
- [x] Soft-deleted categories appear in trash and can be restored

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Controller | `ComplaintCategoryController.php` | index, create, store, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, show | Full implementation |
| Model | `ComplaintCategory.php` | scopeParents(), children(), parent(), recursiveChildren(), severityLevel(), priorityScore() | All relationships defined |
| Views | `complaint/category/` | create, edit, index, show, trash | All 5 views exist |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---|---|---|---|
| 1 | Create category with all SLA hours | Browser | ✅ (ComplaintCategoryTest) | High |
| 2 | Create with invalid escalation order (l2 < l1) | Browser | Partial | High |
| 3 | Force-delete category that has children | Feature | No | Medium |
| 4 | Toggle-status AJAX returns correct JSON | Feature | No | Medium |

---

### FR-CMP-002: Department SLA Configuration (F.D3.1 — extended)

**RBS Reference:** F.D3.1 — Complaint Handling (resolution assignment)
**Priority:** 🔴 Critical
**Status:** ✅ Implemented
**Table(s):** `cmp_department_sla`

#### Requirements

**REQ-CMP-002.1: Create Department SLA Rule**
| Attribute | Detail |
|---|---|
| Description | Define department-level SLA overriding category defaults; maps category (+ optional subcategory) to responsible entity (department, designation, role, user, entity group, vehicle, or vendor) with 5-level escalation hours |
| Actors | School Admin |
| Preconditions | Complaint categories exist; `tenant.department-sla.create` |
| Input | complaint_category_id (required), complaint_subcategory_id (optional), target_* fields (one or more), dept_expected_resolution_hours, dept_escalation_hours_l1–l5 (ascending), escalation_l1–l5_entity_group_id (optional) |
| Processing | Validate ascending hours; create record; unique composite index enforces no duplicate (category + subcategory + user_type + role + user) |
| Output | Redirect to complaint-mgt index |
| Status | ✅ |

**REQ-CMP-002.2: Edit / Update / Delete SLA Rule**
| Attribute | Detail |
|---|---|
| Description | Full lifecycle management with soft-delete, trash, restore, force-delete |
| Status | ✅ |

**Known Issues:**
- The `complaint_subcategory_id` column in the migration is defined as `NOT NULL CONSTRAINED` but the model has it as fillable without required validation in the controller — can cause FK violations if subcategory is omitted.
- Migration defines `target_user_type_id` FK to `sys_dropdowns` but the model's `$fillable` and validation rules reference `target_department_id`, `target_designation_id`, `target_entity_group_id`, `target_vehicle_id`, `target_vendor_id` which do NOT exist in the migration DDL. These columns exist only in the model's `$fillable` — schema migration vs model are out of sync.
- `toggleStatus` route is declared but `DepartmentSlaController` does not implement this method.

**Acceptance Criteria:**
- [x] ST.D3.1.1.2 — Assign complaint to staff (SLA rule defines who is responsible)
- [x] Dept escalation hours must be in ascending order
- [x] Duplicate SLA (same category+subcategory+target) is blocked by unique index

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Controller | `DepartmentSlaController.php` | index, create, store, edit, update, destroy, trashed, restore, forceDelete, show | Full; missing toggleStatus |
| Model | `DepartmentSla.php` | category(), subCategory(), targetDepartment(), targetRole(), targetUser(), targetDesignation(), targetEntityGroup(), targetVehicle(), targetVendor() | Extended target relationships |
| Views | `complaint/department-sla/` | create, edit, index, show, trash | All 5 views exist |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---|---|---|---|
| 1 | Create SLA rule — all fields | Browser | ✅ (DepartmentSlaCrudTest) | High |
| 2 | Duplicate SLA blocked by unique constraint | Feature | No | High |
| 3 | Schema reconciliation: migration vs model fillable columns | Schema | No | Critical |

---

### FR-CMP-003: Complaint Registration (F.D3.1 — T.D3.1.1)

**RBS Reference:** T.D3.1.1 — Register Complaint
**Priority:** 🔴 Critical
**Status:** 🟡 Partial
**Table(s):** `cmp_complaints`, `cmp_complaint_actions`

#### Requirements

**REQ-CMP-003.1: Register New Complaint (ST.D3.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Create a new complaint ticket with auto-generated ticket number, complainant details, target specification, classification, description, and optional image evidence |
| Actors | School Admin, Front Office Staff, Student (via Portal) |
| Preconditions | Complaint categories exist; `tenant.complaint.create` permission |
| Input | complainant_type_id (required), complainant_user_id or complainant_name (conditional on type), target_type_id (required), target fields, category_id (required), subcategory_id (optional), severity_level_id (required), priority_score_id (optional), title (required, max 200), description (optional text), location_details, incident_date, complaint_img (optional file) |
| Processing | 1) Auto-generate ticket_no: `CMP-{YEAR}-{6-digit-padded-serial}` with lock-for-update and collision check; 2) Assign hardcoded `status_id=124`; 3) Create complaint record; 4) Fire `ComplaintSaved` event → AI insights; 5) Send notification to Super Admin users; 6) Log `Created` action to `cmp_complaint_actions`; 7) Handle image media upload via Spatie MediaLibrary |
| Output | Redirect to complaint list with ticket number in success message |
| Status | 🟡 — functional but `dd()` in catch block (line 407), hardcoded `status_id=124`, no FormRequest |

**REQ-CMP-003.2: Assign Complaint to Staff (ST.D3.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | Admin assigns open complaint to a role and/or user; system logs assignment action |
| Actors | School Admin, Principal |
| Input | assigned_to_role_id, assigned_to_user_id, resolution_due_at |
| Processing | Update complaint; fire `ComplaintSaved` event; attempt to log assignment action (current code uses hardcoded action_type_id=197) |
| Status | 🟡 — works but action_type_id partially broken (Builder object not fully resolved for status change logging) |

**Known Issues:**
1. `dd($e->getMessage(), $e->getTraceAsString())` at line 407 of ComplaintController — will crash production on any store error instead of returning error response.
2. `filter()` method has `dd('FILTER HIT', request()->all())` at line 833 — AJAX dashboard filter will always die.
3. `status_id=124` is hardcoded — if the `sys_dropdowns` record with id=124 changes or does not exist in a tenant, complaints will fail FK constraint.
4. In `update()`, the status-change action logging uses `DB::table('...')->where(...)` as a Builder object assigned to `action_type_id` without calling `->value('id')` — the logged action type will be `null`.
5. `destroy()` method body is empty — soft delete is not implemented.
6. `manage()` method uses `Gate::authorize('prime.complaint.manage')` — uses `prime.` prefix, inconsistent with other gates using `tenant.` prefix.

**Acceptance Criteria:**
- [x] ST.D3.1.1.1 — Enter complaint details (title, description, category, severity)
- [x] ST.D3.1.1.2 — Assign complaint to staff (assigned_to_role_id, assigned_to_user_id)
- [ ] Ticket number is globally unique within a tenant for the year
- [ ] Exception handling must not expose `dd()` stack traces
- [ ] status_id must resolve from dropdown table, not be hardcoded

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Controller | `ComplaintController.php` | index, create, store, show, edit, update, manage | destroy() empty; filter() has dd(); hardcoded IDs |
| Model | `Complaint.php` | All major relationships, scopeOpen, scopeEscalated, scopeAssignedToUser/Role, actions(), medicalChecks(), aiInsight() | HasMedia (Spatie) |
| Event | `ComplaintSaved.php` | constructor(Complaint) | Fires on store and update |
| Service | `ComplaintDashboardService.php` | Injected in controller constructor | |
| Views | `complaint/complaint/` | create, edit, index, show, trash | All 5 views exist; complaint-manage/index and actions also exist |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---|---|---|---|
| 1 | Create complaint — schema, model, destroy contract | Browser | ✅ (ComplaintCrudTest) | High |
| 2 | store() fails gracefully without dd() | Feature | No | Critical |
| 3 | Ticket number is unique under concurrent creation | Feature | No | High |
| 4 | AI insight is created on complaint store | Feature | No | High |
| 5 | Notification sent to Super Admin on creation | Feature | No | Medium |

---

### FR-CMP-004: Complaint Resolution & Status Management (F.D3.1 — T.D3.1.2)

**RBS Reference:** T.D3.1.2 — Complaint Resolution
**Priority:** 🔴 Critical
**Status:** 🟡 Partial
**Table(s):** `cmp_complaints`, `cmp_complaint_actions`

#### Requirements

**REQ-CMP-004.1: Update Resolution Status (ST.D3.1.2.1)**
| Attribute | Detail |
|---|---|
| Description | Update complaint status (Open → In-Progress → Resolved/Closed/Escalated/Rejected) |
| Actors | School Admin, Assigned User/Role |
| Input | status_id (FK to sys_dropdowns), is_escalated flag |
| Processing | Update status; fire ComplaintSaved event; log action (currently broken — Builder object passed as action_type_id) |
| Status | 🟡 — update works; action logging is broken |

**REQ-CMP-004.2: Add Resolution Notes (ST.D3.1.2.2)**
| Attribute | Detail |
|---|---|
| Description | Add resolution summary and record who resolved it |
| Input | resolution_summary (text), resolved_by_role_id, resolved_by_user_id, actual_resolved_at |
| Processing | Update complaint; log resolution action (action_type_id=202 hardcoded) |
| Status | 🟡 — update works; hardcoded action IDs |

**REQ-CMP-004.3: Escalation Level Calculation**
| Attribute | Detail |
|---|---|
| Description | Automatically determine escalation level based on time elapsed since ticket_date vs category escalation timeline |
| Processing | Compare `now()` against cumulative hours: expected_resolution_hours (Level 1), +l1 (Level 2), +l2 (Level 3), +l3 (Level 4), +l4 (Level 5), +l5 (Breached); return current level |
| Implementation | Inline calculation in ComplaintController (private helper `getComplaintsWithEscalation()`) and mirrored in `ComplaintDashboardService::calculateCurrentEscalationLevel()` — duplicate logic |
| Status | ✅ calculation works; 🟡 code is duplicated in two places |

**Acceptance Criteria:**
- [x] ST.D3.1.2.1 — Update resolution status
- [x] ST.D3.1.2.2 — Add resolution notes
- [ ] Status change must be logged in cmp_complaint_actions with correct action_type_id
- [ ] Resolved complaint shows actual_resolved_at and resolved_by information

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---|---|---|---|
| 1 | Status changed → action logged correctly | Feature | No | Critical |
| 2 | Resolution summary saved and displayed | Browser | No | High |
| 3 | Escalation level progression over time | Unit | No | High |

---

### FR-CMP-005: Complaint Action / Timeline Log (F.D3.1 — T.D3.1.2 extended)

**RBS Reference:** T.D3.1.2 — Complaint Resolution (audit trail)
**Priority:** 🔴 Critical
**Status:** ❌ Not Started (stub controller)
**Table(s):** `cmp_complaint_actions`

#### Requirements

**REQ-CMP-005.1: View Complaint Timeline**
| Attribute | Detail |
|---|---|
| Description | Display chronological log of all actions taken on a complaint (creation, assignment, status changes, resolution, private notes) |
| Actors | School Admin, Principal, Assigned Staff |
| Processing | Query `cmp_complaint_actions` with relationships; support private notes (is_private_note — visible only to Admin/Principal) |
| Status | ❌ — `ComplaintActionController` is a boilerplate stub; `actions.blade.php` view exists but controller returns wrong view |

**REQ-CMP-005.2: Add Manual Action/Note**
| Attribute | Detail |
|---|---|
| Description | Admin/Staff can manually add notes or actions to a complaint timeline |
| Input | complaint_id, action_type_id, notes, is_private_note |
| Status | ❌ — store() method is empty |

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Controller | `ComplaintActionController.php` | All methods | STUB — return wrong views |
| Model | `ComplaintAction.php` | complaint(), actionType(), performedByUser(), performedByRole(), assignedToUser(), assignedToRole() | Complete |
| Views | `complaint-manage/actions.blade.php` | — | View exists |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---|---|---|---|
| 1 | Timeline shows all actions in chronological order | Feature | No | High |
| 2 | Private note hidden from non-admin users | Feature | No | High |
| 3 | Store action inserts correct record | Feature | No | High |

---

### FR-CMP-006: Medical Check Management (School Welfare Extension)

**RBS Reference:** Beyond RBS — school welfare extension
**Priority:** 🟡 Medium
**Status:** ✅ Implemented
**Table(s):** `cmp_medical_checks`

#### Requirements

**REQ-CMP-006.1: Create Medical Check Record**
| Attribute | Detail |
|---|---|
| Description | Link a medical examination to a complaint where physical welfare is suspected (drug/alcohol test, fitness check) |
| Actors | School Admin, Medical Staff |
| Preconditions | Complaint exists with `is_medical_check_required=true`; `tenant.medical-check.create` |
| Input | complaint_id (required), check_type (required, FK→sys_dropdowns), conducted_by (optional string), conducted_at (required date), result (required, FK→sys_dropdowns), reading_value (optional, max 50), remarks (optional text), medical_img (optional file) |
| Processing | Validate; create record; handle Spatie media upload for `medical_img`; update `evidence_uploaded` flag |
| Output | Redirect to complaint-mgt index with success message |
| Status | ✅ |

**Known Issue:** `MedicalCheck` model does not have `SoftDeletes` applied on the migration (no `softDeletes()` column in migration), but the model uses `SoftDeletes` trait — this will cause a `deleted_at` column missing error when soft-deletes are attempted.

**Acceptance Criteria:**
- [x] Medical check can be created with required fields only
- [x] Image upload sets `evidence_uploaded=true`
- [x] No image keeps `evidence_uploaded=false`
- [ ] Soft-delete migration column must be added to `cmp_medical_checks`

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Controller | `MedicalCheckController.php` | index, create, store, edit, update, destroy, trashed, restore, forceDelete, show | Complete |
| Model | `MedicalCheck.php` | complaint(), checkType(), resultStatus() | HasMedia; missing `created_by` FK |
| Views | `complaint/medical-checks/` | create, edit, index, show, trash | All 5 exist |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---|---|---|---|
| 1 | DB schema correct, model configured | Browser | ✅ (MedicalCheckCrudTest) | High |
| 2 | Create with required fields | Browser | ✅ | High |
| 3 | Image upload sets evidence_uploaded=true | Browser | ✅ | High |
| 4 | Soft-delete → trash → restore → force-delete | Browser | ✅ | High |
| 5 | Missing required field shows validation error | Browser | ✅ (4 scenarios) | High |

---

### FR-CMP-007: AI Insight Engine (AI-Driven Risk Assessment)

**RBS Reference:** Beyond RBS — Prime-AI platform differentiator
**Priority:** 🟡 Medium
**Status:** ✅ Engine complete; ❌ Controller/View stub
**Table(s):** `cmp_ai_insights`

#### Requirements

**REQ-CMP-007.1: Automatic AI Processing on Complaint Save**
| Attribute | Detail |
|---|---|
| Description | Every time a complaint is created or updated, the AI engine processes it synchronously via event/listener pipeline |
| Processing | `ComplaintSaved` event → `ProcessComplaintAIInsights` listener → `ComplaintAIInsightEngine::processComplaint()` |
| Output | One `cmp_ai_insights` record per complaint (upserted via `updateOrCreate`) |
| Status | ✅ |

**REQ-CMP-007.2: Sentiment Analysis**
| Attribute | Detail |
|---|---|
| Description | Score the complaint description for negative sentiment using keyword matching |
| Algorithm | Keyword matching against: angry, delay, harassment, urgent, unsafe, worst, threat, complaint — each adds +0.15 to score (capped at 1.0) |
| Output | `sentiment_score` (DECIMAL 4,3 range 0.00–1.00) + `sentiment_label_id` mapped as: ≥0.75=Angry(147), ≥0.50=Urgent(148), ≥0.25=Neutral(150), default=Calm(149) |
| Status | ✅ |

**REQ-CMP-007.3: Escalation Risk Score**
| Attribute | Detail |
|---|---|
| Description | Composite 0–100 score indicating likelihood of escalation |
| Formula | (severity_score × 0.35) + (frequency_score × 0.30) + (sentiment_score × 0.20) + (pending_days_score × 0.15) |
| Inputs | severity_value (Critical=100, High=80, Medium=50, Low=20), frequency = count of complaints against same target_id (×20, max 100), sentiment ×100, days pending ×5 (max 100) |
| Output | `escalation_risk_score` DECIMAL(5,2) |
| Status | ✅ |

**REQ-CMP-007.4: Safety Risk Score**
| Attribute | Detail |
|---|---|
| Description | Independent safety risk axis based on safety-keyword severity |
| Keywords | accident(90), injury(95), unsafe(85), violence(100), bully(80), harassment(90), rash driving(95), abuse(90), threat(85), weapon(100), blood(95), fight(90), sexual(100) — take max |
| Severity Boost | critical+30, high+20, medium+10 |
| Sensitivity Flag | `is_sensitive=true` → floor score at 85 |
| Output | `safety_risk_score` DECIMAL(5,2) |
| Status | ✅ |

**REQ-CMP-007.5: Category Prediction**
| Attribute | Detail |
|---|---|
| Description | Predict the most appropriate complaint category |
| Current Implementation | Trivially returns `complaint->category_id` — placeholder for future NLP model |
| Status | ✅ (stub — not meaningful) |

**REQ-CMP-007.6: AI Insight Viewing**
| Attribute | Detail |
|---|---|
| Description | Admin can view AI insight scores for any complaint |
| Status | ❌ — `AiInsightController` is a boilerplate stub |

**Known Issues:**
1. `ProcessComplaintAIInsights` listener is NOT queued (does not implement `ShouldQueue`) — runs synchronously during the HTTP request, adding latency on every complaint save.
2. Sentiment label IDs (147, 148, 149, 150) are hardcoded — if `sys_dropdowns` IDs differ in any tenant, labels will be wrong.
3. `calculateRiskScore()` references `$complaint->target_id` but the Complaint model's `target()` method simply returns `$this->target_id` (not a relationship) — `frequency_score` will always reference `cmp_complaints.target_id`, not a polymorphic entity.
4. Category prediction is a no-op — returns existing `category_id`.
5. `model_version = 'rules-v1'` is hardcoded — no versioning management.

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Service | `ComplaintAIInsightEngine.php` | processComplaint(), calculateSentiment(), calculateRiskScore(), calculateSafetyRisk(), predictCategory() | Complete rule-based engine |
| Listener | `ProcessComplaintAIInsights.php` | handle(ComplaintSaved) | Synchronous, no queue |
| Event | `ComplaintSaved.php` | constructor(Complaint) | Fired on store + update |
| Model | `AiInsight.php` | complaint(), sentimentLabel(), predictedCategory() | SoftDeletes |
| Controller | `AiInsightController.php` | All methods | STUB |
| View | `ai-insights/index.blade.php` | — | Exists |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---|---|---|---|
| 1 | AI insight created on complaint store | Feature | No | Critical |
| 2 | Sentiment: "harassment urgent" → score ≥ 0.30 | Unit | No | High |
| 3 | Safety: "violence" keyword → score = 100 | Unit | No | High |
| 4 | Escalation risk formula produces expected output | Unit | No | High |
| 5 | updateOrCreate prevents duplicate insight rows | Feature | No | High |

---

### FR-CMP-008: Complaint Dashboard & Analytics (Beyond RBS)

**RBS Reference:** Beyond RBS
**Priority:** 🟢 Low-Medium
**Status:** ✅ Service complete; ❌ Dedicated controller stub
**Table(s):** `cmp_complaints`, `cmp_ai_insights`, `cmp_department_sla`

#### Requirements

**REQ-CMP-008.1: Dashboard KPIs**
| Attribute | Detail |
|---|---|
| Description | Date-ranged dashboard showing open tickets, new today, avg resolution hours (vs SLA expected), SLA breaches, category pie chart |
| Filtering | Date range (from/to); default last 30 days |
| Output | `openTickets`, `newToday`, `avgResolutionHours`, `resolutionTrend` (Faster/Slower), `slaBreaches`, `categoryPie` |
| Status | ✅ (service) — the index() method of ComplaintController renders this |

**REQ-CMP-008.2: Escalation Heatmap**
| Attribute | Detail |
|---|---|
| Description | Matrix of category × escalation level (Level 1–5, Breached) showing complaint counts |
| Output | ApexCharts-compatible series data |
| Status | ✅ |

**REQ-CMP-008.3: Critical Ticket Widget**
| Attribute | Detail |
|---|---|
| Description | Top 5 open complaints with nearest breach time; flags tickets ≤5 hours to breach |
| Status | ✅ |

**REQ-CMP-008.4: AI Risk Predictions Widget**
| Attribute | Detail |
|---|---|
| Description | Top 5 complaints with escalation_risk_score ≥ 80 |
| Status | ✅ |

**REQ-CMP-008.5: Sentiment Trend Chart**
| Attribute | Detail |
|---|---|
| Description | Daily average sentiment score over the date range |
| Status | ✅ |

**REQ-CMP-008.6: Repeated-Target Frustration Report**
| Attribute | Detail |
|---|---|
| Description | Identifies complainant-target pairs with ≥2 complaints; computes frustration probability score using frequency (×0.35), recency (×0.25), sentiment (×0.20), risk (×0.20) |
| Status | ✅ |

**REQ-CMP-008.7: AJAX Donut Charts**
| Attribute | Detail |
|---|---|
| Description | Three AJAX GET endpoints returning chart data: severity-vs-department, department-vs-severity, department-status |
| Status | ✅ — routes registered and methods implemented |
| Known Issue | `filter()` method (for main dashboard AJAX filter) has `dd()` — completely non-functional |

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Service | `ComplaintDashboardService.php` | getDashboardData(), getRecentCriticalTickets(), getEscalationHeatmapData(), getHighRiskPredictions(), getSentimentTrend(), getSeverityVsDepartmentDonut(), getDepartmentVsSeverityDonut(), getDepartmentStatusDonut(), getRepeatedTargetFrustration(), resolveDateRange() | Full implementation |
| Controller | `ComplaintController.php` | severityVsDepartmentDonut(), departmentVsSeverityDonut(), departmentStatusDonut() | AJAX endpoints |
| Controller | `ComplaintController.php` | filter() | BROKEN — dd() at line 833 |
| Controller | `ComplaintDashboardController.php` | index() | Returns wrong view (complaint::index not dashboard) |

---

### FR-CMP-009: Complaint Reports (Beyond RBS)

**RBS Reference:** Beyond RBS
**Priority:** 🟢 Low-Medium
**Status:** ✅ Implemented
**Table(s):** `cmp_complaints`, `cmp_ai_insights`, `cmp_complaint_categories`

#### Requirements

**REQ-CMP-009.1: Summary & Status Report**
| Attribute | Detail |
|---|---|
| Description | Tabular report by status × priority × category × subcategory × severity; shows total tickets, %, avg resolution hours |
| Filters | start_date, end_date, category, complainant_type_id, status |
| Status | ✅ |

**REQ-CMP-009.2: SLA Violation Report**
| Attribute | Detail |
|---|---|
| Description | Lists complaints that have breached or are at-risk of breaching SLA; shows delay_hours, assigned_to, escalation_level |
| Filters | violation_type (breached/at_risk/all), department, escalation_level, category |
| Note | Department filter code commented out — no `department_id` in `cmp_complaint_categories` schema |
| Status | ✅ (partial — department filter disabled) |

**REQ-CMP-009.3: Pareto Analysis Report**
| Attribute | Detail |
|---|---|
| Description | Pareto chart data — categories ranked by complaint count with cumulative percentage to identify top-80% sources |
| Output | category, sub_category, ticket_count, avg_severity, pct_of_total, cumulative_pct |
| Status | ✅ |

**REQ-CMP-009.4: Complainant Hotspot Report**
| Attribute | Detail |
|---|---|
| Description | Identifies targets (departments, staff, vehicles) receiving the highest complaint volumes with AI-driven avg risk score |
| Filters | min_count (minimum complaints to appear), target_type_id |
| Note | References `c.target_id` but `cmp_complaints` column is named `target_id` (FK-free bigint) — correct |
| Status | ✅ |

**REQ-CMP-009.5: AI Risk & Sentiment Bubble Chart Report**
| Attribute | Detail |
|---|---|
| Description | Scatter/bubble chart with x=sentiment_score, y=escalation_risk_score, z=safety_risk_score, label=ticket_no |
| Filters | high_risk_only, negative_sentiment_only, escalation_threshold, sentiment_threshold |
| Status | ✅ |

**Current Implementation:**
| Layer | File | Method | Notes |
|---|---|---|---|
| Controller | `ComplaintReportController.php` | summary() + 9 private helper methods | All reports combined in summary() |
| Views | `reports/` | index, complaint-status/index, hotspot/index, pareto/index, sentiment/index, sla-violation/index | All 6 view files exist |

---

### FR-CMP-010: Student Portal Complaint Registration

**RBS Reference:** F.D3.1 (student/parent self-service)
**Priority:** 🟡 Medium
**Status:** 🟡 Partial (referenced but not part of this module)
**Table(s):** `cmp_complaints`

#### Requirements

**REQ-CMP-010.1: Student/Parent Self-Service Complaint**
| Attribute | Detail |
|---|---|
| Description | Students and parents can register complaints from the Student Portal |
| Controller | `Modules\StudentPortal\Http\Controllers\StudentPortalComplaintController` |
| Routes | `/complaint` (resource) + `/complaint/ajax/subcategories/{category}` + `/complaint/ajax/subcategory-meta/{category}` |
| Status | 🟡 — controller exists in StudentPortal module; AJAX subcategory endpoints for cascading dropdowns exist |

---

### FR-CMP-011: Feedback Collection (F.D3.2)

**RBS Reference:** F.D3.2 — Feedback Collection
**Priority:** ⚪ Not Started
**Status:** ❌ Not Started

#### Requirements

**REQ-CMP-011.1: Create Feedback Form (ST.D3.2.1.1)**
| Attribute | Detail |
|---|---|
| Description | Admin creates structured feedback forms for students/parents/staff |
| Status | ❌ — No model, controller, view, or DB table exists |

**REQ-CMP-011.2: Collect Feedback Responses (ST.D3.2.1.2)**
| Attribute | Detail |
|---|---|
| Description | Recipients submit responses; responses are stored and viewable |
| Status | ❌ — Not started |

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 Entity Overview

| Table | Model | Records Purpose | Rows ~Range |
|---|---|---|---|
| `cmp_complaint_categories` | ComplaintCategory | Hierarchical complaint types with SLA timelines | 20–100 per school |
| `cmp_department_sla` | DepartmentSla | Category × department/role/user SLA overrides | 10–50 per school |
| `cmp_complaints` | Complaint | Core complaint tickets | 100–10,000 per school/year |
| `cmp_complaint_actions` | ComplaintAction | Audit log entries per complaint | 3–20× complaint count |
| `cmp_medical_checks` | MedicalCheck | Physical check records linked to complaints | Rare — 0.5–5% of complaints |
| `cmp_ai_insights` | AiInsight | AI scores per complaint (1:1 with complaints) | = complaint count |

### 5.2 Detailed Entity Specification

#### cmp_complaint_categories

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | BIGINT UNSIGNED PK | — | AI | Primary key |
| parent_id | BIGINT UNSIGNED FK | NULL | — | Self-referencing parent; restrictOnDelete |
| name | VARCHAR(100) | NOT NULL | — | Category display name |
| code | VARCHAR(30) | NULL | — | Short code (unique if provided) |
| description | VARCHAR(512) | NULL | — | Optional description |
| severity_level_id | BIGINT UNSIGNED FK | NULL | — | → sys_dropdowns; nullOnDelete |
| priority_score_id | BIGINT UNSIGNED FK | NULL | — | → sys_dropdowns; nullOnDelete |
| expected_resolution_hours | INT UNSIGNED | NOT NULL | — | Base SLA in hours |
| escalation_hours_l1 | INT UNSIGNED | NOT NULL | — | Additional hours before L2 escalation |
| escalation_hours_l2 | INT UNSIGNED | NOT NULL | — | Additional hours before L3 escalation |
| escalation_hours_l3 | INT UNSIGNED | NOT NULL | — | Additional hours before L4 escalation |
| escalation_hours_l4 | INT UNSIGNED | NOT NULL | — | Additional hours before L5 escalation |
| escalation_hours_l5 | INT UNSIGNED | NOT NULL | — | Additional hours before Breached |
| is_active | TINYINT(1) | NOT NULL | 1 | Active flag |
| deleted_at | TIMESTAMP | NULL | — | SoftDeletes |
| created_at / updated_at | TIMESTAMP | — | — | Audit timestamps |

**Indexes:** `idx_cat_parent` (parent_id)

**Schema Gap:** Model has `department_id` in `$fillable` but migration comment it out — column does NOT exist in DB.

#### cmp_department_sla

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | BIGINT UNSIGNED PK | — | AI | Primary key |
| complaint_category_id | BIGINT UNSIGNED FK | NOT NULL | — | → cmp_complaint_categories; restrictOnDelete |
| complaint_subcategory_id | BIGINT UNSIGNED FK | NOT NULL | — | → cmp_complaint_categories; restrictOnDelete (NOTE: migration is NOT NULL but code treats as optional) |
| target_user_type_id | BIGINT UNSIGNED FK | NULL | — | → sys_dropdowns; nullOnDelete |
| target_role_id | BIGINT UNSIGNED FK | NULL | — | → sys_roles; nullOnDelete |
| target_user_id | BIGINT UNSIGNED FK | NULL | — | → sys_users; nullOnDelete |
| dept_expected_resolution_hours | INT UNSIGNED | NOT NULL | — | Dept-level base SLA |
| dept_escalation_hours_l1–l5 | INT UNSIGNED | NOT NULL | — | Dept-level escalation ladder |
| escalation_l1–l5_role_id | BIGINT UNSIGNED FK | NULL | — | Escalation responsible role per level |
| escalation_l1–l5_user_id | BIGINT UNSIGNED FK | NULL | — | Escalation responsible user per level |
| is_active | TINYINT(1) | NOT NULL | 1 | |
| deleted_at | TIMESTAMP | NULL | — | SoftDeletes |

**Unique Index:** `idx_sla_lookup` (complaint_category_id, complaint_subcategory_id, target_user_type_id, target_role_id, target_user_id, is_active)

**Schema vs Model Gap:** Model `$fillable` includes `target_department_id`, `target_designation_id`, `target_entity_group_id`, `target_vehicle_id`, `target_vendor_id` — NONE of these columns are in the migration. Model relationships reference these non-existent columns.

#### cmp_complaints

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | BIGINT UNSIGNED PK | — | AI | |
| ticket_no | VARCHAR(30) | NOT NULL UNIQUE | — | Format: CMP-YYYY-000001 |
| ticket_date | DATE | NOT NULL | — | Date ticket was raised |
| complainant_type_id | BIGINT UNSIGNED FK | NOT NULL | — | → sys_dropdowns (Student/Parent/Staff/External) |
| complainant_user_id | BIGINT UNSIGNED FK | NULL | — | → sys_users; nullOnDelete |
| complainant_name | VARCHAR(100) | NULL | — | For external/anonymous complainants |
| complainant_contact | VARCHAR(50) | NULL | — | Phone/email for external complainants |
| target_type_id | BIGINT UNSIGNED FK | NOT NULL | — | → sys_dropdowns (Staff/Department/Vehicle/etc.) |
| target_id | BIGINT UNSIGNED | NULL | — | Unconstrained FK — resolves against target_type |
| target_name | VARCHAR(100) | NULL | — | Denormalized target name |
| category_id | BIGINT UNSIGNED FK | NOT NULL | — | → cmp_complaint_categories |
| subcategory_id | BIGINT UNSIGNED FK | NULL | — | → cmp_complaint_categories; nullOnDelete |
| severity_level_id | BIGINT UNSIGNED FK | NOT NULL | — | → sys_dropdowns |
| priority_score_id | BIGINT UNSIGNED FK | NOT NULL | DEFAULT 3 | → sys_dropdowns |
| title | VARCHAR(200) | NOT NULL | — | Complaint headline |
| description | TEXT | NULL | — | Full description (fed to AI engine) |
| location_details | VARCHAR(255) | NULL | — | |
| incident_date | DATETIME | NULL | — | When incident occurred |
| incident_time | TIME | NULL | — | |
| status_id | BIGINT UNSIGNED FK | NOT NULL | — | → sys_dropdowns; currently hardcoded 124 on create |
| assigned_to_role_id | BIGINT UNSIGNED FK | NULL | — | → sys_roles; nullOnDelete |
| assigned_to_user_id | BIGINT UNSIGNED FK | NULL | — | → sys_users; nullOnDelete |
| resolution_due_at | DATETIME | NULL | — | SLA deadline |
| actual_resolved_at | DATETIME | NULL | — | When actually resolved |
| resolved_by_role_id | BIGINT UNSIGNED FK | NULL | — | |
| resolved_by_user_id | BIGINT UNSIGNED FK | NULL | — | |
| resolution_summary | TEXT | NULL | — | Resolution description |
| escalation_level | TINYINT UNSIGNED | NOT NULL | 0 | Stored escalation level (also computed dynamically) |
| is_escalated | BOOLEAN | NOT NULL | false | Manual escalation flag |
| source_id | BIGINT UNSIGNED FK | NULL | — | → sys_dropdowns (Walk-in/Email/Portal/etc.) |
| is_anonymous | BOOLEAN | NOT NULL | false | Anonymous complaint flag |
| dept_specific_info | JSON | NULL | — | Dept-specific additional fields |
| is_medical_check_required | BOOLEAN | NOT NULL | false | Flag to require medical exam |
| support_file | BOOLEAN | NOT NULL | false | Whether image is attached |
| created_by | BIGINT UNSIGNED FK | NULL | — | → sys_users |
| deleted_at | TIMESTAMP | NULL | — | SoftDeletes |

**Indexes:** `idx_cmp_status` (status_id), `idx_cmp_complainant` (complainant_type_id, complainant_user_id), `idx_cmp_target` (target_type_id, target_id)

**JSON Structure for `dept_specific_info`:** Free-form JSON; no schema defined. Used for department-specific supplementary fields.

#### cmp_complaint_actions

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | BIGINT UNSIGNED PK | — | AI | |
| complaint_id | BIGINT UNSIGNED FK | NOT NULL | — | → cmp_complaints; restrictOnDelete |
| action_type_id | BIGINT UNSIGNED FK | NOT NULL | — | → sys_dropdowns (Created/Assigned/StatusChange/Resolved/Note) |
| performed_by_user_id | BIGINT UNSIGNED FK | NULL | — | NULL = system action |
| performed_by_role_id | BIGINT UNSIGNED FK | NULL | — | Role context of performer |
| assigned_to_user_id | BIGINT UNSIGNED FK | NULL | — | For assignment actions |
| assigned_to_role_id | BIGINT UNSIGNED FK | NULL | — | For assignment actions |
| notes | TEXT | NULL | — | Action note/comment |
| is_private_note | BOOLEAN | NOT NULL | false | Private note flag |
| deleted_at | TIMESTAMP | NULL | — | SoftDeletes |

**Indexes:** `idx_act_complaint` (complaint_id)

#### cmp_medical_checks

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | BIGINT UNSIGNED PK | — | AI | |
| complaint_id | BIGINT UNSIGNED FK | NOT NULL | — | → cmp_complaints; restrictOnDelete |
| check_type | BIGINT UNSIGNED FK | NOT NULL | — | → sys_dropdowns (AlcoholTest/DrugTest/FitnessCheck) |
| conducted_by | VARCHAR(100) | NULL | — | Name of examiner |
| conducted_at | DATETIME | NOT NULL | — | When conducted |
| result | BIGINT UNSIGNED FK | NOT NULL | — | → sys_dropdowns (Positive/Negative/Inconclusive) |
| reading_value | VARCHAR(50) | NULL | — | Numeric/text result reading |
| remarks | TEXT | NULL | — | Additional notes |
| evidence_uploaded | BOOLEAN | NOT NULL | false | Whether evidence image was uploaded |

**Schema Gap:** No `deleted_at` column in migration — model uses SoftDeletes trait but DB lacks the column.
**Schema Gap:** No `created_by` column in migration or model.

#### cmp_ai_insights

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| id | BIGINT UNSIGNED PK | — | AI | |
| complaint_id | BIGINT UNSIGNED FK | NOT NULL UNIQUE | — | → cmp_complaints; restrictOnDelete; 1:1 unique |
| sentiment_score | DECIMAL(4,3) | NULL | — | 0.000–1.000 (rule-based keyword scoring) |
| sentiment_label_id | BIGINT UNSIGNED FK | NULL | — | → sys_dropdowns (Angry/Urgent/Neutral/Calm) |
| escalation_risk_score | DECIMAL(5,2) | NULL | — | 0–100 composite score |
| predicted_category_id | BIGINT UNSIGNED FK | NULL | — | → cmp_complaint_categories |
| safety_risk_score | DECIMAL(5,2) | NULL | — | 0–100 safety keyword score |
| model_version | VARCHAR(20) | NULL | — | 'rules-v1' hardcoded |
| processed_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | Last processing time |
| deleted_at | TIMESTAMP | NULL | — | SoftDeletes |

**Indexes:** `uq_ai_complaint` UNIQUE (complaint_id), `idx_ai_risk` (escalation_risk_score)

### 5.3 Entity Relationship Summary

```
cmp_complaint_categories ─┬── parent_id ──> self (tree)
                           └── children ──> self

cmp_department_sla ──> cmp_complaint_categories (category + subcategory)
                   ──> sys_roles (target + escalation roles)
                   ──> sys_users (target + escalation users)
                   ──> sys_dropdowns (target_user_type_id)

cmp_complaints ──> cmp_complaint_categories (category, subcategory)
               ──> sys_dropdowns (complainant_type, target_type, severity, priority, status, source)
               ──> sys_users (complainant, assigned_to, resolved_by, created_by)
               ──> sys_roles (assigned_to, resolved_by)
               ──<  cmp_complaint_actions (1:many)
               ──<  cmp_medical_checks (1:many)
               ──   cmp_ai_insights (1:1)
               ──   spatie_media (polymorphic — complaint_img)

cmp_ai_insights ──> cmp_complaints (1:1)
                ──> sys_dropdowns (sentiment_label)
                ──> cmp_complaint_categories (predicted_category)

cmp_complaint_actions ──> cmp_complaints
                      ──> sys_dropdowns (action_type)
                      ──> sys_users (performed_by, assigned_to)
                      ──> sys_roles (performed_by, assigned_to)

cmp_medical_checks ──> cmp_complaints
                   ──> sys_dropdowns (check_type, result)
                   ──   spatie_media (polymorphic — medical_img)
```

### 5.4 Schema Reconciliation Notes

| Issue | Table | Severity |
|---|---|---|
| `department_id` in ComplaintCategory `$fillable` but column not in migration | cmp_complaint_categories | High |
| `target_department_id`, `target_designation_id`, `target_entity_group_id`, `target_vehicle_id`, `target_vendor_id` in DepartmentSla `$fillable` but columns not in migration | cmp_department_sla | Critical |
| `complaint_subcategory_id` is NOT NULL in migration but treated as optional in code | cmp_department_sla | High |
| `deleted_at` missing from migration — SoftDeletes will fail | cmp_medical_checks | Critical |
| `created_by` not in migration or model | cmp_medical_checks | Medium |
| `target_table_name` and `target_code` used in store() but not in migration or `$fillable` | cmp_complaints | Medium |
| Escalation level stored in DB column AND computed dynamically — can be stale | cmp_complaints | Medium |

---

## 6. API & ROUTE SPECIFICATION

### 6.1 Route Summary

All routes are under prefix `/complaint` with name prefix `complaint.` and middleware `['auth', 'verified']`.

| Count | Route Group |
|---|---|
| 7 | Complaint Management (complaint-mgt resource: merged index view) |
| 4 | Dashboard AJAX endpoints |
| 9 | Complaint Categories (resource + extras) |
| 7 | Department SLA (resource + extras) |
| 7 | Complaints Core (resource + extras) |
| 5 | Complaint Actions (subset resource + restore/forceDelete) |
| 5 | Medical Checks (resource + extras) |
| 4 | AI Insights (subset resource + forceDelete) |
| 1 | Reports |
| **~49 total** | |

### 6.2 Detailed Endpoint Specification

#### Complaint Management Hub

| Method | URI | Name | Controller | Status |
|---|---|---|---|---|
| GET | /complaint/complaint-mgt | complaint.complaint-mgt.index | ComplaintController@index | 🟡 |
| GET | /complaint/complaint-mgt/create | complaint.complaint-mgt.create | ComplaintController@create | ✅ |
| POST | /complaint/complaint-mgt | complaint.complaint-mgt.store | ComplaintController@store | 🟡 |
| GET | /complaint/complaint-mgt/{id} | complaint.complaint-mgt.show | ComplaintController@show | ✅ |
| GET | /complaint/complaint-mgt/{id}/edit | complaint.complaint-mgt.edit | ComplaintController@edit | ✅ |
| PUT/PATCH | /complaint/complaint-mgt/{id} | complaint.complaint-mgt.update | ComplaintController@update | 🟡 |
| DELETE | /complaint/complaint-mgt/{id} | complaint.complaint-mgt.destroy | ComplaintController@destroy | ❌ empty |

#### Dashboard AJAX

| Method | URI | Name | Controller@Method | Status |
|---|---|---|---|---|
| GET | /complaint/dashboard-data | complaint.dashboard.data | ComplaintController@filter | ❌ dd() |
| GET | /complaint/dashboard/donut/severity-vs-department | — | ComplaintController@severityVsDepartmentDonut | ✅ |
| GET | /complaint/dashboard/donut/department-vs-severity | — | ComplaintController@departmentVsSeverityDonut | ✅ |
| GET | /complaint/dashboard/donut/department-status | — | ComplaintController@departmentStatusDonut | ✅ |

#### Complaint Categories

| Method | URI | Name | Controller@Method | Status |
|---|---|---|---|---|
| GET | /complaint/complaint-categories | complaint.complaint-categories.index | ComplaintCategoryController@index | ✅ |
| GET | /complaint/complaint-categories/create | complaint.complaint-categories.create | @create | ✅ |
| POST | /complaint/complaint-categories | complaint.complaint-categories.store | @store | ✅ |
| GET | /complaint/complaint-categories/{id} | complaint.complaint-categories.show | @show | ✅ |
| GET | /complaint/complaint-categories/{id}/edit | complaint.complaint-categories.edit | @edit | ✅ |
| PUT/PATCH | /complaint/complaint-categories/{id} | complaint.complaint-categories.update | @update | ✅ |
| DELETE | /complaint/complaint-categories/{id} | complaint.complaint-categories.destroy | @destroy | ✅ |
| GET | /complaint/complaint-categories/trash/view | complaint.complaint-categories.trashed | @trashed | ✅ |
| GET | /complaint/complaint-categories/{id}/restore | complaint.complaint-categories.restore | @restore | ✅ |
| DELETE | /complaint/complaint-categories/{id}/force-delete | complaint.complaint-categories.forceDelete | @forceDelete | ✅ |
| POST | /complaint/complaint-categories/{id}/toggle-status | complaint.complaint-categories.toggleStatus | @toggleStatus | ✅ |

#### Department SLA

| Method | URI | Name | Status |
|---|---|---|---|
| CRUD resource | /complaint/department-sla | complaint.department-sla.* | ✅ |
| GET trash | /complaint/department-sla/trash/view | complaint.department-sla.trashed | ✅ |
| GET restore | /complaint/department-sla/{id}/restore | complaint.department-sla.restore | ✅ |
| DELETE force | /complaint/department-sla/{id}/force-delete | complaint.department-sla.forceDelete | ✅ |
| POST toggle | /complaint/department-sla/{id}/toggle-status | complaint.department-sla.toggleStatus | ❌ method missing |

#### Complaints Core

| Method | URI | Status |
|---|---|---|
| Standard resource CRUD | /complaint/complaints | 🟡 destroy empty |
| GET trash | /complaint/complaints/trash/view | ❌ method missing |
| GET restore | /complaint/complaints/{id}/restore | ❌ method missing |
| DELETE force | /complaint/complaints/{id}/force-delete | ❌ method missing |
| POST toggle | /complaint/complaints/{id}/toggle-status | ❌ method missing |
| GET manage | /complaint/complaints/manage | 🟡 wrong gate prefix |

#### Complaint Actions

| Method | URI | Status |
|---|---|---|
| index, store, show, destroy only | /complaint/complaint-actions | ❌ STUB |
| GET restore | /complaint/complaint-actions/{id}/restore | ❌ STUB |
| DELETE force | /complaint/complaint-actions/{id}/force-delete | ❌ STUB |

#### Medical Checks

| Method | URI | Status |
|---|---|---|
| Standard CRUD | /complaint/medical-checks | ✅ |
| Trash/restore/force | /complaint/medical-checks/... | ✅ (but softDeletes missing in migration) |

#### AI Insights

| Method | URI | Status |
|---|---|---|
| index, show, store, update | /complaint/ai-insights | ❌ STUB |
| DELETE force | /complaint/ai-insights/{id}/force-delete | ❌ STUB |

#### Reports

| Method | URI | Name | Status |
|---|---|---|---|
| GET | /complaint/reports/summary-status | complaint.reports.summary | ✅ |

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

| Screen | View File | Purpose | Status |
|---|---|---|---|
| Complaint Hub / Dashboard | `complaint/complaint/index.blade.php` | Mega combined view — dashboard KPIs + complaint list + categories + SLAs + actions + AI insights | ✅ |
| Create Complaint | `complaint/complaint/create.blade.php` | New complaint form | ✅ |
| Edit Complaint | `complaint/complaint/edit.blade.php` | Edit form with assignment, resolution fields | ✅ |
| Show Complaint | `complaint/complaint/show.blade.php` | Detail view with dropdowns resolved | ✅ |
| Complaint Trash | `complaint/complaint/trash.blade.php` | Soft-deleted complaints | ✅ |
| Complaint Manage | `complaint/complaint-manage/index.blade.php` | Management view for a single complaint | 🟡 |
| Complaint Actions | `complaint/complaint-manage/actions.blade.php` | Action timeline partial | 🟡 |
| Category Index | `complaint/category/index.blade.php` | Category list with tree structure | ✅ |
| Category Create | `complaint/category/create.blade.php` | New category form | ✅ |
| Category Edit | `complaint/category/edit.blade.php` | Edit category | ✅ |
| Category Show | `complaint/category/show.blade.php` | View category details | ✅ |
| Category Trash | `complaint/category/trash.blade.php` | Soft-deleted categories | ✅ |
| Department SLA Index | `complaint/department-sla/index.blade.php` | SLA rule list | ✅ |
| Department SLA Create | `complaint/department-sla/create.blade.php` | New SLA rule form | ✅ |
| Department SLA Edit | `complaint/department-sla/edit.blade.php` | Edit SLA rule | ✅ |
| Department SLA Show | `complaint/department-sla/show.blade.php` | View SLA rule | ✅ |
| Department SLA Trash | `complaint/department-sla/trash.blade.php` | Soft-deleted SLA rules | ✅ |
| Medical Check Index | `complaint/medical-checks/index.blade.php` | Medical check list with filters | ✅ |
| Medical Check Create | `complaint/medical-checks/create.blade.php` | New medical check form | ✅ |
| Medical Check Edit | `complaint/medical-checks/edit.blade.php` | Edit form | ✅ |
| Medical Check Show | `complaint/medical-checks/show.blade.php` | Detail view | ✅ |
| Medical Check Trash | `complaint/medical-checks/trash.blade.php` | Soft-deleted checks | ✅ |
| AI Insights Index | `complaint/ai-insights/index.blade.php` | AI insights list | ✅ (view exists) |
| Report Dashboard | `reports/index.blade.php` | Master report container | ✅ |
| Complaint Status Report | `reports/complaint-status/index.blade.php` | Status distribution | ✅ |
| Hotspot Report | `reports/hotspot/index.blade.php` | Target hotspot | ✅ |
| Pareto Report | `reports/pareto/index.blade.php` | Pareto analysis | ✅ |
| Sentiment Report | `reports/sentiment/index.blade.php` | AI sentiment bubble chart | ✅ |
| SLA Violation Report | `reports/sla-violation/index.blade.php` | SLA breach report | ✅ |

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

### BR-CMP-001: Ticket Number Format
- Format: `CMP-{YEAR}-{6-digit-serial}` (e.g., `CMP-2026-000001`)
- Serial resets each calendar year
- Generated inside a database transaction with `lockForUpdate()` to prevent race conditions
- Collision loop ensures uniqueness even under concurrent creation

### BR-CMP-002: Escalation Level Rules
- Escalation levels are time-based, not manual (unless `is_escalated=true` manually)
- Level Pending: Before `ticket_date + expected_resolution_hours`
- Level 1: After base hours; Level 2: After L1 additional hours; etc.
- Level Breached: After all 5 levels
- Resolved complaints do not have an escalation level
- Calculation is done in-memory (not stored), but `escalation_level` column exists in DB — must be kept in sync

### BR-CMP-003: Complaint Status Lifecycle
- Initial status on creation: hardcoded `sys_dropdowns.id=124` (should be 'Open' or 'Submitted')
- Valid transitions: Open → In-Progress → Resolved, Closed, Rejected
- Resolved complaints must have `actual_resolved_at` and `resolution_summary`
- Escalated complaints should have `is_escalated=true`

### BR-CMP-004: Complainant Type Rules
- `complainant_type_id=104` (External/Anonymous) → `complainant_name` required; `complainant_user_id` is null
- All other types → `complainant_user_id` required (FK to sys_users); `complainant_name` is null

### BR-CMP-005: SLA Priority Order
- Department SLA overrides Category SLA
- If no Department SLA exists for a category, Category SLA is used
- SLA due date (`resolution_due_at`) should ideally be set at complaint creation time based on category SLA

### BR-CMP-006: AI Insights Rules
- One insight record per complaint (1:1, UNIQUE constraint)
- Insight is computed synchronously on every create and update
- Model version stored as `rules-v1`
- Sentiment score is [0, 1] not [-1, 1] despite migration comment saying "-1.000 to +1.000" — engine only produces [0, 1]

### BR-CMP-007: Medical Check Linkage
- Medical check can only be created if `is_medical_check_required=true` on the complaint (enforced at business level, not DB constraint)
- Only one check per complaint per `check_type` (no DB constraint — business rule only)

### BR-CMP-008: Anonymous Complaints
- `is_anonymous=true` → complainant identity should be masked in non-admin views
- Anonymous complaints still require `complainant_type_id`

### BR-CMP-009: Image Evidence
- `complaint_img` and `medical_img` use Spatie MediaLibrary `singleFile()` collection
- Media stored with three conversions: small (100×100), medium (300×300), large (600×600) with sharpen(10)
- `support_file` boolean tracks whether a complaint has an attached image

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### 9.1 Complaint Lifecycle

```
                    ┌─────────────────────────────────────────┐
                    │         COMPLAINT REGISTRATION           │
                    └───────────────────┬─────────────────────┘
                                        │
                                        ▼
                               ┌──────────────┐
                               │   SUBMITTED  │ (status_id=124, hardcoded)
                               │   (Open)     │
                               └──────┬───────┘
                                      │ Assigned to Role/User
                                      ▼
                               ┌──────────────┐
                               │ IN-PROGRESS  │
                               └──────┬───────┘
                                      │
                     ┌────────────────┼──────────────┐
                     ▼                ▼               ▼
              ┌──────────┐    ┌───────────┐    ┌──────────┐
              │ RESOLVED │    │  CLOSED   │    │ REJECTED │
              └──────────┘    └───────────┘    └──────────┘
                     ▲
                     │ escalation timer exceeded
                     │
              ┌──────────────────────────────────────────────┐
              │           ESCALATION LEVELS                   │
              │  Pending → Level 1 → Level 2 → Level 3 →    │
              │  Level 4 → Level 5 → BREACHED                │
              └──────────────────────────────────────────────┘
```

**State Machine:**

| From State | Action | To State | Condition |
|---|---|---|---|
| Open/Submitted | Assign | In-Progress | assigned_to set |
| In-Progress | Resolve | Resolved | actual_resolved_at + resolution_summary |
| Any open | Reject | Rejected | Admin decision |
| Resolved | Reopen | In-Progress | Admin action |
| Any | Escalate | Escalated (flag) | Time-based or manual |
| Any open | Breach | Breached | All escalation timers exceeded |

### 9.2 AI Insight Generation Workflow

```
Complaint::store() or ::update()
        │
        ▼
event(new ComplaintSaved($complaint))
        │
        ▼ [synchronous, not queued]
ProcessComplaintAIInsights::handle()
        │
        ▼
ComplaintAIInsightEngine::processComplaint($complaintId)
        │
        ├─── calculateSentiment(complaint)
        │         └── Keyword match on description
        │             → sentiment_score [0,1] + label_id (hardcoded: 147/148/149/150)
        │
        ├─── calculateRiskScore(complaint, sentimentScore)
        │         └── Weighted formula:
        │             severity(35%) + frequency(30%) + sentiment(20%) + days_pending(15%)
        │             → escalation_risk_score [0,100]
        │
        ├─── calculateSafetyRisk(complaint)
        │         └── Safety keyword max-score + severity_boost + sensitivity_flag
        │             → safety_risk_score [0,100]
        │
        ├─── predictCategory(complaint)
        │         └── Returns complaint->category_id (no real prediction)
        │             → predicted_category_id
        │
        └─── AiInsight::updateOrCreate(['complaint_id'=>$id], [...scores...])
```

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| ID | Category | Requirement | Current State |
|---|---|---|---|
| NFR-001 | Performance | AI insight processing must not add >500ms to complaint create/update | Synchronous processing — may add 50–200ms; needs measurement |
| NFR-002 | Performance | Dashboard with 1000 complaints must load in <3s | Multiple N+1 queries in escalation level calculation — risk |
| NFR-003 | Security | `dd()` calls must be removed before production | 2 instances: store() catch block + filter() |
| NFR-004 | Security | Hardcoded dropdown IDs (124, 197, 202, 147–150) must be resolved dynamically | Critical for tenant portability |
| NFR-005 | Reliability | Complaint registration must not fail silently | Current catch block with `dd()` crashes; needs proper error response |
| NFR-006 | Maintainability | Duplicate escalation calculation logic must be centralized | Same logic in ComplaintController and ComplaintDashboardService |
| NFR-007 | Scalability | AI listener should be queued for high-volume schools | Currently synchronous |
| NFR-008 | Compliance | Anonymous complaints must mask complainant identity for non-admin users | Not enforced at view layer — requires implementation |
| NFR-009 | Data Integrity | Schema migration must match model `$fillable` arrays | Multiple gaps identified in Section 5.4 |
| NFR-010 | Auditability | All complaint status changes must produce action log entries | Partially broken — action_type_id resolution is buggy |

---

## 11. CROSS-MODULE DEPENDENCIES

### 11.1 This Module Depends On

| Module | Dependency | Usage |
|---|---|---|
| SchoolSetup | `sch_department` table, Department model | DepartmentSlaController::create() + report filtering |
| SchoolSetup | Designation model | DepartmentSlaController target |
| SchoolSetup | EntityGroup model | DepartmentSla escalation group mapping |
| SchoolSetup | Role model (via sys_roles) | Assignment + resolution by role |
| Transport | Vehicle model | DepartmentSla target_vehicle |
| Vendor | Vendor model | DepartmentSla target_vendor |
| Prime/GlobalMaster | Dropdown model (sys_dropdowns) | All status/type/severity/priority lookups |
| Auth/User | sys_users | Complainant, assignee, resolver, creator |
| StudentPortal | StudentPortalComplaintController | Self-service complaint via student portal |
| Notifications | `StudentPortalComplaintRegistered` notification | Sent to Super Admin on complaint creation |
| Spatie MediaLibrary | `spatie/laravel-medialibrary` | complaint_img + medical_img storage |

### 11.2 Modules That Depend on This

| Module | Dependency Type |
|---|---|
| Analytics/Reports | Could use `cmp_*` data for school performance dashboards |
| Student Portal | Portal complaint registration writes to `cmp_complaints` |
| HR & Payroll (pending) | Staff complaints about payroll could feed into this module |
| Parent Portal (pending) | Parent self-service complaints |

---

## 12. TEST CASE REFERENCE & COVERAGE

### 12.1 Existing Tests

| Test File | Location | Class | Test Methods | Coverage Area |
|---|---|---|---|---|
| ComplaintCategoryTest.php | `tests/Browser/Modules/Complaint/Category/` | ComplaintCategoryTest | Multiple (browser Dusk) | Category CRUD, schema validation, soft-delete lifecycle |
| ComplaintCrudTest.php | `tests/Browser/Modules/Complaint/Complaint/` | ComplaintCrudTest | Multiple (browser Dusk) | Complaint schema, model, destroy contract |
| DepartmentSlaCrudTest.php | `tests/Browser/Modules/Complaint/DepartmentSLA/` | DepartmentSlaCrudTest | Multiple (browser Dusk) | SLA CRUD, schema validation |
| MedicalCheckCrudTest.php | `tests/Browser/Modules/Complaint/MedicalChecks/` | MedicalCheckCrudTest | Multiple (browser Dusk) with proof screenshots | Medical check CRUD, validation, media upload |

Note: All tests are Laravel Dusk browser tests running against a live tenant environment. The `AIInsights` test directory contains only a `requirement.md` — no actual test file exists.

### 12.2 Proposed Test Plan

| # | Test Name | Type | Priority | Target |
|---|---|---|---|---|
| T-001 | Complaint store() handles exception without dd() | Feature/HTTP | Critical | ComplaintController@store |
| T-002 | Ticket number uniqueness under concurrent creation | Feature | High | ComplaintController@store |
| T-003 | Status change logs correct action_type_id | Feature | High | ComplaintController@update |
| T-004 | Escalation level calculation — time-based progression | Unit | High | DashboardService::calculateCurrentEscalationLevel |
| T-005 | AI insight created/updated on complaint save | Feature | High | ProcessComplaintAIInsights |
| T-006 | Sentiment: "harassment urgent" → score ≥ 0.30 | Unit | High | ComplaintAIInsightEngine |
| T-007 | Safety: "violence" keyword → safety_risk_score = 100 | Unit | High | ComplaintAIInsightEngine |
| T-008 | Escalation risk formula (Critical + 3 repeat = ~72) | Unit | Medium | ComplaintAIInsightEngine |
| T-009 | ComplaintAction index returns timeline in order | Feature | High | ComplaintActionController (once implemented) |
| T-010 | filter() AJAX endpoint returns JSON without dd() | Feature | Critical | ComplaintController@filter |
| T-011 | DepartmentSla toggleStatus method responds 200 | Feature | Medium | DepartmentSlaController |
| T-012 | Medical check softDelete fails gracefully (missing column) | Feature | Critical | MedicalCheckController@destroy |
| T-013 | Anonymous complaint masks complainant in non-admin view | Browser | High | complaint/complaint/show.blade.php |
| T-014 | Pareto report correct cumulative percentage | Feature | Medium | ComplaintReportController |
| T-015 | Hotspot report correct grouping | Feature | Medium | ComplaintReportController |

### 12.3 Coverage Summary

| Area | Test Coverage | Gap |
|---|---|---|
| Category CRUD | ✅ Browser tests exist | Force-delete with children; AJAX toggle |
| Department SLA CRUD | ✅ Browser tests exist | toggleStatus missing |
| Complaint Core | Partial browser tests | store exception, concurrent tickets, action logging |
| Medical Checks | ✅ Most comprehensive (with proof screenshots) | softDeletes column missing |
| AI Engine | ❌ Zero tests | All engine logic untested |
| Reports | ❌ Zero tests | 5 report methods untested |
| Dashboard | ❌ Zero tests | All KPIs untested |

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition |
|---|---|
| Ticket | A registered complaint with a unique `CMP-YYYY-NNNNNN` identifier |
| Complainant | The person raising the complaint (Student, Parent, Staff, or External) |
| Target | The person, department, vehicle, or vendor the complaint is against |
| Category / Subcategory | Two-level classification of the complaint nature |
| SLA | Service Level Agreement — time commitment for complaint resolution |
| Escalation Level | Progressive urgency state (Level 1–5, Breached) computed from ticket age vs SLA hours |
| Expected Resolution Hours | Base SLA — time from ticket creation to expected resolution |
| Escalation Hours L1–L5 | Incremental additional hours before each escalation threshold |
| Department SLA | A more specific SLA rule that overrides category defaults for a specific department/role/user target |
| Severity Level | Severity classification (Low / Medium / High / Critical) from sys_dropdowns |
| Priority Score | Business priority weight from sys_dropdowns |
| AI Insight | System-generated risk assessment attached to each complaint |
| Sentiment Score | [0, 1] float — higher = more negative/angry sentiment detected in description |
| Escalation Risk Score | [0, 100] composite score indicating likelihood the complaint will escalate further |
| Safety Risk Score | [0, 100] independent score for physical safety concerns |
| Hotspot | A target entity (person, department, vehicle) that accumulates a disproportionate share of complaints |
| Pareto Analysis | 80/20 analysis — identifies the 20% of categories causing 80% of complaints |
| Frustration Probability | Computed probability that a complainant-target pair represents genuine frustration/ongoing issue |
| Medical Check | Physical examination ordered in connection with a welfare complaint |
| Private Note | An action log note visible only to Admin/Principal, not to the complainant |
| Anonymous Complaint | A complaint where the complainant chooses not to be identified |

---

## 14. ADDITIONAL SUGGESTIONS

> The following suggestions are analyst recommendations based on code review, domain knowledge, and platform context. They are NOT derived from RBS requirements or existing code.

### 14.1 Feature Enhancements

1. **Complaint Reopening Workflow:** Once resolved, allow complainants or admins to reopen a complaint with a reason (e.g., "Resolution not satisfactory"). This addresses a common real-world scenario in Indian schools where initial resolution is incomplete.

2. **Multi-Attachment Support:** Currently only one image per complaint. Schools often need to attach multiple evidence files (photos, documents, PDFs). Convert from `singleFile()` to multi-file MediaLibrary collection.

3. **Complaint Merge:** Allow admins to merge duplicate tickets (same complainant, same target, same category) to avoid scattered data. A `merged_into_id` FK on `cmp_complaints` would support this.

4. **Bulk Status Update:** Allow admins to select multiple complaints and change status in bulk — useful for clearing resolved tickets at term end.

5. **SLA Auto-Set on Creation:** Currently `resolution_due_at` is not auto-populated on complaint creation from the SLA configuration. This should be automated: on create, query Department SLA (if exists) or Category SLA, calculate due date, and set `resolution_due_at`.

6. **Complaint Rating by Complainant:** Allow complainant to rate the resolution quality (1–5 stars) after marking resolved. This data can power the Frustration report.

### 14.2 Technical Improvements

1. **Remove `dd()` calls immediately:** At minimum two production `dd()` calls must be removed before going live — `store()` catch block (line 407) and `filter()` (line 833). Replace with proper HTTP error responses and logging.

2. **Implement FormRequests:** Create `StoreComplaintRequest` and `UpdateComplaintRequest` Form Request classes. The current inline validation in `store()` is 30+ lines and fragile. This also enables pre-authorization and cleaner controller code.

3. **Resolve Hardcoded IDs:** Replace `status_id=124`, `action_type_id=197/202`, and sentiment label IDs `147/148/149/150` with dynamic lookups from `sys_dropdowns` using the `key` field. Consider a `ComplaintDropdownEnum` or config seeder.

4. **Queue the AI Listener:** `ProcessComplaintAIInsights` should implement `ShouldQueue` to avoid blocking the HTTP response. Schools with many concurrent complaint submissions will see latency issues.

5. **Centralize Escalation Calculation:** The escalation level calculation is duplicated in `ComplaintController::getComplaintsWithEscalation()` and `ComplaintDashboardService::calculateCurrentEscalationLevel()`. Extract to a dedicated `EscalationService` or a method on the `Complaint` model.

6. **Fix Schema vs Model Gaps:** Add the missing columns (`target_department_id`, `target_designation_id`, `target_entity_group_id`, `target_vehicle_id`, `target_vendor_id`) to the `cmp_department_sla` migration, OR remove them from the model `$fillable`. Add `deleted_at` to `cmp_medical_checks`.

7. **Implement ComplaintActionController:** This is the action/timeline audit log — currently a boilerplate stub. The model and table are fully defined; only the controller logic and proper views are missing.

8. **Implement AiInsightController:** The AI insight index view exists; the controller needs real index/show logic to display per-complaint insight scores.

9. **Fix `destroy()` on Complaint:** The method is empty — soft delete is not implemented. Add `$complaint->delete()` logic with proper authorization.

10. **Fix Gate Prefix Inconsistency:** `ComplaintController::manage()` uses `Gate::authorize('prime.complaint.manage')` while all other gates use `tenant.` prefix — this will always fail or allow unintended access depending on gate registration.

### 14.3 UX/UI Improvements

1. **Complaint Status Badge:** The status dropdown ID is queried from `sys_dropdowns` per complaint in the index view — consider caching or eager loading for the list view to avoid N+1 queries.

2. **Escalation Indicator on List:** Show a color-coded escalation level badge on the complaint list (Green=Pending, Yellow=Level 1–2, Orange=Level 3–4, Red=Level 5/Breached).

3. **AI Risk Indicator:** Show a small risk icon (low/medium/high/critical) on the complaint list derived from `escalation_risk_score`.

4. **Timeline View in Show Page:** The `complaint-manage/actions.blade.php` partial exists but is not integrated into the show page. The timeline is one of the most valuable views for admin complaint management.

5. **Dashboard Date Range Picker:** The `filter()` AJAX endpoint is broken. Once fixed, a Bootstrap date-range picker on the dashboard would allow admins to analyze trends over custom periods.

### 14.4 Integration Opportunities

1. **SMS/Email Notifications:** On complaint creation and status change, send notifications to the complainant. The platform uses notifications (`StudentPortalComplaintRegistered` already exists) — extend to status-change and resolution notifications.

2. **Notification Module Integration:** Link with the existing Notifications module to push complaint updates as in-app notifications to assigned users and complainants.

3. **HR & Payroll (when built):** Staff-related complaints could automatically populate an HR flag for performance review consideration.

4. **WhatsApp/Email Acknowledgement:** Send an automated acknowledgement with ticket number to the complainant's registered contact when complaint is created.

5. **Academic Calendar Integration:** Complaints during examination periods could be flagged automatically for priority handling.

### 14.5 Indian Education Domain Suggestions

1. **CBSE/NCERT Compliance Flags:** Indian schools must maintain records of complaints related to corporal punishment, sexual harassment (POCSO Act), and child abuse. Add a `is_pocso_reportable` boolean and `is_corporal_punishment` flag to `cmp_complaints`. These complaints should have mandatory escalation to Principal and auto-notification to management.

2. **Complaint Categories Seeder:** Seed common Indian school complaint categories out-of-the-box: Academic (Syllabus, Exam, Result), Infrastructure (Toilet, Canteen, Transport), Behavioral (Bullying, Corporal Punishment, Harassment), Staff Conduct, Health & Safety, Fee Related.

3. **Parent-Teacher Meeting (PTM) Complaint Tracking:** Complaints raised during PTMs should be tagged with a `ptm_session_id`. Many Indian schools have recurring unresolved complaints surfacing at PTMs — this data helps administration identify systemic issues.

4. **Grievance Redressal Policy Compliance:** CBSE mandates a Grievance Redressal Committee. The module could generate a committee-ready report showing unresolved complaints >30 days for any monthly committee review.

5. **Language Support:** Complaint descriptions in regional languages (Hindi, Marathi, Tamil, etc.) are common. The AI engine's keyword list is entirely English — a multi-lingual keyword list or transliteration support would significantly improve sentiment accuracy for Indian schools.

6. **RTE Act Tracking:** Complaints related to RTE (Right to Education Act) non-compliance — denial of admission, discrimination, inadequate facilities — should have a dedicated `rte_complaint` flag and separate escalation chain to the district education office.

---

## 15. APPENDICES

### Appendix A — Full RBS Extract (Module D3)

```
## Module D — Front Office & Communication

### D3 — Complaint & Feedback Management (6 sub-tasks)

**F.D3.1 — Complaint Handling**
- *T.D3.1.1 — Register Complaint*
  - ST.D3.1.1.1  Enter complaint details
  - ST.D3.1.1.2  Assign complaint to staff
- *T.D3.1.2 — Complaint Resolution*
  - ST.D3.1.2.1  Update resolution status
  - ST.D3.1.2.2  Add resolution notes

**F.D3.2 — Feedback Collection**
- *T.D3.2.1 — Collect Feedback*
  - ST.D3.2.1.1  Create feedback form
  - ST.D3.2.1.2  Collect responses
```

**RBS Coverage by this module:**
- F.D3.1 fully: ✅ (complaint management) with significant extensions beyond RBS
- F.D3.2: ❌ Not implemented (feedback forms/responses)

### Appendix B — Complete Route Table

All routes under prefix `/complaint`, name prefix `complaint.`, middleware `['auth','verified']`:

```
GET    /complaint/complaint-mgt                              complaint.complaint-mgt.index
GET    /complaint/complaint-mgt/create                       complaint.complaint-mgt.create
POST   /complaint/complaint-mgt                              complaint.complaint-mgt.store
GET    /complaint/complaint-mgt/{id}                         complaint.complaint-mgt.show
GET    /complaint/complaint-mgt/{id}/edit                    complaint.complaint-mgt.edit
PUT    /complaint/complaint-mgt/{id}                         complaint.complaint-mgt.update
DELETE /complaint/complaint-mgt/{id}                         complaint.complaint-mgt.destroy
GET    /complaint/dashboard-data                             complaint.dashboard.data
GET    /complaint/dashboard/donut/severity-vs-department     (no name)
GET    /complaint/dashboard/donut/department-vs-severity     (no name)
GET    /complaint/dashboard/donut/department-status          (no name)
GET    /complaint/complaint-categories                       complaint.complaint-categories.index
GET    /complaint/complaint-categories/create                complaint.complaint-categories.create
POST   /complaint/complaint-categories                       complaint.complaint-categories.store
GET    /complaint/complaint-categories/{id}                  complaint.complaint-categories.show
GET    /complaint/complaint-categories/{id}/edit             complaint.complaint-categories.edit
PUT    /complaint/complaint-categories/{id}                  complaint.complaint-categories.update
DELETE /complaint/complaint-categories/{id}                  complaint.complaint-categories.destroy
GET    /complaint/complaint-categories/trash/view            complaint.complaint-categories.trashed
GET    /complaint/complaint-categories/{id}/restore          complaint.complaint-categories.restore
DELETE /complaint/complaint-categories/{id}/force-delete     complaint.complaint-categories.forceDelete
POST   /complaint/complaint-categories/{id}/toggle-status    complaint.complaint-categories.toggleStatus
GET    /complaint/department-sla                             complaint.department-sla.index
GET    /complaint/department-sla/create                      complaint.department-sla.create
POST   /complaint/department-sla                             complaint.department-sla.store
GET    /complaint/department-sla/{id}                        complaint.department-sla.show
GET    /complaint/department-sla/{id}/edit                   complaint.department-sla.edit
PUT    /complaint/department-sla/{id}                        complaint.department-sla.update
DELETE /complaint/department-sla/{id}                        complaint.department-sla.destroy
GET    /complaint/department-sla/trash/view                  complaint.department-sla.trashed
GET    /complaint/department-sla/{id}/restore                complaint.department-sla.restore
DELETE /complaint/department-sla/{id}/force-delete           complaint.department-sla.forceDelete
POST   /complaint/department-sla/{id}/toggle-status          complaint.department-sla.toggleStatus  [METHOD MISSING]
GET    /complaint/complaints                                  complaint.complaints.index
GET    /complaint/complaints/create                           complaint.complaints.create
POST   /complaint/complaints                                  complaint.complaints.store
GET    /complaint/complaints/{id}                            complaint.complaints.show
GET    /complaint/complaints/{id}/edit                        complaint.complaints.edit
PUT    /complaint/complaints/{id}                            complaint.complaints.update
DELETE /complaint/complaints/{id}                            complaint.complaints.destroy  [EMPTY METHOD]
GET    /complaint/complaints/trash/view                       complaint.complaints.trashed  [METHOD MISSING]
GET    /complaint/complaints/{id}/restore                     complaint.complaints.restore  [METHOD MISSING]
DELETE /complaint/complaints/{id}/force-delete               complaint.complaints.forceDelete [METHOD MISSING]
POST   /complaint/complaints/{id}/toggle-status              complaint.complaints.toggleStatus [METHOD MISSING]
GET    /complaint/complaints/manage                           complaint.complaints.manage
GET    /complaint/complaint-actions                           complaint.complaint-actions.index  [STUB]
POST   /complaint/complaint-actions                           complaint.complaint-actions.store  [STUB]
GET    /complaint/complaint-actions/{id}                     complaint.complaint-actions.show   [STUB]
DELETE /complaint/complaint-actions/{id}                     complaint.complaint-actions.destroy [STUB]
GET    /complaint/complaint-actions/{id}/restore              complaint.complaint-actions.restore [STUB]
DELETE /complaint/complaint-actions/{id}/force-delete        complaint.complaint-actions.forceDelete [STUB]
GET    /complaint/medical-checks                             complaint.medical-checks.index
GET    /complaint/medical-checks/create                      complaint.medical-checks.create
POST   /complaint/medical-checks                             complaint.medical-checks.store
GET    /complaint/medical-checks/{id}                        complaint.medical-checks.show
GET    /complaint/medical-checks/{id}/edit                   complaint.medical-checks.edit
PUT    /complaint/medical-checks/{id}                        complaint.medical-checks.update
DELETE /complaint/medical-checks/{id}                        complaint.medical-checks.destroy
GET    /complaint/medical-checks/trash/view                  complaint.medical-checks.trashed
GET    /complaint/medical-checks/{id}/restore                complaint.medical-checks.restore
DELETE /complaint/medical-checks/{id}/force-delete           complaint.medical-checks.forceDelete
GET    /complaint/ai-insights                                complaint.ai-insights.index   [STUB]
POST   /complaint/ai-insights                                complaint.ai-insights.store   [STUB]
GET    /complaint/ai-insights/{id}                           complaint.ai-insights.show    [STUB]
PUT    /complaint/ai-insights/{id}                           complaint.ai-insights.update  [STUB]
DELETE /complaint/ai-insights/{id}/force-delete              complaint.ai-insights.forceDelete [STUB]
GET    /complaint/reports/summary-status                     complaint.reports.summary
```

Also (Student Portal, under different middleware):
```
GET/POST/PUT/DELETE /complaint                               StudentPortalComplaintController
GET    /complaint/ajax/subcategories/{category}              complaint.subCategories
GET    /complaint/ajax/subcategory-meta/{category}           complaint.categoryMeta
```

### Appendix C — Code Inventory

| Type | File | Status | Lines ~|
|---|---|---|---|
| Controller | ComplaintController.php | Partial | 925 |
| Controller | ComplaintCategoryController.php | Complete | 319 |
| Controller | DepartmentSlaController.php | Complete | 225 |
| Controller | MedicalCheckController.php | Complete | 271 |
| Controller | ComplaintReportController.php | Complete | 539 |
| Controller | ComplaintActionController.php | Stub | 57 |
| Controller | AiInsightController.php | Stub | 57 |
| Controller | ComplaintDashboardController.php | Stub | 57 |
| Service | ComplaintAIInsightEngine.php | Complete | 199 |
| Service | ComplaintDashboardService.php | Complete | 515 |
| Model | Complaint.php | Complete | 257 |
| Model | ComplaintCategory.php | Complete | 120 |
| Model | DepartmentSla.php | Complete | 180 |
| Model | ComplaintAction.php | Complete | 92 |
| Model | MedicalCheck.php | Complete | 96 |
| Model | AiInsight.php | Complete | 70 |
| Event | ComplaintSaved.php | Complete | 20 |
| Listener | ProcessComplaintAIInsights.php | Complete | 22 |
| Policy | 7 policy files | Complete | — |
| Provider | ComplaintServiceProvider.php, EventServiceProvider.php, RouteServiceProvider.php | Complete | — |
| Migration | 6 migration files | Complete (with gaps) | — |
| View | 21 blade views + 2 layouts + report views | Complete | — |
| Route | routes/tenant.php lines 1187–1344 | Active | — |
| Test | ComplaintCategoryTest.php | Active | — |
| Test | ComplaintCrudTest.php | Active | — |
| Test | DepartmentSlaCrudTest.php | Active | — |
| Test | MedicalCheckCrudTest.php | Active (with proof screenshots) | — |

### Appendix D — Test Listing

**Active Browser Tests:**

1. `/tests/Browser/Modules/Complaint/Category/ComplaintCategoryTest.php`
   - Routes tested: CREATE_PATH, INDEX_PATH, TRASH_PATH, SHOW_BASE, TOGGLE_BASE
   - Tenant: Dusk test environment (DUSK_TENANT_URL env)
   - Method tested: schema validation, CRUD lifecycle

2. `/tests/Browser/Modules/Complaint/Complaint/ComplaintCrudTest.php`
   - Routes tested: CREATE_PATH, INDEX_PATH, LISTING_PATH, SHOW_BASE_PATH
   - Notable: References CONTROLLER_FILE path for file-existence checks
   - Method tested: schema/model contract + destroy stub verification

3. `/tests/Browser/Modules/Complaint/DepartmentSLA/DepartmentSlaCrudTest.php`
   - Routes tested: CREATE_PATH, INDEX_PATH, TRASH_PATH, SHOW_BASE_PATH
   - Migration file reference: `2025_12_25_062953_create_department_slas_table.php`
   - Method tested: schema validation, CRUD lifecycle

4. `/tests/Browser/Modules/Complaint/MedicalChecks/MedicalCheckCrudTest.php`
   - Routes tested: CREATE_PATH, INDEX_PATH, TRASH_PATH, SHOW_BASE_PATH
   - Proof screenshots in `/proof/screenshots/` directory
   - Most comprehensive — includes: schema, model config, required-field validation (4 fields), image upload, soft-delete lifecycle
   - Status report methodology: proof .md files generated per test run
   - Tests confirmed passing: database schema correct, create with image, create without image, validation failures for missing complaint/check_type/result/conducted_at, show page display, edit prefill, soft-delete → restore → force-delete flow

**Pending (requirement.md only, no test file):**
- `/tests/Browser/Modules/Complaint/AIInsights/` — requirement.md exists, no test file

---

*Document generated by Claude Code — Automated Requirement Extraction*
*Source files read: 8 controllers, 6 models, 2 services, 1 event, 1 listener, 6 migrations, 1 event provider, routes/tenant.php (lines 1187–1344), 4 browser test files, RBS lines 2134–2202*
*Last verified against codebase: 2026-03-25*
