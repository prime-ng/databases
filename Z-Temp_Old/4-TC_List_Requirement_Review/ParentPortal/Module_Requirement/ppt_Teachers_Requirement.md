# ParentPortal — Teachers (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Teacher Contact List |
| **Alias** | ppt_teachers |
| **Module** | ParentPortal (PPT) + TimetableFoundation |
| **Route Prefix** | `/parent-portal/teachers` |
| **Primary Controller** | `ParentTeacherController` |
| **Primary Models** | `Activity`, `ActivityTeacher` (from TimetableFoundation) |
| **Base Table(s)** | `tt_activities`, `tt_activity_teachers`, `users` |
| **FRD Reference** | Not explicitly numbered (inferred from teacher contact context) |
| **Priority** | P1 (Should Have) |
| **Type** | Read-only |

## 2. Purpose

Provide parents with a read-only contact list of all subject teachers assigned to their child's class-section for the current academic term. Teachers are grouped by subject, showing name and subjects they teach.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| BR-PTT-001 | Teachers scoped to the active child's class-section | `Activity::where('class_id', ...)->where('section_id', ...)` |
| — | Only teachers for the current academic term shown | `AcademicTerm::where('is_current', true)` filter on activities |
| — | Only active teachers shown | `$q->where('is_active', true)` on activity teachers |
| — | Only active activities shown | `Activity::where('is_active', true)` |
| — | Teachers sorted alphabetically by name | `sortBy(fn => $entry['teacher']->user?->name ?? '')` |

## 4. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Teacher List | `parent-portal.teachers.index` | `index()` | `teachers/index` | Alphabetical list of teachers with subjects |

## 5. Validation Rules

No FormRequests used — read-only feature with no data submission.

## 6. Technical Implementation

### 6.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Modules\TimetableFoundation\Models\Activity` | Model | Subject-class-section-activity mapping |
| `Modules\TimetableFoundation\Models\AcademicTerm` | Model | Current term resolution |
| `Modules\TimetableFoundation\Models\ActivityTeacher` | Model | Teacher assignment to activities (pivot) |
| `ParentContextService` | Service | Resolves active child |

### 6.2 Key Implementation Details

- **Class Resolution:** Uses the child's current academic session to determine class_id and section_id via `$child->currentSession()->with('classSection')`.
- **Current Term:** Resolves the current academic term for the child's academic session where `is_current = true`.
- **Activity Query:** Fetches all activities for the child's class+section in the current term, with eager-loaded `subject` and `teachers` (with teacher user relation).
- **Teacher Map Construction:** Iterates through all activities and builds a flat teacher map keyed by teacher_id. Each entry holds the teacher model and a collection of subjects they teach. Duplicate subjects per teacher are prevented via `contains()` check.
- **No-Consecutive-Class Guard:** If the child has no class-section assigned (no active session), returns an empty collection with `noClass` flag.
- **Alphabetical Sort:** Teachers are sorted by their user name (ascending).

### 6.3 Data Model Chain

```
Student → StudentAcademicSession → ClassSection
                                         ├── class_id → Class
                                         └── section_id → Section
Activity (class_id, section_id, academic_term_id)
├── subject → Subject
└── teachers → ActivityTeacher[]
    └── teacher → Teacher → User
```

## 7. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| No class-section assigned to child | Empty list with `noClass` flag; no error |
| No current term found | Activities loaded without term filter (all terms shown) |
| Activity has no teachers assigned | Activity skipped in teacher map |
| Teacher has no user relationship | Teacher entry skipped |
| Teacher teaches multiple subjects | All subjects listed under one teacher entry |
| No activities for the class-section | Empty teacher list |
| Multiple teachers for same subject | Both teachers shown with their respective subjects |

## 8. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | No contact information loaded — only teacher name and subjects | Low | ⬜ |
| 2 | No explicit teacher contact info (phone/email) — depends on User model data | Low | ⬜ |
| 3 | FRD doesn't explicitly document this feature | Low | ⬜ |
| 4 | `noClass` flag passed to view but no explicit graceful message defined | Low | ⬜ |

## 9. Cross-Module Impact

| Module | Impact |
|--------|--------|
| TimetableFoundation | Activity and AcademicTerm models |
| SchoolSetup | Class/Section for activity filtering |
| SystemConfig | User model for teacher name resolution |

## 10. Route Reference

```php
Route::get('/teachers', [ParentTeacherController::class, 'index'])->name('teachers.index');
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

- Event type: `Viewed`
- Context: student_id, student_name, module, route

## 14. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| IDOR (view teachers for another child) | ParentContextService resolves active child |
| CSRF | Not applicable (GET-only route) |

## 15. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| Not documented in FRD as standalone REQ | Feature exists as teacher contact list | Missing FRD documentation |
