 Review all the REquirement Files in Folder "2-Requirement_Module_wise/2-Detailed_Requirements/V1" and enhance them whereever require. in file   
  "2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/HRS_HrStaff_Requirement.md" you mention "HrStaff is distinct from the Payroll module (`prl_*`)", whcih is not True 

  ---

I have asked you  to create Module wise Requirement Documents using prompt "databases/2-Requirement_Module_wise/Requirement_Creation_Prompts/Consolidated_Prompt_for_Opus/Module_Requirement_Generation_Prompt_v3.md". I used Claude Sonnet to create those Requirements because Opus was taking too much tokans and was not able to complete the cycle.
Now I have created an enhanced RBS file "3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v4.0.md" and I wanted to created new version of ERquirement files for all the Modules on the basis of my new RBS. Provide a Prompt for the same which create all new File in folder "databases/2-Requirement_Module_wise/2-Detailed_Requirements/V2". save that Prompt in folder "databases/2-Requirement_Module_wise/Requirement_Creation_Prompts/Consolidated_Prompt_for_Opus"

In HRS (HrStaff) Module File "2-Requirement_Module_wise/2-Detailed_Requirements/V2/HRS_HrStaff_Requirement.md", you have mentioned All items related to Payroll (prl_) Out of Scope But I wanted to keep a single Module for HR & Payroll Both. So update that file (HRS_HrStaff_Requirement.md) as `HRS_HrStaff_Requirement_v2.md` and incude all Payroll Related Task mentioned in the lates RBS "3-Project_Planning/1-RBS/PrimeAI_Complete_Spec_v2.md". Also consider additional steps (if anything left in latest RBS) to make it complete `HR & Payroll` Module with all possible requirement of a school to manage HR & Payrol Department.

---------------------------------------------------------------------------------------------

We have already created most of the functionality of LMS Moduel. To understand the complete requirement of LMS read all the Files from folder "5-Work-In-Progress/2-In-Progress/LMS/v4" and to understand what has been already developed read all the module mentioned below :

## Modules Detail

| # | Module | Path | Table Prefix | Route Prefix |
|---|---|---|---|---|---|
| 1 | Syllabus | `Modules/Syllabus/` | `slb_*` | `/syllabus/*` |
| 2 | LmsQuiz | `Modules/LmsQuiz/` | `lms_quizzes*` | `/lms-quize/*` |
| 3 | LmsQuests | `Modules/LmsQuests/` | `lms_quests*` | `/lms-quests/*` |
| 4 | LmsExam | `Modules/LmsExam/` | `lms_exam*` | `/lms-exam/*` |
| 5 | LmsHomework | `Modules/LmsHomework/` | `lms_homework*` | `/lms-home-work/*` |
| 6 | QuestionBank | `Modules/QuestionBank/` | `qns_*` | `/question-bank/*` |

Read "StudentPortal" Module Requirement from "databases/2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md".

Now I want to work on StudentAttemp Functionality in StudentPortal Module. For that I have created initial version of DDL Schema at "databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v1.sql". I want you to review StudentAttemp ddl and create an enhanced schema as "databases/1-DDL_Tenant_Modules/55e-LMS_StudentAttempts/StudentAttempt_ddl_v2.sql" by incorporating all the required tables. Please create a complete DDL Schema not the the changes only in the new DDL schema file.

Provide me a Prompt for 

---------------------------------------------------------------------------------------------

