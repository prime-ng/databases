# Entity Groups — Business Requirements

## Purpose

Entity Groups provide a generic, purpose-driven grouping system. Instead of building separate group management for every type of collection (bus route groups, duty rosters, club members, committee members), a single flexible system handles them all.

Any record in any table can be a member of any group. The group's purpose defines what it is for, and the members can be students, employees, rooms — anything in the system.

---

## What Is Defined Here

### Entity Group
A named collection created for a specific purpose:
- Examples: "Bus Route 1 - Morning", "Science Club Members", "Morning Assembly Duty", "Exam Invigilation Team - March 2026"
- Each group has: a purpose (from the dropdown system), a name, a code, and a description
- The purpose defines the context — "transport_route", "club_membership", "duty_roster", "committee"

### Entity Group Member
An individual item belonging to a group:
- Each member references: which group they belong to, what type of entity they are (student, employee, room, etc.), which table the entity lives in, and the specific record ID
- Example: A member of "Bus Route 1 - Morning" might be "Student #1234" from the `sch_students` table
- Members also store the entity's name and code for display purposes

---

## Business Rules

### Entity Group Rules

| Rule | Rationale |
|------|-----------|
| Every group must have a purpose, selected from the dropdown system. | A group without a purpose would be structureless. The purpose gives context to the grouping. |
| Group names must be unique within the same purpose. | You cannot have two "Bus Route 1" groups under the "transport_route" purpose. But you could have "Bus Route 1" under "transport_route" and "Bus Route 1" under "duty_roster" — they serve different purposes. |
| Groups can be searched by name, code, description, or purpose name. | With many groups across the system, quick search helps administrators find what they need. |
| Groups can be filtered by active/inactive status. | Deactivated groups are hidden from selection but their membership data is preserved. |

### Entity Group Member Rules

| Rule | Rationale |
|------|-----------|
| A member can be any entity in the system — students, employees, rooms, teachers, etc. | The system does not restrict membership to a single entity type. This is what makes it a "generic" grouping system. |
| The combination of table name and record ID must be unique within a group. | You cannot add the same student twice to the same bus route group. |
| The entity type (from dropdowns) categorizes what kind of member this is. | While the table name tells the system where to look up the record, the entity type provides a human-readable classification (e.g., "Student", "Teacher", "Staff"). |
| Members can be added or removed from a group at any time. | Group membership is dynamic — rosters change, bus routes get new students, committees add members. |
| A member's name and code are stored directly on the membership record. | This allows the member list to display without querying the source table, improving performance. However, the source record ID is still preserved for deep linking. |
| Members can be searched by entity name, entity code, entity table name, group name, or entity type. | Comprehensive search across all membership attributes helps administrators manage large groups. |
| Members can be filtered by active/inactive status. | Deactivated members are excluded from active group counts and operations but are preserved for history. |

### Cross-Cutting Rules

| Rule | Rationale |
|------|-----------|
| A group cannot be permanently deleted if it has members. | Preserving referential integrity — members would become orphaned. Soft-delete deactivates the group and hides it but preserves membership data. |
| Deactivating a group does not deactivate its members. | Members retain their active/inactive status independently of the group. If a bus route is deactivated for the summer, the student members should remain active so they can be reassigned or reactivated. |
| A member that is deactivated remains in the group. | Deactivation is a status toggle, not a removal. The member stays in the group but is excluded from active operations. |

---

## Business Flow

### Creating a Bus Route Group
1. Admin identifies the need: "I need to group students by their bus route for the morning dispatch."
2. Admin creates an Entity Group with:
   - Purpose: "transport_route" (selected from dropdowns)
   - Name: "Route 1 - Morning"
   - Code: "RT1-M"
   - Description: "Students taking Bus Route 1 in the morning shift"
3. Admin adds members: selects 30 students from the student list, one by one or in bulk
4. Each member is stored with:
   - Entity type: "Student" (from dropdowns)
   - Table: `sch_students`
   - Record ID: the student's database ID
   - Name and code: copied from the student record for quick display
5. The bus dispatch team can now view "Route 1 - Morning" and see all 30 students

### Managing a Duty Roster
1. Admin creates an Entity Group with purpose "duty_roster" and name "Morning Assembly Duty - March 2026"
2. Admin adds 10 teachers as members, each with entity type "Teacher" from table `sch_teachers`
3. Throughout March, the roster is visible to all staff. Substitutions can be made by removing and adding members.
4. At the end of March, the group is deactivated (not deleted — it is preserved for audit).
5. April's roster is created as a new group.

### Managing a Committee
1. Admin creates "Exam Committee 2026" with purpose "committee"
2. Members include both teachers and administrative staff — a mix of entity types in one group
3. This demonstrates the flexibility: a single group can hold any entity type simultaneously

---

## Scenarios and Edge Cases

### Scenario 1: A student changes bus routes mid-year
Student #1234 was in "Route 1 - Morning" but now needs "Route 2 - Evening."
- Admin removes the member from "Route 1 - Morning."
- Admin adds the member to "Route 2 - Evening."
- The student's membership history is not lost — the old membership record remains in the deactivated state.
- Both groups reflect the current state accurately.

### Scenario 2: A group has 200 members and needs bulk operations
"Exam Invigilation Team" has 200 teachers assigned. 50 teachers need to be removed because they have been reassigned.
- Bulk operations are not available at the group management level. Each member must be individually deactivated or removed.
- **Workaround:** If the group is restructured, consider creating a new group and adding the remaining 150 teachers fresh. Then deactivate the old group.

### Scenario 3: A teacher is both a duty roster member and a committee member
Teacher #5678 serves on "Morning Assembly Duty" (duty_roster purpose) and "Science Fair Committee" (committee purpose).
- This is perfectly valid. A single entity (teacher) can be a member of multiple groups across different purposes.
- The teacher appears in both groups independently. Deactivating from one does not affect the other.

### Scenario 4: A group purpose is no longer valid
The school no longer uses bus routes — all students walk to school.
- "transport_route" groups remain in the system but can be deactivated.
- New groups with "transport_route" purpose are no longer created.
- Historical data is preserved for records.
- The purpose dropdown still shows "transport_route" unless it is removed from the dropdown system.

### Scenario 5: A member entity is deleted from the source system
A student who was a member of "Science Club" leaves the school and their student record is force-deleted.
- The entity group member record remains in the system but now references a non-existent record.
- The member's name and code (stored on the membership record) are preserved for display.
- However, clicking through to view the member's profile would fail because the source record is gone.
- **Best practice:** Before force-deleting any record, check entity group memberships and clean them up first.

### Scenario 6: A group is used by the timetable module
The SmartTimetable module uses entity groups for duty rosters and special assignments.
- Changes to group membership are reflected in the timetable when it is regenerated.
- Mid-cycle membership changes may not take effect until the next timetable generation.
- This is a design consideration — the timetable snapshot and the group membership are not automatically synchronized in real time.
