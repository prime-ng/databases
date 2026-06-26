# Academics — Syllabus Progress Tab Requirements

## 1. Functional Overview
Tracks subject syllabus coverage percentage and topic coverage timelines, showing completed, in-progress, and upcoming lessons.

---

## 2. Page Structure & Parameters

### A. Subject Summary Grid
- Cards for each subject displaying:
  - Subject Name.
  - Overall progress bar (completed topics divided by total topics).
  - Metrics breakdown: total topics, completed topics, in-progress, and upcoming.

### B. Lesson & Topic Accordion Tree
- Selecting a subject expands the syllabus schedule tree:
  - **Lesson Name**: Module header.
  - **Topic Details**:
    - Topic Name & Level (Type).
    - Planned Periods & Duration (minutes).
    - Scheduled Start Date & End Date.
    - Status Badge:
      - `Completed` (End date is in the past)
      - `In Progress` (Current date is within start and end date)
      - `Upcoming` (Start date is in the future)
    - Assigned Teacher Name.
    - Notes / Lesson Plan Remarks.

---

## 3. Database References
- **Model**: `Modules\Syllabus\Models\SyllabusSchedule`
- **Table**: `slb_syllabus_schedule`
- **Relationships**:
  - `subject`
  - `lesson`
  - `topic`
  - `assignedTeacher`
