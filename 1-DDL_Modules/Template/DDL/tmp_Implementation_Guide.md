# TMP — Template Module Implementation Guide

> **Module**: Template (`Modules\Template`)
> **DDL File**: `tmp_Config_DDL_v5.sql`
> **Version**: 5.0 — April 2026
> **Database**: `tenant_db` (one per tenant, no tenant_id columns)

---

## 1. MODULE OVERVIEW

The Template module provides a centralized system for creating, managing, and assigning
visual templates across the school ERP. Templates are categorized by type (e.g., Marksheet,
ID Card), contain draggable UI elements stored as JSON, and are assigned to functional
purposes at various scope levels (class, class-group, or school-wide).

### Architecture Layers

```
+---------------------------+
|     LOOKUP TABLES         |
|  +-----------------------+|      sys_dropdown_table
|  | tmp_templates_type    ||           |
|  | tmp_template_purposes |<-----------+  (scope_type_id)
|  +-----------------------+|
+-------------+-------------+
              |
              | type_id
              v
+---------------------------+
|     TEMPLATE DESIGN       |
|  +-----------------------+|
|  | tmp_templates         ||
|  | tmp_template_variables||
|  | tmp_templates_        ||
|  |   variables_jnt       ||
|  +-----------------------+|
+-------------+-------------+
              |
              | template_id, purpose_id
              v
+---------------------------+
|     TEMPLATE ASSIGNMENT   |
|  +-----------------------+|
|  | tmp_template_         ||---> sch_classes
|  |   assignments         ||---> sch_org_academic_sessions_jnt
|  +-----------------------+||---> msh_class_groups
+---------------------------+
```

---

## 2. ENTITY RELATIONSHIP DIAGRAM

```
sys_dropdown_table                      tmp_templates_type
        |                                   |             |
        | scope_type_id                     | type_id     | type_id
        v                                   v             v
tmp_template_purposes              tmp_templates    tmp_template_variables
        |                               |                   |
        | purpose_id                    | template_id       | variable_id
        |                               |                   |
        |                               v                   v
        |                        tmp_templates_variables_jnt
        |
        v
tmp_template_assignments
        |
        +-- template_id -----------> tmp_templates
        +-- academic_session_id ---> sch_org_academic_sessions_jnt
        +-- class_id --------------> sch_classes
        +-- class_group_id --------> msh_class_groups
```

---

## 3. TABLE SUMMARY

| #  | Table Name                     | Section    | Purpose                              | Row Volume                |
|----|--------------------------------|------------|--------------------------------------|---------------------------|
| 1  | `tmp_templates_type`           | Lookup     | Template categories                  | ~5-10 per school          |
| 2  | `tmp_template_purposes`        | Lookup     | Functional purposes for assignment   | ~7-10 (7 seeded + custom) |
| 3  | `tmp_templates`                | Design     | Template definitions (canvas + HTML) | ~5-20 per school          |
| 4  | `tmp_template_variables`       | Design     | Reusable variables per type          | ~10-30 per type           |
| 5  | `tmp_templates_variables_jnt`  | Design     | Template <-> variable mapping        | ~50-200 per school        |
| 6  | `tmp_template_assignments`     | Assignment | Template -> purpose at scope         | ~10-30 / school / session |

**Total: 6 tables**

### Column-Level Summary

#### tmp_templates_type
| Column        | Type             | Nullable | Default | Key     | Notes                       |
|---------------|------------------|----------|---------|---------|-----------------------------|
| id            | INT UNSIGNED     | NO       | AUTO    | PK      |                             |
| name          | VARCHAR(30)      | NO       |         | UNIQUE  | e.g. MARKSHEET              |
| description   | VARCHAR(255)     | YES      | NULL    |         |                             |
| is_active     | TINYINT(1)       | NO       | 0       | INDEX   |                             |
| created_at    | TIMESTAMP        | YES      | NULL    |         |                             |
| updated_at    | TIMESTAMP        | YES      | NULL    |         |                             |
| deleted_at    | TIMESTAMP        | YES      | NULL    |         | Soft delete                 |

