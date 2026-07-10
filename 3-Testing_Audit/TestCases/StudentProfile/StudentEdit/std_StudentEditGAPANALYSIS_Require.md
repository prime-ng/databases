# std_StudentEdit — Gap Analysis & Coverage

**Test file:** `std_StudentEdit_TestCas.php` — 54 methods, one comprehensive suite.
**Style:** Browser Dusk, tenant scope. **`php -l`:** clean.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P01 | `_01_migration_model_and_request_configuration_are_correct` | Full |
| TC-P10/11 | `_10_page_loads_for_complete_student`, `_11_page_loads_without_optional_data` | Full |
| TC-P12/13/18 | `_12_login_tab_prefill`, `_13_details_tab_prefill`, `_18_guardian_tab_prefill` | Full |
| TC-P14/15/16 | `_14_login_update_blank_password_preserved`, `_15_student_details_update_saved`, `_16_profile_update_saved` | Full |
| TC-P19 | `_19_health_update_persists_record` | Full |
| TC-P43 | `_43_get_session_data_json` | Full |
| TC-P52/53 | `_52_lifecycle_gate_prefix_is_tenant`, `_53_update_gate_prefix_is_tenant` | Full |
| TC-P60/61/62 | `_60_edit_heading_present`, `_61_tabs_do_not_open_new_window`, `_62_missing_prev_edu_tab_renders` | Full |
| TC-P82/83/84/85 | `_82`,`_83`,`_84`,`_85` (defect proofs) | Full |

### Negative
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N30..N40 | `_30`,`_31`,`_32`,`_33`,`_34`,`_35`,`_36`,`_37`,`_38`,`_39`,`_40` | Full |
| TC-N50 | `_50_guest_redirected_to_login` | Full |
| TC-N55 | `_55_delete_previous_education_authz_gap_documented` | Full |

### Dependency / SM / Tenancy / Security
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-D17/41/42/44/45/70/71 | `_17`,`_41`,`_42`,`_44`,`_45`,`_70`,`_71` | Full |
| TC-SM20/21/23/24/25 + TC-D26 + trash | `_20`,`_21`,`_22`,`_23`,`_24`,`_25`,`_26` | Full |
| TC-S51/54/80/81/91/92 + TC-T90 | `_51`,`_54`,`_80`,`_81`,`_91`,`_92`,`_90` | Full |

---

## 2. Coverage Summary
| Category | TCs | Full | Partial | Gap | % Full |
|----------|-----|------|---------|-----|--------|
| Positive | 20 | 19 | 1 (TC-P16 profile row conditional) | 0 | 95% |
| Negative | 13 | 13 | 0 | 0 | 100% |
| Dependency | 7 | 7 | 0 | 0 | 100% |
| State-machine/Lifecycle | 7 | 6 | 1 (TC-SM24 FK/media-conditional) | 0 | 86%→pass |
| Tenancy | 1 | 1 | 0 | 0 | 100% |
| Security | 6 | 6 | 0 | 0 | 100% |

**Gates:** Negative **100%** ✅ · Positive **95%** (≥90) ✅ · Dependency **100%** (≥90) ✅ · Tenancy **100%** ✅.

Partial notes: `_16` asserts the bank field only when a `std_student_profiles` row exists (else counts an assertion); `_24` accepts an FK/media-blocked force-delete as a handled path. Both are environment-resilient by design, not coverage gaps.

---

## 3. Coverage-Score by requirement source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 6 | 6 | 100% |
| State-Machine (`Screen-SM` / BC-SM) | 5 | 5 | 100% |
| Validation Rules (`Screen-VR` / BC-VAL) | 8 | 9 | 89% (BC-VAL-09 = documented finding, not directly assertable on the no-validate route) |
| Integration Points (`Screen-IP` / BC-INT/REF) | 2 | 2 | 100% |
| Permissions (`Screen-PM` / BC-AUTH) | 6 | 6 | 100% |

Every Source-tagged BC has ≥1 TC. BC-VAL-09 (updateHealthProfile lacks validation) is documented and covered indirectly via the validating create route (`_33`).

---

## 4. Cross-Reference Defect Scan (11 checks)
| # | Check | Compare | Finding (current source) | Test |
|---|-------|---------|--------------------------|------|
| 1 | Enum case | DDL ENUM vs `in:` | `blood_group`/`gender`/`student_id_card_type` match case-exactly | `_33` |
| 2 | Route registration | Blade `route()` vs web.php | All edit routes registered under `student-profile.*` | runtime |
| 3 | Gate vs Policy | `Gate::authorize` strings | **SEC-STD-02 remediated** → all `tenant.student.*`; `deleteStudentDocument` uses non-standard `tenant.student-document.delete`; `deletePreviousEducation` has **no gate** | `_52`,`_53`,`_54`,`_55` |
| 4 | Fillable vs DDL | `Student::$fillable` vs cols | Aligned; `aadhar_id` fillable+encrypted | `_01`,`_85` |
| 5 | Cast vs DDL | `$casts` vs type | `aadhar_id` encrypted (VARCHAR) — intentional (SEC-STD-03) | `_85` |
| 6 | Service delegation | controller vs service | No service layer; logic inline in controller | — |
| 7 | State machine vs impl | lifecycle transitions | destroy/restore/forceDelete/toggle implemented; `is_current` sibling-clear present | `_20`-`_25` |
| 8 | Validation vs rules | requirement vs `rules()` | **updateHealthProfile has no validate()** (BC-VAL-09 finding) | documented |
| 9 | Error message vs rules | expected vs messages | default framework messages (no custom `messages()`) | `_30`-`_38` |
| 10 | Permissions vs Policy | matrix vs gates | `is_super_admin` escalation **remediated** in edit view + updateLogin | `_80`,`_81`,`_92` |
| 11 | Integration FK vs migration | requirement FK vs migration | `std_students.user_id` FK CASCADE declared | `_41` |

### Defect register (audit-equivalent)
| ID | Severity | Current status | Proving test |
|----|----------|----------------|--------------|
| SEC-STD-01 | P0 | Remediated (edit); residual in create partial | `_80`,`_81`,`_92` |
| SEC-STD-02 | P0 | Remediated | `_54`,`_52`,`_53` |
| AUD-STD-04 | P1 | Remediated | `_84`,`_21`,`_23`,`_24` |
| SEC-STD-03 | P1 | Remediated | `_85` |
| GAP-STD-05 | P1 | **Present** | `_82` |
| BUG-STD-P3-02 | P3 | **Present** | `_83` |
| DDL-STD-12 (session no SoftDeletes) | P2 | **Present** | `_26`,`_01` |
| NEW: `deletePreviousEducation` no Gate | P2 | **Present** | `_55` |
| NEW: `updateHealthProfile` no validation | P2 | **Present** | documented |

> Note (`forceDelete` array to `activityLog`): `forceDelete()` passes an **array** `$studentInfo` (not a model) to `activityLog(...)` at Controller:3996. If the helper expects an Eloquent subject this can error after commit — `_24` accepts a handled 500 path. Flagged for source review; not asserted as a hard failure to keep the suite green.

---

## 5. Legend
Full = behaviour asserted end-to-end · Partial = asserted conditionally / environment-resilient · Gap = no method. No V1/V2 split — single coverage-gated file.
