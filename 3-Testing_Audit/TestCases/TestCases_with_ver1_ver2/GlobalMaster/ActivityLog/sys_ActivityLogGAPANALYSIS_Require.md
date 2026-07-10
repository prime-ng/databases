# Activity Log (Central Audit Viewer) — Gap Analysis & Coverage

**Feature:** GlobalMaster / ActivityLog (read-only audit viewer, central)
**Primary table:** `sys_activity_logs` · **Prefix:** `sys_`
**V1:** 16 methods · **V2:** 48 methods · **Ratio:** 3.0× (≥ 2× gate met)

Legend: **Full** = behaviour directly asserted · **Partial** = asserted indirectly / env-gated · **Gap** = not covered.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-P01 schema/columns/no-softdelete | 01 | 01,02,03 | Full |
| TC-P02 relationships | 02 | 04,05 | Full |
| TC-P03 user_id + indexes | 03 | 06,08 | Full |
| TC-P04 route/method registration | 04 | 09 | Full |
| TC-P05 properties json/text | — | 07 | Full |
| TC-P06 properties cast round-trip | 06 | 11 | Full |
| TC-P07 latest ordering | 07 | 13 | Full |
| TC-P08 pagination 10/20 | 08 | 14,15 | Full |
| TC-P09 morphTo subject | 09 | 16,17 | Full |
| TC-P10 helper writes issued_by | 10 | 18 | Full |
| TC-P11 helper null → null | — | 19 | Full |
| TC-P12 index render/empty state | 12,16 | 60,63 | Partial (env-gated browser) |
| TC-P13 search controls | 16 | 61,66 | Full (blade source) |
| TC-P14 filter options | — | 62 | Full |
| TC-P15 total badge/pagination | 16 | 64,65 | Full |

### Negative / Security
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-N01 guest redirect | 11 | 50,94 | Partial (browser env-gated; HTTP probe backup) |
| TC-N02 index gated viewAny | 14 | 51 | Full |
| TC-N03 GM gate only commented | — | 52 | Full |
| TC-S01 search unguarded (SEC) | 15 | 53 | Full |
| TC-S02 card view/viewAny mismatch | 16 | 55 | Full |
| TC-S03 output escaped | — | 91 | Full |
| TC-S04 XSS stored verbatim | — | 92 | Partial (env-gated seed) |
| TC-S05 super-admin Gate::before | — | 56 | Full |
| TC-S06 policy abilities | — | 54 | Full |
| TC-S07 search HTTP status set | — | 93 | Partial (env-gated) |
| TC-N04 index HTTP status set | — | 94 | Partial (env-gated) |

### Dependency / Edge
| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-D01 FK cascade | 03 | 40 | Full |
| TC-D02 arbitrary subject class | — | 41 | Partial (env-gated seed) |
| TC-D03 distinct sinks | 05 | 42 | Full |
| TC-D04 helper tenancy routing | — | 43 | Full |
| TC-D05 not dead activity_logs table | — | 44 | Full |
| TC-D06 tenancy-aware user() | 02 | 05,90 | Full |
| TC-EDG-01 null props/ip/ua | — | 12,70 | Partial (env-gated seed) |
| TC-EDG-02 unknown event default | — | 71 | Full |
| TC-EDG-03 null subject `—` | — | 72 | Full |
| TC-EDG-04 missing user `System` | — | 73 | Full |
| TC-EDG-05 long user_agent ≤255 | — | 74 | Partial (env-gated seed) |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 15 | 13 | 2 | 0 | 100% |
| Negative/Security | 11 | 7 | 4 | 0 | 100% |
| Dependency | 6 | 4 | 2 | 0 | 100% |
| Edge | 5 | 3 | 2 | 0 | 100% |
| **Overall** | **37** | **27** | **10** | **0** | **100%** |

Targets: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%). Tenancy isolation N/A (central feature) — the model's tenancy-aware `user()` switch is covered instead (TC-D06).

**Partial-coverage limitations:** all "Partial" items are browser-render or DB-seed tests that self-skip when the module is disabled (`modules_statuses.json`) or when no central `sys_users` row exists for the `user_id` FK. Their intent is additionally covered by blade/source-content and Schema assertions that run without a browser, so no requirement area is left unverified.

---

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 9 | 9 | 100% |
| Schema/DDL (BC-DB) | 9 | 9 | 100% |
| Permissions (BC-AUTH) | 6 | 6 | 100% |
| Integration/Ref (BC-INT/REF) | 3 | 3 | 100% |
| Edge (BC-EDG) | 6 | 6 | 100% |
| Security (BC-SEC) | 2 | 2 | 100% |
| State-Machine (BC-SM) | — | 0 | N/A (no lifecycle — read-only) |

Every `Source`-tagged BC has ≥1 TC. No zero-coverage requirement items.

---

## 4. Cross-Reference Findings (defect scan)

| # | Check | Compared | Finding | ID / Action |
|---|-------|----------|---------|-------------|
| 1 | Enum case | — | No enums on this table | N/A |
| 2 | Route registration | Blade `route('central.global-master.activity-log.index')` vs routes/web.php | Registered; **search route also live** (not dead) → BUG-GLB-005 NOT reproduced for central Prime ctrl | Documented (test_09) |
| 3 | Gate vs Policy | ctrl `Gate::authorize` vs `PrimeActivityLogPolicy` | index gate ↔ policy OK; **`search()` has NO gate** | **BUG-GLB-ALOG-01 (SEC, High)** — test_53 |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | Match (7 fillable = non-id/timestamp columns) | OK |
| 5 | Cast vs DDL | `properties`→array vs JSON column | Correct | OK |
| 6 | Service delegation | ctrl vs Service | No service; logic in helper | OK |
| 7 | State machine | — | No FSM (read-only) | N/A |
| 8 | Validation vs FormRequest | — | No FormRequest (read-only) | OK |
| 9 | Error message | — | No user-facing validation messages | N/A |
| 10 | Permissions vs Policy/Gates | index viewAny vs card `@can('...view')` | **viewAny/view mismatch** → viewAny-only user sees empty page; also GlobalMaster screen guarded by `prime.*` permission (namespace coupling) | **BUG-GLB-ALOG-02 (Medium)** — test_55 |
| 11 | Integration FK vs migration | DDL FK vs model | `user_id`→`sys_users` CASCADE present | OK (test_40) |
| 12 | Table of record | central route model vs designated table | Central viewer reads `sys_central_activity_logs`; `sys_activity_logs` is the tenant sink | **BUG-GLB-ALOG-03 / RISK-GLB-008 (Medium ARCH)** — test_42,43 |
| 13 | Migration hygiene | dead `activity_logs` vs real `sys_activity_logs` | Stray migration; model points to real table | **MIG-GLB-001 (P2)** — test_44 |

### Premise corrections vs task brief (source wins per HARD RULE 13)
- **"Index is ungated (SEC)"** → **incorrect**: only the GlobalMaster-specific gate line is commented; a live `Gate::any(['prime.activity-log.viewAny'])`/`Gate::authorize(...)` still guards the index. Proven by test_51/test_52. The genuine SEC hole is the unguarded **`search()`**, encoded instead.
- **"`activity-log.search` dead route → 500 (BUG-GLB-005)"** → **not reproduced** for the wired central Prime controller (its `search()` returns JSON). NOTE: the GlobalMaster *module* controller has no `search()` and its `routes/web.php` registers no search route, so `route('global-master.activity-log.search')` (non-central) would fail — a real but different gap; documented, not a central-viewer 500.
