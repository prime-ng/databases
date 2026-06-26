# Incident Types — Business Requirements

## What This Screen Does

The Incident Types screen defines the master list of all possible incident categories used in the hostel. Each type can have a default severity level, auto-escalation thresholds, and required notification flags. This replaces free-text incident categorization with a structured, consistent taxonomy.

---

## When This Screen Is Used

- During initial setup to configure incident categories
- When a new type of incident emerges and needs to be tracked
- To adjust severity or notification rules for an existing type

---

## Key Fields

- **Name** — Incident type name (e.g., "Late Arrival", "Ragging", "Property Damage")
- **Code** — Unique code for system reference
- **Default Severity** — Minor / Moderate / Serious / Critical
- **Auto-Escalate After N Occurrences** — Number of occurrences before auto-escalation
- **Parent Notification Required** — Always / Based on Severity / Never
- **Warning Letter Template** — Template to use for warning letters
- **Description** — What constitutes this type of incident
- **Status** — Active / Inactive

---

## Business Rules

- Type name must be unique within a tenant
- Changing default severity does not affect existing incidents
- Auto-escalation triggers when student reaches N incidents of this type
- Parent notification rules can be overridden at the incident level
- Only active types appear in incident creation forms

---

## Related Screens

- **Incidents** (Tab 27) — Incidents reference types from here
- **Incident Warnings** (Tab 29) — Warning letters use type templates
