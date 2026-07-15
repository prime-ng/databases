# std_StudentCompleteProfile — Gap Analysis & Coverage

**Feature:** StudentCompleteProfile (read/composite) · **Test file:** `std_StudentCompleteProfile_TestCas.php` (27 methods) · `php -l`: clean

---

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Test method | Coverage |
|-----------|-------------|----------|
| MTC-01 | `test_..._01_schema_model_and_routes_are_correct` | Full |
| MTC-10 | `test_..._10_login_only_redirects_to_student_details` | Full |
| MTC-11 | `test_..._11_no_guardians_redirects_to_parent_details` | Full |
| MTC-12 | `test_..._12_no_session_redirects_to_session_details` | Full |
| MTC-13 | `test_..._13_no_prev_edu_redirects_to_prev_edu` | Full |
| MTC-14 | `test_..._14_no_health_redirects_to_health` | Full |
| MTC-15 | `test_..._15_all_complete_redirects_to_login_tab` | Full |
| MTC-16 | `test_..._16_redirect_url_has_student_and_user_ids` | Full |
| MTC-17 | `test_..._17_no_500_for_any_state` | Full |
| MTC-30 | `test_..._30_send_credentials_requires_password_option` | Full |
| MTC-31 | `test_..._31_export_invalid_type_is_rejected` | Full (static) |
| MTC-40 | `test_..._40_show_renders_profile_overview` | Full |
| MTC-41 | `test_..._41_show_exposes_all_detail_tabs` | Full |
| MTC-42 | `test_..._42_show_eager_loads_composite_relations` | Full (static) |
| MTC-50 | `test_..._50_actions_are_gated_by_correct_abilities` | Full (static) |
| MTC-51 | `test_..._51_policy_view_scopes_to_owner_and_parent` | Full (static) |
| MTC-52 | `test_..._52_guest_is_redirected_to_login` | Full |
| MTC-60 | `test_..._60_index_exposes_row_actions` | Full |
| MTC-61 | `test_..._61_print_id_card_renders_card_shell` | Full |
| MTC-62 | `test_..._62_print_id_card_fails_soft_on_template_error` | Full (static) |
| MTC-70 | `test_..._70_missing_student_returns_404` | Full |
| MTC-71 | `test_..._71_next_tab_ladder_covers_all_states` | Full (static) |
| MTC-80 (GAP-STD-25) | `test_..._80_id_card_exposes_raw_admission_no_defect` | Full |
| MTC-81 (PERF-STD-10) | `test_..._81_export_sync_vs_queue_behaviour_defect` | Full |
| MTC-90 | `test_..._90_routes_are_tenant_module_guarded` | Full |
| MTC-91 | `test_..._91_cross_tenant_show_is_not_leaked` | Full |
| MTC-92 | `test_..._92_export_search_is_not_reflected_unescaped` | Full |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 15 | 15 | 0 | 0 | 100% |
| Negative | 5 | 5 | 0 | 0 | 100% |
| Edge/Dependency | 2 | 2 | 0 | 0 | 100% |
| Defects | 2 | 2 | 0 | 0 | 100% |
| Tenancy/Security | 3 | 3 | 0 | 0 | 100% |
| **Total** | **27** | **27** | **0** | **0** | **100%** |

Gates: Negative 100% ✅ · Positive ≥90% (100%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy 100% (P0/P1) ✅.

## 3. Coverage-Score by requirement source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR resume ladder) | 6 | 6 | 100% |
| Composite render (Screen-INT) | 3 | 3 | 100% |
| Validation (Screen-VR) | 2 | 2 | 100% |
| Permissions (Screen-PM) | 3 | 3 | 100% |
| Tenancy/Security (Screen-SEC) | 3 | 3 | 100% |
| Audit defects | 2 | 2 | 100% |

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding |
|---|-------|----------|---------|
| 1 | Enum case | `student_id_card_type` DDL ENUM vs `validateStudentRequest` `in:QR,RFID,NFC,Barcode` | Match — no defect (create-scope) |
| 2 | Route registration | Blade `route('student-profile.student.*')` vs `routes/web.php` | All 6 feature routes registered ✅ |
| 3 | Gate vs Policy | `Gate::authorize` strings vs `StudentPolicy` | view/create/update/delete/restore/forceDelete mapped; **`export` has NO Policy method** (uses ability `tenant.student.export` via Gate only) — acceptable but note |
| 4 | Fillable vs DDL | `Student::$fillable` vs DDL | `photo_file_name`, `media_id` fillable & present; ok |
| 5 | Cast vs DDL | `aadhar_id` cast `encrypted` vs `VARCHAR(20)` | Encrypted value length may exceed VARCHAR(20) → **candidate DEV (verify in source)**: encrypted aadhar likely stored via `aadhar_id_hash` companion; raw `aadhar_id` VARCHAR(20) too small for ciphertext |
| 6 | Service delegation | export logic in controller vs `StudentsExport` | PDF branch duplicates the export query inline in the controller instead of reusing `StudentsExport::collection()` — minor duplication |
| 7 | State machine vs impl | resume ladder doc vs `getNextIncompleteTabForCreate` | Match — 6 states covered ✅ |
| 8 | Validation vs source | sendCredentials rules vs requirement | Match ✅ |
| 9 | Error message | `Invalid export type`, `Cannot generate ID card` | Verbatim asserted ✅ |
| 10 | Permissions | ability strings vs Policy | export ability lacks Policy method (see #3) |
| 11 | Integration FK | `user_id → sys_users ON DELETE CASCADE` | Present in DDL ✅ |

## 5. Documented Source Defects
| ID | Severity | Description | Proving test | Status |
|----|----------|-------------|--------------|--------|
| GAP-STD-25 | P2 (Security) | ID-card / QR exposes `admission_no` (and `aadhar_id`, `student_qr_code`=emp_code) as raw plaintext — should be a hash/UUID | `test_..._80` | Proven (current behaviour) |
| PERF-STD-10 | P2 (Perf) | Synchronous export full-load: **remediated** for excel/csv (`Excel::queue` + `ShouldQueue`); **still synchronous** in the PDF branch (`->get()` + inline `->download()`) | `test_..._81` | Proven (nuanced — audit partly stale) |
| DEV-STD-CP-01 (candidate) | P3 | `aadhar_id` `encrypted` cast written to `VARCHAR(20)` column — ciphertext likely truncates; masking relies on `aadhar_id_hash`. Verify in source before filing. | (documented) | Candidate |

## 6. Legend
Full = automated assertion for every step · Static = deterministic reflection/schema assertion (runs even when module disabled) · Candidate = suspected defect requiring source confirmation before filing.
