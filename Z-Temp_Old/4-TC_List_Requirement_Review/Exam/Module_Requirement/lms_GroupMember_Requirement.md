# [Group Members] Master Tab Screen

---

## What Does This Screen Do?

The Group Members screen is where you actually put students into the groups you created on the Student Groups screen. Think of it like this: the Student Groups screen creates the empty containers (like "Class 9-A Group SET-A"), and this screen is where you pick which specific students sit inside each container.

A group starts empty — no students. The Admin or Exam Coordinator comes to this screen, selects which group they want to work with, picks a class and section to narrow down the student list, checks off the students they want to add, and submits. The system only adds students who are NOT already in that group, skipping duplicates automatically.

This is a many-to-many relationship: one group can have many students, and one student can belong to many different groups, but the same student cannot be added to the same group twice.

---

## Real-Life Example

Mrs. Patel, the Exam Coordinator at Green Valley Academy, just created a group called "Class 9-A, Group SET-A" on the Student Groups screen. Now she needs to put students into it.

She opens the Masters tab, selects the fourth sub-tab "Group Members", clicks "Add Member", picks "Class 9-A, Group SET-A" from the group dropdown. The system automatically locks the class to "9" and section to "A" (because this group was created for Class 9, Section A). It also grays out any students already in the group so she doesn't select them by mistake.

She sees 40 students listed (paginated 50 per page), checks the 20 students who should be in SET-A, and clicks Submit. The system tells her "20 members added successfully."

Later, a student transfers out of the school. Mrs. Patel comes back, finds that student in the group, and clicks Delete. The system first checks whether this group has been allocated to any exam — if it has, the student cannot be removed because the allocation depends on the group membership being stable.

---

## How the List Page Works

The Group Members index is the fourth sub-tab inside the Masters tab (`active_tab=exam_student_group_member`). Unlike most other list pages, it starts COMPLETELY EMPTY — the user MUST apply at least one filter before any results appear. This is because every school has hundreds of group members and showing them all at once would be overwhelming.

### Filters Available
- **Group** — Select a specific student group to see its members
- **Student** — Search for a specific student across all groups
- **Exam** — Filter by exam (if you want to see members of groups allocated to a particular exam)
- **Class** — Filter by class (shows members of groups that belong to that class)

### What Each Row Shows
- **Student Name** — The student's full name
- **Group Name** — Which group this student belongs to
- **Class** — The class associated with the group
- **Status** — Active or Inactive toggle

The actual data-fetching query is managed by the Exam Query Service. When the user clicks a filter, an AJAX request re-loads the filtered list. The list is paginated at 10 rows per page.

### Trash Page
A separate Trash page shows soft-deleted members. From there, you can Restore (bring back) or Force Delete (permanently remove) group members, provided usage checks pass.

---

## How to Create (Add Members)

**Step 1:** From the Masters tab, click the "Group Members" sub-tab, then click "Add Member".

**Step 2:** Select a Group from the dropdown. The system sends an AJAX request to get the group's class and section details.

**Step 3:** Once you select a group:
- If the group already has a class assigned, the system locks the class dropdown to that class.
- If the group already has a section assigned, the system locks the section dropdown to that section.
- The system fetches the list of students who are ALREADY members of this group and keeps their IDs aside, so it can gray them out in the student selection list.

**Step 4:** The student list appears only after you select a group and optionally a class/section. It shows 50 students per page (paginated). Each student row has a checkbox.

**Step 5:** Check the students you want to add. Existing members are shown but grayed out so you cannot re-select them by mistake.

**Step 6:** Click Submit. The system loops through each selected student ID and:
1. Checks if that student is already a member of this group (checks the combination of group_id + student_id)
2. If NOT already a member, creates the record and logs the activity
3. If ALREADY a member, silently skips it (no error — the system just doesn't create a duplicate)

**Step 7:** After all students are processed, the system shows a success message like "5 members added successfully" and redirects back to the Group Members list.

### Important Note on Validation
The "create" form uses a plain Request (not the FormRequest), which means `student_ids` (the array of selected students) is NOT validated by the FormRequest. Duplicate checking is done manually in the controller's store logic. The FormRequest is only used for the "edit/update" flow.

---

## How to Edit/Delete

### Editing a Single Group Member
You can edit an individual member record (change which group they belong to or which student). However, before the edit form even opens, the system checks whether this member's group has been allocated to any exam.

**Usage Check Logic (Critical):**
The `ExamStudentGroupMemberUsageCheckService` looks at the `lms_exam_allocations` table. If the member's `group_id` appears in any exam allocation record, editing is blocked. This is because changing group members after allocation would break the exam's student roster.

If blocked: "Cannot edit this member because the group is allocated to exams."
If allowed: The edit form opens with the current group and student pre-selected.

When saving an edit, the system:
1. Re-checks usage (in case it changed)
2. Checks that the new group+student combination doesn't already exist in another member record (duplicate check using the FormRequest's unique rule with `ignore($memberId)`)
3. Updates the record, logs the changes, and redirects with success

