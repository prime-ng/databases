# Prime (PRM) — Tenant Domain Management Test Case List

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Tenant Domain Management |
| **Sub-Features** | Domain CRUD, Search, Status Toggle |
| **FRD Reference** | REQ-PRM-001 (School Registration — domain creation sub-step) |
| **Controller** | `TenantDomainController` |
| **Model** | `Domain` (table: `prm_tenant_domains`) |
| **TC List Version** | V1 |
| **CR ID** | ◌ |

---

## 2. Test Case Summary

| TC Total | TC Auto | TC Manual | TC Skipped | Blocked | Removed |
|:--------:|:-------:|:---------:|:----------:|:-------:|:-------:|
| 22 | 0 | 22 | — | — | — |

---

## 3. Test Cases

### 3.1 Domain CRUD — List & Search

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DMN-001 | Verify domain list displays all domains | Multiple domains exist | GET /prime/tenant-domain | Paginated list with tenant names displayed | — | ⬜ | — | ◌ |
| TC-PRM-DMN-002 | Verify domain list is denied without permission | User lacks prime.tenant-domain.viewAny | GET /prime/tenant-domain | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-DMN-003 | Verify search by domain name returns matching domains | Domains exist with known name | GET /prime/tenant-domain?search=test | Only domains containing "test" in domain field returned | — | ⬜ | — | ◌ |
| TC-PRM-DMN-004 | Verify search by tenant name returns matching domains | Domains with known tenant name | GET /prime/tenant-domain?search=Greenwood | Only domains belonging to "Greenwood" tenant returned | — | ⬜ | — | ◌ |
| TC-PRM-DMN-005 | Verify search with no matches returns empty list | No matching domains | GET /prime/tenant-domain?search=ZZZZNOTEXIST | Empty paginated list displayed | — | ⬜ | — | ◌ |

### 3.2 Domain CRUD — Create

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DMN-006 | Verify create form loads with tenant dropdown | Active tenants exist | GET /prime/tenant-domain/create | Form with tenant dropdown displayed | — | ⬜ | — | ◌ |
| TC-PRM-DMN-007 | Verify create form is denied without permission | User lacks prime.tenant-domain.create | GET /prime/tenant-domain/create | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-DMN-008 | Verify domain created with all valid fields | Valid tenant, unique domain | POST /prime/tenant-domain (all valid) | Domain created; db_password encrypted; activity logged; redirect to index | — | ⬜ | — | ◌ |
| TC-PRM-DMN-009 | Verify domain creation validates all required fields | Missing fields | POST /prime/tenant-domain (empty) | Validation errors for all required fields | — | ⬜ | — | ◌ |
| TC-PRM-DMN-010 | Verify domain creation validates unique domain | Existing domain | POST /prime/tenant-domain (duplicate domain) | Validation error: domain already taken | — | ⬜ | — | ◌ |
| TC-PRM-DMN-011 | Verify domain creation validates tenant existence | Non-existent tenant_id | POST /prime/tenant-domain (tenant_id=99999) | Validation error: invalid tenant | — | ⬜ | — | ◌ |
| TC-PRM-DMN-012 | Verify domain creation denied without permission | User lacks prime.tenant-domain.create | POST /prime/tenant-domain (valid) | 403 Access Denied | — | ⬜ | — | ◌ |
| TC-PRM-DMN-013 | Verify domain is_active flag set to 1 when checked | Checkbox checked | POST /prime/tenant-domain (is_active checked) | Domain is_active = true | — | ⬜ | — | ◌ |
| TC-PRM-DMN-014 | Verify domain is_active flag set to 0 when unchecked | Checkbox unchecked | POST /prime/tenant-domain (is_active unchecked) | Domain is_active = false | — | ⬜ | — | ◌ |

### 3.3 Domain Show & Edit

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DMN-015 | Verify show displays domain details with tenant | Domain exists | GET /prime/tenant-domain/{id} | Domain details with tenant name displayed | — | ⬜ | — | ◌ |
| TC-PRM-DMN-016 | Verify edit form pre-fills with existing details | Domain exists | GET /prime/tenant-domain/{id}/edit | Form pre-filled with domain data (domain name not editable) | — | ⬜ | — | ◌ |

### 3.4 Domain Update

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DMN-017 | Verify domain update with new db_password | Domain exists | PUT /prime/tenant-domain/{id} (new db_password) | db_password updated and encrypted; activity logged; redirect to index | — | ⬜ | — | ◌ |
| TC-PRM-DMN-018 | Verify domain update preserves db_password when empty | Domain exists | PUT /prime/tenant-domain/{id} (db_password empty) | Existing db_password kept unchanged | — | ⬜ | — | ◌ |
| TC-PRM-DMN-019 | Verify domain update denied without permission | User lacks prime.tenant-domain.update | PUT /prime/tenant-domain/{id} | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.5 Domain Soft-Delete

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DMN-020 | Verify domain soft-delete | Domain exists | DELETE /prime/tenant-domain/{id} | Domain soft-deleted; activity logged; redirect to index | — | ⬜ | — | ◌ |
| TC-PRM-DMN-021 | Verify domain delete denied without permission | User lacks prime.tenant-domain.delete | DELETE /prime/tenant-domain/{id} | 403 Access Denied | — | ⬜ | — | ◌ |

