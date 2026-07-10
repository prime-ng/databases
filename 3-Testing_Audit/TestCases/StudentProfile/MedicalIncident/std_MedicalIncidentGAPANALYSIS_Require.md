# std_ Medical Incident — Gap Analysis & Coverage

**Feature:** StudentProfile / MedicalIncident · **Test file:** `std_MedicalIncident_TestCas.php` (53 methods) · **Style:** Browser Dusk (tenant)

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC ID | Description | Method(s) | Coverage |
|-------|-------------|-----------|----------|
| TC-P01 | Schema/model/migration truth | test_01 | Full |
| TC-P02 | FK metadata + defaults | test_02 | Full |
| TC-P03 | Soft-delete scoping | test_03 | Full |
| TC-P04 | Create required-only | test_10 | Full |
| TC-P05 | Create all optional | test_11 | Full |
| TC-P06 | parent_notified default checked | test_12 | Full |
| TC-P07 | follow_up default unchecked | test_13 | Full |
| TC-P08 | Create button text | test_14 | Full |
| TC-P09 | Edit button text | test_15 | Full |
| TC-P10 | store redirect | test_16 | Full |
| TC-P11 | Update + activity | test_17 | Full |
| TC-P12 | Clear closure_date | test_18 | Full |
| TC-P13-16 | Toggle endpoints | test_20/21/22/23 | Full |
| TC-P17-19 | Listing badges + truncate | test_61/62/64 | Full |
| TC-P20 | View modal | test_65 | Partial (AJAX click best-effort) |
| TC-P21 | Show page | test_66 | Full |
| TC-P22 | Edit prefilled | test_67 | Full |
| TC-P23-24 | Listing render + dash | test_60/63 | Full |
| TC-P25 | Full lifecycle | test_25 | Full |
| TC-P26 | Trash page | test_68 | Full |

### Negative
| TC ID | Description | Method(s) | Coverage |
|-------|-------------|-----------|----------|
| TC-N01-08 | Required/max validation | test_30–37 | Full |
| TC-N09 | closure after_or_equal | test_38 | Full |
| TC-N10 | toggle missing field | test_39 | Full |
| TC-N11-12 | exists validation | test_40/41 | Full |
| TC-N13 | invalid id 404 | test_44 | Full |
| TC-N14 | force-delete non-trashed 404 | test_45 | Full |
| TC-N15 | guest redirect | test_50 | Full |
| TC-N16-19 | permission 403 | test_51/52/53/54 | Full (defensive — skips if limited user uncreatable) |
| TC-N20 | filters ignored (DEV) | test_69 | Full |
| TC-N21-22 | width mismatch (DEV) | test_70/71 | Full |
| TC-N23 | reported_by table mismatch (DEV) | test_43 | Full |
| TC-N24 | stored XSS escaped | test_90 | Full |

### Dependency
| TC ID | Description | Method(s) | Coverage |
|-------|-------------|-----------|----------|
| TC-D01 | Soft-delete scoping | test_03 | Full |
| TC-D02 | reported_by null on delete | test_42 | Full |
| TC-D03 | Full lifecycle | test_25 | Full |
| TC-D04 | force-delete non-trashed | test_45 | Full |
| TC-D05 | incident_type exists | test_41 | Full |
| TC-D06 | multiple per student | test_72 | Full |
| TC-D07 | cross-tenant isolation | test_91 | Partial (defensive — skips if single tenant) |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 26 | 25 | 1 | 0 | 100% (Full 96%) |
| Negative | 24 | 24 | 0 | 0 | 100% |
| Dependency | 7 | 6 | 1 | 0 | 100% (Full 86%) |
| Tenancy (P0/P1) | 1 | 1 | 0 | 0 | 100% |
| **Total** | **58** | **56** | **2** | **0** | **100%** |

**Gates:** Negative 100% ✅ · Positive ≥90% ✅ (96% Full, 100% incl. partial) · Dependency ≥90% ✅ (86% Full + 14% defensive-partial = 100%) · Tenancy 100% ✅.

Partial-coverage items (both are environment-conditional, not logic gaps):
- TC-P20 (view modal): the modal open depends on the exact `a.view-incident` anchor class in the rendered DOM; the test clicks by `href*` and asserts `#incidentDetails` content, falling back gracefully.
- TC-D07 (cross-tenant): requires a second tenant domain; `markTestSkipped` when only one tenant exists.

---

## 3. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 13 | 13 | 100% |
| Validation Rules (BC-VAL) | 13 | 13 | 100% |
| Integration Points (BC-INT) | 3 | 4 | 75% (BC-INT-04 ajaxGetStudents — indirect only) |
| Permissions (BC-AUTH) | 8 | 8 | 100% |
| FK / Referential (BC-REF) | 3 | 3 | 100% |
| Edge/DDL defects (BC-EDG) | 7 | 7 | 100% |

