# Temporary File for writing - Claude Prompts
=============================================

I want you to create a screen design .md file for Accounting Module start with Voucher Entry Screen similer to Tally. To understand what type of Voucher Entry screen Tally is having you can serch on below url :
https://help.tallysolutions.com/voucher-types-tally/
The DDL file for accounting Module is "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Accounting/Accounting_DDL_v4.sql"
Create a Scree File as "old_db/1-New_Enhancements/Accounting/ScreenDesign_v1.md"

-----------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
I am creating a Testing Application to manage End to End Testing Fuctionality for my Prime-Ai Application. I have an initial version of BRD (Business Requirement Document) for that. I have also get created a Solution document using an AI and then I have created a DDL Schema also, which I am refining right now. I want you to first read all below documents : 
- BRD Doc : /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Testing/Design/TestingApp_BRD_v1.md
- Solution Doc : /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Testing/Design/Solution_Design_v1.md
- Current DDL : /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Testing/testing_DDL_v6.7.sql
- Previous Version DDL : /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Testing/testing_DDL_v6.5.sql

Now when you have understood my complete requirement and know what I have created so far. I want to to provide me below output :
- Provide an refined BRD as - TestingApp_BRD_v2.md. Add a section "Enhancements" in the last to proide your additional fuctionalities suggesions.
- Provide a detailed Solution Document as - Solution_Design_v2.md
- Provide a Refined & Enhanced DDL as testing_DDL_v7.0.sql

Save all output files into "old_db/1-New_Enhancements/Testing/Design/" folder only.

-----------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
Yesterday I have given you below prompt but you could complete only 2 tasks "Provide an refined BRD" & "Provide a detailed Solution Document". Both files are saved in the designated folder "old_db/1-New_Enhancements/Accounting/Design". When you were working on the last tasks my tokan quota got reached and the process got stuck in between. Since the waiting period was long I put my laptop on sleep mode and go away. in-between because of some system update my laptop restarted automatically and the entire session went off. Now I want you to understand the requirement and what has been delivered and then finish the remaing work "Provide a Refined & Enhanced DDL". Since you started working on 3rd task generated an incomplete file as "Accounting_DDL_v4.4.sql" in the folder "/Accounting/Design". Now use the same prompt but save the new DDL as "old_db/1-New_Enhancements/Accounting/Design/Accounting_DDL_v4.5.sql.

### Yesterday Prompt
I am Enhancing the Accounting Module for my Prime-AI App. Accounting Module is having most of the features similer to the famous accounting software "Tally". I have an initial version of BRD (Business Requirement Document) for that. I have created a DDL Schema also, which I am refining right now. I want you to first read below documents: 
- BRD Doc : /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Accounting/Design/Accounting_BRD_v1.md
- Current DDL : /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Accounting/DDL/Accounting_DDL_v4.3.sql
- Previous Version DDL : all previous version are there in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-New_Enhancements/Accounting/DDL"

Now when you have understood my complete requirement and know what I have created so far. I want to to provide me below output :
- Provide an refined BRD as - Accounting_BRD_v2.md. Add a section "Enhancements" in the last to proide your additional fuctionalities suggesions.
- Provide a detailed Solution Document as - Solution_Design_v1.md
- Provide a Refined & Enhanced DDL as Accounting_DDL_v4.4.sql

Save all output files into "old_db/1-New_Enhancements/Accounting/Design" folder only.

-----------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
I am enhancing Behavioural Assessment Module for my Prime-Ai Application. I have an initial version of BRD (Business Requirement Document) for that. I have created a DDL Schema also, which I am refining right now. I want you to first read below documents : 
- BRD Doc : old_db/1-New_Enhancements/BehaviouralAssessment/Design/BehaviouralAssessment_BRD_v2.md
- Current DDL : old_db/1-New_Enhancements/BehaviouralAssessment/DDL/LMS_BehaviouralAssess_DDL_v2.sql

