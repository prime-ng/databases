## Complete Audit — Documentation (DOC) — 2026-06-29      (Mode X: A+B+C+G + scoped D)

**Module:** Documentation · **Code:** DOC · **Prefix:** `doc_` · **Scope:** CENTRAL (prime/central domain — NOT per-tenant)
**App code:** `/Users/bkwork/Herd/prime_ai/Modules/Documentation`
**Baseline (B/C):** `4-Requirement_Module_wise/0-FRD_Documents/DOC_FRD_Complete_2026-06-29.md` (REQ-/BR-/RPT- IDs reused, never renumbered)
**Auditor:** Technical Auditor · **Mode:** X (Complete) · read-only.

---

### Executive Summary
The Documentation module is a small central CRUD + reader knowledge base (3 controllers, 2 models, 3 tables, 0 services, 1 structural test file). It is functionally close but carries a **P0 stored-XSS hole** (Summernote article HTML is stored raw and rendered with `{!! !!}` and via client-side `atob()` → `innerHTML`, with no `mews/purifier` and no sanitisation anywhere), plus a cluster of authorization and correctness defects: the article/category reader pages issue `orderBy('sort_order')` against `doc_articles`, **a column that does not exist** (guaranteed SQL 42S22 crash), every content author who is not a Super Admin is **locked out of creating** content (the controllers gate on a `.store` ability that is never defined or seeded), and the article create form posts categories under the wrong field name so selections are silently lost. **Health: 40/100 (hard-capped — one P0 present). Deploy verdict: NO-GO.**

### Health Score
Weighted layer index = **48/100** before cap; **hard-capped to 40/100** because a P0 (SEC-DOC-001 stored XSS) is present. See Layer Health Summary for the per-layer breakdown.

### Deploy Gate Verdict — **NO-GO**
Blocking items:
- **SEC-DOC-001 (P0)** — stored XSS: unsanitised article HTML rendered raw to authenticated central staff (incl. Super Admins). Account/session compromise of high-privilege users.
Strongly-recommended-before-release (not strict blockers, but each breaks a core path):
- **DATA-DOC-001 (P1)** — reader is a guaranteed 500 (`orderBy('sort_order')` on a non-existent column).
- **BUG-DOC-001 (P1)** — non-super-admin content authors cannot create any article/category (`.store` ability not granted).
- **BUG-DOC-002 (P1)** — article create silently drops category selection.
- **SEC-DOC-002 / SEC-DOC-003 / VAL-DOC-001 (P1)** — ungated category listing, ungated image upload, 20 MB/SVG-permitting upload validation.

Module is CENTRAL — Layer 6 (tenancy) is correctly absent (not a finding). No committed secrets, no queue/Horizon coupling (no jobs), no `env()`-in-routes or route closures in this module's routes. The deploy block is entirely the P0 above.

---

### P0 Findings

```
[SEC-DOC-001] Severity: P0 | Stored XSS — article content stored and rendered without any sanitisation
- Location:
    Modules/Documentation/resources/views/main-doc/index.blade.php:97   {!! $selectedArticle->content !!}
    Modules/Documentation/resources/views/article/show.blade.php:128     {!! $article->content !!}
    Modules/Documentation/resources/views/main-doc/index.blade.php:129   data-article-content="{{ base64_encode($article->content) }}"
    Modules/Documentation/resources/views/partials/footer.blade.php:239  content: decodeURIComponent(escape(atob(this.dataset.articleContent)))  → injected via innerHTML (footer.blade.php:190)
    Store path (no sanitise): DocumentationArticleController.php:65 Article::create($request->validated());  ValidateArticleRequest.php:54 'content' => 'required|string'
- Evidence:
    // reader, server-rendered raw:
    {!! $selectedArticle->content !!}
    // reader, client-rendered raw (footer JS):
    content: decodeURIComponent(escape(atob(this.dataset.articleContent)))   // then articlesList/content pane .innerHTML = ...
- Why it's a risk: Summernote HTML is persisted verbatim (no purifier installed — confirmed: not in composer, FRD §10) and emitted unescaped both server-side (`{!! !!}`) and client-side (`atob` → `innerHTML`). Any `<script>`, `onerror=`, or `javascript:` payload in an article body runs in the browser of every viewer. Because the reader sits behind `auth`+`prime.documentation-mgt.view`, the victims are authenticated central staff (App Maintenance, Super Admins) — so this is a privilege-escalation / admin-session-theft vector, not merely a public defacement.
- Fix: Install `mews/purifier`; sanitise `content` at save (clean in the controller/FormRequest before `create()/update()`) AND render through `clean()`/a purifier on output; stop the base64→innerHTML round-trip or sanitise the decoded HTML before injection. Restrict Summernote's allowed tags/attributes.
- Confidence: High
- Systemic? : Module-local (maps REQ-DOC-012 / BR-DOC-014 / NFR-DOC-001/002 / RISK-DOC-001).
```

