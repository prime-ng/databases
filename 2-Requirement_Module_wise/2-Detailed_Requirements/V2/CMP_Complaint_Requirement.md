# CMP — Complaint Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

The Complaint module provides a structured, SLA-driven grievance management system for Indian K-12 schools on the Prime-AI platform. It enables students, parents, staff, and administrators to register, track, escalate, and resolve complaints through a transparent ticket lifecycle, with an embedded AI Insight Engine performing rule-based sentiment analysis, escalation-risk scoring, and safety-risk scoring on every complaint.

**V2 focus:** This document supersedes V1 by incorporating all 41 issues identified in the 2026-03-22 deep gap analysis, reconciling schema discrepancies between tenant_db_v2.sql DDL and the Laravel model layer, and defining a clear remediation path for the 8 P0 critical blockers that prevent production deployment.

**Overall implementation status: ~40%**
- Schema + models + supporting services: broadly complete (with significant naming mismatches)
- Core complaint management: `dd()` calls in production paths, empty `destroy()`, zero FormRequests, hardcoded dropdown IDs, missing pagination, 3 stub controllers — NOT production-ready

**Gap analysis score: 4.0/10** (Controller Quality 3/10, FormRequest 1/10, Test Coverage 0/10, Security 3/10)

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools handle a wide spectrum of grievances: parents complaining about teacher conduct, students reporting bullying, transport complaints about rash driving, hostel issues, infrastructure failures, and welfare concerns. Without a structured system these are handled informally — often lost, mishandled, or forgotten with no accountability trail.

The Complaint module provides:
1. **Structured registration** — every complaint receives a unique ticket number (`CMP-YYYY-000001`), is classified under a category/subcategory, assigned severity and priority from the category master, and tied to a specific target (person, department, vehicle, vendor, facility, or event).
2. **SLA enforcement** — each category carries a default expected resolution time and five escalation thresholds. Department-specific SLA rules can override category defaults for targeted entities.
3. **Audit trail** — every state change (creation, assignment, status change, resolution, note) is logged to `cmp_complaint_actions`.
4. **Medical check linkage** — physical welfare complaints (suspected substance abuse, injury) can require medical checks with result documentation and evidence upload via Spatie MediaLibrary.
5. **AI insights** — the embedded rule-based engine scores every complaint for sentiment, escalation risk (0–100), and safety risk (0–100); these scores power the dashboard and reports.
6. **Analytics and reporting** — dashboard KPIs, escalation heatmap, Pareto analysis, SLA violation report, complainant hotspot, and AI risk/sentiment bubble chart.

### 2.2 Key Features Summary

| Feature Area | RBS Ref | Status |
|---|---|---|
| Category Management (hierarchical + 5-level SLA) | F.D3.1 | 🟡 Partial — column name mismatches vs DDL |
| Department SLA Configuration | F.D3.1 | 🟡 Partial — target columns present in DDL, missing from V1 model |
| Complaint Registration + Auto-Ticket Number | T.D3.1.1 | 🟡 Partial — `dd()` in catch, hardcoded status_id, no FormRequest |
| Complaint Assignment to Role/User | T.D3.1.1.2 | 🟡 Partial — works but action logging broken |
| Complaint Resolution + Status Management | T.D3.1.2 | 🟡 Partial — update works; hardcoded action IDs |
| Complaint Action / Timeline Audit Log | T.D3.1.2 | ❌ Stub controller — no real logic |
| Auto-Resolution-Due-At on Create | T.D3.1.1 | ❌ Not implemented |
| Scheduled Escalation Job | Beyond RBS | ❌ Not started |
| Medical Check Management | Beyond RBS | ✅ Complete (minor schema gaps) |
| AI Insight Engine (rule-based) | Beyond RBS | ✅ Engine complete; ❌ Controller stub |
| Dashboard + AJAX Charts | Beyond RBS | ✅ Service complete; 🟡 filter() has dd() |
| Reports (5 report types) | Beyond RBS | ✅ Implemented |
| Student/Parent Portal Submission | F.D3.1 | 🟡 Partial (in StudentPortal module) |
| Feedback Collection | F.D3.2 | ❌ Not started |

### 2.3 Menu Navigation Path

```
School Admin Panel
└── Complaint [/complaint]
    ├── Dashboard         [/complaint/complaint-mgt]  (combined hub)
    ├── Categories        [/complaint/complaint-categories]
    ├── Department SLAs   [/complaint/department-sla]
    ├── Complaints        [/complaint/complaints]
    ├── Complaint Actions [/complaint/complaint-actions]
    ├── Medical Checks    [/complaint/medical-checks]
    ├── AI Insights       [/complaint/ai-insights]
    └── Reports           [/complaint/reports/summary-status]
```

### 2.4 Module Architecture

```
Modules/Complaint/
├── app/
│   ├── Events/ComplaintSaved.php              # Fired on create + update
│   ├── Http/Controllers/
│   │   ├── AiInsightController.php            # ❌ STUB
│   │   ├── ComplaintActionController.php      # ❌ STUB
│   │   ├── ComplaintCategoryController.php    # ✅ Complete
│   │   ├── ComplaintController.php            # 🟡 Partial (dd(), empty destroy, no FormRequest)
│   │   ├── ComplaintDashboardController.php   # ❌ STUB
│   │   ├── ComplaintReportController.php      # ✅ Complete
│   │   ├── DepartmentSlaController.php        # ✅ Complete (missing toggleStatus)
│   │   └── MedicalCheckController.php         # ✅ Complete
│   ├── Listeners/ProcessComplaintAIInsights.php  # ✅ Synchronous (not queued)
│   ├── Models/ (6 models — with naming mismatches vs DDL)
│   ├── Policies/ (7 policies — ComplaintPolicy.create() has wrong permission)
│   ├── Providers/ (ComplaintServiceProvider, EventServiceProvider, RouteServiceProvider)
│   └── Services/
│       ├── ComplaintAIInsightEngine.php       # ✅ Rule-based engine
│       └── ComplaintDashboardService.php      # ✅ Dashboard KPIs + donuts
├── database/migrations/ (6 migrations — mismatched column names vs DDL)
├── resources/views/ (28 blade views)
└── routes/api.php + web.php
```

---

## 3. Stakeholders & Roles

| Actor | Role in Module | Key Permissions |
|---|---|---|
| School Admin | Full access: configure categories, SLAs, manage all complaints, reports | All CRUD + manage |
| Principal | View all complaints, manage escalations, approve resolutions | view, update, manage |
| HOD / Teacher | View complaints in their department, update assigned complaints | view-own-dept, update-assigned |
| Student | Register complaint via Student Portal only | create (own) |
| Parent | Register complaint via Student Portal only | create (own) |
| Staff Member | Register complaint; appear as target or complainant | create |
| Front Office Staff | Register complaints on behalf of walk-in complainants | create, update |
| System (automated) | Auto-generate ticket number, fire AI insights, log system actions | internal |

**Permission gate prefix:** `tenant.complaint.*` (NOTE: `ComplaintPolicy::create()` currently uses wrong gate `tenant.vendor-dahsboard.create` — critical bug PL-01)

---

## 4. Functional Requirements

---

### FR-CMP-001: Complaint Category Management
**RBS:** F.D3.1 | **Priority:** Critical | **Status:** 🟡 Partial (column name mismatches)
**Tables:** `cmp_complaint_categories`

#### REQ-CMP-001.1: Create Complaint Category
| Attribute | Detail |
|---|---|
| Description | Admin creates a complaint category (optionally nested under a parent) with SLA timelines and per-level escalation entity groups |
| Actors | School Admin |
| Preconditions | `tenant.complaint-category.create` permission |
| Input | name (required, max 100), code (optional, unique), description (max 512), severity_level_id (FK→sys_dropdown_table), priority_score_id (FK→sys_dropdown_table), default_expected_resolution_hours (required, min 1), default_escalation_hours_l1–l5 (each ascending), default_escalation_l1–l5_entity_group_id (optional, FK→sys_groups), is_medical_check_required (boolean), parent_id (optional, self-ref) |
| Processing | Validate ascending hour rules (l2 > l1 > expected_hours etc.); create record; log activity |
| Output | Redirect to category list with success flash |
| Status | ✅ Controller logic complete |

**🆕 V2 Schema Fix Required:** DDL columns are `default_expected_resolution_hours` and `default_escalation_hours_l1..l5` — model and migrations use `expected_resolution_hours` and `escalation_hours_l1..l5` (without `default_` prefix). Also DDL has `default_escalation_l1..l5_entity_group_id` columns; model fillable is missing these. All must be reconciled before the next migration.

#### REQ-CMP-001.2: Edit / Update / Toggle Status
| Attribute | Detail |
|---|---|
| Description | Modify category including active/inactive toggle via AJAX; deactivate before soft-delete |
| Input | All create fields + is_active |
| Output | Redirect with success; AJAX toggle returns `{ success, is_active, message }` |
| Status | ✅ |

#### REQ-CMP-001.3: Soft Delete / Trash / Restore / Force Delete
| Attribute | Detail |
|---|---|
| Description | Soft-delete (deactivates first); view trash; restore; force-delete blocked if category has children |
| Processing | `is_active=false` then `delete()`; force-delete checks children via `parent_id` |
| Status | ✅ Logic complete |

**🆕 V2 Schema Fix:** DDL `cmp_complaint_categories` has NO `deleted_at` column. The model uses `SoftDeletes` trait — this will fail at runtime. Migration must add `deleted_at TIMESTAMP NULL DEFAULT NULL`. Also missing `created_by` column.

**Acceptance Criteria:**
- [x] Category created and appears in list
- [x] Escalation hours are validated ascending (l1 < l2 < ... < l5)
- [x] Category with children cannot be force-deleted
- [ ] `default_` column name prefix reconciled in model + migration
- [ ] `deleted_at` column added to DDL / migration
- [ ] `default_escalation_l1..l5_entity_group_id` added to model fillable

---

### FR-CMP-002: Department SLA Configuration
**RBS:** F.D3.1 (extended) | **Priority:** Critical | **Status:** 🟡 Partial
**Tables:** `cmp_department_sla`

