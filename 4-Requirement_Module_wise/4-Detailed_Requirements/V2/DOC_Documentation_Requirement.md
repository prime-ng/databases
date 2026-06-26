# DOC — Documentation
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Platform:** Prime-AI Academic Intelligence Platform (ERP + LMS + LXP for Indian K-12 Schools)
**Module Code:** DOC | **Table Prefix:** `doc_` | **Scope:** Central (prime_db / central domain)
**Laravel Module Path:** `Modules/Documentation/` | **Known Completion:** ~65%
**Processing Mode:** FULL — V1 + Gap Analysis + DDL + Controllers + Models read

---

## 1. Executive Summary

The Documentation module is the centrally managed knowledge base and help system for the Prime-AI platform. It is hosted on the central prime domain (not tenant subdomains) and serves as the authoritative content repository for platform documentation, help articles, blog posts, and developer integration guides.

### 1.1 Current State Summary

| Area | Status | Key Finding |
|---|---|---|
| Category CRUD | ✅ ~90% | Full lifecycle implemented; `sort_order` missing from `$fillable` |
| Article CRUD | ✅ ~90% | Full lifecycle implemented; `sort_order` missing from migration |
| Documentation Reader | ✅ ~80% | 3-column browser functional; no search, no view count |
| Authorization (Gate) | 🟡 Bug Present | CRITICAL: singular vs plural permission name mismatch |
| HTML Sanitization | ❌ Not Done | CRITICAL: raw Summernote HTML rendered without sanitization |
| File Upload Validation | 🟡 Bug Present | HIGH: 20 MB upload limit — should be 2–5 MB |
| Service Layer | ❌ Not Done | All business logic in controllers |
| Article Versioning | ❌ Not Done | No revision history |
| Feature Tests | ❌ Not Done | Only structural unit tests exist (17 tests) |

### 1.2 Critical Issues Requiring Immediate Fix

| ID | Severity | Issue |
|---|---|---|
| BUG-002 | CRITICAL | Gate permission strings are singular in controllers but plural in policies — authorization is never enforced via Policy |
| SEC-003 | CRITICAL | Summernote HTML stored and rendered without sanitization — stored XSS risk |
| BUG-001 | CRITICAL | `DocumentationCategoryController::index()` has no Gate check — any authenticated user can list categories |
| SEC-001 | HIGH | Image uploads allow 20 MB files (`max:20048`); should be `max:2048` |
| SEC-002 | HIGH | `uploadImage()` methods on both controllers have no authorization gate check |

### 1.3 V2 Scope

V2 formalizes all V1 requirements, assigns definitive status markers based on code inspection, documents all confirmed bugs as fix requirements, and proposes a set of enhancements (service layer, HTML purifier, caching, search, versioning) needed for production readiness.

---

## 2. Module Overview

### 2.1 Business Purpose

The Documentation module serves as the official knowledge base for the Prime-AI platform. It enables the Prime-AI support and development team to:

- Publish product documentation for school administrators and teachers
- Publish help articles for end-users
- Maintain a developer documentation section for integration partners and API consumers
- Publish blog-style announcements and release notes

### 2.2 Architecture Position

```
Central Domain (prime.yourdomain.com)
    └── Documentation Module (Modules/Documentation/)
            ├── Content Management (Category + Article CRUD) — admin-facing
            └── Content Reader (mainDoc) — consumer-facing
```

The module resides entirely on the central domain. All routes are registered under the `central.prime.*` prefix in the global `routes/web.php`. The module's own `routes/web.php` is a near-empty stub (registers only a default resource route that conflicts with the real routes).

### 2.3 Module Statistics (Verified from Code)

| Component | Count | Details |
|---|---|---|
| Controllers | 3 | `DocumentationController`, `DocumentationArticleController`, `DocumentationCategoryController` |
| Models | 2 | `Article`, `Category` (both in `Modules\Documentation\Models`) |
| Policies | 2 | `DocumentationArticlePolicy`, `DocumentationCategoryPolicy` |
| FormRequests | 2 | `ValidateArticleRequest`, `ValidateCategoryRequest` |
| Services | 0 | No service layer — all logic in controllers |
| Views | 14 | index, main-doc/index, article/[create,edit,index,show,trash], category/[create,edit,index,show,trash], partials/[head,footer] |
| Migrations | 3 | `doc_categories`, `doc_articles`, `doc_article_category_jnt` |
| Seeders | 3 | `DocumentationDatabaseSeeder`, `DocArticleSeeder`, `DocCategorySeeder` |
| Web Routes | 27 | Registered in global `routes/web.php` |
| Tests | 1 file | `DocumentationModuleTest.php` — 17 structural unit tests, 0 feature tests |

### 2.4 Key Technology Dependencies

| Dependency | Usage |
|---|---|
| Spatie MediaLibrary | Featured image upload and conversion for Articles and Categories |
| Spatie Permission (RBAC) | `Gate::authorize()` calls for all controller actions |
| Summernote (CDN) | WYSIWYG rich-text editor for article content authoring |
| `sys_activity_logs` | Audit logging via `activityLog()` helper |
| `sys_users` | Article author reference (`created_by` FK) |
| mews/purifier (proposed) | HTML sanitization for Summernote content (not yet installed) |

---

## 3. Stakeholders & Roles

| Actor | Role | Access Level |
|---|---|---|
| Prime-AI Super Admin | Content owner and publisher | Full CRUD — categories, articles, trash management, force delete |
| Prime-AI Support Team | Content author | Create/edit articles; limited delete permission |
| School Admin (Tenant) | Content consumer | Read-only — published articles via reader |
| Teacher (Tenant) | Content consumer | Read-only — relevant published articles |
| Developer / Integration Partner | Content consumer | Developer-type articles only |
| Student / Parent | Not a primary actor | May access `public` visibility articles if help link is exposed |

### 3.1 Permission Matrix (Canonical — V2 Standardized to Plural)

All Gate permission strings **must** use plural form (`documentation-categories.*` and `documentation-articles.*`) to match the registered Policy methods. The V1 controllers used singular form causing a mismatch.

| Ability | Gate String (Correct — Plural) | Applies To |
|---|---|---|
| View management hub | `prime.documentation-mgt.viewAny` | `DocumentationController@index` |
| View reader | `prime.documentation-mgt.view` | `DocumentationController@mainDoc`, `getArticlesByCategory` |
| List categories | `prime.documentation-categories.viewAny` | `DocumentationCategoryController@index`, `trashed` |
| Create category | `prime.documentation-categories.create` | `DocumentationCategoryController@create`, `store` |
| View category | `prime.documentation-categories.view` | `DocumentationCategoryController@show` |
| Update category | `prime.documentation-categories.update` | `DocumentationCategoryController@edit`, `update`, `toggleStatus` |
| Delete category | `prime.documentation-categories.delete` | `DocumentationCategoryController@destroy` |
| Restore category | `prime.documentation-categories.restore` | `DocumentationCategoryController@restore` |
| Force delete category | `prime.documentation-categories.forceDelete` | `DocumentationCategoryController@forceDelete` |
| List articles | `prime.documentation-articles.viewAny` | `DocumentationArticleController@index`, `trashed` |
| Create article | `prime.documentation-articles.create` | `DocumentationArticleController@create`, `store` |
| View article | `prime.documentation-articles.view` | `DocumentationArticleController@show` |
| Update article | `prime.documentation-articles.update` | `DocumentationArticleController@edit`, `update`, `toggleStatus` |
| Delete article | `prime.documentation-articles.delete` | `DocumentationArticleController@destroy` |
| Restore article | `prime.documentation-articles.restore` | `DocumentationArticleController@restore` |
| Force delete article | `prime.documentation-articles.forceDelete` | `DocumentationArticleController@forceDelete` |
| Upload image | `prime.documentation-articles.create` | Both `uploadImage()` methods (proposed) |

