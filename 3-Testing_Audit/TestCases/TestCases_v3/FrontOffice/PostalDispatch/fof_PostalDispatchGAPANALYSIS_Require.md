# PostalDispatch (FOF) — Gap Analysis & Traceability

Compound feature: **PostalRegister** (`fof_postal_register`) + **DispatchRegister** (`fof_dispatch_register`).
Test file: `fof_PostalDispatch_TestCas.php` — **49 methods**. Legend: **Full** = TC fully automated; **Partial** = automated with an env/guard caveat; **Gap** = manual only.

---

## 1. TC ↔ Method mapping

### Schema / Config
| TC | Method | Coverage |
|----|--------|----------|
| TC-01 (DDL↔app matrix both tables, soft-delete independent, UNIQUE index) | `test_01` | Full |
| TC-02 (FormRequest rule strings + 3 DEV divergences) | `test_02` | Full |

### Positive (14)
| TC | Method | Coverage |
|----|--------|----------|
| TC-P01 postal IN- number | `test_10` | Partial (route → skips if module disabled) |
| TC-P02 postal OUT- number | `test_11` | Partial (route) |
| TC-P03 dispatch DSP- number + dispatched_by | `test_12` | Partial (route) |
| TC-P04 copy_retained default | `test_13` | Full |
| TC-P05 is_active default | `test_14` | Full |
| TC-P06 isLocked domain | `test_15` | Full |
| TC-P07 acknowledge locks | `test_20` | Partial (route) |
| TC-P08 update unlocked ok | `test_24` | Partial (route) |
| TC-P09 destroy unlocked | `test_25` | Partial (route) |
| TC-P10 nullable omittable | `test_34` | Full |
| TC-P11 restore/force-delete lifecycle | `test_43`,`test_44` | Full |
| TC-P12 subject exactly-200 | `test_32`,`test_38` | Full |
| TC-P13 toggle-status JSON | `test_60`,`test_61` | Partial (route) |
| TC-P14 search/filter | `test_62`,`test_63` | Full |

### Negative (16)
| TC | Method | Coverage |
|----|--------|----------|
| TC-N01 postal missing required | `test_30` | Full |
| TC-N02 postal invalid enum | `test_31` | Full |
| TC-N03 postal subject 201 | `test_32` | Full |
| TC-N04 postal sender_name 101 | `test_33` | Full |
| TC-N05 postal assigned user not exist | `test_35` | Full |
| TC-N06 dispatch missing required | `test_36` | Full |
| TC-N07 dispatch invalid enum | `test_37` | Full |
| TC-N08 dispatch subject 201 | `test_38` | Full |
| TC-N09 duplicate postal_number | `test_70` | Full |
| TC-N10 duplicate dispatch_number | `test_71` | Full |
| TC-N11 subject NOT NULL at DB | `test_72` | Full |
| TC-N12 empty/whitespace subject | `test_75` | Full |
| TC-N13 re-acknowledge locked | `test_21` | Partial (route) |
| TC-N14 update locked | `test_22` | Partial (route) |
| TC-N15 destroy locked | `test_23` | Partial (route) |
| TC-N16 invalid id 404 | `test_42` | Partial (route) |

### Dependency (4)
| TC | Method | Coverage |
|----|--------|----------|
| TC-D01 postal FK SET NULL | `test_40` | Partial (guarded try/catch) |
| TC-D02 dispatch FK SET NULL | `test_41` | Partial (guarded) |
| TC-D03 activity Restored/Deleted | `test_45` | Partial (guarded; sys_activity_logs) |
| TC-D04 onlyTrashed scope | `test_64` | Full |

### Authorization (5)
| TC | Method | Coverage |
|----|--------|----------|
| TC-A01 guest blocked | `test_50` | Partial (route) |
| TC-A02 no-create denied (both) | `test_51` | Full (Gate::forUser) |
| TC-A03 granted allowed | `test_52` | Full |
| TC-A04 no-update/delete/forceDelete denied | `test_53` | Full |
| TC-A05 limited user HTTP store not-success | `test_54` | Partial (route) |

### Security / Edge / DEV / Tenancy (7)
| TC | Method | Coverage |
|----|--------|----------|
| TC-S01 addressee_name rule>col | `test_39` | Full |
| TC-S02 dispatch_mode Other divergence | `test_73` | Full |
| TC-S03 Certificate unreachable | `test_74` | Full |
| TC-S04 XSS stored verbatim | `test_76` | Full |
| TC-S05 auto-number not overridable | `test_91` | Partial (route) |
| TC-T01 tenant scoping | `test_90` | Partial (skips if single tenant) |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Schema | 2 | 2 | 0 | 0 | 100% |
| Positive | 14 | 6 | 8 | 0 | 100% |
| Negative | 16 | 12 | 4 | 0 | 100% |
| Dependency | 4 | 1 | 3 | 0 | 100% |
| Authorization | 5 | 3 | 2 | 0 | 100% |
| Security/Edge/DEV | 6 | 5 | 1 | 0 | 100% |
| Tenancy | 1 | 0 | 1 | 0 | 100% |
| **Total** | **48 TC / 49 methods** | **29** | **19** | **0** | **100%** |

