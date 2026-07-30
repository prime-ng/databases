# [Exam Types] Master Tab Screen

---

## What Does This Screen Do?

The Exam Types screen is where the school defines all the categories of exams they conduct. Every exam in the system must be tagged with an exam type. This is the simplest but most foundational master configuration in the entire Exam module.

Examples of exam types in a typical Indian K-12 school:
- **Unit Test 1 (UT-1)**, **Unit Test 2 (UT-2)**, **Unit Test 3 (UT-3)**, **Unit Test 4 (UT-4)**
- **Half Yearly Exam (HY-EXAM)**
- **Annual Exam (ANNUAL-EXAM)**
- **Pre-Board**, **Mock Test**, **Surprise Test**, **Weekly Test**

Each exam type has just a few fields:
- **Code** — A short unique identifier (e.g., `UT-1`, `HY-EXAM`, `ANNUAL-EXAM`)
- **Name** — The full display name (e.g., `Unit Test 1`, `Half Yearly Exam`)
- **Description** — Optional notes about when/how this type is used
- **Active Status** — Controls visibility in dropdown menus

Once created, exam types are reused across academic sessions and classes. They appear in the "Exam Type" dropdown whenever someone creates a new exam.

---

## Real-Life Example

Green Valley Academy is setting up the Exam module for the first time. The Admin, Mr. Sharma, opens the Masters tab and sees the Exam Type sub-tab (the first tab that opens by default).

He creates the following exam types one by one:
1. `UT-1` — Unit Test 1
2. `UT-2` — Unit Test 2
3. `UT-3` — Unit Test 3
4. `UT-4` — Unit Test 4
5. `HY-EXAM` — Half Yearly Exam
6. `ANNUAL-EXAM` — Annual Exam

Each of these now appears in the exam type dropdown whenever any teacher creates a new exam.

Months later, the school decides to introduce a "Pre-Board Exam" for Classes 10 and 12. Mr. Sharma creates `PRE-BOARD` — Pre Board Exam. Now it appears in the dropdown too.

The school used to have a "Surprise Test" exam type, but it's no longer conducted. Mr. Sharma deactivates it using the toggle switch. "Surprise Test" no longer appears in dropdowns, but all old exams that used this type still show the correct name on reports.

---

## How the List Page Works

The Exam Types index is the FIRST sub-tab that opens when you click the Masters tab (`active_tab=exam_type`). This means it's the first thing you see when entering the Masters section. It loads a paginated list immediately, 10 records per page, ordered newest-first.

### How Data Is Loaded
The actual data loading happens through the `LmsExamController@masters()` method. It checks the `active_tab` parameter. If it's `exam_type`, it calls the Exam Query Service's `examTypesQuery()` method, which builds the query with optional filters. The controller passes the query result (paginated) to the view along with the filters array.

### Filters Available
- **Active Status** — Show only active or inactive exam types (dropdown)
- **Search** — Free-text search across code, name, and description

### What Each Row Shows
- **Code** — The unique type code (e.g., `UT-1`, `HY-EXAM`)
- **Name** — Display name (e.g., `Unit Test 1`, `Half Yearly Exam`)
- **Description** — Optional notes (truncated if long)
- **Active** — Green/Red toggle switch (AJAX)
- **Actions** — View (eye icon), Edit (pencil icon), Delete (trash icon)

### Pagination
10 rows per page. Uses `exam_type_page` as the page name parameter in the URL to distinguish it from other sub-tab paginations on the same page.

### Trash Page
A separate page showing only soft-deleted exam types. From here you can:
- **Restore** — Bring back the exam type (reactivates it too)
- **Force Delete** — Permanently remove it (no recovery)

---

## How to Create

**Step 1:** On the Masters tab (which opens on Exam Types by default), click "Add Exam Type."

**Step 2:** Fill in the form:
- **Code** (Required) — A short unique identifier like `UT-5` or `PRE-BOARD`. Max 50 characters. Must be unique across ALL exam types — no two exam types can share the same code. Example: `UT-1`, `HY-EXAM`, `ANNUAL-EXAM`.
  
- **Name** (Required) — The full display name like `Unit Test 5` or `Pre Board Exam`. Max 100 characters.
  
- **Description** (Optional) — Free-text notes about this exam type. Max 255 characters. Example: "First unit test conducted after 45 days of instruction."
  
- **Active** — Checkbox. Default: checked. Controls whether this type appears in dropdowns.

