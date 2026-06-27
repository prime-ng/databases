# Database Schema Reference

> **Last Updated:** 2026-06-27
> **Source:** v4 DEV DDL files in `{OLD_REPO}/0-DDL_Masters/` are authoritative for all AI work

## CANONICAL DDL FILE PATHS

### Development Schema (v4 — use these for all AI analysis and schema work)

| Database | File | Purpose |
|----------|------|---------|
| `global_db` | `{DEV_GLOBAL_DDL}` | Shared reference data |
| `prime_db` | `{DEV_PRIME_DDL}` | Prime team / SaaS management |
| `tenant_db` | `{DEV_TENANT_DDL}` | Common tenant schema + global_db copies (dev) |
| Per-module DDLs | `{DEV_MODULE_DDL_DIR}/{MODULE_NAME}_DDL*.sql` | Module-specific tenant tables |

### Production Schema (v3 — in `{DB_REPO}`, used by Laravel app)
| Database | File |
|----------|------|
| `global_db` | `{GLOBAL_DDL}` |
| `prime_db` | `{PRIME_DDL}` |
| `tenant_db` | `{TENANT_DDL}` |

> **CRITICAL WARNING:** For AI work always use v4 DEV files above. Production v3 files are for reference only.
> - Do NOT use files from `0-DDL_Masters_Old/`, `2-DDL_Tenant_Old/`, `2-DDL_Tenant_Enhanced/`, or any `*_Old*` subfolder
> - Do NOT use non-v4 versions of master DDL files

## Module → Database Assignment

| Module(s) | Database | File |
|-----------|----------|------|
| Billing, Prime, SystemConfig | `prime_db` | `{DEV_PRIME_DDL}` |
| GlobalMaster | `global_db` | `{DEV_GLOBAL_DDL}` |
| All other tenant modules | `tenant_db` + per-module DDL | `{DEV_TENANT_DDL}` + `{DEV_MODULE_DDL_DIR}/{MODULE_NAME}_DDL*.sql` |

## Dev vs Production — tenant_db Architecture

In **Dev environment**: `tenant_db` contains a **full copy** of `global_db` table schemas (for ease of independent development and enhancement).

In **Production**: `tenant_db` will have **Views** into `global_db` tables so that reference data is controlled from one place but accessible to all tenants.

> This means: in dev, `global_db` tables (`glb_countries`, `glb_boards`, etc.) appear directly in `tenant_db`. Do not treat this as the production design.

---

## Database Overview

| Layer | Database | Tables | Purpose |
|-------|----------|--------|---------|
| Global | `global_db` | 12 | Shared reference data: countries, states, boards, languages, menus, modules |
| Prime | `prime_db` | 27 | Central SaaS: tenants, plans, billing, central users, roles |
| Tenant | `tenant_{uuid}` | 370 | Per-school isolated data: all school operations |
| **Total** | — | **409** | — |

### prime_db also has VIEWS into global_db
```sql
CREATE VIEW glb_countries AS SELECT * FROM global_master.glb_countries;
CREATE VIEW glb_states    AS SELECT * FROM global_master.glb_states;
-- ... and so on for all glb_* tables
```

---

## Table Prefix Guide

> **Source of truth:** DDL v4 files in `{DEV_MODULE_DDL_DIR}/`. All prefixes verified against actual DDL.

