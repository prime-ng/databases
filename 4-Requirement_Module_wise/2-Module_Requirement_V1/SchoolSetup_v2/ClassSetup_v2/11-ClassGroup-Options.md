# Class Group Options — Business Requirements

## What This Screen Does

The Class Group Options screen is where the admin links specific student-choice activity options to a Class Group and sets how many periods per week each option needs for that class.

When a Subject + Study Format has multiple student choices — like Physical Education where students pick between Football, Basketball, or Swimming — those choices are first created globally in the Subject + Study Format screen. This screen is the next step. Here the admin decides: "For Grade 8 Section A's PE Class Group, Football is available with 2 periods, Basketball is available with 2 periods. We are not offering Swimming for this class this year."

This gives the school full flexibility to offer different activity choices to different classes. Grade 6 might offer Football and Yoga only. Grade 8 might offer Football, Basketball, and Swimming. Each class is configured independently here without affecting the others.

---

## When This Screen Is Used

- When a Class Group uses a Subject + Study Format that has student-choice options and the admin needs to activate which options are available for that specific class
- When a new option needs to be added to a class group for the current year (for example, adding Yoga to Grade 10 PE this year)
- When an option needs to be removed from a class group (for example, Swimming is unavailable for Grade 6 because the pool is under repair)
- When the number of periods for a specific option needs to be updated

---

## Key Fields at a Glance

**Class Group**
The Class Group this option is being linked to. For example: Grade 8 Section A — PE Activity. Admin selects this from the list of existing Class Groups.

**Subject Option**
The specific student-choice activity being activated for this Class Group. Admin selects this from the list of options defined under the parent Subject + Study Format combination. For example: Football, Basketball, Yoga. Only options belonging to the same Subject + Study Format as the Class Group appear in the selection list.

**Option Periods Per Week**
How many periods per week this specific option requires within this Class Group. For example, if Football is being set up for Grade 8 PE, the admin enters how many periods Football students will have per week. This is usually the same as the Class Group's total period count but can be set differently if a specific option needs fewer periods.

**Class (Auto-Captured)**
The class of the parent Class Group (e.g., Grade 8) is automatically recorded by the system when the record is saved. Admin does not select this separately.

**Section (Auto-Captured)**
The section of the parent Class Group (e.g., Section A) is automatically recorded by the system. If the Class Group applies to all sections of the class, this is left blank.

**Subject + Study Format (Auto-Captured)**
The parent Subject + Study Format combination that the selected option belongs to (e.g., PE — Activity) is automatically recorded by the system from the option record. Admin does not select this separately. This allows the timetable engine to directly know which subject combination this option slot belongs to without having to trace it back through multiple records.

**Option Code (Auto-Captured)**
The short code of the selected option (e.g., FB for Football, BB for Basketball) is automatically copied from the Subject Option record when the record is saved.

**Option Name (Auto-Captured)**
The full name of the selected option (e.g., Football, Basketball, Yoga) is automatically copied from the Subject Option record when the record is saved. This appears in timetable views and student records.

**Overall Class Group Periods Per Week (Auto-Captured)**
The total weekly periods of the parent Class Group (e.g., PE has 2 periods per week for Grade 8) is automatically copied from the Class Group record when the record is saved.

---

## Business Rules and Conditions

**Same Option Cannot Be Added to the Same Class Group Twice**
A specific option (e.g., Football) can only be linked once to a specific Class Group (e.g., Grade 8 Section A PE). The system prevents duplicate entries for the same class, section, subject, and option combination. For example, you cannot add Football twice to the Grade 8 Section A PE Class Group.

**Only Options From the Same Subject + Study Format Can Be Selected**
The selection list only shows options that belong to the same Subject + Study Format as the Class Group. If the Class Group is for PE — Activity, only PE — Activity options appear. Fine Arts or Vocational options are not shown.

**Option Periods Should Not Exceed the Class Group's Total Weekly Periods**
The periods entered for an individual option should not be more than the total periods assigned to the parent Class Group. If the PE Class Group has 2 periods per week, each option should also have 2 periods or fewer.

**Cannot Remove an Option If Students Have Already Chosen It**
If students have already selected this option for the current year, the option cannot be removed from the class group. Admin must first reassign all affected students to another active option. The system shows how many students are affected before allowing any action.

**System Auto-Captures Related Data on Save and Update**
When a record is saved or updated, the system automatically fetches and stores the class, section, option code, option name, and overall class group period count from the related records. Admin does not fill these in manually. This is required so the timetable engine can access all necessary scheduling information from a single record without having to fetch it from multiple screens at runtime. If any of these values change in the parent records, the system must update them here as well to keep everything in sync.

---

## Workflow Steps

**Adding Options to a Class Group**
Admin opens the Class Group Options screen and selects the Class Group (e.g., Grade 8 Section A — PE Activity). The system shows all options defined for the parent Subject + Study Format. Admin selects which options to offer for this class, enters the periods per week for each, and saves. The system automatically records the class, section, option code, option name, and overall period count alongside each record. A success message confirms the setup is complete.

**Viewing Configured Options**
Admin selects a Class Group and sees all the options currently configured for it. Each row shows the option name, periods per week, and how many students have chosen that option.

**Removing an Option**
Admin selects an option row and removes it. If students have already chosen this option, the system blocks removal and shows the count of affected students. Admin must first reassign those students to another option.

**Updating Option Periods**
Admin clicks on an existing option row, updates the periods per week, and saves. The system re-captures all related data to ensure the record stays accurate.

---

## Example Scenario

The school has a Class Group: **Grade 8 Section A — PE Activity** that requires 2 periods per week. The PE — Activity Subject + Study Format has 6 options defined: Football, Basketball, Volleyball, Swimming, Yoga, Gymnastics.

The school decides to offer only three sports for Grade 8 Section A this year — the pool is being renovated and gymnastics equipment has not arrived:

| Option | Periods Per Week |
|---|---|
| Football | 2 |
| Basketball | 2 |
| Yoga | 2 |

Admin selects the Grade 8 Section A PE Class Group, picks Football, Basketball, and Yoga from the list, sets 2 periods for each, and saves. The system automatically records: Grade 8, Section A, option codes FB / BB / YOG, option names Football / Basketball / Yoga, and 2 as the overall class group period count — alongside each record.

Students in Grade 8 Section A now see only three choices on their preference form. Football students go to the Football Ground, Basketball students go to the Indoor Court, and Yoga students go to the Activity Hall — all at the same time slot, with different coaches.

Next year, once the pool is ready, admin simply adds Swimming as a fourth option for Grade 8 Section A on this same screen.

---

## Related Screens

- **Class Group** — The parent Class Group must exist before options can be configured here
- **Subject + Study Format** — Where the base options (Football, Basketball etc.) are first defined globally; this screen selects from them for a specific class group
- **Student Admission / Preference** — Students choose from the options activated here when submitting their preferences at the start of the year
- **Timetable Module** — Reads this screen's data to correctly split and schedule students into different rooms during shared periods
