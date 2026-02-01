# RULE ENGINE – SEQUENCE DIAGRAMS

## SCENARIO 1
Quiz Attempt Submitted → Rule Engine Triggered → Action Executed
🔷 Mermaid Sequence Diagram

``` mermaid
sequenceDiagram
    autonumber

    participant Student
    participant UI as LMS UI
    participant QuizSvc as QuizAttemptService
    participant RED as RuleEngineDispatcher
    participant RDB as RuleEngine DB
    participant Eval as RuleEvaluator
    participant Act as ActionExecutor
    participant LP as LessonPlanService
    participant Log as RuleExecutionLog

    Student ->> UI: Submit Quiz
    UI ->> QuizSvc: submitAttempt()

    QuizSvc ->> QuizSvc: Save Quiz Attempt
    QuizSvc ->> RED: trigger(ON_QUIZ_COMPLETION, context)

    RED ->> RDB: Load Trigger Event
    RED ->> RDB: Load Active Rules (ordered by priority)

    loop For each Rule
        RED ->> Eval: evaluate(rule, context)

        Eval ->> Eval: Validate Conditions (logic_config)

        alt Rule Matched
            Eval ->> Act: execute(action, context)
            Act ->> LP: Assign Remedial Lesson
            Act ->> Log: Insert SUCCESS log
        else Rule Skipped
            Eval ->> Log: Insert SKIPPED log
        end
    end

    QuizSvc ->> UI: Submission Success
```

🧠 What This Diagram Proves

✔ Rules are not hardcoded
✔ Multiple rules can execute
✔ Priority respected
✔ Logs written for every decision
✔ Action execution is decoupled

## SCENARIO 2
Homework Overdue (Cron Job → Rule Engine)

``` mermaid
sequenceDiagram
    autonumber

    participant Cron as Scheduler
    participant HW as HomeworkService
    participant RED as RuleEngineDispatcher
    participant Eval as RuleEvaluator
    participant Act as ActionExecutor
    participant Notify as NotificationService
    participant Log as RuleExecutionLog

    Cron ->> HW: checkOverdueHomework()

    HW ->> HW: Identify Overdue Records

    loop Each Student Homework
        HW ->> RED: trigger(ON_HOMEWORK_OVERDUE, context)

        RED ->> Eval: evaluate(rule, context)

        alt Rule Matched
            Eval ->> Act: execute(NOTIFY_PARENT)
            Act ->> Notify: Send Parent Alert
            Act ->> Log: SUCCESS
        else Rule Skipped
            Eval ->> Log: SKIPPED
        end
    end
```

## SCENARIO 3
Multiple Actions + Stop Further Execution

``` mermaid
sequenceDiagram
    autonumber

    participant RED as RuleEngineDispatcher
    participant Eval as RuleEvaluator
    participant Act as ActionExecutor
    participant Log as RuleExecutionLog

    RED ->> Eval: evaluate(Rule A)

    Eval ->> Act: Action 1
    Eval ->> Act: Action 2
    Eval ->> Log: SUCCESS

    alt stop_further_execution = true
        RED ->> RED: STOP rule loop
    else
        RED ->> Eval: evaluate(Rule B)
    end
```