#### tmp_template_purposes
| Column        | Type             | Nullable | Default      | Key     | Notes                     |
|---------------|------------------|----------|--------------|---------|---------------------------|
| id            | INT UNSIGNED     | NO       | AUTO         | PK      |                           |
| code          | VARCHAR(30)      | NO       |              | UNIQUE  | e.g. MARKSHEET_PRINT      |
| name          | VARCHAR(100)     | NO       |              |         | Display name              |
| description   | VARCHAR(255)     | YES      | NULL         |         |                           |
| scope_type_id | INT UNSIGNED     | NO       |              | FK, IDX | -> sys_dropdown_table.id  |
| display_order | SMALLINT UNSIGNED| NO       | 1            |         | UI sort order             |
| is_system     | TINYINT(1)       | NO       | 0            |         | 1 = seeded                |
| is_active     | TINYINT(1)       | NO       | 1            | INDEX   |                           |
| created_at    | TIMESTAMP        | YES      | CURRENT_TS   |         |                           |
| updated_at    | TIMESTAMP        | YES      | ON UPDATE    |         |                           |
| deleted_at    | TIMESTAMP        | YES      | NULL         |         | Soft delete               |

#### tmp_templates
| Column           | Type             | Nullable | Default | Key     | Notes                     |
|------------------|------------------|----------|---------|---------|---------------------------|
| id               | INT UNSIGNED     | NO       | AUTO    | PK      |                           |
| code             | VARCHAR(50)      | NO       |         | UNIQUE  | Machine-readable code     |
| name             | VARCHAR(100)     | NO       |         |         | Display name              |
| type_id          | INT UNSIGNED     | YES      | NULL    | FK, IDX | -> tmp_templates_type.id  |
| description      | TEXT             | YES      | NULL    |         |                           |
| canvas_json      | JSON             | YES      | NULL    |         | Drag-drop layout data     |
| html_content     | LONGTEXT         | YES      | NULL    |         | Rendered HTML             |
| background_image | VARCHAR(255)     | YES      | NULL    |         | Image URL/path            |
| is_active        | TINYINT(1)       | NO       | 0       | INDEX   | 0=draft, 1=active         |
| created_at       | TIMESTAMP        | YES      | NULL    |         |                           |
| updated_at       | TIMESTAMP        | YES      | NULL    |         |                           |
| deleted_at       | TIMESTAMP        | YES      | NULL    | INDEX   | Soft delete               |

#### tmp_template_variables
| Column      | Type             | Nullable | Default | Key     | Notes                          |
|-------------|------------------|----------|---------|---------|--------------------------------|
| id          | INT UNSIGNED     | NO       | AUTO    | PK      |                                |
| type_id     | INT UNSIGNED     | NO       |         | FK, IDX | -> tmp_templates_type.id       |
| name        | VARCHAR(50)      | NO       |         | UQ      | Unique per type                |
| description | VARCHAR(255)     | YES      | NULL    |         |                                |
| db_name     | VARCHAR(60)      | YES      | NULL    |         | Source DB for auto-resolution  |
| table_name  | VARCHAR(60)      | YES      | NULL    |         | Source table                   |
| field_name  | VARCHAR(60)      | YES      | NULL    |         | Source column                  |
| is_active   | TINYINT(1)       | NO       | 1       | INDEX   |                                |
| created_at  | TIMESTAMP        | YES      | NULL    |         |                                |
| updated_at  | TIMESTAMP        | YES      | NULL    |         |                                |
| deleted_at  | TIMESTAMP        | YES      | NULL    | INDEX   | Soft delete                    |

#### tmp_templates_variables_jnt
| Column        | Type             | Nullable | Default | Key     | Notes                       |
|---------------|------------------|----------|---------|---------|-----------------------------|
| id            | INT UNSIGNED     | NO       | AUTO    | PK      |                             |
| template_id   | INT UNSIGNED     | NO       |         | FK, UQ  | -> tmp_templates.id         |
| variable_id   | INT UNSIGNED     | NO       |         | FK, UQ  | -> tmp_template_variables.id|
| display_order | SMALLINT UNSIGNED| NO       | 0       |         | Render order in template    |
| default_value | VARCHAR(255)     | YES      | NULL    |         | Fallback if NULL            |
| is_active     | TINYINT(1)       | NO       | 1       | INDEX   |                             |
| created_at    | TIMESTAMP        | YES      | NULL    |         |                             |
| updated_at    | TIMESTAMP        | YES      | NULL    |         |                             |
| deleted_at    | TIMESTAMP        | YES      | NULL    |         | Soft delete                 |

