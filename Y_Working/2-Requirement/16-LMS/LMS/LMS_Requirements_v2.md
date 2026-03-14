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
## Sub-Modules

### 1. HOMEWORK & ASSIGNMENT MANAGEMENT

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

### 2. QUESTION CREATION & QUESTION BANK

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

### 3. QUIZ MANAGEMENT 
    
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

### 4. QUEST (LEARNING QUEST)

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

---

### 5. ONLINE EXAM

  **Flow**
  - Here is the Proces Flow how Online Exam will proceed -
    - Teacher will Create Exam (with all the conditions) (e.g. 7th_Half_Yearly_Exam, 7th_Final_Exam)
    - Every Exam will have a fix Scope of the Syllabus (what All Lessons, Topics will be Assessed in that Exam)
    - Questions will be selected from Question Bank as per the Scope of the Syllabus to align with the Exam.
    - Exam can have MCQ & Descriptive Questions
    - Exam questions will be selected as per the Difficulty Level defined in the Exam.
    - Teacher will Assign Exam to Class/Section/Group/Individual Student
    - Student will Attempt Exam with Time Limit apply as per the configuration.
    - Teacher will Evaluate Descriptive Answers of Exam and provide Marks & Remarks
    - The Marks of Descriptive Question (Evaluated by Teacher) will be entered into system mannually.
    - The Marks of MCQ (Auto Evaluated) will be entered into system automatically by system.
    - The Marks of Descriptive Question (Evaluated by Teacher) + Marks of MCQ (Auto Evaluated) will be considered for the Final Result.
    - Teacher can Re-Assign Exam to a class/section/group/individual if required.
    - Teacher will Publish Result on a specified date.
    - Student will View Result on a specified date.
    - Student can raise Grievance against the Marks of Descriptive Question (Evaluated by Teacher) within a specified time period.
    - Teacher will Review the Grievance and provide Final Decision.
    - Student can View the Final Decision of the Grievance.
    - Result Card will be generated for each student using Pre-Defined Template configured by School.

  **Functionalities**
  - All Quiz & Quest conditions applicable with additional conditions
    - is_proctored
    - is_ai_proctored
    - fullscreen_required
    - browser_lock_required
    - Exam Specific Security
      - Anti-Cheating
      - AI Readiness
      - Rubric-based evaluation
      - Performance auto-rating
      - Timer enforced
    - Result card generation per student
    - Subject-wise exam blueprint
    - Exam analytics dashboard
    - Scheduled result publishing
    - Automatic grade & division calculation
    - Performance category calculation
    - Exam timer enforcement. One time is lapsed then exam will be submitted automatically and student cannot restart the exam.
    - Result card generation per student
    - Subject-wise exam blueprint
    - Exam analytics dashboard
    - Collect Data for AI Readiness Prediction
  - Fully online exam capability (NEP aligned)
  - Combination of:
    - MCQ
    - Descriptive
  - Teacher evaluates descriptive answers
  - Exam question pool restricted to exam-enabled questions
  - Each Student may have Unique Exam Paper (Configurable)
  - Exam can be conducted for:
    - Class
    - Section
    - Group of Student
    - Individual Student
  - Exam Scope can have Multipal Lesson Or Topic / Sub-Topic
  - Configurable Difficulty Level (Easy, Medium, Hard) as used in Quiz & Quest
  - Exam result can be scheduled for specific date
    - Teacher can schedule the Exam result to be published on a specified date
    - Teacher can schedule the Exam result to be published Manually to a class/section/group/individual student
  - Exam instructions support:
    - TEXT
    - HTML
    - MARKDOWN
    - LATEX
    - JSON
  - Capture behavioral parameters for Analytics as mentioned below :
    - Time per question
    - Review behavior
    - Answer changes
    - Attempt patterns
  - Exam can be Re-Assigned to a class/section/group/individual student mannually by Teacher
  - Performance of MCQ auto-rating using configuration
  - Exam difficulty balancing
  - Update table (qns_question_statistics) after each attempt e.g. difficulty_index, discrimination_index, guessing_factor, min_time_taken_seconds, max_time_taken_seconds, avg_time_taken_seconds, total_attempts
  - Teacher can:
    - View Attempted Exam
    - View Attempted Exam Result
    - Teacher evaluates descriptive answers
    - Add remarks
    - Re-assign Exam if unsatisfactory
    - See who all submitted OR Not submitted the Exam
    - Extend the date of Exam (Re-schedule the Exam)
    - Extend the Submission Time of Exam (If Required) for a partucler Student/Class/Section/Group
  - Student can: 
    - View Exam Description to understand the Exam and Instruction
    - Attempt the Exam
    - View all Exam Due on him
    - VIEW Attempted Exam Result

