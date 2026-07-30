# Platform Settings (App Level Settings) — Test Case List

**Feature:** Platform Settings Management | **REQ-ID:** REQ-SYS-001 | **Controller:** `SettingController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 18 | — | — | — | 18 | 0% |

---

## 2. Index/List — Settings List (`GET /system-config/setting`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SET-001 | Verify settings list loads with paginated results | Authenticated as Super Admin with `system-config.setting.viewAny` permission | — | Page renders 20 settings per page, ordered by `key` ascending | — | — | ⬜ |
| TC-SYS-SET-002 | Verify search by `key` filters results | At least 1 setting whose key contains `smtp` | `search=smtp` | Only settings with `smtp` in key displayed | — | — | ⬜ |
| TC-SYS-SET-003 | Verify search by `description` filters results | Setting with description containing `host` | `search=host` | Matching settings displayed | — | — | ⬜ |
| TC-SYS-SET-004 | Verify search by `value` filters results | Setting with value containing `true` | `search=true` | Matching settings displayed | — | — | ⬜ |
| TC-SYS-SET-005 | Verify type filter works | Settings with different types | `type=boolean` | Only boolean-type settings displayed | — | — | ⬜ |
| TC-SYS-SET-006 | Verify `is_public=false` values are masked as `••••••••` | Setting with `is_public=0` | — | Value column shows masked bullets, not raw value | — | — | ⬜ |
| TC-SYS-SET-007 | Verify `is_public=true` values shown in plain text | Setting with `is_public=1` | — | Value column shows actual value | — | — | ⬜ |
| TC-SYS-SET-008 | Verify pagination query string preserved across search/filter | 25+ settings | `?search=smtp&page=2` | Page 2 loads with search param preserved | — | — | ⬜ |
| TC-SYS-SET-009 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login page | — | — | ⬜ |
| TC-SYS-SET-010 | Verify user without permission receives 403 | Authenticated without `system-config.setting.viewAny` | — | 403 Forbidden | — | — | ⬜ |

---

## 3. Edit Form — Setting Edit (`GET /system-config/setting/{id}/edit`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SET-011 | Verify edit form loads for valid setting ID | Setting with ID=1 exists | — | Edit form displays with key field read-only, value field editable | — | — | ⬜ |
| TC-SYS-SET-012 | Verify non-existent ID returns 404 | No setting with ID=9999 | — | 404 Not Found | — | — | ⬜ |
| TC-SYS-SET-013 | Verify sensitive key (containing `password`) renders password input | Setting with key containing `password` | — | Value input `type="password"` rendered | — | — | ⬜ |
| TC-SYS-SET-014 | Verify sensitive key (containing `api_key`) renders password input | Setting with key containing `api_key` | — | Value input `type="password"` rendered | — | — | ⬜ |
| TC-SYS-SET-015 | Verify user without `update` permission receives 403 | Authenticated without `system-config.setting.update` | — | 403 Forbidden | — | — | ⬜ |

---

## 4. Update Action — Setting Update (`PUT /system-config/setting/{id}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SET-016 | Verify valid update saves new value and redirects | Setting with ID=1 | `value=new_smtp_host` | Value updated; redirect to index with success flash; audit log entry created | — | — | ⬜ |
| TC-SYS-SET-017 | Verify empty value rejected with validation error | Setting with ID=1 | `value=` | Validation error: value is required | — | — | ⬜ |
| TC-SYS-SET-018 | Verify key submitted in payload does NOT change | Setting with ID=1, key=`smtp_host` | `value=new&key=new_key` | Key remains `smtp_host` in database | — | — | ⬜ |
| TC-SYS-SET-019 | Verify audit log written with correct event | Setting update performed | — | `sys_activity_logs` has entry with event=`updated`, subject_type=`Setting`, properties contain before/after | — | — | ⬜ |
| TC-SYS-SET-020 | Verify sensitive key update audit log excludes raw value | Setting with key containing `password` | `value=new_password` | Audit log entry shows placeholder, not actual password value | — | — | ⬜ |
| TC-SYS-SET-021 | Verify user without `update` permission receives 403 on update | Authenticated without permission | — | 403 Forbidden; no update performed | — | — | ⬜ |
| TC-SYS-SET-022 | Verify value exceeding 1000 characters rejected | Setting with ID=1 | `value=` + 1001 chars | Validation error: max 1000 | — | — | ⬜ |

---

## 5. Edge Cases

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-SET-023 | Verify cross-tenant isolation — setting update in Tenant A does not affect Tenant B | Two active tenants | Update setting in Tenant A | Tenant B's setting unchanged | — | — | ⬜ |
| TC-SYS-SET-024 | Verify description containing special characters searchable | Setting with `description` containing `<script>alert(1)</script>` | `search=<script>` | Search returns the setting; XSS not executed (escaped in view) | — | — | ⬜ |
| TC-SYS-SET-025 | Verify all data types render correct input control | Settings of types string, boolean, int, json, date | — | String: text input; Boolean: toggle/checkbox; Int: number input; JSON: code editor; Date: date picker | — | — | ⬜ |

---

## 6. Permissions Matrix

| Role | View Settings | Edit Settings | Notes |
|------|:-------------:|:-------------:|-------|
| Super Admin | ✅ | ✅ | Full access |
| Platform Manager | ✅ | ✅ | Same as Super Admin for settings |
| Platform Support | ❌ | ❌ | No settings access |
| School Admin | ❌ | ❌ | Tenant-scoped — only central domain routes |
| Teacher | ❌ | ❌ | No access |