#### tmp_template_assignments
| Column              | Type              | Nullable | Default      | Key     | Notes                            |
|---------------------|-------------------|----------|--------------|---------|----------------------------------|
| id                  | INT UNSIGNED      | NO       | AUTO         | PK      |                                  |
| template_id         | INT UNSIGNED      | NO       |              | FK, IDX | -> tmp_templates.id              |
| purpose_id          | INT UNSIGNED      | NO       |              | FK, IDX | -> tmp_template_purposes.id      |
| academic_session_id | SMALLINT UNSIGNED | NO       |              | FK, IDX | -> sch_org_academic_sessions_jnt |
| class_id            | INT UNSIGNED      | YES      | NULL         | FK, IDX | -> sch_classes.id                |
| class_group_id      | INT UNSIGNED      | YES      | NULL         | FK, IDX | -> msh_class_groups.id           |
| scope_hash          | VARCHAR(80)       | --       | GENERATED    | UNIQUE  | Stored generated column          |
| is_active           | TINYINT(1)        | NO       | 1            | INDEX   |                                  |
| created_at          | TIMESTAMP         | YES      | CURRENT_TS   |         |                                  |
| updated_at          | TIMESTAMP         | YES      | ON UPDATE    |         |                                  |
| deleted_at          | TIMESTAMP         | YES      | NULL         |         | Soft delete                      |

---

## 4. SEED DATA

### 4.1 Scope Types (sys_dropdown_table)

Seed these **before** creating any `tmp_template_purposes` rows.

```sql
-- -----------------------------------------------------------------
-- Seed: sys_dropdown_table -- scope types for tmp_template_purposes
-- Key: tmp_template_purposes.scope_type_id
-- -----------------------------------------------------------------
-- CLASS_SCOPED: Supports class-level, class-group, AND school-wide
--              targeting. UI shows class/group selectors.
-- SCHOOL_WIDE: Only supports school-wide targeting.
--              UI hides class/group selectors; both are always NULL.
-- -----------------------------------------------------------------
INSERT INTO `sys_dropdown_table` (`ordinal`, `key`, `value`, `type`, `additional_info`, `is_active`)
VALUES
  (1, 'tmp_template_purposes.scope_type_id', 'CLASS_SCOPED', 'String',
    '{"description": "Supports class-level, class-group, and school-wide scoping"}', 1),
  (2, 'tmp_template_purposes.scope_type_id', 'SCHOOL_WIDE', 'String',
    '{"description": "School-wide only -- no class or class-group targeting"}', 1);
```

### 4.2 Template Types (tmp_templates_type)

```sql
INSERT INTO `tmp_templates_type` (`name`, `description`, `is_active`)
VALUES
  ('MARKSHEET',       'Marksheet / Report Card templates',       1),
  ('STUDENT_ID_CARD', 'Student identity card templates',         1),
  ('STAFF_ID_CARD',   'Staff/teacher identity card templates',   1),
  ('CERTIFICATE',     'Certificate templates (TC, character)',   1),
  ('ADMIT_CARD',      'Exam admit card templates',               1),
  ('FEE_RECEIPT',     'Fee receipt templates',                   1);
```

### 4.3 Template Purposes (tmp_template_purposes)

