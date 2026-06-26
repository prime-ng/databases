<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * CRT — Certificate & Template Module
 * Creates all 10 crt_* tables in Layer 1 → Layer 5 dependency order.
 * Also adds std_students.tc_issued (required by BR-CRT-011).
 *
 * FK type corrections (verified against tenant_db_v2.sql):
 *   sys_users.id                     → unsignedInteger()      (INT UNSIGNED)
 *   std_students.id                  → unsignedInteger()      (INT UNSIGNED)
 *   sys_media.id                     → unsignedInteger()      (INT UNSIGNED)
 *   sys_dropdown_table.id            → unsignedInteger()      (INT UNSIGNED)
 *   sch_org_academic_sessions_jnt.id → unsignedSmallInteger() (SMALLINT UNSIGNED)
 *   crt_* PKs                        → unsignedInteger()      (INT UNSIGNED)
 *
 * Note: Phase 2 prompt template specifies BIGINT UNSIGNED — not used here.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();

        // ===================================================================
        // LAYER 1 — No crt_* dependencies
        // ===================================================================

        // Table 1: crt_certificate_types
        Schema::create('crt_certificate_types', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->string('name', 150)->comment('Display name e.g. Bonafide Certificate');
            $table->string('code', 10)->unique('uq_crt_ct_code')->comment('Unique short code e.g. BON, TC, CHR');
            $table->enum('category', ['administrative', 'legal', 'character', 'achievement', 'identity'])
                  ->comment('Type category');
            $table->tinyInteger('requires_approval')->default(1)
                  ->comment('1 = approval workflow required; 0 = auto-approve on submission');
            $table->unsignedSmallInteger('validity_days')->nullable()
                  ->comment('Certificate validity in days; NULL = no expiry');
            $table->string('serial_format', 100)->default('{TYPE_CODE}-{YYYY}-{SEQ6}')
                  ->comment('Serial number format tokens: {TYPE_CODE},{YYYY},{YY},{SEQ4},{SEQ6}');
            $table->text('description')->nullable()->comment('Admin notes or description');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('is_active', 'idx_crt_ct_is_active');
            $table->index('category', 'idx_crt_ct_category');
            $table->index('created_by', 'idx_crt_ct_created_by');
            $table->index('updated_by', 'idx_crt_ct_updated_by');

            $table->foreign('created_by', 'fk_crt_ct_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_ct_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // Table 2: crt_id_card_configs
        Schema::create('crt_id_card_configs', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->enum('card_type', ['student', 'staff'])->comment('student = Student ID Card; staff = Staff ID Card');
            $table->string('name', 150)->comment('Configuration display name');
            $table->unsignedSmallInteger('academic_session_id')
                  ->comment('sch_org_academic_sessions_jnt.id');
            $table->enum('card_size', ['a5', 'cr80'])->default('cr80')
                  ->comment('a5 = A5 paper; cr80 = credit-card size (85.6 x 54mm)');
            $table->enum('orientation', ['portrait', 'landscape'])->default('portrait')
                  ->comment('Print orientation');
            $table->json('template_json')
                  ->comment('Card layout: field positions, colors, QR placement coordinates');
            $table->unsignedTinyInteger('cards_per_sheet')->default(8)
                  ->comment('Cards per A4 sheet for CR80 layout (1-20)');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('card_type', 'idx_crt_icc_card_type');
            $table->index('academic_session_id', 'idx_crt_icc_academic_session_id');
            $table->index('created_by', 'idx_crt_icc_created_by');
            $table->index('updated_by', 'idx_crt_icc_updated_by');

            $table->foreign('academic_session_id', 'fk_crt_icc_academic_session_id')
                  ->references('id')->on('sch_org_academic_sessions_jnt')->onDelete('restrict');
            $table->foreign('created_by', 'fk_crt_icc_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_icc_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // ===================================================================
        // LAYER 2 — Depends on Layer 1 or external tables
        // ===================================================================

        // Table 3: crt_templates
        Schema::create('crt_templates', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->unsignedInteger('certificate_type_id')
                  ->comment('crt_certificate_types.id');
            $table->string('name', 150)->comment('Template display name');
            $table->longText('template_content')
                  ->comment('Full HTML/CSS body with {{placeholder}} merge fields');
            $table->json('variables_json')
                  ->comment('Declared merge field names array; must match all {{placeholders}} in template_content');
            $table->enum('page_size', ['a4', 'a5', 'letter', 'custom'])->default('a4')
                  ->comment('DomPDF paper size');
            $table->enum('orientation', ['portrait', 'landscape'])->default('portrait')
                  ->comment('DomPDF paper orientation');
            $table->tinyInteger('is_default')->default(0)
                  ->comment('1 = default template for its type; only one per type (application-enforced, BR-CRT-012)');
            $table->json('signature_placement_json')->nullable()
                  ->comment('Optional x/y coordinates + dimensions for digital signature block');
            $table->unsignedSmallInteger('version_no')->default(1)
                  ->comment('Current version number; incremented on each save');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('certificate_type_id', 'idx_crt_tpl_certificate_type_id');
            $table->index('is_default', 'idx_crt_tpl_is_default');
            $table->index('created_by', 'idx_crt_tpl_created_by');
            $table->index('updated_by', 'idx_crt_tpl_updated_by');

            $table->foreign('certificate_type_id', 'fk_crt_tpl_certificate_type_id')
                  ->references('id')->on('crt_certificate_types')->onDelete('cascade');
            $table->foreign('created_by', 'fk_crt_tpl_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_tpl_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // Table 4: crt_serial_counters
        Schema::create('crt_serial_counters', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->unsignedInteger('certificate_type_id')
                  ->comment('crt_certificate_types.id — one counter per type per year');
            $table->unsignedSmallInteger('academic_year')
                  ->comment('4-digit year e.g. 2026; counter resets each academic year');
            $table->unsignedInteger('last_seq_no')->default(0)
                  ->comment('Last issued sequence number; incremented atomically via SELECT FOR UPDATE (BR-CRT-015)');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['certificate_type_id', 'academic_year'], 'uq_crt_sc_type_year');
            $table->index('certificate_type_id', 'idx_crt_sc_certificate_type_id');
            $table->index('created_by', 'idx_crt_sc_created_by');
            $table->index('updated_by', 'idx_crt_sc_updated_by');

            $table->foreign('certificate_type_id', 'fk_crt_sc_certificate_type_id')
                  ->references('id')->on('crt_certificate_types')->onDelete('restrict');
            $table->foreign('created_by', 'fk_crt_sc_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_sc_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // Table 5: crt_bulk_jobs
        Schema::create('crt_bulk_jobs', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->unsignedInteger('certificate_type_id')
                  ->comment('crt_certificate_types.id — type being bulk-generated');
            $table->unsignedInteger('initiated_by')
                  ->comment('sys_users.id — Admin who triggered the bulk job');
            $table->json('filter_json')->nullable()
                  ->comment('Filter criteria: {class_id, section_id, student_ids[]}');
            $table->unsignedInteger('total_count')->default(0)
                  ->comment('Total certificates to generate in this job');
            $table->unsignedInteger('processed_count')->default(0)
                  ->comment('Successfully generated so far');
            $table->unsignedInteger('failed_count')->default(0)
                  ->comment('Individual student failures (batch continues — BR-CRT-009)');
            $table->enum('status', ['queued', 'processing', 'completed', 'failed'])->default('queued')
                  ->comment('Job lifecycle: queued→processing→completed/failed');
            $table->string('zip_path', 500)->nullable()
                  ->comment('Relative path to completed ZIP on storage disk');
            $table->json('error_log_json')->nullable()
                  ->comment('Per-student failure log: [{student_id, student_name, error}]');
            $table->timestamp('started_at')->nullable()
                  ->comment('When queue worker picked up this job');
            $table->timestamp('completed_at')->nullable()
                  ->comment('When job finished (completed or failed)');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('certificate_type_id', 'idx_crt_bj_certificate_type_id');
            $table->index('initiated_by', 'idx_crt_bj_initiated_by');
            $table->index('status', 'idx_crt_bj_status');
            $table->index('created_by', 'idx_crt_bj_created_by');
            $table->index('updated_by', 'idx_crt_bj_updated_by');

            $table->foreign('certificate_type_id', 'fk_crt_bj_certificate_type_id')
                  ->references('id')->on('crt_certificate_types')->onDelete('restrict');
            $table->foreign('initiated_by', 'fk_crt_bj_initiated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('created_by', 'fk_crt_bj_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_bj_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // Table 6: crt_student_documents
        Schema::create('crt_student_documents', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->unsignedInteger('student_id')->comment('std_students.id');
            $table->unsignedInteger('document_category_id')
                  ->comment('sys_dropdown_table.id — TC, Migration, DOB, Aadhaar, Caste, Disability, Photo, Other');
            $table->string('document_name', 255)->comment('Human-readable document name');
            $table->date('document_date')->nullable()
                  ->comment('Date printed on the document');
            $table->unsignedInteger('media_id')
                  ->comment('sys_media.id — polymorphic file storage');
            $table->enum('verification_status', ['pending', 'verified', 'rejected'])->default('pending')
                  ->comment('pending = awaiting review; verified = confirmed; rejected = blocked from eligibility (BR-CRT-008)');
            $table->text('verification_remarks')->nullable()
                  ->comment('Required when verification_status = rejected');
            $table->unsignedInteger('verified_by')->nullable()
                  ->comment('sys_users.id — Admin who verified/rejected; NULL while pending');
            $table->timestamp('verified_at')->nullable()
                  ->comment('Timestamp of verification action');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('student_id', 'idx_crt_sd_student_id');
            $table->index('document_category_id', 'idx_crt_sd_document_category_id');
            $table->index('media_id', 'idx_crt_sd_media_id');
            $table->index('verified_by', 'idx_crt_sd_verified_by');
            $table->index('verification_status', 'idx_crt_sd_verification_status');
            $table->index('created_by', 'idx_crt_sd_created_by');
            $table->index('updated_by', 'idx_crt_sd_updated_by');

            $table->foreign('student_id', 'fk_crt_sd_student_id')
                  ->references('id')->on('std_students')->onDelete('restrict');
            $table->foreign('document_category_id', 'fk_crt_sd_document_category_id')
                  ->references('id')->on('sys_dropdown_table')->onDelete('restrict');
            $table->foreign('media_id', 'fk_crt_sd_media_id')
                  ->references('id')->on('sys_media')->onDelete('restrict');
            $table->foreign('verified_by', 'fk_crt_sd_verified_by')
                  ->references('id')->on('sys_users')->onDelete('set null');
            $table->foreign('created_by', 'fk_crt_sd_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_sd_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // ===================================================================
        // LAYER 3 — Depends on Layer 2
        // ===================================================================

        // Table 7: crt_template_versions
        // NOTE: NO softDeletes() — versions are immutable archive records (DDL Rule 14)
        Schema::create('crt_template_versions', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->unsignedInteger('template_id')
                  ->comment('crt_templates.id — the live template this version was archived from');
            $table->unsignedSmallInteger('version_no')
                  ->comment('Sequential version number per template; archived before each save');
            $table->longText('template_content')
                  ->comment('Snapshot of HTML/CSS template content at this version');
            $table->json('variables_json')
                  ->comment('Snapshot of declared merge field names at this version');
            $table->unsignedInteger('saved_by')
                  ->comment('sys_users.id — user who triggered the save that archived this version');
            $table->timestamp('saved_at')
                  ->comment('Exact timestamp when this version was archived');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            // NO softDeletes() — crt_template_versions is an immutable archive; never soft-deleted

            $table->index('template_id', 'idx_crt_tv_template_id');
            $table->index('version_no', 'idx_crt_tv_version_no');
            $table->index('saved_by', 'idx_crt_tv_saved_by');
            $table->index('created_by', 'idx_crt_tv_created_by');
            $table->index('updated_by', 'idx_crt_tv_updated_by');

            $table->foreign('template_id', 'fk_crt_tv_template_id')
                  ->references('id')->on('crt_templates')->onDelete('cascade');
            $table->foreign('saved_by', 'fk_crt_tv_saved_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('created_by', 'fk_crt_tv_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_tv_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // Table 8: crt_requests
        Schema::create('crt_requests', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->string('request_no', 30)->unique('uq_crt_req_request_no')
                  ->comment('Auto-generated: REQ-YYYY-000001');
            $table->unsignedInteger('certificate_type_id')
                  ->comment('crt_certificate_types.id');
            $table->enum('requester_type', ['student', 'parent', 'staff', 'admin'])
                  ->comment('Who submitted this request');
            $table->unsignedInteger('requester_id')
                  ->comment('sys_users.id — polymorphic; no DB-level FK');
            $table->unsignedInteger('beneficiary_student_id')->nullable()
                  ->comment('std_students.id — student for whom the certificate is; NULL for staff');
            $table->text('purpose')->comment('Stated reason for requesting the certificate');
            $table->date('required_by_date')->nullable()
                  ->comment('Requested delivery date for urgency sorting');
            $table->unsignedInteger('supporting_doc_media_id')->nullable()
                  ->comment('sys_media.id — attached supporting document (BR-CRT-014)');
            $table->enum('status', ['pending', 'under_review', 'approved', 'rejected', 'generated', 'issued'])
                  ->default('pending')
                  ->comment('FSM: pending→under_review→approved/rejected→generated→issued');
            $table->unsignedInteger('approved_by')->nullable()
                  ->comment('sys_users.id — Principal or Admin who approved');
            $table->timestamp('approved_at')->nullable()->comment('Approval timestamp');
            $table->text('approval_remarks')->nullable()->comment('Optional approver comments');
            $table->text('rejection_reason')->nullable()
                  ->comment('Required when status=rejected (BR-CRT-013)');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['beneficiary_student_id', 'certificate_type_id', 'status'], 'idx_crt_req_student_type_status');
            $table->index('certificate_type_id', 'idx_crt_req_certificate_type_id');
            $table->index('status', 'idx_crt_req_status');
            $table->index('approved_by', 'idx_crt_req_approved_by');
            $table->index('supporting_doc_media_id', 'idx_crt_req_supporting_doc');
            $table->index('created_by', 'idx_crt_req_created_by');
            $table->index('updated_by', 'idx_crt_req_updated_by');

            $table->foreign('certificate_type_id', 'fk_crt_req_certificate_type_id')
                  ->references('id')->on('crt_certificate_types')->onDelete('restrict');
            $table->foreign('beneficiary_student_id', 'fk_crt_req_beneficiary_student_id')
                  ->references('id')->on('std_students')->onDelete('restrict');
            $table->foreign('supporting_doc_media_id', 'fk_crt_req_supporting_doc_media_id')
                  ->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('approved_by', 'fk_crt_req_approved_by')
                  ->references('id')->on('sys_users')->onDelete('set null');
            $table->foreign('created_by', 'fk_crt_req_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_req_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // ===================================================================
        // LAYER 4 — Depends on Layer 3
        // ===================================================================

        // Table 9: crt_issued_certificates
        Schema::create('crt_issued_certificates', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->string('certificate_no', 50)->unique('uq_crt_ic_certificate_no')
                  ->comment('Generated serial number e.g. BON-2026-000042; unique per tenant');
            $table->unsignedInteger('request_id')->nullable()
                  ->comment('crt_requests.id — NULL for direct/bulk/admin-initiated certificates');
            $table->unsignedInteger('certificate_type_id')
                  ->comment('crt_certificate_types.id');
            $table->unsignedInteger('template_id')
                  ->comment('crt_templates.id — ON DELETE RESTRICT (BR-CRT-006)');
            $table->enum('recipient_type', ['student', 'staff'])
                  ->comment('Recipient entity type');
            $table->unsignedInteger('recipient_id')
                  ->comment('std_students.id or sys_users.id — polymorphic; no DB-level FK');
            $table->date('issue_date')->comment('Official certificate issue date');
            $table->date('validity_date')->nullable()
                  ->comment('Certificate expiry date; NULL = no expiry');
            $table->string('verification_hash', 64)->unique('uq_crt_ic_verification_hash')
                  ->comment('HMAC-SHA256 hex of (certificate_no+issue_date+recipient_id+APP_KEY)');
            $table->string('file_path', 500)
                  ->comment('Relative path: storage/tenant_{id}/certificates/{type_code}/{YYYY}/');
            $table->tinyInteger('is_revoked')->default(0)
                  ->comment('1 = revoked; verification returns REVOKED not 404 (BR-CRT-005)');
            $table->timestamp('revoked_at')->nullable()->comment('Revocation timestamp');
            $table->unsignedInteger('revoked_by')->nullable()
                  ->comment('sys_users.id — Admin who revoked');
            $table->text('revocation_reason')->nullable()
                  ->comment('Required when is_revoked = 1');
            $table->tinyInteger('is_duplicate')->default(0)
                  ->comment('1 = second issuance; PDF renders with DUPLICATE COPY watermark (BR-CRT-003)');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')
                  ->comment('sys_users.id — who triggered generation (acts as issued_by)');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('request_id', 'idx_crt_ic_request_id');
            $table->index('certificate_type_id', 'idx_crt_ic_certificate_type_id');
            $table->index('template_id', 'idx_crt_ic_template_id');
            $table->index(['recipient_type', 'recipient_id'], 'idx_crt_ic_recipient');
            $table->index('issue_date', 'idx_crt_ic_issue_date');
            $table->index('validity_date', 'idx_crt_ic_validity_date');
            $table->index('is_revoked', 'idx_crt_ic_is_revoked');
            $table->index('revoked_by', 'idx_crt_ic_revoked_by');
            $table->index('created_by', 'idx_crt_ic_created_by');
            $table->index('updated_by', 'idx_crt_ic_updated_by');

            $table->foreign('request_id', 'fk_crt_ic_request_id')
                  ->references('id')->on('crt_requests')->onDelete('set null');
            $table->foreign('certificate_type_id', 'fk_crt_ic_certificate_type_id')
                  ->references('id')->on('crt_certificate_types')->onDelete('restrict');
            $table->foreign('template_id', 'fk_crt_ic_template_id')
                  ->references('id')->on('crt_templates')->onDelete('restrict');
            $table->foreign('revoked_by', 'fk_crt_ic_revoked_by')
                  ->references('id')->on('sys_users')->onDelete('set null');
            $table->foreign('created_by', 'fk_crt_ic_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_ic_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // ===================================================================
        // LAYER 5 — Depends on Layer 4
        // ===================================================================

        // Table 10: crt_tc_register
        Schema::create('crt_tc_register', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->comment('Primary Key');
            $table->unsignedSmallInteger('sl_no')
                  ->comment('Sequential TC serial number for the year; no gaps (BR-CRT-002)');
            $table->unsignedSmallInteger('academic_year')
                  ->comment('4-digit academic year e.g. 2026; sl_no resets each year');
            $table->unsignedInteger('issued_certificate_id')
                  ->comment('crt_issued_certificates.id');
            $table->string('student_name', 200)
                  ->comment('Full student name snapshot at TC issuance');
            $table->string('father_name', 200)->nullable()
                  ->comment('Father/guardian name snapshot');
            $table->date('date_of_birth')->comment('Student date of birth snapshot');
            $table->string('class_at_leaving', 50)
                  ->comment('Class/Section at time of leaving e.g. Grade 10 - A');
            $table->date('date_of_admission')
                  ->comment('Original admission date to this school');
            $table->date('date_of_leaving')
                  ->comment('Date of leaving school — mandatory TC field');
            $table->string('conduct', 100)->default('Good')
                  ->comment('Conduct remark e.g. Good, Excellent, Satisfactory');
            $table->string('reason_for_leaving', 255)
                  ->comment('Reason for transfer — mandatory TC field');
            $table->tinyInteger('is_duplicate_entry')->default(0)
                  ->comment('1 = this TC register entry is for a re-issued (duplicate) TC');
            $table->unsignedInteger('prepared_by')
                  ->comment('sys_users.id — Principal/Admin who prepared and authorised the TC');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->comment('sys_users.id');
            $table->unsignedInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['sl_no', 'academic_year'], 'uq_crt_tc_sl_year');
            $table->index('issued_certificate_id', 'idx_crt_tc_issued_certificate_id');
            $table->index('academic_year', 'idx_crt_tc_academic_year');
            $table->index('prepared_by', 'idx_crt_tc_prepared_by');
            $table->index('created_by', 'idx_crt_tc_created_by');
            $table->index('updated_by', 'idx_crt_tc_updated_by');

            $table->foreign('issued_certificate_id', 'fk_crt_tc_issued_certificate_id')
                  ->references('id')->on('crt_issued_certificates')->onDelete('restrict');
            $table->foreign('prepared_by', 'fk_crt_tc_prepared_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('created_by', 'fk_crt_tc_created_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('updated_by', 'fk_crt_tc_updated_by')
                  ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // ===================================================================
        // CROSS-MODULE: add std_students.tc_issued (required by BR-CRT-011)
        // std_students.tc_issued does not exist in current tenant_db_v2.sql
        // ===================================================================
        Schema::table('std_students', function (Blueprint $table) {
            $table->tinyInteger('tc_issued')->default(0)->after('current_status_id')
                  ->comment('Set to 1 by CRT module after TC issuance (BR-CRT-011)');
        });

        Schema::enableForeignKeyConstraints();
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();

        // Drop in reverse dependency order (Layer 5 → Layer 1)
        Schema::dropIfExists('crt_tc_register');
        Schema::dropIfExists('crt_issued_certificates');
        Schema::dropIfExists('crt_requests');
        Schema::dropIfExists('crt_template_versions');
        Schema::dropIfExists('crt_student_documents');
        Schema::dropIfExists('crt_bulk_jobs');
        Schema::dropIfExists('crt_serial_counters');
        Schema::dropIfExists('crt_templates');
        Schema::dropIfExists('crt_id_card_configs');
        Schema::dropIfExists('crt_certificate_types');

        // Revert cross-module change
        if (Schema::hasColumn('std_students', 'tc_issued')) {
            Schema::table('std_students', function (Blueprint $table) {
                $table->dropColumn('tc_issued');
            });
        }

        Schema::enableForeignKeyConstraints();
    }
};
