# Quest Tab 3: Quest Scopes

This tab manages the scope types that define how quest questions are organized and categorized. While the later question selection tab deals with individual questions, this tab defines the structural categories — the containers — that those questions will be grouped into.

---

## How It Works

When the teacher opens this tab, they first select a quest from a dropdown. Below that, they see a list of scope types that have been created for that quest. Each scope type has a name and a status — Active or Inactive.

To create a new scope, the teacher clicks "Add Scope" and enters a name for the scope type. A scope type is a label that groups related content together. For example, in a quest about Indian History, the teacher might create scope types like "Ancient India," "Medieval India," "Colonial Period," and "Independent India." Or for a science quest, they might create "Mechanics," "Thermodynamics," "Optics," and "Electromagnetism." The name is entirely up to the teacher and their curriculum structure.

Each scope type has its own status toggle. If a scope is set to Inactive, it is hidden from the question selection interface and cannot have questions assigned to it. This is useful if the teacher created a scope type but later decided not to use it — they can deactivate it instead of deleting it.

The teacher can also reorder scope types by dragging them up or down. This order determines how the scope types appear throughout the rest of the module.

---

## Important Business Rules

- Scope types are specific to each quest. Creating a scope type in one quest does not make it available in any other quest. Each quest has its own independent set of scope types.
- A scope type cannot be deleted if it already has questions assigned to it. The teacher must first remove or reassign those questions before deleting the scope. However, they can simply set the scope to Inactive, which hides it while preserving the questions underneath.
- There is no limit on how many scope types a quest can have, but the interface keeps them organized with drag-and-drop ordering.
- Once any student has started the quest, scope types become locked. The teacher cannot add, delete, rename, or reorder scope types at that point.
- Setting a scope to Inactive does not delete the questions under it — it only hides them from the student's view. If the scope is reactivated later, the questions become visible again.
- A quest must have at least one scope type defined before questions can be added. If no scope types exist, the Add Questions interface in the next tab will be unavailable.
- The display order of scope types (set by drag-and-drop) determines how they appear in the student's quest interface and in reports.

---

## Deep Analysis

### Business Workflows & State Machines

**Scope Lifecycle:**
```
ACTIVE ←──→ INACTIVE
  │
  └── (locked once student attempts exist)
```

- Scope types are created in ACTIVE status.
- A scope can be toggled to INACTIVE at any time before student attempts exist.
- After any student starts the quest, scopes are locked — no add, delete, rename, reorder, or activate/deactivate.
- Deleting a scope requires zero questions assigned to it. The system checks `lms_quest_questions` for the quest before allowing deletion.

**State Machine for Scope Mutability:**
| Quest Status | Scopes Mutable? | Constraints |
|-------------|----------------|-------------|
| DRAFT | Yes | Full CRUD + reorder |
| PENDING | Yes | Full CRUD + reorder |
| PUBLISHED (no attempts) | Yes | Full CRUD + reorder |
| PUBLISHED (with attempts) | No | All scope operations blocked |
| ONGOING | No | All scope operations blocked |
| COMPLETED | No | All scope operations blocked |
| ARCHIVED | No | All scope operations blocked |

### Validation Rules & Edge Cases

| Field/Operation | Rule | Error Message |
|----------------|------|---------------|
| Scope name | Required, max 255 chars, unique within the quest | "Scope name is required and must be unique within this quest" |
| Add scope | Quest must exist and not be in locked state | "Cannot modify scopes while quest is in progress" |
| Delete scope | Zero questions assigned to this scope | "Remove all questions from this scope before deleting" |
| Reorder scope | Quest not in locked state | "Cannot reorder scopes once students have started" |
| Scope count | At least 1 scope required to add questions | "Create at least one scope type before adding questions" |

**Edge Cases:**
- If the last active scope is set to INACTIVE and no scopes remain active, the "Add Questions" interface hides and a message shows: "Activate at least one scope type to add questions."
- If a scope is set to INACTIVE after questions have been assigned, those questions are hidden from students but preserved in the database. Reactivating restores visibility.
- Scope order persists across page reloads via the `ordinal` value saved on drag-and-drop.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Syllabus | `slb_lessons`, `slb_topics` | `lesson_id`, `topic_id` | Curriculum-based scope definition |
| QuestionBank | `qns_question_types` | `question_type_id` (nullable) | Optional question-type filter per scope |
| Quest (self) | `lms_quests` | `quest_id` | Parent quest reference |

**Events/Listeners:** None (scope operations are synchronous DB transactions).

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View scopes | Teacher, Admin | `tenant.lms.quest.view` |
| Create scope | Teacher (own quest), Admin | `tenant.lms.quest.update` |
| Edit scope name | Teacher (own quest), Admin | `tenant.lms.quest.update` |
| Reorder scopes | Teacher (own quest), Admin | `tenant.lms.quest.update` |
| Toggle active/inactive | Teacher (own quest), Admin | `tenant.lms.quest.update` |
| Delete scope | Teacher (own quest), Admin | `tenant.lms.quest.update` |

- All scope operations are tied to the quest `update` permission, not separate scope permissions.
- Teachers can only modify scopes on quests they created.
