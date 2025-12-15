# TIMETABLE MODULE - PERMISSIONS MATRIX
## Document Version: 1.0
**Last Updated:** December 14, 2025

---

## OVERVIEW

This document defines the comprehensive Role-Based Access Control (RBAC) system for the Timetable Module, including permissions, roles, and access rules.

### Permission Categories

| Category | Description | Permissions |
|----------|-------------|-------------|
| **Timetable Management** | Core timetable operations | Create, Read, Update, Delete timetables |
| **Generation Control** | Auto-scheduler and generation | Generate, Stop, Pause, Resume |
| **Editing Permissions** | Manual editing capabilities | Edit cells, Drag-drop, Bulk edit |
| **Locking Control** | Protection and approval workflow | Lock, Unlock, Approve changes |
| **Substitution Management** | Teacher replacement workflow | Request, Assign, Approve substitutes |
| **Constraint Management** | Rule definition and enforcement | Create, Update, Delete constraints |
| **Reporting & Export** | Data access and reporting | Print, Export, Import, Analytics |

### Standard ERP Roles

| Role | Description | Access Level |
|------|-------------|--------------|
| **Super Admin** | System-wide administrator | Full access to all modules |
| **PG Support** | PrimeGurukul support staff | Full access for troubleshooting |
| **School Admin** | School administrator | Administrative access within school |
| **Principal** | School principal | Approval and oversight access |
| **Teacher** | Teaching staff | Limited access to own subjects/timetable |
| **Student** | Students | Read-only access to relevant timetables |
| **Parents** | Parents/Guardians | Read-only access to child's timetable |

---

## PERMISSIONS MATRIX

### 1. TIMETABLE MANAGEMENT PERMISSIONS

| Permission | Super Admin | PG Support | School Admin | Principal | Teacher | Student | Parents |
|------------|-------------|------------|--------------|-----------|---------|---------|---------|
| **Create Timetable** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Read Timetable** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Update Timetable** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Delete Timetable** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Publish Timetable** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Archive Timetable** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |

### 2. GENERATION CONTROL PERMISSIONS

| Permission | Super Admin | PG Support | School Admin | Principal | Teacher | Student | Parents |
|------------|-------------|------------|--------------|-----------|---------|---------|---------|
| **Start Generation** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Stop Generation** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Pause Generation** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Resume Generation** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **View Generation Logs** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Modify Generation Params** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |

### 3. EDITING PERMISSIONS

| Permission | Super Admin | PG Support | School Admin | Principal | Teacher | Student | Parents |
|------------|-------------|------------|--------------|-----------|---------|---------|---------|
| **Manual Cell Edit** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Drag & Drop Editing** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Bulk Cell Updates** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Undo/Redo Operations** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Edit Locked Cells** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |

### 4. LOCKING CONTROL PERMISSIONS

| Permission | Super Admin | PG Support | School Admin | Principal | Teacher | Student | Parents |
|------------|-------------|------------|--------------|-----------|---------|---------|---------|
| **Lock Timetable** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Unlock Timetable** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Lock Individual Cells** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Unlock Individual Cells** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Approve Changes** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Override Locks** | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |

### 5. SUBSTITUTION MANAGEMENT PERMISSIONS

| Permission | Super Admin | PG Support | School Admin | Principal | Teacher | Student | Parents |
|------------|-------------|------------|--------------|-----------|---------|---------|---------|
| **Request Substitution** | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| **Assign Substitute** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Approve Substitution** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Reject Substitution** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| **View Substitution History** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Rate Substitute Performance** | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |

### 6. CONSTRAINT MANAGEMENT PERMISSIONS

| Permission | Super Admin | PG Support | School Admin | Principal | Teacher | Student | Parents |
|------------|-------------|------------|--------------|-----------|---------|---------|---------|
| **Create Constraints** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Read Constraints** | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| **Update Constraints** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Delete Constraints** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Activate/Deactivate** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Test Constraints** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |

### 7. REPORTING & EXPORT PERMISSIONS

| Permission | Super Admin | PG Support | School Admin | Principal | Teacher | Student | Parents |
|------------|-------------|------------|--------------|-----------|---------|---------|---------|
| **Print Timetable** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Export PDF** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Export Excel** | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| **Export CSV** | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| **Import Timetable** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **View Analytics** | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |

---

## ROW-LEVEL SECURITY RULES

### 1. TEACHER-SPECIFIC ACCESS
```sql
-- Teachers can only view/edit their own subject periods
CREATE POLICY teacher_timetable_access ON tt_timetable_cell
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM tim_timetable_cell_teacher ttct
    WHERE ttct.cell_id = tt_timetable_cell.id
    AND ttct.teacher_id = current_user_id()
  )
);
```

