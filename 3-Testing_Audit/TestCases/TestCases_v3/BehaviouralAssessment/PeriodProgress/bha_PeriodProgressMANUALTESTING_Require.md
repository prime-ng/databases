# bha_PeriodProgress — Manual Test Specification

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | BehaviouralAssessment |
| Feature / Screen | PeriodProgress (screen 22 — Longitudinal Trend Dashboard) |
| Requirement | `BehaviouralAssessment_v2/22-Period-Progress.md` |
| Specified URL | `/behavioural-assessment/reports/progress` — **NOT registered (404)** |
| Controller | `BaReportController` — **no `progress()` action** (screen unimplemented) |
| Models | `BaComputedScore` (`ba_computed_scores`), `BaAssessmentPeriod` (`ba_assessment_periods`) |
| Data source (specified) | `ba_computed_scores` (per student / category / period) |
| Validation | N/A (no form) — route params on sibling paths only |
| Migrations | `database/migrations/tenant/2026_06_16_130619_create_ba_computed_scores_table.php` |
| CRUD Type | Read-only report / data-viz (no create/edit/delete) |
| Soft Delete | Model uses `SoftDeletes`; screen never mutates |
| Pagination | N/A |
| Activity Log | NONE (read-only surface — documented absence) |
| DB scope | TENANT-side · File prefix `bha_` · Live tables `ba_` (DOC-BA-001) |
| Test file | `bha_PeriodProgress_TestCas.php` (26 methods, single file) |