---

## 4. Functional Requirements

### FR-DOC-001: Category Management — Full Lifecycle
**Status:** ✅ Implemented (with minor model gap)

| Sub-ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DOC-001.1 | Create category: name, slug (auto), type, parent, description, sort_order, meta fields | High | ✅ |
| FR-DOC-001.2 | Auto-generate slug from `name` on create; regenerate on name change via `booted()` hook | High | ✅ |
| FR-DOC-001.3 | Parent/child hierarchy — 2 levels; category cannot be its own parent | High | ✅ |
| FR-DOC-001.4 | Category type: `documentation`, `blog`, `developer`, `help` | High | ✅ |
| FR-DOC-001.5 | Upload category featured image via Spatie MediaLibrary (`doc_category_image` collection) | Medium | ✅ |
| FR-DOC-001.6 | Toggle `is_active` via AJAX (`toggleStatus` endpoint) | High | ✅ |
| FR-DOC-001.7 | Soft delete: set `is_active=false` then `delete()` | High | ✅ |
| FR-DOC-001.8 | View trash, restore, force delete (blocked by RESTRICT FK if children exist) | Medium | ✅ |
| FR-DOC-001.9 | Search by name; filter by type and status | Medium | ✅ |
| FR-DOC-001.10 | Audit log all create/update/delete/restore operations | High | ✅ |
| FR-DOC-001.11 | `sort_order` field validated and stored correctly | Medium | 🟡 Bug: not in `Category::$fillable` — silently dropped on mass assign |

**Fix Required (FR-DOC-001.11):** Add `'sort_order'` to `Category::$fillable` array.

### FR-DOC-002: Article Management — Full Lifecycle
**Status:** ✅ Implemented (with form field mismatch and missing migration column)

| Sub-ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DOC-002.1 | Create article: title, slug (auto), type, content (Summernote), excerpt, categories (M:M), visibility, published_at | High | ✅ |
| FR-DOC-002.2 | Auto-generate slug from `title` on create; regenerate on title change | High | ✅ |
| FR-DOC-002.3 | Article type: `documentation`, `blog`, `developer`, `help` | High | ✅ |
| FR-DOC-002.4 | Article visibility: `public`, `client`, `developer`, `internal`, `draft` | High | ✅ |
| FR-DOC-002.5 | `is_published` toggle via AJAX | High | ✅ |
| FR-DOC-002.6 | Scheduled publishing: articles with future `published_at` excluded from reader by `scopePublished()` | Medium | ✅ |
| FR-DOC-002.7 | SEO fields: `meta_title`, `meta_description` (max 300), `canonical_url`, `is_indexable` | Medium | ✅ |
| FR-DOC-002.8 | Featured image upload via Spatie MediaLibrary (`doc_article_image` — 3 conversions: small/medium/large) | Medium | ✅ |
| FR-DOC-002.9 | Summernote in-editor image upload via AJAX to `documentation/articles/summernote/` | Medium | ✅ |
| FR-DOC-002.10 | Assign article to multiple categories (M:M via `doc_article_category_jnt`, `sync()`) | High | ✅ |
| FR-DOC-002.11 | Soft delete: set `is_published=false` then `delete()` | High | ✅ |
| FR-DOC-002.12 | View trash, restore, force delete with try/catch | Medium | ✅ |
| FR-DOC-002.13 | Audit log all article operations including field-level change tracking | High | ✅ |
| FR-DOC-002.14 | `sort_order` field for article display ordering | Medium | 🟡 Bug: column missing from migration; present in `$fillable` and used in `orderBy()` |
| FR-DOC-002.15 | Form field `categories[]` must match validator `category_ids` | High | 🟡 Bug: form sends `categories[]` but FormRequest/controller expects `category_ids` |

**Fix Required (FR-DOC-002.14):** Add `$table->unsignedInteger('sort_order')->default(0);` to `doc_articles` migration.
**Fix Required (FR-DOC-002.15):** In `article/create.blade.php` and `article/edit.blade.php`, rename form field from `categories[]` to `category_ids[]`.

### FR-DOC-003: Documentation Reader (mainDoc)
**Status:** ✅ Implemented (~80%)

| Sub-ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DOC-003.1 | Three-column layout: category sidebar / article content / article list sidebar | High | ✅ |
| FR-DOC-003.2 | Filter displayed content by `?type=` query parameter (default: `documentation`) | High | ✅ |
| FR-DOC-003.3 | Category navigation: expand parent → show subcategories → click to load articles | High | ✅ |
| FR-DOC-003.4 | AJAX article loading when category selected via `getArticlesByCategory($categoryId)` | High | ✅ |
| FR-DOC-003.5 | Auto-select first category and first subcategory on page load (SSR) | Medium | ✅ |
| FR-DOC-003.6 | Dark/light mode toggle (persisted in `localStorage.docTheme`) | Low | ✅ |
| FR-DOC-003.7 | Responsive layout (col-lg grid, sticky sidebars on desktop) | Medium | ✅ |
| FR-DOC-003.8 | Reader shows only articles where `is_published=true AND visibility='public'` | High | ✅ |
| FR-DOC-003.9 | Reader only shows categories where `is_active=true` | High | ✅ |
| FR-DOC-003.10 | Article content rendered via `{!! $selectedArticle->content !!}` — XSS if unsanitized | High | ❌ XSS Risk — no sanitization |
| FR-DOC-003.11 | AJAX-loaded content injected via `innerHTML` in `displayArticle()` JS — XSS via client side | High | ❌ XSS Risk — unsanitized innerHTML |
| FR-DOC-003.12 | Article content stored as `base64_encode` in DOM data attributes — all article content leaked to page | Medium | 🟡 Sub-optimal — leaks content to DOM |

### FR-DOC-004: Authorization and Security
**Status:** 🟡 Partial — Critical bugs present

| Sub-ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DOC-004.1 | All controller actions protected by `Gate::authorize()` | High | 🟡 `CategoryController::index()` missing Gate check |
| FR-DOC-004.2 | Gate strings must use plural form to match Policy: `documentation-categories.*`, `documentation-articles.*` | Critical | ❌ All controllers use singular form — Policy never invoked |
| FR-DOC-004.3 | `store()` and `create()` must share the same Gate permission string | High | ❌ `store()` uses `.store` ability, `create()` uses `.create` — should be unified |
| FR-DOC-004.4 | `uploadImage()` endpoints must require authorization | High | ❌ Both `uploadImage()` methods have no Gate check |
| FR-DOC-004.5 | HTML Purifier must sanitize all Summernote content before storage | Critical | ❌ Not implemented |
| FR-DOC-004.6 | Image upload size limit: max 2 MB (`max:2048`), no SVG allowed | High | ❌ Currently `max:20048` (~20 MB), SVG allowed |
| FR-DOC-004.7 | `uploadImage()` must return JSON response, not plain text URL string | Medium | 🟡 Returns plain `asset()` string — not proper JSON |

### FR-DOC-005: Content Administration — Management Hub
**Status:** ✅ Implemented

