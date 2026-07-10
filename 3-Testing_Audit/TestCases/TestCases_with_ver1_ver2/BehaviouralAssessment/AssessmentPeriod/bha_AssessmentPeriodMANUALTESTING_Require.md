# AssessmentPeriod — Manual Testing Specification

## 1. Feature Information

| Item | Value |
|------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | AssessmentPeriod (`06-Periods.md`, screen "Periods") |
| Base URL | `{tenant}/behavioural-assessment` |
| List (setup tab) | `GET /behavioural-assessment/setup?tab=periods` |
| Create | `GET /behavioural-assessment/assessment-periods/create` |
| Store | `POST /behavioural-assessment/assessment-periods` |
| Show | `GET /behavioural-assessment/assessment-periods/{id}` → **redirects to edit** |
| Edit | `GET /behavioural-assessment/assessment-periods/{id}/edit` |
| Update | `PUT /behavioural-assessment/assessment-periods/{id}` |
| Destroy (soft) | `DELETE /behavioural-assessment/assessment-periods/{id}` |
| Trash | `GET /behavioural-assessment/assessment-periods/trash` |
| Restore | `GET /behavioural-assessment/assessment-periods/{id}/restore` |
| Force delete | `DELETE /behavioural-assessment/assessment-periods/{id}/force-delete` |
| Toggle active | `POST /behavioural-assessment/assessment-periods/{id}/toggle-status` → JSON |
| Lock | `POST /behavioural-assessment/assessment-periods/{id}/lock` → redirect |
| Unlock | `POST /behavioural-assessment/assessment-periods/{id}/unlock` → redirect |
| Controller | `BaAssessmentPeriodController` |
| FormRequest | `BaAssessmentPeriodRequest` |
| Model | `BaAssessmentPeriod` (`ba_assessment_periods`); child `BaAssessment` (`ba_assessments`) |
| Service | none in write path (plain Eloquent) |
| CRUD type | Full CRUD + **status FSM (lock/unlock)** + toggle active + soft/force-delete |
| Soft delete | Yes |
| Pagination | Setup periods tab (paginator) ; trash `paginate(15)` |
| Activity log | **None** for this feature (flash messages only) |
| Permissions | `tenant.behavioural-assessment.assessment-periods.{viewAny,view,create,update,delete,status,lock,unlock,restore,forceDelete}` |

**Prerequisite:** module `BehaviouralAssessment` must be **enabled** in `prime_testing/modules_statuses.json` (currently `false` → all routes 404). See Validation Report §E.

**Prefix note (`DOC-BA-001`):** DDL doc says `bha_*`; **live table is `ba_assessment_periods`**. All DB checks below use `ba_`.

---

## 2. Business Conditions (detailed)

### Validation — `BaAssessmentPeriodRequest`
| Field | Rule | Failure behaviour |
|-------|------|-------------------|
| academic_session_id | required, integer, `exists:sch_org_academic_sessions_jnt,id` | re-render create/edit with `.alert-danger`; no row |
| academic_term_id | nullable, integer, `exists:sch_academic_term,id` | — |
| name | required, string, max:100 | rejected |
| start_date | required, date | rejected |
| end_date | required, date, `after_or_equal:start_date` | rejected if before start |
| deadline | required, date, `gte:end_date` | rejected if before end |
| status | nullable, `in:open,closed,locked` — **editable on edit form (FSM back-door, BUG-BA-002)** | rejected only if out of enum |

### Status FSM (status enum `open / closed / locked`)
```
store()        → always status = 'open'
lock()         → {open, closed} → 'locked'   (guard: blocks only if already 'locked' → "Period is already locked.")
unlock()       → 'locked' → 'closed'         (guard: blocks if not locked → "Period is not locked.")  [MISLABELED: does NOT return to 'open']
update(status) → any → any                   (NO FSM guard — back-door via edit form <select>)
toggleStatus() → is_active = !is_active       (orthogonal; not a status transition)
(no close() action anywhere → open→closed unreachable via lifecycle)
```

### Flash / JSON messages (real strings)
```
store   → 'Assessment period created successfully.'
update  → 'Assessment period updated successfully.'
destroy → 'Assessment period moved to trash.'    | blocked: 'Cannot delete this assessment period because it has active assessments or computed scores.'
restore → 'Assessment period restored.'
force   → 'Assessment period permanently deleted.' | blocked: 'Cannot permanently delete this assessment period because it has associated assessments or computed scores (active or trashed).'
lock    → 'Period locked. No further edits allowed.' | already: 'Period is already locked.'
unlock  → 'Period unlocked (set to closed).'         | not locked: 'Period is not locked.'
toggle  → JSON {success:true, is_active, message:'Assessment period activated.'/'Assessment period deactivated.'}
```

### Requirement rules NOT enforced in code (documented gaps — see §3 proofs)
- **FRD FSM-2 / BR-BA-012**: `open→closed→locked`, locked terminal — **violated** (illegal transitions allowed; `open→closed` unreachable via actions) → **BUG-BA-002**.
- **The Absolute Lock Rule**: locking a period should freeze all ratings/remarks/review edits (`403`) — **not enforced**; `lock()` sets period status only, no cascade → **BUG-BA-001**.
- **Chronological Non-Overlapping Rule**: no overlapping periods per session — **no check** → **VAL-BA-AP-01**.
- **`authorize()` bare true** on the FormRequest → **SEC-BA-002**.

---

## 3. Test Cases (step / action / expected)

