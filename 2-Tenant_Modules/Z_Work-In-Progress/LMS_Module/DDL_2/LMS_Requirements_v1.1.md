# LMS – DETAILED REQUIREMENT (ENHANCED & INTACT)

## Deliverable 1 (Revised as per User Expectation)

> **Principle Followed**
> - ALL original requirements provided by the user are kept **100% intact**
> - Additional requirements are **clearly additive**
> - Simple, clean structure:
>   - Sub-Module Name
>   - List of Functionalities under that Sub-Module
> - AI-ready, DDL-ready, ERP-grade
> - NEP 2020 aligned

---

## 1. HOMEWORK & ASSIGNMENT MANAGEMENT

### Functionalities

- Create Homework (H/W) for every Class in advance
  - Homework creation Class-wise and Section-wise
  - Homework aligned with:
    - Subject
    - Topic
    - Sub-Topic
    - Mini Topic
    - Micro Topic
- Homework can be auto-assigned / manually assigned
  - If set for Auto-Assigned - 
    - when aligned Topic/Sub-Topic/Mini/Micro Topic is marked **Completed**, 
    - Homework will be auto-assigned to the students of that class/section
  - If set for Manual-Assigned - 
    - Teacher can manually assign the Homework to the students of that class/section
    - Teacher need to manually change the status of Topic/Sub-Topic/Mini/Micro Topic to **Completed**
    - Teacher ccan also assigning Homework on a specified date to a class/section
- Homework can be:
  - Long text based
  - Scanned handwritten attachment (image/PDF)
- Homework visibility:
  - Student portal
  - Parent portal
- Student can complete the Homework by:
  - Submitting Homework with scanned copy upload
  - Submitting Homework with text
  - Can see all the due/submitted/overdue Homeworks
- Homework will be visibal to:
  - Student portal
  - Parent portal
- System tracks:
  - Submitted students
  - Pending students
  - Late submissions
- Teacher can:
  - View submitted Homework
  - Add remarks
  - Re-assign Homework if unsatisfactory
  - See who all submitted OR Not submitted the Homework
- Homework may have marks (config driven)
- Homework release can be:
  - Immediate
  - On Topic completion
  - on a scheduled date
- Teacher can send message regarding Homework non-completion to:
  - Student
  - Parent
- Homework contributes to formative assessment analytics
- Homework difficulty tagging
- Homework workload balancing across subjects

---

## 2. QUESTION CREATION & QUESTION BANK

### Functionalities

- Teachers / Content Team create questions for every:
  - Class
  - Subject
- Questions aligned with:
  - Topic
  - Sub-Topic
  - Mini Topic
  - Micro Topic
  - Competency ()
- Question categorization based on:
  - Bloom Taxonomy
  - Cognitive Skill
  - Question Type Specificity
  - Complexity Level
  - Question Type
- Question formats supported:
  - TEXT
  - HTML
  - MARKDOWN
  - LATEX
  - JSON
  - Image-based
- Each Question has:
  - Marks
  - Optional Negative Marking
- Teacher explanation mandatory for every Question
- Question review & approval workflow
- Capture:
  - Reviewer
  - Approval timestamp
- Question versioning:
  - Old version
  - Change summary
  - Changed by / changed on
- Question usage scope:
  - Quiz only
  - Assessment only
  - Exam only
  - All
- Question ownership:
  - PrimeGurukul
  - School
- Question availability:
  - GLOBAL
  - SCHOOL_ONLY
  - CLASS_ONLY
  - SECTION_ONLY
  - ENTITY_ONLY
  - STUDENT_ONLY
- Capture Question source & reference:
  - Book name
  - Page number
  - External reference
- Question statuses:
  - DRAFT
  - IN_REVIEW
  - APPROVED
  - REJECTED
  - PUBLISHED
  - ARCHIVED
- MCQ questions:
  - Minimum 2 options
  - Option-level explanations (correct & incorrect)
- Media attachment supported at:
  - Question level
  - Option level
- Tags supported:
  - One tag → multiple questions
  - One media → multiple questions
- One question aligned to multiple topics
- Capture Question statistics:
  - Difficulty index
  - Discrimination index
  - Guessing factor
  - Min/Max/Average time
  - Total attempts
- Question mapped to:
  - Performance Category (TOPPER, EXCELLENT, GOOD, AVERAGE)
  - Recommendation Type (REVISION, PRACTICE, CHALLENGE)
- Track question usage:
  - Quiz
  - Assessment
  - Exam
- AI-based question generation
- Excel import & export of questions
- Question quality score

---

# 3. QUIZ MANAGEMENT

  ## Process Flow & Functionalities
  - Teacher creates Quiz to accomodate set of questions.
    Quiz will always cover a Topic/Sub-Topic,Mini Topic/Micro Topic & whatever Topic Level comes underneeth that topic/sub-topic.
    - Quiz will have 2 Tables 
      - lms_quiz
      - lms_quiz_questions
    - lms_quiz will have following attributes:
      - Quiz Code & Name
      - Quiz Description
      - Instructions (e.g. TEXT, HTML, MARKDOWN, LATEX, JSON) - Instructions will be shown to the students before the quiz
      - Quiz Type (e.g. Formative, Summative, Diagnostic, etc.)
      - Quiz_Scope_id FK to slb_topics.id - Quiz Scope will be used to filter the questions based on the topic/Sub-Topic/Mini Topic/Micro Topic 
      - Quiz Status (e.g. DRAFT, IN_REVIEW, APPROVED, REJECTED, PUBLISHED, ARCHIVED)
      - Publish Date
      - Due Date
      - Last Submission Date
      - Duration (in minutes)
      - Total Marks
      - Total Questions
      - Passing Percentage
      - Reusable (e.g. TRUE, FALSE) - Quiz can be reused for different Sections/Groups/Individual Students?
      - Reusable Count (e.g. 1, 2, 3, etc.) - Number of times the quiz can be reused
      - Allowed Attempts (e.g. 1, 2, 3, etc.)
      - Time Duration (e.g. 10, 20, 30, etc.)
      - Negative Marking (e.g. 0.25, 0.5, 1, etc.) - Negative marking will be applied to the quiz
      - Random Question Order (e.g. TRUE, FALSE) - Questions will be selected in random order
      - Show Marks (e.g. TRUE, FALSE) - Marks will be shown to the students after the quiz
      - Auto Publish Result (e.g. TRUE, FALSE) - Result will be published to the students after the quiz
      - Manual Publish Result (e.g. TRUE, FALSE) - Result will be published manually by the teacher
      - Scheduled Result Publish Date (e.g. 2025-01-01) - Result will be published to the students on this date
      - System Generated (e.g. TRUE, FALSE) - Auto-generated quiz based on system rules for performance category
      - Topic-wise Ordinal Sequencing (e.g. TRUE, FALSE) - Questions will be selected based on the topic-wise ordinal sequencing
      - Performance Auto-Rating (e.g. TRUE, FALSE) - Auto-rating of student performance based on the quiz results
      - Timer Enforced (e.g. TRUE, FALSE) - Timer will be enforced for the quiz
      - Question Pool Restricted (e.g. TRUE, FALSE) - Only questions from the quiz-allowed questions will be selected
      - Difficulty Balancing (e.g. TRUE, FALSE) - Questions will be selected based on the difficulty level
      - Difficulty Distribution Id (e.g. EASY, MEDIUM, HARD) - Distribution of questions based on the difficulty level
      - Anti-Cheating Indicators (e.g. TRUE, FALSE) - Questions will be selected based on the anti-cheating indicators
    - lms_quiz_questions will have following attributes:
      - Id
      - Quiz Id (FK to lms_quiz.id)
      - Question Id (FK to lms_questions.id)
      - Question Order (e.g. 1, 2, 3, etc.)
      - Question Type (e.g. MCQ, Single Answer, Multiple Answer)
    - Difficulty Distribution Config:
      - Difficulty Distribution Config will be used to balance the questions based on the difficulty level
      - Difficulty Distribution Config will have 2 tables. 1-(difficulty_distribution_config) & 2-(difficulty_distribution_config_details)
      - difficulty_distribution_config will have following attributes:
        - Id
        - Code (e.g. EASY, MEDIUM, HARD)
        - Name (e.g. Easy, Medium, Hard)
        - Description (e.g. Easy, Medium, Hard)
        - used_for FK to qns_question_usage_type (e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM','UT_TEST')
      - difficulty_distribution_config_details will have following attributes:
        - Id
        - Difficulty Distribution Configuration Id
        - Question Type (e.g. MCQ, Short Answer, Long Answer)
        - Complexity Type (e.g. Easy, Medium, Hard)
        - Complexity Level (e.g. 1, 2, 3)
        - Min. Percentage of Total Questions
        - Max. Percentage of Total Questions
        - Marks for Each Complexity Level
  - Adding Questions to the Quiz
    - Teacher / Admin can Add questions to the Quiz by:
      - Manual selection of questions from Question Bank by filtering on - 
        - Bloom's Taxonomy
        - Cognitive Skill
        - Question Type Specificity
        - Complexity Level
        - Quiz_Difficulty_Level
        - Topic hierarchy (up to Topic → Sub Topic → Micro Topic → Ultra Topic)
        - Question Source & Reference
        - Question Status
        - Question Usage Scope
        - Question Availability
        - Question Statistics
        - Question Quality Score
      - AI based selection of questions from Question Bank
        - AI will consider all the parameters of Question Bank for selection of questions
        - AI based selection of questions from Question Bank based on Bloom's Taxonomy, Cognitive Skill, Question Type Specificity, Complexity Level, Question Type, Difficulty Level, Difficulty Distribution, Anti-Cheating Indicators, Tags, Topic hierarchy (up to Ultra Topic), Performance Category, Recommendation Type, Question Source & Reference, Question Status, Question Usage Scope, Question Ownership, Question Availability, Question Statistics, Question Quality Score
      - Mix of manual and AI based selection of questions from Question Bank
        - AI will consider all the parameters of Question Bank for selection of questions
        - AI based selection of questions from Question Bank based on Bloom's Taxonomy, Cognitive Skill, Question Type Specificity, Complexity Level, Question Type, Difficulty Level, Difficulty Distribution, Anti-Cheating Indicators, Tags, Topic hierarchy (up to Ultra Topic), Performance Category, Recommendation Type, Question Source & Reference, Question Status, Question Usage Scope, Question Ownership, Question Availability, Question Statistics, Question Quality Score
        - Then Teacher can select questions manually from the list provided by AI
        - Teacher can add questions manually from Question Bank
        - Teacher can reorder questions manually from the list provided by AI
  - Quiz Assignment:
    - Quiz Assignment will have following parameters:
      - Assigned to Class
      - Assigned to Section
      - Assigned to Group of Student
      - Assigned to Individual Student
      - Assigned to Subject
      - Assigned to Topic hierarchy (up to Topic → Sub Topic → Micro Topic → Ultra Topic)
      - Assigned to Performance Category
      - Assigned to Recommendation Type
    - Different type of quizzes for different student groups of same class/section. Quiz can be Assigned to:
      - Class
      - Section
      - Group of Student
      - Individual Student
  - Quiz Scheduling:
    - Quiz can be auto-assigned / manually assigned
      - If set for Auto-Assigned - 
        - When aligned Topic/Sub-Topic/Mini/Micro Topic is marked **Completed**, 
        - Quiz will be auto-assigned to the students of that class/section
      - If set for Manual-Assigned - 
        - Teacher can manually assign the Quiz to the students of that class/section
        - Teacher need to manually change the status of Topic/Sub-Topic/Mini/Micro Topic to **Completed**
        - Teacher ccan also assigning Quiz on a specified date to a class/section
    - Quiz auto-assigned when topic marked completed
      - Teacher will Mark the Topic/Sub-Topic/Mini/Micro Topic as **Completed**
      - Auto-assigned quiz will be assigned to the students of the class/section/group/individual student who have completed the topic
    - Quiz can be scheduled for specific date
      - Teacher can assign Quiz on a specified date to a class/section/group/individual student
      - Teacher can assign Quiz Manually to a class/section/group/individual student
  - Quiz instructions support:
    - TEXT
    - HTML
    - MARKDOWN
    - LATEX
    - JSON
  - System will capture behavioral parameters:
    - Time per question
    - Review behavior
    - Answer changes
    - Attempt patterns
  - System will provide Recommendations or can re-assign Quiz as per the Performance Rules:
    - Read (pdf,url)
    - Watch (video, video url)
    - Practice (quiz)
      - If the performance Rules suggested `practice`, then AI will create a new quiz with similer deficulty level but with different questions.
      - newly created quiz will be re-assigned to the students.
    - Re-Test (quiz)
      - If the performance Rules suggested `re-test`, then AI will create a new quiz with similer deficulty level but with different questions.
      - newly created quiz will be re-assigned to the students.
    - Performance Rules will be set by the Teacher / Admin:
      - Different level of performance may have different type of Recommendations.
      - Different level of performance may have different type of Re-Assignment:
        - Challenge
        - Enrichment
        - Practice
        - Revision
        - Re-Test
        - Diagnostic
        - Remedial
    - Recommendations will be provided using Recommendation Module:
      - Recommendation will be identifies using Rules defined in rec_recommendation_rules
      - Student wise Recommendations will be registered in Recommendation Module
      - Recommendations will be provided to the students based on the performance rules
      - Recommendations will be provided to the students based on the performance rules
  - Performance auto-rating will use the Performance Rating configuration
  - Quiz difficulty balancing
    - System will check required difficulty level for the quiz and balance the difficulty level using difficulty_distribution_config. 
  - Teacher can:
    - View Attempted Quiz
    - View Attempted Quiz Result
    - Add remarks
    - Re-assign Quiz if unsatisfactory
    - See who all submitted OR Not submitted the Quiz
    - Extend the Due date of Quiz
    - Extend the Last Submission Date of Quiz
  - Student can: 
    - View Attempted Quiz
    - View Attempted Quiz Result
    - View all Quiz Due on him
    - Attempt the Quiz

---

## 4. QUEST (LEARNING QUEST)

  ### Process Flow & Functionalities
  The purpose of creating Quest is to Check the Knowledge of the student on Group of Lesson/Topics/Sub-Topics. It may be used to evaluate the prepairedness of the Student for the Exam. Quest inherits all Quiz conditions.
  - Quest can Cover 1 or more Lesson / Topic as per the requirement.
  - Quest will accomodate set of questions. Quest can be used for various purposes:
      - Formative Assessment
      - Summative Assessment
      - Diagnostic Assessment
      - Practice
      - Revision
      - Prepair for Exam
      - Assignment
      - Project
      - Portfolio
      - etc.
  - Quest will have 3 Tables 
    - lms_quest
    - lms_quest_scopes
    - lms_quest_questions
  - Teacher creates Quest Which will be used to accomodate set of questions to meet the purpose of Quest.
    - lms_quest will have following attributes:
      - Quest ID
      - Quest Name
      - Quest Description
      - Instructions (e.g. TEXT, HTML, MARKDOWN, LATEX, JSON) - Instructions will be shown to the students before the quest
      - Quest Type (e.g. Formative, Summative, Diagnostic, Practice, Revision, Prepair for Exam, Assignment, Project, Portfolio, etc.)
      - Quest Status (e.g. DRAFT, IN_REVIEW, APPROVED, REJECTED, PUBLISHED, ARCHIVED)
      - Quest Publish Date
      - Quest Due Date
      - Quest Last Submission Date
      - Quest Duration (in minutes)
      - Total Marks
      - Total Questions
      - Total MCQ Questions
      - Total Short Answered Questions
      - Total Long Answered Questions
      - Passing Percentage
      - Quest Reusable (e.g. TRUE, FALSE) - Quest can be reused for different Sections/Groups/Individual Students?
      - Quest Reusable Count (e.g. 1, 2, 3, etc.) - Number of times the quest can be reused
      - Allowed Attempts (e.g. 1, 2, 3, etc.)
      - MCQ Time Duration for MCQ (e.g. 10, 20, 30, etc.)
      - MCQ Negative Marking (e.g. 0.25, 0.5, 1, etc.) - Negative marking will be applied to the quest
      - MCQ Random Question Order (e.g. TRUE, FALSE) - Questions will be selected in random order
      - MCQ Show Marks (e.g. TRUE, FALSE) - Marks will be shown to the students after the quest
      - MCQ Result Auto Publish (e.g. TRUE, FALSE) - Result will be published to the students after the quest
      - MCQ Result Manual Publish (e.g. TRUE, FALSE) - Result will be published manually by the teacher
      - MCQ Topic-wise Ordinal Sequencing (e.g. TRUE, FALSE) - Questions will be selected based on the topic-wise ordinal sequencing
      - MCQ Performance Auto-Rating (e.g. TRUE, FALSE) - Auto-rating of student performance based on the quest results
      - MCQ Timer Enforced (e.g. TRUE, FALSE) - Timer will be enforced for the quest
      - MCQ Question Pool Restricted (e.g. TRUE, FALSE) - Only questions from the quest-allowed questions will be selected
      - Difficulty Balancing (e.g. TRUE, FALSE) - Questions will be selected based on the difficulty level
      - Difficulty Distribution Id (e.g. EASY, MEDIUM, HARD) - Distribution of questions based on the difficulty level
      - Anti-Cheating Indicators (e.g. TRUE, FALSE) - Questions will be selected based on the anti-cheating indicators
      - System Generated (e.g. TRUE, FALSE) - Auto-generated quest based on system rules for performance category
    - lms_quest_scopes will have following attributes:
      - Id
      - Quest Id (FK to lms_quest.id)
      - Scope_type_Id (FK to slb_topic_level_types.id)
      - Scope_lesson_Id (FK to slb_topics.id)
      - Scope_topic_Id (FK to slb_topics.id)
      - Question_type_Id (FK to slb_question_types.id) e.g. MCQ, Short Answered, Long Answered
      - Total_Questions
    - lms_quest_questions will have following attributes:
      - Id
      - Quest Id (FK to lms_quest.id)
      - Question Id (FK to lms_questions.id)
      - Question Order (e.g. 1, 2, 3, etc.)
      - Question Type (FK to slb_question_types.id) e.g. MCQ, Short Answered, Long Answered
    - Difficulty Distribution Config:
      - Difficulty Distribution Config will be used to balance the questions based on the difficulty level
      - Difficulty Distribution Config will have 2 tables. 1-(difficulty_distribution_config) & 2-(difficulty_distribution_config_details)
      - difficulty_distribution_config will have following attributes:
        - Id
        - Code (e.g. EASY, MEDIUM, HARD)
        - Name (e.g. Easy, Medium, Hard)
        - Description (e.g. Easy, Medium, Hard)
        - used_for FK to qns_question_usage_type (e.g. 'QUIZ','QUEST','ONLINE_EXAM','OFFLINE_EXAM','UT_TEST')
      - difficulty_distribution_config_details will have following attributes:
        - Id
        - Difficulty Distribution Configuration Id
        - Question Type (e.g. MCQ, Short Answer, Long Answer)
        - Complexity Type (e.g. Easy, Medium, Hard)
        - Complexity Level (e.g. 1, 2, 3)
        - Min. Percentage of Total Questions
        - Max. Percentage of Total Questions
        - Marks for Each Complexity Level
  - Adding Questions to the Quest
    - Teacher / Admin can Add questions to the Quest as per the Quest Scope by:
      - Manual selection of questions from Question Bank by filtering on - 
        - Bloom's Taxonomy
        - Cognitive Skill
        - Question Type Specificity
        - Complexity Level
        - Quest_Difficulty_Level
        - Topic hierarchy (up to Topic → Sub Topic → Micro Topic → Ultra Topic)
        - Question Source & Reference
        - Question Status
        - Question Usage Scope
        - Question Availability
        - Question Statistics
        - Question Quality Score
      - AI based selection of questions from Question Bank
        - AI will consider all the parameters of Question Bank for selection of questions
        - AI based selection of questions from Question Bank based on Bloom's Taxonomy, Cognitive Skill, Question Type Specificity, Complexity Level, Question Type, Difficulty Level, Difficulty Distribution, Topic hierarchy (up to Ultra Topic), Question Source & Reference, Question Status, Question Usage Scope, Question Availability, Question Statistics, Question Quality Score
      - Mix of manual and AI based selection of questions from Question Bank
        - AI will consider all the parameters of Question Bank for selection of questions
        - AI based selection of questions from Question Bank based on Bloom's Taxonomy, Cognitive Skill, Question Type Specificity, Complexity Level, Question Type, Difficulty Level, Difficulty Distribution, Topic hierarchy (up to Ultra Topic), Question Source & Reference, Question Status, Question Usage Scope, Question Availability, Question Statistics, Question Quality Score
        - Then Teacher can select questions manually from the list provided by AI
        - Teacher can add questions manually from Question Bank
        - Teacher can reorder questions manually from the list provided by AI
      - Quest can have Questions from Multiple Lessons as per Teacher's requirement
  - Quest Assignment:
    - Quest Assignment will have following parameters:
      - Assigned to Class
      - Assigned to Section
      - Assigned to Group of Student
      - Assigned to Individual Student
      - Assigned to Subject
      - Assigned to Topic hierarchy (up to Topic → Sub Topic → Micro Topic → Ultra Topic)
      - Assigned to Performance Category
      - Assigned to Recommendation Type
    - Different type of Quest for different student groups of same class/section. Quest can be Assigned to:
      - Class
      - Section
      - Group of Student
      - Individual Student
  - Quiz Scheduling:
    - Quest can be auto-assigned / manually assigned
      - If set for Auto-Assigned - 
        - When aligned Topic/Sub-Topic/Mini/Micro Topic is marked **Completed**, 
        - Quest will be auto-assigned to the students of that class/section
      - If set for Manual-Assigned - 
        - Teacher can manually assign the Quest to the students of that class/section
        - Teacher need to manually change the status of Topic/Sub-Topic/Mini/Micro Topic to **Completed**
        - Teacher ccan also assigning Quest on a specified date to a class/section
    - Quest auto-assigned when topic marked completed
      - Teacher will Mark the Topic/Sub-Topic/Mini/Micro Topic as **Completed**
      - Auto-assigned quest will be assigned to the students of the class/section/group/individual student who have completed the topic
    - Quest can be scheduled for specific date
      - Teacher can assign Quest on a specified date to a class/section/group/individual student
      - Teacher can assign Quest Manually to a class/section/group/individual student
  - Quest result can be scheduled for specific date
    - Teacher can schedule the Quest result to be published on a specified date
    - Teacher can schedule the Quest result to be published Manually to a class/section/group/individual student
  - Quest instructions support:
    - TEXT
    - HTML
    - MARKDOWN
    - LATEX
    - JSON
  - Capture behavioral parameters:
    - Time per question
    - Review behavior
    - Answer changes
    - Attempt patterns
  - Quest can be Re-Assigned to a class/section/group/individual student mannually by Teacher
  - Performance auto-rating using configuration
  - Quest difficulty balancing
  - Update table (qns_question_statistics) after each attempt e.g. difficulty_index, discrimination_index, guessing_factor, min_time_taken_seconds, max_time_taken_seconds, avg_time_taken_seconds, total_attempts
 - Teacher can:
    - View Attempted Quest
    - View Attempted Quest Result
    - Teacher evaluates descriptive answers
    - Add remarks
    - Re-assign Quest if unsatisfactory
    - See who all submitted OR Not submitted the Quest
    - Extend the Due date of Quest
    - Extend the Last Submission Date of Quest
  - Student can: 
    - View Attempted Quest
    - View Attempted Quest Result
    - View all Quest Due on him
    - Attempt the Quest





- Quest assigned on completion of:
  - Major topic
  - Lesson group
- Quest may span multiple lessons
- Quest used for:
  - Unit readiness
  - Term readiness
- Behavioral telemetry captured
- Scheduled result publishing
- Performance auto-rating
- Timer enforced
- Rubric-based evaluation
- AI readiness prediction

---

## 5. ONLINE EXAM

### Functionalities

- All Quiz & Quest conditions applicable
- Fully online exam capability (NEP aligned)
- Combination of:
  - MCQ
  - Descriptive
- Teacher evaluates descriptive answers
- Exam question pool restricted to exam-enabled questions
- Scheduled result publishing
- Automatic grade & division calculation
- Performance category calculation
- Exam timer enforcement
- Result card generation per student
- Subject-wise exam blueprint
- Exam analytics dashboard

---
## 6. OFFLINE EXAM

### Functionalities

- All Quiz & Quest conditions applicable
- Fully offline exam capability (NEP aligned)
- Combination of:
  - MCQ
  - Descriptive
- Teacher evaluates descriptive answers
- Exam data entry / Data upload into App
- Exam question pool restricted to exam-enabled questions
- Scheduled result publishing
- Automatic grade & division calculation
- Performance category calculation
- Exam timer enforcement
- Result card generation per student
- Subject-wise exam blueprint
- Exam analytics dashboard

## 7. TEACHER DASHBOARD

### Functionalities

- Unified dashboard to Attempt or see status of:
  - Quiz
  - Quest
  - Exam
- Teacher can : 
  - See the status of Quiz/Quest/Exam directly from dashboard
  - See Attempt history
  - See Progress visualization
  - See Personalized recommendations
  - See Result card
  - See Performance analytics
  - See Learning analytics
  - Apply Leave
  - Approve Students Leave
  - Approve Students Homework
  - Check & Marked Student Quest (Descriptive) answers
  - See his/her own Attendance
  - See Class/Student Library detail
  - See Class/Student Transport details
  - See Class/Student Health details
  - See Class/Student details
  - See Parent details for Class/Student
  - See Notifications
  - See Announcements
  - See School Events, News, Gallery
  - See Class/Student Attendance
  - See Class/Student Fees details


## 8. STUDENT DASHBOARD

### Functionalities

- Unified dashboard to Attempt or see status of:
  - Quiz
  - Quest
  - Exam
- Student can : 
  - Attempt Quiz/Quest/Exam directly from dashboard
  - See Attempt history
  - See Progress visualization
  - See Personalized recommendations
  - See Result card
  - See Performance analytics
  - See Learning analytics
  - Apply Leave
  - See Attendance
  - See Fees details
  - See Class/Student Library detail
  - See Class/Student Transport details
  - See Class/Student Health details
  - See Class/Student details
  - See Parent details for Class/Student
  - See Guardian details for Class/Student
  - See Notifications
  - See Announcements
  - See Events
  - See News
  - See Gallery

## 9. LMS CONFIGURATION & RULE ENGINE
- Performance category configuration
- Retest rules
- Marks & grading rules
- AI rule toggles

## 10. LEARNING ANALYTICS & INSIGHTS
- Student learning trajectory
- Weak area detection
- Predictive risk alerts
- Teacher effectiveness analytics

## 11. NEP 2020 & HOLISTIC PROGRESS CARD
- Competency tracking
- Multi-dimensional reporting
- Continuous assessment aggregation
- Holistic Progress Card generation

## 12. CONTENT & CURRICULUM GOVERNANCE
- Content ownership control
- Academic year versioning
- Board-wise curriculum mapping

---

## 13. AI & ML
 - AI based question generation
 - AI based question evaluation
 - AI based performance prediction
 - AI based recommendations
 - AI based insights
 - AI based analytics

## 14. Result card & Progress card Template
 - Result card template
 - Progress card template

## 15. Standard Timetable
  - Timetable will be Created for Every Class/Section
  - All the avalaible Subjects will assigned to the Class/Section
  - Teacher will be assigned to every Subject Period of each class/section
  - Room will be assigned to every Subject Period of each class/section
  - Class Teacher will be assigned to every class/section

## 16. Lesson Planning
  - Lesson Planning will be done for every Subject/Class/Section
  - Lesson Planning will have 2 tables:
    - slb_lesson_plan
    - slb_lesson_plan_details
  - `slb_lesson_plan` will have following attributes:
  - id
  - session_id
  - class_id
  - section_id
  - subject_group_id

  - `slb_lesson_plan_details` will have following attributes:
  - id
  - day e.g. Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
  - period_no e.g. 1, 2, 3, 4, 5, 6, 7, 8
  - start_time e.g. 08:00
  - end_time e.g. 08:45
  - duration e.g. 45 minutes
  - subject_id  (fk to subjects.id)
  - study_format_id (fk to study_formats.id)
  - lesson_plan_id (fk to slb_lesson_plan.id)
  - topic_level_type_id. (fk to lb_topic_level_types.id)
  - topic_id. (fk to lb_topics.id)
  - staff_id. (fk to staff.id)
  - room_no. (fk to rooms.id)

  

