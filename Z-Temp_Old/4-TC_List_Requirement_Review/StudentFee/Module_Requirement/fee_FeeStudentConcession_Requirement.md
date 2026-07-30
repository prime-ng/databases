# Feature Requirement: Fee Student Concession

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Student Concession** — Concession/discount applications applied to specific students

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Name: `student-fee.configuration`, Tab: `fee-student-concession`)

## 4. Description
Manages concession/discount applications for individual students linked to their fee assignments. Supports approval workflow with Pending/Approved/Rejected statuses. If the concession type requires approval, a notification is sent to the approver role. No soft deletes — destroy permanently deletes records.

## 5. Primary Model
**`Modules\StudentFee\Models\FeeStudentConcession`** (Table: `fee_student_concessions`)

## 6. Controller
**`Modules\StudentFee\Http\Controllers\FeeStudentConcessionController`**

### Methods Implemented:
| Method | Route | Permission |
|--------|-------|------------|
| `index()` | `GET /fee-student-concession` | `tenant.fee-student-concession.view` |
| `create()` | `GET /fee-student-concession/create` | `tenant.fee-student-concession.create` |
| `store()` | `POST /fee-student-concession` | `tenant.fee-student-concession.create` |
| `show($id)` | `GET /fee-student-concession/{id}` | `tenant.fee-student-concession.view` |
| `edit($id)` | `GET /fee-student-concession/{id}/edit` | `tenant.fee-student-concession.update` |
| `update()` | `PUT /fee-student-concession/{id}` | `tenant.fee-student-concession.update` |
| `destroy($id)` | `DELETE /fee-student-concession/{id}` | `tenant.fee-student-concession.delete` |
| `trashed()` | `GET /fee-student-concession/trash/view` | Redirects to configuration tab |

## 7. Form Requests

### StoreFeeStudentConcessionRequest
- Authorizes via `tenant.fee-student-concession` CRUD permission
- Rules:
  - `student_assignment_id`: required, integer, exists:fee_student_assignments,id
  - `concession_type_id`: required, integer, exists:fee_concession_types,id
  - `discount_amount`: required, numeric, min:0
  - `approval_status`: required, in:Pending,Approved,Rejected
  - `rejection_reason`: required_if:approval_status,Rejected, nullable, string, max:1000
  - `remarks`: nullable, string, max:1000
- Custom messages:
  - `'Rejection reason is required when status is Rejected.'`

### UpdateFeeStudentConcessionRequest
- Same rules as Store
- Same custom messages

## 8. Database Table Structure

**Table: `fee_student_concessions`**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| `student_assignment_id` | INT UNSIGNED | NOT NULL, FK → fee_student_assignments (CASCADE) |
| `concession_type_id` | INT UNSIGNED | NOT NULL, FK → fee_concession_types (RESTRICT) |
| `approved_by` | INT UNSIGNED | NULL, FK → sys_users (SET NULL) |
| `approved_at` | TIMESTAMP | NULL |
| `approval_status` | ENUM('Pending','Approved','Rejected') | NOT NULL, DEFAULT 'Pending' |
| `rejection_reason` | TEXT | NULL |
| `discount_amount` | DECIMAL(10,2) | NOT NULL |
| `remarks` | TEXT | NULL |
| `created_by` | INT UNSIGNED | NULL |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE |

**Indexes:**
- INDEX `idx_concession_status` (`approval_status`)
- FK `fk_fsc_assignment` → fee_student_assignments(id) ON DELETE CASCADE
- FK `fk_fsc_concession` → fee_concession_types(id) ON DELETE RESTRICT
- FK `fk_fsc_approver` → sys_users(id) ON DELETE SET NULL

### Model Attributes
- **$fillable**: student_assignment_id, concession_type_id, approved_by, approved_at, approval_status, rejection_reason, discount_amount, remarks, created_by
- **$casts**: student_assignment_id(integer), concession_type_id(integer), approved_by(integer), approved_at(datetime), discount_amount(decimal:2), created_by(integer)
- **No SoftDeletes** trait used

### Model Scopes & Helpers
- `scopeApproved(Builder)`: where approval_status = 'Approved'
- `scopePending(Builder)`: where approval_status = 'Pending'
- `scopeRejected(Builder)`: where approval_status = 'Rejected'
- `isApproved(): bool`
- `isPending(): bool`
- `isRejected(): bool`
- `approve(int $userId)`: sets status to Approved, sets approved_by and approved_at
- `reject(int $userId, ?string $reason)`: sets status to Rejected, sets approved_by, approved_at, rejection_reason

### Model Relationships
- `assignment()`: BelongsTo → FeeStudentAssignment
- `concessionType()`: BelongsTo → FeeConcessionType
- `approver()`: BelongsTo → User (sys_users) via approved_by
- `creator()`: BelongsTo → User (sys_users) via created_by

## 9. Business Rules / Logic

### Approval Workflow
1. Admin creates a FeeStudentConcession linked to a student's fee assignment
2. Default status from request (not auto-set): Pending, Approved, or Rejected
3. If status is Approved or Rejected, the current user is set as approved_by and timestamp is set
4. If concession type requires_approval and has approval_level_role_id, a notification is sent to that role
5. Notification is non-critical — failures are caught silently