#### REQ-CMP-002.1: Create Department SLA Rule
| Attribute | Detail |
|---|---|
| Description | Define department-level SLA overriding category defaults; maps category (+ optional subcategory) to a responsible target entity (department, designation, role, entity group, user, vehicle, or vendor) with 5-level escalation hours and escalation entity groups |
| Actors | School Admin |
| Input | complaint_category_id (required), complaint_subcategory_id (optional), target_department_id / target_designation_id / target_role_id / target_entity_group_id / target_user_id / target_vehicle_id / target_vendor_id (at least one), dept_expected_resolution_hours, dept_escalation_hours_l1–l5 (ascending), escalation_l1–l5_entity_group_id (optional) |
| Processing | Validate ascending hours; create record |
| Status | 🟡 Controller complete; V1 model `$fillable` was missing target columns now confirmed in DDL |

**🆕 V2 Correction:** The V1 document claimed target columns (`target_department_id`, `target_designation_id`, `target_entity_group_id`, `target_vehicle_id`, `target_vendor_id`) were "not in the migration." The canonical DDL (tenant_db_v2.sql) DOES contain all these columns. The gap was in the Laravel migration file (Laravel migration must be updated to match DDL). Model `$fillable` and relationships are correct. Also: DDL has NO `deleted_at` on `cmp_department_sla` — model uses SoftDeletes → migration must add it.

#### REQ-CMP-002.2: Edit / Update / Delete SLA Rule
| Attribute | Detail |
|---|---|
| Description | Full lifecycle with soft-delete, trash, restore, force-delete |
| Status | ✅ |

**🆕 V2 Fix Required:** `DepartmentSlaController` is missing `toggleStatus()` method — route is declared but will return 404. Must be implemented.

**Acceptance Criteria:**
- [x] SLA rule created with ascending escalation hours
- [ ] `toggleStatus()` implemented in controller
- [ ] `deleted_at` added to migration for `cmp_department_sla`
- [ ] Laravel migration file reconciled with canonical DDL

---

### FR-CMP-003: Complaint Registration
**RBS:** T.D3.1.1 | **Priority:** Critical | **Status:** 🟡 Partial
**Tables:** `cmp_complaints`, `cmp_complaint_actions`

#### REQ-CMP-003.1: Register New Complaint (ST.D3.1.1.1)
| Attribute | Detail |
|---|---|
| Description | Create a new complaint ticket with auto-generated ticket number, complainant details, target specification, classification, and optional image evidence |
| Actors | School Admin, Front Office Staff, Student (via Portal) |
| Preconditions | Categories exist; `tenant.complaint.create` permission |
| Input | complainant_type_id (required), complainant_user_id or complainant_name (conditional), target_user_type_id (required), target_table_name, target_selected_id, target_code, target_name, category_id (required), subcategory_id (optional), title (required, max 200), description (text), location_details, incident_date, incident_time, source_id, is_anonymous, complaint_img (file, optional) |
| Auto-populated | severity_level_id and priority_score_id fetched from the selected category; is_medical_check_required fetched from category; resolution_due_at calculated from Department SLA (or Category SLA fallback) |
| Ticket Number | `CMP-{YEAR}-{6-digit-padded-serial}` generated in DB transaction with `lockForUpdate()` and collision check |
| Processing | 1) FormRequest validation; 2) Auto-populate severity/priority/medical_check from category; 3) Calculate resolution_due_at; 4) Generate ticket_no; 5) Set status_id dynamically (lookup 'Open' in sys_dropdown_table by key); 6) Create record; 7) Upload image via Spatie MediaLibrary; 8) Log 'Created' action; 9) Fire ComplaintSaved event → AI pipeline; 10) Notify Super Admin |
| Output | Redirect to complaint list with ticket number in success message |
| Status | 🟡 Functional but: `dd()` in catch block (CT-03), hardcoded status_id=124 (CT-05), no FormRequest (CT-01), missing auto-populate from category |

#### REQ-CMP-003.2: Assign Complaint to Staff (ST.D3.1.1.2)
| Attribute | Detail |
|---|---|
| Description | Admin assigns open complaint to a role and/or user; system logs assignment action with correct action_type_id |
| Input | assigned_to_role_id, assigned_to_user_id, resolution_due_at (override) |
| Processing | Update complaint; log 'Assigned' action (action_type_id resolved dynamically by key 'cmp_complaint_actions.action_type'); fire ComplaintSaved event |
| Status | 🟡 Works but action_type_id is hardcoded=197; update() uses Builder object instead of ->value('id') (CT-17) |

**📐 Proposed: StoreComplaintRequest and UpdateComplaintRequest FormRequest classes**
- `StoreComplaintRequest`: validate all create fields; conditional rule — if complainant_type is anonymous/external, complainant_name required + complainant_user_id must be null; authorize via `tenant.complaint.create`
- `UpdateComplaintRequest`: validate update fields; authorize based on ownership + role; handle resolution fields conditional on status

**📐 Proposed: Auto-populate from Category on Store**
- When category_id is provided, fetch severity_level_id and priority_score_id from `cmp_complaint_categories`
- Fetch is_medical_check_required from category
- Calculate resolution_due_at: query `cmp_department_sla` for matching category + target; fall back to `default_expected_resolution_hours` from category

**Critical Bugs to Fix (P0):**
1. `dd($e->getMessage(), $e->getTraceAsString())` at ComplaintController line 407 — crashes production on any store() error → replace with `Log::error()` + return error response
2. `dd('FILTER HIT', request()->all())` at ComplaintController line 833 — AJAX filter always dies → remove and implement filter logic
3. `status_id=124` hardcoded → replace with `DB::table('sys_dropdown_table')->where('key', 'cmp_complaints.status.open')->value('id')`
4. `action_type_id` set to Builder object instead of scalar → add `->value('id')` to all raw query chains
5. `ComplaintPolicy::create()` checks `tenant.vendor-dahsboard.create` → fix to `tenant.complaint.create`
6. `destroy()` is empty → implement soft-delete with Gate::authorize + `$complaint->delete()`

**Acceptance Criteria:**
- [ ] No `dd()` calls anywhere in production code paths
- [ ] StoreComplaintRequest and UpdateComplaintRequest FormRequest classes exist
- [ ] `status_id` resolved dynamically from sys_dropdown_table by key
- [ ] `action_type_id` resolved dynamically (not hardcoded)
- [ ] Ticket number is globally unique within a tenant for the year
- [x] AI insight created on complaint store via event/listener
- [x] Notification sent to Super Admin on creation
- [ ] `resolution_due_at` auto-calculated on create from SLA rules
- [ ] `destroy()` method implements soft-delete

---

### FR-CMP-004: Complaint Resolution & Status Management
**RBS:** T.D3.1.2 | **Priority:** Critical | **Status:** 🟡 Partial
**Tables:** `cmp_complaints`, `cmp_complaint_actions`

#### REQ-CMP-004.1: Update Resolution Status (ST.D3.1.2.1)
| Attribute | Detail |
|---|---|
| Description | Update complaint status through the defined lifecycle |
| Actors | School Admin, Assigned User/Role |
| Input | status_id (FK→sys_dropdown_table key resolution), is_escalated (boolean) |
| Processing | Update status; fire ComplaintSaved event; log action with dynamically resolved action_type_id |
| Status | 🟡 update() works; action logging broken (CT-17) |

#### REQ-CMP-004.2: Add Resolution Notes (ST.D3.1.2.2)
| Attribute | Detail |
|---|---|
| Description | Add resolution summary when marking a complaint resolved |
| Input | resolution_summary (text, required when status=Resolved), resolved_by_role_id, resolved_by_user_id, actual_resolved_at |
| Status | 🟡 Works; hardcoded action_type_id=202 must be resolved dynamically |

#### REQ-CMP-004.3: Escalation Level Calculation
| Attribute | Detail |
|---|---|
| Description | Determine current escalation level based on time elapsed since ticket_date vs category escalation thresholds |
| Calculation | Compare now() against cumulative hours: base=Level 1, +l1=Level 2, +l2=Level 3, +l3=Level 4, +l4=Level 5, +l5=Breached |
| Status | 🟡 Logic works; duplicated in ComplaintController and ComplaintDashboardService |

**📐 Proposed: Extract to EscalationService**
Create `app/Services/EscalationService.php` with:
- `calculateLevel(Complaint $complaint): int` — single source of truth for escalation level
- `getBreachTime(Complaint $complaint): Carbon` — next escalation threshold datetime
- Used by both controller and dashboard service to eliminate duplication

**Acceptance Criteria:**
- [ ] Status change logged in cmp_complaint_actions with correct (non-hardcoded) action_type_id
- [x] Resolved complaint shows actual_resolved_at and resolution_summary
- [ ] Escalation calculation logic centralized in one service/method
- [ ] `current_escalation_level` column in DB kept in sync on status changes

---

### FR-CMP-005: Complaint Action / Timeline Log
**RBS:** T.D3.1.2 (audit trail) | **Priority:** Critical | **Status:** ❌ Not Started
**Tables:** `cmp_complaint_actions`

#### REQ-CMP-005.1: View Complaint Timeline
| Attribute | Detail |
|---|---|
| Description | Display chronological log of all actions taken on a complaint (creation, assignment, status changes, resolution, notes, escalations) |
| Actors | School Admin, Principal, Assigned Staff |
| Processing | Query `cmp_complaint_actions` ordered by `action_timestamp ASC`; eager-load actionType, performedByUser, performedByRole, assignedToUser, assignedToRole; filter private notes for non-admin users |
| Status | ❌ `ComplaintActionController` is boilerplate stub; `actions.blade.php` view exists but controller returns wrong view |

#### REQ-CMP-005.2: Add Manual Action / Note
| Attribute | Detail |
|---|---|
| Description | Admin/Staff can manually add notes or actions to a complaint timeline |
| Input | complaint_id, action_type_id (FK→sys_dropdown_table), notes (text), is_private_note (boolean) |
| Processing | Validate; create `cmp_complaint_actions` record with performed_by_user_id = auth user id + performed_by_role_id |
| Status | ❌ `store()` method is empty stub |

**📐 Proposed: Implement ComplaintActionController fully**
- `index(Complaint $complaint)` → paginated timeline for a specific complaint
- `store(StoreComplaintActionRequest $request)` → create action record
- `destroy(ComplaintAction $action)` → soft-delete (requires `deleted_at` in DDL — currently missing)
- Private note toggle: `is_private_note=true` items filtered from non-admin responses

