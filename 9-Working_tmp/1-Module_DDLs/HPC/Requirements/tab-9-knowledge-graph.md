# HPC Tab 9: Knowledge Graph Validation

This tab provides tools to validate the integrity of the syllabus knowledge graph — the relationships between topics, competencies, learning outcomes, and assessments. It detects issues such as topics missing competency mappings, outcomes not linked to topics, orphaned nodes with no connections, and topics lacking assessment weightage. It also manages topic equivalency across different syllabuses and tracks syllabus coverage progress.

---

## How It Works

The screen has three sections accessible via sub-tabs or a three-panel layout.

**Validation Issues:** This panel shows all detected issues in the knowledge graph. Each issue is displayed with the topic name, the type of issue (No Competency, No Outcome, No Weightage, Orphan Node), its severity level (Low, Medium, High, Critical), and the date it was detected. Users can mark issues as resolved once they have taken corrective action. Issues are auto-detected by the system when syllabus data is modified or when the user clicks "Run Validation." A summary count shows how many open issues exist at each severity level.

**Topic Equivalency:** This panel allows users to define equivalency relationships between topics from different syllabuses. For example, Topic "Photosynthesis" in CBSE Class 7 Science may be equivalent to Topic "Photosynthesis Process" in ICSE Class 7 Biology. The user selects a source topic and a target topic, then chooses the equivalency type — Full (topics are identical), Partial (topics overlap but are not identical), or Prerequisite (source must be learned before target). This is useful for schools that follow multiple syllabuses or for cross-reference during student transfers.

**Syllabus Coverage:** This panel shows a snapshot of syllabus coverage for each class-subject combination. The system records the coverage percentage and the snapshot date. Users can view historical snapshots to track coverage trends over time. New snapshots are typically generated when a teacher marks topics as completed in the syllabus planner.

---

## Important Business Rules

- Validation issues are auto-detected by the system. Manual creation of validation issues is not allowed.
- The same topic can have multiple validation issues simultaneously (e.g., both No Competency and No Outcome).
- When an issue is marked as resolved, the resolved_at timestamp is recorded and the is_resolved flag is set to 1.
- Topic equivalency must be unique per source-target pair. A reverse pair (B is equivalent to A) is considered a separate record.
- Equivalency types are: FULL (100% overlap), PARTIAL (some shared content), PREREQUISITE (source is a prerequisite for target).
- The source and target topic must be different. Self-referencing equivalency is not allowed.
- Syllabus coverage snapshots are historical records. Previous snapshots are never updated. Only the latest snapshot per class-subject-session is displayed by default.
- The coverage_percentage is calculated based on topics marked as completed versus total topics in the syllabus.
- Only users with Admin, Principal, or Curriculum Coordinator roles can access the validation and equivalency features. Teachers have view-only access to coverage snapshots.

---

## Database Columns & Behavior

### hpc_knowledge_graph_validation
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `topic_id` — FK to slb_topics. The topic with the validation issue. INT UNSIGNED NOT NULL.
- `issue_type` — Type of issue detected. ENUM('NO_COMPETENCY','NO_OUTCOME','NO_WEIGHTAGE','ORPHAN_NODE') NOT NULL.
- `severity` — Severity level. ENUM('LOW','MEDIUM','HIGH','CRITICAL'), default 'LOW'.
- `detected_at` — When the issue was detected. TIMESTAMP, default CURRENT_TIMESTAMP.
- `is_resolved` — Whether the issue has been resolved. TINYINT(1), default 0.
- `resolved_at` — When the issue was resolved. TIMESTAMP. NULL allowed.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

### hpc_topic_equivalency
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `source_topic_id` — FK to slb_topics. The source topic. INT UNSIGNED NOT NULL.
- `target_topic_id` — FK to slb_topics. The equivalent target topic. INT UNSIGNED NOT NULL.
- `equivalency_type` — Degree of equivalence. ENUM('FULL','PARTIAL','PREREQUISITE'), default 'FULL'.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

