# 03 — Route → Controller → Model Map

## Routing Architecture

| Route File | Lines | Scope | Middleware |
|-----------|-------|-------|-----------|
| `routes/web.php` | 973 | Central admin | auth, verified |
| `routes/tenant.php` | 2,628 | Per-school features | auth, verified, InitializeTenancyByDomain, EnsureTenantIsActive |
| `routes/api.php` | 9 | Minimal API | auth:sanctum |
| Module `routes/api.php` | varies | Per-module API | auth:sanctum, v1 prefix |

---

## Central Admin Routes (web.php)

### Dashboard
| Endpoint | Method | Controller | Models | Tables |
|----------|--------|-----------|--------|--------|
| `/dashboard` | GET | DashboardController@index | — | — |
| `/dashboard/configuration` | GET | DashboardController@configuration | — | — |
| `/dashboard/foundational-setup` | GET | DashboardController@foundationalSetup | — | — |
| `/dashboard/subscription-billing` | GET | DashboardController@subscriptionBilling | — | — |

### Prime — Tenant Management
| Endpoint | Method | Controller | Models | Tables |
|----------|--------|-----------|--------|--------|
| `/prime/tenants` | GET | TenantController@index | Tenant | prm_tenant |
| `/prime/tenants` | POST | TenantController@store | Tenant, Domain | prm_tenant, prm_tenant_domains |
| `/prime/tenants/{id}` | GET | TenantController@show | Tenant | prm_tenant |
| `/prime/tenants/{id}` | PUT | TenantController@update | Tenant | prm_tenant |
| `/prime/tenants/{id}` | DELETE | TenantController@destroy | Tenant | prm_tenant |
| `/prime/tenants/{id}/toggle-status` | POST | TenantController@toggleStatus | Tenant | prm_tenant |
| `/prime/tenants/{id}/restore` | POST | TenantController@restore | Tenant | prm_tenant |
| `/prime/users` | CRUD | UserController | User, Role | sys_users, sys_roles |
| `/prime/role-permission` | CRUD | RolePermissionController | Role, Permission | sys_roles, sys_permissions |
| `/prime/academic-sessions` | CRUD | AcademicSessionController | AcademicSession | prm_academic_sessions |
| `/prime/boards` | CRUD | BoardController | Board | glb_boards |

### Billing
| Endpoint | Method | Controller | Models | Tables |
|----------|--------|-----------|--------|--------|
| `/billing/billing-management` | CRUD | BillingManagementController | BilTenantInvoice | bil_tenant_invoices |
| `/billing/subscription` | CRUD | SubscriptionController | TenantPlan | prm_tenant_plan_jnt |
| `/billing/invoicing-payment` | CRUD | InvoicingPaymentController | InvoicingPayment | bil_tenant_invoicing_payments |
| `/billing/invoicing-audit-log` | CRUD | InvoicingAuditLogController | InvoicingAuditLog | bil_tenant_invoicing_audit_logs |
| `/billing/billing-cycle` | CRUD | BillingCycleController | BillingCycle | billing_cycles |
| `/billing/send-email/{id}` | POST | BillingManagementController@sendEmail | BilTenantInvoice | bil_tenant_invoices |

### Global Master
| Endpoint | Method | Controller | Models | Tables |
|----------|--------|-----------|--------|--------|
| `/global-master/country` | CRUD | CountryController | Country | glb_countries |
| `/global-master/state` | CRUD | StateController | State | glb_states |
| `/global-master/city` | CRUD | CityController | City | glb_cities |
| `/global-master/district` | CRUD | DistrictController | District | glb_districts |
| `/global-master/plan` | CRUD | PlanController | Plan | prm_plans |
| `/global-master/language` | CRUD | LanguageController | Language | sys_languages |
| `/global-master/module` | CRUD | ModuleController | Module | glb_modules |
| `/global-master/dropdown` | CRUD | DropdownController | Dropdown | sys_dropdowns |

---

## Tenant Routes (tenant.php) — Key Mappings

### School Setup (`/school-setup/*`)
| Endpoint | Controller | Models Used | Tables |
|----------|-----------|-------------|--------|
| `/school-setup/organization` | OrganizationController | Organization, City, Board | sch_organizations, glb_cities, glb_boards |
| `/school-setup/class` | SchoolClassController | SchoolClass, Organization | sch_classes, sch_organizations |
| `/school-setup/section` | SectionController | Section, Organization | sch_sections |
| `/school-setup/subject` | SubjectController | Subject, SubjectGroup | sch_subjects, sch_subject_groups |
| `/school-setup/teacher` | TeacherController | Teacher, User, TeacherProfile | sch_teachers, sys_users, sch_teacher_profiles |
| `/school-setup/room` | RoomController | Room, Building, RoomType | sch_rooms, sch_buildings, sch_room_types |
| `/school-setup/building` | BuildingController | Building, Organization | sch_buildings |
| `/school-setup/class-section` | ClassSectionController | ClassSection, Class, Section | sch_class_section_jnt |
| `/school-setup/subject-group` | SubjectGroupController | SubjectGroup, Subject | sch_subject_groups, sch_subject_group_subject_jnt |
| `/school-setup/users` | UserController | User, Role | sys_users, sys_roles |
| `/school-setup/role-permission` | RolePermissionController | Role, Permission | sys_roles, sys_permissions |

### Student Profile
| Endpoint | Controller | Models Used | Tables |
|----------|-----------|-------------|--------|
| `/student/students` | StudentController | Student, StudentDetail, User, Guardian | std_students, std_student_details, sys_users, std_guardians |
| `/student/attendance` | AttendanceController | StudentAttendance, Student, ClassSection | std_attendance_details, std_students |
| `/student/medical-incidents` | MedicalIncidentController | MedicalIncident, Student | std_medical_incidents |