Now when you have understood my complete requirement and know what I have created so far. I want to to provide me below output :
- Provide an refined BRD as - Behavioural_Assess_BRD_v3.md. Add a section "Enhancements" in the last to proide your additional fuctionalities suggesions.
- Provide a detailed Solution Document as - Solution_Design_v2.md
- Provide a Refined & Enhanced DDL as Behavioural_Assess_DDL_v7.0.sql

Save all output files into "old_db/1-New_Enhancements/BehaviouralAssessment/Design" folder only.

-----------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
The Testing Module you have produced in my previous Prompt, where you have created 3 files as BRD, Solution Doc & DDL. I have observed that the now Testing app has become very big now, so I want to split it into 2 phases. Here are the high level phase wise breakdown of my Testing App : 

## Functionalities need to be covered in Phase 1:
- Application Configuration : To capture App level configuration parameters
- Machine Environment Profile : Capture System profile (OS Version, Browser Version etc.) to identify reason of test case failure
- user Profile management : To capture Who did what?
- Machine Profile for every user : To Distinguish between test case failure due to application defect or environment mismatch
- Catalog Management: Capture application Modules, Category, Main Menu, Sub-Menu, Tabs/screens to map test cases with those.
- Test Case Profile : TestCase List, Test Cases, Steps, Version, History, Duplication of TestCases, TestCase Releasing
- Test Case Execution: Manage Test Execution, Scope, Items, Steps, REsults, Artifacts, Summary, Logs, History
- Test Execution Scheduling : Schedule Test Execution on different machines for different modules/Screens/TestCases
- Comments Mgmt : Reviewer comments on Test Results
- Discovery : Sync Discovery Log, Run Discovery, Discover New Test Cases, Missing Module/Screens, Orphaned TestCases, TestCase Status Sync
- Test Execution History & Trending: View History and Trending of Test Cases
- Bug Management: Raise Bugs, Mark Known Bugs, Bug log, Bug result, Bug history, Bug fixing status, Re-test after bug fix, Relationships between bugs
- Export/Import Mgmt : Export TestCases and Test Results, Import TestCases and Test Results, Import Conflicts
- AI Analysis : Perform TestCases Analysis to identify impact analysis, TestCases Failure reason, Flaky TestCases, Consecutive Failures, AI Recommendations
- Notifications & Audit : Email/In-app notifications for test results, bug reports, and system events. Audit trail for all major actions.

## Functionalities need to be covered in Phase 2:
- Change Request Mgmt : Manage Enhancement/Changes into Application. Required to identify which all TestCases need to run after which change?
- Dependancy Mgmt.: Identify Module/Screen/Testcase's Dependancies and manage them. This will help to decide which all TestCases needs to run for a perticular change.
- Application Path Mapping : Capture info related path of different files (controler, route, model, etc.)
- Suites (Grouping of Test Cases) : Grouping of TestCases as per Modules/Sub-Modules/Tabs/Screens to execute Test Cases in a Group (like Regrassion Testing, Smoke Testing, Etc.)
- Git Ingestion Engine : To capture all Git related info like Commits,Branches,Tags,Files changed,etc. to map them with Test Cases.


## Important Changes :
I have made some changes in the DDL to make it more sutaible to my requirement (Deleted few Tables which are not in use, updated columns, added new tables and relationships etc). I have also added comments in the DDL to explain the changes that I have made or conditions which needs to be followed.

## Most Important change:
1. I have use `machine_code` & `ts_code` to make unique `test_case_code`. This is a major change from the version "1-New_Enhancements/Testing/testing_DDL_v7.0.sql" you have created. 
   - I implemented in table `tst_test_cases` as - `test_case_code` VARCHAR(21) GENERATED ALWAYS AS (CONCAT(`machine_code`,'_',`ts_code`,'_',LPAD(`tc_seq_number`, 3, '0'))) STORED,
   - Though `id` will be different in source & the system which import the data, `test_case_code` will be unique for each test case. which will help me to identify them uniquely in  the child tables like `tst_test_case_steps`, `tst_test_case_versions_history` and so on. This is really a BIG change and I think this is a very good change, which help me to keep `test_case_code` unique and consistent across all machines witout using uuid.
