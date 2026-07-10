# Configuration — Manual Testing Specification

## 1. Feature Information

| Item | Value |
|------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | Configuration (`07-Configuration.md`) |
| Base URL | `{tenant}/behavioural-assessment` |
| List (setup tab) | `GET /behavioural-assessment/setup?tab=configuration` |
| Index (redirect) | `GET /behavioural-assessment/configs` → redirects to setup?tab=configuration |
| Create | `GET /behavioural-assessment/configs/create` |
| Store | `POST /behavioural-assessment/configs` |
| Show | `GET /behavioural-assessment/configs/{id}` |
| Edit | `GET /behavioural-assessment/configs/{id}/edit` |
| Update | `PUT /behavioural-assessment/configs/{id}` |
| Destroy (soft) | `DELETE /behavioural-assessment/configs/{id}` |
| Trash | `GET /behavioural-assessment/configs/trash` |
| Restore | `GET /behavioural-assessment/configs/{id}/restore` |
| Force delete | `DELETE /behavioural-assessment/configs/{id}/force-delete` |
| Toggle status | `POST /behavioural-assessment/configs/{config}/toggle-status` → JSON |
| Controller | `BaConfigController` (app alias for screen "Configuration") |
| FormRequest | `BaConfigRequest` (store + update) |
| Model | `BaConfig` (`ba_config`) |
| Service | none in write path; **`BehaviouralScoreService` READS the config** (scale binding + aggregation_method) |
| CRUD type | Config CRUD + toggle + soft/force-delete (one row per academic session) |
| Soft delete | Yes |
| Pagination | Setup config tab `paginate(15, page name 'cfg_page')`; trash `paginate(15)` |
| Activity log | **None for this feature** (flash messages only; toggle returns JSON) |
| Permissions | `tenant.behavioural-assessment.configs.{viewAny,view,create,update,delete,restore,forceDelete,status}` |

**Prerequisite:** module `BehaviouralAssessment` must be **enabled** in `prime_testing/modules_statuses.json` (currently `false` → all routes 404). See Validation Report §E.

**Prefix note (`DOC-BA-001`):** DDL doc says `bha_config`; **live table is `ba_config`**. All DB checks below use `ba_config`.

---

## 2. Business Conditions (detailed)

### Validation — `BaConfigRequest`
| Field | Rule | Failure behaviour |
|-------|------|-------------------|
| academic_session_id | required, integer, `exists:sch_org_academic_sessions_jnt,id`, **unique**(`ba_config.academic_session_id`) ignoring self, `whereNull(deleted_at)` | Re-render create/edit with `.alert-danger`; message `A configuration already exists for the selected academic session.` |
| rating_scale_id | required, integer, `exists:ba_rating_scales,id` | rejected if missing/invalid |
| weightage_percent | required, numeric, min:5, max:20 | rejected if < 5 or > 20 |
| aggregation_method | required, in `average` \| `weighted_average` \| `separate_display` | rejected if other |
| parent_notification_threshold | required, in `minor` \| `moderate` \| `major` \| `critical` | rejected if other |
| is_result_integration_enabled | nullable boolean (checkbox) | — |
| is_active | nullable boolean, default true | — |

### Status / flash flow
```
Create  → INSERT ba_config                         → flash "Configuration created successfully."
Update  → UPDATE ba_config                         → flash "Configuration updated successfully."
Destroy → set is_active=0 → soft delete (deleted_at) → flash "Configuration moved to trash."
Restore → deleted_at=NULL                           → flash "Configuration restored successfully."
Force   → DELETE row                                → flash "Configuration permanently deleted."
Toggle  → is_active = !is_active                    → JSON {success:true, is_active, message:"Configuration activated./deactivated."}
```

### Config consumption (integration — read path)
```
BehaviouralScoreService::computeForPeriod()
  → BaConfig::where('academic_session_id', period.academic_session_id)->where('is_active', true)->first()
  → $scale = $config?->ratingScale ?? BaRatingScale(is_default & is_active)      [DEFAULT-SCALE BINDING]
  → $aggregationMethod = $config?->aggregation_method ?? 'weighted_average'       [AGGREGATION RULE]
  ✗ weightage_percent                — NOT read anywhere (candidate CFG-BA-CFG-01)
  ✗ parent_notification_threshold    — NOT read by any incident/notification path (SEC-BA-001)
```

### Requirement rules NOT enforced in code (documented gaps — see §3 tests)
- **BR-BA-029 / Scale Integrity Constraint** — active rating scale must lock once ratings exist; **no guard**, dropdown never disabled (DATA-BA-001).
- **REQ-BA-015** — `parent_notification_threshold` should trigger a severe-incident parent notification; **never consumed** (SEC-BA-001 / BUG-BA-003).
- **FormRequest `authorize()`** returns bare `true` (SEC-BA-002).
- **Soft-delete + `uq_ba_config_session`** (no `deleted_at`) → recreate-after-delete integrity error (DATA-BA-003).
- **Screen fields** "Approval Workflow" + "Incident Escalation Threshold" — **not implemented** on `ba_config` (requirement divergence, REQ-BA-CFG-01).

---

## 3. Test Cases (step / action / expected)

