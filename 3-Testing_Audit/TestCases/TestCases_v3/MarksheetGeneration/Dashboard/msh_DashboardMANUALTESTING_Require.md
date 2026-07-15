# MarksheetGeneration — Dashboard & Navigation — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | MarksheetGeneration (`MSH`) |
| Feature / Screen | Dashboard & Navigation (composite / read-focused) |
| URL | `/marksheet-generation/dashboard` (+ `/configuration`, `/components`, `/scheduling`, `/results`) |
| Controller | `MarksheetGenerationController@dashboard\|configuration\|components\|scheduling\|results` |
| Primary table | **None** — composite screen; aggregates `msh_*` tables |
| Aggregated tables | `msh_marksheet_types`, `msh_config_templates`, `msh_marksheet_schedules`, `msh_student_results`, `msh_schedule_class_jnt`, `msh_subject_practical_configs`, `msh_student_subject_results`, `msh_student_ia_marks`, `msh_student_coscholastic_results` |
| Models | `MarksheetType`, `ConfigTemplate`, `MarksheetSchedule`, `StudentResult`, `ScheduleClass`, `SubjectPracticalConfig`, `StudentSubjectResult`, `StudentIaMark`, `StudentCoscholasticResult` |
| Validation | N/A (no form inputs — read-only) |
| Migrations | msh_* tenant migrations (DDL v1) |
| CRUD Type | **Read-only** (no create/edit/delete on this screen) |
| Soft Delete | N/A on this screen |
| Pagination | N/A on dashboard (recent lists capped at 5 via `take(5)`); combined pages paginate their own tabs |
| Activity Log | None on the dashboard (read-only; no mutations) |
| Permission gates | `tenant.msh-dashboard.view`, `tenant.msh-configuration.view`, `tenant.msh-components.view`, `tenant.msh-scheduling.view`, `tenant.msh-results.view` |
| DB scope | tenant-side (`tenant_db`) |

### Environment prerequisites
1. `MarksheetGeneration` **enabled** in `prime_testing/modules_statuses.json` (else 404 on all routes).
2. `APP_ENV=testing` (Dusk; bypasses CSRF).
3. Tenant reachable at `DUSK_TENANT_URL` (default `http://test.localhost:8000`); admin `root@tenant.com` / `password`.
4. D39-MSH: the five `tenant.msh-*.view` gates are **unseeded** — the admin must have them granted (the suite grants them) or must be super-admin.

---

## 2. Business Conditions (detail)

### FR-01 — Key Metric Widgets
The controller computes a `$stats` array with 12 counts (Controller L40-53). The Blade renders six primary stat cards (Marksheet Types, Config Templates, Schedules, Student Results, Schedule Classes, Practical Configs) and a secondary row with an **Active vs Inactive** breakdown for Marksheet Types, Config Templates and Schedules. Inactive = `total − active`.

### FR-02 — 4-Pillar Combined Navigation
The Overview tab shows four link-cards, each an `<a href>` to a combined page:
- Configuration → `/marksheet-generation/configuration`
- Components → `/marksheet-generation/components`
- Scheduling → `/marksheet-generation/scheduling`
- Results → `/marksheet-generation/results`

### FR-03 — Recent Activity Tabs
Two data tabs plus Overview:
- **Recent Schedules** — table (`# / Schedule Name / Template / Schedule Date / Status`) or empty-state "No schedules created yet." Capped at 5 (`MarksheetSchedule::latest()->take(5)`).
- **Recent Results** — table (`# / Student / Class / Grand Total / Recorded`) or empty-state "No results recorded yet." Capped at 5, eager-loads `student, classSection.class, classSection.section`.

### Owned defects
- **BUG-MSH-001 (P0):** `routes/api.php` registers `apiResource('marksheetgenerations', MarksheetGenerationController::class)` (5 REST routes) but `RouteServiceProvider::map()` calls only `mapWebRoutes()` **and** the controller defines none of index/store/show/update/destroy. The API layer is DEAD.
- **PERF-MSH-003 (P2):** `results()` loads `Student::where('is_active',1)->orderBy('id')->get()` and `Subject::orderBy('name')->get()` with no pagination — unbounded on large tenants.
- **D39-MSH (P1):** msh gates unseeded → super-admin only.

