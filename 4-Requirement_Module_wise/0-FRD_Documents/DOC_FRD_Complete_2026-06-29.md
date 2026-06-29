# DOC — Documentation | Complete Analysis Pack | 2026-06-29
**Module:** Documentation · **Code:** DOC · **Prefix:** `doc_` · **Scope:** CENTRAL (prime / central domain — not per-tenant)
**Source read:** Live code (`Modules/Documentation/` — migrations, models, controllers, requests, policies, routes, views, seeders, tests), global `routes/web.php`, `RolePermissionSeeder`, V2 Requirement (`DOC_Documentation_Requirement.md`), V1 screen specs (`Documentation_v2/`). All schema claims three-way reconciled (migration ↔ model ↔ controller); migration is authoritative for "what exists".
**Register:** Business language in §§1–7, 11–12; technical register only in §§8 (Data Dictionary technical view), 10 (Dependency Map).
**This is the single source of truth.** Downstream audits reuse the `REQ-/BR-/RPT-/ENH-` IDs below — never renumber.

> **Index (sections of this consolidated file)**
> 1. Module Overview & Scope · 2. Actors & Roles · 3. Functional Requirements (REQ-) · 4. Business Rules Register (BR-) · 5. Requirement Conditions Catalog · 6. Validation & Edge-Case Catalog · 7. Workflows & State Machines · 8. Data Dictionary (business + technical) · 9. Reporting & KPIs (RPT-) · 10. Cross-Module Dependency Map · 11. NFRs & Risk Register · 12. Future Enhancements (ENH-) · 13. RTM (Traceability) · 14. Prioritization & Sprint Tasks · 15. User Stories · 16. Gap Analysis Readiness Index

---

## Section 1 — Module Overview & Scope

### 1.1 Purpose
The Documentation module is the **central knowledge base and help system** for the Prime-AI platform. The platform support and product team use it to publish and organise four kinds of content — product documentation, help articles, developer/integration guides, and blog-style announcements — and to expose a clean reading experience for those who consume that content (school administrators, teachers, integration partners). It is operated from the central platform admin area, not from individual school sites.

### 1.2 Business Value
- A single, organised home for all platform documentation, reducing repeat support questions.
- Controlled publishing: drafts, scheduled go-live, and audience visibility so the right people see the right content.
- A self-service reader that lets users browse by topic and read articles without contacting support.

### 1.3 Scope

**In scope**
- Create, organise, edit, publish, unpublish, archive (trash), restore, and permanently remove **content categories** (with a two-level parent/child structure) and **articles**.
- Group an article under one or more categories.
- Schedule an article to appear automatically at a future date.
- Control each article's audience through a visibility setting and its content type.
- A three-pane reading experience (topic list → article → article-in-topic list) with light/dark display.
- Attach a featured image to categories and articles, and insert images inside article content.
- Record an audit trail of every content change.

**Out of scope**
- Per-school (tenant) documentation — the module is central only; all content is shared platform-wide.
- Academic-year scoping — documentation content is not tied to an academic session.
- End-user comments, ratings, or community contributions.
- Article revision history / version rollback (proposed — see ENH-DOC-001).
- In-reader full-text search (proposed — see ENH-DOC-002).
- Multi-language / translated content.

### 1.4 Terminology
| Term | Meaning (business) |
|---|---|
| Article | A single piece of published content with a title, rich text body, type, audience visibility, and search/SEO information. |
| Category | A topic container that groups articles; categories can be nested one level deep (parent → child). |
| Content Type | One of four buckets an item belongs to: Documentation, Help, Developer, or Blog. |
| Visibility | The audience an article is meant for: Public, Client (schools), Developer (partners), Internal (staff), or Draft (hidden). |
| Reader | The public-facing three-pane browsing experience for published content. |
| Management Hub | The admin screen where categories and articles are managed side by side. |
| Trash | Holding area for archived (soft-deleted) items that can be restored or permanently removed. |
| Scheduled Publishing | Marking an article to appear automatically on/after a chosen future date. |
| Featured Image | A single representative image attached to a category or article. |

---

## Section 2 — Actors & Roles

### 2.1 Actors
| Actor | Description | Relationship to module |
|---|---|---|
| Platform Super Admin | Owns and publishes all content. | Full control over categories, articles, trash, and permanent deletion. |
| Platform Support / Content Author | Writes and edits content. | Create/edit articles and categories; limited or no permanent-delete rights. |
| App Maintenance role | Maintains platform configuration including documentation. | Manage documentation content (granted the documentation permission group). |
| School Administrator (consumer) | Reads relevant published content. | Read-only via the reader. |
| Teacher (consumer) | Reads relevant published content. | Read-only via the reader. |
| Developer / Integration Partner (consumer) | Reads developer-type content. | Read-only via the reader. |

> Data isolation note: this module is **central** — every actor sees the same shared content library; there is no per-school separation and no academic-year filter.

### 2.2 Role → Feature Matrix (business view)
| Capability | Super Admin | Content Author | App Maintenance | Consumers |
|---|---|---|---|---|
| View management hub | Yes | Yes | Yes | No |
| Manage categories (create/edit/toggle) | Yes | Yes | Yes | No |
| Manage articles (create/edit/publish) | Yes | Yes | Yes | No |
| Archive / restore | Yes | Yes | Yes | No |
| Permanently delete | Yes | (limited) | Yes | No |
| Read published content (reader) | Yes | Yes | Yes | Yes |

