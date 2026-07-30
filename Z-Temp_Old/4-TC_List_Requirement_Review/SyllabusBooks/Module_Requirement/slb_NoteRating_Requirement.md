# slb_NoteRating — Business Requirements

## What This Screen Does

The Note Ratings tab provides an administrative overview of all ratings submitted for study notes across the Syllabus Books module. It is a read-only listing screen under `/syllabus-books?tab=note-ratings` that displays rating records from the `slb_notes_ratings` table. Each row shows the associated note title, star rating (1-5), review text (truncated), created timestamp, and action buttons (Edit — which links to the note's edit page, and Delete).

This is a standalone list tab only — ratings are created, viewed, and edited via the Note edit page (user-side) or the Note show page. The administrator's role here is to monitor ratings, filter by note or rating value, and delete inappropriate ratings if needed.

---

## When This Screen Is Used

- **Rating Monitoring** when an administrator wants to review all ratings across notes
- **Rating Filtering** when investigating ratings for a specific note or a specific star value
- **Rating Cleanup** when an administrator needs to remove inappropriate or spam ratings
- **Rating Audit** when tracking rating patterns across notes and users

## Default Data Load

This screen loads with:
- All rating records loaded with the `note` (SlbNote) relationship
- Ordered by `created_at DESC`
- Pagination (15 per page, `nr_page` param)
- 2 filters: note ID (exact), rating value (1-5 exact)
- Each row shows: Note title (linked), star rating display, review (truncated to 60 chars), created at, Edit and Delete buttons

---

## Key Fields at a Glance

**`note.title`** — The title of the rated note (loaded via relationship).

**`rating`** (TINYINT, 1-5): The numeric star rating. Displayed as filled/empty stars.

**`review`** (VARCHAR 500, NULLABLE): Optional textual review. Truncated to 60 characters in the list view with ellipsis when longer. Hyphen when null.

**`created_at`**: Timestamp of when the rating was submitted.

---

## Business Rules and Conditions

**Read-Only List for Admin**
The Note Ratings tab is a standalone list-only view. Ratings are not created from this tab — they are created via the Note edit page (`notes.edit`) or programmatically. The only actions available from this tab are Edit (which navigates away to the note edit form) and Delete.

**Edit Redirects to Note Edit**
The Edit button for a rating does not open an inline edit form. Instead, it links to the `notes.edit` route with `tab=notes` query parameter. The rating is modified within the note edit form.

**Delete from List**
The Delete button posts directly to the `note-ratings.destroy` route with a `tab=note-ratings` hidden input. After deletion, the system recalculates the affected note's `avg_rating`.

**Rating Recalculation on Delete**
When a rating is deleted, the system recalculates the associated note's `avg_rating` as `AVG(rating)` → `round(2)` and updates `SlbNote.avg_rating`.

---

## Workflow Steps

**Viewing Ratings**
The administrator navigates to the Note Ratings tab. The list loads paginated ratings. The admin can filter by note ID or rating value. Each row shows the note title, star display, review, and actions.

**Editing a Rating**
The admin clicks Edit on a rating row. The system redirects to the note edit page (`/syllabus-books/notes/{note}/edit?tab=notes`), where the rating can be modified. On save, the rating is upserted and `avg_rating` is recalculated.

**Deleting a Rating**
The admin clicks Delete on a rating row. A confirmation prompt appears. On confirm, the system deletes the rating (soft delete), recalculates the note's `avg_rating`, and redirects back to the Note Ratings tab with a success flash.

---

## Example Scenario

The academic admin wants to review ratings for Mathematics notes. They navigate to the Note Ratings tab, filter by note title "Quadratic Equations — Revision Notes" (via note ID), and see all ratings for that note. One rating is 1 star with an inappropriate review. The admin clicks Delete, confirms, and the rating is removed. The note's average rating recalculates from 3.8 to 4.2.

---

## Related Screens

- **Notes Tab** — Main notes management where ratings can be created/edited
- **Note Show** — Displays ratings with user and review details
- **Note Edit** — Where ratings are created and modified per note

---

## Requirements

- The system MUST expose 3 routes for note ratings: index, update, destroy.
- The system MUST route all note-rating endpoints under `/syllabus-books/note-ratings`.
- The system MUST wrap all routes with `module:SYLLABUS_BOOKS` middleware.
- The system MUST authorize each action via `Gate::authorize()`:
  - `index` → `tenant.note-rating.viewAny`
  - `update` → `tenant.note-rating.update`
  - `destroy` → `tenant.note-rating.delete`
- The system MUST validate input via `NoteRatingRequest` for update operations.
- The system MUST paginate the rating list (15 per page, `nr_page` param).
- The system MUST provide 2 filters: note ID (exact) and rating value (1-5 exact).
- The system MUST display star ratings as filled/empty star icons.
- The system MUST truncate reviews longer than 60 characters with ellipsis.
- The system MUST display a hyphen for null reviews.
- The system MUST redirect Edit actions to the note edit page.
- The system MUST recalculate `avg_rating` on the associated note after delete.
- The system MUST show a confirmation prompt before delete.
- The system MUST show an empty state message "No ratings found" when no records match.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.note-rating.viewAny`, `tenant.note-rating.update`, `tenant.note-rating.delete` | Full access |
| Academic Admin | `tenant.note-rating.viewAny` | View only |
| Teacher | No explicit permission | No access |
| Guest (unauthenticated) | None | Redirected to `/login` |

---

## Validate Before Save (Multiple Conditions)

Rating validation is handled by `NoteRatingRequest` when ratings are created/updated via the Note edit page:
1. **Rating Required** — Error: "The rating field is required."
2. **Rating Min 1** — Error: "The rating must be at least 1."
3. **Rating Max 5** — Error: "The rating must not be greater than 5."
4. **Review Max 500** — Error: "The review must not be greater than 500 characters."
5. **Duplicate User+Note** — Error: "Rating already exists for this note and user."

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| rating below 1 | "The rating must be at least 1." | 422 |
| rating above 5 | "The rating must not be greater than 5." | 422 |
| review exceeds 500 | "The review must not be greater than 500 characters." | 422 |
| duplicate user+note | "Rating already exists for this note and user." | Redirect with error |
| unauthorized | "This action is unauthorized." | 403 |
| module disabled | 404 Not Found | 404 |

---

## Success Scenarios

**SC-001: Admin Views and Filters Ratings**
1. Admin navigates to Note Ratings tab. List loads 15 ratings per page.
2. Admin filters by rating = 5 (star). Only 5-star ratings shown.
3. Admin resets filter, all ratings return.

**SC-002: Admin Deletes Inappropriate Rating**
1. Admin finds a 1-star rating with spam review.
2. Admin clicks Delete, confirms.
3. Rating is removed. Note's avg_rating recalculated. Redirect with success flash.

---

## Failure Scenarios

**FC-001: Unauthorized Delete Attempt**
1. Admin with view-only permission attempts to delete a rating.
2. `Gate::authorize()` returns 403. Action blocked.

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Primary Table | `slb_notes_ratings` | `id`, `notes_id` FK, `user_id` FK, `rating` TINYINT (CHECK 1-5), `review` VARCHAR(500), timestamps, UNIQUE(notes_id, user_id) |
| Related Table | `slb_notes` | Parent note for which the rating was submitted |
| Module Dependency | SyllabusBooks Module | Core module |
| Module Dependency | User & Permission Module | Auth and gates |
| Module Dependency | Activity Log Module | Activity logging |
