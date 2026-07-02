# SLB — Syllabus Management
## Requirement Conditions Catalog
**Module:** SLB | **Date:** 2026-06-30 | **Reference:** SLB_FRD_Complete_2026-06-30.md (Part B)

---

## 1. Platform-Level Conditions (inherited by all SLB controllers)

| Condition Code | Condition | Enforcement Layer | Status |
|---------------|-----------|------------------|--------|
| CON-SLB-001 | All routes require auth + verified middleware. Unauthenticated requests return 401; unverified email returns redirect to verify. | Middleware (global) | Verify SyllabusServiceProvider middleware array post-route-migration |
| CON-SLB-002 | Tenant isolation: all Eloquent queries run against the active tenant's isolated database connection. No global-db tables are written in Syllabus controllers. | stancl/tenancy v3.9 (database-per-tenant) | Correctly implemented |
| CON-SLB-003 | Soft-delete pattern: every model with SoftDeletes must use delete() in destroy(); forceDelete() is allowed only via explicit /force-delete routes. | Application layer | P0 BUG: TopicController::destroy() calls forceDelete(). Fix required. |
| CON-SLB-004 | All store() and update() methods must access input exclusively via $request->validated(). Never use $request->all() or $request->input() directly for persistence. | Application layer | P0 BUG: CompetencieController violates this. Fix required. |
| CON-SLB-005 | Gate::authorize() is called at the top of every controller method that reads or modifies data. No method may run without an authorization check. | Authorization layer | P0 BUG: CompetencieController has ZERO auth checks. TopicController is partial. |
| CON-SLB-006 | FormRequest::authorize() must not return hardcoded true. It must return a Gate check or Policy evaluation. (D30 systemic pattern) | Application layer (FormRequest) | P0 BUG: All 15 Syllabus FormRequests likely return hardcoded true. Fix required. |
| CON-SLB-007 | EnsureTenantHasModule middleware must be active on all Syllabus routes. This prevents tenants that have not subscribed to the Syllabus module from accessing any Syllabus endpoint. | Middleware | UNVERIFIED: Post-migration from routes/tenant.php to Modules/Syllabus/routes/web.php; must check SyllabusServiceProvider. |
| CON-SLB-008 | ActivityLog must be written on all data mutations (create, update, delete, restore, toggle). Uses the activityLog() helper from app/Helpers/activityLog.php. | Helper | Spot-check: verify LessonController, SyllabusScheduleController have activityLog calls |
| CON-SLB-009 | No raw SQL strings in any controller or service. All queries use Eloquent methods or DB::select() with parameterized bindings. | Code review gate | Not verified comprehensively; spot-check SyllabusController::report() aggregation queries |
| CON-SLB-010 | Multi-tenancy Artisan commands must call Tenant::all()->each(function($tenant) { tenancy()->initialize($tenant); ... tenancy()->end(); }) to isolate per-tenant data. | Application layer | CORRECTLY IMPLEMENTED in ReleaseLmsResources |

---

## 2. Module-Specific Conditions

