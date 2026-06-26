# Academics — Academic Overview Tab Requirements

## 1. Functional Overview
Aggregates general academic data across sessions, listing historical exam marksheets, summary attendance benchmarks, and fee balance invoices.

---

## 2. Component Details

### A. Academic Stats
- **Session Average**: Mean score across all tests.
- **Best Percentage**: Highest percentage achieved.
- **Pass Rate**: Percentage of passed papers.

### B. Session Results Archive
- Interactive sessions selector accordion:
  - **Exam Results Table**: Lists subject, paper name, maximum marks, obtained marks, percentage, grade, and status (PASS/FAIL).
  - **Exam Summary Info**: Total marks, division attained, average percentage, and status.

### C. Attendance Trend Metrics
- Presents total days, present days, absent days, and overall percentage for the current session.

### D. Fee Invoice Overview
- Quick table showing active invoice numbers, description, total invoice amount, paid amount, remaining balance, and payment action link.

---

## 3. Database References
- **Models**:
  - `Modules\StudentPortal\Models\ExamResult`
  - `Modules\StudentProfile\Models\StudentAttendance`
  - `Modules\StudentFee\Models\FeeInvoice`
- **Tables**:
  - `lms_exam_results`
  - `std_student_attendance`
  - `fee_invoices`
