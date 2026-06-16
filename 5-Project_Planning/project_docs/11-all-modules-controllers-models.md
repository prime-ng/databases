# All Modules — Controllers & Models Reference

## PRIME (CENTRAL) MODULES

---

### Prime [PRIME] — Status: ~80%
**Table Prefix:** prm_*
**Controllers:** 22 | **Models:** 27

**Controllers:**
AcademicSessionController, ActivityLogController, BoardController, DropdownController, DropdownMgmtController, DropdownNeedController, EmailController, LanguageController, MenuController, NotificationController, PrimeAuthController, PrimeController, RolePermissionController, SalesPlanAndModuleMgmtController, SessionBoardSetupController, SettingController, TenantController, TenantGroupController, TenantManagementController, UserController, UserRolePrmController

**Models:**
AcademicSession, ActivityLog, Board, Domain, Dropdown, DropdownMgmtModel, DropdownNeed, DropdownNeedDropdown, DropdownNeedTableJnt, Language, Media, Menu, MenuModule, Permission, Role, Setting, Tenant, TenantGroup, TenantInvoice, TenantInvoiceModule, TenantInvoicingAuditLog, TenantInvoicingPayment, TenantPlan, TenantPlanBillingSchedule, TenantPlanModule, TenantPlanRate, User

**Views:** `Modules/Prime/resources/views/` (24 folders)
**Migrations:** `Modules/Prime/database/migrations/` (37 files) — central
**Routes:** `routes/web.php`

---

### GlobalMaster [PRIME] — Status: ~82%
**Table Prefix:** glb_*
**Controllers:** 15 | **Models:** 12

**Controllers:**
AcademicSessionController, ActivityLogController, CityController, CountryController, DistrictController, DropdownController, GeographySetupController, GlobalMasterController, LanguageController, ModuleController, NotificationController, OrganizationController, PlanController, SessionBoardSetupController, StateController

**Models:**
ActivityLog, Board, City, Country, District, Dropdown, DropdownNeed, Language, Media, Module, Plan, State

**Routes:** `routes/web.php`

---

### Billing [PRIME] — Status: ~70%
**Table Prefix:** bil_*
**Controllers:** 6 | **Models:** 6

**Controllers:**
BillingCycleController, BillingManagementController, InvoicingAuditLogController, InvoicingController, InvoicingPaymentController, SubscriptionController

**Models:**
BilTenantInvoice, BillOrgInvoicingModulesJnt, BillTenatEmailSchedule, BillingCycle, InvoicingAuditLog, InvoicingPayment

**Routes:** `routes/web.php`

---

### SystemConfig [PRIME] — Status: ~75%
**Table Prefix:** sys_*
**Controllers:** 3 | **Models:** 3

**Controllers:** MenuController, SettingController, SystemConfigController
**Models:** Menu, Setting, Translation

**Routes:** `routes/web.php`

---

### Documentation [PRIME] — Status: 100%
**Table Prefix:** doc_*
**Controllers:** 3 | **Models:** 2

**Controllers:** DocumentationArticleController, DocumentationCategoryController, DocumentationController
**Models:** Article, Category

**Routes:** `routes/web.php`

---

## TENANT (SCHOOL) MODULES

---

### SchoolSetup [TENANT] — Status: ~80%
**Table Prefix:** sch_*
**Controllers:** 34 | **Models:** 42

**Controllers:**
AttendanceTypeController, BuildingController, ClassGroupController, ClassSubjectGroupController, ClassSubjectManagementController, DepartmentController, DesignationController, DisableReasonController, EmployeeProfileController, EntityGroupController, EntityGroupMemberController, InfrasetupController, LeaveConfigController, LeaveTypeController, OrganizationAcademicSessionController, OrganizationController, OrganizationGroupController, RolePermissionController, RoomController, RoomTypeController, SchCategoryController, SchoolClassController, SchoolSetupController, SectionController, StudyFormatController, SubjectClassMappingController, SubjectController, SubjectGroupController, SubjectGroupSubjectController, SubjectStudyFormatController, SubjectTypeController, TeacherController, UserController, UserRolePrmController

**Models:**
AttendanceType, Building, ClassSection, Department, Designation, DisableReason, Employee, EmployeeProfile, EntityGroup, EntityGroupMember, LeaveConfig, LeaveType, Organization, OrganizationAcademicSession, OrganizationGroup, OrganizationPlan, OrganizationPlanRate, Permission, Role, Room, RoomType, SchCategory, SchClassGroupsJnt, SchoolClass, Section, StudyFormat, Subject, SubjectGroup, SubjectGroupSubject, SubjectStudyFormat, SubjectTeacher, SubjectType, Teacher, TeacherCapability, TeacherProfile, User

**Routes:** `routes/tenant.php` + `Modules/SchoolSetup/routes/web.php`

---

### SmartTimetable [TENANT] — Status: ~60%
**Table Prefix:** tt_*
**Controllers:** 27 | **Models:** 86