*(Exact permission strings are technical and listed in §8.3.)*

---

## Section 3 — Functional Requirements

> Priority: Core (P0) / Standard (P1) / Enhanced (P2). Tags: [DATA_ENTRY][WORKFLOW][REPORT][CONFIGURATION][DASHBOARD][APPROVAL][INTEGRATION]. Status reflects the live build.

### REQ-DOC-001 — Category Management (full lifecycle) · P0 · [DATA_ENTRY][CONFIGURATION]
Authorised staff can create, view, edit, and archive content categories. Each category has a name, an auto-generated web-friendly identifier (slug), a content type, an optional parent, a description, a display order, an active/inactive switch, and optional search/SEO fields.
- **Actors:** Initiates/Processes — Content Author, Super Admin; Views — admin roles.
- **Business rules:** BR-DOC-001, BR-DOC-002, BR-DOC-003, BR-DOC-019.
- **Acceptance criteria:** (a) Creating a category with a unique name succeeds and a slug is generated automatically. (b) Saving a duplicate name is rejected with a clear message. (c) Toggling active/inactive updates the category immediately. (d) The display-order value is saved and respected. *(Status: display-order currently dropped on save — see BR-DOC-019.)*
- **Status:** Implemented (~90%); display-order persistence defect open.

### REQ-DOC-002 — Category Hierarchy (two-level) · P0 · [DATA_ENTRY]
Categories can be nested one level: a parent category may have child categories. A category may not be set as its own parent. Archiving/removal respects the hierarchy.
- **Business rules:** BR-DOC-004, BR-DOC-005, BR-DOC-013.
- **Acceptance criteria:** (a) A child can be assigned to a parent. (b) Selecting a category as its own parent is rejected. (c) Permanently deleting a parent that still has child categories is blocked with an error.
- **Status:** Implemented.

### REQ-DOC-003 — Article Management (full lifecycle) · P0 · [DATA_ENTRY]
Authorised staff can create, view, edit, and archive articles. Each article has a title, auto slug, content type, rich-text body, optional summary, audience visibility, optional publish date, search/SEO fields, and an author.
- **Business rules:** BR-DOC-006, BR-DOC-007, BR-DOC-014, BR-DOC-018.
- **Acceptance criteria:** (a) Creating an article with a unique title succeeds and records the author. (b) Duplicate title is rejected. (c) Editing updates the article and records what changed in the audit trail. (d) The summary cannot exceed its limit.
- **Status:** Implemented (~90%).

### REQ-DOC-004 — Article Categorisation (multi-category) · P0 · [DATA_ENTRY]
An article can be assigned to one or more categories; assignments are de-duplicated. Removing a category does not delete its articles — only the link is removed.
- **Business rules:** BR-DOC-008, BR-DOC-009.
- **Acceptance criteria:** (a) An article saved against several categories appears under each. (b) The same article cannot be linked to the same category twice. (c) Archiving a category leaves its articles intact.
- **Status:** Implemented at the data layer; **defect:** the create/edit form submits the category selection under the wrong field name, so selections are silently lost (BR-DOC-020).

### REQ-DOC-005 — Publishing & Scheduled Release · P0 · [WORKFLOW][APPROVAL]
An article can be published or unpublished. An article may be given a future publish date; it stays hidden from the reader until that date passes, with no manual step required.
- **Business rules:** BR-DOC-010, BR-DOC-011.
- **Acceptance criteria:** (a) Publishing makes a public article visible in the reader. (b) An article with a future publish date is not shown until the date arrives. (c) Unpublishing immediately removes it from the reader.
- **Status:** Implemented.

### REQ-DOC-006 — Images (featured + in-content) · P1 · [DATA_ENTRY]
A single featured image can be attached to a category or article (auto-resized to small/medium/large). Authors can also insert images directly inside article content.
- **Business rules:** BR-DOC-015, BR-DOC-016.
- **Acceptance criteria:** (a) Uploading a featured image stores it and generates the three sizes. (b) Replacing a featured image removes the previous one. (c) Oversized or disallowed image types are rejected. *(Status: size/type limits currently too permissive — see BR-DOC-015.)*
- **Status:** Implemented; upload-hardening defects open.

### REQ-DOC-007 — Documentation Reader · P1 · [DASHBOARD]
A three-pane reading experience: a topic list on the left, the selected article in the centre, and the list of articles within the chosen topic on the right. The first topic and article load automatically; selecting another topic loads its articles without a full page reload. A light/dark display toggle is remembered for the user.
- **Business rules:** BR-DOC-012, BR-DOC-021.
- **Acceptance criteria:** (a) Opening the reader shows the first topic's first article. (b) Choosing a topic loads its articles. (c) The display-mode choice persists across visits.
- **Status:** Implemented (~80%).

### REQ-DOC-008 — Reader Content Scoping (type & audience) · P0 · [WORKFLOW]
The reader is scoped by content type (e.g. Documentation, Help). Only published, publicly-visible articles within active categories are shown.
- **Business rules:** BR-DOC-011, BR-DOC-012, BR-DOC-017.
- **Acceptance criteria:** (a) Switching content type shows only that type's categories and articles. (b) Unpublished, non-public, or inactive items never appear. (c) Audience-restricted articles (Client/Developer/Internal) are not exposed publicly.
- **Status:** Implemented for the public case; **gap:** Client/Developer/Internal audience enforcement not yet built (only "public" is honoured) — BR-DOC-017.

