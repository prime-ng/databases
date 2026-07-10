# MarksheetGeneration — Dashboard & Navigation — Manual Test Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | MarksheetGeneration |
| Feature / Screen | Dashboard & Navigation (composite / read-focused) |
| Primary URL | `/marksheet-generation/dashboard` (route `marksheet-generation.dashboard`) |
| Combined URLs | `/marksheet-generation/configuration` · `/components` · `/scheduling` · `/results` (`*.combined`) |
| Controller | `MarksheetGenerationController@{dashboard,configuration,components,scheduling,results}` |
| Data provider | `app/Providers/Data/MarksheetDataProvider.php` (marksheet variable resolution — not used by the dashboard render itself) |
| Menu | `MsgMenuController::menuStructure()` (sidebar sync; 4 pillars → combined routes) |
| Views | `resources/views/dashboard.blade.php`, `pages/{configuration,components,scheduling,results}.blade.php` |
| Aggregated models | MarksheetType, ConfigTemplate, MarksheetSchedule, StudentResult, ScheduleClass, SubjectPracticalConfig, StudentSubjectResult, StudentIaMark, StudentCoscholasticResult |
| Validation / FormRequest | None (read-only screen) |
| CRUD Type | **Read-only composite** (no create/edit/delete on this screen) |
| Soft Delete | N/A (dashboard) |
| Pagination | Dashboard: recent lists capped `take(5)`. Combined pages paginate (15/20 per tab) — Results tab has an **unbounded** `Student::get()` / `Subject::get()` (PERF-MSH-003). |
| Activity Log | None emitted by dashboard/combined read actions |
| Permission gates | `tenant.msh-dashboard.view`, `tenant.msh-configuration.view`, `tenant.msh-components.view`, `tenant.msh-scheduling.view`, `tenant.msh-results.view` (**unseeded — D39-MSH**) |
| DB scope | tenant-side (`msh_*`, `Database: tenant_db`) |
| Test style | Browser Dusk (`extends DuskTestCase`) |

**Environment prerequisites**
1. `MarksheetGeneration` must be **enabled** in `prime_testing/modules_statuses.json` — otherwise every route 404s.
2. `APP_ENV=testing` for Dusk (CSRF bypass); tenant reachable at `DUSK_TENANT_URL` (`http://test.localhost:8000`).
3. Admin `root@tenant.com` / `password`. Because msh gates are unseeded (D39), the suite grants the 5 view gates to the admin before rendering.

---

## 2. Business Conditions (detailed)

### Permission gates (BC-AUTH)
Each controller action opens with `Gate::authorize('tenant.msh-<area>.view')`. If the current user lacks the permission the framework throws `AuthorizationException` → **403**. A guest (no auth) is redirected to `/login` by the `auth`+`verified` middleware before the gate is reached.

```
dashboard()      → Gate::authorize('tenant.msh-dashboard.view')
configuration()  → Gate::authorize('tenant.msh-configuration.view')
components()     → Gate::authorize('tenant.msh-components.view')
scheduling()     → Gate::authorize('tenant.msh-scheduling.view')
results()        → Gate::authorize('tenant.msh-results.view')
```

### Aggregation (BC-BIZ)
```
$stats = [
  total_marksheet_types      = MarksheetType::count()
  active_marksheet_types     = MarksheetType::where('is_active',1)->count()
  total_config_templates     = ConfigTemplate::count()
  active_config_templates    = ConfigTemplate::where('is_active',1)->count()
  total_schedules            = MarksheetSchedule::count()
  active_schedules           = MarksheetSchedule::where('is_active',1)->count()
  total_results              = StudentResult::count()
  total_schedule_classes     = ScheduleClass::count()
  total_subject_practical    = SubjectPracticalConfig::count()
  total_student_subject_results = StudentSubjectResult::count()
  total_student_ia_marks     = StudentIaMark::count()
  total_coscholastic_results = StudentCoscholasticResult::count()
];
$recentSchedules = MarksheetSchedule::with('configTemplate')->latest()->take(5)->get();
$recentResults   = StudentResult::with(['student','classSection.class','classSection.section'])->latest()->take(5)->get();
```

### Empty-state branches (BC-EDG)
- Recent Schedules: `@if ($recentSchedules->count())` … `@else` **"No schedules created yet."** + Create Schedule CTA.
- Recent Results: `@if ($recentResults->count())` … `@else` **"No results recorded yet."** + Add Result CTA.