All AI Brain files updated. Now the final report.

  ---
  Deep Audit Final Report — 2026-04-02

  Modules with Hidden Gaps (Claimed % vs Actual %)

  ┌────────────────┬───────────┬─────────┬───────┬───────────────────────────────────────────────────────────────────────┐
  │     Module     │ Previous  │ Actual  │ Delta │                            Primary Reason                             │
  │                │     %     │    %    │       │                                                                       │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ SchoolSetup    │ 55%       │ 40%     │ -15   │ Primary controller all stubs; 3 routes → missing methods; backup      │
  │                │           │         │       │ files inflate count                                                   │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ StudentProfile │ 50%       │ 30%     │ -20   │ Gate facade not imported (auth never fires); module routes = 0%;      │
  │                │           │         │       │ validation commented out                                              │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ Transport      │ 55%       │ 40%     │ -15   │ Module routes = 0 tenant; tested.* typo blocks controller; PII        │
  │                │           │         │       │ unencrypted                                                           │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ Complaint      │ 40%       │ 30%     │ -10   │ 6 routes → non-existent methods; dropdown keys = dummy_table_name; 3  │
  │                │           │         │       │ stub controllers                                                      │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ Notification   │ 50%       │ 35%     │ -15   │ ALL Gate calls use wrong prefix (prime.* on tenant) = 100%            │
  │                │           │         │       │ auth-broken                                                           │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ Dashboard      │ 35%       │ 25%     │ -10   │ Zero auth; 40+ queries via Schema introspection; all sub-dashboards   │
  │                │           │         │       │ empty                                                                 │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ Scheduler      │ 40%       │ 25%     │ -15   │ No tenancy middleware at all; zero auth; broken redirect              │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ LmsExam        │ 65%       │ 58%     │ -7    │ dd($e) blocks rollback; missing toggleStatus; stubs                   │
  ├────────────────┼───────────┼─────────┼───────┼───────────────────────────────────────────────────────────────────────┤
  │ LmsQuests      │ 60%       │ 52%     │ -8    │ Missing getTopics(); Gate still commented; no transactions            │
  └────────────────┴───────────┴─────────┴───────┴───────────────────────────────────────────────────────────────────────┘

  ---
  Top 5 Security Issues

  1. is_super_admin mass-assignable in 3 locations (Prime User $fillable, SchoolSetup UserController, StudentProfile
  StudentController) — any admin can escalate to super-admin
  2. 13 seeder routes with NO auth (tenant.php:3025-3038) — any unauthenticated visitor can wipe and reseed entire tenant
  database
  3. EnsureTenantHasModule applied to only 1 of 26 module groups — any Basic Plan tenant accesses all Enterprise features
  4. StudentPortal IDOR in proceedPayment() — any student can pay another student's invoice by passing arbitrary payable_id
  5. Notification: Tenant::all() inside tenant context + prime.* Gate prefix on all controllers — cross-tenant data leak +
  100% auth-broken

  ---
  Top 5 Performance Issues

  1. TimetableFoundation: ClassWorkingDayController — up to 10,000 upserts in a single web request (no queue)
  2. TimetableFoundation: ActivityController::generateActivities — 400+ updateOrCreate calls synchronously
  3. SmartTimetable: index() — 14+ unbounded queries including full Activity table scan on every dashboard load
  4. Dashboard: 40+ queries per page via Schema::getColumnListing() introspection on every count
  5. Library: User::all() in 20+ controller methods — full table scan on every form load

  ---
  Overall Project Completion (Recalculated)

  ┌─────────────────┬──────────────────────────────────────────────────────────────────────────────────────┬────────────┐
  │    Category     │                                       Modules                                        │ Weighted   │
  │                 │                                                                                      │    Avg     │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼────────────┤
  │ Central (5)     │ Prime 65%, GlobalMaster 50%, SystemConfig 40%, Billing 55%, Documentation 60%        │ 54%        │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼────────────┤
  │ School Admin    │ SchoolSetup 40%, StudentProfile 30%, Transport 40%, StudentFee 50%, Vendor 53%,      │ 45%        │
  │ (6)             │ StudentPortal 55%                                                                    │            │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼────────────┤
  │ LMS + Academic  │ Syllabus 55%, SyllabusBooks 55%, QuestionBank 45%, LmsExam 58%, LmsQuiz 72%,         │ 53%        │
  │ (8)             │ LmsHomework 52%, LmsQuests 52%, Recommendation 39%                                   │            │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼────────────┤
  │ Timetable + HPC │ SmartTT 58%, TT Foundation 65%, StandardTT 5%, Hpc 59%, Library 45%                  │ 46%        │
  │  (5)            │                                                                                      │            │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼────────────┤
  │ Supporting (5)  │ Complaint 30%, Notification 35%, Payment 45%, Dashboard 25%, Scheduler 25%           │ 32%        │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼────────────┤
  │ Accounting (1)  │ 40%                                                                                  │ 40%        │
  ├─────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼────────────┤
  │ Scaffolded (7)  │ Admission 18%, Cafeteria 18%, Certificate 15%, FrontOffice 12%, HrStaff 20%,         │ 17%        │
  │                 │ Inventory 15%, EventEngine 20%                                                       │            │
  └─────────────────┴──────────────────────────────────────────────────────────────────────────────────────┴────────────┘

  Overall Project Completion: ~42% (weighted by module count, down from previously claimed ~55%)

  The 13-point gap is primarily driven by: security issues demoting functional code, production-fatal route bugs, and stubs
  masquerading as complete controllers.
  
  