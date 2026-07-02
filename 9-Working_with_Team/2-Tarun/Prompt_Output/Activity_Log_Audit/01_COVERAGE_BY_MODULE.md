# 01 · Activity-Log Coverage by Module

> Deterministic scan of all controllers under `Modules/*/app/Http/Controllers`. Each mutating method's body was brace-matched and checked for an `activityLog(` call. ✅ present · ❌ missing · `–` method absent · `stub` empty `{}` scaffold (not counted as a gap). `Other` lists custom mutating methods (name:✅/❌).

> **Methodology note:** presence is detected by text analysis of each method body; a ✅ means a call exists, not that it is semantically perfect (see `03_CORRECTNESS_FINDINGS.md`). Custom-method detection uses verb heuristics and may include a few false positives — verify before acting on any single row.


## SchoolSetup

*Controllers: 60 · Fully compliant: 22 · Partial: 5 · Zero-coverage: 24 · No mutating methods: 9 · Missing calls: 131*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AnnualLeaveSessionController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| BuildingController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ClassGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | generateClassGroups:❌ |
| ClassSubjectGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | generateClassSubjectGroups:❌ |
| ClassSubjectManagementController | ❌ | ❌ | ❌ | – | – | – | – | – |
| DepartmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DesignationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| EmployeeAttendanceController | – | – | – | – | – | – | – | approveCorrection:❌, rejectCorrection:❌ |
| EmployeeLeaveApplicationController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | cancel:❌ |
| EmployeeLeaveApplicationDocController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| EmployeeLeaveApplicationRemarkController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | markAsRead:❌ |
| EmployeeLeaveApprovalController | – | ❌ | – | – | – | – | – | – |
| EmployeeLeaveBalanceController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| EmployeeProfileController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ❌ | – |
| EmployeeRoleHistoryController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| EmployeeSeparationController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| EmployeeShiftAssignmentController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| EmployeeShiftController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| EntityGroupController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| EntityGroupMemberController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| HolidayController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| InfrasetupController | stub | stub | stub | – | – | – | – | – |
| LeaveApprovalLevelApproverController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| LeaveApprovalPolicyController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| LeaveApprovalPolicyLevelController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| LeaveConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| AdminStaffLeaveController | ❌ | – | – | – | – | – | – | – |
| OrganizationAcademicSessionController | ❌ | ❌ | ✅ | – | – | – | ✅ | – |
| OrganizationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| OrganizationGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RolePermissionController | ✅ | ✅ | ✅ | – | – | – | – | – |
| RoomController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RoomTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SchClassGroupSubjectOptionsController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| SchoolClassController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SchoolSetupController | ❌ | ❌ | ❌ | – | – | – | – | – |
| SectionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| StaffAttendanceTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| StaffLeaveConfigController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| StaffLeaveTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| StudentLeaveTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| StudyFormatController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubjectClassMappingController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubjectController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubjectGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubjectGroupSubjectController | – | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubjectStudyFormatController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubjectTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SystemConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TeacherController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| UserController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| UserRolePrmController | ❌ | ❌ | ❌ | – | – | – | – | – |

## Hostel

*Controllers: 53 · Fully compliant: 12 · Partial: 9 · Zero-coverage: 16 · No mutating methods: 16 · Missing calls: 112*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AllotmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | bulkVacateForm:❌ |
| AuditLogController | ❌ | ❌ | ❌ | – | – | – | ❌ | – |
| BedController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| BedMaintenanceController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| BedTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| EmergencyContactController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| FeeDemandController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| FloorController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| HostelController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| HousekeepingController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| HstAttendanceController | ✅ | ❌ | ❌ | – | ✅ | ✅ | – | bulkMark:✅ |
| HstComplaintController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| HstDynamicStatusMasterController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| HstFeeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| IncidentController | ✅ | ✅ | ✅ | – | ❌ | ❌ | ❌ | – |
| IncidentTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| IncidentWarningController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| LaundryController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| LeavePassController | ✅ | ✅ | ✅ | – | ❌ | ❌ | ✅ | – |
| MessAttendanceController | ✅ | – | – | – | – | – | – | – |
| MessBillController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| MessMenuController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | togglePublished:✅ |
| MessOptOutController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ✅ | – |
| MovementLogController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| NotificationLogController | – | – | ❌ | – | ❌ | ❌ | – | – |
| RoomChangeRequestController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | approve:✅, reject:✅ |
| RoomController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RoomInventoryController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RoomReservationController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ✅ | – |
| RoomTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| SickBayController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| SickBayMedicationController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| SickBayVitalController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| SpecialDietController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| VisitorLogController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| WardenAssignmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| WardenDutyRosterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## Inventory

