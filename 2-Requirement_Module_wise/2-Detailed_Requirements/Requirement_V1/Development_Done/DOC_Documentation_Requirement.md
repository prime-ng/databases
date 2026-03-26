# Documentation Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** DOC | **Module Path:** `Modules/Documentation`
**Module Type:** Other (Internal Knowledge Base) | **Database:** `doc_categories`, `doc_articles`, `doc_article_category_jnt` (module-owned, in prime_db / central DB)
**Table Prefix:** `doc_` | **Processing Mode:** FULL
**RBS Reference:** N/A

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The Documentation module provides a centrally managed knowledge base and help documentation system for the Prime-AI platform. It allows platform administrators (Prime-AI team) to author, categorize, publish, and maintain articles of multiple types (Documentation, Blog, Developer, Help) that are accessible to authorized users from the central admin domain. It is an internal-facing system, not a public website.

### 1.2 Scope

The module is accessible from the central prime domain (`web.php` routes under `central.prime.*`) rather than the tenant domain. It supports two primary functional areas:

1. **Content Management** — CRUD for Categories and Articles with full lifecycle (draft, publish, soft delete, restore, force delete)
2. **Content Consumption** — A reader-facing three-column documentation browser with category navigation, article listing, and rich content display

### 1.3 Module Statistics

| Item | Count |
|---|---|
| Controllers | 3 (`DocumentationController`, `DocumentationArticleController`, `DocumentationCategoryController`) |
| Models | 2 (`Article`, `Category`) |
| Policies | 2 (`DocumentationArticlePolicy`, `DocumentationCategoryPolicy`) |
| Services | 0 |
| FormRequests | 2 (`ValidateArticleRequest`, `ValidateCategoryRequest`) |
| Tests | 1 (`DocumentationModuleTest.php` — Unit, Pest syntax) |
| Views | 14 (index, main-doc/index, article/[create,edit,index,show,trash], category/[create,edit,index,show,trash], partials/[head,footer], components/layouts/master) |
| Migrations | 3 (`doc_categories`, `doc_articles`, `doc_article_category_jnt`) |
| Seeders | 3 (`DocumentationDatabaseSeeder`, `DocArticleSeeder`, `DocCategorySeeder`) |
| Web Routes | 14 (registered in `routes/web.php` central, under `central.prime.*` prefix) |

### 1.4 Implementation Status

| Area | Status | Notes |
|---|---|---|
| Database schema | Complete | 3 migrations fully defined |
| Category CRUD | Complete (~90%) | Full create/edit/delete/restore/forceDelete/toggle-status implemented |
| Article CRUD | Complete (~90%) | Full create/edit/delete/restore/forceDelete/toggle-status + image upload |
| Documentation reader (`mainDoc`) | Complete (~80%) | 3-column browser with AJAX category switching |
| Authorization (Gate) | Partial — Bug Present | Gate uses singular `documentation-article` but Policy checks plural `documentation-articles` |
| Form validation | Complete | Both `ValidateArticleRequest` and `ValidateCategoryRequest` fully implemented |
| Summernote integration | Done — Security Risk | `{!! $selectedArticle->content !!}` renders unsanitized HTML — XSS risk |
| Image upload | Done — Size Risk | Both controllers allow 20 MB uploads (`max:20048`) — no compression |
| Audit logging | Done | `activityLog()` called on all mutating operations |
| Tests | Partial (~65%) | Unit tests for model structure and architecture only — no integration tests |
| Search | Partial | Search filters exist in controller queries but no dedicated search UI/endpoint |

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

The Documentation module serves as the official knowledge base for the Prime-AI platform. It enables the Prime-AI support/development team to:

- Publish product documentation for school administrators
- Publish help articles for end-users
- Maintain a developer documentation section for integration partners
- Publish blog-style announcements or release notes

It provides a structured content hierarchy (Category → Subcategory → Article) with a clean, dark/light-mode-capable reader interface. Content is managed from the central admin panel and consumed by authorized users.

### 2.2 Key Features Summary

1. Hierarchical category management (parent/child, 2 levels)
2. Article creation with Summernote rich text editor
3. Featured image upload (via Spatie Media Library)
4. Article type classification: `documentation`, `blog`, `developer`, `help`
5. Article visibility levels: `public`, `client`, `developer`, `internal`, `draft`
6. Publication control: `is_published` toggle + `published_at` scheduled publishing
7. SEO metadata: `meta_title`, `meta_description`, `canonical_url`, `is_indexable`
8. Soft delete with trash management and restore capability
9. Three-column documentation reader with AJAX article loading
10. Dark/light mode toggle in the reader interface
11. Audit logging on all create/update/delete operations
12. Image upload endpoint for Summernote in-editor image insertion

### 2.3 Menu Navigation Path

**Central Prime Admin Panel:**
- `Documentation > Documentation Management` (index — categories + articles tabs)
- `Documentation > View Documentation` (reader/mainDoc view)
- `Documentation > Categories` (category CRUD)
- `Documentation > Articles` (article CRUD)

### 2.4 Module Architecture (Actual Folder Structure)

