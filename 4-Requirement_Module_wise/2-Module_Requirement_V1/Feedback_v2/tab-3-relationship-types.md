# Feedback Tab 3: Relationship Types

This screen manages the authorised feedback flows in the system. Each relationship type defines a valid combination of who provides feedback (respondent kind), who receives it (target type), and what context rule applies. This acts as a whitelist — only relationships defined here can be used in feedback cycles.

---

## How It Works

The screen displays a table of all configured relationship types, showing the respondent kind, target type, context requirement, and key flags like peer relationship, self-relationship, and NEP 2020 mandate. Administrators can create, edit, reorder, and deactivate relationship types.

Each relationship type defines a specific feedback flow. For example, STUDENT_TO_CLASS_TEACHER means a Student provides feedback about their Class Teacher, with context resolved by shared Class Section. PARENT_TO_TRANSPORT_DRIVER means a Parent provides feedback about a Transport Driver, with context resolved by Transport Route. The system uses these definitions to determine which feedback forms to show to which users and how to match respondents to their correct targets.

Context required tells the system how to resolve valid respondent-target pairs at runtime. When set to None, any respondent of that kind can rate any target of that type. When set to Class Section, the respondent and target must share a class section. Other contexts include Subject, Subject and Class Section, Transport Route, Hostel, Department, and Custom for flexible school-specific logic.

---

## Important Business Rules

- Each relationship type must have a unique code. The combination of respondent_kind_id, target_type_id, and context_required_id determines the unique identity of a flow.
- Peer relationships (is_peer_relationship = 1) force anonymity to target. This cannot be overridden at the cycle level for child safety reasons.
- Self relationships (is_self_relationship = 1) mean the respondent and target are the same person. These are used for self-reflection forms.
- NEP 2020 mandated relationships (nep_2020_mandated = 1) must always be included when a cycle covers that target type. The system should warn if a cycle is configured without these mandatory flows.
- The default anonymous-to-target flag provides the recommended anonymity setting for this relationship type. Cycles can override this, except for peer relationships where it is always enforced.
- Deactivating a relationship type does not affect existing responses but prevents it from being used in new cycles.
- When context is set to Custom, the application must provide a custom resolver class or callback to determine valid (respondent, target) pairs.

---

## Database Columns & Behavior

### fbk_relationship_types
- `id` — Primary key. SMALLINT UNSIGNED, auto-increment.
- `code` — Unique identifier like STUDENT_TO_CLASS_TEACHER. VARCHAR(60). Unique with soft-delete.
- `name` — Human-readable name for the relationship. VARCHAR(150).
- `description` — Explanation of when this relationship applies. VARCHAR(500).
- `respondent_kind_id` — FK to sys_dropdown_table.id (key: fbk_relationship_types.respondent_kind). Who provides the feedback. INT UNSIGNED.
- `target_type_id` — FK to fbk_target_types.id. Who receives the feedback. SMALLINT UNSIGNED.
- `context_required_id` — FK to sys_dropdown_table.id (key: fbk_relationship_types.context_required). How to resolve valid respondent-target pairs. INT UNSIGNED.
- `is_peer_relationship` — 1 = respondent and target are same kind (student to student). TINYINT(1), default 0.
- `is_self_relationship` — 1 = respondent rates themselves. TINYINT(1), default 0.
- `nep_2020_mandated` — 1 = required by NEP 2020 policy. TINYINT(1), default 0.
- `default_anonymous_to_target` — Recommended anonymity default. TINYINT(1), default 1.
- `is_active` — Soft delete flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines

Master-data CRUD with soft-delete. No complex state machine — records are active or deactivated. Workflow: Admin creates a relationship type with respondent kind, target type, and context → immediately usable in cycles → Admin can edit metadata and flags → Admin can deactivate to prevent use in new cycles → existing responses remain valid. The (respondent_kind_id, target_type_id, context_required_id) combination forms the logical business key and must be unique among active records to prevent duplicate flow definitions.

### Validation Rules & Edge Cases

- **Unique code**: UNIQUE KEY (`code`, `deleted_at`) — code cannot be reused after deletion.
- **Logical uniqueness**: The combination (respondent_kind_id, target_type_id, context_required_id) must be unique among active records. The system must validate this to prevent duplicate flow definitions.
- **is_peer_relationship = 1**: Forces default_anonymous_to_target = 1. Application must prevent setting anonymity to 0 at the cycle level for peer relationships. This is non-negotiable for child safety.
- **is_self_relationship = 1**: Implies respondent_kind_id and target_type_id must be compatible (same person). For example, STUDENT → STUDENT or TEACHER → TEACHER. The target_type_id must point to an individual target type (is_individual = 1).
- **Mutual exclusion**: is_peer_relationship and is_self_relationship can both be 0, but should they both be 1? The business logic likely prevents this — peer means same-kind cross-person, self means same person. Application should validate.
- **context_required_id = Custom**: Requires a registered custom resolver in the application. The system should not allow activating a cycle with a Custom context relationship unless the resolver class is registered.
- **Deactivation with active cycles**: If a relationship type is used by any cycle in Draft or Active status, the system should warn the admin before deactivating. Already-Active cycles will continue to work; only new cycle creation is blocked.
- **Response integrity**: Deactivation must not cascade to fbk_responses. Those rows snapshot relationship_type_id and must remain visible.

### Integration Points

- **fbk_target_types** via target_type_id — determines which entity is being rated.
- **sys_dropdown_table** via respondent_kind_id (key: fbk_relationship_types.respondent_kind) and context_required_id (key: fbk_relationship_types.context_required).
- **fbk_cycle_feedback_types** via relationship_type_id — each cycle feedback type selects one relationship type.
- **fbk_responses** via relationship_type_id — snapshot at submission time.
- **Application resolver layer** for context_required_id = Custom — must implement a class that returns valid (respondent, target) pairs.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View list | Yes | Yes | Yes (read-only) | No | No | No |
| Create new | Yes | No | No | No | No | No |
| Edit existing | Yes | No | No | No | No | No |
| Deactivate | Yes | No | No | No | No | No |
| Delete (if unused) | Yes | No | No | No | No | No |
