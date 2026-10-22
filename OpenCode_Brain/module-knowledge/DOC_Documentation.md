# Module Knowledge — Documentation (DOC)

> **Single source of truth for the Documentation module's accumulated knowledge.**
> Seeded 2026-06-29 by Business Analyst from live code (three-way reconcile: migration ↔ model ↔ controller/route), with the V2 Requirement (`DOC_Documentation_Requirement.md`) and V1 screen specs (`Documentation_v2/`) read for intent. All counts verified against the filesystem.

---

## Module Facts

| Fact | Value | Source / Verification |
|---|---|---|
| Module name | Documentation | `module.json` |
| Module code | DOC | `0-Prime_Ai_Detail/module_list.md` |
| Table prefix | `doc_` | migrations |
| Scope | **CENTRAL** (prime / central domain — NOT per-tenant) | routes registered under `central.prime.*`; `created_by` FK → `sys_users`; permissions prefixed `prime.*` |
| Laravel path | `Modules/Documentation/` | filesystem |
| Known completion | ~65% (per V2) — core CRUD + reader functional; security/service/test gaps open | V2 §1; code inspection |
| Controllers | **3** — `DocumentationController`, `DocumentationArticleController`, `DocumentationCategoryController` | `app/Http/Controllers/` |
| Models | **2** — `Article` (`doc_articles`), `Category` (`doc_categories`) | `app/Models/` |
| Policies | **2** — `DocumentationArticlePolicy`, `DocumentationCategoryPolicy` (⚠ orphaned — see Known Gaps) | `app/Policies/` |
| FormRequests | **2** — `ValidateArticleRequest`, `ValidateCategoryRequest` | `app/Http/Requests/` |
| Services | **0** — all business logic in controllers | filesystem (no `Services/` dir) |
| Migrations | **3** — `doc_categories`, `doc_articles`, `doc_article_category_jnt` | `database/migrations/` |
| Seeders | **3** — `DocumentationDatabaseSeeder` (empty stub), `DocArticleSeeder` (20 articles), `DocCategorySeeder` (Introduction tree) | `database/seeders/` |
| Blade views | **15** | `resources/views/` (see inventory below) |
| Web routes (real) | **27** — registered in **global** `routes/web.php` (lines 187–207) under `central.prime.*` | global `routes/web.php` |
| Module routes | `routes/web.php` + `routes/api.php` are **stubs** registering a conflicting `documentations` resource on `DocumentationController` | module routes files |
| Tests | **1 file** — `tests/Unit/DocumentationModuleTest.php`, ~20 structural unit tests; **0 feature/HTTP/security tests** | `grep -c test(|it(` = 20 |
| FRD status | **FRD + Complete Analysis Pack created 2026-06-29** | `DOC_FRD_Complete_2026-06-29.md` |

### Key technology dependencies
- **Spatie MediaLibrary** — featured image (`doc_article_image`, `doc_category_image`), singleFile, 3 conversions (small 100², medium 300², large 600²).
- **Spatie Permission (RBAC)** — `Gate::authorize()` ability strings in controllers; permissions config-driven via `PermissionHelper::flatten('prime')`, seeded in `Modules/Prime/.../RolePermissionSeeder.php` (`$docs = ['documentation-mgt','documentation-category','documentation-article']`).
- **Summernote (CDN)** — WYSIWYG article content editor.
- **`activityLog()` helper** — audit logging on all mutations → `sys_activity_logs`.
- **`mews/purifier`** — REQUIRED for HTML sanitization but **NOT installed** (P0 security gap).

---

## DDL / Schema Inventory (verified against migration source — authoritative)

> ⚠ **Anomaly:** `doc_*` tables exist **only in the module migrations**. They are NOT present in any consolidated DDL master (`prime_db_v4.sql`, `tenant_db_v4.sql`, `global_db_v4.sql` all return 0 hits). The schema has not been folded into the central DDL master yet.
> ⚠ **Correction to V2 §5:** V2 lists PKs/FKs as `BIGINT UNSIGNED`. The migrations actually use `$table->increments('id')` (**UNSIGNED INT**) and `unsignedInteger(...)` for FKs — *not* BIGINT. Use UNSIGNED INT.