*Controllers: 22 · Fully compliant: 0 · Partial: 0 · Zero-coverage: 15 · No mutating methods: 7 · Missing calls: 79*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AssetCategoryController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| AssetController | – | ❌ | – | – | – | – | – | – |
| GodownController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| GrnController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | reject:❌ |
| InventoryController | stub | stub | stub | – | – | – | – | – |
| IssueRequestController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | approve:❌, reject:❌ |
| ItemVendorController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| PurchaseOrderController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | approve:❌, cancel:❌ |
| PurchaseRequisitionController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | reject:❌ |
| QuotationController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| RateContractController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| StockAdjustmentController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | reject:❌ |
| StockGroupController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| StockIssueController | ❌ | – | – | – | – | – | – | – |
| StockItemController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| UomController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |

## FrontOffice

*Controllers: 21 · Fully compliant: 0 · Partial: 15 · Zero-coverage: 3 · No mutating methods: 3 · Missing calls: 59*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AppointmentController | ✅ | ❌ | ✅ | – | ✅ | ❌ | ❌ | cancel:✅ |
| CertificateRequestController | ✅ | ✅ | ✅ | – | ❌ | ❌ | ❌ | approve:✅, reject:✅ |
| CircularController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| CommunicationController | – | – | – | – | – | – | ❌ | – |
| ComplaintController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| DispatchRegisterController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| EarlyDepartureController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| EmergencyContactController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| FeedbackController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ❌ | publicSubmit:❌ |
| FrontOfficeController | stub | stub | stub | – | – | – | – | – |
| GatePassController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| KeyRegisterController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| LostFoundController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| NoticeBoardController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| PhoneDiaryController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| PostalRegisterController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| SchoolEventController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ❌ | – |
| VisitorController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| VisitorPurposeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |

## BehaviouralAssessment

*Controllers: 12 · Fully compliant: 0 · Partial: 0 · Zero-coverage: 8 · No mutating methods: 4 · Missing calls: 49*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| BaAssessmentController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | bulkRate:❌, submit:❌, approve:❌ |
| BaAssessmentPeriodController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | lock:❌, unlock:❌ |
| BaCategoryController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| BaClassCategoryController | ❌ | – | ❌ | – | – | – | ❌ | – |
| BaConfigController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| BaIncidentController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | removeIntervention:❌ |
| BaInterventionController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| BaRatingScaleController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| BehaviouralAssessmentController | stub | stub | stub | – | – | – | – | – |

## Library

*Controllers: 42 · Fully compliant: 16 · Partial: 10 · Zero-coverage: 8 · No mutating methods: 8 · Missing calls: 49*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| LibAccountEntryConfigController | ✅ | ❌ | ✅ | – | ❌ | ❌ | ❌ | – |
| LibAuthorController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibBookConditionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibBookCopyController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibBookMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | quickCreatePublisher:❌ |
| LibBookPurchaseController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| LibBookReviewController | ✅ | ✅ | ✅ | – | ✅ | ❌ | ❌ | approve:✅, reject:✅ |
| LibCategoryController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibCurricularAlignmentController | ✅ | ✅ | ✅ | – | ❌ | ❌ | – | – |
| LibDigitalAccessRequestController | ✅ | ❌ | ✅ | – | ✅ | ✅ | ✅ | approve:✅, reject:✅ |
| LibDigitalAccessRequestTypeController | – | – | – | – | – | – | ❌ | – |
| LibDigitalResourceAccessRestrictionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibDigitalResourceController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibDigitalResourceTagController | ❌ | – | ❌ | – | – | – | – | bulkDestroy:❌ |
| LibFineController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | payment:✅, razorpayCallback:✅ |
| LibFinePaymentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| LibFineSlabConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | bulkStore:❌, bulkUpdate:❌, bulkDelete:❌ |
| LibFineSlabDetailController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| LibFineTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| LibGenreController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibInventoryAuditController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| LibInventoryAuditDetailController | – | ❌ | ❌ | – | ❌ | ❌ | – | bulkStore:❌ |
| LibKeywordController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibLibrarySettingController | – | ❌ | – | – | – | – | – | – |
| LibLibraryStatusMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibLocationMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibMemberController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| LibMembershipTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibPhysicalBookRequestController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| LibPublisherController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibResourceTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibShelfLocationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LibTransactionController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| LibraryController | stub | stub | stub | – | – | – | – | – |
| StaffLibraryController | – | – | – | – | – | – | – | cancelRequest:❌, submitReview:✅ |

