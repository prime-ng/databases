# Examinations — My Results Tab Requirements

## 1. Functional Overview
A consolidated record of the student's evaluated submissions across Online Exams, LMS Quizzes, Quests, and Class Homework.

---

## 2. Page Structure & Parameters

### A. Online Exams Results Tab
- Lists submitted online exams once the teacher publishes the results.
- **Columns**: Paper Title, Paper Code, Subject, Total Marks, Marks Obtained, Percentage, Grade, Status, and Action buttons (PDF download, detailed view).

### B. Quizzes Results Tab
- Lists completed quizzes.
- **Columns**: Quiz Title, Subject, Max Marks, Marks Obtained, Percentage, Grade, Pass Status (Pass/Fail), and Date Attempted. Offers a "Review" button.

### C. Quests Results Tab
- Lists completed quests.
- **Columns**: Quest Title, Subject, Max Marks, Marks Obtained, Percentage, Grade, Pass Status, and Date. Offers a "Review" button.

### D. Homework Results Tab
- Lists evaluated homework assignments.
- **Columns**: Homework Title, Subject, Assigned Date, Due Date, Submitted Date, Marks Obtained, Max Marks, Status, and Teacher Feedback.

---

## 3. Database References
- **Tables**:
  - `lms_exam_attempts`
  - `lms_exam_results`
  - `lms_quiz_quest_results`
  - `lms_homework_submissions`
