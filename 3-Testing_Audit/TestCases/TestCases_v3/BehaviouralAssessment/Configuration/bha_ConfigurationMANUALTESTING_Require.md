# bha_ Configuration — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | Configuration (Setup › Configuration tab) — screen `07-Configuration*`, app alias `configs` |
| URL prefix | `/behavioural-assessment` (name prefix `behavioural-assessment.`) |
| Setup tab (list) | `GET /behavioural-assessment/setup?tab=configuration` |
| Index URL | `GET /behavioural-assessment/configs` → **redirects** to `setup?tab=configuration` |
| Create URL | `GET /behavioural-assessment/configs/create` |
| Store URL | `POST /behavioural-assessment/configs` |
| Show URL | `GET /behavioural-assessment/configs/{id}` |
| Edit URL | `GET /behavioural-assessment/configs/{id}/edit` |
| Update URL | `PUT /behavioural-assessment/configs/{id}` |
| Delete URL | `DELETE /behavioural-assessment/configs/{id}` |
| Trash URL | `GET /behavioural-assessment/configs/trash` |
| Restore URL | `GET /behavioural-assessment/configs/{id}/restore` (**GET**) |
| Force Delete URL | `DELETE /behavioural-assessment/configs/{id}/force-delete` |
| Toggle Status | `POST /behavioural-assessment/configs/{id}/toggle-status` (JSON) |
| Controller | `Modules\BehaviouralAssessment\Http\Controllers\BaConfigController` |
| FormRequest | `Modules\BehaviouralAssessment\Http\Requests\BaConfigRequest` |
| Model | `Modules\BehaviouralAssessment\Models\BaConfig` (SoftDeletes) |
| Policy | `Modules\BehaviouralAssessment\Policies\BaConfigPolicy` |
| Primary table | **`ba_config`** (live `ba_` prefix — DDL-doc `bha_config` is stale → DOC-BA-001) |
| Migration | `database/migrations/tenant/2026_06_16_130621_create_ba_config_table.php` |
| CRUD type | Full CRUD + trash/restore/forceDelete + JSON status toggle |
| Soft delete | Yes (`deleted_at`); `destroy()` sets `is_active=false` before soft delete |
| Pagination | Setup tab + trash list (server-side) |
| Activity log | **NONE** — controller writes no `activityLog()`; model has no observer (documented absence → test_93) |

### Prerequisites
- At least one row in `sch_org_academic_sessions_jnt` (academic session) with **no existing** `ba_config` (unconditional unique index `uq_ba_config_session`).
- At least one `ba_rating_scales` row (or the suite seeds one).
- An admin user with all `tenant.behavioural-assessment.configs.*` + `setup.viewAny` permissions.
- Module `BehaviouralAssessment` enabled in `prime_testing/modules_statuses.json` (disabled → 404 on all routes — see Validation Report E-prereq).
- `APP_ENV=testing`, Chrome + Dusk driver, `DUSK_TENANT_URL`/`DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`.

---

## 2. Business Conditions (detailed)

### Flash / toast strings (assert exact)
| Action | Verb | Message |
|--------|------|---------|
| Create | POST store | `Configuration created successfully.` |
| Update | PUT | `Configuration updated successfully.` |
| Delete | DELETE | `Configuration moved to trash.` |
| Restore | GET | `Configuration restored successfully.` |
| Force delete | DELETE | `Configuration permanently deleted.` |
| Toggle → off | POST toggle-status | JSON `message` = `Configuration deactivated.` |
| Toggle → on | POST toggle-status | JSON `message` = `Configuration activated.` |
| Scale-lock reject | PUT (DATA-BA-001) | `Cannot change rating scale because ratings have already been recorded for this academic session.` |
| Duplicate session | POST/PUT | `A configuration already exists for the selected academic session.` |

### Activity-log events
```
NONE. BaConfigController calls no activityLog() helper and BaConfig has no observer.
This is a DELIBERATE documented absence (test_93 asserts activityLog(/ActivityLog::create are NOT present).
```

### Validation rules (BaConfigRequest)
```
academic_session_id  required | exists:sch_org_academic_sessions_jnt,id
                              | Rule::unique('ba_config','academic_session_id')->whereNull('deleted_at')
rating_scale_id      required | exists:ba_rating_scales,id
weightage_percent    required | numeric | min:5 | max:20        (column DECIMAL(4,1))
aggregation_method   required | in:average,weighted_average,separate_display
parent_notification_threshold required | in:minor,moderate,major,critical
is_result_integration_enabled  (prepareForValidation → boolean; omitted → false)
is_active            (prepareForValidation → default true when omitted)

Custom message:
  academic_session_id.unique → "A configuration already exists for the selected academic session."

authorize(): return true;   (bare true — SEC-BA-002; controller Gate::authorize is the real guard)
```

