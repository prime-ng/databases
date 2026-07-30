# Digital Resource Tags — Business Requirements

## What This Screen Does

The Digital Resource Tags screen manages keyword tags attached to digital resources (e-books, PDFs, video lectures, etc.). Tags are simple text labels that help members discover related digital resources through search and browsing. Tags are managed inline within the Digital Resource create/edit screen — there is no standalone tag list page. Tags can be added individually or in bulk, and are deleted individually or in bulk. The primary use case is organizing digital resources by topic, subject, or format for improved searchability.

---

## When This Screen Is Used

- When adding tags to a digital resource to make it discoverable by topic or subject
- When organizing digital resources into searchable categories (e.g., "interactive", "video-lecture", "class-10-science")
- When removing outdated or incorrect tags from a resource
- When bulk-removing multiple tags from a resource at once

## Default Data Load

This is not a standalone index page. Tags are displayed within the Digital Resource create/edit view as an inline list beneath the resource details. When editing a digital resource, existing tags are loaded via the resource's `tags()` relationship. The `LibDigitalResourceTagController@index()` method exists but loads the complete Library Operations hub with all its sub-tabs (categories, authors, genres, keywords, publishers, resource types, books, copies, members, transactions, etc.) — it is NOT a tag-specific index.

---

---

## Key Fields at a Glance

**Core Identity**
Each tag has a `tag_name` (VARCHAR 100) and belongs to exactly one digital resource via `digital_resource_id` FK. The combination of `digital_resource_id` + `tag_name` is unique — a resource cannot have duplicate tags.

**Relationship**
Tags cascade delete with their parent digital resource. Deleting a digital resource automatically removes all its tags. Tags use soft deletes, so deletions can be recovered if needed.

---

## Business Rules and Conditions

**Unique Constraint Per Resource**
A digital resource cannot have two tags with the same name. The unique key `uq_lib_digResTags_resourceId_tagName` (`digital_resource_id`, `tag_name`) enforces this at the database level.

**Cascade Delete**
When a digital resource is deleted, all its tags are automatically deleted via `ON DELETE CASCADE`.

**Soft Deletes**
The model uses `SoftDeletes`. Tags are soft-deleted when removed, allowing recovery if needed.

**Inline Management**
Tags are managed directly on the Digital Resource create/edit page — there is no separate tag management screen. The create form for digital resources includes a tag input field, and the edit page shows existing tags with delete buttons.

---

## Workflow Steps

**Adding a Single Tag**
The librarian opens a digital resource for editing. In the Tags section, they type a tag name (e.g., "Physics") into an input field and click Add. An AJAX POST request sends the tag name to `LibDigitalResourceTagController@store()`. The system checks for duplicates, creates the tag, and returns the new tag with a delete URL. The tag appears in the list without a page reload.

**Deleting a Single Tag**
The librarian clicks the delete icon next to a tag. An AJAX DELETE request removes the tag. The tag disappears from the list.

**Bulk Deleting Tags**
The librarian selects multiple tags and clicks a bulk delete button. An AJAX POST request sends the selected tag IDs to `LibDigitalResourceTagController@bulkDestroy()`. All selected tags are soft-deleted at once.

---

## Example Scenario

A new digital resource titled "NCERT Grade 10 Science Textbook PDF" is added to the library. The librarian opens the resource edit screen and adds tags one by one: "Science", "Grade 10", "NCERT", "PDF", "Textbook". Each tag is created via AJAX and appears immediately. Later, the curriculum changes and Grade 10 Science is restructured. The librarian edits the resource, deletes the "NCERT" tag (which is now inaccurate), and adds a new tag "CBSE". The tag list is updated instantly.

---

## Related Screens

