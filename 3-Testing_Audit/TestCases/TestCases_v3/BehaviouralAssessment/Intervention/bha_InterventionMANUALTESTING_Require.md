# Interventions — Manual Testing Specification (`bha_InterventionMANUALTESTING_Require.md`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment (BHA) |
| Feature / Screen | Intervention (masters tab — screen `04-Interventions*`) |
| Masters URL | `/behavioural-assessment/masters?tab=interventions` |
| Create URL | `/behavioural-assessment/interventions/create` |
| Store URL | `POST /behavioural-assessment/interventions` |
| Show URL | `GET /behavioural-assessment/interventions/{id}` |
| Update URL | `PUT /behavioural-assessment/interventions/{id}` |
| Toggle URL | `POST /behavioural-assessment/interventions/{id}/toggle-status` |
| Delete URL | `DELETE /behavioural-assessment/interventions/{id}` |
| Restore URL | `GET /behavioural-assessment/interventions/{id}/restore` |
| Force-delete URL | `DELETE /behavioural-assessment/interventions/{id}/force-delete` |
| Trash URL | `GET /behavioural-assessment/interventions/trash` |
| Controller | `BaInterventionController` |
| FormRequest | `BaInterventionRequest` |
| Model | `BaIntervention` (table `ba_interventions`) |
| Policy | `BaInterventionPolicy` |
| Junction | `ba_incident_intervention_jnt` (`intervention_id` → `ba_interventions`, `ON DELETE RESTRICT`) |
| CRUD type | Full CRUD master |
| Soft delete | Yes (`deleted_at`; `destroy()` also sets `is_active=false`) |
| Pagination | Masters list paginated (server-side) |
| Activity log | NONE for this feature (no `activityLog()` call, no logging observer) — do not expect a log row |
| Permissions | `tenant.behavioural-assessment.interventions.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete\|status}` |
| DB scope | TENANT-side (`tenant_db`) — must be run inside an initialized tenant context |

### Prerequisites
- BehaviouralAssessment module **enabled** in `prime_testing/modules_statuses.json` (disabled → 404 on every route).
- `APP_ENV=testing` (Dusk bypasses CSRF; otherwise state-changing requests get 419).
- A tenant domain resolvable from `DUSK_TENANT_URL` (`http://test.localhost:8000`) with an admin (`root@tenant.com` / `password`).
- A valid `glb_languages` row for the `prefered_language` FK when creating limited users.

---

## 2. Business Conditions (detailed)

### Validation (from `BaInterventionRequest`)
| Field | Rule | Error behaviour |
|-------|------|-----------------|
| `name` | required, `max:100` | 422 with `errors.name` when empty or > 100 chars; whitespace-only is trimmed → required fails |
| `intervention_type` | required, `Rule::in(['reward','corrective','counselling'])` | 422 with `errors.intervention_type` for any other value (incl. requirement labels Supportive/Reinforcement — **INT-GAP-02**) |
| `sort_order` | required, integer, `min:0`, `max:255`, unique on `ba_interventions.sort_order` scoped `whereNull(deleted_at)` | 422 with `errors.sort_order`; duplicate message is exactly `This sort order is already used by another intervention.` |
| `description` | nullable, no max (**VAL-BA-003** — requirement wanted required max:500) | Omitted value accepted; persists `null` |
| `is_active` | defaulted to `true` in `prepareForValidation()` when absent | Created row is active by default |

### State machine (Active ↔ Inactive)
```
   Active  --toggle-status-->  Inactive     (message: "Intervention deactivated.")
   Inactive  --toggle-status-->  Active     (message: "Intervention activated.")
```
- **DATA-BA-002:** an intervention linked to an open incident in `ba_incident_intervention_jnt` SHOULD be undeactivatable, but `toggleStatus()` performs no guard — deactivation still succeeds.

