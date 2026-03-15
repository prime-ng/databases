# Prime-AI Project Documentation

Auto-generated from full codebase exploration on 2026-03-15.
Use these docs before starting any feature task.

| File | Description |
|------|-------------|
| [01-project-overview.md](01-project-overview.md) | Project identity, tech stack, 3-layer DB, all 27 modules |
| [02-prime-side-structure.md](02-prime-side-structure.md) | Prime/central side — structure, routes, migrations |
| [03-tenant-side-structure.md](03-tenant-side-structure.md) | Tenant/school side — structure, routes, migrations |
| [04-migration-guide.md](04-migration-guide.md) | How to create migrations (prime vs tenant), naming rules |
| [05-model-guide.md](05-model-guide.md) | How to create models, $table, $fillable, SoftDeletes |
| [06-controller-guide.md](06-controller-guide.md) | How to create controllers, CRUD pattern, view namespace |
| [07-blade-views-guide.md](07-blade-views-guide.md) | How to create views, shared components, PDF rules |
| [08-routes-guide.md](08-routes-guide.md) | Route files, naming, prime vs tenant registration |
| [09-artisan-commands-reference.md](09-artisan-commands-reference.md) | All artisan commands (module, migration, cache) |
| [10-new-feature-checklist.md](10-new-feature-checklist.md) | Step-by-step checklist for any new feature |
| [11-all-modules-controllers-models.md](11-all-modules-controllers-models.md) | Full reference: all 27 modules, controllers, models |

## Quick Rules

1. Prime migration -> `database/migrations/` or `Modules/<Name>/database/migrations/`
2. Tenant migration -> `database/migrations/tenant/` **ALWAYS**
3. Models -> `Modules/<Name>/app/Models/`
4. Controllers -> `Modules/<Name>/app/Http/Controllers/`
5. Prime routes -> `routes/web.php`
6. Tenant routes -> `routes/tenant.php`
7. Views -> `Modules/<Name>/resources/views/<feature>/`
8. NEVER mix prime and tenant code
9. NEVER modify existing migrations