**🆕 V2 Schema Note:** DDL `cmp_complaint_actions` has `action_timestamp` (not `created_at`), no `updated_at`, no `deleted_at`, no `is_active`, no `created_by`. The model uses `updated_at` and SoftDeletes which will fail. Migration must reconcile with DDL or DDL extended.

**Acceptance Criteria:**
- [ ] Timeline shows all actions in chronological order by action_timestamp
- [ ] Private notes hidden from non-admin users
- [ ] store() creates correct ComplaintAction record with performed_by user
- [ ] logAction() uses Eloquent model — not raw DB::table() insert

---

### FR-CMP-006: Medical Check Management
**RBS:** Beyond RBS (school welfare) | **Priority:** Medium | **Status:** ✅ Mostly complete
**Tables:** `cmp_medical_checks`

#### REQ-CMP-006.1: Create Medical Check Record
| Attribute | Detail |
|---|---|
| Description | Link a medical examination to a complaint where physical welfare is suspected |
| Actors | School Admin, Medical Staff |
| Preconditions | `tenant.medical-check.create`; complaint exists |
| Input | complaint_id (required), check_type_id (required, FK→sys_dropdown_table), conducted_by (optional), conducted_at (required datetime), result (FK→sys_dropdown_table: Positive/Negative/Inconclusive), reading_value (optional, max 50), remarks (optional text), medical_img (optional file) |
| Processing | Validate; create record; upload image via Spatie MediaLibrary; set evidence_uploded=1 if image attached |
| Status | ✅ Controller complete |

**🆕 V2 Schema Corrections:**
- DDL column: `evidence_uploded` (typo — missing 'a') — consistent with DDL; model must use same spelling
- DDL column: `result VARCHAR(20)` (not a FK bigint) — model cast must treat as string not integer FK
- DDL column: `check_type_id` (DDL uses this name); model must match
- DDL: NO `updated_at`, NO `deleted_at`, NO `is_active`, NO `created_by` — model SoftDeletes trait will fail; controller trash/restore/forceDelete routes will fail silently

**Acceptance Criteria:**
- [x] Medical check created with required fields only
- [x] Image upload sets `evidence_uploded=1`
- [ ] SoftDeletes migration column added (or remove SoftDeletes trait from model)
- [ ] `result` column type reconciled (VARCHAR in DDL vs FK in model)

---

### FR-CMP-007: AI Insight Engine
**RBS:** Beyond RBS (Prime-AI differentiator) | **Priority:** Medium
**Status:** ✅ Engine complete; ❌ Controller stub; 🟡 Known logic bugs
**Tables:** `cmp_ai_insights`

#### REQ-CMP-007.1: Automatic AI Processing on Complaint Save
| Attribute | Detail |
|---|---|
| Description | Every complaint create/update triggers AI processing via event/listener pipeline |
| Flow | ComplaintSaved → ProcessComplaintAIInsights → ComplaintAIInsightEngine::processComplaint() |
| Output | One `cmp_ai_insights` record per complaint (upserted via updateOrCreate on complaint_id) |
| Status | ✅ |

#### REQ-CMP-007.2: Sentiment Analysis
| Attribute | Detail |
|---|---|
| Algorithm | Keyword matching against: angry, delay, harassment, urgent, unsafe, worst, threat, complaint — each adds +0.15 to score (capped at 1.0) |
| Output | sentiment_score DECIMAL(4,3) in [0, 1] + sentiment_label_id (lookup 'Angry'/'Urgent'/'Neutral'/'Calm' by key, not hardcoded ID) |
| Status | ✅ Engine logic correct; 🟡 label IDs hardcoded (147–150) — must resolve by key |

#### REQ-CMP-007.3: Escalation Risk Score (0–100)
| Attribute | Detail |
|---|---|
| Formula | (severity×0.35) + (frequency×0.30) + (sentiment×0.20) + (pending_days×0.15) |
| Severity inputs | Critical=100, High=80, Medium=50, Low=20 |
| Frequency | Count of complaints against same target_selected_id (×20, max 100) |
| Status | ✅ Formula correct; 🟡 references `target_id` but DDL column is `target_selected_id` — fix required |

#### REQ-CMP-007.4: Safety Risk Score (0–100)
| Attribute | Detail |
|---|---|
| Keywords | accident(90), injury(95), unsafe(85), violence(100), bully(80), harassment(90), rash driving(95), abuse(90), threat(85), weapon(100), blood(95), fight(90), sexual(100) — take maximum |
| Boost | critical+30, high+20, medium+10 |
| Sensitivity | is_sensitive=true → floor score at 85 |
| Status | ✅ |

#### REQ-CMP-007.5: View AI Insights
| Attribute | Detail |
|---|---|
| Description | Admin views AI insight scores per complaint (list + detail) |
| Status | ❌ AiInsightController is a boilerplate stub; index view exists but controller returns wrong content |

**📐 Proposed: Implement AiInsightController**
- `index()` → paginated list of all complaints with AI scores; sortable by risk score
- `show(AiInsight $insight)` → detail view for single complaint AI analysis
- Link from complaint `show` page to its AI insight

**📐 Proposed: Queue AI Listener**
Add `implements ShouldQueue` to `ProcessComplaintAIInsights` listener. For high-volume schools (100+ complaints/day), synchronous AI processing on every HTTP request adds measurable latency.

**Acceptance Criteria:**
- [ ] AiInsightController index() returns paginated list of insights
- [ ] sentiment label IDs resolved by key, not hardcoded
- [ ] `target_id` reference in engine updated to `target_selected_id`
- [ ] ProcessComplaintAIInsights implements ShouldQueue (async)
- [x] updateOrCreate prevents duplicate insight rows per complaint

---

### FR-CMP-008: Dashboard & Analytics
**RBS:** Beyond RBS | **Priority:** Medium
**Status:** ✅ Service complete; 🟡 filter() has dd(); ❌ ComplaintDashboardController stub
**Tables:** `cmp_complaints`, `cmp_ai_insights`, `cmp_complaint_categories`

#### REQ-CMP-008.1: Dashboard KPIs (date-ranged)
| Metric | Description |
|---|---|
| openTickets | Count of non-resolved/closed complaints in range |
| newToday | Complaints created today |
| avgResolutionHours | Average time from ticket_date to actual_resolved_at vs SLA expected |
| slaBreaches | Count of complaints where now() > resolution_due_at and still open |
| categoryPie | ApexCharts series of complaint count by top-level category |
| Status | ✅ Service implements all; index() renders via ComplaintController |

#### REQ-CMP-008.2: Escalation Heatmap
Category × escalation level (Level 1–5, Breached) matrix with complaint counts.
**Status:** ✅ — but N+1 query in `getEscalationHeatmapData()` (SV-02); should use aggregate SQL.

#### REQ-CMP-008.3–008.6: Other Dashboard Widgets
| Widget | Status |
|---|---|
| Critical Ticket Widget (top-5 nearest breach) | ✅ |
| AI Risk Predictions Widget (top-5 risk ≥ 80) | ✅ |
| Sentiment Trend Chart (daily avg over range) | ✅ |
| Repeated-Target Frustration Report | ✅ |

#### REQ-CMP-008.7: AJAX Dashboard Filter
**Status:** ❌ BROKEN — `filter()` method at ComplaintController line 833 has `dd('FILTER HIT', request()->all())`. Must be removed and filter logic implemented properly.

**📐 Proposed: Implement ComplaintDashboardController**
Move all dashboard logic out of ComplaintController.index() (currently a 220-line god-method loading everything) into a dedicated `ComplaintDashboardController`:
- `index()` → dashboard view with KPIs; paginate complaint list separately
- `filter()` → AJAX JSON response with filtered KPIs (remove dd())

**Acceptance Criteria:**
- [ ] filter() AJAX endpoint returns JSON without dd()
- [ ] ComplaintDashboardController index() renders correct dashboard view
- [ ] Complaint list uses pagination — no unbounded `->get()`
- [ ] N+1 queries resolved in index() map() loop

---

### FR-CMP-009: Complaint Reports
**RBS:** Beyond RBS | **Priority:** Medium | **Status:** ✅ Implemented
**Tables:** `cmp_complaints`, `cmp_ai_insights`, `cmp_complaint_categories`

#### REQ-CMP-009.1: Summary & Status Report
Tabular: status × priority × category × severity; shows total tickets, %, avg resolution hours. Filters: date range, category, complainant_type_id, status. **Status:** ✅

#### REQ-CMP-009.2: SLA Violation Report
Lists complaints breaching or at-risk of breaching SLA; shows delay_hours, assigned_to, escalation_level, violation_type. **Status:** ✅ (department filter disabled — no `department_id` on categories)

#### REQ-CMP-009.3: Pareto Analysis Report
Categories ranked by complaint count with cumulative % to identify top-80% sources. **Status:** ✅

#### REQ-CMP-009.4: Complainant Hotspot Report
Identifies targets receiving highest complaint volumes with avg AI risk scores. **Status:** ✅

#### REQ-CMP-009.5: AI Risk & Sentiment Bubble Chart
Scatter: x=sentiment_score, y=escalation_risk_score, z=safety_risk_score, label=ticket_no. **Status:** ✅

**🆕 V2 Routes:** All reports currently served through a single `summary()` method in ComplaintReportController. Consider individual routes per report type for deep-linking and separate permissions.

---

### FR-CMP-010: Student / Parent Portal Submission
**RBS:** F.D3.1 (self-service) | **Priority:** Medium | **Status:** 🟡 Partial (external module)

Students and parents register complaints from the Student Portal via `Modules\StudentPortal\Http\Controllers\StudentPortalComplaintController`. AJAX endpoints for cascading category → subcategory dropdowns exist. This module only owns the `cmp_complaints` table; portal submission is the StudentPortal module's responsibility.

---

### FR-CMP-011: Complaint Reopening Workflow
**RBS:** — | **Priority:** Medium | **Status:** 📐 Proposed

