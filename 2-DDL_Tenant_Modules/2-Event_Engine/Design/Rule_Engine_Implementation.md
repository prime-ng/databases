# Rule Engine Implementation

Now the missing piece is how the Rule Engine is actually triggered at runtime when something happens like:
  - Quiz submitted
  - Quiz evaluated
  - Homework overdue
  - Exam attempted

Below is a clean, production-grade Laravel pattern that fits perfectly with your ERP/LMS architecture.

## Rule Engine Triggering – End-to-End Design (Laravel)

We’ll implement this in 5 layers:
  1. Where the trigger happens (Event Source)
  2. Trigger Dispatcher (Generic)
  3. Rule Resolver (DB-driven)
  4. Rule Evaluator
  5. Action Executor

This keeps your Rule Engine:
  - decoupled
  - reusable
  - extensible (AI rules later)

### 1. Where Do We Trigger the Rule Engine?
👉 Trigger at domain boundaries, not inside controllers.

Example Scenarios
| Event	                       | Where to trigger
|------------------------------|------------------------------------------
| Quiz Attempt Submitted	   | QuizAttemptService::submit()
| Quiz Evaluated	           | QuizEvaluationService::evaluate()
| Homework Overdue	           | Scheduled Cron Job
| Assignment Submitted	       | Assignment Service

### 2. Trigger Dispatcher (CORE ENTRY POINT)

This is the single gateway for all rule triggers.

📁 app/Services/RuleEngine/RuleEngineDispatcher.php

``` php
<?php

namespace App\Services\RuleEngine;

use App\Models\LmsTriggerEvent;
use App\Models\LmsRuleEngineConfig;

class RuleEngineDispatcher
{
    public static function trigger(string $eventCode, array $context)
    {
        // 1️⃣ Load Trigger Event
        $triggerEvent = LmsTriggerEvent::where('code', $eventCode)
            ->where('is_active', 1)
            ->first();

        if (!$triggerEvent) {
            return;
        }

        // 2️⃣ Load Active Rules for this Event
        $rules = LmsRuleEngineConfig::where('trigger_event_id', $triggerEvent->id)
            ->where('is_active', 1)
            ->get();

        foreach ($rules as $rule) {
            RuleEvaluator::evaluate($rule, $context);
        }
    }
}
```

### 3. Rule Evaluator (LOGIC DECISION MAKER)
This evaluates logic_config JSON against runtime data.

📁 app/Services/RuleEngine/RuleEvaluator.php
``` php
<?php

namespace App\Services\RuleEngine;

use App\Models\LmsActionType;

class RuleEvaluator
{
    public static function evaluate($rule, array $context)
    {
        $logic = json_decode($rule->logic_config, true);

        // Example: Quiz score based rule
        if (isset($logic['min_score'])) {
            if ($context['score'] >= $logic['min_score']) {
                return; // PASS → No action
            }
        }

        if (isset($logic['attempts'])) {
            if ($context['attempt_no'] > $logic['attempts']) {
                return;
            }
        }

        // Rule matched → Execute Action
        $actionType = LmsActionType::find($rule->action_type_id);

        if ($actionType && $actionType->is_active) {
            ActionExecutor::execute($actionType->code, $context);
        }
    }
}
```

### 4. Action Executor (COMMAND PATTERN)

This converts DB action codes into real system behavior.

📁 app/Services/RuleEngine/ActionExecutor.php
``` php
<?php

namespace App\Services\RuleEngine;

use App\Services\LMS\LessonPlanService;
use App\Services\Notification\NotificationService;

class ActionExecutor
{
    public static function execute(string $actionCode, array $context)
    {
        match ($actionCode) {

            'AUTO_ASSIGN_REMEDIAL' =>
                LessonPlanService::assignRemedial(
                    $context['student_id'],
                    $context['subject_id']
                ),

            'NOTIFY_PARENT' =>
                NotificationService::notifyParent(
                    $context['student_id'],
                    'Your child needs improvement'
                ),

            default => null
        };
    }
}
```

### 5. ACTUAL TRIGGER – Quiz Attempt Example 🔥
🎯 Scenario

Student submits a Quiz Attempt.