---

## 3. Manual Test Cases

### TC-P01 — Dashboard renders (admin)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as admin (with msh gates) | Authenticated |
| 2 | Visit `/marksheet-generation/dashboard` | Page loads, not redirected to `/login` |
| 3 | Observe header | "Marksheet Generation Module" + green "Live" indicator visible |
| 4 | Observe date badge | Today's date (current year) visible |
| 5 | DB check | `SELECT count(*) FROM msh_student_results` = the count shown on the Student Results card |

### TC-P02 — Six stat cards
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On the dashboard, read the stat-card row | Labels present: Marksheet Types, Config Templates, Schedules, Student Results, Schedule Classes, Practical Configs |
| 2 | DB check each | Card value = `count(*)` of the corresponding `msh_*` table |

### TC-P04 — Active/Inactive breakdown
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read the secondary row | "N Active · M Inactive" shown for Marksheet Types, Config Templates, Schedules |
| 2 | DB check | Active = `count where is_active=1`; Inactive = `total − active` |

### TC-P05 / TC-P17 — Recent-activity tabs
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Read the tab bar | Overview, Recent Schedules, Recent Results present |
| 2 | Observe default | Overview pane has class `active` |
| 3 | Click "Recent Schedules" | Table (`Schedule Name` header) OR "No schedules created yet." |
| 4 | Click "Recent Results" | Table (`Grand Total` header) OR "No results recorded yet." |

### TC-P06..P10 — 4-pillar navigation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On Overview, inspect the four pillar cards | hrefs = the four combined paths |
| 2 | Click Configuration | Resolves `/marksheet-generation/configuration` (not `/login`) |
| 3 | Repeat for Components / Scheduling / Results | Each resolves to its combined path |

### TC-N01 / TC-N02 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log out | Guest |
| 2 | Visit `/marksheet-generation/dashboard` | Redirect to `/login` |
| 3 | Visit each combined page as guest | Redirect to `/login` each |

### TC-N03..N07 — Permission denial (D39-MSH)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a tenant user with NO msh permission/role | User exists |
| 2 | Log in as that user, visit the dashboard | 403 / "This action is unauthorized" / not shown |
| 3 | Repeat per combined page | Denied each (skip if env grants super-admin bypass) |

### TC-N08..N10 — BUG-MSH-001 (dead API proof)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `route:list \| grep marksheetgeneration` | No `marksheetgeneration.index/store/show/update/destroy` registered |
| 2 | Inspect `MarksheetGenerationController` | No index/store/show/update/destroy methods |
| 3 | `GET /api/v1/marksheetgenerations` (JSON) | Status ∈ {401, 403, 404, 405, 500} — never 200 |
| 4 | Inspect `RouteServiceProvider::map()` | Calls only `mapWebRoutes()`; no `mapApiRoutes()` |

### TC-D03 — PERF-MSH-003 (unbounded results load)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect `results()` source | Contains `Student::where('is_active', 1)->orderBy('id')->get()` and `Subject::orderBy('name')->get()` |
| 2 | Visit `/marksheet-generation/results` | Page renders (documented perf risk, no hard fail) |

### TC-EDG01/EDG02 — Empty-state coherence
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | If `msh_marksheet_schedules` empty | "No schedules created yet." shown; else `Schedule Name` header |
| 2 | If `msh_student_results` empty | "No results recorded yet." shown; else `Grand Total` header |

### TC-T01 / TC-A01/A02 / TC-RSP01 — Tenancy & smoke
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Confirm tenancy initialized | Counts are tenant-scoped, non-negative |
| 2 | Open dashboard, check browser console | No SEVERE errors |
| 3 | Open each combined page, check console | No SEVERE errors |
| 4 | Resize to 390×844, reload dashboard | Header still visible (responsive) |