### Deleting (Soft Delete)
Clicking Delete does the same usage check first. If the group is allocated to exams, deletion is blocked. If not, the record is soft-deleted (a `deleted_at` timestamp is set, but the record stays in the database) and the activity is logged.

### Restoring from Trash
Same usage check applies. If the group is still allocated to exams, restore is blocked. If allowed, the soft-delete is reversed.

### Permanent Delete (Force Delete)
Available only from the Trash page. Same usage check. If passed, the record is permanently removed from the database with NO recovery possible.

### Toggle Active Status (AJAX)
There is a toggle switch for each member that changes their `is_active` status. This works via AJAX — clicking toggles the active/inactive state without a full page reload. No usage check is performed for the toggle — it is always allowed.

---

## Business Rules Summary

| # | Rule | Details |
|---|------|---------|
| 1 | **Unique Student per Group** | A student can only be in a specific group once. Duplicate group_id + student_id is rejected. |
| 2 | **Bulk Addition Skips Duplicates** | When adding multiple students at once, the system checks each one individually. Existing members are silently skipped, not errored. |
| 3 | **Usage Block: Group Allocated to Exams** | If the member's group appears in any exam allocation (lms_exam_allocations), editing, deleting, restoring, and force-deleting individual members is blocked. |
| 4 | **Usage Block NOT on Toggle** | The Active/Inactive toggle does NOT check usage — it is always allowed regardless of allocation status. |
| 5 | **Soft Delete Only** | Delete sends the record to trash (soft-delete). It can be restored. |
| 6 | **Force Delete is Permanent** | From the Trash page, you can permanently remove a record with no recovery. |
| 7 | **Group's Class/Section is Forced** | When creating members, if the selected group has a fixed class and/or section, those are locked and cannot be changed in the create form. |
| 8 | **Load-on-Demand Student List** | The student list only appears after selecting a group and class/section. It does not load beforehand. |
| 9 | **is_active is NOT in Model Fillable** | The model's `$fillable` array does NOT include `is_active`, but the toggleStatus method still saves it directly on the model instance. |
| 10 | **Transactions Used on All Mutations** | Every create, update, delete, restore, force-delete, and toggle operation is wrapped in a database transaction. |

### What "Usage Check" Actually Checks
The usage check service finds the member's record by ID, gets its `group_id`, then queries the `lms_exam_allocations` table to see if that `group_id` is referenced as `exam_group_id`. If even one allocation exists, the member is considered "in use" and all destructive operations are blocked.

---

## Validation & Error Messages

| Scenario | Message | When |
|----------|---------|------|
| Group not selected | "Group is required" | Create form validation |
| Student not selected | "Student is required" | Create/Edit form validation |
| Duplicate student in group | "This student is already a member of this group" | When adding a student already in the group |
| Edit blocked (group allocated) | "Cannot edit this member because the group is allocated to exams." | Controller usage check on edit()/update() |
| Delete blocked (group allocated) | "Cannot delete this member because the group is allocated to exams." | Controller usage check on destroy() |
| Restore blocked (group allocated) | "Cannot restore this member because the group is allocated to exams." | Controller usage check on restore() |
| Force delete blocked | "Cannot permanently delete this member because the group is allocated to exams." | Controller usage check on forceDelete() |
| DB failure on create | "Failed to add exam group members. Please try again." | Exception catch block |
| DB failure on update | "Failed to update exam group member. Please try again." | Exception catch block |
| DB failure on delete/restore/force | "Failed to [action] exam group member. Please try again." | Exception catch blocks |
| Toggle failure | "Failed to update status." | AJAX error response |
| Group not found (AJAX) | "Group not found" | getGroupDetails AJAX returns error |

---

## Activity Log Messages

Every action is recorded in the activity log:
- **Created**: "Student added to exam group"
- **Updated**: "Exam group member was updated."
- **Trashed**: "Exam group member was removed."
- **Restored**: "Exam group member was restored."
- **Force Deleted**: "Exam group member was permanently deleted."
- **Toggled**: "Exam group member status was updated."

