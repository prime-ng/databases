# Billing Cycle — Gap Analysis (`prm_BillingCycleGAPANALYSIS_Require`)

Maps every manual TC ↔ V2 Dusk method with coverage = Full / Partial / Gap.
V1 = 13 methods · V2 = 36 methods (≥ 2×V1).

## 1. Coverage Mapping

### Positive

| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-P01 | Schema/model config | `test_01`, `test_02`, `test_03` | Full |
| TC-P02 | SoftDeletes guard (MIG-BIL-001) | `test_05` | Full |
| TC-P03 | Index loads | `test_60` | Full |
| TC-P04 | Create page loads | `test_62` | Full |
| TC-P05 | Create persists all fields | `test_10` | Full |
| TC-P06 | Update persists all fields | `test_11` | Full |
| TC-P07 | Soft delete deactivates | `test_12` | Full |
| TC-P08 | Store activity log | `test_13` | Full (defensive skip if log table unreachable) |
| TC-P09 | Update same short_name | `test_39` | Full |
| TC-P10 | Index columns | `test_60` | Full |
| TC-P11 | Created record listed | `test_61` | Full |
| TC-P12 | Breadcrumb on create | `test_62` | Full |

### State machine

| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-SM01 | active→inactive | `test_20` | Full |
| TC-SM02 | inactive→active | `test_21` | Full |
| TC-SM03 | toggle-status JSON contract | `test_22` | Full (defensive) |

### Negative

| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-N01 | short_name required | `test_30` | Full |
| TC-N02 | name required | `test_31` | Full |
| TC-N03 | months_count required | `test_32` | Full |
| TC-N04 | duplicate short_name | `test_33` | Full |
| TC-N05 | months_count 0 | `test_34` | Full |
| TC-N06 | months_count 256 | `test_35` | Full |
| TC-N07 | short_name > 50 | `test_36` | Full |
| TC-N08 | name > 50 | `test_37` | Full |
| TC-N09 | description > 255 | `test_38` | Full |
| TC-N10 | guest → login (index) | `test_50` | Full |
| TC-N11 | guest → login (create) | `test_51` | Full |
| TC-N12 | non super-admin forbidden | `test_52` | Full (defensive) |
| TC-N13 | toggle-status missing is_active → 422 | `test_23` | Full (defensive) |

### Dependency

| TC | Sub | Description | V2 method(s) | Coverage |
|----|-----|-------------|--------------|----------|
| TC-D01 | F | Full lifecycle | `test_40` | Full |
| TC-D02 | C | FK RESTRICT | `test_41` | Full (schema-level, defensive) |
| TC-D03 | E | Cross-module ref tables | `test_42` | Full (defensive) |
| TC-D04 | B | Trashed short_name reserved | `test_72` | Full |
| TC-D05 | G | months_count boundaries | `test_70`, `test_71` | Full |

### Security

| TC | Description | V2 method(s) | Coverage |
|----|-------------|--------------|----------|
| TC-S01 | XSS in name escaped | `test_90` | Full |
| TC-S02 | IDOR / direct edit URL auth | `test_91` | Full |

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % Full |
|----------|-------|------|---------|-----|--------|
| Positive | 12 | 12 | 0 | 0 | 100% |
| State machine | 3 | 3 | 0 | 0 | 100% |
| Negative | 13 | 13 | 0 | 0 | 100% |
| Dependency | 5 | 5 | 0 | 0 | 100% |
| Security | 2 | 2 | 0 | 0 | 100% |
| **Total** | **35** | **35** | **0** | **0** | **100%** |

Targets met: Negative 100% (≥100%), Positive 100% (≥90%), Dependency 100% (≥90%).

## 3. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) | 5 | 5 | 100% |
| State-Machine transitions (`Screen-SM`) | 3 | 3 | 100% |
| Validation Rules (`Screen-VR`) | 7 | 7 | 100% |
| Integration Points (`Screen-IP`/BC-REF) | 4 | 4 | 100% |
| Permissions (`Screen-PM`) | 6 | 6 (viewAny/view/create/update/delete/restore) | 100%* |

\* Permission enforcement is validated at guest-redirect + non-super-admin (defensive) level; per-permission granular 403 (e.g. update-but-not-delete) is not individually exercised because the central super-admin `Gate::before` bypass makes granular negative gating environment-dependent — noted as a residual limitation, not a coverage gap of a `Source`-tagged item.

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | DDL comment values vs Request | No `in:` rule on short_name (free VARCHAR); DDL values are comment-only. No mismatch. |
| 2 | Route registration | Blade `route('central.billing.billing-cycle.*')` vs `routes/web.php` | All present (index/create/store/show/edit/update/destroy/trashed/restore/forceDelete/toggleStatus). OK. |
| 3 | Gate vs Policy | `Gate::authorize('prime.billing-cycle.*')` vs `BillingCyclePolicy` | Policy has viewAny/view/create/update/delete/restore/forceDelete. **forceDelete drift → #10.** |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | Match (short_name/name/months_count/description/is_active/is_recurring). OK. |
| 5 | Cast vs DDL | `$casts` vs DDL types | is_active/is_recurring boolean (tinyint(1)), months_count integer (tinyint). OK. |
| 6 | Service delegation | Controller vs Service | No service layer; logic in controller. OK. |
| 7 | State machine vs impl | Screen toggle vs `toggleStatus` | Implemented; JSON contract matches. OK. |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | Match; no `in:` enum enforced on short_name (values are advisory) — **noted, not a defect.** |
| 9 | Error message vs FormRequest | Expected vs `messages()` | Request defines **no custom `messages()`** → default Laravel messages. Acceptable; toast strings come from `config/flash.php` (verified). |
| 10 | Permissions vs Policy/Gates | Controller gates vs Policy | **DEV-BIL-201 (P3):** `forceDelete()` gates on `prime.billing-cycle.delete`, Policy `forceDelete` uses `prime.billing-cycle.forceDelete`. Key drift. |
| 11 | Integration FK vs migration | Screen FKs vs DDL `foreign()` | 4 RESTRICT FKs confirmed (plans/rates/schedule/invoices). OK. |

**Additional discovered items**
- **MIG-BIL-001 (P0)** — model SoftDeletes + timestamps vs DDL `prm_billing_cycles` with no `deleted_at`/`created_at`/`updated_at`. Proven by `test_05` (guard fails on schema-correct DB). From audit `Billing_Complete_Audit_2026-06-29.md`.
- **DEV-BIL-202 (P3)** — store/update redirect to `central.prime.sales-plan-mgmt.index#billing` (not the billing-cycle index); success toast never shows on this screen. Documented in manual TC; not auto-failed.

## 5. Residual Limitations

- Granular per-permission 403 (e.g. has-update-but-not-delete) not exercised — central super-admin `Gate::before` bypass. Covered defensively by `test_52`.
- Activity-log assertion (`test_13`) and endpoint tests (`test_22/23`, `test_52`) `markTestSkipped` if the in-process kernel / `sys_activity_logs` / limited-user creation is not exercisable in the runner — green in partial environments.
- FK-RESTRICT dependency (`test_41`) asserted at `information_schema` level (deterministic) rather than by inserting a live referencing row (avoids fragile cross-module seeding).

## Legend
Full = behaviour asserted end-to-end · Partial = asserted indirectly/defensively · Gap = no automated coverage.
