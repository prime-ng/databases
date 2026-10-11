<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// =============================================================================
// MNT — Maintenance Management Module Migration
// File:     database/migrations/tenant/2026_03_27_000000_create_mnt_tables.php
// Creates:  11 mnt_* tables in dependency-safe order (Layer 1 → Layer 7)
// Drops:    Reverse order (Layer 7 → Layer 1)
// Notes:
//   - BIGINT UNSIGNED for sys_* cross-module FKs (sys_users, sys_roles)
//   - INT UNSIGNED    for mnt_* internal FKs and vnd_* FKs
//   - mnt_asset_depreciation : no softDeletes, no is_active, no updated_by (immutable)
//   - mnt_breakdown_history  : no softDeletes, no is_active                 (immutable)
//   - No tenant_id columns — stancl/tenancy v3.9 uses separate DB per tenant
// =============================================================================

return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No mnt_* dependencies
        // =====================================================================

        Schema::create('mnt_asset_categories', function (Blueprint $table) {
            $table->increments('id');
            $table->string('name', 100)->unique();
            $table->string('code', 20)->nullable()->unique();
            $table->text('description')->nullable();
            $table->enum('default_priority', ['Low', 'Medium', 'High', 'Critical'])->default('Medium');
            $table->unsignedSmallInteger('sla_hours')->default(24);
            $table->unsignedBigInteger('auto_assign_role_id')->nullable()->index();
            $table->json('priority_keywords_json')->nullable();
            $table->json('sla_escalation_json')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
        });

        // =====================================================================
        // LAYER 2 — Depends on vnd_vendors (cross-module); before mnt_assets
        // =====================================================================

        Schema::create('mnt_amc_contracts', function (Blueprint $table) {
            $table->increments('id');
            $table->string('contract_number', 50)->nullable()->unique();
            $table->string('contract_title', 200);
            $table->unsignedInteger('vendor_id')->nullable()->index();
            $table->string('vendor_name_text', 150)->nullable();
            $table->string('vendor_contact', 100)->nullable();
            $table->text('scope_description')->nullable();
            $table->json('covered_assets_ids_json')->nullable();
            $table->date('start_date');
            $table->date('end_date')->index();
            $table->decimal('contract_value', 12, 2)->nullable();
            $table->enum('payment_frequency', ['Monthly', 'Quarterly', 'Half_Yearly', 'Yearly'])->nullable();
            $table->string('visit_frequency', 100)->nullable();
            $table->enum('status', ['Active', 'Expired', 'Cancelled', 'Pending_Renewal'])->default('Active')->index();
            $table->boolean('renewal_alert_sent_60')->default(false);
            $table->boolean('renewal_alert_sent_30')->default(false);
            $table->boolean('renewal_alert_sent_7')->default(false);
            $table->unsignedInteger('document_media_id')->nullable()->index();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('vendor_id')->references('id')->on('vnd_vendors')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 3 — Depends on Layer 1 + Layer 2 + sys_media
        // =====================================================================

        Schema::create('mnt_assets', function (Blueprint $table) {
            $table->increments('id');
            $table->string('asset_code', 30)->unique();
            $table->string('name', 150);
            $table->unsignedInteger('category_id')->index();
            $table->string('location_building', 100)->nullable();
            $table->string('location_floor', 20)->nullable();
            $table->string('location_room', 50)->nullable();
            $table->date('purchase_date')->nullable();
            $table->decimal('purchase_cost', 12, 2)->nullable();
            $table->decimal('salvage_value', 12, 2)->nullable();
            $table->unsignedTinyInteger('useful_life_years')->nullable();
            $table->enum('depreciation_method', ['SLM', 'WDV'])->nullable();
            $table->decimal('depreciation_rate', 5, 2)->nullable();
            $table->decimal('accumulated_depreciation', 12, 2)->default(0.00);
            $table->decimal('current_book_value', 12, 2)->nullable();
            $table->date('warranty_expiry_date')->nullable();
            $table->enum('current_condition', ['Good', 'Fair', 'Poor', 'Critical', 'Decommissioned'])->default('Good')->index();
            $table->date('last_pm_date')->nullable();
            $table->date('next_pm_due_date')->nullable();
            $table->unsignedInteger('amc_contract_id')->nullable()->index();
            $table->decimal('total_maintenance_cost', 12, 2)->default(0.00);
            $table->unsignedInteger('qr_code_media_id')->nullable()->index();
            $table->unsignedInteger('photo_media_id')->nullable()->index();
            $table->text('notes')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('category_id')->references('id')->on('mnt_asset_categories');
            $table->foreign('amc_contract_id')->references('id')->on('mnt_amc_contracts')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 4a — mnt_asset_depreciation
        //   EXCEPTION: no is_active, no updated_by, no softDeletes (DDL rule 14)
        // =====================================================================

        Schema::create('mnt_asset_depreciation', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('asset_id')->index();
            $table->string('financial_year', 9);
            $table->enum('method', ['SLM', 'WDV']);
            $table->decimal('opening_book_value', 12, 2);
            $table->decimal('depreciation_rate', 5, 2);
            $table->decimal('annual_charge', 12, 2);
            $table->decimal('closing_book_value', 12, 2);
            $table->boolean('posted_to_fac')->default(false);
            $table->unsignedInteger('fac_journal_id')->nullable(); // future FK to acc_journal_entries
            $table->unsignedBigInteger('created_by');
            $table->timestamps(); // created_at + updated_at only

            $table->unique(['asset_id', 'financial_year']);
            $table->index('financial_year');
            $table->foreign('asset_id')->references('id')->on('mnt_assets');
        });

        // =====================================================================
        // LAYER 4b — mnt_pm_schedules
        // =====================================================================

        Schema::create('mnt_pm_schedules', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('asset_id')->index();
            $table->unsignedInteger('category_id')->nullable()->index();
            $table->string('title', 200);
            $table->text('description')->nullable();
            $table->enum('recurrence', ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly']);
            $table->unsignedTinyInteger('recurrence_day')->nullable();
            $table->json('checklist_items_json'); // NOT NULL — min 1 item enforced at service layer
            $table->date('start_date');
            $table->date('next_due_date')->nullable()->index();
            $table->unsignedBigInteger('assign_to_role_id')->nullable()->index();
            $table->decimal('estimated_hours', 4, 2)->nullable();
            $table->timestamp('last_generated_at')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('asset_id')->references('id')->on('mnt_assets');
            $table->foreign('category_id')->references('id')->on('mnt_asset_categories')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 5 — mnt_tickets (core ticket table)
        // =====================================================================

        Schema::create('mnt_tickets', function (Blueprint $table) {
            $table->increments('id');
            $table->string('ticket_number', 30)->unique();
            $table->string('title', 200);
            $table->unsignedInteger('category_id');
            $table->unsignedInteger('asset_id')->nullable();
            $table->text('description');
            $table->string('location_building', 100);
            $table->string('location_floor', 20)->nullable();
            $table->string('location_room', 50)->nullable();
            $table->enum('priority', ['Low', 'Medium', 'High', 'Critical']);
            $table->enum('priority_source', ['Auto_Keyword', 'Auto_Category', 'Manual_Override'])->default('Auto_Category');
            $table->enum('status', ['Open', 'Accepted', 'In_Progress', 'On_Hold', 'Resolved', 'Closed', 'Cancelled'])->default('Open');
            $table->unsignedBigInteger('requester_user_id');
            $table->unsignedBigInteger('assigned_to_user_id')->nullable();
            $table->date('requested_date');
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->timestamp('sla_due_at')->nullable();
            $table->boolean('is_sla_breached')->default(false);
            $table->unsignedTinyInteger('escalation_level')->default(0);
            $table->text('resolution_notes')->nullable();
            $table->decimal('total_hours_logged', 6, 2)->default(0.00);
            $table->decimal('total_parts_cost', 10, 2)->default(0.00);
            $table->unsignedTinyInteger('requester_rating')->nullable();
            $table->text('requester_feedback')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            // 5 composite indexes required by spec
            $table->index(['status', 'priority'],            'idx_mnt_tkt_status_priority');
            $table->index(['assigned_to_user_id', 'status'], 'idx_mnt_tkt_assigned_status');
            $table->index(['category_id', 'status'],         'idx_mnt_tkt_category_status');
            $table->index('sla_due_at',                      'idx_mnt_tkt_sla_due');
            $table->index(['is_sla_breached', 'status'],     'idx_mnt_tkt_breach_status');
            $table->index('asset_id');
            $table->index('requester_user_id');

            $table->foreign('category_id')->references('id')->on('mnt_asset_categories');
            $table->foreign('asset_id')->references('id')->on('mnt_assets')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 6a — mnt_ticket_assignments
        // =====================================================================

        Schema::create('mnt_ticket_assignments', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('ticket_id');
            $table->unsignedBigInteger('assigned_to_user_id');
            $table->unsignedBigInteger('assigned_by_user_id')->nullable();
            $table->enum('assignment_type', ['Auto', 'Manual', 'Reassigned'])->default('Auto');
            $table->boolean('is_current')->default(true);
            $table->timestamp('assigned_at')->useCurrent();
            $table->timestamp('released_at')->nullable();
            $table->text('reassign_reason')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['ticket_id', 'is_current'], 'idx_mnt_tasn_ticket_current');
            $table->index('assigned_to_user_id');
            $table->index('assigned_by_user_id');
            $table->foreign('ticket_id')->references('id')->on('mnt_tickets');
        });

        // =====================================================================
        // LAYER 6b — mnt_ticket_time_logs
        // =====================================================================

        Schema::create('mnt_ticket_time_logs', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('ticket_id')->index();
            $table->unsignedBigInteger('logged_by_user_id')->index();
            $table->date('work_date');
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();
            $table->decimal('hours_spent', 4, 2);
            $table->text('work_description')->nullable();
            $table->text('parts_used')->nullable();
            $table->decimal('parts_cost', 10, 2)->default(0.00);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('ticket_id')->references('id')->on('mnt_tickets');
        });

        // =====================================================================
        // LAYER 6c — mnt_breakdown_history
        //   EXCEPTION: no is_active, no softDeletes (DDL rule 14)
        // =====================================================================

        Schema::create('mnt_breakdown_history', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('asset_id');
            $table->unsignedInteger('ticket_id')->nullable();
            $table->date('breakdown_date');
            $table->date('resolved_date')->nullable();
            $table->decimal('downtime_hours', 6, 2)->nullable();
            $table->text('root_cause')->nullable();
            $table->decimal('cost_incurred', 10, 2)->default(0.00);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps(); // no softDeletes

            $table->index(['asset_id', 'breakdown_date'], 'idx_mnt_bkd_asset_date');
            $table->index('ticket_id');
            $table->foreign('asset_id')->references('id')->on('mnt_assets');
            $table->foreign('ticket_id')->references('id')->on('mnt_tickets')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 7a — mnt_pm_work_orders
        // =====================================================================

        Schema::create('mnt_pm_work_orders', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('pm_schedule_id');
            $table->unsignedInteger('asset_id');
            $table->string('wo_number', 30)->nullable()->unique();
            $table->date('due_date')->index();
            $table->unsignedBigInteger('assigned_to_user_id')->nullable()->index();
            $table->enum('status', ['Pending', 'In_Progress', 'Completed', 'Overdue', 'Cancelled'])->default('Pending')->index();
            $table->json('checklist_completion_json')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->decimal('hours_spent', 4, 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['pm_schedule_id', 'status'], 'idx_mnt_pmwo_schedule_status');
            $table->index('asset_id');
            $table->foreign('pm_schedule_id')->references('id')->on('mnt_pm_schedules');
            $table->foreign('asset_id')->references('id')->on('mnt_assets');
        });

        // =====================================================================
        // LAYER 7b — mnt_work_orders
        // =====================================================================

        Schema::create('mnt_work_orders', function (Blueprint $table) {
            $table->increments('id');
            $table->string('wo_number', 30)->unique();
            $table->unsignedInteger('ticket_id')->nullable()->index();
            $table->unsignedInteger('amc_contract_id')->nullable()->index();
            $table->unsignedInteger('asset_id')->nullable()->index();
            $table->unsignedInteger('vendor_id')->nullable()->index();
            $table->string('vendor_name_text', 150)->nullable();
            $table->text('work_description');
            $table->date('scheduled_date')->nullable();
            $table->decimal('estimated_cost', 12, 2)->nullable();
            $table->decimal('actual_cost', 12, 2)->nullable();
            $table->string('purchase_order_number', 50)->nullable();
            $table->enum('status', ['Draft', 'Issued', 'In_Progress', 'Completed', 'Cancelled'])->default('Draft')->index();
            $table->date('completed_date')->nullable();
            $table->text('notes')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('ticket_id')->references('id')->on('mnt_tickets')->nullOnDelete();
            $table->foreign('amc_contract_id')->references('id')->on('mnt_amc_contracts')->nullOnDelete();
            $table->foreign('asset_id')->references('id')->on('mnt_assets')->nullOnDelete();
            $table->foreign('vendor_id')->references('id')->on('vnd_vendors')->nullOnDelete();
        });
    }

    public function down(): void
    {
        // Drop in reverse dependency order (Layer 7 → Layer 1)
        Schema::dropIfExists('mnt_work_orders');
        Schema::dropIfExists('mnt_pm_work_orders');
        Schema::dropIfExists('mnt_breakdown_history');
        Schema::dropIfExists('mnt_ticket_time_logs');
        Schema::dropIfExists('mnt_ticket_assignments');
        Schema::dropIfExists('mnt_tickets');
        Schema::dropIfExists('mnt_pm_schedules');
        Schema::dropIfExists('mnt_asset_depreciation');
        Schema::dropIfExists('mnt_assets');
        Schema::dropIfExists('mnt_amc_contracts');
        Schema::dropIfExists('mnt_asset_categories');
    }
};
