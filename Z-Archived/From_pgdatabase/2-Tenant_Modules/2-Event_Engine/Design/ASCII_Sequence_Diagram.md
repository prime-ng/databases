# ASCII SEQUENCE DIAGRAM (Quick Review Friendly)

## Quiz Completion Flow

``` lua
Student
   |
   v
[QuizAttemptService]
   |
   |-- save attempt
   |
   |-- trigger(ON_QUIZ_COMPLETION)
          |
          v
   [RuleEngineDispatcher]
          |
          |-- load rules (priority ASC)
          |
          v
   [RuleEvaluator]
          |
          |-- condition match?
          |
        YES
          |
          v
   [ActionExecutor]
          |
          |-- Assign Remedial
          |-- Notify Parent
          |
          v
   [RuleExecutionLog]



┌──────────┐     ┌──────────┐      ┌─────────────┐     ┌─────────────┐
│  Student │─────│   LMS UI │──────│ QuizAttempt │     │ RuleEngine  │
└──────────┘     └──────────┘      │  Service    │     │ Dispatcher  │
                                   └─────────────┘     └─────────────┘
                                         │                   │
                                         ▼                   ▼
                                   ┌─────────────┐     ┌─────────────┐
                                   │ RuleEngine  │     │ RuleEngine  │
                                   │   DB        │     │ Evaluator   │
                                   └─────────────┘     └─────────────┘
                                         │                   │
                                         ▼                   ▼
                                   ┌─────────────┐     ┌──────────────┐
                                   │ Action      │     │ RuleExecution│
                                   │ Executor    │     │   Log        │
                                   └─────────────┘     └──────────────┘





## Homework Overdue (Cron)

```lua
[Scheduler]
     |
     v
[HomeworkService]
     |
     |-- find overdue
     |
     v
[RuleEngineDispatcher]
     |
     v
[RuleEvaluator]
     |
   MATCH
     |
     v
[ActionExecutor] --> Notify Parent
     |
     v
[Execution Log]
```





