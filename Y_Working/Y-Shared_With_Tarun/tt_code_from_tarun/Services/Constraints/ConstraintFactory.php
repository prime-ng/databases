<?php

namespace Modules\SmartTimetable\Services\Constraints;

use Illuminate\Support\Facades\Validator;
use Modules\SmartTimetable\Models\Constraint;
use Modules\SmartTimetable\Models\ConstraintType;

class ConstraintFactory
{
    // here we map the constrate type to our DB Caonstraint Types DB, this can has to be connection b/w out DB & Constraint engine.
    private const CONSTRAINT_CLASS_MAP = [
        'LUNCH_BREAK' => \Modules\SmartTimetable\Services\Constraints\Hard\LunchBreakConstraint::class,
        'SHORT_BREAK' => \Modules\SmartTimetable\Services\Constraints\Hard\ShortBreakConstraint::class,
        'BREAK_PERIOD' => \Modules\SmartTimetable\Services\Constraints\Hard\BreakConstraint::class,
        'TEACHER_CONFLICT' => \Modules\SmartTimetable\Services\Constraints\Hard\TeacherConflictConstraint::class,
        'ROOM_AVAILABILITY' => \Modules\SmartTimetable\Services\Constraints\Hard\RoomAvailabilityConstraint::class,
        'MAX_DAILY_LOAD' => \Modules\SmartTimetable\Services\Constraints\Hard\MaximumDailyLoadConstraint::class,
        'NO_SAME_SUBJECT_SAME_DAY' => \Modules\SmartTimetable\Services\Constraints\Hard\NoSameSubjectSameDayConstraint::class,
        'FIXED_PERIOD_HIGH_PRIORITY' => \Modules\SmartTimetable\Services\Constraints\Hard\FixedPeriodForHighPriorityConstraint::class,
        'HIGH_PRIORITY_FIXED_PERIOD' => \Modules\SmartTimetable\Services\Constraints\Hard\HighPriorityFixedPeriodConstraint::class,
        'DAILY_SPREAD' => \Modules\SmartTimetable\Services\Constraints\Hard\DailySpreadConstraint::class,
        'PREFERRED_TIME_OF_DAY' => \Modules\SmartTimetable\Services\Constraints\Soft\PreferredTimeOfDayConstraint::class,
        'BALANCED_DAILY_SCHEDULE' => \Modules\SmartTimetable\Services\Constraints\Soft\BalancedDailyScheduleConstraint::class,
    ];

    /**
     * Create constraint instance from database constraint record
     */
    public function createFromDatabase(Constraint $constraint): TimetableConstraint
    {
        $typeCode = $constraint->constraintType->code;

        // Determine the PHP class
        $className = $this->resolveConstraintClass($typeCode, $constraint->constraintType);

        if (!class_exists($className)) {
            throw new \RuntimeException("Constraint class not found: {$className}");
        }

        // Decode parameters
        $params = $constraint->params_json ?? [];

        // Add metadata for context checking
        // as of now we have to set these parementer or can get theses paramter from our BD constraints.
        $params['_constraint_meta'] = [
            'id' => $constraint->id,
            'uuid' => $constraint->uuid,
            'name' => $constraint->name,
            'description' => $constraint->description,
            'target_type' => $constraint->target_type,
            'target_id' => $constraint->target_id,
            'effective_from' => $constraint->effective_from,
            'effective_to' => $constraint->effective_to,
            'applies_to_days' => $constraint->applies_to_days_json ?? [],
            'weight' => $constraint->weight,
            'scope' => $constraint->constraintType->scope,
            'category' => $constraint->constraintType->category,
        ];

        return new $className($params);
    }

    //Resolve constraint class from type code and constraint type

    private function resolveConstraintClass(string $typeCode, ConstraintType $constraintType): string
    {
        // step 1: Check if we have a direct mapping
        if (isset(self::CONSTRAINT_CLASS_MAP[$typeCode])) {
            return self::CONSTRAINT_CLASS_MAP[$typeCode];
        }

        // step 2: Try to infer from category/scope
        $className = $this->inferClassName($typeCode, $constraintType);

        if (class_exists($className)) {
            return $className;
        }

        // step 3: Use default based on is_hard_capable
        if ($constraintType->is_hard_capable) {
            return \Modules\SmartTimetable\Services\Constraints\Hard\GenericHardConstraint::class;
        } else {
            return \Modules\SmartTimetable\Services\Constraints\Soft\GenericSoftConstraint::class;
        }
    }

