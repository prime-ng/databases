# EVT — Event Engine | Complete Analysis Pack (FRD-led)
**Module:** EventEngine (Rule & Event Configuration) | **Code:** EVT | **Date:** 2026-06-29
**Author:** Business Analyst (pa-business-analyst)
**Sources read:** live application code (`Modules/EventEngine` — models, controllers, FormRequests, routes, views, providers, seeder), central/tenant migrations, `0-DDL_Masters/tenant_db_v4.sql`, `module_list.md`, and the Accounting event-engine code (for the dependency boundary). No V2/V1 requirement document exists for this module — all requirements are reverse-engineered from code and marked `[from code]`; design intent that the code does not yet realise is marked `[inferred]`.

> **Register note:** Sections 1–9 (narrative) use business language. Sections 11–12 (Data Dictionary technical view, Dependency/Integration map) and Section 10 use the technical register by design.

> **Scope reality check (read first).** The live module is a **configuration CRUD** for three entities — *Trigger Events*, *Action Types*, and *Rule Configurations* — surfaced as three tabs on one management screen. It does **not** currently contain any engine that detects an event, evaluates a rule, and executes an action; and its three tables have **no database migration or DDL**. The separate cross-module "event → accounting voucher" engine the platform actually uses lives in the **Accounting** module (`acc_*` tables) and is **out of scope** here. This FRD documents what is built, flags the gaps, and logs the missing execution capability as enhancements.

---

## Index
1. Module Overview
2. User Roles & Access
3. Functional Requirements (REQ-EVT-001…009)
4. Business Rules Register (BR-EVT-001…018)
5. Data Requirements
6. Workflows
7. Reporting & Analytics (RPT-EVT-001…003)
8. Future Enhancement Log (ENH-EVT-001…007)
9. Non-Functional Requirements
10. Gap Analysis Readiness Index
11. Data Dictionary (technical view)
12. Cross-Module Dependency & Integration Map
13. Requirements Traceability Matrix (RTM)
14. Requirement Conditions Catalog
15. Validation & Edge-Case Catalog
16. State Machine (FSM) Catalog
17. NFR & Risk Register
18. Prioritization (MoSCoW) & Effort Estimation
19. User Stories (Gherkin) — P0/P1
20. Module Knowledge handoff

---

## Section 1 — Module Overview

### 1.1 Purpose
The Event Engine lets a school define, in business terms and without developer involvement, three reusable building blocks:
- **Trigger Events** — named occurrences the school cares about (e.g. "Homework Submitted Late", "Quiz Score Below Threshold").
- **Action Types** — named responses the system can perform (e.g. "Send Notification", "Award Badge").
- **Rule Configurations** — the link that says *"when this Trigger Event happens (optionally for this group of classes), perform this Action Type."*

The module's intent is to give schools a self-service way to wire automated responses to academic events.

### 1.2 Business Value
- Schools can change automation behaviour through configuration screens instead of code changes.
- A common vocabulary of events and actions can be reused across rules.
- Rules can be activated/deactivated, soft-deleted, and restored, giving administrators safe experimentation.

### 1.3 Scope

**In scope (built today):**
- Create / view / edit / soft-delete / restore / permanently-delete / activate-deactivate for **Trigger Events**.
- The same lifecycle for **Action Types**.
- The same lifecycle for **Rule Configurations**, each linking one Trigger Event + one Action Type, optionally scoped to a Class Group.
- A single tabbed management screen presenting all three lists with search and status filters.
- Activity logging of every create/update/delete/restore/toggle.

**Out of scope (explicitly):**
1. **Execution of rules** — detecting that a trigger event actually fired, evaluating the rule logic, and performing the action. *No engine exists* (logged as ENH-EVT-001/002).
2. **The cross-module event → accounting voucher engine** — that is implemented in the **Accounting** module (`acc_module_events`, `acc_event_voucher_configs`, etc.) and consumed by Transport/Library; it is a different mechanism and is not part of EventEngine.
3. **Editable rule logic** — the rule's logic payload is currently a fixed placeholder; an authoring UI for conditions is not built (ENH-EVT-003).
4. **Any reporting, dashboard, or notification** delivered by this module.
5. **Academic-year scoping** — the entities are not year-scoped today (see 1.4 / NFR).

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| **Trigger Event** | A named, configurable occurrence (with a unique code) that a rule can listen for. |
| **Action Type** | A named, configurable response a rule can invoke; may declare the parameters it needs. |
| **Rule Configuration** | A record binding one Trigger Event to one Action Type, optionally limited to a Class Group, with an active/inactive state. |
| **Class Group** | A reusable grouping of classes defined in School Setup; used to limit a rule's applicability. |
| **Active / Inactive** | Whether a configuration record is currently in effect; toggled without deleting. |
| **Trash (soft delete)** | A record removed from normal lists but recoverable; distinct from permanent deletion. |
| **Rule Logic / Event Logic / Action Logic** | Structured settings (a small JSON payload) intended to hold the evaluable conditions/parameters; currently placeholder data. |

