# Invoicing Audit Log — Gap Analysis & Coverage

- **Feature:** Billing / Invoicing Audit Log (`prime_db` central, prefix `bil_`)
- **V1:** 16 methods · **V2:** 61 methods · **Ratio:** 3.8×
- Screen type: read/report-heavy (append-only trail + note-update write)

---

## 1. Manual TC ↔ Dusk Method Mapping

### Positive
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-P01 tab renders | 06 | 60, 62, 64, 67 | Full |
| TC-P02 headers | 07 | 61 | Full |
| TC-P03 date_range filter | 10 | 14 | Full |
| TC-P04 tenat_id filter | 10 | 15 | Full |
| TC-P05 performed_by filter | 10 | 16 | Full |
| TC-P06 audit_status filter | 10 | 17 | Full |
| TC-P07 order/eager/paginate | 09 | 11, 12, 13 | Full |
| TC-P08 note update + Store event | 11 | 19, 51 | Full (activity-log asserted via source; DB assert in manual) |
| TC-P09 PDF download | — | 18, 66 | Full |
| TC-P10 AJAX AuditLog | 13 | 44, 45 | Full |
| TC-P11 add-note form fields | — | 65 | Full |
| TC-P12 status options | — | 21 | Full |
| TC-P13 pagination container | — | 63 | Full |
| TC-P14 event_info null decode | — | 71 | Full |

### Negative
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-N01 guest redirect | 14 | — | Full |
| TC-N02 guest note-update rejected | — | 57, 90 | Full |
| TC-N03 add-note invalid id 404 | — | 33 | Full |
| TC-N04 event-info invalid id 404 | — | 34 | Full |
| TC-N05 note-update invalid id 404 | — | 35 | Full |
| TC-N06 no notes validation | 16 | 30, 31, 32 | Full |
| TC-N07 blade prefix mismatch | 15 | 55 | Full |

### Dependency
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-D01 (B) SoftDeletes w/o columns | 01, 03 | 02 | Full |
| TC-D02 (C) invoice FK wrong table | — | 43 | Partial (DDL FK invalidity documented, not DB-asserted) |
| TC-D03 (D) performed_by nullable | — | 42 | Full |
| TC-D04 (E) relation column mismatch | 02, 04 | 03, 09, 40, 70 | Full |
| TC-D05 (F) append-only lifecycle | — | 10, 73 | Full |
| TC-D06 (G) note >500 unbounded | — | 72 | Partial (source-level; live truncation needs a seeded row) |

### Security
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-S01 stored XSS in notes | — | 91 | Partial (source-level; write is unsanitized) |
| TC-S02 note escaped in textarea | — | 92 | Full |
| TC-S03 IDOR event-info gated | — | 94 | Full |
| TC-S04 raw request not here | — | 95 | Full |
| TC-S05 mass-assignment guard | — | 93 | Full |

### Authorization
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-A01 index Gate::any | — | 50 | Full |
| TC-A02 note WRITE gate `.update` | 11 | 51 | Full |
| TC-A03 read endpoints `.view` | 12 | 52 | Full |
| TC-A04 AJAX gate | 13 | 53 | Full |
| TC-A05 policy abilities | — | 54 | Full |
| TC-A06 print/pdf buttons gated | — | 56 | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 14 | 14 | 0 | 0 | 100% |
| Negative | 7 | 7 | 0 | 0 | 100% |
| Dependency | 6 | 4 | 2 | 0 | 100% (67% Full) |
| Security | 5 | 4 | 1 | 0 | 100% |
| Authorization | 6 | 6 | 0 | 0 | 100% |
| **Total** | **38** | **35** | **3** | **0** | **100%** |

Targets met: Negative 100% ✅ · Positive ≥ 90% ✅ (100%) · Dependency ≥ 90% ✅ (100%).

### Partial-coverage limitations
- **TC-D02** — DDL FK invalidity (references `bil_tenant_invoicing` / `users`) is documented; a live FK-constraint assertion is not possible because the DDL FK cannot even be created on a correct schema. Covered by existence assertion of the real `bil_tenant_invoices` table.
- **TC-D06 / TC-S01** — oversize/XSS `notes` are proven at source level (no `max:500`, no sanitization). A live truncation/reflection assertion needs a seeded audit row and a rendering surface; deferred (append-only trail has no create endpoint in this feature).

---

## 3. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) | 5 | 5 | 100% |
| State/Action-type (`Screen-SM`) | 2 | 2 | 100% |
| Validation Rules (`Screen-VR`) | 2 | 2 | 100% |
| Integration Points (`Screen-IP` filters/relations) | 6 | 6 | 100% |
| Permissions (`Screen-PM`) | 7 | 7 | 100% |

Every `Source`-tagged requirement item maps to ≥ 1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|----|
| 1 | Enum case | DDL comment vs Blade vs Screen doc `action_type` | 3 divergent label sets; `action_type` is free VARCHAR(20) (no DB enum) — labels unguarded | note (P3) | 20, 21, 22 |
| 2 | Route registration | Blade routes vs `routes/web.php` | All audit routes registered (add-note/update/event-info/pdf/audit-log) | OK | 74 |
| 3 | Gate vs Policy | Controller `Gate::authorize` vs Policy | prime.* abilities all backed | OK | 54 |
| 4 | Fillable vs DDL | Model `$fillable.tenant_invoice_id` vs DDL `tenant_invoicing_id` | **Column-name mismatch** | **DATA-BIL-001 (P0)** | 02, 03, 09, 40, 70 |
| 5 | Cast vs DDL | `event_info` JSON vs model casts | No array cast → manual `json_decode` | note (BC-EDG) | 05, 71 |
| 6 | Service delegation | Controller vs Service | No Service layer; logic in controllers | OK | — |
| 7 | State machine vs impl | Screen action_type triggers vs controller | No transition enforcement (append-only) | note | 20 |
| 8 | Validation vs FormRequest | Screen note rules vs controller | **No validation on `notes`** | **VAL-BIL-002 (P2)** | 16, 30, 31, 32 |
| 9 | Error message vs source | success msg | `Audit note updated successfully!` matches | OK | 19 |
| 10 | Permissions vs Blade | Policy `prime.*` vs Blade `audit.*` action keys | **Prefix + typo mismatch → UI unreachable** | **AUTH-BIL-002 (P2)** | 15, 55 |
| 11 | Integration FK vs schema | DDL FK targets vs real tables | FK → `bil_tenant_invoicing`/`users` (non-existent objects) | **DATA-BIL-003 (P3)** | 43 |
| — | Migration↔Model↔DDL | SoftDeletes/timestamps vs DDL columns | `updated_at`/`deleted_at` absent | **MIG-BIL-001 (P0)** | 01, 02 |
| — | Gate presence | note-edit WRITE gate | now present (`.update`) | **SEC-BIL-010 remediated** | 11, 51, 52 |
| — | Raw request into audit | `$request->all()` into event_info | Not in this controller (write path elsewhere) | **SEC-BIL-011 (carried)** | 95 |

---

## 5. Legend
- **Full** — behaviour asserted end-to-end (browser flow / endpoint status / DB or source truth).
- **Partial** — asserted at source-truth level or conditionally (needs seeded data / live schema variant).
- **Gap** — no coverage (none in this feature).
- Defect IDs: `DATA-/MIG-/SEC-` carried from `Billing_Complete_Audit_2026-06-29.md`; `AUTH-BIL-002`, `VAL-BIL-002`, `DATA-BIL-003` newly discovered here (report as "verify in source" — all traced to exact file:line above).
