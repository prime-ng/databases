# Business Requirements Document (BRD)
## Module: Documentation
### Sub-Module: Content Management
### Screen: Category Creation

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Category Creation** screen allows admins to build a hierarchical taxonomy (folders and sub-folders) to organize articles so users can easily navigate the knowledge base.

### 1.2 Why is this necessary? (Business Justification)
- **Information Architecture:** Without categories, hundreds of help articles would be a flat, unsearchable mess. Parent-child relationships allow for a clean "book-like" structure.

---

## 2. Document Scope
- **In-Scope:** Creation of Categories, Subcategories, SEO metadata, Slug Auto-generation, Spatie Media uploading, and Activity Logging.
- **Out-of-Scope:** Article creation.

---

## 3. User Personas
1. **Content Admin:** Defines the folder structure of the Knowledge Base.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Hierarchical Structure
- **Parent Category (`parent_id`):** A dropdown to select an existing category. If left empty, this creates a "Root" category. If selected, it creates a "Subcategory".

### FR-02: Category Details & Auto-Slug
- **Name:** The display name of the category.
- **System Behavior (Auto-Slug):** Upon saving, the Model's `booted()` method intercepts the creation/update and automatically generates a URL-friendly `slug` from the `name` using Laravel's `str()->slug()`.
- **Type:** Dropdown classifying the category's purpose (`documentation`, `blog`, `developer`, `help`).
- **Description:** A Summernote WYSIWYG editor.
  - **Image Upload Support:** Includes an AJAX `uploadImage` endpoint saving inline images to `documentation/summernote`.
- **Status:** `is_active` toggle. If disabled, the entire category (and its articles) is hidden from the public.

### FR-03: Media & SEO Metadata
- **Category Image:** Handled via `Spatie\MediaLibrary`. Generates `small`, `medium`, and `large` conversions automatically.
- **Meta Title:** SEO optimized title tag.
- **Meta Description:** SEO optimized meta description.

### FR-04: Auditing & Soft Deletes
- **Activity Log:** Every Create, Update (with old/new changes payload), Restore, and Trash action is recorded in the system's `activity_logs` table via the `activityLog()` helper.
- **Deletion:** Categories are soft-deleted (`is_active` set to false, and record timestamped as deleted) to preserve relational integrity.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Tracking Category Edits
**As an** Admin,
**I want the** system to log exactly what changed when a Category is updated,
**So that** I have an audit trail of who modified the knowledge base structure.

**Acceptance Criteria:**
- **Given** I change the category name from "Guides" to "Setup Guides", **When** I click Save, **Then** the `activity_logs` table stores the `old` ("Guides") and `new` ("Setup Guides") values along with my User ID.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** N/A.
- **Outgoing Dependencies:** `doc_articles` (Articles are linked to these categories).
