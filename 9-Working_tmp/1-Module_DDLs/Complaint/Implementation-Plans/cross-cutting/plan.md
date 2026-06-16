# Cross-Cutting — Implementation Plan

## Purpose
Items that span multiple tabs: migrations for all tables, FormRequest pattern across all entities, automated test infrastructure, and column name alignment.

---

## Item 1: No FormRequest Classes (All Tabs)

**Source:** `Requirements/*.md` — all CRUD specs imply validation classes

**Current Behavior:** All 4 controllers (Category, SLA, Complaint, MedicalCheck) use `$request->validate([...])` inline. No `app/Http/Requests/` directory exists.

**Implement — Create all 9 FormRequest files:**

| File | For Controller | Key Validations |
|------|---------------|-----------------|
| `StoreComplaintCategoryRequest.php` | CategoryController::store | Escalation chain (gt:), code unique, parent exists |
| `UpdateComplaintCategoryRequest.php` | CategoryController::update | Same + parent not self (not_in), code unique ignore self |
| `StoreDepartmentSlaRequest.php` | DepartmentSlaController::store | Escalation chain, at least one target field |
| `UpdateDepartmentSlaRequest.php` | DepartmentSlaController::update | Same as store |
| `StoreComplaintRequest.php` | ComplaintController::store | Complainant type logic, category required, target required |
| `UpdateComplaintRequest.php` | ComplaintController::update | Change detection, category reassignment |
| `UpdateComplaintStatusRequest.php` | ComplaintController (status update) | FSM transition validation, resolution validation |
| `StoreMedicalCheckRequest.php` | MedicalCheckController::store | Check type dropdowns, complaint linkage |
| `UpdateMedicalCheckRequest.php` | MedicalCheckController::update | Same as store |

**Pattern:**
```php
// StoreComplaintCategoryRequest.php
public function rules(): array
{
    return [
        'parent_id'              => 'nullable|exists:cmp_complaint_categories,id',
        'name'                   => 'required|string|max:100',
        'code'                   => 'nullable|string|max:30|unique:cmp_complaint_categories,code',
        'expected_resolution_hours' => 'required|integer|min:1',
        'escalation_hours_l1'    => 'required|integer',
        'escalation_hours_l2'    => 'required|integer|gt:escalation_hours_l1',
        'escalation_hours_l3'    => 'required|integer|gt:escalation_hours_l2',
        'escalation_hours_l4'    => 'required|integer|gt:escalation_hours_l3',
        'escalation_hours_l5'    => 'required|integer|gt:escalation_hours_l4',
    ];
}

public function authorize(): bool
{
    return Gate::allows('tenant.complaint-category.store');
}
```

---

## Item 2: Migrations Exist — but May Need Schema Fixes

**Current Behavior:** 7 migration files exist in `database/migrations/tenant/`:

| File | Table |
|------|-------|
| `2025_12_22_060146_create_complaint_categories_table.php` | `cmp_complaint_categories` |
| `2025_12_22_065413_create_complaints_table.php` | `cmp_complaints` |
| `2025_12_22_070357_create_complaint_actions_table.php` | `cmp_complaint_actions` |
| `2025_12_22_072653_create_medical_checks_table.php` | `cmp_medical_checks` |
| `2025_12_22_074156_create_ai_insights_table.php` | `cmp_ai_insights` |
| `2025_12_25_062953_create_department_slas_table.php` | `cmp_department_sla` |
| `2026_05_07_200000_fix_cmp_complaints_missing_columns.php` | Fix: adds `target_table_name`, `target_selected_id`, `target_code`; makes columns nullable |

**Issues Found:**
- `cmp_complaint_categories.code` has **no unique index** — column is nullable but missing `->unique()`
- The DDL doc (`cmp_requirement.md` + v2 DDL) uses different column names (`default_expected_resolution_hours`, `default_escalation_hours_l1`, `target_selected_id`, `current_escalation_level`) but migrations match the **model** names — so no rename needed

**To Implement:**
- [ ] Add unique index on `code` column in categories table via new migration
- [ ] Update DDL doc to match actual migration column names
- [ ] Update `cmp_requirement.md` section 2.2 field list to match real schema

---

## Item 3: Column Name Alignment — DDL Doc Out of Sync with Migrations

**Current Behavior:** Migrations (`database/migrations/tenant/`) use the same column names as models — **no mismatch exists between code and DB**. However, the DDL doc (`cmp_requirement.md` section 2.2 and v2 DDL) lists different names:

| Model + Migration Uses | DDL Doc Says | Action |
|------------------------|-------------|--------|
| `target_id` | `target_selected_id` | Migrations are correct. Update DDL doc. |
| `escalation_level` | `current_escalation_level` | Migrations are correct. Update DDL doc. |
| `expected_resolution_hours` | `default_expected_resolution_hours` | Migrations are correct. Update DDL doc. |
| `escalation_hours_l1..l5` | `default_escalation_hours_l1..l5` | Migrations are correct. Update DDL doc. |

**To Implement:**
- [ ] Update `cmp_requirement.md` section 2.2 field names to match actual migration/model names
- [ ] Update DDL v2 script to match

---

## Item 4: No Automated Tests (All Tabs)

**Current Behavior:** Only browser tests exist at project level (`tests/Browser/Modules/Complaint/`). Zero feature/unit tests in `Modules/Complaint/tests/`.

**Implement:**

### Feature Tests
| Test File | Coverage |
|-----------|----------|
| `ComplaintCategoryCrudTest.php` | CRUD + escalation chain + force delete child check + status toggle |
| `DepartmentSlaCrudTest.php` | CRUD + escalation chain + target specificity |
| `ComplaintCrudTest.php` | CRUD + ticket number format + image upload |
| `ComplaintStatusWorkflowTest.php` | Valid/invalid transitions + resolution validation |
| `EscalationProcessingTest.php` | Scheduled command + level changes + event dispatch |
| `MedicalCheckCrudTest.php` | CRUD + Spatie media upload + conversions |

### Unit Tests
| Test File | Coverage |
|-----------|----------|
| `SlaResolutionServiceTest.php` | Specificity scoring, fallback, edge cases |
| `AiInsightEngineTest.php` | Sentiment keywords, risk formula, safety mapping |
| `StatusWorkflowServiceTest.php` | All transition combinations |

---

## Item 5: ComplaintPolicy::create() Wrong Permission

**Current Behavior:** `ComplaintPolicy::create()` checks `tenant.vendor-dahsboard.create`.

**Fix:**
- [ ] Change to `tenant.complaint.create`

---

## Implementation Sequence

### Sprint 1 — Foundation
1. Fix `ComplaintPolicy::create()` permission (5 min)
2. Convert `logAction()` to Eloquent (1 hr)
3. Create FormRequest classes for all entities (4 hrs)

### Sprint 2 — Migrations + Column Names
4. Create 6 migration files (3 hrs)
5. Resolve column name mismatches (1 hr)

### Sprint 3 — Fill Stubs
6. ComplaintActionController full CRUD (2 hrs)
7. AiInsightController full CRUD (2 hrs)
8. ComplaintDashboardController → real data (2 hrs)

### Sprint 4 — Tests
9. Feature tests for all tabs (8 hrs)
10. Unit tests for services (4 hrs)