### State machine
```
is_active toggle:   Active --toggle-status--> Inactive --toggle-status--> Active

DATA-BA-001 rating-scale lock (fix VERIFIED PRESENT):
  update():   if (int)$validated['rating_scale_id'] !== $config->rating_scale_id
                 AND BaAssessmentRating::whereHas(... session ...)->exists()
              => back()->withInput() + error "Cannot change rating scale because ratings have already been recorded..."
  edit.blade: rating_scale dropdown carries @disabled($hasRatings) + "Locked" notice.
  Ratings chain: ba_assessment_ratings → ba_assessments → ba_assessment_periods (academic_session_id)
```

### DATA-BA-003 (soft-delete reuse anomaly)
```
uq_ba_config_session  = UNIQUE(academic_session_id)  — UNCONDITIONAL (counts soft-deleted rows)
FormRequest unique    = whereNull(deleted_at)         — ignores soft-deleted rows
Effect: after soft-deleting a config, re-creating for the SAME session passes FormRequest but the DB INSERT is blocked.
```

### SEC-BA-001 (dead config)
```
parent_notification_threshold persists (minor/moderate/major/critical) but NO controller/service
reads it to dispatch a notification on a severe incident — configured-but-unused. UNRESOLVED.
```

---

## 3. Test Cases (step-by-step)

> DB checks use the live table `ba_config`. JSON status codes are captured via an authenticated browser `fetch` (`sendJsonRequestFromBrowser`), never Dusk `assertStatus`.

### TC-P01 / test_01 — Schema, model & request config truth
| Step | Action | Expected |
|------|--------|----------|
| 1 | `Schema::hasTable('ba_config')` | true |
| 2 | `Schema::hasColumns` for the 13 columns | true |
| 3 | SHOW COLUMNS types (mysql) | weightage `decimal`, aggregation `enum`, threshold `enum`, is_active `tinyint` |
| 4 | Read migration file content | contains `Schema::create('ba_config'`, `decimal('weightage_percent',4,1)`, both `enum(...)`, `unique('academic_session_id','uq_ba_config_session')`, `softDeletes()` |
| 5 | Model `getTable()`/`getFillable()`/SoftDeletes/relations/active scope | all match | 
| DB | `SELECT * FROM ba_config WHERE id=<seed>` | is_active bool, weightage `10.0` |

### TC-P02 / test_02 — Runtime prefix DOC-BA-001
| Step | Action | Expected |
|------|--------|----------|
| 1 | `Schema::hasTable('ba_config')` | true |
| 2 | `Schema::hasTable('bha_config')` | false (stale doc name absent) |
| 3 | `(new BaConfig)->getTable()` | `ba_config` |

### TC-P03 / test_03 — FormRequest rule/message strings
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `BaConfigRequest.php` | contains `exists:sch_org_academic_sessions_jnt,id`, `Rule::unique('ba_config','academic_session_id')`, `whereNull('deleted_at')`, `exists:ba_rating_scales,id`, `'min:5','max:20'`, `in:average,weighted_average,separate_display`, `in:minor,moderate,major,critical`, duplicate-session message |

### TC-P04 / test_10 — Create persists + success flash
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST valid payload (session + fresh scale, weightage 12.5, weighted_average, moderate, integration on) | not 422 |
| 2 | `SELECT ... WHERE academic_session_id=<id> ORDER BY id DESC` | row exists |
| 3 | Assert fields | rating_scale matches, weightage `12.5`, integration true, created_by = updated_by = admin id |

### TC-P05 / test_11 — Update persists changes
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed config (weightage 8, average) | seeded |
| 2 | PUT (weightage 15, separate_display, major, integration on) | not 422 |
| 3 | Refresh row | weightage `15.0`, method `separate_display`, threshold `major`, updated_by = admin |

### TC-P06 / test_12 — Cast correctness
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed (weightage 7.5, integration true, is_active false) | seeded |
| 2 | Refresh | weightage `7.5`, integration `true` (bool), is_active `false` (bool) |

### TC-P07 / test_13 — Show page renders
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/configs/{id}` authenticated | page loads |
| 2 | Assert text | "Assessment Configuration Details", "Weightage %", "Parent Alert Notification" |

### TC-P08 / test_14 — Setup tab lists configs
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open `setup?tab=configuration` | tab renders |
| 2 | Assert text | "Academic Session", "Weightage" |

### TC-P09 / test_15 — index redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/configs` | status 200 or 302 (redirect to setup tab) |

### TC-P10 / test_20 — Active↔Inactive
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed active config | is_active true |
| 2 | POST toggle-status | 200; is_active false |
| 3 | POST toggle-status again | 200; is_active true |

### TC-P11 / test_21 — Scale change allowed, no ratings (DATA-BA-001 permissive)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed config; create new scale | seeded |
| 2 | If `ba_assessment_ratings` exists & session has ratings | skip (permissive branch not exercisable) |
| 3 | PUT with new rating_scale_id | not 422 |
| 4 | Refresh | rating_scale_id == new scale |

### TC-P12 / test_22 — Guard + lock present (DATA-BA-001)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read `BaConfigController.php` | contains `BaAssessmentRating::whereHas`, `(int)$validated['rating_scale_id'] !== $config->rating_scale_id`, scale-lock error string |
| 2 | Read `config/edit.blade.php` | contains `@disabled($hasRatings)` and "Locked" |