> **Per-school isolation:** All Event Engine data is isolated per school (database-per-tenant); there is no cross-school sharing of events, actions, or rules.

---

## Section 2 — User Roles & Access

### 2.1 Actors
| Actor | Description |
|-------|-------------|
| **School Administrator / Configuration Manager** | The intended owner — defines trigger events, action types, and rules. All access is governed by fine-grained permissions. |
| **System** | Records an audit entry for every change; (intended, not built) would later detect events and run actions. |

### 2.2 Role–Feature Matrix (permission-driven, business view)
Every action is individually permissioned (separate permissions for View-list, View, Create, Update, Delete, Restore, Permanent-delete per entity). A role sees a tab only if it holds the matching "view list" permission.

| Capability | Trigger Events | Action Types | Rule Configurations |
|------------|:--:|:--:|:--:|
| View list / View | ● | ● | ● |
| Create | ● | ● | ● |
| Edit | ● | ● | ● |
| Activate / Deactivate | ● | ● | ● |
| Move to Trash | ● | ● | ● |
| Restore | ● | ● | ● |
| Permanently Delete | ● | ● | ● |

(● = capability exists and is individually permissioned. No role mapping is seeded; permissions must be granted per role.)

---

## Section 3 — Functional Requirements

> IDs are stable; the audit and all later sections reuse them. Priority: P0 Core / P1 Standard / P2 Enhanced. Tags from the controlled vocabulary.

### REQ-EVT-001 — Manage Trigger Events `[from code]`
- **Priority:** P0 · **Tags:** [DATA_ENTRY][CONFIGURATION]
- **Description:** Administrators can create, view, edit, activate/deactivate, trash, restore, and permanently delete Trigger Events. Each has a unique code, a name, an optional description, and an active flag.
- **Actors:** Initiates/Processes — Administrator; Views — Administrator.
- **Business Rules:** BR-EVT-001, BR-EVT-002, BR-EVT-006, BR-EVT-013, BR-EVT-014, BR-EVT-015.
- **Acceptance Criteria:**
  - Creating a Trigger Event with a duplicate code is rejected with a clear message. (YES/NO)
  - A created event appears on the Trigger Event tab. (YES/NO)
  - Trashing an event removes it from the active list and it appears in the Trash view. (YES/NO)
  - A trashed event can be restored. (YES/NO)
  - Every create/edit/trash/restore/toggle writes an activity-log entry. (YES/NO)

### REQ-EVT-002 — Manage Action Types `[from code]`
- **Priority:** P0 · **Tags:** [DATA_ENTRY][CONFIGURATION]
- **Description:** Administrators manage the full lifecycle of Action Types (unique code, name, optional description, optional declared parameters, active flag).
- **Business Rules:** BR-EVT-003, BR-EVT-004, BR-EVT-006, BR-EVT-013, BR-EVT-014, BR-EVT-015.
- **Acceptance Criteria:**
  - Duplicate action code is rejected. (YES/NO)
  - An active Action Type is selectable when building a Rule. (YES/NO)
  - Trash / restore / permanent-delete behave as specified. (YES/NO)

### REQ-EVT-003 — Manage Rule Configurations `[from code]`
- **Priority:** P0 · **Tags:** [DATA_ENTRY][CONFIGURATION]
- **Description:** Administrators create a Rule that binds one Trigger Event to one Action Type, optionally restricting it to a Class Group, with a unique rule code, name, description, and active flag.
- **Business Rules:** BR-EVT-005, BR-EVT-007, BR-EVT-008, BR-EVT-009, BR-EVT-013, BR-EVT-014, BR-EVT-016.
- **Acceptance Criteria:**
  - A Rule cannot be saved without a Trigger Event and an Action Type. (YES/NO)
  - The selected Trigger Event and Action Type must exist and be valid references. (YES/NO)
  - A Class Group is optional; if supplied it must be a valid School Setup class group. (YES/NO)
  - Duplicate rule code is rejected (ignoring the record being edited). (YES/NO)

### REQ-EVT-004 — Unified Tabbed Management Screen `[from code]`
- **Priority:** P0 · **Tags:** [CONFIGURATION][DASHBOARD]
- **Description:** A single "Event Engine Management" screen presents three tabs (Trigger Events, Action Types, Rule Configurations). Each tab shows its own paginated list, search box, and active/inactive filter; rule list additionally filters by Trigger Event and Action Type. A tab is shown only if the user holds its view permission.
- **Business Rules:** BR-EVT-010, BR-EVT-011, BR-EVT-012.
- **Acceptance Criteria:**
  - Each tab paginates independently. (YES/NO)
  - Searching within a tab filters only that tab's list. (YES/NO)
  - A user lacking a tab's view permission does not see that tab. (YES/NO)