---

### P1 Findings

```
[DATA-DOC-001] Severity: P1 | Reader queries orderBy('sort_order') on doc_articles — column does not exist (guaranteed crash)
- Location:
    Modules/Documentation/app/Http/Controllers/DocumentationController.php:90  (mainDoc)
    Modules/Documentation/app/Http/Controllers/DocumentationController.php:117 (getArticlesByCategory)
    Migration: Modules/Documentation/database/migrations/2026_01_09_102846_create_articles_table.php (no sort_order column)
    Model: Modules/Documentation/app/Models/Article.php:21 ('sort_order' in $fillable)
- Evidence:
    ->where('visibility', 'public')
    ->orderBy('sort_order')          // doc_articles has no sort_order column
- Why it's a risk: The migration is authoritative and creates no `sort_order` on `doc_articles`. `mainDoc()` (the reader landing, `documentation-intro`) and `getArticlesByCategory()` (the AJAX topic switch) both order by it → SQLSTATE[42S22] Unknown column 'doc_articles.sort_order' → the entire reader (REQ-DOC-007/008) returns 500. `$fillable` also advertises the non-existent column (D17). (`Category` ordering by `sort_order` is fine — that column exists on `doc_categories`.)
- Fix: Add a migration introducing `doc_articles.sort_order UNSIGNED INT DEFAULT 0` (then it matches the column already on doc_categories and the $fillable/orderBy usage); or remove the `orderBy('sort_order')` on articles and the fillable entry if article ordering is not required.
- Confidence: High
- Systemic? : D17 (model/DDL field mismatch). Maps NFR-DOC-006 / RISK-DOC-004.
```

```
[BUG-DOC-001] Severity: P1 | store() gates on a '.store' ability that is never defined or seeded — all non-super-admin authors locked out of creating content
- Location:
    Modules/Documentation/app/Http/Controllers/DocumentationArticleController.php:63   Gate::authorize('prime.documentation-article.store');
    Modules/Documentation/app/Http/Controllers/DocumentationCategoryController.php:61   Gate::authorize('prime.documentation-category.store');
    Permission catalogue: config/permissionslist.php:13 ($crud action set) + :86-88 (docs features = $crud)
    Seeder: Modules/Prime/database/seeders/RolePermissionSeeder.php:25-40 ($perms default actions), :103 (App Maintenance → $perms($docs))
    Bypass: app/Providers/AppServiceProvider.php:65 (Gate::before — Super Admin only)
- Evidence:
    // $crud actions (config/permissionslist.php): create,view,viewAny,update,delete,restore,
    // forceDelete,import,export,print,status,email-schedule,remark,pdf,edit,approve  — NO 'store'
    Gate::authorize('prime.documentation-article.store');   // 'store' permission never exists
- Why it's a risk: `prime.documentation-article.store` / `prime.documentation-category.store` are not in `$crud`, so `PermissionHelper::flatten('prime')` never produces them and `RolePermissionSeeder` never grants them to any role. Gate::before only short-circuits for Super Admin / the dual super-admin flags. Therefore the intended primary actors — App Maintenance and any Content Author role — receive a 403 on every article/category create, even though they hold `documentation-*.create`. Content creation is effectively Super-Admin-only.
- Fix: Change both `store()` gates to `.create` (the granted ability `create()` already uses). Do not add a `.store` permission — align to the platform's CRUD action vocabulary.
- Confidence: High
- Systemic? : Module-local (D24-adjacent: action-name vocabulary drift). Maps REQ-DOC-011 / BR-DOC-022 / NFR-DOC-004.
```

