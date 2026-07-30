# STP — Complaints TC List

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Support — Complaints

---

## 2. FRD / BR Reference
- **REQ-STP-028** — Complaints (P0)
- **BR-STP-016** — Data ownership
- **BR-STP-017** — Complainant type correctly resolved
- **BR-STP-018** — Dropdown ID by key, not hardcoded
- **BR-STP-019** — Status correctly resolved

---

## 3. Test Scenarios

| TC ID | Test Case | Preconditions | Test Steps | Expected Result | Status |
|-------|-----------|--------------|------------|----------------|--------|
| TC-STP-CMP-001 | Verify complaint listing loads with existing complaints | Student has 1+ complaints | 1) Login as student 2) Navigate to /complaint | List shows ticket number, ticket date, title, category, status badge; paginated | ⬜ |
| TC-STP-CMP-002 | Verify complaint listing empty state | Student has NO complaints | 1) Login as student 2) Navigate to /complaint | "No complaints" empty state shown | ⬜ |
| TC-STP-CMP-003 | Verify create form loads with parent categories | ComplaintCategory parents exist | 1) Login as student 2) Navigate to /complaint/create | Form renders: category dropdown, title, description, optional fields | ⬜ |
| TC-STP-CMP-004 | Verify AJAX subcategories load on category change | Category has children | 1) Login 2) Open create form 3) Select category with children | GET /complaint/ajax/subcategories/{id} returns JSON with subcategory list | ⬜ |
| TC-STP-CMP-005 | Verify AJAX category meta loads on category change | Category has severity/priority | 1) Login 2) Open create form 3) Select category | GET /complaint/ajax/subcategory-meta/{id} returns JSON with severity_level_id and priority_score_id | ⬜ |
| TC-STP-CMP-006 | Verify successful complaint submission | Valid category, title, description | 1) Login 2) Fill form 3) Submit | Complaint created; redirect to index with success message containing ticket number CMP-YYYY-SSSSSS | ⬜ |
| TC-STP-CMP-007 | Verify ticket number format | After submission | 1) Submit 2) Observe success message 3) Check DB | Ticket number format: CMP-2026-000001 (current year + 6-digit zero-padded serial) | ⬜ |
| TC-STP-CMP-008 | Verify ticket number uniqueness | Multiple complaints in same year | 1) Submit 2 complaints | Ticket numbers are sequential and unique | ⬜ |
| TC-STP-CMP-009 | Verify anonymous submission | is_anonymous = true | 1) Login 2) Check "Submit as Anonymous" 3) Submit | complainant_user_id = null; complainant_type = Anonymous | ⬜ |
| TC-STP-CMP-010 | Verify missing category_id returns error | No category selected | 1) Login 2) Submit without category | 422 validation error: "category_id is required" | ⬜ |
| TC-STP-CMP-011 | Verify title length exceeds 200 characters | Title of 201+ chars | 1) Login 2) Enter long title 3) Submit | 422 validation error | ⬜ |
| TC-STP-CMP-012 | Verify complainant type lookup failure handled | sys_dropdown_table missing key | 1) Remove "Student"/"Anonymous" from dropdown 2) Submit | Error: "Complainant type \"Student\" not found in system dropdowns" | ⬜ |
| TC-STP-CMP-013 | Verify status lookup failure handled | sys_dropdown_table missing "Open" | 1) Remove "Open" from status dropdown 2) Submit | Error: "Default complaint status not found" | ⬜ |
| TC-STP-CMP-014 | Verify file upload with complaint | Valid image file (< 5 MB) | 1) Login 2) Attach image 3) Submit | support_file = 1; media stored in 'complaint_img' collection | ⬜ |
| TC-STP-CMP-015 | Verify show page renders detail | Complaint exists | 1) Login 2) Navigate to /complaint/{id} | Detail shows: ticket no, date, title, description, category, subcategory, severity, priority, status, attachment link | ⬜ |
| TC-STP-CMP-016 | Verify accessing another student's complaint returns 404 | Complaint ID of different student | 1) Login as Student A 2) Navigate to /complaint/{B_id} | 404 Not Found | ⬜ |
| TC-STP-CMP-017 | Verify guardian complaints appear in student's list | Guardian submitted complaint targeting student | 1) Login as student 2) Navigate to /complaint | Guardian's complaint included in listing | ⬜ |
| TC-STP-CMP-018 | Verify pagination (15 per page) | 16+ complaints exist | 1) Login as student with 16 complaints 2) Navigate to /complaint | Page 1 shows 15; pagination links visible | ⬜ |
| TC-STP-CMP-019 | Verify category name and subcategory name display on show | Complaint has category + subcategory | 1) Login 2) Navigate to /complaint/{id} | Both categoryName and subcategoryName displayed | ⬜ |
| TC-STP-CMP-020 | Verify severity and priority labels display | Complaint has severity + priority | 1) Login 2) Navigate to /complaint/{id} | severityLabel and priorityLabel resolved from sys_dropdown_table | ⬜ |
| TC-STP-CMP-021 | Verify severity hidden when not set | Complaint has null severity_level_id | 1) Login 2) Navigate to /complaint/{id} | Severity section not displayed or shows "N/A" | ⬜ |
| TC-STP-CMP-022 | Verify optional fields (location, incident date) display when filled | Complaint has location_details + incident_date | 1) Login 2) Navigate to /complaint/{id} | Location and incident date displayed | ⬜ |
| TC-STP-CMP-023 | Verify complaint with target info displays correctly | Complaint has target_table_name, target_selected_id | 1) Login 2) Submit with target 3) View show | Target information displayed | ⬜ |
| TC-STP-CMP-024 | Verify DB rollback on exception | Any exception during store | 1) Simulate failure (e.g., media store error) 2) Submit | DB transaction rolls back; no partial records; error message shown | ⬜ |