    //Infer class name from constraint type properties
    private function inferClassName(string $typeCode, ConstraintType $constraintType): string
    {
        $namespace = $constraintType->is_hard_capable
            ? 'Modules\SmartTimetable\Services\Constraints\Hard'
            : 'Modules\SmartTimetable\Services\Constraints\Soft';

        // Convert CODE to class name (e.g., TEACHER_CONFLICT -> TeacherConflictConstraint)
        $className = str_replace('_', '', ucwords(strtolower($typeCode), '_')) . 'Constraint';

        return $namespace . '\\' . $className;
    }

    /**
     * Validate constraint parameters against param_schema
     */
    public function validateParameters(Constraint $constraint): array
    {
        if (!$constraint->constraintType->param_schema) {
            return ['valid' => true, 'errors' => []];
        }

        $schema = $constraint->constraintType->param_schema;
        $params = $constraint->params_json ?? [];

        if (!is_array($schema) || empty($schema)) {
            return ['valid' => true, 'errors' => []];
        }

        // Convert schema to Laravel validation rules
        $rules = $this->convertSchemaToRules($schema);

        // Validate using Laravel's validator
        $validator = Validator::make($params, $rules);

        if ($validator->fails()) {
            \Log::warning('Constraint parameter validation failed', [
                'constraint_id' => $constraint->id,
                'errors' => $validator->errors()->toArray(),
                'params' => $params,
                'schema' => $schema,
            ]);

            return [
                'valid' => false,
                'errors' => $validator->errors()->toArray(),
            ];
        }

        return ['valid' => true, 'errors' => []];
    }

    /**
     * Convert JSON schema to Laravel validation rules AI  Generated
     */
    private function convertSchemaToRules(array $schema): array
    {
        $rules = [];

        foreach ($schema as $field => $fieldSchema) {
            $fieldRules = [];

            // Required
            if (isset($fieldSchema['required']) && $fieldSchema['required']) {
                $fieldRules[] = 'required';
            } else {
                $fieldRules[] = 'nullable';
            }

            // Type conversion
            if (isset($fieldSchema['type'])) {
                $typeRules = $this->getTypeRules($fieldSchema['type'], $fieldSchema);
                $fieldRules = array_merge($fieldRules, $typeRules);
            }

            // Enum/In values
            if (isset($fieldSchema['enum'])) {
                $fieldRules[] = 'in:' . implode(',', $fieldSchema['enum']);
            }

            // Min/Max for numbers
            if (isset($fieldSchema['minimum'])) {
                $fieldRules[] = 'min:' . $fieldSchema['minimum'];
            }
            if (isset($fieldSchema['maximum'])) {
                $fieldRules[] = 'max:' . $fieldSchema['maximum'];
            }

            // Min/Max length for strings
            if (isset($fieldSchema['minLength'])) {
                $fieldRules[] = 'min:' . $fieldSchema['minLength'];
            }
            if (isset($fieldSchema['maxLength'])) {
                $fieldRules[] = 'max:' . $fieldSchema['maxLength'];
            }

            $rules[$field] = $fieldRules;
        }

        return $rules;
    }

    /**
     * Get validation rules based on JSON schema type
     */
    private function getTypeRules(string $type, array $schema): array
    {
        switch ($type) {
            case 'string':
                return ['string'];

            case 'integer':
                return ['integer'];

            case 'number':
                return ['numeric'];

            case 'boolean':
                return ['boolean'];

            case 'array':
                $rules = ['array'];

                // Validate array items if specified
                if (isset($schema['items'])) {
                    $itemType = $schema['items']['type'] ?? 'string';

                    switch ($itemType) {
                        case 'string':
                            $rules[] = '*.string';
                            break;
                        case 'integer':
                            $rules[] = '*.integer';
                            break;
                        case 'number':
                            $rules[] = '*.numeric';
                            break;
                    }

                    // Enum for array items
                    if (isset($schema['items']['enum'])) {
                        $rules[] = '*.in:' . implode(',', $schema['items']['enum']);
                    }
                }
                return $rules;

            case 'object':
                return ['array']; // Objects are arrays in PHP

            default:
                return [];
        }
    }

}