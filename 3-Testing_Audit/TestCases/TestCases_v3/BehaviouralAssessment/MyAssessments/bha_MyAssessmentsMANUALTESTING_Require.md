# My Assessments — Manual Testing Specification (`bha_MyAssessmentsMANUALTESTING_Require.md`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (BHA) |
| Feature / Screen | My Assessments (`08-My-Assessments*`) — *my-assessments* tab |
| Page URL | `/behavioural-assessment/assessments-page?tab=my-assessments` |
| Store/CRUD base | `/behavioural-assessment/assessments` |
| Create route | `/behavioural-assessment/assessments/create` |
| Trash route | `/behavioural-assessment/assessments/trash` |
| Controller | `BaAssessmentController` (page via `BaDashboardController::assessmentsPage()`) |
| FormRequest | `BaAssessmentRequest` |
| Policy | `BaAssessmentPolicy` |
| Models | `BaAssessment`, `BaAssessmentPeriod`, `BaAuditLog` |
| Primary table | `ba_assessments` (live `ba_` prefix — DDL doc shows stale `bha_`, **DOC-BA-001**) |
| Audit table | `ba_audit_log` (immutable; `entity_type='assessment'`) |
| CRUD type | CRUD-transactional Full |
| Soft delete | Yes (`deleted_at`) |
| Status enum | `draft`, `submitted`, `reviewed`, `locked` (4 values) |
| DB scope | Tenant-side (database-per-tenant) |
| Activity log | `ba_audit_log` via `BaAuditLog::log(...)` — **not** `sys_activity_logs` |
| Permission prefix | `tenant.behavioural-assessment.assessments.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete\|status}` + `assessments-page.viewAny` |

**Precondition data:** one row each in `sch_employees`, `sch_class_section_jnt`, and `sch_org_academic_sessions_jnt`; at least one `ba_assessment_periods` row with `status='open'`.

---

## 2. Business Conditions (with error messages & flow)

### State machine
```
(none) --store--> draft --submit--> submitted --approve--> reviewed --lock--> locked
                    ^                                 |
                    +------------- sendBack ----------+
```
MyAssessments (teacher) owns: **create → draft**, **submit → draft→submitted**. `edit / update / destroy` are **draft-only** (post-submission freeze).

### Store / create audit flow
```
POST /assessments (period_id, class_section_id, teacher_id)
  → Gate: assessments.create
  → firstOrCreate({teacher,cs,period, status:'draft'})
  → ba_audit_log: entity=assessment, field=status, old=NULL, new='draft'
  → is_active=1, created_by=current user
```

### Error messages (assert verbatim)
| Situation | HTTP | Message |
|-----------|------|---------|
| Missing assessor (non-employee user, no teacher_id) | 422 | `An assessor/teacher must be specified.` |
| edit() on non-draft | 422 | `Only draft assessments can be edited` |
| update() on non-draft | 422 | `Only draft assessments can be updated` |
| destroy() on non-draft | 422 | `Only draft assessments can be deleted` |
| Missing required period_id / class_section_id | 422 | validation `errors` keys |
| Non-existent / non-integer FK | 422 | validation `errors` keys |
| Guest | 302 | redirect to `/login` |
| Missing permission | 403 | forbidden |

### Known defects to reproduce manually
- **BUG-BA-MYA-001 (P0):** open "View Summary" (`GET /assessments/{id}`) → HTTP 500 (un-imported `BaStudentRemark`).
- **VAL-BA-MYA-004 (P1):** submit a 0%-complete draft → it still submits (no completion gate).
- **BUG-BA-MYA-005 (P1):** create over an existing *submitted* triple → 500 unique violation.
- **PERM-BA-MYA-003 (P1):** restore/forceDelete are gated by `.delete`, not `.restore`/`.forceDelete`.
- **DOC-BA-001 / SEC-BA-002:** documentation / defensive — see Test Cases.

---

## 3. Manual Test Cases (Step / Action / Expected + DB & audit checks)