📁 QuizAttemptService.php
``` php
use App\Services\RuleEngine\RuleEngineDispatcher;

class QuizAttemptService
{
    public function submit(array $data)
    {
        $attempt = QuizAttempt::create([
            'student_id' => $data['student_id'],
            'quiz_id'    => $data['quiz_id'],
            'score'      => $data['score'],
            'attempt_no' => $data['attempt_no'],
        ]);

        // 🔥 TRIGGER RULE ENGINE
        RuleEngineDispatcher::trigger('ON_QUIZ_COMPLETION', [
            'student_id' => $attempt->student_id,
            'quiz_id'    => $attempt->quiz_id,
            'score'      => $attempt->score,
            'attempt_no'=> $attempt->attempt_no,
            'subject_id'=> $data['subject_id'],
        ]);

        return $attempt;
    }
}
```

### 6. Homework Overdue (CRON BASED TRIGGER)
📁 app/Console/Commands/CheckHomeworkOverdue.php
``` php
use App\Services\RuleEngine\RuleEngineDispatcher;

foreach ($overdueHomework as $hw) {

    RuleEngineDispatcher::trigger('ON_HOMEWORK_OVERDUE', [
        'student_id'  => $hw->student_id,
        'homework_id' => $hw->id,
        'due_days'    => $hw->due_days,
    ]);
}
```

### 7. Data Flow Summary (Very Important)
``` sql
EVENT (Quiz Submitted)
        ↓
RuleEngineDispatcher
        ↓
Load Trigger Event
        ↓
Load Active Rules
        ↓
RuleEvaluator (logic_config)
        ↓
ActionExecutor
        ↓
Real System Action
```

### 8. Why This Design Is PERFECT for Your ERP

✔ Fully DB-driven
✔ No hard-coding of rules
✔ New rule = DB INSERT ONLY
✔ Supports:
  - AI rules later
  - Conditional branching
  - Multiple actions per event
  - Event chaining

---

## ROADMAP (What we’ll cover)

1️⃣ Rule Execution Log (Audit + Debug)
2️⃣ Rule Priority & Conflict Resolution
3️⃣ Multiple Actions per Rule
4️⃣ AI-Ready Rule Scoring Engine
5️⃣ Visual Rule Builder (Admin UI – Backend Design)

### 1. RULE EXECUTION LOG (FOUNDATION – MUST HAVE)
❓ Why Needed
  - Audit trail (very important for schools)
  - Debugging
  - AI training data later
  - Parent/management explanations (“why was this assigned?”)

**Table: lms_rule_execution_log**
``` sql
CREATE TABLE lms_rule_execution_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    rule_id BIGINT UNSIGNED NOT NULL,
    trigger_event_id BIGINT UNSIGNED NOT NULL,
    action_type_id BIGINT UNSIGNED NOT NULL,

    entity_type VARCHAR(50) NOT NULL,  
    entity_id BIGINT UNSIGNED NOT NULL,

    execution_context JSON NOT NULL,
    execution_result ENUM('SUCCESS','FAILED','SKIPPED') NOT NULL,
    error_message TEXT NULL,

    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_rule (rule_id),
    INDEX idx_entity (entity_type, entity_id)
);
```

**Update: ActionExecutor**

``` php
use App\Models\LmsRuleExecutionLog;

class ActionExecutor
{
    public static function execute(string $actionCode, array $context, $rule)
    {
        try {
            match ($actionCode) {
                'AUTO_ASSIGN_REMEDIAL' =>
                    LessonPlanService::assignRemedial(
                        $context['student_id'],
                        $context['subject_id']
                    ),

                'NOTIFY_PARENT' =>
                    NotificationService::notifyParent(
                        $context['student_id'],
                        'Performance alert'
                    ),
            };

            self::log($rule, $context, 'SUCCESS');

        } catch (\Throwable $e) {

            self::log($rule, $context, 'FAILED', $e->getMessage());
        }
    }

    private static function log($rule, $context, $status, $error = null)
    {
        LmsRuleExecutionLog::create([
            'rule_id'          => $rule->id,
            'trigger_event_id' => $rule->trigger_event_id,
            'action_type_id'   => $rule->action_type_id,
            'entity_type'      => 'STUDENT',
            'entity_id'        => $context['student_id'],
            'execution_context'=> json_encode($context),
            'execution_result'=> $status,
            'error_message'    => $error
        ]);
    }
}
```

✅ Now your Rule Engine is auditable

### 2. RULE PRIORITY & CONFLICT RESOLUTION
❓ Problem

What if multiple rules match the same event?

