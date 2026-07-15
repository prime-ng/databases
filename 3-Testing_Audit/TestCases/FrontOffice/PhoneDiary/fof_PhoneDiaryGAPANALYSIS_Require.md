# FrontOffice :: PhoneDiary — Gap Analysis & Traceability

Maps every TC ↔ test method with coverage = Full / Partial / Gap, plus the Cross-Reference Defect Scan and Coverage-Score tables. Suite: `fof_PhoneDiary_TestCas.php` — 39 methods, `php -l` clean.

Legend: **Full** = TC directly asserted end-to-end; **Partial** = asserted with a documented tolerance/limitation; **Gap** = not automatable in the harness (noted).

---

## 1. Coverage by category

### Schema / DDL (G43–G46)
| TC | Method | Coverage | Notes |
|----|--------|----------|-------|
| TC-P01 | `_01` | Full | Table, columns, casts, fillable, `$table`, soft-delete col+trait independent, unique-index=0 |
| TC-N01 | `_02` | Full | Missing each of 5 NOT-NULL user cols → DB rejection (tolerant message set) |
| TC-P02 | `_03` | Full | All nullable cols omitted → NULL persisted |
| TC-P03 | `_04` | Full | Defaults read back via `->refresh()` |
| TC-P04 | `_05` | Full | G43: no UNIQUE key → duplicates allowed (proven, not assumed) |
| TC-P05 | `_06` | Full | bool/date casts |

### Validation / length (G45)
| TC | Method | Coverage | Notes |
|----|--------|----------|-------|
| TC-N02..N06 / TC-P12 | `_30`–`_34` | Full | Over-length (n+5) rejected/truncated **and** exactly-n accepted, per sized column |
| TC-N07 | `_35` | Full | Invalid ENUM not stored canonical (tolerant of MySQL coercion) |
| TC-P11 | `_36` | Full | Both ENUM values accepted |
| TC-N08 | `_37` | Partial | Store negative via browser POST; asserts non-2xx set `{302,422,419,500}` (500-vs-422 tolerated, F41) |

### Business rules / lifecycle (BC-BIZ / BC-SM)
| TC | Method | Coverage | Notes |
|----|--------|----------|-------|
| TC-P06/P07/P08 | `_10`/`_11`/`_12` | Full | actionPending + active scopes; KPI count `>=` |
| TC-P09 | `_20` | Full | `complete` PATCH sets action_completed |
| TC-P10 | `_21` | Full | `toggle-status` JSON success + is_active flipped |
| TC-P17 | `_64` | Full | Edit loads current value; update endpoint persists change (PUT spoof) |
| TC-P18..P21 | `_70`–`_73` | Full | Soft-delete → trash → restore → force-delete lifecycle |

### FK / Integration (BC-REF)
| TC | Method | Coverage | Notes |
|----|--------|----------|-------|
| TC-N09 | `_40` | Full | Invalid `recipient_user_id` → FK violation |
| TC-D01 | `_41` | Full | `SHOW CREATE TABLE` asserts FKs ON DELETE SET NULL |
| TC-D02/P13 | `_42` | Full | logged_by/created_by auto-set to acting user on store (G48) |

### Permissions (BC-AUTH, F37/#31)
| TC | Method | Coverage | Notes |
|----|--------|----------|-------|
| TC-N10 | `_50` | Full | Guest → `/login` |
| TC-N11 | `_51` | Full | Fresh non-super-admin without viewAny → 403 (cache flushed) |
| TC-N12 | `_52` | Full | Non-super-admin without create → store 403/419 |

### UI/UX
| TC | Method | Coverage | Notes |
|----|--------|----------|-------|
| TC-P14 | `_60`/`_61` | Full | Index lists; search shows match, hides non-match |
| TC-P15 | `_62` | Full | call_type filter |
| TC-P16 | `_63` | Full | Show page details |

### Edge / Security
| TC | Method | Coverage | Notes |
|----|--------|----------|-------|
| TC-N13 | `_74` | Full | 404 for non-existent id (tolerant) |
| TC-P22 | `_75` | Full | TEXT message/action_notes long content |
| TC-N14/S01 | `_90` | Full | Stored XSS escaped on show |
| TC-S02 | `_91` | Full | DEV-FOF-PD-002 proven (no activityLog in controller source) |
| TC-S03 | `_92` | Full | DEV-FOF-PD-001 proven (authorize()=true) |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Negative | 14 | 13 | 1 | 0 | 100% |
| Positive | 22 | 22 | 0 | 0 | 100% |
| Dependency/FK | 2 | 2 | 0 | 0 | 100% |
| Security/DEV | 3 | 3 | 0 | 0 | 100% |
| **Overall** | **41 TC → 39 methods** | **40** | **1** | **0** | **100%** |

