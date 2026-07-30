# STP — Complaints Requirement Document

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Support — Complaints
- **Table Prefix:** stp_ (uses cmp_complaints, cmp_complaint_categories from Complaint module)

---

## 2. FRD Reference
| ID | Description | Priority |
|----|------------|----------|
| REQ-STP-028 | Complaints | P0 |
| BR-STP-016 | Complaint data must belong to authenticated user | P0 |
| BR-STP-017 | Complainant type must be correctly resolved | P0 |
| BR-STP-018 | Dropdown ID must be looked up by string key, not hardcoded integer | P0 |
| BR-STP-019 | Status must be correctly resolved from system dropdowns | P0 |

---

## 3. Feature Description
Enables students to submit complaints against categories/subcategories, automatically resolve severity and priority from category metadata, generate unique ticket numbers (CMP-YYYY-SSSSSS), view their complaint history with status badges, and view individual complaint details.

---

## 4. User Stories / Use Cases
- **As a** student, **I want to** submit a complaint with category, subcategory, title, description, and optional attachment **so that** I can report issues to the school.
- **As a** student, **I want to** view all my complaints with status badges (Open, Assigned, Resolved, Closed) **so that** I can track their progress.
- **As a** student, **I want to** view complaint details including handler notes, severity, priority, and file attachments **so that** I see the full resolution history.

---

## 5. Business Rules (BR)
| BR ID | Rule | Type | Enforcement |
|-------|------|------|-------------|
| BR-STP-001 | Data must belong to authenticated student | Permission | Scoped query with student + guardian user ID matching |
| BR-STP-017 | Complainant type resolved correctly | Validation | Key-based lookup: `sys_dropdown_table.where('key', 'cmp_complaints.complainant_type_id').where('value', $typeValue)` |
| BR-STP-018 | Dropdown ID looked up by key, not hardcoded 104 | Security | See SEC-STP-04 — **current code uses key-based lookup, but hardcoded ID 104 pattern exists elsewhere** |
| — | Status defaults to "Open" via key-based lookup | Validation | `sys_dropdown_table.where('key', 'cmp_complaints.status_id').where('value', 'Open')` |
| — | Ticket number format: CMP-YYYY-SSSSSS | Generation | Year + 6-digit serial with leading zeros; LockForUpdate to prevent duplicates |
| — | Subcategory optionally selected from category children | Display | AJAX endpoint: `getCategories(ComplaintCategory $category)` |
| — | Severity and priority auto-populated from category metadata | Display | AJAX endpoint: `getCategoryMeta(ComplaintCategory $category)` |
| — | File upload: image only, max 5 MB (not explicitly validated in store) | Validation | `complaint_img` from request; stored via media library |
| — | Anonymous complaints allowed | Validation | `is_anonymous` boolean flag; complainant_user_id set to null when true |
| — | Optional fields: location_details, incident_date, target table/name/code | Display | All nullable in validation |

---

## 6. Validations & Edge Cases
| Scenario | Input / Action | Expected Behaviour |
|----------|---------------|-------------------|
| Successful complaint submission | Valid category, title, description | Complaint created; ticket number assigned; success message shown |
| Missing category_id | No category selected | 422 validation error |
| Invalid category_id | Non-existent ID | 422 validation error |
| Title exceeds 200 characters | 201+ character title | 422 validation error |
| Anonymous submission | is_anonymous = true | complainant_user_id = null; complainant_type = Anonymous |
| Non-anonymous submission | is_anonymous = false | complainant_user_id = auth()->user()->id; contact from user profile |
| File upload with complaint | Valid image file | File stored via media collection 'complaint_img'; support_file = 1 |
| No file upload | No file attached | support_file = 0; no media stored |
| Complainant type lookup fails | sys_dropdown_table missing key | Error: "Complainant type not found. Please contact the administrator." |
| Status default lookup fails | sys_dropdown_table missing "Open" | Error: "Default complaint status not found. Please contact the administrator." |
| Ticket number collision | Race condition on serial number | LockForUpdate + while loop ensures uniqueness |
| Category has no children | Leaf category selected | `getCategories()` returns empty subcategories array |
| Student with guardians | Student linked to guardians | Complaint list includes complaints created by guardians |
| Student without guardians | No guardian entries | Complaint list scoped only to direct user + target match |
| Pagination | More than 15 complaints | Paginated with `->paginate(15)` |
| View own complaint | Own complaint ID | Detail page shows ticket info, status label, severity, priority, category names |
| View another's complaint | Another student's complaint ID | 404 Not Found (ownership scoped) |

