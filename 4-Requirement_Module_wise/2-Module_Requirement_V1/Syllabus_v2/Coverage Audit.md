# Coverage Audit Report — Business Requirements

## What This Screen Does

The Coverage Audit report is the most advanced, compliance-focused analytics tool in the system. It shifts the educational focus from counting how many chapters were finished to evaluating what mental skills the students actually developed.

By analyzing the complex links between Topics, Competencies, and Bloom's Taxonomy, this report visually demonstrates the school's adherence to modern educational mandates like the National Education Policy. It proves to external boards that the school is not just doing rote memorization, but is actively delivering higher-order thinking skills.

---

## When This Screen Is Used

- Accreditation Inspections during school audits to provide undeniable, data-backed proof of curriculum depth
- Curriculum Review by Academic Directors at the end of the year to ensure the syllabus isn't overly focused on simple knowledge but includes skill and attitude development
- Teacher Training identifying if certain departments are completely ignoring practical or emotional domains in their lesson plans

---

## Key Visualizations and Metrics

**Cognitive Domain Radar Chart**
A radial spider web chart plots the spread of taught topics across Bloom's 6 levels, from Remembering to Creating. It visually highlights if a school's teaching is heavily skewed towards one side, exposing gaps in higher-order thinking.

**Competency Type Breakdown**
A donut chart shows the percentage of the delivered syllabus dedicated to high-level categories like KNOWLEDGE, SKILL, and ATTITUDE.

**NEP Framework Compliance Ledger**
A tabular list of specific NEP or NCF framework codes, such as Critical Thinking NEP-4.1, mapped directly to the exact lessons and topics that covered them in the classroom.

**Deficient or Uncovered Competencies Alert**
A critical Red Flag list showing skills that were officially defined by the school, but currently have zero topics mapped to them across the entire year's syllabus, warning the administration of neglected learning goals.

---

## Business Rules and Conditions

**Advanced Weightage-Based Calculation**
The audit does not simply count the number of topics; it calculates a weighted score. If a massive topic that takes 20 periods to teach is mapped to Analytical Thinking, that competency gets a massive mathematical boost in the radar chart. Conversely, if a tiny 1-period topic is mapped to Recall, it barely registers. The formula multiplies the importance of the topic by the importance of the competency to derive the true delivery depth.

**Real-time Dynamic Context Auditing**
The report must respond to real-time delivery status. If a user filters the report by Taught Topics Only, the radar chart instantly redraws. It excludes all future planned topics and shows the cognitive depth of exactly what has been physically delivered to the students up to today's date.

**Primary vs Secondary Competency Filtering**
The interface should provide a toggle to either Analyze Primary Competencies Only or Include Secondary Competencies. This allows the user to either show a highly focused report based only on the main goal of each lesson, or a broad overview of all touched skills.

---

## Workflow Steps

**Auditing Departmental Compliance**
The Academic Director opens the Coverage Audit screen. They select School-Wide View for the current academic session and filter by Taught Topics Only. The system generates the Bloom Taxonomy Radar Chart, and the Director notices the web is heavily pulled towards Remembering and Understanding. Identifying this massive gap in higher-order thinking, they drill down into the English Subject. They find that almost zero topics are mapped to Creating or Evaluating. The Director mandates the English HOD to instantly redesign the Term 2 syllabus to include more creative writing topics to balance the radar chart.

---

## Example Scenario

An external school inspector visits the campus to audit NEP 2020 compliance. They demand to know how the school is integrating Experiential Learning and Vocational Skills into standard subjects like Science and Math.

The Principal opens the Coverage Audit screen, selects Class 10, and generates the NEP Alignment Report. The system's algorithm parses the NEP framework codes mapped to the topics taught. It instantly outputs a document detailing exactly which chapters, on which dates, fulfilled specific experiential clauses, impressing the inspector with automated, undeniable proof of compliance without needing to manually collate teacher lesson plans.

---

## Related Screens

- **Topic-Competency Mapping** — The foundational mapping matrix that feeds data to this report
- **Bloom Taxonomy & Competencies Master** — Provides the hierarchy and labels used in the charts
