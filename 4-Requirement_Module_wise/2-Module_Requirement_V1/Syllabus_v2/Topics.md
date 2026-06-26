# Topics Master — Business Requirements

## What This Screen Does

The Topics screen is the most critical and complex interface in the Syllabus module. It breaks down broad Lessons into highly granular, teachable, and assessable units. 

It utilizes an advanced hierarchical structure to allow infinite nesting, such as Topic leading to Sub-topic leading to Micro-topic. It acts as the central hub connecting the teaching content to time duration, prerequisite dependencies, and unique analytics tracking codes. Everything from generating question papers to tracking daily teacher progress relies on the accuracy of this screen.

---

## When This Screen Is Used

- Syllabus Breakdown when a Head of Department takes a large Lesson and breaks it down into specific daily topics
- Prerequisite Enforcement when establishing dependencies to prevent a student from accessing advanced topics before mastering basic ones
- Automation Setup when configuring rules to automatically release quizzes or unlock study materials as soon as a teacher marks a topic as completed

---

## Key Fields at a Glance

**Hierarchical Structure**
The Parent Topic links the topic to an immediate parent, while leaving it empty makes it a root topic. The Topic Level defines whether it is a Topic, Sub-Topic, or Micro-Topic. A human-readable Breadcrumb Path is displayed to provide a fast navigation trail for reporting purposes.

**Identity and Tracking**
An automatically generated Analytics Tracking Code is built by combining parent codes, providing deep context tracking for reporting tools. A User Code is an editable reference code that the school can use for their internal tracking. The full Display Name and a condensed Short Name are captured, along with a Sequence Order which determines the exact order in which topics appear in the curriculum tree.

**Teaching and Assessment Details**
The Duration captures the exact time estimated to teach this specific topic in minutes. The Weightage represents how important this topic is relative to the whole lesson, expressed as a percentage, which is used to auto-calculate progress bars. Baseline mapping allows a prerequisite topic to be linked from a previous academic year, while Current Year Prerequisites is a list of other topics in the current year that must be completed before this topic unlocks.

**Automation Triggers**
The Assessable toggle determines if questions can be linked to this topic in the Question Bank. The Track for Syllabus Status toggle determines if this topic should be counted when calculating the overall Syllabus Completed percentage on the dashboard. The Auto-Release Quiz toggle dictates if the system should automatically push linked quizzes to students as soon as the teacher marks this topic complete.

---

## Business Rules and Conditions

**Auto-Generation of Tracking Paths**
When a new topic is saved, the system must automatically figure out its ancestry and append its code to the parent's code. If a parent topic is moved using drag-and-drop, the system must instantly update the tracking codes for that topic and all of its nested children to ensure analytics are never broken.

**Sequence and Uniqueness Constraints**
The system enforces that no two topics can have the same sequence order under the same parent to maintain a strict chronological curriculum.

**Logical Nesting Validation**
The interface must prevent illogical nesting. For example, a Sub-Topic cannot be the parent of a Root Topic. The hierarchical level of a child must always be deeper than its parent.

**Circular Dependency Prevention**
When saving prerequisites, the system must perform a logic check. Topic A cannot require Topic B if Topic B already requires Topic A. Furthermore, a topic cannot be set as a prerequisite for itself.

---

## Workflow Steps

**Creating a Hierarchical Topic**
The teacher selects the Lesson and clicks Add Topic. The system defaults to the Root Topic level. The teacher names it "Velocity" and sets the duration. Upon saving, the system automatically generates the analytics tracking code. The teacher then clicks to add a child under "Velocity". The system locks the parent to "Velocity" and forces the level to "Sub-Topic". The teacher names it "Average Velocity", assigns a weightage, enables the auto-release quiz option, and saves it. The system creates a deeper tracking code reflecting the parent-child relationship.

---

## Example Scenario

A school enforces a strict Mastery-Based Learning policy. The Biology HOD structures the syllabus by creating Topic A: "Cell Structure" and Topic B: "Cell Division". The HOD edits Topic B and adds Topic A into the prerequisites list. 

When the academic year begins, students can view the study materials for Topic A. However, Topic B is completely locked and greyed out. Even if the scheduled date for Topic B arrives, the system validates the prerequisites. It sees that the student hasn't passed the Topic A assessment yet. Topic B remains locked, forcing the student to master Cell Structure before moving to Cell Division.

---

## Related Screens

- **Topic Types** — Controls the depth and rules for nesting
- **Topic-Competency Mapping** — Links these specific topics to broad educational outcomes
- **Lesson Date Planning** — Where these topics are assigned target completion dates
