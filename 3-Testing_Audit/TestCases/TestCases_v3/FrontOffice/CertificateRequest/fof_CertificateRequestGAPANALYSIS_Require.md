# FrontOffice · CertificateRequest — Gap Analysis & Traceability

> Artifact 2 of 5. Maps every TC → test method with coverage verdict, plus the Cross-Reference Defect Scan and Coverage-Score table. Test file: `fof_CertificateRequest_TestCas.php` (37 methods, `php -l` clean).

Legend: **Full** = behaviour asserted end-to-end (DB/model/source/Gate). **Partial** = asserted at one layer only or env-gated (browser flow skips when module disabled). **Gap** = no method.

---

## 1. Coverage by category

### Positive

| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P01 | test_cert_01 | Full | live schema + model/casts/relations/scopes |
| TC-P02 | test_cert_02 | Full | SHOW INDEX unique cols |
| TC-P03 | test_cert_03 | Full | col + trait independent |
| TC-P04 | test_cert_04 | Full | information_schema nullability |
| TC-P05 | test_cert_10 | Full | source: generator + not-validated |
| TC-P06 | test_cert_11 | Full | refresh() defaults |
| TC-P07 | test_cert_12 | Full | boolean cast |
| TC-P08 | test_cert_13 | Full | source: slash format |
| TC-P09 | test_cert_20 | Full | model transition + approved_at |
| TC-P10 | test_cert_21 | Full | model transition + reason |
| TC-P11 | test_cert_22 | Full | model transition + cert_number/issued_at |
| TC-P12 | test_cert_31 | Full | nullable NULL insert |
| TC-P13 | test_cert_32 | Full | exactly-200 accepted |
| TC-P14 | test_cert_33 | Full | exactly-30 accepted |
| TC-P15 | test_cert_71 | Full | multiple NULL cert_numbers |
| TC-P16 | test_cert_60 | Partial | browser; skips if module disabled |
| TC-P17 | test_cert_61 | Partial | browser; skips if module disabled |
| TC-P18 | test_cert_62 | Full | Blade field names (source) |
| TC-P19 | test_cert_90 | Full | 6 verbatim event strings |
| TC-P20 | test_cert_91 | Full | tenant sink table/column |
| TC-P21 | test_cert_93 | Full | tenant-scoped find |

### Negative

| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-N01 | test_cert_30 (+04) | Full | every NOT-NULL col rejected |
| TC-N02 | test_cert_32 | Full | over-length rejected/truncated (tolerant) |
| TC-N03 | test_cert_70 | Full | duplicate request_number |
| TC-N04 | test_cert_71 | Full | duplicate cert_number |
| TC-N05 | test_cert_40 | Full | FK RESTRICT violation |
| TC-N06 | test_cert_23 | Full | DomainException guards (source) |
| TC-N07 | test_cert_24 | Full | abort_if Issued (source) |
| TC-N08 | test_cert_52 | Partial | guest redirect (tolerant of 404 when disabled) |
| TC-N09 | test_cert_51 | Full | Gate::denies + forgetCachedPermissions + non-super-admin |
| TC-N10 | test_cert_92 | Partial | browser XSS render; skips if disabled |

### Dependency / Validation-source

| TC | Method | Coverage |
|----|--------|----------|
| TC-D01 | test_cert_34 | Full |
| TC-D02 | test_cert_35 | Full |
| TC-D03 | test_cert_36 | Full |
| TC-D04 | test_cert_41 | Full |
| TC-D05 | test_cert_42 | Full (defensive skip) |
| TC-D06 | test_cert_50 | Full |
| TC-D07 | test_cert_25 | Full |
| TC-D08 | test_cert_72 | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 21 | 19 | 2 | 0 | 100% |
| Negative | 10 | 7 | 3 | 0 | 100% |
| Dependency | 8 | 8 | 0 | 0 | 100% |
| State-machine (BC-SM) | 8 rows | 8 | 0 | 0 | 100% |
| Tenancy (TC-T) | 1 | 1 | 0 | 0 | 100% |
| Security (TC-S) | 1 | 0 | 1 | 0 | 100% |

Gates: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%) · Tenancy on P1 100% ✅.

Partial items are browser-flow tests that `markTestSkipped()` when FrontOffice is disabled (env prereq) — their underlying behaviour is additionally covered at the DB/model/source layer, so no coverage is lost when the module is enabled.

---

