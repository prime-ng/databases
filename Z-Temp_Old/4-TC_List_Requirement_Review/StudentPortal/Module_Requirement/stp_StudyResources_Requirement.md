
# Module Requirement: stp_StudyResources

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Study Resources |
| **FRD Reference** | REQ-STP-022, BR-STP-001 |
| **Table Prefix** | `slb_*` (SyllabusBooks module) |
| **DB Layer** | Tenant (tenant_{uuid}) |
| **Controller** | `StudentPortalController@studyResources`, `rateNote`, `downloadNote` |
| **Routes** | `GET /study-resources`, `GET /study-resources/{note}/download`, `POST /study-resources/{note}/rate` |
| **Associated View** | `studentportal::resources.index` |

---

## 2. Directory Layout

### 2.1 Route Map

| Method | URI | Controller Method | Name | Purpose |
|--------|-----|-------------------|------|---------|
| GET | `/study-resources` | `studyResources` | `study-resources` | Browse study notes grouped by type |
| GET | `/study-resources/{note}/download` | `downloadNote` | `study-resources.download` | Download a study note file |
| POST | `/study-resources/{note}/rate` | `rateNote` | `study-resources.rate` | Rate and review a study note |

---

## 3. Data / Entities

### 3.1 Primary Tables (SyllabusBooks Module — Consumed)

| Table | Purpose |
|-------|---------|
| `slb_notes` | Study notes — title, class_id, subject_id, book_id, chapter_id, notes_type, status, visibility, is_downloadable, download_count, avg_rating |
| `slb_notes_ratings` | User ratings for notes — notes_id, user_id, rating (1-5), review text |
| `slb_notes_downloads` | Download audit log — notes_id, user_id, ip_address, user_agent |

### 3.2 Key Model Relationships

```
Student (std_students)
  └── currentAcademicSession ── classSection ── class_id
        └── SlbNote (slb_notes) ── class_id
              ├── Subject (sch_subjects)
              ├── BokBook (bok_books)
              ├── Chapter (slb_chapters)
              ├── Media (spatie media-library)
              └── SlbNotesRating (slb_notes_ratings)
```

---

## 4. Business Rules

### BR-STP-001 (Data Ownership)
- Only notes matching the student's class_id are shown.
- Notes must have `status = 'APPROVED'` and `is_active = true`.
- Notes must have `visibility` in `['CLASS_ONLY', 'SUBJECT_WIDE', 'SCHOOL_WIDE']`.

### Additional Rules (Controller-Enforced)
- **Download restriction**: `is_downloadable` must be `true` for download.
- **Class match verification**: `note->class_id` must match student's class_id (check via `abort_unless`).
- **Rating**: One rating per user per note (updateOrCreate pattern).
- **Rating range**: 1-5 integer, review max 500 characters.
- **Download tracking**: Each download increments `download_count` and creates a `SlbNotesDownload` record.
- **Media attachment**: Note must have a file via Spatie Media Library (`SlbNote::MEDIA_FILE`).

---

## 5. Business Logic / Conditions

| Condition | Trigger | On-Violation |
|-----------|---------|-------------|
| Note is not APPROVED | Page load / Download / Rate | Excluded from list; 404 on direct access |
| Note is not active | Page load / Download / Rate | Excluded from list; 404 on direct access |
| Note visibility not matching class scope | Page load | Excluded from list |
| Note class_id != student's class_id | Download / Rate | 403 Forbidden |
| Note is not downloadable | Download | 403: "This note is not available for download" |
| No file attached to note | Download | 404: "No file attached to this note" |
| Rating out of range (1-5) | POST rate | 422 validation error |
| Review exceeds 500 chars | POST rate | 422 validation error |

---

## 6. Access Control / Permissions

