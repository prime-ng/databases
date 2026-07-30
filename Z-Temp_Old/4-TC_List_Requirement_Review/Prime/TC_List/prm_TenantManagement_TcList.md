# Prime (PRM) — Tenant Management Test Case List

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Tenant Management |
| **Sub-Features** | Tenant CRUD, DB Provisioning, Plan Assignment, Board Assignment, Module Toggling, Academic Rollover, Archive Access, Status Management, Setup Reset |
| **FRD Reference** | REQ-PRM-001 (Registration & Provisioning), REQ-PRM-004 (Subscription & Billing), REQ-PRM-005 (Module Licensing), REQ-PRM-009 (Academic Rollover) |
| **Controller** | `TenantController` (~1030 lines) |
| **TC List Version** | V1 |
| **CR ID** | ◌ |

---

## 2. Test Case Summary

| TC Total | TC Auto | TC Manual | TC Skipped | Blocked | Removed |
|:--------:|:-------:|:---------:|:----------:|:-------:|:-------:|
| 68 | 0 | 68 | — | — | — |

---

## 3. Test Cases

### 3.1 Tenant CRUD — List & View

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-001 | Verify tenant list shows all live tenants | Multiple live tenants exist | GET /prime/tenant | Paginated list of live tenants displayed | — | ⬜ | — | ◌ |
| TC-PRM-TNT-002 | Verify tenant list is denied without permission | User lacks prime.tenant.viewAny | GET /prime/tenant | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-TNT-003 | Verify tenant show redirects to complete-tenant-setup | Tenant exists | GET /prime/tenant/{id} | Redirect to completeTenantSetup | — | ⬜ | — | ◌ |

### 3.2 Tenant CRUD — Create

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-004 | Verify create form loads with all required dropdowns | User has create permission | GET /prime/tenant/create | Form displayed with tenant groups, sessions, boards | — | ⬜ | — | ◌ |
| TC-PRM-TNT-005 | Verify create form is denied without permission | User lacks prime.tenant.create | GET /prime/tenant/create | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-TNT-006 | Verify tenant created with all valid fields | Valid input data | POST /prime/tenant (valid) | Tenant created (is_active=0, setup_status=pending); domain created; job dispatched; email sent; redirected to setup progress | — | ⬜ | — | ◌ |
| TC-PRM-TNT-007 | Verify tenant creation validates required fields | Missing required data | POST /prime/tenant (empty) | Validation errors for all required fields | — | ⬜ | — | ◌ |
| TC-PRM-TNT-008 | Verify tenant creation validates unique code | Duplicate code | POST /prime/tenant (existing code) | Validation error: code already taken | — | ⬜ | — | ◌ |
| TC-PRM-TNT-009 | Verify tenant creation validates unique short_name | Duplicate short_name | POST /prime/tenant (existing short_name) | Validation error: short_name already taken | — | ⬜ | — | ◌ |
| TC-PRM-TNT-010 | Verify tenant creation validates unique domain | Duplicate domain | POST /prime/tenant (existing domain) | Validation error: "This sub-domain is already taken" | — | ⬜ | — | ◌ |
| TC-PRM-TNT-011 | Verify tenant creation validates non-existent city_id | Invalid city_id | POST /prime/tenant (city_id=99999) | Validation error: invalid city | — | ⬜ | — | ◌ |
| TC-PRM-TNT-012 | Verify tenant creation validates domain format (alpha_dash) | Invalid domain | POST /prime/tenant (domain=invalid domain!) | Validation error: domain format | — | ⬜ | — | ◌ |
| TC-PRM-TNT-013 | Verify tenant creation denied without permission | User lacks prime.tenant.create | POST /prime/tenant (valid) | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.3 Tenant Setup Progress & Status

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-014 | Verify setup progress page displays for existing tenant | Tenant exists, status = pending | GET /prime/tenant/setup-progress/{id} | Progress page with current status and polling | — | ⬜ | — | ◌ |
| TC-PRM-TNT-015 | Verify setup status JSON endpoint returns correct data | Tenant exists | GET /prime/tenant/setup-status/{id} | JSON {status, progress, message, name} | — | ⬜ | — | ◌ |
| TC-PRM-TNT-016 | Verify setup status shows "pending" before job runs | Tenant newly created | GET /prime/tenant/setup-status/{id} | status = "pending", progress = 0 | — | ⬜ | — | ◌ |
| TC-PRM-TNT-017 | Verify setup status shows "completed" after successful provisioning | SetupTenantDatabase completed | GET /prime/tenant/setup-status/{id} | status = "completed", progress = 100 | — | ⬜ | — | ◌ |
| TC-PRM-TNT-018 | Verify setup status shows "failed" on provisioning error | SetupTenantDatabase failed | GET /prime/tenant/setup-status/{id} | status = "failed", progress frozen | — | ⬜ | — | ◌ |
| TC-PRM-TNT-019 | Verify setup status returns 404 for non-existent tenant | Invalid id | GET /prime/tenant/setup-status/99999 | 404 Not Found | — | ⬜ | — | ◌ |

