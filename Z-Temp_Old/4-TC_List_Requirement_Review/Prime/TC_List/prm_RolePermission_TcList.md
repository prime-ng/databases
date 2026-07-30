# Role & Permission Management — Test Case List

**Feature:** Role & Permission Management | **REQ-ID:** REQ-PRM-008 | **Controller:** `RolePermissionController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 45 | — | — | — | 45 | 0% |

---

## 2. Index/List — Role List (`GET /prime/role-permission`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-RP-001 | Verify role list loads with all roles and permissions | Multiple roles with permissions exist | — | All roles displayed with eager-loaded permissions | — | — | ⬜ |
| TC-PRM-RP-002 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login | — | — | ⬜ |
| TC-PRM-RP-003 | Verify user without viewAny permission receives 403 | Authenticated without `prime.role-permission.viewAny` | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-RP-004 | Verify getRolesByOrganization filters correctly | Organization with assigned roles exists | organizationId=1 | Only roles for that organization displayed | — | — | ⬜ |
| TC-PRM-RP-005 | Verify getRolesByOrganization with non-existent org | Organization ID 99999 | organizationId=99999 | 404 Not Found | — | — | ⬜ |

---

## 3. Create/Store — Role Create (`GET /prime/role-permission/create` + `POST /prime/role-permission`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-RP-006 | Verify create form loads with grouped permissions | Permissions with module.feature.action format exist | — | Create form renders; permissions grouped by Module > Feature | — | — | ⬜ |
| TC-PRM-RP-007 | Verify valid role creation with permissions | Valid permissions exist | name=Manager, short_name=MGR, description=Manager role, is_system=false, permissions=["prime.tenant.viewAny","prime.tenant.create"] | Role created; permissions synced; activity log written; redirect | — | — | ⬜ |
| TC-PRM-RP-008 | Verify duplicate role name rejected | Existing role "Manager" | name=Manager | Validation error: name already exists | — | — | ⬜ |
| TC-PRM-RP-009 | Verify duplicate short_name rejected | Existing role with short_name=MGR | short_name=MGR | Validation error: short_name already exists | — | — | ⬜ |
| TC-PRM-RP-010 | Verify invalid permission rejected | Non-existent permission name | permissions=["non.existent.action"] | Validation error: permission does not exist in sys_permissions | — | — | ⬜ |
| TC-PRM-RP-011 | Verify user without create permission receives 403 | Authenticated without `prime.role-permission.create` | — | 403 Forbidden | — | — | ⬜ |

---

## 4. Show — Role Detail (`GET /prime/role-permission/{role_permission}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-RP-012 | Verify role detail shows structured permissions | Role with permissions exists | — | Permissions displayed hierarchically (module > feature > action); users with role listed | — | — | ⬜ |
| TC-PRM-RP-013 | Verify role detail with no permissions | Role with no permissions | — | Empty permissions structure; users list may be empty | — | — | ⬜ |
| TC-PRM-RP-014 | Verify non-existent role returns 404 | Role ID 99999 doesn't exist | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-RP-015 | Verify user without view permission receives 403 | Authenticated without `prime.role-permission.view` | — | 403 Forbidden | — | — | ⬜ |

---

## 5. Edit/Update — Role Edit (`GET /prime/role-permission/{role_permission}/edit` + `PUT /prime/role-permission/{role_permission}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-RP-016 | Verify edit form loads with pre-selected permissions | Role with assigned permissions exists | — | Edit form renders; permissions display with "assigned" flags | — | — | ⬜ |
| TC-PRM-RP-017 | Verify valid update changes role metadata and permissions | Existing role | name=UpdatedRole, short_name=UPR, permissions=["prime.tenant.viewAny"] | Role metadata updated; permissions synced; activity log with changes; redirect | — | — | ⬜ |
| TC-PRM-RP-018 | Verify update with no changes creates audit log | Existing role; submit same data | name=same as before | Redirect; activity log: "No attributes changed." | — | — | ⬜ |
| TC-PRM-RP-019 | Verify user without update permission receives 403 | Authenticated without `prime.role-permission.update` | — | 403 Forbidden | — | — | ⬜ |

---

## 6. Delete — Role Delete (`DELETE /prime/role-permission/{role_permission}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-RP-020 | Verify role delete removes role | Existing role without users | — | Role deleted; activity log written; redirect | — | — | ⬜ |
| TC-PRM-RP-021 | Verify user without delete permission receives 403 | Authenticated without `prime.role-permission.delete` | — | 403 Forbidden | — | — | ⬜ |

---

## 7. Trash/Restore/Force-Delete

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-RP-022 | Verify trashed view returns info about no soft-deletes | — | — | Info message: "Soft deletes are not enabled for roles." | — | — | ⬜ |
| TC-PRM-RP-023 | Verify restore returns info about no soft-deletes | — | — | Info message: "Soft deletes are not enabled for roles." | — | — | ⬜ |
| TC-PRM-RP-024 | Verify forceDelete deletes the role permanently | Existing role | — | Role deleted; activity log "Role permanently deleted."; redirect | — | — | ⬜ |

---