> **Environment prerequisites:** BehaviouralAssessment must be ENABLED in `prime_testing/modules_statuses.json`
> (else all routes 404 — constraint #19); `APP_ENV=testing` for Dusk (constraint #20); tenant reachable at
> `DUSK_TENANT_URL`. Prime_ai cloned beside prime_testing with `MAIN_PROJECT_PATH` set (source-truth reads).

---

## 2. Business Conditions (detailed)

**BC-EDG-01 — the screen does not exist.** Screen-22 specifies a standalone trend dashboard: a bold
composite-score trend line, optional per-category dotted lines (max 5), red/green milestone flags for
high-severity incidents / completed interventions, and three KPI cards (Starting Score, Ending Score, Total
Progress Delta %). None of this exists. `BaReportController` has only: `index`, `student`, `byClass`,
`period`, `categories`, `incidents`, `export`. There is no `reports/progress` route and no progress view.

**BC-EDG-03 — BUG-BA-013 on the specified data path.** Screen-22 says the system "queries `ba_computed_scores`
for [the student] across all active terms". The live score column is **`numeric_score`** (DECIMAL 5,2); there
is **no** `score` column. The two implemented computed-scores aggregations a trend screen would reuse read the
wrong name:
- `categories()` → RAW `AVG(score)/MIN(score)/MAX(score)` → **SQL "Unknown column 'score'" → HTTP 500**.
- `byClass()` → collection `->avg('score')/min('score')/max('score')/pluck('score')` → **null → 0.00** (a 4.25
  student silently trends as a flat 0.00, and every student is wrongly flagged at-risk `< 2.50`).
- `student()` → `avg('numeric_score')` / `AVG(numeric_score)` → **correct** (the contrast).

**BC-EDG-04 — export stub.** Step 9 of the workflow ("exports this progress chart to PDF") maps to `export()`,
which is `abort(501, 'Export feature coming soon.')` on a live, authorized route (BUG-BA-011).

**BC-AUTH-05 / VAL-BA-003.** `export()` authorizes `tenant.behavioural-assessment.reports.view`, though
`BaReportPolicy` declares the `export` ability on `tenant.behavioural-assessment.reports.export` — a weaker
gate than the declared ability.

---

## 3. Test Cases (step-by-step)

### TC-P01 — Computed-scores schema & model truth (`_01`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Init tenant; `Schema::hasTable('ba_computed_scores')` | true |
| 2 | `Schema::hasColumns([... numeric_score, overall_score, period_id ...])` | true |
| 3 | `Schema::hasColumn('ba_computed_scores','score')` | **false** (BUG-BA-013 root) |
| 4 | Inspect model: table, SoftDeletes, fillable, relations | `ba_computed_scores`; SoftDeletes; `numeric_score` fillable, no `score`; 3 BelongsTo |
| 5 | `SELECT` column type of `numeric_score` | `decimal(5,2)` |

### TC-P02 — Runtime prefix vs DDL-doc (`_02`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Schema::hasTable('ba_computed_scores')` | true |
| 2 | `Schema::hasTable('bha_computed_scores')` | **false** (DOC-BA-001) |

### TC-D01 — No progress() controller action (`_03`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `method_exists(BaReportController, 'index'|'student'|'byClass'|'period'|'categories'|'incidents'|'export')` | all true |
| 2 | `method_exists(BaReportController, 'progress'|'trend'|'periodProgress'|'trendline')` | all **false** |
| 3 | Reflect public methods; assert `progress`/`trend` absent | absent |

### TC-D02 — No progress route (`_04`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `Route::has('behavioural-assessment.reports.index'|.student|.class|.categories|.export)` | all true |
| 2 | `Route::has('behavioural-assessment.reports.progress'|.trend|.period-progress)` | all **false** |

### TC-D03 — No progress view / trend widgets (`_05`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Assert `reports/progress.blade.php` / `period-progress.blade.php` / `trend.blade.php` do not exist | absent |
| 2 | Grep reports view tree for `Period Progress`, `Trend Line`, `Milestone`, `Composite Score Trend`, `Total Progress Delta`, `Starting Score`, `Ending Score` | none found |

### TC-P03 / TC-D04 — Hub renders & does not link progress (`_10`,`_11`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/behavioural-assessment/reports` authenticated | Not redirected to `/login`; no "Whoops" |
| 2 | Page source | Does NOT contain `Period Progress` or `reports/progress` |

### TC-P04 — Nearest computed-scores surface renders (`_12`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/reports/student/{id}` (student() uses numeric_score) | HTTP 200 or 302 (never 500) |

### TC-N01 — Progress URL 404 (`_30`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/behavioural-assessment/reports/progress` (admin) | **404** — route not registered |

### TC-N02 — Invalid student id (`_31`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/reports/student/987654321` | **404** (findOrFail) |

### TC-P06 — Computed-scores FKs RESTRICT (`_40`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `information_schema.REFERENTIAL_CONSTRAINTS` for `ba_computed_scores` | `std_students`, `ba_categories`, `ba_assessment_periods` → RESTRICT/NO ACTION |

### TC-N03 / TC-N04 — Guest & limited-user auth (`_50`,`_51`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Clear cookies; visit hub | Redirect to `/login` |
| 2 | Login as non-super-admin with no report permission; GET `/reports/student/{id}` | **403** before findOrFail |

### TC-D11 — Export gate divergence (`_53`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Extract `export()` body | contains `reports.view`, NOT `reports.export` |
| 2 | Read `BaReportPolicy` | declares `reports.export` ability (unused by controller) |

### TC-D05 — Export = 501 stub (`_70`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GET `/behavioural-assessment/reports/export` (authorized) | **HTTP 501** "Export feature coming soon." |

### TC-D07 — Deterministic BUG-BA-013 (`_72`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed a `ba_computed_scores` row with `numeric_score = 4.25` | row created |
| 2 | `$rows->avg('score')` (the broken aggregation) | **null** |
| 3 | `round((float) null, 2)` | **0.00** (a 4.25 student trends as flat 0.00) |
| 4 | `round((float) $rows->avg('numeric_score'), 2)` | **4.25** (correct) |
| 5 | `$row->score` attribute | **null** (no such attribute) |
| 6 | Force-delete the seed | cleaned up |

### TC-D08 — Source-level BUG-BA-013 + contrast (`_73`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Extract `categories()` body | contains `AVG(score)` (RAW → hard 500) |
| 2 | Extract `byClass()` body | contains `avg('score')` (collection → 0.00) |
| 3 | Extract `student()` body | contains `avg('numeric_score')`, NOT `avg('score')` (correct contrast) |

### TC-D06 / TC-D09 — Trend widgets & rules unimplemented (`_71`,`_74`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Grep controller (lowercased) | no `function progress`, `milestone`, `interpolat`, `score delta`, `max 5` |
| 2 | Grep reports views | no `interpolat`, `Uncheck a category`, `Total Progress Delta` |

### TC-P09 / TC-D10 / TC-P10 — Tenancy & dead API (`_90`,`_91`,`_92`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `tenancy()->initialized` | true; `ba_computed_scores` resolves in tenant DB |
| 2 | `Route::has('behaviouralassessment.index')` | **false** (DEAD-BA-001) |
| 3 | Read `routes/api.php` | `auth:sanctum`, NO `InitializeTenancyByDomain` |
| 4 | Read `RouteServiceProvider` | web stack has InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, 'auth', 'verified'; never loads `routes/api.php` |

### TC-N05 — Output escaping smoke (`_93`)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Visit `/reports/student/{id}`; inspect source | no unescaped `<script>alert(` |
