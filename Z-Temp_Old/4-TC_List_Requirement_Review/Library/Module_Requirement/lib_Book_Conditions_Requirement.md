# Lib Book Conditions — Business Requirements

## What This Screen Does

The Book Conditions screen defines standardized physical condition states for library book copies. Each condition record carries a unique business code (e.g., NEW, GOOD, DAMAGED, LOST) and a name, along with a borrowable flag that determines whether copies in that condition can be issued to members. Conditions form the backbone of the library's physical collection tracking — every book copy has a current condition assigned, and every time a copy's condition changes, a history record is written to the `lib_book_condition_jnt` junction table.

This screen is a master data configuration within the Library Masters tab group. Beyond simple CRUD, it supports bulk mapping of books and copies to a condition, creating condition assessment history records during both initial setup (store) and updates. The screen also supports AJAX-driven status toggling and a dedicated addBooks endpoint that attaches additional copies to a condition without updating the entire record.

---

## When This Screen Is Used

- When defining new condition types during library setup (e.g., creating NEW, GOOD, DAMAGED, LOST, REPAIRED)
- When bulk-mapping large book sets to a specific condition (e.g., marking 500 copies as DAMAGED after a flood)
- When updating condition names or borrowable status as library policies change
- When reviewing condition history for a specific book copy
- When deactivating or soft-deleting obsolete condition types
- When restoring previously deleted conditions from trash

## Default Data Load

The Conditions screen opens as a tab pane within the Library Masters hub page (`library.tabIndex`). The controller's `index()` method redirects to the hub tab view (`tab=book-condition`). When the tab is active, the private query helper loads all conditions with a books_count relation loaded, paginated at 15 per page. Search and status filters are supported. The search bar filters by name and code.

---

## Key Fields at a Glance

**Core Identity**
Every condition must have a unique code (VARCHAR(30), e.g., "NEW", "DAMAGED") and a display name (VARCHAR(50), e.g., "New", "Damaged"). An optional description (VARCHAR(255)) provides contextual details about what the condition means and when it should be used.

**Borrowable Flag**
The `is_borrowable` boolean controls whether book copies in this condition can be issued to members. A DAMAGED condition typically has `is_borrowable = false`, while NEW and GOOD have `is_borrowable = true`. This flag is checked during the book issue workflow to prevent issuing damaged books. When `is_borrowable` = 0 (e.g., Damaged or Lost condition), books with this condition cannot be issued to any member.

**Status**
The `is_active` boolean toggles whether the condition appears in dropdown selection lists. Inactive conditions retain their data and history but are excluded from active selection in copy management screens.

---

## Business Rules and Conditions

**Unique Constraints**
Condition codes must be unique across all records, including soft-deleted ones. The FormRequest enforces `Rule::unique('lib_book_conditions', 'code')` on create, and ignores the current record's ID on update.

**Delete Protection via Junction References**
On soft delete, the `destroy()` method detaches all book mappings via `$condition->books()->detach()` before calling `$condition->delete()`. On force delete, any remaining `lib_book_condition_jnt` mappings are deleted first, and a QueryException with code 23000 is caught and reported if other database references prevent deletion.

**Bulk Mapping on Create**
When creating a condition, the controller accepts a `mappings` array from the request. Each mapping row specifies a `date`, `note`, and array of `book_ids`. For each book ID, the controller finds all active copies (`LibBookCopy`) of that book (using `where('book_id', $bookId)`) and creates one `LibBookConditionJnt` record per copy. This means condition mappings are at the copy level, not at the book title level.

**Update Replaces All Mappings**
On update, the controller deletes ALL existing `LibBookConditionJnt` records for the condition and re-creates them from the request's `mappings` array. If no mappings are provided, all mappings are deleted. This is a full-replace strategy.

**Activity Logging**
Every operation (store, update, destroy, restore, forceDelete, toggleStatus, addBooks) creates detailed activityLog entries capturing the condition name, code, changed attributes, mapping counts, and the performing user.

**Condition Tracking (Issue-to-Return Degradation)**
When a book is issued and later returned, the condition at both times is compared. If the condition has degraded (return condition is worse than issue condition), a fine may be applicable. This comparison powers the fine assessment workflow.

**Borrowing Block Rule**
When `is_borrowable` = 0 (e.g., Damaged or Lost), books in this condition cannot be issued to any library member. This check is enforced at the transaction level during book issue.

---

## Book Condition Junction (`lib_book_condition_jnt`)

The condition junction table is a historical log that tracks every condition assessment for each book copy over time. Each row records the condition at a specific point (purchase receive, issue, return), creating an audit trail for wear-and-tear analysis, damage accountability, and fine assessment.

### Junction Table Business Rules

1. **Entry on Every Return** — A new row MUST be inserted every time a book is returned, recording the condition at that moment.

