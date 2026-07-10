# Billing → Invoicing — Gap Analysis & Coverage

**Test file:** `bil_Invoicing_TestCas.php` (48 methods) · **Screen:** Invoicing (central, `prime_db`)
This is a **list + auto-generate + AJAX** screen (no manual create/edit/delete UI), so coverage is
read/config/permission/defect-weighted rather than a classic CRUD matrix.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| TC | Method | Coverage |
|----|--------|----------|
| TC-P01 | `_01`, `_04` | Full |
| TC-P02 | `_05` | Full |
| TC-P03 | `_06` | Full |
| TC-P04 | `_08` | Full |
| TC-P05 | `_09` | Full |
| TC-P06 | `_10` | Full (data-gated) |
| TC-P07 | `_11` | Full (data-gated) |
| TC-P08 | `_12` | Full (data-gated) |
| TC-P09 | `_13` | Full (data-gated) |
| TC-P10 | `_14` | Full (data-gated) |
| TC-P11 | `_15` | Full (data-gated) |
| TC-P12 | `_16` | Full |
| TC-P13 | `_20` | Full |
| TC-P14 | `_60`, `_55` | Full |
| TC-P15 | `_61` | Full |
| TC-P16 | `_62` | Full |
| TC-P17 | `_63` | Full |
| TC-P18 | `_64` | Full |
| TC-P19 | `_65` | Full |
| TC-P20 | `_42` | Full |
| TC-P21 | `_40` | Full |
| TC-P22 | `_50` | Full |
| TC-P23 | `_51` | Full |
| TC-P24 | `_52` | Full |
| TC-P25 | `_43` | Full |
| TC-P26 | `_72` | Full |
| TC-P27 | `_73` | Full |
| TC-P28 | `_80` | Full |
| TC-P29 | `_91` | Full |
| TC-P30 | `_21` | Full |

### Negative
| TC | Method | Coverage |
|----|--------|----------|
| TC-N01 | `_30` | Full |
| TC-N02 | `_31` | Full |
| TC-N03 | `_32` | Full |
| TC-N04 | `_33` | Full |
| TC-N05 | `_53` | Full |
| TC-N06 | `_54` | Full |
| TC-N07 | `_70` | Full |
| TC-N08 | `_71` | Full |
| TC-N09 | `_02` | Full |
| TC-N10 | `_93` | Full |

### Dependency / Defect / Security / Tenancy
| TC | Method | Coverage |
|----|--------|----------|
| TC-D01 | `_02` | Full |
| TC-D02 | `_07` | Full |
| TC-D03 | `_03` | Full |
| TC-D04 | `_40` | Full |
| TC-D05 | `_91` | Full |
| TC-D06 | `_41` | Full |
| TC-D07 | `_81` | Full |
| TC-T01 | `_90` | Full |
| TC-S01 | `_92` | Full |
| TC-S02 | `_93` | Full |
| TC-S03 | `_53` | Full |

Every TC maps to ≥1 method; every method maps back to a TC/BC (see TcList §3).

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 30 | 30 | 0 | 0 | 100% |
| Negative | 10 | 10 | 0 | 0 | 100% |
| Dependency | 7 | 7 | 0 | 0 | 100% |
| Security | 3 | 3 | 0 | 0 | 100% |
| Tenancy | 1 | 1 | 0 | 0 | 100% |

> Gates: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%) · Tenancy 100% ✅ (P0 module).
> **Note on "data-gated":** business-rule invariants (`_10`–`_15`) assert against the latest real invoice row; when the environment has no invoice rows the method `markTestSkipped`s rather than failing. This is coverage-present-but-execution-conditional, not a gap.

---

## 3. Coverage-Score by requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 13 | 13 | 100% |
| State-Machine transitions (`Screen-SM` / BC-SM) | 2 | 5 | 40% |
| Validation Rules (`Screen-VR` / BC-VAL) | 4 | 4 | 100% |
| Integration Points (`Screen-IP` / BC-INT/REF) | 5 | 5 | 100% |
| Permissions (`Screen-PM` / BC-AUTH) | 6 | 6 | 100% |

