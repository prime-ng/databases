# Incident (Incident Log) — Gap Analysis & Coverage

**Test file:** `bha_Incident_TestCas.php` — **49 methods**, one file · **Real table:** `ba_incidents`
**Module:** BehaviouralAssessment · **Screen:** `12-Incident-Log*` · **DB scope:** tenant-side · **Style:** Browser Dusk
**Feature class:** CRUD-transactional Full + record lifecycle + post-create core-field lock (BR-BA-008)

---

## 1. Coverage by category

| Category | Manual TCs | Automated methods | Full | Partial | Gap | % Full |
|----------|-----------|-------------------|------|---------|-----|--------|
| Config / schema truth | 3 | 01, 02, 03 | 3 | 0 | 0 | 100% |
| Positive / business | 10 | 10–19 | 9 | 1 | 0 | 90%* |
| Record lifecycle / lock | 5 | 20–24 | 5 | 0 | 0 | 100% |
| Negative / validation | 10 | 30–39 | 10 | 0 | 0 | 100% |
| Permissions | 6 | 50–55 | 6 | 0 | 0 | 100% |
| UI / UX | 4 | 60–63 | 4 | 0 | 0 | 100% |
| Edge / requirement gaps | 6 | 70–75 | 6 | 0 | 0 | 100% |
| Tenancy / security | 5 | 90–94 | 4 | 1 | 0 | 80%* |

\* Partial rows are environment-defensive, not missing coverage:
- **test_incident_13** (intervention attach) `markTestSkipped` when no `ba_interventions` row exists; the attach path itself is asserted when a row is present. Witness attach (_14) uses the always-present staff dependency.
- **test_incident_93** (SEC-BA-001 source scan) `markTestSkipped` when the `prime_ai` module source is not co-located with the runner; the behavioural half of the same defect is proven unconditionally in **test_incident_92** (`is_notified` stays 0 for `critical`).

**Gate scorecard:** Negative **100%**, Positive **≥ 90%**, Dependency/lifecycle **100%**, Tenancy P0/P1 **100%** (defensive-skip where env-limited). All gates met.

---

## 2. Record-lifecycle & core-field-lock coverage summary

States: `Active` · `Trashed` · `Purged`. Cycle: `(create)→Active ⇄ Trashed → Purged`. Core fields lock immediately after create (BR-BA-008).

### Legal transitions — each proven
| # | From | Trigger | To | Method |
|---|------|---------|----|--------|
| L1 | (create) | store() | Active (is_notified=0) | test_incident_10 |
| L2 | Active | destroy() | Trashed | test_incident_20 |
| L3 | Trashed | restore() | Active | test_incident_21 |
| L4 | Trashed | forceDelete() | Purged (+ witness cascade) | test_incident_22 |
| L5 | (all stages) | full lifecycle | Purged | test_incident_23 |

### Guard / lock — proven rejected
| # | Condition | Result | Method |
|---|-----------|--------|--------|
| G1 | update() changes core field `description` | unchanged (BR-BA-008) | test_incident_16 |
| G2 | update() changes core field `student_id` | unchanged (BR-BA-008) | test_incident_24 |
| G3 | restore() a force-deleted id | not recoverable → 404 | test_incident_23 (final stage) |

**Full legal lifecycle + core-field lock matrix is covered.**

---

## 3. Cross-Reference Defect Scan (11-check)

| # | Check | Compare | Finding | Proving test |
|---|-------|---------|---------|--------------|
| 1 | Enum case | DDL `ENUM(...)` vs FormRequest `in:` | Match — `positive_reinforcement,negative_incident` and `minor,moderate,major,critical` verbatim; **INC-GAP-04** screen labels (Info/Low/Medium/High) diverge from enum | test_incident_01, 34, 74, 75 |
| 2 | Route registration | Blade `route(...)` vs registered routes | incidents / incidents-page / create / store / follow-up / restore / force-delete all reachable | test_incident_17, 19, 20–22, 60–63 |
| 3 | Gate vs Policy | controller `Gate::authorize('...incidents.*')` vs Policy | Policy exposes viewAny/view/create/update/delete/restore/forceDelete strings | test_incident_54 |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | Match (student_id, reported_by, category_id, incident_date, incident_type, severity, description, location, is_notified, is_active) | test_incident_01 |
| 5 | Cast vs DDL | `is_notified`/`is_active` bool vs TINYINT(1); `attachments_json` array | Match | test_incident_01 |
| 6 | Service delegation | controller body vs service | store() logic (audit rows, witness/intervention attach, severity-null) inline in controller (acceptable); **SEC-BA-001** notification logic absent from every layer | test_incident_12–14, 92, 93 |
| 7 | State machine vs impl | requirement lifecycle vs controller | soft-delete / restore / force-delete + BR-BA-008 core-field lock all enforced | test_incident_20–24 |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | **INC-GAP-01** 7-day rule missing; **INC-GAP-02** description min missing; **INC-GAP-03** category not required | test_incident_71, 72, 73 |
| 9 | Error message vs FormRequest | expected 422 field keys vs source | required/enum/format/range keys all fire as expected | test_incident_30–39 |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy + Gate | Match; **SEC-BA-002** FormRequest `authorize()` bare true (Gate-mitigated) | test_incident_54, 55 |
| 11 | Integration FK vs migration | requirement FKs vs migration | student_id→std_students, reported_by→sch_employees, witness junction incident_id CASCADE (proven via force-delete cascade) | test_incident_01, 22 |

