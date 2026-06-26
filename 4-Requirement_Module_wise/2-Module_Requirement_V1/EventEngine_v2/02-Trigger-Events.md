# Business Requirements Document (BRD)
## Module: Event Engine
### Sub-Module: Setup & Configuration
### Screen: Trigger Events

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Trigger Event** screen defines the specific system occurrences that can act as a catalyst for an automated action.

### 1.2 Why is this necessary? (Business Justification)
- **Extensibility:** Allows developers and admins to define named constants (like `QUIZ_FAILED` or `ABSENT_3_DAYS`) that the codebase can broadcast when an event happens.

---

## 2. Document Scope
- **In-Scope:** Creation of Trigger Events.
- **Out-of-Scope:** Firing the actual event (handled via Laravel Event listeners in the background).

---

## 3. User Personas
1. **System Admin / Developer:** Creates the master list of triggers recognized by the platform.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Creating a Trigger Event
- **Action:** Add a new event type.
- **Fields Required:**
  - **Code:** A unique string constant (e.g., `QUIZ_FAILED`, `FEE_OVERDUE`). Max 50 chars.
  - **Name:** Human-readable display name (e.g., `Quiz Failed`).
  - **Description:** Textarea explaining exactly when this event fires in the codebase.
  - **Status:** `is_active` boolean toggle.

---

## 5. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Code** | Unique. Must not contain spaces (usually uppercase snake_case). |

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** N/A (Master table).
- **Outgoing Dependencies:** `evn_rule_engine_configs` (A rule must bind to a Trigger).