---
### 6. OFFLINE EXAM

  **Flow**
  - Here is the Proces Flow how Offline Exam will proceed -
    - Teacher will Create Exam (with all the conditions) (e.g. 7th_Half_Yearly_Exam, 7th_Final_Exam)
    - Teacher will define the Scope of the Exam (what All Lessons, Topics will be Assessed in that Exam)
    - Teacher will define the Difficulty Level of the Exam (Easy, Medium, Hard)
    - Teacher will define the Time Limit & Instructions of the Exam
    - System will help Teacher to Create Question Paper as per the Scope of the Exam, Difficulty Level & Time Limit for every Class/Subjects.
    - Teacher will Review the Question Paper and can make necessary changes and download the Question Paper.
    - Teacher will Assign the Question Paper to Class/Section/Group/Individual Student.
    - Exam will be Conducted Offline by Teacher as per the School Rules.
    - Student will attempt the Exam Offline as per the School Rules.
    - Teacher will Evaluate all the Questions and provided Marks & Remarks.
    - Students wise Answer and Marks will be Entered into System OR it can be uploaded as a file into system
    - System will calculate Grade & Division as per the Configuration and use the data for Analysis.
    - Teacher will Publish Result on a specified date.
    - Student will View Result on a specified date.
    - Student can raise Grievance against the Marks of Descriptive Question (Evaluated by Teacher) within a specified time period.
    - Teacher will Review the Grievance and provide Final Decision.
    - Student can View the Final Decision of the Grievance.
    - Result Card will be generated for each student using Pre-Defined Template configured by School.

  **Functionalities**

    - All conditions of Online Exam will be applicable, the only difference is that Exam will be Conducted Offline by Teacher as per the School Rules and Markes will be Enterd / Uploaded Later.
    - Fully offline exam capability (NEP aligned)
    - Combination of:
      - MCQ
      - Descriptive
    - Teacher evaluates all answers
    - Exam data entry / Data upload into App
    - Exam question pool restricted to Exam Paper Creation
    - Scheduled result publishing
    - Automatic grade & division calculation
    - Performance category calculation
    - Exam timer enforcement will be managed by Teacher
    - Result card generation per student
    - Subject-wise exam blueprint
    - Exam analytics dashboard

---

### 7. STUDENT ATTEMPT

  **Dashboard Functionalities**
    - Unified dashboard to Attempt or see status of:
      - Quiz
      - Quest
      - Online Exam
      - Offline Exam

  **Flow To Attempt Quiz**
    - Student will see the Quiz List due on him on his Dashboard
    - Student will click on the Quiz to see all the Instructions of the Quiz.
    - Student will Attempt the Quiz by clicking on Start button.
    - Student will Attempt the Quiz as per the configuration set by Teacher for the Quiz.
    - Student will Submit the Quiz after completion.
    - Student will see the Result of the Quiz
    - Student will see the Analysis of the Quiz

  **Flow To Attempt Quest**
    - Student will see the Quest List due on him on his Dashboard
    - Student will click on the Quest to see all the Instructions of the Quest.
    - Student will Attempt All the MCQs of the Quest by clicking on Start button.
    - Student will Attend all Descriptive Questions of the Quest by typing answers in the text box provided for each question OR,
    - Student will Upload the answers of the Descriptive Questions of the Quest as a PDF/Image file.
    - Student will Attempt the Quest as per the configuration set by Teacher for the Quest.
    - Student will Submit the Quest after completion.
    - Student will see the Result of the Quest once Teacher will evaluate Descriptive Questions and provided Marks & Remarks and publish the result.
    - Student will see the Analysis of the Quest once Teacher will publish the result.

  **Flow To Attempt Online Exam**
    - Student will see the Online Exam List due on him on his Dashboard
    - Student will click on the Online Exam to see all the Instructions of the Online Exam.
    - Student will Attempt All the MCQs of the Online Exam by clicking on Start button.
    - Student will Attend all Descriptive Questions of the Online Exam by typing answers in the text box provided for each question OR,
    - Student will Upload the answers of the Descriptive Questions of the Online Exam as a PDF/Image file.
    - Student will Attempt the Online Exam as per the configuration set by Teacher for the Online Exam.
    - Student will Submit the Online Exam after completion.
    - Student will see the Result of the Online Exam once Teacher will evaluate Descriptive Questions and provided Marks & Remarks and publish the result.
    - Student will see the Analysis of the Online Exam once Teacher will publish the result.

  **Flow To Attempt Offline Exam**
    - Teacher will Create Multipal Question Papers for every subject of every class using System for Offline Exam.
    - Teacher will Assign the different Question Paper to different Class/Section/Group/Individual Student.
    - Data for Which Student attempted which set of Exam paper will be uploaded into system for detail analysis.
    - Student will Attend Offline Exam in the School Premises as per the schedule set by School.
    - Once Exam is Completed, Teacher will Evaluate all the Questions and provided Marks & Remarks.
    - Teacher will Upload answer of all the MCQs of the Offline Exam as a Excel file into system.
    - Teacher will Enter Marks & Remarks for each Question in the System.
    - Teacher will Upload the answers of the Descriptive Questions of the Offline Exam as a PDF/Image file.
    - Student will see the Result of the Offline Exam once Teacher will evaluate Descriptive Questions and provided Marks & Remarks and publish the result.
    - Student will see the Analysis of the Offline Exam once Teacher will publish the result.

  **Other Actions (Student Can do)**
    - Student can see Attempt history
    - Student can see Progress visualization
    - Student can see Personalized recommendations
    - Student can see Result card
    - Student can see Performance analytics
    - Student can see Learning analytics
    - Student can see Attendance
    - Student can see Fees details
    - Student can see Class/Student Library detail
    - Student can see Class/Student Transport details
    - Student can see Class/Student Health details
    - Student can see Class/Student details
    - Student can see Parent details
    - Student can see Guardian details
    - Student can see Notifications
    - Student can see Announcements
    - Student can see Events
    - Student can see News
    - Student can see Gallery
    - Student can Apply for Leave
    - Student can see Leave Status