```
[BUG-DOC-002] Severity: P1 | Article CREATE form posts categories under the wrong field name — selection silently lost
- Location:
    Modules/Documentation/resources/views/article/create.blade.php:84   <select name="categories[]" ...>
    Consumer: DocumentationArticleController.php:67  if ($request->filled('category_ids')) { $article->categories()->sync($request->category_ids); }
    Validation: ValidateArticleRequest.php:73-74  'category_ids' => 'nullable|array'
- Evidence:
    <select name="categories[]" class="form-select" multiple ...>   // create.blade.php
    if ($request->filled('category_ids')) {                          // controller expects category_ids
- Why it's a risk: The create form sends `categories[]`; the controller and FormRequest read/validate `category_ids`. `filled('category_ids')` is false → `sync()` never runs → a newly created article is filed under zero categories regardless of what the author picked, with no error. (The EDIT form is correct — `article/edit.blade.php:69` uses `name="category_ids[]"` — so only create is broken, which is why this slipped through.)
- Fix: Rename the create-form field to `category_ids[]` (and the `old('categories')` references at create.blade.php:88,94 to `old('category_ids')`) to match edit.blade.php and the handler.
- Confidence: High
- Systemic? : Module-local. Maps REQ-DOC-004 / BR-DOC-020 / RISK-DOC-005.
```

```
[SEC-DOC-002] Severity: P1 | DocumentationCategoryController@index has NO authorization gate
- Location: Modules/Documentation/app/Http/Controllers/DocumentationCategoryController.php:18-41
- Evidence:
    public function index(Request $request)
    {
        $categories = Category::query()        // no Gate::authorize(...) anywhere in the method
            ...->paginate(10);
        return view('documentation::category.index', compact('categories'));
    }
- Why it's a risk: Every other action in this controller calls `Gate::authorize('prime.documentation-category.*')`; `index()` does not. The route (global routes/web.php:187, inside the `auth`+`verified`, `prime.` group) is reachable by ANY authenticated central user — including roles with no documentation permission — who can enumerate the full category list and metadata.
- Fix: Add `Gate::authorize('prime.documentation-category.viewAny');` as the first line of `index()` (matching `trashed()` at :179).
- Confidence: High
- Systemic? : Module-local. Maps REQ-DOC-011 / BR-DOC-016 / NFR-DOC-003 / RISK-DOC-002.
```

```
[SEC-DOC-003] Severity: P1 | Both uploadImage() endpoints have NO authorization gate
- Location:
    Modules/Documentation/app/Http/Controllers/DocumentationArticleController.php:91-101
    Modules/Documentation/app/Http/Controllers/DocumentationCategoryController.php:80-90
    Routes: routes/web.php:204 (documentation-articles.upload-image), :192 (documentation.upload-image)
- Evidence:
    public function uploadImage(Request $request)
    {
        $request->validate(['image' => 'required|image|max:20048']);   // no Gate::authorize
        $path = $request->file('image')->store('documentation/articles/summernote', 'public');
        return asset('storage/' . $path);
    }
- Why it's a risk: Any authenticated central user (no documentation permission required) can write files to public storage via these two POST endpoints. Combined with VAL-DOC-001 (SVG allowed) this is an upload-of-active-content vector.
- Fix: Add `Gate::authorize('prime.documentation-article.create')` / `prime.documentation-category.create` to the respective `uploadImage()` methods.
- Confidence: High
- Systemic? : Module-local. Maps REQ-DOC-011 / BR-DOC-016 / NFR-DOC-003 / RISK-DOC-002.
```

