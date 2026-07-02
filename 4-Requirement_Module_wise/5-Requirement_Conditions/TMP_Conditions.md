# TMP — Requirement Conditions Catalog
**Module:** Template Management | **Code:** TMP | **Date:** 2026-06-30
**Source:** `TMP_FRD_Complete_2026-06-30.md` Section 2.1 (canonical copy)
**BR-IDs reuse FRD numbering — no parallel numbering.**

| Condition ID | Entity / Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-TMP-001 | Template / is_active | Template must have ≥ 1 mapped variable before is_active can be set to true | Validation | Template save or toggle-status to active | Return error: "The template must have at least one mapped variable before activation." |
| BR-TMP-002 | Template / code | Machine code must be unique across all templates including trashed records | Validation | Template create / update | Return error: "The template code has already been taken." |
| BR-TMP-003 | Template Category / name | Category name must be unique (case-insensitive) | Validation | Category create / update | Return error: "The template type name has already been taken." |
| BR-TMP-004 | Template Category / delete | Category cannot be deleted (soft or hard) if any template uses it (active or trashed) | Workflow | Category destroy / forceDelete | Return error: "Cannot delete template type because it is being used by one or more templates." |
| BR-TMP-005 | Template Category / delete (seeded) | The six seeded template categories are permanently protected from deletion | Permission | Category destroy / forceDelete | Return error: "System protected template types cannot be deleted." |
| BR-TMP-006 | Template Purpose / code | Purpose code must be unique across all purposes | Validation | Purpose create | Return error: "The purpose code has already been taken." |
| BR-TMP-007a | Template Purpose / code (system) | A system purpose's code cannot be changed via update | Permission | Purpose update | Return error: "System protected purposes cannot be modified." |
| BR-TMP-007b | Template Purpose / scope_type (system) | A system purpose's scope type cannot be changed via update | Permission | Purpose update | Return error: "System protected purposes cannot be modified." |
| BR-TMP-007c | Template Purpose / delete (system) | System purposes cannot be soft-deleted or hard-deleted | Permission | Purpose destroy / forceDelete | Return error: "System protected purposes cannot be modified or deleted." |
| BR-TMP-008 | Template Purpose / delete cascade | Soft-deleting a custom purpose sets all related scope assignments to is_active=0 | Workflow | Purpose soft-delete (destroy) | Cascade: all related tmp_template_assignments.is_active = 0 |
| BR-TMP-009 | Template Variable / name | Variable name must match pattern [a-z0-9_] — no uppercase, spaces, or other characters | Validation | Variable create / update | Return error: "The variable name must contain only lowercase alphanumeric characters and underscores." |
| BR-TMP-010 | Template Variable / table_name + field_name | Source table and source column must be both provided or both empty (partial mapping invalid) | Validation | Variable create / update | Return error: "Both source table and source column are required to configure database auto-resolution." |
| BR-TMP-011 | Template Variable / delete cascade | Deleting a variable (soft or hard) removes all junction records linking it to templates | Workflow | Variable destroy | DB CASCADE ON DELETE removes all rows in tmp_templates_variables_jnt referencing the variable |
| BR-TMP-012 | Scope Assignment / class_id + class_group_id | Cannot both be non-null simultaneously | Validation | Assignment create / update | Return error: "An assignment cannot target both a class and a class group simultaneously." |
| BR-TMP-013 | Scope Assignment / scope_hash | The combination purpose + academic_session + scope_target must be unique | Concurrency | Assignment create / update | Return error: "An active template assignment already exists for this scope." |
| BR-TMP-014 | Scope Assignment / class or group on SCHOOL_WIDE purpose | A School-Wide purpose must not have class_id or class_group_id set in its assignment | Validation | Assignment create / update | Return error: "A school-wide purpose cannot be assigned to a specific class or class group." |
| BR-TMP-015 | Engine / resolveTemplate | Resolution follows Direct Class → Class Group → School-Wide fallback chain; no match raises exception | Workflow | Any render() or toPdf() call | Raise TemplateNotFoundException::forPurpose($purposeCode) |
| BR-TMP-016 | Template / soft-delete cascade | Soft-deleting a template sets all its scope assignments to is_active=0 | Workflow | Template soft-delete (destroy) | Cascade: all related tmp_template_assignments.is_active = 0 |
| BR-TMP-017 | Template / force-delete | A template cannot be hard-deleted while active scope assignments reference it | Workflow | Template forceDelete | Return error: "Cannot permanently delete a template that is linked to active scope assignments." |
| BR-TMP-018a | Background Image / mimes | Must be JPEG or PNG format | Validation | Background image upload endpoint | Return error: "The image must be a file of type: jpg, jpeg, png." |
| BR-TMP-018b | Background Image / size | Must not exceed 2 MB (2048 KB) | Validation | Background image upload endpoint | Return error: "The image may not be greater than 2048 kilobytes." |
| BR-TMP-019 | Engine / data merge | Caller-supplied data overrides provider-supplied data when keys collide | Calculation | render() call — array_merge | array_merge($providerData, $data): caller wins on key collision |
| BR-TMP-020a | Engine / text output type | Text-type variable values are HTML-escaped before substitution | Calculation | formatVariableValue('text', ...) | Apply e($raw) — prevents XSS from automated DB values |
| BR-TMP-020b | Engine / html output type | Rich-HTML-type variable values are trusted pass-through (not escaped) | Calculation | formatVariableValue('html', ...) | $raw returned unmodified — only use with system-controlled source tables |
| BR-TMP-020c | Engine / image output type | Image-type variable values are rendered as HTML img elements | Calculation | formatVariableValue('image', ...) | Produce `<img src="{escaped_url}" alt="{name}" class="tpl-img tpl-img-{name}">` |
| BR-TMP-021 | Template Variable / name (uniqueness scope) | Variable name must be unique within its template category | Validation | Variable create | Return error: "The variable name has already been taken for this template type." |