### 3.4 Tenant Edit & Update

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-020 | Verify edit form loads with existing data | Tenant exists, user has update permission | GET /prime/tenant/{id}/edit | Form pre-filled with tenant data | — | ⬜ | — | ◌ |
| TC-PRM-TNT-021 | Verify tenant update saves changes | Tenant exists | PUT /prime/tenant/{id} (updated name) | Tenant updated; domain updated; success message | — | ⬜ | — | ◌ |
| TC-PRM-TNT-022 | Verify tenant update syncs to tenant DB org when setup completed | Tenant setup = completed | PUT /prime/tenant/{id} (updated name) | Organization in tenant DB also updated | — | ⬜ | — | ◌ |
| TC-PRM-TNT-023 | Verify tenant update denied without permission | User lacks prime.tenant.update | PUT /prime/tenant/{id} | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.5 Tenant Complete Setup View

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-024 | Verify complete setup view loads with all sections | Tenant exists with plans, invoices, domains | GET /prime/tenant/{tenant}/complete-tenant-setup | View loads with plans, modules, boards, sessions, archive, backup sections | — | ⬜ | — | ◌ |
| TC-PRM-TNT-025 | Verify complete setup view loads tenant-scoped data when setup completed | Tenant setup = completed | GET /prime/tenant/{tenant}/complete-tenant-setup | Organization, academic sessions, boards from tenant DB loaded | — | ⬜ | — | ◌ |
| TC-PRM-TNT-026 | Verify complete setup view denied without permission | User lacks prime.tenant.update | GET /prime/tenant/{tenant}/complete-tenant-setup | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.6 Plan Assignment (updateTenantPlan)

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-027 | Verify plan assigned successfully with all 5 steps | Active academic session exists, valid plan data | POST /prime/tenant/{tenant}/update-tenant-plan | Plan created, rate card saved, modules assigned, billing schedules generated, email sent | — | ⬜ | — | ◌ |
| TC-PRM-TNT-028 | Verify correct number of billing schedules generated for monthly plan | Monthly billing, 12-month period | POST /prime/tenant/{tenant}/update-tenant-plan | Exactly 12 billing schedule entries created | — | ⬜ | — | ◌ |
| TC-PRM-TNT-029 | Verify correct number of billing schedules for quarterly plan | Quarterly billing, 12-month period | POST /prime/tenant/{tenant}/update-tenant-plan | Exactly 4 billing schedule entries created | — | ⬜ | — | ◌ |
| TC-PRM-TNT-030 | Verify plan assignment blocked if no active academic session | No session marked current | POST /prime/tenant/{tenant}/update-tenant-plan | RuntimeException: "No active academic session found." | — | ⬜ | — | ◌ |
| TC-PRM-TNT-031 | Verify warning shown when billing window outside session | Subscription dates outside session | POST /prime/tenant/{tenant}/update-tenant-plan | Warning: "No billing periods fall within the current academic session."; no schedules created | — | ⬜ | — | ◌ |
| TC-PRM-TNT-032 | Verify transaction rollback on validation failure | Invalid plan_id | POST /prime/tenant/{tenant}/update-tenant-plan | No partial data saved; validation error returned | — | ⬜ | — | ◌ |
| TC-PRM-TNT-033 | Verify plan re-assignment soft-deactivates old modules | Existing plan assigned | POST /prime/tenant/{tenant}/update-tenant-plan (new plan) | Old TenantPlanModule rows set is_active=0; new rows created | — | ⬜ | — | ◌ |
| TC-PRM-TNT-034 | Verify plan re-assignment soft-deactivates old billing schedules | Existing schedules | POST /prime/tenant/{tenant}/update-tenant-plan (new plan) | Old schedules set is_active=0; new schedules generated | — | ⬜ | — | ◌ |
| TC-PRM-TNT-035 | Verify missing plan_id returns validation error | No plan_id | POST /prime/tenant/{tenant}/update-tenant-plan | ValidationException: "Plan id is required." | — | ⬜ | — | ◌ |
| TC-PRM-TNT-036 | Verify plan assignment denied without permission | User lacks prime.tenant.update | POST /prime/tenant/{tenant}/update-tenant-plan | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.7 Module & Plan Status Toggles

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-037 | Verify tenant module toggle enables/disables module | TenantPlanModule exists | POST /prime/tenant/module/{id}/toggle | is_active toggled; cache cleared; JSON response with new status | — | ⬜ | — | ◌ |
| TC-PRM-TNT-038 | Verify tenant plan toggle enables plan | TenantPlan exists | POST /prime/tenant/plan/{id}/toggle-status (is_active=1) | Plan enabled; cache cleared; JSON success | — | ⬜ | — | ◌ |
| TC-PRM-TNT-039 | Verify tenant plan toggle disables plan | TenantPlan exists | POST /prime/tenant/plan/{id}/toggle-status (is_active=0) | Plan disabled; cache cleared; menus hidden | — | ⬜ | — | ◌ |

