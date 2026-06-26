# Subject + Study Format — Business Requirements

## What This Screen Does

The Subject + Study Format screen is where the school creates a specific deliverable teaching unit by combining a Subject with a Study Format and a Subject Type. This is the foundational unit that the timetable module works with.

To put it simply: a Subject (what is taught) combined with a Study Format (how it is taught) and a Subject Type (how it is classified) gives the system a complete picture of a schedulable teaching unit.

For example:
- **Science** + **Lecture** + **Major** = "Science Lecture Major" → a regular theory class in any normal room
- **Science** + **Lab** + **Major** = "Science Lab Major" → a practical session that must be scheduled in the Science Lab

This screen does not yet say which class or section it belongs to. That happens in the Class Group screen. This screen simply defines the combination itself at a school-wide level.

This screen also allows the admin to define **Subject Options** for any combination where students must individually choose one activity from a set of alternatives. For example, under Physical Education — Activity, students choose between Football, Basketball, or Swimming. These options are defined here and are automatically available to every Class Group that uses this combination.

---

## When This Screen Is Used

- When setting up the academic structure and defining all unique subject-delivery combinations the school uses
- When a subject is to be taught in a new format that was not previously defined (for example, adding a Seminar format for English)
- When the room requirements for a subject-study format combination need to be updated
- When a subject-study format combination is discontinued

---

## Key Fields at a Glance

**Subject**
The academic subject for this combination. Selected from the active subjects defined in the Subject screen. For example: Mathematics, Science, English.

**Study Format**
How this subject will be delivered. Selected from the active study formats. For example: Lecture, Lab, Practical, Tutorial, Workshop.

**Subject Type**
The classification of this combination. Selected from the active subject types. For example: Major, Minor, Optional, Activity, Sports.

**Code**
A system-generated unique code combining the subject code and study format code. For example: SCI_LAC (Science Lecture), SCI_LAB (Science Lab), MTH_LAC (Maths Lecture). This code is used in timetable identifiers and Class Group codes.

**Name**
The full display name of this combination. For example: Science Lecture, Science Lab, Mathematics Tutorial. This name appears in the Class Group screen and timetable reports.

**Uses Class Home Room**
A Yes/No flag that indicates whether this subject-study format combination should always be scheduled in the class's own home room. For example, English Lecture can happen in any available room, but a class test might require the class's own room.

**Requires Specific Room Type**
A Yes/No flag that indicates whether this combination needs a particular type of room. For example, Science Lab requires the "Science Laboratory" room type. If this is Yes, the admin must select which room type is required.

**Required Room Type**
If the above flag is Yes, the admin selects the specific room type that must be used for scheduling this combination. The timetable system will only assign rooms of this type when scheduling this unit.

**Preferred Room (Optional)**
If there is a single specific room that this combination should always use, the admin can specify it here. For example, Chemistry Lab sessions might always happen in the Chemistry Lab room specifically (not just any Science Lab).

**Status (Active / Inactive)**
Determines whether this combination is available for use in Class Group creation.

---

## Business Rules and Conditions

**Unique Combination of Subject + Study Format + Subject Type**
The same subject cannot be combined with the same study format and the same subject type more than once. For example, there can only be one "Science Lecture Major" record. The system prevents duplicates.

**Code Must Be Unique**
The generated code must be unique across all combinations in the school. The system checks and prevents duplicates.

**Room Requirement Logic**
- If Uses Class Home Room is Yes, the room type and preferred room fields are ignored during timetable scheduling
- If Requires Specific Room Type is Yes, the Required Room Type must be selected — this field becomes mandatory
- If Requires Specific Room Type is No, the timetable system will schedule this combination in any available room

**Cannot Delete If Used in Class Groups**
If any Class Group has been created using this Subject + Study Format combination, deletion is blocked. Admin must first remove or update those Class Groups. The system shows a warning.

**Cannot Delete If Options Exist**
If any sub-options have been defined for this combination in the Class Group Options screen (for example, specific game choices under Physical Education), those must be removed first.

**Deactivation**
An inactive combination cannot be selected when creating new Class Groups. Existing Class Groups that reference this combination are not affected.

---

## Workflow Steps