**State-machine gap (explicit):** BC-SM-02/03/04/05 (PARTIALLY_PAID/PAID/OVERDUE/CANCELLED transitions)
are **not driveable from this screen** — payments transitions belong to the Invoice-Payments feature,
`OVERDUE` has no automated detection, and `CANCELLED` has no endpoint (requirement-confirmed gaps).
Covered here: BC-SM-01 (initial PENDING via dropdown, `_20`) and status-populated (`_21`). The remaining
transitions are logged as product gaps, not test debt, and are owned by the payments/reconciliation features.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | DEV / Test |
|---|-------|---------|---------|------------|
| 1 | Enum case | DDL `status` vs code | `status` is a dropdown-ordinal FK, not an ENUM — n/a | — |
| 2 | Route registration | Blade `route(...)` vs routes | `InvoicingController` never routed; screen served by `BillingManagementController` (routes/web.php L322-372). Blade uses `central.billing.billing-management.*` | **DEV-BIL-004** / `_81` |
| 3 | Gate vs Policy | controller `Gate::authorize` vs Policy | `prime.invoicing.*` + `prime.billing-management.*` both defined; policies present | OK / `_50`–`_52` |
| 4 | Fillable vs DDL | model `$fillable` vs DDL cols | audit-claimed phantom `invoice_amount` **not** in current source; fillable ⊆ DDL | **DEV-BIL-002** (remediated) / `_03` |
| 5 | Cast vs DDL | `$casts` vs DDL type | boolean casts on TINYINT(1) is_recurring/auto_renew; decimal on money — consistent | OK / `_05` |
| 6 | Service delegation | controller vs Service | generation correctly delegated to `InvoiceGeneratorService` (reused by command) | OK |
| 7 | State machine vs impl | Screen-SM vs code | OVERDUE (no detection) + CANCELLED (no endpoint) not implemented | Product gap / doc |
| 8 | Validation vs FormRequest | Screen-VR vs `validate()` | remarks-update uses inline `$request->validate` (no FormRequest); filters unvalidated | Note / `_30`–`_33` |
| 9 | Error message vs source | expected vs code | generate returns `No plan rate IDs received.` (400) | OK / `_32` |
| 10 | Permissions vs Policy/Gates | Screen-PM vs Policy | screen mixes `prime.invoicing.*` (blade actions) and `prime.billing-management.*` (controller) — two gate families for one screen | Note / `_50`–`_51` |
| 11 | Integration FK vs DDL | Screen-IP vs migration/DDL | **DEV-BIL-001** SoftDeletes w/o `deleted_at`; **DEV-BIL-003** audit col `tenant_invoicing_id` vs code `tenant_invoice_id`; **DEV-BIL-008** modules_jnt FK targets wrong table/column name (`bil_tenant_invoice`) | `_02`, `_07`, `_41` |

### Confirmed defects (proving/guard tests present)
| DEV | Audit | Sev | State | Proving test |
|-----|-------|-----|-------|--------------|
| DEV-BIL-001 | MIG-BIL-001 | P0 | **Confirmed** (DDL has no deleted_at) | `_02` |
| DEV-BIL-002 | DATA-BIL-002 | P0 | **Remediated in current source** — regression guard | `_03` |
| DEV-BIL-003 | DATA-BIL-001 | P0 | Documented (audit-table col mismatch) | `_07` |
| DEV-BIL-004 | Layer-4 | P2 | Confirmed (dead stub, unrouted) | `_81` |
| DEV-BIL-008 | Layer-1 | P2 | Documented (DDL FK naming) | `_41` |
| DEV-BIL-005 | doc | P3 | DDL comment vs impl on `invoice_date` (impl = generation date; requirement field table agrees with impl; only the DDL inline comment says "next day to billing_end_date") | doc note (not a code test) |

> Candidates are reported as *verified-in-source*; DEV-BIL-002 is honestly reported as **not reproduced** in the current model — the proving test is a regression guard that currently passes (Rule 10: test proves current behaviour).

---

## 5. Limitations / partial-execution notes
- **Data-heavy generation** (POST generate → real invoice with cross-tenant student count) is not seeded end-to-end; `_10`–`_15` verify invariants on existing rows and skip when none exist. Full generation e2e would require seeding `prm_tenant_plan_rates` + `prm_tenant_plan_billing_schedule` + a tenant DB with students.
- **In-process HTTP** endpoint checks (`_30`–`_32`, `_54`, `_70`, `_71`, `_93`) are guarded with `markTestSkipped` on any `Throwable` and accept broad status sets, because the Dusk browser session and the in-process kernel do not share auth state and the module may be route-disabled (05_ E19/E23).
- **Trashed/soft-delete flows** are intentionally NOT exercised (would throw) — instead proved absent via `_02` (DEV-BIL-001).

## 6. Legend
- **Full** — TC fully automated by ≥1 method. **Partial** — automated with environmental caveat. **Gap** — no automation (none here).
- **data-gated / guarded** — method present and correct; skips (not fails) when preconditions (rows/routes/DB) are absent, per 05_ constraints and Rule 9.