### REQ-EVT-005 — Activate / Deactivate any configuration `[from code]`
- **Priority:** P1 · **Tags:** [CONFIGURATION][WORKFLOW]
- **Description:** Each Trigger Event, Action Type, and Rule can be toggled active/inactive in place without deleting. Inactive items are excluded from selection lists used when building rules.
- **Business Rules:** BR-EVT-013, BR-EVT-007.
- **Acceptance Criteria:** Toggling returns the new state; inactive Trigger Events/Action Types do not appear in the Rule build dropdowns. (YES/NO)

### REQ-EVT-006 — Trash, Restore & Permanent Delete `[from code]`
- **Priority:** P1 · **Tags:** [WORKFLOW][CONFIGURATION]
- **Description:** All three entities support soft delete (with a Trash view), restore, and an irreversible permanent delete, each individually permissioned and audit-logged.
- **Business Rules:** BR-EVT-014, BR-EVT-015, BR-EVT-016.
- **Acceptance Criteria:** Trashed records are listed in Trash; permanent delete removes them irrecoverably; both are audit-logged. (YES/NO)

### REQ-EVT-007 — Activity Logging of all changes `[from code]`
- **Priority:** P1 · **Tags:** [INTEGRATION]
- **Description:** Every create, update, trash, restore, permanent-delete, and toggle on any of the three entities records an activity-log entry capturing the action, the record code, and the acting user (and field-level changes on edit).
- **Business Rules:** BR-EVT-017.
- **Acceptance Criteria:** A change to any record produces a corresponding activity-log entry. (YES/NO)

### REQ-EVT-008 — Configurable rule logic payload `[inferred]`
- **Priority:** P2 · **Tags:** [CONFIGURATION]
- **Description:** Intended capability — administrators author the evaluable condition payload for a rule (e.g. a minimum score threshold) and the parameters an action requires. **Not built:** the rule logic is currently a fixed placeholder and the action parameters are stored but not authored through the UI.
- **Business Rules:** BR-EVT-018.
- **Acceptance Criteria:** Saved rule logic reflects administrator input (not a hardcoded value). (YES/NO) — *currently NO.*

### REQ-EVT-009 — Programmatic access to configurations `[from code, stub]`
- **Priority:** P2 · **Tags:** [INTEGRATION]
- **Description:** An authenticated API surface to read/write Event Engine configurations. A route group exists (`api/v1/eventengines`) but the handlers are unimplemented stubs.
- **Acceptance Criteria:** API returns configuration data for authenticated callers. (YES/NO) — *currently NO.*

---

## Section 4 — Business Rules Register

| ID | Rule (business statement) | Type | Trigger | Enforcement Point | Priority |
|----|---------------------------|------|---------|-------------------|----------|
| BR-EVT-001 | A Trigger Event code must be unique among non-deleted events. | Validation | Create/Edit Trigger Event | Trigger Event form | P0 |
| BR-EVT-002 | Trigger Event name is required (≤100 chars); code required (≤50). | Validation | Create/Edit | Trigger Event form | P0 |
| BR-EVT-003 | An Action Type code must be unique (ignoring the record being edited). | Validation | Create/Edit Action Type | Action Type form | P0 |
| BR-EVT-004 | Action Type name is required (≤100); code required (≤50). | Validation | Create/Edit | Action Type form | P0 |
| BR-EVT-005 | A Rule must reference exactly one existing Trigger Event and one existing Action Type. | Validation | Create/Edit Rule | Rule form | P0 |
| BR-EVT-006 | New Trigger Events / Action Types default to Active unless set otherwise. | Workflow | Create | Controller default | P1 |
| BR-EVT-007 | Only Active Trigger Events and Active Action Types are offered when building a Rule. | Workflow | Open Rule form | Rule create/edit lists | P1 |
| BR-EVT-008 | A Rule's Class Group is optional; if provided it must be a valid School Setup class group. | Validation | Create/Edit Rule | Rule form | P1 |
| BR-EVT-009 | A Rule code must be unique (ignoring the record being edited). | Validation | Create/Edit Rule | Rule form | P0 |
| BR-EVT-010 | Each management tab maintains its own independent pagination. | Workflow | View screen | Management screen | P1 |
| BR-EVT-011 | Search within a tab matches code / name / description for that entity only. | Workflow | Search | Management screen | P1 |
| BR-EVT-012 | A tab is visible only to users holding that entity's "view list" permission. | Permission | Render screen | Management screen | P0 |
| BR-EVT-013 | Activating/deactivating a record changes only its active state; it is not deleted. | Workflow | Toggle | Toggle action | P1 |
| BR-EVT-014 | Trashing a record removes it from active lists but keeps it recoverable. | Workflow | Trash | Destroy action | P1 |
| BR-EVT-015 | Permanent delete is irreversible and individually permissioned. | Permission/Workflow | Permanent delete | Force-delete action | P1 |
| BR-EVT-016 | Trashing a Rule deactivates it as part of the trash operation. | Workflow | Trash Rule | Rule destroy | P2 |
| BR-EVT-017 | Every create/update/trash/restore/permanent-delete/toggle is recorded in the activity log with actor and record code. | Workflow | Any mutation | All controllers | P1 |
| BR-EVT-018 | A Rule's evaluable logic and an Action's required parameters should be administrator-authored, not fixed. | Validation | Create/Edit Rule/Action | Rule/Action form | P2 *(unmet — see EVT-G06)* |

