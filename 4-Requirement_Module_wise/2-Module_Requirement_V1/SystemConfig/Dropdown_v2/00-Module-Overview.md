# Dropdown Module — Business Requirements Overview

## Module Purpose

The Dropdown Module provides a centralised way to manage all dropdown/select-list values used across the entire school management system. Instead of developers hardcoding dropdown options into every module, the dropdown system allows school administrators to create, edit, and manage these values dynamically through a user interface.

For example, if the system needs a dropdown for "Blood Group" on a student form, the dropdown module allows an admin to create this key (e.g., `blood_group`) and add values like A+, B+, O+, AB+, etc. Every form in the system that needs a blood group dropdown can then reference this key and always show the current values.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| Super Admin / Prime Admin | Define what dropdown needs exist — which table, which column, which menu/tab context |
| School Admin / Teacher | Add, edit, reorder dropdown values for their school |
| System Config Manager | Manage tenant-specific dropdown values |

---

## Module Screens (Tab-wise)

The Prime Dropdown module is accessible through a single multi-tab interface at: `/global-master/dropdown`

| Tab | Screen | Purpose |
|-----|--------|---------|
| Dropdown Needs | Dropdown Need Management | Define what dropdown is needed — link to DB table, column, menu context |
| Dropdown List | Dropdown Value List | View all dropdown keys and their values across the system |
| Create Dropdown | Dropdown Need Mapping | Map existing dropdown values to a dropdown need |
| Dropdown Need & Table Mapping | Cross-reference Mapping | Map dropdown needs to specific dropdown table entries |

Additionally, on the tenant side:
| Page | URL | Purpose |
|------|-----|---------|
| Tenant Dropdowns | `/system-config/dropdown` | Manage school-specific dropdown values (CRUD) |

---

## Core Business Flow (Prime Side)

```
Super Admin creates a Dropdown Need
    ↓
    Defines: which DB table, which column, which menu/tab
    ↓
Admin creates actual Dropdown Values (key + values)
    ↓
Dropdown Need is mapped to Dropdown Values
    ↓
System forms reference the dropdown key to show live options
```

## Core Business Flow (Tenant Side)

```
School Admin navigates to System Config → Dropdown
    ↓
Creates a new dropdown with Key (e.g., bus_route) and Values (e.g., Route A, Route B)
    ↓
System generates key as table_name.column_name (auto-suggested from DB tables)
    ↓
Dropdown is then available for selection in relevant school forms
```

---

## Key Features

**Dropdown Needs (Prime)**
- Define what dropdown is required for each table/column
- Link to specific menu categories, main menus, sub-menus, tabs, and fields
- Control whether tenant schools can create their own values (tenant_creation_allowed)
- Filter by DB Type (Prime/Global/Tenant), Table Name, Column Name

**Dropdown Values (Prime Tenant)**
- CRUD operations for key-value pairs
- Grouped by key with accordion view
- Type classification (String, Integer, Decimal, Date, etc.)
- Status toggle (Active/Inactive)
- Search by key or value
- Filter by type and status
- Pagination support

**Create Dropdown (Mapping)**
- Add single or multiple values to existing keys
- Create new dropdown keys on-the-fly
- Edit/delete mapped dropdowns inline
- Auto-ordinal assignment

**SystemConfig Tenant Dropdown**
- Table/column auto-suggestion from tenant database
- Auto-key generation as `table_name.column_name`
- CRUD with status toggle, type assignment
- Search, type filter, status filter
- Clear button for filters

---

## Document Index

| File | Screen | Description |
|------|--------|-------------|
| [01-Dropdown-Needs.md](./01-Dropdown-Needs.md) | Dropdown Needs | Define dropdown requirements with menu context |
| [02-Dropdown-List.md](./02-Dropdown-List.md) | Dropdown List | View and manage all dropdown key-value pairs |
| [03-Create-Dropdown.md](./03-Create-Dropdown.md) | Create Dropdown | Map and create dropdown values for needs |
| [04-Mapping.md](./04-Mapping.md) | Dropdown Need & Table Mapping | Cross-reference mappings |
| [05-Tenant-Dropdown.md](./05-Tenant-Dropdown.md) | Tenant Dropdowns | School-specific dropdown management |

---

## Data Tables Reference

| Table | Description |
|-------|-------------|
| `sys_dropdown_needs` | Dropdown need definitions — table, column, menu context, permissions |
| `sys_dropdowns` | Actual dropdown key-value pairs |
| `sys_dropdown_need_dropdowns_jnt` | Junction table linking needs to dropdowns |
