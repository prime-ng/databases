# GlobalMaster :: Language — Manual Testing Guide (`glb_`)

- Module: **GlobalMaster** (CENTRAL / prime-side)
- Screen: **Language**
- URL: **http://127.0.0.1:8000/global-master/language**
- Served by: `Modules\Prime\Http\Controllers\LanguageController` (HARD RULE 13)
- Table: `glb_languages` (connection `global_master_mysql`)

---

## Pre-conditions

1. Both **GlobalMaster** and **Prime** modules ENABLED in `modules_statuses.json`
   (if either is `false`, the route 404s).
2. `APP_ENV=testing`, app reachable at `http://127.0.0.1:8000`.
3. Logged in as a super-admin (or a user holding the `prime.language.*` abilities).
4. `glb_languages` migrated (has `code, name, native_name, direction, is_active,
   deleted_at, created_at, updated_at`).

---

## MT-01 — Index page loads
1. Visit `/global-master/language`.
2. **Expect:** "Language Management" heading, a table with columns Language /
   Native Name / Code / Status / Action, and pagination when > 11 rows.

## MT-02 — Create a language (happy path)
1. Click Add / visit `/global-master/language/create`.
2. Fill: Name = `Testish`, Code = `tsh`, Native Name = `Tëstish`,
   Direction = `Left to Right (LTR)`, toggle Status ON.
3. Press **Add Language**.
4. **Expect:** redirect to index with a success flash; the row appears.

## MT-03 — Required field validation
1. On the create page, leave **Code** empty (fill the rest), submit.
2. **Expect:** stay on create page, `.alert.alert-danger` lists the code error.
3. Repeat for empty **Name**.

## MT-04 — Max-length validation
1. Enter a Code of 11+ characters → submit.
2. **Expect:** red validation alert (`max:10`).
3. Enter a Name of 51+ characters → submit → alert (`max:50`).

## MT-05 — Duplicate validation
1. Create a language with Code `dup`.
2. Try to create another with Code `dup`.
3. **Expect:** validation alert; no second row created.
4. Repeat for a duplicate **Name**.

## MT-06 — Direction constraint
1. The Direction select only offers LTR / RTL — both should save.
2. (Adversarial) Using dev-tools, inject a bogus `<option value="XX">` and submit.
3. **Expect:** server rejects with a validation alert (`Rule::in`).

## MT-07 — Native name optional
1. Create a language leaving Native Name blank (bypass the client `required`).
2. **Expect:** saves successfully with an empty native name (server rule is
   `nullable`). *Note the blade adds a client-side `required` that diverges from
   the server's `nullable` rule — minor UI/server mismatch.*

## MT-08 — Edit / update
1. From index, click the Edit action; confirm the SweetAlert.
2. Change Code / Name / Direction; press **Update Language**.
3. **Expect:** redirect to index; values updated. *(Note: the controller flashes
   the literal `'update.language'` rather than a translated success string —
   cosmetic.)*

## MT-09 — Status toggle
1. On index, click the status switch (`#statusSwitch-{id}`).
2. **Expect:** AJAX success; `is_active` flips; an activity entry `Toggled` is
   written to `sys_central_activity_logs`.

## MT-10 — Soft delete → Trash
1. Click Delete; confirm the SweetAlert.
2. **Expect:** row disappears from index, `deleted_at` set, `is_active=false`;
   activity event **`Trashed`** logged with the acting user's id.
3. Visit `/global-master/language/trash/view` → the record is listed.

## MT-11 — Restore
1. In Trash, click Restore; confirm.
2. **Expect:** record returns to the active list, `deleted_at` cleared; activity
   event **`Restored`** logged.

## MT-12 — Force delete (documents DEV-GLB-L02)
1. Soft-delete a record, open Trash, click Force Delete; confirm.
2. **Expect:** record permanently removed from `glb_languages`.
3. **Bug check:** inspect `sys_central_activity_logs` — the logged event is the
   literal **`Stored`** (not `Deleted`). This is **DEV-GLB-L02**.

## MT-13 — Pagination
1. Ensure > 11 active languages exist.
2. **Expect:** first page shows at most 11 rows; a pagination control appears.

## MT-14 — Empty state
1. With no matching rows, the table body shows `Not Data Found`.

## MT-15 — Access control
1. Log out, visit `/global-master/language`.
2. **Expect:** redirect to `/login`.
3. A user lacking `prime.language.viewAny` receives 403.

## MT-16 — XSS safety
1. Create a language with Name `<script>alert(1)</script>`.
2. **Expect:** on index the payload is rendered as escaped text, not executed
   (Blade `{{ }}` auto-escaping).

## MT-17 — Invalid id / IDOR
1. Visit `/global-master/language/999999999/edit`.
2. **Expect:** 404 (Model `findOrFail`), not a 200 page.

---

## Known defects to observe during manual testing

| ID | What to watch |
| --- | --- |
| DEV-GLB-L01 | DDL `_global_db_v4.sql` lacks timestamps/soft-delete columns; the real migration adds them — verify `deleted_at` exists in the DB. |
| DEV-GLB-L02 | Force delete logs `Stored` instead of a delete event (MT-12). |
| DEV-GLB-L03 | The GlobalMaster module's OWN controller (dead on central) mixes `prime.language.*` and `global-master.language.*` gates and flashes literal `update.language`. Only observable if that dead controller is ever wired. |
| DEV-GLB-L04 | Two `LanguageController` classes share the same request + model. |
