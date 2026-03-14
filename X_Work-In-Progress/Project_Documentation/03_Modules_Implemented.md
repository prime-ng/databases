# 03 — Modules Implemented

## Module Summary (29 Total)

| # | Module | Scope | Status | Models | Controllers | Tables |
|---|--------|-------|--------|--------|-------------|--------|
| 1 | Prime | Central | 100% | 27 | 20 | 27 (prm_*, bil_*, sys_*) |
| 2 | GlobalMaster | Central | 100% | 12 | 12 | 12 (glb_*) |
| 3 | SystemConfig | Central | 100% | 3 | 3 | 3 (sys_*) |
| 4 | Billing | Central | 100% | 6 | 6 | 8 (bil_*) |
| 5 | SchoolSetup | Tenant | 100% | 59 | 32 | ~25 (sch_*) |
| 6 | StudentProfile | Tenant | 100% | 13 | 5 | ~12 (std_*) |
| 7 | SmartTimetable | Tenant | 100% | 94 | 23 | ~45 (tt_*) |
| 8 | Transport | Tenant | 100% | 39 | 29 | ~35 (tpt_*) |
| 9 | Syllabus | Tenant | 100% | 21 | 16 | ~17 (slb_*) |
| 10 | SyllabusBooks | Tenant | 100% | 6 | 4 | ~8 (bok_*) |
| 11 | QuestionBank | Tenant | 100% | 17 | 7 | ~3+ (qns_*) |
| 12 | Notification | Tenant | 100% | 13 | 12 | ~7 (ntf_*) |
| 13 | Complaint | Tenant | 100% | 6 | 8 | 6 (cmp_*) |
| 14 | Vendor | Tenant | 100% | 8 | 7 | 7 (vnd_*) |
| 15 | Payment | Tenant | 100% | 5 | 4 | ~4 (pmt_*) |
| 16 | Dashboard | Tenant | 100% | 0 | 1 | 0 |
| 17 | Scheduler | Central | 100% | 2 | 1 | 2 |
| 18 | Documentation | Central | 100% | 2 | 3 | 3 (doc_*) |
| 19 | Hpc | Tenant | ~90% | 14 | 10 | ~12 (hpc_*) |
| 20 | Recommendation | Tenant | ~90% | 11 | 10 | ~10 (rec_*) |
| 21 | LmsExam | Tenant | ~80% | 11 | 11 | ~11 (lms_*) |
| 22 | LmsQuiz | Tenant | ~80% | 6 | 5 | ~6 (lms_*) |
| 23 | LmsHomework | Tenant | ~80% | 5 | 5 | ~5 (lms_*) |
| 24 | LmsQuests | Tenant | ~80% | 4 | 4 | ~4 (lms_*) |
| 25 | StudentFee | Tenant | ~80% | 19 | 10 | ~21 (fin_*) |
| 26 | StudentPortal | Tenant | Pending | 0 | 3 | 0 |
| 27 | Library | Tenant | Pending | 0 | 1 | 0 |
| **TOTAL** | | | | **381** | **283** | **~280+** |

---

## Detailed Module Documentation

### 1. Prime Module (Central SaaS Management)

**Scope:** Central | **Status:** 100% Complete

**Description:** Core module for managing the SaaS platform — tenants, plans, billing, users, roles, and permissions.

**Controllers (20):**
TenantController, TenantGroupController, TenantManagementController, UserController, UserRolePrmController, RolePermissionController, PrimeAuthController, PrimeController, AcademicSessionController, ActivityLogController, BoardController, DropdownController, DropdownMgmtController, DropdownNeedController, EmailController, LanguageController, MenuController, NotificationController, SalesPlanAndModuleMgmtController, SessionBoardSetupController, SettingController

**Models (27):**
Tenant, Domain, User, TenantPlan, TenantPlanRate, TenantPlanModule, TenantGroup, TenantInvoice, TenantInvoiceModule, TenantInvoicingAuditLog, TenantInvoicingPayment, Role, Permission, Menu, MenuModule, Setting, Dropdown, DropdownNeed, DropdownNeedDropdown, DropdownNeedTableJnt, DropdownMgmtModel, AcademicSession, Language, Board, Media

