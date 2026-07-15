# Behavioural Assessment — Class-Mapping — Manual Testing Guide

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | Class-Mapping (setup tab `class-mapping`, app alias `class-categories`) |
| DB scope | TENANT-side (`tenant_db`, database-per-tenant) |
| Setup URL | `/behavioural-assessment/setup?tab=class-mapping` |
| Store endpoint | `POST /behavioural-assessment/class-categories` |
| Toggle endpoint | `POST /behavioural-assessment/class-categories/{id}/toggle-status` (JSON) |
| Destroy endpoint | `DELETE /behavioural-assessment/class-categories/{id}` |
| Controller | `BaClassCategoryController` (`store`, `toggleStatus`, `destroy`) |
| Listing controller | `BaDashboardController::setup()` |
| Model | `BaClassCategoryJnt` (table `ba_class_category_jnt`) |
| FormRequest | `BaClassCategoryRequest` |
| Policy | `BaClassCategoryPolicy` (8 abilities) |
| Runtime table | `ba_class_category_jnt` (live `ba_` prefix) |
| Validation | class_id: required\|integer\|exists:sch_classes,id · category_id: required\|integer\|exists:ba_categories,id · unique (class_id + category_id) |
| Migration | `2026_06_16_130618_create_ba_class_category_jnt_table.php` |
| CRUD Type | Create / Toggle-status / Delete (NO edit/update route) |
| Soft Delete | Column present (`deleted_at`) but **NOT active** — model omits `SoftDeletes` trait; `destroy()` HARD-deletes (DATA-BA-CM-01) |
| Pagination | Setup tab list (no server-side create/edit modal) |
| Activity Log | **NONE** — controller writes no activity log; model has no observer |
| Permission prefix | `tenant.behavioural-assessment.class-categories.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete\|status}` (+ `tenant.behavioural-assessment.setup.viewAny` for the tab) |

### Prerequisites