### Re-approval Logic (Update)
- If new approval_status is Decided (Approved/Rejected) and was not already decided: sets approved_by to current user and approved_at to now
- If was already decided: preserves original approved_by and approved_at values

### No Soft Deletes
- destroy() performs hard/permanent delete (no call to deactivate first)
- No restore or forceDelete routes (trashed() just redirects to configuration tab)

## 10. Controller Logic Details

### index()
- Authorization: `tenant.fee-student-concession.view`
- Redirects to `route('student-fee.configuration', ['tab' => 'fee-student-concession'])`

### create()
- Authorization: `tenant.fee-student-concession.create`
- Loads active fee student assignments (with student.user, class, section)
- Loads active fee concession types
- Loads active students
- Returns create view

### store(StoreFeeStudentConcessionRequest)
- Authorization: `tenant.fee-student-concession.create`
- Creates FeeStudentConcession with all validated data
- Sets created_by to auth()->id()
- If status is Approved or Rejected, sets approved_by and approved_at
- Activity logged
- If concession type requires_approval and has approval_level_role_id: dispatches Notification
- Notification is in try-catch — non-critical
- Flash: `'Fee concession created successfully.'`
- Redirects to configuration tab

### show($id)
- Authorization: `tenant.fee-student-concession.view`
- Eager loads: assignment.student.user, concessionType, approver, creator
- Returns show view

### edit($id)
- Authorization: `tenant.fee-student-concession.update`
- Eager loads: assignment.student.user, concessionType
- Loads active assignments and concession types
- Returns edit view

### update(UpdateFeeStudentConcessionRequest, $id)
- Authorization: `tenant.fee-student-concession.update`
- Handles re-approval logic:
  - $wasDecided: new status is Approved or Rejected
  - $wasAlreadyDecided: current status is Approved or Rejected
  - If decided and not already decided: sets approved_by to auth()->id(), approved_at to now
  - If decided and already decided: preserves original approved_by and approved_at
- Activity logged
- Flash: `'Fee concession updated successfully.'`
- Redirects to configuration tab

### destroy($id)
- Authorization: `tenant.fee-student-concession.delete`
- findOrFail → delete (permanent, no soft delete)
- Activity logged
- Flash: `'Fee concession deleted successfully.'`
- Redirects to configuration tab

### trashed()
- No authorization gate
- Redirects to `route('student-fee.configuration', ['tab' => 'fee-student-concession'])`

## 11. Edge Cases & Validations
- No soft deletes — destroy() permanently removes the record
- No toggleStatus, restore, or forceDelete methods
- rejection_reason required when approval_status is Rejected (validated in FormRequest)
- Notification dispatch failures are caught silently (non-critical)
- Re-approval preserves original approver info when status is changed from one decided state to another

## 12. Dependencies / Relations
- **fee_student_assignments**: student_assignment_id FK (CASCADE on delete)
- **fee_concession_types**: concession_type_id FK (RESTRICT)
- **sys_users**: approved_by/created_by FK (SET NULL)
- **Notification facade**: for dispatching approval requests to approver role

## 13. API / Route Details

### Web Routes (resource + additional):
| Method | URI | Name |
|--------|-----|------|
| GET | `/fee-student-concession` | `fee-student-concession.index` |
| GET | `/fee-student-concession/create` | `fee-student-concession.create` |
| POST | `/fee-student-concession` | `fee-student-concession.store` |
| GET | `/fee-student-concession/{fee_student_concession}` | `fee-student-concession.show` |
| GET | `/fee-student-concession/{fee_student_concession}/edit` | `fee-student-concession.edit` |
| PUT | `/fee-student-concession/{fee_student_concession}` | `fee-student-concession.update` |
| DELETE | `/fee-student-concession/{fee_student_concession}` | `fee-student-concession.destroy` |
| GET | `/fee-student-concession/trash/view` | `fee-student-concession.trashed` |

## 14. Permissions

| Operation | Permission Key |
|-----------|---------------|
| View student concessions list | `tenant.fee-student-concession.view` |
| View concession details | `tenant.fee-student-concession.view` |
| Create student concession | `tenant.fee-student-concession.create` |
| Update student concession | `tenant.fee-student-concession.update` |
| Delete student concession | `tenant.fee-student-concession.delete` |

## 15. Flash Messages
- `'Fee concession created successfully.'` — on store
- `'Fee concession updated successfully.'` — on update
- `'Fee concession deleted successfully.'` — on destroy

## 16. Known Issues / Gotchas
- No SoftDeletes trait used — destroy is permanent (cannot restore)
- No toggleStatus, restore, forceDelete endpoints (unlike other configuration features)
- trashed() is a dummy route that just redirects to configuration tab
- Notification dispatch is non-blocking but does NOT verify if the notification was actually sent
- index() uses `view` permission (not `viewAny`) — inconsistent with other controllers
- The model does not auto-set approval_status — the request must explicitly provide it (no default 'Pending' on creation)