---

## 4. Test Data Requirements
- ComplaintCategory with parent-child hierarchy (2+ levels)
- sys_dropdown_table entries for `cmp_complaints.complainant_type_id` and `cmp_complaints.status_id`
- Student with complaints (various statuses)
- Student with guardians who have submitted complaints
- Student with 16+ complaints for pagination test
- At least two students for ownership tests

---

## 5. Test Environment
- **Browser:** Chrome / Firefox / Edge (latest)
- **Auth:** Authenticated student user
- **DB:** Tenant database seeded with Complaint module + system dropdowns

---

## 6. Automation Scope
| TC ID | Automatable? | Notes |
|-------|-------------|-------|
| TC-STP-CMP-001–024 | Yes | Most testable via Pest HTTP tests; TC-STP-CMP-004/005 require AJAX endpoint tests |

---

## 7. Pass / Fail Criteria
- **Pass:** All TC IDs pass; ownership enforced; ticket number generated correctly; validations work
- **Fail:** IDOR; ticket collision; hardcoded ID 104 found; missing validation; DB inconsistency

---

## 8. Known Issues
| Issue | Description | Severity |
|-------|-------------|----------|
| SEC-STP-04 | Hardcoded dropdown ID 104 may exist in other code paths | **High** |
| GAP-STP-10 | No `withQueryString()` on pagination — filters reset on page change | Low |
| — | No server-side file type/size validation on complaint_img | Medium |

---

## 9. Route Reference
| Method | URI | Name |
|--------|-----|------|
| GET | /complaint | student-portal.complaint.index |
| GET | /complaint/create | student-portal.complaint.create |
| POST | /complaint | student-portal.complaint.store |
| GET | /complaint/{id} | student-portal.complaint.show |
| GET | /complaint/ajax/subcategories/{category} | student-portal.complaint.subCategories |
| GET | /complaint/ajax/subcategory-meta/{category} | student-portal.complaint.categoryMeta |

---

## 10. Execution Status
| Total TCs | Passed | Failed | Blocked | Not Run |
|-----------|--------|--------|---------|---------|
| 24 | — | — | — | 24 |
