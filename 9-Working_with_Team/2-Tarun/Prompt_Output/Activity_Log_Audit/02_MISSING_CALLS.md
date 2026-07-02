# 02 · Missing `activityLog()` Calls — Full List

> Every mutating method (standard + custom) that lacks an `activityLog()` call, with risk tier. Sorted by tier then module. Risk tiers: 🔴 Critical (money/grades/identity/roles) · 🟠 High (student records/portals/bulk) · 🟡 Medium (operational/master data).

> Caveat: some controller gaps are partially mitigated by logging in a downstream service (e.g. StudentPortal `PaymentService` writes `ptm_*` rows; exam attempts write domain `AttemptActivityLog` tables) — these still miss the central `sys_activity_logs` trail. See `05_NON_CONTROLLER_SURFACES.md`.


**Totals: 947 missing calls — 🔴 172 · 🟠 269 · 🟡 506**


### 🔴 Accounting

- `Modules/Accounting/app/Http/Controllers/AccountingController.php` · `store()`
- `Modules/Accounting/app/Http/Controllers/AccountingController.php` · `update()`
- `Modules/Accounting/app/Http/Controllers/AccountingController.php` · `destroy()`
- `Modules/Accounting/app/Http/Controllers/LedgerMappingController.php` · `toggleStatus()`
- `Modules/Accounting/app/Http/Controllers/TallyExportController.php` · `destroy()`
- `Modules/Accounting/app/Http/Controllers/TallyLedgerMappingController.php` · `toggleStatus()`

### 🔴 Admission

- `Modules/Admission/app/Http/Controllers/AllotmentController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/AllotmentController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/AllotmentController.php` · `destroy()`
- `Modules/Admission/app/Http/Controllers/AllotmentController.php` · `toggleStatus()`
- `Modules/Admission/app/Http/Controllers/ApplicationController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/ApplicationController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/ApplicationController.php` · `destroy()`
- `Modules/Admission/app/Http/Controllers/ApplicationController.php` · `restore()`
- `Modules/Admission/app/Http/Controllers/ApplicationController.php` · `forceDelete()`
- `Modules/Admission/app/Http/Controllers/ApplicationController.php` · `toggleStatus()`
- `Modules/Admission/app/Http/Controllers/EnquiryController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/EnquiryController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/EnquiryController.php` · `destroy()`
- `Modules/Admission/app/Http/Controllers/EnquiryController.php` · `toggleStatus()`
- `Modules/Admission/app/Http/Controllers/EnrollmentController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/EntranceTestController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/EntranceTestController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/EntranceTestController.php` · `toggleStatus()`
- `Modules/Admission/app/Http/Controllers/EntranceTestController.php` · `importCandidates()`
- `Modules/Admission/app/Http/Controllers/FollowUpController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/FollowUpController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/FollowUpController.php` · `destroy()`
- `Modules/Admission/app/Http/Controllers/MeritListController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/MeritListController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/MeritListController.php` · `toggleStatus()`
- `Modules/Admission/app/Http/Controllers/PromotionController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/PromotionController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/PromotionController.php` · `destroy()`
- `Modules/Admission/app/Http/Controllers/WithdrawalController.php` · `store()`
- `Modules/Admission/app/Http/Controllers/WithdrawalController.php` · `update()`
- `Modules/Admission/app/Http/Controllers/WithdrawalController.php` · `destroy()`
- `Modules/Admission/app/Http/Controllers/WithdrawalController.php` · `toggleStatus()`
- `Modules/Admission/app/Http/Controllers/WithdrawalController.php` · `processRefund()`

### 🔴 Billing

- `Modules/Billing/app/Http/Controllers/BillingCycleController.php` · `toggleStatus()`
- `Modules/Billing/app/Http/Controllers/BillingManagementController.php` · `store()`
- `Modules/Billing/app/Http/Controllers/BillingManagementController.php` · `update()`
- `Modules/Billing/app/Http/Controllers/BillingManagementController.php` · `destroy()`
- `Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php` · `store()`
- `Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php` · `update()`
- `Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php` · `destroy()`
- `Modules/Billing/app/Http/Controllers/InvoicingController.php` · `store()`
- `Modules/Billing/app/Http/Controllers/InvoicingController.php` · `update()`
- `Modules/Billing/app/Http/Controllers/InvoicingController.php` · `destroy()`
- `Modules/Billing/app/Http/Controllers/InvoicingPaymentController.php` · `update()`
- `Modules/Billing/app/Http/Controllers/InvoicingPaymentController.php` · `destroy()`
- `Modules/Billing/app/Http/Controllers/SubscriptionController.php` · `update()`
- `Modules/Billing/app/Http/Controllers/SubscriptionController.php` · `destroy()`

### 🔴 Certificate

- `Modules/Certificate/app/Http/Controllers/BulkGenerationController.php` · `generate()`
- `Modules/Certificate/app/Http/Controllers/CertificateIssuedController.php` · `restore()`
- `Modules/Certificate/app/Http/Controllers/CertificateIssuedController.php` · `forceDelete()`
- `Modules/Certificate/app/Http/Controllers/CertificateRequestController.php` · `store()`
- `Modules/Certificate/app/Http/Controllers/CertificateRequestController.php` · `restore()`
- `Modules/Certificate/app/Http/Controllers/CertificateRequestController.php` · `forceDelete()`
- `Modules/Certificate/app/Http/Controllers/CertificateRequestController.php` · `approve()`
- `Modules/Certificate/app/Http/Controllers/CertificateRequestController.php` · `reject()`
- `Modules/Certificate/app/Http/Controllers/CertificateTemplateController.php` · `store()`
- `Modules/Certificate/app/Http/Controllers/CertificateTemplateController.php` · `update()`
- `Modules/Certificate/app/Http/Controllers/CertificateTemplateController.php` · `destroy()`
- `Modules/Certificate/app/Http/Controllers/CertificateTemplateController.php` · `restore()`
- `Modules/Certificate/app/Http/Controllers/CertificateTemplateController.php` · `forceDelete()`
- `Modules/Certificate/app/Http/Controllers/CertificateTemplateController.php` · `toggleStatus()`
- `Modules/Certificate/app/Http/Controllers/CertificateTypeController.php` · `store()`
- `Modules/Certificate/app/Http/Controllers/CertificateTypeController.php` · `update()`
- `Modules/Certificate/app/Http/Controllers/CertificateTypeController.php` · `destroy()`
- `Modules/Certificate/app/Http/Controllers/CertificateTypeController.php` · `restore()`
- `Modules/Certificate/app/Http/Controllers/CertificateTypeController.php` · `forceDelete()`
- `Modules/Certificate/app/Http/Controllers/CertificateTypeController.php` · `toggleStatus()`
- `Modules/Certificate/app/Http/Controllers/IdCardConfigController.php` · `store()`
- `Modules/Certificate/app/Http/Controllers/IdCardConfigController.php` · `update()`
- `Modules/Certificate/app/Http/Controllers/IdCardConfigController.php` · `destroy()`
- `Modules/Certificate/app/Http/Controllers/IdCardConfigController.php` · `toggleStatus()`
- `Modules/Certificate/app/Http/Controllers/IdCardConfigController.php` · `generate()`
- `Modules/Certificate/app/Http/Controllers/StudentDocumentController.php` · `store()`
- `Modules/Certificate/app/Http/Controllers/StudentDocumentController.php` · `destroy()`
- `Modules/Certificate/app/Http/Controllers/StudentDocumentController.php` · `verify()`

