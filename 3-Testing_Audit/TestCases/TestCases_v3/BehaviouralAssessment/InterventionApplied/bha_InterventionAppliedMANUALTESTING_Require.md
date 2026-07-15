# Interventions Applied — Manual Testing Guide

**Module:** BehaviouralAssessment  •  **Feature:** InterventionApplied (screen `14-Interventions-Applied`)

---

## 1. Feature Information

| Attribute | Value |
|-----------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | Interventions Applied (incident ↔ intervention junction) |
| Standalone read-only URL | `/behavioural-assessment/incidents-page?tab=interventions-applied` |
| Mutation endpoints | `POST /behavioural-assessment/incidents/{incident}/interventions` (add), `DELETE /behavioural-assessment/incidents/{incident}/interventions/{jnt}` (remove) |
| Bulk-attach endpoints | `POST /behavioural-assessment/incidents` (store), `PUT /behavioural-assessment/incidents/{incident}` (update) |
| Route names | `behavioural-assessment.incidents.interventions.add`, `...interventions.remove` |
| Controller | `BaIncidentController` (`addIntervention`, `removeIntervention`, `store`, `update`); read-only tab via `BaDashboardController::incidentsPage()` |
| Models | `BaIncidentInterventionJnt`, `BaIncident`, `BaIntervention` |
| Primary table | `ba_incident_intervention_jnt` (live `ba_` prefix; DDL doc uses stale `bha_`) |
| Validation | `addIntervention()` inline rules; bulk via `BaIncidentRequest` (`interventions.*` rules) |
| Migration | `database/migrations/tenant/2026_06_16_130626_create_ba_incident_intervention_jnt_table.php` |
| CRUD type | Junction link/unlink (no dedicated CRUD screen — managed inside the incident flow) |
| Soft delete | Migration adds `deleted_at`, but the model has **no** `SoftDeletes` trait → `->delete()` HARD-deletes (DATA-BA-IA-01) |
| Pagination | Standalone tab uses a dedicated `ia_page` paginator |
| Activity log | **NONE** on junction mutations — `addIntervention()`/`removeIntervention()` call no `activityLog()`/`BaAuditLog` (documented absence) |
| Permission prefix | `tenant.behavioural-assessment.incidents.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete\|status}`; standalone tab: `...incidents-page.viewAny` |
| DB scope | TENANT-side (`tenant_db`, database-per-tenant) |

---

## 2. Business Conditions (detailed)

**Link (add):** `addIntervention()` authorizes `tenant.behavioural-assessment.incidents.update`, `findOrFail`s the incident, validates `intervention_id` (required|integer|exists:ba_interventions,id) + `notes` (nullable|max:500), then `firstOrCreate` on `(incident_id, intervention_id)` stamping `created_by`/`updated_by` from `auth()->id()` and `is_active=1`. Idempotent — a repeat add does not duplicate and does not overwrite the original notes.

**Unlink (remove):** `removeIntervention()` authorizes the SAME `incidents.update` gate and deletes by junction id. Because the model lacks `SoftDeletes`, the row is physically removed. Removing an unknown junction id deletes 0 rows and still redirects back (no-op).

**Bulk attach / re-sync:** incident `store()`/`update()` accept `interventions[]` validated by `BaIncidentRequest` (`array|distinct`, each `exists:ba_interventions,id`). `update()` re-syncs by forceDelete + recreate.

**Referential flow:**
```
ba_incidents ──(incident_id, CASCADE)──► ba_incident_intervention_jnt ◄──(intervention_id, RESTRICT)── ba_interventions
   force delete incident  ─────────────► junction rows removed (DB cascade)
   soft delete incident   ─────────────► junction rows survive (Eloquent, FK not fired)
   raw delete intervention ────────────► BLOCKED by RESTRICT (throws)
   BaIntervention::forceDelete() ──────► observer detaches junction first (INT-OBS-01) then deletes
```

**Requirement gap (VAL-BA-IA-01):** Screen 14 specifies an intervention lifecycle — Status (Assigned/In Progress/Completed/Cancelled), Scheduled Date, Assigned-To Staff, Completion Date, Progress Notes(1000). NONE are implemented; the junction only has `notes(500)` + `is_active`. `is_active` has no toggle endpoint (INFO-BA-IA-02).