**Key Routes:** `/prime/*` — Tenant CRUD, user management, role-permission assignment, academic sessions, boards, dropdown management

**Key Functionality:**
- Tenant creation with UUID, domain assignment, database provisioning
- Plan management with module-level feature toggling
- Central RBAC with 6 roles (Super Admin, Manager, Accounting, Invoicing, Student, Parent)
- Activity logging and audit trails
- Dropdown/lookup management system

---

### 2. GlobalMaster Module

**Scope:** Central | **Status:** 100% Complete

**Description:** Shared reference data accessible across all tenants — geographic data, educational boards, languages, modules.

**Controllers (12):**
CountryController, StateController, DistrictController, CityController, BoardController, LanguageController, ModuleController, PlanController, AcademicSessionController, ActivityLogController, DropdownController, OrganizationController, GeographySetupController, SessionBoardSetupController, GlobalMasterController, NotificationController

**Models (12):**
Country, State, District, City, Board (global_master_mysql connection), Language, Module, Plan, Dropdown, DropdownNeed, ActivityLog, Media

**Key Routes:** `/global-master/*` — Country/state/city/district CRUD, board management, language management, module management

---

### 3. SchoolSetup Module

**Scope:** Tenant | **Status:** 100% Complete

**Description:** Complete school infrastructure setup — classes, sections, subjects, teachers, rooms, buildings, employees, departments.

**Controllers (32):**
OrganizationController, SchoolClassController, SectionController, SubjectController, TeacherController, RoomController, RoomTypeController, BuildingController, EmployeeProfileController, DepartmentController, DesignationController, LeaveTypeController, LeaveConfigController, StudyFormatController, SubjectGroupController, SubjectGroupSubjectController, ClassGroupController, EntityGroupController, EntityGroupMemberController, StudentController, UserController, UserRolePrmController, RolePermissionController, and more

**Models (59):**
Organization, OrganizationGroup, SchoolClass, Section, ClassSection, Subject, SubjectGroup, SubjectGroupSubject, SubjectTeacher, Teacher, TeacherProfile, TeacherCapability, Room, RoomType, Building, Employee, EmployeeProfile, Designation, Department, LeaveType, LeaveConfig, StudyFormat, SubjectStudyFormat, EntityGroup, EntityGroupMember, ClassGroup, DisableReason, QuestionType, User, Role, Permission, and more

**Key Routes:** `/school-setup/*` — Organization setup, class/section management, subject mapping, teacher assignment, infrastructure management

**Key Functionality:**
- Organization hierarchy with academic session binding
- Class-Section-Subject mapping with study formats
- Teacher profile management with capability tracking
- Room/building infrastructure with type classification
- Employee management with departments and designations
- Entity grouping for flexible staff organization

---

### 4. SmartTimetable Module

**Scope:** Tenant | **Status:** 100% Complete

**Description:** AI-powered automatic timetable generation using a FET (Feasible Exam Timetabling) solver with pluggable constraint system. The most complex module in the system.

**Controllers (23):**
TimetableController, SmartTimetableController, ActivityController, AcademicTermController, ConstraintController, ConstraintTypeController, DayTypeController, PeriodController, PeriodSetController, PeriodSetPeriodController, PeriodTypeController, SchoolDayController, WorkingDayController, TeacherAvailabilityController, TeacherUnavailableController, RoomUnavailableController, TimetableTypeController, TtConfigController, TtGenerationStrategyController, SlotRequirementController, RequirementConsolidationController, ClassSubjectSubgroupController, and more

**Models (94):**
Timetable, TimetableCell, TimetableCellTeacher, Activity, SubActivity, ActivityTeacher, ActivityPriority, AcademicTerm, TimetableType, PeriodSet, PeriodSetPeriod, PeriodType, SchoolDay, DayType, WorkingDay, ClassWorkingDay, ClassTimetableType, Constraint, ConstraintType, ConstraintCategory, ConstraintScope, ConstraintTargetType, ConstraintGroup, ConstraintGroupMember, ConstraintTemplate, ConstraintViolation, GenerationRun, GenerationQueue, OptimizationRun, OptimizationIteration, OptimizationMove, TeacherAvailablity, TeacherUnavailable, TeacherAbsences, TeacherWorkload, RoomAvailability, RoomUnavailable, RoomUtilization, ResourceBooking, ConflictDetection, ConflictResolutionSession, SubstitutionLog, SubstitutionPattern, SubstitutionRecommendation, WhatIfScenario, VersionComparison, ImpactAnalysisSession, EscalationRule, MlModel, TrainingData, PredictionLog, PatternResult, ApprovalWorkflow, ApprovalLevel, ApprovalRequest, BatchOperation, ChangeLog, AnalyticsDailySnapshot, and more

