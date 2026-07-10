# Development Status — Platform Summary (All Modules)
**Date:** 2026-07-02 · **Analyzer:** Status_Analyzer v2 (10-Dimension) · **Depth:** Standard (structural) · **Modules:** 45

> ⛔ **Read-only** — no code/DDL/config changed. Files resolved via `0-Prime_Ai_Detail/module_list.md` (authoritative CODE/FOLDER/DDL map). Every score is a count → reproducible.

## ⚠️ Methodology & confidence (read first)
Standard-depth structural pass. **High-confidence** dims (counted): D5 gating, D6 standard, D8 tests, D9 registration/seeders, D1/D2 doc+schema presence. **Proxy dims** (optimistic, Low/Med confidence): **D3** = non-stub/total methods (code structure, *not* FRD-verified); **D4** = stub/God-controller signals only. **D5** capped 55 for tenant modules (systemic P0: dead `Gate::policy()` + missing `EnsureTenantHasModule`, 13/13 confirmed). **D7** = ⚠️ unmeasured (run Technical Auditor). **Doc%** column = documented deep-audit % for reconciliation (structural score is an upper bound on it).

## Platform Dashboard — Structural avg **82%** · 🟢 2 · 🟡 39 · 🔴 4

| Module | Struct% | Verdict | Doc% | D1 Req | D2 DDL | D3 Dev* | D4 Qual* | D5 Sec† | D6 Std | D8 Test | D9 Dep | D10 Perf |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Documentation | **94** | 🟢 | – | 84 | N/A | 100 | 100 | 97 | 100 | 0 | 100 | 100 |
| Billing | **90** | 🟢 | – | 90 | 75 | 100 | 90 | 96 | 85 | 14 | 100 | 100 |
| Ptm | **88** | 🟡 | – | 100 | 75 | 100 | 100 | 55 | 100 | 73 | 100 | 82 |
| Vendor | **88** | 🟡 | 50 (NO-GO) | 89 | 75 | 100 | 97 | 55 | 95 | 88 | 100 | 100 |
| Cafeteria | **86** | 🟡 | – | 99 | 75 | 100 | 100 | 55 | 100 | 0 | 100 | 100 |
| Dashboard | **86** | 🟡 | – | 83 | N/A | 100 | 100 | 55 | 100 | 0 | 100 | 100 |
| Hostel | **86** | 🟡 | – | 100 | 75 | 100 | 100 | 55 | 100 | 0 | 100 | 97 |
| HrStaff | **86** | 🟡 | – | 100 | 75 | 100 | 100 | 55 | 100 | 0 | 100 | 100 |
| Payment | **86** | 🟡 | – | 83 | N/A | 100 | 100 | 55 | 100 | 0 | 100 | 100 |
| Accounting | **85** | 🟡 | – | 92 | 75 | 100 | 97 | 55 | 95 | 14 | 100 | 100 |
| Admission | **85** | 🟡 | – | 98 | 75 | 98 | 99 | 55 | 100 | 0 | 100 | 100 |
| Hpc | **85** | 🟡 | – | 80 | 75 | 100 | 90 | 55 | 85 | 67 | 100 | 100 |
| Inventory | **85** | 🟡 | – | 99 | 75 | 98 | 99 | 55 | 100 | 0 | 100 | 100 |
| QuestionBank | **85** | 🟡 | 50 | 90 | 75 | 100 | 84 | 55 | 75 | 100 | 100 | 100 |
| Recommendation | **85** | 🟡 | – | 90 | 75 | 100 | 97 | 55 | 95 | 10 | 100 | 100 |
| BehaviouralAssessment | **84** | 🟡 | 55 | 100 | 75 | 97 | 95 | 55 | 95 | 0 | 100 | 100 |
| FrontOffice | **84** | 🟡 | – | 96 | 75 | 98 | 96 | 55 | 95 | 0 | 100 | 100 |
| StandardTimetable | **84** | 🟡 | 15 | 82 | 75 | 100 | 97 | 55 | 95 | 0 | 100 | 100 |
| SyllabusBooks | **84** | 🟡 | 75 | 86 | 75 | 94 | 94 | 55 | 95 | 55 | 100 | 85 |
| Template | **84** | 🟡 | 68 (NO-GO) | 86 | 75 | 100 | 97 | 55 | 95 | 0 | 100 | 100 |
| Certificate | **83** | 🟡 | – | 93 | 75 | 95 | 97 | 55 | 100 | 0 | 100 | 100 |
| LmsHomework | **83** | 🟡 | – | 87 | 75 | 100 | 87 | 55 | 80 | 50 | 100 | 100 |
| Prime | **83** | 🟡 | – | 80 | 75 | 99 | 77 | 83 | 65 | 41 | 100 | 52 |
| Syllabus | **83** | 🟡 | 78 | 100 | 75 | 100 | 77 | 55 | 65 | 100 | 100 | 88 |
| GlobalMaster | **82** | 🟡 | – | 80 | 75 | 89 | 94 | 65 | 100 | 0 | 100 | 97 |
| LmsExam | **82** | 🟡 | – | 100 | 75 | 100 | 71 | 55 | 55 | 100 | 100 | 100 |
| Notification | **82** | 🟡 | – | 85 | 75 | 100 | 91 | 55 | 85 | 0 | 100 | 79 |
| StudentProfile | **82** | 🟡 | – | 86 | 75 | 93 | 86 | 55 | 85 | 56 | 100 | 100 |
| Complaint | **81** | 🟡 | – | 88 | 75 | 92 | 80 | 55 | 75 | 100 | 100 | 40 |
| EventEngine | **81** | 🟡 | – | 84 | 75 | 89 | 94 | 55 | 100 | 0 | 100 | 100 |
| StudentFee | **81** | 🟡 | 78 | 95 | 75 | 100 | 84 | 55 | 75 | 7 | 100 | 94 |
| Transport | **81** | 🟡 | – | 100 | 75 | 97 | 73 | 55 | 60 | 100 | 100 | 70 |
| MarksheetGeneration | **80** | 🟡 | – | 85 | 75 | 100 | 97 | 55 | 95 | 0 | 50 | 100 |
| SystemConfig | **80** | 🟡 | 70 | 86 | 75 | 100 | 87 | 48 | 80 | 0 | 100 | 94 |
| Feedback | **78** | 🔴 | – | 90 | 75 | 100 | 100 | 13 | 100 | 0 | 100 | 100 |
| LmsQuests | **78** | 🟡 | – | 87 | 75 | 100 | 74 | 55 | 60 | 0 | 100 | 100 |
| SmartTimetable | **78** | 🟡 | 68 | 87 | 75 | 100 | 77 | 55 | 65 | 0 | 100 | 88 |
| CommonChat | **77** | 🟡 | – | 90 | 75 | 96 | 95 | 49 | 95 | 0 | 50 | 100 |
| LmsQuiz | **76** | 🟡 | – | 89 | 75 | 100 | 67 | 55 | 50 | 0 | 100 | 97 |
| Scheduler | **76** | 🔴 | – | 80 | 75 | 100 | 100 | 0 | 100 | 0 | 100 | 100 |
| ParentPortal | **74** | 🔴 | – | 92 | 75 | 95 | 97 | 0 | 100 | 0 | 100 | 97 |
| SchoolSetup | **74** | 🟡 | 62 | 100 | 75 | 99 | 59 | 55 | 35 | 34 | 100 | 40 |
| TimetableFoundation | **71** | 🟡 | 68 | 92 | 75 | 100 | 52 | 55 | 25 | 4 | 100 | 67 |
| Library | **68** | 🟡 | – | 100 | 75 | 99 | 25 | 55 | 0 | 100 | 100 | 40 |
| StudentPortal | **62** | 🔴 | 80 | 100 | 75 | 99 | 50 | 0 | 25 | 0 | 100 | 100 |
| **Platform avg** | **82** | | | 91 | 75 | 98 | 87 | 53 | 82 | 25 | 98 | 91 |

