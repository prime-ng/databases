<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * VSM — Visitor & Security Management Module Migration
 *
 * Creates 13 vsm_* tables in dependency-safe Layer 1 → Layer 4 order.
 * Drops in reverse Layer 4 → Layer 1 order on rollback.
 *
 * Copy to: database/migrations/tenant/2026_03_27_000000_create_vsm_tables.php
 *
 * FK Type Note:
 *   vsm_* PKs and internal FKs  → bigIncrements / unsignedBigInteger
 *   Cross-module FKs (sys_users, sys_media, std_students) → unsignedInteger
 *   (tenant_db_v2 defines sys_users.id / sys_media.id / std_students.id as INT UNSIGNED)
 *
 * Audit Exceptions:
 *   vsm_patrol_checkpoint_log — no softDeletes(), no updated_at (immutable scan log)
 *   vsm_cctv_events           — no softDeletes(), no updated_at (immutable webhook event)
 */
return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No vsm_* FK dependencies
        // =====================================================================

        // 1. vsm_visitors
        Schema::create('vsm_visitors', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('name', 150);
            $table->string('mobile_no', 20)->index();
            $table->string('email', 100)->nullable();
            $table->enum('id_type', ['Aadhar', 'DrivingLicense', 'Passport', 'VoterID', 'Other'])->nullable();
            $table->string('id_number', 50)->nullable()->index();
            $table->string('company_name', 150)->nullable();
            $table->unsignedInteger('photo_media_id')->nullable()->index();
            $table->unsignedInteger('id_proof_media_id')->nullable()->index();
            $table->unsignedInteger('visit_count')->default(0);
            $table->tinyInteger('is_blacklisted')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('photo_media_id')->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('id_proof_media_id')->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 2. vsm_blacklist
        Schema::create('vsm_blacklist', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('name', 150);
            $table->string('mobile_no', 20)->nullable()->index();
            $table->enum('id_type', ['Aadhar', 'DrivingLicense', 'Passport', 'VoterID', 'Other'])->nullable();
            $table->string('id_number', 50)->nullable()->index();
            $table->unsignedInteger('photo_media_id')->nullable()->index();
            $table->text('reason');
            $table->unsignedInteger('blacklisted_by')->index();
            $table->date('valid_until')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('photo_media_id')->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('blacklisted_by')->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 3. vsm_emergency_protocols
        Schema::create('vsm_emergency_protocols', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->enum('protocol_type', ['Fire', 'Earthquake', 'Lockdown', 'MedicalEmergency', 'Evacuation', 'Other'])->index();
            $table->string('title', 200);
            $table->text('description');
            $table->json('responsible_roles_json')->nullable();
            $table->json('media_ids_json')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 4. vsm_patrol_checkpoints
        Schema::create('vsm_patrol_checkpoints', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('name', 100);
            $table->text('location_description')->nullable();
            $table->string('building', 100)->nullable();
            $table->string('floor', 20)->nullable();
            $table->unsignedTinyInteger('sequence_order')->default(0);
            $table->string('qr_token', 100)->unique();
            $table->string('qr_code_path', 255)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // =====================================================================
        // LAYER 2 — Depends on Layer 1
        // =====================================================================

        // 5. vsm_visits
        Schema::create('vsm_visits', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('visit_number', 30)->unique();
            $table->unsignedBigInteger('visitor_id')->index();
            $table->unsignedInteger('host_user_id')->nullable()->index();
            $table->enum('purpose', ['PTM', 'Admission', 'Meeting', 'Delivery', 'Maintenance', 'Interview', 'StudentPickup', 'Contractor', 'Other']);
            $table->string('purpose_detail', 255)->nullable();
            $table->date('expected_date');
            $table->time('expected_time')->nullable();
            $table->unsignedSmallInteger('expected_duration_minutes')->default(60);
            $table->string('vehicle_number', 20)->nullable();
            $table->string('gate_assigned', 50)->nullable();
            $table->timestamp('checkin_time')->nullable()->index();
            $table->unsignedInteger('checkin_photo_media_id')->nullable()->index();
            $table->timestamp('checkout_time')->nullable();
            $table->unsignedSmallInteger('duration_minutes')->nullable();
            $table->enum('status', ['Pre_Registered', 'Registered', 'Checked_In', 'Checked_Out', 'No_Show', 'Cancelled'])->default('Registered');
            $table->tinyInteger('is_overdue')->default(0);
            $table->tinyInteger('blacklist_hit')->default(0);
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['expected_date', 'status'], 'idx_vsm_vst_date_status');

            $table->foreign('visitor_id')->references('id')->on('vsm_visitors')->onDelete('restrict');
            $table->foreign('host_user_id')->references('id')->on('sys_users')->onDelete('set null');
            $table->foreign('checkin_photo_media_id')->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 6. vsm_emergency_events
        Schema::create('vsm_emergency_events', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->enum('emergency_type', ['Fire', 'Earthquake', 'Lockdown', 'MedicalEmergency', 'Evacuation', 'Other']);
            $table->unsignedBigInteger('protocol_id')->nullable()->index();
            $table->text('message');
            $table->string('affected_zones', 500)->nullable();
            $table->unsignedInteger('triggered_by')->index();
            $table->timestamp('triggered_at')->useCurrent();
            $table->timestamp('resolved_at')->nullable();
            $table->tinyInteger('is_lockdown_active')->default(0)->index();
            $table->unsignedInteger('notification_count')->default(0);
            $table->tinyInteger('headcount_initiated')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('triggered_at', 'idx_vsm_ee_triggered');

            $table->foreign('protocol_id')->references('id')->on('vsm_emergency_protocols')->onDelete('set null');
            $table->foreign('triggered_by')->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 7. vsm_guard_shifts
        Schema::create('vsm_guard_shifts', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('guard_user_id')->index();
            $table->date('shift_date');
            $table->time('shift_start_time');
            $table->time('shift_end_time');
            $table->string('post', 100);
            $table->timestamp('actual_start_time')->nullable();
            $table->timestamp('actual_end_time')->nullable();
            $table->enum('attendance_status', ['Scheduled', 'Present', 'Absent', 'Late', 'Early_Departure'])->default('Scheduled');
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['guard_user_id', 'shift_date', 'shift_start_time'], 'uq_vsm_gs_guard_shift');

            $table->foreign('guard_user_id')->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // =====================================================================
        // LAYER 3 — Depends on Layer 2
        // =====================================================================

        // 8. vsm_gate_passes
        Schema::create('vsm_gate_passes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('visit_id')->unique();
            $table->unsignedBigInteger('visitor_id')->index();
            $table->string('pass_token', 100)->unique();
            $table->string('qr_code_path', 255)->nullable();
            $table->enum('status', ['Issued', 'Used', 'Expired', 'Revoked'])->default('Issued');
            $table->timestamp('issued_at')->useCurrent();
            $table->timestamp('expires_at');
            $table->timestamp('used_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('expires_at', 'idx_vsm_gp_expires');

            $table->foreign('visit_id')->references('id')->on('vsm_visits')->onDelete('restrict');
            $table->foreign('visitor_id')->references('id')->on('vsm_visitors')->onDelete('restrict');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 9. vsm_pickup_auth
        Schema::create('vsm_pickup_auth', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('visit_id')->index();
            $table->unsignedInteger('student_id')->index();
            $table->string('guardian_name', 150);
            $table->string('guardian_mobile', 20);
            $table->string('relationship', 50)->nullable();
            $table->tinyInteger('is_authorised')->comment('1 = guardian in std_student_guardian_jnt.can_pickup=1; 0 = override required');
            $table->unsignedInteger('id_proof_media_id')->nullable()->index();
            $table->unsignedInteger('override_by')->nullable()->index();
            $table->text('override_reason')->nullable();
            $table->unsignedInteger('processed_by')->index();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('visit_id')->references('id')->on('vsm_visits')->onDelete('restrict');
            $table->foreign('student_id')->references('id')->on('std_students')->onDelete('restrict');
            $table->foreign('id_proof_media_id')->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('override_by')->references('id')->on('sys_users')->onDelete('set null');
            $table->foreign('processed_by')->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 10. vsm_contractors
        Schema::create('vsm_contractors', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('contractor_name', 150);
            $table->string('company_name', 150)->nullable();
            $table->string('mobile_no', 20)->index();
            $table->enum('id_type', ['Aadhar', 'DrivingLicense', 'Passport', 'VoterID', 'Other'])->nullable();
            $table->string('id_number', 50)->nullable();
            $table->unsignedInteger('photo_media_id')->nullable()->index();
            $table->string('work_order_no', 100)->nullable();
            $table->text('work_description')->nullable();
            $table->json('allowed_zones_json')->nullable();
            $table->date('access_from');
            $table->date('access_until');
            $table->json('entry_days_json')->nullable();
            $table->string('pass_token', 100)->unique();
            $table->enum('pass_status', ['Active', 'Expired', 'Revoked'])->default('Active')->index();
            $table->unsignedInteger('entry_count')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['access_from', 'access_until'], 'idx_vsm_con_access');

            $table->foreign('photo_media_id')->references('id')->on('sys_media')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 11. vsm_patrol_rounds
        Schema::create('vsm_patrol_rounds', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('guard_user_id')->index();
            $table->unsignedBigInteger('guard_shift_id')->nullable()->index();
            $table->timestamp('patrol_start_time');
            $table->timestamp('patrol_end_time')->nullable();
            $table->unsignedTinyInteger('checkpoints_total')->default(0);
            $table->unsignedTinyInteger('checkpoints_completed')->default(0);
            $table->decimal('completion_pct', 5, 2)->default(0.00);
            $table->enum('status', ['In_Progress', 'Completed', 'Incomplete'])->default('In_Progress');
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->index();
            $table->unsignedInteger('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('guard_user_id')->references('id')->on('sys_users')->onDelete('restrict');
            $table->foreign('guard_shift_id')->references('id')->on('vsm_guard_shifts')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('sys_users')->onDelete('set null');
        });

        // 12. vsm_cctv_events (IMMUTABLE — no updated_at, no softDeletes)
        Schema::create('vsm_cctv_events', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('camera_id', 100);
            $table->string('event_type', 100);
            $table->timestamp('event_timestamp');
            $table->string('snapshot_url', 500)->nullable();
            $table->unsignedBigInteger('linked_visit_id')->nullable()->index();
            $table->json('raw_payload_json')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['camera_id', 'event_timestamp'], 'idx_vsm_ce_camera_time');

            $table->foreign('linked_visit_id')->references('id')->on('vsm_visits')->onDelete('set null');
        });

        // =====================================================================
        // LAYER 4 — Depends on Layer 3
        // =====================================================================

        // 13. vsm_patrol_checkpoint_log (IMMUTABLE — no updated_at, no softDeletes)
        Schema::create('vsm_patrol_checkpoint_log', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('patrol_round_id')->index();
            $table->unsignedBigInteger('checkpoint_id')->index();
            $table->timestamp('scanned_at');
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('patrol_round_id')->references('id')->on('vsm_patrol_rounds')->onDelete('cascade');
            $table->foreign('checkpoint_id')->references('id')->on('vsm_patrol_checkpoints')->onDelete('restrict');
        });
    }

    public function down(): void
    {
        // Drop in reverse Layer 4 → Layer 1 order
        Schema::dropIfExists('vsm_patrol_checkpoint_log');  // Layer 4
        Schema::dropIfExists('vsm_cctv_events');            // Layer 3
        Schema::dropIfExists('vsm_patrol_rounds');          // Layer 3
        Schema::dropIfExists('vsm_contractors');            // Layer 3
        Schema::dropIfExists('vsm_pickup_auth');            // Layer 3
        Schema::dropIfExists('vsm_gate_passes');            // Layer 3
        Schema::dropIfExists('vsm_guard_shifts');           // Layer 2
        Schema::dropIfExists('vsm_emergency_events');       // Layer 2
        Schema::dropIfExists('vsm_visits');                 // Layer 2
        Schema::dropIfExists('vsm_patrol_checkpoints');     // Layer 1
        Schema::dropIfExists('vsm_emergency_protocols');    // Layer 1
        Schema::dropIfExists('vsm_blacklist');              // Layer 1
        Schema::dropIfExists('vsm_visitors');               // Layer 1
    }
};
