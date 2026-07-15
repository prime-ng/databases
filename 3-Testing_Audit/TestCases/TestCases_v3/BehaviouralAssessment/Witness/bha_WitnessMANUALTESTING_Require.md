# Behavioural Assessment — Witness — Manual Testing Spec

**Companion to:** `bha_Witness_TestCas.php` (40 automated Dusk methods) · **1:1 traceable**
**Screen:** `13-Witnesses*` (nested child of Incident) · **DB scope:** TENANT-side

---

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (`bha_` file prefix; **live tables `ba_`**) |
| Feature / Screen | Witness — nested child of Incident (no standalone screen/route) |
| Primary table | `ba_incident_witnesses_jnt` (junction; polymorphic) |
| Parent table | `ba_incidents` |
| Entry URLs | Incident create `/behavioural-assessment/incidents/create`; store `POST /behavioural-assessment/incidents`; update `PUT /behavioural-assessment/incidents/{id}` |
| Controller | `Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController` (`store()`, `update()`, `show()`) |
| Models | `BaIncidentWitnessJnt`, `BaIncident` (`witnesses()` HasMany) |
| FormRequest | `BaIncidentRequest` — `witness_student_ids[]`, `witness_staff_ids[]` |
| Migration | `database/migrations/tenant/2026_06_16_130627_create_ba_incident_witnesses_jnt_table.php` |
| CRUD type | Attach/sync via parent incident form (checkbox arrays) — no dedicated witness CRUD |
| Soft delete | **Column present (`deleted_at`) but model has NO SoftDeletes** → `->delete()` hard-deletes (DATA-BA-WIT-05) |
| Permissions | Inherit parent incident gates `tenant.behavioural-assessment.incidents.{create|update|...}` |
| Activity log | Governed by the incident flow; witness junction itself has no dedicated event |
| Attach mapping | `witness_student_ids[]`→`witness_type='student'`,`witness_id=std_students.id`; `witness_staff_ids[]`→`witness_type='staff'`,`witness_id=sch_employees.id` |

### Prerequisites (environment)
- **BehaviouralAssessment module ENABLED** in `prime_testing/modules_statuses.json` (else all `/behavioural-assessment` routes 404).
- `APP_ENV=testing` (CSRF bypass for authenticated state-changing requests; else 419).
- Tenant host reachable at `DUSK_TENANT_URL` (`http://test.localhost:8000`); admin creds `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`.
- Tenant DB migrated; **cross-module rows present** in `std_students` and `sch_employees` (else data-layer tests self-skip).
- A 2nd tenant domain for the cross-tenant isolation check (else that test self-skips).

---

## 2. Business Conditions (detailed)

**Attach flow (store).** The incident form posts `witness_student_ids[]` and `witness_staff_ids[]`. `store()` writes one junction row per id: students as `witness_type='student'`, staff as `witness_type='staff'`, each with `is_active=true` and `created_by`/`updated_by`=actor. Staff use `firstOrCreate()`; students use plain `create()`.

**Re-sync flow (update).** `update()` does a full re-sync: `BaIncidentWitnessJnt::where('incident_id',$id)->forceDelete()` then recreates all rows from the posted arrays. It never consults incident status or a lock flag.

**Uniqueness.** `UNIQUE(incident_id, witness_type, witness_id)` (`uq_ba_witness`) — one row per (incident, type, id).

**Cascade.** `incident_id` FK → `ba_incidents.id` ON DELETE **CASCADE**; `witness_id` is polymorphic (no DB FK).

**Known defects surfaced (documented, not fixed):**
- **DATA-BA-WIT-01** — requirement's per-witness "Witness Statement" (min 10/max 500) is entirely unimplemented.
- **BUG-BA-WIT-02** — "Self-Referential Block" (subject student ≠ own witness) not enforced.
- **BUG-BA-WIT-03** — "Audit Lock" (freeze witnesses once incident closed/resolved) not enforced.
- **BUG-BA-WIT-04** — student attach loop lacks dedup (asymmetric with staff `firstOrCreate`).
- **DATA-BA-WIT-05** — `deleted_at` present but model omits `SoftDeletes` (dead column, hard delete).
- **DOC-BA-001** — DDL doc uses `bha_*`; runtime is `ba_*` (index `uq_bha_witness` → `uq_ba_witness`).