## TimetableFoundation

*Controllers: 26 · Fully compliant: 8 · Partial: 13 · Zero-coverage: 4 · No mutating methods: 1 · Missing calls: 40*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AcademicTermController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ActivityController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | generateActivities:❌, assignTeacherToActivity:❌ |
| ClassSubjectSubgroupController | ❌ | ❌ | ❌ | – | – | – | – | – |
| ClassTimetableTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ClassWorkingDayController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DayTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PeriodConfigController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| PeriodSetController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| PeriodSetPeriodController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| PeriodTypeController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| RequirementConsolidationController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| RoomAvailabilityController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | generateRoomAvailabilityRatio:❌ |
| SchoolDayController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| SchoolShiftController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SchoolTimingProfileController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SlotRequirementController | ❌ | ❌ | ✅ | – | – | – | ✅ | generateSlotRequirement:❌ |
| SubActivityDetailController | ❌ | ❌ | ❌ | – | – | – | – | – |
| TeacherAssignmentRoleController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| TeacherAvailabilityController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | generateTeacherAvailability:❌ |
| TimetableController | ✅ | ✅ | ✅ | – | – | – | – | – |
| TimetableFoundationController | – | – | – | – | – | – | – | generateClassGroups:❌ |
| TimetableTypeController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| TimingProfileController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| WorkingDayController | ✅ | ✅ | ✅ | – | – | – | – | removeSlotAndCompact:❌ |

## Notification

*Controllers: 12 · Fully compliant: 3 · Partial: 2 · Zero-coverage: 7 · No mutating methods: 0 · Missing calls: 38*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| ChannelMasterController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| DeliveryQueueController | ✅ | ✅ | ✅ | – | – | – | – | – |
| NotificationManageController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| NotificationTargetController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| NotificationThreadController | ❌ | ❌ | ❌ | – | – | – | ❌ | – |
| NotificationThreadMemberController | ❌ | ❌ | ❌ | – | – | – | – | – |
| ProviderMasterController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| ResolvedRecipientController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | markAsProcessed:✅ |
| ScheduleAuditController | ❌ | ❌ | ❌ | – | – | – | – | – |
| TargetGroupController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| TemplateController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | submitForApproval:✅, approve:✅, reject:✅ |
| UserPreferenceController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |

## Feedback

*Controllers: 10 · Fully compliant: 1 · Partial: 0 · Zero-coverage: 7 · No mutating methods: 2 · Missing calls: 36*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| ConsentFormController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FbkCategoryController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| FbkCycleController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| FbkCycleFeedbackTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| FbkMenuController | – | – | – | – | – | – | – | toggleSummaryPublish:❌ |
| FbkRelationshipTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| FbkTargetTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| FbkTemplateController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |

## Prime

*Controllers: 22 · Fully compliant: 6 · Partial: 6 · Zero-coverage: 6 · No mutating methods: 4 · Missing calls: 34*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AcademicSessionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ActivityLogController | ❌ | ❌ | ❌ | – | – | – | – | – |
| BoardController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DropdownController | ❌ | ❌ | ✅ | – | ✅ | ❌ | ✅ | updateBulk:❌, deleteBulk:❌, removeMapping:❌, restoreBulk:❌, forceDeleteBulk:❌ |
| DropdownMgmtController | ✅ | ❌ | stub | – | – | – | – | deleteBulk:❌ |
| DropdownNeedController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LanguageController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| MenuController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| NotificationController | – | – | ❌ | – | – | – | – | – |
| RolePermissionController | ✅ | ✅ | ✅ | – | ❌ | ✅ | – | – |
| SalesPlanAndModuleMgmtController | ❌ | ❌ | ❌ | – | – | – | – | – |
| SessionBoardSetupController | ❌ | ❌ | ❌ | – | – | – | – | – |
| SettingController | ❌ | ❌ | ❌ | – | – | – | – | – |
| TenantController | ✅ | ❌ | ❌ | – | – | – | ❌ | assignBoards:❌ |
| TenantDomainController | ✅ | ✅ | ✅ | – | – | – | ✅ | – |
| TenantGroupController | ✅ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| UserController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| UserRolePrmController | ❌ | ❌ | ❌ | – | – | – | – | – |

## Admission

