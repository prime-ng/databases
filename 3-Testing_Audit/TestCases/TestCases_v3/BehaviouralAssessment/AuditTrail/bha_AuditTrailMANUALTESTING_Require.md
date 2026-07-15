# Audit Trail — Manual Test Specification (`bha_AuditTrailMANUALTESTING_Require.md`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | AuditTrail (Reports → Audit Trail) |
| URL | `GET /behavioural-assessment/audit-log` |
| Route name | `behavioural-assessment.audit-log.index` (only route) |
| Controller | `BaAuditLogController@index` |
| Model | `BaAuditLog` (table `ba_audit_log`, `$timestamps=false`, no SoftDeletes) |
| FormRequest | NONE (read-only) |
| Migration | `database/migrations/tenant/2026_06_16_130613_create_ba_audit_log_table.php` |
| CRUD type | **Read-only** (immutable ledger — insert-only via `BaAuditLog::log()`) |
| Soft delete | NO (no `deleted_at`) |
| Pagination | 30 per page (`paginate(30)`) |
| Filters | `period_id`, `entity_type` (=), `field_name` (LIKE `%..%`) |
| Ordering | `changed_at DESC, id DESC` |
| Activity log | NONE (this screen IS the audit sink) |
| Permission | `tenant.behavioural-assessment.audit-log.{viewAny\|view}` |
| DB scope | TENANT (`InitializeTenancyByDomain`, `auth`, `verified` middleware) |

**Environment prerequisites:** BehaviouralAssessment must be `true` in `prime_testing/modules_statuses.json` (else 404 on all routes); `APP_ENV=testing`; tenant domain resolvable via `DUSK_TENANT_URL`.

---

## 2. Business Conditions (detailed)

**The Immutable Ledger Rule (Screen-BR).** `ba_audit_log` is strictly insert-only. There is **no interface or API endpoint** to edit or delete rows — even a Super Admin cannot mutate history through the UI. Confirmed in code: the module registers only `GET audit-log`; the model has `$timestamps=false`, no `deleted_at`/`updated_at`, and does not use `SoftDeletes`.

**What is logged.** Polymorphic rows keyed by `entity_type` ∈ {`assessment`, `assessment_rating`, `incident`} + `entity_id`, capturing `field_name`, `old_value`, `new_value`, `changed_by`, `changed_at`.

**Filters actually implemented (narrower than the requirement).**
- Period dropdown → `scopeForPeriod(period_id)` (compound subquery over assessments/ratings/incidents).
- Entity Type dropdown → exact match on `entity_type`.
- Field search (text + datalist) → `field_name LIKE %..%`.

**Cross-reference gaps (defects to file):**
- **DOC-BA-001** — DDL doc says `bha_audit_log`; live table is `ba_audit_log`.
- **DOC-BA-AUD-001** — requirement asks for Date-Range, Action-Category dropdown (`Grade Edit`/`Remark Edit`/`Config Change`/`Status Lock`/`Record Delete`), User autocomplete and Student filters — **none implemented**.
- **DOC-BA-AUD-002** — requirement promises IP-address capture + an IP-Address grid column — **no `ip_address` column exists** and the grid renders none.

---

## 3. Manual Test Cases

### MTC-01 — Schema & immutability (DB)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SHOW COLUMNS FROM ba_audit_log` | Columns id, entity_type, entity_id, field_name, old_value, new_value, changed_by, changed_at, is_active, created_by, created_at |
| 2 | Check for `updated_at` / `deleted_at` | **Absent** — ledger is immutable |
| 3 | `SHOW INDEX FROM ba_audit_log` | `idx_ba_audit_entity`, `idx_ba_audit_changed_by`, `idx_ba_audit_changed_at` present |
| 4 | Confirm `SELECT * FROM information_schema.tables WHERE table_name='bha_audit_log'` | 0 rows (DOC-BA-001: only `ba_audit_log` exists) |

### MTC-02 — Render index (Admin)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as Admin (`root@tenant.com`) | Dashboard loads |
| 2 | Visit `/behavioural-assessment/audit-log` | Page 200; breadcrumb "Audit Log" |
| 3 | Inspect grid header | Columns: #, Changed At, Entity, Record, Context, Field, Old Value, New Value, Changed By |
| 4 | Inspect filter bar | Period dropdown, Entity Type dropdown, Field search input, Search + Reset buttons, "{n} records" counter |

### MTC-03 — Listing & ordering
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Insert two audit rows (older `changed_at`, newer `changed_at`) | rows persisted |
| 2 | Visit index filtered to those rows | Both rows visible |
| 3 | Observe order | Newer row appears **above** older row (changed_at DESC) |
| 4 | Read counter | "N records" matches filtered count |

### MTC-04 — Entity-type filter
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed one `incident` row (token INC) and one `assessment` row (token ASM) | rows persisted |
| 2 | Select Entity Type = "Incident", Search | INC visible; ASM **not** visible |

### MTC-05 — Field-name (LIKE) filter
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed one row with `field_name` = matchfield, one with otherfield | rows persisted |
| 2 | Type "matchfield" in Field search, Search | Match row visible; other row hidden |
| 3 | Confirm input retains "matchfield" | Value persists in the box |

### MTC-06 — Empty state
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Search Field = a non-existent token | Grid shows "No audit records found."; counter "0 records" |

### MTC-07 — Period filter
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure an active `ba_assessment_period` exists | present in dropdown |
| 2 | Select a period, Search | Page renders 200; only rows tied to that period (no error) |

### MTC-08 — Pagination (30/page)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed 31 rows with a shared field marker | rows persisted |
| 2 | Filter by that marker | "31 records"; pagination nav visible |
| 3 | Click page 2 | URL keeps `field_name=` filter (appends) |

### MTC-09 — Immutability enforcement
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check `route:list` for `behavioural-assessment.audit-log.*` | Only `.index` (GET) registered |
| 2 | Issue `POST /behavioural-assessment/audit-log` | 405 Method Not Allowed (or 404) |
| 3 | Issue `DELETE /behavioural-assessment/audit-log` | 405 Method Not Allowed (or 404) |
| 4 | Confirm no create/edit/delete button in the UI | None present |

### MTC-10 — Permissions
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Logout, visit the URL as guest | Redirect to `/login` |
| 2 | Login as a non-super-admin **without** `audit-log.viewAny` | GET returns 403 |
| 3 | Confirm `BaAuditLogPolicy::viewAny` → `can('tenant.behavioural-assessment.audit-log.viewAny')` | Gate string matches |

### MTC-11 — Cross-reference gaps (defect confirmation)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect the filter bar for a Date-Range / User / Student / Action-Category dropdown | **Absent** → DOC-BA-AUD-001 |
| 2 | Inspect grid for an "IP Address" column; `SHOW COLUMNS` for `ip_address` | **Absent** → DOC-BA-AUD-002 |

### MTC-12 — Security (XSS)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Insert a row with `old_value = <script>alert(1)</script>` | row persisted |
| 2 | View index filtered to it | Value is Blade-escaped; no script executes; raw tag absent from DOM |