The `DocumentationController@index` route (`GET /prime/documentation-mgt`) provides a tabbed management view with both Category and Article management sub-tabs, filterable by search, type, and status. Both tabs paginate at 10 records per page.

### FR-DOC-006: DocumentationController CRUD Stubs
**Status:** ❌ Dead Code — Requires Decision

`DocumentationController::store()`, `update()`, and `destroy()` contain only a `Gate::authorize()` call with empty bodies. These methods are dead routes that accept POST/PUT/DELETE but silently do nothing. They must either be implemented or removed.

### FR-DOC-007: Article Content Versioning
**Status:** ❌ Not Started | 📐 Proposed for V2

No version history or revision tracking exists. When an article is updated, previous content is permanently overwritten. This is a significant gap for a documentation system.

**Proposed V2 Implementation:**
- New table: `doc_article_revisions` (article_id, version_number, content, excerpt, changed_by, changed_at)
- Save snapshot before each `Article::update()` call
- View revision history in article show/edit screen
- Revert to previous revision

### FR-DOC-008: Search Functionality
**Status:** 🟡 Partial | 📐 Proposed Enhancement

Search filters exist in the management index controllers (by title/name, type, status) but there is no search in the reader interface. No dedicated AJAX autocomplete endpoint exists.

**Proposed V2 Implementation:**
- Full-text search across `doc_articles.title`, `doc_articles.excerpt`, and `doc_articles.content`
- Add MySQL FULLTEXT index on `doc_articles(title, excerpt)`
- AJAX search endpoint returning JSON
- Search input in reader header

### FR-DOC-009: Article View Count Tracking
**Status:** ❌ Not Started | 📐 Proposed for V2

No view counting mechanism exists. Adding a `view_count` column to `doc_articles` and incrementing on each `getArticlesByCategory()` access would enable "Most Read" widgets.

### FR-DOC-010: Orphaned Summernote Image Cleanup
**Status:** ❌ Not Started | 📐 Required

Summernote in-editor images are stored permanently at `storage/documentation/articles/summernote/`. There is no cleanup when articles are force-deleted or images are replaced within content. An `Article::deleting` observer or artisan cleanup command is needed.

---

## 5. Data Model

### 5.1 Table: `doc_categories`

Source: `database/migrations/2026_01_09_101501_create_categories_table.php` (verified)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| `name` | VARCHAR(150) | UNIQUE NOT NULL | Display name |
| `slug` | VARCHAR(180) | UNIQUE NOT NULL | Auto-generated from name |
| `parent_id` | BIGINT UNSIGNED | FK doc_categories.id, RESTRICT DELETE, NULLABLE | Self-referencing parent |
| `type` | ENUM | `documentation`, `blog`, `developer`, `help` | INDEX |
| `description` | TEXT | NULLABLE | |
| `meta_title` | VARCHAR(255) | NULLABLE | SEO |
| `meta_description` | VARCHAR(300) | NULLABLE | SEO |
| `is_active` | BOOLEAN | DEFAULT true | |
| `sort_order` | UNSIGNED INT | DEFAULT 0 | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft delete |

**Composite Index:** `(type, is_active, sort_order)`
**Spatie Media:** `doc_category_image` — singleFile, conversions: small (100x100), medium (300x300), large (600x600)
**Model Gap:** `sort_order` and `created_by` are NOT in `Category::$fillable` — schema has `sort_order`, model does not expose it.

### 5.2 Table: `doc_articles`

Source: `database/migrations/2026_01_09_102846_create_articles_table.php` (verified)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| `title` | VARCHAR(255) | UNIQUE NOT NULL | |
| `slug` | VARCHAR(255) | UNIQUE NOT NULL | Auto-generated from title |
| `type` | ENUM | `documentation`, `blog`, `developer`, `help` | INDEX |
| `content` | LONGTEXT | NOT NULL | Raw Summernote HTML — XSS risk |
| `excerpt` | TEXT | NULLABLE | Max 500 chars (FormRequest enforced) |
| `is_published` | BOOLEAN | DEFAULT false | |
| `published_at` | TIMESTAMP | NULLABLE | Scheduled publish date |
| `visibility` | ENUM | `public`, `client`, `developer`, `internal`, `draft` | DEFAULT `public`, INDEX |
| `meta_title` | VARCHAR(255) | NULLABLE | |
| `meta_description` | VARCHAR(300) | NULLABLE | |
| `canonical_url` | VARCHAR(255) | NULLABLE | |
| `is_indexable` | BOOLEAN | DEFAULT true | |
| `created_by` | BIGINT UNSIGNED | FK sys_users.id, NULL ON DELETE | Author |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft delete |

**Composite Index:** `(type, is_published, published_at)`
**Missing Column (CONFIRMED BUG):** `sort_order` — NOT in migration but IS in `Article::$fillable` and used in `orderBy('sort_order')` queries. Will cause MySQL query errors on unindexed column reference.
**Spatie Media:** `doc_article_image` — singleFile, conversions: small/medium/large

### 5.3 Table: `doc_article_category_jnt`

Source: `database/migrations/2026_01_09_170811_create_article_categories_table.php` (verified)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| `article_id` | BIGINT UNSIGNED | FK doc_articles.id, CASCADE DELETE | |
| `category_id` | BIGINT UNSIGNED | FK doc_categories.id, CASCADE DELETE | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

**Unique Constraint:** `(article_id, category_id)` — prevents duplicate mappings

### 5.4 Proposed Table: `doc_article_revisions` (V2 New)
**Status:** 📐 Proposed

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | |
| `article_id` | BIGINT UNSIGNED | FK doc_articles.id, CASCADE DELETE | |
| `version_number` | UNSIGNED SMALLINT | NOT NULL | Increments per article |
| `title` | VARCHAR(255) | NOT NULL | Snapshot of title |
| `content` | LONGTEXT | NOT NULL | Snapshot of content |
| `excerpt` | TEXT | NULLABLE | |
| `changed_by` | BIGINT UNSIGNED | FK sys_users.id, SET NULL | Editor |
| `change_note` | VARCHAR(255) | NULLABLE | Optional change description |
| `created_at` | TIMESTAMP | | |

**Index:** `(article_id, version_number)` — unique per article

### 5.5 Eloquent Models

**Article Model** (`Modules\Documentation\Models\Article`)

| Aspect | Value |
|---|---|
| Table | `doc_articles` |
| Traits | `SoftDeletes`, `InteractsWithMedia` |
| Implements | `HasMedia` |
| Fillable | title, slug, sort_order, type, content, excerpt, is_published, published_at, visibility, meta_title, meta_description, canonical_url, is_indexable, created_by |
| Casts | `is_published` → boolean, `is_indexable` → boolean, `published_at` → datetime |
| Relationships | `categories()` BelongsToMany via `doc_article_category_jnt`; `author()` BelongsTo `sys_users` via `created_by` |
| Scopes | `scopePublished()` — `is_published=true AND (published_at IS NULL OR published_at <= now())` |
| Boot Hooks | Auto-slug from title on creating; re-slug if title is dirty on updating |
| Missing | `$connection` property not set — database connection is implicit |

**Category Model** (`Modules\Documentation\Models\Category`)

