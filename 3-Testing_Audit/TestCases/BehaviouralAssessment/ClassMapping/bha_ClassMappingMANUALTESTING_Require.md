# ClassMapping — Manual Testing Specification

## 1. Feature Information

| Item | Value |
|------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | ClassMapping (`05-Class-Mapping.md`) · app alias **ClassCategory** |
| Base URL | `{tenant}/behavioural-assessment` |
| List (Setup tab) | `GET /behavioural-assessment/setup?tab=class-mapping` (BaDashboardController@setup, gate `…setup.viewAny`) |
| Store | `POST /behavioural-assessment/class-categories` → `behavioural-assessment.class-categories.store` |
| Toggle status | `POST /behavioural-assessment/class-categories/{id}/toggle-status` → JSON |
| Destroy | `DELETE /behavioural-assessment/class-categories/{id}` → `…class-categories.destroy` |
| Edit / Update | **none** (junction feature — no edit screen) |
| Controller | `BaClassCategoryController` (`store` / `toggleStatus` / `destroy`) |
| FormRequest | **none** — inline `$request->validate()` (`VAL-BA-001`) |
| Model | `BaClassCategoryJnt` (`ba_class_category_jnt`) |
| Service | none in write path (plain Eloquent) |
| CRUD type | Junction/config: add (store) + toggle + remove (hard delete). No edit. |
| Soft delete | **Migration declares `softDeletes()`/`deleted_at`, but the MODEL omits the trait → `destroy()` is a HARD delete (`BUG-BA-012`)** |
| Pagination | `paginate(20, page name 'cm_page')` |
| Activity log | **None** (flash messages only) |
| Permissions | `tenant.behavioural-assessment.class-categories.{viewAny,view,create,update,delete,status,restore,forceDelete}` + `…setup.viewAny` |

**Prerequisite:** module `BehaviouralAssessment` must be **enabled** in `prime_testing/modules_statuses.json` (currently `false` → all routes 404). See Validation Report §E.

**Prefix note (`DOC-BA-001`):** DDL doc says `bha_class_category_jnt`; **live table is `ba_class_category_jnt`**. All DB checks below use `ba_`.

**Cross-module dependency:** `class_id` → `sch_classes` (SchoolSetup, active classes only), `category_id` → `ba_categories` (top-level active). Both `ON DELETE CASCADE`. Tests skip defensively if SchoolSetup is absent.

---

## 2. Business Conditions (detailed)

### Validation (inline in `BaClassCategoryController@store` — no FormRequest)
| Field | Rule | Failure behaviour |
|-------|------|-------------------|
| class_id | `required, integer, exists:sch_classes,id` | redirect back with error; no row |
| category_id | `required, integer, exists:ba_categories,id` | redirect back with error; no row |
| category_id (uniqueness) | `unique(ba_class_category_jnt, category_id)` where `class_id = X` and `deleted_at IS NULL` | error `This category is already mapped to the selected class.`; no row |

### Status / flash flow (real strings)
```
Add     → INSERT ba_class_category_jnt (is_active=1, created_by/updated_by=auth id)
          → flash "Category mapped to class successfully."
Toggle  → is_active = !is_active (updated_by=auth id)
          → JSON {success:true, is_active, message:"Mapping activated." | "Mapping deactivated."}
Remove  → $mapping->delete()  ⚠ HARD delete (model lacks SoftDeletes — BUG-BA-012)
          → flash "Mapping removed."
```

### Requirement rules NOT enforced in code (documented gaps — see §3 tests)
- **BUG-BA-012 (NEW)** — model omits `SoftDeletes`; `destroy()` permanently removes the row; `deleted_at` column is dead; the store unique rule's `whereNull('deleted_at')` scope is effectively moot.
- **GAP-BA-CM-01 (NEW / Screen "Preservation of Existing Grades")** — `destroy()` performs **no** `ba_assessment_ratings` check. Requirement demands the block message `"Cannot remove Category '…' because teachers have already recorded ratings for this class."` — not implemented.
- **GAP-BA-CM-02 (NEW / Screen "Key Fields")** — requirement describes a **multi-category checkbox grid** scoped to an **Academic Session** ("At least 1 must be selected"); implementation adds **one** class+category at a time with no session scope (no `academic_session_id` column).
- **BUG-BA-007** — the Ratings grid reads `ba_class_category_jnt`; an **unmapped class yields an empty grid** instead of the BR-BA-009 permissive default ("no mapping ⇒ all active categories apply").
- **VAL-BA-001** — no `BaClassCategoryRequest`; validation is inline in the controller.

---

## 3. Test Cases (step / action / expected)

### TC-P03 — Create a valid class↔category mapping
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; visit `/behavioural-assessment/setup?tab=class-mapping` | Class + Category selects + "Add Mapping" render |
| 2 | Select a Class and a Behavioural Category not already paired | fields accept input |
| 3 | Click **Add Mapping** | flash `Category mapped to class successfully.` |
| 4 | DB check | `SELECT COUNT(*) FROM ba_class_category_jnt WHERE class_id=? AND category_id=?` → 1 |
| 5 | DB check | row has `is_active=1`, `created_by`/`updated_by` = admin id |

