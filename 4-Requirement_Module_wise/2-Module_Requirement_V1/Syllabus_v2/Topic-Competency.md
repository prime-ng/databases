# Topic-Competency Mapping — Business Requirements

## What This Screen Does

The Topic-Competency Mapping screen is the critical junction where the school's Content intersects with its Goals. 

It allows Subject Matter Experts to declare exactly which skills a specific topic is intended to develop in the student. By creating this link, the system can automatically generate outcome-based reports, showing that when a student completes a specific topic, they have inherently progressed towards achieving a specific competency. This shifts the educational focus from simply finishing the syllabus to acquiring the mandated skills.

---

## When This Screen Is Used

- Post-Setup Alignment after Topics and Competencies have been independently defined, teachers or HODs use this screen to map them together
- Compliance Auditing when preparing a justification report for external boards, proving how textbook chapters map to mandated National Curriculum outcomes
- Assessment Blueprinting when the Exam Module needs to know which questions to pull from the bank to test a specific competency

---

## Key Fields at a Glance

**Relational Linking**
A Topic Selection field identifies the specific teaching unit being mapped, such as "Balancing Chemical Equations". A Competency Selection field identifies the target skill being developed, such as "Analytical Thinking".

**Weightage and Importance**
A Percentage Weightage field captures a numeric value representing how much this specific topic contributes to the mastery of the overall competency. If a topic is heavily focused on a skill, it might carry an 80% weightage. A Primary Focus Toggle acts as a switch indicating importance. A topic can be mapped to many different competencies, but the system forces the user to designate exactly one as the primary focus of the lesson.

---

## Business Rules and Conditions

**Many-to-Many Architecture**
The architecture supports complex, multi-directional mapping. A single science experiment topic can map to Scientific Knowledge, Lab Safety, and Using Instruments simultaneously. Conversely, a single competency like Critical Thinking might be mapped to 50 different topics across the academic year.

**Primary Competency Validation**
While a user can attach multiple competencies to a single topic, the system must enforce a strict rule where only one mapping per topic can be marked as the Primary focus. If the user attempts to set a second competency as primary, the system must either throw an error or automatically downgrade the previous primary competency to secondary.

**Unique Mapping Constraint**
The system ensures that a user cannot map the exact same skill to the exact same topic twice.

**Deletion Rules**
If either the Topic or the Competency is permanently deleted from their respective master screens, this mapping link is automatically destroyed by the system to prevent broken references in reports.

---

## Workflow Steps

**Mapping a Topic to Competencies**
The Science Teacher navigates to the Competency Mapping tab within the Syllabus Master. They select their Lesson and drill down to the Topic "Refraction of Light through a Prism". A selection window opens, displaying all available Competencies. The teacher selects three competencies: Understanding Concepts, Diagrammatic Representation, and Applying Laws of Physics. They set Understanding Concepts as the Primary Competency. They assign weightages: 50% for Understanding, 30% for Diagrammatic, and 20% for Applying. Upon hitting Save, the system validates the unique rules and the single-primary rule, then saves the mapping.

---

## Example Scenario

At the end of the first term, the Principal generates the Coverage Audit Report for Class 10. The school board requires that 15% of the entire term's teaching must focus on Environmental Awareness, a mandated competency.

The system checks the mapping table. It finds that out of 200 topics taught so far, 35 topics across Science, English, and Social Studies were mapped to the Environmental Awareness competency. By calculating the weightage of those topics against the weightage assigned in the mapping table, the system proves to the board that 18% of the curriculum successfully addressed this competency, passing the audit seamlessly.

---

## Related Screens

- **Topics Master** — The source of the content being mapped
- **Competencies Master** — The source of the skills being targeted
- **Coverage Audit Report** — The analytics engine that consumes this mapping data to generate radar charts and compliance PDFs
