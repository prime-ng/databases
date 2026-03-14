# Laravel Modules - Development Status & Understanding
**Last Updated:** 2026-03-01
**Repo Path:** `/Users/bkwork/Herd/laravel/Modules/`
**Total Modules:** 27

---

## Quick Reference - Completeness Tiers

| Tier | Level | Modules |
|------|-------|---------|
| 1 | 90-100% Production-Ready | Prime, Complaint, Notification |
| 2 | 80-89% Feature-Complete | Billing, GlobalMaster, Hpc, LmsExam, StudentFee, Syllabus, SmartTimetable, Transport, QuestionBank, StudentProfile |
| 3 | 70-79% Functional | LmsHomework, LmsQuests, LmsQuiz, Payment, Recommendation, Vendor, SyllabusBooks, Documentation |
| 4 | 50-69% Partial | StudentPortal, SystemConfig, Scheduler |
| 5 | 20-49% Skeleton | Dashboard, Library |

---

## Module-by-Module Breakdown

### 1. Prime (95%) — Core Platform
**Path:** `Modules/Prime/`
**Purpose:** Multi-tenant SaaS core — auth, users, roles, permissions, tenant management, billing
- **Controllers (22):** PrimeAuthController, UserController, TenantController, TenantManagementController, TenantGroupController, RolePermissionController, UserRolePrmController, MenuController, SettingController, EmailController, LanguageController, BoardController, AcademicSessionController, DropdownController, DropdownMgmtController, DropdownNeedController, NotificationController, SessionBoardSetupController, SalesPlanAndModuleMgmtController, ActivityLogController, and more
- **Models (27):** User, Tenant, TenantGroup, Role, Permission, Menu, MenuModule, Setting, TenantPlan, TenantInvoice, TenantInvoiceModule, TenantPlanRate, TenantPlanBillingSchedule, Board, Language, AcademicSession, Domain, Dropdown, DropdownNeed, DropdownNeedDropdown, DropdownNeedTableJnt, Media, ActivityLog, and more
- **Migrations:** 37 (most comprehensive)
- **Jobs:** SendScheduledEmail
- **Key Features:** Multi-tenant architecture, RBAC, menu management, billing integration
- **Notes:** Most mature module. Full migrations present.

---

### 2. Complaint (90%) — Complaint Management
**Path:** `Modules/Complaint/`
**Purpose:** Complaint management with AI insights, SLA tracking, and reporting
- **Controllers (8):** ComplaintController, ComplaintCategoryController, ComplaintActionController, DepartmentSlaController, MedicalCheckController, AiInsightController, ComplaintDashboardController, ComplaintReportController
- **Models (6):** Complaint, ComplaintAction, ComplaintCategory, DepartmentSla, MedicalCheck, AiInsight
- **Services (2):** ComplaintAIInsightEngine, ComplaintDashboardService
- **Migrations:** 6
- **Events/Listeners:** ComplaintSaved → ProcessComplaintAIInsights
- **Key Features:** Multi-channel complaint tracking, AI-powered insights, SLA management, reporting

---

### 3. Notification (90%) — Multi-Channel Notifications
**Path:** `Modules/Notification/`
**Purpose:** Email, SMS, Push, In-app notification system
- **Controllers (12):** ChannelMasterController, ProviderMasterController, NotificationTemplateController, NotificationTargetController, DeliveryQueueController, NotificationThreadController, NotificationThreadMemberController, TargetGroupController, ResolvedRecipientController, TemplateController, NotificationManageController, UserPreferenceController
- **Models (14):** Notification, NotificationChannel, NotificationTemplate, NotificationTarget, NotificationDeliveryLog, NotificationThread, NotificationThreadMember, ChannelMaster, DeliveryQueue, ProviderMaster, ResolvedRecipient, TargetGroup, UserDevice, UserPreference
- **Services (2):** NotificationService, NotificationService_25_02_2026 (backup)
- **Events/Listeners:** SystemNotificationTriggered → ProcessSystemNotification
- **Key Features:** Multi-channel delivery, templates, delivery tracking, user preferences, thread-based notifications

