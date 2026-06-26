# Resources — Prescribed Books Tab Requirements

## 1. Functional Overview
Lists textbooks prescribed for the student's class and session, allowing downloads of the full e-book or individual chapter files.

---

## 2. Directory Layout & Parameters

### A. Books Catalog
- Displays prescribed textbooks grouped by subject:
  - Textbook Name & Cover Image.
  - Authors & Publisher.
  - Language.
  - Action buttons: "Download full E-Book" and "View Chapter Files".

### B. Chapter File List
- Expandable list of chapters:
  - Chapter Number & Title.
  - Chapter File Name & Size.
  - Action button: "Download Chapter PDF".
  - Logs downloads (Book File ID, User ID, IP, User Agent).

---

## 3. Database References
- **Models**:
  - `Modules\SyllabusBooks\Models\BokBook`
  - `Modules\SyllabusBooks\Models\BookFile`
  - `Modules\SyllabusBooks\Models\BookClassSubject`
- **Tables**:
  - `bok_books`
  - `bok_book_files`
  - `bok_book_class_subjects`
