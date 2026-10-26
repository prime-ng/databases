# Subject + Study Format Create Page Architecture & Complete Workflow Guide

**Route:** `route('school-setup.subject-study-format')`  
**Blade View:** `Modules/SchoolSetup/resources/views/school-class/partials/subject-study-format/create.blade.php`  
**Frontend Engine:** **Vue 3 Global Build** (`public/backend/js/subject-study-format.js`)  
**Backend Controllers:** `SubjectStudyFormatController.php`  
**Database Tables Involved:**
1. `sch_subject_study_format_jnt` (Junction table linking Subject, Study Format, Subject Type)
2. `sch_subject_study_format_options` (Grouping child options for practicals/sports/electives)
3. `sch_subjects` (Parent subject)
4. `sch_study_formats` (Parent study format)
5. `sch_subject_types` (Subject classification)
6. `sch_rooms_type` & `sch_rooms` (Room requirements)

---

## 1. 3-Panel Interactive Layout Architecture

The page is designed as a **3-Column Master-Detail Matrix Application**:

```
+----------------------------------------------------------------------------------------------------+
|                                BREADCRUMB: Subject Study Format Management                         |
+--------------------------+------------------------------+------------------------------------------+
| PANEL 1: SUBJECTS LIST   | PANEL 2: STUDY FORMATS LIST  | PANEL 3: SUBJECT TYPE MAPPING MATRIX     |
| [Search subjects...    ] | [Search study formats...   ] | Title: [Subject Name] - [Format Name]    |
|                          |                              | [Save Study Formats Button (Top Right)]  |
| 1. Mathematics     [->]  | 1. Theory Lecture   (3) [->] |                                          |
| 2. Physics (Active)[->]  | 2. Practical (Active)(2) [->]| Table Columns:                           |
| 3. Chemistry       [->]  | 3. Tutorial         (0) [->] | - Subject Type Checkbox (*)              |
| 4. Computer Sc.    [->]  | 4. Laboratory       (1) [->] | - Room Type Dropdown (*)                 |
|                          |                              | - Room Dropdown (Optional)               |
| Pagination: < 1 of 3 >   | Pagination: < 1 of 1 >       | - Class House Room Checkbox              |
|                          |                              | - Compulsory Specific Room Checkbox      |
|                          |                              | - Status Toggle (Active/Inactive)        |
|                          |                              | - Has Options (Opens Modal if checked)   |
+--------------------------+------------------------------+------------------------------------------+
```

---

## 2. Step-by-Step Functional Workflow

### Step 1: Select a Subject (Left Panel)
1. On page load, Panel 1 fetches and displays all active subjects with search & pagination.
2. User clicks the arrow button `[->]` on any Subject (e.g. **Physics**).
3. Physics gets highlighted (`.ssf-active-row`).
4. **Triggered AJAX Action:** Calls `POST school-setup.subject-study-format` passing `{ subject_id: <id> }`.
5. This preloads the entire subject state and updates count badges next to each Study Format in Panel 2.

### Step 2: Select a Study Format (Center Panel)
1. User clicks the arrow button `[->]` on a Study Format (e.g. **Practical**).
2. The format row is highlighted.
3. Panel 3 (Right Panel) immediately unlocks and loads the **Subject Type Mapping Matrix**.

### Step 3: Configure Mapping Matrix (Right Panel)
Each Subject Type (e.g. *Major, Minor, Skill, Elective*) has a row:
1. **Subject Type Checkbox:**
   - Unchecked: Row fields are disabled and cleared.
   - Checked: Enables Room Type, Room, and Timetable rule options.
2. **Room Type Dropdown (`required_room_type_id`):**
   - Mandatory when checked. Lists room types (e.g. *Physics Lab, Computer Lab, General Classroom*).
3. **Room Dropdown (`required_room_id`):**
   - Dynamically filtered to only show rooms belonging to the selected `room_type_id`.
4. **Cls. House Room Checkbox (`require_class_house_room`):**
   - Indicates whether standard section classroom can be used.
5. **Specific Room Checkbox (`compulsory_specific_room_type`):**
   - Enforces timetable constraint that only the specified room type can be scheduled.
6. **Status Toggle (`is_active`):**
   - Active (1) or Inactive (0).
7. **Has Multiple Options Toggle (`has_multiple_options`):**
   - When enabled (e.g., Games format having Football, Cricket, Basketball options):
     - Clears parent row room selections (because options carry their own rooms).
     - Opens the **Mapping Options Modal** to configure parallel option subjects!

### Step 4: Save Configuration
1. User clicks **`Save Study Formats`** button in the matrix card header.
2. **AJAX Request:** Calls `POST school-setup.save-subject-study-format`.
3. Validates triple uniqueness (`uq_ssfj_subjectId_stFormat`) in `sch_subject_study_format_jnt`.
4. Displays a success toast: *"Subject Study Format saved successfully"*.
5. Count badge in Panel 2 updates instantly to reflect the newly saved mappings.