**Error messages (validation):** standard Laravel — required (`The intervention id field is required.`), exists (`The selected intervention id is invalid.`), integer (`The intervention id field must be an integer.`), max (`The notes field must not be greater than 500 characters.`). Tests assert on the 422 status + `errors.{field}` key (message text may vary by locale).

---

## 3. Test Cases (step-by-step)

### TC-C01 — Configuration truth (test_ia_01)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect schema | `ba_incident_intervention_jnt` exists with all 10 columns |
| 2 | `SHOW COLUMNS` / `SHOW INDEX` | `incident_id`/`intervention_id` bigint, `notes` varchar, `is_active` tinyint; UNIQUE index over `(incident_id, intervention_id)` |
| 3 | Read migration file | Contains `Schema::create('ba_incident_intervention_jnt'`, `notes,500`, cascadeOnDelete `ba_incidents`, constrained `ba_interventions`, `uq_ba_inc_int`, `softDeletes()` |
| 4 | Read `BaIncidentRequest` | Contains `'interventions'`, `'distinct'`, `exists:ba_interventions,id` |
| 5 | Inspect model | table = `ba_incident_intervention_jnt`; fillable = 6 fields; `is_active` cast boolean; `incident()`/`intervention()` BelongsTo with correct FKs |

### TC-C02 — Prefix divergence (test_ia_02) — DOC-BA-001
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Schema::hasTable('ba_incident_intervention_jnt')` | true |
| 2 | `Schema::hasTable('bha_incident_intervention_jnt')` | false (DDL-doc name absent at runtime) |
| 3 | Model `getTable()` | returns `ba_incident_intervention_jnt` |

### TC-C03 — Dead soft-delete column (test_ia_03) — DATA-BA-IA-01
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check `deleted_at` column | exists |
| 2 | `class_uses_recursive(BaIncidentInterventionJnt)` | does NOT contain `SoftDeletes` |
| 3 | Link a junction row, call `->delete()` | `SELECT count(*) WHERE id=jntId` = 0 (hard delete) |

### TC-P01 — add links + persists (test_ia_10)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST add with `intervention_id` + notes | 200/302 |
| 2 | `SELECT * FROM ba_incident_intervention_jnt WHERE incident_id=? AND intervention_id=?` | row exists; notes match; `is_active=1`; `created_by`=`updated_by`=admin id |

### TC-P02 — notes persist (test_ia_11)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST add with a specific notes string | Row `notes` = that string verbatim |

### TC-P03 — store bulk-attach (test_ia_12)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST incident store with `interventions=[id]` | 200/302; incident created |
| 2 | Query junction for that incident | 1 row for the selected intervention |

### TC-P04 — update re-sync (test_ia_13)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed link A, PUT incident with `interventions=[B]` | 200/302 |
| 2 | Query junction intervention_ids | contains B |

### TC-P05 — tab list (test_ia_14)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Link a row, open interventions-applied tab | Intervention `name` visible |

### TC-P06 — idempotent (test_ia_15)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST add same pair twice | `count(*)` for the pair = 1 |

### TC-P07 — notes optional (test_ia_16)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST add without notes | 200/302; row `notes` = null |

### TC-P08 — created_by/updated_by from auth (test_ia_17)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST add, inspect row | both = admin id |

### TC-G01 — lifecycle not implemented (test_ia_20) — VAL-BA-IA-01
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check columns `status/scheduled_date/assigned_to/completion_date/progress_notes` | none exist |
| 2 | Inspect `notes` type | varchar(500), not specced 1000 |

### TC-G02 — no toggle endpoint (test_ia_21) — INFO-BA-IA-02
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check `is_active` column | exists |
| 2 | Read `routes/web.php` | `interventions.add` + `interventions.remove` present; `interventions.toggle` absent |

### TC-N01..N06 — Validation negatives (test_ia_30–35)
| TC | Action | Expected Result |
|----|--------|-----------------|
| N01 | POST add with no `intervention_id` | 422, `errors.intervention_id` |
| N02 | POST add `intervention_id=987654321` | 422, `errors.intervention_id` (exists) |
| N03 | POST add `intervention_id='not-an-int'` | 422, `errors.intervention_id` |
| N04 | POST add notes = 501 chars | 422, `errors.notes` |
| N05 | POST store `interventions=[987654321]` | 422, `interventions.0`/`interventions` |
| N06 | POST store `interventions=[id,id]` (dup) | 422 (distinct) |

### TC-D01..D06 — FK / referential (test_ia_40–45)
| TC | Action | Expected Result |
|----|--------|-----------------|
| D01 | Inspect FK `intervention_id` DELETE_RULE | RESTRICT / NO ACTION |
| D02 | Inspect FK `incident_id` DELETE_RULE | CASCADE |
| D03 | Link row, force-delete incident | junction rows removed |
| D04 | Link row, soft-delete incident | junction rows survive |
| D05 | Link row, raw `DELETE FROM ba_interventions WHERE id=?` | throws (RESTRICT) |
| D06 | Link pair, raw-insert same pair | throws (uq_ba_inc_int) |

### TC-P09 — remove hard-deletes (test_ia_46)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Link row, DELETE remove | 200/302; `count(*) WHERE id=jntId` = 0 |

### TC-P10 — full lifecycle (test_ia_47)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | add | row present |
| 2 | open tab | intervention name visible |
| 3 | remove | row gone |

### TC-A01..A06 — Authorization (test_ia_50–55)
| TC | Action | Expected Result |
|----|--------|-----------------|
| A01 | Visit tab as guest (cookies cleared) | redirected to `/login` |
| A02 | Limited user POST add | 403 |
| A03 | Limited user DELETE remove | 403 |
| A04 | Limited user GET tab | 403 |
| A05 | Read `BaIncidentPolicy` | 8 abilities map to `tenant.behavioural-assessment.incidents.*` |
| A06 | Read controller | `addIntervention`/`removeIntervention` present; `Gate::authorize('tenant.behavioural-assessment.incidents.update')` present |

### TC-U01..U05 — UI/UX (test_ia_60–64)
| TC | Action | Expected Result |
|----|--------|-----------------|
| U01 | Tab `&search={studentName}` | intervention name visible |
| U02 | Tab `&intervention_type_filter={type}` | intervention name visible |
| U03 | Tab `&search=ZZZ_NO_MATCH_*` | "No interventions applied yet." |
| U04 | Open tab | "Interventions are applied from within individual incident records." |
| U05 | Tab `&ia_page=2` | second page renders, path still `/incidents-page` |

### TC-E01..E04 — Edge cases (test_ia_70–73)
| TC | Action | Expected Result |
|----|--------|-----------------|
| E01 | POST add on incident `987654321` | 404 |
| E02 | DELETE remove on incident `987654321` | 404 |
| E03 | Link real row, DELETE remove unknown jnt id | 200/302; genuine row untouched (count=1) |
| E04 | POST add notes=500 then notes=501 | 200/302 then 422 |

### TC-P11 — no overwrite of notes (test_ia_74)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | add notes='ORIGINAL', then add notes='OVERWRITE_ATTEMPT' | row notes stays 'ORIGINAL' |

### TC-T01..T02, TC-S01..S03 — Tenancy + Security (test_ia_90–94)
| TC | Action | Expected Result |
|----|--------|-----------------|
| T01 | Check tenant context | `tenancy()->initialized` true; table present |
| T02 | Resolve a second tenant domain | second tenant exists (or skip if single-tenant) |
| S01 | add with `created_by=999999`, `id=555555` in payload | row `created_by`=admin; `id` auto-increment (not 555555) |
| S02 | link notes with `<img src=x onerror=alert(1)>`, open tab | raw markup NOT in page source (Blade escaped) |
| S03 | Read `BaIncidentRequest::authorize()` | matches `return true;` (SEC-BA-002) |

---

## Prerequisites (manual run)
- BehaviouralAssessment module enabled in `modules_statuses.json`.
- Tenant reachable at `DUSK_TENANT_URL`; admin login `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`.
- At least one `ba_incidents` row (or a resolvable `std_students` + `sch_employees` pair to seed one) and one active `ba_interventions` row.