```sql
-- Requires scope_type_id from sys_dropdown_table.
-- Resolve IDs dynamically:

SET @class_scoped = (SELECT id FROM sys_dropdown_table
    WHERE `key` = 'tmp_template_purposes.scope_type_id'
      AND `value` = 'CLASS_SCOPED' LIMIT 1);

SET @school_wide = (SELECT id FROM sys_dropdown_table
    WHERE `key` = 'tmp_template_purposes.scope_type_id'
      AND `value` = 'SCHOOL_WIDE' LIMIT 1);

INSERT INTO `tmp_template_purposes`
  (`code`, `name`, `description`, `scope_type_id`, `display_order`, `is_system`)
VALUES
  ('MARKSHEET_PRINT', 'Marksheet Printing',     'PDF layout for student marksheets',  @class_scoped, 1, 1),
  ('STUDENT_ID_CARD', 'Student ID Card',        'Student identity card layout',       @class_scoped, 2, 1),
  ('STAFF_ID_CARD',   'Staff ID Card',          'Staff/teacher identity card layout', @school_wide,  3, 1),
  ('TRANSFER_CERT',   'Transfer Certificate',   'TC document layout',                @class_scoped, 4, 1),
  ('CHARACTER_CERT',  'Character Certificate',  'Character certificate layout',       @school_wide,  5, 1),
  ('ADMIT_CARD',      'Exam Admit Card',        'Exam admit card layout',             @class_scoped, 6, 1),
  ('FEE_RECEIPT',     'Fee Receipt',            'Fee receipt layout',                 @school_wide,  7, 1);
```

---

## 5. TEMPLATE RESOLUTION LOGIC

### 5.1 Resolution Priority (CLASS_SCOPED purposes)

For CLASS_SCOPED purposes (e.g., MARKSHEET_PRINT), the system resolves the template
using a **3-step fallback chain**:

```
+------------------------------------------+
|  Input: @purpose_code, @session_id,      |
|         @class_id                        |
+-----------------+------------------------+
                  |
         +--------v---------+
         | Step 1: Direct   |     class_id = @class_id
         | Class Match      |---- FOUND ----> return template_id
         | (highest priority|
         +--------+---------+
                  | NOT FOUND
         +--------v---------+
         | Step 2: Class    |     class_group containing @class_id
         | Group Match      |---- FOUND ----> return template_id
         | (fallback)       |
         +--------+---------+
                  | NOT FOUND
         +--------v---------+
         | Step 3: School-  |     class_id IS NULL AND
         | Wide Fallback    |---- class_group_id IS NULL
         |                  |---- FOUND ----> return template_id
         +--------+---------+
                  | NOT FOUND
         +--------v---------+
         | Step 4: ERROR    |
         | No template      |
         | configured       |
         +------------------+
```

### 5.2 SQL Queries

**Step 1 -- Direct class match (highest priority):**

```sql
SELECT ta.template_id
FROM tmp_template_assignments ta
JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id
WHERE tp.code = @purpose_code
  AND ta.academic_session_id = @session_id
  AND ta.class_id = @class_id
  AND ta.is_active = 1
  AND ta.deleted_at IS NULL;
```

**Step 2 -- Class group match (fallback):**

```sql
SELECT ta.template_id
FROM tmp_template_assignments ta
JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id
JOIN msh_class_group_items_jnt cgi ON cgi.class_group_id = ta.class_group_id
WHERE tp.code = @purpose_code
  AND ta.academic_session_id = @session_id
  AND cgi.class_id = @class_id
  AND ta.class_id IS NULL
  AND ta.is_active = 1
  AND ta.deleted_at IS NULL
  AND cgi.is_active = 1
  AND cgi.deleted_at IS NULL;
```

**Step 3 -- School-wide fallback:**

```sql
SELECT ta.template_id
FROM tmp_template_assignments ta
JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id
WHERE tp.code = @purpose_code
  AND ta.academic_session_id = @session_id
  AND ta.class_id IS NULL
  AND ta.class_group_id IS NULL
  AND ta.is_active = 1
  AND ta.deleted_at IS NULL;
```

### 5.3 SCHOOL_WIDE Purposes

For SCHOOL_WIDE purposes (e.g., STAFF_ID_CARD, FEE_RECEIPT), only **Step 3** applies.
`class_id` and `class_group_id` are always NULL.

### 5.4 Combined Query (Single query with COALESCE for performance)

