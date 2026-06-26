# Rating Scales — Business Requirements

## What This Screen Does

The Rating Scales screen is the foundation for all behavioral grading in the module. It allows school administrators to configure the grading frameworks used to assess student behavior. Rather than teachers typing random grades, the system enforces selecting levels defined inside an active Rating Scale.

For example, a school might use an academic-grade style scale (A, B, C, D, E) or a descriptive-level style scale (Outstanding, Proficient, Developing, Emerging). Each level within a scale is linked to a numeric score value (e.g., A = 5, E = 1) to enable the system to calculate averages and aggregates behind the scenes.

---

## When This Screen Is Used

- **Academic Year Commencement**: Admin configures the master behavioral rating scale to be used across all classes for the new session.
- **Modifying Grading Rubrics**: Admin wants to adjust the wordings of levels (e.g., renaming "Unsatisfactory" to "Needs Support" to sound more encouraging).
- **Adding Custom Scales**: The school decides to apply a simpler 3-point scale for nursery/kindergarten students and a more detailed 5-point scale for high schoolers.
- **Deactivating a Scale**: A retired grading scale is turned off so teachers can no longer select it for new setups.

---

## Key Fields at a Glance

### Rating Scale (Header)
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Scale Name** | String | Text Input | Yes | Must be unique. Max 100 characters. e.g., "5-Point Descriptive Scale" |
| **Scale Code** | Alphanumeric | Text Input | Yes | Unique, capitalized, short code. Max 10 chars. e.g., "STD_5_PT" |
| **Status** | Boolean | Toggle / Switch | Yes | Defaults to Active. |

### Rating Levels (Details / Grid Rows)
Multiple levels can be added under a single header.
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Level Name** | String | Text Input | Yes | e.g., "Always", "Consistently", "Frequently", "Seldom", "Never" |
| **Numeric Score** | Integer / Float | Number Input | Yes | Unique within the scale. Used for computing averages. e.g., 5.0, 4.0, 3.0 |
| **Description** | String | Text Area | No | Tooltip context for teachers during grading. Max 250 chars. |

---

## Business Rules and Conditions

**Unique Numeric Scores & Names**
- No two levels inside the same Rating Scale can have the exact same level name or numeric score.

**Minimum & Maximum Levels**
- A Rating Scale must contain at least two levels (e.g., Yes/No) and can support a maximum of ten levels.

**Active Status Constraints**
- A Rating Scale can be deactivated only if it is NOT currently linked in the global [Configuration](./07-Configuration.md) or utilized in active [Assessment Periods](./06-Periods.md).
- Deactivating a scale does not delete historical records. Inactive scales are retained in database queries for past academic terms.

**Soft Delete Protection**
- Deleting a scale is blocked if any `ba_assessment_ratings` reference it. Admin can only toggle the status to Inactive.

---

## Workflow Steps

**Creating a New Rating Scale**
1. Admin navigates to **Masters -> Rating Scales** and clicks **Create New**.
2. Fills in the Scale Name and Scale Code.
3. Clicks **Add Row** under the Levels grid to define the levels.
4. Input details: Level Name: `Exemplary`, Numeric Score: `5`, Description: `Exceeds expectations in behaviour`.
5. Clicks **Add Row** again to add more levels.
6. The system verifies that numeric scores are in descending or ascending sequence (best practice) and that all required fields are filled.
7. Admin clicks **Save**. The records are successfully inserted into `ba_rating_scales` and `ba_rating_levels`.

**Deactivating a Scale**
1. Admin views the list of scales on the Rating Scales index.
2. Toggles the active status switch of an unused scale to "Inactive".
3. System checks for current usage. Since no active terms are linked, the state updates in the DB, and a success toast appears.

---

## Example Scenario

The primary school coordinator wants to establish a simple 3-point behavior scale. The admin creates the scale:
- **Scale Name**: Primary Behaviour Scale
- **Scale Code**: PRI_BEH_3
- **Levels**:
  1. *Consistently* (Numeric Score: 3, Description: "Shows the behavior at almost all times")
  2. *Sometimes* (Numeric Score: 2, Description: "Shows the behavior occasionally")
  3. *Rarely* (Numeric Score: 1, Description: "Struggles to show the behavior")

This scale is then selected in global [Configuration](./07-Configuration.md) for Class 1 to Class 5.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Scoring categories that criteria will be evaluated against.
- [07-Configuration.md](./07-Configuration.md) — Linking classes/years to specific rating scales.
- [09-Ratings.md](./09-Ratings.md) — Core grid where teachers select these level options.