- **Digital Resources** — Tags are managed within the Digital Resource create/edit screen
- **Digital Resource Access Restrictions** — Separate access control settings for the same resources

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibDigitalResourceTagController`
**Model:** `Modules\Library\Models\LibDigitalResourceTag` (table: `lib_digital_resource_tags`, uses `SoftDeletes`)
**Requests:** Inline `$request->validate()` in store/bulkDestroy
**Policy:** `LibDigitalResourceTagPolicy` (permissions match `tenant.lib-digital-resource-tags.*` group in permissionslist.php)
**Route:** Nested under `lib-digital-resources/{resource}/tags` (index, store, destroy) + bulkDestroy

Key controller methods:
- `index()` — Loads the complete Library Operations hub with all sub-tab data (NOT a tag-specific index)
- `store(Request, $resourceId)` — Adds a single tag via AJAX; validates tag_name required|max:100; checks for duplicate within the same resource; returns JSON with success/message/tag/delete_url
- `destroy($resourceId, $tagId)` — Removes a single tag via AJAX; soft-deletes; returns JSON success response
- `bulkDestroy(Request, $resourceId)` — Removes multiple tags at once; validates tag_ids required|array|exists; returns JSON success response

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | Full access — add, delete, bulk delete tags |
| Librarian Admin | Full access — add, delete, bulk delete tags |
| Librarian Operator | Add tags (via Digital Resource edit screen) |

All access is gated by `Gate::authorize('tenant.lib-digital-resource-tags.{action}')`.

---

## How This Screen Works — Logic Flow (Non-Technical)

Tags are not a separate screen — they are an inline feature within the Digital Resource create/edit page. When a librarian creates or edits a digital resource, they see a Tags section with an input field and an Add button. Typing a tag name and clicking Add sends it to the server, which checks for duplicates and saves it. The tag appears in a list below the input, each with a delete button. Deleting a tag removes it immediately. Bulk operations allow selecting multiple tags and removing them together. The entire interaction happens without page reloads, using AJAX.

---

## Validate Before Save

**Single Tag Add (`store()`):**
1. **`tag_name`:** required, string, max:100
2. **Duplicate Check:** The system checks if a tag with the same name already exists for this resource. If so, returns 422 with "This tag already exists for this resource."

**Bulk Delete (`bulkDestroy()`):**
1. **`tag_ids`:** required, array
2. **`tag_ids.*`:** must exist in `lib_digital_resource_tags.id`

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| Tag name required | "The tag name field is required." |
| Tag name too long | "The tag name must not exceed 100 characters." |
| Duplicate tag | "This tag already exists for this resource." (422) |
| Resource not found | 404 — "Resource not found" |
| Tag not found | 404 — "Tag not found" |
| Invalid tag IDs for bulk delete | "The selected tag ids are invalid." |

---

## Success Scenarios

1. A librarian adds tags "interactive", "video-lecture", "class-10" to a digital resource. Each tag is created via AJAX and appears in the list instantly. The resource becomes searchable by these tags on the member portal.
2. A librarian deletes a single outdated tag from a resource. The tag is soft-deleted and removed from the list.
3. A librarian selects 5 tags and uses bulk delete to remove them all at once. All 5 tags are soft-deleted in a single query.

---

## Failure Scenarios

1. A librarian tries to add a tag that already exists for the same resource. The server returns a 422 error with message "This tag already exists for this resource." The UI shows the error without creating a duplicate.
2. A librarian tries to add a tag to a deleted digital resource. The `findOrFail` call returns a 404 error.
3. A network failure occurs during AJAX tag addition. The tag is not created, and the UI shows an error notification. The librarian retries the action.

---

## User-Defined Tags Detail (from Lib_Conditions.md Section 4.6)

### Business Rules

1. **Tags user-defined hain** — koi predefined list nahi hai. Jo chahe woh tag daal sakte hain.
2. **Ek resource par ek tag sirf ek baar** assign ho sakta hai. Duplicate nahi.
3. **Tag length:** Max 100 characters.
4. **Tag resource ke saath delete hoga** — jis resource ke tags hain, woh resource delete hua to uske saare tags bhi apne aap delete ho jayenge (`ON DELETE CASCADE`).
5. **Soft Delete:** Tags delete karte hain to record delete nahi hota — sirf `deleted_at` set hota hai (recoverable).

### FK Cascade Behavior

- `digital_resource_id` → `lib_digital_resources(id)` — `ON DELETE CASCADE`
- Jab parent digital resource force-delete hota hai, saare child tags apne aap delete ho jate hain.
- Koi orphan record nahi bachega.

### Management Flows

**Inline (CRUD Create/Edit Form):**
- Digital Resource create/edit karte waqt, form mein tags add/remove kar sakte hain.
- Tags provided as JSON array string in the form → converted to individual `LibDigitalResourceTag` records on store/update.
- On update with no tags provided, all existing tags are deleted.
- JS-driven input hai — type karte gaye, add hota gaya.

**Dedicated Tag Management Page:**
- Alag se tag management page bhi hai jahan sirf tags handle kar sakte hain.
- AJAX-based single tag add via `LibDigitalResourceTagController@store()`.
- AJAX-based single tag delete via `LibDigitalResourceTagController@destroy()`.
- AJAX-based bulk delete via `LibDigitalResourceTagController@bulkDestroy()`.

**Search:**
- Tag name se search kiya ja sakta hai.

---

## Dependencies module and tables

| Module | Tables |
|---|---|
| Library Core | `lib_digital_resource_tags` (primary, soft-deletes via `deleted_at`) |
| Library Digital Resources | `lib_digital_resources` (FK `digital_resource_id` CASCADE — tags deleted with parent resource) |