- **Authentication**: All routes require `auth` middleware.
- **Authorization Model**: No explicit `Gate::authorize()` calls.
- **Data Scoping**: Notes pre-filtered by `class_id` (from student's current session), `status`, `is_active`, and `visibility`.
- **Rate/Download Guard**: Direct `abort_unless()` checks for class ownership and note status.

---

## 7. States / Statuses

| Note Status | Meaning |
|-------------|---------|
| APPROVED | Ready for student viewing/download |
| PENDING/REJECTED/DRAFT | Hidden from student portal (not returned by query) |

| Visibility | Meaning |
|------------|---------|
| CLASS_ONLY | Visible only to students in the same class |
| SUBJECT_WIDE | Visible to all students of the same subject |
| SCHOOL_WIDE | Visible to all students in the school |

---

## 8. Notifications / Alerts

- No notifications are sent for study resource actions.
- Activity log entries created for view, download, and rating actions.

---

## 9. UI / UX Spec

### Study Resources Page
- **Grouped by note type**: Notes are fetched and grouped by `notes_type` column.
- **Each resource card displays**:
  - Title
  - Subject name
  - Chapter title
  - Author/Teacher name (via note creator relationship)
  - Average rating (stars) + total ratings count
  - Download count
- **Actions**: "Download Notes" button (if `is_downloadable`), "Rate Note" button.
- **User ratings**: Pre-loaded user ratings shown on cards for notes the user has already rated.

### Rating Modal
- Star rating input (1-5)
- Optional review text (max 500 characters)
- On submit: AJAX POST, returns updated `avg_rating` and `total_ratings`.

### Download
- Direct file download via `response()->download()`.
- Increments `download_count`.
- Logs download to `slb_notes_downloads`.

---

## 10. Error / Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Student has no active session | Empty `notesByType` collection — all dependent queries return empty |
| No notes exist for class | Empty grouped collection, page renders with "no resources" |
| Note file missing from media library | `getFirstMedia()` returns null → abort(404) |
| User tries to access another class's note | 403 via `abort_unless()` |
| Download of non-downloadable note | 403 with message |

---

## 11. Performance / NFR

- **Eager Loading**: Notes loaded with `subject`, `book`, `chapter`, `media` relationships.
- **Rating Pre-load**: All user ratings for visible notes loaded in a single query via `whereIn('notes_id', $allNoteIds)`.
- **No Pagination**: Notes are fetched via `->get()` (grouped by type for display). Could be an NFR concern if many notes exist.

---

## 12. Dependencies (Cross-Module)

| Dependency | Type | Details |
|-----------|------|---------|
| `Modules\SyllabusBooks\Models\SlbNote` | Hard | Core model for study notes |
| `Modules\SyllabusBooks\Models\SlbNotesRating` | Hard | Rating model |
| `Modules\SyllabusBooks\Models\SlbNotesDownload` | Hard | Download audit log |
| `Modules\StudentProfile\Models\Student` | Hard | Student record for class_id resolution |

---

## 13. Test Scenarios Summary

**Positive:**
- Student views study resources grouped by type
- Student downloads an approved, downloadable note
- Student rates a note (1-5 stars with optional review)
- Student sees their previous rating pre-loaded

**Negative:**
- Student with no active session sees empty state
- Student tries to download non-downloadable note → 403
- Student tries to download another class's note → 403
- Student tries to rate with invalid value → 422
- Student accesses non-APPROVED note directly → 404

---

## 14. FRD Traceability

| FRD ID | Requirement | Status |
|--------|-------------|--------|
| REQ-STP-022 | Study Resources + Prescribed Books — browse, download, rate | ✅ |
| BR-STP-001 | Data ownership — student only sees own class's resources | ✅ |

---

## 15. Known Gaps / Issues

| Gap ID | Issue | Severity |
|--------|-------|----------|
| GAP-STP-N/A | No pagination on study resources — all notes fetched via `->get()`. Could be slow for many notes | Low |
| GAP-STP-N/A | No `Gate::authorize()` calls — auth is implicit via abort_unless and class_id filtering | Low |

---

## 16. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| V1 | 2026-07-23 | OpenCode | Initial requirement document |
