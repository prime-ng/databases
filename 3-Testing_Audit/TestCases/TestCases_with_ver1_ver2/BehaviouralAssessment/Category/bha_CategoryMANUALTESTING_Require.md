# BehaviouralAssessment › Category — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature | Category (+ child Criteria) |
| Screen requirement | `BehaviouralAssessment_v2/03-Categories.md` |
| Index URL | `/behavioural-assessment/masters?tab=categories` |
| Resource URLs | `/behavioural-assessment/categories/{create,{id},{id}/edit,trash}` |
| Controller | `Modules\BehaviouralAssessment\Http\Controllers\BaCategoryController` |
| FormRequest | `BaCategoryRequest` (category) + inline validation (criterion) |
| Policy | `BaCategoryPolicy` (type-hints `Modules\SchoolSetup\Models\User`) |
| Models | `BaCategory` (`ba_categories`), `BaCriterion` (`ba_criteria`) |
| Migrations | `tenant/2026_06_16_130614_create_ba_categories_table.php`, `…_130620_create_ba_criteria_table.php` |
| CRUD type | Full page CRUD (create/edit/show separate pages) + nested criteria (inline forms) + AJAX toggle/reorder |
| Soft Delete | Yes (both tables) |
| Pagination | 15 / page (`cat_page`) |
| Activity Log | None (no observer/event; no dedicated activity table for categories) |
| DB scope | Tenant-side (requires initialized tenant) |
| Prereq | `BehaviouralAssessment` enabled in `modules_statuses.json`; `APP_ENV=testing`; admin user with `tenant.behavioural-assessment.categories.*` |

> **DOC-BA-001:** DDL doc uses `bha_*`; running app uses `ba_*`. All checks below target the live `ba_categories` / `ba_criteria`.

---

## 2. Business Conditions (detail)

**Category fields:** name (req, ≤100), polarity (req, positive|negative — enum order in DB is `negative,positive`), parent_id (nullable, must exist), weight (req, 0–100, DECIMAL(5,2) default 100.00), sort_order (req, 0–255 tinyint, **unique per parent level among non-deleted**), description (nullable), is_active (default true).

**Criterion fields (nested on edit page):** name (req, ≤150), description (nullable), weight (nullable numeric ≥0, default 1.00), sort_order (nullable integer ≥0, default 0), is_active (default true).

**Error messages (verbatim):**
- `sort_order.unique` → "This sort order is already used for another category at the same level."
- Standard Laravel messages for required / max / in / numeric / exists rules (rendered in `.alert-danger` list).

**Flash messages (verbatim):**
- Create → "Category created successfully." · Update → "Category updated successfully."
- Delete → "Category moved to trash." · Restore → "Category restored successfully." · Force-delete → "Category permanently deleted."
- Criterion add → "Criterion added." · update → "Criterion updated." · remove → "Criterion removed."

**Toggle (AJAX) `POST categories/{category}/toggle-status`** → JSON `{success:true, is_active, message:'Category activated.'|'Category deactivated.'}`.
**Reorder (AJAX) `POST categories/reorder`** with `order[]` → JSON `{success:true}`; each id's `sort_order` = its index in `order[]`.

**Lifecycle / cascade flow:**
```
Active category ──toggle──► Inactive ──toggle──► Active
Active/Inactive ──destroy──► (is_active=false) ──► Trashed ──restore──► Present
Trashed ──forceDelete──► GONE  ══DB cascade══► ba_criteria rows hard-deleted
Soft-delete (destroy) does NOT soft-delete child criteria  ◄── BUG-BA-006 (defect)
Parent hard-delete ──SET NULL──► child.parent_id = NULL
```

---

## 3. Test Cases (Step / Action / Expected)

### TC-P11 — Create a category
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin; go to `/behavioural-assessment/categories/create` | Create page; "Category Identity" + "Configuration" sections; "Save Category" button |
| 2 | Enter Name "Digital Citizenship", Polarity "Positive", Sort Order = a free value | Fields accept input |
| 3 | Click "Save Category" | Redirect to masters?tab=categories; flash "Category created successfully." |
| 4 | DB check | `SELECT * FROM ba_categories WHERE name='Digital Citizenship'` → 1 row, polarity='positive', is_active=1, created_by=admin id |

### TC-P14 — Edit / update
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open `/behavioural-assessment/categories/{id}/edit` | Edit page; category name pre-filled |
| 2 | Change Name, click "Update Category" | Flash "Category updated successfully." |
| 3 | DB check | `ba_categories.name` reflects new value; `updated_by`=admin |