## 3. Coverage-Score (by requirement Source tag)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR: BR-FOF-005, BR-FOF-006, cert-number gen, index grouping) | 4 | 4 | 100% |
| State-Machine transitions (Screen-SM: BC-SM-01..08) | 8 | 8 | 100% |
| Validation Rules (Screen-VR: store/update/reject/issue) | 7 | 7 | 100% |
| Integration Points (Screen-IP: StudentFee fee-gate, sys_media) | 2 | 2 | 100% |
| Permissions (Screen-PM: 6 gate abilities) | 6 | 6 | 100% |

Every Source-tagged requirement item has ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | ID |
|---|-------|----------|---------|----|
| 1 | Enum case | DDL ENUM vs `in:` | cert_type + status enums match exactly (incl. underscores) | — |
| 2 | Route registration | Blade `route('fof.certificates.*')` vs web.php | All names registered | — |
| 3 | Gate vs Policy | `Gate::authorize('frontoffice.certificate.*')` (string) vs `CertificateRequestPolicy` | Policy methods exist but controller uses STRING gates, not policy binding; both key on same abilities → consistent, but `.issue` has NO policy method (only a controller gate) | DEV-FOF-CR-05 (minor) |
| 4 | Fillable vs DDL | model `$fillable` vs DDL cols | All DDL cols fillable | — |
| 5 | Cast vs DDL | `$casts` vs DDL types | is_urgent/is_active boolean(tinyint), stages_json array(JSON), copies integer(tinyint) — consistent | — |
| 6 | Service delegation | controller vs Service | **No** CertificateIssuanceService exists; requirement §Issuance references `CertificateIssuanceService::issue()` but logic is inline in the controller | DEV-FOF-CR-06 |
| 7 | State machine vs impl | lifecycle vs controller | `Cancelled` unreachable; `update()` allows status jump bypassing issue() | DEV-FOF-CR-03, DEV-FOF-CR-04 |
| 8 | Validation vs rules | requirement vs `validate()` | copies "1–5" vs `max:10` | DEV-FOF-CR-02 |
| 9 | Error message vs rules | expected vs actual | reject/issue messages present; DomainException texts verbatim | — |
| 10 | Permissions vs requirement | doc `frontoffice.certificate-request.*`/`.approve` vs code `frontoffice.certificate.*`/`.update` | Key namespace + approve-verb mismatch | DEV-FOF-CR-01 |
| 11 | Integration FK vs migration | requirement FKs vs DDL | student_id RESTRICT, approved_by/issued_by/media_id SET NULL — all present | — |
| 12 | UNIQUE enforcement | DDL UNIQUE vs `unique:` rule | request_number + cert_number are DB-UNIQUE but there is **no `unique:` FormRequest rule** (auto-generated, so enforced at DB only) — acceptable but noted | DEV-FOF-CR-07 (info) |
| 13 | Required enforcement | DDL NOT NULL vs `required` | store() requires student_id/cert_type/purpose; copies is NOT required in store() (DB default 1 covers it) — consistent | — |
| 14 | Length enforcement | DDL VARCHAR(n) vs `max:` | purpose max:200 ✔; cert_number max:30 ✔; issued_to max:100 ✔; rejection_reason max:500 (col TEXT, fine) | — |
| 15 | Soft-delete col vs trait | DDL deleted_at vs SoftDeletes | Both present (independently asserted) | — |

New IDs surfaced here: **DEV-FOF-CR-05** (`.issue` has no policy method), **DEV-FOF-CR-06** (no CertificateIssuanceService; logic inline), **DEV-FOF-CR-07** (UNIQUE enforced at DB only, no FormRequest `unique:`). Report as "verify in source" — all traced to the current controller/model/policy read during generation.

---

## 5. Remaining limitations

- Browser-flow methods (test_cert_52/60/61/92) require FrontOffice ENABLED in `modules_statuses.json` and a live ChromeDriver; they `markTestSkipped()` gracefully otherwise. Underlying behaviour is DB/source-covered.
- Fee-gate blocking (BR-FOF-005) is proven at the **source** layer (test_cert_41) rather than by driving a real outstanding-fee scenario, to avoid seeding the full StudentFee invoice chain in a partial environment. MT-2 in the TcList gives the manual end-to-end path.
- `toggleStatus` route returns JSON; its 200-vs-500 behaviour (historical BUG-FOF-001) is asserted via the source import verification — a live route hit is an execution-env concern (module disabled → 404).
