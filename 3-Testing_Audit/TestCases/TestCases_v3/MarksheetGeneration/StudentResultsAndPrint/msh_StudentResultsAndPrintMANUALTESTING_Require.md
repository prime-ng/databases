# Manual Testing — MarksheetGeneration · Student Results & Print

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (`MSH`) |
| Feature / Screen | StudentResultsAndPrint (`05-Student-Results-and-Print.md`) |
| Combined URL | `/marksheet-generation/results` (route `marksheet-generation.results.combined`, `?tab=student-results`) |
| Resource base | `/marksheet-generation/student-result` (`only(index,create,store,show,edit,update,destroy)`) |
| Special routes | `.../{id}/export` (GET), `.../{id}/print` (GET), `.../{id}/pdf` (GET→downloadPdf), `.../{id}/withhold` (POST), `.../{id}/declare` (POST) |
| Controller | `StudentResultController`; combined page `MarksheetGenerationController::results()` |
| Service | `StudentResultReviewService` (withhold/declare, lock guard, computation-log insert) |
| Export | `StudentResultExport` (Maatwebsite\Excel, `student_result_{id}.xlsx`) |
| Print engine | `Modules\Template\Facades\Template::render('MARKSHEET_PRINT', subjectId, classId, sessionId, studentId)` |
| Models | `StudentResult` (+ StudentSubjectResult, StudentIaMark, StudentCoscholasticResult, StudentAttendance, StudentSubjectExamMark, ComputationLog) |
| Primary table | `msh_student_results` (UNIQUE `uq_msh_sr_schedule_student`) |
| Validation | `StudentResultRequest`, `WithholdStudentResultRequest` |
| Migrations | Consolidated DDL `MarksheetGeneration_DDL_v1.sql` (module has NO per-module migration files) |
| Soft delete | Yes on `msh_student_results` (NOT on `msh_computation_logs`) |
| Pagination | Results tab paginated; child-list Student/Subject `get()` unbounded (PERF-MSH-003) |
| Activity log | `Modules\GlobalMaster\Models\ActivityLog`; events: `Stored`, `Updated`, `Deleted`, `Withheld`, `Declared` |
| Prerequisites | Module enabled in `modules_statuses.json`; `APP_ENV=testing`; tenant seed data (active/unlocked schedule, class-section, student) |

## 2. Business Conditions (with error messages & flows)

### Result review state machine (StudentResultReviewService)
```
        withhold(reason, min:5)                declare()
DECLARED ───────────────────────▶ WITHHELD ───────────────▶ DECLARED
   ▲   (writes withheld_reason,        │   (nulls withheld_reason,
   │    inserts msh_computation_logs   │    inserts msh_computation_logs
   │    action=WITHHOLD, event 'Withheld')  action=DECLARE, event 'Declared')
   └──────────────────────────────────┘
Guard: if schedule.is_locked = 1  →  DomainException
        withhold: 'Cannot withhold — schedule is locked.'
        declare : 'Cannot declare — schedule is locked.'
        empty reason: 'Withhold reason is required.'
```

### Key validation messages (default Laravel unless overridden)
- `schedule_id`/`student_id`/`class_section_id` — required / integer / `exists:` (`The selected … is invalid.`)
- Duplicate `(schedule_id, student_id)` — `Rule::unique('msh_student_results','schedule_id')->where(student_id)`
- `overall_percentage` — `max:100`; `promotion_status` — `in:PROMOTED,DETAINED,COMPARTMENT,PLACED`; `result_status` — `in:DECLARED,WITHHELD`
- `withheld_reason` — required|string|min:5|max:255

### Known source defects (verify in source before fixing)
- **SEC-MSH-001 (P1):** `create()` line 32 → `Gate::authorize('tenant.msh-student-result.view')` (should be `.create`).
- **SEC-MSH-002 (P1):** `store()` line 43 → `Gate::authorize('tenant.msh-student-result.update')` (should be `.create`).
- **SEC-MSH-003 (P1):** all 6 FormRequests `authorize(){ return true; }`.
- **PERF-MSH-003 (P2):** unbounded `Student::get()`/`Subject::get()` in results view.
- **PERF-MSH-004 (P3):** `wipePreviousResults()` hard-deletes soft-deletable result rows on recompute.