**Services (5):**
- **ActivityScoreService** — Difficulty/priority scoring with 5-component formula
- **RoomAvailabilityService** — Room availability generation and scarcity calculation
- **SubActivityService** — Sub-activity generation for multi-period blocks
- **DatabaseConstraintService** — Constraint loading and validation
- **TimetableStorageService** — Atomic timetable persistence

**Solver Components:**
- **FETSolver** — Main scheduling algorithm (50K max iterations, 25s timeout)
- **ConstraintManager** — Hard/soft constraint evaluation
- **ConstraintFactory** — Creates constraints from DB records
- **SlotEvaluator / SlotGenerator** — Candidate slot evaluation and ordering

**Key Routes:** `/smart-timetable/*` — Activities, periods, constraints, teacher availability, room scheduling, timetable generation

**Key Functionality:**
- Automatic timetable generation with configurable constraints
- Hard constraints (teacher conflicts) and soft constraints (preferences)
- Teacher/room availability tracking with unavailability management
- Version comparison and impact analysis
- Substitution management and recommendations
- Approval workflows for timetable publishing
- ML model integration for pattern prediction
- Batch operations for bulk timetable management

---

### 5. Transport Module

**Scope:** Tenant | **Status:** 100% Complete

**Controllers (29):**
VehicleController, RouteController, TripController, DriverHelperController, PickupPointController, ShiftController, StudentAllocationController, StudentBoardingController, StudentAttendanceController, DriverAttendanceController, LiveTripController, FeeMasterController, FeeCollectionController, FineMasterController, VehicleMgmtController, TripMgmtController, TransportDashboardController, TransportReportController, TptDailyVehicleInspectionController, TptVehicleFuelController, TptVehicleMaintenanceController, TptVehicleServiceRequestController, AttendanceDeviceController, RouteSchedulerController, and more

**Models (39):**
Vehicle, Route, Shift, PickupPoint, DriverHelper, DriverRouteVehicleJnt, TptTrip, TptLiveTrip, TptTripIncidents, TptGpsAlerts, TptGpsTripLog, StudentBoardingLog, TptStudentAllocationJnt, TptDriverAttendance, TptDailyVehicleInspection, TptVehicleMaintenance, TptVehicleServiceRequest, TptVehicleFuel, TptFeeMaster, TptFeeCollection, TptFineMaster, TptStudentFineDetail, AttendanceDevice, TptFeatureStore, MlModels, MlModelFeatures, TptNotificationLog, TptRecommendationHistory, and more

**Key Functionality:**
- Vehicle fleet management with inspection and maintenance tracking
- Route planning with pickup points and scheduling
- Real-time trip tracking with GPS logging
- Student-route allocation and boarding logs
- Driver attendance with QR code support
- Fee collection and fine management
- ML-based transport recommendations
- Dashboard and reporting

---

### 6. StudentProfile Module

**Scope:** Tenant | **Status:** 100% Complete

**Controllers (5):**
StudentController, StudentProfileController, AttendanceController, MedicalIncidentController, StudentReportController

**Models (13):**
Student, StudentDetail, StudentProfile, StudentAcademicSession, StudentAddress, StudentAttendance, StudentAttendanceCorrection, StudentDocument, StudentHealthProfile, VaccinationRecord, MedicalIncident, Guardian, StudentGuardianJnt, PreviousEducation

**Key Functionality:**
- Comprehensive student records (personal, academic, health)
- Guardian management with many-to-many relationship
- Attendance tracking with correction workflow
- Health profiles and vaccination records
- Medical incident logging
- Document management (certificates, IDs)
- Previous education tracking
- Student reporting