### `doc_categories`
PK `id` (UNSIGNED INT, auto-inc) · `name` VARCHAR(150) UNIQUE · `slug` VARCHAR(180) UNIQUE · `parent_id` UNSIGNED INT NULL → `doc_categories.id` **RESTRICT on delete** (self-ref) · `type` ENUM(`documentation`,`blog`,`developer`,`help`) INDEX · `description` TEXT NULL · `meta_title` VARCHAR(255) NULL · `meta_description` VARCHAR(300) NULL · `is_active` BOOL default true · `sort_order` UNSIGNED INT default 0 · timestamps · `deleted_at` (soft delete). Composite index `(type, is_active, sort_order)`.

### `doc_articles`
PK `id` (UNSIGNED INT) · `title` VARCHAR(255) UNIQUE · `slug` VARCHAR(255) UNIQUE · `type` ENUM(`documentation`,`blog`,`developer`,`help`) INDEX · `content` LONGTEXT (raw Summernote HTML) · `excerpt` TEXT NULL · `is_published` BOOL default false · `published_at` TIMESTAMP NULL · `visibility` ENUM(`public`,`client`,`developer`,`internal`,`draft`) default `public` INDEX · `meta_title` VARCHAR(255) NULL · `meta_description` VARCHAR(300) NULL · `canonical_url` VARCHAR(255) NULL · `is_indexable` BOOL default true · `created_by` UNSIGNED INT NULL → `sys_users.id` **nullOnDelete** · timestamps · `deleted_at`. Composite index `(type, is_published, published_at)`.
- ⚠ **No `sort_order` column** — yet `Article::$fillable` lists it and `DocumentationController@mainDoc` / `getArticlesByCategory` call `orderBy('sort_order')` on articles (4 call sites). Confirmed schema/code mismatch.

### `doc_article_category_jnt`
PK `id` (UNSIGNED INT) · `article_id` UNSIGNED INT → `doc_articles.id` **cascadeOnDelete** · `category_id` UNSIGNED INT → `doc_categories.id` **cascadeOnDelete** · timestamps. UNIQUE `(article_id, category_id)`.

### Models — fillable/relationship facts
- **Article**: SoftDeletes + InteractsWithMedia(HasMedia). Fillable includes `sort_order` (no such column) but **not** `is_active`. Casts: `is_published`/`is_indexable`→bool, `published_at`→datetime. Rels: `categories()` BelongsToMany via jnt, `author()` BelongsTo `User` (`created_by`). Scope `published()`. Boot: auto-slug from title. No `$connection` set.
- **Category**: SoftDeletes + InteractsWithMedia. Fillable **omits `sort_order`** (column exists, validated, silently dropped on mass-assign) and has no `created_by` (no such column). Rels: `parent()`, `children()`, `childrenRecursive()`. Scopes `active()`, `type()`. Boot: auto-slug from name. No `$connection` set.

### Views inventory (15)
`index.blade.php` (mgmt hub) · `main-doc/index.blade.php` (reader) · `article/{create,edit,index,show,trash}` (5) · `category/{create,edit,index,show,trash}` (5) · `components/layouts/master` · `partials/{head,footer}` (2).

---

## Known Gaps & Open Issues

### P0 — Critical
- **No HTML sanitization (XSS).** `content` is raw Summernote HTML stored as-is and rendered via `{!! $selectedArticle->content !!}` in the reader and injected via `innerHTML` (after base64 decode) in `displayArticle()` JS. `mews/purifier` not installed. → maps REQ-DOC-012 / BR-DOC-014 / NFR-DOC-001/002.
- **`DocumentationCategoryController@index()` has NO `Gate::authorize()`.** Any authenticated central user can list categories. → BR-DOC-016 / NFR-DOC-004.

