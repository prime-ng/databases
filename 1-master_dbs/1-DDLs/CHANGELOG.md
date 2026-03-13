# DDL Schema Change Log

> **Date:** 2026-03-12
> **Purpose:** Document all changes made in v2/corrected versions of the 3 DDL files, plus remaining issues found during MySQL syntax validation.

---

## 1. global_db.sql → global_db_v2.sql

**Total Changes: 1**

### 1.1 Backtick-Quoted CHECK Constraint (Line 149)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 1 | 149 | `glb_modules` | Added backticks to CHECK constraint identifiers: `chk_isSubModule_parentId` — `is_sub_module`, `parent_id` now properly quoted | Syntax Fix |

**Before:**
```sql
CONSTRAINT chk_isSubModule_parentId CHECK ((is_sub_module = 1 AND parent_id IS NOT NULL) OR (is_sub_module = 0 AND parent_id IS NULL))
```
**After:**
```sql
CONSTRAINT `chk_isSubModule_parentId` CHECK ((`is_sub_module` = 1 AND `parent_id` IS NOT NULL) OR (`is_sub_module` = 0 AND `parent_id` IS NULL))
```

### Remaining Issues in global_db_v2.sql

| # | Line | Table | Issue | Severity |
|---|------|-------|-------|----------|
| 1 | 71 | `glb_academic_sessions` | GENERATED column uses backtick-quoted literal `` `1` `` instead of bare integer `1` — MySQL will interpret as column name | **ERROR** |

---

## 2. prime_db.sql → prime_db_v2.sql

**Total Changes: 20**

### 2.1 Duplicate Unique Key Name Fix (Lines 78-79)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 1 | 78-79 | `sys_roles` | Fixed duplicate UNIQUE KEY name `uq_roles_name_guardName` — second key renamed to `uq_roles_shortName_guardName`; added missing comma between the two keys | Duplicate Name + Missing Comma |

### 2.2 Removed Duplicate Column (Line 120)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 2 | 120 | `sys_users` | Removed duplicate `is_active` column definition | Duplicate Column |

### 2.3 Trailing Comma Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 3 | 135 | `sys_users` | Removed trailing comma after `uq_single_super_admin` (was last item before `)`) | Trailing Comma |
| 4 | 166 | `sys_settings` | Removed trailing comma after `uq_settings_key` | Trailing Comma |
| 5 | 425 | `prm_plans` | Removed trailing comma after last CONSTRAINT `fk_plans_billingCycleId` | Trailing Comma |
| 6 | 581 | `bil_tenant_invoices` | Removed trailing comma after last CONSTRAINT `fk_tenantInvoices_cycleId` | Trailing Comma |

### 2.4 Missing Comma Fix

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 7 | 219 | `sys_dropdown_table` | Added missing comma after `PRIMARY KEY (id)` before next UNIQUE KEY | Missing Comma |

### 2.5 Trigger Table Name Fixes (Lines 139-147)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 8 | 140 | Trigger `trg_users_prevent_delete_super` | Changed `BEFORE DELETE ON users` → `BEFORE DELETE ON \`sys_users\`` | Wrong Table Name |
| 9 | 147 | Trigger `trg_users_prevent_update_super` | Changed `BEFORE UPDATE ON users` → `BEFORE UPDATE ON \`sys_users\`` | Wrong Table Name |

### 2.6 Data Type Fix (Line 377)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 10 | 377 | `prm_tenant_domains` | Changed `tenant_id` from `INT NOT NULL` → `INT unsigned NOT NULL` (to match `prm_tenant.id` type) | FK Type Mismatch |

### 2.7 FK Table Reference Fixes (sys_modules → glb_modules)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 11 | 436 | `prm_module_plan_jnt` | Changed FK from `sys_modules` → `glb_modules` (with note about VIEW) | Wrong FK Table |
| 12 | 504 | `prm_tenant_plan_module_jnt` | Changed FK from `sys_modules` → `glb_modules` (with note about VIEW) | Wrong FK Table |
| 13 | 589 | `bil_tenant_invoicing_modules_jnt` | Changed FK from `sys_modules` → `glb_modules` (with note about VIEW) | Wrong FK Table |

