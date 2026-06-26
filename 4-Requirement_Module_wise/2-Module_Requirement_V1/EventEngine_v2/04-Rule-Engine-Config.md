# Business Requirements Document (BRD)
## Module: Event Engine
### Sub-Module: Rule Configuration
### Screen: Rule Engine Configs

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Rule Engine Config** screen is the heart of the automation module. It connects a specific `Trigger Event` to a specific `Action Type`, creating a functional "If This, Then That" (IFTTT) rule.

### 1.2 Why is this necessary? (Business Justification)
- **Dynamic Workflows:** Allows the school to turn off or turn on specific automation pipelines. For example, they can enable "If Quiz Failed -> Auto Assign Remedial" for Class 10, but disable it for Class 1.

---

## 2. Document Scope
- **In-Scope:** Mapping Triggers to Actions, and optionally restricting the rule to a specific Class Group.
- **Out-of-Scope:** The background Job/Queue that actually processes the rule.

---

## 3. User Personas
1. **System Admin:** Builds the automation rules.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Creating a Rule Configuration
- **Action:** Map a Trigger to an Action.
- **Fields Required:**
  - **Rule Code:** Unique identifier (e.g., `RULE_REMEDIAL_ASSIGN`).
  - **Rule Name:** Human-readable display name.
  - **Trigger Event:** Dropdown listing all active `Trigger Events` (The "IF").
  - **Applicable Class Group:** Dropdown listing Class Groups (Optional). If selected, this rule *only* fires if the student involved belongs to this class group.
  - **Action Type:** Dropdown listing all active `Action Types` (The "THEN").
  - **Status:** `is_active` toggle. If disabled, the automation pipeline stops.
  - **Description:** Textarea explaining the rule.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Class-Specific Automation
**As a** System Admin,
**I want to** restrict the "Auto Assign Remedial" rule to only the "High School" class group,
**So that** primary students aren't overwhelmed with automatic re-tests.

**Acceptance Criteria:**
- **Given** I select "High School" in the `applicable_class_group_id` dropdown, **When** the `QUIZ_FAILED` trigger fires for a Grade 2 student, **Then** the Action Type is ignored because the class group condition was not met.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `evn_trigger_events`, `evn_action_types`, `sch_class_groups`.
- **Outgoing Dependencies:** Background queue workers that evaluate these configs whenever an event is dispatched in the application lifecycle.
