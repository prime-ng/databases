# 04 — Database Schema

## Three-Layer Database Architecture

### Layer 1: Global Database (`global_db`) — 12 Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `glb_countries` | Country master | id, name, code, phone_code, is_active, soft_deletes |
| `glb_states` | State master | id, country_id (FK), name, code, is_active, soft_deletes |
| `glb_districts` | District master | id, state_id (FK), name, is_active, soft_deletes |
| `glb_cities` | City master | id, district_id (FK), name, is_active, soft_deletes |
| `glb_boards` | Educational boards (CBSE, ICSE, etc.) | id, name, code, description, is_active, soft_deletes |
| `glb_languages` | Language master | id, name, code, is_active, soft_deletes |
| `glb_academic_sessions` | Academic year sessions | id, name, start_date, end_date, is_current, current_flag (generated) |
| `glb_menus` | Navigation menus | id, name, url, icon, parent_id, sort_order |
| `glb_modules` | Platform modules | id, name, code, description, is_active |
| `glb_menu_model_jnt` | Menu-module junction | id, menu_id (FK), module_id (FK) |
| `glb_translations` | Multi-language translations | id, key, language_id, value |
| `glb_activity_logs` | Global activity logs | id, user_id, subject_type, subject_id, event, properties, ip_address |

---

### Layer 2: Prime Database (`prime_db`) — 27 Tables

**Tenant Management:**

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `prm_tenant` | Tenant master (UUID) | id (uuid), name, email, phone, data (json), is_active, soft_deletes |
| `prm_tenant_domains` | Domain mapping | id, domain, tenant_id (FK) |
| `prm_tenant_groups` | Tenant grouping | id, name, description, is_active |

**Plans & Billing:**

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `prm_plans` | Subscription plans | id, name, code, description, billing_cycle_id, base_price, is_active |
| `prm_tenant_plan_jnt` | Tenant-plan assignment | id, tenant_id, plan_id, start_date, end_date, status |
| `prm_tenant_plan_rates` | Plan rate details | id, tenant_plan_id, rate_type, amount |
| `prm_tenant_plan_module_jnt` | Plan-module mapping | id, tenant_plan_id, module_id |
| `prm_tenant_plan_billing_schedules` | Billing schedules | id, tenant_plan_id, due_date, amount |
| `prm_billing_cycles` | Billing cycle definitions | id, name, months, is_active |

**Invoicing:**

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `bil_tenant_invoices` | Generated invoices | id, tenant_id, tenant_plan_id, invoice_no, amount, status, due_date |
| `bil_tenant_invoicing_modules_jnt` | Invoice-module breakdown | id, invoice_id, module_id, amount |
| `bil_tenant_invoicing_payments` | Payment records | id, invoice_id, amount, payment_method, transaction_id |
| `bil_tenant_invoicing_audit_logs` | Audit trail | id, invoice_id, user_id, action, details |
| `bil_tenant_email_schedules` | Email scheduling | id, invoice_id, scheduled_at, sent_at, status |

**System:**

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `sys_users` | Central users | id, name, email, password, is_super_admin, user_type, is_active, soft_deletes |
| `sys_roles` | Role definitions | id, name, guard_name, is_system, description |
| `sys_permissions` | Permission definitions | id, name, guard_name, description |
| `sys_role_has_permissions_jnt` | Role-permission mapping | role_id, permission_id |
| `sys_model_has_permissions_jnt` | Direct user permissions | model_type, model_id, permission_id |
| `sys_model_has_roles_jnt` | User-role assignment | model_type, model_id, role_id |
| `sys_settings` | System settings | id, key, value, group, type |
| `sys_dropdown_needs` | Dropdown configuration | id, name, description |
| `sys_dropdowns` | Dropdown values | id, dropdown_need_id, label, value, sort_order |
| `sys_dropdown_need_table_jnt` | Dropdown-table mapping | id, dropdown_need_id, table_name |
| `sys_media` | Media library (Spatie) | id, model_type, model_id, collection_name, file_name, disk |
| `sys_activity_logs` | Activity audit trail | id, user_id, subject_type, subject_id, event, properties |