**Adding a New Combination**
Admin opens the Add form, selects the Subject from the dropdown, selects the Study Format, and selects the Subject Type. The system auto-generates the Code (e.g., SCI_LAB) and suggests a Name (e.g., Science Lab). Admin reviews and adjusts the name if needed. Admin sets the room requirement flags and selects the required room type if applicable. Admin submits and a success message appears.

**Viewing All Combinations**
The list shows all subject-study format combinations. Admin can filter by Subject or Study Format to find specific records. Each row shows the code, name, subject type, and room requirement settings.

**Editing a Combination**
Admin clicks on a row and updates the name or room requirement settings. The subject, study format, and subject type should ideally not be changed after the combination has been used in Class Groups.

**Deactivating a Combination**
Admin toggles the status to Inactive. The combination no longer appears in the Class Group creation dropdowns.

---

## Subject Options

### What Are Subject Options?

Subject Options are individual activity or sub-subject choices that students personally select within a shared timetable period. When a Subject + Study Format combination has options, all students in the period share the same time slot — but each student goes to a different room with a different teacher based on their choice.

Options are defined at the Subject + Study Format level, not at the Class Group level. This means once options are added to a combination (for example, PE — Activity has Football, Basketball, Swimming), those same options are automatically available for every Class Group across every class that uses PE — Activity. The admin sets this up once, and it works everywhere.

### When Do You Need Subject Options?

Subject Options are needed when:
- A period has one shared time slot for all students
- But students split into different groups based on individual preference
- Each group goes to a different room and has a different teacher or coach

### Key Fields for Subject Options

**Option Code**
A short unique code for this specific option within the parent combination. This code appears in student preference records and timetable assignments. Examples:
- FB → Football
- BB → Basketball
- SWM → Swimming
- DWG → Drawing
- MUS → Music

**Option Name**
The full readable name shown in student preference forms, timetable views, and result records. Examples: Football, Basketball, Swimming, Drawing and Painting, Classical Music, Bharatanatyam Dance.

**Status (Active / Inactive)**
Whether this option is currently open for student selection. Inactive options are hidden from preference forms but their past selection history is preserved.

### Business Rules for Subject Options

**Options Are Shared Across All Class Groups That Use the Same Combination**
If Football, Basketball, and Volleyball are defined under Physical Education — Activity, then every class that has a Class Group for PE — Activity (whether Grade 6, Grade 8, or Grade 10) will automatically see these same options. There is no need to re-enter options for each class.

**Option Code Must Be Unique Across the Entire School**
The option code must be unique across ALL options defined in the school — not just within one combination. For example, if 'FB' is used for Football under PE Activity, no other option anywhere in the system (whether under Fine Arts or Vocational) can also use 'FB' as its code. The system enforces this globally. This ensures timetable references and student records are never ambiguous.

**Option Name Must Be Unique Within the Same Combination**
Two options under the same Subject + Study Format cannot have the same name. For example, PE — Activity cannot have two options both named "Football". However, "Football" can exist as an option under PE — Activity and a different name can exist under a different combination without conflict.

**A Combination Can Have Zero or Many Options**
Not every combination needs options. Science Lecture has no options — all students simply attend the same class. But PE — Activity has multiple options because students choose their sport. A combination with no options means all students attend the same session with no individual choice involved.

**Cannot Delete an Option If Students Have Selected It**
If any student has already made a selection for this option in the current or any past year, the option cannot be deleted. Admin must first reassign all those students to another active option. The system shows a count of affected students.

**Deactivating an Option Mid-Year**
If an option must be deactivated mid-year (for example, the swimming pool is under repair), the system must alert the admin about every student who had selected Swimming. Admin must then move those students to another active option before the deactivation takes effect.

**Minimum Students to Run an Option**
If fewer than the minimum required students choose an option, the school may decide not to run it. Those students are then asked to pick their second preference. This check is handled during student preference collection, not enforced automatically by the system during setup.

### Workflow for Adding Subject Options

**Adding Options to a Combination**
After creating the Subject + Study Format record, admin opens its detail view and scrolls to the Subject Options section. Admin clicks Add Option, enters the Option Code (e.g., FB) and Option Name (e.g., Football). Admin saves. Admin repeats this for every option under this combination. Options can be added, reordered, or deactivated at any time as long as student selections are handled correctly.