### 2.8 Generated Column Fix (Line 455)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 14 | 455 | `prm_tenant_plan_jnt` | GENERATED column `current_flag` — changed reference from `org_id` → `tenant_id` (column was renamed) | Wrong Column Reference |

### 2.9 FK Column/Name Renames (Lines 492, 588-590)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 15 | 492 | `prm_tenant_plan_rates` | Renamed FK constraint `fk_tenantPlanRates_orgPlanId` → `fk_tenantPlanRates_tenantPlanId`; column `organization_plan_id` → `tenant_plan_id` | Rename |
| 16 | 588 | `bil_tenant_invoicing_modules_jnt` | Renamed UNIQUE KEY `uq_tenantInvModule_orgInvId_moduleId` → `uq_tenantInvModule_invId_moduleId`; fixed column ref `tenant_invoicing_id` → `tenant_invoice_id` | Rename |
| 17 | 589 | `bil_tenant_invoicing_modules_jnt` | Renamed FK `fk_tenantInvModule_invoicingId` → `fk_tenantInvModule_invoiceId`; fixed referenced table `bil_tenant_invoice` → `bil_tenant_invoices` | Wrong FK Table + Rename |

### 2.10 DEFAULT Value Fix (Line 517)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 18 | 517 | `prm_tenant_plan_billing_schedule` | Changed `DEFAULT \`0\`` (backtick-quoted) → `DEFAULT '0'` (string-quoted) | Invalid DEFAULT |

### 2.11 Column Type Order Fix (Line 603)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 19 | 603 | `bil_tenant_invoicing_payments` | Fixed `payment_status NOT NULL VARCHAR(20)` → `payment_status VARCHAR(20) NOT NULL` (type must come before NOT NULL) | Syntax Error |

### 2.12 Billing Audit Log Fixes (Lines 609-623)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 20a | 609 | `bil_tenant_invoicing_payments` | FK changed from `bil_tenant_invoicing` → `bil_tenant_invoices`; column `tenant_invoicing_id` → `tenant_invoice_id` | Wrong FK Table + Rename |
| 20b | 615 | `bil_tenant_invoicing_audit_logs` | Column renamed `tenant_invoicing_id` → `tenant_invoice_id` | Rename |
| 20c | 618 | `bil_tenant_invoicing_audit_logs` | Fixed typo in comment: `ation` → `action` | Typo |
| 20d | 622 | `bil_tenant_invoicing_audit_logs` | FK changed from `bil_tenant_invoicing` → `bil_tenant_invoices` | Wrong FK Table |
| 20e | 623 | `bil_tenant_invoicing_audit_logs` | FK changed from `users` → `sys_users` | Wrong FK Table |

### Remaining Issues in prime_db_v2.sql

| # | Line | Table | Issue | Severity |
|---|------|-------|-------|----------|
| 1 | 412 | `prm_plans` | `billing_cycle_id` is `SMALLINT NOT NULL` (signed) but FK target `prm_billing_cycles.id` is `SMALLINT UNSIGNED` — type mismatch | **ERROR** |
| 2 | 435 | `prm_module_plan_jnt` | `-- Note:` comment embedded in CONSTRAINT line swallows `ON DELETE CASCADE,` — parser will miss the comma and ON DELETE | **ERROR** |
| 3 | 503 | `prm_tenant_plan_module_jnt` | Same `-- Note:` comment issue — swallows `ON DELETE RESTRICT,` | **ERROR** |
| 4 | 524 | `prm_tenant_plan_billing_schedule` | Forward FK reference to `bil_tenant_invoices` which is created later in the file | **ERROR** |
| 5 | 589 | `bil_tenant_invoicing_modules_jnt` | `-- Note:` comment swallows `ON DELETE SET NULL` — silent behavior change | **WARNING** |

