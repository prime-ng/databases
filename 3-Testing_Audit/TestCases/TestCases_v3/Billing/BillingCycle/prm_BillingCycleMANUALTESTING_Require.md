# Billing Cycle — Manual Testing Specification (`prm_BillingCycleMANUALTESTING_Require.md`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (`BIL`) |
| Feature / Screen | Billing Cycle |
| DB scope | **PRIME / CENTRAL** (`prime_db`) — runs on `http://127.0.0.1:8000` (NOT `test.localhost`) |
| Index URL | `/billing/billing-cycle` |
| Create URL | `/billing/billing-cycle/create` |
| Trash URL | `/billing/billing-cycle/trash/view` |
| Edit URL | `/billing/billing-cycle/{id}/edit` |
| Restore URL | `/billing/billing-cycle/{id}/restore` (GET) |
| Force-delete URL | `/billing/billing-cycle/{id}/force-delete` (DELETE) |
| Toggle URL | `/billing/billing-cycle/{id}/toggle-status` (POST, JSON) |
| Route name prefix | `central.billing.billing-cycle.*` |
| Controller | `BillingCycleController` |
| Model(s) | `BillingCycle` (`prm_billing_cycles`), relations → `Plan`, `TenantPlanRate`, `TenantPlanBillingSchedule`, `TenantInvoice` |
| Validation | `BillingCycleRequest` (`authorize()` returns `true`) |
| Migrations | **NONE** for prime layer — schema comes from `Billing_DDL_v1.sql` / `prime_db_v4.sql` |
| CRUD type | Full-page forms (create/edit pages, not modal); SweetAlert2 confirm for edit/delete/restore/force-delete |
| Soft delete | Model uses `SoftDeletes` — **but DDL has no `deleted_at` (MIG-BIL-001)** |
| Pagination | 20/page (index), 10/page (trash) |
| Activity log | `activityLog()` helper — events `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted` |
| Auth | Central Super-Admin. Spatie/super-admin `Gate::before` resolves dotted abilities. |

### Environment prerequisites
- `Billing` module **must be enabled** in `prime_testing/modules_statuses.json` (else all routes 404).
- `APP_ENV=testing` for Dusk (CSRF bypass) — set by runners.
- Central server reachable at `http://127.0.0.1:8000`; admin `DUSK_ADMIN_EMAIL` / `DUSK_ADMIN_PASSWORD`.
- `prm_billing_cycles` present with a valid `deleted_at` column for soft-delete flows (see MIG-BIL-001).

---

## 2. Business Conditions (detailed)

### Create / Update
- Fields: `short_name` (req, ≤50, unique), `name` (req, ≤50), `months_count` (req, int 1–255), `description` (opt, ≤255), `is_recurring` (checkbox, default checked), `is_active` (switch, default active).
- `prepareForValidation` converts checkboxes: value `on` → `true`, absent → `false`; `months_count` cast to int.
- On success both `store()` and `update()` **redirect to `central.prime.sales-plan-mgmt.index` with `#billing` anchor** (not the billing-cycle index) and a green success flash.
- Default validation messages (no custom `messages()`):
  - `The short name field is required.`
  - `The name field is required.`
  - `The months count field is required.`
  - `The short name field must not be greater than 50 characters.`
  - `The short name has already been taken.`
  - `The months count field must be at least 1.`
  - `The months count field must not be greater than 255.`

### Delete / Restore / Force-delete flow
```
Active ──toggle──▶ Inactive ──toggle──▶ Active
Active ──destroy──▶ (is_active=false) ──▶ Trashed(deleted_at set) ──restore──▶ Active
Trashed ──forceDelete──▶ Permanently removed
Trashed(referenced by FK) ──forceDelete──▶ BLOCKED (ON DELETE RESTRICT) → error flash 'operation_failed.billing_cycle'
```

### Toggle status (AJAX)
- `POST /billing/billing-cycle/{id}/toggle-status` with `is_active` boolean.
- Returns JSON `{ "success": true, "is_active": <bool>, "message": "<flash>" }`.

