# Department-Designation Management — Business Requirements

## Purpose

This single screen brings together all the reference data that a school needs to define its organizational structure and employee operations. It answers: **How is the school organized as a workplace, and what rules govern its people?**

All six tabs on this screen are simple master-data lists — they define the vocabulary the rest of the system uses when referring to departments, designations, attendance, leave, categories, and disablement reasons.

---

## Tab 1: Department

### What It Defines
Departments are the functional units within a school:
- Examples: Science Department, Mathematics Department, Administration, Accounts, Transport, Sports
- Each department has a name and an optional code

### Business Rules

| Rule | Rationale |
|------|-----------|
| A department name should be unique within the school. | Duplicate department names would create ambiguity when assigning employees and running reports. |
| System-protected departments cannot be edited or deleted. | Core departments like "Administration" are seeded by the platform and must always exist. |
| A department that has employees assigned to it cannot be force-deleted. | Deleting a department that still has active employees would orphan those employee records. Soft-delete is allowed, which deactivates the department but preserves the linkage for historical reference. |

### Business Flow
1. HR Admin reviews the list of departments — most schools start with defaults (Academic, Administrative, Accounts, etc.)
2. If additional departments are needed (e.g., " Robotics Lab"), the admin creates a new one
3. When employees are created, they are assigned to a department
4. If a department becomes obsolete, it can be deactivated or soft-deleted

---

## Tab 2: Designation

### What It Defines
Designations are the job titles or positions within the school:
- Examples: Principal, Vice Principal, Head of Department, Senior Teacher, Teacher, Clerk, Accountant, Lab Assistant
- Each designation has a name and an optional code

### Business Rules

| Rule | Rationale |
|------|-----------|
| A designation name should be unique within the school. | Two designations with the same name would be indistinguishable when assigning roles. |
| System-protected designations cannot be edited or deleted. | Core titles like "Teacher" are seeded by the platform. |
| A designation that has employees assigned to it cannot be force-deleted. | Same integrity protection as departments — preserving historical employee records. |

### Business Flow
1. HR Admin creates or reviews the list of designations
2. Employees are assigned a designation at creation time
3. Designations help determine role-based permissions, reporting hierarchy, and salary structures
4. Designations can be reordered or deactivated as organizational needs change

---

## Tab 3: Attendance Types

### What It Defines
The codes used to mark employee attendance each day:
- Examples: Present, Absent, Late, Half Day, Holiday, Work From Home
- Each type has: a code, a name, a display order, who it applies to (employees, students, or both), and a flag for whether it counts as "present"

### Business Rules

| Rule | Rationale |
|------|-----------|
| Each attendance type has a **present flag** that determines whether it counts toward attendance percentage. | "Present" should count positively; "Absent" should not. "Late" might count as present for some schools or not for others. The flag gives flexibility. |
| The applicable-for field controls which user groups see this type. | Some attendance types are for employees only (e.g., "On Duty"), some for students only, some for both. |
| Attendance types are ordered by display order. | Common types like "Present" and "Absent" should appear first. Less common types appear further down. |
| At least one attendance type should be marked as present. | Without a "present" type, the attendance system would not be able to mark anyone as present. The system should seed a default "Present" type. |

### Business Flow
1. Admin reviews the default attendance types (Present, Absent, Late, Half Day)
2. If the school has unique attendance categories (e.g., "On Field Trip"), they can add custom types
3. When taking daily attendance, staff select from this list
4. Reports calculate attendance percentages based on the present flag
5. Types can be reordered, deactivated, or deleted as needed

---

## Tab 4: Categories

### What It Defines
Staff classification labels that group employees by employment type:
- Examples: Permanent, Temporary, Contract, Probation, Visiting, Intern
- Each category has: a code, a name, a description, and an applicable-for field (Staff, Student, or Both)

### Business Rules

| Rule | Rationale |
|------|-----------|
| Categories are used to classify employees and sometimes students. | Knowing whether a teacher is permanent or contract affects payroll, benefits, and leave policy. |
| The applicable-for field controls where the category appears. | "Staff" categories show in employee forms. "Student" categories show in student forms. "Both" appears everywhere. |
| Categories can be deactivated but not permanently deleted if they have active references. | Deactivation is safer — it hides the category from new selections while preserving historical assignments. |

### Business Flow
1. Admin creates categories to reflect the school's employment types
2. When creating an employee profile, the admin selects the category
3. Reports can filter by category (e.g., "all contract teachers")
4. If an employment type is discontinued, the category can be deactivated

---

## Tab 5: Disable Reasons

