# Prime — Documentation (Categories + Articles)

**Feature:** Platform Documentation Management | **REQ-ID:** REQ-PRM-DOC | **Priority:** P1 (SHOULD)

**Module:** Prime (`Modules/Prime/`) — Routes defined in global `routes/web.php`
**Real Module Path:** `Modules/Documentation/` (separate nwidart module)
**Table Prefix:** `doc_` (Documentation module)
**Scope:** Central (`prime_db` — central domain only; NOT tenant-scoped)

---

## 1. Description

The Documentation feature provides a CMS-style knowledge base integrated into the Prime admin panel. It enables Super Admin users to manage hierarchical **categories** and rich-text **articles** for platform documentation, help guides, blog posts, and developer integration documentation.

The feature comprises two sub-features:
- **Category Management** — Hierarchical content containers (parent/child, 2 levels) with type scoping, featured images, soft deletes, and AJAX status toggling.
- **Article Management** — Rich-text content documents with Summernote editor, category assignment (M:M), visibility controls, SEO metadata, featured images, scheduled publishing, soft deletes, and AJAX status toggling.
- **Documentation Reader** — A public-facing 3-column reader interface (`/prime/documentation-intro`) for consuming published documentation.

**FRD Status:** Not in FRD (bonus/inferred feature — no formal FRD reference).
**Known Completion:** ~70% (structural complete, several critical bugs and missing security hardening).

---

## 2. Controller & Model

### 2.1 Controllers

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| DocumentationController | `Modules/Documentation/app/Http/Controllers/DocumentationController.php` | 195 | PARTIAL (stubs) |
| DocumentationCategoryController | `Modules/Documentation/app/Http/Controllers/DocumentationCategoryController.php` | 298 | FULL |
| DocumentationArticleController | `Modules/Documentation/app/Http/Controllers/DocumentationArticleController.php` | 282 | FULL |

### 2.2 Models

| Artifact | Path | Table | Fillable Gap |
|----------|------|-------|:------------:|
| Category | `Modules/Documentation/Models/Category.php` | `doc_categories` | `sort_order` NOT in `$fillable` [BUG] |
| Article | `Modules/Documentation/Models/Article.php` | `doc_articles` | `sort_order` in `$fillable` but column missing from migration [BUG] |

### 2.3 Form Requests

| Artifact | Path | Validates |
|----------|------|-----------|
| ValidateCategoryRequest | `Modules/Documentation/Http/Requests/ValidateCategoryRequest.php` | Category create/update |
| ValidateArticleRequest | `Modules/Documentation/Http/Requests/ValidateArticleRequest.php` | Article create/update |

### 2.4 Policies

| Artifact | Path | Gate Prefix |
|----------|------|:-----------:|
| DocumentationCategoryPolicy | `Modules/Documentation/Policies/DocumentationCategoryPolicy.php` | `prime.documentation-categories.*` (plural) |
| DocumentationArticlePolicy | `Modules/Documentation/Policies/DocumentationArticlePolicy.php` | `prime.documentation-articles.*` (plural) |

**⚠️ CRITICAL BUG:** Controllers use **singular** gate strings (`prime.documentation-article.*`, `prime.documentation-category.*`) while Policies register **plural** (`prime.documentation-articles.*`, `prime.documentation-categories.*`). Gate authorization is silently bypassed — policies are never invoked.

### 2.5 Service Layer

| Service | Status | Notes |
|---------|:------:|-------|
| ArticleService | ❌ Not created | All business logic in controller |
| CategoryService | ❌ Not created | All business logic in controller |

### 2.6 Views

| Namespace | Path | Views |
|-----------|------|-------|
| `documentation::category.*` | `resources/views/category/` | index, create, edit, show, trash |
| `documentation::article.*` | `resources/views/article/` | index, create, edit, show, trash |
| `documentation::main-doc.*` | `resources/views/main-doc/` | index (reader) |
| `documentation::index` | `resources/views/index.blade.php` | Management hub (tabs) |
| `documentation::partials.*` | `resources/views/partials/` | head, footer |

---

## 3. Routes

All routes registered in global `routes/web.php` under `/prime/*` prefix. Gate permission strings shown in **controller form** (singular — BUG).