| Aspect | Value |
|---|---|
| Table | `doc_categories` |
| Traits | `SoftDeletes`, `InteractsWithMedia` |
| Implements | `HasMedia` |
| Fillable | name, slug, parent_id, type, description, meta_title, meta_description, is_active |
| Casts | `is_active` → boolean |
| Relationships | `parent()` BelongsTo self; `children()` HasMany self; `childrenRecursive()` HasMany with nested eager loading |
| Scopes | `scopeActive()` — `is_active=true`; `scopeType(string $type)` — filter by type |
| Boot Hooks | Auto-slug from name on creating; re-slug if name is dirty on updating |
| Gap | `sort_order` NOT in `$fillable` despite being in migration and validated in FormRequest |

---

## 6. API Endpoints & Routes

### 6.1 All Routes (Registered in Global `routes/web.php`, Central Domain)

All routes require `auth` middleware on the central domain. Route name prefix: `central.prime.*`

| # | Method | URI | Controller@Method | Route Name Suffix |
|---|---|---|---|---|
| 1 | GET | `/prime/documentation-mgt` | `DocumentationController@index` | `documentation-mgt` |
| 2 | GET | `/prime/documentation-intro` | `DocumentationController@mainDoc` | `documentation-intro` |
| 3 | GET | `/prime/documentation/articles/{categoryId}` | `DocumentationController@getArticlesByCategory` | `documentation.articles.by-category` |
| 4 | GET | `/prime/documentation-categories` | `DocumentationCategoryController@index` | `documentation-categories.index` |
| 5 | GET | `/prime/documentation-categories/create` | `DocumentationCategoryController@create` | `documentation-categories.create` |
| 6 | POST | `/prime/documentation-categories` | `DocumentationCategoryController@store` | `documentation-categories.store` |
| 7 | GET | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@show` | `documentation-categories.show` |
| 8 | GET | `/prime/documentation-categories/{id}/edit` | `DocumentationCategoryController@edit` | `documentation-categories.edit` |
| 9 | PUT/PATCH | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@update` | `documentation-categories.update` |
| 10 | DELETE | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@destroy` | `documentation-categories.destroy` |
| 11 | GET | `/prime/documentation-categories/trash/view` | `DocumentationCategoryController@trashed` | `documentation-categories.trashed` |
| 12 | GET | `/prime/documentation-categories/{id}/restore` | `DocumentationCategoryController@restore` | `documentation-categories.restore` |
| 13 | DELETE | `/prime/documentation-categories/{id}/force-delete` | `DocumentationCategoryController@forceDelete` | `documentation-categories.forceDelete` |
| 14 | POST | `/prime/documentation-categories/{cat}/toggle-status` | `DocumentationCategoryController@toggleStatus` | `documentation-categories.toggleStatus` |
| 15 | POST | `/prime/documentation/upload-image` | `DocumentationCategoryController@uploadImage` | `documentation.upload-image` |
| 16 | GET | `/prime/documentation-articles` | `DocumentationArticleController@index` | `documentation-articles.index` |
| 17 | GET | `/prime/documentation-articles/create` | `DocumentationArticleController@create` | `documentation-articles.create` |
| 18 | POST | `/prime/documentation-articles` | `DocumentationArticleController@store` | `documentation-articles.store` |
| 19 | GET | `/prime/documentation-articles/{id}` | `DocumentationArticleController@show` | `documentation-articles.show` |
| 20 | GET | `/prime/documentation-articles/{id}/edit` | `DocumentationArticleController@edit` | `documentation-articles.edit` |
| 21 | PUT/PATCH | `/prime/documentation-articles/{id}` | `DocumentationArticleController@update` | `documentation-articles.update` |
| 22 | DELETE | `/prime/documentation-articles/{id}` | `DocumentationArticleController@destroy` | `documentation-articles.destroy` |
| 23 | GET | `/prime/documentation-articles/trash/view` | `DocumentationArticleController@trashed` | `documentation-articles.trashed` |
| 24 | GET | `/prime/documentation-articles/{id}/restore` | `DocumentationArticleController@restore` | `documentation-articles.restore` |
| 25 | DELETE | `/prime/documentation-articles/{id}/force-delete` | `DocumentationArticleController@forceDelete` | `documentation-articles.forceDelete` |
| 26 | POST | `/prime/documentation-articles/{art}/toggle-status` | `DocumentationArticleController@toggleStatus` | `documentation-articles.toggleStatus` |
| 27 | POST | `/prime/documentation/articles/upload-image` | `DocumentationArticleController@uploadImage` | `documentation-articles.upload-image` |

### 6.2 AJAX / JSON Endpoints

**`getArticlesByCategory($categoryId)` — GET `/prime/documentation/articles/{categoryId}`**

Success response:
```json
{
    "success": true,
    "articles": [
        {
            "id": 1,
            "title": "Getting Started",
            "content": "<p>Sanitized HTML content</p>",
            "excerpt": "Brief summary",
            "published_at": "January 1, 2026",
            "author_name": "Admin User"
        }
    ]
}
```

Note (V2): The `content` field in this JSON response is the raw HTML that gets injected via `innerHTML` in the JavaScript `displayArticle()` function. This must be sanitized server-side before being included in the JSON response.

**`toggleStatus()` — POST `/prime/documentation-articles/{art}/toggle-status`**
```json
{ "success": true, "is_published": true, "message": "Status updated successfully" }
```

**`toggleStatus()` — POST `/prime/documentation-categories/{cat}/toggle-status`**
```json
{ "success": true, "is_active": true, "message": "Status updated successfully" }
```

**`uploadImage()` — POST endpoints (proposed V2 JSON format)**
```json
{ "success": true, "url": "https://domain.com/storage/documentation/articles/summernote/filename.jpg" }
```
Current implementation returns a plain string — should return JSON for proper error handling.

### 6.3 Route Issues (V2 Fix Required)

| Issue | Description | Fix |
|---|---|---|
| Module `web.php` is a stub | Module's own `routes/web.php` registers a conflicting resource route; all real routes are in global `web.php` | Move all documentation routes into module's `routes/web.php` |
| Inconsistent redirect names | `CategoryController::update()` redirects to `documentation-categories.index` (no prefix) vs `store()` which redirects to `central.prime.documentation-mgt` | Standardize all redirects to use `central.prime.*` prefix |
| `getArticlesByCategory` is a web route | Returns JSON but registered as a web route — no proper content negotiation | Move to `routes/api.php` as an API endpoint |

---

## 7. UI Screens

### 7.1 Screen: Documentation Management Hub
**Route:** `GET /prime/documentation-mgt` | **View:** `documentation::index`
**Gate:** `prime.documentation-mgt.viewAny`

Tabbed management interface with "Categories" tab and "Articles" tab. Each tab includes its respective index partial (category.index / article.index) with search input, type filter dropdown, and status filter. Both are paginated at 10 records per page.

### 7.2 Screen: Documentation Reader (mainDoc)
**Route:** `GET /prime/documentation-intro?type={documentation|blog|developer|help}` | **View:** `documentation::main-doc.index`
**Gate:** `prime.documentation-mgt.view`

| Column | Contents |
|---|---|
| Left sidebar (col-lg-3) | Hierarchical category list: parent categories with collapsible subcategory buttons |
| Center (col-lg-6) | Selected article: title, published_at, author name, `{!! $selectedArticle->content !!}` (sanitization required) |
| Right sidebar (col-lg-3) | Article list for selected category: clickable cards with title + excerpt |
| Floating button | Dark/Light mode toggle (top-right, persisted in `localStorage.docTheme`) |

**V2 Note:** The `displayArticle()` JavaScript function injects `article.content` directly into `innerHTML` after `atob()` decode. This creates a client-side XSS path even if server-side content is sanitized. The implementation should render article content server-side only, avoiding base64 encoding articles in DOM data attributes.

### 7.3 Screen: Article Create / Edit
**Route (Create):** `GET /prime/documentation-articles/create`
**Route (Edit):** `GET /prime/documentation-articles/{id}/edit`

| Field | Input | Validation | V2 Fix |
|---|---|---|---|
| Title | Text | required, max:255, unique | |
| Slug | Text (auto) | required, unique | Read-only auto-generated |
| Article Type | Select | required, enum | |
| Visibility | Select | required, enum | |
| Categories | Multi-select | nullable, array, exists | Fix: rename `categories[]` to `category_ids[]` |
| Excerpt | Textarea | nullable, max:500 | |
| Content | Summernote | required | Apply HTMLPurifier before save |
| Meta Title | Text | nullable, max:255 | |
| Meta Description | Text | nullable, max:300 | |
| Canonical URL | Text | nullable, url | |
| is_indexable | Checkbox | boolean | |
| is_published | Checkbox | boolean | |
| Sort Order | Number | nullable, integer, min:0 | Add to form (missing from article create/edit) |
| Featured Image | File | image, max:2048 | Reduce from 20 MB to 2 MB |

### 7.4 Screen: Category Create / Edit
**Route (Create):** `GET /prime/documentation-categories/create`
**Route (Edit):** `GET /prime/documentation-categories/{id}/edit`

| Field | Input | Validation | V2 Fix |
|---|---|---|---|
| Name | Text | required, max:150, unique | |
| Slug | Text (auto) | required, max:180, unique | Read-only auto-generated |
| Parent Category | Select | nullable, exists, not self | |
| Type | Select | required, enum | |
| Description | Textarea | nullable | |
| Meta Title | Text | nullable, max:255 | |
| Meta Description | Text | nullable, max:300 | |
| Sort Order | Number | nullable, integer, min:0 | Add `sort_order` to `$fillable` |
| Is Active | Checkbox | boolean | |
| Category Image | File | image, max:2048 | Reduce from 20 MB to 2 MB |

### 7.5 Screen: Trash Views (Article / Category)

Both trash views display soft-deleted records with paginated list (10/page), restore action, and force delete action. Force delete on categories is blocked by FK RESTRICT if child categories exist.

### 7.6 Screen: Show Views
- `article.show` — Full article view with author, categories, and content
- `category.show` — Category view with parent and children relationships

---

## 8. Business Rules

| ID | Rule | Status |
|---|---|---|
| BR-DOC-001 | A category cannot be its own parent (`Rule::notIn([$categoryId])` in `ValidateCategoryRequest`) | ✅ |
| BR-DOC-002 | Category `name` and `slug` must be globally unique within `doc_categories` | ✅ |
| BR-DOC-003 | Article `title` and `slug` must be globally unique within `doc_articles` | ✅ |
| BR-DOC-004 | An article with `published_at` in the future must NOT appear in the reader even if `is_published=true` | ✅ `scopePublished()` |
| BR-DOC-005 | The reader (`mainDoc`) shows only articles where `is_published=true AND visibility='public'` | ✅ |
| BR-DOC-006 | When a category is deleted, its articles are NOT deleted — only junction records cascade | ✅ |
| BR-DOC-007 | When an article is soft-deleted, `is_published` is set to `false` before deletion | ✅ |
| BR-DOC-008 | When a category is soft-deleted, `is_active` is set to `false` before deletion | ✅ |
| BR-DOC-009 | Summernote in-editor images are stored at `storage/documentation/articles/summernote/` — permanent until manually cleaned | 🟡 No cleanup on article delete |
| BR-DOC-010 | Article `content` column stores raw HTML. All content MUST be sanitized via HTMLPurifier before storage and before rendering | ❌ Not enforced |
| BR-DOC-011 | The `?type=` parameter scopes the entire reader — categories and articles of other types are hidden | ✅ |
| BR-DOC-012 | Parent category without children loads articles on selection; parent with children expands subcategories first | ✅ |
| BR-DOC-013 | Force delete of a category with active child categories must be blocked (FK RESTRICT enforces at DB level) | ✅ (DB constraint) |
| BR-DOC-014 | All Gate permission strings must use plural entity names to match registered Policy classes | ❌ Currently singular — mismatch |
| BR-DOC-015 | Image uploads must not exceed 2 MB per file and must not accept SVG format | ❌ Currently 20 MB, SVG not blocked |
| BR-DOC-016 | `uploadImage()` endpoints require the same authorization as article/category `create` | ❌ No Gate on uploadImage |
| BR-DOC-017 | `store()` and `create()` controller methods must share the same Gate ability name | ❌ `store()` uses `.store` ability; `create()` uses `.create` |

---

## 9. Workflows

### 9.1 Article Lifecycle State Machine

```
[Draft Created]
    |  (save: is_published=false OR visibility='draft')
    v
