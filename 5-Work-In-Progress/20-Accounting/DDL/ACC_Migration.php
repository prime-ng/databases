<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Accounting Module Migration — 21 tables + sch_employees enhancement
 * Tally-Prime inspired voucher-based double-entry system
 * Replaces old 31-table journal-based acc_* schema (unused draft)
 *
 * Date: 2026-03-21
 * Module: Accounting (ACC)
 * Prefix: acc_
 */
return new class extends Migration
{
    public function up(): void
    {
        // ============================================================
        // DOMAIN 1: CORE ACCOUNTING (12 tables)
        // ============================================================

        // 1. Financial Years
        Schema::create('acc_financial_years', function (Blueprint $table) {
            $table->id();
            $table->string('name', 50)->comment('e.g., 2025-26');
            $table->date('start_date')->comment('Financial year start (April 1)');
            $table->date('end_date')->comment('Financial year end (March 31)');
            $table->boolean('is_locked')->default(false)->comment('Prevents edits when locked');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('is_active', 'idx_acc_fy_active');
            $table->index(['start_date', 'end_date'], 'idx_acc_fy_dates');
        });

        // 2. Account Groups
        Schema::create('acc_account_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100)->comment('Group name');
            $table->string('code', 20)->comment('Unique group code');
            $table->string('alias', 100)->nullable()->comment('Alternative display name');
            $table->unsignedBigInteger('parent_id')->nullable()->comment('Self-referencing hierarchy');
            $table->enum('nature', ['asset', 'liability', 'income', 'expense'])->comment('Account nature');
            $table->boolean('affects_gross_profit')->default(false)->comment('Direct vs Indirect');
            $table->boolean('is_system')->default(false)->comment('Seeded, cannot delete');
            $table->boolean('is_subledger')->default(false)->comment('Behaves as sub-ledger');
            $table->integer('sequence')->default(0)->comment('Display order');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'deleted_at'], 'uq_acc_ag_code');
            $table->index('parent_id', 'idx_acc_ag_parent');
            $table->index('nature', 'idx_acc_ag_nature');
            $table->foreign('parent_id', 'fk_acc_ag_parent')->references('id')->on('acc_account_groups')->nullOnDelete();
        });

        // 7. Cost Centers (created before vouchers for FK)
        Schema::create('acc_cost_centers', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100)->comment('e.g., Primary Wing, Transport');
            $table->string('code', 20)->nullable()->comment('Cost center code');
            $table->unsignedBigInteger('parent_id')->nullable()->comment('Self-referencing hierarchy');
            $table->string('category', 50)->nullable()->comment('Department, Activity, Project');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('parent_id', 'idx_acc_cc_parent');
            $table->foreign('parent_id', 'fk_acc_cc_parent')->references('id')->on('acc_cost_centers')->nullOnDelete();
        });

        // 3. Ledgers
        Schema::create('acc_ledgers', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150)->comment('Ledger name');
            $table->string('code', 20)->nullable()->comment('Unique ledger code');
            $table->string('alias', 150)->nullable()->comment('Alternative name');
            $table->unsignedBigInteger('account_group_id')->comment('FK → acc_account_groups');
            $table->decimal('opening_balance', 15, 2)->default(0.00);
            $table->enum('opening_balance_type', ['Dr', 'Cr'])->nullable();
            $table->boolean('is_bank_account')->default(false);
            $table->string('bank_name', 100)->nullable();
            $table->string('bank_account_number', 50)->nullable();
            $table->string('ifsc_code', 20)->nullable();
            $table->boolean('is_cash_account')->default(false);
            $table->boolean('allow_reconciliation')->default(false);
            $table->boolean('is_system')->default(false);
            $table->unsignedBigInteger('student_id')->nullable()->comment('FK → std_students');
            $table->unsignedBigInteger('employee_id')->nullable()->comment('FK → sch_employees');
            $table->unsignedBigInteger('vendor_id')->nullable()->comment('FK → vnd_vendors');
            $table->string('gst_registration_type', 30)->nullable();
            $table->string('gstin', 20)->nullable();
            $table->string('pan', 15)->nullable();
            $table->text('address')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('account_group_id', 'idx_acc_ledger_group');
            $table->index('student_id', 'idx_acc_ledger_student');
            $table->index('employee_id', 'idx_acc_ledger_employee');
            $table->index('vendor_id', 'idx_acc_ledger_vendor');
            $table->index('is_bank_account', 'idx_acc_ledger_bank');
            $table->foreign('account_group_id', 'fk_acc_ledger_group')->references('id')->on('acc_account_groups')->restrictOnDelete();
        });

        // 4. Voucher Types
        Schema::create('acc_voucher_types', function (Blueprint $table) {
            $table->id();
            $table->string('name', 80)->comment('e.g., Payment Voucher');
            $table->string('code', 20)->comment('PAYMENT, RECEIPT, etc.');
            $table->enum('category', ['accounting', 'inventory', 'payroll', 'order']);
            $table->string('prefix', 20)->nullable()->comment('Voucher number prefix');
            $table->boolean('auto_numbering')->default(true);
            $table->integer('last_number')->default(0);
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'deleted_at'], 'uq_acc_vt_code');
            $table->index('category', 'idx_acc_vt_category');
        });

        // 5. Vouchers (THE HEART)
        Schema::create('acc_vouchers', function (Blueprint $table) {
            $table->id();
            $table->string('voucher_number', 50)->comment('Auto-generated, unique per FY');
            $table->unsignedBigInteger('voucher_type_id');
            $table->unsignedBigInteger('financial_year_id');
            $table->date('date');
            $table->string('reference_number', 100)->nullable();
            $table->date('reference_date')->nullable();
            $table->text('narration')->nullable();
            $table->decimal('total_amount', 15, 2);
            $table->boolean('is_post_dated')->default(false);
            $table->boolean('is_optional')->default(false);
            $table->boolean('is_cancelled')->default(false);
            $table->text('cancelled_reason')->nullable();
            $table->unsignedBigInteger('cost_center_id')->nullable();
            $table->string('source_module', 50)->nullable()->comment('StudentFee, Payroll, Inventory, Transport, Manual');
            $table->string('source_type', 100)->nullable()->comment('Polymorphic model');
            $table->unsignedBigInteger('source_id')->nullable();
            $table->enum('status', ['draft', 'posted', 'approved', 'cancelled'])->default('draft');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['voucher_number', 'financial_year_id', 'deleted_at'], 'uq_acc_voucher_number_fy');
            $table->index('voucher_type_id', 'idx_acc_voucher_type');
            $table->index('financial_year_id', 'idx_acc_voucher_fy');
            $table->index('date', 'idx_acc_voucher_date');
            $table->index('status', 'idx_acc_voucher_status');
            $table->index(['source_module', 'source_type', 'source_id'], 'idx_acc_voucher_source');
            $table->index('cost_center_id', 'idx_acc_voucher_cost');
            $table->index(['date', 'financial_year_id', 'status'], 'idx_acc_voucher_composite');
            $table->foreign('voucher_type_id', 'fk_acc_voucher_type')->references('id')->on('acc_voucher_types')->restrictOnDelete();
            $table->foreign('financial_year_id', 'fk_acc_voucher_fy')->references('id')->on('acc_financial_years')->restrictOnDelete();
            $table->foreign('cost_center_id', 'fk_acc_voucher_cost')->references('id')->on('acc_cost_centers')->nullOnDelete();
        });

        // 6. Voucher Items
        Schema::create('acc_voucher_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('voucher_id');
            $table->unsignedBigInteger('ledger_id');
            $table->enum('type', ['debit', 'credit']);
            $table->decimal('amount', 15, 2);
            $table->string('narration', 500)->nullable();
            $table->unsignedBigInteger('cost_center_id')->nullable();
            $table->string('bill_reference', 100)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('voucher_id', 'idx_acc_vi_voucher');
            $table->index('ledger_id', 'idx_acc_vi_ledger');
            $table->index('type', 'idx_acc_vi_type');
            $table->index(['ledger_id', 'created_at'], 'idx_acc_vi_ledger_date');
            $table->foreign('voucher_id', 'fk_acc_vi_voucher')->references('id')->on('acc_vouchers')->cascadeOnDelete();
            $table->foreign('ledger_id', 'fk_acc_vi_ledger')->references('id')->on('acc_ledgers')->restrictOnDelete();
            $table->foreign('cost_center_id', 'fk_acc_vi_cost')->references('id')->on('acc_cost_centers')->nullOnDelete();
        });

        // 8. Budgets
        Schema::create('acc_budgets', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('financial_year_id');
            $table->unsignedBigInteger('cost_center_id');
            $table->unsignedBigInteger('ledger_id');
            $table->decimal('budgeted_amount', 15, 2)->default(0.00);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['financial_year_id', 'cost_center_id', 'ledger_id'], 'uq_acc_budget');
            $table->foreign('financial_year_id', 'fk_acc_budget_fy')->references('id')->on('acc_financial_years')->restrictOnDelete();
            $table->foreign('cost_center_id', 'fk_acc_budget_cc')->references('id')->on('acc_cost_centers')->restrictOnDelete();
            $table->foreign('ledger_id', 'fk_acc_budget_ledger')->references('id')->on('acc_ledgers')->restrictOnDelete();
        });

        // 9. Tax Rates
        Schema::create('acc_tax_rates', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->decimal('rate', 5, 2);
            $table->enum('type', ['CGST', 'SGST', 'IGST', 'Cess']);
            $table->string('hsn_sac_code', 20)->nullable();
            $table->boolean('is_interstate')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('type', 'idx_acc_tax_type');
        });

        // 10. Ledger Mappings
        Schema::create('acc_ledger_mappings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('ledger_id');
            $table->enum('source_module', ['Fees', 'Library', 'Transport', 'HR', 'Vendor', 'Inventory', 'Payroll']);
            $table->string('source_type', 100)->nullable();
            $table->unsignedBigInteger('source_id');
            $table->string('description', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['ledger_id', 'source_module', 'source_type', 'source_id'], 'uq_acc_lm_combo');
            $table->index(['source_module', 'source_type', 'source_id'], 'idx_acc_lm_source');
            $table->foreign('ledger_id', 'fk_acc_lm_ledger')->references('id')->on('acc_ledgers')->restrictOnDelete();
        });

        // 11. Recurring Templates
        Schema::create('acc_recurring_templates', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->unsignedBigInteger('voucher_type_id');
            $table->enum('frequency', ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly']);
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->tinyInteger('day_of_month')->nullable();
            $table->text('narration')->nullable();
            $table->decimal('total_amount', 15, 2);
            $table->date('last_posted_date')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('voucher_type_id', 'fk_acc_rt_type')->references('id')->on('acc_voucher_types')->restrictOnDelete();
        });

        // 12. Recurring Template Lines
        Schema::create('acc_recurring_template_lines', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('recurring_template_id');
            $table->unsignedBigInteger('ledger_id');
            $table->enum('type', ['debit', 'credit']);
            $table->decimal('amount', 15, 2);
            $table->string('narration', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('recurring_template_id', 'fk_acc_rtl_template')->references('id')->on('acc_recurring_templates')->cascadeOnDelete();
            $table->foreign('ledger_id', 'fk_acc_rtl_ledger')->references('id')->on('acc_ledgers')->restrictOnDelete();
        });

        // ============================================================
        // DOMAIN 2: BANKING (2 tables)
        // ============================================================

        Schema::create('acc_bank_reconciliations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('ledger_id');
            $table->date('statement_date');
            $table->decimal('closing_balance', 15, 2);
            $table->string('statement_path', 255)->nullable();
            $table->enum('status', ['In Progress', 'Completed'])->default('In Progress');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('ledger_id', 'idx_acc_br_ledger');
            $table->foreign('ledger_id', 'fk_acc_br_ledger')->references('id')->on('acc_ledgers')->restrictOnDelete();
        });

        Schema::create('acc_bank_statement_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('reconciliation_id');
            $table->date('transaction_date');
            $table->string('description', 500)->nullable();
            $table->string('reference', 255)->nullable();
            $table->decimal('debit', 15, 2)->default(0.00);
            $table->decimal('credit', 15, 2)->default(0.00);
            $table->decimal('balance', 15, 2)->nullable();
            $table->boolean('is_matched')->default(false);
            $table->unsignedBigInteger('matched_voucher_item_id')->nullable();
            $table->timestamp('matched_at')->nullable();
            $table->unsignedBigInteger('matched_by')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('reconciliation_id', 'idx_acc_bse_recon');
            $table->index('is_matched', 'idx_acc_bse_matched');
            $table->index(['reconciliation_id', 'is_matched'], 'idx_acc_bse_recon_matched');
            $table->foreign('reconciliation_id', 'fk_acc_bse_recon')->references('id')->on('acc_bank_reconciliations')->cascadeOnDelete();
            $table->foreign('matched_voucher_item_id', 'fk_acc_bse_vi')->references('id')->on('acc_voucher_items')->nullOnDelete();
        });

        // ============================================================
        // DOMAIN 3: FIXED ASSETS (3 tables)
        // ============================================================

        Schema::create('acc_asset_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('code', 20);
            $table->enum('depreciation_method', ['SLM', 'WDV']);
            $table->decimal('depreciation_rate', 5, 2);
            $table->integer('useful_life_years')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['code', 'deleted_at'], 'uq_acc_assetcat_code');
        });

        Schema::create('acc_fixed_assets', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->string('asset_code', 50);
            $table->unsignedBigInteger('asset_category_id');
            $table->date('purchase_date');
            $table->decimal('purchase_cost', 15, 2);
            $table->decimal('salvage_value', 15, 2)->default(0.00);
            $table->decimal('current_value', 15, 2);
            $table->decimal('accumulated_depreciation', 15, 2)->default(0.00);
            $table->string('location', 100)->nullable();
            $table->unsignedBigInteger('vendor_id')->nullable();
            $table->unsignedBigInteger('voucher_id')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['asset_code', 'deleted_at'], 'uq_acc_fa_code');
            $table->index('asset_category_id', 'idx_acc_fa_category');
            $table->foreign('asset_category_id', 'fk_acc_fa_category')->references('id')->on('acc_asset_categories')->restrictOnDelete();
            $table->foreign('voucher_id', 'fk_acc_fa_voucher')->references('id')->on('acc_vouchers')->nullOnDelete();
        });

        Schema::create('acc_depreciation_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('fixed_asset_id');
            $table->unsignedBigInteger('financial_year_id');
            $table->date('depreciation_date');
            $table->decimal('depreciation_amount', 15, 2);
            $table->unsignedBigInteger('voucher_id')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('fixed_asset_id', 'idx_acc_de_asset');
            $table->index('financial_year_id', 'idx_acc_de_fy');
            $table->foreign('fixed_asset_id', 'fk_acc_de_asset')->references('id')->on('acc_fixed_assets')->cascadeOnDelete();
            $table->foreign('financial_year_id', 'fk_acc_de_fy')->references('id')->on('acc_financial_years')->restrictOnDelete();
            $table->foreign('voucher_id', 'fk_acc_de_voucher')->references('id')->on('acc_vouchers')->nullOnDelete();
        });

        // ============================================================
        // DOMAIN 4: EXPENSE CLAIMS (2 tables)
        // ============================================================

        Schema::create('acc_expense_claims', function (Blueprint $table) {
            $table->id();
            $table->string('claim_number', 50);
            $table->unsignedBigInteger('employee_id')->comment('FK → sch_employees');
            $table->date('claim_date');
            $table->decimal('total_amount', 15, 2);
            $table->enum('status', ['Draft', 'Submitted', 'Approved', 'Rejected', 'Paid'])->default('Draft');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->unsignedBigInteger('voucher_id')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['claim_number', 'deleted_at'], 'uq_acc_ec_number');
            $table->index('employee_id', 'idx_acc_ec_employee');
            $table->index('status', 'idx_acc_ec_status');
            $table->foreign('voucher_id', 'fk_acc_ec_voucher')->references('id')->on('acc_vouchers')->nullOnDelete();
        });

        Schema::create('acc_expense_claim_lines', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('expense_claim_id');
            $table->date('expense_date');
            $table->unsignedBigInteger('ledger_id');
            $table->string('description', 255);
            $table->decimal('amount', 15, 2);
            $table->decimal('tax_amount', 15, 2)->default(0.00);
            $table->string('receipt_path', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('expense_claim_id', 'idx_acc_ecl_claim');
            $table->foreign('expense_claim_id', 'fk_acc_ecl_claim')->references('id')->on('acc_expense_claims')->cascadeOnDelete();
            $table->foreign('ledger_id', 'fk_acc_ecl_ledger')->references('id')->on('acc_ledgers')->restrictOnDelete();
        });

        // ============================================================
        // DOMAIN 5: TALLY INTEGRATION (2 tables)
        // ============================================================

        Schema::create('acc_tally_export_logs', function (Blueprint $table) {
            $table->id();
            $table->enum('export_type', ['Ledgers', 'Vouchers', 'Inventory']);
            $table->dateTime('export_date');
            $table->string('file_name', 255);
            $table->unsignedBigInteger('exported_by');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->integer('record_count')->nullable();
            $table->enum('status', ['Success', 'Failed', 'Partial']);
            $table->text('error_log')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('export_type', 'idx_acc_tel_type');
            $table->index('export_date', 'idx_acc_tel_date');
        });

        Schema::create('acc_tally_ledger_mappings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('ledger_id');
            $table->string('tally_ledger_name', 200);
            $table->string('tally_group_name', 200)->nullable();
            $table->string('tally_alias', 200)->nullable();
            $table->enum('mapping_type', ['auto', 'manual'])->default('auto');
            $table->enum('sync_direction', ['export_only', 'import_only', 'bidirectional'])->default('export_only');
            $table->timestamp('last_synced_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['ledger_id', 'deleted_at'], 'uq_acc_tlm_ledger');
            $table->foreign('ledger_id', 'fk_acc_tlm_ledger')->references('id')->on('acc_ledgers')->cascadeOnDelete();
        });

        // ============================================================
        // sch_employees ENHANCEMENT (14 new columns)
        // ============================================================

        Schema::table('sch_employees', function (Blueprint $table) {
            if (!Schema::hasColumn('sch_employees', 'is_active')) {
                $table->boolean('is_active')->default(true)->after('notes');
            }
            if (!Schema::hasColumn('sch_employees', 'created_by')) {
                $table->unsignedBigInteger('created_by')->nullable()->after('is_active');
            }
            if (!Schema::hasColumn('sch_employees', 'staff_category_id')) {
                $table->unsignedInteger('staff_category_id')->nullable()->after('created_by')->comment('FK → sch_categories');
            }
            if (!Schema::hasColumn('sch_employees', 'ledger_id')) {
                $table->unsignedBigInteger('ledger_id')->nullable()->after('staff_category_id')->comment('FK → acc_ledgers');
            }
            if (!Schema::hasColumn('sch_employees', 'salary_structure_id')) {
                $table->unsignedBigInteger('salary_structure_id')->nullable()->after('ledger_id')->comment('FK → prl_salary_structures');
            }
            if (!Schema::hasColumn('sch_employees', 'bank_name')) {
                $table->string('bank_name', 100)->nullable()->after('salary_structure_id');
            }
            if (!Schema::hasColumn('sch_employees', 'bank_account_number')) {
                $table->string('bank_account_number', 50)->nullable()->after('bank_name');
            }
            if (!Schema::hasColumn('sch_employees', 'bank_ifsc')) {
                $table->string('bank_ifsc', 20)->nullable()->after('bank_account_number');
            }
            if (!Schema::hasColumn('sch_employees', 'pf_number')) {
                $table->string('pf_number', 30)->nullable()->after('bank_ifsc');
            }
            if (!Schema::hasColumn('sch_employees', 'esi_number')) {
                $table->string('esi_number', 30)->nullable()->after('pf_number');
            }
            if (!Schema::hasColumn('sch_employees', 'uan')) {
                $table->string('uan', 20)->nullable()->after('esi_number');
            }
            if (!Schema::hasColumn('sch_employees', 'pan')) {
                $table->string('pan', 15)->nullable()->after('uan');
            }
            if (!Schema::hasColumn('sch_employees', 'ctc_monthly')) {
                $table->decimal('ctc_monthly', 15, 2)->nullable()->after('pan');
            }
            if (!Schema::hasColumn('sch_employees', 'date_of_leaving')) {
                $table->date('date_of_leaving')->nullable()->after('ctc_monthly');
            }
        });
    }

    public function down(): void
    {
        // Drop in reverse order of creation
        Schema::dropIfExists('acc_tally_ledger_mappings');
        Schema::dropIfExists('acc_tally_export_logs');
        Schema::dropIfExists('acc_expense_claim_lines');
        Schema::dropIfExists('acc_expense_claims');
        Schema::dropIfExists('acc_depreciation_entries');
        Schema::dropIfExists('acc_fixed_assets');
        Schema::dropIfExists('acc_asset_categories');
        Schema::dropIfExists('acc_bank_statement_entries');
        Schema::dropIfExists('acc_bank_reconciliations');
        Schema::dropIfExists('acc_recurring_template_lines');
        Schema::dropIfExists('acc_recurring_templates');
        Schema::dropIfExists('acc_ledger_mappings');
        Schema::dropIfExists('acc_tax_rates');
        Schema::dropIfExists('acc_budgets');
        Schema::dropIfExists('acc_voucher_items');
        Schema::dropIfExists('acc_vouchers');
        Schema::dropIfExists('acc_voucher_types');
        Schema::dropIfExists('acc_ledgers');
        Schema::dropIfExists('acc_cost_centers');
        Schema::dropIfExists('acc_account_groups');
        Schema::dropIfExists('acc_financial_years');

        // Note: sch_employees columns are NOT dropped in down() to avoid data loss
    }
};
