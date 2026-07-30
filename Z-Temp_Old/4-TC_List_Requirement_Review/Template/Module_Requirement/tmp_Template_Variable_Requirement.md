# Template Variable Registry — Business Requirements

## What This Screen Does

The Template Variable Registry screen is where school administrators manage all merge placeholders used in document layouts — report cards, ID cards, mark sheets, certificates, and other printed items. Each placeholder (called a variable) represents a piece of information that will be filled in when the document is generated — for example, a student's name, roll number, photograph, or grade.

The screen shows a list of all registered variables grouped under their template categories. Administrators can create new variables, edit existing ones, remove variables from view, restore them, permanently delete them, and turn them on or off.

Every variable is linked to exactly one template category (such as Marksheet, ID Card, or Certificate) and has a unique name within that category. Variables can be set to one of two modes:
- **Automated Mode** — The system picks the value automatically from a connected data source (a specific area, table, and field)
- **Manual Mode** — The module that calls the document layout supplies the value directly

---

## When This Screen Is Used

- **Setting Up a New Document Layout** — When a school administrator is designing a new template and needs placeholders for student or school data
- **Adding Custom Placeholders** — When a standard variable does not exist and a new one must be created for a specific layout need
- **Connecting Variables to Data Sources** — When an automated variable needs to be pointed to the correct database field so the engine can fetch the value
- **Managing Manual Variables** — When a variable is supplied directly by the calling module rather than fetched automatically
- **Removing and Restoring Variables** — To temporarily hide a variable from the template designer or reinstate it from trash
- **Permanently Deleting Variables** — To permanently remove a variable and all its links to templates
- **Turning Variables On or Off** — To make a variable available or unavailable in the template designer without removing it

---

## Who Can Access This Screen

- **School Admin** — Full access including create, edit, remove, restore, permanent delete, and status toggle
- **Template Designer** — Can create and edit variables for use in document layouts
- **Principal** — Read-only access to view the variable registry

The system checks the user's permissions before every action to ensure only authorised staff can perform each operation.

---

## How This Screen Works — Step by Step

### The Variable List

When an administrator opens the Template Variable Registry, the system shows all registered variables (20 per page) with columns: #, Variable Name, Template Category, Mode (Automated or Manual), Data Source (if automated), Active toggle, and Actions (Edit, Delete). A filter panel above the list lets administrators narrow down by Template Category and Active/Inactive status.

The list shows only active variables by default. A separate "Trash" tab shows removed records.

### Creating a Variable

When the administrator clicks "Add Variable," they see a form with the following fields:

**Basic Information:**
- Template Category (required, chosen from a predefined list — e.g., Marksheet, ID Card, Certificate, Transfer Certificate)
- Variable Name (required, must use only lowercase letters and underscores, no spaces or special characters — e.g., `student_name`, `total_marks`)
- Description (optional, a brief explanation of what this variable represents)

**Data Source Mode:**
- The administrator selects either Automated Mode or Manual Mode

**If Automated Mode is selected:**
- The administrator selects the data source in three steps:
  1. Choose the database area
  2. Choose the table within that area
  3. Choose the specific column or field
- The system updates the choices after each selection to show only valid options for the next step

**If Manual Mode is selected:**
- The data source fields are left empty
- The module that calls the document layout will provide the value at generation time

**Status:**
- Active toggle (defaults to Active)

When the administrator clicks "Save," the system checks that the variable name is unique within the selected template category, validates all fields, creates the variable record, and returns to the list with a success message.

### Editing a Variable

