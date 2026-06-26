# Cognitive Skills — Business Requirements

## What This Screen Does

The Cognitive Skills screen acts as the detailed, actionable translation of Bloom's Taxonomy. 

While Bloom's Taxonomy provides broad buckets like Analyzing, teachers cannot effectively tag a question with such a generic label. This screen breaks down those broad buckets into highly specific, granular verbs and skills, such as Differentiating, Organizing, or Attributing. This gives teachers a precise, standardized vocabulary to use when defining the exact educational intent of a lesson or an assessment question.

---

## When This Screen Is Used

- Curriculum Framework Setup when an Academic Coordinator defines the detailed tagging vocabulary for teachers to use across the platform
- Question Bank Population when teachers are adding new questions to the database and must tag what specific mental process the question demands from the student
- NEP Alignment when mapping the school's internal assessment strategy to the skill-based, competency-driven focus of National Education Policies

---

## Key Fields at a Glance

**Parent Linkage**
A Target Bloom Level links the specific skill directly to one of the 6 fundamental cognitive levels in the Bloom Taxonomy screen. This firmly anchors the granular skill to a broad pedagogical category.

**Identity and Definition**
A Unique Code acts as a standardized identifier, such as COG-DIFFERENTIATE, which is crucial for data imports and ensuring consistency across different subjects. The Display Name captures the name of the skill shown in dropdowns, like 'Differentiating' or 'Recalling'. A Detailed Description provides a pedagogical explanation of the skill, such as distinguishing relevant from irrelevant parts of presented material.

**State Management**
A Status Toggle acts as an active or inactive switch. If marked as inactive, the skill is hidden from the Question Bank dropdowns, preventing teachers from using deprecated tagging standards without deleting historical data.

---

## Business Rules and Conditions

**Strict Parent-Child Enforcements**
A Cognitive Skill cannot exist in a vacuum. It must be linked to a valid Bloom Taxonomy level. If the parent Bloom level is somehow removed or disabled, the system should flag this cognitive skill as orphaned and prevent it from being used in active exam blueprints until it is re-assigned to a valid level.

**Analytics Roll-up Dependency**
This screen is the backbone of the Cognitive Analytics engine. When the system generates a report, it counts the occurrences of Cognitive Skill tags attached to questions or topics, and then aggregates them upwards using the Target Bloom Level to generate the final Radar and Pyramid charts.

**Uniqueness and Standardization**
The system ensures that duplicate skills cannot be created. This prevents the vocabulary from becoming diluted, which would otherwise confuse teachers during tagging and ruin the accuracy of the analytics.

---

## Workflow Steps

**Adding a New Cognitive Skill**
The Academic Head opens the Cognitive Skills screen and clicks Add New Skill. They enter the Name as "Critiquing". They select the Parent Bloom Level from the dropdown as "Evaluating". They enter the Description to explain detecting inconsistencies or fallacies within a process or product and making judgments based on criteria. They save the record. The system validates the uniqueness of the entry and saves the data. Instantly, the "Critiquing" skill becomes available in the Question Bank tagging interface for all teachers to use.

---

## Example Scenario

An English teacher is creating a complex subjective question asking students to read a provided editorial and identify the author's logical fallacies.

When adding this to the Question Bank, the teacher is prompted to tag its cognitive depth. They don't just tag it as the broad "Evaluating" level. Instead, they open the specific dropdown populated by this screen and select the exact Cognitive Skill, which is "Critiquing".

Months later, when the HOD generates an assessment audit, the system groups all questions tagged with "Critiquing" and automatically rolls them up into the "Evaluating" Bloom Level, providing the Principal with a precise, organized breakdown of higher-order thinking assessments.

---

## Related Screens

- **Bloom Taxonomy** — The parent master configuration screen
- **Question Type Specificity** — Links these precise mental skills to specific mechanical question formats
