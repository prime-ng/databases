# Route & Policy Migration Report
## Execution of: `6-Working_with_TEAM/3-Shailesh/migrate-module-routes-policies_v2.md`

**Date:** 2026-04-02
**Branch:** `Brijesh_RoutePermission` (repo: `/Users/bkwork/Herd/prime_ai_shailesh`)
**Commit:** `df9cae09` — "Upload Route & Permission work"
**Scope:** Laravel App Repo (`/Users/bkwork/Herd/prime_ai_shailesh`)
**Total Files Changed:** 53
**Net Lines:** 3,425 insertions / 3,933 deletions across 53 files

---

## Objective

Migrate all module-specific routes and Gate policies OUT of two central files:
- **Routes:** `routes/tenant.php` → each module's `Modules/{Module}/routes/web.php`
- **Policies:** `app/Providers/AppServiceProvider.php` → each module's `Modules/{Module}/app/Providers/{Module}ServiceProvider.php`

Also update each module's `RouteServiceProvider.php` where needed to apply the correct tenant middleware stack.

---

## 1. Central Files Modified

### 1.1 `app/Providers/AppServiceProvider.php`
**Location:** `/Users/bkwork/Herd/prime_ai_shailesh/app/Providers/AppServiceProvider.php`
**Change Type:** Modification (Major Reduction)
**Size Change:** ~955 lines → 128 lines (−827 lines)

**Deletions (Removed):**
- All `use` imports for module models and module policy classes (~80+ import lines removed)
- All `Gate::policy()` registrations for 26+ modules (~238 policy registrations removed)
- All `Gate::define()` calls for module-specific abilities (except `prime.notification.*` which is cross-module)
- Removed imports: `DriverAttendancePolicy`, `DriverHelperPolicy`, `DriverRouteVehiclePolicy`, `LiveTripPolicy`, `PickupPointPolicy`, `PickupPointRoutePolicy`, `RouteSchedulerPolicy`, `ShiftPolicy`, `TransportDashboardPolicy`, `TripMgmtPolicy`, `TripPolicy`, `VehiclePolicy`, `TptDailyVehicleInspectionPolicy`, `TptVehicleMaintenancePolicy` (all Transport)
- Removed imports: `DropdownNeedMgmtPolicy`, `DropdownNeedPolicy`, `DropdownPolicy` (moved to GlobalMaster)
- Removed imports: `ActionTypePolicy`, `TriggerEventPolicy`, `RuleEngineConfigPolicy` (moved to EventEngine)
- Removed imports: `HomeworkPolicy`, `HomeworkSubmissionPolicy` (moved to LmsHomework)
- Removed model imports: All module model classes (Accounting, Billing, Complaint, Documentation, GlobalMaster, etc.)

**Retained (Intentional Stays):**
| Item | Reason |
|------|--------|
| `Gate::before` Super Admin bypass | Application-wide auth logic |
| `Paginator::useBootstrapFive()` | Global UI setting |
| `Gate::define('prime.notification.viewAny', ...)` | Cross-module: Notification policy used in Prime context |
| `Gate::define('prime.notification.create', ...)` | Cross-module: same |
| `Gate::policy(QuestionBank::class, AIQuestionPolicy::class)` | Cross-module: LmsQuiz policy applied to QuestionBank model |
| `BreadcrumServiceInterface` → `MenuBreadcrumService` binding | Core service binding |

---

### 1.2 `routes/tenant.php`
**Location:** `/Users/bkwork/Herd/prime_ai_shailesh/routes/tenant.php`
**Change Type:** Modification (Major Reduction)
**Size Change:** ~3,024 lines → 224 lines (−2,800 lines)

**Deletions (Routes Removed and Moved):**
All module-specific route groups were removed and replaced with comment markers pointing to each module's `routes/web.php`. Modules affected:
`Complaint`, `Dashboard`, `EventEngine`, `GlobalMaster`, `Hpc`, `Library`, `LmsExam`, `LmsHomework`, `LmsQuests`, `LmsQuiz`, `Notification`, `Payment`, `QuestionBank`, `Recommendation`, `SchoolSetup`, `StudentFee`, `StudentProfile`, `Syllabus`, `SyllabusBooks`, `SystemConfig`, `TimetableFoundation`, `Transport`, `Vendor`, `SmartTimetable`