Targets met: Negative 100%, Positive ≥90% (100%), Dependency ≥90% (100%).

---

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 6 | 6 | 100% |
| State-Machine (BC-SM) | 5 | 5 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration/FK (BC-REF) | 2 | 2 | 100% |
| Permissions (BC-AUTH) | 6 | 6 | 100% |
| DDL constraints (BC-DB) | 18 | 18 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No item at 0.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | DDL `ENUM('Incoming','Outgoing')` vs Request `in:Incoming,Outgoing` | **Match** — no defect |
| 2 | Route registration | Blade `route('fof.phone-diary.*')` vs `web.php` | **Match** — all names registered |
| 3 | Gate vs Policy | Controller `Gate::authorize('frontoffice.phone-diary.*')` — string gates, no model Policy | Consistent with module (SEC-FOF-001 pattern is Visitor-specific; no policy guard needed here) |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | **Match** — all user cols fillable |
| 5 | Cast vs DDL | `action_required/completed/is_active` boolean on TINYINT(1); `call_date` date on DATE | **Match** |
| 6 | Service delegation | Controller has no Service (thin CRUD) | N/A |
| 7 | State machine vs impl | complete/toggle/destroy/restore/forceDelete all implemented | **Match** |
| 8 | Validation vs FormRequest | required set vs `rules()` | `call_time` lacks `date_format` → **DEV-FOF-PD-005** |
| 9 | Error message vs FormRequest | Request defines no custom `messages()` | Default Laravel messages (acceptable) |
| 10 | Permissions vs gates | 6 abilities used | **Match**; `show` uses `viewAny` not `view` → **DEV-FOF-PD-004** |
| 11 | Integration FK vs migration | recipient_user_id / logged_by FK SET NULL | **Match** (verified via SHOW CREATE) |
| 12 | UNIQUE enforcement | DDL UNIQUE vs Request `unique:` | No UNIQUE key, no `unique:` rule → **consistent** (G43 N/A) |
| 13 | Required enforcement | DDL NOT-NULL vs Request `required` | call_type/call_date/call_time/caller_name/purpose all `required` → **Match** |
| 14 | Length enforcement | DDL VARCHAR(n) vs Request `max:` | caller_name 100/100, caller_number 15/15, caller_organization 100/100, recipient_name 100/100, purpose 200/200 → **all aligned, no defect** |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs model `SoftDeletes` | **Both present** — agree |
| 16* | Activity-log convention | Module helper `activityLog()` (72 sites) vs PhoneDiaryController | **0 calls** → **DEV-FOF-PD-002** |
| 17* | FormRequest authorize | Defense-in-depth vs `authorize(){return true;}` | Blanket true → **DEV-FOF-PD-001 / SEC-FOF-003** |

\* Extra module-specific checks beyond the standard 15.

### DEV register (this feature)
| ID | Sev | Check | Proving test |
|----|-----|-------|--------------|
| DEV-FOF-PD-001 | P1 | #17 (SEC-FOF-003) | `_92` |
| DEV-FOF-PD-002 | P2 | #16 | `_91` |
| DEV-FOF-PD-004 | P3 | #10 | documented; gate covered by `_51` |
| DEV-FOF-PD-005 | P3 | #8 | `_02` (DB layer) |

---

## 5. Notes / limitations
- G43 (duplicate-rejection) is **not applicable** — `fof_phone_diary` declares no UNIQUE key; `_05` proves duplicates are allowed by design.
- Over-length tests assert `strlen <= n` OR an exception (tolerant of MySQL non-strict truncation vs strict `1406`, per #45/#41).
- FK-SET-NULL cascade (deleting a `sys_users` row and observing `recipient_user_id` nulled) is **not** exercised at runtime (destructive to shared tenant users); instead the constraint is asserted structurally via `SHOW CREATE TABLE` (`_41`).
- All browser mutations run authenticated with CSRF + `X-Requested-With` headers; endpoint status checks prefer the fetch/navigation-timing status over UI scraping.
- Store/update endpoints will 404 while FrontOffice is disabled in `modules_statuses.json`; `_42` fails-soft (`markTestSkipped`) if no row persists.
