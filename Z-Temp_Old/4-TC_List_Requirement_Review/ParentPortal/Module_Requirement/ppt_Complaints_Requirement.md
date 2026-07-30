# ParentPortal — Complaints (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Complaints / Grievances |
| **Alias** | ppt_complaints |
| **Module** | ParentPortal (PPT) + Complaint Module |
| **Route Prefix** | `/parent-portal/complaint` |
| **Primary Controller** | `ParentComplaintController` |
| **Primary Models** | `Complaint`, `ComplaintCategory` (from Modules/Complaint) |
| **Base Table(s)** | `cmp_complaints`, `cmp_complaint_categories` |
| **FRD Reference** | Not explicitly listed in REQ list (inferred from live code) |
| **Priority** | P1 (Should Have) |
| **Type** | Write (Parent submits complaints) |

## 2. Purpose

Allow parents to submit complaints and grievances to the school administration through the Parent Portal. The feature provides a categorized complaint system with hierarchical categories (parent → subcategory), optional anonymous submission, severity/priority assignment, and ticket number tracking.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| — | Parent can view only complaints they created or that reference their child | `ParentComplaintController::index()` — broad query with orWhere |
| — | Anonymous submissions do not record complainant identity | `ParentComplaintController::store()` — `is_anonymous` flag |
| — | Complaint must have at least a valid category_id | `StoreParentComplaintRequest::rules()` — required, exists |
| — | Ticket number auto-generated: `CMP-YYYY-000001` | `ParentComplaintController::store()` — sequential |
| — | Subcategory must be a valid child of ComplaintCategory | `StoreParentComplaintRequest::rules()` — nullable, exists |
| — | Target fields intentionally set to null to prevent payload injection (SEC-PPT-004) | `ParentComplaintController::store()` — target fields nulled |

## 4. Status Workflow

```
[Submitted] → Open (status resolved from sys_dropdown_table)
```

**Note:** The Complaint module's full lifecycle (Open → In Progress → Resolved → Closed) is managed through the admin panel. The parent portal only allows submission and viewing.

## 5. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Complaint List | `parent-portal.complaint.index` | `index()` | `complaint/index` | All complaints created by/for the parent's children |
| New Complaint Form | `parent-portal.complaint.create` | `create()` | `complaint/create` | Category selection, title, description, optional anonymous |
| Store Complaint | `parent-portal.complaint.store` | `store()` | — (redirect) | POST handler |
| Complaint Detail | `parent-portal.complaint.show` | `show()` | `complaint/show` | Single complaint details with status, category, severity |

### AJAX Endpoints

| Route | Method | Controller Method | Purpose |
|-------|--------|-------------------|---------|
| `complaint/ajax/subcategories/{category}` | GET | `getCategories()` | Returns subcategories for selected parent category |
| `complaint/ajax/subcategory-meta/{category}` | GET | `getCategoryMeta()` | Returns severity_level_id and priority_score_id for selected category |

## 6. Validation Rules

### StoreParentComplaintRequest

| Field | Rule | Note |
|-------|------|------|
| `category_id` | `required`, `exists:cmp_complaint_categories,id` | Must be a valid category |
| `subcategory_id` | `nullable`, `exists:cmp_complaint_categories,id` | Optional subcategory |
| `severity_level_id` | `nullable`, `exists:sys_dropdown_table,id` | Auto-resolved from category if null |
| `priority_score_id` | `nullable`, `exists:sys_dropdown_table,id` | Auto-resolved from category if null |
| `title` | `required`, `string`, `max:200` | Complaint title |
| `description` | `nullable`, `string` | Optional description |
| `location_details` | `nullable`, `string`, `max:255` | Optional location |
| `incident_date` | `nullable`, `date` | Optional incident date |

## 7. Technical Implementation

### 7.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Modules\Complaint\Models\Complaint` | Model | Core complaint entity |
| `Modules\Complaint\Models\ComplaintCategory` | Model | Hierarchical category tree (self-referencing via parent_id) |
| `Modules\Complaint\Models\ComplaintAction` | Model | Status change history |
| `ParentContextService` | Service | Resolves active child |
| `sys_dropdown_table` | Table | Status, severity, priority dropdowns |
| `Spatie\MediaLibrary\HasMedia` | Package | Optional complaint image upload |

### 7.2 Key Implementation Details

- **Category Hierarchy:** `ComplaintCategory` supports a self-referencing tree via `parent_id`. Top-level categories have `parent_id = null`. The `scopeParents()` scope filters to parent categories only. Subcategories are loaded AJAX-driven via `getCategories()`.
- **Category Meta:** `getCategoryMeta()` returns the `severity_level_id` and `priority_score_id` from the selected category, which auto-populate in the form.
- **Anonymous Mode:** When `is_anonymous` is true, `complainant_user_id` is set to null and `complainant_name` remains null. Contact info is also nulled.
- **Ticket Number:** Format `CMP-YYYY-000001`. Uses `lockForUpdate()` + while-loop check for uniqueness.
- **Target Field Security:** `target_table_name`, `target_selected_id`, `target_name`, `target_code` are all set to null to prevent payload injection (SEC-PPT-004).
- **File Attachment:** Optional `complaint_img` file upload via Spatie Media Library.
- **Child Ownership:** The index() and show() methods use a broad query that matches complaints where: created_by matches auth user, OR complainant_user_id matches auth user, OR target_selected_id matches child's student_id, OR created_by/complainant_user_id matches child's user_id.
- **Status Resolution:** Status ID is looked up from `sys_dropdown_table` where `key = 'cmp_complaints.status_id'` and `value = 'Open'`.

### 7.3 ComplaintCategory Model Structure

| Field | Type | Purpose |
|-------|------|---------|
| `id` | INT UNSIGNED (PK) | Primary key |
| `parent_id` | INT UNSIGNED (nullable FK) | Self-referencing — null for parent categories |
| `name` | VARCHAR | Category name |
| `code` | VARCHAR | Category code |
| `severity_level_id` | INT UNSIGNED (nullable FK) | Default severity from dropdown |
| `priority_score_id` | INT UNSIGNED (nullable FK) | Default priority from dropdown |
| `is_active` | TINYINT(1) | Active flag |

## 8. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| Submit complaint without selecting category | Validation error on category_id |
| Submit complaint with anonymous flag | Identity not recorded; contact nulled |
| System dropdown for complainant_type not found | Error message: "Complainant type not found" — input preserved |
| System dropdown for status not found | Error message: "Default complaint status not found" — input preserved |
| View complaint from different parent | Filtered out by the query — not visible |
| Submit with subcategory that doesn't belong to selected parent category | Cross-validation not enforced at FormRequest level (only exists check) |
| File upload fails during storage | Exception caught; DB rolled back; error message shown |

## 9. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | No FormRequest validation ensuring subcategory belongs to selected parent category | Medium | ⬜ |
| 2 | Broad query in index()/show() may expose complaints to wrong parents if target fields are populated | Medium | ⬜ |
| 3 | Target fields explicitly nulled to prevent SEC-PPT-004 — means complaints are not associated with any student record directly | Medium | ⬜ |
| 4 | FRD does not include Complaints in REQ list — feature is inferred from controller | Low | ⬜ |
| 5 | No notification dispatch when complaint status changes | Low | ⬜ |
| 6 | complaint_img file upload not tested for large files | Low | ⬜ |

## 10. Cross-Module Impact

| Module | Impact |
|--------|--------|
| Complaint | Primary dependency — all models and tables belong to this module |
| StudentProfile | Child ownership check via ParentContextService |
| SystemConfig | sys_dropdown_table for status/severity/priority resolution |

## 11. Route Reference

```php
Route::resource('complaint', ParentComplaintController::class)->only(['index', 'create', 'store', 'show']);
Route::get('/complaint/ajax/subcategories/{category}', [ParentComplaintController::class, 'getCategories'])
    ->name('complaint.subCategories');
Route::get('/complaint/ajax/subcategory-meta/{category}', [ParentComplaintController::class, 'getCategoryMeta'])
    ->name('complaint.categoryMeta');
```

## 12. Middleware Stack

```
web → InitializeTenancyByDomain → PreventAccessFromCentralDomains
→ EnsureTenantIsActive → auth → verified → ParentPortalMiddleware
→ EnsureTenantHasModule (for parent-portal routes)
```

## 13. Controller Constructor Dependencies

```php
public function __construct(
    private readonly ParentContextService $context,
) {}
```

## 14. Audit Logging

Every controller method logs an activity via `activityLog()` with:
- Event types: `Viewed` (index, create, show), `Submitted` (store), `Fetched complaint subcategories` (getCategories), `Fetched complaint category metadata` (getCategoryMeta)
- Context: student_id, student_name, module, route
- Entity reference: complaint_id, ticket_no, category_id

## 15. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| IDOR (view another parent's complaint) | Filter query limits visibility to own complaints + child-linked complaints |
| CSRF | Laravel CSRF middleware on POST route |
| Payload injection via target fields | Target fields explicitly set to null |
| Anonymous abuse | Anonymous flag respected — complainant identity not stored |
| File upload security | Spatie Media Library with proper validation |

## 16. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| Not listed in FRD REQ list | Full controller and views exist | Feature documented but not in FRD |
| No specific BR for complaints | Rules inferred from controller code | Missing formal BR documentation |