---

## Section 5 — Data Requirements (business view)

Three business entities, all isolated per school, none currently academic-year-scoped:

**5.1 Trigger Event** — code (unique), name, description, active flag, logic payload (placeholder), audit/soft-delete metadata. *Privacy: Internal (configuration data, no PII).*

**5.2 Action Type** — code (unique), name, description, declared required parameters, logic payload (placeholder), active flag, audit/soft-delete metadata. *Privacy: Internal.*

**5.3 Rule Configuration** — rule code (unique), rule name, description, linked Trigger Event, linked Action Type, optional Class Group, logic configuration (placeholder), active flag, audit/soft-delete metadata. *Privacy: Internal.*

> **Data integrity caveat (P0):** none of these entities has a migration or DDL definition (see Section 11). The data model is declared only in application code.

---

## Section 6 — Workflows

### Workflow 1 — Define a reusable Trigger Event / Action Type
- **Trigger:** Administrator needs a new event or action building block. **End state:** building block saved and Active.
- **Actors:** Administrator | System.
- **Steps:** 1) Admin opens the relevant tab → Create. 2) Admin enters code + name (+ description). 3) System validates uniqueness (BR-EVT-001/003). 4) System saves as Active and writes an audit entry. 5) Admin returns to the tab with a success message.
- **Exception paths:** Duplicate or missing code/name → validation error, nothing saved. Save failure on toggle → failure response returned.
- **Notifications:** None (module emits no notifications today).

### Workflow 2 — Build a Rule Configuration
- **Trigger:** Admin wants to link an event to an action. **End state:** Rule saved.
- **Steps:** 1) Admin opens Rule Configuration → Create. 2) System presents only Active Trigger Events and Active Action Types, plus Class Groups (BR-EVT-007). 3) Admin selects a Trigger Event, an Action Type, optionally a Class Group, and enters a unique rule code/name. 4) System validates references + uniqueness (BR-EVT-005/008/009). 5) System saves the Rule (logic payload set to a placeholder — EVT-G06) and audits it.
- **Exception paths:** Missing/invalid Trigger Event or Action Type, or duplicate rule code → validation error.
- **Notifications:** None.

### Workflow 3 — Retire / recover a configuration
- **Trigger:** A building block or rule is obsolete. **End states:** Trashed, Restored, or Permanently Deleted.
- **Steps:** Deactivate (keeps record) → Trash (recoverable) → optionally Restore, or Permanently Delete (irreversible). Each step is permissioned and audited.
- **Exception paths:** Insufficient permission → action refused. Restoring a previously-trashed record returns it (inactive for Rules per BR-EVT-016).
- **Notifications:** None.

---

## Section 7 — Reporting & Analytics

> No reporting is built today. The following are the minimum viable reports the configuration data supports; logged for the audit's RPT coverage.

| ID | Purpose | Audience | Frequency | Contents | Filters | Export | Status |
|----|---------|----------|-----------|----------|---------|--------|--------|
| RPT-EVT-001 | Active Rules catalogue — every rule with its event, action, class-group scope and state. | Administrator | On demand | Rule code/name, trigger event, action type, class group, active flag | Status, Trigger Event, Action Type | PDF/Excel `[inferred]` | Not built |
| RPT-EVT-002 | Trigger Event & Action Type registers — full configuration listings. | Administrator | On demand | Code, name, description, active flag | Status, search | Excel `[inferred]` | Not built |
| RPT-EVT-003 | Configuration change/audit report — who changed which configuration when. | Administrator/Auditor | On demand | Activity-log entries for the three entities | Date range, entity, user | PDF/Excel `[inferred]` | Not built (data exists via activity log) |