**Step 3:** Click "Create Exam Type." The system:
1. Validates: Code required, unique, max 50; Name required, max 100; Description optional, max 255; Active is boolean (converted from checkbox via `prepareForValidation`)
2. Creates the record in `lms_exam_types`
3. Logs activity: "A new exam type was created."
4. Redirects back to Masters tab with success message

### Form Request: `prepareForValidation`
The FormRequest has a `prepareForValidation` method that converts the `is_active` checkbox value to a proper boolean. This is important because HTML checkboxes send "on" or nothing, which needs to be converted to true/false before validation.

---

## How to Edit/Delete

### Editing
Click the Edit button (pencil icon). The system checks usage BEFORE opening the edit form.

**Usage Check Logic:**
The `ExamTypeUsageCheckService` counts how many exams in `lms_exams` have this `exam_type_id`. If the count is greater than zero, the exam type is "in use" and editing is blocked.

Why block editing? If you could change the code `UT-1` to `UT-2` after 50 exams are already tagged as UT-1, all 50 exams would suddenly show the wrong type. The code is a reference that must remain stable once exams are created.

If blocked: "Cannot update this exam type because it is being used in exams."
If allowed: The edit form opens with current values pre-filled.

After saving, the system:
1. Re-checks usage (in case it changed while the form was open — unlikely but possible)
2. Validates the form
3. Compares old vs new values to log only the changes
4. Saves and redirects

### Deleting (Soft Delete)
Click Delete → Same usage check → If blocked, error shown. If allowed, the system does TWO things in sequence:
1. Sets `is_active = false` (deactivates it — hides from dropdowns)
2. Sets `deleted_at` timestamp (marks as soft-deleted in database)

This means a deleted exam type is BOTH inactive AND soft-deleted. The activity log records: "Exam type was deactivated and trashed."

### Important: Deactivation vs Deletion
These are different operations:
- **Deactivation** (via toggle or delete) hides the type from dropdowns but keeps it in the database
- **Deletion** (soft-delete) hides it AND marks it as deleted; it only appears in the Trash page
- Deactivation happens AUTOMATICALLY as part of the delete process — you cannot soft-delete without also deactivating

### Toggle Active Status (AJAX)
The green/red toggle switch sends an AJAX request. **No usage check** is performed — you can deactivate an exam type even if it's being used by 100 exams. The toggle simply controls visibility in dropdowns. The log records: "Exam type status was updated."

### Restoring from Trash
Same usage check → If the exam type is STILL referenced by exams (the foreign keys still exist even in soft-delete), restore is blocked:
"Cannot restore this exam type because it is being used in exams."

If allowed:
1. Removes the soft-delete (`deleted_at = null`)
2. Sets `is_active = true` (reactivates it)
3. Logs: "Exam type was restored."

### Force Delete (Permanent)
From the Trash page, click "Delete Forever." Same usage check. If passed, the record is permanently removed from the database with NO recovery possible. The log records: "Exam type was permanently deleted."

**Edge Case:** If a database exception occurs during force delete (e.g., foreign key constraint), the system shows the actual error message from the database (`$e->getMessage()`), which could be a technical SQL error shown to the user.

---

## How the Show/Details Page Works

Clicking View on an exam type shows:
- All exam type fields (code, name, description, active status)
- **Usage Check Status** — Shows whether this type is "in use" or "not in use"
- **Usage Details** — If in use, shows how many exams are using this type, broken down by total exams and active exams
- **Exam List** — A list of ALL exams that use this exam type, including both active and inactive exams

This gives the admin a complete picture of which exams would be affected if the exam type were changed or removed.

---

## Business Rules Summary

| # | Rule | Details |
|---|------|---------|
| 1 | **Unique Code** | Each exam type code must be unique across all types. Enforced by database unique index AND FormRequest validation. |
| 2 | **Usage Check Blocks Edit/Delete/Restore/ForceDelete** | If any exam references this exam_type_id, the exam type is considered "in use" and all destructive operations (except toggle) are blocked. |
| 3 | **Usage Check NOT on Toggle** | The AJAX status toggle is always allowed regardless of usage. |
| 4 | **Deactivation on Delete** | Soft-delete automatically deactivates (`is_active = false`) BEFORE setting `deleted_at`. |
| 5 | **Reactivation on Restore** | Restore automatically reactivates (`is_active = true`) AFTER removing `deleted_at`. |
| 6 | **Active vs Inactive Controls Dropdown Visibility** | Only active exam types appear in dropdown menus. Inactive types are hidden from new-exam creation but existing exams still display the type name. |
| 7 | **Deleting Does NOT Delete Exams** | Deleting an exam type does NOT delete the exams that use it. The foreign key remains, but the type reference becomes potentially broken. |
| 8 | **Boolean Conversion** | The `is_active` field is converted from checkbox to boolean in `prepareForValidation()` before validation. |
| 9 | **ForceDelete Uses Dynamic Error** | If an exception occurs during forceDelete, the system returns the actual exception message (`$e->getMessage()`) rather than a generic message. |
| 10 | **Usage Check Shows Active Exam Count** | The usage check service additionally distinguishes between total exams and active exams in its `getUsageDetails()` output. |

