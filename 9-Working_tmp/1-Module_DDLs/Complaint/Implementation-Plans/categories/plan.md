# Categories — Implementation Plan

## Purpose
Complaint categories that form a hierarchical taxonomy with default severity, priority, resolution SLA, and escalation timeline. Documented rules not yet implemented.

## Documented But Not Implemented

### Item 1: Category store/update Should Use FormRequest

**Source:** `Requirements/categories.md:70-73` — create with validation, redirect on success/failure

**Current Behavior:** `ComplaintCategoryController::store()` (line 65) and `update()` (line 126) use inline `$request->validate()`.

**Implement:**
- [ ] Create `StoreComplaintCategoryRequest.php` with:
  - `parent_id`: `nullable|exists:cmp_complaint_categories,id`
  - `name`: `required|string|max:100`
  - `code`: `nullable|string|max:30|unique:cmp_complaint_categories,code`
  - `escalation_hours_l1..l5`: `required|integer|gt:previous` (chain)
  - `expected_resolution_hours`: `required|integer|min:1`
- [ ] Create `UpdateComplaintCategoryRequest.php` with same rules plus:
  - `parent_id` excludes self: `not_in:{id}`
  - `code` unique ignores own ID: `unique:cmp_complaint_categories,code,{id}`
- [ ] Replace inline validation in controller with FormRequest injection

### Item 2: Missing Unique Index on `code` Column

**Source:** DDL spec says `code` must be unique

**Current Behavior:** Migration `2025_12_22_060146_create_complaint_categories_table.php` creates `code` as nullable string but **no unique index**. Duplicate codes can be inserted.

**Implement:**
- [ ] Create migration to add unique index: `$table->string('code')->unique()->change();`
- [ ] Handle existing NULL/multiple-NULL issue (MySQL allows multiple NULLs in unique index)

### Item 3: DDL Doc Column Names Out of Sync

**Source:** DDL v2 doc uses `default_expected_resolution_hours` but migration/model use `expected_resolution_hours`. Same for `default_escalation_hours_l1..l5`.

**Current Behavior:** Migrations and models agree — both use `expected_resolution_hours` and `escalation_hours_l1..l5`. Only the DDL doc is wrong.

**Implement:**
- [ ] Update `cmp_requirement.md` field names to match actual migration column names

### Item 4: Event Logging for Change Detection on Update

**Source:** `cmp_requirement.md:146` — "On update, an activity log entry is created recording old and new values for each changed field"

**Current Behavior:** `ComplaintCategoryController::update()` (line 120) captures `$original` but only logs generic "Updated" activity. No per-field change detail is recorded.

**Implement:**
- [ ] Compare `$original` vs `$validated` after update
- [ ] Log each changed field with old/new value in activity log
- [ ] Use pattern: `activityLog($category, 'Updated', ['changes' => $diffs])`

### Item 5: Missing Feature Tests

**Source:** Implied — no tests exist

**Current Behavior:** Zero unit/feature tests for categories.

**Implement:**
- [ ] Create `tests/Feature/Modules/Complaint/ComplaintCategoryCrudTest.php`:
  - Create category with valid data → success
  - Create with escalation chain violation (L1 >= L2) → validation error
  - Create with duplicate code → validation error
  - Update with self-parent → validation error
  - Soft delete → hidden from listing
  - Force delete with children → blocked with error message
  - Force delete without children → success
  - Toggle status AJAX → returns JSON with new state
  - Restore soft-deleted → visible again
