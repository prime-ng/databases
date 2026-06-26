# Subject Type — Business Requirements

## What This Screen Does

The Subject Type screen allows the school to define the different categories or classifications of subjects. These categories are used across the system to indicate how important or mandatory a subject is for a student.

Common subject types include: Major, Minor, Core, Optional, Activity, and Sports. Once defined, these types are used in the Subject + Study Format screen and the Class Group screen to categorise each subject-delivery combination.

Subject Type acts as a label that helps the timetable system, the exam system, and the reporting system understand the weight and priority of each subject in the academic structure.

---

## When This Screen Is Used

- When the school is setting up the system and needs to define how subjects are categorised
- When a new category of subject is introduced (for example, adding a Vocational type for skill-based subjects)
- When an existing type's name needs to be updated
- When a subject type is retired and should no longer be available for selection

---

## Key Fields at a Glance

**Code**
A very short unique identifier for the subject type. Used in timetable codes and system references. Examples: MAJ (Major), MIN (Minor), OPT (Optional), ACT (Activity), SPO (Sports), COR (Core).

**Short Name**
A slightly longer label used in dropdowns and compact list views. Examples: MAJOR, MINOR, OPTIONAL, ACTIVITY, SPORTS.

**Name**
The full display name that appears in reports, class group definitions, and any screen where the type is shown in full. Examples: Major Subject, Minor Subject, Optional Subject, Activity Period, Sports Period.

**Display Order (Ordinal)**
Controls the order in which subject types appear in dropdowns and lists. Major subjects typically appear first, followed by minor, optional, activity, and sports.

**Status (Active / Inactive)**
Determines whether the subject type can be selected when creating a Subject + Study Format combination or a Class Group.

---

## Business Rules and Conditions

**Unique Code**
No two subject types can have the same code. The system prevents duplicates because codes are used in timetable and class group identifiers.

**Unique Short Name**
Each subject type must have a unique short name to avoid confusion in dropdown selections.

**Cannot Delete If In Use**
If a subject type has already been assigned to any Subject + Study Format combination or Class Group, it cannot be deleted. Admin must first remove or reassign those records. The system shows a warning with a count of linked records.

**Deactivation**
An inactive subject type cannot be selected when creating new Subject + Study Format or Class Group records. Existing records that already used this type remain unchanged.

**Seeded Data**
The system comes pre-loaded with standard subject types: Major, Minor, Optional, Activity, Sports, Core. The school can add more or deactivate ones they do not use.

---

## Workflow Steps

**Adding a New Subject Type**
Admin opens the Add form, enters the Code (e.g., VOC), Short Name (e.g., VOCATION), and Full Name (e.g., Vocational Subject). The system assigns the next display order. Admin submits and a confirmation message appears.

**Viewing All Subject Types**
The list shows all subject types sorted by display order. Each row shows code, short name, full name, and status. Admin can drag rows to reorder them.

**Editing a Subject Type**
Admin clicks on a row and updates the short name or full name. The code should not be changed after it has been used in class groups or subject-study formats.

**Deactivating a Subject Type**
Admin toggles the status to Inactive. The type disappears from new record creation dropdowns but remains visible in existing records.

---

## Example Scenario

A school uses the following subject types:
- **MAJ — Major** : Core academic subjects like Maths, Science, English that are compulsory and carry full marks
- **MIN — Minor** : Supporting subjects like Computer Science or Second Language that have fewer periods
- **OPT — Optional** : Subjects students can choose from a group, like Sanskrit or French
- **ACT — Activity** : Non-academic periods like Art, Craft, Music, Dance
- **SPO — Sports** : Physical Education and sports periods

When the admin creates a Class Group for Grade 8 Science Lecture, they select Subject Type as MAJ (Major). This tells the timetable system that this is a high-priority subject that must be scheduled within regular school hours.

---

## Related Screens

- **Subject + Study Format** — Subject Type is selected here when defining how a subject is delivered
- **Class Group** — Class Groups use Subject Type to classify the importance of each scheduled subject