### What It Defines
Standardized reasons for deactivating or disabling an employee record:
- Examples: Resigned, Retired, Transferred, Terminated, Suspended, Deceased, Contract Ended
- Each reason has: a code, a name, a description, whether the action is reversible, whether it counts toward attrition reporting, and who it applies to

### Business Rules

| Rule | Rationale |
|------|-----------|
| The **reversible flag** indicates whether a disabled record can be reactivated. | A teacher on suspension might return; a resigned teacher likely will not. This flag affects the UI and workflow after disablement. |
| The **count attrition flag** determines whether this reason factors into staff turnover reporting. | Resignations and terminations count toward attrition. Retirements might or might not, depending on school policy. |
| The applicable-for field controls who can use this reason. | Some reasons are only for employees (e.g., "Resigned"), others for students (e.g., "Expelled"). |
| Disable reasons help maintain clean records. | Without standardized reasons, deactivations would lack context, making it hard to audit or report on employee turnover. |

### Business Flow
1. Admin sets up the list of disable reasons that apply to the school
2. When an employee leaves or is deactivated, the admin selects the appropriate reason
3. The system records the reason alongside the deactivation date
4. Turnover reports use the attrition flag to calculate staff attrition rates
5. If the deactivation is reversible, the admin can restore the record later

---

## Tab 6: Student Leave Types

### What It Defines
Types of leave that students can apply for:
- Examples: Sick Leave, Medical Leave, Emergency Leave, Family Event
- Each type has: a name, any associated rules (documentation requirements, maximum days, etc.)

### Business Rules

| Rule | Rationale |
|------|-----------|
| Student leave types are simpler than employee leave types. | Students do not have paid leave, carry-forward, or encashment. Their leave is purely for tracking absences. |
| Some leave types may require documentation (e.g., medical certificate for Sick Leave). | Schools need to verify the reason for student absences, especially for extended leave. |
| Student leave types can be deactivated. | If a leave type is no longer offered, it can be hidden without deleting historical records. |

### Business Flow
1. Admin defines the types of leave applicable to students
2. When applying for leave, students or parents select a leave type
3. The system tracks student absences by leave type for reporting
4. Parents can view their child's leave history categorized by type

---

## Cross-Tab Business Rules

| Rule | Rationale |
|------|-----------|
| All six tabs share the same screen and are independent of each other. | Changes in one tab (e.g., deactivating a department) do not affect data in another tab. They are separate reference lists. |
| All six entities support soft-delete, restore, and force-delete with referential integrity checks. | Consistent data protection across all reference data. |
| All six entities log activity for audit purposes. | Every change to these reference lists is tracked. |
| System records across all tabs cannot be modified or removed. | Core seeded data (e.g., "Teacher" designation, "Present" attendance type) must always exist for the system to function. |

---

## Scenarios and Edge Cases

### Scenario 1: A department is renamed after employees have been assigned
The "Computer Department" is renamed to "Information Technology Department."
- The department record is updated. All employees who were in "Computer Department" now show "Information Technology Department."
- Historical reports still show the old name for the period before the rename.
- No employee records need to be reassigned.

### Scenario 2: An attendance type is deactivated mid-year
"Half Day" is being misused and the school decides to remove it.
- Deactivating it hides it from the daily attendance marking screen.
- Previous attendance records that used "Half Day" are preserved.
- Teachers can no longer select "Half Day" for new entries.
- **Impact:** Attendance percentages for the year are now calculated without the "Half Day" option. Teachers must use "Present" (full day) or "Absent" instead.

### Scenario 3: A category is used in employee contracts
"Contract" category is used by 50 teachers. The school wants to merge it with "Temporary."
- **Option 1:** Create a "Temporary" category (if not existing). Deactivate "Contract." The 50 teachers remain classified as "Contract" historically.
- **Option 2:** Create "Temporary." Reassign all 50 teachers to "Temporary." Deactivate "Contract."
- **Important:** The category itself cannot be deleted if teachers reference it. Deactivation is the correct approach.

### Scenario 4: A disable reason for "Resigned" should count attrition but "Retired" should not
The school wants to track turnover but recognizes retirement as natural attrition.
- "Resigned" has `count_attrition = true`.
- "Retired" has `count_attrition = false`.
- Reports calculate turnover rate using only reasons with `count_attrition = true`.

### Scenario 5: A student leave type requires doctor's note after 3 days
"Sick Leave" should require documentation only for absences exceeding 3 days.
- The leave type configuration sets `min_doc_required_days = 3`.
- A 2-day sick leave does not require documents.
- A 5-day sick leave prompts the student to upload a medical certificate.
- The leave application cannot be submitted without the required documents.