### Known defects
- **MIG-BIL-001 (P0):** model SoftDeletes+timestamps vs DDL without `deleted_at`/`created_at`/`updated_at` → SQLSTATE 42S22 on a schema-correct DB. Manual testers running against a raw DDL build must add the columns first.
- **DEV-BIL-020 (P2):** force-delete authorizes `prime.billing-cycle.delete`, not `prime.billing-cycle.forceDelete`. A user granted delete-but-not-forceDelete can still force-delete.

---

## 3. Test Cases (step-by-step)

### TC-P04 — Create billing cycle (happy path)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as central admin; visit `/billing/billing-cycle/create` | Create form renders with `#short_name`,`#name`,`#months_count`,`#description`,`#is_recurring`, status switch |
| 2 | Fill short_name=`BC<rand>`, name=`Monthly`, months_count=`1`, description=`Test`, leave recurring checked, active on | — |
| 3 | Press **Add Billing Cycle** | Redirect to sales-plan-mgmt `#billing`; green success flash |
| 4 | DB check | `SELECT * FROM prm_billing_cycles WHERE short_name='BC<rand>'` → 1 row, `months_count=1`, `is_active=1`, `is_recurring=1` |
| 5 | Activity log | `Stored` event recorded for the cycle |

### TC-N01 — Required field validation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit create page, press **Add Billing Cycle** with all fields empty | Stays on `/billing/billing-cycle/create` |
| 2 | Observe | `.alert.alert-danger` shows a `<ul><li>` list including "The short name field is required.", "The name field is required.", "The months count field is required." |
| 3 | DB check | No new row inserted |

### TC-N10 — Duplicate short_name
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a cycle with short_name=`DUP1` | Row exists |
| 2 | Create another with short_name=`DUP1` | Stays on create page, `.alert-danger` "The short name has already been taken." |
| 3 | DB check | `SELECT COUNT(*) WHERE short_name='DUP1'` = 1 |

### TC-P06 / TC-P07 — Update (incl. unique ignore-self)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | From index, click edit action for a cycle → confirm SweetAlert | Navigates to `/billing/billing-cycle/{id}/edit`, `#short_name` prefilled |
| 2 | Keep the same short_name, change name, submit **Update Billing Cycle** | Update succeeds (unique rule ignores self); redirect + flash |
| 3 | Change short_name + months_count, submit | Values persisted; DB reflects new values |

### TC-P09 — Toggle status
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed active cycle; visit index | `#statusSwitch-{id}` present, checked |
| 2 | Click `#statusSwitch-{id}` | AJAX POST; JSON `{success:true,is_active:false,...}` |
| 3 | DB check | `is_active=0` |

### TC-D04 / TC-P10 / TC-P11 — Soft delete → restore → force delete
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Index → delete action → confirm SweetAlert | `deleted_at` set, `is_active=0` |
| 2 | Visit trash `/billing/billing-cycle/trash/view` | Deleted cycle listed |
| 3 | Click restore → confirm | `deleted_at` null, cycle back on index |
| 4 | Delete again → trash → force-delete → confirm | Row permanently removed (`withTrashed()` finds nothing) |

### TC-D03 — Force delete blocked while referenced
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create cycle; insert a `prm_plans` row with `billing_cycle_id=<cycle>` | FK reference exists |
| 2 | Soft delete cycle; attempt force delete | Blocked by ON DELETE RESTRICT → error flash `operation_failed.billing_cycle`; row still present |

### TC-N11 — Invalid id
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/billing/billing-cycle/98765432/edit` | 404 / Not Found (route-model binding `findOrFail`) |
| 2 | Visit `/billing/billing-cycle/98765432` | 404 / Not Found |

### TC-N12 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies; visit `/billing/billing-cycle` | Redirect to `/login` |

### TC-N13 — Stored XSS escaping
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed cycle with name=`<script>alert("bcxss")</script>` | — |
| 2 | View show/index | Page source does NOT contain the raw script node (Blade `{{ }}` escaped) |

### TC-AUTH03 / DEV-BIL-020 — Force-delete permission mismatch
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `BillingCycleController::forceDelete()` | Authorizes `prime.billing-cycle.delete` (NOT `.forceDelete`) |
| 2 | Inspect `BillingCyclePolicy::forceDelete()` | Maps `prime.billing-cycle.forceDelete` |
| 3 | Conclusion | Mismatch: a user with delete-but-not-forceDelete can force-delete — **DEV-BIL-020** |
