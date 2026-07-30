# Routes, Policy & Permission — Test Case Requirement Checklist

> **Module:** Any Prime AI module  
> **Applies to:** `prime_ai/Modules/{Module}`  
> **Architecture:** Multi-tenant (`stancl/tenancy`), `spatie/laravel-permission` (guard: `web`)  
> **Related doc:** `PRIME_AI_CODING_RULES.md`

---

## Routes

- Verify module web routes are in `Modules/{Module}/routes/web.php` and API routes in `Modules/{Module}/routes/api.php`.
- Verify routes are registered through the module `RouteServiceProvider`.
- Verify the route group uses a consistent URL prefix.
- Verify the route group `name` prefix is used and collision-free.
- Verify resource routes cover: `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`.
- Verify additional routes cover: `trash`, `restore`, `forceDelete`, `toggle` / `status`, `import`, `export`, `print`, `pdf`.
- Verify no leftover dev-only routes (seeders, dumps, debug routes).
- Verify no dead routes pointing to unimplemented controller methods.
- Verify tenant web routes have the full tenancy middleware stack:
  - `InitializeTenancyByDomain`
  - `PreventAccessFromCentralDomains`
  - `EnsureTenantIsActive`
  - `EnsureTenantHasModule:{Module}`
- Verify authenticated routes are behind `auth` (and `verified` where required).
- Verify API routes use `auth:sanctum` with token abilities.
- Verify webhook routes are outside `auth` and validate signatures independently.
- Verify no `env()` calls exist in route files — use `config()` only.
- Verify route names follow `{module}.{feature}.{action}` convention.
- Verify no duplicate route names across modules (`php artisan route:list`).
- Verify route model binding uses the correct model and returns 404 for missing/invalid IDs.
- Verify route model binding respects `SoftDeletes` unless `withTrashed()` is intended.
- Verify `php artisan route:cache` runs without errors (no closures in routes).
- Verify URL parameters follow a consistent convention (`{id}` or `{model}`).

## Policy