### 🔴 Hpc

- `Modules/Hpc/app/Http/Controllers/HpcController.php` · `store()`
- `Modules/Hpc/app/Http/Controllers/HpcController.php` · `update()`
- `Modules/Hpc/app/Http/Controllers/HpcController.php` · `destroy()`

### 🔴 HrStaff

- `Modules/HrStaff/app/Http/Controllers/ComplianceController.php` · `update()`
- `Modules/HrStaff/app/Http/Controllers/HolidayController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/IdCardTemplateController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/LeaveBalanceAdjustmentController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/LeaveTypeController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/PayGradeController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/PtSlabController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/SalaryComponentController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/SalaryStructureController.php` · `toggleStatus()`
- `Modules/HrStaff/app/Http/Controllers/TdsLedgerController.php` · `toggleStatus()`

### 🔴 LmsExam

- `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php` · `bulkToggleStatus()`
- `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php` · `bulkDestroy()`
- `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php` · `bulkRestore()`
- `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php` · `bulkForceDelete()`
- `Modules/LmsExam/app/Http/Controllers/ExamScopeController.php` · `update()`
- `Modules/LmsExam/app/Http/Controllers/GrievanceReviewController.php` · `store()`
- `Modules/LmsExam/app/Http/Controllers/GrievanceReviewController.php` · `toggleStatus()`
- `Modules/LmsExam/app/Http/Controllers/LmsExamController.php` · `submitEvaluationGrade()`
- `Modules/LmsExam/app/Http/Controllers/LmsExamController.php` · `saveBulkGrades()`
- `Modules/LmsExam/app/Http/Controllers/LmsExamController.php` · `bulkUploadAnnotatedPdf()`
- `Modules/LmsExam/app/Http/Controllers/LmsExamController.php` · `bulkUploadMarks()`
- `Modules/LmsExam/app/Http/Controllers/LmsExamController.php` · `submitEvaluationGradeOffline()`
- `Modules/LmsExam/app/Http/Controllers/PaperSetQuestionController.php` · `bulkStore()`

### 🔴 LmsQuests

- `Modules/LmsQuests/app/Http/Controllers/QuestAllocationController.php` · `publishRecommendations()`
- `Modules/LmsQuests/app/Http/Controllers/QuestAllocationController.php` · `publishHiddenRecommendations()`
- `Modules/LmsQuests/app/Http/Controllers/QuestQuestionController.php` · `bulkStore()`
- `Modules/LmsQuests/app/Http/Controllers/QuestScopeController.php` · `store()`
- `Modules/LmsQuests/app/Http/Controllers/QuestScopeController.php` · `update()`

### 🔴 LmsQuiz

- `Modules/LmsQuiz/app/Http/Controllers/QuizAllocationController.php` · `publishRecommendations()`
- `Modules/LmsQuiz/app/Http/Controllers/QuizAllocationController.php` · `publishHiddenRecommendations()`
- `Modules/LmsQuiz/app/Http/Controllers/QuizQuestionController.php` · `bulkStore()`

### 🔴 Payment

- `Modules/Payment/app/Http/Controllers/RefundController.php` · `store()`
- `Modules/Payment/app/Http/Controllers/WebhookController.php` · `razorpay()`

### 🔴 Prime

- `Modules/Prime/app/Http/Controllers/ActivityLogController.php` · `store()`
- `Modules/Prime/app/Http/Controllers/ActivityLogController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/ActivityLogController.php` · `destroy()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `store()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `forceDelete()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `updateBulk()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `deleteBulk()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `removeMapping()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `restoreBulk()`
- `Modules/Prime/app/Http/Controllers/DropdownController.php` · `forceDeleteBulk()`
- `Modules/Prime/app/Http/Controllers/DropdownMgmtController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/DropdownMgmtController.php` · `deleteBulk()`
- `Modules/Prime/app/Http/Controllers/LanguageController.php` · `store()`
- `Modules/Prime/app/Http/Controllers/LanguageController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/NotificationController.php` · `destroy()`
- `Modules/Prime/app/Http/Controllers/RolePermissionController.php` · `restore()`
- `Modules/Prime/app/Http/Controllers/SalesPlanAndModuleMgmtController.php` · `store()`
- `Modules/Prime/app/Http/Controllers/SalesPlanAndModuleMgmtController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/SalesPlanAndModuleMgmtController.php` · `destroy()`
- `Modules/Prime/app/Http/Controllers/SessionBoardSetupController.php` · `store()`
- `Modules/Prime/app/Http/Controllers/SessionBoardSetupController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/SessionBoardSetupController.php` · `destroy()`
- `Modules/Prime/app/Http/Controllers/SettingController.php` · `store()`
- `Modules/Prime/app/Http/Controllers/SettingController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/SettingController.php` · `destroy()`
- `Modules/Prime/app/Http/Controllers/TenantController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/TenantController.php` · `destroy()`
- `Modules/Prime/app/Http/Controllers/TenantController.php` · `toggleStatus()`
- `Modules/Prime/app/Http/Controllers/TenantController.php` · `assignBoards()`
- `Modules/Prime/app/Http/Controllers/TenantGroupController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/UserRolePrmController.php` · `store()`
- `Modules/Prime/app/Http/Controllers/UserRolePrmController.php` · `update()`
- `Modules/Prime/app/Http/Controllers/UserRolePrmController.php` · `destroy()`

### 🔴 StudentFee

- `Modules/StudentFee/app/Http/Controllers/FeeGroupMasterController.php` · `toggleStatus()`
- `Modules/StudentFee/app/Http/Controllers/FeeInvoiceController.php` · `recordPayment()`
- `Modules/StudentFee/app/Http/Controllers/FeeInvoiceController.php` · `generateFeeInvoice()`
- `Modules/StudentFee/app/Http/Controllers/FeeStudentAssignmentController.php` · `generateStudentAssignment()`
- `Modules/StudentFee/app/Http/Controllers/StudentFeeController.php` · `store()`
- `Modules/StudentFee/app/Http/Controllers/StudentFeeController.php` · `update()`
- `Modules/StudentFee/app/Http/Controllers/StudentFeeController.php` · `destroy()`
- `Modules/StudentFee/app/Http/Controllers/StudentFeeManagementController.php` · `store()`
- `Modules/StudentFee/app/Http/Controllers/StudentFeeManagementController.php` · `update()`
- `Modules/StudentFee/app/Http/Controllers/StudentFeeManagementController.php` · `destroy()`

