# Incident (Incident Log) — Manual Testing Guide

**Aligned to:** `bha_Incident_TestCas.php` (49 automated methods, `test_incident_NN_*`). Every manual case below maps to its automated method.

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (live table prefix `ba_`) |
| Feature / Screen | Incident — "Incident Log" (`12-Incident-Log*`) |
| Primary URL | `/behavioural-assessment/incidents-page?tab=log` (list) · `/behavioural-assessment/incidents/create` (create) · `/behavioural-assessment/incidents/{id}` (show) · `.../incidents/trash` |
| Endpoints | `POST /incidents` (store) · `PUT /incidents/{id}` (update) · `POST /incidents/{id}/follow-up` · `DELETE /incidents/{id}` (destroy) · `GET /incidents/{id}/restore` · `DELETE /incidents/{id}/force-delete` |
| Controller | `Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController` |
| FormRequest | `BaIncidentRequest` |
| Policy | `BaIncidentPolicy` |
| Model | `BaIncident` (table `ba_incidents`) |
| Junctions | `ba_incident_witnesses_jnt`, `ba_incident_intervention_jnt` |
| Runtime table | `ba_incidents` (DDL-doc says `bha_incidents` — divergence DOC-BA-001) |
| CRUD type | Full CRUD-transactional + follow-up append + soft-delete lifecycle |
| Soft delete | Yes (`deleted_at`); trash + restore + force-delete (cascades witnesses) |
| Pagination | Yes (incidents-page log tab) |
| Activity log | **`ba_audit_log`** via `BaAuditLog::log(entity_type='incident', ...)` — a per-entity audit sink (NOT the tenant `activity_logs` helper). store() writes field_name rows for incident_type / severity / location / student_id. |
| Permission prefix | `tenant.behavioural-assessment.incidents.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete\|status}` |
| DB scope | Tenant-side (database-per-tenant) |

### Prerequisites
1. BehaviouralAssessment module **enabled** in `modules_statuses.json`.
2. At least one `std_students` row (required FK for create) and one `sch_employees` row (reported_by / staff witness) — otherwise create/seed tests `markTestSkipped`.
3. Optionally one `ba_categories` row and one `ba_interventions` row (category + intervention attach).
4. A tenant admin user with all incident permissions (or super-admin).
5. Migrations applied: `ba_incidents` (+ `ba_incident_witnesses_jnt`, `ba_incident_intervention_jnt`, `ba_audit_log`) present with `incident_type`/`severity` ENUMs, `is_notified` TINYINT, soft-deletes.

---

## 2. Business Conditions (with messages & flows)

### Record lifecycle + post-create core-field lock
```
   (create)              destroy()              forceDelete()
  ───────────▶  Active  ───────────▶  Trashed  ─────────────▶  Purged
  is_notified=0           ▲   restore()   │                    (row gone,
  core fields LOCKED      └───────────────┘                    witnesses cascade)
  (BR-BA-008)
```
- **BR-BA-008 core-field lock:** after creation, core fields (student_id, incident_date/time, incident_type, severity, location, category_id, criterion_id, description) are immutable — update() rejects a change to them (row unchanged). Only follow-up fields (intervention_notes, is_follow_up_required, follow_up_date/notes) stay mutable.
- **forceDelete** cascades `ba_incident_witnesses_jnt` rows (FK ON DELETE CASCADE).

### incident_type / severity behaviour
| Field | Live values | Notes |
|-------|-------------|-------|
| incident_type | `positive_reinforcement`, `negative_incident` | Screen labels "Positive (Achievement)" / "Negative" diverge (INC-GAP-05) |
| severity | `minor`, `moderate`, `major`, `critical` (nullable) | Screen labels Info/Low/Medium/High diverge (INC-GAP-04); NULL for positives; `required_if` negative_incident |

### Validation (FormRequest `BaIncidentRequest`)
- student_id: required, `exists:std_students,id`.
- incident_type: required, `in:positive_reinforcement,negative_incident`.
- severity: `required_if:incident_type,negative_incident`, `in:minor,moderate,major,critical`.
- location: required, `in:` allowed enum (classroom, …).
- incident_date: `before_or_equal:today` (future rejected).
- incident_time: valid time format.
- follow_up_date: `after_or_equal:incident_date`.
- category_id: nullable, `exists:ba_categories,id` when present.
- description: `max:3000` only (no minimum).