All controller `use` imports for those modules were also removed.

**Retained (Intentional Stays):**
| Code | Reason |
|------|--------|
| Auth routes (register, login, forgot-password, reset-password, verify-email, confirm-password, logout) | Framework auth scaffolding — must remain in tenant.php |
| `Route::get('/school-setup/student/create1', [StudentController::class, 'create'])` | Cross-module route (SchoolSetup calls StudentProfile controller) |
| Empty `standard-timetable` Route group | Placeholder for future StandardTimetable module |
| Seeder routes (`seeder/run`, `seeder/foundation`, etc.) | Dev/setup utility routes |
| Welcome page `Route::get('/')` | Base tenant homepage |

---

## 2. RouteServiceProvider Files Modified

Two module `RouteServiceProvider.php` files were updated to add the full tenant middleware stack to their route loading. Previously they only used `Route::middleware('web')`, which bypassed tenancy initialization.

### 2.1 `Modules/Complaint/app/Providers/RouteServiceProvider.php`
**Location:** `/Users/bkwork/Herd/prime_ai_shailesh/Modules/Complaint/app/Providers/RouteServiceProvider.php`
**Change Type:** Modification (+18 lines)

**Changes:**
- Added imports: `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`
- Changed `mapWebRoutes()`: `Route::middleware('web')` → `Route::middleware(['web', InitializeTenancyByDomain::class, PreventAccessFromCentralDomains::class, EnsureTenantIsActive::class])`
- Changed `mapApiRoutes()`: Added same tenant middleware to API routes

### 2.2 `Modules/Dashboard/app/Providers/RouteServiceProvider.php`
**Location:** `/Users/bkwork/Herd/prime_ai_shailesh/Modules/Dashboard/app/Providers/RouteServiceProvider.php`
**Change Type:** Modification (+18 lines)

**Changes:** Same as Complaint — added tenant middleware stack to both `mapWebRoutes()` and `mapApiRoutes()`.

---

## 3. Module ServiceProvider Files Modified (Policy Migration)

Each module's `{Module}ServiceProvider.php` was updated with three changes:
1. Added `use Illuminate\Support\Facades\Gate;`
2. Added `use` imports for module models and policy classes
3. Added `$this->registerPolicies();` call inside `boot()`
4. Added `protected function registerPolicies(): void { ... }` method with `Gate::policy()` calls

### 3.1 `Modules/Accounting/app/Providers/AccountingServiceProvider.php`
**Change Type:** Addition (+60 lines)
**Policies Added (17):** FinancialYear, AccountGroup, Ledger, VoucherType, Voucher, VoucherItem, CostCenter, Budget, TaxRate, LedgerMapping, RecurringTemplate, BankReconciliation, AssetCategory, FixedAsset, ExpenseClaim, TallyExportLog, TallyLedgerMapping

### 3.2 `Modules/Billing/app/Providers/BillingServiceProvider.php`
**Change Type:** Addition (+32 lines)
**Policies Added (8):** BillingCycle → BillingCyclePolicy, BilTenantInvoice → BillingManagementPolicy, BilTenantInvoice → InvoicingPolicy, InvoicingAuditLog → InvoicingAuditLogPolicy, InvoicingPayment → ConsolidatedPaymentPolicy, InvoicingPayment → PaymentReconciliationPolicy, InvoicingPayment → SubscriptionPolicy, InvoicingPayment → InvoicingPaymentPolicy

### 3.3 `Modules/Complaint/app/Providers/ComplaintServiceProvider.php`
**Change Type:** Addition (+27 lines)
**Policies Added (6):** Complaint → ComplaintPolicy, ComplaintAction → ComplaintActionPolicy, ComplaintCategory → ComplaintCategoryPolicy, DepartmentSla → DepartmentSlaPolicy, MedicalCheck → MedicalCheckPolicy, AiInsight → AiInsightPolicy