- Module `BehaviouralAssessment` is enabled in `modules_statuses.json`.
- Tenant DB migrated & seeded; at least one active `sch_classes` row and one active top-level `ba_categories` row exist.
- Admin/root tenant user with all `class-categories.*` + `setup.viewAny` permissions.
- Chrome + ChromeDriver available for the automated Dusk suite (`bha_ClassMapping_TestCas.php`).
- Env: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD` set for the tenant.

---

## 2. Business Conditions (detailed)

### Create (`store`)
1. Submit `class_id` + `category_id` from the setup form → mapping created with `is_active=true`.
2. `created_by` and `updated_by` are forced to the acting admin id; any client-supplied values for these (or `is_active`) are ignored.
3. Success flash: **"Category mapped to class successfully."**
4. Duplicate `(class_id, category_id)` pair → 422 with **"This category is already mapped to the selected class."**

### Toggle (`toggleStatus`) — state machine
```
Active   --toggleStatus-->  Inactive   (JSON message "Mapping deactivated.")
Inactive --toggleStatus-->  Active     (JSON message "Mapping activated.")
```
- Returns JSON `{ success: true, is_active: <bool>, message: <string> }` with HTTP 200.
- Stamps `updated_by` to the acting admin.
- Invalid id → 404.

### Delete (`destroy`)
- Removes the mapping and redirects back (200/302).
- HARD delete (no soft-delete trait): the row is physically removed; `deleted_at` is never populated.
- Invalid id → 404.

### Validation error map
| Field | Rule | Error trigger |
|-------|------|---------------|
| class_id | required, integer, exists:sch_classes,id | empty / non-integer / whitespace / non-existent id |
| category_id | required, integer, exists:ba_categories,id | empty / null / non-integer / non-existent id |
| (class_id, category_id) | unique pair | duplicate mapping → "This category is already mapped to the selected class." |

### Permission matrix
| Action | Required permission | Denied result |
|--------|--------------------|---------------|
| View setup tab | `...setup.viewAny` | 403 / redirect |
| Create mapping | `...class-categories.create` | 403 |
| Toggle status | `...class-categories.status` | 403 |
| Delete mapping | `...class-categories.delete` | 403 |
| (Guest) | — | redirect to `/login` |

---

## 3. Test Cases (step-by-step)

> Every manual case below maps 1:1 to an automated method in `bha_ClassMapping_TestCas.php` (method name in the header). DB checks and JSON checks are called out explicitly.

### TC-C01 — Schema/config truth · `test_..._01`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect table | `ba_class_category_jnt` exists with columns id, class_id, category_id, is_active, created_by, updated_by, created_at, updated_at, deleted_at |
| 2 | `SHOW COLUMNS` | `is_active` type contains `tinyint`; `class_id`/`category_id` contain `int` |
| 3 | Read migration | Contains `Schema::create('ba_class_category_jnt'`, `uq_ba_class_cat`, `fk_ba_cc_class_id`, `->on('sch_classes')`, `constrained('ba_categories')`, `$table->softDeletes()` |
| 4 | Read FormRequest | Contains `exists:sch_classes,id`, `exists:ba_categories,id`, `Rule::unique('ba_class_category_jnt', 'category_id')`, `whereNull('deleted_at')`, custom message |
| 5 | Inspect model | table = `ba_class_category_jnt`; fillable = [class_id, category_id, is_active, created_by, updated_by]; `is_active` cast boolean; `schoolClass()`/`category()` BelongsTo |

### TC-C02 — Prefix divergence DOC-BA-001 · `test_..._02`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check table exists | `ba_class_category_jnt` present |
| 2 | Check stale name | `bha_class_category_jnt` MUST NOT exist |
| 3 | Model table | binds to `ba_class_category_jnt` (code wins over doc) |

### TC-C03 — SoftDeletes omitted DATA-BA-CM-01 · `test_..._03`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check column | `deleted_at` exists (migration added softDeletes) |
| 2 | Check trait | Model does NOT use `SoftDeletes` |
| 3 | Confirm | No soft-delete behaviour exposed |

### TC-P01 — Store creates mapping · `test_..._10`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Resolve an unused (class, category) pair | valid select values |
| 2 | POST to store endpoint | Not 422 |
| 3 | `SELECT * FROM ba_class_category_jnt WHERE class_id=? AND category_id=?` | row exists, `is_active=1` |
| 4 | Cleanup | delete row |

### TC-P02 — Store stamps auditors · `test_..._11`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST store | row created |
| 2 | Inspect row | `created_by` = admin id; `updated_by` = admin id |

### TC-P03 — Toggle flips & returns JSON · `test_..._12`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed active mapping | row `is_active=1` |
| 2 | POST toggle-status | HTTP 200; JSON `success=true`; has `is_active`; message "Mapping deactivated." |
| 3 | `SELECT is_active` | 0 |
| 4 | POST toggle-status again | message "Mapping activated."; `is_active` → 1 |

### TC-P04 — Destroy removes & redirects · `test_..._13`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping | row exists |
| 2 | DELETE endpoint | 200 or 302 |
| 3 | `SELECT ... WHERE id=?` | row gone |

### TC-P05 — Setup tab lists class + category · `test_..._14`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping | row exists |
| 2 | Open setup tab | class name & category name visible |

### TC-P06 — Browser form success flash · `test_..._15`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open setup tab, select class & category, press "Add Mapping" | flash "Category mapped to class successfully." |
| 2 | `SELECT` | mapping persisted |

### TC-P07 — Delete control rendered · `test_..._16`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping, open setup tab | page source contains `class-categories/{id}` |

### TC-SM01 — Active↔Inactive round-trip · `test_..._20`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed active mapping | `is_active=1` |
| 2 | Toggle | 200; `is_active=0` |
| 3 | Toggle | 200; `is_active=1` |

### TC-SM02 — Toggle stamps updated_by · `test_..._21`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping with `updated_by=0` | row exists |
| 2 | Toggle | `updated_by` = admin id |

### TC-N01 — Required fields · `test_..._30`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `{class_id:'', category_id:''}` | 422; errors contain `class_id` & `category_id` |

### TC-N02 — class_id exists · `test_..._31`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST class_id=987654321 (valid category) | 422; error `class_id` |

### TC-N03 — category_id exists · `test_..._32`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST category_id=987654321 (valid class) | 422; error `category_id` |

### TC-N04 — class_id integer · `test_..._33`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST class_id='abc' | 422; error `class_id` |

### TC-N05 — category_id integer · `test_..._34`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST category_id='abc' | 422; error `category_id` |

### TC-N06 — Duplicate rejected w/ message · `test_..._35`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping | row exists |
| 2 | POST same pair | 422; error `category_id` contains "This category is already mapped to the selected class." |

### TC-N07 — Same category, different class allowed · `test_..._36`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping; pick a second class | POST (class2, same category) → not 422 (skips if only one class) |

### TC-N08 — Different category, same class allowed · `test_..._37`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping; pick a second category | POST (same class, category2) → not 422 (skips if only one category) |

### TC-N09 — Whitespace class_id rejected · `test_..._38`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST class_id='   ' | 422; error `class_id` |

### TC-N10 — Null category_id rejected · `test_..._73`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST category_id=null | 422; error `category_id` |

### TC-D01 — class_id FK CASCADE · `test_..._40`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Query information_schema DELETE_RULE for class_id FK | contains CASCADE (MySQL-only, else skip) |

### TC-D02 — category_id FK CASCADE · `test_..._41`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Query DELETE_RULE for category_id FK | contains CASCADE (MySQL-only, else skip) |

### TC-D03 — Unique index VAL-BA-CM-02 · `test_..._42`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW INDEX ... WHERE Key_name='uq_ba_class_cat'` | index exists; columns class_id + category_id; Non_unique=0; `deleted_at` NOT in key |

### TC-D04 — Hard delete DATA-BA-CM-01 · `test_..._43`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping, DELETE endpoint | row physically gone; no soft-deleted remnant (`deleted_at` never set) |

### TC-P08 — Full lifecycle · `test_..._44`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create | not 422; row exists |
| 2 | Toggle off | 200; `is_active=0` |
| 3 | Destroy | row gone |

### TC-A01 — Guest redirected · `test_..._50`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies, visit setup tab | redirected to `/login` |

### TC-A02 — No create → 403 · `test_..._51`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as limited user, POST store | 403 |

### TC-A03 — No status → 403 · `test_..._52`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as limited user, POST toggle | 403 |

### TC-A04 — No delete → 403 · `test_..._53`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as limited user, DELETE mapping | 403 |

### TC-A05 — Policy maps gate strings · `test_..._54`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read policy source | all 8 abilities reference `tenant.behavioural-assessment.class-categories.{ability}` |

### TC-A06 — Setup tab requires setup.viewAny · `test_..._55`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as limited user, GET setup tab | 403 or 302 |

### TC-P09 — Render form + headers · `test_..._60`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open setup tab | sees "Add Mapping", "Class", "Category", "Polarity" |

### TC-P10 — Polarity badge · `test_..._61`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed mapping (category has polarity), open tab | sees ucfirst(polarity); skips if none |

### TC-P11 — Empty-state message · `test_..._62`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read class-mapping partial | contains "No class-category mappings yet." |

### TC-E01 — Toggle invalid id 404 · `test_..._70`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST toggle-status/987654321 | 404 |

### TC-E02 — Destroy invalid id 404 · `test_..._71`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | DELETE /class-categories/987654321 | 404 |

### TC-E03 — Mass-assignment ignored · `test_..._72`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST store with is_active=false, created_by=987654321, updated_by=987654321 | row `is_active=1`; `created_by`=admin id |

### TC-T01 — Tenant context · `test_..._90`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect tenancy | `tenancy()->initialized` true; table exists |

### TC-T02 — Cross-tenant isolation · `test_..._91`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Resolve a second tenant domain | second tenant exists (else skip) |

### TC-S01 — authorize() bare true SEC-BA-002 · `test_..._92`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read FormRequest | `authorize()` matches `return true;` (mitigated by controller Gate) |

### TC-S02 — No activity log · `test_..._93`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read controller | no `activityLog` / `ActivityLog::` |
| 2 | Create mapping, compare activity_logs count | unchanged (if table exists) |

### TC-S03 — Dead non-POST branch CM-GAP-03 · `test_..._94`
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read FormRequest | has `isMethod('POST')` branch |
| 2 | Check routes | `store` & `destroy` registered; `update` route NOT registered → dead branch |
