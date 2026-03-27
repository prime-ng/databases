<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * PPT (Parent Portal) Module — Single migration for all 6 ppt_* tables.
 *
 * Creation order: all 6 tables are Layer 1 (no inter-ppt_ FKs).
 * External FKs reference: std_guardians, std_students, sys_users, sys_media.
 * Ensure those tables exist before running this migration.
 *
 * Key column type decisions (verified against tenant_db_v2.sql 2026-03-27):
 *   - All ppt_* PKs:           ->unsignedInteger() auto-increment
 *   - FKs to std_guardians:    ->unsignedInteger()
 *   - FKs to std_students:     ->unsignedInteger()
 *   - FKs to sys_users:        ->unsignedInteger() (sys_users.id = INT UNSIGNED confirmed)
 *   - created_by:              ->unsignedBigInteger()->nullable() (platform standard)
 *
 * Migration path: database/migrations/tenant/
 */
return new class extends Migration
{
    public function up(): void
    {
        // ---------------------------------------------------------------
        // Table 1: ppt_parent_sessions
        // Per-device portal state: active child, push tokens, prefs
        // ---------------------------------------------------------------
        Schema::create('ppt_parent_sessions', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('guardian_id');
            $table->unsignedInteger('active_student_id')->nullable();
            $table->string('device_token_fcm', 255)->nullable();
            $table->string('device_token_apns', 255)->nullable();
            $table->text('device_token_webpush')->nullable();              // Web Push subscription JSON
            $table->enum('device_type', ['Android', 'iOS', 'Web', 'Unknown'])->default('Unknown');
            $table->json('notification_preferences_json')->nullable();
            $table->time('quiet_hours_start')->nullable();
            $table->time('quiet_hours_end')->nullable();
            $table->timestamp('last_active_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            // NO deleted_at — use is_active=0 on logout

            $table->primary('id');
            $table->unique(['guardian_id', 'device_token_fcm'], 'uq_ppt_session_guardian_device_fcm');
            $table->index('guardian_id', 'idx_ppt_sessions_guardian');
            $table->index('active_student_id', 'idx_ppt_sessions_active_student');
            $table->index('is_active', 'idx_ppt_sessions_is_active');

            $table->foreign('guardian_id', 'fk_ppt_sess_guardian')
                ->references('id')->on('std_guardians')->onDelete('cascade');
            $table->foreign('active_student_id', 'fk_ppt_sess_student')
                ->references('id')->on('std_students')->onDelete('set null');
        });

        // ---------------------------------------------------------------
        // Table 2: ppt_messages
        // Parent-teacher direct messages; thread_id = MD5(guardian+teacher+student)
        // FULLTEXT on (subject, message_body) for FR-PPT-04 search
        // ---------------------------------------------------------------
        Schema::create('ppt_messages', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('guardian_id');
            $table->unsignedInteger('student_id');
            $table->enum('direction', ['Parent_to_Teacher', 'Teacher_to_Parent']);
            $table->unsignedInteger('sender_user_id');                     // sys_users.id = INT UNSIGNED
            $table->unsignedInteger('recipient_user_id');                  // sys_users.id = INT UNSIGNED
            $table->string('thread_id', 64);                               // MD5 hash
            $table->string('subject', 200);
            $table->text('message_body');
            $table->json('attachment_media_ids_json')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->softDeletes();                                         // deleted_at

            $table->primary('id');
            $table->index(['thread_id', 'created_at'], 'idx_ppt_messages_thread');
            $table->index('guardian_id', 'idx_ppt_messages_guardian');
            $table->index('student_id', 'idx_ppt_messages_student');
            $table->index('sender_user_id', 'idx_ppt_messages_sender');
            // FULLTEXT index must be created via raw statement (Laravel Blueprint supports it)
            $table->fullText(['subject', 'message_body'], 'ft_ppt_messages_search');

            $table->foreign('guardian_id', 'fk_ppt_msg_guardian')
                ->references('id')->on('std_guardians')->onDelete('cascade');
            $table->foreign('student_id', 'fk_ppt_msg_student')
                ->references('id')->on('std_students')->onDelete('cascade');
            $table->foreign('sender_user_id', 'fk_ppt_msg_sender')
                ->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('recipient_user_id', 'fk_ppt_msg_recipient')
                ->references('id')->on('sys_users')->onDelete('restrict');
        });

        // ---------------------------------------------------------------
        // Table 3: ppt_leave_applications
        // Leave applications by parent on behalf of child
        // from_date >= tomorrow enforced in ApplyLeaveRequest (not DB constraint)
        // ---------------------------------------------------------------
        Schema::create('ppt_leave_applications', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->string('application_number', 30)->unique('uq_ppt_leave_app_number');
            $table->unsignedInteger('student_id');
            $table->unsignedInteger('guardian_id');
            $table->date('from_date');
            $table->date('to_date');
            $table->unsignedTinyInteger('number_of_days');
            $table->enum('leave_type', ['Sick', 'Family', 'Personal', 'Festival', 'Medical', 'Other']);
            $table->text('reason');
            $table->unsignedInteger('supporting_doc_media_id')->nullable();
            $table->enum('status', ['Pending', 'Approved', 'Rejected', 'Withdrawn'])->default('Pending');
            $table->unsignedInteger('reviewed_by_user_id')->nullable();    // sys_users.id = INT UNSIGNED
            $table->timestamp('reviewed_at')->nullable();
            $table->text('reviewer_notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->softDeletes();

            $table->primary('id');
            $table->index(['student_id', 'status'], 'idx_ppt_leave_student_status');
            $table->index('guardian_id', 'idx_ppt_leave_guardian');
            $table->index('status', 'idx_ppt_leave_status');

            $table->foreign('student_id', 'fk_ppt_leave_student')
                ->references('id')->on('std_students')->onDelete('cascade');
            $table->foreign('guardian_id', 'fk_ppt_leave_guardian')
                ->references('id')->on('std_guardians')->onDelete('cascade');
            $table->foreign('supporting_doc_media_id', 'fk_ppt_leave_media')
                ->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('reviewed_by_user_id', 'fk_ppt_leave_reviewer')
                ->references('id')->on('sys_users')->onDelete('set null');
        });

        // ---------------------------------------------------------------
        // Table 4: ppt_event_rsvps
        // Parent RSVPs and volunteer sign-ups for school events
        // UNIQUE (event_id, guardian_id) = one RSVP per guardian per event
        // NO softDeletes — RSVPs updated in-place
        // ---------------------------------------------------------------
        Schema::create('ppt_event_rsvps', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('event_id');                           // Event Engine event record (no FK — soft dep)
            $table->unsignedInteger('guardian_id');
            $table->unsignedInteger('student_id')->nullable();
            $table->enum('rsvp_status', ['Attending', 'Not_Attending', 'Maybe'])->default('Attending');
            $table->tinyInteger('is_volunteer')->default(0);
            $table->string('volunteer_role', 150)->nullable();
            $table->text('rsvp_notes')->nullable();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('reminder_sent_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            // NO softDeletes on this table

            $table->primary('id');
            $table->unique(['event_id', 'guardian_id'], 'uq_ppt_rsvp_event_guardian');
            $table->index('guardian_id', 'idx_ppt_rsvp_guardian');
            $table->index('student_id', 'idx_ppt_rsvp_student');
            $table->index('event_id', 'idx_ppt_rsvp_event');

            $table->foreign('guardian_id', 'fk_ppt_rsvp_guardian')
                ->references('id')->on('std_guardians')->onDelete('cascade');
            $table->foreign('student_id', 'fk_ppt_rsvp_student')
                ->references('id')->on('std_students')->onDelete('set null');
        });

        // ---------------------------------------------------------------
        // Table 5: ppt_document_requests
        // Online requests for duplicate certificates
        // payment_reference UNIQUE nullable = Razorpay idempotency (BR-PPT-011)
        // MySQL UNIQUE on nullable col allows multiple NULLs natively
        // ---------------------------------------------------------------
        Schema::create('ppt_document_requests', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->string('request_number', 30)->unique('uq_ppt_doc_request_number');
            $table->unsignedInteger('student_id');
            $table->unsignedInteger('guardian_id');
            $table->enum('document_type', ['TC', 'MarkSheet', 'Bonafide', 'Character', 'Migration', 'MedicalFitness', 'Other']);
            $table->text('reason');
            $table->enum('urgency', ['Normal', 'Urgent'])->default('Normal');
            $table->enum('status', ['Pending', 'Processing', 'Ready', 'Completed', 'Rejected'])->default('Pending');
            $table->text('admin_notes')->nullable();
            $table->decimal('fee_required', 8, 2)->default(0.00);
            $table->tinyInteger('fee_paid')->default(0);
            $table->string('payment_reference', 100)->nullable()->unique('uq_ppt_doc_payment_ref');
            $table->unsignedInteger('fulfilled_media_id')->nullable();
            $table->timestamp('fulfilled_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->softDeletes();

            $table->primary('id');
            $table->index(['student_id', 'status'], 'idx_ppt_doc_student_status');
            $table->index('guardian_id', 'idx_ppt_doc_guardian');
            $table->index('status', 'idx_ppt_doc_status');

            $table->foreign('student_id', 'fk_ppt_doc_student')
                ->references('id')->on('std_students')->onDelete('cascade');
            $table->foreign('guardian_id', 'fk_ppt_doc_guardian')
                ->references('id')->on('std_guardians')->onDelete('cascade');
            $table->foreign('fulfilled_media_id', 'fk_ppt_doc_media')
                ->references('id')->on('sys_media')->onDelete('set null');
        });

        // ---------------------------------------------------------------
        // Table 6: ppt_consent_form_responses
        // IMMUTABLE after creation — no softDeletes, no update path
        // signed_at = business timestamp (separate from created_at)
        // UNIQUE (consent_form_id, student_id, guardian_id) = BR-PPT-014
        // ---------------------------------------------------------------
        Schema::create('ppt_consent_form_responses', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('consent_form_id');                    // Event/Activity module consent form (no FK — soft dep)
            $table->unsignedInteger('student_id');
            $table->unsignedInteger('guardian_id');
            $table->enum('response', ['Signed', 'Declined']);
            $table->text('decline_reason')->nullable();                    // required_if response=Declined (FormRequest)
            $table->string('signer_name', 150);
            $table->string('signed_ip', 45)->nullable();                   // IPv4 or IPv6
            $table->timestamp('signed_at')->useCurrent();                  // BUSINESS timestamp — immutable
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            // CRITICAL: NO softDeletes() — consent responses are immutable

            $table->primary('id');
            $table->unique(['consent_form_id', 'student_id', 'guardian_id'], 'uq_ppt_consent_response');
            $table->index('student_id', 'idx_ppt_consent_student');
            $table->index('guardian_id', 'idx_ppt_consent_guardian');
            $table->index('consent_form_id', 'idx_ppt_consent_form');

            $table->foreign('student_id', 'fk_ppt_consent_student')
                ->references('id')->on('std_students')->onDelete('cascade');
            $table->foreign('guardian_id', 'fk_ppt_consent_guardian')
                ->references('id')->on('std_guardians')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        // Drop in reverse order (no inter-ppt_ FKs so order is flexible)
        Schema::dropIfExists('ppt_consent_form_responses');
        Schema::dropIfExists('ppt_document_requests');
        Schema::dropIfExists('ppt_event_rsvps');
        Schema::dropIfExists('ppt_leave_applications');
        Schema::dropIfExists('ppt_messages');
        Schema::dropIfExists('ppt_parent_sessions');
    }
};
