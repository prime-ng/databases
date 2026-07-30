# Promotion Batches — Business Requirements

## What This Screen Does

The Promotion Batches screen manages year-end student promotion from one class to the next academic session's class. A promotion batch defines a from-class → to-class mapping across academic sessions, tracks per-student promotion decisions (Promoted, Detained, Transferred, Alumni, Left), and confirms the batch to atomically write StudentAcademicSession records for the new session.

This is the first tab (`?tab=batches`) of the Promotions & Alumni page at `/admission/promotions-alumni`.

## When This Screen Is Used

- **Year-End Promotion**: Creating batches to promote students to the next class
- **Batch Management**: Adding/removing students from promotion batches
- **Promotion Decision**: Marking each student as Promoted, Detained, Transferred, Alumni, or Left
- **Batch Confirmation**: Committing promotion decisions and writing academic session records

## Key Fields

**Batch Configuration**
- From Session, To Session — academic sessions
- From Class, To Class — source and destination classes
- Criteria JSON — pass criteria configuration

**Batch Counts**
- Total Students, Promoted Count, Detained Count — auto-calculated

**Status**
- Draft (default) — editable, deletable
- Confirmed — frozen, commits academic session records

**Per-Student Record**
- Student, From Class Section, To Class Section
- New Roll Number
- Result: Promoted, Detained, Transferred, Alumni, Left
- Remarks

## Business Rules

**Draft-Only Editing:** Edit, update, and delete are only allowed when batch status is Draft. Confirmed batches are immutable for changes (but confirm is idempotent).

**Confirm Idempotency:** The `confirmBatch()` method uses `firstOrCreate` when writing StudentAcademicSession records, making re-confirmation safe. Already-confirmed batches skip re-processing without error.

**Cancel Operation:** Cancelling a batch (only in Draft) deletes the batch header and all its promotion records. This is a hard operation (not soft-delete).

**AJAX Record Management:** Per-student records are managed entirely via AJAX on the show page: create, update, delete, and toggle active status. The `upsertRecord()` method auto-resolves the student's current `from_class_section_id` from their active academic session, simplifying data entry.

**Auto-Status Counts:** The `updateBatchStats()` method recalculates `total_students`, `promoted_count`, and `detained_count` after any record change. Promoted = count of records with result=Promoted, Detained = count with result=Detained.

**Confirmation Effect:** When a batch is confirmed, the `PromotionService::confirmBatch()` iterates all records and creates/updates `StudentAcademicSession` entries linking each student to their new class section (`to_class_section_id`) for the destination session (`to_session_id`).

## Workflow

1. Admin creates a promotion batch (from_session, to_session, from_class, to_class)
2. System defaults status to Draft
3. Admin adds per-student promotion records (one per student being promoted)
4. Each record specifies the result (Promoted/Detained/Transferred/Alumni/Left) and target section
5. Admin reviews the batch summary on the show page
6. Admin confirms the batch — system writes StudentAcademicSession records atomically
7. Confirmed batch shows frozen counts; no further edits allowed

## Related Screens

- **Alumni Tab** — Lists students with result=Alumni from confirmed batches
- **TCs Tab** — Issue Transfer Certificates to alumni students
- **Academic Sessions** — Source and destination sessions for promotion

## Requirements

- MUST display paginated batches list with search, totals, and status badges
- MUST authorize via `tenant.adm-promotion.*` policy gates
- MUST validate store with 6 rules (sessions, classes, criteria)
- MUST default status=Draft on create
- MUST restrict edit/update/delete to Draft-only
- MUST support AJAX CRUD for promotion records (store, update, destroy, toggle)
- MUST auto-resolve from_class_section_id from current academic session
- MUST auto-recalculate batch counts after record changes
- MUST confirm batches via PromotionService::confirmBatch() — idempotent
- MUST write StudentAcademicSession records on confirm
- MUST support cancel of Draft batches (hard delete batch + records)
- MUST support soft-delete lifecycle with restore/force-delete
- MUST restrict soft-delete to Draft batches only
- MUST log all operations via activityLog()
