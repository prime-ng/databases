# Email Schedule — Gap Analysis (`bil_EmailScheduleGAPANALYSIS_Require`)

Single Dusk suite: `bil_EmailSchedule_TestCas.php` — **37 methods**. Screen type: read + cancel (no create/update matrix).

## 1. Manual TC ↔ Dusk method mapping

| Manual | Dusk method(s) | Coverage |
|--------|----------------|----------|
| MT-01 Index loads | `_10`, `_11` | Full |
| MT-02 View detail | `_13`, `_40` | Full |
| MT-03 Cancel pending | `_14`, `_15` | Full |
| MT-04 Cancel visibility | `_21` | Full |
| MT-05 Search & filter | `_60`,`_61`,`_62`,`_63`,`_64` | Full |
| MT-06 Not found / auth | `_30`,`_31`,`_32`,`_51`,`_52` | Full |
| MT-07 SM defects | `_22`,`_23`,`_20` | Full (documents current) |
| MT-08 Integrity/security | `_41`,`_42`,`_91`,`_92` | Full |
| Config truth | `_01`,`_02`,`_03`,`_04`,`_05`,`_80`,`_81`,`_90` | Full |

## 2. Coverage Summary (by TC category)

| Category | Total | Full | Partial | Gap | % Full |
|----------|-------|------|---------|-----|--------|
| Positive | 13 | 12 | 1 | 0 | 92% |
| Negative | 9 | 9 | 0 | 0 | 100% |
| Dependency / State / Security | 8 | 7 | 1 | 0 | 88% |
| **Overall** | **30** | **28** | **2** | **0** | **93%** |

Partial notes:
- `_40` / `_60`/`_61` invoice-backed search (`_40` uses a seeded `bil_tenant_invoices` row) → `markTestSkipped` if that table's insert isn't satisfiable in the environment. Non-invoice search coverage (`_63`,`_64`) is unconditional.
- `_15` central activity-log assertion is defensive (`markTestSkipped` if `sys_central_activity_logs` unreachable).

## 3. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) | 6 | 7 | 86% |
| State-Machine (`Screen-SM`) | 4 | 4 | 100% |
| Validation Rules (`Screen-VR`) | 2 | 2 | 100% |
| Integration Points (`Screen-IP`) | 2 | 2 | 100% |
| Permissions (`Screen-PM`) | 3 | 3 | 100% |

`Screen-BR` uncovered: the immediate/scheduled **send** flows (`billing-management.sendEmail` / `.scheduleEmail`) live in `BillingManagementController`, **not** this screen — out of scope for the EmailSchedule feature (belongs to Invoicing).

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | Test |
|---|-------|---------|---------|------|
| 1 | Enum case | n/a (VARCHAR status, no ENUM) | none | — |
| 2 | Route registration | blade `route('central.billing.email-schedule.*')` vs `routes/web.php` | **Registered in root `routes/web.php:417`, not the module's own `routes/web.php` (empty).** Module `RouteServiceProvider::map()` calls both mapWeb+mapApi but the web file is empty; routes are wired centrally. (E23 verified — no missing route.) | `_02` |
| 3 | Gate vs Policy | `Gate::authorize('prime.email-schedule.*')` | string gates; resolved via super-admin `Gate::before` (audit). No dedicated EmailSchedule policy — acceptable. | `_50`-`_52` |
| 4 | Fillable vs DDL | model fillable vs columns | fillable minimal (3); table absent from module DDL → **DEV-BIL-ES-002** | `_01`,`_42` |
| 5 | Cast vs DDL | no casts declared | `schedule_time` uncast (string) — minor, not blocking | — |
| 6 | Service delegation | controller vs service | no service layer; logic inline (thin) | — |
| 7 | State machine vs impl | screen SM vs controller/job | **DEV-BIL-ES-001** (no sent/failed write), **DEV-BIL-ES-003** (no pending guard on cancel) | `_22`,`_23` |
| 8 | Validation vs FormRequest | n/a | no FormRequest on screen | — |
| 9 | Error message vs source | flash text | `'Email schedule cancelled successfully.'` asserted via DB+redirect | `_14` |
| 10 | Permissions vs matrix | screen matrix vs gates | **Screen doc lists `prime.billing-management.*`; real gates are `prime.email-schedule.*`** — source wins; doc is stale | `_50`-`_52` |
| 11 | Integration FK vs migration | invoice_id FK | **No FK on `invoice_id`** (DATA-BIL-003) → **DEV-BIL-ES-002** | `_42` |

## 5. Discovered / mapped defects

| DEV ID | Sev | Description | Status | Proving test |
|--------|-----|-------------|--------|--------------|
| DEV-BIL-ES-001 | P2 | Job never persists `sent`/`failed` schedule transition (BR-BIL-030 partial / JOB-BIL-001) | Open | `_23` |
| DEV-BIL-ES-002 | P2 | `invoice_id` has no FK; table absent from module DDL (DATA-BIL-003) | Open | `_42`,`_01` |
| DEV-BIL-ES-003 | P2 | `destroy()` has no server-side `pending` guard | Open | `_22` |
| OBS-BIL-ES-004 | P3 | Stale permission matrix + legacy class-name typo in requirement doc | Doc-only | — |

## 6. Legend
Full = behaviour + DB/source asserted. Partial = defensive skip path exists. Gap = no method. DEV tests assert **current** (buggy) behaviour and will fail loudly if source changes — the signal to update the defect.