**Defects surfaced/confirmed:** SEC-BA-001 (P1 safeguarding, Open), SEC-BA-002 (P1, documented), DOC-BA-001 (prefix), INC-GAP-01/02/03 (unenforced screen rules, Open), INC-GAP-04/05 (label/value divergence, documented). Each carries a proving test — none asserted without source trace.

### SEC-BA-001 mapping (P1 safeguarding — the module's headline defect)
| Facet | Method | Verdict |
|-------|--------|---------|
| `is_notified` stays 0 even for a `critical` negative incident | test_incident_92 | **Open (behaviour proven)** |
| No notify/dispatch/Mail/event() call site anywhere in the module | test_incident_93 | **Open (source proven; skips if source not co-located)** |
| `ba_config.parent_notification_threshold` never read on the store path | (source scan of same _93) | **Open (documented)** |

---

## 4. Coverage-Score (by Source-tagged requirement area)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) | 5 | 6 | 83%* |
| State-Machine / lifecycle transitions (`Screen-SM`) | 6 | 6 | 100% |
| Validation Rules (`Screen-VR`) | 7 | 9 | 78%** |
| Integration Points (`Screen-IP`) | 4 | 4 | 100% |
| Permissions (`Screen-PM`) | 7 | 7 | 100% |

\* One `Screen-BR` item — the "severe-incident parent notification" (BR-BA-013) — is **not implemented** (SEC-BA-001). It is covered by tests proving the *current* (non-notifying) behaviour rather than an enforcement assertion; tracked as an explicit source defect, not a test gap.
\** Two `Screen-VR` items — the 7-day logging window (INC-GAP-01) and description Min 20 (INC-GAP-02) — are **not enforced** in code; both are covered by gap-proof tests (_71, _72) asserting the current permissive behaviour, plus the category-mandatory gap (INC-GAP-03, _73). Every other `Source`-tagged requirement item has ≥1 TC.

---

## 5. Known Source Defects (audit-equivalent)

| ID | Sev | Summary | Proving test(s) | Status |
|----|-----|---------|-----------------|--------|
| SEC-BA-001 | P1 (safeguarding) | Severe-incident parent/staff notification (REQ-BA-015 / BR-BA-013) entirely absent; `is_notified` never set; no notify/dispatch call sites | 92, 93 | **Open** |
| SEC-BA-002 | P1 | FormRequest `authorize()` returns bare `true` (Gate-mitigated) | 55 | Documented |
| DOC-BA-001 | Doc | DDL-doc prefix `bha_` vs live `ba_` | 02 | Confirmed |
| INC-GAP-01 | Gap | 7-day real-time-logging rule not enforced (only before_or_equal:today) | 71 | Open |
| INC-GAP-02 | Gap | description Min 20 / Max 1000 not enforced (only max:3000, no min) | 72 | Open |
| INC-GAP-03 | Gap | Category mandatory (screen) but category_id nullable | 73 | Open |
| INC-GAP-04 | Gap/Doc | severity labels Info/Low/Medium/High vs enum minor/moderate/major/critical | 34, 74 | Documented |
| INC-GAP-05 | Gap/Doc | positive incident_type value `positive_reinforcement` vs screen "Positive (Achievement)" | 11 | Documented |

## 6. Legend
- **Full** — behaviour asserted directly. **Partial** — asserted defensively / skipped when a dependency or co-located source is env-limited. **Gap** — no coverage (none here).
- Method refs are `test_incident_NN`. All 49 methods map to ≥1 TC; all TCs map to ≥1 method (see TcList §2–3).
