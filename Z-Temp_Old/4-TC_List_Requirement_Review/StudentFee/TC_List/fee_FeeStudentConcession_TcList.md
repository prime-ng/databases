# Test Case List: Fee Student Concession

## 1. Module Name
**StudentFee** (Prefix: `fee_`)

## 2. Feature Name
**Fee Student Concession** — Concession applications for individual students

## 3. Tab / Submodule
**Configuration** (Route: `GET /student-fee/configuration`, Tab: `fee-student-concession`)

## 4. Reference Documents
- DDL: `pgdatabase/2-DDL_Tenant_Consolidated/StudentFee_DDL_v4.sql` (Table 11: fee_student_concessions)
- Controller: `Modules/StudentFee/app/Http/Controllers/FeeStudentConcessionController.php`
- Store Request: `Modules/StudentFee/app/Http/Requests/StoreFeeStudentConcessionRequest.php`
- Update Request: `Modules/StudentFee/app/Http/Requests/UpdateFeeStudentConcessionRequest.php`
- Model: `Modules/StudentFee/app/Models/FeeStudentConcession.php`
- Routes: `Modules/StudentFee/routes/web.php` (Lines 95-97)

## 5. Test Case Matrix

| # | Test Case | Precondition | Test Data / Steps | Expected Result | Actual Result | Status (⬜/✅/❌/◌) | V1 | V2 | Remarks |
|---|-----------|-------------|-------------------|----------------|---------------|-------------------|---|---|---|---------|
| TC-FSC-001 | View student concession list (index redirects) | User has view permission | GET /fee-student-concession | 302 Redirect to route('student-fee.configuration', ['tab' => 'fee-student-concession']) | — | ⬜ | — | — | |
| TC-FSC-002 | View create student concession form | User has create permission | GET /fee-student-concession/create | Returns 200, shows create form with active assignments, active concession types, active students | — | ⬜ | — | — | |
| TC-FSC-003 | Create student concession - status Pending | Valid student_assignment and concession_type, user has create permission | POST /fee-student-concession with: student_assignment_id=1, concession_type_id=1, discount_amount=1000.00, approval_status=Pending, remarks='Test' | 302 Redirect to config tab, record created with approval_status=Pending, created_by=auth()->id(), approved_by=null, approved_at=null, activity_log entry | — | ⬜ | — | — | |
| TC-FSC-004 | Create student concession - status Approved (direct approval) | — | POST /fee-student-concession with: approval_status=Approved | Created with approval_status=Approved, approved_by=auth()->id(), approved_at=now() | — | ⬜ | — | — | |
| TC-FSC-005 | Create student concession - status Rejected with reason | — | POST /fee-student-concession with: approval_status=Rejected, rejection_reason='Not eligible' | Created with status=Rejected, rejection_reason='Not eligible', approved_by=auth()->id(), approved_at=now() | — | ⬜ | — | — | |
| TC-FSC-006 | Create student concession - Rejected without rejection_reason | — | POST /fee-student-concession with: approval_status=Rejected, no rejection_reason | Validation error: 'Rejection reason is required when status is Rejected.' | — | ⬜ | — | — | |
| TC-FSC-007 | Create student concession - invalid approval_status | — | POST with: approval_status=Invalid | Validation error: approval_status must be one of Pending,Approved,Rejected | — | ⬜ | — | — | |
| TC-FSC-008 | Create student concession - invalid student_assignment_id | ID=9999 | POST with: student_assignment_id=9999 | Validation error: student_assignment_id does not exist | — | ⬜ | — | — | |
| TC-FSC-009 | Create student concession - discount_amount negative | — | POST with: discount_amount=-100 | Validation error: discount_amount must not be less than 0 | — | ⬜ | — | — | |
| TC-FSC-010 | Create student concession - concession type requires_approval triggers notification | concession_type has requires_approval=1 and approval_level_role_id set | POST with valid data | Notification::dispatch called with FEE_CONCESSION_APPROVAL_REQUESTED event, non-critical if fails | — | ⬜ | — | — | |
| TC-FSC-011 | Notification dispatch failure is non-blocking | Notification throws exception | POST valid data | Create succeeds despite notification failure (exception caught silently) | — | ⬜ | — | — | |
| TC-FSC-012 | View single student concession details | Existing record | GET /fee-student-concession/1 | Returns 200, shows with eager-loaded: assignment.student.user, concessionType, approver, creator | — | ⬜ | — | — | |
| TC-FSC-013 | View student concession - not found | ID=9999 | GET /fee-student-concession/9999 | Returns 404 Not Found | — | ⬜ | — | — | |
| TC-FSC-014 | View edit student concession form | Existing record | GET /fee-student-concession/1/edit | Returns 200, shows edit form with pre-filled data, active assignments, active concession types | — | ⬜ | — | — | |
| TC-FSC-015 | Update student concession - change status from Pending to Approved | Existing with status=Pending | PUT /fee-student-concession/1 with: approval_status=Approved | Updated, approved_by=auth()->id(), approved_at=now() (first time decision) | — | ⬜ | — | — | |
| TC-FSC-016 | Update student concession - change status from Approved to Rejected (re-approval) | Existing with status=Approved, approved_by=2, approved_at=some_date | PUT /fee-student-concession/1 with: approval_status=Rejected, rejection_reason='Reason' | Updated to Rejected, approved_by and approved_at PRESERVED from original (wasAlreadyDecided=true) | — | ⬜ | — | — | |
| TC-FSC-017 | Update student concession - Pending → Pending (no approver change) | Existing with status=Pending | PUT with: approval_status=Pending | Updated, approved_by remains null, approved_at remains null | — | ⬜ | — | — | |
| TC-FSC-018 | Delete student concession (permanent) | Existing record | DELETE /fee-student-concession/1 | Record permanently deleted (no soft delete), redirect to config tab, activity_log 'Deleted' entry | — | ⬜ | — | — | |
| TC-FSC-019 | Delete student concession without permission | User lacks delete permission | DELETE /fee-student-concession/1 | Returns 403 Forbidden | — | ⬜ | — | — | |
| TC-FSC-020 | Trashed route is dummy redirect | — | GET /fee-student-concession/trash/view | Redirect to route('student-fee.configuration', ['tab' => 'fee-student-concession']) | — | ⬜ | — | — | |
| TC-FSC-021 | Create student concession - remarks max length 1001 chars | — | POST with: remarks=string of 1001 chars | Validation error: remarks must not exceed 1000 characters | — | ⬜ | — | — | |
| TC-FSC-022 | Rejection reason max length 1001 chars | approval_status=Rejected | POST with: rejection_reason=string of 1001 chars | Validation error: rejection_reason must not exceed 1000 characters | — | ⬜ | — | — | |
| TC-FSC-023 | approve() helper method | Existing model instance | $model->approve(1) | Sets approval_status=Approved, approved_by=1, approved_at=now() | — | ⬜ | — | — | |
| TC-FSC-024 | reject() helper method | Existing model instance | $model->reject(1, 'Not eligible') | Sets status=Rejected, approved_by=1, approved_at=now(), rejection_reason='Not eligible' | — | ⬜ | — | — | |
| TC-FSC-025 | scopes: scopeApproved, scopePending, scopeRejected | Various records | Apply scopes to query | Proper filtering by approval_status | — | ⬜ | — | — | |
| TC-FSC-026 | isApproved/isPending/isRejected helpers | Model with various statuses | Call each helper | Returns correct boolean values | — | ⬜ | — | — | |

