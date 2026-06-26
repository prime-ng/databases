# Subject — Business Requirements

## What This Screen Does

The Subject screen is where the school defines all the academic subjects taught across all classes. A subject is the basic academic unit — Mathematics, Science, English, Hindi, Social Studies, Computer Science, Physical Education, Art, Music, and so on.

Subjects are defined at the school level, not at the class level. This means Mathematics is defined once, and then it can be used across Grade 1 through Grade 12. The connection between a subject and a specific class is made later in the Subject + Study Format and Class Group screens.

This screen answers the question: "What are all the subjects this school teaches, regardless of which class or grade they are taught in?"

---

## When This Screen Is Used

- When the school is setting up and needs to register all the subjects it offers
- When a new subject is introduced in the school (for example, adding Artificial Intelligence as a subject)
- When a subject's name or display code needs to be updated
- When a subject is discontinued and should be removed from future class assignments

---

## Key Fields at a Glance

**Code**
A short unique code used in timetable grids, result sheets, and system identifiers. Examples: MTH (Maths), SCI (Science), ENG (English), HIN (Hindi), SST (Social Studies), CS (Computer Science), PE (Physical Education).

**Short Name**
A medium-length label for dropdowns and compact display areas. Examples: MATH, SCIENCE, ENGLISH, HINDI, SOC.STUDIES, COMP.SCI, PHY.EDU.

**Name**
The full official name of the subject as it appears on report cards, mark sheets, and official communications. Examples: Mathematics, Science, English Language, Hindi, Social Studies, Computer Science, Physical Education.

**Is Optional**
A flag that indicates whether this subject is available as an optional choice for students (as opposed to being compulsory for everyone). Optional subjects typically have a limited number of students who choose them from a group of alternatives.

**Display Order (Ordinal)**
Controls the sequence of subjects in lists and dropdowns. Core subjects typically appear first, followed by languages, then optional and activity subjects.

**Status (Active / Inactive)**
Determines whether this subject is available for selection in Subject + Study Format and other screens.

---

## Business Rules and Conditions

**Unique Code**
No two subjects can have the same code. The code is used extensively in timetable identifiers and result sheet headers.

**Unique Short Name**
Each subject must have a unique short name.

**Cannot Delete If In Use**
If a subject has already been included in any Subject + Study Format combination, it cannot be deleted. Admin must first remove all linked records. The system shows a warning with a count of how many combinations use this subject.

**Optional Flag — What It Means**
Marking a subject as Optional does not automatically make it optional for every class. It simply signals that this subject is of the type that can be offered optionally. The actual optional-or-compulsory status for a specific class is set in the Class Group screen.

**Deactivation**
Deactivating a subject hides it from new Subject + Study Format and Class Group selections. Existing records that already reference this subject are not affected.

---

## Workflow Steps

**Adding a New Subject**
Admin opens the Add Subject form, enters the Code (e.g., AI), Short Name (e.g., ART.INTEL), and Full Name (e.g., Artificial Intelligence). Admin selects whether it is optional or compulsory using the Is Optional toggle. The system assigns the next display order. Admin submits and a confirmation appears.

**Viewing All Subjects**
The subject list shows all subjects sorted by display order. Each row displays the code, short name, full name, whether it is optional, and its status. Admin can drag rows to reorder them.

**Editing a Subject**
Admin clicks on a subject and updates the short name, full name, or optional flag. The code should not be changed after it has been used in Subject + Study Format records, as this would affect timetable references.

**Deactivating a Subject**
Admin toggles status to Inactive. The subject disappears from new record creation screens.

**Deleting a Subject**
Admin can delete a subject only if no Subject + Study Format combination references it. The system checks and blocks deletion if dependencies exist.

---

## Example Scenario

A school teaches the following subjects across all its classes:

**Core Academic Subjects (Compulsory)**
- Mathematics (Code: MTH)
- Science (Code: SCI)
- English (Code: ENG)
- Hindi (Code: HIN)
- Social Studies (Code: SST)

**Language Subjects (Compulsory)**
- Sanskrit (Code: SNS) — for classes up to Grade 8
- French (Code: FRN) — optional from Grade 9

**Optional Subjects**
- Computer Science (Code: CS) — students choose from a group
- Fine Arts (Code: FA) — students choose from a group
- Music (Code: MUS) — students choose from a group

**Activity Subjects**
- Physical Education (Code: PE) — compulsory for all
- Art and Craft (Code: ART)

Each of these subjects is defined once in this screen. They are then combined with Study Formats and assigned to classes in the subsequent screens.

---

## Related Screens

- **Subject + Study Format** — The core screen where each subject is combined with its delivery format
- **Class Group** — Class Groups link a subject-delivery combination to a specific class for timetabling
- **Subject Group + Subject** — Subject Groups contain a collection of subjects assigned to students of a particular class