## 8. Custom Permission Endpoints

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-RP-025 | Verify updateRolePermission enables a permission | Role without a specific permission | permission="prime.tenant.create", enabled=true | Permission granted to role; JSON success | — | — | ⬜ |
| TC-PRM-RP-026 | Verify updateRolePermission disables a permission | Role with a specific permission | permission="prime.tenant.create", enabled=false | Permission revoked from role; JSON success | — | — | ⬜ |
| TC-PRM-RP-027 | Verify updateRolePermission with invalid permission name | — | permission="invalid.name", enabled=true | Validation error: permission does not exist | — | — | ⬜ |
| TC-PRM-RP-028 | Verify updatePermissions bulk sync replaces all permissions | Role with 3 permissions | permissions=["prime.tenant.viewAny","prime.user.viewAny"] | Role now has exactly 2 permissions; JSON success | — | — | ⬜ |
| TC-PRM-RP-029 | Verify updatePermissions with empty array removes all | Role with permissions | permissions=[] | Role has 0 permissions; JSON success | — | — | ⬜ |
| TC-PRM-RP-030 | Verify getPermissions returns permission names | Role with 2 permissions | — | JSON `{ permissions: ["prime.tenant.viewAny", "prime.tenant.create"] }` | — | — | ⬜ |
| TC-PRM-RP-031 | Verify getPermissions with role having no permissions | Role with no permissions | — | JSON `{ permissions: [] }` | — | — | ⬜ |
| TC-PRM-RP-032 | Verify getPermissions without view permission | Authenticated without `prime.role-permission.view` | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-RP-033 | Verify updateRolePermission without update permission | Authenticated without `prime.role-permission.update` | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-RP-034 | Verify updatePermissions without update permission | Authenticated without `prime.role-permission.update` | — | 403 Forbidden | — | — | ⬜ |

---

## 9. Permissions Matrix

| Role | viewAny | create | view | update | delete | restore | forceDelete |
|------|:-------:|:------:|:----:|:------:|:------:|:-------:|:-----------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Platform Finance | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Platform IT/Ops | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 10. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-RP-001 | REQ-PRM-008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-RP-002 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-003 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-004 | REQ-PRM-008 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-RP-005 | REQ-PRM-008 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-RP-006 | REQ-PRM-008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-RP-007 | REQ-PRM-008 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-RP-008 | REQ-PRM-008 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-RP-009 | REQ-PRM-008 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-RP-010 | REQ-PRM-008 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-RP-011 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-012 | REQ-PRM-008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-RP-013 | REQ-PRM-008 | — | Positive/Edge | P2 | Functional | ⬜ |
| TC-PRM-RP-014 | REQ-PRM-008 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-RP-015 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-016 | REQ-PRM-008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-RP-017 | REQ-PRM-008 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-RP-018 | REQ-PRM-008 | BR-PRM-023 | Positive/Edge | P1 | Functional | ⬜ |
| TC-PRM-RP-019 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-020 | REQ-PRM-008 | BR-PRM-023 | Positive/Delete | P0 | Functional | ⬜ |
| TC-PRM-RP-021 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-022 | REQ-PRM-008 | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-RP-023 | REQ-PRM-008 | — | Positive/UI | P2 | Functional | ⬜ |
| TC-PRM-RP-024 | REQ-PRM-008 | BR-PRM-023 | Positive/Force-Delete | P0 | Functional | ⬜ |
| TC-PRM-RP-025 | REQ-PRM-008 | BR-PRM-020 | Positive | P0 | Functional | ⬜ |
| TC-PRM-RP-026 | REQ-PRM-008 | BR-PRM-020 | Positive | P0 | Functional | ⬜ |
| TC-PRM-RP-027 | REQ-PRM-008 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-RP-028 | REQ-PRM-008 | — | Positive/Bulk-Sync | P0 | Functional | ⬜ |
| TC-PRM-RP-029 | REQ-PRM-008 | — | Positive/Edge | P1 | Functional | ⬜ |
| TC-PRM-RP-030 | REQ-PRM-008 | BR-PRM-020 | Positive/API | P0 | Functional | ⬜ |
| TC-PRM-RP-031 | REQ-PRM-008 | BR-PRM-020 | Positive/API | P1 | Functional | ⬜ |
| TC-PRM-RP-032 | REQ-PRM-008 | BR-PRM-020 | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-033 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-RP-034 | REQ-PRM-008 | — | Security/Auth | P0 | Security | ⬜ |

---

## 11. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | `trashedRolePermission()` and `restore()` are stubs returning info messages | TC-PRM-RP-022, TC-PRM-RP-023 | Low | ⬜ |
| 2 | FormRequest from cross-module dependency (`Modules\SchoolSetup`) | — | Medium | ⬜ |
| 3 | No feature tests exist | All TCs | High | ⬜ |

---

## 12. Route Reference

| Method | URI | Name |
|--------|-----|------|
| GET | `/prime/role-permission` | `central.prime.role-permission.index` |
| GET | `/prime/role-permission/create` | `central.prime.role-permission.create` |
| POST | `/prime/role-permission` | `central.prime.role-permission.store` |
| GET | `/prime/role-permission/{role_permission}` | `central.prime.role-permission.show` |
| GET | `/prime/role-permission/{role_permission}/edit` | `central.prime.role-permission.edit` |
| PUT | `/prime/role-permission/{role_permission}` | `central.prime.role-permission.update` |
| DELETE | `/prime/role-permission/{role_permission}` | `central.prime.role-permission.destroy` |
| GET | `/prime/role-permission/{organization}/get-roles` | `central.prime.role-permission.getRolesByOrganization` |
| GET | `/prime/role-permission/trash/view` | `central.prime.role-permission.trashed` |
| GET | `/prime/role-permission/{id}/restore` | `central.prime.role-permission.restore` |
| DELETE | `/prime/role-permission/{id}/force-delete` | `central.prime.role-permission.forceDelete` |
| PATCH | `/prime/role-permission/{role}/update` | `central.prime.role-permission.updateRolePermission` |
| GET | `/prime/role-permission/{role}/permissions` | (inline) |
| POST | `/prime/role-permission/{role}/permissions/update` | (inline) |

---

## 13. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-RP-001 | ⬜ | — | — | — | — |
| ... (all 34 TCs) | ⬜ | — | — | — | — |