### 3.6 Domain Status Toggle

| ID | Test Case | Precondition | Test Data | Expected Result | Actual Result | Status | V1/V2 | CR |
|----|-----------|-------------|-----------|----------------|---------------|--------|-------|----|
| TC-PRM-DMN-022 | Verify domain status toggle via AJAX | Domain exists | POST /prime/tenant-domain/{id}/toggle-status (is_active=1) | is_active updated; activity logged; JSON success response | — | ⬜ | — | ◌ |

---

## 4. Requirements Coverage

| REQ ID | Feature | TC Coverage |
|--------|---------|:-----------:|
| REQ-PRM-001 | School Registration (domain creation) | TC-PRM-DMN-006 to TC-PRM-DMN-014 |

---

## 5. Business Rules Coverage

| BR ID | Rule | TC Coverage |
|-------|------|:-----------:|
| BR-PRM-006 | Database password encrypted at rest | TC-PRM-DMN-008, TC-PRM-DMN-017 |
| BR-PRM-010 | Tenant model implements HasDomains | Architecture check (not UI-testable) |

---

## 6. Data Setup Requirements

| TC Group | Data Needed |
|----------|-------------|
| List/search | Multiple domains in prm_tenant_domains with different tenants |
| Create | Valid tenant with is_active=true; unique domain string |
| Update | Existing domain record |
| Delete | Existing domain with no hard dependencies |
| Toggle | Existing domain record |

---

## 7. Test Environment

| Environment | Details |
|-------------|---------|
| **Application** | Prime AI (prime_ai) |
| **Database** | prime_db (seeded: prm_tenant_domains, prm_tenant) |
| **Encryption** | SafeEncrypted cast active on db_password |

---

## 8. Dependencies

| Dependency | Purpose |
|-----------|---------|
| `SafeEncrypted` cast | db_password encryption |
| `Tenant` model | FK reference and dropdown source |
| `stancl/tenancy` BaseDomain | Domain model extends BaseDomain |

---

## 9. Risk & Edge Cases

| Risk | Mitigation |
|------|------------|
| db_password encryption may produce string > 255 chars | DDL column may need expansion to VARCHAR(500) (BR-PRM-006 gap) |
| No restore/force-delete for domains | Soft-deleted domains remain in DB with no UI recovery path |
| domain/tenant_id not editable after creation | Must delete and re-create to change; test documents this limitation |
| Transaction rollback on exception | Test happy path and exception path separately |
| is_active checkbox normalization may behave differently by browser | Test both checked and unchecked states |

---

## 10. Traceability Matrix

| TC ID | REQ ID | BR ID | Priority | Test Type | Automation Possible |
|-------|--------|-------|:--------:|-----------|:------------------:|
| TC-PRM-DMN-001 | — | — | P0 | UI | Yes |
| TC-PRM-DMN-002 | — | — | P0 | Security | Yes |
| TC-PRM-DMN-003 | — | — | P1 | Functional | Yes |
| TC-PRM-DMN-004 | — | — | P1 | Functional | Yes |
| TC-PRM-DMN-005 | — | — | P1 | Functional | Yes |
| TC-PRM-DMN-006 | REQ-PRM-001 | — | P0 | UI | Yes |
| TC-PRM-DMN-007 | REQ-PRM-001 | — | P0 | Security | Yes |
| TC-PRM-DMN-008 | REQ-PRM-001 | BR-PRM-006 | P0 | Functional | Yes |
| TC-PRM-DMN-009 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-DMN-010 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-DMN-011 | REQ-PRM-001 | — | P0 | Validation | Yes |
| TC-PRM-DMN-012 | REQ-PRM-001 | — | P0 | Security | Yes |
| TC-PRM-DMN-013 | REQ-PRM-001 | — | P1 | Functional | Yes |
| TC-PRM-DMN-014 | REQ-PRM-001 | — | P1 | Functional | Yes |
| TC-PRM-DMN-015 | — | — | P1 | UI | Yes |
| TC-PRM-DMN-016 | — | — | P1 | UI | Yes |
| TC-PRM-DMN-017 | — | BR-PRM-006 | P0 | Functional | Yes |
| TC-PRM-DMN-018 | — | — | P1 | Functional | Yes |
| TC-PRM-DMN-019 | — | — | P0 | Security | Yes |
| TC-PRM-DMN-020 | — | — | P0 | Functional | Yes |
| TC-PRM-DMN-021 | — | — | P0 | Security | Yes |
| TC-PRM-DMN-022 | — | — | P0 | API | Yes |
