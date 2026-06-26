# Question Type Specificity — Business Requirements

## What This Screen Does

The Question Type Specificity screen acts as the ultimate bridge between the structural format of a question and its deep cognitive intent. 

It defines exactly what a question is asking the student to do in a practical sense, such as identifying the correct diagram, calculating the missing variable, or writing an essay. By explicitly linking these practical actions to a Cognitive Skill, the system closes the loop where the format dictates the action, the action dictates the skill, and the skill dictates the Bloom's Level.

---

## When This Screen Is Used

- System Setup when defining specific assessment rubrics for a new curriculum
- Formative vs Summative Design when defining that certain specific actions like quick recall are meant for Formative Homework, while actions like extensive calculation are meant for Summative Exams
- Detailed Analytics when a school wants to classify its Question Bank not just by Subject and Chapter, but by the exact functional requirement of the questions

---

## Key Fields at a Glance

**Parent Linkage**
A Target Cognitive Skill field links directly to a specific skill defined in the Cognitive Skills screen. This is the crucial link because by setting this, any question tagged with this specificity is instantly associated with the higher-level Cognitive Skill and, by extension, the Bloom's Taxonomy level.

**Identity and Definition**
A Unique Code acts as a standardized identifier, such as CALCULATE_VAR or LABEL_DIAG, which is used for data imports and system stability. A Display Name provides the human-readable name shown to teachers, like 'Calculate the missing variable' or 'Label the diagram'. A Detailed Description provides an explanation of what this specific action entails and when a teacher should select it.

**State Management**
A Status Toggle acts as an active or inactive switch to deprecate specific actions without deleting historical assessment data.

---

## Business Rules and Conditions

**Deep Cognitive Mapping Architecture**
By enforcing the chain from Specificity to Cognitive Skill to Bloom Taxonomy, the system creates a 3-tier deep cognitive engine. Every single time a teacher tags a question with a Specificity like "Label Diagram", the system automatically derives its Cognitive Skill as "Recalling" and its Bloom Level as "Remembering". The teacher only has to make one simple, practical choice, but the system gains 3 levels of analytical depth.

**Cascading Filtering**
To prevent interface clutter in the Question Bank, this screen acts as a secondary cascading filter. If a teacher first selects "Recall" as the Cognitive Skill, the Specificity dropdown will dynamically filter to only show options mapped to "Recall", such as showing "Identify definition" but hiding "Calculate formula".

**Uniqueness and Standardization**
The system ensures that duplicate specificity codes cannot be created. This prevents the vocabulary from becoming diluted and ensures data consistency across thousands of question bank entries.

---

## Workflow Steps

**Adding a New Question Specificity**
The Biology HOD navigates to Question Type Specificity to standardize how diagrams are tested. They click Add Specificity and enter the Name as "Label the Anatomical Parts". They select the Parent Cognitive Skill as "Recalling", which the system knows is linked to the Bloom level "Remembering". They enter the Description explaining that it requires the student to correctly identify and label parts of a provided diagram. They save the record to make it available for all teachers.

---

## Example Scenario

An external audit demands to know how often the school relies on Rote Memorization versus Application. 

The HOD doesn't need to manually read through thousands of test papers. Instead, they run an assessment report. The system looks at all the questions administered over the year. It sees 500 questions tagged with the Specificity of Identify Definition, 300 tagged with Label the Anatomical Parts, and 200 tagged with Calculate Velocity.

Because of the links defined in this screen, the system automatically rolls the first 800 questions up into the Remembering Bloom Level, and the 200 questions up into the Applying Bloom Level. The HOD instantly gets a perfect, data-backed pie chart showing exactly what functional actions the students were tested on.

---

## Related Screens

- **Cognitive Skills** — The parent master configuration screen
- **Question Types (Master)** — Works alongside the mechanical format of the question