---

## AJAX Endpoints

| Endpoint | Purpose | Returns |
|----------|---------|---------|
| `getGroupDetails` | When user selects a group in create form | Group's class, section, and any forced selections |
| `toggleStatus` | Toggle active/inactive | JSON success with new is_active value |

---

## Permissions

| Gate | Methods | What It Allows |
|------|---------|----------------|
| `tenant.exam-group-member.viewAny` | index() | View the members list |
| `tenant.exam-group-member.view` | show() | View a single member's details |
| `tenant.exam-group-member.create` | create(), store() | Open add form and add members |
| `tenant.exam-group-member.update` | edit(), update(), toggleStatus() | Edit, update, and toggle status |
| `tenant.exam-group-member.delete` | destroy() | Soft-delete members |
| `tenant.exam-group-member.restore` | trashed(), restore() | View trash and restore |
| `tenant.exam-group-member.forceDelete` | forceDelete() | Permanent delete |

---

## Related Screens

- **Student Groups** — Defines the containers that hold group members
- **Exam Allocation** — Uses student groups (and by extension, their members) to assign papers
- **Masters Tab** — This screen is the fourth sub-tab in the Masters tab

---

## Technical Implementation Details

### Database Table: `lms_exam_student_group_members`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| group_id | INT UNSIGNED FK | References `lms_exam_student_groups.id` |
| student_id | INT UNSIGNED FK | References `std_students.id` |
| is_active | TINYINT(1) | Toggle status (not in $fillable but can be set directly) |
| created_at / updated_at / deleted_at | TIMESTAMP | Soft deletes via Laravel |

**Unique Constraint:** `(group_id, student_id)` — prevents duplicate membership at the database level.

### Data Loading Architecture
Unlike simple CRUD pages where the controller directly queries and paginates, the Group Members list gets its data through a layered architecture:
1. `ExamStudentGroupMemberController@index()` — Only passes filter parameters to the view; does NOT execute any database query
2. The actual query is built by `ExamQueryService@examStudentGroupMembersQuery()` which:
   - Joins with the `group` relationship to access group data
   - Joins with `student.user` relationship to access student names
   - Filters by group_id, student_id, class_id (via group's class)
   - Has a comprehensive search across student names, admission numbers, user names/emails, group names/codes, and class names
3. The query is executed in `LmsExamController@masters()` only when `active_tab=exam_student_group_member`

### AJAX: getGroupDetails Endpoint
When the user selects a group in the create form, an AJAX call fetches:
- The group's class (or all classes if group has no fixed class)
- The group's section (or all sections if group has no fixed section)
- The selected class_id and section_id (to pre-select in dropdowns)
- If the group is not found, returns: `{status: "error", message: "Group not found"}`

This endpoint is critical for the "class/section forced by group" behavior.

### The Store Flow (Bulk Add)
1. The `store()` method receives the form data (group_id + student_ids array)
2. It uses a plain `Request` object (NOT the FormRequest), so `student_ids` array is NOT validated
3. It wraps everything in a database transaction
4. For each student_id in the array:
   - Checks if a record with (group_id, student_id) already exists
   - If not, creates the record and logs activity
   - If yes, silently skips
5. After the loop, commits the transaction
6. Returns success with count: "X members added successfully."
7. On any exception, rolls back the transaction and shows error

### The ToggleStatus Endpoint
- Accepts POST with `is_active` (required, must be 0 or 1)
- Finds the member or returns 404
- Sets `is_active` directly on the model (even though it's not in $fillable)
- Saves and logs "Exam group member status was updated."
- Returns JSON: `{success: true, is_active: 1/0, message: "..."}`
- On failure, returns 500 JSON: `{success: false, message: "Failed to update status."}`

### Usage Check Service Details
The `ExamStudentGroupMemberUsageCheckService`:
1. Takes a member ID
2. Finds the member record
3. Gets the member's `group_id`
4. Counts how many `ExamAllocation` records have `exam_group_id` = that group_id
5. If count > 0, the member is "in use"

This means usage is checked at the GROUP level, not the individual member level. If the GROUP is allocated, ALL its members are locked.

### Transaction Handling
Every mutation method uses DB::beginTransaction() / DB::commit() / DB::rollBack():
- store() — wraps the entire bulk-insert loop
- update() — wraps validation + save
- destroy() — wraps deactivation + soft-delete
- restore() — wraps restore + reactivation
- forceDelete() — wraps force delete
- toggleStatus() — wraps save + log

This ensures data integrity — if any part fails, the entire operation is rolled back.
