



Prompt: 

I need you to act as a Principal Systems Architect to refine and expand my School ERP Syllabus & Exam Management module. I am using PHP (Laravel) + MySQL.

1. Hierarchy Refinement: Review my attached schema (databases/Modules_DDL/syl_Syllabus_Module/sch_syllabus_ddl_v1.1.sql). I need a robust hierarchical structure: Class -> Subject -> Lesson -> Topic -> Sub-topic -> Mini Topic -> Sub-Mini Topic -> Micro Topic -> Sub-Micro Topic.

  - Requirement: Implement this using a recursive relationship or a 'Materialized Path' approach to allow for unlimited nesting if needed.
  - Analytics Hook: Ensure each level has a unique identifier for performance tracking.
  - Topics will be allignwith competencies & sub-competencies.

2. NEP 2020 & Question Bank: Design a questions table that strictly follows NEP 2020 guidelines. Every question must be categorized by:

  - Bloom’s Taxonomy: (Remember, Understand, Apply, Analyze, Evaluate, Create).
  - Cognitive Level: (Lower Order, Middle Order, Higher Order).
  - Question Time Specificity: Estimated time to solve.
  - Complexity Level: (Easy, Medium, Hard, Challenge).
  - Question Type: (MCQ, MSQ, Descriptive, Assertion-Reasoning, Case-study based).

3. Assessment Engine: Create the logic for Quizzes, Assessments, and Exams(Online / Offline).

  - Linking: How are these assigned to Sections and Students?
  - Teacher will update the status of the completion of the teaching on Topics / sub-topics.
  - Once Teacher will update the status of the completion of the teaching on Topics / sub-topics, the Quiz (whcih will be already created by the Teacher) will be automatically assigned to the Students.
  - System will also capture the time taken by the Student to complete the Quiz and Status of the Quiz (Completed / Incomplete).
  - System will capture all small detail of the Student's attempt on the Quiz whcih will be used later for analytics & Prediction.
  - All type of behavioural data will be captured. Whcih also may used to generate the report of the Student's performance and also can be considered for final result card.
  - System will capture all diffrent parameter to understand student's confidence level and will also cature which all topics/sub-topics are weak and he need assistance for the same.
  - System will provide Recommendation to the student as per their performance level ( e.g., 'You need to focus on Algebra, Geometry, and Statistics').
  - System will provide Text & Video based Recommendation to the student as per their performance level ( e.g., 'You need to focus on Algebra, Geometry, and Statistics').
  - System will provide Recommendation to the Teacher as per their performance level ( e.g., 'You need to focus on Algebra, Geometry, and Statistics').
  - Attempt Tracking: Design the student_attempts and student_responses tables to capture granular data for analytics (e.g., time spent per question).
  - System will also the analysis why Student is strugling in some topics and provide the reason for the same by finding the pattern in the data. e.g. he missed or having low understanding on the base topic (from previous class) because of which he is unable to perform well in the current topic.

Theese are the some key features of the Syllabus & Exam Management Module but there are many more features which are not mentioned here.

4. Deliverables Needed:

    a. Schema Design:
    - Enhanced DDL: Optimized MySQL SQL code with proper indexes and Foreign Keys.
    - Data Dictionary: A complete breakdown of every table and column purpose.

    b. UI Designs:
    - ASCII Screen Designs:
        - Syllabus Manager: A tree-view interface to manage lessons and topics.
        - Exam Analytics Dashboard: An ASCII wireframe showing performance insights (e.g., 'Class performance by Bloom's Level').

    c. Report Design: Detail the logic for a 'Student Gap Analysis Report' (identifying which specific topics a student is weak in based on exam performance).

5. Thinking Instructions:

  - Ensure Multi-tenancy (tenant_id) is present in all tables.
  - Think through the 'Reporting' requirements: How will we efficiently query 'Average score in "Algebra" for Grade 10 across the entire school'? Suggest necessary summary tables or views if the raw data is too heavy.

Please output the schema first, followed by the UI designs and report logic.
First only provide the schema design. Once I will confirm the schema design that no enhancement is required then only I will ask you to provide the UI designs and report logic.

Save all the files in a folder named "Syllabus_Exam_Module" in the "databases/Working/" directory.



---------------------------------------------------------------------------------------------------------------------------------------------

Why this prompt is effective for your specific needs:
Recursive Hierarchy: By mentioning "Materialized Path," you're signaling to the agent to avoid the "N+1" query problem common in Laravel when fetching nested topics (e.g., fetching a sub-topic shouldn't require 5 separate database hits).

NEP 2020 Compliance: It explicitly lists the required metadata for questions, ensuring your database can generate the "Cognitive Reports" required by modern educational boards.