```
[VAL-DOC-001] Severity: P1 | Image uploads allow ~20 MB and SVG (XSS) — no mime allowlist
- Location:
    Modules/Documentation/app/Http/Controllers/DocumentationArticleController.php:93-95
    Modules/Documentation/app/Http/Controllers/DocumentationCategoryController.php:82-84
- Evidence:
    'image' => 'required|image|max:20048',   // 20048 KB ≈ 19.6 MB; Laravel 'image' rule permits SVG
- Why it's a risk: `max:20048` is ~20 MB (the UI even says "max 2MB" — create.blade.php:191/2MB mismatch). Laravel's `image` rule accepts SVG, which can embed `<script>` → stored XSS when served from the same origin. No `mimes:` restriction.
- Fix: `'image' => 'required|image|mimes:jpg,jpeg,png,gif,webp|max:2048'` on both endpoints.
- Confidence: High
- Systemic? : Module-local. Maps REQ-DOC-006 / BR-DOC-015 / NFR-DOC-005 / RISK-DOC-003.
```

```
[SEC-DOC-004] Severity: P1 (systemic) | Both FormRequests authorize() return bare true (D30)
- Location:
    Modules/Documentation/app/Http/Requests/ValidateArticleRequest.php:12-15
    Modules/Documentation/app/Http/Requests/ValidateCategoryRequest.php:11-14
- Evidence:
    public function authorize(): bool { return true; }
- Why it's a risk: No defense-in-depth at the request layer. Controllers do gate (store/update), but the bare `true` means the FormRequest contributes nothing — and where the controller gate is wrong (BUG-DOC-001 `.store`) or missing, there is no second line. This is the platform norm (437/485 ≈ 90%), so report as systemic P1, not a module outlier.
- Fix: Return `Gate::allows('prime.documentation-article.create')` (and `.update` for the update path) / category equivalents, keeping the controller gates too.
- Confidence: High
- Systemic? : D30 (platform-wide).
```

---

### P2 Findings

```
[DATA-DOC-002] Severity: P2 | Category::$fillable omits sort_order — display order silently dropped on save
- Location:
    Modules/Documentation/app/Models/Category.php:18-27 ($fillable, no 'sort_order')
    Column exists: 2026_01_09_101501_create_categories_table.php:24
    Validated then discarded: ValidateCategoryRequest.php:53 ('sort_order' => 'nullable|integer|min:0')
- Evidence:
    protected $fillable = ['name','slug','parent_id','type','description','meta_title','meta_description','is_active'];  // no sort_order
- Why it's a risk: `sort_order` is validated and the column exists, but it is not mass-assignable → `Category::create()/update($request->validated())` silently drops it; categories always persist `sort_order = 0`, so the reader ordering (mainDoc orderBy sort_order on categories) never reflects author intent.
- Fix: Add `'sort_order'` to `Category::$fillable`.
- Confidence: High
- Systemic? : Module-local. Maps BR-DOC-019 / NFR-DOC-007.
```

```
[DEAD-DOC-001] Severity: P2 | DocumentationController@store/update/destroy are no-op stubs; create/show/edit return non-existent views — all exposed by the module 'documentations' resource route
- Location:
    Modules/Documentation/app/Http/Controllers/DocumentationController.php:157-160 (store), 183-186 (update), 191-194 (destroy) — gate only, empty body
    DocumentationController.php:148-178 — create/show/edit return view('documentation::create'|'show'|'edit') (no such blades; real views live under article/ and category/)
    Routes: Modules/Documentation/routes/web.php:7 + routes/api.php:7  Route::resource('documentations', DocumentationController::class)
- Evidence:
    public function store(Request $request) { Gate::authorize('prime.documentation-mgt.create'); }   // returns null, silent no-op
    public function create() { Gate::authorize(...); return view('documentation::create'); }           // view does not exist → 500
- Why it's a risk: A live (auth+verified) `documentations` resource exposes actions that either silently do nothing (store/update/destroy) or 500 (create/show/edit point at missing blades). Violates "no silent no-op management action".
- Fix: Remove the `documentations` resource routes (module routes/web.php:7 and api.php:7) and delete the dead stub methods, OR implement them. The real management surface is `documentation-mgt` (index) + the article/category resources in global routes/web.php.
- Confidence: High
- Systemic? : Module-local. Maps REQ-DOC-015 / BR-DOC-024 / NFR-DOC-009.
```