*Controllers: 18 · Fully compliant: 4 · Partial: 6 · Zero-coverage: 3 · No mutating methods: 5 · Missing calls: 33*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AdmissionController | stub | stub | stub | – | – | – | – | – |
| AdmissionCycleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| AllotmentController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| ApplicationController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| DocumentChecklistController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| EnquiryController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| EnrollmentController | ❌ | – | – | – | – | – | – | – |
| EntranceTestController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ❌ | importCandidates:❌ |
| FollowUpController | ❌ | ❌ | ❌ | – | – | – | – | – |
| MeritListController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ❌ | – |
| PromotionController | ❌ | ❌ | ❌ | – | ✅ | ✅ | – | – |
| QuotaConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SeatCapacityController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| WithdrawalController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | processRefund:❌ |

## Certificate

*Controllers: 10 · Fully compliant: 0 · Partial: 0 · Zero-coverage: 7 · No mutating methods: 3 · Missing calls: 28*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| BulkGenerationController | – | – | – | – | – | – | – | generate:❌ |
| CertificateController | stub | stub | stub | – | – | – | – | – |
| CertificateIssuedController | – | – | – | – | ❌ | ❌ | – | – |
| CertificateRequestController | ❌ | – | – | – | ❌ | ❌ | – | approve:❌, reject:❌ |
| CertificateTemplateController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| CertificateTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| IdCardConfigController | ❌ | ❌ | ❌ | – | – | – | ❌ | generate:❌ |
| StudentDocumentController | ❌ | – | ❌ | – | – | – | – | verify:❌ |

## Complaint

*Controllers: 10 · Fully compliant: 0 · Partial: 2 · Zero-coverage: 5 · No mutating methods: 3 · Missing calls: 21*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AiInsightController | stub | stub | stub | – | – | – | – | – |
| ComplaintActionController | ❌ | stub | ❌ | – | – | – | – | – |
| ComplaintCategoryController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ComplaintController | ❌ | ❌ | ❌ | – | ✅ | ✅ | ❌ | – |
| ComplaintDashboardController | stub | stub | stub | – | – | – | – | – |
| DepartmentSlaController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| DocumentRequestController | – | ❌ | – | – | – | – | – | – |
| MedicalCheckController | ❌ | ❌ | ❌ | – | ❌ | ❌ | – | – |
| ComplaintMobileController | ❌ | ❌ | – | – | – | – | – | – |

## SmartTimetable

*Controllers: 18 · Fully compliant: 4 · Partial: 2 · Zero-coverage: 6 · No mutating methods: 6 · Missing calls: 21*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| TimetableApiController | – | – | – | – | – | – | – | generate:❌ |
| ConstraintCategoryScopeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ConstraintController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ConstraintTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ParallelGroupController | ❌ | ❌ | ❌ | – | – | – | – | removeActivity:❌ |
| RoomUnavailableController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| SmartTimetableController | ❌ | ❌ | ❌ | – | – | – | – | removeCell:❌, generateWithPrime:❌, publishTimetable:❌, unpublishTimetable:❌ |
| TeacherUnavailableController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| TimetableGenerationController | – | – | – | – | – | – | – | generateWithPrime:❌, resetGenerationLock:❌ |
| TimetablePreviewController | – | – | – | – | – | – | – | removeCell:❌ |
| TimetablePublishController | – | – | – | – | – | – | – | publishTimetable:❌, unpublishTimetable:❌ |
| TtGenerationStrategyController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## StudentPortal

*Controllers: 37 · Fully compliant: 0 · Partial: 1 · Zero-coverage: 12 · No mutating methods: 24 · Missing calls: 18*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| MobileComplaintController | ❌ | – | – | – | – | – | – | – |
| MobileHomeworkController | – | – | – | – | – | – | – | submit:❌ |
| MobileLeaveController | ❌ | – | – | – | – | – | – | – |
| MobileQuizAttemptController | – | – | – | – | – | – | – | submitAssessment:❌, hasSubmittedAttempt:❌ |
| StudentExamAttemptController | – | – | – | – | – | – | – | submit:❌ |
| StudentGrievanceController | ❌ | – | – | – | – | – | – | – |
| StudentHomeworkController | – | – | – | – | – | – | – | submit:❌ |
| StudentLeaveController | ❌ | – | – | – | – | – | – | – |
| StudentLibraryController | – | – | – | – | – | – | – | cancelRequest:❌, submitReview:✅ |
| StudentPortalComplaintController | ❌ | stub | stub | – | – | – | – | – |
| StudentPortalController | ❌ | ❌ | ❌ | – | – | – | – | – |
| StudentQuestAttemptController | – | – | – | – | – | – | – | hasSubmittedAttempt:❌, submit:❌ |
| StudentQuizAttemptController | – | – | – | – | – | – | – | hasSubmittedAttempt:❌, submit:❌ |

## SyllabusBooks

