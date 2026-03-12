# 02 — Module Analysis

## Module Inventory (29 Modules)

### Central Scope Modules

#### 1. Prime — Central SaaS Management
- **Controllers (20):** TenantController, TenantGroupController, TenantManagementController, UserController, UserRolePrmController, RolePermissionController, PrimeAuthController, PrimeController, AcademicSessionController, ActivityLogController, BoardController, DropdownController, DropdownMgmtController, DropdownNeedController, EmailController, LanguageController, MenuController, NotificationController, SalesPlanAndModuleMgmtController, SettingController
- **Models (27):** Tenant (UUID), Domain, User, TenantPlan, TenantPlanRate, TenantPlanModule, TenantGroup, TenantInvoice, Role, Permission, Menu, Setting, Dropdown, AcademicSession, Language, Board, Media, etc.
- **Tables:** prm_tenant, prm_tenant_domains, prm_tenant_groups, prm_plans, prm_tenant_plan_jnt, prm_tenant_plan_rates, prm_tenant_plan_module_jnt, sys_users, sys_roles, sys_permissions, sys_settings, sys_dropdowns, etc.
- **Routes:** `/prime/*` — Tenant CRUD, user/role management, academic sessions, boards
- **Services:** TenantPlanAssigner
- **Workflows:** Tenant onboarding, plan assignment, user management, dropdown configuration

#### 2. GlobalMaster — Shared Reference Data
- **Controllers (12):** CountryController, StateController, DistrictController, CityController, BoardController, LanguageController, ModuleController, PlanController, AcademicSessionController, ActivityLogController, DropdownController, OrganizationController
- **Models (12):** Country, State, District, City, Board (global_master_mysql connection), Language, Module, Plan, Dropdown, DropdownNeed, ActivityLog, Media
- **Tables:** glb_countries, glb_states, glb_districts, glb_cities, glb_boards, glb_languages, glb_modules, glb_menus
- **Routes:** `/global-master/*` — Geographic data, boards, languages, modules, plans

#### 3. SystemConfig — System Settings
- **Controllers (3):** MenuController, SettingController, SystemConfigController
- **Models (3):** Menu, Setting, Translation
- **Tables:** sys_menus, sys_settings, sys_translations
- **Routes:** `/system-config/*` — Settings, menus

#### 4. Billing — Invoice & Payment Tracking
- **Controllers (6):** BillingCycleController, BillingManagementController, InvoicingAuditLogController, InvoicingController, InvoicingPaymentController, SubscriptionController
- **Models (6):** BilTenantInvoice, BillingCycle, BillTenatEmailSchedule, BillOrgInvoicingModulesJnt, InvoicingAuditLog, InvoicingPayment
- **Tables:** bil_tenant_invoices, bil_tenant_invoicing_payments, bil_tenant_invoicing_audit_logs, billing_cycles, bil_tenant_email_schedules
- **Routes:** `/billing/*` — Invoice management, payments, audit logs, email scheduling
- **Jobs:** SendInvoiceEmailJob

---

### Tenant Scope Modules — Core

#### 5. SchoolSetup — School Infrastructure
- **Controllers (32):** OrganizationController, SchoolClassController, SectionController, SubjectController, TeacherController, RoomController, BuildingController, EmployeeProfileController, DepartmentController, DesignationController, StudyFormatController, SubjectGroupController, EntityGroupController, UserController, RolePermissionController, etc.
- **Models (59):** Organization, SchoolClass, ClassSection, Section, Teacher, TeacherProfile, Subject, SubjectGroup, Room, RoomType, Building, Employee, EmployeeProfile, Department, Designation, LeaveType, StudyFormat, EntityGroup, etc.
- **Tables:** sch_organizations, sch_classes, sch_sections, sch_class_section_jnt, sch_subjects, sch_teachers, sch_rooms, sch_buildings, sch_employees, sch_departments, sch_designations, etc.
- **Routes:** `/school-setup/*` — 25+ resource routes for school infrastructure

#### 6. StudentProfile — Student Management
- **Controllers (5):** StudentController, StudentProfileController, AttendanceController, MedicalIncidentController, StudentReportController
- **Models (13):** Student, StudentDetail, StudentProfile, StudentAcademicSession, StudentAddress, StudentAttendance, StudentAttendanceCorrection, StudentDocument, StudentHealthProfile, VaccinationRecord, MedicalIncident, Guardian, PreviousEducation
- **Tables:** std_students, std_student_details, std_student_profiles, std_student_academic_session, std_student_addresses, std_attendance_details, std_student_documents, std_guardians, std_student_guardian_jnt, etc.
- **Routes:** Student CRUD, attendance, medical incidents, reports

#### 7. SmartTimetable — AI Timetable Generation
- **Controllers (23):** TimetableController, ActivityController, ConstraintController, PeriodSetController, SchoolDayController, WorkingDayController, TeacherAvailabilityController, RoomUnavailableController, TtConfigController, etc.
- **Models (94):** Timetable, TimetableCell, Activity, SubActivity, Constraint (8 types), GenerationRun, OptimizationRun, TeacherAvailability, RoomAvailability, MlModel, ApprovalWorkflow, SubstitutionLog, ConflictDetection, BatchOperation, ChangeLog, etc.
- **Services (5):** ActivityScoreService, RoomAvailabilityService, SubActivityService, DatabaseConstraintService, TimetableStorageService
- **Tables:** tt_timetables, tt_timetable_cells, tt_activities, tt_constraints (10+ constraint tables), tt_generation_runs, tt_teacher_availabilities, tt_room_availabilities, tt_ml_models, tt_approval_workflows, etc. (~45 tables)
- **Routes:** `/smart-timetable/*` — Activities, constraints, availability, generation