### REQ-DOC-009 — Management Hub (admin overview) · P1 · [DASHBOARD]
A single admin screen presents categories and articles side by side (tabbed), each with search, content-type filter, and active/published filter, paginated.
- **Business rules:** BR-DOC-016 (authorisation).
- **Acceptance criteria:** (a) The hub lists both categories and articles. (b) Searching by name/title filters the list. (c) Filtering by type and status works. (d) Lists paginate.
- **Status:** Implemented.

### REQ-DOC-010 — Archive / Restore / Permanent Removal · P1 · [WORKFLOW]
Items can be archived (kept recoverable), viewed in a trash list, restored, or permanently removed. Archiving an article also unpublishes it; archiving a category also deactivates it.
- **Business rules:** BR-DOC-007, BR-DOC-013, BR-DOC-018.
- **Acceptance criteria:** (a) Archiving moves an item to trash and (article) unpublishes / (category) deactivates it. (b) Restore returns it. (c) Permanent removal deletes it and its image; for a parent category with children it is blocked with an error.
- **Status:** Implemented.

### REQ-DOC-011 — Authorisation & Access Control · P0 · [INTEGRATION]
Every management action requires the matching documentation permission; the reader requires view permission. Consumers cannot reach management screens.
- **Business rules:** BR-DOC-016, BR-DOC-022.
- **Acceptance criteria:** (a) A user without the relevant permission is refused (forbidden). (b) An unauthenticated user is redirected to sign in. (c) Listing categories requires permission. *(Status defects: the category list screen and both image-upload endpoints currently skip the permission check; the publish/create handler uses an action name that may not be granted — see BR-DOC-016, BR-DOC-022.)*
- **Status:** Partial — authorisation gaps open (P0).

### REQ-DOC-012 — Content Safety / Sanitisation · P0 · [INTEGRATION]
Rich-text article content must be cleaned of unsafe markup before it is stored and before it is shown, so that published content cannot run malicious scripts in a reader's browser.
- **Business rules:** BR-DOC-014.
- **Acceptance criteria:** (a) Submitting content containing a script block stores it with the script removed. (b) Submitting content with a dangerous image/event attribute stores it stripped. (c) The reader never executes embedded scripts.
- **Status:** **Not implemented** — highest-priority security gap (no sanitisation library installed; raw content rendered).

### REQ-DOC-013 — Audit Trail · P1 · [INTEGRATION]
Every create, edit, archive, restore, permanent-delete, and status toggle on categories and articles is recorded with who did it and (for edits) what changed.
- **Business rules:** BR-DOC-023.
- **Acceptance criteria:** (a) Creating an item writes an audit entry naming the actor. (b) Editing records the changed fields' old/new values. (c) Archive/restore/delete are each logged.
- **Status:** Implemented.

### REQ-DOC-014 — Search & SEO Metadata · P2 · [DATA_ENTRY]
Categories and articles carry optional search/SEO information (meta title, meta description, canonical link, indexable flag) used for discoverability.
- **Business rules:** BR-DOC-002 (length limits via validation).
- **Acceptance criteria:** (a) SEO fields save within their limits. (b) An article marked non-indexable is flagged accordingly.
- **Status:** Implemented (storage); indexing behaviour (robots) not enforced.

### REQ-DOC-015 — Decommission Dead Management Endpoints · P1 · [CONFIGURATION]
The generic documentation resource endpoints (save/update/delete on the top-level documentation controller) currently accept requests but do nothing. They must be either implemented or removed so the system has no silent no-op actions.
- **Business rules:** BR-DOC-024.
- **Acceptance criteria:** (a) No exposed action silently succeeds without effect. (b) Removed routes return not-found; implemented routes perform a defined action.
- **Status:** Open decision (dead stubs present).

---

## Section 4 — Business Rules Register