### TC-N17 / test_23 — Scale change rejected when ratings exist (DATA-BA-001 blocking)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed config; require ratings for session | else skip (guard verified in test_22) |
| 2 | PUT with new scale | update returns back()->withInput() (redirect) |
| 3 | Refresh | rating_scale_id UNCHANGED |

### TC-N01..N10 / test_30–39 — Validation matrix
| Method | Action | Expected |
|--------|--------|----------|
| test_30 | Empty payload | 422; errors for all 5 required fields |
| test_31 | weightage 4 | 422; weightage error |
| test_32 | weightage 21 | 422; weightage error |
| test_33 | weightage 'abc' | 422; weightage error |
| test_34 | aggregation_method 'median' | 422; aggregation_method error |
| test_35 | parent_notification_threshold 'disabled' | 422; threshold error |
| test_36 | academic_session_id 987654321 | 422; session error |
| test_37 | rating_scale_id 987654321 | 422; scale error |
| test_38 | Duplicate config for existing session | 422; `A configuration already exists...` |
| test_39 | Omit is_result_integration_enabled on update | not 422; stored false |

### TC-D01..D07 / test_40–46 — Integration / lifecycle
| Method | Action | Expected |
|--------|--------|----------|
| test_40 | DELETE config | 200/302; hidden from default scope; onlyTrashed present; is_active false |
| test_41 | soft-delete then GET restore | 200/302; back in default scope |
| test_42 | soft-delete then DELETE force-delete | 200/302; withTrashed absent |
| test_43 | Inspect FK ba_config→sch_org_academic_sessions_jnt | DELETE_RULE RESTRICT/NO ACTION (skip if no metadata) |
| test_44 | Inspect FK ba_config→ba_rating_scales | DELETE_RULE RESTRICT/NO ACTION (skip if no metadata) |
| test_45 | Soft-delete config, re-POST same session (DATA-BA-003) | new active config NOT creatable while unconditional unique index remains |
| test_46 | create→toggle→delete→restore→force-delete | each stage asserted; row gone at end |

### TC-N12..N15, TC-S03, TC-P13 / test_50–55 — Permissions
| Method | Action | Expected |
|--------|--------|----------|
| test_50 | Guest visits create (cookies cleared) | redirected to `/login` |
| test_51 | Limited user POST store | 403 |
| test_52 | Limited user POST toggle-status | 403 |
| test_53 | Limited user DELETE destroy | 403 |
| test_54 | Read `BaConfigPolicy.php` | 8 gate strings `tenant.behavioural-assessment.configs.{ability}` present |
| test_55 | Admin toggle | 200; JSON `{success:true, is_active, message}`; `Configuration deactivated.` then `Configuration activated.` |

### TC-P18/P19/P20, TC-N16 / test_60–63 — UI/UX
| Method | Action | Expected |
|--------|--------|----------|
| test_60 | Open setup tab | search placeholder "Search by session or rating scale" |
| test_61 | Open setup tab with non-matching search | "No configurations found." |
| test_62 | Soft-delete config, visit trash | "Academic Session", "Deleted At" |
| test_63 | Open create + show | breadcrumb "Configuration" / "Configuration Details" |

### TC-N11, TC-P14, TC-P15 / test_70–72 — Edge
| Method | Action | Expected |
|--------|--------|----------|
| test_70 | GET show/edit + toggle on id 987654321 | 404 ×3 |
| test_71 | PUT weightage 5 and 20 | not 422 (boundaries accepted) |
| test_72 | POST omitting is_active | stored is_active true |

### TC-P16, TC-S02, TC-S04, TC-P17 / test_80–83 — Config behaviour
| Method | Action | Expected |
|--------|--------|----------|
| test_80 | Seed each threshold minor/moderate/major/critical | each persists |
| test_81 | Scan BaIncidentController + BehaviouralScoreService | NO `parent_notification_threshold` read, NO Notification/Mail dispatch (SEC-BA-001 unresolved) |
| test_82 | Column checks | approval_workflow / incident_escalation_threshold / escalation_threshold ABSENT; weightage_percent/aggregation_method/parent_notification_threshold/is_result_integration_enabled PRESENT (CFG-BA-001) |
| test_83 | Seed integration on, separate_display, 18.0 | all persist |

### TC-T01, TC-T02, TC-S01, TC-S05 / test_90–93 — Tenancy & security
| Method | Action | Expected |
|--------|--------|----------|
| test_90 | Check tenancy init | initialized; `ba_config` has NO `tenant_id` column (DB-per-tenant) |
| test_91 | Find a second tenant domain | second tenant asserted (skip if single tenant) |
| test_92 | Read `BaConfigRequest.php` | `authorize()` returns bare `true` (SEC-BA-002) |
| test_93 | Read `BaConfigController.php` | NO `activityLog(` and NO `ActivityLog::create` |