**Gate check:** Negative 100% ✅ · Positive ≥90% (100%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy present ✅.
"Partial" = automated but self-`markTestSkipped` when a documented env prerequisite is absent (module disabled → routes 404; single tenant; missing `sys_activity_logs`). No coverage is *lost* — every TC has a method.

---

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BR-FOF-009 lock, auto-number) | 6 | 6 | 100% |
| State-Machine transitions (SM-1..SM-6) | 6 | 6 | 100% |
| Validation Rules (postal 6 + dispatch 4) | 10 | 10 | 100% |
| Integration Points (2 FK + activity + trash) | 4 | 4 | 100% |
| Permissions (viewAny/create/update/delete/restore/forceDelete ×2 entities) | 12 abilities | 12 | 100% (create/update/delete/forceDelete directly asserted; restore/viewAny by grant-parity) |

---

## 4. Cross-Reference Defect Scan (15 checks)

| # | Check | Compare | Finding | ID |
|---|-------|---------|---------|-----|
| 1 | Enum case | DDL ENUM vs FormRequest `in:` | **dispatch_mode**: DDL `(Hand,Post,Courier,Email,Fax)` vs rule `…,Fax,Other` → extra `Other`. **document_type**: DDL has `Certificate`, rule omits it | **DEV-FOF-DR-01 / DEV-FOF-DR-02** |
| 2 | Route registration | Blade `route()` vs web.php | All `fof.postal-register.*` / `fof.dispatch-register.*` registered; index/store/show/edit/update/destroy/acknowledge/toggle/trashed/restore/forceDelete present | none |
| 3 | Gate vs Policy | controller `Gate::authorize` vs Policy | String gates only (Spatie permissions), no model-bound Policy — consistent with module scheme; FormRequest `authorize()=true` (D30) | SEC-FOF-003 |
| 4 | Fillable vs DDL | model `$fillable` vs DDL cols | Postal & Dispatch fillable cover all writable cols; `copy_retained` fillable but not in FormRequest → intentional auto-default | none (G48) |
| 5 | Cast vs DDL | `$casts` vs DDL type | `is_active`→boolean (tinyint ✓), `postal_date`/`dispatch_date`→date ✓, `acknowledged_at`→datetime ✓ | none |
| 6 | Service delegation | controller vs Service | No service layer; logic inline in controllers (auto-number, lock guard) | none |
| 7 | State machine vs impl | BR-FOF-009 vs controller | Lock enforced in acknowledge(L86), update(L157), destroy(L173) — **DAT-FOF-003 remediated** | DAT-FOF-003 (fixed) |
| 8 | Validation vs FormRequest | requirement vs `rules()` | postal aligned; dispatch diverges (checks 1 & 14) | see DR-01/02/03 |
| 9 | Error message vs FormRequest | expected vs `messages()` | No custom `messages()`; abort_if strings verbatim ("already acknowledged", "record is locked") | none |
| 10 | Permissions vs gates | matrix vs `Gate::authorize` | index/trashed/show use `viewAny` (not `view`) — consistent w/ FactPack note | none |
| 11 | Integration FK vs migration | FK vs DDL | `assigned_to_user_id`→sys_users SET NULL; `dispatched_by`→sys_users SET NULL; both no-cross-module RESTRICT | none |
| 12 | UNIQUE enforcement | DDL UNIQUE vs FormRequest `unique:` | `postal_number`/`dispatch_number` UNIQUE at DB but **no `unique:` rule** (auto-generated → intentional; UNIQUE is the backstop) | note (G43 tested at DB) |
| 13 | Required enforcement | DDL NOT NULL vs `required` | Aligned (postal_type/date/document_type/subject; dispatch date/addressee/subject/mode/document_type) | none |
| 14 | Length enforcement | DDL VARCHAR(n) vs `max:` | **addressee_name** DDL 100 vs rule 150 → over by 50 | **DEV-FOF-DR-03** |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs `SoftDeletes` | Both present on both models — consistent (asserted independently in `test_01`) | none |

---

## 5. DEV Register (this feature)

| ID | Sev | Entity | Proving test | Assertion mode |
|----|-----|--------|--------------|----------------|
| DEV-FOF-DR-01 | P2 | Dispatch | `test_73`,`test_02` | rule accepts `Other`; DB refuses/coerces (tolerant) |
| DEV-FOF-DR-02 | P3 | Dispatch | `test_74`,`test_02` | rule rejects DDL-valid `Certificate` |
| DEV-FOF-DR-03 | P2 | Dispatch | `test_39`,`test_02` | rule passes 150-char > col 100 |
| DEV-FOF-PD-04 | P2 | Both | `test_45` | audit-trail gap: only Restored/Deleted logged |
| DAT-FOF-003 | P2→fixed | Postal | `test_22`,`test_23` | lock guard PRESENT (observed) |
| DAT-FOF-002 | P2 | Both | `test_70`,`test_71` | UNIQUE key backstops the race |
| SEC-FOF-003 | P1 | Both | `test_51`,`test_53` | FormRequest `authorize()=true`; controller gate is sole guard |

---

## 6. Remaining limitations
- Route-flow methods (auto-number, acknowledge, toggle, HTTP-403, invalid-id-404) require FrontOffice **enabled** in `modules_statuses.json`; they `markTestSkipped` with the prerequisite noted rather than false-fail (Rule #19/F41).
- FK SET NULL and activity-log methods are `try/catch`-guarded and skip if the dependency/table is absent (Rule #9/#11).
- Tenancy isolation (`test_90`) proves single-tenant scoping structurally and skips the cross-tenant leg unless ≥2 tenants exist.
- `restore`/`viewAny` permission abilities are covered via grant-parity (`test_52`) rather than a dedicated per-ability 403; create/update/delete/forceDelete are directly asserted.