| ID | Rule (business) | Type | Trigger | Enforcement point | Status |
|---|---|---|---|---|---|
| BR-DOC-001 | A category name must be unique across all categories. | Validation | Create/edit category | Category form validation | ✅ |
| BR-DOC-002 | Slugs and SEO fields must respect length limits (slug ≤ chars, meta description ≤ 300). | Validation | Create/edit | Form validation | ✅ |
| BR-DOC-003 | A category's web identifier (slug) is generated automatically from its name and regenerated if the name changes. | Workflow | Create/edit | Model on-save hook | ✅ |
| BR-DOC-004 | A category may not be its own parent. | Validation | Edit category | Category form validation | ✅ |
| BR-DOC-005 | Categories nest at most one level (parent → child). | Workflow | Create/edit | Application convention | ✅ |
| BR-DOC-006 | An article title must be unique across all articles. | Validation | Create/edit article | Article form validation | ✅ |
| BR-DOC-007 | Archiving an article sets it unpublished before it is moved to trash. | Workflow | Archive article | Article archive action | ✅ |
| BR-DOC-008 | An article may belong to many categories; the same article+category pair cannot repeat. | Validation | Save article categories | Junction uniqueness | ✅ |
| BR-DOC-009 | Removing/archiving a category does not delete its articles — only the link is removed. | Workflow | Delete category | Link cascade only | ✅ |
| BR-DOC-010 | A published, public article appears in the reader; an unpublished one does not. | Workflow | Publish/unpublish | Reader query | ✅ |
| BR-DOC-011 | An article with a future publish date stays hidden until that date passes — automatically, with no manual step. | Calculation | Reader read | Published scope (publish date ≤ now) | ✅ |
| BR-DOC-012 | The reader shows only articles in active categories. | Workflow | Reader read | Reader query | ✅ |
| BR-DOC-013 | Permanently deleting a parent category that still has child categories is blocked. | Workflow | Force delete category | Database restrict rule | ✅ |
| BR-DOC-014 | All rich-text article content must be cleaned of unsafe markup before storage and before display. | Validation/Security | Create/edit article; reader render | (to be added) sanitiser at save + safe render | ❌ |
| BR-DOC-015 | An uploaded image must not exceed 2 MB and must be a safe image type (no SVG). | Validation | Image upload | Upload validation | ❌ (currently ~20 MB, no type limit) |
| BR-DOC-016 | Every management action — including listing categories and uploading images — requires the matching documentation permission. | Permission | Any management request | Authorisation gate per action | 🟡 (category list & image upload lack a check) |
| BR-DOC-017 | Audience-restricted articles (Client/Developer/Internal) must not be exposed to the public reader. | Permission | Reader read | (to be added) visibility-aware reader | ❌ (only "public" honoured) |
| BR-DOC-018 | Archiving a category deactivates it before it is moved to trash. | Workflow | Archive category | Category archive action | ✅ |
| BR-DOC-019 | A category's display-order value must be saved as entered. | Validation | Create/edit category | Model mass-assignment list | 🟡 (value silently dropped) |
| BR-DOC-020 | The article form's category selection must reach the save handler intact. | Validation | Create/edit article | Form field name ↔ handler | 🟡 (field-name mismatch loses selection) |
| BR-DOC-021 | The reader's light/dark display choice is remembered for the user. | Workflow | Reader use | Browser-stored preference | ✅ |
| BR-DOC-022 | The publish/create handler must use a permission the platform actually grants. | Permission | Create/publish | Authorisation gate | 🟡 (uses a non-standard action name) |
| BR-DOC-023 | Every content change is recorded with the actor and (for edits) the changed values. | Workflow | Any mutation | Audit-log helper | ✅ |
| BR-DOC-024 | The system exposes no management action that silently does nothing. | Workflow | Any management request | Route/controller wiring | 🟡 (dead stub endpoints present) |

---

## Section 5 — Requirement Conditions Catalog
*(Consolidated, de-duplicated conditions keyed to BR- IDs. Canonical copy also belongs at `5-Requirement_Conditions/Documentation_Conditions.md`; this is the authoritative source.)*

| Condition (=BR-) | Entity/Field | Condition (business) | Type | Trigger | On violation |
|---|---|---|---|---|---|
| BR-DOC-001 | Category.name | Must be unique | Validation | Save | Reject with "name already exists" |
| BR-DOC-004 | Category.parent | ≠ self | Validation | Save | Reject with self-parent error |
| BR-DOC-006 | Article.title | Must be unique | Validation | Save | Reject with "title already exists" |
| BR-DOC-008 | Article↔Category | Pair unique | Validation | Assign | Ignore duplicate link |
| BR-DOC-011 | Article.publish date | Hidden until ≤ now | Calculation | Read | Excluded from reader |
| BR-DOC-013 | Category (parent) | No children before permanent delete | Workflow | Force delete | Block + error |
| BR-DOC-014 | Article.content | No unsafe markup | Security | Save/render | Strip dangerous markup |
| BR-DOC-015 | Image upload | ≤ 2 MB, safe type | Validation | Upload | Reject oversized/SVG |
| BR-DOC-016 | All mgmt actions | Permission required | Permission | Request | Refuse (forbidden) |
| BR-DOC-017 | Article.visibility | Public-only in reader | Permission | Read | Hide restricted content |
| BR-DOC-019 | Category.display order | Persisted as entered | Validation | Save | Value retained |
| BR-DOC-020 | Article categories | Selection reaches handler | Validation | Save | Selection applied |

---

## Section 6 — Validation & Edge-Case Catalog

| Field/Rule | Valid | Invalid | Boundary | Empty/Null | Concurrency | Expected |
|---|---|---|---|---|---|---|
| Category name (BR-DOC-001) | "Getting Started" | duplicate name | 150 chars | blank → required | two saves same name | unique enforced; 2nd rejected |
| Category parent (BR-DOC-004) | another category | itself | n/a | none (root) | n/a | self-parent rejected |
| Article title (BR-DOC-006) | "API Overview" | duplicate | 255 chars | blank → required | two creates same title | 2nd rejected |
| Summary (excerpt) | ≤ 500 chars | > 500 | 500 | null allowed | n/a | over-limit rejected |
| Publish date (BR-DOC-011) | past/now | malformed | exactly now | null → visible if published | n/a | future hidden |
| Content safety (BR-DOC-014) | clean HTML | `<script>` / `onerror=` | large body | empty → required | n/a | dangerous markup stripped |
| Image upload (BR-DOC-015) | 1 MB JPG | 5 MB / .svg | exactly 2 MB | none | replace race | over-limit & SVG rejected |
| Category display order (BR-DOC-019) | 0,1,2… | negative | 0 | null → 0 | n/a | value saved |
| Article categories (BR-DOC-020) | one or more | unknown category id | none selected | empty → no links | concurrent edit | valid links saved |
| Force-delete parent (BR-DOC-013) | leaf category | parent w/ children | last child removed | n/a | delete child + parent race | parent-with-children blocked |
| Permission (BR-DOC-016) | granted user | no permission | n/a | unauthenticated | n/a | forbidden / redirect to login |