### 3.8 Board Assignment

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-040 | Verify boards assigned to tenant for selected session | Tenant DB has session, boards exist | POST /prime/tenant/{tenant}/assign-boards | Boards assigned; success message shows count | — | ⬜ | — | ◌ |
| TC-PRM-TNT-041 | Verify board assignment requires at least one board | No board_ids | POST /prime/tenant/{tenant}/assign-boards | Validation error: "Please select at least one board." | — | ⬜ | — | ◌ |
| TC-PRM-TNT-042 | Verify board assignment validates board existence | Non-existent board_id | POST /prime/tenant/{tenant}/assign-boards (board_id=99999) | Validation error: invalid board | — | ⬜ | — | ◌ |
| TC-PRM-TNT-043 | Verify board assignment validates session belongs to tenant | Session not in tenant DB | POST /prime/tenant/{tenant}/assign-boards (invalid session) | ValidationException: "Invalid academic session for this tenant." | — | ⬜ | — | ◌ |
| TC-PRM-TNT-044 | Verify board assignment replaces existing boards for session | Boards already assigned | POST /prime/tenant/{tenant}/assign-boards (different boards) | Old boards removed; new boards inserted | — | ⬜ | — | ◌ |

### 3.9 Tenant Status Toggle (Active/Inactive)

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-045 | Verify tenant status toggled to active | Tenant exists, inactive | POST /prime/tenant/{tenant}/toggle-status (is_active=1) | Tenant activated; email sent; JSON success | — | ⬜ | — | ◌ |
| TC-PRM-TNT-046 | Verify tenant status toggled to inactive | Tenant exists, active | POST /prime/tenant/{tenant}/toggle-status (is_active=0) | Tenant deactivated; email sent; JSON success | — | ⬜ | — | ◌ |
| TC-PRM-TNT-047 | Verify tenant toggle validates is_active field | Missing is_active | POST /prime/tenant/{tenant}/toggle-status | Validation error: is_active required | — | ⬜ | — | ◌ |
| TC-PRM-TNT-048 | Verify tenant toggle denied without permission | User lacks prime.tenant.update | POST /prime/tenant/{tenant}/toggle-status | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.10 Soft-Delete, Restore & Force-Delete

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-049 | Verify tenant soft-delete deactivates and trashes | Tenant exists, active | DELETE /prime/tenant/{id} | is_active=false; soft-deleted; email sent; redirect with success | — | ⬜ | — | ◌ |
| TC-PRM-TNT-050 | Verify soft-deleted tenant appears in trash list | Soft-deleted tenants exist | GET /prime/tenant/trash/view | Trash list with soft-deleted tenants | — | ⬜ | — | ◌ |
| TC-PRM-TNT-051 | Verify soft-deleted tenant restored and reactivated | Tenant soft-deleted | GET /prime/tenant/{id}/restore | Restored; is_active=true; email sent; success | — | ⬜ | — | ◌ |
| TC-PRM-TNT-052 | Verify tenant force-delete drops database and cleans up | Tenant soft-deleted | DELETE /prime/tenant/{id}/force-delete | DB dropped; storage deleted; archives deleted; record force-deleted; email sent | — | ⬜ | — | ◌ |
| TC-PRM-TNT-053 | Verify force-delete handles missing database gracefully | Tenant DB already dropped | DELETE /prime/tenant/{id}/force-delete | Warning logged; continues with remaining cleanup | — | ⬜ | — | ◌ |
| TC-PRM-TNT-054 | Verify force-delete deletes archive tenants recursively | Tenant has archive tenants | DELETE /prime/tenant/{id}/force-delete | All archive tenants force-deleted with DB drop and storage cleanup | — | ⬜ | — | ◌ |
| TC-PRM-TNT-055 | Verify delete denied without permission | User lacks prime.tenant.delete | DELETE /prime/tenant/{id} | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-TNT-056 | Verify restore denied without permission | User lacks prime.tenant.restore | GET /prime/tenant/{id}/restore | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-TNT-057 | Verify force-delete denied without permission | User lacks prime.tenant.forceDelete | DELETE /prime/tenant/{id}/force-delete | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.11 Setup Reset

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-058 | Verify failed setup can be reset | Tenant setup_status = failed | POST /prime/tenant/{tenant}/reset-setup | DB dropped; status reset to pending; job re-dispatched; redirect to setup progress | — | ⬜ | — | ◌ |
| TC-PRM-TNT-059 | Verify completed setup can be reset | Tenant setup_status = completed | POST /prime/tenant/{tenant}/reset-setup | DB dropped; status reset; job re-dispatched | — | ⬜ | — | ◌ |
| TC-PRM-TNT-060 | Verify reset blocked for pending setup | Tenant setup_status = pending | POST /prime/tenant/{tenant}/reset-setup | Error: "Setup can only be reset when it has failed or already completed." | — | ⬜ | — | ◌ |
| TC-PRM-TNT-061 | Verify reset handles missing DB gracefully | Tenant DB already missing | POST /prime/tenant/{tenant}/reset-setup | Warning logged; continues with reset | — | ⬜ | — | ◌ |

