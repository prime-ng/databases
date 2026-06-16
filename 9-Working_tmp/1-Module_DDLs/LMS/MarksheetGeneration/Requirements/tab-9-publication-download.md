# MarksheetGeneration Tab 9: Publication & PDF Download

This tab handles the final stages of the marksheet lifecycle — reviewing the computed results, publishing them to make them visible to students and parents, locking them to prevent further changes, and generating PDF marksheets for printing or digital distribution. The publication workflow ensures that results go through proper approval before being released.

---

## How It Works

**Publication Lifecycle (SC-MSG-14):** After computation and review, the admin or principal can publish the schedule. Publishing changes the status from Reviewed to Published and makes the marksheet visible on the Student and Parent Portals. Once published, the schedule can optionally be locked, which prevents any further changes. If errors are discovered after publication, an authorized admin can unlock the schedule by providing a mandatory written reason. Unlocking reverts the status to Computed, allowing corrections and recomputation.

**Individual Marksheet Preview (SC-MSG-13):** Before or after publication, any teacher or admin can view a full student marksheet that matches the PDF layout exactly. The preview shows all sections — the scholastic subject-exam matrix with per-exam scores and totals, the IA marks breakdown, the co-scholastic grades, the attendance summary, rank in class-section, overall grade, division, and promotion status. The preview is a faithful representation of what the PDF will look like.

**PDF Generation (SC-MSG-15):** Individual marksheet PDFs can be downloaded for any student. Bulk download generates a ZIP file containing all student marksheets for a selected class-section. The PDF is generated using DomPDF with inline CSS styling and a table-based layout. Each marksheet includes the school logo (embedded as base64), school name and address, board affiliation, student details, the full result matrix, co-scholastic section, attendance, signatures, and the date of issue. Bulk downloads are queued for larger class-sections to avoid timeouts.

---

## Important Business Rules

- Only schedules in Reviewed or Computed status can be published. A Computed schedule must first be marked as Reviewed before publication.
- Once a schedule is Published, all result data becomes read-only. No marks or grades can be edited.
- Locking is a stronger state than Published. Locked schedules cannot be unlocked by standard admins — only by the principal or super admin.
- Unlocking requires a mandatory reason (minimum 10 characters). The reason, user, and timestamp are recorded in the computation log.
- PDF download is available for any schedule that is at least in Computed status, not just Published schedules.
- Bulk PDF generation for more than 30 students is processed asynchronously with progress notification.
- School logo is stored in the school settings table and embedded directly into the PDF — no external URL references.
- Each marksheet PDF includes a placeholder area for the principal's signature. Digital signatures are not supported in Phase 1.

---

## Database Columns & Behavior

### msh_marksheet_schedules (publication fields)
- `status_id` — FK to sys_dropdowns. DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED.
- `is_locked` — Lock flag. TINYINT(1), default 0.
- `locked_at` — DATETIME, nullable.
- `locked_by` — FK to sys_users. INT UNSIGNED, nullable.
- `unlock_reason` — Mandatory text when unlocking. TEXT, nullable.
- `unlocked_at` — DATETIME, nullable.
- `unlocked_by` — FK to sys_users. INT UNSIGNED, nullable.

### msh_student_results (used in marksheet PDF)
- All aggregate columns: grand_total, grand_max, overall_percentage, overall_grade, division, rank_in_section, rank_in_class, total_subjects, subjects_passed, subjects_failed, promotion_status, result_status.

### msh_student_subject_results (used in marksheet PDF)
- All component breakdown columns: exam_weighted_total, theory_marks, practical_marks, homework_score, quiz_score, quest_score, ia_total, subject_total, subject_max, subject_percentage, subject_grade, is_passed.

### msh_student_subject_exam_marks (used in marksheet PDF — the exam matrix)
- `marks_obtained` — Per-exam score. DECIMAL(8,2), nullable.
- `max_marks` — Per-exam max. DECIMAL(8,2), nullable.
- `result_status` — PASS, FAIL, ABSENT, WITHHELD. VARCHAR(20), nullable.

### msh_student_ia_marks (used in marksheet PDF)
- `marks_obtained` — Per IA component. DECIMAL(5,2), nullable.
- `max_marks` — DECIMAL(5,2).

### msh_student_coscholastic_results (used in marksheet PDF)
- `grade` — Grade letter per area. VARCHAR(10), nullable.
- `is_auto_from_ba` — Indicates if auto-populated. TINYINT(1), default 0.

### msh_student_attendance (used in marksheet PDF)
- `total_working_days` — SMALLINT UNSIGNED, nullable.
- `days_present` — SMALLINT UNSIGNED, nullable.

---

## Deep Analysis

### Business Workflows & State Machines
Publication follows a strict sequential state machine: **Computed → Reviewed → Published → Locked**.
- **Reviewed → Published**: Admin or principal clicks "Publish". Schedule status changes to PUBLISHED; results become visible on Student/Parent Portals; all entries become read-only.
- **Published → Locked**: Optional stronger state. Only principal or super admin can lock. Once locked, PDF watermarks may indicate "LOCKED".
- **Locked → Computed** (Unlock): Requires mandatory reason (min 10 chars). Reverts status to COMPUTED, allowing marks re-entry and recomputation. The unlock event is logged.

PDF generation is available once status ≥ Computed. Individual downloads are synchronous; bulk (>30 students) is queued asynchronously with progress notification.

### Validation Rules & Edge Cases
- Publication requires schedule status = COMPUTED or REVIEWED. If COMPUTED, the system should prompt the admin to mark it as Reviewed first (or auto-transition).
- Once PUBLISHED, all result tables (`msh_student_results`, `msh_student_subject_results`, `msh_student_subject_exam_marks`, `msh_student_ia_marks`, `msh_student_coscholastic_results`, `msh_student_attendance`) are read-only. Enforce at application layer.
- Lock is irreversible by standard admins. Only principal/super admin can unlock.
- Unlock reason: min 10 chars, stored in `unlock_reason` and also logged in `msh_computation_logs.remarks`.
- PDF: School logo embedded as base64 (no external URL). Missing logo should not block PDF generation — show placeholder.
- DOM PDF table-based layout must handle page breaks cleanly for students with many subjects (up to 10-12).
- Bulk ZIP download for >30 students runs as queued job. User receives notification when ready.
- Principal's signature is a static placeholder image in Phase 1 — no digital signature support.

### Integration Points
- **msh_marksheet_schedules**: Core status management and lock/unlock fields.
- **msh_student_results**, **msh_student_subject_results**, **msh_student_subject_exam_marks**: PDF data sources.
- **msh_student_ia_marks**, **msh_student_coscholastic_results**: IA and co-scholastic sections.
- **msh_student_attendance**: Attendance section on PDF.
- **School settings**: School name, address, board affiliation, logo (base64).
- **Student/Parent Portal**: Visibility gating — only PUBLISHED schedules are shown.
- **sys_users**: Locker, unlocker, publication triggerer.

### Permissions Matrix
| Role | Publish | Lock | Unlock | View Preview | Download Single PDF | Download Bulk ZIP |
|---|---|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes | Yes | Yes |
| Principal | Yes | Yes | Yes | Yes | Yes | Yes |
| Coordinator | Yes | No | No | Yes | Yes | Yes |
| Class Teacher | No | No | No | Own class-section | Own class-section | Own class-section |
| Subject Teacher | No | No | No | Own subject | Own subject | No |
| Student/Parent | No | No | No | Yes (published only) | Yes (self only) | No |