---

## 3. tenant_db.sql → tenant_db_v2.sql

**Total Changes: 42**

### 3.1 Typo/Spelling Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 1 | 706 | `sch_class_section_jnt` | Fixed typo `class_house_roome_id` → `class_house_room_id` in FK name and column | Typo |
| 2 | 4243 | `sch_class_section_jnt` (dup) | Same typo fix in duplicate table definition | Typo |

### 3.2 Trailing Comma Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 3 | 818 | `sch_class_groups_jnt` | Removed trailing space after comma on UNIQUE KEY line | Whitespace |
| 4 | 825 | `sch_class_groups_jnt` | Removed trailing comma after last CONSTRAINT | Trailing Comma |
| 5 | 1083 | `sch_teacher_profile` | Removed trailing comma after last CONSTRAINT | Trailing Comma |
| 6 | 1167 | `tpt_vehicle` | Removed trailing comma after last CONSTRAINT (also fixed table name) | Trailing Comma |
| 7 | 4358 | `sch_class_groups_jnt` (dup) | Same trailing space fix in duplicate table | Whitespace |
| 8 | 4365 | `sch_class_groups_jnt` (dup) | Same trailing comma fix in duplicate table | Trailing Comma |
| 9 | 4557 | `sch_teacher_profile` (dup) | Same trailing comma fix in duplicate table | Trailing Comma |

### 3.3 Missing Comma Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 10 | 5495 | `qns_question_usage_type` | Added missing comma after UNIQUE KEY before next field | Missing Comma |
| 11 | 6694 | `hpc_student_evaluation` | Added missing comma after UNIQUE KEY before CONSTRAINT | Missing Comma |
| 12 | 6903 | `lms_assessment_types` | Added missing comma after UNIQUE KEY before CONSTRAINT | Missing Comma |