### TC-01 — Schema & config truth *(→ `_01`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | `SHOW TABLES LIKE 'ba_assessments'` | Table exists |
| 2 | Inspect columns | id, period_id, teacher_id, class_section_id, status, submitted_at, reviewed_by, reviewed_at, reviewer_remarks, is_active, created_by, updated_by, timestamps, deleted_at |
| 3 | Inspect `status` column type | `enum` containing draft/submitted/reviewed/locked |
| 4 | Inspect unique index | `unique(teacher_id, class_section_id, period_id)` |
| 5 | Open `BaAssessmentRequest` | Contains `exists:ba_assessment_periods,id`, `exists:sch_class_section_jnt,id`, `exists:sch_employees,id` |

### TC-02 — Prefix divergence *(→ `_02`)* **[DOC-BA-001]**
| # | Action | Expected |
|---|--------|----------|
| 1 | `SHOW TABLES LIKE 'ba_assessments'` | Exists |
| 2 | `SHOW TABLES LIKE 'bha_assessments'` | Does **not** exist |

### TC-03 — Audit log immutability *(→ `_03`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | Inspect `ba_audit_log` columns | id, entity_type, entity_id, field_name, old_value, new_value, changed_by, changed_at, is_active, created_by, created_at |
| 2 | Check `updated_at` / `deleted_at` | Absent (immutable) |

### TC-10 — Create draft + audit *(→ `_10`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | POST `/assessments` with valid period+cs+teacher | Not 422 |
| 2 | `SELECT * FROM ba_assessments WHERE period_id=?` | 1 row, `status='draft'`, `is_active=1`, `created_by=me` |
| 3 | `SELECT * FROM ba_audit_log WHERE entity_type='assessment' AND field_name='status' AND new_value='draft'` | Row present |

### TC-11 — Idempotent create *(→ `_11`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | POST same payload twice | Both not 422 |
| 2 | `SELECT COUNT(*)` for the triple | Exactly 1 |

### TC-12 — Missing assessor rejected *(→ `_12`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | POST without `teacher_id` (root has no employee mapping) | 422, message `assessor/teacher must be specified` |

### TC-13 — Tab renders *(→ `_13`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | Visit `?tab=my-assessments` | "Save Assessment" visible |

### TC-14 — Update period + audit *(→ `_14`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | Seed a draft; PUT `/assessments/{id}` new period_id | Not 422 |
| 2 | `SELECT period_id, updated_by` | period changed, updated_by=me |
| 3 | `ba_audit_log` field_name=`period_id` | Row present |

### TC-15 — details JSON *(→ `_15`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | GET `/assessments/{id}/details` | 200, JSON `id` matches |

### TC-16 — Status filter *(→ `_16`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | Seed draft + submitted; visit `&status=submitted` | Page source contains "Submitted" |

### TC-17 — Period filter *(→ `_17`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | Visit `&period_id={id}` | Page renders ("Save Assessment") |

### TC-20 — Submit draft→submitted *(→ `_20`)* **[BC-SM-01]**
| # | Action | Expected |
|---|--------|----------|
| 1 | Seed draft; POST `/assessments/{id}/submit` | 200/302 |
| 2 | `SELECT status, submitted_at` | `submitted`, submitted_at not null |
| 3 | `ba_audit_log` status old=draft new=submitted | Row present |

### TC-21 — Submit non-draft rejected *(→ `_21`)* **[BC-SM-02]**
| # | Action | Expected |
|---|--------|----------|
| 1 | Seed submitted; POST submit | Status stays `submitted` |

### TC-22 — Edit non-draft 422 *(→ `_22`)* **[BC-SM-03]**
| 1 | Seed submitted; GET `/edit` | 422 `Only draft assessments can be edited` |

### TC-23 — Update non-draft 422 *(→ `_23`)* **[BC-SM-04]**
| 1 | Seed submitted; PUT period | 422 `Only draft assessments can be updated`; period unchanged |

### TC-24 — Destroy non-draft 422 *(→ `_24`)* **[BC-SM-05]**
| 1 | Seed submitted; DELETE | 422 `Only draft assessments can be deleted`; row survives |

### TC-25 — Submit below 100% *(→ `_25`)* **[VAL-BA-MYA-004]**
| # | Action | Expected |
|---|--------|----------|
| 1 | Seed draft with ZERO ratings; POST submit | Status becomes `submitted` — **proves missing completion gate** |

