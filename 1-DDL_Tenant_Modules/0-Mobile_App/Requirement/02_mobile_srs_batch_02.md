# Mobile SRS — Batch 02 (Dashboards)

> Index: `02_mobile_srs_index.md`. Features: F-010, F-011, F-012, F-013.

---

## F-010: Student Dashboard

### 1. Overview
Glance-home for Student. Tiles: today's classes, today's attendance, due homework count, fee dues, upcoming exams, unread notifications. Each tile deep-links into the corresponding feature. Wraps the existing `StudentDashboardAggregatorService` (D4) into a single mobile-shaped response.

### 2. User Stories
- **US-010.1** *As a student opening the app, I want all today's must-know info on one screen, so that I don't navigate three menus to know if I'm late.*
  - Edge — no school today (holiday): tile shows "🎉 Holiday — {reason}".
  - Edge — fully offline: cached snapshot with "as-of HH:MM" timestamp.
- **US-010.2** *As a student with no due homework, the homework tile shows "All caught up" and never alarms me.*

### 3. Functional Requirements
- **FR-010.1** Single-call aggregator: `GET /student/dashboard` → returns all tiles in one payload.
- **FR-010.2** Each tile data is **timestamped**; offline UI shows the timestamp.
- **FR-010.3** Tile order fixed at v1 (Q-OQ — customizable in v1.1).
- **FR-010.4** Tile counts (e.g. "3 due homework") MUST exclude `deleted_at IS NOT NULL` rows (D7 soft deletes).
- **FR-010.5** Aggregator MUST be a single-query optimised service — no N+1 (`student-parent-portal.md` S2 warning).

### 4. Screen Specifications

#### S-010.1 — Home (Student)
```
┌──────────────────────────────────┐
│ Hi, Asha 👋                  [🔔3]│
│ ─────────────────────────────── │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Today's class │ │ Attendance│ │
│ │   Period 3:M  │ │ ✅ Present │ │
│ │  Math (Mr K) │ │  92% term  │ │
│ └──────────────┘ └────────────┘ │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Homework      │ │ Fees       │ │
│ │   3 due        │ │ ₹12,500   │ │
│ │  1 overdue ❗ │ │ overdue ❗ │ │
│ └──────────────┘ └────────────┘ │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Upcoming exam │ │ Notices    │ │
│ │ Math · 3 days│ │  2 unread  │ │
│ └──────────────┘ └────────────┘ │
└──────────────────────────────────┘
```
- Pull-to-refresh.
- Tap tile → deep-link to F-030 / F-021 / F-040 / F-060 / F-052 / F-080.

States: loading skeleton; empty (no school today) — single banner; error inline; offline — banner + cached tiles.

### 5. API Contracts

#### `GET /api/mobile/v1/student/dashboard`
- **Auth:** Bearer + tenant header.
- **Status:** NEW (BG-34 aggregator). Module: StudentPortal.
- **Response 200:**
  ```json
  { "data": {
    "as_of":"2026-05-08T08:14:00Z",
    "today": {
      "current_period": { "period_no":3,"subject":"Math","teacher":"Mr K","room":"R-12" },
      "attendance":     { "status":"PRESENT","term_pct":92.0 },
      "homework":       { "due_count":3,"overdue_count":1 },
      "fees":           { "amount_due":12500,"overdue":true },
      "upcoming_exam":  { "subject":"Math","date":"2026-05-11" },
      "notices_unread": 2
    }
  }}
  ```
- **4xx:** `403 NOT_A_STUDENT`.
- **Caching:** client cache 5 min; pull-to-refresh forces network.
- **Backend gap:** BG-34 aggregator endpoint; existing `StudentDashboardAggregatorService` to be wrapped — BUG-007 null-pointer-on-session must be fixed first.

### 6. Data Model (client-side)
```sql
cache_dashboard_student (
  payload_json TEXT, as_of INTEGER PRIMARY KEY
)
```
Backend mapping: aggregates `std_attendance_details`, `lms_homework`, `lms_homework_submissions`, `tt_timetable_cells`, `fin_fee_invoices`, `lms_exam_allocations`, `ntf_notifications`.

### 7. Offline Behavior
Read-only cached. Last-good payload survives offline; "as-of" timestamp shown.

### 8. Push Notifications
Consumes (does not emit): `HOMEWORK_PUBLISHED`, `EXAM_REMINDER`, `FEE_DUE_SOON`, `ATTENDANCE_ABSENT`, `NOTICE_PUBLISHED` — each updates the relevant tile via `SYNC_HINT` data-message.