---

### 7. StudentFee Module

**Scope:** Tenant | **Status:** ~80% Complete

**Controllers (10):**
StudentFeeController, StudentFeeManagementController, FeeHeadMasterController, FeeInstallmentController, FeeInvoiceController, FeeConcessionController, FeeConcessionTypeController, FeeFineRuleController, FeeScholarshipController, FeeStudentAssignmentController

**Models (19):**
FeeStructureMaster, FeeStructureDetail, FeeHeadMaster, FeeGroupMaster, FeeGroupHeadsJnt, FeeInstallment, FeeStudentAssignment, FeeStudentConcession, FeeConcessionType, FeeInvoice, FeeReceipt, FeeTransaction, FeeTransactionDetail, FeeFineRule, FeeFineTransaction, FeePaymentGatewayLog, FeeScholarship, FeeScholarshipApplication, FeeScholarshipApprovalHistory, FeeNameRemovalLog

**Key Functionality:**
- Fee structure definition with heads and groups
- Installment-based payment plans
- Student-wise fee assignment and concessions
- Invoice generation and receipt tracking
- Fine rule engine with automatic calculation
- Scholarship management with approval workflow
- Payment gateway integration logging

---

### 8. Syllabus Module

**Scope:** Tenant | **Status:** 100% Complete

**Controllers (16):**
SyllabusController, LessonController, TopicController, CompetencieController, CompetencyTypeController, BloomTaxonomyController, CognitiveSkillController, ComplexityLevelController, PerformanceCategoryController, QuestionTypeController, QuestionTypeSpecificityController, GradeDivisionController, TopicCompetencyController, TopicLevelTypeController, SyllabusScheduleController

**Models (21):**
Lesson, Topic, Competencie, CompetencyType, BloomTaxonomy, CognitiveSkill, ComplexityLevel, PerformanceCategory, StudyMaterial, StudyMaterialType, TopicCompetency, TopicDependencies, TopicLevelType, Book, BookAuthor, AuthorBook, BookClassSubject, BookTopicMapping, QuestionType, QueTypeSpecifity, GradeDivisionMaster, SyllabusSchedule

**Key Functionality:**
- Curriculum structure: Lessons → Topics → Competencies
- Bloom's taxonomy and cognitive skill mapping
- Complexity level classification
- Study material management with type categorization
- Topic dependency tracking for learning paths
- Syllabus scheduling for academic planning
- Grade division configuration

---

### 9. QuestionBank Module

**Scope:** Tenant | **Status:** 100% Complete

**Controllers (7):**
QuestionBankController, AIQuestionGeneratorController, QuestionTagController, QuestionVersionController, QuestionStatisticController, QuestionUsageTypeController, QuestionMediaStoreController

**Models (17):**
QuestionBank, QuestionOption, QuestionTag, QuestionQuestionTag, QuestionQuestionTagJnt, QuestionTopic, QuestionTopicJnt, QuestionPerformanceCategory, QuestionPerformanceCategoryJnt, QuestionMedia, QuestionMediaStore, QuestionVersion, QuestionStatistic, QuestionUsageLog, QuestionUsageType, QuestionReviewLog

**Key Functionality:**
- Question creation linked to subjects, classes, lessons, topics
- Bloom taxonomy and complexity level classification
- Multiple question options with correct answer marking
- Question tagging and topic mapping (many-to-many)
- Version history tracking
- Usage statistics and review logs
- Media attachment support
- AI-powered question generation

---

### 10. Complaint Module

**Scope:** Tenant | **Status:** 100% Complete

**Controllers (8):**
ComplaintController, ComplaintCategoryController, ComplaintActionController, DepartmentSlaController, MedicalCheckController, AiInsightController, ComplaintDashboardController, ComplaintReportController

**Models (6):**
Complaint, ComplaintCategory, ComplaintAction, DepartmentSla, MedicalCheck, AiInsight

**Services (2):**
- **ComplaintAIInsightEngine** — Sentiment analysis, risk scoring, category prediction
- **ComplaintDashboardService** — Metrics aggregation, SLA breach tracking

