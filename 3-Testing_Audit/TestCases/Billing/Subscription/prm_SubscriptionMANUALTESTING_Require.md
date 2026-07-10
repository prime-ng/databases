# Subscription — Manual Testing Spec (`prm_Subscription`)

## 1. Feature Information

| Item | Value |
|------|-------|
| Module | Billing (BIL) — Prime/central layer |
| Feature | Subscription (read-only viewing layer) |
| Primary URL | `GET /billing/billing-management?type=subscription_data` (host `http://127.0.0.1:8000`) |
| AJAX panels | `GET /billing/subscription-details?id=`, `GET /billing/billing/pricing-details?id=`, `GET /billing/billing/billing-details?id=`, `GET /billing/module-details?id=&type=subscription|invoice` |
| Toggle | `POST /billing/billing-management/{id}/toggle-status` (`type=subscription&field=<flag>`) |
| Export | `POST /billing/subscription` (`ids[]`) → ZIP of PDFs; `GET /billing/billing-management/print/data?type=subscription_data` |
| Controllers | `BillingManagementController` (index/subscriptionDetails/moduleDetails/toggleStatus/printData), `SubscriptionController` (store/pricingDetails/billingDetails) |
| Models | `TenantPlanRate`, `TenantPlan`, `TenantPlanModule`, `TenantPlanBillingSchedule` (Prime); `BillingCycle` (Billing) |
| Validation | Toggle field allow-list; PDF export requires `ids`; `updateInvoiceRemarks` not in scope |
| Migrations | 0 (DDL `Billing_DDL_v1.sql` + `prime_db_v4.sql` are the schema authority) |
| CRUD Type | **Read-only** (no create/edit/delete in Billing; flag toggles + PDF export only) |
| Soft Delete | **None** — `prm_tenant_plan_*` tables have no `deleted_at`; models omit SoftDeletes |
| Pagination | 10 / page (`paginate(10)`) |
| Activity Log | `Store` (PDF export), `ToggleStatus` (flag toggle) |
| Auth | Central super-admin resolves all abilities via `Gate::before`; routes behind `['auth','verified']` on the central domain |

**Prerequisites**
1. `modules_statuses.json` → `"Billing": true` AND `"Prime": true` (both `false` by default → 404 on every route).
2. Run on `http://127.0.0.1:8000` (central), logged in as the central super-admin (`DUSK_ADMIN_EMAIL`).
3. At least one subscription chain present: `prm_tenant` → `prm_plans` → `prm_tenant_plan_jnt` → `prm_tenant_plan_rates` (+ optional `prm_tenant_plan_module_jnt`, billing schedule). Detail-panel tests skip cleanly if absent.

---

## 2. Business Conditions (detailed)

- **Read-only scope** — Billing never writes plan/rate/schedule rows; the tab only lists them, exposes flag switches (which write to `prm_tenant_plan_jnt`), and exports PDFs. Plan assignment lives in the Prime module.
- **Filters** — `status` (`Active` → `status IN (1,'ACTIVE','active')`; `Inactive` → `status IN (0,'INACTIVE','inactive')`) and `date_range` (`start_date BETWEEN`). `SUSPENDED/CANCELED/EXPIRED` match neither filter (DEV-BIL-SUB-004).
- **Flag toggle** — allowed fields: `automatic_billing, auto_renew, is_trial, is_subscribed, is_active`. Any other field → `422 {message:'Invalid subscription toggle field'}`. Success → `200 {success:true, message:'Subscription status updated successfully', data:{field, value}}` and an activity log `ToggleStatus`.
- **PDF export** — `POST /billing/subscription` with `ids[]`; no ids → `400 {error:'No IDs provided'}`. Each id logs `Store`, generates a DomPDF, zips them, streams the ZIP. Temp PDFs are unlinked.
- **Detail panels** — all return `{html: "..."}` JSON. `subscriptionDetails`/`moduleDetails` gate on `prime.billing-management.view`; `pricingDetails`/`billingDetails` gate on `prime.subscription.view`.