### 3.4 `Modules/Documentation/app/Providers/DocumentationServiceProvider.php`
**Change Type:** Addition (+15 lines)
**Policies Added (2):** DocumentationCategory → DocumentationCategoryPolicy, DocumentationArticle → DocumentationArticlePolicy

### 3.5 `Modules/EventEngine/app/Providers/EventEngineServiceProvider.php`
**Change Type:** Addition (+18 lines)
**Imports Added:** `Gate`, `ActionTypePolicy` (App\Policies), `TriggerEventPolicy` (App\Policies), `ActionType` model, `RuleEngineConfig` model, `TriggerEvent` model, `RuleEngineConfigPolicy` (Modules\LmsHomework\Policies)
**Policies Added (3):** TriggerEvent → TriggerEventPolicy, ActionType → ActionTypePolicy, RuleEngineConfig → RuleEngineConfigPolicy

> **Note:** `RuleEngineConfigPolicy` lives in `Modules\LmsHomework\Policies` — cross-module policy kept here since the model (RuleEngineConfig) belongs to EventEngine.

### 3.6 `Modules/GlobalMaster/app/Providers/GlobalMasterServiceProvider.php`
**Change Type:** Addition (+41 lines)
**Imports Added:** `Gate`, all GlobalMaster models (Country, State, District, City, Board, Module, Plan, ActivityLog), all GlobalMaster policies, plus `Modules\Prime\Models\Dropdown`, `Modules\Prime\Models\DropdownNeed`, `DropdownPolicy`, `DropdownNeedPolicy`, `DropdownNeedMgmtPolicy`
**Policies Added (11):** Country, State, District, City, Board, Module, Plan, ActivityLog, Dropdown, DropdownNeed (×2 — DropdownNeedPolicy + DropdownNeedMgmtPolicy)

> **Note:** `Dropdown` and `DropdownNeed` models are from `Modules\Prime\Models` but their policies are GlobalMaster-owned — registered here by design.

### 3.7 `Modules/Hpc/app/Providers/HpcServiceProvider.php`
**Change Type:** Addition (+39 lines)
**Policies Added (10):** HPC-specific policies including CircularGoals and related models

### 3.8 `Modules/HrStaff/app/Providers/HrStaffServiceProvider.php`
**Change Type:** Addition (+48 lines)
**Imports Added:** `Gate` facade + 13 model imports + 13 policy imports
**Policies Added (13):** EmploymentDetail → EmploymentPolicy, EmployeeDocument → DocumentPolicy, LeaveType → LeaveTypePolicy, LeaveBalance → LeaveBalancePolicy, LeaveApplication → LeaveApplicationPolicy, SalaryStructure → SalaryStructurePolicy, SalaryAssignment → SalaryAssignmentPolicy, ComplianceRecord → CompliancePolicy, PayrollRun → PayrollRunPolicy, Payslip → PayslipPolicy, Form16 → Form16Policy, AppraisalCycle → AppraisalCyclePolicy, Appraisal → AppraisalPolicy

### 3.9 `Modules/Library/app/Providers/LibraryServiceProvider.php`
**Change Type:** Addition (+79 lines)
**Policies Added (22):** Library book catalog, borrowing, member, fine, and report policies

### 3.10 `Modules/LmsExam/app/Providers/LmsExamServiceProvider.php`
**Change Type:** Addition (+40 lines)
**Policies Added (9):** LMS Exam module policies (ExamSchedule, ExamResult, ExamSetting, etc.)

### 3.11 `Modules/LmsHomework/app/Providers/LmsHomeworkServiceProvider.php`
**Change Type:** Addition (+15 lines)
**Imports Added:** `Gate`, `Homework` model, `HomeworkSubmission` model, `HomeworkPolicy`, `HomeworkSubmissionPolicy`
**Policies Added (2):** Homework → HomeworkPolicy, HomeworkSubmission → HomeworkSubmissionPolicy