---

## Section 8 — Future Enhancement Log

| ID | Enhancement | Rationale | Priority |
|----|-------------|-----------|----------|
| ENH-EVT-001 | **Event detection** — a mechanism by which other modules announce that a trigger event fired. | Without it, rules are never evaluated. | P0 (to make module functional) |
| ENH-EVT-002 | **Rule execution engine** — evaluate matching rules and invoke their action types when an event fires. | Core missing capability; "engine" currently does nothing. | P0 |
| ENH-EVT-003 | **Rule-logic authoring UI** — let admins define conditions (e.g. score thresholds) and action parameters. | Logic payload is a fixed placeholder (EVT-G06). | P1 |
| ENH-EVT-004 | **Define database schema** — migrations + DDL for the three tables. | Tables have no migration/DDL (EVT-G01); module is non-runnable. | P0 |
| ENH-EVT-005 | **Resolve prefix** — align table prefix with the registry (`sys_`) or the convention. | `lms_` tables vs registered `sys_` (EVT-G02). | P1 |
| ENH-EVT-006 | **Notification integration** — let an Action Type send notifications via the Notification module. | Common action; nothing wired today. | P2 |
| ENH-EVT-007 | **Complete / remove the API** — implement or retire the `eventengines` API stub. | Stub endpoints (EVT-G11). | P2 |

---

## Section 9 — Non-Functional Requirements (narrative)
- **9.1 Performance:** Lists paginate at 10/page per tab; search is substring match on code/name/description. Volumes are small (configuration, not transactional).
- **9.2 Security:** Every action is individually permissioned via tenant permissions; tabs hide on missing permission. **Gap:** FormRequests authorise `true` (authorisation relies solely on controller Gate checks); the RuleEngineConfig policy binding points to a non-existent class (EVT-G04). Data is per-school isolated (database-per-tenant).
- **9.3 Usability:** One screen, three tabs, consistent CRUD + Trash pattern; placeholder logic fields are confusing to administrators (EVT-G06).

---

## Section 10 — Gap Analysis Readiness Index (downstream contract)

### 10.1 Coverage table
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---|---|---|---|---|---|---|---|---|
| REQ-EVT-001 | Manage Trigger Events | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-EVT-002 | Manage Action Types | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-EVT-003 | Manage Rule Configurations | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-EVT-004 | Unified tabbed screen | P0 | CONFIGURATION, DASHBOARD | No | Yes | No | No | Yes |
| REQ-EVT-005 | Activate/Deactivate | P1 | CONFIGURATION, WORKFLOW | No | Yes | No | No | Yes |
| REQ-EVT-006 | Trash/Restore/Delete | P1 | WORKFLOW, CONFIGURATION | No | Yes | No | No | Yes |
| REQ-EVT-007 | Activity logging | P1 | INTEGRATION | No | No | No | No | Yes |
| REQ-EVT-008 | Configurable rule logic | P2 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-EVT-009 | Programmatic API | P2 | INTEGRATION | No | No | Yes | No | Yes |

### 10.2 Business-rule coverage: 18 rules (BR-EVT-001…018) — Validation 8, Workflow 7, Permission 2, mixed 1.
### 10.3 Report coverage: 3 (RPT-EVT-001…003) — all "Not built".
### 10.4 Totals (reconciled):
- **REQ:** 9 (P0 = 4 [001,002,003,004]; P1 = 3 [005,006,007]; P2 = 2 [008,009])
- **BR:** 18
- **Workflows:** 3
- **Reports:** 3
- **ENH:** 7

---

## Section 11 — Data Dictionary (technical view)

> **⚠️ Schema-of-record gap:** the three tables are declared only in Eloquent models. **No migration and no DDL** define them (verified: not in `Modules/EventEngine/database/migrations`, not in central/tenant `database/migrations`, not in `tenant_db_v4.sql`). Types below are inferred from `$casts`, `$fillable`, controller writes, and FormRequest rules. **Prefix anomaly:** model tables use `lms_` though the registry (`module_list.md`) lists `sys_`.

### `lms_trigger_event` (model `Modules\EventEngine\Models\TriggerEvent`, SoftDeletes)
| Column | Type | Null | Constraint | Cast | Business field |
|--------|------|------|-----------|------|----------------|
| id | bigint PK | No | PK | — | — |
| code | varchar(50) | No | unique (active) | — | Event code |
| name | varchar(100) | No | — | — | Event name |
| description | text | Yes | — | — | Description |
| event_logic | json | Yes | — | array | Logic payload (placeholder) |
| is_active | tinyint | No | default active | boolean | Active flag |
| created_at/updated_at/deleted_at | timestamp | — | soft delete | datetime | Audit |

