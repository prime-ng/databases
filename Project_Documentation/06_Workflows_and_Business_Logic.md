# 06 — Workflows and Business Logic

## 1. Tenant Onboarding Workflow

```
1. Super Admin creates new tenant via Prime module
   └── TenantController@store
       ├── Creates prm_tenant record (UUID)
       ├── Creates prm_tenant_domains record
       ├── Stancl Tenancy provisions tenant_{uuid} database
       ├── Runs tenant migrations (216 migration files)
       └── Dispatches Jobs:
           ├── CreateRootUser (creates admin user in tenant DB)
           ├── CreateTenantStorageSymlink (creates storage directories)
           └── AddOrganizationDetails (initializes school record)

2. Plan assignment
   └── TenantPlanAssigner service (atomic transaction)
       ├── Creates prm_tenant_plan_jnt record
       ├── Creates prm_tenant_plan_rates records
       ├── Creates prm_tenant_plan_module_jnt records
       └── Generates billing schedules

3. Tenant accesses their subdomain (school1.prime-ai.com)
   └── InitializeTenancyByDomain middleware
       ├── Resolves tenant from domain
       ├── Bootstraps: Database, Cache, Filesystem, Queue
       ├── EnsureTenantIsActive middleware checks:
       │   ├── is_active = true
       │   ├── isProfileComplete()
       │   └── allowedModuleIds() has entries
       └── Tenant context fully initialized
```

---

## 2. AI Timetable Generation Workflow

```
1. Prerequisites Setup
   ├── School Setup: Classes, Sections, Subjects, Teachers, Rooms (SchoolSetup module)
   ├── Period Configuration: Period sets, school days, working days
   ├── Activity Creation: Define what needs to be scheduled
   │   └── Each activity = Subject + ClassGroup + Teacher(s) + periods_per_week
   ├── Constraint Definition: Hard/soft scheduling rules
   └── Teacher/Room Availability: Define available slots

2. Pre-Generation Processing
   ├── ActivityScoreService.recalculateBatch()
   │   ├── Calculates difficulty score (5 components):
   │   │   ├── Teacher scarcity
   │   │   ├── Room scarcity
   │   │   ├── Constraint burden
   │   │   ├── Period demand
   │   │   └── Consecutive/gap burden
   │   └── Calculates priority score (manual override + compulsory + difficulty + scarcity)
   ├── RoomAvailabilityService.generate()
   │   └── Generates room availability matrix for all active rooms
   └── SubActivityService.generateForTerm()
       └── Creates sub-activities for multi-period block activities

3. FET Solver Execution
   ├── DatabaseConstraintService.loadConstraintsForGeneration()
   │   └── Loads all active constraints into ConstraintManager
   ├── FETSolver runs (max 50,000 iterations, 25-second timeout)
   │   ├── Orders activities by priority score (highest first)
   │   ├── For each activity:
   │   │   ├── SlotGenerator generates candidate (day, period) slots
   │   │   ├── SlotEvaluator scores each slot against constraints
   │   │   ├── Hard constraints MUST be satisfied (teacher conflict, etc.)
   │   │   ├── Soft constraints generate weighted violation scores
   │   │   └── Best slot selected and activity placed
   │   └── Backtracking when placement fails
   └── Generates TimetableSolution

4. Persistence
   └── TimetableStorageService.storeGeneratedTimetable() (atomic transaction)
       ├── Creates tt_timetables record (status: GENERATED)
       ├── Creates tt_generation_runs record
       ├── Creates tt_timetable_cells for each placed activity
       └── Updates timetable stats (quality_score, soft_score, violations)

5. Post-Generation
   ├── Approval workflow (tt_approval_workflows)
   ├── Version comparison (tt_version_comparisons)
   ├── Impact analysis (tt_impact_analysis_sessions)
   └── Publishing (status: DRAFT → GENERATING → GENERATED → PUBLISHED)
```

---

## 3. Student Admission Workflow

