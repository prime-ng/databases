# Rating Scales — Manual Test Specification (`bha_RatingScaleMANUALTESTING_Require`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| **Module** | BehaviouralAssessment |
| **Feature / Screen** | Rating Scales (Masters tab) — requirement `02-Rating-Scales.md` |
| **Index URL** | `/behavioural-assessment/masters?tab=rating-scales` (list) |
| **Create URL** | `/behavioural-assessment/rating-scales/create` |
| **Store / Update** | `POST /behavioural-assessment/rating-scales` · `PUT /behavioural-assessment/rating-scales/{id}` |
| **Show / Edit** | `GET .../rating-scales/{id}` · `GET .../rating-scales/{id}/edit` |
| **Trash / Restore / Force** | `GET .../rating-scales/trash` · `GET .../{id}/restore` · `DELETE .../{id}/force-delete` |
| **Toggle status** | `POST .../rating-scales/{ratingScale}/toggle-status` (JSON) |
| **Level endpoints** | `POST .../{ratingScale}/levels` · `PUT .../{ratingScale}/levels/{level}` · `DELETE .../{ratingScale}/levels/{level}` |
| **Controller** | `BaRatingScaleController` |
| **FormRequest** | `BaRatingScaleRequest` (`authorize()` returns bare `true` — SEC-BA-002) |
| **Models** | `BaRatingScale` (`ba_rating_scales`), `BaRatingLevel` (`ba_rating_levels`) |
| **Validation** | code req/≤30/unique(soft-scoped); name req/≤100; grade_type in [letter,numeric,descriptive]; min_rating num/≥0; max_rating num/gt:min |
| **Migrations** | `2026_06_16_130616_create_ba_rating_scales_table.php`, `..._130622_create_ba_rating_levels_table.php` |
| **Soft delete** | Yes (`SoftDeletes` on both models; `deleted_at`) |
| **Pagination** | 15/page (trash); masters list paginated via shared component |
| **Activity log** | NONE for this controller (no `activityLog()` call; no observer) — documented absence |
| **CRUD type** | CRUD-master (header + child levels), Full depth |
| **DB scope** | Tenant-side (tenancy init required) |

> **Runtime vs DDL prefix:** the live tables are `ba_*`; the DDL doc's `bha_*` is stale (**DOC-BA-001**). All DB checks below query `ba_rating_scales` / `ba_rating_levels`.

---

## 2. Business Conditions (detailed)

### Fields (header `ba_rating_scales`)
- **code** — required, uppercased automatically, max 30 chars, unique among non-deleted rows.
  *Requirement text says "max 10" — implementation allows 30 (RS-GAP-01).*
- **name** — required, max 100 chars.
- **description** — optional text.
- **grade_type** — required; one of `letter`, `numeric`, `descriptive`. *Create/edit UI offers only Letter & Numeric (RS-GAP-03).*
- **min_rating** / **max_rating** — required decimals(3,1); `max_rating` must be strictly greater than `min_rating`.
- **is_default** — boolean. *No logic unsets other defaults → multiple defaults possible (BUG-BA-009).*
- **is_active** — boolean, defaults true.

### Fields (child `ba_rating_levels`)
- **label** — required, max 50.
- **numeric_value** — required numeric. *Not range-checked against the scale's [min,max] (VAL-BA-002).*
- **sort_order** — nullable int ≥ 0; unique with `rating_scale_id` (`uq_ba_level`).
- **description** — optional.

### Error messages (Laravel default; assert presence of field error key)
- Empty required → 422 with error key per field (`code`, `name`, `grade_type`, `min_rating`, `max_rating`).
- Duplicate active `code` → 422 `code`.
- `max_rating` ≤ `min_rating` → 422 `max_rating`.

### Flash / toast messages (verbatim)
- Create → `Rating scale created successfully.`
- Update → `Rating scale updated successfully.`
- Delete → `Rating scale moved to trash.`
- Restore → `Rating scale restored successfully.`
- Force delete → `Rating scale permanently deleted.`
- Toggle → JSON `message`: `Rating scale activated.` / `Rating scale deactivated.`
- Level → `Level added.` / `Level updated.` / `Level removed.`

