# Learning — LMS Dashboard Tab Requirements

## 1. Functional Overview
A consolidated learning dashboard for the student, displaying assignments, exams, quizzes, and quests allocated to their section.

---

## 2. LMS Sections

### A. Homework Directory
- Lists active homework allocations. Shows subject, title, due date, status (pending, submitted, graded, overdue), and direct details redirect.

### B. Online Exams Allocation List
- Lists allocated online exam papers. Shows subject, date, timings, duration, status, and button triggers (Start Exam, Resume Exam, View Result).

### C. Quizzes Section
- Lists active quizzes. Displays quiz title, subject, attempts allowed vs. used, and status.

### D. Quests Section
- Lists active quests. Displays quest title, subject, and attempt statistics.

---

## 3. Database References
- **Models**:
  - `Modules\LmsHomework\Models\HomeworkAssignment`
  - `Modules\LmsExam\Models\ExamAllocation`
  - `Modules\LmsQuiz\Models\QuizAllocation`
  - `Modules\LmsQuests\Models\QuestAllocation`
