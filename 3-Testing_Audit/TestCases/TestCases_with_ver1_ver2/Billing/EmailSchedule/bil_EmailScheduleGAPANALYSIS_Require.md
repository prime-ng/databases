# Email Schedule — Gap Analysis & Coverage

- **V1 methods:** 16  **V2 methods:** 50  (V2 ≥ 2× V1 ✔)
- **Legend:** Full = automated end-to-end assertion; Partial = asserted with environmental guard/skip or code-inspection proxy; Gap = not automated.

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual | V1 | V2 | Coverage | Notes |
|--------|----|----|----------|-------|
| MT-01 index render | 02,03,16 | 60,61,62,64,71 | Full | |
| MT-02 schedule email | 11 | 10,11,12,13,14 | Full | `Bus::fake`; audit+activity asserted |
| MT-03 immediate send | 12 | 15,16 | Full | performedById asserted |
| MT-04 cancel | 09,10 | 17,18,19,20,23 | Full | status+flash+log |
| MT-05 show details | 08 | 24,25,41,63 | Full | |
| MT-06 filters/search | 06,07 | 33,34,35,61,62,72,73 | Full | cross-table OR via 73 |

### State machine
| Transition | V2 | Coverage |
|-----------|----|----------|
| pending→cancelled | 20 | Full |
| pending→sent | 21 | Partial (representable; real worker not run) |
| pending→failed | 22 | Partial (representable; failure path via code-inspection 44) |
| pending-only cancel UI | 23,24,25 | Full |

### Negative
| Manual | V2 | Coverage |
|--------|----|----------|
| MT-07/1 show 404 | 31 | Full |
| MT-07/2 destroy 404 | 30 | Full |
| MT-07/3 guest redirect | 50,51,90 | Full |
| MT-07/4 limited-user 403 | 54 | Partial (skips if user cannot be provisioned) |
| MT-07/5 verb guard | 91 | Full |
| MT-06/4 reflected XSS | 33 | Full |
| stored XSS invoice_no | 92 | Full |
| no-validation on schedule | 32 | Partial (asserts current behaviour, documents DEV-EMS-002) |

### Dependency
| Manual | V1 | V2 | Coverage |
|--------|----|----|----------|
| MT-09 orphan FK insert | — | 05 | Full |
| MT-09 orphan render | — | 42 | Full |
| MT-08 job retry config | 14 | — | Full (code-inspection) |
| job audit strings | — | 43,44 | Partial (source-file inspection) |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 18 | 17 | 1 | 0 | 100% |
| State-machine | 5 | 3 | 2 | 0 | 100% |
| Negative | 11 | 8 | 3 | 0 | 100% |
| Dependency | 5 | 3 | 2 | 0 | 100% |
| **Total** | **39** | **31** | **8** | **0** | **100%** |

Targets met: Negative 100%, Positive ≥90% (100%), Dependency ≥90% (100%).

## 3. Coverage-Score by requirement source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR) | 6 | 6 | 100% |
| State-Machine (Screen-SM) | 3 | 3 | 100% |
| Validation (Screen-VR) | 3 | 3 | 100% |
| Integration Points (Screen-IP) | 4 | 4 | 100% |
| Permissions (Screen-PM) | 4 | 4 | 100% |

No `Source`-tagged requirement item has 0 tests.

## 4. Cross-Reference Defect Scan
| # | Check | Compared | Finding | Test |
|---|-------|----------|---------|------|
| 1 | Enum/status values | index.blade options vs status writes | Consistent (pending/sent/failed/cancelled) | 61 |
| 2 | Route registration | blade `route('central.billing.email-schedule.*')` vs `routes/web.php:412` | Registered (`Route::resource(...)->only([index,show,destroy])`) — resolved from **app-level** `routes/web.php`, NOT Billing module web.php (module stub is empty) | 30,31 |
| 3 | Gate vs Policy | controller string gates `prime.email-schedule.*` | No dedicated Policy; string gates only — **DEV-EMS-005** (verify permission is seeded as its own resource; RolePermissionSeeder lists `email-schedule` under `billing-management`) | 52,54 |
| 4 | Fillable vs migration | model fillable vs migration cols | Match (`invoice_id, schedule_time, status`) | 02 |
| 5 | Cast vs migration | model has no casts; `schedule_time` timestamp | No boolean/date cast declared (minor) | 03 |
| 6 | Service delegation | controller vs service | No service layer; logic inline (acceptable for this feature) | — |
| 7 | State machine vs impl | doc transitions vs controller | `cancelled` handled; `sent`/`failed` only set by worker — **no guard preventing re-cancel of non-pending via direct DELETE** (UI hides it, controller does not re-check status) — DEV-EMS-006 (verify) | 20,91 |
| 8 | Validation vs FormRequest | screen rules vs `rules()` | **No FormRequest** on send/schedule — DEV-EMS-002 | 32 |
| 9 | Error message vs source | expected msgs vs controller | `Emails queued successfully!`, `Email scheduled successfully for ...`, `Email schedule cancelled successfully.` verified verbatim | 15,11,19 |
| 10 | Permissions vs matrix | screen matrix vs controller gates | Screen matrix lists `prime.billing-management.*`; controller index/show/destroy actually use `prime.email-schedule.*` — **mismatch** documented | 52 |
| 11 | Integration FK vs migration | screen "FK → bil_tenant_invoices" vs migration | **FK missing** — DATA-BIL-003 / DEV-EMS-001 | 05,42 |

## 5. Discovered DEV candidates (feature-specific)
| ID | Sev | Description | Status |
|----|-----|-------------|--------|
| DEV-EMS-001 (DATA-BIL-003) | P2 | `invoice_id` no FK constraint | Confirmed |
| DEV-EMS-002 | P2 | send/schedule endpoints lack FormRequest validation | Confirmed |
| DEV-EMS-003 (DDL gap) | P2 | table absent from `Billing_DDL_v1.sql` | Confirmed |
| DEV-EMS-005 | P3 | `prime.email-schedule.*` gate keys — permission-registration/matrix mismatch | Verify in source |
| DEV-EMS-006 | P3 | `destroy()` does not re-check `status==pending` before cancelling (UI-only guard) | Verify in source |
| JOB-BIL-001 | P2 | (audit) job reliability gaps | **Remediated** in current source |

## 6. Remaining Partial-coverage limitations
- `pending→sent` / `pending→failed` real worker execution is not run (job sends live mail + DomPDF); covered by state-representability (21,22) + code-inspection of audit strings (43,44).
- Limited-user 403 (54) self-skips where a non-super-admin cannot be provisioned (sys_users FK constraints, 05_ §B).
- Job-string checks (43,44) rely on locating the app source via `MAIN_PROJECT_PATH`/sibling path; skip when unavailable.
