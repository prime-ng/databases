# Prime AI Ecosystem — AI Agent / Team Coding Rules

> **Purpose:** A single, shareable reference of the rules AI agents and human developers must follow when creating or modifying files in the Prime AI, PrimeApp, PrimeAdmin, and pg_demosite projects.
>
> **Scope:** Backend (Laravel), mobile (React Native / Expo), database/schema, testing, security, and multi-tenancy.
>
> **Canonical sources:** `.kimi/rules/`, `prime_ai/.kimi/rules/`, `primeapp/.kimi/rules/`, `Prime_context/.claude/rules/`, and the `memory/` files in each `.kimi/` directory.
>
> **Last Updated:** 2026-06-23

---

## Table of Contents

1. [Golden Rules — Non-Negotiable](#1-golden-rules--non-negotiable)
2. [Multi-Tenancy Rules](#2-multi-tenancy-rules)
3. [Database & Migration Rules](#3-database--migration-rules)
4. [Laravel Backend Rules](#4-laravel-backend-rules)
5. [Security Rules](#5-security-rules)
6. [Frontend / Blade Rules](#6-frontend--blade-rules)
7. [Mobile (React Native / Expo) Rules](#7-mobile-react-native--expo-rules)
8. [Testing Rules](#8-testing-rules)
9. [Schema Sync Rules](#9-schema-sync-rules)
10. [Process & Collaboration Rules](#10-process--collaboration-rules)
11. [Known Critical Issues to Avoid](#11-known-critical-issues-to-avoid)
12. [Quick Checklist for Every PR](#12-quick-checklist-for-every-pr)

---

## 1. Golden Rules — Non-Negotiable

These are absolute blockers for merge. Breaking any of them causes data corruption, security holes, or tenant leakage.

1. **Never mix central and tenant code.**
   - Central models/controllers cannot be used in tenant context and vice-versa.
   - Always verify the current database connection before queries.
   - Use `tenancy()->initialized` checks where ambiguous.

2. **Never modify merged migrations.**
   - Once a migration is merged to `develop`, it is **immutable**.
   - Create new `alter_` migrations for any schema changes.
   - Do not rename, delete, or create `.bk` files inside `database/migrations/tenant/`.
   - `.bk` files in `Modules/{Module}/database/migrations/` are acceptable only as canonical references when the active migration lives in `database/migrations/tenant/`.

3. **Always use table prefixes.**
   - Every table must use its module prefix (`sch_`, `std_`, `tt_`, `fin_`, `bil_`, `sys_`, `glb_`, `prm_`, etc.).
   - Never create tables without a proper prefix or mix prefixes within a module.

4. **Always authorize actions.**
   - Every controller method must have authorization (`authorize()` or policy checks).
   - Never assume the user has permission.

5. **Always use Form Requests.**
   - Never use `$request->all()` directly in controllers.
   - Always create dedicated `FormRequest` classes and validate all input fields.

6. **SoftDeletes + `is_active` on every table.**
   - Every model must use the `SoftDeletes` trait.
   - Every table must have `is_active` (boolean, default `1`).
   - Every query must respect `is_active` unless explicitly including inactive records.

7. **Never use `env()` in routes or controllers.**
   - Always use `config()` instead.
   - `env()` returns `null` after `php artisan config:cache`.

8. **Never put sensitive fields in `$fillable`.**
   - `is_super_admin`, `role_id`, `permissions`, passwords, tokens must not be mass-assignable.
   - Use dedicated methods for sensitive field updates.

9. **Webhook routes must NOT be behind auth middleware.**
   - Payment gateways cannot authenticate.
   - Place webhook routes outside `auth:sanctum` and validate signatures independently.

10. **Always check tenant context.**
    - Before running tenant queries, ensure the tenant is initialized.
    - Central queries must not run in tenant context and vice-versa.

11. **Never trust user input.**
    - Sanitize all input, use parameterized queries, and prevent SQL injection, XSS, and CSRF.

12. **Register policies exactly once.**
    - Each policy must be registered exactly once in the module ServiceProvider.

13. **Use Pest syntax for tests.**
    - Use `it()` / `test()` functions, not `function test_...()`.
    - Use `expect()` assertions.

14. **Migration safety protocol.**
    - Backup before production migrations; test on staging; never run raw SQL on production.

15. **Code review before merge.**
    - All code must be reviewed; security-sensitive changes require security reviewer approval.
    - Test coverage must not decrease; no force push on shared branches.

---

## 2. Multi-Tenancy Rules

We use `stancl/tenancy` v3.9 with a **database-per-tenant** architecture.

1. **Database-per-tenant.** Each school gets its own `tenant_db_{uuid}`.
2. **No `tenant_id` columns.** Isolation is at the database level, not row level.
3. **Strict central/tenant separation.**
   - Central models (`Tenant`, `Plan`, global masters) cannot be queried inside tenant context without `tenancy()->central(...)`.
   - Tenant models (`Student`, `SchoolClass`, etc.) cannot be queried from central context without `tenancy()->initialize($tenant)` or `$tenant->run(...)`.

4. **Migration paths.**
   - Central migrations: `database/migrations/`
   - Tenant migrations: `database/migrations/tenant/`
   - Module migrations must be copied to `database/migrations/tenant/` and the original renamed to `.bk`.

5. **Queue jobs must initialize tenant context.** Use `tenancy()->initialize($tenant)` inside jobs that touch tenant data.

6. **Storage/cache isolation.**
   - Each tenant has its own storage directory.
   - Cache keys must be tenant-prefixed; never share cache keys across tenants.

7. **Mobile API tenant resolution.**
   - Mobile app sends `X-School-Code` header.
   - `tenant.mobile` middleware resolves the tenant; tokens are scoped to a specific tenant.

8. **Super admin bypass.**
   - Super admins live only in `prime_db`.
   - `Gate::before()` allows super admin everywhere; tenant admins are scoped to `tenant_db`.

9. **Resolve tenant dynamically.**
   ```php
   // WRONG
   $tenantId = 'abc-123';

   // CORRECT
   $tenantId = tenant('id');
   $tenant = tenant();
   ```

---

## 3. Database & Migration Rules

### Every table must include these standard columns

```php
$table->id();
$table->timestamps();        // created_at, updated_at
$table->softDeletes();       // deleted_at
$table->boolean('is_active')->default(true);
$table->foreignId('created_by')->nullable()->constrained('sys_users');
$table->foreignId('updated_by')->nullable()->constrained('sys_users');
```

### Naming conventions

- **Tables:** snake_case, plural, module-prefixed (e.g., `tt_activities`, `std_students`).
- **Junction tables:** suffixed with `_jnt` (e.g., `sch_org_academic_sessions_jnt`).
- **Models:** PascalCase, singular, explicit `$table` property (e.g., `protected $table = 'tt_activities';`).
- **Foreign keys:** `{entity}_id` (e.g., `teacher_id`, `class_id`).
- **JSON columns:** `_json` suffix (e.g., `params_json`, `preferred_time_slots_json`).
- **Boolean columns:** `is_` or `has_` prefix (e.g., `is_active`, `has_media`).

### Migration rules

1. **Always use table prefixes.**
2. **Always add indexes** on foreign keys and frequently queried columns.
3. **Match integer widths** to the source DDL (do not blindly use `bigInteger`).
4. **Use `foreignId()->constrained()` only for BIGINT foreign keys.** For other integer widths, use explicit FK definitions.
5. **Use `after()`, `nullable()`, `default()`, and `unique()` appropriately.**
6. **Never modify existing migrations.** Create additive `alter_` migrations instead.
7. **Tenant migrations are the source of truth** for live tenant schema. The v2 consolidated DDL files in `pgdatabase/2-DDL_Tenant_Consolidated/` are canonical references.
8. **Engine & charset:** InnoDB + `utf8mb4`.
9. **Production safety:** backup first, test on staging, use `php artisan migrate` / `php artisan tenants:migrate`, never raw SQL.

### Creating migrations

```bash
# Central
php artisan make:migration create_new_table

# Tenant directly
php artisan make:migration create_new_table --path=database/migrations/tenant

# Via module (recommended), then copy to tenant/ and rename original to .bk
php artisan module:make-migration create_new_table ModuleName
```

---

## 4. Laravel Backend Rules

### Architecture

1. **Thin controllers, fat services.** Controllers receive the request, call a Service, and return a response. All business logic lives in Services.
2. **Always use Form Requests** for validation and authorization.
3. **Always use API Resources** for JSON responses.
4. **Queue heavy operations:** report generation, bulk imports/exports, email, PDF batches, timetable generation.
5. **Use Events/Listeners** for cross-module communication; avoid direct coupling.

### Controller standards

- **Method order:** `index` → `create` → `store` → `show` → `edit` → `update` → `destroy`.
- **Constructor inject** the Service.
- **Authorize first**, then call the Service with `$request->validated()`.

```php
class StudentController extends Controller
{
    public function __construct(private StudentService $service) {}

    public function index(IndexStudentRequest $request)
    {
        $this->authorize('viewAny', Student::class);
        $students = $this->service->getAll($request->validated());
        return view('student.index', compact('students'));
    }

    public function store(StoreStudentRequest $request)
    {
        $this->authorize('create', Student::class);
        $student = $this->service->create($request->validated());
        flash()->success('Student created successfully.');
        return redirect()->route('student.index');
    }
}
```

### Model standards

```php
class Student extends Model implements HasMedia
{
    use SoftDeletes, HasRoles, InteractsWithMedia;

    protected $table = 'std_students';

    protected $fillable = [
        'name', 'email', 'roll_number', 'class_id', 'section_id', 'is_active',
    ];

    protected $casts = [
        'is_active'    => 'boolean',
        'params_json'  => 'array',
        'created_at'   => 'datetime',
        'updated_at'   => 'datetime',
        'deleted_at'   => 'datetime',
    ];

    public function class(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }
}
```

### Service standards

```php
class StudentService
{
    public function __construct(private StudentRepository $repository) {}

    public function getAll(array $filters = []): LengthAwarePaginator
    {
        return $this->repository
            ->filter($filters)
            ->active()
            ->paginate(25);
    }

    public function create(array $data): Student
    {
        return DB::transaction(function () use ($data) {
            $student = $this->repository->create($data);
            $this->assignRollNumber($student);
            return $student;
        });
    }
}
```

### Query rules

1. **Eager load** relationships to prevent N+1.
2. **Use `when()`** for conditional filters.
3. **Paginate** all list endpoints — never return unbounded collections.
4. **Chunk** large datasets (`Student::chunk(500, ...)`).
5. **Use transactions** with explicit `DB::beginTransaction()` / `commit()` / `rollBack()` for multi-step operations.

### Route rules

- **Naming:** `module-name.resource.action` (e.g., `smart-timetable.activity.store`).
- **Tenant routes** in `routes/tenant.php` with `['auth', 'verified']` middleware.
- **Central routes** in `routes/web.php` on the central domain.
- **Module routes** in `Modules/{Module}/routes/web.php` and `api.php`.

### Module rules

1. **Every new feature must be built as a module inside `Modules/`.**
2. **Module naming:** PascalCase singular (e.g., `Student`, `Attendance`, `Examination`).
3. **Module structure:** routes, controllers, models, migrations, seeders, services, requests, views, tests, providers.
4. **Avoid tight coupling** between modules. Use Events/Listeners, service container bindings, and contracts/interfaces.
5. **Register policies** in the module ServiceProvider exactly once.

### Package-specific rules

- **Laravel Sanctum v4:** `auth:sanctum` on all API routes; use token abilities.
- **Spatie Permission v6.21:** `HasRoles` trait on User; guard name `'web'`.
- **Spatie MediaLibrary v11.17:** `InteractsWithMedia` trait; tenant-specific media paths.
- **Maatwebsite Excel v3.1:** dedicated Import/Export classes; queue large imports.
- **DomPDF v3.1:** use table layout for PDFs (no flexbox/grid); watch memory on large PDFs.

---

## 5. Security Rules

### Authentication & Authorization

1. Use **Sanctum** for API authentication.
2. Every controller method must `authorize()` or use a policy.
3. Use Form Request `authorize()` for route-level checks.
4. Super admin bypass must use dual flags (`is_super_admin` + role).
5. Never put `is_super_admin`, `role_id`, or permission IDs in `$fillable`.
6. Rate-limit public endpoints.

### Input Validation

1. Always validate through Form Requests.
2. Always use `$request->validated()` — never pass raw input to models.
3. Use `$fillable` mass-assignment protection; never `$guarded = []`.

### IDOR Prevention

```php
// WRONG
public function showInvoice($id)
{
    $invoice = FeeInvoice::find($id);
    return view('invoice.show', compact('invoice'));
}

// CORRECT
public function showInvoice(FeeInvoice $invoice)
{
    $this->authorize('view', $invoice);
    return view('invoice.show', compact('invoice'));
}
```

### Webhook Security

1. Webhooks must NOT be behind auth middleware.
2. Validate gateway signatures.
3. Implement IP whitelisting.
4. Log all webhook requests.
5. Use idempotency keys to prevent duplicate processing.

### Environment & Configuration

1. Never use `env()` in routes/controllers — use `config()`.
2. Never commit `.env` files.
3. Never hardcode API keys; use `config/services.php`.
4. Encrypt sensitive config at rest.

### File Uploads

1. Validate MIME types and extensions.
2. Limit file sizes.
3. Store outside the web root or serve via signed URLs.
4. Use random filenames to prevent overwriting.

### XSS & CSRF

1. Escape Blade output with `{{ }}`; use `{!! !!}` only for trusted HTML.
2. Sanitize user-generated HTML.
3. Include `@csrf` on all state-changing web forms.
4. API routes are CSRF-exempt because they use token auth.

---

## 6. Frontend / Blade Rules

1. **Use the design system.** Bootstrap 5 + AdminLTE 4 + `ss-*` custom tokens. Reference `design/` for tokens and patterns.
2. **Font Awesome 6 Free** is canonical; prefer Bootstrap Icons in new/refactored code where specified.
3. **Use components** for reusable UI: `<x-backend.components.data-table>`, `<x-backend.components.stat-card>`, `<x-backend.tab.nav-tab>`, etc.
4. **Tab-pane IDs:** must be `{tab}-pane`, with `role="tabpanel"` and `aria-labelledby`.
5. **Breadcrumbs:** use `<x-backend.components.breadcrum>`; never include Dashboard in `:links`; last link has no URL.
6. **Escape output** with `{{ }}`.
7. **Vite** for asset bundling.
8. **Respect `prefers-reduced-motion`** for animations.
9. **Cross-platform consistency:** use only design-token colors; document UI changes in `CHANGELOG.md`.

### Blade template structure

```blade
@extends('layouts.app')

@section('title', 'Students')

@section('breadcrumb')
    <x-breadcrumb :items="[
        ['label' => 'Students', 'url' => route('student.index')],
    ]" />
@endsection

@section('content')
    <x-card>
        <x-slot:header><h3>Students</h3></x-slot>
        <x-table :headers="['Name', 'Roll No', 'Class', 'Actions']">
            @foreach($students as $student)
                <tr>
                    <td>{{ $student->name }}</td>
                    <td>{{ $student->roll_number }}</td>
                    <td>{{ $student->class->name }}</td>
                    <td>
                        <x-button action="edit" :route="route('student.edit', $student)" />
                        <x-button action="delete" :route="route('student.destroy', $student)" />
                    </td>
                </tr>
            @endforeach
        </x-table>
    </x-card>
@endsection
```

---

## 7. Mobile (React Native / Expo) Rules

**Stack:** Expo SDK 54, React Native 0.81, React 19, TypeScript 5.9 (strict), Expo Router (file-based routing).

1. **File-based routing.** Files in `app/` become routes.
2. **Theme tokens.** Use `constants/theme.ts`; never hardcode colors. Support light and dark themes.
3. **Use `Pressable`** for all touch targets.
4. **Always handle loading, error, and empty states** on every screen.
5. **Use `ScreenWrapper`** for safe areas and `AppHeader` / `ScreenHeader` as appropriate.
6. **Pull-to-refresh** is mandatory on all list screens (PrimeAdmin).
7. **API integration:**
   - Base URL `/api/mobile/v1/`
   - Sanctum Bearer token auth
   - `X-School-Code` header for tenant resolution
   - Define TypeScript interfaces; add service methods; handle 401/404/network errors.
8. **File naming:**
   - Screens: PascalCase + `Screen` suffix (e.g., `AttendanceScreen.tsx`)
   - Components: PascalCase (e.g., `StudentCard.tsx`)
   - Hooks: camelCase + `use` prefix (e.g., `useStudentData.ts`)
   - Services: camelCase (e.g., `studentService.ts`)
   - Types: PascalCase (e.g., `Student.ts`)
9. **StyleSheet** with theme-driven styles; no Tailwind.
10. **Secure storage** for tokens; use `expo-secure-store` or equivalent.

### Screen pattern

```typescript
// app/attendance/index.tsx
import { ScreenWrapper } from '@/components/layout/screen-wrapper';
import { ScreenHeader } from '@/components/layout/screen-header';
import { useTheme } from '@/hooks/use-theme';
import { studentService } from '@/services/student-service';

export default function AttendanceScreen() {
  const { colors } = useTheme();
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadAttendance(); }, []);

  const loadAttendance = async () => {
    try {
      setLoading(true);
      setAttendance(await studentService.getAttendance());
    } catch (error) {
      // handle error
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScreenWrapper>
      <ScreenHeader title="Attendance" />
      {/* content */}
    </ScreenWrapper>
  );
}
```

---

## 8. Testing Rules

**Framework:** Pest 4.x. Browser testing: Laravel Dusk v8.3 + Allure.

1. **Use Pest syntax:** `it()` / `test()` functions and `expect()` assertions. No `function test_...()`.
2. **Unit tests:** no database interaction; mock dependencies.
3. **Feature tests:** full request/response cycle; use factories.
4. **Tenant tests:** initialize tenant context with `$tenant->run(...)` or `TenantTestCase`.
5. **Use factories** — never manually create models in tests.
6. **Mock external services** (Razorpay, email, SMS, storage).
7. **One assertion per test** where possible; follow Arrange-Act-Assert.
8. **Coverage targets:** Core 90%+, Financial 85%+, Academic 80%+, Utility 70%+, UI 60%+.
9. **Mobile:** Jest for unit tests; Detox/Maestro for E2E when configured.

```php
it('can create a student in tenant context', function () {
    $tenant = Tenant::factory()->create();
    $user = User::factory()->create();
    $user->assignRole('teacher');

    $tenant->run(function () use ($user) {
        $response = $this->actingAs($user)
            ->post(route('student.store'), [
                'name' => 'Test Student',
                'roll_number' => '001',
                'class_id' => 1,
            ]);
        $response->assertRedirect(route('student.index'));
        expect(Student::where('name', 'Test Student')->exists())->toBeTrue();
    });
});
```

---

## 9. Schema Sync Rules

We maintain a DDL → migration pipeline to keep code aligned with the database.

1. **DDL is the source of truth.** Reference only the v2 consolidated DDLs in `pgdatabase/2-DDL_Tenant_Consolidated/`.
2. **Pipeline order:** DDL Validator → Migration Comparator → Verifier → Model Aligner → Controller Auditor.
3. **Never re-run the same tool** with identical parameters.
4. **Merged migrations are immutable.** Fix drift via `alter_` migrations only.
5. **Match integer widths** exactly; use `foreignId()` only for BIGINT foreign keys.
6. **Expression indexes** and complex constraints go through `DB::statement`.
7. **Ask before destructive changes** (drops, renames, data migrations).
8. **Run `tenants:test-migrate`** after migration changes.

---

## 10. Process & Collaboration Rules

1. **Before starting any task, read the relevant `.kimi/README.md`** and `AGENTS.md` for the project you are working in.
2. **Determine scope first:** central vs tenant.
3. **Update progress tracking.** When completing modules or significant features, update `.kimi/memory/PROGRESS.md` and any relevant `SCREENS.md` / `MODULES.md`.
4. **Update known-issues docs.** If you fix or discover a bug/security issue, update `.kimi/memory/KNOWN_ISSUES.md` or `SECURITY_BUGS.md`.
5. **Keep `.kimi/` and `Prime_context/` authoritative.** Do not modify `.kimi/` or `Prime_context/` unless explicitly asked.
6. **Minimal changes.** Make the smallest change that solves the problem; preserve existing logic in tests.
7. **Follow existing code style.** Run `pint` / `php-cs-fixer` / equivalent formatters where configured.
8. **No force push** on shared branches.

---

## 11. Known Critical Issues to Avoid

| ID | Severity | Issue | Rule to Follow |
|----|----------|-------|----------------|
| BUG-002 | HIGH | Duplicate `Gate::policy()` registrations break auth silently | Register each policy exactly once |
| BUG-004 | HIGH | Tenant migration pipeline commented out — new tenants get empty DBs | Use `database/migrations/tenant/` and run `tenants:migrate` |
| SEC-002 | CRITICAL | `is_super_admin` in User `$fillable` | Never put sensitive fields in `$fillable` |
| SEC-004 | CRITICAL | Payment webhook behind auth middleware | Webhooks must be outside `auth:sanctum` |
| SEC-005 | CRITICAL | Gateway whitelist bypass | Implement IP whitelisting + signature validation |
| SEC-008 | CRITICAL | Unauthenticated seeder/run route exposed | Add proper auth |
| SEC-009 | HIGH | `SmartTimetableController` has zero authorization | Add `authorize()` to every method |
| SEC-011 | HIGH | `env()` used in routes breaks after `config:cache` | Use `config()` only |

---

## 12. Quick Checklist for Every PR

- [ ] Central/tenant scope is correct and verified.
- [ ] All controller methods authorize actions.
- [ ] Form Requests validate and authorize input.
- [ ] No `$request->all()`; only `$request->validated()` reaches Services/Models.
- [ ] No sensitive fields in `$fillable`.
- [ ] No `env()` in routes/controllers.
- [ ] SoftDeletes + `is_active` present on new tables/models.
- [ ] Table prefix used correctly.
- [ ] Migrations are additive; no merged migration edited.
- [ ] API/webhook routes have correct middleware.
- [ ] IDOR checks present on resource access.
- [ ] File uploads validated (type/size/extension/MIME).
- [ ] N+1 prevented via eager loading.
- [ ] Pagination used for list endpoints.
- [ ] Pest tests added/updated and passing.
- [ ] Progress/known-issues docs updated if needed.
- [ ] Code reviewed; coverage did not decrease.

---

## References

- Workspace root: `/home/tarun-chauhan/Desktop/Apps/primeworkspace/`
- Shared rules: `.kimi/rules/`
- Shared memory: `.kimi/memory/`
- Prime AI rules: `prime_ai/.kimi/rules/`
- Prime AI conventions: `prime_ai/.kimi/memory/CONVENTIONS.md`
- PrimeApp rules: `primeapp/.kimi/rules/`
- PrimeAdmin instructions: `primeadmin/AGENTS.md`
- pg_demosite instructions: `pg_demosite/AGENTS.md`
- Legacy Claude rules: `Prime_context/.claude/rules/`
- Design system: `design/`

---

*This document is a consolidated reference. When in doubt, follow the canonical `.kimi/rules/` and `AGENTS.md` files for the specific project you are modifying.*