### State machine (Active ↔ Inactive)
```
        toggleStatus
 [Active] ───────────► [Inactive]
    ▲                      │
    └──────────────────────┘
        toggleStatus
```
**Guard that SHOULD exist (but does NOT):** a scale linked in Configuration (`ba_config`) or used by active Assessment Periods must not be deactivated — **DATA-BA-001 / BR-BA-029 not enforced.**

### Referential integrity (auto behaviour)
- Delete scale (hard/force) → cascades child `ba_rating_levels` (CASCADE).
- `ba_config.rating_scale_id` → scale (RESTRICT): a referenced scale cannot be hard-deleted.
- `ba_assessment_ratings.rating_level_id` → level (SET NULL): force-deleting a level nulls the rating's level FK.

---

## 3. Manual Test Cases (Step / Action / Expected + DB checks)

### MTC-01 — Create a valid rating scale (TC-P04)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as admin with rating-scale permissions | Dashboard loads |
| 2 | Navigate to Masters → Rating Scales → Create New (`/rating-scales/create`) | Create form renders with `#code`, `#name`, `#grade_type`, `#min_rating`, `#max_rating` |
| 3 | Enter code `rs01` (lowercase), name `5-Point Scale`, grade type `Numeric`, min `1`, max `5` | Fields accept input |
| 4 | Press **Save Rating Scale** | Redirect to `/behavioural-assessment/masters?tab=rating-scales`; green toast `Rating scale created successfully.` |
| 5 | **DB:** `SELECT code,is_active,created_by FROM ba_rating_scales WHERE code='RS01'` | 1 row; `code='RS01'` (uppercased), `is_active=1`, `created_by=<admin id>` |

### MTC-02 — Code auto-uppercase (TC-P05)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create scale with code `abc_low` | Accepted |
| 2 | **DB:** `SELECT code FROM ba_rating_scales WHERE code='ABC_LOW'` | Row exists with uppercased code |

### MTC-03 — Update a scale (TC-P06)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Edit an existing scale, change name + grade_type to `letter`, save | Toast `Rating scale updated successfully.` |
| 2 | **DB:** `SELECT name,grade_type,updated_by FROM ba_rating_scales WHERE id=?` | Reflects new name/grade_type; `updated_by=<admin id>` |

### MTC-04 — Add / update / remove levels (TC-P07/P08)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST level `{label:Exemplary, numeric_value:5, sort_order:1}` to `/rating-scales/{id}/levels` | Toast `Level added.` |
| 2 | **DB:** `SELECT * FROM ba_rating_levels WHERE rating_scale_id=? AND label='Exemplary'` | Row exists, `numeric_value=5.0` |
| 3 | PUT update level label to `Great` | Toast `Level updated.`; DB label updated |
| 4 | DELETE the level | Toast `Level removed.`; `deleted_at` set (soft-deleted, hidden from default scope) |

### MTC-05 — Show + list rendering (TC-P09/P10)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/rating-scales/{id}` | "Scale Identity" section, code, name, levels table shown |
| 2 | Visit masters tab | Scale row shows code, grade-type badge, range, levels count |

### MTC-06 — Toggle status transitions (TC-P11/P13)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/rating-scales/{id}/toggle-status` on an Active scale | 200 JSON `{success:true, is_active:false, message:'Rating scale deactivated.'}` |
| 2 | **DB:** `SELECT is_active FROM ba_rating_scales WHERE id=?` | `0` |
| 3 | Toggle again | JSON `message:'Rating scale activated.'`; DB `is_active=1` |

### MTC-07 — Required-field validation (TC-N01)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST empty payload (authenticated, JSON Accept) | 422 |
| 2 | Inspect errors | Keys present: `code`, `name`, `grade_type`, `min_rating`, `max_rating` |

