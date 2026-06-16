# Library Tab 3: Book Master Catalog

This tab is the central catalog where the librarian creates and manages the master record for every book and resource in the library. Each master record represents a unique title — not individual copies. A single master record can have multiple physical copies, each tracked separately.

---

## How It Works

When the librarian opens this tab, they see a searchable, filterable list of all book master records. Each entry shows the book title, author(s), ISBN, publisher, resource type, and total copy count. The librarian can search by title, ISBN, author name, or keyword.

**Creating a New Book Record:** The librarian clicks "Add Book." They can enter details manually or use the ISBN lookup feature. The ISBN lookup connects to an external book data service (like Google Books or Open Library) and auto-fills fields — title, author, publisher, publication year, page count, cover image, and summary. The librarian reviews and adjusts the auto-filled data before saving.

The form captures: title (required), subtitle, edition, ISBN, ISSN, DOI, publication year, publisher, language, page count, summary, table of contents, cover image, resource type, reference-only flag, lexile level, reading age range, awards, series name and position, and tags.

**Managing Authors and Classification:** After creating the basic record, the librarian adds authors through a search-and-select interface. They mark one author as primary and set the display order. They also assign categories, genres, subjects, and keywords to classify the book. Subjects link the book to the school's curriculum — class and subject combinations so teachers can find curriculum-aligned resources.

**Editing and Version Tracking:** The librarian can edit any field after creation. Changes are tracked in the activity log with before-and-after values. If a book has copies that are currently issued, certain changes may be restricted — for example, changing the resource type while copies are borrowed is blocked.

**Bulk Operations:** The librarian can select multiple books and perform bulk actions: update tags, change resource type, add a common keyword, or export selected records to CSV/Excel.

---

## Important Business Rules

- ISBN lookup is powered by an external API. If the API is unavailable, the librarian can enter all details manually and save the record for later enrichment.
- The ISBN must be unique across all book master records. If a book with the same ISBN already exists, the system warns the librarian and shows the existing record.
- A book master record cannot be deleted if it has any copies attached. The librarian must first withdraw or remove all copies. However, the record can be deactivated (is_active = 0), which hides it from search but preserves data.
- The reference-only flag prevents copies of this book from being issued. Reference books can only be used within the library premises.
- Books linked to the curriculum (through subjects) appear in the teacher's curriculum-aligned resource list. If a subject is removed from the school's curriculum, associated book links are not automatically removed — the librarian receives a notification to review them.
- Cover images are uploaded to the media manager and referenced by URL. Maximum file size is 5 MB. Supported formats: JPEG, PNG, WebP.
- Series grouping allows the librarian to link books in a series. The series name and position are display-only and do not affect issue/return behavior.
- When a book is enriched using ISBN lookup, the source API is recorded in a metadata field for audit purposes.

---

## Database Columns & Behavior

### `lib_books_master`

(Full column table documented in Tab 1 — Dashboard. Refer to that listing for the complete schema.)

### Junction Tables (M:N relationships from this tab)

**`lib_book_author_jnt`** — Links books to authors with ordering
**`lib_book_category_jnt`** — Links books to categories
**`lib_book_genre_jnt`** — Links books to genres
**`lib_book_subject_jnt`** — Links books to curriculum class+subject
**`lib_book_keyword_jnt`** — Links books to keywords

Each junction table has: id (PK), book_id (FK), target entity_id (FK), plus type-specific columns like author_order, is_primary, etc.

---

## Deep Analysis

### Business Workflows & State Machines

**Book Master Lifecycle:**
```
CREATE (manual / ISBN lookup) → DRAFT → COMPLETE → (edit) → UPDATED
                                        ↓
                                  DEACTIVATED (is_active = 0)
                                        ↓
                                  DELETED (only if zero copies)
```

**ISBN Lookup Flow:**
```
Enter ISBN → Validate format → Call external API → Parse response
                                                      ↓
                                            ↓                    ↓
                                     Success: Auto-fill      Failure: Show manual form
                                     all fields              with message
```

**State Restrictions:**
| Book State | Can Edit? | Can Delete? | Can Add Copies? | Can Issue? |
|-----------|-----------|-------------|-----------------|------------|
| Active | Yes | No (if copies exist) | Yes | Yes |
| Deactivated | Yes | No (if copies exist) | No | No (existing copies preserved) |
| Has issued copies | Limited (resource type locked) | No | Yes | Yes |

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| ISBN uniqueness | Unique across all master records | "A book with ISBN {value} already exists: {title}" |
| ISBN format | 10 or 13 digits with optional hyphens | "Invalid ISBN format. Enter a valid 10 or 13-digit ISBN." |
| Title required | Max 500 chars | "Book title is required" |
| Resource type | Must be active | "Selected resource type is inactive" |
| Delete book | Zero copies attached | "Cannot delete: {count} copies are linked to this book. Withdraw copies first." |
| Add author | Author must exist in master | "Author not found. Create the author record first." |
| Subject link | Class and subject must exist | "Invalid class or subject selected." |

**Edge Cases:**
- If the ISBN lookup API returns multiple possible matches, the librarian selects the correct one from a list.
- If the external API is down for more than 5 seconds, the lookup times out and falls back to manual entry.
- A book can have unlimited authors, but only one primary author.
- When a book is deactivated, it disappears from search but existing issued transactions continue normally.
- Cover images are validated for dimensions (minimum 200×300 pixels) on upload.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Masters (self) | `lib_publishers`, `lib_resource_types` | `publisher_id`, `resource_type_id` | Reference data |
| Masters (self) | `lib_authors`, `lib_categories`, `lib_genres`, `lib_keywords` | Via junction tables | Classification |
| SchoolSetup | `sch_classes`, `sch_subjects` | Via `lib_book_subject_jnt` | Curriculum alignment |
| Book Copies | `lib_book_copies` | `book_id` | Physical copy tracking |
| Media Manager | Media files | `cover_image_url` | Cover image storage |

**External API:** ISBN lookup service (Google Books API / Open Library) — call is synchronous with 5-second timeout.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View book catalog | Librarian, Teacher, Admin | `tenant.library.catalog.view` |
| Create new book | Librarian, Admin | `tenant.library.catalog.create` |
| Edit book details | Librarian, Admin | `tenant.library.catalog.update` |
| Use ISBN lookup | Librarian, Admin | `tenant.library.catalog.isbnLookup` |
| Delete/deactivate book | Admin only | `tenant.library.catalog.delete` |
| Manage classification (authors, genres, etc.) | Librarian, Admin | `tenant.library.catalog.classify` |
| Bulk export | Librarian, Supervisor, Admin | `tenant.library.catalog.export` |
| Bulk edit | Librarian, Admin | `tenant.library.catalog.bulkUpdate` |

- Teachers can view the catalog and see curriculum-aligned books but cannot create or edit records.
- Students see a read-only catalog view through the Student Portal integration.
