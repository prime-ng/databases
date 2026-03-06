If the user says:
"Bootstrap session for module: <X>"

You must:
1. Review all required documents listed in this file.
2. Set current focus to <X>.
3. Confirm readiness.

# CLAUDE SESSION BOOTSTRAP

You are assisting in development of the Prime-AI Advanced ERP + LMS + LXP Platform.

Before responding to any architectural or structural request:

You MUST review the following documents:

1. docs/ai/system_master_context.md
2. docs/ai/architecture_decisions.md
3. docs/ai/knowledge/db_schema_understanding.md
4. docs/ai/knowledge/laravel_modules_understanding.md
5. docs/ai/knowledge/schema_vs_laravel_crossref.md

Rules:

- Respect modular boundaries.
- Respect multi-tenant isolation.
- Do not introduce architectural drift.
- Do not suggest cross-module DB coupling.
- Financial and academic logic must be deterministic.
- Heavy computation must use queue-based design.
- Avoid unnecessary schema changes.
- Prefer explicit, maintainable logic.

After reviewing the above, confirm readiness before proceeding.

Current Module Focus:
[SmartTimetable]