2. **Entry on Purchase Receive** — A new row MUST be inserted when a purchased copy is first received and cataloged, establishing its baseline condition.

3. **Condition Degradation Detection** — By comparing the condition at issue time vs. return time, the library can determine if the copy was damaged during the member's possession and assess fines accordingly.

4. **Sync with `lib_book_copies.current_condition_id`** — Whenever a new condition is recorded in the junction table, the parent `lib_book_copies` record's `current_condition_id` MUST also be updated to reflect the latest assessment.

5. **No Deletion Policy** — Condition records are audit-critical and should never be deleted under normal operations.

### Junction Table Fields

- **`date`** (DATE NOT NULL) — Date when the condition was assessed. Must match the transaction date of the related issue/return/receive operation.
- **`book_id`** (FK → `lib_books_master.id`, ON DELETE CASCADE) — The book title this assessment belongs to.
- **`book_copy_id`** (FK → `lib_book_copies.id`, ON DELETE CASCADE) — The specific physical copy being assessed.
- **`condition_id`** (FK → `lib_book_conditions.id`, ON DELETE CASCADE) — The assessed condition at this point in time.
- **`note`** (VARCHAR(255) NULL) — Optional context notes (e.g., "Spine slightly cracked", "Page 105 torn").

### Condition Degradation → Fine Applicability Flow

```
Purchase Receive → INSERT condition_jnt (condition=New)
Issue to Member → INSERT condition_jnt (condition=Good)
Return from Member → INSERT condition_jnt (condition=Fair) ← degraded!
                         │
                         ▼
              Compare return_condition vs issue_condition
                         │
              ┌──────────┴──────────┐
              ↓                     ↓
        No Degradation        Degradation Detected
        (no fine)             (return_condition worse)
                                      │
                                      ↓
                              Check is_borrowable on
                              return_condition
                              ┌────────┴────────┐
                              ↓                 ↓
                        is_borrowable=0    is_borrowable=1
                        (Damaged/Lost)     (Fair but borrowable)
                              ↓                 ↓
                        Fine assessed      May still be fine-
                        for damage/loss    eligible if condition
                                           is lower severity
```

- **Condition Degradation Rule:** When `return_condition.is_borrowable = false` OR the return condition represents a lower quality state than the issue condition, a fine for damage/loss may be applied.
- The fine amount is determined by the library's fine slab configuration based on condition severity difference.
- Applicable for both lost (`is_lost = 1`) and damaged (`is_damaged = 1`) returns.

## Workflow Steps

1. Navigate to Library Masters hub and select the Book Conditions tab
2. View the existing conditions list with borrowable and active status badges
3. Click "Add Condition" to open the create form
4. Enter unique code, name, description, and set borrowable/active toggles
5. Optionally select multiple books to bulk-map copies to this condition
6. System saves the condition and creates junction records for each copy of each selected book
7. Edit a condition to update its name, description, or borrowable flag — any existing book mappings can be modified or removed
8. Toggle the active status via AJAX status switch
9. Soft delete moves the condition to trash and detaches all book mappings
10. Restore or force delete from trash — force delete includes FK constraint protection

---

## Example Scenario

The school librarian notices that 200 book copies were damaged during a recent shelf collapse. They create a new condition called "Repaired" with code "REP" and `is_borrowable = true`. They then bulk-map all 200 copy records to the "Repaired" condition with date and notes. Later, a student attempts to issue one of the repaired copies — the system checks the condition's `is_borrowable` flag and allows it because the condition allows borrowing. After six months, the librarian decides the "Repaired" condition is no longer needed and soft-deletes it.

---

## Related Screens