---

## 7. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-SYS-SET-001 | REQ-SYS-001 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-SYS-SET-002 | REQ-SYS-001 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-SYS-SET-003 | REQ-SYS-001 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-SYS-SET-004 | REQ-SYS-001 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-SYS-SET-005 | REQ-SYS-001 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-SYS-SET-006 | REQ-SYS-001 | BR-SYS-005 | Security/Masking | P0 | Security | ⬜ |
| TC-SYS-SET-007 | REQ-SYS-001 | BR-SYS-005 | Positive | P1 | Functional | ⬜ |
| TC-SYS-SET-008 | REQ-SYS-001 | — | Pagination | P2 | Functional | ⬜ |
| TC-SYS-SET-009 | REQ-SYS-001 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-SET-010 | REQ-SYS-001 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-SET-011 | REQ-SYS-001 | BR-SYS-001 | Positive | P1 | Functional | ⬜ |
| TC-SYS-SET-012 | REQ-SYS-001 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-SYS-SET-013 | REQ-SYS-001 | BR-SYS-006 | Security/UI | P1 | Functional | ⬜ |
| TC-SYS-SET-014 | REQ-SYS-001 | BR-SYS-006 | Security/UI | P1 | Functional | ⬜ |
| TC-SYS-SET-015 | REQ-SYS-001 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-SET-016 | REQ-SYS-001 | BR-SYS-012 | Positive | P0 | Functional | ⬜ |
| TC-SYS-SET-017 | REQ-SYS-001 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-SYS-SET-018 | REQ-SYS-001 | BR-SYS-001 | Security/Validation | P0 | Security | ⬜ |
| TC-SYS-SET-019 | REQ-SYS-001 | BR-SYS-012 | Audit | P0 | Audit | ⬜ |
| TC-SYS-SET-020 | REQ-SYS-001 | BR-SYS-006 | Security/Audit | P0 | Security | ⬜ |
| TC-SYS-SET-021 | REQ-SYS-001 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-SET-022 | REQ-SYS-001 | — | Negative/Boundary | P2 | Functional | ⬜ |
| TC-SYS-SET-023 | REQ-SYS-001 | — | Multi-Tenancy | P1 | Integration | ⬜ |
| TC-SYS-SET-024 | REQ-SYS-001 | — | Security/XSS | P1 | Security | ⬜ |
| TC-SYS-SET-025 | REQ-SYS-001 | — | UI/UX | P2 | Functional | ⬜ |

---

## 8. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | `update()` uses inline validation instead of Form Request — hard to test and maintain | TC-SYS-SET-016 through TC-SYS-SET-022 | Medium | ⬜ |
| 2 | No `store()` method — settings must be pre-seeded; no UI for creating new settings | — | Low | ⬜ |
| 3 | `sys_settings` has no `SoftDeletes` column — violates project convention | — | Low | ⬜ |
| 4 | No feature tests exist for any SettingController method | All TCs | High | ⬜ |
| 5 | Audit log in `update()` does not capture full before/after JSON — only logs `key` | TC-SYS-SET-019 | Medium | ⬜ |

---

## 9. Route Reference

| Method | URI | Name | Middleware |
|--------|-----|------|-----------|
| GET | `/system-config/setting` | `system-config.setting.index` | `web`, `auth`, `verified`, `InitializeTenancyByDomain` |
| GET | `/system-config/setting/{setting}/edit` | `system-config.setting.edit` | Same as above |
| PUT | `/system-config/setting/{setting}` | `system-config.setting.update` | Same as above |

---

## 10. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-SYS-SET-001 | ⬜ | — | — | — | — |
| TC-SYS-SET-002 | ⬜ | — | — | — | — |
| TC-SYS-SET-003 | ⬜ | — | — | — | — |
| TC-SYS-SET-004 | ⬜ | — | — | — | — |
| TC-SYS-SET-005 | ⬜ | — | — | — | — |
| TC-SYS-SET-006 | ⬜ | — | — | — | — |
| TC-SYS-SET-007 | ⬜ | — | — | — | — |
| TC-SYS-SET-008 | ⬜ | — | — | — | — |
| TC-SYS-SET-009 | ⬜ | — | — | — | — |
| TC-SYS-SET-010 | ⬜ | — | — | — | — |
| TC-SYS-SET-011 | ⬜ | — | — | — | — |
| TC-SYS-SET-012 | ⬜ | — | — | — | — |
| TC-SYS-SET-013 | ⬜ | — | — | — | — |
| TC-SYS-SET-014 | ⬜ | — | — | — | — |
| TC-SYS-SET-015 | ⬜ | — | — | — | — |
| TC-SYS-SET-016 | ⬜ | — | — | — | — |
| TC-SYS-SET-017 | ⬜ | — | — | — | — |
| TC-SYS-SET-018 | ⬜ | — | — | — | — |
| TC-SYS-SET-019 | ⬜ | — | — | — | — |
| TC-SYS-SET-020 | ⬜ | — | — | — | — |
| TC-SYS-SET-021 | ⬜ | — | — | — | — |
| TC-SYS-SET-022 | ⬜ | — | — | — | — |
| TC-SYS-SET-023 | ⬜ | — | — | — | — |
| TC-SYS-SET-024 | ⬜ | — | — | — | — |
| TC-SYS-SET-025 | ⬜ | — | — | — | — |
