# RatingScale — Manual Testing Specification

## 1. Feature Information

| Item | Value |
|------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | RatingScale (`02-Rating-Scales.md`) |
| Base URL | `{tenant}/behavioural-assessment` |
| List (tabbed masters) | `GET /behavioural-assessment/masters?tab=rating-scales` |
| Create | `GET /behavioural-assessment/rating-scales/create` |
| Store | `POST /behavioural-assessment/rating-scales` |
| Show | `GET /behavioural-assessment/rating-scales/{id}` |
| Edit | `GET /behavioural-assessment/rating-scales/{id}/edit` |
| Update | `PUT /behavioural-assessment/rating-scales/{id}` |
| Destroy (soft) | `DELETE /behavioural-assessment/rating-scales/{id}` |
| Trash | `GET /behavioural-assessment/rating-scales/trash` |
| Restore | `GET /behavioural-assessment/rating-scales/{id}/restore` |
| Force delete | `DELETE /behavioural-assessment/rating-scales/{id}/force-delete` |
| Toggle status | `POST /behavioural-assessment/rating-scales/{id}/toggle-status` → JSON |
| Level store / update / destroy | `POST|PUT|DELETE /behavioural-assessment/rating-scales/{id}/levels[/{level}]` |
| Controller | `BaRatingScaleController` |
| FormRequest | `BaRatingScaleRequest` (scale) · inline `$request->validate()` (levels) |
| Models | `BaRatingScale` (`ba_rating_scales`), `BaRatingLevel` (`ba_rating_levels`) |
| Service | none in write path (plain Eloquent) |
| CRUD type | Full CRUD + child levels + toggle + soft/force-delete |
| Soft delete | Yes (both scale and levels) |
| Pagination | Masters list `paginate(15, page name 'rs_page')`; trash `paginate(15)` |
| Activity log | **None for this feature** (flash messages only; `ba_audit_log` is for ratings/incidents) |
| Permissions | `tenant.behavioural-assessment.rating-scales.{viewAny,view,create,update,delete,restore,forceDelete,status}` |

**Prerequisite:** module `BehaviouralAssessment` must be **enabled** in `prime_testing/modules_statuses.json` (currently `false` → all routes 404). See Validation Report §E.

**Prefix note (`DOC-BA-001`):** DDL doc says `bha_*`; **live tables are `ba_rating_scales` / `ba_rating_levels`**. All DB checks below use `ba_`.

---

## 2. Business Conditions (detailed)

### Validation (scale) — `BaRatingScaleRequest`
| Field | Rule | Failure behaviour |
|-------|------|-------------------|
| code | required, string, max:30, unique(`ba_rating_scales.code`) ignoring self, `whereNull(deleted_at)`; upper-cased | Re-render create/edit with `.alert-danger` error list; no row written |
| name | required, string, max:100 | same |
| description | nullable, string | — |
| grade_type | required, in `letter` \| `numeric` \| `descriptive` (UI offers only letter/numeric) | rejected if other |
| min_rating | required, numeric, min:0 | rejected if negative/blank |
| max_rating | required, numeric, gt:min_rating | rejected if ≤ min |
| is_default | nullable boolean (checkbox) — **saved as-is; other defaults NOT unset (BUG-BA-009)** | — |
| is_active | nullable boolean, default true | — |

### Validation (level) — inline in `storeLevel`
| Field | Rule | Note |
|-------|------|------|
| label | required, string, max:50 | |
| numeric_value | required, numeric | **NOT range-checked vs scale min/max (VAL-BA-002)** |
| description | nullable, string | |
| sort_order | nullable, integer, min:0 | `uq_ba_level(rating_scale_id, sort_order)` DB unique — soft-delete collision (DATA-BA-003) |

### Status / flash flow
```
Create  → INSERT ba_rating_scales               → flash "Rating scale created successfully."
Update  → UPDATE ba_rating_scales               → flash "Rating scale updated successfully."
Destroy → set is_active=0 → soft delete (deleted_at) → flash "Rating scale moved to trash."
Restore → deleted_at=NULL                        → flash "Rating scale restored successfully."
Force   → DELETE row (+ cascade ba_rating_levels) → flash "Rating scale permanently deleted."
Toggle  → is_active = !is_active                 → JSON {success:true, is_active, message:"Rating scale activated./deactivated."}
Level+  → INSERT ba_rating_levels                → flash "Level added."
```

### Requirement rules NOT enforced in code (documented gaps — see §3 tests)
- **BR-BA-028** one default scale — not enforced (BUG-BA-009).
- **BR-BA-029 / Active Status Constraints** deactivate only if unused — no guard (DATA-BA-001).
- **Soft Delete Protection** block delete when ratings reference the scale — no guard.
- **BR-BA-003** level value in `[min_rating, max_rating]` — not checked (VAL-BA-002).
- **Min/Max levels (2–10)** per scale — no application enforcement observed.

