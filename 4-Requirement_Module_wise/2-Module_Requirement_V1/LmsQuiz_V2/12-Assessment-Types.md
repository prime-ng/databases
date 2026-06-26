# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Setup
### Screen: Assessment Types

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Assessment Types** screen is a master configuration table used to define the various categories of assessments within the LMS (e.g., Weekly Quiz, Term Exam, Daily Quest).

### 1.2 Why is this necessary? (Business Justification)
- **Categorization:** It allows the school to standardize the nomenclature of tests.
- **Reporting:** Helps filter analytics based on the type of assessment.

---

## 2. Document Scope
- **In-Scope:** Creation and management of Assessment Types.
- **Out-of-Scope:** Actual quiz logic.

---

## 3. User Personas
1. **System Admin / Academic Head:** Sets up the standardized assessment vocabulary for the entire institution.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Creating an Assessment Type
- **Action:** A user creates a new Assessment Type.
- **Fields Required:**
  - **Assessment Code:** Short unique identifier (e.g., `WK_QUIZ`).
  - **Assessment Name:** Full display name (e.g., `Weekly Revision Quiz`).
  - **Assessment Usage Type:** Dropdown (options: `QUIZ`, `QUEST`, `ONLINE_EXAM`, `OFFLINE_EXAM`). This dictates where this assessment type will be available in the system.
  - **Description:** Textarea.
  - **Active Status:** `is_active` toggle.

---

## 5. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Assessment Code** | Unique across the table. Max 50 chars. |
| **Assessment Name** | Max 100 chars. |

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_assessment_usage_types` (Seed data).
- **Outgoing Dependencies:** `lms_quizzes` (Quizzes must belong to an assessment type).