**Controllers:**
AcademicTermController, ActivityController, ClassSubjectSubgroupController, ConstraintController, ConstraintTypeController, DayTypeController, ParallelGroupController, PeriodController, PeriodSetController, PeriodSetPeriodController, PeriodTypeController, RequirementConsolidationController, RoomUnavailableController, SchoolDayController, SchoolShiftController, SchoolTimingProfileController, SlotRequirementController, SmartTimetableController, TeacherAssignmentRoleController, TeacherAvailabilityController, TeacherUnavailableController, TimetableController, TimetableTypeController, TimingProfileController, TtConfigController, TtGenerationStrategyController, WorkingDayController

**Models:** 86 models (Activity, Constraint, TimetableCell, ParallelGroup, GenerationRun, FETSolver services, etc.)

**Routes:** `routes/tenant.php`

---

### Transport [TENANT] — Status: ~82%
**Table Prefix:** tpt_*
**Controllers:** 31 | **Models:** 36

**Controllers:**
AttendanceDeviceController, DriverAttendanceController, DriverHelperController, DriverRouteVehicleController, FeeCollectionController, FeeMasterController, FineMasterController, LiveTripController, NewTripController, PickupPointController, PickupPointRouteController, RouteController, RouteSchedulerController, ShiftController, StaffMgmtController, StudentAllocationController, StudentAttendanceController, StudentBoardingController, StudentRouteFeesController, TptDailyVehicleInspectionController, TptStudentFineDetailController, TptVehicleFuelController, TptVehicleMaintenanceController, TptVehicleServiceRequestController, TransportDashboardController, TransportMasterController, TransportReportController, TripController, TripMgmtController, VehicleController, VehicleMgmtController

**Routes:** `routes/tenant.php`

---

### Hpc [TENANT] — Status: ~68%
**Table Prefix:** hpc_*
**Controllers:** 15 | **Models:** 26

**Controllers:**
CircularGoalsController, HpcController, HpcParametersController, HpcPerformanceDescriptorController, HpcTemplatePartsController, HpcTemplateRubricsController, HpcTemplateSectionsController, HpcTemplatesController, KnowledgeGraphValidationController, LearningActivitiesController, LearningOutcomesController, QuestionMappingController, StudentHpcEvaluationController, SyllabusCoverageSnapshotController, TopicEquivalencyController

**Models:**
CircularGoalCompetencyJnt, CircularGoals, HpcLevels, HpcParameters, HpcPerformanceDescriptor, HpcReport, HpcReportItem, HpcReportTable, HpcTemplateParts, HpcTemplatePartsItems, HpcTemplateRubricItems, HpcTemplateRubrics, HpcTemplateSectionItems, HpcTemplateSections, HpcTemplateSectionTable, HpcTemplates, KnowledgeGraphValidation, LearningActivities, LearningActivityType, LearningOutcomes, OutcomesEntityJnt, OutcomesQuestionJnt, StudentHpcEvaluation, StudentHpcSnapshot, SyllabusCoverageSnapshot, TopicEquivalency

**Routes:** `routes/tenant.php`

---

### StudentFee [TENANT] — Status: ~60%
**Table Prefix:** fin_*
**Controllers:** 15 | **Models:** 23

**Controllers:**
FeeConcessionTypeController, FeeFineRuleController, FeeFineTransactionController, FeeGroupMasterController, FeeHeadMasterController, FeeInstallmentController, FeeInvoiceController, FeeScholarshipApplicationController, FeeScholarshipController, FeeStructureMasterController, FeeStudentAssignmentController, FeeStudentConcessionController, FeeTransactionController, StudentFeeController, StudentFeeManagementController

**Routes:** `routes/tenant.php`

---

### StudentProfile [TENANT] — Status: ~80%
**Table Prefix:** std_*
**Controllers:** 5 | **Models:** 14

**Controllers:**
AttendanceController, MedicalIncidentController, StudentController, StudentProfileController, StudentReportController

**Models:**
Guardian, MedicalIncident, PreviousEducation, Student, StudentAcademicSession, StudentAddress, StudentAttendance, StudentAttendanceCorrection, StudentDetail, StudentDocument, StudentGuardianJnt, StudentHealthProfile, StudentProfile, VaccinationRecord

**Routes:** `routes/tenant.php`

---

### Syllabus [TENANT] — Status: ~78%
**Table Prefix:** slb_*
**Controllers:** 15 | **Models:** 22

**Controllers:**
BloomTaxonomyController, CognitiveSkillController, CompetencieController, CompetencyTypeController, ComplexityLevelController, GradeDivisionController, LessonController, PerformanceCategoryController, QuestionTypeController, QuestionTypeSpecificityController, SyllabusController, SyllabusScheduleController, TopicCompetencyController, TopicController, TopicLevelTypeController

**Routes:** `routes/tenant.php`

---