---

### 4. Billing (85%) — Billing & Invoicing
**Path:** `Modules/Billing/`
**Purpose:** Billing cycles, invoicing, and payment management for tenant subscriptions
- **Controllers (6):** BillingCycleController, BillingManagementController, InvoicingAuditLogController, InvoicingController, InvoicingPaymentController, SubscriptionController
- **Models (6):** BillingCycle, BillOrgInvoicingModulesJnt, BillTenatEmailSchedule, BilTenantInvoice, InvoicingAuditLog, InvoicingPayment
- **Views:** 40
- **Key Features:** Invoice management, payment tracking, billing audit logs, email scheduling
- **Gaps:** No migrations, no services

---

### 5. GlobalMaster (85%) — Global Reference Data
**Path:** `Modules/GlobalMaster/`
**Purpose:** Global reference data — countries, states, boards, languages, dropdowns, activity logs
- **Controllers (15):** CountryController, StateController, CityController, DistrictController, BoardController, LanguageController, ModuleController, PlanController, GeographySetupController, AcademicSessionController, DropdownController, ActivityLogController, OrganizationController, NotificationController, SessionBoardSetupController
- **Models (12):** Country, State, City, District, Board, Language, Dropdown, Plan, Module, Media, ActivityLog, DropdownNeed
- **Migrations:** 6
- **Key Features:** Global reference management, dropdown configuration, activity tracking

---

### 6. Hpc (80%) — Higher-Order Pedagogical Competencies
**Path:** `Modules/Hpc/`
**Purpose:** Competency-based learning assessment framework
- **Controllers (11):** HpcController, HpcParametersController, CircularGoalsController, LearningOutcomesController, LearningActivitiesController, StudentHpcEvaluationController, HpcPerformanceDescriptorController, TopicEquivalencyController, KnowledgeGraphValidationController, SyllabusCoverageSnapshotController, QuestionMappingController
- **Models (15):** CircularGoals, HpcLevels, HpcParameters, HpcPerformanceDescriptor, KnowledgeGraphValidation, LearningActivities, LearningActivityType, LearningOutcomes, StudentHpcEvaluation, StudentHpcSnapshot, SyllabusCoverageSnapshot, TopicEquivalency, OutcomesEntityJnt, OutcomesQuestionJnt, CircularGoalCompetencyJnt
- **Views:** 53
- **Key Features:** Competency mapping, learning outcome tracking, HPC evaluation, performance assessment
- **Gaps:** No migrations

---

### 7. LmsExam (85%) — Exam Management
**Path:** `Modules/LmsExam/`
**Purpose:** Exam creation, blueprint design, paper sets, allocation, and grading
- **Controllers (11):** LmsExamController, ExamTypeController, ExamAllocationController, ExamBlueprintController, ExamPaperController, ExamPaperSetController, PaperSetQuestionController, ExamScopeController, ExamStudentGroupController, ExamStudentGroupMemberController, ExamStatusEventController
- **Models (11):** Exam, ExamType, ExamAllocation, ExamBlueprint, ExamPaper, ExamPaperSet, ExamScope, ExamStudentGroup, ExamStudentGroupMember, ExamStatusEvent, PaperSetQuestion
- **Views:** 58
- **Key Features:** Multi-paper exams, exam allocation, blueprint design, scope management
- **Gaps:** No migrations

---

### 8. StudentFee (80%) — Fee Management
**Path:** `Modules/StudentFee/`
**Purpose:** Student fee management, invoicing, scholarships, and payment tracking
- **Controllers (9):** StudentFeeController, StudentFeeManagementController, FeeInstallmentController, FeeInvoiceController, FeeHeadMasterController, FeeFineRuleController, FeeStudentAssignmentController, FeeScholarshipController, FeeConcessionTypeController
- **Models (20):** FeeStructureMaster, FeeStructureDetail, FeeStudentAssignment, FeeInvoice, FeeTransaction, FeeTransactionDetail, FeeReceipt, FeeInstallment, FeeHeadMaster, FeeGroupMaster, FeeGroupHeadsJnt, FeeScholarship, FeeScholarshipApplication, FeeScholarshipApprovalHistory, FeeStudentConcession, FeeConcessionType, FeeFineRule, FeeFineTransaction, and more
- **Views:** 69
- **Key Features:** Complex fee structures, installments, scholarships, fine rules, concessions
- **Gaps:** No migrations, no services

