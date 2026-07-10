# SessionBoardSetup — Manual Testing Guide (glb_)

- **Screen:** Session & Board Setup (READ-ONLY composite of two lists)
- **URL:** `http://127.0.0.1:8000/prime/session-board-setup`
- **Access:** log in as a CENTRAL super-admin (default `root@tenant.com` / `password`).
- **Prereq:** GlobalMaster **and** Prime modules enabled (`modules_statuses.json`); `APP_ENV=testing`; central app served on `127.0.0.1:8000`.

> This screen only **reads** `glb_academic_sessions` and `glb_boards`. There is no create/edit/delete on this screen (write methods are non-functional stubs — DEV-GLB-S01). To create/edit sessions or boards use their dedicated management screens (out of scope here).

---

## MT-01 — Guest is redirected to login
1. Open a private window (no session). Visit `/prime/session-board-setup`.
2. **Expected:** redirected to `/login`.

## MT-02 — Index renders both lists
1. Log in as super-admin, visit the screen.
2. **Expected:** breadcrumb **"Session & Board Setup"**; two tabs — **Academic Session** and **Academic Board**; each tab shows a table.

## MT-03 — Academic Session list content
1. On the **Academic Session** tab.
2. **Expected:** columns Session / Short Name / Start Date / End Date (+ Action if permitted). The current session shows an "Active" badge. Sessions ordered by newest start date first.

## MT-04 — Academic Board list content
1. Switch to the **Academic Board** tab.
2. **Expected:** columns Name / Short Name / Status (if `prime.board.update`) / Action. Boards ordered by name.

## MT-05 — Search filters a list
1. In a tab's search box type part of a name or short name; submit.
2. **Expected:** the list narrows to matching rows (LIKE on `name`/`short_name`). The other tab reflects the same `search` term.

## MT-06 — Status filter (boards)
1. On the **Academic Board** tab set Status = Active (1) / Inactive (0); submit.
2. **Expected:** boards filtered by `is_active`.

## MT-07 — Status filter (sessions) — KNOWN DEFECT (DEV-GLB-S03)
1. On the **Academic Session** tab set Status = Active/Inactive; submit.
2. **Expected per code:** the controller filters `AcademicSession::where('is_active', ...)`, but `glb_academic_sessions` has **no `is_active` column** (only `is_current`).
3. **Observed:** the filter targets a non-existent column — either a DB error or a no-op. Record the actual behaviour. (Session status should use `is_current`.)

## MT-08 — Sessions pagination (page size 10)
1. If more than 10 sessions exist, confirm the Academic Session list shows 10 rows and a pager.
2. **Expected:** pager uses the `academicsession_page` query parameter and the `#academicsession` fragment; navigating pages keeps `search`/`status`.

## MT-09 — Boards pagination (page size 4)
1. If more than 4 boards exist, confirm the Academic Board list shows 4 rows and a pager.
2. **Expected:** pager uses `academicboard_page` and the `#academicboard` fragment.

## MT-10 — Empty states
1. With an empty sessions list: **"No Academic Session Data Found"**.
2. With an empty boards list: **"No Board Data Found"**.

## MT-11 — Permission gating
1. Log in as a user **without** `prime.session-board-setup.viewAny`.
2. **Expected:** 403 / access denied at `/prime/session-board-setup`.
3. A user with only `prime.board.viewAny` (not `prime.academic-session.viewAny`) should see only the Academic Board tab/pane.

## MT-12 — Business rules (cross-reference, NOT set on this screen)
- Only **one** academic session may be current (`current_flag` UNIQUE).
- `start_date < end_date`; new ranges must not overlap existing (trigger-based, not DB-enforced).
- Board `name` and `short_name` are unique.
- These are enforced on the Academic Session / Board **management** screens; this screen only displays the results.

---

### Sign-off checklist
- [ ] MT-01 guest redirect
- [ ] MT-02 both lists render
- [ ] MT-03 session columns/order/badge
- [ ] MT-04 board columns/order
- [ ] MT-05 search
- [ ] MT-06 board status filter
- [ ] MT-07 session status filter (defect recorded)
- [ ] MT-08 sessions pagination
- [ ] MT-09 boards pagination
- [ ] MT-10 empty states
- [ ] MT-11 permission gating
- [ ] MT-12 business rules cross-referenced
