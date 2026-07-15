# Billing → Invoicing — Manual Testing Spec

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (`BIL`, prefix `bil_`) |
| Feature / Screen | Invoicing (Invoice Generation) — Invoicing tab of Billing Management |
| URL | `GET /billing/billing-management` (default `type=invoicing`, pane `#invoicing-pane`) |
| DB scope | PRIME / CENTRAL (`prime_db`, host `127.0.0.1:8000`) |
| Controller (screen) | `Modules\Billing\Http\Controllers\BillingManagementController` |
| Service | `Modules\Billing\Services\InvoiceGeneratorService` (generation logic) |
| Console command | `prime:generate-invoices` (`GenerateInvoicesCommand`) — auto/batch generation |
| Dead stub | `Modules\Billing\Http\Controllers\InvoicingController` (unrouted — DEV-BIL-004) |
| Models | `BilTenantInvoice` (`bil_tenant_invoices`), `BillOrgInvoicingModulesJnt` (`bil_tenant_invoicing_modules_jnt`), `InvoicingAuditLog`, `InvoicingPayment` |
| Policies / Gates | `InvoicingPolicy` → `prime.invoicing.*`; tab uses `prime.billing-management.*` (Gate::any) |
| Validation | `updateInvoiceRemarks` (`id` required integer; `remarks` nullable string max:5000); filters presence-only |
| Migrations | **0** — schema is DDL-authored (`Billing_DDL_v1.sql`); the audit flags model↔DDL divergence |
| CRUD type | List + auto-generate (POST) + AJAX detail endpoints + status toggle + print/PDF/email. No manual invoice edit/delete UI. |
| Soft delete | Model declares `SoftDeletes` but table has **no `deleted_at`** (DEV-BIL-001) — trashed flows are non-functional |
| Pagination | 10 per page |
| Activity log | `activityLog($model, 'Store', [...])` on generate/print/remark; `'ToggleStatus'` on status toggle |
| Route names | `...billing.billing-management.index/store/toggleStatus/invoice.details/print.data/invoice.remarks.update` (blade uses `central.` prefix) |

**Environment prerequisites:** Billing module **enabled** in `modules_statuses.json` (else 404, 05_ E19); `prime_db` reachable on `127.0.0.1`; `APP_ENV=testing` (05_ E20); super-admin credentials (`DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD`). Invoice generation additionally needs seeded `prm_tenant_plan_rates`, `prm_tenant_plan_billing_schedule`, a tenant DB with students — data-heavy flows are guarded (skip) where unseeded.

---

## 2. Business Conditions (detailed)

### Invoice number auto-generation (BC-BIZ-01)
- Format `INV-YYYYMMDD-NNN`, e.g. `INV-20260710-001`.
- `NNN = count(invoices created today) + 1`, zero-padded to 3 digits. Application-level (not DB) — a race window exists (audit ERR note).

### Financial calculation flow (BC-BIZ-02..06)
```
billing_qty       = max(min_billing_qty, total_user_qty)
sub_total         = plan_rate × billing_qty
tax_base          = sub_total − discount_amount + extra_charges
tax{n}_amount     = tax_base × (tax{n}_percent / 100)     for n in 1..4
total_tax_amount  = tax1_amount + tax2_amount + tax3_amount + tax4_amount
net_payable_amount= sub_total − discount_amount + extra_charges + total_tax_amount
payment_due_date  = invoice_date + credit_days
```

### Cross-tenant student count (BC-BIZ-08)
- `Tenancy::initialize($tenant)` → `Student::where('is_active','1')->whereBetween('created_at',[rate.start,rate.end])->count()` → `Tenancy::end()` (in a `finally`). This is the ONE tenant-DB touch; the invoice itself is central.

### Atomic generation (BC-BIZ-09/10)
- `DB::transaction()` creates: invoice row, module junction rows, `GENERATED` audit-log row; updates schedule `bill_generated=1`, `generated_invoice_id`. Retries up to 5 times on failure. `bill_generated=1` prevents re-invoicing.

### Status lifecycle (BC-SM)
- `PENDING` (initial, dropdown ordinal 1) → `PARTIALLY_PAID` → `PAID` (payments feature). `OVERDUE` has **no automated detection**; `CANCELLED` has **no dedicated endpoint** — documented gaps.

