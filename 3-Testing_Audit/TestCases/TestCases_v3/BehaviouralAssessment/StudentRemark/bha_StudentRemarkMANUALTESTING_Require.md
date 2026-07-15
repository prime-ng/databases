# bha_StudentRemark — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (BHA) |
| Feature / Screen | Student Remarks (`10-Remarks`) |
| Primary URL (read) | `GET /behavioural-assessment/assessments/{id}` → `BaAssessmentController::show()` (renders the ratings + remarks grid) |
| Save URL (write) | `POST /behavioural-assessment/assessments/{assessment}/bulk-rate` → `bulkRate()` ("Save Ratings" button) |
| Autosave URL | `POST /behavioural-assessment/assessments/{assessment}/auto-save` → `autoSave()` (debounced) |
| Reviewer read URL | `GET /behavioural-assessment/reviews/{assessment}` → `reviewShow()` |
| Controller | `BaAssessmentController` |
| Model | `BaStudentRemark` (table `ba_student_remarks`) |
| FormRequest | **None** — remarks validated inline inside `bulkRate()` |
| Migration | `database/migrations/tenant/2026_06_16_130623_create_ba_student_remarks_table.php` |
| CRUD Type | Transactional child of an assessment (create/update via updateOrCreate; soft delete) |
| Soft Delete | Yes (`deleted_at`); model uses `SoftDeletes` |
| Unique Key | `uq_ba_remark (assessment_id, student_id)` — one remark per student per assessment |
| Activity Log | None for remarks (ratings/status use `ba_audit_log`; remark writes emit no audit row) |
| Permissions | Inherit assessments gates: `show=.view`, `bulkRate/autoSave=.update` |
| DB scope | Tenant-side (`tenant_db`) |

> **CRITICAL — READ FIRST.** Because of **BUG-BA-REM-001**, the remarks grid page returns **HTTP 500** and the "Save Ratings" button returns **HTTP 500**. Manual testers will not be able to view or save any remark until `BaStudentRemark` and the `DB` facade are imported in `BaAssessmentController`. The steps below record both the intended behaviour and the current (broken) behaviour.

---

## 2. Business Conditions (detailed)

**BR-1 — Minimum/Maximum length (requirement).** Remarks must be ≥ 30 and ≤ 500 characters and required before submission.
- *Current implementation:* `bulkRate()` validates `remarks.*` as `nullable|string|max:1000`. No `min:30`, max is 1000, not required. → **VAL-BA-REM-002.**

**BR-2 — Debounced autosave.** On blur / 1.5s idle the remark should be written to `ba_student_remarks`.
- *Current implementation:* the JS listener is attached only to `.rating-select` (2000ms), and the `autoSave()` controller endpoint validates and persists **ratings only** — the posted `remarks[]` payload is dropped. → **BUG-BA-REM-003.**

**BR-3 — Comment Bank / Predefined Templates.** A helper panel to insert standard phrases (`{Student}` substitution).
- *Current implementation:* absent from `show.blade.php`. → **FE-BA-REM-004.**

**BR-4 — Character counter (`n / 500`).** Live counter next to each textarea.
- *Current implementation:* absent; textarea placeholder reads "Optional remark...". → **FE-BA-REM-005.**

**BR-5 — One remark per student per assessment.** Enforced by `uq_ba_remark`. `bulkRate()` uses `updateOrCreate` keyed on `(assessment_id, student_id)`.

**BR-6 — Editable only while draft.** The textarea is disabled when `status !== 'draft'` or the user lacks `.update`. `bulkRate()` also blocks locked assessments before the transaction.

**Error / message strings.**
- Locked assessment bulk-rate: redirect back with `"This assessment is locked and cannot be edited."`
- Missing/empty remark: silently skipped (no error).

---

## 3. Test Cases (Step / Action / Expected + DB checks)

