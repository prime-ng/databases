# PTM — Module Knowledge

> **Module:** Parent-Teacher Meeting (PTM)
> **Code:** PTM | **Prefix:** `ptm_` | **DB Layer:** tenant_db
> **Scope:** Tenant (per-school, data isolated per school)
> **Standalone module since:** 2026-06-21 (graduated from SchoolSetup sub-module DDL)
> **Last verified:** 2026-06-29 | Agent: pa-business-analyst
> **Status:** ~65–70% complete (core scheduling and booking built; payment sub-system unmodelled; booking uniqueness constraint degraded P0; no tests; parent-portal integration gap)

---

## Module Facts (verified 2026-06-29 against live filesystem)

| Attribute | Value | Source |
|-----------|-------|--------|
| Table prefix | `ptm_` | DDL v3, tenant migrations |
| DDL version | Sch_PTM_DDL_v3.sql (production-grade) | `2-DDL_Tenant_Consolidated/Sch_PTM_DDL_v3.sql` |
| Core DDL tables | 9 | Count of CREATE TABLE in DDL v3 |
| Payment migration tables | 7 (no models or controllers) | `database/migrations/tenant/2026_06_18_*` |
| Total tenant migration files | 17 (9 core 2026-06-16 + 8 payment 2026-06-18) | `/database/migrations/tenant/` |
| Controllers | 11 (9 entity + PtmManagementController + PtmCombinedViewController) | `Modules/Ptm/app/Http/Controllers/` |
| Models | 9 | `Modules/Ptm/app/Models/` |
| Services | 6 | `Modules/Ptm/app/Services/` |
| Form Requests | 18 (Store + Update x 9 entities) | `Modules/Ptm/app/Http/Requests/` |
| Policies | 9 (one per entity, in module's own `app/Policies/`) | `Modules/Ptm/app/Policies/` |
| Views | 58 (45 entity + 10 management + 3 combined) | `Modules/Ptm/resources/views/` |
| Route lines (web.php) | 103 | `Modules/Ptm/routes/web.php` |
| Jobs | 0 | — |
| Events / Listeners | 0 | — |
| Seeders | 1 (PtmSeeder) | `Modules/Ptm/database/seeders/` |
| Tests | 0 | — |
| FRD | PTM_FRD_Complete_2026-06-29.md | Generated 2026-06-29 |

View breakdown: 9 entity folders × 5 views (create/edit/index/show/trash) = 45 + management/index + 9 management/partials + 3 combined = 58 total.

---

## DDL Table Inventory

### Core Tables (DDL v3 — each has a corresponding migration and model)

| # | Table | Purpose |
|---|-------|---------|
| 1 | `ptm_events` | Top-level PTM event container (one per term/occasion per school). Holds booking window, default meeting mode, cancellation lead time, reschedule toggle, notification flags, default slot parameters. |
| 2 | `ptm_event_class_section_jnt` | Which class+section participates in an event, on which date, at what operating window, in which room or virtual link. UNIQUE on (event, class_section). |
| 3 | `ptm_batches_template` | Reusable teacher-owned batch template defining time window, slot duration, buffer, and capacity. One template can be applied to many events and class-sections. |
| 4 | `ptm_batch_slot_template` | Explicit time-grid rows within a batch (ordinal, start time, end time, is_break flag). UNIQUE on (batch, ordinal) and (batch, start_time). Break rows are BLOCKED on generation. |
| 5 | `ptm_assignments` | Bridge: links a batch template to an event + class-section, assigns a primary teacher, sets allocation mode (SCHOOL_ALLOCATED or PARENT_PICK). `is_published` flag triggers slot generation. Override fields for buffer and max participants. |
| 6 | `ptm_assignment_teacher_jnt` | Multi-teacher sub-batch: secondary teachers for a split class. Each entry carries per-teacher room/virtual-link override and a student_filter_json (roll range or specific student IDs). |
| 7 | `ptm_blockouts` | Teacher unavailability windows scoped to one event. NULL teacher_id = applies to all teachers in the event (school-wide blockout). Slot generation and booking both check this table. |
| 8 | `ptm_slots` | Concrete bookable meeting slot with absolute wall-clock datetime. UNIQUE on (teacher_id, slot_start) enforces no double-booking at DB level. Denormalized teacher_id for fast cross-class conflict checks. Status ENUM: AVAILABLE / BOOKED / FULL / BLOCKED / COMPLETED / CANCELLED. |
| 9 | `ptm_slot_bookings` | One booking per parent/student per slot. Uses VIRTUAL GENERATED COLUMN `active_booking_key` for unique constraint (see D35, D36 — degraded in migration, P0 gap). Status ENUM: CONFIRMED / CANCELLED / NO_SHOW / COMPLETED / RESCHEDULED. |

### Payment Tables (migrations only — no models, controllers, or services in PTM module)

| # | Migration file | Table | Migrate action |
|---|----------------|-------|----------------|
| 10 | 2026_06_18_100101 | `ptm_payment_gateways` | Extended existing table |
| 11 | 2026_06_18_100102 | `ptm_payments` | Rebuilt |
| 12 | 2026_06_18_100103 | `ptm_payment_refunds` | Created |
| 13 | 2026_06_18_100104 | `ptm_payment_audit_logs` | Created |
| 14 | 2026_06_18_100105 | `ptm_payment_webhooks` | Fixed |
| 15 | 2026_06_18_100106 | `ptm_offline_payment_records` | Created |
| 16 | 2026_06_18_100107 | `ptm_payment_reconciliations` | Created |

These 7 payment tables have ZERO corresponding models, controllers, or service classes in the Ptm module. The payment sub-system is schema-only — a P0 gap.

---

## Key Design Patterns

### 1. Three-Level Fallback for Slot Parameters
For slot duration, buffer, and capacity the system follows: Assignment override → Batch Template → PTM Event default. Implemented in `PtmSlotService::createSlotsForTeacher()`. If any level is NULL/0, falls through to the next.

### 2. Dual Slot Generation Mode
- **Static mode** (buffer_min = 0): reads explicit `ptm_batch_slot_template` rows, respects `is_break` markers.
- **Dynamic mode** (buffer_min > 0): recalculates slots on the fly from window start + slot duration + buffer, filling as many slots as fit before window end.
Both modes implemented in `PtmSlotService::createSlotsForTeacher()`.

### 3. Blockout Propagation
`PtmSlotService::syncSlotStatusForBlockout()` re-evaluates all affected slots when a blockout is created or removed, updating slot statuses. Both teacher-specific and school-wide (NULL teacher) blockouts are handled.

### 4. Concurrency Safety (Partial — P0 Gap)
- DB UNIQUE key `uq_ptmSlots_teacher_start` on `(teacher_id, slot_start)` prevents same-start double-booking at DB level.
- Application overlap check in `PtmSlotBookingService::validateOverlaps()` guards against different-duration slot overlaps.
- NO `SELECT ... FOR UPDATE` (pessimistic lock) used during booking — race condition window exists for the last available slot.
- The booking uniqueness GENERATED COLUMN is degraded (see D36 below).

### 5. Generated Column for Booking Uniqueness (Degraded — P0 per D36)
DDL v3 defines `ptm_slot_bookings.active_booking_key` as `GENERATED ALWAYS AS (CASE WHEN status = 'CONFIRMED' THEN student_id ELSE NULL END) VIRTUAL`. The UNIQUE constraint on (ptm_event_id, active_booking_key) should enforce one confirmed booking per student per teacher per event. However, per D36 (confirmed 2026-06-29), Laravel migrations across the platform degrade generated columns to plain writable columns. Since MySQL UNIQUE on all-NULL enforces nothing (NULL != NULL), this constraint currently provides zero protection. A student can create multiple confirmed bookings.

### 6. Notification Integration (Synchronous — P1 Gap)
`PtmSlotBookingService` directly creates `Notification` model records inside DB transactions for booking, cancellation, no-show, and completed events. No queued Jobs. Notification failure can interfere with booking completion. Uses `session('tenant_id')` which may be incorrect in async contexts.

### 7. Gate::authorize Pattern
All entity controllers use `Gate::authorize('tenant.ptm_{entity}.{action}')`. Policies are in `Modules/Ptm/app/Policies/` and registered in `PtmServiceProvider`. This follows the post-2026-04-02 per-module policy registration convention (D22). **Note: PtmManagementController AJAX endpoints (7 routes) do not show explicit Gate::authorize calls in web.php — auth coverage for these endpoints needs verification.**

### 8. Combined Management View
`PtmManagementController` provides a tabbed management dashboard with AJAX endpoints for class teachers, assignment teachers, event teachers, event students, and teacher slots. `PtmCombinedViewController` provides combined setup/bookings/scheduling views with Laravel partial views per entity.

---

## Known Gaps & Open Issues

### P0 (Critical / Blocker)

| ID | Issue | Evidence |
|----|-------|----------|
| SEC-PTM-001 | `ptm_slot_bookings.active_booking_key` GENERATED COLUMN degraded to plain column in migration (D36). UNIQUE constraint on active_booking_key = all-NULL → enforces nothing. Multiple confirmed bookings per student per teacher per event are possible. | D36 platform-wide sweep; migration file `2026_06_16_094315_create_ptm_slot_bookings_table.php` |
| PAY-PTM-001 | 7 payment tables (ptm_payment_gateways, ptm_payments, ptm_payment_refunds, ptm_payment_audit_logs, ptm_payment_webhooks, ptm_offline_payment_records, ptm_payment_reconciliations) have zero models, controllers, or services. Payment sub-system is schema-only. | Filesystem: `app/Models/` has 9 models matching 9 core tables only |
| TEST-PTM-001 | 0 tests across all PTM code. Booking race conditions, slot generation logic, and cascade deletes are untested. | `Modules/Ptm/tests/` empty |

### P1 (High Priority)

| ID | Issue | Evidence |
|----|-------|----------|
| PARENT-PTM-001 | No parent-facing booking screens exist in the PTM module. The ParentPortal module (28 controllers) presumably provides this UI, but the integration contract between PTM and ParentPortal is undocumented. Parent-Pick booking mode requires ParentPortal to call PTM's service layer. | PTM module has no parent-role views; `Modules/ParentPortal/` contains 07-PTM-and-Grievances.md |
| JOB-PTM-001 | No queued Jobs for notification dispatch. Notifications fire synchronously inside DB transactions. Notification failure can cause booking rollback. | 0 Jobs in module |
| REPORT-PTM-001 | No dedicated report controllers or views. PtmManagementController has AJAX data endpoints but no formatted report screens for booking summary, attendance rate, or teacher schedule. | Views: management/partials only; no dedicated report views |
| AUTH-PTM-001 | PtmManagementController 7 AJAX routes need Gate::authorize verification. | web.php: AJAX routes registered without explicit auth gates visible |
| AUTOALLOC-PTM-001 | Auto-allocation for SCHOOL_ALLOCATED mode (admin auto-assigns each student to an available slot) is mentioned in V1 specs but not implemented. Admin must allocate manually one-by-one. | V1 SlotBookings.md section: "admin can also use auto-allocate"; no such method in controllers |
| ENUM-PTM-001 | `allocation_mode`, `meeting_mode`, and `status` fields use ENUM rather than `sys_dropdown_table` FKs (D29). D35 notes this as deferred to v3. Schools cannot extend these values without a schema migration. | DDL v3 ENUMs confirmed |

### P2 (Standard)

| ID | Issue |
|----|-------|
| REMIND-PTM-001 | No reminder notifications (T-24h, T-1h before meeting) |
| CALENDAR-PTM-001 | No iCal / calendar export for confirmed meeting schedules |
| PDF-PTM-001 | No teacher schedule PDF or printable booking list |
| WAITLIST-PTM-001 | No waitlist for full slots |

---

## Design Decisions (PTM-specific)

| Decision | Detail | Source |
|----------|--------|--------|
| D35: PTM DDL v1 → v2 architecture | 10 tables (v2), convention rebuild, `active_booking_key` VIRTUAL column pattern, allocation_mode ENUM, denormalized teacher_id on slots. v3 merged ptm_event_settings into ptm_events. | decisions.md D35 |
| D36: GENERATED columns degraded | Platform-wide: PTM `ptm_slot_bookings.active_booking_key` specifically listed as degraded. Fix: add `->virtualAs("CASE WHEN status='CONFIRMED' THEN student_id ELSE NULL END")` to migration. | decisions.md D36 |
| D-PTM-004 | `teacher_id` denormalized onto `ptm_slots` so the cross-class double-booking UNIQUE key works without joins | D35 |
| D-PTM-005 | `active_booking_key` VIRTUAL = `student_id` when CONFIRMED else NULL; allows re-book after cancel (NULLs exempt from UNIQUE) | D35 |
| D-PTM-006 | Audit trail via status FSM on bookings (`CONFIRMED → CANCELLED → CONFIRMED` allowed via re-insert), not row deletion | D35 |
| Dual slot generation | Static (reads batch grid rows) vs Dynamic (recalculates from window bounds) depending on buffer_min > 0 | PtmSlotService code |
| Three-level fallback | Assignment override → Batch Template → Event default for duration/buffer/capacity | PtmSlotService code |

---

## Cross-Module Dependencies

### Inbound (PTM reads from)
| Source Module | Tables / Entities | Why |
|---------------|-------------------|-----|
| SchoolSetup | `sch_class_section_jnt` | Class-section participation in events |
| SchoolSetup | `sch_rooms` | Physical room assignment for in-person meetings |
| SchoolSetup | `sys_users` (teachers/admins) | Teacher identification, creator tracking |
| SchoolSetup | `sch_org_academic_sessions_jnt` | Academic year scoping of events |
| TimetableFoundation | `sch_academic_terms` | Term-level event categorisation |
| StudentProfile | `std_students` | Booking student identification |

### Outbound (PTM feeds)
| Target Module | Mechanism | What |
|---------------|-----------|------|
| Notification | `Notification::create()` (direct model, synchronous) | Booking confirmed, cancelled, no-show, completed events (parent + teacher) |
| ParentPortal | Service layer integration (contract undocumented) | Parent-pick booking flow, confirmed meetings display |

---

## FRD Summary

| Artifact | Value |
|----------|-------|
| FRD file | `PTM_FRD_Complete_2026-06-29.md` |
| Date generated | 2026-06-29 |
| Requirements (REQ) | 17 (P0: 8, P1: 8, P2: 1) |
| Business Rules (BR) | 15 |
| Workflows | 5 |
| Reports (RPT) | 5 |
| Enhancements (ENH) | 7 |
| NFRs | 9 |
| Risks | 8 |

---

## Lessons Learned

- [2026-06-29 | pa-business-analyst] PTM has 7 payment migration tables (ptm_payment_gateways, ptm_payments, etc.) with zero corresponding models — verify payment sub-system scope and ownership before any payment feature work. These may be intended for a future PTM registration fee collection feature.
- [2026-06-29 | pa-business-analyst] PTM slot generation has two distinct modes (Static vs Dynamic) depending on whether buffer_min > 0. Static reads from `ptm_batch_slot_template` rows; Dynamic recalculates from window bounds. Both are in `PtmSlotService::createSlotsForTeacher()`.
- [2026-06-29 | pa-business-analyst] D36 platform-wide sweep explicitly lists `ptm_slot_bookings.active_booking_key` as a degraded GENERATED COLUMN. The booking uniqueness constraint (1 confirmed booking per student per teacher per event) provides zero protection at DB level. Application-level check in `PtmSlotBookingService::create()` is the only guard — but it is not race-condition safe.
- [2026-06-29 | pa-business-analyst] 58 views verified: 9 entities × 5 (create/edit/index/show/trash) = 45 + management/index + 9 partials + 3 combined = 58. Modules-map count confirmed accurate.
- [2026-06-29 | pa-business-analyst] Both V1 screen specs (PTM_v2/ folder) and D35 in decisions.md exist and are the primary business requirement sources. No consolidated V2 requirement document exists for PTM.
- [2026-06-29 | pa-business-analyst] The D35 DDL v2 design described `ptm_event_settings` as a separate 1:1 table. The current DDL v3 merged those fields directly into `ptm_events`. The live code (PtmEvent model) confirms the merged approach.

---

## Pending Next Steps

1. **P0 Fix:** Add `.virtualAs("CASE WHEN \`status\` = 'CONFIRMED' THEN \`student_id\` ELSE NULL END")` to the `ptm_slot_bookings` migration for `active_booking_key` (D36 remediation).
2. **P0 Fix:** Add `SELECT ... FOR UPDATE` on `ptm_slots` during booking creation to close the race condition window.
3. **P0:** Model and implement the payment sub-system (7 tables: ptm_payment_gateways, ptm_payments, etc.) — clarify ownership (PTM module vs Payment module).
4. **P0:** Write Pest tests for slot generation, booking creation, booking uniqueness, and cancellation flow.
5. **P1:** Clarify and document the ParentPortal integration contract for parent-pick booking.
6. **P1:** Move notifications to queued Jobs (extract `PtmBookingNotificationJob`).
7. **P1:** Verify Gate::authorize coverage on PtmManagementController AJAX endpoints.
8. **P1:** Build reporting screens (booking summary, teacher schedule, attendance report).
9. **P2:** Implement auto-allocation for SCHOOL_ALLOCATED mode.
10. **P2:** Add reminder notifications, iCal export, teacher schedule PDF.
11. **Technical Audit:** Hand off to Technical Auditor (Mode X) for 12-layer audit: focus on booking race condition (P0), ENUM vs D29 compliance, notification synchronous dispatch in transactions, FormRequest authorize() patterns (D30).

---

## Version History

| Version | Date | Agent | Notes |
|---------|------|-------|-------|
| 1.0 | 2026-06-29 | pa-business-analyst | Initial seed from live code inspection. Sources: DDL v3, 17 tenant migrations, 11 controllers, 9 models, 6 services, V1 screen specs (PTM_v2/), decisions.md D35 + D36. FRD_Complete generated same day. |
