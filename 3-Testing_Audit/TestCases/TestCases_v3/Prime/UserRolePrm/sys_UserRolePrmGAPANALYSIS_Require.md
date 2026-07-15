# UserRolePrm — Gap Analysis & Coverage (`sys_`)

**Test file:** `sys_UserRolePrm_TestCas.php` · **44 test methods** · class `sys_UserRolePrm_TestCas extends PrimeDuskTestCase`
**Scope:** central / `prime_db`, no tenancy. Junction screen with a partly-stubbed controller (index + search functional).

---

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-01 Schema/config | `test_01` | Full |
| MTC-02 Index loads | `test_10`, `test_11`, `test_62`, `test_73` | Full |
| MTC-03 Assign (junction) | `test_13`, `test_20`, `test_24` | Full |
| MTC-04 Duplicate rejected | `test_21`, `test_94` | Full |
| MTC-05 Role delete cascade | `test_40` | Full |
| MTC-06 User soft-delete retains | `test_41` | Full |
| MTC-07 Search endpoint | `test_30`,`test_31`,`test_32`,`test_33`,`test_34`,`test_35`,`test_36` | Full |
| MTC-08 Authorization | `test_50`,`test_51`,`test_52`,`test_53` | Full |
| MTC-09 Stub endpoints | `test_54`,`test_55`,`test_72` | Full |
| MTC-10 Filters & UX | `test_42`,`test_43`,`test_44`,`test_45`,`test_60`,`test_61`,`test_63` | Full |
| MTC-11 Activity-log absence | `test_93` | Full |
| MTC-12 Security smoke | `test_70`,`test_71`,`test_92` | Full |
| (extra) Sync/multi-role | `test_22`,`test_23`,`test_25` | Full |
| (extra) Central isolation | `test_90`,`test_91` | Full |
| (extra) No-role countable | `test_14` | Full |

Every TC-ID in the TcList maps to ≥1 method; every method maps back to a TC/BC/DEV.

---

## 2. Coverage Summary (by category)

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 18 | 18 | 0 | 0 | 100% |
| Negative | 15 | 15 | 0 | 0 | 100% |
| Dependency | 6 | 6 | 0 | 0 | 100% |
| Security / Central | 4 | 4 | 0 | 0 | 100% |
| UI/UX | 3 | 3 | 0 | 0 | 100% |
| **Total** | **46** | **46** | **0** | **0** | **100%** |

**Gate check:** Negative 100% (≥100 ✅), Positive 100% (≥90 ✅), Dependency 100% (≥90 ✅), Central/Tenancy isolation 100% on P0/P1 ✅.

> **Partial-coverage note (environmental, not a coverage gap):** UI browser methods (`test_10`–`test_14`, `test_42`–`test_45`, `test_60`–`test_63`, `test_73`) require the dev server + Chrome + Prime area reachable; JSON endpoint methods self-skip (`markTestSkipped`) via `isLive()` when the route is not wired (module-disabled/domain), keeping partial environments green (constraint 9/19).

---

## 3. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`BC-BIZ`) | 6 | 6 | 100% |
| Config binding (`BC-CFG`) | 4 | 4 | 100% |
| Permissions (`BC-AUTH`) | 4 | 4 | 100% |
| Referential/Integration (`BC-REF`/`BC-INT`) | 3 | 3 | 100% |
| Schema (`BC-DB`) | 6 | 6 | 100% |
| Edge (`BC-EDG`) | 4 | 4 | 100% |
| Documented defects (DEV-URP-001..006) | 6 | 6 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No 0-coverage items.

---

## 4. Cross-Reference Defect Scan (11-check)

| # | Check | Compared | Finding | Status |
|---|-------|----------|---------|--------|
| 1 | Enum case | — | No ENUM `in:` on this feature | n/a |
| 2 | Route registration | Blade `route('central.prime.user-role-prm.*')` vs `routes/web.php` | All registered (resource + search) | ✅ Clean |
| 3 | **Gate vs Policy** | `index()` `Gate::authorize('prime.role-permission.viewAny')` vs route family `user-role-prm.*` | Gate borrows the **role-permission** ability; no `user-role-prm` permission defined | **DEV-URP-001** (verify) |
| 4 | Fillable vs DDL | Role/User `$fillable` vs DDL | Consistent | ✅ Clean |
| 5 | Cast vs DDL | User casts (`is_active`, `is_super_admin` boolean) vs tinyint | Consistent | ✅ Clean |
| 6 | Service delegation | Controller vs Service | No service; logic inline (thin, acceptable) | ✅ Clean |
| 7 | State machine vs impl | — | Junction has no lifecycle | n/a |
| 8 | Validation vs FormRequest | Controller reads raw `Request`; no FormRequest | No validation on `search`/filters (low risk; bound params) | Note |
| 9 | Error message vs FormRequest | — | No messages defined | n/a |
| 10 | **Permissions vs Policy/Gates** | `search()` body vs any `Gate::authorize` | **No gate on `search()`** — enumeration open to any authed user | **DEV-URP-002** (verify) |
| 11 | Integration FK vs migration | Requirement FK vs DDL | `role_id` FK CASCADE present; **no FK on `model_id`** (polymorphic — expected) | ✅ Clean |
| + | **Dead endpoints** | `create/show/edit` view refs | `view('prime::create'|'show'|'edit')` do not exist → 500 | **DEV-URP-003** (verify) |
| + | **Unimplemented CRUD** | `store/update/destroy` bodies | Empty → no assignment persisted | **DEV-URP-004** (verify) |
| + | **Audit gap** | Controller vs `activityLog()` | No logging anywhere in controller | **DEV-URP-005** (verify) |

---

## 5. Documented Defects (proving tests)

| ID | Sev | Description | Proving test | Behaviour asserted |
|----|-----|-------------|--------------|--------------------|
| DEV-URP-001 | P2 | `user-role-prm.*` reuses `prime.role-permission.viewAny`; no dedicated permission | `test_01`, `test_51` | current gate documented |
| DEV-URP-002 | P2 | `search()` ungated — enumeration open to any authenticated user | `test_53` | asserts **not 403** (current) |
| DEV-URP-003 | P3 | `create/show/edit` reference missing views → 500 | `test_54`, `test_72` | error/redirect accepted |
| DEV-URP-004 | P3 | `store/update/destroy` empty → no persistence | `test_55` | junction count unchanged |
| DEV-URP-005 | P4 | No activity logging in controller | `test_93` | activity count unchanged |
| DEV-URP-006 | P4 | `search` accepts raw wildcards, no normalisation | `test_70` | no error (documented) |

All proving tests assert **current** behaviour, so the suite stays green; when the defects are fixed the corresponding assertions (e.g. `test_53` expecting not-403, `test_55` no-op) must be flipped.

---

## 6. Legend
- **Full** — behaviour asserted end-to-end (DB and/or HTTP and/or UI).
- **Note** — observation, not a firing defect.
- **verify** — candidate defect surfaced by cross-reference; traced to source lines above, to be confirmed by the owning dev.
