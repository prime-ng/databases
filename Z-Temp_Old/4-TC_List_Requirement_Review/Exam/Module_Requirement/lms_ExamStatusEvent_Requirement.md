# [Exam Status Events] Master Tab Screen

---

## What Does This Screen Do?

The Exam Status Events screen defines all the possible lifecycle statuses that exams, exam papers, results, and student attempts can move through. Think of it as the "state machine configuration" for the entire Exam module — every status that appears in a dropdown anywhere in the exam system is defined here.

There are four categories (called "Event Types") of statuses:

1. **EXAM** — Statuses for the overall exam lifecycle:
   - `DRAFT` → The exam is being set up, not visible to anyone yet
   - `PUBLISHED` → The exam is announced, visible to teachers and students
   - `CONCLUDED` → The exam period is over
   - `ARCHIVED` → The exam is closed and stored for records

2. **PAPER** — Statuses for individual exam papers:
   - `NOT_STARTED` → Paper created but no activity yet
   - `IN_PROGRESS` → Exam is live, students are taking it
   - `SUBMITTED` → Student has submitted
   - `EVALUATION_PENDING` → Waiting for teacher to evaluate
   - `EVALUATED` → Marks have been given
   - `RESULT_PUBLISHED` → Results are out
   - `ABSENT` → Student was absent
   - `CANCELLED` → Paper was cancelled

3. **RESULT** — Statuses for result computation workflows

4. **ATTEMPT** — Statuses for individual student attempts

Each status event has a unique **Code** (like `DRAFT`, `PUBLISHED`), a human-readable **Name** (like `Draft`, `Published`), an **Event Type** (EXAM/PAPER/RESULT/ATTEMPT), and an **Action Logic** field (JSON that stores structured rules for what happens when this status is applied).

---

## Real-Life Example

The school is setting up the Exam module for the first time. The Admin, Ms. Sharma, opens the Masters tab and clicks the "Exam Status Events" sub-tab (second tab). She sees the predefined statuses already loaded from seed data during installation.

Later, the school decides they need a new workflow step. Currently, after a student submits an online paper, the status goes directly to "EVALUATION_PENDING." But the school wants to add a "REVIEW" step between submission and evaluation, where a senior teacher reviews the paper before evaluation begins.

Ms. Sharma clicks "Add Status Event" and creates:
- Code: `REVIEW`
- Name: `Under Review`
- Event Type: `PAPER`
- Active: Yes

Now, whenever anyone creates a new exam paper, "Under Review" appears in the status dropdown.

---

## How the List Page Works

The Exam Status Events index is the second sub-tab inside the Masters tab (`active_tab=exam_status_event`). It loads a paginated list of all status events, 10 per page, ordered newest-first.

### Filters Available
- **Event Type** — Filter by EXAM, PAPER, RESULT, or ATTEMPT
- **Active Status** — Show only active or inactive events
- **Search** — Free-text search across code, name, description, and event_type

### What Each Row Shows
- **Code** — The short identifier (e.g., DRAFT, PUBLISHED)
- **Name** — Display name (e.g., Draft, Published)
- **Event Type** — Which entity this status applies to
- **Active** — Toggle switch (AJAX)
- **Actions** — View, Edit, Delete

---

## How to Create

**Step 1:** Click "Add Status Event" on the Masters tab.

**Step 2:** Fill in the form:
- **Code** (Required) — A unique short identifier like `DRAFT`, `PUBLISHED`, `REVIEW`. Max 50 characters. Must be unique across all status events.
- **Name** (Required) — Human-readable display name like `Draft`, `Published`, `Under Review`. Max 100 characters.
- **Event Type** (Required) — Choose one of: `EXAM`, `PAPER`, `RESULT`, `ATTEMPT`. This determines which dropdowns this status appears in.
- **Description** (Optional) — Any notes about this status (max 255 characters).
- **Active** — Checked by default. If unchecked, this status won't appear in any dropdown.

**Step 3:** The system automatically generates the **Action Logic** field — a JSON structure that contains the name, code, and event_type of the status. This is done automatically and the user does not fill it in manually. The action_logic is built from the submitted form data.

