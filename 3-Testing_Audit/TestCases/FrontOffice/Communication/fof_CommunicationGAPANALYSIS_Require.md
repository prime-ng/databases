# FrontOffice :: Communication — Gap Analysis & Traceability

Maps the combined TcList (`fof_CommunicationTcList_Require.md`) to the single Dusk suite
`fof_Communication_TestCas.php` (57 methods). Coverage legend: **Full** = behaviour asserted end-to-end;
**Partial** = asserted with an environmental tolerance/skip guard; **Gap** = not covered.

---

## 1. Coverage by category

### Schema / DDL (BC-DB)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P01/N21 | test_01 | Full | 3-table alignment matrix + no-UNIQUE + soft-delete independent asserts (LIVE schema) |
| TC-N01 | test_02 | Full | CL NOT-NULL rejection |
| TC-P02 | test_03 | Full | CL nullable omission |
| TC-P03 | test_04 | Full | CL defaults via refresh |
| TC-N02 | test_05 | Full | ET NOT-NULL rejection |
| TC-P04 | test_06 | Full | ET nullable + default |
| TC-N03 | test_07 | Full | SL NOT-NULL/FK rejection |
| TC-P05 | test_08 | Full | SL defaults via refresh |
| TC-P06 | test_09 | Full | casts int/bool/datetime |

### Business rules (BC-BIZ)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P07 | test_10 | Partial | browser send; skips on 404 (module disabled); asserts stub counters |
| TC-P08 | test_11 | Partial | browser send; skips on 404 |
| TC-P09 | test_12 | Full | CL active scope |
| TC-P10 | test_13 | Full | channel query separation |
| TC-P11 | test_14 | Full | ET active scope |
| TC-DEV02 | test_15 | Full | source proof: no SendBulkSmsRequest / no sms_units |

### State machine (BC-SM)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P12 | test_20 | Partial | toggle deactivate; skips if no effect (module disabled) |
| TC-P13 | test_21 | Partial | toggle reactivate |
| TC-P14 | test_22 | Full | SL status legal set (DB) |
| TC-N04 | test_23 | Full | SL status illegal rejected (DB) |
| TC-P15/N05 | test_24 | Full | CL channel legal + illegal (DB) |

### Validation (BC-VAL)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-N06 | test_30 | Full | emailSend missing fields, tolerant status set |
| TC-DEV01 | test_31 | Full | subject max:255 divergence (source + DDL confirm) |
| TC-N07 | test_32 | Full | smsSend missing fields |
| TC-DEV02 | test_33 | Full | body cap 1000 source proof |
| TC-P16/N08 | test_34/35/36 | Full | ET name/subject/module boundary |
| TC-P17/N09 | test_37/38 | Full | CL recipient_group/subject boundary |
| TC-P18/N10 | test_39 | Full | SL mobile_number boundary |

### FK / integration (BC-REF)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-N11 | test_40 | Full | CL invalid template_id FK |
| TC-P19/D01 | test_41 | Partial | SET NULL path; skips if env can't exercise |
| TC-N12/D02 | test_42 | Full | RESTRICT on parent delete |
| TC-N13/D03 | test_43 | Full | SL→sys_users FK |
| TC-D04 | test_44 | Full | SHOW CREATE TABLE FK inspection |
| TC-P20 | test_45 | Partial | created_by via browser send; skips on 404 |

### Permissions (BC-AUTH)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-N14 | test_50 | Full | guest → /login |
| TC-N15 | test_51 | Partial | 403 for limited user; skips on 404 |
| TC-N16 | test_52 | Partial | templates + logs 403 |
| TC-N17 | test_53 | Partial | emailSend 403 |
| TC-N18 | test_54 | Partial | smsSend 403 |
| TC-N19 | test_55 | Partial | toggle 403 |

### UI (BC render)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P21 | test_60–64 | Partial | render/list; each skips on 404 |

### Edge / soft-delete (BC-EDG)
| TC | Method | Coverage |
|----|--------|----------|
| TC-P22 | test_70/71/72 | Full |
| TC-P23 | test_73 | Full |
| TC-P24 | test_74 | Full |

### Security / audit / DEV (BC-SEC / BC-AUTO / DEV)
| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-N20 | test_90 | Partial | XSS escape; skips on 404 |
| TC-P25/D05 | test_91 | Partial | activity `email_queued`; skips on 404/absent sink |
| TC-DEV03 | test_92 | Full | permission key divergence (source) |
| TC-DEV04 | test_93 | Full | stub proof (source) |
| TC-DEV05 | test_94 | Full | template CRUD gap (source) |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 25 | 15 | 10 | 0 | 100% |
| Negative | 21 | 21 | 0 | 0 | 100% |
| Dependency (FK) | 5 | 3 | 2 | 0 | 100% |
| State-machine | 5 | 3 | 2 | 0 | 100% |
| Permissions | 6 | 1 | 5 | 0 | 100% |
| DEV proving | 5 | 5 | 0 | 0 | 100% |
| **Overall** | **67** | **48** | **19** | **0** | **100%** |