### TC-SM01 — Toggle status
| Step | Action | Expected |
|------|--------|----------|
| 1 | On the list, click the `.status-toggle[data-id={id}]` switch | AJAX POST to `class-categories/{id}/toggle-status` |
| 2 | DB check | `SELECT is_active FROM ba_class_category_jnt WHERE id=?` → flipped |
| 3 | Response | JSON `{"success":true,"is_active":false,"message":"Mapping deactivated."}` |

### TC-D01 — Remove mapping (HARD delete — BUG-BA-012 proof)
| Step | Action | Expected (current behaviour) |
|------|--------|------------------------------|
| 1 | Create a mapping | row present |
| 2 | Remove it (trash button → SweetAlert `Remove Mapping?` → confirm) | flash `Mapping removed.` |
| 3 | DB check | `SELECT COUNT(*) FROM ba_class_category_jnt WHERE id=?` → **0** (row physically gone; no `deleted_at`) |
| 4 | Note | `withTrashed()/restore()/forceDelete()` are unavailable — model lacks the trait |

### TC-N01/N02 — Required + duplicate (DB layer)
| TC | Action | Expected |
|----|--------|----------|
| N01 | Insert with missing class_id or category_id | DB error (SQLSTATE 23000 / NOT NULL) |
| N02 | Insert duplicate `(class_id, category_id)` | `uq_ba_class_cat` → 23000 duplicate |

### TC-N03 — Duplicate mapping via form
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create mapping (Class A, Category X) | row present |
| 2 | Submit the same pair again via Add Mapping | error `This category is already mapped to the selected class.`; row count unchanged |

### TC-N04..N07 — Validation (negative)
| TC | Action | Expected |
|----|--------|----------|
| N04 | Submit with class blank | no row created |
| N05 | Submit with category blank | no row created |
| N06 | POST a non-existent class id (crafted option) | `exists:sch_classes,id` rejects; no ghost row |
| N07 | POST a non-existent category id (crafted option) | `exists:ba_categories,id` rejects; no ghost row |

### TC-N20 — BUG-BA-012 (model missing SoftDeletes) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Inspect `class_uses_recursive(BaClassCategoryJnt)` | `SoftDeletes` **absent** |
| 2 | Inspect migration | `$table->softDeletes()` present; `deleted_at` column exists |
| 3 | Conclusion | mismatch → `destroy()` is a hard delete |

### TC-D04 — BUG-BA-007 (unmapped class ⇒ empty grid) — proof
| Step | Action | Expected (buggy) |
|------|--------|------------------|
| 1 | Pick a class with no mapping rows | — |
| 2 | DB check | `SELECT COUNT(*) FROM ba_class_category_jnt WHERE class_id=?` → 0 |
| 3 | Downstream | Ratings grid `whereIn(category_id, [])` → blank; requirement wanted all active categories |

### TC-D05 — GAP-BA-CM-01 (unmap has no recorded-grades guard) — proof
| Step | Action | Expected (gap) |
|------|--------|----------------|
| 1 | Inspect `BaClassCategoryController@destroy` | no `ba_assessment_ratings` reference, no "already recorded" message |
| 2 | Remove a mapping | succeeds unconditionally (requirement said it must be blocked when grades exist) |

### TC-D06 — GAP-BA-CM-02 (single-pair form, no session) — proof
| Step | Action | Expected (gap) |
|------|--------|----------------|
| 1 | Inspect `_class-mapping.blade` | single `class_id`/`category_id` selects, no `category_id[]`, no academic-session control |
| 2 | Inspect schema | no `academic_session_id` column on `ba_class_category_jnt` |

### TC-D07 — Same category across two classes
| Step | Action | Expected |
|------|--------|----------|
| 1 | Map Category X to Class A, then to Class B | both inserts succeed (uniqueness is per pair) |

### TC-S01 — Guest redirect
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout; visit `/behavioural-assessment/setup?tab=class-mapping` | redirect to `/login` |

### TC-S02 / TC-S06 — Gates + invalid id
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect controller | `Gate::authorize('…class-categories.{create,status,delete}')` on each write action |
| 2 | Toggle/destroy an unknown id | `findOrFail` → 404; no success payload; no ghost row |

### TC-S03 — Limited user blocked
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as user without `…setup.viewAny`/class-categories perms | setup page → 403 / no "Add Mapping" form |

### TC-S05 — Category name escaped
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect list markup | category name rendered via `{{ $mapping->category?->name }}` (escaped), never `{!! !!}` |

### TC-T01 — Tenant isolation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenancy initialized | `ba_class_category_jnt` resolves in tenant DB; no `tenant_id` column (DB-per-tenant) |
