# Class + Sections — Business Requirements

## What This Screen Does

The Class + Sections screen is where the school assigns specific sections to each class and sets up the operational details of each class-section combination. This is where abstract definitions become real classrooms.

For example, Grade 10 might have three sections: A, B, and C. Each of these — Grade 10 Section A, Grade 10 Section B, Grade 10 Section C — is set up here with its own class teacher, room assignment, and student capacity.

Every student admitted to the school is assigned to a specific Class + Section combination. Every timetable is built around these combinations. This screen is therefore central to the school's day-to-day operations.

---

## When This Screen Is Used

- When setting up the school at the beginning of the academic year and defining which sections each class will have
- When a new section is added to an existing class mid-year (for example, adding a new Division D to Grade 8)
- When the class teacher or assistant teacher of a section changes
- When a section is moved to a different room
- When the student capacity of a section needs to be updated
- When a class-section is deactivated at the end of the year

---

## Key Fields at a Glance

**Class**
The class this combination belongs to. Selected from the list of active classes defined in the Class screen.

**Section**
The section being assigned to this class. Selected from the list of active sections. Each class-section combination is unique — Grade 10 Section A can only exist once.

**Code**
A system-generated or admin-entered short code combining the class and section codes. For example, 10th_A or 8th_B. This code is used in timetable grids and reports where space is limited.

**Name**
The full display name of this combination, such as Class - 10th Section - A or Grade 8 Section - B. This appears in student records, fee receipts, reports, and result cards.

**Class Teacher**
The main teacher responsible for this class-section. This teacher is the point of contact for the section and their name appears in student records and official communication.

**Assistant Class Teacher**
A secondary teacher who assists the class teacher. This field is optional in some setups but required in the system's current design.

**Room Type**
The type of room this class-section uses as its home room. For most classes this will be a regular classroom. Some specialised classes may use a different room type.

**Home Room**
The specific classroom or room assigned as the permanent home for this class-section. This is where the class meets for registration, general periods, and house activities.

**Capacity (Planned)**
The target number of students this section is designed for. Used during admission planning to know how many seats are available.

**Actual Total Students**
The real number of students currently enrolled in this section. This is typically auto-updated by the system as students are admitted or transferred.

**Minimum Students Required**
The minimum number of students needed for this section to run. If actual enrolment falls below this number, the admin is alerted.

**Maximum Students Allowed**
The upper limit of students permitted in this section. Admission should be blocked once this limit is reached.

**Total Periods Per Day**
The number of teaching periods this section has in a school day. This is used by the timetable module to know how many slots to fill.

**Display Order (Ordinal)**
Controls the sequence of this combination in lists and dropdowns. Grade 10 Section A should appear before Grade 10 Section B.

**Status (Active / Inactive)**
Whether this class-section is currently in use. Inactive combinations are hidden from admission and timetable screens but remain in historical records.

---

## Business Rules and Conditions

**One Section Per Class Per School**
A particular section cannot be assigned to the same class more than once. For example, Grade 10 cannot have two Section A entries. The system prevents this duplicate.

**Class and Section Must Be Active**
Both the selected class and section must be in Active status before they can be combined. Inactive classes or sections cannot be used to create new combinations.

**Capacity vs Maximum Students**
The Planned Capacity represents the ideal number. The Maximum Students Allowed is the hard limit. Actual enrolment should not exceed the maximum. The system should warn the admin during admission if the maximum is about to be breached.

**Class Teacher Must Be a Valid Staff Member**
The teacher selected as class teacher or assistant class teacher must be an active staff member registered in the system. The dropdown should only show eligible teaching staff.

**Code Must Be Unique**
The combined code (e.g., 10th_A) must be unique across the entire school. The system generates this automatically from the class code and section code, ensuring no duplicates.

**Name Must Be Unique**
The full display name of each Class + Section combination (e.g., Class - 10th Section - A) must also be unique across the entire school. Two combinations cannot share the same full name. The system prevents this duplicate.

**Display Order Must Be Unique**
No two Class + Section combinations can have the same display order number. Each position in the sequence belongs to exactly one combination. When the admin rearranges combinations by dragging rows, the system automatically updates the order numbers so that no two records share the same position.

**Cannot Delete If Students Are Enrolled**
If any student is currently assigned to this class-section, deletion is blocked. Admin must transfer or remove all students first. The system displays a count of enrolled students and a warning message.

**Cannot Deactivate If Students Are Enrolled**
Similarly, an active class-section with enrolled students should not be deactivated mid-year. The system should warn the admin and require confirmation.

---

## Workflow Steps

**Adding a New Class + Section Combination**
Admin opens the Add form, selects the class from the dropdown, selects the section, enters the combined name if not auto-generated, assigns the class teacher and assistant teacher, selects the room type and home room, sets the capacity and student limits, enters total periods per day, and submits. A success message confirms the combination is created.

**Viewing All Class + Section Combinations**
The list screen shows all combinations grouped by class, sorted by display order. Each row shows the code, name, class teacher name, room, current student count, capacity, and status.

**Editing a Combination**
Admin clicks on a row and updates any editable fields — teacher assignment, room assignment, capacity values, or periods per day. The class and section themselves cannot be changed after creation (a new combination must be created instead).

**Transferring the Class Teacher**
When a class teacher changes, admin opens the record and selects the new teacher from the dropdown. The change takes effect immediately. The previous teacher's assignment ends.

**Deactivating a Class + Section**
Admin toggles the status to Inactive at the end of the year or when the section is discontinued. The combination no longer appears in active dropdowns but historical records are preserved.

---

## Example Scenario

Grade 10 has three sections: A, B, and C.

Admin sets up:
- **Grade 10 Section A** — Class Teacher: Mrs Sharma, Home Room: Room 201, Capacity: 40, Max: 45, Periods Per Day: 8
- **Grade 10 Section B** — Class Teacher: Mr Verma, Home Room: Room 202, Capacity: 40, Max: 45, Periods Per Day: 8
- **Grade 10 Section C** — Class Teacher: Ms Nair, Home Room: Room 203, Capacity: 40, Max: 45, Periods Per Day: 8

During admission, when student count for Section C reaches 45, the system blocks further admission to that section and prompts the admin to either increase the limit or direct new admissions to Section A or B.

---

## Related Screens

- **Sections** — Sections must be defined first before they can be assigned to a class
- **Class** — Classes must be defined first before this screen can be used
- **Class Group** — Class Groups are always built on top of a Class + Section combination
- **Subject Group** — Subject Groups can be section-specific or shared across all sections of a class