---

### 9. Syllabus (85%) — Curriculum Management
**Path:** `Modules/Syllabus/`
**Purpose:** Curriculum design — topics, lessons, competencies, Bloom's taxonomy, study materials
- **Controllers (15):** SyllabusController, TopicController, LessonController, CompetencieController, CompetencyTypeController, BloomTaxonomyController, CognitiveSkillController, TopicCompetencyController, PerformanceCategoryController, ComplexityLevelController, GradeDivisionController, QuestionTypeController, QuestionTypeSpecificityController, SyllabusScheduleController, TopicLevelTypeController
- **Models (22):** Topic, Lesson, SyllabusSchedule, TopicDependencies, Competencie, CompetencyType, TopicCompetency, QuestionType, QueTypeSpecifity, PerformanceCategory, ComplexityLevel, LearningActivityType, StudyMaterial, StudyMaterialType, Book, BookAuthor, AuthorBook, BookClassSubject, BookTopicMapping, BloomTaxonomy, CognitiveSkill, GradeDivisionMaster, TopicLevelType
- **Views:** 78
- **Imports:** TopicImport, LessonImport, LessonReadOnly
- **Key Features:** Multi-dimensional curriculum, competency mapping, Bloom's taxonomy integration
- **Gaps:** No migrations

---

### 10. SmartTimetable (85%) — Constraint-Based Scheduling
**Path:** `Modules/SmartTimetable/`
**Purpose:** Intelligent timetable generation using constraint programming
- **Controllers (34):** SmartTimetableController (multiple versions), TimetableController, ActivityController (multiple versions), SubActivityController, ConstraintController, ConstraintTypeController, PeriodSetController, PeriodController, PeriodTypeController, DayTypeController, SchoolDayController, SchoolShiftController, AcademicTermController, TeacherAvailabilityController, ClassSubjectSubgroupController, RequirementConsolidationController, and 20+ more
- **Models (41):** AcademicTerm, ClassTimetableType, ClassWorkingDay, SlotRequirement, Activity, SubActivity, ActivityTeacher, ClassSubjectGroup, ClassSubjectSubgroup, ClassSubgroupMember, Constraint, ConstraintType, ConstraintCategoryScope, ConstraintViolation, GenerationRun, ConflictDetection, ChangeLog, SubstitutionLog, PeriodSet, PeriodSetPeriod, PeriodType, DayType, ResourceBooking, and more
- **Services (36):** ActivityScoreService, DatabaseConstraintService, + Constraints/, Generator/, Solver/, Storage/ service directories
- **Views:** 193
- **Exceptions:** HardConstraintViolationException
- **Key Features:** Constraint-based scheduling, conflict detection, auto-generation with heuristics
- **Notes:** Most service-rich and sophisticated module. Multiple controller versions suggest active development.
- **Gaps:** No migrations

---

### 11. Transport (80%) — Transport Management
**Path:** `Modules/Transport/`
**Purpose:** Fleet management, student transport, routes, fees, attendance
- **Controllers (31):** TransportMasterController, TransportDashboardController, TransportReportController, VehicleController, VehicleMgmtController, TptVehicleMaintenanceController, TptVehicleFuelController, TptVehicleServiceRequestController, TptDailyVehicleInspectionController, DriverRouteVehicleController, DriverAttendanceController, DriverHelperController, RouteController, PickupPointController, PickupPointRouteController, RouteSchedulerController, ShiftController, TripController, StudentAllocationController, StudentBoardingController, StudentAttendanceController, FeeMasterController, StudentRouteFeesController, FeeCollectionController, FineMasterController, TptStudentFineDetailController, NewTripController, LiveTripController, TripMgmtController, AttendanceDeviceController
- **Models (36):** Vehicle models, maintenance logs, fuel tracking, inspections, Driver, DriverHelper, Route, PickupPoint, scheduling models, student allocation, boarding, fee master, collection, fines
- **Views:** 151
- **Migrations:** 3
- **Key Features:** Fleet management, student transportation, route optimization, attendance tracking, fee collection