### TC-30..34 — Validation negatives *(→ `_30`–`_34`)*
| TC | Action | Expected |
|----|--------|----------|
| 30 | POST empty period_id + class_section_id | 422; `errors.period_id`, `errors.class_section_id` |
| 31 | POST period_id=987654321 | 422; `errors.period_id` |
| 32 | POST class_section_id=987654321 | 422; `errors.class_section_id` |
| 33 | POST teacher_id=987654321 | 422; `errors.teacher_id` |
| 34 | POST period_id='abc' | 422; `errors.period_id` |

### TC-35 — Unique violation *(→ `_35`)* **[BUG-BA-MYA-005]**
| # | Action | Expected |
|---|--------|----------|
| 1 | Seed a `submitted` row for triple; POST create for same triple | 500 unique violation |
| 2 | `SELECT COUNT(*)` triple | Still 1 |

### TC-40..42 — Soft-delete lifecycle *(→ `_40`–`_42`)*
| TC | Action | Expected |
|----|--------|----------|
| 40 | DELETE a draft | 200/302; hidden from default scope, present in `onlyTrashed` |
| 41 | GET `/{id}/restore` on trashed | 200/302; back in default scope |
| 42 | DELETE `/{id}/force-delete` on trashed | 200/302; physically gone (`withTrashed` empty) |

### TC-43..45 — FK rules *(→ `_43`–`_45`)*
| TC | Action | Expected |
|----|--------|----------|
| 43 | Inspect `period_id` FK delete rule | RESTRICT / NO ACTION |
| 44 | Inspect `teacher_id` + `class_section_id` FK delete rules | RESTRICT / NO ACTION |
| 45 | Inspect `reviewed_by` FK delete rule | SET NULL |

### TC-46 — Full lifecycle *(→ `_46`)*
| # | Action | Expected |
|---|--------|----------|
| 1 | create → submit → GET `/edit` | edit blocked 422 |

### TC-47 — View Summary fatals *(→ `_47`)* **[BUG-BA-MYA-001]**
| # | Action | Expected |
|---|--------|----------|
| 1 | GET `/assessments/{id}` (View Summary) | HTTP 500 (un-imported `BaStudentRemark`) |

### TC-50..55 — Authorization *(→ `_50`–`_55`)*
| TC | Action | Expected |
|----|--------|----------|
| 50 | Visit page as guest (cookies cleared) | Redirect to `/login` |
| 51 | Limited user (no create) POST store | 403 |
| 52 | Limited user (no update) POST submit | 403 |
| 53 | Limited user (no delete) DELETE | 403 |
| 54 | Read `BaAssessmentPolicy` | Contains all 8 `tenant.behavioural-assessment.assessments.*` strings |
| 55 | Read controller `restore()`/`forceDelete()` | Gate on `.delete`, no `.restore`/`.forceDelete` — **PERM-BA-MYA-003** |

### TC-60..63 — UI/UX *(→ `_60`–`_63`)*
| TC | Action | Expected |
|----|--------|----------|
| 60 | Seed draft; open tab | "Draft" badge rendered |
| 61 | Visit with implausible status+period filter | "No assessments found." |
| 62 | Soft-delete then visit trash page | "Trash" heading renders |
| 63 | Open tab | `assessmentModal` + "Save Assessment" present |

### TC-70..72 — Edge *(→ `_70`–`_72`)*
| TC | Action | Expected |
|----|--------|----------|
| 70 | POST `/987654321/submit` | 404 |
| 71 | GET `/987654321/details` and `/987654321/edit` | 404 each |
| 72 | Inspect status enum | includes draft/submitted/reviewed/locked |

### TC-90..94 — Tenancy + Security *(→ `_90`–`_94`)*
| TC | Action | Expected |
|----|--------|----------|
| 90 | Check tenancy | initialized; table present |
| 91 | Find a second tenant domain | isolation asserted, else skip |
| 92 | Read `BaAssessmentRequest::authorize()` | returns bare `true` — **SEC-BA-002** |
| 93 | POST store with `status=reviewed`, `reviewed_by=999999` | row stays `draft` (override ignored) |
| 94 | Seed `reviewer_remarks` with `<script>alert(1)</script>`; open tab | raw `<script>` not in page source |
