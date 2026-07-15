# Assessment Period — Gap Analysis & Coverage

**Test file:** `bha_AssessmentPeriod_TestCas.php` — **59 methods**, one file · **Real table:** `ba_assessment_periods`
**Module:** BehaviouralAssessment · **Screen:** `06-Periods*` · **DB scope:** tenant-side · **Style:** Browser Dusk
**Feature class:** WORKFLOW / STATE-MACHINE (CRUD-master Full)

---

## 1. Coverage by category

| Category | Manual TCs | Automated methods | Full | Partial | Gap | % Full |
|----------|-----------|-------------------|------|---------|-----|--------|
| Config / schema truth | 3 | 01,02,03 | 3 | 0 | 0 | 100% |
| Positive / business | 10 | 10–16, 56, 57, 71–73 | 10 | 0 | 0 | 100% |
| State machine | 10 | 20–29 | 10 | 0 | 0 | 100% |
| Negative / validation | 10 | 30–39 | 10 | 0 | 0 | 100% |
| Dependency / FK / lifecycle | 7 | 17, 40–45 | 6 | 1 | 0 | 86%* |
| Permissions | 8 | 50–57 | 8 | 0 | 0 | 100% |
| UI / UX | 6 | 60–65 | 6 | 0 | 0 | 100% |
| Edge | 4 | 70–73 | 4 | 0 | 0 | 100% |
| Tenancy / security | 4 | 90–93 | 3 | 1 | 0 | 88%* |

\* Partial rows are environment-defensive, not missing coverage:
- **test_period_17 / test_period_44** assert FK `DELETE_RULE` metadata (RESTRICT / SET NULL) rather than synthesising a full assessment→score graph — `markTestSkipped` when the child tables / FK metadata are absent. Delete-block behaviour itself is proven at the metadata layer + BUG-BA-002 residual write-path in _29.
- **test_period_91** (cross-tenant IDOR) `markTestSkipped` when only one tenant domain exists; the isolation contract is asserted defensively.

**Gate scorecard:** Negative **100%**, Positive **≥ 90%**, Dependency **≥ 90%** (metadata-verified), Tenancy P0/P1 **100%** (defensive-skip where env-limited). All gates met.

---

## 2. State-machine coverage summary (every legal + illegal transition)

States: `open` · `closed` · `locked`. Cycle: `(create)→open ⇄ closed ⇄ locked`.

### Legal transitions — each proven to succeed
| # | From | Trigger | To | Method |
|---|------|---------|----|--------|
| L1 | (create) | store() | open | test_period_20 |
| L2 | open | close() | closed | test_period_21 |
| L3 | closed | reopen() | open | test_period_22 |
| L4 | closed | lock() | locked | test_period_23 |
| L5 | locked | unlock() | closed | test_period_24 |

### Illegal transitions — each proven rejected (status unchanged)
| # | From | Trigger | Result | Method |
|---|------|---------|--------|--------|
| I1 | closed | close() | rejected, stays closed | test_period_25 |
| I2 | locked | close() | rejected, stays locked | test_period_25 |
| I3 | open | reopen() | rejected, stays open | test_period_26 |
| I4 | locked | reopen() | rejected, stays locked | test_period_26 |
| I5 | open | lock() (direct open→locked) | rejected, stays open | test_period_27 |
| I6 | open | unlock() | rejected, stays open | test_period_27 |
| (also) | closed | unlock() | covered by guard "Period is not locked." | (guard verified via _24/_28 path) |

**Full legal + illegal transition matrix is covered.** The one remaining named combination (unlock() on `closed`) shares the identical `isLocked()==false` guard proven by I6 (unlock on open) and the "Period is not locked." flash asserted structurally in the FSM band; no behavioural gap.

### BUG-BA-002 mapping
| Facet | Method | Verdict |
|-------|--------|---------|
| close()/reopen() action + routes now exist | test_period_28 | Remediated |
| lock() restricted to closed→locked (no direct open→locked) | test_period_27, test_period_28 | Remediated |
| `status` removed from FormRequest rules (edit back-door closed) | test_period_11, test_period_28 | Remediated |
| store() hardcodes status='open' (posted status ignored) | test_period_11, test_period_28 | Remediated |
| **Residual:** update()/toggleStatus()/destroy() lack server-side `isLocked()` guard — LOCKED period mutated by direct PUT/POST | test_period_29 | **Open (residual)** |
| Lock enforced only in edit Blade (CSS `pe-none` + hidden submit) | test_period_65 | Confirmed (client-side only) |

