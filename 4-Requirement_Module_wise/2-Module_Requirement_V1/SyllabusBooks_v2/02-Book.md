# Book — Business Requirements

## What This Screen Does

The Book screen is the heart of the Syllabus Books module. This is where the school catalogues all academic books — textbooks, reference books, ebooks, etc. Each book can have a cover image, multiple file formats (PDF, EPUB, etc.), a chapter index, and be mapped to specific class-subject combinations.

Think of this as the school's digital bookshelf. Every book that teachers and students need access to lives here.

---

## When This Screen Is Used

- A new textbook is adopted by the school for a subject
- An existing book needs its files updated (new edition)
- A book needs to be assigned to a class and subject
- Admin wants to see which classes use a specific book
- An old book is no longer in use and needs to be archived

---

## Key Sections in the Book Form

### 1. Book Details (Basic Information)

| Field | Required | Description |
|-------|----------|-------------|
| Book Title | Yes | Full title of the book |
| ISBN | No | International Standard Book Number |
| Publisher | No | Name of the publishing house |
| Book Language | Yes | Language the book is written in |
| Edition | No | Edition number or year |
| Tags | No | Free-text keywords for search |
| Class | Yes | Which class this book belongs to |
| Subject | Yes | Which subject this book belongs to |
| Academic Session | Yes | Which academic year this applies to |
| Description | No | Brief description of the book's content |
| Cover Image | No | Book cover photo (uploaded as image file) |
| Ebook File | No | Full ebook upload (optional, separate from chapter files) |

### 2. Author Assignment

Each book can have multiple authors with different roles:

| Role | Description |
|------|-------------|
| Primary Author | Main writer of the book |
| Co-Author | Secondary writer |
| Editor | Person who edited the content |
| Contributor | Person who contributed specific sections |

### 3. Book Files

Each book can have multiple uploaded files. Each file has:

| Field | Description |
|-------|-------------|
| Label | Display name for the file (e.g., "Chapter 1 PDF", "Full Book") |
| File Upload | The actual document (PDF, EPUB, JPG, PNG, DOCX, MOBI) |
| File Format | Auto-detected from the uploaded file |
| Edition | Which edition this file belongs to |
| Primary Flag | Mark one file as the primary/default download |
| Downloadable | Toggle whether this file can be downloaded by students |

### 4. Chapter Index

A list of chapters for the book, with:

| Field | Description |
|-------|-------------|
| Chapter No. | Chapter number (e.g., 1, 2, 3) |
| Chapter Title | Name of the chapter |
| Start Page | Starting page number |
| End Page | Ending page number |
| Summary | Brief chapter description |

---

## Book List Features

| Feature | Description |
|---------|-------------|
| Search | By title, ISBN, publisher, language |
| Filter | By class, subject, academic session, status |
| Status Toggle | Activate/deactivate a book |
| Cover Thumbnail | Small cover image shown in the list |
| Quick Info | Shows number of files, chapters, linked classes |

---

## Business Rules

**Unique ISBN**
If provided, ISBN must be unique — no two books can share the same ISBN. This prevents duplicate catalogue entries.

**Class-Subject Mapping**
A book can be mapped to multiple class-subject combinations, but each combination (class + subject + session) can only appear once per book.

**File Downloads Tracking**
Every time a student or teacher downloads a book file, the download is logged with user name, IP address, and timestamp. This helps schools monitor which content is being accessed.

**Soft Delete**
When a book is deleted, it is soft-deleted (moved to trash). All related files, chapters, and class mappings are kept in the database but hidden. Permanent deletion removes everything.

**Cover Image vs Ebook**
The cover image is a thumbnail for display purposes. The ebook is a separate full-document upload. These are independent of the chapter-level files.

---

## Workflow Steps

**Adding a New Book**
1. Admin clicks Add Book
2. Fills in book details (title, language, class, subject, session)
3. Assigns authors from the author directory (or adds new authors)
4. Uploads cover image and/or ebook
5. Uploads chapter files (PDFs, etc.)
6. Adds chapter index
7. Saves — the book appears in the list

**Editing a Book**
Admin can modify any field, add/remove files, add/remove chapters, or change author assignments.

**Viewing a Book**
Full detail view shows all sections — book info, authors, files, chapters, and class-subject mappings — in one organised page.

---

## Example Scenario

The school adopts "Science for Class 10" published by NCERT. The librarian:
1. Creates a new book entry with title, selects Class 10 and Subject Science
2. Assigns "NCERT" as the Primary Author
3. Uploads the cover image (JPG) and marks it as the display image
4. Uploads 16 chapter PDFs, each labelled "Chapter 1", "Chapter 2", etc.
5. Adds chapter index with chapter numbers and titles
6. Maps the book to Class 10, Subject Science, Session 2025-26

Later, when a student searches for Class 10 Science books, this book appears with its cover, showing 16 files available for download.

---

## Related Screens

- **Author** — Authors must exist before they can be assigned to a book
- **Notes** — Notes can reference a specific book and chapter
- **Downloads** — Book file downloads are tracked in the audit log
- **Settings** — Allowed file formats and size limits are controlled from Settings
