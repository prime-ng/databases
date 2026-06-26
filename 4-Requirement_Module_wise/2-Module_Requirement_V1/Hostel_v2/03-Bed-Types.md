# Bed Types — Business Requirements

## What This Screen Does

The Bed Types screen defines the various bed configurations available in hostel rooms. Examples include Single Bed, Lower Bunk, Upper Bunk, Trundle Bed, and Cot. This classification helps in room setup and allotment planning.

---

## When This Screen Is Used

- During initial hostel setup to define bed categories
- When new furniture is added to rooms
- To update bed type labels or descriptions

---

## Key Fields

- **Name** — Display name (e.g., "Lower Bunk", "Upper Bunk", "Single Bed")
- **Description** — Brief description of the bed type
- **Default Capacity** — Usually 1 (one student per bed)
- **Status** — Active / Inactive

---

## Business Rules

- Bed type name must be unique within a tenant
- Deactivating a bed type does not affect existing beds using that type
- Only active bed types appear in bed creation forms

---

## Related Screens

- **Beds** (Tab 08) — Bed type is selected when creating/editing beds
