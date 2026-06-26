# Class Group — Business Requirements

## What This Screen Does

The Class Group screen is the most critical screen in the Class Setup module for timetable planning. This is where the school specifies exactly what needs to be taught, to which class and section, and how frequently.

A Class Group answers the following question: "For a specific class (and optionally a specific section), how many periods of a particular subject-delivery combination are needed per week, and what room requirements apply?"

For example:
- Grade 10 Section A → Science Lecture → 5 periods per week → in any regular classroom
- Grade 10 Section A → Science Lab → 2 periods per week → must be in Science Lab
- Grade 8 (All Sections) → Maths Lecture → 6 periods per week → in any classroom

This screen is the direct input to the Timetable module. Without Class Groups defined, the timetable cannot be generated.

---

## When This Screen Is Used

- At the beginning of the academic year when the timetable is being planned
- When a new subject is introduced for a class and needs to be scheduled
- When the number of periods for a subject changes for a specific class
- When room requirements for a class group change
- When a subject is removed from a class's timetable

---

## Key Fields at a Glance

**Class**
The class this group belongs to. For example: Grade 10, Grade 8.

**Section (Optional)**
The specific section this group applies to. If left blank, this Class Group applies to all sections of the selected class. If a section is selected, it applies only to that specific section (e.g., only Grade 10 Section A).

**Subject + Study Format**
The subject-delivery combination for this group. Selected from combinations defined in the Subject + Study Format screen. For example: Science Lecture, Science Lab, Maths Lecture.

**Code**
A system-generated unique code that combines the class code, section code (if applicable), subject code, and study format code. For example: 10th_A_SCI_LAC or 8th_MTH_LAC. This code is used in the timetable engine.

**Name**
The full readable name of this class group. For example: Grade 10 Section A — Science Lecture or Grade 8 — Maths Lecture (All Sections).

**Is Compulsory**
Whether this subject-delivery combination is compulsory for all students in this class group, or whether students can opt out. For compulsory subjects, all students in the class section must attend. For optional subjects, only enrolled students attend.

**Required Periods Per Week**
The standard number of periods per week that must be scheduled for this class group. For example, Maths Lecture requires 6 periods per week for Grade 10.

**Minimum Periods Per Week**
The minimum number of periods per week that must be scheduled. The timetable engine must not go below this number.

**Maximum Periods Per Week**
The maximum number of periods per week allowed. The timetable engine must not exceed this number.

**Minimum Periods Per Day**
The minimum number of times this subject can appear in a single school day. Useful for preventing a subject from being scheduled only once at the end of the week.

**Maximum Periods Per Day**
The maximum number of times this subject can appear in a single school day. Prevents the timetable from placing all periods for one subject on a single day (for example, 6 Maths periods in one day would be inappropriate).

**Minimum Gap Between Periods**
The minimum number of other periods that must come between two periods of this subject within the same day. Set to 0 if consecutive periods are allowed.

**Allow Consecutive Periods**
Whether this subject can be scheduled in back-to-back periods on the same day. Some subjects like Lab sessions or PE benefit from consecutive periods. Others like Maths or English should not repeat consecutively.

**Maximum Consecutive Periods**
If consecutive periods are allowed, how many can occur in a row. For example, Science Lab may allow up to 2 consecutive periods (a double period).

**Priority Score**
A number from 1 to 100 indicating the priority of this class group when the timetable engine is making scheduling decisions. Higher priority class groups are scheduled first. Core academic subjects like Maths and English typically have higher priority than optional or activity subjects.

**Uses Class Home Room**
Whether this class group must always be scheduled in the class's own home room. Overrides the setting from the Subject + Study Format screen if set differently here.

**Requires Specific Room Type**
Whether this class group requires a particular room type. If Yes, the admin selects the required room type.

**Required Room Type**
The type of room that must be used when scheduling this class group. For example, Science Lab class groups require the Science Laboratory room type.

**Preferred Room (Optional)**
A specific room that this class group should always be scheduled in, if available. The timetable engine will try to use this room first. If unavailable, it will use any available room of the required type.

**Display Order (Ordinal)**
Controls the order in which class groups appear in the timetable planning lists.