### 2. STUDENT-SPECIFIC ACCESS
```sql
-- Students can only view their class timetable
CREATE POLICY student_timetable_access ON tt_timetable_cell
FOR SELECT USING (
  class_group_id IN (
    SELECT class_group_id FROM sch_class_groups_jnt
    WHERE class_id IN (
      SELECT class_id FROM std_student_class_history
      WHERE student_id = current_user_id()
      AND is_active = 1
    )
  )
);
```

### 3. PARENT-SPECIFIC ACCESS
```sql
-- Parents can only view their children's timetables
CREATE POLICY parent_timetable_access ON tt_timetable_cell
FOR SELECT USING (
  class_group_id IN (
    SELECT DISTINCT cg.class_group_id
    FROM sch_class_groups_jnt cg
    JOIN std_student_class_history sch ON cg.class_id = sch.class_id
    JOIN std_parent_student_jnt psj ON sch.student_id = psj.student_id
    WHERE psj.parent_id = current_user_id()
    AND sch.is_active = 1
  )
);
```

### 4. SCHOOL-SPECIFIC ISOLATION
```sql
-- All users are restricted to their own school
CREATE POLICY school_isolation ON tt_timetable_cell
FOR ALL USING (
  generation_run_id IN (
    SELECT id FROM tim_generation_run
    WHERE academic_session_id IN (
      SELECT id FROM sch_academic_sessions
      WHERE school_id = current_user_school_id()
    )
  )
);
```

---

## JWT TOKEN CLAIMS

### Standard JWT Payload Structure
```json
{
  "sub": "user_123",
  "school_id": 1,
  "roles": ["SCHOOL_ADMIN", "TIMETABLE_EDITOR"],
  "permissions": [
    "timetable:create",
    "timetable:generate",
    "timetable:edit",
    "constraint:manage"
  ],
  "iat": 1640995200,
  "exp": 1641081600
}
```

### Permission Claim Examples

**Super Admin:**
```json
{
  "permissions": [
    "timetable:*",
    "generation:*",
    "constraint:*",
    "substitution:*",
    "reporting:*"
  ]
}
```

**School Admin:**
```json
{
  "permissions": [
    "timetable:create",
    "timetable:read",
    "timetable:update",
    "timetable:publish",
    "generation:start",
    "generation:stop",
    "editing:manual",
    "editing:bulk",
    "locking:lock",
    "locking:unlock",
    "substitution:assign",
    "constraint:create",
    "constraint:update",
    "reporting:export"
  ]
}
```

**Teacher:**
```json
{
  "permissions": [
    "timetable:read",
    "substitution:request",
    "reporting:print",
    "reporting:export_pdf"
  ],
  "restrictions": {
    "own_subjects_only": true,
    "own_periods_only": true
  }
}
```

---

## API AUTHORIZATION MIDDLEWARE

### Laravel Policy Classes

**TimetablePolicy.php:**
```php
class TimetablePolicy
{
    public function create(User $user): bool
    {
        return $user->hasPermission('timetable:create');
    }

    public function update(User $user, TimetableCell $cell): bool
    {
        // Check basic permission
        if (!$user->hasPermission('timetable:update')) {
            return false;
        }

        // Check if cell is locked
        if ($cell->locked && !$user->hasPermission('locking:override')) {
            return false;
        }

        // Check school isolation
        if ($cell->school_id !== $user->school_id) {
            return false;
        }

        return true;
    }

    public function generate(User $user): bool
    {
        return $user->hasPermission('generation:start');
    }
}
```

**SubstitutionPolicy.php:**
```php
class SubstitutionPolicy
{
    public function assign(User $user, SubstitutionRequest $request): bool
    {
        // School admins and above can assign
        if ($user->hasRole(['SUPER_ADMIN', 'PG_SUPPORT', 'SCHOOL_ADMIN', 'PRINCIPAL'])) {
            return true;
        }

        // Teachers can only request, not assign
        return false;
    }

    public function request(User $user): bool
    {
        return $user->hasRole(['SUPER_ADMIN', 'PG_SUPPORT', 'SCHOOL_ADMIN', 'PRINCIPAL', 'TEACHER']);
    }
}
```

---

## DATABASE SCHEMA FOR RBAC

