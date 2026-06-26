# Business Requirements Document (BRD)
## Module: Marksheet Generation
### Screen: Components & Weightages

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
Once a `ConfigTemplate` is created, it needs **Components**. A marksheet is made of Scholastic (Math, Science), IA (Internal Assessment like Notebooks), and Co-Scholastic (Art, Discipline) areas. This sub-module defines the *weightage* of each area.

### 1.2 Why is this necessary? (Business Justification)
- **Complex Aggregation:** An Exam might be out of 80, and IA out of 20, totaling 100. The system needs to know these exact mathematical weightages to compute the final marksheet accurately.

---

## 2. Document Scope
- **In-Scope:** Scholastic Components, Exam Weightages, IA Components, and Coscholastic Components.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Scholastic Components & Exam Weightage
- **Scholastic Component:** Links a subject to the template.
- **Exam Weightage:** Defines how much a specific `LmsExam` contributes to the final marksheet.
  - *Example:* If Half-Yearly is 80 marks, and the weightage is 100%, the system takes the raw 80. If weightage is 50%, the system computes it out of 40.

### FR-02: IA (Internal Assessment) Components
- **System Behavior:** Defines internal parameters that teachers must grade manually (e.g., Portfolio, Subject Enrichment).
- **Setup:** Admin defines the `max_marks` for each IA component within a template.

### FR-03: Co-Scholastic Components
- **System Behavior:** Defines non-academic subjects (e.g., Work Education, Health & Physical Education).
- **Grading:** These are typically graded directly via the Grading Schema (A, B, C) rather than numeric marks.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Defining IA Weightage
**As an** Admin,
**I want to** add a "Notebook Submission" IA component worth 5 marks to the "Term 1 Template",
**So that** teachers can later enter marks out of 5 for notebooks, and it adds to the total 100.

**Acceptance Criteria:**
- **Given** I am in the Components tab, **When** I map an IA Component to a Config Template with `max_marks = 5`, **Then** the configuration is saved for later data entry.
