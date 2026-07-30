# Schedule Classes — Business Requirements

## What This Screen Does

The Schedule Classes screen manages the mappings that link marksheet schedules to specific class sections. Each mapping represents a single assignment: a given class section (e.g., Grade 10 Section A) will have its report cards computed under a specific marksheet schedule (e.g., "Term 1 Final 2026"). This relationship allows a single schedule to cover multiple class sections, and tracks which sections have been processed under which schedule.

While class section assignment is primarily handled during schedule setup, this tab provides a standalone interface for directly inspecting, adding, editing, and removing individual class section assignments. This is useful for verifying mappings and making targeted changes without needing to edit the entire schedule.

The screen appears in the following contexts:
1. **Scheduling Hub → Schedule Classes tab** — Displays a list of all schedule-class mappings, showing schedule name, class section name, and active status.
2. **Modal-Based CRUD** — Inline modals on the scheduling page used to link class sections, update mappings, toggle active status, and delete mappings.

---

## Default Data Load

When the user opens the Scheduling Hub and selects the Schedule Classes tab, the system runs a query in the background that retrieves all schedule-class mappings, paginated at 15 records per page, using a specific page indicator for schedule classes. The query pre-loads references to the marksheet schedule and class section to display in the table.

Shared dropdown lists containing active schedules (excluding locked schedules) and active class sections are loaded for the modals.

---

## When This Screen Is Used

*   **Mapping Audits** — After creating a schedule, the coordinator inspects this list to verify that all intended class sections are correctly linked.
*   **Targeted Adjustments** — When a single class section needs to be added to or removed from a schedule after it has been created, the coordinator uses this screen to update the mapping directly.
*   **Troubleshooting Missing Results** — If a student's report card is missing, the admin checks this screen to confirm if their class section is mapped to the active schedule.

---

## Key Fields at a Glance

**Schedule and Class Binding**
*   **Marksheet Schedule** — The schedule to map the class section to.
*   **Class Section** — The specific class section (e.g., "Grade 10 - Section A").

**Status**
*   **Active Status** — A toggle to enable or disable the mapping. Disabling a mapping excludes that class section from calculations when the marksheet computation runs.

---

## Business Rules and Conditions

**Unique Mapping (BR-MSG-025)**
A specific class section can only be linked to a specific schedule once, preventing duplicate results calculation.

**Locked Schedule Guard (BR-MSG-026)**
No class section mappings can be added or updated for schedules that are locked. The creation dropdown only displays unlocked schedules.

**Deletion Restrictions (BR-MSG-027)**
A schedule-class mapping cannot be deleted if marksheet calculations have already run and generated student results for that class section under the schedule.

---

## Workflow Steps

**Mapping a Class Section to a Schedule**
It is the start of the term. The Examination Coordinator, Mr. Sharma, opens the Scheduling Hub and selects the Schedule Classes tab. He clicks "Add Schedule Class" to open the mapping modal. Mr. Sharma selects Schedule "Term 1 Final 2026" (which is unlocked), selects Class Section "Grade 10 - Section C", and toggles Active to Yes. He clicks Save. The system validates uniqueness, saves the mapping, and refreshes the list.

**Disabling a Mapping Temporarily**
One class section's grades are delayed. Mr. Sharma locates the mapping for "Grade 10 - Section B" under the active schedule, and toggles the active switch to No. The mapping is disabled, and when the calculation job runs, Grade 10 Section B is skipped, allowing other classes to compile without delay.

---

## Example Scenario

Greenwood International School has a schedule "Term 1 Final 2026". The coordinator, Mrs. Desai, needs to map the classes. She maps:
*   "Term 1 Final 2026" mapped to 10-A.
*   "Term 1 Final 2026" mapped to 10-B.

She notices 10-C is missing. Instead of editing the schedule setup, she uses the Schedule Classes tab's Create modal to link 10-C directly.

---

## Related Screens

*   **Marksheet Schedules** — The parent schedule defining grading templates and lifecycle.
*   **Student Results** — Displays computed grades for mapped classes.