### TC-P11 — Create a valid configuration
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; visit `/behavioural-assessment/configs/create` | "Academic Context" + "Rules" sections render; "Save Configuration" present |
| 2 | Select an Academic Session with no existing config; select a Rating Scale | dropdowns accept selection |
| 3 | Set Weightage `12`, Aggregation `Simple Average`, Threshold `Major`; click **Save Configuration** | redirect to setup?tab=configuration, flash `Configuration created successfully.` |
| 4 | DB check | `SELECT rating_scale_id, aggregation_method FROM ba_config WHERE academic_session_id=?` → matches input |

### TC-P13 — Edit an existing configuration
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open an existing config's `/edit` | form pre-filled, "Update Configuration" present |
| 2 | Change Weightage to `15`; click **Update Configuration** | flash `Configuration updated successfully.` |
| 3 | DB check | `SELECT weightage_percent FROM ba_config WHERE id=?` → `15.0` |

### TC-SM01 — Toggle status
| Step | Action | Expected |
|------|--------|----------|
| 1 | Setup config tab, click `.status-toggle[data-id={id}]` switch | AJAX POST toggle-status |
| 2 | DB check | `SELECT is_active FROM ba_config WHERE id=?` → flipped |
| 3 | Response | JSON `{"success":true,"is_active":false,"message":"Configuration deactivated."}` |

### TC-D01 — Soft-delete → restore → force-delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a config (action column) | flash `Configuration moved to trash.`; `deleted_at` set, `is_active=0` |
| 2 | Trash page, Restore | flash `Configuration restored successfully.`; `deleted_at` NULL |
| 3 | Delete again, then Force delete | flash `Configuration permanently deleted.`; row gone |

### TC-N10 — Duplicate session config
| Step | Action | Expected |
|------|--------|----------|
| 1 | Config already exists for session X | — |
| 2 | Create another config selecting session X; Save | `.alert-danger` with `A configuration already exists for the selected academic session.`; no new row |

### TC-N32/N33 — Weightage out of range
| TC | Action | Expected |
|----|--------|----------|
| N32 | Weightage = 4 (min is 5) | rejected; `.alert-danger`; no row |
| N33 | Weightage = 25 (max is 20) | rejected; `.alert-danger`; no row |

### TC-N34/N35 — Enum validation
| TC | Action | Expected |
|----|--------|----------|
| N34 | aggregation_method injected out-of-enum (`median`) | rejected; no row |
| N35 | parent_notification_threshold injected out-of-enum (`extreme`) | rejected; no row |

### TC-N36/N37 — FK integrity
| TC | Action | Expected |
|----|--------|----------|
| N36 | Insert config with rating_scale_id `999999999` | DB FK error (23000) |
| N37 | Insert config with academic_session_id `65000` (nonexistent) | DB FK error (23000) |

### TC-D10 — DATA-BA-003 (soft-delete + unique session) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Create config for session X | inserted |
| 2 | Delete config (soft) | row hidden but `deleted_at` set, still occupies (session X) in `uq_ba_config_session` |
| 3 | Create another config for session X | **Integrity error (SQLSTATE 23000 / duplicate)** → 500 through controller (FormRequest unique passes because it is scoped to `whereNull(deleted_at)`) |

### TC-N41 — DATA-BA-001 (mid-session scale switch not guarded) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Requirement: once ratings exist for the session, the Active Rating Scale dropdown must lock (BR-BA-029) | — |
| 2 | Inspect `BaConfigController@update` | no `ba_assessment_ratings` check before applying change |
| 3 | Inspect `config/edit.blade.php` rating_scale_id `<select>` | no `disabled` attribute — dropdown never locked |
| 4 | Switch a config's `rating_scale_id` to another active scale | succeeds unconditionally |

### TC-N42 — SEC-BA-001 (threshold never consumed) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Config stores `parent_notification_threshold` (validated in:minor,moderate,major,critical) | value persisted |
| 2 | Inspect `BaIncidentController` | **no reference** to `parent_notification_threshold` |
| 3 | Search module for a notification consumer | none — no Notification class; incident flow uses a manual `is_notified` flag only. REQ-BA-015 severe-incident parent notification is absent |

### TC-N43/N44 — candidates (verify in source)
| TC | Action | Expected |
|----|--------|----------|
| N43 | Inspect `BehaviouralScoreService` | no reference to `weightage_percent` → the "% contribution to final result" value is stored but not consumed |
| N44 | Inspect `ba_config` schema vs screen | `approval_workflow` + `incident_escalation_threshold` columns absent (screen fields not implemented) |

### TC-N40 — SEC-BA-002 (authorize() bare true) — proof
| Step | Action | Expected |
|------|--------|----------|
| 1 | `new BaConfigRequest()->authorize()` | returns `true` |
| 2 | Controller | still enforces `Gate::authorize('tenant.behavioural-assessment.configs.*')` (defence-in-depth in controller) |

### TC-S01/S02 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout; visit create/setup paths | redirect to `/login` |

### TC-S04 — Limited user forbidden
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as user without `configs.create` | visiting create → 403 / no "Save Configuration" form |

### TC-S06 — Invalid id 404
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/configs/98765432` | `findOrFail` → 404; "Assessment Configuration Details" not shown |

### TC-CFG01/CFG02 — Config consumed by scoring
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `BehaviouralScoreService` | `$config?->ratingScale` binds the scoring scale (fallback `is_default` scale) |
| 2 | Inspect overall-score computation | `match($aggregationMethod)` selects `average`/`weighted_average`/`separate_display` |

### TC-T01 — Tenant isolation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenancy initialized | `ba_config` resolves in tenant DB; no `tenant_id` column (DB-per-tenant) |