| Condition Code | Condition | Trigger | Expected Behaviour |
|---------------|-----------|---------|-------------------|
| CON-SLB-011 | A lesson's analytics_code (and topic's analytics_code) must never be updated after the initial insert. The model's booted() hook sets the code once; the update() method must explicitly unset or ignore this field. | Topic / Lesson update | Model booted() hook sets code; update never overwrites it. Verify no update() path overwrites analytics_code. |
| CON-SLB-012 | The materialized path (/parentId1/.../topicId/) on slb_topics must be recomputed whenever a topic's parent changes. The current implementation computes it in the created() hook but does NOT recompute on parent update. | Topic parent change | RISK: Moving a topic to a different parent without recomputing the path corrupts subtree queries. |
| CON-SLB-013 | Coverage percentage is computed as (is_active = 1 entries) / (total entries) × 100, scoped to the active session + class + subject filter. Entries with deleted_at NOT NULL are excluded. | Coverage calculation (report(), dashboard stats) | Implemented. Note: diverges from V2 spec which used taught_by_teacher_id AND can_use_for_syllabus_status. Informational gap only. |
| CON-SLB-014 | When marking a schedule entry as released (is_active = 1), the taught_by_teacher_id must be recorded. If the delivering teacher differs from assigned_teacher_id, the taught_by value takes precedence for reporting. | SyllabusScheduleController::markComplete() | Implemented. |
| CON-SLB-015 | The three LMS release level settings (homework, quiz, quest) must each reference a different topic hierarchy level. The saveSetting() method validates uniqueness before persisting. | SyllabusController::saveSetting() | Implemented. |
| CON-SLB-016 | Locked schedule entries (is_locked = 1) are skipped by both saveScheduling() and autoSchedule() bulk operations. Locked entries still receive manual releases via markComplete(). | saveScheduling(), autoSchedule() | Implemented. |
| CON-SLB-017 | Competency parent assignment must not create a circular reference. Direct circular (A → A) must be blocked. Deep circular (A → B → C → A) must also be blocked by a recursive ancestor-check. | CompetencieController::store() / update() | PARTIAL: Only direct circular implemented. Deep circular check missing (GAP-SLB-011). |
| CON-SLB-018 | ReleaseLmsResources Artisan cron should only process schedule entries that are actionable (is_active = 1 or planned_end_date <= today), not all historical entries. This prevents unbounded growth in processing time at scale. | ReleaseLmsResources::handle() | NOT IMPLEMENTED (GAP-SLB-008). Fix: add date/status filter to the schedule query. |
| CON-SLB-019 | The slb_syllabus_schedule.is_active = 1 flag serves dual purpose: (a) records that the topic was taught/released; (b) controls LMS resource visibility. Ensure downstream consumers use this flag consistently. | Any code reading is_active | Design divergence noted. All downstream consumers (cron, manual toggle, report()) use is_active correctly. |
| CON-SLB-020 | Study notes (slb_notes, slb_notes_files, slb_notes_downloads, slb_notes_ratings) are scoped to the tenant and never expose one student's ratings to another. Download tracking must record student_id for analytics but this data is classified as Internal. | StudyNotesController (not yet built) | Condition for when StudyNotesController is built in Sprint 3. |

---

## 3. Validation Edge Cases (Quick Reference)

| Code | Scenario | Required Outcome |
|------|----------|----------------|
| VAL-SLB-001 | Topic with parent in different lesson | Reject |
| VAL-SLB-002 | Level-0 topic with parent set | Reject |
| VAL-SLB-003 | Topic level exceeding max level type | Reject |
| VAL-SLB-004 | Delete topic with children | Reject |
| VAL-SLB-005 | Delete lesson with topics | Reject or warn |
| VAL-SLB-006 | Bulk import with in-file duplicate codes | Row-level error; clean rows still import |
| VAL-SLB-007 | Competency deep circular (A→B→C→A) | Reject (NOT CURRENTLY IMPLEMENTED) |
| VAL-SLB-008 | Two release levels set to same hierarchy level | Reject with named conflict |
| VAL-SLB-009 | planned_periods exceeds daily allocation limit | Reject per row in saveSequencing() |
| VAL-SLB-010 | autoSchedule with planned_periods = 0 | Skip topic; assign no dates |
| VAL-SLB-011 | Mark complete on already-released entry | Idempotent; no error |
| VAL-SLB-012 | Toggle lock on released entry | Permitted (lock = date freeze, not release freeze) |
| VAL-SLB-013 | Overlapping performance category ranges | Reject (NOT CURRENTLY IMPLEMENTED) |
| VAL-SLB-014 | Overlapping grade division ranges | Reject (NOT CURRENTLY IMPLEMENTED) |
| VAL-SLB-015 | Restore topic when parent was force-deleted | Should warn or block; NOT CURRENTLY GUARDED |
| VAL-SLB-016 | System-defined lesson edit/delete attempt | Reject (NOT CURRENTLY IMPLEMENTED) |
| VAL-SLB-017 | Grade division edit after results published | Reject (is_locked guard — verify implementation) |

---

*Generated: 2026-06-30 | Reference: SLB_FRD_Complete_2026-06-30.md Part B*