### Known defects
- **BUG-MSH-001 (P0):** `routes/api.php` → `apiResource('marksheetgenerations', MarksheetGenerationController::class)` names index/store/show/update/destroy, but the controller has none of them, and `RouteServiceProvider::map()` only maps web routes (so the module api.php is never loaded). The API resource is dead.
- **PERF-MSH-003 (P2):** `results()` runs `Student::where('is_active',1)->orderBy('id')->get()` and `Subject::orderBy('name')->get()` with no pagination.
- **D39-MSH (P1):** msh permissions unseeded → gates behave super-admin-only.

---

## 3. Manual Test Cases

### TC-P01 — Dashboard renders for the admin
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure `MarksheetGeneration` enabled; log in as `root@tenant.com`; grant `tenant.msh-dashboard.view` | Login succeeds |
| 2 | Visit `/marksheet-generation/dashboard` | HTTP 200 |
| 3 | Observe header | "Marksheet Generation Module" + "Live" indicator visible |
| 4 | Observe breadcrumb | `ol.breadcrumb` shows Marksheet Generation → Dashboard |
| 5 | DB check | `SELECT COUNT(*) FROM msh_student_results` = value shown in the red "Student Results" card |

### TC-P02 — Six primary stat cards
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On the dashboard, inspect the first card row | Cards: Marksheet Types, Config Templates, Schedules, Student Results, Schedule Classes, Practical Configs |
| 2 | Compare each value to DB | Each equals its `::count()` (e.g. `msh_config_templates`, `msh_schedule_class_jnt`, `msh_subject_practical_configs`) |

### TC-P03 — Stat values match DB counts
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `SELECT COUNT(*) FROM msh_student_results` | Note N |
| 2 | Reload dashboard | "Student Results" card = N |

### TC-P04 — Active/Inactive breakdown
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect the secondary row | For Types/Templates/Schedules: "<active> Active · <total-active> Inactive" |

### TC-P05 — Recent-activity tabs
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Inspect tab strip | Overview, Recent Schedules, Recent Results present; Overview active |

### TC-P06 / TC-P07..P10 — 4-pillar navigation
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On Overview pane, confirm 4 cards | Configuration, Components, Scheduling, Results |
| 2 | Click Configuration | Lands on `/marksheet-generation/configuration`, not `/login` |
| 3 | Repeat for Components / Scheduling / Results | Each combined page resolves (200) |

### TC-P11 — Recent Schedules tab (table or empty)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Recent Schedules" | If `msh_marksheet_schedules` has rows → table with columns #, Schedule Name, Template, Schedule Date, Status (≤ 5 rows). Else → "No schedules created yet." |

### TC-P12 — Recent Results tab (table or empty)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click "Recent Results" | If `msh_student_results` has rows → table #, Student, Class, Grand Total, Recorded (≤ 5). Else → "No results recorded yet." |

### TC-N01 / TC-N02 — Guest redirect
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log out | Session cleared |
| 2 | Visit `/marksheet-generation/dashboard` | Redirected to `/login` |
| 3 | Visit each combined URL as guest | Redirected to `/login` |

### TC-N03..N07 — Permission-gate denial (D39)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a tenant user with **no** msh permissions/roles (`user_type=EMPLOYEE`, valid `prefered_language`, unique `emp_code`) | User created |
| 2 | Log in as that user; visit `/marksheet-generation/dashboard` | 403 / "This action is unauthorized." (not the dashboard) |
| 3 | Repeat for configuration/components/scheduling/results | Each 403 |
| Note | If the environment grants a super-admin bypass, the case is a documented skip (D39 env state) | — |

### TC-N08..N10 — BUG-MSH-001 dead API
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `GET /api/v1/marksheetgenerations` (JSON) | **Not** 200 — 404 (route unregistered) / 401 / 405 / 500 |
| 2 | Inspect `MarksheetGenerationController` | No `index/store/show/update/destroy` methods |
| 3 | `php artisan route:list \| grep marksheetgeneration` | No `marksheetgeneration.*` API routes registered |

### TC-D03 / PERF-MSH-003 — Results page unbounded load
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/marksheet-generation/results` | Page renders |
| 2 | Inspect `results()` source | `Student::where('is_active',1)->orderBy('id')->get()` + `Subject::orderBy('name')->get()` — no pagination (perf risk documented) |

### TC-A01/A02 — Console-error smoke
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open DevTools console; load dashboard & each combined page | No `SEVERE`-level console errors |

### TC-RSP01 — Responsive
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Resize viewport to 390×844; reload dashboard | Header + stat cards remain visible/legible |