### 3.12 Academic Rollover

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-062 | Verify rollover can be started for live tenant | Tenant is live | POST /prime/tenant/{tenant}/start-rollover | AcademicSessionRolloverJob dispatched; success message | — | ⬜ | — | ◌ |
| TC-PRM-TNT-063 | Verify rollover blocked for non-live tenant | Tenant is archive | POST /prime/tenant/{tenant}/start-rollover | Error: "Rollover can only be started for a live tenant." | — | ⬜ | — | ◌ |
| TC-PRM-TNT-064 | Verify rollover status returns JSON | Rollover in progress | GET /prime/tenant/{tenant}/rollover-status | JSON {status, progress, message} | — | ⬜ | — | ◌ |

### 3.13 Archive Access Requests

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-TNT-065 | Verify archive access request submitted | Live and archive tenants exist | POST /prime/tenant/{tenant}/archive/{archive}/request-access | Request created; success message | — | ⬜ | — | ◌ |
| TC-PRM-TNT-066 | Verify archive access request approved | Pending request exists | POST /prime/tenant/{tenant}/archive/{archive}/approve-access | Request approved; archive accessible | — | ⬜ | — | ◌ |
| TC-PRM-TNT-067 | Verify archive access revoked | Approved request exists | POST /prime/tenant/{tenant}/archive/{archive}/revoke-access | Request revoked; archive access disabled | — | ⬜ | — | ◌ |
| TC-PRM-TNT-068 | Verify approve fails for non-pending request | No pending request | POST /prime/tenant/{tenant}/archive/{archive}/approve-access | 404 — request not found | — | ⬜ | — | ◌ |