### 🔴 StudentProfile

- `Modules/StudentProfile/app/Http/Controllers/AttendanceController.php` · `storeBulkAttendance()`
- `Modules/StudentProfile/app/Http/Controllers/MedicalIncidentController.php` · `store()`
- `Modules/StudentProfile/app/Http/Controllers/StdLeaveController.php` · `update()`
- `Modules/StudentProfile/app/Http/Controllers/StudentController.php` · `toggleStatus()`
- `Modules/StudentProfile/app/Http/Controllers/StudentController.php` · `bulkClassAttendance()`
- `Modules/StudentProfile/app/Http/Controllers/StudentLeaveTypeController.php` · `store()`
- `Modules/StudentProfile/app/Http/Controllers/StudentLeaveTypeController.php` · `update()`
- `Modules/StudentProfile/app/Http/Controllers/StudentLeaveTypeController.php` · `destroy()`
- `Modules/StudentProfile/app/Http/Controllers/StudentLeaveTypeController.php` · `restore()`
- `Modules/StudentProfile/app/Http/Controllers/StudentLeaveTypeController.php` · `forceDelete()`
- `Modules/StudentProfile/app/Http/Controllers/StudentLeaveTypeController.php` · `toggleStatus()`

### 🟠 BehaviouralAssessment

- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `update()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `restore()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `forceDelete()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `bulkRate()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `submit()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentController.php` · `approve()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `update()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `restore()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `forceDelete()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `toggleStatus()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `lock()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaAssessmentPeriodController.php` · `unlock()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php` · `update()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php` · `restore()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php` · `forceDelete()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaCategoryController.php` · `toggleStatus()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaClassCategoryController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaClassCategoryController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaClassCategoryController.php` · `toggleStatus()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php` · `update()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php` · `restore()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php` · `forceDelete()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaConfigController.php` · `toggleStatus()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php` · `update()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php` · `restore()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php` · `forceDelete()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaIncidentController.php` · `removeIntervention()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php` · `update()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php` · `restore()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php` · `forceDelete()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaInterventionController.php` · `toggleStatus()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php` · `store()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php` · `update()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php` · `destroy()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php` · `restore()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php` · `forceDelete()`
- `Modules/BehaviouralAssessment/app/Http/Controllers/BaRatingScaleController.php` · `toggleStatus()`

### 🟠 Complaint

- `Modules/Complaint/app/Http/Controllers/ComplaintActionController.php` · `store()`
- `Modules/Complaint/app/Http/Controllers/ComplaintActionController.php` · `destroy()`
- `Modules/Complaint/app/Http/Controllers/ComplaintCategoryController.php` · `store()`
- `Modules/Complaint/app/Http/Controllers/ComplaintController.php` · `store()`
- `Modules/Complaint/app/Http/Controllers/ComplaintController.php` · `update()`
- `Modules/Complaint/app/Http/Controllers/ComplaintController.php` · `destroy()`
- `Modules/Complaint/app/Http/Controllers/ComplaintController.php` · `toggleStatus()`
- `Modules/Complaint/app/Http/Controllers/DepartmentSlaController.php` · `store()`
- `Modules/Complaint/app/Http/Controllers/DepartmentSlaController.php` · `update()`
- `Modules/Complaint/app/Http/Controllers/DepartmentSlaController.php` · `destroy()`
- `Modules/Complaint/app/Http/Controllers/DepartmentSlaController.php` · `restore()`
- `Modules/Complaint/app/Http/Controllers/DepartmentSlaController.php` · `forceDelete()`
- `Modules/Complaint/app/Http/Controllers/DepartmentSlaController.php` · `toggleStatus()`
- `Modules/Complaint/app/Http/Controllers/DocumentRequestController.php` · `update()`
- `Modules/Complaint/app/Http/Controllers/MedicalCheckController.php` · `store()`
- `Modules/Complaint/app/Http/Controllers/MedicalCheckController.php` · `update()`
- `Modules/Complaint/app/Http/Controllers/MedicalCheckController.php` · `destroy()`
- `Modules/Complaint/app/Http/Controllers/MedicalCheckController.php` · `restore()`
- `Modules/Complaint/app/Http/Controllers/MedicalCheckController.php` · `forceDelete()`
- `Modules/Complaint/app/Http/Controllers/Mobile/ComplaintMobileController.php` · `store()`
- `Modules/Complaint/app/Http/Controllers/Mobile/ComplaintMobileController.php` · `update()`

### 🟠 Feedback

- `Modules/Feedback/app/Http/Controllers/FbkCategoryController.php` · `store()`
- `Modules/Feedback/app/Http/Controllers/FbkCategoryController.php` · `update()`
- `Modules/Feedback/app/Http/Controllers/FbkCategoryController.php` · `destroy()`
- `Modules/Feedback/app/Http/Controllers/FbkCategoryController.php` · `restore()`
- `Modules/Feedback/app/Http/Controllers/FbkCategoryController.php` · `forceDelete()`
- `Modules/Feedback/app/Http/Controllers/FbkCategoryController.php` · `toggleStatus()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleController.php` · `store()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleController.php` · `update()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleController.php` · `destroy()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleController.php` · `restore()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleController.php` · `forceDelete()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleController.php` · `toggleStatus()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleFeedbackTypeController.php` · `store()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleFeedbackTypeController.php` · `update()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleFeedbackTypeController.php` · `destroy()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleFeedbackTypeController.php` · `restore()`
- `Modules/Feedback/app/Http/Controllers/FbkCycleFeedbackTypeController.php` · `forceDelete()`
- `Modules/Feedback/app/Http/Controllers/FbkMenuController.php` · `toggleSummaryPublish()`
- `Modules/Feedback/app/Http/Controllers/FbkRelationshipTypeController.php` · `store()`
- `Modules/Feedback/app/Http/Controllers/FbkRelationshipTypeController.php` · `update()`
- `Modules/Feedback/app/Http/Controllers/FbkRelationshipTypeController.php` · `destroy()`
- `Modules/Feedback/app/Http/Controllers/FbkRelationshipTypeController.php` · `restore()`
- `Modules/Feedback/app/Http/Controllers/FbkRelationshipTypeController.php` · `forceDelete()`
- `Modules/Feedback/app/Http/Controllers/FbkRelationshipTypeController.php` · `toggleStatus()`
- `Modules/Feedback/app/Http/Controllers/FbkTargetTypeController.php` · `store()`
- `Modules/Feedback/app/Http/Controllers/FbkTargetTypeController.php` · `update()`
- `Modules/Feedback/app/Http/Controllers/FbkTargetTypeController.php` · `destroy()`
- `Modules/Feedback/app/Http/Controllers/FbkTargetTypeController.php` · `restore()`
- `Modules/Feedback/app/Http/Controllers/FbkTargetTypeController.php` · `forceDelete()`
- `Modules/Feedback/app/Http/Controllers/FbkTargetTypeController.php` · `toggleStatus()`
- `Modules/Feedback/app/Http/Controllers/FbkTemplateController.php` · `store()`
- `Modules/Feedback/app/Http/Controllers/FbkTemplateController.php` · `update()`
- `Modules/Feedback/app/Http/Controllers/FbkTemplateController.php` · `destroy()`
- `Modules/Feedback/app/Http/Controllers/FbkTemplateController.php` · `restore()`
- `Modules/Feedback/app/Http/Controllers/FbkTemplateController.php` · `forceDelete()`
- `Modules/Feedback/app/Http/Controllers/FbkTemplateController.php` · `toggleStatus()`

### 🟠 Notification

- `Modules/Notification/app/Http/Controllers/ChannelMasterController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/ChannelMasterController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/NotificationTargetController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/NotificationTargetController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/NotificationTargetController.php` · `destroy()`
- `Modules/Notification/app/Http/Controllers/NotificationTargetController.php` · `restore()`
- `Modules/Notification/app/Http/Controllers/NotificationTargetController.php` · `forceDelete()`
- `Modules/Notification/app/Http/Controllers/NotificationTargetController.php` · `toggleStatus()`
- `Modules/Notification/app/Http/Controllers/NotificationThreadController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/NotificationThreadController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/NotificationThreadController.php` · `destroy()`
- `Modules/Notification/app/Http/Controllers/NotificationThreadController.php` · `toggleStatus()`
- `Modules/Notification/app/Http/Controllers/NotificationThreadMemberController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/NotificationThreadMemberController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/NotificationThreadMemberController.php` · `destroy()`
- `Modules/Notification/app/Http/Controllers/ProviderMasterController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/ProviderMasterController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/ProviderMasterController.php` · `destroy()`
- `Modules/Notification/app/Http/Controllers/ProviderMasterController.php` · `restore()`
- `Modules/Notification/app/Http/Controllers/ProviderMasterController.php` · `forceDelete()`
- `Modules/Notification/app/Http/Controllers/ProviderMasterController.php` · `toggleStatus()`
- `Modules/Notification/app/Http/Controllers/ScheduleAuditController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/ScheduleAuditController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/ScheduleAuditController.php` · `destroy()`
- `Modules/Notification/app/Http/Controllers/TargetGroupController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/TargetGroupController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/TargetGroupController.php` · `destroy()`
- `Modules/Notification/app/Http/Controllers/TargetGroupController.php` · `restore()`
- `Modules/Notification/app/Http/Controllers/TargetGroupController.php` · `forceDelete()`
- `Modules/Notification/app/Http/Controllers/TargetGroupController.php` · `toggleStatus()`
- `Modules/Notification/app/Http/Controllers/TemplateController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/TemplateController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/UserPreferenceController.php` · `store()`
- `Modules/Notification/app/Http/Controllers/UserPreferenceController.php` · `update()`
- `Modules/Notification/app/Http/Controllers/UserPreferenceController.php` · `destroy()`
- `Modules/Notification/app/Http/Controllers/UserPreferenceController.php` · `restore()`
- `Modules/Notification/app/Http/Controllers/UserPreferenceController.php` · `forceDelete()`
- `Modules/Notification/app/Http/Controllers/UserPreferenceController.php` · `toggleStatus()`

### 🟠 ParentPortal

- `Modules/ParentPortal/app/Http/Controllers/Api/ParentLeaveApiController.php` · `store()`
- `Modules/ParentPortal/app/Http/Controllers/Api/ParentPtmApiController.php` · `cancel()`
- `Modules/ParentPortal/app/Http/Controllers/ParentComplaintController.php` · `store()`
- `Modules/ParentPortal/app/Http/Controllers/ParentDocumentController.php` · `store()`
- `Modules/ParentPortal/app/Http/Controllers/ParentDocumentController.php` · `payCallback()`
- `Modules/ParentPortal/app/Http/Controllers/ParentLeaveController.php` · `store()`
- `Modules/ParentPortal/app/Http/Controllers/ParentPtmController.php` · `cancel()`

### 🟠 Ptm

- `Modules/Ptm/app/Http/Controllers/PtmBatchTemplateController.php` · `generateSlotTemplates()`

### 🟠 QuestionBank

- `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` · `store()`
- `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` · `update()`
- `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` · `restore()`
- `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` · `forceDelete()`
- `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` · `storeClone()`
- `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` · `reviewApprove()`
- `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php` · `reviewReject()`
- `Modules/QuestionBank/app/Http/Controllers/QuestionStatisticController.php` · `toggleStatus()`

### 🟠 Recommendation

- `Modules/Recommendation/app/Http/Controllers/RecommendationMaterialController.php` · `store()`
- `Modules/Recommendation/app/Http/Controllers/RecommendationMaterialController.php` · `update()`
- `Modules/Recommendation/app/Http/Controllers/RecommendationRuleController.php` · `update()`

### 🟠 SmartTimetable

- `Modules/SmartTimetable/app/Http/Controllers/Api/TimetableApiController.php` · `generate()`
- `Modules/SmartTimetable/app/Http/Controllers/ParallelGroupController.php` · `store()`
- `Modules/SmartTimetable/app/Http/Controllers/ParallelGroupController.php` · `update()`
- `Modules/SmartTimetable/app/Http/Controllers/ParallelGroupController.php` · `destroy()`
- `Modules/SmartTimetable/app/Http/Controllers/ParallelGroupController.php` · `removeActivity()`
- `Modules/SmartTimetable/app/Http/Controllers/RoomUnavailableController.php` · `store()`
- `Modules/SmartTimetable/app/Http/Controllers/RoomUnavailableController.php` · `update()`
- `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` · `store()`
- `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` · `update()`
- `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` · `destroy()`
- `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` · `removeCell()`
- `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` · `generateWithPrime()`
- `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` · `publishTimetable()`
- `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` · `unpublishTimetable()`
- `Modules/SmartTimetable/app/Http/Controllers/TeacherUnavailableController.php` · `store()`
- `Modules/SmartTimetable/app/Http/Controllers/TeacherUnavailableController.php` · `update()`
- `Modules/SmartTimetable/app/Http/Controllers/TimetableGenerationController.php` · `generateWithPrime()`
- `Modules/SmartTimetable/app/Http/Controllers/TimetableGenerationController.php` · `resetGenerationLock()`
- `Modules/SmartTimetable/app/Http/Controllers/TimetablePreviewController.php` · `removeCell()`
- `Modules/SmartTimetable/app/Http/Controllers/TimetablePublishController.php` · `publishTimetable()`
- `Modules/SmartTimetable/app/Http/Controllers/TimetablePublishController.php` · `unpublishTimetable()`

### 🟠 StudentPortal

- `Modules/StudentPortal/app/Http/Controllers/Mobile/MobileComplaintController.php` · `store()`
- `Modules/StudentPortal/app/Http/Controllers/Mobile/MobileHomeworkController.php` · `submit()`
- `Modules/StudentPortal/app/Http/Controllers/Mobile/MobileLeaveController.php` · `store()`
- `Modules/StudentPortal/app/Http/Controllers/Mobile/MobileQuizAttemptController.php` · `submitAssessment()`
- `Modules/StudentPortal/app/Http/Controllers/Mobile/MobileQuizAttemptController.php` · `hasSubmittedAttempt()`
- `Modules/StudentPortal/app/Http/Controllers/StudentExamAttemptController.php` · `submit()`
- `Modules/StudentPortal/app/Http/Controllers/StudentGrievanceController.php` · `store()`
- `Modules/StudentPortal/app/Http/Controllers/StudentHomeworkController.php` · `submit()`
- `Modules/StudentPortal/app/Http/Controllers/StudentLeaveController.php` · `store()`
- `Modules/StudentPortal/app/Http/Controllers/StudentLibraryController.php` · `cancelRequest()`
- `Modules/StudentPortal/app/Http/Controllers/StudentPortalComplaintController.php` · `store()`
- `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` · `store()`
- `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` · `update()`
- `Modules/StudentPortal/app/Http/Controllers/StudentPortalController.php` · `destroy()`
- `Modules/StudentPortal/app/Http/Controllers/StudentQuestAttemptController.php` · `hasSubmittedAttempt()`
- `Modules/StudentPortal/app/Http/Controllers/StudentQuestAttemptController.php` · `submit()`
- `Modules/StudentPortal/app/Http/Controllers/StudentQuizAttemptController.php` · `hasSubmittedAttempt()`
- `Modules/StudentPortal/app/Http/Controllers/StudentQuizAttemptController.php` · `submit()`

### 🟠 Syllabus

- `Modules/Syllabus/app/Http/Controllers/CompetencieController.php` · `store()`
- `Modules/Syllabus/app/Http/Controllers/CompetencieController.php` · `update()`
- `Modules/Syllabus/app/Http/Controllers/CompetencieController.php` · `destroy()`
- `Modules/Syllabus/app/Http/Controllers/LessonController.php` · `store()`
- `Modules/Syllabus/app/Http/Controllers/LessonController.php` · `update()`
- `Modules/Syllabus/app/Http/Controllers/SyllabusController.php` · `toggleLock()`
- `Modules/Syllabus/app/Http/Controllers/SyllabusScheduleController.php` · `toggleStatus()`
- `Modules/Syllabus/app/Http/Controllers/TopicCompetencyController.php` · `store()`
- `Modules/Syllabus/app/Http/Controllers/TopicController.php` · `store()`
- `Modules/Syllabus/app/Http/Controllers/TopicController.php` · `update()`
- `Modules/Syllabus/app/Http/Controllers/TopicController.php` · `destroy()`

### 🟠 SyllabusBooks

- `Modules/SyllabusBooks/app/Http/Controllers/AuthorController.php` · `store()`
- `Modules/SyllabusBooks/app/Http/Controllers/AuthorController.php` · `update()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookChapterController.php` · `destroy()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookController.php` · `store()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookController.php` · `update()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookController.php` · `attachBookFiles()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookFileController.php` · `store()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookFileController.php` · `update()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookFileController.php` · `destroy()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookTopicMappingController.php` · `store()`
- `Modules/SyllabusBooks/app/Http/Controllers/BookTopicMappingController.php` · `update()`
- `Modules/SyllabusBooks/app/Http/Controllers/NoteController.php` · `restore()`
- `Modules/SyllabusBooks/app/Http/Controllers/NoteController.php` · `forceDelete()`
- `Modules/SyllabusBooks/app/Http/Controllers/NoteController.php` · `toggleStatus()`
- `Modules/SyllabusBooks/app/Http/Controllers/NoteFileController.php` · `toggleStatus()`
- `Modules/SyllabusBooks/app/Http/Controllers/SyllabusBookConfigController.php` · `update()`

### 🟠 TimetableFoundation

- `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php` · `generateActivities()`
- `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php` · `assignTeacherToActivity()`
- `Modules/TimetableFoundation/app/Http/Controllers/ClassSubjectSubgroupController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/ClassSubjectSubgroupController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/ClassSubjectSubgroupController.php` · `destroy()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodConfigController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodConfigController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetPeriodController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetPeriodController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetPeriodController.php` · `destroy()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetPeriodController.php` · `restore()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetPeriodController.php` · `forceDelete()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodSetPeriodController.php` · `toggleStatus()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodTypeController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/PeriodTypeController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/RequirementConsolidationController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/RequirementConsolidationController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/RoomAvailabilityController.php` · `generateRoomAvailabilityRatio()`
- `Modules/TimetableFoundation/app/Http/Controllers/SchoolDayController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/SchoolDayController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/SchoolShiftController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/SlotRequirementController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/SlotRequirementController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/SlotRequirementController.php` · `generateSlotRequirement()`
- `Modules/TimetableFoundation/app/Http/Controllers/SubActivityDetailController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/SubActivityDetailController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/SubActivityDetailController.php` · `destroy()`
- `Modules/TimetableFoundation/app/Http/Controllers/TeacherAssignmentRoleController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/TeacherAssignmentRoleController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/TeacherAvailabilityController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/TeacherAvailabilityController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/TeacherAvailabilityController.php` · `generateTeacherAvailability()`
- `Modules/TimetableFoundation/app/Http/Controllers/TimetableFoundationController.php` · `generateClassGroups()`
- `Modules/TimetableFoundation/app/Http/Controllers/TimetableTypeController.php` · `store()`
- `Modules/TimetableFoundation/app/Http/Controllers/TimetableTypeController.php` · `update()`
- `Modules/TimetableFoundation/app/Http/Controllers/WorkingDayController.php` · `removeSlotAndCompact()`

### 🟡 CommonChat

- `Modules/CommonChat/app/Http/Controllers/ChatAjaxController.php` · `storeAttachment()`
- `Modules/CommonChat/app/Http/Controllers/ChatMessageController.php` · `store()`
- `Modules/CommonChat/app/Http/Controllers/ChatMessageController.php` · `destroy()`
- `Modules/CommonChat/app/Http/Controllers/ChatModerationController.php` · `destroy()`
- `Modules/CommonChat/app/Http/Controllers/ChatParticipantController.php` · `transferAdmin()`
- `Modules/CommonChat/app/Http/Controllers/ChatPersonalizationController.php` · `update()`
- `Modules/CommonChat/app/Http/Controllers/ChatSettingsController.php` · `update()`
- `Modules/CommonChat/app/Http/Controllers/Mobile/MobileChatParticipantController.php` · `transferAdmin()`
- `Modules/CommonChat/app/Http/Controllers/Mobile/MobileChatPersonalizationController.php` · `update()`

### 🟡 Documentation

- `Modules/Documentation/app/Http/Controllers/DocumentationController.php` · `store()`
- `Modules/Documentation/app/Http/Controllers/DocumentationController.php` · `update()`
- `Modules/Documentation/app/Http/Controllers/DocumentationController.php` · `destroy()`

### 🟡 FrontOffice

- `Modules/FrontOffice/app/Http/Controllers/AppointmentController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/AppointmentController.php` · `forceDelete()`
- `Modules/FrontOffice/app/Http/Controllers/AppointmentController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/CertificateRequestController.php` · `restore()`
- `Modules/FrontOffice/app/Http/Controllers/CertificateRequestController.php` · `forceDelete()`
- `Modules/FrontOffice/app/Http/Controllers/CertificateRequestController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/CircularController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/CircularController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/CircularController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/CircularController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/CommunicationController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/ComplaintController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/DispatchRegisterController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/DispatchRegisterController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/DispatchRegisterController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/DispatchRegisterController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/EarlyDepartureController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/EarlyDepartureController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/EmergencyContactController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/EmergencyContactController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/EmergencyContactController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/EmergencyContactController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/FeedbackController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/FeedbackController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/FeedbackController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/FeedbackController.php` · `publicSubmit()`
- `Modules/FrontOffice/app/Http/Controllers/GatePassController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/GatePassController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/KeyRegisterController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/KeyRegisterController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/LostFoundController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/LostFoundController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/LostFoundController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/LostFoundController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/NoticeBoardController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/NoticeBoardController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/NoticeBoardController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/NoticeBoardController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/PhoneDiaryController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/PhoneDiaryController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/PhoneDiaryController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/PhoneDiaryController.php` · `restore()`
- `Modules/FrontOffice/app/Http/Controllers/PhoneDiaryController.php` · `forceDelete()`
- `Modules/FrontOffice/app/Http/Controllers/PhoneDiaryController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/PostalRegisterController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/PostalRegisterController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/PostalRegisterController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/PostalRegisterController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/SchoolEventController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/SchoolEventController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/SchoolEventController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorController.php` · `toggleStatus()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorPurposeController.php` · `store()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorPurposeController.php` · `update()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorPurposeController.php` · `destroy()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorPurposeController.php` · `restore()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorPurposeController.php` · `forceDelete()`
- `Modules/FrontOffice/app/Http/Controllers/VisitorPurposeController.php` · `toggleStatus()`

### 🟡 GlobalMaster

- `Modules/GlobalMaster/app/Http/Controllers/ActivityLogController.php` · `store()`
- `Modules/GlobalMaster/app/Http/Controllers/ActivityLogController.php` · `update()`
- `Modules/GlobalMaster/app/Http/Controllers/ActivityLogController.php` · `destroy()`
- `Modules/GlobalMaster/app/Http/Controllers/DistrictController.php` · `toggleStatus()`
- `Modules/GlobalMaster/app/Http/Controllers/DropdownController.php` · `store()`
- `Modules/GlobalMaster/app/Http/Controllers/DropdownController.php` · `update()`
- `Modules/GlobalMaster/app/Http/Controllers/GeographySetupController.php` · `store()`
- `Modules/GlobalMaster/app/Http/Controllers/GeographySetupController.php` · `update()`
- `Modules/GlobalMaster/app/Http/Controllers/GeographySetupController.php` · `destroy()`
- `Modules/GlobalMaster/app/Http/Controllers/LanguageController.php` · `store()`
- `Modules/GlobalMaster/app/Http/Controllers/LanguageController.php` · `update()`

### 🟡 Hostel

- `Modules/Hostel/app/Http/Controllers/AllotmentController.php` · `bulkVacateForm()`
- `Modules/Hostel/app/Http/Controllers/AuditLogController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/AuditLogController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/AuditLogController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/AuditLogController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/BedTypeController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/BedTypeController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/BedTypeController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/BedTypeController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/BedTypeController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/BedTypeController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/EmergencyContactController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/EmergencyContactController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/EmergencyContactController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/EmergencyContactController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/EmergencyContactController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/EmergencyContactController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/FeeDemandController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/FeeDemandController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/FeeDemandController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/FeeDemandController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/FeeDemandController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/FeeDemandController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/HousekeepingController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/HousekeepingController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/HousekeepingController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/HousekeepingController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/HousekeepingController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/HousekeepingController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/HstAttendanceController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/HstAttendanceController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/HstComplaintController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/HstDynamicStatusMasterController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/HstDynamicStatusMasterController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/HstDynamicStatusMasterController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/HstDynamicStatusMasterController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/HstDynamicStatusMasterController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/HstDynamicStatusMasterController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/HstFeeController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/IncidentController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/IncidentController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/IncidentController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/IncidentTypeController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/IncidentTypeController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/IncidentTypeController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/IncidentTypeController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/IncidentTypeController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/IncidentTypeController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/IncidentWarningController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/IncidentWarningController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/IncidentWarningController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/IncidentWarningController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/IncidentWarningController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/IncidentWarningController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/LaundryController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/LaundryController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/LaundryController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/LaundryController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/LaundryController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/LaundryController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/LeavePassController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/LeavePassController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/MessBillController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/MessBillController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/MessBillController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/MessBillController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/MessBillController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/MessBillController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/MessOptOutController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/MessOptOutController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/MessOptOutController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/MessOptOutController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/MessOptOutController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/NotificationLogController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/NotificationLogController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/NotificationLogController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/RoomReservationController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/RoomReservationController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/RoomReservationController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/RoomReservationController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/RoomReservationController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/RoomTypeController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/RoomTypeController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/RoomTypeController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/RoomTypeController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/RoomTypeController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/RoomTypeController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/SickBayController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/SickBayController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/SickBayController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/SickBayController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/SickBayController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/SickBayController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/SickBayMedicationController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/SickBayMedicationController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/SickBayMedicationController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/SickBayMedicationController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/SickBayMedicationController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/SickBayMedicationController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/SickBayVitalController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/SickBayVitalController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/SickBayVitalController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/SickBayVitalController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/SickBayVitalController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/SickBayVitalController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/SpecialDietController.php` · `toggleStatus()`
- `Modules/Hostel/app/Http/Controllers/VisitorLogController.php` · `store()`
- `Modules/Hostel/app/Http/Controllers/VisitorLogController.php` · `update()`
- `Modules/Hostel/app/Http/Controllers/VisitorLogController.php` · `destroy()`
- `Modules/Hostel/app/Http/Controllers/VisitorLogController.php` · `restore()`
- `Modules/Hostel/app/Http/Controllers/VisitorLogController.php` · `forceDelete()`
- `Modules/Hostel/app/Http/Controllers/VisitorLogController.php` · `toggleStatus()`

### 🟡 Inventory

- `Modules/Inventory/app/Http/Controllers/AssetCategoryController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/AssetCategoryController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/AssetCategoryController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/AssetCategoryController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/AssetCategoryController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/AssetCategoryController.php` · `toggleStatus()`
- `Modules/Inventory/app/Http/Controllers/AssetController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/GodownController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/GodownController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/GodownController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/GodownController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/GodownController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/GodownController.php` · `toggleStatus()`
- `Modules/Inventory/app/Http/Controllers/GrnController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/GrnController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/GrnController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/GrnController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/GrnController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/GrnController.php` · `reject()`
- `Modules/Inventory/app/Http/Controllers/IssueRequestController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/IssueRequestController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/IssueRequestController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/IssueRequestController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/IssueRequestController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/IssueRequestController.php` · `approve()`
- `Modules/Inventory/app/Http/Controllers/IssueRequestController.php` · `reject()`
- `Modules/Inventory/app/Http/Controllers/ItemVendorController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/ItemVendorController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/ItemVendorController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/ItemVendorController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/ItemVendorController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/PurchaseOrderController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/PurchaseOrderController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/PurchaseOrderController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/PurchaseOrderController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/PurchaseOrderController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/PurchaseOrderController.php` · `approve()`
- `Modules/Inventory/app/Http/Controllers/PurchaseOrderController.php` · `cancel()`
- `Modules/Inventory/app/Http/Controllers/PurchaseRequisitionController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/PurchaseRequisitionController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/PurchaseRequisitionController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/PurchaseRequisitionController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/PurchaseRequisitionController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/PurchaseRequisitionController.php` · `reject()`
- `Modules/Inventory/app/Http/Controllers/QuotationController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/QuotationController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/QuotationController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/QuotationController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/QuotationController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/RateContractController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/RateContractController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/RateContractController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/RateContractController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/RateContractController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/StockAdjustmentController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/StockAdjustmentController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/StockAdjustmentController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/StockAdjustmentController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/StockAdjustmentController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/StockAdjustmentController.php` · `reject()`
- `Modules/Inventory/app/Http/Controllers/StockGroupController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/StockGroupController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/StockGroupController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/StockGroupController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/StockGroupController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/StockGroupController.php` · `toggleStatus()`
- `Modules/Inventory/app/Http/Controllers/StockIssueController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/StockItemController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/StockItemController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/StockItemController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/StockItemController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/StockItemController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/StockItemController.php` · `toggleStatus()`
- `Modules/Inventory/app/Http/Controllers/UomController.php` · `store()`
- `Modules/Inventory/app/Http/Controllers/UomController.php` · `update()`
- `Modules/Inventory/app/Http/Controllers/UomController.php` · `destroy()`
- `Modules/Inventory/app/Http/Controllers/UomController.php` · `restore()`
- `Modules/Inventory/app/Http/Controllers/UomController.php` · `forceDelete()`
- `Modules/Inventory/app/Http/Controllers/UomController.php` · `toggleStatus()`

### 🟡 Library

- `Modules/Library/app/Http/Controllers/LibAccountEntryConfigController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibAccountEntryConfigController.php` · `restore()`
- `Modules/Library/app/Http/Controllers/LibAccountEntryConfigController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/LibAccountEntryConfigController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibBookMasterController.php` · `quickCreatePublisher()`
- `Modules/Library/app/Http/Controllers/LibBookReviewController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/LibBookReviewController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibCurricularAlignmentController.php` · `restore()`
- `Modules/Library/app/Http/Controllers/LibCurricularAlignmentController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/LibDigitalAccessRequestController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibDigitalAccessRequestTypeController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibDigitalResourceTagController.php` · `store()`
- `Modules/Library/app/Http/Controllers/LibDigitalResourceTagController.php` · `destroy()`
- `Modules/Library/app/Http/Controllers/LibDigitalResourceTagController.php` · `bulkDestroy()`
- `Modules/Library/app/Http/Controllers/LibFineController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibFinePaymentController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibFineSlabConfigController.php` · `bulkStore()`
- `Modules/Library/app/Http/Controllers/LibFineSlabConfigController.php` · `bulkUpdate()`
- `Modules/Library/app/Http/Controllers/LibFineSlabConfigController.php` · `bulkDelete()`
- `Modules/Library/app/Http/Controllers/LibFineTypeController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditController.php` · `store()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditController.php` · `destroy()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditController.php` · `restore()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditDetailController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditDetailController.php` · `destroy()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditDetailController.php` · `restore()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditDetailController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/LibInventoryAuditDetailController.php` · `bulkStore()`
- `Modules/Library/app/Http/Controllers/LibLibrarySettingController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibMemberController.php` · `store()`
- `Modules/Library/app/Http/Controllers/LibMemberController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibMemberController.php` · `destroy()`
- `Modules/Library/app/Http/Controllers/LibMemberController.php` · `restore()`
- `Modules/Library/app/Http/Controllers/LibMemberController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/LibMemberController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibPhysicalBookRequestController.php` · `store()`
- `Modules/Library/app/Http/Controllers/LibPhysicalBookRequestController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibPhysicalBookRequestController.php` · `destroy()`
- `Modules/Library/app/Http/Controllers/LibPhysicalBookRequestController.php` · `restore()`
- `Modules/Library/app/Http/Controllers/LibPhysicalBookRequestController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/LibPhysicalBookRequestController.php` · `toggleStatus()`
- `Modules/Library/app/Http/Controllers/LibTransactionController.php` · `store()`
- `Modules/Library/app/Http/Controllers/LibTransactionController.php` · `update()`
- `Modules/Library/app/Http/Controllers/LibTransactionController.php` · `destroy()`
- `Modules/Library/app/Http/Controllers/LibTransactionController.php` · `restore()`
- `Modules/Library/app/Http/Controllers/LibTransactionController.php` · `forceDelete()`
- `Modules/Library/app/Http/Controllers/StaffLibraryController.php` · `cancelRequest()`

### 🟡 LmsHomework

- `Modules/LmsHomework/app/Http/Controllers/HomeworkSubmissionController.php` · `store()`
- `Modules/LmsHomework/app/Http/Controllers/HomeworkSubmissionController.php` · `syncSubmissionAttachments()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `store()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `update()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `syncHomeworkAttachments()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `assignmentsGrade()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `assignmentUpdateStatus()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `assignmentUpdateDueDate()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `assignmentUpdateAssignDate()`
- `Modules/LmsHomework/app/Http/Controllers/LmsHomeworkController.php` · `syncAssignments()`

