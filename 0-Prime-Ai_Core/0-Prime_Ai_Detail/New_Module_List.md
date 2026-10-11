# List of Modules
=================

```
┌───────────────────────┬──────┬───────┬────────┬───────────────────────┬───────────────────────┬──────────────────────────┐
│ MODULE_NAME           │ CODE │ CODE1 │ PREFIX │ FOLDER_NAME           │ REVIEW_FOLDER         │ DDL_FILE_NAME            │
├───────────────────────┼──────┼───────┼────────┼───────────────────────┼───────────────────────┼──────────────────────────┤
│ Accounting            │ ACC  │ Acc   │ acc_   │ Accounting            │ Accounting            │ Accounting_DDL_          │
│ AdmissionManagement   │ ADM  │ Adm   │ adm_   │ Admission             │ Admission             │ Admission_DDL_           │
│ BehaviouralAssessment │ BHA  │ Bha   │ bha_   │ BehaviouralAssessment │ BehaviouralAssessment │ BehaviouralAssess_DDL_   │
│ Billing               │ BIL  │ Bil   │ bil_   │ Billing               │ Billing               │ Billing_DDL_             │
│ Cafeteria             │ CAF  │ Caf   │ caf_   │ Cafeteria             │ Cafeteria             │ Cafeteria_DDL_           │
│ Certificate           │ CRT  │ Crt   │ crt_   │ Certificate           │                       │ Certificates_DDL_        │
│ CommonChat            │ COM  │ Com   │ cht_   │ CommonChat            │                       │ CommonChat_DDL_          │
│ Complaint             │ CMP  │ Cmp   │ cmp_   │ Complaint             │ Complaint             │ Complaint_DDL_           │
│ Dashboard             │ DSH  │ Dsh   │ dsh_   │ Dashboard             │ N/A                   │ N/A                      │
│ Documentation         │ DOC  │ Doc   │ doc_   │ Documentation         │ N/A                   │ N/A                      │
│ EventEngine           │ EVT  │ Evt   │ sys_   │ EventEngine           │ N/A                   │ EventEngine_             │
│ Feedback              │ FBK  │ Fbk   │ fbk_   │ Feedback              │ N/A                   │ Feedback_ddl_            │
│ FrontOffice           │ FOF  │ Fof   │ fof_   │ FrontOffice           │ FrontOffice           │ FrontOffice_DDL_         │
│ GlobalMaster          │ GLB  │ Glb   │ glb_   │ GlobalMaster          │ GlobalMaster          │ _global_db_              │
│ Hostel                │ HST  │ Hst   │ hst_   │ Hostel                │ N/A                   │ Hostel_DDL_              │
│ Hpc                   │ HPC  │ Hpc   │ hpc_   │ Hpc                   │ HPC                   │ HPC_DDL_                 │
│ HrStaff               │ HRS  │ Hrs   │ hrs_   │ HrStaff               │ HrStaff               │ HrStaff_Payroll_DDL_     │
│ Inventory             │ INV  │ Inv   │ inv_   │ Inventory             │ Inventory             │ Inventory_DDL_           │
│ Library               │ LIB  │ Lib   │ lib_   │ Library               │ Library               │ Library_ddl_             │
│ LmsExam               │ EXM  │ Exm   │ lms_   │ LmsExam               │ Exam                  │ LmsExam_DDL_             │
│ LmsHomework           │ HMW  │ Hmw   │ lms_   │ LmsHomework           │ Homework              │ LmsHomework_DDL_         │
│ LmsQuests             │ QST  │ Qst   │ lms_   │ LmsQuests             │ LmsQuests             │ LmsQuest_DDL_            │
│ LmsQuiz               │ QUZ  │ Quz   │ lms_   │ LmsQuiz               │ LmsQuiz               │ LmsQuiz_DDL_             │
│ Maintenance           │ MNT  │ Mnt   │ mnt_   │ Maintenance           │                       │ Maintenance_DDL_         │
│ MarksheetGeneration   │ MSH  │ Msh   │ msh_   │ MarksheetGeneration   │ MarksheetGeneration   │ MarksheetGeneration_DDL_ │
│ Notification          │ NTF  │ Ntf   │ ntf_   │ Notification          │ Notification          │ Notification_DDL_        │
│ ParentPortal          │ PPT  │ Ppt   │ ppt_   │ ParentPortal          │ ParentPortal          │ ParentPortal_DDL_        │
│ Payment               │ PAY  │ Pay   │ pmt_   │ Payment               │ Payment               │ N/A                      │
│ Prime                 │ PRM  │ Prm   │ prm_   │ Prime                 │ Prime                 │ _prime_db_               │
│ PTM                   │ PTM  │ Ptm   │ ptm_   │ PTM                   │ N/A                   │ PTM_DLL_                 │
│ QuestionBank          │ QNS  │ Qns   │ qns_   │ QuestionBank          │ QuestionBank          │ LmsQuestionBank_DDL_     │
│ Recommendation        │ REC  │ Rec   │ rec_   │ Recommendation        │ Recommendation.       │ Recommendation_DDL_      │
│ Scheduler             │ SDL  │ Sdl   │ sdl_   │ Scheduler             │ N/A                   │ Scheduler_ddl_           │
│ SchoolSetup           │ SCH  │ Sch   │ sch_   │ SchoolSetup           │ SchoolSetup           │ SchoolSetup_DDL_         │
│ SmartTimetable        │ STT  │ Stt   │ tt_    │ SmartTimetable        │ SmartTimetable        │ Timetable_DDL_           │
│ StandardTimetable     │ TTS  │ Tts   │ tts_   │ StandardTimetable     │ StandardTimetable     │ Timetable_DDL_           │
│ StudentFee            │ FIN  │ Fin   │ fee_   │ StudentFee            │ StudentFee            │ StudentFee_DDL_          │
│ StudentPortal         │ STP  │ Stp   │ stp_   │ StudentPortal         │ StudentPortal         │ StudentPortal_DDL_       │
│ StudentProfile        │ STD  │ Std   │ std_   │ StudentProfile        │ StudentProfile        │ StudentProfile_DDL_      │
│ Syllabus              │ SLB  │ Slb   │ slb_   │ Syllabus              │ Syllabus              │ Syllabus_DDL_            │
│ SyllabusBooks         │ SLK  │ Slk   │ slb_   │ SyllabusBooks         │ SyllabusBooks         │ SyllabusBooks_DDL_       │
│ SystemConfig          │ SYS  │ Sys   │ sys_   │ SystemConfig          │ SystemConfig          │ _tenant_db_              │
│ Template              │ TMP  │ Tmp   │ tmp_   │ Template              │ Template              │ Template_DDL_            │
│ TenantCore            │ TCO  │ Tco   │ tco_   │ TenantCore            │ N/A                   │ TenantCore_DDL_          │
│ TimetableFoundation   │ TTF  │ Ttf   │ ttf_   │ TimetableFoundation   │ TimetableFoundation   │ Timetable_DDL_           │
│ Transport             │ TPT  │ Tpt   │ tpt_   │ Transport             │ Transport             │ Transport_DDL_           │
│ Vendor                │ VND  │ Vnd   │ vnd_   │ Vendor                │ Vendor                │ Vendor_DDL_              │
└───────────────────────┴──────┴───────┴────────┴───────────────────────┴───────────────────────┴──────────────────────────┘
```
