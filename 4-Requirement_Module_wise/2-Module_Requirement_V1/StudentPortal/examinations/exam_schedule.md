# Examinations — Exam Schedule Tab Requirements

## 1. Functional Overview
Lists details of scheduled examinations (online and offline), showing dates, times, durations, status, and direct action triggers.

---

## 2. Page Structure & Parameters

### A. Ongoing Exams Section
- Exams scheduled for today where the current time is within the start and end limits.
- **Actions**: Direct "Start Exam" button leading to the Online Exam attempt interface.

### B. Today's Exams Section
- All exams scheduled for today (regardless of time limits).

### C. Upcoming Exams Section
- Lists future exams chronologically.
- **Fields**: Exam Title, Subject, Date, Start/End Timings, Duration (minutes), Mode (Online/Offline), and a countdown timer.

### D. Concluded Exams Section
- Past exams.
- Shows status: "Attempted" (with link to results) or "Missed" (if skipped).

---

## 3. Database References
- **Model**: `Modules\LmsExam\Models\ExamAllocation`
- **Table**: `lms_exam_allocations`
- **Relationships**:
  - `examPaper.exam`
  - `examPaper.subject`
