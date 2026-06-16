<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * BA — Behavioural Assessment Module Migration
     * 16 tables in dependency order (Layer 1 → Layer 6)
     * Database: tenant_db (no tenant_id columns)
     */
    public function up(): void
    {
        // =====================================================================
        // LAYER 1 — No dependencies on other ba_* tables
        // =====================================================================

        // 1. ba_rating_scales
        Schema::create('ba_rating_scales', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->text('description')->nullable();
            $table->json('grade_boundaries_json')->nullable()->comment('Grade mapping: [{"grade":"A+","min":4.50,"max":5.00}]');
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
        });

        // 2. ba_categories
        Schema::create('ba_categories', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('parent_id')->nullable()->comment('Self-ref for sub-categories');
            $table->string('name', 100);
            $table->text('description')->nullable();
            $table->enum('polarity', ['positive', 'negative']);
            $table->decimal('weight', 5, 2)->default(100.00)->comment('Weight in overall score (proportional)');
            $table->unsignedTinyInteger('sort_order');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('parent_id', 'idx_ba_cat_parent');
            $table->index('polarity', 'idx_ba_cat_polarity');
            $table->foreign('parent_id', 'fk_ba_cat_parent_id')
                  ->references('id')->on('ba_categories')->onDelete('set null');
        });

        // 3. ba_interventions
        Schema::create('ba_interventions', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->text('description')->nullable();
            $table->enum('intervention_type', ['reward', 'corrective', 'counselling']);
            $table->unsignedTinyInteger('sort_order');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();
        });

        // =====================================================================
        // LAYER 2 — Depends on Layer 1
        // =====================================================================

        // 4. ba_rating_levels
        Schema::create('ba_rating_levels', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rating_scale_id');
            $table->string('label', 50);
            $table->decimal('numeric_value', 3, 1);
            $table->string('description', 255)->nullable();
            $table->unsignedTinyInteger('sort_order');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['rating_scale_id', 'sort_order'], 'uq_ba_level');
            $table->index('rating_scale_id', 'idx_ba_level_scale');
            $table->foreign('rating_scale_id', 'fk_ba_level_rating_scale_id')
                  ->references('id')->on('ba_rating_scales')->onDelete('cascade');
        });

        // 5. ba_criteria
        Schema::create('ba_criteria', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('category_id');
            $table->string('name', 255);
            $table->text('description')->nullable();
            $table->decimal('weight', 5, 2)->default(0.00)->comment('Weight within category (proportional)');
            $table->unsignedTinyInteger('sort_order');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('category_id', 'idx_ba_criteria_category');
            $table->foreign('category_id', 'fk_ba_criteria_category_id')
                  ->references('id')->on('ba_categories')->onDelete('cascade');
        });

        // =====================================================================
        // LAYER 3 — Depends on sch_* + Layer 1
        // =====================================================================

        // 6. ba_class_category_jnt
        Schema::create('ba_class_category_jnt', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('class_id')->comment('FK to sch_classes.id');
            $table->unsignedBigInteger('category_id');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['class_id', 'category_id'], 'uq_ba_class_cat');
            $table->index('class_id', 'idx_ba_cc_class');
            $table->index('category_id', 'idx_ba_cc_category');
            $table->foreign('class_id', 'fk_ba_cc_class_id')
                  ->references('id')->on('sch_classes')->onDelete('cascade');
            $table->foreign('category_id', 'fk_ba_cc_category_id')
                  ->references('id')->on('ba_categories')->onDelete('cascade');
        });

        // 7. ba_assessment_periods
        Schema::create('ba_assessment_periods', function (Blueprint $table) {
            $table->id();
            $table->unsignedSmallInteger('academic_session_id')->comment('FK to sch_org_academic_sessions_jnt.id');
            $table->unsignedSmallInteger('academic_term_id')->nullable()->comment('FK to sch_academic_term.id (optional)');
            $table->string('name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->date('deadline')->comment('Teacher submission deadline');
            $table->enum('status', ['open', 'closed', 'locked'])->default('open');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('academic_session_id', 'idx_ba_period_session');
            $table->index('academic_term_id', 'idx_ba_period_term');
            $table->index('status', 'idx_ba_period_status');
            $table->foreign('academic_session_id', 'fk_ba_period_session_id')
                  ->references('id')->on('sch_org_academic_sessions_jnt')->onDelete('restrict');
            $table->foreign('academic_term_id', 'fk_ba_period_term_id')
                  ->references('id')->on('sch_academic_term')->onDelete('set null');
        });

        // 8. ba_config
        Schema::create('ba_config', function (Blueprint $table) {
            $table->id();
            $table->unsignedSmallInteger('academic_session_id')->comment('FK to sch_org_academic_sessions_jnt.id');
            $table->unsignedBigInteger('rating_scale_id');
            $table->boolean('is_result_integration_enabled')->default(false);
            $table->decimal('weightage_percent', 4, 1)->default(10.0)->comment('5.0–20.0');
            $table->enum('aggregation_method', ['average', 'weighted_average', 'separate_display'])->default('weighted_average');
            $table->enum('parent_notification_threshold', ['minor', 'moderate', 'major', 'critical'])->default('moderate');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique('academic_session_id', 'uq_ba_config_session');
            $table->index('rating_scale_id', 'idx_ba_config_scale');
            $table->foreign('academic_session_id', 'fk_ba_config_session_id')
                  ->references('id')->on('sch_org_academic_sessions_jnt')->onDelete('restrict');
            $table->foreign('rating_scale_id', 'fk_ba_config_scale_id')
                  ->references('id')->on('ba_rating_scales')->onDelete('restrict');
        });

        // =====================================================================
        // LAYER 4 — Depends on Layer 3 + sch_*
        // =====================================================================

        // 9. ba_assessments
        Schema::create('ba_assessments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('period_id');
            $table->unsignedInteger('teacher_id')->comment('FK to sch_employees.id');
            $table->unsignedInteger('class_section_id')->comment('FK to sch_class_section_jnt.id');
            $table->enum('status', ['draft', 'submitted', 'reviewed', 'locked'])->default('draft');
            $table->timestamp('submitted_at')->nullable();
            $table->unsignedInteger('reviewed_by')->nullable()->comment('FK to sch_employees.id');
            $table->timestamp('reviewed_at')->nullable();
            $table->text('reviewer_remarks')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['teacher_id', 'class_section_id', 'period_id'], 'uq_ba_assessment');
            $table->index('period_id', 'idx_ba_assess_period');
            $table->index('teacher_id', 'idx_ba_assess_teacher');
            $table->index('class_section_id', 'idx_ba_assess_cs');
            $table->index('reviewed_by', 'idx_ba_assess_reviewed_by');
            $table->index(['period_id', 'status'], 'idx_ba_assess_status');
            $table->foreign('period_id', 'fk_ba_assess_period_id')
                  ->references('id')->on('ba_assessment_periods')->onDelete('restrict');
            $table->foreign('teacher_id', 'fk_ba_assess_teacher_id')
                  ->references('id')->on('sch_employees')->onDelete('restrict');
            $table->foreign('class_section_id', 'fk_ba_assess_cs_id')
                  ->references('id')->on('sch_class_section_jnt')->onDelete('restrict');
            $table->foreign('reviewed_by', 'fk_ba_assess_reviewed_by')
                  ->references('id')->on('sch_employees')->onDelete('set null');
        });

        // 10. ba_audit_log (IMMUTABLE — no updated_at, no deleted_at)
        Schema::create('ba_audit_log', function (Blueprint $table) {
            $table->id();
            $table->enum('entity_type', ['assessment_rating', 'assessment', 'incident']);
            $table->unsignedBigInteger('entity_id');
            $table->string('field_name', 50);
            $table->string('old_value', 255)->nullable();
            $table->string('new_value', 255)->nullable();
            $table->unsignedBigInteger('changed_by')->comment('sys_users.id');
            $table->timestamp('changed_at')->useCurrent();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->timestamp('created_at')->nullable();
            // NO updated_at, NO deleted_at — immutable audit records

            $table->index(['entity_type', 'entity_id'], 'idx_ba_audit_entity');
            $table->index('changed_by', 'idx_ba_audit_changed_by');
            $table->index('changed_at', 'idx_ba_audit_changed_at');
        });

        // =====================================================================
        // LAYER 5 — Depends on Layer 4 + Layer 2
        // =====================================================================

        // 11. ba_assessment_ratings
        Schema::create('ba_assessment_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('assessment_id');
            $table->unsignedInteger('student_id')->comment('FK to std_students.id');
            $table->unsignedBigInteger('criterion_id');
            $table->unsignedBigInteger('rating_level_id')->nullable()->comment('NULL = not yet rated');
            $table->string('remark', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['assessment_id', 'student_id', 'criterion_id'], 'uq_ba_rating');
            $table->index('assessment_id', 'idx_ba_rating_assess');
            $table->index('student_id', 'idx_ba_rating_student');
            $table->index('criterion_id', 'idx_ba_rating_criterion');
            $table->index('rating_level_id', 'idx_ba_rating_level');
            $table->index(['student_id', 'criterion_id', 'assessment_id'], 'idx_ba_rating_lookup');
            $table->foreign('assessment_id', 'fk_ba_rating_assessment_id')
                  ->references('id')->on('ba_assessments')->onDelete('cascade');
            $table->foreign('student_id', 'fk_ba_rating_student_id')
                  ->references('id')->on('std_students')->onDelete('restrict');
            $table->foreign('criterion_id', 'fk_ba_rating_criterion_id')
                  ->references('id')->on('ba_criteria')->onDelete('restrict');
            $table->foreign('rating_level_id', 'fk_ba_rating_level_id')
                  ->references('id')->on('ba_rating_levels')->onDelete('set null');
        });

        // 12. ba_student_remarks
        Schema::create('ba_student_remarks', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('assessment_id');
            $table->unsignedInteger('student_id')->comment('FK to std_students.id');
            $table->text('remark_text');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['assessment_id', 'student_id'], 'uq_ba_remark');
            $table->index('assessment_id', 'idx_ba_remark_assess');
            $table->index('student_id', 'idx_ba_remark_student');
            $table->foreign('assessment_id', 'fk_ba_remark_assessment_id')
                  ->references('id')->on('ba_assessments')->onDelete('cascade');
            $table->foreign('student_id', 'fk_ba_remark_student_id')
                  ->references('id')->on('std_students')->onDelete('restrict');
        });

        // 13. ba_computed_scores
        Schema::create('ba_computed_scores', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('student_id')->comment('FK to std_students.id');
            $table->unsignedBigInteger('category_id');
            $table->unsignedBigInteger('period_id');
            $table->decimal('numeric_score', 5, 2);
            $table->string('grade', 5)->nullable();
            $table->decimal('overall_score', 5, 2)->nullable();
            $table->string('overall_grade', 5)->nullable();
            $table->timestamp('computed_at')->useCurrent();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['student_id', 'category_id', 'period_id'], 'uq_ba_score');
            $table->index('student_id', 'idx_ba_score_student');
            $table->index('category_id', 'idx_ba_score_category');
            $table->index('period_id', 'idx_ba_score_period');
            $table->index(['student_id', 'period_id'], 'idx_ba_score_lookup');
            $table->foreign('student_id', 'fk_ba_score_student_id')
                  ->references('id')->on('std_students')->onDelete('restrict');
            $table->foreign('category_id', 'fk_ba_score_category_id')
                  ->references('id')->on('ba_categories')->onDelete('restrict');
            $table->foreign('period_id', 'fk_ba_score_period_id')
                  ->references('id')->on('ba_assessment_periods')->onDelete('restrict');
        });

        // 14. ba_incidents
        Schema::create('ba_incidents', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('student_id')->comment('FK to std_students.id');
            $table->unsignedInteger('reported_by')->comment('FK to sch_employees.id');
            $table->unsignedBigInteger('category_id')->nullable();
            $table->unsignedBigInteger('criterion_id')->nullable();
            $table->date('incident_date');
            $table->time('incident_time')->nullable();
            $table->enum('incident_type', ['positive_reinforcement', 'negative_incident']);
            $table->enum('severity', ['minor', 'moderate', 'major', 'critical'])->nullable();
            $table->text('description');
            $table->enum('location', ['classroom', 'playground', 'corridor', 'lab', 'transport', 'canteen', 'library', 'other'])->default('classroom');
            $table->text('intervention_notes')->nullable();
            $table->boolean('is_follow_up_required')->default(false);
            $table->date('follow_up_date')->nullable();
            $table->text('follow_up_notes')->nullable();
            $table->json('attachments_json')->nullable();
            $table->boolean('is_notified')->default(false);
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->index('student_id', 'idx_ba_incident_student');
            $table->index('reported_by', 'idx_ba_incident_reporter');
            $table->index('category_id', 'idx_ba_incident_category');
            $table->index('criterion_id', 'idx_ba_incident_criterion');
            $table->index(['student_id', 'incident_date'], 'idx_ba_incident_timeline');
            $table->index('incident_type', 'idx_ba_incident_type');
            $table->index('severity', 'idx_ba_incident_severity');
            $table->foreign('student_id', 'fk_ba_incident_student_id')
                  ->references('id')->on('std_students')->onDelete('restrict');
            $table->foreign('reported_by', 'fk_ba_incident_reported_by')
                  ->references('id')->on('sch_employees')->onDelete('restrict');
            $table->foreign('category_id', 'fk_ba_incident_category_id')
                  ->references('id')->on('ba_categories')->onDelete('set null');
            $table->foreign('criterion_id', 'fk_ba_incident_criterion_id')
                  ->references('id')->on('ba_criteria')->onDelete('set null');
        });

        // =====================================================================
        // LAYER 6 — Depends on Layer 5 + Layer 1
        // =====================================================================

        // 15. ba_incident_witnesses_jnt
        Schema::create('ba_incident_witnesses_jnt', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('incident_id');
            $table->enum('witness_type', ['student', 'staff']);
            $table->unsignedInteger('witness_id')->comment('Polymorphic: std_students.id or sch_employees.id');
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['incident_id', 'witness_type', 'witness_id'], 'uq_ba_witness');
            $table->index('incident_id', 'idx_ba_witness_incident');
            $table->foreign('incident_id', 'fk_ba_witness_incident_id')
                  ->references('id')->on('ba_incidents')->onDelete('cascade');
        });

        // 16. ba_incident_intervention_jnt
        Schema::create('ba_incident_intervention_jnt', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('incident_id');
            $table->unsignedBigInteger('intervention_id');
            $table->string('notes', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedBigInteger('created_by')->comment('sys_users.id');
            $table->unsignedBigInteger('updated_by')->comment('sys_users.id');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['incident_id', 'intervention_id'], 'uq_ba_inc_int');
            $table->index('incident_id', 'idx_ba_ii_incident');
            $table->index('intervention_id', 'idx_ba_ii_intervention');
            $table->foreign('incident_id', 'fk_ba_ii_incident_id')
                  ->references('id')->on('ba_incidents')->onDelete('cascade');
            $table->foreign('intervention_id', 'fk_ba_ii_intervention_id')
                  ->references('id')->on('ba_interventions')->onDelete('restrict');
        });
    }

    /**
     * Reverse the migrations — drop in reverse dependency order (Layer 6 → Layer 1).
     */
    public function down(): void
    {
        // Layer 6
        Schema::dropIfExists('ba_incident_intervention_jnt');
        Schema::dropIfExists('ba_incident_witnesses_jnt');

        // Layer 5
        Schema::dropIfExists('ba_incidents');
        Schema::dropIfExists('ba_computed_scores');
        Schema::dropIfExists('ba_student_remarks');
        Schema::dropIfExists('ba_assessment_ratings');

        // Layer 4
        Schema::dropIfExists('ba_audit_log');
        Schema::dropIfExists('ba_assessments');

        // Layer 3
        Schema::dropIfExists('ba_config');
        Schema::dropIfExists('ba_assessment_periods');
        Schema::dropIfExists('ba_class_category_jnt');

        // Layer 2
        Schema::dropIfExists('ba_criteria');
        Schema::dropIfExists('ba_rating_levels');

        // Layer 1
        Schema::dropIfExists('ba_interventions');
        Schema::dropIfExists('ba_categories');
        Schema::dropIfExists('ba_rating_scales');
    }
};