### Lifecycle & referential integrity
```
create → (edit) → toggle → destroy[soft, is_active=false] → trash
                                    ↳ restore → default scope
                                    ↳ force-delete → row physically removed
```
- **BUG-BA-005:** `destroy()` soft-deletes unconditionally even when the intervention is linked in the junction (BR-BA-030 not enforced).
- Junction FK is `ON DELETE RESTRICT` (**BC-REF-04**), but the model `booted()` deleting-hook detaches junction rows on `isForceDeleting()` so force-delete still succeeds (**INT-OBS-01**).

### Authorization
- Guest → redirect `/login`.
- A non-super-admin user lacking `...create` / `...status` / `...delete` → 403 on the respective endpoint.
- **SEC-BA-002:** `FormRequest::authorize()` returns bare `true`; real gate is the controller `Gate::authorize`.

---

## 3. Manual Test Cases (Step / Action / Expected)

> DB checks use the tenant DB. Where a check says "SELECT", run it against `ba_interventions` (or the junction) in the active tenant schema. No activity-log check applies (feature logs nothing).

### MTC-01 — Schema / configuration truth (`test_intervention_01/02/03`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `ba_interventions` | Columns id, name, description, intervention_type, sort_order, is_active, created_by, updated_by, timestamps, deleted_at exist |
| 2 | `SHOW COLUMNS` on the table | `name` varchar; `intervention_type` enum with `'reward','corrective','counselling'`; `sort_order`/`is_active` tinyint |
| 3 | Check `bha_interventions` existence | Does NOT exist at runtime (**DOC-BA-001**) |
| 4 | Check columns `code`, `escalation_level` | Neither exists (**INT-GAP-01 / INT-GAP-03**); code rule is commented-out in the FormRequest |

### MTC-02 — Create persists & redirects (`test_intervention_10/15`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit Create page, fill name, type=corrective, a free sort_order, description | Form renders (`#name`, `#type`, `#sort_order`) |
| 2 | Press "Save Intervention" | Redirect to `/behavioural-assessment/masters`, success flash |
| 3 | `SELECT * FROM ba_interventions WHERE name=?` | Row exists; `intervention_type='corrective'`; `is_active=1`; `created_by`=`updated_by`=admin id |

### MTC-03 — is_active default (`test_intervention_11`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST a valid payload with `is_active` omitted | Not 422 |
| 2 | `SELECT is_active` for the new row | `1` (defaulted true via `prepareForValidation`) |

### MTC-04 — Update persists (`test_intervention_12`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed an intervention | Row created |
| 2 | PUT new name + `intervention_type=reward` (same sort_order) | Not 422 |
| 3 | Re-select the row | name updated, type=reward, `updated_by`=admin id |

### MTC-05 — Show & list & breadcrumb (`test_intervention_13/14/64`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/behavioural-assessment/interventions/{id}` | Page shows name, description, label "Intervention Name"; breadcrumb "Intervention" present |
| 2 | Visit masters tab with `search={name}` | The intervention appears in the list; breadcrumb "Interventions" present on create |

### MTC-06 — Duplicate name accepted — BUG-BA-010 (`test_intervention_16`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed intervention "DUP …" | Row created |
| 2 | POST another with the same name (different sort_order) | Not 422 (no unique rule on name) |
| 3 | `SELECT COUNT(*) WHERE name=?` | ≥ 2 → **BUG-BA-010** confirmed |

### MTC-07 — Toggle state (`test_intervention_20/55`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed active intervention | `is_active=1` |
| 2 | POST toggle-status | 200; JSON `{success:true, is_active:false, message:"Intervention deactivated."}` |
| 3 | POST toggle-status again | 200; message `Intervention activated.`; `is_active=1` |

### MTC-08 — Deactivation not blocked when linked — DATA-BA-002 (`test_intervention_21`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed active intervention, insert a junction row linking it to an incident | Junction row present (skip if `ba_incidents` absent) |
| 2 | POST toggle-status | 200; `is_active=0` → **DATA-BA-002**: no deactivation guard |

