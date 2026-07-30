# Complaint Category — Business Requirements

## What This Screen Does

The Complaint Categories screen manages the hierarchical classification of complaint types. Categories can be top-level (parent) or sub-categories (child). Each category defines default escalation hours (5 levels L1–L5), expected resolution hours, optional severity/priority scores, optional escalation group assignments, and whether medical checks are required.

## When This Screen Is Used

- **During initial setup** when configuring the complaint types the organization handles (Academic, Transport, Discipline, Health, Infrastructure, etc.).
- **When adding new categories** for new complaint types.
- **When reconfiguring escalation timelines** for existing categories.
- **When assigning escalation groups** to categories for automated routing.

## Key Fields

- **Name** (string 100) — Category display name, unique under the same parent
- **Parent Category** (FK → self, nullable) — For sub-category hierarchy
- **Code** (string 30, nullable, globally unique) — Optional short code (e.g., "ACAD", "TRANSP")
- **Description** (string 512, nullable)
- **Severity Level** (FK → sys_dropdown_table, nullable)
- **Priority Score** (FK → sys_dropdown_table, nullable)
- **Expected Resolution Hours** (integer, min:1) — Target hours for resolution
- **Escalation Hours L1–L5** (5 integers, strictly increasing L1 < L2 < L3 < L4 < L5) — Time thresholds for each escalation level
- **Escalation Entity Groups L1–L5** (5 FK → sch_entity_groups, nullable) — Groups notified at each escalation level
- **Is Medical Check Required** (boolean, default: false)
- **Is Active** (boolean, default: true)

## Business Rules

**Parent-Child Hierarchy:**
A category can optionally have a parent via `parent_id`. A category without a parent is a top-level/main category. A category with a parent is a sub-category. A category cannot reference itself as parent.

**Escalation Hour Ordering:**
The five escalation levels must be strictly increasing: L5 > L4 > L3 > L2 > L1. Expected resolution hours must be less than L1 (validated at application layer, no DB CHECK constraint).

**Unique Naming:**
Category name must be unique under the same parent (composite unique key on `parent_id + name`). Code must be globally unique.

**Delete Protection (Force Delete):**
A category with child sub-categories cannot be force-deleted. The controller checks `ComplaintCategory::where('parent_id', $id)->exists()` and returns an error. Soft delete does not have this check.

**Soft Delete:**
The DDL does NOT include a `deleted_at` column, but the model uses the SoftDeletes trait. This mismatch will cause a SQL error on delete operations.

**Activity Logging:**
All CRUD operations log to activity log via the global `activityLog()` helper. Changes are tracked with old/new values.

**Escalation Group Assignment:**
Each escalation level (L1–L5) can optionally have an entity group assigned for automated escalation routing.

## Workflow

1. User navigates to Complaint → Complaint Management → Categories tab.
2. Table shows hierarchical list: Name, Code, Parent, Severity, Priority, Resolution Hours, Active toggle, Actions.
3. User creates a category: enters name, optional parent, sets escalation hours (strictly increasing), optional severity/priority/groups.
4. User can view, edit, toggle active status, soft-delete (moves to trash), restore, or force delete.
5. Force delete blocks if category has child sub-categories.
6. Activity is logged for every change.

## Requirements

- MUST display at `/complaint/complaint-mgt?tab=category` as paginated table
- MUST authorize via `tenant.complaint-category.*` policy gates
- MUST support parent-child hierarchy (self-referencing FK)
- MUST enforce unique name under the same parent
- MUST enforce globally unique code
- MUST enforce strictly increasing escalation hours L1 < L2 < L3 < L4 < L5
- MUST validate expected_resolution_hours < L1
- MUST support 5 optional escalation entity group assignments
- MUST block force delete if category has child sub-categories
- MUST support is_active toggle via AJAX
- MUST log activity on create, update, delete, restore, force delete
- MUST support soft delete with trash view, restore, forceDelete
- **CRITICAL:** DDL must add `deleted_at` timestamp column for soft delete to work
