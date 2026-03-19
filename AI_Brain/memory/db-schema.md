# Database Schema Reference

> **Last Updated:** 2026-03-12
> **Source:** Consolidated DDL files (v2 versions are authoritative)

## CANONICAL DDL FILE PATHS

| Database | File | Tables |
|----------|------|--------|
| `global_db` | `{GLOBAL_DDL}` | 12 |
| `prime_db` | `{PRIME_DDL}` | 27 |
| `tenant_db` | `{TENANT_DDL}` | 368 |

> **CRITICAL WARNING:** NEVER reference old DDL files from any other location:
> - Do NOT use files in `2-Prime_Modules/`, `2-Tenant_Modules/`, `0-Policies/`, `Working/`, or any other subfolder
> - Do NOT use the original `global_db.sql`, `prime_db.sql`, or `tenant_db.sql` (non-v2 versions)
> - The only authoritative schema source is the 3 v2 files listed above

---

## Database Overview

| Layer | Database | Tables | Purpose |
|-------|----------|--------|---------|
| Global | `global_db` | 12 | Shared reference data: countries, states, boards, languages, menus, modules |
| Prime | `prime_db` | 27 | Central SaaS: tenants, plans, billing, central users, roles |
| Tenant | `tenant_{uuid}` | 368 | Per-school isolated data: all school operations |
| **Total** | — | **407** | — |

### prime_db also has VIEWS into global_db
```sql
CREATE VIEW glb_countries AS SELECT * FROM global_master.glb_countries;
CREATE VIEW glb_states    AS SELECT * FROM global_master.glb_states;
-- ... and so on for all glb_* tables
```

---

## Table Prefix Guide

| Prefix | Count | Module | Database |
|--------|-------|--------|----------|
| `glb_` | 12 | GlobalMaster | global_db |
| `prm_` | ~8 | Prime | prime_db |
| `bil_` | ~5 | Billing | prime_db |
| `sys_` | ~12 | System Config / RBAC | prime_db + tenant_db |
| `sch_` | ~25 | SchoolSetup | tenant_db |
| `tt_` | ~45 | SmartTimetable | tenant_db |
| `std_` | ~14 | StudentProfile | tenant_db |
| `slb_` | ~17 | Syllabus | tenant_db |
| `qns_` | ~8 | QuestionBank | tenant_db |
| `bok_` | ~8 | SyllabusBooks | tenant_db |
| `tpt_` | ~35 | Transport | tenant_db |
| `vnd_` | ~7 | Vendor | tenant_db |
| `cmp_` | ~6 | Complaint | tenant_db |
| `rec_` | ~10 | Recommendation | tenant_db |
| `ntf_` | ~13 | Notification | tenant_db |
| `fin_` | ~21 | StudentFee | tenant_db |
| `pmt_` | ~5 | Payment | tenant_db |
| `hpc_` | ~12 | HPC | tenant_db |
| `lms_` | ~26 | LMS (Exam/Quiz/Homework/Quests) | tenant_db |
| `doc_` | ~3 | Documentation | tenant_db |
| `lib_` | ~20 | Library (pending) | tenant_db |
| `acc_` | ~25 | Accounting (reserved) | tenant_db |
| `beh_` | — | Behaviour (reserved) | tenant_db |
| `hos_` | — | Hostel (reserved) | tenant_db |
| `mes_` | — | Mess (reserved) | tenant_db |

---

## Layer 1: global_db (12 Tables)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `glb_countries` | Country master | id, name, short_name, global_code, currency_code, is_active |
| `glb_states` | State master | id, country_id (FK), name, short_name, is_active |
| `glb_districts` | District master | id, state_id (FK), name, is_active |
| `glb_cities` | City master | id, district_id (FK), name, default_timezone, is_active |
| `glb_boards` | Educational boards (CBSE, ICSE, etc.) | id, name, code, description, is_active |
| `glb_languages` | Language master | id, name, code, is_active |
| `glb_academic_sessions` | Academic year sessions | id, short_name, name, start_date, end_date, is_current, current_flag (GENERATED) |
| `glb_menus` | Navigation menus | id, name, url, icon, parent_id, sort_order |
| `glb_modules` | Platform modules | id, name, code, description, is_sub_module, parent_id, is_active |
| `glb_menu_model_jnt` | Menu-module junction | id, menu_id (FK), module_id (FK) |
| `glb_translations` | Multi-language translations | id, key, language_id, value |
| `glb_activity_logs` | Global activity logs | id, user_id, subject_type, subject_id, event, properties, ip_address |

