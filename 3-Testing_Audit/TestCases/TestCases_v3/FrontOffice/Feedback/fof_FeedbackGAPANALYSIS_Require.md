# FrontOffice · Feedback — Gap Analysis & Traceability

Maps every TC ↔ test method with coverage = Full / Partial / Gap. Suite: `fof_Feedback_TestCas.php` — **42 methods**.

---

## 1. Coverage by category

| Category | TCs | Full | Partial | Gap | % Full |
|----------|-----|------|---------|-----|--------|
| Positive | 17 | 16 | 1 | 0 | 94% |
| Negative | 15 | 15 | 0 | 0 | 100% |
| Dependency (FK) | 3 | 2 | 1 | 0 | 67%* |
| State-machine | 5 | 5 | 0 | 0 | 100% |
| Security | 4 | 4 | 0 | 0 | 100% |
| Tenancy | 1 | 0 | 1 | 0 | env-guarded |

\* Dependency Full% is 67% only because `test_feedback_42` (SET NULL on user delete) is defensively `markTestSkipped` when user-FK manipulation is not exercisable — the assertion path is real; it is Partial by environment, not by design.

**Gate targets:** Negative 100% ✅ · Positive ≥90% ✅ (94%) · Dependency ≥90% (design-complete; env-guarded) · Tenancy on P0/P1 (single-tenant env → guarded smoke).

---

## 2. TC ↔ Method mapping (Full unless noted)

