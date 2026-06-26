# Business Requirements Document (BRD)
## Module: Marksheet Generation
### Screen: Configuration Templates

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
Before a marksheet can be generated, the school must define **What** is being evaluated. This involves setting up `Marksheet Types` (e.g., Term-1), `Exam Groups` (e.g., UT1 + Half Yearly), and tying them together into a `Config Template`.

### 1.2 Why is this necessary? (Business Justification)
- **Standardization:** Different classes have different grading rules. Primary might only have grades, while Secondary needs strict marks + grades. `Config Templates` allow the school to build repeatable rules for different `Class Groups`.

---

## 2. Document Scope
- **In-Scope:** `MarksheetType`, `ExamGroup`, `ClassGroup`, and `ConfigTemplate` CRUD operations.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Master Lookups Setup
- **Marksheet Types:** Define the category (e.g., Unit Test, Annual Report).
- **Exam Groups:** Group multiple `LmsExam` types into a single logical "Term" for aggregation.
- **Class Groups:** Distinct from timetable class groups. These group classes specifically for grading rules (e.g., "Middle School" = Class 6, 7, 8).

### FR-02: Config Template Builder
- **System Behavior:** The `ConfigTemplate` is the heart of the module.
- **Fields Required:**
  - `name`: E.g., "Class 10 Board Pattern Template"
  - `marksheet_type_id`: Links to the type.
  - `exam_group_id`: Links to the term.
  - `academic_session_id`: Restricts the template to a specific academic year.
  - `grading_schema`: Links to the `Syllabus` module's `GradeDivisionMaster` to define how numeric marks convert to A, B, C, etc.
- **Class Assignment:** A template must be assigned to specific `SchoolClasses` or `ClassGroups` to know who it applies to.

### FR-03: Soft Deletes & Auditing
- **Auditing:** Managed by `ConfigTemplateService` and `activityLog()`. Every template creation, update, or deletion logs the payload and the user who did it.
- **Referential Integrity:** If a template is forcefully deleted (via `forceDelete()`), a `23000` SQL constraint exception is caught and returns a friendly error: "Cannot delete this record because it is referenced by other records."

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Creating a Grading Rule
**As an** Admin,
**I want to** build a Config Template for the 2026 Academic Session using the "10-Point CBSE Grading Schema",
**So that** all students graded under this template automatically get their percentages converted to correct grades.

**Acceptance Criteria:**
- **Given** I am creating a Config Template, **When** I select the grading schema and save, **Then** the `ConfigTemplateService` persists the relationship successfully.
