# FrontOffice (FOF) — Module Defect Register (roll-up)

> Every defect surfaced across the 16 feature artifact sets, plus the 18 audit defects carried from `FrontOffice_Technical_Audit_2026-06-29.md` (FactPack §6).
> Each proving test asserts **current observed behaviour** (with a fix-tripwire), never the intended fix — divergences from the audit are documented, not worked around.
> **Distinct total: 86** = 18 audit-carried + 68 net-new live divergences. (~5 net-new feature IDs alias an audit item — e.g. `DEV-FOF-ED-01`=`SEC-FOF-003`, `DEV-FOF-C01`=`BUG-FOF-002` — and are counted once, under the audit ID.)
> Remediation roll-up of the 18 audit defects: **6 confirmed remediated · 1 mitigated · 1 partially remediated · 10 still open.** All 68 net-new are open (documented).

---

## A. Module-wide patterns (grouped — each affects many features)

| Pattern ID | Sev | Pattern | Features affected | Status | Proving tests |
|-----------|-----|---------|-------------------|--------|---------------|
| **SEC-FOF-003** | P1 | `authorize(){return true;}` in all 10 FormRequests (D30) — no defense-in-depth; sole guard is the controller string gate | **ALL 10 write features** (Appointment, CertReq, Circular, Communication, Complaint, EarlyDeparture, EmergencyContact, GatePass, KeyRegister, LostFound, NoticesEvents, PhoneDiary, PostalDispatch, VisitorManagement) | **OPEN** | per-feature (e.g. `DEV-FOF-PD-001`, `DEV-FOF-ED-01`, `DEV-FOF-GP-001`) |
| **SEC-FOF-001** | P1 | Permission enforced by Spatie **string gates**, not model-bound policies → policy guards (e.g. VisitorPolicy govt-retention, BR-FOF-007) are DEAD on destroy/forceDelete | VisitorManagement, Circular, Communication, EmergencyContact, Feedback, KeyRegister, LostFound, NoticesEvents, PhoneDiary (9 features observe the pattern) | **OPEN** | VisitorManagement suite; `DEV-FOF-GP-006`, `DEV-FOF-ED-06` (policy-dead variants) |
| **Partial/absent activity logging** | P2/P3 | Several controllers omit the `activityLog()` call or use non-convention event strings (lowercase `key_issued`/`key_returned`, `email_queued`/`sms_queued`) | PhoneDiary (absent — `DEV-FOF-PD-002`), KeyRegister (lowercase strings), Communication (queued strings), LostFound | **OPEN** | `DEV-FOF-PD-002`, KeyRegister `test` asserting `key_issued` verbatim |
| **App-ENUM vs DDL-ENUM mismatch** | P2 | App code emits/accepts ENUM values not in the DDL `CREATE TABLE` ENUM (or a strict subset) → data-integrity / unreachable-option risk | Complaint (`DEV-FOF-CMP-01`), EmergencyContact (`DEV-FOF-EC-001`), Appointment (`DEV-FOF-A02` status ENUM), CertificateRequest | **OPEN** | `test_04` (Complaint), `DEV-FOF-EC-001`, `DEV-FOF-A02` (`test_01`,`test_11`) |
| **App-level uniqueness without DB index** | P2/P3 | Uniqueness enforced only in PHP (or an index left non-UNIQUE) → race can insert dups | Appointment (`idx_fof_apt_slot` non-UNIQUE), CertReq (`cert_number` dup-on-NULL), register-number generators | **OPEN / partly mitigated** | `test_12` (Appointment), `DAT-FOF-002` family |
| **DAT-FOF-002** | P2 | Register-number generators use unlocked read-modify-write (race → dup numbers) | ALL auto-number features (CertReq, Complaint, GatePass, KeyRegister, PostalDispatch, EarlyDeparture, VisitorManagement) | **MITIGATED** where `lockForUpdate()` added (EarlyDeparture, GatePass); audit claim narrowed | `_11` (ED), `test_31` (GatePass UNIQUE backstop) |
| **PERF-FOF-001** | P2 | Unbounded `->get()` / full active-student preload per render | CertificateRequest, KeyRegister, Complaint, Appointment, ReportsDashboard (indirect) | **OPEN** | render-success methods per feature |

