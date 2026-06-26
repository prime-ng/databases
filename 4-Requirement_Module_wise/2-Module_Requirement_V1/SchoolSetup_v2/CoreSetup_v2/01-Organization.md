# Organization & Academic Sessions — Business Requirements

## Purpose

This area defines the school entity structure — from multi-branch school groups down to individual schools, with their academic calendars and board affiliations. It answers: **What schools exist, what are their academic years, and which boards do they follow?**

---

## What Is Defined Here

### Organization (School)
Represents a single school or institution. Every tenant has at least one organization record that defines its identity:
- School name, short name, unique code
- Government identifiers (UDISE code, affiliation number)
- Contact details (address, phone, email, website)
- Location (city, area, coordinates)
- Currency and locale settings
- Date of establishment

### Organization Group
A parent entity representing a multi-branch school society or trust:
- Example: "Delhi Public School Society" with member schools in multiple cities
- Groups have their own name, address, and contact details
- Any school may optionally belong to an organization group

### Academic Session
Represents a school year with defined start and end dates:
- Example: "2026-2027" with start date April 1, 2026 and end date March 31, 2027
- Every school can have multiple academic sessions (past, current, future)
- Exactly **one** session is marked as the current/active session at any time

### Board Affiliation
Links a school to an education board (CBSE, ICSE, State Board, etc.):
- Boards are linked at the session level — a school might follow CBSE in one session and ICSE in another
- A school can be affiliated with multiple boards per session

---

## Business Rules

### Organization Rules

| Rule | Rationale |
|------|-----------|
| An organization's code must be unique across the entire platform. | The code is used as a reference identifier. Duplicates would create ambiguity in integrations and reporting. |
| An organization can exist independently without belonging to a group. | Not every school is part of a multi-branch society. Single-branch schools should not be forced into a group structure. |
| System-protected organizations cannot be deleted or deactivated. | Certain organizations are seeded as platform defaults and must always remain available. |
| Soft-deleting an organization first deactivates it (`is_active = false`), then soft-deletes. | This two-step process ensures deactivation triggers any downstream consequences before the record is hidden. |

### Organization Group Rules

| Rule | Rationale |
|------|-----------|
| A group can have any number of member organizations. | School societies can manage any number of branches. No limit is imposed. |
| A group's name must be unique. | Duplicate group names would cause confusion in selection lists and reports. |
| Groups are optional. The system does not require a group hierarchy. | The module is flexible enough for both standalone schools and multi-branch societies. |

### Academic Session Rules

| Rule | Rationale |
|------|-----------|
| Only one academic session can be current at a time for an organization. | A school cannot operate in two academic years simultaneously. Reports, fee structures, and timetables depend on a single active session. |
| When a session is marked as current, all other sessions for that organization are automatically unmarked. | No manual cleanup needed. The system handles the transition atomically. |
| A session's end date must be after its start date. | A session with end date before start date would be logically impossible and would break date-range calculations. |
| The short name for a session must be unique within its organization. | Short names like "2026-27" must not be duplicated, as they are used as display labels. |
| Sessions can be created for past, current, or future periods. | Schools need to maintain historical sessions for records and future sessions for planning. |
| A session can be soft-deleted, which deactivates it first. | Accidental session deletions can be reversed. Deactivation triggers any cascading effects before the record is hidden. |

### Board Affiliation Rules

| Rule | Rationale |
|------|-----------|
| Boards can only be linked or unlinked when a current academic session exists. | Board affiliation is session-scoped. Without a current session, there is no context for the affiliation. |
| A board affiliation can be toggled on/off without affecting the organization or session. | Board changes are administrative adjustments that should not disrupt other school operations. |
| Multiple boards can be active per session. | Some schools follow multiple boards (e.g., CBSE and State Board) simultaneously. |

---

## Scenarios and Edge Cases

### Scenario 1: A school moves from one board to another
A school switching from CBSE to ICSE starting the next academic year:
- **Current session:** CBSE remains affiliated. Academic operations continue as normal.
- **New session:** When the next academic session is created, ICSE is linked. CBSE is unlinked from the new session.
- **Historical data:** The CBSE affiliation remains on the old session for record-keeping.
- **Result:** Reports for the old session show CBSE. Reports for the new session show ICSE.

### Scenario 2: Rolling over to a new academic year
At the end of March, the admin needs to switch to the new academic year:
- Admin creates the new session with April 1 start date.
- Admin marks the new session as current.
- The old session is automatically unmarked.
- **Immediate effects:** All fee structures, timetables, and class assignments that reference "current session" now point to the new session.
- **Rollback:** If the transition was premature, the admin can switch back to the old session. The new session remains available for when it is needed.

### Scenario 3: A multi-branch school group needs reorganization
A school society splits into two independent groups:
- **Option 1:** Create a second organization group. Move some organizations to the new group.
- **Option 2:** Remove organizations from the group, leaving them independent. Create a new group for the new society.
- **Data preservation:** All historical session data, classes, and subjects remain with each organization regardless of group affiliation changes.

### Scenario 4: An organization record needs correction after setup
The school's name was entered incorrectly during initial setup:
- **If no dependent data exists yet:** Edit the name. No cascading effects.
- **If academic sessions and classes exist:** Edit the name. References to the organization name in reports and interfaces update automatically.
- **Cannot change:** The unique code should not be changed once sessions are created, as it may be used as a cross-reference identifier.

### Scenario 5: A session is accidentally marked as current
An admin accidentally marks next year's session as current instead of this year's:
- All forms and reports now reference the wrong session.
- **Fix:** Mark the correct session as current. The system automatically unmarks the incorrect one.
- **No data loss:** No data was created under the wrong session in the short window — or if it was, it now belongs to the correct session context.

### Scenario 6: Permanently deleting a past session
A test session was created and used for initial configuration but is no longer needed:
- **Checks:** The system should verify that no students, fee records, or timetables reference this session.
- **If referenced:** Soft-delete only. The session remains for historical record integrity.
- **If unreferenced:** Permanent deletion is safe.
- **Risk:** Permanently deleting a session that has student enrollments would orphan those enrollment records.