---

## Section 7 — Workflows & State Machines

### 7.1 Workflow — Author & Publish an Article
**Trigger:** Author creates an article. **Actors:** Content Author | System.
1. Author opens the create form and enters title, type, body, categories, visibility, optional publish date.
2. System validates, **cleans the content of unsafe markup** (target state — BR-DOC-014), records the author, saves, and links the chosen categories.
3. Author publishes (now) or sets a future publish date.
4. System makes a published+public article visible in the reader; a future-dated one becomes visible automatically when the date passes.
- **Exception paths:** validation failure → return with messages; duplicate title → rejected; category selection lost → BR-DOC-020 defect; unsafe content not stripped → BR-DOC-014 gap.
- **Notifications:** none defined (internal content tool).

### 7.2 Workflow — Read Content (Reader)
**Trigger:** User opens the reader for a content type. **Actors:** Consumer | System.
1. System loads active root categories for that type and their active children, then auto-selects the first topic and its first published+public article.
2. User selects another topic → system loads that topic's articles without a full reload.
- **Exception paths:** topic with no published public articles → empty state; restricted-visibility content must not appear (BR-DOC-017 gap).

### 7.3 Article State Machine
| From | Event | Guard | To | Side-effects |
|---|---|---|---|---|
| (none) | Create | valid + content cleaned | Draft/Unpublished | author recorded; audit log |
| Draft/Unpublished | Publish | is public to appear in reader | Published | audit log |
| Published | Unpublish | — | Unpublished | removed from reader; audit log |
| Published/Unpublished | Archive | — | Trashed | unpublished first (BR-DOC-007); audit log |
| Trashed | Restore | — | Unpublished | audit log |
| Trashed | Permanent delete | — | Deleted | media removed; audit log |

Terminal: Deleted. Scheduled sub-state: Published + future date ⇒ effectively hidden until date ≤ now (BR-DOC-011).

### 7.4 Category State Machine
| From | Event | Guard | To | Side-effects |
|---|---|---|---|---|
| Active | Toggle off | — | Inactive | hidden from reader; audit log |
| Active/Inactive | Archive | — | Trashed | deactivated first (BR-DOC-018); audit log |
| Trashed | Restore | — | previous state | audit log |
| Trashed | Permanent delete | no child categories (BR-DOC-013) | Deleted | blocked if children exist; media removed |

---

## Section 8 — Data Dictionary

### 8.1 Business view
| Business field | Meaning | Required | Allowed values | Privacy |
|---|---|---|---|---|
| Category name | Topic display name | Yes | unique text | Public |
| Category type | Which content bucket | Yes | Documentation / Help / Developer / Blog | Public |
| Parent topic | Optional grouping | No | an existing category | Public |
| Display order | Sort position | No | 0+ | Internal |
| Active | Whether shown in reader | Yes | Yes/No | Internal |
| Article title | Article heading | Yes | unique text | Public |
| Content type | Which bucket | Yes | Documentation / Help / Developer / Blog | Public |
| Body | Rich-text content | Yes | sanitised HTML | Public |
| Summary | Short blurb | No | ≤ 500 chars | Public |
| Visibility | Intended audience | Yes | Public / Client / Developer / Internal / Draft | Internal |
| Publish date | When it goes live | No | date/time | Internal |
| Author | Who created it | No | platform user | Internal |
| SEO fields | Search metadata | No | text / URL / yes-no | Public |

### 8.2 Technical view (register: technical — migration-authoritative)
> ⚠ PK/FK type is **UNSIGNED INT** (`increments`/`unsignedInteger`), NOT BIGINT. `doc_*` tables exist only in module migrations — not in any consolidated DDL master (prime/tenant/global v4). Central scope (author FK → `sys_users`).

**`doc_categories`** — `id` PK UINT · `name` VARCHAR(150) UNIQUE · `slug` VARCHAR(180) UNIQUE · `parent_id` UINT NULL → `doc_categories.id` RESTRICT · `type` ENUM(documentation,blog,developer,help) IDX · `description` TEXT NULL · `meta_title` VARCHAR(255) NULL · `meta_description` VARCHAR(300) NULL · `is_active` BOOL=1 · `sort_order` UINT=0 · timestamps · `deleted_at`. IDX `(type,is_active,sort_order)`.
- Model gap: `sort_order` NOT in `$fillable` (silently dropped). No `created_by` column. No `$connection`.

**`doc_articles`** — `id` PK UINT · `title` VARCHAR(255) UNIQUE · `slug` VARCHAR(255) UNIQUE · `type` ENUM(...) IDX · `content` LONGTEXT · `excerpt` TEXT NULL · `is_published` BOOL=0 · `published_at` TS NULL · `visibility` ENUM(public,client,developer,internal,draft)=public IDX · `meta_title` VARCHAR(255) NULL · `meta_description` VARCHAR(300) NULL · `canonical_url` VARCHAR(255) NULL · `is_indexable` BOOL=1 · `created_by` UINT NULL → `sys_users.id` NULL-on-delete · timestamps · `deleted_at`. IDX `(type,is_published,published_at)`.
- Schema gap: **no `sort_order` column** though `$fillable` lists it and 4 `orderBy('sort_order')` call sites reference it.

