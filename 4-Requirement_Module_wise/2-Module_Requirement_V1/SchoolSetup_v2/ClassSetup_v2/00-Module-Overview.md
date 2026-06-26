# Class Setup — Module Overview

## What This Module Does

The Class Setup module is the backbone of the school's academic structure. It allows the school administration to define and organise every academic entity that is used across the entire school management system — from basic building blocks like Sections and Subjects to complex combinations like Class Groups and Subject Groups.

Think of this module as the school's academic blueprint. Before any student can be enrolled, any timetable can be planned, or any result can be generated, the school must first define its classes, sections, subjects, and how they combine together.

---

## Why This Module Exists

In a school system, every department depends on correctly configured academic data:
- **Admissions** needs to know which Classes and Sections are available
- **Timetable** needs Class Groups to know which subject is taught where and how often
- **Exam / Results** needs Subject Groups to know which subjects a student is assessed on
- **Fee** needs Class Groups to apply the correct fee structure
- **Reports** need all of the above to generate meaningful output

Without the Class Setup being done correctly, none of the other modules can function properly.

---

## Screens in This Module

The Class Setup module is organised into the following screens, each handling one specific layer of the academic structure:

| # | Screen Name | What It Defines |
|---|---|---|
| 01 | Sections | Individual sections like A, B, C |
| 02 | Class | Individual classes like Grade 1, Grade 10 |
| 03 | Class + Sections | Which sections are assigned to which class |
| 04 | Subject Type | Categories of subjects — Major, Minor, Optional etc. |
| 05 | Study Format | How a subject is delivered — Lecture, Lab, Practical etc. |
| 06 | Subject | Individual subjects like Maths, Science, English |
| 07 | Subject + Study Format | A subject combined with its delivery format and type |
| 08 | Class Group | A class linked to a subject-study format combination for timetable purposes |
| 09 | Subject Group | A named bundle of subjects assigned to a class/section for student enrolment |
| 10 | Subject Group + Subject | Which Class Groups are included inside a Subject Group |
| 11 | Class Group Options | Optional sub-choices within a Class Group (e.g., choosing between Football or Basketball under PE) |

---

## Who Uses This Module

- **School Admin / Principal** — Sets up the entire academic structure at the start of each academic year
- **Academic Coordinator** — Adds or modifies subjects, study formats, and class groups
- **Timetable In-charge** — Reviews Class Groups to ensure all periods and room requirements are correct
- **Admission Team** — Refers to Sections, Classes, and Subject Groups during student admission

---

## When Is This Module Used

- At the beginning of the academic year when the school is setting up
- When a new class or section is added mid-year
- When a new subject or subject type is introduced
- When timetable planning begins and Class Groups need to be reviewed
- When admission forms are opened and students need to be enrolled into Subject Groups

---

## Setup Sequence (Recommended Order)

The school should set up the module in the following order to avoid dependency errors:

```
1. Sections
2. Classes
3. Class + Sections (assign sections to classes)
4. Subject Type
5. Study Format
6. Subjects
7. Subject + Study Format (combine subjects with delivery formats)
8. Class Group (assign subject-study formats to classes/sections)
9. Subject Group (create named bundles for student enrolment)
10. Subject Group + Subject (link class groups into subject groups)
11. Class Group Options (optional: define sub-choices within a class group)
```

---

## Key Concepts to Understand

**Sections vs Classes**
Sections (A, B, C) and Classes (Grade 1, Grade 2) are defined separately so they can be reused across different combinations. For example, Section A can be used for both Grade 5 and Grade 10.

**Subject + Study Format**
A single subject can be delivered in multiple ways. For example, Science can be taught as a Lecture (theory) and as a Lab (practical). Each combination is treated as a separate unit for timetable planning.

**Class Group**
A Class Group is the most important unit for timetable scheduling. It says: "For Class 10-A, Science Lecture is a Major subject that requires 5 periods per week in a regular classroom." This tells the timetable system exactly what needs to be scheduled.

**Subject Group**
A Subject Group is the unit used for student enrolment. It is a named bundle that says: "If a student is in the Science stream of Grade 10, they study Maths, Science, English, Hindi, and SST." Students are enrolled into a Subject Group, which automatically assigns all the linked subjects to them.
