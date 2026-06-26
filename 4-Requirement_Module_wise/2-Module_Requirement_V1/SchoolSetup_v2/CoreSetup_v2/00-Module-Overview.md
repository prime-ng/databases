# School Setup Module — Business Requirements Overview

## Module Purpose

The School Setup module contains the foundational configuration that every school needs to define before employees, teachers, and students can be managed. It covers two main areas:

1. **HR & Operations Setup** — The organizational structure (departments, designations), attendance tracking setup (types), leave policies (leave types, student leave types), employee categorization, and deactivation/disablement reasons.
2. **Entity Groups** — A flexible grouping system for creating purpose-driven collections of any entity in the system (students, employees, rooms, etc.)

Think of this module as the **settings panel for how the school organizes its people and operations** — not what they teach (that is curriculum/subject management), but how they are structured as an organization.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| School Admin / HR Admin | Define departments, designations, attendance types, leave types, categories, disable reasons |
| System Admin / Super Admin | Configure entity groups for cross-functional grouping (duty rosters, clubs, committees) |
| Principal | Review organization structure, approve leave type configurations |

---

## Screens

### Screen 1: Department-Designation Management (Single page with tabs)

| Tab | What It Defines |
|-----|----------------|
| **Department** | Functional units of the school (Science Department, Administration, Accounts) |
| **Designation** | Job titles held by employees (Principal, Teacher, HOD, Clerk) |
| **Attendance Types** | Codes for marking daily attendance (Present, Absent, Late, Half Day, Holiday) |
| **Categories** | Staff classification labels (Permanent, Temporary, Contract, Probation) |
| **Disable Reasons** | Reasons for deactivating an employee or record (Resigned, Transferred, Terminated) |
| **Student Leave Types** | Types of leave applicable to students (Sick Leave, Emergency Leave) |

### Screen 2: Entity Group Management (Single page with tabs)

| Tab | What It Defines |
|-----|----------------|
| **Entity Group** | Named groups for any purpose, tied to a purpose defined in the dropdown system |
| **Entity Group Member** | Individual members belonging to an entity group (students, employees, rooms, etc.) |

---

## Cross-Cutting Business Patterns

| Pattern | How It Works |
|---------|-------------|
| **Soft Deletes** | Every entity can be soft-deleted and restored. Permanent deletion is reserved for cleanup of confirmed-obsolete records. |
| **Active/Inactive Toggle** | Every entity has an active/inactive status, toggled via AJAX. Deactivated records are hidden from selection lists. |
| **System Protection** | Entities with `is_system = true` cannot be edited, deleted, or deactivated by users. |
| **Display Order** | Some entities support ordinal/display-order for drag-and-drop reordering. |
| **Activity Logging** | Every create, update, delete, restore, and toggle operation is logged with who performed it and what changed. |

---

## Document Index

| File | What It Covers |
|------|----------------|
| [01-Department-Designation.md](./01-Department-Designation.md) | Departments, designations, attendance types, categories, disable reasons, student leave types |
| [02-Entity-Groups.md](./02-Entity-Groups.md) | Entity groups and members |