**`doc_article_category_jnt`** — `id` PK UINT · `article_id` UINT → `doc_articles.id` CASCADE · `category_id` UINT → `doc_categories.id` CASCADE · timestamps. UNIQUE `(article_id, category_id)`.

### 8.3 Permission strings (technical)
- Controllers use **singular** abilities: `prime.documentation-mgt.{viewAny,view,create,update,delete}`, `prime.documentation-article.{viewAny,view,create,store,update,delete,restore,forceDelete}`, `prime.documentation-category.{...}`.
- Seeder (`RolePermissionSeeder` `$docs`) defines the **singular** features — so controllers + seeder agree; authorization works via Spatie permission Gate.
- The 2 Policy classes reference **plural** abilities (`...articles.*` / `...categories.*`) that are never seeded and never invoked → **orphaned/dead**.
- Open issues: `Category@index` has no gate; both `uploadImage()` have no gate; `store()` uses a `.store` action likely outside the standard granted set.

---

## Section 9 — Reporting & Analytics

| ID | Purpose | Audience | Frequency | Contents | Filters | Export | Status |
|---|---|---|---|---|---|---|---|
| RPT-DOC-001 | Content inventory | Content team | On demand | Categories & articles with type, status, author, dates | type, status, search | screen (PDF/Excel proposed) | 🟡 list views exist; no formal export |
| RPT-DOC-002 | Trash / archived log | Super Admin | On demand | Soft-deleted categories & articles | entity, date | screen | ✅ trash views |
| RPT-DOC-003 | Most-read articles | Content team | Weekly | Articles ranked by reads | type, period | screen | ❌ needs view-count (ENH-DOC-003) |

**KPIs:** Published-article count by type · Draft backlog · Articles per category (orphan detection) · Most-read (post ENH-DOC-003).

---

## Section 10 — Cross-Module Dependency Map (technical register)

**Inbound (this module reads):**
| Source | Data/entity | Why |
|---|---|---|
| Prime / `sys_users` | Author identity | Article `created_by` author display |
| Spatie Permission (RBAC) | Permission grants | Gate authorisation per action |
| Spatie MediaLibrary | Image storage/conversions | Featured & in-content images |

**Outbound (this module feeds):**
| Target | Mechanism | What |
|---|---|---|
| `sys_activity_logs` | `activityLog()` helper | Audit entries on every mutation |
| (none) | — | No domain events emitted; no module consumes documentation content |

**External:** Summernote (CDN editor); `mews/purifier` (required, **not installed**).
**Isolation:** central only — never per-tenant; no academic-year scoping.

---

## Section 11 — Non-Functional Requirements & Risk Register

### 11.1 NFRs
| ID | Category | Requirement (measurable) | Priority | Status |
|---|---|---|---|---|
| NFR-DOC-001 | Security | All article content sanitised at save and rendered safely; scripts/event-handlers/`javascript:` stripped. | P0 | ❌ |
| NFR-DOC-002 | Security | Reader must not execute embedded scripts; no raw client-side HTML injection from content. | P0 | ❌ |
| NFR-DOC-003 | Security | Authorisation enforced on every management action incl. category listing and image upload. | P0 | 🟡 |
| NFR-DOC-004 | Security | Create/publish handler uses a granted permission action (no orphan ability). | P0 | 🟡 |
| NFR-DOC-005 | Security | Image uploads ≤ 2 MB, restricted to safe raster types (no SVG). | P1 | ❌ |
| NFR-DOC-006 | Correctness | `doc_articles.sort_order` exists (migration) before it is used in ordering. | P1 | ❌ |
| NFR-DOC-007 | Correctness | Category display-order persists (model mass-assignment includes it). | P1 | ❌ |
| NFR-DOC-008 | Correctness | Article form category selection reaches the handler (field-name aligned). | P1 | ❌ |
| NFR-DOC-009 | Correctness | No exposed management action is a silent no-op (dead stubs removed/implemented). | P1 | ❌ |
| NFR-DOC-010 | Performance | Reader category tree cached per content type; invalidated on change. | P2 | ❌ |
| NFR-DOC-011 | Performance | Reader article fetch paginated (no unbounded fetch). | P2 | ❌ |
| NFR-DOC-012 | Maintainability | Business logic extracted into services; author assignment set in controller not the request. | P2 | ❌ |
| NFR-DOC-013 | Data integrity | Models pinned to the central connection so they never query a tenant DB. | P3 | ❌ |

### 11.2 Risk Register
| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| RISK-DOC-001 | Stored cross-site scripting via unsanitised article content reaches all readers. | H | H | Install/clean (NFR-DOC-001/002); safe render. |
| RISK-DOC-002 | Unauthorised category listing / image upload (missing permission checks). | M | H | Add gates (NFR-DOC-003). |
| RISK-DOC-003 | Oversized/SVG uploads enable abuse or XSS. | M | H | Tighten upload limits (NFR-DOC-005). |
| RISK-DOC-004 | Article ordering query fails due to missing `sort_order` column. | M | M | Add migration (NFR-DOC-006). |
| RISK-DOC-005 | Authors lose category selections silently (field mismatch). | H | M | Align field name (NFR-DOC-008). |
| RISK-DOC-006 | Restricted-audience content leaks publicly. | M | M | Visibility-aware reader (BR-DOC-017). |

