# School Domain Map

## Entity Classification

### Central-Scoped Entities (prime_db / global_db)
These exist at the platform level, shared across all tenants:

| Entity | Model | Table | Module |
|--------|-------|-------|--------|
| Tenant (School) | `Prime\Tenant` | `prm_tenant` | Prime |
| Domain | `Prime\Domain` | `prm_tenant_domains` | Prime |
| Tenant Group | `Prime\TenantGroup` | `prm_tenant_groups` | Prime |
| Plan | `GlobalMaster\Plan` | `prm_plans` | GlobalMaster |
| Module | `GlobalMaster\Module` | `glb_modules` | GlobalMaster |
| Menu | `Prime\Menu` | `glb_menus` | Prime |
| Country/State/City/District | `GlobalMaster\*` | `glb_*` | GlobalMaster |
| Board | `GlobalMaster\Board` | `glb_boards` | GlobalMaster |
| Language | `Prime\Language` | `glb_languages` | Prime |
| Billing Invoice | `Billing\TenantInvoice` | `bil_tenant_invoices` | Billing |
| Central User | `App\Models\User` | `sys_users` (central) | App |
| Central Role/Permission | `Prime\Role/Permission` | `sys_roles/permissions` (central) | Prime |

### Tenant-Scoped Entities (tenant_db)
These exist per-school, completely isolated:

**People & Users:**
| Entity | Model | Table | Module |
|--------|-------|-------|--------|
| User (Tenant) | `App\Models\User` | `sys_users` | App |
| Role/Permission | `SchoolSetup\Role/Permission` | `sys_roles/permissions` | SchoolSetup |
| Employee | `SchoolSetup\Employee` | `sch_employees` | SchoolSetup |
| Employee Profile | `SchoolSetup\EmployeeProfile` | `sch_employee_profiles` | SchoolSetup |
| Teacher | `SchoolSetup\Teacher` | `sch_teachers` | SchoolSetup |
| Teacher Profile | `SchoolSetup\TeacherProfile` | `sch_teacher_profiles` | SchoolSetup |
| Teacher Capability | `SchoolSetup\TeacherCapability` | `sch_teacher_capabilities` | SchoolSetup |
| Student | `StudentProfile\Student` | `std_students` | StudentProfile |
| Student Profile | `StudentProfile\StudentProfile` | `std_student_profiles` | StudentProfile |
| Guardian | `StudentProfile\Guardian` | `std_guardians` | StudentProfile |

**School Structure:**
| Entity | Model | Table | Module |
|--------|-------|-------|--------|
| Organization | `SchoolSetup\Organization` | `sch_organizations` | SchoolSetup |
| Department | `SchoolSetup\Department` | `sch_department` | SchoolSetup |
| Designation | `SchoolSetup\Designation` | `sch_designation` | SchoolSetup |
| Class | `SchoolSetup\SchoolClass` | `sch_classes` | SchoolSetup |
| Section | `SchoolSetup\Section` | `sch_sections` | SchoolSetup |
| Class-Section | `SchoolSetup\ClassSection` / `SchClassGroupsJnt` | `sch_class_section_jnt` | SchoolSetup |
| Subject | `SchoolSetup\Subject` | `sch_subjects` | SchoolSetup |
| Subject Type | `SchoolSetup\SubjectType` | `sch_subject_types` | SchoolSetup |
| Subject Group | `SchoolSetup\SubjectGroup` | `sch_subject_groups` | SchoolSetup |
| Study Format | `SchoolSetup\StudyFormat` | `sch_study_formats` | SchoolSetup |
| Building | `SchoolSetup\Building` | `sch_buildings` | SchoolSetup |
| Room | `SchoolSetup\Room` | `sch_rooms` | SchoolSetup |
| Room Type | `SchoolSetup\RoomType` | `sch_room_types` | SchoolSetup |