```
Modules/Documentation/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── DocumentationController.php         (index, mainDoc, getArticlesByCategory, create/store/show/edit/update/destroy — store/update/destroy are stubs)
│   │   │   ├── DocumentationArticleController.php  (full CRUD + trashed/restore/forceDelete/toggleStatus + uploadImage)
│   │   │   └── DocumentationCategoryController.php (full CRUD + trashed/restore/forceDelete/toggleStatus + uploadImage)
│   │   └── Requests/
│   │       ├── ValidateArticleRequest.php
│   │       └── ValidateCategoryRequest.php
│   ├── Models/
│   │   ├── Article.php                             (SoftDeletes, HasMedia, scopePublished, auto-slug)
│   │   └── Category.php                            (SoftDeletes, HasMedia, self-referencing parent/children, scopeActive, scopeType, auto-slug)
│   ├── Policies/
│   │   ├── DocumentationArticlePolicy.php
│   │   └── DocumentationCategoryPolicy.php
│   └── Providers/
│       ├── DocumentationServiceProvider.php
│       ├── EventServiceProvider.php
│       └── RouteServiceProvider.php
├── config/config.php
├── database/
│   ├── migrations/
│   │   ├── 2026_01_09_101501_create_categories_table.php
│   │   ├── 2026_01_09_102846_create_articles_table.php
│   │   └── 2026_01_09_170811_create_article_categories_table.php
│   └── seeders/
│       ├── DocumentationDatabaseSeeder.php
│       ├── DocArticleSeeder.php
│       └── DocCategorySeeder.php
├── resources/views/
│   ├── index.blade.php                             (management hub — tabbed: categories + articles)
│   ├── main-doc/index.blade.php                    (3-column reader view)
│   ├── article/[create|edit|index|show|trash].blade.php
│   ├── category/[create|edit|index|show|trash].blade.php
│   ├── partials/head.blade.php                     (Summernote CSS/JS + all styling)
│   ├── partials/footer.blade.php                   (Summernote init JS + reader AJAX JS)
│   └── components/layouts/master.blade.php         (module layout — not used by main routes)
├── routes/
│   ├── web.php                                     (minimal — original resource route only)
│   └── api.php
└── tests/Unit/
    └── DocumentationModuleTest.php                 (Pest unit tests — model structure + architecture)
```

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role | Module Access |
|---|---|---|
| Prime-AI Admin | Content author and publisher | Full CRUD — categories, articles, trash management |
| Prime-AI Support Team | Content author | Create/edit articles; may not have delete permission |
| School Admin (Tenant) | Content consumer | Read-only access to published articles via reader |
| Teacher (Tenant) | Content consumer | Read-only access to relevant published articles |
| Developer / Integration Partner | Content consumer | Developer-type articles only |
| Student / Parent | Not a primary actor | May access help articles if visibility = `public` |

---

## 4. FUNCTIONAL REQUIREMENTS

### 4.1 Category Management (FR-DOC-001 through FR-DOC-012)

| ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DOC-001 | Create new category with name, slug, type, description, parent, sort_order | High | Done |
| FR-DOC-002 | Auto-generate slug from name on create; regenerate on name change | High | Done |
| FR-DOC-003 | Support parent/child hierarchy (2 levels) — parent cannot assign itself as parent | High | Done |
| FR-DOC-004 | Category type must be one of: `documentation`, `blog`, `developer`, `help` | High | Done |
| FR-DOC-005 | Upload category image (Spatie MediaLibrary, single file, `doc_category_image` collection) | Medium | Done |
| FR-DOC-006 | Toggle category active/inactive via AJAX (`is_active`) | High | Done |
| FR-DOC-007 | Soft delete category (sets `is_active=false`, soft deletes) | High | Done |
| FR-DOC-008 | View trashed categories | Medium | Done |
| FR-DOC-009 | Restore soft-deleted category | Medium | Done |
| FR-DOC-010 | Permanently force-delete category | Medium | Done (with try/catch) |
| FR-DOC-011 | Search categories by name; filter by type and active status | Medium | Done (controller query) |
| FR-DOC-012 | Audit log all category create/update/delete/restore operations | High | Done |

### 4.2 Article Management (FR-DOC-013 through FR-DOC-028)

| ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DOC-013 | Create article with title, slug, type, content (Summernote), excerpt, categories (multi-select), visibility, published_at | High | Done |
| FR-DOC-014 | Auto-generate slug from title on create; regenerate on title change | High | Done |
| FR-DOC-015 | Article type: `documentation`, `blog`, `developer`, `help` | High | Done |
| FR-DOC-016 | Article visibility: `public`, `client`, `developer`, `internal`, `draft` | High | Done |
| FR-DOC-017 | `is_published` toggle control | High | Done |
| FR-DOC-018 | Scheduled publishing: articles with `published_at` in the future should not appear in public feed | Medium | Done (scopePublished) |
| FR-DOC-019 | SEO fields: meta_title, meta_description (max 300), canonical_url, is_indexable | Medium | Done |
| FR-DOC-020 | Upload featured article image (Spatie MediaLibrary, single file, 3 conversions: small/medium/large) | Medium | Done |
| FR-DOC-021 | Summernote in-editor image upload via AJAX to `documentation/articles/summernote` | Medium | Done |
| FR-DOC-022 | Assign article to multiple categories (M:M via `doc_article_category_jnt`) | High | Done |
| FR-DOC-023 | Toggle `is_published` via AJAX | High | Done |
| FR-DOC-024 | Soft delete article (sets `is_published=false`, then soft deletes) | High | Done |
| FR-DOC-025 | View trashed articles | Medium | Done |
| FR-DOC-026 | Restore soft-deleted article | Medium | Done |
| FR-DOC-027 | Force delete article | Medium | Done (with try/catch) |
| FR-DOC-028 | Audit log all article operations | High | Done |