### MTC-09 — Validation negatives (`test_intervention_30–38`, `72`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST empty name/type/sort_order | 422; `errors` has name, intervention_type, sort_order |
| 2 | POST name of 101 chars | 422; `errors.name` |
| 3 | POST type in {Supportive, Reinforcement, symbolic} | 422; `errors.intervention_type` |
| 4 | POST sort_order="abc" / -1 / 256 | Each 422; `errors.sort_order` |
| 5 | POST duplicate active sort_order | 422; message exactly `This sort order is already used by another intervention.` |
| 6 | POST whitespace-only name `"   "` | 422; `errors.name` (trimmed → required fails) |

### MTC-10 — Description optional — VAL-BA-003 (`test_intervention_39`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST valid payload with `description` omitted | Not 422 |
| 2 | `SELECT description` | `NULL` → **VAL-BA-003** (requirement wanted required) |

### MTC-11 — Sort-order reuse after soft delete & boundary (`test_intervention_37/71`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed intervention, soft-delete it | `deleted_at` set |
| 2 | POST new intervention reusing the freed sort_order | Not 422 (unique scoped `whereNull(deleted_at)`) |
| 3 | Free value 255, POST with `sort_order=255` | Not 422 → boundary accepted |

### MTC-12 — Delete / restore / force-delete lifecycle (`test_intervention_40/41/42/46/63`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | DELETE an active intervention | 200/302; hidden from default scope; `is_active=0`; present in trash |
| 2 | Visit trash page | Soft-deleted row is listed |
| 3 | GET restore | Row returns to default scope |
| 4 | Soft-delete then DELETE force-delete | Row physically removed (`withTrashed()` empty) |
| 5 | Full lifecycle create→toggle→delete→restore→force-delete | Each step succeeds end to end |

### MTC-13 — In-use delete not blocked — BUG-BA-005 (`test_intervention_43`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed intervention, link it in the junction to an incident | Junction row present (skip if `ba_incidents`/junction absent) |
| 2 | DELETE the intervention | 200/302; still soft-deleted → **BUG-BA-005** (no usage guard) |

### MTC-14 — Junction FK RESTRICT & observer detach (`test_intervention_44/45`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `information_schema.REFERENTIAL_CONSTRAINTS` for the junction → `ba_interventions` | `DELETE_RULE` = RESTRICT / NO ACTION |
| 2 | Link intervention, soft-delete, then force-delete | Row removed AND junction rows detached (count 0) → **INT-OBS-01** observer detach |

### MTC-15 — Authorization (`test_intervention_50/51/52/53/54`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | As guest (cookies cleared) visit create URL | Redirect to `/login` |
| 2 | As a limited (non-super-admin, no permission) user POST store | 403 |
| 3 | As limited user POST toggle-status | 403 |
| 4 | As limited user DELETE destroy | 403 |
| 5 | Read the Policy source | Contains a `tenant.behavioural-assessment.interventions.{ability}` string for each of the 8 abilities |

### MTC-16 — Search / type filter / empty state (`test_intervention_60/61/62`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Masters with `search={unique name}` | Row appears |
| 2 | Masters with `intervention_type=reward&search={name}` | Reward row appears |
| 3 | Masters with a non-matching search term | Message `No interventions found.` |

### MTC-17 — Invalid id 404 (`test_intervention_70`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET show / edit on id 987654321 | 404 each |
| 2 | POST toggle-status on the missing id | 404 |

### MTC-18 — Tenancy (`test_intervention_90/91`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenancy initialized | `tenancy()->initialized === true`; `ba_interventions` present |
| 2 | Resolve a second tenant domain | Present → isolation exercisable; else the test skips (single-tenant env) |

### MTC-19 — Security (`test_intervention_92/93/94`)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Read the FormRequest source | `authorize()` returns bare `true` → **SEC-BA-002** (mitigated by controller Gate) |
| 2 | Create intervention with `description="Desc <img src=x onerror=alert(1)>"`, visit show | Page source does NOT contain the raw `<img … onerror …>` (Blade escapes) |
| 3 | Create intervention whose name embeds `<script>alert(1)</script>`, visit show | Page source does NOT contain the raw `<script>alert(1)</script>` |
