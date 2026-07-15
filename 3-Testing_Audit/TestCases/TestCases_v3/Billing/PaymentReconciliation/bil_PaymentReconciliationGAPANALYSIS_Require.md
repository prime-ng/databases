# Payment Reconciliation — Gap Analysis & Coverage

**Feature:** PaymentReconciliation · **Module:** Billing (`bil_`) · **Test file:** `bil_PaymentReconciliation_TestCas.php` (33 methods)
**Screen type:** READ/REPORT + manual toggle → report-focused matrix (no create/edit/delete CRUD).

---

## 1. Manual TC ↔ Dusk Method Mapping

### Positive
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01 Config truth | `_01` | Full |
| TC-P02 Routes/policy | `_02` | Full |
| TC-P03 Gate/event strings | `_03` | Full |
| TC-P04 Tab render | `_10` | Full |
| TC-P05 Filter options | `_11` | Full |
| TC-P06 Table columns | `_12` | Full |
| TC-P07 Reconciled bucket | `_13` | Full (skips if no data/FK) |
| TC-P08 Non-reconciled bucket | `_14` | Full (skips if no data/FK) |
| TC-P09 Bucket partition/total | `_15` | Full |
| TC-P10 Toggle 0→1 + log | `_16` | Full (skips if no seed) |
| TC-P11 Toggle 1→0 | `_17` | Full (skips if no seed) |
| TC-P12 Report reflects DB | `_18` | Full |
| TC-P13 Print view | `_34` | Full |
| TC-P14 Pagination 10 | `_61` | Full |
| TC-P15 Export controls | `_62` | Full |

### Negative
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N01 Toggle 404 | `_30` | Full |
| TC-N02 Remark id required | `_31` | Full |
| TC-N03 Remark max 5000 | `_32` | Full |
| TC-N04 PDF no ids 400 | `_33` | Full |
| TC-N05 Guest redirect | `_50` | Full |
| TC-N06 Guest toggle blocked | `_91` | Full |
| TC-N07 Index 403 gate | `_51` | Full (source-level) |
| TC-N08 XSS remarks escaped | `_90` | Full (source-level) |

### Dependency / Authorization / Edge
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-D01 Payment↔invoice | `_40` | Full (skips if no data) |
| TC-D02 FK target | `_41` | Full |
| TC-D03 SoftDeletes divergence | `_42` | Full |
| TC-A01 PDF perm mismatch | `_52` | Full |
| TC-A02 Print perm mismatch | `_53` | Full |
| TC-A03 Toggle perm | `_54` | Full |
| TC-E01 Toggle current value | `_70` | Full |
| TC-E02 Sub-details id mismatch | `_71` | Full |
| TC-E03 Remark audit id | `_72` | Full |
| TC-U01 Empty state | `_60` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 15 | 15 | 0 | 0 | 100% |
| Negative | 8 | 8 | 0 | 0 | 100% |
| Dependency | 3 | 3 | 0 | 0 | 100% |
| Auth/Edge/UI/Sec | 10 | 10 | 0 | 0 | 100% |
| **Total** | **36** | **36** | **0** | **0** | **100%** |

> Gate targets — Negative 100% ✅, Positive ≥90% ✅ (100%), Dependency ≥90% ✅ (100%). Tenancy 100% N/A (central/prime-side; cross-tenant isolation is not the risk model for a Super-Admin-only central screen — see §5).

**Partial-coverage / limitation notes:**
- Data-dependent methods (`_13,_14,_16,_17,_40`) `markTestSkipped` when no `bil_tenant_invoices` parent exists to satisfy the `NOT NULL` FK (seeding a full invoice chain is out of scope for a report screen). They assert real behaviour when a payment/invoice exists.
- HTTP negative probes (`_30–_33,_91`) accept a **status set** (e.g. `{404,403,419,302}`) rather than a single code, to stay green across the central-domain/host and CSRF configuration of the runner (Constraint E20/E21). This is a deliberate robustness choice, not a coverage gap.
- Permission-mismatch and edge findings (`_52,_53,_70,_71,_72`) are **source-inspection** assertions (read the real prime_ai file and assert exact strings); they skip if the app tree is unreachable.

---