### hpc_syllabus_coverage_snapshot
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `academic_session_id` — FK to slb_academic_sessions. INT UNSIGNED NOT NULL.
- `class_id` — FK to sch_classes. INT UNSIGNED NOT NULL.
- `subject_id` — FK to slb_subjects. INT UNSIGNED NOT NULL.
- `coverage_percentage` — Percentage of syllabus covered. DECIMAL(5,2) NOT NULL.
- `snapshot_date` — Date the snapshot was recorded. DATE NOT NULL.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Validation-as-a-Service workflow:** Validation issues are auto-detected by scheduled jobs or triggered on-demand ("Run Validation"). The system scans all topics and detects missing competency mappings, missing outcomes, missing assessment weightages, and orphaned nodes. Manual creation is not allowed.
- **Issue resolution lifecycle:** Issues are auto-detected with `is_resolved = 0`. When a user resolves an issue (e.g., adds a missing competency mapping), they mark it as resolved. If the underlying data changes again, the system may re-detect the same issue on the next validation run.
- **Topic equivalency CRUD:** Users define equivalency relationships between topics from different syllabuses (e.g., CBSE → ICSE). Each relationship is directional — (A→B) is distinct from (B→A). The equivalency type (FULL, PARTIAL, PREREQUISITE) determines how the system treats the relationship in cross-syllabus reports.
- **Syllabus coverage snapshotting:** Coverage snapshots are historical records. Each snapshot captures the `coverage_percentage` at a point in time. Previous snapshots are never updated — only the latest snapshot per class-subject-session is displayed by default, but historical ones are available for trend analysis.

### Validation Rules & Edge Cases
- **Auto-detection scope:** The system validates all topics across all syllabuses. If a topic has no competency mapping, no outcome linked, and no assessment weightage, it will generate three separate issues — not one combined issue.
- **Same-topic multiple issues:** A single topic can have multiple simultaneous issues (e.g., NO_COMPETENCY + NO_OUTCOME). The UI should group or stack these per topic for clarity.
- **Equivalency self-reference guard:** Source and target topic must be different. The system should reject `source_topic_id = target_topic_id` at the application level (no DB constraint for this, so it must be application-enforced).
- **Equivalency directionality:** A→B FULL and B→A FULL are both allowed as separate records. The UI should check if the reverse relationship already exists before allowing creation.
- **Coverage snapshot immutability:** Once recorded, a snapshot cannot be edited or deleted. Only new snapshots can be created. This is critical for audit trail integrity.
- **Severity classification:** Each detected issue is assigned a severity (LOW, MEDIUM, HIGH, CRITICAL). The system must have a deterministic rule for severity assignment — e.g., NO_COMPETENCY = HIGH, ORPHAN_NODE = CRITICAL.

### Integration Points
- **`slb_topics`** — Central entity. Validation checks against topics and their relationships to competencies, outcomes, and assessments.
- **`slb_competencies`** — Topic-to-competency mappings are checked during validation. If no mapping exists → NO_COMPETENCY issue.
- **`hpc_learning_outcomes`** (Tab 3) — Topic-to-outcome mappings are checked. If no outcome is linked → NO_OUTCOME issue.
- **`hpc_outcome_question_jnt`** — If an outcome has questions but no weightage → NO_WEIGHTAGE issue on the topic.
- **`hpc_syllabus_coverage_snapshot`** — Coverage data is consumed in the third panel. The same table is also used in Tab 1 Dashboard.
- **External syllabus modules** — The equivalency feature depends on multiple syllabus definitions (CBSE, ICSE, etc.) existing in `slb_topics`.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Curriculum Coordinator | Admin |
|---|---|---|---|---|---|
| View validation issues | ❌ | ❌ | ✅ | ✅ | ✅ |
| Run validation | ❌ | ❌ | ✅ | ✅ | ✅ |
| Mark issue resolved | ❌ | ❌ | ✅ | ✅ | ✅ |
| View topic equivalencies | ❌ | ❌ | ✅ | ✅ | ✅ |
| Create/edit equivalency | ❌ | ❌ | ❌ | ✅ | ✅ |
| View coverage snapshots | ✅ | ✅ | ✅ | ✅ | ✅ |
| Generate coverage snapshot | ❌ | ❌ | ✅ | ✅ | ✅ |
| Access historical snapshots | ❌ | ❌ | ✅ | ✅ | ✅ |
