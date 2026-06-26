# Grade Divisions Master — Business Requirements

## What This Screen Does

The Grade Divisions Master screen is the definitive source of truth for generating official student Report Cards and Transcripts. 

While the Performance Categories screen drives internal remedial actions and dashboard alerts, the Grade Divisions screen strictly dictates how numerical percentages are translated into the official nomenclature required by the educational board. It converts a raw score into an official board-compliant label, such as "Grade A1" for CBSE, or "First Division" for a State Board.

---

## When This Screen Is Used

- Pre-Exam Configuration during the setup of the Examination Module before any term report cards are finalized and printed
- Multi-Board Operations when a school runs multiple curricula within the same campus and needs different grading scales for different groups of students
- Policy Changes when an educational board officially changes its grading criteria for a new academic year

---

## Key Fields at a Glance

**Identity and Nomenclature**
An Official Code captures the exact text printed on the report card, such as A1, DISTINCTION, or FAIL. A Display Name provides the expanded display name for reference, like 'Grade A1' or 'First Division with Honors'. A Grading Type classifies whether this specific rule is a Grade based system or a Division based system.

**Academic Band**
A Percentage Range captures the precise minimum and maximum percentage boundaries, such as 91.00% to 100.00%.

**Compliance and Dynamic Scoping**
A Board Selection links the grading rule to a specific educational board. An Academic Session links the rule to a specific year, allowing historical preservation so that if grading rules change in the future, past report cards remain unaffected. A Scope Rule determines how widely the rule applies, whether to the entire School, all students under a specific Board, or just students in a specific Class. A Target Class links the rule to that specific grade level if the scope is set to Class-level.

**Data Governance**
A Security Lock Toggle is a critical security feature. If enabled, the system absolutely forbids anyone from altering the minimum or maximum percentage boundaries.

---

## Business Rules and Conditions

**Overlap Prevention**
The system must ensure that percentage ranges do not overlap. Before saving, the system checks if the new range conflicts with any existing active rules that share the same scope, grading type, and class. 

**Resolution Hierarchy**
When the system evaluates a student's score to print their report card, it must search for the correct grade using a strict fallback hierarchy. First, it checks if a Class-specific rule exists for the student's exact class. If not found, it checks if a Board-specific rule exists for the student's registered board. If not found, it falls back to the global School-wide rule.

**Post-Publishing Lockdown**
Once the Examination Module executes the Publish Results action for an academic term, it must automatically trigger an update to this screen, locking all relevant rows. This prevents any user from maliciously or accidentally altering the percentage bands to artificially change a student's printed grade retroactively.

---

## Workflow Steps

**Adding a New Grading Rule**
The Exam Controller opens the Grade Divisions Master and selects Add New Rule. They select the Grading Type as Division, enter the Name as "First Division", and set the Code to "1ST_DIV". They define the range minimum as 60.00% and maximum as 74.99%. They set the Scope to Class and select Class 11 and Class 12. They save the record, and the system validates that no overlap exists for 11th and 12th grade Division rules before saving it.

---

## Example Scenario

A school caters to students from Nursery to Class 12 under the CBSE board. The board mandates a 3-point descriptive grading system for early childhood, an 8-point alphabetical Grade system for Classes 4 to 10, and a traditional Marks or Division system for Classes 11 and 12.

The Admin uses the Grade Divisions Master to set this up effortlessly. They create three distinct sets of rules, setting the scope to Class and mapping them to the respective classes. At the end of the year, the Exam Engine processes all 2,000 students. Thanks to the scoping rules, a 3rd grader with 85% gets "Proficient" printed on their card, a 9th grader with 85% gets "A2", and an 11th grader with 85% gets "Distinction"—all automatically handled by this single master configuration without manual intervention.

---

## Related Screens

- **Performance Categories** — The AI-driven, automated counterpart to this screen
- **Exam Module** — The primary consumer of this grading data for report card generation
