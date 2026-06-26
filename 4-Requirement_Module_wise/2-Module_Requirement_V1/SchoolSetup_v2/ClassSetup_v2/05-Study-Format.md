# Study Format — Business Requirements

## What This Screen Does

The Study Format screen is where the school defines the different ways in which a subject can be delivered or taught. A study format describes the mode of instruction — whether a subject is taught as a regular classroom lecture, as a practical lab session, as a tutorial, as a workshop, or in any other format.

The same subject can be taught in multiple formats. For example, Science may have both a Lecture format (theory class in the classroom) and a Lab format (practical session in the science laboratory). Each format will have different room requirements and may have a different number of periods per week.

By defining Study Formats, the school gives the timetable system the information it needs to schedule the right type of session in the right kind of room.

---

## When This Screen Is Used

- When setting up the school system and defining all the modes of instruction that are used
- When a new teaching format is introduced (for example, adding Online or Blended Learning as a format)
- When an existing format's name needs to be updated
- When a format is no longer used and needs to be deactivated

---

## Key Fields at a Glance

**Code**
A very short unique code used in timetable identifiers and system references. Examples: LECT (Lecture), LAB (Lab), PRAC (Practical), TUT (Tutorial), SEM (Seminar), WSH (Workshop), GRD (Group Discussion).

**Short Name**
A medium-length label used in dropdowns and compact views. Examples: LECTURE, LAB, PRACTICAL, TUTORIAL, SEMINAR, WORKSHOP, GROUP_DISC.

**Name**
The full descriptive name of the study format that appears in reports and detailed views. Examples: Lecture, Laboratory Session, Practical Session, Tutorial, Seminar, Workshop, Group Discussion.

**Display Order (Ordinal)**
Controls the order in which formats appear in dropdowns and lists. Lecture typically appears first as the most common format.

**Status (Active / Inactive)**
Determines whether this format can be selected when creating a Subject + Study Format combination.

---

## Business Rules and Conditions

**Unique Code**
No two study formats can have the same code. The code is used in combination with the subject code to create unique identifiers in the Subject + Study Format screen.

**Unique Short Name**
Each study format must have a unique short name to avoid confusion in dropdowns.

**Cannot Delete If In Use**
If a study format has already been used in any Subject + Study Format combination, it cannot be deleted. Admin must first remove or reassign those combinations. The system shows a warning.

**Deactivation**
An inactive study format cannot be selected when creating new Subject + Study Format records. Existing records are not affected.

**Seeded Data**
The system comes pre-loaded with common study formats: Lecture, Lab, Practical, Tutorial, Seminar, Workshop, Group Discussion, Other. The school can add more or deactivate those not applicable to their setup.

---

## Workflow Steps

**Adding a New Study Format**
Admin opens the Add form, enters the Code (e.g., OLN), Short Name (e.g., ONLINE), and Full Name (e.g., Online Session). The system assigns the next display order automatically. Admin submits and a success message appears.

**Viewing All Study Formats**
The list shows all study formats sorted by their display order. Each row shows code, short name, full name, and status. Admin can drag rows to reorder them.

**Editing a Study Format**
Admin clicks on a row and updates the short name or full name. The code should not be changed after it has been used in Subject + Study Format records.

**Deactivating a Study Format**
Admin toggles the status to Inactive. The format no longer appears in new record creation forms.

---

## Example Scenario

A school offers Science in three different formats:

1. **Lecture (LECT)** — Regular theory class in a normal classroom. 3 periods per week.
2. **Lab (LAB)** — Practical session in the Science Lab room. 2 periods per week, requires the Science Laboratory room type.
3. **Practical (PRAC)** — Outdoor or special setup experiments. 1 period per week, requires the Activity Hall room type.

When these formats are later combined with the Science subject in the Subject + Study Format screen, each combination tells the timetable system: "Schedule Science Lecture in a regular room, and Science Lab only in the Science Lab room."

---

## Related Screens

- **Subject + Study Format** — Study Format is a required input when creating a subject-delivery combination
- **Class Group** — Class Groups are built on top of Subject + Study Format combinations and inherit the room requirements