**Step 4:** Click "Create." The system validates (code unique, name required, event_type valid), creates the record, logs the activity, and redirects to the Masters tab.

### Form Request Details
The `ExamStatusEventRequest` validates:
- `code` — required, string, max:50, **unique** in `lms_exam_status_events` (ignores own ID on update)
- `name` — required, string, max:100
- `description` — nullable, string, max:255
- `event_type` — required, must be one of: EXAM, PAPER, RESULT, ATTEMPT
- `action_logic` — nullable, must be valid JSON if provided
- `is_active` — boolean

The request also has a `prepareForValidation` method that:
- Converts the `is_active` checkbox to a boolean
- If `action_logic` is provided, JSON-encodes it; otherwise sets it to an empty JSON array `[]`

---

## How to Edit/Delete

### Editing
Click Edit → The system checks usage BEFORE opening the edit form.

**Usage Check Logic:**
The `ExamStatusEventUsageCheckService` checks TWO tables:
1. `lms_exams` — Is any exam using this status as its `status_id`?
2. `lms_exam_papers` — Is any exam paper using this status as its `status_id`?

If EITHER exists, editing is blocked: "Cannot edit this status because it is being used in exams or exam papers."

If allowed: The edit form opens. The `action_logic` is auto-regenerated on save (the system recalculates it from the new name/code/event_type values).

### Deleting (Soft Delete)
Click Delete → Same usage check → If blocked, error shown. If allowed:
1. The system sets `is_active = false` (deactivates the status so it disappears from dropdowns)
2. Then soft-deletes the record (sets `deleted_at` timestamp)
3. Logs: "Exam status event was deactivated and trashed."

### Restoring from Trash
Same usage check → If the status is STILL referenced by any exam or exam paper (even after soft-delete, the foreign keys still exist), restore is blocked. If allowed:
1. Restores the record (`deleted_at = null`)
2. Sets `is_active = true` (reactivates)
3. Logs and redirects

### Force Delete (Permanent)
**Two layers of protection:**
1. **Controller level:** Usage check → If used, blocked
2. **Model level:** The model has a `booted()` method with a `deleting` event that checks if the status is referenced by exams or exam papers. If it IS a force-delete (`isForceDeleting()`) and the status IS in use, it throws an exception that prevents the deletion. This is a safety net even if the controller-level check is somehow bypassed.

### Toggle Active Status (AJAX)
The toggle switch works via AJAX — no usage check required. You can deactivate a status even if it's being used by exams. The toggle just controls visibility in dropdowns.

---

## Business Rules Summary

| # | Rule | Details |
|---|------|---------|
| 1 | **Unique Code** | Every status event must have a unique `code`. Enforced by database unique index AND FormRequest validation. |
| 2 | **Event Type Restriction** | A status is tagged to exactly one entity type (EXAM/PAPER/RESULT/ATTEMPT). It cannot be applied to other entity types. |
| 3 | **Usage Check Blocks Edit/Delete/Restore/ForceDelete** | If any exam or exam paper references this status_id, destructive operations are blocked. |
| 4 | **Usage Check NOT on Toggle** | The AJAX status toggle is always allowed. |
| 5 | **Action Logic Auto-Population** | Both store() and update() automatically set `action_logic` to `{name, code, event_type}` based on submitted form data — user does NOT fill this manually. |
| 6 | **Deactivation on Delete** | Soft-delete automatically deactivates the status (`is_active = false`) before setting `deleted_at`. |
| 7 | **Reactivation on Restore** | Restore automatically reactivates (`is_active = true`) after removing `deleted_at`. |
| 8 | **Model-Level Force Delete Safety Net** | The model's `booted()` method blocks hard deletes if the status is in use, as a last-resort protection. |
| 9 | **Action Logic on Update** | Even when editing, the action_logic is recalculated from the NEW name/code/event_type values. |
| 10 | **Search Includes Event Type** | The search filter also searches through the `event_type` column (e.g., searching "PAPER" will find all paper statuses). |