## 3. Coverage-Score by Requirement Section (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: manual toggle, audit trail, filter) | 4 | 4 | 100% |
| Filter System (`Screen-Filter`: date_range, 3-way status) | 2 | 2 | 100% |
| CRUD/Operations (`Screen`: toggle, list, PDF, print) | 4 | 4 | 100% |
| Permissions (`Screen-PM`: viewAny, status, pdf) | 3 | 3 | 100% |
| Current Gaps (`Screen`: no auto-match) | — | — | Documented as product gap, not testable defect |

Every `Source`-tagged requirement item has ≥1 TC. The screen's "Current Gap" section (no automated bank-matching, RBS tasks ST.V3.2.2.1/.2) is an unimplemented-feature note, not a defect — recorded here, no proving test.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared layers | Finding | DEV |
|---|-------|-----------------|---------|-----|
| 1 | Enum case | DDL `mode/payment_status` vs Model/Request | No FormRequest `in:` on reconciliation; no mismatch | — |
| 2 | Route registration | Blade `route(...toggleStatus)` vs `routes/web.php` | Registered; central block registered **3×** | BUG-BIL-014 |
| 3 | Gate vs Policy | Controller `Gate::authorize` vs Policy | `toggleStatus` gates `billing-management.status` (Policy is `payment-reconciliation.*`) → shared/loose | note |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | Match | — |
| 5 | Cast vs DDL | `payment_reconciled=>boolean` vs `tinyint(1)` | Correct | — |
| 6 | Service delegation | Controller vs Service | Reconciliation logic inline in controller (acceptable for a toggle) | — |
| 7 | State machine | n/a (boolean toggle, no FSM) | — | — |
| 8 | Validation vs FormRequest | Screen vs `updateInvoiceRemarks` | Matches (`id integer`, `remarks max:5000`) | — |
| 9 | Error message vs source | Expected vs `downloadSelectedPdf` | `'No items selected'` verbatim | — |
| 10 | Permissions vs Policy/Gates | Button `@can` vs endpoint `Gate::authorize` | **PDF & Print button perms ≠ endpoint perms** | DEV-BIL-R02, DEV-BIL-R03 |
| 11 | Integration FK vs migration | Requirement FK vs DDL `foreign()` | DDL FK targets non-existent `bil_tenant_invoicing` | DEV-BIL-R06 |
| + | Soft-delete backing | Model trait vs DDL column | `SoftDeletes` w/o `deleted_at` | DEV-BIL-R01 |
| + | Audit id semantics | `updateInvoiceRemarks` vs audit col | payment id stored in `tenant_invoice_id` | DEV-BIL-R04 |
| + | Link id semantics | Blade `data-id` vs `subscriptionDetails()` | invoice id passed where schedule id expected | DEV-BIL-R05 |

### DEV register (feature-scoped)
| DEV | Severity | Proving test | Status |
|-----|----------|--------------|--------|
| DEV-BIL-R01 | P0 (schema) | `_01`, `_42` | Open — MIG-BIL-001; add `deleted_at` or drop SoftDeletes |
| DEV-BIL-R02 | P2 | `_52` | Open — align PDF button/endpoint permission |
| DEV-BIL-R03 | P2 | `_53` | Open — align Print button/endpoint permission |
| DEV-BIL-R04 | P3 | `_72` | Open — store invoice id (or a distinct payment column) in audit |
| DEV-BIL-R05 | P2 | `_71` | Open — pass billing-schedule id to Subscription Details |
| DEV-BIL-R06 | P1 (DDL) | `_41` (doc) | Open — correct FK target to `bil_tenant_invoices` |

---

## 5. Notes on skipped enhanced dimensions
- **Tenancy isolation (TC-T):** deliberately **not** emitted — this is a central/prime-side Super-Admin screen (`prime_db`), not tenant-scoped; there is no cross-tenant visibility surface to isolate. Recorded per role prompt.
- **Full CRUD matrix:** deliberately not emitted — report + toggle screen (no create/edit/delete/restore on reconciliation). Soft-delete is covered only as a divergence guard (`_42`).
- **Accessibility/responsive smoke:** omitted for this read screen (low risk); can be added if the tab gains interactive widgets.

**Legend:** Full = behaviour asserted end-to-end or at source-of-truth; Partial = asserted with an environmental caveat; Gap = no coverage. Skips (`markTestSkipped`) keep partial environments green and are not counted as gaps.