#### REQ-CMP-011.1: Reopen a Resolved Complaint
| Attribute | Detail |
|---|---|
| Description | Allow complainant (via portal) or admin to reopen a resolved complaint with a reason |
| Input | complaint_id, reopen_reason (text, required) |
| Processing | Validate status=Resolved; update status to 'Reopened' (or 'In-Progress'); log action with reason; clear actual_resolved_at and resolved_by fields |
| Actors | School Admin, original complainant (portal only) |
| Status | 📐 Proposed — no existing implementation |

---

### FR-CMP-012: Scheduled Escalation Job
**RBS:** — | **Priority:** Medium | **Status:** ❌ Not Started

#### REQ-CMP-012.1: Auto-Escalate Overdue Complaints
| Attribute | Detail |
|---|---|
| Description | Scheduled job runs hourly/daily to update `current_escalation_level` for open complaints that have crossed thresholds |
| Processing | Query open complaints; calculate current escalation level for each; if changed, update DB and log action; optionally notify assigned role/user |
| Status | ❌ No Job class exists; escalation level only computed on read, never persisted by a background process |

**📐 Proposed:** Create `CheckComplaintEscalations` Artisan command / Job scheduled in `Kernel.php` (hourly). Sends notifications to escalation entity groups when threshold crossed.

---

### FR-CMP-013: Feedback Collection
**RBS:** F.D3.2 | **Priority:** Low | **Status:** ❌ Not Started

Feedback forms (ST.D3.2.1.1) and response collection (ST.D3.2.1.2) are not implemented. No model, controller, view, or DB table exists. Out of scope for current sprint; flagged for future planning.

---

## 5. Data Model

### 5.1 Entity Overview

| Table | Model | Purpose | Row Estimate |
|---|---|---|---|
| `cmp_complaint_categories` | ComplaintCategory | Hierarchical complaint types + SLA timelines | 20–100/school |
| `cmp_department_sla` | DepartmentSla | Category × target entity SLA overrides | 10–50/school |
| `cmp_complaints` | Complaint | Core complaint tickets | 100–10,000/school/year |
| `cmp_complaint_actions` | ComplaintAction | Audit log entries per complaint | 3–20× complaint count |
| `cmp_medical_checks` | MedicalCheck | Physical check records linked to complaints | 0.5–5% of complaints |
| `cmp_ai_insights` | AiInsight | AI scores per complaint (1:1 with complaints) | = complaint count |

### 5.2 Canonical DDL Schema (from tenant_db_v2.sql)

#### cmp_complaint_categories
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | NOT NULL | Auto-increment |
| parent_id | INT UNSIGNED FK | NULL | → self (cascade delete) |
| name | VARCHAR(100) | NOT NULL | Unique per parent |
| code | VARCHAR(30) | NULL | Unique if set |
| description | VARCHAR(512) | NULL | |
| severity_level_id | INT UNSIGNED FK | NULL | → sys_dropdown_table; SET NULL on delete |
| priority_score_id | INT UNSIGNED FK | NULL | → sys_dropdown_table; SET NULL on delete |
| default_expected_resolution_hours | INT UNSIGNED | NOT NULL | Base SLA hours |
| default_escalation_hours_l1 | INT UNSIGNED | NOT NULL | Cumulative threshold L1 |
| default_escalation_hours_l2 | INT UNSIGNED | NOT NULL | |
| default_escalation_hours_l3 | INT UNSIGNED | NOT NULL | |
| default_escalation_hours_l4 | INT UNSIGNED | NOT NULL | |
| default_escalation_hours_l5 | INT UNSIGNED | NOT NULL | |
| default_escalation_l1_entity_group_id | INT UNSIGNED FK | NULL | → sys_groups; SET NULL |
| default_escalation_l2_entity_group_id | INT UNSIGNED FK | NULL | → sys_groups; SET NULL |
| default_escalation_l3_entity_group_id | INT UNSIGNED FK | NULL | → sys_groups; SET NULL |
| default_escalation_l4_entity_group_id | INT UNSIGNED FK | NULL | → sys_groups; SET NULL |
| default_escalation_l5_entity_group_id | INT UNSIGNED FK | NULL | → sys_groups; SET NULL |
| is_medical_check_required | TINYINT(1) | NOT NULL DEFAULT 0 | Medical check flag |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at | TIMESTAMP | — | |
| updated_at | TIMESTAMP | — | |
| ~~deleted_at~~ | — | — | **MISSING — must add** |
| ~~created_by~~ | — | — | **MISSING — must add** |

**Indexes:** `idx_cat_parent`, `idx_cat_parent_name` UNIQUE (parent_id, name), `idx_cat_code` UNIQUE (code)

#### cmp_department_sla
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | NOT NULL | |
| complaint_category_id | INT UNSIGNED FK | NOT NULL | → cmp_complaint_categories; SET NULL on delete |
| complaint_subcategory_id | INT UNSIGNED FK | NULL | → cmp_complaint_categories; SET NULL on delete |
| target_department_id | INT UNSIGNED FK | NULL | → sch_departments |
| target_designation_id | INT UNSIGNED FK | NULL | → sch_designations |
| target_role_id | INT UNSIGNED FK | NULL | → sch_roles |
| target_entity_group_id | INT UNSIGNED FK | NULL | → sch_entity_groups |
| target_user_id | INT UNSIGNED FK | NULL | → sch_users |
| target_vehicle_id | INT UNSIGNED FK | NULL | → sch_vehicles |
| target_vendor_id | INT UNSIGNED FK | NULL | → tpt_vendor |
| dept_expected_resolution_hours | INT UNSIGNED | NOT NULL | |
| dept_escalation_hours_l1..l5 | INT UNSIGNED | NOT NULL | Ascending validation required |
| escalation_l1..l5_entity_group_id | INT UNSIGNED FK | NULL | → sch_entity_groups |
| is_active | TINYINT(1) | NOT NULL DEFAULT 1 | |
| created_at | TIMESTAMP | — | |
| updated_at | TIMESTAMP | — | |
| ~~deleted_at~~ | — | — | **MISSING — must add** |
| ~~created_by~~ | — | — | **MISSING — must add** |

#### cmp_complaints
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | NOT NULL | |
| ticket_no | VARCHAR(30) | NOT NULL UNIQUE | CMP-YYYY-000001 format |
| ticket_date | DATE | NOT NULL DEFAULT CURRENT_DATE | |
| complainant_type_id | INT UNSIGNED FK | NOT NULL | → sys_dropdown_table |
| complainant_user_id | INT UNSIGNED FK | NULL | → sys_users |
| complainant_name | VARCHAR(100) | NULL | For anonymous/external |
| complainant_contact | VARCHAR(50) | NULL | |
| target_user_type_id | INT UNSIGNED FK | NULL | → sys_dropdown_table |
| target_table_name | VARCHAR(60) | NULL | e.g. "sch_staff", "sch_vehicle" |
| target_selected_id | INT UNSIGNED | NULL | App-level FK (no DB constraint) |
| target_code | VARCHAR(50) | NULL | |
| target_name | VARCHAR(100) | NULL | |
| category_id | INT UNSIGNED FK | NOT NULL | → cmp_complaint_categories |
| subcategory_id | INT UNSIGNED FK | NULL | → cmp_complaint_categories |
| severity_level_id | INT UNSIGNED FK | NOT NULL | Auto-fetched from category |
| priority_score_id | INT UNSIGNED FK | NOT NULL | Auto-fetched from category |
| title | VARCHAR(200) | NOT NULL | |
| description | TEXT | NULL | Fed to AI engine |
| location_details | VARCHAR(255) | NULL | |
| incident_date | DATETIME | NULL | |
| incident_time | TIME | NULL | |
| status_id | INT UNSIGNED FK | NOT NULL | → sys_dropdown_table (Open/In-Progress/Resolved/Closed/Rejected/Escalated) |
| assigned_to_role_id | INT UNSIGNED FK | NULL | → sys_roles |
| assigned_to_user_id | INT UNSIGNED FK | NULL | → sys_users |
| resolution_due_at | DATETIME | NULL | From SLA calculation on create |
| actual_resolved_at | DATETIME | NULL | |
| resolved_by_role_id | INT UNSIGNED FK | NULL | |
| resolved_by_user_id | INT UNSIGNED FK | NULL | |
| resolution_summary | TEXT | NULL | |
| is_escalated | TINYINT(1) | NOT NULL DEFAULT 0 | Manual escalation flag |
| current_escalation_level | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | 0=None, 1–5=Level, updated by job |
| source_id | INT UNSIGNED FK | NULL | → sys_dropdown_table |
| is_anonymous | TINYINT(1) | NOT NULL DEFAULT 0 | |
| dept_specific_info | JSON | NULL | Free-form department-specific fields |
| is_medical_check_required | TINYINT(1) | NOT NULL DEFAULT 0 | Auto-fetched from category |
| support_file | TINYINT(1) | NOT NULL DEFAULT 0 | Has attached media |
| created_at | TIMESTAMP | — | |
| updated_at | TIMESTAMP | — | |
| deleted_at | TIMESTAMP | NULL | SoftDeletes ✅ |

**DDL Bug:** `KEY idx_cmp_status (status)` — should be `idx_cmp_status (status_id)`.
**DDL Bug:** `CONSTRAINT fk_cmp_medical_check FOREIGN KEY (is_medical_check_required) REFERENCES cmp_medical_checks(id)` — type mismatch (TINYINT FK to INT PK); logically incorrect; must be removed.

#### cmp_complaint_actions
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | NOT NULL | |
| complaint_id | INT UNSIGNED FK | NOT NULL | → cmp_complaints CASCADE DELETE |
| action_type_id | INT UNSIGNED FK | NOT NULL | → sys_dropdown_table |
| performed_by_user_id | INT UNSIGNED FK | NULL | NULL = system action |
| performed_by_role_id | INT UNSIGNED FK | NULL | |
| assigned_to_user_id | INT UNSIGNED FK | NULL | For assignment actions |
| assigned_to_role_id | INT UNSIGNED FK | NULL | |
| notes | TEXT | NULL | |
| is_private_note | TINYINT(1) | NOT NULL DEFAULT 0 | Admin-only notes |
| action_timestamp | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | Primary time column |
| ~~created_at/updated_at~~ | — | — | NOT in DDL — model must not use timestamps trait |
| ~~deleted_at~~ | — | — | **NOT in DDL** — SoftDeletes will fail |
| ~~is_active~~ | — | — | **NOT in DDL** |
| ~~created_by~~ | — | — | **NOT in DDL** |