```sql
-- Resolves template in one query using priority ordering
SELECT ta.template_id
FROM tmp_template_assignments ta
JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id
LEFT JOIN msh_class_group_items_jnt cgi
    ON cgi.class_group_id = ta.class_group_id
    AND cgi.class_id = @class_id
    AND cgi.is_active = 1
    AND cgi.deleted_at IS NULL
WHERE tp.code = @purpose_code
  AND ta.academic_session_id = @session_id
  AND ta.is_active = 1
  AND ta.deleted_at IS NULL
  AND (
      ta.class_id = @class_id                               -- Priority 1: direct class
      OR (ta.class_id IS NULL AND cgi.id IS NOT NULL)        -- Priority 2: class group
      OR (ta.class_id IS NULL AND ta.class_group_id IS NULL) -- Priority 3: school-wide
  )
ORDER BY
    CASE
        WHEN ta.class_id = @class_id THEN 1
        WHEN ta.class_id IS NULL AND cgi.id IS NOT NULL THEN 2
        ELSE 3
    END
LIMIT 1;
```

### 5.5 Cross-Module Integration (Marksheet)

At marksheet generation time, the system resolves **two independent** configurations:

| Source                                              | Module   | Provides                                               |
|-----------------------------------------------------|----------|--------------------------------------------------------|
| `msh_config_templates` (via `msh_class_config_jnt`) | MSG      | Computation rules (weightages, grading, pass criteria) |
| `tmp_template_assignments`                          | Template | Visual layout (PDF template with canvas/HTML)          |

These are **NOT FK-coupled**. They are combined at render time by the service layer.

---

## 6. VARIABLE RESOLUTION MAP

Template variables provide placeholders that auto-resolve to database values at render time.

### 6.1 How It Works

```
Template Canvas/HTML                     Database
---------------------                    --------
{{student_name}}      ---resolve--->     students.full_name
{{class_name}}        ---resolve--->     sch_classes.name
{{total_marks}}       ---manual--->      (computed by MSG module)
{{school_logo}}       ---resolve--->     sch_schools.logo_path
```

### 6.2 Resolution Using Variable Metadata

Each variable in `tmp_template_variables` can specify source mapping:

| Column       | Purpose                        | Example                  |
|--------------|--------------------------------|--------------------------|
| `db_name`    | Source database                | `tenant_db`              |
| `table_name` | Source table                   | `std_students`           |
| `field_name` | Source column                  | `full_name`              |

**Two resolution modes:**

| Mode       | When                                    | Resolved By                |
|------------|-----------------------------------------|----------------------------|
| **Auto**   | `table_name` AND `field_name` are set   | Template engine queries DB |
| **Manual** | `table_name` OR `field_name` is NULL    | Calling module passes value|

### 6.3 Service Layer Pseudo-Code

```php
public function resolveVariables(Template $template, array $context): string
{
    $html = $template->html_content;

    foreach ($template->variables as $variable) {
        if ($variable->table_name && $variable->field_name) {
            // Auto-resolve from database
            $value = DB::connection($variable->db_name ?? 'tenant')
                ->table($variable->table_name)
                ->where('id', $context['entity_id'])
                ->value($variable->field_name);
        } else {
            // Manual resolution -- value passed by calling module
            $value = $context[$variable->name]
                  ?? $variable->pivot->default_value
                  ?? '';
        }

        $html = str_replace('{{' . $variable->name . '}}', $value, $html);
    }

    return $html;
}
```

### 6.4 Example Variable Definitions (MARKSHEET type)

| Variable Name     | table_name              | field_name        | Resolution |
|-------------------|-------------------------|-------------------|------------|
| `student_name`    | `std_students`              | `full_name`       | Auto       |
| `father_name`     | `std_students`              | `father_name`     | Auto       |
| `class_name`      | `sch_classes`           | `name`            | Auto       |
| `section_name`    | `sch_sections`          | `name`            | Auto       |
| `roll_number`     | `std_students`              | `roll_number`     | Auto       |
| `total_marks`     | NULL                    | NULL              | Manual     |
| `grade`           | NULL                    | NULL              | Manual     |
| `result_status`   | NULL                    | NULL              | Manual     |
| `school_name`     | `sch_schools`           | `name`            | Auto       |
| `school_logo`     | `sch_schools`           | `logo_path`       | Auto       |