---

## Section 12 — Future Enhancements

| ID | Enhancement | Value | Priority | Promotes to |
|---|---|---|---|---|
| ENH-DOC-001 | Article version history & rollback | Recover prior content; audit edits | P2 | REQ on approval |
| ENH-DOC-002 | In-reader full-text search | Faster self-service | P2 | REQ |
| ENH-DOC-003 | Article view-count & "Most Read" | Surfaces popular content (RPT-DOC-003) | P3 | REQ |
| ENH-DOC-004 | Orphaned in-content image cleanup | Reclaim storage on delete | P3 | REQ |
| ENH-DOC-005 | Service layer for content logic | Testability, lower controller complexity | P2 | REQ |
| ENH-DOC-006 | Category-tree caching | Reader performance | P2 | REQ |

---

## Section 13 — Requirements Traceability Matrix

| REQ | Feature | BR refs | Screen | Workflow | Report | Test (target) | Code status |
|---|---|---|---|---|---|---|---|
| REQ-DOC-001 | Category mgmt | 001,002,003,019 | Category create/edit/index | 7.4 | RPT-DOC-001 | TC-DOC-001/002 | Done~ (display-order defect) |
| REQ-DOC-002 | Category hierarchy | 004,005,013 | Category create/edit | 7.4 | — | TC-DOC-018 | Done |
| REQ-DOC-003 | Article mgmt | 006,007,014,018 | Article create/edit/index | 7.1,7.3 | RPT-DOC-001 | TC-DOC-003/005 | Done~ |
| REQ-DOC-004 | Categorisation | 008,009 | Article create/edit | 7.1 | — | TC-DOC-022 | Defect (field name) |
| REQ-DOC-005 | Publish/schedule | 010,011 | Article edit; reader | 7.1,7.3 | — | TC-DOC-004/012/013 | Done |
| REQ-DOC-006 | Images | 015,016 | Create/edit; upload | 7.1 | — | TC-DOC-019/020/021 | Done~ (limits) |
| REQ-DOC-007 | Reader | 012,021 | Reader | 7.2 | — | TC-DOC-009 | Done~ |
| REQ-DOC-008 | Reader scoping | 011,012,017 | Reader | 7.2 | — | TC-DOC-008 | Partial (visibility) |
| REQ-DOC-009 | Management hub | 016 | Hub | — | RPT-DOC-001 | TC-DOC-010/011 | Done |
| REQ-DOC-010 | Archive/restore | 007,013,018 | Trash views | 7.3,7.4 | RPT-DOC-002 | TC-DOC-006/007 | Done |
| REQ-DOC-011 | Authorisation | 016,022 | all mgmt | — | — | TC-DOC-010/011/019 | Partial |
| REQ-DOC-012 | Sanitisation | 014 | Article save; reader | 7.1 | — | TC-DOC-016/017 | Not done |
| REQ-DOC-013 | Audit trail | 023 | all mgmt | 7.1 | — | (new) | Done |
| REQ-DOC-014 | SEO metadata | 002 | Article/category | — | — | (new) | Done~ |
| REQ-DOC-015 | Dead endpoints | 024 | — | — | — | (new) | Open |

---

## Section 14 — Prioritization & Sprint Tasks

### 14.1 MoSCoW
- **Must (P0):** REQ-DOC-001/002/003/004/005/008/011/012 + NFR-DOC-001..004.
- **Should (P1):** REQ-DOC-006/007/009/010/013/015 + NFR-DOC-005..009.
- **Could (P2):** REQ-DOC-014, ENH-DOC-001/002/005/006, NFR-DOC-010..012.
- **Won't (now):** ENH-DOC-003/004, multi-language.

### 14.2 Sprint task breakdown (remediation-first)
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|---|---|---|---|---|
| 1 | Install sanitiser; clean content at save; safe render (REQ-DOC-012) | Backend/Frontend | 8 | — | 1 |
| 2 | Add gate to category listing & both image uploads (REQ-DOC-011) | Backend | 3 | — | 1 |
| 3 | Unify create/publish ability to a granted action; resolve plural-policy orphan (decision) | Backend | 3 | — | 1 |
| 4 | Tighten image upload limits/types (NFR-DOC-005) | Backend | 2 | — | 1 |
| 5 | Add `sort_order` migration to `doc_articles` (NFR-DOC-006) | Schema | 2 | — | 1 |
| 6 | Add `sort_order` to category mass-assignment (NFR-DOC-007) | Backend | 1 | — | 1 |
| 7 | Fix article form category field name (NFR-DOC-008) | Frontend | 1 | — | 1 |
| 8 | Implement/remove dead documentation endpoints (REQ-DOC-015) | Backend | 3 | — | 2 |
| 9 | Visibility-aware reader (BR-DOC-017) | Backend | 6 | 1 | 2 |
| 10 | Feature/security test suite (TC-DOC-001..022) | Testing | 16 | 1–9 | 2–3 |
| 11 | Extract content services; move author assignment (NFR-DOC-012) | Backend | 8 | 1 | 3 |
| 12 | Category-tree caching + reader pagination (NFR-DOC-010/011) | Backend | 5 | 11 | 3 |