---

## 3. Manual Test Cases (step-by-step)

> Each case maps to the like-numbered automated method. DB checks use the live tenant DB.

### TC-P01 — Junction schema & model config (`_01`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW TABLES LIKE 'ba_incident_witnesses_jnt'` | Table exists |
| 2 | `SHOW COLUMNS FROM ba_incident_witnesses_jnt` | id, incident_id, witness_type, witness_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at |
| 3 | Inspect types | incident_id BIGINT; witness_id INT/BIGINT; witness_type ENUM |
| 4 | Inspect `BaIncidentWitnessJnt` model | table=`ba_incident_witnesses_jnt`; fillable = incident_id,witness_id,witness_type,is_active,created_by,updated_by; `incident()` BelongsTo |

### TC-P02 — Runtime prefix `ba_` vs doc `bha_` (`_02`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check `ba_incident_witnesses_jnt` and `ba_incidents` | Both exist |
| 2 | Check `bha_incident_witnesses_jnt` | Does NOT exist (DOC-BA-001) |
| 3 | Model `getTable()` | Binds `ba_` names |

### TC-P03 — Composite unique key (`_03`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW INDEX FROM ba_incident_witnesses_jnt WHERE Non_unique=0` | A unique index on columns `(incident_id, witness_type, witness_id)` exists (name may be `uq_ba_witness`) |

### TC-P04 — Enum lowercase (`_04`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `witness_type` column type | `enum('student','staff')` — lowercase, not `'Student'`/`'Staff'` |

### TC-N05 — Model omits SoftDeletes (DATA-BA-WIT-05) (`_05`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm `deleted_at` column present | Present |
| 2 | Check `class_uses_recursive(BaIncidentWitnessJnt)` | Does NOT include `SoftDeletes` → column dead, `->delete()` hard-deletes |

### TC-P10 / TC-P11 — Student / Staff witness persists (`_10`,`_11`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed an incident; pick a `std_students.id` (P10) / `sch_employees.id` (P11) | Ids resolved (else skip) |
| 2 | Attach witness of that type | `SELECT … WHERE incident_id=? AND witness_type=? AND witness_id=?` → 1 row |

### TC-P12 — is_active default + audit columns (`_12`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attach a student witness | Row created |
| 2 | Refresh row | `is_active`=true; `created_by`=`updated_by`=actor id; `created_at` not null |

### TC-P13 — store() attaches both types (`_13`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `BaIncidentController::store()` source | Reads `witness_student_ids` + `witness_staff_ids`; writes `witness_type='student'` and `'staff'` |

### TC-P14 — update() re-sync force-delete then recreate (`_14`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `update()` source | Calls `BaIncidentWitnessJnt::where('incident_id',$incident->id)->forceDelete()` then recreates from arrays |

### TC-P15 — witnesses() HasMany (`_15`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `BaIncident::witnesses()` | Returns `HasMany` |

### TC-N20 — Audit-lock not enforced (source) — BUG-BA-WIT-03 (`_20`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `update()` body | No `isLocked` / `is_frozen` / `=== 'closed'` guard before witness re-sync |

### TC-N21 — Witness attachable regardless of state — BUG-BA-WIT-03 (`_21`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident; mark follow-up complete (simulate "resolved") | Incident updated |
| 2 | Attach a student witness | Row accepted — freeze not enforced |

### TC-N30 / TC-N31 — Witness-id validation rules (`_30`,`_31`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `BaIncidentRequest::rules()` | `witness_student_ids.*` = `['integer','exists:std_students,id']`, nullable array; `witness_staff_ids.*` = `['integer','exists:sch_employees,id']`, nullable array |

### TC-N32 — Arrays optional (`_32`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm `witness_student_ids` declared `['nullable','array']` | Present → incident may be logged with zero witnesses |