**Known defects to observe**
- **DEV-BIL-SUB-001** — `subscription-details` / `billing-schedule` panels may return `500` because the model targets `prm_tenant_plan_billing_schedules` (plural) while the DDL creates the singular table.
- **DEV-BIL-SUB-002** — the "Sub Status" column always shows **Deactive** (blade `status == 1` against a string status).
- **DEV-BIL-SUB-003** — subscription-details permission uses `prime.billing-management.view` not `prime.subscription.view`.

---

## 3. Manual Test Cases

### MTC-01 — Subscription tab loads
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as super-admin at `http://127.0.0.1:8000/login` | Dashboard loads |
| 2 | Visit `/billing/billing-management` | Page renders, not 403/404/login |
| 3 | Confirm the Subscription tab trigger `#subscription-tab` | Present |
| 4 | Click it | `#subscription-pane` becomes visible with a table |
| DB | `SELECT COUNT(*) FROM prm_tenant_plan_rates` | ≥ 0 rows (list source) |

### MTC-02 — Filters present
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Subscription pane | `input[name="date_range"]`, `select[name="status"]`, hidden `type=subscription_data`, and a `table` are present |

### MTC-03 — Subscription data listing
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/billing/billing-management?type=subscription_data` | Table shows headers Organization, Plan (v), Billing Period, Sub Status, and flag switches |
| DB | `... paginate(10)` | ≤ 10 rows per page |

### MTC-04 — Status filter
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select `Active`, submit | URL keeps `type=subscription_data`; results limited to active plans |
| Note | Select `Inactive` | Only `status IN (0,'INACTIVE','inactive')` — SUSPENDED/CANCELED/EXPIRED are NOT shown (DEV-BIL-SUB-004) |

### MTC-05 — Flag toggle (each allowed field)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST toggle `{type:subscription, field:auto_renew}` for a plan id | `200 {success:true, message:'Subscription status updated successfully'}` |
| DB | `SELECT auto_renew FROM prm_tenant_plan_jnt WHERE id=?` | value flipped |
| Log | activity log | event `ToggleStatus`, subject `TenantPlan` |
| 2 | Repeat for `automatic_billing, is_trial, is_subscribed, is_active` | each flips |
| 3 | Toggle again to restore | value returns to original |

### MTC-06 — Invalid toggle field
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST toggle `{type:subscription, field:hacker}` | `422 {message:'Invalid subscription toggle field'}` |
| DB | no column changed | unchanged |

### MTC-07 — Toggle without type=subscription
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST toggle `{field:is_subscribed}` (no type) with a plan id | Routes to payment branch → `InvoicingPayment::findOrFail` → 404; plan flag unchanged |

### MTC-08 — Detail panels
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/billing/subscription-details?id=<scheduleId>` | `200 {html}` — or `500` if DEV-BIL-SUB-001 fires |
| 2 | GET `/billing/billing/pricing-details?id=<tenantPlanId>` | `200 {html}` |
| 3 | GET `/billing/billing/billing-details?id=<tenantPlanId>` | `200 {html}` / `500` (DEV-001) |
| 4 | GET `/billing/module-details?id=<tenantPlanId>&type=subscription` | `200 {html}` — modules from `TenantPlanModule` |
| 5 | GET `/billing/module-details?id=<invoiceId>&type=invoice` | `200 {html}` — modules from `BillOrgInvoicingModulesJnt` |

### MTC-09 — Invalid detail id
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/billing/subscription-details?id=999999999` | `404` (findOrFail) — never `200` with data |

### MTC-10 — PDF/ZIP export
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/billing/subscription` with no `ids` | `400 {error:'No IDs provided'}` |
| 2 | POST `/billing/subscription` with `ids[]=<rateId>` | ZIP stream (`application/zip`); each id logs `Store` |

### MTC-11 — XSS on filters
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `...&status="><script>window.x=1</script>` | Script does NOT execute; value escaped |
| 2 | Visit `...&date_range="><img src=x onerror=...>` | No execution |

### MTC-12 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies, visit `/billing/billing-management` | Redirect to `/login` |

### MTC-13 — Sub Status display (DEV-BIL-SUB-002)
| Step | Action | Expected Result (current) |
|------|--------|---------------------------|
| 1 | View an ACTIVE plan row's "Sub Status" cell | Shows **Deactive** (bug: `'ACTIVE' == 1` is false) |
| Expected (intended) | | Should show "Active" |