### 4.3 Documentation Reader (FR-DOC-029 through FR-DOC-035)

| ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DOC-029 | Three-column layout: Category sidebar / Article content / Article list sidebar | High | Done |
| FR-DOC-030 | Filter displayed content by `type` query parameter (default: `documentation`) | High | Done |
| FR-DOC-031 | Category navigation: expand parent → show subcategories → click to load articles | High | Done |
| FR-DOC-032 | AJAX article loading when category is selected (GET `/prime/documentation/articles/{categoryId}`) | High | Done |
| FR-DOC-033 | Auto-select first article when category is opened | Medium | Done |
| FR-DOC-034 | Dark/light mode toggle (persisted in `localStorage.docTheme`) | Low | Done |
| FR-DOC-035 | Responsive layout (col-lg grid, sticky sidebars on desktop, stacked on mobile) | Medium | Done |

### 4.4 Known Gaps and Issues

| Issue | Severity | Description |
|---|---|---|
| XSS Risk in article content rendering | Critical | `main-doc/index.blade.php` line 97: `{!! $selectedArticle->content !!}` renders raw HTML from Summernote without sanitization. An author with `create` permission could inject malicious scripts. |
| XSS Risk in AJAX-rendered content | Critical | `footer.blade.php` `displayArticle()` function: `${article.content}` is injected directly into `innerHTML` without escaping after `atob` decode — even if server-side was sanitized, this JS path is vulnerable. |
| Gate permission mismatch (Policy vs Controller) | High | `DocumentationArticlePolicy` checks `prime.documentation-articles.viewAny` (plural), but `DocumentationArticleController@index` calls `Gate::authorize('prime.documentation-article.viewAny')` (singular). They will never match, causing 403 on all article operations if Policy is registered. |
| Same mismatch for Category Policy | High | `DocumentationCategoryPolicy` uses `prime.documentation-categories.*` but controller uses `prime.documentation-category.*` (singular). |
| Oversized image upload allowed | High | Both `uploadImage` endpoints validate `max:20048` (approx 20 MB). This should be 2 MB (`max:2048`) as stated in the UI hint. No image compression is applied. |
| `DocumentationController` CRUD stubs | Medium | `store()`, `update()`, and `destroy()` methods contain only the Gate authorization call with empty body — they do nothing on POST/PUT/DELETE. |
| Article `category_ids` vs `categories[]` mismatch | Medium | `create.blade.php` uses `name="categories[]"` but `ValidateArticleRequest` validates `category_ids` and `controller@store` checks `$request->filled('category_ids')`. The form field name does not match. |
| Content stored as base64 in HTML data attribute | Low | Article content is stored as `base64_encode($article->content)` in a `data-article-content` HTML attribute in the server-rendered list. This leaks all article content to DOM regardless of whether the article is viewed. |
| Module `web.php` is a stub | Low | The module's own `routes/web.php` only registers the default resource route — all real routes are in the central `web.php`. |

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 Table: `doc_categories`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | Primary key |
| `name` | VARCHAR(150) | UNIQUE, NOT NULL | Display name |
| `slug` | VARCHAR(180) | UNIQUE, NOT NULL | URL-safe identifier, auto-generated |
| `parent_id` | BIGINT UNSIGNED | FK → `doc_categories.id`, RESTRICT DELETE, NULLABLE | Self-referencing parent category |
| `type` | ENUM | `documentation`, `blog`, `developer`, `help`, INDEX | Content type classifier |
| `description` | TEXT | NULLABLE | Category description |
| `meta_title` | VARCHAR(255) | NULLABLE | SEO meta title |
| `meta_description` | VARCHAR(300) | NULLABLE | SEO meta description |
| `is_active` | BOOLEAN | DEFAULT `true` | Active/inactive flag |
| `sort_order` | UNSIGNED INT | DEFAULT `0` | Display ordering |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft delete |

**Composite Index:** `(type, is_active, sort_order)`

**Spatie Media:** `doc_category_image` collection (single file, conversions: small 100x100, medium 300x300, large 600x600)

### 5.2 Table: `doc_articles`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | Primary key |
| `title` | VARCHAR(255) | UNIQUE, NOT NULL | Article title |
| `slug` | VARCHAR(255) | UNIQUE, NOT NULL | URL-safe identifier, auto-generated |
| `type` | ENUM | `documentation`, `blog`, `developer`, `help`, INDEX | Content type |
| `content` | LONGTEXT | NOT NULL | Rich HTML content (from Summernote) |
| `excerpt` | TEXT | NULLABLE | Short summary (max 500 chars per validation) |
| `is_published` | BOOLEAN | DEFAULT `false` | Publication flag |
| `published_at` | TIMESTAMP | NULLABLE | Scheduled publish date |
| `visibility` | ENUM | `public`, `client`, `developer`, `internal`, `draft`, DEFAULT `public`, INDEX | Audience control |
| `meta_title` | VARCHAR(255) | NULLABLE | SEO meta title |
| `meta_description` | VARCHAR(300) | NULLABLE | SEO meta description |
| `canonical_url` | VARCHAR(255) | NULLABLE | Canonical URL |
| `is_indexable` | BOOLEAN | DEFAULT `true` | Search engine indexing flag |
| `created_by` | BIGINT UNSIGNED | FK → `sys_users.id`, NULL ON DELETE, NULLABLE | Author |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft delete |