---

## 4. Requirements Coverage

| REQ ID | Feature | TC Coverage |
|--------|---------|:-----------:|
| REQ-PRM-001 | School Registration & Provisioning | TC-PRM-TNT-004 to TC-PRM-TNT-019, TC-PRM-TNT-058 to TC-PRM-TNT-061 |
| REQ-PRM-004 | Plan Subscription & Billing Schedule | TC-PRM-TNT-027 to TC-PRM-TNT-036 |
| REQ-PRM-005 | Module Licensing | TC-PRM-TNT-037 to TC-PRM-TNT-039 |
| REQ-PRM-009 | Academic Session Rollover | TC-PRM-TNT-062 to TC-PRM-TNT-064 |
| — | Board Assignment | TC-PRM-TNT-040 to TC-PRM-TNT-044 |
| — | Status Management | TC-PRM-TNT-045 to TC-PRM-TNT-048 |
| — | Soft-Delete/Restore/Force-Delete | TC-PRM-TNT-049 to TC-PRM-TNT-057 |
| — | Archive Access | TC-PRM-TNT-065 to TC-PRM-TNT-068 |

---

## 5. Business Rules Coverage

| BR ID | Rule | TC Coverage |
|-------|------|:-----------:|
| BR-PRM-001 | School access: active + plan | TC-PRM-TNT-045, TC-PRM-TNT-046 |
| BR-PRM-002 | One active subscription per school-plan | TC-PRM-TNT-032 |
| BR-PRM-003 | Active session required for plan assignment | TC-PRM-TNT-030 |
| BR-PRM-004 | Billing window clamped to session | TC-PRM-TNT-031 |
| BR-PRM-005 | Soft-deactivate modules on re-assignment | TC-PRM-TNT-033 |
| BR-PRM-008 | Setup task runs once; failed = manual | TC-PRM-TNT-058, TC-PRM-TNT-059 |
| BR-PRM-013 | Complete setup requires Manage Tenant permission | TC-PRM-TNT-026 |
| BR-PRM-015 | Billing cycle determines schedule | TC-PRM-TNT-028, TC-PRM-TNT-029 |
| BR-PRM-023 | Activity log for all state-changing ops | (covered in activity log module) |

---

## 6. Data Setup Requirements

| TC Group | Data Needed |
|----------|-------------|
| CRUD | Multiple live tenants in prm_tenant, tenant groups in prm_tenant_groups |
| Create | Valid tenant group, city, academic session, board references |
| Setup Status | Tenant records with various setup_status values (pending, completed, failed) |
| Plan Assignment | Active academic session, valid plan + billing cycle, tenant |
| Board Assignment | Tenant with completed setup, academic session in tenant DB, boards |
| Toggles | Existing TenantPlan, TenantPlanModule, Tenant records |
| Soft-Delete | Tenant record with no active dependencies |
| Force-Delete | Soft-deleted tenant with optional archive tenants |
| Archive Access | Live tenant + archive tenant pair |

