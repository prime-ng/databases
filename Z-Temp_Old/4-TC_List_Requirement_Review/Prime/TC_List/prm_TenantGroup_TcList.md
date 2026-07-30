# Prime (PRM) — Tenant Group Management Test Case List

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Tenant Group Management |
| **Sub-Features** | Group CRUD, Soft-Delete/Restore/Force-Delete, Status Toggle |
| **FRD Reference** | REQ-PRM-002 (School Group Management) |
| **Controller** | `TenantGroupController` |
| **Model** | `TenantGroup` (table: `prm_tenant_groups`) |
| **TC List Version** | V1 |
| **CR ID** | ◌ |

---

## 2. Test Case Summary

| TC Total | TC Auto | TC Manual | TC Skipped | Blocked | Removed |
|:--------:|:-------:|:---------:|:----------:|:-------:|:-------:|
| 24 | 0 | 24 | — | — | — |

---

## 3. Test Cases

### 3.1 Group CRUD — List, Create, Show, Edit

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-GRP-001 | Verify group list displays all groups | Multiple groups exist | GET /prime/tenant-group | List of groups displayed | — | ⬜ | — | ◌ |
| TC-PRM-GRP-002 | Verify group list is denied without permission | User lacks prime.tenant-group.viewAny | GET /prime/tenant-group | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-GRP-003 | Verify create form loads | User has create permission | GET /prime/tenant-group/create | Create form displayed | — | ⬜ | — | ◌ |
| TC-PRM-GRP-004 | Verify create form is denied without permission | User lacks prime.tenant-group.create | GET /prime/tenant-group/create | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-GRP-005 | Verify group created with valid data including email | Valid input with email | POST /prime/tenant-group (all valid fields) | Group created; email sent to group email; super admins notified; activity logged; redirect with success | — | ⬜ | — | ◌ |
| TC-PRM-GRP-006 | Verify group created without email (email not provided) | Valid input without email | POST /prime/tenant-group (no email) | Group created; super admins notified; flash: "No email provided" | — | ⬜ | — | ◌ |
| TC-PRM-GRP-007 | Verify group creation validates required fields | Missing required data | POST /prime/tenant-group (empty) | Validation errors for code, short_name, name, city_id | — | ⬜ | — | ◌ |
| TC-PRM-GRP-008 | Verify group creation validates unique short_name | Duplicate short_name | POST /prime/tenant-group (existing short_name) | Validation error: short_name already taken | — | ⬜ | — | ◌ |
| TC-PRM-GRP-009 | Verify group creation validates unique name | Duplicate name | POST /prime/tenant-group (existing name) | Validation error: name already taken | — | ⬜ | — | ◌ |
| TC-PRM-GRP-010 | Verify group creation validates city existence | Non-existent city_id | POST /prime/tenant-group (city_id=99999) | Validation error: invalid city | — | ⬜ | — | ◌ |
| TC-PRM-GRP-011 | Verify group creation denied without permission | User lacks prime.tenant-group.create | POST /prime/tenant-group (valid) | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-GRP-012 | Verify show displays group details with city and tenants | Group exists | GET /prime/tenant-group/{id} | Group details with city name and associated tenants | — | ⬜ | — | ◌ |
| TC-PRM-GRP-013 | Verify edit form pre-fills with existing data | Group exists | GET /prime/tenant-group/{id}/edit | Form pre-filled with group data | — | ⬜ | — | ◌ |

### 3.2 Group Update

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-GRP-014 | Verify group updates successfully | Group exists | PUT /prime/tenant-group/{id} (updated name) | Group updated; redirect with success | — | ⬜ | — | ◌ |
| TC-PRM-GRP-015 | Verify group update validates unique short_name (ignores current) | Current group's short_name | PUT /prime/tenant-group/{id} (same short_name) | Update succeeds (unique rule ignores current record) | — | ⬜ | — | ◌ |
| TC-PRM-GRP-016 | Verify group update denied without permission | User lacks prime.tenant-group.update | PUT /prime/tenant-group/{id} | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.3 Soft-Delete, Restore & Force-Delete

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-GRP-017 | Verify group soft-delete deactivates and trashes | Group exists, no active tenants | DELETE /prime/tenant-group/{id} | is_active=false; soft-deleted; activity logged; redirect with success | — | ⬜ | — | ◌ |
| TC-PRM-GRP-018 | Verify group delete blocked with active tenants (BR-PRM-014) | Group has active tenants | DELETE /prime/tenant-group/{id} | Business-language error: "This group has active schools and cannot be deleted" (currently SQL error — known gap) | — | ⬜ | — | ◌ |
| TC-PRM-GRP-019 | Verify soft-deleted group appears in trash | Soft-deleted group exists | GET /prime/tenant-group/trash/view | Trash list with soft-deleted groups | — | ⬜ | — | ◌ |
| TC-PRM-GRP-020 | Verify soft-deleted group can be restored | Group soft-deleted | GET /prime/tenant-group/{id}/restore | Group restored; activity logged; redirect with success | — | ⬜ | — | ◌ |
| TC-PRM-GRP-021 | Verify soft-deleted group can be force-deleted | Group soft-deleted | DELETE /prime/tenant-group/{id}/force-delete | Group permanently deleted; activity logged; redirect with success | — | ⬜ | — | ◌ |
| TC-PRM-GRP-022 | Verify delete/restore/forceDelete denied without permission | User lacks respective permission | Various | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.4 Status Toggle

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-GRP-023 | Verify group status toggled via AJAX | Group exists | POST /prime/tenant-group/{id}/toggle-status (is_active=1) | is_active updated; activity logged; JSON success response | — | ⬜ | — | ◌ |
| TC-PRM-GRP-024 | Verify group toggle validates is_active | Missing is_active | POST /prime/tenant-group/{id}/toggle-status | Validation error: is_active required | — | ⬜ | — | ◌ |

