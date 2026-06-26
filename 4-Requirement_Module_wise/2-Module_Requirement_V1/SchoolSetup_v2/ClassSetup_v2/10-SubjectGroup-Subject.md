# Subject Group + Subject — Business Requirements

## What This Screen Does

The Subject Group + Subject screen is where the school fills in the content of each Subject Group by linking specific Class Groups to it. This is what actually defines which subjects a student studies when they are enrolled in a particular Subject Group.

To put it simply: if a Subject Group is the container, this screen is where the subjects are placed inside that container. Each "subject" added here is actually a Class Group — because the school needs to track not just what the subject is, but also how it is delivered (lecture, lab, practical) so that the timetable can schedule it correctly.

For example:
- Subject Group: Grade 10 Science Stream
  - Class Group: Grade 10 — Science Lecture (MAJ)
  - Class Group: Grade 10 — Science Lab (MAJ)
  - Class Group: Grade 10 — Maths Lecture (MAJ)
  - Class Group: Grade 10 — English Lecture (MAJ)
  - Class Group: Grade 10 — PE / Sports (SPO)
  - Class Group: Grade 10 — Computer Science Lecture (OPT) ← optional

A student enrolled in this Subject Group is automatically scheduled for all of these Class Groups. The timetable system will assign the student to periods for each of these groups.

---

## When This Screen Is Used

- Immediately after creating a Subject Group, to add subjects to it
- When a new subject or delivery format is added to an existing stream
- When a subject is removed from a stream for the current year
- When reviewing whether the correct Class Groups are assigned to each Subject Group before timetable generation

---

## Key Fields at a Glance

**Subject Group**
The parent group this subject link belongs to. Selected from the Subject Groups defined in the Subject Group screen. For example: Grade 10 — Science Stream.

**Class Group**
The specific Class Group being added to this Subject Group. This is selected from the Class Groups defined in the Class Group screen. The selection list is filtered to show only Class Groups that belong to the same class (and optionally section) as the Subject Group.

**Subject (Displayed, Not Entered)**
The subject associated with the selected Class Group is displayed automatically for reference. The admin does not enter this separately — it is shown based on the selected Class Group.

**Subject + Study Format (Displayed, Not Entered)**
The Subject + Study Format combination associated with the selected Class Group is also displayed automatically. This helps the admin confirm the right combination is selected.

**Status (Active / Inactive)**
Whether this specific link is currently active. An inactive link means the subject is not currently part of this group's curriculum, even though the record exists.

---

## Business Rules and Conditions

**No Duplicate Class Groups in a Subject Group**
The same Class Group cannot be added to the same Subject Group more than once. The system prevents this duplicate to avoid double-scheduling.

**Class Group Must Belong to Same Class as Subject Group**
The admin can only add Class Groups that belong to the same class as the Subject Group. For example, a Subject Group for Grade 10 cannot include a Class Group that is for Grade 8. The system filters the dropdown accordingly.

**Section Compatibility**
If the Subject Group is section-specific (e.g., Grade 10 Section A only), then only Class Groups that are also for Grade 10 Section A or Grade 10 (all sections) can be added. A Class Group for Grade 10 Section B cannot be added to a Grade 10 Section A Subject Group.

**At Least One Class Group Required**
A Subject Group with no Class Groups linked to it is considered incomplete. The system should display a warning or badge on Subject Groups that have no subjects linked yet.

**Cannot Delete a Link If Students Are Enrolled**
If students are enrolled in the Subject Group and the system has already assigned this Class Group to those students, the link cannot be deleted without first handling the student assignments. The system shows a warning.

**Deactivating a Link**
An admin can deactivate a specific Class Group link within a Subject Group without deleting it. This is useful at the end of the year when certain subjects are being phased out, or temporarily when a subject is suspended.

---

## Workflow Steps

**Adding Subjects to a Subject Group**
Admin navigates to the Subject Group + Subject screen. Admin selects the Subject Group from the dropdown (or opens this screen directly from the Subject Group screen using an "Add Subjects" button). Admin then selects Class Groups one by one from the filtered dropdown. Each selection is added as a row. Admin can add multiple Class Groups in one session. After adding all required subjects, admin saves. A success message confirms.

**Viewing the Subject List for a Group**
The screen shows a list of all Class Groups linked to the selected Subject Group. Each row shows the subject name, study format, subject type, and the status of the link. The admin can see at a glance what a student enrolled in this group will study.

**Removing a Subject from a Group**
Admin selects the link row and clicks delete or marks it as inactive. The system checks for student enrolments before allowing removal. If students are enrolled, the admin sees a warning and must confirm.

**Reviewing Before Timetable Generation**
Before the timetable is generated, the academic coordinator reviews all Subject Groups and their linked Class Groups to ensure every stream has the correct subjects with the correct period requirements. This screen is the last checkpoint before timetable planning begins.

---

## Example Scenario

Grade 10 Science Stream Subject Group has the following Class Groups linked:

| Class Group | Subject | Format | Type |
|---|---|---|---|
| Grade 10 — Maths Lecture | Mathematics | Lecture | Major |
| Grade 10 — Science Lecture | Science | Lecture | Major |
| Grade 10 — Science Lab | Science | Lab | Major |
| Grade 10 — English Lecture | English | Lecture | Major |
| Grade 10 — Hindi Lecture | Hindi | Lecture | Major |
| Grade 10 — SST Lecture | Social Studies | Lecture | Major |
| Grade 10 — Computer Science Lecture | Computer Science | Lecture | Optional |
| Grade 10 — PE Sports | Physical Education | Activity | Sports |

A student admitted to Grade 10 in the Science Stream is automatically enrolled in all 8 of these Class Groups. The timetable system will include this student in the scheduling for each of these groups across the week.

---

## Related Screens

- **Subject Group** — The parent screen where Subject Groups are created; subjects are added here
- **Class Group** — The Class Groups linked here must already be defined in the Class Group screen
- **Timetable Module** — Once Subject Groups are fully set up with subjects, the timetable module uses this data to know which students attend which periods
- **Student Admission** — When a student is enrolled in a Subject Group, this linked Class Group list determines their weekly schedule