---

## 7. Test Environment

| Environment | Details |
|-------------|---------|
| **Application** | Prime AI (prime_ai) |
| **Database** | prime_db (seeded: prm_tenant, prm_tenant_groups, prm_tenant_domains, prm_tenant_plan_jnt, prm_tenant_plan_rates, prm_tenant_plan_module_jnt, prm_tenant_plan_billing_schedule) |
| **Queue** | Sync driver preferred for tests; Queue fake for job assertions |
| **Mail** | Mail fake for email assertions |
| **Notification** | Notification fake for in-app notification assertions |
| **Tenancy** | stancl/tenancy configured; tenant databases need to be mockable |

---

## 8. Dependencies

| Dependency | Purpose |
|-----------|---------|
| `SetupTenantDatabase` Job | Async DB provisioning |
| `AcademicSessionRolloverJob` | Session rollover |
| `ArchiveAccessRequestService` | Archive access workflow |
| `TenantRequest` | Tenant create/update validation |
| `TenantPlanRequest` | Plan assignment validation |
| `TenantRegisteredMail` | Welcome email |
| `TenantNotificationMail` | Status/delete/restore notification emails |
| `TenantRegisteredNotification` | Super admin notifications |
| `stancl/tenancy` | Database-per-tenant isolation |
| `Spatie MediaLibrary` | School logo |

---

## 9. Risk & Edge Cases

| Risk | Mitigation |
|------|------------|
| SetupTenantDatabase job is async — tests need queue faking | Use Queue fake to assert job was dispatched |
| Force-delete recursively deletes archives — long operation | Test with minimal archives; mock DB drops |
| Plan assignment transaction spans 5 steps — complex rollback | Test each step failure independently |
| Board assignment runs in tenant DB context — needs tenancy mocking | Use tenancy()->central() / tenant DB fakes |
| Tenant name generation depends on UUID — non-deterministic | Assert pattern match rather than exact string |
| Email sending depends on tenant having email | Test with and without email |

---

## 10. Traceability Matrix