### `lms_action_type` (model `ActionType`, SoftDeletes)
| Column | Type | Null | Constraint | Cast | Business field |
|--------|------|------|-----------|------|----------------|
| id | bigint PK | No | PK | — | — |
| code | varchar(50) | No | unique | — | Action code |
| name | varchar(100) | No | — | — | Action name |
| description | text | Yes | — | — | Description |
| action_logic | json | Yes | — | array | Logic payload (placeholder) |
| required_parameters | json | Yes | — | array | Declared parameters (stored, not UI-authored) |
| is_active | tinyint | No | — | boolean | Active flag |
| created_at/updated_at/deleted_at | timestamp | — | soft delete | datetime | Audit |

### `lms_rule_engine_configs` (model `RuleEngineConfig`, SoftDeletes)
| Column | Type | Null | Constraint | Cast | Business field |
|--------|------|------|-----------|------|----------------|
| id | bigint PK | No | PK | — | — |
| rule_code | varchar(50) | No | unique (ignore self) | — | Rule code |
| rule_name | varchar(100) | No | — | — | Rule name |
| description | text | Yes | — | — | Description |
| trigger_event_id | bigint | No | FK → lms_trigger_event.id | — | Linked event |
| applicable_class_group_id | bigint | Yes | FK → sch_class_groups_jnt.id | — | Class-group scope (SchoolSetup) |
| logic_config | json | Yes | — | array | Rule logic (hardcoded `{min_score:1}` — EVT-G06) |
| action_type_id | bigint | No | FK → lms_action_type.id | — | Linked action |
| is_active | tinyint | No | — | boolean | Active flag |
| created_at/updated_at/deleted_at | timestamp | — | soft delete | datetime | Audit |

---

## Section 12 — Cross-Module Dependency & Integration Map (technical)

**Outbound (EventEngine reads from):**
| Source module | Data/Entity | Mechanism | Why |
|---|---|---|---|
| SchoolSetup | `SchClassGroupsJnt` (`sch_class_groups_jnt`) | `RuleEngineConfig.applicable_class_group_id` belongsTo | Limit a rule to a group of classes |
| Platform (App) | `App\Policies\{TriggerEvent,ActionType,RuleEngineConfig}Policy`, `activityLog()` helper | Gate + helper | Authorisation + audit |

**Inbound (who consumes EventEngine):** **None** — no other module references `Modules\EventEngine\*` (verified by grep). The module currently has no subscribers.

**Adjacent engines (separate, do NOT conflate — verified):**
| Engine | Module | Tables | Migrated | Relationship to EVT |
|---|---|---|---|---|
| Event → Accounting Voucher engine | **Accounting** | `acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log` | **Yes** (tenant migrations 2026-06-15) | This is the real cross-module event mechanism; consumed by Transport (`FeeCollectionController`, `StudentAllocationController`) and Library (`LibFineController`, `LibMemberController`) via `RemoteEntryService`. **Independent of EVT.** |
| Recommendation trigger/rules | **Recommendation** | `rec_trigger_events`, `rec_recommendation_rules` | Yes | Recommendation's own engine; independent of EVT. |

> **Conclusion for architects:** The platform's working "event engine" capability is the **Accounting** acc_* mechanism. `Modules/EventEngine` is a standalone, unmigrated rule-config scaffold with no consumers — its future (build out vs. retire/merge) is an open architecture decision.

---

## Section 13 — Requirements Traceability Matrix (RTM)

| REQ | Feature | BR refs | Screen(s) | Workflow | Report | Test ref | Code Status | Gap |
|-----|---------|---------|-----------|----------|--------|----------|-------------|-----|
| REQ-EVT-001 | Trigger Events CRUD | 001,002,006,013,014,015 | Trigger Event tab + forms/trash | WF1, WF3 | RPT-EVT-002/003 | TC-EVT-001 | PARTIAL | No migration (EVT-G01) |
| REQ-EVT-002 | Action Types CRUD | 003,004,006,013,014,015 | Action Type tab + forms/trash | WF1, WF3 | RPT-EVT-002/003 | TC-EVT-002 | PARTIAL | No migration; params not authored |
| REQ-EVT-003 | Rule Config CRUD | 005,007,008,009,013,014,016 | Rule tab + forms/trash | WF2, WF3 | RPT-EVT-001/003 | TC-EVT-003 | PARTIAL | Broken policy binding (EVT-G04); placeholder logic |
| REQ-EVT-004 | Tabbed screen | 010,011,012 | index.blade | — | — | TC-EVT-004 | DONE | Resource index actions dead (EVT-G05) |
| REQ-EVT-005 | Activate/Deactivate | 013,007 | toggle on each tab | WF3 | — | TC-EVT-005 | DONE | toggle audit-before-save (EVT-G10) |
| REQ-EVT-006 | Trash/Restore/Delete | 014,015,016 | trash views | WF3 | — | TC-EVT-006 | DONE | restore leaves rule inactive (BR-EVT-016) |
| REQ-EVT-007 | Activity logging | 017 | all controllers | all | RPT-EVT-003 | TC-EVT-007 | DONE | — |
| REQ-EVT-008 | Configurable logic | 018 | (intended) rule form | WF2 | — | TC-EVT-008 | NOT STARTED | EVT-G06 |
| REQ-EVT-009 | API | — | api/v1/eventengines | — | — | TC-EVT-009 | NOT STARTED | Empty handlers (EVT-G11) |

