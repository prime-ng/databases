# Prime-AI — Program Defect Register

**Generated:** 2026-Jul-09 17-02 (report mode · program scope · roll-up from existing artifacts only)
**Scope:** every module that currently has a test-artifact set under `TestCases/`.
**Aggregated from:** `Billing/Billing_Coverage_Dashboard.md`, `Billing/Billing_RTM.md`, `Billing/Billing_Feature_Inventory.md`, `BehaviouralAssessment/BehaviouralAssessment_Feature_Inventory.md`, and each feature's `*TcList_Require.md` / `*GAPANALYSIS_Require.md` / `*Validation_Report.md` on disk.
**Source-of-truth rule:** where the Jun-2026 audit registers disagree with the current `prime_ai` source, the source wins (per HARD RULE). Items the feature suites verified as already fixed are listed under **Remediated (audit stale)**.

> **Defect-ID conventions differ by module.** Billing uses `MIG-/DATA-/SEC-/VAL-/BUG-/JOB-/DEAD-/PERF-/AUTH-/INT-/OBS-BIL-*` and `DEV-BIL-*/DEV-EMS-*` for newly-discovered cross-reference findings. BehaviouralAssessment uses `BUG-/SEC-/DATA-/VAL-/AUTH-/DEAD-/DOC-BA-*` (its audit uses no `DEV-###`; these are the module's DEV-equivalents).

**Status legend:** `Open — proven` = live defect with a proving test in a generated V1/V2 suite that asserts current behaviour · `Open — pending` = documented, proving test not yet written because the owning feature is not yet generated · `Open — candidate` = newly-discovered in cross-reference scan, flagged "verify in source" · `Mitigated` = partial fix in source · `Remediated` = audit item verified already fixed in current source (closed).

---

## 1. Modules in scope (roll-up coverage)

| Module | Layer | Features generated | Features complete (8/8) | V1 methods | V2 methods |
|--------|-------|--------------------|--------------------------|-----------|-----------|
| Billing | `prime_db` central (SaaS invoicing) | 9 / 9 canonical | 9 | 136 | 413 |
| BehaviouralAssessment | tenant (`ba_*`) | 6 / 24 canonical | 5 (+Intervention V1/V2 only) | 93 | 262 |
| **Program** | — | **15** | **14** | **229** | **675** |

BehaviouralAssessment has 24 canonical screens; only the 6 Group-A masters/config are generated so far. Defects whose only proving feature is a not-yet-generated screen (Incident, MyAssessments, Rating, Witness, ReviewQueue, StudentRemark, ReportsHub, report screens) are `Open — pending`.

---

## 2. Billing (BIL) — defect register

### 2.1 Live defects (verified against current source)

| ID | Sev | Feature(s) | Description | Proving test | Status |
|----|-----|-----------|-------------|--------------|--------|
| MIG-BIL-001 | P0 | ALL (9) | Models declare `SoftDeletes` + default timestamps; DDL tables lack `deleted_at`/`updated_at` → `SQLSTATE 42S22` on a schema-correct prime_db (dev DB is hand-patched). | every V1 `test_01/02` (schema-guard, fail-fast) | Open — proven |
| DATA-BIL-001 | P0 | InvoicingAuditLog, Invoicing, InvoicingPayment | Model↔DDL audit-FK column mismatch: models use `tenant_invoice_id`; `Billing_DDL_v1.sql:84` declares `tenant_invoicing_id` (conflicting DDLs) → audit read/PDF 500s on the stale DDL. | `bil_InvoicingAuditLogV1/V2` (FK-column asserts) | Open — proven |
| MIG-BIL-002 | P1 | InvoicingPayment | DDL `payment_status NOT NULL VARCHAR(20)` type/qualifier mis-ordered. | `bil_InvoicingPaymentV2 test_04` | Open — proven |
| BUG-BIL-010 | P1 | InvoicingPayment | Payment-row `payment_status` written from the form invoice-status (PENDING/PARTIAL/PAID) — mismatches DDL enum {INITIATED,SUCCESS,FAILED}. | `bil_InvoicingPaymentV2` | Open — proven |
| BUG-BIL-015 | P1 | Invoicing | Invoice-number generation not concurrency-safe (count+1 race). | `bil_InvoicingV2` (retry-loop assert) | Mitigated (retry loop added) |
| DEV-BIL-INV-001 | P1 | Invoicing | Blade action buttons gate on `prime.invoicing.*` while Controller+Policy enforce `prime.billing-management.*` → visibility keyed off a different permission than the one enforced. | `bil_InvoicingV2` | Open — candidate |
| VAL-BIL-001 | P2 | InvoicingPayment, ConsolidatedPayment | No array rules for `invoice_ids[]`/`new_payment[]`/`payment_status[]`; controller reads request input directly, bypassing `validated()`; no `in:` enum on `payment_mode`. | `bil_InvoicingPaymentV2`, `bil_ConsolidatedPaymentV2` | Open — proven |
| BUG-BIL-005 | P2 | ConsolidatedPayment | Consolidated-payment print path crash (`getCollection()`/`isNotEmpty()` misuse). | `bil_ConsolidatedPaymentV2` (defensive) | Open — proven |
| BUG-BIL-013 | P2 | Invoicing | Broken `billing-management.view` route — no `view()` method. | `bil_InvoicingV2` | Open — proven |
| BUG-BIL-014 | P2 | Invoicing | Central billing route block registered 3×. | `bil_InvoicingV2` | Open — proven |
| PERF-BIL-001 | P2 | Subscription, Invoicing | Temp PDFs now `@unlink`'d, dashboard capped `limit(500)`; **synchronous ZIP still stands**. | `bil_SubscriptionV2`, `bil_InvoicingV2` | Mitigated (sync ZIP open) |
| AUTH-BIL-002 | P2 | InvoicingAuditLog | Blade action column gates on `audit.invoicing-audit-log.remakr`/`.viewAny` (wrong prefix + typo), unbacked by any Policy ability → Add-Note/Event-Info UI unreachable for `prime.*` holders. | `bil_InvoicingAuditLogV2` | Open — candidate |
| VAL-BIL-002 | P2 | InvoicingAuditLog | `auditAddNoteUpdate` has no FormRequest / no `max:500` / no sanitization on `notes` VARCHAR(500) → truncation + stored-XSS risk. | `bil_InvoicingAuditLogV2` | Open — candidate |
| DEV-BIL-SUB-001 | P2 | Subscription | Detail-panel permission namespaces split (`billing-management.view` vs `subscription.view`). | `bil_SubscriptionV2` | Open — candidate |
| DEV-EMS-001 (DATA-BIL-003) | P2 | EmailSchedule | `bil_tenant_email_schedules.invoice_id` has no FK — orphan ids insert. | `bil_EmailScheduleV2` | Open — candidate |
| DEV-EMS-002 | P2 | EmailSchedule | `sendEmail`/`scheduleEmail` have no FormRequest validation. | `bil_EmailScheduleV2` | Open — candidate |
| DEV-EMS-003 | P2 | EmailSchedule | `bil_tenant_email_schedules` table absent from `Billing_DDL_v1.sql` (schema drift). | `bil_EmailScheduleV1 test_01` (hasTable-guard) | Open — proven |
| DEV-BIL-R01 | P2 | PaymentReconciliation | `downloadSelectedPdf` authorizes `prime.invoicing-payment.view` while the reconciliation PDF button `@can('prime.payment-reconciliation.pdf')` — key mismatch. | `bil_PaymentReconciliationV2` | Open — candidate |
| INT-BIL-CP-01 | P3 | ConsolidatedPayment | List filter uses `<` (outstanding) while `downloadConsolidatedPdf` uses `!=` → overpaid invoices handled inconsistently. | `bil_ConsolidatedPaymentV2` | Open — candidate |
| DEV-EMS-004 | P3 | EmailSchedule | Requirement/audit class-name typo `BillTenatEmailSchedule` (code is correct). | `bil_EmailScheduleV1 test_01` | Open — proven (doc-only) |
| DEV-EMS-005 / DEV-EMS-006 | P3 | EmailSchedule | Minor cross-reference findings (status/labels, gate drift). | `bil_EmailScheduleV2` | Open — candidate |
| DEV-BIL-201 / 202, DEV-BIL-020, DEV-BIL-SUB-002/003/004, OBS-BIL-R02 | P3 | various | Policy model-type copy-paste (`InvoicingPayment` on `SubscriptionPolicy`), forceDelete gate-key drift, `{session}` param misnomer, double-`billing` route path, unguarded `explode(' - ')`, razorpay dep in root not module composer, DDL FKs referencing non-existent objects (`bil_tenant_invoicing`, `users`). | respective feature V2 suites | Open — candidate |

### 2.2 Remediated (Jun-2026 audit is stale — source-wins)

| ID | Audit sev | Feature | Current source state |
|----|-----------|---------|----------------------|
| SEC-BIL-001 | P0 | InvoicingPayment | REMEDIATED — `store()` wraps `beginTransaction` + try/catch + `rollBack()`. |
| SEC-BIL-002 | P0 | ConsolidatedPayment | REMEDIATED — `consolidatedStore()` try/catch + rollback; empty-selection guard moved before `beginTransaction`. |
| DATA-BIL-002 | P0 | Invoicing | REMEDIATED — no phantom `invoice_amount`, no duplicated fillable block. |
| SEC-BIL-005 | P1 | Invoicing | REMEDIATED — student count runs before the prime tx, inside try/finally. |
| SEC-BIL-010 | P1 | InvoicingAuditLog | REMEDIATED — `auditAddNoteUpdate`, `pricingDetails`, `billingDetails` now gated. |
| SEC-BIL-011 | P1 | InvoicingAuditLog | REMEDIATED — `event_info` is whitelisted, not `$request->all()`. |
| BUG-BIL-011 | P1 | Invoicing | REMEDIATED — `generateInvoiceForOrganization()` returns status arrays. |
| JOB-BIL-001 | P2 | EmailSchedule | REMEDIATED — job declares `$tries/$backoff/$timeout` + `failed()`; performer id passed to constructor. |
| DEAD-BIL-001 | P2 | (policies) | PARTLY — non-existent-model imports gone; some policies still effectively dead. |

---

## 3. BehaviouralAssessment (BA) — defect register

> Prefix note **DOC-BA-001 (P2, schema drift):** consolidated DDL names tables `bha_*` but the running app + all 16 models + tenant migrations use `ba_*`. Artifact filenames/classes keep `bha_`; every schema assertion targets the real `ba_*` tables, with a per-feature proving test `assertTrue(Schema::hasTable('ba_<t>')) + assertFalse(Schema::hasTable('bha_<t>'))`. Status: **Open — proven** (all 6 generated features).

| ID | Sev | Feature(s) (bold = generated → proven) | Description | Proving test | Status |
|----|-----|----------------------------------------|-------------|--------------|--------|
| BUG-BA-001 | P1 | Rating, ReviewQueue, **AssessmentPeriod** | Ratings editable after submit/approve/lock; period lock never freezes assessments. | `bha_AssessmentPeriodV1/V2` (lifecycle) | Open — proven (AP); pending (Rating/ReviewQueue) |
| BUG-BA-002 | P1 | **AssessmentPeriod** | Period lifecycle FSM violated; illegal transitions allowed; `open→closed` unreachable. | `bha_AssessmentPeriodV2` (SM band, 100% legal+illegal) | Open — proven |
| SEC-BA-001 / BUG-BA-003 | P1 | Incident, **Configuration** | Severe-incident parent notification (REQ-BA-015) absent; no compare to `bha_config.parent_notification_threshold`. | `bha_ConfigurationV2` (threshold config) | Open — proven (Config); pending (Incident) |
| DATA-BA-001 | P1 | **Configuration**, **RatingScale** | Active rating scale switchable mid-session after ratings exist (BR-BA-029). | `bha_ConfigurationV2`, `bha_RatingScaleV2` | Open — proven |
| VAL-BA-001 | P1 | MyAssessments, Incident, **ClassMapping** | Core write paths lack FormRequests (BaAssessment, BaIncident, BaClassCategory) — inline validation only. | `bha_ClassMappingV2` | Open — proven (CM); pending (MyAssessments/Incident) |
| SEC-BA-002 | P1 | **RatingScale, Category, Intervention, AssessmentPeriod, Configuration** | All 5 FormRequests `authorize()` return bare `true`. | each feature's V2 (auth-band) | Open — proven |
| BUG-BA-004 | P2 | **Category** | Criterion with ratings still deletable (BR-BA-006). | `bha_CategoryV2` | Open — proven |
| BUG-BA-005 | P2 | **Intervention** | Intervention linked to incidents still deletable (BR-BA-030, FK RESTRICT missing). | `bha_InterventionV2` | Open — proven |
| BUG-BA-006 | P2 | **Category** | Category soft-delete does not cascade to criteria (BR-BA-005). | `bha_CategoryV2` | Open — proven |
| BUG-BA-007 | P2 | **ClassMapping**, Rating | Class with no mapping shows empty grid (BR-BA-009 permissive default missing). | `bha_ClassMappingV2` | Open — proven (CM); pending (Rating) |
| BUG-BA-008 | P2 | Incident | Follow-up notes overwritten, not appended. | (Incident not generated) | Open — pending |
| BUG-BA-009 | P2 | **RatingScale** | Multiple rating scales can be `is_default=true` (BR-BA-028). | `bha_RatingScaleV2` | Open — proven |
| BUG-BA-012 | P2/P3 | **RatingScale/Category** | (a) Model omits `SoftDeletes` despite migration `softDeletes()` → `destroy()` is a hard delete (P2); (b) `reorder()` N+1, one UPDATE per row (P3). ID reused for two findings. | `bha_RatingScaleV2 04/22`; `bha_CategoryV2 test_17` | Open — proven |
| VAL-BA-002 | P2 | **RatingScale** (levels), Witness | Level value not range-checked (BR-BA-003); duplicate student witness 500s. | `bha_RatingScaleV2` | Open — proven (RS); pending (Witness) |
| VAL-BA-AP-01 | P2 | **AssessmentPeriod** | Chronological non-overlapping-period rule not enforced anywhere. | `bha_AssessmentPeriodV2 test_71` | Open — candidate |
| DATA-BA-003 | P2 | **RatingScale, Category, Intervention** | Soft-delete + UNIQUE without `deleted_at` → recreate-after-delete 500. | each feature's V2 | Open — proven |
| DATA-BA-004 | P2 | Incident | Incident create not wrapped in a transaction. | (Incident not generated) | Open — pending |
| BUG-BA-011 | P2 | ReportsHub, report screens | Report export is a permanent `abort(501)` stub on a live route (`reports/export`). | (ReportsHub not generated) | Open — pending |
| DEAD-BA-001 | P2 | (security/tenancy) | Empty API resource controller on live sanctum route with no tenancy middleware (`routes/api.php`). | documented (no owning feature) | Open — pending |
| AUTH-BA-RS-01 | P3 | **RatingScale** | Controller uses permission-string gates; `BaRatingScalePolicy` abilities effectively unused (works via Spatie gate). | `bha_RatingScaleV2 test_52` | Open — candidate |
| AUTH-BA-CFG-01 | P3 | **Configuration** | Same pattern — `BaConfigPolicy` effectively unused. | `bha_ConfigurationV2 test_52` | Open — candidate |
| AUTH-BA-CM-01 | P3 | **ClassMapping** | Permission-string gates, no dedicated Policy for the junction. | `bha_ClassMappingV2 test_51` | Open — candidate |

---

## 4. Program defect totals

### By severity (open + mitigated, excluding remediated)

| Severity | Billing | BehaviouralAssessment | Program |
|----------|--------:|----------------------:|--------:|
| P0 | 2 | 0 | **2** |
| P1 | 4 | 6 | **10** |
| P2 | 12 | 12 | **24** |
| P3 | ~11 | 3 | **~14** |
| **Open/Mitigated total** | **~29** | **21** | **~50** |

*(BUG-BA-012 counted once under BA-P2; DOC-BA-001 counted under BA-P2; the Billing P3 line groups ~11 minor `DEV-BIL-*/DEV-EMS-*/OBS-*` cross-reference candidates reported as "verify in source".)*

### Remediated (closed — audit stale)

| Module | Count | IDs |
|--------|------:|-----|
| Billing | 9 | SEC-BIL-001/002/005/010/011, DATA-BIL-002, BUG-BIL-011, JOB-BIL-001, DEAD-BIL-001(partly) |

### By status

| Status | Count (approx) |
|--------|----:|
| Open — proven | ~24 |
| Open — candidate ("verify in source") | ~18 |
| Open — pending (owning feature not yet generated) | 5 (BUG-BA-008, DATA-BA-004, BUG-BA-011, DEAD-BA-001, + pending halves of BUG-BA-001/007, VAL-BA-001/002, SEC-BA-001) |
| Mitigated | 2 (BUG-BIL-015, PERF-BIL-001) |
| Remediated (closed) | 9 |

### Highest-priority open items (P0/P1)

1. **MIG-BIL-001 (P0)** — Billing CRUD 500s on a schema-correct prime_db (SoftDeletes/timestamps vs DDL).
2. **DATA-BIL-001 (P0)** — Billing audit read/PDF 500s (FK column `tenant_invoice_id` vs DDL `tenant_invoicing_id`).
3. **BUG-BA-001 / BUG-BA-002 (P1)** — BA period-lock never freezes ratings; period FSM violated, `open→closed` unreachable.
4. **SEC-BA-001 / VAL-BA-001 / SEC-BA-002 (P1)** — BA severe-incident parent notification absent; core write paths lack FormRequests; all FormRequests `authorize()=true`.
5. **BUG-BIL-010 / MIG-BIL-002 / DEV-BIL-INV-001 / BUG-BIL-015 (P1)** — Billing payment-status source-of-truth, DDL type mis-order, invoice button-permission mismatch, invoice-number race (mitigated).

---

## 5. Notes & caveats

- **No suite has been executed.** All statuses reflect static analysis + design-time validation (`php -l` clean, schema-truth asserts). Runtime confirmation is blocked until the target module is enabled in `prime_testing/modules_statuses.json` (only `Syllabus` is currently `true`) — see `05_` E19.
- **Billing Jun-2026 audit is materially stale** — 9 P0/P1 items are already remediated in current source; the register above supersedes it (source-wins).
- **BehaviouralAssessment coverage is partial** — 6 of 24 screens generated. Several P1/P2 defects tied to the un-generated transactional/report screens (Incident, MyAssessments, Rating, Witness, ReviewQueue, ReportsHub) remain `Open — pending` with no proving test yet.
- **ID reuse:** `BUG-BA-012` labels two distinct findings across features; `DEV-EMS-001` is the same defect as `DATA-BIL-003`. Recorded once each above with a note.