---

### 12. QuestionBank (80%) — Central Question Repository
**Path:** `Modules/QuestionBank/`
**Purpose:** Centralized question bank with import, versioning, tagging, and statistics
- **Controllers (7):** QuestionBankController, QuestionVersionController, QuestionTagController, QuestionUsageTypeController, QuestionMediaStoreController, QuestionStatisticController, AIQuestionGeneratorController
- **Models (17):** QuestionBank, QuestionOption, QuestionTag, QuestionVersion, QuestionTopic, QuestionPerformanceCategory, QuestionUsageLog, QuestionUsageType, QuestionStatistics, QuestionReviewLog, QuestionMedia, QuestionMediaStore, QuestionQuestionTag, QuestionPerformanceCategoryJnt, QuestionQuestionTagJnt, QuestionTopicJnt, QuestionStatistic
- **Views:** 38
- **Imports:** QuestionImport, QuestionReadOnly
- **Key Features:** Question creation/import, version management, topic mapping, usage tracking, AI generation support
- **Gaps:** No migrations

---

### 13. StudentProfile (80%) — Student Data Management
**Path:** `Modules/StudentProfile/`
**Purpose:** Complete student data — personal, academic, health, documents
- **Controllers (5):** StudentController, StudentProfileController, AttendanceController, MedicalIncidentController, StudentReportController
- **Models (14):** Student, StudentProfile, StudentDetail, StudentAcademicSession, StudentAddress, StudentDocument, StudentHealthProfile, StudentAttendance, StudentAttendanceCorrection, Guardian, StudentGuardianJnt, MedicalIncident, PreviousEducation, VaccinationRecord
- **Views:** 42
- **Exports:** StudentsExport
- **Emails:** StudentLoginCreated
- **Key Features:** Student lifecycle management, health tracking, document storage, family information
- **Gaps:** No migrations

---

### 14. SchoolSetup (75%) — School Infrastructure
**Path:** `Modules/SchoolSetup/`
**Purpose:** Core school setup — organizations, classes, sections, subjects, staff, infrastructure
- **Controllers (40):** OrganizationController, OrganizationGroupController, OrganizationAcademicSessionController, SchoolSetupController, SchoolClassController, SectionController, ClassGroupController, ClassSubjectGroupController, ClassSubjectManagementController, SubjectController, SubjectGroupController, SubjectGroupSubjectController, SubjectTypeController, SubjectClassMappingController, SubjectStudyFormatController, BuildingController, RoomController, RoomTypeController, DepartmentController, DesignationController, DisableReasonController, EmployeeProfileController, LeaveTypeController, LeaveConfigController, AttendanceTypeController, EntityGroupController, EntityGroupMemberController, UserController, UserRolePrmController, RolePermissionController, StudyFormatController, InfrasetupController, and more (multiple versions)
- **Models (42):** Organization, OrganizationGroup, OrganizationAcademicSession, OrganizationPlan, SchoolClass, ClassSection, Section, Building, Room, Employee, EmployeeProfile, Designation, Department, LeaveType, LeaveConfig, AttendanceType, DisableReason, EntityGroup, EntityGroupMember, Permission, Role, and more
- **Views:** 220 (largest view layer of all modules)
- **Events:** StudentRegistration
- **Notes:** Multiple controller versions indicate active development/refactoring
- **Gaps:** No migrations

---

