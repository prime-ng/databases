# Complexity Levels Master — Business Requirements

## What This Screen Does

The Complexity Levels screen acts as a vital calibration tool for the Assessment Engine. It provides a master reference configuration that categorizes the difficulty of any given topic or question, such as Easy, Medium, or Hard. 

This is the primary metric used to balance question papers, generate automated exam blueprints, and power adaptive testing algorithms.

---

## When This Screen Is Used

- System Setup configured during initial deployment to define the school's difficulty scale
- Question Creation whenever a teacher adds a question to the Question Bank, they are forced to assign a complexity level from this list
- Automated Exam Generation when an Exam Coordinator tells the system to generate a 100-mark paper with a specific ratio of Easy, Medium, and Hard questions

---

## Key Fields at a Glance

**Identity and Nomenclature**
A Unique Code acts as the standardized system identifier, such as EASY, MEDIUM, or DIFFICULT, ensuring consistency across data imports. A Display Name provides the human-readable name shown to teachers, like 'Easy', 'Hard', or 'High Order Thinking Skills'.

**Hierarchical Ranking and Mathematics**
A Complexity Rank captures a numeric value representing the mathematical weight or rank of the difficulty. This scales from 1 for Easy up to 4 for Expert. This is not just a label; it is a critical mathematical operator used by the system for sorting, filtering, and adaptive logic.

**State Management**
A Status Toggle acts as an active or inactive switch to enable or disable the level without destroying historical question data.

---

## Business Rules and Conditions

**Mathematical Hierarchy Integrity**
The numeric rank is critical. It allows the system to mathematically understand that a Rank 3 is definitively harder than a Rank 1. This enables Adaptive Testing logic where if a student answers a Rank 1 question correctly, the adaptive algorithm searches the database for questions with a rank higher than 1. If a student fails a Rank 2 question, the system searches for questions with a rank lower than 2 to serve as remedial practice.

**Strict Uniqueness Constraints**
The system ensures that no two complexity levels can share the same unique code. This ensures that automated question paper blueprints do not accidentally query duplicate or ambiguous difficulty pools.

**Immutability of Used Levels**
If a specific Complexity Level like Easy has already been tagged to thousands of questions in the Question Bank, the system must restrict the deletion of this level. It must only allow the Status Toggle to be set to inactive, ensuring that historical analytical reports do not crash due to missing references.

---

## Workflow Steps

**Adding an Advanced Complexity Level**
The Admin navigates to the Complexity Levels screen because the school decides to introduce extreme challenge questions for Olympiad preparation. The Admin clicks Add New Complexity Level. They enter the Name as "Expert / Olympiad Level" and the Code as "EXPERT". They set the Complexity Rank to 4, which is mathematically higher than the existing rank of 3 for Difficult. They save the record, and teachers instantly see this new level as an option when uploading massive calculation-based questions to the bank.

---

## Example Scenario

The Examination Department is creating a blueprint for the critical Class 10 Pre-Board Exams. Instead of manually picking 50 individual questions, the Exam Head sets a purely algorithmic blueprint rule in the Exam Generator. 

They instruct the system to select 10 questions where the Topic is Trigonometry and Complexity Level is Easy, 15 questions where the Complexity Level is Medium, and 5 questions where the Complexity Level is Difficult. The Exam Engine queries the Question Bank based precisely on the numeric ranks defined in this screen. It executes randomized selection and auto-generates a perfectly balanced exam paper in seconds, eliminating human bias.

---

## Related Screens

- **Question Bank Module** — Every single question must be tagged with a complexity level from this configuration
- **Syllabus Reports** — Analytics can cross-reference this to show if a student perfectly answers Easy questions but completely fails Medium or Difficult ones
