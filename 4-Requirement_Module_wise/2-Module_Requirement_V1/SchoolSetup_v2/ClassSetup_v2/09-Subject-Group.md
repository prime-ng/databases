# Subject Group — Business Requirements

## What This Screen Does

The Subject Group screen is where the school creates named bundles of subjects that are assigned to students during admission. A Subject Group represents the complete set of subjects a student will study for the academic year.

Think of a Subject Group as the school's curriculum package for a specific stream or combination. Instead of assigning subjects to each student one by one, the school defines a Subject Group (like "Grade 10 Science Stream") and then enrols students into that group. The student automatically gets all the subjects in that bundle.

This screen answers the question: "What are the different subject combinations that students of a particular class can be enrolled into?"

---

## When This Screen Is Used

- When setting up the academic year and defining the different curriculum streams or subject packages for each class
- When a new subject combination is introduced for a class (for example, adding a new Commerce with Computer Science stream)
- When the school wants to update which subjects are part of an existing group
- When a Subject Group is discontinued and students need to be moved to a different group

---

## Key Fields at a Glance

**Class**
The class this subject group belongs to. All students enrolled in this group must be in this class.

**Section (Optional)**
If this subject group is specific to one section, that section is selected here. If all sections of the class share the same subject combination, this field is left blank.

**Code**
A unique short code for this group. Examples: 10_SCI (Grade 10 Science Stream), 10_COM (Grade 10 Commerce Stream), 7_GEN (Grade 7 General), 8_A_SCI (Grade 8 Section A Science).

**Short Name**
A compact label for dropdown displays. Examples: 10th Science, 10th Commerce, 7th General, 8-A Science.

**Name**
The full descriptive name of the group that appears in student records, reports, and admission forms. Examples: Grade 10 — Science Stream, Grade 10 — Commerce Stream, Grade 7 — General Group.

**Total Registered Students**
A system-maintained count of how many students are currently enrolled in this Subject Group. This field is updated automatically by the system as students are added or transferred. Admin does not manually enter this value.

**Is Default Group for Class**
A flag that marks one group as the default for its class. When a student is admitted to a class and no specific group is selected, the default group is automatically assigned. Useful for classes that have only one subject combination (like junior classes where all students study the same subjects).

**Display Order (Ordinal)**
Controls the order in which groups appear in the dropdowns and lists for that class. If Grade 10 has three streams, Science might appear first, followed by Commerce, then Arts.

**Status (Active / Inactive)**
Determines whether this group can be selected during student admission. Inactive groups are hidden from admission screens.

---

## Business Rules and Conditions

**Unique Code per School**
The code must be unique across all subject groups in the school.

**Unique Short Name per School**
The short name must also be unique.

**Unique Name per Class**
Within a class, two subject groups cannot have the same full name. For example, Grade 10 cannot have two groups both called "Science Stream".

**Only One Default Group per Class (and Section)**
If Is Default Group for Class is Yes, it must be the only group for that class (and section, if applicable) with this flag set to Yes. The system prevents two default groups from being set for the same class-section combination.

**Section-Specific vs All-Sections Logic**
If a Subject Group is defined without a section, it applies to all sections of that class. The system should check whether a section-specific group already exists for the same class-section before allowing a shared group to be created for the same class.

**Cannot Delete If Students Are Enrolled**
If any student is currently enrolled in this Subject Group, deletion is blocked. Admin must first transfer all students to another group. The system displays the count of enrolled students.

**Cannot Deactivate With Active Students**
Deactivating a group with actively enrolled students requires an admin confirmation. A warning is shown explaining that enrolled students will no longer have an active subject group.

**Subject Group Must Have Subjects Linked**
A Subject Group without any subjects linked in the Subject Group + Subject screen is incomplete. The system should warn the admin that subjects have not been assigned yet.

---

## Workflow Steps

**Adding a New Subject Group**
Admin opens the Add form, selects the class and optionally a section. Admin enters the code, short name, and full name. Admin toggles Is Default Group if this is the primary group for the class. Admin submits. A success message appears, but the system reminds the admin to now go to the Subject Group + Subject screen and add subjects to this group.

**Viewing Subject Groups**
The list is grouped by class and shows all defined subject groups. Each row shows the code, short name, name, number of registered students, default group flag, and status.

**Editing a Subject Group**
Admin can update the name, short name, and default group flag. The class and section cannot be changed after creation.

**Deactivating a Subject Group**
Admin toggles the status to Inactive after confirming that no active students are enrolled. Inactive groups are hidden from admission screens.

**Copying a Group from Previous Year**
At the start of a new academic year, admin can duplicate an existing subject group structure as a starting point, then update the subjects in the Subject Group + Subject screen.

---

## Example Scenario

Grade 10 in a school offers three streams. The admin creates three Subject Groups:

**Grade 10 — Science Stream (Code: 10_SCI)**
- Section: None (applies to all sections)
- Subjects: Maths, Science, English, Hindi, SST, Computer Science (optional), Physical Education

**Grade 10 — Commerce Stream (Code: 10_COM)**
- Section: None (applies to all sections)
- Subjects: Business Studies, Accountancy, Economics, English, Hindi, Computer Applications, Physical Education

**Grade 10 — Arts Stream (Code: 10_ART)**
- Section: None (applies to all sections)
- Subjects: History, Geography, Political Science, English, Hindi, Fine Arts, Physical Education

When a student is admitted to Grade 10, the admission team selects which stream the student is in. The system then links the student to the corresponding Subject Group and automatically assigns all the subjects in that group to the student.

---

## Related Screens

- **Class** — Subject Groups always belong to a specific class
- **Sections** — Subject Groups can optionally be section-specific
- **Subject Group + Subject** — This is the screen where the actual list of subjects (Class Groups) is added to each Subject Group
- **Student Admission** — Students are enrolled into a Subject Group during the admission process