### 15. LmsHomework (75%) — Homework Management
**Path:** `Modules/LmsHomework/`
**Purpose:** Homework assignment and submission with rule engine
- **Controllers (5):** LmsHomeworkController, ActionTypeController, HomeworkSubmissionController, RuleEngineConfigController, TriggerEventController
- **Models (5):** Homework, HomeworkSubmission, ActionType, RuleEngineConfig, TriggerEvent
- **Views:** 28
- **Key Features:** Assignment creation, auto-grading rule engine, submission tracking, trigger events
- **Gaps:** No migrations, no services

---

### 16. LmsQuiz (75%) — Quiz & Formative Assessment
**Path:** `Modules/LmsQuiz/`
**Purpose:** Quiz management with difficulty distribution
- **Controllers (5):** LmsQuizController, QuizAllocationController, QuizQuestionController, AssessmentTypeController, DifficultyDistributionConfigController
- **Models (6):** Quiz, QuizAllocation, QuizQuestion, AssessmentType, DifficultyDistributionConfig, DifficultyDistributionDetail
- **Views:** 29
- **Key Features:** Quiz creation with difficulty distribution, assessment types, student allocation
- **Gaps:** No migrations

---

### 17. Payment (75%) — Payment Gateway
**Path:** `Modules/Payment/`
**Purpose:** Payment gateway integration (Razorpay) and transaction management
- **Controllers (4):** PaymentController, PaymentGatewayController, PaymentCallbackController
- **Models (5):** Payment, PaymentGateway, PaymentHistory, PaymentRefund, PaymentWebhook
- **Services (2):** PaymentService, GatewayManager
- **Views:** 8
- **Key Features:** Razorpay integration, refund management, webhook handling, gateway abstraction
- **Gaps:** No migrations

---

### 18. Recommendation (75%) — AI Recommendation Engine
**Path:** `Modules/Recommendation/`
**Purpose:** AI-driven student recommendations for learning materials and activities
- **Controllers (10):** RecommendationController, StudentRecommendationController, RecommendationRuleController, RecTriggerEventController, RecommendationMaterialController, RecommendationModeController, DynamicMaterialTypeController, DynamicPurposeController, MaterialBundleController, RecAssessmentTypeController
- **Models (11):** StudentRecommendation, RecommendationRule, RecommendationMaterial, RecommendationMode, RecTriggerEvent, RecAssessmentType, DynamicMaterialType, DynamicPurpose, MaterialBundle, PerformanceSnapshot, BundleMaterialJnt
- **Views:** 48
- **Key Features:** Rule-based recommendations, dynamic material assignment, performance-triggered recommendations
- **Gaps:** No migrations, no services

---

### 19. LmsQuests (70%) — Quest-Based Learning
**Path:** `Modules/LmsQuests/`
**Purpose:** Quest/challenge-based learning activities
- **Controllers (4):** LmsQuestController, QuestAllocationController, QuestScopeController, QuestQuestionController
- **Models (4):** Quest, QuestAllocation, QuestScope, QuestQuestion
- **Views:** 23
- **Key Features:** Quest creation, question assignment, student allocation, scope management
- **Gaps:** No migrations

---

### 20. Vendor (70%) — Vendor Management
**Path:** `Modules/Vendor/`
**Purpose:** Vendor/supplier management for school procurement
- **Controllers (7):** VendorController, VendorDashboardController, VendorInvoiceController, VendorPaymentController, VendorAgreementController, VndItemController, VndUsageLogController
- **Models (8):** Vendor, VendorAgreement, VendorInvoice, VendorPayment, VendorItem, and relationship models
- **Views:** 35
- **Key Features:** Vendor profiles, agreements, invoicing, item tracking, usage logs
- **Gaps:** No migrations

---

### 21. SyllabusBooks (70%) — Textbook Mapping
**Path:** `Modules/SyllabusBooks/`
**Purpose:** Textbook and reference material mapping to syllabus topics
- **Controllers (4):** SyllabusBooksController, BookController, AuthorController, BookTopicMappingController
- **Models (6):** Book, BookAuthor, AuthorBook, BookClassSubject, BookTopicMapping, and relationship models
- **Views:** 17
- **Migrations:** 1
- **Key Features:** Book catalog, author management, topic-to-book mapping