### 3.12 `Modules/LmsQuests/app/Providers/LmsQuestsServiceProvider.php`
**Change Type:** Addition (+25 lines)
**Policies Added (4):** LMS Quests module policies

### 3.13 `Modules/LmsQuiz/app/Providers/LmsQuizServiceProvider.php`
**Change Type:** Addition (+28 lines)
**Policies Added (5):** LMS Quiz module policies including AssessmentType

### 3.14 `Modules/Prime/app/Providers/PrimeServiceProvider.php`
**Change Type:** Addition (+64 lines)
**Policies Added (14):** Tenant, TenantGroup, SalesPlanAndModuleMgmt, SessionBoardSetup, PrimeActivityLog, PrimeDashboard, PrimeDropdown, PrimeEmail, PrimeMenu, PrimeNotification (Gate::define), PrimeRolePermission, PrimeSetting, PrimeUser, RolePermission

### 3.15 `Modules/QuestionBank/app/Providers/QuestionBankServiceProvider.php`
**Change Type:** Addition (+36 lines)
**Policies Added (8):** QuestionBank-specific policies

### 3.16 `Modules/Recommendation/app/Providers/RecommendationServiceProvider.php`
**Change Type:** Addition (+34 lines)
**Policies Added (7):** Recommendation module policies

### 3.17 `Modules/SchoolSetup/app/Providers/SchoolSetupServiceProvider.php`
**Change Type:** Addition (+69 lines)
**Policies Added (19):** Building, ClassGroup, Organization, OrgGroup, Room, RoomType, StudyFormat, SubjectType, Teacher, User, and additional SchoolSetup policies

### 3.18 `Modules/SmartTimetable/app/Providers/SmartTimetableServiceProvider.php`
**Change Type:** Addition (+15 lines)
**Imports Added:** `Gate`, `Timetable` model, `TtGenerationStrategy` model, `SmartTimetablePolicy`, `TimetableGenerationStrategyPolicy`
**Policies Added (2):** Timetable → SmartTimetablePolicy, TtGenerationStrategy → TimetableGenerationStrategyPolicy

### 3.19 `Modules/StudentFee/app/Providers/StudentFeeServiceProvider.php`
**Change Type:** Addition (+24 lines)
**Policies Added (14):** FeeMaster, FeeStructure, FeeInstallment, FeeInvoice, FeeTransaction, FeeScholarship, FeeConcession, and related policies

### 3.20 `Modules/StudentProfile/app/Providers/StudentProfileServiceProvider.php`
**Change Type:** Addition (+11 lines)
**Policies Added (2):** Student → StudentPolicy, Attendance → AttendancePolicy

### 3.21 `Modules/Syllabus/app/Providers/SyllabusServiceProvider.php`
**Change Type:** Addition (+24 lines)
**Policies Added (15):** Topic, TopicCompetency, Competencie, CompetencyType, ComplexityLevel, QueTypeSpecifity, GradeDivisionMaster, and related syllabus policies

### 3.22 `Modules/SyllabusBooks/app/Providers/SyllabusBooksServiceProvider.php`
**Change Type:** Addition (+12 lines)
**Policies Added (3):** Author → AuthorPolicy, Book → BookPolicy, BookTopicMapping → BookTopicMappingPolicy

### 3.23 `Modules/SystemConfig/app/Providers/SystemConfigServiceProvider.php`
**Change Type:** Addition (+10 lines)
**Policies Added (1):** Menu → MenuPolicy

### 3.24 `Modules/TimetableFoundation/app/Providers/TimetableFoundationServiceProvider.php`
**Change Type:** Addition (+15 lines)
**Policies Added (5):** Day, Period, SchoolTimingProfile, TimingProfile, AcademicSession