---

### Layer 3: Tenant Database (`tenant_{uuid}`) — 368 Tables

Tables organized by prefix:

#### System Tables (sys_* — ~15 tables)
Tenant-level RBAC, settings, media, activity logs — mirrors prime_db structure for tenant isolation.

| Table | Purpose |
|-------|---------|
| `sys_users` | Tenant users (teachers, students, parents, staff) |
| `sys_roles` | Tenant roles (9 roles: Super Admin, Principal, Vice Principal, Teacher, Staff, Accountant, Librarian, Parent, Student) |
| `sys_permissions` | Tenant permissions (100+ per module) |
| `sys_role_has_permissions_jnt` | Role-permission mapping |
| `sys_model_has_permissions_jnt` | Direct user permissions |
| `sys_model_has_roles_jnt` | User-role assignment |
| `sys_settings` | Tenant settings |
| `sys_dropdowns` | Tenant dropdown values |
| `sys_dropdown_needs` | Dropdown definitions |
| `sys_media` | Media files |
| `sys_activity_logs` | Audit logs |

#### School Setup Tables (sch_* — ~25 tables)

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `sch_organizations` | School details | → city, boards (M2M) |
| `sch_organization_groups` | Organization grouping | → country |
| `sch_org_academic_sessions_jnt` | Academic session binding | → organization, academic_session |
| `sch_board_organization_jnt` | Board assignment | → board, organization |
| `sch_classes` | Class master (1-12) | → organization |
| `sch_sections` | Section master (A, B, C) | → organization |
| `sch_class_section_jnt` | Class-section combinations | → class, section, class_teacher |
| `sch_subjects` | Subject master | → subject_groups (M2M) |
| `sch_subject_groups` | Subject groupings | → class |
| `sch_subject_group_subject_jnt` | Subject-group mapping | → subject_group, subject |
| `sch_subject_teachers` | Teacher-subject assignment | → teacher, subject |
| `sch_teachers` | Teacher records | → user |
| `sch_teacher_profiles` | Teacher details | → user, teacher |
| `sch_teacher_capability` | Teacher capabilities | → teacher |
| `sch_rooms` | Room inventory | → building, room_type |
| `sch_room_types` | Room classifications | — |
| `sch_buildings` | Building master | → organization |
| `sch_employees` | Employee records | → user, designation, department |
| `sch_employee_profiles` | Employee details | → employee |
| `sch_departments` | Department master | — |
| `sch_designations` | Designation master | — |
| `sch_leave_types` | Leave type definitions | — |
| `sch_leave_configs` | Leave configuration | → leave_type |
| `sch_study_format` | Study format master | — |
| `sch_subject_study_format` | Subject-format mapping | → subject, study_format |
| `sch_entity_groups` | Entity grouping | — |
| `sch_entity_group_member` | Group members | → entity_group |
| `sch_disable_reasons` | Disable reason master | — |
| `sch_question_types` | Question type master | — |
| `sch_class_groups_jnt` | Class grouping | → class |

