# STP — Progress Card: Test Case List

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
| **Route** | `GET /progress-card` |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| **Backend** | Laravel 12, PHP 8.2+ |
| **Database** | MySQL 8 (Tenant DB) — requires HPC module tables |
| **Auth** | Authenticated web session (student role) |
| **Browser** | Chrome/Firefox/Safari |
| **Test Data** | Seeded student with published HPC reports across multiple terms |

---

## 3. Test Approach

- **Level**: Functional / System
- **Type**: Positive, Negative, UI, Security (IDOR)
- **Method**: Manual + Automated (Pest)
- **Data Setup**: Requires `hpc_reports` records with `student_id`, `status = 'Published'`
- **Key Focus Areas**: Report listing, sorting, data accuracy, empty states, data ownership

---

## 4. Test Scope

### In Scope
- Progress Card page rendering
- HPC report listing with metadata
- Report ordering (report_date DESC)
- Eager-loaded relations (session, template, term)
- Empty state when no reports
- Empty state when no student record
- Data ownership (IDOR)

### Out of Scope
- PDF download functionality (not implemented — GAP-STP-15)
- HPC report generation (belongs to HPC module)
- HPC report detail/expand view
- Print functionality

---

## 5. Test Cases

| TC ID | Test Case | Pre-condition | Test Steps | Expected Result | Priority | Automation |
|-------|-----------|---------------|------------|----------------|----------|------------|
| TC-PC-001 | Verify page loads for student with published reports | Student A has 3 published HPC reports | 1. Login as Student A<br>2. Navigate to `/progress-card` | Page renders; 3 reports displayed with session, template, term, date info | P1 | Yes |
| TC-PC-002 | Verify reports ordered by report_date DESC | Student A has reports dated 2026-06-01, 2026-01-15, 2025-06-01 | 1. Login as Student A<br>2. Navigate to `/progress-card` | Reports listed in order: 2026-06-01, 2026-01-15, 2025-06-01 | P1 | Yes |
| TC-PC-003 | Verify report shows academic session name | Student A has a report tied to Session 2025-26 | 1. Login as Student A<br>2. Navigate to `/progress-card` | Report entry displays correct session name (e.g. "2025-26") | P1 | Yes |
| TC-PC-004 | Verify report shows template name | Report uses template "Middle School HPC v2" | 1. Login as Student A<br>2. Navigate to `/progress-card` | Template name displayed (e.g. "Middle School HPC v2") | P2 | Yes |
| TC-PC-005 | Verify report shows term name if applicable | Report is for "Term I" | 1. Login as Student A<br>2. Navigate to `/progress-card` | Term "Term I" displayed; reports without term show gracefully | P2 | Yes |
| TC-PC-006 | Verify only Published status reports shown | Student A has 3 Published + 1 Draft + 1 Archived report | 1. Login as Student A<br>2. Navigate to `/progress-card` | Only 3 Published reports shown; Draft and Archived not listed | P1 | Yes |
| TC-PC-007 | Verify empty state — no student record | User has no linked student | 1. Login as user without student<br>2. Navigate to `/progress-card` | Page renders; empty collection message | P1 | Yes |
| TC-PC-008 | Verify empty state — no published reports | Student A has 0 HPC reports | 1. Login as Student A<br>2. Navigate to `/progress-card` | Empty collection; "No progress cards available" message | P1 | Yes |
| TC-PC-009 | Verify IDOR — cannot see another student's reports | Student A and Student B both have reports | 1. Login as Student A<br>2. Inspect network/data | Only Student A's reports are visible; Student B's data inaccessible | P1 | Yes |
| TC-PC-010 | Verify report with null academic_session | Report has academic_session_id = null | 1. Login as Student A with such a report<br>2. Navigate to `/progress-card` | Report listed; session name handled gracefully (null/missing) | P2 | Yes |
| TC-PC-011 | Verify report with null template | Report has template_id = null | 1. Login as Student A with such a report<br>2. Navigate to `/progress-card` | Report listed; template field handled gracefully | P2 | Yes |
| TC-PC-012 | Verify report with null report_date | Report has report_date = null | 1. Login as Student A with such a report<br>2. Navigate to `/progress-card` | Report listed; date displayed as "—" or fallback | P3 | Yes |
| TC-PC-013 | Verify activity log entry on page view | Student A views page | 1. Login as Student A<br>2. Navigate to `/progress-card` | Activity log records 'Viewed' with student_id | P3 | No |
| TC-PC-014 | Verify PDF download link is absent (known gap) | Student A has published reports | 1. Login as Student A<br>2. Navigate to `/progress-card` | No "Download PDF" button/link per report (GAP-STP-15) | P1 | Yes |
| TC-PC-015 | Verify page load time | Student A with 5+ reports | 1. Login as Student A<br>2. Measure load time (3 runs) | Average < 2 seconds | P2 | No |

---

## 6. Regression Impact

| Area | Impact | Suggested Tests |
|------|--------|----------------|
| HPC module | Schema changes to `hpc_reports` table could break listing | Verify report listing after HPC schema changes |
| HPC module | Status value changes (case, enum) could affect filtering | Verify only Published reports shown |
| StudentProfile | Student session changes could orphan report links | Verify reports are still listed even if session deleted (null relation) |

---

## 7. Known Gaps & Issues

| Gap ID | Description | Impact on Testing |
|--------|-------------|-------------------|
| GAP-STP-15 | No PDF download link per FRD requirement | TC-PC-014 explicitly verifies absence — will fail when feature is implemented |
| — | `status = 'Published'` is a hard-coded string, case-sensitive | May miss reports with 'PUBLISHED' or 'published' — brittle |
| — | No report detail/expand view in current implementation | Cannot verify full HPC content rendering |

---

## 8. Sign-off Criteria

| Criteria | Target |
|----------|--------|
| P1 Test Cases Passed | 100% |
| P2 Test Cases Passed | 100% |
| CRITICAL/SHOWSTOPPER defects | 0 |
| IDOR security test passed | TC-PC-009 pass |

---

## 9. Appendices

### A. Test Data Requirements
- Student with 2+ published HPC reports across different sessions
- Student with at least 1 Draft + 1 Archived report (to verify filtering)
- Student with null relations (null academic_session_id, null template_id)
- User account without linked student record

### B. Related Routes
```
GET /progress-card → StudentPortalController@progressCard
```

### C. HPC Module PDF Route (reference for gap closure)
```
Expected: GET /progress-card/{reportId}/pdf → HpcController@downloadPdf
```

---

## 10. Traceability

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-015, RPT-STP-005 |
| Business Rules | BR-STP-001, BR-STP-023 |
| Requirement Doc | `stp_ProgressCard_Requirement.md` |
| Controller | `StudentPortalController@progressCard` |
| View | `studentportal::reports.progress-card` |
