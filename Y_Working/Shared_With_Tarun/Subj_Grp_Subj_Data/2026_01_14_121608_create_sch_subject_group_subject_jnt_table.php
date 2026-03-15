<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('sch_subject_group_subject_jnt', function (Blueprint $table) {
            $table->id();

            $table->foreignId('subject_group_id')
                ->constrained(
                    table: 'sch_subject_groups',
                    indexName: 'fk_subjGrpSubj_subjectGroup'
                )
                ->cascadeOnDelete();

            $table->foreignId('class_group_id')
                ->constrained(
                    table: 'sch_class_groups_jnt',
                    indexName: 'fk_subjGrpSubj_classGroup'
                )
                ->cascadeOnDelete();

            $table->foreignId('subject_id')
                ->constrained(
                    table: 'sch_subjects',
                    indexName: 'fk_subjGrpSubj_subject'
                )
                ->cascadeOnDelete();

            $table->foreignId('subject_type_id')
                ->constrained(
                    table: 'sch_subject_types',
                    indexName: 'fk_subjGrpSubj_subjectTypeId'
                )
                ->cascadeOnDelete();

            $table->foreignId('subject_study_format_id')
                ->constrained(
                    table: 'sch_subject_study_format_jnt',
                    indexName: 'fk_subjGrpSubj_subjectStudyFormatId'
                )
                ->cascadeOnDelete();

            $table->boolean('is_compulsory')->default(false);
            $table->unsignedTinyInteger('min_periods_per_week')->nullable();
            $table->unsignedTinyInteger('max_periods_per_week')->nullable();
            $table->unsignedTinyInteger('max_per_day')->nullable();
            $table->unsignedTinyInteger('min_per_day')->nullable();
            $table->unsignedTinyInteger('min_gap_periods')->nullable();
            $table->boolean('allow_consecutive')->default(false);
            $table->unsignedTinyInteger('max_consecutive')->default(2);
            $table->unsignedSmallInteger('priority')->default(50);

            $table->foreignId('compulsory_room_type')
                ->nullable()
                ->constrained('sch_rooms_type')
                ->nullOnDelete();

            $table->boolean('is_active')->default(true);
            $table->softDeletes();
            $table->timestamps();

            $table->unique(['subject_group_id', 'class_group_id'], 'uq_subjGrpSubj_subjGrpId_classGroup');
        });

    }

    public function down()
    {
        Schema::dropIfExists('sch_subject_group_subject_jnt');
    }
};