> Variables with NULL `table_name`/`field_name` are resolved manually by the calling
> module (e.g., MSG computes `total_marks` and passes it to the template renderer).

---

## 7. MIGRATION DEPENDENCY ORDER

### 7.1 File Sequence

Migrations path: `database/migrations/tenant/`

| Order | Migration File                                                     | Creates                         | Depends On                                                              |
|-------|--------------------------------------------------------------------|---------------------------------|-------------------------------------------------------------------------|
| 1     | `2026_04_16_000001_create_tmp_templates_type_table.php`            | `tmp_templates_type`            | _(none)_                                                                |
| 2     | `2026_04_16_000002_create_tmp_template_purposes_table.php`         | `tmp_template_purposes`         | `sys_dropdown_table`                                                    |
| 3     | `2026_04_16_000003_create_tmp_templates_table.php`                 | `tmp_templates`                 | `tmp_templates_type`                                                    |
| 4     | `2026_04_16_000004_create_tmp_template_variables_table.php`        | `tmp_template_variables`        | `tmp_templates_type`                                                    |
| 5     | `2026_04_16_000005_create_tmp_templates_variables_jnt_table.php`   | `tmp_templates_variables_jnt`   | `tmp_templates`, `tmp_template_variables`                               |
| 6     | `2026_04_16_000006_create_tmp_template_assignments_table.php`      | `tmp_template_assignments`      | `tmp_templates`, `tmp_template_purposes`, `sch_org_academic_sessions_jnt`, `sch_classes`, `msh_class_groups` |

### 7.2 Seeder

| Seeder File                | Seeds                                                              | Run After          |
|----------------------------|--------------------------------------------------------------------|--------------------|
| `TemplateConfigSeeder.php` | `sys_dropdown_table` (scope types), `tmp_templates_type`, `tmp_template_purposes` | Migrations 1-2     |

### 7.3 Dependency Graph

```
sys_dropdown_table (exists)        tmp_templates_type
        |                                |            |
        v                                v            v
tmp_template_purposes           tmp_templates   tmp_template_variables
        |                            |                |
        |                            +--------+-------+
        |                                     v
        |                      tmp_templates_variables_jnt
        |                            |
        +----------------------------+
                                     v
                          tmp_template_assignments
                                     |
                    +----------------+----------------+
                    v                v                v
              sch_classes    sch_org_academic_   msh_class_groups
                             sessions_jnt
```

### 7.4 Rollback Order

Reverse of creation. Drop in this sequence to avoid FK violations:

```
1. tmp_template_assignments
2. tmp_templates_variables_jnt
3. tmp_template_variables
4. tmp_templates
5. tmp_template_purposes
6. tmp_templates_type
7. DELETE FROM sys_dropdown_table WHERE `key` = 'tmp_template_purposes.scope_type_id'
```

---

## 8. VALIDATION RULES

Business rules to enforce in the service layer / Form Requests:

| Rule                                              | Enforcement     | Details                                              |
|---------------------------------------------------|-----------------|------------------------------------------------------|
| Template code is unique                           | DB (UNIQUE KEY) | `uq_tmp_tpl_code`                                   |
| One template per purpose + session + scope        | DB (UNIQUE KEY) | `uq_tmp_ta_scope` on `scope_hash`                   |
| Cannot set both `class_id` AND `class_group_id`   | DB (CHECK)      | `chk_tmp_ta_scope_target`                            |
| Variable name unique per type                     | DB (UNIQUE KEY) | `uq_tmp_tv_type_name`                               |
| Template-variable mapping unique per template     | DB (UNIQUE KEY) | `uq_tmp_tvj_tpl_var`                                |
| SCHOOL_WIDE purpose: class fields must be NULL    | Service Layer   | Validate before insert based on `scope_type`         |
| Template type should match purpose type           | Service Layer   | e.g., MARKSHEET template for MARKSHEET_PRINT purpose |
| Soft-delete cascading                             | Service Layer   | Deactivate assignments when template is soft-deleted |
| At least one variable mapped before activation    | Service Layer   | Template must have variables via junction table      |

