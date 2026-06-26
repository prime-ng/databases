# Bloom Taxonomy Master — Business Requirements

## What This Screen Does

The Bloom Taxonomy screen configures the highest echelon of the school's cognitive learning framework. It establishes Benjamin Bloom’s Revised Taxonomy within the system, categorizing the educational goals of the entire curriculum into a hierarchy ranging from low-level retention to high-level synthesis.

This configuration is the foundational cornerstone for all depth of knowledge analytics. Without this setup, the school can only report on how much syllabus was finished, but cannot report on how deeply the students understood it.

---

## When This Screen Is Used

- System Initialization configured once during the initial setup of the educational software
- Framework Customization when an administrator wants to alter the terminology of the 6 standard levels to align with specific international board guidelines
- Analytics Configuration when establishing the baseline levels for cognitive radar charts and pyramid graphs in the reports module

---

## Key Fields at a Glance

**Identity and Definition**
A Unique Code acts as a standardized identifier, such as REMEMBERING or EVALUATING, which is heavily referenced in background reporting queries and is usually locked. The Display Name provides the human-readable name shown on dashboards, like 'Remembering' or 'Evaluating'. A Detailed Description provides a thorough pedagogical explanation of the cognitive level, such as the ability to recall facts and basic concepts.

**Hierarchical Ranking**
A Bloom Rank or Level captures a numeric value representing the mathematical rank of the cognitive level. This rank scales from 1 for Remembering, which is base-level thinking, up to 6 for Creating, which is the apex of higher-order thinking. 

**State Management**
A Status Toggle acts as an active or inactive switch. If deactivated, this level and all its associated child skills disappear from tagging dropdowns across the system.

---

## Business Rules and Conditions

**Mathematical Integrity of the Rank**
While the exact textual name is up to the school's specific pedagogical style, the numeric ranks from 1 through 6 must be strictly maintained. Analytical charts, like Cognitive Depth Pyramids, rely entirely on this mathematical progression. Furthermore, a level 6 skill is mathematically treated as more advanced than a level 2 skill by the AI when generating adaptive question papers.

**Foundational Parent-Child Dependency**
This screen acts as the master parent for all granular cognitive skills. The system enforces a strict relational dependency. You cannot define granular cognitive skills like Comparing or Listing without first linking them to a valid Bloom Taxonomy level. If a Bloom level is ever deactivated, cascading logic should ideally disable all associated cognitive skills to preserve assessment integrity.

**Uniqueness Enforcement**
The system ensures that duplicate levels cannot be created, preventing data corruption during complex analytics roll-ups.

---

## Workflow Steps

**Customizing a Cognitive Level**
This is typically a one-time setup performed by System Administrators. The Academic Director reviews the default system installation and navigates to the Bloom Taxonomy screen. They wish to rename the apex level, so they click Edit on the record with Rank 6. They change the Display Name from "Creating" to "Synthesizing & Creating" to match their specific educational board's terminology. They update the description to reflect compiling component ideas into a new whole and save the record. All radar charts and dropdowns instantly update to reflect the new terminology while maintaining the mathematical Rank 6 weighting in the background.

---

## Example Scenario

At the end of the academic year, the school's Board of Directors reviews the Coverage Audit Report. 

The system scans all the assessment questions administered throughout the year, checking their tagged Cognitive Skills, and tracing those skills back to the Bloom Rank defined in this screen. The generated Pyramid Chart visually demonstrates that 75% of all exams were restricted to Ranks 1 and 2, which are Rote Memorization and Basic Understanding. 

Appalled by the lack of higher-order thinking, the Directors mandate a new policy for the upcoming year stating that every Summative Exam blueprint must include a minimum of 20% weightage allocated to questions mapping back to Rank 4 and Rank 5. The system enforces this rule during paper generation based entirely on this master setup.

---

## Related Screens

- **Cognitive Skills** — The child screen where specific sub-skills are created and mapped to these 6 broad levels
- **Coverage Audit Report** — The analytics consumer that transforms Bloom Rank data into visual insights
