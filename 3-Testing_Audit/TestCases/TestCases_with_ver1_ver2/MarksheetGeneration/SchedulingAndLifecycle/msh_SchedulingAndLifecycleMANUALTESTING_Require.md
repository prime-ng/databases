# Scheduling & Lifecycle — Manual Test Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (`msh_`) |
| Feature / Screen | Scheduling & Lifecycle (`04-Scheduling-and-Lifecycle.md`) |
| Combined URL | `/marksheet-generation/scheduling` (`route('marksheet-generation.scheduling.combined')`, gate `tenant.msh-scheduling.view`) |
| Schedule resource | `/marksheet-generation/marksheet-schedule` (param `marksheet_schedule`) |
| Lifecycle endpoints | POST `…/{id}/review`, `…/{id}/publish`, `…/{id}/lock`, `…/{id}/unlock`, `…/{id}/compute`; GET `…/{id}/precheck`, `…/{id}/export` |
| Controllers | `MarksheetScheduleController`, `ScheduleClassController`, `SubjectPracticalConfigController`, `MarksheetGenerationController::scheduling()` |
| Services | `MarksheetScheduleService`, `MarksheetScheduleLifecycleService`, `MarksheetComputationService`, `MarksheetConfigService` |
| Models | `MarksheetSchedule` (SoftDeletes), `ScheduleClass` (⚠ no SoftDeletes — BUG-MSH-101), `SubjectPracticalConfig` (SoftDeletes), `ComputationLog` (immutable) |
| Validation | `MarksheetScheduleRequest`, `UnlockMarksheetScheduleRequest`, `ScheduleClassRequest`, `SubjectPracticalConfigRequest` (all `authorize()=true`) |
| Migrations | `…115735_create_msh_marksheet_schedules_table`, `…115741_create_msh_schedule_class_jnt_table`, `…115730_create_msh_subject_practical_configs_table`, `…115740_create_msh_computation_logs_table` |
| CRUD type | Resource + tabbed combined page + lifecycle actions (state machine) |
| Soft delete | Schedule / practical config = yes; schedule-class = declared in migration but **trait missing** (BUG-MSH-101); computation log = none |
| Pagination | 15/page (`sch_page`, `pc_page`, `scd_page`) |
| Activity log | `Modules\GlobalMaster\Models\ActivityLog`; events `Stored/Updated/Deleted/Reviewed/Published/Unlocked/Locked/ComputeDispatched/Toggled/Restored`; lifecycle audit rows in `msh_computation_logs` (COMPUTE/REVIEW/PUBLISH/UNLOCK/LOCK) |

**Environment prerequisites:** module enabled in `modules_statuses.json` (currently `false` → 404); `APP_ENV=testing` (bypasses CSRF); tenant seeded with a config template, an academic session, class/subject, and the `msh_marksheet_schedules.status_id` dropdown rows (DRAFT/COMPUTED/REVIEWED/PUBLISHED/LOCKED); MSH permissions seeded (D39-MSH — currently unseeded, super-admin only).

---

## 2. Business Conditions (detailed)

### State machine (authoritative — from `MarksheetScheduleLifecycleService`)
```
        compute (checks is_locked ONLY)                 review                    publish (+ lock template)
DRAFT ─────────────────────────────────▶ COMPUTED ───────────────▶ REVIEWED ─────────────────────────▶ PUBLISHED
   ▲          (job → COMPUTED on success)     ▲  DomainException if   │ DomainException if not REVIEWED       │ lock
   │                                          │  not COMPUTED         │                                       ▼
   └──────────────── unlock(reason) ──────────┴───────────────────────┴────────────────────────────────── LOCKED
                     (forces COMPUTED, is_locked=0, reason audited; NO prior-state check)
```
- **DomainException messages (verbatim):** `Only COMPUTED schedules can be reviewed.` · `Only REVIEWED schedules can be published.` · `Only PUBLISHED schedules can be locked.` · `Unlock reason is required.`
- **compute lock guard (verbatim):** `Schedule is locked - unlock before recomputing.`
- Each successful transition inserts a `msh_computation_logs` row (`action` = REVIEW/PUBLISH/UNLOCK/LOCK, `status`='SUCCESS'); unlock stores the reason in `remarks`.

### Auto-update / audit flow
- `store` → `MarksheetScheduleService::create` (transaction; **syncClassSections calls ScheduleClass::withTrashed()** — BUG-MSH-101 when ids present) → `activityLog(Stored)`.
- `compute` → controller writes `activityLog(ComputeDispatched)` **after** dispatch (always, if not locked) → `ComputeMarksheetJob` → `MarksheetComputationService::computeForSchedule` opens a COMPUTE log (`RUNNING`→`SUCCESS/PARTIAL`), flips status→COMPUTED on full success.
- `publish` → `MarksheetConfigService::lockTemplate()` sets `msh_config_templates.is_locked=1` (BR-MSH-037).

---

## 3. Manual Test Cases (Step / Action / Expected + DB & activity checks)