**Timetable:**
| Entity | Model | Table | Module |
|--------|-------|-------|--------|
| Timetable | `SmartTimetable\Timetable` | `tt_timetable` | SmartTimetable |
| Timetable Cell | `SmartTimetable\TimetableCell` | `tt_timetable_cell` | SmartTimetable |
| Activity | `SmartTimetable\Activity` | `tt_activity` | SmartTimetable |
| Constraint | `SmartTimetable\Constraint` | `tt_constraint` | SmartTimetable |
| Generation Run | `SmartTimetable\GenerationRun` | `tt_generation_run` | SmartTimetable |

**Academic:**
| Entity | Model | Table | Module |
|--------|-------|-------|--------|
| Academic Term | `SmartTimetable\AcademicTerm` | `tt_academic_term` | SmartTimetable |
| Lesson | `Syllabus\Lesson` | `slb_lessons` | Syllabus |
| Topic | `Syllabus\Topic` | `slb_topics` | Syllabus |
| Competency | `Syllabus\Competency` | `slb_competencies` | Syllabus |

**Assessment:**
| Entity | Model | Table | Module |
|--------|-------|-------|--------|
| Question | `QuestionBank\QuestionBank` | `qns_questions_bank` | QuestionBank |
| Exam | `LmsExam\*` | `exm_*` | LmsExam |
| Quiz | `LmsQuiz\*` | `quz_*` | LmsQuiz |
| Homework | `LmsHomework\*` | `hmw_*` | LmsHomework |
| HPC Evaluation | `Hpc\StudentHpcEvaluation` | `hpc_student_hpc_evaluation` | Hpc |

**Finance:**
| Entity | Model | Table | Module |
|--------|-------|-------|--------|
| Fee Head | `StudentFee\FeeHeadMaster` | `fin_fee_head_master` | StudentFee |
| Fee Invoice | `StudentFee\FeeInvoice` | `fin_fee_invoices` | StudentFee |
| Fee Receipt | `StudentFee\FeeReceipt` | `fin_fee_receipts` | StudentFee |
| Payment | `Payment\Payment` | `pay_payments` | Payment |

## Key Relationships
```
Organization (1) ──> (N) Academic Sessions
Organization (1) ──> (N) Departments ──> (N) Designations
Organization (1) ──> (N) Buildings ──> (N) Rooms

SchoolClass (1) ──> (N) Sections ──> (N) ClassSection (junction)
Subject (1) ──> (N) SubjectStudyFormat ──> StudyFormat
Subject (1) ──> (N) SubjectTeacher ──> Teacher

Student (1) ──> (1) StudentProfile
Student (1) ──> (N) Guardians (via junction)
Student (1) ──> (N) StudentAcademicSessions
Student (1) ──> (N) Attendance Records
Student (1) ──> (N) Fee Invoices

Teacher (1) ──> (1) TeacherProfile
Teacher (1) ──> (N) SubjectTeacher ──> Subject
Teacher (1) ──> (N) ActivityTeacher ──> Activity

Activity (1) ──> (N) ActivityTeacher ──> Teacher
Activity (N) ──> (1) Class, Section, Subject, StudyFormat
Activity (1) ──> (N) TimetableCell (via generation)

Timetable (1) ──> (N) TimetableCell
TimetableCell (1) ──> (N) TimetableCellTeacher
```

## Role Structure (RBAC — Spatie)
| Role | Scope | Access Level |
|------|-------|--------------|
| SuperAdmin | Central | Manages tenants, plans, billing. Cannot access tenant data directly. |
| SchoolAdmin | Tenant | Full access to own school data. Cannot access other tenants. |
| Principal | Tenant | Academic oversight, reports, approvals |
| Teacher | Tenant | Own classes, subjects, attendance, grades |
| Student | Tenant | Own profile, assignments, results |
| Parent | Tenant | Children's data only (linked via guardian junction) |
| Accountant | Tenant | Fee management, financial reports |
| Librarian | Tenant | Library management |
| Transport Manager | Tenant | Vehicle, route, trip management |

## Academic Year/Term Structure
- Global academic sessions defined in `glb_academic_sessions`
- Per-school mapping via `sch_org_academic_sessions_jnt`
- Terms defined per timetable in `tt_academic_term`
- All term-dependent data (attendance, exams, timetables) must resolve academic year first