### TC-P10 — Persist a remark (model layer)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a draft assessment (period+teacher+class-section) and a student | rows exist |
| 2 | `BaStudentRemark::create([...remark_text...])` | row inserted |
| 3 | DB check | `SELECT * FROM ba_student_remarks WHERE assessment_id=? AND student_id=?` → 1 row, `created_by = admin id`, `is_active = 1` |

### TC-P11 — One remark per student
| Step | Action | Expected |
|------|--------|----------|
| 1 | `updateOrCreate` remark for (A, S) with text "First" | row created |
| 2 | `updateOrCreate` again for (A, S) with text "Revised" | same `id`, text updated |
| 3 | DB check | `SELECT COUNT(*) ... WHERE assessment_id=A AND student_id=S` = 1 |

### TC-DEV-REM-001a — Remarks page fatals (READ)
| Step | Action | Expected (current) |
|------|--------|--------------------|
| 1 | Log in as admin; open `GET /assessments/{draftId}` | **HTTP 500** (fatal: unimported `BaStudentRemark`) |
| 2 | Intended | grid with a remark textarea per student renders |

### TC-DEV-REM-001b — Save Ratings fatals (WRITE)
| Step | Action | Expected (current) |
|------|--------|--------------------|
| 1 | POST `/assessments/{draftId}/bulk-rate` with `remarks[studentId]="…"` | **HTTP 500** (fatal: unimported `DB` + `BaStudentRemark`) |
| 2 | DB check | `SELECT COUNT(*) FROM ba_student_remarks WHERE assessment_id={draftId}` = **0** (nothing saved) |

### TC-DEV-REM-001c — Reviewer page fatals
| Step | Action | Expected (current) |
|------|--------|--------------------|
| 1 | POST submit the assessment; open `GET /reviews/{id}` | **HTTP 500** (reviewShow reads remarks) |

### TC-SM01 — Locked assessment blocked before fatal
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed a `locked` assessment | row exists |
| 2 | POST `/assessments/{lockedId}/bulk-rate` with remarks | **302** redirect back (isLocked guard runs before the transaction — no 500) |

### TC-DEV-REM-003a — Autosave drops remarks
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/assessments/{draftId}/auto-save` with `remarks[studentId]="…"` | **200** success JSON (`{success:true}`) |
| 2 | DB check | `SELECT COUNT(*) FROM ba_student_remarks WHERE assessment_id={draftId}` = **0** (remark silently dropped) |

### TC-N30 — Length rule mismatch
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `BaAssessmentController::bulkRate()` rules | `remarks.*` = `nullable|string|max:1000` (no `min:30`, no `required`, not 500) |

### TC-N44 — Duplicate pair unique violation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create remark for (A, S) | row 1 |
| 2 | `create` a second remark for (A, S) | throws (unique `uq_ba_remark`) |
| 3 | DB check | count = 1 |

### TC-D40 / D41 / D45 — Soft delete & cascade
| Step | Action | Expected |
|------|--------|----------|
| 1 | Soft-delete a remark | hidden from default scope; in `onlyTrashed()` |
| 2 | Hard-delete the parent assessment | remark cascade-deleted (FK CASCADE) |
| 3 | Force-delete a remark | physically gone |

### TC-AUTH01/02/03 — Permissions
| Step | Action | Expected |
|------|--------|----------|
| 1 | Guest opens `/assessments/{id}` | redirect `/login` |
| 2 | Non-super-admin without `.update` POSTs bulk-rate | **403** |
| 3 | Non-super-admin without `.view` GETs show | **403** (gate fires before the fatal) |

### TC-DEV-REM-004/005 — Missing UI features
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `show.blade.php` | no Comment Bank / template panel |
| 2 | Inspect the remark textarea | no character counter, no `maxlength`, placeholder "Optional remark..." |

### TC-T01 — Tenancy
| Step | Action | Expected |
|------|--------|----------|
| 1 | Initialize tenant context | `tenancy()->initialized === true`; `ba_student_remarks` present in tenant DB |
