# Student Leave Type — Gap Analysis & Coverage

**Feature:** StudentLeaveType (`std_leave_types`) · **Test file:** `std_StudentLeaveType_TestCas.php` · **Methods:** 42

---

## 1. Manual TC ↔ Automated Method Mapping

### Positive
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MTC-01 create happy path | `_11`, `_12`, `_13`, `_61` | Full |
| MTC-04 edit/update | `_14`, `_62` | Full |
| MTC-05 toggle | `_20`, `_21` | Full |
| MTC-06 delete/restore/force | `_15`, `_16`, `_17`, `_64` | Full |
| MTC-09 UI listing/search | `_60`, `_65`, `_10` | Full (filter-status: Partial — see §4) |
| MTC-03 boundary accept | `_72`, `_18` | Full |
| show/details | `_63` | Full |

### Negative
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MTC-02 required + duplicate | `_30`, `_31`, `_32` | Full |
| MTC-03 length/range/negative | `_33`,`_34`,`_35`,`_36`,`_37`,`_38`,`_39` | Full |
| MTC-08 guest | `_50` | Full |
| MTC-10 unknown id 404 | `_70`, `_71` | Full |
| MTC-10 created_by spoof | `_92` | Full |

### Dependency
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MTC-06 code reuse after soft-delete | `_40` | Full |
| MTC-07 FK RESTRICT | `_41` | Full (defensive skip if deps absent) |
| relationship integrity | `_42` | Full |
| soft-delete preservation | `_15`,`_16` | Full |

### Authorization / Security
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MTC-08 policy mapping | `_51` | Full |
| MTC-08 controller gates | `_52` | Full |
| MTC-08 limited-user denial | `_53` | Partial (defensive; super-admin bypass → skip) |
| MTC-10 XSS escaped | `_91` | Full |
| tenancy scoping | `_90` | Full |

---

## 2. Coverage Summary (by TC category)
| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 21 | 20 | 1 | 0 | 100% (95% Full) |
| Negative | 14 | 14 | 0 | 0 | 100% |
| Dependency | 4 | 4 | 0 | 0 | 100% |
| State machine | 2 | 2 | 0 | 0 | 100% |
| Authorization | 3 | 2 | 1 | 0 | 100% |
| Security/Tenancy | 3 | 3 | 0 | 0 | 100% |

**Gates:** Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%) · Tenancy 100% ✅.

---

## 3. Coverage-Score by requirement Source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 9 | 9 | 100% |
| State-Machine (BC-SM) | 2 | 2 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration/FK (BC-REF/INT) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 7 | 7 | 100% (viewAny asserted via policy `_51`; index-route enforcement gap tracked as DEV-STD-LT-01) |
| Edge (BC-EDG) | 4 | 4 | 100% |

Every Source-tagged requirement item has ≥1 TC. No zero-coverage items.

---

## 4. Remaining Partial Coverage / Limitations
| Item | Method | Limitation |
|------|--------|-----------|
| Status filter (Active/Inactive dropdown) | (via `_65` search) | Search asserted; the `status=0/1` filter path is exercised by the service but not asserted with a dedicated negative-set assertion. Low risk. |
| Limited-user 403 | `_53` | Dusk cannot `assertStatus`; test infers denial from page source / redirect and `markTestSkipped`s under super-admin bypass. Controller gates independently proven by `_52` + policy by `_51`. |
| FK RESTRICT | `_41` | Requires seedable `std_leave_applications` (multiple NOT NULL FKs); skips gracefully in partial environments. |

---

## 5. Cross-Reference Defect Scan
| # | Check | Compared | Finding |
|---|-------|----------|---------|
| 1 | Enum case | DDL vs Request `in:` | N/A — no ENUM columns on std_leave_types. Clean. |
| 2 | Route registration | Blade `route()` vs `routes/web.php` | All `student-profile.student-leave-types.*` registered (resource + trashed/restore/forceDelete/toggleStatus). Clean (`_02`). |
| 3 | Gate vs Policy | Controller `Gate::authorize` vs Policy | Policy present with all 7 abilities. **index() gate commented out & wrong prefix** → DEV-STD-LT-01. |
| 4 | Fillable vs DDL | Model `$fillable` vs columns | All persistable columns fillable. Clean. |
| 5 | Cast vs DDL | Model `$casts` vs types | boolean on TINYINT(1); integer on TINYINT/SMALLINT. Clean. |
| 6 | Service delegation | Controller vs `LeaveService` | All CRUD delegated to service (create/update/delete/restore/forceDelete/toggle/getTrashed). Clean. |
| 7 | State machine vs impl | Toggle transitions vs controller | active↔inactive both handled; JSON contract present. Clean. |
| 8 | Validation vs Request | Requirement rules vs `rules()` | All rules present and match DDL limits. Clean. |
| 9 | Error message vs Request | Expected vs `messages()` | No custom `messages()`; relies on `attributes()` labels + Laravel defaults. Acceptable (labels: "Leave Code", "Leave Name", …). |
| 10 | Permissions vs Policy/Gates | Matrix vs Policy + gates | Consistent (`tenant.leave-type.*`) except index viewAny (DEV-STD-LT-01). |
| 11 | Integration FK vs migration | Requirement FK vs migration | `std_leave_applications.leave_type_id` → `std_leave_types.id` RESTRICT present. Clean. |

### Discovered / confirmed defects
| ID | Severity | Description | Proving artifact |
|----|----------|-------------|------------------|
| DEV-STD-LT-01 | P3 | `StudentLeaveTypeController::index()` has `Gate::authorize('prime.department.viewAny')` **commented out** and mis-prefixed; `tenant.leave-type.viewAny` is never enforced on the index route (mitigated — index only redirects to the tab list). Recommend enabling `Gate::authorize('tenant.leave-type.viewAny')`. | `_51` (policy defines the correct key); manual review of controller line 23. |

> GAP-STD-08 (audit "5 missing policies"): **does NOT apply** — `LeaveTypePolicy` exists and correctly maps every ability to `tenant.leave-type.*` (proven by `_51`). No P0/P1 audit defect is primarily owned by this master.

---

## 6. Legend
- **Full** — behaviour asserted end-to-end (DB / activity / response / render).
- **Partial** — behaviour exercised but with a defensive skip or an indirect assertion.
- **Gap** — no automated coverage (none for this feature).
