# Topic-Competency Mapping — Business Requirements

## What This Screen Does

The Topic-Competency Mapping screen is the critical junction where the school's Content intersects with its Goals. 

It allows Subject Matter Experts to declare exactly which skills a specific topic is intended to develop in the student. By creating this link, the system can automatically generate outcome-based reports, showing that when a student completes a specific topic, they have inherently progressed towards achieving a specific competency. This shifts the educational focus from simply finishing the syllabus to acquiring the mandated skills.

---

## When This Screen Is Used

- Post-Setup Alignment after Topics and Competencies have been independently defined, teachers or HODs use this screen to map them together
- Compliance Auditing when preparing a justification report for external boards, proving how textbook chapters map to mandated National Curriculum outcomes
- Assessment Blueprinting when the Exam Module needs to know which questions to pull from the bank to test a specific competency

## Default Data Load

This screen displays within the Syllabus Master tab group. When the user navigates to Syllabus → Master, SyllabusController@master() loads all master tab data simultaneously (Lessons, Topics, Competencies, etc.), each independently paginated at 10 rows per page. Shared dropdowns (Class, Section, Subject, Academic Session, Book) are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Relational Linking**
A Topic Selection field identifies the specific teaching unit being mapped, such as "Balancing Chemical Equations". A Competency Selection field identifies the target skill being developed, such as "Analytical Thinking".

**Weightage and Importance**
A Percentage Weightage field captures a numeric value representing how much this specific topic contributes to the mastery of the overall competency. If a topic is heavily focused on a skill, it might carry an 80% weightage. A Primary Focus Toggle acts as a switch indicating importance. A topic can be mapped to many different competencies, but the system forces the user to designate exactly one as the primary focus of the lesson.

---

## Business Rules and Conditions

**Many-to-Many Architecture**
The architecture supports complex, multi-directional mapping. A single science experiment topic can map to Scientific Knowledge, Lab Safety, and Using Instruments simultaneously. Conversely, a single competency like Critical Thinking might be mapped to 50 different topics across the academic year.

**Primary Competency Validation**
While a user can attach multiple competencies to a single topic, the system must enforce a strict rule where only one mapping per topic can be marked as the Primary focus. If the user attempts to set a second competency as primary, the system must either throw an error or automatically downgrade the previous primary competency to secondary.

**Unique Mapping Constraint**
The system ensures that a user cannot map the exact same skill to the exact same topic twice.

**Deletion Rules**
If either the Topic or the Competency is permanently deleted from their respective master screens, this mapping link is automatically destroyed by the system to prevent broken references in reports.

---

## Workflow Steps

**Mapping a Topic to Competencies**
The Science Teacher navigates to the Competency Mapping tab within the Syllabus Master. They select their Lesson and drill down to the Topic "Refraction of Light through a Prism". A selection window opens, displaying all available Competencies. The teacher selects three competencies: Understanding Concepts, Diagrammatic Representation, and Applying Laws of Physics. They set Understanding Concepts as the Primary Competency. They assign weightages: 50% for Understanding, 30% for Diagrammatic, and 20% for Applying. Upon hitting Save, the system validates the unique rules and the single-primary rule, then saves the mapping.

---

## Example Scenario

At the end of the first term, the Principal generates the Coverage Audit Report for Class 10. The school board requires that 15% of the entire term's teaching must focus on Environmental Awareness, a mandated competency.

The system checks the mapping table. It finds that out of 200 topics taught so far, 35 topics across Science, English, and Social Studies were mapped to the Environmental Awareness competency. By calculating the weightage of those topics against the weightage assigned in the mapping table, the system proves to the board that 18% of the curriculum successfully addressed this competency, passing the audit seamlessly.

---

## Related Screens

- **Topics Master** — The source of the content being mapped
- **Competencies Master** — The source of the skills being targeted
- **Coverage Audit Report** — The analytics engine that consumes this mapping data to generate radar charts and compliance PDFs

---

## Requirements