**Composite Index:** `(type, is_published, published_at)`

**Missing Column:** `sort_order` is present in `ValidateArticleRequest` fillable and used in queries (`->orderBy('sort_order')`) but is **not defined in the migration**. This is a schema gap.

**Spatie Media:** `doc_article_image` collection (single file, conversions: small/medium/large)

### 5.3 Table: `doc_article_category_jnt`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | Primary key |
| `article_id` | BIGINT UNSIGNED | FK → `doc_articles.id`, CASCADE DELETE | Article reference |
| `category_id` | BIGINT UNSIGNED | FK → `doc_categories.id`, CASCADE DELETE | Category reference |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

**Unique:** `(article_id, category_id)` — prevents duplicate mappings

### 5.4 Eloquent Model: `Article`

| Aspect | Value |
|---|---|
| Table | `doc_articles` |
| Traits | `SoftDeletes`, `InteractsWithMedia` |
| Implements | `HasMedia` |
| Key Relationships | `categories()` BelongsToMany via `doc_article_category_jnt`; `author()` BelongsTo `User` via `created_by` |
| Scopes | `scopePublished()` — `is_published=true` AND (`published_at IS NULL` OR `published_at <= now()`) |
| Boot Hooks | Auto-slug on creating; re-slug on title change during updating |
| Media Collections | `doc_article_image` (singleFile) |

### 5.5 Eloquent Model: `Category`

| Aspect | Value |
|---|---|
| Table | `doc_categories` |
| Traits | `SoftDeletes`, `InteractsWithMedia` |
| Implements | `HasMedia` |
| Key Relationships | `parent()` BelongsTo self; `children()` HasMany self; `childrenRecursive()` HasMany with nested eager loading |
| Scopes | `scopeActive()` — `is_active=true`; `scopeType(string $type)` — filter by type |
| Boot Hooks | Auto-slug on creating; re-slug on name change during updating |
| Media Collections | `doc_category_image` (singleFile) |

---

## 6. API & ROUTE SPECIFICATION

### 6.1 Registered Web Routes (central `routes/web.php` under `central.prime.*` prefix)

| # | Method | URI | Controller@Method | Route Name | Auth Guard |
|---|---|---|---|---|---|
| 1 | GET | `/prime/documentation-categories` | `DocumentationCategoryController@index` | `central.prime.documentation-categories.index` | auth (central) |
| 2 | GET | `/prime/documentation-categories/create` | `DocumentationCategoryController@create` | `central.prime.documentation-categories.create` | auth (central) |
| 3 | POST | `/prime/documentation-categories` | `DocumentationCategoryController@store` | `central.prime.documentation-categories.store` | auth (central) |
| 4 | GET | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@show` | `central.prime.documentation-categories.show` | auth (central) |
| 5 | GET | `/prime/documentation-categories/{id}/edit` | `DocumentationCategoryController@edit` | `central.prime.documentation-categories.edit` | auth (central) |
| 6 | PUT/PATCH | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@update` | `central.prime.documentation-categories.update` | auth (central) |
| 7 | DELETE | `/prime/documentation-categories/{id}` | `DocumentationCategoryController@destroy` | `central.prime.documentation-categories.destroy` | auth (central) |
| 8 | GET | `/prime/documentation-categories/trash/view` | `DocumentationCategoryController@trashed` | `central.prime.documentation-categories.trashed` | auth (central) |
| 9 | GET | `/prime/documentation-categories/{id}/restore` | `DocumentationCategoryController@restore` | `central.prime.documentation-categories.restore` | auth (central) |
| 10 | DELETE | `/prime/documentation-categories/{id}/force-delete` | `DocumentationCategoryController@forceDelete` | `central.prime.documentation-categories.forceDelete` | auth (central) |
| 11 | POST | `/prime/documentation-categories/{documentationCategory}/toggle-status` | `DocumentationCategoryController@toggleStatus` | `central.prime.documentation-categories.toggleStatus` | auth (central) |
| 12 | POST | `/prime/documentation/upload-image` | `DocumentationCategoryController@uploadImage` | `central.prime.documentation.upload-image` | auth (central) |
| 13 | GET | `/prime/documentation-mgt` | `DocumentationController@index` | `central.prime.documentation-mgt` | auth (central) |
| 14 | GET | `/prime/documentation-intro` | `DocumentationController@mainDoc` | `central.prime.documentation-intro` | auth (central) |
| 15 | GET | `/prime/documentation-articles` | `DocumentationArticleController@index` | `central.prime.documentation-articles.index` | auth (central) |
| 16 | GET | `/prime/documentation-articles/create` | `DocumentationArticleController@create` | `central.prime.documentation-articles.create` | auth (central) |
| 17 | POST | `/prime/documentation-articles` | `DocumentationArticleController@store` | `central.prime.documentation-articles.store` | auth (central) |
| 18 | GET | `/prime/documentation-articles/{id}` | `DocumentationArticleController@show` | `central.prime.documentation-articles.show` | auth (central) |
| 19 | GET | `/prime/documentation-articles/{id}/edit` | `DocumentationArticleController@edit` | `central.prime.documentation-articles.edit` | auth (central) |
| 20 | PUT/PATCH | `/prime/documentation-articles/{id}` | `DocumentationArticleController@update` | `central.prime.documentation-articles.update` | auth (central) |
| 21 | DELETE | `/prime/documentation-articles/{id}` | `DocumentationArticleController@destroy` | `central.prime.documentation-articles.destroy` | auth (central) |
| 22 | GET | `/prime/documentation-articles/trash/view` | `DocumentationArticleController@trashed` | `central.prime.documentation-articles.trashed` | auth (central) |
| 23 | GET | `/prime/documentation-articles/{id}/restore` | `DocumentationArticleController@restore` | `central.prime.documentation-articles.restore` | auth (central) |
| 24 | DELETE | `/prime/documentation-articles/{id}/force-delete` | `DocumentationArticleController@forceDelete` | `central.prime.documentation-articles.forceDelete` | auth (central) |
| 25 | POST | `/prime/documentation-articles/{documentationArticle}/toggle-status` | `DocumentationArticleController@toggleStatus` | `central.prime.documentation-articles.toggleStatus` | auth (central) |
| 26 | POST | `/prime/documentation/articles/upload-image` | `DocumentationArticleController@uploadImage` | `central.prime.documentation-articles.upload-image` | auth (central) |
| 27 | GET | `/prime/documentation/articles/{categoryId}` | `DocumentationController@getArticlesByCategory` | `central.prime.documentation.articles.by-category` | auth (central) |