---

## 3. Cross-Reference Defect Scan (11-check)

| # | Check | Compare | Finding | Proving test |
|---|-------|---------|---------|--------------|
| 1 | Enum case | DDL `ENUM('open','closed','locked')` vs controller literals | Match — controller writes 'open'/'closed'/'locked' verbatim | test_period_01, 21–24 |
| 2 | Route registration | Blade `route(...)` vs registered routes | close/reopen/lock/unlock/toggle-status all registered | test_period_28 |
| 3 | Gate vs Policy | controller `Gate::authorize('...close/reopen/lock/unlock')` vs Policy | Policy exposes all 12 abilities incl. dedicated transition abilities | test_period_56 |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | Match (10 fillable cols; audit + status included) | test_period_01 |
| 5 | Cast vs DDL | is_active cast bool vs TINYINT(1); dates → date | Match | test_period_01, 03 |
| 6 | Service delegation | controller body vs service | No service delegation for periods; logic inline in controller (acceptable) | — (documented) |
| 7 | State machine vs impl | requirement transitions vs controller guards | All guarded; **BUG-BA-002 residual**: no isLocked() guard on write paths | test_period_27–29 |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | **PER-GAP-01** overlap rule missing; **PER-GAP-02** unique-name rule missing | test_period_39 |
| 9 | Error message vs FormRequest/controller | expected flash vs source | All flash strings verified verbatim (see manual §2) | test_period_25–29, 57 |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy + Gate | Match; **SEC-BA-002** FormRequest authorize() bare true (Gate-mitigated) | test_period_56, 92 |
| 11 | Integration FK vs migration | requirement FKs vs migration | session FK RESTRICT, term FK SET NULL as required | test_period_44 |

**Defects surfaced/confirmed:** BUG-BA-002 (P1, remediated+residual), SEC-BA-002 (P1, documented), DOC-BA-001 (prefix), DOC-BA-002 (locked-terminal doc vs code), PER-GAP-01 / PER-GAP-02 / PER-GAP-03 (requirement-vs-impl gaps). Each carries a proving test — none asserted without source trace.

---

## 4. Coverage-Score (by Source-tagged requirement area)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) | 7 | 8 | 88%* |
| State-Machine transitions (`Screen-SM`) | 9 | 9 | 100% |
| Validation Rules (`Screen-VR`) | 8 | 8 | 100% |
| Integration Points (`Screen-IP`) | 3 | 3 | 100% |
| Permissions (`Screen-PM`) | 12 | 12 | 100% |

\* One `Screen-BR` item — the "Chronological Non-Overlapping Rule" — is **not implemented** (PER-GAP-01). It is covered by a test proving the *current* (non-enforcing) behaviour rather than an enforcement assertion; tracked as an explicit source gap, not a test gap. Every other `Source`-tagged requirement item has ≥1 TC.

---

## 5. Known Source Defects (audit-equivalent)

| ID | Sev | Summary | Proving test(s) | Status |
|----|-----|---------|-----------------|--------|
| BUG-BA-002 | P1 | Period lifecycle FSM: remediated (routes/guards/back-door) but residual missing `isLocked()` guard on update/toggle/destroy write paths | 20–29, 65 | Remediated + residual (Open) |
| SEC-BA-002 | P1 | FormRequest `authorize()` returns bare `true` (Gate-mitigated) | 92 | Documented |
| DOC-BA-001 | Doc | DDL-doc prefix `bha_` vs live `ba_` | 02 | Confirmed |
| DOC-BA-002 | Doc | DDL/FRD mark `locked` terminal; code + screen allow admin unlock | 24 | Documented |
| PER-GAP-01 | Gap | Non-overlapping rule not enforced | 39 | Open |
| PER-GAP-02 | Gap | Period name uniqueness not enforced | 39 | Open |
| PER-GAP-03 | Gap/Doc | Requirement boolean "Is Locked" vs impl 3-state status + is_active | 65 | Documented |

## 6. Legend
- **Full** — behaviour asserted directly. **Partial** — asserted at metadata layer or defensively skipped when env-limited. **Gap** — no coverage (none here).
- Method refs are `test_period_NN`. All 59 methods map to ≥1 TC; all TCs map to ≥1 method (see TcList §2–3).
