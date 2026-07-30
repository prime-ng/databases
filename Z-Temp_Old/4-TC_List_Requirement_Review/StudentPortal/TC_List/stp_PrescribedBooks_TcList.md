
# Test Case List: stp_PrescribedBooks

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Prescribed Books |
| **FRD Reference** | REQ-STP-022, BR-STP-001 |
| **Controller** | `StudentPortalController` (prescribedBooks, downloadEbook, downloadBookFile) |
| **Total Test Cases** | 18 |

---

## 2. Test Case Summary

### 2.1 Prescribed Books Listing

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-PB-001 | Verify prescribed books page loads grouped by subject | Student has active session with class_id; books prescribed for class+session | 1. Login as student with prescribed books<br>2. Navigate to `/prescribed-books` | Books displayed grouped by subject name. Each group shows subject heading. Cards show title, cover image, authors, publisher, language | ✅ | — | ⬜ | ◌ |
| TC-PB-002 | Verify only active `BookClassSubject` entries shown | Some book-class mappings are inactive | 1. Navigate to prescribed-books | Only entries where `BookClassSubject.is_active = true` appear | ✅ | — | ⬜ | ◌ |
| TC-PB-003 | Verify books with `is_active = false` are filtered out | Book is soft-disabled | 1. Navigate to prescribed-books | Books where `book.is_active = false` are excluded via `->filter()` | ✅ | — | ⬜ | ◌ |
| TC-PB-004 | Verify books grouped under 'General' when subject name is null | BookClassSubject has no subject relation | 1. Navigate to prescribed-books | Books with null subject appear under 'General' group heading | ✅ | — | ⬜ | ◌ |
| TC-PB-005 | Verify student without active session sees empty state | Student has no `currentAcademicSession` | 1. Login as student without current session<br>2. Navigate to `/prescribed-books` | Empty `$classSubjectLinks`. Page renders with no book groups | ✅ | — | ⬜ | ◌ |
| TC-PB-006 | Verify student with no prescribed books sees empty groups | No BookClassSubject matches student's class+session | 1. Navigate to prescribed-books | Empty collection. Page renders with "no books" empty state | ✅ | — | ⬜ | ◌ |
| TC-PB-007 | Verify chapter file list shows files ordered by `is_primary` DESC then default | Book has multiple chapter files | 1. Navigate to prescribed-books<br>2. Expand chapter files for a book | Files ordered: primary files first, then others. Each shows chapter number, title, file name, file size, download button | ✅ | — | ⬜ | ◌ |
| TC-PB-008 | Verify activity log on page view | User is authenticated | 1. Navigate to `/prescribed-books` | Activity log entry: "Student viewed prescribed books." with student context | ✅ | — | ⬜ | ◌ |

### 2.2 Download E-Book

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-PB-009 | Verify student can download full e-book | Book has ebook media, is_downloadable = true, student has access via BookClassSubject | 1. GET `/prescribed-books/{book}/download-ebook` | File downloads. Activity log created | ✅ | — | ⬜ | ◌ |
| TC-PB-010 | Verify e-book download blocked when no access (class mismatch) | Book is not prescribed for student's class+session | 1. GET download-ebook for unassigned book | 403 Forbidden | ✅ | — | ⬜ | ◌ |
| TC-PB-011 | Verify e-book download blocked when book has no ebook media | Book has no attached 'ebook' media | 1. GET download-ebook for book without media | 404 Not Found | ✅ | — | ⬜ | ◌ |
| TC-PB-012 | Verify e-book download blocked for student without active session | Student has no current session | 1. GET download-ebook | 403 (session → class_id → access check fails) | ✅ | — | ⬜ | ◌ |

### 2.3 Download Book File (Chapter File)

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-PB-013 | Verify student can download a chapter file | File belongs to book, is_downloadable = true, is_active = true, student has access, file has media | 1. GET `/prescribed-books/{book}/files/{file}/download` | File downloads. `SlbBookDownload` record created with book_file_id, user_id, ip, user_agent. Activity log created | ✅ | — | ⬜ | ◌ |
| TC-PB-014 | Verify file download blocked when file does not belong to book | `file.book_id !== book.id` | 1. GET download with mismatched book_id and file_id | 404 Not Found | ✅ | — | ⬜ | ◌ |
| TC-PB-015 | Verify file download blocked when `book.is_downloadable = false` | Book is not downloadable | 1. GET download | 403: "This file is not available for download" | ✅ | — | ⬜ | ◌ |
| TC-PB-016 | Verify file download blocked when `file.is_downloadable = false` | File is not downloadable | 1. GET download | 403: "This file is not available for download" | ✅ | — | ⬜ | ◌ |
| TC-PB-017 | Verify file download blocked when `file.is_active = false` | File is inactive | 1. GET download | 403: "This file is not available for download" | ✅ | — | ⬜ | ◌ |
| TC-PB-018 | Verify file download blocked when student has no access | Book not prescribed for student | 1. GET download for non-prescribed book | 403 Forbidden | ✅ | — | ⬜ | ◌ |
| TC-PB-019 | Verify file download blocked when file has no media | File has no attached Spatie media | 1. GET download for file without media | 404: "File not stored" | ✅ | — | ⬜ | ◌ |
| TC-PB-020 | Verify file download blocked for student without active session | Student has no current session | 1. GET download | 403 (access check fails) | ✅ | — | ⬜ | ◌ |
