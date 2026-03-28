<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * HST — Hostel Management Module Migration
 *
 * Creates all 21 hst_* tables for the Hostel Management module.
 * Tables created in Layer 1 → Layer 8 dependency order.
 * Dropped in reverse order (Layer 8 → Layer 1) in down().
 *
 * FK TYPE NOTE:
 *   hst_* PKs and internal FKs   → unsignedBigInteger() (BIGINT UNSIGNED)
 *   cross-module FKs              → unsignedInteger()    (INT UNSIGNED)
 *     sys_users.id, sys_media.id, std_students.id, sch_academic_term.id are INT UNSIGNED
 *   created_by / updated_by       → unsignedInteger()    (INT UNSIGNED, matches sys_users.id)
 *   hst_incident_media.media_id   → unsignedInteger()    (sys_media.id is INT UNSIGNED)
 *   hst_sick_bay_log.hpc_record_id → unsignedBigInteger()->nullable() — NO ->foreign() constraint
 *   hst_allotments generated cols  → storedAs("IF(status='active', col, NULL)")
 *   hst_attendance_entries         → CASCADE DELETE from hst_attendance
 *   hst_incident_media             → CASCADE DELETE from hst_incidents
 *
 * Copy to: database/migrations/tenant/2026_03_27_000000_create_hst_tables.php
 */
