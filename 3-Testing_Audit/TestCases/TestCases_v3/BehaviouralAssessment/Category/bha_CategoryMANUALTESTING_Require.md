# Categories & Criteria — Manual Test Cases (`bha_CategoryMANUALTESTING_Require.md`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | Categories & Criteria (masters tab, screen `03-Categories*`) |
| Screen requirement | `BehaviouralAssessment_v2/03-Categories.md` |
| Base URL (tenant) | `http://test.localhost:8000/behavioural-assessment` |
| Masters tab | `/behavioural-assessment/masters?tab=categories` |
| Create page | `/behavioural-assessment/categories/create` |
| Store endpoint | `POST /behavioural-assessment/categories` |
| Show page | `/behavioural-assessment/categories/{id}` |
| Trash page | `/behavioural-assessment/categories/trash` |
| Toggle status | `POST /behavioural-assessment/categories/{id}/toggle-status` |
| Reorder | `POST /behavioural-assessment/categories/reorder` |
| Restore | `GET /behavioural-assessment/categories/{id}/restore` |
| Force-delete | `DELETE /behavioural-assessment/categories/{id}/force-delete` |
| Nested criteria | `POST|PUT|DELETE /behavioural-assessment/categories/{id}/criteria[/{critId}]` |
| Controller | `Modules\BehaviouralAssessment\Http\Controllers\BaCategoryController` |
| FormRequest | `Modules\BehaviouralAssessment\Http\Requests\BaCategoryRequest` (header only; criterion validated inline) |
| Models | `BaCategory` (`ba_categories`), `BaCriterion` (`ba_criteria`) |
| Validation | Category header via FormRequest; criterion via inline controller rules |
| Migrations | `tenant/2026_06_16_130614_create_ba_categories_table.php`, `tenant/2026_06_16_130620_create_ba_criteria_table.php` |
| CRUD type | CRUD-master Full (create/edit/show/soft-delete/restore/force-delete/toggle/reorder + nested criteria) |
| Soft delete | Yes (both tables) |
| Pagination | Masters list; polarity + search filters |
| Activity log | **NONE** — controller calls no `activityLog()` helper; no model observer (documented absence) |
| Permissions | `tenant.behavioural-assessment.categories.{viewAny|view|create|update|delete|restore|forceDelete|status}` |

### Environment prerequisites (must be true before running)
1. Module **enabled** in `prime_testing/modules_statuses.json` (`"BehaviouralAssessment": true`) — a disabled module returns 404 on all routes.
2. `APP_ENV=testing` for Dusk (bypasses CSRF; else 419 on state-changing requests). The runners set it.
3. Tenant reachable at `DUSK_TENANT_URL` (default `http://test.localhost:8000`) with a resolvable `Domain` row.
4. Admin `root@tenant.com` / `password` present and Super-Admin-capable; `glb_languages` has ≥1 row (for limited-user creation).

---

## 2. Business Conditions (detailed — with messages & flows)

**Validation (category header, `BaCategoryRequest`):**
- `name` → required | string | max:100
- `parent_id` → nullable | exists:ba_categories,id
- `polarity` → required | in:`positive`,`negative`
- `weight` → required | numeric | min:0 | max:100 — **`prepareForValidation` merges `100.00` when omitted**
- `sort_order` → required | integer | min:0 | max:255 | unique on `ba_categories.sort_order` **scoped to `parent_id`**
  - custom message: `This sort order is already used for another category at the same level.`

**Validation (criterion, inline in controller):** `name` → required | max:150. `weight` → numeric | min:0 (**no max**). Defaults: `weight ?? 1.00`, `sort_order ?? 0`.

**State machine (Active ↔ Inactive):**
```
Active --toggle-status--> Inactive --toggle-status--> Active
        (no guard for attached criteria; criteria is_active in grid unchanged)
toggle-status JSON: { success:true, is_active:<bool>, message:"Category activated." | "Category deactivated." }
```

**Lifecycle & FK behaviour:**
```
create --> destroy(soft delete, is_active=false, moves to trash)
       --> restore(returns to default scope)
       --> forceDelete(physically removed; ba_criteria CASCADE-deleted; children parent_id SET NULL)
criterion destroy --> BLOCKED if ba_assessment_ratings reference it
   message: "Cannot delete this criterion because ratings have been recorded against it. Deactivate it instead."
   else soft-deleted with flash: "Criterion removed."
```

**Documented gaps (current behaviour, proven — not a to-fix in these tests):** DOC-BA-001 (`bha_` vs `ba_`), SEC-BA-002 (`authorize()` returns true), CAT-GAP-01 (no `code`), CAT-GAP-02 (no `max_score`), CAT-GAP-03 (weightage sum ≠ 100 not enforced), CAT-GAP-04 (active category may have 0 criteria), CAT-GAP-05 (`destroy()` no ratings guard), CAT-GAP-07 (duplicate category name allowed), CAT-GAP-08 (duplicate criterion name allowed), CAT-GAP-09 (criterion weight has no max).

