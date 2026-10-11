<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * ADM — Admission Management Module Migration
 * Path: database/migrations/tenant/2026_03_27_000000_create_adm_tables.php
 *
 * 20 tables across 9 dependency layers.
 * Tenant migration — run via: php artisan tenants:migrate
 * No tenant_id columns (database-per-tenant via stancl/tenancy v3.9).
 */
return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No adm_* dependencies
        // =====================================================================

        Schema::create('adm_admission_cycles', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('academic_session_id')->comment('FK → sch_org_academic_sessions_jnt.id');
            $table->string('name', 100);
            $table->string('cycle_code', 20)->unique();
            $table->date('start_date');
            $table->date('end_date');
            $table->decimal('application_fee', 10, 2)->default(0.00);
            $table->string('admission_no_format', 100)->nullable()->default('{YEAR}/{SEQ}');
            $table->unsignedTinyInteger('sibling_bonus_score')->default(5);
            $table->json('age_rules_json')->nullable();
            $table->json('refund_policy_json')->nullable();
            $table->string('application_form_url', 255)->nullable();
            $table->enum('status', ['Draft', 'Active', 'Closed', 'Archived'])->default('Draft');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('academic_session_id', 'idx_adm_cyc_session');
            $table->index('status', 'idx_adm_cyc_status');
            $table->foreign('academic_session_id', 'fk_adm_cyc_session_id')
                  ->references('id')->on('sch_org_academic_sessions_jnt')
                  ->onDelete('restrict')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 2 — Depends on adm_admission_cycles + sch_classes
        // =====================================================================

        Schema::create('adm_document_checklist', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('admission_cycle_id')->nullable()->comment('NULL = global template row (is_system=1)');
            $table->unsignedInteger('class_id')->nullable()->comment('NULL = applies to all classes');
            $table->string('document_name', 100);
            $table->string('document_code', 30);
            $table->tinyInteger('is_mandatory')->default(1);
            $table->tinyInteger('is_system')->default(0);
            $table->string('accepted_formats', 100)->default('pdf,jpg,png');
            $table->unsignedInteger('max_size_kb')->default(5120);
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('admission_cycle_id', 'idx_adm_chk_cycle');
            $table->index('class_id', 'idx_adm_chk_class');
            $table->foreign('admission_cycle_id', 'fk_adm_chk_cycle_id')
                  ->references('id')->on('adm_admission_cycles')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('class_id', 'fk_adm_chk_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_quota_config', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('admission_cycle_id');
            $table->unsignedInteger('class_id');
            $table->enum('quota_type', ['General', 'Government', 'Management', 'RTE', 'NRI', 'Staff_Ward', 'Sibling', 'EWS']);
            $table->unsignedSmallInteger('total_seats');
            $table->unsignedSmallInteger('reserved_seats')->default(0);
            $table->tinyInteger('application_fee_waiver')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['admission_cycle_id', 'class_id'], 'idx_adm_qcfg_cycle_class');
            $table->index('quota_type', 'idx_adm_qcfg_quota');
            $table->foreign('admission_cycle_id', 'fk_adm_qcfg_cycle_id')
                  ->references('id')->on('adm_admission_cycles')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('class_id', 'fk_adm_qcfg_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
        });

        Schema::create('adm_seat_capacity', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('admission_cycle_id');
            $table->unsignedInteger('class_id');
            $table->enum('quota_type', ['General', 'Government', 'Management', 'RTE', 'NRI', 'Staff_Ward', 'Sibling', 'EWS']);
            $table->unsignedSmallInteger('total_seats');
            $table->unsignedSmallInteger('seats_allotted')->default(0);
            $table->unsignedSmallInteger('seats_enrolled')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['admission_cycle_id', 'class_id', 'quota_type'], 'uq_adm_sc_cycle_class_quota');
            $table->index('admission_cycle_id', 'idx_adm_sc_cycle');
            $table->index('class_id', 'idx_adm_sc_class');
            $table->foreign('admission_cycle_id', 'fk_adm_sc_cycle_id')
                  ->references('id')->on('adm_admission_cycles')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('class_id', 'fk_adm_sc_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
        });

        Schema::create('adm_entrance_tests', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('admission_cycle_id');
            $table->unsignedInteger('class_id');
            $table->string('test_name', 100);
            $table->date('test_date');
            $table->time('start_time');
            $table->time('end_time');
            $table->string('venue', 100)->nullable();
            $table->decimal('max_marks', 6, 2);
            $table->decimal('passing_marks', 6, 2)->nullable();
            $table->json('subjects_json')->nullable();
            $table->enum('status', ['Scheduled', 'Completed', 'Cancelled'])->default('Scheduled');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['admission_cycle_id', 'class_id'], 'idx_adm_et_cycle_class');
            $table->index('test_date', 'idx_adm_et_date');
            $table->index('status', 'idx_adm_et_status');
            $table->foreign('admission_cycle_id', 'fk_adm_et_cycle_id')
                  ->references('id')->on('adm_admission_cycles')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('class_id', 'fk_adm_et_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 3 — Depends on Layer 1 + cross-module (std_students, sys_users)
        // =====================================================================

        Schema::create('adm_enquiries', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('admission_cycle_id');
            $table->string('enquiry_no', 20)->unique();
            $table->string('student_name', 100);
            $table->date('student_dob')->nullable();
            $table->enum('student_gender', ['Male', 'Female', 'Transgender', 'Other'])->nullable();
            $table->unsignedInteger('class_sought_id');
            $table->string('father_name', 100)->nullable();
            $table->string('mother_name', 100)->nullable();
            $table->string('contact_name', 100);
            $table->string('contact_mobile', 15);
            $table->string('contact_email', 100)->nullable();
            $table->enum('lead_source', ['Website', 'Walk-in', 'Campaign', 'Referral', 'Social_Media', 'Phone', 'Other'])->default('Walk-in');
            $table->enum('status', ['New', 'Assigned', 'Contacted', 'Interested', 'Not_Interested', 'Callback', 'Converted', 'Duplicate'])->default('New');
            $table->unsignedInteger('counselor_id')->nullable();
            $table->tinyInteger('is_sibling_lead')->default(0);
            $table->unsignedInteger('sibling_student_id')->nullable();
            $table->tinyInteger('is_duplicate')->default(0);
            $table->text('notes')->nullable();
            $table->string('source_reference', 100)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('admission_cycle_id', 'idx_adm_enq_cycle');
            $table->index('status', 'idx_adm_enq_status');
            $table->index('counselor_id', 'idx_adm_enq_counselor');
            $table->index('contact_mobile', 'idx_adm_enq_mobile');
            $table->index('sibling_student_id', 'idx_adm_enq_sibling');
            $table->index('class_sought_id', 'idx_adm_enq_class_sought');
            $table->foreign('admission_cycle_id', 'fk_adm_enq_cycle_id')
                  ->references('id')->on('adm_admission_cycles')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('class_sought_id', 'fk_adm_enq_class_sought_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('counselor_id', 'fk_adm_enq_counselor_id')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('sibling_student_id', 'fk_adm_enq_sibling_student_id')
                  ->references('id')->on('std_students')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_merit_lists', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('admission_cycle_id');
            $table->unsignedInteger('class_id');
            $table->enum('quota_type', ['General', 'Government', 'Management', 'RTE', 'NRI', 'Staff_Ward', 'Sibling', 'EWS']);
            $table->timestamp('generated_at')->nullable();
            $table->unsignedInteger('generated_by')->nullable();
            $table->enum('status', ['Draft', 'Published', 'Finalized'])->default('Draft');
            $table->json('criteria_json')->nullable()->comment('{"test_pct":40,"interview_pct":30,"academic_pct":30} — must sum to 100');
            $table->unsignedTinyInteger('sibling_bonus_score')->default(5);
            $table->decimal('cutoff_score', 6, 2)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['admission_cycle_id', 'class_id', 'quota_type'], 'idx_adm_ml_cycle_class_quota');
            $table->index('status', 'idx_adm_ml_status');
            $table->index('generated_by', 'idx_adm_ml_generated_by');
            $table->foreign('admission_cycle_id', 'fk_adm_ml_cycle_id')
                  ->references('id')->on('adm_admission_cycles')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('class_id', 'fk_adm_ml_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('generated_by', 'fk_adm_ml_generated_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 4 — Depends on Layer 3 + cross-module
        // =====================================================================

        Schema::create('adm_follow_ups', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('enquiry_id');
            $table->enum('follow_up_type', ['Call', 'Meeting', 'Email', 'SMS', 'Walk-in']);
            $table->dateTime('scheduled_at');
            $table->dateTime('completed_at')->nullable();
            $table->enum('outcome', ['Pending', 'Interested', 'Not_Interested', 'Callback', 'Converted'])->default('Pending');
            $table->text('notes')->nullable();
            $table->unsignedInteger('done_by')->nullable();
            $table->tinyInteger('reminder_sent')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('enquiry_id', 'idx_adm_fu_enquiry');
            $table->index('scheduled_at', 'idx_adm_fu_scheduled');
            $table->index('done_by', 'idx_adm_fu_done_by');
            $table->index('outcome', 'idx_adm_fu_outcome');
            $table->foreign('enquiry_id', 'fk_adm_fu_enquiry_id')
                  ->references('id')->on('adm_enquiries')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('done_by', 'fk_adm_fu_done_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_applications', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('admission_cycle_id');
            $table->unsignedBigInteger('enquiry_id')->nullable()->comment('NULL = direct application without prior enquiry');
            $table->string('application_no', 20)->unique();
            $table->unsignedInteger('class_applied_id');
            $table->enum('quota_type', ['General', 'Government', 'Management', 'RTE', 'NRI', 'Staff_Ward', 'Sibling', 'EWS'])->default('General');
            $table->tinyInteger('is_sibling')->default(0)->comment('1 = staff-confirmed; required for sibling merit bonus (BR-ADM-015)');
            $table->unsignedInteger('sibling_student_id')->nullable();
            $table->tinyInteger('is_staff_ward')->default(0);
            // Student Details
            $table->string('student_first_name', 50);
            $table->string('student_middle_name', 50)->nullable();
            $table->string('student_last_name', 50)->nullable();
            $table->date('student_dob');
            $table->enum('student_gender', ['Male', 'Female', 'Transgender', 'Prefer Not to Say']);
            $table->string('student_religion', 50)->nullable();
            $table->enum('student_caste_category', ['General', 'OBC', 'SC', 'ST', 'EWS', 'Other'])->nullable();
            $table->string('student_nationality', 50)->nullable()->default('Indian');
            $table->string('student_mother_tongue', 50)->nullable();
            $table->string('aadhar_no', 20)->nullable()->comment('Uniqueness enforced at SERVICE LAYER ONLY — not DB UNIQUE');
            $table->string('birth_cert_no', 50)->nullable();
            $table->enum('blood_group', ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'])->nullable();
            $table->text('known_allergies')->nullable();
            // Previous School
            $table->string('prev_school_name', 100)->nullable();
            $table->string('prev_class_passed', 20)->nullable();
            $table->decimal('prev_marks_percent', 5, 2)->nullable();
            $table->string('prev_tc_no', 50)->nullable();
            // Guardian Details
            $table->string('father_name', 100)->nullable();
            $table->string('father_mobile', 15)->nullable();
            $table->string('father_email', 100)->nullable();
            $table->string('father_occupation', 100)->nullable();
            $table->string('mother_name', 100)->nullable();
            $table->string('mother_mobile', 15)->nullable();
            $table->string('mother_email', 100)->nullable();
            $table->string('guardian_name', 100)->nullable();
            $table->string('guardian_mobile', 15)->nullable();
            $table->string('guardian_relation', 50)->nullable();
            // Address
            $table->string('address_line1', 150)->nullable();
            $table->string('address_line2', 150)->nullable();
            $table->string('city', 50)->nullable();
            $table->string('state', 50)->nullable();
            $table->string('pincode', 10)->nullable();
            // Fee
            $table->tinyInteger('application_fee_paid')->default(0)->comment('1 = confirmed; PAY webhook sets this');
            $table->decimal('application_fee_amount', 10, 2)->nullable();
            $table->date('application_fee_date')->nullable();
            // Interview
            $table->dateTime('interview_scheduled_at')->nullable();
            $table->string('interview_venue', 100)->nullable();
            $table->text('interview_notes')->nullable();
            $table->decimal('interview_score', 5, 2)->nullable();
            // Status
            $table->enum('status', ['Draft', 'Submitted', 'Under_Review', 'Verified', 'Shortlisted', 'Rejected', 'Waitlisted', 'Allotted', 'Enrolled', 'Withdrawn'])->default('Draft');
            $table->text('rejection_reason')->nullable();
            $table->unsignedInteger('processed_by')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('admission_cycle_id', 'idx_adm_app_cycle');
            $table->index('status', 'idx_adm_app_status');
            $table->index('class_applied_id', 'idx_adm_app_class');
            $table->index('enquiry_id', 'idx_adm_app_enquiry');
            $table->index('sibling_student_id', 'idx_adm_app_sibling');
            $table->index('processed_by', 'idx_adm_app_processed_by');
            $table->index('aadhar_no', 'idx_adm_app_aadhar');
            $table->foreign('admission_cycle_id', 'fk_adm_app_cycle_id')
                  ->references('id')->on('adm_admission_cycles')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('enquiry_id', 'fk_adm_app_enquiry_id')
                  ->references('id')->on('adm_enquiries')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('class_applied_id', 'fk_adm_app_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('sibling_student_id', 'fk_adm_app_sibling_student_id')
                  ->references('id')->on('std_students')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('processed_by', 'fk_adm_app_processed_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 5 — Depends on Layer 4 + adm_entrance_tests + adm_merit_lists
        // =====================================================================

        Schema::create('adm_application_documents', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('application_id');
            $table->unsignedBigInteger('checklist_item_id');
            $table->unsignedInteger('media_id')->comment('sys_media uses INT UNSIGNED (not BIGINT)');
            $table->string('original_filename', 255);
            $table->enum('verification_status', ['Pending', 'Verified', 'Rejected'])->default('Pending');
            $table->text('verification_remarks')->nullable();
            $table->unsignedInteger('verified_by')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->tinyInteger('is_physically_received')->default(0);
            $table->date('physical_received_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['application_id', 'checklist_item_id'], 'uq_adm_doc_app_checklist');
            $table->index('application_id', 'idx_adm_doc_app');
            $table->index('checklist_item_id', 'idx_adm_doc_checklist');
            $table->index('media_id', 'idx_adm_doc_media');
            $table->index('verified_by', 'idx_adm_doc_verified_by');
            $table->index('verification_status', 'idx_adm_doc_vstatus');
            $table->foreign('application_id', 'fk_adm_doc_application_id')
                  ->references('id')->on('adm_applications')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('checklist_item_id', 'fk_adm_doc_checklist_id')
                  ->references('id')->on('adm_document_checklist')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('media_id', 'fk_adm_doc_media_id')
                  ->references('id')->on('sys_media')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('verified_by', 'fk_adm_doc_verified_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_application_stages', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('application_id');
            $table->string('from_status', 50);
            $table->string('to_status', 50);
            $table->text('remarks')->nullable();
            $table->unsignedInteger('changed_by')->nullable()->comment('NULL = system-triggered transition');
            $table->timestamp('changed_at')->useCurrent();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('application_id', 'idx_adm_stage_app');
            $table->index('changed_at', 'idx_adm_stage_changed_at');
            $table->index('changed_by', 'idx_adm_stage_changed_by');
            $table->foreign('application_id', 'fk_adm_stage_application_id')
                  ->references('id')->on('adm_applications')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('changed_by', 'fk_adm_stage_changed_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_entrance_test_candidates', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('entrance_test_id');
            $table->unsignedBigInteger('application_id');
            $table->string('roll_no', 20)->nullable();
            $table->decimal('marks_obtained', 6, 2)->nullable();
            $table->enum('result', ['Pass', 'Fail', 'Absent', 'Pending'])->default('Pending');
            $table->json('subject_marks_json')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['entrance_test_id', 'application_id'], 'uq_adm_etc_test_app');
            $table->index('entrance_test_id', 'idx_adm_etc_test');
            $table->index('application_id', 'idx_adm_etc_app');
            $table->index('result', 'idx_adm_etc_result');
            $table->foreign('entrance_test_id', 'fk_adm_etc_test_id')
                  ->references('id')->on('adm_entrance_tests')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('application_id', 'fk_adm_etc_application_id')
                  ->references('id')->on('adm_applications')
                  ->onDelete('cascade')->onUpdate('cascade');
        });

        Schema::create('adm_merit_list_entries', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('merit_list_id');
            $table->unsignedBigInteger('application_id');
            $table->unsignedSmallInteger('merit_rank');
            $table->decimal('composite_score', 6, 2)->nullable();
            $table->decimal('entrance_score', 6, 2)->nullable();
            $table->decimal('interview_score', 6, 2)->nullable();
            $table->decimal('academic_score', 6, 2)->nullable();
            $table->tinyInteger('sibling_bonus_applied')->default(0)->comment('1 = sibling bonus added; requires is_sibling=1 on application');
            $table->enum('merit_status', ['Shortlisted', 'Waitlisted', 'Rejected'])->default('Shortlisted');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('merit_list_id', 'idx_adm_mle_list');
            $table->index(['merit_list_id', 'merit_rank'], 'idx_adm_mle_rank');
            $table->index('application_id', 'idx_adm_mle_app');
            $table->index('merit_status', 'idx_adm_mle_status');
            $table->index('composite_score', 'idx_adm_mle_score');
            $table->foreign('merit_list_id', 'fk_adm_mle_merit_list_id')
                  ->references('id')->on('adm_merit_lists')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('application_id', 'fk_adm_mle_application_id')
                  ->references('id')->on('adm_applications')
                  ->onDelete('restrict')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 6 — Depends on Layer 5 + sch_sections, sch_org_academic_sessions_jnt
        // =====================================================================

        Schema::create('adm_allotments', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('merit_list_entry_id');
            $table->unsignedBigInteger('application_id');
            $table->string('admission_no', 50)->nullable()->unique()->comment('NULL until offer letter issued; MySQL UNIQUE allows multiple NULLs');
            $table->unsignedInteger('allotted_class_id');
            $table->unsignedInteger('allotted_section_id')->nullable()->comment('NULL before section assignment');
            $table->date('joining_date')->nullable();
            $table->unsignedInteger('offer_letter_media_id')->nullable()->comment('sys_media uses INT UNSIGNED');
            $table->timestamp('offer_issued_at')->nullable();
            $table->date('offer_expires_at')->nullable()->comment('adm:expire-offers daily job checks this (BR-ADM-014)');
            $table->tinyInteger('admission_fee_paid')->default(0)->comment('Required before enrollment (BR-ADM-002)');
            $table->decimal('admission_fee_amount', 10, 2)->nullable();
            $table->date('admission_fee_date')->nullable();
            $table->enum('status', ['Offered', 'Accepted', 'Declined', 'Expired', 'Enrolled', 'Withdrawn'])->default('Offered');
            $table->unsignedInteger('enrolled_student_id')->nullable()->comment('std_students uses INT UNSIGNED; SET ON ENROLLMENT by EnrollmentService');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('merit_list_entry_id', 'idx_adm_allot_mle');
            $table->index('application_id', 'idx_adm_allot_app');
            $table->index('status', 'idx_adm_allot_status');
            $table->index('offer_expires_at', 'idx_adm_allot_expires');
            $table->index('enrolled_student_id', 'idx_adm_allot_enrolled_student');
            $table->index('allotted_class_id', 'idx_adm_allot_class');
            $table->index('allotted_section_id', 'idx_adm_allot_section');
            $table->index('offer_letter_media_id', 'idx_adm_allot_offer_media');
            $table->foreign('merit_list_entry_id', 'fk_adm_allot_mle_id')
                  ->references('id')->on('adm_merit_list_entries')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('application_id', 'fk_adm_allot_application_id')
                  ->references('id')->on('adm_applications')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('allotted_class_id', 'fk_adm_allot_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('allotted_section_id', 'fk_adm_allot_section_id')
                  ->references('id')->on('sch_sections')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('offer_letter_media_id', 'fk_adm_allot_offer_media_id')
                  ->references('id')->on('sys_media')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('enrolled_student_id', 'fk_adm_allot_enrolled_student_id')
                  ->references('id')->on('std_students')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_promotion_batches', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('from_session_id');
            $table->unsignedInteger('to_session_id');
            $table->unsignedInteger('from_class_id');
            $table->unsignedInteger('to_class_id');
            $table->json('criteria_json')->nullable()->comment('e.g., {"min_pass_pct":33,"use_exam_results":true}');
            $table->unsignedInteger('total_students')->default(0);
            $table->unsignedInteger('promoted_count')->default(0);
            $table->unsignedInteger('detained_count')->default(0);
            $table->enum('status', ['Draft', 'Confirmed'])->default('Draft');
            $table->unsignedInteger('processed_by')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('from_session_id', 'idx_adm_pb_from_session');
            $table->index(['from_session_id', 'from_class_id', 'status'], 'idx_adm_pb_status');
            $table->index('to_session_id', 'idx_adm_pb_to_session');
            $table->index('from_class_id', 'idx_adm_pb_from_class');
            $table->index('to_class_id', 'idx_adm_pb_to_class');
            $table->index('processed_by', 'idx_adm_pb_processed_by');
            $table->foreign('from_session_id', 'fk_adm_pb_from_session_id')
                  ->references('id')->on('sch_org_academic_sessions_jnt')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('to_session_id', 'fk_adm_pb_to_session_id')
                  ->references('id')->on('sch_org_academic_sessions_jnt')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('from_class_id', 'fk_adm_pb_from_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('to_class_id', 'fk_adm_pb_to_class_id')
                  ->references('id')->on('sch_classes')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('processed_by', 'fk_adm_pb_processed_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 7 — Depends on Layer 6 + sch_class_section_jnt
        // =====================================================================

        Schema::create('adm_withdrawals', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('application_id');
            $table->unsignedBigInteger('allotment_id')->nullable()->comment('NULL = withdrawal before allotment');
            $table->date('withdrawal_date');
            $table->enum('reason', ['Personal', 'Financial', 'Relocation', 'School_Change', 'Medical', 'Other']);
            $table->text('remarks')->nullable();
            $table->decimal('fee_paid_amount', 10, 2)->default(0.00);
            $table->decimal('refund_eligible_amount', 10, 2)->default(0.00)->comment('Computed from adm_admission_cycles.refund_policy_json at withdrawal time');
            $table->enum('refund_status', ['Not_Eligible', 'Pending', 'Approved', 'Paid'])->default('Not_Eligible');
            $table->date('refund_processed_at')->nullable();
            $table->unsignedInteger('processed_by')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('application_id', 'idx_adm_wd_app');
            $table->index('allotment_id', 'idx_adm_wd_allotment');
            $table->index('refund_status', 'idx_adm_wd_refund_status');
            $table->index('processed_by', 'idx_adm_wd_processed_by');
            $table->foreign('application_id', 'fk_adm_wd_application_id')
                  ->references('id')->on('adm_applications')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('allotment_id', 'fk_adm_wd_allotment_id')
                  ->references('id')->on('adm_allotments')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('processed_by', 'fk_adm_wd_processed_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_promotion_records', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('promotion_batch_id');
            $table->unsignedInteger('student_id');
            $table->unsignedInteger('from_class_section_id');
            $table->unsignedInteger('to_class_section_id')->nullable()->comment('NULL if detained/left — no section assigned yet');
            $table->unsignedSmallInteger('new_roll_no')->nullable();
            $table->enum('result', ['Promoted', 'Detained', 'Transferred', 'Alumni', 'Left']);
            $table->text('remarks')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('promotion_batch_id', 'idx_adm_pr_batch');
            $table->index(['promotion_batch_id', 'student_id'], 'idx_adm_pr_student');
            $table->index('student_id', 'idx_adm_pr_student_id');
            $table->index('from_class_section_id', 'idx_adm_pr_from_section');
            $table->index('to_class_section_id', 'idx_adm_pr_to_section');
            $table->foreign('promotion_batch_id', 'fk_adm_pr_batch_id')
                  ->references('id')->on('adm_promotion_batches')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('student_id', 'fk_adm_pr_student_id')
                  ->references('id')->on('std_students')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('from_class_section_id', 'fk_adm_pr_from_class_section_id')
                  ->references('id')->on('sch_class_section_jnt')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('to_class_section_id', 'fk_adm_pr_to_class_section_id')
                  ->references('id')->on('sch_class_section_jnt')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 8 — Depends on std_students (cross-module); parallel install OK
        // =====================================================================

        Schema::create('adm_transfer_certificates', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->string('tc_number', 30)->unique();
            $table->date('issue_date');
            $table->date('leaving_date');
            $table->string('class_at_leaving', 30);
            $table->text('reason_for_leaving')->nullable();
            $table->enum('conduct', ['Excellent', 'Good', 'Satisfactory', 'Poor'])->default('Good');
            $table->string('destination_school', 150)->nullable();
            $table->string('academic_status', 100)->nullable();
            $table->tinyInteger('fees_cleared')->default(0)->comment('FIN module must confirm no outstanding balance (BR-ADM-004)');
            $table->tinyInteger('is_duplicate')->default(0);
            $table->unsignedBigInteger('original_tc_id')->nullable()->comment('Self-reference: BIGINT UNSIGNED to match adm_transfer_certificates.id PK');
            $table->unsignedInteger('media_id')->nullable()->comment('sys_media uses INT UNSIGNED; TC PDF with QR code');
            $table->unsignedInteger('issued_by')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('student_id', 'idx_adm_tc_student');
            $table->index('issue_date', 'idx_adm_tc_issue_date');
            $table->index('original_tc_id', 'idx_adm_tc_original');
            $table->index('media_id', 'idx_adm_tc_media');
            $table->index('issued_by', 'idx_adm_tc_issued_by');
            $table->foreign('student_id', 'fk_adm_tc_student_id')
                  ->references('id')->on('std_students')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('original_tc_id', 'fk_adm_tc_original_tc_id')
                  ->references('id')->on('adm_transfer_certificates')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('media_id', 'fk_adm_tc_media_id')
                  ->references('id')->on('sys_media')
                  ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('issued_by', 'fk_adm_tc_issued_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('adm_behavior_incidents', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->date('incident_date');
            $table->enum('incident_type', ['Bullying', 'Cheating', 'Disruption', 'Absenteeism', 'Vandalism', 'Violence', 'Misconduct', 'Other']);
            $table->enum('severity', ['Low', 'Medium', 'High', 'Critical'])->comment('Critical = auto NTF to principal + parent');
            $table->text('description');
            $table->string('location', 100)->nullable();
            $table->json('witnesses_json')->nullable();
            $table->unsignedInteger('reported_by')->nullable();
            $table->tinyInteger('parent_notified')->default(0);
            $table->timestamp('parent_notified_at')->nullable();
            $table->enum('status', ['Open', 'Action_Taken', 'Closed', 'Escalated'])->default('Open');
            $table->tinyInteger('behavior_score_impact')->default(0)->comment('Signed TINYINT — negative = deduction; e.g., -5 Medium, -15 Critical');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['student_id', 'incident_date'], 'idx_adm_bi_student_date');
            $table->index('severity', 'idx_adm_bi_severity');
            $table->index('status', 'idx_adm_bi_status');
            $table->index('reported_by', 'idx_adm_bi_reported_by');
            $table->foreign('student_id', 'fk_adm_bi_student_id')
                  ->references('id')->on('std_students')
                  ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('reported_by', 'fk_adm_bi_reported_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 9 — Depends on Layer 8
        // =====================================================================

        Schema::create('adm_behavior_actions', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('incident_id');
            $table->enum('action_type', ['Warning', 'Detention', 'Suspension', 'Expulsion', 'Parent_Meeting', 'Counseling', 'Community_Service']);
            $table->text('description')->nullable();
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->dateTime('parent_meeting_date')->nullable();
            $table->text('meeting_outcome')->nullable();
            $table->unsignedInteger('action_by')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('incident_id', 'idx_adm_ba_incident');
            $table->index('action_by', 'idx_adm_ba_action_by');
            $table->index('action_type', 'idx_adm_ba_action_type');
            $table->foreign('incident_id', 'fk_adm_ba_incident_id')
                  ->references('id')->on('adm_behavior_incidents')
                  ->onDelete('cascade')->onUpdate('cascade');
            $table->foreign('action_by', 'fk_adm_ba_action_by')
                  ->references('id')->on('sys_users')
                  ->onDelete('set null')->onUpdate('cascade');
        });
    }

    public function down(): void
    {
        // Drop in reverse dependency order (Layer 9 → 1)
        Schema::disableForeignKeyConstraints();

        Schema::dropIfExists('adm_behavior_actions');         // Layer 9
        Schema::dropIfExists('adm_behavior_incidents');       // Layer 8
        Schema::dropIfExists('adm_transfer_certificates');    // Layer 8
        Schema::dropIfExists('adm_promotion_records');        // Layer 7
        Schema::dropIfExists('adm_withdrawals');              // Layer 7
        Schema::dropIfExists('adm_allotments');               // Layer 6
        Schema::dropIfExists('adm_promotion_batches');        // Layer 6
        Schema::dropIfExists('adm_merit_list_entries');       // Layer 5
        Schema::dropIfExists('adm_entrance_test_candidates'); // Layer 5
        Schema::dropIfExists('adm_application_stages');       // Layer 5
        Schema::dropIfExists('adm_application_documents');    // Layer 5
        Schema::dropIfExists('adm_applications');             // Layer 4
        Schema::dropIfExists('adm_follow_ups');               // Layer 4
        Schema::dropIfExists('adm_merit_lists');              // Layer 3
        Schema::dropIfExists('adm_enquiries');                // Layer 3
        Schema::dropIfExists('adm_entrance_tests');           // Layer 2
        Schema::dropIfExists('adm_seat_capacity');            // Layer 2
        Schema::dropIfExists('adm_quota_config');             // Layer 2
        Schema::dropIfExists('adm_document_checklist');       // Layer 2
        Schema::dropIfExists('adm_admission_cycles');         // Layer 1

        Schema::enableForeignKeyConstraints();
    }
};