#### Timetable Tables (tt_* — ~45 tables)

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `tt_timetables` | Generated timetables | → academic_session, academic_term, timetable_type, period_set |
| `tt_timetable_cells` | Individual cells | → timetable, activity, class_group |
| `tt_timetable_cell_teachers` | Cell-teacher mapping | → timetable_cell, teacher |
| `tt_activities` | Teaching activities | → subject, class_group |
| `tt_sub_activities` | Sub-activities (blocks) | → activity |
| `tt_activity_teachers` | Activity-teacher mapping | → activity, teacher |
| `tt_activity_priority` | Priority scoring | — |
| `tt_academic_terms` | Term definitions | → academic_session |
| `tt_timetable_types` | Type classifications | — |
| `tt_period_sets` | Period set definitions | — |
| `tt_period_set_periods` | Period details | → period_set |
| `tt_period_types` | Period type master | — |
| `tt_school_days` | School day definitions | — |
| `tt_day_types` | Day type master | — |
| `tt_working_day` | Working day config | — |
| `tt_class_working_day` | Class-specific working days | → class |
| `tt_class_timetable_type` | Class timetable types | → class |
| `tt_constraints` | Scheduling constraints | → constraint_type, scope, target_type |
| `tt_constraint_types` | Constraint classifications | — |
| `tt_constraint_categories` | Category grouping | — |
| `tt_constraint_category_scopes` | Category-scope mapping | — |
| `tt_constraint_scopes` | Scope definitions | — |
| `tt_constraint_target_types` | Target type definitions | — |
| `tt_constraint_groups` | Constraint grouping | — |
| `tt_constraint_group_members` | Group members | — |
| `tt_constraint_templates` | Template constraints | — |
| `tt_constraint_violations` | Violation records | → constraint, timetable |
| `tt_generation_runs` | Generation execution logs | — |
| `tt_generation_queues` | Generation queue entries | — |
| `tt_teacher_availabilities` | Availability records | → teacher |
| `tt_teacher_availability_logs` | Availability history | → teacher |
| `tt_teacher_unavailable` | Unavailability records | → teacher |
| `tt_teacher_absences` | Absence records | → teacher |
| `tt_teacher_workloads` | Workload tracking | → teacher |
| `tt_room_availabilities` | Room availability | → room |
| `tt_room_unavailable` | Room unavailability | → room |
| `tt_room_utilization` | Utilization metrics | → room |
| `tt_conflict_detections` | Detected conflicts | → timetable |
| `tt_substitution_logs` | Substitution history | → teacher (absent & substitute) |
| `tt_optimization_runs` | Optimization tracking | → generation_run |
| `tt_ml_models` | ML model metadata | — |
| `tt_training_data` | ML training data | → ml_model |
| `tt_approval_workflows` | Approval process | — |
| `tt_approval_requests` | Approval entries | → timetable |
| `tt_change_logs` | Change history | → timetable |
| `tt_config` | Module configuration | — |
| `tt_slot_requirements` | Slot requirement config | — |
| `tt_batch_operations` | Batch operation tracking | — |

#### Student Tables (std_* — ~12 tables)

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `std_students` | Student master | → user, organization |
| `std_student_details` | Extended details | → student |
| `std_student_profiles` | Profile data | → student |
| `std_student_academic_session` | Session enrollment | → student, class_section, academic_session |
| `std_student_addresses` | Address records | → student, state, city |
| `std_attendance_details` | Attendance records | → student, class_section |
| `std_attendance_corrections` | Correction requests | → student |
| `std_student_documents` | Document uploads | → student |
| `std_student_health_profiles` | Health information | → student |
| `std_vaccination_records` | Vaccination history | → student |
| `std_medical_incidents` | Medical incidents | → student |
| `std_guardians` | Guardian master | — |
| `std_student_guardian_jnt` | Student-guardian mapping | → student, guardian |
| `std_previous_educations` | Education history | → student |

#### Syllabus Tables (slb_* — ~17 tables)

| Table | Purpose |
|-------|---------|
| `slb_lessons` | Lesson definitions (→ academic_session, class, subject) |
| `slb_topics` | Topic hierarchy (parent/child, → lesson) |
| `slb_competencies` | Competency definitions (→ competency_type) |
| `slb_competency_types` | Competency type master |
| `slb_topic_competencies` | Topic-competency mapping |
| `slb_topic_dependencies` | Prerequisite topics |
| `slb_topic_level_types` | Topic level classifications |
| `slb_bloom_taxonomy` | Bloom's taxonomy levels |
| `slb_cognitive_skills` | Cognitive skill master |
| `slb_complexity_levels` | Complexity classifications |
| `slb_performance_categories` | Performance categories |
| `slb_grade_division_masters` | Grade divisions |
| `slb_study_materials` | Study material records |
| `slb_study_material_types` | Material type master |
| `slb_question_types` | Question type master |
| `slb_que_type_specifity` | Question type specificity |
| `slb_syllabus_schedules` | Schedule planning |