```
[BUG-DOC-003] Severity: P2 | Reader visibility scoping only honours 'public'; client/developer/internal audiences unsupported
- Location: DocumentationController.php:89 (mainDoc), :116 (getArticlesByCategory)  ->where('visibility','public')
- Evidence:
    ->where('is_published', true)->where('visibility', 'public')
- Why it's a risk: This is SAFE as a filter (restricted articles are correctly hidden, no leak), but the audience feature in the data model (visibility = client/developer/internal) is never surfaced to the right audience — those articles are simply invisible everywhere in the reader. Functional gap, not a security hole.
- Fix: Implement a visibility-aware reader that maps the viewer's role/audience to allowed `visibility` values; until then, the public-only behaviour is acceptable from a security standpoint.
- Confidence: High
- Systemic? : Module-local. Maps REQ-DOC-008 / BR-DOC-017 / RISK-DOC-006.
```

```
[DAT-DOC-003] Severity: P2 | store()/update() perform multi-write (model + categories sync + media) without a transaction
- Location: DocumentationArticleController.php:65-75 (store), 143-152 (update); DocumentationCategoryController.php:63-68 (store)
- Evidence:
    $article = Article::create($request->validated());
    if ($request->filled('category_ids')) { $article->categories()->sync(...); }
    if ($request->hasFile('doc_article_image')) { $article->addMediaFromRequest(...)->toMediaCollection(...); }
- Why it's a risk: If the media step (or sync) throws, the article/category row and partial links are already committed → orphaned/partial records. Low blast radius (no money/stock), hence P2.
- Fix: Wrap each create/update flow in DB::transaction(); media-collection writes that touch the disk should be inside or compensated.
- Confidence: High
- Systemic? : Module-local.
```

```
[PERF-DOC-001] Severity: P2 | getArticlesByCategory returns all rows unpaginated; reader category tree uncached
- Location: DocumentationController.php:111-129 (no paginate/limit), :67-75 (mainDoc category tree, no cache)
- Evidence:
    Article::whereHas('categories', ...)->where('is_published',true)->where('visibility','public')->orderBy('sort_order')->get()
- Why it's a risk: As content grows, the AJAX topic-switch returns the entire article set per category (full body content in the JSON payload too); the root category tree is rebuilt every request. P2 (config-scale today).
- Fix: Paginate getArticlesByCategory; cache the per-type category tree (invalidate on category mutation) per NFR-DOC-010/011.
- Confidence: Medium
- Systemic? : Module-local.
```

---

### P3 Findings

```
[ORM-DOC-001] Severity: P3 | Models have no $connection — central models could query a tenant DB if a tenant context is active
- Location: Article.php / Category.php (no protected $connection)
- Why it's a risk: Documentation is central-only and its routes are central, so risk is latent; but without pinning, a Documentation model resolved inside an initialized tenant context would query the tenant connection.
- Fix: Pin both models to the central connection (e.g. `protected $connection = 'mysql'` / the central connection name).
- Confidence: Medium · Systemic?: D-pattern-adjacent (NFR-DOC-013).
```

```
[BUG-DOC-004] Severity: P3 | created_by assigned inside ValidateArticleRequest::prepareForValidation() (anti-pattern)
- Location: ValidateArticleRequest.php:26  'created_by' => Auth::id()
- Why it's a risk: Author identity is business state set in the request layer; belongs in the controller. (Note: the merge overrides any client-supplied created_by, so it is NOT a spoofing hole — hence P3, not higher.)
- Fix: Set $article->created_by = Auth::id() in the controller; drop created_by from the FormRequest merge/rules.
- Confidence: High · Systemic?: NFR-DOC-012.
```

---

### Layer Health Summary