---

## 3. Test Cases (step / action / expected)

### TC-P10 — Create a valid rating scale
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; visit `/behavioural-assessment/rating-scales/create` | "Scale Identity" + "Score Range & Settings" sections render |
| 2 | Type Code `pri_beh_3`, Name `Primary Behaviour Scale`, Grade Type `Numeric` | fields accept input |
| 3 | Set Min `1`, Max `5`; click **Save Rating Scale** | redirect to masters, flash `Rating scale created successfully.` |
| 4 | DB check | `SELECT code FROM ba_rating_scales WHERE name='Primary Behaviour Scale'` → expect `PRI_BEH_3` (upper-cased) |

### TC-P15 — Add a rating level
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open an existing scale's `/edit` | "Add New Level" form visible |
| 2 | Label `Consistently`, Numeric Value `3`, Order `1`; click **Add** | flash `Level added.` |
| 3 | DB check | `SELECT COUNT(*) FROM ba_rating_levels WHERE rating_scale_id=? AND label='Consistently'` → 1 |

### TC-SM01 — Toggle status
| Step | Action | Expected |
|------|--------|----------|
| 1 | Masters list, click the `.status-toggle[data-id={id}]` switch | AJAX POST toggle-status |
| 2 | DB check | `SELECT is_active FROM ba_rating_scales WHERE id=?` → flipped |
| 3 | Response | JSON `{"success":true,"is_active":false,"message":"Rating scale deactivated."}` |

### TC-D01/D03 — Soft-delete → restore → force-delete (cascade)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a scale (action column trash) | flash `Rating scale moved to trash.`; `deleted_at` set, `is_active=0` |
| 2 | Trash page, Restore | flash `Rating scale restored successfully.`; `deleted_at` NULL |
| 3 | Delete again, then Force delete | flash `Rating scale permanently deleted.` |
| 4 | DB check | scale row gone; `SELECT COUNT(*) FROM ba_rating_levels WHERE rating_scale_id=?` → 0 (cascade) |

### TC-N30..N36 — Validation (negative)
| TC | Action | Expected |
|----|--------|----------|
| N30 | Submit empty form | `.alert-danger` with required errors; no row |
| N31 | Code = 35 chars | rejected; no row |
| N32 | Name = 130 chars | rejected; no row |
| N33 | grade_type = out-of-enum | rejected; no row |
| N34 | min_rating = -3 | rejected; no row |
| N35 | min = max = 4 | rejected (gt); no row |
| N36 | Duplicate active code | rejected; row count unchanged |

### TC-N20 — BUG-BA-009 (multiple defaults) — proof
| Step | Action | Expected (current buggy behaviour) |
|------|--------|-----------------------------------|
| 1 | Create Scale A with **Set as Default** checked | A.is_default=1 |
| 2 | Create Scale B with **Set as Default** checked | B.is_default=1 |
| 3 | DB check | `SELECT COUNT(*) FROM ba_rating_scales WHERE is_default=1 AND deleted_at IS NULL` → **≥ 2** (BR-BA-028 violated) |

### TC-N23 — VAL-BA-002 (level value not range-checked) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Scale with min=1, max=5 | — |
| 2 | Add level numeric_value `9.9` | flash `Level added.` (accepted despite being out of range) |
| 3 | DB check | `SELECT numeric_value FROM ba_rating_levels WHERE label='OutOfRange'` → `9.9` |

### TC-D05 — DATA-BA-003 (soft-delete + unique sort_order) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Add level sort_order=6 to a scale | inserted |
| 2 | Delete that level (soft) | row hidden but `deleted_at` set, still occupies (scale,6) |
| 3 | Add another level sort_order=6 | **Integrity error (SQLSTATE 23000 / duplicate)** → 500 through controller |

### TC-N21 — DATA-BA-001 (deactivate no usage guard) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Scale linked/used in config or period | — |
| 2 | Toggle to Inactive | succeeds with no block (requirement says it should be prevented) |

### TC-S01/S02 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout; visit create/index paths | redirect to `/login` |

### TC-S04 — Limited user forbidden
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as user without `rating-scales.create` | visiting create → 403 / no "Save Rating Scale" form |

### TC-S05 — Stored XSS escaped
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create scale with name `<script>window.x=1</script>` | saved |
| 2 | Open show page | script does not execute (`window.x` undefined); Blade escapes output |

### TC-S06 — Invalid id 404
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/rating-scales/98765432` | `findOrFail` → 404; "Configured Rating Levels" not shown |

### TC-T01 — Tenant isolation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenancy initialized | `ba_rating_scales` resolves in tenant DB; no `tenant_id` column (DB-per-tenant) |
