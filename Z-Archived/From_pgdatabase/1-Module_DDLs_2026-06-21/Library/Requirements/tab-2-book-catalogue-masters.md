# Library Tab 2: Book Catalogue Masters

This tab manages all reference data used throughout the Library module — categories, genres, authors, publishers, keywords, resource types, book conditions, and shelf locations. These are the building blocks that define how books are classified, organized, and found.

---

## How It Works

The tab is organized into sub-sections, each managing one type of master data.

**Categories:** Categories form a hierarchical tree. A top-level category might be "Science" with children like "Physics," "Chemistry," and "Biology." Each category can have sub-categories at multiple levels. The librarian can add, edit, reorder, and delete categories. Moving a parent category moves all its children.

**Genres:** Genres are flat tags like "Fantasy," "Mystery," "Non-Fiction," "Biography." Each genre has a code and name. Genres are linked to books through a many-to-many relationship.

**Authors:** Each author record stores the author's name, optional short name, country, and primary genre. Authors can be linked to multiple books as primary or co-authors with ordering.

**Publishers:** Publisher records include name, address, contact details, email, phone, and website. A single publisher can publish many books.

**Keywords:** Keywords are searchable tags used for fine-grained topic discovery. Each keyword has a unique code and name. Books can have many keywords.

**Resource Types:** These define the format — Physical Book, Digital E-Book, Audio Book, Magazine, Journal, etc. Each type has flags: `is_physical`, `is_digital`, `is_audio_books`, `is_borrowable`. These flags control how the system handles each resource type.

**Book Conditions:** Standardized condition states — New, Good, Fair, Poor, Damaged. Each condition has an `is_borrowable` flag. Books in "Poor" or "Damaged" condition cannot be issued.

**Shelf Locations:** Physical locations follow a hierarchy: Building → Floor → Aisle → Rack → Shelf. Each location record captures this with individual columns plus a computed display name.

---

## Important Business Rules

- Category hierarchy supports unlimited nesting, but the UI displays up to 4 levels by default. Deeper levels are accessible through drill-down.
- Deleting a category that has child categories or linked books is blocked. The librarian must reassign children and remove book links first.
- An author cannot be deleted if they are linked to any books. The system blocks deletion with a count of linked books.
- A publisher with linked books can be deactivated but not deleted — this preserves historical book records.
- Resource types marked `is_borrowable = 0` are informational only and cannot participate in the issue/return workflow.
- Book conditions with `is_borrowable = 0` prevent copies in that condition from being issued. A warning is shown when a copy's condition changes to a non-borrowable state.
- Shelf location deletion is blocked if any book copies reference that location.
- All master records have an `is_active` toggle for soft enable/disable without data loss.
- Master data changes are audited in the activity log. Deletions require confirmation with a count of affected records.

---

## Database Columns & Behavior

### `lib_categories`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| parent_category_id | BIGINT UNSIGNED | `lib_categories.id` | Yes | NULL | Self-referencing parent for hierarchy |
| code | VARCHAR(50) | No | No | — | Unique category code |
| name | VARCHAR(255) | No | No | — | Display name |
| description | TEXT | No | Yes | NULL | Optional description |
| level | INT UNSIGNED | No | No | 0 | Depth in hierarchy |
| display_order | INT UNSIGNED | No | No | 0 | Sort order |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_genres`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | — | Unique genre code |
| name | VARCHAR(255) | No | No | — | Display name |
| description | TEXT | No | Yes | NULL | Optional description |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_authors`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| author_name | VARCHAR(255) | No | No | — | Full author name |
| short_name | VARCHAR(100) | No | Yes | NULL | Abbreviated name |
| country | VARCHAR(100) | No | Yes | NULL | Country of origin |
| primary_genre_id | BIGINT UNSIGNED | `lib_genres.id` | Yes | NULL | Primary writing genre |
| notes | TEXT | No | Yes | NULL | Biographical notes |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_publishers`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | — | Unique publisher code |
| name | VARCHAR(255) | No | No | — | Publisher name |
| address | TEXT | No | Yes | NULL | Physical address |
| contact | VARCHAR(100) | No | Yes | NULL | Contact person |
| email | VARCHAR(100) | No | Yes | NULL | Email address |
| phone | VARCHAR(50) | No | Yes | NULL | Phone number |
| website | VARCHAR(255) | No | Yes | NULL | Website URL |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_keywords`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | — | Unique keyword code |
| name | VARCHAR(255) | No | No | — | Display name |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_resource_types`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | — | Unique code |
| name | VARCHAR(255) | No | No | — | Display name |
| is_physical | TINYINT(1) | No | No | 0 | Physical format flag |
| is_digital | TINYINT(1) | No | No | 0 | Digital format flag |
| is_audio_books | TINYINT(1) | No | No | 0 | Audio format flag |
| is_borrowable | TINYINT(1) | No | No | 1 | Can be issued |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_book_conditions`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | — | Unique code |
| name | VARCHAR(255) | No | No | — | Display name |
| description | TEXT | No | Yes | NULL | Description |
| is_borrowable | TINYINT(1) | No | No | 1 | Can this condition be issued |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_shelf_locations`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | — | Unique location code |
| aisle_number | VARCHAR(50) | No | Yes | NULL | Aisle identifier |
| shelf_number | VARCHAR(50) | No | Yes | NULL | Shelf identifier |
| rack_number | VARCHAR(50) | No | Yes | NULL | Rack identifier |
| floor_number | INT | No | Yes | NULL | Floor level |
| building | VARCHAR(100) | No | Yes | NULL | Building name |
| zone | VARCHAR(100) | No | Yes | NULL | Zone within library |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### Junction Tables

`lib_book_author_jnt` — book_id, author_id, author_order, is_primary
`lib_book_category_jnt` — book_id, category_id
`lib_book_genre_jnt` — book_id, genre_id
`lib_book_keyword_jnt` — book_id, keyword_id

All junction tables use BIGINT UNSIGNED PKs with FKs to their respective master tables and `ON DELETE CASCADE`.

---

## Deep Analysis

### Business Workflows & State Machines

**Master Data Lifecycle:**
```
CREATE → ACTIVE → (edit) → INACTIVE → (reactivate) → ACTIVE
                      ↓
                   DELETE (blocked if referenced)
