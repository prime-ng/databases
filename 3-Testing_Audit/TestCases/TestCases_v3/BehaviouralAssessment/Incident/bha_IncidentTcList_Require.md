# Incident (Incident Log) — Test Case List & Business Conditions

**Module:** BehaviouralAssessment (BHA / live prefix `ba_`) · **Feature/Screen:** Incident (screen `12-Incident-Log*`)
**File prefix:** `bha_` (registry/DDL-doc name) · **Real runtime table:** `ba_incidents` (prefix divergence — DOC-BA-001)
**DB scope:** TENANT-side (database-per-tenant, no `tenant_id` columns → tenancy scaffolding emitted)
**Test style:** Browser Dusk (`namespace Tests\Browser`; `extends DuskTestCase`)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaIncidentController` · route base `incidents` / page `incidents-page`
**FormRequest:** `BaIncidentRequest` · **Policy:** `BaIncidentPolicy` · **Model:** `BaIncident`
**Junctions:** `BaIncidentWitnessJnt` (`ba_incident_witnesses_jnt`), `BaIncidentInterventionJnt` (`ba_incident_intervention_jnt`)
**CRUD master:** Full (CRUD-transactional) · **Feature class:** CRUD + record lifecycle + post-create core-field lock (BR-BA-008)
**Audit log:** `ba_audit_log` via `BaAuditLog::log(entity_type='incident', ...)` — a dedicated per-entity audit sink, NOT the tenant `activity_logs` helper. Assert the literal `field_name` rows written by `store()`.
**Screen requirement:** `2-Module_Requirement_V1/BehaviouralAssessment_v2/12-Incident-Log.md`
**Test file:** `bha_Incident_TestCas.php` — **ONE comprehensive file, 49 methods** (no V1/V2 split), method naming `test_incident_NN_*`.

---

## 1. Business Conditions

### BC-DB — Schema truth (Source: `DDL-bha_incidents`; live table `ba_incidents`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Runtime table `ba_incidents` exists; DDL-doc name `bha_incidents` does NOT (prefix divergence) | DDL / DOC-BA-001 |
| BC-DB-02 | Columns: id, student_id, reported_by, category_id, criterion_id, incident_date, incident_time, incident_type, severity, description, location, intervention_notes, is_follow_up_required, follow_up_date, follow_up_notes, attachments_json, is_notified, is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-03 | `incident_type` ENUM('positive_reinforcement','negative_incident') | DDL / migration |
| BC-DB-04 | `severity` ENUM('minor','moderate','major','critical'); nullable (NULL for positives) | DDL / migration |
| BC-DB-05 | `is_notified` TINYINT(1) (safeguarding notify flag), `is_active` TINYINT(1); `deleted_at` soft-delete column present | DDL |
| BC-DB-06 | Model binds `ba_incidents`; fillable incl. student_id, reported_by, category_id, incident_date, incident_type, severity, description, location, is_notified, is_active; uses `SoftDeletes`; casts `is_notified`/`is_active` → boolean, `attachments_json` → array | Model |
| BC-DB-07 | Junctions: `ba_incident_witnesses_jnt` (id, incident_id, witness_type, witness_id, is_active); `ba_incident_intervention_jnt` (id, incident_id, intervention_id, notes); `witnesses()` relation resolves to the witness junction | Model / DDL |
| BC-DB-08 | Audit sink `ba_audit_log` exists; `BaAuditLog::getTable()` = `ba_audit_log`; `BaAuditLog::ENTITY_INCIDENT` constant = `'incident'` | Model |

### BC-VAL — Validation (Source: `BaIncidentRequest`)
| ID | Rule | Behaviour | Source |
|----|------|-----------|--------|
| BC-VAL-01 | student_id required, `exists:std_students,id` | 422 | Req |
| BC-VAL-02 | incident_type required, `in:positive_reinforcement,negative_incident` | 422 | Req |
| BC-VAL-03 | severity `required_if:incident_type,negative_incident`, `in:minor,moderate,major,critical` | 422 (required + enum) | Req |
| BC-VAL-04 | location required, `in:` allowed enum (e.g. classroom) | 422 | Req |
| BC-VAL-05 | incident_date `before_or_equal:today` (future rejected) | 422 | Req |
| BC-VAL-06 | incident_time date/time format | 422 on bad format | Req |
| BC-VAL-07 | follow_up_date `after_or_equal:incident_date` | 422 | Req |
| BC-VAL-08 | category_id nullable, `exists:ba_categories,id` when present (INC-GAP-03 — screen marks Category mandatory) | 422 only if present+invalid | Req |
| BC-VAL-09 | description `max:3000`, **no min** (INC-GAP-02 — screen requires Min 20 / Max 1000) | accepted <20, rejected >3000 | Req |
| BC-VAL-10 | FormRequest `authorize()` returns bare `true` (mitigated by controller Gate) → SEC-BA-002 | — | Req |

### BC-AUTH — Permissions (Source: Controller `Gate::authorize` + `BaIncidentPolicy`)
| ID | Method | Gate ability (prefix `tenant.behavioural-assessment.incidents.`) | Source |
|----|--------|-------------------------------------------------------------------|--------|
| BC-AUTH-01 | index / incidents-page / trash | `viewAny` (+ page `incidents-page.viewAny`) | Ctrl |
| BC-AUTH-02 | create / store | `create` | Ctrl |
| BC-AUTH-03 | show | `view` | Ctrl |
| BC-AUTH-04 | edit / update / follow-up | `update` | Ctrl |
| BC-AUTH-05 | destroy | `delete` | Ctrl |
| BC-AUTH-06 | restore / forceDelete | `restore` / `forceDelete` | Ctrl |
| BC-AUTH-07 | status toggle | `status` | Ctrl |
| BC-AUTH-08 | guest → /login; super-admin bypasses gates | redirect / bypass | middleware |
| BC-AUTH-09 | FormRequest `authorize()` bare `true` (Gate-mitigated) → SEC-BA-002 | — | Req |

### BC-BIZ — Business logic (Source: Controller + Screen `12-Incident-Log`)
| ID | Rule | Source |
|----|------|--------|
| BC-BIZ-01 | store() persists incident and redirects with success flash (200/302) | Ctrl |
| BC-BIZ-02 | store() nulls `severity` for `positive_reinforcement` even if a severity is posted (INC-GAP-05) | Ctrl |
| BC-BIZ-03 | store() writes audit rows to `ba_audit_log` with field_name in {incident_type, severity, location, student_id} | Ctrl |
| BC-BIZ-04 | store() attaches selected interventions to `ba_incident_intervention_jnt` | Ctrl |
| BC-BIZ-05 | store() attaches student/staff witnesses to `ba_incident_witnesses_jnt` (witness_type='staff'/'student') | Ctrl |
| BC-BIZ-06 | update() persists mutable follow-up fields (intervention_notes, is_follow_up_required) | Ctrl |
| BC-BIZ-07 | update() blocks core-field change (BR-BA-008) — returns error, row unchanged | Ctrl / Screen-BR |
| BC-BIZ-08 | follow-up endpoint `POST /incidents/{id}/follow-up` appends `follow_up_notes` | Ctrl |
| BC-BIZ-09 | **SEC-BA-001:** severe (High/critical) negative incident triggers NO notification; `is_notified` stays 0; no notify/dispatch/Mail/event() call sites in module | Ctrl (absent) / Audit |

### BC-SM — Record lifecycle + core-field lock (Source: `Screen-SM` / Controller) — states `Active` / `Trashed` / `Purged`
| ID | State | Trigger | Next | Notes | Source |
|----|-------|---------|------|-------|--------|
| BC-SM-01 | (create) | store() | Active | is_notified=0 on create | Ctrl |
| BC-SM-02 | Active | destroy() | Trashed | soft-delete; invisible to default scope | Ctrl |
| BC-SM-03 | Trashed | restore() | Active | visible again in default scope | Ctrl |
| BC-SM-04 | Trashed | forceDelete() | Purged | physical delete; cascades witness junction (FK ON DELETE CASCADE) | Ctrl / DDL |
| BC-SM-05 | Purged | restore() | (impossible) | force-deleted id cannot be recovered → 404 | Ctrl |
| BC-SM-06 | Active | update() of core field (student_id/description/…) | (blocked, unchanged) | BR-BA-008 post-create core-field lock | Ctrl / Screen-BR |

> **Legal cycle:** `(create)→Active ⇄(delete/restore) Trashed →(forceDelete) Purged`. Core fields are locked immediately after creation (BR-BA-008); only follow-up / intervention_notes fields remain mutable.

### BC-INT / BC-REF — FK & cross-module (Source: migration / DDL)
| ID | FK | Referenced | onDelete | Source |
|----|----|-----------|----------|--------|
| BC-INT-01 | student_id | std_students.id (StudentProfile module) | RESTRICT | DDL / Screen-IP |
| BC-INT-02 | reported_by | sch_employees.id (SchoolSetup staff) | RESTRICT | DDL |
| BC-REF-01 | category_id | ba_categories.id | SET NULL / nullable | DDL |
| BC-REF-02 | criterion_id | ba_criteria.id (nullable) | SET NULL | DDL |
| BC-REF-03 | ba_incident_witnesses_jnt.incident_id | ba_incidents.id | CASCADE | DDL |
| BC-REF-04 | ba_incident_intervention_jnt.incident_id / intervention_id | ba_incidents.id / ba_interventions.id | CASCADE / RESTRICT | DDL |

### BC-EDG / BC-CFG — Edge & requirement-vs-impl gaps
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | invalid / non-existent id → 404 (show/direct fetch) | Ctrl route binding |
| BC-EDG-02 | XSS payload in description stored, NOT executed on show page | Blade / Security |
| INC-GAP-01 | "max 7 days from event" real-time-logging rule NOT enforced — only `before_or_equal:today` (30-day-old date accepted) | Screen-BR vs Req |
| INC-GAP-02 | description Min 20 / Max 1000 (screen) NOT enforced — rule is only `max:3000`, no min (5-char body accepted) | Screen-VR vs Req |
| INC-GAP-03 | Category marked Mandatory (screen) but `category_id` is nullable in FormRequest (null accepted) | Screen-VR vs Req |
| INC-GAP-04 | severity labels Info/Low/Medium/High (screen) diverge from enum minor/moderate/major/critical | Screen-VR vs DDL |
| INC-GAP-05 | positive incident_type value is `positive_reinforcement`, not the screen's "Positive (Achievement)" | Screen vs code |

---

## 2. Test Case List (one row per test method — mirrors the 49-method `.php` 1:1)

### Schema / config truth (Band 01–09)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-CFG01 | Config | BC-DB-02..06, BC-VAL-01/02/03/05 | DDL/Req/Model | Schema, columns, soft-delete trait, fillable, casts, relationship, FormRequest rule strings | table/columns/casts/rules all match | test_incident_01 | ✅ |
| TC-CFG02 | Config | BC-DB-01 | DOC-BA-001 | Runtime `ba_incidents` diverges from DDL-doc `bha_incidents` | ba_ exists, bha_ absent | test_incident_02 | ✅ |
| TC-CFG03 | Config | BC-DB-07/08 | DDL/Model | Junction + audit table config truth | witness/intervention/audit tables + `ENTITY_INCIDENT` correct | test_incident_03 | ✅ |

### Positive / business rules (Band 10–19)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Positive | BC-BIZ-01 | Ctrl | Create persists incident + success redirect | row persisted; type/location set | test_incident_10 | ✅ |
| TC-P02 | Positive | BC-BIZ-02 | Ctrl | Severity nulled for positive_reinforcement (posted severity discarded) | severity NULL | test_incident_11 | ✅ |
| TC-P03 | Positive | BC-BIZ-03 | Ctrl | Create logs audit rows to ba_audit_log | field_name rows incident_type/location/student_id | test_incident_12 | ✅ |
| TC-P04 | Positive | BC-BIZ-04/BC-REF-04 | Ctrl | Create attaches interventions to junction | 1 intervention row (or skip) | test_incident_13 | ✅ |
| TC-P05 | Positive | BC-BIZ-05/BC-REF-03 | Ctrl | Create attaches staff witness | ≥1 staff witness row | test_incident_14 | ✅ |
| TC-P06 | Positive | BC-BIZ-06 | Ctrl | Update persists mutable follow-up fields | intervention_notes + is_follow_up_required updated | test_incident_15 | ✅ |
| TC-P07 | Positive | BC-BIZ-07 | Ctrl/Screen-BR | Update blocks core field (description) change | description unchanged (BR-BA-008) | test_incident_16 | ✅ |
| TC-P08 | Positive | BC-BIZ-08 | Ctrl | Follow-up endpoint appends notes | follow_up_notes contains posted text | test_incident_17 | ✅ |
| TC-P09 | Positive | BC-BIZ-01 | Blade | Show page renders incident detail | "Incident Detail" visible | test_incident_18 | ✅ |
| TC-P10 | Positive | BC-BIZ-01 | Blade | incidents-page log tab lists incident | table/pagination renders | test_incident_19 | ✅ |

### Record lifecycle / state machine (Band 20–29)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-SM01 | State (legal) | BC-SM-02 | Ctrl | destroy() soft-deletes → Trashed | hidden default, visible withTrashed | test_incident_20 | ✅ |
| TC-SM02 | State (legal) | BC-SM-03 | Ctrl | restore() Trashed → Active | visible in default scope | test_incident_21 | ✅ |
| TC-SM03 | State (legal) | BC-SM-04/BC-REF-03 | Ctrl/DDL | forceDelete() → Purged; cascades witnesses | row gone; 0 witness rows | test_incident_22 | ✅ |
| TC-SM04 | Dependency (F) | BC-SM-01..05 | Ctrl | Full lifecycle create→delete→restore→force-delete | each stage passes | test_incident_23 | ✅ |
| TC-SM05 | State (lock) | BC-SM-06 | Ctrl/Screen-BR | Core field student_id locked after create | student_id unchanged (BR-BA-008) | test_incident_24 | ✅ |

### Negative / validation (Band 30–39)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Negative | BC-VAL-01/02/09 | Req | Empty required fields | 422 for student_id/incident_type/description | test_incident_30 | ✅ |
| TC-N02 | Negative | BC-VAL-01 | Req | student_id non-existent | 422 student_id | test_incident_31 | ✅ |
| TC-N03 | Negative | BC-VAL-02 | Req | incident_type not in enum | 422 incident_type | test_incident_32 | ✅ |
| TC-N04 | Negative | BC-VAL-03 | Req | severity missing for negative_incident | 422 severity (required_if) | test_incident_33 | ✅ |
| TC-N05 | Negative | BC-VAL-03 | Req | severity = 'High' (screen label, not enum) | 422 severity | test_incident_34 | ✅ |
| TC-N06 | Negative | BC-VAL-04 | Req | location not in enum ('rooftop') | 422 location | test_incident_35 | ✅ |
| TC-N07 | Negative | BC-VAL-05 | Req | future incident_date | 422 incident_date | test_incident_36 | ✅ |
| TC-N08 | Negative | BC-VAL-06 | Req | incident_time bad format ('25:99') | 422 incident_time | test_incident_37 | ✅ |
| TC-N09 | Negative | BC-VAL-07 | Req | follow_up_date before incident_date | 422 follow_up_date | test_incident_38 | ✅ |
| TC-N10 | Negative | BC-VAL-08 | Req | category_id non-existent (when provided) | 422 category_id | test_incident_39 | ✅ |

### Permissions / authorization (Band 50–59)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N11 | Negative | BC-AUTH-08 | mw | Guest → /login redirect | /login | test_incident_50 | ✅ |
| TC-N12 | Negative | BC-AUTH-02 | Ctrl | Limited user, no create perm | 401/403 | test_incident_51 | ✅ |
| TC-N13 | Negative | BC-AUTH-05 | Ctrl | Limited user, no delete perm | 401/403/419 | test_incident_52 | ✅ |
| TC-N14 | Negative | BC-AUTH-06 | Ctrl | Limited user, no force-delete perm | 401/403/419 | test_incident_53 | ✅ |
| TC-P11 | Positive | BC-AUTH-01..06 | Policy | Policy maps abilities to permission strings | viewAny/view/create/update/delete/restore/forceDelete present | test_incident_54 | ✅ |
| TC-S01 | Security | BC-VAL-10/BC-AUTH-09 | Req/Ctrl | FormRequest authorize() bare true; controller Gate compensates (SEC-BA-002) | pattern matches + Gate::authorize present | test_incident_55 | ✅ |

### UI / UX (Band 60–69)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P12 | Positive | BC-BIZ-01 | Blade | incidents-page filter by incident_type renders | stays on incidents-page | test_incident_60 | ✅ |
| TC-P13 | Positive | BC-DB-04 | Blade | incidents-page filter by severity=critical renders | stays on incidents-page | test_incident_61 | ✅ |
| TC-P14 | Positive | BC-SM-02 | Blade | Trash page renders | page/table renders | test_incident_62 | ✅ |
| TC-P15 | Positive | BC-BIZ-01 | Blade | Breadcrumb / detail heading on show page | "Incident Detail" visible | test_incident_63 | ✅ |

### Edge cases + requirement gaps (Band 70–79)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N15 | Negative | BC-EDG-01 | Ctrl | Invalid id → 404 | 403/404 | test_incident_70 | ✅ |
| TC-G01 | Gap proof | INC-GAP-01 | Screen-BR | 30-day-old incident_date accepted (7-day rule not enforced) | 200/302, row persists | test_incident_71 | ✅ |
| TC-G02 | Gap proof | INC-GAP-02 | Screen-VR | 5-char description accepted (Min 20 not enforced) | 200/302, row persists | test_incident_72 | ✅ |
| TC-G03 | Gap proof | INC-GAP-03 | Screen-VR | Null category accepted (Mandatory not enforced) | 200/302 | test_incident_73 | ✅ |
| TC-G04 | Gap proof | INC-GAP-04 | Screen-VR/DDL | severity enum = minor/moderate/major/critical, no 'info' label | enum matches; no screen label | test_incident_74 | ✅ |
| TC-G05 | Config | BC-DB-03 | DDL | incident_type enum matches live values | positive_reinforcement + negative_incident present | test_incident_75 | ✅ |

### Tenancy + security pack (Band 90–99) — incl. SEC-BA-001 safeguarding proof
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T01 | Tenancy | — | 05_ | Tenant context initialized | tenancy()->initialized | test_incident_90 | ✅ |
| TC-T02 | Tenancy | BC-INT-01 | 05_ | Cross-tenant direct-ID isolation (database-per-tenant) | exactly one row for id in this tenant | test_incident_91 | ✅ |
| TC-S02 | Security (P1) | BC-BIZ-09 | Audit | **SEC-BA-001:** critical incident — is_notified stays 0 (no parent/staff notify) | is_notified=false for critical | test_incident_92 | ✅ |
| TC-S03 | Security (P1) | BC-BIZ-09 | Audit | **SEC-BA-001 source proof:** no notify/dispatch/Mail/event() call sites in module | ZERO offenders (or skip if source absent) | test_incident_93 | ✅ |
| TC-S04 | Security | BC-EDG-02 | Blade | Stored XSS in description not executed on show | window flag not set | test_incident_94 | ✅ |

---

## 3. Test Method Index (semantic bands)
| # | Method(s) | TC Map | Category | Band |
|---|-----------|--------|----------|------|
| 1 | test_incident_01 | TC-CFG01 | Config truth | 01–09 |
| 2 | test_incident_02 | TC-CFG02 | Config / DOC-BA-001 | 01–09 |
| 3 | test_incident_03 | TC-CFG03 | Junction + audit config | 01–09 |
| 4–13 | test_incident_10..19 | TC-P01..P10 | Business rules | 10–19 |
| 14–18 | test_incident_20..24 | TC-SM01..SM05 | Record lifecycle / lock | 20–29 |
| 19–28 | test_incident_30..39 | TC-N01..N10 | Validation | 30–39 |
| 29–34 | test_incident_50..55 | TC-N11..N14, TC-P11, TC-S01 | Permissions | 50–59 |
| 35–38 | test_incident_60..63 | TC-P12..P15 | UI/UX | 60–69 |
| 39–43 | test_incident_70..75 | TC-N15, TC-G01..G05 | Edge / requirement gaps | 70–79 |
| 44–48 | test_incident_90..94 | TC-T01..T02, TC-S02..S04 | Tenancy / security | 90–99 |

**Total: 49 test methods** in one file.

## 4. Known Source Defects (audit-equivalent)
| ID | Sev | Summary | Proving method(s) | Status |
|----|-----|---------|-------------------|--------|
| SEC-BA-001 | P1 (safeguarding) | Severe-incident parent/staff notification (REQ-BA-015 / BR-BA-013) ENTIRELY ABSENT — store() never notifies, never reads `ba_config.parent_notification_threshold`; `is_notified` stays 0 even for `critical` | test_incident_92 (behaviour), test_incident_93 (source scan) | **Open** |
| SEC-BA-002 | P1 | FormRequest `authorize()` returns bare `true` (mitigated by controller `Gate::authorize`) | test_incident_55 | Documented |
| DOC-BA-001 | Doc | DDL-doc prefix `bha_` diverges from live `ba_` | test_incident_02 | Confirmed |
| INC-GAP-01 | Gap | "max 7 days from event" real-time-logging rule not enforced (only before_or_equal:today) | test_incident_71 | Open |
| INC-GAP-02 | Gap | description Min 20 / Max 1000 not enforced (only max:3000, no min) | test_incident_72 | Open |
| INC-GAP-03 | Gap | Category mandatory (screen) but category_id nullable in FormRequest | test_incident_73 | Open |
| INC-GAP-04 | Gap/Doc | severity labels Info/Low/Medium/High vs enum minor/moderate/major/critical | test_incident_34, test_incident_74 | Documented |
| INC-GAP-05 | Gap/Doc | positive incident_type value `positive_reinforcement` vs screen "Positive (Achievement)" | test_incident_11 | Documented |