---

## Section 14 — Requirement Conditions Catalog
*(Canonical copy also belongs at `5-Requirement_Conditions/EventEngine_Conditions.md`; this is the source.)*

| Condition (=BR) | Entity/Field | Condition (business) | Type | Trigger | On-violation behaviour |
|---|---|---|---|---|---|
| BR-EVT-001 | Trigger Event.code | Unique among non-deleted | Validation | Save | Reject with "code already exists" |
| BR-EVT-003 | Action Type.code | Unique (ignore self on edit) | Validation | Save | Reject |
| BR-EVT-005 | Rule.trigger_event_id / action_type_id | Both required & must exist | Validation | Save | Reject "please select…" |
| BR-EVT-008 | Rule.applicable_class_group_id | Optional; must be valid if set | Validation | Save | Reject "class group invalid" |
| BR-EVT-009 | Rule.rule_code | Unique (ignore self) | Validation | Save | Reject |
| BR-EVT-007 | Rule build lists | Only active events/actions offered | Workflow | Open form | Inactive items excluded |
| BR-EVT-012 | Tab visibility | View permission required | Permission | Render | Tab hidden |
| BR-EVT-015 | Permanent delete | Permission required; irreversible | Permission | Force delete | Refuse if unpermissioned |
| BR-EVT-017 | All mutations | Must write audit entry | Workflow | Any mutation | (must always occur) |

---

## Section 15 — Validation & Edge-Case Catalog

| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected |
|---|---|---|---|---|---|---|
| Trigger/Action/Rule code | "HW_LATE" | duplicate code | 50 chars | blank | two admins save same code | unique enforced (BR-001/003/009); race may slip without DB unique index — **EVT-G01 removes the index too** |
| name | "Late Homework" | — | 100 chars | blank → reject | — | required ≤100 |
| trigger_event_id (rule) | existing active id | non-existent id | — | null → reject | event deleted after list load | exists rule (BR-005); stale id rejected |
| applicable_class_group_id | valid group | invalid id | — | null → allowed | group deleted | optional; validated if present (BR-008) |
| Toggle is_active | 0 / 1 | "yes" | — | missing → reject | concurrent toggles | boolean required; audit written before save (EVT-G10) |
| Restore | trashed record | active record | — | — | concurrent restore | restores; rule stays inactive |

---

## Section 16 — State Machine (FSM) Catalog

**Entity: any configuration record (Trigger Event / Action Type / Rule)**
| From | Event/Action | Guard | To | Side-effects |
|------|--------------|-------|----|--------------|
| (none) | Create | validation passes | Active | audit "Stored" |
| Active | Deactivate (toggle) | permission | Inactive | audit "Toggled" |
| Inactive | Activate (toggle) | permission | Active | audit "Toggled" |
| Active/Inactive | Trash | delete permission | Trashed (for Rule also set Inactive — BR-016) | audit "Trashed" |
| Trashed | Restore | restore permission | Active (Rule: Inactive) | audit "Restored" |
| Trashed | Permanent delete | forceDelete permission | (gone) | audit "Deleted" |

Terminal state: Permanently deleted. Illegal: editing/toggling a Trashed record from the active lists (must be restored first).

> Note: states are driven by a boolean `is_active` + soft-delete, **not** a dynamic-status master (no D29 dropdown-master backing here).

---

## Section 17 — NFR & Risk Register

**NFR**
| NFR | Category | Requirement | Threshold |
|-----|----------|-------------|-----------|
| NFR-EVT-001 | Security | Every action individually permissioned; per-school data isolation | 100% of actions gated |
| NFR-EVT-002 | Performance | Tab list response | < 1s at typical config volumes (10/page) |
| NFR-EVT-003 | Auditability | All mutations logged with actor + code | 100% coverage |
| NFR-EVT-004 | Integrity | Unique codes enforced at DB level | DB unique index present *(unmet — no migration)* |

