# 04 — Bug Report

## Summary

| Severity | Count |
|----------|-------|
| Critical | 2 |
| High | 1 |
| Medium | 3 |
| Low | 2 |
| **Total** | **8** |

---

## BUG-001: Missing Model Imports in AppServiceProvider (Runtime Crash)

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **File** | `app/Providers/AppServiceProvider.php`, lines 525, 537, 538, 547 |
| **Method** | `AppServiceProvider::boot()` |
| **Problem** | Three models are used in `Gate::policy()` calls but never imported: `TptVehicleFuel`, `AttendanceDevice`, and `TptFineMaster`. This will throw a `Class not found` fatal error the first time any authorization check hits these policies, crashing the entire request. Since this is in `boot()`, it may crash on every request depending on PHP's deferred class resolution. |
| **Fix** | Add the missing `use` statements: `Modules\Transport\Models\TptVehicleFuel`, `AttendanceDevice`, `TptFineMaster`. |

---

## BUG-002: Duplicate Policy Registration Overwriting Previous Policies

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **File** | `app/Providers/AppServiceProvider.php`, multiple lines |
| **Method** | `AppServiceProvider::boot()` |
| **Problem** | Laravel's `Gate::policy()` maps one model to one policy. When the same model class is registered with multiple policies, only the LAST registration wins. The following models are registered multiple times with different policies: |

**Affected Models:**
- `QuestionBank::class` registered 3 times (lines 441, 447, 668) — only `AIQuestionPolicy` survives, `QuestionBankPolicy` and `AiQuestionGeneratorPolicy` are silently lost.
- `Competencie::class` registered 3 times (lines 457, 488, 586) — only `CompetencyTypePolicy` survives.
- `Vehicle::class` registered 5 times (lines 513, 524, 548, 550, 551) — only `UniversalReportPolicy` survives, `VehiclePolicy` is lost.
- `Section::class` registered 3 times (lines 672, 679, 681) — only `SubjectClassMappingPolicy` survives, `SectionPolicy` is lost.
- `PickupPoint::class` registered 3 times (lines 518, 519, 542, 543).
- `TptTrip::class` registered 3 times (lines 544, 564, 569, 587).
- `ClassSection::class` registered 2 times (lines 674, 675).
- `DropdownNeed::class` registered 2 times (lines 618, 619).
- `InvoicingPayment::class` registered 3 times (lines 472, 473, 474).
- `BookAuthors::class` mapped to `CircularGoalsPolicy` and `BokBook::class` mapped to `HpcParametersPolicy` (lines 654-655) — clearly copy-paste errors.

| **Impact** | Authorization for Question Bank CRUD, Vehicle CRUD, Section CRUD, and others is effectively broken. Policies that should protect these resources are silently overwritten. |
| **Fix** | Use a different authorization approach (e.g., direct `Gate::define()` or multiple named abilities) rather than multiple `Gate::policy()` calls for the same model. |

---

## BUG-003: SQL Injection via Incorrect DB::raw Usage

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **File** | `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php`, line 394 |
| **Method** | Reorder method |
| **Problem** | The expression `->update(['ordinal' => -1 * DB::raw('id')])` is syntactically incorrect. The multiplication operator `*` with `DB::raw()` will produce a string concatenation bug, not the intended SQL expression. The update will not set `ordinal` to `-id` as intended. |
| **Fix** | Use `DB::raw('-1 * id')` as the entire value. |

---

## BUG-004: Tenant Migration Pipeline Fully Commented Out

| Field | Detail |
|-------|--------|
| **Severity** | High |
| **File** | `app/Providers/TenancyServiceProvider.php`, lines 33-36 |
| **Method** | `TenancyServiceProvider::events()` |
| **Problem** | `MigrateDatabase`, `CreateRootUser`, `AddOrganizationDetails`, and `SeedDatabase` are all commented out in the `TenantCreated` event pipeline. New tenants get only an empty database with no schema, no root user, and no seed data. Tenant onboarding is completely non-functional through the automated pipeline. |
| **Fix** | Uncomment the necessary jobs, at minimum `MigrateDatabase` and `CreateRootUser`. |

---

## BUG-005: Incorrect Permission Check in TenantController

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **File** | `Modules/Prime/app/Http/Controllers/TenantController.php`, line 77 |
| **Method** | `TenantController::edit()` |
| **Problem** | Uses `Gate::authorize('prime.tenant-group.update')` instead of `prime.tenant.update`. The same wrong permission is used in `update()` (line 88), `completeTenantSetup()` (line 116), and `toggleStatus()` (line 345). A user with tenant-group update permission but NOT tenant update permission can edit tenants. |
| **Fix** | Change to `Gate::authorize('prime.tenant.update')` in all tenant-editing methods. |

---

## BUG-006: Syntax Error in SmartTimetableController

| Field | Detail |
|-------|--------|
| **Severity** | Low |
| **File** | `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`, line 104 |
| **Method** | `SmartTimetableController::index()` |
| **Problem** | Line 104 contains `/$activities = Activity::with(...)` — the forward slash before `$activities` makes this a comment-like construct that will cause a PHP parse error or silently skip the line. |
| **Fix** | Remove the leading `/` character. |

---

## BUG-007: Potential Null Pointer in Student Model

| Field | Detail |
|-------|--------|
| **Severity** | Medium |
| **File** | `Modules/StudentProfile/app/Models/Student.php`, line 214 |
| **Method** | `Student::currentFeeAssignemnt()` |
| **Problem** | `AcademicSession::current()->first()->id` will throw a null pointer exception if there is no current academic session. This is called from a relationship definition, meaning any eager-loading or lazy-loading of this relationship will crash if no session is active. |
| **Fix** | Add null-safe operator: `AcademicSession::current()->first()?->id` |

---

## BUG-008: Duplicate Entries in User $fillable

| Field | Detail |
|-------|--------|
| **Severity** | Low |
| **File** | `app/Models/User.php`, lines 36-53 |
| **Method** | `User::$fillable` |
| **Problem** | `user_type` appears twice (lines 37 and 43) and `two_factor_auth_enabled` appears twice (lines 44 and 51). While not a runtime error, it indicates sloppy maintenance and potential confusion. |
| **Fix** | Remove the duplicate entries. |

---

## Bug Summary Table

| ID | Severity | Category | File | Status |
|----|----------|----------|------|--------|
| BUG-001 | Critical | Missing Imports | AppServiceProvider.php | Open |
| BUG-002 | Critical | Policy Overwrite | AppServiceProvider.php | Open |
| BUG-003 | Medium | SQL Bug | SchoolClassController.php | Open |
| BUG-004 | High | Config Bug | TenancyServiceProvider.php | Open |
| BUG-005 | Medium | Wrong Permission | TenantController.php | Open |
| BUG-006 | Low | Syntax Error | SmartTimetableController.php | Open |
| BUG-007 | Medium | Null Pointer | Student.php | Open |
| BUG-008 | Low | Duplicate Fillable | User.php | Open |
