# Dropdown — Manual Testing Guide (`sys_`)

- **Module:** GlobalMaster (GLB) → **Prime / Central** (`prime_db`)
- **Screen:** Global Master → Dropdown (multi-tab: dropdown-need / dropdown-list / create-dropdown-jnt)
- **URL:** `http://127.0.0.1:8000/global-master/dropdown`
- **Primary table:** `sys_dropdown_table` (prefix **`sys_`**, NOT `glb_` — central/prime DB)
- **Live controller:** `Modules\Prime\Http\Controllers\DropdownController` (view `prime::index`)

> **Reconciliation:** the on-disk route file `Modules/GlobalMaster/routes/web.php` still references the GlobalMaster module's OWN `DropdownController`, but per the digested truth the live central screen is served by the Prime multi-tab controller. GlobalMaster's own controller/request path is DEAD and carries defects DEV-GLB-D01..D03. Test against the live Prime screen.

## Preconditions
1. GlobalMaster **and** Prime enabled in `modules_statuses.json`.
2. `APP_ENV=testing`; central app served at `http://127.0.0.1:8000`.
3. Logged in as a super-admin (`is_super_admin=1`) or `DUSK_ADMIN_EMAIL`.
4. At least one `sys_dropdown_needs` row exists (create/store require a `dropdown_need_id`); junction table `sys_dropdown_need_table_jnt` / `sys_dropdown_need_dropdowns_jnt` present.

---

## A. Positive flows

| # | Step | Expected |
|---|------|----------|
| A1 | Visit `/global-master/dropdown` | Tabbed screen renders (dropdown-need / dropdown-list / create-dropdown-jnt); no 403/404 |
| A2 | Open the **Dropdown List** tab | Rows grouped by `key`, paginated 10 per page |
| A3 | Select a dropdown need, open the create form | `key` is suggested as `table_name.column_name`; type defaults to `String` |
| A4 | Create a dropdown: key `demo.key`, value `Alpha`, type `String`, active | Saved; redirect to index with "Dropdown saved successfully!"; a junction row is created; `ordinal` = previous max + 1 |
| A5 | Add a second value under the same key | New row gets the next `ordinal`; UNIQUE(key,value) enforced |
| A6 | Toggle a dropdown's status switch | JSON `{success:true, is_active, message}`; row + junction `is_active` flip together |
| A7 | Edit a dropdown value | Updated; junction re-mapped if the need changed |
| A8 | Soft-delete (trash) a dropdown | Row hidden from active list; junction deactivated; activity event `Trashed` |
| A9 | Restore from trash | Row active again; junction reactivated; activity event `Restored` |
| A10 | Force-delete from trash | Junction removed first, then the row permanently; gone from `withTrashed` |

## B. Negative / validation (live Prime store)

| # | Step | Expected |
|---|------|----------|
| B1 | Submit create with empty `key` | Rejected — `key` required |
| B2 | `key` longer than 160 chars | Rejected — `max:160` |
| B3 | Duplicate `key` | Rejected — `unique:sys_dropdown_table,key` |
| B4 | Empty `value` | Rejected — `value` required |
| B5 | `value` 101–255 chars | **DEV-GLB-D03:** the GlobalMaster request path (max:255) would pass then error at the DB `VARCHAR(100)`; the live Prime store (max:100) rejects it. Expect rejection on the live screen |
| B6 | `type` = `Text` (not in enum) | Rejected — `in:String,Integer,Decimal,Date,Datetime,Time,Boolean` |
| B7 | Create without selecting a dropdown need | Redirect back / to dropdown-need index with "Please select a dropdown need first" |
| B8 | Whitespace-only `value` (`"   "`) | Passes `required` (no trim); UNIQUE(key,value) still applies — documented behaviour |
| B9 | Open edit for a non-existent id | 404 (findOrFail) |
| B10 | Enter `<script>alert(1)</script>` as a value | Stored raw at rest; escaped on output (no script execution) |

## C. Permissions

| # | Step | Expected |
|---|------|----------|
| C1 | Log out, visit `/global-master/dropdown` | Redirect to `/login` |
| C2 | Guest POST to the store endpoint | Rejected (401/403/302/419) |
| C3 | Verify gates | `prime.dropdown.viewAny/view/create/update/delete/restore/forceDelete` defined; `toggleStatus` uses `prime.dropdown.update`; map/bulk use `prime.dropdown-need.update` |

## D. GLB/SYS source defects to verify (in source)

| # | Defect | How to verify |
|---|--------|---------------|
| D1 | **DEV-GLB-D01** orphaned duplicate model | Confirm two classes named `Modules\GlobalMaster\Models\Dropdown`: `app/Models/Dropdown.php` (autoloaded, `sys_dropdown_table`, SoftDeletes) and `Models/Dropdown.php` (outside app/, NOT PSR-4-autoloaded, no `$table`→`dropdowns`, fillable incl `org_id`/`dropdown_needs_id`) |
| D2 | **DEV-GLB-D02** broken GlobalMaster store | In `Modules/GlobalMaster/.../DropdownController@store`, it reads `$data['org_id']/$data['key']/$data['type']` but `DropdownRequest::rules()` returns only `value`+`is_active` → undefined-array-key; `org_id` is not fillable → silently dropped |
| D3 | **DEV-GLB-D03** value length mismatch | `DropdownRequest` `value` is `max:255` while `sys_dropdown_table.value` is `VARCHAR(100)`; live Prime store uses `max:100` |
| D4 | **DEV-GLB-D04** SoftDeletes vs DDL | Active model uses `SoftDeletes` but `_prime_db_v4.sql` `sys_dropdown_table` has no `deleted_at`; if the DB column is absent, soft-delete/onlyTrashed/withTrashed/restore/forceDelete throw "unknown column deleted_at" |

## E. Central / tenancy

| # | Step | Expected |
|---|------|----------|
| E1 | Confirm no tenant is initialized while on this screen | Central/prime context only; host is 127.0.0.1:8000 |