### 3.4 FK Table Reference Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 13 | 1167 | `tpt_vehicle` | FK changed from `tpt_vendor` → `vnd_vendors` | Wrong FK Table |
| 14 | 1750 | `tpt_student_event_log` | FK changed from `tpt_students` → `std_students` | Wrong FK Table |
| 15 | 1751 | `tpt_student_event_log` | FK changed from `tpt_student_session` → `std_student_sessions_jnt` | Wrong FK Table |
| 16 | 1752 | `tpt_student_event_log` | FK changed from `tpt_routes` → `tpt_route` (singular) | Wrong FK Table |
| 17 | 1755 | `tpt_student_event_log` | FK changed from `tpt_routes` → `tpt_route` (singular) | Wrong FK Table |
| 18 | 1779 | `tpt_notification_log` | FK changed from `tpt_student_session` → `std_student_sessions_jnt` | Wrong FK Table |
| 19 | 5283-5284 | `qns_questions` | FK changed from `sch_users` → `sys_users`; commented out `fk_ques_reviewed_by` (column doesn't exist) | Wrong FK Table |
| 20 | 5287 | `qns_questions` | FK changed from `sch_students` → `std_students` | Wrong FK Table |
| 21 | 5481 | `qns_question_review_log` | FK changed from `users` → `sys_users` | Wrong FK Table |
| 22 | 5482 | `qns_question_review_log` | FK changed from `sys_dropdowns` → `sys_dropdown_table` | Wrong FK Table |
| 23 | 5779 | `slb_books` | FK changed from `media_files` → `qns_media_store`; removed trailing comma | Wrong FK Table |
| 24 | 5793 | `slb_book_author_jnt` | FK changed from `bok_books` → `slb_books` | Wrong FK Table |
| 25 | 5794 | `slb_book_author_jnt` | FK changed from `bok_book_authors` → `slb_book_authors` | Wrong FK Table |
| 26 | 5817 | `slb_book_chapter_section_jnt` | FK changed from `bok_books` → `slb_books` | Wrong FK Table |
| 27 | 7856 | `lib_categories` | FK changed from `lib_categories(category_id)` → `lib_categories(id)` | Wrong FK Column |

### 3.5 FK Column/Constraint Renames

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 28 | 1486 | `tpt_student_allocation_jnt` | Split single FK `fk_sa_route` (`route_id`) into two: `fk_sa_pickupRoute` (`pickup_route_id`) + `fk_sa_dropRoute` (`drop_route_id`) | FK Restructure |
| 29 | 1781 | `tpt_notification_log` | FK column changed from `stop_id` → `boarding_stop_id` | Column Rename |
| 30 | 3524 | `tt_teacher_assignment` | Renamed UNIQUE KEY from `uq_ta_class_wise` → `uq_ta_class_wise_detail` | Rename |

### 3.6 DEFAULT Value Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 31 | 4670 | `std_student_academic_sessions` | Removed invalid `DEFAULT 'ACTIVE'` from INT UNSIGNED column `session_status_id` | Invalid DEFAULT |
| 32 | 6008 | `std_student_academic_sessions` (dup) | Same fix in duplicate table definition | Invalid DEFAULT |
| 33 | 5938 | `std_student_personal_details` | Fixed `DEFAULT NOT NULL` → `DEFAULT NULL` for `user_id` | Invalid Syntax |

### 3.7 INDEX Column Reference Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 34 | 5272 | `qns_questions` | Changed INDEX column from `visibility` → `availability` (matching actual column name) | Wrong Column |
| 35 | 5676 | `rec_rules` | Changed INDEX column from `trigger_event` → `trigger_event_id` | Wrong Column |
| 36 | 7838 | `lib_membership_types` | Removed `is_deleted` from INDEX (column doesn't exist; table uses `deleted_at`) | Non-existent Column |
| 37 | 7858 | `lib_categories` | Removed `is_deleted` from INDEX | Non-existent Column |
| 38 | 7872 | `lib_genres` | Removed `is_deleted` from INDEX | Non-existent Column |
| 39 | 7840 | `lib_membership_types` | Removed trailing comma after last UNIQUE KEY | Trailing Comma |

### 3.8 Missing ENGINE Clause Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 40 | 5394 | `qns_media_store` | Added `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci` | Missing ENGINE |
| 41 | 5481-5483 | `qns_question_review_log` | Added ENGINE clause | Missing ENGINE |
| 42 | 5497 | `qns_question_usage_type` | Added ENGINE clause | Missing ENGINE |

### 3.9 Timetable Module Syntax Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 43 | 3603-3609 | `tt_requirement_consolidation` | Added missing commas after 6 consecutive column definitions that ended with `-- comment` but no comma | Missing Commas |
| 44 | 3613 | `tt_requirement_consolidation` | Changed UNIQUE KEY from referencing commented-out columns `(priority_type, priority_name)` → `(requirement_consolidation_id)` | Non-existent Column |
| 45 | 3682 | `tt_activity` | Changed semicolon `;` → comma `,` after INDEX (semicolon was prematurely ending CREATE TABLE) | Semicolon→Comma |
| 46 | 3688 | `tt_activity` | Removed invalid `ON tt_activity` from INDEX inside CREATE TABLE; changed `;` → `,` | Invalid INDEX Syntax |
| 47 | 3718 | `tt_sub_activity` | Fixed UNIQUE KEY column from `sub_activity_ord` → `ordinal` (matching actual column) | Wrong Column |
| 48 | 3719 | `tt_sub_activity` | Removed UNIQUE KEY `uq_subact_code` — column `code` is commented out | Non-existent Column |
| 49 | 3721 | `tt_sub_activity` | Removed trailing comma after last CONSTRAINT | Trailing Comma |

### 3.10 HPC Module Fixes

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 50 | 6387-6388 | `hpc_reports` | Removed trailing comma after KEY; fixed extra `)` before ENGINE | Trailing Comma + Syntax |
| 51 | 6812 | `lms_homework` | Removed FK `fk_hw_sub_topic` referencing non-existent table `slb_sub_topics` | Non-existent Table |

---

## 4. tenant_db.sql → tenant_db_corrected.sql

The corrected version includes ALL changes from v2 above, **plus** the following additional fixes:

**Total Additional Changes (beyond v2): 15**

### 4.1 Polymorphic FK Removal

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 1 | 72-73 | `sys_model_has_permissions_jnt` | Removed FK `fk_modelHasPermissions_modelId_modelType` referencing non-existent `sys_models` table; added comment explaining polymorphic relations cannot have FK constraints | Non-existent Table |
| 2 | 83-84 | `sys_model_has_roles_jnt` | Removed FK `fk_modelHasRoles_modelId_modelType` referencing non-existent `sys_models` table; added comment | Non-existent Table |

### 4.2 Rule Engine FK Fixes (lms_ → sys_)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 3 | 355 | `sys_rule_engine_config` | FK changed from `lms_trigger_event` → `sys_trigger_event` | Wrong FK Table |
| 4 | 370 | `sys_rule_engine_actions` | FK changed from `lms_rule_engine_config` → `sys_rule_engine_config` | Wrong FK Table |
| 5 | 371 | `sys_rule_engine_actions` | FK changed from `lms_action_type` → `sys_action_type` | Wrong FK Table |
| 6 | 391 | `sys_rule_engine_log` | FK changed from `lms_rule_engine_config` → `sys_rule_engine_config` | Wrong FK Table |
| 7 | 392 | `sys_rule_engine_log` | FK changed from `lms_trigger_event` → `sys_trigger_event` | Wrong FK Table |
| 8 | 393 | `sys_rule_engine_log` | FK changed from `lms_action_type` → `sys_action_type` | Wrong FK Table |

### 4.3 Index Column Fix

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 9 | 556 | `sch_attendance_types` | Changed INDEX column from `is_deleted` → `deleted_at` (column `is_deleted` doesn't exist) | Wrong Column |

### 4.4 Vendor Table Reference Fix

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 10 | 2119 | `cmp_sla_config` | FK changed from `tpt_vendor` → `vnd_vendors` | Wrong FK Table |

### 4.5 Notification User Table Fixes (sys_user → sys_users)

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 11 | 2505 | `ntf_device_tokens` | FK changed from `sys_user` → `sys_users` (pluralized) | Wrong FK Table |
| 12 | 2613 | `ntf_notification_recipients` | FK changed from `sys_user` → `sys_users` (pluralized) | Wrong FK Table |

### 4.6 Timetable Unique Key Rename

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 13 | 3523 | `tt_teacher_assignment` | Renamed UNIQUE KEY from `uq_ta_class_wise` → `uq_ta_teacher_day_period` (more descriptive name) | Rename |

### 4.7 Question Bank FK Column Fix

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 14 | 5462 | `qns_question_usage_jnt` | FK column changed from `usage_context` → `question_usage_type` (matching actual column name) | Wrong FK Column |

### 4.8 Syllabus Books Media Reference Fix

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 15 | 5779 | `slb_books` | FK changed from `media_files` → `sys_media` (instead of `qns_media_store` in v2) | Wrong FK Table |

### 4.9 HPC Missing Comma Fix

| # | Line | Table | Change | Category |
|---|------|-------|--------|----------|
| 16 | 6531 | `hpc_learning_outcomes` | Added missing comma after CONSTRAINT `fk_lo_bloom` before next CONSTRAINT | Missing Comma |

---

## 5. Remaining Issues (Found During Validation — Not Yet Fixed)

### 5.1 global_db_v2.sql

| # | Line | Issue | Severity |
|---|------|-------|----------|
| 1 | 71 | GENERATED column `` `1` `` should be bare `1` | ERROR |

### 5.2 prime_db_v2.sql

| # | Line | Issue | Severity |
|---|------|-------|----------|
| 1 | 412 | `billing_cycle_id` SMALLINT vs SMALLINT UNSIGNED mismatch in `prm_plans` | ERROR |
| 2 | 435 | `-- Note:` comment swallows `ON DELETE CASCADE,` in `prm_module_plan_jnt` | ERROR |
| 3 | 503 | `-- Note:` comment swallows `ON DELETE RESTRICT,` in `prm_tenant_plan_module_jnt` | ERROR |
| 4 | 524 | Forward FK reference: `prm_tenant_plan_billing_schedule` → `bil_tenant_invoices` (not yet created) | ERROR |
| 5 | 589 | `-- Note:` comment swallows `ON DELETE SET NULL` in `bil_tenant_invoicing_modules_jnt` | WARNING |

### 5.3 tenant_db (Both v2 and corrected) — Categorized by Module

#### System/Foundation Tables (Lines 1-560)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 1 | 72,83 | FK to non-existent `sys_models` (v2 only — fixed in corrected) | ERROR |
| 2 | 354-393 | FKs reference `lms_*` instead of `sys_*` tables (v2 only — fixed in corrected) | ERROR |
| 3 | 556 | INDEX on `is_deleted` column — doesn't exist (v2 only — fixed in corrected) | ERROR |

#### SchoolSetup Module (Lines 560-1100)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 4 | 919 | `room_type_id` INT (signed) vs `sch_rooms_type.id` INT UNSIGNED | ERROR |
| 5 | 1029 | FK to non-existent `sch_employee_roles` | ERROR |
| 6 | 1030 | FK to `sch_departments` — should be `sch_department` (singular) | ERROR |
| 7 | 1080-1082 | FKs to `sch_employee_roles`, `sch_departments`, `sch_designations` — wrong names | ERROR |

#### Transport Module (Lines 1100-1800)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 8 | 1486 | FK to `route_id` but column is `pickup_route_id` (corrected only) | ERROR |
| 9 | 1751-1752 | FK to `tpt_student_session` and `tpt_routes` (corrected only — v2 fixed these) | ERROR |

#### Vendor Module (Lines 1800-2000)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 10 | 1886 | Trailing comma before `)` in `vnd_agreements` | ERROR |
| 11 | 1922 | Trailing comma before `)` in `vnd_agreement_items_jnt` | ERROR |
| 12 | 1929-1934 | Uncommented plain text (example data) — will cause parse failure | ERROR |
| 13 | 1952, 2000 | FK to `vnd_agreement_items` — should be `vnd_agreement_items_jnt` | ERROR |

#### Complaint Module (Lines 2060-2260)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 14 | 2070-2074 | FKs reference `sys_groups` — should be `sch_entity_groups` | ERROR |
| 15 | 2112 | `ON DELETE SET NULL` on NOT NULL column `complaint_category_id` | ERROR |
| 16 | 2114-2120 | FKs to wrong tables: `sch_departments`, `sch_designations`, `sch_roles`, `sch_users`, `sch_vehicles`, `tpt_vendor` | ERROR |
| 17 | 2140 | `DEFAULT CURRENT_DATE()` — invalid MySQL syntax | ERROR |
| 18 | 2187 | INDEX on `status` — column is `status_id` | ERROR |
| 19 | 2204 | FK on TINYINT boolean `is_medical_check_required` to INT UNSIGNED PK | ERROR |
| 20 | 2252 | FK on VARCHAR `result` to INT UNSIGNED `sys_dropdown_table.id` | ERROR |

#### Notification Module (Lines 2280-2650)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 21 | 2291+ | `tenant_id` column in tenant-scoped tables (redundant, no FK target) | WARNING |

#### Academic Terms (Lines 2780-2810)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 22 | 2803 | INDEX references `start_date`, `end_date` — columns are `term_start_date`, `term_end_date` | ERROR |

#### Timetable Module (Lines 3400-4100)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 23 | 3559 | UNIQUE KEY references 6 non-existent columns in `tt_room_availability` | ERROR |
| 24 | 3561-3564 | FKs reference non-existent columns and wrong tables in `tt_room_availability` | ERROR |
| 25 | 3585 | UNIQUE KEY references non-existent columns in `tt_room_availability_detail` | ERROR |
| 26 | 3685-3686 | INDEX references non-existent `class_group_id`, `class_subgroup_id` in `tt_activity` | ERROR |
| 27 | 3691-3692 | FK references non-existent `class_group_id`, `class_subgroup_id` | ERROR |
| 28 | 3783-3785 | `AFTER` clause in CREATE TABLE — only valid in ALTER TABLE | ERROR |

#### Duplicate Table Definitions (Entire File)
| # | Tables | Issue | Severity |
|---|--------|-------|----------|
| 29 | `sch_organizations`, `sch_org_academic_sessions_jnt`, `sch_board_organization_jnt`, `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subject_types`, `sch_study_formats`, `sch_subjects`, `sch_subject_study_format_jnt`, `sch_class_groups_jnt`, `sch_subject_groups`, `sch_subject_group_subject_jnt`, `sch_buildings`, `sch_rooms_type`, `sch_rooms`, `sch_employees`, `sch_teacher_profile`, `sch_teacher_capabilities` | 19 SchoolSetup tables duplicated in Section 11 (timetable reference) | WARNING |
| 30 | `std_students`, `std_student_academic_sessions` | Student tables duplicated | WARNING |
| 31 | `lms_student_attempts`, `lms_exam_results`, `lms_exam_grievances` | LMS tables with conflicting duplicate definitions | ERROR |
| 32 | `lib_fines` | Library table with conflicting duplicate definitions | ERROR |

#### Question Bank Module (Lines 5200-5500)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 33 | 5283 | FK `fk_ques_reviewed_by` references commented-out column (v2 handled differently than corrected) | WARNING |

#### HPC Module (Lines 6200-6750)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 34 | 6272+ | Multiple signed/unsigned INT mismatches across HPC tables | ERROR |
| 35 | 6511 | FK references `slb_circular_goals` — should be `hpc_circular_goals` | ERROR |
| 36 | 6548 | FK references `slb_learning_outcomes` — should be `hpc_learning_outcomes` | ERROR |
| 37 | 6550 | FK on non-existent column `subject_id` in `hpc_outcome_entity_jnt` | ERROR |
| 38 | 6551 | FK on ENUM column `entity_type` to INT UNSIGNED PK | ERROR |
| 39 | 6697-6704 | FKs reference `slb_students`, `slb_subjects`, `slb_users` — wrong prefixes | ERROR |
| 40 | 6712-6727 | `hpc_learning_activities` created before `hpc_learning_activity_type` (forward FK) | ERROR |

#### LMS Exam Module (Lines 7200-7500)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 41 | 7243, 7301 | `status_id DEFAULT 0` — no row with id=0 exists in FK target | ERROR |

#### Library Module (Lines 7800-8900)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 42 | 7889, 7905, 7924, 8145 | INDEX on non-existent `is_deleted` column (4 tables) | ERROR |
| 43 | 7990-8649 | ~50 FKs reference wrong PK column names (`book_id`, `member_id`, `genre_id`, `category_id`, `keyword_id`, `condition_id`, `shelf_location_id`, `copy_id`, `transaction_id`, `fine_id`, `digital_resource_id`, `membership_type_id`, `audit_id` instead of `id`) | ERROR |
| 44 | 8032-8108 | 4 junction tables have duplicate PRIMARY KEYs (inline `id PK` + composite PK) | ERROR |
| 45 | 8176 | FK to non-existent table `media_files` | ERROR |
| 46 | 8228+ | FK references `users` instead of `sys_users` (5 instances) | ERROR |
| 47 | 8267 | INDEX on `issued_by` — column is `issued_by_id` | ERROR |
| 48 | 8303-8305 | `waived_by_id`, `waived_reason`, `waived_at` are NOT NULL but should be nullable | ERROR |
| 49 | 8429, 8450 | FK on `performed_by` — column is `performed_by_id` | ERROR |
| 50 | 8457 | FK type mismatch: `audit_id` BIGINT vs `lib_inventory_audit.id` INT | ERROR |
| 51 | 8661-8665 | PostgreSQL-only `WHERE` in CREATE INDEX (5 instances) | ERROR |
| 52 | 8912-8965 | INSERT column names don't match table definitions (6 seed blocks) | ERROR |

#### Fee Module (Lines 8900-9600)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 53 | 9189 | Extra closing `)` in CHECK constraint of `fee_concession_applicable_heads` | ERROR |
| 54 | 9211 | Column name `join_in_mid-year` contains hyphen — should be `join_in_mid_year` | WARNING |

#### Accounting Module (Lines 9600-10270)
| # | Line | Issue | Severity |
|---|------|-------|----------|
| 55 | 9646-10080 | ~25 FKs reference un-prefixed table names (e.g., `account_groups` → `acc_account_groups`, `ledgers` → `acc_ledgers`, `fiscal_years` → `acc_fiscal_years`, etc.) | ERROR |
| 56 | 10265-10270 | CREATE INDEX references un-prefixed table names | ERROR |
| 57 | 10268 | PostgreSQL-only `WHERE` in CREATE INDEX | ERROR |
| 58 | 9630-10257 | No tables use `IF NOT EXISTS` in accounting module | WARNING |

---

## 6. Differences Between tenant_db_v2.sql and tenant_db_corrected.sql

The corrected version applied these **additional fixes** that v2 did NOT have:

| # | Area | v2 | Corrected |
|---|------|----|-----------|
| 1 | Polymorphic FKs (L72, L83) | Kept invalid FK to `sys_models` | Removed FK + added comment |
| 2 | Rule Engine FKs (L354-393) | Still references `lms_*` tables | Fixed to `sys_*` tables |
| 3 | Attendance INDEX (L556) | Uses `is_deleted` | Fixed to `deleted_at` |
| 4 | Vendor FK (L2119) | Still references `tpt_vendor` | Fixed to `vnd_vendors` |
| 5 | Notification FKs (L2505, L2613) | References `sys_user` (singular) | Fixed to `sys_users` (plural) |
| 6 | Teacher Assignment UK (L3523) | Named `uq_ta_class_wise_detail` | Named `uq_ta_teacher_day_period` |
| 7 | Question Usage FK (L5462) | Column `usage_context` | Fixed to `question_usage_type` |
| 8 | Books Media FK (L5779) | References `qns_media_store` | References `sys_media` |
| 9 | HPC Missing Comma (L6531) | Missing comma | Added comma |

**However, the corrected version also REVERTED some v2 fixes:**

| # | Area | v2 (Fixed) | Corrected (Reverted) |
|---|------|------------|---------------------|
| 1 | Transport FK (L1486) | Split into `pickup_route_id` + `drop_route_id` | Reverted to single `route_id` |
| 2 | Transport FK (L1751-1752) | Fixed to `std_student_sessions_jnt` + `tpt_route` | Reverted to `tpt_student_session` + `tpt_routes` |
| 3 | Transport FK (L1780) | Fixed to `std_student_sessions_jnt` | Reverted to `tpt_student_session` |
| 4 | Trailing space (L818) | Removed trailing space | Trailing space still present |

---

## 7. Summary Statistics

| Metric | global_db | prime_db | tenant_db |
|--------|-----------|----------|-----------|
| Original file lines | 189 | 644 | 10,297 |
| Changes in v2 | 1 | 20 | 51 |
| Additional in corrected | — | — | 16 |
| Remaining errors | 1 | 4 | ~58 |
| Remaining warnings | — | 1 | ~8 |