---

### Tenant Scope Modules — Operations

#### 8. Transport — Vehicle & Route Management
- **Controllers (29):** VehicleController, RouteController, TripController, DriverHelperController, StudentAllocationController, StudentAttendanceController, DriverAttendanceController, LiveTripController, FeeMasterController, FeeCollectionController, VehicleMgmtController, TransportDashboardController, etc.
- **Models (39):** Vehicle, Route, Shift, PickupPoint, DriverHelper, TptTrip, TptLiveTrip, TptGpsAlerts, StudentBoardingLog, TptStudentAllocationJnt, TptDriverAttendance, TptDailyVehicleInspection, TptVehicleMaintenance, MlModels, etc.
- **Tables:** ~35 tables (tpt_* prefix)
- **Imports/Exports:** StudentAllocationImport/Export, FeeMasterImport, FeeCollectionExport

#### 9. Vendor — Vendor Management
- **Controllers (7):** VendorController, VendorAgreementController, VendorInvoiceController, VendorPaymentController, VndItemController, VndUsageLogController, VendorDashboardController
- **Models (8):** Vendor, VndAgreement, VndAgreementItem, VndInvoice, VndPayment, VndItem, VndUsageLog, VendorDashboard

#### 10. Complaint — Issue Tracking
- **Controllers (8):** ComplaintController, ComplaintCategoryController, ComplaintActionController, DepartmentSlaController, MedicalCheckController, AiInsightController, ComplaintDashboardController, ComplaintReportController
- **Models (6):** Complaint, ComplaintCategory, ComplaintAction, DepartmentSla, MedicalCheck, AiInsight
- **Services (2):** ComplaintAIInsightEngine (sentiment analysis), ComplaintDashboardService
- **Events:** ComplaintSaved → ProcessComplaintAIInsights listener

#### 11. Notification — Multi-Channel
- **Controllers (12):** ChannelMasterController, NotificationManageController, NotificationTemplateController, NotificationTargetController, NotificationThreadController, etc.
- **Models (13):** Notification, NotificationTemplate, NotificationChannel, ChannelMaster, ProviderMaster, NotificationDeliveryLog, UserPreference, etc.
- **Services:** NotificationService (trigger, render, dispatch)
- **Events:** SystemNotificationTriggered → ProcessSystemNotification listener

#### 12. Payment — Razorpay
- **Controllers (4):** PaymentController, PaymentCallbackController, PaymentGatewayController
- **Models (5):** Payment, PaymentGateway, PaymentHistory, PaymentRefund, PaymentWebhook
- **Services:** PaymentService, GatewayManager, RazorpayGateway

---

### Tenant Scope Modules — Curriculum & Assessment

#### 13. Syllabus — Curriculum Management
- **Controllers (16):** LessonController, TopicController, CompetencieController, BloomTaxonomyController, CognitiveSkillController, ComplexityLevelController, etc.
- **Models (21):** Lesson, Topic, Competencie, BloomTaxonomy, CognitiveSkill, StudyMaterial, TopicCompetency, TopicDependencies, SyllabusSchedule, etc.

#### 14. SyllabusBooks — Textbook Management
- **Controllers (4):** BookController, AuthorController, BookTopicMappingController
- **Models (6):** BokBook, BookAuthors, BookAuthorJnt, BookClassSubject, BookTopicMapping, MediaFiles

#### 15. QuestionBank — Question Management
- **Controllers (7):** QuestionBankController, AIQuestionGeneratorController, QuestionTagController, QuestionVersionController, QuestionStatisticController, etc.
- **Models (17):** QuestionBank, QuestionOption, QuestionTag, QuestionVersion, QuestionStatistic, QuestionUsageLog, QuestionMedia, etc.

#### 16-19. LMS Modules (Exam, Quiz, Homework, Quests)
- **LmsExam:** 11 controllers, 11 models — Exams, papers, paper sets, allocations
- **LmsQuiz:** 5 controllers, 6 models — Quizzes, difficulty distribution
- **LmsHomework:** 5 controllers, 5 models — Homework, submissions, rule engine
- **LmsQuests:** 4 controllers, 4 models — Learning quests, scopes

---

### Tenant Scope Modules — Analytics & Finance

#### 20. Hpc — Holistic Progress Card
- **Controllers (10):** LearningOutcomesController, StudentHpcEvaluationController, CircularGoalsController, KnowledgeGraphValidationController, etc.
- **Models (14):** LearningOutcomes, StudentHpcEvaluation, LearningActivities, HpcLevels, CircularGoals, TopicEquivalency, etc.

#### 21. Recommendation — AI Recommendations
- **Controllers (10):** RecommendationRuleController, StudentRecommendationController, MaterialBundleController, etc.
- **Models (11):** StudentRecommendation, RecommendationRule, RecommendationMaterial, MaterialBundle, etc.

#### 22. StudentFee — Fee Management
- **Controllers (10):** FeeHeadMasterController, FeeInstallmentController, FeeInvoiceController, FeeScholarshipController, etc.
- **Models (19):** FeeStructureMaster, FeeHeadMaster, FeeGroupMaster, FeeInstallment, FeeInvoice, FeeReceipt, FeeTransaction, FeeScholarship, etc.

---

### Utility & Pending Modules

#### 23. Dashboard (1 controller) — Admin dashboards
#### 24. Scheduler (1 controller, 2 models) — CRON job scheduling
#### 25. Documentation (3 controllers, 2 models) — Help articles
#### 26. StudentPortal (3 controllers) — Student-facing portal [Pending]
#### 27. Library (1 controller) — Library management [Pending]