| # | Layer | Status | Key finding |
|---|-------|--------|-------------|
| 1 | DDL Schema Integrity | Amber | `type`/`visibility` ENUM (D29) — accepted per design; otherwise clean; `doc_*` absent from consolidated DDL masters (sync gap) |
| 2 | Migration↔Model↔DDL | **Red** | DATA-DOC-001 (sort_order missing on doc_articles, in $fillable+orderBy), DATA-DOC-002 (Category fillable omits sort_order) |
| 3 | Model & ORM | Amber | ORM-DOC-001 (no $connection); fillable/column drift |
| 4 | Code Quality & Dead Code | Amber | DEAD-DOC-001 (no-op stubs + missing-view actions); 0 services |
| 5 | Authorization | **Red** | SEC-DOC-002 (Category@index ungated), SEC-DOC-003 (uploadImage ungated), BUG-DOC-001 (`.store` ungranted), dead plural policies |
| 6 | Multi-Tenancy | Green | Central module — no tenancy expected; correct (not a finding) |
| 7 | Input Validation / Mass-assign | Amber | VAL-DOC-001 (20MB/SVG), SEC-DOC-004 (D30 bare true), DATA-DOC-002 (dropped field) |
| 8 | Data Integrity / Tx | Amber | DAT-DOC-003 (no transaction around multi-write) |
| 9 | Performance | Amber | PERF-DOC-001 (unpaginated reader fetch, uncached tree) |
| 10 | Queue / Job / Scheduler | Green | No jobs / scheduled commands in module |
| 11 | Frontend / Blade / Output Safety | **Red** | SEC-DOC-001 (raw `{!! content !!}` + base64→innerHTML) |
| 12 | Deployment / Operational | Amber | No secrets/closures/queue coupling; dead `documentations` resource + missing-view actions |

Weighted: L1 3.5 + L2 0 + L3 1 + L4 2 + L5 0 + L6 15 + L7 5.5 + L8 6.5 + L9 3.5 + L10 6 + L11 0 + L12 5 = **48** → **capped to 40 (P0 present)**.

---

### STEP 1 Reading-Discipline Output — three-way reconcile (DDL master ↔ migration ↔ model)

| Table | DDL master | Migration (authoritative) | Model | Verdict |
|-------|-----------|---------------------------|-------|---------|
| doc_categories | **absent** from prime/tenant/global v4 masters | `create_categories_table` — id UINT, name(150)U, slug(180)U, parent_id UINT→self RESTRICT, type ENUM, …, `sort_order` UINT=0, softDeletes | `$fillable` **omits sort_order** (DATA-DOC-002) | Migration↔model drift (P2); DDL-master sync gap |
| doc_articles | **absent** from masters | `create_articles_table` — id UINT, title/slug U, type ENUM, content LONGTEXT, is_published, published_at, visibility ENUM, …, created_by UINT→sys_users nullOnDelete; **NO sort_order** | `$fillable` **lists sort_order** (no column) + `orderBy('sort_order')` ×2 (DATA-DOC-001) | Migration↔model+code drift → runtime crash (P1) |
| doc_article_category_jnt | **absent** from masters | `create_article_categories_table` — id UINT, article_id→CASCADE, category_id→CASCADE, UNIQUE(article_id,category_id) | belongsToMany via jnt (correct) | OK; DDL-master sync gap |

**Snapshot corrections vs module-knowledge (verified against live tree):** all module-knowledge counts confirmed accurate (3 controllers, 2 models, 2 orphaned policies, 2 FormRequests, 0 services, 3 migrations, 3 tables, 15 views, 27 web routes, 1 test file). PK/FK type confirmed **UNSIGNED INT** (`increments`/`unsignedInteger`), not BIGINT. `doc_*` confirmed absent from all consolidated DDL masters (DDL-sync gap — hand to DB Architect). The `.store` ability is confirmed **not present in `config/permissionslist.php` `$crud`** (which is what flatten/seeder use) — escalating the module-knowledge's "likely unseeded" note to a confirmed P1 (BUG-DOC-001).

---

### FRD Gap Summary (Mode B) — REQ → DDL / Code / Test

