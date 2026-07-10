# Country (GlobalMaster / CENTRAL) — Manual Testing Guide

- **Feature**: Country — GlobalMaster module, prime-side (CENTRAL)
- **Base URL**: `http://127.0.0.1:8000`
- **Entry point**: `/global-master/country` (Location Setup → Country tab, `#country`)
- **Generated**: 2026-07-10

## Environment prerequisites (do these first)

1. In `prime_testing/modules_statuses.json`, set **both** `"GlobalMaster": true` and
   `"Prime": true`. If either is `false`, every `/global-master/country` route returns **404**.
2. `APP_ENV=testing` (bypasses CSRF for the toggle-status AJAX call).
3. Central dev server running on `http://127.0.0.1:8000`.
4. `global_master_mysql` connection reachable and migrated; `glb_countries.deleted_at` present.
5. Log in as a super-admin (default `root@tenant.com` / `password`).

## Legend
- **Pre** = precondition, **Steps** = actions, **Expected** = pass criteria.
- Defects to watch flagged as `DEV-GLB-C0x`.

---

## MT-01 — View country list
- **Pre**: At least 1 country exists.
- **Steps**: Visit `/global-master/country`.
- **Expected**: "Countries" card renders a table with columns Country, Short Name, Global Code,
  Currency, Status, Action. Active countries appear first. Pagination shows max 10 rows/page.

## MT-02 — Create a country (happy path)
- **Steps**: `Add New Countries` → fill Name, Short Name, Global Code, Currency Code, tick Status →
  press **Add Country**.
- **Expected**: Redirect to Location Setup `#country` with a green success flash. New row visible.
  An activity-log row with event **Stored** exists in `sys_central_activity_logs`.

## MT-03 — Required-field validation
- **Steps**: Open create form, submit empty.
- **Expected**: Stay on create page; red `.alert.alert-danger` lists "name" and "short name" errors.

## MT-04 — Field length limits
- **Steps**: Enter Name > 50, Short Name > 10, Global Code > 10, Currency Code > 8 (one at a time).
- **Expected**: Each is rejected with a validation error; user stays on the create page.

## MT-05 — Duplicate name rejected
- **Steps**: Create a country, then try to create a second with the **same Name**.
- **Expected**: Friendly validation error ("name has already been taken"); no second row.

## MT-06 — Duplicate short_name (DEV-GLB-C01) ⚠️
- **Steps**: Create country A with short_name "US". Create country B with a new name but short_name "US".
- **Expected (current, defective)**: **NO friendly validation error** — the DB `UNIQUE` key fires and
  the app throws a raw `QueryException` (HTTP 500 / dev error page). `CountryRequest` does not validate
  short_name uniqueness. **This is DEV-GLB-C01.** Same class of bug applies to `global_code` (DDL unique).

## MT-07 — Edit a country
- **Steps**: On the list, click the edit (pencil) action → confirm SweetAlert → change Name → **Update Country**.
- **Expected**: Redirect to `#country` with success flash; the change persists; an **Updated** activity
  event is recorded (with `performed_by`).

## MT-08 — View details
- **Steps**: Click the eye action.
- **Expected**: "Country Details" table shows ID, Name, Short Name, Global Code, Currency Code, Status badge.

## MT-09 — Toggle status + cascade (DEV-GLB-C03) ⚠️
- **Pre**: A country that has child states and districts.
- **Steps**: Toggle the `#statusSwitch-{id}` switch to inactive.
- **Expected**: JSON `{success:true, is_active:false}`; the country **and all its child states and
  districts** flip to inactive (DB transaction cascade). **Note the defect**: only the **country** gets a
  `Toggled` activity-log entry — the cascaded child changes are **not** logged. **This is DEV-GLB-C03.**

## MT-10 — Soft-delete (trash)
- **Steps**: Click the delete (trash) action → confirm SweetAlert.
- **Expected**: Country disappears from the list, `deleted_at` set, `is_active` forced to 0,
  a **Trashed** activity event recorded.

## MT-11 — Trash view + restore
- **Steps**: Visit `/global-master/country/trash/view`; find the trashed country; click restore → confirm.
- **Expected**: Country returns to the active list; `deleted_at` cleared; **Restored** event recorded.
  Any previously soft-deleted child states are **not** resurrected.

## MT-12 — Force delete
- **Pre**: Country in trash **with no child states** (see MT-13 for the RESTRICT case).
- **Steps**: In trash view, click force-delete → confirm.
- **Expected**: Row permanently removed; **Deleted** event recorded; redirect to trash view.

## MT-13 — FK RESTRICT on force delete
- **Pre**: A country that still has at least one child state row in `glb_states`.
- **Steps**: Attempt to force-delete that country.
- **Expected**: The delete is **blocked** by the `glb_states.country_id` FK (RESTRICT); the country row
  survives. (Soft delete is unaffected because it never removes the DB row.)

## MT-14 — default_timezone dead rule (DEV-GLB-C02) ℹ️
- **Observation**: `CountryRequest` validates `default_timezone` (max:64), but `glb_countries` has no such
  column and it is not fillable. Any submitted value is silently discarded. **This is DEV-GLB-C02 (minor).**

## MT-15 — Permissions
- **Steps**: Log in as a user without `prime.country.*` permissions; visit `/global-master/country`.
- **Expected**: 403 Forbidden. When a limited user has view-only rights, the Status column and edit/delete
  action buttons are hidden (`@can`/`@canany` guards in the view).

## MT-16 — Guest access
- **Steps**: Log out; visit `/global-master/country`.
- **Expected**: Redirect to `/login`. The `toggle-status` JSON endpoint returns 401/302 for guests.

## MT-17 — XSS safety
- **Steps**: Enter `<script>alert('x')</script>` in Name; save (if it passes length) then view list/detail.
- **Expected**: The payload is HTML-escaped on render (Blade `{{ }}`) and never executes. Reflected
  `old()` values on validation errors are also escaped.

## MT-18 — Pagination
- **Pre**: > 10 countries.
- **Steps**: Observe the list.
- **Expected**: Max 10 data rows per page; pagination links present and navigable.

---

## Defect summary (verify in source)

| ID | Severity | Summary |
| --- | --- | --- |
| DEV-GLB-C01 | High | Duplicate `short_name`/`global_code` bypass validation → raw `QueryException` (500) instead of friendly error. |
| DEV-GLB-C02 | Minor | `default_timezone` validated but no column / not fillable → dead rule. |
| DEV-GLB-C03 | Medium | `toggleStatus` cascades `is_active` to child states/districts but only logs `Toggled` for the country. |