### 9. Permissions & Security
- Read-only.
- Aggregator MUST scope by authenticated student_uuid only (no path/query student_id).
- Audit: not logged (read-only, high-frequency).

### 10. Non-Functional Requirements
- Cached render < 300 ms; network refresh < 1.8 s p50.
- Accessibility: each tile is a labelled button; counters announce "3 due homework, 1 overdue".
- Localization: `f010.tile.{class,attendance,homework,fees,exam,notices}`.

### 11. Acceptance Criteria
- **AC-010.1** Cold-cached dashboard renders in < 300 ms.
- **AC-010.2** Single network round-trip — Charles/mitmproxy shows exactly one `/student/dashboard` call on refresh.
- **AC-010.3** Soft-deleted homework rows excluded from `due_count`.

### 12. Dependencies
- F-002. BG-34 aggregator. BUG-007 fix.

### 13. Out of Scope
- Customizable tile order — v1.1.
- Charts on home (term-trend, fee history) — drilldown screens only at v1.

---

## F-011: Parent Dashboard

### 1. Overview
Per-active-child summary (cycles via F-005 child switcher). Tiles: today's attendance, today's class count, fee balance, recent test scores, current HPC status, transport pickup status, unread notifications. Greenfield — depends on **ParentPortal** (PLANNED, BG-28).

### 2. User Stories
- **US-011.1** *As a parent, I want a summary of my child's day in one screen, so I know if to call the teacher.*
- **US-011.2** *As a parent of two children, switching child via F-005 must completely refresh this screen.*
- **US-011.3** *As a fee-paying parent, the fee tile must show next-due-date in addition to amount.*

### 3. Functional Requirements
- **FR-011.1** Aggregator scoped by `(parent_uuid, X-Active-Student-Id)` — server validates binding (BR-PPT-012).
- **FR-011.2** Tiles match Student dashboard but in "parent voice" (e.g. "Asha was absent today" vs "You were absent today").
- **FR-011.3** Transport tile present only if child enrolled in transport (`tpt_student_assignment.is_active=1`).
- **FR-011.4** HPC tile present only when there is an active HPC report (status `PUBLISHED`).
- **FR-011.5** Soft deletes filtered (D7).

### 4. Screen Specifications

#### S-011.1 — Home (Parent)
```
┌──────────────────────────────────┐
│ [👶 Asha (VII-B) ▾]          [🔔]│
│ ─────────────────────────────── │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Attendance    │ │ Fees       │ │
│ │ ✅ Present    │ │ ₹12,500    │ │
│ │ 92% term     │ │ due 15-May │ │
│ └──────────────┘ └────────────┘ │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Today's class │ │ Transport  │ │
│ │   6 periods   │ │ 🚌 Boarded │ │
│ │              │ │  07:42      │ │
│ └──────────────┘ └────────────┘ │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Recent scores │ │ HPC        │ │
│ │ Math 87/100  │ │ Term 1 ✓  │ │
│ └──────────────┘ └────────────┘ │
└──────────────────────────────────┘
```
States as F-010.

### 5. API Contracts

#### `GET /api/mobile/v1/parent/dashboard`
- **Header:** `X-Active-Student-Id: <uuid>` REQUIRED.
- **Status:** NEW (BG-12, BG-28, BG-34). Module: ParentPortal (PLANNED).
- **Response 200:** mirrors F-010 with parent-voice fields, plus `transport`, `hpc` blocks.
- **4xx:** `400 MISSING_ACTIVE_STUDENT`, `403 CHILD_ACCESS_REVOKED`, `404 PARENT_NOT_FOUND`.
- **Backend gap:** BG-28 ParentPortal module + `ParentDashboardAggregatorService`; BR-PPT-012 policy enforcement.

### 6. Data Model
```sql
cache_dashboard_parent (
  student_uuid TEXT PRIMARY KEY, payload_json TEXT, as_of INTEGER
)
```
Per-child cache keyed by uuid so switcher feels instant.

### 7. Offline Behavior
Read-only cached per child.

### 8. Push Notifications
Consumes parent-targeted pushes from §7 of index (ATTENDANCE_*, FEE_*, TRANSPORT_*, HPC_*, EXAM_RESULT_*).

### 9. Permissions & Security
- **CRITICAL** — IDOR primary risk per `student-parent-portal.md`. Endpoint MUST validate guardian binding.
- Audit: 403s logged at WARN.
- `ParentChildPolicy` (BR-PPT-012) is a hard gate.

### 10. Non-Functional Requirements
- Performance: as F-010.
- Localization: `f011.tile.*` plus parent-voice strings.
- Analytics: `parent_dashboard_view{student_uuid}`.

