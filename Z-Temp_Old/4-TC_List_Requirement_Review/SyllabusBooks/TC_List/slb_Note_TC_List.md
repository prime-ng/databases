# slb_Note — Test Case List & Business Conditions

**Module:** SyllabusBooks (CODE `SLB`, prefix `slb_`) · **Feature:** Notes Master (CRUD + Approval Workflow + Trash)
**DB scope:** TENANT-side (`slb_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `slb_notes` · **Module URL prefix:** `/syllabus-books`
**Test file:** `slb_Note_TestCas.php`
**Tabs:** Notes (third CRUD tab of the Syllabus Books module)

Routes:
- `GET     /syllabus-books?tab=notes` — SyllabusBooksController@index (master tabbed view)
- `GET     /syllabus-books/notes` — NoteController@index (redirects to master tab)
- `GET     /syllabus-books/notes/create` — NoteController@create
- `POST    /syllabus-books/notes` — NoteController@store
- `GET     /syllabus-books/notes/{note}` — NoteController@show
- `GET     /syllabus-books/notes/{note}/edit` — NoteController@edit
- `PUT     /syllabus-books/notes/{note}` — NoteController@update
- `DELETE  /syllabus-books/notes/{note}` — NoteController@destroy
- `GET     /syllabus-books/notes/trash/view` — NoteController@trashedNote
- `GET     /syllabus-books/notes/{id}/restore` — NoteController@restore
- `DELETE  /syllabus-books/notes/{id}/force-delete` — NoteController@forceDelete
- `POST    /syllabus-books/notes/{note}/toggle-status` — NoteController@toggleStatus
- `GET     /syllabus-books/notes/chapters-by-book` — NoteController@getChaptersByBook (AJAX)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `slb_notes` exists with columns: id (PK AI), uuid (BINARY 16), title (VARCHAR 150 NOT NULL), description (VARCHAR 1000 NULLABLE), topic (UINT NULLABLE), notes_type (ENUM 9 values, default LECTURE_NOTES), tags (JSON NULLABLE), uploader_role (ENUM: ADMIN/STUDENT/TEACHER), status (ENUM 5 values, default PENDING_APPROVAL), approved_at (TIMESTAMP NULLABLE), rejection_reason (VARCHAR 500 NULLABLE), is_downloadable (BOOLEAN DEFAULT 1), visibility (ENUM 3 values, default CLASS_ONLY), view_count/download_count/like_count (UINT DEFAULT 0), avg_rating (DECIMAL 3,2 NULLABLE), is_active (BOOLEAN DEFAULT 1), 6 FK columns, timestamps, soft_deletes | Migration |
| BC-DB-02 | FK: class_id→sch_classes, subject_id→sch_subjects, academic_session_id→sch_org_academic_sessions_jnt, book_id→slb_books (nullable), chapter_id→slb_book_chapters (nullable), uploaded_by_user_id→sys_users, approved_by_user_id→sys_users (nullable) | Migration |
| BC-DB-03 | Indexes: idx_notes_class_subject (class_id,subject_id,session), idx_notes_uploader, idx_notes_status, idx_notes_book_chapter | Migration |
| BC-DB-04 | Model `SlbNote`: table `slb_notes`, SoftDeletes, InteractsWithMedia (MEDIA_FILE='note_file' single), auto UUID on create | SlbNote.php |
| BC-DB-05 | Fillable: 23 fields (title, description, class_id, subject_id, academic_session_id, book_id, chapter_id, topic_id, notes_type, tags, uploaded_by_user_id, uploader_role, status, approved_by_user_id, approved_at, rejection_reason, is_downloadable, visibility, view_count, download_count, like_count, avg_rating, is_active) | SlbNote.php:19-44 |
| BC-DB-06 | Casts: is_downloadable (boolean), is_active (boolean), approved_at (datetime) | SlbNote.php:46-50 |
| BC-DB-07 | Tags stored as JSON string, accessor/mutator converts between array and JSON | SlbNote.php:58-80 |
| BC-DB-08 | Table `slb_notes_downloads`: id, notes_id FK, user_id FK, downloaded_at, ip_address (VARCHAR 45), user_agent, soft_deletes | Migration |
| BC-DB-09 | Table `slb_notes_files`: id, notes_id FK, media_id FK, file_format (ENUM: PDF/DOCX/JPG/PNG/EPUB/OTHER), file_size_kb (UINT), ordinal (TINYINT DEFAULT 1), is_active (BOOLEAN DEFAULT 1), timestamps, soft_deletes | Migration |
| BC-DB-10 | Table `slb_notes_ratings`: id, notes_id FK, user_id FK, rating (TINYINT, CHECK 1-5), review (VARCHAR 500), timestamps, UNIQUE(notes_id, user_id) | Migration |
| BC-DB-11 | Relationships: schoolClass (belongsTo), subject, book, chapter, topic, files (hasMany), ratings (hasMany), downloads (hasMany) | SlbNote.php:101-136 |

### BC-VAL — Validation (Source: `NoteRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `title` required string max:150 | NoteRequest:14 |
| BC-VAL-02 | `description` nullable string max:1000 | NoteRequest:15 |
| BC-VAL-03 | `class_id` required integer exists:sch_classes,id | NoteRequest:16 |
| BC-VAL-04 | `subject_id` required integer exists:sch_subjects,id | NoteRequest:17 |
| BC-VAL-05 | `academic_session_id` required integer | NoteRequest:18 |
| BC-VAL-06 | `book_id` nullable integer exists:slb_books,id | NoteRequest:19 |
| BC-VAL-07 | `chapter_id` nullable integer exists:slb_book_chapters,id | NoteRequest:20 |
| BC-VAL-08 | `topic_id` nullable integer | NoteRequest:21 |
| BC-VAL-09 | `notes_type` required in: 9 enum values | NoteRequest:22 |
| BC-VAL-10 | `visibility` required in: CLASS_ONLY,SUBJECT_WIDE,SCHOOL_WIDE | NoteRequest:23 |
| BC-VAL-11 | `uploader_role` required in: TEACHER,STUDENT,ADMIN | NoteRequest:24 |
| BC-VAL-12 | `status` nullable in: DRAFT,PENDING_APPROVAL,APPROVED,REJECTED,ARCHIVED | NoteRequest:25 |
| BC-VAL-13 | `rejection_reason` nullable string max:500 | NoteRequest:26 |
| BC-VAL-14 | `avg_rating` nullable numeric between:0,5 | NoteRequest:27 |
| BC-VAL-15 | `is_downloadable` nullable boolean (forced via prepareForValidation) | NoteRequest:28 |
| BC-VAL-16 | `is_active` nullable boolean (forced) | NoteRequest:29 |
| BC-VAL-17 | `tags` nullable string (comma-separated → JSON array via prepareForValidation) | NoteRequest:30 |
| BC-VAL-18 | `note_file` nullable file mimes:pdf,docx,pptx,jpg,jpeg,png max:20480 KB (20MB) | NoteRequest:31 |

### BC-VAL-RATING — Validation (Source: `NoteRatingRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-R01 | `notes_id` required integer exists:slb_notes,id | RatingRequest:13 |
| BC-VAL-R02 | `user_id` required integer exists:sys_users,id | RatingRequest:14 |
| BC-VAL-R03 | `rating` required integer min:1 max:5 | RatingRequest:15 |
| BC-VAL-R04 | `review` nullable string max:500 | RatingRequest:16 |

### BC-VAL-FILE — Validation (Source: inline in `NoteFileController@store`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-F01 | `notes_id` required integer exists:slb_notes,id | FileCtrl:36 |
| BC-VAL-F02 | `note_file` required file mimes:pdf,docx,jpg,jpeg,png,epub max:20480 | FileCtrl:37 |
| BC-VAL-F03 | `ordinal` nullable integer min:1 max:255 | FileCtrl:38 |
| BC-VAL-F04 | `is_active` nullable boolean | FileCtrl:39 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `tenant.note.viewAny` | Ctrl:20 |
| BC-AUTH-02 | create()/store() gate `tenant.note.create` | Ctrl:27,51 |
| BC-AUTH-03 | show() gate `tenant.note.view` | Ctrl:102 |
| BC-AUTH-04 | edit()/update() gate `tenant.note.update` | Ctrl:110,130 |
| BC-AUTH-05 | destroy() gate `tenant.note.delete` | Ctrl:175 |
| BC-AUTH-06 | trashedNote()/restore() gate `tenant.note.restore` | Ctrl:191,183 |
| BC-AUTH-07 | forceDelete() gate `tenant.note.forceDelete` | Ctrl:199 |
| BC-AUTH-08 | toggleStatus() gate `tenant.note.update` | Ctrl:226 |
| BC-AUTH-09 | getChaptersByBook() gate `tenant.note.viewAny` | Ctrl:238 |
| BC-AUTH-10 | Student upload blocked when config `allow_student_notes_upload`=false → 403 | Ctrl:55-57 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() redirects to `syllabus-books.index?tab=notes` | Ctrl:21-23 |
| BC-BIZ-02 | Master query: filter by note_search (title LIKE), note_type (exact), note_class (class_id exact), note_status (status exact); paginated 10 (`notes_page`); load relationships (schoolClass, subject, book, chapter, uploader); withCount(ratings) | SyllabusBooksCtrl |
| BC-BIZ-03 | create() loads: classes, subjects, sessions, active books, active topics, current session | Ctrl:28-43 |
| BC-BIZ-04 | store() checks config for student/teacher approval requirement; sets status accordingly (PENDING_APPROVAL or APPROVED) | Ctrl:59-65 |
| BC-BIZ-05 | store() in transaction creates SlbNote with uploaded_by_user_id and uploader_role; logs 'Created' activity | Ctrl:67-77,84 |
| BC-BIZ-06 | store() attaches note file via media library if provided | Ctrl:79-82 |
| BC-BIZ-07 | store() redirects to notes tab with success flash | Ctrl:86-88 |
| BC-BIZ-08 | update() handles approval workflow: when status→APPROVED sets approved_by_user_id+approved_at; when REJECTED clears them | Ctrl:138-148 |
| BC-BIZ-09 | update() replaces note file (clears old collection, adds new) | Ctrl:150-153 |
| BC-BIZ-10 | update() logs 'Updated', redirects with flash | Ctrl:155-158 |
| BC-BIZ-11 | destroy(): sets is_active=false, calls delete(), logs 'Trashed' | Ctrl:177-183 |
| BC-BIZ-12 | restore(): withTrashed findOrFail, restore(), redirects to trashed | Ctrl:186-191 |
| BC-BIZ-13 | forceDelete(): deletes ratings, downloads, note files media, clear note media, forceDelete; all in transaction | Ctrl:200-219 |
| BC-BIZ-14 | toggleStatus(): flips is_active, returns JSON `{success, is_active}` | Ctrl:227-234 |
| BC-BIZ-15 | getChaptersByBook(): AJAX returns active chapters for a book ordered by chapter_no | Ctrl:239-247 |
| BC-BIZ-16 | Rating uses updateOrCreate(notes_id, user_id), recalculates avg_rating on SlbNote after each change | RatingCtrl:26-34 |
| BC-BIZ-17 | Rating recalculate: avg of all ratings → round(2) → stored on SlbNote.avg_rating | RatingCtrl:64-68 |
| BC-BIZ-18 | prepareForValidation: tags comma-separated → JSON array; booleans forced | NoteRequest:36-45 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for show/edit/update/destroy → 404 (findOrFail) | Ctrl |
| BC-EDG-02 | WithTrashed for restore/forceDelete → 404 if not in trash | Ctrl:188,201 |
| BC-EDG-03 | title > 150 chars → rejected (max:150) | BC-VAL-01 |
| BC-EDG-04 | description > 1000 chars → rejected (max:1000) | BC-VAL-02 |
| BC-EDG-05 | class_id invalid FK → rejected | BC-VAL-03 |
| BC-EDG-06 | subject_id invalid FK → rejected | BC-VAL-04 |
| BC-EDG-07 | book_id invalid FK → rejected | BC-VAL-06 |
| BC-EDG-08 | chapter_id invalid FK → rejected | BC-VAL-07 |
| BC-EDG-09 | notes_type invalid → rejected (in list) | BC-VAL-09 |
| BC-EDG-10 | visibility invalid → rejected | BC-VAL-10 |
| BC-EDG-11 | uploader_role invalid → rejected | BC-VAL-11 |
| BC-EDG-12 | status invalid → rejected | BC-VAL-12 |
| BC-EDG-13 | note_file > 20MB → rejected (max:20480) | BC-VAL-18 |
| BC-EDG-14 | note_file invalid mime → rejected | BC-VAL-18 |
| BC-EDG-15 | Student upload when config disallows → 403 | BC-AUTH-10 |
| BC-EDG-16 | Empty search result → empty state on notes tab | View |
| BC-EDG-17 | Tags empty/null → stored as null in DB | NoteRequest:36-42 |
| BC-EDG-18 | Soft-deleted note not visible in active list (onlyTrashed scope) | Ctrl:191 |
| BC-EDG-19 | Unique(notes_id, user_id) on ratings prevents duplicate rating per user | Migration |
| BC-EDG-20 | Rating check constraint enforces 1-5 range | Migration |

---

## 2. Test Case List

### Screen 1: Notes Index — List (GET /syllabus-books?tab=notes)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P10 | Positive | Ctrl | Notes tab renders with filters (search, type, class, status) and results table | Page rendered | test_note_10 | Automated |
| TC-NT-P11 | Positive | Ctrl | Filter by note_search (title LIKE) filters results | Filtered | test_note_11 | Automated |
| TC-NT-P12 | Positive | Ctrl | Filter by note_type (exact) narrows results | Filtered | test_note_12 | Automated |
| TC-NT-P13 | Positive | Ctrl | Filter by note_class (class_id exact) narrows results | Filtered | test_note_13 | Automated |
| TC-NT-P14 | Positive | Ctrl | Filter by note_status (status exact) narrows results | Filtered | test_note_14 | Automated |
| TC-NT-P15 | Positive | Ctrl | Combined filters work together | Filtered | test_note_15 | Automated |
| TC-NT-P16 | Positive | Ctrl | Reset button clears all filters | Cleared | test_note_16 | Automated |
| TC-NT-P17 | Positive | Ctrl | Paginated (10 per page, `notes_page` param) | Paginated | test_note_17 | Automated |
| TC-NT-P18 | Positive | View | Table columns: Title, Type, Class/Subject, Uploaded By, Status badge, Avg Rating stars, Downloadable icon, Active toggle, Action buttons | All visible | test_note_18 | Automated |
| TC-NT-P19 | Positive | View | Status toggle per row | Toggle present | test_note_19 | Automated |
| TC-NT-P20 | Positive | View | Action buttons: View, Edit, Delete (permission-gated) | 3 buttons | test_note_20 | Automated |
| TC-NT-P21 | Positive | View | Empty state when no notes match filters | Empty state | test_note_21 | Automated |
| TC-NT-P22 | Positive | JSON | AJAX getChaptersByBook returns chapters for selected book | JSON list | test_note_22 | Automated |

### Screen 2: Create Form (GET /syllabus-books/notes/create)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P30 | Positive | View | Create page renders: title, description, class, subject, session, book, chapter, topic dropdowns, notes_type, uploader_role, visibility, status, tags, is_downloadable, is_active checkboxes, note_file upload | All fields visible | test_note_30 | Automated |
| TC-NT-P31 | Positive | View | Book-to-chapter cascade: selecting a book loads chapters via AJAX | Cascade works | test_note_31 | Automated |

### Screen 3: Store (POST /syllabus-books/notes)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P40 | Positive | Ctrl | Valid store creates note with required fields (title, class_id, subject_id, session, notes_type, uploader_role, visibility) | Created | test_note_40 | Automated |
| TC-NT-P41 | Positive | Ctrl | Store with all optional fields (description, book, chapter, topic, tags, rejection_reason, avg_rating) | Created full | test_note_41 | Automated |
| TC-NT-P42 | Positive | Ctrl | Store with note_file upload → media created | File attached | test_note_42 | Automated |
| TC-NT-P43 | Positive | Ctrl | Status auto-set to APPROVED when no approval required (default config) | Status APPROVED | test_note_43 | Automated |
| TC-NT-P44 | Positive | Ctrl | Status auto-set to PENDING_APPROVAL when student_notes_require_approval=true | Status PENDING_APPROVAL | test_note_44 | Automated |
| TC-NT-P45 | Positive | Ctrl | is_downloadable/is_active forced boolean by prepareForValidation | Correct booleans | test_note_45 | Automated |
| TC-NT-P46 | Positive | Ctrl | Tags submitted as CSV string → stored as JSON array | Tags stored | test_note_46 | Automated |
| TC-NT-P47 | Positive | Ctrl | Store sets uploaded_by_user_id to current auth user | Uploader set | test_note_47 | Automated |
| TC-NT-P48 | Positive | Ctrl | UUID auto-generated on create | UUID set | test_note_48 | Automated |
| TC-NT-P49 | Positive | Ctrl | Store writes 'Created' activity log | Log entry | test_note_49 | Automated |
| TC-NT-P50 | Positive | Ctrl | Store redirects to notes tab with success flash | Redirect + flash | test_note_50 | Automated |
| TC-NT-P51 | Positive | Ctrl | Nullable fields omitted → stored as NULL | NULL stored | test_note_51 | Automated |
| TC-NT-N60 | Negative | Ctrl | title empty → 422 | 422 | test_note_60 | Automated |
| TC-NT-N61 | Negative | Ctrl | title exceeds 150 chars → 422 | 422 | test_note_61 | Automated |
| TC-NT-N62 | Negative | Ctrl | class_id empty → 422 | 422 | test_note_62 | Automated |
| TC-NT-N63 | Negative | Ctrl | class_id invalid FK → 422 | 422 | test_note_63 | Automated |
| TC-NT-N64 | Negative | Ctrl | subject_id empty → 422 | 422 | test_note_64 | Automated |
| TC-NT-N65 | Negative | Ctrl | subject_id invalid FK → 422 | 422 | test_note_65 | Automated |
| TC-NT-N66 | Negative | Ctrl | academic_session_id empty → 422 | 422 | test_note_66 | Automated |
| TC-NT-N67 | Negative | Ctrl | notes_type invalid → 422 | 422 | test_note_67 | Automated |
| TC-NT-N68 | Negative | Ctrl | uploader_role invalid → 422 | 422 | test_note_68 | Automated |
| TC-NT-N69 | Negative | Ctrl | visibility invalid → 422 | 422 | test_note_69 | Automated |
| TC-NT-N70 | Negative | Ctrl | description exceeds 1000 chars → 422 | 422 | test_note_70 | Automated |
| TC-NT-N71 | Negative | Ctrl | book_id invalid FK → 422 | 422 | test_note_71 | Automated |
| TC-NT-N72 | Negative | Ctrl | chapter_id invalid FK → 422 | 422 | test_note_72 | Automated |
| TC-NT-N73 | Negative | Ctrl | status invalid → 422 (not in allowed list) | 422 | test_note_73 | Automated |
| TC-NT-N74 | Negative | Ctrl | rejection_reason > 500 chars → 422 | 422 | test_note_74 | Automated |
| TC-NT-N75 | Negative | Ctrl | note_file > 20MB → 422 | 422 | test_note_75 | Automated |
| TC-NT-N76 | Negative | Ctrl | note_file invalid mime (e.g. .exe) → 422 | 422 | test_note_76 | Automated |
| TC-NT-N77 | Negative | Ctrl | Student upload when config disallows → 403 | 403 | test_note_77 | Automated |

### Screen 4: Show (GET /syllabus-books/notes/{note})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P80 | Positive | View | Show page displays: title, description, type, class/subject, session, book/chapter, topic, uploader, status badge, visibility, tags, is_downloadable, avg_rating, view/download/like counts, created_at, updated_at | All fields shown | test_note_80 | Automated |
| TC-NT-P81 | Positive | View | Show page lists related files with download links | Files listed | test_note_81 | Automated |
| TC-NT-P82 | Positive | View | Show page lists ratings with user and review | Ratings listed | test_note_82 | Automated |
| TC-NT-P83 | Positive | View | Status-dependent UI: PENDING_APPROVAL shows pending badge, APPROVED shows approved badge, REJECTED shows rejected badge | Status badges | test_note_83 | Automated |
| TC-NT-N84 | Negative | Ctrl | Invalid id → 404 | 404 | test_note_84 | Automated |
| TC-NT-N85 | Negative | Ctrl | Soft-deleted id → 404 | 404 | test_note_85 | Automated |

### Screen 5: Edit (GET /syllabus-books/notes/{note}/edit)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P90 | Positive | View | Edit page pre-fills all fields with existing values | All pre-filled | test_note_90 | Automated |
| TC-NT-P91 | Positive | View | Book/chapter cascade: pre-selected book loads chapters | Chapters loaded | test_note_91 | Automated |
| TC-NT-P92 | Positive | View | Existing file preview shown and replaceable | File preview | test_note_92 | Automated |
| TC-NT-P93 | Positive | View | Status dropdown shows current status selected | Status selected | test_note_93 | Automated |
| TC-NT-P94 | Positive | View | When status=APPROVED, approved_by and approved_at shown | Approval info | test_note_94 | Automated |
| TC-NT-N95 | Negative | Ctrl | Invalid id → 404 | 404 | test_note_95 | Automated |

### Screen 6: Update (PUT /syllabus-books/notes/{note})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P100 | Positive | Ctrl | Update modifies basic fields and logs 'Updated' | Updated + log | test_note_100 | Automated |
| TC-NT-P101 | Positive | Ctrl | Update changes class/subject/session/book/chapter | Relations updated | test_note_101 | Automated |
| TC-NT-P102 | Positive | Ctrl | Update changes notes_type, visibility, uploader_role | Enums updated | test_note_102 | Automated |
| TC-NT-P103 | Positive | Ctrl | Update status to APPROVED → approved_by_user_id and approved_at set | Approval recorded | test_note_103 | Automated |
| TC-NT-P104 | Positive | Ctrl | Update status to REJECTED → approved_by fields cleared | Cleared | test_note_104 | Automated |
| TC-NT-P105 | Positive | Ctrl | Update replaces note file (clear old, add new) | File replaced | test_note_105 | Automated |
| TC-NT-P106 | Positive | Ctrl | Update redirects to notes tab with success flash | Redirect + flash | test_note_106 | Automated |
| TC-NT-N107 | Negative | Ctrl | Same validation rules apply on update as create | As create | test_note_107 | Automated |

### Screen 7: Destroy (DELETE /syllabus-books/notes/{note})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P110 | Positive | Ctrl | Destroy soft-deletes and sets is_active=false | Soft-deleted | test_note_110 | Automated |
| TC-NT-P111 | Positive | Ctrl | Destroy logs 'Trashed' activity | Log entry | test_note_111 | Automated |
| TC-NT-P112 | Positive | Ctrl | Destroy redirects with success flash | Redirect + flash | test_note_112 | Automated |
| TC-NT-N113 | Negative | Ctrl | Destroy on non-existing id → 404 | 404 | test_note_113 | Automated |

### Screen 8: Trash (GET /syllabus-books/notes/trash/view)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P120 | Positive | View | Trash page lists soft-deleted notes with class/subject info | Listed | test_note_120 | Automated |
| TC-NT-P121 | Positive | View | Each trashed row has Restore and Force Delete action buttons | 2 buttons | test_note_121 | Automated |
| TC-NT-P122 | Positive | View | Trash paginated (10 per page) | Paginated | test_note_122 | Planned |

### Screen 9: Restore (GET /syllabus-books/notes/{id}/restore)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P130 | Positive | Ctrl | Restore recovers record, redirects to trashed with flash | Restored | test_note_130 | Automated |
| TC-NT-N131 | Negative | Ctrl | Restore on non-trashed/non-existing id → 404 | 404 | test_note_131 | Automated |

### Screen 10: Force Delete (DELETE /syllabus-books/notes/{id}/force-delete)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P140 | Positive | Ctrl | Force delete removes note, deletes ratings/downloads/files media, clears note media, logs 'Deleted' | Removed + log | test_note_140 | Automated |
| TC-NT-P141 | Positive | Ctrl | Force delete redirects to trashed with success flash | Redirect + flash | test_note_141 | Automated |
| TC-NT-N142 | Negative | Ctrl | Force delete on non-trashed id → 404 | 404 | test_note_142 | Automated |

### Screen 11: Toggle Status (POST /syllabus-books/notes/{note}/toggle-status)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P150 | Positive | Ctrl | Toggle active → inactive | is_active=false | test_note_150 | Automated |
| TC-NT-P151 | Positive | Ctrl | Toggle inactive → active | is_active=true | test_note_151 | Automated |
| TC-NT-P152 | Positive | Ctrl | Toggle returns JSON `{success, is_active}` | JSON response | test_note_152 | Automated |

### Screen 12: Note Files (Sub-feature tab=note-files)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P160 | Positive | Ctrl | Store note file with valid data creates SlbNotesFile + media | Created | test_note_160 | Automated |
| TC-NT-N161 | Negative | Ctrl | Store note file without file → 422 | 422 | test_note_161 | Automated |
| TC-NT-N162 | Negative | Ctrl | Store note file invalid mime → 422 | 422 | test_note_162 | Automated |
| TC-NT-N163 | Negative | Ctrl | Store note file > 20MB → 422 | 422 | test_note_163 | Automated |
| TC-NT-N164 | Negative | Ctrl | Store note file with invalid notes_id → 422 | 422 | test_note_164 | Automated |
| TC-NT-P165 | Positive | Ctrl | Destroy note file soft-deletes and clears media | Trashed | test_note_165 | Automated |
| TC-NT-P166 | Positive | Ctrl | Toggle note file status via AJAX | Toggled | test_note_166 | Automated |

### Screen 13: Note Ratings (Sub-feature)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P170 | Positive | Ctrl | Create rating (updateOrCreate) for a note → rating saved, avg_rating recalculated | Rating saved | test_note_170 | Automated |
| TC-NT-P171 | Positive | Ctrl | Update existing rating (same user+note) → upsert updates | Updated | test_note_171 | Automated |
| TC-NT-P172 | Positive | Ctrl | Delete rating → re-calculates avg_rating | Deleted | test_note_172 | Automated |
| TC-NT-N173 | Negative | Ctrl | rating < 1 → 422 | 422 | test_note_173 | Automated |
| TC-NT-N174 | Negative | Ctrl | rating > 5 → 422 | 422 | test_note_174 | Automated |
| TC-NT-N175 | Negative | Ctrl | review > 500 chars → 422 | 422 | test_note_175 | Automated |
| TC-NT-N176 | Negative | Ctrl | notes_id invalid → 422 | 422 | test_note_176 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy, Security

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NT-P01 | Schema | DDL/Model | Migration, model, table, fillable, casts, SoftDeletes, MediaLibrary, JSON tags, UUID | All pass | test_note_01 | Automated |
| TC-NT-P02 | Schema | Routes | All note routes registered (resource + extra: 13 total) | All present | test_note_02 | Automated |
| TC-NT-P03 | Schema | Tables | slb_notes_downloads, slb_notes_files, slb_notes_ratings exist with correct FKs | Present | test_note_03 | Automated |
| TC-NT-P05 | Auth | Middleware | Guest redirected to /login | /login | test_note_05 | Automated |
| TC-NT-P06 | Auth | Policy | Policy permission mapping correct for all 7 gates | Mapped | test_note_06 | Automated |
| TC-NT-P07 | Auth | Ctrl | Controller gate authorization present on all 11 controller methods | Gates present | test_note_07 | Automated |
| TC-NT-N08 | Auth | Ctrl | User without tenant.note.viewAny → 403 on index | 403 | test_note_08 | Automated |
| TC-NT-N09 | Auth | Ctrl | User without tenant.note.create → 403 on create/store | 403 | test_note_09 | Automated |
| TC-NT-N10 | Auth | Ctrl | User without tenant.note.view → 403 on show | 403 | test_note_10 | Automated |
| TC-NT-N11 | Auth | Ctrl | User without tenant.note.update → 403 on edit/update/toggleStatus | 403 | test_note_11 | Automated |
| TC-NT-N12 | Auth | Ctrl | User without tenant.note.delete → 403 on destroy | 403 | test_note_12 | Automated |
| TC-NT-N13 | Auth | Ctrl | User without tenant.note.restore → 403 on trashed/restore | 403 | test_note_13 | Automated |
| TC-NT-N14 | Auth | Ctrl | User without tenant.note.forceDelete → 403 on forceDelete | 403 | test_note_14 | Automated |
| TC-NT-T90 | Tenancy | Tenant | Note records scoped to current tenant | Scoped | test_note_90 | Automated |
| TC-NT-P91 | Security | View | Stored XSS in title/description escaped on render | Escaped | test_note_91 | Automated |

---

## 3. Test Method Index

### File: `slb_Note_TestCas.php` (134 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_note_01_migration_model_and_schema | TC-NT-P01 | Schema | 01-04 |
| 2 | test_note_02_all_routes_are_registered | TC-NT-P02 | Schema | 01-04 |
| 3 | test_note_03_related_tables_exist | TC-NT-P03 | Schema | 01-04 |
| 4 | test_note_05_guest_redirected_to_login | TC-NT-P05 | Auth | 05-09 |
| 5 | test_note_06_policy_permission_mapping_is_correct | TC-NT-P06 | Auth | 05-09 |
| 6 | test_note_07_controller_gate_authorization_is_present | TC-NT-P07 | Auth | 05-09 |
| 7 | test_note_08_user_without_viewAny_permission_gets_403 | TC-NT-N08 | Auth | 05-09 |
| 8 | test_note_09_user_without_create_permission_gets_403 | TC-NT-N09 | Auth | 05-09 |
| 9 | test_note_10_user_without_view_permission_gets_403 | TC-NT-N10 | Auth | 05-09 |
| 10 | test_note_11_user_without_update_permission_gets_403 | TC-NT-N11 | Auth | 05-09 |
| 11 | test_note_12_user_without_delete_permission_gets_403 | TC-NT-N12 | Auth | 05-09 |
| 12 | test_note_13_user_without_restore_permission_gets_403 | TC-NT-N13 | Auth | 05-09 |
| 13 | test_note_14_user_without_forceDelete_permission_gets_403 | TC-NT-N14 | Auth | 05-09 |
| 14 | test_note_10_notes_tab_renders_with_filters | TC-NT-P10 | List | 10-29 |
| 15 | test_note_11_search_by_title | TC-NT-P11 | List | 10-29 |
| 16 | test_note_12_filter_by_note_type | TC-NT-P12 | List | 10-29 |
| 17 | test_note_13_filter_by_class | TC-NT-P13 | List | 10-29 |
| 18 | test_note_14_filter_by_status | TC-NT-P14 | List | 10-29 |
| 19 | test_note_15_combined_filters | TC-NT-P15 | List | 10-29 |
| 20 | test_note_16_reset_button_clears_filters | TC-NT-P16 | List | 10-29 |
| 21 | test_note_17_pagination_10_per_page | TC-NT-P17 | List | 10-29 |
| 22 | test_note_18_table_displays_all_columns | TC-NT-P18 | List | 10-29 |
| 23 | test_note_19_status_toggle_per_row | TC-NT-P19 | List | 10-29 |
| 24 | test_note_20_action_buttons_per_row | TC-NT-P20 | List | 10-29 |
| 25 | test_note_21_empty_state | TC-NT-P21 | List | 10-29 |
| 26 | test_note_22_ajax_get_chapters_by_book | TC-NT-P22 | List | 10-29 |
| 27 | test_note_30_create_page_renders_all_fields | TC-NT-P30 | Create | 30-39 |
| 28 | test_note_31_book_to_chapter_cascade | TC-NT-P31 | Create | 30-39 |
| 29 | test_note_40_store_basic_note | TC-NT-P40 | Store | 40-59 |
| 30 | test_note_41_store_with_all_optional_fields | TC-NT-P41 | Store | 40-59 |
| 31 | test_note_42_store_with_file_upload | TC-NT-P42 | Store | 40-59 |
| 32 | test_note_43_status_auto_approved | TC-NT-P43 | Store | 40-59 |
| 33 | test_note_44_status_pending_approval_when_required | TC-NT-P44 | Store | 40-59 |
| 34 | test_note_45_booleans_forced_correctly | TC-NT-P45 | Store | 40-59 |
| 35 | test_note_46_tags_stored_as_json | TC-NT-P46 | Store | 40-59 |
| 36 | test_note_47_uploader_set_to_current_user | TC-NT-P47 | Store | 40-59 |
| 37 | test_note_48_uuid_auto_generated | TC-NT-P48 | Store | 40-59 |
| 38 | test_note_49_store_logs_created_activity | TC-NT-P49 | Store | 40-59 |
| 39 | test_note_50_store_redirects_with_success | TC-NT-P50 | Store | 40-59 |
| 40 | test_note_51_nullable_fields_stored_as_null | TC-NT-P51 | Store | 40-59 |
| 41 | test_note_60_title_required | TC-NT-N60 | Val | 60-79 |
| 42 | test_note_61_title_max_length | TC-NT-N61 | Val | 60-79 |
| 43 | test_note_62_class_id_required | TC-NT-N62 | Val | 60-79 |
| 44 | test_note_63_class_id_invalid_fk | TC-NT-N63 | Val | 60-79 |
| 45 | test_note_64_subject_id_required | TC-NT-N64 | Val | 60-79 |
| 46 | test_note_65_subject_id_invalid_fk | TC-NT-N65 | Val | 60-79 |
| 47 | test_note_66_academic_session_required | TC-NT-N66 | Val | 60-79 |
| 48 | test_note_67_notes_type_invalid | TC-NT-N67 | Val | 60-79 |
| 49 | test_note_68_uploader_role_invalid | TC-NT-N68 | Val | 60-79 |
| 50 | test_note_69_visibility_invalid | TC-NT-N69 | Val | 60-79 |
| 51 | test_note_70_description_exceeds_1000 | TC-NT-N70 | Val | 60-79 |
| 52 | test_note_71_book_id_invalid_fk | TC-NT-N71 | Val | 60-79 |
| 53 | test_note_72_chapter_id_invalid_fk | TC-NT-N72 | Val | 60-79 |
| 54 | test_note_73_status_invalid | TC-NT-N73 | Val | 60-79 |
| 55 | test_note_74_rejection_reason_exceeds_500 | TC-NT-N74 | Val | 60-79 |
| 56 | test_note_75_note_file_exceeds_20mb | TC-NT-N75 | Val | 60-79 |
| 57 | test_note_76_note_file_invalid_mime | TC-NT-N76 | Val | 60-79 |
| 58 | test_note_77_student_upload_blocked_by_config | TC-NT-N77 | Val | 60-79 |
| 59 | test_note_80_show_displays_all_fields | TC-NT-P80 | Show | 80-89 |
| 60 | test_note_81_show_lists_files | TC-NT-P81 | Show | 80-89 |
| 61 | test_note_82_show_lists_ratings | TC-NT-P82 | Show | 80-89 |
| 62 | test_note_83_show_status_badges | TC-NT-P83 | Show | 80-89 |
| 63 | test_note_84_show_invalid_id_404 | TC-NT-N84 | Show | 80-89 |
| 64 | test_note_85_show_soft_deleted_404 | TC-NT-N85 | Show | 80-89 |
| 65 | test_note_90_edit_prefills_all_fields | TC-NT-P90 | Edit | 90-99 |
| 66 | test_note_91_edit_book_chapter_cascade | TC-NT-P91 | Edit | 90-99 |
| 67 | test_note_92_edit_file_preview | TC-NT-P92 | Edit | 90-99 |
| 68 | test_note_93_edit_status_selected | TC-NT-P93 | Edit | 90-99 |
| 69 | test_note_94_edit_approval_info_shown | TC-NT-P94 | Edit | 90-99 |
| 70 | test_note_95_edit_invalid_id_404 | TC-NT-N95 | Edit | 90-99 |
| 71 | test_note_100_update_modifies_and_logs | TC-NT-P100 | Update | 100-109 |
| 72 | test_note_101_update_relations | TC-NT-P101 | Update | 100-109 |
| 73 | test_note_102_update_enums | TC-NT-P102 | Update | 100-109 |
| 74 | test_note_103_update_approval_workflow | TC-NT-P103 | Update | 100-109 |
| 75 | test_note_104_update_rejection_clears_approval | TC-NT-P104 | Update | 100-109 |
| 76 | test_note_105_update_replaces_file | TC-NT-P105 | Update | 100-109 |
| 77 | test_note_106_update_redirects_with_success | TC-NT-P106 | Update | 100-109 |
| 78 | test_note_107_update_same_validation_as_create | TC-NT-N107 | Update | 100-109 |
| 79 | test_note_110_destroy_soft_deletes | TC-NT-P110 | Destroy | 110-119 |
| 80 | test_note_111_destroy_logs_trashed | TC-NT-P111 | Destroy | 110-119 |
| 81 | test_note_112_destroy_redirects_with_success | TC-NT-P112 | Destroy | 110-119 |
| 82 | test_note_113_destroy_non_existing_404 | TC-NT-N113 | Destroy | 110-119 |
| 83 | test_note_120_trash_lists_soft_deleted | TC-NT-P120 | Trash | 120-129 |
| 84 | test_note_121_trash_restore_force_delete_buttons | TC-NT-P121 | Trash | 120-129 |
| 85 | test_note_122_trash_paginated | TC-NT-P122 | Trash | 120-129 |
| 86 | test_note_130_restore_recovers | TC-NT-P130 | Restore | 130-139 |
| 87 | test_note_131_restore_non_trashed_404 | TC-NT-N131 | Restore | 130-139 |
| 88 | test_note_140_force_delete_permanently_removes | TC-NT-P140 | ForceDel | 140-149 |
| 89 | test_note_141_force_delete_redirects | TC-NT-P141 | ForceDel | 140-149 |
| 90 | test_note_142_force_delete_non_trashed_404 | TC-NT-N142 | ForceDel | 140-149 |
| 91 | test_note_150_toggle_active_to_inactive | TC-NT-P150 | Toggle | 150-159 |
| 92 | test_note_151_toggle_inactive_to_active | TC-NT-P151 | Toggle | 150-159 |
| 93 | test_note_152_toggle_returns_json | TC-NT-P152 | Toggle | 150-159 |
| 94 | test_note_160_store_note_file | TC-NT-P160 | File | 160-169 |
| 95 | test_note_161_store_note_file_without_file_422 | TC-NT-N161 | File | 160-169 |
| 96 | test_note_162_store_note_file_invalid_mime_422 | TC-NT-N162 | File | 160-169 |
| 97 | test_note_163_store_note_file_exceeds_20mb_422 | TC-NT-N163 | File | 160-169 |
| 98 | test_note_164_store_note_file_invalid_notes_id_422 | TC-NT-N164 | File | 160-169 |
| 99 | test_note_165_destroy_note_file | TC-NT-P165 | File | 160-169 |
| 100 | test_note_166_toggle_note_file_status | TC-NT-P166 | File | 160-169 |
| 101 | test_note_170_create_rating | TC-NT-P170 | Rating | 170-179 |
| 102 | test_note_171_update_existing_rating | TC-NT-P171 | Rating | 170-179 |
| 103 | test_note_172_delete_rating | TC-NT-P172 | Rating | 170-179 |
| 104 | test_note_173_rating_below_1_422 | TC-NT-N173 | Rating | 170-179 |
| 105 | test_note_174_rating_above_5_422 | TC-NT-N174 | Rating | 170-179 |
| 106 | test_note_175_review_exceeds_500_422 | TC-NT-N175 | Rating | 170-179 |
| 107 | test_note_176_rating_invalid_notes_id_422 | TC-NT-N176 | Rating | 170-179 |
| 108 | test_note_90_records_are_tenant_scoped | TC-NT-T90 | Tenancy | 90-99 |
| 109 | test_note_91_stored_xss_is_escaped | TC-NT-P91 | Security | 90-99 |

**Total: 109 methods (107 Automated, 2 Planned).**