### TC-P15/16/17 — Criteria CRUD (nested)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On the edit page, in the "Add New Criterion" form enter Name "Completes assignments on time", Weight 50.00, Order 1 | Fields accept input |
| 2 | Click "Add" | Flash "Criterion added." |
| 3 | DB check | `SELECT * FROM ba_criteria WHERE category_id={id} AND name='Completes assignments on time'` → 1 row |
| 4 | Edit the criterion row name, click the row save (✓) | Flash "Criterion updated." |
| 5 | Click the criterion trash button, confirm SweetAlert | Flash "Criterion removed."; `ba_criteria.deleted_at` set (soft) |

### TC-P18 — Reorder
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `categories/reorder` with `order=[idB, idA]` (authenticated, CSRF) | JSON `{"success":true}` |
| 2 | DB check | `ba_categories.sort_order` = 0 for idB, 1 for idA |

### TC-SM01/02 — Toggle status
| Step | Action | Expected |
|------|--------|----------|
| 1 | On masters?tab=categories, click the `.status-toggle` for an active category | AJAX POST toggle-status |
| 2 | Response | JSON `{success:true, is_active:false, message:'Category deactivated.'}` |
| 3 | DB check | `ba_categories.is_active` = 0 |

### TC-D01 — Soft-delete → restore → force-delete
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a category (Action ▸ Delete, confirm) | Flash "Category moved to trash."; row in `onlyTrashed`, is_active=0 |
| 2 | On trash page, Restore | Flash "Category restored successfully."; row back in default scope |
| 3 | Delete again, then Force-delete from trash | Flash "Category permanently deleted."; row gone from `withTrashed` |
| 4 | DB check | `SELECT * FROM ba_categories WHERE id={id}` (any scope) → 0 rows; child `ba_criteria` rows also gone (cascade) |

### TC-N36 — Duplicate sort_order at same level (negative)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create category A (parent = None, sort_order = 7) | Saved |
| 2 | Create category B (parent = None, sort_order = 7) | `.alert-danger` shows "This sort order is already used for another category at the same level."; no row created |

### TC-N31/32/33/34/35/37 — Validation matrix
| Case | Input | Expected |
|------|-------|----------|
| Name > 100 chars | 130-char name | `.alert-danger`; no row |
| Invalid polarity | injected 'mixed' | `.alert-danger`; no row |
| Weight > 100 | 150 | `.alert-danger`; no row |
| Negative weight | -5 | `.alert-danger`; no row |
| Sort order > 255 | 300 | `.alert-danger`; no row |
| Nonexistent parent_id | injected 99999987 | `.alert-danger`; no row |

### TC-D09 — BUG-BA-006 (soft-delete cascade gap)
| Step | Action | Expected (current defect) |
|------|--------|---------------------------|
| 1 | Create category with 1 criterion | Both active |
| 2 | Delete (soft) the category | Category trashed |
| 3 | DB check | `SELECT deleted_at FROM ba_criteria WHERE category_id={id}` → **NULL** (criterion NOT soft-deleted). Documents BUG-BA-006: no soft-delete cascade |

### TC-D10 — BUG-BA-004 (criterion delete guard missing)
| Step | Action | Expected (current defect) |
|------|--------|---------------------------|
| 1 | Create a criterion (optionally linked to a rating in `ba_assessment_ratings`) | Present |
| 2 | Delete the criterion | Deletes with **no** in-use/ratings guard. Documents BUG-BA-004 |

### TC-S03 — SEC-BA-002 (FormRequest authorize)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect `BaCategoryRequest::authorize()` | Returns bare `true` (no gate); access control relies solely on controller `Gate::authorize`. Documents SEC-BA-002 |

### TC-S01/04 — Auth
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logout, visit `/behavioural-assessment/categories/create` | Redirect to `/login` |
| 2 | Login as user without `categories.create`, visit create | 403 / form not rendered |

### TC-T01 / TC-S05 / TC-S06 — Tenancy & security
| Step | Action | Expected |
|------|--------|----------|
| 1 | Confirm tenant initialized; `ba_categories` has no `tenant_id` column | Tenant-per-DB |
| 2 | Create category with name `<script>window.x=1</script>`, open show | Script not executed (Blade `{{ }}` escaping) |
| 3 | Visit `/behavioural-assessment/categories/98765432` | 404; "Associated Criteria" not rendered |