---

## 7. Route Details
| Method | Route | Name | Controller Method |
|--------|-------|------|-------------------|
| GET | /complaint | student-portal.complaint.index | StudentPortalComplaintController@index |
| GET | /complaint/create | student-portal.complaint.create | StudentPortalComplaintController@create |
| POST | /complaint | student-portal.complaint.store | StudentPortalComplaintController@store |
| GET | /complaint/{id} | student-portal.complaint.show | StudentPortalComplaintController@show |
| GET | /complaint/ajax/subcategories/{category} | student-portal.complaint.subCategories | StudentPortalComplaintController@getCategories |
| GET | /complaint/ajax/subcategory-meta/{category} | student-portal.complaint.categoryMeta | StudentPortalComplaintController@getCategoryMeta |

---

## 8. Data / Entity Reference

### A. Complaint
- **Model:** `Modules\Complaint\Models\Complaint`
- **Table:** `cmp_complaints`
- **Key fields:** ticket_no, ticket_date, complainant_type_id, complainant_user_id, is_anonymous, category_id, subcategory_id, severity_level_id, priority_score_id, title, description, location_details, incident_date, status_id, target_table_name, target_selected_id, created_by, support_file

### B. Complaint Category
- **Model:** `Modules\Complaint\Models\ComplaintCategory`
- **Table:** `cmp_complaint_categories`
- **Relations:** parent (self-referential), children
- **Scope:** `parents()` — root-level categories only

### C. System Dropdown
- **Table:** `sys_dropdown_table`
- **Keys used:** `cmp_complaints.complainant_type_id`, `cmp_complaints.status_id`

### D. Ticket Generation
- **Format:** `CMP-{year}-{6-digit serial}`
- **Lock:** `lockForUpdate()` on last ticket query
- **Collision:** `while` loop increments until unique

---

## 9. Dependencies (Cross-Module)
| Module | Dependency | Type |
|--------|-----------|------|
| Complaint (CMP) | Complaint, ComplaintCategory | Read/Write |
| SystemConfig | sys_dropdown_table | Read |
| StudentProfile (STD) | Student (for guardian resolution) | Read |

---

## 10. Integration / API
- AJAX endpoints for subcategories (`getCategories()`) and category meta (`getCategoryMeta()`)
- Media library for complaint image storage
- Paginated listing (15 per page)

---

## 11. Security & Permissions
| Check | Implementation |
|-------|---------------|
| Authentication | Standard `auth` + `verified` middleware |
| Data ownership | Complex query: matches created_by, complainant_user_id, target (student self), AND guardian user IDs |
| Cross-student access | `findOrFail()` inside scoped query → 404 for foreign complaints |
| Anonymous submission | complainant_user_id = null for anonymous |
| Image upload | Stored via `addMediaFromRequest()` to 'complaint_img' collection |

---

## 12. Assumptions & Constraints
- Ticket number generation must be atomic (lockForUpdate)
- Category hierarchy must be pre-configured in `cmp_complaint_categories`
- System dropdowns must have entries for complaint types and statuses
- Guardian complaints are included in the student's complaint list
- No edit/update/destroy operations are exposed (resource controller restricts to index/create/store/show)

---

## 13. Known Issues / Gaps
| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| SEC-STP-04 | Hardcoded dropdown ID 104 referenced elsewhere; store() uses key-based lookup but audit needed for all code paths | **High** | **Open** |
| GAP-STP-10 | Complaint listing is paginated (15/page) but no `withQueryString()` or filter support | Low | Open |
| — | No file type/size validation on complaint_img upload in the controller (relies on client-side) | Medium | Open |
| — | No status filter on complaint listing | Low | Open |
| — | No edit/update/destroy for students (intentional — admin only) | Low | By Design |

---

## 14. Future Enhancements
| ID | Suggestion | Priority |
|----|-----------|----------|
| ENH-STP-CMP-01 | Add status filter to complaint listing | P2 |
| ENH-STP-CMP-02 | Add server-side file type/size validation | P2 |
| ENH-STP-CMP-03 | Add complaint timeline with handler notes visible to student | P2 |
| ENH-STP-CMP-04 | Email notification on status change | P3 |

---

## 15. V1/V2 Status
- **V1:** —
- **V2:** —
- **Status:** ✅ Implemented (with SEC-STP-04 + GAP-STP-10)
- **CR:** ◌

---

## 16. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 23-07-2026 | OpenCode | Initial requirement document |