### 🟡 Scheduler

- `Modules/Scheduler/app/Http/Controllers/SchedulerController.php` · `store()`
- `Modules/Scheduler/app/Http/Controllers/SchedulerController.php` · `update()`
- `Modules/Scheduler/app/Http/Controllers/SchedulerController.php` · `destroy()`

### 🟡 SchoolSetup

- `Modules/SchoolSetup/app/Http/Controllers/AnnualLeaveSessionController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/AnnualLeaveSessionController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/AnnualLeaveSessionController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/AnnualLeaveSessionController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/AnnualLeaveSessionController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/AnnualLeaveSessionController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/ClassGroupController.php` · `generateClassGroups()`
- `Modules/SchoolSetup/app/Http/Controllers/ClassSubjectGroupController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/ClassSubjectGroupController.php` · `generateClassSubjectGroups()`
- `Modules/SchoolSetup/app/Http/Controllers/ClassSubjectManagementController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/ClassSubjectManagementController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/ClassSubjectManagementController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeAttendanceController.php` · `approveCorrection()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeAttendanceController.php` · `rejectCorrection()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationController.php` · `cancel()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationDocController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationDocController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationDocController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationDocController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationDocController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationDocController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php` · `markAsRead()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApprovalController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveBalanceController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveBalanceController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveBalanceController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveBalanceController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveBalanceController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveBalanceController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeRoleHistoryController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeRoleHistoryController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeRoleHistoryController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeRoleHistoryController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeRoleHistoryController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeRoleHistoryController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeSeparationController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeSeparationController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeSeparationController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeSeparationController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeSeparationController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeSeparationController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftAssignmentController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftAssignmentController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftAssignmentController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftAssignmentController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftAssignmentController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftAssignmentController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/EmployeeShiftController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/EntityGroupController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/HolidayController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/HolidayController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/HolidayController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/HolidayController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/HolidayController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/HolidayController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalLevelApproverController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalLevelApproverController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalLevelApproverController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalLevelApproverController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalLevelApproverController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalLevelApproverController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyLevelController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyLevelController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyLevelController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyLevelController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyLevelController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/LeaveApprovalPolicyLevelController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/Mobile/AdminStaffLeaveController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/OrganizationAcademicSessionController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/OrganizationAcademicSessionController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/SchClassGroupSubjectOptionsController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/SchClassGroupSubjectOptionsController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/SchClassGroupSubjectOptionsController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/SchClassGroupSubjectOptionsController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/SchClassGroupSubjectOptionsController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/SchoolSetupController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/SchoolSetupController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/SchoolSetupController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffAttendanceTypeController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffAttendanceTypeController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffAttendanceTypeController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffAttendanceTypeController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffAttendanceTypeController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffAttendanceTypeController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveConfigController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveConfigController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveConfigController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveConfigController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveConfigController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveConfigController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveTypeController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveTypeController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveTypeController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveTypeController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveTypeController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/StaffLeaveTypeController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/StudentLeaveTypeController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/StudentLeaveTypeController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/StudentLeaveTypeController.php` · `destroy()`
- `Modules/SchoolSetup/app/Http/Controllers/StudentLeaveTypeController.php` · `restore()`
- `Modules/SchoolSetup/app/Http/Controllers/StudentLeaveTypeController.php` · `forceDelete()`
- `Modules/SchoolSetup/app/Http/Controllers/StudentLeaveTypeController.php` · `toggleStatus()`
- `Modules/SchoolSetup/app/Http/Controllers/UserRolePrmController.php` · `store()`
- `Modules/SchoolSetup/app/Http/Controllers/UserRolePrmController.php` · `update()`
- `Modules/SchoolSetup/app/Http/Controllers/UserRolePrmController.php` · `destroy()`