### 6.2 JSON Response Format (AJAX Endpoints)

**`getArticlesByCategory($categoryId)` → GET `/prime/documentation/articles/{categoryId}`**

Success:
```json
{
    "success": true,
    "articles": [
        {
            "id": 1,
            "title": "Getting Started",
            "content": "<p>HTML content...</p>",
            "excerpt": "Brief summary",
            "published_at": "January 1, 2026",
            "author_name": "Admin User"
        }
    ]
}
```

Error:
```json
{
    "success": false,
    "message": "Error loading articles",
    "articles": []
}
```

**`toggleStatus($request, Article $documentationArticle)`:**
```json
{
    "success": true,
    "is_published": true,
    "message": "Status updated successfully"
}
```

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

### 7.1 Screen: Documentation Management Hub (`documentation::index`)

**Route:** `GET /prime/documentation-mgt`
**Layout:** `x-prime.layouts.app`
**Description:** Tabbed management view with "Categories" and "Articles" tabs, each loading their respective index partial.

| Element | Description |
|---|---|
| Tab: Categories | Includes `documentation::category.index` |
| Tab: Articles | Includes `documentation::article.index` |
| Breadcrumb | "Documentation Management > Documentation" |

### 7.2 Screen: Documentation Reader (`documentation::main-doc.index`)

**Route:** `GET /prime/documentation-intro?type={documentation|blog|developer|help}`
**Layout:** `x-prime.layouts.app`
**Description:** Three-column knowledge base reader

| Column | Contents |
|---|---|
| Left sidebar (col-lg-3) | Hierarchical category list (parent → subcategory buttons, collapsible) |
| Center (col-lg-6) | Selected article content display area (title, published_at, author, `{!! content !!}`) |
| Right sidebar (col-lg-3) | Article list for selected category (clickable cards with title + excerpt) |
| Floating button | Dark/Light mode toggle (top-right, `localStorage.docTheme`) |

### 7.3 Screen: Article Create (`documentation::article.create`)

**Route:** `GET /prime/documentation-articles/create`
**Layout:** `x-prime.layouts.app`

| Field | Input Type | Validation | Notes |
|---|---|---|---|
| Title | Text | required, max:255, unique `doc_articles.title` | |
| Slug | Auto-generated | required, unique `doc_articles.slug` | Derived from title, editable |
| Article Type | Select | required, in: documentation/blog/developer/help | |
| Visibility | Select | required, in: public/client/developer/internal/draft | |
| Categories | Multi-select | nullable, array of `doc_categories.id` | Note: field name `categories[]` does NOT match validator `category_ids` |
| Excerpt | Textarea | nullable, max:500 | |
| Content | Summernote | required, string | Rich HTML — XSS risk on output |
| Meta Title | Text | nullable, max:255 | |
| Meta Description | Text | nullable, max:300 | |
| Canonical URL | Text | nullable, url | |
| is_indexable | Checkbox | boolean | |
| is_published | Checkbox | boolean | |
| Featured Image | File upload | image, max:20048 (~20MB) | Via Spatie MediaLibrary |
| Summernote images | AJAX upload | image, max:20048 | Stored in `storage/documentation/articles/summernote/` |

### 7.4 Screen: Category Create (`documentation::category.create`)