### MTC-01 — Create schedule (happy path)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; open `/marksheet-generation/scheduling?tab=schedules` | Schedules tab renders |
| 2 | Open "Create schedule"; fill config template, session, code, name, date; submit **without class sections** | Redirect to show page, green success toast |
| 3 | DB | `SELECT * FROM msh_marksheet_schedules WHERE code=?` → 1 row, `status_id`=DRAFT, `created_by`=admin |
| 4 | Activity | `activity_logs` has `event='Stored'`, `subject_type=…MarksheetSchedule`, `user_id`=admin |
| ⚠ | If class sections are selected | **BUG-MSH-101**: `syncClassSections` calls `ScheduleClass::withTrashed()` on a trait-less model → 500 `BadMethodCallException` |

### MTC-02 — Required validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/marksheet-generation/marksheet-schedule` with empty body | 422 / redirect back with errors; no row created |
| 2 | DB | No new `msh_marksheet_schedules` row |

### MTC-03 — Duplicate (session, code)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create schedule code `TERM1` in session S | Created |
| 2 | Create another code `TERM1` in session S | Rejected (unique `uq_msh_ms_session_code`) |
| 3 | Create code `TERM1` in a **different** session | Allowed |

### MTC-04 — Review transition (COMPUTED → REVIEWED)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed schedule at COMPUTED; POST `…/{id}/review` | Redirect show, success `reviewed.marksheet_schedule` |
| 2 | DB | `status_id`=REVIEWED |
| 3 | Audit | `msh_computation_logs` row `action='REVIEW'`, `status='SUCCESS'`; activity `event='Reviewed'` |
| 4 | Negative | POST review on a DRAFT schedule → error flash `Only COMPUTED schedules can be reviewed.`, status unchanged, no REVIEW log |

### MTC-05 — Publish transition (REVIEWED → PUBLISHED, locks template)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed at REVIEWED; POST `…/{id}/publish` | success `published.marksheet_schedule` |
| 2 | DB | `status_id`=PUBLISHED; `SELECT is_locked FROM msh_config_templates WHERE id=?` → 1 (BR-MSH-037) |
| 3 | Audit | computation log `action='PUBLISH'`; activity `Published` |
| 4 | Negative | publish on DRAFT/COMPUTED → `Only REVIEWED schedules can be published.` |

### MTC-06 — Lock transition (PUBLISHED → LOCKED)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed at PUBLISHED; POST `…/{id}/lock` | success `locked.marksheet_schedule` |
| 2 | DB | `status_id`=LOCKED, `is_locked`=1, `locked_at`/`locked_by` set |
| 3 | Audit | computation log `action='LOCK'`; activity `Locked` |
| 4 | Negative | lock on REVIEWED → `Only PUBLISHED schedules can be locked.` |

### MTC-07 — Unlock with reason (BR-MSH-039)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed at PUBLISHED/LOCKED (is_locked=1); POST `…/{id}/unlock` with `unlock_reason` (≥5 chars) | success `unlocked.marksheet_schedule` |
| 2 | DB | `status_id`=COMPUTED, `is_locked`=0, `unlocked_at`/`unlocked_by` set, `unlock_reason` stored |
| 3 | Audit | computation log `action='UNLOCK'`, `remarks`=reason; activity `Unlocked` with reason property |
| 4 | Negative | `unlock_reason` < 5 chars → validation error, no state change |

### MTC-08 — Compute lock guard + defects
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed LOCKED (is_locked=1); POST `…/{id}/compute` | error `Schedule is locked - unlock before recomputing.`; **no** `ComputeDispatched` log |
| 2 | Seed DRAFT; POST compute | `ComputeDispatched` activity written; job dispatched (sync flips status→COMPUTED) |
| 3 | **BR-MSH-026** — Seed REVIEWED (is_locked=0); POST compute | **Not blocked** — dispatches & recomputes (status back to COMPUTED). Documents the P1 FSM gap |
| 4 | **BR-MSH-027** — insert a `RUNNING` computation log, POST compute | Second compute still dispatches (no concurrency guard) |

### MTC-09 — Practical config
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create practical config (session, class, subject, theory=70, practical=30) | Row created, activity `Stored` |
| 2 | Duplicate (session, class, subject) | Rejected (unique) |
| 3 | Toggle status endpoint | `is_active` flips; activity `Toggled` |

### MTC-10 — Precheck (cross-module, guarded)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `…/{id}/precheck` | Renders template checks + per-section counts |
| ⚠ | DEP-MSH-001 | Uses pending StudentPortal/Lms tables — if absent, page errors (test marks skipped). PERF-MSH-001: ~6 queries per class-section (N+1) |

### MTC-11 — Permissions & tenancy
| Step | Action | Expected |
|------|--------|----------|
| 1 | Guest visits combined page | Redirect `/login` |
| 2 | Limited user (no `…marksheet-schedule.view`) opens show | 403 |
| 3 | SEC-MSH-003 | All FormRequests `authorize()=true` — gate enforcement relies solely on controller `Gate::authorize` |
| 4 | Cross-tenant direct id | Schedule from tenant A not visible on tenant B host |

### MTC-12 — BUG-MSH-101 (ScheduleClass SoftDeletes gap)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `ScheduleClass` model | No `use SoftDeletes;` though `msh_schedule_class_jnt` migration declares `softDeletes()` |
| 2 | Open schedule-class trash view / restore / force-delete | Runtime `BadMethodCallException` (onlyTrashed/withTrashed/restore on trait-less model) |
| 3 | Create/update a schedule **with** class sections | `MarksheetScheduleService::syncClassSections` → `ScheduleClass::withTrashed()` → 500 |
