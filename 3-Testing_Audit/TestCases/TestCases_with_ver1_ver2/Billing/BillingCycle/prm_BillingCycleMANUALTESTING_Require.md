# Billing Cycle — Manual Testing Specification (`prm_BillingCycleMANUALTESTING_Require`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (central / prime_db) |
| Feature | BillingCycle |
| Base URL | `http://127.0.0.1:8000/billing/billing-cycle` |
| Index | `GET /billing/billing-cycle` |
| Create | `GET /billing/billing-cycle/create` · `POST /billing/billing-cycle` |
| Show | `GET /billing/billing-cycle/{billingCycle}` |
| Edit | `GET /billing/billing-cycle/{billingCycle}/edit` · `PUT /billing/billing-cycle/{billingCycle}` |
| Delete (soft) | `DELETE /billing/billing-cycle/{billingCycle}` |
| Trash | `GET /billing/billing-cycle/trash/view` |
| Restore | `GET /billing/billing-cycle/{id}/restore` |
| Force delete | `DELETE /billing/billing-cycle/{id}/force-delete` |
| Toggle status | `POST /billing/billing-cycle/{billingCycle}/toggle-status` (AJAX JSON) |
| Controller | `Modules\Billing\Http\Controllers\BillingCycleController` |
| FormRequest | `Modules\Billing\Http\Requests\BillingCycleRequest` |
| Model | `Modules\Billing\Models\BillingCycle` (table `prm_billing_cycles`) |
| Validation | short_name req/≤50/unique · name req/≤50 · months_count req/int/1–255 · description ≤255 · is_active req bool · is_recurring bool |
| Migrations | **None** — table lives in DDL only (`Billing_DDL_v1.sql`); **MIG-BIL-001 (P0)** no `deleted_at`/timestamps in DDL |
| CRUD Type | Full page-based CRUD (create/edit are dedicated pages, not modals) |
| Soft Delete | Yes (model); destroy sets `is_active=false` first |
| Pagination | Index 20/page; trash 10/page (Laravel default links) |
| Activity Log | `sys_activity_logs` — events `Stored`/`Updated`/`Trashed`/`Restored`/`Deleted` (toggle logs nothing) |
| Auth | `auth` + `verified` + `Gate::authorize('prime.billing-cycle.*')`; super-admin `Gate::before` bypass |

**Prerequisites**
- Billing module **enabled** in `prime_testing/modules_statuses.json` (disabled → 404 on all routes).
- `APP_ENV=testing` (CSRF bypass for AJAX/state-changing requests; else 419).
- Central admin (`root@tenant.com` / super-admin) available on `http://127.0.0.1:8000`.
- Dev DB `prm_billing_cycles` hand-patched with `deleted_at` (MIG-BIL-001 workaround).

---

## 2. Business Conditions (detailed)

**Unique short_name (BC-VAL-01)** — `short_name` unique across ALL rows including soft-deleted (rule `Rule::unique('prm_billing_cycles','short_name')->ignore($id)`). Error surfaces in the top `.alert.alert-danger` list; user stays on the create/edit page.

**Cycle length (BC-VAL-03 / BC-EDG-01)** — `months_count` integer 1–255. Standard: MONTHLY=1, QUARTERLY=3, YEARLY=12. Column is TINYINT UNSIGNED (DB hard ceiling 255).

**Soft delete flow (BC-BIZ-03)** —
```
destroy → is_active = false → delete() (deleted_at set) → activityLog 'Trashed' → redirect sales-plan-mgmt#billing (flash: "Billing Cycle was moved to trash.")
```

**Force delete guard (BC-BIZ-05 / BC-REF)** —
```
forceDelete → try { permanent delete → activityLog 'Deleted' } catch { flash error "Failed to perform the operation on Billing Cycle." }
FK RESTRICT from prm_plans / prm_tenant_plan_rates / prm_tenant_plan_billing_schedule / bil_tenant_invoices blocks removal while referenced.
```

**Status toggle (BC-SM / BC-BIZ-06)** —
```
click #statusSwitch-{id} → AJAX POST toggle-status {is_active} → JSON {success:true, is_active, message:"Billing Cycle status was successfully changed."}
```

**Known defects:** MIG-BIL-001 (P0 schema/model mismatch); DEV-BIL-201 (forceDelete gate key drift); DEV-BIL-202 (store/update redirect to sales-plan-mgmt, not the cycle index).

---

## 3. Manual Test Cases

### TC-P05 — Create billing cycle (happy path)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as super-admin; visit `/billing/billing-cycle/create` | Create form renders (short_name, name, months_count, description, is_recurring, is_active) |
| 2 | Enter short_name `MONTHLY_T1`, name `Monthly`, months_count `1`, description `Monthly cycle` | Fields accept input |
| 3 | Leave "Recurring Billing" checked; ensure Active switch on | Both on |
| 4 | Press **Add Billing Cycle** | Redirect to `…/sales-plan-mgmt#billing`; success toast "Billing Cycle was created successfully." |
| 5 | DB check | `SELECT * FROM prm_billing_cycles WHERE short_name='MONTHLY_T1'` → 1 row, months_count=1, is_active=1, is_recurring=1 |
| 6 | Activity log | `SELECT * FROM sys_activity_logs WHERE event='Stored' AND subject_id={id}` → 1 row |

