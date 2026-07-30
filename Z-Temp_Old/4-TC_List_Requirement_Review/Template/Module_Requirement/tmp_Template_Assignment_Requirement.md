# Template Scope Assignment — Business Requirements

## What This Screen Does

The Template Scope Assignment screen is where school administrators link an active template (such as a marksheet or report card layout) to a specific purpose for a given academic session. It determines which template gets used by whom — a single template can be assigned to a particular class, a whole class group, or the entire school.

The screen supports three scope levels with a clear priority system: a **Specific Class** assignment takes highest priority, a **Class Group** assignment comes second, and a **School-Wide** assignment serves as the fallback. This means the system picks the most specific match when deciding which template to apply. Administrators can create new assignments, edit existing ones, toggle them on or off, and remove or restore them.

---

## When This Screen Is Used

- **Creating a New Assignment** — When a school wants a specific template to be used for a purpose (e.g., "Annual Marksheet") in a given session
- **Editing an Assignment** — When the template, scope, or target needs to change for an existing assignment
- **Toggling Status** — To quickly enable or disable an assignment without deleting it
- **Removing and Restoring** — To temporarily remove an assignment from view or reinstate it from trash
- **Managing Template Replacements** — When a new version of a template is created and needs to replace the old one for specific classes or groups

---

## Who Can Access This Screen

- **School Admin** — Full access including create, edit, toggle status, remove, and restore
- **Academics Manager** — Can view and create assignments for academic purposes
- **Principal** — Read-only access to view current assignments
- **Clerk** — Can view assignments but cannot make changes

The system checks the user's permissions before every action to ensure only authorised staff can perform each operation.

---

## How This Screen Works — Step by Step

### The Assignment List

When an administrator opens Template Scope Assignment, the system shows a list of all assignments (20 per page) with columns: Purpose, Template, Academic Session, Scope Type, Scope Target, Status toggle, and Actions (View, Edit, Delete). A filter panel above the list lets administrators narrow down by Purpose, Academic Session, Scope Type, and Active/Inactive status.

The list shows only active assignments by default. A separate "Trash" tab shows removed records.

### Creating an Assignment

When the administrator clicks "Assign Template," they see a form with the following fields:

**Selection Fields:**
- Purpose (required, chosen from a predefined list such as Annual Marksheet, Progress Report, etc.)
- Academic Session (required, chosen from the list of active sessions)
- Template (required, only active templates are shown in the dropdown)

**Scope Selection (Mutually Exclusive Groups):**
- **School-Wide:** Checkbox for school-wide assignment. When selected, the class and class group selectors are disabled. The scope identifier is set to "SCHOOL".
- **Class Group:** Dropdown of class groups (e.g., Primary School, Middle School, High School). When a group is selected, any previously selected class is cleared. The scope identifier is set to "G" followed by the group ID (e.g., "G2").
- **Specific Class:** Dropdown of classes (e.g., Class 10A, Class 10B). When a class is selected, any previously selected class group is cleared. The scope identifier is set to "C" followed by the class ID (e.g., "C5").

**Status:**
- Active toggle (defaults to Active)

When the administrator clicks "Save," the system checks all fields, computes a unique scope hash in the format "purposeId:sessionId:C5" (class), "purposeId:sessionId:G2" (group), or "purposeId:sessionId:SCHOOL" (school-wide), verifies that no duplicate assignment exists for the same purpose+session+scope combination, creates the assignment, and returns to the list with a success message.

### Editing an Assignment

The edit form opens with all existing values pre-filled. The administrator can change the template, scope type, scope target, or status. If the scope type is changed from class to group, the class selection is cleared and vice versa. If school-wide is selected, both class and group selections are cleared and disabled.

### Viewing Assignment Details

The detail view shows the full assignment profile in a structured layout:
- **Purpose & Session Card:** Purpose name, academic session
- **Template Card:** Template name with an indicator showing whether the template is currently active
- **Scope Card:** Scope type (Class / Class Group / School-Wide), scope target name and identifier
- **Scope Hash:** The computed unique hash for the assignment
- **Status:** Active or Inactive badge
- **Activity Log:** Timestamped log of all changes made to this assignment

### Removing and Restoring

When an administrator removes an assignment, the record is soft-deleted — hidden from the main list but retained in the system. The administrator can restore the assignment from the Trash page. However, restoring does NOT reactivate the assignment; it simply brings it back to the main list in an inactive state. The administrator must manually toggle it to Active if needed.

### Toggle Status

Administrators can turn an assignment's active status on or off directly from the list view without reloading the page. Each change is saved with a timestamp. Inactive assignments are not used by the system when resolving which template to apply.

---

## Validation Rules — What's Required Before Saving

### Selection Fields:

| Field | Rule |
|-------|------|
| Purpose | Required, must be a valid option from the predefined purpose list |
| Academic Session | Required, must be a valid active session |
| Template | Required, must be an active template (inactive templates are excluded from the dropdown) |

### Scope Fields:

| Field | Rule |
|-------|------|
| School-Wide | Optional; if selected, class and class group must not be selected |
| Class Group | Optional; cannot be set if a class is already selected |
| Specific Class | Optional; cannot be set if a class group is already selected |
| Scope Uniqueness | The combination of purpose + session + scope must be unique — no duplicate assignments allowed |

### Status:

| Field | Rule |
|-------|------|
| Active | Optional, can be Yes or No. When a template is soft-deleted, its assignments are set to Inactive. |

---

## Business Rules and Conditions

### Rule BR-TSA-001: One Template Per Purpose+Session+Scope
The combination of purpose, academic session, and scope (class/group/school-wide) must be unique. If an assignment already exists for Class 10A with purpose "Annual Marksheet" in session "2025-26", the system rejects any attempt to create a second assignment with the same scope. The scope hash is used to enforce this uniqueness.

### Rule BR-TSA-002: Only Active Templates Can Be Assigned
The template dropdown shows only templates with Active status. Inactive or soft-deleted templates are excluded. If an administrator tries to assign a template that has been deactivated between opening the form and saving, the system rejects the save.

### Rule BR-TSA-003: Class and Class Group Cannot Both Be Set
The scope selection is mutually exclusive between class and class group. Selecting a class automatically clears any selected class group, and selecting a class group automatically clears any selected class. This is enforced both in the user interface and at the server level.

### Rule BR-TSA-004: School-Wide Purposes Cannot Have Class or Group
When the school-wide scope is selected, the system disables the class and class group selectors. If an administrator attempts to set both school-wide and a class or group, the system rejects the save.

### Rule BR-TSA-005: Soft-Delete of Template Cascades to Assignments
When a template is soft-deleted, all its existing assignments are automatically set to Inactive. The assignments are not deleted — they remain visible but become inactive. When the template is restored, the assignments are NOT automatically reactivated; an administrator must manually toggle each one.

### Rule BR-TSA-006: Restore Does Not Reactivate
Restoring a removed assignment from the Trash brings the record back to the main list but sets it to Inactive. The administrator must explicitly toggle the status to Active for the assignment to take effect again.

### Rule BR-TSA-007: Scope Priority Determines Template Resolution
When the system needs to determine which template applies to a student, it checks assignments in priority order: Specific Class first, then Class Group, then School-Wide. For example, if Class 10A has a direct assignment and also belongs to the "High School" group which has a group-level assignment, the class-level assignment takes precedence.

### Rule BR-TSA-008: Scope Hash Is Computed Automatically
The system generates a unique scope hash when an assignment is created or its scope changes. The format is "purposeId:sessionId:scopeIdentifier" where scopeIdentifier is "C{id}" for class, "G{id}" for group, or "SCHOOL" for school-wide. This hash is used for duplicate detection and is displayed in the assignment details.

### Rule BR-TSA-009: All Changes Are Tracked
Every operation — create, edit, remove, restore, toggle status — is recorded with a timestamp. Each entry captures who did it, what action was taken, and a description of the change.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| BR-TSA-001 | One template per purpose + session + scope combination |
| BR-TSA-002 | Only active templates appear in the dropdown |
| BR-TSA-003 | Class and class group selections are mutually exclusive |
| BR-TSA-004 | School-wide scope cannot be combined with class or group |
| BR-TSA-005 | Deleting a template deactivates all its assignments |
| BR-TSA-006 | Restoring an assignment does not reactivate it |
| BR-TSA-007 | Class > Class Group > School-Wide in priority |
| BR-TSA-008 | Scope hash is auto-generated for uniqueness |
| BR-TSA-009 | All changes recorded with user and timestamp |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Purpose not selected | "The purpose field is required." |
| Invalid purpose | "The selected purpose is invalid." |
| Session not selected | "The academic session field is required." |
| Invalid session | "The selected academic session is invalid." |
| Template not selected | "The template field is required." |
| Inactive template selected | "The selected template must be active." |
| Duplicate assignment | "An assignment already exists for this purpose, session, and scope." |
| Both class and group selected | "A class and a class group cannot both be set. Please choose one." |
| School-wide with class or group | "School-wide assignment cannot have a class or class group." |
| Neither scope selected | "Please select a scope: school-wide, a class group, or a specific class." |
| Template soft-deleted — assignment inactive | "The template has been removed. The assignment has been set to inactive." |
| Invalid scope type | "The selected scope type is invalid." |
| Toggle — record not found | "Assignment not found." |
| Restore — record not in trash | "The assignment is not in the trash and cannot be restored." |

