
# Module Requirement: stp_PrescribedBooks

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Prescribed Books |
| **FRD Reference** | REQ-STP-022, BR-STP-001 |
| **Table Prefix** | `bok_*`, `slb_*` (SyllabusBooks module) |
| **DB Layer** | Tenant (tenant_{uuid}) |
| **Controller** | `StudentPortalController@prescribedBooks`, `downloadEbook`, `downloadBookFile` |
| **Routes** | `GET /prescribed-books`, `GET /prescribed-books/{book}/download-ebook`, `GET /prescribed-books/{book}/files/{file}/download` |
| **Associated View** | `studentportal::resources.prescribed-books` |

---

## 2. Directory Layout

### 2.1 Route Map

| Method | URI | Controller Method | Name | Purpose |
|--------|-----|-------------------|------|---------|
| GET | `/prescribed-books` | `prescribedBooks` | `prescribed-books` | List prescribed textbooks grouped by subject |
| GET | `/prescribed-books/{book}/download-ebook` | `downloadEbook` | `prescribed-books.download-ebook` | Download full e-book |
| GET | `/prescribed-books/{book}/files/{file}/download` | `downloadBookFile` | `prescribed-books.files.download` | Download individual chapter file |

---

## 3. Data / Entities

### 3.1 Primary Tables (SyllabusBooks Module — Consumed)

| Table | Purpose |
|-------|---------|
| `bok_books` | Textbook master — title, ISBN, publisher, language, is_downloadable, media (ebook) |
| `bok_book_files` | Chapter/unit files linked to a book — file details, is_primary, is_downloadable, is_active |
| `bok_book_class_subjects` | Junction: book → class → subject → academic_session — defines which books are prescribed for which class/session |
| `slb_book_downloads` | Download audit log — book_file_id, user_id, ip_address, user_agent |

### 3.2 Key Model Relationships

```
Student (std_students)
  └── currentAcademicSession
        ├── classSection ── class_id
        └── academic_session_id

BookClassSubject (bok_book_class_subjects)
  ├── class_id (→ matches student's class)
  ├── academic_session_id (→ matches student's session)
  ├── subject (sch_subjects)
  └── book (bok_books)
        ├── authors (lib_authors)
        ├── media (spatie — ebook)
        ├── languageRelation
        ├── files (bok_book_files) ── media (spatie)
        └── chapters (slb_chapters)
```

---

## 4. Business Rules

### BR-STP-001 (Data Ownership)
- Only books prescribed for the student's class AND academic session are shown.
- `BookClassSubject::where('class_id', ...)->where('academic_session_id', ...)->where('is_active', true)`

### Additional Rules (Controller-Enforced)
- **E-Book download**: Requires `hasAccess` via `BookClassSubject` junction check.
- **Book file download**: Requires `is_downloadable` on both book and file; file must belong to book; student must have access via `BookClassSubject`.
- **Download tracking**: Each download creates a `SlbBookDownload` record with book_file_id, user_id, ip, user_agent.
- **Books without active relationship**: Filtered out via `->filter(fn($r) => $r->book?->is_active)`.

---

## 5. Business Logic / Conditions

| Condition | Trigger | On-Violation |
|-----------|---------|-------------|
| Student has no active session or class_id | Page load | Empty `$classSubjectLinks` collection |
| No book-class-subject mapping for student's class+session | Page load | Empty grouped collection |
| Book `is_active` is false | Page load | Filtered out via `->filter()` |
| Book `is_downloadable` false | Download ebook | 403: "This file is not available for download" |
| File `is_downloadable` false | Download file | 403: "This file is not available for download" |
| File `is_active` false | Download file | 403: "This file is not available for download" |
| File does not belong to book (mismatch) | Download file | 404 |
| Student does not have access via BookClassSubject | Download ebook/file | 403 |
| Media file not stored in media library | Download | 404: "File not stored" or 404 generic |

---

## 6. Access Control / Permissions

- **Authentication**: All routes require `auth` middleware.
- **Authorization Model**: No explicit `Gate::authorize()` calls.
- **Data Scoping**: Books filtered by class + academic session via `BookClassSubject`.
- **Download Guard**: `abort_unless()` access check via `BookClassSubject::exists()` for both e-book and file downloads.