[Draft / Unpublished]
    |  (admin publishes: is_published=true)
    v
[Published — Active]
    |  (admin toggles off OR admin soft-deletes)
    |
    +--[is_published=false]--->[Unpublished]
    |                              |
    +--[soft delete]------------>[Trashed]  ← is_published set false before delete
                                    |
                        [Restore]---+  (returns to Unpublished)
                                    |
                        [Force Delete] → [Permanently Deleted]
```

**Scheduled Publishing Sub-Flow:**
- Article saved with `is_published=true` AND `published_at` = future timestamp
- `scopePublished()` excludes this article (future date check)
- No cron job required — query-time evaluation at read
- Article becomes visible automatically when `published_at <= now()`

### 9.2 Category Lifecycle State Machine

```
[Active]
    |  (toggleStatus: is_active=false)
    v
[Inactive]  ← still in admin, hidden from reader
    |  (soft delete: is_active=false first, then delete())
    v
[Trashed]
    |  (restore)
    v
[Active or Inactive]  ← restore returns to previous state
    |  (force delete — blocked if child categories exist)
    v
[Permanently Deleted]
```

### 9.3 Content Consumption Flow (Reader)

```
1. User: GET /prime/documentation-intro?type=documentation
2. Server: fetch root categories (is_active=true, type=documentation), eager-load active children
3. Server: auto-select first category, first subcategory (if any)
4. Server: fetch articles for selected (sub)category (is_published=true, visibility=public)
5. Server: SSR first article as $selectedArticle
6. Client: render 3-column layout with pre-selected content
7. Client: click different category → AJAX GET /prime/documentation/articles/{categoryId}
8. Server: return articles JSON (content field included — must be pre-sanitized)
9. Client: displayArticle() → inject into innerHTML (XSS risk if not sanitized server-side)
```

### 9.4 Proposed Content Creation Workflow (With Service Layer)

```
1. Admin: POST /prime/documentation-articles (ValidateArticleRequest)
2. DocumentationArticleController@store:
    a. Gate::authorize('prime.documentation-articles.create')
    b. $validated = $request->validated()
    c. $validated['content'] = HTMLPurifier::clean($validated['content'])  ← V2 ADD
    d. $validated['created_by'] = Auth::id()                               ← move from FormRequest
    e. ArticleService::create($validated, $request->category_ids, $request->file('doc_article_image'))
3. ArticleService:
    a. DB::transaction()
    b. Article::create($validated)
    c. $article->categories()->sync($categoryIds)
    d. Handle media upload if file present
    e. activityLog($article, 'Created', [...])