return new class extends Migration
{
    public function up(): void
    {
        // ─────────────────────────────────────────────────────────────────────
        // LAYER 1 — No hst_* dependencies
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_hostels', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('name', 150);
            $table->enum('type', ['boys', 'girls', 'mixed']);
            $table->string('code', 20)->nullable()->unique();
            $table->unsignedInteger('warden_id')->nullable();
            $table->smallInteger('total_capacity')->unsigned()->default(0);
            $table->smallInteger('current_occupancy')->unsigned()->default(0);
            $table->tinyInteger('sick_bay_capacity')->unsigned()->default(5);
            $table->string('address', 500)->nullable();
            $table->string('contact_phone', 20)->nullable();
            $table->json('visiting_days_json')->nullable();
            $table->json('facilities_json')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->foreign('warden_id')->references('id')->on('sys_users')->nullOnDelete();
        });

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 2 — Depends on hst_hostels
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_floors', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->tinyInteger('floor_number');
            $table->string('display_name', 100)->nullable();
            $table->unsignedInteger('floor_incharge_id')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(['hostel_id', 'floor_number'], 'uq_hst_floor_num');
            $table->index('floor_incharge_id');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('floor_incharge_id')->references('id')->on('sys_users')->nullOnDelete();
        });

        Schema::create('hst_warden_assignments', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->unsignedBigInteger('floor_id')->nullable();
            $table->unsignedInteger('user_id');
            $table->enum('assignment_type', ['chief', 'block', 'floor', 'assistant']);
            $table->date('effective_from');
            $table->date('effective_to')->nullable();
            $table->string('remarks', 300)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index(['hostel_id', 'floor_id', 'effective_to'], 'idx_hst_wa_hostel_floor_to');
            $table->index('user_id');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('floor_id')->references('id')->on('hst_floors')->nullOnDelete();
            $table->foreign('user_id')->references('id')->on('sys_users');
        });

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 3 — Depends on hst_floors
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_rooms', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('floor_id');
            $table->string('room_number', 20);
            $table->enum('room_type', ['single', 'double', 'triple', 'dormitory']);
            $table->tinyInteger('capacity')->unsigned();
            $table->tinyInteger('current_occupancy')->unsigned()->default(0);
            $table->enum('status', ['available', 'full', 'maintenance'])->default('available');
            $table->json('amenities_json')->nullable();
            $table->json('priority_flags_json')->nullable();
            $table->string('notes', 500)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(['floor_id', 'room_number'], 'uq_hst_room_num');

            $table->foreign('floor_id')->references('id')->on('hst_floors');
        });

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 4 — Depends on hst_rooms + cross-module
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_beds', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('room_id');
            $table->string('bed_label', 20);
            $table->enum('status', ['available', 'occupied', 'maintenance'])->default('available');
            $table->enum('condition', ['good', 'fair', 'poor'])->default('good');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(['room_id', 'bed_label'], 'uq_hst_bed_label');

            $table->foreign('room_id')->references('id')->on('hst_rooms');
        });

        Schema::create('hst_fee_structures', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->unsignedInteger('academic_session_id');
            $table->enum('room_type', ['single', 'double', 'triple', 'dormitory']);
            $table->enum('meal_plan', ['full_board', 'lunch_only', 'dinner_only', 'none']);
            $table->decimal('room_rent_monthly', 10, 2)->default(0.00);
            $table->decimal('mess_charge_monthly', 10, 2)->default(0.00);
            $table->decimal('electricity_charge_monthly', 10, 2)->default(0.00);
            $table->decimal('laundry_charge_monthly', 10, 2)->default(0.00);
            $table->decimal('security_deposit', 10, 2)->default(0.00);
            $table->date('effective_from');
            $table->date('effective_to')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(
                ['hostel_id', 'academic_session_id', 'room_type', 'meal_plan', 'effective_from'],
                'uq_hst_fee_struct'
            );
            $table->index('academic_session_id');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('academic_session_id')->references('id')->on('sch_academic_term');
        });

        Schema::create('hst_mess_weekly_menus', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->unsignedInteger('academic_session_id');
            $table->date('week_start_date');
            $table->tinyInteger('day_of_week')->unsigned();
            $table->enum('meal_type', ['breakfast', 'lunch', 'dinner', 'snacks']);
            $table->text('menu_description')->nullable();
            $table->tinyInteger('is_special_diet_available')->default(0);
            $table->string('special_diet_description', 500)->nullable();
            $table->tinyInteger('is_published')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(
                ['hostel_id', 'week_start_date', 'day_of_week', 'meal_type'],
                'uq_hst_menu_slot'
            );
            $table->index('academic_session_id');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('academic_session_id')->references('id')->on('sch_academic_term');
        });

        Schema::create('hst_room_inventory', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('room_id');
            $table->string('item_name', 150);
            $table->tinyInteger('quantity')->unsigned()->default(1);
            $table->enum('condition', ['good', 'fair', 'poor', 'under_repair', 'disposed'])->default('good');
            $table->date('last_inspected_at')->nullable();
            $table->text('damage_description')->nullable();
            $table->decimal('estimated_repair_cost', 10, 2)->nullable();
            $table->enum('repair_status', ['none', 'pending', 'under_repair', 'repaired', 'written_off'])->default('none');
            $table->unsignedInteger('responsible_student_id')->nullable();
            $table->tinyInteger('charge_pushed_to_fee')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index('responsible_student_id');

            $table->foreign('room_id')->references('id')->on('hst_rooms');
            $table->foreign('responsible_student_id')->references('id')->on('std_students')->nullOnDelete();
        });

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 5 — Depends on Layer 4 + std_students / sys_users
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_allotments', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->unsignedBigInteger('bed_id');
            $table->unsignedInteger('academic_session_id');
            $table->date('allotment_date');
            $table->date('vacating_date')->nullable();
            $table->enum('meal_plan', ['full_board', 'lunch_only', 'dinner_only', 'none'])->default('full_board');
            $table->enum('status', ['active', 'vacated', 'transferred', 'waitlisted'])->default('active');
            $table->string('remarks', 500)->nullable();

            // Generated columns for partial UNIQUE — double-allotment prevention
            // BR-HST-001: one active allotment per bed
            // BR-HST-002: one active allotment per student
            $table->bigInteger('gen_active_bed_id')
                ->nullable()
                ->storedAs("IF(`status` = 'active', `bed_id`, NULL)");
            $table->bigInteger('gen_active_student_id')
                ->nullable()
                ->storedAs("IF(`status` = 'active', `student_id`, NULL)");

            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique('gen_active_bed_id', 'uq_hst_allot_active_bed');
            $table->unique('gen_active_student_id', 'uq_hst_allot_active_student');
            $table->index(['student_id', 'status'], 'idx_hst_allot_student_status');
            $table->index(['bed_id', 'status'], 'idx_hst_allot_bed_status');
            $table->index('academic_session_id');

            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('bed_id')->references('id')->on('hst_beds');
            $table->foreign('academic_session_id')->references('id')->on('sch_academic_term');
        });

        Schema::create('hst_special_diets', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->unsignedBigInteger('hostel_id');
            $table->enum('diet_type', ['diabetic', 'jain_vegetarian', 'gluten_free', 'nut_allergy', 'religious_fasting', 'custom']);
            $table->string('custom_description', 300)->nullable();
            $table->json('fasting_days_json')->nullable();
            $table->date('effective_from');
            $table->date('effective_to')->nullable();
            $table->string('prescribed_by', 150)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index('student_id');
            $table->index('hostel_id');

            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
        });

        Schema::create('hst_visitor_log', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->unsignedInteger('student_id');
            $table->string('visitor_name', 150);
            $table->enum('relationship', ['parent', 'guardian', 'sibling', 'relative', 'other']);
            $table->string('visitor_phone', 20)->nullable();
            $table->string('id_proof_type', 50)->nullable();
            $table->string('id_proof_number_masked', 30)->nullable();
            $table->date('visit_date');
            $table->time('in_time');
            $table->time('out_time')->nullable();
            $table->string('purpose', 300)->nullable();
            $table->unsignedInteger('allowed_by')->nullable();
            $table->tinyInteger('is_outside_visiting_hours')->default(0);
            $table->string('override_reason', 300)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index(['hostel_id', 'visit_date'], 'idx_hst_vl_hostel_date');
            $table->index('student_id');
            $table->index('allowed_by');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('allowed_by')->references('id')->on('sys_users')->nullOnDelete();
        });

        Schema::create('hst_movement_log', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->unsignedBigInteger('hostel_id');
            $table->date('movement_date');
            $table->time('out_time');
            $table->time('in_time')->nullable();
            $table->time('expected_return_time')->nullable();
            $table->string('destination', 255);
            $table->string('purpose', 500)->nullable();
            $table->unsignedInteger('gate_pass_issued_by')->nullable();
            $table->tinyInteger('overdue_notified')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index(['hostel_id', 'movement_date'], 'idx_hst_ml_hostel_date');
            $table->index(['student_id', 'in_time'], 'idx_hst_ml_student_in');
            $table->index('gate_pass_issued_by');

            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('gate_pass_issued_by')->references('id')->on('sys_users')->nullOnDelete();
        });

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 6 — Depends on Layer 5 + cross-module
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_attendance', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->date('attendance_date');
            $table->enum('shift', ['morning', 'evening', 'night']);
            $table->unsignedInteger('marked_by');
            $table->smallInteger('present_count')->unsigned()->default(0);
            $table->smallInteger('absent_count')->unsigned()->default(0);
            $table->smallInteger('leave_count')->unsigned()->default(0);
            $table->smallInteger('late_count')->unsigned()->default(0);
            $table->tinyInteger('is_locked')->default(0);
            $table->string('remarks', 500)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(['hostel_id', 'attendance_date', 'shift'], 'uq_hst_att_session');
            $table->index('marked_by');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('marked_by')->references('id')->on('sys_users');
        });

        Schema::create('hst_incidents', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->unsignedBigInteger('hostel_id');
            $table->date('incident_date');
            $table->time('incident_time')->nullable();
            $table->string('incident_type', 100);
            $table->text('description');
            $table->enum('severity', ['minor', 'moderate', 'serious']);
            $table->text('action_taken')->nullable();
            $table->unsignedInteger('reported_by');
            $table->tinyInteger('is_escalated')->default(0);
            $table->timestamp('escalated_at')->nullable();
            $table->tinyInteger('warning_letter_sent')->default(0);
            $table->tinyInteger('parent_notified')->default(0);
            $table->tinyInteger('is_auto_generated')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index('student_id');
            $table->index('hostel_id');
            $table->index('reported_by');
            $table->index('incident_date');

            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('reported_by')->references('id')->on('sys_users');
        });

        Schema::create('hst_mess_attendance', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->date('attendance_date');
            $table->enum('meal_type', ['breakfast', 'lunch', 'dinner', 'snacks']);
            $table->unsignedInteger('student_id');
            $table->enum('status', ['present', 'absent', 'on_leave', 'opted_out']);
            $table->tinyInteger('is_special_diet_served')->default(0);
            $table->string('special_diet_served_desc', 255)->nullable();
            $table->unsignedInteger('marked_by')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(
                ['hostel_id', 'attendance_date', 'meal_type', 'student_id'],
                'uq_hst_mess_att'
            );
            $table->index('student_id');
            $table->index('marked_by');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('marked_by')->references('id')->on('sys_users')->nullOnDelete();
        });

        Schema::create('hst_complaints', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->unsignedBigInteger('room_id')->nullable();
            $table->unsignedInteger('reported_by_student_id')->nullable();
            $table->unsignedInteger('reported_by_user_id')->nullable();
            $table->enum('category', ['maintenance', 'electrical', 'plumbing', 'cleanliness', 'security', 'food', 'other']);
            $table->string('subject', 255);
            $table->text('description');
            $table->enum('priority', ['low', 'medium', 'high', 'urgent'])->default('medium');
            $table->enum('status', ['open', 'in_progress', 'resolved', 'escalated', 'closed'])->default('open');
            $table->unsignedInteger('assigned_to')->nullable();
            $table->text('resolution_notes')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('sla_due_at')->nullable();
            $table->tinyInteger('is_escalated')->default(0);
            $table->timestamp('escalated_at')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index('hostel_id');
            $table->index('room_id');
            $table->index('reported_by_student_id');
            $table->index('reported_by_user_id');
            $table->index('assigned_to');
            $table->index('sla_due_at');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('room_id')->references('id')->on('hst_rooms')->nullOnDelete();
            $table->foreign('reported_by_student_id')->references('id')->on('std_students')->nullOnDelete();
            $table->foreign('reported_by_user_id')->references('id')->on('sys_users')->nullOnDelete();
            $table->foreign('assigned_to')->references('id')->on('sys_users')->nullOnDelete();
        });

        Schema::create('hst_sick_bay_log', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('hostel_id');
            $table->unsignedInteger('student_id');
            $table->dateTime('admission_datetime');
            $table->dateTime('discharge_datetime')->nullable();
            $table->text('presenting_symptoms');
            $table->string('initial_diagnosis', 500)->nullable();
            $table->text('treatment_notes')->nullable();
            $table->unsignedInteger('attending_staff_id')->nullable();
            $table->text('discharge_notes')->nullable();
            $table->tinyInteger('is_hospital_referred')->default(0);
            // NO ->foreign() for hpc_record_id — soft reference to HPC module, no DB constraint
            $table->unsignedBigInteger('hpc_record_id')->nullable();
            $table->tinyInteger('parent_notified')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index(['hostel_id', 'admission_datetime'], 'idx_hst_sb_hostel_admission');
            $table->index('student_id');
            $table->index('discharge_datetime');
            $table->index('attending_staff_id');

            $table->foreign('hostel_id')->references('id')->on('hst_hostels');
            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('attending_staff_id')->references('id')->on('sys_users')->nullOnDelete();
            // hpc_record_id: intentionally no FK constraint — soft reference to HPC module
        });

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 7 — Depends on Layer 5 (allotments) + Layer 6 (attendance, incidents)
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_attendance_entries', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('attendance_id');
            $table->unsignedInteger('student_id');
            $table->enum('status', ['present', 'absent', 'leave', 'home', 'late', 'sick_bay']);
            $table->string('late_remarks', 255)->nullable();
            $table->time('check_in_time')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->unique(['attendance_id', 'student_id'], 'uq_hst_att_entry');
            $table->index('student_id');

            // CASCADE DELETE: entries deleted when parent session is deleted
            $table->foreign('attendance_id')
                ->references('id')
                ->on('hst_attendance')
                ->onDelete('cascade');
            $table->foreign('student_id')->references('id')->on('std_students');
        });

        Schema::create('hst_room_change_requests', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->unsignedBigInteger('from_allotment_id');
            $table->unsignedBigInteger('requested_room_id')->nullable();
            $table->text('reason');
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->unsignedInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->unsignedBigInteger('new_allotment_id')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index('student_id');
            $table->index('from_allotment_id');
            $table->index('requested_room_id');
            $table->index('approved_by');
            $table->index('new_allotment_id');

            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('from_allotment_id')->references('id')->on('hst_allotments');
            $table->foreign('requested_room_id')->references('id')->on('hst_rooms')->nullOnDelete();
            $table->foreign('approved_by')->references('id')->on('sys_users')->nullOnDelete();
            $table->foreign('new_allotment_id')->references('id')->on('hst_allotments')->nullOnDelete();
        });

        Schema::create('hst_leave_passes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('student_id');
            $table->unsignedBigInteger('allotment_id');
            $table->enum('leave_type', ['home', 'emergency', 'medical', 'festival', 'vacation', 'other']);
            $table->date('from_date');
            $table->date('to_date');
            $table->string('destination', 255);
            $table->string('purpose', 500);
            $table->string('guardian_contact', 20)->nullable();
            $table->unsignedInteger('applied_by');
            $table->unsignedInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected', 'returned', 'cancelled'])->default('pending');
            $table->text('rejection_reason')->nullable();
            $table->date('actual_return_date')->nullable();
            $table->unsignedBigInteger('late_return_incident_id')->nullable();
            $table->tinyInteger('parent_notified')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index('student_id');
            $table->index('allotment_id');
            $table->index('applied_by');
            $table->index('approved_by');
            $table->index('late_return_incident_id');

            $table->foreign('student_id')->references('id')->on('std_students');
            $table->foreign('allotment_id')->references('id')->on('hst_allotments');
            $table->foreign('applied_by')->references('id')->on('sys_users');
            $table->foreign('approved_by')->references('id')->on('sys_users')->nullOnDelete();
            $table->foreign('late_return_incident_id')->references('id')->on('hst_incidents')->nullOnDelete();
        });

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 8 — Depends on Layer 6 (hst_incidents) + sys_media
        // ─────────────────────────────────────────────────────────────────────

        Schema::create('hst_incident_media', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('incident_id');
            // INT UNSIGNED — matches sys_media.id which is INT UNSIGNED (not BIGINT)
            $table->unsignedInteger('media_id');
            $table->string('media_type', 50)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by');
            $table->unsignedInteger('updated_by');
            $table->timestamp('created_at')->nullable();
            $table->timestamp('updated_at')->nullable();
            $table->timestamp('deleted_at')->nullable();

            $table->index('incident_id');
            $table->index('media_id');

            // CASCADE DELETE: media rows deleted when incident is deleted
            $table->foreign('incident_id')
                ->references('id')
                ->on('hst_incidents')
                ->onDelete('cascade');
            $table->foreign('media_id')->references('id')->on('sys_media');
        });
    }

    public function down(): void
    {
        // Drop in reverse Layer order (Layer 8 → Layer 1)
        Schema::dropIfExists('hst_incident_media');       // L8
        Schema::dropIfExists('hst_leave_passes');          // L7
        Schema::dropIfExists('hst_room_change_requests'); // L7
        Schema::dropIfExists('hst_attendance_entries');   // L7
        Schema::dropIfExists('hst_sick_bay_log');         // L6
        Schema::dropIfExists('hst_complaints');           // L6
        Schema::dropIfExists('hst_mess_attendance');      // L6
        Schema::dropIfExists('hst_incidents');            // L6
        Schema::dropIfExists('hst_attendance');           // L6
        Schema::dropIfExists('hst_movement_log');         // L5
        Schema::dropIfExists('hst_visitor_log');          // L5
        Schema::dropIfExists('hst_special_diets');        // L5
        Schema::dropIfExists('hst_allotments');           // L5
        Schema::dropIfExists('hst_room_inventory');       // L4
        Schema::dropIfExists('hst_mess_weekly_menus');    // L4
        Schema::dropIfExists('hst_fee_structures');       // L4
        Schema::dropIfExists('hst_beds');                 // L4
        Schema::dropIfExists('hst_rooms');                // L3
        Schema::dropIfExists('hst_warden_assignments');   // L2
        Schema::dropIfExists('hst_floors');               // L2
        Schema::dropIfExists('hst_hostels');              // L1
    }
};
