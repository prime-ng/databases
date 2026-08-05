# List of Modules
=================

```
┌──────────────────────────┬──────┬────────┬────────────────────────────┬──────────────────────┬──────────────────────────────┐
│ MODULE_NAME              │ CODE │ PREFIX │ FOLDER_NAME                │ REVIEW_FOLDER        │ DDL_FILE_NAME                │
├──────────────────────────┼──────┼────────┼────────────────────────────┼──────────────────────┼──────────────────────────────┤
│ Accounting               │ ACC  │ acc_   │ Accounting                 │ Accounting           │ Accounting_DDL_              │
│ AdmissionManagement      │ ADM  │ adm_   │ Admission                  │ Admission            │ Admission_DDL_               │
│ BehaviouralAssessment    │ BHA  │ bha_   │ BehaviouralAssessment      │ N/A                  │ BehaviouralAssess_DDL_       │ *
│ Billing                  │ BIL  │ bil_   │ Billing                    │ N/A                  │ Billing_DDL_                 │
│ Cafeteria                │ CAF  │ caf_   │ Cafeteria                  │ Cafeteria            │ Cafeteria_DDL_               │
│ Certificate              │ CRT  │ crt_   │ Certificate                │ N/A                  │ Certificates_DDL_            │ *
│ CommonChat               │ COM  │ cht_   │ CommonChat                 │ N/A                  │ CommonChat_DDL_              │ *
│ Complaint                │ CMP  │ cmp_   │ Complaint                  │ Complaint            │ Complaint_DDL_               │
│ Dashboard                │ DSH  │ dsh_   │ Dashboard                  │ N/A                  │ N/A                          │ *
│ Documentation            │ DOC  │ doc_   │ Documentation              │ N/A                  │ N/A                          │ *
│ EventEngine              │ EVT  │ sys_   │ EventEngine                │ N/A                  │ EventEngine_                 │ *
│ Feedback                 │ FBK  │ fbk_   │ Feedback                   │ N/A                  │ Feedback_ddl_                │ *
│ FrontOffice              │ FOF  │ fof_   │ FrontOffice                │ FrontOffice          │ FrontOffice_DDL_             │
│ GlobalMaster             │ GLB  │ glb_   │ GlobalMaster               │ Dropdown             │ _global_db_                  │ *
│ Hostel                   │ HST  │ hst_   │ Hostel                     │ N/A                  │ Hostel_DDL_                  │
│ Hpc                      │ HPC  │ hpc_   │ Hpc                        │ HPC                  │ HPC_DDL_                     │
│ HrStaff                  │ HRS  │ hrs_   │ HrStaff                    │ HrStaff              │ HrStaff_Payroll_DDL_         │
│ Inventory                │ INV  │ inv_   │ Inventory                  │ Inventory            │ Inventory_DDL_               │
│ Library                  │ LIB  │ lib_   │ Library                    │ Library              │ Library_ddl_                 │
│ LmsExam                  │ EXM  │ lms_   │ LmsExam                    │ Exam                 │ LmsExam_DDL_                 │
│ LmsHomework              │ HMW  │ lms_   │ LmsHomework                │ Homework             │ LmsHomework_DDL_             │
│ LmsQuests                │ QST  │ lms_   │ LmsQuests                  │ LmsQuests            │ LmsQuest_DDL_                │
│ LmsQuiz                  │ QUZ  │ lms_   │ LmsQuiz                    │ LmsQuiz              │ LmsQuiz_DDL_                 │
│ Maintenance              │ MNT  │ mnt_   │ Maintenance                │ N/A                  │ Maintenance_DDL_             │ *
│ MarksheetGeneration      │ MSH  │ msh_   │ MarksheetGeneration        │ MarksheetGeneration  │ MarksheetGeneration_DDL_     │ 
│ Notification             │ NTF  │ ntf_   │ Notification               │ Notification         │ Notification_DDL_            │
│ ParentPortal             │ PPT  │ ppt_   │ ParentPortal               │ ParentPortal         │ ParentPortal_DDL_            │
│ Payment                  │ PAY  │ pmt_   │ Payment                    │ Payment              │ N/A                          │
│ Prime                    │ PRM  │ prm_   │ Prime                      │ Prime                │ _prime_db_                   │
│ PrimeCore                │ PCO  │ pco_   │ PrimeCore                  │ N/A                  │ PrimeCore_DDL_               │ *
│ PTM                      │ PTM  │ ptm_   │ PTM                        │ N/A                  │ PTM_DLL_                     │
│ QuestionBank             │ QNS  │ qns_   │ QuestionBank               │ QuestionBank         │ LmsQuestionBank_DDL_         │
│ Recommendation           │ REC  │ rec_   │ Recommendation             │ N/A                  │ Recommendation_DDL_          │ *
│ Scheduler                │ SDL  │ sdl_   │ Scheduler                  │ N/A                  │ Scheduler_ddl_               │ *
│ SchoolSetup              │ SCH  │ sch_   │ SchoolSetup                │ N/A                  │ SchoolSetup_DDL_             │ *
│ SmartTimetable           │ STT  │ tt_    │ SmartTimetable             │ N/A                  │ Timetable_DDL_               │
│ StandardTimetable        │ TTS  │ tts_   │ StandardTimetable          │ StandardTimetable    │ Timetable_DDL_               │
│ StudentFee               │ FIN  │ fee_   │ StudentFee                 │ StudentFee           │ StudentFee_DDL_              │
│ StudentPortal            │ STP  │ stp_   │ StudentPortal              │ StudentPortal        │ StudentPortal_DDL_           │
│ StudentProfile           │ STD  │ std_   │ StudentProfile             │ StudentProfile       │ StudentProfile_DDL_          │
│ Syllabus                 │ SLB  │ slb_   │ Syllabus                   │ Syllabus             │ Syllabus_DDL_                │
│ SyllabusBooks            │ SLK  │ slb_   │ SyllabusBooks              │ SyllabusBooks        │ SyllabusBooks_DDL_           │
│ SystemConfig             │ SYS  │ sys_   │ SystemConfig               │ SystemConfig         │ _tenant_db_                  │
│ Template                 │ TMP  │ tmp_   │ Template                   │ Template             │ Template_DDL_                │
│ TenantCore               │ TCO  │ tco_   │ TenantCore                 │ N/A                  │ TenantCore_DDL_              │ *
│ TimetableFoundation      │ TTF  │ ttf_   │ TimetableFoundation        │ TimetableFoundation  │ Timetable_DDL_               │
│ Transport                │ TPT  │ tpt_   │ Transport                  │ Transport            │ Transport_DDL_               │
│ Vendor                   │ VND  │ vnd_   │ Vendor                     │ Vendor               │ Vendor_DDL_                  │
└──────────────────────────┴──────┴────────┴────────────────────────────┴──────────────────────┴──────────────────────────────┘
```


