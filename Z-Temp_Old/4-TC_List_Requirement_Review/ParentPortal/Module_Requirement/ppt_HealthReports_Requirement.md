# ParentPortal — Health Reports (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Health Reports |
| **Alias** | ppt_health |
| **Module** | ParentPortal (PPT) + StudentProfile |
| **Route Prefix** | `/parent-portal/health` |
| **Primary Controller** | `ParentHealthController` |
| **Primary Model** | `StudentHealthProfile` (from StudentProfile module) |
| **Base Table** | `std_health_profiles` |
| **FRD Reference** | REQ-PPT-014 |
| **Priority** | P1 (Should Have) |
| **Type** | Read-only |

## 2. Purpose

Provide parents with a read-only view of their child's health profile, including general health information, physical measurements (height, weight, BMI), and medical records. Access is gated by visibility flags controlled by the school nurse/admin.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| BR-PPT-006 | Medical records visible to parent ONLY if the health record's `parent_visible` flag = 1 | `ParentHealthController::index()` — query filter uses `StudentHealthProfile` which respects `parent_visible` |
| BR-PPT-007 | Counsellor/psychological reports visible ONLY if school setting `parent_counsellor_report_visibility` = 1 (default OFF) | `ParentHealthController` — counsellor reports gated (not directly implemented in controller) |
| BR-PPT-001 | Health data scoped to parent's active linked child | `ParentContextService::resolveChild()` |

## 4. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Health Overview | `parent-portal.health.index` | `index()` | `health/index` | Health profile with BMI calculation |
| Health Detail | `parent-portal.health.show` | `show()` | — (redirect) | Redirects to health.index (single profile per student) |

## 5. Validation Rules

No FormRequests used. The health feature is read-only with no data submission.

## 6. Technical Implementation

### 6.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Modules\StudentProfile\Models\StudentHealthProfile` | Model | Core health profile data |
| `ParentContextService` | Service | Resolves active child |
| HPC Module | Module | Counsellor reports, physical assessments (cross-module) |

### 6.2 Key Implementation Details

- **Health Profile:** Fetches the single `StudentHealthProfile` record for the active child.
- **BMI Calculation:** Auto-calculated when both `height_cm` > 0 and `weight_kg` > 0. BMI = weight_kg / (height_m)², rounded to 1 decimal place.
- **Graceful Empty State:** If no health profile exists for the child, `$health` is null — view handles this gracefully.
- **show() Route:** The `{record}` parameter route intentionally redirects to `health.index` because all health data lives in a single profile per student.
- **Counsellor Reports:** BR-PPT-007 requires checking `sys_school_settings.parent_counsellor_report_visibility`. The controller does not directly implement this check — it relies on the view to gate counsellor content.
- **HPC Module Integration:** The FRD references `hpc_health_profiles`, `hpc_physical_assessments`, and `hpc_counsellor_reports` but the controller only reads from `StudentHealthProfile`. HPC data display depends on view implementation.

### 6.3 Health Profile Fields (StudentHealthProfile)

| Field | Type | Purpose |
|-------|------|---------|
| `student_id` | INT UNSIGNED (FK) | Link to student |
| `blood_group` | VARCHAR | Blood group (e.g., A+, O-) |
| `height_cm` | DECIMAL | Height in centimeters |
| `weight_kg` | DECIMAL | Weight in kilograms |
| `allergies` | TEXT | Known allergies |
| `medical_conditions` | TEXT | Medical conditions |
| `parent_visible` | BOOLEAN | Whether parent can view this record |
| `emergency_contact` | VARCHAR | Emergency contact info |

## 7. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| No health profile exists for child | Graceful empty state; no error |
| Health profile has parent_visible = 0 | Record excluded from results (BR-PPT-006) |
| Height or weight is 0 | BMI calculation skipped; BMI = null |
| show() route called | Redirects to health.index |
| HPC module not active | Graceful degradation — "Feature not available" |

## 8. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | BR-PPT-007 (counsellor report visibility) not enforced in controller — relies on view | Medium | ⬜ |
| 2 | HPC module integration not confirmed — controller only reads StudentHealthProfile | Medium | ⬜ |
| 3 | parent_visible flag check not explicitly in controller — relies on model default scope | Medium | ⬜ |
| 4 | No explicit module check — EnsureTenantHasModule not verified for health routes | Low | ⬜ |
| 5 | show() route accepts {record} parameter but ignores it entirely | Low | ⬜ |

## 9. Cross-Module Impact

| Module | Impact |
|--------|--------|
| StudentProfile | StudentHealthProfile model and table |
| HPC | Counsellor reports, physical assessments (if integrated in view) |
| SystemConfig | sys_school_settings for counsellor visibility toggle |

## 10. Route Reference

```php
Route::prefix('health')->name('health.')->group(function () {
    Route::get('/', [ParentHealthController::class, 'index'])->name('index');
    Route::get('/{record}', [ParentHealthController::class, 'show'])->name('show');
});
```

## 11. Middleware Stack

```
web → InitializeTenancyByDomain → PreventAccessFromCentralDomains
→ EnsureTenantIsActive → auth → verified → ParentPortalMiddleware
```

## 12. Controller Constructor Dependencies

```php
public function __construct(
    private readonly ParentContextService $context,
) {}
```

## 13. Audit Logging

- Event types: `Viewed` (index, show)
- Context: student_id, student_name, module, route

## 14. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| IDOR (access another child's health data) | ParentContextService resolves active child; no direct ID parameter in health.index |
| Data visibility bypass | parent_visible flag on StudentHealthProfile (model-level) |
| Counsellor report privacy | Should be gated by school setting (view-level) |

## 15. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| "HPC module read-view" | Controller uses StudentHealthProfile, not HPC models | May not match HPC data sources |
| "Physical assessment data" | Not fetched from hpc_physical_assessments | Missing HPC integration |
| "Counsellor reports gated by school setting" | Not enforced in controller | View-level only |
| "HPC PDF report downloadable" | Not implemented | Missing download endpoint |