*Controllers: 11 · Fully compliant: 1 · Partial: 5 · Zero-coverage: 3 · No mutating methods: 2 · Missing calls: 16*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AuthorController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| BookChapterController | – | – | ❌ | – | – | – | – | – |
| BookController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | attachBookFiles:❌ |
| BookFileController | ❌ | ❌ | ❌ | – | – | – | – | – |
| BookTopicMappingController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| NoteController | ✅ | ✅ | ✅ | – | ❌ | ❌ | ❌ | – |
| NoteFileController | ✅ | – | ✅ | – | – | – | ❌ | – |
| NoteRatingController | ✅ | ✅ | ✅ | – | – | – | – | – |
| SyllabusBookConfigController | – | ❌ | – | – | – | – | – | – |
| SyllabusBooksController | stub | stub | stub | – | – | – | – | – |

## SystemConfig

*Controllers: 11 · Fully compliant: 2 · Partial: 2 · Zero-coverage: 3 · No mutating methods: 4 · Missing calls: 16*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| BackupController | ❌ | – | ❌ | – | – | – | – | – |
| BackupScheduleController | ❌ | ❌ | ❌ | – | – | – | ❌ | – |
| MenuController | ✅ | ✅ | ❌ | – | ❌ | ✅ | ❌ | – |
| SettingController | – | ✅ | – | – | – | – | – | – |
| SystemConfigController | ❌ | ❌ | ❌ | – | – | – | – | – |
| TenantDropdownController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TenantDropdownNeedController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | updateBulk:❌, deleteBulk:❌, removeMapping:❌ |

## Billing

*Controllers: 7 · Fully compliant: 1 · Partial: 4 · Zero-coverage: 2 · No mutating methods: 0 · Missing calls: 14*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| BillingCycleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| BillingManagementController | ❌ | ❌ | ❌ | – | – | – | ✅ | generateInvoiceForOrganization:✅ |
| EmailScheduleController | – | – | ✅ | – | – | – | – | – |
| InvoicingAuditLogController | ❌ | ❌ | ❌ | – | – | – | – | – |
| InvoicingController | ❌ | ❌ | ❌ | – | – | – | – | – |
| InvoicingPaymentController | ✅ | ❌ | ❌ | – | – | – | – | – |
| SubscriptionController | ✅ | ❌ | ❌ | – | – | – | – | – |

## Transport

*Controllers: 31 · Fully compliant: 14 · Partial: 5 · Zero-coverage: 1 · No mutating methods: 11 · Missing calls: 14*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AttendanceDeviceController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DriverAttendanceController | ❌ | ❌ | ✅ | – | ✅ | ✅ | – | – |
| DriverHelperController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| DriverRouteVehicleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FeeCollectionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| FeeMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FineMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| PickupPointController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PickupPointRouteController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| RouteController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RouteSchedulerController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ShiftController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| StaffMgmtController | stub | stub | stub | – | – | – | – | – |
| StudentAllocationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| StudentRouteFeesController | stub | stub | stub | – | – | – | – | – |
| TptDailyVehicleInspectionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| TptStudentFineDetailController | ❌ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| TptVehicleFuelController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| TptVehicleMaintenanceController | – | ❌ | ✅ | – | ✅ | ✅ | – | – |
| TptVehicleServiceRequestController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| TripController | ❌ | ✅ | ✅ | – | ✅ | ✅ | – | bulkUpdateTime:❌, bulkApprove:❌ |
| TripMgmtController | stub | stub | stub | – | – | – | – | – |
| VehicleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## LmsExam

*Controllers: 13 · Fully compliant: 7 · Partial: 4 · Zero-coverage: 1 · No mutating methods: 1 · Missing calls: 13*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| ExamAllocationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ExamBlueprintController | ✅ | ✅ | ✅ | – | – | – | ✅ | bulkToggleStatus:❌, bulkDestroy:❌, bulkRestore:❌, bulkForceDelete:❌ |
| ExamPaperController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ExamPaperSetController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ExamScopeController | ✅ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| ExamStatusEventController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ExamStudentGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ExamStudentGroupMemberController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| ExamTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| GrievanceReviewController | ❌ | – | – | – | – | – | ❌ | – |
| LmsExamController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | submitEvaluationGrade:❌, saveBulkGrades:❌, bulkUploadAnnotatedPdf:❌, bulkUploadMarks:❌, submitEvaluationGradeOffline:❌ |
| PaperSetQuestionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | bulkStore:❌, bulkDestroy:✅ |

## GlobalMaster