### Known defects (proving/guard tests)
- **DEV-BIL-001 (P0):** `bil_tenant_invoices` has no `deleted_at`; model uses `SoftDeletes` → any `withTrashed/onlyTrashed/forceDelete` throws `SQLSTATE[42S22]`.
- **DEV-BIL-002 (P0, remediated):** audit reported a phantom `invoice_amount` + duplicated 8-field block in `$fillable`; current source is clean — regression guard compares `$fillable ⊆ DDL columns`.
- **DEV-BIL-003 (P0):** audit table DDL column is `tenant_invoicing_id`; code writes `tenant_invoice_id`.
- **DEV-BIL-004 (P2):** `InvoicingController` returns non-existent views and is unrouted.
- **DEV-BIL-008 (P2):** modules_jnt DDL FK targets `bil_tenant_invoice`/`tenant_invoicing_id` (wrong names).

---

## 3. Manual Test Cases

### TC-P14 — Invoicing tab loads with filters (`_60`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as super-admin at `http://127.0.0.1:8000/login` | Prime dashboard |
| 2 | Visit `/billing/billing-management` | Page loads; path is exactly `/billing/billing-management` |
| 3 | Ensure `#invoicing-tab` active | `#invoicing-pane` visible, no 403/404/login banner |
| 4 | Inspect filters | `select[name=data_type]`, `input[name=date_range]`, `select[name=status]`, and `#invoicing-pane table` present |
| DB | — | no writes on load |

### TC-P06 — Invoice number auto-format (`_10`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SELECT invoice_no FROM bil_tenant_invoices ORDER BY id DESC LIMIT 1` | Matches `^INV-\d{8}-\d{3,}$` |
| 2 | (skip) if no rows | Documented as pending data |

### TC-P07/P08/P09/P11 — Financial invariants on an existing invoice (`_11/_12/_13/_15`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read latest invoice row | `net_payable_amount = sub_total − discount_amount + extra_charges + total_tax_amount` (±0.01) |
| 2 | Check qty | `billing_qty = max(min_billing_qty, total_user_qty)` |
| 3 | Check due date | `payment_due_date = invoice_date + credit_days` |
| 4 | Check tax | `total_tax_amount = tax1+tax2+tax3+tax4` (±0.01) |

### TC-N09 / DEV-BIL-001 — SoftDeletes without deleted_at (`_02`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm model uses `SoftDeletes` | true |
| 2 | `Schema::hasColumn('bil_tenant_invoices','deleted_at')` | **false** (defect present) |
| 3 | Run `BilTenantInvoice::onlyTrashed()->get()` | throws `SQLSTATE[42S22] Unknown column deleted_at` |
| DB | `SHOW COLUMNS FROM bil_tenant_invoices LIKE 'deleted_at'` | empty |

### TC-D03 / DEV-BIL-002 — fillable regression guard (`_03`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read `$fillable` | does NOT contain `invoice_amount` |
| 2 | For each fillable column | exists in `bil_tenant_invoices` DDL and as a real column |
| 3 | Count uniqueness | no duplicate entries |

### TC-N01/N02 — Remarks update validation (`_30/_31`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/billing/invoice/remarks/update` without `id` (authenticated) | 422 validation (or auth/route guard status) |
| 2 | POST with `remarks` length 5001 | 422 validation |
| DB | — | no remark persisted on failure |

### TC-N03 — Generate requires ids[] (`_32`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/billing/billing-management` with no `ids` (authenticated) | 400 JSON `No plan rate IDs received.` (or guard status) |
| DB | `bil_tenant_invoices` count | unchanged |

### TC-N07 — Invoice details invalid id (`_70`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/billing/invoice-details?id=999999999` (authenticated) | 404 (`findOrFail`) or auth/permission status; no HTML leak |

### TC-N05 — Guest redirect (`_53`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies; visit `/billing/billing-management` | Redirected to `/login` (or login form shown) |

### TC-P22/P24 — Permissions & policy (`_50/_52`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Assert `Gate::has('prime.invoicing.viewAny')` … `remark` | all registered |
| 2 | Assert `InvoicingPolicy` has `viewAny…forceDelete` | 10 methods present |

### TC-P17 — Filter submit renders (`_63`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/billing/billing-management?type=invoicing&data_type=Inv.+Need+To+Generate` | Table renders; no error |

### TC-P12 — Generate command dry-run (`_16`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `php artisan prime:generate-invoices --dry-run` | Lists due schedules or "No billing schedules ready"; exit 0; **no** invoice rows created |

### TC-T01 / TC-P29 — Central scope + tenancy discipline (`_90/_91`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm `prm_tenant`/`prm_billing_cycles` present on connection | central/prime scope |
| 2 | Inspect `InvoiceGeneratorService` | contains `Tenancy::initialize` AND `Tenancy::end` |

### TC-S01 — Remarks XSS escaping (`_92`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `invoice-details.blade.php` | remarks rendered with `{{ }}` (escaped), not `{!! !!}` |