### 11. Acceptance Criteria
- **AC-011.1** Switching child triggers a full cache lookup for the new uuid; if cache miss, network call within 1.8 s.
- **AC-011.2** Tampered `X-Active-Student-Id` returns 403; client recovers gracefully.
- **AC-011.3** Child without transport assignment hides the transport tile entirely.

### 12. Dependencies
- F-002, F-005. BG-28 ParentPortal (XL). BG-34 aggregator. BR-PPT-012.

### 13. Out of Scope
- All-children consolidated view (Q-OQ); v1.1.
- Multi-tenant parent (parent of children at two different Prime-AI tenants) — out of scope; each tenant requires separate install / switch.

---

## F-012: Teacher Dashboard

### 1. Overview
Today's classes period-by-period, pending attendance to mark, homework to grade, pending leave approvals, substitution alerts. Aggregates `tt_timetable_cells`, `std_attendance_details`, `lms_homework`, `sch_employee_leave_applications`.

### 2. User Stories
- **US-012.1** *As a teacher, I want my full day at a glance, so I know which classes still need attendance marking.*
- **US-012.2** *As a class teacher, I want a class-attendance summary widget for my homeroom.*
- **US-012.3** *As an approver, I want pending leave requests directly on my home, so I don't miss them.*

### 3. Functional Requirements
- **FR-012.1** Period strip lists today's periods chronologically with attendance status (`marked`/`pending`).
- **FR-012.2** "To grade" widget = count of `lms_homework_submissions` with `status='SUBMITTED'` for homework owned by this teacher.
- **FR-012.3** Approvals widget = count of `sch_employee_leave_applications` where `current_approver_id = me AND status='PENDING'`.
- **FR-012.4** Class-teacher widget appears only if `sch_class_section_jnt.class_teacher_id = me`.

### 4. Screen Specifications

#### S-012.1 — Home (Teacher)
```
┌──────────────────────────────────┐
│ Good morning, Mrs Verma          │
│                                  │
│ Today  Mon 8 May                 │
│ ──── Period strip ──────────     │
│ [P1 09:00 VII-B Math   ✅mark]   │
│ [P2 09:45 VIII-A Math  ⏳pending]│
│ [P3 10:30 IX-C  Math   ⏳pending]│
│ ...                              │
│ ┌──────────────┐ ┌────────────┐ │
│ │ To grade  12 │ │ Approvals 3│ │
│ └──────────────┘ └────────────┘ │
│ ┌──────────────────────────────┐│
│ │ My class (VII-B) attendance  ││
│ │   present 28 / 32  abs 4    ││
│ └──────────────────────────────┘│
└──────────────────────────────────┘
```

States: loading, empty (no schedule today / off-day), error, offline.

### 5. API Contracts

#### `GET /api/mobile/v1/teacher/dashboard`
- **Status:** NEW (BG-34). Module: SmartTimetable + SchoolSetup + LmsHomework. Q-OQ — owning module: extend StudentPortal-style with sister `TeacherPortal` module, or compose in `Modules/Dashboard/` with proper auth.
- **Response 200:**
  ```json
  { "data":{
    "today_periods":[
      {"period_id":"...","period_no":1,"start":"09:00","end":"09:45",
       "class_section":"VII-B","subject":"Math","attendance":"MARKED|PENDING","attendance_count":{"present":28,"absent":4}}
    ],
    "to_grade_count":12,
    "approvals_pending":3,
    "homeroom":{"class_section":"VII-B","present":28,"absent":4,"late":0}
  }}
  ```
- **Backend gap:** BG-34. Existing `Modules/Dashboard` has zero auth (P0 risk in `progress.md`); MUST be fixed before mobile uses it.

### 6. Data Model
`cache_dashboard_teacher` mirrors payload.

### 7. Offline Behavior
Read-only cached. Period strip remains visible; "Mark attendance" deep-link to F-020 enters offline-queue mode.

### 8. Push Notifications
Consumes: `LEAVE_PENDING_APPROVAL`, `HOMEWORK_GRADED` (count refresh).

### 9. Permissions & Security
- **CRITICAL** — `Modules/Dashboard` has ZERO Gate auth currently. Mobile dashboard MUST authorize per teacher_id.
- Audit: not logged (read-only).
- Reference `security-rules.md` §"Role isolation".

### 10. Non-Functional Requirements
- Performance: cached < 300 ms; network < 2 s p50.
- Localization: `f012.tile.*`, `f012.period.*`.
- Analytics: `teacher_dashboard_view`.