### In Plain English: What "Action Logic" Is
Every time a status event is created or updated, the system automatically stores a JSON record that contains the status's own name, code, and event_type. This is a redundant data structure that serves as a "snapshot" of the status at the time it was applied. So even if the status's name changes later, any entity that was tagged with this status already has a copy of the original values in its action_logic.

---

## Validation & Error Messages

| Scenario | Message | Source |
|----------|---------|--------|
| Code missing | "Status code is required" | FormRequest |
| Duplicate code | "This status code already exists" | FormRequest (code.unique) |
| Name missing | "Status name is required" | FormRequest |
| Event type missing | "Event type is required" | FormRequest |
| Invalid action logic JSON | "Action logic must be valid JSON" | FormRequest |
| Edit blocked (in use) | "Cannot edit this status because it is being used in exams or exam papers." | Controller usage check |
| Update blocked (in use) | "Cannot update this status because it is being used in exams or exam papers." | Controller usage check |
| Delete blocked (in use) | "Cannot delete this status because it is being used in exams or exam papers." | Controller usage check |
| Restore blocked (in use) | "Cannot restore this status because it is being used in exams or exam papers." | Controller usage check |
| Force delete blocked (in use) | "Cannot permanently delete this status because it is being used in exams or exam papers." | Controller usage check |
| Model-level force delete blocked | "Exam status event is in use and cannot be permanently deleted." | Model booted() event |
| DB failure on create/update | "Failed to create/update exam status event. Please try again." | Exception catch |
| DB failure on delete | "Failed to delete exam status event. Please try again." | Exception catch |
| DB failure on restore | "Failed to restore exam status event. Please try again." | Exception catch |
| Force delete failure | "Exam status event is in use and cannot be permanently deleted." (or generic message) | Catch block uses `$e->getMessage()` |
| Toggle failure | "Failed to update status." | AJAX error response |

---

## Activity Log Messages

- **Created**: "A new exam status event was created."
- **Updated**: "Exam status event updated with changes: {\"field\":{\"old\":\"X\",\"new\":\"Y\"}}"
- **Trashed**: "Exam status event was deactivated and trashed."
- **Restored**: "Exam status event was restored."
- **Force Deleted**: "Exam status event was permanently deleted."
- **Toggled**: "Exam status event status was updated."

---

## AJAX Endpoints

| Endpoint | Purpose |
|----------|---------|
| `toggleStatus` | Toggle is_active via AJAX — validates boolean, saves, returns JSON |

---

## Permissions

| Gate | Methods |
|------|---------|
| `tenant.exam-status-event.viewAny` | index() |
| `tenant.exam-status-event.view` | show() |
| `tenant.exam-status-event.create` | create(), store() |
| `tenant.exam-status-event.update` | edit(), update(), toggleStatus() |
| `tenant.exam-status-event.delete` | destroy() |
| `tenant.exam-status-event.restore` | trashed(), restore() |
| `tenant.exam-status-event.forceDelete` | forceDelete() |

---

## Related Screens

- **Exam Creation** — The exam status dropdown only shows statuses with `event_type=EXAM`
- **Exam Papers** — The paper status dropdown only shows statuses with `event_type=PAPER`
- **Masters Tab** — This is the second sub-tab; Exam Types is the first
- **Exam Summary** — Shows status distribution counts across exams

---

## Technical Implementation Details

### Database Table: `lms_exam_status_events`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| code | VARCHAR(50) UNIQUE | e.g., `DRAFT`, `PUBLISHED`, `CONCLUDED` |
| name | VARCHAR(100) | Display name |
| description | VARCHAR(255) NULL | Optional notes |
| event_type | ENUM('EXAM','PAPER','RESULT','ATTEMPT') | Default: EXAM |
| action_logic | JSON | Auto-populated rules |
| is_active | TINYINT(1) | Default: 1 |
| created_at / updated_at / deleted_at | TIMESTAMP | Soft deletes |

**Unique Constraint:** UNIQUE KEY on `code` column — no two statuses can share the same code.