### Smart Timetable (`/smart-timetable/*`)
| Endpoint | Controller | Models Used | Tables |
|----------|-----------|-------------|--------|
| `/smart-timetable/timetable` | TimetableController | Timetable, TimetableCell, GenerationRun | tt_timetables, tt_timetable_cells, tt_generation_runs |
| `/smart-timetable/activity` | ActivityController | Activity, Subject, Teacher, ClassGroup | tt_activities, sch_subjects, sch_teachers |
| `/smart-timetable/constraint` | ConstraintController | Constraint, ConstraintType, ConstraintScope | tt_constraints, tt_constraint_types |
| `/smart-timetable/period-set` | PeriodSetController | PeriodSet, PeriodSetPeriod | tt_period_sets, tt_period_set_periods |
| `/smart-timetable/teacher-availability` | TeacherAvailabilityController | TeacherAvailability, Teacher | tt_teacher_availabilities |

### Transport (`/transport/*`)
| Endpoint | Controller | Models Used | Tables |
|----------|-----------|-------------|--------|
| `/transport/vehicle` | VehicleController | Vehicle, VehicleType | tpt_vehicle |
| `/transport/route` | RouteController | Route, PickupPoint | tpt_routes, tpt_pickup_points |
| `/transport/trip` | TripController | TptTrip, Vehicle, Route | tpt_trips, tpt_vehicle, tpt_routes |
| `/transport/student-allocation` | StudentAllocationController | TptStudentAllocationJnt, Student | tpt_student_allocation_jnt, std_students |
| `/transport/driver-attendance` | DriverAttendanceController | TptDriverAttendance, DriverHelper | tpt_driver_attendance |

### Student Fee (`/student-fee/*`)
| Endpoint | Controller | Models Used | Tables |
|----------|-----------|-------------|--------|
| `/student-fee/fee-head` | FeeHeadMasterController | FeeHeadMaster | fin_fee_head_masters |
| `/student-fee/fee-structure` | StudentFeeController | FeeStructureMaster, FeeStructureDetail | fin_fee_structure_masters, fin_fee_structure_details |
| `/student-fee/fee-invoice` | FeeInvoiceController | FeeInvoice, Student | fin_fee_invoices, std_students |
| `/student-fee/fee-scholarship` | FeeScholarshipController | FeeScholarship | fin_fee_scholarships |
| `/student-fee/fee-concession` | FeeConcessionController | FeeStudentConcession | fin_fee_student_concessions |

### Complaint
| Endpoint | Controller | Models Used | Tables |
|----------|-----------|-------------|--------|
| `/complaint/complaints` | ComplaintController | Complaint, User, Category | cmp_complaints, sys_users, cmp_complaint_categories |
| `/complaint/categories` | ComplaintCategoryController | ComplaintCategory | cmp_complaint_categories |
| `/complaint/department-sla` | DepartmentSlaController | DepartmentSla | cmp_department_sla |
| `/complaint/dashboard` | ComplaintDashboardController | Complaint | cmp_complaints |

### Other Modules
| Module | Route Prefix | Key Endpoints |
|--------|-------------|---------------|
| Syllabus | `/syllabus/*` | lessons, topics, competencies, bloom-taxonomy, complexity-levels |
| SyllabusBooks | `/syllabus-books/*` | books, authors, topic-mappings |
| QuestionBank | `/question-bank/*` | questions, tags, versions, statistics, ai-generator |
| LmsExam | `/exam/*` | exams, papers, paper-sets, allocations, student-groups |
| LmsQuiz | `/quiz/*` | quizzes, questions, allocations, assessment-types |
| LmsHomework | `/homework/*` | homework, submissions, action-types, rule-engine |
| LmsQuests | `/quests/*` | quests, questions, allocations, scopes |
| Hpc | `/hpc/*` | learning-outcomes, evaluations, parameters, circular-goals |
| Recommendation | `/recommendation/*` | rules, materials, student-recommendations |
| Notification | `/notification/*` | channels, templates, targets, delivery, threads |
| Vendor | `/vendor/*` | vendors, agreements, invoices, payments, items |
| Payment | `/payment/*` | payment-management, payment-gateway, webhooks |

---

## API Endpoints (Module-Level)

All module APIs use: `auth:sanctum` middleware, `/v1/` prefix, `apiResource()` pattern.

| Module | API Endpoint | HTTP Methods |
|--------|-------------|-------------|
| Prime | `/v1/primes` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| GlobalMaster | `/v1/globalmasters` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| SchoolSetup | `/v1/schoolsetups` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| SmartTimetable | `/v1/smarttimetables` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| StudentProfile | `/v1/studentprofiles` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| Complaint | `/v1/complaints` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| Transport | `/v1/transports` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| Syllabus | `/v1/syllabi` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| QuestionBank | `/v1/questionbanks` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| LmsQuiz | `/v1/lmsquizzes` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| StudentFee | `/v1/studentfees` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |
| Hpc | `/v1/hpcs` | GET, POST, GET/{id}, PUT/{id}, DELETE/{id} |

---

## Common CRUD Pattern

Most controllers implement this standard pattern:

```
index()         → List with pagination
create()        → Show create form
store()         → Save new record (FormRequest validation)
show()          → Detail view
edit()          → Show edit form
update()        → Save changes (FormRequest validation)
destroy()       → Soft delete
trashedResource() → List soft-deleted
restore()       → Restore soft-deleted
forceDelete()   → Permanent delete
toggleStatus()  → Enable/disable toggle
```