| Prefix | Module | Code | Database |
|--------|--------|------|----------|
| `glb_` | GlobalMaster | GLB | global_db |
| `prm_` | Prime | PRM | prime_db |
| `bil_` | Billing | BIL | prime_db |
| `sys_` | SystemConfig / RBAC | SYS | prime_db + tenant_db |
| `sch_` | SchoolSetup (ClassSetup, CoreSetup, EmployeeSetup, InfraSetup) | SCC/SCO/SCE/SCI | tenant_db |
| `ptm_` | PTM (Parent-Teacher Meeting) | PTM | tenant_db |
| `cht_` | CommonChat | COM | tenant_db |
| `tt_` | SmartTimetable | STT | tenant_db |
| `ttf_` | TimetableFoundation | TTF | tenant_db |
| `tts_` | StandardTimetable | TTS | tenant_db |
| `std_` | StudentProfile | STD | tenant_db |
| `adm_` | Admission Mgmt. | ADM | tenant_db |
| `slb_` | Syllabus + SyllabusBooks | SLB / SLK | tenant_db |
| `qns_` | QuestionBank | QNS | tenant_db |
| `tpt_` | Transport | TPT | tenant_db |
| `vnd_` | Vendor | VND | tenant_db |
| `cmp_` | Complaint | CMP | tenant_db |
| `rec_` | Recommendation | REC | tenant_db |
| `ntf_` | Notification | NTF | tenant_db |
| `fee_` | StudentFee | FIN | tenant_db |
| `pmt_` | Payment | PAY | tenant_db |
| `hpc_` | Hpc | HPC | tenant_db |
| `lms_` | LmsExam / LmsQuiz / LmsHomework / LmsQuests | EXM/QUZ/HMW/QST | tenant_db |
| `msh_` | MarksheetGeneration | MSH | tenant_db |
| `doc_` | Documentation | DOC | tenant_db |
| `lib_` | Library | LIB | tenant_db |
| `acc_` | Accounting | ACC | tenant_db |
| `prl_` | Payroll (planned) | — | tenant_db |
| `inv_` | Inventory | INV | tenant_db |
| `bha_` | BehaviouralAssessment | BHA | tenant_db |
| `hst_` | Hostel | HST | tenant_db |
| `fbk_` | Feedback | FBK | tenant_db |
| `ppt_` | ParentPortal | PPT | tenant_db |
| `stp_` | StudentPortal | STP | tenant_db |
| `fof_` | FrontOffice | FOF | tenant_db |
| `caf_` | Cafeteria | CAF | tenant_db |
| `crt_` | Certificate | CRT | tenant_db |
| `hrs_` | HrStaff | HRS | tenant_db |
| `tmp_` | Template | TMP | tenant_db |
| `dsh_` | Dashboard | DSH | tenant_db |
| `mes_` | Mess (reserved) | — | tenant_db |

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

## Layer 3: tenant_db (370 Tables)

### System Module (sys_* — ~15 tables)
Mirrors prime_db sys_* tables for tenant-level RBAC. Includes 9 tenant roles.
Key tables: `sys_users`, `sys_roles`, `sys_permissions`, `sys_role_has_permissions_jnt`, `sys_model_has_roles_jnt`, `sys_model_has_permissions_jnt`, `sys_settings`, `sys_dropdown_table`, `sys_media`, `sys_activity_logs`

Also includes rule engine tables: `sys_rule_engine_config`, `sys_rule_engine_actions`, `sys_rule_engine_log`, `sys_trigger_event`, `sys_action_type`