---

## Layer 2: prime_db (27 Tables)

### Tenant Management
| Table | Purpose |
|-------|---------|
| `prm_tenant` | Tenant master (UUID PK) — name, email, phone, data(json), is_active, soft_deletes |
| `prm_tenant_domains` | Domain → tenant mapping |
| `prm_tenant_groups` | Tenant grouping |

### Plans & Billing
| Table | Purpose |
|-------|---------|
| `prm_plans` | Subscription plans with billing cycle |
| `prm_tenant_plan_jnt` | Tenant-plan assignment with start/end dates |
| `prm_tenant_plan_rates` | Plan rate details |
| `prm_tenant_plan_module_jnt` | Which modules are in a plan |
| `prm_tenant_plan_billing_schedule` | Billing schedules per plan |
| `prm_billing_cycles` | Billing cycle definitions (monthly, quarterly, annual) |

### Invoicing
| Table | Purpose |
|-------|---------|
| `bil_tenant_invoices` | Generated invoices — invoice_no, amount, status, due_date |
| `bil_tenant_invoicing_modules_jnt` | Invoice module-level breakdown |
| `bil_tenant_invoicing_payments` | Payment records — amount, payment_method, transaction_id |
| `bil_tenant_invoicing_audit_logs` | Audit trail for invoice actions |
| `bil_tenant_email_schedules` | Scheduled email dispatch tracking |

### System (prime_db)
| Table | Purpose |
|-------|---------|
| `sys_users` | Central users — emp_code, name, user_type, email, is_super_admin, super_admin_flag (GENERATED) |
| `sys_roles` | Role definitions — name, guard_name, is_system |
| `sys_permissions` | Permission definitions — name, guard_name |
| `sys_role_has_permissions_jnt` | Role-permission mapping |
| `sys_model_has_permissions_jnt` | Direct user permissions (polymorphic) |
| `sys_model_has_roles_jnt` | User-role assignment (polymorphic) |
| `sys_settings` | System settings — key, value, type, group |
| `sys_dropdown_needs` | Dropdown configuration |
| `sys_dropdown_table` | Dropdown values — label, value, sort_order |
| `sys_dropdown_need_table_jnt` | Dropdown-table mapping |
| `sys_media` | Media library (Spatie) |
| `sys_activity_logs` | Activity audit trail |

---

## Layer 3: tenant_db (368 Tables)

### System Module (sys_* — ~15 tables)
Mirrors prime_db sys_* tables for tenant-level RBAC. Includes 9 tenant roles.
Key tables: `sys_users`, `sys_roles`, `sys_permissions`, `sys_role_has_permissions_jnt`, `sys_model_has_roles_jnt`, `sys_model_has_permissions_jnt`, `sys_settings`, `sys_dropdown_table`, `sys_media`, `sys_activity_logs`

Also includes rule engine tables: `sys_rule_engine_config`, `sys_rule_engine_actions`, `sys_rule_engine_log`, `sys_trigger_event`, `sys_action_type`

