# Quiz Tab 3: Assessment Types

This tab lets teachers define the different kinds of quizzes they can create. Standard types include Practice, Challenge, Revision, Remedial, Formative, Summative, Unit Test, Weekly, Monthly, Mock Test, and Pre-Board. Teachers can also create custom types.

---

## How It Works

Each assessment type has a name — what everyone sees — and a code, which is a short identifier the system uses behind the scenes. Both the name and the code must be unique.

The type determines how the quiz behaves in some important ways. For example, when a student fails a quiz, the system checks the assessment type's code to decide whether to automatically generate a remedial quiz. If the code is FORMATIVE, DIAGNOSTIC, UNIT_TEST, or REVISION, a remedial quiz is created. If the code is SUMMATIVE or MOCK_TEST, it is not. The code REMEDIAL is reserved — only the system can create quizzes of this type; teachers cannot manually create remedial quizzes.

When a teacher creates a new quiz, they pick an assessment type from the dropdown. Once they save the quiz, the type becomes locked and cannot be changed. This is because changing the type after the quiz is created could change its behavior in unexpected ways — a formative quiz that already has student attempts should not suddenly become a summative quiz.

---

## Important Business Rules

- If a teacher tries to delete an assessment type that is being used by any quiz, the deletion is blocked. The system shows "Cannot delete. This assessment type is used by X quizzes." The teacher must first change those quizzes to a different type.
- Making an assessment type inactive hides it from the dropdown when creating new quizzes. Existing quizzes that use this type are unaffected — they keep working normally.
- Changing a type's name updates the name everywhere — on existing quizzes and in dropdowns. Changing a type's code affects the system's behavior rules (like remedial generation), so this should be done carefully. For example, if the code is changed from "FORMATIVE" to "FORM" and the system checks for "FORMATIVE" at runtime, the behavioral link would break.
- The system recognizes specific codes for specific behaviors. If a custom type is created with one of these recognized codes, it inherits the corresponding behavior. For example, creating a type with code "PRACTICE" would give it default Practice behavior.
- The REMEDIAL code is reserved and cannot be assigned to any teacher-created type. Only the system can create quizzes with this code.
- An assessment type can be hard-deleted only if no quizzes reference it. Otherwise, it must be soft-deleted by setting it to inactive.
- The assessment type name is shown to students when they view their quizzes. The code is internal only and not exposed to students.
- There is no limit on the number of assessment types a school can create, but the dropdown sorts them alphabetically by name for easy navigation.

---

## Deep Analysis

### Business Workflows & State Machines

**State Machine for Assessment Type Lifecycle:**

| Current State | Transition | Trigger | Next State | Conditions |
|---|---|---|---|---|
| Active | Create | Teacher fills form & saves | Active | Name and code must be unique |
| Active | Edit Name | Teacher changes name | Active | Name updated everywhere |
| Active | Edit Code | Teacher changes code | Active | Behavioral logic may break if runtime checks use old code |
| Active | Deactivate | Teacher sets `is_active = 0` | Inactive | Hidden from new quiz dropdowns; existing quizzes unaffected |
| Inactive | Reactivate | Teacher sets `is_active = 1` | Active | Reappears in dropdowns |
| Active | Hard Delete | Teacher deletes | Deleted | **Blocked** if referenced by any quiz |
| Active | Soft Delete | Teacher deactivates | Inactive | Allowed regardless of references |
| Active | Create Quiz with Type | Teacher picks type in Tab 4 | — | Type locked after quiz is saved |

**Behavioral Code Mapping (system-recognized codes):**

| Code | Behavior |
|---|---|
| `PRACTICE` | Default practice behavior; no remedial auto-generation |
| `FORMATIVE` | Triggers remedial quiz generation on failure |
| `DIAGNOSTIC` | Triggers remedial quiz generation on failure |
| `UNIT_TEST` | Triggers remedial quiz generation on failure |
| `REVISION` | Triggers remedial quiz generation on failure |
| `SUMMATIVE` | No remedial auto-generation |
| `MOCK_TEST` | No remedial auto-generation |
| `REMEDIAL` | Reserved — system-only; teachers cannot create quizzes with this type |
| `CHALLENGE` | Standard behavior; no special triggers |
| `ENRICHMENT` | Standard behavior; no special triggers |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Name | Must be unique across all types | "An assessment type with this name already exists." |
| Code | Must be unique across all types | "An assessment type with this code already exists." |
| Code – Reserved | `REMEDIAL` cannot be assigned by teachers | "The code REMEDIAL is reserved and cannot be used." |
| Delete Type | Must not be referenced by any quiz | "Cannot delete. This assessment type is used by X quizzes." |
| Deactivate Type | Always allowed | No error; type hidden from dropdowns |
| Edit Code | Allowed but risky | No validation error; system warns about behavioral impact |
| Edit Name | Always allowed | Changes propagate to all existing quizzes and dropdowns |
| Code – System Reserved Codes | Custom type with same code inherits behavior | No error — intentional design |
| Type Locked on Quiz | Cannot change after quiz saved | "Assessment type cannot be changed after the quiz is saved." |
| Limit on Types | No limit | No error |
| Sort Order | Dropdown sorted alphabetically | No error |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | `quiz_type_id` → `lms_assessment_types.id` | Links each quiz to its assessment type |
| Question Usage | `qns_question_usage_type` | `assessment_usage_type_id` → `qns_question_usage_type.id` | Determines which question bank usage this type maps to |
| Remedial Quiz Logic | `lms_quizzes` (system-generated) | Checks `lms_assessment_types.code` at runtime | Determines whether a failed quiz triggers remedial generation |
| Student Portal | `lms_quizzes` | — | Type name displayed to students; code internal only |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Types | Teacher | `quiz.assessment-types.view` |
| Create Type | Teacher | `quiz.assessment-types.create` |
| Edit Type | Teacher | `quiz.assessment-types.edit` |
| Deactivate/Reactivate Type | Teacher | `quiz.assessment-types.toggle-active` |
| Delete Type | Teacher | `quiz.assessment-types.delete` |
| View All Types | Admin | `quiz.assessment-types.view.all` |

---

## Database Columns & Behavior

### Table: `lms_assessment_types`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `code` | VARCHAR(20) | No | No | — | Unique system code (e.g. CHALLENGE, PRACTICE, REMEDIAL); `REMEDIAL` is reserved |
| `name` | VARCHAR(100) | No | No | — | Display name shown to teachers and students |
| `assessment_usage_type_id` | INT UNSIGNED | Yes → `qns_question_usage_type.id` | No | — | Links to question usage type (QUIZ, EXAM, etc.) |
| `description` | VARCHAR(255) | No | Yes | NULL | Optional description |
| `is_active` | TINYINT(1) | No | No | 1 | If 0, hidden from new quiz dropdowns |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |
