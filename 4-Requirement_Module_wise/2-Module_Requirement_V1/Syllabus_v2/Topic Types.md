# Topic Types Master — Business Requirements

## What This Screen Does

The Topic Types screen is a foundational configuration interface that controls the architectural depth of the entire syllabus. 

Instead of hardcoding fixed terms like "Topic" and "Sub-topic", this screen allows the school to define a scalable, multi-tiered hierarchy. It answers the question of how deep a teacher can break down a chapter. Furthermore, it acts as the primary gatekeeper for assessments, defining exactly which levels of the hierarchy are allowed to be tested in exams or given as homework.

---

## When This Screen Is Used

- System Deployment by the software provider or super-admin during the initial rollout to the school
- Assessment Policy Definition when the Examination Board decides that quizzes cannot be generated for extremely small topics
- Analytics Configuration when configuring how the automated tracking codes should be structured for deep reporting

---

## Key Fields at a Glance

**Identity and Depth Indicators**
A numeric depth level represents the mathematical depth of the hierarchy, such as 0 for Root Topic, 1 for Sub-topic, or 2 for Micro Topic. The system strictly relies on these numbers to render the visual tree, ensuring parents always have a lower number than children. The human-readable name is displayed in dropdowns, like "Sub-Topic" or "Nano Topic", alongside a standardized short code which is used by the system to dynamically generate tracking codes for analytics.

**Gatekeeper Settings**
These configuration toggles govern exactly how the rest of the system interacts with this specific depth level. The Homework Release toggle allows teachers to assign homework specifically bound to this level. The Quiz Release toggle allows generating automated short quizzes based on this level. The Question Bank Tagging toggle allows individual questions in the Question Bank to be tagged down to this granular level. The Exam Release toggle allows a formal Summative Exam to be built around this level.

---

## Business Rules and Conditions

**Strict Uniqueness Rules**
The system enforces absolute uniqueness across its core identity fields to prevent structural collapse. No two types can share the same depth number, short code, or name.

**Global Configuration Control**
Because changing these levels fundamentally alters how tracking codes are constructed, this screen is typically locked for regular school administrators. It is maintained at the master tenant level. Allowing schools to randomly insert a new depth level mid-year would break global analytics reporting and cross-school benchmarking.

**Restrictive Deletion**
A Topic Type cannot be deleted if even a single Topic in the database is currently using it, preventing broken references in the curriculum tree.

---

## Workflow Steps

**Adding a New Depth Level**
The Super Admin logs into the Global Master configuration and navigates to Topic Types. If a school requests the ability to track extremely granular details beyond a Micro Topic, the Admin clicks Add New Level. They set the Depth Level to the next available number, enter the Name as "Nano Topic", and the Short Code as "NAN". They enable Homework and Quiz release but disable Exam Release because a Nano Topic is too small to warrant a major final exam. Upon saving, "Nano Topic" instantly becomes available as an option across the entire school.

---

## Example Scenario

The Examination Department is setting up the Mid-Term Exam Blueprint using the Exam Generator. The Exam Head tries to select specific syllabus areas to test. 

They navigate to the "Cell Division" chapter and try to select a deeply nested item called "Spindle Fiber Formation" to build the exam around. However, the system checks the setup and sees that "Spindle Fiber Formation" is categorized as a "Micro Topic". 

The Exam Engine then checks the rules for Micro Topics defined in this screen. It sees that Exam Release is disabled for this level. The system instantly displays a validation error advising the user that they cannot center a formal Exam around a Micro Topic and must select a higher-level Topic. This ensures educational standards are maintained.

---

## Related Screens

- **Topics** — Heavily relies on this table to define parent-child logic and generate analytics codes
- **Exam Blueprinting** — Uses the gatekeeper settings to permit or block assessment generation
