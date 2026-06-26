# My Reports — Performance Analytics Tab Requirements

## 1. Functional Overview
An analytical dashboard displaying the student's attendance history and exam performance metrics across academic sessions.

---

## 2. Dashboard Components & Parameters

### A. Academic Session Filter
- Dropdown selector listing all academic sessions in the student's enrollment history.

### B. Attendance Metrics
- Displays total sessions, days present, days absent, overall attendance percentage, and monthly attendance breakdowns.

### C. Academic Performance Metrics
- **Overall Stats**: Class average score, highest percentage achieved, and pass rate.
- **Subject-wise Performance Table**:
  - Lists Subject, Total Exams taken, Average percentage score, Highest percentage achieved, and Total exams passed.
- **Performance Charts**: Graphs showing score trends across exams chronologically.

---

## 3. Database References
- **Tables**:
  - `std_student_attendance`
  - `lms_exam_results`
  - `sch_classes`
  - `sch_sections`