### QuestionBank [TENANT] — Status: ~75%
**Table Prefix:** qns_*
**Controllers:** 7 | **Models:** 17

**Controllers:**
AIQuestionGeneratorController, QuestionBankController, QuestionMediaStoreController, QuestionStatisticController, QuestionTagController, QuestionUsageTypeController, QuestionVersionController

**Routes:** `routes/tenant.php`

---

### Notification [TENANT] — Status: ~55%
**Table Prefix:** ntf_*
**Controllers:** 12 | **Models:** 14

**Controllers:**
ChannelMasterController, DeliveryQueueController, NotificationManageController, NotificationTargetController, NotificationTemplateController, NotificationThreadController, NotificationThreadMemberController, ProviderMasterController, ResolvedRecipientController, TargetGroupController, TemplateController, UserPreferenceController

**Routes:** `routes/tenant.php`

---

### Complaint [TENANT] — Status: ~70%
**Table Prefix:** cmp_*
**Controllers:** 8 | **Models:** 6

**Controllers:**
AiInsightController, ComplaintActionController, ComplaintCategoryController, ComplaintController, ComplaintDashboardController, ComplaintReportController, DepartmentSlaController, MedicalCheckController

**Routes:** `routes/tenant.php`

---

### Vendor [TENANT] — Status: ~60%
**Table Prefix:** vnd_*
**Controllers:** 7 | **Models:** 8

**Controllers:**
VendorAgreementController, VendorController, VendorDashboardController, VendorInvoiceController, VendorPaymentController, VndItemController, VndUsageLogController

**Routes:** `routes/tenant.php`

---

### Payment [TENANT] — Status: ~45%
**Table Prefix:** pay_*
**Controllers:** 4 | **Models:** 5

**Controllers:**
PaymentCallbackController, PaymentController, PaymentGatewayController

**Routes:** `routes/tenant.php`

---

### LmsExam [TENANT] — Status: ~65%
**Table Prefix:** exm_*
**Controllers:** 11 | **Models:** 11

**Controllers:**
ExamAllocationController, ExamBlueprintController, ExamPaperController, ExamPaperSetController, ExamScopeController, ExamStatusEventController, ExamStudentGroupController, ExamStudentGroupMemberController, ExamTypeController, LmsExamController, PaperSetQuestionController

**Routes:** `routes/tenant.php`

---

### LmsQuiz [TENANT] — Status: ~72%
**Controllers:** 5 | **Models:** 6

**Controllers:** AssessmentTypeController, DifficultyDistributionConfigController, LmsQuizController, QuizAllocationController, QuizQuestionController

---

### LmsHomework [TENANT] — Status: ~60%
**Controllers:** 5 | **Models:** 5

**Controllers:** ActionTypeController, HomeworkSubmissionController, LmsHomeworkController, RuleEngineConfigController, TriggerEventController

---

### LmsQuests [TENANT] — Status: ~68%
**Controllers:** 4 | **Models:** 4

**Controllers:** LmsQuestController, QuestAllocationController, QuestQuestionController, QuestScopeController

---

### Recommendation [TENANT] — Status: ~65%
**Table Prefix:** rec_*
**Controllers:** 10 | **Models:** 11

**Controllers:** DynamicMaterialTypeController, DynamicPurposeController, MaterialBundleController, RecAssessmentTypeController, RecTriggerEventController, RecommendationController, RecommendationMaterialController, RecommendationModeController, RecommendationRuleController, StudentRecommendationController

---

### SyllabusBooks [TENANT] — Status: ~65%
**Table Prefix:** bok_*
**Controllers:** 4 | **Models:** 6

**Controllers:** AuthorController, BookController, BookTopicMappingController, SyllabusBooksController

---

### Library [TENANT] — Status: ~45% (NOT wired to tenant.php)
**Table Prefix:** lib_*
**Controllers:** 26 | **Models:** 35

**Controllers:**
LibAuthorController, LibBookConditionController, LibBookCopyController, LibBookMasterController, LibCategoryController, LibCirculationReportController, LibDigitalResourceController, LibDigitalResourceTagController, LibFineController, LibFineReportController, LibFineSlabConfigController, LibFineSlabDetailController, LibGenreController, LibInventoryAuditController, LibInventoryAuditDetailController, LibKeywordController, LibMemberController, LibMembershipTypeController, LibPublisherController, LibraryController, LibReportPrintController, LibReservationController, LibResourceTypeController, LibShelfLocationController, LibTransactionController, MasterDashboardController

---

### Dashboard [TENANT] — Status: 100%
**Controllers:** 1 (DashboardController) | **Models:** 0

### Scheduler [TENANT] — Status: 100%
**Controllers:** 1 (SchedulerController) | **Models:** 2

### StudentPortal [TENANT] — Status: ~25%
**Controllers:** 3 (NotificationController, StudentPortalComplaintController, StudentPortalController) | **Models:** 0