#### cmp_medical_checks
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | NOT NULL | |
| complaint_id | INT UNSIGNED FK | NOT NULL | → cmp_complaints CASCADE DELETE |
| check_type_id | INT UNSIGNED FK | NOT NULL | → sys_dropdown_table |
| conducted_by | VARCHAR(100) | NULL | Doctor/officer name (string, not FK) |
| conducted_at | DATETIME | NOT NULL | |
| result | VARCHAR(20) | NOT NULL | FK to sys_dropdown_table by value (DDL inconsistency — result is VARCHAR, FK by id) |
| reading_value | VARCHAR(50) | NULL | e.g. BAC level |
| remarks | TEXT | NULL | |
| evidence_uploded | TINYINT(1) | NOT NULL DEFAULT 0 | Note: DDL typo — 'uploded' not 'uploaded' |
| created_at | TIMESTAMP | — | |
| ~~updated_at~~ | — | — | NOT in DDL |
| ~~deleted_at~~ | — | — | **NOT in DDL** — SoftDeletes will fail |
| ~~is_active~~ | — | — | **NOT in DDL** |

#### cmp_ai_insights
| Column | Type | Nullable | Notes |
|---|---|---|---|
| id | INT UNSIGNED PK | NOT NULL | |
| complaint_id | INT UNSIGNED FK | NOT NULL UNIQUE | → cmp_complaints CASCADE DELETE; 1:1 |
| sentiment_score | DECIMAL(4,3) | NULL | [0, 1] (engine produces [0,1] despite DDL comment of [-1,1]) |
| sentiment_label_id | INT UNSIGNED FK | NULL | → sys_dropdown_table |
| escalation_risk_score | DECIMAL(5,2) | NULL | [0, 100] |
| predicted_category_id | INT UNSIGNED FK | NULL | → cmp_complaint_categories |
| safety_risk_score | DECIMAL(5,2) | NULL | [0, 100] |
| model_version | VARCHAR(20) | NULL | 'rules-v1' |
| processed_at | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| ~~deleted_at~~ | — | — | **NOT in DDL** |
| ~~is_active~~ | — | — | **NOT in DDL** |
| ~~created_by~~ | — | — | **NOT in DDL** |

**Indexes:** `uq_ai_complaint` UNIQUE (complaint_id), `idx_ai_risk` (escalation_risk_score)

### 5.3 Schema Reconciliation Summary (V2 Definitive List)

| Issue | Table | Severity | Action |
|---|---|---|---|
| `expected_resolution_hours` vs DDL `default_expected_resolution_hours` | categories | P0-critical | Rename in migration + model |
| `escalation_hours_l1..l5` vs DDL `default_escalation_hours_l1..l5` | categories | P0-critical | Rename in migration + model |
| `deleted_at` missing from DDL | categories, dept_sla | P1 | Add via migration |
| `created_by` missing from DDL | categories, dept_sla | P2 | Add via migration |
| `default_escalation_l1..l5_entity_group_id` missing from model fillable | categories | P1 | Add to fillable + relationships |
| `is_medical_check_required` on complaints FK to cmp_medical_checks — type mismatch | complaints | P0-critical | Remove invalid FK constraint |
| `idx_cmp_status (status)` — column `status` does not exist, should be `status_id` | complaints | P1 | Fix index in migration |
| `target_id` in model vs DDL `target_selected_id` | complaints | P0-critical | Rename in model fillable + all usages |
| `escalation_level` in model vs DDL `current_escalation_level` | complaints | P0-critical | Rename in model + all references |
| `action_timestamp` in DDL vs model's `created_at` | actions | P1 | Use `action_timestamp`; disable timestamps on model |
| `deleted_at` / `updated_at` / `is_active` / `created_by` missing | actions | P1 | Either add to DDL or remove from model |
| `evidence_uploded` (DDL typo preserved) vs `evidence_uploaded` in model | medical_checks | P1 | Use DDL spelling in model + views |
| `updated_at` / `deleted_at` missing from medical_checks DDL | medical_checks | P1 | Add or remove SoftDeletes from model |
| `result VARCHAR(20)` in DDL — not a numeric FK | medical_checks | P1 | Model cast as string; FK logic must change |
| `deleted_at` / `is_active` missing from ai_insights DDL | ai_insights | P2 | Decide: add to DDL or remove from model |

### 5.4 Entity Relationships

```
cmp_complaint_categories ─── parent_id ──> self (tree; cascade delete)
                         ─── default_escalation_l1..l5_entity_group_id ──> sys_groups

cmp_department_sla ──> cmp_complaint_categories (category + subcategory)
                   ──> sch_departments, sch_designations, sch_roles, sch_entity_groups
                   ──> sch_users, sch_vehicles, tpt_vendor (target entities)
                   ──> sch_entity_groups (escalation l1..l5)

cmp_complaints ──> cmp_complaint_categories (category, subcategory)
               ──> sys_dropdown_table (complainant_type, target_user_type, severity, priority, status, source)
               ──> sys_users (complainant, assigned_to, resolved_by)
               ──> sys_roles (assigned_to, resolved_by)
               ──< cmp_complaint_actions (1:many; cascade delete)
               ──< cmp_medical_checks (1:many; cascade delete)
               ──  cmp_ai_insights (1:1; unique FK; cascade delete)
               ──  sys_media (polymorphic via Spatie MediaLibrary)

cmp_complaint_actions ──> cmp_complaints
                      ──> sys_dropdown_table (action_type)
                      ──> sys_users (performed_by, assigned_to)
                      ──> sys_roles (performed_by, assigned_to)

cmp_medical_checks ──> cmp_complaints
                   ──> sys_dropdown_table (check_type)
                   ──  sys_media (polymorphic via Spatie MediaLibrary)

cmp_ai_insights ──> cmp_complaints (1:1)
                ──> sys_dropdown_table (sentiment_label)
                ──> cmp_complaint_categories (predicted_category)
```

---

## 6. API Endpoints & Routes

All routes: prefix `/complaint`, name prefix `complaint.`, middleware `['auth', 'verified']`.
**🆕 V2 Fix Required:** Add `EnsureTenantHasModule` middleware to the route group (currently missing — RT-02).

### 6.1 Route Summary

| Group | Count | Status |
|---|---|---|
| Complaint Management Hub | 7 | 🟡 destroy empty, filter has dd() |
| Dashboard AJAX | 4 | 🟡 filter broken; 3 donut OK |
| Complaint Categories | 11 | ✅ |
| Department SLA | 10 | 🟡 toggleStatus missing |
| Complaints resource | 8 | 🟡 missing trash/restore/forceDelete |
| Complaint Actions | 7 | ❌ all stub |
| Medical Checks | 10 | ✅ (SoftDeletes will fail until DDL fixed) |
| AI Insights | 5 | ❌ all stub |
| Reports | 1 | ✅ |
| **Total** | **~63** | |

### 6.2 Complaint Management Hub

| Method | URI | Name | Controller@Method | Status |
|---|---|---|---|---|
| GET | /complaint/complaint-mgt | complaint.complaint-mgt.index | ComplaintController@index | 🟡 god-method; no pagination |
| GET | /complaint/complaint-mgt/create | complaint.complaint-mgt.create | @create | ✅ |
| POST | /complaint/complaint-mgt | complaint.complaint-mgt.store | @store | 🟡 dd() + hardcoded IDs |
| GET | /complaint/complaint-mgt/{id} | complaint.complaint-mgt.show | @show | 🟡 no Gate auth |
| GET | /complaint/complaint-mgt/{id}/edit | complaint.complaint-mgt.edit | @edit | 🟡 no Gate auth |
| PUT | /complaint/complaint-mgt/{id} | complaint.complaint-mgt.update | @update | 🟡 no Gate auth; hardcoded IDs |
| DELETE | /complaint/complaint-mgt/{id} | complaint.complaint-mgt.destroy | @destroy | ❌ empty |

### 6.3 Dashboard AJAX

| Method | URI | Controller@Method | Status |
|---|---|---|---|
| GET | /complaint/dashboard-data | ComplaintController@filter | ❌ dd() — broken |
| GET | /complaint/dashboard/donut/severity-vs-department | @severityVsDepartmentDonut | ✅ |
| GET | /complaint/dashboard/donut/department-vs-severity | @departmentVsSeverityDonut | ✅ |
| GET | /complaint/dashboard/donut/department-status | @departmentStatusDonut | ✅ |

### 6.4 Complaint Categories (All ✅ except schema fixes pending)

| Method | URI | Name | Status |
|---|---|---|---|
| GET/POST | /complaint/complaint-categories | .index / .store | ✅ |
| GET/PUT/DELETE | /complaint/complaint-categories/{id} | .show / .update / .destroy | ✅ |
| GET | /complaint/complaint-categories/trash/view | .trashed | ✅ |
| GET | /complaint/complaint-categories/{id}/restore | .restore | ✅ |
| DELETE | /complaint/complaint-categories/{id}/force-delete | .forceDelete | ✅ |
| POST | /complaint/complaint-categories/{id}/toggle-status | .toggleStatus | ✅ |

### 6.5 Department SLA