- Library Book Copies — consumes condition assignments to track each copy's physical state
- Library Book Master — books are linked to conditions via the junction table for condition history
- Library Masters Hub — parent tab container holding the Book Conditions tab
- Library Transactions — checks condition at issue and return to detect condition degradation

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibBookConditionController`
**Model:** `Modules\Library\Models\LibBookCondition` (table: `lib_book_conditions`, uses `SoftDeletes`)
**Requests:** `LibBookConditionRequest` (validates code, name, description, is_borrowable, is_active; unique code check scoped to `id` on update)
**Policy:** Named permission string `tenant.lib-book-conditions.*` (no dedicated Policy class — uses Gate facade with string)
**Route:** Resource route `Route::resource('lib-book-conditions', LibBookConditionController::class)` with extras: `trashed`, `restore`, `forceDelete`, `toggleStatus`

Key controller methods:
- `index()` — Redirects to hub tab `library.tabIndex` with `tab=book-condition`
- `create()` — Returns create view with active books dropdown
- `store(LibBookConditionRequest)` — Creates condition + bulk-maps copies via `LibBookConditionJnt` in a DB transaction
- `edit($id)` — Loads condition with existing books, groups mappings by date+note for dynamic form rows
- `update(LibBookConditionRequest, $id)` — Updates condition + replaces all mappings in a transaction
- `destroy($id)` — Detaches all books, soft-deletes condition, logs both actions
- `trashed()` — Lists soft-deleted conditions with books_count
- `restore($id)` — Restores condition from trash
- `forceDelete($id)` — Deletes mappings then force-deletes condition; catches FK exception with user-friendly message
- `toggleStatus($id)` — Toggles `is_active` via AJAX
- `addBooks(Request, $id)` — Attaches additional copies to condition without affecting existing mappings; skips duplicates

**ActivityLog Events:** Stored (with mapping details), Updated (with changes array + mapping counts), Trashed (with books_detached_count), Restored, Deleted (with condition data snapshot), Toggled

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|-------------|
| Super Admin | `tenant.lib-book-conditions.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-book-conditions.*` | Full CRUD + bulk mapping |
| Librarian | `tenant.lib-book-conditions.viewAny`, `.view`, `.create`, `.update` | View, add, edit conditions |
| Library Assistant | `tenant.lib-book-conditions.viewAny`, `.view` | Read-only access |

---

## How This Screen Works — Logic Flow (Non-Technical)

The user opens the Library Masters page and clicks the Book Conditions tab. The system displays a paginated list of all conditions with their borrowable and active status. The user can add a new condition by filling in a unique code, a name, and optional description, plus setting whether books in this condition can be borrowed. Optionally, they can select multiple books from a dropdown — when saved, the system automatically creates a log entry for every physical copy of each selected book, recording them under the new condition with today's date. Editing works the same way, except existing log entries are removed first and replaced with whatever is selected in the form. Deleting a condition first clears all its book log entries then moves it to the trash, from where it can be brought back or permanently removed.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|-------|------|---------------|
| 1 | code | Required, String, Max:30 | Condition code is required. |
| 2 | code | Unique (ignore self on update) | This code is already taken. |
| 3 | name | Required, String, Max:50 | Condition name is required. |
| 4 | description | Nullable, String, Max:255 | — |
| 5 | is_borrowable | Boolean (prepared from checkbox: 0/1) | — |
| 6 | is_active | Boolean (prepared from checkbox: 0/1) | — |
| 7 | mappings | Nullable, Array | — |
| 8 | mappings.*.book_ids | Required if mappings present, Array | — |
| 9 | mappings.*.date | Date (nullable, defaults to now) | — |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Model not found (show/edit/update) | No query results for model | 404 |
| Force delete — FK constraint | Cannot delete this condition: it is referenced by other records. | 422 (redirect with flash) |
| DB transaction fails (store) | Failed to create condition: [detail] | 422 (redirect with flash) |
| DB transaction fails (update) | Failed to update condition: [detail] | 422 (redirect with flash) |
| AJAX toggle fails | Unhandled exception | 500 |

---

## Success Scenarios

**SC-001: Create a new condition with borrowable flag**
1. Librarian clicks "Add Condition", enters code=REP, name="Repaired", description="Book has been repaired after damage"
2. Sets is_borrowable = true, is_active = true
3. Does not select any books for mapping
4. System saves condition, creates no junction records
5. Flash success: "Condition created and mapped to books successfully."

**SC-002: Create condition with bulk book mapping**
1. Librarian creates condition DAMAGED, selects 5 books from the book dropdown
2. System finds all active copies for each selected book (e.g., 3 copies each = 15 records)
3. System creates 15 LibBookConditionJnt records, each with today's date and condition ID
4. activityLog records both the condition creation and the mapping summary

**SC-003: Update condition with full mapping replacement**
1. Librarian edits existing condition, changes description, replaces old mappings with 3 new books
2. System deletes all existing LibBookConditionJnt records for this condition
3. System creates new junction records for copies of the 3 selected books
4. Flash success: "Condition updated successfully."

---

## Failure Scenarios

**FC-001: Create condition with duplicate code**
1. Librarian enters code=NEW for a condition that already exists
2. FormRequest validation fails with "This code is already taken."
3. Form re-displays with validation error and previously entered values

**FC-002: Force delete condition referenced by book copies**
1. Librarian navigates to Trash and clicks force-delete
2. Controller's forceDelete() runs inside try-catch
3. Database throws QueryException with code 23000 (FK constraint)
4. Catch block redirects with error: "Cannot delete this condition: it is referenced by other records."
5. Condition remains in trash

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | lib_book_conditions | Main condition table with unique code, name, is_borrowable flag |
| Table | lib_book_condition_jnt | Junction table mapping conditions to books and copies (FK: condition_id, book_id, book_copy_id) |
| Table | lib_book_copies | FK reference for current_condition_id on each copy |
| Table | lib_book_master | FK reference via junction for condition history |
| Module | Library Book Copies | Consumes condition assignments for copy management |
| Module | Library Masters Hub | Parent tab container holding the Book Conditions tab |
