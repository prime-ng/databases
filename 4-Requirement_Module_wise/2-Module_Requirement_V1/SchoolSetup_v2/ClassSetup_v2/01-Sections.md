# Sections — Business Requirements

## What This Screen Does

The Sections screen is where the school defines all the divisions that can be assigned to any class. Sections are typically named with letters such as A, B, C, D or with names like Rose, Lotus, Star. Once defined, these sections are available to be assigned to any class in the Class + Sections screen.

Think of a Section as a reusable building block. The school defines Section A once, and then it can be applied to Grade 1, Grade 5, Grade 10, or any other class that needs an A Section.

---

## When This Screen Is Used

- When the school is setting up for a new academic year and defining which sections will exist
- When a new section needs to be added (for example, if the school adds a new division D to senior classes)
- When an existing section's name or display order needs to be updated
- When a section is no longer in use and needs to be deactivated

---

## Key Fields at a Glance

**Code**
A short unique code used internally and in timetable references. Usually a single letter or a very short text like A, B, C, D. This code appears in timetable displays and reports where full names do not fit.

**Short Name**
A slightly longer abbreviation for display purposes, such as SEC-A or SEC-B. Used in list views and dropdowns where a compact label is needed.

**Name**
The full display name of the section, such as Section - A or Section - B. This is what students, parents, and teachers see in reports, result cards, and official communications.

**Display Order (Ordinal)**
Controls the sequence in which sections appear in lists and dropdowns. Section A should appear before Section B, and so on. The admin can drag and drop sections to rearrange the order.

**Status (Active / Inactive)**
Determines whether the section is available for use. Only active sections can be assigned to classes.

---

## Business Rules and Conditions

**Unique Code**
No two sections in the school can have the same code. The system must prevent duplicate codes to ensure timetable references remain accurate.

**Unique Name**
No two sections can have the same name. The system must prevent duplicate names to avoid confusion in reports and assignments.

**Cannot Delete If In Use**
If a section has already been assigned to a class in the Class + Sections screen, it cannot be deleted. The admin must first remove all class-section assignments before deleting a section. The system must show a clear warning message explaining why deletion is blocked.

**Deactivating a Section**
An admin can deactivate a section by toggling its status to Inactive. An inactive section no longer appears in the Class + Sections assignment screen, but it remains visible in historical records where it was already assigned.

**Ordinal Must Be Unique**
Each section must have a unique display order number. If the admin rearranges sections via drag and drop, the system must update the ordinal values automatically without conflicts.

---

## Workflow Steps

**Adding a New Section**
Admin opens the Add Section form, enters the Code (e.g., A), Short Name (e.g., SEC-A), and Full Name (e.g., Section - A). The system sets the display order automatically as the next available number. Admin submits and a success message confirms the section is created.

**Viewing All Sections**
The sections list screen displays all sections sorted by their display order. Each row shows the code, short name, full name, and active/inactive status. The admin can drag rows to rearrange the order.

**Editing a Section**
Admin clicks on a section and modifies the short name or full name. The code cannot be changed after creation as it may already be in use in timetable references. Changes are saved and reflected immediately.

**Deactivating a Section**
Admin toggles the status switch on the list screen to mark a section as Inactive. The section disappears from new assignment dropdowns but remains in historical records.

**Deleting a Section**
Admin can delete a section only if it has not been assigned to any class. If assignments exist, the system shows a warning and blocks deletion.

---

## Example Scenario

A school runs three sections for most classes — A, B, and C. The admin sets up:
- Section A (Code: A, Display Order: 1)
- Section B (Code: B, Display Order: 2)
- Section C (Code: C, Display Order: 3)

Later, the school decides to add a fourth section D for senior classes only. Admin adds Section D (Code: D, Display Order: 4) and then assigns it to Grade 9 and Grade 10 in the Class + Sections screen.

---

## Related Screens

- **Class + Sections** — Sections must exist before they can be assigned to a class
- **Class Group** — Class Groups reference sections to define subject-level scheduling for a specific class+section combination
- **Subject Group** — Subject Groups can optionally be section-specific
