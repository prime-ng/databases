# Sales Plan & Module Management — Test Case List

**Feature:** Sales Plan & Module Management | **REQ-ID:** REQ-PRM-003 / REQ-PRM-004 | **Controller:** `SalesPlanAndModuleMgmtController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 26 | — | — | — | 26 | 0% |

---

## 2. Index — Combined Tab View (`GET /prime/sales-plan-mgmt`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SPM-001 | Verify combined view loads with three tabs | Authenticated with `prime.sale-plan-module-mgmt.viewAny`; billing cycles, modules, and plans exist | — | Tabbed view renders with Billing, Modules, Plans tabs | — | — | ⬜ |
| TC-PRM-SPM-002 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login | — | — | ⬜ |
| TC-PRM-SPM-003 | Verify user without viewAny permission receives 403 | Authenticated without `prime.sale-plan-module-mgmt.viewAny` | — | 403 Forbidden | — | — | ⬜ |

---

## 3. Modules Tab

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SPM-004 | Verify modules tab shows paginated modules with menus | Modules with related menus exist | fragment=#modules | Modules list with menus; paginated 10/page | — | — | ⬜ |
| TC-PRM-SPM-005 | Verify search by module name filters results | Module "Timetable" exists | search=Timetable | Only matching modules displayed | — | — | ⬜ |
| TC-PRM-SPM-006 | Verify search by module description filters results | Module with description containing "management" | search=management | Matching modules displayed | — | — | ⬜ |
| TC-PRM-SPM-007 | Verify search by version filters results | Module with version "2.0" | search=2.0 | Matching modules displayed | — | — | ⬜ |
| TC-PRM-SPM-008 | Verify status filter shows only active modules | Mix of active/inactive modules | status=1 | Only active modules (is_active=1) displayed | — | — | ⬜ |
| TC-PRM-SPM-009 | Verify status filter shows only inactive modules | Mix of active/inactive modules | status=0 | Only inactive modules (is_active=0) displayed | — | — | ⬜ |

---

## 4. Billing Cycles Tab

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SPM-010 | Verify billing cycles tab shows paginated cycles | Billing cycles exist | fragment=#billing | Billing cycles list; paginated 10/page; ordered by latest | — | — | ⬜ |
| TC-PRM-SPM-011 | Verify search by short_name filters results | Cycle "MONTHLY" exists | search=MONTHLY | Matching cycles displayed | — | — | ⬜ |
| TC-PRM-SPM-012 | Verify search by name filters results | Cycle "Monthly" exists | search=Monthly | Matching cycles displayed | — | — | ⬜ |
| TC-PRM-SPM-013 | Verify numeric search matches months_count | Cycle with months_count=12 exists | search=12 | Matching cycles displayed | — | — | ⬜ |
| TC-PRM-SPM-014 | Verify status filter works for billing cycles | Mix of active/inactive cycles | status=1 | Only active cycles displayed | — | — | ⬜ |

---

## 5. Plans Tab

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SPM-015 | Verify plans tab shows paginated plans with modules and billing cycle | Plans with linked modules exist | fragment=#plans | Plans list with modules and billing cycle; paginated 10/page | — | — | ⬜ |
| TC-PRM-SPM-016 | Verify search by plan_code filters results | Plan with code "BASIC" exists | search=BASIC | Matching plans displayed | — | — | ⬜ |
| TC-PRM-SPM-017 | Verify search by plan name filters results | Plan "Premium Plan" exists | search=Premium | Matching plans displayed | — | — | ⬜ |
| TC-PRM-SPM-018 | Verify search by currency filters results | Plan with currency "USD" exists | search=USD | Matching plans displayed | — | — | ⬜ |
| TC-PRM-SPM-019 | Verify numeric search matches trial_days | Plan with trial_days=30 exists | search=30 | Matching plans displayed | — | — | ⬜ |
| TC-PRM-SPM-020 | Verify status filter works for plans | Mix of active/inactive plans | status=1 | Only active plans displayed | — | — | ⬜ |

---

## 6. Pagination & URL Fragments

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SPM-021 | Verify modules page parameter preserved | 10+ modules | modules_page=2&fragment=#modules | Page 2 of modules with fragment | — | — | ⬜ |
| TC-PRM-SPM-022 | Verify billing page parameter preserved | 10+ billing cycles | billing_page=2&fragment=#billing | Page 2 of billing cycles with fragment | — | — | ⬜ |
| TC-PRM-SPM-023 | Verify plans page parameter preserved | 10+ plans | plans_page=2&fragment=#plans | Page 2 of plans with fragment | — | — | ⬜ |
| TC-PRM-SPM-024 | Verify search + pagination combined | — | search=test&modules_page=2&fragment=#modules | Search applied and page 2 loads | — | — | ⬜ |

---

## 7. Stub CRUD Methods

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-SPM-025 | Verify create stub returns view with gate check | Authenticated with `prime.sale-plan-module-mgmt.create` | — | View returned (stub) | — | — | ⬜ |
| TC-PRM-SPM-026 | Verify user without create permission receives 403 on create stub | Authenticated without create permission | — | 403 Forbidden | — | — | ⬜ |

---

## 8. Permissions Matrix

| Role | viewAny | create | view | update | delete |
|------|:-------:|:------:|:----:|:------:|:------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Finance | ✅ (view only) | ❌ | ✅ (view only) | ❌ | ❌ |
| Platform IT/Ops | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 9. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-SPM-001 | REQ-PRM-003 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-SPM-002 | REQ-PRM-003 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-SPM-003 | REQ-PRM-003 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-SPM-004 | REQ-PRM-003 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-SPM-005 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-006 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-007 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-008 | REQ-PRM-003 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SPM-009 | REQ-PRM-003 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SPM-010 | REQ-PRM-003 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-SPM-011 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-012 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-013 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-014 | REQ-PRM-003 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SPM-015 | REQ-PRM-003 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-SPM-016 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-017 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-018 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-019 | REQ-PRM-003 | — | Positive/Search | P1 | Functional | ⬜ |
| TC-PRM-SPM-020 | REQ-PRM-003 | — | Positive/Filter | P1 | Functional | ⬜ |
| TC-PRM-SPM-021 | REQ-PRM-003 | — | Pagination | P2 | Functional | ⬜ |
| TC-PRM-SPM-022 | REQ-PRM-003 | — | Pagination | P2 | Functional | ⬜ |
| TC-PRM-SPM-023 | REQ-PRM-003 | — | Pagination | P2 | Functional | ⬜ |
| TC-PRM-SPM-024 | REQ-PRM-003 | — | Pagination/Search | P2 | Functional | ⬜ |
| TC-PRM-SPM-025 | REQ-PRM-003 | — | Positive/Stub | P2 | Functional | ⬜ |
| TC-PRM-SPM-026 | REQ-PRM-003 | — | Security/Auth | P0 | Security | ⬜ |

---

## 10. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | All CRUD operations (create, store, edit, update, destroy, show) are stubs with no business logic | TC-PRM-SPM-025, TC-PRM-SPM-026 | High | ⬜ |
| 2 | Plan versioning not enforced (BR-PRM-012) | — | High | ⬜ |
| 3 | No Form Request validation for any CRUD operation | — | Medium | ⬜ |
| 4 | No feature tests exist | All TCs | High | ⬜ |

---

## 11. Route Reference

| Method | URI | Name |
|--------|-----|------|
| GET | `/prime/sales-plan-mgmt` | `central.prime.sales-plan-mgmt.index` |
| GET | `/prime/sales-plan-mgmt/create` | `central.prime.sales-plan-mgmt.create` |
| POST | `/prime/sales-plan-mgmt` | `central.prime.sales-plan-mgmt.store` |
| GET | `/prime/sales-plan-mgmt/{sales_plan_mgmt}` | `central.prime.sales-plan-mgmt.show` |
| GET | `/prime/sales-plan-mgmt/{sales_plan_mgmt}/edit` | `central.prime.sales-plan-mgmt.edit` |
| PUT | `/prime/sales-plan-mgmt/{sales_plan_mgmt}` | `central.prime.sales-plan-mgmt.update` |
| DELETE | `/prime/sales-plan-mgmt/{sales_plan_mgmt}` | `central.prime.sales-plan-mgmt.destroy` |

---

## 12. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-SPM-001 | ⬜ | — | — | — | — |
| ... (all 26 TCs) | ⬜ | — | — | — | — |