### TC-P10 — Create a valid period
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; visit `/assessment-periods/create` | "Academic Context" + "Period Details" render; note "New periods always start as Open." |
| 2 | Name `Term 2 Assessment`; select Academic Session; Start today, End +1 month, Deadline +40 days | fields accept input |
| 3 | Click **Save Assessment Period** | redirect to setup?tab=periods; flash `Assessment period created successfully.` |
| 4 | DB check | `SELECT status FROM ba_assessment_periods WHERE name='Term 2 Assessment'` → `open` |

### TC-P13 — Edit / update
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open a period `/edit` | prefilled name + status `<select>` |
| 2 | Change name; click **Update Assessment Period** | flash `Assessment period updated successfully.` |
| 3 | DB check | new name persisted |

### TC-SM-tog — Toggle active (JSON)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/assessment-periods/{id}/toggle-status` (from list) | JSON `{"success":true,"is_active":false,"message":"Assessment period deactivated."}` |
| 2 | DB check | `SELECT is_active FROM ba_assessment_periods WHERE id=?` → flipped |

### TC-SM-01 — open → locked (LEGAL)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Period status `open`; POST `/assessment-periods/{id}/lock` | flash `Period locked. No further edits allowed.` |
| 2 | DB check | `status` = `locked` |

### TC-SM-02 — locked → closed (unlock, mislabeled)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Period status `locked`; POST `/assessment-periods/{id}/unlock` | flash `Period unlocked (set to closed).` |
| 2 | DB check | `status` = `closed` (NOT `open`) |

### TC-SM-04 / TC-SM-05 — guards
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/lock` on already-locked period | flash `Period is already locked.`; status stays `locked` |
| 2 | POST `/unlock` on `open` period | flash `Period is not locked.`; status stays `open` |

### TC-SM-03 / TC-N20 — closed → locked re-lock (BUG-BA-002) — proof
| Step | Action | Expected (current buggy behaviour) |
|------|--------|-----------------------------------|
| 1 | Period status `closed` (via lock then unlock) | — |
| 2 | POST `/assessment-periods/{id}/lock` | **succeeds**; status → `locked` |
| 3 | DB check | `status` = `locked` (a terminal/closed period was re-locked — FSM-2 violated) |

### TC-SM-08 / TC-N21 — open → closed unreachable (BUG-BA-002) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Period status `open`; POST `/unlock` (only close-like action) | rejected `Period is not locked.`; status stays `open` |
| 2 | Inspect `routes/web.php` | **no** `assessment-periods/{period}/close` route exists |
| 3 | Conclusion | there is no lifecycle path `open → closed` |

### TC-SM-06a / TC-N22 — edit back-door closed → open (BUG-BA-002) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Period status `closed`; open `/edit` | status `<select>` present, form enabled |
| 2 | Select `Open`; click **Update Assessment Period** | update accepted (no FSM guard) |
| 3 | DB check | `status` = `open` (illegal reopen via back-door) |

### TC-SM-06b / TC-N23 — edit back-door open → closed (BUG-BA-002) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Period status `open`; open `/edit`; select `Closed`; Update | `status` = `closed` (only path to closed is the back-door) |

### TC-N24/TC-N25 — lock does not freeze assessments (BUG-BA-001) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Source scan `lock()` | body sets `'status' => 'locked'` only; contains **no** `assessments`/`ratings` cascade |
| 2 | Create assessment under a `locked` period (data) | assessment **saves** (period lock did not block) |
| 3 | Edit that assessment's `reviewer_remarks` while period locked | save **succeeds** — assessments remain editable (Absolute Lock Rule violated) |

### TC-N26 — overlapping periods allowed (VAL-BA-AP-01) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Create Period A (same session, dates D..D+30) | saved |
| 2 | Create Period B (same session, dates D+10..D+50 — overlaps A) | saved (no overlap check) |
| 3 | DB check | both rows exist; Chronological Non-Overlapping Rule not enforced |

### TC-N10/N30/N32/N33/N34 — validation (negative)
| TC | Action | Expected |
|----|--------|----------|
| N30 | Submit empty form | `.alert-danger`; no row |
| N10 | end_date before start_date | rejected (`after_or_equal`); no row |
| N32 | deadline before end_date | rejected (`gte`); no row |
| N33 | name = 130 chars | rejected (`max:100`); no row |
| N34 | academic_session_id = non-existent id | rejected (`exists`); no row |

### TC-D01 — Soft-delete → restore → force-delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a period (no assessments) | flash `Assessment period moved to trash.`; `deleted_at` set, `is_active=0` |
| 2 | Trash page, Restore | flash `Assessment period restored.`; `deleted_at` NULL |
| 3 | Delete again, Force delete | flash `Assessment period permanently deleted.`; row gone |

### TC-D02 — Destroy blocked when referenced (RESTRICT guard)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Period with an assessment; attempt delete | flash `Cannot delete this assessment period because it has active assessments or computed scores.`; row remains |

### TC-P23 — Locked period edit is frozen (period only)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open `/edit` on a `locked` period | banner `This period is locked.`; **no** "Update Assessment Period" button (form disabled) |

### TC-S01/S02/S04/S05/S06
| TC | Action | Expected |
|----|--------|----------|
| S01/S02 | Logout; visit create / setup | redirect to `/login` |
| S04 | Login as user without `.create` | create → 403 / no "Save Assessment Period" form |
| S05 | Period name `<script>window.x=1</script>`; open edit | script does not execute (Blade escapes) |
| S06 | Visit `/assessment-periods/98765432/edit` | `findOrFail` 404; no "Update Assessment Period" |

### TC-T01 — Tenant isolation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenancy initialized | `ba_assessment_periods` resolves in tenant DB; no `tenant_id` column |