```
1. Student Data Entry
   └── StudentController@store (StudentProfile module)
       ├── Creates std_students record (admission_no, user_id, dob, gender)
       ├── Creates sys_users record (linked user account)
       ├── Creates std_student_details (extended information)
       └── Fires StudentRegistration event (stub)

2. Academic Session Enrollment
   └── Creates std_student_academic_session record
       ├── Links student to class_section_id
       ├── Links to academic_session_id
       └── Sets enrollment status

3. Guardian Linking
   └── Creates std_guardians + std_student_guardian_jnt
       └── Many-to-many: multiple guardians per student

4. Profile Completion
   ├── std_student_profiles (detailed profile)
   ├── std_student_addresses (residential, permanent)
   ├── std_student_documents (certificates, IDs)
   ├── std_student_health_profiles (health data)
   ├── std_vaccination_records (vaccination history)
   └── std_previous_educations (prior schooling)

5. Fee Assignment
   └── StudentFee module
       ├── fin_fee_student_assignments (assigns fee group)
       ├── fin_fee_invoices (generates invoices per installment)
       └── fin_fee_student_concessions (if applicable)

6. Transport Allocation (optional)
   └── Transport module
       ├── tpt_student_allocation_jnt (route/vehicle assignment)
       └── tpt_student_boarding_logs (tracking setup)
```

---

## 4. Fee Payment Workflow

```
1. Fee Structure Setup
   ├── FeeHeadMaster (fee categories: tuition, transport, lab, etc.)
   ├── FeeGroupMaster (groups heads into collections)
   ├── FeeStructureMaster (class-level fee definition)
   ├── FeeStructureDetail (head-level amounts per structure)
   └── FeeInstallment (payment schedule: monthly, quarterly, etc.)

2. Student Assignment
   └── FeeStudentAssignment
       ├── Links student to fee group
       ├── Applies concessions (FeeConcessionType + FeeStudentConcession)
       └── Applies scholarships (FeeScholarship + FeeScholarshipApplication)

3. Invoice Generation
   └── FeeInvoice created for each installment
       ├── Calculates net amount (fee - concession - scholarship)
       ├── Applies fine rules (FeeFineRule) for late payment
       └── Status: Pending

4. Payment Processing
   └── Payment module integration
       ├── PaymentService.createPayment()
       │   └── GatewayManager.resolve('razorpay')
       │       └── RazorpayGateway creates order
       ├── Student makes payment (Razorpay checkout)
       ├── PaymentCallbackController handles webhook
       │   ├── Verifies signature
       │   ├── Creates fin_fee_transactions record
       │   ├── Creates fin_fee_transaction_details (per fee head)
       │   └── Creates fin_fee_receipts
       └── Invoice status updated to Paid

5. Reporting
   ├── Fee collection reports
   ├── Outstanding dues tracking
   ├── Concession/scholarship reports
   └── Payment gateway logs (fin_fee_payment_gateway_logs)
```

---

## 5. Complaint Management Workflow

```
1. Complaint Submission
   └── ComplaintController@store
       ├── Creates cmp_complaints record
       │   ├── complainant_type_id, complainant_user_id
       │   ├── category_id, severity_id, priority_id
       │   └── status_id, description, evidence
       └── Fires ComplaintSaved event

2. AI Analysis (Async)
   └── ProcessComplaintAIInsights listener (queued)
       └── ComplaintAIInsightEngine.processComplaint()
           ├── calculateSentiment() → sentiment score
           ├── calculateRiskScore() → escalation risk
           ├── calculateSafetyRisk() → safety concern score
           ├── predictCategory() → suggested category
           └── Creates cmp_ai_insights record

3. Assignment & Action
   ├── Complaint assigned to role/user
   ├── ComplaintAction records track resolution steps
   │   ├── action type, description, assigned_role, assigned_user
   │   └── performed_by, action_date
   └── Medical checks if health-related (cmp_medical_checks)

4. SLA Monitoring
   └── DepartmentSla defines resolution timeframes
       ├── Tracks against complaint creation time
       └── Escalation based on EscalationRule if SLA breached

5. Resolution
   ├── Status updated (Open → In Progress → Resolved → Closed)
   ├── resolved_by_role_id, resolved_by_user_id recorded
   └── Dashboard updated via ComplaintDashboardService
       ├── Average resolution hours
       ├── SLA breach rate
       ├── Category distribution
       └── Severity trends
```

