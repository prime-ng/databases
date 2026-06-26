# Class — Business Requirements

## What This Screen Does

The Class screen is where the school defines all the academic classes or grades that exist in the school. Every student belongs to a class, and every subject, timetable slot, and result is tied to a class. This screen is the starting point for the entire academic hierarchy.

Classes are defined independently of sections. A class like "Grade 10" is defined once here. Later, in the Class + Sections screen, the admin assigns which sections (A, B, C) exist under Grade 10.

---

## When This Screen Is Used

- At the start of each academic year when the school defines its grade structure
- When a new class or grade is introduced (for example, adding a Pre-Nursery class)
- When a class name needs to be updated (for example, renaming "Standard 1" to "Grade 1")
- When a class is discontinued and needs to be deactivated

---

## Key Fields at a Glance

**Code**
A short unique code used in timetable displays and internal references. Examples: 1, 2, 10, 11, NRS, KG1, KG2, 1st, 10th. This code must be compact because it appears in timetable grids where space is limited.

**Short Name**
A medium-length label used in dropdowns and list views. Examples: G1, G10, 11th, 12th, Nurs. Short enough for compact UI but more readable than the code.

**Name**
The full official name of the class as it will appear in reports, result cards, fee receipts, and official letters. Examples: Grade 1, Class - 10th, Nursery, KG - I.

**Display Order (Ordinal)**
Controls the sequence in which classes appear in all lists and dropdowns throughout the system. Grade 1 should come before Grade 2, and so on. The admin can rearrange classes by dragging rows.

**Status (Active / Inactive)**
Determines whether the class is available for use in admission, timetable, fees, and other modules. Only active classes are visible in those modules.

---

## Business Rules and Conditions

**Unique Code**
No two classes in the same school can have the same code. The system prevents duplicates because the code is used in timetable references and class-section combinations.

**Unique Short Name**
The short name must also be unique across all classes in the school.

**Unique Full Name**
The full name must be unique. Having two classes with the same name would cause confusion in reports and student records.

**Unique Display Order**
Each class must have a unique ordinal. The system must handle reordering automatically when the admin drags and drops rows.

**Cannot Delete If In Use**
If a class already has sections assigned (in Class + Sections screen) or has students enrolled, it cannot be deleted. Admin must first remove all dependencies. The system shows a warning message listing what is preventing deletion.

**Deactivation vs Deletion**
Deactivating a class hides it from new assignment dropdowns and the admission module. Deletion is only possible when the class has no active records linked to it.

---

## Workflow Steps

**Adding a New Class**
Admin opens the Add Class form and fills in the Code (e.g., 10), Short Name (e.g., 10th), and Full Name (e.g., Class - 10th). The system assigns the next available display order automatically. Admin submits and a success confirmation appears.

**Viewing All Classes**
The class list screen shows all defined classes sorted by their display order. Each row shows code, short name, full name, and status. The admin can drag rows to reorder them.

**Editing a Class**
Admin clicks on a class and updates the short name or full name. The code should ideally not change after creation, as it is referenced in class-section codes and timetable. If changed, the system should warn that dependent records will also need updating.

**Deactivating a Class**
Admin toggles the status switch to Inactive. The class no longer appears in the admission module or new assignment dropdowns. Historical records remain intact.

**Deleting a Class**
Admin can delete a class only if it has no sections assigned and no students enrolled. The system checks and either confirms deletion or shows a list of what must be removed first.

---

## Example Scenario

A school runs classes from Nursery to Grade 12. The admin creates:
- Nursery (Code: NRS, Short Name: Nurs, Display Order: 1)
- KG - I (Code: KG1, Short Name: KG1, Display Order: 2)
- KG - II (Code: KG2, Short Name: KG2, Display Order: 3)
- Grade 1 through Grade 12 (Codes: 1 through 12, Display Orders: 4 through 15)

Later, the school adds a new Pre-Nursery class. Admin creates it with Code: PNRS, assigns Display Order: 0 (before Nursery), and the system reorders all existing classes accordingly.

---

## Related Screens

- **Class + Sections** — Once a class is created, sections are assigned to it here
- **Class Group** — Class Groups use a class (and optionally a section) as their base reference
- **Subject Group** — Subject Groups are always linked to a specific class
