# LMS Exam (Masters) — Business Requirements Overview

## Module Purpose

The LMS Exam (Masters) module is the foundational configuration area for the Learning Management System (LMS) Examination engine. It allows the school administrator or exam coordinator to define core configurations that drive the creation, scheduling, and execution of online and offline exams.

This section covers the setup of Exam Types, Exam Status Events, and specialized Student Groups used for targeted exam allocations.

---

## Module Screens (Tab-wise)

The LMS Exam Masters module is located at `/lms-exam/masters` and consists of **4 tabs**:

| # | Screen | Purpose |
|---|--------|---------|
| 01 | Exam Types | Define broad categories of exams (e.g., Mid-Term, Final, Mock Test, Weekly Quiz) |
| 02 | Exam Status Events | Manage status lifecycle events and triggers for exams (e.g., Draft, Scheduled, Ongoing, Completed) |
| 03 | Student Groups | Create customized groupings of students across classes/sections for specific exam targeting |
| 04 | Group Members | Assign individual students to the defined Student Groups |

---

## Data Tables Reference

| Table | Description |
|-------|-------------|
| `lms_exam_types` | Stores exam category definitions (code, name, description) |
| `lms_exam_status_events` | Stores system status codes and their associated action logic |
| `lms_exam_student_groups` | Stores custom student group headers linked to a specific class/section |
| `lms_exam_student_group_members` | Junction table linking students to exam groups |