| TC ID | REQ ID | BR ID | Priority | Test Type | Automation Possible |
|-------|--------|-------|:--------:|-----------|:------------------:|
| TC-PRM-TNT-001 | REQ-PRM-001 | — | P0 | UI | Yes |
| TC-PRM-TNT-002 | REQ-PRM-001 | — | P0 | Security | Yes |
| TC-PRM-TNT-003 | REQ-PRM-001 | — | P1 | Functional | Yes |
| TC-PRM-TNT-004 | REQ-PRM-001 | — | P0 | UI | Yes |
| TC-PRM-TNT-005 | REQ-PRM-001 | — | P0 | Security | Yes |
| TC-PRM-TNT-006 | REQ-PRM-001 | — | P0 | Functional | Yes |
| TC-PRM-TNT-007 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-TNT-008 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-TNT-009 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-TNT-010 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-TNT-011 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-TNT-012 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-TNT-013 | REQ-PRM-001 | — | P0 | Security | Yes |
| TC-PRM-TNT-014 | REQ-PRM-001 | — | P0 | UI | Yes |
| TC-PRM-TNT-015 | REQ-PRM-001 | — | P0 | API | Yes |
| TC-PRM-TNT-016 | REQ-PRM-001 | — | P0 | API | Yes |
| TC-PRM-TNT-017 | REQ-PRM-001 | — | P0 | API | Yes |
| TC-PRM-TNT-018 | REQ-PRM-001 | — | P0 | API | Yes |
| TC-PRM-TNT-019 | REQ-PRM-001 | — | P1 | API | Yes |
| TC-PRM-TNT-020 | REQ-PRM-001 | — | P1 | UI | Yes |
| TC-PRM-TNT-021 | REQ-PRM-001 | — | P0 | Functional | Yes |
| TC-PRM-TNT-022 | REQ-PRM-001 | — | P1 | Integration | Yes |
| TC-PRM-TNT-023 | REQ-PRM-001 | — | P0 | Security | Yes |
| TC-PRM-TNT-024 | REQ-PRM-004 | — | P1 | UI | Yes |
| TC-PRM-TNT-025 | REQ-PRM-004 | — | P1 | Functional | Yes |
| TC-PRM-TNT-026 | REQ-PRM-004 | BR-PRM-013 | P0 | Security | Yes |
| TC-PRM-TNT-027 | REQ-PRM-004 | — | P0 | Functional | Yes |
| TC-PRM-TNT-028 | REQ-PRM-004 | BR-PRM-015 | P0 | Functional | Yes |
| TC-PRM-TNT-029 | REQ-PRM-004 | BR-PRM-015 | P0 | Functional | Yes |
| TC-PRM-TNT-030 | REQ-PRM-004 | BR-PRM-003 | P0 | Functional | Yes |
| TC-PRM-TNT-031 | REQ-PRM-004 | BR-PRM-004 | P1 | Functional | Yes |
| TC-PRM-TNT-032 | REQ-PRM-004 | — | P0 | Functional | Yes |
| TC-PRM-TNT-033 | REQ-PRM-004 | BR-PRM-005 | P1 | Functional | Yes |
| TC-PRM-TNT-034 | REQ-PRM-004 | — | P1 | Functional | Yes |
| TC-PRM-TNT-035 | REQ-PRM-004 | — | P0 | Validation | Yes |
| TC-PRM-TNT-036 | REQ-PRM-004 | — | P0 | Security | Yes |
| TC-PRM-TNT-037 | REQ-PRM-005 | — | P1 | API | Yes |
| TC-PRM-TNT-038 | REQ-PRM-005 | — | P1 | API | Yes |
| TC-PRM-TNT-039 | REQ-PRM-005 | — | P1 | API | Yes |
| TC-PRM-TNT-040 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-041 | — | — | P0 | Validation | Yes |
| TC-PRM-TNT-042 | — | — | P1 | Validation | Yes |
| TC-PRM-TNT-043 | — | — | P1 | Validation | Yes |
| TC-PRM-TNT-044 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-045 | — | — | P0 | API | Yes |
| TC-PRM-TNT-046 | — | — | P0 | API | Yes |
| TC-PRM-TNT-047 | — | — | P1 | Validation | Yes |
| TC-PRM-TNT-048 | — | — | P0 | Security | Yes |
| TC-PRM-TNT-049 | — | — | P0 | Functional | Yes |
| TC-PRM-TNT-050 | — | — | P1 | UI | Yes |
| TC-PRM-TNT-051 | — | — | P0 | Functional | Yes |
| TC-PRM-TNT-052 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-053 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-054 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-055 | — | — | P0 | Security | Yes |
| TC-PRM-TNT-056 | — | — | P0 | Security | Yes |
| TC-PRM-TNT-057 | — | — | P0 | Security | Yes |
| TC-PRM-TNT-058 | REQ-PRM-001 | — | P1 | Functional | Yes |
| TC-PRM-TNT-059 | REQ-PRM-001 | — | P1 | Functional | Yes |
| TC-PRM-TNT-060 | REQ-PRM-001 | BR-PRM-008 | P1 | Validation | Yes |
| TC-PRM-TNT-061 | REQ-PRM-001 | — | P2 | Functional | Yes |
| TC-PRM-TNT-062 | REQ-PRM-009 | — | P1 | Functional | Yes |
| TC-PRM-TNT-063 | REQ-PRM-009 | — | P0 | Validation | Yes |
| TC-PRM-TNT-064 | REQ-PRM-009 | — | P1 | API | Yes |
| TC-PRM-TNT-065 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-066 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-067 | — | — | P1 | Functional | Yes |
| TC-PRM-TNT-068 | — | — | P1 | Functional | Yes |