---

## B. Audit-carried defects (FactPack §6) — full status

| ID | Sev | Feature(s) | One-line | Status | Proving test |
|----|-----|-----------|----------|--------|--------------|
| VAL-FOF-001 | P1 | Appointment | Slot-overlap double-booking (BR-FOF-017) | **REMEDIATED** — `store()` now `lockForUpdate()`+`DomainException`; `update()` still no re-check, idx not UNIQUE | `test_12` (`=DEV-FOF-A01`) |
| DAT-FOF-001 | P1 | CertificateRequest | `issue()` had no StudentFee clearance check (BR-FOF-005) | **REMEDIATED** in current source | `test_cert_41` |
| BUG-FOF-001 | P1 | CertReq, Complaint | `toggleStatus(): JsonResponse` unimported → 500 | **REMEDIATED** — import present | `test_complaint_63`, CertReq source-verify |
| BUG-FOF-003 | P2 | Complaint | `escalate()` did not create linked CMP record | **REMEDIATED** — creates `cmp_complaints` row | `test_complaint_23` |
| DAT-FOF-003 | P2 | PostalDispatch | `update()` bypassed acknowledgement lock (BR-FOF-009) | **REMEDIATED** — lock at acknowledge/update/destroy | `test_22`, `test_23` |
| DAT-FOF-004 | P2 | KeyRegister, GatePass | Key issue & gate-pass create lacked row locks | **REMEDIATED** — `DB::transaction`+`lockForUpdate()` both | `test_95` (KR), GatePass `createPass` |
| DAT-FOF-002 | P2 | ALL auto-number | Unlocked read-modify-write on register numbers | **MITIGATED** (ED, GatePass locked); still open for others | `_11`, `test_31` |
| BUG-FOF-002 | P1 | Circular | `distribute()` a status-flip stub — no recipients/rows/NTF | **PARTIALLY OPEN** — distribution rows now written; NTF dispatch still missing | `test_circular_13` (`=DEV-FOF-C01`) |
| SEC-FOF-001 | P1 | VisitorManagement | Govt-retention guard bypassed (string gate not policy) | **OPEN** — govt visitor deletable today | VisitorManagement suite |
| SEC-FOF-002 | P1 | Feedback | Anonymous feedback stores `respondent_user_id=auth()->id()`; `is_anonymous_allowed` ignored | **OPEN** (partial) — `is_anonymous` never set | `_24`, `_26` |
| SEC-FOF-003 | P1 | ALL (10 FormRequests) | `authorize(){return true;}` ×10 | **OPEN** | per-feature (see §A) |
| JOB-FOF-001 | P1 | EarlyDeparture | `EarlyDepartureAttSyncJob` no tenant context / no `$timeout` | **OPEN** | `DEV-FOF-ED-02` |
| JOB-FOF-002 | P1 | VisitorManagement | `fof:flag-overstay` never scheduled + not tenants:run-wrapped; `Overstay` unreachable | **OPEN** | VisitorManagement job test |
| SEC-FOF-004 | P2 | VisitorManagement | `id_proof_number` (Aadhaar) plaintext, no encrypted cast/masking | **OPEN** | VisitorManagement PII test |
| PERF-FOF-001 | P2 | CertReq, KeyRegister, Complaint, Appointment, Dashboard | Unbounded `->get()` per render | **OPEN** | render methods |
| DEAD-FOF-001 | P3 | Feedback | Commented-out expiry guards in public feedback | **OPEN** | Feedback public-flow test |
| BUG-FOF-004 | P3 | Complaint, CertReq | Register-number formats deviate from BR-FOF-016 | **OPEN** | Complaint/CertReq number-format tests |
| ORM-FOF-001 | P3 | EarlyDeparture, VisitorManagement | Background paths write `updated_by=0` (non-existent user) | **OPEN** | `DEV-FOF-ED-03`, VM |

**Audit remediation summary:** 6 confirmed remediated (VAL-FOF-001, DAT-FOF-001, BUG-FOF-001, BUG-FOF-003, DAT-FOF-003, DAT-FOF-004) · 1 mitigated (DAT-FOF-002) · 1 partially remediated (BUG-FOF-002) · 10 still open.

---