4. Return redirect with success flash
```

---

## 10. Non-Functional Requirements

| ID | Category | Requirement | Priority | Status |
|---|---|---|---|---|
| NFR-DOC-001 | Security — Critical | Sanitize `content` field using `mews/purifier` (HTML Purifier) before DB storage AND before rendering. Must strip `<script>`, event handlers, `javascript:` URLs. | P0 | ❌ |
| NFR-DOC-002 | Security — Critical | Fix `displayArticle()` JS: article content must be sanitized server-side; do not use `innerHTML` with raw server-returned content. Replace base64 DOM storage with SSR-only or sanitized content. | P0 | ❌ |
| NFR-DOC-003 | Security — Critical | Fix all Gate permission strings: change from singular (`documentation-article`, `documentation-category`) to plural (`documentation-articles`, `documentation-categories`) across all controllers. Unify `store()` to use `create` ability. | P0 | ❌ |
| NFR-DOC-004 | Security | Add `Gate::authorize()` to `DocumentationCategoryController::index()` | P0 | ❌ |
| NFR-DOC-005 | Security | Add `Gate::authorize()` to both `uploadImage()` methods | P1 | ❌ |
| NFR-DOC-006 | Security | Reduce image upload from `max:20048` to `max:2048`; add `mimes:jpg,jpeg,png,gif,webp` to block SVG | P1 | ❌ |
| NFR-DOC-007 | Correctness | Add `sort_order` column to `doc_articles` migration (new migration); add `sort_order` to `Category::$fillable` | P1 | ❌ |
| NFR-DOC-008 | Correctness | Fix form field name: `create.blade.php` and `edit.blade.php` must use `name="category_ids[]"` not `name="categories[]"` | P1 | ❌ |
| NFR-DOC-009 | Architecture | Extract `ArticleService` and `CategoryService` — move business logic out of controllers | P2 | ❌ |
| NFR-DOC-010 | Architecture | Move `created_by` assignment from `ValidateArticleRequest::prepareForValidation()` to controller | P2 | 🟡 Anti-pattern |
| NFR-DOC-011 | Architecture | Implement or remove dead stub methods in `DocumentationController` (store/update/destroy) | P1 | ❌ |
| NFR-DOC-012 | Performance | Cache category tree per `type` (rarely changes). Use `Cache::remember('doc-categories-{type}', 3600, ...)`. Invalidate on category mutation. | P2 | ❌ |
| NFR-DOC-013 | Performance | Add pagination to `getArticlesByCategory()` JSON endpoint (currently fetches all without limit) | P2 | ❌ |
| NFR-DOC-014 | Storage | Implement cleanup of orphaned Summernote images on article `deleting` event | P3 | ❌ |
| NFR-DOC-015 | Correctness | Add explicit `$connection` property to both Article and Category models if module uses prime_db (not tenant_db) | P3 | ❌ |
| NFR-DOC-016 | Routes | Move all documentation routes from global `web.php` into module's own `routes/web.php` | P3 | ❌ |
| NFR-DOC-017 | SEO | Add `robots.txt` considerations for `is_indexable=false` articles | P3 | ❌ |

---

## 11. Dependencies

### 11.1 Internal Dependencies

| Module / Component | Type | Usage |
|---|---|---|
| `sys_users` table | Data Read | `Article.author()` — `created_by` FK |
| `sys_activity_logs` | Data Write | `activityLog()` helper on all mutations |
| Spatie Permission (RBAC) | Authorization | `Gate::authorize()` across all controller methods |
| Prime-AI RBAC seed data | Config | Gate permissions must be seeded in `sys_permissions` |

### 11.2 External Package Dependencies

| Package | Version | Usage | Risk |
|---|---|---|---|
| `spatie/laravel-medialibrary` | Installed | Article + Category image upload, conversion, storage | Low |
| `mews/purifier` (Laravel HTMLPurifier) | NOT installed | Required for content sanitization | CRITICAL — install immediately |
| Summernote | CDN (jsDelivr) | Rich text editor in article create/edit views | Medium — CDN dependency |
| Bootstrap Icons | CSS | Reader sidebar icons | Low |

### 11.3 Module Isolation

The Documentation module is **central scope only** — it does not run per-tenant. Tables (`doc_categories`, `doc_articles`, `doc_article_category_jnt`) reside in `prime_db` (central database), not in any `tenant_db`. The `$connection` property should be explicitly set on both models to enforce this.

---

## 12. Test Scenarios

### 12.1 Existing Tests (Verified: `tests/Unit/DocumentationModuleTest.php`)

17 structural Pest tests covering:
- Article model: table name, SoftDeletes trait, HasMedia, fillable fields, casts, relationships, scopePublished method
- Category model: table name, SoftDeletes, HasMedia, fillable, is_active cast, parent/children/childrenRecursive, scopeActive, scopeType
- Architecture: 3 controller files exist, 2 FormRequest files exist, routes/web.php exists

**Assessment:** All 17 tests are structural/existence assertions. Zero functional, HTTP, security, or integration tests.

### 12.2 Required Feature Tests (V2 — All New)

| ID | Type | Scenario | Priority |
|---|---|---|---|
| TC-DOC-001 | Feature/HTTP | POST create category with valid data → 302 redirect, record in `doc_categories` | High |
| TC-DOC-002 | Feature/HTTP | POST create category with duplicate name → 422 validation error | High |
| TC-DOC-003 | Feature/HTTP | POST create article with `category_ids` → junction records in `doc_article_category_jnt` | High |
| TC-DOC-004 | Feature/HTTP | POST toggleStatus on article → JSON response, `is_published` updated in DB | High |
| TC-DOC-005 | Feature/HTTP | DELETE article → `deleted_at` set, `is_published` = false, soft deleted | High |
| TC-DOC-006 | Feature/HTTP | Restore article from trash → `deleted_at` cleared | Medium |
| TC-DOC-007 | Feature/HTTP | Force delete article → record permanently removed | Medium |
| TC-DOC-008 | Feature/HTTP | GET `getArticlesByCategory` → only published + public articles returned in JSON | High |
| TC-DOC-009 | Feature/HTTP | GET `mainDoc?type=help` → only help-type categories shown | Medium |
| TC-DOC-010 | Feature/HTTP | Unauthenticated GET `/prime/documentation-mgt` → redirect to login | High |
| TC-DOC-011 | Feature/HTTP | Authenticated user without permission → 403 Forbidden | High |
| TC-DOC-012 | Unit | `scopePublished()` excludes articles with future `published_at` | High |
| TC-DOC-013 | Unit | `scopePublished()` excludes articles where `is_published=false` | High |
| TC-DOC-014 | Unit | Auto-slug generated from title on Article create | Medium |
| TC-DOC-015 | Unit | Auto-slug regenerated when title changes on update | Medium |
| TC-DOC-016 | Security | POST article with XSS content `<script>alert(1)</script>` → stored content has script stripped | Critical |
| TC-DOC-017 | Security | POST article with `<img onerror=alert(1)>` → stored content has onerror stripped | Critical |
| TC-DOC-018 | Feature/HTTP | Force delete category with child categories → 500/redirect with error (FK RESTRICT) | Medium |
| TC-DOC-019 | Feature/HTTP | POST uploadImage without Gate permission → 403 | High |
| TC-DOC-020 | Feature/HTTP | POST uploadImage with file > 2 MB → 422 validation error | High |
| TC-DOC-021 | Feature/HTTP | POST uploadImage with SVG → 422 validation error | High |
| TC-DOC-022 | Feature/HTTP | POST create article with `categories[]` form field → categories sync correctly (after fix) | High |

### 12.3 Test Implementation Notes

- Use Pest syntax (project convention — `DocumentationModuleTest.php` uses Pest)
- Feature tests: extend `Tests\TestCase` with `use RefreshDatabase`
- Create factory for `Article` and `Category` models
- Mock `activityLog()` helper in unit tests
- Use `Gate::define()` in test setup to bypass RBAC seeder dependency

---

## 13. Glossary

| Term | Definition |
|---|---|
| Article | A content document with title, rich HTML content (Summernote), type, visibility, and SEO metadata stored in `doc_articles` |
| Category | A hierarchical content container (parent/child, max 2 levels) that groups articles, stored in `doc_categories` |
| Junction Table | `doc_article_category_jnt` — the many-to-many bridge between articles and categories |
| Summernote | Open-source Bootstrap-compatible WYSIWYG HTML editor used for article content authoring |
| HTMLPurifier | PHP library (`mews/purifier`) that strips dangerous HTML tags/attributes to prevent XSS |
| Soft Delete | Marking a record as deleted (`deleted_at` timestamp set) without physical removal |
| Force Delete | Permanently removing a record and its Spatie media files from the DB and storage |
| XSS | Cross-Site Scripting — malicious scripts injected via user-supplied HTML and executed in browsers |
| `{!! !!}` | Laravel's unescaped output directive — renders raw HTML; dangerous for user-supplied content |
| Visibility | Article audience control: `public` (all), `client` (school admins), `developer` (API partners), `internal` (staff only), `draft` (hidden) |
| scopePublished | Eloquent query scope on Article: `is_published=true AND (published_at IS NULL OR published_at <= now())` |
| Central Domain | The `prime.yourdomain.com` domain hosting the central admin panel and Documentation module |
| Gate Permission | Laravel authorization gate string (e.g., `prime.documentation-articles.viewAny`) registered in RBAC |
| Singular/Plural Mismatch | BUG: Controllers use `documentation-article` (singular) but Policies register `documentation-articles` (plural) — policies are never invoked |
| Media Collection | Spatie MediaLibrary named collection for file attachment (`doc_article_image`, `doc_category_image`) |

---

## 14. Suggestions (V2 Analyst Recommendations)

### P0 — Critical (Fix Before Any Release)

1. **Install `mews/purifier` and sanitize all article content.** Run `HTMLPurifier::clean($content)` in the `store()` and `update()` methods of `DocumentationArticleController` before calling `Article::create()` / `$article->update()`. This is the single highest-priority fix. The `{!! $selectedArticle->content !!}` in `main-doc/index.blade.php` must render only pre-sanitized content.

2. **Fix all Gate permission strings to use plural form.** In `DocumentationArticleController` and `DocumentationCategoryController`, change every `Gate::authorize('prime.documentation-article.*')` call to `Gate::authorize('prime.documentation-articles.*')` and every `prime.documentation-category.*` to `prime.documentation-categories.*`. Without this fix, policies are never invoked and all Gate-based authorization is silently bypassed.

3. **Add `Gate::authorize('prime.documentation-categories.viewAny')` to `DocumentationCategoryController::index()`.** Any authenticated user can currently list all categories.

4. **Unify `store()` and `create()` Gate ability.** Change `Gate::authorize('prime.documentation-articles.store')` to `Gate::authorize('prime.documentation-articles.create')` and same for categories. Laravel convention is that `store()` is the POST handler for `create()` — they share the same permission.

### P1 — High (Fix Before Production Deployment)

5. **Reduce image upload limit.** In both `uploadImage()` methods, change `'image' => 'required|image|max:20048'` to `'image' => 'required|mimes:jpg,jpeg,png,gif,webp|max:2048'`. This blocks SVG (which can contain XSS) and limits uploads to 2 MB.

6. **Add Gate checks to `uploadImage()` methods.** Add `Gate::authorize('prime.documentation-articles.create')` to `DocumentationArticleController::uploadImage()` and `Gate::authorize('prime.documentation-categories.create')` to `DocumentationCategoryController::uploadImage()`.

7. **Fix form field name in article views.** In `article/create.blade.php` and `article/edit.blade.php`, rename the categories multi-select from `name="categories[]"` to `name="category_ids[]"` to match `ValidateArticleRequest` and the controller's `$request->filled('category_ids')` check.

8. **Add `sort_order` migration for `doc_articles`.** Create a new migration: `$table->unsignedInteger('sort_order')->default(0)->after('excerpt');`. The column is referenced in `orderBy('sort_order')` queries but does not exist in the migration.

9. **Add `sort_order` to `Category::$fillable`.** The `doc_categories` migration has `sort_order` and `ValidateCategoryRequest` validates it, but `Category.php` `$fillable` array does not include it — values are silently dropped on mass assignment.

10. **Implement or remove `DocumentationController` stubs.** `store()`, `update()`, and `destroy()` in `DocumentationController` accept POST/PUT/DELETE but have empty bodies. Either implement them or remove the routes and methods.

### P2 — Medium (Next Sprint)

11. **Create `ArticleService` and `CategoryService`.** Extract query logic (especially `mainDoc` loading with eager-loaded children, and `getArticlesByCategory`) into dedicated service classes. This enables proper unit testing and reduces controller complexity.

12. **Move `created_by` assignment from FormRequest to controller.** `ValidateArticleRequest::prepareForValidation()` sets `'created_by' => Auth::id()` — this is an anti-pattern. Move it to the controller's `store()` method after `$request->validated()`.

13. **Add category tree caching.** Category trees change infrequently. Cache `doc-categories-{type}` for 1 hour in `mainDoc()`. Invalidate in `DocumentationCategoryController::store()`, `update()`, and `destroy()` observers.

14. **Eliminate base64 DOM encoding of article content.** Replace the current approach (which encodes all article content into `data-article-content` attributes on the server side and decodes via JS) with server-side rendering of the initial article and AJAX for subsequent selections. This prevents all article content from being leaked to the DOM regardless of whether they are viewed.

### P3 — Low (Technical Debt)

15. **Write feature tests.** At minimum: CRUD roundtrip, Gate enforcement (403 without permission), XSS sanitization test, and `scopePublished` date filtering.

16. **Add `$connection = 'prime'` to `Article` and `Category` models** to enforce that these models only ever query the central database, not any tenant database.

17. **Move routes to module's own `web.php`.** The module's `routes/web.php` is currently a near-empty stub. Moving all 27 routes into it improves module isolation and follows nwidart/laravel-modules conventions.

18. **Implement article versioning (`doc_article_revisions`).** Save content snapshots before each update. Add a revision history UI tab in the article edit view. Allow reverting to previous versions.

19. **Add article view count.** Add `view_count UNSIGNED INT DEFAULT 0` to `doc_articles`. Increment via a lightweight `Model::increment('view_count')` in the reader. Surface as a "Most Read" sidebar widget.

20. **Implement Summernote image cleanup.** Register an `Article::deleting()` observer that scans `$article->content` for `<img src>` references in the Summernote storage path and deletes those files when the article is force-deleted.

---

## 15. Appendices

### 15.1 Gate Permission Mismatch — Full Audit Table

| Controller Method | Current Gate String (Singular — WRONG) | Correct Gate String (Plural) | Policy Method |
|---|---|---|---|
| `ArticleController@index` | `prime.documentation-article.viewAny` | `prime.documentation-articles.viewAny` | `viewAny()` |
| `ArticleController@create` | `prime.documentation-article.create` | `prime.documentation-articles.create` | `create()` |
| `ArticleController@store` | `prime.documentation-article.store` | `prime.documentation-articles.create` | `create()` |
| `ArticleController@show` | `prime.documentation-article.view` | `prime.documentation-articles.view` | `view()` |
| `ArticleController@edit` | `prime.documentation-article.update` | `prime.documentation-articles.update` | `update()` |
| `ArticleController@update` | `prime.documentation-article.update` | `prime.documentation-articles.update` | `update()` |
| `ArticleController@destroy` | `prime.documentation-article.delete` | `prime.documentation-articles.delete` | `delete()` |
| `ArticleController@restore` | `prime.documentation-article.restore` | `prime.documentation-articles.restore` | `restore()` |
| `ArticleController@forceDelete` | `prime.documentation-article.forceDelete` | `prime.documentation-articles.forceDelete` | `forceDelete()` |
| `ArticleController@toggleStatus` | `prime.documentation-article.update` | `prime.documentation-articles.update` | `update()` |
| `CategoryController@index` | *(MISSING — no gate check)* | `prime.documentation-categories.viewAny` | `viewAny()` |
| `CategoryController@create` | `prime.documentation-category.create` | `prime.documentation-categories.create` | `create()` |
| `CategoryController@store` | `prime.documentation-category.store` | `prime.documentation-categories.create` | `create()` |
| `CategoryController@show` | `prime.documentation-category.view` | `prime.documentation-categories.view` | `view()` |
| `CategoryController@edit` | `prime.documentation-category.update` | `prime.documentation-categories.update` | `update()` |
| `CategoryController@update` | `prime.documentation-category.update` | `prime.documentation-categories.update` | `update()` |
| `CategoryController@destroy` | `prime.documentation-category.delete` | `prime.documentation-categories.delete` | `delete()` |
| `CategoryController@trashed` | `prime.documentation-category.viewAny` | `prime.documentation-categories.viewAny` | `viewAny()` |
| `CategoryController@restore` | `prime.documentation-category.restore` | `prime.documentation-categories.restore` | `restore()` |
| `CategoryController@forceDelete` | `prime.documentation-category.forceDelete` | `prime.documentation-categories.forceDelete` | `forceDelete()` |
| `CategoryController@toggleStatus` | `prime.documentation-category.update` | `prime.documentation-categories.update` | `update()` |

### 15.2 Content Type × Visibility Access Matrix

| Type \ Visibility | public | client | developer | internal | draft |
|---|---|---|---|---|---|
| documentation | All authenticated | School admins | — | Prime staff | Hidden |
| blog | All authenticated | School admins | — | Prime staff | Hidden |
| developer | All | — | Dev partners | Prime staff | Hidden |
| help | All authenticated | School admins | — | Prime staff | Hidden |

Note: The current reader only checks `visibility='public'`. Visibility-based access control for `client`, `developer`, and `internal` articles is not yet implemented.

### 15.3 Schema Gap Summary

| Gap | Table | Column | Impact | Fix |
|---|---|---|---|---|
| Missing column | `doc_articles` | `sort_order` | `orderBy('sort_order')` queries fail silently | New migration to add column |
| Missing fillable | `doc_categories` | `sort_order` | Value silently dropped on mass assign | Add to `Category::$fillable` |
| Missing fillable | `doc_categories` | `created_by` | Author not tracked on categories | Add column to migration + model |
| Missing `$connection` | Both models | — | Models may accidentally query tenant DB | Add `$connection = 'prime'` |

### 15.4 Security Issue Quick-Fix Checklist

- [ ] Install `composer require mews/purifier`
- [ ] In `DocumentationArticleController@store`: wrap `$validated['content']` with `clean($validated['content'])`
- [ ] In `DocumentationArticleController@update`: same wrap on content before `$article->update()`
- [ ] In `main-doc/index.blade.php`: keep `{!! $selectedArticle->content !!}` but ensure content is pre-sanitized at storage time
- [ ] Remove base64 DOM encoding of all article content from the server-rendered list
- [ ] Fix `displayArticle()` JS to not use `innerHTML` for content injection — instead use `getArticlesByCategory` only to select which article to load, render via server-side AJAX partial
- [ ] Change all 21 Gate strings from singular to plural across both controllers
- [ ] Add Gate check to `CategoryController::index()`
- [ ] Add Gate checks to both `uploadImage()` methods
- [ ] Change `max:20048` to `max:2048` in both `uploadImage()` validations
- [ ] Add `mimes:jpg,jpeg,png,gif,webp` to `uploadImage()` validations

---

## 16. V1 → V2 Delta

### 16.1 Changes from V1 to V2

| Section | Change | Reason |
|---|---|---|
| Overall status | Revised to ~65% (from V1's ~85% estimate) | Code inspection reveals critical unfixed security bugs and missing features |
| FR-DOC-004 (Authorization) | Expanded to document all 21 Gate mismatches explicitly | V1 noted the issue; V2 provides the full fix table |
| FR-DOC-006 (Stubs) | Added as a requirement to implement or remove | V1 documented as a gap; V2 makes it a formal FR |
| FR-DOC-007 (Versioning) | New 📐 Proposed requirement | Not in V1 |
| FR-DOC-008 (Search) | Elevated from "suggestion" to formal FR | V1 mentioned as suggestion only |
| FR-DOC-009 (View Count) | New 📐 Proposed requirement | Not in V1 |
| FR-DOC-010 (Image Cleanup) | New 📐 Proposed requirement | Not in V1 |
| Section 5 (Data Model) | `sort_order` migration gap confirmed from actual migration file; `created_by` gap on Category confirmed | V1 stated as suspected; V2 confirmed by reading migration source |
| Section 5.4 (Proposed Table) | `doc_article_revisions` schema proposed | New in V2 |
| Section 6.3 (Route Issues) | Redirect inconsistency and JSON endpoint issues formalized | V1 mentioned; V2 formalizes as requirements |
| NFR-DOC-001/002 | HTMLPurifier fix detailed precisely (both storage and render paths) | V1 stated the need; V2 specifies exact implementation points |
| Section 12 (Tests) | Expanded from 15 to 22 test scenarios including security tests | V1 had 15; V2 adds security and authorization test cases |
| Section 14 (Suggestions) | Prioritized P0/P1/P2/P3 with specific implementation guidance | V1 had unnumbered suggestions |
| Section 15 (Appendices) | Added Security Checklist (15.4) and expanded Schema Gap table | New in V2 |

### 16.2 Status Comparison

| Area | V1 Status | V2 Status | Change |
|---|---|---|---|
| Gate permission strings | "Partial — Bug Present" | ❌ CRITICAL | More severe — 21 mismatches documented |
| HTML sanitization | "Done — Security Risk" | ❌ CRITICAL | Reframed as unimplemented security requirement |
| Image upload size | "Done — Size Risk" | ❌ HIGH | Reframed as unfixed security issue |
| `sort_order` on articles | "Missing from schema" | ❌ HIGH | Confirmed from actual migration file |
| `sort_order` on categories | Not explicitly noted | 🟡 Bug | Confirmed: in migration but not in `$fillable` |
| `categories[]` field mismatch | Noted as issue | 🟡 Bug | Confirmed from controller source code |
| Test coverage | "Partial (~65%)" | ❌ Structural Only | 17 tests, all structural — 0 functional |
| Service layer | "Not present" | ❌ Required for P2 | Formalized as architecture requirement |