| Method | URI | Status |
|---|---|---|
| Full CRUD + trash/restore/forceDelete | /complaint/department-sla/* | ✅ |
| POST toggle-status | /complaint/department-sla/{id}/toggle-status | ❌ method missing in controller |

### 6.6 Complaints Core

| Method | URI | Status |
|---|---|---|
| GET/POST | /complaint/complaints | ✅ |
| GET/PUT/DELETE | /complaint/complaints/{id} | 🟡 destroy empty; show/edit/update missing Gate |
| GET trash | /complaint/complaints/trash/view | ❌ method missing |
| GET restore | /complaint/complaints/{id}/restore | ❌ method missing |
| DELETE force | /complaint/complaints/{id}/force-delete | ❌ method missing |
| POST toggle | /complaint/complaints/{id}/toggle-status | ❌ method missing |
| GET manage | /complaint/complaints/manage | 🟡 wrong gate prefix (prime. instead of tenant.) |

### 6.7 Complaint Actions (All ❌ Stub)
Routes declared: index, store, show, destroy, restore, forceDelete — all return wrong views.

### 6.8 Medical Checks (✅ — pending DDL SoftDeletes fix)
Full CRUD + trash/restore/forceDelete/toggleStatus at `/complaint/medical-checks/*`.

### 6.9 AI Insights (All ❌ Stub)
Routes declared: index, show, store, update, forceDelete — all return wrong views.

### 6.10 Reports
| Method | URI | Name | Status |
|---|---|---|---|
| GET | /complaint/reports/summary-status | complaint.reports.summary | ✅ |

---

## 7. UI Screens

| Screen | View File | Status | Key Issues |
|---|---|---|---|
| Complaint Hub / Dashboard | `complaint/complaint/index.blade.php` | 🟡 | God-method backend; AJAX filter broken |
| Create Complaint | `complaint/complaint/create.blade.php` | ✅ | |
| Edit Complaint | `complaint/complaint/edit.blade.php` | ✅ | |
| Show Complaint | `complaint/complaint/show.blade.php` | 🟡 | Anonymous masking not enforced |
| Complaint Trash | `complaint/complaint/trash.blade.php` | ❌ | No controller method |
| Complaint Manage | `complaint/complaint-manage/index.blade.php` | 🟡 | Wrong gate prefix |
| Complaint Actions | `complaint/complaint-manage/actions.blade.php` | 🟡 | View exists; controller stub |
| Category Index/Create/Edit/Show/Trash | `complaint/category/` (5 views) | ✅ | |
| Department SLA (5 views) | `complaint/department-sla/` | ✅ | |
| Medical Checks (5 views) | `complaint/medical-checks/` | ✅ | |
| AI Insights Index | `complaint/ai-insights/index.blade.php` | 🟡 | View exists; controller stub |
| Report Dashboard | `reports/index.blade.php` | ✅ | |
| Complaint Status Report | `reports/complaint-status/index.blade.php` | ✅ | |
| SLA Violation Report | `reports/sla-violation/index.blade.php` | ✅ | |
| Pareto Report | `reports/pareto/index.blade.php` | ✅ | |
| Hotspot Report | `reports/hotspot/index.blade.php` | ✅ | |
| Sentiment Report | `reports/sentiment/index.blade.php` | ✅ | |

**📐 Proposed New Screens:**
- Complaint Timeline embed in Show page (integrate `actions.blade.php` partial into show)
- Escalation status badge on complaint list (color-coded per level)
- AI risk indicator on complaint list rows

---

## 8. Business Rules

### BR-CMP-001: Ticket Number Format
- Format: `CMP-{YEAR}-{6-digit-zero-padded-serial}` (e.g., `CMP-2026-000001`)
- Serial is per-tenant, resets each calendar year
- Generated in DB transaction with `lockForUpdate()` + collision loop
- `ticket_no` has UNIQUE constraint in DDL

### BR-CMP-002: Escalation Level Thresholds
- Level 0 (Pending): ticket_date + default_expected_resolution_hours not yet exceeded
- Level 1: After base hours exceeded; before +l1 additional hours
- Level 2–5: Progressive; Level "Breached": all 5 levels exhausted
- Resolved complaints have no escalation level
- `current_escalation_level` (DDL) must be updated by scheduled job; computed dynamically on read as fallback

### BR-CMP-003: SLA Priority Order
- Department SLA (cmp_department_sla matching category + target) overrides Category SLA
- `resolution_due_at` must be set at complaint creation time (NOT on demand)
- If no matching Department SLA: use `default_expected_resolution_hours` from `cmp_complaint_categories`

### BR-CMP-004: Complaint Status Lifecycle
- Initial status: resolved dynamically from sys_dropdown_table by key 'cmp_complaints.status' → 'Open/Submitted' (NOT hardcoded ID 124)
- Valid transitions: Open → In-Progress → Resolved / Closed / Rejected; Escalated is a flag not a terminal state
- Resolved requires: `actual_resolved_at` + `resolution_summary`
- Every status change must produce a `cmp_complaint_actions` record with correct action_type_id

### BR-CMP-005: Complainant Type Rules
- Anonymous/External complainant_type → `complainant_name` required; `complainant_user_id` must be null
- All other types → `complainant_user_id` required; `complainant_name` allowed as display name

### BR-CMP-006: Target Entity Resolution
- `target_user_type_id` identifies the entity type (Staff, Student, Department, Vehicle, Vendor, Facility, etc.)
- `target_table_name` + `target_selected_id` resolve the specific entity at application level (no DB FK constraint)
- `target_name` is denormalized display name for read performance

### BR-CMP-007: Auto-Population from Category on Create
- `severity_level_id` and `priority_score_id` are auto-fetched from the selected category — NOT entered by user in complaint form
- `is_medical_check_required` auto-fetched from category
- `resolution_due_at` auto-calculated from applicable SLA rule

### BR-CMP-008: AI Insights Rules
- One insight record per complaint (1:1, UNIQUE constraint on complaint_id)
- Insight is computed via event/listener on every create and update
- `model_version` stored as 'rules-v1'; sentiment score range is [0, 1] (not [-1, 1] despite DDL comment)
- Hardcoded label IDs (147–150) must be replaced with dynamic lookup by key

### BR-CMP-009: Medical Check Linkage
- Medical check only appropriate when `is_medical_check_required=true` on the complaint
- No DB constraint enforces this — business rule validation in controller
- One check per complaint per check_type is recommended (no DB unique constraint)

### BR-CMP-010: Anonymous Complaints
- `is_anonymous=true` → complainant identity must be masked in non-admin views
- Anonymous complaints still require `complainant_type_id`
- Currently NOT enforced at view layer — must be implemented in show view

### BR-CMP-011: Evidence Attachments
- `complaint_img` and `medical_img` use Spatie MediaLibrary single-file collections
- Media stored with conversions: small (100×100), medium (300×300), large (600×600)
- `support_file` boolean on complaint tracks whether media is attached

### BR-CMP-012: Private Notes
- `is_private_note=true` on ComplaintAction → visible only to School Admin and Principal
- Must be filtered at query level when returning actions to non-admin users

---

## 9. Workflows

### 9.1 Complaint Ticket Lifecycle (FSM)

```
[Student/Parent/Staff/Admin creates complaint]
                │
                ▼
        ┌───────────────┐
        │     OPEN      │  status resolved from sys_dropdown_table by key
        │  (Submitted)  │  ticket_no auto-generated; AI insight triggered
        └───────┬───────┘
                │ Admin assigns role/user
                ▼
        ┌───────────────┐
        │  IN-PROGRESS  │  resolution_due_at set (from SLA on create)
        └───┬───────────┘
            │
    ┌───────┼──────────┬──────────┐
    ▼       ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│RESOLVED│ │ CLOSED │ │REJECTED│ │ESCALATE│
└────┬───┘ └────────┘ └────────┘ │  FLAG  │
     │                            └────────┘
     │ Complainant dissatisfied
     ▼ (📐 Proposed)
┌────────────┐
│  REOPENED  │ → back to IN-PROGRESS
└────────────┘

Parallel: Escalation Level (time-based, not status-based)
  Level 0 (Pending) → Level 1 → Level 2 → Level 3 → Level 4 → Level 5 → BREACHED
  Computed from ticket_date + cumulative SLA hours
  Updated by scheduled job (📐 Proposed)
```

**State Transitions:**
| From | Action | To | Condition |
|---|---|---|---|
| Open | Assign | In-Progress | assigned_to set |
| In-Progress | Resolve | Resolved | actual_resolved_at + resolution_summary required |
| In-Progress | Close | Closed | Admin decision |
| Any open | Reject | Rejected | Admin decision |
| Resolved | Reopen | In-Progress | (📐 Proposed) reopen_reason required |
| Any open | Breach escalation | (flag) Escalated | Time-based; is_escalated=true + escalation_level incremented |

### 9.2 AI Insight Generation Workflow

```
ComplaintController::store() or ::update()
        │ model saved
        ▼
event(new ComplaintSaved($complaint))
        │
        ▼ [synchronous — 📐 proposed: queue this]
ProcessComplaintAIInsights::handle()
        │
        ▼
ComplaintAIInsightEngine::processComplaint($complaintId)
        ├── calculateSentiment(complaint)
        │       Keyword match on description → sentiment_score [0,1]
        │       Label mapped by key from sys_dropdown_table (not hardcoded IDs)
        │
        ├── calculateRiskScore(complaint, sentimentScore)
        │       severity(35%) + frequency(30%) + sentiment(20%) + pending_days(15%)
        │       frequency counts against target_selected_id (fix from target_id)
        │       → escalation_risk_score [0,100]
        │
        ├── calculateSafetyRisk(complaint)
        │       Safety keywords max-score + severity boost + sensitivity flag
        │       → safety_risk_score [0,100]
        │
        ├── predictCategory(complaint)
        │       Currently: returns complaint->category_id (placeholder)
        │       Future: Python ML microservice integration
        │
        └── AiInsight::updateOrCreate(['complaint_id'=>$id], [...scores...])
```

### 9.3 SLA Resolution-Due-At Calculation on Create

```
complaint.category_id → cmp_complaint_categories
        │
        ├── Query: SELECT * FROM cmp_department_sla
        │       WHERE complaint_category_id = :cat_id
        │       AND (target matches complaint target fields)
        │       ORDER BY specificity DESC
        │       LIMIT 1
        │
        ├── If found: resolution_due_at = created_at + dept_expected_resolution_hours
        │
        └── If not found: resolution_due_at = created_at + default_expected_resolution_hours
```

---

## 10. Non-Functional Requirements

| ID | Category | Requirement | Current State |
|---|---|---|---|
| NFR-001 | Security | All `dd()` calls removed — ZERO tolerance in production | 2 active dd() calls: store() catch + filter() — CRITICAL |
| NFR-002 | Security | ComplaintPolicy::create() must check `tenant.complaint.create` | Currently checks `tenant.vendor-dahsboard.create` (typo + wrong module) |
| NFR-003 | Security | No hardcoded dropdown IDs (124, 197, 202, 147–150) | 6 hardcoded IDs identified — all must use key-based lookup |
| NFR-004 | Security | Input sanitization on description, resolution_summary, notes (XSS prevention) | Currently no sanitization |
| NFR-005 | Security | EnsureTenantHasModule middleware on complaint route group | Currently missing |
| NFR-006 | Performance | Complaint list must use pagination — no unbounded ->get() | Current index() loads ALL complaints; 10,000-row tables will timeout |
| NFR-007 | Performance | N+1 queries resolved: complaints->map() calling DB::table() per row | Active N+1 in index loop and escalation heatmap |
| NFR-008 | Performance | AI processing should not block HTTP response | Currently synchronous; should implement ShouldQueue |
| NFR-009 | Reliability | store() and update() must handle exceptions gracefully | dd() in catch block currently crashes production |
| NFR-010 | Data Integrity | Schema migration files must match canonical DDL (tenant_db_v2.sql) | 15 schema gaps identified in Section 5.3 |
| NFR-011 | Auditability | All CRUD operations must log via activityLog() helper | Currently missing in store/update/destroy |
| NFR-012 | Auditability | All status changes must produce ComplaintAction records | Partially broken — action_type_id resolution is buggy |
| NFR-013 | Compliance | Anonymous complaints must mask complainant identity in non-admin views | Not enforced at view layer |
| NFR-014 | Maintainability | Duplicate escalation calculation logic must be centralized | Same logic in ComplaintController and ComplaintDashboardService |
| NFR-015 | Maintainability | FormRequest classes required for all write operations | Zero FormRequest classes exist |

---

## 11. Dependencies

### 11.1 This Module Depends On

| Module | Dependency | Usage |
|---|---|---|
| SchoolSetup | `sch_departments`, `sch_designations`, `sch_entity_groups` | DepartmentSla targets |
| SchoolSetup | `sch_roles`, `sch_vehicles` | Assignment + target entities |
| SchoolSetup | `sys_groups` | Escalation entity groups (l1–l5) |
| Auth/User | `sys_users` | Complainant, assignee, resolver, created_by |
| GlobalMaster | `sys_dropdown_table` | All status/type/severity/priority/action_type lookups |
| Transport | `tpt_vendor` | DepartmentSla target_vendor_id FK |
| StudentPortal | `StudentPortalComplaintController` | Student/parent self-service submission |
| Notifications | `StudentPortalComplaintRegistered` | Sent to Super Admin on complaint creation |
| Spatie MediaLibrary | `spatie/laravel-medialibrary` | complaint_img + medical_img storage |

### 11.2 Modules That Depend on This

| Module | Dependency |
|---|---|
| Student Portal | Portal submission writes to `cmp_complaints` |
| Parent Portal (pending) | Parent self-service complaints |
| HR & Payroll (pending) | Staff complaints may create HR flags |
| Analytics / Reports | cmp_* data for school performance dashboards |

---

## 12. Test Scenarios

### 12.1 Existing Tests

| File | Location | Type | Coverage |
|---|---|---|---|
| ComplaintCategoryTest.php | `tests/Browser/Modules/Complaint/Category/` | Dusk Browser | Category CRUD, schema validation, soft-delete lifecycle |
| ComplaintCrudTest.php | `tests/Browser/Modules/Complaint/Complaint/` | Dusk Browser | Complaint schema, model, destroy contract |
| DepartmentSlaCrudTest.php | `tests/Browser/Modules/Complaint/DepartmentSLA/` | Dusk Browser | SLA CRUD, schema validation |
| MedicalCheckCrudTest.php | `tests/Browser/Modules/Complaint/MedicalChecks/` | Dusk Browser | Medical check CRUD, validation, media upload (with proof screenshots) |
| AIInsights/ | `tests/Browser/Modules/Complaint/AIInsights/` | — | requirement.md only — NO test file |

**Note:** `Modules/Complaint/tests/` directory contains only `.gitkeep` files — ZERO Feature or Unit tests.

### 12.2 Required Test Plan (V2)

| # | Test Name | Type | Priority | Status |
|---|---|---|---|---|
| T-001 | store() handles exception without dd() — returns 422/500 JSON | Feature/HTTP | P0-Critical | ❌ |
| T-002 | filter() AJAX returns JSON data without dd() | Feature/HTTP | P0-Critical | ❌ |
| T-003 | ComplaintPolicy.create checks tenant.complaint.create | Unit | P0-Critical | ❌ |
| T-004 | status_id resolved from sys_dropdown_table by key (not hardcoded 124) | Feature | P0-Critical | ❌ |
| T-005 | action_type_id resolved by key — not hardcoded 197/202 | Feature | P0-Critical | ❌ |
| T-006 | destroy() soft-deletes the complaint | Feature | P0-Critical | ❌ |
| T-007 | Ticket number is unique under concurrent creation (lockForUpdate) | Feature | P1-High | ❌ |
| T-008 | Ticket number format is CMP-YYYY-000001 | Unit | P1-High | ❌ |
| T-009 | Status change logs correct action in cmp_complaint_actions | Feature | P1-High | ❌ |
| T-010 | resolution_due_at auto-set from Department SLA on create | Feature | P1-High | ❌ |
| T-011 | resolution_due_at falls back to Category SLA when no Dept SLA | Feature | P1-High | ❌ |
| T-012 | AI insight created on complaint store via event/listener | Feature | P1-High | ❌ |
| T-013 | Sentiment: "harassment urgent" → score >= 0.30 | Unit | P1-High | ❌ |
| T-014 | Safety: "violence" keyword → safety_risk_score = 100 | Unit | P1-High | ❌ |
| T-015 | Escalation risk formula — Critical severity + 3 repeat complaints | Unit | P1-High | ❌ |
| T-016 | updateOrCreate prevents duplicate AI insight rows | Feature | P1-High | ❌ |
| T-017 | Escalation level calculation — time-based progression | Unit | P1-High | ❌ |
| T-018 | ComplaintAction index returns timeline in chronological order | Feature | P1-High | ❌ |
| T-019 | Private note hidden from non-admin response | Feature | P1-High | ❌ |
| T-020 | Anonymous complaint masks complainant in show view | Browser | P1-High | ❌ |
| T-021 | Medical check soft-delete fails gracefully if deleted_at missing | Feature | P1-High | ❌ |
| T-022 | DepartmentSla toggleStatus returns 200 JSON | Feature | P2 | ❌ |
| T-023 | Pareto report correct cumulative percentage calculation | Feature | P2 | ❌ |
| T-024 | Hotspot report correct grouping by target_selected_id | Feature | P2 | ❌ |
| T-025 | Complaint list is paginated (not unbounded get()) | Feature | P2 | ❌ |
| T-026 | EnsureTenantHasModule middleware applied to route group | Feature | P2 | ❌ |

### 12.3 Coverage Summary

| Area | Existing Coverage | Gap |
|---|---|---|
| Category CRUD | ✅ Browser tests | Escalation hours validation edge cases |
| Department SLA CRUD | ✅ Browser tests | toggleStatus; schema reconciliation |
| Complaint Core | 🟡 Partial browser | store exceptions, concurrent tickets, action logging, pagination |
| Medical Checks | ✅ Most comprehensive | SoftDeletes DDL fix; result column type |
| AI Engine | ❌ Zero tests | All engine logic, formula correctness |
| Action Timeline | ❌ Zero tests | All timeline functionality |
| Reports | ❌ Zero tests | 5 report methods |
| Dashboard | ❌ Zero tests | All KPIs, filter endpoint |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Ticket | A registered complaint with unique `CMP-YYYY-NNNNNN` identifier |
| Complainant | Person raising the complaint (Student/Parent/Staff/Vendor/Anonymous/Public) |
| Target | Person, department, vehicle, or vendor the complaint is against |
| Category / Subcategory | Two-level classification of complaint nature |
| SLA | Service Level Agreement — time commitment for complaint resolution |
| Escalation Level | Progressive urgency state (0=Pending, 1–5=Levels, Breached) computed from ticket age vs SLA hours |
| default_expected_resolution_hours | Base SLA hours from category master (DDL canonical column name) |
| default_escalation_hours_l1–l5 | Incremental additional hours before each escalation threshold |
| Department SLA | Dept-specific SLA rule overriding category defaults for a specific target entity |
| target_selected_id | Application-level FK (no DB constraint) identifying the specific target entity |
| target_table_name | Name of the source table for target entity (e.g. "sch_staff", "sch_vehicle") |
| current_escalation_level | Stored escalation level in DB (0–5); updated by scheduled job |
| AI Insight | System-generated risk assessment (sentiment + escalation risk + safety risk) per complaint |
| Sentiment Score | [0, 1] float — higher = more negative/angry content in description |
| Escalation Risk Score | [0, 100] composite score for likelihood of further escalation |
| Safety Risk Score | [0, 100] physical safety concern score based on keyword severity |
| Hotspot | Target entity accumulating disproportionate complaint volume |
| Pareto Analysis | 80/20 analysis — identifies 20% of categories causing 80% of complaints |
| Frustration Probability | Score for complainant-target pairs with recurring complaints |
| Private Note | Action log entry visible only to Admin/Principal |
| action_timestamp | DDL timestamp column on cmp_complaint_actions (not created_at) |
| evidence_uploded | DDL column name (typo preserved from DDL — missing 'a') |
| EnsureTenantHasModule | Laravel middleware verifying tenant has licensed access to a module |

---

## 14. Suggestions

### 14.1 P0 — Must Fix Before Any Production Deployment

1. **Remove all `dd()` calls** — ComplaintController lines 407 (catch block) and 833 (filter method). Replace with `Log::error()` + proper HTTP error responses. These expose stack traces and block production functionality.

2. **Fix ComplaintPolicy::create() permission typo** — `tenant.vendor-dahsboard.create` → `tenant.complaint.create`. Any user with vendor dashboard access currently bypasses complaint creation authorization.

3. **Implement FormRequest classes** — `StoreComplaintRequest` and `UpdateComplaintRequest` as minimum. Add `StoreDepartmentSlaRequest`, `StoreComplaintActionRequest`, `StoreMedicalCheckRequest`. Inline validation in controllers is fragile and untestable.

4. **Replace all hardcoded dropdown IDs** — status_id=124, action_type_id=197/202, sentiment label IDs 147–150 must all be resolved by key from sys_dropdown_table. A `ComplaintDropdownResolver` service or Enum-backed seeder is recommended.

5. **Implement `destroy()` method** — currently empty; add Gate authorization + `$complaint->delete()` (soft-delete).

6. **Add Gate authorization to show(), edit(), update()** — currently missing; any authenticated user can access these routes.

### 14.2 P1 — Fix Before Beta Testing

7. **Reconcile schema column names** — `default_expected_resolution_hours`, `default_escalation_hours_l1..l5`, `target_selected_id`, `current_escalation_level` must match between Laravel migrations and canonical DDL. All model `$fillable` arrays, scopes, and service queries must be updated.

8. **Fix DDL bugs** — remove invalid FK `fk_cmp_medical_check` (TINYINT FK to INT PK); fix index `idx_cmp_status` to use column `status_id`; add `deleted_at` to `cmp_complaint_categories` and `cmp_department_sla`.

9. **Add EnsureTenantHasModule middleware** to the complaint route group.

10. **Implement ComplaintActionController** — the action/timeline audit log is the backbone of accountability; model and DDL are fully defined; only controller + proper view logic are missing.

11. **Implement AiInsightController** — ai-insights/index.blade.php exists; add real index() and show() logic.

12. **Implement DepartmentSlaController::toggleStatus()** — route is declared, method is missing.

13. **Add pagination to complaint list** — `->get()` on cmp_complaints will timeout at scale; use `->paginate(25)`.

14. **Fix N+1 queries** — use `with()` eager loading in complaint index; avoid per-row `DB::table('sys_dropdowns')` lookups.

15. **Implement auto-populate on create** — severity_level_id, priority_score_id, is_medical_check_required, and resolution_due_at must be auto-populated from category + SLA rules; not left to manual input.

### 14.3 P2 — Fix Before General Availability

16. **Extract EscalationService** — centralize escalation level calculation currently duplicated across ComplaintController and ComplaintDashboardService.

17. **Queue AI Listener** — add `implements ShouldQueue` to ProcessComplaintAIInsights.

18. **Implement scheduled escalation job** — `CheckComplaintEscalations` command run hourly to update `current_escalation_level` and notify assigned entity groups.

19. **Refactor ComplaintController::index() god-method** — split into ComplaintDashboardController (dashboard logic) and ComplaintController (complaint CRUD only); use AJAX lazy-load for chart data.

20. **Implement logAction() via Eloquent** — replace raw `DB::table()` insert with `ComplaintAction::create([...])`.

21. **Implement trash/restore/forceDelete for Complaints** — missing controller methods; routes are declared.

22. **Fix manage() gate prefix** — `prime.complaint.manage` → `tenant.complaint.manage`.

### 14.4 Feature Enhancements (Proposed)

23. **Complaint Reopening Workflow (FR-CMP-011)** — Allow admin/complainant to reopen resolved complaints with reason. Very common in Indian school contexts where initial resolution is incomplete.

24. **Multi-Attachment Support** — Convert from `singleFile()` to multi-file MediaLibrary collection for complaint evidence.

25. **SLA Due Date Visual Indicator** — Color-coded escalation level badge on complaint list (Green=Pending, Yellow=L1-L2, Orange=L3-L4, Red=L5/Breached).

26. **Bulk Status Update** — Multi-select + bulk status change for clearing resolved tickets at term end.

27. **Complainant Satisfaction Rating** — 1–5 star rating by complainant after resolution; feeds Frustration report.

28. **POCSO / RTE Compliance Flags** — Add `is_pocso_reportable` and `rte_related` booleans to `cmp_complaints`; mandatory escalation to Principal + management for such complaints (Indian legal requirement).

29. **Complaint Merge** — `merged_into_id` FK for deduplicating identical tickets.

30. **PTM Complaint Tagging** — `ptm_session_id` optional FK for complaints raised during Parent-Teacher Meetings.

### 14.5 Indian Education Domain Suggestions

31. **Grievance Redressal Committee Report** — CBSE mandates a committee reviewing unresolved complaints >30 days monthly. Auto-generate this committee report from the SLA Violation report.

32. **Multi-lingual AI Keywords** — Sentiment engine keywords are English-only; add Hindi transliterations (e.g., "pareshan", "dhakka", "maar") for accuracy with Indian school descriptions.

33. **Category Seeder** — Seed standard categories: Academic (Syllabus, Exam, Result), Infrastructure (Toilet, Canteen, Transport), Behavioral (Bullying, Corporal Punishment, Harassment), Staff Conduct, Health & Safety, Fee Related.

34. **WhatsApp/Email Acknowledgement** — Send ticket number to complainant's registered contact on creation.

---

## 15. Appendices

### Appendix A — RBS Coverage (Module D3)

```
Module D — Front Office & Communication
└── D3 — Complaint & Feedback Management

F.D3.1 — Complaint Handling
├── T.D3.1.1 — Register Complaint
│   ├── ST.D3.1.1.1  Enter complaint details     ✅ (partial bugs)
│   └── ST.D3.1.1.2  Assign complaint to staff   🟡 (action logging broken)
└── T.D3.1.2 — Complaint Resolution
    ├── ST.D3.1.2.1  Update resolution status    🟡 (hardcoded IDs)
    └── ST.D3.1.2.2  Add resolution notes        🟡 (hardcoded IDs)

F.D3.2 — Feedback Collection
└── T.D3.2.1 — Collect Feedback
    ├── ST.D3.2.1.1  Create feedback form         ❌ Not started
    └── ST.D3.2.1.2  Collect responses            ❌ Not started
```

### Appendix B — P0 Critical Issues Requiring Immediate Fix

| ID | File | Line | Issue | Fix |
|---|---|---|---|---|
| CT-03 | ComplaintController.php | 407 | `dd($e->getMessage())` in catch block | Log + return error response |
| CT-04 | ComplaintController.php | 833 | `dd('FILTER HIT', ...)` in filter() | Remove dd() + implement filter |
| CT-05 | ComplaintController.php | 357 | `status_id => 124` hardcoded | Dynamic key lookup |
| CT-06 | ComplaintController.php | 560 | action_type_id=197 hardcoded | Dynamic key lookup |
| CT-07 | ComplaintController.php | 575 | action_type_id=202 hardcoded | Dynamic key lookup |
| PL-01 | ComplaintPolicy.php | 31 | `tenant.vendor-dahsboard.create` wrong gate | `tenant.complaint.create` |
| CT-12 | ComplaintController.php | 591 | `destroy()` is empty | Implement soft-delete |
| FR-01 | Requests/ | — | Zero FormRequest classes | Create Store/UpdateComplaintRequest |

### Appendix C — Gap Analysis Score Summary (2026-03-22)

| Area | Score | Target |
|---|---|---|
| DB Integrity | 5/10 | 9/10 |
| Route Integrity | 6/10 | 9/10 |
| Controller Quality | 3/10 | 8/10 |
| Model Quality | 6/10 | 9/10 |
| Service Layer | 7/10 | 9/10 |
| FormRequest | 1/10 | 9/10 |
| Policy/Auth | 5/10 | 9/10 |
| Test Coverage | 0/10 | 7/10 |
| Security | 3/10 | 9/10 |
| Performance | 4/10 | 8/10 |
| **Overall** | **4.0/10** | **8.5/10** |

**Estimated remediation effort:**
- P0 fixes: 16–20 hours
- P1 fixes: 20–28 hours
- P2 fixes: 16–20 hours
- Test suite: 16–24 hours
- **Total: 68–92 hours**

---

## 16. V1 to V2 Delta

| # | Change | Type |
|---|---|---|
| 1 | DDL column names corrected: `default_expected_resolution_hours`, `default_escalation_hours_l1..l5` (all categories columns) | 🆕 Bug fix |
| 2 | DDL column corrected: `target_selected_id` (not `target_id`) on cmp_complaints | 🆕 Bug fix |
| 3 | DDL column corrected: `current_escalation_level` (not `escalation_level`) on cmp_complaints | 🆕 Bug fix |
| 4 | V2 confirms target columns (`target_department_id` etc.) ARE in DDL — V1 incorrectly flagged them as missing | 🆕 Correction |
| 5 | cmp_department_sla: `complaint_subcategory_id` is NULL-able in DDL (V1 said NOT NULL) | 🆕 Correction |
| 6 | cmp_medical_checks: `evidence_uploded` (DDL typo preserved); `result VARCHAR(20)` not a bigint FK | 🆕 Correction |
| 7 | cmp_complaint_actions: `action_timestamp` is the time column (not `created_at`); no SoftDeletes in DDL | 🆕 Correction |
| 8 | DDL Bug: `fk_cmp_medical_check` FK on `is_medical_check_required` TINYINT — logically incorrect FK | 🆕 New bug found |
| 9 | DDL Bug: `KEY idx_cmp_status (status)` — column `status` does not exist, must be `status_id` | 🆕 New bug found |
| 10 | cmp_complaint_categories DDL missing `deleted_at` — contradicts V1 which showed it | 🆕 Correction |
| 11 | Added FR-CMP-011 (Complaint Reopening) and FR-CMP-012 (Scheduled Escalation Job) as proposed features | 📐 New |
| 12 | Gap analysis score added: 4.0/10 overall; per-dimension breakdown | 🆕 New |
| 13 | Route issue RT-01 (duplicate registration complaint-mgt + complaints), RT-02 (missing EnsureTenantHasModule) | 🆕 New |
| 14 | Security issues added: SEC-02 (wrong policy permission), SEC-03 (CSRF on AJAX), SEC-04 (LIKE injection risk) | 🆕 New |
| 15 | Performance issues added: god-method index(), all-complaints get(), N+1 in map(), AI heatmap N+1 | 🆕 New |
| 16 | Architecture issues: logAction() uses raw DB::table() — should use Eloquent ComplaintAction::create() | 🆕 New |
| 17 | Entity group IDs (sys_groups) clarified as the correct FK reference for escalation groups (not sys_entity_groups) | 🆕 Correction |
| 18 | Appendix B (P0 critical issues table) added for developer quick-reference | 🆕 New |
| 19 | Appendix C (gap analysis score summary + effort estimate) added | 🆕 New |
| 20 | All test scenarios expanded from 15 to 26 items; coverage summary updated | 🆕 Enhanced |