## C. Net-new live divergences (discovered during test generation) — all OPEN

| Feature | New IDs | Notable one-liners (proving test) |
|---------|---------|-----------------------------------|
| Appointment | DEV-FOF-A02..A08, A10 (8) | A02 status-ENUM divergence (`test_01/11`); A03 (`test_13`); A04/A05 (`test_26`); A06 (`test_72`); A07 (`test_55`); A10 update() no overlap re-check (`test_71`) |
| CertificateRequest | DEV-FOF-CR-01..07 (7) | 7 FormRequest⇄DDL / cert_number divergences; CR-05 minor, CR-07 info |
| Circular | DEV-FOF-C02..C05 (4) | distribution/NTF & edit-lock divergences (`test_circular_*`) — C01 aliases BUG-FOF-002 |
| Communication | DEV-FOF-COM-01..05 (5) | **COM-04 (P-impactful): send is a non-dispatching stub, `fof_sms_logs` never written** (`test_93`); COM-01 (`test_31`); COM-02 (`test_15/33`) |
| Complaint | DEV-FOF-CMP-01..02 (2) | CMP-01 ENUM mismatch `Infrastructure/Staff/Transport` vs DDL (`test_04`); CMP-02 `update()` FSM bypass (`test_26`) |
| EarlyDeparture | DEV-FOF-ED-05, ED-06 (2 net-new) | ED-05 info; ED-06 Policy dead on paths (abilities still via Spatie). ED-01/02/03/04 alias SEC-FOF-003/JOB-FOF-001/ORM-FOF-001/DAT-FOF-002 |
| EmergencyContact | DEV-FOF-EC-001..004 (4) | EC-001 contact_type app subset (Utility/Parent_Emergency/Government unreachable); EC-003 no FormRequest → default messages |
| Feedback | DEV-FOF-F01 (1) | **P1: `fof_feedback_responses.created_by/updated_by` NOT NULL but public submit inserts NULL → constraint violation, public submission fails** |
| GatePass | DEV-FOF-GP-002, GP-005, GP-006 (3 net-new) | GP-002 dead `Cancelled` state (P2); GP-006 policy/string-gate divergence (P3). GP-001/003/004 alias SEC-FOF-003/DAT-FOF-004/002 |
| KeyRegister | DEV-FOF-KR-001..008 (8) | **KR-001 (P1): create impossible — `key_type` NOT NULL no-default never validated/set**; KR-006 gap-by-design (no app path) |
| LostFound | DEV-LF-001..008 (8) | **LF-001 (P1): create non-functional** (`test_41/74`); LF-002..008 P2/P3 (`test_30/35/36/37/25/14`) |
| NoticesEvents | DEV-FOF-NE-001..006 (6) | **NE-004 (P1): `end_date` NOT-NULL-vs-nullable divergence**; NE-001/002/003 P2; NE-006 P3 |
| PhoneDiary | DEV-FOF-PD-002, PD-004, PD-005 (3 net-new) | PD-002 no `activityLog()` in controller (P2); PD-004/005 P3. PD-001 aliases SEC-FOF-003 |
| PostalDispatch | DEV-FOF-DR-01..03, DEV-FOF-PD-04 (4) | 3 DispatchRegister FormRequest⇄DDL divergences (DR-01/03 P2, DR-02 P3); PD-04 P2 |
| VisitorManagement | DEV-FOF-VM-04..06 (3) | VM-04 (`test_37`); VM-05; VM-06 (`test_18`) — surfaced beyond FactPack pre-map |

**Net-new count = 68 distinct.** Skew: mostly P2/P3; a handful of **P1 create-blocking** defects worth escalating first — `DEV-FOF-KR-001`, `DEV-LF-001`, `DEV-FOF-F01`, `DEV-FOF-NE-004`, plus `DEV-FOF-COM-04` (stub send).

---

## D. ID-collision note (for the maintainer)
`DEV-FOF-PD-*` is reused by **two** features — PhoneDiary (`DEV-FOF-PD-001/002/004/005`) and PostalDispatch (`DEV-FOF-PD-04`). Namespaced here by feature. Recommend renumbering PostalDispatch's `PD-04` to a `DR-`/`POS-` prefix to avoid ambiguity.