## 6. Business Rules Coverage

| Rule | TC Coverage | Status |
|------|-------------|--------|
| Approval workflow: Pending → Approved/Rejected | TC-FSC-003, TC-FSC-004, TC-FSC-005 | ⬜ |
| Rejection requires rejection_reason | TC-FSC-006 | ⬜ |
| First-time decision sets approved_by/approved_at | TC-FSC-015 | ⬜ |
| Re-approval preserves original approver info | TC-FSC-016 | ⬜ |
| Notification dispatched if requires_approval | TC-FSC-010 | ⬜ |
| Notification failure is non-critical | TC-FSC-011 | ⬜ |
| No soft deletes — permanent deletion | TC-FSC-018 | ⬜ |
| created_by auto-set from auth()->id() | TC-FSC-003 | ⬜ |

## 7. Edge Case Coverage

| Edge Case | TC Coverage | Status |
|-----------|-------------|--------|
| Invalid approval_status value | TC-FSC-007 | ⬜ |
| Invalid student_assignment_id | TC-FSC-008 | ⬜ |
| Negative discount_amount | TC-FSC-009 | ⬜ |
| Remarks max length exceeded | TC-FSC-021 | ⬜ |
| Rejection reason max length exceeded | TC-FSC-022 | ⬜ |
| Pending → Pending (no approver change) | TC-FSC-017 | ⬜ |
| Already decided → different decision (preserve approver) | TC-FSC-016 | ⬜ |
| Trashed route has no functionality (dummy) | TC-FSC-020 | ⬜ |
| Notification failure is non-blocking | TC-FSC-011 | ⬜ |

## 8. Known Issues / Gaps

1. **GAP-FSC-01**: **CRITICAL** — `FeeStudentConcession` model does NOT use the `SoftDeletes` trait. The `destroy()` method calls `$concession->delete()` which performs a permanent/hard delete. This is by design (no soft deletes for this feature), but developers must be aware that records cannot be restored.
2. **GAP-FSC-02**: `index()` uses `tenant.fee-student-concession.view` permission (not `viewAny`), which is inconsistent with the pattern used by other controllers that use `viewAny` for index access.
3. **GAP-FSC-03**: `trashed()` method has no authorization check — it just redirects. This route exists but serves no functional purpose for this feature.
4. **GAP-FSC-04**: No `toggleStatus`, `restore`, or `forceDelete` endpoints exist — this feature has a simplified lifecycle compared to other configuration features.
5. **GAP-FSC-05**: The model does NOT auto-default `approval_status` to 'Pending' — the request must explicitly provide it. If the request omits it, validation will fail.
6. **GAP-FSC-06**: Notification dispatch uses `try-catch` with empty catch block — silent failure means operators won't know if notifications are not being sent.
7. **GAP-FSC-07**: `create()` loads both `feeStudentAssignments` AND `students` separately — the student list seems redundant since assignments already include student info.

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/fee-student-concession` | `fee-student-concession.index` | index() → redirect |
| GET | `/fee-student-concession/create` | `fee-student-concession.create` | create() |
| POST | `/fee-student-concession` | `fee-student-concession.store` | store() |
| GET | `/fee-student-concession/{fee_student_concession}` | `fee-student-concession.show` | show() |
| GET | `/fee-student-concession/{fee_student_concession}/edit` | `fee-student-concession.edit` | edit() |
| PUT | `/fee-student-concession/{fee_student_concession}` | `fee-student-concession.update` | update() |
| DELETE | `/fee-student-concession/{fee_student_concession}` | `fee-student-concession.destroy` | destroy() |
| GET | `/fee-student-concession/trash/view` | `fee-student-concession.trashed` | trashed() → redirect |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Not Run |
|----------|--------|--------|---------|---------|
| 26 | 0 | 0 | 0 | 26 |