### MTC-08 — Field-level negatives (TC-N02..N06,N12,N13)
| Step | Action | Expected |
|------|--------|----------|
| 1 | code 31 chars | 422 `code` |
| 2 | name 101 chars | 422 `name` |
| 3 | grade_type `symbolic` | 422 `grade_type` |
| 4 | min_rating `-1` / `abc` | 422 `min_rating` |
| 5 | max_rating `3` with min `5` | 422 `max_rating` |
| 6 | max_rating `3` with min `3` | 422 `max_rating` (gt not gte) |
| 7 | name `"   "` (spaces) | 422 `name` (trimmed → required) |

### MTC-09 — Duplicate code rules (TC-N07/N08)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create scale code `DUP1`; POST another with `dup1` | 422 `code` (duplicate among active) |
| 2 | Soft-delete the `DUP1` scale, POST a new `DUP1` | Accepted (unique scoped to `whereNull(deleted_at)`) |
| 3 | **DB:** `SELECT COUNT(*) FROM ba_rating_scales WHERE code='DUP1' AND deleted_at IS NULL` | 1 |

### MTC-10 — Soft delete + trash + restore + force (TC-D01/D02/D03/P12)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete an active scale | Toast `Rating scale moved to trash.` |
| 2 | **DB:** `SELECT is_active,deleted_at FROM ba_rating_scales WHERE id=? (withTrashed)` | `is_active=0`, `deleted_at` NOT NULL |
| 3 | Visit `/rating-scales/trash` | Scale listed |
| 4 | Restore it | Toast `Rating scale restored successfully.`; back in default scope |
| 5 | Soft-delete again, then force-delete a scale that has a level | Row physically gone; **DB:** its `ba_rating_levels` rows also gone (CASCADE) |

### MTC-11 — Referential integrity (TC-D04/D05)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect FK `ba_config.rating_scale_id` | DELETE_RULE = RESTRICT / NO ACTION (referenced scale cannot be hard-deleted) |
| 2 | Inspect FK `ba_assessment_ratings.rating_level_id` | DELETE_RULE = SET NULL (force-deleting a level nulls the rating FK) |

### MTC-12 — Authorization (TC-N14..N17)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out; visit create URL | Redirect to `/login` |
| 2 | Log in as a non-super-admin user with NO rating-scale permissions | Logged in |
| 3 | POST create / toggle / delete | 403 each (Gate blocks; note super-admin `Gate::before` bypass — use a stripped user) |

### MTC-13 — Defect proofs (TC-X02..X05, RS-GAP-01/02/03)
| Step | Action | Expected (documents defect) |
|------|--------|-----------------------------|
| 1 | Create two scales both `is_default=1` | Both persist (**BUG-BA-009** — one-default not enforced) |
| 2 | POST level `numeric_value:999` to a 1–5 scale | Accepted / persists (**VAL-BA-002** — no range check) |
| 3 | Link a scale in `ba_config`, then toggle it Inactive | Toggle succeeds (**DATA-BA-001** — no active-scale guard) |
| 4 | Soft-delete a referenced scale | Succeeds unconditionally (**RS-GAP-02**) |
| 5 | Submit code of 30 chars | Accepted (**RS-GAP-01** — requirement's max 10 not enforced) |
| 6 | View create form source | No `value="descriptive"` option (**RS-GAP-03**) |
| 7 | Read `BaRatingScaleRequest::authorize()` | Returns bare `true` (**SEC-BA-002**) |

### MTC-14 — Security & tenancy (TC-N09/N20, TC-P17, TC-D09)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create scale with name `XSS <script>alert(1)</script>` and view show page | Script rendered escaped (not executed) |
| 2 | Create scale with description `<img src=x onerror=alert(1)>` and view show | Escaped in page source |
| 3 | Confirm tenancy initialized during tests | `tenancy()->initialized === true`; `ba_rating_scales` resolves in tenant DB |
| 4 | (If 2 tenants) request another tenant's scale id | Isolated (404/not visible) |