| Method | URI | Controller@Method | Gate (Controller — Singular) | Gate (Correct — Plural) |
|--------|-----|-------------------|:----------------------------:|:------------------------:|
| GET | `/prime/documentation-mgt` | `DocumentationController@index` | `prime.documentation-mgt.viewAny` | Same |
| GET | `/prime/documentation-intro` | `DocumentationController@mainDoc` | `prime.documentation-mgt.view` | Same |
| GET | `/prime/documentation/articles/{categoryId}` | `DocumentationController@getArticlesByCategory` | `prime.documentation-mgt.view` | Same |
| GET | `/prime/documentation-categories` | `DocumentationCategoryController@index` | **NONE** [BUG] | `prime.documentation-categories.viewAny` |
| GET | `/prime/documentation-categories/create` | `DocumentationCategoryController@create` | `prime.documentation-category.create` | `prime.documentation-categories.create` |
| POST | `/prime/documentation-categories` | `DocumentationCategoryController@store` | `prime.documentation-category.store` | `prime.documentation-categories.create` |
| GET | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@show` | `prime.documentation-category.view` | `prime.documentation-categories.view` |
| GET | `/prime/documentation-categories/{id}/edit` | `DocumentationCategoryController@edit` | `prime.documentation-category.update` | `prime.documentation-categories.update` |
| PUT | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@update` | `prime.documentation-category.update` | `prime.documentation-categories.update` |
| DELETE | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@destroy` | `prime.documentation-category.delete` | `prime.documentation-categories.delete` |
| GET | `/prime/documentation-categories/trash/view` | `DocumentationCategoryController@trashed` | `prime.documentation-category.viewAny` | `prime.documentation-categories.viewAny` |
| GET | `/prime/documentation-categories/{id}/restore` | `DocumentationCategoryController@restore` | `prime.documentation-category.restore` | `prime.documentation-categories.restore` |
| DELETE | `/prime/documentation-categories/{id}/force-delete` | `DocumentationCategoryController@forceDelete` | `prime.documentation-category.forceDelete` | `prime.documentation-categories.forceDelete` |
| POST | `/prime/documentation-categories/{cat}/toggle-status` | `DocumentationCategoryController@toggleStatus` | `prime.documentation-category.update` | `prime.documentation-categories.update` |
| POST | `/prime/documentation/upload-image` | `DocumentationCategoryController@uploadImage` | **NONE** [BUG] | `prime.documentation-categories.create` (proposed) |
| GET | `/prime/documentation-articles` | `DocumentationArticleController@index` | `prime.documentation-article.viewAny` | `prime.documentation-articles.viewAny` |
| GET | `/prime/documentation-articles/create` | `DocumentationArticleController@create` | `prime.documentation-article.create` | `prime.documentation-articles.create` |
| POST | `/prime/documentation-articles` | `DocumentationArticleController@store` | `prime.documentation-article.store` | `prime.documentation-articles.create` |
| GET | `/prime/documentation-articles/{id}` | `DocumentationArticleController@show` | `prime.documentation-article.view` | `prime.documentation-articles.view` |
| GET | `/prime/documentation-articles/{id}/edit` | `DocumentationArticleController@edit` | `prime.documentation-article.update` | `prime.documentation-articles.update` |
| PUT | `/prime/documentation-articles/{id}` | `DocumentationArticleController@update` | `prime.documentation-article.update` | `prime.documentation-articles.update` |
| DELETE | `/prime/documentation-articles/{id}` | `DocumentationArticleController@destroy` | `prime.documentation-article.delete` | `prime.documentation-articles.delete` |
| GET | `/prime/documentation-articles/trash/view` | `DocumentationArticleController@trashed` | `prime.documentation-article.viewAny` | `prime.documentation-articles.viewAny` |
| GET | `/prime/documentation-articles/{id}/restore` | `DocumentationArticleController@restore` | `prime.documentation-article.restore` | `prime.documentation-articles.restore` |
| DELETE | `/prime/documentation-articles/{id}/force-delete` | `DocumentationArticleController@forceDelete` | `prime.documentation-article.forceDelete` | `prime.documentation-articles.forceDelete` |
| POST | `/prime/documentation-articles/{art}/toggle-status` | `DocumentationArticleController@toggleStatus` | `prime.documentation-article.update` | `prime.documentation-articles.update` |
| POST | `/prime/documentation/articles/upload-image` | `DocumentationArticleController@uploadImage` | **NONE** [BUG] | `prime.documentation-articles.create` (proposed) |

---

## 4. Data Model

### 4.1 `doc_categories`

| Column | Type | Required | Default | FK / Constraints | Notes |
|--------|------|:--------:|:-------:|------------------|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | PK | |
| `name` | VARCHAR(150) | ✅ | — | UNIQUE NOT NULL | Display name |
| `slug` | VARCHAR(180) | ✅ | — | UNIQUE NOT NULL | Auto-generated from `name` via `booted()` |
| `parent_id` | INT UNSIGNED | — | NULL | FK `doc_categories.id` ON DELETE RESTRICT | Self-referencing parent |
| `type` | ENUM(documentation,blog,developer,help) | ✅ | — | INDEX | |
| `description` | TEXT | — | NULL | — | Sanitized via `SanitizesRichText` trait |
| `meta_title` | VARCHAR(255) | — | NULL | — | SEO |
| `meta_description` | VARCHAR(300) | — | NULL | — | SEO |
| `is_active` | BOOLEAN | ✅ | true | — | |
| `sort_order` | INT UNSIGNED | ✅ | 0 | — | ⚠️ NOT in `Category::$fillable` [BUG] |
| `created_at` | TIMESTAMP | — | — | — | |
| `updated_at` | TIMESTAMP | — | — | — | |
| `deleted_at` | TIMESTAMP | — | NULL | — | Soft delete |

**Indexes:** `(type, is_active, sort_order)` composite index
**Media Collection:** `doc_category_image` — singleFile, conversions: small (100×100), medium (300×300), large (600×600)

### 4.2 `doc_articles`

| Column | Type | Required | Default | FK / Constraints | Notes |
|--------|------|:--------:|:-------:|------------------|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | PK | |
| `title` | VARCHAR(255) | ✅ | — | UNIQUE NOT NULL | |
| `slug` | VARCHAR(255) | ✅ | — | UNIQUE NOT NULL | Auto-generated from `title` via `booted()` |
| `type` | ENUM(documentation,blog,developer,help) | ✅ | — | INDEX | |
| `content` | LONGTEXT | ✅ | — | — | Raw Summernote HTML — XSS risk |
| `excerpt` | TEXT | — | NULL | — | Max 500 chars (FormRequest) |
| `is_published` | BOOLEAN | ✅ | false | — | |
| `published_at` | TIMESTAMP | — | NULL | — | Scheduled publish |
| `visibility` | ENUM(public,client,developer,internal,draft) | ✅ | public | INDEX | |
| `meta_title` | VARCHAR(255) | — | NULL | — | SEO |
| `meta_description` | VARCHAR(300) | — | NULL | — | SEO |
| `canonical_url` | VARCHAR(255) | — | NULL | — | SEO |
| `is_indexable` | BOOLEAN | ✅ | true | — | SEO robots |
| `sort_order` | — | ❌ | — | — | ⚠️ Column **MISSING** from migration [BUG] |
| `created_by` | INT UNSIGNED | — | NULL | FK `sys_users.id` ON DELETE SET NULL | Author |
| `created_at` | TIMESTAMP | — | — | — | |
| `updated_at` | TIMESTAMP | — | — | — | |
| `deleted_at` | TIMESTAMP | — | NULL | — | Soft delete |

**Indexes:** `(type, is_published, published_at)` composite index
**⚠️ Missing Column:** `sort_order` is in `Article::$fillable` and used in `orderBy('sort_order')` queries but does not exist in migration — causes SQL error.
**Media Collection:** `doc_article_image` — singleFile, conversions: small/medium/large

### 4.3 `doc_article_category_jnt` (Junction Table)

| Column | Type | Required | FK | Notes |
|--------|------|:--------:|:--:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | PK | |
| `article_id` | INT UNSIGNED | ✅ | FK `doc_articles.id` ON DELETE CASCADE | |
| `category_id` | INT UNSIGNED | ✅ | FK `doc_categories.id` ON DELETE CASCADE | |
| `created_at` | TIMESTAMP | — | — | |
| `updated_at` | TIMESTAMP | — | — | |

**Unique Constraint:** `(article_id, category_id)` — prevents duplicate mappings

### 4.4 Model Relationships

#### Category Model

| Relationship | Type | Foreign Key | Notes |
|-------------|:----:|:-----------:|-------|
| `parent()` | BelongsTo self | `parent_id` | Returns parent category |
| `children()` | HasMany self | `parent_id` | Returns direct children |
| `childrenRecursive()` | HasMany self with nested eager load | `parent_id` | Recursive children |

| Scope | Logic |
|-------|-------|
| `scopeActive(Builder)` | `WHERE is_active = true` |
| `scopeType(Builder, string)` | `WHERE type = ?` |

#### Article Model

| Relationship | Type | Foreign/Pivot | Notes |
|-------------|:----:|:-------------:|-------|
| `categories()` | BelongsToMany | `doc_article_category_jnt` | M:M via junction table |
| `author()` | BelongsTo `sys_users` | `created_by` | Article author |

| Scope | Logic |
|-------|-------|
| `scopePublished(Builder)` | `WHERE is_published = true AND (published_at IS NULL OR published_at <= now())` |

### 4.5 Model Fillable Gaps

| Model | Missing in `$fillable` | Notes |
|-------|:----------------------:|-------|
| Category | `sort_order` | Validated in FormRequest, stored in migration, but mass-assignment silently drops it |
| Article | — | `sort_order` is in `$fillable` but column does not exist in migration |

---

## 5. Controller Implementation Details

### 5.1 `DocumentationCategoryController`

#### `index(Request $request)`
- **Gate:** ⚠️ **MISSING** — no authorization check [BUG]
- **Filters:** `?search=` (name LIKE), `?type=` (enum exact), `?status=` (is_active)
- **Eager Load:** `parent` relationship
- **Ordering:** `latest()`
- **Pagination:** 10 records/page
- **View:** `documentation::category.index` with `compact('categories')`

#### `create()`
- **Gate:** `prime.documentation-category.create` (singular — BUG)
- **Logic:** Fetches root categories (`parent_id IS NULL`) for parent dropdown
- **View:** `documentation::category.create` with `compact('categories')`

#### `store(ValidateCategoryRequest $request)`
- **Gate:** `prime.documentation-category.store` (singular — BUG; should share `create` with `create()`)
- **Logic:** `Category::create($request->validated())` + optional featured image upload via Spatie MediaLibrary
- **Media:** `clearMediaCollection('doc_category_image')` then `addMediaFromRequest('doc_category_image')` to `doc_category_image` collection
- **Audit:** `activityLog($category, 'Created', ['message' => 'Documentation category created.'])`
- **Redirect:** `route('central.prime.documentation-mgt')` with success flash `flash('created.documentation_category')`

#### `uploadImage(Request $request)`
- **Gate:** ⚠️ **MISSING** [BUG]
- **Validation:** `'image' => 'required|image|max:20048'` (20 MB — too large; XSS risk SVG allowed)
- **Logic:** Stores to `storage/documentation/summernote/` (public disk)
- **Response:** Returns plain `asset()` URL string (not JSON — poor API practice)
- **Usage:** Summernote in-editor image upload handler

#### `show($id)`
- **Gate:** `prime.documentation-category.view` (singular — BUG)
- **Eager Load:** `parent`, `children`
- **View:** `documentation::category.show` with `compact('category')`

#### `edit($id)`
- **Gate:** `prime.documentation-category.update` (singular — BUG)
- **Logic:** Fetches category + root categories excluding self (prevents self-parent)
- **View:** `documentation::category.edit` with `compact('category', 'categories')`

#### `update(ValidateCategoryRequest $request, $id)`
- **Gate:** `prime.documentation-category.update` (singular — BUG)
- **Logic:** `Category::findOrFail($id)` → capture original → `update($request->validated())` → optional media sync
- **Audit:** Field-level change tracking via `getChanges()` — logs old/new for each changed field
- **Redirect:** `route('documentation-categories.index')` (⚠️ inconsistent — `store()` uses `central.prime.documentation-mgt`)

#### `destroy($id)`
- **Gate:** `prime.documentation-category.delete` (singular — BUG)
- **Logic:** Sets `is_active = false` → `save()` → `delete()` (soft delete)
- **Audit:** `activityLog($category, 'Trashed', ['message' => 'Documentation category trashed.'])`
- **Redirect:** `route('documentation-categories.index')` with `flash('trashed.documentation_category')`

#### `trashed()`
- **Gate:** `prime.documentation-category.viewAny` (singular — BUG)
- **Logic:** `Category::onlyTrashed()->with('parent')->paginate(10)`
- **View:** `documentation::category.trash` with `compact('categories')`

#### `restore($id)`
- **Gate:** `prime.documentation-category.restore` (singular — BUG)
- **Logic:** `Category::withTrashed()->findOrFail($id)` → `restore()`
- **Redirect:** `route('documentation-categories.trashed')` with `flash('restored.documentation_category')`

#### `forceDelete($id)`
- **Gate:** `prime.documentation-category.forceDelete` (singular — BUG)
- **Logic:** `Category::withTrashed()->findOrFail($id)` → `forceDelete()` in try/catch
- **Error Handling:** On exception, redirects with `flash('operation_failed.documentation_category')`
- **Restriction:** FK `RESTRICT` on `parent_id` blocks force delete if child categories exist
- **Redirect:** `route('documentation-categories.trashed')` with success/error flash

#### `toggleStatus(Request $request, Category $documentationCategory)`
- **Gate:** `prime.documentation-category.update` (singular — BUG)
- **Validation:** `'is_active' => 'required|boolean'`
- **Logic:** Updates `is_active` column, saves
- **Response:** JSON `{ success: true, is_active: bool, message: string }`
- **Audit:** `activityLog($category, 'Toggled', ['message' => 'Documentation category status toggled.'])`

### 5.2 `DocumentationArticleController`

#### `index(Request $request)`
- **Gate:** `prime.documentation-article.viewAny` (singular — BUG)
- **Filters:** `?search=` (title LIKE), `?type=` (enum exact), `?status=` (is_published)
- **Eager Load:** `categories`, `author`
- **Ordering:** `latest()`
- **Pagination:** 10 records/page
- **View:** `documentation::article.index` with `compact('articles')`

#### `create()`
- **Gate:** `prime.documentation-article.create` (singular — BUG)
- **Logic:** Fetches active categories for multi-select
- **View:** `documentation::article.create` with `compact('categories')`

#### `store(ValidateArticleRequest $request)`
- **Gate:** `prime.documentation-article.store` (singular — BUG; should share `create`)
- **Logic:** `Article::create($request->validated())` → sync categories (`$request->category_ids`) → optional featured image
- **Category Sync:** `$article->categories()->sync($request->category_ids)` — only if `$request->filled('category_ids')`
- **⚠️ Form Field Mismatch:** Form view uses `name="categories[]"` but controller expects `$request->category_ids` — sync silently fails [BUG]
- **Media:** `addMediaFromRequest('doc_article_image')` to `doc_article_image` collection
- **Audit:** `activityLog($article, 'Created', ['message' => 'Documentation article created.'])`
- **Redirect:** `route('central.prime.documentation-mgt')` with `flash('created.documentation_article')`

#### `uploadImage(Request $request)`
- **Gate:** ⚠️ **MISSING** [BUG]
- **Validation:** `'image' => 'required|image|max:20048'` (20 MB — too large)
- **Logic:** Stores to `storage/documentation/articles/summernote/` (public disk)
- **Response:** Returns plain `asset()` URL string (not JSON)

#### `show($id)`
- **Gate:** `prime.documentation-article.view` (singular — BUG)
- **Eager Load:** `author`, `categories`
- **View:** `documentation::article.show` with `compact('article', 'categories')`

#### `edit($id)`
- **Gate:** `prime.documentation-article.update` (singular — BUG)
- **Logic:** Fetches article with categories + all active categories for multi-select
- **View:** `documentation::article.edit` with `compact('article', 'categories')`

#### `update(ValidateArticleRequest $request, $id)`
- **Gate:** `prime.documentation-article.update` (singular — BUG)
- **Logic:** `Article::findOrFail($id)` → capture original → `update($request->validated())` → `categories()->sync($request->category_ids ?? [])` → optional media sync (clear + add)
- **Audit:** Field-level change tracking via `getChanges()`
- **Redirect:** `route('central.prime.documentation-mgt')` with `flash('updated.documentation_article')`

#### `destroy($id)`
- **Gate:** `prime.documentation-article.delete` (singular — BUG)
- **Logic:** Sets `is_published = false` → `save()` → `delete()` (soft delete)
- **Audit:** `activityLog($article, 'Trashed', ['message' => 'Documentation article trashed.'])`
- **Redirect:** `route('documentation-articles.index')` with `flash('trashed.documentation_article')`

#### `trashed()`
- **Gate:** `prime.documentation-article.viewAny` (singular — BUG)
- **Logic:** `Article::onlyTrashed()->with(['categories', 'author'])->paginate(10)`
- **View:** `documentation::article.trash` with `compact('articles')`

#### `restore($id)`
- **Gate:** `prime.documentation-article.restore` (singular — BUG)
- **Logic:** `Article::withTrashed()->findOrFail($id)` → `restore()`
- **Redirect:** `route('documentation-articles.trashed')` with `flash('restored.documentation_article')`

#### `forceDelete($id)`
- **Gate:** `prime.documentation-article.forceDelete` (singular — BUG)
- **Logic:** `Article::withTrashed()->findOrFail($id)` → `forceDelete()` in try/catch
- **Error Handling:** On exception, redirects with `flash('operation_failed.documentation_article')`
- **Redirect:** `route('documentation-articles.trashed')` with success/error flash

#### `toggleStatus(Request $request, Article $documentationArticle)`
- **Gate:** `prime.documentation-article.update` (singular — BUG)
- **Validation:** `'is_published' => 'required|boolean'`
- **Logic:** Updates `is_published` column, saves
- **Response:** JSON `{ success: true, is_published: bool, message: string }`
- **Audit:** `activityLog($article, 'Toggled', ['message' => 'Documentation article status toggled.'])`

### 5.3 `DocumentationController`

#### `index(Request $request)`
- **Gate:** `prime.documentation-mgt.viewAny`
- **Logic:** Fetches both `categories` (with parent) and `articles` (with categories, author) with standalone search/type/status filters and pagination (10 each)
- **View:** `documentation::index` with `compact('categories', 'articles')`
- **Purpose:** Tabbed management hub with Categories tab + Articles tab

#### `mainDoc()`
- **Gate:** `prime.documentation-mgt.view`
- **Logic:**
  - Reads `?type=` query param (default: `'documentation'`)
  - Fetches root categories where `is_active=true AND type={type}`, ordered by `sort_order`, with active children eagerly loaded
  - Auto-selects first category and first subcategory
  - Fetches articles for selected (sub)category where `is_published=true AND visibility='public' AND type={type}`, ordered by `sort_order`
  - SSR renders first article as `$selectedArticle`
- **View:** `documentation::main-doc.index` with compact variables

#### `getArticlesByCategory($categoryId)`
- **Gate:** `prime.documentation-mgt.view`
- **Logic:** Fetches articles for given category where `is_published=true AND visibility='public'`, eager loads author (id, name), ordered by `sort_order`
- **Response:** JSON `{ success: true, articles: [...] }` or `{ success: false, message, articles: [] }` on exception (500)
- **⚠️ XSS Risk:** Article `content` field returned raw in JSON — injected via `innerHTML` client-side

#### `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`
- **Status:** ❌ **DEAD CODE** — All methods contain only `Gate::authorize()` with empty bodies (except `create()` and `show()` which return placeholder views). These are registered as resource routes within the module's own `routes/web.php` stub (not the global routes) and are unreachable via normal navigation.

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:------------:|
| BR-PRM-DOC-001 | Category cannot be its own parent (`Rule::notIn([$categoryId])`) | ✅ `ValidateCategoryRequest` |
| BR-PRM-DOC-002 | Category `name` and `slug` must be globally unique in `doc_categories` | ✅ Migration UNIQUE + FormRequest validation |
| BR-PRM-DOC-003 | Article `title` and `slug` must be globally unique in `doc_articles` | ✅ Migration UNIQUE + FormRequest validation |
| BR-PRM-DOC-004 | Slug auto-generated from `name`/`title` on create; regenerated on name/title change | ✅ `booted()` hooks on both models |
| BR-PRM-DOC-005 | Category type must be one of: `documentation`, `blog`, `developer`, `help` | ✅ FormRequest `Rule::in([...])` |
| BR-PRM-DOC-006 | Article type must be one of: `documentation`, `blog`, `developer`, `help` | ✅ FormRequest `Rule::in([...])` |
| BR-PRM-DOC-007 | Article visibility must be one of: `public`, `client`, `developer`, `internal`, `draft` | ✅ FormRequest `Rule::in([...])` |
| BR-PRM-DOC-008 | Article with future `published_at` must NOT appear in reader even if `is_published=true` | ✅ `scopePublished()` excludes future dates |
| BR-PRM-DOC-009 | Reader shows only articles where `is_published=true AND visibility='public'` | ✅ Explicit WHERE clauses in `mainDoc()` + `getArticlesByCategory()` |
| BR-PRM-DOC-010 | Reader shows only categories where `is_active=true` | ✅ Explicit WHERE clause in `mainDoc()` |
| BR-PRM-DOC-011 | Category soft delete sets `is_active=false` before `delete()` | ✅ `destroy()` method |
| BR-PRM-DOC-012 | Article soft delete sets `is_published=false` before `delete()` | ✅ `destroy()` method |
| BR-PRM-DOC-013 | CASCADE on `doc_article_category_jnt` ensures M:M cleanup on article/category delete | ✅ Migration FK constraint |
| BR-PRM-DOC-014 | RESTRICT on `doc_categories.parent_id` prevents deleting category with child categories | ✅ Migration FK constraint |
| BR-PRM-DOC-015 | `sort_order` controls display ordering in reader | ✅ `orderBy('sort_order')` in queries; ⚠️ model/migration mismatch |
| BR-PRM-DOC-016 | All mutations must produce audit log entries | ✅ `activityLog()` called on all store/update/destroy/restore/toggle operations |
| BR-PRM-DOC-017 | Image uploads must be restricted to 2 MB max and block SVG files | ❌ Currently 20 MB limit, no MIME restrictions |
| BR-PRM-DOC-018 | Article content must be sanitized before storage to prevent XSS | ❌ Raw HTML stored and rendered |
| BR-PRM-DOC-019 | Unify `store()` and `create()` to use same `create` Gate ability | ❌ Controllers use separate `.store` and `.create` abilities |
| BR-PRM-DOC-020 | Gate strings must use plural entity names matching Policy registration | ❌ Controllers use singular names — Policy never invoked |

---

## 7. Security Rules

| Rule | Implementation | Status |
|------|---------------|:------:|
| Gate check on Category `index` | ⚠️ **MISSING** — any authenticated user can list categories | ❌ |
| Gate check on Article `index` | `prime.documentation-article.viewAny` (singular — BUG) | 🟡 |
| Gate check on Category `create/store` | `prime.documentation-category.create` / `.store` (singular — BUG) | 🟡 |
| Gate check on Article `create/store` | `prime.documentation-article.create` / `.store` (singular — BUG) | 🟡 |
| Gate check on all edit/update/delete/restore/forceDelete | Present but uses singular gate strings | 🟡 |
| Gate check on `uploadImage()` (both controllers) | ⚠️ **MISSING** — unauthenticated upload possible | ❌ |
| Gate check on `toggleStatus()` | Uses singular gate string but present | 🟡 |
| Image upload validation | `max:20048` (20 MB) — should be `max:2048`; SVG not blocked | ❌ |
| Summernote content sanitization | No HTMLPurifier — raw HTML stored `{!! !!}` rendered | ❌ |
| Client-side XSS | `displayArticle()` uses `innerHTML` with raw server content | ❌ |
| Base64 DOM encoding | All article content leaked to DOM via `data-article-content` | 🟡 |
| CSRF protection | All routes on `web` middleware (CSRF token required) | ✅ |
| Soft delete compliance | Both models use `SoftDeletes` trait | ✅ |

---

## 8. UI Screens

### 8.1 Documentation Management Hub
**Route:** `GET /prime/documentation-mgt` | **View:** `documentation::index`
**Gate:** `prime.documentation-mgt.viewAny`

Tabbed management interface with two tabs:
- **Categories tab** — Renders `documentation::category.index` partial with search bar, type dropdown, status dropdown, pagination (10/page), and action buttons (Create, Edit, Trash, toggleStatus, Soft Delete)
- **Articles tab** — Renders `documentation::article.index` partial with same filter/pagination pattern

### 8.2 Documentation Reader (mainDoc)
**Route:** `GET /prime/documentation-intro?type={documentation|blog|developer|help}`
**View:** `documentation::main-doc.index`
**Gate:** `prime.documentation-mgt.view`

| Column | Width | Content |
|--------|:-----:|---------|
| Left sidebar | col-lg-3 | Hierarchical category tree: parent names → click to expand subcategories |
| Center | col-lg-6 | Article body: `{!! $selectedArticle->content !!}` (title, published_at, author, raw HTML) |
| Right sidebar | col-lg-3 | Article list for selected category: clickable title + excerpt cards |
| Floating button | — | Dark/Light mode toggle (persisted in `localStorage.docTheme`) |

### 8.3 Category Create/Edit

| Field | Input Type | Validation | Notes |
|-------|:----------:|------------|-------|
| Name | Text (required) | max:150, unique | |
| Slug | Text (auto) | max:180, unique | Read-only auto-generated |
| Parent Category | Select | nullable, exists, not self | Root categories only in dropdown |
| Type | Select (required) | enum: documentation/blog/developer/help | |
| Description | Textarea | nullable | Sanitized via trait |
| Meta Title | Text | nullable, max:255 | |
| Meta Description | Text | nullable, max:300 | |
| Sort Order | Number | nullable, integer, min:0 | ⚠️ Value silently dropped — not in `$fillable` |
| Is Active | Checkbox | boolean | |
| Category Image | File | image, max:20048 | ⚠️ 20 MB limit too large |

### 8.4 Article Create/Edit

| Field | Input Type | Validation | Notes |
|-------|:----------:|------------|-------|
| Title | Text (required) | max:255, unique | |
| Slug | Text (auto) | max:255, unique | Read-only auto-generated |
| Article Type | Select (required) | enum: documentation/blog/developer/help | |
| Visibility | Select (required) | enum: public/client/developer/internal/draft | |
| Categories | Multi-select | nullable, array, exists:doc_categories | ⚠️ Form uses `name="categories[]"` but controller expects `category_ids` |
| Excerpt | Textarea | nullable, max:500 | |
| Content | Summernote (required) | required | ⚠️ No HTML sanitization |
| Meta Title | Text | nullable, max:255 | |
| Meta Description | Text | nullable, max:300 | |
| Canonical URL | Text | nullable, url | |
| is_indexable | Checkbox | boolean | |
| is_published | Checkbox | boolean | |
| Sort Order | Number | nullable, integer, min:0 | ⚠️ Column missing from migration |
| Featured Image | File | image, max:20048 | ⚠️ 20 MB limit too large |

### 8.5 Trash Views (Categories / Articles)

Paginated lists (10/page) of soft-deleted records with:
- **Restore** button → GET route, returns record to active state
- **Force Delete** button → DELETE route, try/catch error handling
- Category force delete blocked by FK RESTRICT if children exist

### 8.6 Show Views

- **Article Show:** Full article with author name, category badges, article content body
- **Category Show:** Category details with parent name and children list

---

## 9. Workflows

### 9.1 Category Lifecycle

```
[Active — is_active=true]
    |  (toggleStatus: is_active=false)
    v
