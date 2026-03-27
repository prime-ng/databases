# Process Flow - LMS
====================

Below is the Complete process flow of Complete Learning Management System :
- At the time of School Onboarding Prime (Service Provider) will get all the information from Tenant (School) related to :
    - How many Class School has - This will be feed into Class Setup Module `sch_classes`. Captured in `SchoolSetup` Module
    - How many Sections are there in Every Class - This also will be feed to Class Setup Module `sch_sections` & `sch_class_section_jnt`. Captured in `SchoolSetup` Module
    - What All type of Board School have - Stored into `sch_board_organization_jnt`
    - Which all Books School teach to each Class for Every Subjects. This info captured into `SyllabusBooks` Module
    - We will be Capturing Complete Syllabus Detail in `Syllabus` Module Like Lesson, Topic, Sub-Topic, Mini Topic etc. which will be alligned with `SyllabusBooks` Module
    - We will be creating Question in `QuentionBank` Module which will be alligned to `Syllabus` Module
    - Then we be creating Homework in `LmsHomework` Module, which will be assigned to the a particuler Section of the Class whome that Homework was created for.
    - We will also create Quiz in `LmsQuiz` Module