| Field | Input Type | Validation |
|---|---|---|
| Name | Text | required, max:150, unique `doc_categories.name` |
| Slug | Auto-generated | required, max:180, unique `doc_categories.slug` |
| Parent Category | Select | nullable, exists `doc_categories.id`, not self |
| Type | Select | required, in: documentation/blog/developer/help |
| Description | Textarea | nullable |
| Meta Title | Text | nullable, max:255 |
| Meta Description | Text | nullable, max:300 |
| Sort Order | Number | nullable, integer, min:0 |
| Is Active | Checkbox | boolean |
| Category Image | File upload | image, max:20048 |

### 7.5 Screen: Trash Views (Article / Category)

Both trash views display soft-deleted records with:
- Paginated list (10 per page) with parent/author relationship
- Restore action
- Force Delete action (permanent)

### 7.6 Screen: Show Views (Article / Category)

- `article.show` — Full article with author and categories
- `category.show` — Category with parent and children relationships

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

| ID | Rule |
|---|---|
| BR-DOC-001 | A category cannot be its own parent (`Rule::notIn([$categoryId])` in `ValidateCategoryRequest`). |
| BR-DOC-002 | Category name and slug must be globally unique within `doc_categories`. |
| BR-DOC-003 | Article title and slug must be globally unique within `doc_articles`. |
| BR-DOC-004 | An article with `published_at` in the future must NOT appear in the public reader even if `is_published=true`. The `scopePublished` scope enforces this. |
| BR-DOC-005 | The reader (`mainDoc`) only shows articles with `is_published=true` AND `visibility='public'`. |
| BR-DOC-006 | When a category is deleted, its articles are NOT deleted (cascade on junction table only — articles remain independently). |
| BR-DOC-007 | When an article is soft-deleted, `is_published` is set to `false` before deletion. |
| BR-DOC-008 | When a category is soft-deleted, `is_active` is set to `false` before deletion. |
| BR-DOC-009 | Summernote image uploads are stored publicly at `storage/documentation/articles/summernote/`. These are permanent files — no cleanup on article deletion. |
| BR-DOC-010 | Article content (`content` column) is stored as raw HTML. Sanitization must be applied before render to prevent XSS. |
| BR-DOC-011 | The `type` parameter scopes the entire reader view — categories and articles of other types are not shown. |
| BR-DOC-012 | A parent category without children will have articles loaded directly when selected. A parent with children will expand to show subcategories; articles load on subcategory selection. |

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### 9.1 Article Lifecycle State Machine

```
[Draft Created]
    ↓  (save with is_published=false or visibility='draft')
[Draft]
    ↓  (admin publishes)
[Published - Active]
    ↓  (admin unpublishes toggle)
[Unpublished]
    ↓  (admin soft deletes)
[Trashed]
    ↓  (admin restores)
[Draft or Unpublished] ← restore returns to pre-delete state
    ↓  (admin force deletes)
[Permanently Deleted]
```

**Scheduled Publishing Flow:**
- Article saved with `is_published=true` but `published_at` set to future date
- Article does not appear in reader (scopePublished excludes future `published_at`)
- At `published_at` datetime, article becomes visible (no cron job currently — relies on query-time check)

### 9.2 Category Lifecycle State Machine

```
[Active]
    ↓  (toggleStatus: is_active=false)
[Inactive] — still visible in admin; hidden from reader
    ↓  (soft delete)
[Trashed]
    ↓  (restore)
[Active or Inactive]
    ↓  (force delete)
[Permanently Deleted] — blocked if child categories exist (RESTRICT FK)
```

### 9.3 Content Consumption Flow (Reader)

1. User navigates to `/prime/documentation-intro?type=documentation`
2. Server fetches root categories of the requested type (active only, ordered by `sort_order`)
3. For each category, children are eager-loaded
4. First category is auto-selected; first subcategory (if any) is auto-selected
5. Articles for the selected (sub)category are fetched
6. Server-side: first article is passed as `$selectedArticle` for SSR
7. Client-side: clicking a category/subcategory triggers AJAX call to `getArticlesByCategory`
8. Articles returned as JSON; first article auto-displayed
9. Clicking an article card renders content in center column

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| ID | Category | Requirement |
|---|---|---|
| NFR-DOC-001 | Security — Critical | Sanitize `content` field before rendering. Use HTML Purifier or a Laravel package (`mews/purifier`) to strip dangerous tags/attributes before inserting into database or before rendering. |
| NFR-DOC-002 | Security — Critical | Fix `displayArticle()` JavaScript function — use `escapeHtml()` on title/excerpt but `article.content` must be sanitized server-side, not client-side. The current `${article.content}` in `innerHTML` is XSS-vulnerable. |
| NFR-DOC-003 | Security | Fix Gate permission name mismatch between Policy (plural) and Controller (singular) to ensure authorization is actually enforced. |
| NFR-DOC-004 | Security | Reduce image upload limit from `max:20048` (20 MB) to `max:2048` (2 MB). Add image compression using Spatie Medialibrary's conversion pipeline. |
| NFR-DOC-005 | Performance | Add pagination to article list in reader for categories with many articles (current implementation fetches all without limit). |
| NFR-DOC-006 | Performance | Cache category tree per `type` parameter (changes infrequently). Invalidate on category create/update/delete. |
| NFR-DOC-007 | Correctness | Add `sort_order` column to `doc_articles` migration (missing from schema but referenced in queries and fillable). |
| NFR-DOC-008 | Correctness | Fix form field name mismatch: `create.blade.php` sends `categories[]` but controller and FormRequest expect `category_ids`. |
| NFR-DOC-009 | Storage | Implement cleanup of orphaned Summernote images when articles are force-deleted or when images are replaced. |
| NFR-DOC-010 | Accessibility | Article content displayed via `{!! !!}` must have proper semantic HTML structure (headings hierarchy, alt text on images) — enforce in Summernote editor configuration. |

