# Syllabus Books Module — Business Requirements Overview

## Module Purpose

The Syllabus Books module is a digital library management system that allows a school to catalogue books, upload study notes, track downloads, and configure content policies — all in one place.

Think of this as the school's central repository for academic content. Teachers can upload books and notes, students can download them, and the admin controls what formats are allowed, who can upload, and whether content is watermarked or protected.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| Admin / Librarian | Manage books, authors, approve notes, configure settings |
| Teachers | Upload books, create study notes, share with classes |
| Students | Download books and notes, rate notes |
| Academic Coordinator | Map books to class-subject combinations, approve student uploads |

---

## Module Screens (Tab-wise)

The entire Syllabus Books module is accessible through a single multi-tab interface at: `/syllabus-books`

| Tab | Screen | Purpose |
|-----|--------|---------|
| Author | Author Master | Register book authors (writers, editors, contributors) |
| Book | Book Master | Catalogue books with cover image, files, chapters, class-subject mapping |
| Notes | Notes | Upload and manage study notes with approval workflow |
| Downloads | Download Audit | Read-only log of who downloaded which books and notes |
| Settings | Module Configuration | Control allowed formats, size limits, content protection |

---

## Core Business Flow

```
Author Registration
       ↓
Book Creation (title, ISBN, publisher, cover image, language)
       ↓
Assign Authors to Book (Primary Author, Co-Author, Editor, Contributor)
       ↓
Upload Book Files (PDF, EPUB, etc.) + Define Chapters
       ↓
Map Book to Class + Subject + Academic Session
       ↓
Teachers Create Study Notes (linked to books/chapters or standalone)
       ↓
Notes Go Through Approval Workflow (DRAFT → PENDING → APPROVED/REJECTED)
       ↓
Students Download Books and Notes (tracked in audit log)
       ↓
Admin Monitors Downloads via Audit Tab
```

---

## Document Index

| File | Screen | Description |
|------|--------|-------------|
| [01-Author.md](./01-Author.md) | Author | Author registration and management |
| [02-Book.md](./02-Book.md) | Book | Book catalogue with files, chapters, class-subject mapping |
| [03-Notes.md](./03-Notes.md) | Notes | Study notes with approval workflow |
| [04-Downloads.md](./04-Downloads.md) | Downloads | Download audit log |
| [05-Settings.md](./05-Settings.md) | Settings | Module configuration |

---

## Key Dependencies Between Screens

- An **Author** does not need to exist before a Book — authors can be created at any time
- A **Book** must exist before **Book Files** and **Chapters** can be added
- A **Book** must exist before **Class-Subject Mapping** can be created
- **Notes** can exist independently of books, or be linked to a specific book + chapter
- **Downloads** is a read-only audit view derived from actual student/teacher download activity
- **Settings** controls limits and policies that apply across all screens (file size, formats, watermarks)

---

## Data Tables Reference

| Table | Description |
|-------|-------------|
| `slb_book_authors` | Author master — name, qualification, bio |
| `slb_book_author_jnt` | Junction — links books to authors with role (PRIMARY/CO_AUTHOR/EDITOR/CONTRIBUTOR) |
| `slb_books` | Book master — title, ISBN, publisher, language, edition, cover image |
| `slb_book_class_subject_jnt` | Junction — maps books to class+subject+academic session |
| `slb_book_files` | Book file records — format, size, label, downloadability |
| `slb_book_chapters` | Chapter index — number, title, page range |
| `slb_book_topic_mapping` | Links books to syllabus topics |
| `slb_notes` | Study notes — title, type, class/subject, approval status |
| `slb_notes_files` | Note file attachments |
| `slb_notes_downloads` | Note download audit log |
| `slb_notes_ratings` | Note ratings (1–5 stars) |
| `slb_book_downloads` | Book file download audit log |
| `slb_config` | Module configuration singleton |