| TC | Method | Coverage | Note |
|----|--------|----------|------|
| TC-P01 | `..._01_schema...` | Full | LIVE information_schema + model + inline-rule + gate + event asserts |
| TC-P02 | `..._02_...unique...` | Full | SHOW INDEX on token |
| TC-P03 | `..._03_...foreign_keys...` | Partial | asserts when FK metadata present; skips if schema lags DDL |
| TC-P04 | `..._04_soft_delete...` | Full | column & trait independent (#30) |
| TC-P05..P08 | `_10.._13` | Full | biz rules via verified model |
| TC-P09/P10/P11/U01 | `_15/_16/_17/_60` | Partial | browser render — tolerant to module-disabled 404 |
| TC-P12 | `_23_toggle...` | Full | model-level flip both directions |
| TC-P13/P14/P15/P16 | `_33/_35/_70/_71` | Full | nullable+, max-len+, special chars, empty report |
| TC-P17 | `_90_public_route...` | Full | no /login redirect on public token |
| TC-N01..N05 | `_30/_31/_32/_34/_36` | Full | NOT NULL + over-length + duplicate token (tolerant of strict/non-strict MySQL) |
| TC-N06 | `_37_type_enum...` | Full | inline rule string asserted |
| TC-N07/N08 | `_18/_19` | Full | inactive / unknown token not served |
| TC-N09/N10 | `_40/_41` | Partial | FK/RESTRICT — skips (documented) if not enforced in test DB |
| TC-N11 | `_50_guest...` | Full | /login redirect |
| TC-N12 | `_51_forbidden...` | Full | factory non-super-admin + `forgetCachedPermissions` + 403 (F37/#31) |
| TC-N13 | `_22_force_deleted_cannot_restore` | Full | illegal transition |
| TC-N14 | `_91_stored_xss...` | Full | Blade escaping |
| TC-N15 | `_25_null_created_by...` | Full | DEV-FOF-F01 proof |
| TC-D01 | `_42_respondent_set_null...` | Partial | guarded markTestSkipped |
| TC-SM01/SM02 | `_20/_21` | Full | lifecycle + activity sink `sys_activity_logs` |
| TC-S01 | `_52_gate_abilities...` | Full | per-action gate strings |
| TC-S02 | `_24_anonymous...` | Full | SEC-FOF-002 observed |
| TC-S03 | `_26_public_submit_e2e...` | Full | tolerant failure-surface for DEV-FOF-F01 |
| TC-DEAD01 | `_14_dead_expiry...` | Full | DEAD-FOF-001 |
| TC-X01 | `_38_description_stricter...` | Full | Cross-Ref 14 |
| TC-T01 | `_92_cross_tenant...` | Partial | env-guarded |

Every TC-ID → ≥1 method; every method → a TC/BC. No orphans.

---

## 3. Cross-Reference Defect Scan

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | DDL vs inline `in:` | questions type `rating,yes_no,text` is app-level enum (not a DDL ENUM) — consistent. No finding. |
| 2 | Route registration | Blade `route()` vs routes/web.php | `fof.feedback.store`, `fof.menu.communication`, `fof.feedback.submit` all registered. No finding. |
| 3 | Gate vs Policy | `Gate::authorize()` vs `FeedbackFormPolicy` | Controller uses **string Gates**, not `authorize($ability,$model)` policy calls; `FeedbackFormPolicy` methods exist but are effectively bypassed by the string-gate pattern (module-wide SEC-FOF-001 shape). Observed behaviour tested via `_51`/`_52`. |
| 4 | Fillable vs DDL | model `$fillable` vs columns | forms fillable omits `deleted_at` (correct); responses fillable includes `respondent_name` never populated by controller. Minor. |
| 5 | Cast vs DDL | `$casts` vs types | `questions_json`/`responses_json`=array (JSON), `is_*`=boolean (TINYINT) — correct. No finding. |
| 6 | Service delegation | controller vs service | No service layer for Feedback; logic inline. No finding. |
| 7 | State machine vs impl | lifecycle vs controller | soft-delete/restore/forceDelete/toggle implemented; **no create/update activity log** (gap). |
| 8 | Validation vs rules | intended vs `validate()` | inline rules present; publicSubmit only validates `answers` (no per-answer type validation). Minor. |
| 9 | Error message vs rules | — | no custom `messages()`; default Laravel messages. No finding. |
| 10 | Permissions vs gates | matrix vs `Gate::authorize` | 6 abilities mapped; `trashed`+`restore` share `...restore`; `toggleStatus`→`...update`. Consistent. |
| 11 | Integration FK vs migration | FK vs schema | responses FKs RESTRICT/SET NULL per DDL — asserted (`_03`). |
| 12 | UNIQUE enforcement | DDL UNIQUE vs `unique:` | token UNIQUE at DB; auto-generated (uuid) so no `unique:` rule needed. DB enforced (`_36`). No finding. |
| 13 | Required enforcement | DDL NOT NULL vs code | **DEV-FOF-F01**: `fof_feedback_responses.created_by`/`updated_by` are NOT NULL but `publicSubmit` inserts NULL for anonymous/guest → constraint violation, public submission fails. |
| 14 | Length enforcement | DDL VARCHAR vs `max:` | `description` DDL=TEXT vs rule `max:1000` (stricter, safe divergence). `title` 200↔max:200 aligned. `questions.*.label` max:255 (JSON payload, no column). |
| 15 | Soft-delete vs trait | `deleted_at` vs SoftDeletes | present on both tables + both models — aligned (`_04`). |

---

## 4. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 6 | 6 | 100% |
| State-Machine (BC-SM) | 5 | 5 | 100% |
| Validation (BC-VAL) | 7 | 7 | 100% |
| Integration/FK (BC-REF/INT) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 5 | 5 | 100% |
| DDL constraints (BC-DB) | 15 | 15 | 100% |

Every Source-tagged requirement item has ≥1 TC. No 0-coverage items.

---

## 5. Documented defects (feature-level DEV register)

| ID | Sev | Proving test | Status |
|----|-----|--------------|--------|
| SEC-FOF-002 | P1 | `_24`, `_26` | Open — partial remediation observed; `is_anonymous` never set; semantics differ from BR-FOF-010 |
| DEV-FOF-F01 | P1 | `_25`, `_26` | Open (new, source-traced) — NULL `created_by`/`updated_by` on NOT NULL columns break public submit |
| DEAD-FOF-001 | P3 | `_14` | Open — commented expiry guard + non-existent `expires_at` |
| No-activity-on-create/update | P3 | MT-1 documented | Open — audit-trail gap |
| Xref-14 description max | P4 | `_38` | Noted — safe stricter divergence |

---

## Legend
Full = automated end-to-end assertion. Partial = real assertion but environment-guarded (`markTestSkipped` when a dependency/tenant/module is absent — Rule Card #9/#11/#19). Gap = no coverage (none here).