### TC-N01 — Required fields

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit create page, press **Add Billing Cycle** with all fields empty | Stays on `/billing/billing-cycle/create` |
| 2 | Observe errors | `.alert.alert-danger` with `<li>` items for short_name / name / months_count |
| 3 | DB check | No new row inserted |

### TC-N04 — Duplicate short_name

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a cycle with short_name `DUP1` | Row exists |
| 2 | Create another with short_name `DUP1` | Validation alert; stays on create page |
| 3 | DB check | `SELECT COUNT(*) … WHERE short_name='DUP1'` = 1 |

### TC-N05 / TC-N06 — months_count range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create with months_count `0` | Alert (min:1); no row |
| 2 | Create with months_count `256` | Alert (max:255); no row |
| 3 | Create with months_count `1` then `255` | Both persist (boundary OK) |

### TC-N07/08/09 — Length limits

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | short_name = 51 chars | Alert (max:50); no row |
| 2 | name = 51 chars | Alert (max:50); no row |
| 3 | description = 256 chars | Alert (max:255); no row |

### TC-P06 — Update

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On index, click the pencil (edit) action | SweetAlert confirm appears |
| 2 | Confirm | Navigates to `…/{id}/edit`; form pre-filled |
| 3 | Change name/months_count/description; press **Update Billing Cycle** | Redirect sales-plan-mgmt#billing; toast "…updated successfully." |
| 4 | DB check | Row reflects new values |
| 5 | Activity log | `event='Updated'` row for subject_id |

### TC-P09 — Update keeps same short_name

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Edit a cycle, keep the same short_name, change only name | Update succeeds (unique ignores self) |
| 2 | DB check | short_name unchanged, name updated |

### TC-SM01/02/03 — Status toggle

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On index, click `#statusSwitch-{id}` of an active cycle | AJAX fires |
| 2 | DB check | `is_active` flips to 0 |
| 3 | Click again | `is_active` flips to 1 |
| 4 | Inspect XHR response | JSON `{success:true, is_active:<bool>, message:"Billing Cycle status was successfully changed."}` |
| 5 | POST toggle-status with no `is_active` | HTTP 422 validation error |

### TC-P07 / TC-D01 — Delete → Restore → Force delete lifecycle

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On index, click the trash (delete) button | SweetAlert confirm |
| 2 | Confirm | Redirect; toast "…moved to trash." |
| 3 | DB check | `deleted_at` NOT NULL, `is_active`=0 |
| 4 | Visit `/billing/billing-cycle/trash/view` | Deleted cycle listed |
| 5 | Click restore (recycle) → confirm | Toast "…restored successfully."; `deleted_at` NULL |
| 6 | Delete again, go to trash, click force-delete (eraser) → confirm | Row permanently removed |
| 7 | DB check | `SELECT … withTrashed WHERE id={id}` → 0 rows |

### TC-D02 — Force delete blocked while referenced

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure a `prm_plans` / `prm_tenant_plan_rates` row references the cycle | FK present |
| 2 | Soft-delete the cycle, then force-delete from trash | try/catch catches FK RESTRICT → error flash "Failed to perform the operation on Billing Cycle." |
| 3 | DB check | Cycle row still exists (force delete blocked) |

### TC-D04 — Soft-deleted short_name reserved

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create + soft-delete a cycle with short_name `RSVD1` | Row trashed |
| 2 | Create a new cycle with short_name `RSVD1` | Validation alert (still unique-blocked); stays on create page |

### TC-N10/11/12 — Authorization

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Logout; visit `/billing/billing-cycle` | Redirect to `/login` |
| 2 | Logout; visit `/billing/billing-cycle/create` | Redirect to `/login` |
| 3 | Login as a non super-admin without `prime.billing-cycle.viewAny` | 403 Forbidden (or redirect) |

### TC-S01 — XSS in name

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a cycle with name `<script>alert("bcx")</script>` | Row stored verbatim |
| 2 | Open index | Name rendered escaped; raw `<script>` NOT present in DOM source; no alert dialog |

### TC-S02 — IDOR / direct edit URL

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Logout; visit `/billing/billing-cycle/{validId}/edit` directly | Redirect to `/login` (auth enforced) |

### DEV-BIL-201 / DEV-BIL-202 (documented, not auto-failed)

| Item | Manual check |
|------|--------------|
| DEV-BIL-201 | Grant a user `prime.billing-cycle.delete` but NOT `.forceDelete`; force-delete still authorized (controller gates on `.delete`), diverging from Policy `forceDelete`. |
| DEV-BIL-202 | After create/update, the app redirects to `sales-plan-mgmt#billing`, not to `/billing/billing-cycle`; success toast shows on the sales-plan-mgmt screen. |