*Controllers: 15 · Fully compliant: 6 · Partial: 3 · Zero-coverage: 2 · No mutating methods: 4 · Missing calls: 11*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AcademicSessionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ActivityLogController | ❌ | ❌ | ❌ | – | – | – | – | – |
| CityController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| CountryController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DistrictController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| DropdownController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| GeographySetupController | ❌ | ❌ | ❌ | – | – | – | – | – |
| GlobalMasterController | stub | stub | stub | – | – | – | – | – |
| LanguageController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| ModuleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| OrganizationController | stub | stub | stub | – | – | – | – | – |
| PlanController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SessionBoardSetupController | stub | stub | stub | – | – | – | – | – |
| StateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## StudentProfile

*Controllers: 9 · Fully compliant: 0 · Partial: 2 · Zero-coverage: 3 · No mutating methods: 4 · Missing calls: 11*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AttendanceController | – | – | – | – | – | – | – | storeBulkAttendance:❌ |
| MedicalIncidentController | ❌ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| StdLeaveController | – | ❌ | – | – | – | – | – | – |
| StudentController | stub | stub | ✅ | – | ✅ | ✅ | ❌ | bulkClassAttendance:❌ |
| StudentLeaveTypeController | ❌ | ❌ | ❌ | – | ❌ | ❌ | ❌ | – |
| StudentProfileController | stub | stub | stub | – | – | – | – | – |
| StudentReportController | stub | stub | stub | – | – | – | – | – |

## Syllabus

*Controllers: 15 · Fully compliant: 9 · Partial: 3 · Zero-coverage: 3 · No mutating methods: 0 · Missing calls: 11*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| BloomTaxonomyController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| CognitiveSkillController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| CompetencieController | ❌ | ❌ | ❌ | – | – | – | – | – |
| CompetencyTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ComplexityLevelController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| GradeDivisionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | toggleLock:✅ |
| LessonController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| PerformanceCategoryController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| QuestionTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| QuestionTypeSpecificityController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SyllabusController | – | – | – | – | – | – | – | toggleLock:❌ |
| SyllabusScheduleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| TopicCompetencyController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TopicController | ❌ | ❌ | ❌ | – | – | – | – | – |
| TopicLevelTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## HrStaff

*Controllers: 26 · Fully compliant: 6 · Partial: 10 · Zero-coverage: 0 · No mutating methods: 10 · Missing calls: 10*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AppraisalController | – | – | – | – | – | – | – | generate:✅ |
| ComplianceController | ✅ | ❌ | – | – | – | – | – | – |
| DocumentController | ✅ | – | ✅ | – | – | – | – | – |
| EmploymentController | ✅ | ✅ | – | – | – | – | – | – |
| HolidayController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| IdCardTemplateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| LeaveApplicationController | ✅ | – | – | – | – | – | – | – |
| LeaveBalanceAdjustmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| LeaveTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| PayGradeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| PayrollController | ✅ | – | – | – | – | – | – | – |
| PtSlabController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| SalaryAssignmentController | ✅ | ✅ | – | – | – | – | – | – |
| SalaryComponentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| SalaryStructureController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| TdsLedgerController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |

## LmsHomework

*Controllers: 2 · Fully compliant: 0 · Partial: 2 · Zero-coverage: 0 · No mutating methods: 0 · Missing calls: 10*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| HomeworkSubmissionController | ❌ | ✅ | ✅ | – | ✅ | ✅ | ✅ | syncSubmissionAttachments:❌ |
| LmsHomeworkController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | clone:✅, publish:✅, syncHomeworkAttachments:❌, assignmentsGrade:❌, assignmentUpdateStatus:❌, assignmentUpdateDueDate:❌, assignmentUpdateAssignDate:❌, toggleAssignmentRelease:✅, syncAssignments:❌ |

## StudentFee

*Controllers: 15 · Fully compliant: 9 · Partial: 3 · Zero-coverage: 2 · No mutating methods: 1 · Missing calls: 10*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| FeeConcessionTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FeeFineRuleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FeeFineTransactionController | ✅ | ✅ | ✅ | – | – | – | – | – |
| FeeGroupMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| FeeHeadMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FeeInstallmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FeeInvoiceController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | recordPayment:❌, generateFeeInvoice:❌ |
| FeeScholarshipApplicationController | ✅ | – | – | – | – | – | – | – |
| FeeScholarshipController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FeeStructureMasterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| FeeStudentAssignmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | updateAssignmentStructure:✅, generateStudentAssignment:❌ |
| FeeStudentConcessionController | ✅ | ✅ | ✅ | – | – | – | – | – |
| StudentFeeController | ❌ | ❌ | ❌ | – | – | – | – | – |
| StudentFeeManagementController | ❌ | ❌ | ❌ | – | – | – | – | – |

## CommonChat

