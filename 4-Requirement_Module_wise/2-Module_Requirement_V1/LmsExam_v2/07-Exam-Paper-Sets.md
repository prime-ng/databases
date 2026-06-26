# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Creation & Allocation 
### Screen: Exam Paper Sets

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Exam Paper Sets** screen is used to create variants (Set A, Set B, Set C) for a single Exam Paper. This prevents mass cheating in physical or online environments by distributing different question combinations to students sitting adjacent to each other.

### 1.2 Why is this necessary? (Business Justification)
- **Anti-Cheating:** Even if the questions are identical, shuffling their order across different sets makes copying extremely difficult.
- **Variant Mapping:** Often, Set A will have completely different questions than Set B to ensure a wider coverage of the syllabus across different exam batches.

---

## 2. Document Scope
- **In-Scope:** Creation and management of Paper Set variants tied to a parent Exam Paper.
- **Out-of-Scope:** Assigning questions to these sets (handled in Paper Questions).

---

## 3. User Personas
1. **Subject Teacher:** Decides how many variants (sets) are needed for their subject's exam.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Creating a Paper Set
- **Action:** A teacher creates a new variant.
- **Fields Required:**
  - **Exam Paper:** Dropdown selecting the parent paper (e.g., *Annual Exam 2025 - Mathematics*).
  - **Set Code:** Short identifier (e.g., `SET_A`, `SET_1`).
  - **Set Name:** Full name (e.g., `Paper Set A`).
  - **Active Toggle:** `is_active` boolean switch.
  - **Description:** Optional textarea for internal notes.

### FR-02: Constraints & Validation
- **Unique Validation:** The combination of `exam_paper_id` and `set_code` must be entirely unique across the system to prevent two "Set A" variants under the same paper.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Preventing Duplicate Sets
**As a** Teacher,
**I want the** system to reject duplicate set codes,
**So that** I don't accidentally create two "Set A"s for my Math paper.

**Acceptance Criteria:**
- **Given** I already created "SET_A" for the Math paper, **When** I try to create another "SET_A" under the same paper, **Then** the form request returns a validation error.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Set Code** | Max 50 chars. Unique per `exam_paper_id`. |
| **Set Name** | Max 100 chars. |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_exam_papers`.
- **Outgoing Dependencies:** `lms_paper_set_questions`, `lms_exam_allocations`. Deleting a Set orphans its questions and breaks allocations tied specifically to this set.