## Column notes

- **REVIEW_FOLDER** = the sub-folder under `prime_testing/Doc_Analysis/4-TC_List_Requirement_Review/` holding this module's reviewed `Module_Requirement/` + `TC_List/` inputs. It is often **NOT** equal to `MODULE_NAME`/`FOLDER_NAME` (business-area naming), so agents MUST resolve it from this column — never assume the review folder equals the module name.
  - Aliases where they differ: `LmsExam → Exam`, `LmsHomework → Homework`, `Hpc → HPC`, `Admission Mgmt. → Admission`, `GlobalMaster → Dropdown`.
  - `N/A` = no reviewed TC inputs exist for that module yet (out of scope for the current generation batch).

## Special cases

- **Dropdown (REVIEW_FOLDER `Dropdown` on the GlobalMaster row):** These reviewed inputs self-identify as **Module `DropDown`, CODE `DD`, prefix `dd_`**, DB scope **CENTRAL** (`sys_dropdown_*`), URL `/global-master/dropdown`. Screens span **GlobalMaster** (`DropdownController`, `DropdownMgmtController`) and **Prime** (`DropdownNeedController`). Because the TcList files carry their own `dd_`/`DD` identity, the Test-Script-Generator's rule "filename prefix = registry PREFIX" needs a **`dd_` override** for this folder (do NOT emit `glb_*`). *(Open decision: keep as override, or add a dedicated `DropDown` registry row.)*
- **Recommendation (REVIEW_FOLDER `N/A`):** Recommendation is the **verified GOLD reference** for test output (`prime_testing/tests/Browser/Modules/Recommendation/...`), not a generation target — it has no `4-TC_List_Requirement_Review/Recommendation/` input by design.



## Missing Developer Review
===========================

### Assigned to Sameer
----------------------
BehaviouralAssessment
Certificate
CommonChat
GlobalMaster
Recommendation
SchoolSetup


### Assigned to Tarun
---------------------
Maintenance
PrimeCore
TenantCore


### On Hold / Under Development
-------------------------------
Dashboard
Documentation
EventEngine
Feedback
Scheduler