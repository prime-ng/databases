# Business Requirements Document (BRD)
## Module: Event Engine
### Sub-Module: Setup & Configuration
### Screen: Action Types

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Action Type** screen defines the catalog of automated responses the system can execute when a trigger is fired.

### 1.2 Why is this necessary? (Business Justification)
- **Standardization:** It standardizes what the system *can* do, such as sending an SMS, auto-assigning a quiz, or generating an alert.

---

## 2. Document Scope
- **In-Scope:** Creation of Action Types.
- **Out-of-Scope:** The programmatic execution of the action.

---

## 3. User Personas
1. **System Admin:** Defines the available actions.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Creating an Action Type
- **Action:** Add a new action.
- **Fields Required:**
  - **Action Code:** A unique string constant (e.g., `AUTO_ASSIGN_REMEDIAL`, `SEND_SMS`). Max 50 chars.
  - **Action Name:** Human-readable display name.
  - **Description:** Textarea explaining what the action physically does in the system.
  - **Status:** `is_active` boolean toggle.

---

## 5. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Code** | Unique. Max 50 chars. |

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** N/A (Master table).
- **Outgoing Dependencies:** `evn_rule_engine_configs` (A rule must bind to an Action).
