# Competencies Master — Business Requirements

## What This Screen Does

The Competencies screen is designed to shift education from topic-based to outcome-based. It stores the master dictionary of specific, measurable skills, behaviors, and knowledge outcomes that students are expected to acquire.

This screen supports deep hierarchical nesting, allowing schools to define broad outcomes and break them down into specific sub-skills. Crucially, this screen maps the school's internal objectives directly to external national standards like the National Education Policy or National Curriculum Framework.

---

## When This Screen Is Used

- Curriculum Mapping Phase when Academic Directors translate official board guidelines into the digital system
- Skill Framework Expansion when adding new, modern requirements to the curriculum like coding logic or financial literacy
- Subject Specialization when Heads of Departments define specific outcomes that apply exclusively to their subjects

---

## Key Fields at a Glance

**Hierarchical Architecture**
A Parent Competency field links a skill to a broader parent skill, allowing the creation of a skill tree. A background Breadcrumb Path mechanism allows the system to instantly fetch all sub-skills of a master skill for reporting purposes without slow queries.

**Core Identity**
A Unique Tracking ID provides an unchanging identifier used for global analytics and data warehousing. A Reference Code and Name act as a unique reference, such as SCI_EXP_01, and the full display name. A Short Name is also captured for condensed mobile app displays.

**Categorization and Scope**
The Competency Type links the skill to a broad category defined in the Competency Types screen. The Cognitive Domain classifies the outcome into one of three psychological domains: Cognitive, Affective, or Psychomotor. The Class and Subject Scope determines where this skill is applicable; if left empty, it becomes a Global Competency available across the entire school.

**External Compliance Mapping**
The NEP Framework Reference aligns the skill with a specific clause from the National Education Policy. The NCF Alignment aligns the skill with the National Curriculum Framework. The Board Learning Outcome Code aligns the skill with the specific educational board's official outcome code.

---

## Business Rules and Conditions

**Global vs Specific Scope**
The system intentionally allows the Class and Subject fields to be left blank. A competency with blank scope fields must appear in the mapping dropdowns for every subject and class. If a class is selected, the system must restrict this competency so it only appears when teachers are mapping topics within that specific class.

**Domain Standardization**
The Cognitive Domain field must be a strict selection between Cognitive, Affective, or Psychomotor. The system must provide this as a fixed dropdown or radio button. Custom values cannot be entered, ensuring standardized data for radar charts.

**Unique Naming and Coding**
The reference code must be universally unique across the system to prevent confusion during data imports or reporting.

**Automatic Tree Updates**
The system must automatically compute and update the internal tracking paths whenever a competency is saved or moved under a new parent, preserving reporting integrity.

---

## Workflow Steps

**Creating a Hierarchical Competency**
The History HOD navigates to Master and selects Competencies. They click Add Competency, enter the Name as "Critical Analysis of Historical Sources", and provide a unique Code. They select the Cognitive Domain and the appropriate Competency Type. They link it specifically to Class 10 and the Subject History, enter the NCF Alignment Code provided by the government, and save the record. They then create a child competency named "Identifying Bias in Texts", setting the parent to the newly created Critical Analysis competency.

---

## Example Scenario

During an external school inspection, the inspector asks how the school is implementing the government mandate for Psychomotor Development in junior classes.

The Principal opens the system and filters the Competencies master by the Psychomotor domain and Class 2. The system instantly displays a deeply nested list of competencies like "Hand-Eye Coordination" leading to "Catching a Ball", all tagged with official NEP framework reference codes. Because these competencies exist in this master table, teachers are able to map their daily lesson plans directly to them, providing undeniable, organized proof of compliance to the inspector.

---

## Related Screens

- **Topic-Competency Mapping** — Where these defined skills are attached to the actual topics being taught
- **Competency Types** — The parent categories that group these skills together
- **Coverage Audit Report** — Visualizes the delivery of these competencies across the academic term