### SEC-BA-001 — safeguarding notification gap (P1)
Per REQ-BA-015 / BR-BA-013 a High/critical negative incident MUST notify the homeroom teacher, HOD, principal and (per `ba_config.parent_notification_threshold`) the parent. **The implementation does none of this.** `store()` never sets `is_notified` and never dispatches any notification/mail/event. Observe: a `critical` incident is saved with `is_notified = 0` and no notification is produced.

### Known gaps to observe (not blockers)
- **INC-GAP-01:** a 30-day-old incident_date is accepted (only `before_or_equal:today`; the 7-day real-time rule is missing).
- **INC-GAP-02:** a 5-char description is accepted (no min-length rule).
- **INC-GAP-03:** an incident with no category is accepted (category_id is nullable despite "Mandatory: Yes").
- **INC-GAP-04 / 05:** UI/screen labels diverge from the stored enum values.

---

## 3. Test Cases (step-by-step)

### Config / schema truth
**TC-CFG01 — Schema & config truth (test_incident_01)**
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW TABLES LIKE 'ba_incidents'` | table exists |
| 2 | `SHOW COLUMNS FROM ba_incidents` | id, student_id, reported_by, category_id, criterion_id, incident_date, incident_time, incident_type, severity, description, location, intervention_notes, is_follow_up_required, follow_up_date, follow_up_notes, attachments_json, is_notified, is_active, created_by, updated_by, timestamps, deleted_at |
| 3 | Inspect model | binds `ba_incidents`; SoftDeletes; `is_notified`/`is_active` cast bool; `attachments_json` cast array |
| 4 | Open `BaIncidentRequest` | contains `exists:std_students,id`, `before_or_equal:today`, `in:positive_reinforcement,negative_incident`, `required_if:incident_type,negative_incident`, `in:minor,moderate,major,critical` |

**TC-CFG02 — Prefix divergence (test_incident_02):** confirm `ba_incidents` exists and `bha_incidents` does NOT (DOC-BA-001).

**TC-CFG03 — Junction + audit config (test_incident_03):** `ba_incident_witnesses_jnt` (id, incident_id, witness_type, witness_id, is_active) + `ba_incident_intervention_jnt` (id, incident_id, intervention_id, notes) exist; `ba_audit_log` exists; `BaAuditLog::ENTITY_INCIDENT` = 'incident'.

### Positive / business
**TC-P01 — Create (test_incident_10)**
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open create page; fill valid student + category + dates + description | form accepts |
| 2 | Submit `POST /incidents` | 200/302 success redirect |
| 3 | `SELECT incident_type,location FROM ba_incidents WHERE student_id=... ORDER BY id DESC LIMIT 1` | incident_type='negative_incident', location='classroom' |

**TC-P02 — Severity nulled for positive (test_incident_11):** POST with incident_type=positive_reinforcement + severity=critical → stored `severity` is NULL (INC-GAP-05).
**TC-P03 — Audit rows (test_incident_12):** after create, `SELECT field_name FROM ba_audit_log WHERE entity_type='incident' AND entity_id=<id>` contains incident_type, location, student_id.
**TC-P04 — Interventions attach (test_incident_13):** create with `interventions[]` → 1 row in `ba_incident_intervention_jnt` (skip if no ba_interventions row).
**TC-P05 — Witness attach (test_incident_14):** create with `witness_staff_ids[]` → ≥1 `ba_incident_witnesses_jnt` row with witness_type='staff'.
**TC-P06 — Update follow-up fields (test_incident_15):** PUT with intervention_notes + is_follow_up_required=1 → persisted.
**TC-P07 — Core-field lock (test_incident_16):** PUT attempting to change `description` → row unchanged (BR-BA-008).
**TC-P08 — Follow-up endpoint (test_incident_17):** `POST /incidents/{id}/follow-up` with follow_up_notes → follow_up_notes contains the text.
**TC-P09 — Show renders (test_incident_18):** visit `/incidents/{id}` → "Incident Detail" visible.
**TC-P10 — Log tab lists (test_incident_19):** visit `/incidents-page?tab=log` → table/pagination renders.

### Record lifecycle / state machine
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-SM01 | test_incident_20 | DELETE an incident | soft-deleted; hidden default, visible withTrashed |
| TC-SM02 | test_incident_21 | GET `/incidents/{id}/restore` a trashed incident | visible in default scope |
| TC-SM03 | test_incident_22 | DELETE `/incidents/{id}/force-delete` a trashed incident | row gone; 0 witness junction rows (cascade) |
| TC-SM04 | test_incident_23 | full lifecycle create→delete→restore→delete→force-delete | each stage as expected; purged at end |
| TC-SM05 | test_incident_24 | PUT attempting to change student_id | student_id unchanged (BR-BA-008 lock) |

### Negative / validation
| TC | Method | Input | Expected |
|----|--------|-------|----------|
| TC-N01 | test_incident_30 | empty student_id/incident_type/description | 422 for each |
| TC-N02 | test_incident_31 | student_id=999999999 | 422 student_id |
| TC-N03 | test_incident_32 | incident_type='made_up_type' | 422 incident_type |
| TC-N04 | test_incident_33 | incident_type=negative_incident, severity='' | 422 severity (required_if) |
| TC-N05 | test_incident_34 | severity='High' (screen label) | 422 severity (not a valid enum value) |
| TC-N06 | test_incident_35 | location='rooftop' | 422 location |
| TC-N07 | test_incident_36 | incident_date = tomorrow | 422 incident_date |
| TC-N08 | test_incident_37 | incident_time='25:99' | 422 incident_time |
| TC-N09 | test_incident_38 | follow_up_date 3 days before incident_date | 422 follow_up_date |
| TC-N10 | test_incident_39 | category_id=999999999 | 422 category_id |

### Permissions
| TC | Method | Actor / action | Expected |
|----|--------|----------------|----------|
| TC-N11 | test_incident_50 | guest visits create | redirect to /login |
| TC-N12 | test_incident_51 | limited user visits create | 401/403 |
| TC-N13 | test_incident_52 | limited user DELETE destroy | 401/403/419 |
| TC-N14 | test_incident_53 | limited user DELETE force-delete | 401/403/419 |
| TC-P11 | test_incident_54 | inspect Policy | viewAny/view/create/update/delete/restore/forceDelete map to permission strings |
| TC-S01 | test_incident_55 | inspect FormRequest + controller | authorize() returns bare `true` (SEC-BA-002); controller has `Gate::authorize('...incidents.create')` |

### UI / UX
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-P12 | test_incident_60 | incidents-page `&incident_type=negative_incident` | stays on `/incidents-page` |
| TC-P13 | test_incident_61 | incidents-page `&severity=critical` | stays on `/incidents-page` |
| TC-P14 | test_incident_62 | open trash page | page/table renders |
| TC-P15 | test_incident_63 | open show page | "Incident Detail" heading visible |

### Edge / requirement gaps
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-N15 | test_incident_70 | fetch id 999999999 | 403/404 |
| TC-G01 | test_incident_71 | create with incident_date 30 days ago | **accepted** — proves INC-GAP-01 (no 7-day rule) |
| TC-G02 | test_incident_72 | create with description "Short" (5 chars) | **accepted** — proves INC-GAP-02 (no min) |
| TC-G03 | test_incident_73 | create with null category | **accepted** — proves INC-GAP-03 (not mandatory) |
| TC-G04 | test_incident_74 | inspect severity column type | enum minor/moderate/major/critical, no 'info' label (INC-GAP-04) |
| TC-G05 | test_incident_75 | inspect incident_type column type | contains positive_reinforcement + negative_incident |

### Tenancy / security
| TC | Method | Action | Expected |
|----|--------|--------|----------|
| TC-T01 | test_incident_90 | check tenant context | tenancy initialized |
| TC-T02 | test_incident_91 | seed incident, query by id | exactly one row for id in this tenant DB (database-per-tenant isolation) |
| TC-S02 | test_incident_92 | create a `critical` negative incident | `is_notified = 0` — **SEC-BA-001**: no parent/staff notification produced |
| TC-S03 | test_incident_93 | scan module source | ZERO notify/dispatch/Mail/event() call sites — **SEC-BA-001** source proof (skips if source not co-located) |
| TC-S04 | test_incident_94 | create with `<script>` in description; open show | stored but NOT executed (window flag not set) |