Performance Analytics: Most developers forget the "Analytics" part until the end. This prompt forces the agent to design the attempts table now so you can calculate "Time vs. Accuracy" later.

Next Step in Antigravity
Once Claude Opus generates this schema:

Run the DDL in your Antigravity terminal to create the tables.

Ask for "Laravel Migration & Models": You can then say: "Great, now generate the Laravel Migrations and the Eloquent Models with all relationships defined for this schema."

-------------------------------------------------------------------------------------------------------------------

I need you to act as a Principal Systems Architect to analyze and refine (if Required) my School ERP Syllabus & Exam Management module. I am using PHP (Laravel) + MySQL.

1. Hierarchy Refinement: Review my attached schema (sch_syllabus_ddl_v1.3.sql).  
   Other then 9sys_syllabus_ddl_v1.3.sql), you can analyze other database schema as well, which are already created like -
      - master/prime_db.sql
      - master/tenant_db.sql
      - master/global_db.sql
      - Or Module Based Schema's under folder "databases/Working/Modules/" & "databases/Modules_DDL/"

2. New Requirement: 
   - We will also be capturing information of Which Book (Book Subject, Book Title, Writer, Publication, Edition, Year, ISBN, etc.). This info will be alligned with the Lesson/Topics/Sub-Topics/Mini Topics. This will help us in Question Creation for different Schools. If Book is same for different schools then we will be using the same Book for different schools. 
   - School can also create it's own customise Questions for all the classes/Subjects, which will be available to that School only and will not be shared with any other school.
   - We will be having Recommended Study Material (PDF, Video, etc.) for Every Lesson/Topic/Sub-Topic/Mini Topic. This material will differ for different level of the Performance e.g. Student who is at Basic level will get different material than Student who is at Standard level.
   - Performance Categories will be Configurable at School Level. e.g. Basic, Average, Good, Excellent, Exceptional, etc
   - We will be capturing Teaching Status (Syllabus Completion Status) of every Lesson/Topic/Sub-Topic/Mini Topic for every Class,Section & Subject.
   - We will also capture Syllabus Schedulling for every class & Section for Every Subject
   - Teacher Assignment for every class & Section for Every Subject with Timetable.
   - I want to capture the Syllabus in a hierarchical manner. So that if some student is not able to perform well in some topics/sub-topic/mini topic then application can provide the recommendation to the student as per their performance level ( e.g., 'You need to focus on Algebra, Geometry, and Statistics').
   - Also I want to capture the Syllabus in a hierarchical manner. So that if some student is not able to perform well in some topics then application can provide him questions on the base topic (from previous class). The Base topic for every Topic/Sub-topic/Mini Topic will be pre-configured and Application will provide the questions on the base topic (from previous class) to the student. By this way Application will be able to provide complete root cause analysis why the Student is not able to perform well in some topics. 
   - Analytics Hook: Ensure each level has a unique identifier for performance tracking.
   - Topics will be allignwith competencies & sub-competencies.
   - Questions will be alligned with competencies/sub-competencies, Bloom’s Taxonomy, Cognitive Level, Question Time Specificity, Complexity Level, Question Type.
   - We will be creating Question Bank for every subject/Lesson/Topic/Sub-Topic/Mini Topic using AI and then we will be Creating Quiz/ Assesment/Home-Work, Exam(Online/Offline).
   - Quiz will be Automatically assigned to the entire class+Section when a Teacher mark th status of a Topic/Sub-Topic to be Completed in that Class. Quiz will be having only Objective Type Question which can be checked by Application
   - Assessment will be created by Teacher on need basis and can have Descriptive Question as well as Objective Type Question. Descriptive Question can be checked by Teacher and provided Marks by Teacher. Assessment will be assigned to the entire class+Section by the Teacher mannually or can be scheduled in advance.
   - Online Exam will be created by Teacher by selecting the Questions from Question Bank on need basis and can have Descriptive Question as well as Objective Type Question. Descriptive Question can be checked by Teacher and provided Marks by Teacher. Online Exam will be assigned to the entire class+Section by the Teacher mannually or can be scheduled in advance. Online Exam will be a replacement of Offline Exam and totally depend of School's willingness to switch to Online Exam.
   - Offline Exam will be a Automation of Offline Exam. Offline Exam can have different Options -
      1. Teacher can create Question Paper using Qustion Bank and school will conduct Offline Exam (Paper Pen Exam). Once exam is done and Answer Sheet is Marked by Teacher Application will be provided all the Marks related detail and then Application will do Grading, Division and provide the Result. Application will provide detail Result Analysis as possible on the basis of the data provided to the System.
      2. Offline Exam will be created by Teacher by Created Question paper by Themselves and the School will conduct Offline Exam (Paper Pen Exam). Once exam is done and Answer Sheet is Marked by Teacher Application will be provided all the Marks related detail and then Application will do Grading, Division and provide the Result. Application will provide detail Result Analysis as possible on the basis of the data provided to the System.
   - Option 2 is less effective as compared to Option 1 because Application is having less control on the Question Paper created by Teacher.

   - Once Quiz & assesement will be assign to the Student, Student will be able to attempt the Quiz & Assessment online at home.