\* D3/D4 structural proxies. † D5 tenant-capped 55 (systemic P0). D2 N/A = code-only module (no DDL by design). D7 omitted (unmeasured).

## Stage Heatmap — weakest modules per stage
- **D8 Test Coverage** (avg 25): Admission 0, BehaviouralAssessment 0, Cafeteria 0, Certificate 0, CommonChat 0
- **D5 Security** (avg 53): ParentPortal 0, Scheduler 0, StudentPortal 0, Feedback 13, SystemConfig 48
- **D2 DDL/Schema** (avg 75): Accounting 75, Admission 75, BehaviouralAssessment 75, Billing 75, Cafeteria 75
- **D3 Dev Coverage** (avg 98): EventEngine 89, GlobalMaster 89, Complaint 92, StudentProfile 93, SyllabusBooks 94
- **D1 Requirement Doc** (avg 91): GlobalMaster 80, Hpc 80, Prime 80, Scheduler 80, StandardTimetable 82

## Files-present matrix (what was found this run)
| Module | DDL | FRD | ReqV1 files | Test files |
|--------|:---:|:---:|:---:|:---:|
| Accounting | Accounting_DDL_v3.sql | ✅ | 12 | 3 |
| Admission | Admission_DDL_v1.sql | ✅ | 18 | 0 |
| BehaviouralAssessment | BehaviouralAssess_DDL_v2.sql | ✅ | 25 | 0 |
| Billing | Billing_DDL_v1.sql | ✅ | 10 | 1 |
| Cafeteria | Cafeteria_DDL_v1.sql | ✅ | 19 | 0 |
| Certificate | Certificates_DDL_v1.sql | ✅ | 13 | 0 |
| CommonChat | CommonChat_DDL_v1.sql | ✅ | 10 | 0 |
| Complaint | Complaint_DDL_v2.sql | ✅ | 8 | 15 |
| Dashboard | N/A | ✅ | 3 | 0 |
| Documentation | N/A | ✅ | 4 | 0 |
| EventEngine | EventEngine_v2.sql (1-DDL_Modules) | ✅ | 4 | 0 |
| Feedback | Feedback_ddl_v3.sql (1-DDL_Modules) | ✅ | 10 | 0 |
| FrontOffice | FrontOffice_DDL_v1.sql | ✅ | 16 | 0 |
| GlobalMaster | global_db_v4.sql | ✅ | 0 | 0 |
| Hostel | Hostel_DDL_v4.sql | ✅ | 41 | 0 |
| Hpc | HPC_DDL_v2.sql | ✅ | 0 | 8 |
| HrStaff | HrStaff_Payroll_DDL_v2.sql | ✅ | 22 | 0 |
| Inventory | Inventory_DDL_v1.sql | ✅ | 19 | 0 |
| Library | Library_ddl_v7.sql | ✅ | 31 | 66 |
| LmsExam | LmsExam_DDL_v6.sql | ✅ | 25 | 24 |
| LmsHomework | LmsHomework_DDL_v5.sql | ✅ | 7 | 1 |
| LmsQuests | LmsQuest_DDL_v2.sql | ✅ | 7 | 0 |
| LmsQuiz | LmsQuiz_DDL_v2.sql | ✅ | 9 | 0 |
| MarksheetGeneration | MarksheetGeneration_DDL_v1.sql | ✅ | 5 | 0 |
| Notification | Notification_DDL_v3.sql | ✅ | 5 | 0 |
| ParentPortal | ParentPortal_DDL_v2.sql | ✅ | 12 | 0 |
| Payment | N/A | ✅ | 3 | 0 |
| Prime | prime_db_v4.sql | ✅ | 0 | 9 |
| Ptm | PTM_DDL_v3.sql | ✅ | 21 | 8 |
| QuestionBank | LmsQuestionBank_DDL_v1.4.sql | ✅ | 10 | 16 |
| Recommendation | Recommendation_DDL_v1.6.sql | ✅ | 10 | 1 |
| Scheduler | Scheduler_ddl_v1.sql (1-DDL_Modules) | ✅ | 0 | 0 |
| SchoolSetup | SchoolSetup_DDL_v3.sql | ✅ | 48 | 21 |
| SmartTimetable | Timetable_DDL_v7.8.sql | ✅ | 7 | 0 |
| StandardTimetable | Timetable_DDL_v7.8.sql | ✅ | 2 | 0 |
| StudentFee | StudentFee_DDL_v4.sql | ✅ | 15 | 1 |
| StudentPortal | StudentPortal_DDL_v4.sql | ✅ | 34 | 0 |
| StudentProfile | StudentProfile_DDL_v1.6.sql | ✅ | 6 | 5 |
| Syllabus | Syllabus_DDL_v1.1.sql | ✅ | 21 | 35 |
| SyllabusBooks | SyllabusBooks_DDL_v3.sql | ✅ | 6 | 6 |
| SystemConfig | tenant_db_v4.sql | ✅ | 6 | 0 |
| Template | Template_DDL_v5.sql | ✅ | 6 | 0 |
| TimetableFoundation | Timetable_DDL_v7.8.sql | ✅ | 12 | 1 |
| Transport | Transport_DDL_v2.3.sql | ✅ | 41 | 40 |
| Vendor | Vendor_DDL_v2.1.sql | ✅ | 9 | 7 |

## Systemic P0 (platform-wide, from known-issues.md)
- `Gate::policy()` dead / `EnsureTenantHasModule` absent — **13/13** audited (P0): counted Gates over-state auth → D5 capped.
- FormRequest `authorize(){return true;}` — 437/485 (P1).
- Test coverage now measured from `prime_testing`: platform D8 avg **25%** (Library/Transport/Syllabus/LmsExam/SchoolSetup strongest; ~20 modules still 0).
- PII plaintext (Vendor), secrets in source (QuestionBank) — P0 data-protection.

## Recommended platform priorities
1. Fix the two systemic auth P0s → lifts D5 (15% weight) across all tenant modules at once.
2. Add Browser tests for the ~20 zero-coverage modules (D8).
3. Run **Full depth** on 🔴/low-D3 modules to replace structural D3/D4 with FRD-verified numbers.
4. Run **Technical Auditor** to populate D7 (bug-fix status).

---
*Status_Analyzer v2 · `AI_Brain/config/completion-formula-v2.md` · files resolved via module_list.md · read-only.*