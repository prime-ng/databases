# Categories and Criteria — Business Requirements

## What This Screen Does

The Categories and Criteria screen allows school administrators to build the behavioral curriculum. Behaviour is evaluated based on concrete, structured criteria rather than abstract judgment. 

A **Category** represents a broad domain of personal development or conduct (e.g., "Social Skills," "Responsibility," "Health & Hygiene"). 

Under each Category, the school defines specific, measurable **Criteria** (e.g., under "Social Skills", the criteria might be "Collaborates effectively in groups" and "Respects diverse opinions"). During the assessment phase, teachers assign grades directly against these criteria.

---

## When This Screen Is Used

- **Configuring Assessment Framework**: Admin wants to define new areas of behavior to be assessed for students.
- **Adding Criteria**: A teacher requests an additional criterion under the "Ethics" category to track "Demonstrates honesty in academic tasks."
- **Deactivating Criteria**: The school decides to stop grading a specific criterion and flags it as Inactive.
- **Setting up Grade Weightages**: Customizing how criteria contribute to the overall category score.

---

## Key Fields at a Glance

### Behavioural Category (Header)
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Category Name** | String | Text Input | Yes | Must be unique. Max 100 characters. e.g., "Personal Integrity" |
| **Category Code** | Alphanumeric | Text Input | Yes | Capitalized, unique code. Max 15 chars. e.g., "PERS_INTEG" |
| **Description** | String | Text Area | No | Explain what this behavioral category covers. |
| **Status** | Boolean | Toggle | Yes | Defaults to Active. |

### Behavioral Criteria (Details / Sub-Grid)
Each Category contains a nested grid to add one or more child criteria.
| Field Name | Data Type | UI Element | Mandatory | Validation / Rules |
|------------|-----------|------------|-----------|--------------------|
| **Criteria Name** | String | Text Input | Yes | Unique within the category. Max 150 chars. e.g., "Completes assignments on time" |
| **Criteria Code** | Alphanumeric | Text Input | Yes | Unique code. e.g., "HW_PUNCT" |
| **Max Score** | Decimal | Number Input | Yes | Defaults to 5.0. Configures the maximum numeric rating point. |
| **Weightage (%)** | Integer | Number Input | Yes | Sum of all active criteria weightages under one category must equal 100%. |
| **Status** | Boolean | Toggle | Yes | Active/Inactive. |

---

## Business Rules and Conditions

**Parent-Child Integrity**
- An active Category must have at least one active Criterion linked to it.
- If a Category is deactivated, all of its nested Criteria are automatically marked Inactive in grading screens, though their individual statuses in this master grid remain unchanged.

**Weightage Validation**
- If the school configures weighted grading, the system will enforce that the sum of the `Weightage (%)` of all active Criteria under a single Category is exactly `100` before allowing the record to save.

**Category Deactivation & Soft Deletes**
- A Category or Criterion cannot be deleted if there are any recorded marks in `ba_assessment_ratings` linked to them. Instead, the admin must switch the Status toggle to Inactive.
- Inactive Categories/Criteria are hidden from the [Class Mapping](./05-Class-Mapping.md) form and the [Ratings Grid](./09-Ratings.md).

---

## Workflow Steps

**Adding a Category and Criteria**
1. Admin navigates to **Masters -> Categories** and clicks **Add Category**.
2. Fills in the Category Name (e.g., "Digital Citizenship") and Category Code (e.g., "DIG_CIT").
3. In the nested table, clicks **Add Criterion**.
4. Enters Criteria Name: `Uses technology responsibly`, Code: `TECH_RESP`, Max Score: `5`, and Weightage: `50`.
5. Clicks **Add Criterion** again, enters Criteria Name: `Respects digital privacy`, Code: `TECH_PRIV`, Max Score: `5`, and Weightage: `50`.
6. Admin clicks **Save**. The system validates the 100% total weightage and writes the records to `ba_categories` and `ba_criteria`.

**Modifying Weightage**
1. Admin clicks on an existing category (e.g., "Social Skills").
2. Modifies the weightages of the 4 active criteria from `25% each` to `30%, 30%, 20%, 20%`.
3. System verifies the sum is 100% and updates the records.

---

## Example Scenario

An elite secondary school wants to assess "Emotional Intelligence." The admin adds a new Category:
- **Category Name**: Emotional Quotient
- **Category Code**: EQ_MASTER
- **Criteria Grid**:
  1. *Self-Regulation* (Code: EQ_SELF, Weight: 40%, Max Score: 5)
  2. *Empathy & Peer Support* (Code: EQ_EMP, Weight: 60%, Max Score: 5)

This structure is instantly available for teacher evaluations once class mappings are set.

---

## Related Screens

- [02-Rating-Scales.md](./02-Rating-Scales.md) — Scoring scales used to grade these criteria.
- [05-Class-Mapping.md](./05-Class-Mapping.md) — Linking these categories to specific grades.
- [09-Ratings.md](./09-Ratings.md) — Scoring interface showing active criteria.