### P1 — High
- **Orphaned Policy classes / permission-name nuance.** Controllers call **singular** abilities (`prime.documentation-article.*`, `prime.documentation-category.*`, `prime.documentation-mgt.*`) which **match** the seeded permissions (`RolePermissionSeeder` `$docs` group is singular). The 2 Policy classes reference **plural** abilities (`...articles.*`, `...categories.*`) which are never seeded and never invoked (controllers use string-ability `Gate::authorize`, not model-bound policy authorization). **Net effect:** authorization functions via singular permissions; the policies are dead code. *(This corrects V2's framing that controllers are "wrong/should be plural" — controllers+seeder are internally consistent; the decision is to either delete the plural policies or migrate everything to plural and re-seed.)*
- **`store()` vs `create()` ability split.** `store()` uses a `.store` ability while `create()` uses `.create`; `.store` is not in the standard action set → likely unseeded → `store()` may hard-fail authorization. Needs unifying to `.create`.
- **`uploadImage()` (both controllers) has no Gate check** and allows `max:20048` (~20 MB) with no mime restriction (SVG → XSS vector). Should be `max:2048` + `mimes:jpg,jpeg,png,gif,webp`.
- **`sort_order` missing from `doc_articles`** (column referenced in `orderBy`). New migration required.
- **`sort_order` missing from `Category::$fillable`** (column exists; silently dropped).
- **Form field mismatch:** `article/create.blade.php` (and edit) send `name="categories[]"` but the FormRequest/controller expect `category_ids` → category assignment silently fails. Confirmed at `create.blade.php:84`.
- **`DocumentationController@store/update/destroy` are dead stubs** (Gate call + empty body) exposed by the module stub `documentations` resource route. Implement or remove.

### P2 — Medium
- No service layer (all logic in controllers).
- `created_by` set inside `ValidateArticleRequest::prepareForValidation()` (anti-pattern — belongs in controller).
- No category-tree caching; `getArticlesByCategory()` returns all rows (no pagination).
- Base64 DOM encoding of all article content leaks content into the page.

### Technical Auditor — Complete (Mode X) Audit, 2026-06-29 (issue codes assigned)
Report: `3-Audit_Reports/V1_Jun-2026/Documentation_Complete_Audit_2026-06-29.md`. Health **40/100 (P0-capped)**, Deploy **NO-GO**. 1 P0 · 7 P1 · 5 P2 · 2 P3.
- **SEC-DOC-001 (P0)** Stored XSS — raw `{!! $article->content !!}` (main-doc/index.blade.php:97, article/show.blade.php:128) + base64→`atob`→`innerHTML` (footer.blade.php:239); no purifier, no sanitise at save (controller:65). Victims are authenticated central staff/Super Admins (reader behind `auth`+`documentation-mgt.view`).
- **DATA-DOC-001 (P1)** `doc_articles.sort_order` column does NOT exist yet `orderBy('sort_order')` runs in mainDoc (DocumentationController.php:90) and getArticlesByCategory (:117) → guaranteed SQL 42S22 → reader 500. Also in Article::$fillable (D17).
- **BUG-DOC-001 (P1)** CONFIRMED (escalated from BA "likely"): `store()` gates on `prime.documentation-article.store` / `documentation-category.store`; **`.store` is not in `config/permissionslist.php` `$crud`** (create,view,viewAny,update,delete,restore,forceDelete,import,export,print,status,email-schedule,remark,pdf,edit,approve) so it is never flattened/seeded. Gate::before bypasses Super Admin only → App Maintenance / Content Author roles get 403 on every create. Fix: gate `.create`.
- **BUG-DOC-002 (P1)** article/create.blade.php:84 posts `name="categories[]"` but handler/request read `category_ids` → category selection silently lost on CREATE only (edit.blade.php:69 correctly uses `category_ids[]`).
- **SEC-DOC-002 (P1)** DocumentationCategoryController@index (:18-41) has no Gate.
- **SEC-DOC-003 (P1)** both `uploadImage()` (article :91, category :80) have no Gate.
- **VAL-DOC-001 (P1)** uploads `image|max:20048` (~20MB, SVG allowed) on both controllers; UI says 2MB.
- **SEC-DOC-004 (P1, systemic D30)** both FormRequests `authorize(){return true;}`.
- **DATA-DOC-002 (P2)** Category::$fillable omits `sort_order` (column exists, validated) → silently dropped.
- **DEAD-DOC-001 (P2)** DocumentationController@store/update/destroy no-op stubs + create/show/edit return non-existent `documentation::create|show|edit` views, exposed by module `documentations` resource (routes/web.php:7, api.php:7).
- **BUG-DOC-003 (P2)** reader visibility only honours `public` (safe-hidden, but client/developer/internal audiences unsupported).
- **DAT-DOC-003 (P2)** store/update multi-write (model+sync+media) without DB::transaction.
- **PERF-DOC-001 (P2)** getArticlesByCategory unpaginated + uncached category tree.
- **ORM-DOC-001 (P3)** models lack `$connection`. **BUG-DOC-004 (P3)** `created_by` set in ValidateArticleRequest::prepareForValidation (anti-pattern; not a spoof — merge overrides client value).

### P3 — Low / Tech-debt
- No `$connection` on models (could query wrong DB).
- Module routes not consolidated into module's own `web.php`; stub resource route conflicts.
- No article versioning, no view-count, no orphaned-Summernote-image cleanup, no reader search.
- `doc_*` tables not folded into the consolidated central DDL master.

---

## Design Decisions Made
- **Central-only scope.** Tables live on the central/prime side (referenced via `sys_users`, `prime.*` permissions, `central.prime.*` routes). No tenant isolation, no academic-year scoping (not academic data).
- **Config-driven ENUMs.** `type` (4 values) and `visibility` (5 values) are fixed in migration ENUMs (not D29 dropdown masters) — extending requires a migration.
- **Scheduled publish by query-time evaluation.** `scopePublished()` hides future-dated articles at read time; no cron needed.
- **Soft-delete-with-deactivate pattern.** Destroy sets `is_published=false` (article) / `is_active=false` (category) *before* `delete()`.

## Cross-Module Dependencies
- **Inbound (reads):** `sys_users` (article author), Spatie Permission tables (RBAC), `sys_activity_logs` (writes audit).
- **Outbound (feeds):** none (no events emitted; no other module consumes documentation content).
- **External packages:** spatie/laravel-medialibrary (installed), Summernote (CDN), `mews/purifier` (NOT installed — required).

## Lessons Learned
- `[2026-06-29 | Business Analyst]` V2 §5 mislabels PK/FK types as BIGINT; the migrations use `increments`/`unsignedInteger` = UNSIGNED INT. Always three-way reconcile DDL↔migration↔model — migration wins for "what exists".
- `[2026-06-29 | Business Analyst]` The "singular vs plural permission" issue is more subtle than V2 states: controllers + seeder agree (singular) and authorization *works*; the **plural Policy classes are the orphaned/dead artifacts**. The genuine risk is the missing gate on `Category@index` and the `.store` ability that is likely unseeded.
- `[2026-06-29 | Business Analyst]` `doc_*` schema lives only in module migrations, absent from all consolidated DDL masters — a sync gap to flag to DB Architect.
- `[2026-06-29 | Technical Auditor]` The `.store` ability split is a CONFIRMED P1, not a maybe: `config/permissionslist.php` `$crud` has no `store` action, so `prime.documentation-*.store` is never flattened or seeded; only Super Admin (Gate::before) can create — App Maintenance/Content Author are 403'd. Always verify a controller's `Gate::authorize('x.y.action')` string against `config/permissionslist.php $crud`, not just the seeder role groups.
- `[2026-06-29 | Technical Auditor]` `sort_order` is the inverse defect on the two tables: doc_ARTICLES has it in `$fillable`+`orderBy` but NO column (runtime crash); doc_CATEGORIES has the column but NOT in `$fillable` (silently dropped). Easy to conflate — they are two separate fixes (add column to articles; add fillable to categories).
- `[2026-06-29 | Technical Auditor]` Field-name mismatch was create-only: `categories[]` on create.blade.php vs `category_ids[]` on edit.blade.php — edit works, create loses the selection. Check create AND edit blades separately.

## Pending Next Steps
1. DDL Schema Gap Analysis → DB Architect (add `sort_order` to `doc_articles`; reconcile `doc_*` into central DDL master; resolve `created_by` on categories decision).
2. Application Code Gap → Technical Auditor (FRD-driven: XSS, gate on `Category@index`, `.store` ability, uploadImage hardening, dead stubs).
3. Business-Rule Enforcement audit (sanitization BR-DOC-014, visibility access matrix).
4. Test Coverage Gap → Testing Architect (0 feature/security tests today).

## Version History
| Date | Agent | Change |
|---|---|---|
| 2026-06-29 | Business Analyst | Seeded from live code + V2/V1; created FRD + Complete Analysis Pack (`DOC_FRD_Complete_2026-06-29.md`). Counts verified against filesystem. |
| 2026-06-29 | Technical Auditor | Mode X (Complete) audit. 1 P0 / 7 P1 / 5 P2 / 2 P3; Health 40/100 (P0-capped); Deploy NO-GO. Assigned codes SEC/BUG/DATA/VAL/DEAD/DAT/PERF/ORM-DOC-001…. Report `3-Audit_Reports/V1_Jun-2026/Documentation_Complete_Audit_2026-06-29.md`. Confirmed `.store` ungranted (BUG-DOC-001) and reader sort_order crash (DATA-DOC-001). |