| REQ | Feature | DDL | Code | Test | Status | Finding link |
|-----|---------|-----|------|------|--------|--------------|
| REQ-DOC-001 | Category mgmt | OK | OK | structural only | Done~ | DATA-DOC-002 (display order), BUG-DOC-001 (create gate) |
| REQ-DOC-002 | Hierarchy (2-level) | OK | OK | none | Done | — |
| REQ-DOC-003 | Article mgmt | **sort_order missing** | OK | none | Done~ | DATA-DOC-001, BUG-DOC-001 |
| REQ-DOC-004 | Categorisation | OK | **create form field wrong** | none | Defect | BUG-DOC-002 |
| REQ-DOC-005 | Publish/schedule | OK | OK (scopePublished) | none | Done | — |
| REQ-DOC-006 | Images | OK | OK | none | Done~ | VAL-DOC-001, SEC-DOC-003 |
| REQ-DOC-007 | Reader (3-pane) | n/a | **crashes (sort_order)** | none | Broken | DATA-DOC-001 |
| REQ-DOC-008 | Reader scoping | n/a | public-only | none | Partial | BUG-DOC-003 |
| REQ-DOC-009 | Management hub | n/a | OK (paginated) | none | Done | — |
| REQ-DOC-010 | Archive/restore | OK | OK | none | Done | — |
| REQ-DOC-011 | Authorisation | n/a | **gaps** | none | Partial | SEC-DOC-002/003, BUG-DOC-001 |
| REQ-DOC-012 | Sanitisation | n/a | **none** | none | Not done | SEC-DOC-001 |
| REQ-DOC-013 | Audit trail | n/a | OK (activityLog) | none | Done | — |
| REQ-DOC-014 | SEO metadata | OK | OK (stored) | none | Done~ | indexable not enforced (P3, accepted) |
| REQ-DOC-015 | Dead endpoints | n/a | dead stubs present | none | Open | DEAD-DOC-001 |

Test gap: only `tests/Unit/DocumentationModuleTest.php` (~20 structural tests); **0 feature/HTTP/security tests** — every "Test Needed=Yes" row in FRD §16.1 is unmet (hand to Testing Architect).

---

### Business-Rule Enforcement (Mode C)

| BR | Type | Enforcement point | Status | Finding |
|----|------|-------------------|--------|---------|
| BR-DOC-001 | Validation | ValidateCategoryRequest unique name | ENFORCED | — |
| BR-DOC-002 | Validation | length limits in both FormRequests | ENFORCED | — |
| BR-DOC-003 | Workflow | Category::booted slug | ENFORCED | — |
| BR-DOC-004 | Validation | parent_id notIn(self) | ENFORCED | — |
| BR-DOC-005 | Workflow | app convention | ENFORCED (by convention) | — |
| BR-DOC-006 | Validation | unique title | ENFORCED | — |
| BR-DOC-007 | Workflow | destroy() sets is_published=false then delete | ENFORCED | — |
| BR-DOC-008 | Validation | jnt UNIQUE + sync() | ENFORCED | — |
| BR-DOC-009 | Workflow | sync/link-only | ENFORCED | — |
| BR-DOC-010 | Workflow | reader is_published filter | ENFORCED | — |
| BR-DOC-011 | Calculation | scopePublished (published_at ≤ now) | ENFORCED | — |
| BR-DOC-012 | Workflow | reader is_active filter | ENFORCED | — |
| BR-DOC-013 | Workflow | DB RESTRICT on parent_id (forceDelete try/catch) | ENFORCED (DB-level) | — |
| BR-DOC-014 | Security | sanitiser at save+render | **MISSING** | SEC-DOC-001 |
| BR-DOC-015 | Validation | upload size/type | **MISSING** | VAL-DOC-001 |
| BR-DOC-016 | Permission | gate per mgmt action | **PARTIAL** | SEC-DOC-002, SEC-DOC-003 |
| BR-DOC-017 | Permission | visibility-aware reader | **MISSING** (safe-hidden) | BUG-DOC-003 |
| BR-DOC-018 | Workflow | destroy() sets is_active=false then delete | ENFORCED | — |
| BR-DOC-019 | Validation | sort_order persisted | **MISSING** | DATA-DOC-002 |
| BR-DOC-020 | Validation | category selection reaches handler | **MISSING (create)** | BUG-DOC-002 |
| BR-DOC-021 | Workflow | theme persistence (client) | ENFORCED (JS/localStorage) | — |
| BR-DOC-022 | Permission | create/publish uses granted ability | **MISSING** | BUG-DOC-001 |
| BR-DOC-023 | Workflow | activityLog on mutations | ENFORCED | — |
| BR-DOC-024 | Workflow | no silent no-op action | **PARTIAL** | DEAD-DOC-001 |