**Viewing Options**
Options are listed within the detail view of the Subject + Study Format combination. Each option row shows its code, name, status, and the number of students currently enrolled in that option.

**Editing an Option**
Admin can update the name or status of an option. The option code should not be changed once students have made their selection, as it is used as a reference in timetable and student records.

**Deactivating an Option**
Admin toggles the status to Inactive. If students have selected this option, the system warns the admin and lists the affected students.

**Deleting an Option**
Admin can delete an option only if no student has ever selected it. If selections exist, the system blocks deletion and displays a warning.

---

## Example Scenario

A school defines the following Subject + Study Format combinations for its academic setup:

---

**1. Maths Lecture (MTH_LAC)** — Subject: Mathematics, Format: Lecture, Type: Major
- Uses Home Room: No | Requires Specific Room Type: No
- Subject Options: **None** — all students attend the same Maths class, no individual choice

---

**2. Science Lab (SCI_LAB)** — Subject: Science, Format: Lab, Type: Major
- Uses Home Room: No | Requires Specific Room Type: Yes → Science Laboratory
- Subject Options: **None** — all students attend the same lab session together

---

**3. Physical Education — Activity (PE_ACT)** — Subject: Physical Education, Format: Activity, Type: Sports
- Uses Home Room: No | Requires Specific Room Type: Yes → Sports Area
- Subject Options: **Yes — students individually choose one sport**

| Option Code | Option Name | Room Used |
|---|---|---|
| FB | Football | Football Ground |
| BB | Basketball | Indoor Basketball Court |
| VB | Volleyball | Volleyball Court |
| SWM | Swimming | Swimming Pool |
| YOG | Yoga | Activity Hall |
| GYM | Gymnastics | Gymnasium |

How this works: All students from Grade 8 have their PE period at the same time (say, Period 5 on Monday and Wednesday). But they are split by their chosen sport. Football students go to the Football Ground with the Football coach. Yoga students go to the Activity Hall with the Yoga instructor. The timetable system handles this split automatically using the option selections each student has made.

Since options are defined at the combination level, Grade 6, Grade 8, and Grade 10 — all of which use PE — Activity — automatically get the same six sport options without the admin needing to re-enter them for each class.

---

**4. Fine Arts — Activity (FA_ACT)** — Subject: Fine Arts, Format: Activity, Type: Minor
- Uses Home Room: No | Requires Specific Room Type: Yes → Activity Room
- Subject Options: **Yes — students individually choose one art form**

| Option Code | Option Name | Room Used |
|---|---|---|
| DWG | Drawing and Painting | Art Room |
| MUS | Classical Music | Music Room |
| WMUS | Western Music | Band Room |
| DNC | Bharatanatyam Dance | Dance Studio |
| POT | Pottery and Craft | Craft Room |

How this works: All Grade 7 students have their Fine Arts period at the same time. Students who chose Music go to the Music Room, Dance students go to the Dance Studio, and so on — all in the same timeslot, managed by different teachers.

---

**5. Vocational — Work Education (VOC_ACT)** — Subject: Work Education, Format: Practical, Type: Minor
- Uses Home Room: No | Requires Specific Room Type: Yes → Lab / Workshop
- Subject Options: **Yes — students individually choose one vocational skill**

| Option Code | Option Name | Room Used |
|---|---|---|
| CA | Computer Applications | Computer Lab |
| HS | Home Science | Home Science Lab |
| EL | Basic Electronics | Electronics Workshop |
| MM | Mass Media Studies | Media Room |

All three sets of options (PE, Fine Arts, Vocational) are created once in this screen. When the admin creates Class Groups in the next screen, every Class Group that uses PE — Activity automatically inherits the six sport options. No extra setup is needed per class.

---

## Related Screens

- **Subject** — The subject used in this combination must already exist
- **Study Format** — The delivery format used in this combination must already exist
- **Subject Type** — The classification type must already exist
- **Class Group** — Class Groups are created by linking a Subject + Study Format combination to a specific class and section; all Subject Options defined here are automatically inherited by those Class Groups
- **Class Group Options** — This is where the Subject Options defined here are linked to specific Class Groups with their per-student period requirements and room assignments for the timetable engine
- **Student Admission / Preference Collection** — When a student is admitted, they select their preferred option (e.g., which sport, which art form) from the options defined here