### Permissions Table
```sql
CREATE TABLE `tim_permissions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,           -- e.g., 'timetable:create'
  `display_name` VARCHAR(150) NOT NULL,   -- e.g., 'Create Timetable'
  `description` VARCHAR(255) DEFAULT NULL,
  `category` VARCHAR(50) NOT NULL,        -- e.g., 'TIMETABLE', 'GENERATION'
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_permissions_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Role-Permission Junction
```sql
CREATE TABLE `tim_role_permissions_jnt` (
  `role_id` BIGINT UNSIGNED NOT NULL,
  `permission_id` BIGINT UNSIGNED NOT NULL,
  `granted_by` BIGINT UNSIGNED NOT NULL,    -- User who granted permission
  `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`, `permission_id`),
  KEY `idx_role_permissions_role` (`role_id`),
  KEY `idx_role_permissions_permission` (`permission_id`),
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`),
  CONSTRAINT `fk_rp_permission` FOREIGN KEY (`permission_id`) REFERENCES `tim_permissions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### User-Permission Overrides
```sql
CREATE TABLE `tim_user_permissions_jnt` (
  `user_id` BIGINT UNSIGNED NOT NULL,
  `permission_id` BIGINT UNSIGNED NOT NULL,
  `is_granted` TINYINT(1) NOT NULL,         -- 1=grant, 0=deny (for exceptions)
  `reason` VARCHAR(255) DEFAULT NULL,       -- Why this override exists
  `granted_by` BIGINT UNSIGNED NOT NULL,
  `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL DEFAULT NULL, -- For temporary permissions
  PRIMARY KEY (`user_id`, `permission_id`),
  KEY `idx_user_permissions_user` (`user_id`),
  KEY `idx_user_permissions_permission` (`permission_id`),
  CONSTRAINT `fk_up_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_up_permission` FOREIGN KEY (`permission_id`) REFERENCES `tim_permissions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## PERMISSION SEED DATA

### Core Permissions
```sql
INSERT INTO `tim_permissions` (`name`, `display_name`, `description`, `category`, `is_active`) VALUES
-- Timetable Management
('timetable:create', 'Create Timetable', 'Create new timetables', 'TIMETABLE', 1),
('timetable:read', 'Read Timetable', 'View timetables', 'TIMETABLE', 1),
('timetable:update', 'Update Timetable', 'Modify timetables', 'TIMETABLE', 1),
('timetable:delete', 'Delete Timetable', 'Delete timetables', 'TIMETABLE', 1),
('timetable:publish', 'Publish Timetable', 'Publish timetables for use', 'TIMETABLE', 1),
('timetable:archive', 'Archive Timetable', 'Archive old timetables', 'TIMETABLE', 1),

-- Generation Control
('generation:start', 'Start Generation', 'Start timetable generation', 'GENERATION', 1),
('generation:stop', 'Stop Generation', 'Stop running generation', 'GENERATION', 1),
('generation:pause', 'Pause Generation', 'Pause generation process', 'GENERATION', 1),
('generation:resume', 'Resume Generation', 'Resume paused generation', 'GENERATION', 1),
('generation:logs', 'View Generation Logs', 'View generation logs', 'GENERATION', 1),
('generation:params', 'Modify Generation Params', 'Change generation parameters', 'GENERATION', 1),

-- Editing Permissions
('editing:manual', 'Manual Cell Edit', 'Edit individual cells', 'EDITING', 1),
('editing:dragdrop', 'Drag & Drop Editing', 'Use drag-drop interface', 'EDITING', 1),
('editing:bulk', 'Bulk Cell Updates', 'Update multiple cells', 'EDITING', 1),
('editing:undo', 'Undo/Redo Operations', 'Use undo/redo', 'EDITING', 1),
('editing:locked', 'Edit Locked Cells', 'Edit locked cells', 'EDITING', 1),

-- Locking Control
('locking:lock', 'Lock Timetable', 'Lock timetables', 'LOCKING', 1),
('locking:unlock', 'Unlock Timetable', 'Unlock timetables', 'LOCKING', 1),
('locking:individual', 'Lock Individual Cells', 'Lock specific cells', 'LOCKING', 1),
('locking:override', 'Override Locks', 'Override existing locks', 'LOCKING', 1),
('locking:approve', 'Approve Changes', 'Approve timetable changes', 'LOCKING', 1),

-- Substitution Management
('substitution:request', 'Request Substitution', 'Request teacher substitution', 'SUBSTITUTION', 1),
('substitution:assign', 'Assign Substitute', 'Assign substitute teachers', 'SUBSTITUTION', 1),
('substitution:approve', 'Approve Substitution', 'Approve substitution requests', 'SUBSTITUTION', 1),
('substitution:reject', 'Reject Substitution', 'Reject substitution requests', 'SUBSTITUTION', 1),
('substitution:history', 'View Substitution History', 'View past substitutions', 'SUBSTITUTION', 1),
('substitution:rate', 'Rate Substitute', 'Rate substitute performance', 'SUBSTITUTION', 1),

-- Constraint Management
('constraint:create', 'Create Constraints', 'Create new constraints', 'CONSTRAINT', 1),
('constraint:read', 'Read Constraints', 'View constraints', 'CONSTRAINT', 1),
('constraint:update', 'Update Constraints', 'Modify constraints', 'CONSTRAINT', 1),
('constraint:delete', 'Delete Constraints', 'Delete constraints', 'CONSTRAINT', 1),
('constraint:activate', 'Activate Constraints', 'Enable/disable constraints', 'CONSTRAINT', 1),
('constraint:test', 'Test Constraints', 'Test constraint logic', 'CONSTRAINT', 1),

-- Reporting & Export
('reporting:print', 'Print Timetable', 'Print timetables', 'REPORTING', 1),
('reporting:export_pdf', 'Export PDF', 'Export as PDF', 'REPORTING', 1),
('reporting:export_excel', 'Export Excel', 'Export as Excel', 'REPORTING', 1),
('reporting:export_csv', 'Export CSV', 'Export as CSV', 'REPORTING', 1),
('reporting:import', 'Import Timetable', 'Import timetable data', 'REPORTING', 1),
('reporting:analytics', 'View Analytics', 'Access analytics', 'REPORTING', 1);
```

### Role-Permission Assignments
```sql
-- Super Admin gets all permissions
INSERT INTO `tim_role_permissions_jnt` (`role_id`, `permission_id`, `granted_by`)
SELECT r.id, p.id, 1
FROM `sys_roles` r
CROSS JOIN `tim_permissions` p
WHERE r.name = 'SUPER_ADMIN';

-- School Admin gets most permissions except system-level ones
INSERT INTO `tim_role_permissions_jnt` (`role_id`, `permission_id`, `granted_by`)
SELECT r.id, p.id, 1
FROM `sys_roles` r
CROSS JOIN `tim_permissions` p
WHERE r.name = 'SCHOOL_ADMIN'
AND p.name NOT IN ('locking:override', 'constraint:delete', 'timetable:delete');

-- Teacher gets limited permissions
INSERT INTO `tim_role_permissions_jnt` (`role_id`, `permission_id`, `granted_by`)
SELECT r.id, p.id, 1
FROM `sys_roles` r
CROSS JOIN `tim_permissions` p
WHERE r.name = 'TEACHER'
AND p.name IN ('timetable:read', 'substitution:request', 'reporting:print', 'reporting:export_pdf');
```

---

## ACCESS CONTROL WORKFLOW

### 1. Permission Check Flow
```
User Action → Middleware Check → JWT Token Validation → Permission Lookup → Row-Level Security → Allow/Deny
```

### 2. Dynamic Permission Evaluation
```php
// Check if user can edit a specific timetable cell
function canEditCell(User $user, TimetableCell $cell): bool
{
    // Basic permission check
    if (!$user->can('editing:manual')) {
        return false;
    }

    // Check if cell is locked
    if ($cell->locked && !$user->can('editing:locked')) {
        return false;
    }

    // Check ownership (teachers can only edit their subjects)
    if ($user->hasRole('TEACHER')) {
        $isAssigned = $cell->teachers()->where('teacher_id', $user->id)->exists();
        if (!$isAssigned) {
            return false;
        }
    }

    // Check school isolation
    if ($cell->school_id !== $user->school_id) {
        return false;
    }

    return true;
}
```

### 3. Audit Logging
```php
// Log all permission checks for security
Log::info('Permission Check', [
    'user_id' => $user->id,
    'permission' => 'timetable:update',
    'resource' => 'timetable_cell:' . $cell->id,
    'result' => $allowed ? 'ALLOWED' : 'DENIED',
    'ip_address' => request()->ip(),
    'user_agent' => request()->userAgent()
]);
```

---

## TESTING PERMISSIONS

### Unit Tests for Permission Logic
```php
class TimetablePermissionTest extends TestCase
{
    public function test_super_admin_can_edit_locked_cells()
    {
        $user = User::factory()->create(['role' => 'SUPER_ADMIN']);
        $cell = TimetableCell::factory()->create(['locked' => true]);

        $this->assertTrue(canEditCell($user, $cell));
    }

    public function test_teacher_cannot_edit_other_subjects()
    {
        $user = User::factory()->create(['role' => 'TEACHER']);
        $cell = TimetableCell::factory()->create();

        // Cell not assigned to this teacher
        $this->assertFalse(canEditCell($user, $cell));
    }

    public function test_student_cannot_edit_timetable()
    {
        $user = User::factory()->create(['role' => 'STUDENT']);
        $cell = TimetableCell::factory()->create();

        $this->assertFalse(canEditCell($user, $cell));
    }
}
```

---

**Document Created By:** ERP Architect GPT  
**Last Reviewed:** December 14, 2025  
**Next Review Date:** March 14, 2026  
**Version Control:** Initial creation