---

## 11. CROSS-MODULE DEPENDENCIES

| Module/Component | Dependency Type | Usage |
|---|---|---|
| `sys_users` / User Model | Data Read | Article `author()` — `created_by` FK references `sys_users.id` |
| Spatie Media Library | Package | Article and Category image storage and conversion |
| Spatie Permission (RBAC) | Package | Gate::authorize calls for all controller actions |
| `sys_activity_logs` | Data Write | `activityLog()` helper called on all mutating operations |
| Summernote (CDN) | JS/CSS Library | Rich text editor — loaded from jsDelivr CDN |
| Bootstrap Icons | CSS | Reader sidebar icons (`bi-folder`, `bi-file-earmark-text`, etc.) |

---

## 12. TEST CASE REFERENCE & COVERAGE

### 12.1 Existing Tests: `tests/Unit/DocumentationModuleTest.php`

| Test Group | Tests | Description |
|---|---|---|
| Article Model | 8 tests | table name, SoftDeletes, HasMedia, fillable fields, casts, categories/author relationships, scopePublished |
| Category Model | 8 tests | table name, SoftDeletes, HasMedia, fillable fields, is_active cast, parent/children/childrenRecursive, scopeActive, scopeType |
| Architecture | 5 tests | All 3 controllers exist, ValidateArticleRequest exists, ValidateCategoryRequest exists, routes/web.php exists |

**Total existing tests: 21 (all Unit — no Feature/Integration tests)**

### 12.2 Test Coverage Gaps

| ID | Type | Scenario | Priority |
|---|---|---|---|
| TC-DOC-001 | Feature | Create category with valid data → 201/redirect, record in DB | High |
| TC-DOC-002 | Feature | Create category with duplicate name → validation error | High |
| TC-DOC-003 | Feature | Create article with `category_ids` → `doc_article_category_jnt` records created | High |
| TC-DOC-004 | Feature | Toggle article `is_published` via AJAX → JSON response, DB updated | High |
| TC-DOC-005 | Feature | Soft delete article → `deleted_at` set, `is_published` = false | High |
| TC-DOC-006 | Feature | Restore article from trash → `deleted_at` cleared | Medium |
| TC-DOC-007 | Feature | Force delete article → permanent removal | Medium |
| TC-DOC-008 | Feature | `getArticlesByCategory` returns only published + public articles | High |
| TC-DOC-009 | Feature | `mainDoc` with `?type=help` → only help categories shown | Medium |
| TC-DOC-010 | Feature | Unauthenticated user accesses `/prime/documentation-mgt` → redirect to login | High |
| TC-DOC-011 | Unit | `scopePublished` excludes articles with future `published_at` | High |
| TC-DOC-012 | Unit | Auto-slug generated on Article create | Medium |
| TC-DOC-013 | Security | Article with XSS content in title is escaped in reader list | Critical |
| TC-DOC-014 | Feature | Image upload returns correct storage URL | Medium |
| TC-DOC-015 | Feature | Force delete category blocked if child categories exist (FK RESTRICT) | Medium |

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition |
|---|---|
| Article | A content document with title, rich HTML content, type, visibility, and SEO metadata |
| Category | A hierarchical content container (parent/child) that groups articles by topic |
| Summernote | Open-source Bootstrap-compatible WYSIWYG HTML editor used for article content authoring |
| Soft Delete | Marking a record as deleted (`deleted_at` timestamp) without physical removal from the database |
| Force Delete | Permanently removing a record and all its media from the database and storage |
| XSS (Cross-Site Scripting) | A security vulnerability where malicious scripts are injected into content and executed in users' browsers |
| `{!! !!}` | Laravel's unescaped output directive — renders raw HTML without escaping; dangerous for user-supplied content |
| Visibility | An attribute that controls who can see an article: `public` (all), `client` (school admins), `developer` (integrators), `internal` (staff only), `draft` (hidden) |
| MediaLibrary | Spatie's file attachment package; used for article and category featured images with automatic conversion/resizing |
| Central Domain | The prime.yourdomain.com domain where the Documentation module is hosted, as opposed to per-school tenant subdomains |
| Gate Permission | Laravel's authorization gate check (e.g., `prime.documentation-article.viewAny`) registered in the RBAC system |
| scopePublished | An Eloquent query scope on the Article model that filters to only currently-visible published articles |
| AJAX | Asynchronous JavaScript and XML — the reader uses fetch() to load articles without page reload |

---

## 14. ADDITIONAL SUGGESTIONS

> This section contains analyst recommendations only.

1. **Sanitize article content immediately** — integrate `mews/purifier` (HTML Purifier) and run `clean($content)` before saving and before rendering. This is the single highest-priority fix in the module.

2. **Fix the Gate permission mismatch** — standardize on plural form for all permission strings: change all controller `Gate::authorize('prime.documentation-article.*')` calls to `Gate::authorize('prime.documentation-articles.*')` to match the Policy and avoid silent authorization bypass.