### 11. Acceptance Criteria
- **AC-012.1** A teacher with 6 periods today sees 6 period rows in chronological order.
- **AC-012.2** Marking attendance via F-020 immediately updates the period row to `MARKED` (Riverpod state propagation).
- **AC-012.3** A non-teacher accessing this endpoint receives 403.

### 12. Dependencies
- F-002. BG-34 aggregator. Module ownership decision (Q-OQ from F-012). Dashboard auth fix.

### 13. Out of Scope
- Long-form analytics (term-trend, student-risk lists) — web-only, deferred.

---

## F-013: Principal / Head Dashboard (P1)

### 1. Overview
Daily KPIs: attendance %, today's collection, open complaints, pending approvals, notice draft inbox. Aggregator across SchoolSetup, StudentProfile, StudentFee, Hpc, Notification.

### 2. User Stories
- **US-013.1** *As a principal, I want one screen of school KPIs, so I can react before the day's first meeting.*
- **US-013.2** *As an approver, I want a unified queue of approvals (leave, exam config, HPC publish), so I can clear them on the move.*

### 3. Functional Requirements
- **FR-013.1** KPI tiles: school-wide attendance % today, collection ₹ today, open complaint count + SLA-breached count, pending approvals total.
- **FR-013.2** Approvals widget shows top-5 pending; deep-link to a unified approvals queue.
- **FR-013.3** Aggregator response cached 60 s server-side to avoid hot-path queries.
- **FR-013.4** Auth: `Spatie role IN (Principal, VicePrincipal, SchoolAdmin)`.

### 4. Screen Specifications

#### S-013.1 — Home (Principal)
```
┌──────────────────────────────────┐
│ Good morning, Principal          │
│                                  │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Attendance   │ │ Collection │ │
│ │   88.4%      │ │ ₹ 1.2 L    │ │
│ │  ▼ vs y'day  │ │ (today)    │ │
│ └──────────────┘ └────────────┘ │
│ ┌──────────────┐ ┌────────────┐ │
│ │ Complaints   │ │ Approvals  │ │
│ │ 14 open · 2🚨│ │ 7 pending  │ │
│ └──────────────┘ └────────────┘ │
│ Pending approvals (top 5):       │
│  • Leave: Mr K · 2 days          │
│  • HPC publish: Class IV-B       │
│  ...                             │
└──────────────────────────────────┘
```

### 5. API Contracts

#### `GET /api/mobile/v1/principal/dashboard`
- **Auth:** role-gated (Principal / VicePrincipal / SchoolAdmin).
- **Status:** NEW (BG-34). Module: `Modules/Dashboard/` after auth fix, or new `Modules/Hpc/`-side aggregator.
- **Response 200:**
  ```json
  {"data":{
    "attendance":{"pct_today":88.4,"delta_vs_yesterday":-0.6},
    "collection":{"amount_today":120000,"target_today":150000},
    "complaints":{"open":14,"sla_breached":2},
    "approvals":{"pending":7,"items":[
      {"type":"LEAVE","subject":"Mr K","duration_days":2,"id":"..."},
      {"type":"HPC_PUBLISH","subject":"Class IV-B","id":"..."}
    ]}
  }}
  ```
- **Backend gap:** BG-34; Dashboard module auth fix; reporting tables for KPIs may not exist yet (P2 OQ).

### 6. Data Model
`cache_dashboard_principal` (60 s TTL).

### 7. Offline Behavior
Read-only cached.

### 8. Push Notifications
Consumes: `LEAVE_PENDING_APPROVAL`, `TRANSPORT_INCIDENT` (escalation), `HPC_PARENT_FORM_DUE` (publishing flag).

### 9. Permissions & Security
- Role-gate via Spatie roles.
- Audit log: `PRINCIPAL_DASHBOARD_VIEWED` (compliance — who saw fee figures when).

### 10. Non-Functional Requirements
- Performance: < 2 s; KPIs may use cached aggregates.
- Localization: `f013.tile.*`.
- Analytics: `principal_dashboard_view`.

### 11. Acceptance Criteria
- **AC-013.1** A non-principal accessing the endpoint receives 403.
- **AC-013.2** Aggregator returns within 2 s; if individual KPI fails (e.g. complaints DB unavailable), the tile shows "—" but other tiles render.

### 12. Dependencies
- F-002. BG-34. Dashboard module auth (cross-cutting).
- Reporting tables for collection trends (may need a v1.1 add).

### 13. Out of Scope
- Drilldowns (collection by class, attendance by section) — phased in v1.1+.
- Multi-school principal (district view) — not planned.

---

> End Batch 02. Continue to `02_mobile_srs_batch_03.md` (Attendance + Academics).
