# STP — Progress Card (Holistic Progress Card — HPC)

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F015 |
| **Feature Name** | Progress Card (HPC) |
| **REQ ID(s)** | REQ-STP-015 |
| **RPT ID(s)** | RPT-STP-005 |
| **BR ID(s)** | BR-STP-001, BR-STP-023 |
| **Controller** | `StudentPortalController@progressCard` |
| **Route** | `GET /progress-card` (named `progress-card`) |
| **View** | `studentportal::reports.progress-card` |
| **Table Prefix** | `hpc_*` (reads from HPC module) |
| **DB Layer** | Tenant |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Feature Overview

Displays the student's Holistic Progress Card (HPC) reports. The page lists all published HPC reports for the authenticated student, showing report metadata (academic session, template, term, report date) and providing a view of the holistic assessment data.

**Known Gap (GAP-STP-15):** No PDF download link is provided per report, despite the HPC module having PDF generation capability.

---

## 3. Functional Requirements

### 3.1 Progress Card Listing
- Display a list of all HPC reports where:
  - `student_id` matches the authenticated student.
  - `status = 'Published'`.
- Each report entry shows:
  - Academic session name.
  - Template name (from HPC template).
  - Term name (if applicable).
  - Report date (ordered descending).
- Reports are ordered by `report_date` descending (most recent first).

### 3.2 Report View
- Each listed report should be clickable/expandable to view the full HPC data.
- The report view includes holistic assessment dimensions as defined by the HPC module.

### 3.3 PDF Download (GAP)
- Per FRD, each report should have a "Download PDF" link.
- The HPC module already provides a PDF generation route/endpoint.
- **Not wired** in the current implementation (GAP-STP-15).

---

## 4. Non-Functional Requirements

| NFR-ID | Requirement | Threshold |
|--------|------------|-----------|
| NFR-STP-001 | Page load time | < 2 seconds |
| NFR-STP-006 | IDOR prevention | Only own reports listed |
| NFR-STP-008 | Error handling | No stack traces; empty state if no reports |
| NFR-STP-016 | DPDP Act compliance | Report data accessible only by the student |

---

## 5. Business Rules

| Rule ID | Description | Enforcement |
|---------|-------------|-------------|
| BR-STP-001 | Data must belong to authenticated student | `$reports = HpcReport::where('student_id', $student->id)` |
| BR-STP-023 | Report access tied to exam/session context | Report visibility gated by `status = 'Published'` |
| — | Only Published status reports shown | `where('status', 'Published')` — case-sensitive string comparison |
| — | Reports ordered by date descending | `orderByDesc('report_date')` |

---

## 6. User Interface / UX

- **Layout**: Card or table listing showing report metadata (session, template, term, date).
- **Empty State**: When no student record or no published reports, page renders empty collection.
- **Actions per Report**: Currently view only; "Download PDF" button is **absent** (known gap).
- **Report Detail**: Clicking a report should navigate to a detail view showing the full HPC dimensions.

---

## 7. Data Dictionary

| Variable | Source | Type | Description |
|----------|--------|------|-------------|
| `reports` | `HpcReport::where('student_id', ...)` | Collection | All published HPC reports for the student |
| — `academicSession` | Eager-loaded relation | Model | Academic session info (name, dates) |
| — `template` | Eager-loaded relation | Model | HPC template used for the report |
| — `term` | Eager-loaded relation | Model | Term/semester info |
| — `report_date` | Direct column | Date | Date the report was generated |

---

## 8. API / Controller Specifications

### `StudentPortalController@progressCard()`

| Aspect | Detail |
|--------|--------|
| **Method** | `GET` |
| **Auth** | `auth` middleware (web) |
| **Parameters** | None |
| **Ownership** | Scoped to `auth()->user()->student->id` |
| **Query** | `HpcReport::where('student_id', $id)->where('status', 'Published')->with(['academicSession', 'template', 'term'])->orderByDesc('report_date')->get()` |
| **View** | `studentportal::reports.progress-card` with `compact('reports')` |

---

## 9. Validation Rules

| Field | Rule | Error |
|-------|------|-------|
| No parameters | N/A | N/A |
| No student record | Guard: `if ($student)` | Empty collection |

No Form Request is used.

---

## 10. Error Handling & Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Student has no user-student record | `$reports = collect()` — empty view |
| Student has no published HPC reports | Empty collection rendered |
| HPC report has null academic_session/template/term | Eager-loaded relations return null — display gracefully |
| Report date is null | Report still listed but date column shows "—" (handled by view) |
| HPC module tables missing | 500 error (module dependency) |

---

## 11. Security & Compliance

| Concern | Status |
|---------|--------|
| **IDOR** | ✅ Query scoped to `auth()->user()->student->id` |
| **Authentication** | ✅ Web auth middleware |
| **Data Minimization** | ✅ Only Published reports shown |
| **Authorization Gates** | ⚠️ No `Gate::authorize()` calls |
| **PDF Download** | ❌ Not implemented |

---

## 12. Integration Points

| Module | Integration | Direction |
|--------|-------------|-----------|
| HPC | `hpc_reports` table — report data | STP ← HPC |
| HPC | `hpc_report_templates` — template metadata | STP ← HPC |
| StudentProfile (STD) | `std_students` — student identity | STP ← STD |

---

## 13. Performance Considerations

- Single query with eager loading (3 relations) — minimal overhead.
- No pagination — acceptable for typical report count (1–10 per student).
- No caching.

---

## 14. Dependencies & Pre-requisites

| Dependency | Type | Status |
|-----------|------|--------|
| HPC module installed and active | Module | Required |
| `hpc_reports` table with Published records | Data | Required |
| Student has HPC reports generated | Data | Required for non-empty state |

---

## 15. Known Gaps & Issues

| Gap ID | Description | Severity | Status |
|--------|-------------|----------|--------|
| **GAP-STP-15** | **No PDF download link.** FRD requires a downloadable PDF per report. HPC module generates PDFs but STP does not provide a link. | Medium | 🟡 Open |
| — | No report detail/expand view — only basic listing is shown | Low | ⬜ |
| — | `status = 'Published'` is case-sensitive — may miss reports with different casing | Low | ⬜ |

---

## 16. Traceability Matrix

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-015 |
| Report Spec | RPT-STP-005 |
| Business Rules | BR-STP-001, BR-STP-023 |
| Controller Method | `StudentPortalController@progressCard` |
| Route | `GET /progress-card` |
| View | `studentportal::reports.progress-card` |