---

## 6. Notification Dispatch Workflow

```
1. Trigger
   └── SystemNotificationTriggered event fired
       ├── Event code (e.g., 'COMPLAINT_CREATED', 'INVOICE_GENERATED')
       └── Context payload (entity data, user data)

2. Processing (Async)
   └── ProcessSystemNotification listener (queued)
       └── NotificationService.trigger(eventCode, context)
           ├── Fetch notification definition by event code
           ├── Load active channels for this notification
           ├── Render template with context payload
           └── For each channel:
               └── dispatchToChannel(channel, renderedContent)

3. Channel Dispatch
   ├── EMAIL → Send via configured SMTP/SES
   ├── IN_APP → Store in ntf_notification_delivery_logs
   ├── SMS → (Stubbed, not fully implemented)
   └── PUSH → (Stubbed, not fully implemented)

4. Logging
   └── ntf_notification_delivery_logs
       ├── notification_id, channel, recipient
       ├── status (sent, failed, pending)
       └── sent_at, error_message
```

---

## 7. Attendance Recording Workflow

```
1. Student Attendance
   └── AttendanceController (StudentProfile module)
       ├── Teacher selects class-section and date
       ├── Student list loaded from std_student_academic_session
       ├── Marks present/absent/late for each student
       └── Creates std_attendance_details records

2. Transport Attendance
   └── StudentAttendanceController (Transport module)
       ├── QR code scanned at boarding/alighting
       ├── Creates tpt_student_boarding_logs
       ├── GPS-tagged with trip details
       └── Real-time tracking via tpt_live_trips

3. Driver Attendance
   └── DriverAttendanceController (Transport module)
       ├── QR-based check-in/check-out
       ├── Creates tpt_driver_attendance records
       └── Logs in tpt_driver_attendance_logs

4. Attendance Corrections
   └── Student/parent requests correction
       ├── Creates std_attendance_corrections
       ├── Teacher/admin reviews
       └── Updates original attendance record
```

---

## 8. Billing & Invoice Workflow (Central)

```
1. Plan Setup
   ├── Plans defined with billing cycles (monthly, quarterly, annual)
   ├── Each plan links to specific modules
   └── Rates configured per plan

2. Invoice Generation
   └── BillingManagementController
       ├── Creates bil_tenant_invoices for due period
       ├── Breaks down by module (bil_tenant_invoicing_modules_jnt)
       └── Status: Draft

3. Invoice Delivery
   └── SendInvoiceEmailJob (queued)
       ├── Generates PDF via DomPDF
       ├── Sends InvoiceMail with PDF attachment
       └── Logs in bil_tenant_invoicing_audit_logs

4. Payment Recording
   └── InvoicingPaymentController
       ├── Records payment (bil_tenant_invoicing_payments)
       ├── Updates invoice status (Paid/Partial)
       └── Audit log entry

5. Scheduled Emails
   └── bil_tenant_email_schedules
       ├── SendScheduledEmail job processes queue
       └── Tracks send status and errors
```

---

## 9. Authorization Flow

```
1. Request arrives at route
   ├── auth middleware → verify user session/token
   ├── verified middleware → check email verification
   ├── InitializeTenancyByDomain → resolve and bootstrap tenant
   ├── EnsureTenantIsActive → check tenant status
   └── EnsureTenantHasModule → check module access

2. Controller method
   └── $this->authorize('viewAny', Model::class)
       └── Gate evaluates matching Policy
           ├── Checks user role via Spatie Permission
           ├── Super Admin bypasses all checks
           └── Returns true/false

3. Permission checking patterns:
   ├── Route middleware: ->middleware('permission:manage-students')
   ├── Controller: $this->authorize('create', Student::class)
   ├── Blade: @can('update', $student) ... @endcan
   └── Helper: PermissionHelper::exists('module.action')
```