The edit form opens with all existing values pre-filled. The variable name uniqueness check ignores the current variable being edited and also ignores deleted records (so a deleted variable's name can be reused for a new one in the same category). The data source selections are pre-filled. If the mode changes from Automated to Manual, the data source fields are cleared. Every change is recorded with a timestamp.

### Removing and Restoring

When an administrator removes a variable, the record is hidden but retained in the system. The link between this variable and any templates that use it is also removed. The administrator can restore the variable from the Trash page — the variable is reinstated, and it becomes available again in the template designer.

### Permanently Deleting

When an administrator permanently deletes a variable from the Trash, the variable record is permanently removed from the system along with all its links to any templates. This action cannot be undone.

### Toggle Status

Administrators can turn a variable's active status on or off directly from the list view without reloading the page. Each change is saved with a timestamp. Inactive variables are hidden from the variable picker in the template designer.

---

## Validation Rules — What's Required Before Saving

### Basic Information:

| Field | Rule |
|-------|------|
| Template Category | Required, must be a valid option from the predefined list |
| Variable Name | Required, must use only lowercase letters and underscores, no spaces or special characters |
| Variable Name Uniqueness | Must be unique within the selected template category (ignores the variable being edited and deleted records) |
| Description | Optional, up to 500 characters |

### Data Source Mode:

| Field | Rule |
|-------|------|
| Mode | Required, must be either Automated or Manual |
| Database Area | Required only if Mode is Automated; must be a valid option |
| Table | Required only if Mode is Automated; must be a valid option within the selected database area |
| Column | Required only if Mode is Automated; must be a valid option within the selected table |

### Status:

| Field | Rule |
|-------|------|
| Active | Optional, can be Yes or No |

---

## Business Rules and Conditions

### Rule BR-TVR-001: Variable Name Format
Variable names must use only lowercase letters (a–z), underscores (_), and digits (0–9). The name must start with a letter. No spaces, hyphens, or special characters are allowed. This ensures the placeholder can be embedded in document layouts without errors.

### Rule BR-TVR-002: Variable Name Uniqueness Per Category
Each variable name must be unique within its template category. Two different categories may have variables with the same name (e.g., `student_name` can exist under both Marksheet and ID Card). Deleted records are excluded from this check.

### Rule BR-TVR-003: Automated Mode Requires Complete Data Source
When a variable is set to Automated Mode, all three data source selections (database area, table, and column) must be provided. The system validates that the selected column belongs to the selected table, and the selected table belongs to the selected database area.

### Rule BR-TVR-004: Data Source Selections Are Progressive
When choosing the data source in Automated Mode, the administrator must first select the database area, then the table (only tables within that area are shown), and then the column (only columns within that table are shown). The options narrow down at each step.

### Rule BR-TVR-005: Manual Variables Have No Data Source
Manual Mode variables do not store a data source. The calling module provides the value when the document is generated. The data source fields must be left empty when Manual Mode is selected.

### Rule BR-TVR-006: Remove Cascade Removes Template Links
When a variable is removed (sent to trash), all links between that variable and every template that uses it are also removed. When the variable is restored, it does not automatically re-link to templates — the administrator must re-add the variable to each template manually.

### Rule BR-TVR-007: Permanent Delete Also Removes All Links
When a variable is permanently deleted, all its links to templates are permanently removed as well. This is done as a single complete operation.

### Rule BR-TVR-008: Only Active Variables Appear in Template Designer
When administrators are adding variables to a document layout in the template designer, only active variables within the selected template category are shown. Inactive and removed variables are excluded.

### Rule BR-TVR-009: All Changes Are Tracked
Every operation — create, edit, remove, restore, permanent delete, toggle status — is recorded with a timestamp. Each entry captures who did it, what action was taken, and a description of the change.

### Rule BR-TVR-010: Pre-Seeded Common Variables
Each template category comes with a standard set of pre-seeded variables:
- **Marksheet:** student_name, roll_no, class_name, section_name, subject_name, subject_code, total_marks, obtained_marks, percentage, grade, academic_year, term_name, school_name, school_address, date_of_issue
- **ID Card:** student_name, photo, admission_no, class_name, section_name, roll_no, school_name, school_address, school_logo, blood_group, emergency_contact, date_of_birth, valid_until
- **Certificate:** student_name, father_name, mother_name, date_of_birth, class_name, school_name, school_address, date_of_issue, certificate_number, principal_name

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| BR-TVR-001 | Variable names must be lowercase letters, underscores, and digits only |
| BR-TVR-002 | Variable name must be unique within its category |
| BR-TVR-003 | Automated variables need a complete data source (area, table, column) |
| BR-TVR-004 | Data source selection narrows down step by step |
| BR-TVR-005 | Manual variables leave data source fields empty |
| BR-TVR-006 | Removing a variable also removes its links to all templates |
| BR-TVR-007 | Permanently deleting a variable also removes all template links |
| BR-TVR-008 | Only active variables appear in the template designer picker |
| BR-TVR-009 | All changes are recorded with user and timestamp |
| BR-TVR-010 | Common variables are pre-seeded for each category |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Template category not selected | "The template category field is required." |
| Invalid template category | "The selected template category is invalid." |
| Missing variable name | "The variable name field is required." |
| Variable name invalid format | "The variable name must only contain lowercase letters, underscores, and digits." |
| Duplicate variable name in category | "The variable name has already been taken in this category." |
| Missing database area for automated mode | "The database area is required when mode is set to Automated." |
| Missing table for automated mode | "The table is required when mode is set to Automated." |
| Missing column for automated mode | "The column is required when mode is set to Automated." |
| Invalid database area | "The selected database area is invalid." |
| Invalid table for selected area | "The selected table is invalid for this database area." |
| Invalid column for selected table | "The selected column is invalid for this table." |
| Description too long | "The description must not exceed 500 characters." |
| Invalid active status | "The active field must be set to Yes or No." |
| Record not found | "Template variable not found." |

---

## Success Scenarios

- An administrator creates a new variable: Template Category = "Marksheet", Variable Name = "term_fee_total", Description = "Total term fee amount for the student", Mode = "Automated", Database Area = "Fees", Table = "fee_transactions", Column = "total_amount". The system saves the variable, makes it available in the Marksheet category in the template designer, and returns to the list with a success message.

- An administrator creates a new variable: Template Category = "ID Card", Variable Name = "bus_route_name", Description = "Student's bus route name", Mode = "Manual". The system saves the variable without a data source. The calling module will supply the value when the ID card is generated.

- An administrator turns a variable from Active to Inactive via the list toggle. The variable disappears from the variable picker in the template designer. A timestamped record is created.

- An administrator removes a variable that is linked to three different Marksheet templates. The variable is hidden and all three template links are removed. The administrator later restores the variable — it becomes available again but must be re-added to each template manually.

---

## Failure Scenarios

- An administrator tries to create a variable with name "student-name" (using a hyphen). The system rejects with "The variable name must only contain lowercase letters, underscores, and digits."

- An administrator tries to create a variable "total_marks" under the Marksheet category when "total_marks" already exists in that category. The system rejects with "The variable name has already been taken in this category."

- An administrator selects Automated Mode but leaves the database area empty. The system rejects with "The database area is required when mode is set to Automated."

- An administrator selects Automated Mode, chooses a database area, but selects a table that does not belong to that area. The system rejects with "The selected table is invalid for this database area."

- An administrator tries to permanently delete a variable from the Trash. The system removes the variable and all its template links permanently.

---

## Example Scenario

Mr. Sharma, the School Admin of Sunshine International School, needs to add a new placeholder for printing "bus_route_name" on student ID cards.

He navigates to Template Variable Registry and clicks "Add Variable":

1. **Basic Information:** He selects Template Category = "ID Card", enters Variable Name = "bus_route_name", and writes Description = "Student's bus route name for display on ID card".

2. **Data Source Mode:** He selects Manual Mode because the bus route information will be supplied by the module that generates the ID card, rather than fetched automatically from a database field.

3. **Status:** He leaves Active toggle ON.

4. He clicks "Save". The system validates the variable name format, checks it is unique within the ID Card category, saves the variable, and returns to the variable list showing the new entry.

Later, the school decides to make this variable automatic. Mr. Sharma edits the variable, changes the mode to Automated, selects Database Area = "Transport", Table = "student_route_mapping", Column = "route_name". The system saves the updated variable. Now the ID card engine fetches the bus route automatically.

---

## Related Screens

- **Template Category Master** — Where template categories are managed
- **Template Designer** — Uses template variables as placeholders when building document layouts
- **Document Generation** — The engine that replaces variables with actual values when generating documents

---

## How Other Parts of the System Depend on This Screen

| Area | What It Needs From Template Variable Registry |
|------|----------------------------------------------|
| **Variable records** | All template variables are stored and managed here |
| **Template categories** | Category options come from the Template Category Master; database schema information comes from the system's data dictionary |
| **Template designer** | The variable picker in the template designer shows only active variables belonging to the selected category |
| **Document generation engine** | Automated variables are resolved by fetching values from the specified data source; manual variables are supplied by the calling module |
| **Change history** | All changes to variables are recorded with timestamps |