---

## 3. Manual Test Cases (Step / Action / Expected — with DB checks)

> Automated counterpart method noted per case. Activity-log checks are intentionally omitted — this feature writes **no** activity log.

### MTC-01 — Schema / model / request configuration  *(auto: `test_category_01`, `_03`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `ba_categories` | Columns `id, parent_id, name, description, polarity, weight, sort_order, is_active, created_by, updated_by, timestamps, deleted_at` exist |
| 2 | Inspect column types | `name` varchar(100); `polarity` enum(negative,positive); `weight` decimal(5,2) default 100.00; `sort_order` tinyint |
| 3 | Inspect `ba_criteria` | Columns present; `category_id` FK → `ba_categories` ON DELETE CASCADE |
| 4 | DB check | `SELECT` on both tables succeeds; both use soft-delete (`deleted_at`) |

### MTC-02 — Runtime prefix divergence (DOC-BA-001)  *(auto: `test_category_02`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check `ba_categories`/`ba_criteria` exist | Present at runtime |
| 2 | Check `bha_categories`/`bha_criteria` | **Do NOT exist** (proves DDL doc prefix is stale) |

### MTC-03 — Missing `code` / `max_score` (CAT-GAP-01/02)  *(auto: `test_category_04`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW COLUMNS FROM ba_categories` / `ba_criteria` | No `code` column on either |
| 2 | `SHOW COLUMNS FROM ba_criteria` | No `max_score` column |

### MTC-10 — Create a category  *(auto: `test_category_10`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open create page | Form with `#name`, `#polarity`, weight, sort_order |
| 2 | Enter name, polarity=positive, weight=50, next free sort_order; Save | Redirect to `/behavioural-assessment/masters` with success flash |
| 3 | DB check | `SELECT * FROM ba_categories WHERE name=?` → 1 row; `is_active=1`; `created_by=updated_by=<admin id>`; `polarity='positive'` |

### MTC-11 — Weight defaults to 100  *(auto: `test_category_11`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Submit create omitting `weight` | Not rejected (no 422) |
| 2 | DB check | `weight = 100.00` |

### MTC-12 — Update a category  *(auto: `test_category_12`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Edit an existing category: new name, polarity=negative, weight=40 | Saved (no 422) |
| 2 | DB check | Name/polarity updated; `updated_by=<admin id>` |

### MTC-13/14 — Add criterion (persist + defaults)  *(auto: `test_category_13`, `_14`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST criterion `{name:'Participation', weight:30, sort_order:1}` | 200/302 |
| 2 | DB check | Criterion row; `weight=30.00`; `is_active=1`; `created_by=<admin id>` |
| 3 | POST criterion `{name:'Defaults Criterion'}` (no weight/sort_order) | 200/302 |
| 4 | DB check | `weight=1.00`; `sort_order=0` |

### MTC-15 — Update & delete criterion  *(auto: `test_category_15`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | PUT criterion → name='Renamed', weight=20 | 200/302; DB `name='Renamed'`, `weight=20.00` |
| 2 | DELETE criterion | 200/302; row hidden from default scope (soft-deleted) |

### MTC-15b — Show page renders  *(auto: `test_category_15b`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/categories/{id}` | Sees category name, its criterion name, and `Category Identity` |

### MTC-16 — Masters list  *(auto: `test_category_16`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open masters tab | Category (with a criterion) listed by name |

### MTC-17 — Parent/child self-reference  *(auto: `test_category_17`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create child with `parent_id`=parent | `child.parent_id = parent.id`; `parent.children()` includes child; `child.parent` resolves |

### MTC-18 — Duplicate category name allowed (CAT-GAP-07)  *(auto: `test_category_18`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a second category with an existing name | Accepted (no 422) |
| 2 | DB check | `COUNT(*) WHERE name=?` ≥ 2 |

### MTC-19 — Weightage sum not enforced (CAT-GAP-03)  *(auto: `test_category_19`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Add two criteria weight 40 + 40 (=80) | Both accepted |
| 2 | DB check | `SUM(weight)=80` and still accepted (no 100% rule) |

### MTC-20/21 — Toggle status (state machine)  *(auto: `test_category_20`, `_21`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Toggle active category | 200; DB `is_active=0` |
| 2 | Toggle again | 200; DB `is_active=1` |
| 3 | Category with attached criterion → toggle | Deactivated (no guard); criterion `is_active` unchanged in grid |

