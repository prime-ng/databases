# Department SLA — Business Requirements

## What This Screen Does

The Department SLA screen defines department-level Service Level Agreements for complaint resolution. Each SLA maps a complaint category (and optional subcategory) to a target entity (department, designation, role, user group, specific user, vehicle, or vendor), with its own escalation hours, expected resolution time, and escalation entity groups.

## When This Screen Is Used

- **During initial setup** when configuring which departments/roles handle which complaint categories.
- **When assigning specific users or roles** as responsible for certain complaint types.
- **When setting department-specific escalation rules** that differ from category defaults.
- **When configuring vehicle/vendor-specific SLAs** for transport complaints.

## Key Fields

- **Complaint Category** (FK → cmp_complaint_categories) — Primary category
- **Complaint Subcategory** (FK → cmp_complaint_categories, nullable) — Optional subcategory
- **Target Entities (8 nullable FK fields):** Department, Designation, Role, Entity Group, User, Vehicle, Vendor
- **Expected Resolution Hours** (integer, min:1) — Department-specific target
- **Escalation Hours L1–L5** (5 integers, strictly increasing) — Time thresholds
- **Escalation Entity Groups L1–L5** (5 FK → sch_entity_groups, nullable)
- **Is Active** (boolean)

## Business Rules

**Unique Combination:**
Each SLA must be unique for the combination of complaint_category_id + complaint_subcategory_id + all target entity fields. The form request enforces this with a composite unique rule.

**8 Flexible Target Types:**
An SLA can target any combination of department, designation, role, entity group, user, vehicle, and vendor — all optional. This provides extreme flexibility for routing complaints to the right resolver.

**Escalation Hour Ordering:**
Same as categories: L5 > L4 > L3 > L2 > L1, enforced via `gt:` validation.

**Soft Delete:**
Uses SoftDeletes. Trash view, restore, and forceDelete routes available.

## Workflow

1. User navigates to Complaint → Complaint Management → SLA tab.
2. Table shows: Category, Subcategory, Target (department/role/user), Resolution Hours, Active toggle, Actions.
3. User creates an SLA: selects category, optionally subcategory, picks target entities, sets hours.
4. Duplicate category+target combos are rejected.
5. SLA can be toggled, soft-deleted, restored, or force-deleted.

## Requirements

- MUST display at `/complaint/complaint-mgt?tab=sla` as paginated table
- MUST authorize via `tenant.department-sla.*` policy gates
- MUST enforce unique category + subcategory + target combination
- MUST support 8 target entity types (department, designation, role, group, user, vehicle, vendor)
- MUST enforce strictly increasing escalation hours L1–L5
- MUST support is_active toggle via AJAX
- MUST support soft delete with trash view, restore, forceDelete