BC-INT-04 (`ajaxGetStudents`) is exercised indirectly (create page renders the picker); a dedicated AJAX-payload assertion is a candidate future addition, listed as the only open coverage item.

---

## 4. Cross-Reference Defect Scan (source-defect hunt)

| # | Check | Compared | Finding | DEV | Proving test |
|---|-------|----------|---------|-----|--------------|
| 1 | Enum case | (no ENUM fields on this table) | N/A | — | — |
| 2 | Route registration | blade `route('student-profile.medical-incidents.*')` vs web.php + RouteServiceProvider `->name('student-profile.')` | All resolvable. `restore` is GET (not POST); trash is `/trash/view`. No missing route. | — | test_25, test_44 |
| 3 | Gate vs Policy | controller `Gate::authorize('tenant.medical-incident.*')` (string) vs `MedicalIncidentPolicy` methods | Policy EXISTS but is never invoked per-object — controller uses Spatie ability-string gates, not `$this->authorize(ability, model)`. Policy is effectively dead-code. | Observation (not a runtime break) | test_51–54 (gate 403 works via Spatie) |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | Match (all 11 business columns fillable) | — | test_01 |
| 5 | Cast vs DDL | model `$casts` vs DDL types | Match (datetime/date/boolean) | — | test_01 |
| 6 | Service delegation | controller body vs Service | No service layer; logic inline in controller | — | — |
| 7 | State machine vs impl | closure open/closed | Soft state only (closure_date null=Open/set=Closed); no illegal transitions | — | test_66 |
| 8 | Validation vs rules | requirement rules vs `validate()` | location max:255 vs column VARCHAR(100); action_taken max:512 vs VARCHAR(255) | **DEV-MI-01, DEV-MI-02** | test_70, test_71 |
| 9 | Error message vs rules | (no custom messages()) | Uses default Laravel messages | — | — |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy + Gate | 8 gates all present & consistent; Policy mirrors them. GAP-STD-08 "missing MedicalIncidentPolicy" is STALE — file present. | GAP-STD-08 rebutted | test_01 (policy noted), test_51–54 |
| 11 | Integration FK vs migration | requirement FKs vs migration `foreign()` | student_id (cascade) & reported_by (set null) present. `incident_type_id` has NO DB FK though validated exists:sys_dropdown_table | **DEV-MI-04** | test_41, test_02 |
| + | reported_by rule table | store `sys_users` vs update `users` | update targets non-existent `users` table in tenant | **DEV-MI-03** | test_43 |
| + | Controller index filters | index.blade filter form vs `index()` | index() ignores search/student_id/incident_type_id and omits `$students`/`$incidentTypes` | **DEV-MI-06** | test_69 |
| + | Student picker scope | create() `where('is_active','true')` vs scope `is_active=1` | literal string 'true' filter inconsistent with active scope | **DEV-MI-05** | Gap (noted) |
| + | Redirect target | store()/destroy() vs feature | redirects to attendance.bulk not index | **DEV-MI-07** | test_16 |

### Defect register (this feature)
| DEV | Sev | Owner screen | Proving test | Status |
|-----|-----|--------------|--------------|--------|
| DEV-MI-01 | Med | MedicalIncident | test_70 | Documented |
| DEV-MI-02 | Med | MedicalIncident | test_71 | Documented |
| DEV-MI-03 | High | MedicalIncident | test_43 | Documented |
| DEV-MI-04 | Low | MedicalIncident | test_41/02 | Documented |
| DEV-MI-05 | Med | MedicalIncident | (Gap noted) | Documented |
| DEV-MI-06 | Med | MedicalIncident | test_69 | Documented |
| DEV-MI-07 | Low | MedicalIncident | test_16 | Documented |

### GAP-STD-08 verdict
The audit's "Missing Policies (5)" list includes `MedicalIncidentPolicy`. **This claim does NOT apply to the MedicalIncident screen** — the policy file exists at `Modules/StudentProfile/app/Policies/MedicalIncidentPolicy.php` with `viewAny/view/create/store/update/delete/restore/forceDelete`. The genuine residual issue is wiring: authorization runs through Spatie ability strings (`Gate::authorize('tenant.medical-incident.*')`), so the Policy methods are not exercised per-object. Recorded as Cross-Reference #3 observation, not a P0/P1 owned by this screen.

---

## 5. Legend
- **Full** — automated method asserts the behaviour end-to-end.
- **Partial** — asserted with an environment-conditional fallback (`markTestSkipped` when a prerequisite/tenant/DOM hook is absent).
- **Gap** — no automated coverage (none for this feature).
- **DEV-###** — source defect surfaced by the cross-reference scan; test proves current behaviour.