### 🟡 StandardTimetable

- `Modules/StandardTimetable/app/Http/Controllers/StandardTimetableController.php` · `removeCell()`

### 🟡 SystemConfig

- `Modules/SystemConfig/app/Http/Controllers/BackupController.php` · `store()`
- `Modules/SystemConfig/app/Http/Controllers/BackupController.php` · `destroy()`
- `Modules/SystemConfig/app/Http/Controllers/BackupScheduleController.php` · `store()`
- `Modules/SystemConfig/app/Http/Controllers/BackupScheduleController.php` · `update()`
- `Modules/SystemConfig/app/Http/Controllers/BackupScheduleController.php` · `destroy()`
- `Modules/SystemConfig/app/Http/Controllers/BackupScheduleController.php` · `toggleStatus()`
- `Modules/SystemConfig/app/Http/Controllers/MenuController.php` · `destroy()`
- `Modules/SystemConfig/app/Http/Controllers/MenuController.php` · `restore()`
- `Modules/SystemConfig/app/Http/Controllers/MenuController.php` · `toggleStatus()`
- `Modules/SystemConfig/app/Http/Controllers/SystemConfigController.php` · `store()`
- `Modules/SystemConfig/app/Http/Controllers/SystemConfigController.php` · `update()`
- `Modules/SystemConfig/app/Http/Controllers/SystemConfigController.php` · `destroy()`
- `Modules/SystemConfig/app/Http/Controllers/TenantDropdownNeedController.php` · `toggleStatus()`
- `Modules/SystemConfig/app/Http/Controllers/TenantDropdownNeedController.php` · `updateBulk()`
- `Modules/SystemConfig/app/Http/Controllers/TenantDropdownNeedController.php` · `deleteBulk()`
- `Modules/SystemConfig/app/Http/Controllers/TenantDropdownNeedController.php` · `removeMapping()`

