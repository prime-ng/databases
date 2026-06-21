# Quest Tab 5: Quest Allocation

This tab is where teachers assign quests to specific students. Unlike the Quiz module where allocation is often done to entire classes, the Quest module allows both class-wide and individual student allocation, giving teachers finer control over who gets which quest.

---

## How It Works

When the teacher opens this tab, they first select a quest from a dropdown. Below that, they see two sections: "Available Students" and "Allocated Students."

**Available Students** lists students who are not yet allocated to this quest. The list is filtered to show only students who belong to the class selected during quest creation. The teacher can search by student name or roll number, or filter by group or section.

**Allocated Students** lists students who have already been assigned to this quest. Each entry shows the student's name, roll number, and the date they were allocated. The teacher can remove a student from this list, which unassigns the quest from that student — but only if the student has not yet started the quest.

To allocate, the teacher selects students from the Available list (individually, all on the current page, or all matching the current filter) and clicks "Allocate." The selected students move to the Allocated list. They can also select multiple students across both lists and use the "Save Bulk Allocation" button to confirm all changes at once.

---

## Bulk Allocation by Class

The teacher can also allocate the quest to an entire class at once using the "Allocate by Class" button. This opens a confirmation dialog that shows the class name and total student count. When confirmed, every student in that class who is not already allocated gets assigned to the quest.

This is useful for standard class-wide assessments. But for remedial or enrichment quests, the teacher typically allocates to individual students or small groups.

---

## Important Business Rules

- Only students who belong to the quest's selected class can be allocated. If the teacher needs to allocate a student from a different class, they must change the quest's class — but only if no one has started the quest yet.
- A student cannot be allocated to the same quest twice. If the teacher tries to allocate a student who is already in the Allocated list, the system silently skips them.
- Once a student has started the quest, they cannot be removed from the Allocated list. The teacher sees a warning: "Student has already started this quest and cannot be unallocated."
- If the quest is deleted, all allocations are removed as well. Student attempt data is preserved independently but the allocation link is broken.
- The teacher cannot allocate students to a quest that is in Completed or Archived state.
- Bulk allocation by class only adds students who are not already allocated. Students already in the Allocated list are not duplicated.
- Allocation does not notify students automatically. The teacher should inform students separately that a quest is available for them.
- If a new student joins the class after the quest has been allocated, they are not automatically allocated. The teacher must manually add them through this tab.
- Removing an allocation while a student is actively taking the quest cancels their ongoing attempt. Their progress is lost and they cannot resume. If they have already submitted, their result is preserved.

---

## Deep Analysis

### Business Workflows & State Machines

**Allocation Lifecycle:**
```
STUDENT SELECTED ──→ ALLOCATED ──→ ATTEMPT STARTED ──→ SUBMITTED
       │                  │                                      │
       └── (skip if       │                              (allocation
        already allocated) │                               preserved)
                           │
                    REMOVED (only if no attempt started)
```

**Allocation Types (defined by `allocation_type` ENUM):**
| Type | Target Table | Example |
|------|-------------|---------|
| CLASS | `sch_classes` | Assign to entire class |
| SECTION | `sch_sections` | Assign to a specific section |
| GROUP | `sch_entity_groups` | Assign to a custom group |
| STUDENT | `std_students` | Assign to individual students |

The `target_table_name` + `target_id` pair forms a polymorphic reference. When displaying allocated students, the system resolves these references to actual student lists by querying the appropriate table.

**Locking Rules:**
| Quest Status | Can Allocate? | Can Remove? |
|-------------|---------------|-------------|
| DRAFT | Yes | Yes (students without attempts) |
| PENDING | Yes | Yes (students without attempts) |
| PUBLISHED | Yes | Yes (students without attempts) |
| ONGOING | No | No |
| COMPLETED | No | No |
| ARCHIVED | No | No |
| CANCELLED | No | No |

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Allocate student | Student must belong to quest's class | "Student is not in the selected class" |
| Allocate student | Student must not already be allocated | Silently skipped |
| Allocate by class | Only adds students not already allocated | "X new students allocated. Y students were already allocated." |
| Remove allocation | Student must not have started the quest | "Student has already started and cannot be unallocated" |
| Allocate to completed quest | Blocked per quest status | "Cannot allocate students to a completed quest" |

**Edge Cases:**
- If a student is transferred out of the class after allocation, their allocation remains but they appear with a "Transferred" badge.
- If the quest class is changed (only possible before any allocation), all existing allocations' class checks must be re-validated.
- Bulk allocation across sections: If a quest targets a class with 5 sections, "Allocate by Class" adds all students across all sections.
- An allocation record with `assigned_by = NULL` indicates system-generated allocation (e.g., from auto-remediation rules).

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| SchoolSetup | `sch_classes`, `sch_sections` | Polymorphic `target_id` | Class/section targeting |
| Student | `std_students` | Polymorphic `target_id` | Individual student targeting |
| User | `sys_users` | `assigned_by` | Who performed the allocation |
| Quest (self) | `lms_quests` | `quest_id` | Parent quest |

**Events to consider:**
- `StudentAllocated` — could trigger notification to student.
- `StudentUnallocated` — could trigger notification if student had started.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View allocations | Teacher, Admin | `tenant.lms.quest.view` |
| Allocate students individually | Teacher (own), Admin | `tenant.lms.quest.allocate` |
| Bulk allocate by class | Teacher (own), Admin | `tenant.lms.quest.allocateBulk` |
| Remove allocation | Teacher (own), Admin | `tenant.lms.quest.allocate` |
| View allocated student list | Teacher, Admin | `tenant.lms.quest.view` |

- Teachers can only allocate students for quests they created or that are assigned to their class.
