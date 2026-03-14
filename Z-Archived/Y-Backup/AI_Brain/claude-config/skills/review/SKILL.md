---
name: review
description: Code review for security, tenancy, performance, and style issues
user_invocable: true
---

# /review — Code Review

Perform a structured code review checking for security, tenancy, performance, and code quality.

## Usage
- `/review` — Review staged git changes
- `/review path/to/file` — Review a specific file
- `/review Modules/ModuleName/` — Review all changes in a module directory

## Review Checklist

### 1. Security (Critical)
- [ ] No `$request->all()` — must use `$request->validated()`
- [ ] No sensitive fields in `$fillable` (`is_super_admin`, `password`, etc.)
- [ ] No raw SQL with user input — use parameterized queries
- [ ] `{{ }}` in Blade (not `{!! !!}` unless trusted HTML)
- [ ] `@csrf` on all forms
- [ ] Webhook routes outside auth middleware
- [ ] No `dd()`, `dump()`, or debug routes in production code

### 2. Tenancy (Critical)
- [ ] No cross-tenant data access
- [ ] Queries scoped to current tenant context
- [ ] Central models accessed via `tenancy()->central(fn() => ...)`
- [ ] Migrations in correct path (central vs tenant)
- [ ] Cache keys prefixed with tenant ID

### 3. Performance
- [ ] No N+1 queries — eager load relationships with `->with()`
- [ ] No `Model::all()` — use `->select()` + `->paginate()`
- [ ] No `updateOrCreate` in loops — use `DB::upsert()`
- [ ] Caching for dropdown/reference data

### 4. Code Quality
- [ ] Thin controllers — business logic in Services
- [ ] Form Requests for validation
- [ ] PSR-12 code style
- [ ] SoftDeletes on all models

## Output Format
```
## Critical Issues (Must Fix)
- [SEC-xxx] Description — file:line

## Suggestions (Should Fix)
- [PERF-xxx] Description — file:line

## Good Patterns
- Description
```
