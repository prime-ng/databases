
# Test Case List: stp_StudyResources

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Study Resources |
| **FRD Reference** | REQ-STP-022, BR-STP-001 |
| **Controller** | `StudentPortalController` (studyResources, downloadNote, rateNote) |
| **Total Test Cases** | 18 |

---

## 2. Test Case Summary

### 2.1 Study Resources Listing

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-SR-001 | Verify study resources page loads grouped by notes_type | Student has active session with class_id; notes exist for class | 1. Login as student with assigned notes<br>2. Navigate to `/study-resources` | Notes displayed grouped by `notes_type`. Each group has heading. Cards show title, subject, chapter, avg_rating, download_count | ✅ | — | ⬜ | ◌ |
| TC-SR-002 | Verify only APPROVED + is_active notes are shown | Notes with mixed statuses exist | 1. Navigate to study-resources | Only notes with `status = APPROVED` AND `is_active = true` appear | ✅ | — | ⬜ | ◌ |
| TC-SR-003 | Verify only notes with matching class_id are shown | Notes exist for different classes | 1. Navigate to study-resources | Only notes where `class_id` matches student's current class appear | ✅ | — | ⬜ | ◌ |
| TC-SR-004 | Verify only notes with proper visibility scope shown | Notes with CLASS_ONLY, SUBJECT_WIDE, SCHOOL_WIDE exist | 1. Navigate to study-resources | Notes with `visibility IN ('CLASS_ONLY', 'SUBJECT_WIDE', 'SCHOOL_WIDE')` appear. Others hidden | ✅ | — | ⬜ | ◌ |
| TC-SR-005 | Verify student without active session sees empty state | Student has no `currentAcademicSession` | 1. Login as student without active session<br>2. Navigate to `/study-resources` | Empty `notesByType` collection. Page renders with no resource groups | ✅ | — | ⬜ | ◌ |
| TC-SR-006 | Verify page shows student's previous ratings pre-loaded | Student has rated some notes | 1. Rate 2 notes<br>2. Navigate to `/study-resources` | Previously rated notes show the student's rating (star value and review text) | ✅ | — | ⬜ | ◌ |
| TC-SR-007 | Verify activity log on page view | User is authenticated | 1. Navigate to `/study-resources` | Activity log entry: "Student viewed study resources." with context | ✅ | — | ⬜ | ◌ |

### 2.2 Download Note

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-SR-008 | Verify student can download an approved downloadable note | Note is APPROVED, is_active, is_downloadable = true, matches student's class, has media file | 1. GET `/study-resources/{note}/download` | File downloads. `download_count` incremented by 1. `SlbNotesDownload` record created with notes_id, user_id, ip, user_agent | ✅ | — | ⬜ | ◌ |
| TC-SR-009 | Verify download blocked for non-APPROVED note | Note status is PENDING or DRAFT | 1. GET download for non-approved note | 404 Not Found | ✅ | — | ⬜ | ◌ |
| TC-SR-010 | Verify download blocked for inactive note | Note `is_active = false` | 1. GET download for inactive note | 404 Not Found | ✅ | — | ⬜ | ◌ |
| TC-SR-011 | Verify download blocked when `is_downloadable = false` | Note exists but is not downloadable | 1. GET download | 403: "This note is not available for download" | ✅ | — | ⬜ | ◌ |
| TC-SR-012 | Verify download blocked when note class_id differs from student's class | Note belongs to different class | 1. GET download (note for class 10, student in class 9) | 403 Forbidden | ✅ | — | ⬜ | ◌ |
| TC-SR-013 | Verify download blocked when note has no media file | Note exists but no file uploaded | 1. GET download | 404: "No file attached to this note" | ✅ | — | ⬜ | ◌ |
| TC-SR-014 | Verify download blocked for student without active session | Student has no current session | 1. GET download | 403 (class_id check fails because session → class_id is null) | ✅ | — | ⬜ | ◌ |

### 2.3 Rate Note

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-SR-015 | Verify student can rate a note with valid rating (1-5) | Note is APPROVED, is_active, matches student's class | 1. POST `/study-resources/{note}/rate` with `rating=4`, `review="Good notes"` | 200. `SlbNotesRating` created/updated. JSON: `{success: true, message: "Rating submitted. Thank you!", avg_rating: N, total_ratings: M}` | ✅ | — | ⬜ | ◌ |
| TC-SR-016 | Verify rating updates existing record (updateOrCreate) | Student already rated this note | 1. POST rate again with different `rating=5` | Existing rating updated to 5. `avg_rating` on note recalculated | ✅ | — | ⬜ | ◌ |
| TC-SR-017 | Verify rating 0 or 6 is rejected | Invalid value | 1. POST rate with `rating=0` or `rating=6` | 422 validation error | ✅ | — | ⬜ | ◌ |
| TC-SR-018 | Verify review text > 500 chars rejected | Long text | 1. POST rate with `review=501_char_string` | 422 validation error | ✅ | — | ⬜ | ◌ |
| TC-SR-019 | Verify rating blocked for non-APPROVED note | Note not approved | 1. POST rate for non-approved note | 404 Not Found | ✅ | — | ⬜ | ◌ |
| TC-SR-020 | Verify rating blocked for wrong class note | Note does not match student's class | 1. POST rate for other class note | 403 Forbidden | ✅ | — | ⬜ | ◌ |
| TC-SR-021 | Verify `avg_rating` on note recalculated after rating | Note had previous ratings | 1. POST a new rating<br>2. Check `avg_rating` on SlbNote | `avg_rating` column updated to rounded average of all ratings | ✅ | — | ⬜ | ◌ |
