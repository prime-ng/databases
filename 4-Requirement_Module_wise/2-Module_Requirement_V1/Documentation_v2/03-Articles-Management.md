# Business Requirements Document (BRD)
## Module: Documentation
### Sub-Module: Content Management
### Screen: Article Creation

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Article Creation** screen is a full-fledged WYSIWYG authoring tool for writing the actual documentation pages, blogs, and help guides.

### 1.2 Why is this necessary? (Business Justification)
- **Content Delivery:** This is where the actual value is created. It includes granular visibility controls so internal SOPs aren't leaked to public clients.

---

## 2. Document Scope
- **In-Scope:** Rich text authoring, category binding, visibility rules, featured images (Spatie Media), Auto-slug generation, Activity Logging, and SEO configuration.
- **Out-of-Scope:** Frontend rendering layout.

---

## 3. User Personas
1. **Technical Writer:** Writes the documentation.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Basic Classification & Visibility
- **Article Title:** The main `h1` heading.
- **System Behavior (Auto-Slug):** Upon saving, the Model's `booted()` method automatically generates a URL-friendly `slug` from the `title`.
- **Article Type:** Dropdown (`documentation`, `blog`, `developer`, `help`).
- **Visibility:** Dropdown restricting who can read this article:
  - `public`: Anyone on the internet.
  - `client`: Logged-in school clients.
  - `developer`: Technical API consumers.
  - `internal`: Internal staff only.
  - `draft`: Work-in-progress, hidden from everyone except admins.
- **Categories:** A multiple-select box (syncs to `doc_article_category_jnt` pivot table).

### FR-02: Content Authoring & Summernote Integration
- **Excerpt:** A short 150-160 character summary.
- **Article Content:** A Summernote WYSIWYG editor.
  - **AJAX Image Upload:** The controller provides an `uploadImage` endpoint saving inline images to `documentation/articles/summernote`.

### FR-03: SEO & Spatie Media
- **Featured Image:** Uses `Spatie\MediaLibrary` bound to the `doc_article_image` collection. Automatically crops/sharpens images into `small` (100x100), `medium` (300x300), and `large` (600x600) variants.
- **SEO Fields:** `meta_title`, `meta_description`, and `canonical_url`.

### FR-04: Auditing & Lifecycle
- **Author Tracking:** Saves the `created_by` field to the active User.
- **Activity Log:** All Create, Update, Restore, and Trash operations are deeply audited, including JSON payloads of what fields were changed.
- **Soft Delete:** Deleting an article toggles `is_published = false` and soft deletes the record.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Inline Image Uploads
**As a** Technical Writer,
**I want to** paste images directly into the Summernote content editor,
**So that** I can write visual step-by-step guides.

**Acceptance Criteria:**
- **Given** I am writing an article, **When** I insert an image into the editor, **Then** an AJAX request uploads it to the server and returns a public asset URL to embed inline.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `doc_categories`.
- **Outgoing Dependencies:** The Main Knowledge Base Viewer UI.