Right Now Create the Schema for Syllabus Module and then we will move to the next module which will be Quiz 7 Assessment and then we will move to the next module which will be Exam Module.

3. Old Requirement already considered into attached Schema (sch_syllabus_ddl_v1.3.sql) but you can re-verify and add if find anything missing for below requirement also.

  A. NEP 2020 & Question Bank: Design a questions table that strictly follows NEP 2020 guidelines. Every question must be categorized by:
    - Bloom’s Taxonomy: (Remember, Understand, Apply, Analyze, Evaluate, Create).
    - Cognitive Level: (Lower Order, Middle Order, Higher Order).
    - Question Time Specificity: Estimated time to solve.
    - Complexity Level: (Easy, Medium, Hard, Challenge).
    - Question Type: (MCQ, MSQ, Descriptive, Assertion-Reasoning, Case-study based).

  B. Assessment Engine: Create the logic for Quizzes, Assessments, and Exams(Online / Offline).

    - Linking: How are these assigned to Sections and Students?
    - Teacher will update the status of the completion of the teaching on Topics / sub-topics.
    - Once Teacher will update the status of the completion of the teaching on Topics / sub-topics, the Quiz (whcih will be already created by the Teacher) will be automatically assigned to the Students.
    - System will also capture the time taken by the Student to complete the Quiz and Status of the Quiz (Completed / Incomplete).
    - System will capture all small detail of the Student's attempt on the Quiz whcih will be used later for analytics & Prediction.
    - All type of behavioural data will be captured. Whcih also may used to generate the report of the Student's performance and also can be considered for final result card.
    - System will capture all diffrent parameter to understand student's confidence level and will also cature which all topics/sub-topics are weak and he need assistance for the same.
    - System will provide Recommendation to the student as per their performance level ( e.g., 'You need to focus on Algebra, Geometry, and Statistics').
    - System will provide Text & Video based Recommendation to the student as per their performance level ( e.g., 'You need to focus on Algebra, Geometry, and Statistics').
    - System will provide Recommendation to the Teacher as per their performance level ( e.g., 'You need to focus on Algebra, Geometry, and Statistics').
    - Attempt Tracking: Design the student_attempts and student_responses tables to capture granular data for analytics (e.g., time spent per question).
    - System will also the analysis why Student is strugling in some topics and provide the reason for the same by finding the pattern in the data. e.g. he missed or having low understanding on the base topic (from previous class) because of which he is unable to perform well in the current topic.

Above are some key features of the Syllabus & Exam Management Module which I have provided previously when I used different AI to create the attached schema but there are many more features which are not mentioned here but I want you to provide the schema design for all the features which are not mentioned here but in a seperate file.

4. Deliverables Needed:

    a. Schema Design:
    - Enhanced DDL: Optimized MySQL SQL code with proper indexes and Foreign Keys and store it with name "sch_syllabus_ddl_v1.4.sql".
    - Data Dictionary: A complete breakdown of every table and every field and store it with name "sch_syllabus_ddl_v1.4_data_dictionary.md".

    b. Schema for additional Features(not Mentioned in Requirement but suggested by you):
    - Enhanced DDL: Optimized MySQL SQL code with proper indexes and Foreign Keys and store it with name "sch_new_features_ddl_v1.4.sql".
    - Data Dictionary: A complete breakdown of every table and every field and store it with name "sch_new_features_ddl_v1.4_dictionary.md".    

    c. UI Designs:
    - ASCII Screen Designs:
        - An ASCII wireframe showing complete screen design in the same format as the attached file "Z-Screen-Sample.md".

    d. Report Design: Detail the logic for a 'Student Gap Analysis Report' (identifying which specific topics a student is weak in based on exam performance).

5. Thinking Instructions:

  - Think through the 'Reporting' requirements: How will we efficiently query 'Average score in "Algebra" for Grade 10 across the entire school' then entire city / State / Country? Suggest necessary summary tables or views if the raw data is too heavy.


Please output the schema first, followed by the UI designs and report logic after getting confirmation from me on the schema design.
First only provide the schema design. Once I will confirm the schema design that no enhancement is required then only I will ask you to provide the UI designs and report logic.

Save all the files in a folder named "Syllabus_Exam_Module" in the "databases/Working/" directory.