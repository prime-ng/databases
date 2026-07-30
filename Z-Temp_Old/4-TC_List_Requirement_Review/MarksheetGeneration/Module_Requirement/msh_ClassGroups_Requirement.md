# Class Groups — Business Requirements

## What This Screen Does

The Class Groups screen defines logical clusters of school classes that frequently share the same marksheet configuration. Rather than assigning a configuration template individually to each class section (such as Class 6A, Class 6B, Class 7A, etc.), the school can bundle classes with identical grading requirements into a Class Group — for example, "Primary (1-5)" or "Secondary (9-10)".

This screen transforms a chaotic collection of individual class sections into organised academic sections that inherit standard grading policies. Without class groups, the school's Examination Coordinator would have to manually assign weightages, passing percentages, and co-scholastic categories to dozens of class sections individually. This would not only be time-consuming but also prone to human error, resulting in inconsistent report cards across different sections of the same grade. By establishing class groups, the school ensures that all classes within a specific section band follow identical evaluation protocols.

The screen appears in the following contexts:
1. **Configuration Hub → Class Groups tab** — A tabbed interface displaying a paginated table of class groups with their code, name, description, active status, and number of assigned classes.
2. **Modal-Based CRUD** — Pop-up modals used to create, edit, restore, toggle status, and permanently delete class groups directly from the hub page.

---

## Default Data Load

When the user navigates to the Configuration Hub and selects the Class Groups tab, the system runs a query in the background that retrieves all class groups, paginated at 15 records per page, using a specific page indicator for class groups. The query pre-loads all linked class sections so the count of assigned classes can be displayed in the list.

A master list of all active school classes is loaded and shared with the creation and edit modals so the user can easily select the classes that should belong to the group.

---

## When This Screen Is Used

*   **Initial School Setup** — During the initial setup of the marksheet system, the Examination Coordinator establishes the core academic sections (such as Primary, Middle, Secondary, and Senior Secondary). This sets the foundation for template assignments.
*   **Academic Year Transition** — At the start of a new school year, the coordinator reviews the class groups to add new classes or retire old ones, ensuring the mappings are ready for the new session.
*   **Template Assignment** — When configuring a new marksheet template, the coordinator links the template to class groups rather than individual classes, allowing all member classes to automatically inherit the grading blueprint.
*   **Adding New Class Sections Mid-Year** — If the school opens a new section (e.g., Grade 5 Section C) mid-year, the coordinator edits the Primary Class Group to include the new section, immediately applying the correct report card rules to it.

---

## Key Fields at a Glance

**Identity and Display Settings**
Each class group is identified by a unique, short code (e.g., "PRIM_1_5") and a descriptive name (e.g., "Primary Section Grades 1 to 5"). A display order field (which must be a positive integer) controls the visual sorting sequence on dropdowns and lists, ensuring that "Primary" appears before "Secondary". An optional description field allows coordinators to note the group's purpose.

**Class Membership**
A selection list allows the coordinator to associate multiple school classes with the group. The system syncs these selections, ensuring that added classes are linked and removed classes are unlinked safely without leaving orphaned records.

**Status Toggle**
An active status toggle controls whether the class group is available for new marksheet templates. Inactive groups are hidden from template setup dropdowns.

---

## Business Rules and Conditions

**Strict Unique Code (BR-MSG-001)**
No two class groups can share the same code. The code must be globally unique across all groups to prevent mismatched template assignments.

**Junction Sync Integrity (BR-MSG-002)**
When a class group is created or updated, the system evaluates the selected classes. It links newly selected classes, unlinks removed classes, and restores previously unlinked classes if they are re-selected, keeping the system database clean.

**Cascade Protection on Deletion (BR-MSG-003)**
A class group cannot be permanently deleted if it is referenced by any active marksheet configuration templates. The system blocks the deletion and displays a message prompting the coordinator to remove the template assignments first.

**Status Gating (BR-MSG-004)**
Only active class groups appear as options when assigning class groups to marksheet templates. Inactive class groups are hidden.

---

## Workflow Steps

**Creating a New Class Group from Scratch**
It is the start of the school term. The Examination Coordinator, Mr. Sharma, opens the Configuration Hub and selects the Class Groups tab. He clicks "Add Class Group" to open a pop-up form. Mr. Sharma enters the code "SEC_9_10", the name "Secondary Section (9-10)", a brief description: _Covers CBSE Secondary curriculum for Grades 9 and 10_, sets the display order to 3, and selects "Grade 9" and "Grade 10" from the checkbox list. He clicks Save. The system validates the code is unique, saves the class group, links Grade 9 and Grade 10 to it, logs the creation in the system log, and refreshes the list where the new group appears. The group is now ready for marksheet template assignments.

**Editing a Class Group to Add a Class**
A month later, the school introduces Grade 10 Section C. Mr. Sharma locates "Secondary Section (9-10)" in the class groups list, clicks the Edit icon to open the pre-filled modal, checks "Grade 10 Section C" in the class list, and saves. The system updates the class group, maps the new section, and records the change in the system activity log.

**Deactivating a Class Group Temporarily**
During curriculum restructuring, a particular class group is paused. Mr. Sharma toggles the active switch next to the group in the list. The status updates instantly to Inactive, and the group is hidden from template assignment dropdowns. All historical class mappings are preserved while the group is inactive.

---

## Example Scenario

Greenwood International School organizes its curriculum into bands: Primary (1-5), Middle (6-8), and Secondary (9-10). The Examination Coordinator, Mrs. Desai, sets up three class groups:
1. **PRIM** — "Primary Group", display order 1, linked to Grades 1, 2, 3, 4, 5.
2. **MID** — "Middle Group", display order 2, linked to Grades 6, 7, 8.
3. **SEC** — "Secondary Group", display order 3, linked to Grades 9, 10.

Later, when Mrs. Desai creates the "Term 1 Report Card Template", she assigns it to the **PRIM** class group. The system automatically maps all sections of Grades 1 through 5 to this template, ensuring all primary students receive consistent report cards.

---

## Related Screens

*   **Config Templates** — Where marksheet templates are assigned to class groups.
*   **School Classes** — The source screen defining the classes that can be grouped.
*   **Configuration Hub** — The master screen housing the Class Groups tab.
