# Student Remarks — Business Requirements

## What This Screen Does

The Student Remarks screen allows teachers to enter qualitative narratives to accompany numerical scores. While numbers and averages show general performance trends, qualitative statements offer essential nuance, giving parents specific context on their child's classroom conduct, emotional growth, and areas requiring corrective guidance.

The screen provides a list of all students in the cohort, with a large, descriptive text box next to each name. To assist teachers in writing professional and constructive comments quickly, the UI includes a **Comment Bank / Predefined Templates** panel that allows them to insert standard phrases with a single click.

---

## When This Screen Is Used

- **Finalizing Assessment Cycles**: After completing the [Ratings Grid](./09-Ratings.md), teachers write behavioral summaries for each student before submitting the term data.
- **Mid-term Progress Notes**: Class teachers input developmental recommendations for students struggling with behavior.
- **Reporting Updates**: Modifying and correcting written remarks based on coordinator feedback.

---

## Key Fields & UI Layout

### Header Information
- Displays Class, Section, and active Assessment Period.

### Remarks Entry Table
- **Student Profile**: Student Photo, Roll Number, and Name.
- **Numeric Summary**: A read-only badge showing the student's computed average score from the [Ratings Grid](./09-Ratings.md) (e.g., `4.5 / 5.0`). This helps the teacher write remarks that match the numerical scoring.
- **Remarks Text Area**: Standard text entry field.
  - *Character Counter*: Visual indicator showing current count (e.g., `120 / 500 characters`). Enforces a minimum of 30 characters.
- **Comment Bank Helper Button**: A wizard button next to each text area that pops open a side panel containing standardized, categorised comments (e.g., Categories: *Collaboration Positive*, *Discipline Corrective*, *Leadership Praise*).

---

## Business Rules and Conditions

**Minimum Word Count & Validation**
- To prevent teachers from writing generic or single-word comments (e.g., "Good," "Nice"), the system enforces a **minimum length of 30 characters** and a **maximum of 500 characters**.
- The "Submit" button on [My Assessments](./08-My-Assessments.md) remains locked until every student has an approved, non-empty remark that passes the validation threshold.

**Autosave Mechanics**
- Similar to ratings, the text boxes feature a debounced autosave. When the teacher stops typing for more than `1.5 seconds`, or shifts focus away from the text area (`blur` event), the remarks are written to `ba_student_remarks` in the background.

**Safety Filters**
- The system includes a basic profanity/inappropriate language filter. If a teacher enters restricted terms, the input outlines in red, and the system prompts them to rephrase before saving.

---

## Workflow Steps

**Writing a Narrative Comment**
1. Teacher clicks **Proceed to Remarks** after completing the [Ratings Grid](./09-Ratings.md).
2. The list of students loads. MRS. Priya starts with student **John Doe** (rolling average is `2.3` - representing some behavior struggles).
3. Mrs. Priya clicks the **Comment Bank** helper icon.
4. Selects category: `Needs Support -> Focus & Distraction`.
5. Selects template: `"{Student} frequently struggles to maintain focus during independent tasks but responds well to quiet redirections."`
6. The system inserts the template, replacing `{Student}` with `John`.
7. Mrs. Priya appends custom details: `"He showed slight improvement in the final week of November."`
8. The character counter reads `135 / 500`. 
9. She clicks `Tab` to go to the next row. The system autosaves John's narrative.

---

## Example Scenario

Mrs. Priya is writing a remark for Amit Sharma (Average `4.9`):
- Entered text: `"Amit is a natural leader who constantly helps his peers during lab activities. His positive attitude is an asset to Class 8-A."`
- Character count: 125 characters. Validation: Passed.
- Database records the text under `remarks` in the `ba_student_remarks` table.

---

## Related Screens

- [08-My-Assessments.md](./08-My-Assessments.md) — The parent submission dashboard.
- [09-Ratings.md](./09-Ratings.md) — Grid displaying the numeric scores Mrs. Priya references.
- [20-Student-Report.md](./20-Student-Report.md) — The standalone report card where these paragraphs are printed.