2. You can also see that `machine_code` is having info of user as well their machine id and same way `ts_code` is having info of Category, Main-Menu, Sub-Menu, Tab/Screen (4 Parts) and a Suffix for individual test case. 
   - Format is: C1_M1_S1_T1_tc001 where C1 = Category Code, M1 = Main Menu Code, S1 = Sub Menu Code, T1 = Tab/Screen Code, tc001 = Test Case Code.

## Below are some important changes I have made OR want to make in Tables:
### 1. Table Removed:
`tst_roles`, `tst_permissions` : Since my team is small, micro level permission management is not required. ENUM in User table is enough.
`tst_releases` : I have cover all the requirement in `tst_test_case_review`
### 2. New Table Added:
`tst_tc_required_list` : To keep track of Test Cases List (tc_list). Which basically contain list of required Test Cases for a Module/Tab/Screen and their creation status.
`tst_test_case_review` : To capture Review & Release of TestCases and the information of Reviewer and Approver.
### 3. Major Table modification for new Unique Coding System:
- Table-`tst_users` : 
    - Changed User_Code Format to use it as a key in Test Run (User Code format - 1st Character = First Letter of Role(A/Q/T/D/R/S) + 2 Char Simple Integer Number(e.g., "D01,D02,..D99,T01, etc.)
- Table-`tst_machines` :
    - Added column `machine_number` : Single Char Alphabate like (A,B,C,D etc)
    - Changed `machine_code` format. CONCAT(`owner_user_code`,`machine_number`). 4 Character Unique code which have user_code in it. During Test Case Run `machine_code`+ will be send to Test case

## Tasks you need to do:
- Read all 3 files you have created previously :
    - DDL (you generated) : old_db/1-New_Enhancements/Testing/testing_DDL_v7.0.sql
    - DDL (I Enhanced) : old_db/1-New_Enhancements/Testing/testing_DDL_v7.1.sql
    - BRD : old_db/1-New_Enhancements/Testing/TestingApp_BRD_v2.md
    - Solution Design : old_db/1-New_Enhancements/Testing/Solution_Design_v2.md
- Create a New solution design file as "Solution_Design_v3.md" to accomodate all above requirement.
- Create a New BRD file as "TestingApp_BRD_v3.md" to accomodate all above requirement.
- Create a New DDL file as "testing_DDL_v7.2.sql" to accomodate all above requirement.
- Implement new Coding system (`test_case_code`, `machine_code` & `ts_code`) as required and remove `id` based FK. This is a very important step to make the system more scalable and maintainable. 
- I have implemented the New Coding System in tc_list (`tst_tc_required_list`) and TestCase Creation (`tst_test_cases`, `tst_test_case_steps`,`tst_test_case_versions_history`, `tst_duplicate_test_case`,`tst_test_case_review`), you can use those as reference to implement in other tables.
- Must implement New Coding System as I have implemented in tc_list and TestCase Creation. 
- To understand my changes, you can take compare OLD DDL (testing_DDL_v7.0.sql) and my NEW Enhanced DDL (testing_DDL_v7.1.sql). Understand the changes in detail along with the comments I have added in (testing_DDL_v7.1.sql). Accordingly update/modify the tables in the new DDL file you have to generate.
- Carefully check all reference (Foreign Key references) tables and update them accordingly.
- Devide all 3 files (BRD, DDL, Solution Design) into 2 Phases : Phase1 and Phase 2, which you are going to create.

Let me know if you have any questions or need any clarification. Save all output files into "old_db/1-New_Enhancements/Testing/Design" folder only.

## Responce:
All three files are in 1-New_Enhancements/Testing/Design/.

┌───────────────────────┬───────┬─────────────────────────────────────────────┐
│         File          │ Lines │                   Content                   │
├───────────────────────┼───────┼─────────────────────────────────────────────┤
│ TestingApp_BRD_v3.md  │ 1,050 │ Requirements, every one marked [P1] or [P2] │
├───────────────────────┼───────┼─────────────────────────────────────────────┤
│ Solution_Design_v3.md │ 978   │ Design, with a table inventory by phase     │
├───────────────────────┼───────┼─────────────────────────────────────────────┤
│ testing_DDL_v7.2.sql  │ 3,738 │ 58 tables (44 P1 + 14 P2), 21 views, seeded │
└───────────────────────┴───────┴─────────────────────────────────────────────┘

Your coding system is implemented everywhere. Every test_case_id FK is now test_case_code VARCHAR(21) — run items, results, summary, bugs, suites, dependencies, path mappings, impact items, git commit files, coverage mapping, schedule targets. Same for ts_code (11), user_code (3), machine_code (4), module_code (5).

Answers to your two questions. tst_source_test_cases — not required, removed. It existed because two machines could both mint T0104010200/001; now they mint D02A_… and T01A_…, so both import cleanly and quarantine is unnecessary. What it was really deciding was equivalence, which is what your tst_duplicate_test_case already handles. tst_schema_version — you were right, removed. Laravel's migrations table plus one tst_app_settings row covers it, and the importer already compares tst_data_exports.schema_version.

One constraint your design imposes that I'd flag. MySQL forbids ON UPDATE CASCADE on a foreign key whose column feeds a generated column. So machine_code and ts_code FKs on tst_test_cases can only be ON DELETE RESTRICT — meaning a code can never be renamed once a test case exists. That's arguably a feature, but it makes registering a user, machine or screen a decision rather than a data-entry step. All five affected FKs verified as RESTRICT.

18 defects found in v7.1 — 8 of them stop the script executing. Indexes and FKs on columns that aren't declared (group_name, primary_role_code, created_by/updated_by/deleted_by on tst_users, tc_list_code, test_case_id in versions_history); a generated test_case_code on tst_test_runs built from an undeclared machine_code; deferred FKs to the deleted tst_releases/tst_roles; and two tables defined after the tables referencing them. Plus width drift — test_case_code was 21 on the parent and 20 on children, user_code was 3 and 10, ts_code 11 and 20. All listed in BRD §17 / SD §16.

Phase separation. No Phase-1 table has a foreign key into Phase 2. The five columns that will point at suites, impact analyses and change requests are declared in Phase 1 and left null; their FKs are added in Section 30. That keeps the Phase-2 upgrade a constraint addition rather than an ALTER on a multi-million-row results table.

Validated: 58 tables balanced, no forward FK references, no duplicate constraint/index names, every FK column type matches its parent, all deferred ALTERs target real columns, no view joins on tc.id.

Not verified: MySQL isn't installed here, so nothing was executed. Logged as OPEN-06 in both docs: the design assumes a foreign key may reference a STORED generated column. MySQL's documented restriction covers VIRTUAL columns only and all three are STORED with UNIQUE indexes, but confirm on first install — if a server rejects it, drop the GENERATED clause and have CodeFactory write the concatenated value; nothing else changes.

One thing worth your call: tcr_code pads the sequence to 4 digits (_0001) while test_case_code pads to 3 (_001). Both work, both are VARCHAR(21), and I implemented exactly as you specified — but the same position renders differently in the two codes for one test case. Logged as OPEN-01.

-----------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
 In DDL "1-New_Enhancements/Accounting/DDL/Accounting_DDL_v4.5.sql" you have used "del_marker" to make record really unique. But I am ok to keep 'code' & 'name' only UNIQUE, because there is no point to have same 'account_group' code or name created  again when you already have one in deleted stage. same applicable to category, ledger, cost_center, voucher_type, tax_type etc. so rather then keeping one extra field in so many tables, I would like to go with having 'code' & 'name' alone UNIQUE. Please make this change in the DDL and save it as "Accounting_DDL_v4.6.sql" in the same folder.

-----------------------------------------------------------------------------------------------------------------------------------------------
## Prompt:
