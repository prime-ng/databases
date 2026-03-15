
SYSTEM:
You are "Business Analyst GPT" - an Experienced Business Analyst specializing in SCHOOL ERP systems. You will Identify all the requirement needs to be incorporated in LMS Module.

Your outputs must be precise, grouped in modules and Sub-Modules and formatted cleanly in Markdown with example and ready to provide to a AI to create an deteailed DDL design and then further design documents.

REQUIREMENT:
Below is the Pre-liminary Requirement for 6 Sub-Modules of LMS Module.

1. Homework & Assignment	
   - Create Homework(H/W) for Every class in Advance
   - Allign Homework(H/W) with Topic/Sub-Topic/Mini Topic/Micro Topic
   - Teacher can change the Completion Status of the Mini/Micro Topic
   - Once Teacher will change the Status of Any Topic/Sub-Topic/Mini/Micro Topic-H/W will assign to the class Automatically
   - H/W Can have a Long Text Based assignment OR Teacher can scan a Hand Written Assignment and attached it with H/W
   - H/W Needs to be created Class & Section wise and will be assigned accordingly
   - H/W will be visibal to the Student on his Portal
   - Parents also can see what is assigned (Quiz, H/W, Assessment) to threir Kids
   - Student Can Complete the H/W and attche Scan copy of the H/W if required
   - Teacher will be able to see who all have submitted and who has not
   - Teacher can send Message to the Student & to their Parents too, if they have not completed H/W in time.
   - Teacher can Add Remark on the H/W and can Re-assigne also if H/W is not as it needs to be done.
   - H/W may have Markes alligne to it if School want. Having Marks or Not will be besed on a Configuration Parameter in Data.
   - H/W can be set to be realeased once  Teacher will Update status of a Topic/Sub-Topic/Mini-Topic to "Completed" with which H/W is alligned to.
      
2. Question Creation	
   - Provide team OR School Teacher will Create Questions in the system for Every Class/Subject
   - Questions will be created by Class/Subject/Topic/Sub-topic/Mini-Topic/Micro-Topic/Competancy wise
   - Questions will be based on Categories (bloom_taxonomy, cognitive_skill, ques_type_specificity, complexity_level, question_types)
   - Every Question will have Marks & may have Negetive Marking too (If School wants)
   - Question can be in different Formats (TEXT','HTML','MARKDOWN','LATEX','JSON') and also can have Images allign to it
   - Every Question will have "teacher_explanation" allign to ti to provide a detiled explaination to the Student
   - Every Question will be Reviewed by some teacher and we will be capturing who Reviewed & Approved it and When
   - In case of Question Refinement we will be capturing the Older Version Deatile, What has been changed and who did it & When
   - Every Question may have Different use (Only for Quiz, Assessment, Exam or for All)
   - Every Question may have different Ownership (PrimeGurukul, School)
   - Question can be is_school_specific or can be used for all the School
   - Questions may have different QUESTIONS AVAILABILITY (GLOBAL','SCHOOL_ONLY','CLASS_ONLY','SECTION_ONLY','ENTITY_ONLY','STUDENT_ONLY')
   - We will capture Questons SOURCE & REFERENCE (Book Name, book_page, external_ref, reference_material)
   - Question may have different status like ('DRAFT','IN_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED')
   - Every Question may have 2 or More Options for MCQ
   - Every Question Option will have Explanation, if that Option is Correct then Why and if it is not then also Why it is not a Currect Option.
   - Every Question, Their Options & their Explainations may have Media File attached to it
   - Question may Have One or More Tag allign to it for easy search
   - One Media & One Tag can be Alligned to multipal Questions / Options
   - Every Question Can be alligned to multipal Topics/Sub-Topics/Mini Topic/Micro Topics 
   - We will collect question_statistics (difficulty_index, discrimination_index, guessing_factor, Minimum/Maximum/Average time taken by Students, total_attempt)
   - Every Questio will be alligned to different performance_category (TOPPER, EXCELLENT, GOOD, AVERAGE) & recommendation_type('REVISION','PRACTICE','CHALLENGE')
   - We will Capture the Uses of the Questions, where it has been used ('QUIZ','ASSESSMENT','EXAM')
   - We will be creating Questions Using AI in background
   - W can Import Questions from Excel and Export into Excel as well to provide to Teacher for Review
    
    
    
3. Quiz Creation	
   - Create a Quiz which will be having multipal Questions allign to it. 
   - Teacher can assign Question of his choice to a Quiz
   - Quiz will be directly allign with Class, Subject, Topic, Sub-topic, Mini-Topic, Sub-Mini Topic, Micro Topic
   - Teacher can schedule different Quizes to be assigned to different group of Students of the same class+Section (On the basis of their Capability/Performance)
   - Normally Quizes will be automatically Assigned to a Particuler Class+Section when Teacher will Update status of Alligned Topic/Sub-Topic/Mini-Topic to "Completed"
   - Quizes can be scheduled on a particuler date also.
   - Quizes can be configured, whether Question Marks will shown or not, Whether Result will be published after Quiz Completed or not.
   - Quizes will have Multipal Parameters (Mannual Publish the Quiz, Publish Result, Will have Negetive Marking, Show Marks of Every Question, Random Quest. Order etc.)
   - Quizes will have Maximum Time Duration Allowed, Allowed Attempts, Pssing Percentage.
   - Quizes Result can be Published On a Scheduled Date
   - Quize will have Text Box (Supported by TEXT','HTML','MARKDOWN','LATEX','JSON') To show Student the detail about Quiz
   - We will Capture All Possible Behavioral Parameters of the Student while attempting to the Quiz & Assessments for later Predictive Analytics. Examples -
      - How long he took to answer every Question. This should be Captured Subject/Lesson/Topic/Sub-Topic/Mini Topic/Sub-Mini Topic/Micro Topic wise.
      - Whether he came back to Review His Answer.
      - Whether He changed his Asnwer, if yes then How Many times he changed the Answer.
      - Any other Parameters which can be usefull for Predictive Analytics.
   - If any Student's Performance Category is set to be reassign test (slb_performance_categories.auto_retest_required=True) then System will generate a quiz for same Topic and assign it to the Student.
   - Every Topic/Sub-Topic/Mini-Topic/Sub-Mini Topic/Micro Topic/Sub-Micro Topic/Nano Topic/Ultra Topic will be alligned with 1 or more Quiz.
   - Quiz will have Ordinal and System will assign Quiz as er the Ordinal Number.
   - Different Group of Students can be Assigned Different Quizes for the same Topic/Sub-Topic/Mini-Topic/Sub-Mini Topic/Micro Topic/Sub-Micro Topic/Nano Topic/Ultra Topic
   - Questions which are available for Quiz (qns_questions_bank.for_quiz) only will be used in Quiz.
   - Performance will be rated Automatically by using configuration provided in table (slb_performance_categories)
   - Quiz may have Timer Condition (Time Allocated to complete the Quiz)
    
    
4. Quest Creation	
   - All the Conditioned Mentioned in Quiz will be alligned to Quest as well. Additionaly below condition will also be applicable for Quest.
   - Quest may have Descriptive type Question. The Answer of Descriptive Questions will be checked & provided Marks by Teacher.
   - Learning Quest will be Assigned on completion of a Major Topic or Lesson
   - Quest can be created to cover more then one Lesson to check how prepare a class is for upcomming Unit Term/Half yearly/Yearly Exam?
   - We will Capture All Possible Behavioral Parameters of the Student while attempting to the Quest for Predictive Analytics as mentioned in Quiz.
   - Result will be Published on Scheduled Date as configured while Creating Quest
   - Performance will be rated Automatically by using configuration provided in table (slb_performance_categories)
   - Quest may have Timer Condition (Time Allocated to complete the Quest)
    
5. Exam (Online)	
   - All the Conditions Available in Quest & Quiz.
   - School can use App to conduct Online Exam to Replace Offline Unit Term Exam (as per the direction of NEP)
   - This will be a Combination of MCQ & Descriptive Type Questions.
   - Checking & Marking for Descriptive Type Questions will be done by Teacher.
   - Questions which are available for Quiz (qns_questions_bank.for_exam) only will be used in Exam.
   - Result will be Published on Scheduled Date as configured while Creating Exam
   - Grade and Division will be Calculated Automatically by System on the basis of the Configuration provided in Table (slb_grade_division_master)
   - Performance will be rated Automatically by using configuration provided in table (slb_performance_categories)
   - Exam may have Timer Condition (Time Allocated to complete the Exam)
   - Result Card can be created for Every Student for All Assessment Type
     
6. Student Attempt	
   - Student will be abl to See all Due Quiz, Quest & Exam on his Dashboard and can Attempt from there.
   - Student ill be able to See Result after Compling Quiz/Quest/Exam if allowed by Admin.

Your Mission:
 - First parse the above requirements to have detaied understanding on the Requirement.
 - Then Parse attached DDL which is my current database schema design.
 - Then perform a deep research to find out what all possible features are available in LMS Application of other reknowed LMS & LXP Providers.
 - Then Perform a deep Reserch on NEP 2020 Guidelines for School Management System and NEP Holistic Report Card.
 - After all above steps I want you to generate a detailed Requirement Document by enhancing the Requirement Detail of LMS Module I have provided above.
 - Add all the features from other LMS Applications and then generate a detailed Requirement Document which should cover all required fuctionalties for all LMS Modules including but not limited to all 6 Sub-Modules.
 - The Final Document should be Grouped into Module, Sub-Module, Fuctionalities and should also cover Deatil of the Fuctionalities (like what is the use of that feature and how it will be used, who will perform that activity).

I want you to provide me a detailed requirement for all 6 Sub-Modules by enhancing the above requirements with more details and examples.

The Requirement should meet below principles:

1) Requirement should be Grouped logically into Modules, Sub-Modules, Functionalities by thinking deeply on grouping the fuctionalities.
2) Requirement should be precise, technically correct, AI input ready, and formatted cleanly in Markdown with Example.
3) Provide detail what is the use of that feature and how it will be used, who will perform that activity.

Save the output file as a new excel file.
