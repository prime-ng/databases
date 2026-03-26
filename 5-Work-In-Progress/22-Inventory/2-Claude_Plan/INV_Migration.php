<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * INV — Inventory Module Migration
 * 28 tables in 10 dependency layers
 *
 * FK type notes (verified against tenant_db_v2.sql):
 *   sch_department.id, sch_employees.id, vnd_vendors.id = INT UNSIGNED  → unsignedInteger()
 *   acc_ledgers.id, acc_tax_rates.id, acc_fixed_assets.id = BIGINT UNSIGNED → unsignedBigInteger()
 *   acc_vouchers: NOT YET in tenant_db — FK constraints commented out (Decision D21)
 *   All sys_users refs = BIGINT UNSIGNED
 *
 * File path: database/migrations/tenant/2026_03_26_000000_create_inv_tables.php
 */
return new class extends Migration
{
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No inv_* dependencies
        // =====================================================================

        Schema::create('inv_units_of_measure', function (Blueprint $table) {
            $table->id();
            $table->string('name', 50);
            $table->string('symbol', 10);
            $table->tinyInteger('decimal_places')->default(0);
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('is_active', 'idx_inv_uom_is_active');
        });

        Schema::create('inv_asset_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('code', 20)->nullable()->unique('uq_inv_ac_code');
            $table->decimal('depreciation_rate', 5, 2)->nullable();
            $table->integer('useful_life_years')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('is_active', 'idx_inv_acat_is_active');
        });

        // =====================================================================
        // LAYER 2 — Depends on Layer 1
        // =====================================================================

        Schema::create('inv_stock_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('code', 20)->nullable()->unique('uq_inv_sg_code');
            $table->string('alias', 100)->nullable();
            $table->unsignedBigInteger('parent_id')->nullable();
            $table->unsignedBigInteger('default_uom_id')->nullable();
            $table->integer('sequence')->default(0);
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('parent_id', 'idx_inv_sg_parent_id');
            $table->index('default_uom_id', 'idx_inv_sg_default_uom_id');
            $table->index('is_active', 'idx_inv_sg_is_active');
            $table->foreign('parent_id', 'fk_inv_sg_parent_id')
                  ->references('id')->on('inv_stock_groups')->nullOnDelete();
            $table->foreign('default_uom_id', 'fk_inv_sg_default_uom_id')
                  ->references('id')->on('inv_units_of_measure')->nullOnDelete();
        });

        Schema::create('inv_uom_conversions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('from_uom_id');
            $table->unsignedBigInteger('to_uom_id');
            $table->decimal('conversion_factor', 15, 6);
            $table->date('effective_from')->nullable();
            $table->date('effective_to')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['from_uom_id', 'to_uom_id'], 'uq_inv_uom_conv');
            $table->index('from_uom_id', 'idx_inv_uom_conv_from');
            $table->index('to_uom_id', 'idx_inv_uom_conv_to');
            $table->foreign('from_uom_id', 'fk_inv_uom_conv_from_uom_id')
                  ->references('id')->on('inv_units_of_measure');
            $table->foreign('to_uom_id', 'fk_inv_uom_conv_to_uom_id')
                  ->references('id')->on('inv_units_of_measure');
        });

        // =====================================================================
        // LAYER 3 — Depends on Layer 2 + cross-module
        // =====================================================================

        Schema::create('inv_stock_items', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->string('sku', 50)->nullable()->unique('uq_inv_si_sku');
            $table->string('alias', 150)->nullable();
            $table->unsignedBigInteger('stock_group_id');
            $table->unsignedBigInteger('uom_id');
            $table->enum('item_type', ['consumable', 'asset'])->default('consumable');
            $table->decimal('opening_balance_qty', 15, 3)->default(0);
            $table->decimal('opening_balance_rate', 15, 2)->default(0);
            $table->decimal('opening_balance_value', 15, 2)->default(0);
            $table->enum('valuation_method', ['fifo', 'weighted_average', 'last_purchase'])->default('weighted_average');
            $table->decimal('reorder_level', 15, 3)->nullable();
            $table->decimal('reorder_qty', 15, 3)->nullable();
            $table->decimal('min_stock', 15, 3)->nullable();
            $table->decimal('max_stock', 15, 3)->nullable();
            $table->boolean('auto_reorder_pr')->default(false);
            $table->boolean('has_batch_tracking')->default(false);
            $table->boolean('has_expiry_tracking')->default(false);
            $table->string('hsn_sac_code', 20)->nullable();
            $table->string('brand', 100)->nullable();
            $table->string('model', 100)->nullable();
            $table->integer('warranty_months')->nullable();
            $table->unsignedBigInteger('tax_rate_id')->nullable();          // acc_tax_rates.id
            $table->unsignedBigInteger('purchase_ledger_id')->nullable();   // acc_ledgers.id
            $table->unsignedBigInteger('sales_ledger_id')->nullable();      // acc_ledgers.id
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('stock_group_id', 'idx_inv_sitm_stock_group_id');
            $table->index('uom_id', 'idx_inv_sitm_uom_id');
            $table->index('item_type', 'idx_inv_sitm_item_type');
            $table->index('tax_rate_id', 'idx_inv_sitm_tax_rate_id');
            $table->index('purchase_ledger_id', 'idx_inv_sitm_purchase_ledger_id');
            $table->index('sales_ledger_id', 'idx_inv_sitm_sales_ledger_id');
            $table->index('is_active', 'idx_inv_sitm_is_active');
            $table->foreign('stock_group_id', 'fk_inv_sitm_stock_group_id')
                  ->references('id')->on('inv_stock_groups');
            $table->foreign('uom_id', 'fk_inv_sitm_uom_id')
                  ->references('id')->on('inv_units_of_measure');
            // UNCOMMENT after Accounting DDL applied:
            // $table->foreign('tax_rate_id', 'fk_inv_sitm_tax_rate_id')->references('id')->on('acc_tax_rates')->nullOnDelete();
            // $table->foreign('purchase_ledger_id', 'fk_inv_sitm_purchase_ledger_id')->references('id')->on('acc_ledgers')->nullOnDelete();
            // $table->foreign('sales_ledger_id', 'fk_inv_sitm_sales_ledger_id')->references('id')->on('acc_ledgers')->nullOnDelete();
        });

        Schema::create('inv_godowns', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('code', 20)->nullable()->unique('uq_inv_gdn_code');
            $table->unsignedBigInteger('parent_id')->nullable();
            $table->string('address', 500)->nullable();
            $table->unsignedInteger('in_charge_employee_id')->nullable(); // sch_employees.id INT UNSIGNED
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('parent_id', 'idx_inv_gdn_parent_id');
            $table->index('in_charge_employee_id', 'idx_inv_gdn_in_charge_employee_id');
            $table->index('is_active', 'idx_inv_gdn_is_active');
            $table->foreign('parent_id', 'fk_inv_gdn_parent_id')
                  ->references('id')->on('inv_godowns')->nullOnDelete();
            // $table->foreign('in_charge_employee_id', 'fk_inv_gdn_in_charge_employee_id')->references('id')->on('sch_employees')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 4 — Depends on Layer 3 + cross-module
        // =====================================================================

        Schema::create('inv_stock_balances', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('stock_item_id');
            $table->unsignedBigInteger('godown_id');
            $table->decimal('current_qty', 15, 3)->default(0);
            $table->decimal('current_value', 15, 2)->default(0);
            $table->timestamp('last_entry_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['stock_item_id', 'godown_id'], 'uq_inv_sb_item_godown');
            $table->index('godown_id', 'idx_inv_sbal_godown_id');
            $table->index('is_active', 'idx_inv_sbal_is_active');
            $table->foreign('stock_item_id', 'fk_inv_sbal_stock_item_id')
                  ->references('id')->on('inv_stock_items');
            $table->foreign('godown_id', 'fk_inv_sbal_godown_id')
                  ->references('id')->on('inv_godowns');
        });

        Schema::create('inv_item_vendor_jnt', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('item_id');
            $table->unsignedInteger('vendor_id'); // vnd_vendors.id INT UNSIGNED
            $table->string('vendor_sku', 50)->nullable();
            $table->decimal('last_purchase_rate', 15, 2)->nullable();
            $table->date('last_purchase_date')->nullable();
            $table->integer('lead_time_days')->nullable();
            $table->boolean('is_preferred')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['item_id', 'vendor_id'], 'uq_inv_ivj_item_vendor');
            $table->index('item_id', 'idx_inv_ivj_item_id');
            $table->index('vendor_id', 'idx_inv_ivj_vendor_id');
            $table->index('is_active', 'idx_inv_ivj_is_active');
            $table->foreign('item_id', 'fk_inv_ivj_item_id')
                  ->references('id')->on('inv_stock_items');
            // $table->foreign('vendor_id', 'fk_inv_ivj_vendor_id')->references('id')->on('vnd_vendors');
        });

        Schema::create('inv_rate_contracts', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('vendor_id'); // vnd_vendors.id INT UNSIGNED
            $table->string('contract_number', 50)->nullable()->unique('uq_inv_rc_contract_number');
            $table->date('valid_from');
            $table->date('valid_to');
            $table->enum('status', ['draft', 'active', 'expired', 'cancelled'])->default('draft');
            $table->text('remarks')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('vendor_id', 'idx_inv_rc_vendor_id');
            $table->index('status', 'idx_inv_rc_status');
            $table->index('valid_to', 'idx_inv_rc_valid_to');
            $table->index('is_active', 'idx_inv_rc_is_active');
            // $table->foreign('vendor_id', 'fk_inv_rc_vendor_id')->references('id')->on('vnd_vendors');
        });

        Schema::create('inv_purchase_requisitions', function (Blueprint $table) {
            $table->id();
            $table->string('pr_number', 50)->unique('uq_inv_pr_number');
            $table->unsignedBigInteger('requested_by');
            $table->unsignedInteger('department_id')->nullable(); // sch_department.id INT UNSIGNED
            $table->date('required_date');
            $table->enum('priority', ['low', 'normal', 'high', 'urgent'])->default('normal');
            $table->enum('status', ['draft', 'submitted', 'approved', 'rejected', 'converted', 'cancelled'])->default('draft');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->text('remarks')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('requested_by', 'idx_inv_pr_requested_by');
            $table->index('department_id', 'idx_inv_pr_department_id');
            $table->index('status', 'idx_inv_pr_status');
            $table->index('approved_by', 'idx_inv_pr_approved_by');
            $table->index('is_active', 'idx_inv_pr_is_active');
            // $table->foreign('department_id', 'fk_inv_pr_department_id')->references('id')->on('sch_department')->nullOnDelete();
        });

        Schema::create('inv_stock_adjustments', function (Blueprint $table) {
            $table->id();
            $table->string('adjustment_number', 50)->unique('uq_inv_sadj_number');
            $table->date('adjustment_date');
            $table->unsignedBigInteger('godown_id');
            $table->string('reason', 500)->nullable();
            $table->enum('status', ['draft', 'submitted', 'approved', 'rejected', 'posted'])->default('draft');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('godown_id', 'idx_inv_sadj_godown_id');
            $table->index('status', 'idx_inv_sadj_status');
            $table->index('approved_by', 'idx_inv_sadj_approved_by');
            $table->index('is_active', 'idx_inv_sadj_is_active');
            $table->foreign('godown_id', 'fk_inv_sadj_godown_id')
                  ->references('id')->on('inv_godowns');
        });

        // =====================================================================
        // LAYER 5 — Depends on Layer 4
        // =====================================================================

        Schema::create('inv_rate_contract_items_jnt', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rate_contract_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('agreed_rate', 15, 2);
            $table->decimal('min_qty', 15, 3)->nullable();
            $table->decimal('max_qty', 15, 3)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['rate_contract_id', 'item_id'], 'uq_inv_rcij_contract_item');
            $table->index('rate_contract_id', 'idx_inv_rcij_rate_contract_id');
            $table->index('item_id', 'idx_inv_rcij_item_id');
            $table->foreign('rate_contract_id', 'fk_inv_rcij_rate_contract_id')
                  ->references('id')->on('inv_rate_contracts')->cascadeOnDelete();
            $table->foreign('item_id', 'fk_inv_rcij_item_id')
                  ->references('id')->on('inv_stock_items');
        });

        Schema::create('inv_purchase_requisition_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pr_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('qty', 15, 3);
            $table->unsignedBigInteger('uom_id');
            $table->decimal('estimated_rate', 15, 2)->nullable();
            $table->string('remarks', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('pr_id', 'idx_inv_pri_pr_id');
            $table->index('item_id', 'idx_inv_pri_item_id');
            $table->index('uom_id', 'idx_inv_pri_uom_id');
            $table->foreign('pr_id', 'fk_inv_pri_pr_id')
                  ->references('id')->on('inv_purchase_requisitions')->cascadeOnDelete();
            $table->foreign('item_id', 'fk_inv_pri_item_id')
                  ->references('id')->on('inv_stock_items');
            $table->foreign('uom_id', 'fk_inv_pri_uom_id')
                  ->references('id')->on('inv_units_of_measure');
        });

        Schema::create('inv_quotations', function (Blueprint $table) {
            $table->id();
            $table->string('rfq_number', 50)->unique('uq_inv_quot_rfq_number');
            $table->unsignedBigInteger('pr_id')->nullable();
            $table->unsignedInteger('vendor_id'); // vnd_vendors.id INT UNSIGNED
            $table->date('validity_date')->nullable();
            $table->enum('status', ['draft', 'sent', 'received', 'expired', 'converted'])->default('draft');
            $table->text('notes')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('pr_id', 'idx_inv_quot_pr_id');
            $table->index('vendor_id', 'idx_inv_quot_vendor_id');
            $table->index('status', 'idx_inv_quot_status');
            $table->index('is_active', 'idx_inv_quot_is_active');
            $table->foreign('pr_id', 'fk_inv_quot_pr_id')
                  ->references('id')->on('inv_purchase_requisitions')->nullOnDelete();
            // $table->foreign('vendor_id', 'fk_inv_quot_vendor_id')->references('id')->on('vnd_vendors');
        });

        Schema::create('inv_issue_requests', function (Blueprint $table) {
            $table->id();
            $table->string('request_number', 50)->unique('uq_inv_ir_number');
            $table->unsignedBigInteger('requested_by');
            $table->unsignedInteger('department_id'); // sch_department.id INT UNSIGNED NOT NULL
            $table->date('required_date');
            $table->enum('status', ['submitted', 'approved', 'issued', 'partial', 'rejected'])->default('submitted');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->text('remarks')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('requested_by', 'idx_inv_ir_requested_by');
            $table->index('department_id', 'idx_inv_ir_department_id');
            $table->index('status', 'idx_inv_ir_status');
            $table->index('approved_by', 'idx_inv_ir_approved_by');
            $table->index('is_active', 'idx_inv_ir_is_active');
            // $table->foreign('department_id', 'fk_inv_ir_department_id')->references('id')->on('sch_department');
        });

        // =====================================================================
        // LAYER 6 — Depends on Layer 5
        // =====================================================================

        Schema::create('inv_quotation_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('quotation_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('quoted_rate', 15, 2);
            $table->integer('lead_time_days')->nullable();
            $table->string('remarks', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('quotation_id', 'idx_inv_qi_quotation_id');
            $table->index('item_id', 'idx_inv_qi_item_id');
            $table->foreign('quotation_id', 'fk_inv_qi_quotation_id')
                  ->references('id')->on('inv_quotations')->cascadeOnDelete();
            $table->foreign('item_id', 'fk_inv_qi_item_id')
                  ->references('id')->on('inv_stock_items');
        });

        Schema::create('inv_purchase_orders', function (Blueprint $table) {
            $table->id();
            $table->string('po_number', 50)->unique('uq_inv_po_number');
            $table->unsignedInteger('vendor_id'); // vnd_vendors.id INT UNSIGNED
            $table->unsignedBigInteger('pr_id')->nullable();
            $table->unsignedBigInteger('quotation_id')->nullable();
            $table->date('order_date');
            $table->date('expected_delivery_date')->nullable();
            $table->enum('status', ['draft', 'sent', 'partial', 'received', 'cancelled', 'closed'])->default('draft');
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->decimal('tax_amount', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('net_amount', 15, 2)->default(0);
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->decimal('approval_threshold_amount', 15, 2)->nullable();
            $table->text('terms_and_conditions')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('vendor_id', 'idx_inv_po_vendor_id');
            $table->index('pr_id', 'idx_inv_po_pr_id');
            $table->index('quotation_id', 'idx_inv_po_quotation_id');
            $table->index('status', 'idx_inv_po_status');
            $table->index('approved_by', 'idx_inv_po_approved_by');
            $table->index('is_active', 'idx_inv_po_is_active');
            $table->foreign('pr_id', 'fk_inv_po_pr_id')
                  ->references('id')->on('inv_purchase_requisitions')->nullOnDelete();
            $table->foreign('quotation_id', 'fk_inv_po_quotation_id')
                  ->references('id')->on('inv_quotations')->nullOnDelete();
            // $table->foreign('vendor_id', 'fk_inv_po_vendor_id')->references('id')->on('vnd_vendors');
        });

        Schema::create('inv_issue_request_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('issue_request_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('requested_qty', 15, 3);
            $table->decimal('issued_qty', 15, 3)->default(0);
            $table->unsignedBigInteger('uom_id');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('issue_request_id', 'idx_inv_iri_issue_request_id');
            $table->index('item_id', 'idx_inv_iri_item_id');
            $table->index('uom_id', 'idx_inv_iri_uom_id');
            $table->foreign('issue_request_id', 'fk_inv_iri_issue_request_id')
                  ->references('id')->on('inv_issue_requests')->cascadeOnDelete();
            $table->foreign('item_id', 'fk_inv_iri_item_id')
                  ->references('id')->on('inv_stock_items');
            $table->foreign('uom_id', 'fk_inv_iri_uom_id')
                  ->references('id')->on('inv_units_of_measure');
        });

        Schema::create('inv_stock_adjustment_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('adjustment_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('system_qty', 15, 3);
            $table->decimal('physical_qty', 15, 3);
            // GENERATED ALWAYS AS — never INSERT/UPDATE this column directly (BR-INV-018)
            $table->decimal('variance_qty', 15, 3)->storedAs('physical_qty - system_qty');
            $table->decimal('unit_cost', 15, 2);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('adjustment_id', 'idx_inv_sadji_adjustment_id');
            $table->index('item_id', 'idx_inv_sadji_item_id');
            $table->foreign('adjustment_id', 'fk_inv_sadji_adjustment_id')
                  ->references('id')->on('inv_stock_adjustments')->cascadeOnDelete();
            $table->foreign('item_id', 'fk_inv_sadji_item_id')
                  ->references('id')->on('inv_stock_items');
        });

        // =====================================================================
        // LAYER 7 — Depends on Layer 6
        // =====================================================================

        Schema::create('inv_purchase_order_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('po_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('ordered_qty', 15, 3);
            $table->decimal('received_qty', 15, 3)->default(0);
            $table->decimal('unit_price', 15, 2);
            $table->unsignedBigInteger('tax_rate_id')->nullable(); // acc_tax_rates.id
            $table->decimal('discount_percent', 5, 2)->default(0);
            $table->decimal('total_amount', 15, 2);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('po_id', 'idx_inv_poi_po_id');
            $table->index('item_id', 'idx_inv_poi_item_id');
            $table->index('tax_rate_id', 'idx_inv_poi_tax_rate_id');
            $table->foreign('po_id', 'fk_inv_poi_po_id')
                  ->references('id')->on('inv_purchase_orders')->cascadeOnDelete();
            $table->foreign('item_id', 'fk_inv_poi_item_id')
                  ->references('id')->on('inv_stock_items');
            // $table->foreign('tax_rate_id', 'fk_inv_poi_tax_rate_id')->references('id')->on('acc_tax_rates')->nullOnDelete();
        });

        Schema::create('inv_goods_receipt_notes', function (Blueprint $table) {
            $table->id();
            $table->string('grn_number', 50)->unique('uq_inv_grn_number');
            $table->unsignedBigInteger('po_id');
            $table->unsignedInteger('vendor_id'); // vnd_vendors.id INT UNSIGNED
            $table->date('receipt_date');
            $table->unsignedBigInteger('godown_id');
            $table->enum('status', ['draft', 'inspected', 'accepted', 'partial', 'rejected'])->default('draft');
            $table->enum('qc_status', ['pending', 'passed', 'failed', 'partial'])->default('pending');
            $table->text('qc_notes')->nullable();
            $table->unsignedBigInteger('received_by');
            $table->unsignedBigInteger('voucher_id')->nullable(); // acc_vouchers.id — D21, set on acceptance
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('po_id', 'idx_inv_grn_po_id');
            $table->index('vendor_id', 'idx_inv_grn_vendor_id');
            $table->index('godown_id', 'idx_inv_grn_godown_id');
            $table->index('status', 'idx_inv_grn_status');
            $table->index('received_by', 'idx_inv_grn_received_by');
            $table->index('voucher_id', 'idx_inv_grn_voucher_id');
            $table->index('is_active', 'idx_inv_grn_is_active');
            $table->foreign('po_id', 'fk_inv_grn_po_id')
                  ->references('id')->on('inv_purchase_orders');
            $table->foreign('godown_id', 'fk_inv_grn_godown_id')
                  ->references('id')->on('inv_godowns');
            // $table->foreign('vendor_id', 'fk_inv_grn_vendor_id')->references('id')->on('vnd_vendors');
            // $table->foreign('voucher_id', 'fk_inv_grn_voucher_id')->references('id')->on('acc_vouchers')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 8 — Depends on Layer 7
        // =====================================================================

        Schema::create('inv_grn_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('grn_id');
            $table->unsignedBigInteger('po_item_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('received_qty', 15, 3);
            $table->decimal('accepted_qty', 15, 3);
            $table->decimal('rejected_qty', 15, 3)->default(0);
            $table->decimal('unit_cost', 15, 2);
            $table->string('batch_number', 50)->nullable();
            $table->date('expiry_date')->nullable();
            $table->string('qc_remarks', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('grn_id', 'idx_inv_grni_grn_id');
            $table->index('po_item_id', 'idx_inv_grni_po_item_id');
            $table->index('item_id', 'idx_inv_grni_item_id');
            $table->foreign('grn_id', 'fk_inv_grni_grn_id')
                  ->references('id')->on('inv_goods_receipt_notes')->cascadeOnDelete();
            $table->foreign('po_item_id', 'fk_inv_grni_po_item_id')
                  ->references('id')->on('inv_purchase_order_items');
            $table->foreign('item_id', 'fk_inv_grni_item_id')
                  ->references('id')->on('inv_stock_items');
        });

        Schema::create('inv_stock_issues', function (Blueprint $table) {
            $table->id();
            $table->string('issue_number', 50)->unique('uq_inv_si_issue_number');
            $table->unsignedBigInteger('issue_request_id')->nullable();
            $table->unsignedBigInteger('godown_id');
            $table->unsignedBigInteger('issued_by');
            $table->unsignedInteger('issued_to_employee_id')->nullable(); // sch_employees.id INT UNSIGNED
            $table->unsignedInteger('department_id'); // sch_department.id INT UNSIGNED NOT NULL
            $table->date('issue_date');
            $table->unsignedBigInteger('voucher_id')->nullable(); // acc_vouchers.id — D21
            $table->unsignedBigInteger('acknowledged_by')->nullable();
            $table->timestamp('acknowledged_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('issue_request_id', 'idx_inv_si_issue_request_id');
            $table->index('godown_id', 'idx_inv_si_godown_id');
            $table->index('issued_by', 'idx_inv_si_issued_by');
            $table->index('issued_to_employee_id', 'idx_inv_si_issued_to_employee_id');
            $table->index('department_id', 'idx_inv_si_department_id');
            $table->index('voucher_id', 'idx_inv_si_voucher_id');
            $table->index('is_active', 'idx_inv_si_is_active');
            $table->foreign('issue_request_id', 'fk_inv_si_issue_request_id')
                  ->references('id')->on('inv_issue_requests')->nullOnDelete();
            $table->foreign('godown_id', 'fk_inv_si_godown_id')
                  ->references('id')->on('inv_godowns');
            // $table->foreign('issued_to_employee_id', 'fk_inv_si_issued_to_employee_id')->references('id')->on('sch_employees')->nullOnDelete();
            // $table->foreign('department_id', 'fk_inv_si_department_id')->references('id')->on('sch_department');
            // $table->foreign('voucher_id', 'fk_inv_si_voucher_id')->references('id')->on('acc_vouchers')->nullOnDelete();
        });

        Schema::create('inv_stock_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('stock_item_id');
            $table->unsignedBigInteger('godown_id');
            // MANDATORY — no orphan entries (BR-INV-001). FK constraint commented out until Accounting DDL applied.
            $table->unsignedBigInteger('voucher_id');
            $table->enum('entry_type', ['inward', 'outward', 'transfer_in', 'transfer_out', 'adjustment']);
            $table->decimal('quantity', 15, 3);
            $table->decimal('rate', 15, 2);
            $table->decimal('amount', 15, 2);
            $table->string('batch_number', 50)->nullable();
            $table->date('expiry_date')->nullable();
            $table->unsignedBigInteger('destination_godown_id')->nullable();
            $table->unsignedBigInteger('party_ledger_id')->nullable(); // acc_ledgers.id
            $table->string('narration', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes(); // Guard: only via StockLedgerService (BR-INV-014)
            $table->index(['stock_item_id', 'godown_id', 'created_at'], 'idx_inv_sent_item_godown_date');
            $table->index(['entry_type', 'created_at'], 'idx_inv_sent_entry_type_date');
            $table->index('voucher_id', 'idx_inv_sent_voucher_id');
            $table->index('destination_godown_id', 'idx_inv_sent_destination_godown');
            $table->index('party_ledger_id', 'idx_inv_sent_party_ledger_id');
            $table->foreign('stock_item_id', 'fk_inv_sent_stock_item_id')
                  ->references('id')->on('inv_stock_items');
            $table->foreign('godown_id', 'fk_inv_sent_godown_id')
                  ->references('id')->on('inv_godowns');
            $table->foreign('destination_godown_id', 'fk_inv_sent_destination_godown_id')
                  ->references('id')->on('inv_godowns')->nullOnDelete();
            // UNCOMMENT after Accounting DDL applied (acc_vouchers is NOT NULL — critical integrity):
            // $table->foreign('voucher_id', 'fk_inv_sent_voucher_id')->references('id')->on('acc_vouchers');
            // $table->foreign('party_ledger_id', 'fk_inv_sent_party_ledger_id')->references('id')->on('acc_ledgers')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 9 — Depends on Layer 8
        // =====================================================================

        Schema::create('inv_stock_issue_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('stock_issue_id');
            $table->unsignedBigInteger('item_id');
            $table->decimal('qty', 15, 3);
            $table->decimal('unit_cost', 15, 2);
            $table->string('batch_number', 50)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('stock_issue_id', 'idx_inv_sii_stock_issue_id');
            $table->index('item_id', 'idx_inv_sii_item_id');
            $table->foreign('stock_issue_id', 'fk_inv_sii_stock_issue_id')
                  ->references('id')->on('inv_stock_issues')->cascadeOnDelete();
            $table->foreign('item_id', 'fk_inv_sii_item_id')
                  ->references('id')->on('inv_stock_items');
        });

        Schema::create('inv_assets', function (Blueprint $table) {
            $table->id();
            $table->string('asset_tag', 50)->unique('uq_inv_asset_tag');
            $table->unsignedBigInteger('asset_category_id');
            $table->unsignedBigInteger('stock_item_id');
            $table->unsignedBigInteger('grn_item_id')->nullable();
            $table->date('purchase_date')->nullable();
            $table->decimal('purchase_cost', 15, 2)->nullable();
            $table->decimal('current_book_value', 15, 2)->nullable();
            $table->unsignedBigInteger('acc_fixed_asset_id')->nullable(); // acc_fixed_assets.id
            $table->unsignedBigInteger('godown_id')->nullable();
            $table->unsignedInteger('assigned_employee_id')->nullable(); // sch_employees.id INT UNSIGNED
            $table->enum('condition', ['good', 'fair', 'poor', 'under_repair', 'disposed'])->default('good');
            $table->date('warranty_expiry_date')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('asset_category_id', 'idx_inv_ast_asset_category_id');
            $table->index('stock_item_id', 'idx_inv_ast_stock_item_id');
            $table->index('grn_item_id', 'idx_inv_ast_grn_item_id');
            $table->index('acc_fixed_asset_id', 'idx_inv_ast_acc_fixed_asset_id');
            $table->index('godown_id', 'idx_inv_ast_godown_id');
            $table->index('assigned_employee_id', 'idx_inv_ast_assigned_employee_id');
            $table->index('condition', 'idx_inv_ast_condition');
            $table->index('is_active', 'idx_inv_ast_is_active');
            $table->foreign('asset_category_id', 'fk_inv_ast_asset_category_id')
                  ->references('id')->on('inv_asset_categories');
            $table->foreign('stock_item_id', 'fk_inv_ast_stock_item_id')
                  ->references('id')->on('inv_stock_items');
            $table->foreign('grn_item_id', 'fk_inv_ast_grn_item_id')
                  ->references('id')->on('inv_grn_items')->nullOnDelete();
            $table->foreign('godown_id', 'fk_inv_ast_godown_id')
                  ->references('id')->on('inv_godowns')->nullOnDelete();
            // $table->foreign('acc_fixed_asset_id', 'fk_inv_ast_acc_fixed_asset_id')->references('id')->on('acc_fixed_assets')->nullOnDelete();
            // $table->foreign('assigned_employee_id', 'fk_inv_ast_assigned_employee_id')->references('id')->on('sch_employees')->nullOnDelete();
        });

        // =====================================================================
        // LAYER 10 — Depends on Layer 9
        // =====================================================================

        Schema::create('inv_asset_movements', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('asset_id');
            $table->date('movement_date');
            $table->unsignedBigInteger('from_godown_id')->nullable();
            $table->unsignedBigInteger('to_godown_id')->nullable();
            $table->unsignedInteger('from_employee_id')->nullable(); // sch_employees.id INT UNSIGNED
            $table->unsignedInteger('to_employee_id')->nullable();   // sch_employees.id INT UNSIGNED
            $table->string('reason', 500)->nullable();
            $table->unsignedBigInteger('moved_by');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('asset_id', 'idx_inv_amov_asset_id');
            $table->index('from_godown_id', 'idx_inv_amov_from_godown_id');
            $table->index('to_godown_id', 'idx_inv_amov_to_godown_id');
            $table->index('from_employee_id', 'idx_inv_amov_from_employee_id');
            $table->index('to_employee_id', 'idx_inv_amov_to_employee_id');
            $table->index('moved_by', 'idx_inv_amov_moved_by');
            $table->index('movement_date', 'idx_inv_amov_movement_date');
            $table->foreign('asset_id', 'fk_inv_amov_asset_id')
                  ->references('id')->on('inv_assets');
            $table->foreign('from_godown_id', 'fk_inv_amov_from_godown_id')
                  ->references('id')->on('inv_godowns')->nullOnDelete();
            $table->foreign('to_godown_id', 'fk_inv_amov_to_godown_id')
                  ->references('id')->on('inv_godowns')->nullOnDelete();
            // $table->foreign('from_employee_id', 'fk_inv_amov_from_employee_id')->references('id')->on('sch_employees')->nullOnDelete();
            // $table->foreign('to_employee_id', 'fk_inv_amov_to_employee_id')->references('id')->on('sch_employees')->nullOnDelete();
        });

        Schema::create('inv_asset_maintenance', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('asset_id');
            $table->date('maintenance_date');
            $table->enum('maintenance_type', ['preventive', 'corrective', 'amc', 'calibration']);
            $table->unsignedInteger('vendor_id')->nullable(); // vnd_vendors.id INT UNSIGNED
            $table->decimal('cost', 15, 2)->nullable();
            $table->text('notes')->nullable();
            $table->date('next_due_date')->nullable();
            $table->enum('status', ['scheduled', 'completed', 'overdue'])->default('scheduled');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by');
            $table->timestamps();
            $table->softDeletes();
            $table->index('asset_id', 'idx_inv_amnt_asset_id');
            $table->index('vendor_id', 'idx_inv_amnt_vendor_id');
            $table->index('status', 'idx_inv_amnt_status');
            $table->index('next_due_date', 'idx_inv_amnt_next_due_date');
            $table->index('maintenance_date', 'idx_inv_amnt_maint_date');
            $table->foreign('asset_id', 'fk_inv_amnt_asset_id')
                  ->references('id')->on('inv_assets');
            // $table->foreign('vendor_id', 'fk_inv_amnt_vendor_id')->references('id')->on('vnd_vendors')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::disableForeignKeyConstraints();

        // Drop in reverse dependency order: Layer 10 → Layer 1
        Schema::dropIfExists('inv_asset_maintenance');
        Schema::dropIfExists('inv_asset_movements');

        Schema::dropIfExists('inv_assets');
        Schema::dropIfExists('inv_stock_issue_items');

        Schema::dropIfExists('inv_stock_entries');
        Schema::dropIfExists('inv_stock_issues');
        Schema::dropIfExists('inv_grn_items');

        Schema::dropIfExists('inv_goods_receipt_notes');
        Schema::dropIfExists('inv_purchase_order_items');

        Schema::dropIfExists('inv_stock_adjustment_items');
        Schema::dropIfExists('inv_issue_request_items');
        Schema::dropIfExists('inv_purchase_orders');
        Schema::dropIfExists('inv_quotation_items');

        Schema::dropIfExists('inv_issue_requests');
        Schema::dropIfExists('inv_quotations');
        Schema::dropIfExists('inv_purchase_requisition_items');
        Schema::dropIfExists('inv_rate_contract_items_jnt');

        Schema::dropIfExists('inv_stock_adjustments');
        Schema::dropIfExists('inv_purchase_requisitions');
        Schema::dropIfExists('inv_rate_contracts');
        Schema::dropIfExists('inv_item_vendor_jnt');
        Schema::dropIfExists('inv_stock_balances');

        Schema::dropIfExists('inv_godowns');
        Schema::dropIfExists('inv_stock_items');

        Schema::dropIfExists('inv_uom_conversions');
        Schema::dropIfExists('inv_stock_groups');

        Schema::dropIfExists('inv_asset_categories');
        Schema::dropIfExists('inv_units_of_measure');

        Schema::enableForeignKeyConstraints();
    }
};