- Controller `TopicCompetencyController`; `index()` is loaded via Syllabus tab; `Gate::authorize('tenant.topic-competency.viewAny')` is enforced
- Route: `syllabus.master.index` with tab parameter `topic_competency`
- `store()` gates `tenant.topic-competency.create`, accepts bulk format: `topic_ids` (array) + `competencies` (array of `{competency_id, weightage, is_primary}`)
- `store()` validates FK existence, skips duplicate mappings (`where('topic_id', $topicId)->where('competency_id', $competencyId)->exists()`), enforces one primary per topic via `$primaryInserted` flag
- `destroy()` gates `tenant.topic-competency.delete`, logs "Deleted" then calls `$entry->delete()` (soft delete)
- `update()` supports both individual fields (form) and bulk (AJAX) format
- `restore()` gates, finds `onlyTrashed()`, calls `$entry->restore()`, logs "Restored"
- `forceDelete()` gates, finds `onlyTrashed()`, calls `$entry->forceDelete()`, logs "Force Deleted"
- `toggleStatus($id)` AJAX: toggles `is_active`
- `prepareForValidation()` normalizes `topic_ids` to unique integer array, normalizes `competencies` array with type casting
- Soft deletes enabled; pagination: 10 per page
- Activity logged: Stored, Updated, Restored, Deleted, Force Deleted, Toggle Status
- Policy: `TopicCompetencyPolicy` (`tenant.topic-competency.*`)

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.topic-competency.viewAny` | `index()` | Page load |
| `tenant.topic-competency.view` | `show()` | View single |
| `tenant.topic-competency.create` | `create()`, `store()` | Create |
| `tenant.topic-competency.update` | `edit()`, `update()`, `toggleStatus()` | Edit / toggle |
| `tenant.topic-competency.delete` | `destroy()` | Soft delete |
| `tenant.topic-competency.restore` | `restore()`, `trashed()` | Restore |
| `tenant.topic-competency.forceDelete` | `forceDelete()` | Permanent delete |
| Policy: `TopicCompetencyPolicy` | Single policy | Uses `tenant.topic-competency.*` |

## Logic Flow

1. **Page Load** — Screen loads via Master tab; Gates, eager-loads `topic` and `competency` relations, paginates 10 per page.
2. **Create** — `create()` gates, loads active `Topic` and `Competencie` lists for dropdowns. POST to `store()` accepts bulk format. `prepareForValidation()` normalizes input. `store()` validates FKs, iterates each `topic_id` × each `competency`, skips duplicates, enforces single primary per topic via boolean `$primaryInserted` flag. Returns JSON `{success, message, redirect}`.
3. **Edit** — `edit()` gates, loads record + topics + competencies. POST to `update()` supports both individual fields (`topic_id`, `competency_id`, `weightage`, `is_primary`) and AJAX bulk (`topic_ids[]`, `competencies[]`). Logs "Updated". Returns JSON or redirect.
4. **View** — `show()` gates, eager-loads `topic.lesson`, `topic.class`, `topic.subject`, `competency`. Also queries all topics under same competency for statistics.
5. **Delete** — `destroy()` gates, finds record, logs "Deleted", calls `$entry->delete()` (soft delete). Redirects.
6. **Restore** — `restore()` finds `onlyTrashed()`, calls `restore()`, logs "Restored".
7. **Force Delete** — `forceDelete()` finds `onlyTrashed()`, calls `forceDelete()`, logs "Force Deleted".
8. **Status Toggle** — `toggleStatus()` inverts `is_active`, saves, logs "Toggle Status".

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `topic_ids` | `required, array, min:1` | "Please select at least one topic." |
| `topic_ids.*` | `integer, exists:slb_topics,id` | "One or more selected topics are invalid." |
| `competencies` | `required, array, min:1` | "Please select at least one competency." |
| `competencies.*.competency_id` | `required, integer, exists:slb_competencies,id` | "Competency is required." / "Selected competency does not exist." |
| `competencies.*.weightage` | `nullable, numeric, min:0, max:100` | "Weightage must be numeric." / "Weightage cannot exceed 100%." |
| `competencies.*.is_primary` | `boolean` | — |
| **Duplicate (business)** | Controller checks `TopicCompetency::where(topic_id, competency_id)->exists()` | Skips silently, not an error |
| **Single primary (business)** | Controller `$primaryInserted` flag | Only first `is_primary=1` per topic set; subsequent ignored |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| No topic selected | "Please select at least one topic." | Validation |
| Invalid topic ID | "One or more selected topics are invalid." | Validation |
| No competency selected | "Please select at least one competency." | Validation |
| Invalid competency ID | "Selected competency does not exist." | Validation |
| Weightage > 100 | "Weightage cannot exceed 100%." | Validation |
| Non-numeric weightage | "Weightage must be numeric." | Validation |
| Store exception | "Failed to save mappings." + error details | Controller 500 JSON |

## Success Scenarios

**SC-001 — Creating Mappings for Multiple Topics**
User posts `topic_ids=[1,2]`, `competencies=[{competency_id:5, weightage:50, is_primary:1}, {competency_id:7, weightage:30}]`. `store()` creates 4 junction records (2 topics × 2 competencies), enforces single primary per topic. Returns JSON success.

**SC-002 — Bulk Store Skips Duplicates**
Same mapping already exists for topic_id=1 + competency_id=5. `store()` detects via `exists()` check, skips silently, creates only non-duplicate records.

**SC-003 — Updating a Mapping Weightage**
User updates mapping record via `update()`. Logs "Updated". Returns success.

## Failure Scenarios

**FC-001 — No Topic Selected**
User submits with empty `topic_ids`. Validation: `topic_ids.required` fails with "Please select at least one topic."

**FC-002 — Invalid Competency Reference**
User submits `competency_id` that does not exist. Validation: `competencies.*.competency_id.exists` fails with "Selected competency does not exist."

**FC-003 — Store Transaction Failure**
Database error during bulk insert. `DB::rollBack()` in catch block, returns 500 JSON "Failed to save mappings." with error details.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `slb_topics` | FK Table | `topic_id` → `id` ON DELETE CASCADE |
| `slb_competencies` | FK Table | `competency_id` → `id` ON DELETE CASCADE |
| Activity Log | Consumer | `activityLog()` on CRUD + toggle |

**Table:** `slb_topic_competency_jnt`

| Column | Type | Details |
|--------|------|---------|
| id | BIGINT PK | Auto-increment |
| topic_id | BIGINT FK | → `slb_topics.id` ON DELETE CASCADE |
| competency_id | BIGINT FK | → `slb_competencies.id` ON DELETE CASCADE |
| weightage | DECIMAL(5,2) | Contribution percentage (0–100) |
| is_primary | TINYINT(1) | Primary focus flag (one per topic) |
| is_active | TINYINT(1) | Soft-delete flag |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP | Soft deletes |
| UNIQUE | (topic_id, competency_id) | Prevents duplicate mappings |