---

### 7. TEACHER DASHBOARD

  **Dashboard Functionalities**
    - Unified dashboard to see Status and take appropriate action on :
      - Quiz
      - Quest
      - Online Exam
      - Offline Exam
    - Teacher can : 
      - See the status of Quiz/Quest/Online Exam/Offline Exam detail directly from dashboard
      - See Attempt history
      - See Progress visualization
      - See Personalized recommendations
      - See Result card
      - See Performance analytics
      - See Learning analytics
      - Apply Leave
      - Approve Students Leave
      - Approve Students Homework
      - Check & Marked Descriptive type Questions for Quest & Online Exam
      - Check & Marked all question of Offline Exam
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


### 8. STUDENT DASHBOARD

  **Functionalities**
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


### 10. LEARNING ANALYTICS & INSIGHTS
- Student learning trajectory
- Weak area detection
- Predictive risk alerts
- Teacher effectiveness analytics

### 11. NEP 2020 & HOLISTIC PROGRESS CARD
- Competency tracking
- Multi-dimensional reporting
- Continuous assessment aggregation
- Holistic Progress Card generation

### 12. CONTENT & CURRICULUM GOVERNANCE
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

------------------------------------------------------------------------------------------------------------------
- we will be having 2 type of Exam (Online & Offline)
- Table 1 : lms_exams (this will have Common Exam Details applicable to all Subjects and assigned classes)
- Table 2 : lms_exam_papers (This will have detail about about exam papers for different Class, Sections, Subjects)
- Table 4 : lms_exam_paper_set (Evry class+Section may have multipal exam papers for the same Subject for same exam)
- Table 3 : lms_exam_paper_questions (This will have detail about about exam paper questions for different Class, Sections, Subjects)
- Table 3 : lms_exam_details (this will have Subject wise Exam Details)


Re-Evaluate "2-Tenant_Modules/16-LMS/LMS_Exam/LMS_Exam_ddl_v1.sql" and enhance the DDLs to meet all below conditions. Create new DDL with the name "2-Tenant_Modules/16-LMS/LMS_Exam/LMS_Exam_ddl_v2.sql

- Schools may have 2 type of Exam - Online & Offline for different Assessment type (Unit Test, Term Test, Half Yearly Exam, Annual Exam, etc)
- Multipal papers for different Subject for every class+section will be conducted.
- School may use both Method (Online & Offline) for the same Exam for different Class/Section or for different Subject.
- There will be some conditions which will be applicable to both Online & Offline Exam, which we should keep separate.
- There will be some conditions which will be applicable to Online Exam only, which we should keep separate.
- I feel chanses are extremly low to have any condition which will be applicable to Offline Exam only and to both, but if there is any we should keep that also separate. 
- Different Subject for a Particuler Class/Section may have different Method of Exam (Online or Offline or Both)
- Every Subject for a Particuler Class/Section may have multipal sets of papers for Online & Offline Method of Exam
- Different set of exam papers set may have different questions
- we may divide students of every class,section into different groups for exam purpose.
- School may decide to create different exam paper for different group of students or for every student for the same Subject for same exam
- Different group of students will be assigned different set of papers for the same Subject for same exam
- Every exam may have MCQ & Descriptive type Questions.
- Descriptive type Questions will be evaluated by Teacher & later can be evaluated by AI to suggest improvement or to help teacher in evaluation.
- MCQ Questions for both type of Exam (Online & Offline) will be evaluated by System
- For Offline Exams Questions & Answers will be uploaded in Excel/PDF format or will be entereed manually into system
- For Offline exam Answer key & Teacher's Marks will be uploaded in Excel format or will be entereed manually into system
- All Descriptive type questions Marks whcih will be evaluated by teacher will be uploaded in Excel format or entered manually into system.
- Answeres for all Descriptive type questions in Online Exams will be uploaded in Excel/PDF format or entered manually into system
- Grading & Division will be calculated by system by using pre-defined config table