3. **Fix the form field name bug** in `article/create.blade.php` and `article/edit.blade.php` — change `name="categories[]"` to `name="category_ids[]"` to match the `ValidateArticleRequest` validator.

4. **Add `sort_order` column** to the `doc_articles` migration and add it to the article create/edit forms with a numeric field.

5. **Reduce image upload size limit** from `max:20048` to `max:2048` in both `uploadImage` methods. Consider auto-compression using Spatie Medialibrary's image conversions.

6. **Implement article search** — the reader currently has no search capability. Add a search input at the top of the reader that queries across article titles and excerpts.

7. **Add article view count tracking** — a `views` or `view_count` column on `doc_articles` would allow surfacing "Most Read" articles in a reader sidebar widget.

8. **Implement scheduled publishing cron** — currently `published_at` filtering is query-time only. For notification emails on publish, a scheduled job should check and notify subscribers.

9. **Create a `DocumentationService`** to extract the query logic from controllers (especially `mainDoc` and `getArticlesByCategory`) to improve testability and separation of concerns.

10. **Add breadcrumb/back navigation in the reader** — when accessing via deep link, users have no way to navigate to other categories/articles without using the sidebar.

11. **Consider `sort_order` UI** — add drag-and-drop reordering in the category and article index views for easier content management.

12. **Delete orphaned Summernote images** — add a cleanup command or hook in `Article::deleting` that removes files from `storage/documentation/articles/summernote/` that are no longer referenced in any article's content.

---

## 15. APPENDICES

### 15.1 Permission Matrix

| Permission | Used In Controller (actual) | Used In Policy (actual) | Match? |
|---|---|---|---|
| `prime.documentation-mgt.viewAny` | `DocumentationController@index` | — | N/A |
| `prime.documentation-mgt.view` | `DocumentationController@mainDoc`, `getArticlesByCategory`, `show` | — | N/A |
| `prime.documentation-mgt.create` | `DocumentationController@create`, `store` | — | N/A |
| `prime.documentation-mgt.update` | `DocumentationController@edit`, `update` | — | N/A |
| `prime.documentation-mgt.delete` | `DocumentationController@destroy` | — | N/A |
| `prime.documentation-article.viewAny` | `DocumentationArticleController@index`, `trashed` | — | **MISMATCH** (Policy uses plural) |
| `prime.documentation-article.create` | `DocumentationArticleController@create` | — | **MISMATCH** |
| `prime.documentation-article.store` | `DocumentationArticleController@store` | — | **MISMATCH** |
| `prime.documentation-article.view` | `DocumentationArticleController@show` | `prime.documentation-articles.view` | **MISMATCH** |
| `prime.documentation-article.update` | `DocumentationArticleController@edit`, `update`, `toggleStatus` | `prime.documentation-articles.update` | **MISMATCH** |
| `prime.documentation-article.delete` | `DocumentationArticleController@destroy` | `prime.documentation-articles.delete` | **MISMATCH** |
| `prime.documentation-article.restore` | `DocumentationArticleController@restore` | `prime.documentation-articles.restore` | **MISMATCH** |
| `prime.documentation-article.forceDelete` | `DocumentationArticleController@forceDelete` | `prime.documentation-articles.forceDelete` | **MISMATCH** |
| `prime.documentation-category.create` | `DocumentationCategoryController@create` | `prime.documentation-categories.create` | **MISMATCH** |
| `prime.documentation-category.store` | `DocumentationCategoryController@store` | — | **MISMATCH** |
| `prime.documentation-category.view` | `DocumentationCategoryController@show` | `prime.documentation-categories.view` | **MISMATCH** |
| `prime.documentation-category.update` | `DocumentationCategoryController@edit`, `update`, `toggleStatus` | `prime.documentation-categories.update` | **MISMATCH** |
| `prime.documentation-category.delete` | `DocumentationCategoryController@destroy` | `prime.documentation-categories.delete` | **MISMATCH** |
| `prime.documentation-category.restore` | `DocumentationCategoryController@restore` | `prime.documentation-categories.restore` | **MISMATCH** |
| `prime.documentation-category.forceDelete` | `DocumentationCategoryController@forceDelete` | `prime.documentation-categories.forceDelete` | **MISMATCH** |

**Recommendation:** Standardize all permission strings to plural form (matching the Policy file names and conventions) and update all `Gate::authorize()` calls accordingly.

### 15.2 Content Type × Visibility Matrix

| Type \ Visibility | public | client | developer | internal | draft |
|---|---|---|---|---|---|
| documentation | School admins, users | School admins only | — | Staff only | Hidden |
| blog | All users | School admins | — | Staff only | Hidden |
| developer | All | — | Dev partners | Staff | Hidden |
| help | All users | School admins | — | Staff | Hidden |

### 15.3 Article `sort_order` Column Gap

The `doc_articles` migration does **not** include `sort_order`, but:
- `Article::$fillable` does **not** list it (so not a direct PHP issue)
- `DocumentationController@mainDoc` queries `->orderBy('sort_order')` — this will use a non-existent column
- `DocumentationController@getArticlesByCategory` queries `->orderBy('sort_order')` — same

**Fix required:** Add `$table->unsignedInteger('sort_order')->default(0);` to the migration and add `'sort_order'` to `Article::$fillable`.
