<?php

// Tenant migration — copy to: database/migrations/tenant/2026_03_27_000000_create_fof_tables.php
// Run: php artisan tenants:migrate

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No fof_* dependencies (7 tables)
        // =====================================================================

        Schema::create('fof_visitor_purposes', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('code', 30)->unique();
            $table->tinyInteger('is_government_visit')->default(0);
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('is_active', 'idx_fof_vp_active');
        });

        Schema::create('fof_emergency_contacts', function (Blueprint $table) {
            $table->id();
            $table->string('contact_name', 100);
            $table->string('organization', 150)->nullable();
            $table->enum('contact_type', ['Hospital','Police','Fire','Ambulance','Transport','Utility','Parent_Emergency','Government','Other']);
            $table->string('primary_phone', 15);
            $table->string('alternate_phone', 15)->nullable();
            $table->string('address', 200)->nullable();
            $table->text('notes')->nullable();
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('contact_type', 'idx_fof_ec_type');
        });

        Schema::create('fof_notices', function (Blueprint $table) {
            $table->id();
            $table->string('title', 200);
            $table->longText('content');
            $table->enum('category', ['Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other']);
            $table->enum('audience', ['All','Students','Staff','Parents'])->default('All');
            $table->date('display_from');
            $table->date('display_until')->nullable();
            $table->tinyInteger('is_pinned')->default(0);
            $table->tinyInteger('is_emergency')->default(0);
            $table->unsignedInteger('attachment_media_id')->nullable();
            $table->enum('status', ['Active','Archived'])->default('Active');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['display_from','display_until','status'], 'idx_fof_ntc_display');
            $table->index('is_emergency', 'idx_fof_ntc_emergency');
            $table->index('audience', 'idx_fof_ntc_audience');
            $table->index('is_pinned', 'idx_fof_ntc_pinned');
            $table->index('attachment_media_id', 'idx_fof_ntc_attachment');

            $table->foreign('attachment_media_id', 'fk_fof_ntc_attachment_media_id')
                ->references('id')->on('sys_media')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_school_events', function (Blueprint $table) {
            $table->id();
            $table->string('event_name', 200);
            $table->enum('event_type', ['Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other']);
            $table->date('start_date');
            $table->date('end_date');
            $table->text('description')->nullable();
            $table->string('venue', 200)->nullable();
            $table->enum('audience', ['All','Students','Staff','Parents'])->default('All');
            $table->tinyInteger('is_public')->default(0);
            $table->tinyInteger('notification_sent')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['start_date','event_type'], 'idx_fof_se_date_type');
            $table->index('is_public', 'idx_fof_se_public');
        });

        Schema::create('fof_email_templates', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('subject', 300);
            $table->longText('body');
            $table->string('module', 50)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('is_active', 'idx_fof_et_active');
        });

        Schema::create('fof_feedback_forms', function (Blueprint $table) {
            $table->id();
            $table->string('title', 200);
            $table->text('description')->nullable();
            $table->json('questions_json');
            $table->string('token', 64)->unique();
            $table->tinyInteger('is_anonymous_allowed')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('is_active', 'idx_fof_ff_active');
        });

        Schema::create('fof_key_register', function (Blueprint $table) {
            $table->id();
            $table->string('key_label', 100);
            $table->string('key_tag_number', 30);
            $table->enum('key_type', ['Room','Lab','Vehicle','Cabinet','Store','Other']);
            $table->unsignedInteger('issued_to_user_id')->nullable();
            $table->string('purpose', 200)->nullable();
            $table->dateTime('issued_at')->nullable();
            $table->dateTime('expected_return_at')->nullable();
            $table->dateTime('returned_at')->nullable();
            $table->enum('status', ['Available','Issued','Overdue','Lost'])->default('Available');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status','issued_to_user_id'], 'idx_fof_kr_status_user');
            $table->index('issued_to_user_id', 'idx_fof_kr_issued_to');

            $table->foreign('issued_to_user_id', 'fk_fof_kr_issued_to_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 2 — Depends on Layer 1 + cross-module refs (10 tables)
        // =====================================================================

        Schema::create('fof_visitors', function (Blueprint $table) {
            $table->id();
            $table->string('pass_number', 25)->unique();
            $table->unsignedBigInteger('vsm_visitor_id')->nullable();  // FK omitted — VSM module pending
            $table->string('visitor_name', 100);
            $table->string('visitor_mobile', 15);
            $table->string('visitor_email', 100)->nullable();
            $table->enum('id_proof_type', ['Aadhar','Driving_License','Passport','Voter_ID','PAN','Employee_ID','Other'])->nullable();
            $table->string('id_proof_number', 50)->nullable();
            $table->string('address', 200)->nullable();
            $table->string('organization', 100)->nullable();
            $table->unsignedBigInteger('purpose_id');
            $table->string('person_to_meet', 100)->nullable();
            $table->unsignedInteger('meet_user_id')->nullable();
            $table->string('vehicle_number', 20)->nullable();
            $table->unsignedTinyInteger('accompanying_count')->default(0);
            $table->unsignedInteger('photo_media_id')->nullable();
            $table->dateTime('in_time')->useCurrent();
            $table->dateTime('out_time')->nullable();
            $table->enum('status', ['In','Out','Overstay'])->default('In');
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('status', 'idx_fof_vis_status');
            $table->index('visitor_mobile', 'idx_fof_vis_mobile');
            $table->index('purpose_id', 'idx_fof_vis_purpose');
            $table->index('vsm_visitor_id', 'idx_fof_vis_vsm');
            $table->index('meet_user_id', 'idx_fof_vis_meet_user');
            $table->index('photo_media_id', 'idx_fof_vis_photo');

            $table->foreign('purpose_id', 'fk_fof_vis_purpose_id')
                ->references('id')->on('fof_visitor_purposes')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('meet_user_id', 'fk_fof_vis_meet_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('photo_media_id', 'fk_fof_vis_photo_media_id')
                ->references('id')->on('sys_media')
                ->onDelete('set null')->onUpdate('cascade');
        });
        // Functional index on DATE(in_time) — MySQL 8.0+ functional index
        DB::statement('ALTER TABLE fof_visitors ADD INDEX idx_fof_vis_date ((DATE(in_time)))');

        Schema::create('fof_gate_passes', function (Blueprint $table) {
            $table->id();
            $table->string('pass_number', 25)->unique();
            $table->enum('person_type', ['Student','Staff']);
            $table->unsignedInteger('student_id')->nullable();
            $table->unsignedInteger('staff_user_id')->nullable();
            $table->enum('purpose', ['Medical','Personal','Official','Sports','Family_Emergency','Other']);
            $table->string('purpose_details', 200)->nullable();
            $table->dateTime('exit_time')->nullable();
            $table->dateTime('expected_return_time')->nullable();
            $table->dateTime('actual_return_time')->nullable();
            $table->tinyInteger('parent_notified')->default(0);
            $table->enum('status', ['Pending_Approval','Approved','Rejected','Exited','Returned','Cancelled'])->default('Pending_Approval');
            $table->unsignedInteger('approved_by')->nullable();
            $table->dateTime('approved_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('student_id', 'idx_fof_gp_student');
            $table->index('staff_user_id', 'idx_fof_gp_staff');
            $table->index('status', 'idx_fof_gp_status');
            $table->index('approved_by', 'idx_fof_gp_approved_by');

            $table->foreign('student_id', 'fk_fof_gp_student_id')
                ->references('id')->on('std_students')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('staff_user_id', 'fk_fof_gp_staff_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('approved_by', 'fk_fof_gp_approved_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_early_departures', function (Blueprint $table) {
            $table->id();
            $table->string('departure_number', 25)->unique();
            $table->unsignedInteger('student_id');
            $table->dateTime('departure_time');
            $table->enum('reason', ['Medical','Family_Emergency','Event','Bereavement','Other']);
            $table->string('reason_details', 200)->nullable();
            $table->string('collecting_person_name', 100);
            $table->enum('collecting_person_relation', ['Father','Mother','Guardian','Sibling','Other']);
            $table->enum('collecting_id_proof_type', ['Aadhar','Driving_License','Passport','Other'])->nullable();
            $table->string('collecting_id_proof_number', 50)->nullable();
            $table->tinyInteger('parent_authorized')->default(0);
            $table->enum('att_sync_status', ['Pending','Synced','Failed'])->default('Pending');
            $table->dateTime('att_synced_at')->nullable();
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('student_id', 'idx_fof_ed_student');
            $table->index('att_sync_status', 'idx_fof_ed_att_sync');

            $table->foreign('student_id', 'fk_fof_ed_student_id')
                ->references('id')->on('std_students')
                ->onDelete('restrict')->onUpdate('cascade');
        });
        DB::statement('ALTER TABLE fof_early_departures ADD INDEX idx_fof_ed_date ((DATE(departure_time)))');

        Schema::create('fof_phone_diary', function (Blueprint $table) {
            $table->id();
            $table->enum('call_type', ['Incoming','Outgoing']);
            $table->date('call_date');
            $table->time('call_time');
            $table->string('caller_name', 100);
            $table->string('caller_number', 15)->nullable();
            $table->string('caller_organization', 100)->nullable();
            $table->string('recipient_name', 100)->nullable();
            $table->unsignedInteger('recipient_user_id')->nullable();
            $table->string('purpose', 200);
            $table->text('message')->nullable();
            $table->tinyInteger('action_required')->default(0);
            $table->text('action_notes')->nullable();
            $table->tinyInteger('action_completed')->default(0);
            $table->unsignedInteger('logged_by')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['call_date','call_type'], 'idx_fof_pd_date_type');
            $table->index('recipient_user_id', 'idx_fof_pd_recipient');
            $table->index('action_required', 'idx_fof_pd_action');
            $table->index('logged_by', 'idx_fof_pd_logged_by');

            $table->foreign('recipient_user_id', 'fk_fof_pd_recipient_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('logged_by', 'fk_fof_pd_logged_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_postal_register', function (Blueprint $table) {
            $table->id();
            $table->enum('postal_type', ['Inward','Outward']);
            $table->string('postal_number', 30)->unique();
            $table->date('postal_date');
            $table->string('sender_name', 100)->nullable();
            $table->string('sender_address', 200)->nullable();
            $table->string('recipient_name', 100)->nullable();
            $table->string('recipient_address', 200)->nullable();
            $table->enum('document_type', ['Letter','Courier','Parcel','Government_Notice','Cheque','Legal','Other']);
            $table->string('subject', 200);
            $table->string('courier_company', 100)->nullable();
            $table->string('tracking_number', 100)->nullable();
            $table->string('department', 100)->nullable();
            $table->unsignedInteger('assigned_to_user_id')->nullable();
            $table->string('acknowledgement_by', 100)->nullable();
            $table->dateTime('acknowledged_at')->nullable();
            $table->text('remarks')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['postal_type','postal_date'], 'idx_fof_pr_type_date');
            $table->index('assigned_to_user_id', 'idx_fof_pr_assigned');

            $table->foreign('assigned_to_user_id', 'fk_fof_pr_assigned_to_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_dispatch_register', function (Blueprint $table) {
            $table->id();
            $table->string('dispatch_number', 30)->unique();
            $table->date('dispatch_date');
            $table->string('addressee_name', 100);
            $table->string('addressee_address', 200)->nullable();
            $table->string('subject', 200);
            $table->enum('document_type', ['Letter','Notice','Legal','Certificate','Report','Circular','Other']);
            $table->enum('dispatch_mode', ['Hand','Post','Courier','Email','Fax']);
            $table->string('reference_number', 100)->nullable();
            $table->tinyInteger('copy_retained')->default(1);
            $table->unsignedInteger('dispatched_by')->nullable();
            $table->text('remarks')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('dispatch_date', 'idx_fof_dr_date');
            $table->index('dispatched_by', 'idx_fof_dr_dispatched_by');

            $table->foreign('dispatched_by', 'fk_fof_dr_dispatched_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_appointments', function (Blueprint $table) {
            $table->id();
            $table->string('appointment_number', 25)->unique();
            $table->enum('appointment_type', ['Parent_Teacher_Meeting','Principal_Meeting','Grievance','Admission_Enquiry','Other']);
            $table->unsignedInteger('with_user_id');
            $table->string('visitor_name', 100);
            $table->string('visitor_mobile', 15);
            $table->string('visitor_email', 100)->nullable();
            $table->string('purpose', 300);
            $table->date('appointment_date');
            $table->time('start_time');
            $table->time('end_time');
            $table->enum('status', ['Pending','Confirmed','Completed','Cancelled','No_Show'])->default('Pending');
            $table->unsignedInteger('confirmed_by')->nullable();
            $table->dateTime('confirmed_at')->nullable();
            $table->string('cancellation_reason', 300)->nullable();
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('with_user_id', 'idx_fof_apt_with_user');
            $table->index('appointment_date', 'idx_fof_apt_date');
            $table->index('status', 'idx_fof_apt_status');
            $table->index('confirmed_by', 'idx_fof_apt_confirmed_by');
            $table->index(['with_user_id','appointment_date','start_time','end_time'], 'idx_fof_apt_slot');

            $table->foreign('with_user_id', 'fk_fof_apt_with_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('confirmed_by', 'fk_fof_apt_confirmed_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_lost_found', function (Blueprint $table) {
            $table->id();
            $table->string('item_number', 25)->unique();
            $table->string('item_description', 300);
            $table->enum('category', ['Electronics','Clothing','Stationery','ID_Card','Money','Jewellery','Books','Sports','Other']);
            $table->date('found_date');
            $table->string('found_location', 200);
            $table->string('found_by_name', 100);
            $table->unsignedInteger('found_by_user_id')->nullable();
            $table->unsignedInteger('photo_media_id')->nullable();
            $table->enum('status', ['Unclaimed','Claimed','Disposed','Returned_to_Authority'])->default('Unclaimed');
            $table->string('claimant_name', 100)->nullable();
            $table->string('claimant_contact', 15)->nullable();
            $table->date('claimed_date')->nullable();
            $table->text('disposal_notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('status', 'idx_fof_lf_status');
            $table->index('found_date', 'idx_fof_lf_found_date');
            $table->index('found_by_user_id', 'idx_fof_lf_found_by');
            $table->index('photo_media_id', 'idx_fof_lf_photo');

            $table->foreign('found_by_user_id', 'fk_fof_lf_found_by_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('photo_media_id', 'fk_fof_lf_photo_media_id')
                ->references('id')->on('sys_media')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_certificate_requests', function (Blueprint $table) {
            $table->id();
            $table->string('request_number', 25)->unique();
            $table->unsignedInteger('student_id');
            $table->enum('cert_type', ['Bonafide','Character','Fee_Paid','Study','TC_Copy','Migration','Conduct','Other']);
            $table->string('purpose', 200);
            $table->unsignedTinyInteger('copies_requested')->default(1);
            $table->tinyInteger('is_urgent')->default(0);
            $table->string('applicant_name', 100)->nullable();
            $table->string('applicant_contact', 15)->nullable();
            $table->json('stages_json')->nullable();
            $table->enum('status', ['Pending_Approval','Approved','Rejected','Issued','Cancelled'])->default('Pending_Approval');
            $table->unsignedInteger('approved_by')->nullable();
            $table->dateTime('approved_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->string('cert_number', 30)->nullable()->unique();
            $table->dateTime('issued_at')->nullable();
            $table->unsignedInteger('issued_by')->nullable();
            $table->string('issued_to', 100)->nullable();
            $table->unsignedInteger('media_id')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('student_id', 'idx_fof_cr_student');
            $table->index('status', 'idx_fof_cr_status');
            $table->index('cert_type', 'idx_fof_cr_cert_type');
            $table->index('approved_by', 'idx_fof_cr_approved_by');
            $table->index('issued_by', 'idx_fof_cr_issued_by');
            $table->index('media_id', 'idx_fof_cr_media');

            $table->foreign('student_id', 'fk_fof_cr_student_id')
                ->references('id')->on('std_students')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('approved_by', 'fk_fof_cr_approved_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('issued_by', 'fk_fof_cr_issued_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('media_id', 'fk_fof_cr_media_id')
                ->references('id')->on('sys_media')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_complaints', function (Blueprint $table) {
            $table->id();
            $table->string('complaint_number', 30)->unique();
            $table->string('complainant_name', 100);
            $table->string('complainant_contact', 15)->nullable();
            $table->enum('complaint_type', ['Academic','Facility','Staff_Behavior','Fee','Safety','Transportation','Food','Hygiene','Other']);
            $table->text('description');
            $table->enum('urgency', ['Normal','Urgent','Critical'])->default('Normal');
            $table->unsignedInteger('assigned_to_user_id')->nullable();
            $table->enum('status', ['Open','In_Progress','Resolved','Closed','Escalated'])->default('Open');
            $table->text('resolution_notes')->nullable();
            $table->dateTime('resolved_at')->nullable();
            $table->unsignedInteger('resolved_by')->nullable();
            $table->unsignedInteger('cmp_complaint_id')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status','urgency'], 'idx_fof_cmp_status_urgency');
            $table->index('assigned_to_user_id', 'idx_fof_cmp_assigned');
            $table->index('cmp_complaint_id', 'idx_fof_cmp_escalated');
            $table->index('resolved_by', 'idx_fof_cmp_resolved_by');

            $table->foreign('assigned_to_user_id', 'fk_fof_cmp_assigned_to_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('resolved_by', 'fk_fof_cmp_resolved_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('cmp_complaint_id', 'fk_fof_cmp_cmp_complaint_id')
                ->references('id')->on('cmp_complaints')
                ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 3 — Depends on Layer 2 (2 tables)
        // =====================================================================

        Schema::create('fof_circulars', function (Blueprint $table) {
            $table->id();
            $table->string('circular_number', 30)->unique();
            $table->string('title', 200);
            $table->string('subject', 300);
            $table->longText('body');
            $table->enum('audience', ['Parents','Staff','Both','Specific_Class','Specific_Section']);
            $table->json('audience_filter_json')->nullable();
            $table->date('effective_date');
            $table->date('expires_on')->nullable();
            $table->unsignedInteger('attachment_media_id')->nullable();
            $table->enum('status', ['Draft','Pending_Approval','Approved','Distributed','Recalled'])->default('Draft');
            $table->unsignedInteger('approved_by')->nullable();
            $table->dateTime('approved_at')->nullable();
            $table->dateTime('distributed_at')->nullable();
            $table->unsignedInteger('distributed_by')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('status', 'idx_fof_cir_status');
            $table->index('approved_by', 'idx_fof_cir_approved_by');
            $table->index('distributed_by', 'idx_fof_cir_distributed_by');
            $table->index('attachment_media_id', 'idx_fof_cir_attachment');

            $table->foreign('approved_by', 'fk_fof_cir_approved_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('distributed_by', 'fk_fof_cir_distributed_by')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
            $table->foreign('attachment_media_id', 'fk_fof_cir_attachment_media_id')
                ->references('id')->on('sys_media')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_feedback_responses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('feedback_form_id');
            $table->unsignedInteger('respondent_user_id')->nullable();
            $table->string('respondent_name', 100)->nullable();
            $table->tinyInteger('is_anonymous')->default(0);
            $table->json('responses_json');
            $table->timestamp('submitted_at')->useCurrent();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by')->default(0);  // 0 for anonymous submissions
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('feedback_form_id', 'idx_fof_fr_form');
            $table->index('respondent_user_id', 'idx_fof_fr_respondent');
            $table->index('submitted_at', 'idx_fof_fr_submitted');

            $table->foreign('feedback_form_id', 'fk_fof_fr_feedback_form_id')
                ->references('id')->on('fof_feedback_forms')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('respondent_user_id', 'fk_fof_fr_respondent_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('set null')->onUpdate('cascade');
        });

        // =====================================================================
        // LAYER 4 — Depends on Layer 3 (3 tables)
        // =====================================================================

        // Append-only log — no softDeletes(), no updated_by column
        Schema::create('fof_circular_distributions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('circular_id');
            $table->unsignedInteger('recipient_user_id');
            $table->enum('channel', ['Email','SMS','Push']);
            $table->enum('status', ['Queued','Sent','Delivered','Failed'])->default('Queued');
            $table->timestamp('sent_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->unsignedBigInteger('ntf_log_id')->nullable();  // no FK — cross-module reference
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            // No updated_by — append-only immutable log
            $table->timestamps();
            // No softDeletes() — immutable distribution log

            $table->index('circular_id', 'idx_fof_cd_circular');
            $table->index(['circular_id','recipient_user_id'], 'idx_fof_cd_recipient');
            $table->index('status', 'idx_fof_cd_status');
            $table->index('recipient_user_id', 'idx_fof_cd_recipient_user');

            $table->foreign('circular_id', 'fk_fof_cd_circular_id')
                ->references('id')->on('fof_circulars')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('recipient_user_id', 'fk_fof_cd_recipient_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('restrict')->onUpdate('cascade');
        });

        Schema::create('fof_communication_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('template_id')->nullable();
            $table->enum('channel', ['Email','SMS']);
            $table->string('subject', 300)->nullable();
            $table->text('body');
            $table->string('recipient_group', 100);
            $table->unsignedInteger('total_recipients')->default(0);
            $table->unsignedInteger('sent_count')->default(0);
            $table->unsignedInteger('failed_count')->default(0);
            $table->timestamp('sent_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('created_at', 'idx_fof_cl_created_at');
            $table->index('channel', 'idx_fof_cl_channel');
            $table->index('template_id', 'idx_fof_cl_template');

            $table->foreign('template_id', 'fk_fof_cl_template_id')
                ->references('id')->on('fof_email_templates')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('fof_sms_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('communication_log_id');
            $table->unsignedInteger('recipient_user_id');
            $table->string('mobile_number', 15);
            $table->text('message');
            $table->unsignedTinyInteger('sms_units')->default(1);
            $table->enum('status', ['Queued','Sent','Delivered','Failed'])->default('Queued');
            $table->timestamp('sent_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->text('gateway_response')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index('communication_log_id', 'idx_fof_sl_comm_log');
            $table->index('recipient_user_id', 'idx_fof_sl_recipient');
            $table->index('status', 'idx_fof_sl_status');

            $table->foreign('communication_log_id', 'fk_fof_sl_communication_log_id')
                ->references('id')->on('fof_communication_logs')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('recipient_user_id', 'fk_fof_sl_recipient_user_id')
                ->references('id')->on('sys_users')
                ->onDelete('restrict')->onUpdate('cascade');
        });
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();

        // Layer 4
        Schema::dropIfExists('fof_sms_logs');
        Schema::dropIfExists('fof_communication_logs');
        Schema::dropIfExists('fof_circular_distributions');

        // Layer 3
        Schema::dropIfExists('fof_feedback_responses');
        Schema::dropIfExists('fof_circulars');

        // Layer 2
        Schema::dropIfExists('fof_complaints');
        Schema::dropIfExists('fof_certificate_requests');
        Schema::dropIfExists('fof_lost_found');
        Schema::dropIfExists('fof_appointments');
        Schema::dropIfExists('fof_dispatch_register');
        Schema::dropIfExists('fof_postal_register');
        Schema::dropIfExists('fof_phone_diary');
        Schema::dropIfExists('fof_early_departures');
        Schema::dropIfExists('fof_gate_passes');
        Schema::dropIfExists('fof_visitors');

        // Layer 1
        Schema::dropIfExists('fof_key_register');
        Schema::dropIfExists('fof_feedback_forms');
        Schema::dropIfExists('fof_email_templates');
        Schema::dropIfExists('fof_school_events');
        Schema::dropIfExists('fof_notices');
        Schema::dropIfExists('fof_emergency_contacts');
        Schema::dropIfExists('fof_visitor_purposes');

        Schema::enableForeignKeyConstraints();
    }
};