### Action Logic JSON Structure
When a status event is created or updated, the system automatically generates an `action_logic` JSON field:

```json
{
    "name": "Draft",
    "code": "DRAFT",
    "event_type": "EXAM"
}
```

This serves as a "snapshot" — even if the status's name or code changes later, any entity that was tagged with this status at a point in time retains the original values in its action_logic.

### Data Loading Architecture
The `ExamStatusEventController@index()` method:
1. Authorizes the user via gate
2. Builds a query via `queryBuilder()` with filters (event_type, search, is_active)
3. Paginates at 10 rows per page (default page size)
4. Passes the filters array back to the view so the form retains state

The same query can be built by `ExamQueryService@examStatusEventsQuery()` from the Masters tab view when `active_tab=exam_status_event`.

### Model-Level Force Delete Protection
The model has a `booted()` method that registers a `deleting` event:

1. The event checks if the current operation is a FORCE delete (`isForceDeleting()`)
2. If it IS a force delete and the status is referenced by ANY exam or exam paper
3. It throws an exception: "Exam status event is in use and cannot be permanently deleted."
4. This prevents the database deletion

This is a SAFETY NET — even if the controller-level usage check somehow fails or is bypassed, the model itself blocks the deletion.

**Important:** This protection only applies to forceDelete (hard delete). Soft deletes (regular `delete()`) are NOT blocked at the model level — they rely solely on the controller's usage check.

### FormRequest Data Preparation
The `ExamStatusEventRequest` has a `prepareForValidation()` method that:
1. Converts the `is_active` checkbox value to a boolean: `$this->boolean('is_active')`
2. If `action_logic` was provided by the user, JSON-encodes it
3. If `action_logic` was NOT provided, sets it to an empty JSON array `[]`

However, in the controller, the `action_logic` is ALWAYS overridden regardless of what was submitted. Both `store()` and `update()` set:
```php
$statusData['action_logic'] = [
    'name'   => $request->name,
    'code'   => $request->code,
    'event_type' => $request->event_type,
];
```
This means user-submitted action_logic values are ALWAYS ignored and replaced.

### Transaction Handling
All mutating methods wrap operations in DB::beginTransaction()/commit()/rollBack():
- store(): Create record + activity log
- update(): Update record + detect changes + activity log
- destroy(): Deactivate + soft-delete + activity log
- restore(): Restore + reactivate + activity log
- forceDelete(): Force delete + activity log
- toggleStatus(): Update is_active + activity log

### The ToggleStatus Endpoint
The AJAX toggle for active/inactive:
1. Requires `is_active` parameter (validated as boolean)
2. Finds the status event or returns 404
3. Sets `is_active` to the new value
4. Saves; if successful:
   - Logs activity: "Exam status event status was updated."
   - Commits transaction
   - Returns JSON: `{success: true, is_active: 1/0, message: "..."}`
5. If save fails: rolls back, returns JSON error
6. On exception: rolls back, returns 500 JSON error

### Usage Check Service: Dual Table Check
The `ExamStatusEventUsageCheckService` checks TWO consumer tables:
1. `lms_exams` — Counts exams with matching `status_id`
2. `lms_exam_papers` — Counts papers with matching `status_id`

If EITHER count > 0, the status is "in use." The `getUsageDetails()` method returns both counts separately, so the show page can display "Used in X exams and Y papers."

### Search Behavior
The search filter on the index page searches across:
- Status code (e.g., "DRAFT")
- Status name (e.g., "Draft")
- Description
- Event type (e.g., "EXAM", "PAPER")

This last one means searching "PAPER" will return all statuses with event_type PAPER, effectively acting as a second event type filter.

### Error Handling in Catch Blocks
- Most catch blocks use `\Exception` type hinting
- The `destroy()` and `forceDelete()` methods use `\Throwable` instead, which catches both exceptions AND errors (PHP 7+)
- The `forceDelete()` catch block returns `$e->getMessage()` if available, otherwise defaults to "Failed to permanently delete exam status event." — this means database-level error messages could be shown to the user