### 3.25 `Modules/Transport/app/Providers/TransportServiceProvider.php`
**Change Type:** Addition (+63 lines)
**Policies Added (29):** Full Transport policy suite across 5 groups:
- **Core:** Vehicle (Dashboard + Vehicle), DriverHelper, TptLiveTrip, PickupPoint (×2), PickupPointRoute, Route, Shift, TptVehicleFuel
- **Vehicle Management:** DriverRouteVehicleJnt, TptRouteSchedulerJnt, TptDailyVehicleInspection, TptVehicleServiceRequest (×2 — Request + Approval), TptVehicleMaintenance, AttendanceDevice, TptFineMaster
- **Reports:** Route (performance), PickupPoint (usage + stop analysis), TptTrip (execution), DriverHelper (performance), TptStudentFeeCollection (finance), TptVehicleFuel (cost), Vehicle (×3 — dashboard + notifications + universal), StudentBoardingLog
- **Staff:** TptDriverAttendance
- **Trips:** TptTrip (×3 — trip + approve + legacy), TptTripStopDetail, StudentBoardingLog, TptTripIncidents
- **Student Fees:** TptStudentAllocationJnt, TptFeeMaster, TptStudentFineDetail, TptStudentFeeCollection, StudentPayLog

> **Note:** All Gate::policy calls use **Fully Qualified Class Names (FQCN)** — no `use` imports needed in TransportServiceProvider.

### 3.26 `Modules/Vendor/app/Providers/VendorServiceProvider.php`
**Change Type:** Addition (+16 lines)
**Policies Added (7):** Vendor, VendorAgreement, VendorInvoice, VendorPayment, VndItem, VndUsageLog → respective policies, VendorDashboard policy

---

## 4. Module Route Files Modified

Routes were moved FROM `routes/tenant.php` INTO each module's `Modules/{Module}/routes/web.php`. The module's existing `RouteServiceProvider` loads these routes with the tenant middleware stack.

| Module | File | Lines Changed | Notes |
|--------|------|:-------------:|-------|
| Complaint | `Modules/Complaint/routes/web.php` | 174 | Full complaint routes including AiInsight, ComplaintAction, ComplaintCategory, DepartmentSla, MedicalCheck |
| Dashboard | `Modules/Dashboard/routes/web.php` | 27 | Dashboard + all-notifications route |
| EventEngine | `Modules/EventEngine/routes/web.php` | 30 | TriggerEvent, ActionType, RuleEngineConfig routes |
| GlobalMaster | `Modules/GlobalMaster/routes/web.php` | 57 | Country, Language, ActivityLog, Dropdown routes |
| Hpc | `Modules/Hpc/routes/web.php` | 265 | Full HPC route suite (PDF generation, web forms, learning activities) |
| Library | `Modules/Library/routes/web.php` | 268 | Full library management routes |
| LmsExam | `Modules/LmsExam/routes/web.php` | 126 | LMS Exam creation, scheduling, result routes |
| LmsHomework | `Modules/LmsHomework/routes/web.php` | 56 | Homework CRUD + submission routes |
| LmsQuests | `Modules/LmsQuests/routes/web.php` | 57 | Quests management routes |
| LmsQuiz | `Modules/LmsQuiz/routes/web.php` | 65 | Quiz creation and assessment routes |
| Notification | `Modules/Notification/routes/web.php` | 112 | Full notification management routes |
| Payment | `Modules/Payment/routes/web.php` | 18 | Payment gateway + transaction routes |
| QuestionBank | `Modules/QuestionBank/routes/web.php` | 86 | Question management, AI generation routes |
| Recommendation | `Modules/Recommendation/routes/web.php` | 91 | Recommendation engine routes |
| SchoolSetup | `Modules/SchoolSetup/routes/web.php` | 278 | Full school setup routes (buildings, classes, subjects, staff, infra) |
| StudentFee | `Modules/StudentFee/routes/web.php` | 142 | Fee masters, structures, invoices, transactions, scholarships |
| StudentPortal | `Modules/StudentPortal/routes/web.php` | 7 | Student portal entry routes |
| StudentProfile | `Modules/StudentProfile/routes/web.php` | 155 | Student CRUD, attendance, document routes |
| Syllabus | `Modules/Syllabus/routes/web.php` | 174 | Syllabus, topics, competencies, complexity routes |
| SyllabusBooks | `Modules/SyllabusBooks/routes/web.php` | 50 | Book catalog, author, topic mapping routes |
| SystemConfig | `Modules/SystemConfig/routes/web.php` | 15 | Menu management routes |
| Transport | `Modules/Transport/routes/web.php` | 288 | Full transport suite (vehicles, routes, trips, fees, attendance, reports) |
| Vendor | `Modules/Vendor/routes/web.php` | 69 | Vendor management, agreements, invoicing routes |

