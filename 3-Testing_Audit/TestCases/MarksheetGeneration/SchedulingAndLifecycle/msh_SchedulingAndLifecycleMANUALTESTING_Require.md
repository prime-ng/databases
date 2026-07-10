# MarksheetGeneration — Scheduling & Lifecycle — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (`MSH`, `msh_`) |
| Screen | Scheduling & Lifecycle |
| Combined URL | `/marksheet-generation/scheduling` (`?tab=schedules` / `?tab=practical-configs` / `?tab=schedule-classes`) |
| Resource URL | `/marksheet-generation/marksheet-schedule` (+ `/{id}/{review,lock,unlock,publish,compute}` POST, `/{id}/{precheck,export}` GET) |
| Controllers | `MarksheetScheduleController`, `ScheduleClassController`, `SubjectPracticalConfigController`, `ComputationLogController` |
| Models | `MarksheetSchedule` (SoftDeletes), `ScheduleClass` (⚠ no SoftDeletes — BUG-MSH-101), `SubjectPracticalConfig` (SoftDeletes), `ComputationLog` (immutable, no SoftDeletes) |
| Services | `MarksheetScheduleService`, `MarksheetScheduleLifecycleService` (FSM/`DomainException`), `MarksheetComputationService` |
| Validation | `MarksheetScheduleRequest`, `UnlockMarksheetScheduleRequest` (`min:5,max:500`), `ScheduleClassRequest`, `SubjectPracticalConfigRequest` — all `authorize()=true` (SEC-MSH-003) |
| CRUD type | Modal + redirect page (create/edit blade); AJAX toggle/trash for SPC & ScheduleClass |
| Soft delete | schedules + SPC: yes; ScheduleClass: **declared in migration but model trait missing** (BUG-MSH-101); computation_logs: **none (immutable)** |
| Pagination | schedule-class 20/page, SPC 20/page, computation-log 50/page |
| Activity log | `sys_activity_logs` via `activityLog()`; events `Stored`, `Updated`, `Deleted`, `Reviewed`, `Published`, `Locked`, `Unlocked`, `ComputeDispatched`, `Toggled`, `Restored` |
| Status table | **`sys_dropdown_table`** (key `msh_marksheet_schedules.status_id`) — corrected vs audit DOC-MSH-002 |
| DB scope | tenant-side (`tenant_db`) |

**Environment prerequisites**
1. `MarksheetGeneration: true` in `prime_testing/modules_statuses.json` (else all routes 404).
2. `APP_ENV=testing` (Dusk; bypasses CSRF/419).
3. Tenant DB seeded with: a `msh_config_templates` row, a `sch_org_academic_sessions_jnt` row, and the 5 status dropdown rows on `sys_dropdown_table`.
4. D39-MSH: tenant permission rows are unseeded — the admin login is granted permissions defensively in `setUp()`.

---

## 2. Business Conditions (detailed)

### 2.1 The lifecycle state machine (BC-SM)

```
              compute (is_locked=0)         review (COMPUTED)        publish (REVIEWED)        lock (PUBLISHED)
   DRAFT ─────────────────────────► COMPUTED ───────────────► REVIEWED ──────────────► PUBLISHED ───────────► LOCKED
     ▲                                   ▲                                                   │ (locks template)      │ (is_locked=1)
     │                                   └───────────────────────────────────────────────────┘                      │
     └──────────────────────── unlock (reason ≥5 chars) forces COMPUTED + is_locked=0 ◄──────────────────────────────┘
```

- **compute** guard = `is_locked === 1` only → early-return message `'Schedule is locked - unlock before recomputing.'`. It does **not** check status (BR-MSH-026).
- **review** → `DomainException('Only COMPUTED schedules can be reviewed.')` if not COMPUTED.
- **publish** → `DomainException('Only REVIEWED schedules can be published.')` if not REVIEWED; also sets `msh_config_templates.is_locked=1` (BR-MSH-037).
- **lock** → `DomainException('Only PUBLISHED schedules can be locked.')` if not PUBLISHED; sets schedule `is_locked=1`.
- **unlock** → `DomainException('Unlock reason is required.')` if blank; FormRequest `min:5`. Reverts to **COMPUTED**, clears `is_locked`, writes `UNLOCK` ComputationLog with `remarks`=reason. (BRD text says "Draft/Reviewed" — implementation says COMPUTED → DOC-MSH-003 discrepancy.)

### 2.2 Error messages (verbatim)

| Trigger | Message |
|---------|---------|
| review not from COMPUTED | `Only COMPUTED schedules can be reviewed.` |
| publish not from REVIEWED | `Only REVIEWED schedules can be published.` |
| lock not from PUBLISHED | `Only PUBLISHED schedules can be locked.` |
| unlock blank reason (service) | `Unlock reason is required.` |
| compute while locked (controller) | `Schedule is locked - unlock before recomputing.` |

---

## 3. Manual Test Cases

### TC-M01 — Create a schedule (happy path)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; open `/marksheet-generation/scheduling?tab=schedules` | Schedules tab renders |
| 2 | Open create; select ConfigTemplate + AcademicSession; enter unique `code`, `name`, `schedule_date`; select class-sections | Form accepts |
| 3 | Submit | Redirect to schedule show; green toast |
| 4 | DB check | `SELECT * FROM msh_marksheet_schedules WHERE code=?` → 1 row, `status_id`=DRAFT id, `created_by`=admin |
| 5 | Activity check | `SELECT * FROM sys_activity_logs WHERE subject_type LIKE '%MarksheetSchedule' AND event='Stored'` → row, `user_id`=admin |