```

All master entities follow a standard CRUD lifecycle. The key difference is in deletion behavior:
- Soft delete (`deleted_at` set) for all entities
- Hard delete blocked if any child records reference the entity
- Deactivation (`is_active = 0`) preferred over deletion to preserve referential integrity

**Category Hierarchy Management:**
- Adding a child increments the child's `level` to (parent_level + 1)
- Moving a category recalculates level for all descendants
- Reordering uses `display_order` with drag-and-drop

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Delete category | No child categories or book links | "Category has X child categories and Y linked books. Reassign or remove them first." |
| Delete author | No linked books | "Author is linked to X books. Remove all book links before deleting." |
| Delete publisher | No linked books | "Publisher has X linked books. Deactivate instead of deleting." |
| Category code | Unique, max 50 chars | "Category code must be unique" |
| ISBN format | 10 or 13 digit standard | "ISBN must be a valid 10 or 13 digit number" |
| Shelf location delete | No copies at that location | "X book copies are currently at this location. Move them first." |

**Edge Cases:**
- A category cannot be its own parent (circular reference prevention).
- Setting a book condition's `is_borrowable = 0` does not retroactively affect already-issued books — only prevents new issues.
- Deactivating a publisher preserves all historical book references.
- Shelf location code is auto-generated from building+floor+aisle+rack+shelf but can be overridden.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Book Master | `lib_books_master` | `publisher_id`, `resource_type_id` | Core catalog linkage |
| Book Copies | `lib_book_copies` | `shelf_location_id`, `current_condition_id` | Physical copy placement |
| Book-Author Jnt | `lib_book_author_jnt` | `author_id` | M:N author mapping |
| Book-Category Jnt | `lib_book_category_jnt` | `category_id` | M:N category mapping |
| Book-Genre Jnt | `lib_book_genre_jnt` | `genre_id` | M:N genre mapping |
| Book-Keyword Jnt | `lib_book_keyword_jnt` | `keyword_id` | M:N keyword mapping |

**Events:** All CRUD operations on master data should log to the activity log.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View master data | Librarian, Supervisor, Admin | `tenant.library.masters.view` |
| Create/Edit categories | Librarian, Admin | `tenant.library.masters.manage` |
| Create/Edit genres | Librarian, Admin | `tenant.library.masters.manage` |
| Create/Edit authors | Librarian, Admin | `tenant.library.masters.manage` |
| Create/Edit publishers | Librarian, Admin | `tenant.library.masters.manage` |
| Create/Edit keywords | Librarian, Admin | `tenant.library.masters.manage` |
| Create/Edit resource types | Admin only | `tenant.library.masters.configure` |
| Create/Edit conditions | Admin only | `tenant.library.masters.configure` |
| Create/Edit shelf locations | Librarian, Admin | `tenant.library.masters.manage` |
| Delete any master record | Admin only | `tenant.library.masters.delete` |