*Controllers: 15 · Fully compliant: 1 · Partial: 0 · Zero-coverage: 8 · No mutating methods: 6 · Missing calls: 9*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| ChatAjaxController | – | – | – | – | – | – | – | storeAttachment:❌ |
| ChatMessageController | ❌ | – | ❌ | – | – | – | – | – |
| ChatModerationController | – | – | ❌ | – | – | – | – | – |
| ChatParticipantController | – | – | – | – | – | – | – | transferAdmin:❌ |
| ChatPermissionConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ChatPersonalizationController | – | ❌ | – | – | – | – | – | – |
| ChatSettingsController | – | ❌ | – | – | – | – | – | – |
| CommonChatController | stub | stub | stub | – | – | – | – | – |
| MobileChatParticipantController | – | – | – | – | – | – | – | transferAdmin:❌ |
| MobileChatPersonalizationController | – | ❌ | – | – | – | – | – | – |

## Vendor

*Controllers: 8 · Fully compliant: 3 · Partial: 2 · Zero-coverage: 1 · No mutating methods: 2 · Missing calls: 9*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| VendorAgreementController | ✅ | ✅ | ❌ | – | ❌ | ❌ | ✅ | – |
| VendorController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| VendorInvoiceController | ❌ | ❌ | ❌ | – | – | – | ✅ | generateInvoice:❌ |
| VendorPaymentController | – | ❌ | ❌ | – | – | – | – | – |
| VndItemController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| VndUsageLogController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |

## QuestionBank

*Controllers: 7 · Fully compliant: 4 · Partial: 2 · Zero-coverage: 0 · No mutating methods: 1 · Missing calls: 8*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| QuestionBankController | ❌ | ❌ | ✅ | – | ❌ | ❌ | ✅ | storeClone:❌, reviewApprove:❌, reviewReject:❌ |
| QuestionMediaStoreController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| QuestionStatisticController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| QuestionTagController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| QuestionUsageTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| QuestionVersionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## ParentPortal

*Controllers: 28 · Fully compliant: 0 · Partial: 0 · Zero-coverage: 6 · No mutating methods: 22 · Missing calls: 7*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| ParentLeaveApiController | ❌ | – | – | – | – | – | – | – |
| ParentPtmApiController | – | – | – | – | – | – | – | cancel:❌ |
| ParentComplaintController | ❌ | – | – | – | – | – | – | – |
| ParentDocumentController | ❌ | – | – | – | – | – | – | payCallback:❌ |
| ParentLeaveController | ❌ | – | – | – | – | – | – | – |
| ParentPortalController | stub | stub | stub | – | – | – | – | – |
| ParentPtmController | – | – | – | – | – | – | – | cancel:❌ |

## Accounting

*Controllers: 21 · Fully compliant: 15 · Partial: 3 · Zero-coverage: 1 · No mutating methods: 2 · Missing calls: 6*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AccountGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| AccountingController | ❌ | ❌ | ❌ | – | – | – | – | – |
| AssetCategoryController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| BankReconciliationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| BudgetController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| CostCenterController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| EventVoucherConfigController | ✅ | ✅ | ✅ | – | – | – | – | – |
| ExpenseClaimController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| FinancialYearController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | lock:✅, unlock:✅ |
| FixedAssetController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LedgerController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LedgerMappingController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| ModuleEventController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RecurringTemplateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TallyExportController | – | – | ❌ | – | ✅ | ✅ | – | – |
| TallyLedgerMappingController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ❌ | – |
| TaxRateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| VoucherController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | approve:✅ |
| VoucherTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## LmsQuests

*Controllers: 4 · Fully compliant: 1 · Partial: 3 · Zero-coverage: 0 · No mutating methods: 0 · Missing calls: 5*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| LmsQuestController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| QuestAllocationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | publishRecommendations:❌, publishHiddenRecommendations:❌ |
| QuestQuestionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | bulkStore:❌, bulkDestroy:✅ |
| QuestScopeController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |

## Documentation

*Controllers: 3 · Fully compliant: 2 · Partial: 0 · Zero-coverage: 1 · No mutating methods: 0 · Missing calls: 3*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| DocumentationArticleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DocumentationCategoryController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DocumentationController | ❌ | ❌ | ❌ | – | – | – | – | – |

## Hpc

*Controllers: 11 · Fully compliant: 4 · Partial: 0 · Zero-coverage: 1 · No mutating methods: 6 · Missing calls: 3*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| HpcController | ❌ | ❌ | ❌ | – | – | – | – | – |
| HpcTemplatePartsController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| HpcTemplateRubricsController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| HpcTemplateSectionsController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| HpcTemplatesController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## LmsQuiz