- Verify a Policy class exists for every model with controller actions.
- Verify the policy is registered in the module `ServiceProvider` exactly once.
- Verify no duplicate/conflicting policies for the same model in different providers.
- Verify the policy is in the correct namespace: `Modules\{Module}\app\Policies`.
- Verify policy implements standard methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`.
- Verify additional methods exist for `status` / `toggle`, `import`, `export`, `print`, `pdf` where applicable.
- Verify every public controller method maps to a policy method.
- Verify every policy method checks the spatie permission via `$user->can(...)` or `$user->hasPermissionTo(...)`.
- Verify Super Admin bypass is handled only via `Gate::before()` or policy `before()`.
- Verify policy methods return strict booleans with no side effects.
- Verify policies contain no business logic — only *who can* decisions.
- Verify policies do not mix central/tenant model checks.
- Verify controller calls `$this->authorize(...)` or Form Request `authorize()` performs the check.
- Verify Form Request `authorize()` does not return bare `true`.

## Permission

- Verify all permission names follow `{module}.{feature}.{action}` format.
- Verify actions used are from the standard set: `create`, `view`, `viewAny`, `update`, `delete`, `restore`, `forceDelete`, `import`, `export`, `print`, `status`, `email-schedule`, `remark`, `pdf`.
- Verify no orphan permissions (seeded but never checked) or phantom permissions (checked but never seeded).
- Verify permissions are seeded via `Permission::firstOrCreate()` with `guard_name => 'web'`.
- Verify module permission source is complete for every screen.
- Verify every seeded role gets permissions through the standard seeder mechanism.
- Verify role permission subsets are intentional.
- Verify system roles (`Super Admin`, `is_system = 1`) cannot be deleted or modified via UI routes.
- Verify `is_super_admin`, `role_id`, and permission IDs are NOT in model `$fillable`.
- Verify assigning/revoking a role clears the spatie permission cache.
- Verify every Create/Edit/Delete/Restore/Force-Delete/Toggle/Import/Export/Print button is wrapped in `@can` or handled by the project's button component.
- Verify menu/sidebar items are rendered only when the user has the corresponding `viewAny` permission.
- Verify breadcrumbs don't expose links to inaccessible screens.
- Verify listing pages with mixed permissions degrade gracefully.
- Verify permission-dependent Blade sections never throw undefined-variable errors when skipped by `@can`.

## Views

- Verify layout component, session alerts, and CSRF meta are present.
- Verify success messages display correctly after Create, Update, Delete, Restore, Force Delete.
- Verify validation errors display in `alert-danger` block and below corresponding fields.
- Verify all dropdowns are populated with expected data.
- Verify form fields are correctly pre-filled on Edit page.
- Verify `old()` input repopulation on validation failure.
- Verify method spoofing (`@method('PUT')`) on edit forms.
- Verify create vs edit form patterns are consistent.
- Verify index views include table, actions, status switch, search/filter.
- Verify show views include detail table, null-safe display, status badges.
- Verify trash views list soft-deleted records with restore/force-delete actions.
- Verify pagination, sorting, search, filter, and reset functionality work.
- Verify modals, confirmation dialogs, and delete confirmations function correctly.
- Verify all routes used in forms and action buttons are correct.
- Verify file/image preview displays correctly on Edit page where applicable.
- Verify no undefined variable, undefined index, or null property errors occur.
- Verify dependent dropdowns and AJAX toggles work via JavaScript.

## Dusk / Browser Test Scenarios

### Route Access

- Guest visits any module route → redirected to login.
- Authenticated user with permission visits route → page loads (HTTP 200), correct view rendered.
- Authenticated user without permission visits route → 403, never 500.
- User visits route with non-existent record ID → 404.
- User visits route with soft-deleted record ID → 404 or redirect to trash.
- Form submission routes (`store`, `update`, `destroy`) work end-to-end with success message and redirect.
- Breadcrumb links navigate to correct routes.
- Action buttons navigate to correct routes.
- Redirect after Create/Update/Delete follows project convention.
- Trash flow: trash loads soft-deleted records; restore returns to listing; forceDelete removes permanently.
- Toggle/status route updates UI immediately.

### Tenant Context

- Tenant A user accesses module routes → works within Tenant A.
- Tenant A user accesses Tenant B record URL → 404.
- Tenant without module subscription visits module routes → blocked by `EnsureTenantHasModule`.
- Module route accessed from central domain → blocked by `PreventAccessFromCentralDomains`.
- Inactive/suspended tenant visits module routes → blocked by `EnsureTenantIsActive`.

### API Routes

- Unauthenticated API request → 401 JSON response.
- Authenticated token without ability → 403 JSON response.
- Valid request → correct JSON structure and status code (`200`/`201`).
- API routes are CSRF-exempt.

### Policy / Permission Matrix

- User with `viewAny` → listing loads, records visible.
- User without `viewAny` → listing returns 403, no data leaked.
- User with only `viewAny` → Create button hidden; `/create` direct URL → 403.
- User with `viewAny` + `view` → detail page loads read-only; Edit button hidden.
- User with `viewAny` + `create` → Create form opens, submits, success message, record visible.
- User with `viewAny` + `update` (no `create`) → Edit works; Create button absent; `/create` → 403.
- User with `viewAny` + `delete` → Delete confirmation; record soft-deleted; success message.
- User with `delete` but no `restore`/`forceDelete` → Trash visible; Restore/Force-Delete hidden; direct URLs → 403.
- User without `status` permission → Toggle switch hidden/disabled; direct toggle URL → 403.
- Super Admin → all actions allowed via `Gate::before` bypass.
- UI visibility matches backend enforcement: hidden button AND blocked direct URL for same action.

### Permission Change Behavior

- Admin revokes permission, user refreshes → button gone, direct URL → 403.
- Admin grants permission, user refreshes → new button/menu item appears.
- User's role changed mid-session → next page load reflects new permissions.

## PR Sign-Off Checklist

**Routes**
- [ ] Module routes in module route files with prefix + name prefix.
- [ ] Full CRUD + trash/restore/forceDelete/toggle routes present.
- [ ] Tenancy middleware stack + `EnsureTenantHasModule` applied.
- [ ] No `env()`, no dev-only routes, no duplicate route names.
- [ ] `route:cache` runs clean.
- [ ] Dusk: guest → login, no-permission → 403, bad ID → 404 verified.

**Policy**
- [ ] Policy exists per model, registered exactly once.
- [ ] All screen-wise methods implemented.
- [ ] Methods check spatie permissions; Super Admin bypass via `Gate::before` only.
- [ ] Every controller method authorizes (or Form Request does).
- [ ] No Form Request `authorize()` returning bare `true`.
- [ ] Dusk: hidden button + blocked direct URL verified for each restricted action.

**Permission**
- [ ] Names follow `{module}.{feature}.{action}`, seeded idempotently.
- [ ] Role subsets intentional; system roles protected.
- [ ] No privilege fields in `$fillable`; cache cleared on role/permission change.
- [ ] `@can` on all action buttons; menu filtered by `viewAny`.
- [ ] Dusk: permission matrix executed for every screen.
- [ ] Dusk: cross-tenant access attempt returns 404.

---

*End of Document*