---

### 22. Documentation (70%) — In-App Help System
**Path:** `Modules/Documentation/`
**Purpose:** In-app documentation and help articles
- **Controllers (3):** DocumentationController, DocumentationArticleController, DocumentationCategoryController
- **Models (2):** Article, Category
- **Migrations:** 3
- **Views:** 15
- **Key Features:** Article/category management with hierarchical organization

---

### 23. StudentPortal (50%) — Student-Facing Portal
**Path:** `Modules/StudentPortal/`
**Purpose:** Student portal — assignments, grades, fees, complaints
- **Controllers (3):** StudentPortalController, StudentPortalComplaintController, NotificationController
- **Models:** 0
- **Views:** 27
- **Key Features:** Student dashboard, assignment viewing, complaint filing
- **Gaps:** No models, no migrations, no services

---

### 24. SystemConfig (60%) — System Configuration
**Path:** `Modules/SystemConfig/`
**Purpose:** System-wide configuration and settings
- **Controllers (3):** SystemConfigController, MenuController, SettingController
- **Models (3):** Menu, Setting, and related
- **Views:** 8
- **Key Features:** Dynamic menu management, system-wide settings
- **Gaps:** No migrations

---

### 25. Scheduler (60%) — Job Scheduling
**Path:** `Modules/Scheduler/`
**Purpose:** Background job scheduling and management
- **Controllers (1):** SchedulerController
- **Models (2):** Schedule, ScheduleRun
- **Services (2):** SchedulerService, JobRegistry
- **Migrations:** 2
- **Contracts:** SchedulableJob
- **Enums:** SchedulerType
- **Key Features:** Scheduled job management, job registry, execution tracking

---

### 26. Dashboard (40%) — Navigation Hub
**Path:** `Modules/Dashboard/`
**Purpose:** Main dashboard/navigation hub
- **Controllers (1):** DashboardController
- **Models:** 0
- **Views (8):** foundational-setup, school-setup, core-configuration, operation-management, admission-student-management, support-management
- **Key Features:** Unified dashboard navigation
- **Gaps:** Skeleton only — needs analytics, widgets, and real data

---

### 27. Library (20%) — Library Management
**Path:** `Modules/Library/`
**Purpose:** Library book inventory, circulation, and management
- **Controllers (1):** LibraryController
- **Models:** 0
- **Views:** 2
- **Key Features:** Planned — not yet implemented
- **Gaps:** Needs full implementation from scratch

---

## Key Observations

### Architectural Patterns
- **MVC Pattern:** Standard Laravel with Controllers, Models, Views
- **Resource-Based Routing:** RESTful API design
- **Module Structure:** nwidart/laravel-modules pattern
- **Event-Driven:** Used in Complaint, Notification, SchoolSetup
- **Service Layer:** Implemented in SmartTimetable (36 services), Notification, Complaint, Payment, Scheduler
- **Junction Tables:** `_jnt` suffix pattern consistent with schema conventions

### Common Gaps Across Modules
1. **No database migrations** in: LmsExam, LmsQuiz, LmsQuests, Hpc, Syllabus, SchoolSetup, SmartTimetable, StudentProfile, Recommendation, Billing, QuestionBank, StudentFee, Vendor, Payment, Notification, LmsHomework, SystemConfig
2. **No service layer** in most modules (only SmartTimetable, Complaint, Notification, Payment, Scheduler have services)
3. **Empty API routes** in many modules — web routes implemented but API stubs empty
4. **No unit tests** across all modules

### Active Development Indicators
- Multiple backup/version files in SmartTimetable and SchoolSetup (e.g., controller versions)
- Backup service file in Notification (`NotificationService_25_02_2026`)
- Most recent development timestamps in late February 2026

### Schema ↔ Laravel Alignment
- Table prefix conventions (`sys_`, `std_`, `sch_`, etc.) align with Model naming in Laravel
- Junction table pattern (`_jnt`) consistent in both schema and Models
- `is_active` + `deleted_at` soft delete pattern should be verified in Models