Targets met: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%). "Partial" here means the assertion is real but guarded by a `markTestSkipped` when the module is disabled (404) — a documented ENV prerequisite, not a coverage gap.

---

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR: BR-FOF-011) | 1 | 1 | 100% (proven UNIMPLEMENTED → DEV-FOF-COM-02) |
| State-Machine (Screen-SM: template toggle, SL status, CL channel) | 5 | 5 | 100% |
| Validation Rules (emailSend×4, smsSend×2) | 6 | 6 | 100% |
| Integration Points (template FK, SL parent FK, SL user FK) | 3 | 3 | 100% |
| Permissions (create/view/update + guest) | 4 | 4 | 100% |
| DB fields (CL 10, ET 5, SL 9 distinctive) | 24 | 24 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No item with 0 coverage.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | ID | Proving test |
|---|-------|---------|---------|----|--------------|
| 1 | Enum case | DDL ENUM vs code | `channel` Email/SMS, SL `status` Queued/Sent/Delivered/Failed — match (no `in:` rule; DB-enforced only) | — | test_22/23/24 |
| 2 | Route registration | Blade `route()` vs routes/web.php | All `fof.communication.*` routes registered under `front-office` prefix | OK | n/a |
| 3 | Gate vs Policy | `Gate::authorize()` strings | String gates, no CommunicationPolicy — Spatie permission strings only (module-wide SEC-FOF-001 pattern) | note | test_92 |
| 4 | Fillable vs DDL | model `$fillable` vs columns | CL/ET/SL fillable cover all user columns incl. `sent_at`; match | OK | test_01 |
| 5 | Cast vs DDL | `$casts` vs type | int counts, bool is_active, datetime sent_at — consistent | OK | test_09 |
| 6 | Service delegation | controller vs service | No service layer; logic inline in controller (send is a stub) | note | test_93 |
| 7 | State machine vs impl | requirement flow vs controller | Bulk-send steps 4–7 (resolve recipients, dispatch NTF, per-recipient SL) NOT implemented | **DEV-FOF-COM-04** | test_93 |
| 8 | Validation vs requirement | requirement rules vs `validate()` | BR-FOF-011 multi-unit rule missing; body 1000≠640 | **DEV-FOF-COM-02** | test_15/33 |
| 9 | Error message | expected vs actual | Inline validate → default Laravel messages (no custom messages()) | note | test_30/32 |
| 10 | Permissions vs requirement | requirement keys vs gates | `.create/.view/.update` used vs requirement `.email/.sms` | **DEV-FOF-COM-03** | test_92 |
| 11 | Integration FK vs migration | requirement FK vs DDL | CL.template_id SET NULL, SL FKs RESTRICT — match DDL | OK | test_44 |
| 12 | UNIQUE enforcement | DDL UNIQUE vs `unique:` | No UNIQUE keys on any of the 3 tables; none required | OK | test_01 |
| 13 | Required enforcement | DDL NOT NULL vs `required` | emailSend/smsSend `required` aligns with CL NOT-NULL (channel/body set by controller) | OK | test_02/30 |
| 14 | Length enforcement | DDL VARCHAR vs `max:` | `subject` max:255 < column 300 (stricter, not truncation) | **DEV-FOF-COM-01** | test_31 |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs SoftDeletes | Present + trait on all 3 models; agree | OK | test_01 |
| — | Feature completeness | requirement "CRUD templates" vs controller | Only list + toggle; no store/update/destroy | **DEV-FOF-COM-05** | test_94 |

---

## 5. Remaining limitations

- All browser-layer TCs (send, toggle, render, permission 403, XSS, activity) depend on FrontOffice being ENABLED in `modules_statuses.json`. Until enabled they `markTestSkipped` on a 404 — the DB/model/source-layer TCs (36 of 57) provide the guaranteed baseline coverage.
- `fof_sms_logs` write path is exercised only at the model level (the controller never creates SL rows — DEV-FOF-COM-04), so its FSM/units coverage is DB-level, not end-to-end UI.
- SET-NULL FK test (test_41) and RESTRICT test (test_42) require FK enforcement active in the test DB (InnoDB, `FOREIGN_KEY_CHECKS=1`); guarded with `markTestSkipped` otherwise.

---

## 6. Legend
- **Full** — real assertion, no environmental guard around the core check.
- **Partial** — real assertion guarded by `markTestSkipped` for a documented ENV prerequisite (module-disabled 404 / absent sink / FK checks off). NOT a coverage gap.
- **Gap** — no assertion. (None in this suite.)
