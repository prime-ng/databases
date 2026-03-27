<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * HRS — HR & Payroll Module Migration
 * Module: HrStaff (Modules\HrStaff)
 * Table Prefixes: hrs_* (23 tables) + pay_* (10 tables)
 * Database: tenant_db (one per tenant — no tenant_id columns)
 * Generated: 2026-03-26
 *
 * Deploy path: database/migrations/tenant/2026_03_26_000000_create_hrs_and_pay_tables.php
 *
 * NOTE: sch_* and sys_* FKs reference existing tenant_db tables.
 * NOTE: sch_employees.id = INT UNSIGNED — use unsignedInteger() for FK columns.
 * NOTE: sch_org_academic_sessions_jnt.id = SMALLINT UNSIGNED — use unsignedSmallInteger().
 */
return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No dependencies on other hrs_*/pay_* tables (7 tables)
        // =====================================================================

        // 1. hrs_kpi_templates
        Schema::create('hrs_kpi_templates', function (Blueprint $table) {
            $table->id();
            $table->string('name', 200)->comment('Template name e.g. Teaching KPI 2025-26');
            $table->enum('applicable_to', ['all', 'teaching', 'non_teaching'])->default('all')->comment('Staff category this template applies to');
            $table->unsignedTinyInteger('rating_scale')->default(5)->comment('5-point or 10-point rating scale');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
        });

        // 2. hrs_leave_types
        Schema::create('hrs_leave_types', function (Blueprint $table) {
            $table->id();
            $table->string('code', 10)->comment('Short code: CL, EL, SL, ML, PL, CO, LWP');
            $table->string('name', 100)->comment('e.g. Casual Leave, Earned Leave');
            $table->decimal('days_per_year', 5, 1)->default(0)->comment('0 for LWP and CO (granted ad-hoc)');
            $table->unsignedTinyInteger('carry_forward_days')->default(0)->comment('0 = no carry-forward');
            $table->enum('applicable_to', ['all', 'teaching', 'non_teaching'])->default('all')->comment('Which staff category can apply');
            $table->boolean('is_paid')->default(true)->comment('0 = unpaid leave (LWP)');
            $table->boolean('requires_medical_cert')->default(false)->comment('1 = medical certificate required (SL)');
            $table->unsignedTinyInteger('medical_cert_threshold_days')->default(3)->comment('SL: cert needed if absence > this days');
            $table->boolean('half_day_allowed')->default(false)->comment('1 = half-day application supported');
            $table->enum('gender_restriction', ['all', 'male', 'female'])->default('all')->comment('all / female (ML) / male (PL)');
            $table->unsignedTinyInteger('min_service_months')->default(0)->comment('EL typically requires 6 months service');
            $table->unsignedTinyInteger('max_consecutive_days')->nullable()->comment('NULL = no limit');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique('code', 'uq_hrs_leave_type_code');
        });

        // 3. hrs_id_card_templates
        Schema::create('hrs_id_card_templates', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150)->comment('Template name');
            $table->json('layout_json')->comment('Fields list, dimensions, color scheme, logo position');
            $table->boolean('is_default')->default(false)->comment('One default allowed — enforced in IdCardService');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
        });

        // 4. hrs_pay_grades
        Schema::create('hrs_pay_grades', function (Blueprint $table) {
            $table->id();
            $table->string('grade_name', 100)->comment('e.g. Grade A, Senior Teacher');
            $table->decimal('min_ctc', 12, 2)->comment('Minimum annual CTC for this grade');
            $table->decimal('max_ctc', 12, 2)->comment('Maximum annual CTC for this grade');
            $table->json('applicable_designation_ids')->nullable()->comment('Array of sch_designation.id; NULL = all designations');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
        });

        // 5. hrs_pt_slabs
        Schema::create('hrs_pt_slabs', function (Blueprint $table) {
            $table->id();
            $table->string('state_code', 5)->comment('ISO state code: HP, KA, MH, etc.');
            $table->decimal('min_salary', 10, 2)->comment('Slab lower bound — monthly gross (inclusive)');
            $table->decimal('max_salary', 10, 2)->comment('Upper bound; use 999999999.00 for open-ended');
            $table->decimal('pt_amount', 8, 2)->comment('Monthly PT amount (INR) for this slab');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('state_code', 'idx_hrs_pt_state');
        });

        // 6. pay_salary_components
        Schema::create('pay_salary_components', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150)->comment('Component name e.g. Basic Pay, PF Employee');
            $table->string('code', 30)->comment('Unique code: BASIC, DA, HRA, PF_EMP, etc.');
            $table->enum('component_type', ['earning', 'deduction', 'employer_contribution'])->comment('earning / deduction / employer_contribution');
            $table->enum('calculation_type', ['fixed', 'percentage_of_basic', 'percentage_of_gross', 'statutory', 'manual'])->comment('How this component is computed');
            $table->decimal('default_value', 10, 4)->default(0.0000)->comment('Amount (INR) or percentage. HRA = 25.0000');
            $table->boolean('is_taxable')->default(true)->comment('1 = included in TDS projected income');
            $table->boolean('is_statutory')->default(false)->comment('1 for PF/ESI/PT/TDS components');
            $table->unsignedTinyInteger('display_order')->default(99)->comment('Order on payslip');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique('code', 'uq_pay_comp_code');
        });

        // 7. pay_salary_structures
        Schema::create('pay_salary_structures', function (Blueprint $table) {
            $table->id();
            $table->string('name', 200)->comment('e.g. Teaching Staff Structure');
            $table->text('description')->nullable()->comment('Optional description');
            $table->enum('applicable_to', ['all', 'teaching', 'non_teaching', 'contractual'])->default('all')->comment('Staff category');
            $table->boolean('is_active')->default(true)->comment('Inactive structures cannot be newly assigned');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
        });

        // =====================================================================
        // LAYER 2 — Depends on Layer 1 (2 tables)
        // =====================================================================

        // 8. hrs_kpi_template_items
        Schema::create('hrs_kpi_template_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('template_id')->comment('FK → hrs_kpi_templates.id');
            $table->string('kpi_name', 200)->comment('KPI item name e.g. Student Performance');
            $table->enum('category', ['academic', 'behavioral', 'administrative'])->comment('KPI grouping category');
            $table->decimal('weight', 5, 2)->comment('% weight; all items must sum to 100');
            $table->text('description')->nullable()->comment('Optional KPI explanation');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('template_id', 'fk_hrs_kpiitem_tmplid');
            $table->foreign('template_id', 'fk_hrs_kpiitem_tmplid')->references('id')->on('hrs_kpi_templates');
        });

        // 9. pay_salary_structure_components
        Schema::create('pay_salary_structure_components', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('structure_id')->comment('FK → pay_salary_structures.id');
            $table->unsignedBigInteger('component_id')->comment('FK → pay_salary_components.id');
            $table->unsignedTinyInteger('sequence_order')->default(99)->comment('Computation and display order');
            $table->text('calculation_formula')->nullable()->comment('Override formula if different from component default');
            $table->boolean('is_mandatory')->default(false)->comment('1 = cannot be removed from this structure');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['structure_id', 'component_id'], 'uq_pay_struct_comp');
            $table->index('structure_id', 'fk_pay_structcomp_structid');
            $table->index('component_id', 'fk_pay_structcomp_compid');
            $table->foreign('structure_id', 'fk_pay_structcomp_structid')->references('id')->on('pay_salary_structures');
            $table->foreign('component_id', 'fk_pay_structcomp_compid')->references('id')->on('pay_salary_components');
        });

        // =====================================================================
        // LAYER 3 — Depends on sch_* tables only (7 tables)
        // =====================================================================

        // 10. hrs_employment_details
        Schema::create('hrs_employment_details', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id (INT UNSIGNED)');
            $table->enum('contract_type', ['permanent', 'contractual', 'probation', 'part_time', 'substitute'])->comment('Employment contract type');
            $table->date('probation_end_date')->nullable()->comment('Probation end date');
            $table->date('confirmation_date')->nullable()->comment('Date employment was confirmed');
            $table->unsignedTinyInteger('notice_period_days')->default(30)->comment('Notice period in days');
            $table->text('bank_account_number')->nullable()->comment('Laravel encrypt() — never plaintext (BR-HRS-015)');
            $table->string('bank_ifsc', 11)->nullable()->comment('Bank IFSC code');
            $table->string('bank_name', 100)->nullable()->comment('Bank name');
            $table->string('bank_branch', 100)->nullable()->comment('Bank branch name');
            $table->json('emergency_contact_json')->nullable()->comment('{name, relationship, phone, address}');
            $table->json('previous_employer_json')->nullable()->comment('[{company, role, from_date, to_date}]');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique('employee_id', 'uq_hrs_emp_details_emp');
            $table->index('employee_id', 'fk_hrs_empdet_empid');
            $table->foreign('employee_id', 'fk_hrs_empdet_empid')->references('id')->on('sch_employees');
        });

        // 11. hrs_employment_history
        Schema::create('hrs_employment_history', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->string('change_type', 50)->comment('contract_type, department, designation, pay_grade, salary_revision');
            $table->json('old_value')->comment('Previous value(s)');
            $table->json('new_value')->comment('New value(s)');
            $table->date('effective_date')->comment('Date the change took effect');
            $table->unsignedInteger('changed_by')->comment('FK → sch_employees.id; who made the change');
            $table->text('remarks')->nullable()->comment('Optional explanation');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('employee_id', 'fk_hrs_emphist_empid');
            $table->index('changed_by', 'fk_hrs_emphist_changedby');
            $table->foreign('employee_id', 'fk_hrs_emphist_empid')->references('id')->on('sch_employees');
            $table->foreign('changed_by', 'fk_hrs_emphist_changedby')->references('id')->on('sch_employees');
        });

        // 12. hrs_employee_documents
        Schema::create('hrs_employee_documents', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->string('document_type', 50)->comment('appointment_letter, increment_letter, transfer_letter, warning_letter, experience_certificate, id_proof, educational_certificate, medical_certificate, other');
            $table->string('document_name', 200)->comment('Human-readable document label');
            $table->unsignedBigInteger('media_id')->comment('FK → sys_media.id; actual file reference');
            $table->date('issued_date')->nullable()->comment('Document issue date');
            $table->date('expiry_date')->nullable()->comment('DocumentExpiringSoon event 30 days before expiry');
            $table->string('issued_by', 150)->nullable()->comment('Issuing institution or person');
            $table->text('remarks')->nullable()->comment('Optional remarks');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('employee_id', 'fk_hrs_empdoc_empid');
            $table->index('media_id', 'fk_hrs_empdoc_mediaid');
            $table->index('expiry_date', 'idx_hrs_empdoc_expiry');
            $table->foreign('employee_id', 'fk_hrs_empdoc_empid')->references('id')->on('sch_employees');
            $table->foreign('media_id', 'fk_hrs_empdoc_mediaid')->references('id')->on('sys_media');
        });

        // 13. hrs_leave_policies
        Schema::create('hrs_leave_policies', function (Blueprint $table) {
            $table->id();
            $table->unsignedSmallInteger('academic_year_id')->nullable()->comment('FK → sch_org_academic_sessions_jnt.id; NULL = global default');
            $table->unsignedTinyInteger('max_backdated_days')->default(3)->comment('Max days in past for backdated application');
            $table->unsignedTinyInteger('min_advance_days')->default(0)->comment('Min advance days before leave start');
            $table->unsignedTinyInteger('approval_levels')->default(2)->comment('1 = HOD only; 2 = HOD + Principal');
            $table->unsignedTinyInteger('optional_holiday_count')->default(2)->comment('Optional holidays per year');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('academic_year_id', 'fk_hrs_lvpol_ayid');
            $table->foreign('academic_year_id', 'fk_hrs_lvpol_ayid')->references('id')->on('sch_org_academic_sessions_jnt');
        });

        // 14. hrs_holiday_calendars
        Schema::create('hrs_holiday_calendars', function (Blueprint $table) {
            $table->id();
            $table->unsignedSmallInteger('academic_year_id')->comment('FK → sch_org_academic_sessions_jnt.id');
            $table->date('holiday_date')->comment('Date of the holiday');
            $table->string('holiday_name', 150)->comment('e.g. Independence Day, Diwali');
            $table->enum('holiday_type', ['national', 'state', 'school', 'optional'])->comment('Type of holiday');
            $table->enum('applicable_to', ['all', 'teaching', 'non_teaching'])->default('all')->comment('Staff category');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('academic_year_id', 'fk_hrs_holiday_ayid');
            $table->index('holiday_date', 'idx_hrs_holiday_date');
            $table->foreign('academic_year_id', 'fk_hrs_holiday_ayid')->references('id')->on('sch_org_academic_sessions_jnt');
        });

        // 15. hrs_compliance_records
        Schema::create('hrs_compliance_records', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->enum('compliance_type', ['pf', 'esi', 'tds', 'gratuity', 'pt'])->comment('Statutory compliance type');
            $table->string('reference_number', 100)->nullable()->comment('UAN (PF), IP number (ESI), encrypted PAN (TDS) — VARCHAR(100)');
            $table->date('enrollment_date')->nullable()->comment('Date enrolled in this scheme');
            $table->boolean('applicable_flag')->default(true)->comment('1 = this compliance applies to this employee');
            $table->json('nominee_json')->nullable()->comment('PF/Gratuity nominee: [{name, relationship, share_pct}]');
            $table->json('details_json')->nullable()->comment('TDS→{regime,80C,HRA,LTA}; PT→{state_code}; ESI→{dispensary}');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['employee_id', 'compliance_type'], 'uq_hrs_compliance');
            $table->index('employee_id', 'fk_hrs_compl_empid');
            $table->index('compliance_type', 'idx_hrs_compl_type');
            $table->foreign('employee_id', 'fk_hrs_compl_empid')->references('id')->on('sch_employees');
        });

        // 16. hrs_lop_records
        Schema::create('hrs_lop_records', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->date('absent_date')->comment('Date employee was absent without approved leave');
            $table->enum('flag_status', ['flagged', 'confirmed', 'waived'])->default('flagged')->comment('flagged / confirmed / waived');
            $table->unsignedInteger('confirmed_by')->nullable()->comment('FK → sch_employees.id; HR Manager who confirmed');
            $table->timestamp('confirmed_at')->nullable()->comment('Confirmation timestamp');
            $table->string('payroll_month', 7)->nullable()->comment('YYYY-MM; set when consumed by payroll');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['employee_id', 'absent_date'], 'uq_hrs_lop');
            $table->index('employee_id', 'fk_hrs_lop_empid');
            $table->index('confirmed_by', 'fk_hrs_lop_confirmedby');
            $table->index('payroll_month', 'idx_hrs_lop_month');
            $table->index('flag_status', 'idx_hrs_lop_status');
            $table->foreign('employee_id', 'fk_hrs_lop_empid')->references('id')->on('sch_employees');
            $table->foreign('confirmed_by', 'fk_hrs_lop_confirmedby')->references('id')->on('sch_employees');
        });

        // =====================================================================
        // LAYER 4 — Depends on Layer 1 + sch_* (5 tables)
        // =====================================================================

        // 17. hrs_salary_assignments
        Schema::create('hrs_salary_assignments', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->unsignedBigInteger('pay_salary_structure_id')->comment('FK → pay_salary_structures.id (cross-prefix FK)');
            $table->unsignedBigInteger('pay_grade_id')->nullable()->comment('FK → hrs_pay_grades.id');
            $table->decimal('ctc_amount', 12, 2)->comment('Annual CTC in INR');
            $table->decimal('gross_monthly', 12, 2)->comment('Monthly gross = CTC/12 minus employer contributions');
            $table->date('effective_from_date')->comment('Assignment effective from this date');
            $table->date('effective_to_date')->nullable()->comment('NULL = currently active');
            $table->string('revision_reason', 200)->nullable()->comment('Reason for assignment/revision');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('employee_id', 'fk_hrs_salassgn_empid');
            $table->index('pay_salary_structure_id', 'fk_hrs_salassgn_structid');
            $table->index('pay_grade_id', 'fk_hrs_salassgn_gradeid');
            $table->index(['effective_from_date', 'effective_to_date'], 'idx_hrs_salassgn_effective');
            $table->foreign('employee_id', 'fk_hrs_salassgn_empid')->references('id')->on('sch_employees');
            $table->foreign('pay_salary_structure_id', 'fk_hrs_salassgn_structid')->references('id')->on('pay_salary_structures');
            $table->foreign('pay_grade_id', 'fk_hrs_salassgn_gradeid')->references('id')->on('hrs_pay_grades');
        });

        // 18. hrs_appraisal_cycles
        Schema::create('hrs_appraisal_cycles', function (Blueprint $table) {
            $table->id();
            $table->string('name', 200)->comment('e.g. 2025-26 Annual Appraisal');
            $table->unsignedSmallInteger('academic_year_id')->comment('FK → sch_org_academic_sessions_jnt.id');
            $table->enum('appraisal_type', ['annual', 'mid_year', 'probation', 'confirmation'])->comment('Type of appraisal cycle');
            $table->unsignedBigInteger('kpi_template_id')->comment('FK → hrs_kpi_templates.id');
            $table->date('self_open_date')->comment('Employees can begin self-appraisal from this date');
            $table->date('self_close_date')->comment('Self-appraisal submission deadline');
            $table->date('manager_open_date')->comment('Must be >= self_close_date (BR-HRS-018)');
            $table->date('manager_close_date')->comment('Manager review deadline');
            $table->json('applicable_departments')->nullable()->comment('Array of sch_department.id; NULL = all');
            $table->enum('reviewer_mode', ['auto', 'manual'])->default('auto')->comment('auto = reporting_to; manual = HR assigns');
            $table->enum('status', ['draft', 'active', 'closed'])->default('draft')->comment('Cycle FSM status');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('academic_year_id', 'fk_hrs_aprcyc_ayid');
            $table->index('kpi_template_id', 'fk_hrs_aprcyc_tmplid');
            $table->foreign('academic_year_id', 'fk_hrs_aprcyc_ayid')->references('id')->on('sch_org_academic_sessions_jnt');
            $table->foreign('kpi_template_id', 'fk_hrs_aprcyc_tmplid')->references('id')->on('hrs_kpi_templates');
        });

        // 19. hrs_leave_balances
        Schema::create('hrs_leave_balances', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->unsignedBigInteger('leave_type_id')->comment('FK → hrs_leave_types.id');
            $table->unsignedSmallInteger('academic_year_id')->comment('FK → sch_org_academic_sessions_jnt.id');
            $table->decimal('allocated_days', 5, 1)->default(0)->comment('From leave_type.days_per_year at year start');
            $table->decimal('carry_forward_days', 5, 1)->default(0)->comment('From prior year; capped at type limit');
            $table->decimal('used_days', 5, 1)->default(0)->comment('Updated on leave approval/cancellation');
            $table->decimal('lop_days', 5, 1)->default(0)->comment('LOP days accrued this year');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['employee_id', 'leave_type_id', 'academic_year_id'], 'uq_hrs_leave_bal');
            $table->index('employee_id', 'fk_hrs_lbal_empid');
            $table->index('leave_type_id', 'fk_hrs_lbal_ltid');
            $table->index('academic_year_id', 'fk_hrs_lbal_ayid');
            $table->foreign('employee_id', 'fk_hrs_lbal_empid')->references('id')->on('sch_employees');
            $table->foreign('leave_type_id', 'fk_hrs_lbal_ltid')->references('id')->on('hrs_leave_types');
            $table->foreign('academic_year_id', 'fk_hrs_lbal_ayid')->references('id')->on('sch_org_academic_sessions_jnt');
        });

        // 20. hrs_leave_applications
        Schema::create('hrs_leave_applications', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id; applicant');
            $table->unsignedBigInteger('leave_type_id')->comment('FK → hrs_leave_types.id');
            $table->unsignedSmallInteger('academic_year_id')->comment('FK → sch_org_academic_sessions_jnt.id');
            $table->date('from_date')->comment('Leave start date');
            $table->date('to_date')->comment('Leave end date');
            $table->boolean('half_day')->default(false)->comment('1 = half-day application');
            $table->enum('half_day_session', ['first', 'second'])->nullable()->comment('Relevant only if half_day=1');
            $table->decimal('days_count', 5, 1)->comment('Computed on save excluding holidays');
            $table->text('reason')->comment('Employee-provided reason');
            $table->unsignedBigInteger('media_id')->nullable()->comment('FK → sys_media.id; supporting document');
            $table->enum('status', ['pending', 'pending_l2', 'approved', 'rejected', 'cancelled', 'returned'])->default('pending')->comment('Leave application FSM status');
            $table->unsignedTinyInteger('current_approver_level')->default(1)->comment('1 = awaiting HOD; 2 = awaiting Principal');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('employee_id', 'fk_hrs_lapp_empid');
            $table->index('leave_type_id', 'fk_hrs_lapp_ltid');
            $table->index('academic_year_id', 'fk_hrs_lapp_ayid');
            $table->index('media_id', 'fk_hrs_lapp_mediaid');
            $table->index('status', 'idx_hrs_lapp_status');
            $table->foreign('employee_id', 'fk_hrs_lapp_empid')->references('id')->on('sch_employees');
            $table->foreign('leave_type_id', 'fk_hrs_lapp_ltid')->references('id')->on('hrs_leave_types');
            $table->foreign('academic_year_id', 'fk_hrs_lapp_ayid')->references('id')->on('sch_org_academic_sessions_jnt');
            $table->foreign('media_id', 'fk_hrs_lapp_mediaid')->references('id')->on('sys_media');
        });

        // 21. pay_payroll_runs
        Schema::create('pay_payroll_runs', function (Blueprint $table) {
            $table->id();
            $table->string('payroll_month', 7)->comment('YYYY-MM format e.g. 2025-12');
            $table->unsignedSmallInteger('academic_year_id')->comment('FK → sch_org_academic_sessions_jnt.id');
            $table->enum('run_type', ['regular', 'supplementary'])->default('regular')->comment('regular = main monthly; supplementary = missed employees');
            $table->unsignedBigInteger('parent_run_id')->nullable()->comment('FK → pay_payroll_runs.id (self-ref); supplementary run links to parent');
            $table->enum('status', ['draft', 'computing', 'computed', 'reviewing', 'approved', 'locked'])->default('draft')->comment('Payroll Run FSM; locked = immutable (BR-PAY-003)');
            $table->unsignedInteger('initiated_by')->comment('FK → sch_employees.id; Payroll Manager');
            $table->unsignedInteger('approved_by')->nullable()->comment('FK → sch_employees.id; Principal');
            $table->timestamp('approved_at')->nullable()->comment('Approval timestamp');
            $table->timestamp('locked_at')->nullable()->comment('Lock timestamp; immutable after this');
            $table->decimal('total_gross', 14, 2)->nullable()->comment('Aggregate gross — stored on lock');
            $table->decimal('total_net', 14, 2)->nullable()->comment('Aggregate net — stored on lock');
            $table->unsignedSmallInteger('employee_count')->nullable()->comment('Number of employees in this run');
            $table->text('computation_notes')->nullable()->comment('Errors or warnings from computation');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['payroll_month', 'run_type'], 'uq_pay_run_month_type');
            $table->index('academic_year_id', 'fk_pay_run_ayid');
            $table->index('parent_run_id', 'fk_pay_run_parent');
            $table->index('initiated_by', 'fk_pay_run_initiated');
            $table->index('approved_by', 'fk_pay_run_approved');
            $table->index('status', 'idx_pay_run_status');
            $table->foreign('academic_year_id', 'fk_pay_run_ayid')->references('id')->on('sch_org_academic_sessions_jnt');
            $table->foreign('parent_run_id', 'fk_pay_run_parent')->references('id')->on('pay_payroll_runs');
            $table->foreign('initiated_by', 'fk_pay_run_initiated')->references('id')->on('sch_employees');
            $table->foreign('approved_by', 'fk_pay_run_approved')->references('id')->on('sch_employees');
        });

        // =====================================================================
        // LAYER 4.5 — After pay_payroll_runs (2 tables)
        // =====================================================================

        // 22. hrs_pf_contribution_register
        Schema::create('hrs_pf_contribution_register', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('compliance_record_id')->comment('FK → hrs_compliance_records.id');
            $table->unsignedBigInteger('payroll_run_id')->nullable()->comment('FK → pay_payroll_runs.id');
            $table->unsignedTinyInteger('month')->comment('Month number 1-12');
            $table->unsignedSmallInteger('year')->comment('Calendar year YYYY');
            $table->decimal('basic_wage', 12, 2)->comment('PF-eligible wages');
            $table->decimal('emp_contribution', 10, 2)->comment('Employee PF 12%');
            $table->decimal('employer_epf', 10, 2)->comment('Employer EPF 3.67%');
            $table->decimal('employer_eps', 10, 2)->comment('Employer EPS 8.33%');
            $table->unsignedTinyInteger('ncp_days')->default(0)->comment('Non-contributing days for EPFO ECR');
            $table->enum('status', ['computed', 'submitted', 'challan_generated'])->default('computed')->comment('Filing lifecycle');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['compliance_record_id', 'month', 'year'], 'uq_hrs_pfreg');
            $table->index('compliance_record_id', 'fk_hrs_pfreg_complid');
            $table->index('payroll_run_id', 'fk_hrs_pfreg_runid');
            $table->foreign('compliance_record_id', 'fk_hrs_pfreg_complid')->references('id')->on('hrs_compliance_records');
            $table->foreign('payroll_run_id', 'fk_hrs_pfreg_runid')->references('id')->on('pay_payroll_runs');
        });

        // 23. hrs_esi_contribution_register
        Schema::create('hrs_esi_contribution_register', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('compliance_record_id')->comment('FK → hrs_compliance_records.id');
            $table->unsignedBigInteger('payroll_run_id')->nullable()->comment('FK → pay_payroll_runs.id');
            $table->unsignedTinyInteger('month')->comment('Month number 1-12');
            $table->unsignedSmallInteger('year')->comment('Calendar year YYYY');
            $table->decimal('gross_wage', 12, 2)->comment('ESI-eligible wages (gross ≤ ₹21,000 threshold)');
            $table->decimal('emp_contribution', 10, 2)->comment('Employee ESI 0.75%');
            $table->decimal('employer_contribution', 10, 2)->comment('Employer ESI 3.25%');
            $table->enum('status', ['computed', 'submitted', 'challan_generated'])->default('computed')->comment('Filing lifecycle');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['compliance_record_id', 'month', 'year'], 'uq_hrs_esireg');
            $table->index('compliance_record_id', 'fk_hrs_esireg_complid');
            $table->index('payroll_run_id', 'fk_hrs_esireg_runid');
            $table->foreign('compliance_record_id', 'fk_hrs_esireg_complid')->references('id')->on('hrs_compliance_records');
            $table->foreign('payroll_run_id', 'fk_hrs_esireg_runid')->references('id')->on('pay_payroll_runs');
        });

        // =====================================================================
        // LAYER 5 — Depends on Layer 4 (6 tables)
        // =====================================================================

        // 24. hrs_leave_balance_adjustments
        Schema::create('hrs_leave_balance_adjustments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('leave_balance_id')->comment('FK → hrs_leave_balances.id');
            $table->decimal('adjustment_days', 5, 1)->comment('Positive = add; negative = deduct');
            $table->text('reason')->comment('Mandatory explanation');
            $table->unsignedInteger('adjusted_by')->comment('FK → sch_employees.id; HR Manager');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('leave_balance_id', 'fk_hrs_lbadj_lbid');
            $table->index('adjusted_by', 'fk_hrs_lbadj_adjby');
            $table->foreign('leave_balance_id', 'fk_hrs_lbadj_lbid')->references('id')->on('hrs_leave_balances');
            $table->foreign('adjusted_by', 'fk_hrs_lbadj_adjby')->references('id')->on('sch_employees');
        });

        // 25. hrs_leave_approvals
        Schema::create('hrs_leave_approvals', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('application_id')->comment('FK → hrs_leave_applications.id');
            $table->unsignedInteger('approver_id')->comment('FK → sch_employees.id; HOD or Principal');
            $table->unsignedTinyInteger('level')->comment('1 = HOD; 2 = Principal');
            $table->enum('action', ['approve', 'reject', 'return_for_clarification'])->comment('Action taken');
            $table->text('remarks')->comment('Mandatory remarks (BR-HRS-024)');
            $table->timestamp('actioned_at')->useCurrent()->comment('Timestamp of approval action');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('application_id', 'fk_hrs_lappr_appid');
            $table->index('approver_id', 'fk_hrs_lappr_approverid');
            $table->foreign('application_id', 'fk_hrs_lappr_appid')->references('id')->on('hrs_leave_applications');
            $table->foreign('approver_id', 'fk_hrs_lappr_approverid')->references('id')->on('sch_employees');
        });

        // 26. hrs_appraisals
        Schema::create('hrs_appraisals', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('cycle_id')->comment('FK → hrs_appraisal_cycles.id');
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id; appraisee');
            $table->unsignedInteger('reviewer_id')->nullable()->comment('FK → sch_employees.id; assigned reviewer');
            $table->json('self_rating_json')->nullable()->comment('[{kpi_id, rating, comments}]');
            $table->json('reviewer_rating_json')->nullable()->comment('[{kpi_id, rating, comments}]');
            $table->decimal('overall_rating', 4, 2)->nullable()->comment('Computed weighted average');
            $table->text('self_comments')->nullable()->comment('Overall self-assessment comment');
            $table->text('reviewer_comments')->nullable()->comment('Overall reviewer comment');
            $table->text('hr_remarks')->nullable()->comment('HR Manager remarks');
            $table->enum('status', ['draft', 'submitted', 'reviewed', 'finalized'])->default('draft')->comment('Appraisal FSM status');
            $table->timestamp('finalized_at')->nullable()->comment('Finalization timestamp');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['cycle_id', 'employee_id'], 'uq_hrs_appraisal');
            $table->index('cycle_id', 'fk_hrs_appr_cycleid');
            $table->index('employee_id', 'fk_hrs_appr_empid');
            $table->index('reviewer_id', 'fk_hrs_appr_reviewerid');
            $table->foreign('cycle_id', 'fk_hrs_appr_cycleid')->references('id')->on('hrs_appraisal_cycles');
            $table->foreign('employee_id', 'fk_hrs_appr_empid')->references('id')->on('sch_employees');
            $table->foreign('reviewer_id', 'fk_hrs_appr_reviewerid')->references('id')->on('sch_employees');
        });

        // 27. hrs_appraisal_increment_flags
        Schema::create('hrs_appraisal_increment_flags', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('appraisal_id')->comment('FK → hrs_appraisals.id');
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id; denormalised');
            $table->unsignedBigInteger('cycle_id')->comment('FK → hrs_appraisal_cycles.id');
            $table->enum('flag_status', ['pending', 'processed'])->default('pending')->comment('pending / processed');
            $table->timestamp('processed_at')->nullable()->comment('When IncrementService processed this flag');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('appraisal_id', 'fk_hrs_incflag_apprid');
            $table->index('employee_id', 'fk_hrs_incflag_empid');
            $table->index('cycle_id', 'fk_hrs_incflag_cycleid');
            $table->index('flag_status', 'idx_hrs_incflag_status');
            $table->foreign('appraisal_id', 'fk_hrs_incflag_apprid')->references('id')->on('hrs_appraisals');
            $table->foreign('employee_id', 'fk_hrs_incflag_empid')->references('id')->on('sch_employees');
            $table->foreign('cycle_id', 'fk_hrs_incflag_cycleid')->references('id')->on('hrs_appraisal_cycles');
        });

        // 28. pay_payroll_run_details
        Schema::create('pay_payroll_run_details', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('payroll_run_id')->comment('FK → pay_payroll_runs.id');
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->unsignedBigInteger('salary_assignment_id')->comment('FK → hrs_salary_assignments.id (cross-prefix)');
            $table->decimal('lop_days', 4, 1)->default(0)->comment('Confirmed LOP days for this month');
            $table->decimal('gross_pay', 12, 2)->default(0)->comment('Gross before LWP');
            $table->decimal('lwp_deduction', 12, 2)->default(0)->comment('LWP = (gross_monthly/working_days) × lop_days');
            $table->decimal('pf_employee', 10, 2)->default(0)->comment('Employee PF 12%');
            $table->decimal('pf_employer', 10, 2)->default(0)->comment('Employer PF 12%');
            $table->decimal('esi_employee', 10, 2)->default(0)->comment('Employee ESI 0.75%');
            $table->decimal('esi_employer', 10, 2)->default(0)->comment('Employer ESI 3.25%');
            $table->decimal('tds_deducted', 10, 2)->default(0)->comment('Monthly TDS; shortfall carried forward (BR-PAY-006)');
            $table->decimal('pt_deduction', 8, 2)->default(0)->comment('Profession Tax from hrs_pt_slabs');
            $table->decimal('other_deductions', 10, 2)->default(0)->comment('Loan EMI, advance recovery, etc.');
            $table->decimal('total_deductions', 12, 2)->default(0)->comment('Sum of all deductions');
            $table->decimal('net_pay', 12, 2)->default(0)->comment('gross_pay − lwp − total_deductions');
            $table->json('computation_json')->nullable()->comment('Full per-component breakdown for payslip');
            $table->enum('payment_status', ['pending', 'exported', 'paid', 'failed'])->default('pending')->comment('Bank disbursement status');
            $table->boolean('is_override')->default(false)->comment('1 = manually overridden');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['payroll_run_id', 'employee_id'], 'uq_pay_rundetail');
            $table->index('payroll_run_id', 'fk_pay_det_runid');
            $table->index('employee_id', 'fk_pay_det_empid');
            $table->index('salary_assignment_id', 'fk_pay_det_assgnid');
            $table->foreign('payroll_run_id', 'fk_pay_det_runid')->references('id')->on('pay_payroll_runs');
            $table->foreign('employee_id', 'fk_pay_det_empid')->references('id')->on('sch_employees');
            $table->foreign('salary_assignment_id', 'fk_pay_det_assgnid')->references('id')->on('hrs_salary_assignments');
        });

        // 29. pay_increment_policies
        Schema::create('pay_increment_policies', function (Blueprint $table) {
            $table->id();
            $table->string('name', 200)->comment('Policy name e.g. FY2026 Increment Matrix');
            $table->unsignedBigInteger('appraisal_cycle_id')->nullable()->comment('FK → hrs_appraisal_cycles.id; NULL = all cycles');
            $table->decimal('min_rating', 4, 2)->comment('Inclusive lower bound of overall_rating');
            $table->decimal('max_rating', 4, 2)->comment('Inclusive upper bound of overall_rating');
            $table->enum('increment_type', ['percentage', 'flat'])->comment('percentage of CTC or flat INR');
            $table->decimal('increment_value', 8, 2)->comment('% or INR increment amount');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('appraisal_cycle_id', 'fk_pay_incpol_cycleid');
            $table->foreign('appraisal_cycle_id', 'fk_pay_incpol_cycleid')->references('id')->on('hrs_appraisal_cycles');
        });

        // =====================================================================
        // LAYER 6 — Depends on Layer 5 (4 tables)
        // =====================================================================

        // 30. pay_payroll_overrides
        Schema::create('pay_payroll_overrides', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('run_detail_id')->comment('FK → pay_payroll_run_details.id');
            $table->string('field_name', 50)->comment('Column overridden e.g. net_pay, tds_deducted');
            $table->decimal('original_value', 12, 2)->comment('Value before override');
            $table->decimal('override_value', 12, 2)->comment('Value after override');
            $table->text('reason')->comment('Mandatory explanation (BR-PAY-005)');
            $table->unsignedInteger('overridden_by')->comment('FK → sch_employees.id; Payroll Manager');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->index('run_detail_id', 'fk_pay_ovr_detid');
            $table->index('overridden_by', 'fk_pay_ovr_by');
            $table->foreign('run_detail_id', 'fk_pay_ovr_detid')->references('id')->on('pay_payroll_run_details');
            $table->foreign('overridden_by', 'fk_pay_ovr_by')->references('id')->on('sch_employees');
        });

        // 31. pay_payslips
        Schema::create('pay_payslips', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('run_detail_id')->comment('FK → pay_payroll_run_details.id (UNIQUE)');
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id; denormalised');
            $table->string('payroll_month', 7)->comment('YYYY-MM — denormalised');
            $table->unsignedBigInteger('media_id')->comment('FK → sys_media.id; password-protected PDF');
            $table->timestamp('generated_at')->useCurrent()->comment('Payslip generation timestamp');
            $table->enum('email_status', ['not_sent', 'pending', 'sent', 'failed'])->default('not_sent')->comment('Email dispatch status');
            $table->timestamp('email_sent_at')->nullable()->comment('Email sent timestamp');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique('run_detail_id', 'uq_pay_payslip_detail');
            $table->index('run_detail_id', 'fk_pay_pslip_detid');
            $table->index('employee_id', 'fk_pay_pslip_empid');
            $table->index('media_id', 'fk_pay_pslip_mediaid');
            $table->foreign('run_detail_id', 'fk_pay_pslip_detid')->references('id')->on('pay_payroll_run_details');
            $table->foreign('employee_id', 'fk_pay_pslip_empid')->references('id')->on('sch_employees');
            $table->foreign('media_id', 'fk_pay_pslip_mediaid')->references('id')->on('sys_media');
        });

        // 32. pay_tds_ledger
        Schema::create('pay_tds_ledger', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->string('financial_year', 7)->comment('Financial year YYYY-YY e.g. 2025-26');
            $table->unsignedTinyInteger('month')->comment('Month 1-12');
            $table->decimal('gross_pay', 12, 2)->default(0)->comment('Gross for this month');
            $table->decimal('tds_deducted', 10, 2)->default(0)->comment('TDS deducted this month');
            $table->decimal('ytd_gross', 14, 2)->default(0)->comment('Year-to-date cumulative gross');
            $table->decimal('ytd_tds', 12, 2)->default(0)->comment('Year-to-date cumulative TDS');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['employee_id', 'financial_year', 'month'], 'uq_pay_tds');
            $table->index('employee_id', 'fk_pay_tds_empid');
            $table->foreign('employee_id', 'fk_pay_tds_empid')->references('id')->on('sch_employees');
        });

        // 33. pay_form16
        Schema::create('pay_form16', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('employee_id')->comment('FK → sch_employees.id');
            $table->string('financial_year', 7)->comment('Financial year YYYY-YY');
            $table->unsignedBigInteger('media_id')->comment('FK → sys_media.id; Form 16 PDF');
            $table->timestamp('generated_at')->useCurrent()->comment('Generation timestamp');
            $table->unsignedInteger('generated_by')->comment('FK → sch_employees.id; Payroll Manager');
            $table->boolean('is_active')->default(true)->comment('Soft enable/disable');
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['employee_id', 'financial_year'], 'uq_pay_form16');
            $table->index('employee_id', 'fk_pay_form16_empid');
            $table->index('media_id', 'fk_pay_form16_mediaid');
            $table->index('generated_by', 'fk_pay_form16_genby');
            $table->foreign('employee_id', 'fk_pay_form16_empid')->references('id')->on('sch_employees');
            $table->foreign('media_id', 'fk_pay_form16_mediaid')->references('id')->on('sys_media');
            $table->foreign('generated_by', 'fk_pay_form16_genby')->references('id')->on('sch_employees');
        });
    }

    public function down(): void
    {
        // Drop in reverse dependency order (Layer 6 → Layer 1)
        Schema::dropIfExists('pay_form16');
        Schema::dropIfExists('pay_tds_ledger');
        Schema::dropIfExists('pay_payslips');
        Schema::dropIfExists('pay_payroll_overrides');
        Schema::dropIfExists('pay_increment_policies');
        Schema::dropIfExists('pay_payroll_run_details');
        Schema::dropIfExists('hrs_appraisal_increment_flags');
        Schema::dropIfExists('hrs_appraisals');
        Schema::dropIfExists('hrs_leave_approvals');
        Schema::dropIfExists('hrs_leave_balance_adjustments');
        Schema::dropIfExists('hrs_esi_contribution_register');
        Schema::dropIfExists('hrs_pf_contribution_register');
        Schema::dropIfExists('pay_payroll_runs');
        Schema::dropIfExists('hrs_leave_applications');
        Schema::dropIfExists('hrs_leave_balances');
        Schema::dropIfExists('hrs_appraisal_cycles');
        Schema::dropIfExists('hrs_salary_assignments');
        Schema::dropIfExists('hrs_lop_records');
        Schema::dropIfExists('hrs_compliance_records');
        Schema::dropIfExists('hrs_holiday_calendars');
        Schema::dropIfExists('hrs_leave_policies');
        Schema::dropIfExists('hrs_employee_documents');
        Schema::dropIfExists('hrs_employment_history');
        Schema::dropIfExists('hrs_employment_details');
        Schema::dropIfExists('pay_salary_structure_components');
        Schema::dropIfExists('hrs_kpi_template_items');
        Schema::dropIfExists('pay_salary_structures');
        Schema::dropIfExists('pay_salary_components');
        Schema::dropIfExists('hrs_pt_slabs');
        Schema::dropIfExists('hrs_pay_grades');
        Schema::dropIfExists('hrs_id_card_templates');
        Schema::dropIfExists('hrs_leave_types');
        Schema::dropIfExists('hrs_kpi_templates');
    }
};
