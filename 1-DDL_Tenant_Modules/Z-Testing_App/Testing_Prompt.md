# Prompt for Testing_App
========================

I am creating a small Project to Automate my Testing for my Prime-AI App. I want you create a complete project to automate the entire Testing process and capture all the data to for all below fuctionalities :

## Environment Detail:
- My Application is belongs to `/Users/bkwork/Herd/prime_ai`
- This Testing App will reside in a separate folder `/Users/bkwork/Herd/prime_ai_testing`
- At present all the Test case scripts, Screenshot, Test result reports etc. reside under folder `/Users/bkwork/Herd/prime_ai/tests` but I want it to be moved into new Project `prime_ai_testing`
- Read the entire folder `/Users/bkwork/Herd/prime_ai/tests` to understand which type of file located in which folder.
- Read AI_Brain for all app related Info and Paths.

## High Level App Functionalities:
- Below are the functionalities which new `testting_app` should perform :
  - Application should read all the Module's Name from folder `/Users/bkwork/Herd/prime_ai/Modules` and add those into a a Module in `prime_ai_testing`
  - Every Module is having category, Main Menus, Sub Menus which are directly linked a view and Every View 9Screen) may have multipal Tabs. Every Tab manage a different Fuctionality e.g.
    In Category (School Setup) -> Main Menu(syllabus Mgmt.) -> Sub Menu(Syllabus Master) and then Syllabus Master is having 8 tabs : Lessons, Topic Types, Topics, Competency Types, Competencies, Topic-Competency, Prformance Categories, Grade Divisions Master.
  - We have separate separate TestCase File for every Tab like for Tab(Lesson) File (/Users/bkwork/Herd/prime_ai/tests/Browser/Modules/Syllabus/Lesson/LessonPlanningTest.php), For Tab(Topic Types) File (/Users/bkwork/Herd/prime_ai/tests/Browser/Modules/Syllabus/TopicTypes/requirements.md) and so on.
  App should show me all the Module name, once I select Module then it should show me All the Folders of Screens which may belongs to Main Menu/Sub Menu/Tabs and then it should  showcase all the TestCases Names from the TestCase File.
  - I can select all or selected TestCases from the List and then Click Run Button to Execute selected TestCases.
  - App should capture complete information which all TestCases I have Run, on date & Time and what was the Test Result of those TestCases.
  - App should keep the entire hisoty of the TestCase Run for analysis
  - It should capture all possible Information like Execute_by, date, Time, Run Duration, Test Result etc.
  - If any TestCase Failed then it should Capture Screenshot of it and allign the Screenshot Path with the TestCase Entry Log.
- App should be capable to provide detailed Analytical Reports for Testing History.
- It should facilitate to create new TestCases and capture them in the Process.
- Add if you find any other information which can be usefull to Automate the entire Testing Process.

## Your Goal
- First Read all the Files mentioned in "Environment Detail" section.
- Read a preliminary version of ddl from file "/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/test_runner_db.sql"
- Then create a Testing Application Requirement in File "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/Design/testing_requirement.md"
- Onc you are done with creation of "testing_requirement.md", wait for my approval to move on next step.
- Create a DDL Schema for "Testing_App" in File "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v1.sql"

---------------------------------------------------------------------------------------------
I want to add few more fuctionalities into Testing Module. First read DDL Schema from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v4.sql" and Requirement Document from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/Design/testing_requirement_v1.md". Below are the fuctionalities which I want to add into Testing Module :
- As we will be enhancing Prime-AI app regulerly, therefor we need to add new Test Cases to Test New Enhanced Functionalities.
- Add Fuctionality to add any New test Case Requirement.
- When Testing team will Create New required Test Cases , they can mark the Status of TEst Case Requirement to Completed.
- When Test Case will Fail (Find Bug), Application should have fuctionality to assign Bug Fixing to the developer by picking from User table.
- When Developer will Complete the Bug Fixing, he will mark Status of Bug Fixing to "Completed"
- Once Bug fixing done, App will Automatically Re-Schedule the Test Case to Run all the Test cases for that Screen and it Failes again then again it will assigne to the same Developer and this loop will continue till All the Test Cases will Pass for that Particuler Screen.
- Add any other Fuctionality if I missed any in the Requirement Document first and create a New Requirement Doc as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/Design/testing_requirement_v2.md
- After Creating "testing_requirement_v2.md", Generate DDL Schema to accomodate all new Requirements and create a New DDL file as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Z-Testing_App/DDL/testing_ddl_v5.sql"