**Key Functionality:**
- Complaint submission with severity and priority classification
- Hierarchical category system (parent/child)
- Action tracking with role-based assignment
- Department SLA configuration and monitoring
- Medical check integration for health-related complaints
- AI-powered sentiment analysis and risk scoring
- Dashboard with Pareto, hotspot, and trend analytics
- Comprehensive reporting

---

### 11. LMS Modules (Exam, Quiz, Homework, Quests)

**Scope:** Tenant | **Status:** ~80% Complete

#### LmsExam (11 controllers, 11 models)
- Exam creation with types, scopes, and blueprints
- Paper generation with multiple sets
- Student group allocation
- Question mapping from QuestionBank

#### LmsQuiz (5 controllers, 6 models)
- Quiz creation linked to syllabus (class, subject, lesson, topic)
- Difficulty distribution configuration
- Student allocation
- Assessment type management

#### LmsHomework (5 controllers, 5 models)
- Homework assignment and submission tracking
- Rule engine configuration
- Trigger events for automated actions

#### LmsQuests (4 controllers, 4 models)
- Learning quest creation with scoped questions
- Student allocation for personalized paths

---

### 12. HPC Module (Holistic Progress Card)

**Scope:** Tenant | **Status:** ~90% Complete

**Controllers (10):**
HpcController, LearningOutcomesController, LearningActivitiesController, StudentHpcEvaluationController, HpcParametersController, HpcPerformanceDescriptorController, CircularGoalsController, KnowledgeGraphValidationController, TopicEquivalencyController, SyllabusCoverageSnapshotController, QuestionMappingController

**Models (14):**
LearningOutcomes, StudentHpcEvaluation, StudentHpcSnapshot, LearningActivities, LearningActivityType, HpcLevels, HpcParameters, HpcPerformanceDescriptor, CircularGoals, CircularGoalCompetencyJnt, OutcomesEntityJnt, OutcomesQuestionJnt, KnowledgeGraphValidation, TopicEquivalency, SyllabusCoverageSnapshot

**Key Functionality:**
- Learning outcomes mapped to Bloom's taxonomy
- Student evaluation and snapshot tracking
- Learning activities with type classification
- Circular goals linked to competencies
- Knowledge graph validation
- Topic equivalency mapping
- Syllabus coverage snapshots

---

### 13. Recommendation Module

**Scope:** Tenant | **Status:** ~90% Complete

**Controllers (10):**
RecommendationController, StudentRecommendationController, RecommendationRuleController, RecommendationMaterialController, MaterialBundleController, DynamicMaterialTypeController, DynamicPurposeController, RecAssessmentTypeController, RecommendationModeController, RecTriggerEventController

**Models (11):**
StudentRecommendation, RecommendationRule, RecommendationMaterial, MaterialBundle, BundleMaterialJnt, PerformanceSnapshot, DynamicMaterialType, DynamicPurpose, RecAssessmentType, RecTriggerEvent, RecommendationMode

**Key Functionality:**
- Rule-based recommendation engine
- Student recommendations linked to performance categories
- Material bundles for grouped learning resources
- Dynamic material types and purposes
- Trigger event configuration for automated recommendations
- Multiple recommendation modes

---

### 14–17. Other Modules

#### Notification (13 models, 12 controllers)
Multi-channel notification system (Email, In-App, SMS) with templates, delivery logging, and user preferences.

#### Vendor (8 models, 7 controllers)
Vendor management with agreements, items, invoices, payments, and usage tracking.

#### Payment (5 models, 4 controllers)
Razorpay payment gateway integration with order creation, verification, webhooks, and refunds.

#### Billing (6 models, 6 controllers)
Central billing management with cycles, invoicing, payments, and audit logs.

#### Documentation (2 models, 3 controllers)
Help article management with categories and image uploads.

#### Scheduler (2 models, 1 controller)
Job scheduling with CRON expressions, execution logging, and configurable job registry.

#### Dashboard (0 models, 1 controller)
Admin dashboards for various operational views.

#### StudentPortal (0 models, 3 controllers)
Student-facing portal with academic information, payment, and complaint access. (Pending full implementation)

#### Library (0 models, 1 controller)
Library management placeholder. (Pending implementation)