Example:
  - Rule A → Assign Remedial
  - Rule B → Notify Parent
  - Rule C → Lock Further Attempts

You need control.

**Table Change**
``` sql
ALTER TABLE lms_rule_engine_config
ADD COLUMN priority INT DEFAULT 100,
ADD COLUMN stop_further_execution TINYINT(1) DEFAULT 0;
```

**Dispatcher Update**
``` php
$rules = LmsRuleEngineConfig::where('trigger_event_id', $triggerEvent->id)
    ->where('is_active', 1)
    ->orderBy('priority', 'ASC')
    ->get();

foreach ($rules as $rule) {

    $executed = RuleEvaluator::evaluate($rule, $context);

    if ($executed && $rule->stop_further_execution) {
        break;
    }
}
```

**Evaluator Return Flag**
``` php
public static function evaluate($rule, array $context): bool
{
    $logic = json_decode($rule->logic_config, true);

    if ($context['score'] >= $logic['min_score']) {
        return false;
    }

    ActionExecutor::execute(
        $rule->actionType->code,
        $context,
        $rule
    );
    return true;
}
```

✅ Deterministic behavior achieved

### 3. MULTIPLE ACTIONS PER RULE (VERY IMPORTANT)
❓ Real Scenario

Fail exam →
✔ Assign remedial
✔ Notify parent
✔ Notify teacher

**New Table: lms_rule_action_map**
``` sql
CREATE TABLE lms_rule_action_map (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_id BIGINT UNSIGNED NOT NULL,
    action_type_id BIGINT UNSIGNED NOT NULL,
    execution_order INT DEFAULT 1,
    is_active TINYINT(1) DEFAULT 1
);
```

**Evaluator Update**
``` php
$actions = $rule->actions()
    ->where('is_active', 1)
    ->orderBy('execution_order')
    ->get();

foreach ($actions as $action) {
    ActionExecutor::execute(
        $action->actionType->code,
        $context,
        $rule
    );
}
```

**Model Relation**
```php
public function actions()
{
    return $this->hasMany(LmsRuleActionMap::class, 'rule_id');
}
```

### 4.AI-READY RULE SCORING ENGINE
❓ Why Needed

Static rules fail over time.
AI should:
  - learn patterns
  - suppress noisy rules
  - recommend actions

**Add Columns**
``` sql
ALTER TABLE lms_rule_engine_config
ADD COLUMN ai_confidence_score DECIMAL(5,2) DEFAULT NULL,
ADD COLUMN ai_enabled TINYINT(1) DEFAULT 0;
```

**AI Scoring Hook**
``` php
if ($rule->ai_enabled) {

    $score = AIRuleScoringService::score($rule, $context);

    if ($score < 0.6) {
        return false;
    }
```

**AI Input Signals (Future)**
From lms_rule_execution_log:
  - success rate
  - parent response
  - improvement delta
  - teacher overrides

This gives you true AI-driven automation later.

### 5. VISUAL RULE BUILDER – BACKEND DESIGN
**Admin UI Capabilities**
    - Select Trigger
    - Add Conditions
    - Add Actions
    - Priority
    - Stop further rules

**UI JSON Schema (Saved in DB)**
``` json
  {
  "conditions": [
    { "field": "score", "operator": "<", "value": 33 },
    { "field": "attempt_no", "operator": ">=", "value": 2 }
  ],
  "actions": [
    { "code": "AUTO_ASSIGN_REMEDIAL" },
    { "code": "NOTIFY_PARENT" }
  ]
  }
```

**Evaluator (Generic Condition Engine)**
``` php
  foreach ($logic['conditions'] as $condition) {

    if (!ConditionResolver::match($condition, $context)) {
        return false;
    }
}
```

**Condition Resolver**
``` php
class ConditionResolver
{
    public static function match($condition, $context)
    {
        return match ($condition['operator']) {
            '<'  => $context[$condition['field']] < $condition['value'],
            '>'  => $context[$condition['field']] > $condition['value'],
            '>=' => $context[$condition['field']] >= $condition['value'],
            '='  => $context[$condition['field']] == $condition['value'],
        };
    }
}
```

✅ This directly supports drag-drop UI rules

**FINAL RESULT**
You now have a production-grade Rule Engine:

✔ DB-driven
✔ Auditable
✔ Conflict-safe
✔ Multi-action capable
✔ AI-ready
✔ UI-ready