### SchoolSetup (sch_* — ~33 tables)
`sch_organizations`, `sch_organization_groups`, `sch_org_academic_sessions_jnt`, `sch_board_organization_jnt`, `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, `sch_subject_groups`, `sch_subject_group_subject_jnt`, `sch_subject_teachers`, `sch_teachers`, `sch_teacher_profiles`, `sch_teacher_capabilities`, `sch_rooms`, `sch_rooms_type`, `sch_buildings`, `sch_employees`, `sch_employee_profiles`, `sch_departments`, `sch_designations`, `sch_leave_types`, `sch_leave_configs`, `sch_categories`, `sch_attendance_types`, `sch_study_formats`, `sch_subject_study_format_jnt`, `sch_entity_groups`, `sch_entity_group_members`, `sch_disable_reasons`, `sch_class_groups_jnt`

**Employee Leave Management (8 new tables — DDL v2, 2026-04-08, code not yet implemented):**
`sch_leave_approval_policies`, `sch_leave_approval_policy_levels`, `sch_leave_approval_level_approvers`, `sch_employee_leave_applications`, `sch_employee_leave_approvals`, `sch_employee_leave_application_docs`, `sch_employee_leave_application_remarks`, `sch_employee_leave_balance`
> DDL source: `1-DDL_Tenant_Modules/12-SchoolSetup/DDL/Employee_setup_ddl_v2.sql`
> Balance quota source: `sch_leave_config` (existing) drives `sch_employee_leave_balance.opening_balance` at year-start.

**Employee Setup DDL v4 (2026-05-04, D33) — `Employee_setup_ddl_v4.sql`:** 25 tables total (was 13 in v3). Fixed 3 CREATE-time bugs and added 12 new HR tables:
- Personal: `sch_employee_addresses`, `sch_employee_emergency_contacts`, `sch_employee_bank_details`
- Documents: `sch_employee_documents`
- Lifecycle: `sch_employee_role_history` (promotion/transfer audit), `sch_employee_separations` (resignation workflow)
- Leave masters: `sch_leave_types` (closed dangling FK from 4 tables), `sch_leave_config` (per-(role × leave_type) entitlement / accrual)
- Holidays + Shifts: `sch_holidays`, `sch_employee_shifts`, `sch_employee_shift_assignments`
- Attendance: `sch_employee_attendance_punches` (raw biometric/mobile), `sch_employee_attendance_corrections` (correction workflow)
> DDL source: `1-DDL_Tenant_Modules/2-SchoolSetup/DDL/Employee_setup_ddl_v4.sql`
> Strictly additive over v3 — no renames or type changes. Renames (sch_employees_profile → plural, etc.) deferred to v5.

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

### Accounting (acc_* — 28 tables, DDL v3 — seeded 2026-06-27)
> Old module code: `FAC` (V1 used `fac_*` prefix; V2 req file still named `FAC_FinanceAccounting_Requirement.md`). Module now unified as `ACC` with `acc_*` prefix.
> DDL source: `{DEV_MODULE_DDL_DIR}/Accounting_DDL_v3.sql`

| Domain | Tables (count) | Purpose |
|--------|----------------|---------|
| D0 — Infrastructure | 3 | `acc_accounting_status_masters`, `acc_voucher_modules`, `acc_voucher_category` — status master pattern (avoids ENUM changes) + module registry |
| D1 — Core Accounting | 12 | `acc_financial_years`, `acc_account_groups`, `acc_ledgers`, `acc_voucher_types`, `acc_vouchers`, `acc_voucher_items`, `acc_cost_centers`, `acc_budgets`, `acc_tax_rates`, `acc_ledger_mappings`, `acc_recurring_templates`, `acc_recurring_template_lines` |
| D2 — Banking | 2 | `acc_bank_reconciliations`, `acc_bank_statement_entries` |
| D3 — Fixed Assets | 3 | `acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries` |
| D4 — Expense Claims | 2 | `acc_expense_claims`, `acc_expense_claim_lines` |
| D5 — Tally Integration | 2 | `acc_tally_export_logs`, `acc_tally_ledger_mappings` |
| D6 — Generic Event Engine | 4 | `acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log` — **NOT in V2 req**; runtime ledger resolution + full retry audit |

> Schema gaps vs V2 req: `acc_gst_details`, `acc_tds_entries`, `acc_year_end_closings` proposed in V2 req but NOT in DDL v3.
> See `AI_Brain/module-knowledge/ACC_Accounting.md` for full knowledge including architecture decisions and gaps.

### Template (tmp_* — 3 tables, DDL v1 — 2026-04-16)
`tmp_templates` (existing — visual template builder, canvas/HTML), `tmp_template_purposes` (output purpose registry — Marksheet Print, Student ID Card, Staff ID Card, etc.), `tmp_template_assignments` (scope-based template-to-purpose assignment per session — class, class-group, or school-wide)

> DDL source: `1-DDL_Tenant_Modules/Template/Template_Config_DDL_v1.sql`
> Cross-module FK: `tmp_template_assignments.class_group_id` → `msh_class_groups.id` (Decision D-TMP-001)
> Scope uniqueness enforced via generated `scope_hash` column (Decision D-TMP-003)
> `tmp_templates` migration DOES NOT EXIST yet — only `.gitkeep` in `Modules/Template/database/migrations/`
> `tmp_templates.created_by` is BIGINT UNSIGNED but `sys_users.id` is INT UNSIGNED — type mismatch to fix

### Admission Mgmt. (adm_* — 20 tables, DDL v1 — documented 2026-06-27)
> DDL source: `{DEV_MODULE_DDL_DIR}/Admission_DDL_v1.sql`
> Req source: `{REQUIREMENT_OLD}/ADM_Admission_Requirement.md` (consolidated V2)
> Code: ~60–65% complete. All 18 controllers, 20 models, 6 services, 24 FormRequests, 13 policies, 84 views present. 0 tests. PromoteExpiredOffersJob missing. 0 migrations.

| Layer | Tables (count) | Key Tables |
|-------|----------------|------------|
| L1 — Cycle foundation | 1 | `adm_admission_cycles` |
| L2 — Cycle config | 4 | `adm_document_checklist`, `adm_quota_config`, `adm_seat_capacity`, `adm_entrance_tests` |
| L3 — Lead / enquiry | 2 | `adm_enquiries`, `adm_merit_lists` |
| L4 — Application | 2 | `adm_follow_ups`, `adm_applications` |
| L5 — Application detail | 4 | `adm_application_documents`, `adm_application_stages`, `adm_entrance_test_candidates`, `adm_merit_list_entries` |
| L6 — Allotment | 2 | `adm_allotments`, `adm_promotion_batches` |
| L7 — Post-allotment | 2 | `adm_withdrawals`, `adm_promotion_records` |
| L8 — TC / Incident | 2 | `adm_transfer_certificates`, `adm_behavior_incidents` |
| L9 — Incident action | 1 | `adm_behavior_actions` |

> 5 DDL deviations vs V2 req documented: aadhar_no is non-unique index (service-layer check only); created_by/updated_by are NOT NULL; adm_merit_lists has extra sibling_bonus_score + cutoff_score; adm_document_checklist.admission_cycle_id nullable (for system templates); FK type INT vs BIGINT UNSIGNED for sys_users references.
> Key FSMs: Application (Draft→Submitted→Verified→Shortlisted→Allotted/Waitlisted→Enrolled→Withdrawn), Allotment Offer (Offered→Accepted/Declined/Expired), Enquiry Lead (New→Contacted→Converted/Not_Interested).
> Critical integration: `EnrollmentService::enrollStudent()` does cross-module writes (sys_users + std_students + std_student_academic_sessions) in a single DB::transaction().
> See `AI_Brain/module-knowledge/ADM_Admission.md` for full knowledge including FSMs, business rules, and DDL deviations.

### BehaviouralAssessment (bha_* — 16 tables, DDL v2 — seeded 2026-06-27)
> DDL source: `{DEV_MODULE_DDL_DIR}/BehaviouralAssess_DDL_v2.sql` (very well-documented with per-table comments)
> Req source: 24 screen files in `{REQUIRE_DETAIL_V1}/BehaviouralAssessment_v2/` — no consolidated V2 req file.

| Layer | Tables (count) | Purpose |
|-------|----------------|---------|
| L1 — Foundation | 3 | `bha_rating_scales`, `bha_categories` (polarity: positive/negative), `bha_interventions` |
| L2 — Detail | 2 | `bha_rating_levels`, `bha_criteria` (58 seeded across 9 categories) |
| L3 — Configuration | 3 | `bha_class_category_jnt`, `bha_assessment_periods`, `bha_config` |
| L4 — Transaction Headers | 2 | `bha_assessments`, `bha_audit_log` (**immutable** — no updated_at/deleted_at; CBSE/ICSE CCE compliance) |
| L5 — Core Transaction | 4 | `bha_assessment_ratings` (core fact), `bha_student_remarks`, `bha_computed_scores` (materialised cache), `bha_incidents` |
| L6 — Junctions | 2 | `bha_incident_witnesses_jnt`, `bha_incident_intervention_jnt` |

> Key design: negative polarity inversion at service layer; pull-based result integration via `BehaviouralScoreService::getBulkScores()`.
> See `AI_Brain/module-knowledge/BHA_BehaviouralAssessment.md` for full knowledge including FSMs and seeded data.

### MarksheetGeneration (msh_* — 23 tables, DDL v1 — 2026-04-13)
`msh_marksheet_types`, `msh_source_components`, `msh_ia_component_types`, `msh_class_groups`, `msh_class_group_items_jnt`, `msh_exam_groups`, `msh_exam_group_items_jnt`, `msh_config_templates`, `msh_template_scholastic_components`, `msh_template_exam_weightages`, `msh_template_ia_components`, `msh_template_coscholastic_components`, `msh_class_config_jnt`, `msh_subject_practical_configs`, `msh_marksheet_schedules`, `msh_schedule_class_jnt`, `msh_student_results`, `msh_student_subject_results`, `msh_student_subject_exam_marks`, `msh_student_ia_marks`, `msh_student_coscholastic_results`, `msh_student_attendance`, `msh_computation_logs`

> DDL source: `1-DDL_Tenant_Modules/LMS_MarksheetGeneration/DDL/MSG_DDL_v1.sql`
> Data dictionary: `1-DDL_Tenant_Modules/LMS_MarksheetGeneration/MSG_DataDictionary.md`
> Cross-module FK to `msh_class_groups` is reused by Template module (D-TMP-001)

### Hostel (hst_* — 36 tables, DDL v3 — 2026-05-04, code pending)
21-table v2 augmented to 36 tables in v3 (D34). Convention fix: `created_by`/`updated_by` added on every v2 table (was systematically missing). 15 new tables across 10 domains:

**Warden / Duty:** `hst_warden_duty_roster` (daily on-duty, distinct from role-level posting)
**Maintenance:** `hst_bed_maintenance_log`, `hst_housekeeping_log`
**Laundry:** `hst_laundry_tickets`
**Mess:** `hst_mess_opt_outs`, `hst_mess_bills`
**Fee:** `hst_fee_demands` (local audit of fin_* charges)
**Discipline masters:** `hst_incident_types` (closes free-text VARCHAR), `hst_incident_warnings` (letter audit)
**Reservation:** `hst_room_reservations` (pre-allotment, supports prospective_name when std_students record doesn't yet exist)
**Emergency:** `hst_emergency_contacts` (hostel-level: doctor / ambulance / hospital / police / vendors)
**Security:** `hst_visitor_media` (multi-photo per visit)
**Sick bay:** `hst_sick_bay_vitals`, `hst_sick_bay_medications`
**Cross-cutting:** `hst_audit_log`, `hst_notification_log`

> DDL source: `1-DDL_Tenant_Modules/Hostel/DDL/HST_DDL_v3.sql` (v2 superseded but available for diff)
> Strictly additive — every v2 column / constraint / index preserved.
> 14 field additions on v2 tables, all nullable. Notable: `hst_incidents.incident_type_id` FK (old VARCHAR retained for back-compat).
> Deferred to v4: drop `hst_incidents.incident_type` VARCHAR; normalize `facilities_json`/`amenities_json` to master + junction; visitor blacklist; partition audit_log + notification_log by month.

---

### Feedback (fbk_* — 11 tables, DDL v2 — 2026-04-09, code pending)
Generic cross-entity feedback module supporting Student/Parent → Teacher (and any other staff), NEP 2020 Teacher → Student, NEP 2020 Student → Peer Student, Admin → Teacher, Teacher 360°, and Self-Reflection.

**Reference masters (3):** `fbk_target_types`, `fbk_relationship_types`, `fbk_categories`
**Templates (2):** `fbk_templates`, `fbk_questions`
**Cycles (3):** `fbk_cycles`, `fbk_cycle_feedback_types`, `fbk_cycle_targets`
**Transactional (3):** `fbk_responses`, `fbk_answers`, `fbk_summary`

> DDL source: `1-DDL_Tenant_Modules/39-Feedback/StudentFeedback_ddl_v2.sql` (v1 superseded)
> Polymorphic target via 4 nullable FKs (user/student/employee/department) + 7 generated `_uq` COALESCE columns for dedup.
> Peer feedback has forced anonymity (hardcoded rules R7-R8); k-anonymity enforced via `min_responses_for_visibility` (default 3).

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
- Enums: **AVOID** — use FK to `sys_dropdown_table` (key = `{table}.{column}`) for any semi-open list. ENUM allowed only when the option set is immutably code-gated (see D29). For binary flags prefer `TINYINT(1)` over a 2-row dropdown.
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
