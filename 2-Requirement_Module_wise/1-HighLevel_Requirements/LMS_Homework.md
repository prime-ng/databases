# Requirement Document - LMS-Homework
=====================================

## Below is the highlevel Requirement of LMS_Homework Module:

LMS_Homework Requirement:
1. Create Homework `lms_homework_submissions`
  - Select class & subject
  - Enter homework instructions
  - Attach supporting files
  - Fill all the Fileds (e.g. is_gradable, max_marks, passing_marks, allow_late_submission, auto_publish_score)
2. Lesson Planning (Homework Scheduling) `slb_syllabus_schedule`
  - Teacher will feed Lesson Plan (scheduling)
  - `scheduled_start_date`, `scheduled_end_date` & `planned_periods` etc. for Lesson, Topic, Sub-Topic
3. Homework Assignment (New Table Need to be Created)
  - Teacher change Topic/Sub-Topic status -> Completed
  - System will check `realease_condition`
      If Homework needs to be assigned on the Topic Comletion, then
        - Create Entry in `lms_homework_assignment` Table for all the Student of the selected Class+Section+Subject
      IF `realease_condition` = 'ON_SCHEDULED_DATE' then
        - Create Entry in `lms_homework_assignment` Table for all the Student of the selected Class+Section+Subject with `release_scheduled_date`
      IF `realease_condition` = 'IMMEDIATE' then
        - Create Entry in `lms_homework_assignment` Table for all the Student of the selected Class+Section+Subject with Immediatly
    - Fill all the requireed Fileds (e.g. allow_late_submission etc.)
    - Teacher can allow one student for late_submission inemergency whereas for other student it is not allowed.
    - So the fields which can have diiferent value for different Student needs to be in the New table.
4. Homework Submission `lms_homework_submissions`
  - Student complete Homework
  - Submit Homework
5. Review Submission	`lms_homework_submissions`
  - View submitted files
  - Review Submission	Evaluate and grade
6. Feedback	`lms_homework_submissions`
  - Provide written feedback
  - Send notification to parents