### 🟡 Transport

- `Modules/Transport/app/Http/Controllers/DriverAttendanceController.php` · `store()`
- `Modules/Transport/app/Http/Controllers/DriverAttendanceController.php` · `update()`
- `Modules/Transport/app/Http/Controllers/DriverHelperController.php` · `toggleStatus()`
- `Modules/Transport/app/Http/Controllers/PickupPointRouteController.php` · `store()`
- `Modules/Transport/app/Http/Controllers/PickupPointRouteController.php` · `update()`
- `Modules/Transport/app/Http/Controllers/PickupPointRouteController.php` · `destroy()`
- `Modules/Transport/app/Http/Controllers/PickupPointRouteController.php` · `restore()`
- `Modules/Transport/app/Http/Controllers/PickupPointRouteController.php` · `forceDelete()`
- `Modules/Transport/app/Http/Controllers/PickupPointRouteController.php` · `toggleStatus()`
- `Modules/Transport/app/Http/Controllers/TptStudentFineDetailController.php` · `store()`
- `Modules/Transport/app/Http/Controllers/TptVehicleMaintenanceController.php` · `update()`
- `Modules/Transport/app/Http/Controllers/TripController.php` · `store()`
- `Modules/Transport/app/Http/Controllers/TripController.php` · `bulkUpdateTime()`
- `Modules/Transport/app/Http/Controllers/TripController.php` · `bulkApprove()`

### 🟡 Vendor

- `Modules/Vendor/app/Http/Controllers/VendorAgreementController.php` · `destroy()`
- `Modules/Vendor/app/Http/Controllers/VendorAgreementController.php` · `restore()`
- `Modules/Vendor/app/Http/Controllers/VendorAgreementController.php` · `forceDelete()`
- `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php` · `store()`
- `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php` · `update()`
- `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php` · `destroy()`
- `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php` · `generateInvoice()`
- `Modules/Vendor/app/Http/Controllers/VendorPaymentController.php` · `update()`
- `Modules/Vendor/app/Http/Controllers/VendorPaymentController.php` · `destroy()`