### In Plain English: When Is an Exam Type "In Use"?
An exam type is "in use" when there is at least one exam in the `lms_exams` table that has its `exam_type_id` pointing to this exam type's ID. This includes:
- Exams that are still in DRAFT status
- Exams that are PUBLISHED
- Exams that are CONCLUDED or ARCHIVED
- Soft-deleted exams (if they still exist in the database)

There is NO distinction between "currently ongoing" exams and "completed" exams — if any exam references the type, it's considered in use.

### In Plain English: Usage Details
When viewing the show page, you see:
- "Exams": Total count of ALL exams using this type
- "Active Exams": Count of exams that are in active status (`is_active = true`)

---

## Validation & Error Messages

| Scenario | Message | Source |
|----------|---------|--------|
| Code missing | "Exam type code is required" | FormRequest |
| Duplicate code | "This exam type code already exists" | FormRequest (code.unique) |
| Name missing | "Exam type name is required" | FormRequest |
| Edit blocked (in use) | "Cannot update this exam type because it is being used in exams." | Controller usage check (edit) |
| Update blocked (in use) | "Cannot update this exam type because it is being used in exams." | Controller usage check (update) |
| Delete blocked (in use) | "Cannot delete this exam type because it is being used in exams." | Controller usage check (destroy) |
| Restore blocked (in use) | "Cannot restore this exam type because it is being used in exams." | Controller usage check (restore) |
| Force delete blocked (in use) | "Cannot permanently delete this exam type because it is being used in exams." | Controller usage check (forceDelete) |
| DB failure on create | "Failed to create exam type. Please try again." | Exception catch (transaction rollback) |
| DB failure on update | "Failed to update exam type. Please try again." | Exception catch (transaction rollback) |
| DB failure on delete | "Failed to delete exam type. Please try again." | Exception catch (transaction rollback) |
| DB failure on restore | "Failed to restore exam type. Please try again." | Exception catch (transaction rollback) |
| DB failure on toggle | "Failed to update status." | AJAX exception catch |
| DB exception on forceDelete | Dynamic: `$e->getMessage()` | Catch block returns actual exception message |

---

## Activity Log Messages

| Action | Log Message |
|--------|-------------|
| Create | "A new exam type was created." |
| Update | "Exam type updated with changes: {\"name\":{\"old\":\"Unit Test 1\",\"new\":\"Unit Test 1 Updated\"}}" |
| Soft Delete (Trash) | "Exam type was deactivated and trashed." |
| Restore | "Exam type was restored." |
| Force Delete | "Exam type was permanently deleted." |
| Toggle Status | "Exam type status was updated." |

---

## AJAX Endpoints

| Endpoint | Purpose | Details |
|----------|---------|---------|
| `toggleStatus` | Toggle active/inactive | Validates boolean, saves, logs, returns JSON `{success, is_active, message}` |

---

## Permissions

| Gate | Methods | Notes |
|------|---------|-------|
| `tenant.exam-type.viewAny` | index() | View the list |
| `tenant.exam-type.view` | show() | View single type details |
| `tenant.exam-type.create` | create(), store() | Create new type |
| `tenant.exam-type.update` | edit(), update(), toggleStatus() | Edit, update, and toggle |
| `tenant.exam-type.delete` | destroy() | Soft-delete |
| `tenant.exam-type.restore` | trashed(), restore() | View trash and restore |
| `tenant.exam-type.forceDelete` | forceDelete() | Permanent delete |
| `tenant.exam-type.status` | (used in Blade) | View/change toggle switch |
| `tenant.exam-type.import/export/print` | (policy only) | Reserved for future use |

---

## Related Screens

- **Exam Creation (Creation & Allocation tab)** — The exam type dropdown gets its options from this screen. Only ACTIVE exam types appear.
- **Exam Status Events** — Another master on the same Masters tab (second sub-tab)
- **Exam Summary** — Shows exam counts grouped by exam type
- **Masters Tab** — This is the FIRST sub-tab, which opens by default when you click the Masters tab
