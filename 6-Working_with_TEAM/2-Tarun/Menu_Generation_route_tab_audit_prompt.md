# Route & Tab Inventory Audit — Prime-AI

**Objective:** Produce an Excel file that maps every multi-tab (combined view) route in the system to its menu name, route name, URL, tab count, tab titles, and any loose ends.

---

## Step 1 — Understand the menu system

Read these two files first:

1. `/home/tarun-chauhan/Desktop/Apps/prime_ai/Modules/SystemConfig/app/Http/Controllers/MenuSyncController.php` — extract the full menu tree: every menu item's `name`, `route_name`, `url`, `icon`, and `parent`.
2. `/home/tarun-chauhan/Desktop/Apps/Prime_context/files/menu_tab_audit.xlsx` — read all sheets/columns to understand the existing audit structure so the output file matches or extends it.

---

## Step 2 — Collect all routes

Read these two route files in full:
- `/home/tarun-chauhan/Desktop/Apps/prime_ai/routes/web.php`
- `/home/tarun-chauhan/Desktop/Apps/prime_ai/routes/tenant.php`

For each `Route::get/post/put/patch/delete` entry, record:
- HTTP method
- URI pattern
- Route name (`.name(...)`)
- Controller class + method

Then read every module's own route file. The modules live at:
`/home/tarun-chauhan/Desktop/Apps/prime_ai/Modules/*/routes/web.php`

Glob that pattern and read every file found.

---

## Step 3 — Identify combined/tabbed views

For **every controller method** referenced in the routes above, read the controller file and determine whether the method:

**A) Loads a combined/tabbed view** — defined as any of:
- The Blade view rendered by `view(...)` contains Bootstrap tab markup (`nav-tabs`, `tab-pane`, `data-bs-toggle="tab"`, `data-toggle="tab"`)
- OR the controller method passes **3 or more distinct model/query results** to `compact()` or `view()->with()`
- OR the method name contains keywords: `index`, `dashboard`, `overview`, `combined`, `summary`

**B) Has loose ends** — defined as:
- Controller method exists but returns an empty view or `return view(...)` with no data
- Route defined but controller method does not exist (undefined method)
- View file referenced does not exist on disk
- Tab section in view is present but has no content or just `<!-- TODO -->`

---

## Step 4 — Read Blade views for tab titles

For each controller method identified in Step 3A, find the Blade view file it renders. The view namespace follows nwidart module convention:

`'modulename::folder.file'` → `Modules/{ModuleName}/resources/views/folder/file.blade.php`

Read the view and extract:
- Every tab's **display title** (text inside `<button class="nav-link"` or `<a class="nav-link"` or `<li class="nav-item"`)
- Tab count

---

## Step 5 — Build the Excel output

Write the results to:
`databases/6-Working_with_TEAM/2-Tarun/route_tab_audit_output.xlsx`

### Sheet 1: Tab Routes — one row per tabbed route

| Module | Menu Name | Route Name | HTTP Method | URL Pattern | Controller::Method | View File | Tab Count | Tab Titles (pipe-separated) | Data Variables Passed | Notes |
|--------|-----------|------------|-------------|-------------|-------------------|-----------|-----------|-----------------------------|-----------------------|-------|

### Sheet 2: Loose Ends — one row per issue found

| Module | Route Name | URL | Controller::Method | Issue Type | Detail |
|--------|------------|-----|--------------------|------------|--------|

Issue types: `MISSING_CONTROLLER_METHOD`, `MISSING_VIEW_FILE`, `EMPTY_VIEW`, `ROUTE_NO_NAME`, `TAB_NO_CONTENT`

### Sheet 3: All Routes — complete flat list of every route (for reference)

| Module | Route Name | HTTP Method | URL | Controller::Method | Is Tabbed? |
|--------|------------|-------------|-----|--------------------|------------|

---

## Constraints

- Use `openpyxl` (Python) or `PhpSpreadsheet` to write the Excel file — whichever is available via `python3 -c "import openpyxl"` or `composer show | grep spreadsheet`.
- If neither is available, write a `.csv` per sheet instead and note it.
- Do not modify any application code — read-only audit.
- If a module folder has no `routes/web.php`, skip it and note the module name in Sheet 2 with issue type `NO_ROUTE_FILE`.
- Work module by module. After processing each module, append its rows before moving to the next — do not batch everything in memory.

---

## Output confirmation

When done, print a summary:

```
Modules scanned:      N
Routes found:         N
Tabbed routes found:  N
Loose ends found:     N
Output written to:    /path/to/file
```