---

## Success Scenarios

- An administrator creates a new assignment: Purpose = "Annual Marksheet", Session = "2025-26", Template = "Marksheet v2", Scope = Specific Class "10A". The system generates the scope hash "annual_marksheet:2025-26:C5", verifies no duplicate exists, creates the assignment as Active, and returns to the list with a success message.

- An administrator edits an existing assignment changing the scope from Class "10A" to Class Group "High School". The system clears the class selection, updates the scope hash to "annual_marksheet:2025-26:G2", checks for duplicates, saves the change, and logs the modification.

- An administrator toggles an assignment from Active to Inactive via the list toggle. The assignment's status is set to Inactive. The system stops using this assignment when resolving templates. A timestamped record is created.

- An administrator removes an assignment with no issues. The assignment disappears from the main list but appears in the Trash tab. The administrator later restores the assignment — all original data is reinstated but the status is set to Inactive.

---

## Failure Scenarios

- An administrator tries to create an assignment for Class "10A" with purpose "Annual Marksheet" in session "2025-26", but an identical assignment already exists. The system rejects with "An assignment already exists for this purpose, session, and scope."

- An administrator selects Class Group "Primary School" and then selects Class "1A". The system clears the class group selection because class and class group cannot both be set.

- An administrator selects School-Wide scope but also tries to select a class. The class selector is disabled and the system prevents the combination.

- An administrator tries to assign a template that was soft-deleted earlier. The template does not appear in the dropdown at all.

- An administrator restores an assignment from the Trash expecting it to work immediately. The assignment reappears in the list but with Inactive status. The administrator must manually toggle it to Active.

- An administrator's template is soft-deleted by another user. All assignments linked to that template are automatically set to Inactive. The assignments remain visible but stop being used by the system.

---

## Example Scenario

Mrs. Sharma, the School Admin of Green Valley Academy, needs to set up templates for the new academic session 2025-26.

She navigates to Template Scope Assignment and clicks "Assign Template":

1. **Selection:** She selects Purpose = "Annual Marksheet", Session = "2025-26", Template = "Marksheet v2" (an active template).

2. **Scope:** She chooses "Specific Class" and selects "10A" from the class dropdown. The scope identifier is set to "C5" (where 5 is the internal ID for Class 10A).

3. **Status:** She leaves the Active toggle ON.

4. She clicks "Save". The system computes the scope hash "annual_marksheet:2025-26:C5", checks that no duplicate exists for this purpose+session+scope, creates the assignment as Active, and returns to the list showing the new entry with scope type "Class", scope target "10A".

Next, she wants all classes in the Primary School group to use "Marksheet v1". She creates another assignment:

1. **Selection:** Purpose = "Annual Marksheet", Session = "2025-26", Template = "Marksheet v1".
2. **Scope:** She selects "Class Group" and chooses "Primary School". The scope identifier is set to "G2".
3. She saves. The system creates the assignment.

Finally, she sets up a school-wide fallback. She creates a third assignment:

1. **Selection:** Purpose = "Annual Marksheet", Session = "2025-26", Template = "Default Marksheet".
2. **Scope:** She checks "School-Wide". The class and group selectors become disabled. The scope identifier is set to "SCHOOL".
3. She saves.

Now when the system generates marksheets for session 2025-26:
- Class 10A gets "Marksheet v2" (class-level, highest priority)
- Other classes in Primary School get "Marksheet v1" (group-level)
- All remaining classes get "Default Marksheet" (school-wide fallback)

Later, Mrs. Sharma decides to disable the Primary School group assignment. She finds it in the list and toggles the status to Inactive. The assignment remains in the list but is no longer applied. Classes in Primary School now fall through to the school-wide "Default Marksheet" template.

---

## Related Screens

- **Template Master** — Where templates are created, edited, and activated or deactivated
- **Purpose Master** — Where purpose options are managed
- **Academic Session Management** — Where academic sessions are created and managed
- **Class Management** — Where classes and class groups are defined
- **Report Generation** — Where the assigned templates are actually applied to generate documents

---

## How Other Parts of the System Depend on This Screen

| Area | What It Needs From Template Scope Assignment |
|------|---------------------------------------------|
| **Template records** | Determines which template is active for each purpose, session, and scope |
| **Report generation** | Uses assignment data to resolve the correct template when generating student reports |
| **Marksheet generation** | References assignments to pick the right marksheet layout for each class |
| **Progress reports** | Uses assignments to determine which progress report template applies |
| **Change history** | All assignment changes are recorded with timestamps for audit |
| **Class and group hierarchy** | Relies on class and class group definitions for scope resolution |
| **Template lifecycle** | When a template is deactivated, the system cascades the change to its assignments |