### MTC-30 — Required fields  *(auto: `test_category_30`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST empty name/polarity/weight/sort_order | 422; errors for all four fields |

### MTC-31..34 — Field validation  *(auto: `test_category_31`–`_34`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `name` = 101 chars | 422 name error |
| 2 | `polarity` = `neutral` | 422 polarity error |
| 3 | `weight` = 150 / -1 / `abc` | 422 weight error each |
| 4 | `sort_order` = 300 / -1 | 422 sort_order error each |

### MTC-35/36/37 — sort_order uniqueness scoped by parent  *(auto: `test_category_35`–`_37`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Two top-level categories same `sort_order` | Second → 422 sort_order error |
| 2 | Error message | `This sort order is already used for another category at the same level.` |
| 3 | Child under a parent reusing a top-level `sort_order` | Accepted (unique scoped to parent_id) |

### MTC-38 — parent_id exists  *(auto: `test_category_38`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `parent_id`=987654321 | 422 parent_id error |

### MTC-39 — Criterion name required + max:150  *(auto: `test_category_39`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST criterion name='' | 422 name error |
| 2 | POST criterion name=151 chars | 422 name error |

### MTC-40..43 — Delete / restore / force-delete / SET NULL  *(auto: `test_category_40`–`_43`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Delete category | Hidden from default scope; `onlyTrashed` finds it; `is_active=0` |
| 2 | Restore | Returns to default scope |
| 3 | Force-delete category with criterion | Category + criterion physically removed (CASCADE) |
| 4 | Force-delete parent with child | Child `parent_id` = NULL (SET NULL) |

### MTC-44 — Criterion delete ratings guard  *(auto: `test_category_44`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Delete an unrated criterion | Soft-deleted; flash `Criterion removed.` |
| 2 | (Source) `destroyCriterion` guards on `BaAssessmentRating::where('criterion_id', ...)->exists()` | Block message present in source |

### MTC-45 — Category delete not blocked with criteria (CAT-GAP-05)  *(auto: `test_category_45`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Delete a category that has a criterion | Soft-deleted unconditionally (no usage guard) |

### MTC-46 — Full lifecycle  *(auto: `test_category_46`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | create → toggle → delete → restore → force-delete | Each stage behaves per MTC-10/20/40/41/42 |

### MTC-50..53 — Authorization  *(auto: `test_category_50`–`_53`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Guest visits create page | Redirect to `/login` |
| 2 | Limited user POST store | 403 |
| 3 | Limited user POST toggle-status | 403 |
| 4 | Limited user DELETE category | 403 |

### MTC-54 — Policy gate strings  *(auto: `test_category_54`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `BaCategoryPolicy` | Contains `tenant.behavioural-assessment.categories.{viewAny,view,create,update,delete,restore,forceDelete,status}` |

### MTC-55 — Toggle JSON contract  *(auto: `test_category_55`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Toggle active category | 200; JSON `success:true`, has `is_active`, message `Category deactivated.` |
| 2 | Toggle again | message `Category activated.` |

### MTC-56 — Reorder  *(auto: `test_category_56`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST reorder `{order:[B.id, A.id]}` | 200; JSON `success:true` |
| 2 | DB check | `B.sort_order=0`, `A.sort_order=1` |

### MTC-60..64 — UI/UX  *(auto: `test_category_60`–`_64`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Search masters by name | Matching category visible |
| 2 | Apply `polarity=negative` filter + search | Negative category visible |
| 3 | Search a non-matching string | Sees `No categories found.` |
| 4 | Visit trash page (after delete) | Trashed category visible |
| 5 | Create page / show page breadcrumb | Sees `Categories` / `Categories & Criteria` |

### MTC-70..74 — Edge cases  *(auto: `test_category_70`–`_74`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET show/edit/toggle for id 987654321 | 404 each |
| 2 | Create with name = `'   '` | 422 (TrimStrings → required fails) |
| 3 | Criterion weight = 250 | Accepted; DB `weight=250.00` (CAT-GAP-09) |
| 4 | Two criteria same name in one category | Both accepted; count ≥ 2 (CAT-GAP-08) |
| 5 | Active category with 0 criteria | Accepted; `is_active=1`, `criteria().count()=0` (CAT-GAP-04) |

### MTC-90..93 — Tenancy & security  *(auto: `test_category_90`–`_93`)*
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm tenant context | Tenancy initialized; `ba_categories` present |
| 2 | Cross-tenant direct-ID | Isolated (or skipped if only one tenant) |
| 3 | Inspect `BaCategoryRequest::authorize()` | Returns `true` (SEC-BA-002) |
| 4 | Store name/description with `<script>`/`<img onerror>`; open show page | Payloads escaped — not present as executable HTML in page source |
