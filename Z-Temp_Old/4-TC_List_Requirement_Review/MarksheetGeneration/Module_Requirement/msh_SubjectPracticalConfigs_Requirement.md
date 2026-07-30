# Subject Practical Configs — Business Requirements

## What This Screen Does

The Subject Practical Configs screen defines which subjects in a class carry a practical examination component and specifies how the maximum marks are divided between the written theory paper and the practical exam. Many subjects (such as Physics, Chemistry, Biology, and Computer Science) require both written theory and hands-on practical evaluations. This screen allows the school to configure that split per subject, class, and academic session.

Without this configuration, the system would assume that every subject is 100% theory-based. By defining a practical configuration, the system knows to pull practical marks from a separate internal assessment workflow and cap theory marks at the configured theory maximum. This ensures that the final calculated results are accurate.

The screen appears in the following contexts:
1. **Scheduling Hub → Practical Configs tab** — A tabbed interface displaying a paginated table of configurations with their session, class, subject, and mark splits.
2. **Modal-Based CRUD** — Inline modals on the scheduling page used to create, edit, restore, toggle status, and delete configurations.

---

## Default Data Load

When the user opens the Scheduling Hub and selects the Practical Configs tab, the system runs a query in the background that retrieves all configurations, paginated at 15 records per page, using a specific page indicator for practical configurations. The query pre-loads references to the school class and subject to display in the table.

Shared dropdown lists containing active classes, active subjects, and active academic sessions are loaded for the modals.

---

## When This Screen Is Used

*   **Academic Session Setup** — At the start of a school year, the coordinator defines which subjects have practical components and sets their marks splits.
*   **Curriculum updates** — If the board revises the mark distribution for a subject (e.g., changing Physics from a 70/30 split to 80/20), the coordinator updates the configuration.
*   **Adding New Practical Subjects** — When the school introduces a new practical course, the coordinator configures it in this list.

---

## Key Fields at a Glance

**Academic and Subject Context**
*   **Academic Session** — The school year (e.g., "2026-27").
*   **School Class** — The class level (e.g., "Grade 11").
*   **Subject** — The academic subject (e.g., "Physics").

**Marks Distribution**
*   **Has Practical** — A checkbox/toggle indicating whether the subject has a practical component.
*   **Theory Max Marks** — The maximum possible written exam score. Must be 0 or greater.
*   **Practical Max Marks** — The maximum possible practical exam score. Must be 0 or greater.

---

## Business Rules and Conditions

**Unique Configuration Triplet (BR-MSG-042)**
No two configurations can exist for the same subject in the same class and academic session.

**Status Gating (BR-MSG-043)**
Only active practical configurations are used during marksheet calculations. Inactive configurations are ignored.

**Deletion Safety (BR-MSG-044)**
A practical configuration cannot be permanently deleted if it is referenced by computed student results. The system blocks the deletion.

**Soft Deletion (BR-MSG-045)**
Deleting a configuration soft-deletes the record (moves it to trash), from where it can be restored (which automatically makes it active again) or permanently deleted.

---

## Workflow Steps

**Configuring a Practical Mark Split**
It is the start of the academic year. The Examination Coordinator, Mr. Sharma, opens the Scheduling Hub and selects the Practical Configs tab. He clicks "Add Subject Practical Config" to open the creation modal. Mr. Sharma selects Academic Session "2026-27", Class "Grade 11", Subject "Physics", checks **Has Practical**, enters Theory Max Marks "70.00", Practical Max Marks "30.00", and sets status to Active. He clicks Save. The system validates uniqueness, saves the configuration, logs the action, and refreshes the list.

**Editing a Split**
The board updates Chemistry to a 60/40 split. Mr. Sharma clicks Edit next to the Chemistry configuration, changes Theory Max to 60.00 and Practical Max to 40.00, and clicks Save. The system updates the values and logs the change.

---

## Example Scenario

Greenwood International School has a new Grade 11 Science batch. The coordinator, Mrs. Desai, sets up:
*   **Physics** — Theory Max: 70, Practical Max: 30
*   **Chemistry** — Theory Max: 70, Practical Max: 30
*   **Mathematics** — Has Practical: No, Theory Max: 100, Practical Max: 0

When calculations run, the system pulls exam scores capped at 70 for Physics theory and practical scores capped at 30, while Mathematics uses the full 100 written marks.

---

## Related Screens

*   **Config Templates** — Templates reference these split rules during calculations.
*   **Student IA Marks** — Where practical scores are recorded.
*   **Subject Results** — Displays the final calculated theory and practical totals.
