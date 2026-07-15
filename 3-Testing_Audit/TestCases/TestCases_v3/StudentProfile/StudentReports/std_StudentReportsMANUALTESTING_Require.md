# std_StudentReports — Manual Testing Guide

## 1. Feature Information
| Field | Value |
|-------|-------|
| Module | StudentProfile |
| Feature | StudentReports (composite, read-only) |
| URL(s) | `/student-profile/reports-mgt` · `/student-profile/reports/class-wise-student-strength` |
| Route names | `student-profile.reports.index` · `student-profile.reports.class-strength` |
| Controller | `StudentReportController@combinedStudentReport` (backs both routes) |
| View | `studentprofile::reports.index` (tabs: student-strength · admission-register · medical-profile) |
| Composite read tables | `std_students`, `std_student_academic_sessions`, `std_health_profiles`, `std_medical_incidents`, `std_student_attendance` |
| Validation | None (GET filter params only: `class_id`, `academic_session_id`, `from_date`, `to_date`) |
| CRUD Type | READ-ONLY report/dashboard (no create/edit/delete) |
| Soft Delete | N/A |
| Pagination | None (collections rendered in-page) |
| Activity Log | None on render (read-only) |
| Permission | `tenant.student.viewAny` (report) · `tenant.student.export` (export) |
| Export | Student-dataset export via `StudentController@export`: PDF = synchronous inline (`Pdf::download`); Excel/CSV = queued (`Excel::queue`) |

**Environment prerequisites:** module `STUDENT` ENABLED in `prime_testing/modules_statuses.json` (else 404); `APP_ENV=testing`; a tenant seeded with students in the current session.

---

## 2. Business Conditions (detail)

- **Current-session scoping (BC-BIZ-01):** the report only counts `std_student_academic_sessions` rows with `is_current = 1` and `academic_session_id = currentSessionId` (defaults to the session flagged `is_current`, or the `academic_session_id` filter).
- **Strength report (BC-BIZ-02):** grouped by `class|section`; boys = gender `Male`, girls = `Female`; General vs OBC/SC/ST from `std_student_profiles.caste_category`; RTE/EWS from `right_to_education || is_ews`.
- **Admission register (BC-BIZ-03):** one row per current-session enrollment; father/mother from guardian pivot `relation_type`; previous school + TC no from last `previousEducations`.
- **Medical report (BC-BIZ-04):** only students whose `healthProfile` has `allergies` OR `chronic_conditions`; emergency contact from guardian pivot `is_emergency_contact = 1`.
- **Read-only (BC-BIZ-05):** no writes; the `activity_logs` table row count must be unchanged after rendering.

**Known defects to observe**
- **PERF-STD-10:** the module student export PDF path (`StudentController@export` → `exportPDF`) builds the entire student collection in-request and streams via `Pdf::loadView(...)->download()` — no queue. For 1000+ students this risks memory exhaustion / timeout. Excel/CSV are queued.
- **DEV-STD-R1:** report index breadcrumb links `route('complaint.reports.summary')` — an unregistered route → `RouteNotFoundException` on render.
- **DEV-STD-R2:** `$currentSessionId = $request->academic_session_id ?? $currentSession->id;` throws "Attempt to read property 'id' on null" when no session is current and no session param is passed.

---

## 3. Manual Test Cases

### TC-P10 — Report index renders three tabs
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as School Admin | Dashboard loads |
| 2 | Visit `/student-profile/reports-mgt` | Report page loads, HTTP 200 |
| 3 | Inspect tabs | "Student Strength", "Admission Register", "Medical Profile" tabs visible (`#student-strength-pane`, `#admission-register-pane`, `#medical-profile-pane`) |
| 4 | DB check | `SELECT COUNT(*) FROM std_student_academic_sessions WHERE is_current=1` matches strength totals |

### TC-P14 — Current-session scoping
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit report with no filter | Only current-session enrollments counted |
| 2 | DB check | `SELECT COUNT(*) FROM std_student_academic_sessions WHERE is_current=1 AND academic_session_id=<current>` = report total |

### TC-P30/31/32 — Filters
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `?class_id=<id>` | Only that class's rows; no 500 |
| 2 | Visit `?academic_session_id=<id>` | Report scoped to that session |
| 3 | Visit `?from_date=2020-01-01&to_date=2030-12-31` | Admission register limited to date range |

### TC-N33 — Malformed filters
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `?class_id=abc&from_date=notadate` | Page renders (empty/unfiltered), NO 500 / Whoops |

### TC-D43 — PERF-STD-10 (PDF export synchronous)
| Step | Action | Expected |
|------|--------|----------|
| 1 | On student list, trigger PDF export with a large filter set | Response streams synchronously (blocking); no job queued |
| 2 | Source check | `StudentController@export` PDF branch calls `exportPDF()` → `Pdf::loadView(...)->download()` (synchronous) |
| 3 | Compare Excel/CSV | Excel/CSV branches call `Excel::queue(...)` → "Export is being processed" flash (async) |
| 4 | Verdict | Document PDF path as the remaining synchronous-export performance gap |

### TC-D63 — DEV-STD-R1 (breadcrumb dead route)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Source check `reports/index.blade.php` line 2 | breadcrumb uses `route('complaint.reports.summary')` |
| 2 | `php artisan route:list \| grep complaint.reports.summary` | Route NOT registered → render would throw `RouteNotFoundException` |

### TC-N70 — DEV-STD-R2 (null session)
| Step | Action | Expected |
|------|--------|----------|
| 1 | In a tenant with NO session flagged `is_current` | — |
| 2 | Visit `/student-profile/reports-mgt` (no `academic_session_id`) | Current behaviour: 500 "Attempt to read property 'id' on null" (defect) |

### TC-N50 / TC-T94 — Guest access
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out; visit `/student-profile/reports-mgt` | Redirect to `/login`; no report panes in HTML |

### TC-N52 — No-permission user
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as a user WITHOUT `tenant.student.viewAny` | — |
| 2 | Visit report URL | HTTP 403 (Gate denies) |

### TC-S92 — Read-only guarantee
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SELECT COUNT(*) FROM activity_logs` before | record N |
| 2 | Render the report | — |
| 3 | `SELECT COUNT(*) FROM activity_logs` after | still N (no write) |

### TC-S93 — Reflected input
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `?from_date="><script>window.__xss=1</script>` | Input escaped; `window.__xss` undefined |