### TC-N33 — Witness statement unimplemented — DATA-BA-WIT-01 (`_33`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW COLUMNS` for `statement`/`witness_statement` | Absent |
| 2 | Model fillable | No `statement` |
| 3 | FormRequest + create blade | No `statement`/`witness_statement` rule or field |

### TC-N34 — Self-referential block absent (source) — BUG-BA-WIT-02 (`_34`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | FormRequest | No `different:student_id` guard |
| 2 | `store()` body | No subject-exclusion logic |

### TC-N35 — Subject student as own witness (data) — BUG-BA-WIT-02 (`_35`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident; take its `student_id` as subject | Subject id resolved |
| 2 | Attach that student as witness | Row accepted (bug proven) |

### TC-D40 / TC-D41 / TC-D45 — Cascade delete (`_40`,`_41`,`_45`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attach witness(es) to a seeded incident | Rows created |
| 2 | `SELECT DELETE_RULE` for incident FK | CASCADE (`_41`) |
| 3 | Force-delete parent incident | All its witness rows removed (`_40`; `_45` starts with 2 rows → 0) |

### TC-D42 — Polymorphic (no FK on witness_id) (`_42`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Query `information_schema.KEY_COLUMN_USAGE` for FK columns | `incident_id` present; `witness_id` absent |

### TC-N43 — Duplicate row rejected (`_43`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attach a student witness | 1 row |
| 2 | Insert identical `(incident,'student',id)` again | Throws (uq_ba_witness); count stays 1 |

### TC-N44 — Student loop lacks dedup — BUG-BA-WIT-04 (`_44`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `store()` body | Staff → `BaIncidentWitnessJnt::firstOrCreate`; student → plain `create([…])`; no `array_unique($request->witness_student_ids…)` |

### TC-N50 — Guest redirect (`_50`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies; visit `/behavioural-assessment/incidents/create` | Redirected; path contains `/login` |

### TC-N51 / TC-N52 — Limited user 403 (`_51`,`_52`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a non-super-admin user with NO incident permissions/roles | User created |
| 2 | POST `/behavioural-assessment/incidents` (`_51`) / PUT `/…/{id}` (`_52`) with witness ids | HTTP 403 |

### TC-P53 — Policy permission strings (`_53`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `BaIncidentPolicy` | Each of viewAny/view/create/update/delete/restore/forceDelete/status maps to `tenant.behavioural-assessment.incidents.*` |

### TC-P54 — No standalone witness routes (`_54`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Route::has(...)` for witness route names | All false |
| 2 | `Route::has('behavioural-assessment.incidents.store'/'.update')` | True |

### TC-P60 / TC-P61 / TC-S62 — Blade selectors (`_60`,`_61`,`_62`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | create.blade | `name="witness_student_ids[]"`, `name="witness_staff_ids[]"`, id markers `ws_{{id}}`/`wf_{{id}}` |
| 2 | edit.blade | `old('witness_student_ids',$witnessStudentIds)` and staff equivalent (pre-checks saved) |
| 3 | show.blade | Names echoed escaped `{{ }}`, no `{!! !!}`; "No witnesses recorded." empty state |

### TC-D70 / TC-D71 / TC-N72 — Edge cases (`_70`,`_71`,`_72`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed incident, attach no witnesses | Count 0; relationship empty (`_70`) |
| 2 | Call `firstOrCreate` for same staff twice | Exactly 1 row (`_71`) |
| 3 | GET `/behavioural-assessment/incidents/987654321` | HTTP 404 (`_72`) |

### TC-T90 / TC-T91 / TC-S92 / TC-S93 — Tenancy & security (`_90`–`_93`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm `tenancy()->initialized` | True; junction table present (`_90`) |
| 2 | Find a 2nd tenant domain | Present → isolation assertable, else skip (`_91`) |
| 3 | Attach witness; inspect stored row | `witness_id` integer; `witness_type` ∈ {student,staff} — no free-text (`_92`) |
| 4 | Insert `witness_type='parent'` | Rejected by DB enum (`_93`) |