[Inactive — is_active=false]   ← hidden from reader
    |  (soft delete: is_active=false → delete())
    v
[Trashed — deleted_at IS NOT NULL]
    |  (restore → is_active remains false)
    |
    +--[Force Delete]--→ blocked by FK RESTRICT if children exist
    +--[Force Delete]--→ permanently removed if no children
```

### 9.2 Article Lifecycle

```
[Draft / Unpublished]
    |  (save with is_published=true)
    v
[Published — is_published=true]
    |  (future published_at ? → excluded by scopePublished)
    |
    +--[toggleStatus: is_published=false] → [Unpublished]
    +--[soft delete] → [Trashed — is_published=false first]
                          |
                   [Restore] → [Unpublished or Published depending on previous state]
                          |
                   [Force Delete] → [Permanently Deleted]
```

### 9.3 Content Consumption Flow

```
1. User navigates to GET /prime/documentation-intro?type=documentation
2. Server loads root categories (is_active=true, type=documentation) with children
3. Server auto-selects first category → first subcategory
4. Server loads articles for selected subcategory (is_published=true, visibility=public)
5. Server SSR renders initial article
6. User clicks different category → AJAX GET /prime/documentation/articles/{categoryId}
7. Server returns JSON array of articles (id, title, content, excerpt, published_at, author)
8. Client-side displayArticle() injects content into innerHTML
```

---

## 10. Non-Functional Requirements

| NFR-ID | Category | Requirement | Priority | Status |
|--------|----------|-------------|:--------:|:------:|
| NFR-PRM-DOC-001 | Security | Fix all Gate permission strings from singular to plural (matching Policy registration) | P0 (Critical) | ❌ |
| NFR-PRM-DOC-002 | Security | Add `Gate::authorize()` to `DocumentationCategoryController::index()` | P0 (Critical) | ❌ |
| NFR-PRM-DOC-003 | Security | Add `Gate::authorize()` to both `uploadImage()` methods | P0 (Critical) | ❌ |
| NFR-PRM-DOC-004 | Security | Install `mews/purifier` and sanitize all article `content` before storage and rendering | P0 (Critical) | ❌ |
| NFR-PRM-DOC-005 | Security | Reduce image upload from `max:20048` to `max:2048`; add `mimes:jpg,jpeg,png,gif,webp` to block SVG | P1 (High) | ❌ |
| NFR-PRM-DOC-006 | Security | Fix client-side `displayArticle()` to avoid raw `innerHTML`; sanitize AJAX JSON response content | P0 (Critical) | ❌ |
| NFR-PRM-DOC-007 | Correctness | Add `sort_order` to `Category::$fillable` | P1 (High) | ❌ |
| NFR-PRM-DOC-008 | Correctness | Create migration to add `sort_order` column to `doc_articles` table | P1 (High) | ❌ |
| NFR-PRM-DOC-009 | Correctness | Fix form field name from `categories[]` to `category_ids[]` in article create/edit views | P1 (High) | ❌ |
| NFR-PRM-DOC-010 | Architecture | Unify `store()` and `create()` to share `create` Gate ability | P1 (High) | ❌ |
| NFR-PRM-DOC-011 | Architecture | Extract business logic into `ArticleService` and `CategoryService` | P2 (Medium) | ❌ |
| NFR-PRM-DOC-012 | Architecture | Move `created_by` assignment from FormRequest `prepareForValidation()` to controller `store()` | P2 (Medium) | ❌ |
| NFR-PRM-DOC-013 | Architecture | Implement or remove dead stub methods in `DocumentationController` (store/update/destroy) | P1 (High) | ❌ |
| NFR-PRM-DOC-014 | Correctness | Standardize redirect route names — all should use `central.prime.*` prefix consistently | P2 (Medium) | ❌ |
| NFR-PRM-DOC-015 | Correctness | Move `uploadImage()` response to proper JSON format with `success` boolean and `url` string | P2 (Medium) | ❌ |
| NFR-PRM-DOC-016 | Performance | Add pagination to `getArticlesByCategory()` JSON endpoint (currently unlimited) | P2 (Medium) | ❌ |
| NFR-PRM-DOC-017 | Performance | Cache category tree by type (invalidate on category mutation) | P3 (Low) | ❌ |
| NFR-PRM-DOC-018 | Storage | Clean up orphaned Summernote images on article force delete | P3 (Low) | ❌ |
| NFR-PRM-DOC-019 | Architecture | Move all documentation routes from global `routes/web.php` into module's own `routes/web.php` | P3 (Low) | ❌ |
| NFR-PRM-DOC-020 | Testing | Add feature tests for all CRUD operations, authorization checks, and security scenarios | P1 (High) | ❌ |

---

## 11. Dependencies

### 11.1 Internal

| Module / Component | Type | Usage |
|--------------------|:----:|-------|
| `sys_users` (`Modules\Prime\Models\User`) | Data Read | `Article.author()` — `created_by` FK |
| `sys_activity_logs` | Data Write | `activityLog()` helper on all mutations |
| Spatie Permission (RBAC) | Authorization | `Gate::authorize()` across controller methods |
| Prime-AI RBAC seed data | Configuration | Permissions must be seeded: `prime.documentation-categories.*`, `prime.documentation-articles.*`, `prime.documentation-mgt.*` |

### 11.2 External Packages

| Package | Status | Usage |
|---------|:------:|-------|
| `spatie/laravel-medialibrary` | ✅ Installed | Article + Category featured image upload, conversion, storage |
| `mews/purifier` | ❌ NOT installed | Required for HTML content sanitization |
| Summernote (CDN) | ✅ CDN | WYSIWYG rich-text editor |
| Bootstrap Icons (CDN) | ✅ CDN | UI icons in reader layout |

### 11.3 Scope

The Documentation feature operates entirely on the **central domain** (prime_db). It is NOT tenant-scoped. All tables (`doc_categories`, `doc_articles`, `doc_article_category_jnt`) reside in the central `prime_db` database.

---

## 12. Validation Rules

### 12.1 `ValidateCategoryRequest`

| Field | Rule | Comment |
|-------|------|---------|
| `parent_id` | `nullable`, `exists:doc_categories,id`, `not_in:[current_id]` | Prevents self-parent |
| `name` | `required`, `string`, `max:150`, `unique:doc_categories,name` | Ignore current ID on update |
| `slug` | `required`, `string`, `max:180`, `unique:doc_categories,slug` | Ignore current ID on update; auto-generated if omitted |
| `type` | `required`, `in:documentation,blog,developer,help` | |
| `description` | `nullable`, `string` | Sanitized via trait |
| `meta_title` | `nullable`, `string`, `max:255` | |
| `meta_description` | `nullable`, `string`, `max:300` | |
| `sort_order` | `nullable`, `integer`, `min:0` | ⚠️ Dropped by mass assignment |
| `is_active` | `boolean` | Auto-set to `true` if checkbox present |

### 12.2 `ValidateArticleRequest`

| Field | Rule | Comment |
|-------|------|---------|
| `title` | `required`, `string`, `max:255`, `unique:doc_articles,title` | Ignore current ID on update |
| `slug` | `required`, `string`, `max:255`, `unique:doc_articles,slug` | Ignore current ID on update; auto-generated if omitted |
| `type` | `required`, `in:documentation,blog,developer,help` | |
| `content` | `required`, `string` | ⚠️ No HTML sanitization |
| `excerpt` | `nullable`, `string`, `max:500` | |
| `visibility` | `required`, `in:public,client,developer,internal,draft` | |
| `published_at` | `nullable`, `date` | |
| `meta_title` | `nullable`, `string`, `max:255` | |
| `meta_description` | `nullable`, `string`, `max:300` | |
| `canonical_url` | `nullable`, `url` | |
| `is_indexable` | `boolean` | Auto-set if checkbox present |
| `is_published` | `boolean` | Auto-set if checkbox present |
| `created_by` | `nullable`, `exists:sys_users,id` | Auto-set to `Auth::id()` in `prepareForValidation()` |
| `category_ids` | `nullable`, `array` | |
| `category_ids.*` | `exists:doc_categories,id` | Each must be a valid category |

---

## 13. Known Issues & Gaps

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | Gate permission strings use singular form in controllers — Policy never invoked | Authorization completely bypassed — any user with no explicit deny can access | CRITICAL | ⬜ |
| 2 | `CategoryController::index()` has no Gate check — any authenticated user can list categories | Information disclosure; no authorization enforcement | HIGH | ⬜ |
| 3 | Both `uploadImage()` methods lack Gate check — unauthenticated image upload | Unauthorized file upload; storage abuse | HIGH | ⬜ |
| 4 | Image upload limit is 20 MB (`max:20048`) instead of 2 MB | Storage abuse; SVG XSS vector not blocked | HIGH | ⬜ |
| 5 | Article `content` stored as raw Summernote HTML — no sanitization | Stored XSS when rendered via `{!! !!}` or AJAX `innerHTML` | CRITICAL | ⬜ |
| 6 | `sort_order` not in `Category::$fillable` — mass assignment silently drops value | Functional gap — sort order cannot be set on categories | MEDIUM | ⬜ |
| 7 | `sort_order` column missing from `doc_articles` migration — column referenced in `orderBy()` | SQL error on column-not-found | HIGH | ⬜ |
| 8 | Form field mismatch: `name="categories[]"` vs expected `category_ids` | Category sync on article create/edit silently fails | HIGH | ⬜ |
| 9 | `DocumentationController` has dead stub methods (store/update/destroy with empty bodies) | Confusing dead code; maintenance burden | LOW | ⬜ |
| 10 | `created_by` set in FormRequest `prepareForValidation()` instead of controller | Anti-pattern; FormRequest should not mutate auth state | MEDIUM | ⬜ |
| 11 | No service layer — all business logic in controllers | Hard to test; violates single responsibility | MEDIUM | ⬜ |
| 12 | Inconsistent redirect names: `CategoryController::update()` uses un-prefixed route name | Inconsistent UX; maintenance burden | LOW | ⬜ |
| 13 | `getArticlesByCategory()` returns unlimited results — no pagination | Performance risk with many articles | LOW | ⬜ |
| 14 | No feature tests exist — only 17 structural unit tests | Testing gap | HIGH | ⬜ |
| 15 | Article content leaked to DOM via `data-article-content` base64 attributes | All articles visible in page source regardless of visibility | MEDIUM | ⬜ |
| 16 | `uploadImage()` returns plain string instead of JSON | Poor API design; no error handling on client side | LOW | ⬜ |

---

## 14. Test Scenarios

### 14.1 Existing Tests

**File:** `Modules/Documentation/tests/Unit/DocumentationModuleTest.php` (17 Pest tests)

All 17 tests are **structural/existence assertions**:
- Article model: table name, SoftDeletes, HasMedia, fillable fields, casts, relationships (`categories`, `author`), `scopePublished` method existence
- Category model: table name, SoftDeletes, HasMedia, fillable fields, `is_active` cast, parent/children/childrenRecursive, `scopeActive`, `scopeType`
- Architecture: 3 controller files exist, 2 FormRequest files exist, routes/web.php exists

**Assessment:** Zero functional tests, zero HTTP/feature tests, zero security tests, zero permission tests.

### 14.2 Required Feature Tests

| TC-ID | Type | Scenario | Priority |
|-------|:----:|----------|:--------:|
| TC-PRM-DOC-001 | Feature/HTTP | POST create category with valid data → 302 redirect, record in `doc_categories` | High |
| TC-PRM-DOC-002 | Feature/HTTP | POST create category with duplicate name → 422 validation error | High |
| TC-PRM-DOC-003 | Feature/HTTP | POST create article with `category_ids` → junction records created | High |
| TC-PRM-DOC-004 | Feature/HTTP | POST toggleStatus on article → JSON response, `is_published` toggled in DB | High |
| TC-PRM-DOC-005 | Feature/HTTP | DELETE article → soft deleted (`deleted_at` set, `is_published=false`) | High |
| TC-PRM-DOC-006 | Feature/HTTP | Restore article from trash → `deleted_at` cleared | Medium |
| TC-PRM-DOC-007 | Feature/HTTP | Force delete article → record permanently removed | Medium |
| TC-PRM-DOC-008 | Feature/HTTP | GET `getArticlesByCategory` → only published + public articles returned | High |
| TC-PRM-DOC-009 | Feature/HTTP | GET `mainDoc?type=help` → only help-type categories shown | Medium |
| TC-PRM-DOC-010 | Feature/HTTP | Unauthenticated access → redirect to login | High |
| TC-PRM-DOC-011 | Feature/HTTP | Authenticated without permission → 403 Forbidden | High |
| TC-PRM-DOC-012 | Unit | `scopePublished()` excludes articles with future `published_at` | High |
| TC-PRM-DOC-013 | Unit | Auto-slug generation from title on Article create | Medium |
| TC-PRM-DOC-014 | Security | POST article with XSS content → stored content sanitized | Critical |
| TC-PRM-DOC-015 | Feature/HTTP | Force delete category with child categories → error (FK RESTRICT) | Medium |
| TC-PRM-DOC-016 | Feature/HTTP | POST uploadImage without permission → 403 | High |
| TC-PRM-DOC-017 | Feature/HTTP | POST uploadImage with file > 2 MB → 422 validation error | High |
| TC-PRM-DOC-018 | Feature/HTTP | POST uploadImage with SVG → 422 validation error | High |
| TC-PRM-DOC-019 | Feature/HTTP | Category create with `sort_order` value → value persisted (after fix) | High |

---

## 15. Glossary

| Term | Definition |
|------|-----------|
| Article | Content document with rich HTML (Summernote), type, visibility, SEO metadata, stored in `doc_articles` |
| Category | Hierarchical content container (parent/child, max 2 levels) grouping articles, stored in `doc_categories` |
| Junction Table | `doc_article_category_jnt` — M:M bridge between articles and categories |
| Summernote | Bootstrap-compatible WYSIWYG HTML editor used for article content authoring |
| HTMLPurifier | PHP library for stripping dangerous HTML tags/attributes to prevent XSS |
| Soft Delete | Record marked as deleted (`deleted_at` set) without physical removal |
| Force Delete | Permanent removal of record and associated media files |
| XSS | Cross-Site Scripting — malicious script injection via user-supplied HTML |
| `{!! !!}` | Laravel unescaped output directive — renders raw HTML |
| Visibility | Article audience: `public` (all), `client` (school admins), `developer` (API partners), `internal` (staff only), `draft` (hidden) |
| `scopePublished` | Article scope: `is_published=true AND (published_at IS NULL OR published_at <= now())` |
| mediaCollection | Spatie MediaLibrary collection for file attachment: `doc_article_image`, `doc_category_image` |

---

## 16. Change Log

| Version | Date | Author | Description |
|---------|:----:|--------|-------------|
| V1 | — | — | Initial implementation (code written, no formal doc) |
| V2 | 2026-07-23 | OpenCode | Full requirement document generated from code audit |

---

## Appendices

### A. Route Name Standardization

| Current Redirect | Proposed Redirect | Controller |
|-----------------|-------------------|------------|
| `route('documentation-categories.index')` | `route('central.prime.documentation-categories.index')` | `CategoryController@update` |
| `route('documentation-categories.trashed')` | `route('central.prime.documentation-categories.trashed')` | `CategoryController@restore`, `forceDelete` |
| `route('documentation-categories.index')` | `route('central.prime.documentation-categories.index')` | `CategoryController@destroy` |
| `route('documentation-articles.index')` | `route('central.prime.documentation-articles.index')` | `ArticleController@destroy` |
| `route('documentation-articles.trashed')` | `route('central.prime.documentation-articles.trashed')` | `ArticleController@restore`, `forceDelete` |
| `route('central.prime.documentation-mgt')` | (correct) | `CategoryController@store`, `ArticleController@store`, `ArticleController@update` |

### B. Permission Seeding Requirements

```
prime.documentation-mgt.viewAny
prime.documentation-mgt.view
prime.documentation-mgt.create
prime.documentation-mgt.update
prime.documentation-mgt.delete

prime.documentation-categories.viewAny
prime.documentation-categories.view
prime.documentation-categories.create
prime.documentation-categories.update
prime.documentation-categories.delete
prime.documentation-categories.restore
prime.documentation-categories.forceDelete

prime.documentation-articles.viewAny
prime.documentation-articles.view
prime.documentation-articles.create
prime.documentation-articles.update
prime.documentation-articles.delete
prime.documentation-articles.restore
prime.documentation-articles.forceDelete
```
