# slb_NoteRating — Test Case List & Business Conditions

**Module:** SyllabusBooks (CODE `SLB`, prefix `slb_`) · **Feature:** Note Ratings List (Admin Overview)
**DB scope:** TENANT-side (`slb_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary table:** `slb_notes_ratings` · **Module URL prefix:** `/syllabus-books`
**Test file:** `slb_NoteRating_TestCas.php`
**Tabs:** Note Ratings (standalone list tab, ratings are created via Note edit page)

Routes:
- `GET     /syllabus-books?tab=note-ratings` — SyllabusBooksController@index (master tabbed view)
- `GET     /syllabus-books/note-ratings` — NoteRatingController@index (redirects to master tab)
- `PUT     /syllabus-books/note-ratings/{id}` — NoteRatingController@update
- `DELETE  /syllabus-books/note-ratings/{id}` — NoteRatingController@destroy

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `slb_notes_ratings`: id, notes_id FK, user_id FK, rating (TINYINT), review (VARCHAR 500), timestamps; UNIQUE(notes_id, user_id); CHECK rating 1-5 | Migration |
| BC-DB-02 | Model `SlbNotesRating`: table `slb_notes_ratings`, fillable [notes_id, user_id, rating, review], casts rating→integer | SlbNotesRating.php |
| BC-DB-03 | Relationship: note() belongsTo SlbNote | SlbNotesRating.php:38-40 |

### BC-VAL — Validation (Source: `NoteRatingRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `notes_id` required integer exists:slb_notes,id | RatingRequest:13 |
| BC-VAL-02 | `user_id` required integer exists:sys_users,id | RatingRequest:14 |
| BC-VAL-03 | `rating` required integer min:1 max:5 | RatingRequest:15 |
| BC-VAL-04 | `review` nullable string max:500 | RatingRequest:16 |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index() gate `tenant.note-rating.viewAny` | RatingCtrl:16 |
| BC-AUTH-02 | update() gate `tenant.note-rating.update` | RatingCtrl:40 |
| BC-AUTH-03 | destroy() gate `tenant.note-rating.delete` | RatingCtrl:64 |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | index() redirects to `syllabus-books.index?tab=note-ratings` | RatingCtrl:17-19 |
| BC-BIZ-02 | Master query: filters by nr_notes_id (exact), nr_rating (exact); loads note relation; ordered by created_at DESC; paginated 15 (`nr_page`) | SyllabusBooksCtrl:116-124 |
| BC-BIZ-03 | update() validates unique(notes_id, user_id) excluding self before updating; recalculates avg_rating on both old and new note | RatingCtrl:42-60 |
| BC-BIZ-04 | destroy() soft-deletes rating, recalculates avg_rating on the note | RatingCtrl:65-73 |
| BC-BIZ-05 | recalculateAvgRating: AVG(rating) → round(2) → update SlbNote.avg_rating | RatingCtrl:83-87 |
| BC-BIZ-06 | Edit action links to note edit page (`notes.edit` with tab=notes) — not an inline edit | View:99-102 |
| BC-BIZ-07 | Delete action posts directly to note-ratings.destroy with tab=note-ratings hidden input | View:105-114 |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Non-existing id for update/destroy → 404 (findOrFail) | RatingCtrl |
| BC-EDG-02 | Empty list → "No ratings found" | View:120-122 |

---

## 2. Test Case List

### Screen 1: Index — List (GET /syllabus-books?tab=note-ratings)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NR-P10 | Positive | Ctrl | Note ratings tab renders with filters (note, rating) and results table | Page rendered | test_note_rating_10 | Automated |
| TC-NR-P11 | Positive | Ctrl | Filter by nr_notes_id (exact) narrows results | Filtered | test_note_rating_11 | Automated |
| TC-NR-P12 | Positive | Ctrl | Filter by nr_rating (1-5 exact) narrows results | Filtered | test_note_rating_12 | Automated |
| TC-NR-P13 | Positive | Ctrl | Combined filters work together | Filtered | test_note_rating_13 | Automated |
| TC-NR-P14 | Positive | Ctrl | Reset button clears all filters | Cleared | test_note_rating_14 | Automated |
| TC-NR-P15 | Positive | Ctrl | Paginated (15 per page, `nr_page` param) | Paginated | test_note_rating_15 | Automated |
| TC-NR-P16 | Positive | View | Table columns: Note title, Rating stars (★/5), Review (truncated 60), Created At, Action | All visible | test_note_rating_16 | Automated |
| TC-NR-P17 | Positive | View | Rating stars display correct filled/empty stars for value 1-5 | Stars correct | test_note_rating_17 | Automated |
| TC-NR-P18 | Positive | View | Edit button links to note edit page with tab=notes | Links to edit | test_note_rating_18 | Automated |
| TC-NR-P19 | Positive | View | Delete button with confirmation prompt | Confirm | test_note_rating_19 | Automated |
| TC-NR-P20 | Positive | View | Empty state when no ratings match filters | "No ratings found" | test_note_rating_20 | Automated |
| TC-NR-P21 | Positive | View | Review shown with ellipsis when > 60 chars, dash when null | Truncated/dash | test_note_rating_21 | Automated |

### Screen 2: Update (PUT /syllabus-books/note-ratings/{id}) — via Note edit page

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NR-P30 | Positive | Ctrl | Update rating via note edit form → rating modified, avg_rating recalculated | Updated | test_note_rating_30 | Automated |
| TC-NR-P31 | Positive | Ctrl | Update moves rating to a different note → recalculates both notes | Dual recalc | test_note_rating_31 | Planned |
| TC-NR-P32 | Positive | Ctrl | Update redirects to note edit page with success flash | Redirect | test_note_rating_32 | Automated |
| TC-NR-N33 | Negative | Ctrl | Update with rating < 1 → 422 | 422 | test_note_rating_33 | Automated |
| TC-NR-N34 | Negative | Ctrl | Update with rating > 5 → 422 | 422 | test_note_rating_34 | Automated |
| TC-NR-N35 | Negative | Ctrl | Update with review > 500 chars → 422 | 422 | test_note_rating_35 | Automated |
| TC-NR-N36 | Negative | Ctrl | Duplicate user+note (excluding self) on update → error flash | Error flash | test_note_rating_36 | Automated |

### Screen 3: Destroy (DELETE /syllabus-books/note-ratings/{id})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NR-P40 | Positive | Ctrl | Delete rating → record removed, avg_rating recalculated, redirect with flash | Deleted + recalc | test_note_rating_40 | Automated |
| TC-NR-N41 | Negative | Ctrl | Delete on non-existing id → 404 | 404 | test_note_rating_41 | Automated |

### Cross-Cutting — Schema, Auth, Tenancy

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-NR-P01 | Schema | DDL/Model | Migration, model, table, fillable, cast, unique constraint, check constraint | All pass | test_note_rating_01 | Automated |
| TC-NR-P02 | Schema | Routes | NoteRating routes registered (index, update, destroy) | All present | test_note_rating_02 | Automated |
| TC-NR-P05 | Auth | Middleware | Guest redirected to /login | /login | test_note_rating_05 | Automated |
| TC-NR-P06 | Auth | Policy | Policy permission mapping for all 3 gates | Mapped | test_note_rating_06 | Automated |
| TC-NR-P07 | Auth | Ctrl | Gate authorization present on all 3 controller methods | Gates present | test_note_rating_07 | Automated |
| TC-NR-N08 | Auth | Ctrl | User without tenant.note-rating.viewAny → 403 | 403 | test_note_rating_08 | Automated |
| TC-NR-N09 | Auth | Ctrl | User without tenant.note-rating.update → 403 on update | 403 | test_note_rating_09 | Automated |
| TC-NR-N10 | Auth | Ctrl | User without tenant.note-rating.delete → 403 on destroy | 403 | test_note_rating_10 | Automated |

---

## 3. Test Method Index

### File: `slb_NoteRating_TestCas.php` (31 methods)
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_note_rating_01_migration_model_and_schema | TC-NR-P01 | Schema | 01-04 |
| 2 | test_note_rating_02_routes_are_registered | TC-NR-P02 | Schema | 01-04 |
| 3 | test_note_rating_05_guest_redirected_to_login | TC-NR-P05 | Auth | 05-09 |
| 4 | test_note_rating_06_policy_permission_mapping_is_correct | TC-NR-P06 | Auth | 05-09 |
| 5 | test_note_rating_07_controller_gate_authorization_is_present | TC-NR-P07 | Auth | 05-09 |
| 6 | test_note_rating_08_user_without_viewAny_permission_gets_403 | TC-NR-N08 | Auth | 05-09 |
| 7 | test_note_rating_09_user_without_update_permission_gets_403 | TC-NR-N09 | Auth | 05-09 |
| 8 | test_note_rating_10_user_without_delete_permission_gets_403 | TC-NR-N10 | Auth | 05-09 |
| 9 | test_note_rating_10_tab_renders_with_filters | TC-NR-P10 | List | 10-29 |
| 10 | test_note_rating_11_filter_by_note | TC-NR-P11 | List | 10-29 |
| 11 | test_note_rating_12_filter_by_rating | TC-NR-P12 | List | 10-29 |
| 12 | test_note_rating_13_combined_filters | TC-NR-P13 | List | 10-29 |
| 13 | test_note_rating_14_reset_button_clears | TC-NR-P14 | List | 10-29 |
| 14 | test_note_rating_15_pagination_15_per_page | TC-NR-P15 | List | 10-29 |
| 15 | test_note_rating_16_table_displays_all_columns | TC-NR-P16 | List | 10-29 |
| 16 | test_note_rating_17_stars_display_correctly | TC-NR-P17 | List | 10-29 |
| 17 | test_note_rating_18_edit_links_to_note_edit | TC-NR-P18 | List | 10-29 |
| 18 | test_note_rating_19_delete_with_confirmation | TC-NR-P19 | List | 10-29 |
| 19 | test_note_rating_20_empty_state | TC-NR-P20 | List | 10-29 |
| 20 | test_note_rating_21_review_truncated_or_dash | TC-NR-P21 | List | 10-29 |
| 21 | test_note_rating_30_update_rating | TC-NR-P30 | Update | 30-39 |
| 22 | test_note_rating_31_update_change_note | TC-NR-P31 | Update | 30-39 |
| 23 | test_note_rating_32_update_redirects | TC-NR-P32 | Update | 30-39 |
| 24 | test_note_rating_33_rating_below_1_422 | TC-NR-N33 | Update | 30-39 |
| 25 | test_note_rating_34_rating_above_5_422 | TC-NR-N34 | Update | 30-39 |
| 26 | test_note_rating_35_review_exceeds_500_422 | TC-NR-N35 | Update | 30-39 |
| 27 | test_note_rating_36_duplicate_user_note_error | TC-NR-N36 | Update | 30-39 |
| 28 | test_note_rating_40_destroy_rating | TC-NR-P40 | Destroy | 40-49 |
| 29 | test_note_rating_41_destroy_non_existing_404 | TC-NR-N41 | Destroy | 40-49 |
| 30 | test_note_rating_90_records_are_tenant_scoped | TC-NR-T90 | Tenancy | 90-99 |
| 31 | test_note_rating_91_stored_xss_is_escaped | TC-NR-P91 | Security | 90-99 |

**Total: 31 methods (30 Automated, 1 Planned).**
