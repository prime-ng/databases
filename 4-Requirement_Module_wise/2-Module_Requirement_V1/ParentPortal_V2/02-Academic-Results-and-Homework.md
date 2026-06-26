# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 02: Academic Results, Learning & Homework

---

## 1. Executive Summary
Parents need to monitor their child's academic progress. This feature exposes data from the `Hpc` (Holistic Progress Card), `LmsHomework`, and `ParentLearningController` modules in a read-only format.

## 2. Core Components
- `ParentResultController.php`
- `ParentHomeworkController.php`
- `ParentLearningController.php`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Homework Tracking (`ParentHomeworkController`)
- **Tabs:** Categorizes homework into 5 buckets client-side for fast switching: `Pending`, `Overdue`, `Submitted`, `Graded`, `All`.
- **View Logic:** Shows assignments where `is_released = true` and `is_active = true`.
- **Attachments:** Fetches attached media (PDFs, Images) using Spatie Media Library via `getMedia('homework_files')`.
- **Grading Visibility:** Once the teacher grades the submission, the parent can see the `marks_obtained` and teacher remarks.

### FR-02: Report Cards (`ParentResultController`)
- Fetches official report cards from the `MarksheetGeneration` / `Hpc` module.
- **Condition:** Only shows records where `status = 'Published'`. Draft or In-Review marksheets remain hidden.
- **PDF Export:** Integrates with the `Template` engine to allow parents to download the exact replica of the printed marksheet in PDF format.

### FR-03: Learning Resources (`ParentLearningController`)
- Provides access to study materials, syllabus copies, and video links shared by the subject teachers.

---

## 4. Acceptance Criteria
- **Given** a teacher assigns Math homework due on Friday, **When** I log into the portal on Wednesday, **Then** I see it under the 'Pending' tab. **When** Friday passes without submission, **Then** it moves automatically to the 'Overdue' tab.