Enforced 15 · Missing/Partial 9 (014,015,016,017,019,020,022,024 + 015). Highest priority unmet: BR-DOC-014 (P0), then BR-DOC-016/022/020 (P1).

---

### Systemic-Pattern Scorecard (Mode D — scoped to DOC)

| Pattern | Present? | Count / Evidence |
|---------|----------|------------------|
| D17 — model field not in DB (fillable/orderBy vs column) | **Yes** | 2 — Article.sort_order (no column), Category.sort_order (column not fillable) |
| D24 — permission-prefix chaos / action drift | **Yes (variant)** | 2 — `.store` action not in $crud vocabulary (BUG-DOC-001); plural orphan policies vs singular abilities |
| D25 — `$request->all()` into model | No | 0 — uses `$request->validated()` (good) |
| D29 — ENUM in migration | Yes (accepted) | 2 — `type`, `visibility` ENUMs (design decision per FRD; not flagged) |
| D30 — FormRequest authorize() bare true | **Yes** | 2/2 (SEC-DOC-004) — at platform norm |
| D36 — DDL GENERATED column shipped plain | No | 0 — no generated columns |
| Layer 2.5 — cross-DB / missing FK target | No | created_by→sys_users (central, present); parent_id/article_id/category_id self/intra-module |
| Layer 6.2 — initialize() without end() | No | 0 — central module, no tenancy calls |
| Layer 10.1 — job without tenancy/retry | N/A | 0 jobs |
| TEN-RTG-001 — module-subscription middleware | N/A | central module |

---

### vs Platform Baseline
- D30 (authorize() true): 2/2 here = the platform norm (437/485 ≈ 90%) — systemic, not an outlier.
- D25 ($request->all()): 0 sites — **better** than baseline (24 platform sites); uses validated().
- Write controllers with no authz: 1 real (Category@index) + 2 uploadImage — comparable to the 64-controller platform pattern, but all reachable behind central `auth` (lower blast radius than tenant equivalents).
- DDL-master sync: `doc_*` absent from consolidated masters — same class of gap noted for other late modules; hand to DB Architect.
- Jobs/queue/secrets: clean — none of the platform P0 deploy patterns (Horizon mismatch, committed APP_KEY, SEC-RTG-001 seeder routes) touch this module.

---

### Recommended Fix Order (unblock-the-most / highest-risk first)
1. **SEC-DOC-001 (P0)** — install + apply purifier (save + render), stop raw `{!! !!}` / base64→innerHTML. *(Deploy blocker.)*
2. **DATA-DOC-001 (P1)** — add `doc_articles.sort_order` migration (or drop the orderBy) → reader stops crashing.
3. **BUG-DOC-001 (P1)** — change both `store()` gates from `.store` to `.create` → content authors can create.
4. **BUG-DOC-002 (P1)** — rename create-form field to `category_ids[]` → category selection saved.
5. **SEC-DOC-002 / SEC-DOC-003 (P1)** — add gates to Category@index and both uploadImage().
6. **VAL-DOC-001 (P1)** — `mimes:jpg,jpeg,png,gif,webp|max:2048` on uploads.
7. **SEC-DOC-004 (P1)** — make FormRequest authorize() return the matching Gate::allows().
8. **DATA-DOC-002 (P2)** — add `sort_order` to Category::$fillable.
9. **DEAD-DOC-001 (P2)** — remove the `documentations` resource routes + dead stub methods.
10. P2/P3 — transaction wrap (DAT-DOC-003), reader pagination/cache (PERF-DOC-001), visibility-aware reader (BUG-DOC-003), $connection pin (ORM-DOC-001), move created_by to controller (BUG-DOC-004).

**Next steps:** P0/P1 code fixes → Developer · `doc_articles.sort_order` migration + fold `doc_*` into central DDL master → DB Architect · feature/security test suite (0 today) → Testing Architect · completeness score → Status_Analyzer.