## 3. Manual Test Cases

### TC-P11 — Store a student result (happy path)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; open `/marksheet-generation/results` | Four tabs render (Student/Subject/IA/Coscholastic Results) |
| 2 | POST to `/marksheet-generation/student-result` with valid schedule_id/student_id/class_section_id, grand_total, promotion_status=PROMOTED | HTTP 200/302, redirect to show |
| 3 | DB check | `SELECT * FROM msh_student_results WHERE schedule_id=? AND student_id=?` → 1 row, promotion_status='PROMOTED' |
| 4 | Activity check | `SELECT * FROM <activity_logs> WHERE subject_type LIKE '%StudentResult' AND event='Stored'` → 1 row, user_id = admin |

### TC-SM20 — Withhold a declared result
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a DECLARED result on an unlocked schedule | row exists |
| 2 | POST `/student-result/{id}/withhold` with `withheld_reason='Malpractice investigation in progress'` | 200/302 |
| 3 | DB | `result_status='WITHHELD'`, `withheld_reason` = submitted text |
| 4 | Audit | `msh_computation_logs` has a new `action='WITHHOLD'` row; activity event `Withheld` |

### TC-SM21 — Declare a withheld result
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a WITHHELD result with a reason | row exists |
| 2 | POST `/student-result/{id}/declare` | 200/302 |
| 3 | DB | `result_status='DECLARED'`, `withheld_reason` = NULL |
| 4 | Audit | `msh_computation_logs` `action='DECLARE'`; activity event `Declared` |

### TC-SM22/23 — Locked-schedule guard
| Step | Action | Expected |
|------|--------|----------|
| 1 | Set `msh_marksheet_schedules.is_locked=1` for the schedule | locked |
| 2 | POST withhold / declare | Service throws `DomainException`; redirect back with error; `result_status` unchanged |

### TC-N24/25/39 — Withhold reason validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST withhold `withheld_reason='no'` (len<5) | 422 |
| 2 | POST withhold with no `withheld_reason` | 422 |
| 3 | POST withhold with 300-char reason | 422 (max:255) |
| 4 | DB | result stays not-WITHHELD |

### TC-N30/31 — Store validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST store with only `is_active` | 422; body mentions schedule_id/student_id/required |
| 2 | POST store duplicating an existing (schedule_id, student_id) | 422; `SELECT COUNT(*)` stays 1 |

### TC-N32/33/34/35/36/37 — Field-level validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | overall_percentage=150 | 422 |
| 2 | promotion_status='GRADUATED' | 422 |
| 3 | result_status='PENDING' | 422 |
| 4 | schedule_id=999999999 | 422 (exists) |
| 5 | student_id=999999999 | 422 (exists) |
| 6 | rank_in_section=0 | 422 (min:1) |

### TC-P15/16/17 — Export / Print / PDF
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/student-result/{id}/export` | HTTP 200, xlsx download (`student_result_{id}.xlsx`) |
| 2 | GET `/student-result/{id}/print` | 200 (render) or 302 (DomainException → back with `Cannot print: …`) |
| 3 | GET `/student-result/{id}/pdf` | 302 redirect to `.../print?download=1&auto=1` (or 200) |

### TC-D13/40 — Soft delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | DELETE `/student-result/{id}` | 200/302; `deleted_at` set; activity `Deleted` |
| 2 | Default query | row hidden; `withTrashed()` shows it |

### TC-N50 — Guest access
| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear cookies, visit `/marksheet-generation/results` | Redirect to `/login` |

### TC-S51/52/53 — Security defects (proving current behaviour)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `StudentResultController::create()` | authorizes `tenant.msh-student-result.view` (SEC-MSH-001 — should be `.create`) |
| 2 | Read `StudentResultController::store()` | authorizes `tenant.msh-student-result.update` (SEC-MSH-002 — should be `.create`) |
| 3 | Read `StudentResultRequest::authorize()` | returns `true` (SEC-MSH-003) |

### TC-S91 — XSS in withhold reason
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST withhold `withheld_reason='<script>alert(1)</script> flagged'` | 200/302 |
| 2 | DB | value stored verbatim; on-screen render is HTML-escaped by Blade |