---

## 7. States / Statuses

| Entity | State | Meaning |
|--------|-------|---------|
| BookClassSubject.is_active | true/false | Whether the book is currently prescribed |
| BookFile.is_active | true/false | Whether the file is available |
| BookFile.is_primary | true/false | Primary file indicator (ordered first) |
| Book.is_downloadable | true/false | Whether the ebook can be downloaded |
| BookFile.is_downloadable | true/false | Whether the file can be downloaded |

---

## 8. Notifications / Alerts

- No notifications sent for book downloads or views.
- Activity log entries created for view and download actions.

---

## 9. UI / UX Spec

### Prescribed Books Page
- **Grouped by subject name**: Books are grouped by `$r->subject?->name ?? 'General'`.
- **Each book card displays**:
  - Textbook name
  - Cover image (via Spatie Media)
  - Author(s)
  - Publisher
  - Language
  - "Download Full E-Book" button
  - Expandable chapter file list with "Download Chapter" buttons

### Chapter File List
- Expandable section per book
- Chapter number + title
- File name + size
- "Download Chapter PDF" button

### Download Flows
- **Full E-Book**: Route `downloadEbook` → gets `getFirstMedia('ebook')` → `response()->download()`.
- **Chapter File**: Route `downloadBookFile` → gets `getFirstMedia(BookFile::MEDIA_FILE)` → `response()->download()`.

---

## 10. Error / Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Student has no active session | Empty `$classSubjectLinks`. Page renders with no books |
| No books prescribed for class+session | Empty grouped collection. Page renders "no prescribed books" |
| Book has no ebook media attached | 404 on `getFirstMedia('ebook')` → abort |
| File has no media attached | 404: "File not stored" |
| Book is_active = false | Filtered out from listing |
| File is_active = false | Hidden from chapter file list |
| Download of non-downloadable ebook | 403 |
| Book file ID does not belong to book | 404 (abort_if mismatch) |

---

## 11. Performance / NFR

- **Eager Loading**: Books loaded with `authors`, `media`, `languageRelation`, `files` (with media), `chapters`.
- **No Pagination**: Books fetched via `->get()`. Could be NFR concern if many prescribed books.
- **Filtering**: In-memory filter `->filter(fn($r) => $r->book?->is_active)` after query.

---

## 12. Dependencies (Cross-Module)

| Dependency | Type | Details |
|-----------|------|---------|
| `Modules\SyllabusBooks\Models\BokBook` | Hard | Core ebook model |
| `Modules\SyllabusBooks\Models\BookFile` | Hard | Chapter/file model |
| `Modules\SyllabusBooks\Models\BookClassSubject` | Hard | Prescription junction |
| `Modules\SyllabusBooks\Models\SlbBookDownload` | Hard | Download audit log |
| `Modules\StudentProfile\Models\Student` | Hard | Student record for class/session resolution |

---

## 13. Test Scenarios Summary

**Positive:**
- Student views prescribed books grouped by subject
- Student downloads a full e-book
- Student downloads a chapter file
- Books with cover images display correctly

**Negative:**
- Student with no active session sees empty state
- Student tries to download book not prescribed for their class → 403
- Student tries to download non-downloadable book → 403
- Book file not belonging to the book → 404
- E-book with no media → 404

---

## 14. FRD Traceability

| FRD ID | Requirement | Status |
|--------|-------------|--------|
| REQ-STP-022 | Study Resources + Prescribed Books — browse, download, rate | ✅ |
| BR-STP-001 | Data ownership — student only sees own class's prescribed books | ✅ |

---

## 15. Known Gaps / Issues

| Gap ID | Issue | Severity |
|--------|-------|----------|
| GAP-STP-N/A | No pagination on prescribed books — all fetched via `->get()` | Low |
| GAP-STP-N/A | No `Gate::authorize()` calls — class/session check is implicit | Low |
| GAP-STP-N/A | In-memory filter for `book->is_active` — could be done at query level | Low |

---

## 16. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| V1 | 2026-07-23 | OpenCode | Initial requirement document |