**Risk**
| Risk | Cat | L | I | Mitigation | Owner |
|------|-----|---|---|-----------|-------|
| RISK-EVT-001 | Module non-runnable — no migration/DDL for its tables | Tech | H | H | Author migrations (ENH-EVT-004) before any rollout | DB Architect |
| RISK-EVT-002 | RuleEngineConfig policy points to non-existent class → runtime error | Tech | H | M | Repoint to `App\Policies\RuleEngineConfigPolicy` (EVT-G04) | Backend Dev |
| RISK-EVT-003 | "Engine" implies automation that does not exist → user/stakeholder confusion | Process | M | M | Rename UI or build execution engine (ENH-EVT-001/002) | EA / PO |
| RISK-EVT-004 | Duplicate/overlap with Accounting acc_* engine and Recommendation engine | Arch | M | M | Architecture decision: consolidate or scope clearly | Enterprise Architect |
| RISK-EVT-005 | No unique DB index → duplicate codes under concurrency | Data | M | M | Add unique indexes with migrations | DB Architect |

---

## Section 18 — Prioritization (MoSCoW) & Effort Estimation

**MoSCoW:** Must — REQ-001/002/003/004 + ENH-004 (schema). Should — REQ-005/006/007. Could — REQ-008/009 + ENH-001/002 (the actual engine). Won't (this release) — Notification integration (ENH-006), full API (ENH-007).

**Effort (assumes schema authored first; +h noted):**
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------|------------|--------|
| 1 | Migrations + DDL for 3 tables (decide prefix) | Schema | 8 | EVT-G02 decision | 1 |
| 2 | Fix policy binding + remove dead index actions/stray imports | Backend | 4 | 1 | 1 |
| 3 | Rule-logic authoring UI (conditions + action params) | Full-stack | 24 | 1 | 2 |
| 4 | Event-detection + execution engine | Backend/Integration | 40+ | 1,3 | 3+ |
| 5 | Reports RPT-001/002/003 | Full-stack | 16 | 1 | 2 |
| 6 | Pest tests (CRUD + permissions + toggle/trash) | Testing | 16 | 1,2 | 1–2 |

---

## Section 19 — User Stories (Gherkin) — P0/P1

**US-EVT-001 (REQ-EVT-001, P0)** — *As an Administrator, I want to create Trigger Events so rules can listen for them.*
- Happy: Given valid unique code+name, When I save, Then the event appears Active on the Trigger tab and an audit entry is written.
- Boundary/invalid: Given a code that already exists, When I save, Then I see "code already exists" and nothing is saved.
- Permission denied: Given a user without Create-Trigger-Event, When they open Create, Then access is refused.
- Empty: Given blank name, When I save, Then a required-field error shows.
- DoD: audit logged; appears in list; per-school isolated.

**US-EVT-002 (REQ-EVT-002, P0)** — *As an Administrator, I want to manage Action Types* — analogous criteria (unique code, active default, trash/restore, permission-gated, audited).

**US-EVT-003 (REQ-EVT-003, P0)** — *As an Administrator, I want to bind an event to an action via a Rule.*
- Happy: Given an active event + active action + unique rule code, When I save, Then the rule is created and audited.
- Boundary: Given no action selected, When I save, Then "please select an action type".
- Invalid ref: Given a class group that doesn't exist, When I save, Then validation rejects it.
- Permission denied: without Create-Rule permission → refused.
- DoD: references validated; audit logged; (note: logic payload currently placeholder — EVT-G06).

**US-EVT-004 (REQ-EVT-004, P0)** — *As an Administrator, I want one screen with three tabs* — each tab paginates/searches independently; a tab hides without its view permission.

**US-EVT-005 (REQ-EVT-005, P1)** — *As an Administrator, I want to activate/deactivate items* — toggling returns new state; inactive events/actions disappear from rule dropdowns.

**US-EVT-006 (REQ-EVT-006, P1)** — *As an Administrator, I want trash/restore/permanent-delete* — trashed items listed in Trash; restore recovers; permanent delete irreversible; all permissioned + audited.

**US-EVT-007 (REQ-EVT-007, P1)** — *As an Auditor, I want every configuration change logged* — each mutation produces an activity-log entry with actor and record code.

---

## Section 20 — Module Knowledge handoff
Module knowledge seeded/updated at `AI_Brain/module-knowledge/EVT_EventEngine.md` (v1.0, 2026-06-29) with verified counts, the prefix/migration/engine anomalies, the EventEngine-vs-Accounting-engine distinction, gaps EVT-G01…G11, and this FRD's counts (REQ 9 / BR 18 / WF 3 / RPT 3 / ENH 7; P0 4 / P1 3 / P2 2).

> **Audit handoff:** REQ-/BR-/RPT-/ENH- IDs in this document are the stable contract — the downstream audit must reuse them and must not renumber.