### SchoolSetup (sch_* — ~25 tables)
`sch_organizations`, `sch_organization_groups`, `sch_org_academic_sessions_jnt`, `sch_board_organization_jnt`, `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, `sch_subject_groups`, `sch_subject_group_subject_jnt`, `sch_subject_teachers`, `sch_teachers`, `sch_teacher_profiles`, `sch_teacher_capabilities`, `sch_rooms`, `sch_rooms_type`, `sch_buildings`, `sch_employees`, `sch_employee_profiles`, `sch_departments`, `sch_designations`, `sch_leave_types`, `sch_leave_configs`, `sch_study_formats`, `sch_subject_study_format_jnt`, `sch_entity_groups`, `sch_entity_group_members`, `sch_disable_reasons`, `sch_class_groups_jnt`

### SmartTimetable (tt_* — ~45 tables)
Core: `tt_timetables`, `tt_timetable_cells`, `tt_timetable_cell_teachers`, `tt_activities`, `tt_sub_activities`, `tt_activity_teachers`, `tt_activity_priority`

Time/Periods: `tt_academic_terms`, `tt_timetable_types`, `tt_period_sets`, `tt_period_set_periods`, `tt_period_types`, `tt_school_days`, `tt_day_types`, `tt_working_day`, `tt_class_working_day`, `tt_class_timetable_type`

Constraints: `tt_constraints`, `tt_constraint_types`, `tt_constraint_categories`, `tt_constraint_category_scopes`, `tt_constraint_scopes`, `tt_constraint_target_types`, `tt_constraint_groups`, `tt_constraint_group_members`, `tt_constraint_templates`, `tt_constraint_violations`

Availability: `tt_teacher_availabilities`, `tt_teacher_availability_logs`, `tt_teacher_unavailable`, `tt_teacher_absences`, `tt_teacher_workloads`, `tt_room_availabilities`, `tt_room_unavailable`, `tt_room_utilization`

Generation: `tt_generation_runs`, `tt_generation_queues`, `tt_optimization_runs`, `tt_conflict_detections`, `tt_substitution_logs`, `tt_ml_models`, `tt_training_data`, `tt_approval_workflows`, `tt_approval_requests`, `tt_change_logs`, `tt_config`, `tt_slot_requirements`, `tt_batch_operations`, `tt_requirement_consolidation`, `tt_teacher_assignment`, `tt_parallel_group`, `tt_parallel_group_activity`

### Student (std_* — ~14 tables)
`std_students`, `std_student_details`, `std_student_profiles`, `std_student_academic_sessions`, `std_student_addresses`, `std_attendance_details`, `std_attendance_corrections`, `std_student_documents`, `std_student_health_profiles`, `std_vaccination_records`, `std_medical_incidents`, `std_guardians`, `std_student_guardian_jnt`, `std_previous_educations`

### Syllabus (slb_* — ~17 tables)
`slb_lessons`, `slb_topics`, `slb_competencies`, `slb_competency_types`, `slb_topic_competencies`, `slb_topic_dependencies`, `slb_topic_level_types`, `slb_bloom_taxonomy`, `slb_cognitive_skills`, `slb_complexity_levels`, `slb_performance_categories`, `slb_grade_division_masters`, `slb_study_materials`, `slb_study_material_types`, `slb_question_types`, `slb_que_type_specifity`, `slb_syllabus_schedules`, `slb_books`, `slb_book_authors`, `slb_book_author_jnt`, `slb_book_chapter_section_jnt`

### QuestionBank (qns_* — ~8 tables)
`qns_questions`, `qns_question_options`, `qns_question_question_tag_jnt`, `qns_question_topics_jnt`, `qns_question_performance_category_jnt`, `qns_question_review_log`, `qns_question_usage_jnt`, `qns_question_usage_type`, `qns_media_store`

### Transport (tpt_* — ~35 tables)
`tpt_vehicle`, `tpt_route`, `tpt_shifts`, `tpt_pickup_points`, `tpt_driver_helper`, `tpt_driver_route_vehicle_jnt`, `tpt_trips`, `tpt_live_trips`, `tpt_trip_incidents`, `tpt_gps_alerts`, `tpt_gps_trip_log`, `tpt_student_boarding_logs`, `tpt_student_allocation_jnt`, `tpt_driver_attendance`, `tpt_daily_vehicle_inspections`, `tpt_vehicle_maintenance`, `tpt_vehicle_service_requests`, `tpt_vehicle_fuel`, `tpt_fee_master`, `tpt_fee_collection`, `tpt_fine_master`, `tpt_student_fine_details`, `tpt_attendance_devices`, `tpt_feature_store`, `tpt_ml_models`, `tpt_notification_log`, `tpt_recommendation_history`, `tpt_student_event_log`, `tpt_route_scheduler_jnt`

### Vendor (vnd_* — ~7 tables)
`vnd_vendors`, `vnd_agreements`, `vnd_agreement_items_jnt`, `vnd_vendor_invoices`, `vnd_vendor_invoice_payments`, `vnd_vendor_usage_logs`, `vnd_vendor_dashboard`

### Complaint (cmp_* — ~6 tables)
`cmp_complaint_categories`, `cmp_complaints`, `cmp_complaint_actions`, `cmp_sla_config`, `cmp_medical_checks`, `cmp_ai_insights`

### Recommendation (rec_* — ~10 tables)
`rec_rules`, `rec_materials`, `rec_material_bundles`, `rec_bundle_material_jnt`, `rec_performance_snapshots`, `rec_dynamic_material_types`, `rec_dynamic_purposes`, `rec_assessment_types`, `rec_trigger_events`, `rec_recommendation_modes`, `rec_student_recommendations`

### Notification (ntf_* — ~13 tables)
`ntf_notifications`, `ntf_notification_templates`, `ntf_notification_channels`, `ntf_channel_masters`, `ntf_provider_masters`, `ntf_notification_targets`, `ntf_target_groups`, `ntf_notification_delivery_logs`, `ntf_device_tokens`, `ntf_user_preferences`, `ntf_notification_threads`, `ntf_resolved_recipients`, `ntf_delivery_queues`, `ntf_notification_recipients`

### Finance/Fees (fin_* — ~21 tables)
`fin_fee_structure_masters`, `fin_fee_structure_details`, `fin_fee_head_masters`, `fin_fee_group_masters`, `fin_fee_group_heads_jnt`, `fin_fee_installments`, `fin_fee_student_assignments`, `fin_fee_student_concessions`, `fin_fee_concession_types`, `fin_fee_invoices`, `fin_fee_receipts`, `fin_fee_transactions`, `fin_fee_transaction_details`, `fin_fee_fine_rules`, `fin_fee_fine_transactions`, `fin_fee_payment_gateway_logs`, `fin_fee_scholarships`, `fin_fee_scholarship_applications`, `fin_fee_scholarship_approval_history`, `fin_fee_name_removal_logs`, `fee_concession_applicable_heads`

### Payment Gateway (pmt_* — ~5 tables)
`pmt_payments`, `pmt_payment_gateways`, `pmt_payment_histories`, `pmt_payment_refunds`, `pmt_payment_webhooks`

### HPC (hpc_* — ~26 tables)
`hpc_learning_outcomes`, `hpc_student_evaluations`, `hpc_student_snapshots`, `hpc_learning_activities`, `hpc_learning_activity_type`, `hpc_levels`, `hpc_parameters`, `hpc_performance_descriptors`, `hpc_circular_goals`, `hpc_circular_goal_competency_jnt`, `hpc_outcome_entity_jnt`, `hpc_outcome_question_jnt`, `hpc_knowledge_graph_validations`, `hpc_topic_equivalencies`, `hpc_syllabus_coverage_snapshots`, `hpc_reports`

#### HPC Schema Gap (identified 2026-03-16)
- Schema-1 (Template + Report): 11 tables — all have migrations
- Schema-2 (NEP 2020 / PARAKH): 15 tables — models exist but NO migration files
  - Missing: hpc_circular_goals, hpc_circular_goal_competency_jnt, hpc_learning_outcomes,
    hpc_outcome_entity_jnt, hpc_outcome_question_jnt, hpc_knowledge_graph_validation,
    hpc_topic_equivalency, hpc_syllabus_coverage_snapshot, hpc_ability_parameters,
    hpc_performance_descriptors, hpc_student_evaluation, hpc_learning_activities,
    hpc_learning_activity_type, hpc_student_hpc_snapshot, hpc_hpc_levels
- These tables likely exist in the DB (created via raw SQL or seeder) but lack versioned migrations
- **Action needed:** Create 15 additive migration files before next deployment

### LMS (lms_* — ~26 tables)
Exam: `lms_exams`, `lms_exam_types`, `lms_exam_blueprints`, `lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_questions`, `lms_exam_student_groups`, `lms_exam_scopes`, `lms_exam_allocations`, `lms_assessment_types`, `lms_student_attempts`, `lms_exam_results`, `lms_exam_grievances`

Quiz: `lms_quizzes`, `lms_quiz_questions`, `lms_quiz_allocations`, `lms_quiz_difficulty_distributions`

Homework: `lms_homework`, `lms_homework_submissions`, `lms_homework_action_types`

Quests: `lms_quests`, `lms_quest_questions`, `lms_quest_allocations`, `lms_quest_scopes`

### Documentation (doc_* — ~3 tables)
`doc_articles`, `doc_categories`, `doc_article_media`

### Library (lib_* — ~20 tables, pending)
`lib_membership_types`, `lib_categories`, `lib_genres`, `lib_books`, `lib_book_copies`, `lib_members`, `lib_transactions`, `lib_fines`, `lib_reservations`, `lib_digital_resources`, `lib_inventory_audit`, and more

### Accounting (acc_* — ~25 tables, reserved)
`acc_account_groups`, `acc_ledgers`, `acc_fiscal_years`, `acc_journals`, `acc_journal_entries`, and more

---

## Common Schema Patterns

### Standard Columns (ALL tables)
```sql
`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
`is_active` TINYINT(1) NOT NULL DEFAULT 1,
`created_by` INT UNSIGNED DEFAULT NULL,
`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
`deleted_at` TIMESTAMP NULL DEFAULT NULL,
PRIMARY KEY (`id`)
```

### Naming Conventions
- Tables: `{prefix}_{entity_plural}` → `std_students`
- Junction: `{prefix}_{entity1}_{entity2}_jnt` → `std_student_guardian_jnt`
- Foreign keys: `{entity_singular}_id` → `student_id`
- Booleans: `is_` or `has_` prefix
- JSON fields: `_json` suffix (e.g., `data_json`)
- Dates: `_date` suffix (e.g., `start_date`)

### Data Types
- Primary keys: `INT UNSIGNED AUTO_INCREMENT`
- Foreign keys: `INT UNSIGNED`
- Booleans: `TINYINT(1)`
- Money: `DECIMAL(12,2)`
- Enums: `ENUM()` for fixed sets
- Structured data: `JSON`
- Tenant PK: UUID (`VARCHAR(36)`) for `prm_tenant.id`

---

## CHANGELOG Summary (v1 → v2)

### global_db: 1 change
- Fixed backtick quoting in CHECK constraint on `glb_modules`

### prime_db: 20 changes
Key fixes: duplicate UNIQUE KEY name on sys_roles, duplicate is_active column in sys_users, trailing commas, trigger table names (`users` → `sys_users`), FK type mismatch on prm_tenant_domains, FK references from `sys_modules` → `glb_modules`, column renames in prm_tenant_plan_rates and billing tables

### tenant_db: 51 changes (v2) + 16 more in corrected version
Key fixes: typo in sch_class_section_jnt column name, trailing/missing commas, FK table references fixed across tpt_*, qns_*, slb_*, hpc_* tables, DEFAULT value fixes, INDEX column reference fixes, ENGINE clause additions, timetable module syntax fixes (semicolons → commas, AFTER clauses removed)

### Remaining Known Issues in v2 Files
**global_db_v2.sql:** GENERATED column uses backtick-quoted `\`1\`` (should be bare `1`)

**prime_db_v2.sql (5 errors):**
- `billing_cycle_id` SMALLINT vs SMALLINT UNSIGNED mismatch in `prm_plans`
- `-- Note:` comment inside CONSTRAINT lines swallows ON DELETE clauses (3 tables)
- Forward FK reference in `prm_tenant_plan_billing_schedule` → `bil_tenant_invoices`

**tenant_db_v2.sql:** Multiple errors remain in Vendor, Complaint, Timetable, HPC, LMS Exam, Library, and Accounting modules.
