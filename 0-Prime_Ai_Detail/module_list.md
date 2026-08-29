# List of Modules
=================

```
┌──────────────────────────┬──────┬────────┬────────────────────────────┬──────────────────────┬──────────────────────────────┐
│ MODULE_NAME              │ CODE │ PREFIX │ FOLDER_NAME                │ REVIEW_FOLDER        │ DDL_FILE_NAME                │
├──────────────────────────┼──────┼────────┼────────────────────────────┼──────────────────────┼──────────────────────────────┤
│ Accounting               │ ACC  │ acc_   │ Accounting                 │ Accounting           │ Accounting_DDL_              │
│ AdmissionManagement      │ ADM  │ adm_   │ Admission                  │ Admission            │ Admission_DDL_               │
│ BehaviouralAssessment    │ BHA  │ bha_   │ BehaviouralAssessment      │ BehaviouralAssessment │ BehaviouralAssess_DDL_      │ 
│ Billing                  │ BIL  │ bil_   │ Billing                    │ Billing              │ Billing_DDL_                 │
│ Cafeteria                │ CAF  │ caf_   │ Cafeteria                  │ Cafeteria            │ Cafeteria_DDL_               │
│ Certificate              │ CRT  │ crt_   │ Certificate                │                      │ Certificates_DDL_            │ *
│ CommonChat               │ COM  │ cht_   │ CommonChat                 │                      │ CommonChat_DDL_              │ **
│ Complaint                │ CMP  │ cmp_   │ Complaint                  │ Complaint            │ Complaint_DDL_               │
│ Dashboard                │ DSH  │ dsh_   │ Dashboard                  │ N/A                  │ N/A                          │ *
│ Documentation            │ DOC  │ doc_   │ Documentation              │ N/A                  │ N/A                          │ *
│ EventEngine              │ EVT  │ sys_   │ EventEngine                │ N/A                  │ EventEngine_                 │ *
│ Feedback                 │ FBK  │ fbk_   │ Feedback                   │ N/A                  │ Feedback_ddl_                │ *
│ FrontOffice              │ FOF  │ fof_   │ FrontOffice                │ FrontOffice          │ FrontOffice_DDL_             │
│ GlobalMaster             │ GLB  │ glb_   │ GlobalMaster               │ GlobalMaster         │ _global_db_                  │
│ Hostel                   │ HST  │ hst_   │ Hostel                     │ N/A                  │ Hostel_DDL_                  │
│ Hpc                      │ HPC  │ hpc_   │ Hpc                        │ HPC                  │ HPC_DDL_                     │
│ HrStaff                  │ HRS  │ hrs_   │ HrStaff                    │ HrStaff              │ HrStaff_Payroll_DDL_         │
│ Inventory                │ INV  │ inv_   │ Inventory                  │ Inventory            │ Inventory_DDL_               │
│ Library                  │ LIB  │ lib_   │ Library                    │ Library              │ Library_ddl_                 │
│ LmsExam                  │ EXM  │ lms_   │ LmsExam                    │ Exam                 │ LmsExam_DDL_                 │
│ LmsHomework              │ HMW  │ lms_   │ LmsHomework                │ Homework             │ LmsHomework_DDL_             │
│ LmsQuests                │ QST  │ lms_   │ LmsQuests                  │ LmsQuests            │ LmsQuest_DDL_                │
│ LmsQuiz                  │ QUZ  │ lms_   │ LmsQuiz                    │ LmsQuiz              │ LmsQuiz_DDL_                 │
│ Maintenance              │ MNT  │ mnt_   │ Maintenance                │                      │ Maintenance_DDL_             │ *
│ MarksheetGeneration      │ MSH  │ msh_   │ MarksheetGeneration        │ MarksheetGeneration  │ MarksheetGeneration_DDL_     │ 
│ Notification             │ NTF  │ ntf_   │ Notification               │ Notification         │ Notification_DDL_            │
│ ParentPortal             │ PPT  │ ppt_   │ ParentPortal               │ ParentPortal         │ ParentPortal_DDL_            │
│ Payment                  │ PAY  │ pmt_   │ Payment                    │ Payment              │ N/A                          │
│ Prime                    │ PRM  │ prm_   │ Prime                      │ Prime                │ _prime_db_                   │
│ PTM                      │ PTM  │ ptm_   │ PTM                        │ N/A                  │ PTM_DLL_                     │
│ QuestionBank             │ QNS  │ qns_   │ QuestionBank               │ QuestionBank         │ LmsQuestionBank_DDL_         │
│ Recommendation           │ REC  │ rec_   │ Recommendation             │ Recommendation.      │ Recommendation_DDL_          │
│ Scheduler                │ SDL  │ sdl_   │ Scheduler                  │ N/A                  │ Scheduler_ddl_               │ *
│ SchoolSetup              │ SCH  │ sch_   │ SchoolSetup                │ SchoolSetup          │ SchoolSetup_DDL_             │
│ SmartTimetable           │ STT  │ tt_    │ SmartTimetable             │ SmartTimetable       │ Timetable_DDL_               │
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
