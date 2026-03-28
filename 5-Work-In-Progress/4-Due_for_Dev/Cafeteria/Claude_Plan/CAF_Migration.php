<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * CAF — Cafeteria Module Migration
 * Creates all 21 caf_* tables for the Cafeteria module.
 *
 * Dependency order: Layer 1 (8) → Layer 2 (9) → Layer 3 (3) → Layer 4 (1)
 * Down order: Layer 4 → Layer 3 → Layer 2 → Layer 1
 *
 * FK type notes (verified against tenant_db_v2.sql):
 *   sys_users.id          = INT UNSIGNED  → unsignedInteger() for all created_by/published_by/staff_id etc.
 *   sch_academic_term.id  = SMALLINT UNSIGNED → unsignedSmallInteger()  (singular table name)
 *   std_students.id       = INT UNSIGNED  → unsignedInteger()
 *   sys_media.id          = INT UNSIGNED  → unsignedInteger()
 *   All caf_* PKs         = INT UNSIGNED  → unsignedInteger()->autoIncrement()
 *   All caf_* intra FKs   = INT UNSIGNED  → unsignedInteger()
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No caf_* dependencies
        // =====================================================================

        // 1. caf_menu_categories
        Schema::create('caf_menu_categories', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->string('name', 100)->comment('Category name e.g. Breakfast, Lunch');
            $table->string('code', 20)->nullable()->unique()->comment('Short code e.g. BRK, LNC');
            $table->enum('meal_time', ['Breakfast', 'Lunch', 'Snacks', 'Dinner', 'Tuck_Shop'])
                  ->comment('Serving type');
            $table->time('meal_start_time')->nullable()->comment('Scheduled serving start time');
            $table->text('description')->nullable();
            $table->unsignedTinyInteger('display_order')->default(0)->comment('Sort order on student portal');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('created_by');
        });

        // 2. caf_suppliers
        Schema::create('caf_suppliers', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->string('name', 150)->comment('Supplier company name');
            $table->string('contact_person', 100)->nullable();
            $table->string('phone', 20)->nullable();
            $table->string('email', 100)->nullable();
            $table->text('address')->nullable();
            $table->string('fssai_license_no', 50)->nullable()->comment('Supplier FSSAI license number');
            $table->date('fssai_expiry_date')->nullable()->comment('Alert 30+7 days before expiry (BR-CAF-014)');
            $table->json('supply_categories_json')->nullable()->comment('Array e.g. ["Vegetables","Grains"]');
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('fssai_expiry_date');
            $table->index('is_active');
            $table->index('created_by');
        });

        // 3. caf_fssai_records (no softDeletes — compliance record)
        Schema::create('caf_fssai_records', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->enum('record_type', ['License', 'Audit'])->comment('Discriminator');
            $table->string('license_number', 50)->nullable()->comment('For License records');
            $table->enum('license_type', ['Basic', 'State', 'Central'])->nullable()
                  ->comment('For License records');
            $table->date('issue_date')->nullable();
            $table->date('expiry_date')->nullable()->comment('Alert 60+30 days before expiry (BR-CAF-014)');
            $table->string('licensed_entity_name', 150)->nullable();
            $table->unsignedInteger('fssai_document_media_id')->nullable()->comment('sys_media.id');
            $table->date('audit_date')->nullable()->comment('For Audit records');
            $table->string('auditor_name', 100)->nullable();
            $table->unsignedTinyInteger('audit_score')->nullable()->comment('Hygiene score 1-10');
            $table->text('audit_remarks')->nullable();
            $table->text('corrective_actions')->nullable();
            $table->date('next_audit_date')->nullable();
            $table->tinyInteger('is_active')->default(1)->comment('Soft enable/disable');
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            // No softDeletes — compliance record; never soft-deleted

            $table->index('record_type');
            $table->index('expiry_date');
            $table->index('fssai_document_media_id');
            $table->index('created_by');
        });

        // 4. caf_daily_menus
        Schema::create('caf_daily_menus', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->date('menu_date')->unique()->comment('One menu per calendar date (BR-CAF-018)');
            $table->date('week_start_date')->comment('ISO Monday of the menu week');
            $table->unsignedSmallInteger('academic_term_id')->nullable()
                  ->comment('sch_academic_term.id (SMALLINT UNSIGNED — verified)');
            $table->enum('status', ['Draft', 'Published', 'Archived'])->default('Draft');
            $table->timestamp('published_at')->nullable();
            $table->unsignedInteger('published_by')->nullable()->comment('sys_users.id');
            $table->text('notes')->nullable()->comment('Kitchen notes');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('week_start_date');
            $table->index('academic_term_id');
            $table->index('status');
            $table->index('published_by');
            $table->index('created_by');
        });

        // 5. caf_subscription_plans
        Schema::create('caf_subscription_plans', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->string('name', 150)->comment('Plan name e.g. Full Day Plan');
            $table->text('description')->nullable();
            $table->json('included_category_ids_json')->comment('Array of caf_menu_categories.id');
            $table->enum('billing_period', ['Monthly', 'Termly', 'Annual'])->default('Monthly');
            $table->decimal('price', 10, 2)->comment('Plan price in INR');
            $table->unsignedSmallInteger('academic_term_id')->nullable()
                  ->comment('sch_academic_term.id (SMALLINT UNSIGNED — verified)');
            $table->tinyInteger('is_hostel_plan')->default(0)->comment('Links to HST module (BR-CAF-015)');
            $table->tinyInteger('is_staff_plan')->default(0)->comment('For staff meal PAY signal');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('academic_term_id');
            $table->index('is_hostel_plan');
            $table->index('is_staff_plan');
            $table->index('created_by');
        });

        // 6. caf_meal_cards
        Schema::create('caf_meal_cards', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('student_id')->unique()
                  ->comment('std_students.id — one active card per student (BR-CAF-004)');
            $table->string('card_number', 20)->unique()->comment('e.g. CAF-CARD-XXXXXXXX');
            $table->decimal('current_balance', 10, 2)->default(0.00)
                  ->comment('Updated atomically by MealCardService via SELECT...FOR UPDATE');
            $table->decimal('total_credited', 10, 2)->default(0.00)->comment('Lifetime credit total');
            $table->decimal('total_debited', 10, 2)->default(0.00)->comment('Lifetime debit total');
            $table->date('valid_from_date');
            $table->date('valid_to_date')->nullable()->comment('Typically end of academic year');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('is_active');
            $table->index('created_by');
        });

        // 7. caf_pos_sessions (no softDeletes; no created_by — opened_by serves)
        Schema::create('caf_pos_sessions', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->date('session_date');
            $table->unsignedInteger('opened_by')->comment('sys_users.id — staff who opened session');
            $table->timestamp('opened_at')->comment('Session open timestamp');
            $table->timestamp('closed_at')->nullable()->comment('NULL = session still active (BR-CAF-013)');
            $table->decimal('total_cash_collected', 10, 2)->default(0.00);
            $table->decimal('total_card_debited', 10, 2)->default(0.00);
            $table->unsignedInteger('total_transactions')->default(0);
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->timestamps();
            // No softDeletes; no created_by

            $table->index('session_date');
            $table->index('opened_by');
            $table->index('closed_at');
        });

        // 8. caf_dietary_profiles
        Schema::create('caf_dietary_profiles', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('student_id')->unique()
                  ->comment('std_students.id — one profile per student');
            $table->enum('food_preference', ['Veg', 'Non_Veg', 'Egg', 'Jain'])->default('Veg');
            $table->tinyInteger('is_no_onion_garlic')->default(0);
            $table->tinyInteger('is_gluten_free')->default(0);
            $table->tinyInteger('is_nut_allergy')->default(0)->comment('Flagged on POS scan (BR-CAF-002)');
            $table->tinyInteger('is_dairy_free')->default(0);
            $table->text('custom_restrictions')->nullable();
            $table->text('medical_dietary_note')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('created_by');
        });

        // =====================================================================
        // LAYER 2 — Depends on Layer 1
        // =====================================================================

        // 9. caf_menu_items
        Schema::create('caf_menu_items', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('category_id')->comment('caf_menu_categories.id');
            $table->string('name', 150)->comment('Dish name');
            $table->text('description')->nullable();
            $table->decimal('price', 8, 2)->comment('Per-serving price in INR');
            $table->enum('food_type', ['Veg', 'Non_Veg', 'Egg', 'Jain'])->default('Veg');
            $table->unsignedSmallInteger('calories')->nullable()->comment('kcal per serving');
            $table->decimal('protein_grams', 5, 2)->nullable();
            $table->decimal('carbs_grams', 5, 2)->nullable();
            $table->decimal('fat_grams', 5, 2)->nullable();
            $table->text('allergen_notes')->nullable();
            $table->unsignedInteger('photo_media_id')->nullable()->comment('sys_media.id');
            $table->tinyInteger('is_available')->default(1)->comment('Real-time availability toggle');
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('category_id');
            $table->index('photo_media_id');
            $table->index('food_type');
            $table->index('is_available');
            $table->index('created_by');
            $table->foreign('category_id', 'fk_caf_mi_category_id')
                  ->references('id')->on('caf_menu_categories')->onDelete('restrict');
        });

        // 10. caf_stock_items
        Schema::create('caf_stock_items', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('supplier_id')->nullable()->comment('caf_suppliers.id');
            $table->string('name', 150)->comment('Raw material name');
            $table->enum('category', [
                'Grains', 'Pulses', 'Vegetables', 'Fruits', 'Dairy',
                'Spices', 'Beverages', 'Condiments', 'Cleaning', 'Other',
            ]);
            $table->string('unit', 20)->comment('kg, litre, piece, dozen');
            $table->decimal('current_quantity', 10, 3)->default(0.000);
            $table->decimal('reorder_level', 10, 3)->comment('Alert threshold (BR-CAF-007)');
            $table->decimal('reorder_quantity', 10, 3)->nullable()->comment('Suggested qty for INV bridge');
            $table->decimal('cost_per_unit', 8, 2)->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('supplier_id');
            $table->index('category');
            $table->index('is_active');
            $table->index('created_by');
            $table->foreign('supplier_id', 'fk_caf_si_supplier_id')
                  ->references('id')->on('caf_suppliers')->onDelete('set null');
        });

        // 11. caf_event_meals
        Schema::create('caf_event_meals', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->string('name', 150)->comment('e.g. Diwali Special Lunch');
            $table->date('event_date');
            $table->unsignedInteger('meal_category_id')->comment('caf_menu_categories.id');
            $table->json('target_class_ids_json')->nullable()->comment('NULL = all students (BR-CAF-016)');
            $table->enum('status', ['Draft', 'Published', 'Archived'])->default('Draft');
            $table->timestamp('published_at')->nullable();
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('event_date');
            $table->index('meal_category_id');
            $table->index('status');
            $table->index('created_by');
            $table->foreign('meal_category_id', 'fk_caf_em_meal_category_id')
                  ->references('id')->on('caf_menu_categories')->onDelete('restrict');
        });

        // 12. caf_subscription_enrollments
        Schema::create('caf_subscription_enrollments', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('subscription_plan_id')->comment('caf_subscription_plans.id');
            $table->unsignedInteger('student_id')->nullable()
                  ->comment('std_students.id — mutually exclusive with staff_id');
            $table->unsignedInteger('staff_id')->nullable()
                  ->comment('sys_users.id — mutually exclusive with student_id');
            $table->unsignedInteger('meal_card_id')->nullable()->comment('caf_meal_cards.id');
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->enum('status', ['Active', 'Paused', 'Cancelled', 'Expired'])->default('Active');
            $table->text('cancellation_reason')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('subscription_plan_id');
            $table->index('student_id');
            $table->index('staff_id');
            $table->index('meal_card_id');
            $table->index('status');
            $table->index('created_by');
            $table->foreign('subscription_plan_id', 'fk_caf_se_plan_id')
                  ->references('id')->on('caf_subscription_plans')->onDelete('restrict');
            $table->foreign('meal_card_id', 'fk_caf_se_meal_card_id')
                  ->references('id')->on('caf_meal_cards')->onDelete('set null');
        });

        // 13. caf_meal_card_transactions (no softDeletes — financial ledger)
        Schema::create('caf_meal_card_transactions', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('meal_card_id')->comment('caf_meal_cards.id');
            $table->unsignedInteger('student_id')->comment('std_students.id — denormalized');
            $table->enum('transaction_type', ['Credit', 'Debit', 'Refund', 'Adjustment']);
            $table->decimal('amount', 10, 2);
            $table->decimal('balance_after', 10, 2)
                  ->comment('Balance snapshot AFTER transaction — ledger integrity');
            $table->string('reference_type', 50)->nullable()
                  ->comment('Order, POS, TopUp, Refund, Adjustment');
            $table->unsignedInteger('reference_id')->nullable()
                  ->comment('Polymorphic FK to referenced record');
            $table->enum('payment_mode', ['Online', 'Cash', 'Wallet', 'Free'])->nullable()
                  ->comment('For top-up (Credit) transactions');
            $table->string('razorpay_payment_id', 100)->nullable()->unique()
                  ->comment('Idempotency (BR-CAF-011) — multiple NULLs allowed');
            $table->text('notes')->nullable();
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            // No softDeletes — financial ledger; immutable

            $table->index('meal_card_id');
            $table->index('student_id');
            $table->index('transaction_type');
            $table->index(['meal_card_id', 'created_at'], 'idx_caf_mct_card_created');
            $table->index('created_by');
            $table->foreign('meal_card_id', 'fk_caf_mct_meal_card_id')
                  ->references('id')->on('caf_meal_cards')->onDelete('restrict');
        });

        // 14. caf_meal_attendance (no is_active/updated_at/softDeletes — immutable scan record)
        Schema::create('caf_meal_attendance', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('student_id')->comment('std_students.id');
            $table->date('meal_date');
            $table->unsignedInteger('meal_category_id')->comment('caf_menu_categories.id');
            $table->timestamp('scanned_at')->useCurrent()->comment('Exact scan timestamp');
            $table->enum('scan_method', ['QR', 'Biometric', 'Manual'])->default('QR');
            $table->string('counter_name', 100)->nullable()->comment('POS counter name');
            $table->unsignedInteger('scanned_by')->nullable()
                  ->comment('sys_users.id — for manual scans only');
            $table->timestamp('created_at')->nullable();
            // No updated_at, no is_active, no softDeletes — immutable

            $table->unique(['student_id', 'meal_date', 'meal_category_id'], 'uq_caf_ma');
            $table->index('meal_date');
            $table->index('meal_category_id');
            $table->index('scanned_by');
            $table->foreign('meal_category_id', 'fk_caf_ma_meal_category_id')
                  ->references('id')->on('caf_menu_categories')->onDelete('restrict');
        });

        // 15. caf_pos_transactions (no is_active/softDeletes — transactional record)
        Schema::create('caf_pos_transactions', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('pos_session_id')->comment('caf_pos_sessions.id');
            $table->unsignedInteger('student_id')->nullable()->comment('std_students.id — NULL if anonymous');
            $table->unsignedInteger('staff_id')->nullable()
                  ->comment('sys_users.id — NULL if student transaction');
            $table->unsignedInteger('meal_card_id')->nullable()
                  ->comment('caf_meal_cards.id — NULL for cash');
            $table->json('items_json')->comment('Immutable snapshot [{menu_item_id,name,qty,price}]');
            $table->decimal('total_amount', 10, 2);
            $table->enum('payment_mode', ['MealCard', 'Cash']);
            $table->decimal('balance_after', 10, 2)->nullable()
                  ->comment('Card balance after deduction (MealCard only)');
            $table->json('dietary_flags_json')->nullable()
                  ->comment('Student dietary flags snapshot at scan time');
            $table->tinyInteger('receipt_sent')->default(0);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            // No is_active, no softDeletes — transactional record

            $table->index('pos_session_id');
            $table->index('student_id');
            $table->index('staff_id');
            $table->index('meal_card_id');
            $table->index('created_by');
            $table->foreign('pos_session_id', 'fk_caf_pt_session_id')
                  ->references('id')->on('caf_pos_sessions')->onDelete('restrict');
            $table->foreign('meal_card_id', 'fk_caf_pt_meal_card_id')
                  ->references('id')->on('caf_meal_cards')->onDelete('set null');
        });

        // 16. caf_staff_meal_logs (no is_active/softDeletes — transactional log)
        Schema::create('caf_staff_meal_logs', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('staff_id')->comment('sys_users.id');
            $table->date('meal_date');
            $table->unsignedInteger('meal_category_id')->comment('caf_menu_categories.id');
            $table->json('items_json')->nullable()->comment('Items consumed (snapshot)');
            $table->decimal('amount', 8, 2)->default(0.00);
            $table->enum('payment_mode', ['Subscription', 'Cash', 'CardDeduction']);
            $table->tinyInteger('payroll_deduction_flag')->default(0)
                  ->comment('Signal for PAY module (BR-CAF-019) — CAF never writes to pay_*');
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            // No is_active, no softDeletes — transactional log

            $table->index('staff_id');
            $table->index('meal_date');
            $table->index('meal_category_id');
            $table->index('payroll_deduction_flag');
            $table->index('created_by');
            $table->foreign('meal_category_id', 'fk_caf_sml_meal_category_id')
                  ->references('id')->on('caf_menu_categories')->onDelete('restrict');
        });

        // 17. caf_orders
        Schema::create('caf_orders', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->string('order_number', 30)->unique()->comment('e.g. CAF-2026-XXXXXXXX');
            $table->unsignedInteger('student_id')->comment('std_students.id');
            $table->unsignedInteger('meal_card_id')->nullable()
                  ->comment('caf_meal_cards.id — NULL if cash/counter');
            $table->date('order_date')->comment('Calendar date the meal is ordered for');
            $table->unsignedInteger('meal_category_id')->comment('caf_menu_categories.id');
            $table->decimal('total_amount', 10, 2);
            $table->enum('payment_mode', ['MealCard', 'Cash', 'Counter', 'Subscription'])
                  ->default('MealCard');
            $table->enum('status', ['Pending', 'Confirmed', 'Served', 'Cancelled'])
                  ->default('Confirmed');
            $table->timestamp('cancelled_at')->nullable();
            $table->string('cancellation_reason', 255)->nullable();
            $table->text('notes')->nullable();
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('student_id');
            $table->index('meal_card_id');
            $table->index('meal_category_id');
            $table->index(['student_id', 'order_date'], 'idx_caf_ord_student_date');
            $table->index(['order_date', 'meal_category_id', 'status'], 'idx_caf_ord_date_cat_status');
            $table->index('created_by');
            $table->foreign('meal_card_id', 'fk_caf_ord_meal_card_id')
                  ->references('id')->on('caf_meal_cards')->onDelete('set null');
            $table->foreign('meal_category_id', 'fk_caf_ord_meal_category_id')
                  ->references('id')->on('caf_menu_categories')->onDelete('restrict');
        });

        // =====================================================================
        // LAYER 3 — Depends on Layer 2
        // =====================================================================

        // 18. caf_daily_menu_items_jnt (no softDeletes — junction table)
        Schema::create('caf_daily_menu_items_jnt', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('daily_menu_id')->comment('caf_daily_menus.id');
            $table->unsignedInteger('menu_item_id')->comment('caf_menu_items.id');
            $table->unsignedInteger('meal_category_id')->comment('caf_menu_categories.id');
            $table->string('serving_size_notes', 100)->nullable()->comment('e.g. 1 plate, 200ml');
            $table->unsignedTinyInteger('display_order')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            // No softDeletes — junction table

            $table->unique(['daily_menu_id', 'menu_item_id', 'meal_category_id'], 'uq_caf_dmij');
            $table->index('daily_menu_id');
            $table->index('menu_item_id');
            $table->index('meal_category_id');
            $table->index('created_by');
            $table->foreign('daily_menu_id', 'fk_caf_dmij_daily_menu_id')
                  ->references('id')->on('caf_daily_menus')->onDelete('cascade');
            $table->foreign('menu_item_id', 'fk_caf_dmij_menu_item_id')
                  ->references('id')->on('caf_menu_items')->onDelete('cascade');
            $table->foreign('meal_category_id', 'fk_caf_dmij_meal_category_id')
                  ->references('id')->on('caf_menu_categories')->onDelete('restrict');
        });

        // 19. caf_event_meal_items_jnt (no softDeletes — junction; menu_item_id nullable)
        Schema::create('caf_event_meal_items_jnt', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('event_meal_id')->comment('caf_event_meals.id');
            $table->unsignedInteger('menu_item_id')->nullable()
                  ->comment('caf_menu_items.id — NULLABLE: free-text items allowed');
            $table->string('free_text_item', 150)->nullable()
                  ->comment('Item name when not in dish library');
            $table->decimal('quantity_per_student', 5, 2)->nullable();
            $table->unsignedTinyInteger('display_order')->default(0);
            $table->tinyInteger('is_active')->default(1);
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            // No softDeletes — junction table

            $table->index('event_meal_id');
            $table->index('menu_item_id');
            $table->index('created_by');
            $table->foreign('event_meal_id', 'fk_caf_emij_event_meal_id')
                  ->references('id')->on('caf_event_meals')->onDelete('cascade');
            $table->foreign('menu_item_id', 'fk_caf_emij_menu_item_id')
                  ->references('id')->on('caf_menu_items')->onDelete('set null');
        });

        // 20. caf_consumption_logs (no is_active/softDeletes — usage log)
        Schema::create('caf_consumption_logs', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('stock_item_id')->comment('caf_stock_items.id');
            $table->date('log_date');
            $table->decimal('quantity_used', 10, 3)->comment('Amount consumed');
            $table->unsignedInteger('meal_category_id')->nullable()->comment('caf_menu_categories.id');
            $table->string('notes', 255)->nullable();
            $table->unsignedInteger('created_by')->nullable()->comment('sys_users.id');
            $table->timestamps();
            // No is_active, no softDeletes — consumption log

            $table->index('stock_item_id');
            $table->index('log_date');
            $table->index('meal_category_id');
            $table->index(['stock_item_id', 'log_date'], 'idx_caf_cl_item_date');
            $table->index('created_by');
            $table->foreign('stock_item_id', 'fk_caf_cl_stock_item_id')
                  ->references('id')->on('caf_stock_items')->onDelete('restrict');
            $table->foreign('meal_category_id', 'fk_caf_cl_meal_category_id')
                  ->references('id')->on('caf_menu_categories')->onDelete('set null');
        });

        // =====================================================================
        // LAYER 4 — Depends on Layer 3
        // =====================================================================

        // 21. caf_order_items (no is_active/created_by/softDeletes — transactional line item)
        Schema::create('caf_order_items', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement();
            $table->unsignedInteger('order_id')->comment('caf_orders.id');
            $table->unsignedInteger('menu_item_id')->comment('caf_menu_items.id');
            $table->unsignedTinyInteger('quantity')->default(1)->comment('Number of servings');
            $table->decimal('unit_price', 8, 2)
                  ->comment('Price snapshot at order time — NEVER re-read from caf_menu_items.price');
            $table->decimal('line_total', 10, 2)
                  ->comment('quantity × unit_price — populated at insert');
            $table->timestamps();
            // No is_active, no created_by, no softDeletes — transactional line item

            $table->unique(['order_id', 'menu_item_id'], 'uq_caf_oi_order_item');
            $table->index('order_id');
            $table->index('menu_item_id');
            $table->foreign('order_id', 'fk_caf_oi_order_id')
                  ->references('id')->on('caf_orders')->onDelete('cascade');
            $table->foreign('menu_item_id', 'fk_caf_oi_menu_item_id')
                  ->references('id')->on('caf_menu_items')->onDelete('restrict');
        });
    }

    /**
     * Reverse the migrations.
     * Drops all 21 caf_* tables in reverse dependency order (Layer 4 → Layer 1).
     */
    public function down(): void
    {
        Schema::disableForeignKeyConstraints();

        // Layer 4
        Schema::dropIfExists('caf_order_items');

        // Layer 3
        Schema::dropIfExists('caf_consumption_logs');
        Schema::dropIfExists('caf_event_meal_items_jnt');
        Schema::dropIfExists('caf_daily_menu_items_jnt');

        // Layer 2
        Schema::dropIfExists('caf_orders');
        Schema::dropIfExists('caf_staff_meal_logs');
        Schema::dropIfExists('caf_pos_transactions');
        Schema::dropIfExists('caf_meal_attendance');
        Schema::dropIfExists('caf_meal_card_transactions');
        Schema::dropIfExists('caf_subscription_enrollments');
        Schema::dropIfExists('caf_event_meals');
        Schema::dropIfExists('caf_stock_items');
        Schema::dropIfExists('caf_menu_items');

        // Layer 1
        Schema::dropIfExists('caf_dietary_profiles');
        Schema::dropIfExists('caf_pos_sessions');
        Schema::dropIfExists('caf_meal_cards');
        Schema::dropIfExists('caf_subscription_plans');
        Schema::dropIfExists('caf_daily_menus');
        Schema::dropIfExists('caf_fssai_records');
        Schema::dropIfExists('caf_suppliers');
        Schema::dropIfExists('caf_menu_categories');

        Schema::enableForeignKeyConstraints();
    }
};