> Estimation basis: small central CRUD+reader module (3 controllers / 2 models / 3 tables); remediation dominates. Assumes schema additions via new migrations.

---

## Section 15 — User Stories (P0/P1)

- **US-DOC-001** (REQ-DOC-001, P0): As a Content Author, I want to create a category with a unique name so that articles can be grouped. *AC:* unique name accepted with auto slug; duplicate rejected; permission required.
- **US-DOC-002** (REQ-DOC-003, P0): As a Content Author, I want to write an article so that users can read it. *AC:* unique title; author recorded; summary ≤ limit; edit logs changes.
- **US-DOC-003** (REQ-DOC-004, P0): As a Content Author, I want to file an article under several topics so that it's found in each. *AC:* multi-category save; no duplicate links; selection reaches handler (BR-DOC-020).
- **US-DOC-004** (REQ-DOC-005, P0): As a Content Author, I want to schedule a future publish so that content goes live automatically. *AC:* future-dated hidden until date; unpublish removes immediately.
- **US-DOC-005** (REQ-DOC-008, P0): As a Consumer, I want the reader to show only content meant for me so that I don't see drafts or restricted items. *AC:* only published+public+active shown; type-scoped; restricted hidden.
- **US-DOC-006** (REQ-DOC-011, P0): As the Platform, I want every management action gated so that only authorised staff manage content. *AC:* no-permission → forbidden; unauthenticated → login; category list gated.
- **US-DOC-007** (REQ-DOC-012, P0): As the Platform, I want article content cleaned so that published pages cannot run malicious scripts. *AC:* script/event-handler stripped at save; reader never executes scripts.
- **US-DOC-008** (REQ-DOC-006, P1): As a Content Author, I want to attach/replace a featured image so that content is illustrated. *AC:* stored with three sizes; replace removes prior; oversized/SVG rejected.
- **US-DOC-009** (REQ-DOC-007, P1): As a Consumer, I want a three-pane reader with light/dark so that browsing is comfortable. *AC:* first topic/article auto-loads; topic switch loads articles; theme persists.
- **US-DOC-010** (REQ-DOC-010, P1): As a Super Admin, I want to archive, restore, and permanently remove content so that I control the library. *AC:* archive unpublishes/deactivates; restore returns; parent-with-children permanent delete blocked.

---

## Section 16 — Gap Analysis Readiness Index

### 16.1 Coverage table (downstream contract — Yes/No)
| REQ | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---|---|---|---|---|---|---|---|---|
| REQ-DOC-001 | Category mgmt | P0 | DATA_ENTRY,CONFIG | Yes | Yes | No | No | Yes |
| REQ-DOC-002 | Hierarchy | P0 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-DOC-003 | Article mgmt | P0 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-DOC-004 | Categorisation | P0 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-DOC-005 | Publish/schedule | P0 | WORKFLOW,APPROVAL | Yes | Yes | No | No | Yes |
| REQ-DOC-006 | Images | P1 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-DOC-007 | Reader | P1 | DASHBOARD | No | Yes | Yes | No | Yes |
| REQ-DOC-008 | Reader scoping | P0 | WORKFLOW | No | Yes | Yes | No | Yes |
| REQ-DOC-009 | Management hub | P1 | DASHBOARD | No | Yes | No | No | Yes |
| REQ-DOC-010 | Archive/restore | P1 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-DOC-011 | Authorisation | P0 | INTEGRATION | No | No | No | No | Yes |
| REQ-DOC-012 | Sanitisation | P0 | INTEGRATION | No | No | No | No | Yes |
| REQ-DOC-013 | Audit trail | P1 | INTEGRATION | No | No | No | No | Yes |
| REQ-DOC-014 | SEO metadata | P2 | DATA_ENTRY | Yes | Yes | No | No | Yes |
| REQ-DOC-015 | Dead endpoints | P1 | CONFIGURATION | No | No | No | No | Yes |

### 16.2 Business-rule coverage
24 business rules (BR-DOC-001…024): 13 enforced ✅, 7 partial/defective 🟡 (016,019,020,022,024 + 015 partial), 4 not enforced ❌ (014,015,017 + sanitisation). Highest priority: BR-DOC-014 (sanitisation), BR-DOC-016 (authorisation gaps).

### 16.3 Report coverage
3 reports (RPT-DOC-001…003): 1 ✅ (trash), 1 🟡 (inventory via list views, no export), 1 ❌ (most-read — needs view-count ENH-DOC-003).

### 16.4 Totals (reconciled)
- **Functional Requirements (REQ-):** 15 — P0: 8 (001,002,003,004,005,008,011,012); P1: 6 (006,007,009,010,013,015); P2: 1 (014).
- **Business Rules (BR-):** 24.
- **Reports (RPT-):** 3.
- **Enhancements (ENH-):** 6.
- **NFRs:** 13 · **Risks:** 6 · **User Stories:** 10 · **Workflows:** 3 + 2 state machines.
- **Verified module facts:** 3 controllers · 2 models · 2 policies (orphaned) · 2 form requests · 0 services · 3 migrations · 3 tables · 15 views · 27 web routes · 1 test file (~20 structural tests, 0 feature/security).