*Controllers: 6 · Fully compliant: 3 · Partial: 2 · Zero-coverage: 0 · No mutating methods: 1 · Missing calls: 3*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| AssessmentTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DifficultyDistributionConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| LmsQuizController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| QuizAllocationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | publishRecommendations:❌, publishHiddenRecommendations:❌ |
| QuizQuestionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | bulkStore:❌, bulkDestroy:✅ |

## Recommendation

*Controllers: 10 · Fully compliant: 7 · Partial: 2 · Zero-coverage: 0 · No mutating methods: 1 · Missing calls: 3*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| DynamicMaterialTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| DynamicPurposeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| MaterialBundleController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RecAssessmentTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RecTriggerEventController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RecommendationMaterialController | ❌ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| RecommendationModeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RecommendationRuleController | ✅ | ❌ | ✅ | – | ✅ | ✅ | ✅ | – |
| StudentRecommendationController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |

## Scheduler

*Controllers: 1 · Fully compliant: 0 · Partial: 0 · Zero-coverage: 1 · No mutating methods: 0 · Missing calls: 3*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| SchedulerController | ❌ | ❌ | ❌ | – | – | – | – | – |

## Payment

*Controllers: 4 · Fully compliant: 1 · Partial: 0 · Zero-coverage: 2 · No mutating methods: 1 · Missing calls: 2*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| PaymentGatewayController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| RefundController | ❌ | – | – | – | – | – | – | – |
| WebhookController | – | – | – | – | – | – | – | razorpay:❌ |

## Ptm

*Controllers: 11 · Fully compliant: 8 · Partial: 1 · Zero-coverage: 0 · No mutating methods: 2 · Missing calls: 1*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| PtmAssignmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PtmAssignmentTeacherController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PtmBatchSlotTemplateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PtmBatchTemplateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | generateSlotTemplates:❌ |
| PtmBlockoutController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PtmEventClassSectionController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PtmEventController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PtmSlotBookingController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| PtmSlotController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## StandardTimetable

*Controllers: 1 · Fully compliant: 0 · Partial: 0 · Zero-coverage: 1 · No mutating methods: 0 · Missing calls: 1*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| StandardTimetableController | – | – | – | – | – | – | – | removeCell:❌ |

## Cafeteria

*Controllers: 16 · Fully compliant: 11 · Partial: 0 · Zero-coverage: 0 · No mutating methods: 5 · Missing calls: 0*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| DietaryProfileController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| EventMealController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| FssaiController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| MealCardController | – | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| MenuCategoryController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |
| MenuItemController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| StockController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubscriptionEnrollmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SubscriptionPlanController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| SupplierController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| WeeklyMenuController | ✅ | ✅ | ✅ | – | ✅ | ✅ | – | – |

## Dashboard

*Controllers: 26 · Fully compliant: 0 · Partial: 0 · Zero-coverage: 0 · No mutating methods: 26 · Missing calls: 0*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|

## EventEngine

*Controllers: 4 · Fully compliant: 3 · Partial: 0 · Zero-coverage: 0 · No mutating methods: 1 · Missing calls: 0*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| ActionTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| EventEngineController | stub | stub | stub | – | – | – | – | – |
| RuleEngineConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TriggerEventController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## MarksheetGeneration

*Controllers: 21 · Fully compliant: 17 · Partial: 0 · Zero-coverage: 0 · No mutating methods: 4 · Missing calls: 0*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| ClassGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ConfigTemplateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ExamGroupController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| IaComponentTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| MarksheetScheduleController | ✅ | ✅ | ✅ | – | – | – | – | – |
| MarksheetTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| ScheduleClassController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| StudentAttendanceController | ✅ | ✅ | – | – | – | – | – | – |
| StudentCoscholasticResultController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| StudentIaMarkController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| StudentResultController | ✅ | ✅ | ✅ | – | – | – | – | – |
| StudentSubjectResultController | ✅ | ✅ | – | – | – | – | – | – |
| SubjectPracticalConfigController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplateCoscholasticComponentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplateExamWeightageController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplateIaComponentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplateScholasticComponentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |

## Template

*Controllers: 5 · Fully compliant: 5 · Partial: 0 · Zero-coverage: 0 · No mutating methods: 0 · Missing calls: 0*


| Controller | store | update | destroy | delete | restore | forceDelete | toggleStatus | Other (custom) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| TemplateAssignmentController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplateController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplatePurposeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplateTypeController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |
| TemplateVariableController | ✅ | ✅ | ✅ | – | ✅ | ✅ | ✅ | – |