---

## 9. LARAVEL MODEL HINTS

### 9.1 Relationships

```php
// TemplateType model (tmp_templates_type)
public function templates()    { return $this->hasMany(Template::class, 'type_id'); }
public function variables()    { return $this->hasMany(TemplateVariable::class, 'type_id'); }

// Template model (tmp_templates)
public function type()         { return $this->belongsTo(TemplateType::class, 'type_id'); }
public function variables()    {
    return $this->belongsToMany(TemplateVariable::class,
            'tmp_templates_variables_jnt', 'template_id', 'variable_id')
        ->withPivot('display_order', 'default_value', 'is_active')
        ->orderBy('tmp_templates_variables_jnt.display_order');
}
public function assignments()  { return $this->hasMany(TemplateAssignment::class, 'template_id'); }

// TemplateVariable model (tmp_template_variables)
public function type()         { return $this->belongsTo(TemplateType::class, 'type_id'); }
public function templates()    {
    return $this->belongsToMany(Template::class,
            'tmp_templates_variables_jnt', 'variable_id', 'template_id');
}

// TemplatePurpose model (tmp_template_purposes)
public function scopeType()    { return $this->belongsTo(SysDropdown::class, 'scope_type_id'); }
public function assignments()  { return $this->hasMany(TemplateAssignment::class, 'purpose_id'); }

// TemplateAssignment model (tmp_template_assignments)
public function template()     { return $this->belongsTo(Template::class, 'template_id'); }
public function purpose()      { return $this->belongsTo(TemplatePurpose::class, 'purpose_id'); }
public function session()      { return $this->belongsTo(AcademicSession::class, 'academic_session_id'); }
public function schClass()     { return $this->belongsTo(SchClass::class, 'class_id'); }
public function classGroup()   { return $this->belongsTo(ClassGroup::class, 'class_group_id'); }
```

### 9.2 Recommended Casts

```php
// Template model
protected $casts = [
    'canvas_json' => 'array',
    'is_active'   => 'boolean',
];

// TemplatePurpose model
protected $casts = [
    'is_system'  => 'boolean',
    'is_active'  => 'boolean',
];
```

### 9.3 Useful Scopes

```php
// Shared across models
public function scopeActive($query)
{
    return $query->where('is_active', 1)->whereNull('deleted_at');
}

// Template model
public function scopeOfType($query, string $typeName)
{
    return $query->whereHas('type', fn($q) => $q->where('name', $typeName));
}

// TemplateAssignment model -- resolve template for a class
public function scopeForPurpose($query, string $purposeCode, int $sessionId)
{
    return $query->whereHas('purpose', fn($q) => $q->where('code', $purposeCode))
        ->where('academic_session_id', $sessionId)
        ->active();
}

public function scopeForClass($query, int $classId)
{
    return $query->where('class_id', $classId);
}

public function scopeSchoolWide($query)
{
    return $query->whereNull('class_id')->whereNull('class_group_id');
}
```

---

## 10. CHANGELOG (v4 -> v5)

| #  | Change                                             | Impact                                               |
|----|----------------------------------------------------|------------------------------------------------------|
| 1  | Fixed table creation order                         | No forward FK references -- clean `migrate`          |
| 2  | `tmp_template_variables.template_id` -> `type_id`  | Variables scoped to type, not template -- enables reuse |
| 3  | Removed phantom `created_by`/`updated_by` indexes | Prevents migration failure                           |
| 4  | Fixed syntax errors in templates, junction table   | Clean DDL execution                                  |
| 5  | Added FKs + UNIQUE KEY to junction table           | Referential integrity enforced                       |
| 6  | Added `code` column to `tmp_templates`             | Machine-readable identifier separate from name       |
| 7  | Fixed `template_id` type mismatch in assignments   | `BIGINT` -> `INT UNSIGNED` matches PK                |
| 8  | Added `display_order`, `default_value` to junction | Richer template-variable configuration               |
| 9  | Extracted non-DDL sections to this guide           | Clean separation: schema vs implementation           |