**Modules with NO route file changes** (routes were already in module files before this migration):
- Accounting, Billing, Documentation, HrStaff, SmartTimetable, TimetableFoundation

---

## 5. What Was Intentionally NOT Migrated

### Routes Kept in `routes/tenant.php`
| Route | Reason |
|-------|--------|
| Auth routes (login, register, logout, password reset, email verification) | Laravel framework auth scaffold — must stay in central tenant routes |
| `GET /school-setup/student/create1` → `StudentController@create` | Cross-module: SchoolSetup URL prefix + StudentProfile controller — kept as comment-documented cross-module route |
| `GET /` → welcome view | Base tenant landing page |
| Seeder routes (`seeder/*`) | Dev utility — not module-specific |

### Policies Kept in `AppServiceProvider.php`
| Policy Registration | Reason |
|--------------------|--------|
| `Gate::define('prime.notification.viewAny', PrimeNotificationPolicy)` | Cross-module Gate::define (not Gate::policy) — Notification policy used as a named Gate ability across modules |
| `Gate::define('prime.notification.create', PrimeNotificationPolicy)` | Same |
| `Gate::policy(QuestionBank::class, AIQuestionPolicy::class)` | Cross-module: `AIQuestionPolicy` is owned by `LmsQuiz` module but registered against `QuestionBank` model — cannot cleanly live in either module alone |

### Modules with No Policy Migration
| Module | Reason |
|--------|--------|
| Dashboard | No `app/Policies/` directory — no policies to migrate |
| Notification | Policies handled via `Gate::define` in AppServiceProvider (cross-module); `PrimeNotificationPolicy` intentionally stays central |
| Payment | No `app/Policies/` directory — no policies to migrate |
| StandardTimetable | No dedicated ServiceProvider for standard timetable; empty placeholder route group in tenant.php |

---

## 6. Summary Statistics

| Category | Count |
|----------|-------|
| Total files changed | 53 |
| Total lines added | 3,425 |
| Total lines deleted | 3,933 |
| Central files simplified | 2 (`AppServiceProvider.php`, `tenant.php`) |
| RouteServiceProvider files updated (tenant middleware) | 2 |
| Module ServiceProviders updated with policies | 26 |
| Module `routes/web.php` files updated | 23 |
| Total `Gate::policy()` calls migrated | ~238 |
| Total route lines migrated from tenant.php | ~2,800 |
| `AppServiceProvider.php` size reduction | 955 → 128 lines (−87%) |
| `tenant.php` size reduction | 3,024 → 224 lines (−93%) |

---

## 7. Architecture After Migration

```
Before:
  routes/tenant.php          ← All ~3,024 lines of routes (all modules)
  AppServiceProvider.php     ← All ~955 lines of policy registrations

After:
  routes/tenant.php          ← 224 lines (auth + seeder + 2 cross-module routes)
  AppServiceProvider.php     ← 128 lines (Gate::before + 3 cross-module policies)

  Each module owns its own:
    Modules/{X}/routes/web.php                    ← Module routes
    Modules/{X}/app/Providers/{X}ServiceProvider  ← registerPolicies() method
```

Each module ServiceProvider now follows the pattern:
```php
public function boot(): void {
    // ...
    $this->registerPolicies(); // ← Added
}

protected function registerPolicies(): void {
    Gate::policy(Model::class, Policy::class);
    // ...
}
```
