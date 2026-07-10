# Manual Test Specification — MarksheetGeneration / Student Results & Print

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (MSH) |
| Feature / Screen | StudentResultsAndPrint (`05-Student-Results-and-Print.md`) |
| URL | `/marksheet-generation/results` (combined) · `/marksheet-generation/student-result/{id}` (show) |
| Controller | `StudentResultController` (+ `MarksheetGenerationController::results()`) |
| Models | `StudentResult` (primary, `msh_student_results`), `StudentSubjectResult`, `StudentIaMark`, `StudentCoscholasticResult`, `StudentAttendance`, `StudentSubjectExamMark`, `ComputationLog` |
| Services | `StudentResultReviewService` (withhold/declare) |
| Validation | `StudentResultRequest`, `WithholdStudentResultRequest` (both `authorize()=true`) |
| Migrations | `2026_04_13_000017..000023_create_msh_*` (tenant) |
| CRUD type | AJAX/JSON store/update/destroy from combined screen; separate create/edit/show pages |
| Soft delete | `msh_student_results` (+ subject/ia/coscholastic/attendance): YES · **`msh_computation_logs`: NO (immutable audit)** |
| Pagination | student-results paginate(15, `sr_page`); subject/ia/coscholastic paginate(10) |
| Activity log | `sys_activity_logs` via `activityLog($model,$event,[...])` → events `Stored/Updated/Deleted/Withheld/Declared` (children also `Toggled/Restored`) |
| Print / PDF | `Template::render('MARKSHEET_PRINT', ...)`; PDF = redirect to print `?download=1&auto=1` (html2pdf.js) |
| Export | `StudentResultExport` → `.xlsx` |

## 2. Business Conditions (detail)

### State machine (result_status)
```
DECLARED ──withhold(reason ≥5, schedule unlocked)──► WITHHELD  (writes msh_computation_logs action=WITHHOLD)
WITHHELD ──declare(schedule unlocked)────────────────► DECLARED (withheld_reason = NULL, action=DECLARE)
any ── withhold/declare while is_locked=1 ──► DomainException → redirect back with error, state unchanged
```
Error strings (verbatim, `StudentResultReviewService`):
- `Withhold reason is required.`
- `Cannot withhold — schedule is locked.`
- `Cannot declare — schedule is locked.`

### Known source defects to be aware of during manual testing
- **SEC-MSH-001**: create page is guarded by `.view` not `.create` — a view-only user can reach the create form.
- **SEC-MSH-002**: store is guarded by `.update` not `.create` — a user with only `.update` can create.
- **SEC-MSH-003**: FormRequest `authorize()` returns `true`; the only gate is the controller `Gate::authorize`.
- **PERF-MSH-003**: results/create/edit load unbounded student & class-section collections (no pagination).

## 3. Test Cases (step-by-step)

### TC-P03 — Create a student result (Stored)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin; open `/marksheet-generation/results` | Combined results screen with 4 tabs |
| 2 | POST to `/marksheet-generation/student-result` with valid schedule_id/student_id/class_section_id + aggregates | 200/302 (redirect to show) |
| 3 | DB check | `SELECT * FROM msh_student_results WHERE schedule_id=? AND student_id=?` → 1 row, promotion_status='PROMOTED', created_by=admin id |
| 4 | Activity check | `sys_activity_logs` row: subject_type=`Modules\MarksheetGeneration\Models\StudentResult`, event='Stored', user_id=admin id |

### TC-P05 — Update (Updated)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a result | row exists |
| 2 | PUT `/student-result/{id}` with overall_grade='A2', promotion_status='DETAINED' | 200/302 |
| 3 | DB check | overall_grade='A2', promotion_status='DETAINED' |
| 4 | Activity check | event='Updated', user_id=admin |

### TC-P06 — Destroy (soft delete + Deleted)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a result | row exists |
| 2 | DELETE `/student-result/{id}` | 200/302 |
| 3 | DB check | `deleted_at` IS NOT NULL |
| 4 | Activity check | event='Deleted' |

### TC-P11 / TC-SM01 — Withhold (DECLARED → WITHHELD)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed result on an **unlocked** schedule, result_status='DECLARED' | row exists |
| 2 | POST `/student-result/{id}/withhold` with `withheld_reason='Disciplinary inquiry pending'` | redirect back with success 'Result withheld.' |
| 3 | DB check | result_status='WITHHELD', withheld_reason set |
| 4 | Audit check | `SELECT * FROM msh_computation_logs WHERE schedule_id=? AND action='WITHHOLD'` → 1 row, status='SUCCESS' |
| 5 | Activity check | event='Withheld' |

### TC-SM02 — Declare (WITHHELD → DECLARED)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed result, result_status='WITHHELD', withheld_reason set, unlocked schedule | row exists |
| 2 | POST `/student-result/{id}/declare` | redirect back with success 'Result declared.' |
| 3 | DB check | result_status='DECLARED', withheld_reason IS NULL |
| 4 | Audit check | msh_computation_logs action='DECLARE' present |
| 5 | Activity check | event='Declared' |

### TC-SM03 — Withhold blocked when schedule locked
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed result on a schedule with is_locked=1 | row exists |
| 2 | POST `/student-result/{id}/withhold` with valid reason | redirect back with error 'Cannot withhold — schedule is locked.' |
| 3 | DB check | result_status unchanged (NOT 'WITHHELD') |

### TC-SM04 — Declare blocked when schedule locked
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed result WITHHELD on locked schedule | row exists |
| 2 | POST `/student-result/{id}/declare` | redirect back with error 'Cannot declare — schedule is locked.' |
| 3 | DB check | result_status stays 'WITHHELD' |

### TC-N01 — Required validation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/student-result` with only `is_active` | HTTP 422; JSON errors for schedule_id/student_id/class_section_id |

### TC-N02 — Duplicate (schedule_id, student_id)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed result for (schedule, student) | row exists |
| 2 | POST `/student-result` with same pair | HTTP 422 |
| 3 | DB check | `COUNT(*)` for the pair = 1 (no duplicate) |

### TC-N11/12/13 — Withhold reason rules
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST withhold with no `withheld_reason` | 422 (required) |
| 2 | POST withhold with `withheld_reason='no'` | 422 (min:5) |
| 3 | POST withhold with 300-char reason | 422 (max:255) |

### TC-P07 — Export xlsx
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/student-result/{id}/export` | HTTP 200; xlsx download stream |

### TC-P08 / TC-P09 — Print & PDF
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/student-result/{id}/print` | 200 (rendered template) or 302 back-with-error if `MARKSHEET_PRINT` template missing (`\DomainException`) |
| 2 | GET `/student-result/{id}/pdf` | 302 → print `?download=1&auto=1` |

### TC-D04 — Computation log is immutable (no soft delete)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `msh_computation_logs` | no `deleted_at` column |
| 2 | Call `ComputationLog::withTrashed()` | throws `BadMethodCallException` (model has no SoftDeletes) |

### TC-S01/02/03 — SEC defects (proving current behaviour)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `StudentResultController::create()` | authorizes `tenant.msh-student-result.view` (SEC-MSH-001) |
| 2 | Inspect `StudentResultController::store()` | authorizes `tenant.msh-student-result.update` (SEC-MSH-002) |
| 3 | Inspect `StudentResultRequest::authorize()` | returns `true` (SEC-MSH-003) |

### TC-N15 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies; GET `/marksheet-generation/results` | redirect to `/login` |
