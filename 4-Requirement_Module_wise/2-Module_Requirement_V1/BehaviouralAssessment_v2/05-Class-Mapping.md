# Class Mapping — Business Requirements

## What This Screen Does

The Class Mapping screen bridges the behavioral curriculum to specific grade levels. Not all student age groups should be evaluated on the same behavioral expectations. For instance, kindergarteners should be assessed on fundamental physical habits (e.g., "Maintains cleanliness," "Shares toys"), whereas senior high schoolers should be evaluated on mature cognitive and social standards (e.g., "Leadership initiative," "Digital Citizenship," "Critical Thinking").

Class Mapping allows administrators to select a Class (e.g., "Grade 1") and map specific **Behavioural Categories** to it. This dynamic link ensures that teachers grading a specific section only see the categories and criteria appropriate for that student age group.

---

## When This Screen Is Used

- **Academic Session Setup**: Admin links the behavioral categories to each class level at the beginning of the year.
- **Introducing a New Subject Area**: The school adds a "Community Service" category and maps it only to Grade 9 through Grade 12.
- **Excluding Non-Applicable Categories**: Admin removes the "Fine Motor Skills" behavioral category from Middle School classes as they transition to higher grades.

---

## Key Fields at a Glance

| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **School Class** | Integer (ID) | Dropdown / Select | Yes | References `sch_classes`. e.g., "Grade 6". |
| **Academic Session**| Integer (ID)| Dropdown / Read-only | Yes | References `org_academic_sessions`. Set to the active session. |
| **Select Categories**| Array (IDs) | Checkbox Grid / Multi-Select | Yes | Lists active categories from `ba_categories`. At least 1 must be selected. |

---

## Business Rules and Conditions

**No Blank Evaluations**
- Every class active in the current academic session must have at least one mapped category. The system will throw an validation error if an admin tries to save a class mapping with zero checked categories.

**Preservation of Existing Grades**
- If an admin unmaps a category from a class midway through an academic session, the system will perform an integrity check on `ba_assessment_ratings` for that class.
- If grades have already been entered for the category being unmapped, the action is **blocked**, and the admin is prompted: `"Cannot remove Category 'Social Skills' because teachers have already recorded ratings for this class."`

**Dynamic Form Rendering**
- The [Ratings Grid](./09-Ratings.md) automatically queries `ba_class_category_jnt` based on the selected student's class to determine which criteria to render. If no mapping is found, the grading form is disabled.

---

## Workflow Steps

**Mapping Categories to a Class**
1. Admin navigates to **Setup -> Class Mapping**.
2. Selects School Class: `Grade 9` from the dropdown list.
3. The checkbox grid shows all active behavioral categories.
4. Admin checks the boxes for:
   - `Emotional Intelligence`
   - `Personal Hygiene`
   - `Digital Citizenship`
   - `Leadership Skills`
5. Leaves `Motor Skills` unchecked.
6. Admin clicks **Save**. The system inserts the mappings into the joint table `ba_class_category_jnt`.

**Overriding Mappings**
1. Admin opens `Grade 9` mapping.
2. Unchecks `Personal Hygiene` (determining that high schoolers no longer need this tracked).
3. The system checks `ba_assessment_ratings`. Since it is a new academic year and no grades have been inputted, the system permits the update.
4. Clicks **Save**. The obsolete joint rows are deleted, and new mappings persist.

---

## Example Scenario

A school has a separate Preschool wing and High School wing. The admin configures Class Mappings:
- **Class**: `LKG (Lower Kindergarten)`
  - *Mapped Categories*: Basic Hygiene, Motor Skills, Sharing & Cooperation.
- **Class**: `Grade 10`
  - *Mapped Categories*: Leadership & Initiative, Analytical Mindset, digital Ethics, Peer Collaboration.

When the Grade 10 homeroom teacher opens the grading portal, they are only presented with advanced rubrics, while the kindergarten teacher receives developmental rubrics.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Master categories that are selected in this mapping form.
- [07-Configuration.md](./07-Configuration.md) — Setting up global modules parameters.
- [09-Ratings.md](./09-Ratings.md) — Grade grid that dynamically adjusts based on these mappings.