**Status (Active / Inactive)**
Determines whether this class group is included in timetable generation.

---

## Business Rules and Conditions

**Unique Combination of Class + Section + Subject + Study Format**
The same class-section combination cannot have two class groups with the same subject-study format. For example, Grade 10 Section A cannot have two entries for Science Lecture. The system prevents this duplicate.

**Section is Optional — But Shared Group Cannot Coexist With Section-Specific Group**
If a class group is defined without a section (applying to all sections of Grade 10), then a section-specific class group for the same subject-study format cannot also exist for that class. Either one shared group applies to all sections, or section-specific groups are defined individually.

**Required Periods Cannot Exceed Maximum or Be Below Minimum**
The Required Periods Per Week must be between the Minimum and Maximum values. The system validates this on save.

**Max Per Day Cannot Exceed Required Per Week**
The Maximum Periods Per Day cannot be greater than the Required Periods Per Week. For example, if only 3 periods per week are required, the maximum per day cannot be set to 4.

**Consecutive Period Logic**
If Allow Consecutive Periods is No, then Maximum Consecutive Periods and Minimum Gap Between Periods must reflect that restriction. If Allow Consecutive Periods is Yes, Maximum Consecutive Periods must be at least 2.

**Cannot Delete If Subject Group Links Exist**
If any Subject Group has linked to this Class Group via the Subject Group + Subject screen, deletion is blocked. Admin must first remove those links.

**Deactivation Removes From Timetable**
An inactive Class Group is excluded from timetable generation. If a Class Group is deactivated mid-year, the timetable system will flag that an existing scheduled slot now has no active Class Group backing it.

---

## Workflow Steps

**Adding a New Class Group**
Admin opens the Add form, selects the class and optionally a section, selects the Subject + Study Format combination, reviews the auto-generated code and name. Admin enters period requirements (required, min, max per week and per day), sets consecutive period rules, enters priority score. Admin reviews room requirements inherited from the Subject + Study Format screen and overrides if needed. Admin submits and a success message appears.

**Viewing Class Groups**
Admin can view class groups filtered by class or section. The list shows the code, name, periods per week, room type, and status. This view is used by the timetable coordinator to review all scheduling requirements before generating the timetable.

**Bulk Setup (Recommended for New Year)**
At the beginning of the year, admin can copy Class Groups from the previous year's setup as a starting point, then adjust periods and room requirements as needed. This saves time when the class structure is mostly unchanged.

**Editing a Class Group**
Admin clicks on a row and updates period requirements, room settings, or priority score. The class, section, and subject-study format combination should not be changed after creation — a new class group should be created instead.

**Deactivating a Class Group**
Admin toggles the status to Inactive when a subject is no longer to be scheduled for that class.

---

## Example Scenario

For Grade 10 Section A, the school defines the following Class Groups:

| Subject + Format | Req/Week | Min/Max Per Day | Consecutive | Room Type |
|---|---|---|---|---|
| Maths Lecture | 6 | Min 1, Max 2 | No | Any Classroom |
| Science Lecture | 5 | Min 1, Max 2 | No | Any Classroom |
| Science Lab | 2 | Min 0, Max 2 | Yes (max 2) | Science Lab |
| English Lecture | 5 | Min 1, Max 2 | No | Any Classroom |
| Hindi Lecture | 4 | Min 1, Max 1 | No | Any Classroom |
| SST Lecture | 4 | Min 1, Max 1 | No | Any Classroom |
| PE / Sports | 2 | Min 1, Max 2 | Yes (max 2) | Sports Ground |

The timetable engine reads all these Class Groups for Grade 10 Section A and generates a weekly timetable that respects all the period counts, daily limits, consecutive rules, and room assignments.

---

## Related Screens

- **Subject + Study Format** — Class Groups are built on top of these combinations
- **Class** and **Sections** — Class Groups reference a class and optionally a specific section
- **Subject Group + Subject** — Links from Subject Groups point to Class Groups to tell the system which class groups make up a student's subject bundle
- **Class Group Options** — Sub-choices (like specific game options under PE) are defined for a Class Group