### TC-M02 — Required-field validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/marksheet-generation/marksheet-schedule` with empty body | Rejected (422/redirect back with errors); no row created |

### TC-M03 — Duplicate code per session blocked
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a schedule with `code=X` in session S | Success |
| 2 | Create another with `code=X` in the same session S | Rejected (`uq_msh_ms_session_code`) |
| 3 | Create with `code=X` in a different session | Allowed |

### TC-M04 — Compute from DRAFT
| Step | Action | Expected |
|------|--------|----------|
| 1 | On a DRAFT schedule, POST `/{id}/compute` | Success toast; job dispatched |
| 2 | Activity check | `event='ComputeDispatched'` row added |
| 3 | On success, DB check | `status_id` becomes COMPUTED; `last_computed_at` set |

### TC-M05 — Review (COMPUTED → REVIEWED)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On COMPUTED schedule, POST `/{id}/review` | Redirect show; success |
| 2 | DB check | `status_id`=REVIEWED |
| 3 | Log check | `msh_computation_logs` row `action='REVIEW'` |

### TC-M06 — Publish (REVIEWED → PUBLISHED, locks template) [BR-MSH-037]
| Step | Action | Expected |
|------|--------|----------|
| 1 | On REVIEWED schedule, POST `/{id}/publish` | Success |
| 2 | DB check | `status_id`=PUBLISHED; `msh_config_templates.is_locked=1` |
| 3 | Log check | `action='PUBLISH'` |

### TC-M07 — Lock (PUBLISHED → LOCKED)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On PUBLISHED schedule, POST `/{id}/lock` | Success |
| 2 | DB check | `status_id`=LOCKED; `is_locked=1`; `locked_by`=admin |
| 3 | Log check | `action='LOCK'` |

### TC-M08 — Unlock (requires reason, reverts to COMPUTED) [BR-MSH-039]
| Step | Action | Expected |
|------|--------|----------|
| 1 | On LOCKED schedule, POST `/{id}/unlock` with `unlock_reason` < 5 chars | Rejected; stays LOCKED/PUBLISHED |
| 2 | POST `/{id}/unlock` with a ≥5-char reason | Success |
| 3 | DB check | `status_id`=COMPUTED; `is_locked=0`; `unlock_reason` persisted |
| 4 | Log check | `action='UNLOCK'`, `remarks`=reason |

### TC-M09 — Illegal transitions
| Step | Action | Expected |
|------|--------|----------|
| 1 | review from DRAFT | error banner `Only COMPUTED schedules can be reviewed.`; status unchanged; no REVIEW log |
| 2 | publish from COMPUTED | error `Only REVIEWED schedules can be published.`; unchanged |
| 3 | lock from REVIEWED | error `Only PUBLISHED schedules can be locked.`; unchanged |
| 4 | compute on LOCKED | error `Schedule is locked - unlock before recomputing.`; no dispatch |

### TC-M10 — BR-MSH-026 (defect): recompute a REVIEWED schedule
| Step | Action | Expected (current, defective) |
|------|--------|-------------------------------|
| 1 | On a REVIEWED schedule with `is_locked=0`, POST `/{id}/compute` | **Dispatches** (`ComputeDispatched` logged) — NOT blocked by status. Documents the P1 gap. |

### TC-M11 — BR-MSH-027 (defect): concurrent compute
| Step | Action | Expected (current, defective) |
|------|--------|-------------------------------|
| 1 | Insert a RUNNING `msh_computation_logs` row for a schedule | — |
| 2 | POST `/{id}/compute` | **Still dispatches** — no concurrency guard. Documents the P1 gap. |

### TC-M12 — Subject Practical Config
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create SPC (session, class, subject, theory=70, practical=30) | Row persisted |
| 2 | Create duplicate (same session+class+subject) | Rejected (`uq_msh_spc_session_class_sub`) |
| 3 | toggleStatus endpoint | 200 JSON `{success:true}`; `event='Toggled'` |

### TC-M13 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit combined page as guest | Redirect to `/login` |
| 2 | Visit schedule show as a permission-less user | 403/redirect |
| 3 | Review the Policy | `publish/unlock/lock/export` abilities exist; **no `review` ability** though the controller uses the `review` gate (gap) |

### TC-M14 — Security
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a schedule with `name='<script>alert(1)</script>'` | stored raw |
| 2 | Open show page | script NOT present raw (Blade-escaped) |
| 3 | Unlock with an XSS `unlock_reason` | stored raw; escaped on render |

### TC-M15 — Tenancy isolation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Note a schedule id on tenant A | — |
| 2 | Visit `/marksheet-generation/marksheet-schedule/{idA}` on tenant B's host | tenant A's `code` not exposed (per-tenant DB) |

### TC-M16 — FK integrity
| Step | Action | Expected |
|------|--------|----------|
| 1 | Attempt to delete a `msh_config_templates` row referenced by a schedule | Blocked (RESTRICT) |
| 2 | Add a `msh_schedule_class_jnt` row, then hard-delete the schedule | Junction row removed (CASCADE) |
| 3 | Verify `msh_computation_logs` has no `deleted_at` | Column absent (immutable) |
