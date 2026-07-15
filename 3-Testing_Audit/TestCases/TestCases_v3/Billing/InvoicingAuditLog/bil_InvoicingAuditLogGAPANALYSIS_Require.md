# Invoice Audit Log — Gap Analysis (`bil_InvoicingAuditLog`)

Single suite: **`bil_InvoicingAuditLog_TestCas.php`** — **42 test methods**. `php -l` clean.

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01/P02/P17/P03 (config/schema) | `test_01,02,06,07` | Full |
| TC-P04/P05/P06/P07 (biz) | `test_10,11,12,13` | Full |
| TC-P08/P09/P10 (FK/relations) | `test_40,41,42,43` | Full |
| TC-P11/P12/P13/P14/P15 (UI) | `test_60,61,62,63,64,65` | Full |
| TC-P16 (nullable performed_by) | `test_71,72` | Full |

### Negative
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N01/N02/N03 (invalid id → 404) | `test_30,31,32` | Full |
| TC-N04/N05 (length bounds) | `test_33,70` | Full |
| TC-N06 (guest redirect) | `test_34` | Full |
| TC-N07/N08/N09 (XSS/IDOR) | `test_35,92,93` | Full |

### Dependency / Auth / Security / Tenancy
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-D01/D02 (FK cascade/set-null) | `test_40,41` | Full |
| TC-D03 (queue gap) | `test_73` | Partial (documented; job source may be absent) |
| TC-S01..S06 (authz) | `test_50,51,52,53,54,55` | Full |
| TC-T01 (central scope) | `test_90` | Full |
| TC-DEV01..05 (defects) | `test_03,04,05,14,91` | Full (proving) |

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 17 | 17 | 0 | 0 | 100% |
| Negative | 9 | 9 | 0 | 0 | 100% |
| Dependency/FK | 3 | 2 | 1 | 0 | 67% (Full+Partial 100%) |
| Auth/Security | 8 | 8 | 0 | 0 | 100% |
| Tenancy | 1 | 1 | 0 | 0 | 100% |
| Defect proving | 5 | 5 | 0 | 0 | 100% |
| **Overall** | **43** | **42** | **1** | **0** | **97.7%** |

Gate check: Negative **100%** ✅ · Positive **100%** (≥90) ✅ · Dependency **100% incl. partial** (≥90) ✅ · Tenancy **100%** on P0 central ✅.

Partial note: TC-D03 `test_73` asserts only that `SendInvoiceEmailJob` exists (queue `Auth::id()`-null risk); it cannot force a real queued insert because the schema is P0-broken. Skips cleanly if the job file is absent.

## 3. Coverage-Score by requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: append-only, action-types, sensitive-data, queue) | 4 | 4 | 100% |
| State-Machine (`Screen-SM`) | 0 | 0 | n/a (append-only, no FSM) |
| Validation Rules (`Screen-VR`: id/404, length, escaping) | 5 | 5 | 100% |
| Integration Points (`Screen-IP`: invoice FK, user FK, dropdown source) | 3 | 3 | 100% |
| Permissions (`Screen-PM`: 7 keys + 2 anomalies) | 9 | 9 | 100% |

Every `Source`-tagged requirement item maps to ≥1 TC. No requirement area at 0 coverage.

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | Proving test |
|---|-------|----------|---------|--------------|
| 1 | Enum/status values | Screen action_type list vs blade dropdown | Blade omits `PAYMENT_UPDATED`/`PENDING`; adds `Overdue` — cosmetic drift | `test_62` |
| 2 | Route registration | Blade `route('central.billing.audit.*')` vs `routes/web.php` | All 5 registered (app-level web.php, not module) | `test_55` |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.*')` vs Policy methods | Aligned for note/event/pdf; **AuditLog uses billing-management.view** (DEV-BIL-A05) | `test_53` |
| 4 | Fillable vs DDL | Model `$fillable` `tenant_invoice_id` vs DDL `tenant_invoicing_id` | **MISMATCH → DEV-BIL-A01 (P0)** | `test_03` |
| 5 | Cast vs DDL/req | Model casts vs requirement (`event_info` array-cast) | `event_info` **not** cast → DEV-BIL-A06 | `test_05` |
| 6 | Service delegation | Controller vs Service | No service layer — logic inline in controllers (noted) | `test_10,13` |
| 7 | State machine vs impl | Append-only vs controllers | Confirmed append-only; only `notes` mutable | `test_10` |
| 8 | Validation vs FormRequest | Requirement vs `rules()` | **No FormRequest** — relies on `findOrFail` + DB limits (thin validation) | `test_30-33` |
| 9 | Error message vs source | Toast text vs controller | `Audit note updated successfully!` verbatim | `test_11` (activity), MTC-02 |
| 10 | Permissions vs blade | Blade `@can('audit.*')` vs backend `prime.*` | **MISMATCH → DEV-BIL-A04 (P2)**; note-edit UI hidden | `test_52` |
| 11 | FK vs migration/DDL | Requirement FK vs DDL `FOREIGN KEY` | CASCADE (invoice) + SET NULL (user) present; DDL FK references `bil_tenant_invoicing` (vs actual `bil_tenant_invoices`) — table-name drift noted | `test_40,41` |
| — | SoftDeletes vs columns | Model `SoftDeletes`+timestamps vs DDL | **MISMATCH → DEV-BIL-A02 (P0)** (no deleted_at/updated_at) | `test_04` |
| — | Mass-assign / sensitive data | Requirement whitelist vs `event_info` writes | Raw request keys beyond whitelist → **DEV-BIL-A03 (P1)** | `test_91` |

### Discovered/confirmed defects (audit-equivalent)
| ID | Sev | Status vs audit report | Proving test |
|----|-----|------------------------|--------------|
| DEV-BIL-A01 / DATA-BIL-001 | P0 | Confirmed (note: DDL-v1 col = `tenant_invoicing_id`; model = `tenant_invoice_id` — mismatch either direction) | `test_03` |
| DEV-BIL-A02 / MIG-BIL-001 | P0 | Confirmed | `test_04` |
| DEV-BIL-A03 / SEC-BIL-011 | P1 | **Partially remediated** — literal `$request->all()` removed; residual over-capture of `remarks`/`gateway_resp`/`payment_reconciled` remains | `test_91` |
| DEV-BIL-A04 | P2 | New/confirmed (blade key mismatch) | `test_52` |
| DEV-BIL-A05 | P3 | New/confirmed (read route perm) | `test_53` |
| DEV-BIL-A06 | P3 | Confirmed (missing cast) | `test_05` |
| DEV-BIL-A07 | P3 | Confirmed (action_type mislabels) | `test_14` |

> **Honest-state note (HARD RULE 11/13):** the audit report (2026-06-29) listed "9 routed methods without permission checks (incl. note-edit write)". In **current** source those methods DO carry `Gate::authorize(...)` — that finding is largely **remediated**. This suite asserts the real, current gates (`test_51`) and documents only the residual authorization anomalies (DEV-BIL-A04/A05) that persist in current source, rather than asserting a stale bug.

## 5. Legend
Full = automated assertion(s) directly verify the TC. Partial = verified indirectly or gated on optional source/env (skips cleanly). Gap = none.