#### Other Table Groups

| Prefix | Count | Purpose |
|--------|-------|---------|
| **qns_*** | ~3+ | Question Bank (questions, options, media) |
| **bok_*** | ~8 | Books/Textbooks (books, authors, topic mappings) |
| **tpt_*** | ~35 | Transport (vehicles, routes, trips, GPS, ML, fees, attendance) |
| **vnd_*** | ~7 | Vendor (vendors, agreements, items, invoices, payments) |
| **cmp_*** | ~6 | Complaint (categories, complaints, actions, SLA, AI insights) |
| **rec_*** | ~10 | Recommendation (rules, materials, bundles, triggers) |
| **ntf_*** | ~7 | Notification (channels, templates, targets, delivery logs) |
| **fin_*** | ~21 | Fee Management (heads, groups, structures, installments, invoices, transactions, scholarships) |
| **pmt_*** | ~4 | Payment Gateway (payments, gateways, histories, webhooks) |
| **hpc_*** | ~12 | HPC (learning outcomes, evaluations, activities, goals) |
| **lms_*** | ~20+ | LMS (exams, quizzes, homework, quests, papers, allocations) |
| **doc_*** | ~3 | Documentation (articles, categories) |

---

## Migration Statistics

| Location | Files | Purpose |
|----------|-------|---------|
| `database/migrations/` | 6 | Central tables (cache, jobs, tokens, media, notifications, telescope) |
| `database/migrations/tenant/` | 216 | Tenant-scoped tables |
| `Modules/Prime/database/migrations/` | 38 | Prime module migrations |
| `Modules/GlobalMaster/database/migrations/` | 10 | Global master migrations |
| `Modules/Transport/database/migrations/` | 26 | Transport module migrations |
| `Modules/Complaint/database/migrations/` | 6 | Complaint module migrations |
| `Modules/SyllabusBooks/database/migrations/` | 6 | SyllabusBooks module migrations |
| `Modules/Documentation/database/migrations/` | 3 | Documentation module migrations |
| `Modules/Scheduler/database/migrations/` | 2 | Scheduler module migrations |
| **TOTAL** | **280** | |

## Common Schema Patterns

**Standard Columns (ALL tables):**
```sql
`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
`is_active` TINYINT(1) NOT NULL DEFAULT 1,
`created_by` INT UNSIGNED DEFAULT NULL,
`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`deleted_at` TIMESTAMP NULL DEFAULT NULL,
PRIMARY KEY (`id`)
```

**Naming Conventions:**
- Tables: `{prefix}_{entity_plural}` (e.g., `std_students`)
- Junction: `{prefix}_{entity1}_{entity2}_jnt` (e.g., `std_student_guardian_jnt`)
- Foreign keys: `{entity_singular}_id` (e.g., `student_id`)
- Booleans: `is_` or `has_` prefix
- JSON fields: `_json` suffix
- Dates: `_date` suffix

**Data Types:**
- Primary keys: `INT UNSIGNED AUTO_INCREMENT`
- Foreign keys: `INT UNSIGNED`
- Booleans: `TINYINT(1)`
- Money: `DECIMAL(12,2)`
- Enums: `ENUM()` for fixed sets
- Structured data: `JSON`

> **Authoritative Schema Reference:** Only use the consolidated DDL files at:
> `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDLs/`
> - `global_db.sql` (12 tables)
> - `prime_db.sql` (27 tables)
> - `tenant_db.sql` (368 tables, 10,297 lines)
