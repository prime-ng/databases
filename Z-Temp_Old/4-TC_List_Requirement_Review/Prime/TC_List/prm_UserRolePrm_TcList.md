# User Role PRM (Combined Tab View) — Test Case List

**Feature:** User Role PRM (Combined View) | **REQ-ID:** REQ-PRM-007 / REQ-PRM-008 | **Controller:** `UserRolePrmController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 22 | — | — | — | 22 | 0% |

---

## 2. Index — Combined Tab View (`GET /prime/user-role-prm`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-URP-001 | Verify combined view loads with default "user" tab | Authenticated with `prime.role-permission.viewAny` | — | Tabbed view renders; User tab active by default | — | — | ⬜ |
| TC-PRM-URP-002 | Verify "role-permisons" tab loads roles list | Roles with permissions exist | tab=role-permisons | Role tab active; paginated roles list with permissions shown | — | — | ⬜ |
| TC-PRM-URP-003 | Verify User tab shows all users by default | 10+ users exist | tab=user | Paginated user list (10/page) ordered by is_super_admin DESC then name ASC | — | — | ⬜ |
| TC-PRM-URP-004 | Verify stats cards show correct counts | Users in various states | — | totalUsers, activeUsers, superAdminCount, noRoleCount displayed accurately | — | — | ⬜ |
| TC-PRM-URP-005 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login | — | — | ⬜ |
| TC-PRM-URP-006 | Verify user without viewAny permission receives 403 | Authenticated without `prime.role-permission.viewAny` | — | 403 Forbidden | — | — | ⬜ |

---

## 3. User Tab — Filters

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-URP-007 | Verify filter by specific role returns only those users | Multiple users with role ID 2 | tab=user&role=2 | Only users with role ID 2 displayed | — | — | ⬜ |
| TC-PRM-URP-008 | Verify filter by "no-role" returns users without any role | Users without any roles exist | tab=user&role=no-role | Only users with no roles displayed | — | — | ⬜ |
| TC-PRM-URP-009 | Verify search by name filters results | Users exist with "John" in name | tab=user&search=John | Only users with "John" in name displayed | — | — | ⬜ |
| TC-PRM-URP-010 | Verify search by email filters results | Users exist with "test" in email | tab=user&search=test | Only users with "test" in email displayed | — | — | ⬜ |
| TC-PRM-URP-011 | Verify status filter shows only active users | Mix of active/inactive users | tab=user&status=1 | Only active users (is_active=1) displayed | — | — | ⬜ |
| TC-PRM-URP-012 | Verify status filter shows only inactive users | Mix of active/inactive users | tab=user&status=0 | Only inactive users (is_active=0) displayed | — | — | ⬜ |
| TC-PRM-URP-013 | Verify combined filters (role + search + status) work together | — | tab=user&role=2&search=John&status=1 | Results intersection of all filters | — | — | ⬜ |
| TC-PRM-URP-014 | Verify pagination query string preserved across tab switch | 10+ users | tab=user&page=2 | Page 2 loads with tab fragment #user | — | — | ⬜ |

---

## 4. Search API (`GET /prime/user-role-prm/search`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-URP-015 | Verify search by user name returns matching users | Users with "Jane" in name | q=Jane&type=user | JSON array of users with id and name, limited to 10 | — | — | ⬜ |
| TC-PRM-URP-016 | Verify search by role name returns matching roles | Roles with "Admin" in name | q=Admin&type=role | JSON array of roles with id and name, limited to 10 | — | — | ⬜ |
| TC-PRM-URP-017 | Verify search with no query returns empty | — | q=&type=user | Empty JSON array | — | — | ⬜ |
| TC-PRM-URP-018 | Verify search with invalid type returns empty | — | q=test&type=invalid | Empty JSON array | — | — | ⬜ |
| TC-PRM-URP-019 | Verify search with no results returns empty | — | q=zzzxxxyyy&type=user | Empty JSON array | — | — | ⬜ |

---

## 5. Role-Permissions Tab Data

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-URP-020 | Verify role-permissions tab shows paginated roles with permissions | 10+ roles exist | tab=role-permisons | Paginated roles (10/page) with eager-loaded permissions | — | — | ⬜ |
| TC-PRM-URP-021 | Verify all roles for dropdown filter are loaded | Multiple roles exist | — | allRoles includes all roles with user counts, sorted by name | — | — | ⬜ |
| TC-PRM-URP-022 | Verify tab fragment preserved in URL | — | tab=user#user | URL fragment #user present | — | — | ⬜ |

---

## 6. Permissions Matrix

| Role | viewAny (index) |
|------|:---------------:|
| Super Admin | ✅ |
| Platform Manager | ❌ |
| Platform Finance | ❌ |
| Platform IT/Ops | ❌ |

**Note:** Index uses `prime.role-permission.viewAny` permission gate.

---

## 7. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-URP-001 | REQ-PRM-007/008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-URP-002 | REQ-PRM-008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-URP-003 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-URP-004 | REQ-PRM-007 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-URP-005 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-URP-006 | REQ-PRM-007 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-URP-007 | REQ-PRM-007 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-URP-008 | REQ-PRM-007 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-URP-009 | REQ-PRM-007 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-URP-010 | REQ-PRM-007 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-URP-011 | REQ-PRM-007 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-URP-012 | REQ-PRM-007 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-URP-013 | REQ-PRM-007 | — | Positive/Combo | P1 | Functional | ⬜ |
| TC-PRM-URP-014 | REQ-PRM-007 | — | Pagination | P2 | Functional | ⬜ |
| TC-PRM-URP-015 | REQ-PRM-007 | — | Positive/API | P1 | Functional | ⬜ |
| TC-PRM-URP-016 | REQ-PRM-008 | — | Positive/API | P1 | Functional | ⬜ |
| TC-PRM-URP-017 | REQ-PRM-007 | — | Negative/Edge | P2 | Functional | ⬜ |
| TC-PRM-URP-018 | REQ-PRM-007 | — | Negative/Edge | P2 | Functional | ⬜ |
| TC-PRM-URP-019 | REQ-PRM-007 | — | Negative/Edge | P2 | Functional | ⬜ |
| TC-PRM-URP-020 | REQ-PRM-008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-URP-021 | REQ-PRM-008 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-URP-022 | REQ-PRM-007 | — | UI/UX | P2 | Functional | ⬜ |

---

## 8. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | `search()` endpoint has no authorization gate — any unauthenticated user can search users/roles by name | TC-PRM-URP-015 through TC-PRM-URP-019 | High | ⬜ |
| 2 | All resource CRUD methods (except index) are stubs — no-op or empty views | — | — (by design) | ⬜ |
| 3 | No feature tests exist | All TCs | High | ⬜ |

---

## 9. Route Reference

| Method | URI | Name |
|--------|-----|------|
| GET | `/prime/user-role-prm` | `central.prime.user-role-prm.index` |
| GET | `/prime/user-role-prm/search` | `central.prime.user-role-prm.search` |
| GET | `/prime/user-role-prm/create` | `central.prime.user-role-prm.create` |
| POST | `/prime/user-role-prm` | `central.prime.user-role-prm.store` |
| GET | `/prime/user-role-prm/{user_role_prm}` | `central.prime.user-role-prm.show` |
| GET | `/prime/user-role-prm/{user_role_prm}/edit` | `central.prime.user-role-prm.edit` |
| PUT | `/prime/user-role-prm/{user_role_prm}` | `central.prime.user-role-prm.update` |
| DELETE | `/prime/user-role-prm/{user_role_prm}` | `central.prime.user-role-prm.destroy` |

---

## 10. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-URP-001 | ⬜ | — | — | — | — |
| ... (all 22 TCs) | ⬜ | — | — | — | — |