---

## 4. Requirements Coverage

| REQ ID | Feature | TC Coverage |
|--------|---------|:-----------:|
| REQ-PRM-002 | School Group Management | TC-PRM-GRP-001 to TC-PRM-GRP-024 |

---

## 5. Business Rules Coverage

| BR ID | Rule | TC Coverage |
|-------|------|:-----------:|
| BR-PRM-014 | Group delete blocked by active schools | TC-PRM-GRP-018 (known gap) |
| BR-PRM-023 | Activity log for state-changing operations | TC-PRM-GRP-005, TC-PRM-GRP-014, TC-PRM-GRP-017, TC-PRM-GRP-020, TC-PRM-GRP-021, TC-PRM-GRP-023 |

---

## 6. Data Setup Requirements

| TC Group | Data Needed |
|----------|-------------|
| CRUD | Multiple groups in prm_tenant_groups; valid city references in glb_cities |
| Create-with-email | Group with valid email; working mailer (or mock) |
| Delete-blocked | Group with at least one associated tenant (prm_tenant.tenant_group_id) |
| Trash/restore | Soft-deleted group record |
| Toggle | Active group with is_active flag |

---

## 7. Test Environment

| Environment | Details |
|-------------|---------|
| **Application** | Prime AI (prime_ai) |
| **Database** | prime_db (seeded: prm_tenant_groups, glb_cities) |
| **Mail** | Mail fake for email assertions |
| **Notification** | Notification fake for super admin notification assertions |

---

## 8. Dependencies

| Dependency | Purpose |
|-----------|---------|
| `TenantGroupRequest` | Create/update validation |
| `TenantGroupCreatedMail` | Group creation email |
| `TenantGroupCreatedNotification` | Super admin notification |
| `City` model | FK reference for city_id |

---

## 9. Risk & Edge Cases

| Risk | Mitigation |
|------|------------|
| Delete blocked by active tenants produces SQL error (BR-PRM-014 gap) | Test documents the gap; friendly message needs implementation |
| Email failure on group creation is non-blocking but may go unnoticed | Check flash message includes email status |
| Unique short_name/name constraints prevent duplicates | Already enforced via FormRequest |
| Toggle status with missing field returns validation error | Already handled via is_active boolean rule |

---

## 10. Traceability Matrix

| TC ID | REQ ID | BR ID | Priority | Test Type | Automation Possible |
|-------|--------|-------|:--------:|-----------|:------------------:|
| TC-PRM-GRP-001 | REQ-PRM-002 | — | P0 | UI | Yes |
| TC-PRM-GRP-002 | REQ-PRM-002 | — | P0 | Security | Yes |
| TC-PRM-GRP-003 | REQ-PRM-002 | — | P0 | UI | Yes |
| TC-PRM-GRP-004 | REQ-PRM-002 | — | P0 | Security | Yes |
| TC-PRM-GRP-005 | REQ-PRM-002 | — | P0 | Functional | Yes |
| TC-PRM-GRP-006 | REQ-PRM-002 | — | P1 | Functional | Yes |
| TC-PRM-GRP-007 | REQ-PRM-002 | — | P0 | Validation | Yes |
| TC-PRM-GRP-008 | REQ-PRM-002 | — | P0 | Validation | Yes |
| TC-PRM-GRP-009 | REQ-PRM-002 | — | P0 | Validation | Yes |
| TC-PRM-GRP-010 | REQ-PRM-002 | — | P0 | Validation | Yes |
| TC-PRM-GRP-011 | REQ-PRM-002 | — | P0 | Security | Yes |
| TC-PRM-GRP-012 | REQ-PRM-002 | — | P1 | UI | Yes |
| TC-PRM-GRP-013 | REQ-PRM-002 | — | P1 | UI | Yes |
| TC-PRM-GRP-014 | REQ-PRM-002 | — | P0 | Functional | Yes |
| TC-PRM-GRP-015 | REQ-PRM-002 | — | P1 | Validation | Yes |
| TC-PRM-GRP-016 | REQ-PRM-002 | — | P0 | Security | Yes |
| TC-PRM-GRP-017 | REQ-PRM-002 | — | P0 | Functional | Yes |
| TC-PRM-GRP-018 | REQ-PRM-002 | BR-PRM-014 | P1 | Functional | Yes |
| TC-PRM-GRP-019 | REQ-PRM-002 | — | P1 | UI | Yes |
| TC-PRM-GRP-020 | REQ-PRM-002 | — | P0 | Functional | Yes |
| TC-PRM-GRP-021 | REQ-PRM-002 | — | P1 | Functional | Yes |
| TC-PRM-GRP-022 | REQ-PRM-002 | — | P0 | Security | Yes |
| TC-PRM-GRP-023 | REQ-PRM-002 | — | P0 | API | Yes |
| TC-PRM-GRP-024 | REQ-PRM-002 | — | P1 | Validation | Yes |
